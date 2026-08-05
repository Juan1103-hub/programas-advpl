---
name: vortice-workflow
description: Consolidated Vortice workflow - skill routing, compile, encoding fix, gotchas
---

# Vortice Workflow

Use when starting a new task, before coding, or when unsure about the workflow.

## Session Init

1. `.opencode/memory.md` → canonical skill → routing table
2. Identify the task and load corresponding skill via routing table
3. NEVER respond without loading the relevant skill first

## Quick Reference

| Task | Action |
|------|--------|
| **Compile** | Skill `advpl-tlpp-compile` — server `PROTHEUS_CLOUD_HOMOL` |
| **Encoding fix** | Skill `utf8-to-cp1252-conversion` — ONCE after FINAL edit only |
| **Code review** | Load `advpl-code-review` + `code-review` |
| **SQL review** | Load `embedded-sql` + `sql-safe` |
| **Debug error** | Load `advpl-error-memory` → `advpl-debugging` |
| **Lookup func/SX** | Load `protheus-reference` + `data-dictionary-lookup` |
| **Patterns** | `.opencode/skills/advpl-code-generation/patterns-*.md` (ExecAuto, MVC, TReport, PE, REST) |

## File Naming

| Prefix | Type |
|--------|------|
| `Z*.PRW` | Custom functions |
| `MT*.PRW` | Points of Entry |
| `MTA*.PRW` | Approval PEs |
| `CAD*.PRW` | Telas Cadastro |
| `*.tlpp` | Classes TLPP |

**Glob on Windows**: `**/*.prw` misses `.PRW`. Use `**/*.[pP][rR][wW]`.

## Mandatory Rules

1. `Eof()/Bof()` validation before reading
2. Ask before `RecLock`/`MsExecAuto`/`DbDelete`
3. Confirm before SX changes (impacts all branches)
4. Never commit without explicit request
5. Always respond in Portuguese (PT-BR)
6. Never invent native functions — consult TDN or skill
7. TReport in Build mode only, never Plan
8. Run Quality Checklist (`advpl-quality-checklist` skill) before concluding
9. Encoding conversion ONCE per file (last edit only)
10. Not a git repo — use file reads and Grep

## SA2 Inscricao Estadual

O nome do campo varia por ambiente:
- `A2_INSCR` — Inscricao Estadual (antigo, mais comum)
- `A2_INSEST` — Inscricao Estadual (novo, pode nao existir)
- `A2_INSCRM` — Inscricao Municipal

**Sempre validar com `FieldPos()` antes de usar.**

## FWMBrowse Gotchas

- `SetFilterDefault` + query alias = browse vazio → filtros na SQL
- `SetSeek(.T.)` + query alias = lupa nao aparece → botao Pesquisar
- `oBrw:Refresh(.T.)` reseta cursor → usar `oBrw:Refresh()` sem parametro
- `SetSort` nao existe no build 7.00.240223P

## PEs Module Rules

| PE | Regra |
|----|-------|
| MATA110 | `MT110CON` em A110GRAVA/A110ALTERA |
| MATA020 | `MT20FOPOS` after save; `M020EXC` always `.T.` |
| MATA103 | `MTA103OK` oficial; `MT103NBL` bloqueia se `.T.` |
| MATA094 | `MTALCFIM` em CADA nivel; guard `C7_CONAPRO == 'L'` |

## CFOPs Remessa Terceiros (ZCONSRE5)

`'5949','6949','5901','6901','5909','6909','5915','6915'`
