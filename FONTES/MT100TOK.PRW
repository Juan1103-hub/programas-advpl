#Include "Protheus.ch"

#Define CRLF          Chr(13)+Chr(10)
#Define CTAEST_ALMOXA "11401200001"

/*/{Protheus.doc} MT100TOK
Ponto de entrada para validacao do Documento de Entrada (SD1 / MATA103).
Bloqueia a inclusao de itens cuja conta contabil de estoque (B1_XCTAEST)
seja igual a 11401200001 e cuja TES movimente estoque (F4_ESTOQUE == 'S'),
EXCETO quando o item originar de um Pedido de Compra (D1_PEDIDO preenchido).
Itens de servico/TES sem estoque sao liberados porque nao geram saldo em SB2.
@type     User Function
@author   Desenvolvimento
@since    26/04/2026
@return   lRet, logical, .T. = Permite gravar | .F. = Bloqueia gravacao
/*/
User Function MT100TOK()
    Local aArea      := GetArea() As Array
    Local lRet       := .T.  As Logical
    Local nX         := 0    As Numeric
    Local cProduto   := ""   As Character
    Local cTES       := ""   As Character
    Local cCtaEst    := ""   As Character
    Local cNumPC     := ""   As Character
    Local cMsgItens  := ""   As Character
    Local lBloqueado := .F.  As Logical
    Local lMovEst    := .F.  As Logical

    ConOut("========================================")
    ConOut("MT100TOK - Validacao Documento de Entrada")
    ConOut("========================================")

    // Percorre todas as linhas do documento de entrada
    For nX := 1 To Len(aCols)

        // Ignora linhas deletadas
        If aCols[nX][Len(aCols[nX])]
            Loop
        EndIf

        // Obtem codigo do produto da linha
        cProduto := GdFieldGet("D1_COD", nX)

        // Se produto nao informado, pula para proxima linha
        If Empty(cProduto)
            Loop
        EndIf

        // Verifica se o item originou de Pedido de Compra
        cNumPC  := AllTrim(GdFieldGet("D1_PEDIDO", nX))
        cTES    := AllTrim(GdFieldGet("D1_TES", nX))
        lMovEst := MT1MOVES(cTES)

        ConOut("MT100TOK - Linha " + cValToChar(nX) + ;
               " | Produto: [" + cProduto + "]" + ;
               " | D1_TES: [" + cTES + "]" + ;
               " | Mov.Estoque: [" + IIf(lMovEst, "S", "N") + "]" + ;
               " | D1_PEDIDO: [" + cNumPC + "]")

        // TES que nao movimenta estoque (servico/sem saldo SB2) nao deve ser bloqueada
        If !lMovEst
            Loop
        EndIf

        // Se veio de pedido de compra, permite (pula a validacao)
        If !Empty(cNumPC)
            Loop
        EndIf

        // Busca conta contabil de estoque na tabela SB1
        DbSelectArea("SB1")
        SB1->(DbSetOrder(1)) // B1_FILIAL + B1_COD

        If SB1->(DbSeek(xFilial("SB1") + cProduto))
            cCtaEst := AllTrim(SB1->B1_XCTAEST)

            ConOut("MT100TOK - B1_XCTAEST: [" + cCtaEst + "]")

            // Verifica se a conta contabil e a de almoxarifado (bloqueada)
            If cCtaEst == CTAEST_ALMOXA
                cMsgItens += "  - " + AllTrim(cProduto) + " | " + AllTrim(SB1->B1_DESC) + CRLF
                lBloqueado := .T.
            EndIf
        EndIf

    Next nX

    // Se encontrou itens bloqueados, exibe mensagem e impede gravacao
    If lBloqueado
        MsgStop( "ITEM(NS) DE ALMOXARIFADO NAO PERMITIDO(S) NO DOCUMENTO DE ENTRADA." + CRLF + CRLF + ;
                 "Os itens abaixo possuem conta contabil de estoque" + CRLF + ;
                 "[" + CTAEST_ALMOXA + "] e TES que movimenta estoque." + CRLF + ;
                 "Somente podem ser recebidos" + CRLF + ;
                 "quando vinculados a um Pedido de Compra." + CRLF + CRLF + ;
                 "Itens bloqueados:" + CRLF + cMsgItens + CRLF + ;
                 "Vincule os itens a um Pedido de Compra ou" + CRLF + ;
                 "entre em contato com Suprimentos.", ;
                 "Documento de Entrada - Acesso Negado")
        lRet := .F.
    EndIf

    ConOut("MT100TOK - Resultado: " + IIf(lRet, "PERMITE", "BLOQUEIA"))
    ConOut("========================================")

    RestArea(aArea)

Return lRet

/*/{Protheus.doc} MT1MOVES
Verifica se a TES informada movimenta estoque.
@type Static Function
@param cTES, Character, Codigo da TES (D1_TES)
@return lMovEst, Logical, .T. = F4_ESTOQUE == 'S' | .F. = servico/sem estoque
/*/
Static Function MT1MOVES(cTES)
    Local aArea   := GetArea() As Array
    Local lMovEst := .F.      As Logical
    Local cChave  := ""       As Character

    cTES := AllTrim(cTES)

    If Empty(cTES)
        RestArea(aArea)
        Return .F.
    EndIf

    DbSelectArea("SF4")
    SF4->(DbSetOrder(1))

    cChave := xFilial("SF4") + PadR(cTES, TamSX3("F4_CODIGO")[1])

    If SF4->(DbSeek(cChave))
        lMovEst := (Upper(AllTrim(SF4->F4_ESTOQUE)) == "S")
    EndIf

    RestArea(aArea)

Return lMovEst
