#Include "Protheus.ch"
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} CADFORN
Solicitacao Cadastral de Fornecedores (ZZ4).
Tela FWMBrowse com sincronizacao automatica de status: ao mudar
de linha, verifica se o CNPJ ja foi cadastrado na SA2 e atualiza
a legenda (BR_BRANCO=Pendente / BR_VERMELHO=Cadastrado).

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   24/04/2026
/*/
//-------------------------------------------------------------------
User Function CADFORN()

    Local aArea    := GetArea()
    Local aAreaSX2 := GetArea()
    Local lZZ4OK   := .F.
    Private oBrw

    DbSelectArea("SX2")
    SX2->(DbSetOrder(1))
    lZZ4OK := SX2->(DbSeek("ZZ4"))
    RestArea(aAreaSX2)

    If !lZZ4OK
        MsgStop("Tabela ZZ4 nao encontrada no dicionario (SX2)." + Chr(13) + Chr(10) + ;
                "Execute U_DIAGZZ4 para diagnostico.", "CADFORN")
        RestArea(aArea)
        Return
    EndIf

    If Select("ZZ4") <= 0
        ChkFile("ZZ4")
    EndIf

    If Select("ZZ4") <= 0
        MsgStop("Nao foi possivel abrir a tabela ZZ4.", "CADFORN")
        RestArea(aArea)
        Return
    EndIf

    DbSelectArea("ZZ4")
    ZZ4->(DbSetOrder(1))
    ZZ4->(DbGoTop())

    // Sincroniza STATUS de TODOS os registros ZZ4 com a SA2
    // antes de abrir o browse, garantindo bolinha vermelha
    // para fornecedores ja cadastrados e filtro correto.
    FSyncZZ4Status()

    Private cCadastro    := "Solicitacao Cadastral de Fornecedores"
    Private lZZ4SyncBusy := .F.

    oBrw := FWMBrowse():New()
    oBrw:SetAlias("ZZ4")
    oBrw:SetDescription(cCadastro)
    oBrw:SetMenuDef("CADFORN")
    oBrw:DisableDetails()
    // 0=Pendente (branco) | 1=Cadastrado (vermelho)
    oBrw:AddLegend("ZZ4_STATUS == '0'", "BR_BRANCO"  , "Pendente"  )
    oBrw:AddLegend("ZZ4_STATUS == '1'", "BR_VERMELHO", "Cadastrado")
    // Sincroniza status automaticamente ao mudar de linha.
    // Flag lZZ4SyncBusy evita recursao infinita (Refresh dispara bChange).
    oBrw:bChange := {|| FZ4SyncBrw(oBrw) }
    // Exibe TODOS os registros: pendentes (BRANCO) e cadastrados (VERMELHO).
    // A cor e controlada pelo AddLegend acima.
    // Nao usar SetFilterDefault: removeria registros cadastrados do historico.
    oBrw:Activate()

    RestArea(aArea)

Return
//-------------------------------------------------------------------
/*/{Protheus.doc} FZ4SyncBrw
Callback do bChange: verifica APENAS o registro atual contra a SA2
e ajusta ZZ4_STATUS / ZZ4_DTREJ via Replace (sem mexer em outras linhas).
/*/
//-------------------------------------------------------------------
Static Function FZ4SyncBrw(oBrw)

    Local cAls       := ""
    Local cQuery     := ""
    Local cCnpjLimpo := ""
    Local lExisteSA2 := .F.
    Local lMudou     := .F.

    If lZZ4SyncBusy
        Return
    EndIf

    lZZ4SyncBusy := .T.

    DbSelectArea("ZZ4")

    If ZZ4->(Eof()) .Or. Empty(ZZ4->ZZ4_CNPJ)
        lZZ4SyncBusy := .F.
        Return
    EndIf

    cCnpjLimpo := StrTran(StrTran(StrTran(AllTrim(ZZ4->ZZ4_CNPJ),".",""),"/",""),"-","")

    // Verifica se o CNPJ atual existe na SA2 (1 SELECT pontual, leve).
    cAls   := GetNextAlias()
    cQuery := " SELECT 1 AS QTD FROM " + RetSqlName("SA2") + " "
    cQuery += " WHERE D_E_L_E_T_ = ' ' "
    cQuery += "   AND REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(A2_CGC)),'.',''),'/',''),'-','') = '" + cCnpjLimpo + "' "
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAls, .F., .T.)
    lExisteSA2 := !(cAls)->(Eof())
    (cAls)->(DbCloseArea())

    // Ajusta apenas o registro atual.
    If lExisteSA2 .And. AllTrim(ZZ4->ZZ4_STATUS) == '0'
        If Reclock("ZZ4", .F.)
            Replace ZZ4_STATUS With '1'
            Replace ZZ4_DTREJ  With dDataBase
            MsUnlock()
            lMudou := .T.
        EndIf
    ElseIf !lExisteSA2 .And. AllTrim(ZZ4->ZZ4_STATUS) == '1'
        If Reclock("ZZ4", .F.)
            Replace ZZ4_STATUS With '0'
            Replace ZZ4_DTREJ  With CtoD("  /  /  ")
            MsUnlock()
            lMudou := .T.
        EndIf
    EndIf

    If lMudou .And. ValType(oBrw) == "O"
        oBrw:Refresh()
    EndIf

    lZZ4SyncBusy := .F.

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Define o menu de acoes do FWMBrowse de CADFORN.
/*/
//-------------------------------------------------------------------
Static Function MenuDef()

    Local aRot := {}

    aAdd(aRot, {"Incluir"   , "U_CADINSZ4", 0, 3})
    aAdd(aRot, {"Alterar"   , "U_CFRNALT" , 0, 4})
    aAdd(aRot, {"Visualizar", "U_CFRNVIS" , 0, 2})
    aAdd(aRot, {"Pesquisar" , "AxPesqui"  , 0, 1})
    aAdd(aRot, {"Excluir"   , "U_CFRNDEL" , 0, 5})
    aAdd(aRot, {"Legenda"   , "U_CADLESZ4", 0, 6})

Return aRot


//-------------------------------------------------------------------
/*/{Protheus.doc} CADFRN_Alt
Formulario de alteracao de fornecedor. Bloqueia se nao for Pendente.
/*/
//-------------------------------------------------------------------
Static Function CADFRN_Alt()

    Local cSts := ""

    DbSelectArea("ZZ4")

    If ZZ4->(Eof()) .Or. ZZ4->(Bof())
        MsgStop("Nenhum registro selecionado.", "Alterar")
        Return
    EndIf

    cSts := AllTrim(ZZ4->ZZ4_STATUS)

    If cSts != '0'
        MsgStop("Somente solicitacoes PENDENTES podem ser alteradas." + Chr(13) + Chr(10) + ;
                "Status atual: " + IIF(cSts == '1', 'Aprovado', 'Rejeitado'), "Alteracao Bloqueada")
        Return
    EndIf

    FEditZZ4()

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FEditZZ4
Formulario de edicao de solicitacao de fornecedor (ZZ4).
/*/
//-------------------------------------------------------------------
Static Function FEditZZ4()

    Local oButton1, oButton2
    Local oGroup1, oGroup2, oGroup3, oGroup4, oGroup5, oGroup6, oGroup7, oGroup8
    Local oGet1, oGet2, oGet3, oGet3b, oGet4, oGet5, oGet6, oGet7, oCboSimp
    Local aSimple  := {"1=Sim", "2=Nao"}
    Local nRecNo   := ZZ4->(RecNo())
    Local cRazao   := Space(40)
    Local cCnpj    := Space(18)
    Local cFoneRaw := ""
    Local cDDD     := Space(2)
    Local cNumero  := Space(8)
    Local cEmail   := Space(60)
    Local cInsEst  := Space(18)
    Local cInsMun  := Space(18)
    Local cContat  := Space(40)
    Local cSimple  := "2=Nao"
    Local nIni     := 0
    Local nFim     := 0

    Private oDlg

    DbSelectArea("ZZ4")
    cRazao   := PadR(SubStr(AllTrim(ZZ4->ZZ4_RAZAO) , 1, 40), 40)
    cCnpj    := PadR(AllTrim(ZZ4->ZZ4_CNPJ)  , 18)
    cFoneRaw := AllTrim(ZZ4->ZZ4_NUMERO)
    // Extrai DDD e numero do formato gravado "(31) 3193-3015"
    nIni := At("(", cFoneRaw)
    nFim := At(")", cFoneRaw)
    If nIni > 0 .And. nFim > nIni
        cDDD    := PadR(AllTrim(SubStr(cFoneRaw, nIni+1, nFim-nIni-1)), 2)
        cNumero := PadR(AllTrim(SubStr(cFoneRaw, nFim+2)), 8)
    ElseIf Len(cFoneRaw) >= 2
        cDDD    := SubStr(cFoneRaw, 1, 2)
        cNumero := PadR(AllTrim(SubStr(cFoneRaw, 3)), 8)
    EndIf
    cEmail  := PadR(AllTrim(ZZ4->ZZ4_EMAIL)  , 60)
    cInsEst := PadR(SubStr(AllTrim(ZZ4->ZZ4_INSEST), 1, 18), 18)
    cInsMun := PadR(SubStr(AllTrim(ZZ4->ZZ4_INSMUN), 1, 18), 18)
    If ZZ4->(FieldPos("ZZ4_CONTAT")) > 0
        cContat := PadR(AllTrim(ZZ4->ZZ4_CONTAT), 40)
    EndIf
    If ZZ4->(FieldPos("ZZ4_SIMPLE")) > 0
        cSimple := IIF(AllTrim(ZZ4->ZZ4_SIMPLE) == "S", "1=Sim", "2=Nao")
    EndIf

    DEFINE MSDIALOG oDlg TITLE "Alterar Solicitacao de Fornecedor" ;
        FROM 000, 000 TO 800, 735 COLORS 0, 16777215 PIXEL

        @ 003, 005 GROUP oGroup1 TO 037, 355 PROMPT "RAZAO SOCIAL - Nome completo da empresa conforme contrato social." OF oDlg COLOR 0, 16777215 PIXEL
        @ 016, 016 MSGET oGet1 VAR cRazao SIZE 322, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 044, 005 GROUP oGroup2 TO 078, 355 PROMPT "CNPJ - Cadastro Nacional de Pessoas Juridicas." OF oDlg COLOR 0, 16777215 PIXEL
        @ 057, 016 MSGET oGet2 VAR cCnpj PICTURE "@R XX.XXX.XXX/XXXX-XX" VALID FVldCnpjExisteZZ4(cCnpj) SIZE 200, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 085, 005 GROUP oGroup3 TO 119, 355 PROMPT "TELEFONE - DDD (2 digitos) + Numero (8 digitos). Ex: DDD=31  Tel=3193-3015" OF oDlg COLOR 0, 16777215 PIXEL
        @ 098, 016 MSGET oGet3  VAR cDDD    PICTURE "99"              SIZE 020, 010 OF oDlg COLORS 0, 16777215 PIXEL
        @ 098, 040 MSGET oGet3b VAR cNumero PICTURE "@R 9999-9999"   SIZE 065, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 126, 005 GROUP oGroup4 TO 160, 355 PROMPT "E-MAIL - Endereco de e-mail para contato." OF oDlg COLOR 0, 16777215 PIXEL
        @ 139, 016 MSGET oGet4 VAR cEmail SIZE 322, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 167, 005 GROUP oGroup7 TO 201, 355 PROMPT "CONTATO - Nome do vendedor / representante comercial do fornecedor." OF oDlg COLOR 0, 16777215 PIXEL
        @ 180, 016 MSGET oGet7 VAR cContat SIZE 322, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 208, 005 GROUP oGroup5 TO 242, 355 PROMPT "INSCRICAO ESTADUAL - Obrigatoria. Caso nao possua, informe: ISENTO" OF oDlg COLOR 0, 16777215 PIXEL
        @ 221, 016 MSGET oGet5 VAR cInsEst SIZE 250, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 249, 005 GROUP oGroup6 TO 283, 355 PROMPT "INSCRICAO MUNICIPAL - Obrigatoria. Caso nao possua, informe: ISENTO" OF oDlg COLOR 0, 16777215 PIXEL
        @ 262, 016 MSGET oGet6 VAR cInsMun SIZE 250, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 290, 005 GROUP oGroup8 TO 324, 355 PROMPT "SIMPLES NACIONAL - O fornecedor e optante do regime Simples Nacional?" OF oDlg COLOR 0, 16777215 PIXEL
        @ 303, 016 MSCOMBOBOX oCboSimp VAR cSimple ITEMS aSimple SIZE 080, 012 OF oDlg PIXEL

        @ 334, 220 BUTTON oButton1 PROMPT "Confirmar" SIZE 050, 014 OF oDlg PIXEL ;
            ACTION FSaveZZ4(nRecNo, cRazao, cCnpj, cDDD, cNumero, cEmail, cInsEst, cInsMun, cContat, cSimple)
        @ 334, 285 BUTTON oButton2 PROMPT "Cancelar"  SIZE 050, 014 OF oDlg PIXEL ;
            ACTION oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FSaveZZ4
Grava alteracoes na solicitacao de fornecedor existente (ZZ4).
/*/
//-------------------------------------------------------------------
Static Function FSaveZZ4(nRecNo, cRazao, cCnpj, cDDD, cNumero, cEmail, cInsEst, cInsMun, cContat, cSimple)

    Local cCnpjLimpo := ""
    Local cSimpVal   := ""
    Local cFoneGrav  := ""
    Local lGravou    := .F.

    If Empty(AllTrim(cRazao))
        MsgStop("A Razao Social e obrigatoria!")
        Return
    EndIf

    If Empty(AllTrim(cCnpj))
        MsgStop("O CNPJ e obrigatorio!")
        Return
    EndIf

    cCnpjLimpo := StrTran(StrTran(StrTran(StrTran(AllTrim(cCnpj),".",""),"/",""),"-","")," ","")
    If Len(cCnpjLimpo) < 14 .Or. !FVldCNPJZZ4(cCnpjLimpo)
        MsgStop("CNPJ invalido! Verifique o numero informado.")
        Return
    EndIf

    If Empty(AllTrim(cEmail))
        MsgStop("O E-mail e obrigatorio!")
        Return
    EndIf

    If !("@" $ AllTrim(cEmail)) .Or. !("." $ SubStr(AllTrim(cEmail), At("@",AllTrim(cEmail))+1))
        MsgStop("E-mail invalido!")
        Return
    EndIf

    If Empty(AllTrim(cDDD)) .Or. Len(AllTrim(cDDD)) < 2
        MsgStop("Informe o DDD (2 digitos)!")
        Return
    EndIf

    If Empty(AllTrim(cNumero))
        MsgStop("O Telefone e obrigatorio!")
        Return
    EndIf

    If Empty(AllTrim(cContat))
        MsgStop("Informe o Nome do Vendedor!")
        Return
    EndIf

    If Empty(AllTrim(cInsEst))
        MsgStop("A Inscricao Estadual e obrigatoria!" + Chr(13) + Chr(10) + "Caso nao possua, informe: ISENTO")
        Return
    EndIf

    If Empty(AllTrim(cInsMun))
        MsgStop("A Inscricao Municipal e obrigatoria!" + Chr(13) + Chr(10) + "Caso nao possua, informe: ISENTO")
        Return
    EndIf

    cSimpVal  := IIF(SubStr(AllTrim(cSimple),1,1) == "1", "S", "N")
    cFoneGrav := "(" + AllTrim(cDDD) + ") " + AllTrim(StrTran(cNumero," ",""))

    DbSelectArea("ZZ4")
    DbSetOrder(01)
    DbGoTo(nRecNo)

    If Reclock("ZZ4", .F.)
        Replace ZZ4_RAZAO  With UPPER(AllTrim(cRazao))
        Replace ZZ4_CNPJ   With AllTrim(cCnpj)
        Replace ZZ4_NUMERO With cFoneGrav
        Replace ZZ4_EMAIL  With LOWER(AllTrim(cEmail))
        Replace ZZ4_INSEST With AllTrim(cInsEst)
        Replace ZZ4_INSMUN With AllTrim(cInsMun)
        If ZZ4->(FieldPos("ZZ4_CONTAT")) > 0
            Replace ZZ4_CONTAT With UPPER(AllTrim(cContat))
        EndIf
        If ZZ4->(FieldPos("ZZ4_SIMPLE")) > 0
            Replace ZZ4_SIMPLE With cSimpVal
        EndIf
        MsUnlock()
        ZZ4->(DbCommit())
        lGravou := .T.
    EndIf

    If !lGravou
        MsgStop("Nao foi possivel gravar a alteracao. Tente novamente ou verifique bloqueios na ZZ4.", "Alterar")
        Return
    EndIf

    oDlg:End()

    MsgInfo("Solicitacao atualizada com sucesso!", "Sucesso")

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} CADFRN_Vis
Visualizacao (somente leitura) do fornecedor selecionado.
/*/
//-------------------------------------------------------------------
Static Function CADFRN_Vis()

    Local nRec     := 0
    Local aARotina := {{"Visualizar", "AxVisual", 0, 3}}

    DbSelectArea("ZZ4")

    If ZZ4->(Eof()) .Or. ZZ4->(Bof())
        MsgStop("Nenhum registro selecionado.", "Visualizar")
        Return
    EndIf

    nRec := ZZ4->(RecNo())
    AxVisual("ZZ4", nRec, 3, aARotina)

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} CADFRN_Del
Exclui logicamente o fornecedor selecionado se for Pendente.
/*/
//-------------------------------------------------------------------
Static Function CADFRN_Del()

    Local cSts := ""

    DbSelectArea("ZZ4")

    If ZZ4->(Eof()) .Or. ZZ4->(Bof())
        MsgStop("Nenhum registro selecionado.", "Excluir")
        Return
    EndIf

    cSts := AllTrim(ZZ4->ZZ4_STATUS)

    If cSts != '0'
        MsgStop("Somente solicitacoes PENDENTES podem ser excluidas." + Chr(13) + Chr(10) + ;
                "Status atual: " + IIF(cSts == '1', 'Aprovado', 'Rejeitado'), "Exclusao Bloqueada")
        Return
    EndIf

    If !MsgYesNo("Confirma a exclusao desta solicitacao?", "Excluir")
        Return
    EndIf

    If Reclock("ZZ4", .F.)
        DbDelete()
        MsUnlock()
    EndIf

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} CADINSZ4
Tela de inclusao de solicitacao de cadastro de fornecedor.
/*/
//-------------------------------------------------------------------
User Function CADINSZ4()

    Local oButton1, oButton2
    Local oGroup1, oGroup2, oGroup3, oGroup4, oGroup5, oGroup6, oGroup7, oGroup8

    Local cRazao   := Space(40)
    Local cCnpj    := Space(18)
    Local cDDD     := Space(2)
    Local cNumero  := Space(8)
    Local cEmail   := Space(60)
    Local cInsEst  := Space(18)
    Local cInsMun  := Space(18)
    Local cContat  := Space(40)
    Local cSimple  := "2"

    Local oGet1, oGet2, oGet3, oGet3b, oGet4, oGet5, oGet6, oGet7, oCboSimp
    Local aSimple := {"1=Sim", "2=Nao"}

    Private oDlg

    DEFINE MSDIALOG oDlg TITLE "Solicitacao de Cadastro de Fornecedor" ;
        FROM 000, 000 TO 800, 735 COLORS 0, 16777215 PIXEL

        @ 003, 005 GROUP oGroup1 TO 037, 355 PROMPT "RAZAO SOCIAL - Nome completo da empresa conforme contrato social. - Exemplo: ACME INDUSTRIA E COMERCIO LTDA" OF oDlg COLOR 0, 16777215 PIXEL
        @ 016, 016 MSGET oGet1 VAR cRazao SIZE 322, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 044, 005 GROUP oGroup2 TO 078, 355 PROMPT "CNPJ - Cadastro Nacional de Pessoas Juridicas. - Exemplo: 12.345.678/0001-99" OF oDlg COLOR 0, 16777215 PIXEL
        @ 057, 016 MSGET oGet2 VAR cCnpj PICTURE "@R XX.XXX.XXX/XXXX-XX" VALID FVldCnpjExisteZZ4(cCnpj) SIZE 200, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 085, 005 GROUP oGroup3 TO 119, 355 PROMPT "TELEFONE - DDD (2 digitos) + Numero (8 digitos). Ex: DDD=31  Tel=3193-3015" OF oDlg COLOR 0, 16777215 PIXEL
        @ 098, 016 MSGET oGet3  VAR cDDD    PICTURE "99"             SIZE 020, 010 OF oDlg COLORS 0, 16777215 PIXEL
        @ 098, 040 MSGET oGet3b VAR cNumero PICTURE "@R 9999-9999"  SIZE 065, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 126, 005 GROUP oGroup4 TO 160, 355 PROMPT "E-MAIL - Endereco de e-mail para contato. - Exemplo: compras@fornecedor.com.br" OF oDlg COLOR 0, 16777215 PIXEL
        @ 139, 016 MSGET oGet4 VAR cEmail SIZE 322, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 167, 005 GROUP oGroup7 TO 201, 355 PROMPT "NOME DO VENDEDOR - Nome do vendedor / representante comercial do fornecedor." OF oDlg COLOR 0, 16777215 PIXEL
        @ 180, 016 MSGET oGet7 VAR cContat SIZE 322, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 208, 005 GROUP oGroup5 TO 242, 355 PROMPT "INSCRICAO ESTADUAL - Obrigatoria. Caso nao possua, informe: ISENTO" OF oDlg COLOR 0, 16777215 PIXEL
        @ 221, 016 MSGET oGet5 VAR cInsEst SIZE 250, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 249, 005 GROUP oGroup6 TO 283, 355 PROMPT "INSCRICAO MUNICIPAL - Obrigatoria. Caso nao possua, informe: ISENTO" OF oDlg COLOR 0, 16777215 PIXEL
        @ 262, 016 MSGET oGet6 VAR cInsMun SIZE 250, 010 OF oDlg COLORS 0, 16777215 PIXEL

        @ 290, 005 GROUP oGroup8 TO 324, 355 PROMPT "SIMPLES NACIONAL - O fornecedor e optante do regime Simples Nacional? Selecione Sim ou Nao." OF oDlg COLOR 0, 16777215 PIXEL
        @ 303, 016 MSCOMBOBOX oCboSimp VAR cSimple ITEMS aSimple SIZE 080, 012 OF oDlg PIXEL

        @ 334, 220 BUTTON oButton1 PROMPT "Confirmar" SIZE 050, 014 OF oDlg PIXEL ;
            ACTION FGravForn(cRazao, cCnpj, cDDD, cNumero, cEmail, cInsEst, cInsMun, cContat, cSimple)
        @ 334, 285 BUTTON oButton2 PROMPT "Cancelar"  SIZE 050, 014 OF oDlg PIXEL ;
            ACTION oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED

    If ValType(oBrw) == "O"
        oBrw:Refresh()
    EndIf

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FGravForn
Valida e grava a solicitacao de cadastro de fornecedor na ZZ4.
/*/
//-------------------------------------------------------------------
Static Function FGravForn(cRazao, cCnpj, cDDD, cNumero, cEmail, cInsEst, cInsMun, cContat, cSimple)

    Local cCnpjLimpo := ""
    Local cCodId     := Space(06)
    Local cSimpVal   := ""
    Local cFoneGrav  := ""
    Local lGravou    := .F.

    Default cContat := ""
    Default cSimple := "2"
    Default cDDD    := ""

    If Empty(AllTrim(cRazao))
        MsgStop("A Razao Social e obrigatoria!")
        Return
    EndIf

    If Empty(AllTrim(cCnpj))
        MsgStop("O CNPJ e obrigatorio!")
        Return
    EndIf

    cCnpjLimpo := StrTran(StrTran(StrTran(StrTran(AllTrim(cCnpj),".",""),"/",""),"-","")," ","")
    If Len(cCnpjLimpo) < 14 .Or. !FVldCNPJZZ4(cCnpjLimpo)
        MsgStop("CNPJ invalido! Verifique o numero informado.")
        Return
    EndIf

    If Empty(AllTrim(cEmail))
        MsgStop("O E-mail e obrigatorio!")
        Return
    EndIf

    If !("@" $ AllTrim(cEmail)) .Or. !("." $ SubStr(AllTrim(cEmail), At("@",AllTrim(cEmail))+1))
        MsgStop("E-mail invalido! Informe um endereco de e-mail valido.")
        Return
    EndIf

    If Empty(AllTrim(cDDD)) .Or. Len(AllTrim(cDDD)) < 2
        MsgStop("Informe o DDD (2 digitos)!")
        Return
    EndIf

    If Empty(AllTrim(cNumero))
        MsgStop("O Numero de contato (telefone) e obrigatorio!")
        Return
    EndIf

    If Empty(AllTrim(cContat))
        MsgStop("Informe o Nome do Vendedor do fornecedor!")
        Return
    EndIf

    If Empty(AllTrim(cInsEst))
        MsgStop("A Inscricao Estadual e obrigatoria!" + Chr(13) + Chr(10) + "Caso nao possua, informe: ISENTO")
        Return
    EndIf

    If Empty(AllTrim(cInsMun))
        MsgStop("A Inscricao Municipal e obrigatoria!" + Chr(13) + Chr(10) + "Caso nao possua, informe: ISENTO")
        Return
    EndIf

    cSimpVal  := IIF(SubStr(AllTrim(cSimple),1,1) == "1", "S", "N")
    cFoneGrav := "(" + AllTrim(cDDD) + ") " + AllTrim(StrTran(cNumero," ",""))

    cCodId := FSEQUZZ4()

    dbSelectArea("ZZ4")
    dbSetOrder(01)
    If Reclock("ZZ4",.T.)
        Replace ZZ4_FILIAL With xFilial("ZZ4")
        Replace ZZ4_ID     With cCodId
        Replace ZZ4_RAZAO  With UPPER(AllTrim(cRazao))
        Replace ZZ4_CNPJ   With AllTrim(cCnpj)
        Replace ZZ4_NUMERO With cFoneGrav
        Replace ZZ4_EMAIL  With LOWER(AllTrim(cEmail))
        Replace ZZ4_INSEST With AllTrim(cInsEst)
        Replace ZZ4_INSMUN With AllTrim(cInsMun)
        Replace ZZ4_STATUS With '0'
        Replace ZZ4_USR    With Substr(cUsuario,7,15)
        Replace ZZ4_ZDTSOL With dDataBase
        If ZZ4->(FieldPos("ZZ4_CONTAT")) > 0
            Replace ZZ4_CONTAT With UPPER(AllTrim(cContat))
        EndIf
        If ZZ4->(FieldPos("ZZ4_SIMPLE")) > 0
            Replace ZZ4_SIMPLE With cSimpVal
        EndIf
        MsUnlock()
        ZZ4->(DbCommit())
        lGravou := .T.
    EndIf

    If !lGravou
        MsgStop("Nao foi possivel gravar a solicitacao. Tente novamente ou verifique bloqueios na ZZ4.", "Inclusao")
        Return
    EndIf

    oDlg:End()

    MsgInfo("Fornecedor cadastrado com sucesso!", "Sucesso")

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FVldCNPJZZ4
Valida os digitos verificadores do CNPJ (algoritmo oficial).
/*/
//-------------------------------------------------------------------
Static Function FVldCNPJZZ4(cCnpj)

    Local nI       := 0
    Local nSoma    := 0
    Local nResto   := 0
    Local aPeso1   := {5,4,3,2,9,8,7,6,5,4,3,2}
    Local aPeso2   := {6,5,4,3,2,9,8,7,6,5,4,3,2}
    Local cBase    := SubStr(cCnpj, 1, 12)
    Local nDig1    := 0
    Local nDig2    := 0

    If Len(StrTran(cCnpj, SubStr(cCnpj,1,1), "")) == 0
        Return .F.
    EndIf

    nSoma := 0
    For nI := 1 To 12
        nSoma += Val(SubStr(cBase, nI, 1)) * aPeso1[nI]
    Next nI
    nResto := nSoma % 11
    nDig1  := IIF(nResto < 2, 0, 11 - nResto)

    If nDig1 != Val(SubStr(cCnpj, 13, 1))
        Return .F.
    EndIf

    nSoma := 0
    cBase := SubStr(cCnpj, 1, 13)
    For nI := 1 To 13
        nSoma += Val(SubStr(cBase, nI, 1)) * aPeso2[nI]
    Next nI
    nResto := nSoma % 11
    nDig2  := IIF(nResto < 2, 0, 11 - nResto)

    If nDig2 != Val(SubStr(cCnpj, 14, 1))
        Return .F.
    EndIf

Return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} FVldCnpjExisteZZ4
Verifica se o CNPJ ja existe na SA2 e/ou na ZZ4.
/*/
//-------------------------------------------------------------------
Static Function FVldCnpjExisteZZ4(cCnpj)

    Local cCnpjLimpo := ""
    Local cQuery     := ""
    Local cAls       := ""
    Local cMsg       := ""

    cCnpjLimpo := StrTran(StrTran(StrTran(StrTran(AllTrim(cCnpj),".",""),"/",""),"-","")," ","")

    If Len(cCnpjLimpo) < 14 .Or. !FVldCNPJZZ4(cCnpjLimpo)
        Return .T.
    EndIf

    cAls   := GetNextAlias()
    cQuery := " SELECT A2_COD, A2_LOJA, A2_NOME, A2_CGC "
    cQuery += " FROM " + RetSqlName("SA2") + " "
    cQuery += " WHERE D_E_L_E_T_ = ' ' "
    cQuery += "   AND A2_FILIAL = '" + xFilial("SA2") + "' "
    cQuery += "   AND REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(A2_CGC)),'.',''),'/',''),'-','') = '" + cCnpjLimpo + "' "
    cQuery := ChangeQuery(cQuery)

    If Select(cAls) > 0
        (cAls)->(DbCloseArea())
    EndIf
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAls, .F., .T.)

    // CNPJ ja esta em SA2: bloqueia a inclusao
    If !(cAls)->(Eof())
        cMsg := "CNPJ ja cadastrado em FORNECEDORES (SA2):" + Chr(13) + Chr(10) + ;
                "Codigo: " + AllTrim((cAls)->A2_COD) + " - " + AllTrim((cAls)->A2_NOME) + Chr(13) + Chr(10) + ;
                "CNPJ: " + AllTrim((cAls)->A2_CGC)
        (cAls)->(DbCloseArea())
        MsgStop(cMsg + Chr(13) + Chr(10) + Chr(13) + Chr(10) + ;
                "Nao e possivel solicitar cadastro de fornecedor ja existente.", ;
                "CNPJ ja cadastrado")
        Return .F.
    EndIf
    (cAls)->(DbCloseArea())

    cAls   := GetNextAlias()
    cQuery := " SELECT ZZ4_ID, ZZ4_RAZAO, ZZ4_STATUS "
    cQuery += " FROM " + RetSqlName("ZZ4") + " "
    cQuery += " WHERE D_E_L_E_T_ = ' ' "
    cQuery += "   AND ZZ4_FILIAL = '" + xFilial("ZZ4") + "' "
    cQuery += "   AND REPLACE(REPLACE(REPLACE(ZZ4_CNPJ,'.',''),'/',''),'-','') = '" + cCnpjLimpo + "' "
    cQuery := ChangeQuery(cQuery)

    If Select(cAls) > 0
        (cAls)->(DbCloseArea())
    EndIf
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAls, .F., .T.)

    If !(cAls)->(Eof())
        If AllTrim((cAls)->ZZ4_STATUS) == '0'
            cMsg := "Ja existe uma solicitacao PENDENTE para este CNPJ:" + Chr(13) + Chr(10) + ;
                    "ID: " + AllTrim((cAls)->ZZ4_ID) + " - " + AllTrim((cAls)->ZZ4_RAZAO) + Chr(13) + Chr(10) + ;
                    "Somente uma solicitacao pendente por CNPJ e permitida."
            (cAls)->(DbCloseArea())
            MsgStop(cMsg, "Solicitacao Duplicada")
            Return .F.
        EndIf
        (cAls)->(DbCloseArea())
        Return .T.
    EndIf
    (cAls)->(DbCloseArea())

Return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} FSEQUZZ4
Proximo sequencial disponivel para ZZ4 (MAX(ZZ4_ID)+1).
/*/
//-------------------------------------------------------------------
Static Function FSEQUZZ4()

    Local cAls   := GetNextAlias()
    Local cQuery := ""
    Local nMax   := 0
    Local cNext  := "000001"

    cQuery := "SELECT MAX(CASE WHEN ISNUMERIC(LTRIM(RTRIM(ZZ4_ID))) = 1 " + ;
              "THEN CAST(LTRIM(RTRIM(ZZ4_ID)) AS INT) ELSE 0 END) AS MAXID " + ;
              "FROM " + RetSQLName("ZZ4") + " "
    cQuery += "WHERE D_E_L_E_T_ = ' ' AND ZZ4_FILIAL = '" + xFilial("ZZ4") + "'"
    cQuery := ChangeQuery(cQuery)

    If Select(cAls) > 0
        (cAls)->(DbCloseArea())
    EndIf
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAls, .F., .T.)
    If !Empty((cAls)->MAXID)
        nMax := (cAls)->MAXID
    EndIf
    (cAls)->(DbCloseArea())

    cNext := StrZero(nMax + 1, 6)

Return(cNext)


//-------------------------------------------------------------------
/*/{Protheus.doc} VALZ4STS
Valida o campo ZZ4_STATUS. Preenche ZZ4_DTREJ quando rejeitado.
/*/
//-------------------------------------------------------------------
User Function VALZ4STS()

    If M->ZZ4_STATUS == '2'
        If Empty(M->ZZ4_DTREJ)
            M->ZZ4_DTREJ := dDataBase
        EndIf
        M->ZZ4_ZDTSOL := M->ZZ4_DTREJ
    EndIf

Return(.T.)


//-------------------------------------------------------------------
/*/{Protheus.doc} CADLESZ4
Exibe a legenda do browse de solicitacao de cadastro de fornecedor.
/*/
//-------------------------------------------------------------------
User Function CADLESZ4()

    BRWLEGENDA("Solicitacao Cadastral de Fornecedor","Legenda",;
        {{"BR_BRANCO",  "Solicitacao aguardando cadastro de fornecedor."},;
         {"BR_VERMELHO","Fornecedor cadastrado com sucesso."             }})

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} RENUMZZ4
Renumera os registros ZZ4 em ordem crescente de data.
/*/
//-------------------------------------------------------------------
User Function RENUMZZ4()

    Local aArea  := GetArea()
    Local nSeq   := 0
    Local nTotal := 0
    Local cNovoID:= ""

    If !MsgYesNo("Esta funcao vai renumerar TODOS os registros da ZZ4" + Chr(13) + Chr(10) + ;
                 "a partir de 000001 em ordem de data." + Chr(13) + Chr(10) + Chr(13) + Chr(10) + ;
                 "Confirma?", "Renumerar ZZ4")
        RestArea(aArea)
        Return
    EndIf

    DbSelectArea("ZZ4")
    DbSetOrder(1)
    ZZ4->(DbGoTop())

    While !ZZ4->(Eof())
        If ZZ4->(D_E_L_E_T_) == " "
            nSeq    := nSeq + 1
            cNovoID := StrZero(nSeq, 6)
            If Reclock("ZZ4", .F.)
                Replace ZZ4_ID With cNovoID
                MsUnlock()
                nTotal := nTotal + 1
            EndIf
        EndIf
        ZZ4->(DbSkip())
    EndDo

    RestArea(aArea)

    MsgInfo("Renumeracao concluida!" + Chr(13) + Chr(10) + ;
            "Registros atualizados: " + CValToChar(nTotal) + Chr(13) + Chr(10) + ;
            "Proximo ID sera: " + StrZero(nSeq + 1, 6), "RENUMZZ4")

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FSyncZZ4Status
Sincroniza ZZ4_STATUS: marca '1' (Cadastrado) para registros ZZ4
cujo CNPJ ja existe na SA2 como fornecedor ativo.
Executado sempre que CADFORN e aberto.
/*/
//-------------------------------------------------------------------
Static Function FSyncZZ4Status()

    Local aArea  := GetArea()
    Local cAlias := ""
    Local cQuery := ""

    // Garante que as tabelas estao abertas
    If Select("ZZ4") <= 0
        ChkFile("ZZ4")
    EndIf
    If Select("SA2") <= 0
        ChkFile("SA2")
    EndIf
    If Select("ZZ4") <= 0 .Or. Select("SA2") <= 0
        RestArea(aArea)
        Return
    EndIf

    // --- Passo 1: Marca STATUS='1' para ZZ4 cujo CNPJ existe na SA2 ---
    // Usa SELECT + RecLock (AdvPL) em vez de UPDATE direto via SQL,
    // garantindo que a serializacao de data e status funcione corretamente.
    cAlias := GetNextAlias()
    cQuery := "SELECT Z.ZZ4_ID FROM " + RetSqlName("ZZ4") + " Z "
    cQuery += " WHERE Z.D_E_L_E_T_ = ' ' "
    cQuery += "   AND Z.ZZ4_STATUS = '0' "
    cQuery += "   AND EXISTS (SELECT 1 FROM " + RetSqlName("SA2") + " S "
    cQuery += "               WHERE S.D_E_L_E_T_ = ' ' "
    cQuery += "               AND REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(S.A2_CGC)),'.',''),'/',''),'-','') = "
    cQuery += "                   REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(Z.ZZ4_CNPJ)),'.',''),'/',''),'-','')) "
    cQuery := ChangeQuery(cQuery)

    If Select(cAlias) > 0
        (cAlias)->(DbCloseArea())
    EndIf
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        DbSelectArea("ZZ4")
        ZZ4->(DbSetOrder(1))
        If ZZ4->(DbSeek(xFilial("ZZ4") + PadR(AllTrim((cAlias)->ZZ4_ID), TamSX3("ZZ4_ID")[1])))
            If Reclock("ZZ4", .F.)
                Replace ZZ4_STATUS With '1'
                If Empty(ZZ4->ZZ4_DTREJ)
                    Replace ZZ4_DTREJ With dDataBase
                EndIf
                MsUnlock()
            EndIf
        EndIf
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    // --- Passo 2: Reverte para Pendente ('0') quem foi excluido da SA2 ---
    cAlias := GetNextAlias()
    cQuery := "SELECT Z.ZZ4_ID FROM " + RetSqlName("ZZ4") + " Z "
    cQuery += " WHERE Z.D_E_L_E_T_ = ' ' "
    cQuery += "   AND Z.ZZ4_STATUS = '1' "
    cQuery += "   AND NOT EXISTS (SELECT 1 FROM " + RetSqlName("SA2") + " S "
    cQuery += "                   WHERE S.D_E_L_E_T_ = ' ' "
    cQuery += "                   AND REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(S.A2_CGC)),'.',''),'/',''),'-','') = "
    cQuery += "                       REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(Z.ZZ4_CNPJ)),'.',''),'/',''),'-','')) "
    cQuery := ChangeQuery(cQuery)

    If Select(cAlias) > 0
        (cAlias)->(DbCloseArea())
    EndIf
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        DbSelectArea("ZZ4")
        ZZ4->(DbSetOrder(1))
        If ZZ4->(DbSeek(xFilial("ZZ4") + PadR(AllTrim((cAlias)->ZZ4_ID), TamSX3("ZZ4_ID")[1])))
            If Reclock("ZZ4", .F.)
                Replace ZZ4_STATUS With '0'
                Replace ZZ4_DTREJ  With CtoD("  /  /  ")
                MsUnlock()
            EndIf
        EndIf
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    RestArea(aArea)

Return


//-------------------------------------------------------------------
// Wrappers User Function chamados pelo MenuDef do FWMBrowse.
//-------------------------------------------------------------------

User Function CFRNALT()
    DbSelectArea("ZZ4")
    CADFRN_Alt()
Return

User Function CFRNVIS()
    DbSelectArea("ZZ4")
    CADFRN_Vis()
Return

User Function CFRNDEL()
    DbSelectArea("ZZ4")
    CADFRN_Del()
Return


//-------------------------------------------------------------------
/*/{Protheus.doc} DIAGZ4SA2
Diagnostico: mostra o estado real de ZZ4 vs SA2 para descobrir
por que um registro nao esta ficando vermelho.
/*/
//-------------------------------------------------------------------
User Function DIAGZ4SA2()

    Local aArea  := GetArea()
    Local cAls   := GetNextAlias()
    Local cQuery := ""
    Local cMsg   := ""
    Local nLin   := 0

    cQuery := " SELECT Z.ZZ4_ID, Z.ZZ4_FILIAL AS ZFIL, Z.ZZ4_RAZAO, Z.ZZ4_CNPJ, "
    cQuery += "        Z.ZZ4_STATUS, Z.ZZ4_DTREJ, "
    cQuery += "        REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(Z.ZZ4_CNPJ)),'.',''),'/',''),'-','') AS CNPJ_LIMPO, "
    cQuery += "        ( SELECT TOP 1 A2_COD + '/' + A2_LOJA + ' ' + A2_NOME "
    cQuery += "          FROM " + RetSqlName("SA2") + " "
    cQuery += "          WHERE D_E_L_E_T_ = ' ' "
    cQuery += "          AND REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(A2_CGC)),'.',''),'/',''),'-','') = "
    cQuery += "              REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(Z.ZZ4_CNPJ)),'.',''),'/',''),'-','') "
    cQuery += "        ) AS SA2_FORN "
    cQuery += " FROM " + RetSqlName("ZZ4") + " Z "
    cQuery += " WHERE Z.D_E_L_E_T_ = ' ' "
    cQuery += " ORDER BY Z.ZZ4_ID "
    cQuery := ChangeQuery(cQuery)

    If Select(cAls) > 0
        (cAls)->(DbCloseArea())
    EndIf
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAls, .F., .T.)

    cMsg := "=== DIAGNOSTICO ZZ4 vs SA2 ===" + Chr(13) + Chr(10) + Chr(13) + Chr(10)

    While !(cAls)->(Eof())
        nLin++
        cMsg += "ID:[" + AllTrim((cAls)->ZZ4_ID) + "] FIL:[" + AllTrim((cAls)->ZFIL) + "]" + Chr(13) + Chr(10)
        cMsg += "  Razao..: " + AllTrim((cAls)->ZZ4_RAZAO) + Chr(13) + Chr(10)
        cMsg += "  CNPJ ZZ4: [" + AllTrim((cAls)->ZZ4_CNPJ) + "]" + Chr(13) + Chr(10)
        cMsg += "  Limpo..: [" + AllTrim((cAls)->CNPJ_LIMPO) + "]" + Chr(13) + Chr(10)
        cMsg += "  Status.: " + AllTrim((cAls)->ZZ4_STATUS) + ;
                "  Dt.: " + DtoC(StoD(SubStr(AllTrim((cAls)->ZZ4_DTREJ),1,8))) + Chr(13) + Chr(10)
        If Empty((cAls)->SA2_FORN)
            cMsg += "  SA2....: (NAO EXISTE NA SA2)" + Chr(13) + Chr(10)
        Else
            cMsg += "  SA2....: " + AllTrim((cAls)->SA2_FORN) + Chr(13) + Chr(10)
        EndIf
        cMsg += "---" + Chr(13) + Chr(10)
        (cAls)->(DbSkip())
    EndDo

    (cAls)->(DbCloseArea())

    If nLin == 0
        cMsg += "Nenhum registro em ZZ4."
    EndIf

    MsgInfo(cMsg, "Diagnostico ZZ4 x SA2")

    RestArea(aArea)

Return
