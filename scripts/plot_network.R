# scripts/plot_network.R
#
# Etapa 3a: visualizacao estatica da rede de orientacao, para uso em artigo.
# Le data/rede_orientacao_nos.csv e data/rede_orientacao_arestas.csv
# (scripts/build_network.R) e exporta PNG/PDF em alta resolucao.
#
# Rodar:
#   Rscript scripts/plot_network.R
#
# Produz:
#   figuras/rede_orientacao_historia_direito.png (300 dpi)
#   figuras/rede_orientacao_historia_direito.pdf (vetorial)
#
# NAO altera nenhum CSV.

library(readr)
library(dplyr)
library(igraph)
library(ggraph)
library(ggplot2)

caminho_nos     <- "data/rede_orientacao_nos.csv"
caminho_arestas <- "data/rede_orientacao_arestas.csv"
dir_saida       <- "figuras"

nos     <- read_csv(caminho_nos, show_col_types = FALSE)
arestas <- read_csv(caminho_arestas, show_col_types = FALSE)

# --- paleta do projeto (www/styles.css) --------------------------------
abd_ink       <- "#121212"
abd_ink_muted <- "#5c5750"
abd_paper     <- "#fbfaf7"
abd_rule      <- "#d9d2c2"
abd_signal    <- "#9a2020"

# --- categoria de cada no, para a legenda ---------------------------------
# Ver Etapa 3a do prompt original: cor indica foi_orientando_no_corpus,
# com destaque para quem fez a transicao geracional. Como a maioria dos
# nos e orientando-terminal (nunca orienta ninguem no corpus), a
# categoria "orientando" fica em tom neutro para nao competir visualmente
# com o que a figura quer evidenciar: os orientadores formados no corpus.
nos <- nos |>
  mutate(
    categoria = case_when(
      foi_orientador_no_corpus & foi_orientando_no_corpus ~ "Orientador(a) formado(a) no corpus",
      foi_orientador_no_corpus & !foi_orientando_no_corpus ~ "Orientador(a) externo(a) ao corpus",
      TRUE ~ "Orientando(a) (sem orientacao no corpus)"
    ),
    categoria = factor(categoria, levels = c(
      "Orientador(a) formado(a) no corpus",
      "Orientador(a) externo(a) ao corpus",
      "Orientando(a) (sem orientacao no corpus)"
    ))
  )

cores_categoria <- c(
  "Orientador(a) formado(a) no corpus"       = abd_signal,
  "Orientador(a) externo(a) ao corpus"       = abd_ink,
  "Orientando(a) (sem orientacao no corpus)" = abd_rule
)

grafo <- graph_from_data_frame(
  d = arestas |> select(orientador, orientando),
  vertices = nos |> select(nome_canonico, n_como_orientador, categoria),
  directed = TRUE
)

set.seed(42) # layout reprodutivel
layout_fr <- create_layout(grafo, layout = "fr")

# --- rotulos: so os orientadores mais centrais, senao 580 nomes poluem a figura
LIMIAR_ROTULO <- 4
layout_fr$rotulo <- ifelse(layout_fr$n_como_orientador >= LIMIAR_ROTULO, layout_fr$name, NA)

grafico <- ggraph(layout_fr) +
  geom_edge_link(
    color = abd_ink_muted, alpha = 0.15, width = 0.3,
    arrow = arrow(length = unit(1.3, "mm"), type = "closed"),
    end_cap = circle(1.2, "mm")
  ) +
  geom_node_point(
    aes(size = pmax(n_como_orientador, 1), color = categoria),
    alpha = 0.9
  ) +
  geom_node_text(
    aes(label = rotulo), repel = TRUE, family = "serif",
    size = 3.1, color = abd_ink, min.segment.length = 0.2, seed = 42,
    max.overlaps = 30
  ) +
  scale_color_manual(values = cores_categoria, name = NULL) +
  scale_size_continuous(range = c(1, 11), guide = "none") +
  labs(
    title = "Rede de orientação em História do Direito (CAPES, 1994-2024)",
    subtitle = paste0(
      vcount(grafo), " pessoas · ", ecount(grafo), " orientações · ",
      sum(nos$categoria == "Orientador(a) formado(a) no corpus"),
      " orientadores(as) formados(as) dentro do próprio corpus"
    ),
    caption = "Fonte: Banco de Teses e Dissertações da CAPES, área Direito (1994-2024). Elaboração própria."
  ) +
  theme_void(base_family = "sans") +
  theme(
    plot.background = element_rect(fill = abd_paper, color = NA),
    panel.background = element_rect(fill = abd_paper, color = NA),
    legend.position = "bottom",
    legend.text = element_text(size = 9, color = abd_ink),
    plot.title = element_text(family = "serif", face = "bold", size = 15, color = abd_ink, hjust = 0.5),
    plot.subtitle = element_text(size = 9.5, color = abd_ink_muted, hjust = 0.5, margin = margin(t = 4, b = 8)),
    plot.caption = element_text(size = 7.5, color = abd_ink_muted, hjust = 0.5, margin = margin(t = 8)),
    plot.margin = margin(12, 12, 12, 12)
  )

dir.create(dir_saida, showWarnings = FALSE, recursive = TRUE)

caminho_png <- file.path(dir_saida, "rede_orientacao_historia_direito.png")
caminho_pdf <- file.path(dir_saida, "rede_orientacao_historia_direito.pdf")

ggsave(caminho_png, grafico, width = 11, height = 9, dpi = 300, bg = abd_paper)
# cairo_pdf exige X11/Cairo instalados no sistema (XQuartz no macOS); nem
# sempre disponivel na maquina de quem roda o script. pdf() e base R, sem
# dependencia externa, e ja produz PDF vetorial adequado para artigo.
ggsave(caminho_pdf, grafico, width = 11, height = 9, device = "pdf", bg = abd_paper)

cat("OK:", caminho_png, "\n")
cat("OK:", caminho_pdf, "\n")
