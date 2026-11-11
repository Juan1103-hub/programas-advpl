# Workflow — SDD, Compilação, Hooks, Unlazy e Cadeia de Documentação

> **Consulte este arquivo quando** for iniciar um desenvolvimento programado (SDD), compilar fontes, trabalhar com hooks/automação, ativar o disciplina unlazy, depurar, ou precisar saber a precedência de documentação/fallback. Não é contexto fixo — leia sob demanda.

## Workflow Padrão — Spec-Driven Development (SDD)

> **Skill**: `skills/advpl-tlpp/advpl-tlpp-sdd` — metodologia orientada a especificação para ADVPL/TLPP + Protheus. Use como padrão para todo desenvolvimento programado.

**Fluxo com 4 fases adaptativas (auto-sizing por complexidade):**

```
SPECIFY → DESIGN → TASKS → EXECUTE
 required  optional* optional* required   *auto-skip quando escopo não justifica
```

| Escopo | Quando | Specify | Design | Tasks | Execute |
|--------|--------|---------|--------|-------|---------|
| **Small** | ≤3 arquivos, frase única | Quick mode | - | - | - |
| **Medium** | feature clara <10 tasks | Spec breve | skip inline | skip implícito | Implement + verify |
| **Large** | multi-componente | Spec + IDs | Architecture | Full + deps | Por task |
| **Complex** | ambiguidade/novo domínio | Spec + discuss | Research + arch | Breakdown paralelo | + UAT interativo |

**Estrutura**: `.specs/project/{PROJECT.md,ROADMAP.md,STATE.md}` + `.specs/codebase/{7 docs brownfield}` + `.specs/features/[feature]/{spec.md,context.md,design.md,tasks.md}` + `.specs/quick/NNN-slug/` (pastas criadas pela skill no 1º uso).

**Gatilhos** (use quando falar): `initialize project`, `map codebase`, `specify feature`, `discuss feature`, `design`, `tasks`, `implement`, `validate`, `quick fix`, `pause work`, `resume work` — ver `skills/advpl-tlpp/advpl-tlpp-sdd/SKILL.md`.

> Regra: **Specify e Execute sempre obrigatórios**; Design/Tasks com skip automático; toda geração `.prw/.tlpp` no Execute exige `utf8-to-cp1252-conversion` + pergunta de `advpl-tlpp-compile` antes do Gate.

## Build and Compilation

- **Compilador**: RDMake (TOTVS) via extensão **TOTVS Language Server** (tds-vscode) no VS Code; fluxo guiado na skill `advpl-tlpp-compile` (não existe skill `advpl-tds-ls`).
- **Servidor**: AppServer TOTVS `CINVJ6_DEV` (`vortice192877.protheus.cloudtotvs.com.br:10771`, build `7.00.240223P`), config em `CONFIG/servers.json`. **Atenção**: o arquivo contém token de sessão do AppServer — nunca imprimir o conteúdo em docs, logs ou commits.
- **Includes do compilador**: `INCLUDES/totvs/` do projeto (apontado em `CONFIG/servers.json`) e `C:\Users\Vortice 0097\Desktop\BKP_JUAN\totvs\includes` (linter TDS em `.vscode/settings.json`). O caminho antigo `C:\totvs\includes` não existe mais na máquina.
- **Workflow pós-geração obrigatório**:
  1. Gerar código (cria UTF-8)
  2. Converter **UTF-8 → CP-1252** (skill `utf8-to-cp1252-conversion`) — o RDMake ignora/corrompe UTF-8
  3. Compilar contra o AppServer (skill `advpl-tlpp-compile`)
  4. Code review (`advpl-code-review` / `code-review`)
- Não há Makefile/Gradle nem arquivos `.PRJ` versionados no repo — a compilação é sempre via TDS contra o AppServer; artefato `.O` fica no RPO do servidor.

## Automação do Workspace (hooks, comandos e memória)

- **Hooks** (`.opencode/settings.json`): ao salvar `.prw/.prg/.prx/.tlpp` → PreToolUse roda `advpl-code-review --level high`; PostToolUse roda **conversão → compilação** (ordem canônica **converter → compilar → review** — compilar UTF-8 corrompe acentos no RPO; ver `.opencode/memory/bugs/zmma01-detalhes-janela-mes.md`). **Não confiar que os hooks rodam**: os comandos `utf8-to-cp1252-conversion`/`advpl-code-review` não estão no PATH desta máquina e o hook de compilação usa `C:\totvs\advpls.exe` (pasta `C:\totvs` não existe mais) — executar conversão e compilação manualmente pelas skills `utf8-to-cp1252-conversion` e `advpl-tlpp-compile`.
- **Slash commands** (`.opencode/command/`): `/specify`, `/design`, `/tasks`, `/execute`, `/map`, `/quick-fix`, `/compile`, `/review`.
- **Memória de projeto** (`.opencode/memory/`): índice em `MEMORY.md` — bugs resolvidos, padrões, tabelas, regras, MVC, SX3, PEs e dados do projeto (AppServer, build, módulo). Consultar e atualizar junto com o Obsidian (fallback abaixo).

## Unlazy — Disciplina de Conclusão (anti-laziness)

Arquivos da skill `unlazy` em `skills/unlazy/`. Uso: tarefas grandes, multi-etapa, ou quando o trabalho retorna incompleto.

**Atenção**: não há comando `/unlazy` em `.opencode/command/` nem `unlazy` em `skills.paths` — a skill **não carrega automaticamente**. Ativar lendo `skills/unlazy/SKILL.md` e executando os scripts de `skills/unlazy/scripts/` manualmente (gatilhos textuais "tree N", "gates", "não pare até estar pronto" valem como lembrete de comportamento, não como comando).

**Como funciona:**
1. **Escrever gates antes de começar** — criar `GATES.md` com resultados observáveis e comandos de verificação.
2. **Executar checks aprovados** — rodar `node skills/unlazy/scripts/gate-check.mjs --approve GATES.md`.
3. **Reverificar trabalho retornado** — usar `--reverify` para confirmar evidências.
4. **Relatar apenas com evidência** — não declarar pronto sem todos os gates verificados.

**Exemplo de gate:**
```markdown
- [ ] G1: Correção do DECRESCENTE aplicada em ambos os loops
CHECK: grep -c "nBaseCalc * 0.6" FONTES/ZMMA01.PRW
EXPECT: 2
EVIDENCE: pending
```

**Modos:**
- **Solo:** Um `GATES.md` para tarefa focada.
- **Orquestrado:** `PLAN.md` + gates por leaf (para builds grandes).
- **Paralelo:** Dispatch com waves + reconciliação de ownership.

**Regra de ouro:** Nunca declarar pronto sem evidência verificada. Se um gate é impossível, marcar `ABANDON:` com motivo.

## Skills disponíveis (catálogo)

- Catálogo completo: `docs/CLAUDE-SKILLS-REF.md`, `CONFIG/references_advpl-tlpp-skills-reference.md` e `skills/skills-registry.json`.
- **Restrição**: usar **somente** `skills/advpl-tlpp`, `skills/superpowers`, `skills/vortice` (registradas em `skills.paths`). `skills/unlazy` não está registrada — ler `SKILL.md` diretamente.
- Categorias principais:
  | Categoria | Skills |
  |---|---|
  | SDD | `advpl-tlpp-sdd` |
  | Migração | `advpl-to-tlpp-migration` |
  | Qualidade | `code-review`, `advpl-code-review`, `sql-code-review`, `sql-optimization`, `refactor` |
  | Testes | `tir-test-generator` |
  | Compilação | `advpl-tlpp-compile` |
  | Code-gen | `mvc-generator`, `tlpp-rest-endpoint-generator`, `fwrest-client-generator`, `query-builder` |
  | Documentação/Plano | `documentation-writer`, `create-implementation-plan`, `data-dictionary-lookup`, `entry-point-designer`, `context-map` |
  | Encoding | `utf8-to-cp1252-conversion` |
  | Superpowers | `brainstorming`, `systematic-debugging`, `dispatching-parallel-agents`, `writing-skills`… |
  | Vortice | `advpl-protheus`, `protheus-rules`, `tabelas-protheus`, `pontos-entrada`, `sql-safe`, `sx-configuration`, `advpl-debugging`, `advpl-refactoring`, `probat-testing`, `verification-evidence`, `vortice-workflow`… |
  | Disciplina | `unlazy` (anti-laziness, completion discipline com gates de aceitação) |

## Tests

- **TIR** (e2e Webapp/SmartClient): Python `unittest.TestCase` com `setUpClass()`, `test_CTNNN()`, `tearDownClass()`. Scripts deste repo ficam em `CONFIG/tir/`. Gerar usando `tir-test-generator`.
  - **Pré-requisitos hoje**: pacote `tir` NÃO está instalado (`pip install tir`) e `CONFIG/tir/config.json` ainda contém placeholders `{server}:{port}`/`{username}` — preencher antes de rodar.
  - Teste único: `python -m unittest <Classe>.<test_...>` a partir de `CONFIG/tir/` (ex.: `python -m unittest ZANALPRCTESTCASE.ZANALPRC.test_ZANALPRC_CT001`).
- **Testes unitários**: ProBat para TLPP (`probat-testing`).
- Verificação de dados para código: validar via **APSDU** antes de hardcoding (ver `CONFIG/AGENTS.md`) — nunca assumir campo/valor inexistente.

## Debugging — fluxo obrigatório

1. **Reproduzir e isolar**: identificar rotina, PE no fluxo e mensagem exata do AppServer (console/log do `CINVJ6_DEV`).
2. **Consultar memória antes de hipóteses**: Obsidian `06 - Bugs Resolvidos.md` (ou fallback `.opencode/memory/MEMORY.md`) — o bug pode já estar documentado.
3. **Validar dados via APSDU**: antes de assumir campo/valor/estrutura, gerar query SQL e pedir execução ao usuário (nunca inventar estado da base).
4. **Citar código como `arquivo:linha`** ao explicar causa raiz — econômico e clicável.
5. **Log de PE**: `FWLogMsg` (nunca `ConOut`); em legados existentes, log com prefixo `[PE_NAME] mensagem`.
6. **Depois de resolver**: registrar o caso no Obsidian `06 - Bugs Resolvidos.md` (formato Problema → Causa → Fix → Como aplicar) e no `.opencode/memory/` conforme fluxo do workspace.

## Hierarchy of Documentation (precedência)

Em caso de conflito entre arquivos de documentação, vale nesta ordem:

1. **Instruções do usuário** (sempre acima de qualquer doc)
2. **Obsidian** (`06 - Bugs Resolvidos.md` — solução já documentada tem precedência)
3. `CONFIG/AGENTS.md` (SUPER-regras SIGAEST/workspace — tabelas core, acesso a dados)
4. `AGENTS.md` da raiz (convenções de código, padrões, checklist)
5. `CLAUDE.md` / `docs/` (referências e kits)
6. Skills (`skills/advpl-tlpp`, `skills/superpowers`, `skills/vortice`)
7. TDN oficial (tdn.totvs.com) + fontes web confiáveis

> **Fonte de verdade única de código**: o próprio repositório. Se doc conflita com fonte real, o **código vence** — registrar a divergência como achado, não ignorar.

### Base de Conhecimento — Obsidian (consultar ANTES de codar ou debugar)

Vault com memória técnica do projeto — bugs resolvidos, padrões, tabelas, PEs:
`C:\Users\Vortice 0097\Desktop\BKP_JUAN\Memoria\Memoria\ADVPL-Protheus\`

| Situação | Nota |
|----------|------|
| Bug / erro desconhecido | `06 - Bugs Resolvidos.md` |
| Padrão de código | `07 - Padrões de Código ADVPL.md` |
| Tabelas e filtros canônicos | `08 - Tabelas-Chave e Filtros.md` |
| Regras e boas práticas | `09 - Regras e Boas Práticas.md` |
| MVC / ModelDef / ViewDef | `02 - MVC no Protheus.md` |
| SX3 / dicionário | `03 - SX3 e Dicionário de Dados.md` |
| ZZ4 / ZD1 / SA2 custom | `04 - Tabelas Customizadas.md` |
| Pontos de Entrada | `05 - Pontos de Entrada (PE).md` |

Ao resolver bug novo → registrar em `06 - Bugs Resolvidos.md`.

### Fallback quando o vault Obsidian estiver indisponível

O vault externo pode ficar inacessível no runtime (máquina sem o BKP, caminho movido, permissão). Nesse caso, **consultar/registrar** pela rota alternativa — a precedência acima permanece intacta; apenas a fonte 2 (Obsidian) é substituída:

| Situação | Fallback de consulta | Fallback de registro |
|----------|----------------------|----------------------|
| Bug / erro desconhecido | `.opencode/memory/MEMORY.md` + `bugs/` (versionado no repo) | Adicionar o caso a `.opencode/memory/bugs/` + index `MEMORY.md` |
| Padrão de código | `.opencode/memory/padroes/` | — |
| Contexto/regras do projeto | `.opencode/memory/` (tabelas, regras, projeto) | Atualizar o arquivo correspondente |
| Busca por tabela/filtro/PE | TDN oficial (tdn.totvs.com) + fontes web confiáveis | Registrar achado em `.opencode/memory/` |

- Ao resolver bug novo com o vault indisponível: registrar **imediatamente** no fallback e sincronizar para `06 - Bugs Resolvidos.md` (Obsidian) quando o caminho voltar.
- Se o vault estiver disponível, **prevalece o vault**.

## Fallback Escalation Chain

1. Codebase — código e convenções no projeto (ex.: `FONTES/`)
   ↓ não achou
2. Skill references (`skills/advpl-tlpp/**`, `skills/superpowers/**`, `skills/vortice/**`, `skills/unlazy/**` e `CONFIG/references_*.md`)
   ↓
3. `AGENTS.md`/`CLAUDE.md`/`CONFIG/AGENTS.md`
   ↓
4. TDN oficial (tdn.totvs.com) + fontes web confiáveis
   ↓
5. Perguntar ao usuário — nunca inventar
