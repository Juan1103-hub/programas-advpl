#Include "PROTHEUS.CH"
#Include "FWMVCDEF.CH"


/*
================================================================================
| Ponto de Entrada | MTA094RO                                                 |
|------------------------------------------------------------------------------|
| Descrição         | Adiciona um botão na rotina de Liberação de Documentos  |
|                   | para comparar com a última compra.                      |
================================================================================
*/
User Function MTA094RO()
    Local aRotina := PARAMIXB[1]


    AAdd(aRotina, { "Comparar Ult. Compra", "U_COMPULT()", 0, 2, 0, Nil } )


Return aRotina


//------------------------------------------------------------------------------
// Botão: compara TODAS as linhas do pedido atual
//------------------------------------------------------------------------------
User Function COMPULT()
    Local aArea   := FWGetArea()
    Local cNum    := ""
    Local cMsg    := ""
    Local cProd   := ""
    Local cDescPd := ""


    // 1) Pegamos o número do documento na SCR (linha da MATA094)
    DbSelectArea("SCR")
    If SCR->(Eof())
        MsgInfo("Nenhum documento selecionado.", "Comparar Ultima Compra")
        FWRestArea(aArea)
        Return
    EndIf


    cNum := AllTrim(SCR->CR_NUM)    // CONFIRME se é CR_NUM ou CR_DOC


    If Empty(cNum)
        MsgInfo("Documento atual sem número de pedido.", "Comparar Ultima Compra")
        FWRestArea(aArea)
        Return
    EndIf


    // 2) Agora usa exatamente a mesma lógica antiga na SC7
    DbSelectArea("SC7")
    SC7->(DbSetOrder(1))            // mesma ordem que você usava antes


    If ! SC7->(DbSeek(xFilial("SC7") + cNum))
        MsgInfo("Pedido " + AllTrim(cNum) + " sem itens na SC7.", "Comparar Ultima Compra")
        FWRestArea(aArea)
        Return
    EndIf


    cProd := SC7->C7_PRODUTO


    // Descrição do produto em foco (opcional)
    DbSelectArea("SB1")
    If ! Empty(cProd) .And. DbSeek(xFilial("SB1") + cProd)
        cDescPd := SB1->B1_DESC
    EndIf


    // Cabeçalho geral (sem repetir produto se você já tirou)
    cMsg := "Comparacao das ultimas compras - Pedido " + AllTrim(cNum) + CRLF + CRLF


    // Loop em TODOS os itens do pedido - IGUAL AO CÓDIGO QUE FUNCIONAVA
    DbSelectArea("SC7")             // garante área SC7 ativa
    While ! SC7->(Eof()) .And. SC7->C7_FILIAL == xFilial("SC7") .And. SC7->C7_NUM == cNum


        cMsg += U_ZUltCompItem( ;
            SC7->C7_PRODUTO, ;
            SC7->C7_ITEM, ;
            SC7->C7_FORNECE, ;
            SC7->C7_NUM, ;
            SC7->C7_EMISSAO, ;
            SC7->C7_PRECO, ;
            SC7->C7_DESC, ;
            SC7->C7_VLDESC, ;
            SC7->C7_QUANT, ;
            SC7->C7_UM ) + CRLF + CRLF


        SC7->(DbSkip())
    EndDo


    MsgInfo(cMsg, "Comparar Ultima Compra")


    FWRestArea(aArea)


Return


//------------------------------------------------------------------------------
// Função auxiliar: compara ÚNICO item (uma linha da SC7)
// Mostra preço cheio, desconto (%) e preço líquido do atual x último pedido
//------------------------------------------------------------------------------
User Function ZUltCompItem( cProd, cItem, cFor, cNum, dEmiss, nPreco, ;
                            nPercDescAtu, nVlrDescAtu, nQtdAtu, cUMAtu )


    Local aArea      := FWGetArea()
    Local cMsg       := ""
    Local cDescProd  := ""
    Local cDescFor   := ""
    Local cUltForNom := ""
    Local cDataAtu   := ""
    Local cDataUlt   := ""
    Local cUltNum    := ""
    Local cUltItem   := ""
    Local cUltFor    := ""
    Local cUltUM     := ""
    Local nUltQtd    := 0
    Local nUltPrec   := 0
    Local nVarPct    := 0
    Local dUltEmi    := Ctod("")
    Local cAliasQ    := GetNextAlias()
    Local cQuery     := ""
    Local cSep       := Replicate("-", 60)
    Local nPercDescUlt := 0
    Local nVlrDescUlt  := 0
    Local nPrecoLiqAtu := 0
    Local nPrecoLiqUlt := 0
    Local cMascPreco  := "@E 999,999,999.99"
    Local nQtdAtual   := nQtdAtu
    Local nPrecoAtual := nPreco
    Local cUMAtual    := cUMAtu


    // Descrição do produto
    DbSelectArea("SB1")
    If DbSeek(xFilial("SB1") + cProd)
        cDescProd := SB1->B1_DESC
    EndIf


    // Descrição do fornecedor ATUAL
    DbSelectArea("SA2")
    If DbSeek(xFilial("SA2") + cFor)
        cDescFor := SA2->A2_NOME
    EndIf


    //===========================
    // Busca ÚLTIMA compra ANTERIOR desse produto / item
    // ignorando: resíduo, cancelado/recusado, em aprovação
    //===========================
    // 1ª tentativa: mesmo produto + item
    cQuery  := "SELECT TOP 1 "
    cQuery  += "  C7_EMISSAO, C7_PRECO, C7_NUM, C7_ITEM, "
    cQuery  += "  C7_FORNECE, C7_QUANT, C7_UM, C7_DESC, C7_VLDESC "
    cQuery  += "FROM "  + RetSqlName("SC7") + " "
    cQuery  += "WHERE C7_FILIAL   = '" + xFilial("SC7")      + "' "
    cQuery  += "  AND C7_PRODUTO  = '" + AllTrim(cProd)      + "' "
    cQuery  += "  AND C7_NUM     <> '" + AllTrim(cNum)       + "' "
    cQuery  += "  AND D_E_L_E_T_  = ' ' "
    cQuery  += "  AND (C7_RESIDUO IS NULL OR C7_RESIDUO <> 'S') "
    cQuery  += "  AND (C7_ENCER   IS NULL OR C7_ENCER   <> 'C') "
    cQuery  += "  AND (C7_CONAPRO IS NULL OR C7_CONAPRO NOT IN ('B','R')) "
    cQuery  += "ORDER BY C7_EMISSAO DESC, C7_NUM DESC"


    DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAliasQ, .F., .T.)


    If !(cAliasQ)->(Eof())     // ENCONTROU última compra


        nUltPrec     := (cAliasQ)->C7_PRECO
        nPercDescUlt := (cAliasQ)->C7_DESC
        nVlrDescUlt  := (cAliasQ)->C7_VLDESC


        If ValType((cAliasQ)->C7_EMISSAO) == "C"
            dUltEmi := StoD((cAliasQ)->C7_EMISSAO)
        Else
            dUltEmi := (cAliasQ)->C7_EMISSAO
        EndIf


        cUltNum  := (cAliasQ)->C7_NUM
        cUltItem := (cAliasQ)->C7_ITEM
        cUltFor  := (cAliasQ)->C7_FORNECE
        nUltQtd  := (cAliasQ)->C7_QUANT
        cUltUM   := (cAliasQ)->C7_UM


        // Nome do fornecedor da última compra
        DbSelectArea("SA2")
        If DbSeek(xFilial("SA2") + cUltFor)
            cUltForNom := SA2->A2_NOME
        EndIf


        // Datas seguras
        If ValType(dEmiss) != "D"
            dEmiss := Ctod("")
        EndIf
        If ValType(dUltEmi) != "D"
            dUltEmi := Ctod("")
        EndIf


        cDataAtu := IIf(ValType(dEmiss)  == "D", DtoC(dEmiss),  "")
        cDataUlt := IIf(ValType(dUltEmi) == "D", DtoC(dUltEmi), "")


        //===========================
        // Preço / desconto ATUAL
        //===========================
        If nPercDescAtu > 0
            nPrecoLiqAtu := nPreco * (1 - (nPercDescAtu / 100))
        ElseIf nVlrDescAtu > 0 .And. nQtdAtu > 0 .And. (nPreco * nQtdAtu) <> 0
            nPercDescAtu := ( (nVlrDescAtu / (nPreco * nQtdAtu)) * 100 )
            nPrecoLiqAtu := nPreco * (1 - (nPercDescAtu / 100))
        Else
            nPrecoLiqAtu := nPreco
        EndIf


        //===========================
        // Preço / desconto ÚLTIMO PEDIDO
        //===========================
        If nPercDescUlt > 0
            nPrecoLiqUlt := nUltPrec * (1 - (nPercDescUlt / 100))
        ElseIf nVlrDescUlt > 0 .And. nUltQtd > 0 .And. (nUltPrec * nUltQtd) <> 0
            nPercDescUlt := ( (nVlrDescUlt / (nUltPrec * nUltQtd)) * 100 )
            nPrecoLiqUlt := nUltPrec * (1 - (nPercDescUlt / 100))
        Else
            nPrecoLiqUlt := nUltPrec
        EndIf


        //===========================
        // Monta texto do item
        //===========================
        cMsg := ""
        cMsg += ">>> Item " + AllTrim(cItem) + " - " + AllTrim(cProd) + " - " + ;
                AllTrim(cDescProd) + " <<<" + CRLF + CRLF


        // PEDIDO ATUAL
        cMsg += PadC(" PEDIDO ATUAL ", 24, "=") + CRLF
        cMsg += "Numero: " + AllTrim(cNum) + CRLF
        cMsg += "Emissao: " + cDataAtu + CRLF
        cMsg += "Fornec: " + AllTrim(cFor) + " - " + AllTrim(cDescFor) + CRLF
        cMsg += "Qtde: " + AllTrim(Str(nQtdAtual, 12, 2)) + " " + AllTrim(cUMAtual) + CRLF
        cMsg += "Preco: " + AllTrim(StrTran(Transform(nPrecoAtual, cMascPreco), ",", ".")) + CRLF
        cMsg += "Desc %: " + AllTrim(Str(nPercDescAtu, 6, 2)) + CRLF
        cMsg += "Preco liq.: " + AllTrim(StrTran(Transform(nPrecoLiqAtu, cMascPreco), ",", ".")) + CRLF + CRLF


        // ULTIMO PEDIDO
        cMsg += PadC(" ULTIMO PEDIDO ", 24, "=") + CRLF
        cMsg += "Numero: " + AllTrim(cUltNum) + CRLF
        cMsg += "Emissao: " + cDataUlt + CRLF
        cMsg += "Fornec: " + AllTrim(cUltFor) + " - " + AllTrim(cUltForNom) + CRLF
        cMsg += "Qtde: " + AllTrim(Str(nUltQtd, 12, 2)) + " " + AllTrim(cUltUM) + CRLF
        cMsg += "Preco: " + AllTrim(StrTran(Transform(nUltPrec, cMascPreco), ",", ".")) + CRLF
        cMsg += "Desc %: " + AllTrim(Str(nPercDescUlt, 6, 2)) + CRLF
        cMsg += "Preco liq.: " + AllTrim(StrTran(Transform(nPrecoLiqUlt, cMascPreco), ",", ".")) + CRLF + CRLF


        // Variação em cima do preço líquido
        If nPrecoLiqUlt > 0
            nVarPct := ((nPrecoLiqAtu - nPrecoLiqUlt) / nPrecoLiqUlt) * 100
            cMsg    += cSep + CRLF
            cMsg    += "Variacao de preco liq.: " + Str(nVarPct, 8, 2) + " %" + CRLF
        EndIf


    Else   // NÃO encontrou última compra


        cMsg := "Item " + AllTrim(cItem) + " - " + AllTrim(cProd) + " - " + ;
                AllTrim(cDescProd) + CRLF + ;
                "Nenhuma compra anterior encontrada para este item."


    EndIf


    (cAliasQ)->(DbCloseArea())
    FWRestArea(aArea)


Return cMsg
