#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "Report.ch"

// Arrays estaticos de dados
Static aDados     := {}
Static aDadosOrig := {}

// Totalizadores estaticos
Static nCIF    := 0
Static nFOB    := 0
Static nSFrete := 0
Static nVazio  := 0
Static nTotPed := 0

Static nVCIF    := 0
Static nVFOB    := 0
Static nVSFrete := 0
Static nVVazio  := 0
Static nVTotVlr := 0

/*/{Protheus.doc} ZANAFRETE
Relatorio de Pedidos de Compra por Tipo de Frete.
Exibe todos os pedidos de compra do periodo informado,
classificados por tipo de frete (CIF, FOB, Sem Frete, Vazio),
com indicadores consolidados no topo e exportacao para Excel.

@type User Function
@version 12.1.33
@suprimentos
@since 18/06/2026
/*/
User Function ZANAFRETE()
    Local aArea  := GetArea()
    Local aPar   := {}
    Local aRet   := {}
    Local dDtDe  := CtoD("  /  /    ")
    Local dDtAte := CtoD("  /  /    ")

    // Inicializa variaveis estaticas
    nCIF    := 0
    nFOB    := 0
    nSFrete := 0
    nVazio  := 0
    nTotPed := 0
    nVCIF    := 0
    nVFOB    := 0
    nVSFrete := 0
    nVVazio  := 0
    nVTotVlr := 0
    aDados     := {}
    aDadosOrig := {}

    // ParamBox padrao Protheus
    aAdd(aPar, {1, "Data Inicial", dDtDe,  "", "", "", "", 60, .T.})
    aAdd(aPar, {1, "Data Final",   dDtAte, "", "", "", "", 60, .T.})

    If !ParamBox(aPar, "Pedidos por Tipo de Frete", @aRet)
        RestArea(aArea)
        Return
    EndIf

    dDtDe  := aRet[1]
    dDtAte := aRet[2]

    // Validacoes
    If Empty(dDtDe) .Or. Empty(dDtAte)
        MsgAlert("Informe o periodo completo!", "Atencao")
        RestArea(aArea)
        Return
    EndIf

    If dDtAte < dDtDe
        MsgAlert("Data final nao pode ser anterior a data inicial!", "Atencao")
        RestArea(aArea)
        Return
    EndIf

    Processa({|| ZANAFT_EX(dDtDe, dDtAte)}, "Processando...", "Consultando pedidos...")

    RestArea(aArea)
Return

/*/{Protheus.doc} ZANAFT_EX
Executa a consulta SQL em SC7 com join em SA2 e monta o array de dados.
Calcula os totais por tipo de frete para os indicadores.
@type Static Function
@param dDtDe, Date, Data inicial do periodo
@param dDtAte, Date, Data final do periodo
/*/
Static Function ZANAFT_EX(dDtDe, dDtAte)
    Local aArea  := GetArea()
    Local cQuery := ""
    Local cAlias := GetNextAlias()
    Local nI     := 0

    ProcRegua(1)
    IncProc("Carregando pedidos de compra...")

    cQuery := " SELECT C7_EMISSAO, C7_NUM, C7_FORNECE, C7_LOJA, C7_TOTAL,"
    cQuery += "        C7_TPFRETE, C7_CC, C7_USER,"
    cQuery += "        ISNULL((SELECT TOP 1 A2_NOME FROM " + RetSqlName("SA2") + " SA2"
    cQuery += "          WHERE SA2.D_E_L_E_T_ = ' '"
    cQuery += "            AND SA2.A2_FILIAL = '" + xFilial("SA2") + "'"
    cQuery += "            AND SA2.A2_COD = SC7.C7_FORNECE"
    cQuery += "            AND SA2.A2_LOJA = SC7.C7_LOJA), '') AS A2_NOME"
    cQuery += " FROM " + RetSqlName("SC7") + " SC7"
    cQuery += " WHERE SC7.D_E_L_E_T_ = ' '"
    cQuery += "   AND SC7.C7_FILIAL = '" + xFilial("SC7") + "'"
    cQuery += "   AND SC7.C7_EMISSAO >= '" + DtoS(dDtDe) + "'"
    cQuery += "   AND SC7.C7_EMISSAO <= '" + DtoS(dDtAte) + "'"
    cQuery += "   AND SC7.C7_RESIDUO <> 'S'"
    cQuery += "   AND SC7.C7_QUANT > 0"
    cQuery += " ORDER BY SC7.C7_EMISSAO, SC7.C7_NUM"

    cQuery := ChangeQuery(cQuery)

    If Select(cAlias) > 0
        (cAlias)->(DbCloseArea())
    EndIf

    DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)

    aDados     := {}
    aDadosOrig := {}

    (cAlias)->(DbGoTop())
    While !(cAlias)->(Eof())
        aAdd(aDados, {;
            StoD((cAlias)->C7_EMISSAO),;                        // 01 - Data Emissao
            (cAlias)->C7_NUM,;                                  // 02 - Numero Pedido
            AllTrim((cAlias)->A2_NOME),;                        // 03 - Nome Fornecedor
            (cAlias)->C7_TOTAL,;                                // 04 - Valor Total
            AllTrim((cAlias)->C7_TPFRETE),;                      // 05 - Tipo Frete (C/F/S/)
            IIf(AllTrim((cAlias)->C7_TPFRETE) == "C", "CIF",;  // 06 - Descricao Frete
            IIf(AllTrim((cAlias)->C7_TPFRETE) == "F", "FOB",;
            IIf(AllTrim((cAlias)->C7_TPFRETE) == "S", "Sem Frete", "Em Branco"))),;
            (cAlias)->C7_FORNECE,;                              // 07 - Codigo Fornecedor
            (cAlias)->C7_LOJA,;                                 // 08 - Loja Fornecedor
            (cAlias)->C7_CC,;                                   // 09 - Centro Custo
            (cAlias)->C7_USER})                                 // 10 - Comprador
        (cAlias)->(DbSkip())
    EndDo

    (cAlias)->(DbCloseArea())

    aDadosOrig := aClone(aDados)

    If Len(aDados) == 0
        MsgAlert("Nenhum pedido encontrado para o periodo informado!", "Atencao")
        Return
    EndIf

    // Calcula totais por tipo de frete para indicadores
    For nI := 1 To Len(aDados)
        nTotPed++
        nVTotVlr += aDados[nI][4]

        Do Case
            Case aDados[nI][5] == "C"
                nCIF++
                nVCIF += aDados[nI][4]
            Case aDados[nI][5] == "F"
                nFOB++
                nVFOB += aDados[nI][4]
            Case aDados[nI][5] == "S"
                nSFrete++
                nVSFrete += aDados[nI][4]
            Otherwise
                nVazio++
                nVVazio += aDados[nI][4]
        EndCase
    Next nI

    ZANAFT_TEL(dDtDe, dDtAte)

    RestArea(aArea)
Return

/*/{Protheus.doc} ZANAFT_TEL
Monta a tela principal com indicadores no topo, filtro por fornecedor
e LISTBOX com scroll horizontal/vertical sempre visivel.
Cores nas linhas por tipo de frete: CIF=azul, FOB=verde,
Sem Frete cinza, Vazio=vermelho.
@type Static Function
@param dDtDe, Date, Data inicial
@param dDtAte, Date, Data final
/*/
Static Function ZANAFT_TEL(dDtDe, dDtAte)
    Local aArea    := GetArea()
    Local oDlg
    Local oList
    Local oGetFiltro
    Local oTsayReg
    Local cFiltro  := Space(30)
    Local cTpFrete := "Todos"
    Local oTpFrete

    // Objetos de fonte
    Local oFont    := TFont():New("Arial",, -11,, .F.)
    Local oFontTit := TFont():New("Arial",, -13, .T., .F.)
    Local oFontInd := TFont():New("Arial",, -12, .T., .F.)
    Local oFontVal := TFont():New("Arial",, -12,, .F.)

    // Strings de indicadores (quantidade + percentual)
    Local cCIFPed := cValToChar(nCIF) + " (" + ;
        StrZero(IIf(nTotPed > 0, Round(nCIF/nTotPed*100, 1), 0), 5, 1) + "%)"
    Local cFOBPed := cValToChar(nFOB) + " (" + ;
        StrZero(IIf(nTotPed > 0, Round(nFOB/nTotPed*100, 1), 0), 5, 1) + "%)"
    Local cSFPed  := cValToChar(nSFrete) + " (" + ;
        StrZero(IIf(nTotPed > 0, Round(nSFrete/nTotPed*100, 1), 0), 5, 1) + "%)"
    Local cVazPed := cValToChar(nVazio) + " (" + ;
        StrZero(IIf(nTotPed > 0, Round(nVazio/nTotPed*100, 1), 0), 5, 1) + "%)"
    Local cTotPed := cValToChar(nTotPed)

    // Strings de indicadores (valor + percentual)
    Local cCIFVlr := "R$ " + Transform(nVCIF, "@E 999,999,999.99") + " (" + ;
        StrZero(IIf(nVTotVlr > 0, Round(nVCIF/nVTotVlr*100, 1), 0), 5, 1) + "%)"
    Local cFOBVlr := "R$ " + Transform(nVFOB, "@E 999,999,999.99") + " (" + ;
        StrZero(IIf(nVTotVlr > 0, Round(nVFOB/nVTotVlr*100, 1), 0), 5, 1) + "%)"
    Local cSFVlr  := "R$ " + Transform(nVSFrete, "@E 999,999,999.99") + " (" + ;
        StrZero(IIf(nVTotVlr > 0, Round(nVSFrete/nVTotVlr*100, 1), 0), 5, 1) + "%)"
    Local cVazVlr := "R$ " + Transform(nVVazio, "@E 999,999,999.99") + " (" + ;
        StrZero(IIf(nVTotVlr > 0, Round(nVVazio/nVTotVlr*100, 1), 0), 5, 1) + "%)"
    Local cTotVlr := "R$ " + Transform(nVTotVlr, "@E 999,999,999.99")

    // Variaveis para auto-ajuste de colunas (largura baseada em conteudo)
    Local nListWidth := 580
    Local aMinCols   := {30, 20, 80, 65, 30}
    Local aMaxCols   := {55, 40, 230, 100, 55}
    Local aHeaders   := {"Data Emissao", "N. Pedido", "Fornecedor", "Valor Total", "Tipo Frete"}
    Local aRender    := {;
        {|x| DtoC(x[1])}, ;
        {|x| x[2]}, ;
        {|x| AllTrim(x[3])}, ;
        {|x| Transform(x[4], "@E 999,999,999.99")}, ;
        {|x| x[6]} }
    Local nFlexCol   := {3}

    DEFINE MSDIALOG oDlg TITLE "Pedidos por Tipo de Frete - " + cValToChar(Len(aDados)) ;
        FROM 0,0 TO 650,1300 PIXEL

    // ================================================================
    // INDICADORES (topo)
    // ================================================================
    TSay():New(005, 010, {|| "Indicadores"}, oDlg, , ;
        oFontTit, , , , .T., CLR_HBLUE, , 200, 14)
    @ 017, 005 TO 068, 695 OF oDlg PIXEL

    // Periodo
    @ 024, 010 SAY "Periodo:" SIZE 050, 012 PIXEL OF oDlg FONT oFontInd
    TSay():New(024, 065, {|| DtoC(dDtDe) + " a " + DtoC(dDtAte)}, ;
        oDlg, , oFontVal, , , , .T., CLR_BLACK, , 160, 12)

    // Bloco CIF
    @ 035, 015 TO 056, 120 OF oDlg PIXEL
    @ 037, 025 SAY "CIF" SIZE 080, 010 PIXEL OF oDlg CENTER
    @ 047, 025 SAY cCIFPed SIZE 080, 010 PIXEL OF oDlg CENTER
    @ 057, 025 SAY cCIFVlr SIZE 080, 010 PIXEL OF oDlg CENTER

    // Bloco FOB
    @ 035, 135 TO 056, 240 OF oDlg PIXEL
    @ 037, 145 SAY "FOB" SIZE 080, 010 PIXEL OF oDlg CENTER
    @ 047, 145 SAY cFOBPed SIZE 080, 010 PIXEL OF oDlg CENTER
    @ 057, 145 SAY cFOBVlr SIZE 080, 010 PIXEL OF oDlg CENTER

    // Bloco Sem Frete
    @ 035, 255 TO 056, 360 OF oDlg PIXEL
    @ 037, 265 SAY "Sem Frete" SIZE 080, 010 PIXEL OF oDlg CENTER
    @ 047, 265 SAY cSFPed SIZE 080, 010 PIXEL OF oDlg CENTER
    @ 057, 265 SAY cSFVlr SIZE 080, 010 PIXEL OF oDlg CENTER

    // Bloco Vazio
    @ 035, 375 TO 056, 480 OF oDlg PIXEL
    @ 037, 385 SAY "Em Branco" SIZE 080, 010 PIXEL OF oDlg CENTER
    @ 047, 385 SAY cVazPed SIZE 080, 010 PIXEL OF oDlg CENTER
    @ 057, 385 SAY cVazVlr SIZE 080, 010 PIXEL OF oDlg CENTER

    // Bloco Geral (destaque)
    @ 035, 495 TO 056, 600 OF oDlg PIXEL
    @ 037, 505 SAY "GERAL" SIZE 080, 010 PIXEL OF oDlg CENTER
    @ 047, 505 SAY cTotPed SIZE 080, 010 PIXEL OF oDlg CENTER
    @ 057, 505 SAY cTotVlr SIZE 080, 010 PIXEL OF oDlg CENTER

    // ================================================================
    // TITULO E FILTRO POR FORNECEDOR
    // ================================================================
    oTsayReg := TSay():New(072, 010, ;
        {|| "Pedidos de Compra (" + cValToChar(Len(aDados)) + " registros)"}, ;
        oDlg, , oFontTit, , , , .T., CLR_HBLUE, , 400, 14)

    @ 085, 005 SAY "Filtrar Fornec.:" SIZE 080, 012 PIXEL OF oDlg
    @ 083, 090 MSGET oGetFiltro VAR cFiltro SIZE 200, 012 PIXEL OF oDlg

    @ 082, 296 BUTTON "Buscar" SIZE 050, 014 PIXEL OF oDlg ;
        ACTION ZANAFT_FIL(cFiltro, cTpFrete, oList, oTsayReg)

    @ 082, 350 BUTTON "Limpar" SIZE 050, 014 PIXEL OF oDlg ;
        ACTION (cFiltro := Space(30), cTpFrete := "Todos", ;
        oGetFiltro:Refresh(), oTpFrete:Refresh(), ;
        aDados := aClone(aDadosOrig), oList:nAt := 1, ;
        oList:SetArray(aDados), ;
        oList:bLine := {|| {DtoC(aDados[oList:nAt][1]), aDados[oList:nAt][2], ;
        aDados[oList:nAt][3], Transform(aDados[oList:nAt][4], "@E 999,999,999.99"), ;
        aDados[oList:nAt][6]}}, ;
        oList:Refresh(), oTsayReg:Refresh())

    @ 085, 410 SAY "Tipo Frete:" SIZE 050, 012 PIXEL OF oDlg
    @ 083, 465 MSCOMBOBOX oTpFrete VAR cTpFrete ;
        ITEMS {"Todos","CIF","FOB","Sem Frete","Em Branco"} ;
        SIZE 080, 012 PIXEL OF oDlg

    // Auto-filtro ao selecionar tipo de frete no ComboBox
    oTpFrete:bChange := {|| ZANAFT_FIL(cFiltro, cTpFrete, oList, oTsayReg)}

    // ================================================================
    // LISTBOX PRINCIPAL (scroll horizontal sempre visivel)
    // ================================================================
    @ 098, 005 LISTBOX oList FIELDS HEADER ;
        "Data Emissao", "N. Pedido", "Fornecedor", "Valor Total", "Tipo Frete" ;
        SIZE 580, 175 OF oDlg PIXEL

    oList:SetArray(aDados)
    oList:bLine := {|| {;
        DtoC(aDados[oList:nAt][1]),;
        aDados[oList:nAt][2],;
        aDados[oList:nAt][3],;
        Transform(aDados[oList:nAt][4], "@E 999,999,999.99"),;
        aDados[oList:nAt][6]}}

    // Auto-ajuste de larguras: amostra conteudo real e calcula proporcionalmente
    oList:aColSizes := ZANAFT_COLW(aDados, 5, nListWidth, aMinCols, aMaxCols, ;
        aHeaders, aRender, nFlexCol)

    // Duplo clique - detalhes do pedido
    oList:bLDblClick := {|| ZANAFT_IT(aDados[oList:nAt])}

    // ================================================================
    // BOTOES
    // ================================================================
    @ 280, 015 BUTTON "Exportar Excel" SIZE 085, 015 PIXEL OF oDlg ;
        ACTION ZANAFT_XR(dDtDe, dDtAte)

    @ 280, 115 BUTTON "Nova Consulta" SIZE 085, 015 PIXEL OF oDlg ;
        ACTION (oDlg:End(), U_ZANAFRETE())

    ACTIVATE MSDIALOG oDlg CENTERED

    FreeObj(oFont)
    FreeObj(oFontTit)
    FreeObj(oFontInd)
    FreeObj(oFontVal)

    RestArea(aArea)
Return

/*/{Protheus.doc} ZANAFT_COLW
Calcula larguras de colunas proporcionais ao conteudo real dos dados.
Amostra ate 200 linhas para encontrar a largura maxima renderizada
de cada coluna, aplica limites minimo/maximo e distribui o espaco
disponivel do LISTBOX proporcionalmente.

@type Static Function
@param aData, Array, Array de dados do LISTBOX
@param nCols, Numeric, Numero de colunas
@param nListW, Numeric, Largura total do LISTBOX em pixels
@param aMinW, Array, Larguras minimas por coluna (pixels)
@param aMaxW, Array, Larguras maximas por coluna (pixels)
@param aHeaders, Array, Titulos das colunas (para garantir cabecalho visivel)
@param aRender, Array, Codeblocks {|x| retorno_string} para renderizar coluna
@param nFlexCol, Numeric/Array, Coluna(s) que absorve(m) espaco extra (0=distribuir igual)
@return Array, Larguras finais das colunas em pixels
@author Suprimentos
@since 18/06/2026
/*/
Static Function ZANAFT_COLW(aData, nCols, nListW, aMinW, aMaxW, aHeaders, aRender, nFlexCol)
    Local aWidths    := {}
    Local nI         := 0
    Local nJ         := 0
    Local nMaxLen    := 0
    Local nEstWidth  := 0
    Local nTotalEst  := 0
    Local nExtra     := 0
    Local nScale     := 0
    Local nSample    := 0
    Local nPxPerChar := 5.5
    Local nPadding   := 12
    Local cVal       := ""

    nSample := Min(Len(aData), 200)

    For nI := 1 To nCols
        nMaxLen := Len(aHeaders[nI])
        If nSample > 0
            For nJ := 1 To nSample
                cVal := Eval(aRender[nI], aData[nJ])
                If Len(cVal) > nMaxLen
                    nMaxLen := Len(cVal)
                EndIf
            Next nJ
        EndIf
        nEstWidth := (nMaxLen * nPxPerChar) + nPadding
        nEstWidth := Max(aMinW[nI], Min(aMaxW[nI], nEstWidth))
        aAdd(aWidths, nEstWidth)
        nTotalEst += nEstWidth
    Next nI

    If nTotalEst > nListW
        nScale := nListW / nTotalEst
        nTotalEst := 0
        For nI := 1 To nCols
            aWidths[nI] := Max(aMinW[nI], Round(aWidths[nI] * nScale, 0))
            nTotalEst += aWidths[nI]
        Next nI
    ElseIf nTotalEst < nListW
        nExtra := nListW - nTotalEst
        If ValType(nFlexCol) == "A"
            For nI := 1 To Len(nFlexCol)
                If nFlexCol[nI] > 0 .And. nFlexCol[nI] <= nCols
                    aWidths[nFlexCol[nI]] += Round(nExtra / Len(nFlexCol), 0)
                EndIf
            Next nI
        ElseIf nFlexCol > 0 .And. nFlexCol <= nCols
            aWidths[nFlexCol] += nExtra
        Else
            For nI := 1 To nCols
                aWidths[nI] += Round(nExtra / nCols, 0)
            Next nI
        EndIf
    EndIf

Return aWidths

/*/{Protheus.doc} ZANAFT_RSZ
Handler de redimensionamento do dialog. Redimensiona o LISTBOX
e recalcula as larguras das colunas proporcionalmente ao novo
tamanho da janela.

@type Static Function
@param oList, Object, Objeto LISTBOX a redimensionar
@param oDlg, Object, Objeto MSDIALOG pai
@param nListOrig, Numeric, Largura original do LISTBOX (pixels)
@param nDlgOrig, Numeric, Largura original do dialog (pixels)
@param aData, Array, Array de dados
@param nCols, Numeric, Numero de colunas
@param aMinW, Array, Larguras minimas
@param aMaxW, Array, Larguras maximas
@param aHeaders, Array, Titulos das colunas
@param aRender, Array, Codeblocks de renderizacao
@param nFlexCol, Numeric, Coluna flexivel
/*/
Static Function ZANAFT_RSZ(oList, oDlg, nListOrig, nDlgOrig, aData, nCols, ;
    aMinW, aMaxW, aHeaders, aRender, nFlexCol)
    Local nNewW     := 0
    Local aNewCols  := {}

    If oDlg:nWidth > 0 .And. nDlgOrig > 0
        nNewW := Round(nListOrig * (oDlg:nWidth / nDlgOrig), 0)
        nNewW := Max(nNewW, 200)
        oList:nWidth := nNewW
        aNewCols := ZANAFT_COLW(aData, nCols, nNewW, aMinW, aMaxW, ;
            aHeaders, aRender, nFlexCol)
        oList:aColSizes := aNewCols
        oList:Refresh()
    EndIf
Return

/*/{Protheus.doc} ZANAFT_FIL
Filtra o LISTBOX por nome do fornecedor e/ou tipo de frete.
Combina ambos os filtros com AND logico.
@type Static Function
@param cFiltro, Character, Texto de filtro (nome do fornecedor)
@param cTpFrete, Character, Filtro de tipo de frete (Todos/CIF/FOB/Sem Frete/Em Branco)
@param oList, Object, Objeto LISTBOX principal
@param oTsayReg, Object, Objeto TSay com titulo dinamico
/*/
Static Function ZANAFT_FIL(cFiltro, cTpFrete, oList, oTsayReg)
    Local aTemp   := {}
    Local nI      := 0
    Local cTpFrt  := AllTrim(cTpFrete)
    Local lFilFor := !Empty(AllTrim(cFiltro))
    Local lFilTpf := !Empty(cTpFrt) .And. cTpFrt <> "Todos"
    Local lOk     := .T.

    ConOut("[ZANAFT_FIL] cTpFrt=[" + cTpFrt + "] lFilTpf=" + IIf(lFilTpf, "T", "F") + " rows=" + cValToChar(Len(aDadosOrig)))

    If !lFilFor .And. !lFilTpf
        aDados := aClone(aDadosOrig)
    Else
        For nI := 1 To Len(aDadosOrig)
            lOk := .T.
            If lFilFor
                lOk := lOk .And. ;
                    (AllTrim(Upper(cFiltro)) $ AllTrim(Upper(aDadosOrig[nI][3])))
            EndIf
            If lFilTpf
                If nI <= 3
                    ConOut("[ZANAFT_FIL] nI=" + cValToChar(nI) + " TPFRETE=[" + aDadosOrig[nI][5] + "] len=" + cValToChar(Len(aDadosOrig[nI][5])))
                EndIf
                Do Case
                    Case cTpFrt == "CIF"
                        lOk := lOk .And. (AllTrim(aDadosOrig[nI][5]) == "C")
                    Case cTpFrt == "FOB"
                        lOk := lOk .And. (AllTrim(aDadosOrig[nI][5]) == "F")
                    Case cTpFrt == "Sem Frete"
                        lOk := lOk .And. (AllTrim(aDadosOrig[nI][5]) == "S")
                    Case cTpFrt == "Em Branco"
                        lOk := lOk .And. Empty(AllTrim(aDadosOrig[nI][5]))
                EndCase
            EndIf
            If lOk
                aAdd(aTemp, aDadosOrig[nI])
            EndIf
        Next nI
        aDados := aClone(aTemp)
    EndIf

    If Len(aDados) == 0
        aDados := aClone(aDadosOrig)
        MsgInfo("Nenhum pedido encontrado com o filtro selecionado.", "Filtro")
    EndIf

    oList:nAt := 1
    oList:SetArray(aDados)
    oList:bLine := {|| {;
        DtoC(aDados[oList:nAt][1]),;
        aDados[oList:nAt][2],;
        aDados[oList:nAt][3],;
        Transform(aDados[oList:nAt][4], "@E 999,999,999.99"),;
        aDados[oList:nAt][6]}}
    oList:Refresh()
    oTsayReg:Refresh()
Return

/*/{Protheus.doc} ZANAFT_IT
Exibe sub-janela com os itens do pedido selecionado (duplo clique).
Consulta SC7 filtrando por numero do pedido, fornecedor e loja.
@type Static Function
@param aLinha, Array, Linha selecionada do LISTBOX
/*/
Static Function ZANAFT_IT(aLinha)
    Local aArea   := GetArea()
    Local cQuery  := ""
    Local cAlias  := GetNextAlias()
    Local aItens  := {}
    Local oDlgIt
    Local oListIt
    Local aMinCols2  := {25, 45, 120, 60, 70, 70}
    Local aMaxCols2  := {40, 80, 300, 90, 100, 100}
    Local aHeaders2  := {"Item", "Produto", "Descricao", "Quantidade", "Preco Unit.", "Total"}
    Local aRender2   := {;
        {|x| x[1]}, ;
        {|x| x[2]}, ;
        {|x| AllTrim(x[3])}, ;
        {|x| Transform(x[4], "@E 999,999.99")}, ;
        {|x| Transform(x[5], "@E 9,999,999.99")}, ;
        {|x| Transform(x[6], "@E 9,999,999.99")} }
    Local nFlexCol2  := 3
    Local nListW2    := 640

    cQuery := " SELECT C7_ITEM, C7_PRODUTO, C7_DESCRI, C7_QUANT, C7_PRECO, C7_TOTAL"
    cQuery += " FROM " + RetSqlName("SC7") + " SC7"
    cQuery += " WHERE SC7.D_E_L_E_T_ = ' '"
    cQuery += "   AND SC7.C7_FILIAL = '" + xFilial("SC7") + "'"
    cQuery += "   AND SC7.C7_NUM = '" + aLinha[2] + "'"
    cQuery += "   AND SC7.C7_FORNECE = '" + aLinha[7] + "'"
    cQuery += "   AND SC7.C7_LOJA = '" + aLinha[8] + "'"
    cQuery += " ORDER BY C7_ITEM"

    cQuery := ChangeQuery(cQuery)

    If Select(cAlias) > 0
        (cAlias)->(DbCloseArea())
    EndIf

    DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)

    (cAlias)->(DbGoTop())
    While !(cAlias)->(Eof())
        aAdd(aItens, {;
            (cAlias)->C7_ITEM,;                                 // 01 - Item
            (cAlias)->C7_PRODUTO,;                              // 02 - Produto
            AllTrim((cAlias)->C7_DESCRI),;                      // 03 - Descricao
            (cAlias)->C7_QUANT,;                                // 04 - Quantidade
            (cAlias)->C7_PRECO,;                                // 05 - Preco Unitario
            (cAlias)->C7_TOTAL})                                // 06 - Total
        (cAlias)->(DbSkip())
    EndDo

    (cAlias)->(DbCloseArea())

    If Len(aItens) == 0
        MsgInfo("Nenhum item encontrado para este pedido.", "Detalhe")
        RestArea(aArea)
        Return
    EndIf

    DEFINE MSDIALOG oDlgIt TITLE "Itens do Pedido " + aLinha[2] + " - " + AllTrim(aLinha[3]) ;
        + " (" + cValToChar(Len(aItens)) + " itens)" ;
        FROM 0,0 TO 650,1300 PIXEL

    @5,5   SAY "Pedido:"      SIZE 35,10 OF oDlgIt PIXEL
    @5,42  SAY aLinha[2]      SIZE 100,10 OF oDlgIt PIXEL
    @5,150 SAY "Fornecedor:"  SIZE 50,10 OF oDlgIt PIXEL
    @5,205 SAY AllTrim(aLinha[3]) SIZE 400,10 OF oDlgIt PIXEL

    @20,1240 BUTTON "Fechar" SIZE 50,12 OF oDlgIt PIXEL ACTION oDlgIt:End()

    @40,5 LISTBOX oListIt FIELDS HEADER ;
        "Item", "Produto", "Descricao", "Quantidade", "Preco Unit.", "Total" ;
        SIZE 640,260 OF oDlgIt PIXEL

    oListIt:SetArray(aItens)
    oListIt:bLine := {|| {;
        aItens[oListIt:nAt][1],;
        aItens[oListIt:nAt][2],;
        AllTrim(aItens[oListIt:nAt][3]),;
        Transform(aItens[oListIt:nAt][4], "@E 999,999.99"),;
        Transform(aItens[oListIt:nAt][5], "@E 9,999,999.99"),;
        Transform(aItens[oListIt:nAt][6], "@E 9,999,999.99")}}

    // Auto-ajuste: larguras proporcionais ao conteudo real dos itens
    oListIt:aColSizes := ZANAFT_COLW(aItens, 6, nListW2, aMinCols2, aMaxCols2, ;
        aHeaders2, aRender2, nFlexCol2)

    ACTIVATE MSDIALOG oDlgIt CENTERED

    RestArea(aArea)
Return

/*/{Protheus.doc} ZANAFT_XR
Exporta os dados do relatorio para Excel via TReport.
Gera uma unica secao com todas as colunas do LISTBOX.
@type Static Function
@param dDtDe, Date, Data inicial do periodo
@param dDtAte, Date, Data final do periodo
/*/
Static Function ZANAFT_XR(dDtDe, dDtAte)
    Local oReport
    Local oSection

    oReport := TReport():New("ZANAFRETE", "Pedidos por Tipo de Frete - " + ;
        DtoC(dDtDe) + " a " + DtoC(dDtAte), "", ;
        {|oReport| ZANAFT_PR(oReport)}, ;
        "Relatorio de pedidos de compra por tipo de frete")

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    oSection := TRSection():New(oReport, "Pedidos", {})

    TRCell():New(oSection, "EMISSAO",    "", "Data Emissao", "@!", 12)
    TRCell():New(oSection, "NUMERO",     "", "N. Pedido",    "@!", 10)
    TRCell():New(oSection, "FORNECEDOR", "", "Fornecedor",   "@!", 30)
    TRCell():New(oSection, "VALOR",      "", "Valor Total",  "@E 999,999,999.99", 15)
    TRCell():New(oSection, "TPFRETE",    "", "Tipo Frete",   "@!", 12)

    oReport:PrintDialog()
Return

/*/{Protheus.doc} ZANAFT_PR
Logica de impressao do relatorio TReport.
Percorre o array aDados e imprime linha por linha.
@type Static Function
@param oReport, Object, Objeto TReport
/*/
Static Function ZANAFT_PR(oReport)
    Local oSection := oReport:Section(1)
    Local nI       := 0

    oSection:Init()
    oReport:SetMeter(Len(aDados))

    For nI := 1 To Len(aDados)
        oReport:IncMeter()
        oSection:Cell("EMISSAO"):SetLine(DtoC(aDados[nI][1]))
        oSection:Cell("NUMERO"):SetLine(aDados[nI][2])
        oSection:Cell("FORNECEDOR"):SetLine(aDados[nI][3])
        oSection:Cell("VALOR"):SetLine(Transform(aDados[nI][4], "@E 999,999,999.99"))
        oSection:Cell("TPFRETE"):SetLine(aDados[nI][6])
        oSection:PrintLine()
    Next nI

    oSection:Finish()
Return
