# Protheus Workflow and Approval Patterns

Complete reference for implementing approval workflows, automatic routines (MsExecAuto), and email notifications in TOTVS Protheus.

---

## 1. Overview

TOTVS Protheus provides built-in support for document approval workflows through the approval control system (Alcada), automatic routine execution (MsExecAuto/FWMVCRotAuto), and email notifications.

Key components:
- **MsExecAuto**: Executes standard Protheus routines (ExecAuto) programmatically without user interface.
- **FWMVCRotAuto**: Executes MVC-based routines programmatically.
- **SCR Table**: Stores documents pending approval (Documentos com Alcada).
- **SAK Table**: Stores approver definitions and limits.
- **TMailManager**: Email server communication class (SMTP/POP3).
- **TMailMessage**: Email message composition and sending.

Required includes:
```advpl
#Include "TOTVS.CH"
```

For MVC operations:
```advpl
#Include "TOTVS.CH"
#Include "FWMVCDef.ch"
```

---

## 2. MsExecAuto - Automatic Routine Execution

### 2.1 Syntax

```advpl
MsExecAuto({|x,y,z| ROUTINE(x,y,z)}, aCabec, aItens, nOpc)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| Block | Block | Code block calling the target routine |
| `aCabec` | Array | Header fields array `{{"FIELD", value, Nil}, ...}` |
| `aItens` | Array | Item lines array (for master-detail routines) |
| `nOpc` | Numeric | Operation: `3`=Include, `4`=Update, `5`=Delete |

### 2.2 Standard Variables

Before calling MsExecAuto, declare these Private variables:

```advpl
Private lMsErroAuto    := .F.  // Error flag
Private lMsHelpAuto    := .T.  // Suppress Help dialogs
Private lAutoErrNoFile := .T.  // Errors to memory (not file)
```

### 2.3 Error Handling

```advpl
If lMsErroAuto
    // Erro ocorreu
    Local cErro := MostraErro(.F.)  // .F. retorna string em vez de exibir dialog
    ConOut("Erro na rotina automatica: " + cErro)
Else
    ConOut("Rotina executada com sucesso.")
EndIf
```

### 2.4 Include Purchase Request (MATA110)

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} zIncSC
Inclusao de Solicitacao de Compras via MsExecAuto
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function zIncSC()
    Local aArea    := GetArea()
    Local aCabec   := {}
    Local aItens   := {}
    Local aLinha   := {}

    Private lMsErroAuto    := .F.
    Private lMsHelpAuto    := .T.
    Private lAutoErrNoFile := .T.

    // Cabecalho (pode nao ser necessario para todas as rotinas)
    // MATA110 trabalha diretamente nos itens

    // Item 1
    aLinha := {}
    aAdd(aLinha, {"C1_PRODUTO", "000001",       Nil})
    aAdd(aLinha, {"C1_QUANT",   10,             Nil})
    aAdd(aLinha, {"C1_DESCRI",  "PRODUTO TESTE", Nil})
    aAdd(aLinha, {"C1_UM",      "UN",           Nil})
    aAdd(aLinha, {"C1_LOCAL",   "01",           Nil})
    aAdd(aLinha, {"C1_DATPRF",  Date() + 30,    Nil})
    aAdd(aItens, aLinha)

    // Item 2
    aLinha := {}
    aAdd(aLinha, {"C1_PRODUTO", "000002",        Nil})
    aAdd(aLinha, {"C1_QUANT",   5,               Nil})
    aAdd(aLinha, {"C1_DESCRI",  "PRODUTO TESTE 2", Nil})
    aAdd(aLinha, {"C1_UM",      "UN",            Nil})
    aAdd(aLinha, {"C1_LOCAL",   "01",            Nil})
    aAdd(aLinha, {"C1_DATPRF",  Date() + 30,     Nil})
    aAdd(aItens, aLinha)

    // Executa inclusao (opcao 3)
    MsExecAuto({|x, y, z| MATA110(x, y, z)}, aCabec, aItens, 3)

    If lMsErroAuto
        ConOut("Erro na inclusao da SC: " + MostraErro(.F.))
    Else
        ConOut("Solicitacao de compras incluida com sucesso.")
    EndIf

    RestArea(aArea)

Return Nil
```

### 2.5 Include Sales Order (MATA410)

```advpl
User Function zIncPV()
    Local aCabec := {}
    Local aItens := {}
    Local aLinha := {}
    Local aArea  := GetArea()

    Private lMsErroAuto    := .F.
    Private lMsHelpAuto    := .T.
    Private lAutoErrNoFile := .T.

    // Cabecalho do pedido de venda
    aAdd(aCabec, {"C5_TIPO",    "N",      Nil})
    aAdd(aCabec, {"C5_CLIENTE", "000001", Nil})
    aAdd(aCabec, {"C5_LOJACLI", "01",     Nil})
    aAdd(aCabec, {"C5_CONDPAG", "001",    Nil})

    // Item 1
    aLinha := {}
    aAdd(aLinha, {"C6_ITEM",    "01",      Nil})
    aAdd(aLinha, {"C6_PRODUTO", "000001",  Nil})
    aAdd(aLinha, {"C6_QTDVEN",  10,        Nil})
    aAdd(aLinha, {"C6_PRCVEN",  50.00,     Nil})
    aAdd(aLinha, {"C6_PRUNIT",  50.00,     Nil})
    aAdd(aLinha, {"C6_VALOR",   500.00,    Nil})
    aAdd(aLinha, {"C6_TES",     "501",     Nil})
    aAdd(aItens, aLinha)

    // Executa inclusao
    MsExecAuto({|x, y, z| MATA410(x, y, z)}, aCabec, aItens, 3)

    If lMsErroAuto
        ConOut("Erro na inclusao do PV: " + MostraErro(.F.))
    Else
        ConOut("Pedido de venda incluido com sucesso.")
    EndIf

    RestArea(aArea)

Return Nil
```

---

## 3. FWMVCRotAuto - MVC Automatic Execution

### 3.1 Syntax

```advpl
lRet := FWMVCRotAuto(oModel, cSource, nOperation, aParams)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `oModel` | Object | Model object (usually Nil, framework creates internally) |
| `cSource` | Character | Source program name with ModelDef |
| `nOperation` | Numeric | Operation constant (MODEL_OPERATION_INSERT, etc.) |
| `aParams` | Array | Data array: `{{"ModelId", aFieldValues}, {"GridId", aGridLines}}` |
| **Return** | Logical | `.T.` if operation succeeded |

### 3.2 Include via FWMVCRotAuto

```advpl
#Include "TOTVS.CH"
#Include "FWMVCDef.ch"

User Function zIncMVC()
    Local aHeader := {}
    Local aItems  := {}
    Local aLine   := {}
    Local lRet    := .F.
    Local oModel  := Nil

    // Cabecalho
    aAdd(aHeader, {"ZA1_NUM",    "000001",  Nil})
    aAdd(aHeader, {"ZA1_CLIENT", "000001",  Nil})
    aAdd(aHeader, {"ZA1_LOJA",   "01",      Nil})
    aAdd(aHeader, {"ZA1_EMISSA", Date(),    Nil})

    // Item 1
    aLine := {}
    aAdd(aLine, {"ZA2_ITEM",   "01",     Nil})
    aAdd(aLine, {"ZA2_PROD",   "000001", Nil})
    aAdd(aLine, {"ZA2_QUANT",  10,       Nil})
    aAdd(aLine, {"ZA2_PRCUNI", 25.50,    Nil})
    aAdd(aItems, aLine)

    // Executa
    lRet := FWMVCRotAuto(oModel, "FATA090", MODEL_OPERATION_INSERT, {;
        {"ZA1MASTER", aHeader}, ;
        {"ZA2DETAIL", aItems}   ;
    })

    If lRet
        ConOut("Registro incluido com sucesso!")
    Else
        ConOut("Erro na inclusao.")
        MostraErro()
    EndIf

Return lRet
```

---

## 4. Approval Flow - SCR Table

### 4.1 SCR Table Structure (Documentos com Alcada)

The SCR table stores documents pending approval in the Protheus approval system.

| Field | Type | Description |
|-------|------|-------------|
| `CR_FILIAL` | C(2) | Branch |
| `CR_NUM` | C(50) | Document number |
| `CR_TIPO` | C(2) | Document type |
| `CR_USER` | C(6) | User code who created the document |
| `CR_APROV` | C(6) | Approver code |
| `CR_GRUPO` | C(6) | Approval group |
| `CR_NIVEL` | C(2) | Approval level |
| `CR_STATUS` | C(2) | Approval status |
| `CR_EMISSAO` | D | Issue date |
| `CR_TOTAL` | N(14,2) | Total value |
| `CR_DATALIB` | D | Release/approval date |
| `CR_OBS` | M(50) | Approval observations |
| `CR_USERLIB` | C(6) | User who approved |
| `CR_LIBAPRO` | C(6) | Effective approver of the document |
| `CR_VALLIB` | N(14,2) | Approved value |
| `CR_TIPOLIM` | C(1) | Approver limit type |
| `CR_MOEDA` | N(2) | Currency |

### 4.2 SAK Table Structure (Aprovadores)

The SAK table stores approver definitions.

| Field | Type | Description |
|-------|------|-------------|
| `AK_FILIAL` | C(2) | Branch |
| `AK_COD` | C(6) | Approver code |
| `AK_USER` | C(6) | User code |
| `AK_NOME` | C(40) | Full name |
| `AK_LIMMIN` | N(14,2) | Minimum approval limit |
| `AK_LIMMAX` | N(14,2) | Maximum approval limit |
| `AK_APROSUP` | C(6) | Superior approver code |
| `AK_LIMITE` | N(14,2) | Approver limit |
| `AK_TIPO` | C(1) | Limit type |
| `AK_LOGIN` | C(25) | User login |

### 4.3 Querying Pending Approvals

```advpl
Static Function fGetPendentes(cAprovador)
    Local cQuery  := ""
    Local cAlias  := GetNextAlias()
    Local aResult := {}

    cQuery := "SELECT CR_NUM, CR_TIPO, CR_TOTAL, CR_EMISSAO, CR_USER "
    cQuery += "FROM " + RetSqlName("SCR") + " SCR "
    cQuery += "WHERE SCR.D_E_L_E_T_ = ' ' "
    cQuery += "AND CR_FILIAL = '" + xFilial("SCR") + "' "
    cQuery += "AND CR_APROV  = '" + cAprovador + "' "
    cQuery += "AND CR_STATUS = '01' "  // Pendente de aprovacao
    cQuery += "ORDER BY CR_EMISSAO, CR_NUM "

    TCQuery cQuery New Alias (cAlias)

    While !(cAlias)->(Eof())
        aAdd(aResult, { ;
            AllTrim((cAlias)->CR_NUM),    ;
            AllTrim((cAlias)->CR_TIPO),   ;
            (cAlias)->CR_TOTAL,           ;
            (cAlias)->CR_EMISSAO,         ;
            AllTrim((cAlias)->CR_USER)    ;
        })
        (cAlias)->(DbSkip())
    EndWh

    (cAlias)->(DbCloseArea())

Return aResult
```

---

## 5. Email - TMailManager and TMailMessage

### 5.1 TMailManager - Server Connection

**Constructor and methods confirmed on TDN:**

| Method | Description |
|--------|-------------|
| `TMailManager():New()` | Creates a new mail manager instance |
| `Init(cServer, cSmtpServer, cUser, cPass, nPop3Port, nSmtpPort)` | Initializes server parameters |
| `SetUseTLS(lUseTLS)` | Enables TLS encryption |
| `SetUseSSL(lUseSSL)` | Enables SSL encryption |
| `SetSmtpTimeOut(nTimeout)` | Sets SMTP timeout in seconds |
| `SmtpConnect()` | Establishes SMTP connection |
| `SmtpAuth(cUser, cPass)` | Authenticates on the SMTP server |
| `SmtpDisconnect()` | Closes the SMTP connection |
| `GetErrorString(nError)` | Returns error description for the given error code |

### 5.2 TMailMessage - Email Composition

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `cFrom` | Character | Sender email address |
| `cTo` | Character | Recipient email address |
| `cCc` | Character | CC recipients |
| `cBcc` | Character | BCC recipients |
| `cSubject` | Character | Email subject |
| `cBody` | Character | Email body (HTML or plain text) |

**Methods:**

| Method | Description |
|--------|-------------|
| `TMailMessage():New()` | Creates a new message instance |
| `Clear()` | Clears all message fields |
| `Send(oServer)` | Sends the message via the TMailManager server object |
| `AttachFile(cFilePath)` | Attaches a file to the message |

### 5.3 Complete Email Sending Example

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} zSendMail
Envia email via SMTP usando TMailManager e TMailMessage
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function zSendMail(cDestinatario, cAssunto, cCorpo)
    Local oServer  := Nil
    Local oMessage := Nil
    Local nRet     := 0
    Local cSmtp    := "smtp.empresa.com"
    Local cUser    := "sistema@empresa.com"
    Local cPass    := "senha123"
    Local nPort    := 587
    Local lRet     := .F.

    // Cria o gerenciador de email
    oServer := TMailManager():New()
    oServer:SetUseTLS(.T.)

    // Inicializa com dados do servidor SMTP
    nRet := oServer:Init("", cSmtp, cUser, cPass, 0, nPort)
    If nRet <> 0
        ConOut("Erro ao inicializar email: " + oServer:GetErrorString(nRet))
        Return .F.
    EndIf

    // Configura timeout
    oServer:SetSmtpTimeOut(60)

    // Conecta ao servidor SMTP
    nRet := oServer:SmtpConnect()
    If nRet <> 0
        ConOut("Erro ao conectar SMTP: " + oServer:GetErrorString(nRet))
        Return .F.
    EndIf

    // Autentica
    nRet := oServer:SmtpAuth(cUser, cPass)
    If nRet <> 0
        ConOut("Erro na autenticacao SMTP: " + oServer:GetErrorString(nRet))
        oServer:SmtpDisconnect()
        Return .F.
    EndIf

    // Monta a mensagem
    oMessage := TMailMessage():New()
    oMessage:Clear()
    oMessage:cFrom    := cUser
    oMessage:cTo      := cDestinatario
    oMessage:cSubject := cAssunto
    oMessage:cBody    := cCorpo

    // Envia
    nRet := oMessage:Send(oServer)
    If nRet <> 0
        ConOut("Erro ao enviar email: " + oServer:GetErrorString(nRet))
    Else
        ConOut("Email enviado com sucesso para: " + cDestinatario)
        lRet := .T.
    EndIf

    // Desconecta
    oServer:SmtpDisconnect()

Return lRet
```

### 5.4 Email with Attachment

```advpl
// Monta mensagem com anexo
oMessage := TMailMessage():New()
oMessage:Clear()
oMessage:cFrom    := "sistema@empresa.com"
oMessage:cTo      := "gestor@empresa.com"
oMessage:cSubject := "Relatorio Diario"
oMessage:cBody    := "<html><body><h2>Relatorio em anexo</h2></body></html>"

// Anexa arquivo
oMessage:AttachFile("/reports/relatorio_diario.pdf")

// Envia
nRet := oMessage:Send(oServer)
```

---

## 6. TMailMng - Modern Email Class

TMailMng is the newer replacement for TMailManager, offering greater configuration flexibility and not depending on the `appserver.ini` Protocol key.

```advpl
// TMailMng usa o protocolo definido diretamente no construtor
// Consulte a documentacao TDN para sintaxe atualizada:
// https://tdn.totvs.com/display/tec/Classe+TMailMng
```

**Note**: TMailMng is confirmed on TDN as a valid replacement class. For production implementations, consult the TDN documentation for the most current constructor syntax and method signatures, as they may vary by Protheus version.

---

## 7. Complete Example - Purchase Order Approval Workflow

This example implements a complete approval workflow: creating a purchase order, checking approval requirements, and sending email notifications.

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} zAprovPC
Fluxo de aprovacao de Pedido de Compras
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function zAprovPC(cNumPC)
    Local aArea    := GetArea()
    Local lAprov   := .F.
    Local cAprov   := ""
    Local nTotal   := 0

    // Busca dados do pedido de compras
    DbSelectArea("SC7")
    DbSetOrder(1)

    If !DbSeek(xFilial("SC7") + cNumPC)
        ConOut("[zAprovPC] Pedido nao encontrado: " + cNumPC)
        RestArea(aArea)
        Return .F.
    EndIf

    nTotal := fTotalPC(cNumPC)

    // Busca aprovador com alcada suficiente
    cAprov := fGetAprovador(nTotal)

    If Empty(cAprov)
        ConOut("[zAprovPC] Nenhum aprovador encontrado para o valor: " + cValToChar(nTotal))
        RestArea(aArea)
        Return .F.
    EndIf

    // Verifica se ja existe aprovacao pendente na SCR
    If fTemAprovPendente(cNumPC, "PC")
        ConOut("[zAprovPC] Pedido ja possui aprovacao pendente.")
        RestArea(aArea)
        Return .F.
    EndIf

    // Registra solicitacao de aprovacao na SCR
    fRegistraAprovacao(cNumPC, "PC", cAprov, nTotal)

    // Envia notificacao por email ao aprovador
    fNotificaAprovador(cAprov, cNumPC, nTotal)

    ConOut("[zAprovPC] Solicitacao de aprovacao registrada para PC: " + cNumPC)

    RestArea(aArea)

Return .T.

// =============================================================
// Calcula o valor total do pedido de compras
// =============================================================
Static Function fTotalPC(cNumPC)
    Local cQuery := ""
    Local cAlias := GetNextAlias()
    Local nTotal := 0

    cQuery := "SELECT SUM(C7_QUANT * C7_PRECO) AS TOTAL "
    cQuery += "FROM " + RetSqlName("SC7") + " SC7 "
    cQuery += "WHERE SC7.D_E_L_E_T_ = ' ' "
    cQuery += "AND C7_FILIAL = '" + xFilial("SC7") + "' "
    cQuery += "AND C7_NUM = '" + cNumPC + "' "

    TCQuery cQuery New Alias (cAlias)

    If !(cAlias)->(Eof())
        nTotal := (cAlias)->TOTAL
    EndIf

    (cAlias)->(DbCloseArea())

Return nTotal

// =============================================================
// Busca aprovador com alcada suficiente
// =============================================================
Static Function fGetAprovador(nValor)
    Local cQuery  := ""
    Local cAlias  := GetNextAlias()
    Local cAprov  := ""

    cQuery := "SELECT AK_COD, AK_NOME, AK_LIMITE "
    cQuery += "FROM " + RetSqlName("SAK") + " SAK "
    cQuery += "WHERE SAK.D_E_L_E_T_ = ' ' "
    cQuery += "AND AK_FILIAL = '" + xFilial("SAK") + "' "
    cQuery += "AND AK_LIMITE >= " + cValToChar(nValor) + " "
    cQuery += "ORDER BY AK_LIMITE "

    TCQuery cQuery New Alias (cAlias)

    If !(cAlias)->(Eof())
        cAprov := AllTrim((cAlias)->AK_COD)
    EndIf

    (cAlias)->(DbCloseArea())

Return cAprov

// =============================================================
// Verifica se existe aprovacao pendente
// =============================================================
Static Function fTemAprovPendente(cNumDoc, cTipoDoc)
    Local lPendente := .F.

    DbSelectArea("SCR")
    DbSetOrder(1)

    If DbSeek(xFilial("SCR") + cNumDoc)
        If AllTrim(SCR->CR_TIPO) == cTipoDoc .And. AllTrim(SCR->CR_STATUS) < "03"
            lPendente := .T.
        EndIf
    EndIf

Return lPendente

// =============================================================
// Registra solicitacao de aprovacao
// =============================================================
Static Function fRegistraAprovacao(cNumDoc, cTipoDoc, cAprov, nTotal)

    DbSelectArea("SCR")

    RecLock("SCR", .T.)
        SCR->CR_FILIAL  := xFilial("SCR")
        SCR->CR_NUM     := cNumDoc
        SCR->CR_TIPO    := cTipoDoc
        SCR->CR_USER    := cUserID  // Usuario logado
        SCR->CR_APROV   := cAprov
        SCR->CR_STATUS  := "01"     // Pendente
        SCR->CR_EMISSAO := Date()
        SCR->CR_TOTAL   := nTotal
    MsUnlock()

Return Nil

// =============================================================
// Notifica aprovador por email
// =============================================================
Static Function fNotificaAprovador(cAprov, cNumPC, nTotal)
    Local cEmail  := ""
    Local cCorpo  := ""

    // Busca email do aprovador
    DbSelectArea("SAK")
    DbSetOrder(1)

    If DbSeek(xFilial("SAK") + cAprov)
        // Busca email do usuario vinculado ao aprovador
        cEmail := fGetEmailUsuario(AllTrim(SAK->AK_USER))
    EndIf

    If Empty(cEmail)
        ConOut("[zAprovPC] Email do aprovador nao encontrado: " + cAprov)
        Return Nil
    EndIf

    // Monta corpo do email
    cCorpo := "<html><body>"
    cCorpo += "<h2>Solicitacao de Aprovacao - Pedido de Compras</h2>"
    cCorpo += "<p>Numero do Pedido: <strong>" + AllTrim(cNumPC) + "</strong></p>"
    cCorpo += "<p>Valor Total: <strong>R$ " + AllTrim(Transform(nTotal, "@E 999,999,999.99")) + "</strong></p>"
    cCorpo += "<p>Data: " + DToC(Date()) + "</p>"
    cCorpo += "<p>Acesse o Protheus para aprovar ou rejeitar este documento.</p>"
    cCorpo += "</body></html>"

    // Envia email (usando funcao do exemplo anterior)
    U_zSendMail(cEmail, "Aprovacao Pendente - PC " + AllTrim(cNumPC), cCorpo)

Return Nil

// =============================================================
// Busca email de um usuario
// =============================================================
Static Function fGetEmailUsuario(cUserId)
    Local cEmail := ""
    Local cQuery := ""
    Local cAlias := GetNextAlias()

    cQuery := "SELECT USR_EMAIL "
    cQuery += "FROM " + RetSqlName("SYS_USR") + " "
    cQuery += "WHERE D_E_L_E_T_ = ' ' "
    cQuery += "AND USR_ID = '" + cUserId + "' "

    TCQuery cQuery New Alias (cAlias)

    If !(cAlias)->(Eof())
        cEmail := AllTrim((cAlias)->USR_EMAIL)
    EndIf

    (cAlias)->(DbCloseArea())

Return cEmail
```

---

## 8. MsExecAuto with Approval Blocking

When a document requires approval, MsExecAuto may block the operation if the approval flow is configured. To handle this:

```advpl
// Antes do MsExecAuto, verificar se o documento necessita aprovacao
// e tratar o retorno adequadamente

Private lMsErroAuto    := .F.
Private lMsHelpAuto    := .T.
Private lAutoErrNoFile := .T.

MsExecAuto({|x, y, z| MATA120(x, y, z)}, aCabec, aItens, 3)

If lMsErroAuto
    Local cErro := MostraErro(.F.)

    // Verifica se o erro e relacionado a aprovacao/alcada
    If "ALCADA" $ Upper(cErro) .Or. "APROV" $ Upper(cErro)
        ConOut("Documento gerado e encaminhado para aprovacao.")
    Else
        ConOut("Erro na geracao do documento: " + cErro)
    EndIf
EndIf
```

---

## 9. FWMVCRotAuto with Approver Validation

Example of using FWMVCRotAuto with pre-validation that checks approver permissions:

```advpl
#Include "TOTVS.CH"
#Include "FWMVCDef.ch"

User Function zMVCAprov()
    Local aHeader := {}
    Local lRet    := .F.
    Local oModel  := Nil

    // Verifica se o usuario atual e aprovador
    If !fIsAprovador(cUserID)
        ConOut("Usuario nao possui permissao de aprovador.")
        Return .F.
    EndIf

    // Posiciona no registro a ser aprovado
    DbSelectArea("ZA1")
    DbSetOrder(1)
    DbSeek(xFilial("ZA1") + "000001")

    // Campos de aprovacao
    aAdd(aHeader, {"ZA1_STATUS", "A", Nil})  // A = Aprovado
    aAdd(aHeader, {"ZA1_DTAPRO", Date(), Nil})
    aAdd(aHeader, {"ZA1_USRAPR", cUserID, Nil})

    lRet := FWMVCRotAuto(oModel, "FATA090", MODEL_OPERATION_UPDATE, {;
        {"ZA1MASTER", aHeader} ;
    })

    If lRet
        ConOut("Documento aprovado com sucesso!")
        // Notifica solicitante
        fNotificaSolicitante("000001", "APROVADO")
    Else
        ConOut("Erro na aprovacao.")
        MostraErro()
    EndIf

Return lRet

Static Function fIsAprovador(cUser)
    Local lAprov := .F.

    DbSelectArea("SAK")
    DbSetOrder(1)

    // Busca aprovador pelo codigo do usuario
    DbGoTop()
    While !Eof()
        If xFilial("SAK") == SAK->AK_FILIAL .And. AllTrim(SAK->AK_USER) == AllTrim(cUser)
            lAprov := .T.
            Exit
        EndIf
        DbSkip()
    EndWh

Return lAprov
```

---

## 10. Best Practices

### 10.1 MsExecAuto
- Always declare `lMsErroAuto`, `lMsHelpAuto`, and `lAutoErrNoFile` as Private before calling.
- Always check `lMsErroAuto` after execution.
- Use `MostraErro(.F.)` to capture error messages as strings.
- Use `GetArea()` / `RestArea()` to preserve table positioning.

### 10.2 Approval Flows
- Use the standard SCR/SAK tables for approval control when possible.
- Always validate approver limits before allowing approval operations.
- Log all approval actions for auditing purposes.

### 10.3 Email Notifications
- Always check the return value of each TMailManager method (0 = success).
- Always call `SmtpDisconnect()` even when errors occur.
- Use TLS/SSL for secure email transmission.
- For high-volume email sending, consider using a background job.
