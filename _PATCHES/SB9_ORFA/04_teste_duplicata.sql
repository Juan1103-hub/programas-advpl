-- =====================================================================
-- SB9 ORFA - 04 - TESTE DE DUPLICATA (assinatura real da IMPSLDINI)
--
--     A IMPSLDINI grava B9_QINI e B9_VINI1 JUNTOS (IMPSLDINI.PRW:595),
--     entao a linha orfa DUPLICA quantidade e valor de uma linha datada
--     ja existente. Exemplo do MC.1001.00022:
--       orfa      : QTD 3 / VALOR 267 / CUSTO 0
--       datada    : 20260901 / QTD 3 / VALOR 267 / CUSTO 89
--
--     DIAGNOSTICO:
--       DUPLICA      -> seguro marcar (e a linha datada ja tem o custo)
--       NAO DUPLICA  -> NAO marcar, investigar antes
--
--     ATENCAO: o console do Webapp CORTA o ultimo caractere da ultima
--     linha. Por isso o ORDER BY e curto e ha uma linha inofensiva
--     depois dele. Nao usar WITH (NOLOCK).
--     SQL Server - APSDU - ASCII puro.
-- =====================================================================
SELECT O.B9_FILIAL  AS FILIAL,
       O.B9_COD     AS CODIGO,
       O.B9_LOCAL   AS LOCAL,
       O.B9_QINI    AS QTD_ORFA,
       O.B9_VINI1   AS VALOR_ORFA,
       C.B9_DATA    AS DT_DUPLICADA,
       C.B9_CM1     AS CUSTO_DUPLIC,
       CASE WHEN C.B9_DATA IS NULL
            THEN 'NAO_DUPLICA'
            ELSE 'DUPLICA' END AS DIAG
  FROM SB9010 O
  LEFT JOIN SB9010 C
         ON C.B9_FILIAL = O.B9_FILIAL
        AND C.B9_COD    = O.B9_COD
        AND C.B9_LOCAL  = O.B9_LOCAL
        AND C.D_E_L_E_T_ = ' '
        AND LEN(LTRIM(RTRIM(COALESCE(C.B9_DATA, '')))) > 0
        AND C.B9_QINI  = O.B9_QINI
        AND C.B9_VINI1 = O.B9_VINI1
 WHERE O.D_E_L_E_T_ = ' '
   AND LEN(LTRIM(RTRIM(COALESCE(O.B9_DATA, '')))) = 0
   AND (O.B9_QINI <> 0 OR O.B9_VINI1 <> 0)
 ORDER BY 1, 2, 3;
-- FIM (linha acima e a ultima; se cortar, corta aqui e nao no ORDER BY)
