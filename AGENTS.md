# AdvPL/TLPP Development Guidelines

## Language and Ecosystem

This workspace contains source code for **TOTVS Protheus ERP** in the **AdvPL** (`.prw`, `.prg`, `.prx`, `.ppx`) and **TLPP** (`.tlpp`) languages, plus automated tests in **Python** (TIR — interface/e2e via Webapp).

Foco do cliente: **Vortice Consultoria Mineral** — módulo **Suprimentos/Compras** (SC7 tomadas centrais) sobre **Protheus 12**, build `7.00.240223P`, banco SQL Server.

> **Idioma padrão**: todas as interações, documentação, comentários, mensagens de commit e revisões em **português brasileiro**; identificadores seguem convenção técnica (inglês/abreviaturas Protheus).

## Base de Conhecimento — Obsidian (consultar ANTES de codar ou debugar)

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

O vault externo (`C:\Users\Vortice 0097\Desktop\BKP_JUAN\Memoria\Memoria\ADVPL-Protheus\`) pode
ficar inacessível no runtime (máquina sem o BKP, caminho movido, permissão). Nesse caso,
**consultar/registrar** segue a rota alternativa abaixo — a precedência da hierarquia de docs
(seção seguinte) permanece intacta; apenas a fonte 2 (Obsidian) é substituída pelo fallback:

| Situação | Fallback de consulta | Fallback de registro |
|----------|----------------------|----------------------|
| Bug / erro desconhecido | `.kiro/steering/bugs-resolvidos.md` (versionado no repo) | Adicionar o caso resolvido ao `.kiro/steering/bugs-resolvidos.md` e registrar em `.opencode/memory.md`; sincronizar para o Obsidian quando voltar |
| Padrão de código | `.kiro/steering/padroes-codigo.md` | — |
| Contexto/regras do projeto | `.kiro/steering/projeto-advpl.md`, `.opencode/memory.md` | Atualizar `.opencode/memory.md` |
| Busca por tabela/filtro/PE | TDN oficial (tdn.totvs.com) + fontes web confiáveis + `CONFIG/.opencode/skills/tabelas-protheus` | Registrar achado em `.kiro/steering/` |

- `.kiro/steering/*.md` são **versionados no repositório** e espelham os resumos do vault.
- Ao resolver bug novo com o vault indisponível: registrar **imediatamente** no fallback e
  sincronizar para `06 - Bugs Resolvidos.md` (Obsidian) quando o caminho voltar.
- Se o vault estiver disponível, **prevalece o vault** (hierarquia de docs inalterada).

---

## Hierarchy of Documentation (precedência)

Em caso de conflito entre arquivos de documentação, vale nesta ordem:
1. **Instruções do usuário** (sempre acima de qualquer doc)
2. **Obsidian** (`06 - Bugs Resolvidos.md` — solução já documentada tem precedência)
3. `CONFIG/AGENTS.md` (SUPER-regras SIGAEST/workspace — tabelas core, acesso a dados)
4. Este `AGENTS.md` (raiz — convenções de código, padrões, checklist)
5. `CLAUDE.md` / `DOCUMENTACAO/` (referências e kits)
6. Skills (`SKILLS/` e espelho `.opencode/skills/`)
7. TDN oficial (tdn.totvs.com) + fontes web confiáveis

> **Fonte de verdade única de código**: o próprio repositório. Se doc conflita com fonte real, o **código vence** — registrar a divergência como achado, não ignorar.

> **[PENDENTE] OpenSpec**: referências a `openspec` e comandos `opsx-*` removidos de `opencode.json` (não usados). Se necessário no futuro, reavaliar e documentar aqui.

---

## Project Structure (real)

```
PROGRAMAS_ADVPL/                   # raiz deste workspace
├── FONTES/              # fontes principais (62): MT*/MTA* (Entry Points), Z* (custom),
│                        #   CAD* (cadastros), VO*/V* (Vortice), *.tlpp (TLPP moderno), PE*
│   │                    #   nome arquivo = nome do PE. Ex.: MTA110OK.PRW, MT110TOK.PRW
├── INCLUDES/            # includes binários (_binary_class.prw, _binary_functions.prw)
├── PATCHES/
│   ├── PATCH/           # patch original (~13 fontes)
│   └── PATCH_01/        # MT110TOK + custom25-06-2026.ptm
├── SKILLS/              # skills locais do repo (cada <nome>/SKILL.md) — catálogo em skills-registry.json
├── DOCUMENTACAO/        # CLAUDE-SKILLS-REF.md, CLAUDE-SOLUTION-PATTERNS.md, listas (*.txt)
├── CONFIG/              # configuração do workspace:
│   ├── servers.json     # AppServer TOTVS (conexão/compilação)
│   ├── references_sonarqube-rules-reference.md        # regras SonarQube G1–G5 (AUTORMENTE)
│   ├── references_advpl-tlpp-skills-reference.md      # catálogo completo de skills
│   ├── AGENTS.md        # SUPER-regras SIGAEST/workspace (ver abaixo)
│   ├── tir/             # scripts TIR (testes python)
│   ├── .vscode/         # settings.json, launch.json, snippets
│   └── .advpl/          # includes AdvPL
├── .opencode/           # agents/, skills/ (espelho), memory.md
└── .vscode/             # settings.json, launch.json, snippets (projeto)

> Config principal OpenCode (`opencode.json`, default_agent) fica em
> `~/.config/opencode/opencode.jsonc` (global), NÃO na raiz do repo.
> `CONFIG/.opencode/README.md` documenta o estado real da configuração.
```

Skills de agentes também existem (espelhadas) em `.opencode/skills/`. Nunca assumir skill sem localizá-la em `SKILLS/`, `.opencode/skills/` ou nas skills globais do OpenCode.

> **ORIENTAÇÃO**: Leia `CONFIG/AGENTS.md` (regras de workspace SIGAEST) antes de tocar em tabelas core — inclui regras de acesso a dados, `GetArea()/RestArea()`, `xFilial()`, `RecLock` SÓ em tabelas `Z*`, `MSExecAuto` para tables core, e histórico de workarounds (SXB/ZZ4/FWBrowse). Doc não substitui o trade.

---

## Build and Compilation

- **Compilador**: RDMake (TOTVS) via extensão **TOTVS Language Server** (tds-vscode) no VS Code, ou headless via CLI `advpls.exe` (skill `advpl-tds-ls`).
- **Servidor**: AppServer TOTVS `CINVJ6_DEV` (`vortice192877.protheus.cloudtotvs.com.br:10771`, build `7.00.240223P`), config em `CONFIG/servers.json`.
- **Includes do compilador**: `C:\totvs\includes` (definido em servers.json e `.vscode/settings.json`).
- **Workflow pós-geração obrigatório**:
  1. Gerar código (cria UTF-8)
  2. Converter **UTF-8 → CP-1252** (skill `utf8-to-cp1252-conversion`) — o RDMake ignora/corrompe UTF-8
  3. Compilar contra o AppServer (skill `advpl-tlpp-compile`)
  4. Code review (`advpl-code-review` / `code-review`)
- `.PRJ` aponta fontes por módulo (não há Makefile/Gradle); output `.O` no RPO.

---

## Code Conventions

### Naming
- **Notação húngara obrigatória**: `c` (char), `n` (num), `d` (date), `l` (logical), `a` (array), `o` (object), `b` (codeblock), `x` (variat), `j` (json)
- **Arquivos fonte**: prefixo módulo (4 letras) + número (3 dígitos) — ex.: `MATA010`, `FINA138`; fontes Z* e VO* não seguem.
- **Campos de tabela**: prefixo tabela (2-3 letras) + `_` + nome — ex.: `A1_COD`, `C7_QUANT`.
- **Convenções deste repo** (README): `MT*`/`MTA*` = PE de rotinas MATA*, `Z*` = custom, `CAD*` = cadastro, `V*`/`VO*` = Ventice.

### Type System

#### AdvPL Types
> **Atenção**: `as` NÃO existe em AdvPL — é exclusivo de TLPP. Em `.prw`, tipagem é apenas por prefixo húngaro.
| Type | Indicator | Descrição |
|------|-----------|-----------|
| Character (C) | `C` | strings até 65.535 chars (64 KB). Delimitadores `" "` ou `' '` |
| Memo (M) | `M` | como Character, tamanho livre; armazenado em dados (SYP) |
| Numeric (N) | `N` | ponto flutuante; precisão 15 dígitos |
| Logical (L) | `L` | `.T.`/`.Y.` (true), `.F.`/`.N.` (false) |
| Date (D) | `D` | datas em juliano interno |
| Fixed Size Decimal (F) | `F` | decimais de tamanho fixo, alta precisão |
| Array (A) | `A` | arrays multidimensionais |
| Code Block (B) | `B` | código executável armazenável |
| Undefined (U) | `U` | tipo indefinido (NIL) |
| Object (O) | `O` | instâncias de classes |

### TLPP Types (typing estático — anotações com `as`)
| Tipo | Indicador | Default | Descrição |
|------|-----------|---------|-----------|
| `numeric` | `N` | `0` | ponto flutuante |
| `integer` | `N` | `0` | inteiro (contadores, loops) |
| `decimal` | `F` | `Nil` | alta precisão — **dinheiro** |
| `character` | `C` | `""` | texto |
| `logical` | `L` | `.F.` | `.T.`/`.F.` |
| `date` | `D` | `31/12/1899` | datas |
| `json` | `J` | `Nil` | JSON |
| `array` | `A` | `Nil` | arrays |
| `object` | `O` | `Nil` | classes |
| `codeblock` | `B` | `Nil` | code blocks |
| `variant` | `U` | `Nil` | autopolimórfico |
| `variadic` | `J` | `-` | parâmetros de comprimento variável (não instanciável) |

#### TLPP — declaração de variável
```tlpp
// CERTA'?  atrás do tipo
Local cName  := "" as Character
Local nTotal := 0  as Numeric
Local oModel as Object          // sem atribuição — válido
// ERRADO: 'as' antes da atribuição — não compila
Local cX as Character := ""     // não compila
```

#### Ordem obrigatória em toda função/método
```advpl
User Function MyFunction()      // 1. cabeçalho
    Local  cVar := ""           // 2. todos os Local
    Private cPriv := ""         // 3. todos os Private (logo após)
    // ... código               // 4. lógica
Return xValue                   // 5. Return
```
Nunca declarar `Local`/`Private` no meio do fluxo (dentro de `If`, `For`, após chamada).

#### Classes (AdvPL/TLPP estrutura em duas partes)
- Declaração dentro de `class`/`endclass` **tem** modificadores de acesso (`public`, `private`, `protected`, `static`).
- Implementação (fora `endclass`) **nunca** tem modificador nem `static` — apenas `method`, nome, parâmetros, retorno e `class Classe`.
```tlpp
class MinhaClasse
    public method new() as object
    private method valida() as logical
    private data nVal as numeric
endclass

method new() as object class MinhaClasse
return self

method valida() as logical class MinhaClasse
return ::nVal > 0
```
- Herança usa **`from`** (não `extends`/`inherits`/`of`).
- Construtor de classe filha chama `_Super:new()`.
- `static method` — na declaração aceita apenas `()` vazio (sem params/retorno); params e retorno vão SÓ na implementação.

> Fonte: TDN TOTVS (TDN pageId 821588162 / 334341656 / 822220426).

### Include Files
- Padrão moderno: `#include "totvs.ch"`.
- TLPP: `#include "tlpp-core.th"` **primeiro**, depois `totvs.ch`.
- **Regra de precedência**: códigos novos e refactors usam `#include "totvs.ch"`. PE/fontes legados que já usam `#include "Protheus.ch"` **mantêm** o include atual (não migrar por caça ao estilo; migrar apenas se o arquivo for tocado em refactor). Ex.: `MT120TFR.PRW`, `MT120OK.PRW` continuam `Protheus.ch`.
- NÃO use includes obsoletos em código novo: `protheus.ch`, `Ap5Mail.ch`, `ApWizard.ch`, `FileIO.ch`, `Font.ch`, `ParmType.ch`, `RWMake.ch` (substituídos por apis modernas em `totvs.ch`).

### Mandatory Standards (SonarQube + TOTVS)
- SQL: sempre `D_E_L_E_T_ = ' '` (soft-delete), filtro por filial `XX_FILIAL = xFilial('XXX')`, `FWExecStatement`/`ChangeQuery()` (anti-injection), `RetSqlName()` na tabela física, `%nolock%` em leitura.
- Nunca chamar `GetMV()`, `SuperGetMV()`, `ExistBlock()`, `Type()`, `Pergunte()` dentro de loop.
- **`Function` proibido** em customização — use `User Function` (público) ou `Static Function` (interno ao arquivo). Escopo `Function` é reservado ao produto.
- **Entry Points**: nome NÃO tem prefixo `U_` (`User Function MT410INC()`, nunca `U_MT410INC()`). Nome do arquivo = nome do PE, maiúsculo (ex.: `MT410INC.tlpp`, `A010TOK.prw`).
- **Encoding**: arquivos `.prw/.prg/.prx/.tlpp/.ch/.aph` em **CP-1252** — nunca UTF-8.
- **Destruição**: use `Destroy()` da própria class; nunca `FwFetchObj()`/`FreeObj()`/`FwFreeArray()` se a class tem `Destroy()`.
- **`IIF` proibido** — use `If/Else/EndIf` explícito (SonarQube CA4000).
- **Sem UI dentro de transação** (`MsgAlert`, `MsgYesNo`, `Aviso`, `Help`, `Pergunte`...) — deadlock multi-user (CA1002).
- **No ISAM/`MSCREATE`/`DBCREATE`/`CRIATRAB`** — use `FWTemporaryTable` (CA1000).
- **Sem `ConOut()`/`OutErr()`/`?`** — use `FWLogMsg()` (CA1004).
- **Nunca use variável `cFilial` direta** (reservada) — use `cFilAux`, ou `xFilial('XXX')`/`FWxFilial('XXX')`.
- **REST client externo** — sempre via `FWRest`. Proibido `HTTPCGet/HTTPCPost/HTTPQuote` para novo código (exceto workstation+WebAgent ou PATCH, que FWRest não suporta). Secrets de `GetMV()`, nunca hardcode.
- **Sem lixo/fontes órfãos** — quando um fonte deixar de ser necessário, ou quando código de um PE for incorporado/migrado para outro fonte existente, **excluir o fonte antigo** (e remover gatilhos SX7/configs que apontem para ele). Nunca deixar arquivo morto "por segurança". Se houver risco de perder histórico, registrar no changelog/commit antes da exclusão.

### MVC Pattern
`MenuDef()` → `ModelDef()` (FWFormModel) → `ViewDef()` (FWFormView) → `BrowseDef()`. Modelo 1 (única entidade) e Modelo 3 (mestre-detate).

### Modern TLPP (preferido p/ códigos novos)
- `using namespace` obrigatório no topo de `.tlpp`; nunca namespace fully qualified no call.
- Tipagem estática, Try-Catch, REST por anotação (`@Get`, `@Post`, `@Put`, `@Patch`, `@Delete`).

---

## SonarQube AdvPL/TLPP Compliance

Todas as atividades de implementação, refatoração, review e otimização **devem** atender às regras SonarQube para AdvPL/TLPP (sem excessões).

- **Geração**: sem violação CRITICAL/MAJOR; INFO é obrigatória (CA2050 SQL Injection, CA2051, CA2052).
- **Review**: apontar explicitamente violação com o ID da regra (ex.: `CA2050 — SQL Injection`).
- **Refactor**: corrigir violações das linhas tocadas; nunca introduzir novas.
- **Otimização**: respeitar regras de performance (G2); não usar API proibida.

> **Referência completa (G1–G5)**: `CONFIG/references_sonarqube-rules-reference.md` — leia antes de gerar/revisar código.

---

## API Symbol Validation (Obrigatório)

Antes de gerar/migrar/refatorar código, validar que **todo** símbolo externo (class, method, function, namespace, parâmetros) existe de fato no framework/versão alvo.

- Fonte de verdade para validar (em ordem): código existente → skill files (o corpo/templates/exemplos de `SKILLS/**/SKILL.md` e `SKILLS/**/references/**`) → `AGENTS.md`/`CLAUDE.md` → TDN (tdn.totvs.com) → web confiável → **perguntar ao usuário** (nunca inventar).
- Símbolos NÃO encontrados na doc, codebase ou skill → NÃO inventar; documentar o gap.
- Validar também a **assinatura completa** (ordem de parâmetros, tipos, retorno) e o **contexto de execução** (ciclo de vida).
- Migração: validar cada símbolo no framework **alvo**, nunca assumir portagem com mesmo nome.

---

## Completeness Verification (Obrigatório)

Depois de qualquer **geração, migração ou refactor**, antes de considerar concluído:

1. **Gap analysis**: comparar item-a-item features originais vs migradas — lista explícita: ✅ migrado, ⚠️ não-migrável (justificativa da limitação framework), 🔄 preservado na layer legado.
2. **Nunca omitir comportamento em silêncio**. "Esqueci" ou "assumi que o framework cuida" NÃO são justificativas.
3. **Lógica condicional deve ser replicada**: `VerifyAccess`, `MPUserHasAccess`, `SuperGetMV`, `FWModeAccess`, `FwAliasInDic`, `nModulo`, `cPaisLoc`, `FindFunction` — nada disso é automático, precisa estar explícito.
4. Apresentar o gap analysis ao usuário antes de declarar o fim da tarefa.

---

## Tests

- **TIR** (e2e Webapp/SmartClient): Python `unittest.TestCase` com `setUpClass()`, `test_CTNNN()`, `tearDownClass()`. Scripts deste repo ficam em `CONFIG/tir/`. Gerar usando `tir-test-generator`.
- **Testes unitários**: ProBat para TLPP (`probat-testing`).
- Verificação de dados para código: validar via **APSDU** antes de hardcoding (ver `CONFIG/AGENTS.md`) — nunca assumir campo/valor inexistente.

---

## Skills disponíveis

- Catálogo completo: `DOCUMENTACAO/CLAUDE-SKILLS-REF.md`, `CONFIG/references_advpl-tlpp-skills-reference.md` e `skills-registry.json`.
- Skills com contexto: catálogo (resumo):
  | Categoria | Skills |
  |---|---|
  | SDD | `advpl-tlpp-sdd` |
  | Migração | `advpl-to-tlpp-migration` |
  | Qualidade | `code-review`, `advpl-code-review`, `sql-code-review`, `anon...` |
  | Testes | `tir-test-generator`, `tir-setup-and-best-practices` |
  | Compilação | `advpl-tlpp-compile`, `advpl-tds-ls` |
  | Documentação/Plano | `documentation-writer`, `context-concept`, `create-implementation-plan`, `data-dictionary-lookup`, `entry-point-designer`, `mvc-generator`, `query-builder`, `fwrest-client-generator`, `tlpp-rest-endpoint-generator` |
  | Encoding | `utf8-to-cp1252-conversion` |
  | Vária | `changelog-patterns`, `sx-configuration`, `sql-safe`, `sql-optimization`, `advpl-tela-consulta`, `advpl-debugging`, `advpl-protheus`, `advpl-empresa` |

### SmartView — Objetos de Negocio (IntegratedProvider)
Ao criar/**alterar** um ON do SmartView (**qualquer** mudança: campo, parâmetro, filtro, lookup, página/consist), consultar OBRIGATORIAMENTE `SKILLS/advpl-code-generation/patterns-smartview-integratedprovider.md` antes de editar. Essências:
- Campo novo: `addProperty(...)` no `getSchema()` (via existente, sem alterar `self:oSchema`) e incluir na `SELECT`/`#QueryFields#` do `getData()`. Campo fora do `schema` **o SmartView ignora**.
- Schema dinâmico: `getSchema()` montado do SX3 (`X3_TIPO` → tipo de schema) e `getData()` com `#QueryFields#`/`#QueryWhere#`.
- `addProperty(...)`: `cRealName` = nome real do campo (após. qualificado `SB1.B1_DESC` em JOINs).
- **Métodos**: manter as assinaturas públicas dos métodos do `IntegratedProvider` preservadas; para ampliar comportamento, criar subclasse de `IntegratedProvider`.
- **Após compilar ON, reiniciar o AppServer** para o SmartView enxergar via REST.

---

## Fallback Escalation Chain

1. Codebase — código e convenções no projeto (ex.: `FONTES/`)
   ↓ não achou
2. Skill references (`SKILLS/**/references/*.md`, `SKILLS/**/SKILL.md`) e `CONFIG/references_*.md`
   ↓
3. `AGENTS.md`/`CLAUDE.md`/`CONFIG/AGENTS.md`
   ↓
4. TDN oficial (tdn.totvs.com) + fontes web confiáveis
   ↓
5. Perguntar ao usuário — nunca inventar/gorjejar


