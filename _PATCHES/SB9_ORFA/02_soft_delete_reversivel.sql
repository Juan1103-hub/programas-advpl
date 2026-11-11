-- =====================================================================
-- SB9 ORFA - 02 - SOFT DELETE REVERSIVEL (marcar, nao apagar)
--
--     ESCOPO FINAL: UMA linha unica, confirmada pelo 04.
--
--     CONCLUSAO DAS INVESTIGACOES (23/10):
--       - 111 linhas tem B9_DATA vazio, MAS quase todas com 0/0/0,
--         espalhadas por dezenas de produtos e por AMBAS as filiais.
--         B9_DATA vazio e ESTADO NORMAL deste ambiente, nao dano.
--       - 6 linhas tem valor nao-zero. O 04 (teste de duplicata)
--         mostrou que APENAS UMA tem a assinatura da IMPSLDINI:
--
--         0102 / MC.1001.00022 / 02 / QTD 3 / VALOR 267
--         -> duplica a linha 20260901 (QTD 3 / VALOR 267 / CUSTO 89)
--
--       - As outras 5 (MC.0803.00001 x2, MC.1003.00015, PA.0007.00001,
--         PA.0007.00003) NAO duplicam. NAO sao da IMPSLDINI e NAO devem
--         ser tocadas aqui. Investigacao a parte, se voce quiser.
--
--     POR ISSO o WHERE abaixo e ESCOPO POR PRODUTO, nao criterio geral.
--     Criterio geral ja me enganou uma vez (marcou as 111).
--
--     Por que SOFT DELETE e nao DELETE fisico:
--       1) e o padrao Protheus (D_E_L_E_T_ = '*')
--       2) e REVERSIVEL - se der problema, volta para ' ' (script 02-C)
--       3) nao perde o registro fisico
--
--     ATENCAO: R_E_C_D_E_L_ retornou 0 no console do Webapp, entao NAO
--              da para identificar linha unica por RECNO. O WHERE usa o
--              CONTEUDO (produto + armazem + data vazia + valor), que e
--              inequivoco para esta linha.
--
--     ATENCAO 2: nao usar WITH (NOLOCK) - o console do Webapp remove o
--              hint e quebra o WHERE.
--     SQL Server - APSDU - ASCII puro.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 02-A) BACKUP - LEIA E GUARDE O RESULTADO EM ARQUIVO
--       Isto nao altera nada. Copie a saida e guarde: e a sua
--       seguranca caso precise restaurar na mao.
--       Mostra tambem o R_E_C_D_E_L_, que vem 0 no console do Webapp
--       (limitacao conhecida) - por isso guarde TODOS os campos.
-- ---------------------------------------------------------------------
SELECT R_E_C_D_E_L_ AS RECNO,
       B9_FILIAL    AS FILIAL,
       B9_COD       AS CODIGO,
       B9_LOCAL     AS LOCAL,
       B9_DATA      AS DATA,
       B9_QINI      AS QTD,
       B9_VINI1     AS VALOR_TOTAL,
       B9_CM1       AS CUSTO_MEDIO,
       D_E_L_E_T_   AS DELETED
  FROM SB9010
 WHERE D_E_L_E_T_ = ' '
   AND B9_FILIAL  = '0102'
   AND B9_COD     = 'MC.1001.00022'
   AND B9_LOCAL   = '02'
   AND LEN(LTRIM(RTRIM(COALESCE(B9_DATA, '')))) = 0
   AND (B9_QINI <> 0 OR B9_VINI1 <> 0);


-- ---------------------------------------------------------------------
-- 02-B) SOFT DELETE - A UNICA LINHA QUE ALTERA DADO
--
--       Marca como deletada a linha orfa. NAO apaga fisicamente.
--
--       SEGURANCA: o WHERE e ESCOPO POR PRODUTO, nao criterio geral.
--       Deve marcar EXATAMENTE 1 linha (a do MC.1001.00022, arm. 02).
--       Se marcar mais que 1, NAO faca commit.
--
--       Rode em transacao. Confira o numero de linhas. So faca COMMIT
--       se for igual a 1.
--
--       >>> SEGURANCA MAXIMA: rode primeiro com BEGIN TRAN + ROLLBACK
--           (modo teste, NADA e persistido) e confira quantas linhas
--           seriam afetadas. Depois repita com COMMIT.
-- ---------------------------------------------------------------------

-- PASSO 1 - TESTE SECO (nao persiste nada, so mostra o impacto)
BEGIN TRAN;

UPDATE SB9010
   SET D_E_L_E_T_ = '*'
 WHERE D_E_L_E_T_ = ' '
   AND B9_FILIAL  = '0102'
   AND B9_COD     = 'MC.1001.00022'
   AND B9_LOCAL   = '02'
   AND LEN(LTRIM(RTRIM(COALESCE(B9_DATA, '')))) = 0
   AND (B9_QINI <> 0 OR B9_VINI1 <> 0);

-- Confira: o numero abaixo TEM que ser igual a 1. Se for diferente,
-- nao descomente o COMMIT - volte e revise o WHERE.
SELECT @@ROWCOUNT AS LINHAS_MARCADAS;

-- Sempre desfaca neste primeiro passo:
ROLLBACK;


-- PASSO 2 - EXECUCAO REAL (so depois que o PASSO 1 bateu)
--           Descomente as linhas abaixo e rode.
--
-- BEGIN TRAN;
--
-- UPDATE SB9010
--    SET D_E_L_E_T_ = '*'
--  WHERE D_E_L_E_T_ = ' '
--    AND B9_FILIAL  = '0102'
--    AND B9_COD     = 'MC.1001.00022'
--    AND B9_LOCAL   = '02'
--    AND LEN(LTRIM(RTRIM(COALESCE(B9_DATA, '')))) = 0
--    AND (B9_QINI <> 0 OR B9_VINI1 <> 0);
--
-- -- Confira de novo. Se bater, descomente o COMMIT.
-- -- Se NAO bater, descomente o ROLLBACK.
-- SELECT @@ROWCOUNT AS LINHAS_MARCADAS;
-- COMMIT;
-- --ROLLBACK;


-- ---------------------------------------------------------------------
-- 02-C) RESTAURACAO - desfaz o soft delete INTEIRO
--       Use somente se algo sair errado. Volta para ' ' TODA linha
--       orfa que tenha sido marcada.
-- ---------------------------------------------------------------------
-- UPDATE SB9010
--    SET D_E_L_E_T_ = ' '
--  WHERE D_E_L_E_T_ = '*'
--    AND B9_FILIAL  = '0102'
--    AND B9_COD     = 'MC.1001.00022'
--    AND B9_LOCAL   = '02'
--    AND LEN(LTRIM(RTRIM(COALESCE(B9_DATA, '')))) = 0
--    AND (B9_QINI <> 0 OR B9_VINI1 <> 0);


-- ---------------------------------------------------------------------
-- 02-D) CONFERENCIA POS-ACTO - deve vir 0
--       Se vier 0, nenhuma linha orfa COM VALOR ficou ativa. Correto.
--       (As linhas orfas zeradas DEVEM continuar ativas - sao legitimas)
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS ORFAS_COM_VALOR_ATIVAS
  FROM SB9010
 WHERE D_E_L_E_T_ = ' '
   AND B9_FILIAL  = '0102'
   AND B9_COD     = 'MC.1001.00022'
   AND B9_LOCAL   = '02'
   AND LEN(LTRIM(RTRIM(COALESCE(B9_DATA, '')))) = 0
   AND (B9_QINI <> 0 OR B9_VINI1 <> 0);
