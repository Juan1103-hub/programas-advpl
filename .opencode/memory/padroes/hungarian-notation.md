---
name: hungarian-notation
description: Notação húngara obrigatória em AdvPL/TLPP
type: reference
metadata:
  type: reference
---
**Padrão:** Prefixo indicando tipo em toda variável/parâmetro/campo
**Quando usar:** Sempre — declaração de `Local`, `Private`, `Static`, parâmetros de função, campos de tabela
**Prefixos:**
| Tipo | Prefixo | Exemplo |
|------|---------|---------|
| Character | `c` | `cQuery`, `cFilial` |
| Numeric | `n` | `nQuant`, `nValor` |
| Date | `d` | `dData`, `dVenc` |
| Logical | `l` | `lOk`, `lAchou` |
| Array | `a` | `aItens`, `aDados` |
| Object | `o` | `oModel`, `oRest` |
| CodeBlock | `b` | `bBloco`, `bValida` |
| Variant | `x` | `xRet`, `xParam` |
| JSON | `j` | `jConfig`, `jResp` |

**Campos de tabela:** `<tabela>_<campo>` — ex: `C7_QUANT`, `B1_DESC`, `A1_COD`
**Regras:**
- Nunca `Function` — use `User Function` (público) ou `Static Function` (interno)
- Entry Points: arquivo = nome PE, maiúsculo, sem `U_` (`MTA110OK.PRW` → `User Function MTA110OK()`)
- TLPP: `as` **após** atribuição (`Local cX := "" as Character`)
[[entry-point-naming]] [[encoding-cp1252]] [[sql-anti-injection]]