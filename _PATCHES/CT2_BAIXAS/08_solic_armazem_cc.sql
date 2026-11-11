-- =====================================================================
-- 08 - VERIFICACAO CENTRO DE CUSTO DA SOLICITACAO AO ARMAZEM (SCP)
--      (informacao do processo: o Centro de Custo e informado na
--       Solicitacao ao Armazem, NAO no cadastro do produto; e o custo
--       medio processando os itens de inventario TM 999)
-- =====================================================================

-- 8a) CONFIRMAR NOMES REAIS DOS CAMPOS ANTES DE USAR AS ROTINAS
--     (nao assumir nomes: verificar na estrutura fisica)
SELECT COLUMN_NAME,
       DATA_TYPE,
       CHARACTER_MAXIMUM_LENGTH AS TAMANHO
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME = 'SCP010'
   AND COLUMN_NAME LIKE 'CP_%'
 ORDER BY COLUMN_NAME;

SELECT COLUMN_NAME,
       DATA_TYPE,
       CHARACTER_MAXIMUM_LENGTH AS TAMANHO
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME = 'SD3010'
   AND (COLUMN_NAME LIKE 'D3_%SA%' OR COLUMN_NAME LIKE 'D3_NUM%')
 ORDER BY COLUMN_NAME;

-- =====================================================================
-- 8b) BAIXAS TM 502 NAO CONTABILIZADAS x SOLICITACAO AO ARMAZEM
--     Verifica se o pedido de origem (D3_NUMSA) tem Centro de Custo
--     (CP_CC) preenchido. Se o pedido tem CP_CC e a baixa segue sem
--     lancamento, o problema esta na regra do LP 666 (ver script 07b)
--     ou no SEQCALC (script 07a) - nao no cadastro do produto.
--     Confirmado o nome do campo do item (8a), descomente o join
--     pela linha da solicitacao para precisao por item.
-- =====================================================================

SELECT DISTINCT
       D.D3_DOC,
       D.D3_ITEM,
       D.D3_COD,
       D.D3_TM,
       D.D3_EMISSAO,
       D.D3_NUMSA,
       D.D3_QUANT,
       D.D3_CUSTO1,
       S.CP_NUM,
       S.CP_CC,
       S.CP_QUANT,
       S.CP_QUJE
  FROM SD3010 D
  LEFT JOIN SCP010 S
         ON S.CP_FILIAL   = D.D3_FILIAL
        AND S.CP_NUM      = D.D3_NUMSA
        -- AND S.CP_ITEM   = D.D3_ITEMSA   -- confirmar nome do campo (8a)
        AND S.D_E_L_E_T_  = ' '
 WHERE D.D_E_L_E_T_ = ' '
   AND D.D3_FILIAL  = '0102'
   AND D.D3_EMISSAO BETWEEN '20260901' AND '20260930'
   AND ISNULL(D.D3_ESTORNO, '') <> 'S'
   AND D.D3_TM      = '502'
   AND ISNULL(LTRIM(RTRIM(D.D3_DIACTB)), '') = ''
 ORDER BY D.D3_NUMSA, D.D3_COD;

-- =====================================================================
-- 8c) BASE COMPARATIVA: baixas TM 502 JA contabilizadas (por exemplo,
--     em meses anteriores que funcionaram) - servem como referencia
--     do que um caso normal tem preenchido:
-- =====================================================================

SELECT TOP 20
       D3_DOC, D3_ITEM, D3_COD, D3_TM, D3_EMISSAO, D3_NUMSA,
       D3_QUANT, D3_CUSTO1,
       ISNULL(LTRIM(RTRIM(D3_SEQCALC)), '') AS SEQCALC,
       ISNULL(LTRIM(RTRIM(D3_DIACTB)), '')  AS DIACTB
  FROM SD3010
 WHERE D_E_L_E_T_ = ' '
   AND D3_FILIAL  = '0102'
   AND ISNULL(D3_ESTORNO, '') <> 'S'
   AND D3_TM = '502'
   AND ISNULL(LTRIM(RTRIM(D3_DIACTB)), '') <> ''
 ORDER BY D3_EMISSAO DESC;
