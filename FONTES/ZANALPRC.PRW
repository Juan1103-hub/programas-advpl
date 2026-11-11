#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "Report.ch"

Static cCCUltimo := "*"   // Persiste ultimo CC selecionado na sessao

/*/{Protheus.doc} U_ZANALPRC
Tela virtual de consulta e analise de variacao de precos de itens de compra.
Compara o valor unitario das notas fiscais de entrada (SD1) dentro de um
periodo, agrupando por item, identificando aumento, reducao ou manutencao
de preco entre a menor e a maior data de compra encontradas.
Funcionalidades:
- ParamBox de periodo e comprador (padrao ZLEADTIME)
- Filtros adicionais na tela: item, descricao, tipo de variacao
- Grid principal com situacao textual (AUMENTOU/DIMINUIU/MANTEVE)
- Duplo clique no grid abre historico completo de compras do item
- Botao Indicadores: totais por situacao, maior aumento/reducao, economia
  acumulada (penultima vs ultima compra) e economia historica (primeira vs ultima)
- Botao Excel: exporta Analise, Historico e Indicadores em 3 abas
@author  Copilot / Suprimentos
@since   02/06/2026
@version 3.0
/*/
User Function ZANALPRC()
    Local aDlg
    Local oL
    Local oDtDe, oDtAte, oItem, oDescr, oTipo
    Local dDtDe      := CtoD("")
    Local dDtAte     := Date()
    Local cItem      := Space(30)
    Local cDescr     := Space(30)
    Local cTipoVar   := "TODAS"
    Local aCompCombo := {}
    Local aCompCods  := {}
    Local aCCCombo   := {}
    Local aCCCods    := {}
    Local cCodUser   := ""
    Local cCodCC     := "*"
    Local aPar       := {}
    Local aRet       := {}
    Local nIdx       := 1
    Local nIdxCC     := 1
    Local aArray     := {}

    // Variaveis para ajuste dinamico das colunas do LISTBOX
    Local nListWidth := 640
    Local aMinCols := {55,180,95,55,70,75,70,50,50,60}
    Local nSumMin := 0
    Local nI := 0
    Local aFinalCols := {}
    Local nVal := 0
    Local nExtra := 0

    Private aZANPDET := {}
    Private dZANPDE  := CtoD("")
    Private dZANPATE := Date()
    Private nZANPSO1 := 0   // Itens com apenas 1 compra no periodo (sem comparacao)

    AnpCarCompLT(@aCompCombo, @aCompCods)
    AnpCarCC(@aCCCombo, @aCCCods)

    // Pre-seleciona o ultimo CC utilizado na sessao
    nIdxCC := aScan(aCCCods, {|x| x = cCCUltimo})
    If nIdxCC = 0
        nIdxCC := 1
    EndIf

    Do While .T.
        aPar := {}
        aAdd(aPar, {1, "Data Inicial", dDtDe,  "", "", "", "", 60, .T.})
        aAdd(aPar, {1, "Data Final",   dDtAte, "", "", "", "", 60, .T.})
        aAdd(aPar, {2, "Comprador",    nIdx,    aCompCombo, 80, "", .F.})
        aAdd(aPar, {2, "Centro Custo", nIdxCC,  aCCCombo,   80, "", .F.})

        If !ParamBox(aPar, "Analise de Variacao de Precos", @aRet)
            Exit
        EndIf

        dDtDe  := aRet[1]
        dDtAte := aRet[2]
        nIdx   := IIF(ValType(aRet[3]) = "N", aRet[3], ;
            aScan(aCompCombo, {|x| AllTrim(x) = AllTrim(cValToChar(aRet[3]))}))
        nIdx   := Max(1, Min(nIdx, Len(aCompCombo)))
        // indice e codigo do Centro de Custo selecionado
        nIdxCC := IIF(ValType(aRet[4]) = "N", aRet[4], ;
            aScan(aCCCombo, {|x| AllTrim(x) = AllTrim(cValToChar(aRet[4]))}))
        nIdxCC := Max(1, Min(nIdxCC, Len(aCCCombo)))
        cCodCC := aCCCods[nIdxCC]
        cCCUltimo := cCodCC   // Persiste para proxima chamada

        If Empty(dDtDe) .Or. Empty(dDtAte)
            MsgAlert("Informe o periodo completo!", "Atencao")
            Loop
        EndIf
        If dDtAte < dDtDe
            MsgAlert("Data Final nao pode ser anterior a Data Inicial!", "Atencao")
            Loop
        EndIf

        cCodUser := aCompCods[nIdx]
        dZANPDE  := dDtDe
        dZANPATE := dDtAte

        aArray := AnpCarrega(dDtDe, dDtAte, cItem, cCodUser, cDescr, cTipoVar, cCodCC)

        If Len(aArray) = 0
            MsgAlert("Nenhum registro encontrado para o periodo e filtros informados!", "Atencao")
            Loop
        EndIf

        DEFINE MSDIALOG aDlg TITLE "Analise de Variacao de Precos - " + cValToChar(Len(aArray)) ;
        FROM 0,0 TO 650,1500 PIXEL

        @5,5    SAY "Data DE:"       SIZE 42,10 OF aDlg PIXEL
        @5,50   MSGET oDtDe  VAR dDtDe  SIZE 55,10 OF aDlg PIXEL
        @5,110  SAY "ate:"           SIZE 18,10 OF aDlg PIXEL
        @5,130  MSGET oDtAte VAR dDtAte SIZE 55,10 OF aDlg PIXEL
        @5,195  SAY "Codigo Item:"   SIZE 50,10 OF aDlg PIXEL
        @5,248  MSGET oItem  VAR cItem  SIZE 100,10 OF aDlg PIXEL
        @5,358  SAY "Descricao:"     SIZE 42,10 OF aDlg PIXEL
        @5,402  MSGET oDescr VAR cDescr SIZE 110,10 OF aDlg PIXEL
        @5,520  SAY "Variacao:"      SIZE 35,10 OF aDlg PIXEL
        @5,558  MSCOMBOBOX oTipo VAR cTipoVar ;
            ITEMS {"TODAS","So AUMENTOU","So DIMINUIU","So MANTEVE"} SIZE 85,10 OF aDlg PIXEL ;
            ON CHANGE (dZANPDE := dDtDe, dZANPATE := dDtAte, ;
            aArray := AnpCarrega(dDtDe, dDtAte, cItem, cCodUser, cDescr, cTipoVar, cCodCC), ;
            AnpReGrid(aDlg, oL, @aArray))

        @20,5   BUTTON "Filtrar"     SIZE 45,12 OF aDlg PIXEL ACTION (;
            dZANPDE := dDtDe, dZANPATE := dDtAte, ;
            aArray := AnpCarrega(dDtDe, dDtAte, cItem, cCodUser, cDescr, cTipoVar, cCodCC), ;
            AnpReGrid(aDlg, oL, @aArray))

        @20,55  BUTTON "Limpar"      SIZE 45,12 OF aDlg PIXEL ACTION (;
            cItem := Space(30), cDescr := Space(30), cTipoVar := "TODAS", ;
            oItem:Refresh(), oDescr:Refresh(), oTipo:Refresh(), ;
            dZANPDE := dDtDe, dZANPATE := dDtAte, ;
            aArray := AnpCarrega(dDtDe, dDtAte, cItem, cCodUser, cDescr, cTipoVar, cCodCC), ;
            AnpReGrid(aDlg, oL, @aArray))

        @20,105 BUTTON "Excel"        SIZE 45,12 OF aDlg PIXEL ACTION AnpExcel(aArray)
        @20,155 BUTTON "Nova Consulta" SIZE 65,12 OF aDlg PIXEL ACTION aDlg:End()
        @20,225 BUTTON "Indicadores"  SIZE 55,12 OF aDlg PIXEL ACTION AnpInd(aArray, dDtDe, dDtAte, cItem, cCodUser, cCodCC)

        @40,5 LISTBOX oL FIELDS HEADER ;
            "Codigo","Descricao do Item","Centro Custo","Qtd. Total","Primeiro Valor Unitario","Valor Unitario Anterior","Valor Unitario Atual","Diferenca R$","Variacao %","Situacao" ;
            SIZE 740,260 OF aDlg PIXEL HSCROLL

        oL:SetArray(aArray)
        // Ajuste dinamico das larguras das colunas para caber na largura do LISTBOX (740 px)
        nListWidth := 740
        aMinCols := {55,180,95,55,70,75,70,50,50,60}
        nSumMin := 0
        aFinalCols := {}
        nVal := 0
        nExtra := 0
        For nI := 1 To Len(aMinCols)
            nSumMin += aMinCols[nI]
        Next
        If nSumMin <= nListWidth
            nExtra := nListWidth - nSumMin
            For nI := 1 To Len(aMinCols)
                nVal := aMinCols[nI] + IIf(nI = 2, nExtra, 0)
                aAdd(aFinalCols, nVal)
            Next
        Else
            For nI := 1 To Len(aMinCols)
                nVal := Round(aMinCols[nI] * nListWidth / nSumMin, 0)
                aAdd(aFinalCols, nVal)
            Next
        EndIf
        oL:aColSizes := aFinalCols

        oL:bLine := {|| {;
            aArray[oL:nAt,1], ;
            AllTrim(aArray[oL:nAt,2]), ;
            AllTrim(aArray[oL:nAt,3]), ;
            Transform(aArray[oL:nAt,5],"@E 999,999.99"), ;
            Transform(aArray[oL:nAt,6],"@E 9,999,999.99"), ;
            Transform(aArray[oL:nAt,7],"@E 9,999,999.99"), ;
            Transform(aArray[oL:nAt,8],"@E 9,999,999.99"), ;
            Transform(aArray[oL:nAt,9],"@E 9,999,999.99"), ;
            Str(aArray[oL:nAt,10],10,2) + "%", ;
            aArray[oL:nAt,11]}}

        oL:bLDblClick := {|| AnpDet(aArray[oL:nAt,1], aArray[oL:nAt,2])}

        ACTIVATE MSDIALOG aDlg CENTERED
    EndDo
Return

//=====================================================================
// Static Function AnpCalcColWidths
// Calcula larguras ideais das colunas baseadas no conteudo real
// @param aArray: array de dados
// @param aHeaders: array de headers
// @param aFormats: array de formatos Transform (ou bloco de c?digo)
// @param nListWidth: largura total do LISTBOX (default 640)
// @param aMinByType: array de pisos m?nimos por tipo de coluna
// @return aFinalCols: array com larguras finais por coluna
//=====================================================================
Static Function AnpCalcColWidths(aArray, aHeaders, aFormats, nListWidth, aMinByType)
    Local nCols := Len(aHeaders)
    Local aIdeal := Array(nCols, 0)
    Local aMin   := aMinByType
    Local nSumIdeal := 0
    Local nSumMin := 0
    Local nI := 0
    Local nJ := 0
    Local cSample := ""
    Local nCharW := 7
    Local nPad   := 12
    Local aFinal := Array(nCols, 0)
    Local nExtra := 0
    Local aFlex := {}
    Local nFlexCount := 0
    Local nAdd := 0
    Local nSumFinal := 0
    Local nScale := 0
    Local nIdealHdr := 0
    Local nIdealDat := 0

    // Se nao passou pisos, usa defaults por posicao (heuristica)
    If Len(aMin) != nCols
        aMin := {}
        For nI := 1 To nCols
            aAdd(aMin, 50)
        Next
    EndIf

    // Para cada coluna: largura ideal = max(header, maior dado formatado) * charW + pad
    For nI := 1 To nCols
        // Header
        nIdealHdr := Len(AllTrim(aHeaders[nI])) * nCharW + nPad

        // Amostra de dados (ate 50 linhas ou todas)
        nIdealDat := 0
        For nJ := 1 To Min(Len(aArray), 50)
            If ValType(aFormats[nI]) == "B"
                cSample := AllTrim(cValToChar(Eval(aFormats[nI], aArray[nJ])))
            Else
                cSample := AllTrim(Transform(aArray[nJ, nI], aFormats[nI]))
            EndIf
            nIdealDat := Max(nIdealDat, Len(cSample) * nCharW + nPad)
        Next

        aIdeal[nI] := Max(nIdealHdr, nIdealDat)
        // Aplica piso minimo
        aIdeal[nI] := Max(aIdeal[nI], aMin[nI])
        nSumIdeal += aIdeal[nI]
    Next

    nSumMin := 0
    For nI := 1 To nCols
        nSumMin += aMin[nI]
    Next

    // Distribuicao final
    If nSumIdeal <= nListWidth
        // Cabe tudo: usa ideal + distribui sobra nas colunas "flexiveis"
        nExtra := nListWidth - nSumIdeal
        // Colunas que podem crescer: Descricao (2), Nome CC (6), Fornecedor (9 no historico)
        aFlex := {2, 6, 9, 3}
        nFlexCount := 0
        For nI := 1 To Len(aFlex)
            If aFlex[nI] <= nCols
                nFlexCount++
            EndIf
        Next
        For nI := 1 To nCols
            nAdd := 0
            If nFlexCount > 0 .And. aScan(aFlex, {|x| x == nI}) > 0
                nAdd := Int(nExtra / nFlexCount)
            EndIf
            aFinal[nI] := aIdeal[nI] + nAdd
        Next
        // Ajusta ultimo para fechar exatamente nListWidth
        nSumFinal := 0
        For nI := 1 To nCols
            nSumFinal += aFinal[nI]
        Next
        aFinal[nCols] += (nListWidth - nSumFinal)
    Else
        // Nao cabe: escala proporcional mas respeita piso minimo
        nScale := nListWidth / nSumIdeal
        For nI := 1 To nCols
            aFinal[nI] := Max(aMin[nI], Round(aIdeal[nI] * nScale, 0))
        Next
        // Correcao final para somar exatamente nListWidth
        nSumFinal := 0
        For nI := 1 To nCols
            nSumFinal += aFinal[nI]
        Next
        aFinal[nCols] += (nListWidth - nSumFinal)
    EndIf

Return aFinal

//=====================================================================
// Static Function AnpReGrid
//=====================================================================
Static Function AnpReGrid(oDlg, oL, aArray)
    // Variaveis locais para ajuste dinamico das colunas
    Local nListWidth := 740
    Local aMinCols := {55,180,95,55,70,75,70,50,50,60}
    Local nSumMin := 0
    Local nI := 0
    Local aFinalCols := {}
    Local nVal := 0
    Local nExtra := 0

    oL:nAt := 1
    oL:SetArray(aArray)
    For nI := 1 To Len(aMinCols)
        nSumMin += aMinCols[nI]
    Next
    If nSumMin <= nListWidth
        nExtra := nListWidth - nSumMin
        For nI := 1 To Len(aMinCols)
            nVal := aMinCols[nI] + IIf(nI = 2, nExtra, 0)
            aAdd(aFinalCols, nVal)
        Next
    Else
        For nI := 1 To Len(aMinCols)
            nVal := Round(aMinCols[nI] * nListWidth / nSumMin, 0)
            aAdd(aFinalCols, nVal)
        Next
    EndIf
    oL:aColSizes := aFinalCols
    oL:bLine := {|| {;
        aArray[oL:nAt,1], ;
        AllTrim(aArray[oL:nAt,2]), ;
        AllTrim(aArray[oL:nAt,3]), ;
        Transform(aArray[oL:nAt,5],"@E 999,999.99"), ;
        Transform(aArray[oL:nAt,6],"@E 9,999,999.99"), ;
        Transform(aArray[oL:nAt,7],"@E 9,999,999.99"), ;
        Transform(aArray[oL:nAt,8],"@E 9,999,999.99"), ;
        Transform(aArray[oL:nAt,9],"@E 9,999,999.99"), ;
        Str(aArray[oL:nAt,10],10,2) + "%", ;
        aArray[oL:nAt,11]}}
    oL:bLDblClick := {|| AnpDet(aArray[oL:nAt,1], aArray[oL:nAt,2])}
    oL:Refresh()
    oDlg:SetText("Analise de Variacao de Precos - " + cValToChar(Len(aArray)))
    oDlg:Refresh()
Return

//=====================================================================
// Static Function AnpCarCompLT
// Carrega compradores fixos autorizados usando UsrRetName.
//=====================================================================
Static Function AnpCarCompLT(aCombo, aCods)
    Local aKeep := {"000031","000047","000057","000059","000071","000093"}
    Local cCod  := ""
    Local cNome := ""
    Local nK    := 0

    aCombo := {"** Todos os Compradores **"}
    aCods  := {"*"}

    For nK := 1 To Len(aKeep)
        cCod  := aKeep[nK]
        cNome := AllTrim(UsrRetName(cCod))
        If Empty(cNome)
            cNome := cCod
        EndIf
        aAdd(aCombo, cCod + " - " + cNome)
        aAdd(aCods,  cCod)
    Next
Return

//=====================================================================
// Static Function AnpCarCC
// Carrega centros de custo (CTT) para combo
//=====================================================================
Static Function AnpCarCC(aCombo, aCods)
    Local cAlias := GetNextAlias()
    Local cCod   := ""
    Local cNome  := ""
    Local cQuery := ""

    aCombo := {"** Todos os Centros **"}
    aCods  := {"*"}

    // Monta query para TopConnect - apenas centros de custo autorizados da Vortice
    cQuery := "SELECT CTT.CTT_CUSTO AS COD, CTT.CTT_DESC01 AS DESCR " + ;
                   " FROM " + RetSqlName("CTT") + " CTT " + ;
                   " WHERE CTT.D_E_L_E_T_ = ' ' " + ;
                   "   AND CTT.CTT_FILIAL = '" + xFilial("CTT") + "' " + ;
                   "   AND CTT.CTT_CUSTO IN ('5010201','5010202','5010203','5010204','5010205','5010206','5010207'," + ;
                   "        '6010201','6010202','6010203','6010204','6010205','6010206','6010207','6010208','6010209','6010210'," + ;
                   "        '6010212','6010213','6010214','7010201','7010202','8010201','8010202','9010201','9010202') " + ;
                   " ORDER BY CTT.CTT_CUSTO"

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        cCod  := AllTrim((cAlias)->COD)
        cNome := AllTrim((cAlias)->DESCR)
        If Empty(cNome)
            cNome := cCod
        EndIf
        aAdd(aCombo, cCod + " - " + cNome)
        aAdd(aCods,  cCod)
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())
Return

//=====================================================================
// Static Function AnpCarrega
// Carrega e calcula variacao de precos por item no periodo.
//=====================================================================
Static Function AnpCarrega(dDe, dAte, cItem, cCodUser, cDescr, cTipo, cCodCC)
    Local aArea   := GetArea()
    Local aRet    := {}
    Local aAgrup  := {}
    Local cAlias  := GetNextAlias()
    Local cQuery  := ""
    Local nPos    := 0
    Local nDif    := 0
    Local nDifPct := 0
    Local cSit    := ""
    Local nI      := 0
    Local lInc    := .T.
    Local cNome   := ""
    Local nVUnitLiq := 0
    Local nDescVlr  := 0
    Local nSolo1    := 0
    Local aUsrCache := {}   // Cache de nome do comprador: UsrRetName so no 1o acesso do codigo
    Local nPUsr     := 0

    aZANPDET := {}
    nZANPSO1 := 0

    cQuery := " SELECT SD1.D1_COD     AS COD,                                    "
    cQuery += "        SB1.B1_DESC    AS DESCR,                                  "
    cQuery += "        SD1.D1_DTDIGIT AS DT,                                     "
    cQuery += "        SD1.D1_QUANT   AS QTD,                                    "
    cQuery += "        SD1.D1_VUNIT   AS VUNIT,                                  "
    cQuery += "        SD1.D1_TOTAL   AS VTOT,                                   "
    cQuery += "        SD1.D1_PEDIDO  AS PEDIDO,                                 "
    cQuery += "        SD1.D1_DOC     AS DOC,                                    "
    cQuery += "        SD1.D1_ITEMPC  AS ITEMPC,                                 "
    cQuery += "        SD1.D1_FORNECE AS FORN,                                   "
    cQuery += "        SD1.D1_LOJA    AS LOJA,                                   "
    cQuery += "        SA2.A2_NOME    AS FORNNOME,                               "
    cQuery += "        SD1.D1_CC      AS CCUSTO,                                 "
    cQuery += "        CTT.CTT_DESC01 AS CCNOME,                                 "
    cQuery += "        SC7.C7_USER    AS USER_COMP,                              "
    cQuery += "        SC7.C7_COND    AS COND,                                   "
    cQuery += "        SC7.C7_PRECO   AS C7PRECO,                                "
    cQuery += "        SC7.C7_VLDESC  AS C7VLDESC,                               "
    cQuery += "        SC7.C7_QUANT   AS C7QUANT,                                "
    cQuery += "        SE4.E4_DESCRI  AS CONDDESC,                               "
    cQuery += "        SC7.C7_NUMSC   AS NUMSC                                   "
    cQuery += "   FROM " + RetSqlName("SD1") + " SD1 WITH (NOLOCK)              "
    cQuery += "   LEFT JOIN " + RetSqlName("SB1") + " SB1                        "
    cQuery += "          ON SB1.D_E_L_E_T_ = ' '                                 "
    cQuery += "         AND SB1.B1_FILIAL  = '" + xFilial("SB1") + "'            "
    cQuery += "         AND SB1.B1_COD     = SD1.D1_COD                          "
    cQuery += "   LEFT JOIN " + RetSqlName("SA2") + " SA2                        "
    cQuery += "          ON SA2.D_E_L_E_T_ = ' '                                 "
    cQuery += "         AND SA2.A2_FILIAL  = '" + xFilial("SA2") + "'            "
    cQuery += "         AND SA2.A2_COD     = SD1.D1_FORNECE                      "
    cQuery += "         AND SA2.A2_LOJA    = SD1.D1_LOJA                         "
    cQuery += "   LEFT JOIN " + RetSqlName("CTT") + " CTT                        "
    cQuery += "          ON CTT.D_E_L_E_T_ = ' '                                 "
    cQuery += "         AND CTT.CTT_FILIAL = '" + xFilial("CTT") + "'            "
    cQuery += "         AND CTT.CTT_CUSTO  = SD1.D1_CC                           "
    cQuery += "   LEFT JOIN " + RetSqlName("SC7") + " SC7                        "
    cQuery += "          ON SC7.D_E_L_E_T_ = ' '                                 "
    cQuery += "         AND SC7.C7_FILIAL  = '" + xFilial("SC7") + "'            "
    cQuery += "         AND SC7.C7_NUM     = SD1.D1_PEDIDO                       "
    cQuery += "         AND SC7.C7_ITEM    = SD1.D1_ITEMPC                       "
    cQuery += "         AND SC7.C7_CONAPRO NOT IN ('R','B')                      "
    cQuery += "   LEFT JOIN " + RetSqlName("SE4") + " SE4                        "
    cQuery += "          ON SE4.D_E_L_E_T_ = ' '                                 "
    cQuery += "         AND SE4.E4_FILIAL  = '" + xFilial("SE4") + "'            "
    cQuery += "         AND SE4.E4_CODIGO  = SC7.C7_COND                         "
    cQuery += "  WHERE SD1.D_E_L_E_T_ = ' '                                      "
    cQuery += "    AND SD1.D1_FILIAL  = '" + xFilial("SD1") + "'                 "
    cQuery += "    AND SD1.D1_DTDIGIT BETWEEN '" + DtoS(dDe) + "' AND '" + DtoS(dAte) + "' "
    cQuery += "    AND SD1.D1_TIPO    = 'N'                                       "
    cQuery += "    AND SD1.D1_QUANT   > 0                                         "
    cQuery += "    AND SD1.D1_VUNIT   > 0                                         "
    cQuery += "    AND (SD1.D1_COD LIKE 'MC%' OR SD1.D1_COD LIKE 'MD%' OR SD1.D1_COD LIKE 'AI%') "

    If !Empty(AllTrim(cItem))
        cQuery += "    AND SD1.D1_COD LIKE '" + AllTrim(cItem) + "%' "
    EndIf
    If !Empty(AllTrim(cDescr))
        cQuery += "    AND SB1.B1_DESC LIKE '%" + AllTrim(cDescr) + "%' "
    EndIf
    If !Empty(cCodUser) .And. cCodUser <> "*"
        // SC7.C7_FILIAL IS NULL = NF sem pedido (LEFT JOIN nao achou SC7); inclui essas NFs mesmo filtrando comprador
        cQuery += "    AND (SC7.C7_FILIAL IS NULL OR LTRIM(RTRIM(SC7.C7_USER)) = '" + AllTrim(cCodUser) + "') "
    EndIf

    If !Empty(AllTrim(cCodCC)) .And. cCodCC <> "*"
        cQuery += "    AND SD1.D1_CC = '" + AllTrim(cCodCC) + "' "
    EndIf

    cQuery += " ORDER BY SD1.D1_COD, SD1.D1_DTDIGIT, SD1.D1_PEDIDO "

    cQuery := ChangeQuery(cQuery)
    cQuery := StrTran(cQuery, "(NOLOCK)", "")              // normaliza (evita dica duplicada)
    cQuery := StrTran(cQuery, " WITH ", " WITH (NOLOCK) ") // reinjeta a dica que o ChangeQuery remove
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        // Desconto: usa C7_VLDESC (R$) do pedido quando disponivel, senao calcula implicito pela NF
        nDescVlr := IIf(!Empty((cAlias)->PEDIDO) .And. (cAlias)->C7VLDESC > 0, ;
            (cAlias)->C7VLDESC, ;
            IIf((cAlias)->VTOT > 0, Max(0, ((cAlias)->VUNIT * (cAlias)->QTD) - (cAlias)->VTOT), 0))
        // Preco unitario liquido: usa dados do pedido (C7_PRECO * QTD - C7_VLDESC) / C7_QUANT
        // quando existe pedido, senao usa VTOT/QTD ou VUNIT como fallback
        nVUnitLiq := IIf(!Empty((cAlias)->PEDIDO) .And. (cAlias)->C7PRECO > 0 .And. (cAlias)->C7QUANT > 0, ;
            Max(0, ((cAlias)->C7PRECO * (cAlias)->C7QUANT - (cAlias)->C7VLDESC) / (cAlias)->C7QUANT), ;
            IIf((cAlias)->VTOT > 0 .And. (cAlias)->QTD > 0, ;
                Min((cAlias)->VUNIT, (cAlias)->VTOT / (cAlias)->QTD), ;
                (cAlias)->VUNIT))

        // Cache: UsrRetName (consulta ao SR7) apenas na 1a vez de cada codigo de comprador
        nPUsr := aScan(aUsrCache, {|x| x[1] == (cAlias)->USER_COMP})
        If nPUsr == 0
            cNome := AllTrim(UsrRetName(AllTrim((cAlias)->USER_COMP)))
            If Empty(cNome)
                cNome := AllTrim((cAlias)->USER_COMP)
            EndIf
            If Empty(cNome)
                cNome := "-"
            EndIf
            aAdd(aUsrCache, {(cAlias)->USER_COMP, cNome})
        Else
            cNome := aUsrCache[nPUsr, 2]
        EndIf

        aAdd(aZANPDET, {;
            AllTrim((cAlias)->COD), ;
            AllTrim((cAlias)->DESCR), ;
            SToD((cAlias)->DT), ;
            (cAlias)->QTD, ;
            nVUnitLiq, ;
            (cAlias)->VTOT, ;
            AllTrim((cAlias)->PEDIDO), ;
            AllTrim((cAlias)->ITEMPC), ;
            IIf(Empty(AllTrim((cAlias)->FORN) + AllTrim((cAlias)->LOJA)), "-", AllTrim((cAlias)->FORN) + "/" + AllTrim((cAlias)->LOJA)), ;
            IIf(Empty(AllTrim((cAlias)->FORNNOME)), "-", AllTrim((cAlias)->FORNNOME)), ;
            IIf(Empty(AllTrim((cAlias)->CCUSTO)), "-", AllTrim((cAlias)->CCUSTO)), ;
            IIf(Empty(AllTrim((cAlias)->CCNOME)), "-", AllTrim((cAlias)->CCNOME)), ;
            AllTrim((cAlias)->USER_COMP), ;
            cNome, ;
            IIf(Empty(AllTrim((cAlias)->COND)) .And. Empty(AllTrim((cAlias)->CONDDESC)), "-", AllTrim((cAlias)->COND) + " - " + AllTrim((cAlias)->CONDDESC)), ;
            IIf(Empty(AllTrim((cAlias)->NUMSC)), "-", AllTrim((cAlias)->NUMSC)), ;
            nDescVlr, ;
            (cAlias)->C7PRECO, ;
            (cAlias)->C7VLDESC, ;
            (cAlias)->C7QUANT, ;
            AllTrim((cAlias)->DOC)})

        // Somente NFs com pedido de compra participam da comparacao de preco e quantidade
        // NFs sem pedido (devolucoes, ajustes, etc.) ficam apenas em aZANPDET (historico)
        If !Empty(AllTrim((cAlias)->PEDIDO))
            nPos := aScan(aAgrup, {|x| x[1] = AllTrim((cAlias)->COD)})
            If nPos = 0
                aAdd(aAgrup, {;
                    AllTrim((cAlias)->COD), ;
                    AllTrim((cAlias)->DESCR), ;
                    cNome, ;
                    (cAlias)->QTD, ;
                    nVUnitLiq, ;
                    nVUnitLiq, ;
                    SToD((cAlias)->DT), ;
                    SToD((cAlias)->DT), ;
                    1, ;
                    IIf(Empty(AllTrim((cAlias)->CCUSTO)), "-", AllTrim((cAlias)->CCUSTO)), ;
                    IIf(Empty(AllTrim((cAlias)->CCNOME)), "-", AllTrim((cAlias)->CCNOME)), ;
                    0})  // [9]=contador, [12]=penultimo
            Else
                aAgrup[nPos,4] += (cAlias)->QTD
                aAgrup[nPos,9]++  // incrementa contador
                If SToD((cAlias)->DT) >= aAgrup[nPos,8]
                    aAgrup[nPos,8]  := SToD((cAlias)->DT)
                    aAgrup[nPos,12] := aAgrup[nPos,6]  // penultimo = atual final
                    aAgrup[nPos,6]  := nVUnitLiq
                    If !Empty(cNome)
                        aAgrup[nPos,3] := cNome
                    EndIf
                EndIf
            EndIf
        EndIf

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    For nI := 1 To Len(aAgrup)
        // Exige ao menos 2 compras para ter comparacao de preco
        If aAgrup[nI,9] < 2
            nSolo1++
            Loop
        EndIf
        nDif    := aAgrup[nI,6] - aAgrup[nI,5]
        nDifPct := Round(IIf(aAgrup[nI,5] > 0, (nDif / aAgrup[nI,5]) * 100, 0), 1)

        Do Case
            Case nDifPct > 0
                cSit := "AUMENTOU"
            Case nDifPct < 0
                cSit := "DIMINUIU"
            Otherwise
                cSit := "MANTEVE"
        EndCase

        lInc := .T.
        Do Case
            Case cTipo = "So AUMENTOU" .And. cSit <> "AUMENTOU"
                lInc := .F.
            Case cTipo = "So DIMINUIU" .And. cSit <> "DIMINUIU"
                lInc := .F.
            Case cTipo = "So MANTEVE"  .And. cSit <> "MANTEVE"
                lInc := .F.
        EndCase

        If lInc
            aAdd(aRet, {;
                aAgrup[nI,1], ;
                aAgrup[nI,2], ;
                IIf(Empty(AllTrim(aAgrup[nI,10])) .Or. aAgrup[nI,10] = "-", "-", aAgrup[nI,10] + " - " + aAgrup[nI,11]), ;
                aAgrup[nI,3], ;
                aAgrup[nI,4], ;
                aAgrup[nI,5], ;
                aAgrup[nI,12], ;
                aAgrup[nI,6], ;
                nDif, ;
                nDifPct, ;
                cSit})
        EndIf
    Next nI

    aSort(aRet,,, {|x,y| Abs(x[9]) > Abs(y[9])})

    nZANPSO1 := nSolo1

    RestArea(aArea)
Return aRet

//=====================================================================
// Static Function AnpDet
// Historico: Data - SC - Pedido - Item PC - CC - Nome CC - Fornecedor - Cond.Pgto
//            Comprador - Quantidade - Valor Unitario - Desconto - Valor Total
//=====================================================================
Static Function AnpDet(cCodItem, cDescItem)
    Local oDlg2, oL2
    Local aHist := {}
    Local nI    := 0
    Local dIniHist := IIf(ValType(dZANPDE) = "D", dZANPDE, CtoD(""))
    Local dFimHist := IIf(ValType(dZANPATE) = "D", dZANPATE, Date())

    // Variaveis para ajuste dinamico das colunas do LISTBOX do historico
    Local nListWidth2 := 740
    Local aMinCols2 := {40,40,40,40,40,40,80,120,40,40,40,40,40,40}
    Local nSumMin2 := 0
    Local nJ := 0
    Local aFinalCols2 := {}
    Local nVal2 := 0
    Local nExtra2 := 0

    For nI := 1 To Len(aZANPDET)
        If aZANPDET[nI,1] = cCodItem .And. ;
           aZANPDET[nI,3] >= dIniHist .And. aZANPDET[nI,3] <= dFimHist .And. ;
           !Empty(AllTrim(aZANPDET[nI,7])) .And. ;
           aZANPDET[nI,4] > 0 .And. aZANPDET[nI,5] > 0 .And. aZANPDET[nI,6] > 0
            aAdd(aHist, aZANPDET[nI])
        EndIf
    Next nI

    If Len(aHist) = 0
        MsgAlert("Nenhum historico encontrado para o item " + cCodItem, "Atencao")
        Return
    EndIf

    aSort(aHist,,, {|x,y| x[3] < y[3]})

    DEFINE MSDIALOG oDlg2 TITLE "Historico do Item " + AllTrim(cCodItem) + " - " + AllTrim(cDescItem) ;
        + " (" + cValToChar(Len(aHist)) + " compras)" ;
        FROM 0,0 TO 650,1500 PIXEL

    @5,5  SAY "Item:"         SIZE 25,10 OF oDlg2 PIXEL
    @5,30 SAY AllTrim(cCodItem) + " - " + AllTrim(cDescItem) SIZE 500,10 OF oDlg2 PIXEL

    @20,5 SAY "Periodo:"      SIZE 35,10 OF oDlg2 PIXEL
    @20,40 SAY DtoC(dIniHist) + " a " + DtoC(dFimHist) SIZE 100,10 OF oDlg2 PIXEL
    @20,150 SAY cValToChar(Len(aHist)) + " compra(s)" SIZE 80,10 OF oDlg2 PIXEL
    @20,260  BUTTON "Imprimir Browse" SIZE 80,12 OF oDlg2 PIXEL ACTION AnpDetXls(aHist, cCodItem, cDescItem)

    @40,5 LISTBOX oL2 FIELDS HEADER ;
        "Data","Sol. Compra","Pedido Compra","Nota Fiscal","Item PC","Centro Custo","Nome Centro Custo","Fornecedor","Condicao Pagamento","Comprador","Quantidade","Valor Unitario","Desconto","Valor Total" ;
        SIZE 740,260 OF oDlg2 PIXEL

    oL2:SetArray(aHist)
    // Ajuste dinamico das larguras das colunas do historico para caber na largura do LISTBOX (740 px)
    nListWidth2 := 740
    aMinCols2 := {40,40,40,40,40,40,80,120,40,40,40,40,40,40}
    nSumMin2 := 0
    aFinalCols2 := {}
    nVal2 := 0
    nExtra2 := 0
    For nJ := 1 To Len(aMinCols2)
        nSumMin2 += aMinCols2[nJ]
    Next
    For nJ := 1 To Len(aMinCols2)
        nVal2 := Round(aMinCols2[nJ] * nListWidth2 / nSumMin2, 0)
        aAdd(aFinalCols2, nVal2)
    Next
    oL2:aColSizes := aFinalCols2
    oL2:bLine := {|| {;
        DtoC(aHist[oL2:nAt,3]), ;
        aHist[oL2:nAt,16], ;
        aHist[oL2:nAt,7], ;
        aHist[oL2:nAt,21], ;
        aHist[oL2:nAt,8], ;
        aHist[oL2:nAt,11], ;
        AllTrim(aHist[oL2:nAt,12]), ;
        AllTrim(aHist[oL2:nAt,9]) + " " + AllTrim(aHist[oL2:nAt,10]), ;
        AllTrim(aHist[oL2:nAt,15]), ;
        AllTrim(aHist[oL2:nAt,14]), ;
        Transform(aHist[oL2:nAt,4],"@E 999,999.99"), ;
        Transform(aHist[oL2:nAt,5],"@E 9,999,999.9999"), ;
        Transform(aHist[oL2:nAt,17],"@E 9,999,999.99"), ;
        Transform(aHist[oL2:nAt,6],"@E 9,999,999.99")}}

    ACTIVATE MSDIALOG oDlg2 CENTERED
Return

//=====================================================================
// Static Function AnpDetXls
// Exporta o historico do item para Excel/PDF/HTML usando TReport.
//=====================================================================
/*/{Protheus.doc} AnpDetXls
Exporta o historico de compras do item selecionado para Excel via TReport.
Inclui todas as colunas exibidas no browse de historico.
@type    Static Function
@version 12.1.33
@author  Suprimentos
@since   21/06/2026
@param aHist,   Array,  Array com os dados do historico do item
@param cCod,    String, Codigo do item
@param cDesc,   String, Descricao do item
/*/
Static Function AnpDetXls(aHist, cCod, cDesc)
    Local oReport
    Local oSec
    Local aArea := GetArea()

    If Len(aHist) == 0
        MsgAlert("Nenhum dado para exportar!", "Atencao")
        Return
    EndIf

    oReport := TReport():New("ZANLPRC" + AllTrim(cCod), ;
        "", ;
        "", {|oReport| AnpDetPrt(oReport, aHist)}, ;
        "")

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    oSec := TRSection():New(oReport, "Historico", {})
    TRCell():New(oSec, "DT",       "", "Data",               "@D",           12)
    TRCell():New(oSec, "SOL",      "", "Sol. Compra",       "@!",           12)
    TRCell():New(oSec, "PC",       "", "Pedido Compra",     "@!",           12)
    TRCell():New(oSec, "NF",       "", "Nota Fiscal",       "@!",           12)
    TRCell():New(oSec, "ITEMPC",   "", "Item PC",           "@!",            8)
    TRCell():New(oSec, "CC",       "", "Centro Custo",       "@!",           15)
    TRCell ():New(oSec, "CCNAME",   "", "Nome Centro Custo",  "@!",           25)
    TRCell():New(oSec, "FORN",     "", "Fornecedor",         "@!",           30)
    TRCell():New(oSec, "COND",     "", "Condicao Pagamento", "@!",           20)
    TRCell():New(oSec, "COMP",     "", "Comprador",          "@!",           20)
    TRCell():New(oSec, "QTD",      "", "Quantidade (PO)",    "@E 999,999.99", 12)
    TRCell():New(oSec, "VUNIT",    "", "Valor Unit. (PO)",   "@E 9,999,999.99", 14)
    TRCell():New(oSec, "DESCONTO", "", "Desconto (PO)",      "@E 999,999.99", 14)
    TRCell():New(oSec, "VTOT",     "", "Valor Total (PO)",   "@E 999,999,999.99", 16)

    oReport:PrintDialog()
    RestArea(aArea)
Return

//=====================================================================
// Static Function AnpDetPrt
// Callback do TReport: imprime linhas do historico do item.
//=====================================================================
/*/{Protheus.doc} AnpDetPrt
Callback de impressao do TReport para o historico do item.
@type    Static Function
@version 12.1.33
@author  Suprimentos
@since   21/06/2026
@param oReport, Object, Objeto TReport
@param aHist,   Array,  Dados do historico
/*/
Static Function AnpDetPrt(oReport, aHist)
    Local oSec := oReport:Section(1)
    Local nI := 0
    Local aArea := GetArea()

    oSec:Init()
    For nI := 1 To Len(aHist)
        oSec:Cell("DT"):SetValue(aHist[nI, 3])
        oSec:Cell("SOL"):SetValue(aHist[nI, 16])
        oSec:Cell("PC"):SetValue(aHist[nI, 7])
        oSec:Cell("NF"):SetValue(aHist[nI, 21])
        oSec:Cell("ITEMPC"):SetValue(aHist[nI, 8])
        oSec:Cell("CC"):SetValue(aHist[nI, 11])
        oSec:Cell("CCNAME"):SetValue(aHist[nI, 12])
        oSec:Cell("FORN"):SetValue(AllTrim(aHist[nI, 9]) + " " + AllTrim(aHist[nI, 10]))
        oSec:Cell("COND"):SetValue(aHist[nI, 15])
        oSec:Cell("COMP"):SetValue(aHist[nI, 14])
        oSec:Cell("QTD"):SetValue(IIf(!Empty(AllTrim(aHist[nI, 7])) .And. aHist[nI, 20] > 0, aHist[nI, 20], aHist[nI, 4]))
        oSec:Cell("VUNIT"):SetValue(aHist[nI, 5])
        oSec:Cell("DESCONTO"):SetValue(IIf(!Empty(AllTrim(aHist[nI, 7])) .And. aHist[nI, 19] > 0, aHist[nI, 19], aHist[nI, 17]))
        oSec:Cell("VTOT"):SetValue(IIf(!Empty(AllTrim(aHist[nI, 7])) .And. aHist[nI, 18] > 0 .And. aHist[nI, 20] > 0, (aHist[nI, 18] * aHist[nI, 20] - aHist[nI, 19]), aHist[nI, 6]))
        oSec:PrintLine()
        oReport:IncMeter()
    Next nI
    oSec:Finish()
    RestArea(aArea)
Return

//=====================================================================
// Static Function AnpInd
//=====================================================================
/*/{Protheus.doc} AnpInd
Janela de indicadores gerenciais da analise de variacao de precos:
totais por situacao, extremos de variacao (com item), prazo de pagamento,
economia acumulada/historica e estabilidade de precos.
@type    Static Function
@version 12.1.33
@author  Suprimentos
@since   24/09/2026
@param aArray, Array,  Linhas da analise (grid principal)
@param dDe,    Date,   Data inicial do periodo
@param dAte,   Date,   Data final do periodo
@param cItemFlt, Character, Filtro de item aplicado
@param cUserFlt, Character, Codigo do comprador filtrado (* = todos)
@param cCCFlt,   Character, Centro de custo filtrado (* = todos)
/*/
Static Function AnpInd(aArray, dDe, dAte, cItemFlt, cUserFlt, cCCFlt)
    Local oDlg3
    Local nI           := 0
    Local nTot         := Len(aArray)
    Local nAum         := 0
    Local nDim         := 0
    Local nMan         := 0
    Local nMaxAum      := 0
    Local nMaxDim      := 0
    Local cItemMaxAum  := ""
    Local cItemMaxDim  := ""
    Local cDescMaxAum  := ""
    Local cDescMaxDim  := ""
    Local nPrazo         := 0
    Local aEcon          := {}
    Local cEconAcumTxt   := ""
    Local cEconHistTxt   := ""
    Local oTipL01, oTipL02, oTipL03, oTipL04, oTipL05
    Local oTipL06, oTipL07, oTipL08, oTipL10
    Local oTipL11, oTipL12, oTipL13, oTipL14, oTipL15, oTipL16
    Local oValL01, oValL02, oValL03, oValL04, oValL05
    Local oValL06, oValL07, oValL08, oValL09, oValL10
    Local aEstab         := {}
    Local nEstCongelado  := 0
    Local nEstUltima     := 0
    Local nEstVariacao   := 0
    Local nTotEstab      := 0
    Local nPctCong       := 0
    Local nPctUlt        := 0
    Local nPctVar        := 0
    Local cEstCongTxt    := ""
    Local cEstUltTxt     := ""
    Local cEstVarTxt     := ""
    Local cTxtMaxAum     := ""
    Local cTxtMaxDim     := ""
    // --- calculo dos indicadores existentes ---
    For nI := 1 To nTot
        Do Case
            Case aArray[nI,11] = "AUMENTOU"
                nAum++
                If aArray[nI,10] > nMaxAum
                    nMaxAum     := aArray[nI,10]
                    cItemMaxAum := aArray[nI,1]
                    cDescMaxAum := aArray[nI,2]
                EndIf
            Case aArray[nI,11] = "DIMINUIU"
                nDim++
                If aArray[nI,10] < nMaxDim
                    nMaxDim     := aArray[nI,10]
                    cItemMaxDim := aArray[nI,1]
                    cDescMaxDim := aArray[nI,2]
                EndIf
            Otherwise
                nMan++
        EndCase
    Next nI

    nPrazo := AnpPrazMedPgto()

    // Calcula economia acumulada (penultima->ultima) e historica (primeira->ultima)
    aEcon        := AnpCalcEcon(dDe, dAte, cItemFlt, cUserFlt, cCCFlt)
    cEconAcumTxt := IIf(aEcon[3] > 0, ;
        IIf(aEcon[1] >= 0, "+", "") + AllTrim(Str(aEcon[1],8,2)) + "% / " + ;
        IIf(aEcon[1] >= 0, "+R$ ", "-R$ ") + AllTrim(Transform(Abs(aEcon[2]),"@E 9,999,999.99")), ;
        "Sem dados suficientes")
    cEconHistTxt := IIf(aEcon[6] > 0, ;
        IIf(aEcon[4] >= 0, "+", "") + AllTrim(Str(aEcon[4],8,2)) + "% / " + ;
        IIf(aEcon[4] >= 0, "+R$ ", "-R$ ") + AllTrim(Transform(Abs(aEcon[5]),"@E 9,999,999.99")), ;
        "Sem dados suficientes")

    // Calcula indicadores de estabilidade de preco
    aEstab       := AnpCalcEstab(dDe, dAte, cItemFlt, cUserFlt, cCCFlt)
    nEstCongelado := aEstab[1]
    nEstUltima    := aEstab[2]
    nEstVariacao  := aEstab[3]
    nTotEstab     := aEstab[5]

    nPctCong := IIf(nTotEstab > 0, Round(nEstCongelado / nTotEstab * 100, 2), 0)
    nPctUlt  := IIf(nTotEstab > 0, Round(nEstUltima    / nTotEstab * 100, 2), 0)
    nPctVar  := IIf(nTotEstab > 0, Round(nEstVariacao  / nTotEstab * 100, 2), 0)

    // Sincroniza "Sem alteracao" com a soma dos estaveis (SQL): congelado + ultima
    // Garante fechamento: nAum + nDim + nMan = nTot
    nMan := nEstCongelado + nEstUltima
    nAum := Max(0, nTot - nDim - nMan)

    cEstCongTxt := Transform(nEstCongelado, "@E 999,999") + " (" + Transform(nPctCong, "@E 999.99") + "%)"
    cEstUltTxt  := Transform(nEstUltima,    "@E 999,999") + " (" + Transform(nPctUlt,  "@E 999.99") + "%)"
    cEstVarTxt  := Transform(nEstVariacao,  "@E 999,999") + " (" + Transform(nPctVar,  "@E 999.99") + "%)"

    cTxtMaxAum := Transform(nMaxAum, "@E 9,999.99") + "%"
    If !Empty(cItemMaxAum)
        cTxtMaxAum += "  -  " + cItemMaxAum
    EndIf
    cTxtMaxDim := Transform(nMaxDim, "@E 9,999.99") + "%"
    If !Empty(cItemMaxDim)
        cTxtMaxDim += "  -  " + cItemMaxDim
    EndIf

    DEFINE MSDIALOG oDlg3 TITLE "Indicadores Gerenciais" FROM 0,0 TO 640,530 PIXEL

    @10, 10 SAY oTipL01 PROMPT "Total de itens analisados:"       SIZE 150,10 OF oDlg3 PIXEL
    @10,165 SAY oValL01 PROMPT Transform(nTot,    "@E 999,999")   SIZE 290,10 OF oDlg3 PIXEL
    oTipL01:cToolTip := "Quantidade total de itens que possuem historico de compras " + ;
        "dentro do periodo selecionado e que foram considerados na analise comparativa de precos."

    @30, 10 SAY oTipL02 PROMPT "Itens com AUMENTO de preco:"      SIZE 150,10 OF oDlg3 PIXEL
    @30,165 SAY oValL02 PROMPT Transform(nAum,    "@E 999,999")   SIZE 290,10 OF oDlg3 PIXEL
    oTipL02:cToolTip := "Quantidade de itens cuja ultima compra apresentou valor superior " + ;
        "ao preco de referencia utilizado na comparacao."

    @50, 10 SAY oTipL03 PROMPT "Itens com REDUCAO de preco:"      SIZE 150,10 OF oDlg3 PIXEL
    @50,165 SAY oValL03 PROMPT Transform(nDim,    "@E 999,999")   SIZE 290,10 OF oDlg3 PIXEL
    oTipL03:cToolTip := "Quantidade de itens cuja ultima compra apresentou valor inferior " + ;
        "ao preco de referencia utilizado na comparacao."

    @70, 10 SAY oTipL04 PROMPT "Itens SEM alteracao:"             SIZE 150,10 OF oDlg3 PIXEL
    @70,165 SAY oValL04 PROMPT Transform(nMan,    "@E 999,999")   SIZE 290,10 OF oDlg3 PIXEL
    oTipL04:cToolTip := "Quantidade de itens que mantiveram o mesmo preco na comparacao realizada."

    @90, 10 SAY oTipL15 PROMPT "Itens sem comparacao (1 compra):" SIZE 150,10 OF oDlg3 PIXEL
    @90,165 SAY oValL10 PROMPT Transform(nZANPSO1, "@E 999,999")  SIZE 290,10 OF oDlg3 PIXEL
    oTipL15:cToolTip := "Itens comprados apenas uma vez no periodo: " + ;
        "nao ha preco anterior para comparar, por isso nao aparecem na grade principal " + ;
        "nem nos totais de aumento/reducao."

    @110, 10 SAY oTipL05 PROMPT "Maior aumento encontrado (%):"   SIZE 150,10 OF oDlg3 PIXEL
    @110,165 SAY oValL05 PROMPT cTxtMaxAum                         SIZE 290,10 OF oDlg3 PIXEL
    oTipL05:cToolTip := "Maior variacao percentual positiva entre todos os itens analisados." + Chr(13) + ;
        "Item: " + cItemMaxAum + " - " + cDescMaxAum + Chr(13) + ;
        "Formula: ((Preco Atual - Preco Anterior) / Preco Anterior) x 100" + Chr(13) + ;
        "Atencao: valores extremos podem indicar erro de lancamento ou troca de unidade de medida."

    @130, 10 SAY oTipL06 PROMPT "Maior reducao encontrada (%):"   SIZE 150,10 OF oDlg3 PIXEL
    @130,165 SAY oValL06 PROMPT cTxtMaxDim                         SIZE 290,10 OF oDlg3 PIXEL
    oTipL06:cToolTip := "Maior variacao percentual negativa entre todos os itens analisados." + Chr(13) + ;
        "Item: " + cItemMaxDim + " - " + cDescMaxDim + Chr(13) + ;
        "Formula: ((Preco Atual - Preco Anterior) / Preco Anterior) x 100" + Chr(13) + ;
        "Atencao: valores extremos podem indicar erro de lancamento ou troca de unidade de medida."

    @150, 10 SAY oTipL10 PROMPT "Prazo mais frequente:"           SIZE 150,10 OF oDlg3 PIXEL
    @150,165 SAY oValL07 PROMPT Transform(nPrazo, "@E 999") + " dias" SIZE 290,10 OF oDlg3 PIXEL
    oTipL10:cToolTip := "Este numero representa o prazo de pagamento que a empresa mais utiliza no dia a dia das suas compras."

    @170, 10 SAY oTipL07 PROMPT "Economia acumulada (periodo):"   SIZE 150,10 OF oDlg3 PIXEL
    @170,165 SAY oValL08 PROMPT cEconAcumTxt                       SIZE 290,10 OF oDlg3 PIXEL
    oTipL07:cToolTip := "Economia media gerada pela variacao de preco entre a penultima e a ultima compra de cada item." + Chr(13) + ;
        "Valor positivo = reducao de preco (ganho). Valor negativo = aumento de preco (perda)." + Chr(13) + ;
        "Formula: (Vunit_penultimo - Vunit_ultimo) / Vunit_penultimo x 100" + Chr(13) + ;
        "Itens com apenas uma compra no periodo sao ignorados."

    @190, 10 SAY oTipL08 PROMPT "Economia historica (acumulada):" SIZE 150,10 OF oDlg3 PIXEL
    @190,165 SAY oValL09 PROMPT cEconHistTxt                       SIZE 290,10 OF oDlg3 PIXEL
    oTipL08:cToolTip := "Economia acumulada desde a primeira ate a ultima compra de cada item no periodo." + Chr(13) + ;
        "Valor positivo = reducao de preco (ganho). Valor negativo = aumento de preco (perda)." + Chr(13) + ;
        "Formula: (Vunit_primeiro - Vunit_ultimo) / Vunit_primeiro x 100" + Chr(13) + ;
        "Itens com apenas uma compra no periodo sao ignorados."

    @210, 10 SAY oTipL16 PROMPT "(+) ganho, preco caiu   |   (-) perda, preco subiu" ;
        SIZE 300,10 OF oDlg3 PIXEL COLOR RGB(80,80,80)
    oTipL16:cToolTip := "Leitura rapida dos indicadores de economia: " + Chr(13) + ;
        "se o valor estiver com sinal positivo, o preco medio caiu em relacao a compra anterior (ganho). " + ;
        "Se estiver negativo, o preco subiu (perda)."

    // --- Secao: Estabilidade de Precos ---
    @230,10 SAY oTipL11 PROMPT "--- Estabilidade de Precos ---"   SIZE 425,10 OF oDlg3 PIXEL
    oTipL11:cToolTip := "Ranking de estabilidade de preco dos itens no periodo." + Chr(13) + ;
        "Considera apenas itens com ao menos 2 compras (pedido de compra) no periodo."

    @250, 10 SAY oTipL12 PROMPT "Estaveis desde sempre:"          SIZE 150,10 OF oDlg3 PIXEL
    @250,165 SAY cEstCongTxt                                       SIZE 290,10 OF oDlg3 PIXEL
    oTipL12:cToolTip := "Itens cujo preco nunca variou no periodo: VMAX_HIST = VMIN_HIST" + Chr(13) + ;
        "e o preco da primeira compra igual ao da ultima." + Chr(13) + ;
        "Sinal de estabilidade total de fornecimento e negociacao."

    @270, 10 SAY oTipL13 PROMPT "Estaveis apenas na ultima:"      SIZE 150,10 OF oDlg3 PIXEL
    @270,165 SAY cEstUltTxt                                        SIZE 290,10 OF oDlg3 PIXEL
    oTipL13:cToolTip := "Itens onde a penultima e a ultima compra tiveram o mesmo preco," + Chr(13) + ;
        "mas houve variacao em algum momento anterior do periodo." + Chr(13) + ;
        "Indica estabilizacao recente de preco."

    @290, 10 SAY oTipL14 PROMPT "Em variacao ativa:"              SIZE 150,10 OF oDlg3 PIXEL
    @290,165 SAY cEstVarTxt                                        SIZE 290,10 OF oDlg3 PIXEL
    oTipL14:cToolTip := "Itens onde a ultima compra teve preco diferente da penultima." + Chr(13) + ;
        "Esses itens precisam de atencao para negociacao ou revisao de fornecedor."

    ACTIVATE MSDIALOG oDlg3 CENTERED
Return

//=====================================================================
// Static Function AnpExcel
// Exporta para Excel: Analise, Historico, Indicadores
//=====================================================================
/*/{Protheus.doc} AnpPrazMedPgto
Identifica o prazo de pagamento mais utilizado (moda) com base nas condicoes
de pagamento (SE4) registradas nas NFs do historico (aZANPDET).
Contabiliza a frequencia de cada condicao e retorna os dias da mais recorrente.
@return Numeric - dias da condicao de pagamento mais frequente
/*/
Static Function AnpPrazMedPgto()
    Local cAlias     := ""
    Local aArea     := GetArea()
    Local nI        := 0
    Local nJ        := 0
    Local nSep      := 0
    Local cCond     := ""
    Local nPos      := 0
    Local aContagem := {}  // {cCond, nCount}
    Local cModaCond := ""
    Local nModaCnt  := 0
    Local cE4Cond   := ""
    Local aParc     := {}
    Local cQrySE4   := ""
    Local nSomaPrc  := 0
    Local cTok      := ""
    Local nResult   := 0

    // Conta a frequencia de cada condicao de pagamento nas NFs do historico
    // Equivalente a: SELECT C7_COND, COUNT(*) GROUP BY C7_COND ORDER BY COUNT(*) DESC TOP 1
    For nI := 1 To Len(aZANPDET)
        If aZANPDET[nI,15] = "-" .Or. aZANPDET[nI,6] <= 0
            Loop
        EndIf
        nSep  := At(" - ", aZANPDET[nI,15])
        cCond := IIf(nSep > 1, AllTrim(Left(aZANPDET[nI,15], nSep - 1)), "")
        If Empty(cCond)
            Loop
        EndIf
        nPos := aScan(aContagem, {|x| x[1] = cCond})
        If nPos = 0
            aAdd(aContagem, {cCond, 1})
        Else
            aContagem[nPos,2]++
        EndIf
    Next nI

    If Len(aContagem) = 0
        RestArea(aArea)
        Return 0
    EndIf

    // Identifica a condicao mais frequente (TOP 1 ORDER BY COUNT(*) DESC)
    For nI := 1 To Len(aContagem)
        If aContagem[nI,2] > nModaCnt
            nModaCnt  := aContagem[nI,2]
            cModaCond := aContagem[nI,1]
        EndIf
    Next nI

    If Empty(cModaCond)
        RestArea(aArea)
        Return 0
    EndIf

    // Busca E4_COND da condicao mais frequente
    // Usa RetSqlName() + D_E_L_E_T_ explicito (padrao mandatorio)
    cQrySE4 := " SELECT E4_COND " + ;
        "   FROM " + RetSqlName("SE4") + " SE4 " + ;
        "  WHERE SE4.D_E_L_E_T_ = ' ' " + ;
        "    AND SE4.E4_FILIAL  = '" + xFilial("SE4") + "' " + ;
        "    AND SE4.E4_CODIGO  = '" + cModaCond + "' "
    cAlias := GetNextAlias()
    DbUseArea(.T., "TOPCONN", TcGenQry(,, ChangeQuery(cQrySE4)), cAlias, .F., .T.)

    If !(cAlias)->(Eof())
        cE4Cond := AllTrim((cAlias)->E4_COND)
    EndIf
    (cAlias)->(DbCloseArea())

    // Decodifica E4_COND para dias (ex: "030" -> 30 | "030/060/090" -> media das parcelas)
    aParc    := {}
    nSomaPrc := 0
    Do While !Empty(cE4Cond)
        nSep := At("/", cE4Cond)
            If nSep > 0
                cTok    := AllTrim(Left(cE4Cond, nSep - 1))
                cE4Cond := SubStr(cE4Cond, nSep + 1)
            Else
                cTok    := AllTrim(cE4Cond)
                cE4Cond := ""
            EndIf
            If Val(cTok) >= 0
                aAdd(aParc, Val(cTok))
            EndIf
        EndDo
    For nJ := 1 To Len(aParc)
        nSomaPrc += aParc[nJ]
    Next nJ
    nResult := IIf(Len(aParc) > 0, Round(nSomaPrc / Len(aParc), 0), 0)
    RestArea(aArea)
Return nResult

//=====================================================================
// Static Function AnpExcel
// Exporta Analise, Historico e Indicadores via TReport (Excel/PDF/HTML)
// Padr?o adaptado de ZLOGCOL.prw
//=====================================================================
Static Function AnpExcel(aArray)
    Local oReport, oSecAna, oSecHist, oSecInd

    If Len(aArray) = 0
        MsgAlert("Nada para exportar!", "Atencao")
        Return
    EndIf

    oReport := TReport():New("ZANALPRC", "Analise de Variacao de Precos", "", ;
        {|oReport| ImprimirZANAL(oReport, aArray, aZANPDET)}, ;
        "Analise de variacao de precos - Analise, Historico e Indicadores")

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    // Secao Analise
    oSecAna := TRSection():New(oReport, "Analise", {})
    TRCell():New(oSecAna, "COD",   "", "Codigo",               "@!", 12)
    TRCell():New(oSecAna, "DESCR", "", "Descricao do Item",    "@!", 40)
    TRCell():New(oSecAna, "CC",    "", "Centro Custo",         "@!", 18)
    TRCell():New(oSecAna, "COMP",  "", "Comprador",            "@!", 20)
    TRCell():New(oSecAna, "QTD",   "", "Qtd.Total",            "@E 999,999.99", 10)
    TRCell():New(oSecAna, "VINI",  "", "Primeiro Valor Unit�rio", "@E 9,999,999.99", 23)
    TRCell():New(oSecAna, "VPEN",  "", "Valor Unit�rio Anterior",  "@E 9,999,999.99", 23)
    TRCell():New(oSecAna, "VFIN",  "", "Valor Unit�rio Atual",     "@E 9,999,999.99", 20)
    TRCell():New(oSecAna, "DIFR",  "", "Diferenca R$",         "@E 999,999,999.99", 14)
    TRCell():New(oSecAna, "VAR",   "", "Variacao %",           "@E 9,999.99", 12)
    TRCell():New(oSecAna, "SIT",   "", "Situacao",             "@!", 12)

    // Secao Historico
    oSecHist := TRSection():New(oReport, "Historico", {})
    TRCell():New(oSecHist, "DT",      "", "Data",               "@D", 10)
    TRCell():New(oSecHist, "SOL",     "", "Sol. Compra",        "@!", 12)
    TRCell():New(oSecHist, "PC",      "", "Pedido Compra",      "@!", 10)
    TRCell():New(oSecHist, "ITEMPC",  "", "Item PC",            "@!", 8)
    TRCell():New(oSecHist, "CC2",     "", "Centro Custo",       "@!", 15)
    TRCell():New(oSecHist, "CCNAME",  "", "Nome Centro Custo",  "@!", 25)
    TRCell():New(oSecHist, "FORN",    "", "Fornecedor",         "@!", 30)
    TRCell():New(oSecHist, "COND",    "", "Condicao Pagamento", "@!", 20)
    TRCell():New(oSecHist, "COMP2",   "", "Comprador",          "@!", 20)
    TRCell():New(oSecHist, "QTD2",    "", "Quantidade (PO)",    "@E 999,999.99", 10)
    TRCell():New(oSecHist, "VUNIT",   "", "Valor Unit. (PO)",   "@E 9,999,999.99", 12)
    TRCell():New(oSecHist, "DESCONTO","", "Desconto (PO)",      "@E 999,999,999.99", 12)
    TRCell():New(oSecHist, "VTOT",    "", "Valor Total (PO)",   "@E 999,999,999.99", 14)

    // Secao Indicadores
    oSecInd := TRSection():New(oReport, "Indicadores", {})
    TRCell():New(oSecInd, "IND", "", "Indicador", "@!", 40)
    TRCell():New(oSecInd, "VAL", "", "Valor",      "@!", 20)

    oReport:PrintDialog()
Return

/*/{Protheus.doc} ImprimirZANAL
Callback do TReport: imprime Analise, Historico e Indicadores
@type    Static Function
@version 12.1.33
@author  Suprimentos
@since   03/06/2026
@param oReport, Object, Objeto TReport
@param aArray, Array, Analise (array retornado pela busca)
@param aZANPDET, Array, Historico (detalhes das notas)
/*/
Static Function ImprimirZANAL(oReport, aArray, aZANPDET)
    Local oSecAna := oReport:Section(1)
    Local oSecHist := oReport:Section(2)
    Local oSecInd  := oReport:Section(3)
    Local i          := 0
    Local nTot       := Len(aArray)
    Local nAum       := 0
    Local nDim       := 0
    Local nMan       := 0
    Local nMaxAum    := 0
    Local nMaxDim    := 0
    // Contadores de estabilidade de preco para secao Excel
    Local nEstXCong  := 0
    Local nEstXUlt   := 0
    Local nVMaxXH    := 0
    Local nVMinXH    := 0
    // Variaveis para Economia Acumulada e Historica (calculados a partir de aZANPDET)
    Local cCodEconX      := ""
    Local nVPrimX        := 0
    Local nVPenX         := 0
    Local nVUltX         := 0
    Local nCntEconX      := 0
    Local nSumAcumX      := 0
    Local nEconAcumRSX   := 0
    Local nCntAcumX      := 0
    Local nSumHistX      := 0
    Local nEconHistRSX   := 0
    Local nCntHistX      := 0
    Local nEconAcumPctX  := 0
    Local nEconHistPctX  := 0
    Local cEconAcumTxtX  := ""
    Local cEconHistTxtX  := ""

    oReport:SetMeter(0)

    // Imprime Analise
    oSecAna:Init()
    For i := 1 To Len(aArray)
        oSecAna:Cell("COD"):SetValue(aArray[i,1])
        oSecAna:Cell("DESCR"):SetValue(aArray[i,2])
        oSecAna:Cell("CC"):SetValue(aArray[i,3])
        oSecAna:Cell("COMP"):SetValue(aArray[i,4])
        oSecAna:Cell("QTD"):SetValue(aArray[i,5])
        oSecAna:Cell("VINI"):SetValue(aArray[i,6])
        oSecAna:Cell("VPEN"):SetValue(aArray[i,7])
        oSecAna:Cell("VFIN"):SetValue(aArray[i,8])
        oSecAna:Cell("DIFR"):SetValue(aArray[i,9])
        oSecAna:Cell("VAR"):SetValue(aArray[i,10])
        oSecAna:Cell("SIT"):SetValue(aArray[i,11])
        oSecAna:PrintLine()
        oReport:IncMeter()
    Next
    oSecAna:Finish()

    // Calcula indicadores a partir de aArray
    For i := 1 To nTot
        Do Case
            Case aArray[i,11] = "AUMENTOU"
                nAum++
                If aArray[i,10] > nMaxAum
                    nMaxAum := aArray[i,10]
                EndIf
            Case aArray[i,11] = "DIMINUIU"
                nDim++
                If aArray[i,10] < nMaxDim
                    nMaxDim := aArray[i,10]
                EndIf
            Otherwise
                nMan++
        EndCase

        // Indicador 'Economia potencial' removido: nao acumula mais Diferenca R$ x Quantidade
    Next

    // --- Economia Acumulada e Historica (calculado a partir de aZANPDET, ordenado por COD/DATA ASC) ---
    // Itera rastreando primeiro, penultimo e ultimo preco por item
    // Tambem rastreia VMAX/VMIN por item para classificar estabilidade de preco
    nVMaxXH := 0
    nVMinXH := 0
    For i := 1 To Len(aZANPDET)
        If aZANPDET[i,5] <= 0 .Or. aZANPDET[i,4] <= 0 .Or. Empty(AllTrim(aZANPDET[i,7]))
            Loop
        EndIf
        If aZANPDET[i,1] <> cCodEconX
            // Consolida item anterior se tiver ao menos 2 compras
            If !Empty(cCodEconX) .And. nCntEconX >= 2
                If nVPenX > 0 .And. nVUltX > 0
                    nSumAcumX    += (nVPenX - nVUltX) / nVPenX * 100
                    nEconAcumRSX += (nVPenX - nVUltX)
                    nCntAcumX++
                EndIf
                If nVPrimX > 0 .And. nVUltX > 0
                    nSumHistX    += (nVPrimX - nVUltX) / nVPrimX * 100
                    nEconHistRSX += (nVPrimX - nVUltX)
                    nCntHistX++
                EndIf
                // Classifica estabilidade do item anterior
                If Round(nVMaxXH, 4) = Round(nVMinXH, 4) .And. ;
                   Round(nVPrimX, 4) = Round(nVUltX, 4)
                    nEstXCong++
                ElseIf Round(nVUltX, 4) = Round(nVPenX, 4)
                    nEstXUlt++
                EndIf
            EndIf
            cCodEconX := aZANPDET[i,1]
            nVPrimX   := aZANPDET[i,5]
            nVPenX    := 0
            nVUltX    := aZANPDET[i,5]
            nCntEconX := 1
            nVMaxXH   := aZANPDET[i,5]
            nVMinXH   := aZANPDET[i,5]
        Else
            nVPenX    := nVUltX          // penultimo = antigo ultimo
            nVUltX    := aZANPDET[i,5]  // ultimo = atual
            nCntEconX++
            nVMaxXH   := Max(nVMaxXH, aZANPDET[i,5])
            nVMinXH   := Min(nVMinXH, aZANPDET[i,5])
        EndIf
    Next i
    // Consolida ultimo item
    If !Empty(cCodEconX) .And. nCntEconX >= 2
        If nVPenX > 0 .And. nVUltX > 0
            nSumAcumX    += (nVPenX - nVUltX) / nVPenX * 100
            nEconAcumRSX += (nVPenX - nVUltX)
            nCntAcumX++
        EndIf
        If nVPrimX > 0 .And. nVUltX > 0
            nSumHistX    += (nVPrimX - nVUltX) / nVPrimX * 100
            nEconHistRSX += (nVPrimX - nVUltX)
            nCntHistX++
        EndIf
        // Classifica estabilidade do ultimo item
        If Round(nVMaxXH, 4) = Round(nVMinXH, 4) .And. ;
           Round(nVPrimX, 4) = Round(nVUltX, 4)
            nEstXCong++
        ElseIf Round(nVUltX, 4) = Round(nVPenX, 4)
            nEstXUlt++
        EndIf
    EndIf
    // Sincroniza nMan (Sem alteracao) com a soma dos estaveis identificados no historico
    nMan := nEstXCong + nEstXUlt
    nAum := Max(0, nTot - nDim - nMan)
    nEconAcumPctX := IIf(nCntAcumX > 0, Round(nSumAcumX / nCntAcumX, 2), 0)
    nEconHistPctX := IIf(nCntHistX > 0, Round(nSumHistX / nCntHistX, 2), 0)
    cEconAcumTxtX := IIf(nCntAcumX > 0, ;
        IIf(nEconAcumPctX >= 0, "+", "") + AllTrim(Str(nEconAcumPctX,8,2)) + "% / " + ;
        IIf(nEconAcumPctX >= 0, "+R$ ", "-R$ ") + AllTrim(Transform(Abs(nEconAcumRSX),"@E 9,999,999.99")), ;
        "Sem dados suficientes")
    cEconHistTxtX := IIf(nCntHistX > 0, ;
        IIf(nEconHistPctX >= 0, "+", "") + AllTrim(Str(nEconHistPctX,8,2)) + "% / " + ;
        IIf(nEconHistPctX >= 0, "+R$ ", "-R$ ") + AllTrim(Transform(Abs(nEconHistRSX),"@E 9,999,999.99")), ;
        "Sem dados suficientes")

    // Imprime Historico
    oSecHist:Init()
    For i := 1 To Len(aZANPDET)
        oSecHist:Cell("DT"):SetValue(aZANPDET[i,3])
        oSecHist:Cell("SOL"):SetValue(aZANPDET[i,16])
        oSecHist:Cell("PC"):SetValue(aZANPDET[i,7])
        oSecHist:Cell("ITEMPC"):SetValue(aZANPDET[i,8])
        oSecHist:Cell("CC2"):SetValue(aZANPDET[i,11])
        oSecHist:Cell("CCNAME"):SetValue(aZANPDET[i,12])
        oSecHist:Cell("FORN"):SetValue(aZANPDET[i,9] + " " + aZANPDET[i,10])
        oSecHist:Cell("COND"):SetValue(aZANPDET[i,15])
        oSecHist:Cell("COMP2"):SetValue(aZANPDET[i,14])
        // Usa preco liquido (nVUnitLiq) para consistencia com painel de analise
        oSecHist:Cell("QTD2"):SetValue(IIf(!Empty(AllTrim(aZANPDET[i,7])) .And. aZANPDET[i,20] > 0, aZANPDET[i,20], aZANPDET[i,4]))
        oSecHist:Cell("VUNIT"):SetValue(aZANPDET[i,5])
        oSecHist:Cell("DESCONTO"):SetValue(IIf(!Empty(AllTrim(aZANPDET[i,7])) .And. aZANPDET[i,19] > 0, aZANPDET[i,19], aZANPDET[i,17]))
        oSecHist:Cell("VTOT"):SetValue(IIf(!Empty(AllTrim(aZANPDET[i,7])) .And. aZANPDET[i,18] > 0 .And. aZANPDET[i,20] > 0, (aZANPDET[i,18] * aZANPDET[i,20] - aZANPDET[i,19]), aZANPDET[i,6]))
        oSecHist:PrintLine()
        oReport:IncMeter()
    Next
    oSecHist:Finish()

    // Imprime Indicadores ? todos os valores passados como string para evitar overflow na celula "@!"
    oSecInd:Init()
    oSecInd:Cell("IND"):SetValue("Total de itens analisados")
    oSecInd:Cell("VAL"):SetValue(AllTrim(Str(nTot, 10, 0)))
    oSecInd:PrintLine()
    oSecInd:Cell("IND"):SetValue("Itens com aumento")
    oSecInd:Cell("VAL"):SetValue(AllTrim(Str(nAum, 10, 0)))
    oSecInd:PrintLine()
    oSecInd:Cell("IND"):SetValue("Itens com reducao")
    oSecInd:Cell("VAL"):SetValue(AllTrim(Str(nDim, 10, 0)))
    oSecInd:PrintLine()
    oSecInd:Cell("IND"):SetValue("Itens sem alteracao")
    oSecInd:Cell("VAL"):SetValue(AllTrim(Str(nMan, 10, 0)))
    oSecInd:PrintLine()
    oSecInd:Cell("IND"):SetValue("Maior aumento (%)")
    oSecInd:Cell("VAL"):SetValue(AllTrim(Str(nMaxAum, 10, 2)) + "%")
    oSecInd:PrintLine()
    oSecInd:Cell("IND"):SetValue("Maior reducao (%)")
    oSecInd:Cell("VAL"):SetValue(AllTrim(Str(nMaxDim, 10, 2)) + "%")
    oSecInd:PrintLine()
    // Indicadores de economia removidos a pedido do usuario
    oSecInd:Cell("IND"):SetValue("Prazo de pagamento mais frequente")
    oSecInd:Cell("VAL"):SetValue(AllTrim(Str(AnpPrazMedPgto(), 10, 0)) + " dias")
    oSecInd:PrintLine()
    oSecInd:Cell("IND"):SetValue("Economia acumulada (periodo)")
    oSecInd:Cell("VAL"):SetValue(cEconAcumTxtX)
    oSecInd:PrintLine()
    oSecInd:Cell("IND"):SetValue("Economia historica (acumulada)")
    oSecInd:Cell("VAL"):SetValue(cEconHistTxtX)
    oSecInd:PrintLine()
    oSecInd:Finish()

Return

//=====================================================================
// Static Function AnpCalcEcon
// Economia Acumulada (penultima->ultima) e Historica (primeira->ultima)
// via Embedded SQL com ROW_NUMBER() OVER PARTITION BY D1_COD.
//=====================================================================
/*/{Protheus.doc} AnpCalcEcon
Calcula dois indicadores de economia de compras usando SQL com funcoes
de janela (ROW_NUMBER() OVER PARTITION BY):
- Economia Acumulada : diferenca entre a penultima e a ultima compra do
  periodo (Vunit_penultimo - Vunit_ultimo).
- Economia Historica : diferenca entre a primeira e a ultima compra do
  periodo (Vunit_primeiro - Vunit_ultimo).
Itens com apenas uma compra no periodo sao ignorados (COUNT >= 2).
Valores negativos indicam aumento de preco (impacto negativo).
@type    Static Function
@version 3.0
@author  Copilot / Suprimentos
@since   08/06/2026
@param dDe,      Date,      Data inicial do periodo
@param dAte,     Date,      Data final do periodo
@param cItem,    Character, Codigo do item (vazio = todos)
@param cCodUser, Character, Codigo do comprador (* = todos)
@param cCodCC,   Character, Codigo do centro de custo (* = todos)
@return Array - {nEconAcumPct, nEconAcumRS, nCntAcum, nEconHistPct, nEconHistRS, nCntHist}
/*/
Static Function AnpCalcEcon(dDe, dAte, cItem, cCodUser, cCodCC)
    Local aArea        := GetArea()
    Local cAlias       := GetNextAlias()
    Local cQuery       := ""
    Local nEconAcumPct := 0
    Local nEconAcumRS  := 0
    Local nCntAcum     := 0
    Local nEconHistPct := 0
    Local nEconHistRS  := 0
    Local nCntHist     := 0
    Local nSumAcumPct  := 0
    Local nSumHistPct  := 0
    Local nVltUlt      := 0
    Local nVltPen      := 0
    Local nVltPri      := 0
    Local dDtDe        := IIf(ValType(dDe)  == "D" .And. !Empty(dDe),  dDe,  Date() - 365)
    Local dDtAte       := IIf(ValType(dAte) == "D" .And. !Empty(dAte), dAte, Date())

    // Guarda defensiva: se as datas forem invalidas retorna zerado sem gerar erro de thread
    If !(ValType(dDe)  == "D") .Or. Empty(dDe) .Or. ;
       !(ValType(dAte) == "D") .Or. Empty(dAte)
        RestArea(aArea)
        Return {0, 0, 0, 0, 0, 0}
    EndIf
    If dDtAte < dDtDe
        dDtAte := dDtDe
    EndIf

    // Sub-select com funcoes de janela:
    //   RN_DESC=1 -> ultima compra do item no periodo
    //   RN_DESC=2 -> penultima compra do item no periodo
    //   RN_ASC =1 -> primeira compra do item no periodo
    //   CNT_TOT   -> total de compras do item (filtra >= 2 no outer select)
    cQuery := " SELECT BASE.D1_COD,                                                                "
    cQuery += "        MAX(CASE WHEN BASE.RN_DESC = 1 THEN BASE.D1_VUNIT END) AS VLR_ULTIMO,      "
    cQuery += "        MAX(CASE WHEN BASE.RN_DESC = 2 THEN BASE.D1_VUNIT END) AS VLR_PENULT,      "
    cQuery += "        MAX(CASE WHEN BASE.RN_ASC  = 1 THEN BASE.D1_VUNIT END) AS VLR_PRIMEIRO     "
    cQuery += "   FROM (                                                                            "
    cQuery += "         SELECT SD1.D1_COD,                                                         "
    cQuery += "                SD1.D1_VUNIT,                                                       "
    cQuery += "                ROW_NUMBER() OVER (PARTITION BY SD1.D1_COD                          "
    cQuery += "                                   ORDER BY SD1.D1_DTDIGIT DESC,                    "
    cQuery += "                                            SD1.D1_PEDIDO  DESC) AS RN_DESC,         "
    cQuery += "                ROW_NUMBER() OVER (PARTITION BY SD1.D1_COD                          "
    cQuery += "                                   ORDER BY SD1.D1_DTDIGIT ASC,                     "
    cQuery += "                                            SD1.D1_PEDIDO  ASC)  AS RN_ASC,          "
    cQuery += "                COUNT(*)     OVER (PARTITION BY SD1.D1_COD)       AS CNT_TOT        "
    cQuery += "           FROM " + RetSqlName("SD1") + " SD1                                       "
    cQuery += "          WHERE SD1.D_E_L_E_T_ = ' '                                                "
    cQuery += "            AND SD1.D1_FILIAL  = '" + xFilial("SD1") + "'                           "
    cQuery += "            AND SD1.D1_DTDIGIT BETWEEN '" + DtoS(dDtDe) + "' AND '" + DtoS(dDtAte) + "'"
    cQuery += "            AND SD1.D1_TIPO    = 'N'                                                 "
    cQuery += "            AND SD1.D1_QUANT   > 0                                                   "
    cQuery += "            AND SD1.D1_VUNIT   > 0                                                   "
    cQuery += "            AND SD1.D1_PEDIDO  <> ' '                                                "
    cQuery += "            AND (SD1.D1_COD LIKE 'MC%' OR SD1.D1_COD LIKE 'MD%'                     "
    cQuery += "                 OR SD1.D1_COD LIKE 'AI%')                                           "

    If !Empty(AllTrim(cItem))
        cQuery += "            AND SD1.D1_COD LIKE '" + AllTrim(cItem) + "%'                         "
    EndIf
    If !Empty(AllTrim(cCodCC)) .And. cCodCC <> "*"
        cQuery += "            AND SD1.D1_CC  = '" + AllTrim(cCodCC) + "'                          "
    EndIf
    If !Empty(AllTrim(cCodUser)) .And. cCodUser <> "*"
        // Filtra pelo comprador do pedido (SC7), excluindo NFs sem pedido
        cQuery += "            AND EXISTS (                                                          "
        cQuery += "                SELECT 1 FROM " + RetSqlName("SC7") + " SC7E                     "
        cQuery += "                 WHERE SC7E.D_E_L_E_T_ = ' '                                     "
        cQuery += "                   AND SC7E.C7_FILIAL  = '" + xFilial("SC7") + "'                "
        cQuery += "                   AND SC7E.C7_NUM     = SD1.D1_PEDIDO                           "
        cQuery += "                   AND SC7E.C7_ITEM    = SD1.D1_ITEMPC                           "
        cQuery += "                   AND SC7E.C7_CONAPRO NOT IN ('R','B')                          "
        cQuery += "                   AND LTRIM(RTRIM(SC7E.C7_USER)) = '" + AllTrim(cCodUser) + "' "
        cQuery += "                )                                                                 "
    EndIf

    cQuery += "        ) BASE                                                                        "
    cQuery += "  WHERE BASE.CNT_TOT >= 2                                                            "
    cQuery += "  GROUP BY BASE.D1_COD                                                               "

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        nVltUlt := IIf((cAlias)->VLR_ULTIMO  > 0, (cAlias)->VLR_ULTIMO,  0)
        nVltPen := IIf((cAlias)->VLR_PENULT  > 0, (cAlias)->VLR_PENULT,  0)
        nVltPri := IIf((cAlias)->VLR_PRIMEIRO > 0, (cAlias)->VLR_PRIMEIRO, 0)

        // Economia Acumulada: (penultimo - ultimo) / penultimo * 100
        // Positivo = reducao de preco (ganho), Negativo = aumento de preco (perda)
        If nVltPen > 0 .And. nVltUlt > 0
            nSumAcumPct += (nVltPen - nVltUlt) / nVltPen * 100
            nEconAcumRS += (nVltPen - nVltUlt)
            nCntAcum++
        EndIf

        // Economia Historica: (primeiro - ultimo) / primeiro * 100
        If nVltPri > 0 .And. nVltUlt > 0
            nSumHistPct += (nVltPri - nVltUlt) / nVltPri * 100
            nEconHistRS += (nVltPri - nVltUlt)
            nCntHist++
        EndIf

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    nEconAcumPct := IIf(nCntAcum > 0, Round(nSumAcumPct / nCntAcum, 2), 0)
    nEconHistPct := IIf(nCntHist > 0, Round(nSumHistPct / nCntHist, 2), 0)
    nEconAcumRS  := Round(nEconAcumRS, 4)
    nEconHistRS  := Round(nEconHistRS, 4)

    RestArea(aArea)
Return {nEconAcumPct, nEconAcumRS, nCntAcum, nEconHistPct, nEconHistRS, nCntHist}

//=====================================================================
// Static Function AnpCalcEstab
//=====================================================================
/*/{Protheus.doc} AnpCalcEstab
Calcula indicadores de estabilidade de preco por item no periodo,
classificando cada produto em tres categorias:
  1. Estavel desde sempre  : VMAX_HIST = VMIN_HIST E primeira = ultima
  2. Estavel apenas na ultima : penultima = ultima (mas nao congelado)
  3. Em variacao           : demais itens
Tambem retorna o valor de mercado protegido (soma do VTOT da ultima
compra dos itens das categorias 1 e 2).
@author  Copilot / Suprimentos
@since   08/06/2026
@param dDe,      Date,      Data inicial do periodo
@param dAte,     Date,      Data final do periodo
@param cItem,    Character, Codigo do item (vazio = todos)
@param cCodUser, Character, Codigo do comprador (* = todos)
@param cCodCC,   Character, Codigo do centro de custo (* = todos)
@return Array - {nEstCongelado, nEstUltima, nEstVariacao, nTotalMovim, nTotEstab}
/*/
Static Function AnpCalcEstab(dDe, dAte, cItem, cCodUser, cCodCC)
    Local aArea          := GetArea()
    Local cAlias         := GetNextAlias()
    Local cQuery         := ""
    Local nEstCongelado  := 0
    Local nEstUltima     := 0
    Local nEstVariacao   := 0
    Local nTotalMovim    := 0
    Local nTotEstab      := 0
    Local nVltUlt        := 0
    Local nVltPen        := 0
    Local nVltPri        := 0
    Local nVMaxH         := 0
    Local nVMinH         := 0
    Local nVMovLast      := 0
    Local dDtDe          := IIf(ValType(dDe)  == "D" .And. !Empty(dDe),  dDe,  Date() - 365)
    Local dDtAte         := IIf(ValType(dAte) == "D" .And. !Empty(dAte), dAte, Date())

    If !(ValType(dDe)  == "D") .Or. Empty(dDe) .Or. ;
       !(ValType(dAte) == "D") .Or. Empty(dAte)
        RestArea(aArea)
        Return {0, 0, 0, 0, 0}
    EndIf
    If dDtAte < dDtDe
        dDtAte := dDtDe
    EndIf

    // Subquery com funcoes de janela para classificar cada linha por item:
    //   RN_DESC : 1 = ultima compra, 2 = penultima compra (ordem decrescente de data)
    //   RN_ASC  : 1 = primeira compra (ordem crescente de data)
    //   CNT_TOT : total de compras do item no periodo
    //   VMAX_H  : maior preco unitario pago pelo item no periodo
    //   VMIN_H  : menor preco unitario pago pelo item no periodo
    //   VMOV    : valor movimentado de cada linha (D1_VUNIT * D1_QUANT)
    cQuery := " SELECT BASE.D1_COD,                                                                  "
    cQuery += "        MAX(CASE WHEN BASE.RN_DESC = 1 THEN BASE.D1_VUNIT END) AS VLR_ULTIMO,         "
    cQuery += "        MAX(CASE WHEN BASE.RN_DESC = 2 THEN BASE.D1_VUNIT END) AS VLR_PENULT,         "
    cQuery += "        MAX(CASE WHEN BASE.RN_ASC  = 1 THEN BASE.D1_VUNIT END) AS VLR_PRIMEIRO,       "
    cQuery += "        MAX(BASE.VMAX_H)                                        AS VMAX_HIST,          "
    cQuery += "        MAX(BASE.VMIN_H)                                        AS VMIN_HIST,          "
    cQuery += "        MAX(CASE WHEN BASE.RN_DESC = 1 THEN BASE.VMOV END)      AS VMOV_LAST           "
    cQuery += "   FROM (                                                                               "
    cQuery += "         SELECT SD1.D1_COD,                                                            "
    cQuery += "                SD1.D1_VUNIT,                                                          "
    cQuery += "                SD1.D1_VUNIT * SD1.D1_QUANT                AS VMOV,                    "
    cQuery += "                ROW_NUMBER() OVER (PARTITION BY SD1.D1_COD                             "
    cQuery += "                                   ORDER BY SD1.D1_DTDIGIT DESC,                       "
    cQuery += "                                            SD1.D1_PEDIDO  DESC) AS RN_DESC,            "
    cQuery += "                ROW_NUMBER() OVER (PARTITION BY SD1.D1_COD                             "
    cQuery += "                                   ORDER BY SD1.D1_DTDIGIT ASC,                        "
    cQuery += "                                            SD1.D1_PEDIDO  ASC)  AS RN_ASC,             "
    cQuery += "                COUNT(*)     OVER (PARTITION BY SD1.D1_COD)      AS CNT_TOT,            "
    cQuery += "                MAX(SD1.D1_VUNIT) OVER (PARTITION BY SD1.D1_COD) AS VMAX_H,             "
    cQuery += "                MIN(SD1.D1_VUNIT) OVER (PARTITION BY SD1.D1_COD) AS VMIN_H              "
    cQuery += "           FROM " + RetSqlName("SD1") + " SD1                                          "
    cQuery += "          WHERE SD1.D_E_L_E_T_ = ' '                                                   "
    cQuery += "            AND SD1.D1_FILIAL  = '" + xFilial("SD1") + "'                              "
    cQuery += "            AND SD1.D1_DTDIGIT BETWEEN '" + DtoS(dDtDe) + "' AND '" + DtoS(dDtAte) + "'"
    cQuery += "            AND SD1.D1_TIPO    = 'N'                                                    "
    cQuery += "            AND SD1.D1_QUANT   > 0                                                     "
    cQuery += "            AND SD1.D1_VUNIT   > 0                                                     "
    cQuery += "            AND SD1.D1_PEDIDO  <> ' '                                                   "
    cQuery += "            AND (SD1.D1_COD LIKE 'MC%' OR SD1.D1_COD LIKE 'MD%'                        "
    cQuery += "                 OR SD1.D1_COD LIKE 'AI%')                                              "

    If !Empty(AllTrim(cItem))
        cQuery += "            AND SD1.D1_COD LIKE '" + AllTrim(cItem) + "%'                            "
    EndIf
    If !Empty(AllTrim(cCodCC)) .And. cCodCC <> "*"
        cQuery += "            AND SD1.D1_CC  = '" + AllTrim(cCodCC) + "'                             "
    EndIf
    If !Empty(AllTrim(cCodUser)) .And. cCodUser <> "*"
        cQuery += "            AND EXISTS (                                                             "
        cQuery += "                SELECT 1 FROM " + RetSqlName("SC7") + " SC7E                        "
        cQuery += "                 WHERE SC7E.D_E_L_E_T_ = ' '                                        "
        cQuery += "                   AND SC7E.C7_FILIAL  = '" + xFilial("SC7") + "'                   "
        cQuery += "                   AND SC7E.C7_NUM     = SD1.D1_PEDIDO                               "
        cQuery += "                   AND SC7E.C7_ITEM    = SD1.D1_ITEMPC                               "
        cQuery += "                   AND SC7E.C7_CONAPRO NOT IN ('R','B')                             "
        cQuery += "                   AND LTRIM(RTRIM(SC7E.C7_USER)) = '" + AllTrim(cCodUser) + "'     "
        cQuery += "                )                                                                    "
    EndIf

    cQuery += "        ) BASE                                                                          "
    cQuery += "  WHERE BASE.CNT_TOT >= 2                                                              "
    cQuery += "  GROUP BY BASE.D1_COD                                                                 "

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        nVltUlt   := IIf((cAlias)->VLR_ULTIMO   > 0, (cAlias)->VLR_ULTIMO,   0)
        nVltPen   := IIf((cAlias)->VLR_PENULT   > 0, (cAlias)->VLR_PENULT,   0)
        nVltPri   := IIf((cAlias)->VLR_PRIMEIRO > 0, (cAlias)->VLR_PRIMEIRO, 0)
        nVMaxH    := IIf((cAlias)->VMAX_HIST     > 0, (cAlias)->VMAX_HIST,    0)
        nVMinH    := IIf((cAlias)->VMIN_HIST     > 0, (cAlias)->VMIN_HIST,    0)
        nVMovLast := IIf((cAlias)->VMOV_LAST     > 0, (cAlias)->VMOV_LAST,    0)

        If nVltUlt > 0 .And. nVltPen > 0

            // Categoriza: congelado = nunca variou (max = min = primeira = ultima)
            If Round(nVMaxH, 4) = Round(nVMinH, 4) .And. ;
               Round(nVltPri, 4) = Round(nVltUlt, 4)
                nEstCongelado++
                nTotalMovim += nVMovLast

            // Semi-estavel: penultima = ultima (mas alguma variacao no historico)
            ElseIf Round(nVltUlt, 4) = Round(nVltPen, 4)
                nEstUltima++
                nTotalMovim += nVMovLast

            // Variacao ativa entre penultima e ultima compra
            Else
                nEstVariacao++
            EndIf

            nTotEstab++
        EndIf

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    RestArea(aArea)
Return {nEstCongelado, nEstUltima, nEstVariacao, nTotalMovim, nTotEstab}
