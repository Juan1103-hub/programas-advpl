-- =====================================================================
-- 14) VERIFICACAO POS-MATA330 - OS 25 ITENS JA FORAM CORRIGIDOS NO SD3?
--
--     CONTEXTO: em 21/10 o usuario rodou MATA330 (recalculo custo medio)
--     e depois Acompanha Custos, e re-tirou o razao. Ainda falta saber
--     se o MATA330 CORRIGIU o D3_CUSTO1 = 0 dos 25 itens.
--
--     FATO TDN (validado): a pergunta "Atualiza Arq. Movimentacao" = Sim
--     da MATA330 e OBRIGATORIA para atualizar o SD3 (e SD1/SD2/SDB/SD5).
--     Quando Sim, a rotina regrava os custos nos ARQUIVOS DE MOVIMENTO,
--     nao so no SB2. Ou seja: se o usuario rodou com Atualiza Mov = Sim,
--     o D3_CUSTO1 dos 25 itens JA DEVE ESTAR > 0 hoje.
--     Fonte: TDN "MATA330 - Perguntas do Recalculo do Custo Medio".
--
--     ALEM DISSO: a MATA330 tem a pergunta "Gera lancamento contabil?"
--     e o PE MA330CTB dispara "apos REPROCESSAR OS LANCAMENTOS CONTABEIS
--     APAGADOS" -> ou seja, a MATA330 APAGA e REGRAVA o CT2 do periodo.
--     Se rodou com Gera Lanc = Sim para set/2026, os 25 itens JA DEVEM
--     estar no razao. Se nao estao, ou o periodo/reprocessamento nao
--     alcancou setembro, ou o lote contabil foi gravado em outra data.
--
-- =====================================================================

-- =====================================================================
-- Q24) SITUACAO ATUAL DOS 25 ITENS NO SD3 (custo corrigido pelo MATA330?)
--      Se D3_CUSTO1 > 0 nesta query = MATA330 corrigiu o movimento.
--      Se ainda vem 0 = MATA330 nao alcancou setembro (reprocessar).
--      (Completar a lista IN com os 25 codigos da aba "Baixas sem Razao")
-- =====================================================================
SELECT SD3010.D3_COD,
       SD3010.D3_EMISSAO,
       SD3010.D3_TM,
       SD3010.D3_DOC,
       SD3010.D3_QUANT,
       SD3010.D3_CUSTO1,
       CASE WHEN SD3010.D3_CUSTO1 = 0 THEN 'AINDA SEM CUSTO' ELSE 'CORRIGIDO' END AS SITUACAO
  FROM SD3010
 WHERE D3_FILIAL = '0102'
   AND D_E_L_E_T_ = ' '
   AND D3_EMISSAO BETWEEN '20260901' AND '20260930'
   AND D3_LOCAL = '02'
   AND D3_COD IN (
       'MC.1003.00015','MC.1001.00022','MC.1001.00069','MC.1001.00044',
       'MC.0301.00467','MC.0301.00468','MC.0301.00469','MC.0809.00172',
       'MC.0202.00049','MC.0806.00010','MC.0801.00008'
       -- + os demais da aba "Baixas sem Razao"
   )
 ORDER BY SD3010.D3_EMISSAO, SD3010.D3_COD;

-- =====================================================================
-- Q25) OS 25 ITENS AGORA CONTAM NO CT2? (conta 11401200001, set/2026)
--      Se vier linhas com o codigo no HIST = MATA330 ja contabilizou.
--      Se vier VAZIO = o lancamento nao foi (re)gerado para setembro.
-- =====================================================================
SELECT CT2010.CT2_DATA,
       CT2010.CT2_LOTE,
       CT2010.CT2_DOC,
       CT2010.CT2_DC,
       LEFT(CT2010.CT2_HIST, 50) AS HISTORICO,
       CT2010.CT2_VALOR
  FROM CT2010
 WHERE CT2_FILIAL = '0102'
   AND D_E_L_E_T_ = ' '
   AND CT2_DATA BETWEEN '20260901' AND '20260930'
   AND (CT2_DEBITO = '11401200001' OR CT2_CREDIT = '11401200001')
   AND (CT2_HIST LIKE '%MC.1003.00015%' OR CT2_HIST LIKE '%MC.1001.00022%'
     OR CT2_HIST LIKE '%MC.1001.00069%' OR CT2_HIST LIKE '%MC.1001.00044%'
     OR CT2_HIST LIKE '%MC.0301.00467%' OR CT2_HIST LIKE '%MC.0301.00468%'
     OR CT2_HIST LIKE '%MC.0301.00469%' OR CT2_HIST LIKE '%MC.0809.00172%'
     OR CT2_HIST LIKE '%MC.0202.00049%' OR CT2_HIST LIKE '%MC.0806.00010%'
     OR CT2_HIST LIKE '%MC.0801.00008%')
 ORDER BY CT2010.CT2_DATA, CT2010.CT2_DOC;

-- =====================================================================
-- Q26) TOTAIS DA CONTA DEPOIS DO MATA330 (bate agora com 214.272,91?)
--      Credito (DC=3) deve ter SUBIDO de 35.046,21 para ~37.153,06
--      (35.046,21 + 2.106,85). Debito (DC=1) pode ter mudado pelo
--      ajuste dos 17,95 (item reclassificado para conta de despesa).
-- =====================================================================
SELECT CT2_DC,
       COUNT(*)       AS QTDE_LINHAS,
       SUM(CT2_VALOR) AS VALOR_TOTAL
  FROM CT2010
 WHERE CT2_FILIAL = '0102'
   AND D_E_L_E_T_ = ' '
   AND CT2_DATA BETWEEN '20260901' AND '20260930'
   AND (CT2_DEBITO = '11401200001' OR CT2_CREDIT = '11401200001')
 GROUP BY CT2_DC
 ORDER BY CT2_DC;

-- =====================================================================
-- Q27) O NOVO SALDO FINAL (depois do MATA330) - deve fechar 214.272,91
--      saldo anterior (209.832,08) + debitos - creditos
-- =====================================================================
SELECT CT2_DC,
       COUNT(*)       AS QTDE_LINHAS,
       SUM(CT2_VALOR) AS VALOR_TOTAL
  FROM CT2010
 WHERE CT2_FILIAL = '0102'
   AND D_E_L_E_T_ = ' '
   AND CT2_DATA BETWEEN '20260901' AND '20260930'
   AND (CT2_DEBITO = '11401200001' OR CT2_CREDIT = '11401200001')
 GROUP BY CT2_DC;
