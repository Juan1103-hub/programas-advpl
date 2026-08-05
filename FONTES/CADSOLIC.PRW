#Include "Protheus.ch"
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} CADSOLIC
Browse unificado de Solicitacoes Cadastrais - Produtos e Fornecedores.

Utiliza mBrowse padrao do Protheus sobre uma query TOPCONN UNION ALL
que combina os registros de SZ3 (Produtos) e SZ4 (Fornecedores).

O botao Incluir exibe seletor de tipo; Alterar, Visualizar e Excluir
roteiam para a tabela correta conforme o campo ZU_TIPO do alias.

Colunas do alias ZU_SOL:
  ZU_TIPO  - "P"=Produto  / "F"=Fornecedor
  ZU_ID    - ID da solicitacao
  ZU_USR   - Usuario solicitante
  ZU_PRAZO - "S"=Urgente / "" para fornecedor
  ZU_DESC  - Descricao (produto) ou Razao Social (fornecedor)
  ZU_STS   - "0"=Pendente / "1"=Cadastrado / "2"=Rejeitado
  ZU_DTSOL - Data da solicitacao
  ZU_REC   - R_E_C_N_O_ original (para reposicionamento)

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   20/04/2026
/*/
//-------------------------------------------------------------------
User Function CADSOLIC()

    Local cAlias := "ZU_SOL"
    Local aArea  := GetArea()

    // Abre a query UNION ALL combinando SZ3 e SZ4
    FSOL_AbreQuery(cAlias)

    If Select(cAlias) == 0
        MsgStop("Erro ao abrir consulta de solicitacoes.", "Solicitacao Cadastral")
        RestArea(aArea)
        Return
    EndIf

    // Privates obrigatorias para mBrowse
    Private cCadastro := "Solicitacao Cadastral"
    Private cDelFunc  := "U_CSOLPODEXC()"
    Private cString   := cAlias

    // Cores: branco=Pendente / cinza=Cadastrado / preto=Rejeitado
    Private aCores := {{ cAlias + "->ZU_STS == '0'", "BR_BRANCO" },;
                       { cAlias + "->ZU_STS == '1'", "DISABLE"   },;
                       { cAlias + "->ZU_STS == '2'", "BR_PRETO"  }}

    // Menu do mBrowse: os 3 primeiros ficam na barra superior
    // e os demais permanecem no menu "Outras Acoes".
    Private aRotina := { {"Incluir"   , "U_CSOLINC()" , 0, 3},;
                         {"Alterar"   , "U_CSOLALT()" , 0, 3},;
                         {"Visualizar", "U_CSOLVIZ()" , 0, 3},;
                         {"Pesquisar" , "AxPesqui"    , 0, 1},;
                         {"Excluir"   , "U_CSOLEXC()" , 0, 5},;
                         {"Legenda"   , "U_CSOLLES()" , 0, 6}}

    (cAlias)->(dbSetOrder(1))
    (cAlias)->(dbGoTop())

    // mBrowse sobre o alias unificado
    // Parametro 7 = cColunas: campos do alias a exibir
    mBrowse(6, 1, 22, 75, cAlias, ,;
        "ZU_TIPO;ZU_ID;ZU_USR;ZU_PRAZO;ZU_DESC;ZU_STS;ZU_DTSOL",;
        , , , aCores)

    If Select(cAlias) > 0
        (cAlias)->(dbCloseArea())
    EndIf

    RestArea(aArea)

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} U_CSOLINC
Acao Incluir do mBrowse unificado.
Exibe seletor Produto / Fornecedor e abre o formulario correto.
Apos gravacao, recria o alias da query para refletir o novo registro.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   20/04/2026
/*/
//-------------------------------------------------------------------
User Function CSOLINC()

    Local oDlgSel
    Local oBtnP, oBtnF, oBtnC
    Local nOpc  := 0
    Local cSave := cString

    DEFINE MSDIALOG oDlgSel TITLE "Tipo de Solicitacao" ;
        FROM 000, 000 TO 080, 335 COLORS 0, 16777215 PIXEL

        @ 014, 010 SAY "O que deseja solicitar?" SIZE 200, 012 PIXEL OF oDlgSel

        @ 040, 010 BUTTON oBtnP PROMPT "Produto"    SIZE 090, 016 OF oDlgSel PIXEL ;
            ACTION (nOpc := 1, oDlgSel:End())
        @ 040, 120 BUTTON oBtnF PROMPT "Fornecedor" SIZE 090, 016 OF oDlgSel PIXEL ;
            ACTION (nOpc := 2, oDlgSel:End())
        @ 040, 230 BUTTON oBtnC PROMPT "Cancelar"   SIZE 090, 016 OF oDlgSel PIXEL ;
            ACTION oDlgSel:End()

    ACTIVATE MSDIALOG oDlgSel CENTERED

    If nOpc == 1
        cString   := "SZ3"
        cCadastro := "Solicitacao de Produto"
        dbSelectArea("SZ3")
        dbSetOrder(1)
        U_CADINSZ3()
    ElseIf nOpc == 2
        cString   := "ZZ4"
        cCadastro := "Solicitacao de Fornecedor"
        dbSelectArea("ZZ4")
        dbSetOrder(1)
        U_CADINSZ4()
    EndIf

    // Recria a query unificada para o novo registro aparecer no browse
    cCadastro := "Solicitacao Cadastral"
    FSOL_AbreQuery(cSave)
    cString := cSave

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} U_CSOLALT
Acao Alterar do mBrowse unificado.
Posiciona em SZ3 ou SZ4 pelo ZU_REC e chama a alteracao correta.
Apos alteracao, recria o alias da query.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   20/04/2026
/*/
//-------------------------------------------------------------------
User Function CSOLALT()

    Local cTipo   := AllTrim((cString)->ZU_TIPO)
    Local nRec    := (cString)->ZU_REC
    Local cSave   := cString
    Local cTabela := IIF(cTipo == "P", "SZ3", "ZZ4")

    dbSelectArea(cTabela)
    dbGoTo(nRec)

    // Redireciona cString para tabela fisica (necessario para AxAltera interno)
    cString   := cTabela
    cCadastro := IIF(cTipo == "P", "Solicitacao de Produto", ;
                                   "Solicitacao de Fornecedor")
    If cTipo == "P"
        U_CPRDALT()
    Else
        U_CFRNALT()
    EndIf

    cCadastro := "Solicitacao Cadastral"
    FSOL_AbreQuery(cSave)
    cString := cSave

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} U_CSOLVIZ
Acao Visualizar do mBrowse unificado.
Posiciona em SZ3 ou SZ4 pelo ZU_REC e chama AxVisual.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   20/04/2026
/*/
//-------------------------------------------------------------------
User Function CSOLVIZ()

    Local cTipo   := AllTrim((cString)->ZU_TIPO)
    Local nRec    := (cString)->ZU_REC
    Local cSave   := cString
    Local cTabela := IIF(cTipo == "P", "SZ3", "ZZ4")

    dbSelectArea(cTabela)
    dbGoTo(nRec)

    cString   := cTabela
    cCadastro := IIF(cTipo == "P", "Solicitacao de Produto", ;
                                   "Solicitacao de Fornecedor")
    AxVisual()

    // Visualizar nao altera dados: apenas restaura alias e repositiona
    cCadastro := "Solicitacao Cadastral"
    cString   := cSave
    If Select(cSave) > 0
        (cSave)->(dbGoTop())
    EndIf

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} U_CSOLEXC
Acao Excluir do mBrowse unificado.
Bloqueia exclusao de registros ja Cadastrados ou Rejeitados.
Posiciona em SZ3 ou SZ4 pelo ZU_REC e chama AxDeleta.
Apos exclusao, recria o alias da query.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   20/04/2026
/*/
//-------------------------------------------------------------------
User Function CSOLEXC()

    Local cTipo   := AllTrim((cString)->ZU_TIPO)
    Local nRec    := (cString)->ZU_REC
    Local cSave   := cString
    Local cTabela := IIF(cTipo == "P", "SZ3", "ZZ4")

    If AllTrim((cString)->ZU_STS) != "0"
        MsgStop("Apenas solicitacoes Pendentes podem ser excluidas.", "Exclusao")
        Return
    EndIf

    dbSelectArea(cTabela)
    dbGoTo(nRec)

    cString   := cTabela
    cCadastro := IIF(cTipo == "P", "Solicitacao de Produto", ;
                                   "Solicitacao de Fornecedor")
    AxDeleta()

    cCadastro := "Solicitacao Cadastral"
    FSOL_AbreQuery(cSave)
    cString := cSave

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} U_CSOLPODEXC
Expressao de validacao de exclusao (cDelFunc).
Retorna .T. apenas para registros Pendentes (ZU_STS == "0").

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   20/04/2026
/*/
//-------------------------------------------------------------------
User Function CSOLPODEXC()
Return ( AllTrim((cString)->ZU_STS) == "0" )


//-------------------------------------------------------------------
/*/{Protheus.doc} U_CSOLLES
Legenda de cores do mBrowse unificado.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   20/04/2026
/*/
//-------------------------------------------------------------------
User Function CSOLLES()

    Local aLeg := {}

    AADD(aLeg, {"Pendente (aguardando cadastro)", "BR_BRANCO"})
    AADD(aLeg, {"Cadastrado"                    , "DISABLE"  })
    AADD(aLeg, {"Rejeitado"                     , "BR_PRETO" })

    BRWLEGENDA(aLeg)

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FSOL_AbreQuery
Constroi e abre (ou reabre) o alias TOPCONN UNION ALL com registros
de SZ3 (Produtos) e SZ4 (Fornecedores).

Se o alias ja existir, e fechado antes de reabrir.
Usado para atualizar o browse apos Incluir / Alterar / Excluir.

@param cAlias C Nome do alias a criar (padrao: "ZU_SOL")
@type  Static Function
/*/
//-------------------------------------------------------------------
Static Function FSOL_AbreQuery(cAlias)

    Local cQuery  := ""
    Local cFilSZ3 := xFilial("SZ3")
    Local cFilSZ4 := xFilial("ZZ4")

    If Select(cAlias) > 0
        (cAlias)->(dbCloseArea())
    EndIf

    cQuery := " SELECT "
    cQuery += "   'P'              AS ZU_TIPO, "
    cQuery += "   Z3_FILIAL        AS ZU_FILI, "
    cQuery += "   Z3_ID            AS ZU_ID,   "
    cQuery += "   Z3_USR           AS ZU_USR,  "
    cQuery += "   LEFT(Z3_DESCRI,80) AS ZU_DESC,"
    cQuery += "   Z3_STATUS        AS ZU_STS,  "
    cQuery += "   Z3_ZDTSOL        AS ZU_DTSOL,"
    cQuery += "   Z3_PRAZO         AS ZU_PRAZO,"
    cQuery += "   R_E_C_N_O_       AS ZU_REC   "
    cQuery += " FROM " + RetSqlName("SZ3")
    cQuery += " WHERE D_E_L_E_T_ = ' ' "
    cQuery += "   AND Z3_FILIAL = '" + cFilSZ3 + "' "
    cQuery += " UNION ALL "
    cQuery += " SELECT "
    cQuery += "   'F'              AS ZU_TIPO, "
    cQuery += "   ZZ4_FILIAL       AS ZU_FILI, "
    cQuery += "   ZZ4_ID           AS ZU_ID,   "
    cQuery += "   ZZ4_USR          AS ZU_USR,  "
    cQuery += "   LEFT(ZZ4_RAZAO,80) AS ZU_DESC, "
    cQuery += "   ZZ4_STATUS       AS ZU_STS,  "
    cQuery += "   ZZ4_ZDTSOL       AS ZU_DTSOL,"
    cQuery += "   ''               AS ZU_PRAZO,"
    cQuery += "   R_E_C_N_O_       AS ZU_REC   "
    cQuery += " FROM " + RetSqlName("ZZ4")
    cQuery += " WHERE D_E_L_E_T_ = ' ' "
    cQuery += "   AND ZZ4_FILIAL = '" + cFilSZ4 + "' "
    cQuery += " ORDER BY ZU_DTSOL DESC, ZU_ID DESC "

    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)

    If Select(cAlias) > 0
        (cAlias)->(dbGoTop())
    EndIf

Return
