-- =====================================================================
-- SB9 ORFA - 03 - CONFERENCIA FINAL (RODAR DEPOIS DO 02)
--
--     Objetivo: provar que o problema foi resolvido e que NADA mais
--     foi afetado. Rode TODAS antes de considerar encerrado.
--
--     ATENCAO: nao usar WITH (NOLOCK) - o console do Webapp remove o
--              hint e quebra o WHERE.
--     SQL Server - APSDU - ASCII puro.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 03-A) NENHUMA ORFA ATIVA RESTANTE (deve vir 0)
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS ORFAS_ATIVAS
  FROM SB9010
 WHERE D_E_L_E_T_ = ' '
   AND LEN(LTRIM(RTRIM(ISNULL(B9_DATA, '')))) = 0;


-- ---------------------------------------------------------------------
-- 03-B) O HISTORICO MENSAL DO PRODUTO FICOU INTACTO?
--       As linhas 20260430, 20260531, 20260630, 20260831, 20260901
--       e 20261001 DEVEM continuar la com os valores originais.
--       Se qualquer uma sumiu ou mudou de valor, ALGO DEU ERRADO -
--       rode o 02-C (restauracao) imediatamente.
-- ---------------------------------------------------------------------
SELECT R_E_C_D_E_L_  AS RECNO,
       B9_FILIAL     AS FILIAL,
       B9_COD        AS CODIGO,
       B9_LOCAL      AS LOCAL,
       B9_DATA       AS DATA,
       B9_QINI       AS QTD,
       B9_VINI1      AS VALOR_TOTAL,
       B9_CM1        AS CUSTO_MEDIO,
       D_E_L_E_T_    AS DELETED
  FROM SB9010
 WHERE D_E_L_E_T_ = ' '
   AND B9_COD   = 'MC.1001.00022'
   AND B9_LOCAL = '02'
 ORDER BY B9_FILIAL, B9_DATA;


-- ---------------------------------------------------------------------
-- 03-C) INTEGRIDADE GERAL - A SB9 CONTINUA CONSISTENTE?
--       Confere se ha produtos com linha orfa ativa em qualquer filial.
-- ---------------------------------------------------------------------
SELECT B9_FILIAL AS FILIAL,
       COUNT(*)  AS ORFAS
  FROM SB9010
 WHERE D_E_L_E_T_ = ' '
   AND LEN(LTRIM(RTRIM(ISNULL(B9_DATA, '')))) = 0
 GROUP BY B9_FILIAL;


-- ---------------------------------------------------------------------
-- 03-D) PROXIMO PASSO DEPOIS DAQUI
--
--       Com a linha orfa marcada, rode o MATA330 na mao:
--         Miscelanea -> Calculos -> Custo Medio
--
--       Parametros (fonte TDN 360024805291):
--         Data Limite Final ....... 30/09/2026
--         Atualiza Arq. Movimentacao  Sim   (OBRIGATORIO - atualiza
--                                             SD3, SD1, SD2, SDB, SD5)
--         Gera Lancamento Contabil  Sim   (faz o item ENTRAR NO RAZAO)
--         Apaga Estornos ........... Nao
--         Calcula Mao de Obra ...... Nao
--         Calculo do custo por ..... Filial corrente
--
--       Depois rode o 04 para conferir se o D3_CUSTO1 zerado foi
--       corrigido e se o item entrou no CT2.
-- ---------------------------------------------------------------------
