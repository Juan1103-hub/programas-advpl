-- =====================================================================
-- 00 - DISCOVERY DE COLUNAS (RODAR PRIMEIRO)
--
--     Objetivo: validar TODOS os nomes de campo usados nos arquivos
--     04, 07, 09, 10 e 11 em uma unica execucao, evitando erro 207
--     (Invalid column name) no APSDU.
--
--     Como usar:
--       1) rode a query 00-A  (confere se as tabelas existem)
--       2) rode a query 00-B  (lista TODAS as colunas de cada tabela)
--       3) confira se cada campo citado na lista "CAMPOS USADOS" abaixo
--          aparece com o mesmo nome
--       4) se algum campo NAO existir, ajuste o arquivo correspondente
--
--     ATENCAO 1: se CT2010 / CT5010 NAO tiverem a coluna D_E_L_E_T_,
--                 REMOVER o filtro "D_E_L_E_T_ = ' '" das queries dos
--                 arquivos 04, 07 e 09 (tabelas standard antigas).
--     ATENCAO 2: nao usar WITH (NOLOCK) - o console do Webapp remove o
--                 hint e quebra o WHERE.
--     SQL Server - APSDU - ASCII puro.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 00-A) AS TABELAS ENVOLVIDAS EXISTEM?
--      (confere o nome fisico: CT2010 / CTK1010 / SCP010 / CTT1010 ...)
-- ---------------------------------------------------------------------
SELECT TABLE_NAME, TABLE_TYPE
  FROM INFORMATION_SCHEMA.TABLES
 WHERE TABLE_NAME IN ('CT2010', 'CT5010', 'CT1010', 'CTK1010', 'SD3010',
                      'SB1010', 'SCP010', 'CTT1010', 'SE1010', 'SE2010')
 ORDER BY TABLE_NAME;


-- ---------------------------------------------------------------------
-- 00-B) TODAS AS COLUNAS DAS TABELAS ENVOLVIDAS
--      Leia e compare com a lista "CAMPOS USADOS" do rodape.
-- ---------------------------------------------------------------------
SELECT TABLE_NAME       AS TABELA,
       ORDINAL_POSITION AS ORDEM,
       COLUMN_NAME      AS CAMPO,
       DATA_TYPE        AS TIPO,
       CHARACTER_MAXIMUM_LENGTH AS TAMANHO
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME IN ('CT2010', 'CT5010', 'CT1010', 'CTK1010', 'SD3010',
                      'SB1010', 'SCP010', 'CTT1010', 'SE1010', 'SE2010')
 ORDER BY TABLE_NAME, ORDINAL_POSITION;


-- =====================================================================
-- CAMPOS USADOS NOS ARQUIVOS 04 / 07 / 09 / 10 / 11
-- (confirme um a um no resultado da 00-B)
-- ---------------------------------------------------------------------
-- CT2010 (CT2)   : CT2_FILIAL, CT2_DATA, CT2_LOTE, CT2_SBLOTE, CT2_DOC,
--                  CT2_LINHA, CT2_DC, CT2_DEBITO, CT2_CREDIT, CT2_VALOR,
--                  CT2_HP, CT2_HIST, CT2_CCD, CT2_CCC, CT2_ITEMD,
--                  CT2_ITEMC, CT2_MOEDLC, CT2_TPSALD, CT2_LP, CT2_MANUAL,
--                  CT2_ORIGEM, CT2_ROTINA, CT2_INCONS, CT2_PROCES,
--                  CT2_ESTCAN, CT2_SEQUEN
-- CT5010 (CT5)   : CT5_FILIAL, CT5_LANPAD, CT5_SEQUEN, CT5_DESC,
--                  CT5_STATUS, CT5_DC, CT5_DEBITO, CT5_CREDIT, CT5_VLR01,
--                  CT5_HIST, CT5_CCD, CT5_CCC, CT5_MOEDLC, CT5_SBLOTE,
--                  CT5_TPSALD, CT5_ORIGEM, CT5_TABORI, CT5_RECORI,
--                  CT5_DIACTB, CT5_OBS
-- SD3010 (SD3)   : D3_FILIAL, D3_TM, D3_COD, D3_ITEM, D3_QUANT, D3_CUSTO1,
--                  D3_CC, D3_NUMSA, D3_ITEMSA, D3_NUM, D3_DOC,
--                  D3_EMISSAO, D3_ESTORNO, D3_SEQCALC, D3_DIACTB, D3_CF
-- SB1010 (SB1)   : B1_FILIAL, B1_COD, B1_DESC, B1_CC, B1_CONTA, B1_CLVL,
--                  B1_ITEMCC, B1_CCCCUSTO, B1_APROPRI, B1_XCTCUST,
--                  B1_XCTCIND, B1_XCTDESP, B1_TIPO, B1_MSBLQL
-- SCP010 (SCP)   : CP_NUM, CP_FILIAL, CP_CC, CP_DATA, CP_QUANT, CP_QUJE
-- CTT1010 (CTT)   : CTT_FILIAL, CTT_CUSTO, CTT_DESC01
-- CT1010 (CT1)   : CT1_FILIAL, CT1_CONTA, CT1_DESC01
--
-- CAMPOS QUE NAO EXISTEM (NUNCA USAR - erro 207):
--   CT2_CREDITO, CT2_CONTA, CT2_CC, CT2_ITEMCTA, CT2_KEY, CT2_MOEDA,
--   CT5_LP, CT5_CONTA, CT5_CC, CT5_ITEM, CT5_CLVL, CT5_EXIG, CT5_MOEDA,
--   B1_CTA
-- =====================================================================
