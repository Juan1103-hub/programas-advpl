# Protheus SOAP Web Service Patterns

Patterns for exposing and consuming SOAP Web Services in TOTVS Protheus. SOAP in Protheus is exclusive to `.prw` files — there is no TLPP equivalent.

---

## 1. Exposing SOAP Web Services (WsService)

The `WsService` approach defines SOAP services with typed attributes and methods. The Protheus AppServer automatically generates the WSDL.

### 1.1 Includes

```advpl
#Include "TOTVS.CH"
#Include "APWebSrv.ch"
```

**Both includes are required** for exposing SOAP services.

### 1.2 Service Declaration

```advpl
#Include "TOTVS.CH"
#Include "APWebSrv.ch"

/*/{Protheus.doc} zWSClientes
Web Service SOAP para operacoes com clientes
@type WsService
@author Autor
@since 01/01/2026
@version 1.0
/*/
WsService zWSClientes Description "WebService de Clientes"

    // Atributos de entrada/saida
    WsData cViewRece As String
    WsData cViewSend As String
    WsData cNewRece  As String
    WsData cNewSend  As String
    WsData cDelRece  As String
    WsData cDelSend  As String

    // Metodos expostos
    WsMethod ViewCli Description "Consultar cliente por codigo ou CGC"
    WsMethod NewCli  Description "Incluir novo cliente"
    WsMethod DelCli  Description "Excluir cliente por codigo"

EndWsService
```

### 1.3 WsData Types

| Type | ADVPL Equivalent | Example |
|------|-----------------|---------|
| `String` | Character | `WsData cNome As String` |
| `Integer` | Numeric (integer) | `WsData nQtd As Integer` |
| `Float` | Numeric (decimal) | `WsData nValor As Float` |
| `Boolean` | Logical | `WsData lAtivo As Boolean` |
| `Date` | Date | `WsData dEmissao As Date` |

### 1.4 WsMethod Syntax

```advpl
WsMethod <MethodName> WsReceive <param1>, <param2> WsSend <paramOut> WsService <ServiceName>
```

- `WsReceive` — attributes that the method receives (input)
- `WsSend` — attribute that the method returns (output)
- `WsService` — name of the service this method belongs to
- All parameters must be declared as `WsData` in the service

### 1.5 Method Implementation: Query (ViewCli)

```advpl
/*/{Protheus.doc} WsMethod ViewCli
Consulta informacoes de um cliente por codigo ou CGC
@type WsMethod
@author Autor
@since 01/01/2026
@param cViewRece, Caractere, Codigo ou CGC do cliente
@return cViewSend, Caractere, JSON com dados do cliente
/*/
WsMethod ViewCli WsReceive cViewRece WsSend cViewSend WsService zWSClientes
    Local aArea     := FWGetArea()
    Local lRet      := .T.
    Local cBusca    := AllTrim(::cViewRece)
    Local nIndice   := 0
    Local cCGC      := ""
    Local cMascCPF  := "@R 999.999.999-99"
    Local cMascCNPJ := "@R 99.999.999/9999-99"
    Local jResponse := JsonObject():New()

    // Normalizar entrada (remover pontuacao)
    cBusca := StrTran(cBusca, ".", "")
    cBusca := StrTran(cBusca, "/", "")
    cBusca := StrTran(cBusca, "-", "")

    // Determinar indice de busca
    If Len(cBusca) == 14 .Or. Len(cBusca) == 11
        nIndice := 3 // A1_FILIAL + A1_CGC
    Else
        nIndice := 1 // A1_FILIAL + A1_COD + A1_LOJA
    EndIf

    DbSelectArea("SA1")
    SA1->(DbSetOrder(nIndice))

    If SA1->(MsSeek(FWxFilial("SA1") + cBusca))
        cCGC := AllTrim(SA1->A1_CGC)

        jResponse["status"]  := "Cliente encontrado"
        jResponse["codigo"]  := AllTrim(SA1->A1_COD) + AllTrim(SA1->A1_LOJA)
        jResponse["nome"]    := AllTrim(SA1->A1_NOME)
        jResponse["email"]   := AllTrim(SA1->A1_EMAIL)

        If Len(cCGC) == 14
            jResponse["cnpj"] := AllTrim(Transform(cCGC, cMascCNPJ))
        ElseIf Len(cCGC) == 11
            jResponse["cpf"]  := AllTrim(Transform(cCGC, cMascCPF))
        EndIf
    Else
        jResponse["status"] := "Cliente nao encontrado com a chave fornecida"
    EndIf

    ::cViewSend := jResponse:ToJson()

    FreeObj(jResponse)
    FWRestArea(aArea)
Return lRet
```

### 1.6 Method Implementation: Create (NewCli)

```advpl
/*/{Protheus.doc} WsMethod NewCli
Inclui um novo cliente via JSON
@type WsMethod
@author Autor
@since 01/01/2026
@param cNewRece, Caractere, JSON com dados do cliente
@return cNewSend, Caractere, JSON com resultado da inclusao
/*/
WsMethod NewCli WsReceive cNewRece WsSend cNewSend WsService zWSClientes
    Local aArea    := FWGetArea()
    Local lRet     := .T.
    Local jRecebe  := JsonObject():New()
    Local jResp    := JsonObject():New()
    Local cError   := ""
    Local aDados   := {}
    Local aLogAuto := {}
    Local cErrorLog := ""
    Local nLinha   := 0
    Private lMsHelpAuto    := .T.
    Private lAutoErrNoFile := .T.
    Private lMsErroAuto    := .F.

    // Parse do JSON de entrada
    cError := jRecebe:FromJson(::cNewRece)

    If !Empty(cError)
        jResp["errorId"]  := "NEW001"
        jResp["error"]    := "Erro no parse do JSON"
        jResp["solution"] := "Verifique a estrutura do JSON enviado"
        ::cNewSend := jResp:ToJson()
        FreeObj(jRecebe)
        FreeObj(jResp)
        FWRestArea(aArea)
        Return lRet
    EndIf

    // Validacao de campos obrigatorios
    If Empty(jRecebe:GetJsonObject("cod"))  .Or. ;
       Empty(jRecebe:GetJsonObject("loja")) .Or. ;
       Empty(jRecebe:GetJsonObject("nome")) .Or. ;
       Empty(jRecebe:GetJsonObject("tipo"))

        jResp["errorId"]  := "NEW002"
        jResp["error"]    := "Campos obrigatorios ausentes"
        jResp["solution"] := "Envie: cod, loja, nome, tipo"
        ::cNewSend := jResp:ToJson()
        FreeObj(jRecebe)
        FreeObj(jResp)
        FWRestArea(aArea)
        Return lRet
    EndIf

    // Montar array para MsExecAuto
    aAdd(aDados, {"A1_COD",    jRecebe:GetJsonObject("cod"),    Nil})
    aAdd(aDados, {"A1_LOJA",   jRecebe:GetJsonObject("loja"),   Nil})
    aAdd(aDados, {"A1_NOME",   jRecebe:GetJsonObject("nome"),   Nil})
    aAdd(aDados, {"A1_TIPO",   jRecebe:GetJsonObject("tipo"),   Nil})

    If !Empty(jRecebe:GetJsonObject("end"))
        aAdd(aDados, {"A1_END", jRecebe:GetJsonObject("end"), Nil})
    EndIf
    If !Empty(jRecebe:GetJsonObject("mun"))
        aAdd(aDados, {"A1_MUN", jRecebe:GetJsonObject("mun"), Nil})
    EndIf
    If !Empty(jRecebe:GetJsonObject("est"))
        aAdd(aDados, {"A1_EST", jRecebe:GetJsonObject("est"), Nil})
    EndIf

    // Executar inclusao via ExecAuto
    MsExecAuto({|x, y| CRMA980(x, y)}, aDados, 3)

    If lMsErroAuto
        aLogAuto := GetAutoGrLog()
        For nLinha := 1 To Len(aLogAuto)
            cErrorLog += aLogAuto[nLinha] + CRLF
        Next nLinha

        Conout("zWSClientes:NewCli - Erro: " + cErrorLog)

        jResp["errorId"]  := "NEW003"
        jResp["error"]    := "Erro na inclusao do registro"
        jResp["solution"] := cErrorLog
    Else
        jResp["note"] := "Registro incluido com sucesso"
    EndIf

    ::cNewSend := jResp:ToJson()

    FreeObj(jRecebe)
    FreeObj(jResp)
    FWRestArea(aArea)
Return lRet
```

### 1.7 Method Implementation: Delete (DelCli)

```advpl
/*/{Protheus.doc} WsMethod DelCli
Exclui um cliente por codigo
@type WsMethod
@author Autor
@since 01/01/2026
@param cDelRece, Caractere, Codigo do cliente (cod+loja)
@return cDelSend, Caractere, JSON com resultado da exclusao
/*/
WsMethod DelCli WsReceive cDelRece WsSend cDelSend WsService zWSClientes
    Local aArea   := FWGetArea()
    Local lRet    := .T.
    Local cBusca  := AllTrim(::cDelRece)
    Local jResp   := JsonObject():New()
    Local aDados  := {}
    Private lMsHelpAuto    := .T.
    Private lAutoErrNoFile := .T.
    Private lMsErroAuto    := .F.

    DbSelectArea("SA1")
    SA1->(DbSetOrder(1))

    If !SA1->(MsSeek(FWxFilial("SA1") + cBusca))
        jResp["errorId"] := "DEL001"
        jResp["error"]   := "Cliente nao encontrado: " + cBusca
        ::cDelSend := jResp:ToJson()
        FreeObj(jResp)
        FWRestArea(aArea)
        Return lRet
    EndIf

    aAdd(aDados, {"A1_COD",  SA1->A1_COD,  Nil})
    aAdd(aDados, {"A1_LOJA", SA1->A1_LOJA, Nil})

    MsExecAuto({|x, y| CRMA980(x, y)}, aDados, 5)

    If lMsErroAuto
        jResp["errorId"] := "DEL002"
        jResp["error"]   := "Erro na exclusao do registro"
    Else
        jResp["note"] := "Registro excluido com sucesso"
    EndIf

    ::cDelSend := jResp:ToJson()

    FreeObj(jResp)
    FWRestArea(aArea)
Return lRet
```

### 1.8 Accessing the WSDL

After compiling the service and starting the AppServer, the WSDL is available at:

```
http://<server>:<port>/ws/<ServiceName>.apw?WSDL
```

Example:
```
http://localhost:8091/ws/ZWSCLIENTES.apw?WSDL
```

The WSDL index page listing all services:
```
http://localhost:8091/ws/WSINDEX.apw
```

### 1.9 appserver.ini Configuration

```ini
[HTTPSERVER]
Enable=1
Port=8091

[HTTPENV]
Environment=ENVIRONMENT_NAME
```

---

## 2. Consuming SOAP Web Services (TWsdlManager)

Use `TWsdlManager` to call external SOAP services from ADVPL.

### 2.1 Include

```advpl
#Include "TOTVS.CH"
```

Only `TOTVS.CH` is needed — `TWsdlManager` is a native Protheus class.

### 2.2 Basic Flow: Load WSDL, Call Operation, Read Response

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} ConsumeWS
Exemplo de consumo de Web Service SOAP via TWsdlManager
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function ConsumeWS()
    Local oWsdl    := TWsdlManager():New()
    Local cUrl     := "http://127.0.0.1:8091/ws/ZWSCLIENTES.apw?WSDL"
    Local cResp    := ""
    Local cMsgWs   := ""
    Local lRet     := .F.

    // Configurar timeout (segundos)
    oWsdl:nTimeout := 120

    // Desabilitar verificacao de certificado SSL (apenas para testes)
    oWsdl:bNoCheckPeerCert := .T.

    // Carregar WSDL
    If !oWsdl:ParseURL(cUrl)
        Conout("Erro ao carregar WSDL: " + oWsdl:cError)
        Return lRet
    EndIf

    // Selecionar operacao
    If !oWsdl:SetOperation("VIEWCLI")
        Conout("Erro ao selecionar operacao: " + oWsdl:cError)
        Return lRet
    EndIf

    // Montar envelope SOAP
    cMsgWs := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://localhost/">'
    cMsgWs += '  <soapenv:Header/>'
    cMsgWs += '  <soapenv:Body>'
    cMsgWs += '    <ws:VIEWCLI>'
    cMsgWs += '      <ws:CVIEWRECE>000001</ws:CVIEWRECE>'
    cMsgWs += '    </ws:VIEWCLI>'
    cMsgWs += '  </soapenv:Body>'
    cMsgWs += '</soapenv:Envelope>'

    // Enviar requisicao
    If oWsdl:SendSoapMsg(cMsgWs)
        cResp := oWsdl:GetParsedResponse()

        If !Empty(cResp)
            Conout("Resposta: " + cResp)
            lRet := .T.
        Else
            Conout("Resposta vazia")
        EndIf
    Else
        Conout("Erro ao enviar SOAP: " + oWsdl:cError)
    EndIf

Return lRet
```

### 2.3 Listing Available Operations

```advpl
User Function ListOps()
    Local oWsdl  := TWsdlManager():New()
    Local cUrl   := "http://127.0.0.1:8091/ws/ZWSCLIENTES.apw?WSDL"
    Local aOps   := {}
    Local nI     := 0

    oWsdl:nTimeout := 60

    If !oWsdl:ParseURL(cUrl)
        Conout("Erro: " + oWsdl:cError)
        Return
    EndIf

    // Listar operacoes do servico
    Conout("Operacoes disponiveis:")
    aOps := oWsdl:ListOperations()
    For nI := 1 To Len(aOps)
        Conout("  " + aOps[nI])
    Next nI

Return
```

### 2.4 Error Handling

```advpl
User Function ConsumeWSSafe()
    Local oWsdl  := TWsdlManager():New()
    Local cUrl   := "http://api.externa.com/service?WSDL"
    Local cResp  := ""
    Local cFault := ""
    Local cMsgWs := ""

    oWsdl:nTimeout := 30
    oWsdl:bNoCheckPeerCert := .T.

    // Carregar WSDL com tratamento
    If !oWsdl:ParseURL(cUrl)
        FWLogMsg("ERROR", , "ConsumeWS", "ParseURL", , , ;
            "Falha ao carregar WSDL: " + cUrl + " - " + oWsdl:cError)
        Return .F.
    EndIf

    If !oWsdl:SetOperation("OPERACAO")
        FWLogMsg("ERROR", , "ConsumeWS", "SetOperation", , , ;
            "Operacao nao encontrada: OPERACAO")
        Return .F.
    EndIf

    // Montar e enviar
    cMsgWs := fMontaEnvelope()

    If !oWsdl:SendSoapMsg(cMsgWs)
        FWLogMsg("ERROR", , "ConsumeWS", "SendSoapMsg", , , ;
            "Falha no envio SOAP: " + oWsdl:cError)
        Return .F.
    EndIf

    // Verificar SOAP Fault via propriedades
    If !Empty(oWsdl:cFaultCode)
        FWLogMsg("ERROR", , "ConsumeWS", "SoapFault", , , ;
            "SOAP Fault: [" + oWsdl:cFaultCode + "] " + oWsdl:cFaultString)
        Return .F.
    EndIf

    // Ler resposta
    cResp := oWsdl:GetParsedResponse()

    If Empty(cResp)
        FWLogMsg("WARN", , "ConsumeWS", "Response", , , ;
            "Resposta vazia do servico")
        Return .F.
    EndIf

    // Processar resposta (pode ser XML ou texto)
    Conout("Resposta: " + cResp)

Return .T.

Static Function fMontaEnvelope()
    Local cMsg := ""
    cMsg := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://target/">'
    cMsg += '  <soapenv:Header/>'
    cMsg += '  <soapenv:Body>'
    cMsg += '    <ws:OPERACAO>'
    cMsg += '      <ws:PARAMETRO>valor</ws:PARAMETRO>'
    cMsg += '    </ws:OPERACAO>'
    cMsg += '  </soapenv:Body>'
    cMsg += '</soapenv:Envelope>'
Return cMsg
```

### 2.5 TWsdlManager Key Properties and Methods

| Property/Method | Type | Description |
|-----------------|------|-------------|
| `nTimeout` | Property | Timeout in seconds (default: 120) |
| `bNoCheckPeerCert` | Property | `.T.` to skip SSL certificate validation |
| `cError` | Property | Last error message |
| `ParseURL(cUrl)` | Method | Load WSDL from URL. Returns `.T.`/`.F.` |
| `ParseFile(cPath)` | Method | Load WSDL from local file. Returns `.T.`/`.F.` |
| `SetOperation(cOp)` | Method | Select the operation to call. Returns `.T.`/`.F.` |
| `SendSoapMsg(cXml)` | Method | Send SOAP envelope. Returns `.T.`/`.F.` |
| `GetParsedResponse()` | Method | Get the parsed response body |
| `GetSoapResponse()` | Method | Get the raw SOAP XML response |
| `GetSoapMsg()` | Method | Get the SOAP message that will be/was sent |
| `ListOperations()` | Method | List operations for the current service |
| `SetPort(cPort)` | Method | Select a service port from the WSDL |
| `SetValue(cParam, cValue)` | Method | Set input parameter value |
| `SimpleInput(cField)` | Method | Navigate to a simple input field |
| `cFaultCode` | Property | SOAP Fault code (check after SendSoapMsg) |
| `cFaultSubCode` | Property | SOAP Fault sub-code |
| `cFaultString` | Property | SOAP Fault description message |
| `cFaultActor` | Property | SOAP Fault actor |
| `lProcResp` | Property | `.T.` to auto-process response (default `.T.`) |

---

## 3. SOAP vs REST — When to Use Each

| Aspect | SOAP (WsService) | REST (WsRestFul / TLPP) |
|--------|-------------------|------------------------|
| Protocol | XML over HTTP | JSON over HTTP |
| Contract | WSDL (strict) | Documentation (flexible) |
| Use case | Enterprise integration, legacy systems, NFe/NFSe | Modern APIs, mobile, SPA |
| Complexity | Higher (XML, envelope, WSDL) | Lower (JSON, HTTP verbs) |
| Performance | Heavier (XML parsing) | Lighter (JSON) |
| TLPP support | No (`.prw` only) | Yes (`.prw` and `.tlpp`) |
| Error format | SOAP Fault (XML) | HTTP status + JSON |
| When to choose | Integrating with systems that require SOAP (banks, government, NFe) | New APIs, internal integration, mobile apps |

**Rule of thumb:** Use REST for new development. Use SOAP only when the external system requires it.

---

## 4. Common Errors and Troubleshooting

### 4.1 WSDL Not Found (404)

**Error:** `http://server:port/ws/SERVICE.apw?WSDL` returns 404

**Causes:**
- Service not compiled into RPO
- `[HTTPSERVER]` not configured in `appserver.ini`
- Service name in URL does not match `WsService` declaration (case-sensitive)

**Solution:**
```ini
; appserver.ini
[HTTPSERVER]
Enable=1
Port=8091
```
Recompile the `.prw` file and restart the AppServer.

### 4.2 ParseURL Fails

**Error:** `oWsdl:ParseURL()` returns `.F.`

**Causes:**
- Network unreachable or timeout
- Invalid WSDL URL
- SSL certificate issue

**Solution:**
```advpl
// Increase timeout
oWsdl:nTimeout := 300

// Disable SSL check for testing
oWsdl:bNoCheckPeerCert := .T.

// Try loading from local file instead
If !oWsdl:ParseURL(cUrl)
    Conout("ParseURL failed: " + oWsdl:cError)
    // Save WSDL manually and use ParseFile
    // oWsdl:ParseFile("C:\temp\service.wsdl")
EndIf
```

### 4.3 SOAP Fault Response

**Error:** The service returns a SOAP Fault instead of the expected response.

**Solution:**
```advpl
If oWsdl:SendSoapMsg(cMsgWs)
    // Check SOAP Fault via properties (NOT via GetSoapFault which does not exist)
    If !Empty(oWsdl:cFaultCode)
        Conout("SOAP Fault Code: " + oWsdl:cFaultCode)
        Conout("SOAP Fault Msg:  " + oWsdl:cFaultString)
        // Also check the raw response for details
        Conout("Raw XML: " + oWsdl:GetSoapResponse())
    Else
        cResp := oWsdl:GetParsedResponse()
    EndIf
EndIf
```

### 4.4 Empty Response

**Error:** `GetParsedResponse()` returns empty string.

**Causes:**
- Wrong operation name
- Missing or wrong parameters in the envelope
- Server error not returned as SOAP Fault

**Solution:**
```advpl
// Check the raw SOAP response
Local cRawXml := oWsdl:GetSoapMsg()
Conout("Raw response: " + cRawXml)

// Verify operation name matches exactly (case-sensitive)
// Verify namespace in envelope matches the WSDL target namespace
```

### 4.5 SSL Certificate Error

**Error:** Connection fails with SSL/TLS error.

**Solution:**
```advpl
// For testing only — disable certificate verification
oWsdl:bNoCheckPeerCert := .T.

// For production — configure certificates in appserver.ini:
// [SSLConfigure]
// CertificateClient=cert\client.pem
// KeyClient=cert\client.key
```

---

## 5. Best Practices

| Practice | Description |
|----------|-------------|
| Always use `FWGetArea()` / `FWRestArea()` | Preserve work area state in every WsMethod |
| Validate input before processing | Check required fields and data format |
| Return structured responses | Use JSON via `JsonObject` for consistent output |
| Log errors with context | Use `FWLogMsg` or `Conout` with service/method name |
| Set appropriate timeout | Default 120s may be too long or short — adjust per service |
| Handle SOAP Faults explicitly | Always check `cFaultCode`/`cFaultString` properties after `SendSoapMsg()` |
| Use `MsExecAuto` for data operations | Triggers standard Protheus validations and workflows |
| Do NOT use `Private` variables in new code | Exception: `lMsHelpAuto`, `lAutoErrNoFile`, `lMsErroAuto` required by `MsExecAuto` |
| Name services with `z` prefix | Convention for custom services: `zWSClientes`, `zWSPedidos` |
| Keep methods focused | One operation per method — avoid methods that do multiple things |
