-- =====================================================================
-- 11) POSICAO DE SET/2026 NO CT2  (RAZAO CTBR400 x CTBA350)
--
--     SINTOMA (usuario, 21/10/2026):
--       - roda apenas MATA330 (custo medio) + Acompanha Custos
--       - CTBR400 (conta 11401200001) mostra SO AS ENTRADAS
--       - o REPROCESSAMENTO DE SALDOS / CTBA350 "nao processou nenhum item"
--       - mes passado (11/09/2026) o mesmo ritual funcionou:
--         448 lanc / R$ 54.285,05 efetivados (de 9 para 1)
--         [registrado em .opencode/memory.md:115-125]
--
--     PERGUNTAS QUE ESTE ARQUIVO RESPONDE:
--       11a) EXISTE tipo de saldo 9 em 09/2026?  (se nao existe, nao ha
--            o que efetivar -> CTBA350 processa 0 item por definicao)
--       11b) de qual ROTINA / ORIGEM / DATA / LP vieram os lancamentos
--       11c) a conta 11401200001 tem CREDITO (baixas) em set/2026?
--            em que tipo de saldo?
--       11d) as 3 linhas pendentes (075/076/403) - com rastreio completo
--       11e) diff de assinatura: mes que FUNCIONOU (08/2026) x mes que
--            FALHOU (09/2026)  [metodologia do caso de 11/09/2026]
--
--     SQL Server - APSDU - ASCII puro, sem WITH (NOLOCK).
--     Execute na ordem: 11a, 11c, 11e, 11d.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 11a) MAPA DO CT2 DE SET/2026 (filial 0102) POR TIPO DE SALDO
--      >>> DECISIVO: se aparecer SO CT2_TPSALD = 1, nao ha pre-lancamento
--      para efetivar e o CTBA350 processa 0 item por construcao.
--      Se aparecer 9 (e nao 1), o pre-lancamento existe e o problema e
--      de PARAMETRO/FILTRO do CTBA350 (periodo, filial, tipo de saldo,
--      "Efetivar Parcialmente").
-- ---------------------------------------------------------------------
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


-- ---------------------------------------------------------------------
-- 11b) MESMA COISA, MAS POR FILIAL E POR EMPRESA (o filtro do CTBR400
--      pode estar em outra filial) - soma por filial/tipo de saldo
-- ---------------------------------------------------------------------
SELECT CT2_FILIAL,
       CT2_TPSALD,
       COUNT(*)                  AS QTDE_LINHAS,
       SUM(ISNULL(CT2_VALOR, 0)) AS VALOR_TOTAL,
       MIN(CT2_DATA) AS DATA_INICIAL,
       MAX(CT2_DATA) AS DATA_FINAL
  FROM CT2010
 WHERE CT2_DATA BETWEEN '20260901' AND '20260930'
   AND (ISNULL(LTRIM(RTRIM(CT2_DEBITO)), '') <> ''
     OR ISNULL(LTRIM(RTRIM(CT2_CREDIT)), '') <> '')
 GROUP BY CT2_FILIAL, CT2_TPSALD
 ORDER BY CT2_FILIAL, CT2_TPSALD;


-- ---------------------------------------------------------------------
-- 11c) CONTA ALMOXARIFADO 11401200001 - DEBITO (entradas) x CREDITO
--      (baixas) POR MES E POR TIPO DE SALDO (202606 a 202609)
--      >>> Se set/2026 tiver credito no tipo 1, o Razao DEVERIA mostrar.
--      >>> Se o credito so existir no tipo 9, falta efetivar.
-- ---------------------------------------------------------------------
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


-- ---------------------------------------------------------------------
-- 11d) AS 3 LINHAS PENDENTES DO DOC 000011 (lote 008840, 30/09/2026)
--      com rastreio completo: rotina, origem, processo, inconsistencia,
--      tipo de saldo e LP que gravaram o lancamento.
-- ---------------------------------------------------------------------
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


-- ---------------------------------------------------------------------
-- 11e) DIFF DE ASSINATURA: MES QUE FUNCIONOU (08/2026) x MES QUE
--      FALHOU (09/2026) - mesma metodologia do caso de 11/09/2026
--      (onde o diff TPSALD 1 x 9 isolou a causa em 1 query).
-- ---------------------------------------------------------------------
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


-- ---------------------------------------------------------------------
-- 11f) DOCUMENTOS DE SET/2026 QUE CONTRIBUIRAM PARA A CONTA 11401200001
--      (lote, sub lote, doc, tipo de saldo, rotulo de origem)
--      Identifica qual documento holds as baixas e em que tipo de saldo.
-- ---------------------------------------------------------------------
SELECT CT2_DATA, CT2_LOTE, CT2_SBLOTE, CT2_DOC, CT2_TPSALD,
       CT2_ROTINA, CT2_ORIGEM, CT2_LP,
       COUNT(*)                  AS QTDE_LINHAS,
       SUM(ISNULL(CT2_VALOR, 0)) AS VALOR_TOTAL
  FROM CT2010
 WHERE CT2_FILIAL = '0102'
   AND CT2_DATA BETWEEN '20260901' AND '20260930'
   AND CT2_CREDIT = '11401200001'
 GROUP BY CT2_DATA, CT2_LOTE, CT2_SBLOTE, CT2_DOC, CT2_TPSALD,
          CT2_ROTINA, CT2_ORIGEM, CT2_LP
 ORDER BY CT2_DATA, CT2_DOC;


-- ---------------------------------------------------------------------
-- 11g) SD3 DE SET/2026 COM MOVIMENTO 502 OU 999 - MARCADO OU NAO
--      PELA MATA330 (D3_SEQCALC) E COM D3_DIACTB (diario contabilidade)
--      Sem D3_SEQCALC a MATA331 nao contabiliza (fonte TDN).
-- ---------------------------------------------------------------------
SELECT D3_TM,
       CASE WHEN ISNULL(LTRIM(RTRIM(D3_SEQCALC)), '') = '' THEN 'SEM SEQCALC' ELSE 'COM SEQCALC' END AS SITUACAO_SEQCALC,
       CASE WHEN ISNULL(LTRIM(RTRIM(D3_DIACTB)), '') = '' THEN 'SEM DIACTB' ELSE 'COM DIACTB' END AS SITUACAO_DIACTB,
       COUNT(*)                  AS QTDE,
       SUM(ISNULL(D3_CUSTO1, 0)) AS VALOR_CUSTO
  FROM SD3010
 WHERE D_E_L_E_T_ = ' '
   AND D3_FILIAL = '0102'
   AND D3_EMISSAO BETWEEN '20260901' AND '20260930'
   AND ISNULL(LTRIM(RTRIM(D3_ESTORNO)), '') <> 'S'
   AND D3_TM IN ('502', '999')
 GROUP BY D3_TM,
          CASE WHEN ISNULL(LTRIM(RTRIM(D3_SEQCALC)), '') = '' THEN 'SEM SEQCALC' ELSE 'COM SEQCALC' END,
          CASE WHEN ISNULL(LTRIM(RTRIM(D3_DIACTB)), '') = '' THEN 'SEM DIACTB' ELSE 'COM DIACTB' END
 ORDER BY D3_TM, SITUACAO_SEQCALC;


-- ---------------------------------------------------------------------
-- 11h) DIARIO / LOTE GERADOS PELA JORNADA EM SET/2026 (para comparar
--      com os docs de agosto que funcionaram)
--      11h1) CT5_DIACTB x doc/lote;  11h2) discover de CT1/CT5/CTK
--      (rotinas que gravam o "lote" 008840)
-- ---------------------------------------------------------------------
SELECT CT2_ORIGEM, CT2_ROTINA, CT2_PROCES, CT2_TPSALD,
       COUNT(*)                  AS QTDE,
       MIN(CT2_DATA) AS DATA_MIN,
       MAX(CT2_DATA) AS DATA_MAX,
       MIN(CT2_LOTE) AS LOTE_INICIAL
  FROM CT2010
 WHERE CT2_FILIAL = '0102'
   AND CT2_DATA BETWEEN '20260901' AND '20260930'
 GROUP BY CT2_ORIGEM, CT2_ROTINA, CT2_PROCES, CT2_TPSALD
 ORDER BY CT2_ORIGEM, CT2_ROTINA, CT2_TPSALD;
