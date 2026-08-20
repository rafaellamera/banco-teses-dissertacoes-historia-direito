# scripts/network_metrics.R
#
# Etapa 2 do pipeline de rede de orientacao: metricas sobre
# data/rede_orientacao_nos.csv e data/rede_orientacao_arestas.csv
# (produzidos por scripts/build_network.R).
#
# Rodar:
#   Rscript scripts/network_metrics.R
#
# Produz:
#   - data/rede_orientacao_evolucao_temporal.csv (item c abaixo)
#   - imprime no console os rankings/itens a e b para conferencia
#
# NAO altera nenhum dos CSVs de entrada.

library(readr)
library(dplyr)

caminho_nos     <- "data/rede_orientacao_nos.csv"
caminho_arestas <- "data/rede_orientacao_arestas.csv"
caminho_evolucao <- "data/rede_orientacao_evolucao_temporal.csv"

nos     <- read_csv(caminho_nos, show_col_types = FALSE)
arestas <- read_csv(caminho_arestas, show_col_types = FALSE)

# --- a. grau de saida por orientador (n de orientandos no corpus) -----------

ranking_orientadores <- nos |>
  filter(n_como_orientador > 0) |>
  arrange(desc(n_como_orientador)) |>
  select(nome_canonico, n_como_orientador, ano_primeira_aparicao, ano_ultima_aparicao)

cat("=== a. Ranking de orientadores por grau de saida ===\n")
cat("Total de orientadores distintos:", nrow(ranking_orientadores), "\n")
print(ranking_orientadores, n = 15)

# --- b. transicao orientando -> orientador -----------------------------------

transicao_geracional <- nos |>
  filter(foi_orientando_no_corpus, foi_orientador_no_corpus) |>
  arrange(desc(n_como_orientador)) |>
  select(nome_canonico, n_como_orientador, n_como_autor, ano_primeira_aparicao, ano_ultima_aparicao)

cat("\n=== b. Transicao orientando -> orientador (evidencia direta) ===\n")
cat("Total:", nrow(transicao_geracional), "de", nrow(ranking_orientadores),
    "orientadores (",
    round(100 * nrow(transicao_geracional) / nrow(ranking_orientadores), 1),
    "% dos orientadores do corpus foram, antes, orientandos no proprio corpus)\n")
print(transicao_geracional)

# --- c. evolucao temporal cumulativa -----------------------------------------
#
# Duas metricas de densidade, deliberadamente distintas, porque medem coisas
# diferentes e uma delas contraria a intuicao antes de ser explicada:
#
#   c1. Densidade classica de grafo dirigido (arestas / n_nos*(n_nos-1)).
#       Esta metrica DECLINA ao longo do tempo -- e um artefato estrutural
#       esperado neste tipo de rede de orientacao, nao um sinal de que o
#       campo esta "menos denso": a cada ano entram dezenas de orientandos
#       novos (nos terminais, que nunca orientam ninguem no corpus) e o
#       denominador (n_nos^2) cresce muito mais rapido que o numerador
#       (arestas). Reportar so esta metrica seria enganoso para o argumento
#       do usuario -- por isso ela e complementada por c2.
#
#   c2. Participacao da "geracao 2+": arestas cujo orientador e alguem que
#       foi, antes, orientando dentro do proprio corpus (ver ranking b).
#       Esta e a metrica que efetivamente evidencia densidade crescente de
#       formacao -- ela so pode crescer ou ficar estavel (e monotona por
#       construcao), nunca cai, e mede algo que a contagem bruta de
#       trabalhos por ano nao mede: quanto da producao recente e sustentada
#       por gente formada dentro do proprio campo, e nao so por orientadores
#       "importados" de fora do corpus.

pessoas_transicao <- nos |>
  filter(foi_orientando_no_corpus, foi_orientador_no_corpus) |>
  pull(nome_canonico)

anos <- seq(min(arestas$ano_base), max(arestas$ano_base))

evolucao <- lapply(anos, function(ano) {
  sub <- arestas |> filter(ano_base <= ano)
  n_orientadores <- n_distinct(sub$orientador)
  n_nos <- n_distinct(c(sub$orientador, sub$orientando))
  n_arestas <- nrow(sub)
  densidade_classica <- if (n_nos > 1) n_arestas / (n_nos * (n_nos - 1)) else NA_real_

  sub_geracao2 <- sub |> filter(orientador %in% pessoas_transicao)
  n_arestas_geracao2 <- nrow(sub_geracao2)
  n_orientadores_geracao2 <- n_distinct(sub_geracao2$orientador)

  tibble(
    ano = ano,
    orientadores_distintos_acumulado = n_orientadores,
    nos_distintos_acumulado = n_nos,
    arestas_acumuladas = n_arestas,
    densidade_classica_acumulada = densidade_classica,
    orientadores_geracao2_acumulado = n_orientadores_geracao2,
    arestas_geracao2_acumuladas = n_arestas_geracao2,
    participacao_geracao2 = if (n_arestas > 0) n_arestas_geracao2 / n_arestas else 0
  )
}) |> bind_rows()

write_csv(evolucao, caminho_evolucao)

cat("\n=== c. Evolucao temporal cumulativa (amostra a cada 5 anos) ===\n")
print(evolucao |> filter(ano %% 5 == 0 | ano == max(ano)), n = Inf, width = Inf)
cat("\nOK:", nrow(evolucao), "linhas gravadas em", caminho_evolucao, "\n")
