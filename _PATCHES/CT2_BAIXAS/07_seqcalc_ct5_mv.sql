-- =====================================================================
-- 07 - VERIFICACAO AVANCADA (pesquisa TOTVS 2026-10-21)
--
-- 7a) D3_SEQCALC: sem este campo preenchido pela MATA330 (calculo do
--     custo medio), a MATA331 NAO contabiliza o movimento. A coluna
--     COM_SEQCALC do script 03 ja mostra o total; aqui fica o detalhe
--     dos movimentos SEM SEQCALC:
-- =====================================================================

SELECT D3_DOC, D3_COD, D3_TM, D3_CF, D3_SEQCALC,
       D3_EMISSAO, D3_QUANT, D3_CUSTO1,
       ISNULL(LTRIM(RTRIM(D3_DIACTB)), '') AS DIACTB
  FROM SD3010
 WHERE D_E_L_E_T_ = ' '
   AND D3_FILIAL  = '0102'
   AND D3_EMISSAO BETWEEN '20260901' AND '20260930'
   AND ISNULL(LTRIM(RTRIM(D3_ESTORNO)), '') <> 'S'
   AND D3_TM IN ('502', '999')
   AND ISNULL(LTRIM(RTRIM(D3_SEQCALC)), '') = ''
 ORDER BY D3_TM, D3_COD;

-- =====================================================================
-- 7b) REGRA DO LANCAMENTO PADRAO (LP) - SAIDA DE SALDO EM ESTOQUE
--     (LP 666 requisicao/saida, 668 entrada/devolucao, 679/680
--      apropriacao indireta, 674/676 inventario).
--
-- A regra (tabela CT5) define SE o movimento sera contabilizado e DE
-- ONDE a conta e o centro de custo sao puxados (CT5_DEBITO, CT5_CREDIT,
-- CT5_CCD, CT5_CCC sao EXPRESSOES AdvPL). Para EXCLUIR o TM 999 da
-- contabilizacao, o mecanismo oficial e incluir CONDICAO na regra.
-- NAO existe filtro de Tipo de Movimento na Jornada do Acompanha Custos.
--
-- ATENCAO: o codigo do LP e o campo CT5_LANPAD (CT5_LP nao existe
-- fisicamente neste build).
-- =====================================================================

SELECT CT5_LANPAD, CT5_SEQUEN, CT5_STATUS, CT5_DC,
       CT5_DEBITO, CT5_CREDIT, CT5_CCD, CT5_CCC, CT5_HIST,
       CT5_TPSALD, CT5_ORIGEM, CT5_TABORI
  FROM CT5010
 WHERE D_E_L_E_T_ = ' '
   AND CT5_LANPAD IN ('666', '668', '674', '676', '679', '680')
 ORDER BY CT5_LANPAD, CT5_SEQUEN;

-- =====================================================================
-- 7c) PARAMETROS PARA DEIXAR O PROBLEMA VISIVEL (configurar no SX6 -
--     parametros, antes de "Refazer contabilizacao" na Jornada):
--   MV_CT105MS = S  -> mostra mensagem de inconsistencia na integracao
--   MV_ALTLCTO  = S -> permite ver/editar lancamento de integracao
--   MV_PRELAN   = D -> movimento gravado como PRE-LANCAMENTO quando
--                      houver inconsistencia (recomendacao TOTVS)
-- Com essa combinacao, os movimentos sem Centro de Custo/Conta aparecem
-- como lancamento inconsistente na tela, em vez de ausentes.
-- =====================================================================
-- SELECT X6_PARM, X6_CONTEUD
--   FROM SX6010
--  WHERE X6_PARM IN ('MV_PRELAN', 'MV_ALTLCTO', 'MV_CT105MS', 'MV_CUSMED',
--                    'MV_ATUSAL', 'MV_CT350SL');
