#Include "Protheus.ch"

#Define CRLF Chr(13)+Chr(10)
#Define CTAEST_BLOQUEADA "11401200001"

/*/{Protheus.doc} MT120OK
Ponto de entrada de validacao do Pedido de Compra (SC7 / MATA121).

1) Bloqueia a inclusao de itens cuja conta contabil de estoque (B1_XCTAEST)
   seja igual a 11401200001, EXCETO quando o item originar de uma Solicitacao
   de Compra (C7_NUMSC preenchido).

2) Valida que o C7_TPFRETE (Tipo de Frete) esteja preenchido. A regra e:
   - O usuario DEVE informar o Tp. Frete na primeira linha do grid.
   - O PE MT120TFR (via gatilho SX7 em C7_PRODUTO) propaga o valor para
     as demais linhas e alimenta o M->C7_TPFRETE (cabecalho).
   - Este PE valida que o M->C7_TPFRETE esta preenchido no momento do save.
   - Se vazio, bloqueia com MsgStop.

@type     User Function
@author   Desenvolvimento
@since    25/05/2026
@version  2.0
@return   lRet, logical, .T. = Permite gravar | .F. = Bloqueia gravacao
/*/
User Function MT120OK()
    Local aArea       := GetArea()
    Local lRet        := .T.  As Logical
    Local nX          := 0    As Numeric
    Local cProduto    := ""   As Character
    Local cCtaEst     := ""   As Character
    Local cMsgItens   := ""   As Character
    Local lBloqueado  := .F.  As Logical
    Local cNumSC      := ""   As Character
    Local cTpFreteCab := ""   As Character

    // -------------------------------------------------------------------------
    // BLOCO 1: Validacao de C7_TPFRETE obrigatorio
    // -------------------------------------------------------------------------
    If Type("M->C7_TPFRETE") == "C"
        cTpFreteCab := AllTrim(M->C7_TPFRETE)
    EndIf

    If Empty(cTpFreteCab)
        MsgStop("Tipo de Frete obrigatorio." + CRLF + ;
                "Informe o Tipo de Frete (CIF/FOB/Sem Frete) na primeira " + ;
                "linha do pedido. As demais linhas serao preenchidas " + ;
                "automaticamente ao informar o produto.", ;
                "Validacao - Tipo de Frete")
        lRet := .F.
    EndIf

    // -------------------------------------------------------------------------
    // BLOCO 2: Validacao de conta contabil bloqueada
    // -------------------------------------------------------------------------
    If lRet
        For nX := 1 To Len(aCols)

            // Ignora linhas deletadas
            If aCols[nX][Len(aCols[nX])]
                Loop
            EndIf

            // Obtem codigo do produto da linha
            cProduto := GdFieldGet("C7_PRODUTO", nX)

            // Se produto nao informado, pula para proxima linha
            If Empty(cProduto)
                Loop
            EndIf

            // Verifica se o item originou de Solicitacao de Compra
            cNumSC := GdFieldGet("C7_NUMSC", nX)

            // Se veio de solicitacao de compra, permite (pula a validacao)
            If !Empty(cNumSC)
                Loop
            EndIf

            // Busca conta contabil de estoque na tabela SB1
            DbSelectArea("SB1")
            SB1->(DbSetOrder(1)) // B1_FILIAL + B1_COD

            If SB1->(DbSeek(xFilial("SB1") + cProduto))
                cCtaEst := AllTrim(SB1->B1_XCTAEST)

                // Verifica se a conta contabil e a bloqueada
                If cCtaEst == CTAEST_BLOQUEADA
                    cMsgItens += "  - " + AllTrim(cProduto) + " | " + AllTrim(SB1->B1_DESC) + CRLF
                    lBloqueado := .T.
                EndIf
            EndIf

        Next nX

        // Se encontrou itens bloqueados, exibe mensagem e impede gravacao
        If lBloqueado
            MsgStop( "ITEM(NS) NAO PERMITIDO(S) NO PEDIDO DE COMPRA DIRETO." + CRLF + CRLF + ;
                     "Os itens abaixo possuem conta contabil de estoque" + CRLF + ;
                     "[" + CTAEST_BLOQUEADA + "] e so podem ser adquiridos" + CRLF + ;
                     "via Solicitacao de Compra." + CRLF + CRLF + ;
                     "Itens bloqueados:" + CRLF + cMsgItens + CRLF + ;
                     "Utilize uma Solicitacao de Compra para esses itens" + CRLF + ;
                     "ou entre em contato com Suprimentos.", ;
                     "Pedido de Compra - Acesso Negado")
            lRet := .F.
        EndIf
    EndIf

    RestArea(aArea)
Return lRet
