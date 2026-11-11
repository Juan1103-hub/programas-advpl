# /map <padrão> — Busca rápida no codebase

## Uso
```
/map "MTA110"
/map "FWRest"
/map "RecLock.*Z"
/map "User Function.*OK"
/map "RetSqlName"
```

## O que faz
Executa grep/glob paralelo em:
- `FONTES/` (62 fontes principais)
- `INCLUDES/` (includes binários)
- `PATCHES/PATCH/` + `PATCHES/PATCH_01/`

## Output
```
## Resultados para "MTA110"

### FONTES/
- MTA110OK.PRW:12  → User Function MTA110OK()
- MTA110INC.PRW:8  → User Function MTA110INC()
- MTA110DEL.PRW:15 → User Function MTA110DEL()
- MTA110BRW.PRW:22 → User Function MTA110BRW()

### PATCHES/PATCH_01/
- MT110TOK.PRW:5   → User Function MT110TOK()

### INCLUDES/
- _binary_functions.prw:145 → Static Function MTA110_GetDefaults()
```

## Dicas
- Use regex: `/map "C7_QUANT.*<"` → acha comparações
- Combine: `/map "MSExecAuto.*SC7"` → acha usos core
- Para símbolos TLPP: `/map "using namespace.*totvs"`