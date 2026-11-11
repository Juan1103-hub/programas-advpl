---
name: padrao-fwbrowse-query-refresh-limpar
description: FWMBrowse SetDataQuery — refresh/limpeza de filtro deve trocar a query no OBJETO (SetQuery+Refresh), nunca reabrir o alias na mão
type: feedback
metadata:
  type: feedback
---
**Contexto:** ZMM01 usa `FWMBrowse` com `SetDataQuery(.T.)` + `SetQuery()` + `SetAlias(GetNextAlias())`. O próprio browse executa a query e guarda a string em cache.

**Erro comum:** filtrar reabrindo o alias manualmente (`DbCloseArea` + `DbUseArea` com query nova) — o `Refresh(.T.)` do browse volta a usar a query antiga e o filtro "não vale".

**Correto (confirmado em 2026-10-21):**
- Filtrar: `oBrowse:SetQuery(MontaQuery())` → `oBrowse:Refresh(.T.)` → `oBrowse:GoTop()`.
- Limpar: `oBrowse:CleanFilter()` (TDN FWFormBrowse, herdada pelo FWMBrowse — limpa o filtro nativo "Filtrar") + `cBuscaProd := ""` + `SetQuery/Refresh/GoTop`.
- UI de busca em Webapp: preferir `ParamBox` a MSDIALOG artesanal (MSDIALOG renderizou cortado/transaço).

**Notas TDN (FwBrowse):** `ExecuteFilter(lBrwUpdate)` reaplica; `SetProfileID` obrigatório (≤4 chars) para browse com `GetNextAlias()`; `SetDataQuery` não deve receber `R_E_C_N_O_` na query a partir de Lib 20161010 (ZMM01 ainda usa `RECNO` no SELECT — funciona, mas é pendência).

**Como aplicar:** qualquer browse de query com busca/filtro custom: sempre trocar a query no objeto do browse. [[zmm01-browse-vazio-filial]]
