---
name: fechamento-estoque-x-razao-reconciliacao
description: Como reconciliar planilha de reposição de estoque (custo médio) com razão conta 1.1.4.01.200001 e compor a diferença
type: padrao
---
**Cenário**: Fechamento mensal de estoque (planilha "REPOSIÇÃO DE ESTOQUE") não bate com o razão contábil do Almoxarifado (conta 1.1.4.01.200001).

**Regra de ouro**: a única coluna da planilha que reconcilia com o razão é **"custo medio ( total )" = Saldo Atual × Custo Médio** (coluna O). A coluna "Valor em estoque" (coluna P) = Saldo × **Preço Unitário** (último preço de compra) e NÃO é valor contábil — nunca usá-la no fechamento.

**Prova empírica (fechamento set/2026)**:
- Planilha ago (2) soma "custo medio (total)" = 209.832,085 = saldo anterior do razão setembro (209.832,08) — bate 100%.
- Planilha set soma "custo medio (total)" = 214.272,91; razão final = 216.467,17 → diferença 2.194,26.

**Como compor a diferença** (método que fechou):
1. Somar itens com baixa no mês que NÃO têm nenhum lançamento no razão (cruzar códigos do razão com "Dt ult.Baixa" da planilha) → valor = Δsaldo × custo médio.
2. Itens que existiam no mês anterior e sumiram da planilha atual sem lançamento.
3. Residual = efeito de reavaliação do custo médio (entrada nova a preço diferente muda a média dos saldos antigos sem gerar lançamento) + arredondamento.

**Causas típicas de baixa sem lançamento no razão**: baixa para outro almoxarifado/filial (razão cobre só 1 filial/conta), perda/ajuste de inventário com conta própria, consumo direto.

**Causa raiz comprovada (set/2026 — ver também `_PATCHES/CT2_BAIXAS/`)**: saídas TM 502/499 gravadas no SD3 com **`D3_CUSTO1 = 0`** não têm nenhuma linha no CT2 (correlação 100% nos 25 itens: zero linhas com o código no `CT2_HIST`; controles com `D3_CUSTO1 > 0` têm linha) → sem crédito em 1.1.4.01.200001 → razão fica maior que o plano físico. Discriminador observado = só `D3_CUSTO1 = 0`.

**Hipóteses refutadas no diagnóstico**: `D3_SEQCALC` vazio (preenchido nos dois grupos — `D3_SEQCALC` é da MATA330, ver `07_seqcalc_ct5_mv.sql:4-7`), `D3_DIACTB` (vazio até em movimentos que contabilizaram — campo não usado neste cliente), `CT2_TPSALD = 9` (não existe na conta), conta trocada (`B1_XCTAEST` = 11401200001 em 24/25), condição LP 666 ausente (cadastrada), **origem/rotina do movimento** (Q17b: `D3_CF='RE0'`, `D3_TIPO='MC'`, TM, centro de custo e NUMSA idênticos em movimentos com e sem custo — mesmo dia com SA diferentes até: 01/09 SA 007674 = custo 0 × SA 007672 = 4,3661), item sem valor hoje (Q18: todos com `B2_QATU > 0` e `B2_VATU1 > 0` — consertados no fechamento/outubro). Resta só **estado do item na hora da gravação** (custo lido zerado; sem histórico de SB2 para provar — testar com entradas sem valor no mês, ver `13_fechamento_pendencias.sql` Q22).

**Armadilha CSV × CT2 (export do razão)** — **CASO ENCERRADO**: o CSV de 21/10 foi exportado ANTES do usuário rodar MATA330 (custo médio) + Acompanha Custos; depois disso o CT2 mudou. Os 17,95 do CSV eram o item da NF 773 que **não era para estoque** — entrou errado, foi corrigido na entrada e a contrapartida foi para conta de despesa (31202100004), não para 11401200001. **Lição**: nunca cruzar export de razão com consultas diretas em CT2 feitas em datas diferentes — o MATA330 regera o CT2 do período (PE MA330CTB dispara "após reprocessar os lançamentos contábeis apagados", TDN PEST06016).

**Correção de baixa sem custo (procedimento TOTVS validado no TDN — PEST06016)**:
1. Acerto de Saldo Atual + Refaz Acumulados antes de qualquer acerto.
2. Rodar **MATA330** com "Atualiza Arq. Movimentação" = **Sim** (obrigatório — atualiza SD3/SD1/SD2/SDB/SD5, não só SB2) com "Gera lançamento contábil?" = Sim: corrige `D3_CUSTO1` e regera o CT2 do período automaticamente.
   - **TESTADO E NÃO RESOLVEU (22/10/2026, set/2026)**: MATA330 executada com todos os parâmetros corretos (Atualizar=Sim, GerarLanc=Sim, limite 30/09, filial 0102) e o recálculo **reproduziu os mesmos valores** (preview 35.046,21 idêntico; SD3 segue com 60 movimentos em `D3_CUSTO1 = 0`; CT2 regenerado igual: DC=1 33 linhas 41.681,30 / DC=3 414 linhas 35.046,21) → **o próprio recálculo calcula custo zero na hora dessas baixas**. A MATA330 só corrige movimento que ficou zero por descuido de gravação; se a cadeia de valor do item no mês estava zerada/exaurida, o recálculo chega ao mesmo zero. Só conserta com valorização manual (TMS valorizadas + MATA240, item a item) ou aceitando a cadeia.
3. Alternativa manual pontual: TMS valorizadas (`F5_VAL = SIM`, `F5_QTDZERO = SIM`) + MATA240 informando `D3_CUSTO1` à mão.
4. Contabilização complementar: MATA331 (Contabilização do Custo Médio).

**Pós-MATA330 (obrigatório conferir)**: rodar `14_verificacao_pos_mata330.sql` (Q24 SD3 corrigido? / Q25 CT2 regenerado? / Q26 totais DC / Q27 saldo final ≈ 214.272,91).

**Composição dos 60 movimentos sem custo (set/2026)**: 55 TM 502 (requisição, 227 un) + 5 TM 499 (inventário, 308 un). Teste de cadeia (Q22b, ago+set): para os itens afetados (ex.: MC.0301.00467/468/469, MC.1003.00015, MC.1001.00022/00044/00069, MC.0809.00172, MC.0202.00049, MC.0806.00010) **só existem saídas no período, todas sem valor, e nenhuma entrada valorizada** — o valor teria que vir do saldo anterior. Itens de controle (MC.0109.00697, MC.0403.00349, MC.1003.00055, MC.0801.00008) têm saídas COM valor no mesmo período, provando que a cadeia valorizada gera CT2 normalmente.

**Armadilha de coluna SB9**: `B9_QATU` e `B9_VATU1` **não existem** neste build (erro 207, junto com `D3_NUM` e `CT2_CONTA`). Colunas reais da SB9 (via `INFORMATION_SCHEMA.COLUMNS`): **`B9_QINI`** (saldo inicial quantidade), **`B9_VINI1`** (saldo inicial valor moeda 1), **`B9_CM1`** (custo médio) — SB9 guarda só INI (inicial), não tem QFIM/VFIM. Descobrir colunas de qualquer tabela desconhecida com `INFORMATION_SCHEMA.COLUMNS` antes de escrever query.

**CAUSA RAIZ FINAL COMPROVADA (22/10/2026 — exemplar MC.0301.00467)**: histórico COMPLETO do item no SD3 = 3 movimentos: 30/04 entrada TM 03, 5 un, `D3_CUSTO1 = 0` (entrou sem valor, dilui a média) → 10/06 saída TM 502, 5 un, valor 48,33 (consumiu todo o valor que existia) → 15/09 saída TM 502, 10 un, **0** (não sobrou valor para tirar). Ou seja: o estoque do item estava **SEM VALOR contábil na hora da baixa de setembro**; a MATA330 recalcula e chega ao mesmo zero — **é aritmeticamente certo, não é bug de gravação**. Soma-se: os 5 TM 499 (doc INVENT, 28-29/09, 308 un: MC.0806.00098 200 un, MC.0806.00010 82 un, MC.0806.00153 18, MC.0402.00175 7, MC.0506.00230 1) = baixa de quantidade **sem tirar valor** da conta. O valor que a planilha mostra só apareceu em **outubro** (saídas de outubro com valor: MC.1003.00015 @59,9486, MC.0806.00010 @3,26, MC.1001.00044 @99,9 + TM 005 46 un @270,23; 467/468/469 sem movimento em outubro = consertados pelo acerto/fechamento). **A diferença 2.194,26 é de TIMING (valorização posterior), não de lançamento faltando no razão.** Resolução: ajuste contábil de fechamento (crédito 11401200001 × débito de conta de ajuste, a definir com a contabilidade) ou aceite documentado; e corrigir o processo — **toda entrada precisa nascer valorizada e TM 499 precisa ser lançado com valor** (senão o problema se repete todo mês).

**TM999 em estoque**: ajuste de inventário com custo (`D3_CUSTO1 > 0`) pode ficar fora do razão da conta de estoque se a contrapartida cair em conta de diferença de inventário — bater totais por `CT2_DC` (Q21 do arquivo 13) antes de concluir que "sumiu".

**Armadilha de comparação**: `SUM(D3_CUSTO1)` do SD3 (TM 502 do mês ≈ 218 mil) NÃO é comparável direto com os créditos do razão (35.046,21 = só conta 1.1.4.01.200001/local 02) — cortar por `D3_LOCAL` e `B1_XCTAEST` antes de comparar.

**Custo médio contaminado — sintoma**: `Custo Medio` >> `Preco Unitario` (ex.: retentor a R$784,62 com último preço R$10,00 = entrada com quantidade errada na NF).

**Como aplicar**: sempre reconciliar usando a coluna de custo médio; validar saldo físico sem custo (saldo>0 e custo=0 = item que sai sem valor).
[[zmma01-detalhes-janela-mes]] [[query-builder]]
