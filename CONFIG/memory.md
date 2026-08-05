# Memory — Workspace-wide TOTVS Protheus SIGAEST

> Contexto permanente do workspace PAI (nivel .vscode). Compartilhado entre
> todos os projetos (programas_vortice, Suprimentos, PATCH, etc).
> **Ultima atualizacao**: 30/06/2026

## Identidade

- **Workspace-wide**: TOTVS Protheus 12 | SQL Server | AdvPL/TLPP
- **Modulo principal**: SIGAEST (Estoque) + SIGACOM (Compras)
- **Path**: `C:\totvs\advpl\.vscode\`
- **Repo git**: NAO

## Estrutura Hierarquica .opencode/

```
C:\totvs\advpl\.vscode\
├── .opencode/                            [PAI - workspace-wide]
│   ├── opencode.json                     model, MCP advpl-sensei, default_agent=advpl-dev
│   ├── AGENTS.md                         5 super-regras (ver secao "Regras Globais")
│   ├── memory.md                         ESTE ARQUIVO
│   ├── openspec-config.yaml              config workflow OpenSpec
│   ├── agents/                           4 subagentes TOTVS:
│   │   advpl-dev, advpl-review-checklist, html-frontend-dev, html-frontend-verify
│   ├── commands_opsx-*.md                5 commands OpenSpec (soltos)
│   ├── openspec-*.md                     5 skills OpenSpec (soltos, mesmo conteudo)
│   ├── references_*.md                   2 references (sonarqube-rules, advpl-tlpp-skills)
│   ├── package.json                      runtime OpenCode (@kilocode/plugin, @opencode-ai/plugin)
│   └── node_modules/                     runtime OpenCode
│
├── .claude/skills/                       skills Claude (openspec-* workflow)
│
└── programas_vortice/                    [FILHO - projeto Vortice]
    ├── opencode.json                     instructions + compaction + mcp (FILHO)
    ├── AGENTS.md                         13 regras Vortice
    ├── 49 .PRW + 2 .tlpp                 fontes de producao
    └── .opencode/
        ├── memory.md                     contexto do projeto Vortice
        ├── skills/                       45 skills projeto-specificas
        └── agents/                       10 subagentes projeto
```

## Descoberta Hierarquica OpenCode

- CWD tipico = `programas_vortice/` (projeto atual)
- OpenCode descobre configs subindo diretorios:
  - `programas_vortice/opencode.json` (FILHO) → instructions, compaction, mcp
  - `C:\totvs\advpl\.vscode\.opencode\opencode.json` (PAI) → model, mcp, permissions
- Skills do FILHO carregadas via `.opencode/skills/<name>/SKILL.md` (45 pastas)
- Skills do PAI: nenhuma propria (são 5 commands + 5 OpenSpec + 2 references, via `.md` soltos)
- Agents do PAI carregados via `.opencode/agents/*.md` (4 agents)
- Skills OpenSpec carregadas via `.claude/skills/openspec-*/SKILL.md`
- Skills globais do usuario carregadas via `~/.config/opencode/skills/` (15 superpowers)

## Subagentes TOTVS no PAI (4)

Via `..\.opencode\agents\`:

- **advpl-dev**: desenvolvimento/correcao rotinas AdvPL/TLPP SIGAEST
- **advpl-review-checklist**: revisao com checklist completo
- **html-frontend-dev**: telas HTML/CSS/JS
- **html-frontend-verify**: validacao frontend

> **Nota**: o FILHO `programas_vortice\.opencode\agents\` tem 10 subagentes adicionais
> (code-generator, code-reviewer, debugger, doc-generator, docs-reference, etc).
> Ver `programas_vortice\.opencode\memory.md` para lista completa.

## Skills TOTVS no PAI

O PAI **nao tem skills TOTVS engpro** (correto em 24/06/2026). Skills TOTVS
estão concentradas no FILHO (`programas_vortice\.opencode\skills\`, 45 skills).

PAI possui apenas:
- 5 commands OpenSpec (`commands_opsx-*.md`)
- 5 skills OpenSpec (`openspec-*.md` — workflow OpenSpec)
- 2 references (`references_*.md` — sonarqube-rules, advpl-tlpp-skills)

## Skills OpenSpec Workflow (em .claude/skills/)

Disponiveis via `C:\totvs\advpl\.vscode\.claude\skills\openspec-*/SKILL.md`:
- `openspec-apply-change` — Implementar tarefas de uma change
- `openspec-archive-change` — Arquivar change concluida
- `openspec-explore` — Modo exploracao (thinking partner)
- `openspec-propose` — Propor nova change com artefatos
- `openspec-sync-specs` — Sincronizar delta specs para main specs

## Documentos de Referencia Externos

- `../CLAUDE.md` — diretrizes raiz
- `../CLAUDE-SOLUTION-PATTERNS.md` — solucoes validadas (F3/SXB/PEs/filtros)
- `../CLAUDE-SKILLS-REF.md` — referencia de skills TOTVS engpro
- `.claude/skills/openspec-*/` — workflow OpenSpec (5 skills)
- `programas_vortice\.opencode\memory.md` — contexto do projeto Vortice

## Regras Globais (mandatorio)

> **As 5 super-regras workspace-wide estao em `..\AGENTS.md` (PAI)**.
> Esta secao NAO duplica — apenas referencia para evitar drift.

Hierarquia de regras (ver `..\AGENTS.md` secao "Super-regras"):
1. Sempre responder em portugues
2. Sempre perguntar antes de codar
3. Nunca presumir nomes de tabelas/campos/indices
4. Preservar `GetArea()`/`RestArea()`
5. Usar `xFilial("ALIAS")`

Regras especificas de PROJETO estao em cada `AGENTS.md` de FILHO
(ex: `programas_vortice\AGENTS.md` tem 13 regras Vortice).

## Historico de Workarounds

Ver `..\AGENTS.md` secao 6 (renomeada em 24/06/2026 de "8" para "6") — historico
de sessao com:
- 6.1 FWLookup:BuildBrowse:SetAlias — Build 7.00.240223P
- 6.2 U_ZZ4SEL / U_OPENZZ4 — FWBrowse incompativel com X3_WHEN no MVC
- 6.3 SXB + FWLookup (F3/lupa) — retorno a consulta padrao

## Projetos no Workspace

| Projeto | Path | Modulo | Especificidade |
|---------|------|--------|---------------|
| programas_vortice | `programas_vortice/` | Suprimentos/Compras | Customizacoes Vortice (49 .PRW + 2 .TLPP) |
| Suprimentos | `Suprimentos/` | Suprimentos | Outras customizacoes |
| PATCH | `PATCH/` | Varios | Patches e correcoes pontuais |

## Changelog

### 30/06/2026
- **Cleanup PAI `.opencode/`**: removidos `.vscode/` (leak cache), `node_modules/` (25 pacotes), `package.json`, `package-lock.json`
- **Provider Ollama removido** do global `opencode.jsonc` (URL ngrok efemera)
- **agente README built-in**: `agent.disable` em `opencode.json` nao funciona (issues #15222, #21364)
- PAI final: 4 agents, AGENTS.md, memory.md, opencode.json, openspec-config.yaml, 2 references, tui.json

### 24/06/2026
- Removido: duplicacao de "Regras Globais" (agora sao 5 super-regras em `..\AGENTS.md`)
- Corrigido: contagem de subagentes (4 reais, nao 13)
- Corrigido: lista de "28 skills TOTVS engpro no PAI" (sao 0, estao no FILHO)
- Corrigido: lista de skills no FILHO (45, nao 16)
- Corrigido: estrutura hierarquica reflete filesystem real
- Corrigido: "AGENTS.md secao 8" → "secao 6" (renumerado em 24/06/2026)
- Atualizado: "ultima atualizacao 18/06/2026" → "24/06/2026"
