# Modulo de Faturamento (FAT)

## Visao Geral

O modulo de Faturamento (SIGAFAT) do TOTVS Protheus gerencia todo o ciclo de vendas da empresa, desde o cadastro de clientes e tabelas de precos ate a emissao de notas fiscais de saida e transmissao eletronica (NF-e). Ele abrange orcamentos, pedidos de venda, liberacao de credito e estoque, faturamento (emissao de documentos de saida) e integracao com os modulos de Estoque, Financeiro, Fiscal e Contabilidade.

**Prefixo do modulo:** FAT
**Sigla do ambiente:** SIGAFAT
**Prefixo das rotinas:** MATA4xx (ex: MATA410, MATA440, MATA450, MATA455, MATA460, MATA461), FATA0xx (ex: FATA050), OMSA0xx (ex: OMSA010)

### Ciclo principal de faturamento

```
Orcamento → Pedido de Venda → Liberacao (Credito + Estoque) → Documento de Saida (NF) → Transmissao NF-e → Titulo a Receber
```

O modulo permite tanto o fluxo completo (com orcamento e analise de credito/estoque) quanto o fluxo simplificado (pedido direto com faturamento), controlado pelo parametro `MV_BLOQUEI`.

---

## Tabelas Principais

### SC5 - Pedidos de Venda (Cabecalho)

Armazena o cabecalho dos pedidos de venda. Cada registro representa um pedido vinculado a um cliente.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| C5_FILIAL | C | 8 | Filial |
| C5_NUM | C | 6 | Numero do pedido de venda |
| C5_CLIENTE | C | 6 | Codigo do cliente |
| C5_LOJACLI | C | 2 | Loja do cliente |
| C5_TIPO | C | 1 | Tipo do pedido: N=Normal, D=Devolucao, B=Beneficiamento, C=Complemento |
| C5_EMISSAO | D | 8 | Data de emissao |
| C5_CONDPAG | C | 3 | Condicao de pagamento |
| C5_VEND1 | C | 6 | Codigo do vendedor |
| C5_TABELA | C | 3 | Tabela de precos |
| C5_MOEDA | N | 2 | Moeda |
| C5_MENNOTA | C | 1 | Mensagem na NF |
| C5_TRANSP | C | 6 | Codigo da transportadora |
| C5_TPFRETE | C | 1 | Tipo de frete: C=CIF, F=FOB |
| C5_LIBEROK | C | 1 | Status da liberacao: Branco=Pendente, S=Liberado |
| C5_NOTA | C | 9 | Numero da NF gerada |
| C5_SERIE | C | 3 | Serie da NF gerada |
| C5_BLQ | C | 1 | Pedido bloqueado: Branco=Nao, 1=Credito, 2=Estoque, 3=Ambos |
| C5_DESCONT | C | 50 | Expressao/percentual de desconto |
| C5_DESPESA | N | 14,2 | Despesas acessorias |
| C5_FRETE | N | 14,2 | Valor do frete |
| C5_SEGURO | N | 14,2 | Valor do seguro |
| C5_OBS | C | 60 | Observacoes |
| C5_OBSM | M | 10 | Observacoes (memo) |
| C5_NATUREZ | C | 10 | Natureza da operacao |
| C5_ESSION | C | 3 | Tipo da operacao |
| C5_REDESP | C | 6 | Transportadora de redespacho |

**Indices principais:**
- Ordem 1: `C5_FILIAL + C5_NUM`
- Ordem 2: `C5_FILIAL + C5_CLIENTE + C5_LOJACLI + C5_NUM`
- Ordem 3: `C5_FILIAL + C5_EMISSAO + C5_NUM`

---

### SC6 - Pedidos de Venda (Itens)

Armazena os itens dos pedidos de venda. Cada registro representa um item do pedido vinculado ao cabecalho SC5.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| C6_FILIAL | C | 8 | Filial |
| C6_NUM | C | 6 | Numero do pedido (vinculo com SC5) |
| C6_ITEM | C | 4 | Item do pedido |
| C6_PRODUTO | C | 15 | Codigo do produto |
| C6_DESCRI | C | 30 | Descricao do produto |
| C6_UM | C | 2 | Unidade de medida |
| C6_QTDVEN | N | 12,2 | Quantidade vendida |
| C6_QTDENT | N | 12,2 | Quantidade ja faturada (entregue) |
| C6_PRCVEN | N | 14,2 | Preco unitario de venda |
| C6_VALOR | N | 14,2 | Valor total do item |
| C6_PRUNIT | N | 14,2 | Preco unitario original |
| C6_DESCONT | N | 5,2 | Percentual de desconto |
| C6_VALDESC | N | 14,2 | Valor do desconto |
| C6_TES | C | 3 | Tipo de entrada/saida (TES) |
| C6_LOCAL | C | 2 | Armazem de saida |
| C6_CLI | C | 6 | Codigo do cliente (pode diferir do cabecalho) |
| C6_LOJA | C | 2 | Loja do cliente |
| C6_ENTREG | D | 8 | Data de entrega prevista |
| C6_COMIS1 | N | 5,2 | Percentual de comissao |
| C6_NOTA | C | 9 | Numero da NF gerada |
| C6_SERIE | C | 3 | Serie da NF gerada |
| C6_BLQ | C | 1 | Bloqueio do item: Branco=Nao, R=Residuo |
| C6_QTDLIB | N | 12,2 | Quantidade liberada (tela, nao grava em SC6) |
| C6_NUMOP | C | 13 | Numero da Ordem de Producao vinculada |
| C6_OPER | C | 2 | Operacao fiscal |
| C6_LOTECTL | C | 10 | Lote do produto |
| C6_NUMLOTE | C | 6 | Numero do lote |

**Indices principais:**
- Ordem 1: `C6_FILIAL + C6_NUM + C6_ITEM`
- Ordem 2: `C6_FILIAL + C6_PRODUTO + C6_NUM + C6_ITEM`
- Ordem 3: `C6_FILIAL + C6_CLI + C6_LOJA + C6_NUM + C6_ITEM`

---

### SC9 - Itens Liberados do Pedido de Venda

Armazena as liberacoes dos itens do pedido de venda. Gerada pela rotina de liberacao (MATA440/MATA456), controla os bloqueios de credito e estoque. Cada registro pode ter status liberado ou bloqueado.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| C9_FILIAL | C | 8 | Filial |
| C9_PEDIDO | C | 6 | Numero do pedido (vinculo com SC5) |
| C9_ITEM | C | 4 | Item do pedido (vinculo com SC6) |
| C9_PRODUTO | C | 15 | Codigo do produto |
| C9_CLIENTE | C | 6 | Codigo do cliente |
| C9_LOJA | C | 2 | Loja do cliente |
| C9_QTDLIB | N | 12,2 | Quantidade liberada |
| C9_NFISCAL | C | 9 | Numero da NF vinculada |
| C9_DATENT | D | 8 | Data de entrega |
| C9_BLCRED | C | 1 | Bloqueio de credito: Branco=Nao, 1=Sim |
| C9_BLEST | C | 1 | Bloqueio de estoque: Branco=Nao, 1=Sim |
| C9_BLFIN | C | 1 | Bloqueio financeiro |
| C9_BLREG | C | 1 | Bloqueio por regra |

**Indices principais:**
- Ordem 1: `C9_FILIAL + C9_PEDIDO + C9_ITEM`
- Ordem 2: `C9_FILIAL + C9_CLIENTE + C9_LOJA + C9_PEDIDO`

---

### SF2 - Cabecalho de NF de Saida

Armazena o cabecalho das notas fiscais de saida, gerado pelo processo de faturamento (MATA460/MATA461).

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| F2_FILIAL | C | 8 | Filial |
| F2_DOC | C | 9 | Numero do documento |
| F2_SERIE | C | 3 | Serie |
| F2_CLIENTE | C | 6 | Codigo do cliente |
| F2_LOJA | C | 2 | Loja do cliente |
| F2_EMISSAO | D | 8 | Data de emissao |
| F2_HORA | C | 5 | Hora de emissao |
| F2_VALBRUT | N | 14,2 | Valor bruto |
| F2_VALMERC | N | 14,2 | Valor das mercadorias |
| F2_FRETE | N | 14,2 | Valor do frete |
| F2_SEGURO | N | 14,2 | Valor do seguro |
| F2_DESPESA | N | 14,2 | Despesas acessorias |
| F2_DESCONT | N | 14,2 | Desconto |
| F2_VALICM | N | 14,2 | Valor de ICMS |
| F2_VALIPI | N | 14,2 | Valor de IPI |
| F2_TIPO | C | 1 | Tipo da NF: N=Normal, D=Devolucao, C=Complemento, B=Beneficiamento |
| F2_COND | C | 3 | Condicao de pagamento |
| F2_VEND1 | C | 6 | Codigo do vendedor |
| F2_TRANSP | C | 6 | Transportadora |
| F2_TPFRETE | C | 1 | Tipo de frete: C=CIF, F=FOB |
| F2_CHVNFE | C | 44 | Chave da NF-e |
| F2_DTENTR | D | 8 | Data de entrega |
| F2_MENNOTA | C | 1 | Mensagem na NF |
| F2_NATUREZ | C | 10 | Natureza da operacao |

**Indices principais:**
- Ordem 1: `F2_FILIAL + F2_DOC + F2_SERIE + F2_CLIENTE + F2_LOJA + F2_TIPO`
- Ordem 2: `F2_FILIAL + F2_CLIENTE + F2_LOJA + F2_DOC`
- Ordem 3: `F2_FILIAL + F2_EMISSAO + F2_DOC`

---

### SD2 - Itens de Nota Fiscal de Saida

Armazena os itens do documento de saida (NF). Gerada no faturamento do pedido de venda.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| D2_FILIAL | C | 8 | Filial |
| D2_DOC | C | 9 | Numero do documento |
| D2_SERIE | C | 3 | Serie |
| D2_CLIENTE | C | 6 | Codigo do cliente |
| D2_LOJA | C | 2 | Loja do cliente |
| D2_COD | C | 15 | Codigo do produto |
| D2_ITEM | C | 4 | Item |
| D2_QUANT | N | 12,2 | Quantidade |
| D2_PRCVEN | N | 14,2 | Preco unitario de venda |
| D2_TOTAL | N | 14,2 | Valor total |
| D2_VALBRUT | N | 14,2 | Valor bruto |
| D2_DESCONT | N | 5,2 | Percentual de desconto |
| D2_VALDESC | N | 14,2 | Valor do desconto |
| D2_TES | C | 3 | Tipo de entrada/saida |
| D2_LOCAL | C | 2 | Armazem de saida |
| D2_PEDIDO | C | 6 | Numero do pedido de venda vinculado |
| D2_ITEMPV | C | 4 | Item do pedido de venda |
| D2_EMISSAO | D | 8 | Data de emissao |
| D2_COMIS1 | N | 5,2 | Percentual de comissao |
| D2_VALIPI | N | 14,2 | Valor de IPI |
| D2_VALICM | N | 14,2 | Valor de ICMS |
| D2_ICMSRET | N | 14,2 | ICMS retido (ST) |
| D2_LOTECTL | C | 10 | Lote |
| D2_NUMLOTE | C | 6 | Numero do lote |
| D2_CF | C | 4 | Codigo fiscal (CFOP) |

**Indices principais:**
- Ordem 1: `D2_FILIAL + D2_DOC + D2_SERIE + D2_CLIENTE + D2_LOJA + D2_COD + D2_ITEM`
- Ordem 2: `D2_FILIAL + D2_COD + D2_DOC + D2_SERIE`
- Ordem 3: `D2_FILIAL + D2_EMISSAO + D2_DOC + D2_SERIE`
- Ordem 4: `D2_FILIAL + D2_PEDIDO + D2_ITEMPV`

---

### SA1 - Clientes (referencia)

Cadastro mestre de clientes, consultado em todo o ciclo de faturamento.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| A1_FILIAL | C | 8 | Filial |
| A1_COD | C | 6 | Codigo do cliente |
| A1_LOJA | C | 2 | Loja |
| A1_NOME | C | 40 | Razao social |
| A1_NREDUZ | C | 20 | Nome reduzido |
| A1_CGC | C | 14 | CNPJ/CPF |
| A1_INSCR | C | 18 | Inscricao estadual |
| A1_END | C | 40 | Endereco |
| A1_EST | C | 2 | Estado |
| A1_MUN | C | 30 | Municipio |
| A1_CEP | C | 8 | CEP |
| A1_TEL | C | 15 | Telefone |
| A1_EMAIL | C | 50 | E-mail |
| A1_CONTATO | C | 20 | Nome do contato |
| A1_TIPO | C | 1 | Tipo: F=Fisico, J=Juridico, X=Exterior |
| A1_COND | C | 3 | Condicao de pagamento padrao |
| A1_TABELA | C | 3 | Tabela de precos padrao |
| A1_VEND | C | 6 | Vendedor padrao |
| A1_LC | N | 14,2 | Limite de credito |
| A1_VENCLC | D | 8 | Vencimento do limite de credito |
| A1_RISCO | C | 1 | Classificacao de risco: A, B, C, D, E |
| A1_MSBLQL | C | 1 | Bloqueado (1=Sim, 2=Nao) |
| A1_NATUREZ | C | 10 | Natureza financeira padrao |
| A1_TRANSP | C | 6 | Transportadora padrao |

**Indices principais:**
- Ordem 1: `A1_FILIAL + A1_COD + A1_LOJA`
- Ordem 2: `A1_FILIAL + A1_NOME`
- Ordem 3: `A1_FILIAL + A1_CGC`

---

### DA0 / DA1 - Tabela de Precos

DA0 armazena o cabecalho da tabela de precos e DA1 armazena os itens (produtos e seus precos). Consultada na inclusao de pedidos de venda para definir o preco de venda dos produtos.

**DA0 - Cabecalho da Tabela de Precos:**

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| DA0_FILIAL | C | 8 | Filial |
| DA0_CODTAB | C | 3 | Codigo da tabela de precos |
| DA0_DESCRI | C | 30 | Descricao da tabela |
| DA0_ATIVO | C | 1 | Status: 1=Ativa, 2=Inativa |
| DA0_DATDE | D | 8 | Data de vigencia inicial |
| DA0_DATATE | D | 8 | Data de vigencia final |

**DA1 - Itens da Tabela de Precos:**

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| DA1_FILIAL | C | 8 | Filial |
| DA1_CODTAB | C | 3 | Codigo da tabela de precos (vinculo DA0) |
| DA1_CODPRO | C | 15 | Codigo do produto |
| DA1_PRCVEN | N | 14,2 | Preco de venda |
| DA1_DATVIG | D | 8 | Data de vigencia |
| DA1_ATIVO | C | 1 | Status: 1=Ativo, 2=Inativo |
| DA1_DESMAX | N | 5,2 | Desconto maximo permitido |

**Indices principais (DA1):**
- Ordem 1: `DA1_FILIAL + DA1_CODTAB + DA1_CODPRO`
- Ordem 2: `DA1_FILIAL + DA1_CODPRO + DA1_CODTAB`

---

### SE1 - Titulos a Receber (referencia)

Titulos financeiros gerados automaticamente ao faturar o pedido de venda, representando os creditos a receber do cliente.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| E1_FILIAL | C | 8 | Filial |
| E1_PREFIXO | C | 3 | Prefixo do titulo |
| E1_NUM | C | 9 | Numero do titulo |
| E1_PARCELA | C | 1 | Parcela |
| E1_TIPO | C | 3 | Tipo do titulo (NF, DP, etc.) |
| E1_CLIENTE | C | 6 | Codigo do cliente |
| E1_LOJA | C | 2 | Loja do cliente |
| E1_EMISSAO | D | 8 | Data de emissao |
| E1_VENCTO | D | 8 | Data de vencimento |
| E1_VALOR | N | 14,2 | Valor do titulo |
| E1_SALDO | N | 14,2 | Saldo em aberto |
| E1_HIST | C | 40 | Historico |
| E1_NATUREZ | C | 10 | Natureza financeira |
| E1_VEND1 | C | 6 | Codigo do vendedor |

**Indices principais:**
- Ordem 1: `E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO`
- Ordem 2: `E1_FILIAL + E1_CLIENTE + E1_LOJA + E1_PREFIXO + E1_NUM`
- Ordem 3: `E1_FILIAL + E1_VENCTO`

---

## Rotinas Principais

### MATA030 - Cadastro de Clientes

**O que faz:** Permite incluir, alterar, excluir e visualizar o cadastro de clientes na tabela SA1. E o cadastro mestre utilizado em todo o ciclo de faturamento, contendo dados comerciais (limite de credito, risco, vendedor, condicao de pagamento) e fiscais (CNPJ, IE, endereco). A partir do Protheus 12, a rotina CRMA980 (MVC) substitui progressivamente o MATA030 quando `MV_MVCSA1` esta habilitado.

**Tabelas envolvidas:**
- SA1 (escrita) - Cadastro de Clientes
- SA3 (leitura) - Cadastro de Vendedores
- SE4 (leitura) - Condicoes de Pagamento
- AI0 (leitura) - IBGE (Municipios)

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_MVCSA1 | Habilita novo cadastro de clientes em MVC (CRMA980) |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MA030INC | Executado na inclusao do cliente |
| MA030ALT | Executado na alteracao do cliente |
| MA030TOK | Validacao customizada na confirmacao do cadastro |

---

### OMSA010 - Tabela de Precos

**O que faz:** Permite o cadastro e manutencao de tabelas de precos (DA0/DA1). Define os precos de venda dos produtos por tabela, com controle de vigencia, status (ativa/inativa) e desconto maximo. As tabelas de precos sao consultadas automaticamente na inclusao de pedidos de venda.

**Tabelas envolvidas:**
- DA0 (escrita) - Cabecalho da Tabela de Precos
- DA1 (escrita) - Itens da Tabela de Precos
- SB1 (leitura) - Cadastro de Produtos

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_LJRETVL | Define criterio de preco quando ha mais de uma tabela ativa (1=menor, 2=maior) |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| OM010CPO | Retorna array com campos adicionais da tabela DA1 |

---

### MATA410 - Pedido de Venda

**O que faz:** Permite incluir, alterar, excluir e visualizar pedidos de venda. E a rotina central do ciclo de faturamento, formalizando a venda de produtos ou servicos ao cliente com condicoes comerciais (precos, descontos, prazos, tabela de precos). O pedido pode ser gerado manualmente, a partir de um orcamento, ou automaticamente via ExecAuto (integracao e-commerce, EDI, etc.).

O codigo-fonte do MATA410 foi modularizado em processos incrementais, sendo o MATA410 padrao (BASE) responsavel pelas operacoes de inclusao, alteracao, exclusao, visualizacao, browse e interfaces.

**Tabelas envolvidas:**
- SC5 (escrita) - Cabecalho do Pedido de Venda
- SC6 (escrita) - Itens do Pedido de Venda
- SA1 (leitura) - Cadastro de Clientes
- SB1 (leitura) - Cadastro de Produtos
- DA0/DA1 (leitura) - Tabela de Precos
- SE4 (leitura) - Condicoes de Pagamento
- SA3 (leitura) - Cadastro de Vendedores
- SB2 (leitura) - Saldos por Armazem

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_BLOQUEI | Submete pedido a analise de credito na liberacao (.T./.F.) |
| MV_PZRESER | Prazo de validade da reserva de estoque (em dias) |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT410INC | Executado na rotina de inclusao do pedido (A410INCLUI) |
| MT410ALT | Executado na rotina de alteracao do pedido |
| MT410TOK | Valida confirmacao de inclusao, alteracao, exclusao e copia |
| MTA410I | Executado na rotina de gravacao do pedido (A410GRAVA) |
| M410ALOK | Executado antes de iniciar alteracao, exclusao ou copia |
| M410STTS | Executado apos todas as alteracoes no arquivo de pedido |
| MA410COR | Altera cores do cadastro de status do pedido |
| MA410LEG | Altera textos da legenda de status do pedido |
| A410LPCx | Manipula a carga dos dados do produto na inclusao do pedido |

---

### MATA440 - Liberacao de Pedidos de Venda

**O que faz:** Controla a liberacao dos pedidos de venda para faturamento, aplicando analise de credito do cliente e disponibilidade de estoque dos produtos. Os pedidos aptos para liberacao sao aqueles com status de "Pedido de Venda em Aberto". Gera registros na tabela SC9 (Itens Liberados), controlando as quantidades liberadas, bloqueadas por credito e bloqueadas por estoque.

Possui dois modos de operacao:
- **Manual:** apresenta os dados do pedido para verificacao e permite definir a quantidade a faturar.
- **Automatico:** libera um grupo de pedidos com base em parametros, avaliando credito do cliente, estoque disponivel e data de entrega.

Se existem 100 unidades em estoque e o usuario libera 180, sao gerados 2 registros na SC9: o primeiro com 100 unidades liberadas e o segundo com 80 unidades bloqueadas por estoque.

**Tabelas envolvidas:**
- SC9 (escrita) - Itens Liberados do Pedido
- SC5 (leitura/escrita) - Cabecalho do Pedido (atualiza C5_LIBEROK, C5_BLQ)
- SC6 (leitura) - Itens do Pedido de Venda
- SA1 (leitura) - Cadastro de Clientes (verifica credito)
- SB2 (leitura) - Saldos por Armazem (verifica estoque)

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_BLOQUEI | Habilita analise de credito na liberacao (.T. submete todos os pedidos) |
| MV_GRVBLQ2 | Gera bloqueio de estoque se nao houver saldo disponivel |
| MV_LIBNODP | Define se avalia credito para pedidos que nao geram duplicata (conforme TES). "S" avalia credito mesmo sem geracao de duplicata |
| MV_GERABLQ | Controla avaliacao de saldo por enderecos/lotes na liberacao. "S"=avalia saldos por endereco e bloqueia se insuficiente. Funciona em conjunto com MV_GRVBLQ2 |
| MV_CREDCLI | Define controle de credito por loja (L) ou por cliente (C) |
| MV_RESEST | Reserva estoque para pedidos sem credito aprovado. Quando ativo, gera reserva na SC0 mesmo com credito bloqueado |
| MV_MCUSTO | Define o custo a ser considerado na liberacao |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MTA440 | Customiza processo de liberacao de pedidos |
| M440FLOK | Validacao adicional no filtro de liberacao |

---

### MATA450 - Analise de Credito

**O que faz:** Permite avaliar o credito do cliente por pedido de venda, analisando sua situacao quanto a classificacao de risco (A1_RISCO), limite de credito (A1_LC) e data de vencimento desse limite (A1_VENCLC). O valor em analise e somado aos titulos em aberto (SE1) e pedidos em aberto (SC5/SC6) e comparado com o limite de credito, desde que a data de validade seja superior a data corrente.

Possui dois modos:
- **Automatico:** reavalia credito conforme parametros de risco, limite e vencimento.
- **Manual:** permite liberar ou bloquear credito independente da avaliacao parametrica.

**Tabelas envolvidas:**
- SC9 (leitura/escrita) - Itens Liberados (atualiza C9_BLCRED)
- SA1 (leitura) - Cadastro de Clientes (risco, limite, vencimento)
- SE1 (leitura) - Titulos a Receber (titulos em aberto)
- SC5/SC6 (leitura) - Pedidos em Aberto

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_BLOQUEI | Habilita controle de credito |
| MV_CREDCLI | Define controle de credito por loja (L) ou por cliente (C) |

---

### MATA455 - Liberacao de Estoque

**O que faz:** Permite verificar e liberar os itens de pedidos bloqueados por insuficiencia de estoque. Utilizada quando e necessario liberar em qualquer circunstancia, mesmo com estoque negativo.

Possui dois modos:
- **Automatico:** reprocessa a analise de estoque; se houver saldo suficiente apos reposicao, libera o pedido automaticamente.
- **Manual:** permite liberar o bloqueio independentemente do saldo, podendo deixar o estoque negativo (quando MV_ESTNEG permite).

**Tabelas envolvidas:**
- SC9 (leitura/escrita) - Itens Liberados (atualiza C9_BLEST)
- SB2 (leitura) - Saldos por Armazem

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_ESTNEG | Permite estoque negativo |
| MV_GRVBLQ2 | Gera bloqueio quando nao ha saldo |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MTA455E | Validacao da liberacao automatica de bloqueio de estoque |

---

### MATA460 / MATA461 - Documento de Saida (Nota Fiscal de Saida)

**O que faz:** MATA460 (interface/selecao de pedidos) e MATA461 (processamento/geracao) sao as rotinas de faturamento que geram a nota fiscal de saida (SF2/SD2) a partir dos pedidos de venda liberados. Os documentos de saida sao preparados para finalizar o processo de expedicao de mercadorias e/ou prestacao de servicos, gerando diferentes documentos: Nota Fiscal, Complemento de Preco, Complemento de ICMS, Complemento de IPI, Devolucao de Compra e Beneficiamento, conforme definido no pedido de venda.

Para que os documentos de saida sejam emitidos, os pedidos de venda devem estar liberados pela analise de credito do cliente e pela disponibilidade de estoque (SC9 sem bloqueios).

A rotina MATA460A e a versao mais recente, com interface modernizada.

**Tabelas envolvidas:**
- SF2 (escrita) - Cabecalho NF de Saida
- SD2 (escrita) - Itens NF de Saida
- SC5 (leitura/escrita) - Cabecalho do Pedido (atualiza C5_NOTA, C5_SERIE)
- SC6 (leitura/escrita) - Itens do Pedido (atualiza C6_QTDENT, C6_NOTA, C6_SERIE)
- SC9 (leitura/escrita) - Itens Liberados (atualiza vinculo com NF)
- SD3 (escrita) - Movimentacoes de Estoque (baixa)
- SE1 (escrita) - Titulos a Receber
- SFT (escrita) - Livros Fiscais
- CT2 (escrita) - Lancamentos Contabeis
- SA1 (leitura) - Cadastro de Clientes
- SB1 (leitura) - Cadastro de Produtos
- SB2 (leitura/escrita) - Saldos por Armazem (baixa de estoque)

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_DCSSPD | Define quais tipos de series de Documentos de Saida sao gerados no bloco F100 do SPED PIS/COFINS |
| MV_FATTRAV | Parametro de travamento/lock no faturamento. Controla bloqueio de tabelas durante gravacao de pedidos e geracao de NF |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| M460FIM | Executado apos gravacao da NF de saida (SF2/SD2). Permite manipular dados gravados |
| M460MARK | Validacao dos pedidos marcados para faturamento |
| M461LSF2 | Permite alterar dados da SF2 apos gravacao da NF |
| M461SER | Define serie e numero da NF de saida |
| M461SLD | Valida saldo de estoque do produto por lote/endereco |
| M461SB3 | Manipula atualizacao da tabela SB3 (saldos) na nota de saida |
| M461LEG | Altera titulos da legenda do browse de preparacao do documento de saida |
| SF2460I | Executado na atualizacao das tabelas referentes a nota fiscal |
| MAPVLNFS | Geracao de documento de saida a partir de itens do pedido de venda |

---

### MATA430 - Controle de Reservas

**O que faz:** Gerencia as reservas de estoque vinculadas aos pedidos de venda. Quando uma reserva excede o prazo de validade definido em MV_PZRESER e nao esta vinculada a nenhum pedido ativo, ao logar no modulo SIGAFAT, o processo de depuracao exclui automaticamente as reservas vencidas e atualiza o campo B2_RESERVA.

**Tabelas envolvidas:**
- SB2 (leitura/escrita) - Saldos por Armazem (atualiza B2_RESERVA)
- SC6 (leitura) - Itens do Pedido de Venda

---

### SPEDNFE (NF-e SEFAZ) - Transmissao de NF-e

**O que faz:** Rotina de transmissao da Nota Fiscal Eletronica (NF-e) para a SEFAZ (Secretaria da Fazenda). Acessada no SIGAFAT em Atualizacoes > NF-e e NFS-e > NF-e Sefaz (SPEDNFE), com a opcao Transmissao. Permite transmitir, consultar status, cancelar e inutilizar numeracao de NF-e.

Integra com o TSS (TOTVS Service SOA) para comunicacao com os web services da SEFAZ. Suporta contingencia automatica em caso de indisponibilidade da SEFAZ.

**Tabelas envolvidas:**
- SF2 (leitura/escrita) - Cabecalho NF de Saida (atualiza F2_CHVNFE, status de transmissao)
- SD2 (leitura) - Itens NF de Saida

---

## Processos de Negocio

### Fluxo Completo de Faturamento

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  1. Pedido de    │────>│  2. Liberacao    │────>│  3. Analise de   │
│  Venda           │     │  (MATA440)       │     │  Credito          │
│  MATA410/SC5+SC6 │     │  SC9             │     │  MATA450/SA1+SE1  │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                          │
┌─────────────────┐     ┌─────────────────┐     ┌────────v────────┐
│  6. Titulo a     │<────│  5. Transmissao  │<────│  4. Documento    │
│  Receber         │     │  NF-e            │     │  de Saida         │
│  SE1             │     │  SPEDNFE         │     │  MATA460-461      │
└─────────────────┘     └─────────────────┘     │  SF2+SD2          │
                                                 └─────────────────┘
```

#### Passo 1: Pedido de Venda (MATA410)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA410 |
| **Tabelas** | SC5 (escrita), SC6 (escrita), SA1 (leitura), SB1 (leitura), DA0/DA1 (leitura), SE4 (leitura) |
| **O que acontece** | O vendedor ou usuario formaliza a venda informando cliente, produtos, quantidades, precos, tabela de precos, condicao de pagamento, TES e data de entrega. O sistema busca o preco na tabela de precos vinculada (DA1), aplica descontos e calcula impostos preliminares. Se `MV_BLOQUEI` estiver ativo, o pedido fica pendente de liberacao. |
| **Resultado** | Registros na SC5 (cabecalho) e SC6 (itens) |

#### Passo 2: Liberacao de Pedidos (MATA440)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA440 |
| **Tabelas** | SC9 (escrita), SC5 (leitura/escrita), SC6 (leitura), SA1 (leitura), SB2 (leitura) |
| **O que acontece** | O sistema avalia o credito do cliente (limite, risco, titulos em aberto) e a disponibilidade de estoque dos produtos. Se ambos forem aprovados, gera registro na SC9 com status liberado. Se houver impedimento, gera registro na SC9 com bloqueio de credito (C9_BLCRED) e/ou estoque (C9_BLEST). |
| **Resultado** | Registros na SC9 com status liberado ou bloqueado |

#### Passo 3: Analise de Credito e Estoque (MATA450/MATA455)

| Aspecto | Detalhe |
|---------|---------|
| **Rotinas** | MATA450 (credito), MATA455 (estoque), MATA456 (liberacao manual combinada) |
| **Tabelas** | SC9 (escrita), SA1 (leitura), SE1 (leitura), SB2 (leitura) |
| **O que acontece** | Para pedidos bloqueados, o responsavel financeiro analisa o credito do cliente (MATA450) e o responsavel de estoque verifica a disponibilidade (MATA455). A liberacao pode ser automatica (reavaliacao) ou manual (override). Apos liberacao, o registro SC9 tem os campos de bloqueio limpos. |
| **Resultado** | SC9 atualizada com bloqueios removidos; pedido apto para faturamento |

#### Passo 4: Documento de Saida (MATA460/MATA461)

| Aspecto | Detalhe |
|---------|---------|
| **Rotinas** | MATA460 (selecao/interface), MATA461 (processamento/geracao) |
| **Tabelas** | SF2 (escrita), SD2 (escrita), SC5 (escrita), SC6 (escrita), SC9 (escrita), SD3 (escrita), SE1 (escrita), SFT (escrita), CT2 (escrita), SB2 (escrita) |
| **O que acontece** | O usuario seleciona os pedidos liberados (SC9 sem bloqueios) e gera a nota fiscal de saida. O sistema grava o cabecalho da NF (SF2) e os itens (SD2), atualiza o saldo do pedido (C6_QTDENT), gera movimentacao de estoque (SD3 - baixa), titulo a receber (SE1), escrituracao fiscal (SFT) e lancamentos contabeis (CT2). O campo C5_NOTA e C6_NOTA sao atualizados com o numero da NF gerada. |
| **Resultado** | NF registrada (SF2/SD2), estoque baixado, financeiro gerado, fiscal escriturado |

#### Passo 5: Transmissao NF-e (SPEDNFE)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | SPEDNFE |
| **Tabelas** | SF2 (leitura/escrita - atualiza F2_CHVNFE e status) |
| **O que acontece** | A NF gerada e transmitida eletronicamente para a SEFAZ via TSS (TOTVS Service SOA). Apos autorizacao, o sistema grava a chave da NF-e (F2_CHVNFE) e o protocolo de autorizacao. Se a SEFAZ estiver indisponivel, o sistema pode usar contingencia automatica. |
| **Resultado** | NF-e autorizada pela SEFAZ com chave e protocolo gravados |

#### Passo 6: Titulo a Receber (SE1)

| Aspecto | Detalhe |
|---------|---------|
| **Tabelas** | SE1 (gerada automaticamente no passo 4) |
| **O que acontece** | O titulo a receber e gerado automaticamente no faturamento, conforme condicao de pagamento (SE4). O desdobramento em parcelas segue a regra da condicao. O titulo fica disponivel para o modulo Financeiro (SIGAFIN) para cobranca, baixa e conciliacao bancaria. |
| **Resultado** | Titulos em SE1 com vencimentos e valores conforme condicao de pagamento |

### Fluxo Simplificado (sem liberacao separada)

```
Pedido de Venda (SC5/SC6) → Documento de Saida (SF2/SD2) → Transmissao NF-e → Titulo a Receber (SE1)
```

Quando `MV_BLOQUEI` estiver desabilitado (.F.), o pedido pode ser faturado diretamente sem etapa intermediaria de liberacao.

---

## Regras de Negocio

### Campos obrigatorios por rotina

**Pedido de Venda (MATA410 - SC5/SC6):**
- C5_CLIENTE + C5_LOJACLI (Cliente)
- C5_CONDPAG (Condicao de pagamento)
- C5_TIPO (Tipo do pedido)
- C6_PRODUTO (Codigo do produto)
- C6_QTDVEN (Quantidade vendida)
- C6_PRCVEN (Preco unitario de venda)
- C6_TES (Tipo de Entrada/Saida)
- C6_LOCAL (Armazem)

**Documento de Saida (MATA460/461 - SD2):**
- D2_COD (Codigo do produto)
- D2_QUANT (Quantidade)
- D2_PRCVEN (Preco de venda)
- D2_TES (Tipo de Entrada/Saida)
- D2_DOC (Numero do documento)
- D2_SERIE (Serie da NF)
- D2_LOCAL (Armazem)

### Validacoes principais

| Validacao | Descricao |
|-----------|-----------|
| Credito do cliente | Se `MV_BLOQUEI` = .T., o pedido e submetido a analise de credito. Compara valor do pedido + titulos em aberto com limite de credito (A1_LC). Se exceder ou limite vencido, bloqueia |
| Estoque disponivel | Se `MV_GRVBLQ2` = .T., verifica saldo em estoque (SB2). Se insuficiente, gera bloqueio de estoque na SC9 |
| Cliente bloqueado | Nao permite gerar pedido para cliente com A1_MSBLQL = "1" |
| Desconto maximo | Valida se o desconto informado nao excede o maximo permitido (DA1_DESMAX na tabela de precos) |
| Saldo do pedido | Ao gerar NF, a quantidade nao pode ultrapassar o saldo do pedido (C6_QTDVEN - C6_QTDENT) |
| Reserva vencida | Reservas que excedem MV_PZRESER dias e nao estao vinculadas a pedidos sao depuradas automaticamente |
| Pedido liberado | Somente pedidos com registros na SC9 sem bloqueios de credito e estoque podem ser faturados |
| Residuo | Itens marcados como residuo (C6_BLQ = "R") nao participam do faturamento |
| Duplicidade de NF | Verifica numeracao sequencial da NF para evitar duplicidade |

### Gatilhos SX7 relevantes

| Campo origem | Campo destino | Regra | Tabela lookup |
|-------------|---------------|-------|---------------|
| C6_PRODUTO | C6_DESCRI | SB1->B1_DESC | SB1 |
| C6_PRODUTO | C6_UM | SB1->B1_UM | SB1 |
| C6_PRODUTO | C6_PRCVEN | DA1->DA1_PRCVEN (via tabela de precos) | DA1 |
| C5_CLIENTE | C5_CONDPAG | SA1->A1_COND | SA1 |
| C5_CLIENTE | C5_TABELA | SA1->A1_TABELA | SA1 |
| C5_CLIENTE | C5_VEND1 | SA1->A1_VEND | SA1 |
| C5_CLIENTE | C5_TRANSP | SA1->A1_TRANSP | SA1 |
| C6_QTDVEN * C6_PRCVEN | C6_VALOR | Calculado | - |
| D2_COD | D2_DESCRI | SB1->B1_DESC | SB1 |

### Pontos de entrada mais utilizados no modulo

| Ponto de Entrada | Rotina | Descricao |
|------------------|--------|-----------|
| MT410INC | MATA410 | Customiza inclusao do pedido de venda |
| MT410ALT | MATA410 | Customiza alteracao do pedido de venda |
| MT410TOK | MATA410 | Validacao na confirmacao de operacao no pedido |
| MTA410I | MATA410 | Pos-gravacao do pedido de venda |
| M410ALOK | MATA410 | Executado antes de alterar/excluir/copiar pedido |
| M410STTS | MATA410 | Pos-atualizacao de todas as alteracoes no pedido |
| MA410COR | MATA410 | Altera cores de status do pedido |
| MA410LEG | MATA410 | Altera textos da legenda de status |
| MTA440 | MATA440 | Customiza processo de liberacao |
| MTA455E | MATA455 | Validacao na liberacao automatica de estoque |
| M460FIM | MATA461 | Pos-gravacao da NF de saida |
| M460MARK | MATA461 | Validacao de pedidos marcados para faturamento |
| M461LSF2 | MATA461 | Altera dados da SF2 apos gravacao |
| M461SER | MATA461 | Define serie e numero da NF de saida |
| M461SLD | MATA461 | Valida saldo de estoque por lote/endereco |
| M461SB3 | MATA461 | Manipula atualizacao da SB3 na nota de saida |
| SF2460I | MATA461 | Atualizacao das tabelas referentes a NF |
| MAPVLNFS | MATA461 | Geracao de documento de saida a partir de itens do PV |
| MA030TOK | MATA030 | Validacao no cadastro de clientes |

---

## Integracoes

### Faturamento → Estoque

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na geracao do Documento de Saida (MATA461) |
| **O que acontece** | Gera movimentacao na SD3 (Movimentacoes de Estoque) do tipo Saida. Atualiza saldo do produto no armazem (SB2), reduzindo a quantidade disponivel. O tipo de movimento e definido pela TES informada no item da NF. A reserva de estoque (B2_RESERVA) e baixada correspondentemente |
| **Tabelas afetadas** | SD3 (movimentacao), SB2 (saldo por armazem), SB9 (saldo consolidado) |
| **Controles** | Se controle de lote/sublote estiver ativo (B1_RASTRO), exige informacao de lote. Se enderecamento ativo, exige endereco de saida |

### Faturamento → Financeiro

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na geracao do Documento de Saida (MATA461) |
| **O que acontece** | Gera titulo(s) a receber na SE1, desdobrados conforme a condicao de pagamento (SE4). O prefixo e numero do titulo sao baseados no numero da NF. A natureza financeira e determinada pela TES e/ou natureza da operacao (C5_NATUREZ). Comissoes do vendedor podem ser geradas na SE3 |
| **Tabelas afetadas** | SE1 (Titulos a Receber), SE3 (Comissoes) |
| **Observacao** | O titulo fica disponivel para o modulo Financeiro (SIGAFIN) para cobranca, bordero, baixa e conciliacao |

### Faturamento → Fiscal

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na geracao do Documento de Saida (MATA461) e na transmissao NF-e (SPEDNFE) |
| **O que acontece** | Gera escrituracao no livro de saidas (SFT/SF3). Registra valores de ICMS, IPI, PIS, COFINS, ICMS-ST e demais tributos conforme configuracao da TES e natureza de operacao (SED). A NF-e e transmitida para a SEFAZ via TSS, gerando chave de acesso (F2_CHVNFE) e protocolo |
| **Tabelas afetadas** | SFT (Livros Fiscais), SF3 (Resumo de NF), SF2 (chave NF-e) |
| **Observacao** | Integra com o modulo SIGAFIS para apuracao de impostos e obrigacoes acessorias (SPED Fiscal, EFD Contribuicoes) |

### Faturamento → Contabilidade

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na geracao do Documento de Saida (MATA461), se contabilizacao online estiver habilitada |
| **O que acontece** | Gera lancamentos contabeis na CT2, debitando contas de clientes/receita e creditando contas de estoque/impostos, conforme Lancamento Padrao (CT5) configurado na TES |
| **Tabelas afetadas** | CT2 (Lancamentos Contabeis) |
| **Observacao** | A contabilizacao por item da NF de saida foi implementada nas rotinas MATA461 e MATA521 (exclusao de NF) |

### Faturamento → Comissoes

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na geracao do Documento de Saida (MATA461) |
| **O que acontece** | Gera registros de comissao na SE3, com base no percentual de comissao informado no pedido (C6_COMIS1) e/ou cadastrado no vendedor (SA3). A rotina MATA490 (Manutencao de Comissao) permite consultar e ajustar comissoes |
| **Tabelas afetadas** | SE3 (Comissoes de Vendas) |

### Resumo das integracoes no Documento de Saida

```
                         MATA461 - Documento de Saida
                                     │
                    ┌────────────────┼────────────────┐
                    │                │                │
              ┌─────v─────┐   ┌─────v─────┐   ┌─────v─────┐
              │  Estoque   │   │ Financeiro│   │   Fiscal  │
              │ SD3 / SB2  │   │  SE1/SE3  │   │ SFT / SF3 │
              └───────────┘   └───────────┘   └───────────┘
                    │                                │
              ┌─────v─────┐                   ┌──────v──────┐
              │  Reservas  │                   │Contabilidade│
              │ B2_RESERVA │                   │     CT2     │
              └───────────┘                   └─────────────┘
                                                     │
                                              ┌──────v──────┐
                                              │  NF-e SEFAZ │
                                              │   SPEDNFE   │
                                              └─────────────┘
```

---

## Cadastros Auxiliares

| Rotina | Descricao | Tabela |
|--------|-----------|--------|
| MATA030 / CRMA980 | Cadastro de Clientes | SA1 |
| MATA040 | Cadastro de Vendedores | SA3 |
| OMSA010 | Tabela de Precos | DA0 / DA1 |
| MATA430 | Controle de Reservas | SB2 (B2_RESERVA) |
| MATA490 | Manutencao de Comissao | SE3 |
| MATA521 | Exclusao de NF de Saida | SF2 / SD2 |
| SPEDNFE | NF-e SEFAZ (Transmissao) | SF2 |
| MATA456 | Liberacao Manual de Credito e Estoque | SC9 |

---

## Parametros Globais do Modulo (MV_*)

| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| MV_BLOQUEI | L | Habilita analise de credito na liberacao de pedidos. Quando .T., submete todas as liberacoes a aprovacao de credito |
| MV_CREDCLI | C | Define controle de credito por loja (L) ou por cliente (C). Usado na liberacao automatica de credito |
| MV_DCSSPD | C | Define quais tipos de series de Documentos de Saida sao gerados no bloco F100 do SPED PIS/COFINS |
| MV_ESTNEG | L | Permite estoque negativo nas rotinas de faturamento e estoque |
| MV_FATTRAV | C | Parametro de travamento/lock no faturamento. Controla bloqueio de tabelas (SA1, SA2, SB2) durante gravacao de pedidos e geracao de NF |
| MV_GERABLQ | C | Controla avaliacao de saldo por enderecos/lotes na liberacao. "S"=avalia saldos por endereco e bloqueia se insuficiente. "N"=avalia e exige reducao de quantidade. Funciona em conjunto com MV_GRVBLQ2 |
| MV_GRVBLQ2 | L | Gera bloqueio de estoque quando nao ha saldo disponivel |
| MV_LIBNODP | C | Define se avalia credito para pedidos que nao geram duplicata (conforme TES). Conteudo "S" avalia credito mesmo sem geracao de duplicata |
| MV_LJRETVL | N | Define criterio de preco quando ha mais de uma tabela ativa (1=menor, 2=maior) |
| MV_MCUSTO | N | Define custo a ser considerado na liberacao |
| MV_MVCSA1 | L | Habilita novo cadastro de clientes em MVC (CRMA980) |
| MV_PZRESER | N | Prazo de validade da reserva de estoque (em dias) |
| MV_RESEST | L | Reserva estoque para pedidos sem credito aprovado. Quando ativo, gera reserva na SC0 mesmo com credito bloqueado |
