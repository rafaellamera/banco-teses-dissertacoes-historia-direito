# global.R
# Carregado uma vez, na inicializacao do app.
# Pacotes, leitura de dados e objetos usados tanto em ui.R quanto em server.R.

library(shiny)
library(bslib)
library(DT)
library(dplyr)
library(readr)
library(stringr)

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

# --- Módulos -------------------------------------------------------------
source("R/mod_busca.R")
source("R/mod_contribuicao.R")
