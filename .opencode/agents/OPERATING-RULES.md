# OPERATING-RULES.md — Regras Operacionais Unificadas

Model-agnostic rules for all agents in this workspace. Inspired by
freebuff-proxy's disciplined approach: rules embedded in the agent, not
in the model. Every model (mimo, nemotron, big-pickle, etc.) follows
the same discipline.

## 1. Identity

- Workspace: Vortice Consultoria Mineral — Protheus 12, build 7.00.240223P, SQL Server.
- Module: Suprimentos/Compras (SC7 tomadas centrais).
- Language: AdvPL (.prw) and TLPP (.tlpp). Compiler: RDMake via TOTVS Language Server.
- Server: `CINVJ6_DEV` (`vortice192877.protheus.cloudtotvs.com.br:10771`).
- Encoding: CP-1252 (never UTF-8 for .prw/.tlpp).

## 2. Safety Rails (MODO_SEGURO)

Default ON. Equivalent to freebuff's `SAFE_MODE=true`. Every agent must
enforce these unless the user explicitly overrides:

| Rail | Rule | Violation |
|------|------|-----------|
| **DB Safety** | `GetArea()`/`RestArea()` around every alias access | CRITICAL |
| **xFilial** | `xFilial('ALIAS')` in every filial filter | CRITICAL |
| **RecLock** | Only on Z* tables; core tables use `MsExecAuto` | CRITICAL |
| **SQL Injection** | `FWExecStatement`/`BeginSQL` with `%table:%`, `%notDel%`, `%xfilial:%`, `%exp:` — never string concat with user input | CRITICAL |
| **No IIF** | Use `If/Else/EndIf` (SonarQube CA4000) | WARNING |
| **No UI in Tx** | No `MsgAlert`, `MsgYesNo`, `Aviso`, `Help` inside transactions | CRITICAL |
| **No Function** | Use `User Function` or `Static Function` — never bare `Function` | CRITICAL |
| **Encoding** | Generated .prw/.tlpp → convert UTF-8→CP-1252 before compile | CRITICAL |
| **Destroy** | Use class's own `Destroy()`, never `FwFetchObj()`/`FreeObj()` | WARNING |
| **No ConOut** | Use `FWLogMsg()` (SonarQube CA1004) | WARNING |

## 3. Workflow (never commit unless asked)

Follows freebuff's disciplined workflow, adapted for Protheus:

```
1. Understand    → Read code, load skills, consult Obsidian vault
2. Plan          → Present approach (if non-trivial), get approval
3. Implement     → Write code following safety rails
4. Verify        → Compile, lint, quality checklist
5. Report        → Show results, wait for user to ask for commit
```

### Hard Rules

- **NEVER stage/commit unless asked.** User must explicitly request commit.
- **NEVER commit secrets** (tokens, passwords, keys, MV_* values with credentials).
- **Compile before declaring done.** Run `advpl-tlpp-compile` skill.
- **Quality gate before concluding.** Run `advpl-quality-checklist` skill.
- **One change at a time.** Don't mix unrelated changes in one commit.
- **Conventional Commits** when committing: `feat|fix|chore|docs|refactor(scope): subject`.

### Test Flake Policy (from freebuff)

> Single FAIL with greens before/after → note-and-move-on after 2 reruns;
> reproduce on pristine `main` before blaming the branch.

Equivalent: if a compilation fails once but succeeds before/after, check
for AppServer connectivity or encoding issues before assuming code is broken.

## 4. Skill Loading (auto-load)

Every agent MUST load relevant skills BEFORE responding. Model-agnostic:
the rules are in the skill files, not dependent on which LLM runs them.

| Context | Skills to Load |
|---------|---------------|
| **Always at start** | `advpl-protheus` (canonical patterns) |
| Generate code/function/screen/MVC | `advpl-code-generation` |
| Create Entry Point | `entry-point-designer` |
| REST API | `fwrest-client-generator` |
| Review code | `advpl-code-review` + `code-review` |
| Debug error | `advpl-debugging` + `advpl-error-memory` |
| SQL/query | `embedded-sql` + `query-builder` + `sql-code-review` |
| Query table/field/SX | `data-dictionary-lookup` + `tabelas-protheus` |
| Refactor | `advpl-refactoring` + `refactor` |
| SX Dictionary | `sx-configuration` |
| Document | `documentation-patterns` + `documentation-writer` |
| Migrate .PRW → .tlpp | `advpl-to-tlpp-migration` |
| Encoding | `utf8-to-cp1252-conversion` |
| Quality gate | `advpl-quality-checklist` (before concluding) |
| Changelog | `changelog-patterns` |

## 5. Code Conventions (enforced)

### Naming
- Hungarian notation mandatory: `c`=char, `n`=num, `d`=date, `l`=logical, `a`=array, `o`=object, `b`=codeblock, `x`=variant.
- Files: module prefix (4 letters) + number (3 digits) — e.g., `MATA010`, `MT110TOK`.
- Fields: table prefix + `_` + name — e.g., `A1_COD`, `C7_QUANT`.

### Structure
- `User Function` for entry points (no `U_` prefix in name).
- `Static Function` for internal helpers.
- Locals/Private at top of function, before executable code.
- `#Include "TOTVS.CH"` for new code; legacy `Protheus.ch` stays.
- `#Include "TopConn.ch"` when using SQL.

### SQL
- Always `D_E_L_E_T_ = ' '` (soft-delete).
- Always `xx_filial = xFilial('XXX')` for filial filter.
- `FWExecStatement` or `BeginSQL`/`EndSQL` with macros.
- `%nolock%` for read-only queries.
- `RetSqlName()` for physical table name.
- Never `SELECT *` in production code.

### Documentation
- `/*/{Protheus.doc}` block in every function.
- `@type`, `@author`, `@since`, `@param`, `@return`.

## 6. Budgets

| Limit | Value | Source |
|-------|-------|--------|
| maxTurns (orchestrator) | 30 | agent definition |
| maxTurns (subagent) | 18 | agent definition |
| Autonomy steps | ≤10 before reporting | freebuff pattern |
| Request limits | 30/min, 1500/day | upstream Protheus |

## 7. Knob Chain (config precedence)

Like freebuff's `dotenv → static → live → SSE hash → store refresh`:

```
User instructions > AGENTS.md > CONFIG/AGENTS.md > skills > Obsidian vault > TDN
```

When in conflict: **user instructions win**. Always.

## 8. Fallback Chain

```
1. Codebase (existing code and conventions)
2. Skill files (skills/**/SKILL.md and references)
3. AGENTS.md / CONFIG/AGENTS.md
4. Obsidian vault (if accessible)
5. TDN official (tdn.totvs.com) + reliable web sources
6. Ask user — never invent/guess
```

## 9. Forbidden

- `StaticCall()` in new code
- `PARAMBOX` (restricted API)
- `IIF` (SonarQube CA4000)
- `ConOut()`/`OutErr()`/`?` (use `FWLogMsg()`)
- `Function` (use `User Function` or `Static Function`)
- `CRIATRAB`/`MSCREATE`/`DBCREATE` (use `FWTemporaryTable`)
- `GetMV()`/`SuperGetMV()`/`ExistBlock()`/`Type()`/`Pergunte()` inside loops
- REST client via `HTTPCGet`/`HTTPCPost` (use `FWRest`)
- Variable name `cFilial` (reserved — use `cFilAux` or `xFilial()`)
- `FwFetchObj()`/`FreeObj()`/`FwFreeArray()` when class has `Destroy()`
- UTF-8 encoding in .prw/.tlpp (must be CP-1252)
