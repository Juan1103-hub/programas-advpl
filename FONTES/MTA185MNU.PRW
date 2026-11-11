// --- Ponto de Entrada: MTA185MNU - Adiciona botao Imprimir no browse da MATA185 ---

#include "Protheus.ch"

User Function MTA185MNU()
    aAdd(aRotina, {"Imprimir", "U_f185ImpRel", 0, 7})
Return

// --- Funcao auxiliar: dialog para informar nr. da SA ---
User Function f185ImpRel()
    Local oDlg      := Nil
    Local cSolic    := Space(TamSx3("CP_NUM")[1])
    Local nOpc      := 0

    Define MSDialog oDlg Title "Impressao de Baixa" From 0,0 To 120,350 Pixel

    @ 10,10 Say "Nr. S.A.:" Of oDlg Pixel
    @ 10,50 MsGet cSolic Size 60,10 Of oDlg Pixel

    Define SButton From 45,100 Type 1 Action (nOpc:=1,oDlg:End()) Enable Of oDlg
    Define SButton From 45,140 Type 2 Action (oDlg:End()) Enable Of oDlg

    Activate MSDialog oDlg Centered

    If nOpc == 1
        f185GerRel(AllTrim(cSolic))
    EndIf
Return

// --- Geracao do relatorio via TReport ---
Static Function f185GerRel(cSolic)
    Local oReport  := Nil
    Local oSection := Nil

    oReport := TReport():New("f185GerRel", "Baixa de Pre-Requisicao ao Armazem", Nil,;
        {|oReport| f185Print(oReport, cSolic)})
    oReport:SetLandscape()
    oReport:oPage:SetPaperSize(9) // A4
    oReport:SetTotalInLine(.F.)
    oReport:nFontBody   := 8
    oReport:lParamPage  := .F.

    oSection := TRSection():New(oReport, "Itens", {"QRY_SA"})
    oSection:SetHeaderSection(.T.)

    TRCell():New(oSection, "CP_NUM",     "QRY_SA", "Nr. SA",         Nil, 09, .F., Nil, "LEFT", Nil, "LEFT")
    TRCell():New(oSection, "CP_ITEM",    "QRY_SA", "Item",           Nil, 06, .F., Nil, "LEFT", Nil, "LEFT")
    TRCell():New(oSection, "CP_PRODUTO", "QRY_SA", "Produto",        Nil, 20, .F., Nil, "LEFT", Nil, "LEFT")
    TRCell():New(oSection, "B1_DESC",    "QRY_SA", "Descricao",      Nil, 135, .F., Nil, "LEFT", Nil, "LEFT")
    TRCell():New(oSection, "ZC1_POSIC",  "QRY_SA", "Posicao",        Nil, 20, .F., Nil, "LEFT", Nil, "LEFT")
    TRCell():New(oSection, "CP_QUANT",   "QRY_SA", "Qtd Req.",       "@E 999,999.99", 12, .F., Nil, "RIGHT", Nil, "RIGHT")

    oReport:PrintDialog()
Return

// --- Logica de impressao ---
Static Function f185Print(oReport, cSolic)
    Local cQuery   := ""
    Local cAlias   := GetNextAlias()
    Local oSection := oReport:Section(1)
    Local cSolicit := ""

    cQuery := "SELECT SCP.CP_NUM, SCP.CP_ITEM, SCP.CP_PRODUTO, SB1.B1_DESC, SCP.CP_SOLICIT, SCP.CP_QUANT, "
    cQuery += "ZC1.ZC1_POSIC "
    cQuery += "FROM " + RetSqlName("SCP") + " SCP "
    cQuery += "LEFT JOIN " + RetSqlName("ZC1") + " ZC1 "
    cQuery += "ON ZC1.ZC1_ITEM = SCP.CP_PRODUTO AND ZC1.D_E_L_E_T_ = ' ' "
    cQuery += "LEFT JOIN " + RetSqlName("SB1") + " SB1 "
    cQuery += "ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' AND SB1.B1_COD = SCP.CP_PRODUTO AND SB1.D_E_L_E_T_ = ' ' "
    cQuery += "WHERE SCP.CP_FILIAL = '0102' "
    cQuery += "AND SCP.CP_NUM = '" + cSolic + "' "
    cQuery += "AND SCP.D_E_L_E_T_ = ' ' "
    cQuery += "ORDER BY SCP.CP_ITEM"

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    oSection:Init()

    // Solicitante no cabecalho (1x por relatorio)
    If !(cAlias)->(Eof())
        cSolicit := AllTrim((cAlias)->CP_SOLICIT)
        oReport:PrintText("Solicitante: " + cSolicit, 0)
        oReport:SkipLine()
    EndIf

    While !(cAlias)->(Eof())
        oSection:Cell("CP_NUM"):SetValue((cAlias)->CP_NUM)
        oSection:Cell("CP_ITEM"):SetValue((cAlias)->CP_ITEM)
        oSection:Cell("CP_PRODUTO"):SetValue((cAlias)->CP_PRODUTO)
        oSection:Cell("B1_DESC"):SetValue((cAlias)->B1_DESC)
        oSection:Cell("ZC1_POSIC"):SetValue((cAlias)->ZC1_POSIC)
        oSection:Cell("CP_QUANT"):SetValue((cAlias)->CP_QUANT)

        oSection:PrintLine()
        (cAlias)->(DbSkip())
    EndDo

    oSection:Finish()
    (cAlias)->(DbCloseArea())
Return
