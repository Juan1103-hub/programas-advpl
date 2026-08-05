#Include "Protheus.ch"
#Include "TopConn.ch"

#Define ENTER  Chr(10) + Chr (13) // SALTO DE LINHA (CARRIAGE RETURN + LINE FEED)

//-------------------------------------------------------------------
/*/{Protheus.doc} CADSZ3
Solicitacao Cadastral de Produtos (SZ3).
Tela padrao mBrowse com aRotina, apresentando no topo os botoes
Incluir, Alterar, Visualizar e o menu "Outras Acoes" (Pesquisar,
Excluir e Legenda).

Para Fornecedores utilize o programa CADFORN (U_CADFORN).

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   25/04/2024
/*/
//-------------------------------------------------------------------
User Function CADSZ3()

    Local aArea := GetArea()

    If Select("SZ3") <= 0
        ChkFile("SZ3")
    EndIf

    FCfgValZ3(.T.)
    FSyncZ3Rej(.T.)

    DbSelectArea("SZ3")
    SZ3->(DbSetOrder(1))
    SZ3->(DbGoTop())

    Private cCadastro := "Solicitacao Cadastral de Produtos"
    Private cString   := "SZ3"

    // 0=Pendente (branco) | 1=Cadastrado (cinza) | 2=Rejeitado (preto)
    Private aCores := { ;
        {"SZ3->Z3_STATUS == '0'", "BR_BRANCO"}, ;
        {"SZ3->Z3_STATUS == '1'", "DISABLE"  }, ;
        {"SZ3->Z3_STATUS == '2'", "BR_PRETO" } }

    Private aRotina := { ;
        {"Incluir"   , "U_CADINSZ3", 0, 3}, ;
        {"Alterar"   , "U_CPRDALT" , 0, 3}, ;
        {"Visualizar", "U_CPRDVIS" , 0, 2}, ;
        {"Pesquisar" , "AxPesqui"  , 0, 1}, ;
        {"Excluir"   , "U_CPRDDEL" , 0, 5}, ;
        {"Legenda"   , "U_CADLESZ3", 0, 6} }

    mBrowse(6, 1, 22, 75, "SZ3", , , , , , aCores)

    RestArea(aArea)

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} CADSZ3_Alt
Abre formulario customizado de edicao para o produto selecionado.
Bloqueia alteracao de registros que nao sejam Pendentes ('0').
/*/
//-------------------------------------------------------------------
Static Function CADSZ3_Alt()

    Local cSts := ""

    DbSelectArea("SZ3")

    If SZ3->(Eof()) .Or. SZ3->(Bof())
        MsgStop("Nenhum registro selecionado.", "Alterar")
        Return
    EndIf

    cSts := AllTrim(SZ3->Z3_STATUS)

    If cSts != '0'
        MsgStop("Somente solicitacoes PENDENTES podem ser alteradas." + Chr(13) + Chr(10) + ;
                "Status atual: " + IIF(cSts == '1', 'Aprovado', 'Rejeitado'), "Alteracao Bloqueada")
        Return
    EndIf

    FEditSZ3()

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FEditSZ3
Formulario de edicao de solicitacao de produto (SZ3).
/*/
//-------------------------------------------------------------------
Static Function FEditSZ3()

    Local oButton1, oButton2, oButton3
    Local oGroup1, oGroup2, oGroup3, oGroup4, oGroup5, oGroup6, oGroup7
    Local oGet1, oGet2, oGet3, oGet4, oGet5, oGet6, oGet7
    Local oCombo
    Local cGet1  := Space(120)
    Local cGet2  := Space(120)
    Local cGet3  := Space(150)
    Local cGet4  := Space(254)
    Local cGet5  := Space(02)
    Local cGet6  := Space(100)
    Local cGet7  := Space(100)
    Local cCombo := ""
    Local aItens := {"Sim", "Nao"}
    Local nRecNo := SZ3->(RecNo())

    Private oDlg
    Private oMSNewGe1
    Private aHeaderEx := {}
    Private aColsEx   := {}

    DbSelectArea("SZ3")
    cGet2  := PadR(AllTrim(SZ3->Z3_DESCRI), 120)
    cGet3  := PadR(AllTrim(SZ3->Z3_PN)    , 150)
    cGet4  := PadR(AllTrim(SZ3->Z3_LINK)  , 254)
    cGet5  := PadR(AllTrim(SZ3->Z3_UM)    ,   2)
    cGet6  := PadR(AllTrim(SZ3->Z3_APLIC) , 100)
    cGet7  := PadR(AllTrim(SZ3->Z3_MOTIVO), 100)
    cCombo := IIF(SZ3->Z3_PRAZO == 'S', aItens[1], aItens[2])

    DEFINE MSDIALOG oDlg TITLE "Alterar Solicitacao de Produto - " + AllTrim(SZ3->Z3_ID) ;
        FROM 000, 000 TO 800, 735 COLORS 0, 16777215 PIXEL

        @ 003, 005 GROUP oGroup1 TO 119, 351 PROMPT "Pesquise aqui se o produto ja existe no cadastro." OF oDlg COLOR 0, 16777215 PIXEL
        @ 016, 011 MSGET oGet1 VAR cGet1 SIZE 253, 010 OF oDlg COLORS 0, 16777215 PIXEL
        fMSNewGe1()
        @ 015, 283 BUTTON oButton3 PROMPT "Pesquisar" SIZE 037, 012 OF oDlg PIXEL Action FPesProd(cGet1)

        @ 128, 007 GROUP oGroup2 TO 161, 355 PROMPT "Descricao do material completa, de forma clara e concisa - Exemplo: PARAFUSO SEXTAVADO ACO 8.8 ROSCA INTEIRA M16 X 50" OF oDlg COLOR 0, 16777215 PIXEL
        @ 139, 016 MSGET oGet2 VAR cGet2 SIZE 313, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 169, 007 GROUP oGroup3 TO 197, 355 PROMPT "PART NUMBER (PN) - No. referencia ou codigo do material - Exemplo: Macaco Hidropneumatico Tipo Garrafa 12 Toneladas - PN LPK-207Q" OF oDlg COLOR 0, 16777215 PIXEL
        @ 181, 016 MSGET oGet3 VAR cGet3 SIZE 326, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 207, 007 GROUP oGroup4 TO 236, 355 PROMPT "LINK DE REFERENCIA - Informar o link do site do fabricante, exceto links de marketplaces - Exemplo:Mercado livre,Shoppe,Magazine luiza." OF oDlg COLOR 0, 16777215 PIXEL
        @ 218, 016 MSGET oGet4 VAR cGet4 SIZE 321, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 242, 007 GROUP oGroup5 TO 270, 355 PROMPT "UNIDADE DE MEDIDA - Unidade na qual o material e medido. - Exemplo: pecas, metros, litros." OF oDlg COLOR 0, 16777215 PIXEL
        @ 253, 016 MSGET oGet5 VAR cGet5 VALID FVldSAH(cGet5) SIZE 038, 010 OF oDlg COLORS 0, 16777215 PIXEL F3 "SAH"

        @ 276, 007 GROUP oGroup6 TO 305, 300 PROMPT "Urgente - Sim para cadastro ate 24h uteis. / Nao urgente ate 72h uteis." OF oDlg COLOR 0, 16777215 PIXEL
        oCombo := tComboBox():New(286,016,{|u|if(PCount()>0,cCombo:=u,cCombo)},;
            aItens,30,10,oDlg,,,,,,.T.,,,,,,,,,'cCombo')
        @ 286, 050 MSGET oGet7 VAR cGet7 SIZE 230, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 310, 007 GROUP oGroup7 TO 338, 300 PROMPT "APLICACAO - Onde o produto sera aplicado." OF oDlg COLOR 0, 16777215 PIXEL
        @ 320, 016 MSGET oGet6 VAR cGet6 SIZE 200, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 282, 310 BUTTON oButton1 PROMPT "Confirmar" SIZE 037, 012 OF oDlg PIXEL ;
            ACTION FSaveSZ3(nRecNo, cGet2, cGet3, cGet4, cGet5, SubStr(cCombo,1,1), cGet6, cGet7)
        @ 302, 310 BUTTON oButton2 PROMPT "Cancelar"  SIZE 037, 012 OF oDlg PIXEL ;
            ACTION oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FSaveSZ3
Grava alteracoes na solicitacao de produto existente (SZ3).
/*/
//-------------------------------------------------------------------
Static Function FSaveSZ3(nRecNo, cDescProd, cPart, cLink, cUM, cUrg, cAplic, cMotivo)

    If Empty(AllTrim(cDescProd))
        MsgStop("A descricao do produto e obrigatoria!")
        Return
    EndIf

    If Empty(AllTrim(cUM))
        MsgStop("A unidade de medida e obrigatoria!")
        Return
    EndIf

    If Empty(AllTrim(cPart)) .And. Empty(AllTrim(cLink))
        MsgStop("Informe o Part Number ou o link de referencia!")
        Return
    EndIf

    If Empty(AllTrim(cAplic))
        MsgStop("A aplicacao e obrigatoria!")
        Return
    EndIf

    If 'S' $ cUrg .And. Empty(AllTrim(cMotivo))
        MsgStop("Se cadastro for urgente o motivo e obrigatorio!")
        Return
    EndIf

    If 'S' $ cUrg .And. !Empty(AllTrim(cMotivo)) .And. Len(AllTrim(cMotivo)) <= 10
        MsgStop("Por favor, detalhe melhor o motivo da urgencia!")
        Return
    EndIf

    oDlg:End()

    DbSelectArea("SZ3")
    DbSetOrder(01)
    DbGoTo(nRecNo)

    If Reclock("SZ3", .F.)
        Replace Z3_PN     With UPPER(AllTrim(cPart))
        Replace Z3_LINK   With AllTrim(cLink)
        Replace Z3_UM     With UPPER(AllTrim(cUM))
        Replace Z3_DESCRI With UPPER(AllTrim(cDescProd))
        Replace Z3_PRAZO  With cUrg
        Replace Z3_APLIC  With UPPER(AllTrim(cAplic))
        Replace Z3_MOTIVO With IIF('S' $ cUrg, AllTrim(cMotivo), "")
        MsUnlock()
    EndIf

    MsgInfo("Solicitacao atualizada com sucesso!", "Sucesso")

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} CADSZ3_Vis
Visualizacao (somente leitura) do produto selecionado.
/*/
//-------------------------------------------------------------------
Static Function CADSZ3_Vis()

    Local nRec     := 0
    Local aARotina := {{"Visualizar", "AxVisual", 0, 3}}

    DbSelectArea("SZ3")

    If SZ3->(Eof()) .Or. SZ3->(Bof())
        MsgStop("Nenhum registro selecionado.", "Visualizar")
        Return
    EndIf

    nRec := SZ3->(RecNo())
    AxVisual("SZ3", nRec, 3, aARotina)

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} CADSZ3_Del
Exclui logicamente o produto selecionado se for Pendente.
/*/
//-------------------------------------------------------------------
Static Function CADSZ3_Del()

    Local cSts := ""

    DbSelectArea("SZ3")

    If SZ3->(Eof()) .Or. SZ3->(Bof())
        MsgStop("Nenhum registro selecionado.", "Excluir")
        Return
    EndIf

    cSts := AllTrim(SZ3->Z3_STATUS)

    If cSts != '0'
        MsgStop("Somente solicitacoes PENDENTES podem ser excluidas." + Chr(13) + Chr(10) + ;
                "Status atual: " + IIF(cSts == '1', 'Aprovado', 'Rejeitado'), "Exclusao Bloqueada")
        Return
    EndIf

    If !MsgYesNo("Confirma a exclusao desta solicitacao?", "Excluir")
        Return
    EndIf

    If Reclock("SZ3", .F.)
        DbDelete()
        MsUnlock()
    EndIf

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} CADINSZ3
Tela de inclusao de solicitacao de cadastro de produto.
Permite pesquisar produto existente no catalogo (SB1) antes de
preencher os dados e gravar a solicitacao na SZ3.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   25/04/2024
/*/
//-------------------------------------------------------------------
User Function CADINSZ3()

    Local oButton1, oButton2, oButton3
    Local oGet1, oGet2, oGet3, oGet4, oGet5, oGet6, oGet7
    Local cGet1 := Space(120)
    Local cGet2 := Space(120)
    Local cGet3 := Space(150)
    Local cGet4 := Space(254)
    Local cGet5 := Space(02)
    Local cGet6 := Space(100)
    Local cGet7 := Space(100)
    Local oGroup1, oGroup2, oGroup3, oGroup4, oGroup5, oGroup6, oGroup7
    Local oCombo
    Local cCombo
    Local aItens := {'Sim','Nao'}

    Private oMSNewGe1
    Private oDlg
    Private aHeaderEx := {}
    Private aColsEx   := {}

    cCombo := aItens[2]

    DEFINE MSDIALOG oDlg TITLE "Solicitacao de Cadastro de Produtos" FROM 000, 000 TO 800, 735 COLORS 0, 16777215 PIXEL

        @ 003, 005 GROUP oGroup1 TO 119, 351 PROMPT "Pesquise aqui se o produto ja existe no cadastro." OF oDlg COLOR 0, 16777215 PIXEL
        @ 016, 011 MSGET oGet1 VAR cGet1 SIZE 253, 010 OF oDlg COLORS 0, 16777215 PIXEL

        fMSNewGe1()

        @ 015, 283 BUTTON oButton1 PROMPT "Pesquisar" SIZE 037, 012 OF oDlg PIXEL Action FPesProd(cGet1)

        @ 128, 007 GROUP oGroup2 TO 161, 355 PROMPT "Descricao do material completa, de forma clara e concisa - Exemplo: PARAFUSO SEXTAVADO ACO 8.8 ROSCA INTEIRA M16 X 50" OF oDlg COLOR 0, 16777215 PIXEL
        @ 139, 016 MSGET oGet2 VAR cGet2 SIZE 313, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 169, 007 GROUP oGroup3 TO 197, 355 PROMPT "PART NUMBER (PN) - No. referencia ou codigo do material - Exemplo: Macaco Hidropneumatico Tipo Garrafa 12 Toneladas - PN LPK-207Q" OF oDlg COLOR 0, 16777215 PIXEL
        @ 181, 016 MSGET oGet3 VAR cGet3 SIZE 326, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 207, 007 GROUP oGroup4 TO 236, 355 PROMPT "LINK DE REFERENCIA - Informar o link do site do fabricante, exceto links de marketplaces - Exemplo:Mercado livre,Shoppe,Magazine luiza." OF oDlg COLOR 0, 16777215 PIXEL
        @ 218, 016 MSGET oGet4 VAR cGet4 SIZE 321, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 242, 007 GROUP oGroup5 TO 270, 355 PROMPT "UNIDADE DE MEDIDA - Unidade na qual o material e medido. - Exemplo: pecas, metros, litros." OF oDlg COLOR 0, 16777215 PIXEL
        @ 253, 016 MSGET oGet5 VAR cGet5 VALID FVldSAH(cGet5) SIZE 038, 010 OF oDlg COLORS 0, 16777215 PIXEL F3 "SAH"

        @ 276, 007 GROUP oGroup6 TO 305, 300 PROMPT "Urgente - Sim para cadastro ate 24h uteis. / Nao urgente ate 72h uteis." OF oDlg COLOR 0, 16777215 PIXEL

        oCombo := tComboBox():New(286,016,{|u|if(PCount()>0,cCombo:=u,cCombo)},;
            aItens,30,10,oDlg,,,;
            ,,,.T.,,,,,,,,,'cCombo')

        @ 286, 050 MSGET oGet7 VAR cGet7 SIZE 230, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 310, 007 GROUP oGroup7 TO 338, 300 PROMPT "APLICACAO - Onde o produto sera aplicado." OF oDlg COLOR 0, 16777215 PIXEL
        @ 320, 016 MSGET oGet6 VAR cGet6 SIZE 200, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 282, 310 BUTTON oButton2 PROMPT "Confirmar" SIZE 037, 012 OF oDlg PIXEL Action FGravDados(cGet2,cGet3,cGet4,cGet5,SubStr(cCombo,1,1),cGet6,cGet7)
        @ 302, 310 BUTTON oButton3 PROMPT "Cancelar"  SIZE 037, 012 OF oDlg PIXEL Action oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FVldSAH
Valida se a unidade de medida informada existe na tabela SAH.
/*/
//-------------------------------------------------------------------
Static Function FVldSAH(cGet5)

    Local lRet := .T.

    If !Empty(cGet5)
        lRet := ExistCpo("SAH", UPPER(cGet5))
    EndIf

Return(lRet)


//-------------------------------------------------------------------
/*/{Protheus.doc} fMSNewGe1
Inicializa o TCBrowse de pesquisa de produtos existentes (SB1).
/*/
//-------------------------------------------------------------------
Static Function fMSNewGe1()

    Local nX
    Local aFieldFill := {}
    Local aFields := {"B1_COD","B1_UM","B1_GRUPO","B1_POSIPI ","B1_DESC","B2_QATU"}

    DbSelectArea("SX3")
    SX3->(DbSetOrder(2))
    For nX := 1 To Len(aFields)
        If SX3->(DbSeek(aFields[nX]))
            Aadd(aHeaderEx, {AllTrim(X3Titulo()),SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,;
                             SX3->X3_USADO,SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CONTEXT,SX3->X3_CBOX,SX3->X3_RELACAO})
        EndIf
    Next nX

    For nX := 1 To Len(aFields)
        If DbSeek(aFields[nX])
            Aadd(aFieldFill, CriaVar(SX3->X3_CAMPO))
        EndIf
    Next nX

    Aadd(aColsEx, aFieldFill)

    oMSNewGe1 := TCBrowse():New( 34 , 11, 335, 80,,;
                                {'Codigo        ','U.M.','Grupo    ','NCM         ','Descricao','Saldo'},{20,04,10,15,100,50},;
                                oDlg,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )

    oMSNewGe1:SetArray(aColsEx)

    oMSNewGe1:bLine := {|| IIF(Len(aColsEx) > 0 .And. oMSNewGe1:nAt >= 1 .And. oMSNewGe1:nAt <= Len(aColsEx), ;
                            { aColsEx[oMSNewGe1:nAt,01],;
                              aColsEx[oMSNewGe1:nAt,02],;
                              aColsEx[oMSNewGe1:nAt,03],;
                              aColsEx[oMSNewGe1:nAt,04],;
                              aColsEx[oMSNewGe1:nAt,05],;
                              Transform(aColsEx[oMSNewGe1:nAt,06],PesqPict("SB2","B2_QATU"))}, ;
                            {"","","","","",""}) }

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FPesProd
Pesquisa produtos na tabela SB1 conforme texto digitado.
/*/
//-------------------------------------------------------------------
Static Function FPesProd(cGetPesq)

    Local cQuery := ""

    aColsEx := {}

    cQuery := "SELECT B1_COD, B1_DESC, B1_UM, B1_GRUPO, B1_POSIPI, "
    cQuery += "(SELECT B2_QATU FROM " + RetSqlName("SB2") + " WHERE D_E_L_E_T_ <> '*' AND "
    cQuery += "B2_FILIAL = '" + xFilial("SB2") + "' AND "
    cQuery += "B2_COD = B1_COD AND B2_LOCAL = B1_LOCPAD) AS B2_QATU "
    cQuery += "FROM " + RetSqlName("SB1") + " WHERE D_E_L_E_T_ <> '*' AND "
    cQuery += "B1_MSBLQL <> '1' AND "
    cQuery += "B1_FILIAL = '" + xFilial("SB1") + "' AND "
    cQuery += "B1_DESC LIKE '"+AllTrim(Upper(cGetPesq))+"%' "
    cQuery += "ORDER BY B1_DESC "

    TcQuery cQuery Alias "TRB" New

    dbSelectArea("TRB")
    dbGoTop()
    While !Eof()
        AADD(aColsEx,{TRB->B1_COD,TRB->B1_UM,TRB->B1_GRUPO,TRB->B1_POSIPI,TRB->B1_DESC,TRB->B2_QATU})
        dbSelectArea("TRB")
        dbSkip()
    EndDo

    dbSelectArea("TRB")
    dbCloseArea()

    cQuery := "SELECT B1_COD, B1_DESC, B1_UM, B1_GRUPO, B1_POSIPI, "
    cQuery += "(SELECT B2_QATU FROM " + RetSqlName("SB2") + " WHERE D_E_L_E_T_ <> '*' AND "
    cQuery += "B2_FILIAL = '" + xFilial("SB2") + "' AND "
    cQuery += "B2_COD = B1_COD AND B2_LOCAL = B1_LOCPAD) AS B2_QATU "
    cQuery += "FROM " + RetSqlName("SB1") + " WHERE D_E_L_E_T_ <> '*' AND "
    cQuery += "B1_MSBLQL <> '1' AND "
    cQuery += "B1_FILIAL = '" + xFilial("SB1") + "' AND "
    cQuery += "B1_DESC LIKE '%"+AllTrim(Upper(cGetPesq))+"%' AND "
    cQuery += "B1_DESC NOT LIKE '"+AllTrim(Upper(cGetPesq))+"%' "
    cQuery += "ORDER BY B1_DESC "

    TcQuery cQuery Alias "TRC" New

    dbSelectArea("TRC")
    dbGoTop()
    While !Eof()
        AADD(aColsEx,{TRC->B1_COD,TRC->B1_UM,TRC->B1_GRUPO,TRC->B1_POSIPI,TRC->B1_DESC,TRC->B2_QATU})
        dbSelectArea("TRC")
        dbSkip()
    EndDo

    dbSelectArea("TRC")
    dbCloseArea()

    oMSNewGe1:SetArray(aColsEx)

    oMSNewGe1:bLine := {|| IIF(Len(aColsEx) > 0 .And. oMSNewGe1:nAt >= 1 .And. oMSNewGe1:nAt <= Len(aColsEx), ;
                              { aColsEx[oMSNewGe1:nAt,01],;
                                aColsEx[oMSNewGe1:nAt,02],;
                                aColsEx[oMSNewGe1:nAt,03],;
                                aColsEx[oMSNewGe1:nAt,04],;
                                aColsEx[oMSNewGe1:nAt,05],;
                                Transform(aColsEx[oMSNewGe1:nAt,06],PesqPict("SB2","B2_QATU"))}, ;
                              {"","","","","",""}) }

    oMSNewGe1:Refresh()

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FGravDados
Valida e grava a solicitacao de cadastro de produto na tabela SZ3.
/*/
//-------------------------------------------------------------------
Static Function FGravDados(cDescProd,cPart,cLink,cUM,cUrg,cAplic,cMotivo)

    Local cCodId := Space(06)

    If Empty(cDescProd)
       MsgStop("A descricao do produto e obrigatoria!")
       Return
    EndIf

    If Empty(cUM)
       MsgStop("A unidade de medida e obrigatoria!")
       Return
    EndIf

    If Empty(cPart) .And. Empty(cLink)
       MsgStop("Informe o Part Number ou o link de referencia!")
       Return
    EndIf

    If Empty(cAPlic)
       MsgStop("A aplicacao e obrigatoria!")
       Return
    EndIf

    If 'S' $ cUrg .And. Empty(cMotivo)
       MsgStop("Se cadastro for urgente o motivo e obrigatorio!")
       Return
    EndIf

    If 'S' $ cUrg .And. !Empty(cMotivo) .And. Len(AllTrim(cMotivo)) <= 10
       MsgStop("Por favor, detalhe melhor o motivo da urgencia!")
       Return
    EndIf

    oDlg:End()

    cCodId := FSEQSZ3()

    dbSelectArea("SZ3")
    dbSetOrder(01)
    If Reclock("SZ3",.T.)
       Replace Z3_FILIAL With xFilial("SZ3")
       Replace Z3_ID     With cCodId
       Replace Z3_PN     With UPPER(cPart)
       Replace Z3_LINK   With cLink
       Replace Z3_UM     With UPPER(cUM)
       Replace Z3_DESCRI With UPPER(cDescProd)
       Replace Z3_STATUS With '0'
       Replace Z3_PRAZO  With cUrg
       Replace Z3_APLIC  With UPPER(cAplic)
       Replace Z3_USR    With Substr(cUsuario,7,15)
       Replace Z3_ZDTSOL With dDataBase
       If 'S' $ cUrg
          Replace Z3_MOTIVO With cMotivo
       EndIf
       MsUnlock()
    EndIf

    MsgInfo("Solicitacao de cadastro de produto registrada com sucesso!" + Chr(10) + Chr(13) + ;
            "Codigo: " + cCodId, "Sucesso")

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FSEQSZ3
Retorna o proximo sequencial disponivel para SZ3 (MAX(Z3_ID)+1).
/*/
//-------------------------------------------------------------------
Static Function FSEQSZ3()

    Local cAls   := GetNextAlias()
    Local cQuery := ""
    Local cMax   := "000000"
    Local cNext  := "000001"

    cQuery := "SELECT MAX(Z3_ID) AS MAXID FROM " + RetSQLName("SZ3") + " "
    cQuery += "WHERE D_E_L_E_T_ = ' ' AND Z3_FILIAL = '" + xFilial("SZ3") + "'"
    cQuery := ChangeQuery(cQuery)

    If Select(cAls) > 0
        (cAls)->(DbCloseArea())
    EndIf
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAls, .F., .T.)
    cMax := IIF(Empty((cAls)->MAXID), "000000", AllTrim((cAls)->MAXID))
    (cAls)->(DbCloseArea())

    If Empty(cMax) .Or. cMax == "000000"
        cNext := "000001"
    Else
        cNext := Soma1(cMax, 6)
    EndIf

Return(cNext)


//-------------------------------------------------------------------
/*/{Protheus.doc} CADLESZ3
Exibe a legenda do browse de solicitacao de cadastro de produto.
/*/
//-------------------------------------------------------------------
User Function CADLESZ3()

    FSyncZ3Rej(.T.)

    BRWLEGENDA("Solicitacao Cadastral","Legenda",;
        {{"BR_BRANCO","Solicitacao aguardando cadastro de produtos."},;
         {"BR_VERMELHO","Produto cadastrado (Aprovado)."             },;
         {"BR_PRETO" ,"Solicitacao rejeitada."                     }})

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} VALZ3STS
Valida o campo Z3_STATUS. Quando rejeitado, preenche Z3_DTREJ e
copia a data para Z3_ZDTSOL para exibir na mesma coluna do browse.
/*/
//-------------------------------------------------------------------
User Function VALZ3STS()

    Local cStatus := AllTrim(M->Z3_STATUS)

    If cStatus == '2'
        If Empty(M->Z3_DTREJ)
            M->Z3_DTREJ := dDataBase
        EndIf
        M->Z3_ZDTSOL := M->Z3_DTREJ
    ElseIf cStatus == '0' .And. !Empty(M->Z3_DTREJ)
        M->Z3_DTREJ := CtoD("  /  /  ")
    EndIf

Return(.T.)


//-------------------------------------------------------------------
/*/{Protheus.doc} FIXZ3REJ
Corrige registros rejeitados da SZ3 copiando Z3_DTREJ para Z3_ZDTSOL.
Use para atualizar registros ja rejeitados que ficaram sem data.
/*/
//-------------------------------------------------------------------
User Function FIXZ3REJ()

    FSyncZ3Rej(.F.)

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FSyncZ3Rej
Sincroniza a data dos registros rejeitados para aparecer no browse.
@param lSilencioso - Nao exibe mensagem quando .T.
/*/
//-------------------------------------------------------------------
Static Function FSyncZ3Rej(lSilencioso)

    Local aArea       := GetArea()
    Local cFilial     := xFilial("SZ3")
    Local nCorrigidos := 0
    Local dDataRej    := CtoD("  /  /  ")
    Local lAtualiza   := .F.

    Default lSilencioso := .T.

    If Select("SZ3") <= 0
        ChkFile("SZ3")
    EndIf

    DbSelectArea("SZ3")
    SZ3->(DbGoTop())

    While !SZ3->(Eof())
        If !SZ3->(Deleted()) .And. SZ3->Z3_FILIAL == cFilial .And. AllTrim(SZ3->Z3_STATUS) == '2'
            dDataRej  := IIF(Empty(SZ3->Z3_DTREJ), dDataBase, SZ3->Z3_DTREJ)
            lAtualiza := Empty(SZ3->Z3_DTREJ) .Or. Empty(SZ3->Z3_ZDTSOL) .Or. SZ3->Z3_ZDTSOL != dDataRej

            If lAtualiza .And. RecLock("SZ3", .F.)
                Replace Z3_DTREJ  With dDataRej
                Replace Z3_ZDTSOL With dDataRej
                MsUnlock()
                nCorrigidos++
            EndIf
        EndIf

        SZ3->(DbSkip())
    EndDo

    If !lSilencioso
        If nCorrigidos > 0
            MsgInfo(AllTrim(Str(nCorrigidos)) + " registro(s) rejeitado(s) atualizado(s).", "Correcao SZ3")
        Else
            MsgInfo("Nenhum registro rejeitado pendente de correcao.", "Correcao SZ3")
        EndIf
    EndIf

    RestArea(aArea)

Return nCorrigidos


//-------------------------------------------------------------------
/*/{Protheus.doc} CFGVALZ3
Grava "U_VALZ3STS()" no X3_VALID do campo Z3_STATUS. Execute uma
vez apos compilar para ativar o preenchimento automatico de Z3_DTREJ.
/*/
//-------------------------------------------------------------------
User Function CFGVALZ3()

    FCfgValZ3(.F.)

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FCfgValZ3
Configura a validacao do campo Z3_STATUS no SX3.
@param lSilencioso - Nao exibe mensagem quando .T.
/*/
//-------------------------------------------------------------------
Static Function FCfgValZ3(lSilencioso)

    Local aArea  := GetArea()
    Local lAchou := .F.
    Local cValid := ""
    Local cNovo  := ""

    Default lSilencioso := .F.

    DbSelectArea("SX3")
    DbSetOrder(2)

    If SX3->(DbSeek("Z3_STATUS"))
        While !SX3->(Eof()) .And. AllTrim(SX3->X3_CAMPO) == "Z3_STATUS"
            If AllTrim(SX3->X3_ARQUIVO) == "SZ3"
                lAchou := .T.
                If FieldPos("X3_VALID") > 0
                    cValid := AllTrim(SX3->X3_VALID)
                    If !("U_VALZ3STS()" $ Upper(cValid))
                        cNovo := IIF(Empty(cValid) .Or. cValid == "@!" .Or. cValid == ".T.", ;
                                     "U_VALZ3STS()", ;
                                     "U_VALZ3STS().And.(" + cValid + ")")
                        If Len(cNovo) <= Len(SX3->X3_VALID)
                            RecLock("SX3", .F.)
                                SX3->X3_VALID := cNovo
                            MsUnlock()
                        EndIf
                    EndIf
                EndIf
                Exit
            EndIf
            SX3->(DbSkip())
        EndDo
    EndIf

    If !lSilencioso
        If lAchou
            MsgInfo("X3_VALID configurado: Z3_STATUS -> U_VALZ3STS()" + Chr(13) + Chr(10) + ;
                    "O preenchimento automatico de Z3_DTREJ esta ativo.", "Configuracao Concluida")
        Else
            MsgStop("Campo Z3_STATUS nao localizado na SX3 para alias SZ3.", "Erro de Configuracao")
        EndIf
    EndIf

    RestArea(aArea)

Return lAchou


//-------------------------------------------------------------------
/*/{Protheus.doc} RELSZ3
Relatorio de Solicitacoes Cadastrais de Produto (SZ3).
/*/
//-------------------------------------------------------------------
User Function RELSZ3()

    Local oReport

    FSyncZ3Rej(.T.)
    oReport := RELSZ3_Def()

    If oReport != Nil
        oReport:PrintDialog()
    EndIf

Return


Static Function RELSZ3_Def()

    Local oReport
    Local oSection
    Local aPar    := {}
    Local aRet    := {}
    Local aStatus := {"Todos","Pendente","Aprovado","Rejeitado"}
    Local nSts    := 1

    aAdd(aPar, {5, "Status", nSts, aStatus, "", "", "", 60, .T.})

    If !ParamBox(aPar, "Filtro do Relatorio", @aRet)
        Return Nil
    EndIf

    nSts := aRet[1]

    oReport := TReport():New("RELSZ3", ;
        "Solicitacoes Cadastrais de Produto", "", ;
        {|oRep| RELSZ3_Print(oRep, nSts)}, ;
        "Relatorio de solicitacoes de cadastro de produto")

    oReport:SetLandscape(.F.)
    oReport:SetTotalInLine(.F.)

    oSection := TRSection():New(oReport, "Solicitacoes", {})

    TRCell():New(oSection, "ID",      "", "Codigo",      "@!",              6)
    TRCell():New(oSection, "DTSOL",   "", "Data",        "@D",             10)
    TRCell():New(oSection, "USR",     "", "Solicitante", "@!",             15)
    TRCell():New(oSection, "DESCRI",  "", "Descricao",   "@!",             40)
    TRCell():New(oSection, "UM",      "", "UM",          "@!",              4)
    TRCell():New(oSection, "URGENTE", "", "Urgente",     "@!",              3)
    TRCell():New(oSection, "STATUS",  "", "Status",      "@!",             10)

Return oReport


Static Function RELSZ3_Print(oReport, nSts)

    Local cAlias   := GetNextAlias()
    Local cQuery   := ""
    Local cFiltSts := ""
    Local oSection := oReport:Section(1)
    Local nCount   := 0
    Local cStsTxt  := ""

    Do Case
        Case nSts == 2
            cFiltSts := " AND Z3_STATUS = '0' "
        Case nSts == 3
            cFiltSts := " AND Z3_STATUS = '1' "
        Case nSts == 4
            cFiltSts := " AND Z3_STATUS = '2' "
        Otherwise
            cFiltSts := ""
    EndCase

    cQuery := " SELECT "
    cQuery += "   Z3_ID, "
    cQuery += "   Z3_ZDTSOL, "
    cQuery += "   Z3_USR, "
    cQuery += "   LEFT(Z3_DESCRI, 80) AS Z3_DESCRI, "
    cQuery += "   Z3_UM, "
    cQuery += "   Z3_PRAZO, "
    cQuery += "   Z3_STATUS "
    cQuery += " FROM " + RetSQLName("SZ3") + " "
    cQuery += " WHERE Z3_FILIAL = '" + xFilial("SZ3") + "' "
    cQuery += "   AND D_E_L_E_T_ = ' ' "
    cQuery += cFiltSts
    cQuery += " ORDER BY Z3_ZDTSOL DESC, Z3_ID "

    cQuery := ChangeQuery(cQuery)

    If Select(cAlias) > 0
        (cAlias)->(DbCloseArea())
    EndIf

    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    If (cAlias)->(Eof())
        (cAlias)->(DbCloseArea())
        MsgInfo("Nenhum registro encontrado para o filtro selecionado!", "Atencao")
        Return
    EndIf

    oSection:Init()

    While !(cAlias)->(Eof())

        Do Case
            Case (cAlias)->Z3_STATUS == '0'
                cStsTxt := "Pendente"
            Case (cAlias)->Z3_STATUS == '1'
                cStsTxt := "Aprovado"
            Case (cAlias)->Z3_STATUS == '2'
                cStsTxt := "Rejeitado"
            Otherwise
                cStsTxt := "?"
        EndCase

        oSection:Cell("ID"):SetValue(AllTrim((cAlias)->Z3_ID))
        oSection:Cell("DTSOL"):SetValue(StoD((cAlias)->Z3_ZDTSOL))
        oSection:Cell("USR"):SetValue(AllTrim((cAlias)->Z3_USR))
        oSection:Cell("DESCRI"):SetValue(AllTrim((cAlias)->Z3_DESCRI))
        oSection:Cell("UM"):SetValue(AllTrim((cAlias)->Z3_UM))
        oSection:Cell("URGENTE"):SetValue(IIF((cAlias)->Z3_PRAZO == 'S', 'Sim', 'Nao'))
        oSection:Cell("STATUS"):SetValue(cStsTxt)

        oSection:PrintLine()
        nCount++

        (cAlias)->(DbSkip())
        oReport:IncMeter()
    EndDo

    oSection:Finish()
    (cAlias)->(DbCloseArea())

    If nCount == 0
        MsgInfo("Nenhum registro encontrado!", "Atencao")
    EndIf

Return


//-------------------------------------------------------------------
// Wrappers User Function chamados pelo aRotina do mBrowse.
// Necessarios porque CADSZ3_Alt/Vis/Del sao Static.
//-------------------------------------------------------------------

User Function CPRDALT()
    DbSelectArea("SZ3")
    CADSZ3_Alt()
Return

User Function CPRDVIS()
    DbSelectArea("SZ3")
    CADSZ3_Vis()
Return

User Function CPRDDEL()
    DbSelectArea("SZ3")
    CADSZ3_Del()
Return
