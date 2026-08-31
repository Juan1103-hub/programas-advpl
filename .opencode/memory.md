# Memory — Vortice AdvPL/Protheus Workspace

> Contexto permanente do projeto. **Ler no inicio de cada sessao** antes de qualquer tarefa.
> Ultima atualizacao: 15/08/2026

## Base de Conhecimento — Obsidian (consultar sempre)

Vault local com notas organizadas de ADVPL/Protheus e Web:
`C:\Users\Vortice 0097\Desktop\BKP_JUAN\Memoria\Memoria\`

| Situacao | Nota a consultar |
|----------|-----------------|
| Bug estranho / erro desconhecido | `ADVPL-Protheus\06 - Bugs Resolvidos.md` |
| Duvida sobre padrao de codigo | `ADVPL-Protheus\07 - Padroes de Codigo ADVPL.md` |
| Nome de tabela / filtro canonico | `ADVPL-Protheus\08 - Tabelas-Chave e Filtros.md` |
| Regras e boas praticas | `ADVPL-Protheus\09 - Regras e Boas Praticas.md` |
| MVC / ModelDef / ViewDef | `ADVPL-Protheus\02 - MVC no Protheus.md` |
| SX3 / dicionario de dados | `ADVPL-Protheus\03 - SX3 e Dicionario de Dados.md` |
| ZZ4 / ZD1 / SA2 customizada | `ADVPL-Protheus\04 - Tabelas Customizadas.md` |
| Lista de programas do projeto | `ADVPL-Protheus\01 - Programas Customizados.md` |
| Pontos de Entrada (PE) | `ADVPL-Protheus\05 - Pontos de Entrada (PE).md` |

**Instrucao**: Ao iniciar qualquer tarefa de desenvolvimento ou debug, ler a nota relevante acima ANTES de responder.
Para registrar um bug resolvido: gravar em `ADVPL-Protheus\06 - Bugs Resolvidos.md`.

## Regras de Eficiencia (usuario VCM37)

Conclusao rapida, sem rodeios. Obrigatorio:

1. **Validar funcoes/simbolos nativos AdvPL ANTES de gerar codigo** (ex.: `Round(nVal,nDec)` — `nRound` NAO existe; fonte: TDN / protheusadvpl / codebase).
2. **Consultar TDN/Central TOTVS no INICIO** da investigacao (ex.: IMP0058 resolveu base IPI bruto/liquido).
3. **1 pergunta bloqueadora por vez**; confirmar hipotese com sim/nao.
4. **Usuario NAO tem APSDU/AppServer** — ele roda as queries SQL que eu fornecer e devolve resultado. Nunca assumir dado de banco.
5. **Extrair objetivo quantificado no 1o prompt** (ex.: total pedido = 17.040, IPI 6,5% sobre base liquida).
6. **Restricoes de negocio desde o inicio** (ex.: TES intocavel).
7. **Exclusao de fontes orfaos**: avisar o usuario ANTES (nome + motivo) para ele excluir do RPO; so depois apagar o arquivo local. Nunca apagar fonte antes da confirmacao da exclusao do RPO.

## Casos Arquivados (consultar antes de debugar)

### MATA120 IPI bruto/liquido (13/08/2026) — resolvido (grid+gravacao) | pendente impressao

**Objetivo**: total pedido = 17.040 (IPI sobre base liquida, total - desconto). Restricao: TES (F4_TPIPI) intocavel.

**Solucao — 3 camadas**:

1. **Gatilho SX7** (`MT120TFR.PRW` — `U_MT120IPI`): executa em tempo real na digitacao. Calcula base liquida (C7_TOTAL - C7_VLDESC), atualiza aCols E chama `MaFisRef("IT_VALIPI","MT120",...)` / `MaFisRef("IT_BASEIPI","MT120",...)` para atualizar o motor fiscal (rodape "Total do Pedido"). Retorna `"L"` para contra-dominio C7_IPIBRUT. Gatilhos SX7: C7_VLDESC->001, C7_IPI->001, C7_PRODUTO->003.

2. **PE gravacao** (`MTA120G3.PRW`): roda no loop A120GRAVA, sobrescreve o que o framework gravou:
   - `SC7->C7_IPIBRUT := "L"`
   - `SC7->C7_BASEIPI := SC7->C7_TOTAL - SC7->C7_VLDESC`
   - `SC7->C7_VALIPI  := Round(SC7->C7_BASEIPI * SC7->C7_IPI / 100, 2)`

3. **(PENDENTE) Impressao**: o formulario "ORDEM DE COMPRAS" (padrao TOTVS/MISCC) recalcula IPI do zero usando `C7_TOTAL * C7_IPI/100` (bruto), ignorando C7_VALIPI gravado. SC7 esta correto (C7_BASEIPI=16.000, C7_VALIPI=1.040, C7_IPIBRUT=L) mas o print mostra 17.072,50. Aguarda identificar rotina de impressao.

**Licoes**: (a) `nRound` NAO existe em AdvPL, usar `Round(nVal, nDec)`; (b) `MaFisRef("IT_VALIPI","MT120",...)` atualiza motor fiscal — necessario para rodape em tempo real; (c) Gatilho SX7 roda DEPOIS do framework calcular — por isso consegue corrigir; (d) C7_IPIBRUT = "Cons. Desc. Considera Desconto p/IPI" (TDN IMP0058); (e) Impressao TOTVS pode recalcular impostos do zero — verificar se le campos gravados.

**SQL validacao APSDU**: `SELECT C7_BASEIPI, C7_VALIPI, C7_IPIBRUT FROM SC7010 WHERE C7_NUM='<NUM>' AND D_E_L_E_T_=' '`

**Complementos MATA120 ativos**: `MT120TFR.PRW` (gatilhos SX7 U_MT120IPI + frete), `MTA120G3.PRW` (gravacao), `MT120OK.PRW` (pre-save).

## Casos Arquivados (consultar antes de debugar)

### FWBUILDFEATURE / SSYacc0105e (02/07/2026) — resolvido

**Erro**: `invalid macro source (SSYacc0105e: Error token failed, no valid token):({|a,b,c| FWInitCpo(a,b,c),xRet:=(@!),FWCloseCpo(a,b,c,.T.),xRet })` em `FWBUILDFEATURE(PROTHEUSFUNCTIONMVC.PRX)`.

**Causa-raiz (oficial TOTVS Central #4404702402455)**: O `X3_PICTVAR` (Form. Variável) de campos do SX3 contém `@!`. O framework monta code-block `xRet:=(<X3_PICTVAR>)` e o macro-parser quebra com `(@!)`.

**Solucao aplicada no ZLANCDIE.PRW**: Refatorar `FBrowse()` de `FWMBrowse` para **`mBrowse` + `aRotina` + `User Function` wrappers** (padrao `CADSZ3.PRW`). Elimina dependencia de `FWBUILDFEATURE`/`FWFORMSTRUCT`.

**Skill canonica criada**: `.opencode/skills/advpl-fwbrowse-fwbldfeature-bug/SKILL.md` — contem:
- Sintomas/triggers
- 4 queries de diagnostico SQL
- 4 solucoes (limpar X3_PICTVAR, profile, mBrowse, evitar SetDataQuery)
- Links oficiais TOTVS Central (5 artigos) + Forum (thread #19677)
- Prevencao (regras para criacao de tabelas Z*)

**Ao encontrar este erro novamente**: carregar a skill `advpl-fwbrowse-fwbldfeature-bug` ANTES de tentar qualquer alteracao.

## Identidade do Projeto

- **Projeto**: Vortice — Customizacoes AdvPL/TLPP para TOTVS Protheus 12.1.33
- **Modulo principal**: Suprimentos / Compras (SIGAEST, SIGACOM)
- **Workspace**: `C:\totvs\advpl\.vscode\programas_vortice`
- **Plataforma**: Windows (win32), PowerShell 5.1
- **Repo git**: NAO (sem `.git`) — usar file reads e Grep para inspecionar mudancas

## Ambiente de Desenvolvimento

- **Compilacao**: TDS VS Code extension (nao e uma skill OpenCode)
  - Config: `.vscode/launch.json`
  - Includes: `C:\totvs\includes`
- **Encoding**: Todos os fontes devem ser **CP1252** (Windows-1252)
  - IA gera UTF-8 → converter via skill `utf8-to-cp1252-conversion` (PAI) antes de compilar
- **MCP**: Servidor `advpl-sensei` ativo (funcoes `advpl-sensei_advpl_*`)

## Fontes de Codigo

### CADPOSIC — FWMBrowse com Pesquisa Rápida (30/08/2026) — resolvido

**Problema**: Tela FWMBrowse da tabela customizada ZC1 (Posições de Estoque do Item) sem barra de pesquisa e sem botões CRUD.

**3 erros encadeados resolvidos**:
1. `SetSeek(.T.)` sem array `aSeek` → barra de pesquisa não aparece. **Solução**: `SetSeek(.T., aSeek)` com array de definição dos campos.
2. `SetFieldSeek()` **não existe** em FWMBrowse → erro de method. Usar `SetSeek` com 2º parâmetro.
3. `Private aRotina` e `Private cCadastro` não declarados → `AxInclui`/`AxAltera`/`AxDeleta` falham com "variable does not exist CCADASTRO".

**Estrutura correta**:
```advpl
Private aRotina  := {{"Visualizar", "AxVisual", 0, 2},;
                     {"Incluir",    "AxInclui", 0, 3},;
                     {"Alterar",    "AxAltera", 0, 4},;
                     {"Excluir",    "AxDeleta", 0, 5}}
Private cCadastro := "Titulo do Browse"

aSeek := {;
    {"Filial",    {{"ZC1_FILIAL", "C", 2,  0, "Filial",    "@!"}}, 1, .T.},;
    {"Codigo",    {{"ZC1_ITEM",   "C", 13, 0, "Codigo",    "@!"}}, 2, .T.},;
    {"Descricao", {{"ZC1_DESCRI", "C", 50, 0, "Descricao", "@!"}}, 3, .T.};
}
oBrowse:SetSeek(.T., aSeek)
```

**Campos ZC1 confirmados**: ZC1_FILIAL (2), ZC1_ITEM (13), ZC1_DESCRI (50), ZC1_POSIC, ZC1_SALDO, ZC1_LOCAL.

**Regras derivadas**:
- `TamSx3()` e `FWSizeFilial()` NÃO devem ser chamados inline no array literal de `SetSeek` para tabelas Z* (causa "array out of bounds").
- Sempre conferir nomes dos campos no Configurador (SIGACFG) — nomes podem ser diferentes do esperado.

### Arquivos na raiz do workspace (49 .PRW + 2 .TLPP)

**Funcoes customizadas (Z*.PRW) — 20 arquivos:**
ZSLDEST, ZMMA02, ZMMA01, ZMM01, ZLOGCOL, ZLEADTIME, ZFIXSX3SA2, ZFIXMODSA2,
ZCTAEST, ZCRIAZZ4SA2, ZCRIASX3, ZCONSRE5, ZCOMPRAS, ZCALCCOM, ZAVALNEG,
ZANALPRC, ZANALBX, ZALTZZ4SA2, ZADTASK

**Pontos de Entrada (MT*.PRW / MTA*.PRW) — 21 arquivos:**
MT100TOK, MT100OK, MT020ATE, MT010ALT, M020EXC, MT20FOPOS, MT160GRPC,
MT150GET, MT120OK, MT110TOK, MT101OK, MTA105OK, MTA094RO, MTA020,
MTA131C8, MTA110OK, MTALCFIM

**Telas/Cadastros (CAD*.PRW) — 4 arquivos:**
CADSZ3, CADSOLIC, CADFORN, CADPOSIC

**Outros .PRW:**
AVALCOT, CORCITEM, FALTFPED, FFZZ4A2, OPENZZ4, RLCOMPRAS, TIDEV,
VLDNOMEFORN, VOGSB101, VORATF01, VOREST02

**TLPP (.tlpp):**
ZDIAG110.tlpp, TESTDATA.tlpp

### Exemplos canonicos (na raiz do workspace)

| Tipo | Arquivo (raiz) |
|------|----------------|
| Telas/Cadastro | `CADSZ3.PRW` |
| Ponto de Entrada | `MTA110OK.PRW` |
| Relatorio/Analise | `ZANALBX.PRW` |

## Convencoes de Nomenclatura de Arquivos

| Prefixo | Tipo | Exemplos |
|---------|------|----------|
| `Z*.PRW` | Funcoes customizadas | ZCOMPRAS, ZAVALNEG, ZANALPRC |
| `MT*.PRW` | Pontos de Entrada | MT110TOK, MT20FOPOS |
| `MTA*.PRW` | PEs de Aprovacao | MTA110OK, MTA094RO |
| `CAD*.PRW` | Telas de Cadastro | CADSZ3, CADFORN, CADSOLIC |
| `*.tlpp` | Classes TLPP | ZDIAG110, TESTDATA |

## Tabelas-Chave (Suprimentos)

| Alias | Descricao | Filtros Canonicos |
|-------|-----------|-------------------|
| SC7 | Pedidos Compra | `C7_RESIDUO<>'S'`, `C7_QUANT>0`, `C7_CONAPRO NOT IN ('R','B')` |
| SC1 | Solicitacoes Compra | Key: `xFilial("SC1") + C1_NUM` |
| SC8 | Cotacoes | Key: `xFilial("SC8") + C8_NUM` |
| SA2 | Fornecedores | `A2_CGC` = 14 digitos sem formatacao |
| SD1 | NF Entrada | |
| SD3 | Mov. Estoque | TM <= 499 entrada, > 499 saida |
| SB1 | Produtos | `B1_MSBLQL <> '1'` |
| SB2 | Saldos | `B2_COD = B1_COD AND B2_LOCAL = B1_LOCPAD` |
| SB9 | Saldos Historicos | `B9_DATA` = YYYYMMDD, `B9_QINI`/`B9_VINI1` |
| SCP | Solic. Armazem | `CP_NUM` = D3_NUMSA, `CP_QUJE >= CP_QUANT` |
| CTT | Centros de Custo | `CTT_CUSTO = D3_CC` |
| SCR | Aprovacoes | `CR_TIPO`: 'IP' ou 'PC', `CR_STATUS='03'`=aprovado |
| SZ3 | Solic. Cadastrais Produtos | `Z3_ID` key, Z3_STATUS: 0/1/2 |
| ZZ3 | Solic. Cadastrais (alt) | `Z3_ID` key |
| ZZ4 | Solic. Fornecedor | `ZZ4_ID` key |

## Padroes de Codigo Identificados

### Includes
```advpl
#Include "Protheus.ch"
#Include "TopConn.ch"
```

### Estrutura de Funcao
- Cabecalho `/*/{Protheus.doc}.../*/` em todas (User e Static)
- `Local aArea := GetArea()` ... `RestArea(aArea)`
- `xFilial("ALIAS")` para filtro de filial
- `RecLock` apenas para tabelas custom Z* (core → MSExecAuto)
- `GetNextAlias()` + close para alias temporarios
- `ConOut("[PE_NAME] msg")` para log em PEs

### UI
- mBrowse + aRotina + aCores para cadastros
- MSDIALOG 650x1300 PIXEL para analises
- LISTBOX com SetArray + bLine + aColSizes
- TReport para exportacao Excel/PDF
- ParamBox para filtros

### SQL
- `RetSqlName("ALIAS")` + `D_E_L_E_T_ = ' '`
- `ChangeQuery()` em queries string
- `DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)`
- Datas: `DtoS(dData)` para filtro SQL, `StoD(cData)` para conversao inversa
- Limpeza de data: `CtoD("  /  /  ")` — nunca NULL

## Skills OpenCode Instaladas

Local: `.opencode/skills/` (15 skills + arquivos de padroes)

Skills ativas:
- `advpl-code-generation` — geracao de codigo (functions, classes, MVC, REST, PEs)
- `advpl-code-review` — revisao (boas praticas, performance, seguranca, modernizacao)
- `advpl-debugging` — diagnostico de erros e logs
- `advpl-fwbrowse-fwbldfeature-bug` — bug SSYacc0105e em FWBUILDFEATURE/X3_PICTVAR
- `advpl-refactoring` — refatoracao
- `advpl-to-tlpp-migration` — migracao ADVPL → TLPP
- `changelog-patterns` — changelogs
- `code-explanation` — explicacao de codigo
- `documentation-patterns` — documentacao tecnica
- `embedded-sql` — SQL embutido (BeginSQL/EndSQL)
- `probat-testing` — testes unitarios ProBat
- `protheus-business` — processos de negocio Protheus
- `protheus-reference` — funcoes nativas, SX, APIs REST, parametros MV
- `sx-configuration` — dicionario SX (SX3/SIX/SX1/SX5)
- `karpathy-guidelines` — diretrizes comportamentais

Skill canonica do workspace (criada nesta sessao):
- `.opencode/skills/advpl-protheus.md` — padroes completos + checklist de qualidade

## Estrutura Hierarquica .opencode/

OpenCode descobre configuracoes subindo diretorios a partir do CWD atual
(`programas_vortice/`):

### [PAI] `C:\totvs\advpl\.vscode\.opencode\` (workspace-wide)
- 5 commands OpenSpec em `commands_opsx-*.md` soltos (propose/apply/explore/archive/sync)
- 5 skills OpenSpec em `openspec-*.md` soltos (mesmo conteudo, usados via `.claude/skills/`)
- 2 references em `references_*.md` soltos (sonarqube-rules, advpl-tlpp-skills)
- 4 subagentes em `agents/` (advpl-dev, advpl-review-checklist, html-frontend-dev, html-frontend-verify)
- `package.json` runtime (@kilocode/plugin + @opencode-ai/plugin)
- AGENTS.md com regras SIGAEST globais
- memory.md (workspace-wide)
- opencode.json: model=opencode-go/minimax-m3, default_agent=advpl-dev, mcp.advpl-sensei habilitado

> **NOTA (corrigido em 29/06/2026)**: O PAI NAO possui as 28 skills TOTVS engpro
> no `.opencode/skills/` (pasta esta vazia/inexistente). As skills engpro existem
> APENAS no FILHO (`programas_vortice\.opencode\skills\`, 45 skills). O PAI
> fornece apenas: 4 agents, AGENTS.md, memory.md, opencode.json, mcp.advpl-sensei.
> Excecao: 3 skills compartilhas (advpl-error-memory, protheus-rules, sql-safe)
> em `..\.claude\skills\advpl\` (carregadas via `opencode.json.skills.paths`).
> Dessas, `advpl-error-memory` divergiu entre os dois locais — preservada nos dois.

### [FILHO] `programas_vortice\.opencode\` (este projeto)
- 45 skills em `skills/` (todos em diretorios, 0 .md soltos)
  - Canonica do Vortice: `advpl-protheus/` (skills/advpl-protheus/SKILL.md)
  - Skills engpro: code-generation, code-review, debugging, refactoring,
    migration, sx-configuration, mvc-generator, fwrest-client-generator,
    tlpp-rest-endpoint-generator, entry-point-designer, data-dictionary-lookup,
    protheus-reference, protheus-business, embedded-sql, query-builder,
    sql-code-review, sql-optimization, probat-testing,
    tir-test-generator, utf8-to-cp1252-conversion, verification-evidence,
    code-explanation, changelog-patterns, documentation-patterns,
    documentation-writer, create-implementation-plan, context-map, refactor,
    refactor-method-complexity-reduce, frontend-quality, solucoes-consultas,
    pontos-entrada, tabelas-protheus, advpl-empresa,
    advpl-error-memory, advpl-fwbrowse-fwbldfeature-bug, advpl-tlpp-sdd, advpl-tela-consulta,
    advpl-tlpp-reference-guide, superpowers, vortice-workflow
- 10 subagentes em `agents/` (changelog-generator, code-generator, code-reviewer,
  debugger, doc-generator, docs-reference, migrator, process-consultant,
  refactorer, sx-configurator)
- memory.md (este arquivo - contexto Vortice)
- 45 skills em `skills/` (eram 44; +1 `advpl-fwbrowse-fwbldfeature-bug` em 02/07/2026)
- Sem `node_modules/`, sem `package-lock.json/` (removidos em 29/06/2026; sem plugin ativo)
- `opencode.json` agora é stub de schema (referência de plugin quebrada foi removida)

### [Claude] `C:\totvs\advpl\.vscode\.claude\skills\openspec-*`
- 5 skills workflow OpenSpec (apply-change, archive-change, explore,
  propose, sync-specs)

### Descoberta automatica
- Skills FILHO via `.opencode/skills/<name>/SKILL.md` (estrutura padrao)
- Skills PAI via registro no opencode.json (locations apontando pra .md)
- Agents PAI via `.opencode/agents/*.md`
- Skills OpenSpec via `.claude/skills/openspec-*/SKILL.md`

## Documentos de Referencia Externos

- `../CLAUDE.md` — documento raiz de diretrizes (source of truth)
- `../CLAUDE-SOLUTION-PATTERNS.md` — solucoes validadas (F3/SXB/PEs/filtros)
- `../openspec/` — pasta para especificacoes OpenSpec (changes ativas e arquivadas)
- `AGENTS.md` — referencia compacta para agentes OpenCode
- `.opencode/skills/advpl-protheus.md` — skill canonica com padroes e checklist

## Pendencias e Limitacoes Conhecidas

1. **Encoding**: Conversao UTF-8 → CP1252 via skill `utf8-to-cp1252-conversion` (PAI)
2. **Git**: Repositorio nao versionado — sem `git status/diff/log`
3. **Glob case-sensitive**: `**/*.prw` nao acha `.PRW` no Windows — usar `**/*.[pP][rR][wW]`
4. **Skills no CLAUDE.md**: Algumas skills referenciadas em `CLAUDE.md` (secao 20) nao estao disponiveis como loadable skills — verificar `available_skills` antes de usar

## Fluxo de Trabalho Recomendado

1. **Inicio de sessao**: ler este arquivo (`.opencode/memory.md`)
1.5 **Consultar memoria de erros**: se a tarefa envolver correcao de bug ou erro, carregar a skill `advpl-error-memory` (PAI) e revisar `CLAUDE-SOLUTION-PATTERNS.md` para verificar se o problema ja foi resolvido anteriormente
2. **Antes de responder qualquer solicitacao**: identificar a tarefa e carregar a skill correta conforme a Tabela de Roteamento em `AGENTS.md` (secao "Skill Consultation Rules"). NUNCA responder tecnicamente sem antes carregar a skill relevante.
3. **Antes de implementar**: carregar skill `advpl-code-generation` (ou `protheus-business` para processo de negocio)
4. **Gerar codigo**: usar skill especifica conforme tarefa (ver tabela de roteamento)
5. **Revisar**: carregar `advpl-code-review` / `embedded-sql` apos gerar codigo
6. **Apos gerar .prw/.tlpp**: converter UTF-8 → CP1252 via skill `utf8-to-cp1252-conversion`
7. **Compilar**: usar TDS VS Code extension (skill `advpl-tlpp-compile` se necessario)
8. **Erro desconhecido**: consultar TDN (tdn.totvs.com) — nao assumir
9. **Antes de concluir**: executar Checklist de Qualidade em `.opencode/skills/advpl-quality-checklist/SKILL.md`
10. **Sugerir proximo passo**: revisao, encoding, compilacao

## Regras de Comportamento (mandatorio)

> **As 13 regras Vortice vivem em `AGENTS.md` do FILHO** (secao "Regras Vortice").
> **As 5 super-regras workspace-wide vivem em `..\.opencode\AGENTS.md` (PAI).**
> Esta secao NAO duplica — apenas referencia para evitar drift.

Hierarquia de regras:
1. `..\.opencode\AGENTS.md` (PAI) — 5 super-regras (portugues, perguntar, nao presumir, GetArea, xFilial)
2. `AGENTS.md` (FILHO) — 13 regras Vortice-specificas
3. `.opencode/skills/advpl-protheus/SKILL.md` — padroes detalhados + exemplos
4. `.opencode/skills/advpl-quality-checklist/SKILL.md` — checklist obrigatorio pre-conclusao

## Changelog

### 30/08/2026
- **CADPOSIC**: criado tela FWMBrowse para tabela ZC1 (Posições de Estoque do Item) com pesquisa rápida. 3 erros resolvidos: SetSeek com aSeek, aRotina+cCadastro para CRUD, nomes de campos ZC1 conferidos no Configurador.
- **Atualizado**: `06 - Bugs Resolvidos.md` (Obsidian) com caso FWMBrowse SetSeek.
- **Atualizado**: `07 - Padrões de Código ADVPL.md` (Obsidian) com padrão FWMBrowse + pesquisa rápida.

### 15/08/2026
- **MATA120 IPI**: solucao completa em 3 camadas — gatilho SX7 U_MT120IPI (tempo real + MaFisRef para rodape), MTA120G3 (gravacao), impressao pendente (form recalcula IPI bruto). SC7 validado via APSDU.
- **Atualizado**: `06 - Bugs Resolvidos.md` (Obsidian) com solucao completa e pendencia de impressao.

### 02/07/2026
- **Caso arquivado: FWBUILDFEATURE / SSYacc0105e** — bug em `PROTHEUSFUNCTIONMVC.PRX` quando `X3_PICTVAR` tem `@!`
- **Skill canonica criada**: `advpl-fwbrowse-fwbldfeature-bug` (em `.opencode/skills/advpl-fwbrowse-fwbldfeature-bug/SKILL.md`)
- **Solucao aplicada**: ZLANCDIE.PRW refatorado de FWMBrowse para mBrowse (padrao CADSZ3.PRW)
- **Atualizado**: memory.md com secao "Casos Arquivados" para consulta futura
- **Fontes oficiais**: 5 artigos TOTVS Central + 1 thread Forum TOTVS (build 7.00.240223P)

### 30/06/2026
- **Cleanup completo do workspace** — todos os artefatos mortos removidos:
  - PAI `.opencode/`: removidos `.vscode/` (leak de cache VSCode), `node_modules/` (25 pacotes), `package.json`, `package-lock.json`
  - FILHO `programas_vortice/`: removido `node_modules/` (28 pacotes SQL Server)
  - FILHO `.opencode/`: removidos `node_modules/` (28 pacotes), `package.json` (plugin ref quebrada)
- **Provider Ollama removido** do global `opencode.jsonc` (URL ngrok era efemera, nao utilizada)
- **Agent.disable para README** testado — `agent.disable` em `opencode.json` NAO funciona para agentes built-in do OpenCode
  - Issue #15222 (enable/disable from TUI) aberta desde Fev/2026
  - Issue #21364 (`footerShowSubagents`) planejado para v1.3.6 mas nao implementado
  - **Conclusao**: agente README e feature built-in, nao configuravel — usuario deve ignora-lo no TUI
- **verify-harness.ps1**: 28/28 PASS (estado final limpo)
- Estado final:
  - PAI: 4 agents, AGENTS.md, memory.md, opencode.json, openspec-config.yaml, 2 references, tui.json
  - FILHO: 10 agents, 45 skills, memory.md, opencode.json (instructions + commands + MCPs)
  - Global: model routing, shell=powershell, MCP advpl-tds-ls

### 29/06/2026 (continuacao)
- **Investigado e removido**: 5 `commands_opsx-*.md` + 5 `openspec-*.md` soltos no PAI `.opencode/`
  - `commands_opsx-*` eram versoes antigas (substituidas por inline templates em `programas_vortice/opencode.json`)
  - `openspec-{apply,archive,explore,propose,sync}.md` eram duplicatas (canonico em `../.claude/skills/`)
  - `openspec-project.md` orfao removido
  - PAI typo detectado: `/opsx:apply` → canonical `/opsx-apply` em .claude/skills/
  - Mantidos: `openspec-config.yaml` (config), 2 `references_*.md` (docs uteis)
- **Leak de cache removido**: `\.opencode\.vscode\` (com `.advpl` e `.cache` do VSCode) - lixo
- **Deps mortas removidas** (confirmado por busca: nao referenciadas em nenhum `opencode.json`):
  - PAI: `package.json` (com `@kilocode/plugin` + `@opencode-ai/plugin`) + `package-lock.json` + `node_modules/` (25 pacotes)
  - FILHO: `package.json` (com `@opencode-ai/plugin`)
- **`.claude/hook-chains.json` removido** (estava `enabled: false` - dead code)
- **`.claude/README.md` criado** documentando uso dual (Claude Code + OpenCode)
- **`verify-harness.ps1` criado** em `programas_vortice/` - smoke test com 28 checks (executar antes de cada deploy)
- **`README.md` criado** em `programas_vortice/` - onboarding rapido (hierarquia, model routing, como rodar)
- PAI `.opencode/` final: 4 agents, AGENTS.md, memory.md, opencode.json, openspec-config.yaml, 2 references, tui.json
- FILHO `.opencode/` final: 10 agents, 45 skills, memory.md, opencode.json (schema-only)

### 24/06/2026
- Removido: duplicacao de regras entre `AGENTS.md` FILHO e `memory.md` (referencia cruzada)
- Criado: skill `advpl-quality-checklist` (extraida de `advpl-protheus.md`)
- Atualizado: PAI `AGENTS.md` para 5 super-regras (workarounds historicos mantidos)
- Reorganizado: hierarquia PAI (5) -> FILHO (13) -> canonica (detalhes) -> checklist (gate)

### 29/06/2026
- Corrigido: Provider `opencode-zen` nao existia em auth.json — todos os modelos `opencode-zen/*` retornavam "Model not found"
- Corrigido: Modelos renomeados — `opencode-zen/deepseek-v4-flash-free` → `opencode-go/deepseek-v4-flash`,
  `opencode-zen/mimo-v2.5-free` → `opencode-go/mimo-v2.5`
- Motivo: `opencode-zen` requer `/connect` + API key separada; `opencode-go` ja esta autenticado e
  inclui ambos os modelos (DeepSeek V4 Flash $0.14/$0.28, MiMo-V2.5 $0.14/$0.28)
- Docs consultadas: https://opencode.ai/docs/go, https://opencode.ai/docs/zen, https://opencode.ai/docs/providers
- Atualizados: opencode.jsonc (global), image-analyzer.md, AGENTS.md (global/PAI/FILHO), README.md,
  verify-harness.ps1

### 22/06/2026
- Adicionado: Regra "Consultar skills antes de qualquer acao" (AGENTS.md regra 11, memory.md)
- Adicionado: Regra "Encoding uma unica vez por programa" (AGENTS.md regra 12, memory.md)

### 21/06/2026
- Corrigido: Pendencias item #1 (encoding) — `utf8-to-cp1252-conversion` agora existe como skill no PAI
- Corrigido: Pendencias item #3 (openspec) — pasta contem changes ativas/arquivadas, nao esta vazia
- Corrigido: Pendencias item #4 renumerado (antigo #5) — skills TOTVS engpro AGORA existem como loadable skills
- Corrigido: Nota no Ambiente de Desenvolvimento — encoding agora cita `utf8-to-cp1252-conversion`
- Corrigido: Referencia ao openspec \"recem-criada, vazia\" → \"changes ativas e arquivadas\"
- Adicionado: Secao Changelog para rastrear alteracoes neste arquivo
