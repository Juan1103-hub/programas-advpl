-- =====================================================================
-- 05 - VALIDAR OS CENTROS DE CUSTO E CONTAS CONTABEIS DA PLANILHA
--      ANTES DE CARREGAR EM SB1
--
-- Substitua a lista do IN pelos valores coletados do acervo de centros
-- de custo e de contas da planilha de carga e execute as duas consultas.
-- Todo valor que NAO voltar linha aqui e invalido: a rotina de carga
-- ZATUCC rejeitara a linha correspondente (contador de erros).
-- =====================================================================

-- 5a - Centros de Custo existentes na filial 0102 (tabela CTT)
SELECT CTT_CUSTO,
       CTT_DESC01
  FROM CTT1010
 WHERE D_E_L_E_T_ = ' '
   AND CTT_FILIAL = '0102'
   AND CTT_CUSTO IN ('000001', '000002');

-- 5b - Contas Contabeis existentes na filial 0102 (tabela CT1)
SELECT CT1_CONTA,
       CT1_DESC01
  FROM CT11010
 WHERE D_E_L_E_T_ = ' '
   AND CT1_FILIAL = '0102'
   AND CT1_CONTA IN ('11401200001');

-- =====================================================================
-- NOTA: se alguma tabela responder informando que o cadastro esta
-- compartilhado entre filiais, troque o filtro CTT_FILIAL/CT1_FILIAL
-- por espacos em branco (' ') e refaca - ajuste no APSDU conforme o
-- modo de compartilhamento real (X2_MODO) e informe antes de carregar.
-- =====================================================================
