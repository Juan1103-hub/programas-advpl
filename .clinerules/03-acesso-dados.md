---
paths:
  - "FONTES/**"
  - "**/*.prw"
  - "**/*.tlpp"
---

# 03 - Acesso a Dados e SQL Seguro

## Regras de acesso (CONFIG/AGENTS.md)

1. **`GetArea()` / `RestArea()`** obrigatorio em toda funcao que acessar alias.
2. **`xFilial("ALIAS")`** em todos os filtros por filial. Nunca hardcode.
3. **`RecLock` APENAS em tabelas `Z*`** (custom). Tabelas core
   (SC7, SC1, SC8, SB1, SA2, SD1...) usam **MSExecAuto**.
4. `Private` so p/ controle de ExecAuto e controles de tela; `Public` so p/ dados entre PEs.

## MSExecAuto — checklist obrigatorio

```advpl
Private lMsErroAuto    := .F.
Private lMsHelpAuto    := .T.
Private lAutoErrNoFile := .T.
MSExecAuto({|x, y, z| MATA110(x, y, z)}, aCabec, aItens, 3)
If lMsErroAuto
    cErro := MostraErro(.F.)
EndIf
```

- Operacoes: `3`=inclusao, `4`=alteracao, `5`=exclusao. MVC: `FWMVCRotAuto()`.
- Modelo MVC: `FWMVCRotAuto(oModel, "ROTINA", MODEL_OPERATION_INSERT, aParams)`.
- Data vazia: `CtoD("  /  /  ")` — nunca `NULL` via SQL.
- Validar `Eof()`/`Bof()` antes de ler; fechar temp com `(cAls)->(DbCloseArea())` apos `Select(cAls) > 0`.
- Nunca `GetMV()`/`SuperGetMV()`/`ExistBlock()`/`Type()`/`Pergunte()` dentro de loop.

## SQL seguro (SQL Server via TcQuery/BeginSQL)

- Sempre `D_E_L_E_T_ = ' '`, filtro filial, `RetSqlName()` na tabela fisica.
- `%nolock%` e proibido (nao e macro do BeginSQL/DBAccess). Leitura/relatorio usa hint literal `WITH (NOLOCK)`, reinjetado apos o `ChangeQuery()`.
- `FWExecStatement`/`ChangeQuery()`, parametros (`?`/`:param`). Nunca concatenar entrada do usuario.
- CNPJ (SA2 x ZZ4): `REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(campo)),'.',''),'/',''),'-','')`.

## Qualidade obrigatoria

- SonarQube G1–G5: sem violacao CRITICAL/MAJOR; citar ID da regra no review (ex.: `CA2050 — SQL Injection`).
- **Validar simbolos** antes de gerar: codigo existente -> skills -> AGENTS.md -> TDN -> web -> perguntar. Nunca inventar.
- **Completeness**: apos gerar/migrar, gap analysis item-a-item (migrado / nao-migravel justificado / preservado). Nunca omitir comportamento em silencio.
