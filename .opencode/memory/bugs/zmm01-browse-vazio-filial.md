---
name: bug-zmm01-browse-vazio-filial
description: ZMM01 browse vazio — RPO antigo com filtro estrito de filial escondia registros com ZZA_FILIAL vazia
type: feedback
metadata:
  type: feedback
---
**Problema:** ZMM01 (FWMBrowse com SetDataQuery) abria com browse totalmente vazio, ainda com 1.213 registros ativos na ZZA013 (tabela `ZZA<cEmpAnt>3`).

**Causa:** RPO desatualizado executando versão antiga cuja `MontaQuery` filtrava `AND ZZA_FILIAL = xFilial('SB1')` SEM aceitar filial vazia; todos os registros da base tinham `ZZA_FILIAL` vazia (legado `ZMM01.PRW` insere com `xFilial('SB1')` mas histórico tem registros sem filial). Fonte em disco já tinha `OR ZZA_FILIAL = ''` mas não estava compilado.

**Diagnóstico:** query por AnoMes/Filial/D_E_L_E_T_ no console (INFORMATION_SCHEMA.TABLES para achar `ZZA013` — sys.tables NÃO funciona no console TOTVS). Tela vazia + registros ativos = RPO divergente (padrão destá máquina, hooks não confiáveis).

**Fix:** corrigir fonte + compilar manualmente; query do browse ficou `(ZZA_FILIAL = xFilial('SB1') OR ZZA_FILIAL = '')`.

**Como aplicar:** tela vazia ≠ falta de dados; sempre cruzar com SQL de contagem e suspeitar de RPO antigo. [[zmm01-crash-abertura]] [[(encoding-cp1252)]]
