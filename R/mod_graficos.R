# R/mod_graficos.R
# Módulo: construtor de gráficos a partir do corpus (420 teses/dissertações),
# com download em PNG, PDF, SVG ou dos dados agregados em CSV.
#
# Deliberadamente independente dos filtros da aba "Buscar" (módulo próprio,
# não reaproveita o estado de mod_busca.R): tem seu próprio recorte de
# período e nível, porque aqui a variável de interesse frequentemente é a
# própria dimensão de agregação (IES, programa, região...), não um registro
# individual.

ABD_G_INK       <- "#121212"
ABD_G_INK_MUTED <- "#5c5750"
ABD_G_PAPER     <- "#fbfaf7"
ABD_G_RULE      <- "#d9d2c2"
ABD_G_SIGNAL    <- "#9a2020"

# label exibido ao usuário -> nome da coluna no corpus ("__decada__" é
# derivada, não existe no corpus).
GRAFICOS_DIMENSOES <- c(
  "Ano"                          = "ano_base",
  "Década"                       = "__decada__",
  "Nível (mestrado/doutorado)"   = "tipo_normalizado",
  "Região"                       = "regiao",
  "UF"                           = "uf",
  "IES"                          = "ies",
  "Programa de pós-graduação"    = "nome_programa",
  "Idioma"                       = "idioma"
)
GRAFICOS_DIM_TEMPORAL <- c("Ano", "Década")

GRAFICOS_COR_OPCOES <- c("Nenhum", "Nível (mestrado/doutorado)", "Região")

paleta_categorica_graficos <- function(niveis) {
  n <- length(niveis)
  if (n <= 1) return(setNames(ABD_G_SIGNAL, niveis))
  cores <- colorRampPalette(c(ABD_G_SIGNAL, ABD_G_INK, ABD_G_INK_MUTED, ABD_G_RULE))(n)
  setNames(cores, niveis)
}

tema_abd_grafico <- function() {
  theme_minimal(base_family = "sans") +
    theme(
      plot.background = element_rect(fill = ABD_G_PAPER, color = NA),
      panel.background = element_rect(fill = ABD_G_PAPER, color = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major.y = element_line(color = ABD_G_RULE, linewidth = 0.3),
      panel.grid.major.x = element_line(color = ABD_G_RULE, linewidth = 0.3),
      axis.text = element_text(color = ABD_G_INK_MUTED, size = 9.5),
      axis.title = element_text(color = ABD_G_INK_MUTED, size = 9.5),
      plot.title = element_text(family = "serif", face = "bold", size = 15, color = ABD_G_INK),
      plot.subtitle = element_text(size = 9.5, color = ABD_G_INK_MUTED, margin = margin(t = 3, b = 10)),
      plot.caption = element_text(size = 7.5, color = ABD_G_INK_MUTED, margin = margin(t = 8)),
      legend.position = "bottom",
      legend.title = element_blank(),
      legend.text = element_text(size = 9, color = ABD_G_INK),
      plot.margin = margin(10, 16, 10, 10)
    )
}

graficos_ui <- function(id) {
  ns <- NS(id)

  layout_sidebar(
    sidebar = sidebar(
      width = 320,
      class = "abd-sidebar",

      div(
        class = "abd-filter-group",
        span(class = "abd-filter-label", "O que exibir"),
        selectInput(ns("dimensao"), "Dimensão (eixo)", choices = names(GRAFICOS_DIMENSOES), selected = "Ano"),
        selectInput(ns("cor"), "Agrupar / colorir por", choices = GRAFICOS_COR_OPCOES, selected = "Nenhum"),
        selectInput(ns("tipo_grafico"), "Tipo de gráfico", choices = c("Barras", "Linha"), selected = "Barras"),
        conditionalPanel(
          condition = sprintf(
            "!(['%s'].includes(input['%s']))",
            paste(GRAFICOS_DIM_TEMPORAL, collapse = "','"), ns("dimensao")
          ),
          sliderInput(ns("top_n"), "Nº máximo de categorias (resto agrupado em \"Outros\")",
                      min = 3, max = 30, value = 15, step = 1)
        )
      ),

      div(
        class = "abd-filter-group",
        span(class = "abd-filter-label", "Filtrar corpus"),
        sliderInput(ns("periodo"), "Período", min = faixa_anos[1], max = faixa_anos[2],
                    value = faixa_anos, sep = "", step = 1),
        checkboxGroupInput(ns("nivel"), "Nível", choices = lista_tipo, selected = lista_tipo)
      ),

      div(
        class = "abd-filter-group",
        span(class = "abd-filter-label", "Título do gráfico"),
        textInput(ns("titulo"), NULL, value = "Teses e dissertações em História do Direito")
      ),

      div(
        class = "abd-filter-group",
        span(class = "abd-filter-label", "Baixar"),
        selectInput(ns("formato"), "Formato", choices = c("PNG", "PDF", "SVG", "Dados (CSV)"), selected = "PNG"),
        downloadButton(ns("baixar"), "Baixar gráfico", class = "btn-primary w-100")
      )
    ),

    div(class = "abd-eyebrow", textOutput(ns("contagem"), inline = TRUE)),
    plotOutput(ns("grafico"), height = "560px")
  )
}

graficos_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # --- tipo de grafico disponivel depende da dimensao (linha so faz
    # sentido em serie temporal) ---------------------------------------
    observeEvent(input$dimensao, {
      if (input$dimensao %in% GRAFICOS_DIM_TEMPORAL) {
        updateSelectInput(session, "tipo_grafico", choices = c("Barras", "Linha"),
                           selected = isolate(input$tipo_grafico))
      } else {
        updateSelectInput(session, "tipo_grafico", choices = "Barras", selected = "Barras")
      }
    })

    dados_base <- reactive({
      req(length(input$nivel) > 0)
      corpus |>
        filter(
          ano_base >= input$periodo[1], ano_base <= input$periodo[2],
          tipo_normalizado %in% input$nivel
        )
    })

    dados_agregados <- reactive({
      df <- dados_base()
      dim_col <- GRAFICOS_DIMENSOES[[input$dimensao]]

      df$.eixo <- if (input$dimensao == "Década") {
        paste0((df$ano_base %/% 10) * 10, "s")
      } else {
        df[[dim_col]]
      }

      cor_col <- if (input$cor == "Nenhum") NULL else GRAFICOS_DIMENSOES[[input$cor]]
      df$.cor <- if (is.null(cor_col)) "Total" else df[[cor_col]]

      agregado <- df |> count(.eixo, .cor, name = "n")

      temporal <- input$dimensao %in% GRAFICOS_DIM_TEMPORAL
      if (!temporal) {
        totais <- agregado |> group_by(.eixo) |> summarise(total = sum(n), .groups = "drop")
        top_categorias <- totais |> arrange(desc(total)) |> slice_head(n = input$top_n) |> pull(.eixo)
        agregado <- agregado |>
          mutate(.eixo = if_else(.eixo %in% top_categorias, .eixo, "Outros")) |>
          group_by(.eixo, .cor) |>
          summarise(n = sum(n), .groups = "drop")

        totais2 <- agregado |> group_by(.eixo) |> summarise(total = sum(n), .groups = "drop")
        ordem <- totais2 |> filter(.eixo != "Outros") |> arrange(total) |> pull(.eixo)
        if ("Outros" %in% totais2$.eixo) ordem <- c("Outros", ordem)
        agregado$.eixo <- factor(agregado$.eixo, levels = ordem)
      } else if (input$dimensao == "Década") {
        agregado$.eixo <- factor(agregado$.eixo, levels = sort(unique(agregado$.eixo)))
      }

      agregado
    })

    construir_grafico <- reactive({
      dados <- dados_agregados()
      temporal <- input$dimensao %in% GRAFICOS_DIM_TEMPORAL
      niveis_cor <- sort(unique(as.character(dados$.cor)))
      pal <- paleta_categorica_graficos(niveis_cor)
      mostrar_legenda <- length(niveis_cor) > 1

      p <- ggplot(dados, aes(x = .eixo, y = n))
      guia <- if (mostrar_legenda) "legend" else "none"

      # scale_fill_manual/scale_color_manual so sao adicionadas quando a
      # aesthetic correspondente e de fato usada no geom — caso contrario o
      # ggplot avisa "No shared levels found" (inofensivo, mas poluia o log).
      if (temporal && input$tipo_grafico == "Linha") {
        p <- p +
          geom_line(aes(color = .cor, group = .cor), linewidth = 1) +
          geom_point(aes(color = .cor), size = 1.7) +
          scale_color_manual(values = pal, guide = guia)
      } else {
        p <- p + geom_col(aes(fill = .cor), position = position_stack()) +
          scale_fill_manual(values = pal, guide = guia)
        if (!temporal) p <- p + coord_flip()
      }

      p <- p +
        labs(
          title = input$titulo,
          subtitle = sprintf(
            "%s trabalhos · %d-%d · elaboração própria a partir do Banco de Teses e Dissertações da CAPES",
            format(sum(dados$n), big.mark = ".", decimal.mark = ","), input$periodo[1], input$periodo[2]
          ),
          x = NULL, y = "Nº de trabalhos"
        ) +
        tema_abd_grafico()

      if (!temporal) p <- p + theme(panel.grid.major.y = element_blank())

      p
    })

    output$contagem <- renderText({
      sprintf("%d de %d trabalhos considerados neste gráfico.", nrow(dados_base()), n_total)
    })

    output$grafico <- renderPlot(construir_grafico(), res = 108)

    output$baixar <- downloadHandler(
      filename = function() {
        ext <- switch(input$formato, "PNG" = "png", "PDF" = "pdf", "SVG" = "svg", "Dados (CSV)" = "csv")
        paste0("grafico_historia_direito_", Sys.Date(), ".", ext)
      },
      content = function(file) {
        if (input$formato == "Dados (CSV)") {
          df <- dados_agregados()
          names(df)[names(df) == ".eixo"] <- input$dimensao
          names(df)[names(df) == ".cor"] <- if (input$cor == "Nenhum") "categoria" else input$cor
          names(df)[names(df) == "n"] <- "n_trabalhos"
          write_csv(df, file)
        } else {
          device <- switch(input$formato, "PNG" = "png", "PDF" = "pdf", "SVG" = "svg")
          ggsave(
            file, plot = construir_grafico(), device = device,
            width = 9.5, height = 6.5, dpi = 300, bg = ABD_G_PAPER
          )
        }
      }
    )
  })
}
