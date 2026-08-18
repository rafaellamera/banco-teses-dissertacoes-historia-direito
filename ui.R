# ui.R

ui <- page_fluid(
  theme = bs_theme(
    version = 5,
    base_font = font_google("Libre Franklin"),
    heading_font = font_google("Source Serif 4")
  ),
  title = "Banco de Teses e Dissertações - História do Direito",
  padding = 0,

  tags$head(
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(
      rel = "stylesheet",
      href = paste0(
        "https://fonts.googleapis.com/css2?family=Libre+Franklin:wght@400;500;600;700",
        "&family=Source+Serif+4:opsz,wght@8..60,400;8..60,600;8..60,700&display=swap"
      )
    ),
    tags$link(rel = "stylesheet", href = "styles.css"),
    tags$script(HTML(
      "Shiny.addCustomMessageHandler('abrirMailto', function(url) {
         window.location.href = url;
       });"
    ))
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

    div(
      class = "abd-callout",
      span(class = "abd-callout-text", "Sua tese ou dissertação não está neste banco? "),
      actionLink("abrir_contribuicao", "Fale conosco.", class = "abd-callout-link")
    ),

    layout_sidebar(
      sidebar = sidebar(
        width = 320,
        class = "abd-sidebar",

        div(
          class = "abd-filter-group",
          span(class = "abd-filter-label", "Período"),
          sliderInput(
            "f_ano", NULL,
            min = faixa_anos[1], max = faixa_anos[2],
            value = faixa_anos, sep = "", step = 1
          )
        ),

        div(
          class = "abd-filter-group",
          span(class = "abd-filter-label", "Tipo de pesquisa"),
          checkboxGroupInput("f_tipo", NULL, choices = lista_tipo, selected = lista_tipo)
        ),

        div(
          class = "abd-filter-group",
          span(class = "abd-filter-label", "Instituição"),
          selectizeInput(
            "f_programa", "Programa de pós-graduação",
            choices = lista_programas, multiple = TRUE,
            options = list(placeholder = "Todos os programas")
          ),
          selectizeInput(
            "f_ies", "IES",
            choices = lista_ies, multiple = TRUE,
            options = list(placeholder = "Todas as IES")
          )
        ),

        div(
          class = "abd-filter-group",
          span(class = "abd-filter-label", "Localização"),
          checkboxGroupInput("f_regiao", "Região", choices = lista_regiao, selected = lista_regiao),
          selectizeInput(
            "f_uf", "UF",
            choices = lista_uf, multiple = TRUE,
            options = list(placeholder = "Todas as UF")
          )
        ),

        div(
          class = "abd-filter-group",
          span(class = "abd-filter-label", "Busca textual"),
          textInput("f_titulo", "Título contém"),
          textInput("f_autoria", "Autoria contém"),
          textInput("f_orientacao", "Orientação contém"),
          textInput("f_assunto", "Assunto (resumo e título)")
        ),

        div(
          class = "abd-filter-group",
          actionButton("limpar", "Limpar filtros", icon = icon("eraser"), class = "btn-outline-secondary w-100"),
          br(), br(),
          checkboxInput("mostrar_metadados", "Mostrar metadados de classificação", value = FALSE)
        ),

        div(
          class = "abd-filter-group",
          downloadButton("baixar_filtrados", "Baixar filtrados (CSV)", class = "btn-primary w-100 mb-2"),
          downloadButton("baixar_completo", "Baixar base completa (CSV)", class = "btn-outline-primary w-100")
        )
      ),

      navset_tab(
        nav_panel(
          "Buscar",
          div(class = "abd-eyebrow", textOutput("contagem", inline = TRUE)),
          DTOutput("tabela")
        ),
        nav_panel(
          "Sobre e metodologia",
          div(class = "abd-article", includeMarkdown("www/sobre.md"))
        )
      )
    ),

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
        "Dados: Banco de Teses e Dissertações da CAPES. Última atualização: 17 de agosto de 2026."
      )
    )
  )
)
