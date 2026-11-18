//Bibliotecas
#Include "Totvs.ch"
#Include "FWPrintSetup.ch"
#Include "RPTDEF.ch"
#Include "Protheus.ch"

//Alinhamentos
#Define PAD_LEFT    0
#Define PAD_RIGHT   1
#Define PAD_CENTER  2
#Define PAD_JUSTIFY 3 //Opção disponível somente a partir da versão 1.6.2 da TOTVS Printer
#Define IMP_SPOOL   2

//Variável de setup que será acionada na primeira impressão
Static oSetupRel

/*/{Protheus.doc} User Function VOREST03
Etiquetas  de produtos termcias
@author JUVENIL GONCALVES DE SOUZA
@since 27/01/2025
@version 1.0
@type function
@obs Codigo gerado automaticamente pelo Autumn Code Maker
@see http://autumncodemaker.com
/*/

User Function VOREST03()
	Local aArea     := FWGetArea()
	Local	aParamBox := {}
	local aRet        := {}
	Local Nx        := 0
	local cCod1     := space(TamSx3("B1_COD")[1])
	local cCod2     := space(TamSx3("B1_COD")[1])
	local	nQtEti		:= 1
	Local aOpcoes   := {"Por Pedido", "Por Produto"}

	private cAlias  := 'TRB'
	private LRet    := .F.

	// cCod1 := "AI.0102.00003"
	// cCod2 := "AI.0102.00004"
	//Faz um laço infinito
	aAdd(aParamBox,{2,"Tipo de Seleção:"  , "Por Pedido", aOpcoes, 70, "",.T.})
	aadd(aParamBox,{1,"Pedido de Compra: " ,CriaVar("C7_NUM",.F.),"",".t.","SC7",".t.",60,.f.}) // Tipo caractere})
	aadd(aParamBox,{1,"De Produto: " ,cCod1,"",".t.","SB1",".t.",60,.f.}) // Tipo caractere})
	aadd(aParamBox,{1,"Ate Produto: ",cCod2,"",".t.","SB1",".T.",60,.f.}) // Tipo caractere})
	aAdd(aParamBox,{1,"Qtde",nQtEti,"9999","Positivo()","",".T.",30,.t.})	// Tipo numerico

	While .T.
		If ParamBox(aParamBox,"Parâmetros e Pesquisa.",@aRet)
			For nX:=1 To Len(aRet)
				&('MV_PAR'+strzero(nX,2)) := aRet[nX]
			next
		else
		Exit
		Endif 
		//Mantem a ultima selecao na proxima abertura da tela
		aParamBox[1][3] := MV_PAR01
		aParamBox[2][3] := MV_PAR02
		aParamBox[3][3] := MV_PAR03
		aParamBox[4][3] := MV_PAR04
		aParamBox[5][3] := MV_PAR05


	    If UPPER(MV_PAR01) = "POR PEDIDO" 
	       If alltrim(MV_PAR02) = ""
	          fwalerterror("Para imprimir por pedido é obrigatório informar o pedido de compra","Erro Seleção ")
			  Loop
		   Endif 
	      
		Else 
		  If alltrim(MV_PAR03) = "" .OR. alltrim(MV_PAR04) = ""
		     fwalerterror("Para imprimir por produto é obrigatório informar o produto inicial e o produto final","Erro Seleção ")
			 Loop 
		  Endif 	 	      
	    Endif 

		if monta_Base()
		   MsAguarde({||lRet := fImprEtq()},"Aguarde","Aguarde gerando etiquetas...",.F.)
			// fImprEtq()
		else
			msgalert('Sem dados para impressão das etiquetas.','Erro Seleção ')
		endif
		dbselectarea(cAlias)
		dbclosearea()
	EndDo

	FWRestArea(aArea)
Return

/*/{Protheus.doc} monta_Base
Monta a consulta de produtos ou de itens do pedido de compra para as etiquetas
@author JUVENIL GONCALVES DE SOUZA
@since 17/11/2026
@version 1.0
@type function
@return logical, .T. quando existe pelo menos um registro para imprimir
/*/

static function monta_Base()
	local cQuery	:= ''
	local cNumPed	:= ''
	local lRet 		:= .f.
	local aCampos 	:= {}

	LOCAL oStru
	local nX 		:= 0
//local cCampos	:= 'DA1_CODTAB, DA1_CODPRO, DA1_PRCVEN, B1_DESC'
	local cCampos	:= 'B1_COD, B1_PRV1, B1_DESC'

	oStru  := FWFormStruct( 1, 'SB1' , /* bAvalCampo */, /* lViewUsado */ )

	for nX:= 1 to len(oStru:AFIELDS)
		if alltrim(oStru:AFIELDS[nX,3]) $ cCampos
			aadd(aCampos,{oStru:AFIELDS[nX,3] ,oStru:AFIELDS[nX,4], oStru:AFIELDS[nX,5], oStru:AFIELDS[nX,6]})
		endif
	next
	//A posicao do estoque nao faz parte do dicionario da SB1: inclui manualmente
	aAdd(aCampos, {"ZC1_POSIC", "C", 20, 0})
	
	If UPPER(MV_PAR01) = "POR PEDIDO"
		//Remove aspas e ponto e virgula do pedido digitado antes de montar o SQL
		cNumPed	:= AllTrim(MV_PAR02)
		cNumPed	:= StrTran(cNumPed, "'", "")
		cNumPed	:= StrTran(cNumPed, ";", "")

		//A descricao vem da SB1 da filial; se o produto nao estiver cadastrado
		//nesta filial, usa a descricao gravada no proprio pedido (C7_DESCRI)
		cQuery	:= " SELECT SC7.C7_ITEM, SC7.C7_PRODUTO AS B1_COD, " + CRLF
		cQuery	+= " ISNULL(NULLIF(LTRIM(RTRIM(SB1.B1_DESC)), ''), SC7.C7_DESCRI) AS B1_DESC, " + CRLF
		//A posicao vem da ZC1 pelo codigo do produto, sem filtro de filial.
		//Mesmo criterio da MTA185: nao depende da filial gravada no registro.
		cQuery	+= " (SELECT TOP 1 ZC1.ZC1_POSIC " + CRLF
		cQuery	+= " FROM " + RetSQLName("ZC1") + " ZC1 " + CRLF
		cQuery	+= " WHERE ZC1.ZC1_ITEM = SC7.C7_PRODUTO " + CRLF
		cQuery	+= " AND ZC1.D_E_L_E_T_ = ' ' " + CRLF
		cQuery	+= " AND LTRIM(RTRIM(ISNULL(ZC1.ZC1_POSIC, ''))) <> '' " + CRLF
		cQuery	+= " ORDER BY ZC1.ZC1_FILIAL) AS ZC1_POSIC " + CRLF
		cQuery	+= " FROM " + RetSQLName("SC7") + " SC7 " + CRLF
		cQuery	+= " LEFT JOIN " + RetSQLName("SB1") + " SB1 " + CRLF
		cQuery	+= " ON SB1.B1_FILIAL = '"+xFilial('SB1')+"' " + CRLF
		cQuery	+= " AND SB1.B1_COD = SC7.C7_PRODUTO " + CRLF
		cQuery	+= " AND SB1.D_E_L_E_T_ = ' ' " + CRLF
		cQuery	+= " WHERE SC7.D_E_L_E_T_ <> '*' " + CRLF
		cQuery	+= " AND SC7.C7_FILIAL = '"+xFilial('SC7')+"' " + CRLF
		cQuery	+= " AND SC7.C7_NUM = '"+cNumPed+"' " + CRLF
		cQuery	+= " ORDER BY SC7.C7_ITEM"

		//Tipo e tamanho dos campos do pedido para o TopConnect
		aCampos	:= {}
		aAdd(aCampos, {"C7_ITEM", "C", 4,  0})
		aAdd(aCampos, {"B1_COD",  "C", TamSX3("B1_COD")[1],  0})
		aAdd(aCampos, {"B1_DESC", "C", TamSX3("B1_DESC")[1], 0})
		aAdd(aCampos, {"ZC1_POSIC", "C", 20, 0})
	Else
		cQuery	:= " SELECT SB1.B1_COD, SB1.B1_DESC, " + CRLF
		cQuery	+= " (SELECT TOP 1 ZC1.ZC1_POSIC " + CRLF
		cQuery	+= " FROM " + RetSQLName("ZC1") + " ZC1 " + CRLF
		cQuery	+= " WHERE ZC1.ZC1_ITEM = SB1.B1_COD " + CRLF
		cQuery	+= " AND ZC1.D_E_L_E_T_ = ' ' " + CRLF
		cQuery	+= " AND LTRIM(RTRIM(ISNULL(ZC1.ZC1_POSIC, ''))) <> '' " + CRLF
		cQuery	+= " ORDER BY ZC1.ZC1_FILIAL) AS ZC1_POSIC " + CRLF
		cQuery  += " FROM " + RetSQLName("SB1") + " SB1 " + CRLF
		cQuery	+= " WHERE SB1.B1_FILIAL = '"+xfilial('SB1')+"' AND " + CRLF
		cQuery	+= " SB1.D_E_L_E_T_ <> '*' AND " + CRLF
		cQuery	+= " SB1.B1_COD BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"' " + CRLF
		cQuery	+= " ORDER BY SB1.B1_COD"
	Endif
	// alert(cQuery)
	MPSysOpenQuery( cQuery, cAlias )
	For nX := 1 To Len(aCampos)
		TcSetField(cAlias,aCampos[nX,1],aCampos[nX,2],aCampos[nX,3],aCampos[nX,4])
	Next nX
//
	(cAlias)->(dbgotop())
//
	if (cAlias)->(!eof())
		lRet	:= .t.
	endif
//
return lRet




/*/{Protheus.doc} fImprEtq
Faz a impressão da etiqueta da VOREST03
@author JUVENIL GONCALVES DE SOUZA
@since 27/01/2025
@version 1.0
@type function
@obs Codigo gerado automaticamente pelo Autumn Code Maker
@see http://autumncodemaker.com
/*/

Static Function fImprEtq()
	Local aArea         := FWGetArea()
	Local oPrint
	Local nMiliAltur    := 29
	Local nMiliLargu    := 62
	Local nAlturPx		:= nMiliAltur * 2.8346
	Local nLarguPx		:= nMiliLargu * 2.8346
	// Local cLogo         := ''
	Local lNegrito      := .T.
	Local lSublinhado   := .T.
	Local lItalico      := .T.
	Local cNomeFont     := 'Arial'
	// Local oFontDadN     := TFont():New(cNomeFont, /*uPar2*/, -15, /*uPar4*/,     lNegrito, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, ! lSublinhado, ! lItalico)
	Local oFontDad      := TFont():New(cNomeFont, /*uPar2*/, -10, /*uPar4*/,   ! lNegrito, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, ! lSublinhado, ! lItalico)
	Local oFontDad9     := TFont():New(cNomeFont, /*uPar2*/,  -9, /*uPar4*/,   ! lNegrito, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, ! lSublinhado, ! lItalico)
	Local oFontDad8     := TFont():New(cNomeFont, /*uPar2*/,  -8, /*uPar4*/,   ! lNegrito, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, ! lSublinhado, ! lItalico)
	Local oFontDad7     := TFont():New(cNomeFont, /*uPar2*/,  -7, /*uPar4*/,   ! lNegrito, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, ! lSublinhado, ! lItalico)
	Local oFontDad6     := TFont():New(cNomeFont, /*uPar2*/,  -6, /*uPar4*/,   ! lNegrito, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, ! lSublinhado, ! lItalico)
	Local oFontMin      := TFont():New(cNomeFont, /*uPar2*/, -11, /*uPar4*/,     lNegrito, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, ! lSublinhado, ! lItalico)
	// Local nCorDestaq    := RGB(180, 180, 180)
	Local nColSepara    := 003 // de: 030
	Local nLinAtu       := 002 // 30
	Local nLargurTxt    := nLarguPx - (nColSepara + 3)
	Local nLargurDes    := nLargurTxt // mesma margem do codigo nos dois lados
	Local cTexto        := ''
	Local cDescr        := ''
	Local cCodBar       := ''
	Local cPosic        := ''
	Local aDescr        := {}
	Local oFontDes      := oFontDad
	Local nx            := 0
	Local nLin          := 0
	Local cFilePrintert := "etiq"+ALLTRIM(STR(int(SECONDS())))+"new"
	Local cPrinter      := "Microsoft Print to PDF"


	//Dados da empresa
	nAlturPx := nAlturPx

	//Criando a impressão
	/* oPrint := FWMSPrinter():New(;
		'ETQ_AUTUMN',;  // cFilePrintert
	,;              // nDevice
	.F.,;           // lAdjustToLegacy
	GetTempPath(),; // cPathInServer
	.T.;            // lDisabeSetup
	) */

    oPrint := FWMSPrinter():New(cFilePrintert ,IMP_PDF /*IMP_PDF*/, .F., /*cPathInServer*/, .T. , .F., /*@oPrintSetup*/, cPrinter, .F., .F., /*lRaw*/, /*lViewPDF*/, /*nQtdCopy*/ )

    oPrint:SetPortrait()
	oPrint:SetPaperSize(0,29,62)                    // (DMPAPER_A4) 
    oPrint:SetMargin(0,0,0,0) // nEsquerda, nSuperior, nDireita, nInferior

	//Inicia a página
	// oPrint:StartPage()

    (cAlias)->(dbgotop())
	while (cAlias)->(!eof())

		//Define o campo que será usado na composição do código de barras ou QR Code
		cCodBar := alltrim((cAlias)->B1_COD)

		//Posicao do estoque do produto na ZC1, impressa na linha do codigo
		cPosic := alltrim((cAlias)->ZC1_POSIC)

		//Quebra a descricao em ate 3 linhas e reduz a fonte se necessario
		cDescr  := alltrim((cAlias)->B1_DESC)
		aDescr  := fDescrEtq(cDescr, nLargurDes)

		If aDescr[2] == -9
			oFontDes := oFontDad9
		ElseIf aDescr[2] == -8
			oFontDes := oFontDad8
		ElseIf aDescr[2] == -7
			oFontDes := oFontDad7
		ElseIf aDescr[2] == -6
			oFontDes := oFontDad6
		Else
			oFontDes := oFontDad
		EndIf

	     for nX := 1 to MV_PAR05
		 // alert("Nlinatu "+str(nLinAtu))

     	  //Imprime o logo na esquerda e faz uma barra separando
	      /* oPrint:SayBitmap(001, 001, cLogo, 025, 025)
	         oPrint:Line(0,        nColSepara, nAlturPx, nColSepara, nCorDestaq, '-2')
	         oPrint:Line(nLinAtu,  0,          nLinAtu,  nLarguPx,   nCorDestaq, '-2') */

          //Imprime o título em destaque
	      //oPrint:SayAlign(007, nColSepara + 3, 'Impressora termicas', oFontDadN, nLargurTxt, 20, nCorDestaq, PAD_LEFT, /*nAlignVert*/)
          oPrint:StartPage() // aqui
          nLinAtu       := 002

	      //Imprime o código de barras na parte de cima da etiqueta
	      // oPrint:Code128(nAlturPx - 80, nColSepara + 15, cCodBar, 1, 30, .T., oFontMin, (nLarguPx - nColSepara - 30)) // 50
		  oPrint:Code128(nLinAtu, nColSepara + 14, cCodBar, 1, 28, .F., oFontMin, (nLarguPx - nColSepara - 30)) // de 30 para 28
          nLinAtu += 30

		  cTexto  := cCodBar
		  If !Empty(cPosic)
		      cTexto += ' - ' + cPosic
		  EndIf
              oPrint:SayAlign(nLinAtu, nColSepara , cTexto, oFontMin, nLargurTxt, 15, /*nClrText*/, PAD_CENTER, /*nAlignVert*/)
          nLinAtu += 15 // desce a descricao, afastando do codigo e usando a borda inferior

	      //Imprime a descrição já quebrada por palavra
	      For nLin := 1 To Len(aDescr[1])
	          cTexto  := cValToChar(aDescr[1][nLin])
	          oPrint:SayAlign(nLinAtu, nColSepara , cTexto, oFontDes, nLargurDes, 15, /*nClrText*/, PAD_LEFT, /*nAlignVert*/)
	          nLinAtu += 9
	      Next nLin
          
		  oPrint:EndPage()

         Next 
	     // if nX == mv_par03
	     (cAlias)->(dbskip())
	     // alert("Skip "+(cAlias)->B1_COD)
         // endif
	Enddo 
	//Mandando para o spool de impressão
	oPrint:Preview()

	//oPrint:Print()
	FWRestArea(aArea)
Return

/*/{Protheus.doc} fQuebraTexto
Quebra um texto em linhas, respeitando os espaços entre as palavras
@author JUVENIL GONCALVES DE SOUZA
@since 17/11/2026
@version 1.0
@type function
@param cTexto, character, texto que será quebrado
@param nColunas, numeric, quantidade máxima de caracteres por linha
@param nMaxLinhas, numeric, quantidade máxima de linhas
@return array, {linhas do texto, .T. quando todo o texto coube}
/*/
Static Function fQuebraTexto(cTexto, nColunas, nMaxLinhas)
	Local aPalavras := {}
	Local aLinhas   := {}
	Local cResto    := AllTrim(cTexto)
	Local cLinha    := ''
	Local cPalavra  := ''
	Local nPos      := 0
	Local nI        := 0
	Local lCompleto := .T.

	If nColunas < 1
		nColunas := 1
	EndIf

	//Separa o texto em palavras
	While !Empty(cResto)
		nPos := At(" ", cResto)
		If nPos == 0
			cPalavra := cResto
			cResto   := ''
		Else
			cPalavra := SubStr(cResto, 1, nPos - 1)
			cResto   := AllTrim(SubStr(cResto, nPos + 1))
		EndIf
		If !Empty(cPalavra)
			aAdd(aPalavras, cPalavra)
		EndIf
	EndDo

	//Monta as linhas, palavra por palavra
	For nI := 1 To Len(aPalavras)
		cPalavra := aPalavras[nI]

		//Palavra maior que a linha inteira: corta no limite da coluna
		While Len(cPalavra) > nColunas
			If !Empty(cLinha)
				aAdd(aLinhas, cLinha)
				cLinha := ''
			EndIf
			If Len(aLinhas) >= nMaxLinhas
				lCompleto := .F.
				Exit
			EndIf
			aAdd(aLinhas, SubStr(cPalavra, 1, nColunas))
			cPalavra := AllTrim(SubStr(cPalavra, nColunas + 1))
		EndDo

		If !lCompleto
			Exit
		EndIf

		If !Empty(cPalavra)
			If Empty(cLinha)
				cLinha := cPalavra
			ElseIf Len(cLinha) + 1 + Len(cPalavra) <= nColunas
				cLinha += " " + cPalavra
			Else
				aAdd(aLinhas, cLinha)
				cLinha := cPalavra
				If Len(aLinhas) >= nMaxLinhas
					lCompleto := .F.
					Exit
				EndIf
			EndIf
		EndIf
	Next nI

	If lCompleto .And. !Empty(cLinha)
		If Len(aLinhas) >= nMaxLinhas
			lCompleto := .F.
		Else
			aAdd(aLinhas, cLinha)
		EndIf
	EndIf

Return {aLinhas, lCompleto}

/*/{Protheus.doc} fDescrEtq
Escolhe o tamanho da fonte da descrição da etiqueta e devolve as linhas já quebradas
@author JUVENIL GONCALVES DE SOUZA
@since 17/11/2026
@version 1.0
@type function
@param cTexto, character, descrição do produto
@param nLargura, numeric, largura útil da etiqueta em pixels de impressão
@return array, {linhas da descrição, tamanho da fonte escolhido}
/*/
Static Function fDescrEtq(cTexto, nLargura)
	Local aTamanhos := {-10, -9, -8, -7, -6}
	Local aQuebra   := {}
	Local cUltima   := ''
	Local nI        := 0
	Local nColunas  := 0
	Local nLargCar  := 0.62 //Largura media de um caractere Arial, em relacao ao tamanho da fonte

	cTexto := AllTrim(cTexto)
	If Empty(cTexto)
		Return {{''}, -10}
	EndIf

	//Tenta do maior para o menor tamanho ate o texto caber em 3 linhas
	For nI := 1 To Len(aTamanhos)
		nColunas := Int(nLargura / (Abs(aTamanhos[nI]) * 0.78 * nLargCar))
		aQuebra  := fQuebraTexto(cTexto, nColunas, 3)
		If aQuebra[2]
			Return {aQuebra[1], aTamanhos[nI]}
		EndIf
	Next nI

	//Nem na menor fonte coube: mantem a menor e corta o final com reticencias
	nColunas := Int(nLargura / (Abs(aTamanhos[Len(aTamanhos)]) * 0.78 * nLargCar))
	aQuebra  := fQuebraTexto(cTexto, nColunas, 3)

	If Empty(aQuebra[1])
		aQuebra[1] := {SubStr(cTexto, 1, nColunas)}
	EndIf

	cUltima := aQuebra[1][Len(aQuebra[1])]
	aQuebra[1][Len(aQuebra[1])] := SubStr(cUltima, 1, nColunas - 3) + '...'

Return {aQuebra[1], aTamanhos[Len(aTamanhos)]}


/*/{Protheus.doc} fConfImpr
Abre a tela para selecionar a impressora da VOREST03
@author JUVENIL GONCALVES DE SOUZA
@since 27/01/2025
@version 1.0
@type function
@obs Codigo gerado automaticamente pelo Autumn Code Maker
@see http://autumncodemaker.com
/*/

Static Function fConfImpr()
	Local aArea         := FWGetArea()
	Local aDevice       := {'DISCO', 'SPOOL', 'EMAIL', 'EXCEL', 'HTML', 'PDF'}
	Local oSetup
	Local cSession  	:= GetPrinterSession()
	Local cDevice     	:= If(Empty(fwGetProfString(cSession,'PRINTTYPE','SPOOL',.T.)),'PDF',fwGetProfString(cSession,'PRINTTYPE','SPOOL',.T.))
	Local nPrintType    := aScan(aDevice, {|x| x == cDevice })
	Local nOrientation  := 2 //If(fwGetProfString(cSession, 'ORIENTATION', 'PORTRAIT', .T.) == 'PORTRAIT', 1, 2)
	Local nLocal        := 2 //If(fwGetProfString(cSession, 'LOCAL', 'SERVER', .T.) == 'SERVER', 1, 2)
	Local nFlags        := PD_ISTOTVSPRINTER + PD_DISABLEPAPERSIZE + PD_DISABLEPREVIEW + PD_DISABLEMARGIN

	//Cria o setup do relatório
	oSetup := FWPrintSetup():New(nFlags, 'ETIQUETA TERMICA')
	oSetup:SetPropert(PD_DESTINATION , nLocal)
	oSetup:SetPropert(PD_ORIENTATION , nOrientation)
	oSetup:SetPropert(PD_PRINTTYPE   , nPrintType)
	oSetup:SetPropert(PD_MARGIN      , {0,0,0,0})

	oSetupRel := Nil

	//Se a tela for confirmada, atualiza o setup default do relatório
	If oSetup:Activate() == PD_OK
		If oSetup:GetProperty(PD_PRINTTYPE) == IMP_SPOOL .And. oSetup:GetProperty(PD_DESTINATION) == 2
			oSetupRel := oSetup
		Else
			FWAlertInfo('Escolha o tipo SPOOL e LOCAL para impressão!')
		EndIf
	EndIf



	FWRestArea(aArea)
Return

