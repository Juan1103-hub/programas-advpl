#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} MT110TOK
Validacao TudoOK da Solicitacao de Compra (MATA110).

Responsabilidade unica:
  Bloquear inclusao/alteracao de itens cujo produto possui estoque
  de seguranca (B1_ESTSEG > 0), exceto para usuarios autorizados.
    Tambem garante que C1_EMISSAO fique com a data original nos itens
    existentes e com dDataBase apenas nos itens novos.

Usuarios liberados: 000047, 000080, 000095, 000057.

Obs.: A regra de C1_EMISSAO / C1_DATPRF foi centralizada em MT110CON v4.
      Snapshot aZ110Snap removido em 02/06/2026.

@type     user function
@author   Eurai Rapelli / Suprimentos
@since    2023.01.01
@version  4.2 - 07/06/2026 - Date() em vez de dDataBase para C1_EMISSAO de novos
@return   logical, .T. = Permite gravar | .F. = Bloqueia
/*/
User Function MT110TOK()
    Local aArea      := GetArea()
    Local aAreaSC1   := SC1->(GetArea())
    Local lRet       := .T.
    Local nX         := 0
    Local nPosEmiss  := 0
    Local nPosNum    := 0
    Local nPosItem   := 0
    Local cProduto   := ""
    Local cNumSC     := ""
    Local cItemSC    := ""
    Local nEstSeg    := 0
    Local cUserMat   := ""
    Local aUsersLib  := {"000047", "000080", "000095", "000057"}
    Local lUserLib   := .F.
    Local cMsgItens  := ""
    Local lBloqueado := .F.
    Local lLinhaNova := .T.
    Local dEmissNova := Date()             // data real do servidor (nao dDataBase)

    cUserMat := RetCodUsr()
    lUserLib := (aScan(aUsersLib, {|x| AllTrim(x) == AllTrim(cUserMat)}) > 0)

    If lUserLib
        RestArea(aAreaSC1)
        RestArea(aArea)
        Return .T.
    EndIf

    nPosEmiss := aScan(aHeader, {|x| AllTrim(Upper(x[2])) == "C1_EMISSAO"})
    nPosNum   := aScan(aHeader, {|x| AllTrim(Upper(x[2])) == "C1_NUM"    })
    nPosItem  := aScan(aHeader, {|x| AllTrim(Upper(x[2])) == "C1_ITEM"   })

    If nPosEmiss > 0
        SC1->(DbSetOrder(1))
    EndIf

    For nX := 1 To Len(aCols)

        If aCols[nX][Len(aCols[nX])]
            Loop
        EndIf

        cProduto := GdFieldGet("C1_PRODUTO", nX)

        If Empty(cProduto)
            Loop
        EndIf

        DbSelectArea("SB1")
        SB1->(DbSetOrder(1))

        If SB1->(DbSeek(xFilial("SB1") + cProduto))
            nEstSeg := SB1->B1_ESTSEG
            If nEstSeg > 0
                cMsgItens += AllTrim(cProduto) + CRLF
                lBloqueado := .T.
            EndIf
        EndIf

        // Ajuste de emissao por linha: novo => Date() | existente => data original do banco
        If nPosEmiss > 0
            lLinhaNova := .T.
            cNumSC  := ""
            cItemSC := ""

            If nPosNum > 0
                cNumSC := AllTrim(cValToChar(aCols[nX][nPosNum]))
            EndIf
            If nPosItem > 0
                cItemSC := AllTrim(cValToChar(aCols[nX][nPosItem]))
            EndIf

            If !Empty(cNumSC) .And. !Empty(cItemSC)
                If SC1->(DbSeek(xFilial("SC1") + cNumSC + cItemSC))
                    lLinhaNova := .F.
                    aCols[nX][nPosEmiss] := SC1->C1_EMISSAO
                EndIf
            EndIf

            If lLinhaNova
                aCols[nX][nPosEmiss] := dEmissNova
            EndIf
        EndIf

    Next nX

    If lBloqueado
        MsgStop("ITEM CONTROLADO POR MINIMO/MAXIMO." + CRLF + CRLF + ;
                "COMPRA BLOQUEADA PARA SEU USUARIO." + CRLF + CRLF + ;
                "Itens bloqueados:" + CRLF + CRLF + ;
                cMsgItens + CRLF + ;
                "SOLICITE LIBERACAO AO SUPRIMENTOS.", ;
                "Acesso Negado")
        lRet := .F.
    EndIf

    RestArea(aArea)
    RestArea(aAreaSC1)

Return lRet
