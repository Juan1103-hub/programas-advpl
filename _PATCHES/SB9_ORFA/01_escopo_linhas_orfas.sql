-- =====================================================================
-- SB9 ORFA - 01 - ESCOPO DAS LINHAS ORFAS (RODAR ANTES DE QUALQUER COISA)
--
--     Objetivo: saber EXATAMENTE quantas linhas orfas existem na SB9
--     antes de apagar qualquer coisa. A IMPSLDINI pode ter sido rodada
--     mais de uma vez - apagar so a do produto do log seria consertar
--     o sintoma.
--
--     REGRA DE NEGOCIO: na SB9 a chave e FILIAL+COD+LOCAL+DATA, sendo
--     DATA = fechamento do mes (20260331, 20260430, ...). Uma linha com
--     B9_DATA vazio nao pertence a nenhum mes e e orfa.
--
--     COMO USAR:
--       1) rode 01-A  (conta TODAS as orfas da empresa - o escopo real)
--       2) rode 01-B  (lista as orfas com detalhe para conferencia)
--       3) rode 01-C  (mostra o historico do produto do log, provando
--                      que a linha com data ja traz o custo 89)
--
--     NAO rode o arquivo 03 (DELETE) antes de ver o resultado daqui.
--
--     ATENCAO: nao usar WITH (NOLOCK) - o console do Webapp remove o
--              hint e quebra o WHERE.
--     SQL Server - APSDU - ASCII puro.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 01-A) QUANTAS LINHAS ORFAS EXISTEM NA SB9 INTEIRA?
--      Esta e a pergunta que decide o tamanho do problema.
--      Se vier 1  -> so a do log do MC.1001.00022.
--      Se vier N  -> a rotina rodou N vezes ou afetou N itens.
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS LINHAS_ORFAS
  FROM SB9010
 WHERE D_E_L_E_T_ = ' '
   AND LEN(LTRIM(RTRIM(ISNULL(B9_DATA, '')))) = 0;


-- ---------------------------------------------------------------------
-- 01-B) LISTA COMPLETA DAS ORFAS (para conferencia detalhada)
--      Mostra tambem se ja existe a linha CORRETA do mesmo mes,
--      que e a que o MATA330 deve usar.
-- ---------------------------------------------------------------------
SELECT O.R_E_C_D_E_L_        AS RECNO,
       O.B9_FILIAL           AS FILIAL,
       O.B9_COD              AS CODIGO,
       O.B9_LOCAL            AS LOCAL,
       '<VAZIA>'             AS DATA_ORFA,
       O.B9_QINI             AS QTD_ORFA,
       O.B9_VINI1            AS VALOR_ORFA,
       O.B9_CM1              AS CUSTO_ORFA,
       C.B9_DATA             AS DATA_CORRETA_EXISTENTE,
       C.B9_QINI             AS QTD_CORRETA,
       C.B9_VINI1            AS VALOR_CORRETA,
       C.B9_CM1              AS CUSTO_CORRETA
  FROM SB9010 O
  LEFT JOIN SB9010 C
         ON C.B9_FILIAL = O.B9_FILIAL
        AND C.B9_COD    = O.B9_COD
        AND C.B9_LOCAL  = O.B9_LOCAL
        AND C.D_E_L_E_T_ = ' '
        AND LEN(LTRIM(RTRIM(ISNULL(C.B9_DATA, '')))) > 0
 WHERE O.D_E_L_E_T_ = ' '
   AND LEN(LTRIM(RTRIM(ISNULL(O.B9_DATA, '')))) = 0
 ORDER BY O.B9_FILIAL, O.B9_COD, O.B9_LOCAL;


-- ---------------------------------------------------------------------
-- 01-C) HISTORICO DO PRODUTO DO LOG (MC.1001.00022, armazem 02)
--      Prova que a linha de 20260901 ja traz 3 / 267 / 89 - ou seja,
--      o custo medio que a planilha pede JA ESTAVA NO BANCO.
--      A linha com data vazia (3 / 267 / 0) e a duplicata inutil.
-- ---------------------------------------------------------------------
SELECT R_E_C_D_E_L_  AS RECNO,
       B9_FILIAL     AS FILIAL,
       B9_COD        AS CODIGO,
       B9_LOCAL      AS LOCAL,
       B9_DATA       AS DATA,
       B9_QINI       AS QTD,
       B9_VINI1      AS VALOR_TOTAL,
       B9_CM1        AS CUSTO_MEDIO,
       CASE WHEN LEN(LTRIM(RTRIM(ISNULL(B9_DATA, '')))) = 0
            THEN 'ORFA - CANDIDATA A REMOCAO'
            ELSE 'OK' END AS SITUACAO
  FROM SB9010
 WHERE D_E_L_E_T_ = ' '
   AND B9_COD   = 'MC.1001.00022'
   AND B9_LOCAL = '02'
 ORDER BY B9_FILIAL, B9_DATA;
