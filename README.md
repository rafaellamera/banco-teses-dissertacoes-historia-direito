# Banco de Teses e Dissertações em História do Direito (1994-2024)

Aplicativo Shiny para busca e download de um corpus de 420 teses e dissertações em
História do Direito, produzidas em Programas de Pós-Graduação em Direito no Brasil
entre 1994 e 2024.

## Acesso ao aplicativo

[preencher após o deploy: link do shinyapps.io]

## O que você pode fazer

Filtrar por ano de defesa, tipo de pesquisa (mestrado/doutorado), programa de
pós-graduação, instituição (IES), região e UF. Buscar por título, autoria, orientação
e assunto (busca no resumo e no título). Baixar os resultados filtrados ou a base
completa em CSV.

## Fonte dos dados

Ver aba "Sobre e metodologia" dentro do aplicativo.

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
# copie a planilha original para data-raw/4_trabalhos_historia_direito_1994_2024_classificados.xlsx
Rscript scripts/prepare_data.R
```

**Passo 2. Rodar o app**, a partir da raiz do projeto:

```r
shiny::runApp()
```

## Estrutura do projeto

```
.
├── global.R              # pacotes, leitura de dados, constantes
├── ui.R                  # interface
├── server.R              # lógica reativa
├── data/
│   └── corpus_historia_direito_1994_2024.csv   # dado que o app efetivamente lê
├── data-raw/              # planilha original (não versionada, ver .gitignore)
├── scripts/
│   └── prepare_data.R     # pipeline de limpeza: xlsx -> csv
├── www/
│   └── sobre.md            # conteúdo da aba "Sobre e metodologia"
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
- Nenhum corte por `confianca` foi aplicado: os 420 registros da aba "Corpus
  unificado v1" foram tratados como a amostra final. Se isso não corresponder à
  intenção do projeto, é preciso decidir um limiar e reprocessar.

## Identidade visual

Direção editorial, inspirada na tipografia e no layout de jornalismo impresso (New York
Times como referência), sem reproduzir marca ou fonte proprietária de terceiros.

- **Cor:** tinta `#121212`, papel `#fbfaf7`, papel-secundário `#f1ede3`, fio `#d9d2c2`,
  vermelho-selo `#9a2020` (uso restrito a kicker, botão primário e seleção).
- **Tipografia:** Libre Franklin (Google Fonts, mesma linhagem tipográfica — Franklin
  Gothic — da fonte proprietária usada pelo NYT) para interface e tabela; Source
  Serif 4 (Google Fonts) para masthead, título de registro e corpo do resumo.
- **Assinatura:** ao selecionar um registro na tabela, ele abre como uma "matéria"
  (kicker com IES/programa, título, linha de autoria/orientação, linha de data,
  resumo com capitular), definido em `www/styles.css` (classes `.abd-record-*`) e
  montado em `server.R` (`output$detalhe`).

Ambas as fontes são carregadas via Google Fonts (`ui.R`), o que exige acesso à
internet no navegador de quem usa o app; não é necessário instalar nada em R para
isso.

**Aviso de verificação:** o ambiente usado para gerar este projeto não tem R
instalado, então o CSS foi escrito mas não pôde ser visualmente conferido rodando o
app de fato. Os seletores usados para o fundo da barra lateral (`.bslib-sidebar-layout
> .sidebar` e variantes) cobrem as versões mais comuns do bslib, mas se a cor de fundo
da barra lateral não aparecer ao rodar localmente, abra o DevTools do navegador,
identifique a classe real do elemento `<aside>` gerado e ajuste esse seletor em
`www/styles.css`.

## Licença

[MIT](LICENSE).

## Como citar

Ver aba "Sobre e metodologia" dentro do aplicativo.
