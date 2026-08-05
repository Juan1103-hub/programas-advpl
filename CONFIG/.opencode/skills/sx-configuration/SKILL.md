---
name: sx-configuration
description: Use when generating SX dictionary configuration scripts for TOTVS Protheus - SX3 fields, SIX indexes, SX1 questions, SX5 generic tables, SX7 triggers
---

# SX Configuration

## Overview

Templates and validation rules for generating Protheus data dictionary configuration scripts. Covers SX3 (fields), SIX (indexes), SX1 (report questions), SX5 (generic tables), and SX7 (triggers).

## When to Use

- Creating new custom fields for a table
- Defining indexes for custom tables
- Setting up report parameter questions
- Creating generic lookup tables
- Configuring field triggers

## SX3 — Field Definition

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| X3_ARQUIVO | Table alias | ZA1 |
| X3_ORDEM | Field order (2 digits) | 01 |
| X3_CAMPO | Field name (ALIAS_FIELD) | ZA1_CODIGO |
| X3_TIPO | Type: C, N, D, L, M | C |
| X3_TAMANHO | Size | 6 |
| X3_DECIMAL | Decimal places (for N) | 0 |
| X3_TITULO | Title pt-BR (max 15 chars) | Codigo |
| X3_TITSPA | Title es (max 15 chars) | Codigo |
| X3_TITENG | Title en (max 15 chars) | Code |
| X3_DESCRIC | Description pt-BR | Codigo da OS |
| X3_DESCSPA | Description es | Codigo de la OS |
| X3_DESCENG | Description en | OS Code |
| X3_PICTURE | Display format | @! |
| X3_VALID | Validation expression | NaoVazio() |
| X3_USADO | In use (Sim/Nao) | Sim |
| X3_OBRIGAT | Required (Sim/Nao) | Sim |
| X3_BROWSE | Show in browse (Sim/Nao) | Sim |
| X3_VISUAL | Edit mode: Alterar/Visualizar | Alterar |
| X3_CONTEXT | Context: Real/Virtual | Real |
| X3_CBOX | Combo options (val1=desc1;val2=desc2) | |
| X3_RELACAO | Initial value expression | |
| X3_F3 | F3 lookup alias | SA1 |
| X3_VLDUSER | User validation expression | |
| X3_TRIGGER | Has trigger (Sim/Nao) | Nao |

### Validation Rules

| Rule | Condition | Action |
|------|-----------|--------|
| Field name format | Must be ALIAS_XXXXXX (6 chars after underscore) | Error if invalid |
| Type C size | 1-254 characters | Warn if > 100 |
| Type N size | Max 18 digits including decimal | Error if > 18 |
| Type D size | Always 8 | Auto-set to 8 |
| Type L size | Always 1 | Auto-set to 1 |
| Type M size | Always 10 | Auto-set to 10 |
| Picture for C | @! (uppercase), @R (mask), or custom | Suggest @! for codes |
| Picture for N | @E 999,999,999.99 (adjust to size) | Auto-generate from size/decimal |
| Picture for D | (none needed) | Leave empty |
| Required + Validation | If X3_OBRIGAT = Sim, add NaoVazio() to X3_VALID | Auto-add |
| F3 lookup | If X3_F3 set, validation should include ExistCpo | Suggest adding |
| CBOX + Validation | If X3_CBOX set, add Pertence() to X3_VALID | Auto-add |
| Auto-increment | If primary key, set X3_RELACAO = GetSXENum() | Suggest for first field |
| Trigger | If F3 set and related display field needed, generate SX7 | Auto-generate |

### Common Validations

| Validation | When to use | Syntax |
|------------|------------|--------|
| NaoVazio() | Required field | NaoVazio() |
| ExistCpo(alias, M->field) | Foreign key lookup | ExistCpo("SA1", M->ZA1_CLIENT) |
| ExistChav(alias, M->field, order) | Unique key check | ExistChav("ZA1", M->ZA1_CODIGO, 1) |
| Pertence(values) | Combo validation | Pertence("1234") |
| Positivo() | Must be > 0 | Positivo() |
| Vazio() .Or. ExistCpo() | Optional foreign key | Vazio() .Or. ExistCpo("SA1", M->ZA1_CLIENT) |

### Common Pictures

| Type | Picture | Example display |
|------|---------|----------------|
| Code (uppercase) | @! | ABC123 |
| CNPJ | @R 99.999.999/9999-99 | 12.345.678/0001-90 |
| CPF | @R 999.999.999-99 | 123.456.789-00 |
| Phone | @R (99) 99999-9999 | (11) 98765-4321 |
| Currency | @E 999,999,999.99 | 1,234.56 |
| Percentage | @E 999.99 | 15.50 |

## SIX — Index Definition

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| INDICE | Table alias | ZA1 |
| ORDEM | Index order number | 1 |
| CHAVE | Key expression (concatenated fields) | ZA1_FILIAL + ZA1_CODIGO |
| DESCRICAO | Description pt-BR | Codigo |
| DESCSPA | Description es | Codigo |
| DESCENG | Description en | Code |
| NICKNAME | Index nickname | ZA1_CODIGO |
| SHOWPESQ | Show in search (Sim/Nao) | Sim |

### Rules
- Index 1 is ALWAYS the primary key (FILIAL + unique field)
- FILIAL must be the first component of every index
- Nickname must be unique within the table
- Order must be sequential starting from 1

## SX1 — Report Questions

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| X1_GRUPO | Group name (matches report alias) | ZA1 |
| X1_ORDEM | Question order (2 digits) | 01 |
| X1_PERGUNT | Question text pt-BR | Data Abertura De |
| X1_PERGSPA | Question text es | Fecha Apertura De |
| X1_PERGENG | Question text en | Open Date From |
| X1_TIPO | Type: C, N, D | D |
| X1_TAMANHO | Field size | 8 |
| X1_GSC | Get/Select/Combo: G, S, C | G |
| X1_VALID | Validation expression | |
| X1_DEF01 | Default value | Space(8) |
| X1_F3 | F3 lookup (for type C) | SA1 |
| X1_HELP | Help text | Data inicial |

### Rules
- Questions come in pairs for range filters (De/Ate)
- Type D always has size 8
- Default for "De" date: Space(8) or first day of month
- Default for "Ate" date: dDataBase or last day of month
- Default for "De" char: Space(size)
- Default for "Ate" char: Replicate("Z", size)
- If combo (C), X1_DEF01 contains the default option value
- X1_GSC: G=Get (text input), S=Select (not common), C=Combo

## SX5 — Generic Tables

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| X5_FILIAL | Branch (usually empty for global) | |
| X5_TABELA | Table code (2 chars) | ZZ |
| X5_CHAVE | Key value (2 chars) | 01 |
| X5_DESCRI | Description pt-BR | Preventiva |
| X5_DESCSPA | Description es | Preventiva |
| X5_DESCENG | Description en | Preventive |

### Rules
- Table code: 2 uppercase characters (use Z prefix for custom: ZA, ZB, ZZ, etc.)
- Key: 2 characters, sequential (01, 02, 03...)
- To use in code: GetSX5("ZZ", "01") or X5DESCRI("ZZ", "01")

## SX7 — Triggers

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| X7_CAMPO | Source field | ZA1_CLIENT |
| X7_SEQUENC | Sequence (3 digits) | 001 |
| X7_REGRA | Expression to evaluate | Posicione("SA1", 1, xFilial("SA1") + M->ZA1_CLIENT, "A1_NOME") |
| X7_CDOMIN | Domain field (target to fill) | ZA1_NMCLI |
| X7_TIPO | Type: P=Primary | P |
| X7_SEEK | Seek expression | xFilial("SA1") + M->ZA1_CLIENT |
| X7_ALIAS | Lookup alias | SA1 |
| X7_ORDEM | Index order for seek | 1 |
| X7_CHTEFIL | Check branch (Sim/Nao) | Sim |

### Rules
- Triggers fire when source field changes
- Posicione() is the standard function for lookups
- Always include xFilial() in the seek expression
- Sequence allows multiple triggers on the same field

## Output Format

Scripts are formatted as key-value blocks, one field definition per block, separated by dashes. This format is human-readable and can be used as reference for manual configuration in the Configurador or for import scripts.
