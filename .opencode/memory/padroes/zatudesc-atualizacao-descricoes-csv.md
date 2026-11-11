---
name: zatudesc-atualizacao-descricoes-csv
description: Rotina de importação em massa de descrições do produto (B1_DESC, B1_ZDESCF) a partir de CSV
type: reference
metadata:
  type: reference
---
**Rotina:** `FONTES/ZATUDESC.PRW` — `User Function ZATUDESC()`
**Objetivo:** atualização em massa de `B1_DESC` (descrição resumida) e `B1_ZDESCF` (descrição completa) do produto a partir de CSV
**Estrutura do CSV (separador `;`):**
- Coluna A (posição 1) → `B1_COD` (código do item)
- Coluna B (posição 2) → `B1_DESC` (descrição resumida)
- Coluna C (posição 3) → `B1_ZDESCF` (descrição completa)
**Mecanismo:** `FWFileReader` + `StrTokArr` + `DbSeek` na ordem 1 (B1_FILIAL+B1_COD) + `RecLock("SB1", .F.)` + `MsUnlock()`
**Regras:**
- Cabeçalho é detectado automaticamente e ignorado (cobre "codigo" e "código")
- Colunas vazias de descrição NÃO zeram o campo — mantém o valor atual
- Linhas com código não encontrado na SB1 ou sem nenhuma descrição contam como erro
- `PADR(..., TamSX3(...)[1])` para ajuste ao tamanho do campo
- `Processa()` com `IncProc()` para barra de progresso
- Duas telas de confirmação (arquivo + gravação)
**Observações:**
- `B1_ZDESCF` é campo custom Vortice — confirmar existência no SX3 do ambiente antes de usar
- Acesso via PE de botão `MA010BUT` na MATA010 (cadastro de produtos)
- Encoding: CP-1252 (gerar em UTF-8 → converter → compilar)
[[pe-botao-codigo-mnu]] [[entry-point-naming]]

## 2026-10-09 — parser de aspas + fim do PADR (bug da descrição completa)
- Leitura do CSV agora usa a Static `fCsvSplit(cLinha, ";")` do próprio fonte:
  respeita campos entre aspas, `;` interno não divide, `""` vira aspas literal.
  (`StrTokArr` quebrava a coluna 3 no primeiro `;` da ficha técnica.)
- Gravação **sem `PADR`**: `SB1->B1_DESC := AllTrim(cDescRes)` e
  `SB1->B1_ZDESCF := AllTrim(cDescCom)` — `PADR(..., TamSX3(...)[1])` truncava
  campos MEMO a 10 caracteres (SX3 retorna 10 para memo).
- Validado: 20/20 linhas da planilha real do cliente → 3 campos, completa íntegra.
