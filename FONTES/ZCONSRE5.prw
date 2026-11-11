#Include "Totvs.ch"

#DEFINE CRLF Chr(13)+Chr(10)

// Vari?veis Static para controle dos filtros
Static cStcProd    := ""
Static cStcFornCd  := ""
Static cStcFornNm  := ""
Static cStcAlsTmp  := ""
Static cStcAlsQry  := ""
Static dStcDtIni   := Ctod("")
Static dStcDtFim   := Ctod("")
Static cStcFilSB1  := ""
Static cStcFilSA1  := ""
Static cStcFilSA2  := ""
Static nStcOrder   := 0

User Function ZCONSRE5()

    Local aStruct    := {}
    Local aColumns   := {}
    Local nX         := 0
    Local dDtIni     := Ctod("  /  /  ")
    Local dDtFim     := dDataBase
    Local oDataIni
    Local oDataFim
    Local oDlgPar
    Local cAliasTmp  := ""
    Local oTempTable
    Local lProc      := .F.
    Local oFontGrd
    Local oDlgBrw
    Local oBrw
    Local oPnlFlt
    Local oPnlBrw
    Local oFontFlt
    Local oSplit
    Local cProd, cFornCd, cFornNm
    Local oProd, oFornCd, oFornNm

    // Inicializa filtros
    cStcProd   := ""
    cStcFornCd := ""
    cStcFornNm := ""

    // Filiais
    cStcFilSB1 := FWxFilial("SB1")
    cStcFilSA1 := FWxFilial("SA1")
    cStcFilSA2 := FWxFilial("SA2")

    // Fontes
    Define Font oFontGrd Name "Arial" Size 0,-12 Bold
    Define Font oFontFlt Name "Arial" Size 0,-11

    // ============================================================
    // Dialog de par?metros (somente datas - como era antes)
    // ============================================================
    DEFINE MSDIALOG oDlgPar TITLE "Notas em poder de terceiros (sem retorno)" FROM 120,230 TO 466,916 PIXEL

    @ 004,004 TO 068,343 LABEL PIXEL OF oDlgPar

    @ 016,010 SAY "Data a processar" SIZE 070,008 COLOR CLR_BLUE FONT oFontGrd PIXEL OF oDlgPar

    @ 014,100 MSGET oDataIni VAR dDtIni SIZE 080,010 VALID .T. COLOR CLR_BLACK FONT oFontGrd PIXEL OF oDlgPar
    @ 030,100 MSGET oDataFim VAR dDtFim SIZE 080,010 VALID .T. COLOR CLR_BLACK FONT oFontGrd PIXEL OF oDlgPar

    @ 100,210 BUTTON "&Confirma" SIZE 037,014 ACTION ( lProc := .T. , oDlgPar:End() ) FONT oFontGrd PIXEL OF oDlgPar
    @ 100,254 BUTTON "Ca&ncela"  SIZE 037,014 ACTION ( lProc := .F. , oDlgPar:End() ) FONT oFontGrd PIXEL OF oDlgPar

    ACTIVATE MSDIALOG oDlgPar CENTERED

    If ! lProc
        Return
    EndIf

    // Ajusta datas vazias
    dDtIni := IIf( Empty(dDtIni), dDataBase, dDtIni )
    dDtFim := IIf( Empty(dDtFim), dDataBase, dDtFim )

    dStcDtIni := dDtIni
    dStcDtFim := dDtFim

    // ============================================================
    // Estrutura da tempor?ria
    // ============================================================
    AAdd(aStruct , { "NUMREG"   , "N" , 12 , 0 })
    AAdd(aStruct , { "DTEMIS"   , "D" ,  8 , 0 })
    AAdd(aStruct , { "NFDOC"    , "C" ,  9 , 0 })
    AAdd(aStruct , { "NFSER"    , "C" ,  3 , 0 })
    AAdd(aStruct , { "CODPROD"  , "C" , 15 , 0 })
    AAdd(aStruct , { "DESCPROD" , "C" , 60 , 0 })
    AAdd(aStruct , { "QTDE"     , "N" , 13 , 2 })
    AAdd(aStruct , { "QTDEDEV"  , "N" , 13 , 2 })
    AAdd(aStruct , { "CODCLI"   , "C" ,  6 , 0 })
    AAdd(aStruct , { "LOJACLI"  , "C" ,  2 , 0 })
    AAdd(aStruct , { "NOMEFOR"  , "C" , 60 , 0 })
    AAdd(aStruct , { "INSCR"    , "C" , 18 , 0 })
    AAdd(aStruct , { "CFOP"     , "C" ,  4 , 0 })
    AAdd(aStruct , { "SOLICIT"  , "C" , 60 , 0 })

    // Colunas do browse (a partir do 2? campo)
    For nX := 2 To Len(aStruct)
        AAdd(aColumns , FWBrwColumn():New())
        aColumns[Len(aColumns)]:SetData( &("{||" + aStruct[nX][1] + "}") )

        Do Case
        Case aStruct[nX][1] == "DTEMIS"   ; aColumns[Len(aColumns)]:SetTitle("Dt.Emissao")
        Case aStruct[nX][1] == "NFDOC"    ; aColumns[Len(aColumns)]:SetTitle("Documento")
        Case aStruct[nX][1] == "NFSER"    ; aColumns[Len(aColumns)]:SetTitle("Serie")
        Case aStruct[nX][1] == "CODPROD"  ; aColumns[Len(aColumns)]:SetTitle("Produto")
        Case aStruct[nX][1] == "DESCPROD" ; aColumns[Len(aColumns)]:SetTitle("Descricao")
        Case aStruct[nX][1] == "QTDE"     ; aColumns[Len(aColumns)]:SetTitle("Quantidade")
        Case aStruct[nX][1] == "QTDEDEV"  ; aColumns[Len(aColumns)]:SetTitle("Quantidade Devolvida")
        Case aStruct[nX][1] == "CODCLI"   ; aColumns[Len(aColumns)]:SetTitle("Cliente/Fornec.")
        Case aStruct[nX][1] == "LOJACLI"  ; aColumns[Len(aColumns)]:SetTitle("Loja")
        Case aStruct[nX][1] == "NOMEFOR"  ; aColumns[Len(aColumns)]:SetTitle("Nome Cliente/Fornec.")
        Case aStruct[nX][1] == "INSCR"    ; aColumns[Len(aColumns)]:SetTitle("Insc.Estadual")
        Case aStruct[nX][1] == "CFOP"     ; aColumns[Len(aColumns)]:SetTitle("CFOP")
        Case aStruct[nX][1] == "SOLICIT"  ; aColumns[Len(aColumns)]:SetTitle("Solicitante")
        Otherwise
            aColumns[Len(aColumns)]:SetTitle(aStruct[nX][1])
        EndCase

        aColumns[Len(aColumns)]:SetSize( aStruct[nX][3] )
        aColumns[Len(aColumns)]:SetDecimal( aStruct[nX][4] )
    Next nX

    // Cria tempor?ria
    oTempTable := FWTemporaryTable():New()
    oTempTable:SetFields(aStruct)
    oTempTable:AddIndex("IDX1" , { "DTEMIS" } )
    oTempTable:Create()
    cAliasTmp := oTempTable:GetAlias()
    cStcAlsTmp := cAliasTmp

    // Carrega dados iniciais (sem filtro)
    fCarregaDados( cAliasTmp )

    // ============================================================
    // Dialog principal: Filtros em cima + Browse embaixo
    // ============================================================
    cProd   := Space(15)
    cFornCd := Space(6)
    cFornNm := Space(60)

    DEFINE MSDIALOG oDlgBrw TITLE "Gestao de frete embarcador - Notas em poder de terceiros" FROM 000,000 TO 800,1600 PIXEL

    // Maximiza a janela
    oDlgBrw:lMaximized := .T.

    // --- Painel superior (filtros) ---
    oPnlFlt := tPanel():New( 0, 0, "", oDlgBrw, , , , , , 0, 34 )
    oPnlFlt:Align := CONTROL_ALIGN_TOP

    @ 008,008  SAY "Produto:" SIZE 040,008 FONT oFontFlt PIXEL OF oPnlFlt
    @ 006,050  MSGET oProd   VAR cProd   SIZE 090,012 PICTURE "@!" FONT oFontFlt F3 "SB1" PIXEL OF oPnlFlt

    @ 008,150 SAY "Cod.Fornecedor:" SIZE 065,008 FONT oFontFlt PIXEL OF oPnlFlt
    @ 006,220 MSGET oFornCd VAR cFornCd SIZE 050,012 PICTURE "@!" FONT oFontFlt F3 "SA2" PIXEL OF oPnlFlt

    @ 008,280 SAY "Nome Fornecedor:" SIZE 070,008 FONT oFontFlt PIXEL OF oPnlFlt
    @ 006,355 MSGET oFornNm VAR cFornNm SIZE 130,012 PICTURE "@!" FONT oFontFlt PIXEL OF oPnlFlt

    @ 005,495 BUTTON "Pesquisar" SIZE 045,014 ;
        ACTION ( fAplicaFiltro( cAliasTmp, AllTrim(cProd), AllTrim(cFornCd), AllTrim(cFornNm), oBrw ) ) ;
        FONT oFontFlt PIXEL OF oPnlFlt

    @ 005,545 BUTTON "Limpar" SIZE 040,014 ;
        ACTION ( cProd := Space(15), cFornCd := Space(6), cFornNm := Space(60), ;
                 oProd:Refresh(), oFornCd:Refresh(), oFornNm:Refresh(), ;
                 fAplicaFiltro( cAliasTmp, "", "", "", oBrw ) ) ;
        FONT oFontFlt PIXEL OF oPnlFlt

    // --- Painel inferior (browse) ---
    oPnlBrw := tPanel():New( 0, 0, "", oDlgBrw, , , , , , 0, 0 )
    oPnlBrw:Align := CONTROL_ALIGN_ALLCLIENT

    // Browse dentro do painel inferior
    oBrw := FWMBrowse():New()
    oBrw:SetOwner( oPnlBrw )
    oBrw:SetAlias( cAliasTmp )
    oBrw:SetTemporary( .T. )
    oBrw:SetColumns( aColumns )
    oBrw:OptionReport( .T. )
    oBrw:SetDescription( "Notas em poder de terceiros" )
    oBrw:Activate()

    ACTIVATE MSDIALOG oDlgBrw CENTERED

    // Limpeza
    If !Empty(cStcAlsQry) .And. Select(cStcAlsQry) > 0
        (cStcAlsQry)->(DbCloseArea())
    EndIf

    If ValType(oTempTable) == "O"
        oTempTable:Delete()
    EndIf

Return

//----------------------------------------------------
// Aplica filtro: limpa tempor?ria e recarrega
//----------------------------------------------------
Static Function fAplicaFiltro( cAliasTmp, cProd, cFornCod, cFornNome, oBrw )

    cStcProd   := cProd
    cStcFornCd := cFornCod
    cStcFornNm := cFornNome

    // Limpa tempor?ria
    (cAliasTmp)->(DbGoTop())
    While !(cAliasTmp)->(Eof())
        If RecLock( cAliasTmp, .F. )
            (cAliasTmp)->(DbDelete())
            (cAliasTmp)->(MsUnlock())
        EndIf
        (cAliasTmp)->(DbSkip())
    EndDo

    // Recarrega com filtros
    fCarregaDados( cAliasTmp )

    (cAliasTmp)->(DbGoTop())

    If ValType(oBrw) == "O"
        oBrw:Refresh()
    EndIf

Return

//----------------------------------------------------
// Carrega dados na tempor?ria via query
//----------------------------------------------------
Static Function fCarregaDados( cAliasTmp )
    Local cAliasQry := GetNextAlias()
    Local cQuery    := ""

    // Fecha alias anterior se existir
    If !Empty(cStcAlsQry) .And. Select(cStcAlsQry) > 0
        (cStcAlsQry)->(DbCloseArea())
    EndIf

    nStcOrder := 0

    // Monta query
    cQuery  := "SELECT " + CRLF
    cQuery += "REM.D2_EMISSAO AS DTEMIS, "        + CRLF
    cQuery += "REM.D2_DOC     AS NFDOC, "         + CRLF
    cQuery += "REM.D2_SERIE   AS NFSER, "         + CRLF
    cQuery += "REM.D2_COD     AS CODPROD, "       + CRLF
    cQuery += "SB1.B1_DESC    AS DESCPROD, "      + CRLF
    cQuery += "REM.D2_QUANT   AS QTDE, "          + CRLF
    cQuery += "REM.D2_QTDEDEV AS QTDEDEV, "       + CRLF
    cQuery += "REM.D2_CLIENTE AS CODCLI, "        + CRLF
    cQuery += "REM.D2_LOJA    AS LOJACLI, "       + CRLF
    cQuery += "SA2.A2_NOME    AS NOMEFOR, "       + CRLF
    cQuery += "SA2.A2_INSCR   AS INSCR, "         + CRLF
    cQuery += "REM.D2_CF      AS CFOP, "          + CRLF
    cQuery += "ISNULL(SA1.A1_NOME, '') AS SOLICIT " + CRLF
    cQuery += "FROM " + RetSqlName("SD2") + " REM " + CRLF
    // Devolucoes somadas por item de remessa: a linha do processo sai da lista
    // quando a soma das quantidades devolvidas atinge a quantidade remetida.
    cQuery += "LEFT JOIN ( " + CRLF
    cQuery += "  SELECT DER.D1_FILIAL, DER.D1_NFORI, DER.D1_SERIORI, DER.D1_ITEMORI, " + CRLF
    cQuery += "         SUM(DER.D1_QUANT) AS QTDERET " + CRLF
    cQuery += "  FROM " + RetSqlName("SD1") + " DER " + CRLF
    cQuery += "  WHERE DER.D_E_L_E_T_ = ' ' " + CRLF
    cQuery += "    AND DER.D1_NFORI <> ' ' " + CRLF
    cQuery += "    AND DER.D1_EMISSAO >= '" + DtoS(dStcDtIni) + "' " + CRLF
    cQuery += "  GROUP BY DER.D1_FILIAL, DER.D1_NFORI, DER.D1_SERIORI, DER.D1_ITEMORI " + CRLF
    cQuery += ") DEV " + CRLF
    cQuery += "  ON DEV.D1_FILIAL  = REM.D2_FILIAL " + CRLF
    cQuery += " AND DEV.D1_NFORI   = REM.D2_DOC " + CRLF
    cQuery += " AND DEV.D1_SERIORI = REM.D2_SERIE " + CRLF
    cQuery += " AND DEV.D1_ITEMORI = REM.D2_ITEM " + CRLF
    // Pedido de venda que originou a remessa e cliente que fez o pedido.
    cQuery += "LEFT JOIN " + RetSqlName("SC5") + " SC5 " + CRLF
    cQuery += "  ON SC5.C5_FILIAL  = REM.D2_FILIAL " + CRLF
    cQuery += " AND SC5.C5_NUM     = REM.D2_PEDIDO " + CRLF
    cQuery += " AND SC5.D_E_L_E_T_ = ' ' " + CRLF
    cQuery += "LEFT JOIN " + RetSqlName("SA1") + " SA1 " + CRLF
    cQuery += "  ON SA1.A1_FILIAL  = '" + cStcFilSA1 + "' " + CRLF
    cQuery += " AND SA1.A1_COD     = SC5.C5_CLIENTE " + CRLF
    cQuery += " AND SA1.A1_LOJA    = SC5.C5_LOJACLI " + CRLF
    cQuery += " AND SA1.D_E_L_E_T_ = ' ' " + CRLF
    cQuery += "LEFT JOIN " + RetSqlName("SB1") + " SB1 " + CRLF
    cQuery += "  ON SB1.B1_FILIAL  = '" + cStcFilSB1 + "' " + CRLF
    cQuery += " AND SB1.B1_COD     = REM.D2_COD " + CRLF
    cQuery += " AND SB1.D_E_L_E_T_ = ' ' "        + CRLF
    cQuery += "LEFT JOIN " + RetSqlName("SA2") + " SA2 " + CRLF
    cQuery += "  ON SA2.A2_FILIAL  = '" + cStcFilSA2 + "' " + CRLF
    cQuery += " AND SA2.A2_COD     = REM.D2_CLIENTE " + CRLF
    cQuery += " AND SA2.A2_LOJA    = REM.D2_LOJA " + CRLF
    cQuery += " AND SA2.D_E_L_E_T_ = ' ' "        + CRLF
    cQuery += "WHERE REM.D_E_L_E_T_ = ' ' "       + CRLF
    cQuery += "  AND REM.D2_TIPO    = 'B' "       + CRLF
    cQuery += "  AND REM.D2_CF IN ('5949','6949','5901','6901','5909','6909','5915','6915') " + CRLF
    cQuery += "  AND REM.D2_EMISSAO BETWEEN '" + DtoS(dStcDtIni) + "' AND '" + DtoS(dStcDtFim) + "' " + CRLF
    cQuery += "  AND ISNULL(DEV.QTDERET, 0) < REM.D2_QUANT "  + CRLF
    cQuery += "  AND REM.D2_COD NOT LIKE 'PA%' "  + CRLF

    // Filtro por produto
    If !Empty( cStcProd )
        cQuery += "  AND REM.D2_COD = '" + PadR(cStcProd, 15) + "' " + CRLF
    EndIf

    // Filtro por c?digo do fornecedor
    If !Empty( cStcFornCd )
        cQuery += "  AND REM.D2_CLIENTE = '" + PadR(cStcFornCd, 6) + "' " + CRLF
    EndIf

    // Filtro por nome do fornecedor (cont?m)
    If !Empty( cStcFornNm )
        cQuery += "  AND SA2.A2_NOME LIKE '%" + cStcFornNm + "%' " + CRLF
    EndIf

    cQuery += "ORDER BY REM.D2_EMISSAO, REM.D2_DOC, REM.D2_ITEM" + CRLF

    cQuery := ChangeQuery(cQuery)
    PlsQuery(cQuery , cAliasQry)

    If Empty(cAliasQry)
        Return
    EndIf

    cStcAlsQry := cAliasQry

    (cAliasQry)->(DbGoTop())

    While ! (cAliasQry)->(Eof())
        nStcOrder++
        If RecLock(cAliasTmp , .T.)
            (cAliasTmp)->NUMREG   := nStcOrder
            (cAliasTmp)->DTEMIS   := StoD((cAliasQry)->DTEMIS)
            (cAliasTmp)->NFDOC    := (cAliasQry)->NFDOC
            (cAliasTmp)->NFSER    := (cAliasQry)->NFSER
            (cAliasTmp)->CODPROD  := (cAliasQry)->CODPROD
            (cAliasTmp)->DESCPROD := (cAliasQry)->DESCPROD
            (cAliasTmp)->QTDE     := (cAliasQry)->QTDE
            (cAliasTmp)->QTDEDEV  := (cAliasQry)->QTDEDEV
            (cAliasTmp)->CODCLI   := (cAliasQry)->CODCLI
            (cAliasTmp)->LOJACLI  := (cAliasQry)->LOJACLI
            (cAliasTmp)->NOMEFOR  := (cAliasQry)->NOMEFOR
            (cAliasTmp)->INSCR    := (cAliasQry)->INSCR
            (cAliasTmp)->CFOP     := (cAliasQry)->CFOP
            (cAliasTmp)->SOLICIT  := (cAliasQry)->SOLICIT
            (cAliasTmp)->(MsUnlock())
        EndIf
        (cAliasQry)->(DbSkip())
    EndDo

    (cAliasTmp)->(DbGoTop())

Return
