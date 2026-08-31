---
name: tabelas-protheus
description: 'Skill Vortice custom tabelas-protheus - SC7/CINVJ6_DEV 7.00.240223P'
---

# Skill: Tabelas Protheus â€” SIGAEST

> Estrutura das tabelas padrÃ£o e customizadas do mÃ³dulo SIGAEST (GestÃ£o de Estoques).
> Use esta skill para consultar campos, Ã­ndices e relaÃ§Ãµes antes de codar.

---
## SB1 â€” Produtos

| Campo | Tipo | DescriÃ§Ã£o |
|-------|------|-----------|
| B1_COD | C(6) | CÃ³digo do produto |
| B1_DESC | C(40) | DescriÃ§Ã£o |
| B1_UM | C(2) | Unidade de medida |
| B1_TIPO | C(2) | Tipo (PA=Prod Acabado, MP=MatÃ©ria-Prima, etc.) |
| B1_LOCPAD | C(6) | LocalizaÃ§Ã£o padrÃ£o |
| B1_GRUPO | C(6) | Grupo |
| B1_MSBLQL | C(1) | Bloqueio (1=Bloqueado) |
| B1_ESTSEG | N(12,2) | Estoque de seguranÃ§a |

**Ãndice**: B1_COD

## SB2 â€” Saldos em Estoque

| Campo | Tipo | DescriÃ§Ã£o |
|-------|------|-----------|
| B2_COD | C(6) | CÃ³digo do produto |
| B2_LOCAL | C(6) | ArmazÃ©m |
| B2_QATU | N(12,2) | Quantidade atual |
| B2_VATU1 | N(14,2) | Valor atual total |
| B2_CM1 | N(14,6) | Custo mÃ©dio ponderado |
| B2_CM2 | N(14,6) | Ãšltimo custo |

**Ãndice**: B2_FILIAL+B2_COD+B2_LOCAL

## SB8 â€” Lotes e Validade

| Campo | Tipo | DescriÃ§Ã£o |
|-------|------|-----------|
| B8_COD | C(6) | CÃ³digo do produto |
| B8_LOCAL | C(6) | ArmazÃ©m |
| B8_LOTECTL | C(20) | NÂº do lote |
| B8_DTVALID | D | Data de validade |
| B8_QATU | N(12,2) | Quantidade atual |
| B8_DTFABRI | D | Data de fabricaÃ§Ã£o |

## SB9 â€” Saldos HistÃ³ricos

| Campo | Tipo | DescriÃ§Ã£o |
|-------|------|-----------|
| B9_COD | C(6) | CÃ³digo do produto |
| B9_LOCAL | C(6) | ArmazÃ©m |
| B9_DATA | C(8) | Data (YYYYMMDD) |
| B9_QINI | N(12,2) | Quantidade inicial |
| B9_VINI1 | N(14,2) | Valor inicial |

## SD1 â€” Documentos de Entrada

| Campo | Tipo | DescriÃ§Ã£o |
|-------|------|-----------|
| D1_DOC | C(9) | NÂº documento |
| D1_SERIE | C(3) | SÃ©rie |
| D1_COD | C(6) | CÃ³digo produto |
| D1_QUANT | N(12,2) | Quantidade |
| D1_TOTAL | N(14,2) | Valor total |
| D1_VUNIT | N(14,6) | Valor unitÃ¡rio |
| D1_CUSTO | N(14,6) | Custo contÃ¡bil |

## SD3 â€” Movimentos de Estoque

| Campo | Tipo | DescriÃ§Ã£o |
|-------|------|-----------|
| D3_COD | C(6) | CÃ³digo produto |
| D3_LOCAL | C(6) | ArmazÃ©m |
| D3_TM | C(3) | Tipo movimento |
| D3_QUANT | N(12,2) | Quantidade |
| D3_CUSTO1 | N(14,2) | Valor total do movimento |
| D3_ORIGEM | C(1) | Origem |
| D3_DTDIGIT | D | Data do movimento |

**Obs**: TM <= 499 = entrada; TM > 499 = saÃ­da. Custo unitÃ¡rio = D3_CUSTO1 / D3_QUANT.

## SF4 â€” Tipos de Entrada/SaÃ­da (TES)

| Campo | Tipo | DescriÃ§Ã£o |
|-------|------|-----------|
| F4_CODIGO | C(3) | CÃ³digo TES |
| F4_ESTOQUE | C(1) | Movimenta estoque (S/N) |
| F4_DUPLIC | C(1) | Gera duplicata |
| F4_FISCAL | C(1) | Gera fiscal |

## SA2 â€” Fornecedores

| Campo | Tipo | DescriÃ§Ã£o |
|-------|------|-----------|
| A2_COD | C(6) | CÃ³digo do fornecedor |
| A2_NOME | C(40) | RazÃ£o social |
| A2_NREDUZ | C(20) | Nome fantasia |
| A2_CGC | C(18) | CNPJ/CPF |
| A2_TEL | C(15) | Telefone |
| A2_EMAIL | C(60) | E-mail |
| A2_INSEST | C(18) | InscriÃ§Ã£o Estadual |
| A2_INSCRM | C(18) | InscriÃ§Ã£o Municipal |
| A2_CONTATO | C(40) | Contato |
| A2_SIMPNAC | C(2) | Simples Nacional |
| A2_ZZ4ID | C(6) | ID Solic. Cadastral (custom) |

**Ãndice 1**: A2_FILIAL+A2_COD
**Ãndice 2**: A2_FILIAL+A2_CGC

## SC1 â€” SolicitaÃ§Ãµes de Compra

| Campo | Tipo | DescriÃ§Ã£o |
|-------|------|-----------|
| C1_NUM | C(6) | NÂº SC |
| C1_ITEM | C(2) | Item |
| C1_COD | C(6) | CÃ³digo produto |
| C1_DESCRI | C(40) | DescriÃ§Ã£o |
| C1_QUANT | N(12,2) | Quantidade |
| C1_DATPRF | D | Data de necessidade |
| C1_EMISSAO | D | Data de emissÃ£o |
| C1_CC | C(13) | Centro de custo |
| C1_EC05DB | C(6) | CÃ³digo EC05 (custom) |

**Ãndice 1**: C1_FILIAL+C1_NUM+C1_ITEM

## SC7 â€” Pedidos de Compra

| Campo | Tipo | DescriÃ§Ã£o |
|-------|------|-----------|
| C7_NUM | C(6) | NÂº pedido |
| C7_ITEM | C(2) | Item |
| C7_COD | C(6) | CÃ³digo produto |
| C7_QUANT | N(12,2) | Quantidade |
| C7_PRECO | N(14,2) | PreÃ§o |
| C7_TPFRETE | C(1) | Tipo frete |
| C7_XESTOQ1 | C(1) | Flag estoque (custom) |

**Ãndice 1**: C7_FILIAL+C7_NUM+C7_ITEM

## SC8 â€” CotaÃ§Ãµes

| Campo | Tipo | DescriÃ§Ã£o |
|-------|------|-----------|
| C8_NUM | C(8) | NÂº cotaÃ§Ã£o |
| C8_ITEM | C(2) | Item |
| C8_PRODUTO | C(6) | CÃ³digo produto |
| C8_EC05DB | C(6) | CÃ³digo EC05 (custom) |
| C8_ZUPRC | N(14,2) | PreÃ§o (custom) |

---
## ZZA â€” Amostragem Mensal de Estoque (Custom)

| Campo | Tipo SQL | Tam | DescriÃ§Ã£o |
|-------|----------|-----|-----------|
| ZZA_FILIAL | VARCHAR | 4 | Filial |
| ZZA_DATA | VARCHAR | 8 | Data da amostragem |
| ZZA_PROD | VARCHAR | 15 | CÃ³digo do produto |
| ZZA_DESCRI | VARCHAR | 200 | DescriÃ§Ã£o do produto |
| ZZA_LOCAL | VARCHAR | 2 | ArmazÃ©m |
| ZZA_SLDSYS | FLOAT | - | Saldo do sistema |
| ZZA_QTDCNT | FLOAT | - | Quantidade contada |
| ZZA_DIFER | FLOAT | - | DiferenÃ§a (contado - sistema) |
| ZZA_VLRUNI | FLOAT | - | Valor unitÃ¡rio |
| ZZA_VLRTOT | FLOAT | - | Valor total (adic. posterior) |
| ZZA_OBS | VARCHAR(MAX) | - | ObservaÃ§Ã£o |
| ZZA_MOTIVO | VARCHAR | 500 | Motivo da divergÃªncia |
| ZZA_STATUS | VARCHAR | 20 | Status (PENDENTE / ESTOQUE CORRETO / FURO DE ESTOQUE / AJUSTADO) |
| ZZA_INDSIT | VARCHAR | 1 | Indicador situaÃ§Ã£o (C=Correto, P=Pendente, A=Ajustado) |
| ZZA_DTAJUS | VARCHAR | 8 | Data do ajuste |
| ZZA_USER | VARCHAR | 25 | UsuÃ¡rio |
| ZZA_HORA | VARCHAR | 8 | Hora |

**Nome fÃ­sico**: ZZA + cEmpAnt + "3" (ex: ZZA010003)
**Programa**: `ZMM01.PRW`
**Ãndice 1**: ZZA_FILIAL + ZZA_PROD + ZZA_LOCAL + ZZA_DATA
**Ãndice 2**: ZZA_FILIAL + ZZA_DATA

## SZ3 / ZZ3 â€” Solic. Cadastral de Produtos (Custom)

| Campo | Tipo | Tam | DescriÃ§Ã£o |
|-------|------|-----|-----------|
| Z3_FILIAL | C | 2 | Filial |
| Z3_ID | C | 6 | ID da solicitaÃ§Ã£o |
| Z3_DESCRI | C | 120 | DescriÃ§Ã£o do produto |
| Z3_PN | C | 150 | Part number |
| Z3_LINK | C | 254 | Link de referÃªncia |
| Z3_UM | C | 2 | Unidade de medida |
| Z3_APLIC | C | 100 | AplicaÃ§Ã£o |
| Z3_MOTIVO | C | 100 | Motivo de urgÃªncia |
| Z3_PRAZO | C | 1 | Urgente (S/N) |
| Z3_STATUS | C | 1 | Status (0=Pendente, 1=Cadastrado, 2=Rejeitado) |
| Z3_USR | C | 15 | UsuÃ¡rio solicitante |
| Z3_ZDTSOL | D | 8 | Data da solicitaÃ§Ã£o |
| Z3_DTREJ | D | 8 | Data de rejeiÃ§Ã£o |

**Programa**: `CADSZ3.PRW`
**Ãndice 1**: Z3_FILIAL + Z3_ID
**Regras**: SÃ³ altera/exclui Pendentes; Se urgente, motivo obrigatÃ³rio (>10 chars).

## SZ4 / ZZ4 â€” Solic. Cadastral de Fornecedores (Custom)

| Campo | Tipo | Tam | DescriÃ§Ã£o | Grupo |
|-------|------|-----|-----------|-------|
| ZZ4_FILIAL | C | 2 | Filial | 01 |
| ZZ4_ID | C | 6 | ID da solicitaÃ§Ã£o (seq) | 01 |
| ZZ4_RAZAO | C | 40 | RazÃ£o social | 01 |
| ZZ4_CNPJ | C | 18 | CNPJ | 01 |
| ZZ4_NUMERO | C | 15 | Telefone contato | 01 |
| ZZ4_EMAIL | C | 60 | E-mail | 01 |
| ZZ4_INSEST | C | 18 | InscriÃ§Ã£o Estadual | 01 |
| ZZ4_INSMUN | C | 18 | InscriÃ§Ã£o Municipal | 01 |
| ZZ4_CONTAT | C | 40 | Contato | 01 |
| ZZ4_SIMPLE | C | 1 | Simples Nacional (S/N) | 01 |
| ZZ4_STATUS | C | 1 | Status (0=Pendente, 1=Cadastrado, 2=Rejeitado) | 02 |
| ZZ4_USR | C | 15 | UsuÃ¡rio solicitante | 02 |
| ZZ4_ZDTSOL | D | 8 | Data da solicitaÃ§Ã£o | 02 |
| ZZ4_DTREJ | D | 8 | Data do Ãºltimo status | 02 |

**Programa**: `CADFORN.PRW` | **Lookup**: SXB configurado (`ZCONSZZ4.PRW`)
**Ãndice 1**: ZZ4_FILIAL + ZZ4_ID
**Ãndice 2**: ZZ4_FILIAL + ZZ4_CNPJ
**Ãndice 3**: ZZ4_FILIAL + ZZ4_STATUS
**IntegraÃ§Ã£o**: Sincroniza com SA2 via PEs MATA020 (MT020INC, MT20FOPOS, M020EXC)

