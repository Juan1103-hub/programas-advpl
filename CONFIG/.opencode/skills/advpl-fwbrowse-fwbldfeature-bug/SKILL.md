---
name: advpl-fwbrowse-fwbldfeature-bug
description: Use when encountering Protheus runtime error `invalid macro source (SSYacc0105e)` originating from `FWBUILDFEATURE(PROTHEUSFUNCTIONMVC.PRX)`, especially with picture `@!` in the code-block `({|a,b,c| FWInitCpo(a,b,c),xRet:=(@!),FWCloseCpo(...),xRet })`. Triggers on FWMBrowse/MVC open errors, custom SX3 tables, or any FWBUILDFEATURE macro error.
---

# AdvPL FWBUILDFEATURE Bug (SSYacc0105e) — X3_PICTVAR

## Overview

O erro `SSYacc0105e: Error token failed, no valid token` originado em `FWBUILDFEATURE` é causado pelo conteúdo de campos do SX3 (`X3_PICTVAR`, `X3_WHEN`, `X3_INIBRW` ou `X3_RELACAO`) que o framework injeta em um code-block AdvPL. Quando o conteúdo começa com `@`, o macro-parser AdvPL interpreta `@(...)` como macro-referência `&(...)`, gerando o token inválido.

**Causa-raiz oficial TOTVS (Central #4404702402455, SIGAPCP MATA098):**
> "Há uma `!` no campo `X3_PICTVAR - Form. Variável`. Para que o erro não ocorra é necessário **retirar a `!`** do campo `X3_PICTVAR`."

## Sintomas (Triggers)

- `THREAD ERROR ... invalid macro source (SSYacc0105e: Error token failed, no valid token)`
- Stack trace passa por `FWBUILDFEATURE(PROTHEUSFUNCTIONMVC.PRX)` linha ~5413
- Chamado por: `FORMVIEWFIELD` → `FORMSTRUTABLE` → `FWFORMSTRUCT` → `FWMBROWSE:LOADCOLUMNS` → `FWMBROWSE:ACTIVATE`
- Ocorre **ao abrir o browse** (não em CRUD)
- Acontece em **tabelas customizadas Z*** recém-criadas (não em tabelas padrão Protheus)
- O conteúdo problemático aparece como `xRet:=(@!)` ou `xRet:=(!)` no code-block

## Causa Raiz

O `FWBUILDFEATURE` monta dinamicamente:

```advpl
{|a,b,c| FWInitCpo(a,b,c), xRet:=(<CONTEUDO_SX3>), FWCloseCpo(a,b,c,.T.), xRet }
```

`<CONTEUDO_SX3>` vem de um dos campos do SX3:
- `X3_PICTVAR` (Form. Variável) — **caso mais comum**
- `X3_WHEN`
- `X3_INIBRW` (Inicializador Browser)
- `X3_RELACAO`

Quando o conteúdo é `@!`, o code-block vira:

```advpl
{|a,b,c| FWInitCpo(a,b,c), xRet:=(@!), FWCloseCpo(a,b,c,.T.), xRet }
```

O AdvPL macro-parser interpreta `@(...)` como `&(...)` (macro-referência), e `(!)` é token inválido.

## Diagnóstico (queries SQL)

```sql
-- 1. Listar campos com picture em X3_PICTVAR (suspeitos principais)
SELECT X3_CAMPO, X3_PICTVAR, X3_PICTURE
FROM SX3010
WHERE X3_ARQUIVO = 'SUA_TABELA'
  AND X3_PICTVAR LIKE '@%'

-- 2. Listar X3_WHEN malformados
SELECT X3_CAMPO, X3_WHEN
FROM SX3010
WHERE X3_ARQUIVO = 'SUA_TABELA'
  AND X3_WHEN IS NOT NULL
  AND X3_WHEN <> ' '

-- 3. Listar X3_INIBRW problemáticos
SELECT X3_CAMPO, X3_INIBRW
FROM SX3010
WHERE X3_ARQUIVO = 'SUA_TABELA'
  AND X3_INIBRW IS NOT NULL
  AND X3_INIBRW <> ' '

-- 4. Listar X3_RELACAO problemáticos
SELECT X3_CAMPO, X3_RELACAO
FROM SX3010
WHERE X3_ARQUIVO = 'SUA_TABELA'
  AND X3_RELACAO IS NOT NULL
  AND X3_RELACAO <> ' '
```

## Soluções (em ordem de preferência)

### Solução A — Limpar `X3_PICTVAR` (RECOMENDADA — oficial TOTVS)

**Por Configurador** (manual, validado):
1. Configurador → Base de Dados → Dicionário → Dicionário de Dados
2. Filtre por `X3_ARQUIVO = SUA_TABELA`
3. Para cada campo com `X3_PICTVAR = @!`: limpar o campo (deixar vazio)
4. Salvar

**Por SQL direto** (se tiver APS, NÃO APSDU — APSDU não suporta UPDATE):

```sql
UPDATE SX3010
SET X3_PICTVAR = ' '
WHERE X3_ARQUIVO = 'SUA_TABELA'
  AND X3_PICTVAR LIKE '@%'
```

### Solução B — Limpar profile do usuário

Quando o erro ocorre intermitentemente na abertura da rotina, TOTVS recomenda reinicializar o profile do usuário (TOTVS Central #360025097012):
- Configurador → Usuários → Profile → Reinicializar

### Solução C — Substituir `FWMBrowse` por `mBrowse` (workaround)

**Quando aplicar**: Se a Solução A não for viável (ambiente compartilhado, SX3 intocável, etc).

`mBrowse` NÃO usa `FWFORMSTRUCT`/`FWBUILDFEATURE` → bug desaparece.

**Padrão de substituição** (do `CADSZ3.PRW` canônico do workspace Vortice):

```advpl
// ANTES (FWMBrowse com bug FWBUILDFEATURE):
oBrowse := FWMBrowse():New()
oBrowse:SetAlias("ZD1")
oBrowse:Activate()

// DEPOIS (mBrowse, padrão CADSZ3):
Private cCadastro := "Titulo"
Private cString   := "ZD1"
Private aRotina   := { ;
    {"Pesquisar" , "AxPesqui"     , 0, 1}, ;
    {"Visualizar", "U_VISUALIZAR" , 0, 2}, ;
    {"Incluir"   , "U_INCLUIR"    , 0, 3}, ;
    {"Alterar"   , "U_ALTERAR"    , 0, 4}, ;
    {"Excluir"   , "U_EXCLUIR"    , 0, 5} }

mBrowse(6, 1, 22, 75, "ZD1")
```

E criar wrappers `User Function` para cada ação do aRotina:

```advpl
User Function U_INCLUIR()
    // Validar posicao: If (cString)->(Eof()) .Or. (cString)->(Bof())
    // Chamar tela/rotina de inclusao
Return
```

### Solução D — `SetDataQuery` (NÃO recomendado neste caso)

`SetDataQuery(.T.)` + `SetQuery()` não resolve — `LOADCOLUMNS` ainda chama `FWFORMSTRUCT` antes de popular dados. A construção do code-block é **anterior** à carga.

## Por que tabelas padrão Protheus (SC1, SA1) funcionam com `@!`

Tabelas padrão Protheus têm o campo `X3_PICTVAR` configurado consistentemente pelo time da TOTVS. O `@!` em tabelas padrão fica **apenas no `X3_PICTURE`** (Formato), nunca no `X3_PICTVAR` (Form. Variável).

Tabelas Z* recém-criadas (via Configurador manual) frequentemente herdam `@!` no `X3_PICTVAR` por engano, especialmente quando o usuário copia campos de outras tabelas.

## Causa Relacionada: `WITH (%lock%)` em FWExecStatement / TCQuery

**Sintoma** (distinto do FWBUILDFEATURE):
```
: Error : 102 (37000) (RC=-1) - [Microsoft][ODBC Driver 13 for SQL Server][SQL Server]Incorrect syntax near '%'.
...
SELECT ... FROM ZD1010 WITH (%%) WHERE ...
```

**Causa**: O macro `%nolock%` ou `%lock%` no `WITH (...)` é processado pelo TOPConnect e substituído. No build 24.1.1.3, o `%nolock%` é resolvido para `%` literal (vazio + `%`), gerando `WITH (%%)` que é SQL inválido.

**Solução**: **NUNCA use** `WITH (%lock%)` ou `WITH (%nolock%)` em AdvPL/TLPP. Remova o hint e use a sintaxe padrão.

```advpl
// ERRADO - causa "Incorrect syntax near '%'"
cSQL := "SELECT ... FROM " + RetSqlName("ZD1") + " WITH (%nolock%) WHERE ..."

// CORRETO - sem hint
cSQL := "SELECT ... FROM " + RetSqlName("ZD1") + " WHERE ..."
```

**Quando aplicou**: 02/07/2026 no ZLANCDIE.PRW (`FProximoSequencial`).

**RPO desatualizado**: Se o erro aparece mesmo após corrigir a fonte, **o RPO precisa ser recompilado** — o AppServer ainda está executando a versão antiga que tinha `WITH (%nolock%)`.

## Workarounds que NÃO funcionam

| Tentativa | Por que falha |
|-----------|---------------|
| Trocar `SetDataTable(.T.)` por `SetDataTable(.F.)` | `LOADCOLUMNS` é sempre chamado, independente do modo |
| Trocar `FWMBrowse` por `FWFormBrowse` | Também usa `FWBUILDFEATURE` |
| Adicionar `SetColumns([])` | Apenas limpa colunas custom, não impede `LOADCOLUMNS` |
| Patch binário do `PROTHEUSFUNCTIONMVC.PRX` | TOTVS não publicou patch; código é fechado |
| Trocar build do AppServer | Build `7.00.240223P-20260211` é o mais recente; mesmo `7.00.240223P-20241010` tem o bug |

## Links Oficiais (Central TOTVS)

| Artigo | Causa | Solução |
|--------|-------|---------|
| [Central #4404702402455 (SIGAPCP)](https://centraldeatendimento.totvs.com/hc/pt-br/articles/4404702402455) | `X3_PICTVAR` com `!` | Retirar `!` do `X3_PICTVAR` |
| [Central #360044238274 (SIGACOM)](https://centraldeatendimento.totvs.com/hc/pt-br/articles/360044238274) | `X3_WHEN` malformado | Corrigir `X3_WHEN` (ex: `..F` → `.F.`) |
| [Central #360026815053 (SIGAGCT)](https://centraldeatendimento.totvs.com/hc/pt-br/articles/360026815053) | `X3_INIBRW` malformado (via FWMBrowse) | Corrigir `Posicione()` no `X3_INIBRW` |
| [Central #115015486348 (SIGACTB)](https://centraldeatendimento.totvs.com/hc/pt-br/articles/115015486348) | `X3_WHEN` com `If()` malformado | Reescrever expressão |
| [Central #360025544331 (genérico)](https://centraldeatendimento.totvs.com/hc/pt-br/articles/360025544331) | Genérico `X3_PICTVAR/WHEN/INIBRW/RELACAO` | Validar aspas, parênteses, chaves |

**Fórum TOTVS**:
- [Thread #19677 (build 7.00.240223P)](https://forum.totvs.io/t/invalid-macro-source-ssyacc0105e-error-token-failed-no-valid-token/19677) — confirma bug no mesmo build

## Caso Real (workspace Vortice — 02/07/2026)

**Sintoma**: `ZLANCDIE.PRW` (tabela custom ZD1) quebrava ao abrir com `SSYacc0105e`.

**Causa**: Campos da ZD1 tinham `X3_PICTVAR = @!` (herdado de cópia de outros campos).

**Solução aplicada**: Refatorar `FBrowse()` de `FWMBrowse` para `mBrowse` (padrão `CADSZ3.PRW` do workspace). Bug do framework contornado.

**Lição**: ao criar tabelas custom Z* no Configurador, **sempre validar que `X3_PICTVAR` está vazio** para campos que não precisam de formatação variável complexa.

## Quick Reference

| Sintoma | Ação Imediata |
|---------|---------------|
| `SSYacc0105e` em `FWBUILDFEATURE` + `xRet:=(@!)` | Rodar query 1 acima; limpar `X3_PICTVAR` |
| `SSYacc0105e` em `FWBUILDFEATURE` + `lRet:=(..F)` | Rodar query 2 acima; corrigir `X3_WHEN` |
| `SSYacc0105e` em `FWBROWSE:GETPOSICIONE` | Rodar query 3; corrigir `X3_INIBRW` (geralmente `Posicione` errado) |
| Erro intermitente só na abertura | Tentar Solução B (limpar profile) |
| Tabela custom intocável (ambiente compartilhado) | Usar Solução C (mBrowse) |

## Prevenção (criação de novas tabelas)

Ao criar campos no SX3 via Configurador:

1. **X3_PICTURE**: picture principal (ex: `@!`, `@D`, `@E 99,999.99`)
2. **X3_PICTVAR**: **DEIXAR VAZIO** a menos que tenha formatação variável complexa (ex: picture que muda por contexto)
3. **X3_WHEN**: expressão AdvPL válida, balanceada (parênteses, aspas)
4. **X3_INIBRW**: `Posicione()` correto ou vazio
5. **X3_RELACAO**: expressão de inicialização ou vazio

**Regra de ouro**: se copiar de campo existente, **sempre revisar `X3_PICTVAR`** após colar.
