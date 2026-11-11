-- =====================================================================
-- SB9 ORFA - 00 - DISCOVERY DE COLUNAS (RODAR PRIMEIRO)
--
--     CONTEXTO: a rotina IMPSLDINI.PRW gravou uma linha na SB9 com
--     B9_DATA vazio. A SB9 e UMA LINHA POR FILIAL+COD+LOCAL+DATA
--     (fechamento mensal), entao a linha sem data e orfa e pode
--     contaminar o MATA300/MATA330 e o Kardex.
--
--     Objetivo: validar os nomes de coluna da SB9010 antes de rodar
--     qualquer UPDATE/DELETE, evitando erro 207 (Invalid column name).
--
--     Como usar:
--       1) rode 00-A (confere se a tabela existe)
--       2) rode 00-B (lista TODAS as colunas da SB9010)
--       3) confira se cada campo citado nos arquivos 01 a 04 existe
--
--     ATENCAO: nao usar WITH (NOLOCK) - o console do Webapp remove o
--              hint e quebra o WHERE.
--
--     PADRAO DE DATA VAZIA: B9_DATA e C(8) (YYYYMMDD), nao DATE
--     (fonte: skills/vortice/tabelas-protheus/SKILL.md e CLAUDE.md).
--     O teste de vazio usado nos arquivos 01 a 03 e o mesmo que ja
--     roda em producao em FONTES/ZMMA01.PRW:
--       LEN(LTRIM(RTRIM(ISNULL(B9_DATA, '')))) = 0
--
--     SQL Server - APSDU - ASCII puro.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 00-A) A TABELA SB9010 EXISTE NESTA EMPRESA?
-- ---------------------------------------------------------------------
SELECT TABLE_NAME, TABLE_TYPE
  FROM INFORMATION_SCHEMA.TABLES
 WHERE TABLE_NAME = 'SB9010';


-- ---------------------------------------------------------------------
-- 00-B) COLUNAS DA SB9010
--      Campos usados nos arquivos seguintes:
--        R_E_C_D_E_L_  (identificador unico do registro - chave do DELETE)
--        B9_FILIAL, B9_COD, B9_LOCAL, B9_DATA
--        B9_QINI, B9_VINI1, B9_CM1
--        D_E_L_E_T_
-- ---------------------------------------------------------------------
SELECT ORDINAL_POSITION AS ORDEM,
       COLUMN_NAME      AS COLUNA,
       DATA_TYPE        AS TIPO,
       CHARACTER_MAXIMUM_LENGTH AS TAM
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME = 'SB9010'
 ORDER BY ORDINAL_POSITION;
