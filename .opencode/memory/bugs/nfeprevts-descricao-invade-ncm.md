---
name: NFEPREVTS_DESCRICAO_INVADIA_NCM
description: Preview DANFE NFEPREVTS - descricao do item invadia a coluna NCM por coluna DESC estreita
type: feedback
metadata:
  type: feedback
---
**Problema:** No preview DANFE (`FONTES/NFEPREVTS.PRW`), descricoes longas (ex.: "MINERIO DE FERRO HEMATITINHA TIPO A", ~34 caracteres ~ 114 unidades da fonte 7pt) transbordavam da coluna DESCRIACAO e sobrepunham o valor da coluna NCM/SH ("NCM bagunçado"). A quebra por palavras tambem gerava linha orfa ("A" sozinho) quando o texto tinha espacos internos duplos.

**Causa:** Largura da coluna DESC no grid = 110 unidades < largura real do texto (~114). `NPT_GridCab` (cabecalho) e o loop de impressao usavam o mesmo valor fixo. `NPT_QuebraDesc` nao normalizava espacos duplos internos apos `AllTrim`.

**Fix:** `FONTES/NFEPREVTS.PRW` —
1. Coluna DESC 110 → 126 em `NPT_GridCab` (Box/Say/`nAuxG +=`) e no loop (`nAuxH += 126`); compensacao: COD.PROD 56→48, QUANT 34→30, V.UNITARIO 44→40 (soma mantida **563**, cab e loop identicos).
2. `NPT_QuebraDesc`: apos `AllTrim`, `While "  " $ cTexto / cTexto := StrTran(cTexto, "  ", " ") / EndDo` antes do quebra-palavras.

**Como aplicar:** Em grid do preview DANFE, a largura de cada coluna deve ser um unico valor usado em `NPT_GridCab` (Box + Say + incremento) E no incremento do loop — conferir soma 563. Em funcoes de quebra de texto, sempre normalizar espacos duplos (StrTran em While) apos AllTrim.

**Verificacao (2026-10-08):** If/EndIf 122/122, For/Next 5/5, While/EndDo 4/4, ASCII 0, convert-encoding SKIP; preview do usuario OK (desc 2 linhas limpas, NCM 26011100 sem sobreposicao).

[[nfeprevts]] [[danfe-preview]] [[grid-colunas]]
