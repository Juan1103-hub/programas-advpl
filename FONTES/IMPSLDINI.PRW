#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} IMPSLDINI
Acerto de saldo e custo medio a partir de um arquivo CSV (;), na data
que o usuario escolher (inclusive data passada, dentro do periodo aberto).

Layout do CSV (coluna 7 opcional):
Codigo;Descricao;Unidade;Saldo Atual;Valor Unitario;Observacao;Local

A planilha representa o SALDO DE HOJE do item, com o custo medio correto.

Versao 4.1 (correcoes):
 - Limpeza (EstDoc): o SD3 ficava posicionado no registro DEPOIS do documento
   quando o MATA241 (estorno) era chamado, entao o estorno atingia o documento
   seguinte e o log dizia OK sem estornar o documento listado. Agora o programa
   reposiciona no primeiro registro ativo do documento e confere se o D3_ESTORNO
   foi realmente marcado antes de registrar OK.
 - Limpeza (BuscaSD3): nao lista mais baixa de pre-requisicao (D3_NUMSA
   preenchido), porque e movimento real e o MATA241 nao a estorna (A185ESTOR).
 - Acerto: item com custo zero na planilha e que precisa de entrada e recusado
   com mensagem clara (a TM valorizada exige custo; help A240VALSD3).
 - Leitura do CSV: linha com menos de 5 campos agora vai para o log e conta
   como erro (antes era descartada em silencio). Cabecalho "Codigo" com ou sem
   acento e ignorado.

Versao 4.0:
 - O programa calcula quanto o item precisava ter no inicio da Data do
   acerto (ex.: 01/09) para:
     a) o saldo de hoje ficar igual a planilha, e
     b) o saldo nunca ficar negativo entre a data do acerto e hoje.
   Qtd no acerto = maior entre (planilha - movimentos reais desde a data)
                   e (pior saldo negativo do caminho), nunca menor que zero.
 - Lanca na Data do acerto a entrada (custo da planilha) e o acerto de valor.
 - Se o item precisou de mais saldo no meio do periodo do que a planilha
   permite hoje, lanca uma saida na data base para o saldo de hoje ser
   exatamente a planilha.
 - Depois do MATA330: Kardex sem saldo negativo e baixas pelo custo da
   planilha (ajustado pelas entradas reais do periodo, se houver).

Versao 3.2: referencia passou a ser o inicio do dia (CalcEst(data)).
 Na 3.0/3.1 a referencia era o fim do dia: uma baixa no proprio dia do
 acerto (ainda com custo 0) entrava na conta e o programa gerava entrada
 a mais e um acerto de valor a menor. Depois do MATA330 o custo medio
 ficava abaixo do custo da planilha.
 Como o acerto entra no mesmo dia, se ja existir acerto (TMs de entrada /
 acerto) naquela data, o item e recusado: rode a Limpeza antes.

Versao 3.0 - acerto retroativo para corrigir o custo do mes:
 - Saldo de referencia = CalcEst(produto, armazem, Data do acerto),
   ou seja, a posicao no inicio daquele dia, e NAO o B2_QATU de hoje.
 - Diferenca de quantidade = planilha - referencia, lancada na Data do acerto.
 - Diferenca de valor calculada sobre a referencia, para que, depois do
   Recalculo do Custo Medio (MATA330), o custo medio logo depois do acerto
   seja o custo da planilha.
 - As baixas posteriores (ex.: requisicoes de setembro) passam a sair com o
   custo correto quando o MATA330 for rodado, e aparecem no razao pela
   contabilizacao do custo.
 - O saldo de HOJE fica: planilha + movimentos posteriores ao acerto.
   Se isso der negativo, o log avisa (AVISO), mas o acerto e feito.
 - Rodar de novo a mesma planilha com a mesma data e bloqueado por item
   (ja existe acerto no dia). Estorne pela Limpeza e rode de novo.

Regras:
 - NAO grava quantidade/valor em SB2, SB9 ou SD3 por RecLock/UPDATE.
   Tudo via MATA241.
 - Data do acerto deve ser posterior ao MV_ULMES.
 - TM de entrada e TMs de acerto precisam ser valorizadas (F5_VAL = S),
   para o valor nao ser refeito pelo MATA330. TMs de acerto com
   quantidade zero permitida.
 - Produto bloqueado, com lote ou com endereco vai para o log.
 - Depois: Recalculo do Custo Medio (MATA330) a partir do mes do acerto
   ate a data base, e contabilizacao do custo.

Versao 3.1: um unico menu. Ao abrir, o usuario escolhe:
 1 - Limpeza (SB9 fora do fechamento e estorno de acertos anteriores)
 2 - Acerto (este fluxo)
O acerto recusa o item se ainda houver SB9 com data depois do MV_ULMES.

@author geraldo.franciscon / revisado
@since 23/10/2026
@version 4.1
/*/
User Function IMPSLDINI()

	Local oDlg
	Local nOpc := 0

	DEFINE MSDIALOG oDlg TITLE "Acerto de Saldo e Custo Medio" FROM 000,000 TO 230,460 PIXEL

	@ 010,010 SAY "Ordem correta:" SIZE 200,010 OF oDlg PIXEL
	@ 022,010 SAY "1) Limpeza  ->  2) Refaz Saldos (MATA215)  ->  3) Acerto  ->  4) MATA330" SIZE 220,010 OF oDlg PIXEL

	@ 040,010 BUTTON "1 - Limpeza (SB9 fora do fechamento e estorno de acertos)" SIZE 210,016 OF oDlg PIXEL ACTION (nOpc := 1, oDlg:End())
	@ 062,010 BUTTON "2 - Acerto de saldo e custo medio pela planilha"           SIZE 210,016 OF oDlg PIXEL ACTION (nOpc := 2, oDlg:End())
	@ 090,170 BUTTON "Sair" SIZE 050,014 OF oDlg PIXEL ACTION oDlg:End()

	ACTIVATE MSDIALOG oDlg CENTERED

	If nOpc == 1
		TelaLimpa()
	ElseIf nOpc == 2
		TelaAcerto()
	EndIf

Return Nil


/*
Tela do acerto (opcao 2).
*/
Static Function TelaAcerto()

	Local oDlg
	Local lOk      := .F.

	Private cFile    := Space(250)
	Private dDataMov := dDataBase
	Private cLocPad  := PadR("02", TamSX3("B2_LOCAL")[1])
	Private cTmEnt   := Space(TamSX3("F5_CODIGO")[1])
	Private cTmSai   := Space(TamSX3("F5_CODIGO")[1])
	Private cTmAMai  := Space(TamSX3("F5_CODIGO")[1])
	Private cTmAMen  := Space(TamSX3("F5_CODIGO")[1])
	Private cTipo    := "Arquivos .CSV (*.CSV) | *.CSV | Todos os Arquivos (*.*) | *.* | "

	DEFINE MSDIALOG oDlg TITLE "Acerto de Saldo e Custo Medio via CSV" FROM 000,000 TO 330,520 PIXEL

	@ 008,010 SAY "Arquivo CSV:"            SIZE 060,010 OF oDlg PIXEL
	@ 006,075 MSGET cFile                    SIZE 140,010 OF oDlg PIXEL
	@ 006,220 BUTTON "..."                   SIZE 030,012 OF oDlg PIXEL ACTION LeArq()

	@ 028,010 SAY "Data do acerto:"          SIZE 060,010 OF oDlg PIXEL
	@ 026,075 MSGET dDataMov                 SIZE 060,010 OF oDlg PIXEL VALID !Empty(dDataMov)
	@ 028,140 SAY "(planilha = saldo de hoje)" SIZE 115,010 OF oDlg PIXEL

	@ 048,010 SAY "Armazem padrao:"          SIZE 060,010 OF oDlg PIXEL
	@ 046,075 MSGET cLocPad                  SIZE 030,010 OF oDlg PIXEL VALID !Empty(cLocPad)

	@ 068,010 SAY "TM Entrada qtd:"          SIZE 060,010 OF oDlg PIXEL
	@ 066,075 MSGET cTmEnt  F3 "SF5"         SIZE 030,010 OF oDlg PIXEL VALID VldTM(cTmEnt, "E", .F.)

	@ 088,010 SAY "TM Saida qtd:"            SIZE 060,010 OF oDlg PIXEL
	@ 086,075 MSGET cTmSai  F3 "SF5"         SIZE 030,010 OF oDlg PIXEL VALID VldTM(cTmSai, "S", .F.)

	@ 108,010 SAY "TM Acerto a maior:"       SIZE 060,010 OF oDlg PIXEL
	@ 106,075 MSGET cTmAMai F3 "SF5"         SIZE 030,010 OF oDlg PIXEL VALID VldTM(cTmAMai, "E", .F.)

	@ 128,010 SAY "TM Acerto a menor:"       SIZE 060,010 OF oDlg PIXEL
	@ 126,075 MSGET cTmAMen F3 "SF5"         SIZE 030,010 OF oDlg PIXEL VALID VldTM(cTmAMen, "S", .F.)

	@ 148,150 BUTTON "Processar"             SIZE 050,012 OF oDlg PIXEL ACTION (lOk := .T., oDlg:End())
	@ 148,205 BUTTON "Cancelar"              SIZE 050,012 OF oDlg PIXEL ACTION oDlg:End()

	ACTIVATE MSDIALOG oDlg CENTERED

	If lOk
		OkLeTxt()
	EndIf

Return Nil


Static Function LeArq()
	Local cSel := cGetFile(cTipo, "Selecione o arquivo", 1, , .T., GETF_LOCALHARD + GETF_NETWORKDRIVE)
	If !Empty(cSel)
		cFile := PadR(cSel, 250)
	EndIf
Return .T.


/*
Valida a TM.
cTipoEsp = "E" exige TM de entrada (F5_TIPO D/E/P)
cTipoEsp = "S" exige TM de saida   (F5_TIPO R/S)
lExigeVal = .T. exige TM valorizada (F5_VAL = S)
*/
Static Function VldTM(cTM, cTipoEsp, lExigeVal)

	Local aArea := GetArea()
	Local lRet  := .T.

	If Empty(cTM)
		Return .T.  // obrigatoriedade checada ao processar
	EndIf

	SF5->(DbSetOrder(1))
	If !SF5->(DbSeek(xFilial("SF5") + cTM))
		MsgAlert("TM " + cTM + " nao cadastrada.", "Atencao")
		lRet := .F.
	ElseIf cTipoEsp == "E" .And. !(SF5->F5_TIPO $ "DEP")
		MsgAlert("TM " + cTM + " nao e de ENTRADA (F5_TIPO = " + SF5->F5_TIPO + ").", "TM invalida")
		lRet := .F.
	ElseIf cTipoEsp == "S" .And. !(SF5->F5_TIPO $ "RS")
		MsgAlert("TM " + cTM + " nao e de SAIDA (F5_TIPO = " + SF5->F5_TIPO + ").", "TM invalida")
		lRet := .F.
	ElseIf lExigeVal .And. !(AllTrim(SF5->F5_VAL) $ "S1")
		MsgAlert("TM " + cTM + " precisa ser valorizada (F5_VAL = S). Hoje esta: [" + AllTrim(SF5->F5_VAL) + "]." + CRLF + ;
			"Sem isso o Recalculo do Custo Medio refaz o valor e o custo da planilha se perde.", "TM invalida")
		lRet := .F.
	EndIf

	RestArea(aArea)

Return lRet


Static Function OkLeTxt()

	Local dUlMes := GetMV("MV_ULMES")

	If Empty(cFile) .Or. !File(AllTrim(cFile))
		MsgStop("Arquivo nao encontrado: " + AllTrim(cFile), "Atencao")
		Return
	EndIf

	If Empty(cTmEnt) .Or. Empty(cTmSai) .Or. Empty(cTmAMai) .Or. Empty(cTmAMen)
		MsgStop("Informe as 4 TMs.", "Atencao")
		Return
	EndIf

	If !VldTM(cTmEnt, "E", .T.) .Or. !VldTM(cTmSai, "S", .F.) .Or. ;
		!VldTM(cTmAMai, "E", .T.) .Or. !VldTM(cTmAMen, "S", .T.)
		Return
	EndIf

	If dDataMov <= dUlMes
		MsgStop("A data " + DtoC(dDataMov) + " esta em periodo fechado (MV_ULMES = " + DtoC(dUlMes) + ").", "Periodo fechado")
		Return
	EndIf

	If dDataMov > dDataBase
		MsgStop("A data do acerto nao pode ser maior que a data base.", "Atencao")
		Return
	EndIf

	If !MsgYesNo("Serao gerados movimentos internos (MATA241) com data " + DtoC(dDataMov) + "." + CRLF + ;
		"A planilha sera tratada como a posicao do item no fim desse dia." + CRLF + ;
		"Depois e obrigatorio rodar o Recalculo do Custo Medio (MATA330) a partir desse mes." + CRLF + ;
		"Confirma?", "Confirmacao")
		Return
	EndIf

	Processa({|| RunCont() }, "Processando " + AllTrim(cFile))

Return


Static Function RunCont()

	Local aCampos  := {}
	Local aDados   := {}
	Local aChaves  := {}
	Local cLinha   := ""
	Local cProduto := ""
	Local cLocal   := ""
	Local nSaldo   := 0
	Local nCusto   := 0
	Local nI       := 0
	Local nOk      := 0
	Local nErro    := 0
	Local nLidos   := 0
	Local nHandle  := 0
	Local cArqLog  := ""
	Local cIni     := Time()

	Private cLog   := ""

	// Abre o arquivo. Sem isso o FT_FEOF nunca fica verdadeiro.
	nHandle := FT_FUse(AllTrim(cFile))
	If nHandle == -1
		MsgStop("Nao foi possivel abrir o arquivo " + AllTrim(cFile) + " (FError " + cValToChar(FError()) + ").", "Atencao")
		Return
	EndIf

	FT_FGoTop()
	While !FT_FEOF()

		cLinha := AllTrim(FT_FReadLn())
		FT_FSkip()

		If Empty(cLinha)
			Loop
		EndIf

		aCampos := Separa(cLinha, ";", .T.)
		If Len(aCampos) < 5
			AddLog("", "", "ERRO", "Linha ignorada (" + cValToChar(Len(aCampos)) + " campo(s); esperado 5 ou mais separados por ponto e virgula): " + Left(cLinha, 80))
			nErro++
			Loop
		EndIf

		If Len(AllTrim(aCampos[1])) == 6 .And. Right(Upper(AllTrim(aCampos[1])), 4) == "DIGO"
			Loop
		EndIf

		nLidos++
		cProduto := PadR(AllTrim(aCampos[1]), TamSX3("B1_COD")[1])
		nSaldo   := ConvNum(aCampos[4])
		nCusto   := ConvNum(aCampos[5])
		cLocal   := cLocPad
		If Len(aCampos) >= 7 .And. !Empty(aCampos[7])
			cLocal := PadR(AllTrim(aCampos[7]), TamSX3("B2_LOCAL")[1])
		EndIf

		If nSaldo < 0 .Or. nCusto < 0
			AddLog(cProduto, cLocal, "ERRO", "Saldo ou custo negativo na planilha.")
			nErro++
			Loop
		EndIf

		If aScan(aChaves, cProduto + cLocal) > 0
			AddLog(cProduto, cLocal, "ERRO", "Produto/armazem duplicado na planilha. Linha ignorada.")
			nErro++
			Loop
		EndIf
		aAdd(aChaves, cProduto + cLocal)

		aAdd(aDados, {cProduto, cLocal, nSaldo, nCusto})
	EndDo
	FT_FUse()   // fecha o arquivo

	ProcRegua(Len(aDados))

	For nI := 1 To Len(aDados)
		IncProc("Produto " + AllTrim(aDados[nI][1]) + " (" + cValToChar(nI) + "/" + cValToChar(Len(aDados)) + ")")
		If AjustaItem(aDados[nI][1], aDados[nI][2], aDados[nI][3], aDados[nI][4])
			nOk++
		Else
			nErro++
		EndIf
	Next nI

	cLog += Replicate("-", 80) + CRLF
	cLog += "ARQUIVO: " + AllTrim(cFile) + CRLF
	cLog += "DATA DO ACERTO: " + DtoC(dDataMov) + " (planilha = saldo de hoje; acerto lancado no inicio desse dia)" + CRLF
	cLog += "INICIO: " + cIni + "  FIM: " + Time() + CRLF
	cLog += "LINHAS LIDAS: " + cValToChar(nLidos) + "  OK: " + cValToChar(nOk) + "  ERRO: " + cValToChar(nErro) + CRLF
	cLog += "Proximo passo: Recalculo do Custo Medio (MATA330) de " + DtoC(FirstDay(dDataMov)) + ;
		" ate a data base, e depois a contabilizacao do custo." + CRLF

	cArqLog := SubStr(AllTrim(cFile), 1, Rat("\", AllTrim(cFile))) + "IMPSLDINI_" + DtoS(Date()) + "_" + StrTran(Time(), ":", "") + ".txt"
	MemoWrite(cArqLog, cLog)

	MostraLog(cLog, cArqLog)

Return


/*
Acerta um produto/armazem na data dDataMov. Retorna .T. se terminou sem erro.

Referencia = posicao no inicio do dia do acerto (CalcEst com a data).
Valor depois do movimento de quantidade (o que o MATA330 vai considerar):
 - entrada (TM valorizada): valor ref + qtd * custo planilha
 - saida: sai pelo custo medio da referencia -> qtd planilha * CM ref
Acerto de valor = qtd planilha * custo planilha - valor depois da quantidade.
*/
Static Function AjustaItem(cProduto, cLocal, nQtdPla, nCusto)

	Local aArea    := GetArea()
	Local nQtdDest := 0
	Local nDifHoje := 0
	Local nMinAc   := 0
	Local nAcum    := 0
	Local aDias    := {}
	Local nD       := 0
	Local lOk      := .T.
	Local aRef     := {}
	Local aHoje    := {}
	Local nQtdRef  := 0
	Local nVlrRef  := 0
	Local nCMRef   := 0
	Local nDifQtd  := 0
	Local nVlrApos := 0
	Local nDifVlr  := 0
	Local nVlrDest := 0
	Local nMovPos  := 0
	Local nQtdHoje := 0
	Local cUM      := ""
	Local cMsgMov  := ""
	Local cStatus  := "OK"

	SB1->(DbSetOrder(1))
	If !SB1->(DbSeek(xFilial("SB1") + cProduto))
		AddLog(cProduto, cLocal, "ERRO", "Produto nao cadastrado.")
		RestArea(aArea)
		Return .F.
	EndIf

	If SB1->B1_MSBLQL == "1"
		AddLog(cProduto, cLocal, "ERRO", "Produto bloqueado (B1_MSBLQL). Desbloqueie e rode de novo.")
		RestArea(aArea)
		Return .F.
	EndIf

	If SB1->B1_RASTRO $ "LS" .Or. SB1->B1_LOCALIZ == "S"
		AddLog(cProduto, cLocal, "ERRO", "Produto controla lote/endereco. Acertar manualmente.")
		RestArea(aArea)
		Return .F.
	EndIf

	cUM := SB1->B1_UM

	If TemSB9Pos(cProduto, cLocal)
		AddLog(cProduto, cLocal, "ERRO", "Existe SB9 com data depois do MV_ULMES. Rode a opcao 1 (Limpeza) e o Refaz Saldos antes do acerto.")
		RestArea(aArea)
		Return .F.
	EndIf

	SB2->(DbSetOrder(1))
	If !SB2->(DbSeek(xFilial("SB2") + cProduto + cLocal))
		CriaSB2(cProduto, cLocal)
	EndIf

	If TemAcDia(cProduto, cLocal)
		AddLog(cProduto, cLocal, "ERRO", "Ja existe acerto (TM " + AllTrim(cTmEnt) + "/" + AllTrim(cTmAMai) + "/" + AllTrim(cTmAMen) + ;
			") em " + DtoC(dDataMov) + ". Estorne pela opcao 1 (Limpeza), rode o Refaz Saldos e depois o acerto.")
		RestArea(aArea)
		Return .F.
	EndIf

	// Posicao no inicio do dia do acerto (antes das baixas do dia)
	aRef    := CalcEst(cProduto, cLocal, dDataMov)
	nQtdRef := aRef[1]
	nVlrRef := aRef[2]
	nCMRef  := IIf(nQtdRef > 0, nVlrRef / nQtdRef, 0)

	// Movimentos reais desde o inicio do dia do acerto ate hoje:
	// nMovPos = saldo liquido (entradas - saidas), nMinAc = pior momento (mais negativo)
	aHoje   := CalcEst(cProduto, cLocal, dDataBase + 1)
	nMovPos := aHoje[1] - nQtdRef
	aDias   := DiasMov(cProduto, cLocal)
	For nD := 1 To Len(aDias)
		nAcum := CalcEst(cProduto, cLocal, aDias[nD] + 1)[1] - nQtdRef
		If nAcum < nMinAc
			nMinAc := nAcum
		EndIf
	Next nD
	If nMovPos < nMinAc
		nMinAc := nMovPos
	EndIf

	// Quantidade no inicio do dia do acerto para:
	//  a) o saldo de hoje ser a planilha (nQtdPla - nMovPos)
	//  b) nunca ficar negativo no caminho (-nMinAc)
	nQtdDest := Max(nQtdPla - nMovPos, -nMinAc)
	nQtdDest := Max(nQtdDest, 0)
	nVlrDest := Round(nQtdDest * nCusto, 2)

	// Sobra hoje (quando o item precisou de mais saldo no meio do periodo)
	nQtdHoje := nQtdDest + nMovPos
	nDifHoje := nQtdPla - nQtdHoje

	nDifQtd := nQtdDest - nQtdRef

	// Valor que o item tera depois do movimento de quantidade
	If nDifQtd > 0.00001
		nVlrApos := nVlrRef + Round(nDifQtd * nCusto, 2)
	ElseIf nDifQtd < -0.00001
		nVlrApos := Round(nQtdDest * nCMRef, 2)
	Else
		nVlrApos := nVlrRef
	EndIf
	nDifVlr := Round(nVlrDest - nVlrApos, 2)

	// TM de entrada valorizada (F5_VAL = S) exige D3_CUSTO1 preenchido (help A240VALSD3).
	// Custo zero na planilha nao tem como ser lancado como entrada valorizada.
	If nCusto <= 0 .And. (nDifQtd > 0.00001 .Or. nDifHoje > 0.00001)
		AddLog(cProduto, cLocal, "ERRO", "Custo zero na planilha: a TM de entrada valorizada exige custo. Informe um custo na planilha ou trate o item manualmente.")
		RestArea(aArea)
		Return .F.
	EndIf

	Begin Transaction

		// 1) Quantidade no dia do acerto
		If nDifQtd > 0.00001
			lOk := MovInterno(cProduto, cLocal, cUM, cTmEnt, nDifQtd, Round(nDifQtd * nCusto, 2), @cMsgMov, dDataMov)
		ElseIf nDifQtd < -0.00001
			lOk := MovInterno(cProduto, cLocal, cUM, cTmSai, Abs(nDifQtd), 0, @cMsgMov, dDataMov)
		EndIf

		// 2) Valor no dia do acerto
		If lOk
			If nDifVlr > 0.009
				lOk := MovInterno(cProduto, cLocal, cUM, cTmAMai, 0, nDifVlr, @cMsgMov, dDataMov)
			ElseIf nDifVlr < -0.009
				lOk := MovInterno(cProduto, cLocal, cUM, cTmAMen, 0, Abs(nDifVlr), @cMsgMov, dDataMov)
			EndIf
		EndIf

		// 3) Ajuste final na data base para o saldo de hoje ser a planilha
		If lOk
			If nDifHoje < -0.00001
				lOk := MovInterno(cProduto, cLocal, cUM, cTmSai, Abs(nDifHoje), 0, @cMsgMov, dDataBase)
			ElseIf nDifHoje > 0.00001
				lOk := MovInterno(cProduto, cLocal, cUM, cTmEnt, nDifHoje, Round(nDifHoje * nCusto, 2), @cMsgMov, dDataBase)
			EndIf
		EndIf

		If !lOk
			DisarmTransaction()
		EndIf

	End Transaction

	If lOk
		If Empty(cMsgMov)
			cMsgMov := " | Sem movimento (ja estava de acordo)"
		EndIf
		AddLog(cProduto, cLocal, cStatus, ;
			"Inicio de " + DtoC(dDataMov) + ": qtd " + cValToChar(nQtdRef) + " -> " + cValToChar(nQtdDest) + ;
			", valor " + cValToChar(Round(nVlrRef, 2)) + " -> " + cValToChar(nVlrDest) + ", CM " + cValToChar(nCusto) + ;
			" | Mov. reais desde " + DtoC(dDataMov) + ": " + cValToChar(nMovPos) + ;
			" (pior momento " + cValToChar(nMinAc) + ")" + ;
			" | Saldo hoje: " + cValToChar(nQtdPla) + " (planilha)" + ;
			IIf(Abs(nDifHoje) > 0.00001, " com ajuste em " + DtoC(dDataBase) + " de " + cValToChar(nDifHoje), "") + ;
			cMsgMov)
	EndIf

	RestArea(aArea)

Return lOk


/*
Datas (distintas, em ordem) com movimento real do produto/armazem
entre a data do acerto e a data base (SD1, SD2 e SD3 nao estornados).
*/
Static Function DiasMov(cProduto, cLocal)

	Local aArea  := GetArea()
	Local cAlias := GetNextAlias()
	Local cQuery := ""
	Local cIni   := DtoS(dDataMov)
	Local cFim   := DtoS(dDataBase)
	Local aRet   := {}

	cQuery := "SELECT DISTINCT DT FROM ( "
	cQuery += " SELECT D1_DTDIGIT DT FROM " + RetSqlName("SD1")
	cQuery += "  WHERE D_E_L_E_T_ = ' ' AND D1_FILIAL = '" + xFilial("SD1") + "' AND D1_COD = '" + cProduto + "'"
	cQuery += "    AND D1_LOCAL = '" + cLocal + "' AND D1_DTDIGIT BETWEEN '" + cIni + "' AND '" + cFim + "' "
	cQuery += " UNION ALL "
	cQuery += " SELECT D2_EMISSAO DT FROM " + RetSqlName("SD2")
	cQuery += "  WHERE D_E_L_E_T_ = ' ' AND D2_FILIAL = '" + xFilial("SD2") + "' AND D2_COD = '" + cProduto + "'"
	cQuery += "    AND D2_LOCAL = '" + cLocal + "' AND D2_EMISSAO BETWEEN '" + cIni + "' AND '" + cFim + "' "
	cQuery += " UNION ALL "
	cQuery += " SELECT D3_EMISSAO DT FROM " + RetSqlName("SD3")
	cQuery += "  WHERE D_E_L_E_T_ = ' ' AND D3_FILIAL = '" + xFilial("SD3") + "' AND D3_COD = '" + cProduto + "'"
	cQuery += "    AND D3_LOCAL = '" + cLocal + "' AND D3_ESTORNO <> 'S' AND D3_EMISSAO BETWEEN '" + cIni + "' AND '" + cFim + "' "
	cQuery += ") TMP ORDER BY DT "

	DbUseArea(.T., "TOPCONN", TcGenQry(, , cQuery), cAlias, .F., .T.)
	While !(cAlias)->(Eof())
		If !Empty((cAlias)->DT)
			aAdd(aRet, StoD((cAlias)->DT))
		EndIf
		(cAlias)->(DbSkip())
	EndDo
	(cAlias)->(DbCloseArea())

	RestArea(aArea)

Return aRet


/*
.T. se ja existe movimento das TMs de entrada/acerto na data do acerto.
*/
Static Function TemAcDia(cProduto, cLocal)

	Local aArea  := GetArea()
	Local cAlias := GetNextAlias()
	Local cQuery := ""
	Local lRet   := .F.

	cQuery := "SELECT COUNT(*) QTD FROM " + RetSqlName("SD3") + " "
	cQuery += "WHERE D_E_L_E_T_ = ' ' "
	cQuery += "  AND D3_FILIAL = '" + xFilial("SD3") + "' "
	cQuery += "  AND D3_COD = '" + cProduto + "' "
	cQuery += "  AND D3_LOCAL = '" + cLocal + "' "
	cQuery += "  AND D3_EMISSAO = '" + DtoS(dDataMov) + "' "
	cQuery += "  AND D3_ESTORNO <> 'S' "
	cQuery += "  AND D3_TM IN ('" + cTmEnt + "','" + cTmAMai + "','" + cTmAMen + "') "

	DbUseArea(.T., "TOPCONN", TcGenQry(, , cQuery), cAlias, .F., .T.)
	lRet := (cAlias)->QTD > 0
	(cAlias)->(DbCloseArea())

	RestArea(aArea)

Return lRet


/*
.T. se o produto/armazem tem SB9 com data maior que o MV_ULMES.
*/
Static Function TemSB9Pos(cProduto, cLocal)

	Local aArea  := GetArea()
	Local cAlias := GetNextAlias()
	Local cQuery := ""
	Local lRet   := .F.

	cQuery := "SELECT COUNT(*) QTD FROM " + RetSqlName("SB9") + " "
	cQuery += "WHERE D_E_L_E_T_ = ' ' "
	cQuery += "  AND B9_FILIAL = '" + xFilial("SB9") + "' "
	cQuery += "  AND B9_COD = '" + cProduto + "' "
	cQuery += "  AND B9_LOCAL = '" + cLocal + "' "
	cQuery += "  AND B9_DATA > '" + DtoS(GetMV("MV_ULMES")) + "' "

	DbUseArea(.T., "TOPCONN", TcGenQry(, , cQuery), cAlias, .F., .T.)
	lRet := (cAlias)->QTD > 0
	(cAlias)->(DbCloseArea())

	RestArea(aArea)

Return lRet


/*
Gera um movimento interno pela MATA241 na data dDataMov.
D3_CUSTO1 sempre positivo: o F5_TIPO da TM define se soma ou subtrai.
Na TM de saida de quantidade o valor nao e enviado: o custo sai pelo medio.
*/
Static Function MovInterno(cProduto, cLocal, cUM, cTM, nQtd, nValor, cMsgMov, dEmis)

	Local aArea   := GetArea()
	Local aCab    := {}
	Local aItem   := {}
	Local aItens  := {}
	Local aErro   := {}
	Local cErro   := ""
	Local cDoc    := ""
	Local nX      := 0

	Private lMsErroAuto    := .F.
	Private lMsHelpAuto    := .T.
	Private lAutoErrNoFile := .T.

	cDoc := NextNumero("SD3", 2, "D3_DOC", .T.)

	aAdd(aCab, {"D3_DOC"    , cDoc    , Nil})
	aAdd(aCab, {"D3_TM"     , cTM     , Nil})
	Default dEmis := dDataMov

	aAdd(aCab, {"D3_EMISSAO", dEmis, Nil})

	aAdd(aItem, {"D3_COD"  , cProduto, Nil})
	aAdd(aItem, {"D3_UM"   , cUM     , Nil})
	aAdd(aItem, {"D3_QUANT", nQtd    , Nil})
	aAdd(aItem, {"D3_LOCAL", cLocal  , Nil})
	If nValor > 0
		aAdd(aItem, {"D3_CUSTO1", Abs(nValor), Nil})
	EndIf
	aAdd(aItens, aItem)

	MSExecAuto({|x, y, z| MATA241(x, y, z)}, aCab, aItens, 3)

	RestArea(aArea)

	If lMsErroAuto
		aErro := GetAutoGRLog()
		For nX := 1 To Len(aErro)
			cErro += AllTrim(aErro[nX]) + " "
		Next nX
		AddLog(cProduto, cLocal, "ERRO", "TM " + cTM + " Doc " + cDoc + " Qtd " + cValToChar(nQtd) + ;
			" Valor " + cValToChar(nValor) + " : " + cErro)
		Return .F.
	EndIf

	cMsgMov += " | " + DtoC(dEmis) + " TM " + cTM + " Doc " + cDoc + " Qtd " + cValToChar(nQtd) + " Vlr " + cValToChar(nValor)

Return .T.


Static Function ConvNum(cTexto)
	Local cVal := AllTrim(cTexto)
	cVal := StrTran(cVal, "R$", "")
	cVal := StrTran(cVal, " ", "")
	If Empty(cVal) .Or. cVal == "-"
		Return 0
	EndIf
	If "," $ cVal
		cVal := StrTran(cVal, ".", "")
		cVal := StrTran(cVal, ",", ".")
	EndIf
Return Val(cVal)


Static Function AddLog(cProduto, cLocal, cStatus, cMsg)
	cLog += cStatus + " | " + AllTrim(cProduto) + " | Local " + cLocal + " | " + cMsg + CRLF
Return


Static Function MostraLog(cTexto, cArqLog)
	Local oDlg
	Local oMemo
	DEFINE MSDIALOG oDlg TITLE "Log do processamento" FROM 000,000 TO 450,700 PIXEL
	@ 005,005 GET oMemo VAR cTexto MEMO SIZE 340,190 OF oDlg PIXEL READONLY
	@ 200,005 SAY "Log salvo em: " + cArqLog SIZE 280,010 OF oDlg PIXEL
	@ 200,295 BUTTON "Fechar" SIZE 050,012 OF oDlg PIXEL ACTION oDlg:End()
	ACTIVATE MSDIALOG oDlg CENTERED
Return


/*
Limpeza antes do acerto retroativo (opcao 1 do U_IMPSLDINI).

Para os produtos da planilha, no armazem informado:
 1. Lista os saldos iniciais (SB9) com data MAIOR que o MV_ULMES.
    SB9 so pode existir na data de fechamento. Registro no meio do periodo
    aberto (ex.: 01/09 gravado pelo IMPSLDINI antigo) vira base do Refaz
    Saldos e da CalcEst e duplica a quantidade.
    -> esses registros sao excluidos (unica gravacao direta do programa,
       restrita a B9_DATA > MV_ULMES).
 2. Lista os movimentos internos (SD3) das TMs informadas, a partir da data
    informada, (opcional) a partir de um documento inicial e (opcional)
    somente dos usuarios informados (D3_USUARIO; padrao juan.almeida;000047).
    -> os marcados sao ESTORNADOS pela MATA241 (opcao 6), nunca apagados.
 Tudo aparece numa tela de marcacao antes de gravar. Desmarque o que for
 movimento real.

Depois: Refaz Saldos (MATA215) -> opcao 2 (Acerto) com data 01/09 -> MATA330.
*/
Static Function TelaLimpa()

	Local oDlg
	Local lOk := .F.

	Private cFileL  := Space(250)
	Private cLocL   := PadR("02", TamSX3("B2_LOCAL")[1])
	Private cTMsL   := PadR("005;501;502", 40)
	Private dIniL   := GetMV("MV_ULMES") + 1
	Private cDocIni := Space(TamSX3("D3_DOC")[1])
	Private cUsrL   := PadR("juan.almeida;000047", 60)
	Private cTipo   := "Arquivos .CSV (*.CSV) | *.CSV | Todos os Arquivos (*.*) | *.* | "

	DEFINE MSDIALOG oDlg TITLE "Limpeza antes do acerto (SB9 fora do fechamento e estorno SD3)" FROM 000,000 TO 310,560 PIXEL

	@ 008,010 SAY "Arquivo CSV:"              SIZE 070,010 OF oDlg PIXEL
	@ 006,085 MSGET cFileL                     SIZE 150,010 OF oDlg PIXEL
	@ 006,240 BUTTON "..."                     SIZE 030,012 OF oDlg PIXEL ACTION LeArqL()

	@ 028,010 SAY "Armazem padrao:"            SIZE 070,010 OF oDlg PIXEL
	@ 026,085 MSGET cLocL                      SIZE 030,010 OF oDlg PIXEL

	@ 048,010 SAY "TMs a estornar (;):"        SIZE 070,010 OF oDlg PIXEL
	@ 046,085 MSGET cTMsL                      SIZE 100,010 OF oDlg PIXEL

	@ 068,010 SAY "Movimentos a partir de:"    SIZE 070,010 OF oDlg PIXEL
	@ 066,085 MSGET dIniL                      SIZE 060,010 OF oDlg PIXEL

	@ 088,010 SAY "Documento inicial:"         SIZE 070,010 OF oDlg PIXEL
	@ 086,085 MSGET cDocIni                    SIZE 060,010 OF oDlg PIXEL
	@ 088,150 SAY "(em branco = todos)"        SIZE 100,010 OF oDlg PIXEL

	@ 108,010 SAY "Usuarios (;):"              SIZE 070,010 OF oDlg PIXEL
	@ 106,085 MSGET cUsrL                      SIZE 150,010 OF oDlg PIXEL
	@ 118,085 SAY "(so lista movimentos desses usuarios; em branco = todos)" SIZE 190,010 OF oDlg PIXEL

	@ 135,170 BUTTON "Listar"                  SIZE 050,012 OF oDlg PIXEL ACTION (lOk := .T., oDlg:End())
	@ 135,225 BUTTON "Cancelar"                SIZE 050,012 OF oDlg PIXEL ACTION oDlg:End()

	ACTIVATE MSDIALOG oDlg CENTERED

	If lOk
		LimpaRun()
	EndIf

Return Nil


Static Function LeArqL()
	Local cSel := cGetFile(cTipo, "Selecione o arquivo", 1, , .T., GETF_LOCALHARD + GETF_NETWORKDRIVE)
	If !Empty(cSel)
		cFileL := PadR(cSel, 250)
	EndIf
Return .T.


Static Function LimpaRun()

	Local aProd   := {}
	Local aSB9    := {}
	Local aSD3    := {}
	Local dUlMes  := GetMV("MV_ULMES")
	Local nMarc9  := 0
	Local nMarc3  := 0
	Local nI      := 0
	Local cArqLog := ""

	Private cLog  := ""

	If Empty(cFileL) .Or. !File(AllTrim(cFileL))
		MsgStop("Arquivo nao encontrado: " + AllTrim(cFileL), "Atencao")
		Return
	EndIf

	If dIniL <= dUlMes
		MsgStop("A data inicial deve ser maior que o MV_ULMES (" + DtoC(dUlMes) + ").", "Atencao")
		Return
	EndIf

	aProd := LeProdCSV(AllTrim(cFileL), cLocL)
	If Len(aProd) == 0
		MsgStop("Nenhum produto valido no arquivo.", "Atencao")
		Return
	EndIf

	aSB9 := BuscaSB9(aProd, dUlMes)
	aSD3 := BuscaSD3(aProd)

	If Len(aSB9) == 0 .And. Len(aSD3) == 0
		MsgInfo("Nada a limpar: nenhum SB9 depois de " + DtoC(dUlMes) + " e nenhum movimento das TMs/usuarios informados." + CRLF + "Se esperava movimentos, deixe o campo Usuarios em branco e confira a coluna Usuario.", "Limpeza")
		Return
	EndIf

	If !TelaMarca(@aSB9, @aSD3)
		Return
	EndIf

	aEval(aSB9, {|x| IIf(x[1], nMarc9++, Nil)})
	aEval(aSD3, {|x| IIf(x[1], nMarc3++, Nil)})

	If nMarc9 == 0 .And. nMarc3 == 0
		MsgInfo("Nada marcado.", "Limpeza")
		Return
	EndIf

	If !MsgYesNo("Serao estornados " + cValToChar(nMarc3) + " movimento(s) pela MATA241" + CRLF + ;
		"e excluidos " + cValToChar(nMarc9) + " saldo(s) inicial(is) SB9 com data depois de " + DtoC(dUlMes) + "." + CRLF + ;
		"Confirma?", "Confirmacao")
		Return
	EndIf

	Processa({|| ExecLimpa(aSB9, aSD3, dUlMes) }, "Limpando...")

	cLog += Replicate("-", 80) + CRLF
	cLog += "ARQUIVO: " + AllTrim(cFileL) + CRLF
	cLog += "MV_ULMES: " + DtoC(dUlMes) + CRLF
	cLog += "Proximo passo: Refaz Saldos (MATA215), depois IMPSLDINI opcao 2 (Acerto) com a data do acerto, depois MATA330." + CRLF

	cArqLog := SubStr(AllTrim(cFileL), 1, Rat("\", AllTrim(cFileL))) + "IMPSLDLIM_" + DtoS(Date()) + "_" + StrTran(Time(), ":", "") + ".txt"
	MemoWrite(cArqLog, cLog)
	MostraLog(cLog, cArqLog)

Return


/*
Le os produtos da planilha (coluna 1 e coluna 7 opcional = armazem).
Retorna {{cProduto, cLocal}, ...}
*/
Static Function LeProdCSV(cArq, cLocPadr)

	Local aRet    := {}
	Local aCampos := {}
	Local cLinha  := ""
	Local cProd   := ""
	Local cLoc    := ""

	If FT_FUse(cArq) == -1
		Return aRet
	EndIf

	FT_FGoTop()
	While !FT_FEOF()
		cLinha := AllTrim(FT_FReadLn())
		FT_FSkip()

		If Empty(cLinha)
			Loop
		EndIf

		aCampos := Separa(cLinha, ";", .T.)
		If Len(aCampos) < 1 .Or. Empty(aCampos[1]) .Or. Upper(AllTrim(aCampos[1])) == "CODIGO"
			Loop
		EndIf

		cProd := PadR(AllTrim(aCampos[1]), TamSX3("B1_COD")[1])
		cLoc  := cLocPadr
		If Len(aCampos) >= 7 .And. !Empty(aCampos[7])
			cLoc := PadR(AllTrim(aCampos[7]), TamSX3("B2_LOCAL")[1])
		EndIf

		If aScan(aRet, {|x| x[1] + x[2] == cProd + cLoc}) == 0
			aAdd(aRet, {cProd, cLoc})
		EndIf
	EndDo
	FT_FUse()

Return aRet


Static Function InProd(aProd)
	Local cRet := ""
	Local nI   := 0
	For nI := 1 To Len(aProd)
		cRet += IIf(nI > 1, ",", "") + "'" + aProd[nI][1] + "'"
	Next nI
Return cRet


Static Function InLoc(aProd)
	Local cRet  := ""
	Local aLocs := {}
	Local nI    := 0
	For nI := 1 To Len(aProd)
		If aScan(aLocs, aProd[nI][2]) == 0
			aAdd(aLocs, aProd[nI][2])
		EndIf
	Next nI
	For nI := 1 To Len(aLocs)
		cRet += IIf(nI > 1, ",", "") + "'" + aLocs[nI] + "'"
	Next nI
Return cRet


/*
SB9 com data depois do ultimo fechamento.
Retorna {{lMarca, cCod, cLocal, dData, nQIni, nVIni, nRecno}, ...}
*/
Static Function BuscaSB9(aProd, dUlMes)

	Local aRet   := {}
	Local cAlias := GetNextAlias()
	Local cQuery := ""

	cQuery := "SELECT B9_COD, B9_LOCAL, B9_DATA, B9_QINI, B9_VINI1, R_E_C_N_O_ RECNO "
	cQuery += "FROM " + RetSqlName("SB9") + " "
	cQuery += "WHERE D_E_L_E_T_ = ' ' "
	cQuery += "  AND B9_FILIAL = '" + xFilial("SB9") + "' "
	cQuery += "  AND B9_COD IN (" + InProd(aProd) + ") "
	cQuery += "  AND B9_LOCAL IN (" + InLoc(aProd) + ") "
	cQuery += "  AND B9_DATA > '" + DtoS(dUlMes) + "' "
	cQuery += "ORDER BY B9_COD, B9_DATA "

	DbUseArea(.T., "TOPCONN", TcGenQry(, , cQuery), cAlias, .F., .T.)
	While !(cAlias)->(Eof())
		If aScan(aProd, {|x| x[1] + x[2] == (cAlias)->B9_COD + (cAlias)->B9_LOCAL}) > 0
			aAdd(aRet, {.T., (cAlias)->B9_COD, (cAlias)->B9_LOCAL, StoD((cAlias)->B9_DATA), ;
				(cAlias)->B9_QINI, (cAlias)->B9_VINI1, (cAlias)->RECNO})
		EndIf
		(cAlias)->(DbSkip())
	EndDo
	(cAlias)->(DbCloseArea())

Return aRet


/*
Movimentos SD3 candidatos a estorno.
Retorna {{lMarca, cCod, cLocal, dEmissao, cTM, cDoc, nQuant, nCusto, cUsuario, cNumSeq, nRecno}, ...}
Ordem: mais recente primeiro (estorno de tras para frente).
*/
Static Function BuscaSD3(aProd)

	Local aRet   := {}
	Local cAlias := GetNextAlias()
	Local cQuery := ""
	Local aTMs   := Separa(AllTrim(cTMsL), ";", .F.)
	Local cTMs   := ""
	Local aUsr   := Separa(AllTrim(cUsrL), ";", .F.)
	Local cUsr   := ""
	Local nI     := 0

	For nI := 1 To Len(aUsr)
		If !Empty(aUsr[nI])
			cUsr += IIf(Empty(cUsr), "", ",") + "'" + Upper(AllTrim(aUsr[nI])) + "'"
		EndIf
	Next nI

	For nI := 1 To Len(aTMs)
		If !Empty(aTMs[nI])
			cTMs += IIf(Empty(cTMs), "", ",") + "'" + AllTrim(aTMs[nI]) + "'"
		EndIf
	Next nI
	If Empty(cTMs)
		Return aRet
	EndIf

	cQuery := "SELECT D3_COD, D3_LOCAL, D3_EMISSAO, D3_TM, D3_DOC, D3_QUANT, D3_CUSTO1, D3_USUARIO, D3_NUMSEQ, R_E_C_N_O_ RECNO "
	cQuery += "FROM " + RetSqlName("SD3") + " "
	cQuery += "WHERE D_E_L_E_T_ = ' ' "
	cQuery += "  AND D3_FILIAL = '" + xFilial("SD3") + "' "
	cQuery += "  AND D3_COD IN (" + InProd(aProd) + ") "
	cQuery += "  AND D3_LOCAL IN (" + InLoc(aProd) + ") "
	cQuery += "  AND D3_TM IN (" + cTMs + ") "
	cQuery += "  AND D3_ESTORNO <> 'S' "
	cQuery += "  AND D3_EMISSAO >= '" + DtoS(dIniL) + "' "
	// Baixa de pre-requisicao (MATA185) e movimento real: nao entra na Limpeza.
	// Esses movimentos trazem o numero da SA (D3_NUMSA) preenchido.
	If SD3->(FieldPos("D3_NUMSA")) > 0
		cQuery += "  AND (D3_NUMSA = ' ' OR D3_NUMSA IS NULL) "
	EndIf
	If !Empty(cDocIni)
		cQuery += "  AND D3_DOC >= '" + cDocIni + "' "
	EndIf
	If !Empty(cUsr)
		cQuery += "  AND UPPER(LTRIM(RTRIM(D3_USUARIO))) IN (" + cUsr + ") "
	EndIf
	cQuery += "ORDER BY D3_EMISSAO DESC, D3_NUMSEQ DESC "

	DbUseArea(.T., "TOPCONN", TcGenQry(, , cQuery), cAlias, .F., .T.)
	While !(cAlias)->(Eof())
		If aScan(aProd, {|x| x[1] + x[2] == (cAlias)->D3_COD + (cAlias)->D3_LOCAL}) > 0
			aAdd(aRet, {.T., (cAlias)->D3_COD, (cAlias)->D3_LOCAL, StoD((cAlias)->D3_EMISSAO), ;
				(cAlias)->D3_TM, (cAlias)->D3_DOC, (cAlias)->D3_QUANT, (cAlias)->D3_CUSTO1, ;
				AllTrim((cAlias)->D3_USUARIO), (cAlias)->D3_NUMSEQ, (cAlias)->RECNO})
		EndIf
		(cAlias)->(DbSkip())
	EndDo
	(cAlias)->(DbCloseArea())

Return aRet


/*
Tela de marcacao. Duplo clique marca/desmarca.
*/
Static Function TelaMarca(aSB9, aSD3)

	Local oDlg
	Local oLb1
	Local oLb2
	Local oOk   := LoadBitmap(GetResources(), "LBOK")
	Local oNo   := LoadBitmap(GetResources(), "LBNO")
	Local lRet  := .F.
	Local lVz9  := Len(aSB9) == 0
	Local lVz3  := Len(aSD3) == 0

	If lVz9
		aAdd(aSB9, {.F., "(nenhum)", "", CtoD(""), 0, 0, 0})
	EndIf
	If lVz3
		aAdd(aSD3, {.F., "(nenhum)", "", CtoD(""), "", "", 0, 0, "", "", 0})
	EndIf

	DEFINE MSDIALOG oDlg TITLE "Marque o que deve ser limpo (duplo clique marca/desmarca)" FROM 000,000 TO 560,900 PIXEL

	@ 005,005 SAY "SB9 com data depois do MV_ULMES (serao EXCLUIDOS):" SIZE 300,010 OF oDlg PIXEL
	@ 015,005 LISTBOX oLb1 FIELDS HEADER " ", "Produto", "Local", "Data", "Qtd inicial", "Valor inicial", "Recno" ;
		SIZE 440,095 OF oDlg PIXEL ;
		ON DBLCLICK (IIf(!lVz9, aSB9[oLb1:nAt,1] := !aSB9[oLb1:nAt,1], Nil), oLb1:Refresh())
	oLb1:SetArray(aSB9)
	oLb1:bLine := {|| { IIf(aSB9[oLb1:nAt,1], oOk, oNo), aSB9[oLb1:nAt,2], aSB9[oLb1:nAt,3], ;
		DtoC(aSB9[oLb1:nAt,4]), aSB9[oLb1:nAt,5], aSB9[oLb1:nAt,6], aSB9[oLb1:nAt,7] } }

	@ 115,005 SAY "Movimentos SD3 (serao ESTORNADOS pela MATA241). Desmarque os movimentos reais:" SIZE 400,010 OF oDlg PIXEL
	@ 125,005 LISTBOX oLb2 FIELDS HEADER " ", "Produto", "Local", "Emissao", "TM", "Documento", "Qtd", "Custo", "Usuario", "NumSeq" ;
		SIZE 440,125 OF oDlg PIXEL ;
		ON DBLCLICK (IIf(!lVz3, aSD3[oLb2:nAt,1] := !aSD3[oLb2:nAt,1], Nil), oLb2:Refresh())
	oLb2:SetArray(aSD3)
	oLb2:bLine := {|| { IIf(aSD3[oLb2:nAt,1], oOk, oNo), aSD3[oLb2:nAt,2], aSD3[oLb2:nAt,3], ;
		DtoC(aSD3[oLb2:nAt,4]), aSD3[oLb2:nAt,5], aSD3[oLb2:nAt,6], aSD3[oLb2:nAt,7], ;
		aSD3[oLb2:nAt,8], aSD3[oLb2:nAt,9], aSD3[oLb2:nAt,10] } }

	@ 258,290 BUTTON "Confirmar" SIZE 060,014 OF oDlg PIXEL ACTION (lRet := .T., oDlg:End())
	@ 258,355 BUTTON "Cancelar"  SIZE 060,014 OF oDlg PIXEL ACTION oDlg:End()

	ACTIVATE MSDIALOG oDlg CENTERED

	If lVz9
		aSB9 := {}
	EndIf
	If lVz3
		aSD3 := {}
	EndIf

Return lRet


Static Function ExecLimpa(aSB9, aSD3, dUlMes)

	Local aDocs  := {}
	Local nI     := 0
	Local nPos   := 0

	// 1) Estorno dos movimentos marcados, agrupados por documento,
	//    do mais recente para o mais antigo
	For nI := 1 To Len(aSD3)
		If aSD3[nI][1]
			nPos := aScan(aDocs, {|x| x[1] == aSD3[nI][6]})
			If nPos == 0
				aAdd(aDocs, {aSD3[nI][6], 0})
				nPos := Len(aDocs)
			EndIf
			aDocs[nPos][2]++
		EndIf
	Next nI

	ProcRegua(Len(aDocs) + Len(aSB9))

	For nI := 1 To Len(aDocs)
		IncProc("Estornando documento " + aDocs[nI][1])
		EstDoc(aDocs[nI][1], aDocs[nI][2])
	Next nI

	// 2) Exclusao das SB9 marcadas (somente data depois do MV_ULMES)
	For nI := 1 To Len(aSB9)
		IncProc("SB9 " + AllTrim(aSB9[nI][2]))
		If !aSB9[nI][1]
			Loop
		EndIf
		SB9->(DbGoTo(aSB9[nI][7]))
		If SB9->(Eof()) .Or. SB9->(Deleted())
			AddLog(aSB9[nI][2], aSB9[nI][3], "ERRO", "SB9 recno " + cValToChar(aSB9[nI][7]) + " nao encontrado.")
			Loop
		EndIf
		If SB9->B9_DATA <= dUlMes
			AddLog(aSB9[nI][2], aSB9[nI][3], "ERRO", "SB9 de " + DtoC(SB9->B9_DATA) + " e de periodo fechado. Nao excluido.")
			Loop
		EndIf
		RecLock("SB9", .F.)
		SB9->(DbDelete())
		SB9->(MsUnLock())
		AddLog(aSB9[nI][2], aSB9[nI][3], "OK", "SB9 de " + DtoC(aSB9[nI][4]) + " excluido (qtd " + ;
			cValToChar(aSB9[nI][5]) + ", valor " + cValToChar(aSB9[nI][6]) + ").")
	Next nI

Return


/*
Estorna um documento inteiro pela MATA241 (opcao 6).
So estorna se todos os itens ativos do documento estiverem marcados.
*/
Static Function EstDoc(cDoc, nMarcados)

	Local aArea  := GetArea()
	Local aCab   := {}
	Local aItens := {}
	Local aItem  := {}
	Local aErro  := {}
	Local cErro  := ""
	Local cDesc  := ""
	Local nX     := 0
	Local nRecIni := 0

	Private lMsErroAuto    := .F.
	Private lMsHelpAuto    := .T.
	Private lAutoErrNoFile := .T.
	Private l241Auto       := .T.

	SD3->(DbSetOrder(2))   // D3_FILIAL + D3_DOC + D3_COD
	If !SD3->(DbSeek(xFilial("SD3") + cDoc))
		AddLog("", "", "ERRO", "Documento " + cDoc + " nao encontrado.")
		RestArea(aArea)
		Return .F.
	EndIf

	While !SD3->(Eof()) .And. SD3->D3_FILIAL == xFilial("SD3") .And. SD3->D3_DOC == cDoc
		If SD3->D3_ESTORNO <> "S"
			// Guarda o primeiro registro ativo do documento: o MATA241 (estorno)
			// trabalha sobre o registro posicionado no SD3.
			If nRecIni == 0
				nRecIni := SD3->(Recno())
			EndIf
			aItem := {}
			aAdd(aItem, {"D3_COD"    , SD3->D3_COD  , Nil})
			aAdd(aItem, {"D3_UM"     , SD3->D3_UM   , Nil})
			aAdd(aItem, {"D3_QUANT"  , SD3->D3_QUANT, Nil})
			aAdd(aItem, {"D3_LOCAL"  , SD3->D3_LOCAL, Nil})
			aAdd(aItem, {"D3_ESTORNO", "S"          , Nil})
			aAdd(aItens, aClone(aItem))
			cDesc += AllTrim(SD3->D3_COD) + " TM " + SD3->D3_TM + " qtd " + cValToChar(SD3->D3_QUANT) + ;
				" custo " + cValToChar(SD3->D3_CUSTO1) + "; "
		EndIf
		SD3->(DbSkip())
	EndDo

	If Len(aItens) == 0
		AddLog("", "", "ERRO", "Documento " + cDoc + " sem itens ativos.")
		RestArea(aArea)
		Return .F.
	EndIf

	If Len(aItens) <> nMarcados
		AddLog("", "", "ERRO", "Documento " + cDoc + " tem " + cValToChar(Len(aItens)) + ;
			" itens e so " + cValToChar(nMarcados) + " foram marcados. Nao estornado: " + cDesc)
		RestArea(aArea)
		Return .F.
	EndIf

	aAdd(aCab, {"D3_DOC", cDoc, Nil})

	// Reposiciona no primeiro registro ativo do documento. Sem isso o SD3 fica
	// no registro DEPOIS do documento (saida do laco acima) e o estorno atinge
	// o documento errado.
	SD3->(DbSetOrder(2))
	SD3->(DbGoTo(nRecIni))

	MSExecAuto({|x, y, z| MATA241(x, y, z)}, aCab, aItens, 6)

	If lMsErroAuto
		aErro := GetAutoGRLog()
		For nX := 1 To Len(aErro)
			cErro += AllTrim(aErro[nX]) + " "
		Next nX
		RestArea(aArea)
		AddLog("", "", "ERRO", "Estorno do documento " + cDoc + " falhou: " + cDesc + " -> " + cErro)
		Return .F.
	EndIf

	// Confere se o registro foi mesmo marcado como estornado.
	SD3->(DbGoTo(nRecIni))
	If SD3->D3_ESTORNO <> "S"
		RestArea(aArea)
		AddLog("", "", "ERRO", "Documento " + cDoc + ": o ExecAuto nao retornou erro, mas D3_ESTORNO nao foi marcado. Estorne pela tela do MATA241. " + cDesc)
		Return .F.
	EndIf

	RestArea(aArea)
	AddLog("", "", "OK", "Documento " + cDoc + " estornado: " + cDesc)

Return .T.
