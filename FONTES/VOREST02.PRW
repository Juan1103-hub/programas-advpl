#INCLUDE "PROTHEUS.CH"

#DEFINE CRLF   Chr(13)+Chr(10)
//-------------------------------------------------------------------
/*/{Protheus.doc} VOREST02
Módulo SIGAEST - Relatório de Reposição de Estoque
@author Juvenil G. Souza
@since 12/01/2025
@version 1.0
/*/
//-------------------------------------------------------------------
User Function VOREST02()
    Local oReport
    Local aPergs    := {}
    Local aResps    := {}
    Local aOpcoes   := {"COM Min Max", "SEM Min Max"}

    aAdd(aPergs, {1, "Filial:",        Criavar("C7_FILIAL",.F.),, "", "SM0", ".T.", 30, .F.})
    aAdd(aPergs, {1, "Produto De:",    Criavar("B1_COD",.F.),, "", "SB1", ".T.", 80, .F.})
    aAdd(aPergs, {1, "Produto Até:",   Replicate("Z",TamSX3("B1_COD")[1]),, "", "SB1", ".T.", 80, .F.})
    aAdd(aPergs, {2, "Tipo relatório:", "COM Min Max", aOpcoes, 55, "", .T.})

    If ParamBox(aPergs, "Parâmetros do relatório", @aResps,,,,,,,, .T., .T.)
        oReport := ReportDef(aResps)
        oReport:PrintDialog()
    EndIf

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} ReportDef
Definicoes do relatorio
@author Juvenil G. Souza
@since 12/01/2025
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ReportDef(aResps)
    Local oReport    := Nil
    Local oSection1  := Nil
    Local cNomArq    := "VOREST02_" + DToS(Date()) + StrTran(Time(),":","")
    Local cTitulo    := "Rel. Posicao de estoque"

    oReport := TReport():New(cNomArq, cTitulo, "", {|oReport| ReportPrint(oReport, aResps)}, "Relatório de Reposição de Estoque")
    oReport:SetTotalInLine(.F.)
    oReport:ShowHeader()
    oReport:SetLandScape(.T.)
    oReport:HideParamPage()

    oSection1 := TRSection():New(oReport, "REPOSIÇÃO DE ESTOQUE", {"SX5"})
    oSection1:SetTotalInLine(.F.)

    TRCell():New(oSection1, "CODIGO",       "QRY_REP", 'Código',           "", 20)
    TRCell():New(oSection1, "DESCRICAO",    "QRY_REP", 'Descrição',        "", 50)
    TRCell():New(oSection1, "UM",           "QRY_REP", 'UM',               "@!", 04)
    TRCell():New(oSection1, "INCLUSAO",     "QRY_REP", 'DT Inclusao',      "@!", 10)
    TRCell():New(oSection1, "ALTERACAO",    "QRY_REP", 'DT Alteracao',     "@!", 10)
    TRCell():New(oSection1, "DTCOMPRA",     "QRY_REP", 'Dt ult.Compra',    "@!", 10)
    TRCell():New(oSection1, "DTENTRADA",    "QRY_REP", 'Dt ult.Entrada',   "@!", 10)
    TRCell():New(oSection1, "DTBAIXA",      "QRY_REP", 'Dt ult.Baixa',     "@!", 10)
    TRCell():New(oSection1, "JUSTIFIC",     "QRY_REP", 'Justificativa',    "@!", 60)
    TRCell():New(oSection1, "MINIMO",       "QRY_REP", 'Minimo',           "@E 9,999,999", 15)
    TRCell():New(oSection1, "MAXIMO",       "QRY_REP", 'Máximo',           "@E 9,999,999", 15)
    TRCell():New(oSection1, "SALDO",        "QRY_REP", 'Saldo Atual',      "@E 9,999,999", 15)
    TRCell():New(oSection1, "PRECO",        "QRY_REP", 'Preço Unitário',   "@E 9999,999.99", 15)
    TRCell():New(oSection1, "CUSTOMEDIO",   "QRY_REP", 'Custo Médio',      "@E 9999,999.9999", 18)
    TRCell():New(oSection1, "VALOR",        "QRY_REP", 'Valor em estoque', "@E 9999,999.99", 15)
    TRCell():New(oSection1, "SC",           "QRY_REP", 'SC em aberto',     "@E 9,999,999", 15)
    TRCell():New(oSection1, "PC",           "QRY_REP", 'PC em aberto',     "@E 9,999,999", 15)
    TRCell():New(oSection1, "PROJETADO",    "QRY_REP", 'Saldo Projetado',  "@E 9,999,999", 15)
    TRCell():New(oSection1, "QTDECOMPRA",   "QRY_REP", 'Qtdade Comprar',   "@E 99,999,999", 15)
    TRCell():New(oSection1, "STATUS",       "QRY_REP", 'Status',           "@!", 45)
    TRCell():New(oSection1, "CRITICIDADE",  "QRY_REP", 'Criticidade',      "@!", 20)
    TRCell():New(oSection1, "FAMILIA",      "QRY_REP", 'Família Prod.',    "@!", 30)

    oSection1:SetTotalInLine(.F.)
    oSection1:SetPageBreak(.T.)
    oSection1:SetTotalText(" ")

Return oReport

//-------------------------------------------------------------------
/*/{Protheus.doc} ReportPrint
Execução da query e impressao do relatorio
@author Juvenil G. Souza
@since 12/01/2025
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ReportPrint(oReport, aResps)
    Local oSection1     := oReport:Section(1)
    Local cQuery        := ""
    Local nAtual        := 0
    Local nTotal        := 0
    Local cFil          := aResps[1]
    Local cProdDe       := aResps[2]
    Local cProdate      := aResps[3]
    Local cTipo         := aResps[4]
    Local cStatus       := ""
    Local nQtdecomp     := 0
    Local cCRITICIDADE  := ""
    Local cFamilia      := ""

    cQuery := " SELECT B1_COD, B1_DESC, B1_UM, B1_ESTSEG, B1_EMAX, B2_QATU, B2_CM1, B1_ZDTINC, B1_ZDTALT," + CRLF
    cQuery += " B1_ZJUSTIF, B1_UPRC, B1_ZCRIT, B1_ZFAMIL, " + CRLF
    cQuery += " (SELECT SUM(C1_QUANT - C1_QUJE) FROM "+RetSqlname("SC1")+" SC1 WHERE SC1.D_E_L_E_T_ <>'*' AND C1_COTACAO = '' AND C1_QUJE < C1_QUANT " + CRLF
    cQuery += " AND C1_RESIDUO <> 'S' AND C1_PRODUTO = B1_COD AND C1_FILIAL = '"+cFil+"' ) AS SOLICOMP," + CRLF
    cQuery += " (SELECT MAX(D1_DTDIGIT) FROM "+RetSqlname("SD1")+" SD1 WHERE SD1.D_E_L_E_T_ = '' AND D1_COD = B1_COD AND D1_FILIAL ='"+cFil+"' ) AS DTNF, " + CRLF
    cQuery += " (SELECT MAX(D3_EMISSAO) FROM "+RetSqlname("SD3")+" SD3 WHERE SD3.D_E_L_E_T_ = '' AND D3_COD = B1_COD AND D3_FILIAL ='"+cFil+"' AND D3_TM NOT IN ('499','999') ) AS DTBAIXA, " + CRLF
    cQuery += " (SELECT MAX(C7_DATPRF)  FROM "+RetSqlname("SC7")+" SC7 WHERE SC7.D_E_L_E_T_ = '' AND C7_RESIDUO <> 'S' AND C7_PRODUTO = B1_COD " + CRLF
    cQuery += " AND C7_FILIAL ='"+cFil+"' ) AS DTPEDIDO, " + CRLF
    cQuery += " (SELECT SUM(CASE WHEN C7_ACCPROC <> '1' AND C7_CONAPRO = 'B' THEN 1 ELSE (C7_QUANT - C7_QUJE) END)" + CRLF
    cQuery += "   FROM "+RetSqlname("SC7")+" SC7 WHERE SC7.D_E_L_E_T_ = '' AND C7_QUJE < C7_QUANT AND C7_RESIDUO = '' " + CRLF
    cQuery += " AND C7_PRODUTO = B1_COD AND C7_FILIAL = '"+cFil+"' " + CRLF
    cQuery += " AND NOT (C7_ACCPROC <> '1' AND C7_CONAPRO = 'R' AND C7_QUJE < C7_QUANT) ) AS PEDCSALD " + CRLF
    cQuery += " FROM "+RetSqlName("SB1")+" SB1 " + CRLF
    cQuery += " LEFT JOIN "+RetSqlName("SB2")+" SB2 ON " + CRLF
    cQuery += " SB2.D_E_L_E_T_ = ' ' AND B1_COD=B2_COD AND B2_LOCAL = '02' AND B2_FILIAL = '"+cFil+"' " + CRLF
    cQuery += " WHERE SB1.D_E_L_E_T_ = '' " + CRLF

    If UPPER(cTipo) == "COM MIN MAX"
        cQuery += " AND B1_ESTSEG > 0 " + CRLF
    Else
        cQuery += " AND B1_ESTSEG = 0 AND B1_ZREPOS = 'S' " + CRLF
    EndIf

    cQuery += " AND B1_COD BETWEEN '" + cProdDe + "' AND '" + cProdate + "' " + CRLF

    MemoWrite("C:\erp\sql\VOREST002-01.SQL", cQuery)
    PlsQuery(cQuery, "QRY_REP")

    DbSelectArea("QRY_REP")
    Count to nTotal
    oReport:SetMeter(nTotal)

    QRY_REP->(DbGoTop())

    While !QRY_REP->(Eof())
        If oReport:Cancel()
            Exit
        EndIf

        oSection1:Init()
        nAtual++
        oReport:Incmeter()
        oReport:SetMsgPrint("Imprimindo registro " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")

        oSection1:Cell("CODIGO"):SetValue(QRY_REP->B1_COD)
        oSection1:Cell("CODIGO"):SetAlign("LEFT")

        oSection1:Cell("DESCRICAO"):SetValue(QRY_REP->B1_DESC)
        oSection1:Cell("DESCRICAO"):SetAlign("LEFT")

        oSection1:Cell("UM"):SetValue(QRY_REP->B1_UM)
        oSection1:Cell("UM"):SetAlign("LEFT")

        oSection1:Cell("INCLUSAO"):SetValue(QRY_REP->B1_ZDTINC)
        oSection1:Cell("INCLUSAO"):SetAlign("CENTER")

        oSection1:Cell("ALTERACAO"):SetValue(QRY_REP->B1_ZDTALT)
        oSection1:Cell("ALTERACAO"):SetAlign("CENTER")

        oSection1:Cell("DTCOMPRA"):SetValue(StoD(QRY_REP->DTPEDIDO))
        oSection1:Cell("DTCOMPRA"):SetAlign("LEFT")

        oSection1:Cell("DTENTRADA"):SetValue(StoD(QRY_REP->DTNF))
        oSection1:Cell("DTENTRADA"):SetAlign("LEFT")

        oSection1:Cell("DTBAIXA"):SetValue(StoD(QRY_REP->DTBAIXA))
        oSection1:Cell("DTBAIXA"):SetAlign("LEFT")

        oSection1:Cell("JUSTIFIC"):SetValue(QRY_REP->B1_ZJUSTIF)
        oSection1:Cell("JUSTIFIC"):SetAlign("LEFT")

        oSection1:Cell("MINIMO"):SetValue(QRY_REP->B1_ESTSEG)
        oSection1:Cell("MINIMO"):SetAlign("RIGHT")

        oSection1:Cell("MAXIMO"):SetValue(QRY_REP->B1_EMAX)
        oSection1:Cell("MAXIMO"):SetAlign("RIGHT")

        oSection1:Cell("SALDO"):SetValue(QRY_REP->B2_QATU)
        oSection1:Cell("SALDO"):SetAlign("RIGHT")

        oSection1:Cell("PRECO"):SetValue(QRY_REP->B1_UPRC)
        oSection1:Cell("PRECO"):SetAlign("RIGHT")

        oSection1:Cell("CUSTOMEDIO"):SetValue(QRY_REP->B2_CM1)
        oSection1:Cell("CUSTOMEDIO"):SetAlign("RIGHT")

        oSection1:Cell("VALOR"):SetValue(QRY_REP->B2_QATU * QRY_REP->B1_UPRC)
        oSection1:Cell("VALOR"):SetAlign("RIGHT")

        oSection1:Cell("SC"):SetValue(QRY_REP->SOLICOMP)
        oSection1:Cell("SC"):SetAlign("RIGHT")

        oSection1:Cell("PC"):SetValue(QRY_REP->PEDCSALD)
        oSection1:Cell("PC"):SetAlign("RIGHT")

        oSection1:Cell("PROJETADO"):SetValue(QRY_REP->B2_QATU + QRY_REP->SOLICOMP + QRY_REP->PEDCSALD)
        oSection1:Cell("PROJETADO"):SetAlign("RIGHT")

        cStatus   := ""
        nQtdecomp := 0

        If QRY_REP->B1_EMAX + QRY_REP->B1_ESTSEG = 0
            cStatus := "Solicitar Compra"
            If (QRY_REP->B2_QATU + QRY_REP->SOLICOMP + QRY_REP->PEDCSALD) > 0
                cStatus := "Estoque OK"
            EndIf
        Else
            If (QRY_REP->B2_QATU + QRY_REP->SOLICOMP + QRY_REP->PEDCSALD) > QRY_REP->B1_EMAX
                cStatus := "Estoque no Máximo"
            ElseIf (QRY_REP->B2_QATU + QRY_REP->SOLICOMP + QRY_REP->PEDCSALD) <= QRY_REP->B1_ESTSEG
                cStatus := "Solicitar Compra"
                nQtdecomp := QRY_REP->B1_EMAX - (QRY_REP->B2_QATU + QRY_REP->SOLICOMP + QRY_REP->PEDCSALD)
            ElseIf (QRY_REP->B2_QATU + QRY_REP->SOLICOMP + QRY_REP->PEDCSALD) >= QRY_REP->B1_ESTSEG .AND. ;
                   (QRY_REP->B2_QATU + QRY_REP->SOLICOMP + QRY_REP->PEDCSALD) <= QRY_REP->B1_EMAX
                cStatus := "Estoque OK"
            EndIf
        EndIf

        oSection1:Cell("QTDECOMPRA"):SetValue(nQtdecomp)
        oSection1:Cell("QTDECOMPRA"):SetAlign("RIGHT")

        oSection1:Cell("STATUS"):SetValue(cStatus)
        oSection1:Cell("STATUS"):SetAlign("LEFT")

        cCRITICIDADE := ""
        Do Case
            Case QRY_REP->B1_ZCRIT == "A"
                cCRITICIDADE := "MUITO CRITICO"
            Case QRY_REP->B1_ZCRIT == "B"
                cCRITICIDADE := "CRITICIDADE MEDIA"
            Case QRY_REP->B1_ZCRIT == "C"
                cCRITICIDADE := "POUCO CRITICO"
        EndCase

        oSection1:Cell("CRITICIDADE"):SetValue(cCRITICIDADE)
        oSection1:Cell("CRITICIDADE"):SetAlign("LEFT")

        cFamilia := ""
        DbSelectArea("SZ5")
        SZ5->(DbSetOrder(1))
        If SZ5->(DbSeek(xFilial("SZ5") + QRY_REP->B1_ZFAMIL))
            cFamilia := SZ5->Z5_FAMIL
        EndIf

        oSection1:Cell("FAMILIA"):SetValue(cFamilia)
        oSection1:Cell("FAMILIA"):SetAlign("LEFT")

        oSection1:Printline()
        QRY_REP->(DbSkip())
    EndDo

    oSection1:Finish()
    QRY_REP->(DbCloseArea())

Return