-- =====================================================================
-- 04 - MOVIMENTOS CONTABEIS (CT2) DA CONTA ALMOXARIFADO 11401200001
--      EM SETEMBRO/2026 - FILIAL 0102
--
-- Resumo por dia, tipo de linha (CT2_DC: 1 = Debito, 2 = Credito,
-- 3 = Partida Dobrada), TIPO DE SALDO (CT2_TPSALD) e moeda (CT2_MOEDLC).
-- Diagnostico anterior: so entradas (debitos via CTBANFE), creditos 0,00.
--
-- CT2_TPSALD = '1' -> saldo atual (efetivado) -> VISIVEL no CTBR400
-- CT2_TPSALD = '9' -> pre-lancamento -> NAO aparece no CTBR400 com Tipo
--                     de Saldo = 1 (A Jornada do Acompanha Custos grava
--                     tudo como tipo 9 por design; efetivar na CTBA350).
--
-- ATENCAO: rodar 00_colunas_banco.sql ANTES deste arquivo. Se a CT2010
-- nao tiver a coluna D_E_L_E_T_, REMOVER o filtro "D_E_L_E_T_ = ' '"
-- das duas queries abaixo (CT2 e tabela standard antiga).
-- O campo de credito chama-se CT2_CREDIT (Nao existe CT2_CREDITO).
-- =====================================================================

SELECT CT2_DEBITO,
       CT2_CREDIT,
       CT2_DC,
       CT2_TPSALD,
       CT2_MOEDLC,
       SUBSTRING(CT2_DATA, 1, 6) AS MES,
       CT2_DATA,
       COUNT(*) AS QTDE,
       SUM(CT2_VALOR) AS VALOR
  FROM CT2010
 WHERE D_E_L_E_T_ = ' '
   AND CT2_FILIAL = '0102'
   AND CT2_DATA BETWEEN '20260901' AND '20260930'
   AND (CT2_DEBITO = '11401200001' OR CT2_CREDIT = '11401200001')
 GROUP BY CT2_DEBITO, CT2_CREDIT, CT2_DC, CT2_TPSALD, CT2_MOEDLC,
          SUBSTRING(CT2_DATA, 1, 6), CT2_DATA
 ORDER BY CT2_DATA, CT2_DC;

-- =====================================================================
-- SEPARACAO DEBITO (entradas) x CREDITO (baixas) - a leitura do "razao"
-- =====================================================================
SELECT CT2_TPSALD,
       SUM(CASE WHEN CT2_DEBITO = '11401200001' THEN CT2_VALOR ELSE 0 END) AS DEBITO_ALMOX,
       SUM(CASE WHEN CT2_CREDIT = '11401200001' THEN CT2_VALOR ELSE 0 END) AS CREDITO_ALMOX,
       COUNT(*) AS QTDE
  FROM CT2010
 WHERE D_E_L_E_T_ = ' '
   AND CT2_FILIAL = '0102'
   AND CT2_DATA BETWEEN '20260901' AND '20260930'
   AND (CT2_DEBITO = '11401200001' OR CT2_CREDIT = '11401200001')
 GROUP BY CT2_TPSALD;

-- =====================================================================
-- DETALHE (se precisar identificar documento por documento, limitado
-- aos primeiros 100 lancamentos da conta):
-- Campos de centro de custo: CT2_CCD (debito) e CT2_CCC (credito).
-- Nao existem CT2_CC, CT2_ITEMCTA nem CT2_KEY.
-- =====================================================================
--SELECT TOP 100
--       CT2_DATA, CT2_LOTE, CT2_SBLOTE, CT2_DOC, CT2_LINHA,
--       CT2_DEBITO, CT2_CREDIT, CT2_VALOR, CT2_MOEDLC, CT2_TPSALD,
--       CT2_CCD, CT2_CCC, CT2_ITEMD, CT2_ITEMC, CT2_HIST
--  FROM CT2010
-- WHERE D_E_L_E_T_ = ' '
--   AND CT2_FILIAL = '0102'
--   AND CT2_DATA BETWEEN '20260901' AND '20260930'
--   AND (CT2_DEBITO = '11401200001' OR CT2_CREDIT = '11401200001')
-- ORDER BY CT2_DATA, CT2_LOTE, CT2_DOC, CT2_LINHA;
