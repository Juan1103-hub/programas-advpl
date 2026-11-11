-- =====================================================================
-- 09 - VERIFICACAO DECISIVA - SETEMBRO/2026 - FILIAL 0102
-- Objetivo: responder em uma tela duas perguntas:
--   (A) Por que as baixas do Acompanha Custos NAO aparecem no CTBR400?
--   (B) Por que o ajuste de inventario (TM 999) entra na contabilizacao?
--
-- Nome de campos conferidos no dicionario do projeto:
--   CT2_FILIAL, CT2_DATA, CT2_LOTE, CT2_SBLOTE, CT2_DOC, CT2_LINHA,
--   CT2_DC (1=Debito 2=Credito 3=Partida Dobrada), CT2_DEBITO, CT2_CREDIT,
--   CT2_VALOR, CT2_HP, CT2_HIST, CT2_CCD (CC debito), CT2_CCC (CC credito),
--   CT2_ITEMD, CT2_ITEMC, CT2_MOEDLC, CT2_TPSALD (tipo de saldo),
--   CT2_LP, CT2_MANUAL, CT2_ORIGEM, CT2_ROTINA, CT2_INCONS.
--   CT5_FILIAL, CT5_LANPAD (cod. do Lancamento Padrao), CT5_SEQUEN,
--   CT5_DESC, CT5_STATUS, CT5_DC, CT5_DEBITO, CT5_CREDIT, CT5_VLR01,
--   CT5_HIST, CT5_CCD, CT5_CCC, CT5_TPSALD, CT5_ORIGEM, CT5_TABORI.
-- ATENCAO: CT5_LP / CT2_CONTA / CT2_CC / CT2_ITEMCTA / CT5_CONTA NAO existem.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 9a) ESTADO DO CT2 EM SET/2026 POR TIPO DE SALDO  (RESPOSTA DO "RAZAO VAZIO")
-- CT2_TPSALD = '1' -> saldo atual (efetivado) -> VISIVEL no CTBR400
-- CT2_TPSALD = '9' -> pre-lancamento -> NAO aparece no CTBR400 com Tipo
--                     de Saldo = 1. A Jornada do Acompanha Custos (ExecAuto)
--                     grava TUDO como tipo 9 por design.
-- Se aqui so houver '9' para o periodo 202609, o CTBA350 (Efetivacao de
-- Pre-lancamentos, "Efetivar para Saldo = 1") nao foi executado em setembro.
-- ---------------------------------------------------------------------
SELECT CT2_TPSALD,
       ISNULL(NULLIF(CT2_ROTINA, ''), '(vazio)')  AS ROTINA,
       ISNULL(NULLIF(CT2_ORIGEM, ''), '(vazio)')  AS ORIGEM,
       ISNULL(NULLIF(CT2_LP, ''), '(vazio)')      AS LP,
       COUNT(*)                                   AS QTDE,
       SUM(CT2_VALOR)                             AS VALOR
  FROM CT2010
 WHERE D_E_L_E_T_ = ' '
   AND CT2_FILIAL = '0102'
   AND CT2_DATA BETWEEN '20260901' AND '20260930'
 GROUP BY CT2_TPSALD,
          ISNULL(NULLIF(CT2_ROTINA, ''), '(vazio)'),
          ISNULL(NULLIF(CT2_ORIGEM, ''), '(vazio)'),
          ISNULL(NULLIF(CT2_LP, ''), '(vazio)')
 ORDER BY CT2_TPSALD, QTDE DESC;

-- ---------------------------------------------------------------------
-- 9b) CONTA ALMOXARIFADO 11401200001 - DEBITO (entradas) x CREDITO (baixas)
--     por mes e por tipo de saldo. E o "razao" que o usuario viu:
--     debito 41.681,30 e credito 0,00.
-- ---------------------------------------------------------------------
SELECT SUBSTRING(CT2_DATA, 1, 6) AS MES,
       CT2_TPSALD,
       SUM(CASE WHEN CT2_DEBITO = '11401200001' THEN CT2_VALOR ELSE 0 END) AS DEBITO_ALMOX,
       SUM(CASE WHEN CT2_CREDIT = '11401200001' THEN CT2_VALOR ELSE 0 END) AS CREDITO_ALMOX,
       COUNT(*) AS QTDE
  FROM CT2010
 WHERE D_E_L_E_T_ = ' '
   AND CT2_FILIAL = '0102'
   AND CT2_DATA BETWEEN '20260601' AND '20260930'
   AND (CT2_DEBITO = '11401200001' OR CT2_CREDIT = '11401200001')
 GROUP BY SUBSTRING(CT2_DATA, 1, 6), CT2_TPSALD
 ORDER BY MES, CT2_TPSALD;

-- ---------------------------------------------------------------------
-- 9c) DOCUMENTO DA JORNADA EM SET/2026 (lote 008840 / doc 000011)
--     Todas as linhas geradas pela contabilizacao do custo.
-- ---------------------------------------------------------------------
SELECT CT2_LINHA, CT2_DC, CT2_DEBITO, CT2_CREDIT, CT2_VALOR,
       CT2_CCD, CT2_CCC, CT2_INCONS, CT2_TPSALD, CT2_LP, CT2_HIST
  FROM CT2010
 WHERE D_E_L_E_T_ = ' '
   AND CT2_FILIAL = '0102'
   AND CT2_DATA BETWEEN '20260901' AND '20260930'
   AND CT2_LOTE = '008840'
   AND CT2_DOC = '000011'
 ORDER BY CT2_LINHA;

-- ---------------------------------------------------------------------
-- 9d) LINHAS INCONSISTENTES do periodo (sem conta de debito OU sem CC)
--     Sao os lancamentos "pendentes" (CT2_INCONS = 'S'): nao podem ser
--     confirmados na tela e ficam retidos na CTBA350.
--     ATENCAO: credito em conta de estoque normalmente NAO exige CC
--     (falso positivo se o filtro for OR sobre os dois lados).
-- ---------------------------------------------------------------------
SELECT CT2_DATA, CT2_LOTE, CT2_DOC, CT2_LINHA, CT2_DC,
       CT2_DEBITO, CT2_CREDIT, CT2_VALOR, CT2_CCD, CT2_CCC,
       CT2_INCONS, CT2_TPSALD, CT2_LP, CT2_HIST
  FROM CT2010
 WHERE D_E_L_E_T_ = ' '
   AND CT2_FILIAL = '0102'
   AND CT2_DATA BETWEEN '20260901' AND '20260930'
   AND CT2_LP = '666'
   AND (ISNULL(LTRIM(RTRIM(CT2_DEBITO)), '') = ''
     OR ISNULL(LTRIM(RTRIM(CT2_CCD)), '') = '')
 ORDER BY CT2_DATA, CT2_DOC, CT2_LINHA;

-- ---------------------------------------------------------------------
-- 9e) SD3 DAS 3 LINHAS PENDENTES DA PLANILHA ctb_implanc.xlsx
--     (linhas 075 e 076 = doc MC.1001.00174; linha 403 = doc MC.0301.00126)
--     Confirma se sao TM 999 (ajuste de inventario) e se vieram de
--     requisicao (D3_NUMSA) ou nao.
-- ---------------------------------------------------------------------
SELECT D3_DOC, D3_ITEM, D3_COD, D3_TM, D3_ESTORNO, D3_CC,
       D3_CUSTO1, D3_QUANT, D3_NUMSA, D3_EMISSAO,
       ISNULL(LTRIM(RTRIM(D3_SEQCALC)), '') AS SEQCALC,
       ISNULL(LTRIM(RTRIM(D3_DIACTB)), '')  AS DIACTB
  FROM SD3010
 WHERE D_E_L_E_T_ = ' '
   AND D3_FILIAL = '0102'
   AND D3_DOC IN ('MC.1001.00174', 'MC.0301.00126')
 ORDER BY D3_DOC, D3_ITEM, D3_TM;

-- ---------------------------------------------------------------------
-- 9f) DIMENSIONAMENTO: baixas 502 e 999 de set/2026 SEM centro de custo
--     (D3_CC vazio) - o volume que a condicao do Lancamento Padrao
--     eliminaria da contabilizacao.
-- ---------------------------------------------------------------------
SELECT D3_TM,
       COUNT(*)                    AS QTDE,
       SUM(ISNULL(D3_CUSTO1, 0))   AS VALOR_CUSTO,
       SUM(CASE WHEN ISNULL(LTRIM(RTRIM(D3_SEQCALC)), '') <> '' THEN 1 ELSE 0 END) AS COM_SEQCALC
  FROM SD3010
 WHERE D_E_L_E_T_ = ' '
   AND D3_FILIAL = '0102'
   AND D3_EMISSAO BETWEEN '20260901' AND '20260930'
   AND ISNULL(LTRIM(RTRIM(D3_ESTORNO)), '') <> 'S'
   AND D3_TM IN ('502', '999')
   AND ISNULL(LTRIM(RTRIM(D3_CC)), '') = ''
 GROUP BY D3_TM;

-- ---------------------------------------------------------------------
-- 9g) SB1 DOS PRODUTOS DAS PENDENCIAS
--     VCTBL002 (expressao de conta do LP de custo) devolve "" quando:
--       - o produto tem B1_XCTCUST/XCTDESP/XCTCIND preenchidos E o
--         centro de custo nao comeca por 60/70/80/90/50/10-14/0199;
--       - ou o produto nao tem B1_CONTA.
--     => movimento sem centro de custo (ajuste de inventario) gera
--        lancamento sem conta de debito.
-- ---------------------------------------------------------------------
SELECT B1_COD, B1_DESC, B1_CONTA, B1_CC,
       B1_XCTCUST, B1_XCTDESP, B1_XCTCIND
  FROM SB1010
 WHERE B1_COD IN (SELECT D3_COD FROM SD3010
                   WHERE D_E_L_E_T_ = ' '
                     AND D3_FILIAL = '0102'
                     AND D3_DOC IN ('MC.1001.00174', 'MC.0301.00126'));

-- ---------------------------------------------------------------------
-- 9h) PARAMETROS RELEVANTES (SX6)
-- MV_PRELAN=N/S/D | MV_ALTLCTO | MV_CT105MS | MV_CT350SL | MV_CUSMED
-- MV_ATUSAL | MV_CTGBLOQ
-- ---------------------------------------------------------------------
SELECT X6_PARM, X6_CONTEUD
  FROM SX6010
 WHERE X6_PARM IN ('MV_PRELAN', 'MV_ALTLCTO', 'MV_CT105MS', 'MV_CT350SL',
                   'MV_CUSMED', 'MV_ATUSAL', 'MV_CTGBLOQ')
 ORDER BY X6_PARM;

-- ---------------------------------------------------------------------
-- 9i) REGRA DO LANCAMENTO PADRAO (CT5) - LP 666 (requisicoes/saida),
--     668 (entrada/devolucao), 674/676 (inventario), 679/680 (apropriacao)
--     Verifique se existe a CONDICAO de geracao (o "Cond." do Lancamento
--     Padrao) e se ela esta nas DUAS sequencias (001 debito / 002 credito).
-- ---------------------------------------------------------------------
SELECT CT5_LANPAD, CT5_SEQUEN, CT5_STATUS, CT5_DC,
       CT5_DEBITO, CT5_CREDIT, CT5_CCD, CT5_CCC, CT5_HIST,
       CT5_TPSALD, CT5_ORIGEM, CT5_TABORI
  FROM CT5010
 WHERE D_E_L_E_T_ = ' '
   AND CT5_LANPAD IN ('666', '668', '674', '676', '679', '680')
 ORDER BY CT5_LANPAD, CT5_SEQUEN;

-- ---------------------------------------------------------------------
-- 9j) DISCOVERY DAS COLUNAS FISICAS (nome real do campo de "Condicao"
--     e de qualquer campo de condicao/exigencia da CT5 neste build).
--     Rodar SEMPRE antes de escrever query com nomes de campo.
-- ---------------------------------------------------------------------
SELECT ORDINAL_POSITION, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME = 'CT5010'
 ORDER BY ORDINAL_POSITION;

-- 9k) Colunas fisicas da CT2 (confirmar CT2_INCONS, CT2_TPSALD, CT2_LP...)
SELECT ORDINAL_POSITION, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME = 'CT2010'
 ORDER BY ORDINAL_POSITION;
