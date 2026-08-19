# Banco de Teses e Dissertações em História do Direito (1994-2024)

Aplicativo Shiny para busca e download de um corpus de 420 teses e dissertações em
História do Direito, produzidas em Programas de Pós-Graduação em Direito no Brasil
entre 1994 e 2024.

## Acesso ao aplicativo

🔗 [Banco de Teses e Dissertações em História do Direito](https://rafaellamera.shinyapps.io/banco-teses-dissertacoes-historia-direito/)

## O que você pode fazer

Filtrar por ano de defesa, tipo de pesquisa (mestrado/doutorado), programa de
pós-graduação, instituição (IES), região e UF. Buscar por título, autoria, orientação
e assunto (busca no resumo e no título). Baixar os resultados filtrados ou a base
completa em CSV.

## Fonte dos dados

Os dados sobre teses e dissertações da CAPES são públicos e estão disponíveis na Plataforma Sucupira. A seleção de teses e dissertações na área da História do Direito foi organizada a partir de algumas etapas.

A primeira consistiu em selecionar, dentro do corpus principal, os produtos vinculados a programas de pós-graduação exclusivamente da área do Direito na CAPES; programas interdisciplinares não foram incluídos. No recorte temporal do projeto de pesquisa, foram selecionadas 68.108 teses e dissertações da área do Direito.

O marco inicial de 1994 é importante por ser o primeiro momento de indução do conteúdo de História do Direito na estrutura curricular dos cursos de Direito no Brasil. O ano de 2024 fecha os 30 anos de manutenção do conteúdo de História do Direito nos componentes curriculares dos cursos de Direito e corresponde também aos últimos dados disponíveis na Plataforma Sucupira em março de 2026, época do levantamento.

Com esse corpus, aplicamos um filtro sobre títulos e resumos (os únicos dados extraídos diretamente do conteúdo das pesquisas e disponíveis na Plataforma Sucupira), com o uso de quatro descritores: história, historiografia, historiográfico e cultura jurídica. A partir desse filtro, o corpus foi reduzido para 4.246 produtos.

A segunda etapa consistiu em qualificar, de forma automatizada, o que é história do direito e como o campo se organiza, a fim de identificar quais pesquisas deveriam ser selecionadas. Essa etapa foi coliderada pelo Prof. Dr. Ulisses Levy Silvério dos Reis (PPGD-UFERSA), especialista em ciência de dados aplicada ao Direito. Os índices de confiabilidade variaram de 5 a 10 e foram validados manualmente pelo pesquisador.

O resultado inicial compreende 420 teses e dissertações. Para mais detalhes, veja a aba "Sobre a metodologia" dentro do aplicativo.

## Reprodução local

**Requisitos:** R (>= 4.2) e os seguintes pacotes:

```r
install.packages(c(
  "shiny", "bslib", "DT", "dplyr", "readr", "stringr", "readxl"
))
```

**Passo 1. Preparar os dados** (só é necessário se você alterar a planilha original;
o repositório já inclui `data/corpus_historia_direito_1994_2024.csv` pronto):

```
mkdir -p data-raw
# copie a planilha original (aba "Corpus unificado v1") para data-raw/Base de dados consolidada 17ago.xlsx
Rscript scripts/prepare_data.R
```

**Passo 2. Rodar o app**, a partir da raiz do projeto:

```r
shiny::runApp()
```

## Estrutura do projeto

```
.
├── global.R              # pacotes, leitura de dados, constantes, carrega os módulos
├── ui.R                  # interface principal (masthead, módulos, rodapé)
├── server.R              # inicializa os módulos
├── R/
│   ├── mod_busca.R        # módulo: filtros, tabela, detalhe em modal, downloads
│   └── mod_contribuicao.R # módulo: banner "Sua tese não está aqui?" (link para Google Forms)
├── data/
│   └── corpus_historia_direito_1994_2024.csv   # dado que o app efetivamente lê
├── data-raw/              # planilha original (não versionada, ver .gitignore)
├── scripts/
│   └── prepare_data.R     # pipeline de limpeza: xlsx -> csv
├── www/
│   ├── sobre.md            # conteúdo da aba "Sobre a metodologia"
│   ├── styles.css          # identidade visual
│   └── fonts/              # Libre Franklin e Source Serif 4 (.woff2, locais)
├── LICENSE
└── README.md
```

## Deploy (shinyapps.io)

```r
install.packages("rsconnect")
rsconnect::setAccountInfo(name = "[preencher]", token = "[preencher]", secret = "[preencher]")
rsconnect::deployApp()
```

## Transformações aplicadas aos dados originais

Documentadas em `scripts/prepare_data.R`: remoção de espaços em branco nas bordas,
padronização de `nome_programa` para caixa alta, padronização de `idioma`
("Português"/"Inglês", ignorando acentuação e caixa) e atribuição de um identificador
estável (`id`) por linha. Nenhum conteúdo de título, resumo, autoria ou orientação é
alterado.

## Decisões de desenho pendentes de validação

- A coluna `tipo_normalizado` (Dissertação/Tese) é usada como filtro de nível; a
  coluna `tipo` original (mista) é mantida no CSV apenas para rastreabilidade.
- As colunas `confianca`, `origem`, `justificativa` e `lote` são metadados do
  processo de classificação do corpus, não do trabalho em si. Por padrão ficam
  ocultas na tabela; `confianca` e `origem` podem ser exibidas via checkbox na
  interface. `justificativa` e `lote` não são exibidas na UI atual.
- Limiar de `confianca` para inclusão no corpus: nota 5 ou maior (ver aba "Sobre a
  metodologia" no app). Os 420 registros da aba "Corpus unificado v1" já respeitam
  esse limiar; nenhum corte adicional é aplicado pelo app.

## Identidade visual

Direção editorial, inspirada na tipografia e no layout de jornalismo impresso (New York
Times como referência), sem reproduzir marca ou fonte proprietária de terceiros.

- **Cor:** tinta `#121212`, papel `#fbfaf7`, papel-secundário `#f1ede3`, fio `#d9d2c2`,
  vermelho-selo `#9a2020` (uso restrito a kicker, botão primário e seleção).
- **Tipografia:** Libre Franklin (mesma linhagem tipográfica — Franklin Gothic — da
  fonte proprietária usada pelo NYT) para interface e tabela; Source Serif 4 para
  masthead, título de registro e corpo do resumo. Ambas variable fonts, arquivos
  `.woff2` embutidos em `www/fonts/` (baixados uma vez do Google Fonts, subconjunto
  latin) — o app roda sem acesso à internet no navegador, exceto para o mapa de
  ícones (Font Awesome, empacotado com o `shiny`, também local).
- **Assinatura:** ao selecionar um registro na tabela, ele abre em um modal como uma
  "matéria" (kicker com IES/programa, título, linha de autoria/orientação, linha de
  data, resumo com capitular), definido em `www/styles.css` (classes `.abd-record-*`)
  e montado em `R/mod_busca.R`.

Identidade visual verificada rodando o app de fato no navegador: fundo da barra
lateral, tipografia e o modal de detalhe conferidos visualmente.

## Agradecimentos

Esse projeto foi possível a partir da integração e apoio dos pesquisadores do [Observatório dos Direitos Sociais do Semiárido](https://www.odss.ufersa.edu.br) e do Projeto DATALAB-ODSS, que inova no uso de tecnologias aplicadas para o Direito.

## Licença

[MIT](LICENSE).

## Como citar

CABRAL, Rafael Lamera Giesta. Banco de Teses e Dissertações em História do Direito (1994-2024). Aplicativo Shiny interativo. Observatório dos Direitos Sociais do Semiárido / DATALAB-ODSS / PPGD-UFERSA, 2026. Disponível em: https://rafaellamera.shinyapps.io/banco-teses-dissertacoes-historia-direito/. Acesso em: [data].
