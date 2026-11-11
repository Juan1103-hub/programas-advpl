# Catálogo de Skills — AdvPL/TLPP (Protheus)

Índice canônico das skills deste workspace, no mesmo formato do
`skills/advpl-tlpp/README.md` do repositório oficial
`totvs/engpro-advpl-tlpp-skills`.

**Onde fica o quê**

| Arquivo | Papel |
| --- | --- |
| `AGENTS.md` → "Roteamento obrigatório de skills" | regra geral + tabela de rota espelhada do §7 deste arquivo (em caso de divergência, o §7 vence) |
| **este arquivo** | catálogo completo + tabela "qual skill usar?" (§7), consultado sob demanda |
| `skills/skills-registry.json` | catálogo legível por máquina (nome, categoria, caminho, arquivos) |
| `docs/agents-totvs-oficial.md` | espelho do `instructions/AGENTS.md` oficial da TOTVS |

**Como usar**

1. Antes de gerar código, localize a skill nesta tabela e leia o `SKILL.md` da pasta indicada.
2. Use apenas skills que existem em `skills/` — nunca invente nome de skill.
3. Se a tarefa cruzar categorias (ex.: criar MVC + exportar Excel), leia as duas skills.

Total: **20 oficiais TOTVS** + **30 específicas Vortice** + **14 de método** + **1 de disciplina** = **65**.

---

## Sumário

- [1. Skills oficiais TOTVS — `skills/advpl-tlpp/`](#1-skills-oficiais-totvs--skillsadvpl-tlpp)
  - [Geração de Código](#geração-de-código)
  - [Migração e Modernização](#migração-e-modernização)
  - [Qualidade de Código e Revisão](#qualidade-de-código-e-revisão)
  - [Testes](#testes)
  - [Build e Compilação](#build-e-compilação)
  - [Documentação e Planejamento](#documentação-e-planejamento)
- [2. Skills específicas Vortice — `skills/vortice/`](#2-skills-específicas-vortice--skillsvortice)
- [3. Skills de método — `skills/superpowers/`](#3-skills-de-método--skillssuperpowers)
- [4. Disciplina de execução — `skills/unlazy/`](#4-disciplina-de-execução--skillsunlazy)
- [5. Referências compartilhadas](#5-referências-compartilhadas)
- [6. Fluxo padrão de uma tarefa](#6-fluxo-padrão-de-uma-tarefa)
- [7. Referência rápida: qual skill usar?](#7-referência-rápida-qual-skill-usar)
- [8. Manutenção deste catálogo](#8-manutenção-deste-catálogo)

---

## 1. Skills oficiais TOTVS — `skills/advpl-tlpp/`

Espelho das 20 skills de `totvs/engpro-advpl-tlpp-skills`.

### Geração de Código

Skills que geram estruturas prontas para produção seguindo os padrões do framework TOTVS.

| Skill | Quando usar |
| --- | --- |
| [mvc-generator](advpl-tlpp/mvc-generator/SKILL.md) | Criar tela MVC: `ModelDef`, `ViewDef`, `MenuDef`, `BrowseDef` com `FWFormModel`/`FWFormView`/`FWFormBrowse`, Modelo 1 e Modelo 3, validações, gatilhos e PEs. |
| [tlpp-rest-endpoint-generator](advpl-tlpp/tlpp-rest-endpoint-generator/SKILL.md) | **Expor** API REST em TLPP com `@Get`/`@Post`/`@Put`/`@Patch`/`@Delete` e `oRest`, padrão TTALK (paginação, modelo de erro, Swagger). |
| [fwrest-client-generator](advpl-tlpp/fwrest-client-generator/SKILL.md) | **Consumir** API externa com `FWRest`: GET/POST/PUT/DELETE, headers, query/path, body JSON, autenticação (No Auth, Basic, Bearer/JWT, OAuth 2.0), timeout, SSL, status code, try/catch. |
| [fwmsexcelxlsx-generator](advpl-tlpp/fwmsexcelxlsx-generator/SKILL.md) | Exportar dados para `.xlsx` com `FwMsExcelXlsx` em `User Function`: abas, tabelas, alinhamento/formato/totalizador, gravação em arquivo ou banco, SmartClient/WebApp/job. `FWMsExcelEx` só se pedido explicitamente. |
| [entry-point-designer](advpl-tlpp/entry-point-designer/SKILL.md) | Criar ou documentar Ponto de Entrada: assinatura `User Function`, layout `PARAMIXB`, retorno e programação defensiva. Gera TLPP por padrão; AdvPL só se pedido. |
| [query-builder](advpl-tlpp/query-builder/SKILL.md) | Escrever SQL seguro e otimizado para tabelas Protheus: filtros obrigatórios (`D_E_L_E_T_`, filial), índices SIX, anti-injection, versões embarcada (`FWExecStatement`) e workarea (`DBSelectArea`/`DBSeek`). |

### Migração e Modernização

| Skill | Quando usar |
| --- | --- |
| [advpl-to-tlpp-migration](advpl-tlpp/advpl-to-tlpp-migration/SKILL.md) | Migrar `.prw` para `.tlpp`: extensão, `tlpp-core.th`, namespaces, tipagem, Try-Catch, REST, identificadores longos, JSON inline, parâmetros nomeados, modificadores de acesso, remoção de `StaticCall`. |

### Qualidade de Código e Revisão

| Skill | Quando usar |
| --- | --- |
| [code-review](advpl-tlpp/code-review/SKILL.md) | Revisão completa AdvPL/TLPP em 8 categorias (segurança, performance, legado, metadados, ProtheusDOC, clean code, TLPP, compilação), com achados por severidade e ID SonarQube. |
| [sql-code-review](advpl-tlpp/sql-code-review/SKILL.md) | Revisão focada em SQL: injection, controle de acesso, estrutura da consulta, índices, anti-patterns; PostgreSQL, SQL Server e Oracle. |
| [refactor](advpl-tlpp/refactor/SKILL.md) | Refatoração cirúrgica sem mudar comportamento; 15 code smells com padrões seguros de extração. |
| [refactor-method-complexity-reduce](advpl-tlpp/refactor-method-complexity-reduce/SKILL.md) | Reduzir complexidade cognitiva de um método via extração de auxiliares, virando orquestrador de alto nível. |
| [sql-optimization](advpl-tlpp/sql-optimization/SKILL.md) | Tuning de consulta, estratégia de índices, paginação, lote, plano de execução, específico por banco. |
| [utf8-to-cp1252-conversion](advpl-tlpp/utf8-to-cp1252-conversion/SKILL.md) | Converter fontes para CP-1252 antes de compilar (obrigatório: o RPO não aceita UTF-8). |

### Testes

| Skill | Quando usar |
| --- | --- |
| [tir-test-generator](advpl-tlpp/tir-test-generator/SKILL.md) | Gerar teste E2E TIR em Python (`tir.Webapp`) para SmartClient/Webapp: CRUD, MVC, grid, parâmetros de relatório, validação de campo, caixa de mensagem. |

### Build e Compilação

| Skill | Quando usar |
| --- | --- |
| [advpl-tlpp-compile](advpl-tlpp/advpl-tlpp-compile/SKILL.md) | Compilar fontes e enviar ao RPO via `tds-vscode` + `servers.json`: valida extensão e servidor, conduz conexão/autenticação (senha digitada pelo usuário) e reporta o resultado. |

### Documentação e Planejamento

| Skill | Quando usar |
| --- | --- |
| [documentation-writer](advpl-tlpp/documentation-writer/SKILL.md) | Gerar bloco `/*/{Protheus.doc}` para funções, classes e métodos com todas as tags suportadas. |
| [data-dictionary-lookup](advpl-tlpp/data-dictionary-lookup/SKILL.md) | Consultar o dicionário: SX2, SX3, SIX, SX6, SX5, SX7, SX1, SX9, SXB, SXG/SXA. |
| [context-map](advpl-tlpp/context-map/SKILL.md) | Mapear arquivos afetados, dependências, testes e risco antes de implementar. |
| [create-implementation-plan](advpl-tlpp/create-implementation-plan/SKILL.md) | Criar plano faseado e legível por máquina em `/plan/`, com tarefas atômicas e critérios de validação. |
| [advpl-tlpp-sdd](advpl-tlpp/advpl-tlpp-sdd/SKILL.md) | Conduzir feature/projeto com Spec-Driven Development em 4 fases adaptativas (Specify → Design → Tasks → Execute), com rastreabilidade e memória entre sessões. |

---

## 2. Skills específicas Vortice — `skills/vortice/`

Conhecimento deste cliente (Suprimentos/Compras, SC7, `CINVJ6_DEV` 7.00.240223P).

### Conhecimento do ambiente e da base

| Skill | Quando usar |
| --- | --- |
| [advpl-protheus](vortice/advpl-protheus/SKILL.md) | Skill canônica do workspace: includes, estrutura de funções, padrões de banco e UI, checklist de qualidade, Protheus 12.1.33. |
| [advpl-tlpp-reference-guide](vortice/advpl-tlpp-reference-guide/SKILL.md) | Referência de linguagem, estrutura de projeto, compilação, includes, TIR e convenções. |
| [advpl-empresa](vortice/advpl-empresa/SKILL.md) | Convenções da empresa para o módulo SIGAEST — aplicar antes de implementar. |
| [tabelas-protheus](vortice/tabelas-protheus/SKILL.md) | Estrutura das tabelas padrão e customizadas do SIGAEST: campos, índices e relações antes de codar. |
| [solucoes-consultas](vortice/solucoes-consultas/SKILL.md) | Soluções validadas de F3, Consulta Padrão, `FWLookup` e SXB (caso ZZ4 em `A2_ZSOLID` no MATA020). |
| [pontos-entrada](vortice/pontos-entrada/SKILL.md) | Catálogo dos Pontos de Entrada já implementados — consultar antes de criar customização nova. |
| [protheus-business](vortice/protheus-business/SKILL.md) | Processos de negócio, fluxos de módulo, rotinas e integrações do ERP. |
| [protheus-reference](vortice/protheus-reference/SKILL.md) | Funções nativas, tabelas SX, endpoints REST e parâmetros MV. |
| [sx-configuration](vortice/sx-configuration/SKILL.md) | Gerar scripts de configuração SX3, SIX, SX1, SX5 e SX7. |

### Regras e padrões de código

| Skill | Quando usar |
| --- | --- |
| [protheus-rules](vortice/protheus-rules/SKILL.md) | Regras de implementação segura em Suprimentos: ProtheusDOC, `GetArea`/`RestArea`, `xFilial`. |
| [advpl-quality-checklist](vortice/advpl-quality-checklist/SKILL.md) | Checklist obrigatório antes de concluir tarefa ADVPL: estrutura, escopo, acesso a banco, UI, PEs, pré-compilação. |
| [sql-safe](vortice/sql-safe/SKILL.md) | Padrão de SQL seguro para TopConnect: `GetNextAlias`, `%Table:%`, `%NotDel%`, filtro de filial. |
| [embedded-sql](vortice/embedded-sql/SKILL.md) | `BeginSQL`/`EndSQL`, macros `%table%`, `%notDel%`, `%xfilial%`, `%exp%`; quando usar embarcado em vez de `TCQuery`. |
| [advpl-padrao-fonte](vortice/advpl-padrao-fonte/SKILL.md) | Molde do fonte deste repositório: header Protheus.doc, layout, `GetArea`/`RestArea`, SQL TopConnect, PE, tela, classe TLPP — com script de auditoria (`--estrito` para fonte novo). |
| [frontend-quality](vortice/frontend-quality/SKILL.md) | Checklist de HTML/CSS/JS: responsividade, semântica, acessibilidade, reuso de estilo. |

### Geração, revisão e correção

| Skill | Quando usar |
| --- | --- |
| [advpl-code-generation](vortice/advpl-code-generation/SKILL.md) | Criar funções, classes, MVC, REST, Web Services e PEs. |
| [advpl-code-review](vortice/advpl-code-review/SKILL.md) | Revisar boas práticas, performance, segurança e modernização. |
| [advpl-refactoring](vortice/advpl-refactoring/SKILL.md) | Refatorar: extrair funções, simplificar lógica, remover código morto, renomear. |
| [advpl-debugging](vortice/advpl-debugging/SKILL.md) | Depurar erros, logs Protheus, performance e problemas de compilação/runtime. |
| [advpl-error-memory](vortice/advpl-error-memory/SKILL.md) | Evitar repetir erros conhecidos de escopo, query, `MSExecAuto`, `dbSeek`, arrays e PEs. |
| [advpl-tela-consulta](vortice/advpl-tela-consulta/SKILL.md) | Criar tela virtual de consulta no modelo ZLGCONS (MSDIALOG 650x1300, filtros, LISTBOX). |
| [advpl-msdialog-dimensionamento](vortice/advpl-msdialog-dimensionamento/SKILL.md) | Dimensionar tela `MSDIALOG` Modelo 1: moldura = 2x o bounding box dos controles; auditar com `scripts/calc_frame.py`. Obrigatória antes de tela modal nova ou tela cortada. |
| [advpl-msdialog-ciclo-de-vida](vortice/advpl-msdialog-ciclo-de-vida/SKILL.md) | Evitar `variable is not an object`: capturar valores no `ACTION` antes do `oDlg:End()`; auditar com `scripts/check_pos_activate.py`. |
| [advpl-fwbrowse-fwbldfeature-bug](vortice/advpl-fwbrowse-fwbldfeature-bug/SKILL.md) | Workaround do `invalid macro source (SSYacc0105e)` em `FWBUILDFEATURE` com picture `@!`. |

### Documentação, teste e verificação

| Skill | Quando usar |
| --- | --- |
| [documentation-patterns](vortice/documentation-patterns/SKILL.md) | Documentação técnica: cabeçalho ProtheusDOC, docs de rotina e de API. |
| [code-explanation](vortice/code-explanation/SKILL.md) | Explicar código em linguagem simples para desenvolvedor ou consultor funcional. |
| [changelog-patterns](vortice/changelog-patterns/SKILL.md) | Gerar changelog a partir de diff, comparação de arquivos e release notes. |
| [probat-testing](vortice/probat-testing/SKILL.md) | Gerar testes unitários ProBat para classes e funções TLPP. |
| [verification-evidence](vortice/verification-evidence/SKILL.md) | Verificar com comando executado e saída observável — nunca só por leitura de código. |
| [vortice-workflow](vortice/vortice-workflow/SKILL.md) | Workflow consolidado do cliente: roteamento de skills, compilação, correção de encoding e pegadinhas. |

---

## 3. Skills de método — `skills/superpowers/`

Não são específicas de AdvPL: orientam **como** executar o trabalho.

| Skill | Quando usar |
| --- | --- |
| [brainstorming](superpowers/brainstorming/SKILL.md) | Antes de qualquer trabalho criativo: explorar intenção, requisitos e desenho. |
| [writing-plans](superpowers/writing-plans/SKILL.md) | Transformar spec/requisito em plano antes de tocar no código. |
| [executing-plans](superpowers/executing-plans/SKILL.md) | Executar plano escrito em sessão separada, com checkpoints de revisão. |
| [subagent-driven-development](superpowers/subagent-driven-development/SKILL.md) | Executar plano com tarefas independentes na mesma sessão. |
| [dispatching-parallel-agents](superpowers/dispatching-parallel-agents/SKILL.md) | Duas ou mais tarefas independentes, sem estado compartilhado. |
| [test-driven-development](superpowers/test-driven-development/SKILL.md) | Implementar feature ou correção começando pelo teste. |
| [systematic-debugging](superpowers/systematic-debugging/SKILL.md) | Diante de bug, teste falhando ou comportamento inesperado, antes de propor correção. |
| [requesting-code-review](superpowers/requesting-code-review/SKILL.md) | Ao concluir tarefa ou feature, antes de integrar. |
| [receiving-code-review](superpowers/receiving-code-review/SKILL.md) | Ao receber feedback de review, com rigor técnico em vez de concordância automática. |
| [verification-before-completion](superpowers/verification-before-completion/SKILL.md) | Antes de afirmar que algo está pronto, corrigido ou passando. |
| [finishing-a-development-branch](superpowers/finishing-a-development-branch/SKILL.md) | Ao terminar a implementação: decidir merge, PR ou limpeza. |
| [using-git-worktrees](superpowers/using-git-worktrees/SKILL.md) | Isolar o trabalho em worktree antes de executar planos. |
| [writing-skills](superpowers/writing-skills/SKILL.md) | Criar, editar ou validar skills. |
| [using-superpowers](superpowers/using-superpowers/SKILL.md) | Descobrir e usar skills no início de qualquer conversa. |

---

## 4. Disciplina de execução — `skills/unlazy/`

| Skill | Quando usar |
| --- | --- |
| [unlazy](unlazy/SKILL.md) | Tarefa longa ou multi-etapa, auditoria/build extenso, trabalho que voltou pela metade: escrever gates antes de executar, decompor com Depth Tree e re-verificar evidência antes de reportar. |

---

## 5. Referências compartilhadas

| Referência | Usada por | Conteúdo |
| --- | --- | --- |
| [`advpl-tlpp/references/sonarqube-rules-reference.md`](advpl-tlpp/references/sonarqube-rules-reference.md) | `code-review`, `entry-point-designer` | Regras SonarQube G1–G5 com IDs e severidade. |
| [`advpl-tlpp/references/advpl-tlpp-skills-reference.md`](advpl-tlpp/references/advpl-tlpp-skills-reference.md) | `AGENTS.md`, `CLAUDE.md` | Catálogo oficial em inglês das skills AdvPL/TLPP. |
| `CONFIG/references_sonarqube-rules-reference.md` | uso diário | Cópia de trabalho das regras SonarQube. |
| `CONFIG/references_advpl-tlpp-skills-reference.md` | uso diário | Cópia de trabalho do catálogo oficial. |
| `docs/agents-totvs-oficial.md` | consulta sob demanda | Espelho do `instructions/AGENTS.md` oficial, com caminhos locais. |

---

## 6. Fluxo padrão de uma tarefa

```
1. Planejar      advpl-tlpp-sdd · context-map · create-implementation-plan
2. Gerar         mvc-generator · entry-point-designer · query-builder
                 tlpp-rest-endpoint-generator · fwrest-client-generator · fwmsexcelxlsx-generator
3. Encoding      utf8-to-cp1252-conversion
4. Compilar      advpl-tlpp-compile (LSP + RDMake)
5. Revisar       code-review · sql-code-review · advpl-quality-checklist
6. Verificar     verification-evidence · verification-before-completion
7. Encerrar      gap analysis item a item + relatório do que ficou "não confirmado"
```

---

## 7. Referência rápida: qual skill usar?

| Eu quero... | Skill |
| --- | --- |
| Criar tela CRUD MVC (Modelo 1 / Modelo 3) | `mvc-generator` |
| Seguir o padrão dos fontes deste repositório | `advpl-padrao-fonte` |
| Criar tela virtual de consulta (não MVC) | `advpl-tela-consulta` |
| Dimensionar tela modal `MSDIALOG` / tela abrindo cortada | `advpl-msdialog-dimensionamento` |
| Erro `variable is not an object` logo após `ACTIVATE MSDIALOG` | `advpl-msdialog-ciclo-de-vida` |
| Criar ou customizar Ponto de Entrada | `entry-point-designer` · catálogo em `pontos-entrada` |
| Expor API REST | `tlpp-rest-endpoint-generator` |
| Consumir API REST externa | `fwrest-client-generator` |
| Exportar dados para `.xlsx` | `fwmsexcelxlsx-generator` |
| Escrever SQL embarcado / escolher entre SQL e workarea | `query-builder` · `embedded-sql` |
| Garantir SQL seguro (TopConnect) | `sql-safe` · `query-builder` |
| Otimizar consulta lenta | `sql-optimization` |
| Revisar código | `code-review` · `advpl-code-review` |
| Revisar SQL | `sql-code-review` |
| Validar antes de concluir | `advpl-quality-checklist` · `verification-evidence` |
| Refatorar / reduzir complexidade | `refactor` · `refactor-method-complexity-reduce` · `advpl-refactoring` |
| Migrar `.prw` para `.tlpp` | `advpl-to-tlpp-migration` |
| Converter encoding para CP-1252 | `utf8-to-cp1252-conversion` |
| Compilar e enviar ao RPO | `advpl-tlpp-compile` |
| Criar teste E2E de tela | `tir-test-generator` |
| Criar teste unitário TLPP | `probat-testing` |
| Documentar com ProtheusDOC | `documentation-writer` · `documentation-patterns` |
| Explicar código para o usuário | `code-explanation` |
| Gerar changelog | `changelog-patterns` |
| Consultar dicionário de dados | `data-dictionary-lookup` · `tabelas-protheus` |
| Gerar script de configuração SX | `sx-configuration` |
| Consultar função nativa / parâmetro MV | `protheus-reference` |
| Entender processo de negócio do ERP | `protheus-business` |
| Resolver F3 / Consulta Padrão / FWLookup | `solucoes-consultas` |
| Debugar erro em runtime | `advpl-debugging` · `systematic-debugging` |
| Evitar repetir erro já conhecido | `advpl-error-memory` |
| Erro `SSYacc0105e` em FWMBrowse/MVC | `advpl-fwbrowse-fwbldfeature-bug` |
| Mapear arquivos antes de implementar | `context-map` |
| Planejar implementação | `create-implementation-plan` · `writing-plans` |
| Conduzir feature com SDD | `advpl-tlpp-sdd` |
| Rotina do cliente (fluxo completo) | `vortice-workflow` |

---

## 8. Manutenção deste catálogo

- Ao criar, renomear ou remover uma skill, atualizar **este arquivo** e `skills/skills-registry.json`.
- A descrição deste catálogo deve refletir o `description:` do `SKILL.md` correspondente — não inventar capacidade.
- Antes de publicar, conferir que cada caminho linkado existe.
