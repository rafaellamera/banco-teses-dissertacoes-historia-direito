# scripts/build_network.R
#
# Le data/corpus_historia_direito_1994_2024.csv e produz a rede de
# orientacao (genealogia academica) do corpus de Historia do Direito:
#   - data/rede_orientacao_nos.csv
#   - data/rede_orientacao_arestas.csv
#
# Rodar:
#   Rscript scripts/build_network.R
#
# NAO altera data/corpus_historia_direito_1994_2024.csv.
#
# ---------------------------------------------------------------------------
# Diagnostico previo (Etapa 0, feito fora deste script, sobre os 420
# registros) e decisoes confirmadas pelo usuario antes da normalizacao
# abaixo ser travada:
#
#   1. Coorientacao: 0 casos. Nenhum delimitador (";", "/", " e ", "&",
#      quebra de linha, virgula, parenteses) foi encontrado no campo
#      `orientacao`. Cada linha do corpus vira exatamente UMA aresta
#      orientador -> orientando.
#
#   2. Duplicatas de grafia (mesma pessoa, strings diferentes):
#      a. 32 pares que colapsam automaticamente ao normalizar caixa e
#         acentuacao (ex.: "RICARDO MARCELO FONSECA" / "Ricardo Marcelo
#         Fonseca") -- tratados pela normalizacao generica abaixo.
#      b. 2 merges adicionais confirmados manualmente (nome parcial vs.
#         nome completo, ver ALIAS_MANUAL abaixo):
#           - "RAFAEL LAMERA CABRAL" -> "Rafael Lamera Giesta Cabral"
#             (autor da tese de doutorado UnB/2016, orientado por
#             Cristiano Paixao; reaparece como orientador na UFERSA sob
#             o nome completo)
#           - "VERA MALAGUTI DE SOUZA WEGLINSKI" -> "Vera Malaguti de
#             Souza Weglinski Batista"
#      c. "Paulo Santos" (UGF, 2002) e "Joao Paulo Santos Araujo" (UnB,
#         2022) foram avaliados e MANTIDOS SEPARADOS -- 20 anos de
#         intervalo, instituicoes e orientadores distintos, nome comum
#         demais para inferir identidade unica. Nao ha alias para este
#         par.
#
#   3. Nenhuma outra inferencia de identidade (por IES, por ano, etc.)
#      foi aplicada alem do que esta listado acima.
# ---------------------------------------------------------------------------

library(readr)
library(dplyr)
library(stringr)
library(stringi)
library(tidyr)

caminho_corpus <- "data/corpus_historia_direito_1994_2024.csv"
caminho_nos     <- "data/rede_orientacao_nos.csv"
caminho_arestas <- "data/rede_orientacao_arestas.csv"

if (!file.exists(caminho_corpus)) {
  stop("Corpus nao encontrado em ", caminho_corpus, ". Rode scripts/prepare_data.R antes.")
}

corpus <- read_csv(caminho_corpus, show_col_types = FALSE)

# --- normalizacao de nomes -------------------------------------------------

# NB: iconv(x, "UTF-8", "ASCII//TRANSLIT") foi testado e descartado aqui --
# no libiconv do macOS ele transforma "i" acentuado em "'i" em vez de
# remover o acento (comportamento diferente do glibc/Linux), o que colapsava
# incorretamente pares de nomes. stri_trans_general() e consistente entre
# plataformas.
remover_acentos <- function(x) stri_trans_general(x, "Latin-ASCII")

chave_normalizada <- function(x) {
  x |>
    remover_acentos() |>
    str_to_lower() |>
    str_replace_all("[.\\-]", "") |>
    str_squish()
}

# Aliases manuais confirmados na Etapa 0 (item 2b acima). A chave e a
# forma normalizada do nome parcial/variante; o valor e a chave
# normalizada do nome canonico escolhido.
ALIAS_MANUAL <- c(
  "rafael lamera cabral"              = "rafael lamera giesta cabral",
  "vera malaguti de souza weglinski"  = "vera malaguti de souza weglinski batista"
)

aplicar_alias <- function(chave) {
  ifelse(chave %in% names(ALIAS_MANUAL), ALIAS_MANUAL[chave], chave)
}

# Titulo em portugues preservando conectores em minuscula (de/da/do/...),
# usado apenas como fallback para escolher o nome de exibicao quando
# nenhuma variante do corpus ja vem em caixa mista.
CONECTORES <- c("de", "da", "do", "das", "dos", "e")

titulo_pt <- function(x) {
  palavras <- str_split(str_to_lower(x), " ")[[1]]
  palavras <- ifelse(
    palavras %in% CONECTORES,
    palavras,
    str_to_title(palavras)
  )
  palavras[1] <- str_to_title(palavras[1])
  str_c(palavras, collapse = " ")
}

# Overrides explicitos de nome canonico para os dois merges manuais
# (evita depender do titulo_pt() para pessoas cuja grafia correta ja e
# conhecida de outra fonte).
CANONICO_MANUAL <- c(
  "rafael lamera giesta cabral"             = "Rafael Lamera Giesta Cabral",
  "vera malaguti de souza weglinski batista" = "Vera Malaguti de Souza Weglinski Batista"
)

escolher_nome_canonico <- function(variantes) {
  chave <- chave_normalizada(variantes[1])
  if (chave %in% names(CANONICO_MANUAL)) {
    return(unname(CANONICO_MANUAL[chave]))
  }
  caixa_mista <- variantes[variantes != str_to_upper(variantes)]
  if (length(caixa_mista) > 0) {
    return(caixa_mista[[which.max(nchar(caixa_mista))]])
  }
  titulo_pt(variantes[[which.max(nchar(variantes))]])
}

# --- monta o dicionario nome bruto -> nome canonico -------------------------

nomes_brutos <- corpus |>
  select(autoria, orientacao) |>
  pivot_longer(everything(), values_to = "nome_bruto") |>
  distinct(nome_bruto) |>
  mutate(chave = aplicar_alias(chave_normalizada(nome_bruto)))

dicionario_canonico <- nomes_brutos |>
  group_by(chave) |>
  summarise(nome_canonico = escolher_nome_canonico(nome_bruto), .groups = "drop")

nomes_brutos <- nomes_brutos |>
  left_join(dicionario_canonico, by = "chave") |>
  select(nome_bruto, nome_canonico)

canonizar <- function(x) {
  nomes_brutos$nome_canonico[match(x, nomes_brutos$nome_bruto)]
}

# --- tabela de arestas -------------------------------------------------------
# Uma linha do corpus = uma aresta orientador -> orientando (sem
# coorientacao a separar, ver item 1 acima).

arestas <- corpus |>
  transmute(
    orientador = canonizar(orientacao),
    orientando = canonizar(autoria),
    ano_base,
    tipo_normalizado,
    ies,
    nome_programa
  )

# --- tabela de nos ------------------------------------------------------------

como_orientador <- arestas |>
  count(nome_canonico = orientador, name = "n_como_orientador")

como_autor <- arestas |>
  count(nome_canonico = orientando, name = "n_como_autor")

anos_orientador <- arestas |>
  group_by(nome_canonico = orientador) |>
  summarise(ano_min_or = min(ano_base), ano_max_or = max(ano_base), .groups = "drop")

anos_autor <- arestas |>
  group_by(nome_canonico = orientando) |>
  summarise(ano_min_au = min(ano_base), ano_max_au = max(ano_base), .groups = "drop")

nos <- dicionario_canonico |>
  distinct(nome_canonico) |>
  left_join(como_orientador, by = "nome_canonico") |>
  left_join(como_autor, by = "nome_canonico") |>
  left_join(anos_orientador, by = "nome_canonico") |>
  left_join(anos_autor, by = "nome_canonico") |>
  mutate(
    n_como_orientador = coalesce(n_como_orientador, 0L),
    n_como_autor = coalesce(n_como_autor, 0L),
    ano_primeira_aparicao = pmin(ano_min_or, ano_min_au, na.rm = TRUE),
    ano_ultima_aparicao = pmax(ano_max_or, ano_max_au, na.rm = TRUE),
    foi_orientando_no_corpus = n_como_autor > 0,
    foi_orientador_no_corpus = n_como_orientador > 0
  ) |>
  select(
    nome_canonico, n_como_orientador, n_como_autor,
    ano_primeira_aparicao, ano_ultima_aparicao,
    foi_orientando_no_corpus, foi_orientador_no_corpus
  ) |>
  arrange(desc(n_como_orientador), nome_canonico)

# --- escreve saidas -----------------------------------------------------------

dir.create(dirname(caminho_nos), showWarnings = FALSE, recursive = TRUE)
write_csv(nos, caminho_nos)
write_csv(arestas, caminho_arestas)

cat("OK:", nrow(nos), "nos gravados em", caminho_nos, "\n")
cat("OK:", nrow(arestas), "arestas gravadas em", caminho_arestas, "\n")

transicao <- nos |> filter(foi_orientando_no_corpus, foi_orientador_no_corpus)
cat("\nPessoas com transicao orientando -> orientador no corpus:", nrow(transicao), "\n")
print(transicao |> select(nome_canonico, n_como_orientador, ano_primeira_aparicao, ano_ultima_aparicao))
