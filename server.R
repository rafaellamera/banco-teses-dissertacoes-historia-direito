# server.R

server <- function(input, output, session) {

  # --- Reativo central: aplica todos os filtros em sequencia -----------
  dados_filtrados <- reactive({
    df <- corpus

    df <- df |> filter(ano_base >= input$f_ano[1], ano_base <= input$f_ano[2])

    if (length(input$f_tipo) > 0) {
      df <- df |> filter(tipo_normalizado %in% input$f_tipo)
    } else {
      df <- df[0, ]
    }

    if (length(input$f_programa) > 0) {
      df <- df |> filter(nome_programa %in% input$f_programa)
    }

    if (length(input$f_ies) > 0) {
      df <- df |> filter(ies %in% input$f_ies)
    }

    if (length(input$f_regiao) > 0) {
      df <- df |> filter(regiao %in% input$f_regiao)
    } else {
      df <- df[0, ]
    }

    if (length(input$f_uf) > 0) {
      df <- df |> filter(uf %in% input$f_uf)
    }

    termo_titulo <- str_trim(input$f_titulo)
    if (nzchar(termo_titulo)) {
      alvo <- remover_acentos(termo_titulo)
      df <- df |> filter(str_detect(remover_acentos(titulo), fixed(alvo)))
    }

    termo_autoria <- str_trim(input$f_autoria)
    if (nzchar(termo_autoria)) {
      alvo <- remover_acentos(termo_autoria)
      df <- df |> filter(str_detect(remover_acentos(autoria), fixed(alvo)))
    }

    termo_orientacao <- str_trim(input$f_orientacao)
    if (nzchar(termo_orientacao)) {
      alvo <- remover_acentos(termo_orientacao)
      df <- df |> filter(str_detect(remover_acentos(orientacao), fixed(alvo)))
    }

    termo_assunto <- str_trim(input$f_assunto)
    if (nzchar(termo_assunto)) {
      alvo <- remover_acentos(termo_assunto)
      df <- df |> filter(
        str_detect(remover_acentos(titulo), fixed(alvo)) |
          str_detect(remover_acentos(resumo), fixed(alvo))
      )
    }

    df
  })

  # --- Botao "Limpar filtros" --------------------------------------------
  observeEvent(input$limpar, {
    updateSliderInput(session, "f_ano", value = faixa_anos)
    updateCheckboxGroupInput(session, "f_tipo", selected = lista_tipo)
    updateSelectizeInput(session, "f_programa", selected = character(0))
    updateSelectizeInput(session, "f_ies", selected = character(0))
    updateCheckboxGroupInput(session, "f_regiao", selected = lista_regiao)
    updateSelectizeInput(session, "f_uf", selected = character(0))
    updateTextInput(session, "f_titulo", value = "")
    updateTextInput(session, "f_autoria", value = "")
    updateTextInput(session, "f_orientacao", value = "")
    updateTextInput(session, "f_assunto", value = "")
  })

  # --- Contador ------------------------------------------------------------
  output$contagem <- renderText({
    n <- nrow(dados_filtrados())
    sprintf("%d de %d trabalhos exibidos.", n, n_total)
  })

  # --- Tabela principal ------------------------------------------------
  output$tabela <- renderDT({
    colunas_base <- c(
      "ano_base", "tipo_normalizado", "titulo",
      "autoria", "orientacao", "ies", "nome_programa", "uf"
    )
    colunas_extra <- if (isTRUE(input$mostrar_metadados)) c("confianca", "origem") else character(0)

    df <- dados_filtrados() |> select(any_of(c(colunas_base, colunas_extra)))

    rotulos <- c(
      ano_base = "Ano", tipo_normalizado = "Nível",
      titulo = "Título", autoria = "Autoria", orientacao = "Orientação",
      ies = "IES", nome_programa = "Programa", uf = "UF",
      confianca = "Confiança", origem = "Corpus de origem"
    )
    colnames(df) <- unname(rotulos[colnames(df)])

    datatable(
      df,
      class = "hover",
      selection = "single",
      rownames = FALSE,
      filter = "none",
      options = list(
        pageLength = 15,
        columnDefs = list(list(className = "dt-right", targets = 0)),
        language = list(
          url = "//cdn.datatables.net/plug-ins/1.13.6/i18n/pt-BR.json"
        )
      )
    )
  })

  # --- Detalhe do registro selecionado, em modal (estilo materia editorial)
  observeEvent(input$tabela_rows_selected, {
    sel <- input$tabela_rows_selected
    req(sel)
    df <- dados_filtrados()
    req(nrow(df) >= sel)

    reg <- df[sel, ]

    showModal(modalDialog(
      title = NULL,
      size = "l",
      easyClose = TRUE,
      footer = modalButton("Fechar"),
      div(
        class = "abd-record",
        div(class = "abd-record-kicker", paste(reg$ies, reg$nome_programa, sep = " · ")),
        h2(class = "abd-record-title", reg$titulo),
        p(class = "abd-record-byline", sprintf("Por %s. Orientação de %s.", reg$autoria, reg$orientacao)),
        p(class = "abd-record-dateline",
          sprintf("%s · %d · %s (%s)", reg$tipo_normalizado, reg$ano_base, reg$uf, reg$regiao)),
        p(class = "abd-record-body", reg$resumo)
      )
    ))
  })

  # --- Formulário "Sua tese ou dissertação não está aqui?" -----------------
  observeEvent(input$abrir_contribuicao, {
    showModal(modalDialog(
      title = "Indicar tese ou dissertação",
      size = "m",
      easyClose = TRUE,
      footer = tagList(
        modalButton("Cancelar"),
        actionButton("enviar_contribuicao", "Enviar", class = "btn-primary")
      ),
      div(
        class = "abd-form",
        p(
          "Preencha os dados abaixo. Ao enviar, seu programa de e-mail vai abrir uma",
          "mensagem pré-preenchida para ", tags$strong("rafaelcabral@ufersa.edu.br"), "."
        ),
        textInput("contrib_nome", "Nome completo do autor(a)"),
        textInput("contrib_orientador", "Orientador(a)"),
        textInput("contrib_link", "Link da dissertação/tese no repositório da universidade")
      )
    ))
  })

  observeEvent(input$enviar_contribuicao, {
    nome <- str_trim(input$contrib_nome)
    if (!nzchar(nome)) {
      showNotification("Informe ao menos o nome completo.", type = "error")
      return()
    }

    assunto <- "Sugestão de inclusão - Banco de Teses História do Direito"
    corpo <- sprintf(
      "Nome completo: %s\nOrientador(a): %s\nLink da dissertação/tese: %s",
      nome,
      str_trim(input$contrib_orientador),
      str_trim(input$contrib_link)
    )
    url <- paste0(
      "mailto:rafaelcabral@ufersa.edu.br",
      "?subject=", utils::URLencode(assunto, reserved = TRUE),
      "&body=", utils::URLencode(corpo, reserved = TRUE)
    )

    session$sendCustomMessage("abrirMailto", url)
    removeModal()
    showNotification("Seu programa de e-mail deve abrir com a mensagem pronta.", type = "message")
  })

  # --- Downloads -----------------------------------------------------------
  output$baixar_filtrados <- downloadHandler(
    filename = function() paste0("corpus_historia_direito_filtrado_", Sys.Date(), ".csv"),
    content = function(file) write_csv(dados_filtrados(), file)
  )

  output$baixar_completo <- downloadHandler(
    filename = function() "corpus_historia_direito_1994_2024_completo.csv",
    content = function(file) write_csv(corpus, file)
  )
}
