#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TopConn.ch"

/*/{Protheus.doc} ZMMA02
Controle de Compras Diretas que Passam pelo Almoxarifado
Identifica recorrencia, tempo de permanencia e taxa de baixa de materiais
comprados que atualizam estoque mas nao sao para o CC 5010206
@type     function
@author   Juan Almeida
@since    2026.02.02
@version  4.0 - Versao simplificada focada em compras diretas
/*/

User Function ZMMA02()
    Local aArea := GetArea() as array
    Local oDlg as object
    Local oPanel1 as object
    Local oPanel2 as object
    Local oSay1, oSay2, oSay3, oSay4, oSay5 as object
    Local oGet1, oGet2, oGet3, oGet4 as object
    Local oCmbSit as object
    Local oBtn1, oBtn3, oBtn4 as object

    // Variaveis compartilhadas entre funcoes
    Private dDataDe := CtoD("") as date          // Data inicial do periodo
    Private dDataAte := Date() as date          // Data final do periodo (padrao hoje)
    Private cLocal := Space(2) as character      // Armazem (opcional)
    Private cFiltroProd := Space(20) as character // Filtro por codigo do produto
    Private cFiltroSit := "TODOS" as character   // Filtro por situacao
    Private aItens := {} as array                // Array filtrado exibido no browse
    Private aItensFull := {} as array            // Array completo antes dos filtros
    Private aColunas := {} as array              // Definicao das colunas do browse
    Private oBrowse as object                    // Objeto browse

    // Define tela principal
    DEFINE MSDIALOG oDlg TITLE "Analise de Compras Diretas - Permanencia no Almoxarifado" FROM 000,000 TO 750,1800 PIXEL

    // Painel superior - Parametros e filtros
    oPanel1 := TPanel():New(000, 000, "", oDlg, , , , , , 700, 055, .T., .T.)
    oPanel1:Align := CONTROL_ALIGN_TOP

    // Linha 1 - Parametros principais
    @ 008, 010 SAY oSay1 PROMPT "Data De:" SIZE 040, 007 OF oPanel1 PIXEL
    @ 006, 050 MSGET oGet1 VAR dDataDe SIZE 050, 010 OF oPanel1 PIXEL

    @ 008, 110 SAY oSay2 PROMPT "Data Ate:" SIZE 040, 007 OF oPanel1 PIXEL
    @ 006, 150 MSGET oGet2 VAR dDataAte SIZE 050, 010 OF oPanel1 PIXEL

    @ 008, 210 SAY oSay3 PROMPT "Local:" SIZE 040, 007 OF oPanel1 PIXEL
    @ 006, 240 MSGET oGet3 VAR cLocal SIZE 030, 010 OF oPanel1 PIXEL

    // Botoes de acao - AJUSTADO O ESPACAMENTO
    @ 006, 280 BUTTON oBtn1 PROMPT "Processar" SIZE 050, 012 OF oPanel1 PIXEL ACTION Processa({|| ProcessaAnalise()}, "Processando...")
    @ 006, 332 BUTTON oBtn3 PROMPT "Legenda" SIZE 050, 012 OF oPanel1 PIXEL ACTION MostraLegenda()
    @ 006, 384 BUTTON oBtn4 PROMPT "Sair" SIZE 050, 012 OF oPanel1 PIXEL ACTION oDlg:End()

    // Linha 2 - Filtros
    @ 023, 010 SAY oSay4 PROMPT "Filtro Produto:" SIZE 050, 007 OF oPanel1 PIXEL
    @ 021, 065 MSGET oGet4 VAR cFiltroProd SIZE 080, 010 OF oPanel1 PIXEL
    @ 021, 150 BUTTON "Filtrar" SIZE 040, 012 OF oPanel1 PIXEL ACTION AplicaFiltros()

    @ 023, 200 SAY oSay5 PROMPT "Situacao:" SIZE 040, 007 OF oPanel1 PIXEL
    @ 021, 240 COMBOBOX oCmbSit VAR cFiltroSit ITEMS {"TODOS","AGUARDANDO ENTRADA NF","PARADO","BAIXA PARCIAL","OK"} SIZE 100, 012 OF oPanel1 PIXEL ON CHANGE AplicaFiltros()

    // Texto explicativo
    @ 038, 010 SAY "Compras Diretas (Fora CC 5010206) | Objetivo: Identificar recorrencia e tempo de permanencia" SIZE 680, 007 OF oPanel1 PIXEL FONT TFont():New(, , 10, .T.) COLOR CLR_BLUE

    // Painel inferior - Browse de dados
    oPanel2 := TPanel():New(000, 000, "", oDlg, , , , , , 700, 260, .T., .T.)
    oPanel2:Align := CONTROL_ALIGN_ALLCLIENT

    // Monta estrutura de colunas
    MontaColunas()

    // Cria e configura o browse
    oBrowse := FWBrowse():New()
    oBrowse:SetOwner(oPanel2)
    oBrowse:SetDataArray()
    oBrowse:SetArray(aItens)
    oBrowse:SetColumns(aColunas)
    oBrowse:DisableConfig()
    oBrowse:SetDoubleClick({|| DetalheItem()})
    oBrowse:Activate()

    ACTIVATE MSDIALOG oDlg CENTERED

    RestArea(aArea)

Return

/*/{Protheus.doc} MontaColunas
Monta a estrutura de colunas do browse
Define formato, tamanho, alinhamento e dados de cada coluna
@type     function
@author   Juan Almeida
@since    2026.02.02
/*/
Static Function MontaColunas()
    Local oColumn as object

    aColunas := {}

    // Coluna 1: Icone de status (vermelho/amarelo/verde)
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| ""})
    oColumn:SetTitle("!")
    oColumn:SetSize(2)
    oColumn:SetAlign(CONTROL_ALIGN_CENTER)
    oColumn:SetImage(.T., {|| aItens[oBrowse:nAt][15]})
    aAdd(aColunas, oColumn)

    // Coluna 2: Codigo do produto
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][1]})
    oColumn:SetTitle("Produto")
    oColumn:SetSize(15)
    oColumn:SetAlign(CONTROL_ALIGN_LEFT)
    aAdd(aColunas, oColumn)

    // Coluna 3: Descricao do produto
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][2]})
    oColumn:SetTitle("Descricao")
    oColumn:SetSize(30)
    oColumn:SetAlign(CONTROL_ALIGN_LEFT)
    aAdd(aColunas, oColumn)

    // Coluna 4: Numero de compras (recorrencia)
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aItens[oBrowse:nAt][3], "@E 999")})
    oColumn:SetTitle("N Compras")
    oColumn:SetSize(10)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    // Coluna 5: Quantidade comprada no periodo
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aItens[oBrowse:nAt][4], "@E 999,999.99")})
    oColumn:SetTitle("Qtd Comprada")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    // Coluna 6: Quantidade baixada (consumida)
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aItens[oBrowse:nAt][5], "@E 999,999.99")})
    oColumn:SetTitle("Qtd Baixada")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    // Coluna 7: Percentual baixado
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aItens[oBrowse:nAt][6], "@E 999.99") + "%"})
    oColumn:SetTitle("% Baixado")
    oColumn:SetSize(10)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    // Coluna 8: Saldo atual no estoque
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aItens[oBrowse:nAt][7], "@E 999,999.99")})
    oColumn:SetTitle("Saldo Atual")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    // Coluna 9: Data de entrada da NF
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| DtoC(aItens[oBrowse:nAt][8])})
    oColumn:SetTitle("Dt Entrada NF")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_CENTER)
    aAdd(aColunas, oColumn)

    // Coluna 10: Numero do pedido de compra
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][9]})
    oColumn:SetTitle("Pedido")
    oColumn:SetSize(10)
    oColumn:SetAlign(CONTROL_ALIGN_CENTER)
    aAdd(aColunas, oColumn)

    // Coluna 11: Data da ultima baixa
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| DtoC(aItens[oBrowse:nAt][10])})
    oColumn:SetTitle("Ultima Baixa")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_CENTER)
    aAdd(aColunas, oColumn)

    // Coluna 12: Dias no almoxarifado (permanencia)
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aItens[oBrowse:nAt][11], "@E 9,999")})
    oColumn:SetTitle("Dias Almox")
    oColumn:SetSize(10)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    // Coluna 13: Situacao (PARADO/BAIXA PARCIAL/OK)
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][14]})
    oColumn:SetTitle("Situacao")
    oColumn:SetSize(15)
    oColumn:SetAlign(CONTROL_ALIGN_LEFT)
    aAdd(aColunas, oColumn)

Return

/*/{Protheus.doc} ProcessaAnalise
Funcao principal de processamento
Busca compras diretas (C7_XESTOQ1='S' e fora CC 5010206)
Calcula tempo de permanencia e percentual de baixa
@type     function
@author   Juan Almeida
@since    2026.02.02
/*/
Static Function ProcessaAnalise()
    Local aAreaProc := GetArea() as array
    Local cQuery := "" as character
    Local cAlias := GetNextAlias() as character
    Local cAliasBx := "" as character
    Local cAliasNF := "" as character
    Local cProduto as character
    Local nQtdComprada as numeric
    Local nOcorCompras as numeric
    Local dDataEntrada as date
    Local cPedido as character
    Local nQtdBaixada as numeric
    Local nQtdMovTot as numeric
    Local dUltimaBaixa as date
    Local nSaldoAtual as numeric
    Local nPercBaixado as numeric
    Local nDiasAlmox as numeric
    Local cSituacao as character
    Local cIcone as character
    Local nPrioridade as numeric
    Local cNotaFisc as character

    // VALIDACAO DAS DATAS
    If Empty(dDataDe)
        MsgStop("Informe a Data De!", "Atencao")
        Return
    EndIf

    If Empty(dDataAte)
        MsgStop("Informe a Data Ate!", "Atencao")
        Return
    EndIf

    If dDataAte < dDataDe
        MsgStop("Data Ate deve ser maior ou igual a Data De!", "Atencao")
        Return
    EndIf

    // Limpa arrays
    aItens := {}
    aItensFull := {}

    // ==========================================
    // QUERY 1: BUSCA COMPRAS DIRETAS (SC7)
    // ==========================================
    // Criterios:
    // - C7_XESTOQ1 = 'S' (atualiza estoque)
    // - C7_CC diferente de 5010206 (ou vazio)
    // - No periodo informado
    // ==========================================
cQuery := " SELECT "
cQuery += "   C7_PRODUTO, "
cQuery += "   SUM(C7_QUANT) AS QTD_COMPRADA, "
cQuery += "   COUNT(DISTINCT C7_NUM) AS NUM_COMPRAS "
cQuery += " FROM " + RetSqlName("SC7") + " SC7 "
cQuery += " WHERE SC7.D_E_L_E_T_ = '' "
cQuery += "   AND C7_FILIAL = '" + xFilial("SC7") + "' "
cQuery += "   AND C7_PRODUTO NOT LIKE 'SV%' "  // Exclui servicos
cQuery += "   AND C7_XESTOQ1 = 'S' "  // Apenas itens que atualizam estoque
cQuery += "   AND C7_RESIDUO = ' ' "
cQuery += "   AND (C7_CC <> '5010206' OR C7_CC IS NULL OR C7_CC = '') "  // Fora CC 5010206
cQuery += "   AND C7_CONAPRO <> 'B' "  // EXCLUI APENAS PEDIDOS EM APROVACAO
cQuery += "   AND C7_EMISSAO BETWEEN '" + DtoS(dDataDe) + "' AND '" + DtoS(dDataAte) + "' "
If !Empty(cLocal)
    cQuery += "   AND C7_LOCAL = '" + AllTrim(cLocal) + "' "  // Filtro por armazem (opcional)
EndIf
cQuery += " GROUP BY C7_PRODUTO "
cQuery += " ORDER BY COUNT(DISTINCT C7_NUM) DESC, C7_PRODUTO "  // Ordena por recorrencia

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    // Define tipos dos campos
    TCSetField(cAlias, "QTD_COMPRADA", "N", 12, 2)
    TCSetField(cAlias, "NUM_COMPRAS", "N", 6, 0)

    // Processa cada produto encontrado
    (cAlias)->(DbGoTop())
    While (cAlias)->(!Eof())

        cProduto := (cAlias)->C7_PRODUTO
        nQtdComprada := (cAlias)->QTD_COMPRADA
        nOcorCompras := (cAlias)->NUM_COMPRAS

        // Busca dados cadastrais do produto
        DbSelectArea("SB1")
        SB1->(DbSetOrder(1))  // B1_FILIAL + B1_COD

        If SB1->(DbSeek(xFilial("SB1") + cProduto))

            // Exclui produtos com conta contabil 11401200001
            If AllTrim(SB1->B1_XCTAEST) == "11401200001"
                (cAlias)->(DbSkip())
                Loop
            EndIf

           // ==========================================
// QUERY 2: BUSCA DATA ENTRADA NF E PEDIDO (SD1)
// CORRIGIDO: Busca apenas pedidos com C7_XESTOQ1='S'
// ==========================================
dDataEntrada := CtoD("")
cPedido := ""
cNotaFisc := ""

// ==========================================
// QUERY 2: BUSCA ENTRADA FINAL DE NF (SD1)
// Pre-nota NAO conta como entrada final
// D1_TES preenchido = NF classificada (entrada final)
// ==========================================
cQuery := " SELECT TOP 1 "
cQuery += "   COALESCE(SD1.D1_DTDIGIT, SD1.D1_EMISSAO) AS DATA_ENTRADA, "
cQuery += "   SD1.D1_PEDIDO AS PEDIDO, "
cQuery += "   RTRIM(SD1.D1_DOC) + '-' + RTRIM(SD1.D1_SERIE) AS NOTA_FISCAL "
cQuery += " FROM " + RetSqlName("SD1") + " SD1 "
cQuery += " INNER JOIN " + RetSqlName("SC7") + " SC7 "
cQuery += "   ON SC7.C7_FILIAL = SD1.D1_FILIAL "
cQuery += "   AND SC7.C7_NUM = SD1.D1_PEDIDO "
cQuery += "   AND SC7.C7_ITEM = SD1.D1_ITEMPC "
cQuery += "   AND SC7.C7_PRODUTO = SD1.D1_COD "
cQuery += "   AND SC7.C7_XESTOQ1 = 'S' "  // GARANTE QUE O PEDIDO TENHA ATUALIZACAO DE ESTOQUE
cQuery += "   AND SC7.D_E_L_E_T_ = '' "
cQuery += " WHERE SD1.D_E_L_E_T_ = '' "
cQuery += "   AND SD1.D1_FILIAL = '" + xFilial("SD1") + "' "
cQuery += "   AND SD1.D1_COD = '" + cProduto + "' "
cQuery += "   AND SD1.D1_DTDIGIT <= '" + DtoS(dDataAte) + "' "  // Sem data minima - busca historico completo
cQuery += "   AND SD1.D1_TES <> '' "  // SOMENTE NF CLASSIFICADA (entrada final, exclui pre-nota)
If !Empty(cLocal)
    cQuery += "   AND SD1.D1_LOCAL = '" + AllTrim(cLocal) + "' "
EndIf
cQuery += " ORDER BY COALESCE(SD1.D1_DTDIGIT, SD1.D1_EMISSAO) DESC "

            cQuery := ChangeQuery(cQuery)
            cAliasNF := GetNextAlias()
            DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasNF, .F., .T.)

            If (cAliasNF)->(!Eof())
                If !Empty((cAliasNF)->DATA_ENTRADA)
                    dDataEntrada := StoD(StrTran((cAliasNF)->DATA_ENTRADA, "-", ""))
                EndIf
                cPedido := AllTrim((cAliasNF)->PEDIDO)
                cNotaFisc := AllTrim((cAliasNF)->NOTA_FISCAL)
            EndIf

            (cAliasNF)->(DbCloseArea())

            // Fallback: se nao tem NF (AGUARDANDO), busca pedido direto do SC7
            If Empty(dDataEntrada) .Or. Empty(cPedido)
                cQuery := " SELECT TOP 1 SC7.C7_NUM AS PEDIDO "
                cQuery += " FROM " + RetSqlName("SC7") + " SC7 "
                cQuery += " WHERE SC7.D_E_L_E_T_ = '' "
                cQuery += "   AND SC7.C7_FILIAL = '" + xFilial("SC7") + "' "
                cQuery += "   AND SC7.C7_PRODUTO = '" + cProduto + "' "
                cQuery += "   AND SC7.C7_XESTOQ1 = 'S' "
                cQuery += "   AND SC7.C7_EMISSAO BETWEEN '" + DtoS(dDataDe) + "' AND '" + DtoS(dDataAte) + "' "
                If !Empty(cLocal)
                    cQuery += "   AND SC7.C7_LOCAL = '" + AllTrim(cLocal) + "' "
                EndIf
                cQuery += " ORDER BY SC7.C7_EMISSAO DESC, SC7.C7_NUM DESC "
                cQuery := ChangeQuery(cQuery)
                cAliasNF := GetNextAlias()
                DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasNF, .F., .T.)
                If (cAliasNF)->(!Eof())
                    cPedido := AllTrim((cAliasNF)->PEDIDO)
                EndIf
                (cAliasNF)->(DbCloseArea())
            EndIf

            // Ajuste N Compras: conta entradas de NF (SD1) no periodo
            // Pedido 006167 (27/11/2023) fora da janela nao entra em SC7, mas
            // se tiver duas NFs de 011880 (29/05 e 17/06) N=2. Regra do user:
            // cada entrada final (D1_TES<>'') conta como uma compra no display
            cQuery := " SELECT COUNT(*) AS NUM_NFS "
            cQuery += " FROM " + RetSqlName("SD1") + " SD1 "
            cQuery += " WHERE SD1.D_E_L_E_T_ = '' "
            cQuery += "   AND SD1.D1_FILIAL = '" + xFilial("SD1") + "' "
            cQuery += "   AND SD1.D1_COD = '" + cProduto + "' "
            cQuery += "   AND SD1.D1_TES <> '' "
            cQuery += "   AND COALESCE(SD1.D1_DTDIGIT, SD1.D1_EMISSAO) BETWEEN '" + DtoS(dDataDe) + "' AND '" + DtoS(dDataAte) + "' "
            If !Empty(cLocal)
                cQuery += "   AND SD1.D1_LOCAL = '" + AllTrim(cLocal) + "' "
            EndIf
            cQuery := ChangeQuery(cQuery)
            cAliasNF := GetNextAlias()
            DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasNF, .F., .T.)
            TCSetField(cAliasNF, "NUM_NFS", "N", 6, 0)
            If (cAliasNF)->(!Eof()) .And. (cAliasNF)->NUM_NFS > nOcorCompras
                nOcorCompras := (cAliasNF)->NUM_NFS
            EndIf
            (cAliasNF)->(DbCloseArea())

            // ==========================================
            // QUERY 3: BUSCA BAIXAS SD3
            // ==========================================
            // QTD_BAIXADA = so TM 502 (para BAIXA PARCIAL)
            // QTD_MOVTOT = TM 502+499+999 (para PARADO)
            // Itens zerados por inventario caem em OK via nSaldoAtual==0
            // ==========================================
            nQtdBaixada := 0
            nQtdMovTot := 0
            dUltimaBaixa := CtoD("")

cQuery := " SELECT "
cQuery += "   SUM(CASE WHEN D3_TM='502' THEN D3_QUANT ELSE 0 END) AS QTD_BAIXADA, "
cQuery += "   SUM(CASE WHEN D3_TM IN ('502','499','999') THEN D3_QUANT ELSE 0 END) AS QTD_MOVTOT, "
cQuery += "   MAX(CASE WHEN D3_TM='502' THEN D3_EMISSAO ELSE '' END) AS ULT_BAIXA "
cQuery += " FROM " + RetSqlName("SD3") + " SD3 "
cQuery += " WHERE SD3.D_E_L_E_T_ = '' "
cQuery += "   AND D3_FILIAL = '" + xFilial("SD3") + "' "
cQuery += "   AND D3_COD = '" + cProduto + "' "
If !Empty(dDataEntrada)
    cQuery += "   AND D3_EMISSAO BETWEEN '" + DtoS(dDataEntrada) + "' AND '" + DtoS(dDataAte) + "' "
Else
    cQuery += "   AND D3_EMISSAO <= '" + DtoS(dDataAte) + "' "
EndIf
cQuery += "   AND D3_TM IN ('502','499','999') "

// Exclui movimentos estornados
cQuery += "   AND (D3_ESTORNO = '' OR D3_ESTORNO IS NULL) "

If !Empty(cLocal)
    cQuery += "   AND D3_LOCAL = '" + AllTrim(cLocal) + "' "
EndIf

cQuery := ChangeQuery(cQuery)
cAliasBx := GetNextAlias()
DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasBx, .F., .T.)

TCSetField(cAliasBx, "ULT_BAIXA", "D")
TCSetField(cAliasBx, "QTD_BAIXADA", "N", 12, 2)
TCSetField(cAliasBx, "QTD_MOVTOT", "N", 12, 2)

If (cAliasBx)->(!Eof())
    If (cAliasBx)->QTD_BAIXADA > 0
        nQtdBaixada := (cAliasBx)->QTD_BAIXADA
    EndIf
    If (cAliasBx)->QTD_MOVTOT > 0
        nQtdMovTot := (cAliasBx)->QTD_MOVTOT
    EndIf
    If !Empty((cAliasBx)->ULT_BAIXA)
        dUltimaBaixa := (cAliasBx)->ULT_BAIXA
    EndIf
EndIf

(cAliasBx)->(DbCloseArea())

// AGUARDANDO ENTRADA NF: nao faz sentido ter baixa/% - zera
// Ex: MC.0113.00108 mostrava 3,00/75% com DtEntr //  e baixa 24/09/2024 de estoque antigo
If Empty(dDataEntrada)
    nQtdBaixada := 0
    nQtdMovTot := 0
    dUltimaBaixa := CtoD("")
EndIf

            // ==========================================
            // BUSCA SALDO ATUAL (SB2)
            // ==========================================
            nSaldoAtual := 0

            DbSelectArea("SB2")
            SB2->(DbSetOrder(1))  // B2_FILIAL + B2_COD + B2_LOCAL

            If Empty(cLocal)
                // Sem filtro de local: soma todos os armazens
                If SB2->(DbSeek(xFilial("SB2") + cProduto))
                    While SB2->(!Eof()) .And. SB2->B2_FILIAL == xFilial("SB2") .And. SB2->B2_COD == cProduto
                        nSaldoAtual += SB2->B2_QATU
                        SB2->(DbSkip())
                    EndDo
                EndIf
            Else
                // Com filtro de local: busca armazem especifico
                If SB2->(DbSeek(xFilial("SB2") + cProduto + cLocal))
                    nSaldoAtual := SB2->B2_QATU
                EndIf
            EndIf

            // ==========================================
            // CALCULOS
            // ==========================================

            // Calcula percentual de baixa
            nPercBaixado := 0
            If nQtdComprada > 0
                nPercBaixado := Round((nQtdBaixada / nQtdComprada) * 100, 2)
            EndIf

            // Calcula dias no almoxarifado
            // So conta dias DEPOIS que a entrada final foi realizada e gerou saldo
            // Condicao: NF digitada E (tem saldo atual OU teve baixa = saldo existiu)
            nDiasAlmox := 0
            If !Empty(dDataEntrada) .And. (nSaldoAtual > 0 .Or. nQtdBaixada > 0)
                If !Empty(dUltimaBaixa) .And. nPercBaixado >= 100
                    // Baixou 100%: conta ate ultima baixa
                    nDiasAlmox := dUltimaBaixa - dDataEntrada
                Else
                    // Nao baixou tudo: conta ate hoje
                    nDiasAlmox := Date() - dDataEntrada
                EndIf

                // Protecao contra datas inconsistentes
                If nDiasAlmox < 0
                    nDiasAlmox := 0
                EndIf
            EndIf

            // ==========================================
            // DEFINE SITUACAO (4 STATUS)
            // ==========================================
            cSituacao := ""
cIcone := ""
nPrioridade := 0

// Verifica se nao tem entrada final de NF (pre-nota nao conta)
If Empty(dDataEntrada)
    cSituacao := "AGUARDANDO ENTRADA NF"
    cIcone := "BR_PRETO"
    nPrioridade := 1
ElseIf nSaldoAtual == 0
    // Saldo zerado: baixou 100%, consumido por inventario ou outros meios = OK
    cSituacao := "OK"
    cIcone := "BR_VERDE"
    nPrioridade := 4
ElseIf nQtdMovTot == 0 .And. nSaldoAtual > 0
    // Tem saldo mas nenhuma movimentacao 502/499/999 - material parado
    cSituacao := "PARADO"
    cIcone := "BR_LARANJA"
    nPrioridade := 2
ElseIf nQtdBaixada > 0 .And. nPercBaixado < 100 .And. nSaldoAtual > 0
    // Baixou parcial via 502 e AINDA TEM saldo
    cSituacao := "BAIXA PARCIAL"
    cIcone := "BR_AMARELO"
    nPrioridade := 3
Else
    cSituacao := "OK"
    cIcone := "BR_VERDE"
    nPrioridade := 4
EndIf

            // Adiciona no array completo
    aAdd(aItensFull, {;
    cProduto,;           // 1  - Codigo do produto
    SB1->B1_DESC,;       // 2  - Descricao
    nOcorCompras,;       // 3  - Numero de compras
    nQtdComprada,;       // 4  - Quantidade comprada
    nQtdBaixada,;        // 5  - Quantidade baixada
    nPercBaixado,;       // 6  - Percentual baixado
    nSaldoAtual,;        // 7  - Saldo atual
    dDataEntrada,;       // 8  - Data entrada NF
    cPedido,;            // 9  - Numero do pedido
    dUltimaBaixa,;       // 10 - Data ultima baixa
    nDiasAlmox,;         // 11 - Dias no almoxarifado
    SB1->B1_UM,;         // 12 - Unidade de medida
    SB1->B1_TIPO,;       // 13 - Tipo do produto
    cSituacao,;          // 14 - Situacao
    cIcone,;             // 15 - Icone
    nPrioridade,;        // 16 - Prioridade
    cNotaFisc;           // 17 - Numero da NF
    })
        EndIf

        (cAlias)->(DbSkip())
    EndDo

    (cAlias)->(DbCloseArea())

    // Ordena por prioridade (PARADO > BAIXA PARCIAL > OK)
    aSort(aItensFull, , , {|x, y| x[16] < y[16]})

    // Copia array completo para array de exibicao
    aItens := aClone(aItensFull)

    // Mensagem final
    If Len(aItens) == 0
        MsgInfo("Nenhum produto encontrado.", "Aviso")
    Else
        MsgInfo("Encontrados " + cValToChar(Len(aItens)) + " produto(s).", "Sucesso")
    EndIf

    // Atualiza browse
    oBrowse:SetArray(aItens)
    oBrowse:Refresh()

    RestArea(aAreaProc)

Return

/*/{Protheus.doc} AplicaFiltros
Aplica filtros de situacao e produto sobre o array completo
Permite visualizar apenas registros especificos
@type     function
@author   Juan Almeida
@since    2026.02.02
/*/
Static Function AplicaFiltros()
    Local nX as numeric
    Local lIncluir as logical

    // Limpa array de exibicao
    aItens := {}

    // Percorre array completo aplicando filtros
    For nX := 1 To Len(aItensFull)
        lIncluir := .T.

        // Filtro por situacao (TODOS/PARADO/BAIXA PARCIAL/OK)
        If cFiltroSit != "TODOS"
            If aItensFull[nX][14] != cFiltroSit
                lIncluir := .F.
            EndIf
        EndIf

        // Filtro por codigo do produto (busca parcial)
        If lIncluir .And. !Empty(AllTrim(cFiltroProd))
            If !(AllTrim(cFiltroProd) $ aItensFull[nX][1])  // Posicao 1 = Codigo produto
                lIncluir := .F.
            EndIf
        EndIf

        // Se passou pelos filtros, adiciona no array de exibicao
        If lIncluir
            aAdd(aItens, aClone(aItensFull[nX]))
        EndIf
    Next nX

    // Mensagem de resultado
    If Len(aItens) == 0
        MsgInfo("Nenhum registro encontrado com os filtros aplicados.", "Aviso")
    Else
        MsgInfo("Filtro aplicado: " + cValToChar(Len(aItens)) + " registro(s).", "Sucesso")
    EndIf

    // Atualiza browse
    oBrowse:SetArray(aItens)
    oBrowse:GoTop()
    oBrowse:Refresh()

Return

/*/{Protheus.doc} MostraLegenda
Exibe legenda explicativa dos status e icones
@type     function
@author   Juan Almeida
@since    2026.02.02
/*/
Static Function MostraLegenda()
    Local aLegenda := {} as array

    // Monta array de legenda
    aAdd(aLegenda, {"BR_LARANJA", "PARADO - Nenhuma baixa (0%)"})
    aAdd(aLegenda, {"BR_LARANJA", "  Material nao foi consumido"})
    aAdd(aLegenda, {"", ""})
    aAdd(aLegenda, {"BR_AMARELO", "BAIXA PARCIAL - Baixou entre 1% e 99%"})
    aAdd(aLegenda, {"BR_AMARELO", "  Material parcialmente consumido"})
    aAdd(aLegenda, {"", ""})
    aAdd(aLegenda, {"BR_VERDE", "OK - Saldo zerado"})
    aAdd(aLegenda, {"BR_VERDE", "  Totalmente consumido (baixa ou inventario)"})
    aAdd(aLegenda, {"", ""})
    aAdd(aLegenda, {"", "Objetivo:"})
    aAdd(aLegenda, {"", "  Monitorar tempo de permanencia"})
    aAdd(aLegenda, {"", "  Identificar material parado"})

    // Exibe janela de legenda
    BrwLegenda("Status de Consumo", "Legenda", aLegenda)

Return

/*/{Protheus.doc} DetalheItem
Exibe detalhes completos do item selecionado no browse
Acionado por duplo clique
@type     function
@author   Juan Almeida
@since    2026.02.02
/*/
Static Function DetalheItem()
    Local nLinha as numeric
    Local cMsg as character

    // Verifica se tem dados
    If Len(aItens) == 0
        Return
    EndIf

    nLinha := oBrowse:nAt
    cMsg := ""

    // Monta mensagem formatada com detalhes
    cMsg += "-------------------------------------------------" + CRLF
    cMsg += "     ANALISE DE COMPRA DIRETA                   " + CRLF
    cMsg += "-------------------------------------------------" + CRLF + CRLF

    cMsg += "Produto.........: " + aItens[nLinha][1] + CRLF
    cMsg += "Descricao.......: " + aItens[nLinha][2] + CRLF
    cMsg += "Pedido..........: " + aItens[nLinha][9] + CRLF
    cMsg += CRLF

    cMsg += "-------------------------------------------------" + CRLF
    cMsg += "  MOVIMENTACAO                                   " + CRLF
    cMsg += "-------------------------------------------------" + CRLF
    cMsg += "Qtd Comprada....: " + Transform(aItens[nLinha][4],"@E 999,999.99") + " " + aItens[nLinha][12] + CRLF
    cMsg += "Qtd Baixada.....: " + Transform(aItens[nLinha][5],"@E 999,999.99") + " " + aItens[nLinha][12] + CRLF
    cMsg += "Saldo Atual.....: " + Transform(aItens[nLinha][7],"@E 999,999.99") + " " + aItens[nLinha][12] + CRLF
    cMsg += "% Baixado.......: " + Transform(aItens[nLinha][6],"@E 999.99") + "%" + CRLF + CRLF

    cMsg += "-------------------------------------------------" + CRLF
    cMsg += "  PERMANENCIA NO ALMOXARIFADO                    " + CRLF
    cMsg += "-------------------------------------------------" + CRLF
    cMsg += "Nota Fiscal.....: " + aItens[nLinha][17] + CRLF
    cMsg += "Dt Entrada NF...: " + DtoC(aItens[nLinha][8]) + CRLF
    cMsg += "Ultima Baixa....: " + DtoC(aItens[nLinha][10]) + CRLF
    cMsg += "Dias no Almox...: " + cValToChar(aItens[nLinha][11]) + " dia(s)" + CRLF + CRLF

    cMsg += "-------------------------------------------------" + CRLF
    cMsg += " SITUACAO: " + aItens[nLinha][14] + CRLF
    cMsg += "-------------------------------------------------" + CRLF

    // Orientacao baseada na situacao
    If aItens[nLinha][16] == 1  // AGUARDANDO ENTRADA NF
        cMsg += "ACAO: Aguardando digitacao da Nota Fiscal" + CRLF
        cMsg += "      Verificar com fornecedor/comprador" + CRLF
    ElseIf aItens[nLinha][16] == 2  // PARADO
        cMsg += "ACAO: Material nao foi consumido" + CRLF
    ElseIf aItens[nLinha][16] == 3  // BAIXA PARCIAL
        cMsg += "ACAO: Verificar uso ou destino do material" + CRLF
    Else  // OK
        cMsg += "Material totalmente consumido." + CRLF
    EndIf

    // Exibe mensagem
    MsgInfo(cMsg, "Detalhes do Produto")

Return

/*/{Protheus.doc} ImprimirBrowse
Menu de exportacao - escolhe entre Excel ou CSV
@type     function
@author   Juan Almeida
@since    2026.02.02
/*/
Static Function ImprimirBrowse()
    Local nOpcao as numeric

    // Verifica se tem dados
    If Len(aItens) == 0
        MsgInfo("Nao ha dados para imprimir.", "Aviso")
        Return
    EndIf

    // Menu de opcoes
    nOpcao := Aviso("Exportar Dados", "Escolha o formato:", {"Excel", "CSV", "Cancelar"}, 3)

    If nOpcao == 1
        ExportaExcel()
    ElseIf nOpcao == 2
        ExportaCSV()
    EndIf

Return
