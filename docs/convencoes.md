# Convenções de Código — AdvPL/TLPP

> **Consulte este arquivo quando** for gerar, refatorar ou revisar código AdvPL/TLPP (tipagem, includes, classes, padrões SonarQube, MSExecAuto, MVC, SmartView). Não é contexto fixo — leia sob demanda.

## Naming — Notação húngara

- **Notação húngara obrigatória**: `c` (char), `n` (num), `d` (date), `l` (logical), `a` (array), `o` (object), `b` (codeblock), `x` (variadic/variant), `j` (json).
- **Arquivos fonte**: prefixo módulo (4 letras) + número (3 dígitos) — ex.: `MATA010`, `FINA138`; fontes Z* e VO* não seguem.
- **Campos de tabela**: prefixo tabela (2-3 letras) + `_` + nome — ex.: `A1_COD`, `C7_QUANT`.
- **Convenções deste repo**: `MT*`/`MTA*` = PE de rotinas MATA*, `Z*` = custom, `CAD*` = cadastro, `V*`/`VO*` = Vortice.

## Type System

### AdvPL Types
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

Não existem `String`, `Number` nem `Boolean` — use os tipos da tabela.

### TLPP — declaração de variável

```tlpp
// CERTO: tipo antes da atribuição
Local cName  := "" as Character
Local nTotal := 0  as Numeric
Local oModel as Object          // sem atribuição — válido
// ERRADO: 'as' antes da atribuição — não compila
Local cX as Character := ""     // não compila
```

### Ordem obrigatória em toda função/método

```advpl
User Function MyFunction()      // 1. cabeçalho
    Local  cVar := ""           // 2. todos os Local
    Private cPriv := ""         // 3. todos os Private (logo após)
    // ... código               // 4. lógica
Return xValue                   // 5. Return
```

Nunca declarar `Local`/`Private` no meio do fluxo (dentro de `If`, `For`, após chamada).

### Classes (AdvPL/TLPP — estrutura em duas partes)

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
- `static method` — na declaração, apenas `()` vazio (sem parâmetros); o **tipo de retorno deve ser idêntico ao da implementação** (divergência só falha na compilação real, o LSP não acusa). Parâmetros vão só na implementação.

> Fonte: TDN TOTVS (TDN pageId 821588162 / 334341656 / 822220426).

## Include Files

- Padrão moderno: `#include "totvs.ch"`.
- TLPP: `#include "tlpp-core.th"` **primeiro**, depois `totvs.ch`.
- **Regra de precedência**: códigos novos e refactors usam `#include "totvs.ch"`. PE/fontes legados que já usam `#include "Protheus.ch"` **mantêm** o include atual (não migrar por caça ao estilo; migrar apenas se o arquivo for tocado em refactor). Ex.: `MT120TFR.PRW`, `MT120OK.PRW` continuam `Protheus.ch`.
- NÃO use includes obsoletos em código novo: `protheus.ch`, `Ap5Mail.ch`, `ApWizard.ch`, `FileIO.ch`, `Font.ch`, `ParmType.ch`, `RWMake.ch` (substituídos por apis modernas em `totvs.ch`).

## Mandatory Standards (SonarQube + TOTVS)

- SQL: sempre `D_E_L_E_T_ = ' '` (soft-delete), filtro por filial `XX_FILIAL = xFilial('XXX')`, `FWExecStatement`/`ChangeQuery()` (anti-injection), `RetSqlName()` na tabela física.
- **Lock**: `%nolock%` é proibido (em AdvPL é expandido pelo TOPConnect, mas neste build vira `WITH (%%)` — SQL inválido; fora do AdvPL nunca é expandido). Em leitura/relatório use o hint literal `WITH (NOLOCK)`, reinjetado depois do `ChangeQuery()` porque ele remove a dica — padrão em `FONTES/CADSZ3.PRW`. Nunca em leitura que alimenta gravação ou cálculo financeiro.
- Nunca chamar `GetMV()`, `SuperGetMV()`, `ExistBlock()`, `Type()`, `Pergunte()` dentro de loop.
- **`Function` proibido** em customização — use `User Function` (público) ou `Static Function` (interno ao arquivo). Escopo `Function` é reservado ao produto.
- **Entry Points**: nome NÃO tem prefixo `U_` (`User Function MT410INC()`, nunca `U_MT410INC()`). Nome do arquivo = nome do PE, maiúsculo.
- **Encoding**: arquivos `.prw/.prg/.prx/.tlpp/.ch/.aph` em **CP-1252** — nunca UTF-8.
- **Destruição**: use `Destroy()` da própria class; nunca `FwFreeObj()`/`FreeObj()`/`FwFreeArray()` se a class tem `Destroy()`.
- **`IIF` proibido** — use `If/Else/EndIf` explícito (SonarQube CA4000).
- **Sem UI dentro de transação** (`MsgAlert`, `MsgYesNo`, `Aviso`, `Help`, `Pergunte`...) — deadlock multi-user (CA1002).
- **No ISAM/`MSCREATE`/`DBCREATE`/`CRIATRAB`** — use `FWTemporaryTable` (CA1000).
- **Sem `ConOut()`/`OutErr()`/`?`** — use `FWLogMsg()` (CA1004). Assinatura: `FWLogMsg(cLevel, cGroup, cCategory, cSource, cDetail, cLogId, cMessage)` — ex.: `FWLogMsg("ERROR", , "SUPR", FunName(), , "01", cMsg, 0, 0, {})`.
- **Nunca use variável `cFilial` direta** (reservada) — use `cFilAux`, ou `xFilial('XXX')`/`FWxFilial('XXX')`.
- **REST client externo** — sempre via `FWRest`. Proibido `HTTPCGet/HTTPCPost/HTTPQuote` para novo código (exceto workstation+WebAgent ou PATCH, que FWRest não suporta). Secrets via `GetMV()`, nunca hardcode.
- **Sem lixo/fontes órfãos** — quando um fonte deixar de ser necessário, ou quando código de um PE for incorporado/migrado para outro fonte existente, **exclua o fonte antigo** (e remova gatilhos SX7/configs que apontem para ele). Nunca deixar arquivo morto "por segurança". Se houver risco de perder histórico, registrar no changelog/commit antes da exclusão.

## MSExecAuto (tabelas core) — checklist obrigatório

```advpl
Private lMsErroAuto    := .F.   // flag de erro da rotina automática
Private lMsHelpAuto    := .T.   // suprime janelas de Help
Private lAutoErrNoFile := .T.   // erros em memória (não em arquivo)

MSExecAuto({|x, y, z| MATA110(x, y, z)}, aCabec, aItens, 3)
If lMsErroAuto
    cErro := MostraErro(.F.)      // .F. = retorna string, não exibe dialog
    // alternativa p/ REST/job: GetAutoGRLog()
EndIf
```

- Operações: `3` = inclusão, `4` = alteração, `5` = exclusão.
- Sempre `GetArea()`/`RestArea()` em volta de trecho que dependa de posicionamento de alias.
- Em modelo MVC use `FWMVCRotAuto(oModel, "ROTINA", MODEL_OPERATION_INSERT, aParams)`.
- `Private` só para controle de ExecAuto e controles de tela (`oDlg`, `aHeader`, `aCols`); `Public` só para compartilhar dados entre PEs.
- Data vazia: `CtoD("  /  /  ")` — nunca `NULL` via SQL. Validar `Eof()`/`Bof()` antes de ler registro posicionado; fechar alias temporário com `(cAls)->(DbCloseArea())` após verificar `Select(cAls) > 0`.

## MVC Pattern

`MenuDef()` → `ModelDef()` (FWFormModel) → `ViewDef()` (FWFormView) → `BrowseDef()`. Modelo 1 (única entidade) e Modelo 3 (mestre-detalhe).

## Modern TLPP (preferido p/ códigos novos)

- `using namespace` obrigatório no topo de `.tlpp`; nunca namespace fully qualified no call.
- Tipagem estática, Try-Catch, REST por anotação (`@Get`, `@Post`, `@Put`, `@Patch`, `@Delete`).

## SonarQube AdvPL/TLPP Compliance

Todas as atividades de implementação, refatoração, review e otimização **devem** atender às regras SonarQube para AdvPL/TLPP (sem exceções).

- **Geração**: sem violação CRITICAL/MAJOR; INFO é obrigatória (CA2050 SQL Injection, CA2051, CA2052).
- **Review**: apontar explicitamente violação com o ID da regra (ex.: `CA2050 — SQL Injection`).
- **Refactor**: corrigir violações das linhas tocadas; nunca introduzir novas.
- **Otimização**: respeitar regras de performance (G2); não usar API proibida.

> **Referência completa (G1–G5)**: `CONFIG/references_sonarqube-rules-reference.md` e `skills/advpl-tlpp/references/sonarqube-rules-reference.md` — leia antes de gerar/revisar código.

## API Symbol Validation (Obrigatório)

Antes de gerar/migrar/refatorar código, validar que **todo** símbolo externo (class, method, function, namespace, parâmetros) existe de fato no framework/versão alvo.

- Fonte de verdade para validar (em ordem): código existente → skill files (corpo/templates/exemplos de `skills/**/SKILL.md` e `skills/**/references/**`) → `AGENTS.md`/`CLAUDE.md` → TDN (tdn.totvs.com) → web confiável → **perguntar ao usuário** (nunca inventar).
- Símbolos NÃO encontrados na doc, codebase ou skill → NÃO inventar; documentar o gap.
- Validar também a **assinatura completa** (ordem de parâmetros, tipos, retorno) e o **contexto de execução** (ciclo de vida).
- Migração: validar cada símbolo no framework **alvo**, nunca assumir portagem com mesmo nome.

## Completeness Verification (Obrigatório)

Depois de qualquer **geração, migração ou refactor**, antes de considerar concluído:

1. **Gap analysis**: comparar item-a-item features originais vs migradas — lista explícita: ✅ migrado, ⚠️ não-migrável (justificativa da limitação framework), 🔄 preservado na layer legado.
2. **Nunca omitir comportamento em silêncio**. "Esqueci" ou "assumi que o framework cuida" NÃO são justificativas.
3. **Lógica condicional deve ser replicada**: `VerifyAccess`, `MPUserHasAccess`, `SuperGetMV`, `FWModeAccess`, `FwAliasInDic`, `nModulo`, `cPaisLoc`, `FindFunction` — nada disso é automático, precisa estar explícito.
4. Apresentar o gap analysis ao usuário antes de declarar o fim da tarefa.

## ProtheusDOC Documentation

Todo código novo deve incluir bloco `/*/{Protheus.doc}` com no mínimo: `@type`, `@author`, `@since`, `@param` (se houver), `@return` (se houver). Ver skill `documentation-writer` para referência completa. Mantém padrão Vortice existente — não remove checklist de qualidade.

## SmartView — Objetos de Negócio (IntegratedProvider)

Ao criar/**alterar** um ON do SmartView (**qualquer** mudança: campo, parâmetro, filtro, lookup, página/consist), consultar OBRIGATORIAMENTE a skill `skills/advpl-tlpp` correspondente antes de editar. Essências:

- Campo novo: `addProperty(...)` no `getSchema()` (via existente, sem alterar `self:oSchema`) e incluir na `SELECT`/`#QueryFields#` do `getData()`. Campo fora do `schema` o SmartView ignora.
- Schema dinâmico: `getSchema()` montado do SX3 (`X3_TIPO` → tipo de schema) e `getData()` com `#QueryFields#`/`#QueryWhere#`.
- `addProperty(...)`: `cRealName` = nome real do campo (após qualificado `SB1.B1_DESC` em JOINs).
- **Métodos**: manter as assinaturas públicas dos métodos do `IntegratedProvider` preservadas; para ampliar comportamento, criar subclasse de `IntegratedProvider`.
- **Após compilar ON, reiniciar o AppServer** para o SmartView enxergar via REST.
