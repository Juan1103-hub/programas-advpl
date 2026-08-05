# Skill: Tabelas Protheus — SIGAEST

> Estrutura das tabelas padrão e customizadas do módulo SIGAEST (Gestão de Estoques).
> Use esta skill para consultar campos, índices e relações antes de codar.

---
## SB1 — Produtos

| Campo | Tipo | Descrição |
|-------|------|-----------|
| B1_COD | C(6) | Código do produto |
| B1_DESC | C(40) | Descrição |
| B1_UM | C(2) | Unidade de medida |
| B1_TIPO | C(2) | Tipo (PA=Prod Acabado, MP=Matéria-Prima, etc.) |
| B1_LOCPAD | C(6) | Localização padrão |
| B1_GRUPO | C(6) | Grupo |
| B1_MSBLQL | C(1) | Bloqueio (1=Bloqueado) |
| B1_ESTSEG | N(12,2) | Estoque de segurança |

**Índice**: B1_COD

## SB2 — Saldos em Estoque

| Campo | Tipo | Descrição |
|-------|------|-----------|
| B2_COD | C(6) | Código do produto |
| B2_LOCAL | C(6) | Armazém |
| B2_QATU | N(12,2) | Quantidade atual |
| B2_VATU1 | N(14,2) | Valor atual total |
| B2_CM1 | N(14,6) | Custo médio ponderado |
| B2_CM2 | N(14,6) | Último custo |

**Índice**: B2_FILIAL+B2_COD+B2_LOCAL

## SB8 — Lotes e Validade

| Campo | Tipo | Descrição |
|-------|------|-----------|
| B8_COD | C(6) | Código do produto |
| B8_LOCAL | C(6) | Armazém |
| B8_LOTECTL | C(20) | Nº do lote |
| B8_DTVALID | D | Data de validade |
| B8_QATU | N(12,2) | Quantidade atual |
| B8_DTFABRI | D | Data de fabricação |

## SB9 — Saldos Históricos

| Campo | Tipo | Descrição |
|-------|------|-----------|
| B9_COD | C(6) | Código do produto |
| B9_LOCAL | C(6) | Armazém |
| B9_DATA | C(8) | Data (YYYYMMDD) |
| B9_QINI | N(12,2) | Quantidade inicial |
| B9_VINI1 | N(14,2) | Valor inicial |

## SD1 — Documentos de Entrada

| Campo | Tipo | Descrição |
|-------|------|-----------|
| D1_DOC | C(9) | Nº documento |
| D1_SERIE | C(3) | Série |
| D1_COD | C(6) | Código produto |
| D1_QUANT | N(12,2) | Quantidade |
| D1_TOTAL | N(14,2) | Valor total |
| D1_VUNIT | N(14,6) | Valor unitário |
| D1_CUSTO | N(14,6) | Custo contábil |

## SD3 — Movimentos de Estoque

| Campo | Tipo | Descrição |
|-------|------|-----------|
| D3_COD | C(6) | Código produto |
| D3_LOCAL | C(6) | Armazém |
| D3_TM | C(3) | Tipo movimento |
| D3_QUANT | N(12,2) | Quantidade |
| D3_CUSTO1 | N(14,2) | Valor total do movimento |
| D3_ORIGEM | C(1) | Origem |
| D3_DTDIGIT | D | Data do movimento |

**Obs**: TM <= 499 = entrada; TM > 499 = saída. Custo unitário = D3_CUSTO1 / D3_QUANT.

## SF4 — Tipos de Entrada/Saída (TES)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| F4_CODIGO | C(3) | Código TES |
| F4_ESTOQUE | C(1) | Movimenta estoque (S/N) |
| F4_DUPLIC | C(1) | Gera duplicata |
| F4_FISCAL | C(1) | Gera fiscal |

## SA2 — Fornecedores

| Campo | Tipo | Descrição |
|-------|------|-----------|
| A2_COD | C(6) | Código do fornecedor |
| A2_NOME | C(40) | Razão social |
| A2_NREDUZ | C(20) | Nome fantasia |
| A2_CGC | C(18) | CNPJ/CPF |
| A2_TEL | C(15) | Telefone |
| A2_EMAIL | C(60) | E-mail |
| A2_INSEST | C(18) | Inscrição Estadual |
| A2_INSCRM | C(18) | Inscrição Municipal |
| A2_CONTATO | C(40) | Contato |
| A2_SIMPNAC | C(2) | Simples Nacional |
| A2_ZZ4ID | C(6) | ID Solic. Cadastral (custom) |

**Índice 1**: A2_FILIAL+A2_COD
**Índice 2**: A2_FILIAL+A2_CGC

## SC1 — Solicitações de Compra

| Campo | Tipo | Descrição |
|-------|------|-----------|
| C1_NUM | C(6) | Nº SC |
| C1_ITEM | C(2) | Item |
| C1_COD | C(6) | Código produto |
| C1_DESCRI | C(40) | Descrição |
| C1_QUANT | N(12,2) | Quantidade |
| C1_DATPRF | D | Data de necessidade |
| C1_EMISSAO | D | Data de emissão |
| C1_CC | C(13) | Centro de custo |
| C1_EC05DB | C(6) | Código EC05 (custom) |

**Índice 1**: C1_FILIAL+C1_NUM+C1_ITEM

## SC7 — Pedidos de Compra

| Campo | Tipo | Descrição |
|-------|------|-----------|
| C7_NUM | C(6) | Nº pedido |
| C7_ITEM | C(2) | Item |
| C7_COD | C(6) | Código produto |
| C7_QUANT | N(12,2) | Quantidade |
| C7_PRECO | N(14,2) | Preço |
| C7_TPFRETE | C(1) | Tipo frete |
| C7_XESTOQ1 | C(1) | Flag estoque (custom) |

**Índice 1**: C7_FILIAL+C7_NUM+C7_ITEM

## SC8 — Cotações

| Campo | Tipo | Descrição |
|-------|------|-----------|
| C8_NUM | C(8) | Nº cotação |
| C8_ITEM | C(2) | Item |
| C8_PRODUTO | C(6) | Código produto |
| C8_EC05DB | C(6) | Código EC05 (custom) |
| C8_ZUPRC | N(14,2) | Preço (custom) |

---
## ZZA — Amostragem Mensal de Estoque (Custom)

| Campo | Tipo SQL | Tam | Descrição |
|-------|----------|-----|-----------|
| ZZA_FILIAL | VARCHAR | 4 | Filial |
| ZZA_DATA | VARCHAR | 8 | Data da amostragem |
| ZZA_PROD | VARCHAR | 15 | Código do produto |
| ZZA_DESCRI | VARCHAR | 200 | Descrição do produto |
| ZZA_LOCAL | VARCHAR | 2 | Armazém |
| ZZA_SLDSYS | FLOAT | - | Saldo do sistema |
| ZZA_QTDCNT | FLOAT | - | Quantidade contada |
| ZZA_DIFER | FLOAT | - | Diferença (contado - sistema) |
| ZZA_VLRUNI | FLOAT | - | Valor unitário |
| ZZA_VLRTOT | FLOAT | - | Valor total (adic. posterior) |
| ZZA_OBS | VARCHAR(MAX) | - | Observação |
| ZZA_MOTIVO | VARCHAR | 500 | Motivo da divergência |
| ZZA_STATUS | VARCHAR | 20 | Status (PENDENTE / ESTOQUE CORRETO / FURO DE ESTOQUE / AJUSTADO) |
| ZZA_INDSIT | VARCHAR | 1 | Indicador situação (C=Correto, P=Pendente, A=Ajustado) |
| ZZA_DTAJUS | VARCHAR | 8 | Data do ajuste |
| ZZA_USER | VARCHAR | 25 | Usuário |
| ZZA_HORA | VARCHAR | 8 | Hora |

**Nome físico**: ZZA + cEmpAnt + "3" (ex: ZZA010003)
**Programa**: `ZMM01.PRW`
**Índice 1**: ZZA_FILIAL + ZZA_PROD + ZZA_LOCAL + ZZA_DATA
**Índice 2**: ZZA_FILIAL + ZZA_DATA

## SZ3 / ZZ3 — Solic. Cadastral de Produtos (Custom)

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| Z3_FILIAL | C | 2 | Filial |
| Z3_ID | C | 6 | ID da solicitação |
| Z3_DESCRI | C | 120 | Descrição do produto |
| Z3_PN | C | 150 | Part number |
| Z3_LINK | C | 254 | Link de referência |
| Z3_UM | C | 2 | Unidade de medida |
| Z3_APLIC | C | 100 | Aplicação |
| Z3_MOTIVO | C | 100 | Motivo de urgência |
| Z3_PRAZO | C | 1 | Urgente (S/N) |
| Z3_STATUS | C | 1 | Status (0=Pendente, 1=Cadastrado, 2=Rejeitado) |
| Z3_USR | C | 15 | Usuário solicitante |
| Z3_ZDTSOL | D | 8 | Data da solicitação |
| Z3_DTREJ | D | 8 | Data de rejeição |

**Programa**: `CADSZ3.PRW`
**Índice 1**: Z3_FILIAL + Z3_ID
**Regras**: Só altera/exclui Pendentes; Se urgente, motivo obrigatório (>10 chars).

## SZ4 / ZZ4 — Solic. Cadastral de Fornecedores (Custom)

| Campo | Tipo | Tam | Descrição | Grupo |
|-------|------|-----|-----------|-------|
| ZZ4_FILIAL | C | 2 | Filial | 01 |
| ZZ4_ID | C | 6 | ID da solicitação (seq) | 01 |
| ZZ4_RAZAO | C | 40 | Razão social | 01 |
| ZZ4_CNPJ | C | 18 | CNPJ | 01 |
| ZZ4_NUMERO | C | 15 | Telefone contato | 01 |
| ZZ4_EMAIL | C | 60 | E-mail | 01 |
| ZZ4_INSEST | C | 18 | Inscrição Estadual | 01 |
| ZZ4_INSMUN | C | 18 | Inscrição Municipal | 01 |
| ZZ4_CONTAT | C | 40 | Contato | 01 |
| ZZ4_SIMPLE | C | 1 | Simples Nacional (S/N) | 01 |
| ZZ4_STATUS | C | 1 | Status (0=Pendente, 1=Cadastrado, 2=Rejeitado) | 02 |
| ZZ4_USR | C | 15 | Usuário solicitante | 02 |
| ZZ4_ZDTSOL | D | 8 | Data da solicitação | 02 |
| ZZ4_DTREJ | D | 8 | Data do último status | 02 |

**Programa**: `CADFORN.PRW` | **Lookup**: SXB configurado (`ZCONSZZ4.PRW`)
**Índice 1**: ZZ4_FILIAL + ZZ4_ID
**Índice 2**: ZZ4_FILIAL + ZZ4_CNPJ
**Índice 3**: ZZ4_FILIAL + ZZ4_STATUS
**Integração**: Sincroniza com SA2 via PEs MATA020 (MT020INC, MT20FOPOS, M020EXC)
