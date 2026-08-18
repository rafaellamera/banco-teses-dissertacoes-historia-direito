# ui.R

ui <- page_fluid(
  theme = bs_theme(version = 5),
  title = "Banco de Teses e Dissertações - História do Direito",
  padding = 0,

  tags$head(
    tags$link(rel = "stylesheet", href = "styles.css")
  ),

  div(
    class = "abd-shell",

    div(
      class = "abd-masthead",
      span(class = "abd-kicker", "Observatório dos Direitos Sociais do Semiárido · PPGD-UFERSA"),
      h1(class = "abd-title", "Banco de Teses e Dissertações em História do Direito"),
      p(class = "abd-subtitle",
        sprintf("1994-2024 · %d registros de mestrado e doutorado em Programas de Pós-Graduação em Direito no Brasil", n_total)),
      p(class = "abd-byline", "Rafael Lamera Giesta Cabral · UFERSA")
    ),

    contribuicao_ui("contribuicao"),

    busca_ui("busca"),

    tags$footer(
      class = "abd-footer",
      p(
        class = "abd-footer-line",
        "Desenvolvido por Rafael Lamera Giesta Cabral · UFERSA · Código aberto · Projeto disponível no ",
        tags$a(
          href = "https://github.com/rafaellamera/banco-teses-historia-direito",
          target = "_blank", rel = "noopener noreferrer",
          "GitHub"
        )
      ),
      p(
        class = "abd-footer-line",
        "Dados: Banco de Teses e Dissertações da CAPES (1994-2024). Última atualização: 17 de agosto de 2026."
      ),
      div(
        class = "abd-footer-links",
        tags$a(
          href = "mailto:rafaelcabral@ufersa.edu.br",
          target = "_blank", title = "E-mail",
          icon("envelope")
        ),
        tags$a(
          href = "https://github.com/rafaellamera",
          target = "_blank", rel = "noopener noreferrer", title = "GitHub",
          icon("github")
        ),
        tags$a(
          href = "https://orcid.org/0000-0002-6442-4924",
          target = "_blank", rel = "noopener noreferrer", title = "ORCID",
          icon("id-badge")
        ),
        tags$a(
          href = "http://lattes.cnpq.br/8035594335420500",
          target = "_blank", rel = "noopener noreferrer", title = "Lattes",
          icon("file-lines")
        )
      )
    )
  )
)
