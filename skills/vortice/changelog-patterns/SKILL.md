---
name: changelog-patterns
description: Use when generating changelogs from code changes - git diffs, file comparisons, release notes
---

# Changelog Patterns

## Overview

Patterns for generating structured changelogs from ADVPL/TLPP code changes on TOTVS Protheus. Analyzes diffs, identifies change types, and produces formatted release notes.

## When to Use

- Generating changelog for a delivery to the client
- Creating release notes for a patch or update
- Documenting what changed between versions
- Auditing code changes for compliance

## Change Types

| Type | Label | Description |
|------|-------|-------------|
| NEW | [NOVO] | Nova funcionalidade ou rotina |
| FIX | [CORRECAO] | Correcao de bug |
| CHANGE | [ALTERACAO] | Melhoria ou modificacao de comportamento existente |
| REMOVE | [REMOCAO] | Funcionalidade ou codigo removido |
| REFACTOR | [REFATORACAO] | Mudanca estrutural sem alterar comportamento |

## Impact Levels

| Level | Description |
|-------|-------------|
| ALTO | Altera fluxo de negocio, tabelas, ou integracao entre modulos |
| MEDIO | Altera validacoes, calculos, ou comportamento de rotina existente |
| BAIXO | Mudanca cosmetica, refatoracao, ou correcao pontual |

## Changelog Format — Markdown

```markdown
# Changelog — [Nome do Projeto/Pacote]
Data: DD/MM/YYYY
Versao: X.Y.Z

## Resumo
[1-2 frases descrevendo o escopo das mudancas]

## Alteracoes

### [NOVO] Descricao da nova funcionalidade
- **Arquivo:** CadOrdemServico.prw
- **Impacto:** ALTO
- **Detalhes:** Cadastro MVC de Ordens de Servico com tabela customizada ZA1
- **Tabelas afetadas:** ZA1 (nova)

### [CORRECAO] Descricao do bug corrigido
- **Arquivo:** MATA461.prw:145
- **Impacto:** MEDIO
- **Detalhes:** RecLock sem MsUnlock causava lock permanente na SF2
- **Tabelas afetadas:** SF2

### [ALTERACAO] Descricao da melhoria
- **Arquivo:** RelVendas.prw
- **Impacto:** BAIXO
- **Detalhes:** Adicionada coluna de desconto no relatorio
- **Tabelas afetadas:** SC6 (leitura)
```

## Changelog Format — TXT (plain text)

```
CHANGELOG — [Nome do Projeto/Pacote]
Data: DD/MM/YYYY | Versao: X.Y.Z
============================================

RESUMO: [1-2 frases]

[NOVO] Descricao
  Arquivo: CadOrdemServico.prw
  Impacto: ALTO
  Tabelas: ZA1 (nova)

[CORRECAO] Descricao
  Arquivo: MATA461.prw:145
  Impacto: MEDIO
  Tabelas: SF2
```

## Analysis Process

1. Get the list of changed files (git diff, file list, or user input)
2. For each changed file:
   a. Read the current version
   b. If git available, get the diff (git diff <since> -- <file>)
   c. Identify what changed: new functions, modified functions, removed functions
   d. Detect tables affected (DBSelectArea, RecLock, BeginSQL patterns)
   e. Classify the change type (NEW, FIX, CHANGE, REMOVE, REFACTOR)
   f. Assess impact level (ALTO, MEDIO, BAIXO)
3. Group changes by type
4. Generate changelog in the requested format
