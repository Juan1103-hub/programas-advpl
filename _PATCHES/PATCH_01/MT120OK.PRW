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

3) Copia de seguranca (pre-save) de C7_XESTOQ1, C7_EC05DB e C7_ZREGUL:
   - O PE MT120TFR replica esses campos da linha 1 quando o usuario
     informa o produto de uma nova linha (gatilho em C7_PRODUTO).
   - Se o usuario preencher a linha 1 APOS as demais linhas ja criadas,
     o gatilho pode nao ter disparado; este PE garante a replicacao
     antes da gravacao, com as mesmas regras: somente linhas manuais
     (C7_NUMSC vazio), nao-deletadas e somente campos vazios.

@type     User Function
@author   Desenvolvimento
@since    25/05/2026
@version  2.1
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
    // BLOCO 2: Copia de seguranca dos campos replicaveis (pre-save)
    // Mesma regra do PE MT120TFR (gatilho em C7_PRODUTO): copia da linha 1
    // para linhas manuais nao-deletadas, somente onde o campo esta vazio.
    // Garante o caso em que a linha 1 foi preenchida depois de criadas
    // as demais linhas (gatilho ainda nao teria disparado).
    // -------------------------------------------------------------------------
    MT120ReplicaSeg()

    // -------------------------------------------------------------------------
    // BLOCO 3: Validacao de conta contabil bloqueada
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

// -------------------------------------------------------------------------
// MT120ReplicaSeg - Copia de seguranca pre-save (ver cabecalho, item 3).
// Copia C7_XESTOQ1, C7_EC05DB e C7_ZREGUL da linha 1 do aCols para as
// demais linhas NAO-deletadas e MANUAIS (C7_NUMSC vazio), somente quando
// o campo destino esta vazio. Mesma regra do MT120TFR:MT120Replica.
// -------------------------------------------------------------------------
Static Function MT120ReplicaSeg()
    Local aCampos := {"C7_XESTOQ1", "C7_EC05DB", "C7_ZREGUL"}
    Local aPos    := {}
    Local nPosSC  := 0
    Local nI      := 0
    Local nC      := 0
    Local nCopias := 0
    Local xOrigem := Nil

    If Type("aCols") == "U" .Or. Type("aHeader") == "U"
        Return
    EndIf

    If Len(aCols) < 2
        Return
    EndIf

    // Sem coluna C7_NUMSC nao e possivel garantir "somente pedido manual"
    nPosSC := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_NUMSC"})
    If nPosSC <= 0 .Or. nPosSC > Len(aCols[1])
        Return
    EndIf

    // Localiza as colunas dos campos a propagar
    For nC := 1 To Len(aCampos)
        AAdd(aPos, aScan(aHeader, {|x| AllTrim(x[2]) == aCampos[nC]}))
    Next nC

    // Linha 1 deletada ou veio de SC -> nada a replicar como fonte manual
    If aCols[1][Len(aCols[1])]
        Return
    EndIf

    If !Empty(aCols[1][nPosSC])
        Return
    EndIf

    For nC := 1 To Len(aCampos)

        If aPos[nC] <= 0 .Or. aPos[nC] > Len(aCols[1])
            Loop
        EndIf

        xOrigem := aCols[1][aPos[nC]]

        // Origem vazia ou de tipo inesperado -> nao propaga este campo
        If ValType(xOrigem) != "C" .Or. Empty(xOrigem)
            Loop
        EndIf

        For nI := 2 To Len(aCols)

            // Pula linhas deletadas
            If aCols[nI][Len(aCols[nI])]
                Loop
            EndIf

            // Pula linhas originadas de Solicitacao de Compra
            If !Empty(aCols[nI][nPosSC])
                Loop
            EndIf

            // So preenche onde esta vazio (preserva edicao manual)
            If Empty(aCols[nI][aPos[nC]])
                aCols[nI][aPos[nC]] := xOrigem
                nCopias++
            EndIf

        Next nI

    Next nC

    If nCopias > 0
        FWLogMsg("INFO", , "SUPR", "MT120OK", , "01", ;
                 "MT120ReplicaSeg - " + cValToChar(nCopias) + " campo(s) copiado(s) da linha 1 antes da gravacao")
    EndIf

Return
