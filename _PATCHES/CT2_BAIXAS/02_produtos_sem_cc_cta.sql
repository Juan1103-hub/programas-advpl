-- =====================================================================
-- 02 - PRODUTOS COM BAIXAS (TM 502 e 999) EM SETEMBRO/2026 - FILIAL 0102
--      QUE ESTAO SEM CENTRO DE CUSTO (B1_CC) OU SEM CONTA CONTABIL (B1_CONTA)
--
-- Objetivo: gerar a LISTA BASE da carga do cadastro de produtos.
--   - Coluna TM_502 / TM_999  = produto aparece em baixa de consumo (502)
--     e/ou ajuste/inventario (999) no periodo;
--   - Coluna CUSTO_TM_502     = valor total baixado como consumo (deve
--     virar credito na conta almoxarifado depois da contabilizacao);
--   - Coluna SIT_CC / SIT_CTA = situacao do cadastro (campo B1_CONTA).
--
-- Antes de carregar, valide cada Centro de Custo e Conta no script 05.
-- NAO incluir produtos apenas de ajuste (somente TM 999 = Nao na TM_502)
-- na carga sem avaliar: o tratamento deles pode ser outro.
-- =====================================================================

SELECT B1.B1_COD,
       B1.B1_DESC,
       B1.B1_TIPO,
       CASE WHEN ISNULL(LTRIM(RTRIM(B1.B1_CC)), '') = ''
            THEN 'Vazio' ELSE 'Preenchido' END              AS SIT_CC,
       B1.B1_CC,
       CASE WHEN ISNULL(LTRIM(RTRIM(B1.B1_CONTA)), '') = ''
            THEN 'Vazio' ELSE 'Preenchido' END              AS SIT_CTA,
       B1.B1_CONTA,
       MAX(CASE WHEN D.D3_TM = '502' THEN 'Sim' ELSE 'Nao' END) AS TM_502,
       MAX(CASE WHEN D.D3_TM = '999' THEN 'Sim' ELSE 'Nao' END) AS TM_999,
       SUM(CASE WHEN D.D3_TM = '502' THEN D.D3_CUSTO1 ELSE 0 END) AS CUSTO_TM_502,
       COUNT(*)                                             AS QTDE_MOV
  FROM SD3010 D
  INNER JOIN SB1010 B
          ON B.B1_FILIAL = D.D3_FILIAL
         AND B.B1_COD    = D.D3_COD
         AND B.D_E_L_E_T_ = ' '
 WHERE D.D_E_L_E_T_  = ' '
   AND D.D3_FILIAL   = '0102'
   AND D.D3_EMISSAO BETWEEN '20260901' AND '20260930'
   AND ISNULL(D.D3_ESTORNO, '') <> 'S'
   AND D.D3_TM IN ('502', '999')
 GROUP BY B1.B1_COD, B1.B1_DESC, B1.B1_TIPO, B1.B1_CC, B1.B1_CONTA
 ORDER BY CASE WHEN ISNULL(LTRIM(RTRIM(B1.B1_CC)), '') = ''    THEN 0 ELSE 1 END,
          CASE WHEN ISNULL(LTRIM(RTRIM(B1.B1_CONTA)), '') = ''   THEN 0 ELSE 1 END,
          B1.B1_COD;

-- =====================================================================
-- Criterio de prioridade do resultado:
--   1o  produtos com SIT_CC = Vazio e TM_502 = Sim  (impedem o credito)
--   2o  produtos com SIT_CTA = Vazio e TM_502 = Sim
--   3o  demais
-- =====================================================================
