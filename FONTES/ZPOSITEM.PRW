#Include "Protheus.ch"
#Include "TopConn.ch"

#Define CRLF Chr(13) + Chr(10)

//-------------------------------------------------------------------
/*/{Protheus.doc} FFZC1ITM
Regra de gatilho SX7 no campo ZC1_ITEM do AxCadastro ZC1 (CADPOSIC).

Ao informar o item, preenche automaticamente:
  ZC1_DESCRI <- SB1->B1_DESC
  ZC1_LOCAL  <- armazem da SB2 com B2_QATU > 0 (preferencia, 1o na
                ordem do indice) ou o 1o armazem existente (fallback)
  ZC1_SALDO  <- SB2->B2_QATU do armazem escolhido

O retorno alimenta o X7_CDOMIN (ZC1_SALDO). Os demais campos sao
gravados via M-> (buffer do formulario do AxCadastro) - mesmo padrao
de FFZZ4A2/MT110EMI.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   2026
@return  nSaldo, numeric, saldo do armazem escolhido (para X7_CDOMIN)
/*/
//-------------------------------------------------------------------
User Function FFZC1ITM()

    Local aArea    := GetArea()
    Local aAreaSB1 := {}
    Local aAreaSB2 := {}
    Local cItem    := ""
    Local cLocal   := ""
    Local cLocPref := ""
    Local cLocFbk  := ""
    Local nSaldo   := 0
    Local nSalPref := 0
    Local nSalFbk  := 0
    Local lPref    := .F.

    // Campo origem vazio: nada a preencher
    If Empty(M->ZC1_ITEM)
        RestArea(aArea)
        Return 0
    EndIf

    // --- SB1: descricao (ordem 1 = B1_FILIAL + B1_COD) ---
    If Select("SB1") <= 0
        ChkFile("SB1")
    EndIf

    If Select("SB1") > 0
        aAreaSB1 := SB1->(GetArea())
        DbSelectArea("SB1")
        SB1->(DbSetOrder(1))
        cItem := PadR(AllTrim(M->ZC1_ITEM), TamSX3("B1_COD")[1])
        If SB1->(DbSeek(xFilial("SB1") + cItem))
            M->ZC1_DESCRI := PadR(SB1->B1_DESC, TamSX3("ZC1_DESCRI")[1])
        Else
            M->ZC1_DESCRI := Space(TamSX3("ZC1_DESCRI")[1])
        EndIf
        RestArea(aAreaSB1)
    EndIf

    // --- SB2: local com saldo (ordem 1 = B2_FILIAL + B2_COD + B2_LOCAL) ---
    If Select("SB2") <= 0
        ChkFile("SB2")
    EndIf

    If Select("SB2") > 0
        aAreaSB2 := SB2->(GetArea())
        DbSelectArea("SB2")
        SB2->(DbSetOrder(1))
        cItem := PadR(AllTrim(M->ZC1_ITEM), TamSX3("B2_COD")[1])

        If SB2->(DbSeek(xFilial("SB2") + cItem))
            While !SB2->(Eof()) .And. SB2->B2_FILIAL == xFilial("SB2") .And. SB2->B2_COD == cItem
                // 1o armazem existente (fallback)
                If !lPref .And. Empty(cLocFbk)
                    cLocFbk := SB2->B2_LOCAL
                    nSalFbk := SB2->B2_QATU
                EndIf
                // 1o armazem COM saldo (preferencia do requisito)
                If !lPref .And. SB2->B2_QATU > 0
                    cLocPref := SB2->B2_LOCAL
                    nSalPref := SB2->B2_QATU
                    lPref    := .T.
                EndIf
                SB2->(DbSkip())
            EndDo
        EndIf

        // Preferencia > fallback > vazio
        If lPref
            cLocal := cLocPref
            nSaldo := nSalPref
        ElseIf !Empty(cLocFbk)
            cLocal := cLocFbk
            nSaldo := nSalFbk
        EndIf

        M->ZC1_LOCAL := PadR(cLocal, TamSX3("ZC1_LOCAL")[1])
        M->ZC1_SALDO := nSaldo

        RestArea(aAreaSB2)
    EndIf

    RestArea(aArea)

Return nSaldo
