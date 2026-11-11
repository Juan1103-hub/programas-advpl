-- =====================================================================
-- 01 - VERIFICAR EXISTENCIA DOS CAMPOS EM SB1
-- Objetivo: confirmar que os campos B1_CC (Centro de Custo) e B1_CTA
--           (Conta Contabil) existem na estrutura fisica da tabela SB1010
--           ANTES de gerar a planilha de carga ou executar qualquer update.
-- Executar no APSDU ou SQL Server Management Studio (base da empresa 01).
-- =====================================================================

SELECT COLUMN_NAME,
       DATA_TYPE,
       CHARACTER_MAXIMUM_LENGTH AS TAMANHO,
       IS_NULLABLE
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME = 'SB1010'
   AND COLUMN_NAME IN ('B1_CC', 'B1_CONTA', 'B1_ITEMCC', 'B1_CLVL', 'B1_MSBLQL', 'B1_DESC', 'B1_TIPO')
 ORDER BY COLUMN_NAME;

-- =====================================================================
-- IMPORTANTE (pesquisa TOTVS 2026-10-21):
-- A conta contabil padrao do produto e B1_CONTA ("Cta Contabil").
-- O campo B1_CTA NAO existe no dicionario padrao; se esta consulta
-- revelar um campo custom com esse nome na sua base, informe o autor
-- da carga antes de usar (a rotina ZATUCC usa o campo padrao B1_CONTA).
-- Campos auxiliares de contabilidade do produto: B1_ITEMCC (item
-- contabil), B1_CLVL (classe de valor), B1_CCCCUSTO, B1_APROPRI.
-- =====================================================================

-- =====================================================================
-- OBSERVACAO IMPORTANTE
-- Protheus grava campos texto vazios como espacos (' '), nao como NULL.
-- Por isso nas demais consultas usamos LTRIM(RTRIM(...)) = '' para
-- identificar campo vazio (metodo seguro nos dois cenarios).
-- =====================================================================
