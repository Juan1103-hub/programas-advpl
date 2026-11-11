# /review <arquivo> — Code review SonarQube + padrões AdvPL

## Uso
```
/review MTA110OK.PRW
/review "FONTES/*.prw"
/review ZC7DATAENT.tlpp --level high
```

## Níveis
- `--level low` (padrão): CRITICAL + MAJOR apenas
- `--level high`: CRITICAL + MAJOR + MINOR + INFO (recomendado para PR)
- `--level ultra`: multi-agent deep review (precisa conta claude.ai)

## Regras verificadas (SonarQube G1–G5 + AdvPL)

### Security (G1)
- CA2050: SQL Injection (concatenação direta)
- CA2051: SQL Injection via parâmetro
- CA2052: SQL Injection via variável
- CA2053: Command Injection

### Reliability (G2)
- CA1000: ISAM/MSCREATE/DBCREATE/CRIATRAB → FWTemporaryTable
- CA1002: UI em transação (MsgAlert, MsgYesNo, Aviso, Help, Pergunte)
- CA1004: ConOut/OutErr/? → FWLogMsg
- CA1005: GetMV/SuperGetMV/ExistBlock/Type/Pergunte em loop

### Maintainability (G3)
- CA4000: IIF → If/Else/EndIf
- CA4001: Function proibido → User Function/Static Function
- CA4002: Encoding não CP-1252
- CA4003: cFilial direta → FWxFilial/xFilial

### AdvPL Específicas (G4)
- Hungarão obrigatório (prefixos c/n/d/l/a/o/b/x/j)
- Entry Point naming (arquivo = nome PE, sem U_, maiúsculo)
- RecLock só em Z* (core = MSExecAuto + GetArea/RestArea)
- Destroy() da class (não FwFetchObj/FreeObj)
- Includes: totvs.ch (novo), Protheus.ch (legado mantém)
- TLPP: `as` após atribuição, `using namespace` obrigatório

### Performance (G5)
- %nolock% em SELECT
- RetSqlName() em tabela física
- FWExecStatement/ChangeQuery (anti-injection + plan cache)
- Índices alinhados (SC7_FILIAL + C7_NUM + C7_ITEM)

## Output
```
## Review: MTA110OK.PRW (high)

### CRITICAL (0)
—

### MAJOR (2)
1. CA2050 — Linha 45: SQL Injection — concatenação direta cNum
   Fix: Use FWExecStatement + RetSqlName + FWxFilial + cValToChar
2. CA1002 — Linha 78: MsgAlert dentro de transação (RecLock ativo)
   Fix: Mova validação para antes do RecLock ou use FWLogMsg

### MINOR (1)
1. CA4003 — Linha 12: cFilial direta → FWxFilial("SC7")

### INFO (3)
1. CA4001 — Linha 5: Function MTA110OK_Helper() → Static Function
2. Hungarian — Linha 22: variável `quant` sem prefixo `n`
3. TLPP — Linha 5: `as Character := ""` → `:= "" as Character`

### Aprovado: NÃO (2 MAJOR)
```