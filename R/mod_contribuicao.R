# R/mod_contribuicao.R
# Módulo: chamada "Sua tese ou dissertação não está aqui?" e formulário
# de indicação, enviado por mailto: (sem backend de e-mail).

contribuicao_ui <- function(id) {
  ns <- NS(id)

  tagList(
    tags$script(HTML(
      "Shiny.addCustomMessageHandler('abrirMailto', function(url) {
         window.location.href = url;
       });"
    )),
    div(
      class = "abd-callout",
      span(class = "abd-callout-text", "Sua tese ou dissertação não está neste banco? "),
      actionLink(ns("abrir_contribuicao"), "Fale conosco.", class = "abd-callout-link")
    )
  )
}

contribuicao_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$abrir_contribuicao, {
      showModal(modalDialog(
        title = "Indicar tese ou dissertação",
        size = "m",
        easyClose = TRUE,
        footer = tagList(
          modalButton("Cancelar"),
          actionButton(session$ns("enviar_contribuicao"), "Enviar", class = "btn-primary")
        ),
        div(
          class = "abd-form",
          p(
            "Preencha os dados abaixo. Ao enviar, seu programa de e-mail vai abrir uma",
            "mensagem pré-preenchida para ", tags$strong("rafaelcabral@ufersa.edu.br"), "."
          ),
          textInput(session$ns("contrib_nome"), "Nome completo do autor(a)"),
          textInput(session$ns("contrib_orientador"), "Orientador(a)"),
          textInput(session$ns("contrib_link"), "Link da dissertação/tese no repositório da universidade")
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
  })
}
