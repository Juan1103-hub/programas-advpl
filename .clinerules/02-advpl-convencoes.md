---
paths:
  - "FONTES/**"
  - "**/*.prw"
  - "**/*.tlpp"
  - "**/*.prg"
  - "**/*.ch"
---

# 02 - Convencoes AdvPL/TLPP

## Nomenclatura

- **Notacao hungara obrigatoria**: `c`=char, `n`=num, `d`=date, `l`=logico, `a`=array,
  `o`=objeto, `b`=codeblock, `x`=variante, `j`=json.
- Campos de tabela: prefixo + `_` + nome (ex.: `A1_COD`, `C7_QUANT`).
- Arquivos novos `.prw` em **maiusculo**. Legados em minusculo/misto nao renomear sem necessidade.

## Estrutura de funcao (ordem obrigatoria)

1. Cabecalho (`User Function` / `Static Function`)
2. Todos os `Local`
3. Todos os `Private` (logo apos)
4. Logica
5. `Return`

Nunca declarar `Local`/`Private` no meio do fluxo. **`Function` proibido** em customizacao
(reservado ao produto) — usar `User Function` (publico) ou `Static Function` (interno).

## Entry Points

- Nome **sem** prefixo `U_` (`User Function MT410INC()`), nome do arquivo = nome do PE
  (ex.: `MT110TOK.PRW`, `MTA110OK.PRW`).
- Classes: declaracao com modificador (`public`/`private`), implementacao **sem** modificador;
  heranca usa **`from`**; construtor filha chama `_Super:new()`.

## Includes e encoding

- Codigo novo: `#include "totvs.ch"`. TLPP: `#include "tlpp-core.th"` primeiro, depois `totvs.ch`.
- Legado com `Protheus.ch`: manter, nao migrar por estilo.
- Fontes `.prw/.tlpp` em **CP-1252** (IA gera UTF-8 -> converter pela skill
  `utf8-to-cp1252-conversion` antes de compilar). Fluxo: converter -> compilar -> review.

## Proibicoes (SonarQube + TOTVS)

- `IIF` proibido — usar `If/Else/EndIf` (CA4000).
- Sem UI dentro de transacao (`MsgAlert`, `Aviso`, `Pergunte`...) — deadlock (CA1002).
- Sem `ConOut()`/`?` — usar `FWLogMsg()` (CA1004).
- Sem `MSCREATE`/`DBCREATE`/`CRIATRAB` — usar `FWTemporaryTable` (CA1000).
- Nunca usar variavel `cFilial` direta — usar `cFilAux` ou `xFilial()`/`FWxFilial()`.
- REST externo sempre via `FWRest` (proibido `HTTPCGet/HTTPCPost` em codigo novo).
- `Destroy()` da propria classe; nunca `FwFetchObj()`/`FreeObj()` se a classe tem `Destroy()`.
- Sem fontes orfaos/mortos "por seguranca" — excluir e registrar no changelog/commit.
