---
name: sql-anti-injection
description: SQL canônico anti-injection + soft-delete + filial + nolock
type: reference
metadata:
  type: reference
---
**Padrão:** Toda query SQL em AdvPL segue este template
**Quando usar:** Qualquer `FWExecStatement`, `ChangeQuery`, `TCQuery`, `ADO`, `FWQuery`
**Template canônico:**
```advpl
Local cQuery := ""
cQuery += " SELECT " + RetSqlName("C7") + ".C7_NUM, " + RetSqlName("C7") + ".C7_ITEM, " + RetSqlName("C7") + ".C7_QUANT "
cQuery += " FROM " + RetSqlName("SC7") + " " + RetSqlName("C7") + " "
cQuery += " WHERE " + RetSqlName("C7") + ".D_E_L_E_T_ = ' ' "
cQuery += "   AND " + RetSqlName("C7") + ".C7_FILIAL = " + FWxFilial("SC7") + " "
cQuery += "   AND " + RetSqlName("C7") + ".C7_NUM = " + FWxFilial("SC7") + " "
cQuery += "   AND " + RetSqlName("C7") + ".C7_ITEM = " + cValToChar(nItem) + " "

// Para leitura: adicionar %nolock%
cQuery += " %nolock% "

FWExecStatement(cQuery, .F., .T.)  // .T. = log, .F. = não commit
```
**Regras obrigatórias:**
1. `D_E_L_E_T_ = ' '` (soft-delete)
2. `XX_FILIAL = FWxFilial('XXX')` ou `xFilial('XXX')` — nunca `cFilial` direta
3. `FWExecStatement` ou `ChangeQuery()` — **nunca** concatenação direta de variável (SQL injection = CA2050/CA2051/CA2052)
4. `RetSqlName("ALIAS")` na tabela física (portabilidade Oracle/SQL Server/PostgreSQL)
5. `%nolock%` em **toda leitura** (SELECT) — evita bloqueios
6. Parâmetros via `FWxFilial`, `cValToChar`, `dToS` — nunca interpolação string
**SonarQube:** CA2050 (SQL Injection), CA2051, CA2052, CA2053
[[hungarian-notation]] [[regras-cfilial-nunca-direta]] [[tabelas-sc7-tomadas-centrais]]