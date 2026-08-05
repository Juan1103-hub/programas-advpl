---
name: protheus-reference
description: Use when looking up Protheus native functions, SX data dictionary tables, REST API endpoints, MV parameters, or TOTVS framework documentation
---

# Protheus Reference

## Overview

Reference guide for the TOTVS Protheus ecosystem. Provides quick access to native functions, data dictionary (SX tables), REST API endpoints, and system parameters (MV_*).

## When to Use

- Looking up native function syntax, parameters, or return values
- Understanding SX data dictionary structure (SX1 through SX9, SIX)
- Finding REST API endpoints for Protheus integration
- Checking MV_* parameter purpose and default values
- Understanding .ini configuration files (appserver.ini, smartclient.ini)

## Lookup Strategy

```dot
digraph lookup {
    "Need function/API info?" [shape=diamond];
    "Check native-functions.md" [shape=box];
    "Found?" [shape=diamond];
    "Return result" [shape=box];
    "Search TDN online" [shape=box];
    "WebSearch: site:tdn.totvs.com <term>" [shape=box];
    "Fetch failed?" [shape=diamond];
    "Playwright fallback" [shape=box];

    "Need function/API info?" -> "Check native-functions.md";
    "Check native-functions.md" -> "Found?";
    "Found?" -> "Return result" [label="yes"];
    "Found?" -> "Search TDN online" [label="no"];
    "Search TDN online" -> "WebSearch: site:tdn.totvs.com <term>";
    "WebSearch: site:tdn.totvs.com <term>" -> "Fetch failed?";
    "Fetch failed?" -> "Return result" [label="no"];
    "Fetch failed?" -> "Playwright fallback" [label="yes"];
    "Playwright fallback" -> "Return result";
}
```

1. **Local first:** Check supporting files (native-functions.md, sx-dictionary.md, rest-api-reference.md)
2. **Online fallback:** Search TDN with `WebSearch` using query: `site:tdn.totvs.com <function_name>`
3. **WebFetch TDN page:** If URL found, use `WebFetch` to extract details
4. **Playwright fallback:** Se `WebSearch` ou `WebFetch` falhar, use Playwright MCP:
   - `browser_navigate` para a URL do TDN (se disponível) ou buscar em `https://tdn.totvs.com`
   - `browser_snapshot` para extrair texto; se insuficiente, `browser_take_screenshot` para captura visual
   - `browser_close` ao finalizar para liberar recursos

## CRITICAL: Restricted Functions Check

**Before recommending any function, ALWAYS check if it appears in `restricted-functions.md`.** TOTVS maintains a list of 195+ functions/classes that are internal property and MUST NOT be used in custom code. Some have their compilation blocked since release 12.1.33.

See `restricted-functions.md` for the complete list and supported alternatives.

## Function Categories

| Category | Common Functions | File Reference |
|----------|-----------------|----------------|
| String | Alltrim, SubStr, StrTran, Pad*, Upper, Lower | native-functions.md |
| Date/Time | dDataBase, DtoS, StoD, Day, Month, Year | native-functions.md |
| Array | aAdd, aDel, aSize, aScan, aSort, aClone | native-functions.md |
| Database | DbSelectArea, DbSetOrder, DbSeek, RecLock, MsUnlock | native-functions.md |
| Interface | MsgInfo, MsgYesNo, MsgAlert, FWExecView, Enchoice | native-functions.md |
| File I/O | FOpen, FRead, FWrite, FClose, FErase, Directory | native-functions.md |
| Network | HttpGet, HttpPost, FWRest, WsRestFul | native-functions.md |
| System | GetMV, PutMV, SuperGetMV, Conout, FWLogMsg | native-functions.md |
| Company/Branch | FWCodFil, FWCodEmp, FWFilial, FWCompany, xFilial | native-functions.md |
| JsonObject | New, FromJSON, toJSON, GetNames, HasProperty, GetJsonObject, GetJsonText, GetJsonValue, DelName, Set | native-functions.md |
| TWsdlManager | New, ParseURL, ParseFile, SetOperation, SendSoapMsg, GetParsedResponse, GetSoapResponse, GetSoapMsg, ListOperations, SetPort, SetValue | native-functions.md |
| Browse/UI | FwBrowse, FWMarkBrowse, FWBrwColumn, FWBrwRelation, FWLegend, FWCalendar, FWSimpEdit | native-functions.md |
| Process | FWGridProcess, tNewProcess | native-functions.md |
| WorkArea | FwGetArea, FwRestArea | native-functions.md |
| User | FwGetUserName, UsrRetName | native-functions.md |
| Dialog | FWMsgRun, FWInputBox | native-functions.md |
| Memory | FWFreeObj, FWFreeVar | native-functions.md |
| Date ISO | Fw8601ToDate, FWDateTo8601 | native-functions.md |
| URL Encode | FWHttpEncode, FWURIDecode | native-functions.md |
| Semaphore | MayIUseCode, MPCriaNumS | native-functions.md |
| Dictionary | FWX3Titulo, FWX2CHAVE, FWX2Unico | native-functions.md |
| Interface | SaveInter, RestInter | native-functions.md |
| ExecAuto | MsGetDAuto, MsExecAuto, FWMVCRotAuto | native-functions.md |
| Restricted | StaticCall, PTInternal, PARAMBOX, etc. | restricted-functions.md |

## Data Dictionary Quick Reference

| Table | Purpose |
|-------|---------|
| SX1 | Perguntas (parameters for reports/routines) |
| SX2 | Tabelas (table definitions) |
| SX3 | Campos (field definitions) |
| SX5 | Tabelas genericas (generic lookup tables) |
| SX6 | Parametros (MV_* system parameters) |
| SX7 | Gatilhos (field triggers) |
| SX9 | Relacionamentos (table relationships) |
| SXB | Consultas padrao (standard queries) |
| SIX | Indices (index definitions) |

See `sx-dictionary.md` for complete structure with field descriptions.

## REST API Patterns

Protheus REST APIs follow two main patterns:

1. **FWRest Framework** (newer): Annotation-based with `@Get`, `@Post`, `@Put`, `@Delete`
2. **WsRestFul** (legacy): Class-based with `wsmethod`

See `rest-api-reference.md` for endpoint patterns and authentication.

## Online Search Tips

When searching TDN (TOTVS Developer Network):
- Use `WebSearch` with query: `site:tdn.totvs.com <function_name> advpl`
- For API docs: `site:tdn.totvs.com rest api <endpoint_name>`
- For release notes: `site:tdn.totvs.com <feature> release notes`
- TDN base URL: `https://tdn.totvs.com`
