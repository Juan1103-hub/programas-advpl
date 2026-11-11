-- =====================================================================
-- 03 - STATUS DE CONTABILIZACAO DAS BAIXAS SD3 POR TM (checkpoint)
-- Rodar ANTES da Jornada (linha de base) e DEPOIS da recontabilizacao
-- (validacao final). Se CONTAB = QTDE para o TM 502, as baixas passaram
-- a gerar lancamento contabil.
-- =====================================================================

SELECT D3_TM,
       COUNT(*) AS QTDE,
       SUM(CASE WHEN ISNULL(LTRIM(RTRIM(D3_DIACTB)), '') = ''
                THEN 1 ELSE 0 END) AS NAO_CONTAB,
       SUM(CASE WHEN ISNULL(LTRIM(RTRIM(D3_DIACTB)), '') <> ''
                THEN 1 ELSE 0 END) AS CONTAB,
       SUM(CASE WHEN ISNULL(LTRIM(RTRIM(D3_SEQCALC)), '') <> ''
                THEN 1 ELSE 0 END) AS COM_SEQCALC,
       SUM(D3_CUSTO1) AS VALOR_TM
  FROM SD3010
 WHERE D_E_L_E_T_ = ' '
   AND D3_FILIAL  = '0102'
   AND D3_EMISSAO BETWEEN '20260901' AND '20260930'
   AND ISNULL(D3_ESTORNO, '') <> 'S'
   AND D3_TM IN ('502', '999')
 GROUP BY D3_TM
 ORDER BY D3_TM;
