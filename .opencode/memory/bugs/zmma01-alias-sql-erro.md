---
name: zmma01-alias-sql-erro
description: Erros SQL 4104 (alias não declarado) e 8120 (coluna fora do GROUP BY) na query SB9 do ZMMA01
type: feedback
metadata:
  type: feedback
---

# Bug: Erros SQL no SELECT com alias/subquery (ZMMA01 - ExportarDetalhes)

**Data**: 2026-10-01 · **Fonte**: `FONTES/ZMMA01.PRW` (funcao `ExportarDetalhes`, query SB9) · **Ambiente**: `CINVJ6_DEV`, SQL Server / ODBC Driver 13

## Problema

Dois THREAD ERRORs sucessivos ao executar o botao Detalhes (query do SB9 via `TCGenQry`):

1. **Erro 4104** `The multi-part identifier "B9.B9_COD" could not be bound`
2. **Erro 8120** `Column 'MX.MAXDT' is invalid in the select list because it is not contained in either an aggregate function or the GROUP BY clause`

Query gerada (log do console):

```sql
SELECT SB9.B9_COD COD, SUM(SB9.B9_QINI) QTD, MX.MAXDT DTB9
FROM SB9010 SB9 WITH (NOLOCK)
INNER JOIN ( SELECT B9X.B9_COD CODX, MAX(B9X.B9_DATA) MAXDT
             FROM SB9010 B9X ... GROUP BY B9X.B9_COD ) MX
  ON MX.CODX = SB9.B9_COD AND MX.MAXDT = SB9.B9_DATA
WHERE ...
GROUP BY SB9.B9_COD
```

## Causa

1. **4104**: SELECT usava alias `B9.` enquanto FROM/JOIN/GROUP BY declaravam `SB9.` — alias nunca declarado.
2. **8120**: `MX.MAXDT` no SELECT mas ausente do GROUP BY. O SQL Server exige que toda coluna nao agregada do SELECT esteja no GROUP BY, mesmo quando o JOIN ja garante valor unico por grupo.

## Fix

- `ZMMA01.PRW:1452` — alias do SELECT corrigido de `B9.` para `SB9.`
- `ZMMA01.PRW:1470` — GROUP BY ampliado para `GROUP BY SB9.B9_COD, MX.MAXDT` (sem mudanca de resultado: o JOIN restringe MAXDT ao maximo por produto)

## Como aplicar

- Alias SQL: o nome apos `FROM <tabela> <alias>` e a UNICA referencia valida no SELECT/WHERE/GROUP BY. Nao confundir nome curto da tabela (SB9) com o alias declarado — conferir cada prefixo `tabela.campo` contra o alias do FROM antes de compilar.
- GROUP BY: cada coluna nao agregada do SELECT precisa estar no GROUP BY (SQL Server e restritivo). Coluna vinda de JOIN 1:1 pode entrar no GROUP BY sem alterar o resultado.
- Padrao do repo (ChangeQuery + StrTran de NOLOCK) nao valida semantica SQL — erro so aparece em execucao (THREAD ERROR no console do AppServer).

[[zmma01-botao-detalhes]] [[padroes/sql-anti-injection]]
