# /quick-fix <arquivo> <problema> — Fix pequeno + compile + review

## Uso
```
/quick-fix MTA110OK.PRW "CA2050 SQL injection linha 45"
/quick-fix ZC7DATAENT.tlpp "encoding UTF-8 → CP1252"
/quick-fix MTA110INC.PRW "IIF proibido linha 33"
```

## Scope
- **Máx 3 arquivos** (se >3, use `/specify` → `/tasks` → `/execute`)
- Fix direto: húngaro, SonarQube, encoding, IIF, UI em transação, cFilial

## Fluxo automático
1. `read` arquivo alvo
2. `edit` fix pontual
3. `utf8-to-cp1252-conversion` no arquivo
4. `advpl-tlpp-compile` contra `CINVJ6_DEV`
5. `advpl-code-review --level high` no arquivo
6. Se erro compilação/review → **para e mostra**
7. Se OK → cria memory se bug novo (`TEMPLATE-BUG.md`)

## Exemplo fix CA2050
**Antes (linha 45):**
```advpl
cQuery := "SELECT * FROM SC7 WHERE C7_NUM = '" + cNum + "'"
```
**Depois:**
```advpl
cQuery := "SELECT * FROM " + RetSqlName("SC7") + " WHERE D_E_L_E_T_ = ' ' AND C7_FILIAL = " + FWxFilial("SC7") + " AND C7_NUM = " + cValToChar(cNum) + " %nolock%"
```

## Validações incluídas
- [ ] Notação húngara
- [ ] SQL anti-injection (CA2050/51/52)
- [ ] IIF → If/Else (CA4000)
- [ ] UI em transação (CA1002)
- [ ] cFilial direta → FWxFilial
- [ ] Encoding CP-1252
- [ ] Function → User Function/Static Function
- [ ] Entry Point naming