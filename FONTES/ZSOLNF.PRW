#Include "PROTHEUS.CH"
#Include "TOTVS.CH"
#Include "RPTDEF.CH"
#Include "FWMBROWSE.CH"
#Include "TOPCONN.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} ZSOLNF
Solicitação interna de emissão de Nota Fiscal de devolução ao fornecedor.

A rotina substitui a planilha "Solicitação de Nota Fiscal Devolução -
Estação Solda". Guarda o cabeçalho da solicitação na tabela ZSN e os
produtos na tabela ZSI. As duas tabelas são criadas na primeira
execução, sem depender de dicionário (SX2/SX3).

@type    User Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
User Function ZSOLNF()
    GaranteTabelas()
    MostraBrowse()
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} NomeTabCab
Nome físico da tabela de cabeçalho da solicitação (empresa + filial).

@type    Static Function
@author  Vortice
@since   10/11/2026
@return  cTabela Nome da tabela, exemplo ZSN0101
/*/
//-------------------------------------------------------------------
Static Function NomeTabCab()
Return "ZSN" + cEmpAnt + cFilAnt

//-------------------------------------------------------------------
/*/{Protheus.doc} NomeTabItm
Nome físico da tabela de produtos da solicitação (empresa + filial).

@type    Static Function
@author  Vortice
@since   10/11/2026
@return  cTabela Nome da tabela, exemplo ZSI0101
/*/
//-------------------------------------------------------------------
Static Function NomeTabItm()
Return "ZSI" + cEmpAnt + cFilAnt

//-------------------------------------------------------------------
/*/{Protheus.doc} GaranteTabelas
Cria as tabelas ZSN e ZSI quando ainda não existem.

@type    Static Function
@author  Vortice
@since   10/11/2026
@return  lOk .T. quando as duas tabelas estão disponíveis
/*/
//-------------------------------------------------------------------
Static Function GaranteTabelas()
    Local lOk := .T.

    If !TabelaExiste(NomeTabCab())
        lOk := CriaTabCab()
    EndIf

    If lOk .And. !TabelaExiste(NomeTabItm())
        lOk := CriaTabItm()
    EndIf

Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} TabelaExiste
Verifica no SQL Server se a tabela informada já existe.

@param   cTabela Nome físico da tabela
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  lExiste .T. quando a tabela existe
/*/
//-------------------------------------------------------------------
Static Function TabelaExiste(cTabela)
    Local lExiste := .F.
    Local aArea   := GetArea()
    Local cAlias  := GetNextAlias()
    Local cQuery  := ""

    cQuery := "SELECT COUNT(*) AS QTD FROM INFORMATION_SCHEMA.TABLES "
    cQuery += "WHERE TABLE_NAME = '" + cTabela + "'"

    TcQuery cQuery New Alias (cAlias)

    If (cAlias)->QTD > 0
        lExiste := .T.
    EndIf

    (cAlias)->(DbCloseArea())
    RestArea(aArea)
Return lExiste

//-------------------------------------------------------------------
/*/{Protheus.doc} CriaTabCab
Cria a tabela de cabeçalho da solicitação de devolução.

@type    Static Function
@author  Vortice
@since   10/11/2026
@return  lOk .T. quando a tabela foi criada
/*/
//-------------------------------------------------------------------
Static Function CriaTabCab()
    Local lOk      := .T.
    Local cTabela  := NomeTabCab()
    Local cQuery   := ""

    cQuery := "CREATE TABLE " + cTabela + " ("
    cQuery += "ZSN_FILIAL VARCHAR(4) NOT NULL DEFAULT '    ', "
    cQuery += "ZSN_NUM VARCHAR(6) NOT NULL DEFAULT '      ', "
    cQuery += "ZSN_DTSOL VARCHAR(8) NOT NULL DEFAULT '        ', "
    cQuery += "ZSN_FORNEC VARCHAR(6) NOT NULL DEFAULT '      ', "
    cQuery += "ZSN_LOJA VARCHAR(2) NOT NULL DEFAULT '  ', "
    cQuery += "ZSN_NOMFOR VARCHAR(100) NOT NULL DEFAULT '', "
    cQuery += "ZSN_CGC VARCHAR(18) NOT NULL DEFAULT '', "
    cQuery += "ZSN_ARMAZ VARCHAR(30) NOT NULL DEFAULT '', "
    cQuery += "ZSN_VOLUME FLOAT NOT NULL DEFAULT 0, "
    cQuery += "ZSN_TPFRETE VARCHAR(40) NOT NULL DEFAULT '', "
    cQuery += "ZSN_TPOPER VARCHAR(60) NOT NULL DEFAULT '', "
    cQuery += "ZSN_DESCOP VARCHAR(200) NOT NULL DEFAULT '', "
    cQuery += "ZSN_DTEMIS VARCHAR(8) NOT NULL DEFAULT '        ', "
    cQuery += "ZSN_HREMIS VARCHAR(5) NOT NULL DEFAULT '', "
    cQuery += "ZSN_MOTOR VARCHAR(80) NOT NULL DEFAULT '', "
    cQuery += "ZSN_CPF VARCHAR(14) NOT NULL DEFAULT '', "
    cQuery += "ZSN_PLACA VARCHAR(8) NOT NULL DEFAULT '', "
    cQuery += "ZSN_MODELO VARCHAR(30) NOT NULL DEFAULT '', "
    cQuery += "ZSN_OBS VARCHAR(MAX) NULL, "
    cQuery += "ZSN_TOTAL FLOAT NOT NULL DEFAULT 0, "
    cQuery += "ZSN_STATUS VARCHAR(1) NOT NULL DEFAULT '1', "
    cQuery += "ZSN_USER VARCHAR(25) NOT NULL DEFAULT '', "
    cQuery += "ZSN_HORA VARCHAR(8) NOT NULL DEFAULT '        ', "
    cQuery += "D_E_L_E_T_ VARCHAR(1) NOT NULL DEFAULT ' ', "
    cQuery += "R_E_C_N_O_ INT IDENTITY(1,1) NOT NULL, "
    cQuery += "CONSTRAINT PK_" + cTabela + " PRIMARY KEY (R_E_C_N_O_)"
    cQuery += ")"

    If TcSqlExec(cQuery) < 0
        MsgAlert("Erro ao criar a tabela " + cTabela + ":" + CRLF + TcSqlError(), "Erro")
        lOk := .F.
    Else
        cQuery := "CREATE INDEX IDX_" + cTabela + "_01 ON " + cTabela
        cQuery += " (ZSN_FILIAL, ZSN_NUM)"
        TcSqlExec(cQuery)

        cQuery := "CREATE INDEX IDX_" + cTabela + "_02 ON " + cTabela
        cQuery += " (ZSN_FILIAL, ZSN_DTSOL)"
        TcSqlExec(cQuery)
    EndIf

Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} CriaTabItm
Cria a tabela de produtos da solicitação de devolução.

@type    Static Function
@author  Vortice
@since   10/11/2026
@return  lOk .T. quando a tabela foi criada
/*/
//-------------------------------------------------------------------
Static Function CriaTabItm()
    Local lOk      := .T.
    Local cTabela  := NomeTabItm()
    Local cQuery   := ""

    cQuery := "CREATE TABLE " + cTabela + " ("
    cQuery += "ZSI_FILIAL VARCHAR(4) NOT NULL DEFAULT '    ', "
    cQuery += "ZSI_NUM VARCHAR(6) NOT NULL DEFAULT '      ', "
    cQuery += "ZSI_ITEM VARCHAR(3) NOT NULL DEFAULT '   ', "
    cQuery += "ZSI_PROD VARCHAR(15) NOT NULL DEFAULT '               ', "
    cQuery += "ZSI_DESC VARCHAR(200) NOT NULL DEFAULT '', "
    cQuery += "ZSI_QTDE FLOAT NOT NULL DEFAULT 0, "
    cQuery += "ZSI_VLRUNI FLOAT NOT NULL DEFAULT 0, "
    cQuery += "ZSI_VLRTOT FLOAT NOT NULL DEFAULT 0, "
    cQuery += "D_E_L_E_T_ VARCHAR(1) NOT NULL DEFAULT ' ', "
    cQuery += "R_E_C_N_O_ INT IDENTITY(1,1) NOT NULL, "
    cQuery += "CONSTRAINT PK_" + cTabela + " PRIMARY KEY (R_E_C_N_O_)"
    cQuery += ")"

    If TcSqlExec(cQuery) < 0
        MsgAlert("Erro ao criar a tabela " + cTabela + ":" + CRLF + TcSqlError(), "Erro")
        lOk := .F.
    Else
        cQuery := "CREATE INDEX IDX_" + cTabela + "_01 ON " + cTabela
        cQuery += " (ZSI_FILIAL, ZSI_NUM, ZSI_ITEM)"
        TcSqlExec(cQuery)
    EndIf

Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} MostraBrowse
Monta e exibe a lista de solicitações de devolução.

@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function MostraBrowse()
    Local oBrowse

    Private cAliasQry := GetNextAlias()
    Private cFiltUsu  := ""  // usuario escolhido na pesquisa (vazio = todos)

    oBrowse := FWMBrowse():New()
    oBrowse:SetDescription("Solicitação de Nota Fiscal")
    oBrowse:SetFontBrowse(TFont():New("Arial",,-12,.F.))

    oBrowse:SetDataQuery(.T.)
    oBrowse:SetQuery(MontaQuery())
    oBrowse:SetAlias(cAliasQry)
    oBrowse:SetProfileID("ZSNF")

    // O filtro nativo é desligado porque a consulta é montada por SQL livre:
    // o botão "Filtrar" não encontra os campos no dicionário e derruba a thread.
    oBrowse:SetUseFilter(.F.)

    oBrowse:AddLegend("ZSN_STATUS == '1'", "YELLOW", "Pendente")
    oBrowse:AddLegend("ZSN_STATUS == '2'", "GREEN",  "Emitida")
    oBrowse:AddLegend("ZSN_STATUS == '3'", "RED",    "Cancelada")

    oBrowse:AddButton("Incluir",     {|| U_ZSOLNFINC(), AtualizaBrowse(oBrowse) }, , 2)
    oBrowse:AddButton("Alterar",     {|| U_ZSOLNFALT(), AtualizaBrowse(oBrowse) }, , 2)
    oBrowse:AddButton("Visualizar",  {|| U_ZSOLNFVIS(), AtualizaBrowse(oBrowse) }, , 2)
    oBrowse:AddButton("Excluir",     {|| U_ZSOLNFEXC(), AtualizaBrowse(oBrowse) }, , 2)
    oBrowse:AddButton("Situação",    {|| U_ZSOLNFSTS(), AtualizaBrowse(oBrowse) }, , 2)
    oBrowse:AddButton("Imprimir PDF", {|| U_ZSOLNFPDF() }, , 2)
    oBrowse:AddButton("Pesquisar por Usuário", {|| PesquisaUsuario(oBrowse) }, , 2)

    oBrowse:SetColumns(MontaColunas())
    oBrowse:Activate()

    If Select(cAliasQry) > 0
        (cAliasQry)->(DbCloseArea())
    EndIf
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} MontaQuery
Consulta que alimenta a lista de solicitações.

@type    Static Function
@author  Vortice
@since   10/11/2026
@return  cQuery Comando SQL de leitura
/*/
//-------------------------------------------------------------------
Static Function MontaQuery()
    Local cQuery := ""

    cQuery := "SELECT "
    cQuery += "R_E_C_N_O_ AS NRECZSN, "
    cQuery += "ZSN_FILIAL, "
    cQuery += "ZSN_NUM, "
    cQuery += "ZSN_DTSOL, "
    cQuery += "ZSN_FORNEC, "
    cQuery += "ZSN_LOJA, "
    cQuery += "ZSN_NOMFOR, "
    cQuery += "ZSN_TOTAL, "
    cQuery += "ZSN_STATUS, "
    cQuery += "ZSN_USER, "
    cQuery += "ZSN_HORA, "
    // Coluna auxiliar so para ordenar: o numero e gravado sem zeros a
    // esquerda (1, 2, 3...), entao a ordem tem de ser pelo valor.
    cQuery += "CASE WHEN ISNUMERIC(ZSN_NUM) = 1 THEN CAST(ZSN_NUM AS INT) ELSE 0 END AS ZSN_ORDEM "
    cQuery += "FROM " + NomeTabCab() + " "
    cQuery += "WHERE D_E_L_E_T_ = ' ' "
    cQuery += "AND ZSN_FILIAL = '" + xFilial("SA2") + "' "

    If !Empty(cFiltUsu)
        cQuery += "AND ZSN_USER = '" + EscapaSql(cFiltUsu) + "' "
    EndIf

    cQuery += "ORDER BY ZSN_ORDEM DESC"

Return cQuery

//-------------------------------------------------------------------
/*/{Protheus.doc} MontaColunas
Colunas exibidas na lista de solicitações.

@type    Static Function
@author  Vortice
@since   10/11/2026
@return  aColunas Vetor de objetos FWBrwColumn
/*/
//-------------------------------------------------------------------
Static Function MontaColunas()
    Local aColunas := {}
    Local oColuna

    oColuna := FWBrwColumn():New()
    oColuna:SetData({|| NumeroVisivel((cAliasQry)->ZSN_NUM) })
    oColuna:SetTitle("Número")
    oColuna:SetSize(8)
    oColuna:SetDecimal(0)
    aAdd(aColunas, oColuna)

    oColuna := FWBrwColumn():New()
    oColuna:SetData({|| DtoC(STOD((cAliasQry)->ZSN_DTSOL)) })
    oColuna:SetTitle("Data Solicitação")
    oColuna:SetSize(12)
    oColuna:SetDecimal(0)
    aAdd(aColunas, oColuna)

    oColuna := FWBrwColumn():New()
    oColuna:SetData({|| AllTrim((cAliasQry)->ZSN_FORNEC) + "/" + AllTrim((cAliasQry)->ZSN_LOJA) })
    oColuna:SetTitle("Fornecedor")
    oColuna:SetSize(12)
    oColuna:SetDecimal(0)
    aAdd(aColunas, oColuna)

    oColuna := FWBrwColumn():New()
    oColuna:SetData({|| AllTrim((cAliasQry)->ZSN_NOMFOR) })
    oColuna:SetTitle("Razão Social")
    oColuna:SetSize(45)
    oColuna:SetDecimal(0)
    aAdd(aColunas, oColuna)

    oColuna := FWBrwColumn():New()
    oColuna:SetData({|| (cAliasQry)->ZSN_TOTAL })
    oColuna:SetTitle("Total")
    oColuna:SetSize(14)
    oColuna:SetDecimal(2)
    oColuna:SetPicture("@E 999,999,999.99")
    aAdd(aColunas, oColuna)

    oColuna := FWBrwColumn():New()
    oColuna:SetData({|| DescStatus((cAliasQry)->ZSN_STATUS) })
    oColuna:SetTitle("Situação")
    oColuna:SetSize(12)
    oColuna:SetDecimal(0)
    aAdd(aColunas, oColuna)

    oColuna := FWBrwColumn():New()
    oColuna:SetData({|| AllTrim((cAliasQry)->ZSN_USER) })
    oColuna:SetTitle("Usuário")
    oColuna:SetSize(15)
    oColuna:SetDecimal(0)
    aAdd(aColunas, oColuna)

    oColuna := FWBrwColumn():New()
    oColuna:SetData({|| AllTrim((cAliasQry)->ZSN_HORA) })
    oColuna:SetTitle("Hora")
    oColuna:SetSize(8)
    oColuna:SetDecimal(0)
    aAdd(aColunas, oColuna)

Return aColunas

//-------------------------------------------------------------------
/*/{Protheus.doc} DescStatus
Descrição da situação a partir do código gravado na tabela.

@param   cStatus Código da situação (1, 2 ou 3)
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  cDescricao Texto da situação
/*/
//-------------------------------------------------------------------
Static Function DescStatus(cStatus)
    Local cDescricao := "Pendente"

    Do Case
    Case AllTrim(cStatus) == "2"
        cDescricao := "Emitida"
    Case AllTrim(cStatus) == "3"
        cDescricao := "Cancelada"
    EndCase

Return cDescricao

//-------------------------------------------------------------------
/*/{Protheus.doc} StatusCodigo
Código da situação a partir da descrição.

@param   cDescricao Texto da situação
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  cCodigo Código da situação (1, 2 ou 3)
/*/
//-------------------------------------------------------------------
Static Function StatusCodigo(cDescricao)
    Local cCodigo := "1"

    Do Case
    Case AllTrim(cDescricao) == "Emitida"
        cCodigo := "2"
    Case AllTrim(cDescricao) == "Cancelada"
        cCodigo := "3"
    EndCase

Return cCodigo

//-------------------------------------------------------------------
/*/{Protheus.doc} AtualizaBrowse
Recarrega a lista de solicitações mantendo o cursor no início.

@param   oBrowse Objeto da lista
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function AtualizaBrowse(oBrowse)
    oBrowse:Refresh(.T.)
    oBrowse:GoTop()
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} PesquisaUsuario
Mostra na lista somente as solicitações feitas por um usuário. A primeira
opção da lista (Todos os usuários) remove o filtro e volta a mostrar tudo.

@param   oBrowse Objeto da lista de solicitações
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function PesquisaUsuario(oBrowse)
    Local aArea  := GetArea()
    Local aUsu   := {}
    Local cTodos := "(Todos os usuários)"
    Local cAlias := GetNextAlias()
    Local cQuery := ""
    Local nSel   := 1
    Local lOk    := .F.
    Local oDlg
    Local oLbx
    Local oBtnOk
    Local oBtnCanc

    // Usuarios que ja fizeram solicitacoes nesta filial
    cQuery := "SELECT DISTINCT ZSN_USER "
    cQuery += "FROM " + NomeTabCab() + " "
    cQuery += "WHERE ZSN_FILIAL = '" + xFilial("SA2") + "' "
    cQuery += "AND D_E_L_E_T_ = ' ' "
    cQuery += "AND ZSN_USER <> '' "
    cQuery += "ORDER BY ZSN_USER"

    TcQuery cQuery New Alias (cAlias)

    aAdd(aUsu, { cTodos })

    (cAlias)->(DbGoTop())
    While !(cAlias)->(Eof())
        aAdd(aUsu, { AllTrim((cAlias)->ZSN_USER) })
        (cAlias)->(DbSkip())
    EndDo

    (cAlias)->(DbCloseArea())

    DEFINE MSDIALOG oDlg TITLE "Pesquisar por Usuário" FROM 000,000 TO 600,450 PIXEL

    @ 010,010 SAY "Usuário que fez a solicitação:" SIZE 200,007 OF oDlg PIXEL

    // Botoes acima da lista: a lista ocupa toda a area restante da janela.
    // nSel e lido aqui dentro: depois do End() a lista nao existe mais.
    @ 026,010 BUTTON oBtnOk PROMPT "Pesquisar" SIZE 70,016 OF oDlg PIXEL ;
        ACTION ( nSel := oLbx:nAt, lOk := .T., oDlg:End() )
    @ 026,100 BUTTON oBtnCanc PROMPT "Cancelar" SIZE 70,016 OF oDlg PIXEL ;
        ACTION oDlg:End()

    @ 050,010 LISTBOX oLbx FIELDS HEADER "Usuário" SIZE 200,240 OF oDlg PIXEL
    oLbx:SetArray(aUsu)
    oLbx:bLine := {|| { aUsu[oLbx:nAt][1] } }
    oLbx:nAt   := 1

    ACTIVATE MSDIALOG oDlg CENTERED

    If lOk
        If nSel <= 1 .Or. nSel > Len(aUsu)
            cFiltUsu := ""
        Else
            cFiltUsu := AllTrim(aUsu[nSel][1])
        EndIf

        oBrowse:SetQuery(MontaQuery())
        oBrowse:Refresh(.T.)
        oBrowse:GoTop()

        If !Empty(cFiltUsu) .And. Select(cAliasQry) > 0 .And. (cAliasQry)->(Eof())
            MsgAlert("Nenhuma solicitação encontrada para este usuário.", "Atenção")
        EndIf
    EndIf

    RestArea(aArea)
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} NumeroVisivel
Mostra o número da solicitação sem os zeros à esquerda (000003 vira 3).

@param   cNumero Número gravado na tabela
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  cNumero Número pronto para exibição
/*/
//-------------------------------------------------------------------
Static Function NumeroVisivel(cNumero)
    Local cNum := AllTrim(cValToChar(cNumero))

    If Empty(cNum)
        Return ""
    EndIf

Return AllTrim(Str(Val(cNum), 10))

//-------------------------------------------------------------------
/*/{Protheus.doc} ZSOLNFINC
Abre a tela em modo de inclusão.

@type    User Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
User Function ZSOLNFINC()
    Local aArea := GetArea()

    MontaTela(1, 0)
    RestArea(aArea)
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} ZSOLNFALT
Abre a tela em modo de alteração da solicitação selecionada.

@type    User Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
User Function ZSOLNFALT()
    Local aArea   := GetArea()
    Local nRec    := 0
    Local cStatus := ""

    nRec    := (cAliasQry)->NRECZSN
    cStatus := AllTrim((cAliasQry)->ZSN_STATUS)

    If nRec <= 0
        MsgAlert("Selecione uma solicitação na lista.", "Atenção")
        RestArea(aArea)
        Return Nil
    EndIf

    If cStatus == "3"
        MsgAlert("Solicitação cancelada não pode ser alterada.", "Atenção")
        RestArea(aArea)
        Return Nil
    EndIf

    MontaTela(2, nRec)
    RestArea(aArea)
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} ZSOLNFVIS
Abre a tela em modo de visualização (somente leitura).

@type    User Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
User Function ZSOLNFVIS()
    Local aArea := GetArea()
    Local nRec  := 0

    nRec := (cAliasQry)->NRECZSN

    If nRec <= 0
        MsgAlert("Selecione uma solicitação na lista.", "Atenção")
        RestArea(aArea)
        Return Nil
    EndIf

    MontaTela(3, nRec)
    RestArea(aArea)
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} ZSOLNFEXC
Exclui logicamente a solicitação selecionada e seus produtos.

@type    User Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
User Function ZSOLNFEXC()
    Local aArea   := GetArea()
    Local nRec    := 0
    Local cNum    := ""
    Local cQuery  := ""
    Local lOk     := .T.

    nRec := (cAliasQry)->NRECZSN
    cNum := AllTrim((cAliasQry)->ZSN_NUM)

    If nRec <= 0
        MsgAlert("Selecione uma solicitação na lista.", "Atenção")
        RestArea(aArea)
        Return Nil
    EndIf

    If AllTrim((cAliasQry)->ZSN_STATUS) == "2"
        MsgAlert("Solicitação já emitida não pode ser excluída. Use o botão Situação.", "Atenção")
        RestArea(aArea)
        Return Nil
    EndIf

    If !MsgYesNo("Confirma a exclusão da solicitação número " + NumeroVisivel(cNum) + "?", "Atenção")
        RestArea(aArea)
        Return Nil
    EndIf

    BEGIN TRANSACTION

    cQuery := "UPDATE " + NomeTabCab() + " SET D_E_L_E_T_ = '*' "
    cQuery += "WHERE ZSN_FILIAL = '" + xFilial("SA2") + "' "
    cQuery += "AND ZSN_NUM = '" + EscapaSql(cNum) + "'"
    If TcSqlExec(cQuery) < 0
        DisarmTransaction()
        lOk := .F.
    EndIf

    If lOk
        cQuery := "UPDATE " + NomeTabItm() + " SET D_E_L_E_T_ = '*' "
        cQuery += "WHERE ZSI_FILIAL = '" + xFilial("SA2") + "' "
        cQuery += "AND ZSI_NUM = '" + EscapaSql(cNum) + "'"
        If TcSqlExec(cQuery) < 0
            DisarmTransaction()
            lOk := .F.
        EndIf
    EndIf

    END TRANSACTION

    If lOk
        MsgInfo("Solicitação " + NumeroVisivel(cNum) + " excluída.", "Concluído")
    Else
        MsgAlert("Não foi possível excluir a solicitação." + CRLF + TcSqlError(), "Erro")
    EndIf

    RestArea(aArea)
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} ZSOLNFSTS
Troca a situação da solicitação selecionada.

@type    User Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
User Function ZSOLNFSTS()
    Local aArea   := GetArea()
    Local nRec    := 0
    Local cNum    := ""
    Local cStatus := ""
    Local oDlgSt
    Local oBtn1
    Local oBtn2
    Local oBtn3

    nRec    := (cAliasQry)->NRECZSN
    cNum    := AllTrim((cAliasQry)->ZSN_NUM)
    cStatus := AllTrim((cAliasQry)->ZSN_STATUS)

    If nRec <= 0
        MsgAlert("Selecione uma solicitação na lista.", "Atenção")
        RestArea(aArea)
        Return Nil
    EndIf

    DEFINE MSDIALOG oDlgSt TITLE "Situação da Solicitação" FROM 000,000 TO 250,450 PIXEL

    @ 012,010 SAY "Solicitação:" SIZE 50,007 OF oDlgSt PIXEL
    @ 010,065 SAY NumeroVisivel(cNum) SIZE 60,007 OF oDlgSt PIXEL
    @ 030,010 SAY "Situação atual:" SIZE 60,007 OF oDlgSt PIXEL
    @ 028,075 SAY DescStatus(cStatus) SIZE 80,007 OF oDlgSt PIXEL

    @ 060,010 BUTTON oBtn1 PROMPT "Pendente" SIZE 60,016 OF oDlgSt PIXEL ;
        ACTION (TrocaStatus(cNum, StatusCodigo("Pendente")), oDlgSt:End())
    @ 060,080 BUTTON oBtn2 PROMPT "Emitida" SIZE 60,016 OF oDlgSt PIXEL ;
        ACTION (TrocaStatus(cNum, StatusCodigo("Emitida")), oDlgSt:End())
    @ 060,150 BUTTON oBtn3 PROMPT "Cancelada" SIZE 60,016 OF oDlgSt PIXEL ;
        ACTION (TrocaStatus(cNum, StatusCodigo("Cancelada")), oDlgSt:End())
    ACTIVATE MSDIALOG oDlgSt CENTERED

    RestArea(aArea)
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} TrocaStatus
Grava a nova situação da solicitação.

@param   cNum    Número da solicitação
@param   cStatus Código da nova situação
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  lOk .T. quando a situação foi gravada
/*/
//-------------------------------------------------------------------
Static Function TrocaStatus(cNum, cStatus)
    Local lOk    := .T.
    Local cQuery := ""

    cQuery := "UPDATE " + NomeTabCab() + " SET "
    cQuery += "ZSN_STATUS = '" + EscapaSql(cStatus) + "', "
    cQuery += "ZSN_USER = '" + EscapaSql(UsrRetName(RetCodUsr())) + "', "
    cQuery += "ZSN_HORA = '" + Time() + "' "
    cQuery += "WHERE ZSN_FILIAL = '" + xFilial("SA2") + "' "
    cQuery += "AND ZSN_NUM = '" + EscapaSql(cNum) + "' "
    cQuery += "AND D_E_L_E_T_ = ' '"

    If TcSqlExec(cQuery) < 0
        lOk := .F.
        MsgAlert("Não foi possível gravar a situação." + CRLF + TcSqlError(), "Erro")
    Else
        MsgInfo("Situação alterada para " + DescStatus(cStatus) + ".", "Concluído")
    EndIf

Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} ZSOLNFPDF
Gera o espelho da solicitação em PDF para envio ao fornecedor.

Sem parâmetro, imprime a solicitação selecionada na lista. O arquivo é
aberto na visualização do Protheus, de onde o usuário pode imprimir ou
salvar o PDF.

@param   nRec R_E_C_N_O_ da solicitação (vazio = registro selecionado na lista)
@type    User Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
User Function ZSOLNFPDF(nRec)
    Local aArea  := GetArea()
    Local aCab   := {}
    Local aItens := {}
    Local nReg   := 0

    If ValType(nRec) == "N"
        nReg := nRec
    EndIf

    // Chamada pela lista: usa a solicitação posicionada no browse.
    If nReg <= 0 .And. Type("cAliasQry") == "C"
        If Select(cAliasQry) > 0
            nReg := (cAliasQry)->NRECZSN
        EndIf
    EndIf

    If nReg <= 0
        MsgAlert("Selecione uma solicitação na lista.", "Atenção")
        RestArea(aArea)
        Return Nil
    EndIf

    If !CarregaPDF(nReg, @aCab)
        MsgAlert("Solicitação não encontrada para gerar o PDF.", "Atenção")
        RestArea(aArea)
        Return Nil
    EndIf

    aItens := ItensPdf(aCab[1])

    GeraPdf(aCab, aItens)

    RestArea(aArea)
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} CarregaPDF
Lê o cabeçalho da solicitação para o espelho em PDF.

@param   nRec R_E_C_N_O_ da solicitação
@param   aCab Vetor preenchido com os dados do cabeçalho
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  lOk .T. quando o registro foi encontrado
/*/
//-------------------------------------------------------------------
Static Function CarregaPDF(nRec, aCab)
    Local lOk    := .F.
    Local aArea  := GetArea()
    Local cAlias := GetNextAlias()
    Local cQuery := ""

    cQuery := "SELECT ZSN_NUM, ZSN_DTSOL, ZSN_FORNEC, ZSN_LOJA, ZSN_NOMFOR, ZSN_CGC, "
    cQuery += "ZSN_ARMAZ, ZSN_VOLUME, ZSN_TPFRETE, ZSN_TPOPER, ZSN_DESCOP, ZSN_DTEMIS, "
    cQuery += "ZSN_HREMIS, ZSN_MOTOR, ZSN_CPF, ZSN_PLACA, ZSN_MODELO, "
    // VARCHAR(MAX) não aparece no alias do TCQuery: o CAST expõe a coluna.
    cQuery += "CAST(ZSN_OBS AS VARCHAR(500)) AS ZSN_OBS, "
    cQuery += "ZSN_TOTAL, ZSN_STATUS, ZSN_USER, ZSN_HORA "
    cQuery += "FROM " + NomeTabCab() + " "
    cQuery += "WHERE R_E_C_N_O_ = " + cValToChar(nRec) + " "
    cQuery += "AND ZSN_FILIAL = '" + xFilial("SA2") + "' "
    cQuery += "AND D_E_L_E_T_ = ' '"

    TcQuery cQuery New Alias (cAlias)

    If !(cAlias)->(Eof())
        aCab := { AllTrim((cAlias)->ZSN_NUM),;
                  STOD((cAlias)->ZSN_DTSOL),;
                  DescStatus((cAlias)->ZSN_STATUS),;
                  AllTrim((cAlias)->ZSN_FORNEC),;
                  AllTrim((cAlias)->ZSN_LOJA),;
                  AllTrim((cAlias)->ZSN_NOMFOR),;
                  FormataCGC((cAlias)->ZSN_CGC),;
                  AllTrim((cAlias)->ZSN_ARMAZ),;
                  (cAlias)->ZSN_VOLUME,;
                  AllTrim((cAlias)->ZSN_TPFRETE),;
                  AllTrim((cAlias)->ZSN_TPOPER),;
                  AllTrim((cAlias)->ZSN_DESCOP),;
                  STOD((cAlias)->ZSN_DTEMIS),;
                  AllTrim((cAlias)->ZSN_HREMIS),;
                  AllTrim((cAlias)->ZSN_MOTOR),;
                  AllTrim((cAlias)->ZSN_CPF),;
                  AllTrim((cAlias)->ZSN_PLACA),;
                  AllTrim((cAlias)->ZSN_MODELO),;
                  AllTrim((cAlias)->ZSN_OBS),;
                  (cAlias)->ZSN_TOTAL,;
                  AllTrim((cAlias)->ZSN_USER),;
                  AllTrim((cAlias)->ZSN_HORA) }
        lOk := .T.
    EndIf

    (cAlias)->(DbCloseArea())
    RestArea(aArea)
Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} ItensPdf
Lê os produtos da solicitação para o espelho em PDF.

@param   cNumero Número da solicitação
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  aItens Vetor de produtos (item, produto, descrição, qtde, valor unitário, total)
/*/
//-------------------------------------------------------------------
Static Function ItensPdf(cNumero)
    Local aItens := {}
    Local aArea  := GetArea()
    Local cAlias := GetNextAlias()
    Local cQuery := ""

    cQuery := "SELECT ZSI_ITEM, ZSI_PROD, ZSI_DESC, ZSI_QTDE, ZSI_VLRUNI, ZSI_VLRTOT "
    cQuery += "FROM " + NomeTabItm() + " "
    cQuery += "WHERE ZSI_FILIAL = '" + xFilial("SA2") + "' "
    cQuery += "AND ZSI_NUM = '" + EscapaSql(cNumero) + "' "
    cQuery += "AND D_E_L_E_T_ = ' ' "
    cQuery += "ORDER BY ZSI_ITEM"

    TcQuery cQuery New Alias (cAlias)

    (cAlias)->(DbGoTop())
    While !(cAlias)->(Eof())
        aAdd(aItens, { Val((cAlias)->ZSI_ITEM),;
                       (cAlias)->ZSI_PROD,;
                       (cAlias)->ZSI_DESC,;
                       (cAlias)->ZSI_QTDE,;
                       (cAlias)->ZSI_VLRUNI,;
                       (cAlias)->ZSI_VLRTOT })
        (cAlias)->(DbSkip())
    EndDo

    (cAlias)->(DbCloseArea())
    RestArea(aArea)
Return aItens

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfDaTela
Imprime o espelho com os dados que estão na tela da solicitação.

Usado pelo botão "Imprimir PDF": imprime exatamente o que o usuário
está vendo, inclusive alterações ainda não gravadas.

@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function PdfDaTela()
    Local aCab := {}

    aCab := { cNumSol, dDataSol, cStDesc, AllTrim(cFornec), AllTrim(cLoja),;
              AllTrim(cNomFor), cCgc, AllTrim(cArmaz), nVolume,;
              AllTrim(cTpFrete), AllTrim(cTpOper), AllTrim(cDescOp),;
              dDtEmis, AllTrim(cHrEmis), AllTrim(cMotor), AllTrim(cCpf),;
              AllTrim(cPlaca), AllTrim(cModelo), AllTrim(cObs), nTotal,;
              UsrRetName(RetCodUsr()), Time() }

    GeraPdf(aCab, aItens)
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} EmpresaPdf
Nome e CNPJ da empresa/filial ativa para o cabeçalho do espelho.

@type    Static Function
@author  Vortice
@since   10/11/2026
@return  aEmp Vetor com o nome e o CNPJ da empresa
/*/
//-------------------------------------------------------------------
Static Function EmpresaPdf()
    Local aArea := GetArea()
    Local aEmp  := {"", ""}

    If Select("SM0") > 0
        DbSelectArea("SM0")
        SM0->(DbSetOrder(1))
        If SM0->(DbSeek(FwGrpCompany() + FwCodFil()))
            aEmp := { AllTrim(SM0->M0_NOME), FormataCGC(SM0->M0_CGC) }
            If Empty(aEmp[1])
                aEmp[1] := AllTrim(SM0->M0_NOMECOM)
            EndIf
        EndIf
    EndIf

    RestArea(aArea)
Return aEmp

//-------------------------------------------------------------------
/*/{Protheus.doc} GeraPdf
Desenha o espelho da solicitação em PDF e abre a visualização.

A paginação é automática: quando os produtos passam do limite da página
o cabeçalho é repetido na página seguinte. O total, as observações e as
assinaturas ficam sempre na última página.

@param   aCab   Vetor com os dados do cabeçalho
@param   aItens Vetor de produtos da solicitação
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function GeraPdf(aCab, aItens, cDirSrv)
    Local aArea    := GetArea()
    Local aEmp     := EmpresaPdf()
    Local cArqPdf  := ""
    Local nLimite  := 740
    Local nLinha   := 0
    Local nPag     := 1
    Local nTotal   := 0
    Local nI       := 0
    Local nAlt     := 0
    Local oPrinter := Nil
    Local lEmail   := (cDirSrv != Nil)
    Local cRetPdf  := ""

    Private nPdfEsq  := 20
    Private nPdfDir  := 555
    Private nPdfDes  := 50
    Private aPdfCol  := {20, 48, 118, 350, 412, 482, 555}
    Private oPdfFt06 := Nil
    Private oPdfFt07 := Nil
    Private oPdfFt07N:= Nil
    Private oPdfFt08 := Nil
    Private oPdfFt08R:= Nil
    Private oPdfFt09N:= Nil
    Private oPdfFt12N:= Nil

    cArqPdf := "SOLICITACAO_NF_" + NumeroVisivel(aCab[1])

    If lEmail
        oPrinter := FWMSPrinter():New(cArqPdf, IMP_PDF, .F., cDirSrv, .T., , , , .T., , , .F.)
        oPrinter:cPathPDF := cDirSrv
    Else
        oPrinter := FWMSPrinter():New(cArqPdf, IMP_PDF, .F., , .T.)
    EndIf
    oPrinter:SetPortrait()
    oPrinter:SetPaperSize(DMPAPER_A4)
    oPrinter:SetMargin(15, 15, 15, 15)
    oPrinter:SetResolution(72)

    oPdfFt06  := TFontEx():New(oPrinter, "Arial", 06, 06, .F., .F., .F.)
    oPdfFt07  := TFontEx():New(oPrinter, "Arial", 07, 07, .F., .F., .F.)
    oPdfFt07N := TFontEx():New(oPrinter, "Arial", 07, 07, .T., .F., .F.)
    oPdfFt08  := TFontEx():New(oPrinter, "Arial", 08, 08, .T., .F., .F.)
    oPdfFt08R := TFontEx():New(oPrinter, "Arial", 08, 08, .F., .F., .F.)
    oPdfFt09N := TFontEx():New(oPrinter, "Arial", 09, 09, .T., .F., .F.)
    oPdfFt12N := TFontEx():New(oPrinter, "Arial", 12, 12, .T., .F., .F.)

    oPrinter:StartPage()
    nLinha := PdfCabecalho(oPrinter, aCab, aEmp, nPag)

    For nI := 1 To Len(aItens)
        nAlt := PdfAlturaItem(aItens[nI])

        If nLinha + nAlt > nLimite
            PdfRodape(oPrinter, aCab, nPag)
            oPrinter:EndPage()
            nPag   += 1
            oPrinter:StartPage()
            nLinha := PdfCabecalho(oPrinter, aCab, aEmp, nPag)
        EndIf

        nLinha := PdfItem(oPrinter, nLinha, aItens[nI])
    Next nI

    nTotal := SomaItens(aItens)
    If nTotal == 0
        nTotal := aCab[20]
    EndIf

    // Total, observações e assinaturas não cabem nesta página: abre outra.
    If nLinha + 225 > nLimite
        PdfRodape(oPrinter, aCab, nPag)
        oPrinter:EndPage()
        nPag   += 1
        oPrinter:StartPage()
        nLinha := PdfCabecalho(oPrinter, aCab, aEmp, nPag)
    EndIf

    nLinha := PdfTotal(oPrinter, nLinha, nTotal)
    nLinha := PdfObservacoes(oPrinter, nLinha, aCab)
    PdfAssinaturas(oPrinter, nLinha)

    PdfRodape(oPrinter, aCab, nPag)

    oPrinter:EndPage()
    If lEmail
        oPrinter:Print()
        cRetPdf := cDirSrv + cArqPdf + ".pdf"
    Else
        oPrinter:Preview()
    EndIf

    FreeObj(oPdfFt06)
    FreeObj(oPdfFt07)
    FreeObj(oPdfFt07N)
    FreeObj(oPdfFt08)
    FreeObj(oPdfFt08R)
    FreeObj(oPdfFt09N)
    FreeObj(oPdfFt12N)
    FreeObj(oPrinter)

    nPdfEsq  := Nil
    nPdfDir  := Nil
    nPdfDes  := Nil
    aPdfCol  := Nil
    oPdfFt06  := Nil
    oPdfFt07  := Nil
    oPdfFt07N := Nil
    oPdfFt08  := Nil
    oPdfFt08R := Nil
    oPdfFt09N := Nil
    oPdfFt12N := Nil
    oPrinter  := Nil

    RestArea(aArea)
Return cRetPdf

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfFim
Coluna inicial de um texto alinhado pela direita dentro de uma coluna.

@param   nCol   Limite direito da coluna
@param   cTexto Texto a alinhar
@param   nFonte Corpo da fonte em pontos
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nX Coluna onde o texto deve começar
/*/
//-------------------------------------------------------------------
Static Function PdfFim(nCol, cTexto, nFonte, lNeg)
    // 8 pontos de folga. O texto precisa vir sem espacos a esquerda (AllTrim),
    // senao o Say imprime os espacos e o numero ultrapassa a linha.
Return (nCol - 8) - PdfLargTxt(cTexto, nFonte, lNeg)

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfCentro
Coluna inicial de um texto centralizado na largura útil da página.

@param   cTexto Texto a centralizar
@param   nFonte Corpo da fonte em pontos
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nX Coluna onde o texto deve começar
/*/
//-------------------------------------------------------------------
Static Function PdfCentro(cTexto, nFonte)
Return nPdfEsq + ((nPdfDir - nPdfEsq) - PdfLargTxt(cTexto, nFonte, .T.)) / 2

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfCampo
Escreve um campo do espelho: rótulo alinhado à direita e valor sempre na
mesma coluna, de modo que os dois pontos e os valores formem uma coluna reta.

O rótulo termina na coluna nColFim e o valor começa 8 pontos depois, o que
mantém o valor junto do seu título em todas as linhas do bloco.

@param   oPrinter   Objeto FWMSPrinter
@param   nLinha     Linha do campo
@param   nColFim    Coluna onde o rótulo termina
@param   cRotulo    Texto do rótulo
@param   cValor     Valor do campo
@param   oFontValor Fonte do valor
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nLinha Próxima linha livre depois do valor
/*/
//-------------------------------------------------------------------
Static Function PdfCampo(oPrinter, nLinha, nColRot, cRotulo, cValor, oFontValor, nColLim, nColVal)
    Local nLarg := 0
    Local nFim  := 0

    If nColVal == Nil
        nColVal := 122
    EndIf
    If nColLim == Nil
        nColLim := nPdfDir
    EndIf
    nLarg := Max(Int((nColLim - nColVal) / (0.6 * 8)), 5)

    oPrinter:Say(nLinha, nColRot, cRotulo, oPdfFt08:oFont)
    nFim := PdfTexto(oPrinter, nLinha, nColVal, nLarg, AllTrim(cValToChar(cValor)), oFontValor)
Return nFim + 4

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfCabecalho
Desenha o cabeçalho do espelho e os títulos da grade de produtos.

Repetido em todas as páginas para que a folha enviada ao fornecedor tenha
sempre a identificação da solicitação.

@param   oPrinter Objeto FWMSPrinter
@param   aCab     Vetor com os dados do cabeçalho
@param   aEmp     Vetor com o nome e o CNPJ da empresa
@param   nPag     Número da página
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nLinha Próxima linha livre depois do cabeçalho
/*/
//-------------------------------------------------------------------
Static Function PdfCabecalho(oPrinter, aCab, aEmp, nPag)
    Local nLinha  := 34
    Local cTitulo := "SOLICITAÇÃO DE NOTA FISCAL DE DEVOLUÇÃO"
    Local cPag    := "Página " + cValToChar(nPag)

    // 34: identificação da empresa e página
    oPrinter:Say(nLinha, nPdfEsq, aEmp[1], oPdfFt12N:oFont)
    oPrinter:Say(nLinha + 2, PdfFim(nPdfDir + 6, cPag, 7), cPag, oPdfFt07:oFont)

    // 50: CNPJ da empresa
    nLinha += 16
    oPrinter:Say(nLinha, nPdfEsq, "CNPJ " + aEmp[2], oPdfFt08R:oFont)

    // 62 e 65: filete duplo sob o timbre
    nLinha += 12
    oPrinter:Line(nLinha, nPdfEsq, nLinha, nPdfDir, CLR_BLACK, "-8")
    nLinha += 3
    oPrinter:Line(nLinha, nPdfEsq, nLinha, nPdfDir, CLR_BLACK, "-5")

    // 83: título do documento
    nLinha += 18
    oPrinter:Say(nLinha, PdfCentro(cTitulo, 12), cTitulo, oPdfFt12N:oFont)

    nLinha += 20
    oPrinter:Box(nLinha, nPdfEsq, nLinha + 22, nPdfDir)
    oPrinter:Say(nLinha + 14, nPdfEsq + 8, "Nº " + NumeroVisivel(aCab[1]), oPdfFt09N:oFont)
    PdfCampo(oPrinter, nLinha + 14, 200, "Data da Solicitação:", PdfData(aCab[2]), oPdfFt08R, 390, 292)
    PdfCampo(oPrinter, nLinha + 14, 400, "Situação:", aCab[3], oPdfFt08, nPdfDir, 450)

    nLinha += 36
    nLinha := PdfSecao(oPrinter, nLinha, "DADOS DO FORNECEDOR")

    nLinha := Max(PdfCampo(oPrinter, nLinha, 24, "Código:", aCab[4] + " / " + aCab[5], oPdfFt08R, 325), ;
                  PdfCampo(oPrinter, nLinha, 330, "CNPJ:", aCab[7], oPdfFt08R, nPdfDir, 392))
    nLinha := PdfCampo(oPrinter, nLinha, 24, "Razão Social:", aCab[6], oPdfFt08R)

    nLinha := PdfSecao(oPrinter, nLinha, "DADOS DA OPERAÇÃO")
    nLinha := PdfCampo(oPrinter, nLinha, 24, "Tipo de Operação:", aCab[11], oPdfFt08R)
    nLinha := PdfCampo(oPrinter, nLinha, 24, "Descrição:", aCab[12], oPdfFt08R)
    nLinha := PdfCampo(oPrinter, nLinha, 24, "Tipo de Frete:", aCab[10], oPdfFt08R)
    nLinha := Max(PdfCampo(oPrinter, nLinha, 24, "Armazenagem:", aCab[8], oPdfFt08R, 325), ;
                  PdfCampo(oPrinter, nLinha, 330, "Volume:", Transform(aCab[9], "@E 999"), oPdfFt08R, nPdfDir, 392))
    nLinha := Max(PdfCampo(oPrinter, nLinha, 24, "Emissão da Nota Fiscal:", PdfData(aCab[13]), oPdfFt08R, 325), ;
                  PdfCampo(oPrinter, nLinha, 330, "Horário Limite:", aCab[14], oPdfFt08R, nPdfDir, 392))

    nLinha := PdfSecao(oPrinter, nLinha, "TRANSPORTE")
    nLinha := PdfCampo(oPrinter, nLinha, 24, "Motorista:", aCab[15], oPdfFt08R)
    nLinha := Max(Max(PdfCampo(oPrinter, nLinha, 24, "CPF:", aCab[16], oPdfFt08R, 215), ;
                      PdfCampo(oPrinter, nLinha, 225, "Placa:", aCab[17], oPdfFt08R, 325, 262)), ;
                      PdfCampo(oPrinter, nLinha, 330, "Modelo:", aCab[18], oPdfFt08R, nPdfDir, 392))

    // Grade de produtos: títulos na mesma régua das colunas de dados
    nLinha := PdfSecao(oPrinter, nLinha, "PRODUTOS DA DEVOLUÇÃO")

    oPrinter:Box(nLinha, nPdfEsq, nLinha + 20, nPdfDir)
    oPrinter:Say(nLinha + 13, aPdfCol[1] + 4, "Item", oPdfFt07N:oFont)
    oPrinter:Say(nLinha + 13, aPdfCol[2] + 4, "Código", oPdfFt07N:oFont)
    oPrinter:Say(nLinha + 13, aPdfCol[3] + 4, "Descrição", oPdfFt07N:oFont)
    oPrinter:Say(nLinha + 13, PdfFim(aPdfCol[5], "Qtde", 7, .T.), "Qtde", oPdfFt07N:oFont)
    oPrinter:Say(nLinha + 13, PdfFim(aPdfCol[6], "Unitário (R$)", 7, .T.), "Unitário (R$)", oPdfFt07N:oFont)
    oPrinter:Say(nLinha + 13, PdfFim(aPdfCol[7], "Total (R$)", 7, .T.), "Total (R$)", oPdfFt07N:oFont)

    nLinha += 20
Return nLinha

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfSecao
Escreve o título de um bloco e a linha de sublinhado, deixando respiro
antes do título para ele não encostar na informação do bloco anterior.

@param   oPrinter Objeto FWMSPrinter
@param   nLinha   Linha de onde o bloco começa
@param   cTitulo  Texto do título
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nLinha Primeira linha livre abaixo do título
/*/
//-------------------------------------------------------------------
Static Function PdfSecao(oPrinter, nLinha, cTitulo)
    nLinha += 4
    oPrinter:Say(nLinha + 6, nPdfEsq, cTitulo, oPdfFt08:oFont)
    oPrinter:Line(nLinha + 16, nPdfEsq, nLinha + 16, nPdfDir, CLR_BLACK, "-5")
Return nLinha + 26

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfItem
Desenha uma linha de produto no espelho, com as colunas fechadas.

Os valores ficam alinhados à direita dentro da sua coluna e a descrição
quebra dentro da largura da coluna, sem invadir os números.

@param   oPrinter Objeto FWMSPrinter
@param   nLinha   Linha onde a linha começa
@param   aItem    Vetor do produto (item, produto, descrição, qtde, valor unitário, total)
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nLinha Próxima linha livre
/*/
//-------------------------------------------------------------------
Static Function PdfItem(oPrinter, nLinha, aItem)
    Local aDes  := PdfLinhas(AllTrim(aItem[3]), nPdfDes)
    Local nFim  := nLinha + PdfAlturaItem(aItem)
    Local nBase := nLinha + 12
    Local cQtd  := AllTrim(Transform(aItem[4], "@E 999,999.99"))
    Local cUni  := AllTrim(Transform(aItem[5], "@E 999,999,999.99"))
    Local cTot  := AllTrim(Transform(aItem[6], "@E 999,999,999.99"))
    Local nI    := 0

    // Primeira linha: item, codigo, primeira linha da descricao e numeros
    // alinhados à direita nas colunas de qtde, unitario e total.
    oPrinter:Say(nBase, aPdfCol[1] + 4, StrZero(aItem[1], 3), oPdfFt07:oFont)
    oPrinter:Say(nBase, aPdfCol[2] + 4, AllTrim(aItem[2]), oPdfFt07:oFont)
    oPrinter:Say(nBase, aPdfCol[3] + 4, aDes[1], oPdfFt07:oFont)
    oPrinter:Say(nBase, PdfFim(aPdfCol[5], cQtd, 7), cQtd, oPdfFt07:oFont)
    oPrinter:Say(nBase, PdfFim(aPdfCol[6], cUni, 7), cUni, oPdfFt07:oFont)
    oPrinter:Say(nBase, PdfFim(aPdfCol[7], cTot, 7), cTot, oPdfFt07:oFont)

    // Linhas seguintes da descricao (quebra): somente texto, sem numeros,
    // para nao repetir valores e nao embolar a linha da grade.
    For nI := 2 To Len(aDes)
        oPrinter:Say(nBase + ((nI - 1) * 11), aPdfCol[3] + 4, aDes[nI], oPdfFt07:oFont)
    Next nI

    oPrinter:Line(nFim, nPdfEsq, nFim, nPdfDir, CLR_BLACK, "-5")
    For nI := 1 To Len(aPdfCol)
        oPrinter:Line(nLinha, aPdfCol[nI], nFim, aPdfCol[nI], CLR_BLACK, "-5")
    Next nI

Return nFim + 1

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfAlturaItem
Altura que a linha do produto ocupa, contando as quebras da descrição.

@param   aItem Vetor do produto
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nAlt Altura da linha em pontos
/*/
//-------------------------------------------------------------------
Static Function PdfAlturaItem(aItem)
    Local nDes := Len(PdfLinhas(AllTrim(aItem[3]), nPdfDes))

    If nDes < 1
        nDes := 1
    EndIf

Return (nDes * 11) + 9

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfTotal
Desenha o quadro do total geral da solicitação.

@param   oPrinter Objeto FWMSPrinter
@param   nLinha   Linha onde o quadro começa
@param   nTotal   Valor total da solicitação
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nLinha Próxima linha livre
/*/
//-------------------------------------------------------------------
Static Function PdfTotal(oPrinter, nLinha, nTotal)
    Local cTot := AllTrim(Transform(nTotal, "@E 999,999,999.99"))

    nLinha += 8
    oPrinter:Box(nLinha, aPdfCol[4], nLinha + 22, nPdfDir)
    oPrinter:Say(nLinha + 14, aPdfCol[4] + 6, "TOTAL GERAL (R$)", oPdfFt08R:oFont)
    oPrinter:Say(nLinha + 15, PdfFim(nPdfDir, cTot, 9, .T.), cTot, oPdfFt09N:oFont)

Return nLinha + 32

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfObservacoes
Desenha as observações da solicitação e os avisos fixos.

@param   oPrinter Objeto FWMSPrinter
@param   nLinha   Linha onde o bloco começa
@param   aCab     Vetor com os dados do cabeçalho
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nLinha Próxima linha livre
/*/
//-------------------------------------------------------------------
Static Function PdfObservacoes(oPrinter, nLinha, aCab)
    // Largura em caracteres: pontos disponíveis / largura do caractere.
    Local nLarg := Int((nPdfDir - (nPdfEsq + 4)) / (0.6 * 7))

    nLinha += 6
    nLinha := PdfSecao(oPrinter, nLinha, "OBSERVAÇÕES")

    If Empty(AllTrim(aCab[19]))
        oPrinter:Say(nLinha, nPdfEsq + 4, "Sem observações.", oPdfFt07:oFont)
        nLinha += 15
    Else
        nLinha := PdfTexto(oPrinter, nLinha, nPdfEsq + 4, nLarg, aCab[19], oPdfFt07)
    EndIf

    nLinha += 15
    nLinha := PdfSecao(oPrinter, nLinha, "OBSERVAÇÕES IMPORTANTES")
    nLinha := PdfTexto(oPrinter, nLinha, nPdfEsq + 4, nLarg,;
             "A solicitação de emissão de Nota Fiscal deve ser feita com prazo de 24 horas de antecedência.",;
             oPdfFt07)
    nLinha := PdfTexto(oPrinter, nLinha, nPdfEsq + 4, nLarg,;
             "As notas fiscais somente serão emitidas com a apresentação deste modelo padrão.",;
             oPdfFt07)

Return nLinha

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfAssinaturas
Desenha as linhas de assinatura no pé da última página.

@param   oPrinter Objeto FWMSPrinter
@param   nLinha   Linha livre depois das observações
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function PdfAssinaturas(oPrinter, nLinha)
    Local cEsq := "Solicitante / Expedição"
    Local cDir := "Motorista / Transportadora"

    If nLinha < 660
        nLinha := 660
    EndIf

    nLinha += 20
    oPrinter:Line(nLinha, 045, nLinha, 245, CLR_BLACK, "-5")
    oPrinter:Line(nLinha, 310, nLinha, 510, CLR_BLACK, "-5")

    oPrinter:Say(nLinha + 10, 145 - (PdfLargTxt(cEsq, 7, .T.) / 2), cEsq, oPdfFt07N:oFont)
    oPrinter:Say(nLinha + 10, 410 - (PdfLargTxt(cDir, 7, .T.) / 2), cDir, oPdfFt07N:oFont)

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfRodape
Desenha a linha de rodapé com a identificação de quem imprimiu.

@param   oPrinter Objeto FWMSPrinter
@param   aCab     Vetor com os dados do cabeçalho
@param   nPag     Número da página
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function PdfRodape(oPrinter, aCab, nPag)
    Local cPag := "Página " + cValToChar(nPag)

    oPrinter:Line(790, nPdfEsq, 790, nPdfDir, CLR_BLACK, "-5")
    oPrinter:Say(796, nPdfEsq, "Impresso por " + aCab[21] + " em " + DtoC(Date()) + " às " + Time(),;
                 oPdfFt06:oFont)
    oPrinter:Say(796, PdfFim(nPdfDir + 6, cPag, 6), cPag, oPdfFt06:oFont)
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfTexto
Escreve um texto no PDF quebrando as linhas entre as palavras.

@param   oPrinter Objeto FWMSPrinter
@param   nLinha   Linha inicial
@param   nCol     Coluna inicial
@param   nLarg    Largura máxima em caracteres
@param   cTexto   Texto a imprimir
@param   oFont    Fonte do texto
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nLinha Próxima linha livre depois do texto
/*/
//-------------------------------------------------------------------
Static Function PdfTexto(oPrinter, nLinha, nCol, nLarg, cTexto, oFont)
    Local aLin := PdfLinhas(cTexto, nLarg)
    Local nI   := 0

    For nI := 1 To Len(aLin)
        oPrinter:Say(nLinha, nCol, aLin[nI], oFont:oFont)
        nLinha += 11
    Next nI

Return nLinha

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfLinhas
Divide um texto em linhas de até nLarg caracteres, quebrando em espaços.

Texto sem espaço no meio é cortado para não estourar a coluna.

@param   cTexto Texto a dividir
@param   nLarg  Largura máxima em caracteres
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  aLinhas Vetor com as linhas prontas para impressão
/*/
//-------------------------------------------------------------------
Static Function PdfLinhas(cTexto, nLarg)
    Local aLinhas := {}
    Local cResto  := AllTrim(cTexto)
    Local cPedaco := ""
    Local nPos    := 0

    If Empty(cResto)
        aAdd(aLinhas, "")
        Return aLinhas
    EndIf

    While Len(cResto) > nLarg
        cPedaco := SubStr(cResto, 1, nLarg)
        nPos    := Rat(" ", cPedaco)

        If nPos > 1
            aAdd(aLinhas, AllTrim(SubStr(cPedaco, 1, nPos - 1)))
            cResto := AllTrim(SubStr(cResto, nPos + 1))
        Else
            aAdd(aLinhas, cPedaco)
            cResto := AllTrim(SubStr(cResto, nLarg + 1))
        EndIf
    EndDo

    aAdd(aLinhas, cResto)
Return aLinhas

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfLargTxt
Largura aproximada em pontos de um texto em Arial, para alinhar títulos.

@param   cTexto Texto a medir
@param   nFonte Corpo da fonte em pontos
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nLarg Largura aproximada em pontos
/*/
//-------------------------------------------------------------------
Static Function PdfLargTxt(cTexto, nFonte, lNeg)
    Local nW   := 0
    Local nI   := 0
    Local cCh  := ""
    Local cTx  := AllTrim(cTexto)
    Local nFat := 0.53

    For nI := 1 To Len(cTx)
        cCh := SubStr(cTx, nI, 1)
        Do Case
            Case cCh $ "0123456789$"
                nFat := 0.556
            Case cCh $ " .,:;/'|!()[]-"
                nFat := 0.278
            Case cCh $ "ijl"
                nFat := 0.222
            Case cCh $ "ftrI"
                nFat := 0.30
            Case cCh $ "mM"
                nFat := 0.85
            Case cCh $ "wW%"
                nFat := 0.80
            Case cCh $ "ABCDEFGHJKLNOPQRSTUVXYZÇÃÕÁÉÍÓÚÂÊÔÀ"
                nFat := 0.70
            Case cCh $ "cksvxyz"
                nFat := 0.50
            OtherWise
                nFat := 0.556
        EndCase
        nW += nFat
    Next nI

    If lNeg != Nil .And. lNeg
        nW *= 1.07
    EndIf
Return nW * nFonte

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfData
Data para impressão no espelho; vazia quando não informada.

@param   dData Data a imprimir
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  cData Data no formato dd/mm/aaaa, ou vazio
/*/
//-------------------------------------------------------------------
Static Function PdfData(dData)
    Local cData := ""

    If !Empty(dData)
        cData := DtoC(dData)
    EndIf

Return cData
/*/{Protheus.doc} MontaTela
Tela de inclusão, alteração e consulta da solicitação de devolução.

@param   nModo 1 = inclusão, 2 = alteração, 3 = consulta
@param   nRec  R_E_C_N_O_ da solicitação (0 na inclusão)
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function MontaTela(nModo, nRec)
    Local aArea    := GetArea()
    Local lNovo    := (nModo == 1)
    Local lSoLe    := (nModo == 3)
    Local cTitulo  := ""
    Local oDlg
    Local oGrp1
    Local oGrp2
    Local oGrp3
    Local oGetNum
    Local oGetDtSol
    Local oGetSt
    Local oGetForn
    Local oGetLoja
    Local oGetNom
    Local oGetCgc
    Local oGetArm
    Local oGetVol
    Local oGetFrete
    Local oGetOper
    Local oGetDesc
    Local oGetDtEmi
    Local oGetHr
    Local oGetMot
    Local oGetCpf
    Local oGetPlaca
    Local oGetMod
    Local oGetObs
    Local oGetTot
    Local oGrid
    Local oBtnGrava
    Local oBtnCanc
    Local oBtnAdd
    Local oBtnAlt
    Local oBtnDel
    Local oBtnPdf

    Private cNumSol  := Space(6)
    Private cNumVis  := ""   // numero exibido na tela (sem zeros a esquerda)
    Private dDataSol := Date()
    Private cFornec  := Space(6)
    Private cLoja    := Space(2)
    Private cNomFor  := Space(100)
    Private cCgc     := Space(18)
    Private cArmaz   := Space(30)
    Private nVolume  := 0
    Private cTpFrete := Space(40)
    Private cTpOper  := Space(60)
    Private cDescOp  := Space(200)
    Private dDtEmis  := Date()
    Private cHrEmis  := Space(5)
    Private cMotor   := Space(80)
    Private cCpf     := Space(14)
    Private cPlaca   := Space(8)
    Private cModelo  := Space(30)
    Private cObs     := Space(500)
    Private nTotal   := 0
    Private cStatus  := "1"
    Private cStDesc  := ""
    Private aItens   := {}
    Private nItemSel := 0

    If lNovo
        cTitulo  := "Solicitação de Nota Fiscal- Inclusão"
        cNumSol  := AllTrim(Str(ProxNumero(), 6))
        cNumVis  := cNumSol
        dDataSol := Date()
        dDtEmis  := Date()
        cStDesc  := DescStatus(cStatus)
    Else
        If !CarregaCabecalho(nRec)
            MsgAlert("Solicitação não encontrada.", "Erro")
            RestArea(aArea)
            Return Nil
        EndIf

        If lSoLe
            cTitulo := "Solicitação de Nota Fiscal - Consulta"
        Else
            cTitulo := "Solicitação de Nota Fiscal - Alteração"
        EndIf

        cNumVis := NumeroVisivel(cNumSol)
        CarregaItens(cNumSol)
    EndIf

    DEFINE MSDIALOG oDlg TITLE cTitulo FROM 000,000 TO 900,1250 PIXEL

    @ 005,005 GROUP oGrp1 TO 200,612 PROMPT "Dados da Solicitação" OF oDlg PIXEL

    @ 018,012 SAY "Número" SIZE 45,007 OF oDlg PIXEL
    @ 016,058 MSGET oGetNum VAR cNumVis SIZE 55,010 OF oDlg PIXEL WHEN .F.

    @ 018,125 SAY "Data da Solicitação" SIZE 85,007 OF oDlg PIXEL
    @ 016,215 MSGET oGetDtSol VAR dDataSol SIZE 70,010 OF oDlg PIXEL PICTURE "@D" ;
        WHEN !lSoLe

    @ 018,300 SAY "Situação" SIZE 40,007 OF oDlg PIXEL
    @ 016,345 MSGET oGetSt VAR cStDesc SIZE 80,010 OF oDlg PIXEL WHEN .F.

    @ 035,012 SAY "Fornecedor" SIZE 45,007 OF oDlg PIXEL
    @ 033,058 MSGET oGetForn VAR cFornec SIZE 55,010 OF oDlg PIXEL ;
        VALID FBuscaForn(oGetNom, oGetCgc) F3 "SA2" WHEN !lSoLe
    @ 033,118 MSGET oGetLoja VAR cLoja SIZE 28,010 OF oDlg PIXEL ;
        VALID FBuscaForn(oGetNom, oGetCgc) WHEN !lSoLe

    @ 035,155 SAY "Razão Social" SIZE 55,007 OF oDlg PIXEL
    @ 033,212 MSGET oGetNom VAR cNomFor SIZE 195,010 OF oDlg PIXEL WHEN .F.

    @ 035,415 SAY "CNPJ" SIZE 30,007 OF oDlg PIXEL
    @ 033,448 MSGET oGetCgc VAR cCgc SIZE 100,010 OF oDlg PIXEL WHEN .F.

    @ 052,012 SAY "Armazenagem" SIZE 65,007 OF oDlg PIXEL
    @ 050,080 MSGET oGetArm VAR cArmaz SIZE 100,010 OF oDlg PIXEL WHEN !lSoLe

    @ 052,190 SAY "Volume" SIZE 40,007 OF oDlg PIXEL
    @ 050,232 MSGET oGetVol VAR nVolume SIZE 45,010 OF oDlg PIXEL ;
        PICTURE "@E 999" WHEN !lSoLe

    @ 052,288 SAY "Tipo de Frete" SIZE 60,007 OF oDlg PIXEL
    @ 050,350 MSGET oGetFrete VAR cTpFrete SIZE 250,010 OF oDlg PIXEL WHEN !lSoLe

    @ 069,012 SAY "Tipo de Operação" SIZE 80,007 OF oDlg PIXEL
    @ 067,095 MSGET oGetOper VAR cTpOper SIZE 230,010 OF oDlg PIXEL WHEN !lSoLe

    @ 069,335 SAY "Descrição da Operação" SIZE 100,007 OF oDlg PIXEL
    @ 067,438 MSGET oGetDesc VAR cDescOp SIZE 162,010 OF oDlg PIXEL WHEN !lSoLe

    @ 086,012 SAY "Data de Emissão da NF" SIZE 100,007 OF oDlg PIXEL
    @ 084,115 MSGET oGetDtEmi VAR dDtEmis SIZE 70,010 OF oDlg PIXEL PICTURE "@D" ;
        WHEN !lSoLe

    @ 086,195 SAY "Horário Limite" SIZE 65,007 OF oDlg PIXEL
    @ 084,265 MSGET oGetHr VAR cHrEmis SIZE 45,010 OF oDlg PIXEL ;
        PICTURE "99:99" WHEN !lSoLe

    @ 103,012 SAY "Motorista" SIZE 45,007 OF oDlg PIXEL
    @ 101,060 MSGET oGetMot VAR cMotor SIZE 240,010 OF oDlg PIXEL WHEN !lSoLe

    @ 103,310 SAY "CPF" SIZE 25,007 OF oDlg PIXEL
    @ 101,340 MSGET oGetCpf VAR cCpf SIZE 90,010 OF oDlg PIXEL WHEN !lSoLe

    @ 103,440 SAY "Placa" SIZE 30,007 OF oDlg PIXEL
    @ 101,472 MSGET oGetPlaca VAR cPlaca SIZE 60,010 OF oDlg PIXEL WHEN !lSoLe

    @ 120,012 SAY "Modelo" SIZE 45,007 OF oDlg PIXEL
    @ 118,060 MSGET oGetMod VAR cModelo SIZE 160,010 OF oDlg PIXEL WHEN !lSoLe

    @ 140,012 SAY "Observações" SIZE 60,007 OF oDlg PIXEL
    @ 152,012 GET oGetObs VAR cObs WHEN !lSoLe SIZE 585,040 OF oDlg PIXEL MULTILINE

    @ 208,005 GROUP oGrp2 TO 352,612 PROMPT "Produtos da Devolução" OF oDlg PIXEL

    oGrid := TCBrowse():New( 230 , 012, 590, 92,,;
        {"Item","Código","Descrição","Qtde","Valor Unit.","Total"},{35,90,230,45,75,75},;
        oDlg,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )

    oGrid:SetArray(aItens)
    oGrid:bLine      := {|| LinhaItem(aItens, oGrid:nAt) }
    oGrid:bChange    := {|| nItemSel := oGrid:nAt }
    oGrid:bLDblClick := {|| AlteraItem(nModo, aItens, oGrid, oGetTot) }

    // Sem posicionar o cursor a grade pinta linhas em branco: o bloco bLine
    // recebe nAt = 0 e LinhaItem devolve as seis colunas vazias.
    If Len(aItens) > 0
        oGrid:nAt := 1
        nItemSel  := 1
    EndIf

    @ 328,012 BUTTON oBtnAdd PROMPT "Adicionar" SIZE 70,014 OF oDlg PIXEL ;
        ACTION AdicionaItem(nModo, aItens, oGrid, oGetTot)
    @ 328,090 BUTTON oBtnAlt PROMPT "Alterar" SIZE 70,014 OF oDlg PIXEL ;
        ACTION AlteraItem(nModo, aItens, oGrid, oGetTot)
    @ 328,168 BUTTON oBtnDel PROMPT "Remover" SIZE 70,014 OF oDlg PIXEL ;
        ACTION RemoveItem(nModo, aItens, oGrid, oGetTot)

    @ 340,420 SAY "Total (R$)" SIZE 55,007 OF oDlg PIXEL
    @ 338,480 MSGET oGetTot VAR nTotal SIZE 110,010 OF oDlg PIXEL ;
        PICTURE "@E 999,999,999.99" WHEN .F.

    @ 358,005 GROUP oGrp3 TO 412,612 PROMPT "Observações Importantes" OF oDlg PIXEL
    @ 370,012 SAY "A solicitação de emissão de Nota Fiscal deve ser feita com prazo de 24 horas de antecedência." ;
        SIZE 590,007 OF oDlg PIXEL
    @ 384,012 SAY "As notas fiscais somente serão emitidas com a apresentação deste modelo padrão." ;
        SIZE 590,007 OF oDlg PIXEL

    @ 420,220 BUTTON oBtnGrava PROMPT "Gravar" SIZE 70,016 OF oDlg PIXEL ;
        ACTION ConfirmaGravacao(nModo, oDlg) WHEN nModo <> 3
    @ 420,380 BUTTON oBtnPdf PROMPT "Imprimir PDF" SIZE 70,016 OF oDlg PIXEL ;
        ACTION PdfDaTela()
    @ 420,300 BUTTON oBtnCanc PROMPT "Fechar" SIZE 70,016 OF oDlg PIXEL ;
        ACTION oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED

    RestArea(aArea)
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} CarregaCabecalho
Carrega os dados da solicitação nas variáveis da tela.

@param   nRec R_E_C_N_O_ da solicitação
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  lOk .T. quando o registro foi encontrado
/*/
//-------------------------------------------------------------------
Static Function CarregaCabecalho(nRec)
    Local lOk    := .F.
    Local aArea  := GetArea()
    Local cAlias := GetNextAlias()
    Local cQuery := ""

    cQuery := "SELECT ZSN_NUM, ZSN_DTSOL, ZSN_FORNEC, ZSN_LOJA, ZSN_NOMFOR, ZSN_CGC, "
    cQuery += "ZSN_ARMAZ, ZSN_VOLUME, ZSN_TPFRETE, ZSN_TPOPER, ZSN_DESCOP, ZSN_DTEMIS, "
    // VARCHAR(MAX) não aparece no alias do TCQuery: o CAST expõe a coluna.
    cQuery += "ZSN_HREMIS, ZSN_MOTOR, ZSN_CPF, ZSN_PLACA, ZSN_MODELO, "
    cQuery += "CAST(ZSN_OBS AS VARCHAR(500)) AS ZSN_OBS, "
    cQuery += "ZSN_TOTAL, ZSN_STATUS "
    cQuery += "FROM " + NomeTabCab() + " "
    cQuery += "WHERE R_E_C_N_O_ = " + cValToChar(nRec) + " "
    cQuery += "AND ZSN_FILIAL = '" + xFilial("SA2") + "' "
    cQuery += "AND D_E_L_E_T_ = ' '"

    TcQuery cQuery New Alias (cAlias)

    If !(cAlias)->(Eof())
        cNumSol  := PadR((cAlias)->ZSN_NUM, 6)
        dDataSol := STOD((cAlias)->ZSN_DTSOL)
        cFornec  := PadR((cAlias)->ZSN_FORNEC, 6)
        cLoja    := PadR((cAlias)->ZSN_LOJA, 2)
        cNomFor  := PadR((cAlias)->ZSN_NOMFOR, 100)
        cCgc     := PadR(FormataCGC((cAlias)->ZSN_CGC), 18)
        cArmaz   := PadR((cAlias)->ZSN_ARMAZ, 30)
        nVolume  := (cAlias)->ZSN_VOLUME
        cTpFrete := PadR((cAlias)->ZSN_TPFRETE, 40)
        cTpOper  := PadR((cAlias)->ZSN_TPOPER, 60)
        cDescOp  := PadR((cAlias)->ZSN_DESCOP, 200)
        dDtEmis  := STOD((cAlias)->ZSN_DTEMIS)
        cHrEmis  := PadR((cAlias)->ZSN_HREMIS, 5)
        cMotor   := PadR((cAlias)->ZSN_MOTOR, 80)
        cCpf     := PadR((cAlias)->ZSN_CPF, 14)
        cPlaca   := PadR((cAlias)->ZSN_PLACA, 8)
        cModelo  := PadR((cAlias)->ZSN_MODELO, 30)
        cObs     := PadR((cAlias)->ZSN_OBS, 500)
        nTotal   := (cAlias)->ZSN_TOTAL
        cStatus  := (cAlias)->ZSN_STATUS
        cStDesc  := DescStatus(cStatus)
        lOk      := .T.
    EndIf

    (cAlias)->(DbCloseArea())
    RestArea(aArea)
Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} CarregaItens
Carrega os produtos da solicitação no vetor da grade.

@param   cNumero Número da solicitação
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function CarregaItens(cNumero)
    Local aArea  := GetArea()
    Local cAlias := GetNextAlias()
    Local cQuery := ""

    aItens := {}

    cQuery := "SELECT ZSI_ITEM, ZSI_PROD, ZSI_DESC, ZSI_QTDE, ZSI_VLRUNI, ZSI_VLRTOT "
    cQuery += "FROM " + NomeTabItm() + " "
    cQuery += "WHERE ZSI_FILIAL = '" + xFilial("SA2") + "' "
    cQuery += "AND ZSI_NUM = '" + EscapaSql(cNumero) + "' "
    cQuery += "AND D_E_L_E_T_ = ' ' "
    cQuery += "ORDER BY ZSI_ITEM"

    TcQuery cQuery New Alias (cAlias)

    (cAlias)->(DbGoTop())
    While !(cAlias)->(Eof())
        aAdd(aItens, { Val((cAlias)->ZSI_ITEM),;
                       (cAlias)->ZSI_PROD,;
                       (cAlias)->ZSI_DESC,;
                       (cAlias)->ZSI_QTDE,;
                       (cAlias)->ZSI_VLRUNI,;
                       (cAlias)->ZSI_VLRTOT })
        (cAlias)->(DbSkip())
    EndDo

    (cAlias)->(DbCloseArea())

    nTotal := SomaItens(aItens)
    RestArea(aArea)
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} LinhaItem
Monta a linha exibida na grade de produtos.

@param   aItens Vetor de produtos
@param   nAt    Posição corrente da grade
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  aLinha Linha pronta para exibição
/*/
//-------------------------------------------------------------------
Static Function LinhaItem(aItens, nAt)
    Local aLinha := {"", "", "", "", "", ""}

    If nAt >= 1 .And. nAt <= Len(aItens)
        aLinha := { StrZero(aItens[nAt][1], 3),;
                    AllTrim(aItens[nAt][2]),;
                    AllTrim(aItens[nAt][3]),;
                    Transform(aItens[nAt][4], "@E 999,999.99"),;
                    Transform(aItens[nAt][5], "@E 999,999,999.99"),;
                    Transform(aItens[nAt][6], "@E 999,999,999.99") }
    EndIf

Return aLinha

//-------------------------------------------------------------------
/*/{Protheus.doc} SomaItens
Soma o total dos produtos informados.

@param   aItens Vetor de produtos
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nTotal Valor total da solicitação
/*/
//-------------------------------------------------------------------
Static Function SomaItens(aItens)
    Local nSoma := 0
    Local nI    := 0

    For nI := 1 To Len(aItens)
        nSoma += aItens[nI][6]
    Next nI

Return nSoma

//-------------------------------------------------------------------
/*/{Protheus.doc} RenumeraItens
Renumera os itens da grade na ordem em que aparecem.

@param   aItens Vetor de produtos
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function RenumeraItens(aItens)
    Local nI := 0

    For nI := 1 To Len(aItens)
        aItens[nI][1] := nI
    Next nI

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} AtualizaGrade
Redesenha a grade de produtos e o total a partir do vetor de itens.

A grade foi criada com o vetor vazio, então o cursor é posicionado
logo depois do SetArray: sem posicionamento o bloco bLine é chamado
com nAt = 0 e a linha é pintada em branco.

@param   aItens  Vetor de produtos
@param   oGrid   Grade de produtos
@param   oGetTot Campo do total
@param   nAt     Linha que deve ficar selecionada
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function AtualizaGrade(aItens, oGrid, oGetTot, nAt)
    Local nQtd := Len(aItens)

    If nQtd > 0
        If nAt < 1 .Or. nAt > nQtd
            nAt := 1
        EndIf
    Else
        nAt := 0
    EndIf

    nItemSel := nAt
    nTotal   := SomaItens(aItens)

    oGrid:SetArray(aItens)
    oGrid:bLine := {|| LinhaItem(aItens, oGrid:nAt) }

    If nQtd > 0
        oGrid:nAt := nAt
    EndIf

    oGrid:Refresh()

    oGetTot:Refresh()
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} AdicionaItem
Inclui um produto na grade da solicitação.

@param   nModo    Modo da tela (1, 2 ou 3)
@param   aItens   Vetor de produtos
@param   oGrid    Grade de produtos
@param   oGetTot  Campo do total
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function AdicionaItem(nModo, aItens, oGrid, oGetTot)
    Local aNovo := {}

    If nModo == 3
        MsgAlert("Consulta não permite incluir produtos.", "Atenção")
        Return Nil
    EndIf

    aNovo := EditaItem(0, aItens)

    If Len(aNovo) > 0
        aAdd(aItens, { Len(aItens) + 1, aNovo[1], aNovo[2], aNovo[3], aNovo[4], aNovo[5] })
        RenumeraItens(aItens)
        AtualizaGrade(aItens, oGrid, oGetTot, Len(aItens))
    EndIf
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} AlteraItem
Altera o produto selecionado na grade.

@param   nModo    Modo da tela (1, 2 ou 3)
@param   aItens   Vetor de produtos
@param   oGrid    Grade de produtos
@param   oGetTot  Campo do total
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function AlteraItem(nModo, aItens, oGrid, oGetTot)
    Local aAlt := {}
    Local nAt  := 0

    If nModo == 3
        MsgAlert("Consulta não permite alterar produtos.", "Atenção")
        Return Nil
    EndIf

    If Len(aItens) == 0
        MsgAlert("Nenhum produto informado.", "Atenção")
        Return Nil
    EndIf

    nAt := nItemSel

    If nAt < 1 .Or. nAt > Len(aItens)
        MsgAlert("Selecione um produto na grade.", "Atenção")
        Return Nil
    EndIf

    aAlt := EditaItem(nAt, aItens)

    If Len(aAlt) > 0
        aItens[nAt][2] := aAlt[1]
        aItens[nAt][3] := aAlt[2]
        aItens[nAt][4] := aAlt[3]
        aItens[nAt][5] := aAlt[4]
        aItens[nAt][6] := aAlt[5]
        AtualizaGrade(aItens, oGrid, oGetTot, nAt)
    EndIf
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} RemoveItem
Remove o produto selecionado na grade.

@param   nModo    Modo da tela (1, 2 ou 3)
@param   aItens   Vetor de produtos
@param   oGrid    Grade de produtos
@param   oGetTot  Campo do total
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function RemoveItem(nModo, aItens, oGrid, oGetTot)
    Local nAt := 0

    If nModo == 3
        MsgAlert("Consulta não permite remover produtos.", "Atenção")
        Return Nil
    EndIf

    If Len(aItens) == 0
        MsgAlert("Nenhum produto informado.", "Atenção")
        Return Nil
    EndIf

    nAt := nItemSel

    If nAt < 1 .Or. nAt > Len(aItens)
        MsgAlert("Selecione um produto na grade.", "Atenção")
        Return Nil
    EndIf

    If !MsgYesNo("Confirma a remoção do produto " + AllTrim(aItens[nAt][2]) + "?", "Atenção")
        Return Nil
    EndIf

    aDel(aItens, nAt)
    aSize(aItens, Len(aItens) - 1)
    RenumeraItens(aItens)
    AtualizaGrade(aItens, oGrid, oGetTot, nAt)
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} EditaItem
Janela de inclusão e alteração de um produto da solicitação.

@param   nPos   Posição do produto na grade (0 na inclusão)
@param   aItens Vetor de produtos
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  aItem Dados do produto informado, ou vetor vazio quando cancelado
/*/
//-------------------------------------------------------------------
Static Function EditaItem(nPos, aItens)
    Local aArea    := GetArea()
    Local lNovo    := (nPos < 1 .Or. nPos > Len(aItens))
    Local cTitulo  := "Incluir Produto"
    Local oDlgIt
    Local oGetCod
    Local oGetDes
    Local oGetQtd
    Local oGetVlr
    Local oGetTot
    Local oBtnOk
    Local oBtnCanc

    Private cItProd  := Space(15)
    Private cItDesc  := Space(200)
    Private nItQtde  := 1
    Private nItVlrUn := 0
    Private nItVlrTt := 0
    Private lItOk    := .F.
    Private aItRet   := {}
    // .T. somente quando o sistema não devolve valor unitário para o produto.
    Private lVlrMan  := .F.

    If !lNovo
        cTitulo  := "Alterar Produto"
        cItProd  := PadR(aItens[nPos][2], 15)
        cItDesc  := PadR(aItens[nPos][3], 200)
        nItQtde  := aItens[nPos][4]
        nItVlrUn := aItens[nPos][5]
        nItVlrTt := aItens[nPos][6]
        lVlrMan  := (PrecoSistema(aItens[nPos][2], cFornec, cLoja) == 0)
    EndIf

    DEFINE MSDIALOG oDlgIt TITLE cTitulo FROM 000,000 TO 300,1050 PIXEL

    @ 015,010 SAY "Código do Produto" SIZE 80,007 OF oDlgIt PIXEL
    @ 013,095 MSGET oGetCod VAR cItProd SIZE 100,010 OF oDlgIt PIXEL ;
        VALID FBuscaProd(oGetCod, oGetDes, oGetVlr, oGetTot) F3 "SB1"

    @ 035,010 SAY "Descrição" SIZE 50,007 OF oDlgIt PIXEL
    @ 033,095 MSGET oGetDes VAR cItDesc SIZE 420,010 OF oDlgIt PIXEL WHEN .F.

    @ 055,010 SAY "Quantidade" SIZE 55,007 OF oDlgIt PIXEL
    @ 053,095 MSGET oGetQtd VAR nItQtde SIZE 80,010 OF oDlgIt PIXEL ;
        PICTURE "@E 999,999.99" VALID CalculaItem(oGetTot)

    @ 075,010 SAY "Valor Unitário (R$)" SIZE 90,007 OF oDlgIt PIXEL
    @ 073,095 MSGET oGetVlr VAR nItVlrUn SIZE 100,010 OF oDlgIt PIXEL ;
        PICTURE "@E 999,999,999.99" VALID CalculaItem(oGetTot) WHEN lVlrMan

    @ 095,010 SAY "Total do Produto (R$)" SIZE 100,007 OF oDlgIt PIXEL
    @ 093,095 MSGET oGetTot VAR nItVlrTt SIZE 100,010 OF oDlgIt PIXEL ;
        PICTURE "@E 999,999,999.99" WHEN .F.

    @ 125,300 BUTTON oBtnOk PROMPT "Confirmar" SIZE 70,016 OF oDlgIt PIXEL ;
        ACTION ConfirmaItem(oDlgIt)
    @ 125,380 BUTTON oBtnCanc PROMPT "Cancelar" SIZE 70,016 OF oDlgIt PIXEL ;
        ACTION oDlgIt:End()

    ACTIVATE MSDIALOG oDlgIt CENTERED

    If lItOk
        aItRet := { AllTrim(cItProd), AllTrim(cItDesc), nItQtde, nItVlrUn, nItVlrTt }
    EndIf

    RestArea(aArea)
Return aItRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CalculaItem
Recalcula o total do produto na janela de item.

@param   oGetTot Campo do total do produto
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  lOk Sempre .T.
/*/
//-------------------------------------------------------------------
Static Function CalculaItem(oGetTot)
    nItVlrTt := nItQtde * nItVlrUn
    oGetTot:Refresh()
Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} ConfirmaItem
Valida e confirma os dados do produto na janela de item.

@param   oDlgIt Janela do item
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function ConfirmaItem(oDlgIt)
    If Empty(AllTrim(cItProd))
        MsgAlert("Informe o código do produto.", "Atenção")
        Return Nil
    EndIf

    If nItQtde <= 0
        MsgAlert("Informe a quantidade do produto.", "Atenção")
        Return Nil
    EndIf

    If nItVlrUn < 0
        MsgAlert("O valor unitário não pode ser negativo.", "Atenção")
        Return Nil
    EndIf

    nItVlrTt := nItQtde * nItVlrUn
    lItOk    := .T.
    oDlgIt:End()
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} FBuscaProd
Busca o produto no cadastro, preenche a descrição e o valor unitário.

@param   oGetCod  Campo do código do produto
@param   oGetDesc Campo da descrição
@param   oGetVlr  Campo do valor unitário
@param   oGetTot  Campo do total do produto
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  lOk .T. quando o produto existe
/*/
//-------------------------------------------------------------------
Static Function FBuscaProd(oGetCod, oGetDesc, oGetVlr, oGetTot)
    Local lOk    := .T.
    Local aArea  := GetArea()
    Local cAlias := GetNextAlias()
    Local cQuery := ""

    cItDesc  := Space(200)
    nItVlrUn := 0
    nItVlrTt := 0
    lVlrMan  := .F.

    If Empty(AllTrim(cItProd))
        oGetCod:Refresh()
        oGetDesc:Refresh()
        oGetVlr:lActive := lVlrMan
        oGetVlr:Refresh()
        oGetTot:Refresh()
        RestArea(aArea)
        Return .T.
    EndIf

    cQuery := "SELECT B1_COD, B1_DESC FROM " + RetSqlName("SB1") + " "
    cQuery += "WHERE D_E_L_E_T_ = ' ' "
    cQuery += "AND B1_FILIAL = '" + xFilial("SB1") + "' "
    cQuery += "AND B1_MSBLQL <> '1' "
    cQuery += "AND B1_COD = '" + EscapaSql(AllTrim(cItProd)) + "'"

    TcQuery cQuery New Alias (cAlias)

    If (cAlias)->(Eof())
        MsgAlert("Produto não cadastrado ou bloqueado.", "Atenção")
        lOk := .F.
    Else
        cItProd  := (cAlias)->B1_COD
        cItDesc  := PadR((cAlias)->B1_DESC, 200)
        nItVlrUn := PrecoSistema(cItProd, cFornec, cLoja)
        lVlrMan  := (nItVlrUn == 0)
        nItVlrTt := nItQtde * nItVlrUn
    EndIf

    (cAlias)->(DbCloseArea())
    oGetCod:Refresh()
    oGetDesc:Refresh()
    oGetVlr:lActive := lVlrMan
    oGetVlr:Refresh()
    oGetTot:Refresh()
    RestArea(aArea)
Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} PrecoCadastro
Último preço de compra gravado no cadastro do produto (B1_UPRC).

Segunda fonte do valor unitário, usada quando o item nunca foi comprado.

@param   cProd Código do produto
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nPreco Último preço de compra do cadastro, ou zero quando não existe
/*/
//-------------------------------------------------------------------
Static Function PrecoCadastro(cProd)
    Local nPreco := 0
    Local aArea  := GetArea()
    Local cAlias := GetNextAlias()
    Local cQuery := ""

    If !Empty(AllTrim(cProd))
        cQuery := "SELECT B1_UPRC FROM " + RetSqlName("SB1") + " "
        cQuery += "WHERE D_E_L_E_T_ = ' ' "
        cQuery += "AND B1_FILIAL = '" + xFilial("SB1") + "' "
        cQuery += "AND B1_COD = '" + EscapaSql(AllTrim(cProd)) + "'"

        TcQuery cQuery New Alias (cAlias)

        If !(cAlias)->(Eof())
            nPreco := (cAlias)->B1_UPRC
        EndIf

        (cAlias)->(DbCloseArea())
    EndIf

    RestArea(aArea)
Return nPreco

//-------------------------------------------------------------------
/*/{Protheus.doc} PrecoSistema
Valor unitário do produto buscado no sistema ao incluir o item.

Ordem de busca: valor unitário da última compra do item nas notas fiscais
de entrada e, quando o item nunca foi comprado, o último preço de compra
gravado no cadastro do produto. Quando as duas fontes devolvem zero o campo
fica zerado e passa a aceitar digitação manual.

@param   cProd   Código do produto
@param   cFornec Código do fornecedor da solicitação
@param   cLoja   Loja do fornecedor da solicitação
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nPreco Valor unitário encontrado, ou zero quando não há compra
/*/
//-------------------------------------------------------------------
Static Function PrecoSistema(cProd, cFornec, cLoja)
    Local nPreco := 0

    nPreco := UltimaCompra(cProd, cFornec, cLoja)

    If nPreco == 0
        nPreco := PrecoCadastro(cProd)
    EndIf

Return nPreco

//-------------------------------------------------------------------
/*/{Protheus.doc} UltimaCompra
Valor unitário da última compra do produto nas notas fiscais de entrada.

A consulta prioriza a compra do fornecedor informado na solicitação e, quando
esse fornecedor não tem compra do item, devolve a última compra do item com
qualquer fornecedor. Só considera entrada com valor unitário maior que zero,
porque entrada zerada não serve como preço de devolução.

@param   cProd   Código do produto
@param   cFornec Código do fornecedor da solicitação
@param   cLoja   Loja do fornecedor da solicitação
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nPreco Valor unitário da última compra, ou zero quando não existe
/*/
//-------------------------------------------------------------------
Static Function UltimaCompra(cProd, cFornec, cLoja)
    Local nPreco := 0
    Local aArea  := GetArea()
    Local cAlias := GetNextAlias()
    Local cQuery := ""

    If !Empty(AllTrim(cProd))
        cQuery := "SELECT TOP 1 D1_VUNIT FROM " + RetSqlName("SD1") + " "
        cQuery += "WHERE D_E_L_E_T_ = ' ' "
        cQuery += "AND D1_FILIAL = '" + xFilial("SD1") + "' "
        cQuery += "AND D1_COD = '" + EscapaSql(AllTrim(cProd)) + "' "
        cQuery += "AND D1_TIPO = 'N' "
        cQuery += "AND D1_QUANT > 0 "
        cQuery += "AND D1_VUNIT > 0 "

        If !Empty(AllTrim(cFornec))
            cQuery += "ORDER BY CASE WHEN D1_FORNECE = '" + EscapaSql(AllTrim(cFornec)) + "' "
            cQuery += "AND D1_LOJA = '" + EscapaSql(AllTrim(cLoja)) + "' THEN 0 ELSE 1 END, "
            cQuery += "D1_DTDIGIT DESC"
        Else
            cQuery += "ORDER BY D1_DTDIGIT DESC"
        EndIf

        TcQuery cQuery New Alias (cAlias)

        If !(cAlias)->(Eof())
            nPreco := (cAlias)->D1_VUNIT
        EndIf

        (cAlias)->(DbCloseArea())
    EndIf

    RestArea(aArea)
Return nPreco

//-------------------------------------------------------------------
/*/{Protheus.doc} FBuscaForn
Busca o fornecedor no cadastro e preenche razão social e CNPJ.

@param   oGetNom Campo da razão social
@param   oGetCgc Campo do CNPJ
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  lOk .T. quando o fornecedor existe
/*/
//-------------------------------------------------------------------
Static Function FBuscaForn(oGetNom, oGetCgc)
    Local lOk    := .T.
    Local aArea  := GetArea()
    Local cAlias := GetNextAlias()
    Local cQuery := ""

    If Empty(AllTrim(cFornec))
        cNomFor := Space(100)
        cCgc    := Space(18)
        oGetNom:Refresh()
        oGetCgc:Refresh()
        RestArea(aArea)
        Return .T.
    EndIf

    If Empty(AllTrim(cLoja))
        cLoja := "01"
    EndIf

    cQuery := "SELECT A2_COD, A2_LOJA, A2_NOME, A2_CGC FROM " + RetSqlName("SA2") + " "
    cQuery += "WHERE D_E_L_E_T_ = ' ' "
    cQuery += "AND A2_FILIAL = '" + xFilial("SA2") + "' "
    cQuery += "AND A2_COD = '" + EscapaSql(AllTrim(cFornec)) + "' "
    cQuery += "AND A2_LOJA = '" + EscapaSql(AllTrim(cLoja)) + "'"

    TcQuery cQuery New Alias (cAlias)

    If (cAlias)->(Eof())
        MsgAlert("Fornecedor não cadastrado nesta loja.", "Atenção")
        cNomFor := Space(100)
        cCgc    := Space(18)
        lOk     := .F.
    Else
        cFornec := (cAlias)->A2_COD
        cLoja   := (cAlias)->A2_LOJA
        cNomFor := (cAlias)->A2_NOME
        cCgc    := FormataCGC((cAlias)->A2_CGC)
    EndIf

    (cAlias)->(DbCloseArea())
    oGetNom:Refresh()
    oGetCgc:Refresh()
    RestArea(aArea)
Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} ConfirmaGravacao
Valida os dados da tela e grava a solicitação.

@param   nModo Modo da tela (1 = inclusão, 2 = alteração)
@param   oDlg  Janela da solicitação
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  Nil
/*/
//-------------------------------------------------------------------
Static Function ConfirmaGravacao(nModo, oDlg)
    Local lOk  := .T.
    Local cNum := ""

    If Empty(AllTrim(cFornec))
        MsgAlert("Informe o código do fornecedor.", "Atenção")
        lOk := .F.
    ElseIf Empty(AllTrim(cLoja))
        MsgAlert("Informe a loja do fornecedor.", "Atenção")
        lOk := .F.
    ElseIf Empty(dDataSol)
        MsgAlert("Informe a data da solicitação.", "Atenção")
        lOk := .F.
    ElseIf Empty(dDtEmis)
        MsgAlert("Informe a data de emissão da Nota Fiscal.", "Atenção")
        lOk := .F.
    ElseIf dDtEmis < dDataSol
        MsgAlert("A data de emissão não pode ser anterior à data da solicitação.", "Atenção")
        lOk := .F.
    ElseIf !ValidaHora(cHrEmis)
        MsgAlert("Informe o horário limite no formato HH:MM.", "Atenção")
        lOk := .F.
    ElseIf !Empty(AllTrim(cCpf)) .And. !ValidaCPF(cCpf)
        MsgAlert("O CPF do motorista é inválido.", "Atenção")
        lOk := .F.
    ElseIf Len(aItens) == 0
        MsgAlert("Informe pelo menos um produto na devolução.", "Atenção")
        lOk := .F.
    EndIf

    If !lOk
        Return Nil
    EndIf

    If nModo == 1
        cNum := AllTrim(Str(ProxNumero(), 6))
    Else
        cNum := AllTrim(cNumSol)
    EndIf

    nTotal := SomaItens(aItens)

    If GravaSol(nModo, cNum, aItens)
        MsgInfo("Solicitação " + cNum + " gravada com sucesso.", "Concluído")

        oDlg:End()

        If nModo == 1
            If Empty(EmailEmissorNF())
                MsgAlert("Solicitação gravada. O aviso por e-mail ainda não está configurado:" + CRLF + ;
                         "informe o e-mail de quem emite a Nota Fiscal.", "Atenção")
            ElseIf !EnviaAvisoNF(cNum, aItens)
                MsgAlert("Solicitação gravada, mas o aviso por e-mail não pôde ser enviado." + CRLF + ;
                         "Verifique a conta de e-mail do Protheus (E-mail/Proxy no Configurador).", "Atenção")
            EndIf
        EndIf
    Else
        MsgAlert("Não foi possível gravar a solicitação." + CRLF + TcSqlError(), "Erro")
    EndIf
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} GravaSol
Grava o cabeçalho e os produtos da solicitação em uma única transação.

@param   nModo  Modo da tela (1 = inclusão, 2 = alteração)
@param   cNum   Número da solicitação
@param   aItens Vetor de produtos
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  lOk .T. quando a gravação foi confirmada
/*/
//-------------------------------------------------------------------
Static Function GravaSol(nModo, cNum, aItens)
    Local lOk    := .T.
    Local cQuery := ""
    Local cFil   := xFilial("SA2")
    Local nI     := 0

    BEGIN TRANSACTION

    If nModo == 1
        cQuery := "INSERT INTO " + NomeTabCab() + " ("
        cQuery += "ZSN_FILIAL, ZSN_NUM, ZSN_DTSOL, ZSN_FORNEC, ZSN_LOJA, ZSN_NOMFOR, ZSN_CGC, "
        cQuery += "ZSN_ARMAZ, ZSN_VOLUME, ZSN_TPFRETE, ZSN_TPOPER, ZSN_DESCOP, ZSN_DTEMIS, "
        cQuery += "ZSN_HREMIS, ZSN_MOTOR, ZSN_CPF, ZSN_PLACA, ZSN_MODELO, ZSN_OBS, ZSN_TOTAL, "
        cQuery += "ZSN_STATUS, ZSN_USER, ZSN_HORA, D_E_L_E_T_"
        cQuery += ") VALUES ("
        cQuery += "'" + EscapaSql(cFil) + "', "
        cQuery += "'" + EscapaSql(cNum) + "', "
        cQuery += "'" + DtoS(dDataSol) + "', "
        cQuery += "'" + EscapaSql(cFornec) + "', "
        cQuery += "'" + EscapaSql(cLoja) + "', "
        cQuery += "'" + EscapaSql(cNomFor) + "', "
        cQuery += "'" + EscapaSql(SoNumeros(cCgc)) + "', "
        cQuery += "'" + EscapaSql(cArmaz) + "', "
        cQuery += NumSql(nVolume) + ", "
        cQuery += "'" + EscapaSql(cTpFrete) + "', "
        cQuery += "'" + EscapaSql(cTpOper) + "', "
        cQuery += "'" + EscapaSql(cDescOp) + "', "
        cQuery += "'" + DtoS(dDtEmis) + "', "
        cQuery += "'" + EscapaSql(cHrEmis) + "', "
        cQuery += "'" + EscapaSql(cMotor) + "', "
        cQuery += "'" + EscapaSql(cCpf) + "', "
        cQuery += "'" + EscapaSql(cPlaca) + "', "
        cQuery += "'" + EscapaSql(cModelo) + "', "
        cQuery += "'" + EscapaSql(cObs) + "', "
        cQuery += NumSql(SomaItens(aItens)) + ", "
        cQuery += "'" + EscapaSql(cStatus) + "', "
        cQuery += "'" + EscapaSql(UsrRetName(RetCodUsr())) + "', "
        cQuery += "'" + Time() + "', "
        cQuery += "' ')"
    Else
        cQuery := "UPDATE " + NomeTabCab() + " SET "
        cQuery += "ZSN_DTSOL = '" + DtoS(dDataSol) + "', "
        cQuery += "ZSN_FORNEC = '" + EscapaSql(cFornec) + "', "
        cQuery += "ZSN_LOJA = '" + EscapaSql(cLoja) + "', "
        cQuery += "ZSN_NOMFOR = '" + EscapaSql(cNomFor) + "', "
        cQuery += "ZSN_CGC = '" + EscapaSql(SoNumeros(cCgc)) + "', "
        cQuery += "ZSN_ARMAZ = '" + EscapaSql(cArmaz) + "', "
        cQuery += "ZSN_VOLUME = " + NumSql(nVolume) + ", "
        cQuery += "ZSN_TPFRETE = '" + EscapaSql(cTpFrete) + "', "
        cQuery += "ZSN_TPOPER = '" + EscapaSql(cTpOper) + "', "
        cQuery += "ZSN_DESCOP = '" + EscapaSql(cDescOp) + "', "
        cQuery += "ZSN_DTEMIS = '" + DtoS(dDtEmis) + "', "
        cQuery += "ZSN_HREMIS = '" + EscapaSql(cHrEmis) + "', "
        cQuery += "ZSN_MOTOR = '" + EscapaSql(cMotor) + "', "
        cQuery += "ZSN_CPF = '" + EscapaSql(cCpf) + "', "
        cQuery += "ZSN_PLACA = '" + EscapaSql(cPlaca) + "', "
        cQuery += "ZSN_MODELO = '" + EscapaSql(cModelo) + "', "
        cQuery += "ZSN_OBS = '" + EscapaSql(cObs) + "', "
        cQuery += "ZSN_TOTAL = " + NumSql(SomaItens(aItens)) + ", "
        cQuery += "ZSN_USER = '" + EscapaSql(UsrRetName(RetCodUsr())) + "', "
        cQuery += "ZSN_HORA = '" + Time() + "' "
        cQuery += "WHERE ZSN_FILIAL = '" + EscapaSql(cFil) + "' "
        cQuery += "AND ZSN_NUM = '" + EscapaSql(cNum) + "' "
        cQuery += "AND D_E_L_E_T_ = ' '"
    EndIf

    If TcSqlExec(cQuery) < 0
        DisarmTransaction()
        lOk := .F.
    EndIf

    If lOk .And. nModo == 2
        cQuery := "UPDATE " + NomeTabItm() + " SET D_E_L_E_T_ = '*' "
        cQuery += "WHERE ZSI_FILIAL = '" + EscapaSql(cFil) + "' "
        cQuery += "AND ZSI_NUM = '" + EscapaSql(cNum) + "'"
        If TcSqlExec(cQuery) < 0
            DisarmTransaction()
            lOk := .F.
        EndIf
    EndIf

    If lOk
        For nI := 1 To Len(aItens)
            cQuery := "INSERT INTO " + NomeTabItm() + " ("
            cQuery += "ZSI_FILIAL, ZSI_NUM, ZSI_ITEM, ZSI_PROD, ZSI_DESC, "
            cQuery += "ZSI_QTDE, ZSI_VLRUNI, ZSI_VLRTOT, D_E_L_E_T_"
            cQuery += ") VALUES ("
            cQuery += "'" + EscapaSql(cFil) + "', "
            cQuery += "'" + EscapaSql(cNum) + "', "
            cQuery += "'" + StrZero(aItens[nI][1], 3) + "', "
            cQuery += "'" + EscapaSql(aItens[nI][2]) + "', "
            cQuery += "'" + EscapaSql(aItens[nI][3]) + "', "
            cQuery += NumSql(aItens[nI][4]) + ", "
            cQuery += NumSql(aItens[nI][5]) + ", "
            cQuery += NumSql(aItens[nI][6]) + ", "
            cQuery += "' ')"

            If TcSqlExec(cQuery) < 0
                DisarmTransaction()
                lOk := .F.
                Exit
            EndIf
        Next nI
    EndIf

    END TRANSACTION
Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} EmailEmissorNF
E-mail de quem emite a Nota Fiscal e recebe o aviso de nova solicitacao.

@type    Static Function
@author  Vortice
@since   10/11/2026
@return  cEmail Endereco(s) de destino, separados por ponto e virgula
/*/
//-------------------------------------------------------------------
Static Function EmailEmissorNF()
    // Informe aqui o e-mail de quem emite a Nota Fiscal.
    // Para mais de um destinatario, separe por ponto e virgula.
Return "juan@vorticemineral.com"

//-------------------------------------------------------------------
/*/{Protheus.doc} MontaCorpoAvisoNF
Monta o texto do e-mail de aviso da nova solicitacao.

@param   cNumero Numero da solicitacao
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  cCorpo Texto do e-mail em HTML
/*/
//-------------------------------------------------------------------
Static Function MontaCorpoAvisoNF(cNumero)
    Local cCorpo := ""

    cCorpo := "<html><body>"
    cCorpo += "<p>Foi criada uma <strong>solicitação de Nota Fiscal</strong>.</p>"
    cCorpo += "<p><strong>Número da solicitação:</strong> " + NumeroVisivel(cNumero) + "<br>"
    cCorpo += "<strong>Solicitante:</strong> " + UsrRetName(RetCodUsr()) + "</p>"
    cCorpo += "<p><em>Esta é uma mensagem automática do Protheus.</em></p>"
    cCorpo += "</body></html>"

Return cCorpo

//-------------------------------------------------------------------
/*/{Protheus.doc} PdfParaEmail
Gera o espelho da solicitacao em PDF no servidor, para anexar ao e-mail.

@param   cNumero Numero da solicitacao ja gravada
@type    Static Function
@author  Vortice
@since   11/11/2026
@return  cArq Caminho do PDF no servidor, ou vazio se nao foi gerado
/*/
//-------------------------------------------------------------------
Static Function PdfParaEmail(cNumero)
    Local cArq   := ""
    Local cDir   := "\system\solnf\"
    Local aCab   := {}
    Local aItens := {}
    Local nRec   := 0
    Local aArea  := GetArea()
    Local cAlias := GetNextAlias()
    Local cQuery := ""

    If !ExistDir(cDir)
        MakeDir("\system")
        MakeDir(cDir)
    EndIf

    cQuery := "SELECT R_E_C_N_O_ AS NREC FROM " + NomeTabCab() + " "
    cQuery += "WHERE ZSN_FILIAL = '" + xFilial("SA2") + "' "
    cQuery += "AND ZSN_NUM = '" + EscapaSql(cNumero) + "' "
    cQuery += "AND D_E_L_E_T_ = ' '"
    TcQuery cQuery New Alias (cAlias)
    If !(cAlias)->(Eof())
        nRec := (cAlias)->NREC
    EndIf
    (cAlias)->(DbCloseArea())

    If nRec > 0 .And. CarregaPDF(nRec, @aCab)
        aItens := ItensPdf(aCab[1])
        cArq   := GeraPdf(aCab, aItens, cDir)
        If !File(cArq)
            cArq := ""
        EndIf
    EndIf

    RestArea(aArea)
Return cArq

//-------------------------------------------------------------------
/*/{Protheus.doc} EnviaAvisoNF
Envia por e-mail o aviso da nova solicitacao para quem emite a Nota Fiscal.
Usa a conta de e-mail configurada no Protheus (parametros MV_REL*).

@param   cNumero Numero da solicitacao gravada
@param   aItens  Vetor de produtos da solicitacao
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  lOk .T. quando o aviso foi enviado
/*/
//-------------------------------------------------------------------
Static Function EnviaAvisoNF(cNumero, aItens)
    Local aArea    := GetArea()
    Local lOk      := .T.
    Local lConect  := .F.
    Local cDestino := EmailEmissorNF()
    Local cConta   := ""
    Local cSmtp    := ""
    Local cSenha   := ""
    Local lAutent  := .F.
    Local nPorta   := 587
    Local nTimeOut := 60
    Local nRet     := 0
    Local oServer  := Nil
    Local oMessage := Nil
    Local cPdf     := ""

    If Empty(cDestino)
        RestArea(aArea)
        Return .F.
    EndIf

    cConta   := AllTrim(SuperGetMV("MV_RELACNT", .F., ""))
    cSmtp    := AllTrim(SuperGetMV("MV_RELSERV", .F., ""))
    cSenha   := AllTrim(SuperGetMV("MV_RELPSW", .F., ""))
    lAutent  := SuperGetMV("MV_RELAUTH", .F., .F.)
    nTimeOut := SuperGetMV("MV_RELTIME", .F., 60)

    If Empty(cSmtp) .Or. Empty(cConta)
        FWLogMsg("ERROR", , "SOLNF", FunName(), , "01", ;
                 "Conta de envio nao configurada (MV_RELACNT / MV_RELSERV)")
        RestArea(aArea)
        Return .F.
    EndIf

    // MV_RELSERV aceita "servidor:porta"; a porta padrao e 587
    If ":" $ cSmtp
        nPorta := Val(SubStr(cSmtp, At(":", cSmtp) + 1))
        cSmtp  := SubStr(cSmtp, 1, At(":", cSmtp) - 1)
    EndIf

    If nPorta <= 0
        nPorta := 587
    EndIf

    cPdf := PdfParaEmail(cNumero)

    BEGIN SEQUENCE
        oServer := TMailManager():New()
        oServer:SetUseTLS(.T.)
        oServer:SetSmtpTimeOut(nTimeOut)
        nRet := oServer:Init("", cSmtp, cConta, cSenha, 0, nPorta)

        If nRet == 0
            nRet := oServer:SmtpConnect()
            If nRet == 0
                lConect := .T.
            EndIf
        EndIf

        If nRet == 0 .And. lAutent
            nRet := oServer:SmtpAuth(cConta, cSenha)
        EndIf

        If nRet == 0
            oMessage := TMailMessage():New()
            oMessage:Clear()
            oMessage:cFrom    := cConta
            oMessage:cTo      := cDestino
            oMessage:cSubject := "Nova solicitação de NF - número " + NumeroVisivel(cNumero)
            oMessage:cBody    := MontaCorpoAvisoNF(cNumero)
            oMessage:MsgBodyType("text/html")
            If !Empty(cPdf)
                If oMessage:AttachFile(cPdf) < 0
                    FWLogMsg("ERROR", , "SOLNF", FunName(), , "03", "Falha ao anexar o PDF " + cPdf)
                EndIf
            EndIf
            nRet := oMessage:Send(oServer)
        EndIf
    RECOVER
        nRet := 1
    END SEQUENCE

    If nRet != 0
        lOk := .F.
        FWLogMsg("ERROR", , "SOLNF", FunName(), , "02", ;
                 "Falha ao enviar o aviso da solicitacao " + NumeroVisivel(cNumero) + " - codigo " + AllTrim(Str(nRet, 3)))
    EndIf

    If !Empty(cPdf) .And. File(cPdf)
        FErase(cPdf)
    EndIf

    If lConect .And. oServer != Nil
        BEGIN SEQUENCE
            oServer:SmtpDisconnect()
        RECOVER
        END SEQUENCE
    EndIf

    RestArea(aArea)
Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} ProxNumero
Menor número livre: reaproveita números de solicitações excluídas.

@type    Static Function
@author  Vortice
@since   10/11/2026
@return  nNumero Menor número livre
/*/
//-------------------------------------------------------------------
Static Function ProxNumero()
    Local nNumero := 1
    Local nUsado  := 0
    Local aArea   := GetArea()
    Local cAlias  := GetNextAlias()
    Local cQuery  := ""

    // Menor numero nao utilizado pelas solicitacoes ativas: se a solicitacao 2
    // for excluida, a proxima volta a ser a 2 (nao pula para a 3).
    cQuery := "SELECT CAST(ZSN_NUM AS INT) AS NUMUSADO "
    cQuery += "FROM " + NomeTabCab() + " "
    cQuery += "WHERE ZSN_FILIAL = '" + xFilial("SA2") + "' "
    cQuery += "AND D_E_L_E_T_ = ' ' "
    cQuery += "AND ISNUMERIC(ZSN_NUM) = 1 "
    cQuery += "ORDER BY 1"

    TcQuery cQuery New Alias (cAlias)

    (cAlias)->(DbGoTop())
    While !(cAlias)->(Eof())
        nUsado := (cAlias)->NUMUSADO
        If nUsado > nNumero
            Exit
        ElseIf nUsado == nNumero
            nNumero++
        EndIf
        (cAlias)->(DbSkip())
    EndDo

    (cAlias)->(DbCloseArea())
    RestArea(aArea)
Return nNumero

//-------------------------------------------------------------------
/*/{Protheus.doc} NumSql
Converte número em texto aceito pelo SQL Server (ponto decimal).

@param   nValor Número a converter
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  cNumero Número pronto para uso no comando SQL
/*/
//-------------------------------------------------------------------
Static Function NumSql(nValor)
Return AllTrim(Str(nValor, 18, 4))

//-------------------------------------------------------------------
/*/{Protheus.doc} EscapaSql
Duplica as aspas simples para uso seguro em comando SQL.

@param   cTexto Texto original
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  cTexto Texto com as aspas duplicadas
/*/
//-------------------------------------------------------------------
Static Function EscapaSql(cTexto)
    If cTexto == Nil
        Return ""
    EndIf
Return StrTran(cTexto, "'", "''")

//-------------------------------------------------------------------
/*/{Protheus.doc} SoNumeros
Remove tudo que não for dígito do texto informado.

@param   cTexto Texto original
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  cNumeros Somente os dígitos
/*/
//-------------------------------------------------------------------
Static Function SoNumeros(cTexto)
    Local cNumeros := ""
    Local cChar    := ""
    Local nI       := 0

    If cTexto == Nil
        Return ""
    EndIf

    For nI := 1 To Len(cTexto)
        cChar := SubStr(cTexto, nI, 1)
        If cChar $ "0123456789"
            cNumeros += cChar
        EndIf
    Next nI

Return cNumeros

//-------------------------------------------------------------------
/*/{Protheus.doc} FormataCGC
Formata o CNPJ no padrão 99.999.999/9999-99.

@param   cCgc CNPJ com ou sem formatação
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  cFormatado CNPJ formatado, ou o valor original quando inválido
/*/
//-------------------------------------------------------------------
Static Function FormataCGC(cCgc)
    Local cNumero    := SoNumeros(cCgc)
    Local cFormatado := ""

    If cCgc <> Nil
        cFormatado := AllTrim(cCgc)
    EndIf

    If Len(cNumero) == 14
        cFormatado := SubStr(cNumero, 1, 2) + "." + SubStr(cNumero, 3, 3) + "."
        cFormatado += SubStr(cNumero, 6, 3) + "/" + SubStr(cNumero, 9, 4) + "-"
        cFormatado += SubStr(cNumero, 13, 2)
    EndIf

Return cFormatado

//-------------------------------------------------------------------
/*/{Protheus.doc} ValidaHora
Valida o horário no formato HH:MM.

@param   cHora Horário informado
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  lOk .T. quando o horário é válido
/*/
//-------------------------------------------------------------------
Static Function ValidaHora(cHora)
    Local lOk := .F.
    Local cHr := ""

    If cHora == Nil
        Return .F.
    EndIf

    cHr := AllTrim(cHora)

    If Len(cHr) == 5 .And. SubStr(cHr, 3, 1) == ":" .And. ;
       Val(SubStr(cHr, 1, 2)) <= 23 .And. Val(SubStr(cHr, 4, 2)) <= 59
        lOk := .T.
    EndIf

Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} ValidaCPF
Valida o CPF pelos dígitos verificadores.

@param   cCpf CPF com ou sem formatação
@type    Static Function
@author  Vortice
@since   10/11/2026
@return  lOk .T. quando o CPF é válido
/*/
//-------------------------------------------------------------------
Static Function ValidaCPF(cCpf)
    Local lOk     := .F.
    Local cNumero := ""
    Local nSoma   := 0
    Local nResto  := 0
    Local nD1     := 0
    Local nD2     := 0
    Local nI      := 0

    cNumero := SoNumeros(cCpf)

    If Len(cNumero) != 11
        Return .F.
    EndIf

    If cNumero == Replicate(SubStr(cNumero, 1, 1), 11)
        Return .F.
    EndIf

    For nI := 1 To 9
        nSoma += Val(SubStr(cNumero, nI, 1)) * (11 - nI)
    Next nI

    nResto := (nSoma * 10) % 11
    If nResto == 10
        nResto := 0
    EndIf
    nD1 := nResto

    nSoma := 0
    For nI := 1 To 10
        nSoma += Val(SubStr(cNumero, nI, 1)) * (12 - nI)
    Next nI

    nResto := (nSoma * 10) % 11
    If nResto == 10
        nResto := 0
    EndIf
    nD2 := nResto

    If nD1 == Val(SubStr(cNumero, 10, 1)) .And. nD2 == Val(SubStr(cNumero, 11, 1))
        lOk := .T.
    EndIf

Return lOk


