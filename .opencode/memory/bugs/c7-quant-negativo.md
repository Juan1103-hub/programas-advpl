---
name: c7-quant-negativo
description: C7_QUANT permite negativo em devolução de compra
type: feedback
metadata:
  type: feedback
---
**Problema:** Devolução de compra (SC7 com C7_TIPO = 'D') gravava C7_QUANT < 0, gerando saldo negativo no estoque.
**Causa:** PE `MTA110OK` (validação OK de MATA110) não validava sinal de `nQuant` para tipo devolução.
**Fix:** `FONTES/MTA110OK.PRW:78` — adicionado:
```advpl
If AllTrim(C7_TIPO) == 'D' .And. nQuant < 0
    MsgAlert("Quantidade não pode ser negativa em devolução", "Atenção")
    Return(.F.)
EndIf
```
**Como aplicar:** Em **todo** PE de validação OK (`*OK.PRW`) que toque SC7, validar sinal de quantidade conforme `C7_TIPO` ('N'=normal, 'D'=devolução, 'B'=bonificação).
[[mta110ok-validacao]] [[tabelas-sc7-tomadas-centrais]] [[regras-sem-ui-transacao]]