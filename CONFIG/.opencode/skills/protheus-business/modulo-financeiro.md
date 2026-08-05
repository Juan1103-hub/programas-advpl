# Modulo Financeiro (FIN)

## Visao Geral

O modulo Financeiro (SIGAFIN) do TOTVS Protheus gerencia todo o ciclo financeiro da empresa, abrangendo contas a pagar, contas a receber, movimentacoes bancarias, borderos, CNAB, compensacoes e conciliacao bancaria. Ele controla os titulos que representam obrigacoes de pagamento e direitos de recebimento, integrando-se diretamente com os modulos de Compras, Faturamento, Fiscal e Contabilidade.

**Prefixo do modulo:** FIN
**Sigla do ambiente:** SIGAFIN
**Prefixo das rotinas:** FINAx0x (ex: FINA010, FINA040, FINA050, FINA060, FINA070, FINA080, FINA090, FINA100, FINA110, FINA200, FINA240, FINA330, FINA340, FINA450)

### Ciclo principal financeiro

```
Inclusao de Titulo → Aprovacao → Bordero/CNAB → Baixa → Compensacao → Conciliacao Bancaria
```

O modulo permite tanto a inclusao manual de titulos quanto a geracao automatica a partir de documentos de entrada (Compras) e notas de saida (Faturamento). Os titulos passam por processos de agrupamento (bordero), comunicacao bancaria (CNAB), baixa (manual ou automatica), compensacao e conciliacao.

---

## Tabelas Principais

### SE1 - Titulos a Receber

Armazena os titulos que representam receitas da empresa: duplicatas, cheques, notas promissorias, adiantamentos, entre outros. Cada registro representa um titulo ou parcela a receber de um cliente.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| E1_FILIAL | C | 2 | Filial |
| E1_PREFIXO | C | 3 | Prefixo do titulo |
| E1_NUM | C | 9 | Numero do titulo |
| E1_PARCELA | C | 2 | Parcela do titulo |
| E1_TIPO | C | 3 | Tipo do titulo (NF, DP, CH, NCC, RA, etc.) |
| E1_CLIENTE | C | 6 | Codigo do cliente |
| E1_LOJA | C | 2 | Loja do cliente |
| E1_NOMCLI | C | 20 | Nome reduzido do cliente |
| E1_NATUREZ | C | 10 | Natureza financeira |
| E1_EMISSAO | D | 8 | Data de emissao |
| E1_VENCTO | D | 8 | Data de vencimento |
| E1_VENCREA | D | 8 | Data de vencimento real |
| E1_VALOR | N | 16,2 | Valor do titulo |
| E1_SALDO | N | 16,2 | Saldo em aberto |
| E1_DESCONT | N | 16,2 | Valor do desconto |
| E1_JUROS | N | 16,2 | Valor de juros |
| E1_MULTA | N | 16,2 | Valor de multa |
| E1_CORREC | N | 16,2 | Valor de correcao monetaria |
| E1_HIST | C | 40 | Historico do titulo |
| E1_PORTADO | C | 3 | Codigo do banco portador |
| E1_AGEDEP | C | 5 | Agencia depositaria |
| E1_CONTA | C | 10 | Conta corrente |
| E1_NUMBCO | C | 15 | Numero bancario do documento |
| E1_SITUACA | C | 1 | Situacao do titulo |
| E1_MOEDA | N | 2 | Moeda do titulo |
| E1_BAIXA | D | 8 | Data da baixa |
| E1_IRRF | N | 14,2 | Valor IRRF |
| E1_ISS | N | 14,2 | Valor ISS |
| E1_INSS | N | 14,2 | Valor INSS |
| E1_CSLL | N | 14,2 | Valor CSLL |
| E1_COFINS | N | 14,2 | Valor COFINS |
| E1_PIS | N | 14,2 | Valor PIS |
| E1_VEND1 | C | 6 | Codigo do vendedor 1 |
| E1_COMIS1 | N | 6,2 | Percentual de comissao 1 |
| E1_NUMBOR | C | 6 | Numero do bordero |

**Indices principais:**
- Ordem 1: `E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO`
- Ordem 2: `E1_FILIAL + E1_CLIENTE + E1_LOJA + E1_PREFIXO + E1_NUM`
- Ordem 3: `E1_FILIAL + E1_EMISSAO + E1_PREFIXO + E1_NUM`
- Ordem 4: `E1_FILIAL + E1_VENCTO + E1_PREFIXO + E1_NUM`

---

### SE2 - Titulos a Pagar

Armazena os titulos que representam obrigacoes de pagamento da empresa: duplicatas de fornecedores, impostos, alugueis, salarios, emprestimos, entre outros. Pode ser gerado manualmente ou automaticamente via documento de entrada (Compras).

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| E2_FILIAL | C | 2 | Filial |
| E2_PREFIXO | C | 3 | Prefixo do titulo |
| E2_NUM | C | 9 | Numero do titulo |
| E2_PARCELA | C | 2 | Parcela do titulo |
| E2_TIPO | C | 3 | Tipo do titulo (NF, DP, TX, PA, etc.) |
| E2_FORNECE | C | 6 | Codigo do fornecedor |
| E2_LOJA | C | 2 | Loja do fornecedor |
| E2_NOMFOR | C | 20 | Nome reduzido do fornecedor |
| E2_NATUREZ | C | 10 | Natureza financeira |
| E2_EMISSAO | D | 8 | Data de emissao |
| E2_VENCTO | D | 8 | Data de vencimento |
| E2_VENCREA | D | 8 | Data de vencimento real |
| E2_VALOR | N | 16,2 | Valor do titulo |
| E2_SALDO | N | 16,2 | Saldo em aberto |
| E2_DESCONT | N | 16,2 | Valor do desconto |
| E2_JUROS | N | 16,2 | Valor de juros |
| E2_MULTA | N | 16,2 | Valor de multa |
| E2_HIST | C | 40 | Historico do titulo |
| E2_PORTADO | C | 3 | Codigo do banco portador |
| E2_NUMBOR | C | 6 | Numero do bordero |
| E2_SITUACA | C | 1 | Situacao do titulo |
| E2_MOEDA | N | 2 | Moeda do titulo |
| E2_IRRF | N | 14,2 | Valor IRRF |
| E2_ISS | N | 14,2 | Valor ISS |
| E2_INSS | N | 14,2 | Valor INSS |
| E2_CSLL | N | 14,2 | Valor CSLL |
| E2_COFINS | N | 14,2 | Valor COFINS |
| E2_PIS | N | 14,2 | Valor PIS |
| E2_RATEIO | C | 1 | Rateio por centro de custo (S/N) |
| E2_CC | C | 9 | Centro de custo |
| E2_CONTA | C | 20 | Conta contabil |

**Indices principais:**
- Ordem 1: `E2_FILIAL + E2_PREFIXO + E2_NUM + E2_PARCELA + E2_TIPO + E2_FORNECE + E2_LOJA`
- Ordem 2: `E2_FILIAL + E2_FORNECE + E2_LOJA + E2_PREFIXO + E2_NUM`
- Ordem 3: `E2_FILIAL + E2_EMISSAO + E2_PREFIXO + E2_NUM`
- Ordem 4: `E2_FILIAL + E2_VENCTO + E2_PREFIXO + E2_NUM`

---

### SE5 - Movimentacao Bancaria

Registra todas as movimentacoes bancarias do sistema: baixas de titulos, transferencias entre contas, depositos, saques, pagamentos e recebimentos. E a tabela central de rastreamento financeiro.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| E5_FILIAL | C | 2 | Filial |
| E5_DATA | D | 8 | Data da movimentacao |
| E5_BANCO | C | 3 | Codigo do banco |
| E5_AGENCIA | C | 5 | Agencia bancaria |
| E5_CONTA | C | 10 | Conta corrente |
| E5_PREFIXO | C | 3 | Prefixo do titulo |
| E5_NUMERO | C | 9 | Numero do titulo |
| E5_PARCELA | C | 2 | Parcela do titulo |
| E5_TIPO | C | 3 | Tipo do titulo |
| E5_TIPODOC | C | 2 | Tipo da movimentacao (controle interno) |
| E5_NATUREZ | C | 10 | Natureza financeira |
| E5_VALOR | N | 16,2 | Valor da movimentacao |
| E5_RECPAG | C | 1 | Recebimento (R) ou Pagamento (P) |
| E5_CLIFOR | C | 6 | Codigo do cliente/fornecedor |
| E5_LOJA | C | 2 | Loja do cliente/fornecedor |
| E5_HISTOR | C | 40 | Historico do movimento |
| E5_MOTBX | C | 3 | Motivo da baixa |
| E5_SITUACA | C | 1 | Situacao (vazio=ativo, E=estorno) |
| E5_DTDISPO | D | 8 | Data de disponibilizacao |
| E5_MOEDA | C | 2 | Numerario/moeda |
| E5_NUMCHEQ | C | 15 | Numero do cheque |
| E5_DOCUMEN | C | 50 | Numero do documento |
| E5_VLJUROS | N | 16,2 | Valor de juros |
| E5_VLMULTA | N | 16,2 | Valor de multa |
| E5_VLCORRE | N | 16,2 | Valor de correcao monetaria |
| E5_VLDESCO | N | 16,2 | Valor do desconto |
| E5_VLACRES | N | 16,2 | Valor do acrescimo |
| E5_VLDECRE | N | 16,2 | Valor do decrescimo |
| E5_RECONC | C | 1 | Documento reconciliado (S/N) |
| E5_LA | C | 2 | Identificador de lancamento/deposito |
| E5_LOTE | C | 4 | Lote da baixa |
| E5_SEQ | C | 2 | Sequencia da baixa |
| E5_DEBITO | C | 20 | Conta contabil debito |
| E5_CREDITO | C | 20 | Conta contabil credito |
| E5_ORIGEM | C | 8 | Origem do movimento bancario |

**Indices principais:**
- Ordem 1: `E5_FILIAL + E5_DATA + E5_BANCO + E5_AGENCIA + E5_CONTA`
- Ordem 2: `E5_FILIAL + E5_NUMERO + E5_PREFIXO + E5_PARCELA + E5_TIPO`
- Ordem 3: `E5_FILIAL + E5_BANCO + E5_AGENCIA + E5_CONTA + E5_DATA`

**Nota sobre reestruturacao:** A tabela SE5 foi reestruturada na familia de tabelas FKx (FK5, FKA, FKD, etc.) para normalizacao e melhoria de performance. Dependendo da versao do Protheus, as movimentacoes podem estar distribuidas entre SE5 e as tabelas FKx.

---

### SA6 - Bancos

Cadastro mestre de bancos (contas correntes da empresa), utilizado em todo o ciclo financeiro para identificar as contas de origem/destino de movimentacoes.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| A6_FILIAL | C | 2 | Filial |
| A6_COD | C | 3 | Codigo do banco |
| A6_AGENCIA | C | 5 | Agencia |
| A6_NUMCON | C | 10 | Numero da conta corrente |
| A6_NOME | C | 30 | Nome do banco |
| A6_NREDUZ | C | 20 | Nome reduzido |
| A6_DVCTA | C | 1 | Digito verificador da conta |
| A6_DVAGE | C | 1 | Digito verificador da agencia |
| A6_MOEDA | N | 2 | Moeda da conta |
| A6_BCOOFI | C | 3 | Codigo oficial do banco (FEBRABAN) |
| A6_TIPOCTA | C | 1 | Tipo de conta (C=Corrente, P=Poupanca, I=Investimento) |

**Indices principais:**
- Ordem 1: `A6_FILIAL + A6_COD + A6_AGENCIA + A6_NUMCON`
- Ordem 2: `A6_FILIAL + A6_NOME`

---

### SE8 - Saldos Bancarios

Armazena os saldos diarios de cada conta bancaria. Atualizada automaticamente pelas movimentacoes registradas na SE5.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| E8_FILIAL | C | 2 | Filial |
| E8_BANCO | C | 3 | Codigo do banco |
| E8_AGENCIA | C | 5 | Agencia |
| E8_CONTA | C | 10 | Conta corrente |
| E8_DATA | D | 8 | Data do saldo |
| E8_MOEDA | N | 2 | Moeda |
| E8_SAINI | N | 16,2 | Saldo inicial do dia |
| E8_SAIFIM | N | 16,2 | Saldo final do dia |
| E8_ENTRADA | N | 16,2 | Total de entradas no dia |
| E8_SAIDA | N | 16,2 | Total de saidas no dia |

**Indices principais:**
- Ordem 1: `E8_FILIAL + E8_BANCO + E8_AGENCIA + E8_CONTA + E8_DATA + E8_MOEDA`

---

### SEA - Titulos em Bordero (Controle de Bordero)

Registra os titulos enviados ao banco via bordero, mantendo o historico de transferencias, situacoes de cobranca e comunicacao bancaria.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| EA_FILIAL | C | 2 | Filial |
| EA_PREFIXO | C | 3 | Prefixo do titulo |
| EA_NUM | C | 9 | Numero do titulo |
| EA_PARCELA | C | 2 | Parcela do titulo |
| EA_TIPO | C | 3 | Tipo do titulo |
| EA_PORTADO | C | 3 | Codigo do banco portador |
| EA_AGEDEP | C | 5 | Agencia depositaria |
| EA_NUMBOR | C | 6 | Numero do bordero |
| EA_DATABOR | D | 8 | Data do bordero |
| EA_CART | C | 1 | Carteira de cobranca |
| EA_FORNECE | C | 6 | Codigo do fornecedor |
| EA_LOJA | C | 2 | Loja do fornecedor |
| EA_NUMCON | C | 10 | Conta corrente |
| EA_SITUACA | C | 1 | Situacao do bordero |
| EA_SALDO | N | 16,2 | Saldo do titulo |
| EA_OCORR | C | 2 | Ocorrencia CNAB |
| EA_TRANSF | C | 1 | Status de transferencia |
| EA_MODELO | C | 2 | Modelo do bordero |
| EA_TIPOPAG | C | 2 | Tipo de pagamento |

**Indices principais:**
- Ordem 1: `EA_FILIAL + EA_PREFIXO + EA_NUM + EA_PARCELA + EA_TIPO`
- Ordem 2: `EA_FILIAL + EA_NUMBOR + EA_PREFIXO + EA_NUM`

---

### SED - Naturezas Financeiras

Cadastro de naturezas financeiras que classificam as operacoes a pagar e a receber, controlando tambem o calculo de retencoes tributarias.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| ED_FILIAL | C | 2 | Filial |
| ED_CODIGO | C | 10 | Codigo da natureza |
| ED_DESCRIC | C | 30 | Descricao da natureza |
| ED_TIPO | C | 1 | Tipo: S=Sintetica, A=Analitica |
| ED_CLASSE | C | 1 | Classe: R=Receita, D=Despesa |
| ED_CALCIRF | C | 1 | Calcula IRRF (S/N) |
| ED_CALCINR | C | 1 | Calcula INSS retido (S/N) |
| ED_CALCISS | C | 1 | Calcula ISS retido (S/N) |
| ED_CALCCSL | C | 1 | Calcula CSLL retida (S/N) |
| ED_CALCCOF | C | 1 | Calcula COFINS retida (S/N) |
| ED_CALCPIS | C | 1 | Calcula PIS retido (S/N) |

**Indices principais:**
- Ordem 1: `ED_FILIAL + ED_CODIGO`
- Ordem 2: `ED_FILIAL + ED_DESCRIC`

---

### FI9 - Controle CNAB

Armazena as informacoes de controle dos arquivos CNAB (remessa e retorno), vinculando titulos aos arquivos gerados e processados.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| FI9_FILIAL | C | 2 | Filial |
| FI9_BANCO | C | 3 | Codigo do banco |
| FI9_AGENCI | C | 5 | Agencia |
| FI9_CONTA | C | 10 | Conta corrente |
| FI9_LAYOUT | C | 6 | Layout CNAB |
| FI9_TIPO | C | 1 | Tipo: R=Remessa, T=Retorno |
| FI9_DTGER | D | 8 | Data de geracao |
| FI9_ARQCNB | C | 50 | Nome do arquivo CNAB |
| FI9_STATUS | C | 1 | Status do processamento |

---

### FK2 - Faturas

Armazena os cabecalhos de faturas que agrupam titulos a pagar ou a receber para cobranca ou pagamento consolidado.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| FK2_FILIAL | C | 2 | Filial |
| FK2_IDFATU | C | 9 | Identificador da fatura |
| FK2_PREFAT | C | 3 | Prefixo da fatura |
| FK2_TIPO | C | 1 | Tipo: R=Receber, P=Pagar |
| FK2_CLIFOR | C | 6 | Cliente/fornecedor |
| FK2_LOJA | C | 2 | Loja |
| FK2_VALOR | N | 16,2 | Valor total da fatura |
| FK2_EMISSA | D | 8 | Data de emissao |
| FK2_VENCTO | D | 8 | Data de vencimento |

---

## Rotinas Principais

### FINA010 - Naturezas Financeiras

**O que faz:** Cadastro e manutencao das naturezas financeiras na tabela SED. As naturezas funcionam como classificadores das operacoes financeiras (a pagar ou a receber) e sao responsaveis por definir o calculo de retencoes tributarias (IRRF, PIS, COFINS, CSLL, ISS, INSS). Devem ser agrupadas por tipo de operacao (receita ou despesa) para facilitar filtros em consultas e relatorios.

**Tabelas envolvidas:**
- SED (escrita) - Naturezas Financeiras
- SX5 (leitura) - Tabelas Genericas

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_MASCNAT | Mascara do codigo da natureza do titulo financeiro |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| FA010INC | Validacoes customizadas na inclusao de natureza |

---

### FINA040 - Contas a Receber

**O que faz:** Permite incluir, alterar, excluir e visualizar titulos a receber (SE1). Controla todos os documentos que geram receita para a empresa: duplicatas, cheques, notas promissorias, adiantamentos de clientes, entre outros. A inclusao pode ser manual (digitacao individual) ou automatica (a partir de notas de saida do Faturamento).

**Tabelas envolvidas:**
- SE1 (escrita) - Titulos a Receber
- SE5 (escrita) - Movimentacao Bancaria (na baixa)
- SA1 (leitura) - Cadastro de Clientes
- SED (leitura) - Naturezas Financeiras
- SE4 (leitura) - Condicoes de Pagamento
- SA6 (leitura) - Bancos

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_1DUP | Numero inicial da primeira duplicata |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| FA040INC | Validacoes customizadas na inclusao do titulo a receber |
| M040SE1 | Gravacao auxiliar de registros na SE1 (pos-gravacao) |
| F040VLDEX | Validacao na exclusao do titulo a receber |
| FA040GRV | Manipula dados antes da gravacao do titulo |
| FA040TRB | Customiza toolbar da rotina |

---

### FINA050 - Contas a Pagar

**O que faz:** Permite incluir, alterar, excluir e visualizar titulos a pagar (SE2). Controla os compromissos de pagamento da empresa: duplicatas de fornecedores, impostos, alugueis, salarios, emprestimos, insumos de producao, entre outros. A inclusao pode ser manual ou automatica (via documento de entrada do modulo Compras/Estoque).

**Tabelas envolvidas:**
- SE2 (escrita) - Titulos a Pagar
- SE5 (escrita) - Movimentacao Bancaria (na baixa)
- SA2 (leitura) - Cadastro de Fornecedores
- SED (leitura) - Naturezas Financeiras
- SE4 (leitura) - Condicoes de Pagamento
- SA6 (leitura) - Bancos

**Parametros relevantes:**

> Nenhum parametro MV_* confirmado no TDN para esta rotina especifica. Os parametros de impostos e retencoes sao configurados na natureza financeira (SED).

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| F050BROW | Pre-validacao de dados no browse do Contas a Pagar |
| F050PERGUNT | Altera configuracao de perguntas na rotina automatica |
| F050MCP | Adiciona campos na alteracao do Contas a Pagar |
| FA050GRV | Manipula dados antes da gravacao do titulo |
| F050VLDEX | Validacao na exclusao do titulo a pagar |

---

### FINA060 - Transferencias / Bordero de Recebimento

**O que faz:** Permite transferir titulos a receber para carteiras de cobranca (simples, descontada, caucionada, vinculada). Realiza transferencias manuais (titulo a titulo) ou via bordero (multiplos titulos de uma vez). O bordero pode ser utilizado para gerar arquivos de remessa CNAB para envio ao banco. Calcula IOF em transferencias para situacao de cobranca descontada.

**Tabelas envolvidas:**
- SE1 (leitura/escrita) - Titulos a Receber (atualiza situacao/portador)
- SEA (escrita) - Titulos em Bordero
- SE5 (escrita) - Movimentacao Bancaria
- SA6 (leitura) - Bancos

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_NUMBORR | Numeracao sequencial do bordero a receber |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| F060FILSE1 | Filtro customizado na selecao de titulos para bordero |
| F060BORDE | Manipula dados do bordero antes da gravacao |
| F060IMPTIT | Impostos na transferencia de titulo |

---

### FINA070 - Baixas a Receber (Manual)

**O que faz:** Registra o recebimento individual de titulos a receber. Permite informar o valor efetivamente recebido, acrescimos (juros, multa, correcao) e descontos. O valor recebido, parcial ou total, nunca pode ser maior que o saldo liquido do titulo. Gera movimentacao na SE5 e atualiza saldo na SE1.

**Tabelas envolvidas:**
- SE1 (leitura/escrita) - Titulos a Receber (atualiza E1_SALDO, E1_BAIXA)
- SE5 (escrita) - Movimentacao Bancaria
- SA6 (leitura) - Bancos
- FKD (escrita) - Valores Acessorios (se aplicavel)

**Parametros relevantes:**

> Nenhum parametro MV_* confirmado no TDN para esta rotina especifica. Os parametros de juros, multa e desconto sao configurados via MV_JURTIPO, MV_TXPER e na natureza financeira.

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| F070VDATA | Validacao de dados da baixa a receber |
| F070INCSE5 | Manipula dados da SE5 gerada pela baixa |
| F070BXCR | Pos-gravacao da baixa a receber |
| F070ACRE | Altera valor de acrescimo/decrescimo na baixa |

---

### FINA080 - Baixas a Pagar (Manual)

**O que faz:** Registra o pagamento individual de titulos a pagar. Permite definir o motivo da baixa (tabela de motivos previamente cadastrada), que pode gerar movimentacao bancaria ou emitir cheque. Para titulos em bordero, somente a baixa total e permitida na FINA080.

**Tabelas envolvidas:**
- SE2 (leitura/escrita) - Titulos a Pagar (atualiza E2_SALDO)
- SE5 (escrita) - Movimentacao Bancaria
- SA6 (leitura) - Bancos
- FKD (escrita) - Valores Acessorios (se aplicavel)

**Parametros relevantes:**

> Nenhum parametro MV_* confirmado no TDN para esta rotina especifica. Os parametros de juros, multa e desconto sao configurados via MV_JURTIPO, MV_TXPER e na natureza financeira.

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| F080ACRE | Altera valor de acrescimo/decrescimo na baixa a pagar |
| F080VDATA | Validacao de dados da baixa a pagar |
| F080INCSE5 | Manipula dados da SE5 gerada pela baixa |
| F080BXCP | Pos-gravacao da baixa a pagar |

---

### FINA090 - Baixas a Pagar (Automatica)

**O que faz:** Executa a baixa automatica de multiplos titulos a pagar simultaneamente. Seleciona titulos por faixa de fornecedor, natureza, vencimento, prefixo, entre outros filtros. A partir de abril/2022, as rotinas FINA090 e FINA091 foram unificadas na FINA090 (a FINA091, que era multi-filial, foi descontinuada).

**Tabelas envolvidas:**
- SE2 (leitura/escrita) - Titulos a Pagar
- SE5 (escrita) - Movimentacao Bancaria
- SA6 (leitura) - Bancos

**Parametros relevantes:**

> Nenhum parametro MV_* confirmado no TDN para esta rotina especifica.

---

### FINA100 - Movimentos Bancarios

**O que faz:** Permite realizar transferencias entre contas bancarias, alimentando o saldo na SE8 e registrando a movimentacao na SE5. Caracteristica principal: nao gera receitas ou despesas para a empresa, controlando apenas entradas e saidas de valores entre contas. Ao cancelar um movimento, gera registro na SE5 com E5_SITUACA = 'E' (estorno).

**Tabelas envolvidas:**
- SE5 (escrita) - Movimentacao Bancaria
- SE8 (escrita) - Saldos Bancarios
- SA6 (leitura) - Bancos

**Parametros relevantes:**

> Nenhum parametro MV_* confirmado no TDN para esta rotina especifica. O numero do documento bancario e armazenado no campo E1_NUMBCO/E5_NUMBCO, nao em um parametro MV_.

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| F100FILBCO | Filtro de bancos disponiveis na movimentacao |
| F100HIST | Manipula historico do movimento bancario |
| F110SE5 | Manipulacao de titulos processados na SE5 |

---

### FINA110 - Baixa Automatica de Titulos a Receber

**O que faz:** Executa a baixa automatica de multiplos titulos a receber simultaneamente. Similar a FINA090 para o lado de recebimentos. Processa titulos por faixa de cliente, vencimento, prefixo, entre outros criterios.

**Tabelas envolvidas:**
- SE1 (leitura/escrita) - Titulos a Receber
- SE5 (escrita) - Movimentacao Bancaria
- SA6 (leitura) - Bancos

**Parametros relevantes:**

> Nenhum parametro MV_* confirmado no TDN para esta rotina especifica.

---

### FINA200 - Retorno de Cobrancas (CNAB Receber)

**O que faz:** Processa os arquivos de retorno CNAB enviados pelo banco para contas a receber. Realiza a baixa automatica dos titulos conforme as ocorrencias informadas no arquivo (confirmacao de pagamento, rejeicao, protesto, etc.). Cada ocorrencia do banco deve estar vinculada a uma ocorrencia do sistema (cadastrada via FINA140).

**Tabelas envolvidas:**
- SE1 (leitura/escrita) - Titulos a Receber (atualiza situacao/baixa)
- SE5 (escrita) - Movimentacao Bancaria
- SEA (leitura/escrita) - Titulos em Bordero
- FI9 (escrita) - Controle CNAB
- SA6 (leitura) - Bancos

**Parametros relevantes:**

> Nenhum parametro MV_* confirmado no TDN para esta rotina especifica. A configuracao de layout CNAB e feita nas tabelas EE*/SEE.

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| F200FILCNAB | Filtro de arquivos CNAB para processamento |
| FA200RET | Manipula dados do retorno antes da baixa |
| NGFPOSE1 | Posiciona SE1 para baixa do titulo no retorno |

---

### FINA240 - Bordero de Pagamentos

**O que faz:** Agrupa titulos a pagar em borderos para envio ao banco com instrucoes sobre a forma de pagamento. O bordero pode ser impresso ou gerado em arquivo TXT (mesmo mecanismo do CNAB). Apos a geracao do bordero de pagamento, os titulos sao automaticamente baixados. Inclui opcoes de cancelamento de bordero.

**Tabelas envolvidas:**
- SE2 (leitura/escrita) - Titulos a Pagar
- SEA (escrita) - Titulos em Bordero
- SE5 (escrita) - Movimentacao Bancaria
- SA6 (leitura) - Bancos

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_NUMBORP | Numeracao sequencial do bordero a pagar |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| F240MARK | Altera MarkBrowse do bordero de pagamentos |
| F240PCB | Validacao do cancelamento de bordero |
| F240SE2 | Manipula titulos antes da inclusao no bordero |

---

### FINA241 - Bordero de Impostos

**O que faz:** Variacao do bordero de pagamentos que agrupa titulos a pagar com retencao de impostos (IRRF, PIS, COFINS, CSLL, ISS, INSS). Realiza as deducoes tributarias no momento do pagamento e gera o arquivo de remessa CNAB incluindo os valores liquidos.

**Tabelas envolvidas:**
- SE2 (leitura/escrita) - Titulos a Pagar
- SEA (escrita) - Titulos em Bordero
- SE5 (escrita) - Movimentacao Bancaria

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| F241MARK | Altera MarkBrowse do bordero de impostos |
| F241IRAN | Customizacao na conclusao do bordero com impostos |

---

### FINA290 - Faturas a Pagar

**O que faz:** Agrupa titulos a pagar em uma unica fatura para pagamento consolidado. Permite a selecao de titulos do mesmo fornecedor para composicao de uma fatura unificada.

**Tabelas envolvidas:**
- SE2 (leitura/escrita) - Titulos a Pagar
- FK2 (escrita) - Faturas

---

### FINA330 - Compensacao Contas a Receber

**O que faz:** Permite compensar titulos a receber entre si. Seleciona um titulo de referencia (normalmente tipo NF) e compensa com outros titulos do mesmo cliente (adiantamentos, notas de credito, etc.). Suporta compensacao com titulos em moeda estrangeira, realizando a conversao pela taxa contratada.

**Tabelas envolvidas:**
- SE1 (leitura/escrita) - Titulos a Receber
- SE5 (escrita) - Movimentacao Bancaria

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| F330COMP | Manipula dados da compensacao a receber |

---

### FINA340 - Compensacao Contas a Pagar

**O que faz:** Permite compensar titulos a pagar entre si. Funciona de forma similar a FINA330, porem para o lado das obrigacoes. Aceita apenas juros, multa e descontos registrados junto com o titulo (sem vinculo com valores acessorios). Permite tambem o estorno da compensacao.

**Tabelas envolvidas:**
- SE2 (leitura/escrita) - Titulos a Pagar
- SE5 (escrita) - Movimentacao Bancaria

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| F340COMP | Manipula dados da compensacao a pagar |

---

### FINA430 - Retorno CNAB a Pagar

**O que faz:** Processa os arquivos de retorno CNAB enviados pelo banco para contas a pagar. Confirma ou rejeita pagamentos conforme ocorrencias do arquivo de retorno, de acordo com o layout configurado no CNAB a Pagar (CFGX043).

**Tabelas envolvidas:**
- SE2 (leitura/escrita) - Titulos a Pagar
- SE5 (escrita) - Movimentacao Bancaria
- SEA (leitura/escrita) - Titulos em Bordero
- SA6 (leitura) - Bancos

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| FA430SE2 | Posiciona tabela SE2 para baixa no retorno CNAB a pagar |

---

### FINA450 - Compensacao entre Carteiras

**O que faz:** Permite compensar titulos a pagar com titulos a receber do mesmo cliente/fornecedor. Requer um titulo a pagar e um titulo a receber disponiveis para compensacao. Zera (total ou parcialmente) os saldos de ambos os titulos de forma cruzada.

**Tabelas envolvidas:**
- SE1 (leitura/escrita) - Titulos a Receber
- SE2 (leitura/escrita) - Titulos a Pagar
- SE5 (escrita) - Movimentacao Bancaria

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| F450GRAVA | Manipulacao dos arquivos temporarios SE1/SE2 na compensacao |
| F450OWN1 | Filtro da tabela SE2 na compensacao entre carteiras |

---

### FINA473 - Conciliacao Bancaria Automatica

**O que faz:** Realiza a conciliacao automatica entre os movimentos registrados no sistema (SE5) e o extrato bancario importado. Compara valores, datas e identificadores para conciliar os registros automaticamente. Complementa a conciliacao manual (FINA380).

**Tabelas envolvidas:**
- SE5 (leitura/escrita) - Movimentacao Bancaria (marca E5_RECONC)
- SIG (leitura) - Extrato Bancario Importado
- SA6 (leitura) - Bancos

---

### FINA210 - Recalculo de Saldos Bancarios

**O que faz:** Reprocessa os saldos bancarios na SE8 com base nas movimentacoes registradas na SE5. Utilizada para corrigir eventuais inconsistencias entre movimentacoes e saldos.

**Tabelas envolvidas:**
- SE5 (leitura) - Movimentacao Bancaria
- SE8 (escrita) - Saldos Bancarios
- SA6 (leitura) - Bancos

---

### FINA750 - Funcoes Contas a Pagar

**O que faz:** Painel centralizado de funcoes para contas a pagar. Oferece acesso rapido as principais operacoes: inclusao de titulos, bordero, baixa automatica, CNAB, compensacao e consultas. Funciona como ponto de entrada unificado para as rotinas de pagamento.

**Tabelas envolvidas:**
- SE2 (leitura) - Titulos a Pagar
- SA6 (leitura) - Bancos

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| F750BROW | Manipula opcoes do menu da rotina |

---

## Processos de Negocio

### Fluxo Completo de Contas a Pagar

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  1. Inclusao     │────>│  2. Aprovacao    │────>│  3. Bordero de   │
│  Titulo a Pagar  │     │  (opcional)      │     │  Pagamento       │
│  FINA050 / SE2   │     │  Alcadas         │     │  FINA240 / SEA   │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                          │
┌─────────────────┐     ┌─────────────────┐     ┌────────v────────┐
│  6. Conciliacao  │<────│  5. Retorno      │<────│  4. CNAB         │
│  Bancaria        │     │  CNAB            │     │  Remessa         │
│  FINA473/FINA380 │     │  FINA430         │     │  CFGX043         │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

#### Passo 1: Inclusao do Titulo a Pagar (FINA050 ou automatico)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | FINA050 (manual) ou MATA103 (automatico via documento de entrada) |
| **Tabelas** | SE2 (escrita), SED (leitura), SA2 (leitura) |
| **O que acontece** | Titulo e incluido com fornecedor, valor, vencimento, natureza financeira e condicao de pagamento. Se originado do Compras, o titulo e gerado automaticamente na classificacao do documento de entrada, desdobrado conforme condicao de pagamento (SE4). |
| **Resultado** | Registro(s) na SE2 com saldo em aberto |

#### Passo 2: Aprovacao (opcional)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | Alcadas/aprovacao configuradas por parametro |
| **O que acontece** | Se controle de alcada estiver ativo, titulos acima de determinados valores podem exigir aprovacao antes de seguir para pagamento. |
| **Resultado** | Titulo liberado para pagamento |

#### Passo 3: Bordero de Pagamento (FINA240)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | FINA240 |
| **Tabelas** | SE2 (leitura), SEA (escrita), SE5 (escrita) |
| **O que acontece** | Titulos sao agrupados em bordero por banco/agencia/conta. O bordero pode ser impresso ou gerar arquivo TXT para envio ao banco. Os titulos sao marcados com numero do bordero (E2_NUMBOR). |
| **Resultado** | Bordero gerado, titulos vinculados na SEA, baixa automatica dos titulos |

#### Passo 4: Remessa CNAB (CFGX043)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | Configurador CNAB a Pagar (CFGX043) |
| **Tabelas** | SEA (leitura), FI9 (escrita) |
| **O que acontece** | Arquivo de remessa (.txt) e gerado conforme layout CNAB configurado (240 ou 400 posicoes). Enviado ao banco com instrucoes de pagamento (tipo, data, valor, favorecido). |
| **Resultado** | Arquivo CNAB gerado e registrado para controle |

#### Passo 5: Retorno CNAB (FINA430)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | FINA430 |
| **Tabelas** | SE2 (escrita), SE5 (escrita), SEA (escrita) |
| **O que acontece** | Arquivo de retorno do banco e processado. Ocorrencias confirmam ou rejeitam pagamentos. Titulos confirmados tem a baixa efetivada; rejeitados retornam ao status anterior. |
| **Resultado** | Titulos baixados ou devolvidos conforme retorno bancario |

#### Passo 6: Conciliacao Bancaria (FINA473/FINA380)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | FINA473 (automatica) / FINA380 (manual) |
| **Tabelas** | SE5 (escrita - marca E5_RECONC), SIG (leitura) |
| **O que acontece** | Movimentos do sistema (SE5) sao confrontados com o extrato bancario importado (SIG). Movimentos conciliados sao marcados como reconciliados. Divergencias sao sinalizadas para tratamento manual. |
| **Resultado** | Movimentacoes conciliadas entre sistema e banco |

### Fluxo Completo de Contas a Receber

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  1. Inclusao     │────>│  2. Bordero de   │────>│  3. CNAB         │
│  Titulo a Receber│     │  Recebimento     │     │  Remessa         │
│  FINA040 / SE1   │     │  FINA060 / SEA   │     │  (cobranca)      │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                          │
┌─────────────────┐     ┌─────────────────┐     ┌────────v────────┐
│  5. Conciliacao  │<────│  4. Retorno      │<────│  Envio ao        │
│  Bancaria        │     │  CNAB            │     │  Banco           │
│  FINA473/FINA380 │     │  FINA200         │     │                  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

#### Passo 1: Inclusao do Titulo a Receber (FINA040 ou automatico)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | FINA040 (manual) ou MATA461/MATA468 (automatico via faturamento) |
| **Tabelas** | SE1 (escrita), SED (leitura), SA1 (leitura) |
| **O que acontece** | Titulo e incluido com cliente, valor, vencimento e natureza. Se originado do Faturamento, e gerado automaticamente ao emitir nota fiscal de saida, desdobrado conforme condicao de pagamento. |
| **Resultado** | Registro(s) na SE1 com saldo em aberto |

#### Passo 2: Bordero de Recebimento / Transferencia (FINA060)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | FINA060 |
| **Tabelas** | SE1 (escrita), SEA (escrita) |
| **O que acontece** | Titulos sao transferidos para carteira de cobranca (simples, descontada, caucionada). Podem ser agrupados em bordero para envio ao banco. |
| **Resultado** | Titulos vinculados na SEA com situacao de cobranca definida |

#### Passo 3: Remessa CNAB (cobranca)

| Aspecto | Detalhe |
|---------|---------|
| **O que acontece** | Arquivo de remessa CNAB de cobranca e gerado com instrucoes ao banco (cobrar, protestar, alterar vencimento, etc.). |
| **Resultado** | Arquivo CNAB enviado ao banco para cobranca |

#### Passo 4: Retorno CNAB (FINA200)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | FINA200 |
| **Tabelas** | SE1 (escrita), SE5 (escrita), SEA (escrita) |
| **O que acontece** | Arquivo de retorno do banco e processado. Ocorrencias indicam: confirmacao de pagamento, rejeicao, protesto, alteracao de vencimento. Titulos pagos sao baixados automaticamente. |
| **Resultado** | Titulos baixados ou com instrucoes processadas |

### Fluxo de Baixa Manual

```
Titulo em aberto (SE1/SE2) → Baixa Manual (FINA070/FINA080) → Movimentacao Bancaria (SE5) → Saldo Bancario (SE8)
```

### Fluxo de Compensacao

```
Titulo a Receber (SE1) + Titulo a Pagar (SE2) → Compensacao entre Carteiras (FINA450) → Abatimento mutuo de saldos
```

---

## Regras de Negocio

### Campos obrigatorios por rotina

**Contas a Receber (FINA040 - SE1):**
- E1_PREFIXO (Prefixo do titulo)
- E1_NUM (Numero do titulo)
- E1_TIPO (Tipo do titulo)
- E1_CLIENTE + E1_LOJA (Cliente)
- E1_NATUREZ (Natureza financeira)
- E1_EMISSAO (Data de emissao)
- E1_VENCTO (Data de vencimento)
- E1_VALOR (Valor do titulo)

**Contas a Pagar (FINA050 - SE2):**
- E2_PREFIXO (Prefixo do titulo)
- E2_NUM (Numero do titulo)
- E2_TIPO (Tipo do titulo)
- E2_FORNECE + E2_LOJA (Fornecedor)
- E2_NATUREZ (Natureza financeira)
- E2_EMISSAO (Data de emissao)
- E2_VENCTO (Data de vencimento)
- E2_VALOR (Valor do titulo)

**Baixa Manual a Pagar (FINA080 - SE5):**
- Banco/Agencia/Conta de pagamento
- Data da baixa
- Valor da baixa
- Motivo da baixa

**Baixa Manual a Receber (FINA070 - SE5):**
- Banco/Agencia/Conta de recebimento
- Data da baixa
- Valor recebido
- Motivo da baixa

### Validacoes principais

| Validacao | Descricao |
|-----------|-----------|
| Saldo do titulo | O valor da baixa (parcial ou total) nunca pode ultrapassar o saldo em aberto do titulo (E1_SALDO ou E2_SALDO) |
| Titulo em bordero | Titulos vinculados a bordero somente podem ser baixados totalmente na FINA080; baixa parcial nao e permitida |
| Duplicidade de titulo | Verifica duplicidade de numero de titulo por cliente/fornecedor (chave unica: FILIAL + PREFIXO + NUM + PARCELA + TIPO + CLIFOR + LOJA) |
| Data da baixa | Data da baixa nao pode ser anterior a data de emissao do titulo (exceto se parametro permitir) |
| Natureza obrigatoria | Todo titulo deve ter natureza financeira valida cadastrada na SED |
| Retencoes tributarias | Se a natureza configurar calculo de retencoes (IRRF, PIS, COFINS, CSLL, ISS, INSS), os valores sao calculados automaticamente e deduzidos do titulo |
| Motivo de baixa | Na baixa manual, e obrigatorio informar motivo de baixa previamente cadastrado na tabela de motivos |
| Fornecedor/Cliente valido | Fornecedor (SE2→SA2) ou cliente (SE1→SA1) deve existir e nao estar bloqueado |
| Estorno de baixa | Ao estornar uma baixa, e gerado registro na SE5 com E5_SITUACA = 'E' (estorno), recompondo o saldo do titulo |

### Gatilhos SX7 relevantes

| Campo origem | Campo destino | Regra | Tabela lookup |
|-------------|---------------|-------|---------------|
| E1_CLIENTE | E1_NOMCLI | SA1->A1_NREDUZ | SA1 |
| E1_NATUREZ | (retencoes) | SED->ED_CALCIRF, ED_CALCPIS, etc. | SED |
| E2_FORNECE | E2_NOMFOR | SA2->A2_NREDUZ | SA2 |
| E2_NATUREZ | (retencoes) | SED->ED_CALCIRF, ED_CALCPIS, etc. | SED |
| E1_VENCTO | E1_VENCREA | Calcula vencimento real (dias uteis) | - |
| E2_VENCTO | E2_VENCREA | Calcula vencimento real (dias uteis) | - |

### Tipos de titulo mais comuns

| Tipo | Descricao | Carteira |
|------|-----------|----------|
| NF | Nota Fiscal / Duplicata | CP e CR |
| DP | Duplicata | CP e CR |
| CH | Cheque | CR |
| NCC | Nota de Credito ao Cliente | CR (credito) |
| RA | Recebimento Antecipado (adiantamento) | CR |
| PA | Pagamento Antecipado (adiantamento) | CP |
| TX | Impostos/Taxas | CP |
| PR | Provisao | CP |
| AB | Abatimento | CP e CR |
| NC | Nota de Credito ao Fornecedor | CP (credito) |

### Pontos de entrada mais utilizados no modulo

| Ponto de Entrada | Rotina | Descricao |
|------------------|--------|-----------|
| FA040INC | FINA040 | Validacao customizada na inclusao do titulo a receber |
| M040SE1 | FINA040 | Pos-gravacao do titulo a receber |
| F050BROW | FINA050 | Pre-validacao no browse do contas a pagar |
| FA050GRV | FINA050 | Manipula dados antes da gravacao do titulo a pagar |
| F070VDATA | FINA070 | Validacao de dados da baixa a receber |
| F070INCSE5 | FINA070 | Manipula SE5 gerada pela baixa a receber |
| F080ACRE | FINA080 | Altera acrescimo/decrescimo na baixa a pagar |
| F080INCSE5 | FINA080 | Manipula SE5 gerada pela baixa a pagar |
| F060BORDE | FINA060 | Manipula dados do bordero de recebimento |
| F240MARK | FINA240 | Altera MarkBrowse do bordero de pagamento |
| F240PCB | FINA240 | Validacao do cancelamento de bordero |
| F241IRAN | FINA241 | Customizacao no bordero de impostos |
| FA200RET | FINA200 | Manipula dados do retorno CNAB a receber |
| FA430SE2 | FINA430 | Posiciona SE2 no retorno CNAB a pagar |
| F450GRAVA | FINA450 | Manipula SE1/SE2 na compensacao entre carteiras |
| FINALEG | Varias | Manipula legendas de cores no browse financeiro |

---

## Integracoes

### Financeiro <-> Compras

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na classificacao do Documento de Entrada (MATA103) |
| **O que acontece** | O modulo de Compras gera automaticamente titulos a pagar (SE2) ao classificar um documento de entrada. Os titulos sao desdobrados conforme a condicao de pagamento (SE4). O prefixo e numero do titulo sao baseados no numero da NF. A natureza financeira e determinada pela TES. |
| **Tabelas afetadas** | SE2 (Titulos a Pagar gerados automaticamente) |
| **Observacao** | O titulo fica disponivel no SIGAFIN para bordero, pagamento e baixa. Alteracoes no titulo via FINA050 nao retroagem ao documento de entrada |

### Financeiro <-> Faturamento

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na emissao da Nota Fiscal de Saida (MATA461/MATA468) |
| **O que acontece** | O modulo de Faturamento gera automaticamente titulos a receber (SE1) ao emitir nota fiscal de saida. Os titulos sao desdobrados conforme a condicao de pagamento (SE4). O prefixo, numero e tipo do titulo sao baseados nos dados da NF de saida. |
| **Tabelas afetadas** | SE1 (Titulos a Receber gerados automaticamente) |
| **Observacao** | Comissoes de vendedores (E1_VEND1..5 / E1_COMIS1..5) sao herdadas do pedido de venda ou configuracao do cadastro de clientes |

### Financeiro -> Contabilidade

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na inclusao de titulos (SE1/SE2), na baixa (FINA070/FINA080/FINA090/FINA110), na movimentacao bancaria (FINA100) e na compensacao |
| **O que acontece** | Gera lancamentos contabeis na CT2 conforme Lancamento Padrao (CT5) configurado. Na inclusao: debita contas de clientes/fornecedores e credita contas de receita/despesa. Na baixa: debita/credita contas de banco e abate o titulo. |
| **Tabelas afetadas** | CT2 (Lancamentos Contabeis) |
| **Parametro** | A contabilizacao e controlada pelo Lancamento Padrao (CT5) e pela flag MV_CTBFLAG |
| **Observacao** | A contabilizacao pode ser online (no momento da operacao) ou offline (via rotina CTBAFIN em lote) |

### Financeiro -> Fiscal (Retencoes)

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na inclusao e/ou baixa de titulos a pagar e a receber |
| **O que acontece** | Com base na natureza financeira (SED), o sistema calcula automaticamente as retencoes tributarias: IRRF, PIS, COFINS, CSLL, ISS e INSS. Os valores sao deduzidos do titulo e podem gerar titulos de imposto separados (tipo TX). As retencoes sao consideradas nas obrigacoes acessorias (EFD-REINF, DIRF, etc.). |
| **Tabelas afetadas** | SE2 (titulos de imposto gerados), SFT (escrituracao fiscal quando aplicavel) |
| **Observacao** | A configuracao de retencoes e feita na natureza financeira (SED) e nos parametros MV_ALIQIRF, MV_VLRETIR, MV_VRETPIS, MV_VRETCOF, MV_VRETCSL |

### Resumo das integracoes do Financeiro

```
                    Compras (MATA103)              Faturamento (MATA461/468)
                         │                                  │
                    Gera SE2                           Gera SE1
                         │                                  │
                         v                                  v
                ┌──────────────────────────────────────────────┐
                │              FINANCEIRO (SIGAFIN)             │
                │                                              │
                │  SE2 (Pagar) ◄──────────► SE1 (Receber)      │
                │       │                        │             │
                │       └──── SE5 (Mov.Bancaria) ┘             │
                │                    │                         │
                │               SE8 (Saldos)                   │
                └───────────────┬──────────────┬───────────────┘
                                │              │
                           Gera CT2       Gera retencoes
                                │              │
                                v              v
                         Contabilidade      Fiscal
                            (CT2)        (SFT / EFD)
```

---

## Cadastros Auxiliares

| Rotina | Descricao | Tabela |
|--------|-----------|--------|
| FINA010 | Naturezas Financeiras | SED |
| FINA020 | Bancos | SA6 |
| FINA030 | Moedas | CTO |
| FINA140 | Ocorrencias CNAB | FI2 |
| CFGX043 | Configurador CNAB a Pagar | SX1/Tabelas CNAB |
| CFGX042 | Configurador CNAB a Receber | SX1/Tabelas CNAB |
| FINA986 | Complemento do Titulo (Pagar/Receber) | FKD |
| FINA250 | Rastreamento de Titulos | SE1/SE2/SE5 |
| FINA210 | Recalculo de Saldos Bancarios | SE8/SE5 |
| FINA380 | Conciliacao Bancaria Manual | SE5/SIG |
| FINA473 | Conciliacao Bancaria Automatica | SE5/SIG |
| FINA710 | Novo Gestor Financeiro | F75/F76/SE1/SE2 |

---

## Parametros Globais do Modulo (MV_*)

| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| MV_1DUP | C | Numero inicial da primeira duplicata |
| MV_ALIQIRF | N | Aliquota padrao de IRRF |
| MV_MASCNAT | C | Mascara do codigo da natureza do titulo financeiro (tipo C, padrao "19") |
| MV_VLRETIR | N | Valor minimo para retencao de IRRF (padrao 10.00) |
| MV_NUMBORP | C | Numeracao sequencial de borderos a pagar |
| MV_NUMBORR | C | Numeracao sequencial de borderos a receber |

> **Nota:** Esta tabela contem apenas parametros confirmados no TDN e nos fontes do Protheus. Existem centenas de outros parametros MV_* utilizados pelo modulo Financeiro (impostos, retencoes, contabilizacao, integracao, etc.) que podem ser consultados diretamente na tabela SX6 do ambiente Protheus.
