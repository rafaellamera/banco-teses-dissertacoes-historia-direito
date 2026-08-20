# global.R
# Carregado uma vez, na inicializacao do app.
# Pacotes, leitura de dados e objetos usados tanto em ui.R quanto em server.R.

library(shiny)
library(bslib)
library(DT)
library(dplyr)
library(readr)
library(stringr)
# Exigido por shiny::includeMarkdown() (aba "Sobre a metodologia"). Nunca chamado
# diretamente no código, então precisa de library() explícito para que o rsconnect
# detecte a dependência e instale no servidor (ver deploy no shinyapps.io).
library(markdown)
# Usados pelo módulo de rede de orientação (R/mod_rede.R): visNetwork para o
# grafo interativo, igraph só para calcular o layout (posição x/y de cada nó)
# uma única vez aqui, na inicialização — o mesmo motivo do library(markdown)
# acima se aplica: sem chamada explícita, o rsconnect não detecta a dependência.
library(visNetwork)
library(igraph)
# Usados pelo módulo de gráficos (R/mod_graficos.R): ggplot2 para montar os
# gráficos, svglite só para o download em SVG (ggsave chama o pacote por
# baixo dos panos quando device="svg", sem library() explícito aqui).
library(ggplot2)
library(svglite)

# --- Dados -------------------------------------------------------------
# CSV produzido por scripts/prepare_data.R a partir da planilha original.
corpus <- read_csv(
  "data/corpus_historia_direito_1994_2024.csv",
  show_col_types = FALSE
)

# --- Funcao auxiliar: busca textual insensivel a acento e caixa --------
remover_acentos <- function(x) {
  x <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT")
  str_to_lower(x)
}

# --- Vetores usados para popular os filtros (calculados uma unica vez) -
faixa_anos      <- range(corpus$ano_base, na.rm = TRUE)
lista_tipo      <- sort(unique(corpus$tipo_normalizado))
lista_programas <- sort(unique(corpus$nome_programa))
lista_ies       <- sort(unique(corpus$ies))
lista_regiao    <- sort(unique(corpus$regiao))
lista_uf        <- sort(unique(corpus$uf))

n_total <- nrow(corpus)

# Rótulos do checkbox de Região com contagem, para exibição inicial
# (recalculados dinamicamente pelo mod_busca.R conforme os demais filtros).
regiao_choices_iniciais <- setNames(
  lista_regiao,
  sprintf("%s (%d)", lista_regiao, as.integer(table(factor(corpus$regiao, levels = lista_regiao))))
)

# --- Rede de orientação (genealogia acadêmica) --------------------------
# CSVs produzidos por scripts/build_network.R a partir do corpus acima
# (ver esse script para a metodologia de normalização de nomes e as
# decisões confirmadas sobre coorientação/duplicatas de grafia).
rede_nos     <- read_csv("data/rede_orientacao_nos.csv", show_col_types = FALSE)
rede_arestas <- read_csv("data/rede_orientacao_arestas.csv", show_col_types = FALSE)
faixa_anos_rede <- range(rede_arestas$ano_base, na.rm = TRUE)

# Layout (posição x/y de cada nó) calculado uma única vez sobre o grafo
# completo, para que a posição de cada pessoa fique estável enquanto o
# slider de ano cumulativo (mod_rede.R) vai revelando mais nós — sem isso,
# a rede "pularia" a cada mudança de ano em vez de crescer visivelmente.
grafo_rede_completo <- graph_from_data_frame(
  d = rede_arestas |> select(orientador, orientando),
  vertices = rede_nos |> select(nome_canonico),
  directed = TRUE
)
set.seed(42) # mesma semente do script estático (scripts/plot_network.R)
coords_rede <- layout_with_fr(grafo_rede_completo) * 60
rede_nos <- rede_nos |>
  mutate(
    layout_x = coords_rede[match(nome_canonico, V(grafo_rede_completo)$name), 1],
    layout_y = coords_rede[match(nome_canonico, V(grafo_rede_completo)$name), 2]
  )

# --- Módulos -------------------------------------------------------------
source("R/mod_busca.R")
source("R/mod_contribuicao.R")
source("R/mod_rede.R")
source("R/mod_graficos.R")
