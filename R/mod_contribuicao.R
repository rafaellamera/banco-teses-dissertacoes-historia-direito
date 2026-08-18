# R/mod_contribuicao.R
# Módulo: chamada "Sua tese ou dissertação não está aqui?", com link
# direto para o formulário Google Forms de indicação.

contribuicao_ui <- function(id) {
  div(
    class = "abd-callout",
    span(class = "abd-callout-text", "Sua tese ou dissertação não está neste banco? "),
    tags$a(
      href = "https://docs.google.com/forms/d/e/1FAIpQLSeXGojzRqzTapeAC5HQDSBneijTvHmcgXTHGtKqtGj-XWEwug/viewform?usp=header",
      target = "_blank", rel = "noopener noreferrer",
      class = "abd-callout-link",
      "Fale conosco."
    )
  )
}
