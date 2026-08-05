# Security Rules

Rules for detecting security vulnerabilities in ADVPL/TLPP code. Each rule includes a detection pattern, violation example, correct example, and explanation.

---

## [SEC-001] SQL built by string concatenation without %exp: macro (SQL injection risk)

**Severity:** CRITICAL

**Description:** Building SQL queries by concatenating user-supplied or external variables directly into the query string allows SQL injection attacks. Attackers can manipulate input to execute arbitrary SQL commands, potentially reading, modifying, or deleting data.

**What to look for:** `TCQuery` or string-based SQL construction where variables are concatenated with `+` instead of using BeginSQL with `%exp:variable%` macro substitution.

**Violation:**

```advpl
User Function SearchClient(cSearch)
    Local cQuery := ""

    // DANGEROUS: cSearch is concatenated directly into SQL
    cQuery := "SELECT A1_COD, A1_NOME FROM " + RetSqlName("SA1")
    cQuery += " WHERE A1_NOME LIKE '%" + cSearch + "%'"
    cQuery += " AND D_E_L_E_T_ = ' '"

    TCQuery cQuery New Alias "QRY_CLI"

    // If cSearch = "'; DROP TABLE SA1; --"
    // the query becomes destructive!

Return
```

**Correct:**

```advpl
User Function SearchClient(cSearch)
    Local cAlias  := GetNextAlias()
    Local cFilter := "%" + cSearch + "%"

    BeginSQL Alias cAlias
        SELECT SA1.A1_COD, SA1.A1_NOME
        FROM %table:SA1% SA1
        WHERE SA1.%notDel%
        AND SA1.A1_FILIAL = %xfilial:SA1%
        AND SA1.A1_NOME LIKE %exp:cFilter%
    EndSQL

Return
```

**Why it matters:** SQL injection is one of the most exploited vulnerabilities in web applications and internal systems alike. In Protheus, an injected query could bypass access controls, extract sensitive financial data, or corrupt critical business tables. The `%exp:` macro safely parameterizes values, preventing injection.

---

## [SEC-002] REST endpoint using SELF:GetContent() without input validation

**Severity:** CRITICAL

**Description:** REST API endpoints that read request body content via `SELF:GetContent()` (or `oRest:GetBody()`) and use the data directly without validation expose the system to injection attacks, type errors, and business logic bypass.

**What to look for:** `SELF:GetContent()`, `oRest:GetBody()`, or similar request body reading methods where the returned content is used directly in SQL queries, database operations, or business logic without validation or sanitization.

**Violation:**

```tlpp
@Get("/api/v1/clients")
Method GetClient() Class ClientService
    Local cBody   := SELF:GetContent()
    Local jBody   := JsonObject():New()
    Local cCodCli := ""

    jBody:FromJson(cBody)
    cCodCli := jBody["code"]  // No validation!

    // Used directly in database lookup
    DbSelectArea("SA1")
    DbSetOrder(1)
    DbSeek(xFilial("SA1") + cCodCli)

    // cCodCli could be NIL, empty, oversized, or contain
    // malicious data - no checks performed

Return
```

**Correct:**

```tlpp
@Get("/api/v1/clients")
Method GetClient() Class ClientService
    Local cBody   := SELF:GetContent()
    Local jBody   := JsonObject():New()
    Local cCodCli := ""
    Local nRet    := jBody:FromJson(cBody)

    // Validate JSON parsing
    If nRet <> 0
        SELF:SetResponse('{"error": "Invalid JSON body"}')
        SELF:SetStatus(400)
        Return
    EndIf

    // Validate required field existence and type
    If ValType(jBody["code"]) <> "C" .Or. Empty(jBody["code"])
        SELF:SetResponse('{"error": "Field code is required and must be a string"}')
        SELF:SetStatus(400)
        Return
    EndIf

    // Validate field length and content
    cCodCli := PadR(AllTrim(jBody["code"]), TamSX3("A1_COD")[1])

    DbSelectArea("SA1")
    DbSetOrder(1)
    If DbSeek(xFilial("SA1") + cCodCli)
        // Process valid client
    Else
        SELF:SetResponse('{"error": "Client not found"}')
        SELF:SetStatus(404)
    EndIf

Return
```

**Why it matters:** REST endpoints are exposed to external consumers and potentially the public internet. Without input validation, attackers can send malformed payloads that cause runtime errors (crashing the thread), bypass business rules, or exploit downstream operations. Every input must be validated for type, length, format, and business constraints.

---

## [SEC-003] Sensitive data in ConOut/FWLogMsg output

**Severity:** WARNING

**Description:** Logging sensitive information such as passwords, API tokens, CPF/CNPJ numbers, credit card numbers, or personal data in `ConOut` or `FWLogMsg` exposes it to anyone with access to the AppServer console or log files.

**What to look for:** `ConOut` or `FWLogMsg` calls that output variables containing passwords, tokens, credentials, CPF, CNPJ, or any personally identifiable information (PII).

**Violation:**

```advpl
User Function AuthenticateUser(cUser, cPassword)
    Local lOk := .F.

    // DANGER: password logged in plain text!
    ConOut("[Auth] Attempting login - User: " + cUser + " Password: " + cPassword)

    lOk := ValidateCredentials(cUser, cPassword)

    If !lOk
        FWLogMsg("WARNING", , "AUTH", "Security", "", 01, ;
            "Failed login for user: " + cUser + " with password: " + cPassword)
    EndIf

Return lOk
```

**Correct:**

```advpl
User Function AuthenticateUser(cUser, cPassword)
    Local lOk := .F.

    ConOut("[Auth] Attempting login - User: " + cUser)

    lOk := ValidateCredentials(cUser, cPassword)

    If !lOk
        FWLogMsg("WARNING", , "AUTH", "Security", "", 01, ;
            "Failed login attempt for user: " + cUser)
    EndIf

Return lOk
```

**Why it matters:** Log files are often stored unencrypted, shared across teams, and retained for long periods. Sensitive data in logs can be accessed by unauthorized personnel, leaked through log aggregation tools, or exposed in security breaches. Regulations like LGPD (Brazil) and GDPR explicitly require that personal data not be logged unnecessarily.

---

## [SEC-004] Hardcoded credentials in source code

**Severity:** WARNING

**Description:** Passwords, API keys, database connection strings, and other credentials must never be hardcoded in source code. Source code is stored in version control, compiled into RPO, and accessible to all developers, making hardcoded secrets a significant security risk.

**What to look for:** String literals that appear to be passwords, API keys, bearer tokens, connection strings, or authentication secrets assigned to variables or used directly in function calls.

**Violation:**

```advpl
User Function ConnectAPI()
    Local cUrl    := "https://api.example.com/v1"
    Local cApiKey := "sk-abc123def456ghi789jkl012mno345"
    Local cPass   := "P@ssw0rd!2025"
    Local aHeaders := {}

    aAdd(aHeaders, "Authorization: Bearer " + cApiKey)
    aAdd(aHeaders, "Content-Type: application/json")

    cResponse := HttpGet(cUrl + "/data", "", aHeaders)

Return cResponse
```

**Correct:**

```advpl
User Function ConnectAPI()
    Local cUrl     := "https://api.example.com/v1"
    Local cApiKey  := GetAPICredential("EXAMPLE_API_KEY")
    Local aHeaders := {}

    If Empty(cApiKey)
        ConOut("[ConnectAPI] API key not configured. Check SX6 parameter EXAMPLE_API_KEY.")
        Return ""
    EndIf

    aAdd(aHeaders, "Authorization: Bearer " + cApiKey)
    aAdd(aHeaders, "Content-Type: application/json")

    cResponse := HttpGet(cUrl + "/data", "", aHeaders)

Return cResponse

// Store credentials in SX6 parameters, environment variables,
// or a secure vault - never in source code
Static Function GetAPICredential(cParamName)
    Local cValue := AllTrim(GetMV(cParamName))
Return cValue
```

**Why it matters:** Hardcoded credentials in source code are exposed to every developer with repository access, remain in version history even after deletion, and can be extracted from compiled RPO. If the repository is compromised, all hardcoded credentials are immediately exposed. Use Protheus SX6 parameters, environment variables, or a secrets management solution instead.

---

## [SEC-005] Usage of TOTVS restricted/internal functions, classes, or variables

**Severity:** CRITICAL

**Description:** TOTVS maintains a list of functions, classes, and variables that are internal property. These resources are NOT documented, NOT supported, and may be altered or removed without notice. Some have their compilation blocked since release 12.1.33. Using them in custom code causes compilation failures, runtime errors, or unpredictable behavior after updates.

**What to look for:** Any call to functions or classes listed in the TOTVS restricted resources list. See `restricted-functions.md` in the protheus-reference skill for the complete list.

**Compilation BLOCKED (will not compile on 12.1.33+):**

- `StaticCall()` — use public User Functions or TLPP namespaced calls instead
- `PTInternal()` — no replacement available; redesign the logic

**Commonly found restricted functions (NOT supported, may change without notice):**

| Restricted | Alternative |
|------------|-------------|
| `PARAMBOX` | Use `Pergunte()` with SX1 or `FWInputDialog()` |
| `MsExcel` | Use `FWMsExcel` or `FWAdaptor` |
| `CriaVar` | Use `FWCriaVar()` |
| `LASTKEY` | Use specific navigation control logic |
| `SetPrvt` | Declare variables explicitly with `Private` |
| `MontaBlock` | Build code blocks directly with `{|| ... }` |
| `FWMVCROTAUTO` | Use `FWExecView()` for MVC automation |
| `FWLOOKUP` | Use `FWInputDialog()` or standard F3 lookups |
| `OPENSXS` | Tables are opened automatically by the framework |
| `APPEND FROM` | Use `RecLock` + field-by-field copy |
| `COPY TO` | Use `RecLock` + field-by-field copy |
| `LoadLayout()` | Use `FWLoadLayout()` |
| `PivotTable` | Use `FWPivotTable` |
| `StaticCall()` | Use `User Function` (public) or TLPP namespace |
| `ApOleClient` | Use `FWMsExcel` for Excel or native file operations |
| `FWAUTHUSER` | Use proper REST authentication mechanisms |
| `E_FIELD` | Use `GetSx3Cache()` or `TamSx3()` |

**Violation:**

```advpl
User Function MyReport()
    // WRONG: StaticCall is BLOCKED since 12.1.33
    Local aMenu := StaticCall(MATA030, MenuDef)

    // WRONG: PARAMBOX is restricted
    PARAMBOX(aParams, "Filtros", , , , , , , , , .F., .F.)

    // WRONG: CriaVar is restricted
    Local xVal := CriaVar("A1_COD")
Return
```

**Correct:**

```advpl
User Function MyReport()
    // CORRECT: Call public function directly
    Local aMenu := U_MenuDef()

    // CORRECT: Use Pergunte() with SX1 configuration
    Pergunte("MYREPORT", .F.)

    // CORRECT: Use FWCriaVar
    Local xVal := FWCriaVar("A1_COD")
Return
```

**Reference:** Full list at https://centraldeatendimento.totvs.com/hc/pt-br/articles/360016461772

**Why it matters:** TOTVS reserves the right to modify or remove internal functions without notice. Code that uses restricted functions will break silently after Protheus updates — or fail to compile entirely on releases 12.1.33+. The TOTVS support team does NOT provide assistance for issues caused by restricted function usage. Always use documented, supported alternatives.
