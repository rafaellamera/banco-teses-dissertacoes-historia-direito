# scripts/prepare_data.R
#
# Le a planilha original (aba "Corpus unificado v1") e produz
# data/corpus_historia_direito_1994_2024.csv, que e o arquivo que
# o app efetivamente le (ver global.R).
#
# Rodar UMA VEZ (ou sempre que a planilha original for atualizada):
#   Rscript scripts/prepare_data.R
#
# Transformacoes aplicadas (documentadas para fins de transparencia
# metodologica, ver aba "Sobre e metodologia" no app):
#   1. remove espacos em branco nas bordas de todas as colunas de texto
#   2. padroniza nome_programa para caixa alta (unifica "Direito" e "DIREITO")
#   3. padroniza idioma para "Portugues"/"Ingles", ignorando acentuacao e caixa
#   4. ordena por ano_base, ies, titulo e atribui um id estavel (1..n)
#   5. NAO altera tipo (bruto), titulo, resumo, autoria, orientacao:
#      o nivel harmonizado (mestrado/doutorado) ja vem pronto na coluna
#      tipo_normalizado, produzida na etapa de classificacao anterior a este
#      script, e e essa a coluna que o app usa como filtro de "Tipo de pesquisa"

library(readxl)
library(dplyr)
library(stringr)
library(readr)

caminho_origem <- "data-raw/Base de dados consolidada 17ago.xlsx"
caminho_saida  <- "data/corpus_historia_direito_1994_2024.csv"

if (!file.exists(caminho_origem)) {
  stop(
    "Planilha original nao encontrada em ", caminho_origem, ".\n",
    "Copie o arquivo .xlsx original para a pasta data-raw/ antes de rodar este script."
  )
}

remover_acentos <- function(x) {
  iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT")
}

canonicalizar_idioma <- function(x) {
  chave <- str_to_lower(str_trim(remover_acentos(x)))
  case_when(
    chave == "portugues" ~ "Portugu\u00eas",
    chave == "ingles"    ~ "Ingl\u00eas",
    TRUE                 ~ str_trim(x)
  )
}

corpus_bruto <- read_excel(caminho_origem, sheet = "Corpus unificado v1")

corpus <- corpus_bruto |>
  mutate(across(where(is.character), str_trim)) |>
  mutate(
    nome_programa = str_to_upper(nome_programa),
    idioma        = canonicalizar_idioma(idioma)
  ) |>
  arrange(ano_base, ies, titulo) |>
  mutate(id = row_number(), .before = 1) |>
  select(
    id, ano_base, tipo_normalizado, tipo, titulo, resumo,
    autoria, orientacao, ies, nome_programa, area,
    regiao, uf, idioma, confianca, origem, justificativa, lote
  )

dir.create(dirname(caminho_saida), showWarnings = FALSE, recursive = TRUE)
write_csv(corpus, caminho_saida)

cat("OK:", nrow(corpus), "linhas gravadas em", caminho_saida, "\n")
