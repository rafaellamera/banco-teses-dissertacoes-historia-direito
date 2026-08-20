# R/mod_rede.R
# Módulo: rede de orientação (genealogia acadêmica) interativa.
#
# Dados: rede_nos / rede_arestas / faixa_anos_rede, carregados em global.R
# a partir de data/rede_orientacao_nos.csv e data/rede_orientacao_arestas.csv
# (scripts/build_network.R). O layout (rede_nos$layout_x/layout_y) também é
# calculado uma única vez em global.R, para a posição de cada pessoa ficar
# estável enquanto o slider de ano cumulativo revela mais nós.
#
# Nota metodológica (repetida da Etapa 4 do prompt original, também exibida
# dentro do próprio painel, ver rede_ui() abaixo):
#   - a rede reflete só os 420 trabalhos já classificados como História do
#     Direito, não o universo completo de orientações dessas pessoas;
#   - uma aresta "A orientou B" não implica ausência de outras orientações
#     de A ou B fora deste corpus;
#   - homônimos são um risco residual mesmo após a checagem manual da
#     Etapa 0 (ver scripts/build_network.R);
#   - não houve coorientação nos 420 registros (0 casos, ver Etapa 0).

ABD_COR_SIGNAL <- "#9a2020"
ABD_COR_INK    <- "#121212"
ABD_COR_RULE   <- "#d9d2c2"
ABD_COR_INK_MUTED <- "#5c5750"

CATEGORIA_FORMADO  <- "Orientador(a) formado(a) no corpus"
CATEGORIA_EXTERNO  <- "Orientador(a) externo(a) ao corpus"
CATEGORIA_ORIENTANDO <- "Orientando(a) (sem orientação no corpus, até este ano)"

rede_ui <- function(id) {
  ns <- NS(id)

  layout_sidebar(
    sidebar = sidebar(
      width = 320,
      class = "abd-sidebar",

      div(
        class = "abd-filter-group",
        span(class = "abd-filter-label", "Ano (visão cumulativa)"),
        sliderInput(
          ns("ano"), NULL,
          min = faixa_anos_rede[1], max = faixa_anos_rede[2],
          value = faixa_anos_rede[2], sep = "", step = 1,
          animate = animationOptions(interval = 900, loop = FALSE)
        ),
        p(
          class = "abd-footer-line",
          style = "text-align:left; margin-top:0.4rem;",
          "Mostra todas as orientações registradas até o ano selecionado. Aperte o play para ver a rede crescer."
        )
      ),

      div(
        class = "abd-filter-group",
        span(class = "abd-filter-label", "Como ler"),
        p(class = "abd-footer-line", style = "text-align:left;",
          tags$span(style = paste0("color:", ABD_COR_SIGNAL, "; font-weight:700;"), "● "),
          "Orientador(a) formado(a) dentro do próprio corpus."),
        p(class = "abd-footer-line", style = "text-align:left;",
          tags$span(style = paste0("color:", ABD_COR_INK, "; font-weight:700;"), "● "),
          "Orientador(a) externo(a) ao corpus."),
        p(class = "abd-footer-line", style = "text-align:left;",
          tags$span(style = paste0("color:", ABD_COR_RULE, "; font-weight:700;"), "● "),
          "Orientando(a) sem orientação registrada no corpus até este ano."),
        p(class = "abd-footer-line", style = "text-align:left;",
          "Tamanho do nó = nº de orientandos(as) acumulado. Clique num nó para destacar sua vizinhança direta.")
      ),

      div(
        class = "abd-filter-group",
        span(class = "abd-filter-label", "Ranking de orientadores(as) até o ano selecionado"),
        DTOutput(ns("ranking"))
      )
    ),

    div(class = "abd-eyebrow", textOutput(ns("contagem"), inline = TRUE)),
    visNetworkOutput(ns("grafo"), height = "640px"),

    div(
      class = "abd-article",
      style = "margin-top:1.5rem; font-size:0.86rem;",
      tags$h2("Nota metodológica"),
      tags$ul(
        tags$li("A rede reflete apenas os 420 trabalhos já classificados como História do Direito neste banco, não o universo completo de orientações dessas pessoas em outras áreas ou fora do recorte temporal (1994-2024)."),
        tags$li("Uma aresta “A orientou B” não implica ausência de outras orientações de A ou B fora deste corpus."),
        tags$li("Homônimos são um risco residual mesmo após checagem manual de grafia (nomes duplicados por caixa/acentuação e por nome parcial vs. completo foram unificados manualmente; casos de identidade incerta, como sobrenomes comuns sem outra evidência, foram mantidos separados)."),
        tags$li("Não houve coorientação nos 420 registros do corpus: nenhum delimitador de múltiplos nomes foi encontrado no campo de orientação, então cada registro corresponde a exatamente uma aresta orientador → orientando.")
      )
    )
  )
}

rede_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    arestas_ate <- reactive({
      rede_arestas |> filter(ano_base <= input$ano)
    })

    nos_ate <- reactive({
      ae <- arestas_ate()
      ids_presentes <- union(ae$orientador, ae$orientando)

      grau_orientador <- ae |> count(orientador, name = "grau_ate")
      orientandos_set <- unique(ae$orientando)
      orientadores_set <- unique(ae$orientador)

      rede_nos |>
        filter(nome_canonico %in% ids_presentes) |>
        left_join(grau_orientador, by = c("nome_canonico" = "orientador")) |>
        mutate(
          grau_ate = coalesce(grau_ate, 0L),
          foi_orientando_ate = nome_canonico %in% orientandos_set,
          foi_orientador_ate = nome_canonico %in% orientadores_set,
          categoria = case_when(
            foi_orientador_ate & foi_orientando_ate ~ CATEGORIA_FORMADO,
            foi_orientador_ate & !foi_orientando_ate ~ CATEGORIA_EXTERNO,
            TRUE ~ CATEGORIA_ORIENTANDO
          )
        )
    })

    output$contagem <- renderText({
      sprintf(
        "%d pessoas · %d orientações registradas até %d.",
        nrow(nos_ate()), nrow(arestas_ate()), input$ano
      )
    })

    output$grafo <- renderVisNetwork({
      nos_df <- nos_ate() |>
        transmute(
          id = nome_canonico,
          label = nome_canonico,
          title = sprintf(
            "<b>%s</b><br>Orientandos(as) no corpus (até %d): %d<br>%s",
            nome_canonico, input$ano, grau_ate,
            ifelse(foi_orientando_ate, "Também é autor(a) de um trabalho no corpus.", "")
          ),
          value = pmax(grau_ate, 1),
          group = categoria,
          x = layout_x,
          y = -layout_y
        )

      arestas_df <- arestas_ate() |>
        transmute(from = orientador, to = orientando)

      visNetwork(nos_df, arestas_df) |>
        visGroups(groupname = CATEGORIA_FORMADO, color = list(background = ABD_COR_SIGNAL, border = ABD_COR_SIGNAL)) |>
        visGroups(groupname = CATEGORIA_EXTERNO, color = list(background = ABD_COR_INK, border = ABD_COR_INK)) |>
        visGroups(groupname = CATEGORIA_ORIENTANDO, color = list(background = ABD_COR_RULE, border = ABD_COR_RULE)) |>
        visNodes(shape = "dot", font = list(color = ABD_COR_INK, face = "Libre Franklin", size = 13)) |>
        visEdges(
          arrows = list(to = list(enabled = TRUE, scaleFactor = 0.5)),
          color = list(color = ABD_COR_INK_MUTED, opacity = 0.35),
          smooth = FALSE
        ) |>
        visOptions(
          highlightNearest = list(enabled = TRUE, degree = 1, hover = FALSE),
          nodesIdSelection = list(enabled = TRUE, main = "Buscar pessoa")
        ) |>
        visInteraction(hover = TRUE, tooltipDelay = 100, navigationButtons = TRUE) |>
        visPhysics(enabled = FALSE)
      # Sem visLegend(): os marcadores de legenda automaticos do visNetwork
      # renderizam o rotulo inteiro dentro do circulo (ilegivel com nomes
      # longos como os das categorias abaixo). A legenda fica no sidebar,
      # em "Como ler" (rede_ui() acima), com as mesmas 3 cores.
    })

    output$ranking <- renderDT({
      df <- nos_ate() |>
        filter(grau_ate > 0) |>
        arrange(desc(grau_ate)) |>
        select(nome_canonico, grau_ate)
      colnames(df) <- c("Orientador(a)", "Nº")

      datatable(
        df,
        class = "hover",
        rownames = FALSE,
        selection = "none",
        options = list(
          pageLength = 8,
          dom = "tp",
          language = list(url = "//cdn.datatables.net/plug-ins/1.13.6/i18n/pt-BR.json")
        )
      )
    })
  })
}
