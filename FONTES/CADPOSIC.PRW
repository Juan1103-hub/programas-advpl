#Include "Protheus.ch"
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} CADPOSIC
Cadastro de Posicoes de Estoque do Item (tabela ZC1).

Tela via mBrowse com suporte a Pesquisa e Filtros.

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

    // Verifica se a tabela ZC1 existe no dicionario
    If !FPOS_TabelaExiste("ZC1")
        MsgStop("Tabela ZC1 nao encontrada no dicionario (SX2)." + Chr(13) + Chr(10) + ;
                "Cadastre a tabela ZC1 e seus campos no Configurador (SIGACFG) " + ;
                "e reinicie o Protheus.", "CADPOSIC")
        RestArea(aArea)
        Return 
    EndIf

    Private aRotina    := {{"Visualizar", "AxVisual",  0, 2},;
                           {"Incluir",    "AxInclui",  0, 3},;
                           {"Alterar",    "AxAltera",  0, 4},;
                           {"Excluir",    "U_FPOS_DELETA", 0, 5},;
                           {"Imprimir",   "Imprimir",  0, 6},;
                           {"Atualizar",  "U_FPOS_REFRESH", 0, 7},;
                           {"Importar Planilha", "U_FPOS_IMPORT", 0, 8},;
                           {"Limpar Registros", "U_FPOS_LIMPAR", 0, 9}}

    Private cCadastro  := "Posicoes de Estoque do Item"
    Private oBrowseZC1 := Nil

    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias("ZC1")
    oBrowse:SetDescription("Posicoes de Estoque do Item")

    // Tamanhos fixos (regra do projeto: TamSX3() inline no array do
    // SetSeek para tabelas Z* causa "array out of bounds"). ZC1_ITEM = 13
    // e ZC1_DESCRI = 50 conforme SX3. Ordem 1 = ZC1_FILIAL+ZC1_ITEM e
    // ordem 2 = ZC1_FILIAL+ZC1_DESCRI - mesmo padrao de aSeek do
    // MATA010 (SB1), onde o FWSeek posiciona/filtra pelo indice.
    aSeek := {;
        {"Codigo",    {{"ZC1_ITEM",   "C", 13, 0, "Codigo",    "@!"}}, 1, .T.},;
        {"Descricao", {{"ZC1_DESCRI", "C", 50, 0, "Descricao", "@!"}}, 2, .T.};
    }
    oBrowse:SetSeek(.T., aSeek)

    // Auto-refresh desativado em 14/10/2026: o SetTimer de 60s corria junto
    // com a navegacao e o FWSeek, e ao clicar nas linhas do browse os
    // codigos exibidos trocavam (dessincronizacao do repaint). Use o botao
    // "Atualizar" para recalcular o saldo sob demanda.
    // oBrowse:SetTimer({|| U_FPOS_REFRESH()}, 60000)

    oBrowseZC1 := oBrowse

    oBrowse:Activate()

    RestArea(aArea)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} FPOS_IMPORT
Importa posicoes de estoque em massa via planilha CSV.
Planilha deve conter colunas: Codigo (ZC1_ITEM) e Posicao (ZC1_POSIC).
Descricao e Saldo Atual sao preenchidos automaticamente.

@type    User Function
/*/
//-------------------------------------------------------------------
User Function FPOS_IMPORT()

    Local cFile   := ""
    Local nHandle := 0
    Local cLinha  := ""
    Local cCod    := ""
    Local cPosic  := ""
    Local cDesc   := ""
    Local nSaldo  := 0
    Local cLocal  := "01"
    Local nInc    := 0
    Local nSkip   := 0
    Local nDupl   := 0
    Local lPriLin := .T.
    Local aCampos := {}
    Local aArea   := GetArea()

    // Abre o dialogo para selecionar o arquivo CSV
    cFile := cGetFile("Planilha CSV (*.csv)|*.csv", "Selecione a planilha de posicoes",, "C:\", .F., GETF_LOCALFLOPPY + GETF_LOCALHARD)

    If Empty(cFile)
        Return
    EndIf

    If !File(cFile)
        MsgStop("Arquivo nao encontrado: " + cFile, "Importar Planilha")
        Return
    EndIf

    // Abre o arquivo CSV
    nHandle := FT_FUse(cFile)
    If nHandle < 0
        MsgStop("Erro ao abrir o arquivo: " + cFile, "Importar Planilha")
        Return
    EndIf

    DbSelectArea("ZC1")
    ZC1->(DbSetOrder(1)) // ZC1_FILIAL + ZC1_ITEM

    // Percorre as linhas do CSV
    FT_FGoTop()
    While !FT_FEOF()
        cLinha := AllTrim(FT_FReadln())

        If Empty(cLinha)
            FT_FSkip()
            Loop
        EndIf

        // Pula cabecalho (linha 1)
        If lPriLin
            lPriLin := .F.
            FT_FSkip()
            Loop
        EndIf

        // Separa por ponto e virgula: Codigo;Posicao
        aCampos := StrTokArr(cLinha, ";")

        If Len(aCampos) < 2
            FT_FSkip()
            Loop
        EndIf

        cCod   := AllTrim(aCampos[1])
        cPosic := AllTrim(aCampos[2])

        If Empty(cCod)
            FT_FSkip()
            Loop
        EndIf

        // Busca descricao do SB1
        cDesc := ""
        DbSelectArea("SB1")
        SB1->(DbSetOrder(1))
        If SB1->(DbSeek(xFilial("SB1") + PadR(cCod, TamSX3("B1_COD")[1])))
            cDesc := SB1->B1_DESC
            cLocal := SB1->B1_LOCPAD
        Else
            nSkip++
            FT_FSkip()
            Loop
        EndIf

        // Verifica se ja existe na ZC1
        DbSelectArea("ZC1")
        ZC1->(DbSetOrder(1))
        If ZC1->(DbSeek(xFilial("ZC1") + PadR(cCod, TamSX3("ZC1_ITEM")[1])))
            nDupl++
            FT_FSkip()
            Loop
        EndIf

        // Busca saldo na SB2
        nSaldo := 0
        DbSelectArea("SB2")
        SB2->(DbSetOrder(1))
        If SB2->(DbSeek(xFilial("SB2") + PadR(cCod, TamSX3("B2_COD")[1]) + PadR(cLocal, TamSX3("B2_LOCAL")[1])))
            nSaldo := SB2->B2_QATU
        EndIf

        // Inclui o registro na ZC1
        DbSelectArea("ZC1")
        RecLock("ZC1", .T.)
        ZC1->ZC1_FILIAL := xFilial("ZC1")
        ZC1->ZC1_ITEM   := cCod
        ZC1->ZC1_POSIC  := cPosic
        ZC1->ZC1_DESCRI := cDesc
        ZC1->ZC1_LOCAL  := cLocal
        If ZC1->(ColumnPos("ZC1_SALDO")) > 0
            ZC1->ZC1_SALDO := nSaldo
        EndIf
        MsUnlock()
        nInc++

        FT_FSkip()
    EndDo

    FT_FUse()

    RestArea(aArea)

    // Mensagem final
    MsgInfo("Importacao concluida!" + Chr(13) + Chr(10) + ;
            "Incluidos: " + AllTrim(Str(nInc)) + Chr(13) + Chr(10) + ;
            "Duplicados (ignorados): " + AllTrim(Str(nDupl)) + Chr(13) + Chr(10) + ;
            "Codigo nao encontrado no SB1 (ignorados): " + AllTrim(Str(nSkip)), "Importar Planilha")

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} FPOS_DELETA
Exclui registro da ZC1, mas impede deletar o ultimo registro
para evitar erro ARQVAZIO no browse.

@type    User Function
/*/
//-------------------------------------------------------------------
User Function FPOS_DELETA()

    Local nReg := 0

    DbSelectArea("ZC1")
    Count To nReg

    If nReg <= 1
        MsgStop("Nao e possivel excluir o ultimo registro da tabela." + Chr(13) + Chr(10) + ;
                "A tabela deve conter ao menos 1 registro.", "Excluir")
        Return
    EndIf

    AxDeleta("ZC1", ZC1->(RecNo()), 5)

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
    Local aAreaZC1 := GetArea()

    // Captura o codigo do produto (memoria ou tabela SCP/SB1)
    If Type("M->CP_PRODUTO") == "C" .And. !Empty(M->CP_PRODUTO)
        cCodProd := M->CP_PRODUTO
    ElseIf Type("SCP->CP_PRODUTO") == "C" .And. !Empty(SCP->CP_PRODUTO)
        cCodProd := SCP->CP_PRODUTO
    EndIf

    // Busca a posicao na tabela ZC1 (contexto SCP/MATA185)
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

Recalcula o saldo armazenado (ZC1_SALDO) direto da SB2 para todos os
registros ANTES de redesenhar a tela, para que a coluna "Saldo atual"
reflete as baixas/devolucoes feitas na MATA185. Vale somente quando
ZC1_SALDO e um campo REAL; se a coluna for virtual com Relacao
U_FPOS_SALDO(), o proprio repaint ja atualiza o valor.

@type    User Function
/*/
//-------------------------------------------------------------------
User Function FPOS_REFRESH()

    Local aArea  := GetArea()
    Local nSaldo := 0
    Local lReal  := .F.

    // Nao recalcula enquanto uma inclusao/alteracao estiver aberta
    // (evita conflito de lock e de posicionamento com AxInclui/AxAltera)
    If (Type("INCLUI") == "L" .And. INCLUI) .Or. (Type("ALTERA") == "L" .And. ALTERA)
        Return
    EndIf

    // Verifica se ZC1_SALDO existe fisicamente e e campo REAL
    If ZC1->(ColumnPos("ZC1_SALDO")) > 0 .And. ;
       GetSX3Cache("ZC1_SALDO", "X3_CONTEXT") == "R"
        lReal := .T.
    EndIf

    // Recalcula o saldo de cada registro a partir da SB2
    If lReal
        DbSelectArea("ZC1")
        DbGoTop()
        Do While !Eof()
            If !Empty(ZC1->ZC1_ITEM) .And. !Empty(ZC1->ZC1_LOCAL)
                // User Function chamada com prefixo U_ (registro no AppMap)
                nSaldo := U_FPOS_SALDO()
                // Grava somente quando o saldo mudou e conseguir o lock
                If ZC1->ZC1_SALDO != nSaldo
                    If RecLock("ZC1", .F.)
                        ZC1->ZC1_SALDO := nSaldo
                        MsUnlock()
                    EndIf
                EndIf
            EndIf
            DbSkip()
        EndDo
    EndIf

    RestArea(aArea)

    // Agora sim redesenha com os valores ja recalculados
    If oBrowseZC1 != Nil
        oBrowseZC1:Refresh()
    EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} FPOS_LIMPAR
Exclui todos os registros da ZC1, mantendo apenas 1
para evitar erro ARQVAZIO no browse.

@type    User Function
/*/
//-------------------------------------------------------------------
User Function FPOS_LIMPAR()

    Local nReg := 0
    Local nDel := 0
    Local aArea := GetArea()

    DbSelectArea("ZC1")
    Count To nReg

    If nReg <= 1
        MsgInfo("A tabela ja possui apenas " + AllTrim(Str(nReg)) + " registro(s)." + Chr(13) + Chr(10) + ;
                "Nenhuma exclusao necessaria.", "Limpar Registros")
        RestArea(aArea)
        Return
    EndIf

    If !MsgYesNo("Deseja excluir TODOS os registros da tabela ZC1?" + Chr(13) + Chr(10) + Chr(13) + Chr(10) + ;
                 "Sera mantido apenas 1 registro para evitar erro ARQVAZIO." + Chr(13) + Chr(10) + Chr(13) + Chr(10) + ;
                 "Total de registros: " + AllTrim(Str(nReg)) + Chr(13) + Chr(10) + ;
                 "Registros a excluir: " + AllTrim(Str(nReg - 1)), "Limpar Registros")
        RestArea(aArea)
        Return
    EndIf

    DbGoTop()
    DbSkip() // Pula o primeiro registro

    Do While !Eof()
        RecLock("ZC1", .F.)
        DbDelete()
        MsUnlock()
        nDel++
        DbSkip()
    EndDo

    DbGoTop()

    RestArea(aArea)

    MsgInfo("Limpeza concluida!" + Chr(13) + Chr(10) + ;
            "Registros excluidos: " + AllTrim(Str(nDel)) + Chr(13) + Chr(10) + ;
            "Registros mantidos: 1", "Limpar Registros")

    If oBrowseZC1 != Nil
        oBrowseZC1:Refresh()
    EndIf

Return
