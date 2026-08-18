# server.R

server <- function(input, output, session) {
  busca_server("busca")
  contribuicao_server("contribuicao")
}
