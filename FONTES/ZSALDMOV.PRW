#Include "totvs.ch"
#Include "topconn.ch"

/*/{Protheus.doc} ZSALDMOV
Compara os saldos de estoque (SB2) no inicio de duas datas, mostrando
todos os itens e permitindo imprimir a grade.

O saldo no inicio de uma data D e calculado por:
    B2_QATU - (entradas - saidas) do SD3 com D3_EMISSAO a partir de D

Entradas: D3_TM abaixo de 500. Saidas: D3_TM de 500 em diante.
A conta le apenas o SD3 (estornos excluidos); a SD1 nao e lida
diretamente.

@type User Function
@author Suprimentos
@since 28/10/2026
@return Nil
/*/
User Function ZSALDMOV()

    Local aArea    := GetArea()
    Local oDlg
    Local oPanel1
    Local oPanel2
    Local oGetDe, oGetAte, oGetProd, oGetLoc
    Local oBtnProc, oBtnImp, oBtnSai

    // Variaveis compartilhadas com as funcoes estaticas
    Private dDataDe     := dDataBase - 2   // 26/10/2026 com data base 28/10/2026
    Private dDataAte    := dDataBase - 1   // 27/10/2026 com data base 28/10/2026
    Private dProcDe     := CtoD("")        // data efetivamente processada
    Private dProcAte    := CtoD("")
    Private cFiltroProd := Space(TamSX3("B2_COD")[1])
    Private cFiltroLocal := Space(TamSX3("B2_LOCAL")[1])
    Private aDados      := {}
    Private aColunas    := {}
    Private oBrowse
    Private oSayPer
    Private oSayTot
    Private nItensAum   := 0
    Private nItensRed   := 0

    DEFINE MSDIALOG oDlg TITLE "Comparativo de Saldos de Estoque" FROM 000,000 TO 750,1800 PIXEL

    // Painel superior - datas, filtros e acoes
    oPanel1 := TPanel():New(000, 000, "", oDlg, , , , , , 800, 064, .T., .T.)
    oPanel1:Align := CONTROL_ALIGN_TOP

    @ 008, 010 SAY "Data Inicial:" SIZE 060, 007 OF oPanel1 PIXEL
    @ 006, 075 MSGET oGetDe VAR dDataDe SIZE 050, 010 OF oPanel1 PIXEL VALID !Empty(dDataDe)

    @ 008, 135 SAY "Data Final:" SIZE 055, 007 OF oPanel1 PIXEL
    @ 006, 195 MSGET oGetAte VAR dDataAte SIZE 050, 010 OF oPanel1 PIXEL VALID !Empty(dDataAte)

    @ 008, 255 SAY "Produto:" SIZE 045, 007 OF oPanel1 PIXEL
    @ 006, 305 MSGET oGetProd VAR cFiltroProd SIZE 080, 010 OF oPanel1 PIXEL

    @ 008, 392 SAY "Armazem:" SIZE 050, 007 OF oPanel1 PIXEL
    @ 006, 450 MSGET oGetLoc VAR cFiltroLocal SIZE 040, 010 OF oPanel1 PIXEL

    @ 006, 500 BUTTON oBtnProc PROMPT "Processar" SIZE 060, 012 OF oPanel1 PIXEL ACTION ZSAL_Processa()
    @ 006, 565 BUTTON oBtnImp PROMPT "Imprimir" SIZE 060, 012 OF oPanel1 PIXEL ACTION ZSAL_Imprime()
    @ 006, 630 BUTTON oBtnSai PROMPT "Sair" SIZE 050, 012 OF oPanel1 PIXEL ACTION oDlg:End()

    @ 023, 010 SAY "Saldo Inicial = Saldo Atual - (entradas - saidas) do SD3 a partir da data inicial. O Saldo Final usa o mesmo criterio a partir da data final." ;
        SIZE 900, 007 OF oPanel1 PIXEL FONT TFont():New(, , 10, .T.) COLOR CLR_BLUE

    @ 033, 010 SAY oSayPer PROMPT "Datas comparadas: " + DtoC(dDataDe) + " (saldo inicial) e " + DtoC(dDataAte) + " (saldo final)" ;
        SIZE 700, 007 OF oPanel1 PIXEL

    @ 042, 010 SAY oSayTot PROMPT "Processe a consulta para carregar os saldos." ;
        SIZE 700, 018 OF oPanel1 PIXEL FONT TFont():New(, , 16, .T., .T.) COLOR CLR_RED

    // Painel inferior - grade de dados
    oPanel2 := TPanel():New(000, 000, "", oDlg, , , , , , 800, 300, .T., .T.)
    oPanel2:Align := CONTROL_ALIGN_ALLCLIENT

    ZSAL_MontaColunas()

    oBrowse := FWBrowse():New()
    oBrowse:SetOwner(oPanel2)
    oBrowse:SetDataArray()
    oBrowse:SetArray(aDados)
    oBrowse:SetColumns(aColunas)
    oBrowse:DisableConfig()
    oBrowse:Activate()

    ACTIVATE MSDIALOG oDlg CENTERED

    RestArea(aArea)

Return Nil

/*/{Protheus.doc} ZSAL_MontaColunas
Monta as colunas da grade de saldos.

@type   Static Function
@author Suprimentos
@since  28/10/2026
@return Nil
/*/
Static Function ZSAL_MontaColunas()

    Local oColumn

    aColunas := {}

    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aDados[oBrowse:nAt][1]})
    oColumn:SetTitle("Produto")
    oColumn:SetSize(16)
    oColumn:SetAlign(CONTROL_ALIGN_LEFT)
    aAdd(aColunas, oColumn)

    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aDados[oBrowse:nAt][2]})
    oColumn:SetTitle("Descricao")
    oColumn:SetSize(34)
    oColumn:SetAlign(CONTROL_ALIGN_LEFT)
    aAdd(aColunas, oColumn)

    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aDados[oBrowse:nAt][3]})
    oColumn:SetTitle("Armazem")
    oColumn:SetSize(9)
    oColumn:SetAlign(CONTROL_ALIGN_CENTER)
    aAdd(aColunas, oColumn)

    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aDados[oBrowse:nAt][4]})
    oColumn:SetTitle("Saldo Inicial")
    oColumn:SetType("N")
    oColumn:SetPicture("@E 999,999,999.99")
    oColumn:SetSize(16)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aDados[oBrowse:nAt][5]})
    oColumn:SetTitle("Saldo Final")
    oColumn:SetType("N")
    oColumn:SetPicture("@E 999,999,999.99")
    oColumn:SetSize(16)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aDados[oBrowse:nAt][6]})
    oColumn:SetTitle("Variacao")
    oColumn:SetType("N")
    oColumn:SetPicture("@E 999,999,999.99")
    oColumn:SetSize(16)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aDados[oBrowse:nAt][7]})
    oColumn:SetTitle("Saldo Atual")
    oColumn:SetType("N")
    oColumn:SetPicture("@E 999,999,999.99")
    oColumn:SetSize(16)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

Return Nil

/*/{Protheus.doc} ZSAL_Processa
Valida os parametros da tela e dispara a consulta dos saldos.

@type   Static Function
@author Suprimentos
@since  28/10/2026
@return Nil
/*/
Static Function ZSAL_Processa()

    If Empty(dDataDe) .Or. Empty(dDataAte)
        MsgAlert("Informe as duas datas da comparacao.", "Atencao")
        Return
    EndIf

    If dDataDe > dDataAte
        MsgAlert("A data inicial nao pode ser maior que a data final.", "Atencao")
        Return
    EndIf

    If dDataAte > dDataBase
        MsgAlert("A data final nao pode ser maior que a data base (" + DtoC(dDataBase) + ").", "Atencao")
        Return
    EndIf

    // CA2050: conteudo digitado validado antes de entrar na query (anti-injection)
    If !Empty(AllTrim(cFiltroProd)) .And. !ZSAL_VldTxt(AllTrim(cFiltroProd), "produto")
        Return
    EndIf

    If !Empty(AllTrim(cFiltroLocal)) .And. !ZSAL_VldTxt(AllTrim(cFiltroLocal), "armazem")
        Return
    EndIf

    Processa({|| ZSAL_Carrega()}, "Consultando saldos...")

    If oBrowse != Nil
        oBrowse:SetArray(aDados)
        oBrowse:GoTop()
        oBrowse:Refresh()
    EndIf

    If Len(aDados) == 0
        MsgInfo("Nenhum saldo encontrado para os filtros informados.", "Saldos")
    EndIf

Return Nil

/*/{Protheus.doc} ZSAL_VldTxt
Valida o texto digitado nos filtros de produto e armazem, aceitando
somente letras, numeros, ponto, hifen, sublinhado e barra.

@param  cTxt      Texto informado pelo usuario
@param  cCampo    Nome do campo exibido na mensagem de erro
@type   Static Function
@author Suprimentos
@since  28/10/2026
@return Logico .T. quando o texto pode ser usado na query
/*/
Static Function ZSAL_VldTxt(cTxt, cCampo)

    Local nI   := 0
    Local cChr := ""

    For nI := 1 To Len(cTxt)
        cChr := SubStr(cTxt, nI, 1)
        If !(Upper(cChr) $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_/")
            MsgAlert("Caractere invalido no filtro de " + cCampo + ": [" + cChr + "].", "Atencao")
            Return .F.
        EndIf
    Next nI

Return .T.

/*/{Protheus.doc} ZSAL_Carrega
Consulta todos os saldos do SB2 e calcula, para cada item, o saldo no
inicio da data inicial e no inicio da data final, alem da variacao.

@type   Static Function
@author Suprimentos
@since  28/10/2026
@return Nil
/*/
Static Function ZSAL_Carrega()

    Local aArea     := GetArea()
    Local cAlias    := GetNextAlias()
    Local cQuery    := ""
    Local cProd     := PadR(SubStr(AllTrim(cFiltroProd), 1, TamSX3("B2_COD")[1]), TamSX3("B2_COD")[1])
    Local cLocal    := PadR(SubStr(AllTrim(cFiltroLocal), 1, TamSX3("B2_LOCAL")[1]), TamSX3("B2_LOCAL")[1])
    Local nSaldoAtu := 0
    Local nSaldoIni := 0
    Local nSaldoFim := 0
    Local nMovDe    := 0
    Local nMovAte   := 0
    Local nVar      := 0

    dProcDe  := dDataDe
    dProcAte := dDataAte

    aDados    := {}
    nItensAum := 0
    nItensRed := 0

    cQuery := " SELECT B2.B2_COD AS CODIGO, B2.B2_LOCAL AS LOCAL, B2.B2_QATU AS SALDO_ATU, "
    cQuery += "        B1.B1_DESC AS DESCRICAO, "
    cQuery += "        ISNULL(MOV.ENT_DE, 0) AS ENT_DE, ISNULL(MOV.SAI_DE, 0) AS SAI_DE, "
    cQuery += "        ISNULL(MOV.ENT_ATE, 0) AS ENT_ATE, ISNULL(MOV.SAI_ATE, 0) AS SAI_ATE "
    cQuery += "   FROM " + RetSqlName("SB2") + " B2 WITH (NOLOCK) "
    cQuery += "   LEFT JOIN " + RetSqlName("SB1") + " B1 WITH (NOLOCK) "
    cQuery += "          ON B1.B1_FILIAL = '" + xFilial("SB1") + "' "
    cQuery += "         AND B1.B1_COD = B2.B2_COD "
    cQuery += "         AND B1.D_E_L_E_T_ = ' ' "
    cQuery += "   LEFT JOIN ( "
    cQuery += "        SELECT D3.D3_COD AS CODIGO, D3.D3_LOCAL AS LOCAL, "
    cQuery += "               SUM(CASE WHEN D3.D3_TM < '500' AND D3.D3_EMISSAO >= '" + DtoS(dDataDe) + "' THEN D3.D3_QUANT ELSE 0 END) AS ENT_DE, "
    cQuery += "               SUM(CASE WHEN D3.D3_TM >= '500' AND D3.D3_EMISSAO >= '" + DtoS(dDataDe) + "' THEN D3.D3_QUANT ELSE 0 END) AS SAI_DE, "
    cQuery += "               SUM(CASE WHEN D3.D3_TM < '500' AND D3.D3_EMISSAO >= '" + DtoS(dDataAte) + "' THEN D3.D3_QUANT ELSE 0 END) AS ENT_ATE, "
    cQuery += "               SUM(CASE WHEN D3.D3_TM >= '500' AND D3.D3_EMISSAO >= '" + DtoS(dDataAte) + "' THEN D3.D3_QUANT ELSE 0 END) AS SAI_ATE "
    cQuery += "          FROM " + RetSqlName("SD3") + " D3 WITH (NOLOCK) "
    cQuery += "         WHERE D3.D_E_L_E_T_ = ' ' "
    cQuery += "           AND D3.D3_ESTORNO = ' ' "
    cQuery += "           AND D3.D3_FILIAL = '" + xFilial("SD3") + "' "
    cQuery += "           AND D3.D3_EMISSAO >= '" + DtoS(dDataDe) + "' "
    cQuery += "         GROUP BY D3.D3_COD, D3.D3_LOCAL "
    cQuery += "         ) MOV "
    cQuery += "          ON MOV.CODIGO = B2.B2_COD "
    cQuery += "         AND MOV.LOCAL = B2.B2_LOCAL "
    cQuery += "  WHERE B2.D_E_L_E_T_ = ' ' "
    cQuery += "    AND B2.B2_FILIAL = '" + xFilial("SB2") + "' "
    If !Empty(cProd)
        cQuery += "    AND B2.B2_COD = '" + cProd + "' "
    EndIf
    If !Empty(cLocal)
        cQuery += "    AND B2.B2_LOCAL = '" + cLocal + "' "
    EndIf
    cQuery += "  ORDER BY B2.B2_COD, B2.B2_LOCAL "
    cQuery := ChangeQuery(cQuery)
    cQuery := StrTran(cQuery, "(NOLOCK)", "")              // normaliza (evita dica duplicada)
    cQuery := StrTran(cQuery, " WITH ", " WITH (NOLOCK) ") // reinjeta a dica que o ChangeQuery remove

    DbUseArea(.T., "TOPCONN", TCGenQry(, , cQuery), cAlias, .F., .T.)
    TCSetField(cAlias, "SALDO_ATU", "N", 16, 4)
    TCSetField(cAlias, "ENT_DE",    "N", 16, 4)
    TCSetField(cAlias, "SAI_DE",    "N", 16, 4)
    TCSetField(cAlias, "ENT_ATE",   "N", 16, 4)
    TCSetField(cAlias, "SAI_ATE",   "N", 16, 4)

    (cAlias)->(DbGoTop())
    While !(cAlias)->(Eof())
        nSaldoAtu := (cAlias)->SALDO_ATU
        nMovDe    := (cAlias)->ENT_DE - (cAlias)->SAI_DE
        nMovAte   := (cAlias)->ENT_ATE - (cAlias)->SAI_ATE
        nSaldoIni := nSaldoAtu - nMovDe
        nSaldoFim := nSaldoAtu - nMovAte
        nVar      := nSaldoFim - nSaldoIni

        // [1] Produto [2] Descricao [3] Armazem [4] Saldo inicial
        // [5] Saldo final [6] Variacao [7] Saldo atual
        aAdd(aDados, { ;
            AllTrim((cAlias)->CODIGO), ;
            AllTrim((cAlias)->DESCRICAO), ;
            AllTrim((cAlias)->LOCAL), ;
            nSaldoIni, ;
            nSaldoFim, ;
            nVar, ;
            nSaldoAtu })

        If nVar > 0
            nItensAum++
        ElseIf nVar < 0
            nItensRed++
        EndIf

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    If oSayPer != Nil
        oSayPer:SetText("Datas comparadas: " + DtoC(dProcDe) + " (saldo inicial) e " + DtoC(dProcAte) + " (saldo final)")
    EndIf

    If oSayTot != Nil
        oSayTot:SetText("Itens: " + cValToChar(Len(aDados)) + ;
            "   |   Aumentaram: " + cValToChar(nItensAum) + ;
            "   |   Reduziram: " + cValToChar(nItensRed) + ;
            "   |   Sem variacao: " + cValToChar(Len(aDados) - nItensAum - nItensRed))
    EndIf

    RestArea(aArea)

Return Nil

/*/{Protheus.doc} ZSAL_Imprime
Abre o dialogo de impressao do Protheus (impressora, PDF, HTML ou
planilha) com a grade de saldos carregada.

@type   Static Function
@author Suprimentos
@since  28/10/2026
@return Nil
/*/
Static Function ZSAL_Imprime()

    Local oReport  := Nil
    Local oSection := Nil

    If Len(aDados) == 0
        MsgAlert("Processe a consulta antes de imprimir.", "Atencao")
        Return
    EndIf

    oReport := TReport():New("ZSALDMOV", "Comparativo de Saldos de Estoque", "", ;
        {|oReport| ZSAL_Rep(oReport)}, ;
        "Saldo no inicio de " + DtoC(dProcDe) + " comparado com o inicio de " + DtoC(dProcAte))
    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    oSection := TRSection():New(oReport, "Saldos", {})
    TRCell():New(oSection, "PRODUTO",   "", "Produto",      "@!",                 16)
    TRCell():New(oSection, "DESCRICAO", "", "Descricao",    "@!",                 34)
    TRCell():New(oSection, "ARMAZEM",   "", "Armazem",      "@!",                  9)
    TRCell():New(oSection, "SALDOINI",  "", "Saldo Inicial", "@E 999,999,999.99", 16)
    TRCell():New(oSection, "SALDOFIM",  "", "Saldo Final",   "@E 999,999,999.99", 16)
    TRCell():New(oSection, "VARIACAO",  "", "Variacao",      "@E 999,999,999.99", 16)
    TRCell():New(oSection, "SALDOATU",  "", "Saldo Atual",   "@E 999,999,999.99", 16)

    oReport:PrintDialog()

Return Nil

/*/{Protheus.doc} ZSAL_Rep
Popula o relatorio com os saldos carregados na grade.

@param  oReport   Objeto TReport criado em ZSAL_Imprime
@type   Static Function
@author Suprimentos
@since  28/10/2026
@return Nil
/*/
Static Function ZSAL_Rep(oReport)

    Local oSection := oReport:Section(1)
    Local nI       := 0
    Local nAum     := 0
    Local nRed     := 0

    oReport:SetMeter(Len(aDados))
    oSection:Init()
    oSection:SetHeaderSection(.T.)
    oReport:PrintText("Saldo Inicial: saldo no inicio de " + DtoC(dProcDe) + " (saldo atual menos os movimentos do SD3 a partir dessa data).", 0)
    oReport:PrintText("Saldo Final: saldo no inicio de " + DtoC(dProcAte) + ", com o mesmo criterio.", 0)
    oReport:PrintText("Entradas: tipos de movimento abaixo de 500. Saidas: 500 em diante. Estornos excluidos.", 0)
    oReport:PrintText("A conta le apenas o SD3; a SD1 nao e lida diretamente.", 0)
    oReport:SkipLine()

    For nI := 1 To Len(aDados)
        oSection:Cell("PRODUTO"):SetValue(aDados[nI][1])
        oSection:Cell("DESCRICAO"):SetValue(aDados[nI][2])
        oSection:Cell("ARMAZEM"):SetValue(aDados[nI][3])
        oSection:Cell("SALDOINI"):SetValue(aDados[nI][4])
        oSection:Cell("SALDOFIM"):SetValue(aDados[nI][5])
        oSection:Cell("VARIACAO"):SetValue(aDados[nI][6])
        oSection:Cell("SALDOATU"):SetValue(aDados[nI][7])
        oSection:PrintLine()

        If aDados[nI][6] > 0
            nAum++
        ElseIf aDados[nI][6] < 0
            nRed++
        EndIf

        oReport:IncMeter()
    Next nI

    oReport:SkipLine()
    oReport:PrintText("Itens listados: " + cValToChar(Len(aDados)) + " | Aumentaram: " + cValToChar(nAum) + " | Reduziram: " + cValToChar(nRed), 0)

Return Nil
