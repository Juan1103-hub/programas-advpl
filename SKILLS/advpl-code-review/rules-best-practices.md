# Best Practices Rules

Rules for detecting violations of ADVPL/TLPP best practices. Each rule includes a detection pattern, violation example, correct example, and explanation.

---

## [BP-001] RecLock without corresponding MsUnlock

**Severity:** CRITICAL

**Description:** Every `RecLock` call must have a corresponding `MsUnlock` call. Forgetting to unlock a record keeps it locked, blocking other users and threads from accessing it, potentially causing deadlocks and data access failures.

**What to look for:** A `RecLock` call that is not followed by `MsUnlock` within the same logical block. Check that all code paths (including error branches) release the lock.

**Violation:**

```advpl
User Function UpdateClient()
    Local cCodCli := "000001"

    DbSelectArea("SA1")
    DbSetOrder(1)

    If DbSeek(xFilial("SA1") + cCodCli)
        RecLock("SA1", .F.)
        SA1->A1_NOME := "New Name"
        // Missing MsUnlock - record stays locked!
    EndIf

Return
```

**Correct:**

```advpl
User Function UpdateClient()
    Local cCodCli := "000001"

    DbSelectArea("SA1")
    DbSetOrder(1)

    If DbSeek(xFilial("SA1") + cCodCli)
        If RecLock("SA1", .F.)
            SA1->A1_NOME := "New Name"
            MsUnlock()
        EndIf
    EndIf

Return
```

**Why it matters:** An unreleased lock blocks all other threads attempting to write to the same record. In high-concurrency environments this leads to lock timeouts, deadlocks, and user complaints about frozen screens.

---

## [BP-002] Local variables declared outside the function header

**Severity:** ERROR

**Description:** In ADVPL/TLPP, ALL `Local` variable declarations MUST appear at the top of the function, immediately after the function signature and before any executable code. Declaring `Local` inside `If`, `While`, `For` blocks, or after any executable statement is a violation that can cause compilation errors or unpredictable behavior.

**What to look for:** `Local` keyword appearing after any executable statement (DbSelectArea, If, While, RecLock, assignments, function calls, etc.).

**Violation:**

```advpl
User Function ProcessData()
    Local aArea := GetArea()
    Local cAlias := "SA1"

    DbSelectArea(cAlias)
    DbSetOrder(1)

    If DbSeek(xFilial("SA1") + "000001")
        Local cNome := AllTrim(SA1->A1_NOME)  // WRONG: Local inside If block
        Local nSaldo := SA1->A1_SALDO         // WRONG: Local after executable code
    EndIf

    RestArea(aArea)
Return cNome
```

**Correct:**

```advpl
User Function ProcessData()
    Local aArea  := GetArea()
    Local cAlias := "SA1"
    Local cNome  := ""
    Local nSaldo := 0

    DbSelectArea(cAlias)
    DbSetOrder(1)

    If DbSeek(xFilial("SA1") + "000001")
        cNome  := AllTrim(SA1->A1_NOME)
        nSaldo := SA1->A1_SALDO
    EndIf

    RestArea(aArea)
Return cNome
```

**Why it matters:** ADVPL/TLPP requires all variable declarations at the function header. Declaring variables in the middle of executable code violates the language specification and can lead to compilation errors in strict mode or undefined behavior. Variables that are conditionally needed should be declared at the top with a default value (Nil, "", 0, .F., {}) and assigned later.

---

## [BP-002b] Variables declared as Private or Public instead of Local

**Severity:** WARNING

**Description:** Variables should be declared as `Local` unless there is a specific need for broader scope. `Private` and `Public` variables pollute the call stack and can be accidentally overwritten by called functions.

**What to look for:** `Private` or `Public` variable declarations where `Local` would suffice. Legitimate uses of `Private` include passing variables to MVC models or legacy framework functions that expect them.

**Violation:**

```advpl
User Function CalcTotal()
    Private nTotal  := 0
    Private cCodCli := "000001"
    Private nIdx    := 0

    For nIdx := 1 To 10
        nTotal += GetValue(nIdx)
    Next nIdx

Return nTotal
```

**Correct:**

```advpl
User Function CalcTotal()
    Local nTotal  := 0
    Local cCodCli := "000001"
    Local nIdx    := 0

    For nIdx := 1 To 10
        nTotal += GetValue(nIdx)
    Next nIdx

Return nTotal
```

**Why it matters:** `Private` variables are visible to all functions called from the declaring function. A called function may unintentionally read or overwrite a `Private` variable, causing hard-to-trace bugs. `Local` variables are scoped to the declaring function only, making code predictable and safer.

---

## [BP-003] Missing GetArea/RestArea in functions that use DbSelectArea/DbSetOrder/DbSeek

**Severity:** WARNING

**Description:** Functions that change the current WorkArea (via `DbSelectArea`, `DbSetOrder`, `DbSeek`, etc.) must save and restore the caller's WorkArea state using `GetArea()` and `RestArea()`. Otherwise, the calling function's WorkArea context is silently altered.

**What to look for:** Any function that calls `DbSelectArea`, `DbSetOrder`, `DbSeek`, or `DbGoTo` without first calling `GetArea()` on the affected alias and calling `RestArea()` before returning.

**Violation:**

```advpl
User Function GetClientName(cCodCli)
    Local cNome := ""

    DbSelectArea("SA1")
    DbSetOrder(1)

    If DbSeek(xFilial("SA1") + cCodCli)
        cNome := SA1->A1_NOME
    EndIf

Return cNome
```

**Correct:**

```advpl
User Function GetClientName(cCodCli)
    Local cNome   := ""
    Local aAreaSA1 := SA1->(GetArea())

    DbSelectArea("SA1")
    DbSetOrder(1)

    If DbSeek(xFilial("SA1") + cCodCli)
        cNome := SA1->A1_NOME
    EndIf

    RestArea(aAreaSA1)

Return cNome
```

**Why it matters:** Without saving and restoring the area, the calling function loses its WorkArea position. This causes incorrect reads, skipped records, and mysterious bugs that are extremely difficult to diagnose because they depend on call order.

---

## [BP-004] #Include "Protheus.ch" instead of #Include "TOTVS.CH"

**Severity:** WARNING

**Description:** The include `Protheus.ch` is obsolete. All `.prw` files should use `#Include "TOTVS.CH"` which is the current standard and includes all necessary definitions.

**What to look for:** Any line containing `#Include "Protheus.ch"` (case-insensitive).

**Violation:**

```advpl
#Include "Protheus.ch"

User Function MyFunc()
    // ...
Return
```

**Correct:**

```advpl
#Include "TOTVS.CH"

User Function MyFunc()
    // ...
Return
```

**Why it matters:** `Protheus.ch` is a legacy include that may not contain all current definitions and may be removed in future Protheus versions. `TOTVS.CH` is the officially supported include that aggregates all necessary header definitions.

---

## [BP-005] Missing Begin Sequence/Recover/End Sequence around critical operations

**Severity:** WARNING

**Description:** Critical operations such as `RecLock`, database writes, external API calls, and file operations should be wrapped in `Begin Sequence`/`Recover`/`End Sequence` blocks to handle errors gracefully instead of crashing.

**What to look for:** `RecLock`, `MsExecAuto`, `HttpGet`, `HttpPost`, `FT_FUse`, or web service calls that are not inside a `Begin Sequence` block.

**Violation:**

```advpl
User Function ProcessOrder(cOrder)
    Local lRet := .T.

    DbSelectArea("SC5")
    DbSetOrder(1)
    DbSeek(xFilial("SC5") + cOrder)

    RecLock("SC5", .F.)
    SC5->C5_LIBEROK := "S"
    MsUnlock()

    // If RecLock fails or an error occurs, function crashes
    // with an unhandled exception

Return lRet
```

**Correct:**

```advpl
User Function ProcessOrder(cOrder)
    Local lRet   := .T.
    Local oError

    DbSelectArea("SC5")
    DbSetOrder(1)
    DbSeek(xFilial("SC5") + cOrder)

    Begin Sequence

        If RecLock("SC5", .F.)
            SC5->C5_LIBEROK := "S"
            MsUnlock()
        Else
            lRet := .F.
            ConOut("[ProcessOrder] Could not lock SC5 for order: " + cOrder)
        EndIf

    Recover Using oError
        lRet := .F.
        ConOut("[ProcessOrder] Error: " + oError:Description)

    End Sequence

Return lRet
```

**Why it matters:** Without error handling, any failure in database or external operations causes the entire thread to crash, potentially leaving records locked and data in an inconsistent state. Structured error handling allows graceful recovery and proper cleanup.

---

## [BP-006] Variable names not following Hungarian notation

**Severity:** INFO

**Description:** ADVPL convention uses Hungarian notation with a type prefix followed by PascalCase: `c` for character, `n` for numeric, `l` for logical, `d` for date, `a` for array, `o` for object, `b` for code block, `x` for variant/indefinite.

**What to look for:** Variable declarations where the name does not start with a recognized type prefix (`c`, `n`, `l`, `d`, `a`, `o`, `b`, `x`) or does not follow PascalCase after the prefix.

**Violation:**

```advpl
User Function Calculate()
    Local total     := 0
    Local clientName := ""
    Local flag      := .T.
    Local items     := {}
    Local dt        := Date()

    // Variable names do not indicate their type

Return
```

**Correct:**

```advpl
User Function Calculate()
    Local nTotal      := 0
    Local cClientName := ""
    Local lFlag       := .T.
    Local aItems      := {}
    Local dDate       := Date()

    // Each variable name starts with its type prefix

Return
```

**Why it matters:** Hungarian notation makes code self-documenting. When reading `nTotal`, any developer immediately knows it is a numeric value. This reduces bugs caused by type mismatches and speeds up code reviews.

---

## [BP-007] Functions missing Protheus.doc documentation header

**Severity:** INFO

**Description:** Every `User Function`, `Static Function`, and `Main Function` should have a `Protheus.doc` documentation header describing the function's purpose, author, date, parameters, and return value.

**What to look for:** Function definitions without a preceding `Protheus.doc` comment block.

**Violation:**

```advpl
User Function CalcDiscount(nPrice, nPercent)
    Local nDiscount := nPrice * (nPercent / 100)
Return nDiscount
```

**Correct:**

```advpl
/*/{Protheus.doc} CalcDiscount
Calculates discount value based on price and percentage.

@type  User Function
@author Developer Name
@since 01/01/2025
@version 1.0

@param nPrice, Numeric, Original price
@param nPercent, Numeric, Discount percentage (0-100)

@return Numeric, Calculated discount value

@example
Local nDisc := CalcDiscount(100.00, 10) // Returns 10.00
/*/
User Function CalcDiscount(nPrice, nPercent)
    Local nDiscount := nPrice * (nPercent / 100)
Return nDiscount
```

**Why it matters:** Documentation headers enable IDE tooltips, automatic documentation generation, and help other developers understand the function's contract without reading the implementation. They are especially important in large teams and long-lived codebases.

---

## [BP-008] Using reserved system variables as Local/Static variable names

**Severity:** CRITICAL

**Description:** The Protheus framework maintains several `Private` variables to track the current company, branch, and environment context. Declaring a `Local` variable with the same name shadows the system variable, causing loss of context, incorrect data filtering, and hard-to-reproduce bugs in multi-branch/multi-company environments.

**Reserved variable names (NEVER use as Local/Static):**

| Variable | Purpose |
|----------|---------|
| `cFilial` | Branch context — used internally by xFilial() and other framework functions |
| `cFilAnt` | Current branch code — default value for xFilial() second parameter |
| `cEmpAnt` | Current company/group code — used by FWSizeFilial() and environment functions |
| `nModulo` | Current module number |
| `cUsuario` | Current user login |

**Violation:**

```advpl
User Function MyJob()
    Local cEmpresa := "99"
    Local cFilial  := "01"   // WRONG: shadows system Private variable

    RpcSetEnv(cEmpresa, cFilial)
    // After this call, the system's cFilial Private is overwritten
    // xFilial() and other functions may return incorrect values
Return
```

**Correct:**

```advpl
User Function MyJob()
    Local cCodEmp := "99"
    Local cCodFil := "01"   // Safe: different name from system variable

    RpcSetEnv(cCodEmp, cCodFil)
    // System's cFilAnt/cEmpAnt are set correctly by RpcSetEnv
    // xFilial() works as expected
Return
```

**Recommended alternatives:**

| Instead of | Use |
|------------|-----|
| `cFilial` | `cCodFil` |
| `cEmpresa` | `cCodEmp` |
| `cFilAnt` | (never reassign — read-only system variable) |
| `cEmpAnt` | (never reassign — read-only system variable) |

**Use FW* functions to read company/branch values:**

| Function | Purpose |
|----------|---------|
| `FWCodFil()` | Returns current branch code (M0_CODFIL) |
| `FWCodEmp()` | Returns current company code |
| `FWFilial(cAlias)` | Returns branch for the given alias (respects sharing mode) |
| `FWCompany(cAlias)` | Returns company for the given alias |
| `FWGrpCompany()` | Returns current company group |
| `FWUnitBusiness(cAlias)` | Returns current business unit |
| `FWAllFilial()` | Returns array of all branches for current group/company |
| `FWAllCompany()` | Returns array of all companies for current group |
| `FWAllGrpCompany()` | Returns array of all company groups |
| `FWSizeFilial()` | Returns branch field size |
| `xFilial(cAlias)` | Returns branch for index composition (respects sharing mode) |

**Why it matters:** Shadowing system Private variables is one of the most dangerous bugs in Protheus because it is silent — the code compiles and appears to work in single-branch testing, but fails in multi-branch production environments where branch context is critical for data isolation.
