#Include "TOTVS.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} RLCOMPRAS
Relatorio de Valor Unitario de Compras por Produto
Exibe o valor unitario da ultima compra de cada mes do periodo,
com o saldo atual e custo medio (SB2) no final.
Colunas dinamicas por mes/ano conforme periodo informado.
Suporta periodos que cruzam anos (ex: Out/2025 a Fev/2026).
@type User Function
@author TOTVS
@since 2024
@version 3.0
/*/
User Function RLCOMPRAS()
	Local oReport

	oReport := ReportDef()

	If oReport != Nil
		oReport:PrintDialog()
	EndIf
Return

/*/{Protheus.doc} ReportDef
Define parametros e estrutura do relatorio com colunas dinamicas
@type Static Function
@return oReport, Objeto TReport
/*/
Static Function ReportDef()
	Local oReport
	Local oSection
	Local aPar     := {}
	Local aRet     := {}
	Local dDataDe  := CTOD("01/10/2025")
	Local dDataAte := Date()
	Local aMeses   := {}
	Local nAnoLoop := 0
	Local nMesLoop := 0
	Local nI       := 0
	Local cHeader  := ""
	Local aNomeMes := {"Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"}

	// Parametros: Data De, Data Ate
	aAdd(aPar, {1, "Data De",  dDataDe,  "", "", "", "", 60, .T.})
	aAdd(aPar, {1, "Data Ate", dDataAte, "", "", "", "", 60, .T.})

	If !ParamBox(aPar, "Ultimas Compras x Custo Medio", @aRet)
		Return Nil
	EndIf

	// Validacoes
	If Empty(aRet[1]) .Or. Empty(aRet[2])
		MsgStop("Datas De e Ate sao obrigatorias!", "Atencao")
		Return Nil
	EndIf

	If aRet[1] > aRet[2]
		MsgStop("Data De nao pode ser maior que Data Ate!", "Atencao")
		Return Nil
	EndIf

	// Monta array de meses do periodo (max 24 colunas)
	nAnoLoop := Year(aRet[1])
	nMesLoop := Month(aRet[1])

	While (nAnoLoop < Year(aRet[2])) .Or. ;
		  (nAnoLoop == Year(aRet[2]) .And. nMesLoop <= Month(aRet[2]))
		aAdd(aMeses, {nAnoLoop, nMesLoop})
		nMesLoop++
		If nMesLoop > 12
			nMesLoop := 1
			nAnoLoop++
		EndIf
		If Len(aMeses) >= 24
			Exit
		EndIf
	EndDo

	If Len(aMeses) == 0
		MsgStop("Periodo invalido!", "Atencao")
		Return Nil
	EndIf

	// Guarda aMeses no aRet para PrintReport
	aAdd(aRet, aMeses)  // aRet[3]

	// Cria o objeto TReport
	oReport := TReport():New("RLCOMPRAS", ;
		"Ultimas Compras x Custo Medio por Produto", "", ;
		{|oReport| PrintReport(oReport, aRet)}, ;
		"Valor unitario das ultimas compras com saldo e custo medio")

	oReport:SetLandscape(.T.)
	oReport:SetTotalInLine(.F.)

	// Secao unica
	oSection := TRSection():New(oReport, "Compras", {})

	TRCell():New(oSection, "PRODUTO",   "", "Produto",   "@!", 15)
	TRCell():New(oSection, "DESCRICAO", "", "Descricao", "@!", 30)
	TRCell():New(oSection, "ARM",       "", "Arm",       "@!", 4)
	TRCell():New(oSection, "SALDO",     "", "Saldo",     "@E 999,999.99", 11)

	// Colunas dinamicas: ultima compra de cada mes do periodo
	For nI := 1 To Len(aMeses)
		cHeader := aNomeMes[aMeses[nI][2]] + "/" + Right(cValToChar(aMeses[nI][1]), 2)
		TRCell():New(oSection, "MES" + StrZero(nI, 2), "", cHeader, "@E 99,999.9999", 11)
	Next nI

	TRCell():New(oSection, "CUSTOMEDIO", "", "Custo Medio", "@E 99,999.9999", 13)

Return oReport

/*/{Protheus.doc} PrintReport
Processa e imprime o relatorio.
Para cada produto com saldo no armazem:
  1) Busca a ultima compra (SD1 tipo NF) de cada mes do periodo
  2) Exibe o valor unitario de cada mes
  3) Exibe saldo atual (SB2.B2_QATU) e custo medio atual (SB2.B2_CM1)
@type Static Function
@param oReport, Objeto TReport
@param aParam, Array [1]=DataDe [2]=DataAte [3]=aMeses
/*/
Static Function PrintReport(oReport, aParam)
	Local dDataDe    := aParam[1]
	Local dDataAte   := aParam[2]
	Local cArmazem   := "02"
	Local aMeses     := aParam[3]

	Local cAliasProd := GetNextAlias()
	Local cAliasComp := GetNextAlias()
	Local cQuery     := ""
	Local oSection   := oReport:Section(1)
	Local nCount     := 0

	Local aValores   := Array(Len(aMeses))
	Local nI         := 0
	Local nPos       := 0
	Local nAnoMov    := 0
	Local nMesMov    := 0
	Local nCustoMedio := 0

	Local cDataDe    := DtoS(dDataDe)
	Local cDataAte   := DtoS(dDataAte)

	oReport:SetMeter(0)

	// ============================================================
	// Query: Todos os produtos com saldo > 0 no armazem
	// ============================================================
	cQuery := " SELECT "
	cQuery += "   SB1.B1_COD, "
	cQuery += "   SB1.B1_DESC, "
	cQuery += "   ISNULL(SB2.B2_QATU, 0) AS B2_QATU, "
	cQuery += "   ISNULL(SB2.B2_CM1, 0) AS B2_CM1 "
	cQuery += " FROM " + RetSQLName("SB1") + " SB1 "
	cQuery += " INNER JOIN " + RetSQLName("SB2") + " SB2 "
	cQuery += "   ON SB2.B2_FILIAL = '" + xFilial("SB2") + "' "
	cQuery += "   AND SB2.B2_COD = SB1.B1_COD "
	cQuery += "   AND SB2.B2_LOCAL = '" + cArmazem + "' "
	cQuery += "   AND SB2.D_E_L_E_T_ = ' ' "
	cQuery += " WHERE SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	cQuery += "   AND SB1.D_E_L_E_T_ = ' ' "
	cQuery += "   AND SB2.B2_QATU > 0 "
	cQuery += "   AND SB1.B1_COD NOT LIKE 'SV%' "
	cQuery += "   AND SB1.B1_COD NOT LIKE 'PA%' "
	cQuery += " ORDER BY SB1.B1_COD "

	cQuery := ChangeQuery(cQuery)

	If Select(cAliasProd) > 0
		(cAliasProd)->(DbCloseArea())
	EndIf
	DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasProd, .F., .T.)

	TCSetField(cAliasProd, "B2_QATU", "N", 16, 2)
	TCSetField(cAliasProd, "B2_CM1",  "N", 16, 4)

	If (cAliasProd)->(Eof())
		(cAliasProd)->(DbCloseArea())
		MsgInfo("Nenhum produto encontrado com saldo no armazem " + cArmazem + "!", "Atencao")
		Return
	EndIf

	oSection:Init()

	// ============================================================
	// Loop pelos produtos
	// ============================================================
	While !(cAliasProd)->(Eof())

		AFill(aValores, 0)
		nCustoMedio := (cAliasProd)->B2_CM1

		// ========================================================
		// Busca ultima compra de cada mes/ano do periodo
		// Usa ROW_NUMBER particionado por ano+mes, pega a mais recente
		// ========================================================
		cQuery := " SELECT "
		cQuery += "   YEAR(D1_DTDIGIT) AS ANO_MOV, "
		cQuery += "   MONTH(D1_DTDIGIT) AS MES_MOV, "
		cQuery += "   D1_VUNIT AS VALOR_UNIT "
		cQuery += " FROM ( "
		cQuery += "   SELECT "
		cQuery += "     D1_DTDIGIT, "
		cQuery += "     D1_VUNIT, "
		cQuery += "     ROW_NUMBER() OVER ( "
		cQuery += "       PARTITION BY YEAR(D1_DTDIGIT), MONTH(D1_DTDIGIT) "
		cQuery += "       ORDER BY D1_DTDIGIT DESC, D1_NUMSEQ DESC "
		cQuery += "     ) AS RN "
		cQuery += "   FROM " + RetSQLName("SD1") + " "
		cQuery += "   WHERE D1_FILIAL = '" + xFilial("SD1") + "' "
		cQuery += "     AND D1_COD = '" + (cAliasProd)->B1_COD + "' "
		cQuery += "     AND D1_LOCAL = '" + cArmazem + "' "
		cQuery += "     AND D1_DTDIGIT >= '" + cDataDe + "' "
		cQuery += "     AND D1_DTDIGIT <= '" + cDataAte + "' "
		cQuery += "     AND D1_TIPO = 'N' "
		cQuery += "     AND D_E_L_E_T_ = ' ' "
		cQuery += " ) COMPRAS "
		cQuery += " WHERE RN = 1 "
		cQuery += " ORDER BY ANO_MOV, MES_MOV "

		cQuery := ChangeQuery(cQuery)

		If Select(cAliasComp) > 0
			(cAliasComp)->(DbCloseArea())
		EndIf
		DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasComp, .F., .T.)

		TCSetField(cAliasComp, "ANO_MOV",    "N", 4, 0)
		TCSetField(cAliasComp, "MES_MOV",    "N", 2, 0)
		TCSetField(cAliasComp, "VALOR_UNIT", "N", 16, 4)

		// Preenche array com valor da ultima compra de cada mes
		While !(cAliasComp)->(Eof())
			nAnoMov := (cAliasComp)->ANO_MOV
			nMesMov := (cAliasComp)->MES_MOV

			// Localiza posicao no array de meses do periodo
			nPos := aScan(aMeses, {|x| x[1] == nAnoMov .And. x[2] == nMesMov})

			If nPos > 0
				aValores[nPos] := (cAliasComp)->VALOR_UNIT
			EndIf

			(cAliasComp)->(DbSkip())
		EndDo

		(cAliasComp)->(DbCloseArea())

		// ========================================================
		// Preenche secao do relatorio
		// ========================================================
		oSection:Cell("PRODUTO"):SetValue((cAliasProd)->B1_COD)
		oSection:Cell("DESCRICAO"):SetValue(SubStr((cAliasProd)->B1_DESC, 1, 30))
		oSection:Cell("ARM"):SetValue(cArmazem)
		oSection:Cell("SALDO"):SetValue((cAliasProd)->B2_QATU)

		// Valor unitario da ultima compra de cada mes
		For nI := 1 To Len(aMeses)
			oSection:Cell("MES" + StrZero(nI, 2)):SetValue(aValores[nI])
		Next nI

		// Custo medio atual do SB2
		oSection:Cell("CUSTOMEDIO"):SetValue(nCustoMedio)

		oSection:PrintLine()
		nCount++

		(cAliasProd)->(DbSkip())
		oReport:IncMeter()
	EndDo

	oSection:Finish()
	(cAliasProd)->(DbCloseArea())

	If nCount == 0
		MsgInfo("Nenhum produto encontrado!", "Atencao")
	EndIf

Return
