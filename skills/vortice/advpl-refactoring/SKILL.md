---
name: advpl-refactoring
description: Use when refactoring ADVPL/TLPP code - extract functions, simplify logic, remove dead code, improve naming
---

# ADVPL/TLPP Refactoring

## Overview

Patterns and rules for safe refactoring of ADVPL/TLPP code on TOTVS Protheus. Focuses on improving code structure without changing behavior.

## When to Use

- Functions too long (>100 lines)
- Duplicated code across files or functions
- Complex nested conditionals (>3 levels deep)
- Variables with unclear names
- Dead code (unreachable blocks, unused variables/functions)
- God functions that do too many things

## Refactoring Patterns

### RF-001: Extract Function (Complexity: LOW)

**Detect:** Function body > 100 lines with identifiable logical blocks
**Action:** Extract logical block into a new Static Function
**Rule:** The extracted function must receive all needed data as parameters (no shared Private/Public)

Before:
```advpl
User Function ProcessaPedido()
    // ... 40 lines validating data ...
    // ... 30 lines calculating totals ...
    // ... 50 lines saving to database ...
Return
```

After:
```advpl
User Function ProcessaPedido()
    If !fValidaDados(cCodPed)
        Return .F.
    EndIf
    nTotal := fCalculaTotais(cCodPed)
    lOk := fGravaPedido(cCodPed, nTotal)
Return lOk

Static Function fValidaDados(cCodPed)
    // 40 lines
Return lValido

Static Function fCalculaTotais(cCodPed)
    // 30 lines
Return nTotal

Static Function fGravaPedido(cCodPed, nTotal)
    // 50 lines
Return lOk
```

### RF-002: Simplify Conditionals (Complexity: LOW)

**Detect:** Nested If > 3 levels deep, or long If/ElseIf chains
**Action:** Use early return, guard clauses, or Do Case

Before:
```advpl
If lCondicao1
    If lCondicao2
        If lCondicao3
            // codigo principal
        EndIf
    EndIf
EndIf
```

After:
```advpl
If !lCondicao1
    Return
EndIf
If !lCondicao2
    Return
EndIf
If !lCondicao3
    Return
EndIf
// codigo principal
```

### RF-003: Remove Dead Code (Complexity: LOW)

**Detect:** Variables declared but never used, unreachable code after Return, commented-out blocks
**Action:** Remove the dead code entirely
**Rule:** Use Grep to verify the variable/function is not called from other files before removing

### RF-004: Improve Naming (Complexity: LOW)

**Detect:** Variables without Hungarian notation, single-letter names (except loop counters), unclear names
**Action:** Rename following Hungarian notation convention

| Type | Prefix | Example |
|------|--------|---------|
| Character | c | cNomeCli, cCodProd |
| Numeric | n | nValor, nQtde |
| Logical | l | lOk, lContinua |
| Date | d | dDataIni, dEmissao |
| Array | a | aDados, aItens |
| Object | o | oModel, oReport |
| Block | b | bBloco, bFiltro |

### RF-005: Eliminate Duplication (Complexity: MEDIUM)

**Detect:** Two or more code blocks with >5 similar lines
**Action:** Extract common logic into a shared function
**Rule:** Only extract if the logic is truly identical, not just visually similar

### RF-006: Reduce Function Parameters (Complexity: MEDIUM)

**Detect:** Functions with >5 parameters
**Action:** Group related parameters into a JSON object or array
**Rule:** Only apply if parameters are logically related

## Refactoring Process

1. **Analyze** — Read the file, identify refactoring opportunities
2. **Prioritize** — Order by impact: dead code removal first, then naming, then extraction
3. **Present plan** — Show each refactoring with before/after
4. **Wait for approval** — User must approve before changes are applied
5. **Apply changes** — One refactoring at a time
6. **Verify** — Ensure the code structure is correct after each change

## Safety Rules

- NEVER change business logic during refactoring
- NEVER rename Public/Private variables that might be used externally
- ALWAYS check for external callers before removing functions (use Grep)
- ALWAYS preserve the function signature (parameters and return type)
- If unsure whether behavior will change, DO NOT refactor — flag it as a suggestion only
