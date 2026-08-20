# server.R

server <- function(input, output, session) {
  busca_server("busca")
  rede_server("rede")
  graficos_server("graficos")
}
