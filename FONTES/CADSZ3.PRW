#Include "Protheus.ch"
#Include "TopConn.ch"

#Define ENTER  Chr(10) + Chr (13) // SALTO DE LINHA (CARRIAGE RETURN + LINE FEED)
#Define Z3_COBERT6     0.70       // Cobertura minima de peso (IDF) da Camada 6
#Define Z3_IDF_BUCKETS 1021       // Baldes do hash de frequencia das palavras
#Define Z3_PESOMAX     100        // Peso maximo de uma palavra no IDF da Camada 6
#Define Z3_FOLGA6      0.05       // Folga minima de nota entre o 1o e o 2o aprovado

// Cache da SB1 usado pela verificacao de duplicidade (ver FCarregaSB1Z3).
Static aCacheSB1 := {}

// Frequencia das palavras do cache, usada so pela Camada 6 (FCamada6Z3).
// Montada na primeira chamada da camada, nunca altera aCacheSB1.
Static aIdfZ3    := {}
Static nIdfDocZ3 := 0
Static lIdfOkZ3  := .F.

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
        {"Legenda"   , "U_CADLESZ3", 0, 6}, ;
        {"Verificar Cadastros", "U_CADVERZ3", 0, 7} }

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

    Local oButton1, oButton2, oButton3, oButton4
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
        FROM 000, 000 TO 800, 800 COLORS 0, 16777215 PIXEL

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
            ACTION FConfirmaZ3(.T., nRecNo, cGet2, cGet3, cGet4, cGet5, SubStr(cCombo,1,1), cGet6, cGet7)
        @ 302, 310 BUTTON oButton2 PROMPT "Cancelar"  SIZE 037, 012 OF oDlg PIXEL ;
            ACTION oDlg:End()
        @ 322, 310 BUTTON oButton4 PROMPT "Verificar Duplicidade" SIZE 080, 012 OF oDlg PIXEL ;
            ACTION FVerifDupZ3(cGet2, cGet3, .T.)

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

    Local oButton1, oButton2, oButton3, oButton4
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

    DEFINE MSDIALOG oDlg TITLE "Solicitacao de Cadastro de Produtos" FROM 000, 000 TO 800, 800 COLORS 0, 16777215 PIXEL

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

        @ 282, 310 BUTTON oButton2 PROMPT "Confirmar" SIZE 037, 012 OF oDlg PIXEL Action FConfirmaZ3(.F., 0, cGet2,cGet3,cGet4,cGet5,SubStr(cCombo,1,1),cGet6,cGet7)
        @ 302, 310 BUTTON oButton3 PROMPT "Cancelar"  SIZE 037, 012 OF oDlg PIXEL Action oDlg:End()
        @ 322, 310 BUTTON oButton4 PROMPT "Verificar Duplicidade" SIZE 080, 012 OF oDlg PIXEL Action FVerifDupZ3(cGet2,cGet3,.T.)

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

    // A validacao so tem o que fazer se o campo da data de rejeicao existir
    // na estrutura da SZ3 desta base. Sem ele, sai sem alterar nada.
    If FieldPos("Z3_DTREJ") == 0
        Return .T.
    EndIf

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

    // O campo Z3_DTREJ ainda nao foi criado na estrutura da SZ3 desta base.
    // Sem ele nao ha o que sincronizar, e ler SZ3->Z3_DTREJ derruba a thread
    // antes de abrir o browse. A rotina sai 0 quando o campo nao existe.
    If FieldPos("Z3_DTREJ") == 0
        If !lSilencioso
            MsgInfo("O campo Z3_DTREJ ainda nao existe na SZ3 desta base." + Chr(13) + Chr(10) + ;
                    "Crie o campo (tipo D, tamanho 8) no Configurador e reprocese a SZ3.", ;
                    "Sincronizacao indisponivel")
        EndIf

        RestArea(aArea)
        Return 0
    EndIf

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

    // Nao adianta instalar U_VALZ3STS() no X3_VALID de Z3_STATUS enquanto o
    // campo Z3_DTREJ que ela grava nao existir na SZ3 desta base.
    If Select("SZ3") <= 0
        ChkFile("SZ3")
    EndIf

    If SZ3->(FieldPos("Z3_DTREJ")) == 0
        If !lSilencioso
            MsgInfo("Validacao nao instalada: o campo Z3_DTREJ ainda nao existe na SZ3 desta base.", ;
                    "Configuracao")
        EndIf

        RestArea(aArea)
        Return
    EndIf

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


//-------------------------------------------------------------------
// VERIFICACAO DE DUPLICIDADE DE PRODUTO
// Percorre o cadastro (SB1) procurando itens ja existentes que sejam o
// mesmo produto do solicitado, mesmo escrito com as palavras em outra
// ordem. Evita cadastro duplicado na solicitacao cadastral.
//-------------------------------------------------------------------


//-------------------------------------------------------------------
/*/{Protheus.doc} FSemAcentoZ3
Remove acentos do texto, em maiusculo e em minusculo: a solicitacao pode ser
digitada em qualquer caixa e o descritivo da SB1 vem em maiusculo. Os codigos
sao montados com Chr() para manter o fonte em CP-1252 puro.
@param cTexto Texto original.
@return cRet Texto sem acentos.
@type    Static Function
@author  Suprimentos
@since   29/10/2026
/*/
//-------------------------------------------------------------------
Static Function FSemAcentoZ3(cTexto)

    Local cDe   := Chr(192) + Chr(193) + Chr(194) + Chr(195) + Chr(196) + ;
                   Chr(200) + Chr(201) + Chr(202) + Chr(203) + ;
                   Chr(204) + Chr(205) + Chr(206) + Chr(207) + ;
                   Chr(210) + Chr(211) + Chr(212) + Chr(213) + Chr(214) + ;
                   Chr(217) + Chr(218) + Chr(219) + Chr(220) + ;
                   Chr(199) + Chr(209) + ;
                   Chr(224) + Chr(225) + Chr(226) + Chr(227) + Chr(228) + ;
                   Chr(232) + Chr(233) + Chr(234) + Chr(235) + ;
                   Chr(236) + Chr(237) + Chr(238) + Chr(239) + ;
                   Chr(242) + Chr(243) + Chr(244) + Chr(245) + Chr(246) + ;
                   Chr(249) + Chr(250) + Chr(251) + Chr(252) + ;
                   Chr(231) + Chr(241)
    Local cPara := "AAAAAEEEEIIIIOOOOOUUUUCN" + ;
                   "aaaaaeeeeiiiiooooouuuucn"
    Local cRet  := cTexto
    Local nI    := 1

    For nI := 1 To Len(cDe)
        cRet := StrTran(cRet, SubStr(cDe, nI, 1), SubStr(cPara, nI, 1))
    Next nI

Return cRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FNormalZ3
Normaliza um descritivo para comparacao: maiusculo, sem acentos e sem
pontuacao. Ponto, hifen, aspa e grau desaparecem (O-RING vira ORING),
qualquer outro simbolo vira separador de palavra e a barra e preservada
porque 1/16 nao pode ser confundido com 116.
Barra com espaco de um lado separa palavra (MOTOR/ TRIFASICO), mas continua
dentro do token quando nao ha espaco (ECJ/C3, 19982/220) e depois de C, P ou
S, que formam C/ (com), P/ (para) e S/ (sem). A checagem usa o texto ja
normalizado, porque parenteses e demais simbolos viram espaco ali.
Antes de tirar a pontuacao a fracao mista e juntada por FJuntaMistoZ3()
(2 1/2 vira 2.1/2) e os numeros passam por FCanonNumZ3(), que iguala
virgula e ponto sem nunca transformar 2,5 em 25 nem 1.300 em 1.3.
Depois disso duas medidas iguais passam a ser escritas do mesmo jeito:
  5/8POLX3POL e 5/8"X3" viram 5/8 X 3 (polegada por extenso sai e o X
  colado entre numeros vira separador).
@param cTexto Texto original.
@return cRet Texto normalizado, com espacos simples.
@type    Static Function
@author  Suprimentos
@since   29/10/2026
/*/
//-------------------------------------------------------------------
Static Function FNormalZ3(cTexto)

    Local cRet   := ""
    Local cOut   := ""
    Local cAux   := ""
    Local cAnt   := ""
    Local cPos   := ""
    Local cUlt   := ""
    Local cOk    := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/"
    Local cGruda := "-'" + Chr(34) + Chr(176)
    Local nI     := 1

    If Empty(cTexto)
        Return ""
    EndIf

    cRet := Upper(AllTrim(FSemAcentoZ3(cTexto)))
    cRet := FJuntaMistoZ3(cRet)
    cRet := FCanonNumZ3(cRet)

    For nI := 1 To Len(cRet)
        cAux := SubStr(cRet, nI, 1)
        cAnt := ""
        cPos := ""
        cUlt := SubStr(cOut, Len(cOut), 1)
        If nI > 1
            cAnt := SubStr(cRet, nI - 1, 1)
        EndIf
        If nI < Len(cRet)
            cPos := SubStr(cRet, nI + 1, 1)
        EndIf

        // Hifen, apostrofo, aspa e grau somem sem separar a palavra.
        If At(cAux, cGruda) == 0
            // O ponto sobrevive apenas dentro do numero: 1.1/16 fica diferente
            // de 11/16, e um ponto solto vira separador de palavra.
            If cAux == "." .And. cAnt $ "0123456789" .And. cPos $ "0123456789"
                cOut += cAux
            ElseIf cAux == "/" .And. (Empty(cUlt) .Or. cUlt == " " .Or. ;
               Empty(cPos) .Or. cPos == " ") .And. ;
               !(cUlt == "C" .Or. cUlt == "P" .Or. cUlt == "S")
                // Barra solta separa palavra; depois de C, P ou S ela fica,
                // porque C/, P/ e S/ sao conectivos.
                cOut += " "
            ElseIf At(cAux, cOk) > 0
                cOut += cAux
            Else
                cOut += " "
            EndIf
        EndIf
    Next nI

    Do While At("  ", cOut) > 0
        cOut := StrTran(cOut, "  ", " ")
    EndDo

    cOut := FSeparaCPZ3(AllTrim(cOut))
    cOut := FSemPolegZ3(cOut)
    cOut := FSeparaXZ3(cOut)
    cOut := FJuntaCatZ3(cOut)

Return AllTrim(cOut)


//-------------------------------------------------------------------
/*/{Protheus.doc} FJuntaCatZ3
Junta a categoria de cabo escrita com espaco: CAT 5E e CAT5E sao a mesma
norma e o catalogo grava das duas formas, entao sem juntar o Part Number
CAT5E nao encontra o item cadastrado como "CAT 5E". A lista e fechada e so
vale para as categorias de cabo 5, 5E, 6, 6A, 7 e 8 logo depois de CAT.
@param cTexto Texto normalizado por FNormalZ3().
@return cRet Texto com a categoria junta.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FJuntaCatZ3(cTexto)

    Local aCat := {"5E", "5", "6A", "6", "7", "8"}
    Local aTok := StrTokArr(cTexto, " ")
    Local aOut := {}
    Local cRet := ""
    Local nI   := 1

    If Len(aTok) < 2
        Return cTexto
    EndIf

    While nI <= Len(aTok)
        If aTok[nI] == "CAT" .And. nI < Len(aTok) .And. ;
           AScan(aCat, aTok[nI + 1]) > 0
            AAdd(aOut, "CAT" + aTok[nI + 1])
            nI := nI + 2
        Else
            AAdd(aOut, aTok[nI])
            nI := nI + 1
        EndIf
    EndDo

    For nI := 1 To Len(aOut)
        cRet += aOut[nI]
        If nI < Len(aOut)
            cRet += " "
        EndIf
    Next nI

Return cRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FJuntaMistoZ3
Junta a fracao mista de polegada numa forma unica: 2-1/2, 2 1/2 e 2.1/2
viram 2.1/2 antes da canonizacao dos numeros.
O inteiro tem de um a tres digitos, o numerador de um a dois e o
denominador tem de ser 2, 4, 8, 16, 32 ou 64, com o numerador menor que o
denominador (300/5A nao e fracao). O caractere imediatamente antes do
inteiro nao pode ser digito, ponto, virgula ou barra, para 8.8 1/2
continuar sendo o aco 8.8 e a medida 1/2 separados.
@param cTexto Texto em maiusculo e sem acentos.
@return cRet Texto com a fracao mista na forma inteiro.numerador/denominador.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FJuntaMistoZ3(cTexto)

    Local aDen  := {"2", "4", "8", "16", "32", "64"}
    Local cRet  := ""
    Local cAnt  := ""
    Local cSep  := ""
    Local cInt  := ""
    Local cNum  := ""
    Local cDen  := ""
    Local cPst  := ""
    Local lOk   := .F.
    Local nI    := 1
    Local nDig  := 0
    Local nNum  := 0
    Local nD    := 1
    Local nBase := 0
    Local nPos  := 0

    Do While nI <= Len(cTexto)
        lOk  := .F.
        cAnt := ""
        If nI > 1
            cAnt := SubStr(cTexto, nI - 1, 1)
        EndIf

        If (Empty(cAnt) .Or. !(cAnt $ "0123456789.,/")) .And. ;
           SubStr(cTexto, nI, 1) $ "0123456789"
            nDig := 0
            Do While nDig < 4 .And. nI + nDig <= Len(cTexto) .And. ;
               SubStr(cTexto, nI + nDig, 1) $ "0123456789"
                nDig += 1
            EndDo

            cSep := SubStr(cTexto, nI + nDig, 1)
            // Separador entre o inteiro e o numerador: espaco, ponto ou hifen.
            If nDig >= 1 .And. nDig <= 3 .And. !Empty(cSep) .And. ;
               At(cSep, " .-") > 0

                nNum  := 0
                nBase := nI + nDig + 1
                Do While nNum < 2 .And. nBase + nNum <= Len(cTexto) .And. ;
                   SubStr(cTexto, nBase + nNum, 1) $ "0123456789"
                    nNum += 1
                EndDo

                If nNum > 0 .And. SubStr(cTexto, nBase + nNum, 1) == "/"
                    nPos := nBase + nNum + 1
                    For nD := 1 To Len(aDen)
                        If SubStr(cTexto, nPos, Len(aDen[nD])) == aDen[nD]
                            cPst := SubStr(cTexto, nPos + Len(aDen[nD]), 1)
                            If Empty(cPst) .Or. !(cPst $ "0123456789/")
                                cInt := SubStr(cTexto, nI, nDig)
                                cNum := SubStr(cTexto, nBase, nNum)
                                cDen := aDen[nD]
                                If Val(cNum) < Val(cDen)
                                    cRet += cInt + "." + cNum + "/" + cDen
                                    nI   += nDig + nNum + Len(cDen) + 2
                                    lOk  := .T.
                                EndIf
                                Exit
                            EndIf
                        EndIf
                    Next nD
                EndIf
            EndIf
        EndIf

        If !lOk
            cRet += SubStr(cTexto, nI, 1)
            nI   += 1
        EndIf
    EndDo

Return cRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FCanonNumZ3
Reescreve cada numero do texto numa forma canonica, preservando o valor.
Sequencias de digitos com ponto ou virgula sao isoladas e entregues a
FNumRunZ3(); o resto do texto passa intacto.
@param cTexto Texto ja em maiusculo e sem acentos.
@return cRet Texto com os numeros canonizados.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FCanonNumZ3(cTexto)

    Local cRet := ""
    Local cRun := ""
    Local nI   := 1

    Do While nI <= Len(cTexto)
        If SubStr(cTexto, nI, 1) $ "0123456789"
            cRun := ""
            Do While nI <= Len(cTexto) .And. SubStr(cTexto, nI, 1) $ "0123456789.,"
                cRun += SubStr(cTexto, nI, 1)
                nI   += 1
            EndDo
            cRet += FNumRunZ3(cRun)
        Else
            cRet += SubStr(cTexto, nI, 1)
            nI   += 1
        EndIf
    EndDo

Return cRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FNumRunZ3
Canoniza uma sequencia de digitos com ponto e/ou virgula. A virgula e
tratada como separador decimal (2,5 vira 2.5) e o ponto com tres digitos
como separador de milhar (1.300 vira 1300, mas 0.750 continua 0.75).
Agrupamento que nao fecha com milhar volta intacto: juntar os digitos de
um codigo de fabricante seria pior do que deixar os separadores virarem
divisao de palavras.
@param cRun Sequencia de digitos, pontos e virgulas.
@return cRet Numero canonico, ou a propria sequencia quando ambigua.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FNumRunZ3(cRun)

    Local nVir  := 0
    Local nPto  := 0
    Local nPos  := 0
    Local cSep  := ""
    Local cInt  := ""
    Local cFrac := ""
    Local cMil  := ""

    nVir := Len(cRun) - Len(StrTran(cRun, ",", ""))
    nPto := Len(cRun) - Len(StrTran(cRun, ".", ""))

    If nVir == 0 .And. nPto == 0
        // Inteiro puro: zero a esquerda nao muda a quantidade (02 FUROS e
        // 2 FUROS). So remove enquanto sobrar digito, para o "0" sozinho
        // continuar sendo zero.
        Do While Len(cRun) > 1 .And. SubStr(cRun, 1, 1) == "0"
            cRun := SubStr(cRun, 2)
        EndDo
        Return cRun
    EndIf

    // Ponto e virgula no mesmo numero: um dos dois esta agrupando milhar.
    If nVir > 0 .And. nPto > 0
        If nVir == 1
            nPos  := At(",", cRun)
            cInt  := SubStr(cRun, 1, nPos - 1)
            cFrac := SubStr(cRun, nPos + 1)
            cMil  := FMilharZ3(cInt, ".")
            If !Empty(cMil) .And. FEhDigZ3(cFrac)
                cFrac := FZeraFracZ3(cFrac)
                If Empty(cFrac)
                    Return cMil
                EndIf
                Return cMil + "." + cFrac
            EndIf
        EndIf

        If nPto == 1
            nPos  := At(".", cRun)
            cInt  := SubStr(cRun, 1, nPos - 1)
            cFrac := SubStr(cRun, nPos + 1)
            cMil  := FMilharZ3(cInt, ",")
            If !Empty(cMil) .And. FEhDigZ3(cFrac)
                cFrac := FZeraFracZ3(cFrac)
                If Empty(cFrac)
                    Return cMil
                EndIf
                Return cMil + "." + cFrac
            EndIf
        EndIf

        Return cRun
    EndIf

    If nVir > 0
        cSep := ","
    Else
        cSep := "."
    EndIf

    nPos  := At(cSep, cRun)
    cInt  := SubStr(cRun, 1, nPos - 1)
    cFrac := SubStr(cRun, nPos + 1)

    // Mais de um ponto: agrupamento de milhar ou codigo lido com pontos
    // (71.7.54237 vira 71754237). Virgula repetida e lista de medidas
    // (6,8,10) e fica intacta; ponto no fim (2.5.) tambem, porque ali o
    // separador pode ser decimal seguido de ponto final.
    If Len(cRun) - Len(StrTran(cRun, cSep, "")) > 1
        cMil := FMilharZ3(cRun, cSep)
        If !Empty(cMil)
            Return cMil
        EndIf
        If cSep == "." .And. At("..", cRun) == 0 .And. SubStr(cRun, Len(cRun), 1) != "."
            Return StrTran(cRun, ".", "")
        EndIf
        Return cRun
    EndIf

    If Empty(cFrac)
        Return cInt
    EndIf

    // Ponto com tres digitos e milhar (1.300 = 1300); zero na frente (0.750)
    // e decimal, e a virgula nunca vira milhar aqui.
    If cSep == "." .And. Len(cFrac) == 3 .And. !Empty(cInt) .And. cInt != "0"
        Return cInt + cFrac
    EndIf

    // Ponto unico com um lado de cinco digitos ou mais e o outro de no maximo
    // dois e codigo de fabricante lido com ponto (7175423.7 e 7.1754237 viram
    // 71754237): medida decimal nao tem essa assimetria. So o ponto; a virgula
    // continua sendo sempre decimal.
    If cSep == "." .And. FEhDigZ3(cFrac)
        If (Len(cInt) >= 5 .And. Len(cFrac) <= 2) .Or. ;
           (Len(cFrac) >= 5 .And. Len(cInt) <= 2)
            Return cInt + cFrac
        EndIf
    EndIf

    If Empty(cInt)
        cInt := "0"
    EndIf

    cFrac := FZeraFracZ3(cFrac)

    If Empty(cFrac)
        Return cInt
    EndIf

Return cInt + "." + cFrac


//-------------------------------------------------------------------
/*/{Protheus.doc} FMilharZ3
Devolve os digitos de um numero agrupado em milhar (1.234.567 vira
1234567). Agrupamento invalido devolve vazio, e quem chamou decide o que
fazer com isso.
@param cTexto Numero com o separador de milhar.
@param cSep   Separador de milhar, ponto ou virgula.
@return cRet  Digitos sem separador, ou vazio quando o agrupamento nao fecha.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FMilharZ3(cTexto, cSep)

    Local aPart := StrTokArr(cTexto, cSep)
    Local cRet  := ""
    Local nI    := 1

    If Len(aPart) < 2
        Return ""
    EndIf

    If Empty(aPart[1]) .Or. Len(aPart[1]) > 3
        Return ""
    EndIf

    For nI := 2 To Len(aPart)
        If Len(aPart[nI]) != 3
            Return ""
        EndIf
    Next nI

    For nI := 1 To Len(aPart)
        cRet += aPart[nI]
    Next nI

    // StrTokArr descarta grupo vazio: 1..234 nao pode virar 1234.
    If Len(cRet) != Len(StrTran(cTexto, cSep, ""))
        Return ""
    EndIf

Return cRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FZeraFracZ3
Remove os zeros a direita da parte fracionaria: 2.50 vira 2.5 e 1.00 vira
1. O valor nao muda, so a grafia.
@param cFrac Parte fracionaria, somente digitos.
@return cFrac Parte fracionaria sem os zeros a direita.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FZeraFracZ3(cFrac)

    Do While Len(cFrac) > 0 .And. SubStr(cFrac, Len(cFrac), 1) == "0"
        cFrac := SubStr(cFrac, 1, Len(cFrac) - 1)
    EndDo

Return cFrac


//-------------------------------------------------------------------
/*/{Protheus.doc} FEhDigZ3
Informa se o texto tem pelo menos um caractere e e formado so por digitos.
@param cTexto Texto a conferir.
@return lRet .T. quando o texto e numerico e nao esta vazio.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FEhDigZ3(cTexto)

    Local nI := 1

    If Empty(cTexto)
        Return .F.
    EndIf

    For nI := 1 To Len(cTexto)
        If !(SubStr(cTexto, nI, 1) $ "0123456789")
            Return .F.
        EndIf
    Next nI

Return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} FEhNumZ3
Informa se o token e um numero, inteiro ou fracionario: 40, 5/8, 2.5 e
220/380 contam; 5/8X3 nao conta porque o X ja e outra palavra.
@param cTok Palavra a conferir.
@return lRet .T. quando a palavra e so digito, ponto e barra.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FEhNumZ3(cTok)

    Local cOk  := "0123456789./"
    Local lDig := .F.
    Local nI   := 1

    If Empty(cTok)
        Return .F.
    EndIf

    For nI := 1 To Len(cTok)
        If SubStr(cTok, nI, 1) $ "0123456789"
            lDig := .T.
        EndIf
        If !(SubStr(cTok, nI, 1) $ cOk)
            Return .F.
        EndIf
    Next nI

Return lDig


//-------------------------------------------------------------------
/*/{Protheus.doc} FSeparaCPZ3
Separa o "C/", o "P/" e o "S/" da palavra seguinte: C/MOTOR vira C/ MOTOR
e S/RR vira S/ RR. Sem isso, "C/ LOGO" e "C/LOGO" geram palavras diferentes,
e o "C" solto (condulete tipo C) tem de continuar sendo palavra de verdade.
O inicio do texto e a barra anterior tambem valem como inicio de palavra,
para C//P/ ficar separado.
@param cTexto Texto normalizado, com espacos simples.
@return cRet Mesmo texto, com espaco depois de C/, P/ e S/ antes de letra.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FSeparaCPZ3(cTexto)

    Local cAlfa := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    Local cRet  := ""
    Local cAnt  := ""
    Local cPos  := ""
    Local lIni  := .F.
    Local nI    := 1

    For nI := 1 To Len(cTexto)
        cRet += SubStr(cTexto, nI, 1)

        If SubStr(cTexto, nI, 1) == "/" .And. nI > 1
            cAnt := SubStr(cTexto, nI - 1, 1)
            cPos := SubStr(cTexto, nI + 1, 1)
            lIni := nI == 2
            If nI > 2
                lIni := SubStr(cTexto, nI - 2, 1) == " " .Or. ;
                        SubStr(cTexto, nI - 2, 1) == "/"
            EndIf

            If lIni .And. (cAnt == "C" .Or. cAnt == "P" .Or. cAnt == "S") .And. ;
               !Empty(cPos) .And. cPos $ cAlfa
                cRet += " "
            EndIf
        EndIf
    Next nI

Return cRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FSemPolegZ3
Remove a unidade polegada escrita por extenso quando ela acompanha um
numero: 5/8POL vira 5/8, 5/8POLX3POL vira 5/8X3 e 2POLEGADAS vira 2.
POL dentro de palavra (POLIURETANO, POLO) nao e tocado, porque a remocao
exige numero imediatamente antes e fim, espaco, numero ou X depois.
@param cTexto Texto normalizado por FNormalZ3().
@return cRet Texto sem a unidade por extenso.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FSemPolegZ3(cTexto)

    Local aUnid  := {"POLEGADAS", "POLEGADA", "POLEG", "POL"}
    Local cRet   := ""
    Local cAnt   := ""
    Local cPos   := ""
    Local nI     := 1
    Local nU     := 1
    Local lAchou := .F.

    Do While nI <= Len(cTexto)
        lAchou := .F.

        For nU := 1 To Len(aUnid)
            If SubStr(cTexto, nI, Len(aUnid[nU])) == aUnid[nU]
                cAnt := ""
                If nI > 1
                    cAnt := SubStr(cTexto, nI - 1, 1)
                EndIf
                cPos := SubStr(cTexto, nI + Len(aUnid[nU]), 1)

                If cAnt $ "0123456789" .And. (Empty(cPos) .Or. cPos $ " 0123456789X")
                    nI     += Len(aUnid[nU])
                    lAchou := .T.
                    Exit
                EndIf
            EndIf
        Next nU

        If !lAchou
            cRet += SubStr(cTexto, nI, 1)
            nI   += 1
        EndIf
    EndDo

Return cRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FSeparaXZ3
Separa o X colado entre numeros: 5/8X3 vira 5/8 X 3. Assim a medida
escrita com e sem espaco em volta do X gera as mesmas palavras-chave.
Tambem separa o X que vem depois de espaco ou no inicio e antes de digito
(X847), porque 1778 X847 MM e a mesma medida escrita de outro jeito.
@param cTexto Texto normalizado por FSemPolegZ3().
@return cRet Texto com o X isolado entre os numeros.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FSeparaXZ3(cTexto)

    Local cRet := ""
    Local cAux := ""
    Local cAnt := ""
    Local cPos := ""
    Local nI   := 1

    For nI := 1 To Len(cTexto)
        cAux := SubStr(cTexto, nI, 1)
        cAnt := ""
        cPos := ""
        If nI > 1
            cAnt := SubStr(cTexto, nI - 1, 1)
        EndIf
        If nI < Len(cTexto)
            cPos := SubStr(cTexto, nI + 1, 1)
        EndIf

        // X antes de digito e separador quando esta entre numeros, depois de
        // espaco ou no comeco do texto. X no meio de palavra (POLIURETANO)
        // nao tem digito depois e fica intacto.
        If cAux == "X" .And. cPos $ "0123456789" .And. ;
           (cAnt $ "0123456789" .Or. Empty(cAnt) .Or. cAnt == " ")
            cRet += " X "
        Else
            cRet += cAux
        EndIf
    Next nI

    Do While At("  ", cRet) > 0
        cRet := StrTran(cRet, "  ", " ")
    EndDo

Return AllTrim(cRet)


//-------------------------------------------------------------------
/*/{Protheus.doc} FTokensZ3
Quebra o texto ja normalizado em palavras unicas e ordenadas, descartando
os artigos e conectivos que nao identificam o produto. Com as palavras
ordenadas, a ordem digitada deixa de importar na comparacao.
Antes de guardar a palavra, seis equivalencias homologadas sao aplicadas:
  1 - numero seguido de unidade cola: 40 MM e 40MM viram 40MM
  2 - unidade por extenso vira simbolo: 20 LITROS e 20L viram 20L
  3 - abreviacao inequivoca e trocada pelo termo completo: PARAF = PARAFUSO
  4 - plural volta ao singular: FUROS = FURO
  5 - genero volta ao masculino: SEXTAVADA = SEXTAVADO
  6 - norma de material cola no numero: SAE 1020 e SAE1020 viram SAE1020
O item 6 e o que impede a qualidade do aco (SAE 1020, ACO 1045) de ser
contada como medida na terceira camada de duplicidade.
O "C" solto deixou de ser conectivo: ele identifica o condulete tipo C, e
so o "C/" (com) continua sendo descartado. O "COM/" colado tambem e
conectivo. O "S/" e o "SEM/", que significam "sem", viram o token SEM em
vez de sumir, porque C/ LONA e S/ LONA sao cadastros diferentes e nao podem
gerar a mesma chave. O "N" de "No" seguido de numero e marcador de numero,
nao designador, e sai da chave.
@param cNormal Texto normalizado por FNormalZ3().
@return aTokens Vetor de palavras, sem repeticao, em ordem alfabetica.
@type    Static Function
@author  Suprimentos
@since   29/10/2026
/*/
//-------------------------------------------------------------------
Static Function FTokensZ3(cNormal)

    Local aTokens := {}
    Local aAux    := {}
    // CA e o marcador do Certificado de Aprovacao: uma descricao cita e a outra
    // nao, sem que o produto mude. O numero do certificado continua na chave.
    Local aStop   := FStopZ3()
    Local aUnid   := {"MM", "CM", "KM", "KG", "GR", "MG", "ML", "CV", ;
                      "KV", "KW", "RPM", "HZ", "BAR", "PSI", "LBS", ;
                      "MM2", "MM3", "M2", "M3", "BTU", "BTUS", "WATT", ;
                      "WATTS", "KCAL", "CAL", "NM", "M", "L", "G", "V", "W", ;
                      "UN", "UND", "PC", "PCS", "PECA", "PECAS"}
    // Unidade por extenso: 20 LITROS e 20L viram o mesmo token 20L.
    Local aAlias  := {"LITRO", "LITROS", "METRO", "METROS", "QUILO", "QUILOS", ;
                      "QUILOGRAMA", "QUILOGRAMAS", "GRAMA", "GRAMAS", ;
                      "MILILITRO", "MILILITROS", "MILIMETRO", "MILIMETROS", ;
                      "CENTIMETRO", "CENTIMETROS", "UNIDADE", "UNIDADES", ;
                      "UNID", "LT", "LTS"}
    Local aSimbol := {"L", "L", "M", "M", "KG", "KG", "KG", "KG", "G", "G", ;
                      "ML", "ML", "MM", "MM", "CM", "CM", "UN", "UN", "UN", ;
                      "L", "L"}
    // Genero fechado (feminino -> masculino). So entra palavra cujo feminino
    // nao muda o significado; PONTEIRA, RODA, PONTA e LIXA ficam de fora.
    Local aFem    := FListaFemZ3()
    Local aMasc   := FListaMascZ3()
    // Prefixo de norma de material. O numero que vem depois e a qualidade do
    // aco (SAE 1020, AISI 4140, ACO 1045), nao uma medida: cola no prefixo para
    // a terceira camada nao contar como medida a mais.
    Local aNoma   := {"SAE", "AISI", "ASTM", "DIN", "ABNT", "NBR", "API", ;
                      "ISO", "ANSI", "ASME", "AWS", "JIS", "UNS", "NACE", ;
                      "AFNOR", "ACO"}
    Local cTok    := ""
    Local cProx   := ""
    Local lGrudou := .F.
    Local nAlias  := 0
    Local nI      := 1

    If Empty(cNormal)
        Return aTokens
    EndIf

    aAux := StrTokArr(cNormal, " ")

    Do While nI <= Len(aAux)
        cTok  := AllTrim(aAux[nI])
        cProx := ""
        If nI < Len(aAux)
            cProx := AllTrim(aAux[nI + 1])
        EndIf

        // COM/ colado e conectivo. S/ e SEM/ significam "sem" e viram o token
        // SEM, senao "C/ LONA" e "S/ LONA" (cadastros distintos) empatariam.
        If SubStr(cTok, 1, 4) == "COM/" .And. Len(cTok) > 4
            cTok := SubStr(cTok, 5)
        EndIf
        If cTok == "S/"
            cTok := "SEM"
        EndIf
        If SubStr(cTok, 1, 4) == "SEM/" .And. Len(cTok) > 4
            If AScan(aTokens, "SEM") == 0
                AAdd(aTokens, "SEM")
            EndIf
            cTok := SubStr(cTok, 5)
        EndIf

        // "No 38" vira N + 38: o N e marcador de numero, nao designador.
        If cTok == "N" .And. !Empty(cProx) .And. SubStr(cProx, 1, 1) $ "0123456789"
            cTok := ""
        EndIf

        If !Empty(cTok) .And. FEhNumZ3(cTok)
            nAlias := AScan(aAlias, cProx)
            If nAlias > 0
                cTok := cTok + aSimbol[nAlias]
                nI   += 1
            ElseIf AScan(aUnid, cProx) > 0
                cTok := cTok + cProx
                nI   += 1
            EndIf
        EndIf

        If !Empty(cTok) .And. AScan(aStop, cTok) == 0
            cTok   := FAbrevZ3(cTok)
            cTok   := FDobraZ3(cTok, aFem, aMasc)
            // Grau por extenso depois de numero e a unidade do simbolo de grau,
            // que FNormalZ3 ja descarta: "90 GRAUS" e "90" sao o mesmo token.
            If cTok == "GRAU" .And. Len(aTokens) > 0 .And. ;
               SubStr(aTokens[Len(aTokens)], 1, 1) $ "0123456789"
                cTok := ""
            EndIf
            // SAE 1020 e SAE1020 viram o mesmo token, e o numero da norma deixa
            // de ser contado como medida por FContidoNumZ3().
            lGrudou := .F.
            If Len(aTokens) > 0 .And. AScan(aNoma, aTokens[Len(aTokens)]) > 0 .And. ;
               FEhDigZ3(StrTran(cTok, ".", ""))
                aTokens[Len(aTokens)] := aTokens[Len(aTokens)] + cTok
                lGrudou := .T.
            EndIf
            If !lGrudou .And. !Empty(cTok) .And. AScan(aStop, cTok) == 0 .And. ;
               AScan(aTokens, cTok) == 0
                AAdd(aTokens, cTok)
            EndIf
        EndIf

        nI += 1
    EndDo

    ASort(aTokens)

Return aTokens


//-------------------------------------------------------------------
/*/{Protheus.doc} FStopZ3
Devolve a lista de palavras descartadas da chave: conectivos, artigos,
preposicoes, unidade por extenso e o marcador de Certificado de Aprovacao -
CA e CA'S, que a normalizacao escreve CAS. Fica fora de FTokensZ3() para
FCabecaZ3() usar exatamente a mesma lista.
@return aStop Vetor de palavras descartadas.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FStopZ3()

    Local aStop := {"DE", "DA", "DO", "DOS", "DAS", "NO", "NA", "NOS", ;
                    "EM", "COM", "C/", "PARA", "P/", "PRO", "AO", ;
                    "AOS", "AS", "OS", "O", "A", "UM", "UMA", ;
                    "POL", "POLEG", "POLEGADA", "POLEGADAS", "CA", ;
                    "CAS", "COM/"}

Return aStop


//-------------------------------------------------------------------
/*/{Protheus.doc} FListaFemZ3
Devolve a lista de adjetivos no feminino que FDobraZ3() converte para o
masculino. So entra palavra cujo feminino nao muda o significado; PONTEIRA,
RODA, PONTA e LIXA ficam de fora.
@return aFem Vetor de femininos.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FListaFemZ3()

    Local aFem := {"GALVANIZADA", "REFORCADA", "SINTETICA", "HIDRAULICA", ;
                   "MEDIA", "PLASTICA", "LIQUIDA", "BRANCA", "PRETA", ;
                   "QUADRADA", "ELETRONICA", "SEXTAVADA", "POLIDA", ;
                   "ENEGRECIDA", "ZINCADA", "CONICA", "ADESIVA", ;
                   "PNEUMATICA", "CILINDRICA", "ORGANICA", "VERMELHA", ;
                   "AMARELA", "DUPLA", "COMPLETA", "REVESTIDA", ;
                   "COLORIDA", "LONGA", "CURTA"}

Return aFem


//-------------------------------------------------------------------
/*/{Protheus.doc} FListaMascZ3
Devolve a lista de adjetivos no masculino, na mesma ordem de FListaFemZ3().
@return aMasc Vetor de masculinos.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FListaMascZ3()

    Local aMasc := {"GALVANIZADO", "REFORCADO", "SINTETICO", "HIDRAULICO", ;
                    "MEDIO", "PLASTICO", "LIQUIDO", "BRANCO", "PRETO", ;
                    "QUADRADO", "ELETRONICO", "SEXTAVADO", "POLIDO", ;
                    "ENEGRECIDO", "ZINCADO", "CONICO", "ADESIVO", ;
                    "PNEUMATICO", "CILINDRICO", "ORGANICO", "VERMELHO", ;
                    "AMARELO", "DUPLO", "COMPLETO", "REVESTIDO", ;
                    "COLORIDO", "LONGO", "CURTO"}

Return aMasc


//-------------------------------------------------------------------
/*/{Protheus.doc} FAbrevZ3
Troca a abreviacao homologada pelo termo completo. Sao duas listas
fechadas: abreviacao ambigua (EXT, INT, RED, PES) fica de fora, porque
aproximacao textual nao prova que o item e o mesmo. Cada trecho separado
por barra e tratado sozinho, para CONJ/ROLAM funcionar. Plural e genero
sao tratados depois, em FDobraZ3().
@param cTok Palavra vinda de FTokensZ3().
@return cRet Palavra no termo canonico.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FAbrevZ3(cTok)

    Local aDe    := {"PARAF", "ROLAM", "GALV", "MOT", "TUB", "CONJ", ;
                     "ELET", "FLEX", "POLOS", "UNIDADES", "METROS", ;
                     "LITROS", "PECAS", "DIAM"}
    Local aPara  := {"PARAFUSO", "ROLAMENTO", "GALVANIZADO", "MOTOR", "TUBO", ;
                     "CONJUNTO", "ELETRICO", "FLEXIVEL", "POLO", "UNIDADE", ;
                     "METRO", "LITRO", "PECA", "DIAMETRO"}
    Local aSeg   := {}
    Local cRet   := ""
    Local nPos   := 0
    Local nI     := 1

    If Empty(cTok)
        Return ""
    EndIf

    aSeg := StrTokArr(cTok, "/")

    If Len(aSeg) < 2
        nPos := AScan(aDe, cTok)
        If nPos > 0
            Return aPara[nPos]
        EndIf
        Return cTok
    EndIf

    For nI := 1 To Len(aSeg)
        If nI > 1
            cRet += "/"
        EndIf
        nPos := AScan(aDe, aSeg[nI])
        If nPos > 0
            cRet += aPara[nPos]
        Else
            cRet += aSeg[nI]
        EndIf
    Next nI

Return cRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FDobraZ3
Reduz plural e genero a uma forma unica: FUROS vira FURO e SEXTAVADA vira
SEXTAVADO. As duas listas sao fechadas. O plural so age em palavra de
letras, com quatro caracteres ou mais, terminada em S (nunca SS) e cujo
singular tenha tres letras ou mais: GAS e LAPIS ficam como estao. O genero
usa a lista declarada em FTokensZ3(), restrita a adjetivos que nao mudam o
significado da palavra.
@param cTok Palavra ja passada por FAbrevZ3().
@param aFem Lista de femininos.
@param aMasc Lista de masculinos, na mesma ordem de aFem.
@return cRet Palavra na forma canonica.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FDobraZ3(cTok, aFem, aMasc)

    Local nPos := 0

    cTok := FPluralZ3(cTok)

    nPos := AScan(aFem, cTok)
    If nPos > 0
        cTok := aMasc[nPos]
    EndIf

Return cTok


//-------------------------------------------------------------------
/*/{Protheus.doc} FCabecaZ3
Devolve a primeira palavra substantiva do descritivo, na ordem digitada:
o tipo do produto (CABO, CONECTOR, PNEU). Serve de corroboracao para a
camada de Part Number quando a chave tem um digito so, porque codigo com
um digito (CAT5E, IP68) e norma ou padrao tecnico e casa com a familia
inteira do catalogo.
@param cNormal Descritivo normalizado por FNormalZ3().
@return cCab Palavra canonica, ou vazio quando nao existe.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FCabecaZ3(cNormal)

    Local aStop := FStopZ3()
    Local aFem  := FListaFemZ3()
    Local aMasc := FListaMascZ3()
    Local aAux  := {}
    Local cTok  := ""
    Local nI    := 1

    If Empty(cNormal)
        Return ""
    EndIf

    aAux := StrTokArr(cNormal, " ")

    For nI := 1 To Len(aAux)
        cTok := AllTrim(aAux[nI])
        If !Empty(cTok) .And. AScan(aStop, cTok) == 0 .And. !FEhNumZ3(cTok)
            cTok := FAbrevZ3(cTok)
            If !Empty(cTok) .And. AScan(aStop, cTok) == 0
                Return FDobraZ3(cTok, aFem, aMasc)
            EndIf
        EndIf
    Next nI

Return ""


//-------------------------------------------------------------------
/*/{Protheus.doc} FPluralZ3
Devolve o singular homologado de uma palavra no plural. Palavra com
digito ou barra fica intacta, porque ali o S final faz parte de codigo ou
de fracao (2.5MM2S), nao de plural.
@param cTok Palavra em maiusculo.
@return cRet Palavra no singular, ou a propria palavra.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FPluralZ3(cTok)

    Local cSem := ""

    If Len(cTok) < 4
        Return cTok
    EndIf
    If SubStr(cTok, Len(cTok), 1) != "S"
        Return cTok
    EndIf
    If SubStr(cTok, Len(cTok) - 1, 2) == "SS"
        Return cTok
    EndIf
    If !FEhLetraZ3(cTok)
        Return cTok
    EndIf

    cSem := SubStr(cTok, 1, Len(cTok) - 1)
    If Len(cSem) < 3
        Return cTok
    EndIf

Return cSem


//-------------------------------------------------------------------
/*/{Protheus.doc} FEhLetraZ3
Informa se o texto tem apenas letras de A a Z, sem digito, barra ou
simbolo. Usado para nao dobrar plural em codigo de fabricante.
@param cTexto Texto a conferir.
@return lRet .T. quando so ha letras e o texto nao esta vazio.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FEhLetraZ3(cTexto)

    Local nI := 1

    If Empty(cTexto)
        Return .F.
    EndIf

    For nI := 1 To Len(cTexto)
        If !(SubStr(cTexto, nI, 1) $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
            Return .F.
        EndIf
    Next nI

Return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} FChaveZ3
Monta a chave canonica do descritivo: as palavras ordenadas unidas por
barra vertical. Duas descricoes com a mesma chave sao o mesmo produto
escrito em ordens diferentes.
@param aTokens Vetor vindo de FTokensZ3().
@return cChave Chave canonica.
@type    Static Function
@author  Suprimentos
@since   29/10/2026
/*/
//-------------------------------------------------------------------
Static Function FChaveZ3(aTokens)

    Local cChave := ""
    Local nI     := 1

    For nI := 1 To Len(aTokens)
        cChave += aTokens[nI] + "|"
    Next nI

Return cChave


//-------------------------------------------------------------------
/*/{Protheus.doc} FSepTokZ3
Separa os tokens em palavras e numeros. Conta como numero o token que
comeca com digito, o que inclui a medida colada na unidade (40MM, 1L) e a
fracao com barra (5/8): nos dois casos o digito e o que identifica o item.
@param aTokens Vetor de tokens vindo de FTokensZ3().
@param lQuer   .T. devolve os numeros, .F. devolve as palavras.
@return aRet Vetor filtrado, na mesma ordem.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FSepTokZ3(aTokens, lQuer)

    Local aRet := {}
    Local cTok := ""
    Local lNum := .F.
    Local nI   := 1

    For nI := 1 To Len(aTokens)
        cTok := aTokens[nI]
        lNum := SubStr(cTok, 1, 1) $ "0123456789"

        If lNum == lQuer
            AAdd(aRet, cTok)
        EndIf
    Next nI

Return aRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FPrefNumZ3
Devolve o comprimento do prefixo numerico do token: o trecho que comeca em
digito e segue com digito, ponto ou barra. 40MM tem prefixo 2, 5/8 tem 3 e
LPK207Q tem 0.
@param cTok Token vindo de FTokensZ3().
@return nLen Comprimento do prefixo numerico, ou 0 quando nao comeca em digito.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FPrefNumZ3(cTok)

    Local cAux := ""
    Local nLen := 0
    Local nI   := 1

    Do While nI <= Len(cTok)
        cAux := SubStr(cTok, nI, 1)
        If nI == 1 .And. !(cAux $ "0123456789")
            Return 0
        EndIf
        If !(cAux $ "0123456789./")
            Exit
        EndIf
        nLen := nI
        nI   += 1
    EndDo

Return nLen


//-------------------------------------------------------------------
/*/{Protheus.doc} FNucleoNumZ3
Devolve a parte numerica do token, sem ponto ou barra sobrando no fim e sem
zero a esquerda: 40MM vira 40, 2.5MM2 vira 2.5, 5/8 vira 5/8 e 012 vira 12.
E o valor da medida, separado da unidade.
@param cTok Token vindo de FTokensZ3().
@return cRet Nucleo numerico, ou vazio quando o token nao comeca em digito.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FNucleoNumZ3(cTok)

    Local nLen := FPrefNumZ3(cTok)

    If nLen == 0
        Return ""
    EndIf

    cTok := SubStr(cTok, 1, nLen)

    Do While Len(cTok) > 1 .And. (SubStr(cTok, Len(cTok), 1) == "/" .Or. ;
                                  SubStr(cTok, Len(cTok), 1) == ".")
        cTok := SubStr(cTok, 1, Len(cTok) - 1)
    EndDo

    // Zero a esquerda nao muda o valor: TR-08 tem a medida 8, e 012 e o
    // mesmo numero 12. So vale para nucleo inteiro, senao 0.5 perderia o 0.
    If FEhDigZ3(cTok)
        Do While Len(cTok) > 1 .And. SubStr(cTok, 1, 1) == "0"
            cTok := SubStr(cTok, 2)
        EndDo
    EndIf

Return cTok


//-------------------------------------------------------------------
/*/{Protheus.doc} FUnidNumZ3
Devolve a unidade que vem depois do numero: 40MM vira MM, 1L vira L e
5/8 vira vazio. Unidade por extenso vira simbolo (20LITROS e 20L) e o X
solto depois do numero e separador de medida, nao unidade (320X).
@param cTok Token vindo de FTokensZ3().
@return cRet Unidade, ou vazio quando o token nao tem unidade.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FUnidNumZ3(cTok)

    Local aDe   := {"LITRO", "LITROS", "METRO", "METROS", "QUILO", "QUILOS", ;
                    "QUILOGRAMA", "QUILOGRAMAS", "GRAMA", "GRAMAS", ;
                    "MILILITRO", "MILILITROS", "MILIMETRO", "MILIMETROS", ;
                    "CENTIMETRO", "CENTIMETROS", "UNIDADE", "UNIDADES", "UNID"}
    Local aPa   := {"L", "L", "M", "M", "KG", "KG", "KG", "KG", "G", "G", ;
                    "ML", "ML", "MM", "MM", "CM", "CM", "UN", "UN", "UN"}
    Local cUni  := ""
    Local nAli  := 0
    Local nLen  := FPrefNumZ3(cTok)

    If nLen == 0
        Return ""
    EndIf

    cUni := SubStr(cTok, nLen + 1)

    If cUni == "X"
        Return ""
    EndIf

    nAli := AScan(aDe, cUni)
    If nAli > 0
        cUni := aPa[nAli]
    EndIf

Return cUni


//-------------------------------------------------------------------
/*/{Protheus.doc} FEhUnidZ3
Informa se o texto e uma unidade de medida homologada. A lista e a mesma
usada em FTokensZ3() para colar o numero na unidade. Inclui a unidade de
contagem (4 e 4UN sao a mesma quantidade).
@param cUnid Texto a conferir.
@return lRet .T. quando o texto esta na lista de unidades.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FEhUnidZ3(cUnid)

    Local aUnid := {"MM", "CM", "KM", "KG", "GR", "MG", "ML", "CV", ;
                    "KV", "KW", "RPM", "HZ", "BAR", "PSI", "LBS", ;
                    "MM2", "MM3", "M2", "M3", "BTU", "BTUS", "WATT", ;
                    "WATTS", "KCAL", "CAL", "NM", "M", "L", "G", "V", "W", ;
                    "UN", "UND", "PC", "PCS", "PECA", "PECAS"}

Return AScan(aUnid, cUnid) > 0


//-------------------------------------------------------------------
/*/{Protheus.doc} FNumMesmoZ3
Informa se dois tokens numericos representam a mesma medida, tolerando a
unidade omitida de um lado (35X52X7 e 35X52X7MM). Unidade diferente nos
dois lados nao e a mesma medida: 20L nao e 20M.
@param cA Primeiro token numerico.
@param cB Segundo token numerico.
@return lRet .T. quando o valor e a unidade sao compativeis.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FNumMesmoZ3(cA, cB)

    Local cNucA := ""
    Local cNucB := ""
    Local cUniA := ""
    Local cUniB := ""

    If cA == cB
        Return .T.
    EndIf

    cNucA := FNucleoNumZ3(cA)
    cNucB := FNucleoNumZ3(cB)
    If Empty(cNucA) .Or. Empty(cNucB) .Or. cNucA != cNucB
        Return .F.
    EndIf

    cUniA := FUnidNumZ3(cA)
    cUniB := FUnidNumZ3(cB)
    If cUniA == cUniB
        Return .T.
    EndIf
    If Empty(cUniA) .And. FEhUnidZ3(cUniB)
        Return .T.
    EndIf
    If Empty(cUniB) .And. FEhUnidZ3(cUniA)
        Return .T.
    EndIf

Return .F.


//-------------------------------------------------------------------
/*/{Protheus.doc} FNumEncaixaZ3
Informa se um numero aparece no descritivo maior, aceitando as escritas
equivalentes da mesma medida: mesmo valor com unidade omitida de um lado
(FNumMesmoZ3), cadeia de medidas com X colada no cadastro (2550X1960MM
contra 2550 X 1960MM), numero inteiro com sufixo curto (7100 contra 7100P)
e numero cortado no fim do cadastro (36843 gravado como 3684). O corte so
vale entre inteiros, com o menor de ao menos quatro digitos e o maior
exatamente um digito maior. Sem esse limite, 20 e 200 litros - produtos
diferentes - passariam como o mesmo item. O sufixo curto tambem tem limite
de quatro caracteres: sufixo maior e outro codigo, nao a mesma medida.
@param cNum Numero procurado.
@param aNum Vetor de numeros do descritivo maior.
@return lRet .T. quando o numero encaixa em algum numero do maior.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FNumEncaixaZ3(cNum, aNum)

    Local aLado := {}
    Local cCur  := ""
    Local cLon  := ""
    Local cNuc  := ""
    Local cNuc2 := ""
    Local cRest := ""
    Local cUni  := ""
    Local cUni2 := ""
    Local lTodo := .T.
    Local nI    := 1
    Local nJ    := 1

    For nI := 1 To Len(aNum)
        If FNumMesmoZ3(cNum, aNum[nI])
            Return .T.
        EndIf

        // Cadeia de medidas colada no cadastro (2550X1960MM) e o mesmo
        // conjunto que a solicitacao escreve com X entre as medidas. So vale
        // quando todos os lados comecam em digito, senao um pedaco de codigo
        // (M22-CK02) entraria como medida.
        If At("X", aNum[nI]) > 0
            aLado := StrTokArr(aNum[nI], "X")
            lTodo := Len(aLado) > 1
            For nJ := 1 To Len(aLado)
                If !(SubStr(AllTrim(aLado[nJ]), 1, 1) $ "0123456789")
                    lTodo := .F.
                EndIf
            Next nJ
            If lTodo
                For nJ := 1 To Len(aLado)
                    If FNumMesmoZ3(cNum, AllTrim(aLado[nJ]))
                        Return .T.
                    EndIf
                Next nJ
            EndIf
        EndIf

        cNuc  := FNucleoNumZ3(cNum)
        cNuc2 := FNucleoNumZ3(aNum[nI])

        // Numero inteiro seguido de ate quatro caracteres e a mesma medida
        // escrita com sufixo curto no cadastro: 7100 e 7100P, 30214 e
        // 30214J2Q. Sufixo longo e outro codigo, nao a mesma medida.
        If Len(cNuc) >= 4 .And. FEhDigZ3(cNuc) .And. Empty(FUnidNumZ3(cNum)) .And. ;
           Len(aNum[nI]) > Len(cNuc) .And. SubStr(aNum[nI], 1, Len(cNuc)) == cNuc
            cRest := SubStr(aNum[nI], Len(cNuc) + 1)
            If Len(cRest) <= 4 .And. FTemLetraZ3(cRest)
                Return .T.
            EndIf
        EndIf

        If FEhDigZ3(cNuc) .And. FEhDigZ3(cNuc2)
            cCur := cNuc
            cLon := cNuc2

            If Len(cLon) < Len(cCur)
                cCur := cNuc2
                cLon := cNuc
            EndIf

            If Len(cCur) >= 4 .And. Len(cLon) == Len(cCur) + 1 .And. ;
               SubStr(cLon, 1, Len(cCur)) == cCur
                cUni  := FUnidNumZ3(cNum)
                cUni2 := FUnidNumZ3(aNum[nI])
                If cUni == cUni2 .Or. Empty(cUni) .Or. Empty(cUni2)
                    Return .T.
                EndIf
            EndIf
        EndIf
    Next nI

Return .F.


//-------------------------------------------------------------------
/*/{Protheus.doc} FContidoNumZ3
Terceira camada de duplicidade: um descritivo contido no outro, com numeros
compativeis. Vale nos dois sentidos - a solicitacao pode trazer o descritivo
completo do fabricante e o cadastro encurtado, ou o cadastro trazer cor e
acabamento que a solicitacao nao citou (MESA TUBULAR 4 CADEIRAS COM TAMPO
GRANITO 0,75X0,75M acha o cadastro da mesma mesa com PRATA e OCRE).
Quem garante que e o mesmo item e a medida: os dois lados tem de citar a
MESMA QUANTIDADE de numeros, cada um encaixando no outro. Detalhe a mais no
cadastro entra por decisao do usuario; medida a mais nao entra, porque
medida diferente e outro produto (PORCA 3/8 nao casa com PORCA 3/8X3/4).
Numero cortado no fim do cadastro (36843 gravado como 3684) continua aceito
por FNumEncaixaZ3. Qualidade do aco nao pesa como medida: FTokensZ3() cola a
norma no numero (SAE 1020 vira SAE1020), entao BUCHA CILINDRICA DE 70MM PARA
EIXO 60MM acha a versao em ACO SAE 1020.
Exige ao menos duas palavras e um numero no lado menor - numero sozinho
casaria com qualquer item da mesma medida, e duas palavras sem numero
casariam com a familia inteira (FILTRO DE OLEO MOTOR DIESEL nao casa com
FILTRO DE OLEO MOTOR DIESEL PESADO).
Palavra de uma letra e designador, nao detalhe: o "C" do condulete tipo C
identifica o item, entao so casa quando os dois descritivos o citam. O X
fica de fora porque e separador de medida, ja isolado por FSeparaXZ3.
@param aPalSol Palavras da solicitacao.
@param aNumSol Numeros da solicitacao.
@param aPalCad Palavras do cadastro.
@param aNumCad Numeros do cadastro.
@return lRet .T. quando um descritivo esta contido no outro com numeros compativeis.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FContidoNumZ3(aPalSol, aNumSol, aPalCad, aNumCad)

    If FContidoDirZ3(aPalCad, aNumCad, aPalSol, aNumSol)
        Return .T.
    EndIf

Return FContidoDirZ3(aPalSol, aNumSol, aPalCad, aNumCad)


//-------------------------------------------------------------------
/*/{Protheus.doc} FContidoDirZ3
Confere a terceira camada em um sentido so: o descritivo menor (aContido)
esta inteiro dentro do maior (aExterno), com a mesma quantidade de numeros e
encaixe nas duas direcoes. FContidoNumZ3 chama esta funcao nos dois sentidos.
@param aContido    Palavras do descritivo menor.
@param aNumContido Numeros do descritivo menor.
@param aExterno    Palavras do descritivo maior.
@param aNumExterno Numeros do descritivo maior.
@return lRet .T. quando o descritivo menor esta contido no maior.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FContidoDirZ3(aContido, aNumContido, aExterno, aNumExterno)

    Local nI := 1

    If Len(aContido) < 2 .Or. Len(aNumContido) < 1
        Return .F.
    EndIf

    If Len(aNumContido) != Len(aNumExterno)
        Return .F.
    EndIf

    // E e conjuncao na descricao, nunca designador de produto.
    For nI := 1 To Len(aExterno)
        If Len(aExterno[nI]) == 1 .And. aExterno[nI] != "X" .And. ;
           aExterno[nI] != "E" .And. AScan(aContido, aExterno[nI]) == 0
            Return .F.
        EndIf
    Next nI

    // X e separador de medida (1600 KG X 20 = 1600KG COM 20), nao identidade:
    // o numero ja foi conferido, entao X de um lado so nao barra a contencao.
    For nI := 1 To Len(aContido)
        If aContido[nI] != "X" .And. AScan(aExterno, aContido[nI]) == 0
            Return .F.
        EndIf
    Next nI

    For nI := 1 To Len(aNumContido)
        If !FNumEncaixaZ3(aNumContido[nI], aNumExterno)
            Return .F.
        EndIf
    Next nI

    For nI := 1 To Len(aNumExterno)
        If !FNumEncaixaZ3(aNumExterno[nI], aNumContido)
            Return .F.
        EndIf
    Next nI

Return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} FTemLetraZ3
Informa se o texto tem ao menos uma letra de A a Z.
@param cTexto Texto a conferir.
@return lRet .T. quando existe letra no texto.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FTemLetraZ3(cTexto)

    Local nI := 1

    For nI := 1 To Len(cTexto)
        If SubStr(cTexto, nI, 1) $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            Return .T.
        EndIf
    Next nI

Return .F.


//-------------------------------------------------------------------
/*/{Protheus.doc} FTemDigZ3
Informa se o texto tem ao menos um digito.
@param cTexto Texto a conferir.
@return lRet .T. quando existe digito no texto.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FTemDigZ3(cTexto)

    Local nI := 1

    For nI := 1 To Len(cTexto)
        If SubStr(cTexto, nI, 1) $ "0123456789"
            Return .T.
        EndIf
    Next nI

Return .F.


//-------------------------------------------------------------------
/*/{Protheus.doc} FContaDigZ3
Conta quantos digitos o texto tem. A camada de Part Number usa a contagem
para separar codigo de fabricante (dois digitos ou mais) de norma ou padrao
tecnico escrito com um digito so (CAT5E, IP68).
@param cTexto Texto a conferir.
@return nQtd Quantidade de digitos encontrados.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FContaDigZ3(cTexto)

    Local nI   := 1
    Local nQtd := 0

    For nI := 1 To Len(cTexto)
        If SubStr(cTexto, nI, 1) $ "0123456789"
            nQtd += 1
        EndIf
    Next nI

Return nQtd


//-------------------------------------------------------------------
/*/{Protheus.doc} FEhCodigoZ3
Informa se o token e codigo de fabricante: tem letra e digito, cinco
caracteres ou mais, e nao e numero com unidade (40MM, 2.5MM2). O codigo e
o que prova que dois descritivos com mais ou menos palavras sao o mesmo
item.
@param cTok Token vindo de FTokensZ3().
@return lRet .T. quando o token e codigo de fabricante.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FEhCodigoZ3(cTok)

    Local cNuc := ""
    Local cUni := ""

    If Len(cTok) < 5
        Return .F.
    EndIf

    If !FTemLetraZ3(cTok) .Or. !FTemDigZ3(cTok)
        Return .F.
    EndIf

    cNuc := FNucleoNumZ3(cTok)
    cUni := FUnidNumZ3(cTok)

    If !Empty(cNuc) .And. !Empty(cUni) .And. FEhUnidZ3(cUni)
        Return .F.
    EndIf

Return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} FEhRotuloCodZ3
Informa se o token e rotulo de campo (COD.20877, REF1234, PN5678) ou norma
(NR-10, NBR6023, ISO9001): as letras formam um rotulo conhecido e o resto
sao so digitos e separadores. O numero que vem depois e codigo interno,
norma ou fornecedor, nao identidade do produto.
@param cTok Token bruto, em maiusculo.
@return lRet .T. quando o token e rotulo de campo ou norma.
@type    Static Function
@author  Suprimentos
@since   03/11/2026
/*/
//-------------------------------------------------------------------
Static Function FEhRotuloCodZ3(cTok)

    Local aRot  := {"COD", "CODIGO", "REF", "PN", "PART", "NR", "NBR", "ISO", ;
                    "ABNT", "SAE", "DIN", "ASTM", "ANSI", "API", "ASME", ;
                    "AWS", "JIS", "UNS", "NACE", "AFNOR", "CA"}
    Local cChar := ""
    Local cLet  := ""
    Local cNum  := ""
    Local nI    := 1

    If Empty(cTok)
        Return .F.
    EndIf

    For nI := 1 To Len(cTok)
        cChar := SubStr(cTok, nI, 1)
        If cChar $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            cLet += cChar
        Else
            cNum += cChar
        EndIf
    Next nI

    If Empty(cNum) .Or. AScan(aRot, cLet) == 0
        Return .F.
    EndIf

    For nI := 1 To Len(cNum)
        If !(SubStr(cNum, nI, 1) $ "0123456789.-/")
            Return .F.
        EndIf
    Next nI

Return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} FEhCodAlfaZ3
Informa se o token compactado distingue produto: tem letra e digito e nao e
medida (170X80MM, 1000X800X200) nem numero com unidade curta (40MM, 24V),
que casam com familias inteiras. Numero puro de fornecedor (175579) tambem
nao entra, porque nao tem letra.
@param cTok Token so com letras e digitos.
@return lRet .T. quando o token e codigo alfanumerico de produto.
@type    Static Function
@author  Suprimentos
@since   03/11/2026
/*/
//-------------------------------------------------------------------
Static Function FEhCodAlfaZ3(cTok)

    Local cNuc  := ""
    Local cUni  := ""
    Local cSuf  := ""
    Local nPref := 0

    If Empty(cTok) .Or. !FTemLetraZ3(cTok) .Or. !FTemDigZ3(cTok)
        Return .F.
    EndIf

    If FEhDimensaoTokZ3(cTok) .Or. FEhEspecTokZ3(cTok)
        Return .F.
    EndIf

    // Numero com ate quatro letras no fim e a mesma forma de uma medida
    // escrita por extenso (50MM, 24V, 12KG), mesmo com sete digitos ou mais.
    nPref := FPrefNumZ3(cTok)
    If nPref > 0 .And. Len(cTok) - nPref >= 1 .And. Len(cTok) - nPref <= 4
        cSuf := SubStr(cTok, nPref + 1)
        If !FTemDigZ3(cSuf)
            Return .F.
        EndIf
    EndIf

    cNuc := FNucleoNumZ3(cTok)
    cUni := FUnidNumZ3(cTok)
    If !Empty(cNuc) .And. !Empty(cUni) .And. FEhUnidZ3(cUni)
        Return .F.
    EndIf

Return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} FPartesCodZ3
Extrai os trechos aproveitaveis de um codigo composto, separados por ponto,
hifen ou barra: FAR44-40-04N/2 devolve FAR44, 40 e 04N. Trecho
alfanumerico vale a partir de cinco caracteres; trecho so numerico vale
apenas dentro de codigo que tem letra (TRAMONTINA-41905306), porque numero
solto e medida ou codigo de fornecedor.
@param cTok       Token bruto como foi digitado.
@param lComposto  .T. quando o token tem letra.
@return aRet Vetor de trechos compactados, sem repeticao.
@type    Static Function
@author  Suprimentos
@since   03/11/2026
/*/
//-------------------------------------------------------------------
Static Function FPartesCodZ3(cTok, lComposto)

    Local aRet  := {}
    Local aSeg  := {}
    Local cComp := ""
    Local lVale := .F.
    Local nI    := 1

    aSeg := StrTokArr(StrTran(StrTran(StrTran(cTok, ".", " "), "-", " "), "/", " "), " ")

    For nI := 1 To Len(aSeg)
        cComp := FSoAlfaNumZ3(AllTrim(aSeg[nI]))
        lVale := !Empty(cComp) .And. AScan(aRet, cComp) == 0
        If lVale
            lVale := (Len(cComp) >= 5 .And. FEhCodAlfaZ3(cComp)) .Or. ;
                     (lComposto .And. FEhDigZ3(cComp) .And. Len(cComp) >= 5)
        EndIf
        If lVale
            AAdd(aRet, cComp)
        EndIf
    Next nI

Return aRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FAchouCodLinZ3
Informa se o codigo da solicitacao aparece na linha do cache: o codigo
inteiro nos tokens brutos ou qualquer trecho dele nos segmentos.
@param aCod   Codigo no formato {codigo inteiro, trechos, e alfanumerico}.
@param aLinha Linha do cache da SB1.
@return lRet .T. quando o codigo esta no cadastro.
@type    Static Function
@author  Suprimentos
@since   03/11/2026
/*/
//-------------------------------------------------------------------
Static Function FAchouCodLinZ3(aCod, aLinha)

    Local nI := 1

    If At("|" + aCod[1] + "|", aLinha[8]) > 0
        Return .T.
    EndIf

    For nI := 1 To Len(aCod[2])
        If At("|" + aCod[2][nI] + "|", aLinha[9]) > 0
            Return .T.
        EndIf
    Next nI

Return .F.


//-------------------------------------------------------------------
/*/{Protheus.doc} FTemCodZ3
Informa se o vetor tem algum codigo de fabricante. Serve para pular a
camada de codigo inteira quando a solicitacao nao traz nenhum.
Recebe o vetor inteiro de tokens, e nao so as palavras: codigo que comeca
por numero (6312ZZC3) fica do lado dos numeros, e o rolamento so entra na
camada 4 por causa dele.
@param aTok Vetor de tokens da solicitacao.
@return lRet .T. quando existe ao menos um codigo de fabricante.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FTemCodZ3(aTok)

    Local nI := 1

    For nI := 1 To Len(aTok)
        If FEhCodigoZ3(aTok[nI])
            Return .T.
        EndIf
    Next nI

Return .F.


//-------------------------------------------------------------------
/*/{Protheus.doc} FContidoCodZ3
Quarta camada de duplicidade: mesmo codigo de fabricante e uma descricao
contida na outra, sem medida em conflito. O codigo e a identidade do item,
entao o descritivo maior pode trazer caracteristica e medida que o menor
nao traz - e detalhe do codigo, nao outro produto.
Cobre o cadastro escrito com mais detalhe do que a solicitacao: RETENTOR
35X52X7 SKF HMSA10RG casa com RETENTOR VEDACAO EXTRA BORRACHA 35X52X7MM
SKF HMSA10-RG, porque o codigo HMSA10RG e o mesmo.
Cobre a descricao reduzida, sem numero dos dois lados: CARTUCHO DE TONER
EM TERMOPLASTICO NA COR PRETA MULTIFUNCIONAL HP CF283 e o mesmo item de
CARTUCHO DE TONER EM TERMOPLASTICO COM SUPERFICIE LISA NA COR PRETA
MULTIFUNCIONAL HP CF283.
Cobre o codigo que carrega a medida: ROLAMENTO RIGIDO DE ESFERAS EM ACO
CROMO 6312-ZZ-C3 casa com o cadastro que escreve 60X130X31MM e FOLGA C3,
porque o 6312 ja diz o tamanho e o codigo confere. Nesse caso o codigo
comeca por numero e chega pelo vetor de numeros, por isso os dois vetores
sao conferidos.
Exige: duas palavras de cada lado, toda palavra da descricao menor
presente na maior (a menor e a de menos palavras), toda medida da menor
presente na maior (FNumEncaixaZ3; medida so na maior e detalhe), as
mesmas letras soltas dos dois lados (o X fica de fora porque e separador
de medida) e ao menos um codigo de fabricante em comum. Sem o codigo em
comum, a descricao menor seria apenas parecida, e parecido nao entra.
@param aPalSol Palavras da solicitacao.
@param aNumSol Numeros da solicitacao.
@param aPalCad Palavras do cadastro.
@param aNumCad Numeros do cadastro.
@return lRet .T. quando o cadastro e o mesmo item pelo codigo de fabricante.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FContidoCodZ3(aPalSol, aNumSol, aPalCad, aNumCad)

    Local lCod      := .F.
    Local aPalMenor := {}
    Local aPalMaior := {}
    Local aNumMenor := {}
    Local aNumMaior := {}
    Local nI        := 1

    If Len(aPalSol) < 2 .Or. Len(aPalCad) < 2
        Return .F.
    EndIf

    // A descricao com menos palavras e a reduzida; o detalhe a mais fica na
    // maior. Sem numero, "escrito menor" nao tem lado, entao a comparacao
    // vale nos dois sentidos.
    If Len(aPalSol) <= Len(aPalCad)
        aPalMenor := aPalSol
        aPalMaior := aPalCad
        aNumMenor := aNumSol
        aNumMaior := aNumCad
    Else
        aPalMenor := aPalCad
        aPalMaior := aPalSol
        aNumMenor := aNumCad
        aNumMaior := aNumSol
    EndIf

    // Toda palavra da descricao menor tem de existir na maior. X e separador
    // de medida, nao palavra: a medida ja e conferida pelos numeros.
    For nI := 1 To Len(aPalMenor)
        If aPalMenor[nI] != "X" .And. AScan(aPalMaior, aPalMenor[nI]) == 0
            Return .F.
        EndIf
    Next nI

    // Medida so na descricao maior e detalhe do codigo (o 60X130X31 de um
    // 6312). Medida na descricao menor que a maior nao cita e conflito: os
    // dois descritivos estariam falando de tamanhos diferentes.
    For nI := 1 To Len(aNumMenor)
        If !FNumEncaixaZ3(aNumMenor[nI], aNumMaior)
            Return .F.
        EndIf
    Next nI

    // Designador de uma letra (o C do condulete) muda o item, entao as duas
    // descricoes tem de citar exatamente as mesmas letras soltas. E e conjuncao.
    For nI := 1 To Len(aPalSol)
        If Len(aPalSol[nI]) == 1 .And. aPalSol[nI] != "X" .And. ;
           aPalSol[nI] != "E" .And. AScan(aPalCad, aPalSol[nI]) == 0
            Return .F.
        EndIf
    Next nI

    For nI := 1 To Len(aPalCad)
        If Len(aPalCad[nI]) == 1 .And. aPalCad[nI] != "X" .And. ;
           aPalCad[nI] != "E" .And. AScan(aPalSol, aPalCad[nI]) == 0
            Return .F.
        EndIf
    Next nI

    For nI := 1 To Len(aPalSol)
        If FEhCodigoZ3(aPalSol[nI]) .And. AScan(aPalCad, aPalSol[nI]) > 0
            lCod := .T.
            Exit
        EndIf
    Next nI

    // Codigo que comeca por numero (6312ZZC3) chega pelo vetor de numeros,
    // nao pelo de palavras: sem esta volta a camada nunca veria o rolamento.
    If !lCod
        For nI := 1 To Len(aNumSol)
            If FEhCodigoZ3(aNumSol[nI]) .And. AScan(aNumCad, aNumSol[nI]) > 0
                lCod := .T.
                Exit
            EndIf
        Next nI
    EndIf

Return lCod


//-------------------------------------------------------------------
/*/{Protheus.doc} FTokBrutoZ3
Separa o texto como ele foi digitado, sem normalizacao: um token comeca em
letra ou digito e continua enquanto houver letra, digito, ponto, hifen ou
barra (3546489.000, LPK-207Q, 1/2). Diferente de FTokensZ3(), que junta
palavra com medida e troca abreviacao, aqui o codigo do fabricante precisa
chegar intacto para ser comparado por igualdade.
@param cTexto Texto original (descritivo ou Part Number).
@return aTok Vetor de tokens em maiusculo, sem separador no fim.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FTokBrutoZ3(cTexto)

    Local aTok   := {}
    Local cAtual := ""
    Local cChar  := ""
    Local nI     := 1

    cTexto := Upper(cTexto)

    For nI := 1 To Len(cTexto)
        cChar := SubStr(cTexto, nI, 1)
        If cChar $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            cAtual += cChar
        ElseIf !Empty(cAtual) .And. (cChar == "." .Or. cChar == "-" .Or. cChar == "/")
            cAtual += cChar
        Else
            If !Empty(cAtual)
                AAdd(aTok, cAtual)
            EndIf
            cAtual := ""
        EndIf
    Next nI

    If !Empty(cAtual)
        AAdd(aTok, cAtual)
    EndIf

    For nI := 1 To Len(aTok)
        Do While Len(aTok[nI]) > 0 .And. SubStr(aTok[nI], Len(aTok[nI]), 1) $ ".-/"
            aTok[nI] := SubStr(aTok[nI], 1, Len(aTok[nI]) - 1)
        EndDo
    Next nI

Return aTok


//-------------------------------------------------------------------
/*/{Protheus.doc} FSoAlfaNumZ3
Descarta tudo que nao for letra ou digito. Usado para comparar o codigo
sem os separadores que o fabricante escreve ora com hifen, ora com ponto,
ora colado.
@param cTexto Texto a limpar.
@return cRet Texto so com letras e digitos, em maiusculo.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FSoAlfaNumZ3(cTexto)

    Local cRet  := ""
    Local cChar := ""
    Local nI    := 1

    For nI := 1 To Len(cTexto)
        cChar := SubStr(cTexto, nI, 1)
        If cChar $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            cRet += cChar
        EndIf
    Next nI

Return cRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FToksBrutosZ3
Monta a representacao do descritivo para busca por codigo: cada token
bruto compactado entre barras verticais (|TOK|TOK|). A barra no comeco e no
fim evita que o codigo 3546489 case dentro de 35464890.
@param cTexto Descritivo original do cadastro.
@return cRet Texto com os tokens entre barras.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FToksBrutosZ3(cTexto)

    Local aTok  := {}
    Local cComp := ""
    Local cRet  := ""
    Local nI    := 1

    aTok := FTokBrutoZ3(cTexto)

    For nI := 1 To Len(aTok)
        cComp := FSoAlfaNumZ3(aTok[nI])
        If !Empty(cComp)
            cRet += "|" + cComp + "|"
        EndIf
    Next nI

Return cRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FSegsBrutosZ3
Representa o descritivo tambem em segmentos: cada token bruto e quebrado
nos pontos, hifens e barras que o separam, e cada pedaco entra compactado
entre barras (|FAR44|40|04N|). E o que permite comparar um trecho do codigo
composto (FAR44-40-04N/2) com o codigo curto gravado no cadastro.
@param cTexto Descritivo original do cadastro.
@return cRet Texto com os segmentos entre barras.
@type    Static Function
@author  Suprimentos
@since   03/11/2026
/*/
//-------------------------------------------------------------------
Static Function FSegsBrutosZ3(cTexto)

    Local cAux := StrTran(cTexto, ".", " ")

    cAux := StrTran(cAux, "-", " ")
    cAux := StrTran(cAux, "/", " ")

Return FToksBrutosZ3(cAux)


//-------------------------------------------------------------------
/*/{Protheus.doc} FMaiorRunDigZ3
Devolve a maior sequencia de digitos seguidos do texto. Codigo de
fabricante de verdade tem bloco numerico (3546489, 6ES72121); medida com
letra tem no maximo dois digitos seguidos (50MM, 24V).
@param cTexto Texto a conferir.
@return nMaior Tamanho da maior sequencia de digitos.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FMaiorRunDigZ3(cTexto)

    Local nAtual := 0
    Local nMaior := 0
    Local nI     := 1

    For nI := 1 To Len(cTexto)
        If SubStr(cTexto, nI, 1) $ "0123456789"
            nAtual += 1
            If nAtual > nMaior
                nMaior := nAtual
            EndIf
        Else
            nAtual := 0
        EndIf
    Next nI

Return nMaior


//-------------------------------------------------------------------
/*/{Protheus.doc} FTemBarraNumZ3
Informa se o texto tem digito, barra e digito (1/2, 220/380). Fracao e
tensao dupla nao sao codigo de fabricante.
@param cTexto Texto a conferir.
@return lRet .T. quando existe digito/barra/digito.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FTemBarraNumZ3(cTexto)

    Local nI := 1

    For nI := 1 To Len(cTexto) - 2
        If SubStr(cTexto, nI, 1) $ "0123456789" .And. ;
           SubStr(cTexto, nI + 1, 1) == "/" .And. ;
           SubStr(cTexto, nI + 2, 1) $ "0123456789"
            Return .T.
        EndIf
    Next nI

Return .F.


//-------------------------------------------------------------------
/*/{Protheus.doc} FEhFamiliaZ3
Informa se o token e nome de familia de produto (S7-1200, C-1234):
letra, digito, hifen e tres ou quatro digitos ate o fim. Esse formato
identifica a linha inteira, nao um item, e por isso fica fora da camada de
codigo forte.
@param cTexto Token bruto.
@return lRet .T. quando o token tem formato de familia.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FEhFamiliaZ3(cTexto)

    Local nI := 4

    If Len(cTexto) < 6 .Or. Len(cTexto) > 7
        Return .F.
    EndIf
    If !(SubStr(cTexto, 1, 1) $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        Return .F.
    EndIf
    If !(SubStr(cTexto, 2, 1) $ "0123456789") .Or. SubStr(cTexto, 3, 1) != "-"
        Return .F.
    EndIf

    For nI := 4 To Len(cTexto)
        If !(SubStr(cTexto, nI, 1) $ "0123456789")
            Return .F.
        EndIf
    Next nI

Return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} FLeNumComDecZ3
Avanca sobre um numero inteiro ou decimal (50, 2.5, 1,25) a partir de uma
posicao e devolve a posicao seguinte. Serve para reconhecer medida sem
depender de expressao regular, que AdvPL nao tem.
@param cTexto Texto lido.
@param nPos   Posicao inicial (1 = primeiro caractere).
@return nPos   Posicao logo depois do numero.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FLeNumComDecZ3(cTexto, nPos)

    Local nIni := nPos

    Do While nPos <= Len(cTexto) .And. SubStr(cTexto, nPos, 1) $ "0123456789"
        nPos += 1
    EndDo

    If nPos == nIni
        Return nPos
    EndIf

    If nPos <= Len(cTexto) .And. (SubStr(cTexto, nPos, 1) == "." .Or. ;
       SubStr(cTexto, nPos, 1) == ",")
        nIni := nPos + 1
        nPos += 1
        Do While nPos <= Len(cTexto) .And. SubStr(cTexto, nPos, 1) $ "0123456789"
            nPos += 1
        EndDo
        If nPos == nIni
            nPos := nIni - 1
        EndIf
    EndIf

Return nPos


//-------------------------------------------------------------------
/*/{Protheus.doc} FEhDimensaoTokZ3
Informa se o token e medida com dimensoes (50X50CM, 20X30X10, 2.5X1.5M):
numero, uma ou mais partes X numero e ate quatro letras de unidade.
Medida nao e identidade de produto.
@param cTexto Token bruto.
@return lRet .T. quando o token e medida com X.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FEhDimensaoTokZ3(cTexto)

    Local nI   := 1
    Local nQtd := 0

    If Empty(cTexto) .Or. !(SubStr(cTexto, 1, 1) $ "0123456789")
        Return .F.
    EndIf

    nI := FLeNumComDecZ3(cTexto, 1)

    Do While nI <= Len(cTexto) .And. SubStr(cTexto, nI, 1) == "X"
        nQtd += 1
        nI   += 1
        If !(SubStr(cTexto, nI, 1) $ "0123456789")
            Return .F.
        EndIf
        nI := FLeNumComDecZ3(cTexto, nI)
    EndDo

    If nQtd < 1
        Return .F.
    EndIf

    If Len(cTexto) - nI + 1 > 4
        Return .F.
    EndIf

    Do While nI <= Len(cTexto)
        If !(SubStr(cTexto, nI, 1) $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
            Return .F.
        EndIf
        nI += 1
    EndDo

Return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} FEhEspecTokZ3
Informa se o token e medida com unidade (50MM, 24V, 12,5KG): de dois a seis
digitos, parte decimal opcional e de uma a quatro letras. Numero com sete
digitos ou mais nao e medida, e codigo de fabricante com a mesma forma
(160422059G). Medida nao e identidade de produto.
@param cTexto Token bruto.
@return lRet .T. quando o token e medida com unidade.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FEhEspecTokZ3(cTexto)

    Local nI   := 1
    Local nDig := 0

    If Empty(cTexto) .Or. !(SubStr(cTexto, 1, 1) $ "0123456789")
        Return .F.
    EndIf

    Do While SubStr(cTexto, nI, 1) $ "0123456789"
        nDig += 1
        nI   += 1
    EndDo

    If nDig < 2 .Or. nDig > 6
        Return .F.
    EndIf

    If SubStr(cTexto, nI, 1) == "." .Or. SubStr(cTexto, nI, 1) == ","
        nI += 1
        If !(SubStr(cTexto, nI, 1) $ "0123456789")
            Return .F.
        EndIf
        Do While SubStr(cTexto, nI, 1) $ "0123456789"
            nI += 1
        EndDo
    EndIf

    nDig := Len(cTexto) - nI + 1
    If nDig < 1 .Or. nDig > 4
        Return .F.
    EndIf

    Do While nI <= Len(cTexto)
        If !(SubStr(cTexto, nI, 1) $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
            Return .F.
        EndIf
        nI += 1
    EndDo

Return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} FNucleoMedZ3
Devolve o valor numerico de um token de medida, sem a unidade: 200MM vira
200, 12,5KG vira 12,5, 60X130X31MM vira 60. E o numero que precisa bater
para a medida ser a mesma.
@param cTok Token bruto.
@return cRet Nucleo numerico, ou vazio quando o token nao comeca em digito.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FNucleoMedZ3(cTok)

    Local cChar := ""
    Local cRet  := ""
    Local nI    := 1

    Do While nI <= Len(cTok)
        cChar := SubStr(cTok, nI, 1)
        If cChar $ "0123456789.,/"
            cRet += cChar
        Else
            Exit
        EndIf
        nI += 1
    EndDo

    Do While Len(cRet) > 1 .And. (SubStr(cRet, Len(cRet), 1) == "/" .Or. ;
        SubStr(cRet, Len(cRet), 1) == "." .Or. SubStr(cRet, Len(cRet), 1) == ",")
        cRet := SubStr(cRet, 1, Len(cRet) - 1)
    EndDo

    // Zero a esquerda nao muda o valor: 05MM e a medida 5. So vale para nucleo
    // inteiro, senao 0,5 perderia o zero e viraria 5.
    If FEhDigZ3(cRet)
        Do While Len(cRet) > 1 .And. SubStr(cRet, 1, 1) == "0"
            cRet := SubStr(cRet, 2)
        EndDo
    EndIf

Return cRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FUnidMedZ3
Devolve a unidade no fim de um token de medida: 200MM vira MM, 12,5KG vira
KG, 50X50CM vira CM e 4X2 vira vazio.
@param cTok Token bruto.
@return cRet Unidade, ou vazio quando o token nao tem letra no fim.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FUnidMedZ3(cTok)

    Local cRet := ""
    Local nI   := Len(cTok)

    Do While nI >= 1 .And. Len(cRet) < 4 .And. ;
        SubStr(cTok, nI, 1) $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        cRet := SubStr(cTok, nI, 1) + cRet
        nI -= 1
    EndDo

Return cRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FMedPartesZ3
Decompoe um token de medida nos valores que ele cita: 170X80MM vira 170 e
80, 50X50X10CM vira 50, 50 e 10. Todos os lados herdam a unidade do fim do
token. Sem a decomposicao, 170X80MM seria lido so como 170 e o 80 sumiria,
fazendo uma medida igual parecer conflito.
@param cTok Token bruto de medida.
@return aRet Vetor de pares {nucleo, unidade}.
@type    Static Function
@author  Suprimentos
@since   03/11/2026
/*/
//-------------------------------------------------------------------
Static Function FMedPartesZ3(cTok)

    Local aRet  := {}
    Local aLado := StrTokArr(cTok, "X")
    Local cUni  := FUnidMedZ3(cTok)
    Local cNuc  := ""
    Local nI    := 1

    For nI := 1 To Len(aLado)
        cNuc := FNucleoMedZ3(AllTrim(aLado[nI]))
        If !Empty(cNuc)
            AAdd(aRet, { cNuc, cUni })
        EndIf
    Next nI

Return aRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FConflitoMedZ3
Informa se a solicitacao cita medida incompativel com o cadastro. Medida de
comprimento (MM, CM, KM, POL, M2, MM2, M3, MM3) escrita na solicitacao tem
de existir no cadastro: 200MM contra um cadastro que nao cita tamanho prova
que o item cadastrado e outro. Nas demais unidades (V, A, L, KG) so ha
conflito quando o cadastro cita a mesma unidade com valor diferente
(250V contra 127V); cadastro que nao cita a unidade esta apenas omitindo
detalhe. Assim o codigo forte nao traz item de tamanho diferente.
Medida com mais de um lado (170X80MM) e comparada lado a lado.
@param cDescSol Descritivo da solicitacao.
@param cDescCad Descritivo do produto cadastrado.
@return lRet .T. quando existe medida em conflito.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FConflitoMedZ3(cDescSol, cDescCad)

    Local aSol    := FTokBrutoZ3(cDescSol)
    Local aCad    := FTokBrutoZ3(cDescCad)
    Local aMedCad := {}
    Local aPart   := {}
    // Unidades em que a medida e o tamanho do produto, nao uma caracteristica
    // que o cadastro possa omitir (tensao, corrente, volume da embalagem).
    Local aFort   := {"MM", "CM", "KM", "POL", "POLEG", "POLEGADA", ;
                      "M2", "MM2", "M3", "MM3"}
    Local cNuc    := ""
    Local cUni    := ""
    Local lTemUni := .F.
    Local lCompat := .F.
    Local nI      := 1
    Local nJ      := 1
    Local nK      := 1

    For nJ := 1 To Len(aCad)
        If FEhDimensaoTokZ3(aCad[nJ]) .Or. FEhEspecTokZ3(aCad[nJ])
            aPart := FMedPartesZ3(aCad[nJ])
            For nK := 1 To Len(aPart)
                AAdd(aMedCad, aPart[nK])
            Next nK
        EndIf
    Next nJ

    For nI := 1 To Len(aSol)
        aPart := {}
        If FEhDimensaoTokZ3(aSol[nI]) .Or. FEhEspecTokZ3(aSol[nI])
            aPart := FMedPartesZ3(aSol[nI])
        EndIf
        For nK := 1 To Len(aPart)
            cNuc := aPart[nK][1]
            cUni := aPart[nK][2]
            If !Empty(cNuc)
                lTemUni := .F.
                lCompat := .F.
                For nJ := 1 To Len(aMedCad)
                    If aMedCad[nJ][2] == cUni
                        lTemUni := .T.
                        If aMedCad[nJ][1] == cNuc
                            lCompat := .T.
                        EndIf
                    EndIf
                Next nJ
                If AScan(aFort, cUni) > 0
                    If !lCompat
                        Return .T.
                    EndIf
                ElseIf lTemUni .And. !lCompat
                    Return .T.
                EndIf
            EndIf
        Next nK
    Next nI

Return .F.


//-------------------------------------------------------------------
/*/{Protheus.doc} FAddUniqZ3
Acrescenta um texto ao vetor so quando ele ainda nao existe.
@param aArr Vetor de textos (passado por referencia).
@param cVal Texto a acrescentar.
@return Nil
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FAddUniqZ3(aArr, cVal)

    If !Empty(cVal) .And. AScan(aArr, cVal) == 0
        AAdd(aArr, cVal)
    EndIf

Return Nil


//-------------------------------------------------------------------
/*/{Protheus.doc} FChavesCodZ3
Extrai do texto os codigos fortes: trechos que sozinhos identificam o item
no catalogo do fabricante.
Entra:
  - numero de material com seis digitos ou mais (3546489, 2760000046573);
  - numero com desdobramento decimal (3546489.000 vira 3546489), porque o
    sufixo identifica a variacao do mesmo codigo, nao outro produto;
  - codigo alfanumerico de seis caracteres ou mais com pelo menos cinco
    digitos e um bloco de tres digitos seguidos (6ES72121HE400XB0,
    MC011000089);
  - o mesmo codigo sem o A inicial quando o resto e so digito (A9608300818
    entra tambem como 9608300818), porque o cadastro grava o numero sem o
    prefixo de fabricante.
Fica de fora: fracao e tensao dupla (1/2, 220/380), nome de familia
(S7-1200), medida com X (50X50CM) e medida com unidade (50MM, 24V).
@param cTexto Descritivo ou Part Number original.
@return aChv Vetor de codigos, sem repeticao.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FChavesCodZ3(cTexto)

    Local aChv  := {}
    Local aTok  := {}
    Local cTok  := ""
    Local cComp := ""
    Local cEsq  := ""
    Local cDir  := ""
    Local cSemA := ""
    Local nPos  := 0
    Local nI    := 1

    aTok := FTokBrutoZ3(cTexto)

    For nI := 1 To Len(aTok)
        cTok  := aTok[nI]
        cComp := FSoAlfaNumZ3(cTok)

        // Codigo com desdobramento: 3546489.000 e a mesma identidade de 3546489.
        nPos := At(".", cTok)
        If nPos > 0
            cEsq := SubStr(cTok, 1, nPos - 1)
            cDir := SubStr(cTok, nPos + 1)
            If Len(cEsq) + 1 + Len(cDir) == Len(cTok) .And. ;
               FEhDigZ3(cEsq) .And. FEhDigZ3(cDir) .And. ;
               FContaDigZ3(cEsq) >= 5
                FAddUniqZ3(@aChv, cEsq)
            EndIf
        EndIf

        // Numero de material.
        If Len(cTok) >= 6 .And. FEhDigZ3(cTok)
            FAddUniqZ3(@aChv, cTok)
        EndIf

        // Codigo alfanumerico: letra e digito, sem medida nem familia.
        If FTemLetraZ3(cTok) .And. !FTemBarraNumZ3(cTok) .And. ;
           !FEhFamiliaZ3(cTok) .And. !FEhDimensaoTokZ3(cTok) .And. ;
           !FEhEspecTokZ3(cTok) .And. ;
           Len(cComp) >= 6 .And. FContaDigZ3(cComp) >= 5 .And. ;
           FMaiorRunDigZ3(cComp) >= 3
            FAddUniqZ3(@aChv, cComp)
        EndIf

        // Prefixo A do fabricante: o cadastro grava o numero sem o A, entao o
        // mesmo codigo sem o prefixo tambem identifica o item.
        cSemA := FPnSemAZ3(cComp)
        If !Empty(cSemA)
            FAddUniqZ3(@aChv, cSemA)
        EndIf
    Next nI

Return aChv


//-------------------------------------------------------------------
/*/{Protheus.doc} FAddCodZ3
Acrescenta {codigo, descricao, fornecedor} ao vetor so quando aquele
codigo ainda nao esta na lista.
@param aArr Vetor de linhas (passado por referencia).
@param cCod Codigo do produto no cadastro.
@param cDes Descritivo do produto no cadastro.
@return Nil
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FAddCodZ3(aArr, cCod, cDes)

    Local nI := 1

    For nI := 1 To Len(aArr)
        If aArr[nI][1] == cCod
            Return Nil
        EndIf
    Next nI

    AAdd(aArr, { cCod, cDes, "" })

Return Nil


//-------------------------------------------------------------------
/*/{Protheus.doc} FAchaCodCacheZ3
Procura no cache da SB1 os produtos que trazem o codigo forte como palavra
inteira. Codigo que aparece em um so item e identidade: entra. Em dois
itens, entra apenas o que comeca pelo mesmo tipo de produto da solicitacao
(para nao trazer camera e pneu do mesmo aro). Em tres ou mais e linha de
produto e nao entra: o codigo difere em outra parte que a solicitacao nao
escreveu.
@param aCod    Vetor de codigos fortes.
@param cCabSol Tipo do produto da solicitacao (FCabecaZ3).
@param cDescSol Descritivo da solicitacao (usado no veto de medida).
@return aRet   Vetor de {codigo, descricao, fornecedor}.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FAchaCodCacheZ3(aCod, cCabSol, cDescSol)

    Local aRet   := {}
    Local aHit   := {}
    Local cBusca := ""
    Local nI     := 1
    Local nJ     := 1

    For nI := 1 To Len(aCod)
        cBusca := "|" + aCod[nI] + "|"
        aHit   := {}

        For nJ := 1 To Len(aCacheSB1)
            If cBusca $ aCacheSB1[nJ][8]
                AAdd(aHit, nJ)
            EndIf
        Next nJ

        If Len(aHit) == 1
            // Medida em conflito prova que o item cadastrado e outro: o codigo
            // pode ser o mesmo, mas o tamanho escrito nao bate.
            If !FConflitoMedZ3(cDescSol, aCacheSB1[aHit[1]][2])
                FAddCodZ3(@aRet, aCacheSB1[aHit[1]][1], aCacheSB1[aHit[1]][2])
            EndIf
        ElseIf Len(aHit) == 2 .And. !Empty(cCabSol)
            For nJ := 1 To 2
                If aCacheSB1[aHit[nJ]][7] == cCabSol .And. ;
                   !FConflitoMedZ3(cDescSol, aCacheSB1[aHit[nJ]][2])
                    FAddCodZ3(@aRet, aCacheSB1[aHit[nJ]][1], aCacheSB1[aHit[nJ]][2])
                EndIf
            Next nJ
        EndIf
    Next nI

Return aRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FChavesPnZ3
Separa do campo Part Number os trechos que servem de chave de busca. O
campo chega com texto em volta - "COD: 2760000046573 - LOJA ELETRICA",
"PN LPK-207Q" - e o descritivo do cadastro guarda so o numero. Comparar a
frase inteira nunca acha o item; o numero sozinho acha.
Entra como chave a sequencia so de digitos com seis ou mais (numero de
material) e o codigo com letra e digito (LPK207Q, CF283). Bitola com
unidade (100MM) e fracao (1.1/16) ficam de fora para nao casar com a
familia inteira.
O CA do EPI tambem entra: o numero de quatro a seis digitos logo depois
da palavra CA, colado ou espacado (CA 36995, CA36995, CA:17074), e a
identidade do produto e acha o item mesmo quando o tamanho escrito na
solicitacao difere do cadastro.
@param cPn Part Number digitado.
@return aChv Vetor de chaves, sem repeticao.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FChavesPnZ3(cPn)

    Local aChv := {}
    Local aTok := {}
    Local aPal := {}
    Local cNorm := ""
    Local cTok := ""
    Local nI   := 1

    If Empty(AllTrim(cPn))
        Return aChv
    EndIf

    cNorm := FNormalZ3(cPn)
    aTok  := FTokensZ3(cNorm)

    For nI := 1 To Len(aTok)
        cTok := aTok[nI]
        If (FEhCodigoZ3(cTok) .Or. (Len(cTok) >= 6 .And. FEhDigZ3(cTok))) .And. ;
           AScan(aChv, cTok) == 0
            AAdd(aChv, cTok)
        EndIf
    Next nI

    aPal := StrTokArr(cNorm, " ")
    nI   := 1

    Do While nI <= Len(aPal)
        cTok := aPal[nI]

        // CA colado: CA36995 vira a chave 36995. CA'S e o mesmo rotulo com
        // apostrofo, que a normalizacao escreve CAS.
        If cTok == "CA" .Or. cTok == "CAS"
            If nI < Len(aPal)
                cTok := aPal[nI + 1]
                nI   := nI + 2
            Else
                cTok := ""
                nI   := nI + 1
            EndIf
        ElseIf SubStr(cTok, 1, 2) == "CA" .And. Len(cTok) > 2
            cTok := SubStr(cTok, 3)
            nI   := nI + 1
        Else
            cTok := ""
            nI   := nI + 1
        EndIf

        If Len(cTok) >= 4 .And. Len(cTok) <= 6 .And. FEhDigZ3(cTok) .And. ;
           AScan(aChv, cTok) == 0
            AAdd(aChv, cTok)
        EndIf
    EndDo

Return aChv


//-------------------------------------------------------------------
/*/{Protheus.doc} FPnSemAZ3
Devolve o numero de material sem o A inicial do fabricante. O catalogo
grava o mesmo item com e sem o prefixo: o Part Number chega como
A9608300818 e o descritivo do cadastro escreve 9608300818. So vale para
o A seguido apenas de digito, com seis digitos ou mais - o mesmo minimo
de numero de material usado em FChavesPnZ3.
Usado por FPnNaDescZ3 (camada 1) e FChavesCodZ3 (camada 5).
@param cTok Token do Part Number, do descritivo ou codigo compactado.
@return cRet Numero sem o A inicial, ou vazio quando nao se aplica.
@type    Static Function
@author  Suprimentos
@since   03/11/2026
/*/
//-------------------------------------------------------------------
Static Function FPnSemAZ3(cTok)

    Local cNum := ""

    If Len(cTok) < 7 .Or. SubStr(cTok, 1, 1) != "A"
        Return ""
    EndIf

    cNum := SubStr(cTok, 2)

    If !FEhDigZ3(cNum)
        Return ""
    EndIf

Return cNum


//-------------------------------------------------------------------
/*/{Protheus.doc} FContemChvNumZ3
Informa se a chave so de digitos aparece no descritivo como numero
inteiro. Substring simples nao serve para a faixa do CA (quatro a seis
digitos): 17074 estaria dentro de 3454217074 e traria o pino do freio
Mercedes para quem pediu a luva CA 17074. Vale quando o caractere dos
dois lados nao e digito, que cobre CA17074, CA 17074 e 17074 isolado.
@param cChv   Chave so de digitos.
@param cTexto Descritivo normalizado do cadastro.
@return lRet .T. quando a chave existe com limite de numero.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FContemChvNumZ3(cChv, cTexto)

    Local cSub   := ""
    Local lOkAnt := .T.
    Local lOkPos := .T.
    Local nIni   := 1
    Local nLen   := Len(cChv)
    Local nPos   := 0

    Do While nIni <= Len(cTexto)
        cSub := SubStr(cTexto, nIni)
        nPos := At(cChv, cSub)

        If nPos == 0
            Exit
        EndIf

        nPos := nPos + nIni - 1

        lOkAnt := .T.
        lOkPos := .T.

        If nPos > 1 .And. SubStr(cTexto, nPos - 1, 1) $ "0123456789"
            lOkAnt := .F.
        EndIf

        If nPos + nLen <= Len(cTexto) .And. ;
           SubStr(cTexto, nPos + nLen, 1) $ "0123456789"
            lOkPos := .F.
        EndIf

        If lOkAnt .And. lOkPos
            Return .T.
        EndIf

        nIni := nPos + 1
    EndDo

Return .F.


//-------------------------------------------------------------------
/*/{Protheus.doc} FPnNaDescZ3
Informa se o Part Number aparece no descritivo do cadastro. Testa a frase
normalizada inteira, quando tem seis caracteres ou mais, e cada chave
extraida por FChavesPnZ3(), para o campo poder vir com rotulo e nome da
loja sem perder o numero.
Chave com dois digitos ou mais prova o item sozinha. Chave com um digito so
e norma ou padrao tecnico (CAT5E, IP68) e casa com a familia inteira; nesse
caso exige que o cadastro tenha o mesmo tipo de produto da solicitacao
(primeira palavra substantiva), senao "PLUG RJ45 CAT5E" traria todos os
cabos e tomadas CAT5E do catalogo.
Chave so de digitos na faixa do CA (quatro a seis) e procurada com limite
de numero, para 17074 nao casar dentro de 3454217074.
Chave com A inicial de fabricante (A9608300818) tambem vale sem o A,
porque o cadastro grava so 9608300818. Nesse caso a comparacao e por
palavra inteira do descritivo: B-272-2632 nao e A-272-2632.
@param cPnNorm   Part Number normalizado.
@param aPnChv    Chaves extraidas por FChavesPnZ3().
@param cDescNorm Descritivo normalizado do cadastro.
@param lFamilia  .T. quando o tipo do produto do cadastro e o mesmo da solicitacao.
@return lRet .T. quando o Part Number aparece no descritivo.
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FPnNaDescZ3(cPnNorm, aPnChv, cDescNorm, lFamilia)

    Local lTem  := .F.
    Local cSemA := ""
    Local nI    := 1

    If !Empty(cPnNorm) .And. Len(cPnNorm) >= 6 .And. (cPnNorm $ cDescNorm)
        Return .T.
    EndIf

    For nI := 1 To Len(aPnChv)
        lTem := aPnChv[nI] $ cDescNorm

        // Na faixa do CA a chave nao pode estar no meio de outro numero.
        If Len(aPnChv[nI]) >= 4 .And. Len(aPnChv[nI]) <= 6 .And. ;
           FEhDigZ3(aPnChv[nI])
            lTem := FContemChvNumZ3(aPnChv[nI], cDescNorm)
        EndIf

        If lTem .And. (FContaDigZ3(aPnChv[nI]) >= 2 .Or. lFamilia)
            Return .T.
        EndIf

        // A inicial do fabricante: o cadastro grava so o numero. So vale como
        // palavra inteira, senao B-272-2632 casaria com A-272-2632.
        cSemA := FPnSemAZ3(aPnChv[nI])
        If !Empty(cSemA) .And. AScan(StrTokArr(cDescNorm, " "), cSemA) > 0
            Return .T.
        EndIf
    Next nI

Return .F.


//-------------------------------------------------------------------
/*/{Protheus.doc} FCarregaSB1Z3
Carrega a SB1 inteira em memoria uma unica vez por sessao, ja com a chave
canonica de cada descritivo. A base tem cerca de 11.800 produtos, entao a
varredura completa em memoria e mais confiavel do que filtrar por LIKE no
SQL, que nao encontra o item quando a grafia difere.
A descricao completa (B1_ZDESCF) fica fora da carga porque e campo MEMO
gravado como varbinary(max) e lido pelo alias devolve apenas o ponteiro.
Cada linha do cache e {codigo, descricao, descricao normalizada, chave
canonica, palavras, numeros, tipo do produto, tokens brutos, segmentos
brutos}. As palavras e os numeros ja vem separados porque a camada de
descricao contida compara esses dois conjuntos item a item: separar a cada
comparacao custaria uma varredura inteira da base por solicitacao. O tipo do
produto entra tambem pronto porque a guarda da chave com um digito so o
consulta em cada item.
Os tokens brutos sao o descritivo como foi digitado, sem normalizacao,
unidos por barra vertical (|TOK|TOK|): a camada de codigo forte exige que o
codigo do fabricante apareca como palavra inteira no cadastro, e a
normalizacao junta palavra com medida e quebraria essa igualdade. Os
segmentos brutos quebram cada token nos pontos, hifens e barras, para o
trecho de um codigo composto ser comparado com o codigo curto do cadastro.
@return nRegs Quantidade de itens carregados no cache.
@type    Static Function
@author  Suprimentos
@since   29/10/2026
/*/
//-------------------------------------------------------------------
Static Function FCarregaSB1Z3(lRecarrega)

    Local aArea  := GetArea()
    Local cAlias := GetNextAlias()
    Local cQuery := ""
    Local aTok   := {}
    Local cDesc  := ""
    Local cNorm  := ""
    Local cToks  := ""
    Local cSegs  := ""

    Default lRecarrega := .F.

    If Len(aCacheSB1) > 0 .And. !lRecarrega
        Return Len(aCacheSB1)
    EndIf

    cQuery := " SELECT B1_COD, B1_DESC "
    cQuery += "   FROM " + RetSqlName("SB1") + " SB1 WITH (NOLOCK) "
    cQuery += "  WHERE D_E_L_E_T_ = ' ' "
    cQuery += "    AND B1_FILIAL = '" + xFilial("SB1") + "' "
    cQuery += "  ORDER BY B1_COD "
    cQuery := ChangeQuery(cQuery)
    cQuery := StrTran(cQuery, "(NOLOCK)", "")              // normaliza (evita dica duplicada)
    cQuery := StrTran(cQuery, " WITH ", " WITH (NOLOCK) ") // reinjeta a dica que o ChangeQuery remove

    If Select(cAlias) > 0
        (cAlias)->(DbCloseArea())
    EndIf

    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    // Recomeca o cache do zero: na recarga nao se pode acumular sobre a carga anterior.
    aCacheSB1 := {}

    (cAlias)->(DbGoTop())

    While !(cAlias)->(Eof())
        cDesc := AllTrim((cAlias)->B1_DESC)
        cNorm := FNormalZ3(cDesc)
        aTok  := FTokensZ3(cNorm)
        cToks := FToksBrutosZ3(cDesc)
        cSegs := FSegsBrutosZ3(cDesc)

        AAdd(aCacheSB1, { AllTrim((cAlias)->B1_COD), ;
                          cDesc                    , ;
                          cNorm                    , ;
                          FChaveZ3(aTok)           , ;
                          FSepTokZ3(aTok, .F.)     , ;
                          FSepTokZ3(aTok, .T.)     , ;
                          FCabecaZ3(cNorm)         , ;
                          cToks                    , ;
                          cSegs                    })

        (cAlias)->(DbSkip())
    EndDo

    (cAlias)->(DbCloseArea())
    RestArea(aArea)

Return Len(aCacheSB1)


//-------------------------------------------------------------------
/*/{Protheus.doc} FBlocoBrw
Devolve a linha do browse de duplicidades na ordem das colunas.
@param aLinhas Array de resultados de FAvaliaDupZ3().
@param nAt     Numero da linha atual do browse.
@return aLinha Linha na ordem codigo, descricao, fornecedor.
@type    Static Function
@author  Suprimentos
@since   29/10/2026
/*/
//-------------------------------------------------------------------
Static Function FBlocoBrw(aLinhas, nAt)

    If nAt >= 1 .And. nAt <= Len(aLinhas)
        Return { aLinhas[nAt,1], aLinhas[nAt,2], aLinhas[nAt,3] }
    EndIf

Return {"", "", ""}


//-------------------------------------------------------------------
/*/{Protheus.doc} FAvaliaDupZ3
Varre o cache da SB1 e devolve os itens que sao o mesmo produto do solicitado.
Sao cinco camadas, nesta ordem de prioridade:
  1 - Mesmo Part Number   o PN digitado aparece no descritivo do cadastro; chave
                          com um digito so (CAT5E, IP68) exige que o tipo do
                          produto da solicitacao tambem apareca no cadastro
  2 - Mesmas palavras     chave canonica identica, ordem das palavras irrelevante
  3 - Descricao contida   todas as palavras e numeros do cadastro existem no
                          descritivo da solicitacao, numeros compativeis
  4 - Mesmo codigo        codigo de fabricante em comum, uma descricao
                          contida na outra e nenhuma medida em conflito
  5 - Codigo forte        codigo de fabricante como palavra inteira no cadastro,
                          so quando nenhuma camada anterior achou nada
Descritivo apenas parecido fica de fora: a lista existe para mostrar duplicidade
real, nao sugestao, e resultado difuso esconde o item certo.
@param cDescZ3 Descricao digitada na solicitacao.
@param cPnZ3   Part number digitado na solicitacao.
@return aRet Vetor de {codigo, descricao, fornecedor}.
@type    Static Function
@author  Suprimentos
@since   29/10/2026
/*/
//-------------------------------------------------------------------
Static Function FAvaliaDupZ3(cDescZ3, cPnZ3)

    Local aRet    := {}
    Local aTmp    := {}
    Local aSol    := {}
    Local aPalSol := {}
    Local aNumSol := {}
    Local aN1     := {}
    Local aN2     := {}
    Local aN3     := {}
    Local aN4     := {}
    Local aN5     := {}
    Local aN6     := {}
    Local aCod    := {}
    Local aAdd    := {}
    Local aGrupos := {}
    Local aLinha  := {}
    Local aPnChv  := {}
    Local cChave   := ""
    Local cNormSol := ""
    Local cCabSol  := ""
    Local cPnNorm  := ""
    Local lAchou   := .F.
    Local lCodSol  := .F.
    Local lFam     := .F.
    Local nI       := 1
    Local nJ       := 1

    cNormSol := FNormalZ3(cDescZ3)
    aSol    := FTokensZ3(cNormSol)
    aPalSol := FSepTokZ3(aSol, .F.)
    aNumSol := FSepTokZ3(aSol, .T.)
    cChave  := FChaveZ3(aSol)
    cCabSol := FCabecaZ3(cNormSol)
    cPnNorm := FNormalZ3(cPnZ3)
    aPnChv  := FChavesPnZ3(cPnZ3)
    lCodSol := FTemCodZ3(aSol)

    If Len(aCacheSB1) == 0
        Return aRet
    EndIf

    For nI := 1 To Len(aCacheSB1)
        aLinha := aCacheSB1[nI]
        lAchou := .F.

        // PN com menos de 6 caracteres e bitola (1/16, M16X50), nao part number:
        // casaria com a familia inteira e mascararia o resultado do descritivo.
        // Chave de um digito so tambem precisa do tipo do produto: CAT5E e
        // norma, nao codigo, e sozinha traria toda a linha de cabos e tomadas.
        // Tipo so aparece na descricao nao basta: o cabo cita PLUG no texto e
        // nao e um plugue. O cadastro tem de comecar pelo mesmo tipo.
        lFam := Empty(cCabSol) .Or. cCabSol == aLinha[7]
        If FPnNaDescZ3(cPnNorm, aPnChv, aLinha[3], lFam)
            AAdd(aN1, { aLinha[1], aLinha[2], "" })
            lAchou := .T.
        ElseIf !Empty(cChave) .And. cChave == aLinha[4]
            AAdd(aN2, { aLinha[1], aLinha[2], "" })
            lAchou := .T.
        EndIf

        // Camada 3 so para o que nao entrou nas duas primeiras: o mesmo item
        // nao pode aparecer duas vezes na lista.
        If !lAchou .And. FContidoNumZ3(aPalSol, aNumSol, aLinha[5], aLinha[6])
            AAdd(aN3, { aLinha[1], aLinha[2], "" })
            lAchou := .T.
        EndIf

        // Camada 4 apenas quando a solicitacao traz codigo de fabricante. Sem
        // codigo, FContidoCodZ3 nunca casaria e a varredura seria desperdicio.
        If !lAchou .And. lCodSol .And. ;
           FContidoCodZ3(aPalSol, aNumSol, aLinha[5], aLinha[6])
            AAdd(aN4, { aLinha[1], aLinha[2], "" })
        EndIf
    Next nI

    // Camada 5, ultimo recurso: so roda quando as quatro anteriores nao
    // acharam nada. Procura o codigo forte do Part Number e, se nao houver,
    // o do descritivo, como palavra inteira no cadastro. Fica por ultimo
    // porque o codigo do fabricante identifica o item mesmo quando o
    // solicitante escreveu outra descricao, mas nao pode competir com uma
    // duplicidade ja provada por descritivo.
    If Len(aN1) + Len(aN2) + Len(aN3) + Len(aN4) == 0
        aCod := FChavesCodZ3(cPnZ3)
        aAdd := FAchaCodCacheZ3(aCod, cCabSol, cDescZ3)
        If Len(aAdd) == 0
            aCod := FChavesCodZ3(cDescZ3)
            aAdd := FAchaCodCacheZ3(aCod, cCabSol, cDescZ3)
        EndIf
        aN5 := aAdd
    EndIf

    // Camada 6, confianca alta: descritivo da solicitacao e versao resumida do
    // cadastro. Mesma condicao da Camada 5 e ligada por parametro; com
    // MV_Z3ALTA desligado a rotina nao e chamada e o resultado nao muda.
    If Len(aN1) + Len(aN2) + Len(aN3) + Len(aN4) + Len(aN5) == 0 .And. ;
       SuperGetMV("MV_Z3ALTA", .F., .F.)
        aN6 := FCamada6Z3(cDescZ3, cPnZ3, aPalSol, aNumSol, cCabSol)
    EndIf

    // O '+' nao concatena arrays em AdvPL (type mismatch): a juncao e por indice,
    // mantendo o Part Number na frente das mesmas palavras.
    aGrupos := { aN1, aN2, aN3, aN4, aN5, aN6 }

    For nI := 1 To Len(aGrupos)
        For nJ := 1 To Len(aGrupos[nI])
            AAdd(aRet, aGrupos[nI][nJ])
        Next nJ
    Next nI

    If Len(aRet) > 50
        aTmp := {}
        For nI := 1 To 50
            AAdd(aTmp, aRet[nI])
        Next nI
        aRet := aTmp
    EndIf

Return FCarregaFornZ3(aRet)


//-------------------------------------------------------------------
/*/{Protheus.doc} FCarregaFornZ3
Preenche o fornecedor de cada item da lista. A fonte principal e o ultimo
documento de entrada (nota fiscal) do produto; a filial atual tem
prioridade, mas a busca cobre todas as filiais da empresa - produto
comprado apenas pela matriz (0101) aparece mesmo com a solicitacao na
filial 0102. Quem ficar sem fornecedor recebe o do ultimo pedido de
compra (SC7), tambem de qualquer filial.
A consulta roda somente sobre os itens ja filtrados (no maximo 50), nunca
sobre a SB1 inteira.
As colunas do codigo do produto e do fornecedor variam conforme quem montou
o vetor: FAvaliaDupZ3() devolve {codigo, descricao, fornecedor} e
FVarreDupZ3() devolve {solicitacao, descricao pedida, codigo, descricao,
fornecedor}. Por isso as duas colunas sao parametros.
@param aDup     Vetor de duplicidades.
@param nColCod  Coluna que guarda o codigo do produto.
@param nColForn Coluna onde o fornecedor sera gravado.
@return aDup Mesmo vetor, com a coluna do fornecedor preenchida.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FCarregaFornZ3(aDup, nColCod, nColForn)

    Local cIn    := ""
    Local cInFal := ""
    Local nI     := 1

    Default nColCod  := 1
    Default nColForn := 3

    If Len(aDup) == 0
        Return aDup
    EndIf

    For nI := 1 To Len(aDup)
        cIn += "'" + StrTran(aDup[nI][nColCod], "'", "") + "',"
    Next nI
    cIn := SubStr(cIn, 1, Len(cIn) - 1)

    // Documento de entrada (nota fiscal) primeiro: e o fornecedor que de fato
    // entregou o produto. A filial atual tem prioridade, mas a consulta nao
    // se limita a ela - sem isso, produto comprado so pela matriz fica vazio.
    FBuscaFornZ3(aDup, nColCod, nColForn, cIn, .F.)

    // Quem ficou sem fornecedor recebe o do ultimo pedido de compra, tambem
    // de qualquer filial: cobre produto ja pedido e ainda sem nota de entrada.
    For nI := 1 To Len(aDup)
        If Empty(AllTrim(aDup[nI][nColForn]))
            cInFal += "'" + StrTran(aDup[nI][nColCod], "'", "") + "',"
        EndIf
    Next nI

    If !Empty(cInFal)
        cInFal := SubStr(cInFal, 1, Len(cInFal) - 1)
        FBuscaFornZ3(aDup, nColCod, nColForn, cInFal, .T.)
    EndIf

Return aDup


//-------------------------------------------------------------------
/*/{Protheus.doc} FBuscaFornZ3
Executa a consulta de fornecedor para os codigos informados e preenche a
coluna do fornecedor em aDup, sem sobrescrever quem ja tem fornecedor.
Duas fontes: o documento de entrada (SD1) e o pedido de compra (SC7). Nas
duas a filial atual vem antes das demais e, dentro da mesma prioridade,
vale o documento mais recente.
@param aDup     Vetor de duplicidades.
@param nColCod  Coluna que guarda o codigo do produto.
@param nColForn Coluna onde o fornecedor sera gravado.
@param cIn      Codigos ja entre aspas simples, separados por virgula.
@param lPedido  .T. consulta o pedido de compra; .F. o documento de entrada.
@return Nil
@type    Static Function
@author  Suprimentos
@since   31/10/2026
/*/
//-------------------------------------------------------------------
Static Function FBuscaFornZ3(aDup, nColCod, nColForn, cIn, lPedido)

    Local aArea  := GetArea()
    Local cAlias := GetNextAlias()
    Local cQuery := ""
    Local cCod   := ""
    Local cFil   := xFilial("SD1")
    Local nI     := 1

    Default lPedido := .F.

    cQuery := " SELECT X.COD, X.FORN FROM ( "

    If lPedido
        cQuery += "   SELECT C7.C7_PRODUTO AS COD, A2.A2_NOME AS FORN, "
        cQuery += "          ROW_NUMBER() OVER (PARTITION BY C7.C7_PRODUTO ORDER BY "
        cQuery += "            CASE WHEN C7.C7_FILIAL = '" + cFil + "' THEN 0 ELSE 1 END, "
        cQuery += "            C7.C7_EMISSAO DESC, C7.C7_NUM DESC) AS RN "
        cQuery += "     FROM " + RetSqlName("SC7") + " C7 WITH (NOLOCK) "
        cQuery += "    INNER JOIN " + RetSqlName("SA2") + " A2 WITH (NOLOCK) "
        cQuery += "            ON A2.D_E_L_E_T_ = ' ' "
        cQuery += "           AND A2.A2_COD  = C7.C7_FORNECE "
        cQuery += "           AND A2.A2_LOJA = C7.C7_LOJA "
        cQuery += "    WHERE C7.D_E_L_E_T_ = ' ' "
        cQuery += "      AND C7.C7_RESIDUO  <> 'S' "
        cQuery += "      AND C7.C7_QUANT    > 0 "
        cQuery += "      AND C7.C7_CONAPRO NOT IN ('R','B') "
        cQuery += "      AND C7.C7_PRODUTO IN (" + cIn + ") "
    Else
        cQuery += "   SELECT D1.D1_COD AS COD, A2.A2_NOME AS FORN, "
        cQuery += "          ROW_NUMBER() OVER (PARTITION BY D1.D1_COD ORDER BY "
        cQuery += "            CASE WHEN D1.D1_FILIAL = '" + cFil + "' THEN 0 ELSE 1 END, "
        cQuery += "            D1.D1_EMISSAO DESC, D1.D1_DOC DESC) AS RN "
        cQuery += "     FROM " + RetSqlName("SD1") + " D1 WITH (NOLOCK) "
        cQuery += "    INNER JOIN " + RetSqlName("SA2") + " A2 WITH (NOLOCK) "
        cQuery += "            ON A2.D_E_L_E_T_ = ' ' "
        cQuery += "           AND A2.A2_COD  = D1.D1_FORNECE "
        cQuery += "           AND A2.A2_LOJA = D1.D1_LOJA "
        cQuery += "    WHERE D1.D_E_L_E_T_ = ' ' "
        cQuery += "      AND D1.D1_COD IN (" + cIn + ") "
    EndIf

    cQuery += " ) X WHERE X.RN = 1 "

    cQuery := ChangeQuery(cQuery)
    cQuery := StrTran(cQuery, "(NOLOCK)", "")              // normaliza (evita dica duplicada)
    cQuery := StrTran(cQuery, " WITH ", " WITH (NOLOCK) ") // reinjeta a dica que o ChangeQuery remove

    If Select(cAlias) > 0
        (cAlias)->(DbCloseArea())
    EndIf

    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    (cAlias)->(DbGoTop())

    While !(cAlias)->(Eof())
        cCod := AllTrim((cAlias)->COD)

        For nI := 1 To Len(aDup)
            If AllTrim(aDup[nI][nColCod]) == cCod .And. ;
               Empty(AllTrim(aDup[nI][nColForn]))
                aDup[nI][nColForn] := AllTrim((cAlias)->FORN)
            EndIf
        Next nI

        (cAlias)->(DbSkip())
    EndDo

    (cAlias)->(DbCloseArea())
    RestArea(aArea)

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FVerifDupZ3
Apresenta os produtos do cadastro que possivelmente ja sao o item
solicitado. A lista e informativa: fechada a janela, o fluxo segue.
@param cDescZ3 Descricao digitada na solicitacao.
@param cPnZ3   Part number digitado na solicitacao.
@param lRecarrega .T. recarrega o cache da SB1 (botao manual).
@param lAvisaVazio .T. avisa quando nada foi encontrado. No Confirmar o fluxo
seguir direto, sem mensagem: a janela so aparece quando ha duplicidade.
@return .T. A verificacao nao bloqueia a gravacao.
@type    Static Function
@author  Suprimentos
@since   29/10/2026
/*/
//-------------------------------------------------------------------
Static Function FVerifDupZ3(cDescZ3, cPnZ3, lRecarrega, lAvisaVazio)

    Local aDups   := {}
    Local oDlgDup := Nil
    Local oBrwDup := Nil
    Local oSayDup := Nil
    Local cTit    := ""

    Default lRecarrega  := .F.
    Default lAvisaVazio := .T.

    If Empty(AllTrim(cDescZ3))
        Return .T.
    EndIf

    FCarregaSB1Z3(lRecarrega)

    aDups := FAvaliaDupZ3(cDescZ3, cPnZ3)

    If Len(aDups) == 0
        If lAvisaVazio
            MsgInfo("Nenhum produto com o mesmo Part Number, as mesmas palavras," + ENTER + ;
                    "a descricao contida com os mesmos numeros ou o mesmo codigo" + ENTER + ;
                    "de fabricante foi encontrado no cadastro." + ENTER + ;
                    "A solicitacao pode ser registrada.", "Verificacao de Duplicidade")
        EndIf
        Return .T.
    EndIf

    cTit := "Produtos ja cadastrados - " + AllTrim(Str(Len(aDups))) + " item(ns)"

    // A moldura do MSDIALOG usa o valor literal, mas as coordenadas dos controles
    // sao renderizadas com zoom do ambiente (~2x). Por isso a moldura e declarada
    // com o dobro da area ocupada pelos controles, como em ZANALBX e IMPSLDINI;
    // sem isso a ultima coluna e os botoes ficam fora da janela.
    DEFINE MSDIALOG oDlgDup TITLE cTit FROM 000, 000 TO 400, 800 COLORS 0, 16777215 PIXEL

        @ 008, 012 SAY oSayDup PROMPT "Produtos do cadastro que sao o mesmo item da solicitacao:" ;
            SIZE 700, 020 OF oDlgDup COLORS 0, 16777215 PIXEL

        oBrwDup := TCBrowse():New( 034 , 012, 376, 150,,;
                                  {'Codigo','Descricao','Fornecedor'},{40,196,140},;
                                  oDlgDup,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )

        oBrwDup:SetArray(aDups)
        oBrwDup:bLine := {|| FBlocoBrw(aDups, oBrwDup:nAt) }

    ACTIVATE MSDIALOG oDlgDup CENTERED

Return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} CADANLZ3
Analisa um item antes do cadastro: o usuario digita a descricao e o Part
Number, como no formulario de solicitacao, e a rotina mostra os produtos do
cadastro que sao o mesmo item. Serve para testar variacoes de escrita - trocar
palavra, tirar medida, mudar o codigo - e clicar em Analisar de novo, sem
gravar nada. A lista e a mesma do botao Verificar Duplicidade (FVerifDupZ3).
@type    User Function
@author  Suprimentos
@since   03/11/2026
/*/
//-------------------------------------------------------------------
User Function CADANLZ3()

    Local cDesc  := Space(120)
    Local cPn    := Space(150)
    Local oDlgA  := Nil
    Local oSayD  := Nil
    Local oSayP  := Nil
    Local oSayA1 := Nil
    Local oSayA2 := Nil
    Local oGetD  := Nil
    Local oGetP  := Nil

    // A moldura do MSDIALOG e literal e os controles renderizam com o zoom do
    // ambiente (~2x), por isso a moldura e declarada com o dobro da area que
    // os controles ocupam.
    DEFINE MSDIALOG oDlgA TITLE "Analisar Cadastro" FROM 000, 000 TO 360, 1100 COLORS 0, 16777215 PIXEL

        @ 014, 012 SAY oSayD PROMPT "Descricao do produto:" ;
            SIZE 400, 014 OF oDlgA COLORS 0, 16777215 PIXEL
        @ 032, 012 MSGET oGetD VAR cDesc SIZE 500, 012 OF oDlgA COLORS 0, 16777215 PIXEL

        @ 068, 012 SAY oSayP PROMPT "Part Number:" ;
            SIZE 400, 014 OF oDlgA COLORS 0, 16777215 PIXEL
        @ 086, 012 MSGET oGetP VAR cPn SIZE 500, 012 OF oDlgA COLORS 0, 16777215 PIXEL

        @ 116, 012 SAY oSayA1 PROMPT "Escreva a descricao e o Part Number e clique em Analisar." ;
            SIZE 500, 014 OF oDlgA COLORS 0, 16777215 PIXEL
        @ 132, 012 SAY oSayA2 PROMPT "Troque a escrita para testar variacoes. Nada e gravado." ;
            SIZE 500, 014 OF oDlgA COLORS 0, 16777215 PIXEL

        TButton():New( 150, 012, "Analisar", oDlgA,{|| FAnalisaItemZ3(cDesc, cPn) },;
         60,012,,,.F.,.T.,.F.,,.F.,,,.F. )
        TButton():New( 150, 086, "Fechar", oDlgA,{|| oDlgA:End() },;
         60,012,,,.F.,.T.,.F.,,.F.,,,.F. )

    ACTIVATE MSDIALOG oDlgA CENTERED

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FAnalisaItemZ3
Executa a verificacao de duplicidade para o texto digitado na tela Analisar
Cadastro. A descricao e obrigatoria; o Part Number e opcional, porque as
camadas de palavras e de descricao contida decidem sem ele. O cadastro de
produtos e carregado uma vez por sessao, com progresso na primeira vez.
@param cDesc Descricao digitada.
@param cPn   Part Number digitado.
@return Nil
@type    Static Function
@author  Suprimentos
@since   03/11/2026
/*/
//-------------------------------------------------------------------
Static Function FAnalisaItemZ3(cDesc, cPn)

    If Empty(AllTrim(cDesc))
        MsgStop("Informe a descricao do produto.", "Analisar Cadastro")
        Return Nil
    EndIf

    If Len(aCacheSB1) == 0
        Processa({ || FCarregaSB1Z3() }, "Carregando cadastro de produtos...")
    EndIf

    FVerifDupZ3(cDesc, cPn, .F., .T.)

Return Nil


//-------------------------------------------------------------------
/*/{Protheus.doc} FConfirmaZ3
Mostra a verificacao de duplicidade entre o botao Confirmar e a gravacao.
A lista e informativa e nao impede a gravacao.
Nao altera as assinaturas de FGravDados e FSaveSZ3.
@param lAlterar .T. na alteracao de solicitacao existente, .F. na inclusao.
@param nRecNo   Numero do registro na SZ3 (usado somente na alteracao).
@param cDescProd Descricao do produto.
@param cPart    Part number.
@param cLink    Link de referencia.
@param cUM      Unidade de medida.
@param cUrg     Urgente (S/N).
@param cAplic   Aplicacao.
@param cMotivo  Motivo da urgencia.
@type    Static Function
@author  Suprimentos
@since   29/10/2026
/*/
//-------------------------------------------------------------------
Static Function FConfirmaZ3(lAlterar, nRecNo, cDescProd, cPart, cLink, cUM, cUrg, cAplic, cMotivo)

    // Sem aviso quando nada e encontrado: o Confirmar segue direto e a janela
    // so aparece quando ha produto ja cadastrado com a mesma identificacao.
    FVerifDupZ3(cDescProd, cPart, .F., .F.)

    If lAlterar
        FSaveSZ3(nRecNo, cDescProd, cPart, cLink, cUM, cUrg, cAplic, cMotivo)
    Else
        FGravDados(cDescProd, cPart, cLink, cUM, cUrg, cAplic, cMotivo)
    EndIf

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} CADVERZ3
Varre as solicitacoes pendentes da SZ3 e mostra quais delas ja tem produto
cadastrado na SB1, com a mesma regra do botao Verificar Duplicidade: mesmo
Part Number, as mesmas palavras, a descricao contida com os mesmos numeros
ou o mesmo codigo de fabricante.
A lista e informativa: nada e alterado na solicitacao nem no cadastro.
@type    User Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
User Function CADVERZ3()

    Local aArea  := GetArea()
    Local aIdx   := {}
    Local aDups  := {}
    Local aTmp   := {}
    Local nTotal := 0
    Local nI     := 1
    Local cTit   := ""
    Local oDlgV  := Nil
    Local oBrwV  := Nil
    Local oSayV  := Nil

    If Select("SZ3") <= 0
        ChkFile("SZ3")
    EndIf

    // Recarga sempre: a varredura tem de olhar a SB1 de agora.
    FCarregaSB1Z3(.T.)

    If Len(aCacheSB1) == 0
        MsgInfo("Nao foi possivel carregar o cadastro de produtos." + ENTER + ;
                "A verificacao nao foi executada.", "Verificar Cadastros")
        RestArea(aArea)
        Return
    EndIf

    aIdx := FIndiceSB1Z3()

    Processa({ || aDups := FVarreDupZ3(aIdx) }, "Verificando solicitacoes pendentes...")

    nTotal := Len(aDups)

    If nTotal == 0
        MsgInfo("Nenhuma solicitacao pendente tem produto com o mesmo Part Number," + ENTER + ;
                "as mesmas palavras, a descricao contida com os mesmos numeros ou o" + ENTER + ;
                "mesmo codigo de fabricante ja cadastrado.", "Verificar Cadastros")
        RestArea(aArea)
        Return
    EndIf

    // O fornecedor de cada item custa uma consulta com a lista de codigos:
    // acima de 500 linhas a tela perde utilidade e a consulta fica pesada.
    If nTotal > 500
        For nI := 1 To 500
            AAdd(aTmp, aDups[nI])
        Next nI
        aDups := aTmp
    EndIf

    // O vetor da varredura tem o ID da solicitacao na coluna 1; o codigo do
    // produto esta na 3 e o fornecedor vai para a 5.
    aDups := FCarregaFornZ3(aDups, 3, 5)

    If nTotal > 500
        cTit := "Solicitacoes com produto cadastrado - exibindo 500 de " + AllTrim(Str(nTotal))
    Else
        cTit := "Solicitacoes com produto cadastrado - " + AllTrim(Str(nTotal)) + " item(ns)"
    EndIf

    // Mesmo dimensionamento do modal de duplicidade: a moldura usa o valor
    // literal e os controles renderizam com zoom do ambiente (~2x). A altura
    // comporta o browse e a linha do botao de impressao.
    DEFINE MSDIALOG oDlgV TITLE cTit FROM 000, 000 TO 480, 1100 COLORS 0, 16777215 PIXEL

        @ 008, 012 SAY oSayV PROMPT "Produto do cadastro que e o mesmo item da solicitacao:" ;
            SIZE 700, 020 OF oDlgV COLORS 0, 16777215 PIXEL

        oBrwV := TCBrowse():New( 034 , 012, 506, 150,,;
                                 {'Solicitacao','Descricao solicitada','Codigo','Descricao do cadastro','Fornecedor'},;
                                 {60,150,60,150,86},;
                                 oDlgV,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )

        oBrwV:SetArray(aDups)
        oBrwV:bLine := {|| FBlocoVerZ3(aDups, oBrwV:nAt) }

        // Imprime exatamente as linhas que estao na tela.
        TButton():New( 200, 012, "Imprimir", oDlgV,{|| FVerImpZ3(aDups) },;
         70,012,,,.F.,.T.,.F.,,.F.,,,.F. )

    ACTIVATE MSDIALOG oDlgV CENTERED

    RestArea(aArea)

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FVerImpZ3
Imprime a lista de solicitacoes com produto cadastrado, nas mesmas colunas
e na mesma ordem da tela aberta por CADVERZ3().
@param aLinhas Vetor de {solicitacao, descricao pedida, codigo, descricao, fornecedor}.
@return Nil
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FVerImpZ3(aLinhas)

    Local oReport  := Nil
    Local oSection := Nil

    If Len(aLinhas) == 0
        MsgInfo("Nenhuma solicitacao para imprimir.", "Verificar Cadastros")
        Return
    EndIf

    oReport := TReport():New("VERCADZ3", ;
        "Solicitacoes com Produto Cadastrado", "", ;
        {|oRep| FMontaImpZ3(oRep, aLinhas)}, ;
        "Solicitacoes pendentes que ja possuem produto cadastrado")

    // Cinco colunas com duas descricoes so cabem na folha deitada.
    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    oSection := TRSection():New(oReport, "Solicitacoes", {})

    TRCell():New(oSection, "SOL",   "", "Solicitacao",           "@!", 10)
    TRCell():New(oSection, "DESCS", "", "Descricao solicitada",  "@!", 34)
    TRCell():New(oSection, "COD",   "", "Codigo",                "@!", 12)
    TRCell():New(oSection, "DESCC", "", "Descricao do cadastro", "@!", 34)
    TRCell():New(oSection, "FORN",  "", "Fornecedor",            "@!", 22)

    oReport:PrintDialog()

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FMontaImpZ3
Monta as linhas do relatorio a partir do vetor exibido na tela.
@param oReport Relatorio criado por FVerImpZ3().
@param aLinhas Vetor de {solicitacao, descricao pedida, codigo, descricao, fornecedor}.
@return Nil
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FMontaImpZ3(oReport, aLinhas)

    Local oSection := oReport:Section(1)
    Local nI       := 1

    oSection:Init()

    For nI := 1 To Len(aLinhas)
        oSection:Cell("SOL"):SetValue(AllTrim(aLinhas[nI][01]))
        oSection:Cell("DESCS"):SetValue(AllTrim(aLinhas[nI][02]))
        oSection:Cell("COD"):SetValue(AllTrim(aLinhas[nI][03]))
        oSection:Cell("DESCC"):SetValue(AllTrim(aLinhas[nI][04]))
        oSection:Cell("FORN"):SetValue(AllTrim(aLinhas[nI][05]))

        oSection:PrintLine()
        oReport:IncMeter()
    Next nI

    oSection:Finish()

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FVarreDupZ3
Percorre as solicitacoes pendentes e devolve uma linha por produto do
cadastro que casa com a solicitacao, na mesma ordem de FAvaliaDupZ3():
primeiro as de Part Number, depois as de mesmas palavras, em seguida as de
descricao contida com numeros compativeis, depois as de mesmo codigo de
fabricante e por fim as de codigo forte exato, que so entram quando as
quatro anteriores nao acharam nada.
@param aIdx Indice da SB1 ordenado por chave (ver FIndiceSB1Z3()).
@return aRet Vetor de {solicitacao, descricao pedida, codigo, descricao, fornecedor}.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FVarreDupZ3(aIdx)

    Local aArea   := GetArea()
    Local aRet    := {}
    Local aJa     := {}
    Local aSol    := {}
    Local aPalSol := {}
    Local aNumSol := {}
    Local aPnChv  := {}
    Local aCod    := {}
    Local aAdd    := {}
    Local cFilAux := xFilial("SZ3")
    Local cDesc   := ""
    Local cPn     := ""
    Local cChave  := ""
    Local cPnNorm := ""
    Local cCabSol := ""
    Local lCodSol := .F.
    Local lFam    := .F.
    // Lido uma vez, fora do laco: parametro nao pode ser consultado por linha.
    Local lAlta   := SuperGetMV("MV_Z3ALTA", .F., .F.)
    Local nI      := 1
    Local nJ      := 1
    Local nPos    := 0

    SZ3->(DbSetOrder(1))
    SZ3->(DbGoTop())

    While !SZ3->(Eof())
        If !SZ3->(Deleted()) .And. ;
           SZ3->Z3_FILIAL == cFilAux .And. ;
           AllTrim(SZ3->Z3_STATUS) == "0"

            cDesc   := AllTrim(SZ3->Z3_DESCRI)
            cPn     := AllTrim(SZ3->Z3_PN)
            cPnNorm := FNormalZ3(cPn)
            aSol    := FTokensZ3(FNormalZ3(cDesc))
            aPalSol := FSepTokZ3(aSol, .F.)
            aNumSol := FSepTokZ3(aSol, .T.)
            cChave  := FChaveZ3(aSol)
            cCabSol := FCabecaZ3(FNormalZ3(cDesc))
            aPnChv  := FChavesPnZ3(cPn)
            lCodSol := FTemCodZ3(aSol)
            aJa     := {}

            // Camada 1: o Part Number digitado aparece no descritivo do cadastro.
            If !Empty(cPnNorm) .Or. Len(aPnChv) > 0
                For nJ := 1 To Len(aCacheSB1)
                    lFam := Empty(cCabSol) .Or. cCabSol == aCacheSB1[nJ][7]
                    If FPnNaDescZ3(cPnNorm, aPnChv, aCacheSB1[nJ][3], lFam)
                        AAdd(aRet, { AllTrim(SZ3->Z3_ID), cDesc, aCacheSB1[nJ][1], aCacheSB1[nJ][2], "" })
                        AAdd(aJa, aCacheSB1[nJ][1])
                    EndIf
                Next nJ
            EndIf

            // Camada 2: mesmas palavras, sem repetir o que a camada 1 ja achou.
            If !Empty(cChave)
                nPos := FBuscaChaveZ3(aIdx, cChave)
                nJ   := nPos
                Do While nJ > 0 .And. nJ <= Len(aIdx) .And. aIdx[nJ][1] == cChave
                    If AScan(aJa, aIdx[nJ][2]) == 0
                        AAdd(aRet, { AllTrim(SZ3->Z3_ID), cDesc, aIdx[nJ][2], aIdx[nJ][3], "" })
                        AAdd(aJa, aIdx[nJ][2])
                    EndIf
                    nJ := nJ + 1
                EndDo
            EndIf

            // Camada 3: descricao do cadastro contida na solicitacao, com os
            // numeros compativeis. Compara so o que as camadas anteriores nao
            // acharam, para nao repetir a linha.
            For nJ := 1 To Len(aCacheSB1)
                If AScan(aJa, aCacheSB1[nJ][1]) == 0 .And. ;
                   FContidoNumZ3(aPalSol, aNumSol, aCacheSB1[nJ][5], aCacheSB1[nJ][6])
                    AAdd(aRet, { AllTrim(SZ3->Z3_ID), cDesc, aCacheSB1[nJ][1], aCacheSB1[nJ][2], "" })
                    AAdd(aJa, aCacheSB1[nJ][1])
                EndIf
            Next nJ

            // Camada 4: mesmo codigo de fabricante, com a solicitacao contida
            // no cadastro. Pulado quando a solicitacao nao traz codigo.
            If lCodSol
                For nJ := 1 To Len(aCacheSB1)
                    If AScan(aJa, aCacheSB1[nJ][1]) == 0 .And. ;
                       FContidoCodZ3(aPalSol, aNumSol, aCacheSB1[nJ][5], aCacheSB1[nJ][6])
                        AAdd(aRet, { AllTrim(SZ3->Z3_ID), cDesc, aCacheSB1[nJ][1], aCacheSB1[nJ][2], "" })
                        AAdd(aJa, aCacheSB1[nJ][1])
                    EndIf
                Next nJ
            EndIf

            // Camada 5, ultimo recurso: so roda quando as quatro anteriores
            // nao acharam nada. Procura o codigo forte do Part Number e, se
            // nao houver, o do descritivo, como palavra inteira no cadastro.
            If Len(aJa) == 0
                aCod := FChavesCodZ3(cPn)
                aAdd := FAchaCodCacheZ3(aCod, cCabSol, cDesc)
                If Len(aAdd) == 0
                    aCod := FChavesCodZ3(cDesc)
                    aAdd := FAchaCodCacheZ3(aCod, cCabSol, cDesc)
                EndIf
                For nJ := 1 To Len(aAdd)
                    AAdd(aRet, { AllTrim(SZ3->Z3_ID), cDesc, aAdd[nJ][1], aAdd[nJ][2], "" })
                    AAdd(aJa, aAdd[nJ][1])
                Next nJ
            EndIf

            // Camada 6, confianca alta: mesma condicao da Camada 5. O retorno
            // da camada ja vem no formato {codigo, descricao, ""}.
            If lAlta .And. Len(aJa) == 0
                aAdd := FCamada6Z3(cDesc, cPn, aPalSol, aNumSol, cCabSol)
                If Len(aAdd) > 0
                    AAdd(aRet, { AllTrim(SZ3->Z3_ID), cDesc, aAdd[1][1], aAdd[1][2], "" })
                    AAdd(aJa, aAdd[1][1])
                EndIf
            EndIf
        EndIf

        SZ3->(DbSkip())
    EndDo

    RestArea(aArea)

Return aRet


//-------------------------------------------------------------------
/*/{Protheus.doc} FCamada6Z3
Sexta camada de duplicidade: confianca alta sobre descritivo resumido.
O cadastro costuma trazer detalhe que a solicitacao omite (material,
acabamento, embalagem, marca). Aqui a solicitacao e tratada como versao
resumida do cadastro e so entra quando as camadas 1 a 5 nao acharam nada.
Exige o mesmo tipo de produto, todos os numeros da solicitacao presentes,
nenhuma medida em conflito, mesmo tamanho, CA e voltagem, e cobertura minima
do peso das palavras (Z3_COBERT6). Quando a solicitacao nao traz numero nem
codigo de fabricante, a decisao so pode ser por palavras, e nesse caso exige
todas elas presentes no cadastro. Devolve no maximo um item: quando mais de um
cadastro passa em todas as provas, escolhe o de maior nota (cobertura ponderada
mais bonus de codigo de fabricante) somente se a nota for alta e a folga para o
segundo for de ao menos Z3_FOLGA6; caso contrario, o caso e ambiguo e nada e
devolvido.
A leitura de MV_Z3ALTA fica nas rotinas chamadoras, fora do laco da varredura
em lote, porque parametro nao pode ser consultado linha a linha.
@param cDescSol Descritivo da solicitacao.
@param cPnSol   Part Number da solicitacao.
@param aPalSol  Palavras da solicitacao (FSepTokZ3 .F.).
@param aNumSol  Numeros da solicitacao (FSepTokZ3 .T.).
@param cCabSol  Tipo do produto da solicitacao (FCabecaZ3).
@return aRet Vetor vazio ou com uma linha {codigo, descricao, ""}.
@type    Static Function
@author  Suprimentos
@since   03/11/2026
/*/
//-------------------------------------------------------------------
Static Function FCamada6Z3(cDescSol, cPnSol, aPalSol, aNumSol, cCabSol)

    Local aStop   := FStopZ3()
    Local aTams   := {"P", "M", "G", "GG", "XG", "XGG", "EG", "EGG"}
    Local aTamsF  := {"GG", "XG", "XGG", "EG", "EGG"}
    Local aVolUni := {"V", "VCA", "VCC", "VDC", "VAC"}
    Local aBruto  := {}
    Local aPal    := {}
    Local aPalCad := {}
    Local aPart   := {}
    Local aTamSol := {}
    Local aCodSol := {}
    Local aVolSol := {}
    Local aPeso   := {}
    Local aBucket := {}
    Local aLinha  := {}
    Local aAchou  := {}
    Local aPts    := {}
    Local cPal    := ""
    Local cTok    := ""
    Local cCA     := ""
    Local cFull   := ""
    Local cNuc    := ""
    Local cUni    := ""
    Local cParte  := ""
    Local cProd   := ""
    Local cCadP   := ""
    Local lCodAlfa := .F.
    Local lFaltaCod := .F.
    Local lMarc   := .F.
    Local lOk     := .F.
    Local lVolOk  := .F.
    Local lSoPal  := .F.
    Local lTmp    := .F.
    Local nB      := 0
    Local nC      := 0
    Local nDf     := 0
    Local nDocs   := 0
    Local nI      := 1
    Local nJ      := 1
    Local nK      := 1
    Local nP      := 0
    Local nPeso   := 0
    Local nTot    := 0
    Local nCob    := 0
    Local nScr    := 0
    Local nMelhor := 0
    Local nSegundo := 0

    // (a) Sem tipo de produto nao ha como decidir: fica para revisao manual.
    If Empty(cCabSol) .Or. Len(aCacheSB1) == 0
        Return aAchou
    EndIf

    // Tamanho: GG, XG e afins valem em qualquer posicao; P, M e G so depois de
    // TAMANHO/TAM, porque sozinhos podem significar outra coisa (M de macho).
    aBruto := FTokBrutoZ3(cDescSol)
    For nJ := 1 To Len(aBruto)
        cTok := aBruto[nJ]
        If cTok == "TAMANHO" .Or. cTok == "TAM"
            lMarc := .T.
        ElseIf lMarc
            If AScan(aTams, cTok) > 0
                FAddUniqZ3(@aTamSol, cTok)
            EndIf
            lMarc := .F.
        ElseIf AScan(aTamsF, cTok) > 0
            FAddUniqZ3(@aTamSol, cTok)
        EndIf
    Next nJ

    // CA: FStopZ3 descarta o rotulo, entao o numero e lido do texto normalizado.
    // CA'S e o mesmo rotulo com apostrofo, que a normalizacao escreve CAS.
    aPal := StrTokArr(FNormalZ3(cDescSol), " ")
    For nJ := 1 To Len(aPal)
        cTok := AllTrim(aPal[nJ])
        If (cTok == "CA" .Or. cTok == "CAS") .And. nJ < Len(aPal)
            cTok := AllTrim(aPal[nJ + 1])
            If FEhDigZ3(cTok) .And. Len(cTok) >= 4 .And. Len(cTok) <= 6
                cCA := cTok
            EndIf
        ElseIf SubStr(cTok, 1, 2) == "CA" .And. Len(cTok) > 2
            cTok := SubStr(cTok, 3)
            If FEhDigZ3(cTok) .And. Len(cTok) >= 4 .And. Len(cTok) <= 6
                cCA := cTok
            EndIf
        EndIf
    Next nJ

    // Codigo de fabricante e voltagem pedida. O codigo e lido como foi
    // digitado, sem a normalizacao que cola palavra com medida: vale o token
    // inteiro e cada trecho separado por ponto, hifen ou barra
    // (SCHIOPPA-K7658 -> SCHIOPPAK7658 e K7658). Rotulo de campo ou norma
    // (COD.20877, NR-10) fica de fora, porque o numero atras nao e do produto.
    aPal := FTokBrutoZ3(cDescSol + " " + cPnSol)
    For nJ := 1 To Len(aPal)
        cFull := FSoAlfaNumZ3(aPal[nJ])
        lTmp  := .F.
        For nK := 1 To Len(aCodSol)
            If aCodSol[nK][1] == cFull
                lTmp := .T.
            EndIf
        Next nK
        If !Empty(cFull) .And. !lTmp .And. !FEhRotuloCodZ3(aPal[nJ])
            lCodAlfa := FEhCodAlfaZ3(cFull)
            aPart    := FPartesCodZ3(aPal[nJ], FTemLetraZ3(aPal[nJ]))
            If (lCodAlfa .And. Len(cFull) >= 5) .Or. Len(aPart) > 0
                AAdd(aCodSol, { cFull, aPart, lCodAlfa })
            EndIf
        EndIf
    Next nJ
    For nJ := 1 To Len(aNumSol)
        If AScan(aVolUni, FUnidNumZ3(aNumSol[nJ])) > 0
            AAdd(aVolSol, aNumSol[nJ])
        EndIf
    Next nJ

    // (b) Sem numero/medida e sem codigo de fabricante a decisao so pode ser
    // por palavras, e nesse caso exige 100% delas no cadastro. Sem nenhuma
    // palavra util tambem nao ha decisao.
    If Len(aNumSol) == 0 .And. Len(aCodSol) == 0
        If Len(aPalSol) == 0
            Return aAchou
        EndIf
        lSoPal := .T.
    EndIf

    // Peso por raridade (IDF): total de produtos dividido pela quantidade que
    // tem a palavra, limitado a 20. Evita Log(), nao confirmado neste release.
    nDocs := Len(aCacheSB1)
    If !lIdfOkZ3 .Or. nIdfDocZ3 != nDocs
        aIdfZ3 := {}
        For nI := 1 To Z3_IDF_BUCKETS
            AAdd(aIdfZ3, {})
        Next nI
        For nI := 1 To nDocs
            aPal := aCacheSB1[nI][5]
            For nJ := 1 To Len(aPal)
                cPal := aPal[nJ]
                nB   := 0
                For nC := 1 To Len(cPal)
                    nB := (nB * 31 + Asc(SubStr(cPal, nC, 1))) % Z3_IDF_BUCKETS
                Next nC
                nB += 1
                aBucket := aIdfZ3[nB]
                nK := 1
                Do While nK <= Len(aBucket) .And. aBucket[nK][1] != cPal
                    nK += 1
                EndDo
                If nK > Len(aBucket)
                    AAdd(aBucket, { cPal, 1 })
                Else
                    aBucket[nK][2] := aBucket[nK][2] + 1
                EndIf
                aIdfZ3[nB] := aBucket
            Next nJ
        Next nI
        nIdfDocZ3 := nDocs
        lIdfOkZ3  := .T.
    EndIf

    For nJ := 1 To Len(aPalSol)
        cPal  := aPalSol[nJ]
        nPeso := 0
        // TAMANHO/TAM sao rotulos do proprio criterio de tamanho, nao
        // descricao do produto: nao podem diluir a cobertura de palavras.
        If AScan(aStop, cPal) == 0 .And. cPal != "TAMANHO" .And. cPal != "TAM"
            nB := 0
            For nC := 1 To Len(cPal)
                nB := (nB * 31 + Asc(SubStr(cPal, nC, 1))) % Z3_IDF_BUCKETS
            Next nC
            nB += 1
            aBucket := aIdfZ3[nB]
            nDf := 0
            For nK := 1 To Len(aBucket)
                If aBucket[nK][1] == cPal
                    nDf := aBucket[nK][2]
                    Exit
                EndIf
            Next nK
            nPeso := nDocs / (nDf + 1)
            If nPeso > Z3_PESOMAX
                nPeso := Z3_PESOMAX
            EndIf
        EndIf
        AAdd(aPeso, nPeso)
        nTot += nPeso
    Next nJ

    // Modo so palavras sem nenhum peso util (por exemplo, so rotulos): sem
    // decisao, porque a cobertura de 100% seria vazia.
    If lSoPal .And. nTot == 0
        Return aAchou
    EndIf

    For nI := 1 To Len(aCacheSB1)
        aLinha := aCacheSB1[nI]
        nScr   := 0

        // (a) Filtro barato: so o mesmo tipo de produto entra nas provas caras.
        lOk := aLinha[7] == cCabSol

        // (c) Todo numero da solicitacao precisa encaixar no cadastro. Numero
        // so do cadastro e detalhe e nao reprova. CA colado no cadastro
        // (CA48582) nao entra em aLinha[6]; nesse caso vale a prova de limite
        // de numero da propria Camada 6.
        If lOk
            For nJ := 1 To Len(aNumSol)
                If !FNumEncaixaZ3(aNumSol[nJ], aLinha[6]) .And. ;
                   !(!Empty(cCA) .And. aNumSol[nJ] == cCA .And. ;
                     FContemChvNumZ3(cCA, aLinha[3]))
                    lOk := .F.
                    Exit
                EndIf
            Next nJ
        EndIf

        // (f) Codigo de fabricante da solicitacao precisa estar no cadastro,
        // inteiro ou por um dos trechos. Quando o codigo alfanumerico nao
        // aparece, a prova que resta e a descricao: a cobertura de palavras
        // passa a exigir 100%, senao o "codigo parecido" aprovava sozinho.
        lFaltaCod := .F.
        If lOk
            For nJ := 1 To Len(aCodSol)
                If aCodSol[nJ][3] .And. !FAchouCodLinZ3(aCodSol[nJ], aLinha)
                    lFaltaCod := .T.
                EndIf
            Next nJ
        EndIf

        // (e) CA pedido precisa existir no cadastro, colado ou separado.
        If lOk .And. !Empty(cCA)
            If !FContemChvNumZ3(cCA, aLinha[3])
                lOk := .F.
            EndIf
        EndIf

        // (e) Tamanho pedido precisa existir igual no cadastro.
        If lOk .And. Len(aTamSol) > 0
            aPalCad := StrTokArr(aLinha[3], " ")
            For nJ := 1 To Len(aTamSol)
                If AScan(aPalCad, aTamSol[nJ]) == 0 .And. ;
                   AScan(aLinha[5], aTamSol[nJ]) == 0
                    lOk := .F.
                    Exit
                EndIf
            Next nJ
        EndIf

        // (e) Voltagem: cada valor pedido (inclusive cada lado de 220/380)
        // precisa existir com a mesma unidade no cadastro.
        If lOk .And. Len(aVolSol) > 0
            nJ := 1
            Do While nJ <= Len(aVolSol) .And. lOk
                cNuc := FNucleoNumZ3(aVolSol[nJ])
                cUni := FUnidNumZ3(aVolSol[nJ])
                Do While !Empty(cNuc) .And. lOk
                    nP := At("/", cNuc)
                    If nP > 0
                        cParte := SubStr(cNuc, 1, nP - 1)
                        cNuc   := SubStr(cNuc, nP + 1)
                    Else
                        cParte := cNuc
                        cNuc   := ""
                    EndIf
                    lVolOk := .F.
                    For nK := 1 To Len(aLinha[6])
                        If FUnidNumZ3(aLinha[6][nK]) == cUni
                            cProd := FNucleoNumZ3(aLinha[6][nK])
                            Do While !Empty(cProd)
                                nP := At("/", cProd)
                                If nP > 0
                                    cCadP := SubStr(cProd, 1, nP - 1)
                                    cProd := SubStr(cProd, nP + 1)
                                Else
                                    cCadP := cProd
                                    cProd := ""
                                EndIf
                                If cCadP == cParte
                                    lVolOk := .T.
                                EndIf
                            EndDo
                        EndIf
                    Next nK
                    If !lVolOk
                        lOk := .F.
                    EndIf
                EndDo
                nJ += 1
            EndDo
        EndIf

        // (d) Nenhuma medida da solicitacao pode conflitar com o cadastro.
        If lOk
            If FConflitoMedZ3(cDescSol, aLinha[2])
                lOk := .F.
            EndIf
        EndIf

        // (f) Cobertura de palavras pelo peso: o cadastro pode ter palavras a
        // mais, nunca faltar o que a solicitacao exige. Sem numero nem codigo,
        // a exigencia sobe para 100% das palavras.
        If lOk .And. nTot > 0
            nCob := 0
            For nJ := 1 To Len(aPalSol)
                If AScan(aLinha[5], aPalSol[nJ]) > 0
                    nCob += aPeso[nJ]
                EndIf
            Next nJ
            If lSoPal
                If nCob < nTot
                    lOk := .F.
                EndIf
            ElseIf (nCob / nTot) < Z3_COBERT6
                lOk := .F.
            EndIf
            If lOk .And. lFaltaCod .And. nCob < nTot
                lOk := .F.
            EndIf
            If lOk
                nScr := nCob / nTot
            EndIf
        ElseIf lOk .And. lFaltaCod
            lOk := .F.
        EndIf

        // Nota do aprovado: cobertura ponderada mais o bonus do codigo de
        // fabricante alfanumerico achado inteiro no cadastro.
        If lOk
            For nJ := 1 To Len(aCodSol)
                If aCodSol[nJ][3] .And. At("|" + aCodSol[nJ][1] + "|", aLinha[8]) > 0
                    nScr += 0.15
                    Exit
                EndIf
            Next nJ
        EndIf

        // (g) Guarda todos os aprovados com a nota; a escolha do melhor e
        // feita depois da varredura.
        If lOk
            AAdd(aAchou, { aLinha[1], aLinha[2], "" })
            AAdd(aPts, nScr)
        EndIf
    Next nI

    // (g) Um aprovado: devolve como sempre. Mais de um: so escolhe o melhor
    // quando a nota e alta e ele esta bem a frente do segundo; empate, nota
    // baixa ou folga curta continuam ambiguos.
    If Len(aAchou) <= 1
        Return aAchou
    EndIf

    nMelhor := 1
    For nJ := 2 To Len(aPts)
        If aPts[nJ] > aPts[nMelhor]
            nMelhor := nJ
        EndIf
    Next nJ

    nSegundo := 0
    For nJ := 1 To Len(aPts)
        If nJ != nMelhor .And. aPts[nJ] > nSegundo
            nSegundo := aPts[nJ]
        EndIf
    Next nJ

    If aPts[nMelhor] >= 0.85 .And. (aPts[nMelhor] - nSegundo) >= Z3_FOLGA6
        Return { aAchou[nMelhor] }
    EndIf

Return {}


//-------------------------------------------------------------------
/*/{Protheus.doc} FIndiceSB1Z3
Monta o indice da SB1 ordenado pela chave de palavras. A varredura em
lote precisa de busca binaria: comparar a chave de cada solicitacao com
os 11 mil itens da SB1, um por um, nao termina em tempo util.
@return aIdx Vetor de {chave, codigo, descricao}.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FIndiceSB1Z3()

    Local aIdx := {}
    Local nI   := 1

    For nI := 1 To Len(aCacheSB1)
        AAdd(aIdx, { aCacheSB1[nI][4], aCacheSB1[nI][1], aCacheSB1[nI][2] })
    Next nI

    If Len(aIdx) > 1
        ASort(aIdx, 1, Len(aIdx), { |x, y| x[1] < y[1] })
    EndIf

Return aIdx


//-------------------------------------------------------------------
/*/{Protheus.doc} FBuscaChaveZ3
Devolve a posicao da primeira linha do indice com a chave informada.
@param aIdx   Indice ordenado por chave.
@param cChave Chave procurada.
@return nAch Posicao no indice, ou 0 quando a chave nao existe.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FBuscaChaveZ3(aIdx, cChave)

    Local nIni := 1
    Local nFim := Len(aIdx)
    Local nMed := 0
    Local nAch := 0

    Do While nIni <= nFim
        nMed := Int((nIni + nFim) / 2)
        If aIdx[nMed][1] < cChave
            nIni := nMed + 1
        ElseIf aIdx[nMed][1] > cChave
            nFim := nMed - 1
        Else
            nAch := nMed
            nFim := nMed - 1
        EndIf
    EndDo

Return nAch


//-------------------------------------------------------------------
/*/{Protheus.doc} FBlocoVerZ3
Devolve a linha do browse da varredura na ordem das colunas.
@param aLinhas Vetor de resultados de FVarreDupZ3().
@param nAt     Numero da linha atual do browse.
@return aLinha Linha na ordem solicitacao, descricao pedida, codigo, descricao, fornecedor.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FBlocoVerZ3(aLinhas, nAt)

    If nAt >= 1 .And. nAt <= Len(aLinhas)
        Return { aLinhas[nAt,1], aLinhas[nAt,2], aLinhas[nAt,3], aLinhas[nAt,4], aLinhas[nAt,5] }
    EndIf

Return { "", "", "", "", "" }
