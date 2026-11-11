# Evidencias — o padrao medido em `FONTES/`

> Medicao de **11/11/2026** sobre os fontes de `FONTES/`: 79 arquivos
> (`.prw`, `.PRW`, `.tlpp`), 57.021 linhas.
> Regerar: `python skills/vortice/advpl-padrao-fonte/scripts/auditar_padrao.py FONTES --json`
> + contagem por regex (ver §Como medir). Numero que nao bate com o codigo atual
> significa que o codigo mudou — o codigo vence.

## 1. O que e consenso (pode tratar como regra)

| Padrao | Medida | Exemplo verificado |
| --- | --- | --- |
| Nome do arquivo = funcao principal | 72/79 | `MT110TOK.PRW:23`, `ZPOSITEM.PRW:27` |
| `Function` puro | **0** ocorrencias | — |
| `%nolock%` | **0** ocorrencias | — |
| Bloco `/*/{Protheus.doc}` | 536 blocos | `MT110TOK.PRW:3-21` |
| `User Function` / `Static Function` | 211 / 901 | `ZDIAG110.tlpp:25,115,150` |
| `GetArea()` / `RestArea()` | 192 / 327 | `MT110TOK.PRW:24,138` |
| `xFilial()` | 603 usos | `ZPOSITEM.PRW:57` |
| SQL TopConnect (`TCGenQry` + `DbUseArea`) | 29/79 arquivos | `CADSZ3.PRW:586-600` |
| `ChangeQuery()` | 83 usos | `CADSZ3.PRW:593` |
| Hint `WITH (NOLOCK)` reinjetado | receita de 2 `StrTran` apos `ChangeQuery` | `CADSZ3.PRW:3948-3950`, `ZMMA01.PRW:474-475` |
| Separador `//---` antes do Protheus.doc | 25/79 | `CADSOLIC.PRW:4`, `MT110TOK.PRW` |
| `#Define CRLF Chr(13)+Chr(10)` | 15/79 | `ZPOSITEM.PRW:4` |
| `Local` com `:=` alinhado | maioria dos fontes novos | `MT110TOK.PRW:24-41` |
| `RestArea` no return antecipado (LIFO) | `MT110TOK.PRW:50-51` | o exit final (`:138-139`) esta fora da ordem — nao copie |
| `Private` de tela depois do codigo | `CADSOLIC.PRW:45-63`, `CADPOSIC.PRW:31-41` | excecao legitima ao "tudo no topo" |
| Mensagens em portugues, caixa alta, titulo curto | `MT110TOK.PRW:120-137`, `ZANALBX.PRW:86-92` | — |
| `ParamBox` + `RestArea` no cancelamento | 16/79 | `ZANALBX.PRW:58-66` |
| `mBrowse` com `aRotina`/`aCores` | 8/79 | `CADSOLIC.PRW:45-72` |

## 2. O que e divida de legado (nao replicar)

| Divida | Medida | Onde |
| --- | --- | --- |
| `IIF()` — CA4000 | 789 usos em 22 arquivos | `CADSZ3.PRW:599`, `CADFORN.PRW:182` |
| `ConOut()`/`OutErr()`/`?` — CA1004 | 56 usos em 10 arquivos | `MT100TOK.PRW:29`, `NFEPREVTS.PRW:39` |
| `FWLogMsg()` (o alvo) | 4 usos | `SC7TREP.tlpp:59` |
| `Protheus.ch` (include antigo) | 60 arquivos vs 22 em `totvs.ch` | `CADSOLIC.PRW:1` |
| Cobertura de Protheus.doc | 536 blocos / 1.112 declaracoes ≈ **48%** | `CADFORN.PRW:942-952` (3 sem doc) |
| `Local` no meio do fluxo | 128 em `nfesefaz.prw`, 33 em `CADSZ3.PRW`, 26 em `MTA094RO.PRW` | `nfesefaz.prw:7914` |
| `RecLock` | 56 usos | tabelas Z* — legitimo |
| `MSExecAuto` | 5 usos | subutilizado: gravacao core deveria passar por aqui |
| Indentacao com TAB | 9 arquivos | `IMPSLDINI.PRW:86`, `CADSZ3.v2.prw:329` |
| `SELECT *` | 5 arquivos | `ZSLDEST.PRW:1423`, `ZZ3NORM.prw:14` |

## 3. Defeitos encontrados na medicao (corrigir, nao copiar)

1. **4 fontes em UTF-8** (o RPO corrompe acento): `FFZZ4A2.PRW`, `M020EXC.PRW`,
   `VLDNOMEFORN.prw`, `ZANALPRC.PRW`. Converter com `utf8-to-cp1252-conversion`.
2. **`GetArea()` sem `RestArea()`** em `nfesefaz.prw:11674` (5 GetArea / 3 RestArea).
3. **Sem include de Protheus**: `AVALCOT.PRW`, `MT150GET.prw`, `MTA131C8.PRW`
   (nenhum include) e `VOGSB101.prw` (so `rwmake.ch`).
4. **UI dentro de `Begin Transaction`**: 5 `MsgAlert` em `AJUSTCUST.PRW`
   (`:266, 275, 291, 300, 307`) — risco de deadlock multi-usuario (CA1002).
5. **Nome do arquivo != funcao principal**: `CADSZ3.v2.prw` (`CADSZ3_V2`),
   `FAMAPRODV2.prw` (`FAMAPROD`), `SC7TREP.tlpp` (`SC7TPVal` — ha uma funcao
   `SC7TPVal` antes da classe), `TIDEV.PRW` (`AfterLogin`), `ZLOGCOL.prw` (`NextZZ3`),
   `ZPOSITEM.PRW` (`FFZC1ITM`), `nfesefaz.prw` (`XmlNfeSef`). Nos dois ultimos o
   nome do arquivo e que esta errado para o padrao "arquivo = PE".
6. **Arquivo morto em `FONTES/`**: `CADSZ3.PRW.bak` (52.937 bytes). Regra do repo:
   excluir e registrar no changelog, nunca deixar "por seguranca".

## 4. Como medir (reproduzir)

```powershell
# 1) violacoes estruturadas (ERRO/AVISO) de todos os fontes
python skills\vortice\advpl-padrao-fonte\scripts\auditar_padrao.py FONTES

# 2) contagem por padrao (exemplo: IIF)
Get-ChildItem FONTES -Include *.prw,*.PRW,*.tlpp -Recurse |
  Select-String -Pattern 'IIF\(' | Group-Object Filename |
  Measure-Object Count -Sum
```

Regras do auditor e o que cada codigo significa: ver `REGRAS` no inicio de
`scripts/auditar_padrao.py`. Perfil `--estrito` promove `DOC`, `TYPE`, `DECL` e
`ALGN` a ERRO — e o perfil para fonte **novo**; o perfil padrao audita legado
sem transformar divida antiga em bloqueio.

## 5. Fontes de referencia (os que passam no `--estrito`)

| Fonte | Papel |
| --- | --- |
| `FONTES/MT110TOK.PRW` | PE de validacao de grid — molde A |
| `FONTES/MA410MNU.PRW` | PE de menu — molde B |
| `FONTES/ZPOSITEM.PRW` | PE de gatilho SX7 com `M->` — molde C |
| `FONTES/CADSOLIC.PRW` | tela mBrowse — molde E |
| `FONTES/ZANALBX.PRW` | rotina com ParamBox — molde D |
| `FONTES/ZDIAG110.tlpp` | TLPP com Try/Catch e funcoes auxiliares |
| `FONTES/SC7TREP.tlpp` | classe TLPP + SmartView — molde F |
| `FONTES/CADSZ3.PRW` | SQL TopConnect canonico (`:586-600`) |
