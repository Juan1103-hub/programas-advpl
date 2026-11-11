-- =====================================================================
-- 12) QUERIES DECISIVAS - SET/2026 - RAZAO CTBR400 x CTBA350
--
--     COMO EXECUTAR (importante, learned em 21/10/2026):
--       - No ANALISADOR do Protheus (Leitura de Buffer) os macros
--         %Table:% / %xFilial:% / GetSqlName() NAO sao expandidos: vao
--         literais para o SQL Server e retornam erro 102 / 208
--         ("Incorrect syntax near '%'" / "Invalid object name").
--         NESSA TELA use sempre o NOME FISICO da tabela (CT2010,
--         SD3010, SB1010...) - que e exatamente o que estas queries
--         ja usam.
--       - As queries abaixo JA usam nome fisico, entao funcionam no
--         Analisador, no SSMS e no APSDU.
--       - Nao usar WITH (NOLOCK): o console do Webapp remove o hint e
--         quebra o WHERE.
--       - Se aparecer erro 207 (Invalid column name), rode antes o
--         arquivo 00_colunas_banco.sql e me passe o resultado.
--
--     RESULTADO ESPERADO (para eu interpretar):
--       Q1 -> existe CT2_TPSALD = 9 em set/2026? (decide H1 x H2)
--       Q2 -> o credito da conta 11401200001 esta em tipo 1 ou 9?
--       Q3 -> diff 08/2026 (funcionou) x 09/2026 (falhou)
--       Q4 -> as 3 linhas pendentes (075/076/403) com rastreio
--
--     COMO ME ENTREGAR: exportar a grade de cada query para CSV e
--     colocar na pasta C:\Users\Vortice 0097\Desktop\apsdu_resultados\
--     (ou colar o texto aqui). Eu leio e faco a analise.
-- =====================================================================


-- =====================================================================
-- Q1) MAPA DO CT2 DE SET/2026 (filial 0102) POR TIPO DE SALDO
--     DECISIVO: se vier SO CT2_TPSALD = 1, nao existe pre-lancamento
--     (9) para efetivar -> o CTBA350 processa 0 item por construcao.
--     Se vier 9, o pre-lancamento existe e o problema e de parametro/
--     filtro do CTBA350 (periodo, filial, "Efetivar para Saldo = 1",
--     "Efetivar Parcialmente = Sim").
-- =====================================================================
SELECT CT2_TPSALD,
       CT2_ROTINA,
       CT2_ORIGEM,
       CT2_LP,
       CT2_DOC,
       CT2_DATA,
       COUNT(*)                  AS QTDE_LINHAS,
       SUM(ISNULL(CT2_VALOR, 0)) AS VALOR_TOTAL
  FROM CT2010
 WHERE CT2_FILIAL = '0102'
   AND CT2_DATA BETWEEN '20260901' AND '20260930'
 GROUP BY CT2_TPSALD, CT2_ROTINA, CT2_ORIGEM, CT2_LP, CT2_DOC, CT2_DATA
 ORDER BY CT2_TPSALD, CT2_DATA, CT2_DOC;
-- nome do csv sugerido: Q1_ct2_setembro.csv


-- =====================================================================
-- Q2) CONTA ALMOXARIFADO 11401200001 - DEBITO (entradas) x CREDITO
--     (baixas) POR MES E POR TIPO DE SALDO (202606 a 202609)
--     Se set/2026 tiver credito no tipo 1, o Razao DEVERIA mostrar.
--     Se o credito so existir no tipo 9, falta efetivar.
-- =====================================================================
SELECT SUBSTRING(CT2_DATA, 1, 6) AS MES,
       CT2_TPSALD,
       SUM(CASE WHEN CT2_DEBITO = '11401200001' THEN ISNULL(CT2_VALOR, 0) ELSE 0 END) AS DEBITO,
       SUM(CASE WHEN CT2_CREDIT = '11401200001' THEN ISNULL(CT2_VALOR, 0) ELSE 0 END) AS CREDITO,
       COUNT(*) AS QTDE
  FROM CT2010
 WHERE CT2_FILIAL = '0102'
   AND CT2_DATA BETWEEN '20260601' AND '20260930'
   AND (CT2_DEBITO = '11401200001' OR CT2_CREDIT = '11401200001')
 GROUP BY SUBSTRING(CT2_DATA, 1, 6), CT2_TPSALD
 ORDER BY MES, CT2_TPSALD;
-- nome do csv sugerido: Q2_conta_almox.csv


-- =====================================================================
-- Q3) DIFF DE ASSINATURA: MES QUE FUNCIONOU (08/2026) x MES QUE
--     FALHOU (09/2026) - mesma metodologia do caso de 11/09/2026,
--     onde o diff TPSALD 1 x 9 isolou a causa em 1 query.
-- =====================================================================
SELECT SUBSTRING(CT2_DATA, 1, 6) AS MES,
       CT2_TPSALD,
       CT2_ROTINA,
       CT2_ORIGEM,
       CT2_LP,
       CT2_MOEDLC,
       COUNT(*)                  AS QTDE_LINHAS,
       SUM(ISNULL(CT2_VALOR, 0)) AS VALOR_TOTAL
  FROM CT2010
 WHERE CT2_FILIAL = '0102'
   AND CT2_DATA BETWEEN '20260801' AND '20260930'
   AND (ISNULL(LTRIM(RTRIM(CT2_DEBITO)), '') <> ''
     OR ISNULL(LTRIM(RTRIM(CT2_CREDIT)), '') <> '')
 GROUP BY SUBSTRING(CT2_DATA, 1, 6), CT2_TPSALD, CT2_ROTINA,
          CT2_ORIGEM, CT2_LP, CT2_MOEDLC
 ORDER BY MES, CT2_TPSALD, CT2_ROTINA, CT2_LP;
-- nome do csv sugerido: Q3_diff_agosto_setembro.csv


-- =====================================================================
-- Q4) AS 3 LINHAS PENDENTES (075 / 076 / 403) - doc 000011, lote 008840
--     com rastreio completo: LP, inconsistencia, tipo de saldo, rotina,
--     origem e processo que gravaram o lancamento.
--     Se CT2_TPSALD = 9 -> ainda e pre-lancamento (nao efetivado):
--     corrigir a condicao do LP 666 + "Refazer contabilizacao" e so
--     depois efetivar (nao precisa excluir nada).
--     Se CT2_TPSALD = 1 -> ja esta no Razao: exige reprocessar o
--     periodo apos corrigir a condicao do LP 666.
-- =====================================================================
SELECT CT2_LINHA, CT2_DC, CT2_DEBITO, CT2_CREDIT, CT2_VALOR,
       CT2_CCD, CT2_CCC, CT2_ITEMD, CT2_ITEMC, CT2_LP,
       CT2_INCONS, CT2_TPSALD, CT2_MANUAL, CT2_ORIGEM, CT2_ROTINA,
       CT2_PROCES, CT2_HIST, CT2_MOEDLC,
       CT2_DATA, CT2_FILIAL, CT2_LOTE, CT2_SBLOTE, CT2_DOC
  FROM CT2010
 WHERE CT2_LOTE = '008840'
   AND CT2_DOC  = '000011'
   AND CT2_LINHA IN (75, 76, 403)
 ORDER BY CT2_LINHA, CT2_DC;
-- nome do csv sugerido: Q4_linhas_pendentes.csv


-- =====================================================================
-- Q5) (OPCIONAL, se 11a vier vazio) MOVIMENTOS 502/999 DE SET/2026
--     COM E SEM CENTRO DE CUSTO / D3_SEQCALC
--     Sem D3_SEQCALC a MATA331 nao contabiliza o movimento (fonte TDN).
-- =====================================================================
SELECT D3_TM,
       CASE WHEN ISNULL(LTRIM(RTRIM(D3_CC)), '') = '' THEN 'SEM CC' ELSE 'COM CC' END AS SITUACAO_CC,
       CASE WHEN ISNULL(LTRIM(RTRIM(D3_SEQCALC)), '') = '' THEN 'SEM SEQCALC' ELSE 'COM SEQCALC' END AS SITUACAO_SEQCALC,
       COUNT(*)                  AS QTDE,
       SUM(ISNULL(D3_CUSTO1, 0)) AS VALOR_CUSTO
  FROM SD3010
 WHERE D_E_L_E_T_ = ' '
   AND D3_FILIAL = '0102'
   AND D3_EMISSAO BETWEEN '20260901' AND '20260930'
   AND ISNULL(LTRIM(RTRIM(D3_ESTORNO)), '') <> 'S'
   AND D3_TM IN ('502', '999')
 GROUP BY D3_TM,
          CASE WHEN ISNULL(LTRIM(RTRIM(D3_CC)), '') = '' THEN 'SEM CC' ELSE 'COM CC' END,
          CASE WHEN ISNULL(LTRIM(RTRIM(D3_SEQCALC)), '') = '' THEN 'SEM SEQCALC' ELSE 'COM SEQCALC' END
 ORDER BY D3_TM, SITUACAO_CC;
-- nome do csv sugerido: Q5_sd3_502_999.csv
-- =====================================================================
