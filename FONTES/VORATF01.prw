#Include "Protheus.ch"

/*/{Protheus.doc} User Function ACRCOM03
Módulo SIGACOM - Compras
@author juvenil . Souza  Conti Consultoria 
@since 14/07/2025
@version 1.0
/*/


User Function VORATF01()

	Local aPergs	  := {}
	Local aResps	  := {}
	Local oReport
	Local aArea		   := FWGetArea()
	Local cLoadName  := "VORATF01"
	Private cTitulo  := ""
	Private cVlmes2  := ""
	Private cVlmes3  := ""
	Private cVlmes4  := ""
	Private cAno1    := ""
	Private cAno2    := ""
	Private cAno3    := ""
	Private cAno4    := ""
	Private cAno5    := ""
	Private cAno6    := ""
	Private cAno7    := ""
	Private cAno8    := ""
	Private cAno9    := ""
	Private cAno10   := ""
	Private cAno11   := ""
	Private cAno12   := ""
	Private cMes1    := ""
	Private cMes2    := ""
	Private cMes3    := ""
	Private cMes4    := ""
	Private cMes5    := ""
	Private cMes6    := ""
	Private cMes7    := ""
	Private cMes8    := ""
	Private cMes9    := ""
	Private cMes10   := ""
	Private cMes11   := ""
	Private cMes12   := ""
	Private cUltMes1 := ""
	Private cUltMes2 := ""
	Private cUltMes3 := ""
	Private cUltMes4 := ""
	Private cLegMes1 := ""
	Private cLegMes2 := ""
	Private cLegMes3 := ""
	Private cLegMes4 := ""
	Private cLegMes5 := ""
	Private cLegMes6 := ""
	Private cLegMes7 := ""
	Private cLegMes8 := ""
	Private cLegMes9 := ""
	Private cLegMes10:= ""
	Private cLegMes11:= ""
	Private cLegMes12:= ""

	aAdd(aPergs, {1, "Bem De:" , CriaVar("N1_CBASE",.F.),,, "SN1", ".T.", 80,  .F.})
	aAdd(aPergs, {1, "Bem Até:", Replicate("Z",TamSX3("N1_CBASE")[1]),, "", "SN1", ".T.", 80,  .F.})
	aAdd(aPergs, {1, "Inclusão Bem  De:"  , CriaVar("N1_AQUISIC",.F.),,, "", ".T.", 80,  .F.})
	aAdd(aPergs, {1, "Inclusão Bem Até:"  , CriaVar("N1_AQUISIC",.F.),,, "", ".T.", 80,  .T.})
	aAdd(aPergs, {1, "Data Depreciação:"  , CriaVar("N1_AQUISIC",.F.),,, "", ".T.", 80,  .T.})
	aAdd(aPergs, {1, "C.Contabil Bem  De:" , CriaVar("N3_CCONTAB",.F.),,, "CT1", ".T.", 80,  .F.})
	aAdd(aPergs, {1, "C.Contabil Bem Até:", Replicate("Z",TamSX3("N3_CCONTAB")[1]),, "", "CT1", ".T.", 80,  .F.})
	aAdd(aPergs, {1, "C.Depreciação  De:" , CriaVar("N3_CCONTAB",.F.),,, "CT1", ".T.", 80,  .F.})
	aAdd(aPergs, {1, "C.Depreciação Até:", Replicate("Z",TamSX3("N3_CCONTAB")[1]),, "", "CT1", ".T.", 80,  .F.})

	If ParamBox(aPergs, "Informe os parâmetros", @aResps,  /*bOk*/, /*aButtons*/, /*lCentered*/, /*nPosx*/, /*nPosy*/, /*oDlgWizard*/, cLoadName, .T., .T.)
		Ctitulo   := "Depreciação Acumulada - ATF "
		ParamSave(cLoadName, aResps, "1")
		cAno1        := str(year((aResps[5])),4)
		cAno2        := str(year((aResps[5])),4)
		cAno3        := str(year((aResps[5])),4)
		cAno4        := str(year((aResps[5])),4)
		cAno5        := str(year((aResps[5])),4)
		cAno6        := str(year((aResps[5])),4)
		cAno7        := str(year((aResps[5])),4)
		cAno8        := str(year((aResps[5])),4)
		cAno9        := str(year((aResps[5])),4)
		cAno10       := str(year((aResps[5])),4)
		cAno11       := str(year((aResps[5])),4)
		cAno12       := str(year((aResps[5])),4)
		cMes1        := strzero(month(aResps[5]),2)

		cAnoV1 := cAno1

		If month(aResps[5]) >= 1 .AND. month(aResps[5]) <= 11
			cAno12  := strzero(year(aResps[5])-1,4)
		Endif
		if month(aResps[5]) >= 1 .AND. month(aResps[5]) <= 10
			cAno11  := strzero(year(aResps[5])-1,4)
		Endif
		if month(aResps[5]) >= 1 .AND. month(aResps[5]) <= 9
			cAno10  := strzero(year(aResps[5])-1,4)
		Endif
		if month(aResps[5]) >= 1 .AND. month(aResps[5]) <= 8
			cAno9  := strzero(year(aResps[5])-1,4)
		Endif
		if month(aResps[5]) >= 1 .AND. month(aResps[5]) <= 7
			cAno8  := strzero(year(aResps[5])-1,4)
		Endif

		if month(aResps[5]) >= 1 .AND. month(aResps[5]) <= 6
			cAno7  := strzero(year(aResps[5])-1,4)
		Endif
		if month(aResps[5]) >= 1 .AND. month(aResps[5]) <= 5
			cAno6  := strzero(year(aResps[5])-1,4)
		Endif

		if month(aResps[5]) >= 1 .AND. month(aResps[5]) <= 4
			cAno5  := strzero(year(aResps[5])-1,4)
		Endif

		if month(aResps[5]) >= 1 .AND. month(aResps[5]) <= 3
			cAno4  := strzero(year(aResps[5])-1,4)
		Endif

		if month(aResps[5]) >= 1 .AND. month(aResps[5]) <= 2
			cAno3  := strzero(year(aResps[5])-1,4)
		Endif

		if month(aResps[5]) = 1
			cAno02  := strzero(year(aResps[5])-1,4)
		Endif


		cMes2   := strzero(month(MonthSub(aResps[5], 1)),2)
		cMes3   := strzero(month(MonthSub(aResps[5], 2)),2)
		cMes4   := strzero(month(MonthSub(aResps[5], 3)),2)
		cMes5   := strzero(month(MonthSub(aResps[5], 4)),2)
		cMes6   := strzero(month(MonthSub(aResps[5], 5)),2)
		cMes7   := strzero(month(MonthSub(aResps[5], 6)),2)
		cMes8   := strzero(month(MonthSub(aResps[5], 7)),2)
		cMes9   := strzero(month(MonthSub(aResps[5], 8)),2)
		cMes10  := strzero(month(MonthSub(aResps[5], 9)),2)
		cMes11  := strzero(month(MonthSub(aResps[5], 10)),2)
		cMes12  := strzero(month(MonthSub(aResps[5], 11)),2)

		cLegMes1  := strzero(Last_day(ctod("01/"+cMes1+"/"+cAno1)),2)+"/"+cMes1+"/"+cAno1
		cLegMes2  := strzero(Last_day(ctod("01/"+cMes2+"/"+cAno2)),2)+"/"+cMes2+"/"+cAno2
		cLegMes3  := strzero(Last_day(ctod("01/"+cMes3+"/"+cAno3)),2)+"/"+cMes3+"/"+cAno3
		cLegMes4  := strzero(Last_day(ctod("01/"+cMes4+"/"+cAno4)),2)+"/"+cMes4+"/"+cAno4
		cLegMes5  := strzero(Last_day(ctod("01/"+cMes5+"/"+cAno5)),2)+"/"+cMes5+"/"+cAno5
		cLegMes6  := strzero(Last_day(ctod("01/"+cMes6+"/"+cAno6)),2)+"/"+cMes6+"/"+cAno6
		cLegMes7  := strzero(Last_day(ctod("01/"+cMes7+"/"+cAno7)),2)+"/"+cMes7+"/"+cAno7
		cLegMes8  := strzero(Last_day(ctod("01/"+cMes8+"/"+cAno8)),2)+"/"+cMes8+"/"+cAno8
		cLegMes9  := strzero(Last_day(ctod("01/"+cMes9+"/"+cAno9)),2)+"/"+cMes9+"/"+cAno9
		cLegMes10 := strzero(Last_day(ctod("01/"+cMes10+"/"+cAno10)),2)+"/"+cMes10+"/"+cAno10
		cLegMes11 := strzero(Last_day(ctod("01/"+cMes11+"/"+cAno11)),2)+"/"+cMes11+"/"+cAno11
		cLegMes12 := strzero(Last_day(ctod("01/"+cMes12+"/"+cAno12)),2)+"/"+cMes12+"/"+cAno12

		cUltMes1 := dtos(ctod(cLegMes1))
		cUltMes2 := dtos(ctod(cLegMes2))
		cUltMes3 := dtos(ctod(cLegMes3))
		cUltMes4 := dtos(ctod(cLegMes4))
		cUltMes5 := dtos(ctod(cLegMes5))
		cUltMes6 := dtos(ctod(cLegMes6))
		cUltMes7 := dtos(ctod(cLegMes7))
		cUltMes8 := dtos(ctod(cLegMes8))
		cUltMes9 := dtos(ctod(cLegMes9))
		cUltMes10 := dtos(ctod(cLegMes10))
		cUltMes11 := dtos(ctod(cLegMes11))
		cUltMes12 := dtos(ctod(cLegMes12))


		/*  alert("*** cUltmes1 = "+cUltmes1)
	  	alert("*** cUltmes2 = "+cUltmes2)
	    alert("*** cUltmes3 = "+cUltmes3)
			alert("*** cUltmes4 = "+cUltmes4) 
	    alert("*** cUltmes5 = "+cUltmes5) 
			alert("*** cUltmes6 = "+cUltmes6) 
			alert("*** cUltmes7 = "+cUltmes7) 
			alert("*** cUltmes8 = "+cUltmes8) 
			alert("*** cUltmes9 = "+cUltmes9) 
			alert("*** cUltmes10 = "+cUltmes10) 
			alert("*** cUltmes11 = "+cUltmes11) 
			alert("*** cUltmes12 = "+cUltmes12) */

		oReport := fReportDef(aResps)
		oReport:PrintDialog()
	EndIf

	FWRestArea(aArea)

Return

Static Function fReportDef(aResps)

	Local oReport
	Local oSection 	:= Nil
	Local cNomArq   := "VORATF01-"+SubStr( time(), 4, 2 )
	// Local Ctitulo   := " "

	//Criacao do componente de impressao
	oReport := TReport():New(cNomArq, cTitulo, "", {|oReport| ReportPrint(oReport, aResps)}, "Este programa tem como objetivo imprimir informações do relatório.")
	oReport:SetTotalInLine(.F.)
	oReport:lParamPage := .F.
	oReport:oPage:SetPaperSize(9)

	//Orientacao do Relatorio
	oReport:SetLandscape()
	oReport:lBold := .T.

	//Criando a secao de dados
	oSection  := TRSection():New(oReport,"Dados",{"QRY_ATF6"})
	oSection:SetTotalInLine(.F.)

	//Colunas do relatorio
	TRCell():New(oSection, "FILIAL", 		 "QRY_ATF", "FILIAL", "@!", 			15, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "BEM", 		     "QRY_ATF", "BEM", "@!", 				30, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "ITEM", 	         "QRY_ATF", "ITEM", "@!", 				20, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", .F., "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "DESCRICAO",      "QRY_ATF", "DESCRIÇÃO", "@!", 	 	 	130, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", .F., "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "TIPO", 	         "QRY_ATF", "TIPO ATIVO", "@!",			20, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", .F., "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "AQUISICAO",      "QRY_ATF", "AQUISIÇÃO", "@!", 			25, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", .F., "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "BAIXA",          "QRY_ATF", "DATA DA BAIXA", "@!", 		25, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", .F., "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "NOTAFISCAL",     "QRY_ATF", "NOTA FISCAL", "@!", 		35, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "SERIE",          "QRY_ATF", "SERIE", "@!", 		    	20, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "INIDEPRE",       "QRY_ATF", "DT.INIC.DEPR.", "@!", 		25, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "CCONTABIL",      "QRY_ATF", "C.CONTABIL","@!",     		35, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "CDEPRECIA",      "QRY_ATF", "C.DEPREC.ACUM.","@!",     	35, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "CDEPREC",        "QRY_ATF", "C.DESPESA DEPR.","@!",     35, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "TAXAANO",        "QRY_ATF", "TX.DEPR.ANO", "@E 999",	35, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "TAXAMES",        "QRY_ATF", "TX.DEPRECIACAO", "@E 999.999999",	35, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "ORIGINAL",       "QRY_ATF", "VL.BEM", "@E 999,999,999.99",		50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "VLMES",  	     "QRY_ATF", "VL.DEPREC.", "@E 999,999,999.99",	50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "SALDO",  	     "QRY_ATF", "VL.SALDO.", "@E 999,999,999.99",	50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
    TRCell():New(oSection, "VLMES1",  	     "QRY_ATF", cLegMes1, "@E 999,999,999.99",		50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "VLMES2",  	     "QRY_ATF", cLegMes2, "@E 999,999,999.99",		50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "VLMES3",  	     "QRY_ATF", cLegMes3, "@E 999,999,999.99",		50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
  TRCell():New(oSection, "VLMES4",  	     "QRY_ATF", cLegMes4, "@E 999,999,999.99",		50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
		TRCell():New(oSection, "VLMES5",  	     "QRY_ATF", cLegMes5, "@E 999,999,999.99",	50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "VLMES6",  	     "QRY_ATF", cLegMes6, "@E 999,999,999.99",		50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "VLMES7",  	     "QRY_ATF", cLegMes7, "@E 999,999,999.99",		50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "VLMES8",  	     "QRY_ATF", cLegMes8, "@E 999,999,999.99",		50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "VLMES9",  	     "QRY_ATF", cLegMes9, "@E 999,999,999.99",		50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "VLMES10",  	     "QRY_ATF", cLegMes10, "@E 999,999,999.99",		50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "VLMES11",  	     "QRY_ATF", cLegMes11, "@E 999,999,999.99",		50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "VLMES12",  	     "QRY_ATF", cLegMes12, "@E 999,999,999.99",		50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
// TRCell():New(oSection, "GERAL",  	     "QRY_ATF", "TOTAL GERAL", "@E 999,999,999.99",				50, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.) */
Return oReport


// Static Function fRepPrint(oReport, aResps)
Static Function ReportPrint(oReport, aResps)
	Local oSection  := oReport:Section(1)
	Local aArea     := FWGetArea()
	Local nAtual       := 0
	Local nTotal       := 0
	Local dInclusaode  := dtos(aResps[3]) //dtos(aResps[1])
	Local dInclusaoate := dtos(aResps[4])
	Local dDeprecia    := dtos(aResps[5])

	Private nLastKey := 0

	oSection:Init()
	oSection:SetHeaderSection(.T.)

	If nLastKey == 27
		Return .f.
	Endif



	//Montando consulta de dados
	cQuery := " SELECT N1_FILIAL, N1_CBASE, N1_ITEM, N1_DESCRIC, N1_AQUISIC, N1_BAIXA, N1_NFISCAL, N1_NSERIE, N3_DINDEPR, N3_CCONTAB, N3_CCDEPR, " + CRLF
	cQuery += " N3_CDEPREC, N3_TXDEPR1, N4_TXDEPR, N3_VORIG1, N3_VRDACM1, N3_TIPO, (N3_VORIG1 - N3_VRDACM1) SLD_DEPR, " + CRLF
	cQuery += " (SELECT N4_VLROC1 " + CRLF
	cQuery += " FROM " + RetSQLName("SN4") + " SN4" + CRLF
	cQuery += " WHERE SN4.D_E_L_E_T_='' AND N1_FILIAL=N4_FILIAL AND N1_CBASE=N4_CBASE AND N1_ITEM=N4_ITEM " + CRLF
	cQuery += " AND N4_OCORR = '06'  AND N4_TIPOCNT = '4' AND N4_DATA = '" +cUltMes1+ "') AS DEPMES1, " + CRLF
	cQuery += " (SELECT N4_VLROC1 " + CRLF
	cQuery += " FROM " + RetSQLName("SN4") + " SN4" + CRLF
	cQuery += " WHERE SN4.D_E_L_E_T_='' AND N1_FILIAL=N4_FILIAL AND N1_CBASE=N4_CBASE AND N1_ITEM=N4_ITEM " + CRLF
	cQuery += " AND N4_OCORR = '06'  AND N4_TIPOCNT = '4' AND N4_DATA = '" +cUltmes2+ "') AS DEPMES2, " + CRLF
	cQuery += " (SELECT N4_VLROC1 " + CRLF
	cQuery += " FROM " + RetSQLName("SN4") + " SN4 " + CRLF
	cQuery += " WHERE SN4.D_E_L_E_T_='' AND N1_FILIAL=N4_FILIAL AND N1_CBASE=N4_CBASE AND N1_ITEM=N4_ITEM " + CRLF
	cQuery += " AND N4_OCORR = '06'  AND N4_TIPOCNT = '4' AND N4_DATA = '" +cUltmes3+ "') AS DEPMES3, " + CRLF
	cQuery += " (SELECT N4_VLROC1 " + CRLF
	cQuery += " FROM " + RetSQLName("SN4") + " SN4 " + CRLF
	cQuery += " WHERE SN4.D_E_L_E_T_='' AND N1_FILIAL=N4_FILIAL AND N1_CBASE=N4_CBASE AND N1_ITEM=N4_ITEM " + CRLF
	cQuery += " AND N4_OCORR = '06'  AND N4_TIPOCNT = '4' AND N4_DATA = '" +cUltmes4+ "') AS DEPMES4, " + CRLF
	cQuery += " (SELECT N4_VLROC1 " + CRLF
	cQuery += " FROM " + RetSQLName("SN4") + " SN4 " + CRLF
	cQuery += " WHERE SN4.D_E_L_E_T_='' AND N1_FILIAL=N4_FILIAL AND N1_CBASE=N4_CBASE AND N1_ITEM=N4_ITEM " + CRLF
	cQuery += " AND N4_OCORR = '06'  AND N4_TIPOCNT = '4' AND N4_DATA = '" +cUltmes5+ "') AS DEPMES5, " + CRLF
	cQuery += " (SELECT N4_VLROC1 " + CRLF
	cQuery += " FROM " + RetSQLName("SN4") + " SN4 " + CRLF
	cQuery += " WHERE SN4.D_E_L_E_T_='' AND N1_FILIAL=N4_FILIAL AND N1_CBASE=N4_CBASE AND N1_ITEM=N4_ITEM " + CRLF
	cQuery += " AND N4_OCORR = '06'  AND N4_TIPOCNT = '4' AND N4_DATA = '" +cUltmes6+ "') AS DEPMES6, " + CRLF
	cQuery += " (SELECT N4_VLROC1 " + CRLF
	cQuery += " FROM " + RetSQLName("SN4") + " SN4 " + CRLF
	cQuery += " WHERE SN4.D_E_L_E_T_='' AND N1_FILIAL=N4_FILIAL AND N1_CBASE=N4_CBASE AND N1_ITEM=N4_ITEM " + CRLF
	cQuery += " AND N4_OCORR = '06'  AND N4_TIPOCNT = '4' AND N4_DATA = '" +cUltmes7+ "') AS DEPMES7, " + CRLF
	cQuery += " (SELECT N4_VLROC1 " + CRLF
	cQuery += " FROM " + RetSQLName("SN4") + " SN4 " + CRLF
	cQuery += " WHERE SN4.D_E_L_E_T_='' AND N1_FILIAL=N4_FILIAL AND N1_CBASE=N4_CBASE AND N1_ITEM=N4_ITEM " + CRLF
	cQuery += " AND N4_OCORR = '06'  AND N4_TIPOCNT = '4' AND N4_DATA = '" +cUltmes8+ "') AS DEPMES8, " + CRLF
	cQuery += " (SELECT N4_VLROC1 " + CRLF
	cQuery += " FROM " + RetSQLName("SN4") + " SN4 " + CRLF
	cQuery += " WHERE SN4.D_E_L_E_T_='' AND N1_FILIAL=N4_FILIAL AND N1_CBASE=N4_CBASE AND N1_ITEM=N4_ITEM " + CRLF
	cQuery += " AND N4_OCORR = '06'  AND N4_TIPOCNT = '4' AND N4_DATA = '" +cUltmes9+ "') AS DEPMES9, " + CRLF
	cQuery += " (SELECT N4_VLROC1 " + CRLF
	cQuery += " FROM " + RetSQLName("SN4") + " SN4 " + CRLF
	cQuery += " WHERE SN4.D_E_L_E_T_='' AND N1_FILIAL=N4_FILIAL AND N1_CBASE=N4_CBASE AND N1_ITEM=N4_ITEM " + CRLF
	cQuery += " AND N4_OCORR = '06'  AND N4_TIPOCNT = '4' AND N4_DATA = '" +cUltmes10+ "') AS DEPMES10, " + CRLF
	cQuery += " (SELECT N4_VLROC1 " + CRLF
	cQuery += " FROM " + RetSQLName("SN4") + " SN4 " + CRLF
	cQuery += " WHERE SN4.D_E_L_E_T_='' AND N1_FILIAL=N4_FILIAL AND N1_CBASE=N4_CBASE AND N1_ITEM=N4_ITEM " + CRLF
	cQuery += " AND N4_OCORR = '06'  AND N4_TIPOCNT = '4' AND N4_DATA = '" +cUltmes11+ "') AS DEPMES11, " + CRLF
	cQuery += " (SELECT N4_VLROC1 " + CRLF
	cQuery += " FROM " + RetSQLName("SN4") + " SN4 " + CRLF
	cQuery += " WHERE SN4.D_E_L_E_T_='' AND N1_FILIAL=N4_FILIAL AND N1_CBASE=N4_CBASE AND N1_ITEM=N4_ITEM " + CRLF
	cQuery += " AND N4_OCORR = '06'  AND N4_TIPOCNT = '4' AND N4_DATA = '" +cUltMes12+ "') AS DEPMES12 " + CRLF
	cQuery += " FROM " + RetSQLName("SN1") + " SN1 " + CRLF 
	cQuery += " INNER JOIN " + RetSQLName("SN3")+" SN3 ON SN3.D_E_L_E_T_='' AND N1_FILIAL=N3_FILIAL AND N1_CBASE=N3_CBASE AND N1_ITEM=N3_ITEM " + CRLF
	cQuery += " INNER JOIN " + RetSQLName("SN4")+" SN4 ON SN4.D_E_L_E_T_='' AND N1_FILIAL=N4_FILIAL AND N1_CBASE=N4_CBASE AND N1_ITEM=N4_ITEM " + CRLF
	cQuery += " WHERE SN1.D_E_L_E_T_='' " + CRLF
	cQuery += " AND N4_OCORR = '06'  AND N4_TIPOCNT = '4'  " + CRLF
	cQuery += " AND N3_CCONTAB BETWEEN '"+aResps[6]+"' AND '"+aResps[7]+"' " + CRLF
	cQuery += " AND N3_CCDEPR    BETWEEN '"+aResps[8]+"' AND '"+aResps[9]+"' " + CRLF
	cQuery += " AND N1_CBASE     BETWEEN  '"+aResps[1]+"' AND '"+aResps[2]+"' " + CRLF
	cQuery += " AND N1_AQUISIC   BETWEEN  '"+dInclusaode+"' AND '"+dInclusaoate+"' " + CRLF
	cQuery += " AND N4_DATA      =  '"+dDeprecia+"' " + CRLF
	cQuery += " ORDER BY N1_FILIAL, N1_CBASE " + CRLF

	// alert(cQuery)

	MemoWrite( "C:\erp\sql\VORATF01-01.SQL", cQuery )
	//Executando consulta e setando o total da regua
	PlsQuery(cQuery, "QRY_ATF")
	DbSelectArea("QRY_ATF")
	Count to nTotal
	oReport:SetMeter(nTotal)
	
	
	QRY_ATF->(DbGoTop())
	While QRY_ATF->(!EOF())

		If oReport:Cancel()
			Exit
		EndIf
		oSection:Init()
		oReport:IncMeter()

		//	incproc("Imprimindo Relatório Contas à pagar..... "+alltrim(TMP_SE2->NUM+" - "+TMP_SE2->PARCELA))
		nAtual++
		oReport:SetMsgPrint("Imprimindo registro " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")

		oSection:Cell("FILIAL"):SetValue(QRY_ATF->N1_FILIAL)
		oSection:Cell("FILIAL"):SetAlign("LEFT")

		oSection:Cell("BEM"):SetValue(QRY_ATF->N1_CBASE)
		oSection:Cell("BEM"):SetAlign("LEFT")

		oSection:Cell("ITEM"):SetValue(QRY_ATF->N1_ITEM)
		oSection:Cell("ITEM"):SetAlign("LEFT")

		oSection:Cell("DESCRICAO"):SetValue(QRY_ATF->N1_DESCRIC)
		oSection:Cell("DESCRICAO"):SetAlign("LEFT")

		oSection:Cell("TIPO"):SetValue(QRY_ATF->N3_TIPO)
		oSection:Cell("TIPO"):SetAlign("LEFT")

		oSection:Cell("AQUISICAO"):SetValue(QRY_ATF->N1_AQUISIC)
		oSection:Cell("AQUISICAO"):SetAlign("LEFT")

		oSection:Cell("BAIXA"):SetValue(QRY_ATF->N1_BAIXA)
		oSection:Cell("BAIXA"):SetAlign("LEFT")

		oSection:Cell("NOTAFISCAL"):SetValue(QRY_ATF->N1_NFISCAL)
		oSection:Cell("NOTAFISCAL"):SetAlign("LEFT")

		oSection:Cell("SERIE"):SetValue(QRY_ATF->N1_NSERIE)
		oSection:Cell("SERIE"):SetAlign("LEFT")

		oSection:Cell("INIDEPRE"):SetValue(QRY_ATF->N3_DINDEPR)
		oSection:Cell("INIDEPRE"):SetAlign("RIGHT")

		oSection:Cell("CCONTABIL"):SetValue(QRY_ATF->N3_CCONTAB)
		oSection:Cell("CCONTABIL"):SetAlign("RIGHT")

		oSection:Cell("CDEPRECIA"):SetValue(QRY_ATF->N3_CCDEPR) 
		oSection:Cell("CDEPRECIA"):SetAlign("LEFT")

		oSection:Cell("CDEPREC"):SetValue(QRY_ATF->N3_CDEPREC) 
		oSection:Cell("CDEPREC"):SetAlign("LEFT")

		oSection:Cell("TAXAANO"):SetValue(QRY_ATF->N3_TXDEPR1)
		oSection:Cell("TAXAANO"):SetAlign("CENTER")

		oSection:Cell("TAXAMES"):SetValue(QRY_ATF->N4_TXDEPR)
		oSection:Cell("TAXAMES"):SetAlign("CENTER")

		oSection:Cell("ORIGINAL"):SetValue(QRY_ATF->N3_VORIG1)
		oSection:Cell("ORIGINAL"):SetAlign("RIGHT")

		oSection:Cell("VLMES"):SetValue(QRY_ATF->N3_VRDACM1)
		oSection:Cell("VLMES"):SetAlign("RIGHT")

		oSection:Cell("SALDO"):SetValue(QRY_ATF->N3_VORIG1-QRY_ATF->N3_VRDACM1)
		oSection:Cell("SALDO"):SetAlign("RIGHT")

		oSection:Cell("VLMES1"):SetValue(QRY_ATF->DEPMES1)
		oSection:Cell("VLMES1"):SetAlign("RIGHT")

		oSection:Cell("VLMES2"):SetValue(QRY_ATF->DEPMES2)
		oSection:Cell("VLMES2"):SetAlign("RIGHT")

		oSection:Cell("VLMES3"):SetValue(QRY_ATF->DEPMES3)
		oSection:Cell("VLMES3"):SetAlign("RIGHT")

		oSection:Cell("VLMES4"):SetValue(QRY_ATF->DEPMES4)
		oSection:Cell("VLMES4"):SetAlign("RIGHT")

		oSection:Cell("VLMES5"):SetValue(QRY_ATF->DEPMES5)
		oSection:Cell("VLMES5"):SetAlign("RIGHT")

		oSection:Cell("VLMES6"):SetValue(QRY_ATF->DEPMES6)
		oSection:Cell("VLMES6"):SetAlign("RIGHT")

		oSection:Cell("VLMES7"):SetValue(QRY_ATF->DEPMES7)
		oSection:Cell("VLMES7"):SetAlign("RIGHT")

		oSection:Cell("VLMES8"):SetValue(QRY_ATF->DEPMES8)
		oSection:Cell("VLMES8"):SetAlign("RIGHT")

		oSection:Cell("VLMES9"):SetValue(QRY_ATF->DEPMES9)
		oSection:Cell("VLMES9"):SetAlign("RIGHT")

		oSection:Cell("VLMES10"):SetValue(QRY_ATF->DEPMES10)
		oSection:Cell("VLMES10"):SetAlign("RIGHT")

		oSection:Cell("VLMES11"):SetValue(QRY_ATF->DEPMES11)
		oSection:Cell("VLMES11"):SetAlign("RIGHT")

		oSection:Cell("VLMES12"):SetValue(QRY_ATF->DEPMES12)
		oSection:Cell("VLMES12"):SetAlign("RIGHT")

/*
		oSection:Cell("GERAL"):SetValue(QRY_ATF->DEPMES1+QRY_ATF->DEPMES2+QRY_ATF->DEPMES3+QRY_ATF->DEPMES4+)
		oSection:Cell("GERAL"):SetAlign("RIGHT") */


		oSection:PrintLine()

		QRY_ATF->(DbSkip())
	EndDo
	oSection:Finish()
	QRY_ATF->(DbCloseArea())

	FWRestArea(aArea)
Return
