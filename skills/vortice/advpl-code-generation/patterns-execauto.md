# Protheus ExecAuto Patterns

Manual for implementing automated routines (ExecAuto) in TOTVS Protheus. This is the **mandatory** pattern for complex business entities like Sales Orders, Purchase Orders, and Invoices.

---

## 1. Why use ExecAuto?

Directly using `RecLock` on core tables (SC5, SC6, SC7, SD1, SD2, etc.) bypasses:
- **Field Validations** (VLDUSER, CNIVEL, etc.)
- **Automatic Triggers** (SX7)
- **Integrity Checks** (SX9)
- **Standard Business Rules** (Calculations, stock updates, financial entries)

**MANDATORY:** Always use `MSExecAuto` for entities that have a standard Protheus routine.

---

## 2. Sales Order (MATA410)

The most common ExecAuto. It handles header (SC5) and items (SC6) simultaneously.

### 2.1 Basic Structure

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} MySalesOrder
Example of Sales Order creation via ExecAuto
@type function
/*/
User Function MySalesOrder(oRequest)
    Local aCabec     := {}
    Local aItens     := {}
    Local aLinha     := {}
    Local i          := 0
    Local lOk        := .T.
    
    // MSExecAuto global control variables
    Private lMsErroAuto := .F.
    Private lMsHelpAuto := .T.

    // 1. Prepare Header (SC5)
    // Format: { FieldName, Value, Nil }
    aAdd(aCabec, {"C5_TIPO",    "N",               Nil})
    aAdd(aCabec, {"C5_CLIENTE", oRequest["client"], Nil})
    aAdd(aCabec, {"C5_LOJACLI", oRequest["store"],  Nil})
    aAdd(aCabec, {"C5_CONDPAG", "001",             Nil})
    aAdd(aCabec, {"C5_TABELA",  "01",              Nil})
    aAdd(aCabec, {"C5_EMISSAO", dDataBase,         Nil})

    // 2. Prepare Items (SC6)
    // Format: Array of arrays, where each inner array is a line
    For i := 1 To Len(oRequest["items"])
        aLinha := {}
        aAdd(aLinha, {"C6_ITEM",    StrZero(i, 2), Nil})
        aAdd(aLinha, {"C6_PRODUTO", oRequest["items"][i]["product"], Nil})
        aAdd(aLinha, {"C6_QTD",     oRequest["items"][i]["quantity"], Nil})
        aAdd(aLinha, {"C6_PRECO",   oRequest["items"][i]["price"], Nil})
        aAdd(aLinha, {"C6_TES",     "501", Nil})
        aAdd(aItens, aLinha)
    Next i

    // 3. Execute MATA410 (3 = Inclusion, 4 = Alteration, 5 = Deletion)
    MSExecAuto({|x,y,z| MATA410(x,y,z)}, aCabec, aItens, 3)

    // 4. Handle Errors
    If lMsErroAuto
        lOk := .F.
        Conout("Error in MATA410 ExecAuto")
        MostraErro() // Log or show errors
    Else
        Conout("Sales Order created: " + SC5->C5_NUM)
    EndIf

Return lOk
```

---

## 3. Operations Reference

| Operation | Value | Description |
|-----------|-------|-------------|
| Inclusion | 3 | Create new record |
| Alteration | 4 | Update existing record (requires positioning) |
| Deletion | 5 | Remove record (requires positioning) |

---

## 4. Error Handling Pattern for APIs

When using ExecAuto inside a REST API, you should capture the error log into a string to return in the JSON response.

```advpl
If lMsErroAuto
    cError := GetAutoGRLog() // Captures the error log
    SetRestFault(500, cError)
EndIf
```

---

## 5. Common ExecAuto Routines

| Entity | Routine | Table |
|--------|---------|-------|
| Sales Order | `MATA410` | SC5/SC6 |
| Purchase Order | `MATA120` | SC7 |
| Products | `MATA010` | SB1 |
| Customers | `CRMA980` | SA1 |
| Invoices (Inbound) | `MATA103` | SF1/SD1 |
| Invoices (Outbound) | `MATA461` | SF2/SD2 |
| Inventory Adjustments | `MATA241` | SD3 |
| Accounts Payable | `FINA050` | SE2 |
| Accounts Receivable | `FINA040` | SE1 |
