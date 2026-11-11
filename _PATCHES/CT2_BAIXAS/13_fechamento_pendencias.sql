-- =====================================================================
-- 13) PENDENCIAS FINAIS - SET/2026 - DESTINO DO TM999 + ENTRADAS SEM VALOR
--
--     COMO EXECUTAR: mesmo fluxo do arquivo 12 (nome fisico, sem
--     WITH (NOLOCK), sem macros) no Analisador/SSMS/APSDU.
--
--     PENDENCIA 1 (Q21): o TM999 (3 movs, 162,15 em D3_CUSTO1) nao
--       aparece nem como credito (414 linhas = so TM502) nem como
--       debito (33 linhas = 100% NOSSA AQUISICAO). Esta query fecha
--       por totais: DC=1 deve fechar 41.681,30 e DC=3 deve fechar
--       35.046,21. Se fechar, o TM999 esta FORA da conta em setembro
--       (conta de diferenca de inventario / outro lancamento).
--       Conferencia cruzada: 209.832,08 (saldo anterior) + 41.681,30
--       - 35.046,21 = 216.467,17 (saldo final do CSV).
--
--     PENDENCIA 2 (Q22): a unica hipotese remanescena para
--       D3_CUSTO1 = 0 nos 25 itens e estado do item NA HORA da
--       gravacao da baixa (B2_VATU1/B2_CM1 zerado em setembro e
--       consertado no fechamento - sem historico de SB2 para
--       provar). O TESTE barato: existiu ENTRADA sem valor em
--       setembro para esses itens antes da baixa? Entrada com
--       D3_CUSTO1 = 0 zera a media e a saida seguinte sai a zero.
--       Exemplo conhecido no cliente: conversao caixas->unidades
--       (MC.1001.00044, outubro) - ver memoria.
--       Se Q22 vier com linhas = causa raiz provada; se vier vazio,
--       resta so reconstruir o estado do SB2 por movimento anterior.
--
-- =====================================================================

-- =====================================================================
-- Q21) TOTAIS DA CONTA 11401200001 EM SET/2026 POR LADO (DC)
-- =====================================================================
SELECT CT2_DC,
       COUNT(*)           AS QTDE_LINHAS,
       SUM(CT2_VALOR)     AS VALOR_TOTAL
  FROM CT2010
 WHERE CT2_FILIAL = '0102'
   AND D_E_L_E_T_ = ' '
   AND CT2_DATA BETWEEN '20260901' AND '20260930'
   AND (CT2_DEBITO = '11401200001' OR CT2_CREDIT = '11401200001')
 GROUP BY CT2_DC
 ORDER BY CT2_DC;

-- =====================================================================
-- Q21b) DETALHE POR HISTORICO (para localizar se TM999 aparece em
--       algum DC com historico de ajuste/inventario)
-- =====================================================================
SELECT CT2_DC,
       LEFT(CT2_HIST, 40)  AS HISTORICO,
       COUNT(*)            AS QTDE_LINHAS,
       SUM(CT2_VALOR)      AS VALOR_TOTAL
  FROM CT2010
 WHERE CT2_FILIAL = '0102'
   AND D_E_L_E_T_ = ' '
   AND CT2_DATA BETWEEN '20260901' AND '20260930'
   AND (CT2_DEBITO = '11401200001' OR CT2_CREDIT = '11401200001')
 GROUP BY CT2_DC, LEFT(CT2_HIST, 40)
 ORDER BY CT2_DC, VALOR_TOTAL DESC;

-- =====================================================================
-- Q22) ENTRADAS SEM VALOR EM SET/2026 PARA OS ITENS DOS 25 SEM RAZAO
--     (teste da hipotese de media zerada antes da baixa)
--
--     TM de entrada: 100 (entrada compra/devolucao), 101/102,
--     999 (ajuste/inventario) - trago tudo e filtra por D3_CUSTO1 = 0.
--     Criterio: D3_QUANT > 0 (entrada) e D3_CUSTO1 = 0 em setembro.
-- =====================================================================
SELECT SD3010.D3_COD,
       SD3010.D3_EMISSAO,
       SD3010.D3_TM,
       SD3010.D3_CF,
       SD3010.D3_DOC,
       SD3010.D3_QUANT,
       SD3010.D3_CUSTO1
  FROM SD3010
 WHERE D3_FILIAL = '0102'
   AND D_E_L_E_T_ = ' '
   AND D3_EMISSAO BETWEEN '20260901' AND '20260930'
   AND D3_LOCAL = '02'
   AND D3_QUANT > 0
   AND D3_CUSTO1 = 0
   AND D3_COD IN (
       'MC.1003.00015','MC.1001.00022','MC.1001.00069','MC.1001.00044',
       'MC.0301.00467','MC.0301.00468','MC.0301.00469','MC.0809.00172',
       'MC.0202.00049','MC.0806.00010','MC.0801.00008',
       -- completar com os demais codigos da aba "Baixas sem Razao"
       -- da planilha Analise_Fechamento_Estoque_Setembro_2026.xlsx
       'MC.1003.00055','MC.0109.00697','MC.0403.00349'
   )
 ORDER BY SD3010.D3_EMISSAO, SD3010.D3_COD;

-- =====================================================================
-- Q22b) MESMO TESTE, TODAS AS ENTRADAS (com e sem valor) DOS ITENS
--       PARA VER A ORDEM entrada x baixa
-- =====================================================================
SELECT SD3010.D3_COD,
       SD3010.D3_EMISSAO,
       SD3010.D3_TM,
       SD3010.D3_DOC,
       SD3010.D3_QUANT,
       SD3010.D3_CUSTO1,
       CASE WHEN SD3010.D3_CUSTO1 = 0 THEN 'SEM VALOR' ELSE 'COM VALOR' END AS SITUACAO
  FROM SD3010
 WHERE D3_FILIAL = '0102'
   AND D_E_L_E_T_ = ' '
   AND D3_EMISSAO BETWEEN '20260801' AND '20260930'
   AND D3_LOCAL = '02'
   AND D3_QUANT > 0
   AND D3_COD IN (
       'MC.1003.00015','MC.1001.00022','MC.1001.00069','MC.1001.00044',
       'MC.0301.00467','MC.0301.00468','MC.0301.00469','MC.0809.00172',
       'MC.0202.00049','MC.0806.00010','MC.0801.00008',
       'MC.1003.00055','MC.0109.00697','MC.0403.00349'
   )
 ORDER BY SD3010.D3_COD, SD3010.D3_EMISSAO;

-- =====================================================================
-- Q23) SOMATORIO FISICO x VALOR - SANIDADE (bate com a planilha?)
--     PELA_MEDIA deve fechar 214.272,91 (coluna "custo medio ( total )")
--     VATU1 mostra se o campo de valor do SB2 hoje esta coerente.
-- =====================================================================
SELECT COUNT(*)                       AS ITENS,
       SUM(B2_QATU * B2_CM1)          AS PELA_MEDIA,
       SUM(ISNULL(B2_VATU1, 0))       AS VATU1
  FROM SB2010
 WHERE B2_FILIAL = '0102'
   AND D_E_L_E_T_ = ' '
   AND B2_LOCAL = '02';
