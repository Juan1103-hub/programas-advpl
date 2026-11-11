-- =====================================================================
-- 10) DIAGNOSTICO DEFINITIVO DA CONDICAO DO LP 666 (consumo)
--
--     PREMISA: a condicao do Lancamento Padrao do LP 666 JA ESTA
--     CADASTRADA (confirmado pelo usuario em 21/10/2026).
--     Logo, as 3 linhas pendentes da planilha (075, 076 e 403 - ajuste
--     de inventario TM 999, sem conta de debito e/ou sem centro de
--     custo) NAO deveria existir no CT2. Como elas existem, a condicao NAO
--     esta sendo aplicada neste movimento. Este arquivo isola QUAL
--     das 5 explicacoes abaixo esta em jogo:
--
--     (E1) CT2 de 09/2026 gravado ANTES da condicao existir (lixo)
--     (E2) Condicao cadastrada em apenas UMA das sequencias do LP 666
--     (E3) Movimento contabilizado por OUTRO LP (nao 666) neste periodo
--     (E4) Expressao da condicao nao suportada pelo motor (ex.: chamada
--          de User Function / Empty() no campo "Cond.") -> e ignorada
--     (E5) Pre-lancamento (TPSALD 9) do mesmo doc ainda nao efetivado
--
--     Execute na ordem: 10a, 10b, 10c, 10i, 10j, 10d, 10e.
--     SQL Server - APSDU - SQL ASCII puro, sem WITH (NOLOCK).
-- =====================================================================


-- ---------------------------------------------------------------------
-- 10a) DUMP COMPLETO DO LANCAMENTO PADRAO (CT5) DOS LPs RELEVANTES
--      SELECT * para nao depender do nome da coluna de "Cond."
--      (cole o resultado aqui: preciso ver o texto da condicao)
--      Inclui as 2 sequencias conhecidas (001 e 002) e os LPs 674/676
--      (saida/entrada de inventario).
-- ---------------------------------------------------------------------
SELECT *
  FROM CT5010
 WHERE CT5_LANPAD IN ('666','668','674','676','679','680')
 ORDER BY CT5_LANPAD, CT5_SEQUEN;


-- ---------------------------------------------------------------------
-- 10b) COLUNAS FISICAS DE CT5 (descobre o nome real do campo de
--      "Condicao" e de todos os demais neste build)
-- ---------------------------------------------------------------------
SELECT ORDINAL_POSITION, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME = 'CT5010'
 ORDER BY ORDINAL_POSITION;


-- ---------------------------------------------------------------------
-- 10c) AS 3 LINHAS PENDENTES NO CT2 (doc 000011 / lote 008840 / 30-09-2026)
--      Responde: qual LP gravou, se CT2_INCONS foi marcado, qual rotina
--      e origem gerou, e se o valor e exatamente 27,00 / 48,00 / 85,00.
-- ---------------------------------------------------------------------
SELECT CT2_LINHA, CT2_DC, CT2_DEBITO, CT2_CREDIT, CT2_VALOR,
       CT2_CCD, CT2_CCC, CT2_ITEMD, CT2_ITEMC, CT2_LP,
       CT2_INCONS, CT2_TPSALD, CT2_MANUAL, CT2_ORIGEM, CT2_ROTINA,
       CT2_PROCES, CT2_HIST, CT2_MOEDLC, CT2_DATA, CT2_FILIAL,
       CT2_LOTE, CT2_SBLOTE, CT2_DOC
  FROM CT2010
 WHERE CT2_LOTE = '008840'
   AND CT2_DOC  = '000011'
   AND CT2_LINHA IN (75, 76, 403)
 ORDER BY CT2_LINHA, CT2_DC;


-- ---------------------------------------------------------------------
-- 10d) MOVIMENTOS DE AJUSTE DE INVENTARIO (TM 999) DE SET/2026
--      Confirma: quais docs, se tem D3_NUMSA (requisicao), se tem
--      D3_SEQCALC (marcado pela MATA330) e se D3_DIACTB ficou vazio.
-- ---------------------------------------------------------------------
SELECT D3_DOC, D3_ITEM, D3_COD, D3_TM, D3_ESTORNO, D3_CC,
       D3_CUSTO1, D3_QUANT, D3_NUMSA, D3_EMISSAO,
       ISNULL(LTRIM(RTRIM(D3_SEQCALC)), '') AS SEQCALC,
       ISNULL(LTRIM(RTRIM(D3_DIACTB)), '')  AS DIACTB
  FROM SD3010
 WHERE D_E_L_E_T_ = ' '
   AND D3_FILIAL = '0102'
   AND D3_EMISSAO BETWEEN '20260901' AND '20260930'
   AND D3_TM = '999'
 ORDER BY D3_DOC, D3_ITEM;


-- ---------------------------------------------------------------------
-- 10e) DIMENSIONAMENTO 502 x 999 COM E SEM CENTRO DE CUSTO / SEQCALC
--      Volume que a condicao do LP 666 eliminaria da contabilizacao.
-- ---------------------------------------------------------------------
SELECT D3_TM,
       CASE WHEN ISNULL(LTRIM(RTRIM(D3_CC)), '') = '' THEN 'SEM CC' ELSE 'COM CC' END AS SITUACAO_CC,
       CASE WHEN ISNULL(LTRIM(RTRIM(D3_SEQCALC)), '') = '' THEN 'SEM SEQCALC' ELSE 'COM SEQCALC' END AS SITUACAO_SEQCALC,
       COUNT(*)                  AS QTDE,
       SUM(ISNULL(D3_CUSTO1, 0)) AS VALOR_CUSTO
  FROM SD3010
 WHERE D_E_L_E_T_ = ' '
   AND D3_FILIAL = '0102'
   AND D3_EMISSAO BETWEEN '20260901' AND '20260930'
   AND ISNULL(LTRIM(RTRIM(D3_ESTORNO)), '') <> 'S'
   AND D3_TM IN ('502', '999')
 GROUP BY D3_TM,
          CASE WHEN ISNULL(LTRIM(RTRIM(D3_CC)), '') = '' THEN 'SEM CC' ELSE 'COM CC' END,
          CASE WHEN ISNULL(LTRIM(RTRIM(D3_SEQCALC)), '') = '' THEN 'SEM SEQCALC' ELSE 'COM SEQCALC' END
 ORDER BY D3_TM, SITUACAO_CC, SITUACAO_SEQCALC;


-- ---------------------------------------------------------------------
-- 10i) DISTRIBUICAO DE LP NO DOCUMENTO 000011
--      O ajuste de inventario saiu pelo LP 666 (consumo) ou por
--      outro LP (674/676 de inventario)?  (explicacao E3)
-- ---------------------------------------------------------------------
SELECT CT2_LP,
       COUNT(*)                  AS QTDE_LINHAS,
       SUM(ISNULL(CT2_VALOR, 0)) AS VALOR_TOTAL
  FROM CT2010
 WHERE CT2_LOTE = '008840'
   AND CT2_DOC  = '000011'
 GROUP BY CT2_LP
 ORDER BY CT2_LP;


-- ---------------------------------------------------------------------
-- 10j) PRE-LANCAMENTO (TPSALD 9) x EFETIVADO (TPSALD 1) NO MESMO DOC
--      Se ainda existir tipo 9 para o doc 000011, a CTBA350 nao
--      efetivou tudo (explicacao E5). Se so existir tipo 1, a CTBA350
--      foi completa.
-- ---------------------------------------------------------------------
SELECT CT2_TPSALD,
       COUNT(*)                  AS QTDE,
       SUM(ISNULL(CT2_VALOR, 0)) AS VALOR_TOTAL
  FROM CT2010
 WHERE CT2_LOTE = '008840'
   AND CT2_DOC  = '000011'
 GROUP BY CT2_TPSALD
 ORDER BY CT2_TPSALD;


-- ---------------------------------------------------------------------
-- 10k) TODOS OS LANCAMENTOS DE 09/2026 SEM CONTA DE DEBITO OU SEM CC
--      Panorama do que ja foi implantado com pendencia no Razao.
-- ---------------------------------------------------------------------
SELECT CT2_DATA, CT2_LOTE, CT2_DOC, CT2_LINHA, CT2_DC,
       CT2_DEBITO, CT2_CREDIT, CT2_VALOR, CT2_CCD, CT2_CCC,
       CT2_LP, CT2_INCONS, CT2_TPSALD, CT2_HIST
  FROM CT2010
 WHERE CT2_FILIAL = '0102'
   AND CT2_DATA BETWEEN '20260901' AND '20260930'
   AND (ISNULL(LTRIM(RTRIM(CT2_DEBITO)), '') = ''
     OR ISNULL(LTRIM(RTRIM(CT2_CCC)), '') = '')
 ORDER BY CT2_DOC, CT2_LINHA;


-- ---------------------------------------------------------------------
-- 10l) COLUNAS FISICAS DE SE1010 (TES)
--      Para localizar o vinculo TES/TM -> Lancamento Padrao (CT5),
--      que e o que define qual LP contabiliza o movimento 999.
--      Discovery apenas - nao depende do resultado para o diagnostico.
-- ---------------------------------------------------------------------
SELECT ORDINAL_POSITION, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME = 'SE1010'
 ORDER BY ORDINAL_POSITION;
