# Modulo de Estoque (EST)

## Visao Geral

O modulo de Estoque (SIGAEST) do TOTVS Protheus gerencia todo o controle de materiais da empresa, desde o cadastro de produtos ate a movimentacao fisica e financeira dos itens em armazem. Ele abrange recebimento, armazenagem, movimentacoes internas (requisicoes, devolucoes, transferencias), controle de lotes, inventario fisico, enderecamento (WMS) e calculo de custos, integrando-se diretamente com os modulos de Compras, Faturamento, PCP, Fiscal e Contabilidade.

**Prefixo do modulo:** EST
**Sigla do ambiente:** SIGAEST
**Prefixo das rotinas:** MATA0xx / MATA2xx / MATA3xx (ex: MATA010, MATA220, MATA240, MATA261, MATA330)

### Ciclo principal de estoque

```
Cadastro de Produto → Recebimento (Entrada) → Armazenagem/Enderecamento → Movimentacao Interna → Inventario → Expedicao (Saida)
```

O modulo controla saldos fisicos e financeiros por armazem (SB2), por lote (SB8) e por endereco (SBF), permitindo rastreabilidade completa de materiais desde a entrada ate o consumo ou venda.

---

## Tabelas Principais

### SB1 - Cadastro de Produtos

Tabela mestre de produtos. Armazena todas as informacoes basicas dos itens (materias-primas, produtos acabados, intermediarios, servicos, ativos, etc.). E compartilhada entre todos os modulos do Protheus.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| B1_FILIAL | C | 8 | Filial |
| B1_COD | C | 15 | Codigo do produto |
| B1_DESC | C | 30 | Descricao do produto |
| B1_TIPO | C | 2 | Tipo: PA=Prod.Acabado, MP=Mat.Prima, PI=Prod.Intermediario, MC=Mat.Consumo, BN=Beneficiamento, GG=Gastos Gerais, SV=Servico, MO=Mao de Obra |
| B1_UM | C | 2 | Unidade de medida |
| B1_LOCPAD | C | 2 | Armazem padrao |
| B1_GRUPO | C | 4 | Grupo de produto |
| B1_CONTA | C | 20 | Conta contabil |
| B1_CUSTD | N | 14,2 | Custo standard |
| B1_UCALSTD | D | 8 | Data do ultimo calculo do custo standard |
| B1_UCOM | C | 2 | Unidade de medida de compra |
| B1_CONV | N | 7,2 | Fator de conversao (UM compra → UM estoque) |
| B1_CODBAR | C | 15 | Codigo de barras (EAN/GTIN) |
| B1_RASTRO | C | 1 | Rastreabilidade: L=Lote, S=Sublote, branco=Nao |
| B1_LOCALIZ | C | 1 | Controle de enderecamento: S=Sim, N=Nao |
| B1_PESO | N | 11,4 | Peso liquido |
| B1_PESBRU | N | 11,4 | Peso bruto |
| B1_ESTSEG | N | 12,2 | Estoque de seguranca |
| B1_EMIN | N | 12,2 | Estoque minimo (ponto de pedido) |
| B1_EMAX | N | 12,2 | Estoque maximo |
| B1_LE | N | 12,2 | Lote economico |
| B1_LM | N | 12,2 | Lote minimo |
| B1_IMPORT | C | 1 | Produto importado (S/N) |
| B1_ORIGEM | C | 1 | Origem: 0=Nacional, 1=Estrangeira-Import.Direta, 2=Estrangeira-Merc.Interno |
| B1_IPI | N | 5,2 | Percentual de IPI |
| B1_NCM | C | 10 | Classificacao fiscal (NCM) |
| B1_POSIPI | C | 10 | Posicao IPI (NCM antigo) |
| B1_MSBLQL | C | 1 | Produto bloqueado (1=Sim, 2=Nao) |
| B1_REVATU | C | 3 | Revisao atual da estrutura |
| B1_DATREF | D | 8 | Data de referencia |
| B1_FANTASM | C | 1 | Produto fantasma (S/N) |
| B1_CEST | C | 7 | Codigo CEST |
| B1_PRESSION | C | 1 | Produto de producao (S/N) |
| B1_MRP | C | 1 | Utiliza MRP (S/N) |
| B1_APROPRI | C | 1 | Tipo de apropriacao: D=Direto, I=Indireto |
| B1_TIPCONV | C | 1 | Tipo de conversao: M=Multiplica, D=Divide |
| B1_CODISS | C | 9 | Codigo ISS |
| B1_CLASFIS | C | 10 | Classe fiscal |

**Indices principais:**
- Ordem 1: `B1_FILIAL + B1_COD`
- Ordem 2: `B1_FILIAL + B1_DESC`
- Ordem 3: `B1_FILIAL + B1_GRUPO + B1_COD`
- Ordem 4: `B1_FILIAL + B1_TIPO + B1_COD`
- Ordem 5: `B1_FILIAL + B1_CODBAR`

---

### SB2 - Saldos por Armazem

Armazena os saldos fisicos e financeiros de cada produto em cada armazem. Atualizada automaticamente a cada movimentacao de estoque.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| B2_FILIAL | C | 8 | Filial |
| B2_COD | C | 15 | Codigo do produto |
| B2_LOCAL | C | 2 | Codigo do armazem |
| B2_QATU | N | 14,2 | Quantidade atual em estoque |
| B2_QEMP | N | 14,2 | Quantidade empenhada (reservada para OP/pedidos) |
| B2_QNPT | N | 14,2 | Quantidade em poder de terceiros |
| B2_QQDT | N | 14,2 | Quantidade de terceiros em nosso poder |
| B2_RESERV | N | 14,2 | Quantidade reservada |
| B2_VATU1 | N | 14,2 | Valor atual (custo medio) |
| B2_VATU2 | N | 14,2 | Valor atual (custo standard) |
| B2_VATU3 | N | 14,2 | Valor atual (ultimo preco) |
| B2_VATU4 | N | 14,2 | Valor atual (medio ponderado) |
| B2_VATU5 | N | 14,2 | Valor atual (FIFO/PEPS) |
| B2_CM1 | N | 14,2 | Custo medio unitario |
| B2_DMOV | D | 8 | Data da ultima movimentacao |
| B2_HMOV | C | 5 | Hora da ultima movimentacao |
| B2_DINVENT | D | 8 | Data do ultimo inventario |
| B2_QINVENT | N | 14,2 | Quantidade contada no inventario |
| B2_SESSION | C | 1 | Status do inventario: branco=Normal, I=Inventariando |
| B2_QPROD | N | 14,2 | Quantidade prevista para producao |
| B2_QSEG | N | 14,2 | Estoque de seguranca |

**Indices principais:**
- Ordem 1: `B2_FILIAL + B2_COD + B2_LOCAL`
- Ordem 2: `B2_FILIAL + B2_LOCAL + B2_COD`

---

### SB5 - Dados Complementares do Produto

Armazena informacoes complementares do produto que nao cabem na SB1, como dados tributarios, informacoes de importacao/exportacao, dados logisticos e texto livre.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| B5_FILIAL | C | 8 | Filial |
| B5_COD | C | 15 | Codigo do produto |
| B5_CEME | C | 60 | Descricao em ingles (ou nome generico) |
| B5_CODBAR | C | 15 | Codigo de barras complementar |
| B5_FORNE | C | 6 | Fornecedor padrao |
| B5_LOTEFN | C | 2 | Loja do fornecedor padrao |
| B5_COMPR | N | 11,4 | Comprimento |
| B5_LARG | N | 11,4 | Largura |
| B5_ALTURA | N | 11,4 | Altura |
| B5_PRESSION | N | 11,4 | Volume |
| B5_INI | D | 8 | Data inicio de validade |
| B5_FIM | D | 8 | Data fim de validade |
| B5_SITPROD | C | 1 | Situacao do produto |
| B5_INSTAM | C | 3 | Instrucoes de armazenagem |
| B5_CLASRIS | C | 2 | Classe de risco |
| B5_ONU | C | 5 | Numero ONU (produtos perigosos) |
| B5_PRESSEN | C | 1 | Produto sensivel (S/N) |

**Indices principais:**
- Ordem 1: `B5_FILIAL + B5_COD`

---

### SD3 - Movimentacoes Internas

Registra todas as movimentacoes internas de estoque: requisicoes, devolucoes, transferencias, producao, ajustes de inventario. E a tabela central de historico de movimentacao.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| D3_FILIAL | C | 8 | Filial |
| D3_DOC | C | 9 | Numero do documento |
| D3_COD | C | 15 | Codigo do produto |
| D3_LOCAL | C | 2 | Armazem |
| D3_QUANT | N | 12,4 | Quantidade movimentada |
| D3_CUSTO1 | N | 14,2 | Custo medio |
| D3_CUSTO2 | N | 14,2 | Custo standard |
| D3_CUSTO3 | N | 14,2 | Ultimo preco |
| D3_CUSTO4 | N | 14,2 | Medio ponderado |
| D3_CUSTO5 | N | 14,2 | FIFO/PEPS |
| D3_TM | C | 3 | Tipo de movimentacao (TM) |
| D3_CF | C | 3 | Tipo RE/DE (Requisicao/Devolucao): RE0-RE9, DE0-DE9 |
| D3_EMISSAO | D | 8 | Data de emissao |
| D3_OP | C | 13 | Ordem de producao vinculada |
| D3_CC | C | 9 | Centro de custo |
| D3_CONTA | C | 20 | Conta contabil |
| D3_CLVL | C | 9 | Classe de valor |
| D3_ITEMCTA | C | 9 | Item contabil |
| D3_NUMSEQ | C | 6 | Sequencia da movimentacao |
| D3_LOTECTL | C | 10 | Lote de controle |
| D3_NUMLOTE | C | 6 | Sublote |
| D3_LOCALIZ | C | 15 | Endereco de estoque |
| D3_USUARIO | C | 15 | Usuario responsavel |
| D3_ESTORNO | C | 1 | Movimento de estorno (S/N) |
| D3_GRUPO | C | 4 | Grupo de produto |
| D3_UM | C | 2 | Unidade de medida |
| D3_LOCEST | C | 2 | Armazem destino (transferencia) |
| D3_NFISCAL | C | 9 | Numero da NF (quando originado de NF) |
| D3_SERIE | C | 3 | Serie da NF |

**Indices principais:**
- Ordem 1: `D3_FILIAL + D3_DOC + D3_COD + D3_NUMSEQ`
- Ordem 2: `D3_FILIAL + D3_COD + D3_LOCAL + D3_DOC`
- Ordem 3: `D3_FILIAL + D3_EMISSAO + D3_COD + D3_DOC`
- Ordem 4: `D3_FILIAL + D3_OP + D3_COD`
- Ordem 5: `D3_FILIAL + D3_CC + D3_EMISSAO`

**Tipos de movimentacao (D3_CF):**
- `RE0` a `RE9`, `REA`: Requisicoes (saida interna) - codigos 500 a 998
- `DE0` a `DE9`: Devolucoes (entrada interna) - codigos 001 a 499
- `999`: Reservado para atualizacoes automaticas do sistema (ex: transferencias entre armazens)

---

### SBZ - Indicadores de Produtos por Filial

Armazena indicadores de produto exclusivos por filial, permitindo o compartilhamento do catalogo de produtos (SB1) entre filiais enquanto mantem parametros individuais.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| BZ_FILIAL | C | 8 | Filial |
| BZ_COD | C | 15 | Codigo do produto |
| BZ_LOCPAD | C | 2 | Armazem padrao da filial |
| BZ_EMIN | N | 12,2 | Estoque minimo (filial) |
| BZ_EMAX | N | 12,2 | Estoque maximo (filial) |
| BZ_ESTSEG | N | 12,2 | Estoque de seguranca (filial) |
| BZ_CONTA | C | 20 | Conta contabil (filial) |
| BZ_LE | N | 12,2 | Lote economico (filial) |
| BZ_LM | N | 12,2 | Lote minimo (filial) |
| BZ_REVATU | C | 3 | Revisao atual da estrutura (filial) |
| BZ_MSBLQL | C | 1 | Produto bloqueado na filial (1=Sim, 2=Nao) |
| BZ_TIPO | C | 2 | Tipo do produto (filial) |

**Indices principais:**
- Ordem 1: `BZ_FILIAL + BZ_COD`

**Parametro relacionado:** `MV_ARQPROD` - Define se o sistema utiliza SBZ em vez dos campos correspondentes na SB1 para indicadores por filial.

---

### SB8 - Saldos por Lote

Armazena os saldos de estoque detalhados por lote e sublote, para produtos com rastreabilidade ativa (B1_RASTRO = "L" ou "S").

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| B8_FILIAL | C | 8 | Filial |
| B8_PRODUTO | C | 15 | Codigo do produto |
| B8_LOCAL | C | 2 | Armazem |
| B8_LOTECTL | C | 10 | Numero do lote |
| B8_NUMLOTE | C | 6 | Sublote |
| B8_SALDO | N | 14,2 | Saldo atual do lote |
| B8_SARONE | N | 14,2 | Saldo atual UM alternativa |
| B8_DATA | D | 8 | Data de entrada do lote |
| B8_DTVALID | D | 8 | Data de validade do lote |
| B8_EMPENHO | N | 14,2 | Quantidade empenhada do lote |
| B8_FESSION | C | 6 | Codigo do fornecedor de origem |
| B8_LOJFORN | C | 2 | Loja do fornecedor de origem |
| B8_NFORN | C | 9 | Numero da NF de origem do lote |
| B8_SFORN | C | 3 | Serie da NF de origem |

**Indices principais:**
- Ordem 1: `B8_FILIAL + B8_PRODUTO + B8_LOCAL + B8_LOTECTL + B8_NUMLOTE`
- Ordem 2: `B8_FILIAL + B8_LOTECTL + B8_NUMLOTE + B8_PRODUTO`

---

### SBE - Cadastro de Enderecos de Estoque

Cadastro de enderecos fisicos nos armazens, utilizado para controle de localizacao (WMS/enderecamento). Cada registro representa uma posicao fisica no armazem (rua, prateleira, nivel, coluna).

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| BE_FILIAL | C | 8 | Filial |
| BE_LOCAL | C | 2 | Armazem |
| BE_LOCALIZ | C | 15 | Codigo do endereco |
| BE_DESCRI | C | 30 | Descricao do endereco |
| BE_TIPEND | C | 2 | Tipo de endereco: 01=Armazenagem, 02=Picking, 03=Expedicao, 04=Recebimento |
| BE_PRIOR | N | 3 | Prioridade de armazenagem |
| BE_CAPAC | N | 12,2 | Capacidade maxima (peso ou volume) |
| BE_STATUS | C | 1 | Status: 1=Livre, 2=Ocupado, 3=Bloqueado |
| BE_RESTPRO | C | 15 | Restricao por produto |
| BE_RESTGRP | C | 4 | Restricao por grupo |

**Indices principais:**
- Ordem 1: `BE_FILIAL + BE_LOCAL + BE_LOCALIZ`
- Ordem 2: `BE_FILIAL + BE_LOCALIZ`

**Pre-requisito:** Para utilizar enderecamento, o parametro `MV_LOCALIZ` deve estar preenchido com "S" e o campo B1_LOCALIZ do produto deve ser "S".

---

### SBF - Saldos por Endereco

Armazena saldos de estoque por endereco fisico no armazem, para produtos com controle de enderecamento ativo.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| BF_FILIAL | C | 8 | Filial |
| BF_PRODUTO | C | 15 | Codigo do produto |
| BF_LOCAL | C | 2 | Armazem |
| BF_LOCALIZ | C | 15 | Endereco |
| BF_QUANT | N | 14,2 | Quantidade no endereco |
| BF_LOTECTL | C | 10 | Lote |
| BF_NUMLOTE | C | 6 | Sublote |
| BF_EMPENHO | N | 14,2 | Quantidade empenhada |

**Indices principais:**
- Ordem 1: `BF_FILIAL + BF_PRODUTO + BF_LOCAL + BF_LOCALIZ + BF_LOTECTL + BF_NUMLOTE`

---

### SD4 - Saldos Iniciais / Inventario

Armazena os registros de contagem de inventario e saldos iniciais de produtos. Utilizada nas rotinas de inventario (MATA220/MATA225) para comparacao entre saldo do sistema e contagem fisica.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| D4_FILIAL | C | 8 | Filial |
| D4_COD | C | 15 | Codigo do produto |
| D4_LOCAL | C | 2 | Armazem |
| D4_QUANT | N | 14,2 | Quantidade contada |
| D4_CUSTO1 | N | 14,2 | Custo medio |
| D4_DATA | D | 8 | Data da contagem |
| D4_LOTECTL | C | 10 | Lote |
| D4_NUMLOTE | C | 6 | Sublote |
| D4_LOCALIZ | C | 15 | Endereco |
| D4_QTDSEG | N | 14,2 | Quantidade da segunda contagem |
| D4_QTDTER | N | 14,2 | Quantidade da terceira contagem |

**Indices principais:**
- Ordem 1: `D4_FILIAL + D4_COD + D4_LOCAL`
- Ordem 2: `D4_FILIAL + D4_LOCAL + D4_COD`

---

## Rotinas Principais

### MATA010 - Cadastro de Produtos

**O que faz:** Permite incluir, alterar, excluir e visualizar o cadastro de produtos na tabela SB1. E a rotina central de manutencao de itens do sistema, utilizada por todos os modulos. Suporta copia de produtos, consulta de saldos (F4), dados complementares (SB5) na mesma tela e utiliza arquitetura MVC.

**Tabelas envolvidas:**
- SB1 (escrita) - Cadastro de Produtos
- SB5 (escrita) - Dados Complementares do Produto
- SBZ (escrita) - Indicadores de Produto por Filial
- SB2 (leitura) - Saldos por Armazem (consulta F4)

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_CADPROD | Define quais cadastros complementares exibir junto ao produto (ex: SB5) |
| MV_ARQPROD | Habilita uso da SBZ (indicadores por filial) em vez dos campos da SB1 |
| MV_RASTRO | Ativa rastreabilidade global por lote/sublote |
| MV_LOCALIZ | Ativa controle de enderecamento de estoque |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MTA010MNU | Adiciona opcoes no menu do browse de Cadastro de Produtos |
| MA010BUT | Adiciona botoes de usuario na toolbar do Cadastro de Produtos |
| MT010INC | Complementa gravacao apos inclusao do produto (salva campos/tabelas de usuario) |
| MT010ALT | Complementa gravacao apos alteracao do produto |
| MT010COR | Customiza legenda de cores no browse do Cadastro de Produtos |
| M010B5CP | Manipula campos de Complemento de Produtos (SB5) na copia de produto |
| A010INCLOI | Executado na confirmacao da inclusao do produto |

---

### MATA220 - Saldos Iniciais (Controle de Itens do Estoque)

**O que faz:** Permite a implantacao de saldos iniciais de estoque na tabela SD4/SB2. Utilizada para carga inicial do sistema ou para registrar saldos de abertura em novas filiais. Pode incluir saldo inicial para produto, armazem, lote e endereco.

**Tabelas envolvidas:**
- SD4 (escrita) - Saldos Iniciais
- SB2 (escrita) - Saldos por Armazem (atualiza saldo)
- SB8 (escrita) - Saldos por Lote (quando rastreabilidade ativa)
- SBF (escrita) - Saldos por Endereco (quando enderecamento ativo)
- SB1 (leitura) - Cadastro de Produtos

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_ULMES | Data do ultimo fechamento de estoque (mes anterior) |
| MV_LOCALIZ | Habilita controle por endereco |
| MV_RASTRO | Habilita rastreabilidade por lote/sublote |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MATIMP | Alimenta informacoes na rotina de implantacao de saldos em estoque |
| MT220GRV | Executado apos a gravacao dos saldos iniciais |

---

### MATA225 - Acerto de Inventario

**O que faz:** Processa o acerto de inventario comparando a contagem fisica (registrada via MATA220 ou MATA340) com o saldo do sistema (SB2). Gera movimentacoes de ajuste (SD3) para regularizar as diferencas encontradas, atualizando saldos fisicos e financeiros.

**Tabelas envolvidas:**
- SD4 (leitura) - Contagem de Inventario
- SB2 (leitura/escrita) - Saldos por Armazem (ajusta saldos)
- SD3 (escrita) - Movimentacoes Internas (gera ajustes)
- SB8 (escrita) - Saldos por Lote (quando rastreabilidade ativa)
- SBF (escrita) - Saldos por Endereco (quando enderecamento ativo)

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_TMPAD | Tipo de movimentacao padrao para acerto de inventario |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT225COR | Manipula apresentacao de cores no array de itens inventariados |
| MT340D3 | Manipula dados da SD3 no ajuste de inventario |

---

### MATA240 - Movimentacoes Internas (Simples)

**O que faz:** Registra movimentacoes internas de materiais na forma de requisicoes (saida) ou devolucoes (entrada). Atualiza saldos fisicos e financeiros dos produtos. Cada lancamento movimenta um unico produto. O tipo de movimentacao (TM) define as regras de atualizacao de empenho, custo e contabilizacao.

**Tabelas envolvidas:**
- SD3 (escrita) - Movimentacoes Internas
- SB2 (escrita) - Saldos por Armazem
- SB8 (escrita) - Saldos por Lote
- SBF (escrita) - Saldos por Endereco
- SB1 (leitura) - Cadastro de Produtos
- CTT (leitura) - Centro de Custo

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_TMPAD | Tipo de movimentacao padrao |
| MV_LOCPROC | Local padrao para processamento |
| MV_ESTNEG | Permite saldo negativo em estoque (S/N) |
| MV_CMDBLQV | Bloqueia movimentacao quando produto esta bloqueado |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT240DVL | Executado na validacao da movimentacao interna |
| A240GRAVA | Executado apos a gravacao da movimentacao na SD3 |
| MT240FIL | Filtro customizado no browse de movimentacoes |
| MT240INI | Executado na inicializacao da rotina |
| A240QTDOK | Validacao da quantidade informada |
| A240EXPLOD | Explosao do 1o nivel da estrutura para produtos indiretos |

**Nota:** A rotina de Movimentacao Simples (MATA240) foi descontinuada em 04/04/2022 para produtos com modelo 1 item. Recomenda-se migrar para MATA241 (Modelo 2 - multiplos itens).

---

### MATA241 - Movimentacoes Internas (Modelo 2 - Multiplos Itens)

**O que faz:** Versao avancada da MATA240 que permite movimentar multiplos produtos em um unico documento (ate 999 itens). Possui as mesmas regras de negocio, com a vantagem de agrupar movimentacoes com mesma data e documento.

**Tabelas envolvidas:**
- SD3 (escrita) - Movimentacoes Internas
- SB2 (escrita) - Saldos por Armazem
- SB8 (escrita) - Saldos por Lote
- SBF (escrita) - Saldos por Endereco
- SB1 (leitura) - Cadastro de Produtos

**Parametros relevantes:**
- Mesmos parametros do MATA240

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT241FIL | Filtro customizado no browse |
| MT241INI | Inicializacao da rotina |
| A241GRAVA | Executado apos gravacao das movimentacoes |
| A241EXPLOD | Explosao de estrutura para produtos indiretos |

---

### MATA261 - Transferencias entre Armazens (Modelo 2)

**O que faz:** Permite a transferencia de multiplos produtos entre armazens em um unico documento. Movimenta saldo do armazem origem para o armazem destino, valorizado pelo custo medio do produto. Substituiu a MATA260 (descontinuada em 04/04/2022).

**Tabelas envolvidas:**
- SD3 (escrita) - Movimentacoes Internas (dois registros: saida do origem, entrada no destino)
- SB2 (escrita) - Saldos por Armazem (debita origem, credita destino)
- SB8 (escrita) - Saldos por Lote
- SBF (escrita) - Saldos por Endereco
- SB1 (leitura) - Cadastro de Produtos

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_ESTNEG | Permite saldo negativo (S/N) |
| MV_LOCALIZ | Habilita controle de enderecamento |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT261FIL | Filtro no browse de transferencias |
| A261INI | Inicializacao da rotina |
| A261GRAVA | Pos-gravacao da transferencia |

**Nota:** A transferencia nao pode ser excluida. Para reverter, deve-se usar a opcao de Estorno no menu.

---

### MATA265 - Enderecamento de Produtos

**O que faz:** Realiza o enderecamento (armazenagem) dos materiais recebidos, distribuindo-os nos enderecos fisicos do armazem. O saldo a enderecar e retirado da SB2 (saldo sem endereco) e alocado na SBF (saldo por endereco).

**Tabelas envolvidas:**
- SBF (escrita) - Saldos por Endereco
- SBE (leitura) - Cadastro de Enderecos
- SB2 (leitura/escrita) - Saldos por Armazem
- SDA (escrita) - Saldos a Distribuir
- SDB (escrita) - Movimentos de Distribuicao

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_LOCALIZ | Habilita controle de enderecamento |
| MV_WMSENPK | Armazenamento prioritario no picking |
| MV_WMSPKFX | Endereco fixo de picking |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| A265QUERY | Manipula query de selecao de enderecos |
| WMSSERORI | Controle de numero de serie no WMS |

---

### MATA105 - Solicitacao ao Armazem

**O que faz:** Permite incluir, alterar e excluir solicitacoes de materiais ao armazem (almoxarifado). Formaliza o pedido interno de materiais para consumo, producao ou manutencao. Suporta rateio por centro de custo.

**Tabelas envolvidas:**
- SCP (escrita) - Solicitacoes ao Armazem
- SB1 (leitura) - Cadastro de Produtos
- SB2 (leitura) - Saldos por Armazem (consulta disponibilidade)
- CTT (leitura) - Centro de Custo

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_TMPAD | Tipo de movimentacao padrao |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT105FIM | Executado apos gravacao da solicitacao ao armazem |
| A105GRAVA | Pos-gravacao da solicitacao |
| MDTA6959 | Permite adicionar novos campos na solicitacao ao armazem |

---

### MATA230 - Tipos de Movimentacao (TM)

**O que faz:** Cadastro e manutencao dos tipos de movimentacao interna. Cada TM define as regras que serao aplicadas quando utilizada: se atualiza empenho, se transfere para CQ, se libera pedido de venda, se gera contabilizacao, entre outros controles.

**Tabelas envolvidas:**
- SX5 (escrita) - Tabela Generica (tabela DJ - Tipos de Movimentacao)
- SB1 (leitura) - Cadastro de Produtos

**Faixas de codigos:**
| Faixa | Tipo |
|-------|------|
| 001 a 499 | Entradas (devolucoes, producao, ajustes positivos) |
| 500 a 998 | Saidas (requisicoes, consumo, ajustes negativos) |
| 999 | Reservado pelo sistema (transferencias automaticas) |

---

### MATA330 - Recalculo do Custo Medio

**O que faz:** Recalcula e reordena as movimentacoes de estoque (SD3) para apurar o custo medio correto dos produtos. Gera lancamentos contabeis (CT2) quando contabilizacao on-line esta habilitada. Considera entradas (NF entrada, producao, devolucao) e saidas (NF saida, requisicao, transferencia) para recalcular o custo unitario.

**Tabelas envolvidas:**
- SD3 (leitura/escrita) - Movimentacoes Internas
- SD1 (leitura) - Itens de NF Entrada
- SD2 (leitura) - Itens de NF Saida
- SB2 (escrita) - Saldos por Armazem (atualiza custos)
- SB9 (escrita) - Saldos Consolidados
- CT2 (escrita) - Lancamentos Contabeis

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_CUSMED | Metodo de custeio (1=Medio, 2=Standard, 3=Ultimo Preco, 4=FIFO) |
| MV_ULMES | Mes de referencia do fechamento |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT330FIM | Executado ao finalizar o recalculo |
| MA330C3 | Utilizado na atualizacao do saldo SB2 (fisico e financeiro) |

---

### MATA390 - Manutencao de Lotes

**O que faz:** Permite pesquisar, visualizar, incluir e excluir lotes manualmente, alem de alterar a data de validade de lotes existentes. Somente lotes incluidos manualmente podem ser excluidos. Para produtos com controle WMS, apenas alteracao de peso e potencia e permitida.

**Tabelas envolvidas:**
- SB8 (escrita) - Saldos por Lote
- SD3 (leitura) - Movimentacoes (rastreabilidade)
- SB1 (leitura) - Cadastro de Produtos

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_LOTVENC | Permite uso de lote com data de validade vencida (S/N) |
| MV_VLDLOTE | Validacao de datas de origem do lote |
| MV_TDATALO | Tipo de data para checagem de lotes vencidos |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT390DTV | Executado apos alterar data de validade - permite validacoes adicionais |
| A390ZERO | Manutencao de lotes com saldo zero |

---

## Processos de Negocio

### Fluxo Completo de Estoque (Recebimento → Expedicao)

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  1. Recebimento  │────>│  2. Armazenagem  │────>│  3. Movimentacao │
│  (Entrada)       │     │  (Enderecamento) │     │  Interna         │
│  MATA103 / SD1   │     │  MATA265 / SBF   │     │  MATA241 / SD3   │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                          │
┌─────────────────┐     ┌─────────────────┐     ┌────────v────────┐
│  6. Expedicao    │<────│  5. Recalculo    │<────│  4. Inventario   │
│  (Saida)         │     │  Custo Medio     │     │  Fisico          │
│  MATA461/SD2     │     │  MATA330/SB2     │     │  MATA220-225/SD4 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

#### Passo 1: Recebimento (Entrada de Material)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA103 (Documento de Entrada) - integrado com Compras |
| **Tabelas** | SF1/SD1 (NF Entrada), SD3 (movimentacao), SB2 (saldo) |
| **O que acontece** | Ao classificar o documento de entrada, o sistema gera movimentacao de entrada na SD3, atualiza o saldo fisico e financeiro na SB2 (B2_QATU), e se o produto tem rastreabilidade (B1_RASTRO), gera registro na SB8 com o lote informado. Se o produto tem enderecamento (B1_LOCALIZ), o saldo fica disponivel para enderecamento (SDA). |
| **Resultado** | Saldo atualizado na SB2, movimentacao registrada na SD3, lote na SB8 (se aplicavel) |

#### Passo 2: Armazenagem / Enderecamento

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA265 (Enderecamento de Produtos) |
| **Tabelas** | SBE (enderecos), SBF (saldos por endereco), SDA (saldos a distribuir), SDB (movimentos de distribuicao) |
| **O que acontece** | O operador seleciona o material recebido e indica o endereco fisico no armazem (rua, prateleira, nivel). O saldo e transferido da posicao "sem endereco" para o endereco especifico na SBF. Se o armazem opera com WMS, pode haver sugestao automatica de endereco por tipo (picking, armazenagem). |
| **Resultado** | Material enderecado na SBF com localizacao precisa no armazem |

#### Passo 3: Movimentacao Interna

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA241 (Movimentacoes Internas Modelo 2) ou MATA261 (Transferencias) |
| **Tabelas** | SD3 (escrita), SB2 (escrita), SB8 (escrita), SBF (escrita) |
| **O que acontece** | Requisicoes (saida para consumo/producao), devolucoes (retorno ao armazem) ou transferencias (entre armazens). O tipo de movimentacao (TM) define as regras de atualizacao. O saldo na SB2 e atualizado: decrementado para requisicao, incrementado para devolucao. Para transferencias, debita o armazem origem e credita o destino. |
| **Resultado** | Movimentacao registrada na SD3, saldos atualizados na SB2/SB8/SBF |

#### Passo 4: Inventario Fisico

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA220 (Saldos Iniciais / Contagem) + MATA225 (Acerto de Inventario) |
| **Tabelas** | SD4 (contagem), SB2 (leitura/escrita), SD3 (escrita - ajustes) |
| **O que acontece** | Processo em 3 etapas: (1) Bloqueio do produto para inventario (B2_SESSION = "I"), impedindo movimentacoes. (2) Digitacao da contagem fisica na SD4. (3) Acerto de inventario (MATA225) que compara contagem com saldo do sistema e gera movimentacoes de ajuste (positivas ou negativas) na SD3 para regularizar diferencas. Permite multiplas contagens (2a, 3a). |
| **Resultado** | Saldos regularizados com base na contagem fisica, ajustes registrados na SD3 |

#### Passo 5: Recalculo do Custo Medio

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA330 (Recalculo do Custo Medio) |
| **Tabelas** | SD3 (leitura/escrita), SD1/SD2 (leitura), SB2 (escrita), SB9 (escrita), CT2 (escrita) |
| **O que acontece** | Reordena cronologicamente todas as movimentacoes do periodo e recalcula o custo medio de cada produto. Gera lancamentos contabeis das diferencas apuradas. Garante que o custo unitario reflita corretamente a media ponderada das entradas. |
| **Resultado** | Custos unitarios recalculados, saldos financeiros ajustados, lancamentos contabeis gerados |

#### Passo 6: Expedicao (Saida de Material)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA461 (Faturamento / NF Saida) - integrado com Faturamento |
| **Tabelas** | SF2/SD2 (NF Saida), SD3 (movimentacao), SB2 (saldo) |
| **O que acontece** | Ao faturar o pedido de venda, o sistema gera movimentacao de saida na SD3, debita o saldo na SB2, e registra o custo de saida conforme metodo de custeio configurado (MV_CUSMED). Se rastreavel, debita o lote na SB8. Se enderecado, debita o endereco na SBF. |
| **Resultado** | Saldo decrementado na SB2, movimentacao de saida na SD3, NF emitida |

### Fluxo de Inventario

```
Bloqueio para Inventario → Contagem Fisica (1a) → Contagem Fisica (2a) → Digitacao → Acerto → Desbloqueio
     B2_SESSION="I"           SD4 (1a cont.)         SD4 (2a cont.)        MATA220     MATA225    B2_SESSION=""
```

### Fluxo de Requisicao de Materiais

```
Solicitacao ao Armazem (MATA105/SCP) → Aprovacao → Separacao → Movimentacao Interna (MATA241/SD3) → Atualiza Saldo (SB2)
```

---

## Regras de Negocio

### Campos obrigatorios por rotina

**Cadastro de Produtos (MATA010 - SB1):**
- B1_COD (Codigo do produto)
- B1_DESC (Descricao)
- B1_TIPO (Tipo de produto)
- B1_UM (Unidade de medida)
- B1_LOCPAD (Armazem padrao)
- B1_GRUPO (Grupo de produto)

**Movimentacoes Internas (MATA241 - SD3):**
- D3_COD (Codigo do produto)
- D3_QUANT (Quantidade)
- D3_TM (Tipo de movimentacao)
- D3_LOCAL (Armazem)
- D3_EMISSAO (Data de emissao)
- D3_CF (Tipo RE/DE)

**Transferencias (MATA261 - SD3):**
- D3_COD (Codigo do produto)
- D3_QUANT (Quantidade)
- D3_LOCAL (Armazem origem)
- D3_LOCEST (Armazem destino)
- D3_EMISSAO (Data de emissao)

**Inventario (MATA220 - SD4):**
- D4_COD (Codigo do produto)
- D4_LOCAL (Armazem)
- D4_QUANT (Quantidade contada)

### Validacoes principais

| Validacao | Descricao |
|-----------|-----------|
| Saldo negativo | Por padrao, nao permite saldo negativo em estoque. Controlado pelo parametro `MV_ESTNEG` |
| Produto bloqueado | Nao permite movimentacao de produto com B1_MSBLQL = "1" (parametro `MV_CMDBLQV`) |
| Inventario em andamento | Produto com B2_SESSION = "I" nao permite movimentacao ate o desbloqueio |
| Rastreabilidade | Se B1_RASTRO = "L" ou "S", obriga informar lote/sublote em toda movimentacao |
| Enderecamento | Se B1_LOCALIZ = "S", movimentacoes exigem endereco valido no SBE |
| Lote vencido | Se `MV_LOTVENC` = "N", impede uso de lotes com data de validade expirada |
| Tipo de movimentacao | O TM deve existir na tabela DJ (SX5) e ser compativel com o tipo de operacao (entrada/saida) |
| Armazem valido | O armazem deve existir na tabela NNR (Locais de Estoque) |
| Produto fantasma | Produtos com B1_FANTASM = "S" nao podem ter saldo em estoque |
| Acerto de inventario | Nao processa acerto se quantidade inventariada for menor que quantidade empenhada (B2_QEMP) |

### Gatilhos SX7 relevantes

| Campo origem | Campo destino | Regra | Tabela lookup |
|-------------|---------------|-------|---------------|
| D3_COD | D3_UM | SB1->B1_UM | SB1 |
| D3_COD | D3_GRUPO | SB1->B1_GRUPO | SB1 |
| D3_COD | D3_CONTA | SB1->B1_CONTA | SB1 |
| D3_COD | D3_CC | SB1->B1_CC | SB1 |
| D3_LOCAL + D3_COD | D3_CUSTO1 | SB2->B2_CM1 | SB2 |
| D3_QUANT * D3_CUSTO1 | D3_TOTAL | Calculado | - |
| B1_COD | B1_DESC | Gatilho de preenchimento automatico | - |
| B1_GRUPO | B1_CONTA | SBM->BM_CONTA | SBM |

### Pontos de entrada mais utilizados no modulo

| Ponto de Entrada | Rotina | Descricao |
|------------------|--------|-----------|
| MTA010MNU | MATA010 | Customiza menu do Cadastro de Produtos |
| MA010BUT | MATA010 | Adiciona botoes no Cadastro de Produtos |
| MT010INC | MATA010 | Pos-inclusao no Cadastro de Produtos |
| MT010COR | MATA010 | Legenda de cores no browse de Produtos |
| MT240DVL | MATA240 | Validacao de movimentacao interna |
| A240GRAVA | MATA240 | Pos-gravacao de movimentacao interna |
| MT241FIL | MATA241 | Filtro no browse de Movimentacoes Modelo 2 |
| MT261FIL | MATA261 | Filtro no browse de Transferencias Modelo 2 |
| MT225COR | MATA225 | Cores no acerto de inventario |
| MT340D3 | MATA225 | Manipula SD3 no ajuste de inventario |
| MT105FIM | MATA105 | Pos-gravacao da Solicitacao ao Armazem |
| MT330FIM | MATA330 | Pos-recalculo do custo medio |
| MA330C3 | MATA330 | Atualizacao de saldo SB2 no recalculo |
| MT390DTV | MATA390 | Validacao de data de validade de lote |
| MATIMP | MATA220 | Alimenta saldos iniciais |
| M010B5CP | MATA010 | Manipula SB5 na copia de produto |

---

## Integracoes

### Estoque <-> Compras

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na classificacao do Documento de Entrada (MATA103) |
| **O que acontece** | O recebimento da NF de compra gera movimentacao de entrada na SD3, atualiza saldo na SB2 (B2_QATU) e registra custo de entrada. O pedido de compra (SC7) tem seu saldo atendido (C7_QUJE) atualizado. Se o produto tem rastreabilidade, gera lote na SB8 com dados do fornecedor |
| **Tabelas afetadas** | SD3 (movimentacao entrada), SB2 (saldo), SB8 (lote), SC7 (pedido de compra) |
| **Controles** | TES define se atualiza estoque. Se controle de qualidade ativo, pode direcionar para armazem CQ (MV_CQ) |

### Estoque <-> Faturamento

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na emissao da NF de saida (MATA461) |
| **O que acontece** | O faturamento gera movimentacao de saida na SD3, debita saldo na SB2. O custo de saida e calculado conforme metodo de custeio (MV_CUSMED). Se o produto tem rastreabilidade, debita o lote especifico na SB8. O pedido de venda (SC5/SC6) tem saldo atendido atualizado |
| **Tabelas afetadas** | SD3 (movimentacao saida), SB2 (saldo), SB8 (lote), SD2 (itens NF saida) |
| **Controles** | TES define se atualiza estoque. Nao permite faturar se saldo insuficiente (a menos que MV_ESTNEG = "S") |

### Estoque <-> PCP (Producao)

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na requisicao de materiais para OP e no apontamento de producao |
| **O que acontece** | Requisicao (MATA241 vinculada a OP): debita materia-prima da SB2 via SD3. Apontamento de producao (MATC010): credita produto acabado na SB2 via SD3. O empenho (B2_QEMP) e atualizado na geracao da OP e decrementado na requisicao |
| **Tabelas afetadas** | SD3 (movimentacao), SB2 (saldo e empenho), SC2 (ordens de producao) |
| **Controles** | TM define se debita empenho. Explosao de estrutura (SG1) para requisicao automatica de componentes |

### Estoque -> Contabilidade

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | No recalculo do custo medio (MATA330) e em movimentacoes com contabilizacao on-line |
| **O que acontece** | Gera lancamentos contabeis na CT2 debitando/creditando contas de estoque, custos, producao e consumo conforme o tipo de movimentacao e o Lancamento Padrao (CT5) configurado na TES ou no TM |
| **Tabelas afetadas** | CT2 (Lancamentos Contabeis) |
| **Parametro** | MV_CUSMED - Metodo de custeio |

### Estoque -> Fiscal

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Nas movimentacoes de entrada e saida com NF (via Compras ou Faturamento) |
| **O que acontece** | Os documentos fiscais (NF entrada/saida) geram escrituracao nos livros fiscais (SFT/SF3). O inventario valorizado (posicao em 31/12) alimenta o Bloco H do SPED Fiscal e o Registro K200 (Estoque Escriturado) e K220 (Outras Movimentacoes Internas) do Bloco K |
| **Tabelas afetadas** | SFT (Livros Fiscais), SF3 (Resumo NF) |
| **Observacao** | O Bloco K do SPED Fiscal exige detalhamento de todas as movimentacoes internas (SD3) e saldos de estoque por produto |

### Resumo das integracoes do Estoque

```
                              SIGAEST - Estoque
                                    │
               ┌────────────────────┼────────────────────┐
               │                    │                    │
        ┌──────v──────┐     ┌──────v──────┐     ┌──────v──────┐
        │   Compras    │     │ Faturamento │     │     PCP     │
        │   SIGACOM    │     │   SIGAFAT   │     │   SIGAPCP   │
        │ NF Entrada   │     │  NF Saida   │     │ Req/Apont.  │
        │ SD1→SD3→SB2  │     │ SD2→SD3→SB2 │     │ SD3→SB2     │
        └─────────────┘     └─────────────┘     └─────────────┘
                                    │
               ┌────────────────────┼────────────────────┐
               │                    │                    │
        ┌──────v──────┐     ┌──────v──────┐     ┌──────v──────┐
        │Contabilidade│     │   Fiscal    │     │  Qualidade  │
        │   SIGACTB   │     │  SIGAFIS    │     │   SIGAQLT   │
        │     CT2     │     │  SFT / SF3  │     │  CQ (MV_CQ) │
        └─────────────┘     └─────────────┘     └─────────────┘
```

---

## Cadastros Auxiliares

| Rotina | Descricao | Tabela |
|--------|-----------|--------|
| MATA010 | Cadastro de Produtos | SB1 |
| MATA180 | Complemento de Produtos | SB5 |
| MATA018 | Indicadores de Produtos | SBZ |
| MATA015 | Cadastro de Enderecos | SBE |
| MATA230 | Tipo de Movimentacao | SX5 (tabela DJ) |
| MATA390 | Manutencao de Lotes | SB8 |
| MATA280 | Virada de Saldos (Transferencia de Saldos) | SB2/SB9 |
| MATA215 | Refaz Acumulados | SB2/SB9 |
| NNR | Locais de Estoque (Armazens) | NNR |
| MATA093 | Familia de Produto / Configurador de Produto | SB1 |

---

## Parametros Globais do Modulo (MV_*)

| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| MV_CUSMED | N | Metodo de custeio: 1=Medio, 2=Standard, 3=Ultimo Preco, 4=FIFO/PEPS |
| MV_ESTNEG | C | Permite saldo negativo em estoque (S/N) |
| MV_RASTRO | C | Habilita rastreabilidade global por lote/sublote (S/N) |
| MV_LOCALIZ | C | Habilita controle de enderecamento/localizacao (S/N) |
| MV_ARQPROD | C | Utiliza SBZ (indicadores por filial) em vez da SB1 (S/N) |
| MV_CADPROD | C | Cadastros complementares exibidos com o produto |
| MV_TMPAD | C | Tipo de movimentacao padrao |
| MV_ULMES | D | Data do ultimo fechamento de estoque |
| MV_LOTVENC | C | Permite uso de lote vencido (S/N) |
| MV_VLDLOTE | C | Validacao de datas de origem do lote |
| MV_TDATALO | C | Tipo de data para checagem de lotes vencidos |
| MV_CQ | C | Codigo do armazem de Controle de Qualidade |
| MV_CMDBLQV | C | Bloqueia movimentacao de produto bloqueado (S/N) |
| MV_LOCPROC | C | Local padrao para processamento |
| MV_WMSENPK | C | Armazenamento prioritario no picking |
| MV_WMSPKFX | C | Endereco fixo de picking |
