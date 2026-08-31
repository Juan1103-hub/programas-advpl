#Include "Protheus.ch"
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} CADPOSIC
Cadastro de Posicoes de Estoque do Item (tabela ZC1).

Tela via FWMBrowse com suporte a Pesquisa Rapida e Filtros.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   2026
/*/
//-------------------------------------------------------------------
User Function CADPOSIC()

    Local aArea   := GetArea()
    Local oBrowse := Nil
    Local aSeek   := {}

    Private aRotina := {{"Visualizar", "AxVisual",  0, 2},;
                        {"Incluir",    "AxInclui",  0, 3},;
                        {"Alterar",    "AxAltera",  0, 4},;
                        {"Excluir",    "AxDeleta",  0, 5},;
                        {"Imprimir",   "Imprimir",  0, 6},;
                        {"Atualizar",  "U_FPOS_REFRESH", 0, 7}}

    Private cCadastro := "Posicoes de Estoque do Item"
    Private oBrowseZC1 := Nil

    // Verifica se a tabela ZC1 existe no dicionario
    If !FPOS_TabelaExiste("ZC1")
        MsgStop("Tabela ZC1 nao encontrada no dicionario (SX2)." + Chr(13) + Chr(10) + ;
                "Cadastre a tabela ZC1 e seus campos no Configurador (SIGACFG) " + ;
                "e reinicie o Protheus.", "CADPOSIC")
        RestArea(aArea)
        Return 
    EndIf

    // Instancia o Browse Moderno (MVC / FWMBrowse)
    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias("ZC1")
    oBrowse:SetDescription("Posicoes de Estoque do Item")
    
    // Habilita o campo de Pesquisa R�pida
    aSeek := {;
        {"Filial",    {{"ZC1_FILIAL", "C", 2,  0, "Filial",    "@!"}}, 1, .T.},;
        {"Codigo",    {{"ZC1_ITEM",   "C", 13, 0, "Codigo",    "@!"}}, 2, .T.},;
        {"Descricao", {{"ZC1_DESCRI", "C", 50, 0, "Descricao", "@!"}}, 3, .T.};
    }
    oBrowse:SetSeek(.T., aSeek)

    oBrowseZC1 := oBrowse

    // Ativa o Browse
    oBrowse:Activate()

    RestArea(aArea)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} FPOS_TabelaExiste
Verifica se a tabela informada existe na SX2.
/*/
//-------------------------------------------------------------------
Static Function FPOS_TabelaExiste(cArq)

    Local lRet := .F.

    DbSelectArea("SX2")
    SX2->(DbSetOrder(1))
    lRet := SX2->(DbSeek(cArq))

Return lRet
//-------------------------------------------------------------------
/*/{Protheus.doc} FPOS_BUSCA
Retorna a posicao de estoque do item cadastrado na ZC1.
Pode ser usada no Inic. Padrao de campos (ex: CP_POSIC).

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   2026
/*/
//-------------------------------------------------------------------
User Function FPOS_BUSCA()

    Local cCodProd := ""
    Local cPosic   := ""
    Local cFilZC1  := ""
    Local aAreaZC1 := ZC1->(GetArea())

    // Captura o codigo do produto (memoria ou tabela SCP/SB1)
    If Type("M->CP_PRODUTO") == "C" .And. !Empty(M->CP_PRODUTO)
        cCodProd := M->CP_PRODUTO
    ElseIf Type("SCP->CP_PRODUTO") == "C" .And. !Empty(SCP->CP_PRODUTO)
        cCodProd := SCP->CP_PRODUTO
    EndIf

    // Busca a posicao na tabela ZC1
    If !Empty(cCodProd)
        cFilZC1 := xFilial("ZC1")
        DbSelectArea("ZC1")
        ZC1->(DbSetOrder(1))
        If ZC1->(MsSeek(cFilZC1 + PadR(cCodProd, TamSX3("ZC1_ITEM")[1])))
            cPosic := ZC1->ZC1_POSIC
        EndIf
    EndIf

    RestArea(aAreaZC1)

Return cPosic

//-------------------------------------------------------------------
/*/{Protheus.doc} FPOS_SALDO
Retorna o saldo fisico atual do produto na SB2 para o browse/form.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   2026
/*/
//-------------------------------------------------------------------
User Function FPOS_SALDO()

    Local cCodProd := ZC1->ZC1_ITEM
    Local cLocal   := ZC1->ZC1_LOCAL
    Local nSaldo   := 0

    If !Empty(cCodProd) .And. !Empty(cLocal)
        // Posiciona na SB2 (Indice 1: B2_FILIAL + B2_COD + B2_LOCAL)
        DbSelectArea("SB2")
        SB2->(DbSetOrder(1))
        If SB2->(DbSeek(xFilial("SB2") + PadR(cCodProd, TamSX3("B2_COD")[1]) + PadR(cLocal, TamSX3("B2_LOCAL")[1])))
            // Retorna o Saldo Atual (B2_QATU) tirando reservas se necessario
            nSaldo := SB2->B2_QATU
        EndIf
        DbSelectArea("ZC1")
    EndIf

Return nSaldo

//-------------------------------------------------------------------
/*/{Protheus.doc} FPOS_REFRESH
Atualiza o browse de Posicoes de Estoque (ZC1).

@type    User Function
/*/
//-------------------------------------------------------------------
User Function FPOS_REFRESH()

    If oBrowseZC1 != Nil
        oBrowseZC1:Refresh()
    EndIf

Return
