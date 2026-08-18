# R/mod_busca.R
# Módulo: filtros, busca, tabela, detalhe em modal e downloads do corpus.

busca_ui <- function(id) {
  ns <- NS(id)

  layout_sidebar(
    sidebar = sidebar(
      width = 320,
      class = "abd-sidebar",

      div(
        class = "abd-filter-group",
        span(class = "abd-filter-label", "Período"),
        sliderInput(
          ns("f_ano"), NULL,
          min = faixa_anos[1], max = faixa_anos[2],
          value = faixa_anos, sep = "", step = 1
        )
      ),

      div(
        class = "abd-filter-group",
        span(class = "abd-filter-label", "Tipo de pesquisa"),
        checkboxGroupInput(ns("f_tipo"), NULL, choices = lista_tipo, selected = lista_tipo)
      ),

      div(
        class = "abd-filter-group",
        span(class = "abd-filter-label", "Instituição"),
        selectizeInput(
          ns("f_programa"), "Programa de pós-graduação",
          choices = lista_programas, multiple = TRUE,
          options = list(placeholder = "Todos os programas")
        ),
        selectizeInput(
          ns("f_ies"), "IES",
          choices = lista_ies, multiple = TRUE,
          options = list(placeholder = "Todas as IES")
        )
      ),

      div(
        class = "abd-filter-group",
        span(class = "abd-filter-label", "Localização"),
        checkboxGroupInput(ns("f_regiao"), "Região", choices = lista_regiao, selected = lista_regiao),
        selectizeInput(
          ns("f_uf"), "UF",
          choices = lista_uf, multiple = TRUE,
          options = list(placeholder = "Todas as UF")
        )
      ),

      div(
        class = "abd-filter-group",
        span(class = "abd-filter-label", "Busca textual"),
        textInput(ns("f_titulo"), "Título"),
        textInput(ns("f_autoria"), "Autoria"),
        textInput(ns("f_orientacao"), "Orientador(a)"),
        textInput(ns("f_assunto"), "Assunto (resumo e título)")
      ),

      div(
        class = "abd-filter-group",
        actionButton(ns("limpar"), "Limpar filtros", icon = icon("eraser"), class = "btn-outline-secondary w-100"),
        br(), br(),
        checkboxInput(ns("mostrar_metadados"), "Mostrar metadados de classificação", value = FALSE)
      ),

      div(
        class = "abd-filter-group",
        downloadButton(ns("baixar_filtrados"), "Baixar filtrados (CSV)", class = "btn-primary w-100 mb-2"),
        downloadButton(ns("baixar_completo"), "Baixar base completa (CSV)", class = "btn-outline-primary w-100")
      )
    ),

    navset_tab(
      nav_panel(
        "Buscar",
        div(class = "abd-eyebrow", textOutput(ns("contagem"), inline = TRUE)),
        DTOutput(ns("tabela"))
      ),
      nav_panel(
        "Sobre e metodologia",
        div(class = "abd-article", includeMarkdown("www/sobre.md"))
      )
    )
  )
}

busca_server <- function(id) {
  moduleServer(id, function(input, output, session) {

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

    # --- Downloads -----------------------------------------------------------
    output$baixar_filtrados <- downloadHandler(
      filename = function() paste0("corpus_historia_direito_filtrado_", Sys.Date(), ".csv"),
      content = function(file) write_csv(dados_filtrados(), file)
    )

    output$baixar_completo <- downloadHandler(
      filename = function() "corpus_historia_direito_1994_2024_completo.csv",
      content = function(file) write_csv(corpus, file)
    )
  })
}
