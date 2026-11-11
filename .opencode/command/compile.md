# /compile <arquivo> — UTF-8 → CP1252 → RDMake no AppServer

## Uso
```
/compile MTA110OK.PRW
/compile ZC7DATAENT.tlpp
/compile "FONTES/*.prw"
```

## Fluxo
1. **utf8-to-cp1252-conversion** no(s) arquivo(s)
   - Converte BOM UTF-8 → CP-1252
   - Valida caracteres não-mapeáveis (ã, õ, ç, acentos)
2. **advpl-tlpp-compile** via `advpls.exe` no AppServer `CINVJ6_DEV`
   - `C:\totvs\advpls.exe -compile ${file} -server CINVJ6_DEV -includes C:\totvs\includes`
3. **Output**: sucesso + warnings / erro com linha

## Configuração (servers.json)
```json
{
  "CINVJ6_DEV": {
    "host": "vortice192877.protheus.cloudtotvs.com.br",
    "port": 10771,
    "build": "7.00.240223P",
    "includes": "C:\\totvs\\includes",
    "rpo": "C:\\totvs\\rpo"
  }
}
```

## Erros comuns
| Erro | Causa | Fix |
|------|-------|-----|
| `Syntax error` | UTF-8 não convertido | Rode `utf8-to-cp1252-conversion` antes |
| `Undefined symbol FWRest` | Include faltando | Adicione `#include "totvs.ch"` |
| `Table SC7 not found` | Alias não aberto | `DbSelectArea("SC7")` antes |
| `RecLock failed` | Tabela core sem MSExecAuto | Use `MSExecAuto({|x| ... }, "SC7")` |

## Pós-compile
- Se warnings SonarQube → rode `/review ${file}`
- Se novo arquivo → considere `/specify` para documentar