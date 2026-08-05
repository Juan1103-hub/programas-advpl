#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

// Arrays estaticos de dados
Static aDados     := {}
Static aDadosOrig := {}

// Totalizadores
Static nTotItens    := 0    // Qtd itens distintos com baixa no periodo
Static nVlrInicial  := 0    // Valor saldo inicial do almoxarifado no periodo
Static nVlrTotal    := 0    // Valor saldo final do almoxarifado no periodo
Static nVlrEntradas := 0    // Valor total das entradas no periodo
Static nVlrSaidas   := 0    // Valor total das baixas no periodo
Static nVlrSaldoSB2 := 0    // Valor SB2 na data final para itens do periodo
Static nVlrRazAnt   := 0    // Saldo anterior dos itens da conta/armazem
Static nVlrRazDeb   := 0    // Entradas dos itens da conta/armazem no periodo
Static nVlrRazCred  := 0    // Baixas dos itens da conta/armazem no periodo
Static nVlrRazMov   := 0    // Movimento dos itens no periodo (entradas - baixas)
Static nVlrRazFinal := 0    // Saldo final dos itens da conta/armazem

/*/{Protheus.doc} ZSLDEST
Kardex Diário do Almoxarifado
Exibe a movimentação consolidada para itens com saida no periodo
com conta contabil (B1_XCTAEST) informada (padrao 11401200001).
Mostra valores de abertura, entradas, baixas e fechamento do almoxarifado.
Reconstroi o saldo diário a partir do SB2 (saldo atual)
considerando SD1, SD2 e SD3.
Exibe no rodape o resultado do razao esperado para os itens filtrados.
@type User Function
@version 12.1.33
@author Gemini Code Assist
@since 20/04/2026
/*/
User Function ZSLDEST()
    Local aArea    := GetArea()
    Local aPar     := {}
    Local aRet     := {}
    Local dDtDe    := CtoD("")
    Local dDtAte   := Date()
    Local cConta   := ""
    Local cProdF   := ""
    Local cArmazem := "02"

    // Inicializa estaticas
    aDados       := {}
    aDadosOrig   := {}
    nTotItens    := 0
    nVlrInicial  := 0
    nVlrTotal    := 0
    nVlrEntradas := 0
    nVlrSaidas   := 0
    nVlrSaldoSB2 := 0
    nVlrRazAnt   := 0
    nVlrRazDeb   := 0
    nVlrRazCred  := 0
    nVlrRazMov   := 0
    nVlrRazFinal := 0

    // Parametros
    aAdd(aPar, {1, "Periodo De",                   dDtDe,         "", "", "", "", 60, .T.})
    aAdd(aPar, {1, "Periodo Ate",                  dDtAte,        "", "", "", "", 60, .T.})
    aAdd(aPar, {1, "Conta Contabil (B1_XCTAEST)",  "11401200001", "", "", "", "", 80, .T.})

    If !ParamBox(aPar, "Saldo Mensal do Almoxarifado", @aRet)
        RestArea(aArea)
        Return
    EndIf

    dDtDe    := aRet[1]
    dDtAte   := aRet[2]
    cProdF   := ""
    cConta   := AllTrim(aRet[3])

    // Validacoes
    If Empty(dDtDe) .Or. Empty(dDtAte)
        MsgAlert("Informe o periodo completo!", "Atencao")
        RestArea(aArea)
        Return
    EndIf

    If dDtAte < dDtDe
        MsgAlert("Data final nao pode ser anterior a data inicial!", "Atencao")
        RestArea(aArea)
        Return
    EndIf

    If Empty(cConta)
        MsgAlert("Informe a conta contabil!", "Atencao")
        RestArea(aArea)
        Return
    EndIf

    // Processa
    Processa({|| ZSLD_Dados(dDtDe, dDtAte, cConta, cArmazem, cProdF)}, "Processando Kardex Diário...")

    If Len(aDados) > 0
        ZSLD_Tela(dDtDe, dDtAte, cConta)
    Else
        MsgInfo("Nenhum dado encontrado para o periodo!" + Chr(13) + Chr(10) + ;
                "Verifique os filtros informados.", "Atencao")
    EndIf

    RestArea(aArea)
Return

Static Function ZSLD_Dados(dDtDe, dDtAte, cConta, cArmazem, cProdF)
    Local cAlias       := ""
    Local cQuery       := ""
    Local nI           := 0
    Local nJ           := 0
    Local nSaldoFinal  := 0
    Local nSaldoIni    := 0
    Local nSaldoRetro  := 0
    Local nSaldoHistBase := 0
    Local nSaldoAtualCalc := 0
    Local nSaldoMin    := 0
    Local nSaldoCalc   := 0
    Local nEntPeriodo  := 0
    Local nSaiPeriodo  := 0
    Local nCustoUnit   := 0
    Local nVlrFinal    := 0
    Local nValorEnt    := 0   // Valor total das entradas no periodo para CM ponderado
    Local nValorSai    := 0   // Valor total das baixas no periodo
    Local nCustoSai    := 0   // Custo unitario usado na baixa do periodo
    Local nValorIni    := 0   // Valor saldo de abertura (SB9 fechamento mes anterior)
    Local cProd        := ""
    Local cLocal       := ""
    Local cDesc        := ""
    Local nPos         := 0
    Local aBalances    := {}   // {cProd, cDesc, cLocal, nQFim, nVFim}  <- de SB9
    Local aSB9Fut      := {}   // Proximo saldo futuro SB9: {cProd, cLocal, cData, nQFim, nVFim}
    Local aMovs        := {}   // Movimentos dDtDe-dDtAte: {cProd, cLocal, cTipo, nQtd, cDt, nVlr}
    Local aMovAnt      := {}   // Movimentos entre saldo SB9 e dDtDe: {cProd, cLocal, cTipo, nQtd, cDt, nVlr}
    Local aMovProd     := {}
    Local aSaldoHist   := {}   // Saldo antes de dDtDe via movimentos historicos: {cProd, cLocal, nSaldo}
    Local aFutKeys     := {}
    Local cMovKey      := ""
    Local cFiltB1      := ""
    Local lHasF4Est    := .F.
    Local cAliasCol    := GetNextAlias()
    Local cTblSF4      := RetSqlName("SF4")
    Local nMesAnt      := 0
    Local nAnoAnt      := 0
    Local cMesAnt      := ""
    Local cAnoAnt      := ""
    Local cDtSB9Ini    := ""
    Local cDtSB9Ant    := ""
    Local lB9MesAno    := .F.   // SB9 usa B9_MES / B9_ANO separados
    Local lB9Data      := .F.   // SB9 usa B9_DATA
    Local lSaldoHistOk := .F.   // .T. quando historico antes do periodo reconcilia com SB2
    Local cB9QFim      := ""    // nome da coluna de qtd final/inicial no SB9
    Local cB9VFim      := ""    // nome da coluna de vlr final/inicial no SB9
    Local lB9IsIni     := .F.   // .T. = usando B9_QINI/B9_VINI (saldo inicial do mes)
    Local cAliasB9     := ""
    Local aSB2         := {}    // Saldo atual SB2 por produto: {cProd, cLocal, nQATU, nVATU, nCM1}
    Local nCustoUnit2  := 0     // Custo unitario da ultima entrada conhecida
    Local nCustoUltEnt := 0     // Ultimo custo de entrada ate o fim do periodo
    Local nEntPosFim   := 0     // Entradas apos dDtAte (para retroativo SB2)
    Local nSaiPosFim   := 0     // Saidas apos dDtAte (para retroativo SB2)
    Local nVlrEntFut   := 0     // Valor entradas apos dDtAte (retroativo SB2)
    Local nVlrSaiFut   := 0     // Valor saidas apos dDtAte (retroativo SB2)
    Local nVlrSB2Fim   := 0     // Valor SB2 recalculado na data final
    Local lSaldoSB9    := .F.   // .T. quando saldo veio do SB9, senao retroativo SB2
    Local nPosSB2      := 0
    Local aMovPosFim   := {}    // Movimentos apos dDtAte (para retroativo SB2)
    Local nQtdKdx      := 0     // Qtd corrente no loop Kardex
    Local nVlrKdx      := 0     // Valor total corrente no loop Kardex
    Local nCMKdx       := 0     // Custo medio corrente no loop Kardex
    Local nCM_abertura := 0     // CM de abertura do periodo (custo unitario da primeira saida)
    Local aLastCust    := {}    // Ultimo custo de entrada por produto antes de dDtDe: {cProd, cLocal, nCusto, cDt}
    Local nPosLC       := 0     // Posicao em aLastCust
    Local nPosHist     := 0     // Posicao em aSaldoHist
    Local nPosSB9Fut   := 0     // Posicao em aSB9Fut
    Local cDtBaseFut   := ""    // Data do proximo SB9 futuro
    Local nSaldoFimBase:= 0     // Saldo final do periodo calculado pelo SB9 futuro
    Local nEntSB9Fut   := 0     // Entradas de dDtAte ate o SB9 futuro
    Local nSaiSB9Fut   := 0     // Saidas de dDtAte ate o SB9 futuro
    Local lEntradaAntes := .F.  // Indica entrada antes da primeira saida do periodo
    Local lTemSaidaPer := .F.   // Indica se houve baixa/saida no periodo selecionado
    Local nUltCustoEnt := 0     // Ultimo custo de entrada conhecido para fallback
    Local cDtB9Base    := ""    // Data base do saldo SB9 usado na abertura
    Local nQtdPreKdx   := 0     // Saldo em qtd ajustado entre SB9 e dDtDe
    Local nVlrPreKdx   := 0     // Valor ajustado entre SB9 e dDtDe
    Local nCMPreKdx    := 0     // Custo medio ajustado entre SB9 e dDtDe
    Local aRaz         := {}

    cFiltB1 := " AND B1.B1_XCTAEST = '" + PadR(cConta, TamSX3("B1_XCTAEST")[1]) + "' "
    If !Empty(cProdF)
        cFiltB1 += " AND B1.B1_COD = '" + cProdF + "' "
    EndIf

    aDados       := {}
    aDadosOrig   := {}
    nTotItens    := 0
    nVlrInicial  := 0
    nVlrTotal    := 0
    nVlrEntradas := 0
    nVlrSaidas   := 0
    nVlrSaldoSB2 := 0
    nVlrRazAnt   := 0
    nVlrRazDeb   := 0
    nVlrRazCred  := 0
    nVlrRazMov   := 0
    nVlrRazFinal := 0

    // 0. Verifica existencia da coluna F4_ESTOQUE no SF4 (TES fiscal)
    //    Se existir, usa JOIN SF4010 no SD1 para filtrar somente TES que atualizam estoque.
    //    Exclui automaticamente TES como 125 (F4_ESTOQUE='N') que nao movimentam estoque.
    cQuery := "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS "
    cQuery += "WHERE TABLE_NAME = '" + cTblSF4 + "' AND COLUMN_NAME = 'F4_ESTOQUE'"
    DbUseArea(.T., "TOPCONN", TcGenQry(,, ChangeQuery(cQuery)), cAliasCol, .F., .T.)
    If !(cAliasCol)->(Eof())
        lHasF4Est := .T.
    EndIf
    (cAliasCol)->(DbCloseArea())

    // 1. Busca saldo atual SB2 por produto (usado para totalizador e fallback retroativo)
    IncProc("Buscando saldo atual SB2...")
    cAlias := GetNextAlias()
    cQuery := " SELECT B2.B2_COD, B2.B2_LOCAL, "
    cQuery += "   ISNULL(B2.B2_QATU, 0)  AS QATU, "
    cQuery += "   ISNULL(B2.B2_VATU1, 0) AS VATU, "
    cQuery += "   ISNULL(B2.B2_CM1, 0)   AS CM1 "
    cQuery += " FROM " + RetSqlName("SB2") + " B2 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 "
    cQuery += "   ON B1.B1_COD = B2.B2_COD AND B1.B1_FILIAL = '" + xFilial("SB1") + "' AND B1.D_E_L_E_T_=' ' "
    cQuery += " WHERE B2.D_E_L_E_T_=' ' AND B2.B2_FILIAL = '" + xFilial("SB2") + "' "
    cQuery += cFiltB1
    If !Empty(cArmazem)
        cQuery += " AND B2.B2_LOCAL = '" + cArmazem + "' "
    EndIf
    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    TCSetField(cAlias, "QATU", "N", 16, 4)
    TCSetField(cAlias, "VATU", "N", 16, 2)
    TCSetField(cAlias, "CM1",  "N", 16, 4)
    (cAlias)->(DbGoTop())
    While !(cAlias)->(EoF())
        aAdd(aSB2, { ;
            AllTrim((cAlias)->B2_COD), ;     // [1] Produto
            AllTrim((cAlias)->B2_LOCAL), ;   // [2] Armazem
            (cAlias)->QATU, ;               // [3] Qtd atual
            (cAlias)->VATU, ;               // [4] Valor atual
            (cAlias)->CM1 })                // [5] Custo medio atual
        (cAlias)->(DbSkip())
    End
    (cAlias)->(DbCloseArea())

    // 1.5 Saldo historico antes do periodo.
    //     Quando nao ha SB9 anterior, o Kardex nativo parte do saldo acumulado
    //     ate a data inicial, nao do SB2 atual. Usa o mesmo criterio de estoque:
    //     entradas por SD1+SF4 e SD3(TM<=499), saidas por SD3(TM>499).
    IncProc("Buscando saldo historico antes do periodo...")
    cAlias := GetNextAlias()
    cQuery := " SELECT M.COD, M.LOC, SUM(M.ENT - M.SAI) SALDO "
    cQuery += " FROM ( "
    cQuery += " SELECT D3.D3_COD COD, D3.D3_LOCAL LOC, 0 ENT, ISNULL(D3.D3_QUANT,0) SAI "
    cQuery += " FROM " + RetSqlName("SD3") + " D3 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.B1_COD=D3.D3_COD AND B1.D_E_L_E_T_=' ' "
    cQuery += " WHERE D3.D3_FILIAL='" + xFilial("SD3") + "' "
    cQuery += " AND D3.D3_EMISSAO < '" + DtoS(dDtDe) + "' "
    cQuery += " AND D3.D3_TM > '499' "
    cQuery += " AND D3.D3_ESTORNO=' ' AND D3.D_E_L_E_T_=' ' " + cFiltB1
    If !Empty(cArmazem)
        cQuery += " AND D3.D3_LOCAL='" + cArmazem + "' "
    EndIf
    cQuery += " UNION ALL "
    cQuery += " SELECT D3.D3_COD COD, D3.D3_LOCAL LOC, ISNULL(D3.D3_QUANT,0) ENT, 0 SAI "
    cQuery += " FROM " + RetSqlName("SD3") + " D3 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.B1_COD=D3.D3_COD AND B1.D_E_L_E_T_=' ' "
    cQuery += " WHERE D3.D3_FILIAL='" + xFilial("SD3") + "' "
    cQuery += " AND D3.D3_EMISSAO < '" + DtoS(dDtDe) + "' "
    cQuery += " AND D3.D3_TM <= '499' "
    cQuery += " AND D3.D3_ESTORNO=' ' AND D3.D_E_L_E_T_=' ' " + cFiltB1
    If !Empty(cArmazem)
        cQuery += " AND D3.D3_LOCAL='" + cArmazem + "' "
    EndIf
    cQuery += " UNION ALL "
    cQuery += " SELECT D1.D1_COD COD, D1.D1_LOCAL LOC, ISNULL(D1.D1_QUANT,0) ENT, 0 SAI "
    cQuery += " FROM " + RetSqlName("SD1") + " D1 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.B1_COD=D1.D1_COD AND B1.D_E_L_E_T_=' ' "
    If lHasF4Est
        cQuery += " INNER JOIN " + RetSqlName("SF4") + " F4 ON F4.F4_FILIAL='" + xFilial("SF4") + "' AND F4.F4_CODIGO=D1.D1_TES AND F4.F4_ESTOQUE='S' AND F4.D_E_L_E_T_=' ' "
    EndIf
    cQuery += " WHERE D1.D1_FILIAL='" + xFilial("SD1") + "' "
    cQuery += " AND D1.D1_DTDIGIT < '" + DtoS(dDtDe) + "' "
    If !lHasF4Est
        cQuery += " AND LEFT(D1.D1_CF,1) IN ('1','2','3') "
    EndIf
    cQuery += " AND D1.D_E_L_E_T_=' ' " + cFiltB1
    If !Empty(cArmazem)
        cQuery += " AND D1.D1_LOCAL='" + cArmazem + "' "
    EndIf
    cQuery += " ) M "
    cQuery += " GROUP BY M.COD, M.LOC "
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    TCSetField(cAlias, "SALDO", "N", 16, 4)
    (cAlias)->(DbGoTop())
    While !(cAlias)->(EoF())
        aAdd(aSaldoHist, { ;
            AllTrim((cAlias)->COD), ;
            AllTrim((cAlias)->LOC), ;
            (cAlias)->SALDO })
        (cAlias)->(DbSkip())
    End
    (cAlias)->(DbCloseArea())

    // 2. Saldo de ABERTURA via SB9 (mesmo logica do Kardex Diario - MATA230)
    //    Detecta colunas do SB9 dinamicamente pois a estrutura varia entre versoes:
    //    - Versao A: B9_MES (MM) + B9_ANO (YYYY) + B9_QFIM + B9_VFIM
    //    - Versao B: B9_DATA (YYYYMMDD/legado YYYYMM) + B9_QINI/B9_VINI1 ou B9_QATU/B9_VATU
    IncProc("Buscando saldo inicial (SB9)...")
    nMesAnt := Month(dDtDe) - 1
    nAnoAnt := Year(dDtDe)
    If nMesAnt == 0
        nMesAnt := 12
        nAnoAnt -= 1
    EndIf
    cMesAnt := PadL(cValToChar(nMesAnt), 2, '0')
    cAnoAnt := cValToChar(nAnoAnt)
    cDtSB9Ini := DtoS(dDtDe)
    cDtSB9Ant := DtoS(dDtDe - Day(dDtDe))

    // Detecta quais colunas existem no SB9 deste banco
    cAliasB9 := GetNextAlias()
    cQuery := "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS "
    cQuery += "WHERE TABLE_NAME = '" + RetSqlName("SB9") + "' "
    cQuery += "AND COLUMN_NAME IN ('B9_MES','B9_ANO','B9_DATA','B9_QFIM','B9_QINI','B9_QATU','B9_VFIM','B9_VINI1','B9_VATU','B9_VATU1')"
    DbUseArea(.T., "TOPCONN", TcGenQry(,, ChangeQuery(cQuery)), cAliasB9, .F., .T.)
    (cAliasB9)->(DbGoTop())
    While !(cAliasB9)->(EoF())
        Do Case
            Case AllTrim((cAliasB9)->COLUMN_NAME) == "B9_MES"   ; lB9MesAno := .T.
            Case AllTrim((cAliasB9)->COLUMN_NAME) == "B9_DATA"  ; lB9Data   := .T.
            // Prioridade: B9_QFIM (saldo final) > B9_QINI (saldo inicial do mes) > B9_QATU
            Case AllTrim((cAliasB9)->COLUMN_NAME) == "B9_QFIM"  ; cB9QFim := "B9_QFIM" ; lB9IsIni := .F.
            Case AllTrim((cAliasB9)->COLUMN_NAME) == "B9_QINI"  ; If Empty(cB9QFim)  ; cB9QFim := "B9_QINI"  ; lB9IsIni := .T. ; EndIf
            Case AllTrim((cAliasB9)->COLUMN_NAME) == "B9_QATU"  ; If Empty(cB9QFim)  ; cB9QFim := "B9_QATU"  ; EndIf
            // Prioridade: B9_VFIM > B9_VINI1 > B9_VATU > B9_VATU1
            Case AllTrim((cAliasB9)->COLUMN_NAME) == "B9_VFIM"  ; cB9VFim := "B9_VFIM"
            Case AllTrim((cAliasB9)->COLUMN_NAME) == "B9_VINI1" ; If Empty(cB9VFim)  ; cB9VFim := "B9_VINI1" ; EndIf
            Case AllTrim((cAliasB9)->COLUMN_NAME) == "B9_VATU"  ; If Empty(cB9VFim)  ; cB9VFim := "B9_VATU"  ; EndIf
            Case AllTrim((cAliasB9)->COLUMN_NAME) == "B9_VATU1" ; If Empty(cB9VFim)  ; cB9VFim := "B9_VATU1" ; EndIf
        EndCase
        (cAliasB9)->(DbSkip())
    End
    (cAliasB9)->(DbCloseArea())

    // So executa a query SB9 se as colunas necessarias existirem
    If (lB9MesAno .Or. lB9Data) .And. !Empty(cB9QFim) .And. !Empty(cB9VFim)
        cAlias := GetNextAlias()
        cQuery := " SELECT B9.B9_COD, B9.B9_LOCAL, B1.B1_DESC, "
        If lB9Data
            cQuery += "   B9.B9_DATA AS DTB9, "
        ElseIf lB9IsIni
            cQuery += "   '" + cDtSB9Ini + "' AS DTB9, "
        Else
            cQuery += "   '" + cDtSB9Ant + "' AS DTB9, "
        EndIf
        cQuery += "   ISNULL(B9." + cB9QFim + ", 0) AS QFIM, "
        cQuery += "   ISNULL(B9." + cB9VFim + ", 0) AS VFIM "
        cQuery += " FROM " + RetSqlName("SB9") + " B9 "
        cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 "
        cQuery += "   ON B1.B1_COD = B9.B9_COD "
        cQuery += "   AND B1.B1_FILIAL = '" + xFilial("SB1") + "' "
        cQuery += "   AND B1.D_E_L_E_T_ = ' ' "
        cQuery += " WHERE B9.D_E_L_E_T_ = ' ' "
        cQuery += "   AND B9.B9_FILIAL = '" + xFilial("SB9") + "' "
        // Se B9_QINI (saldo inicial do mes), filtra pelo mes/ano de dDtDe;
        // se B9_QFIM (saldo final do mes anterior), filtra pelo mes anterior
        If lB9MesAno
            If lB9IsIni
                cQuery += "   AND B9.B9_MES = '" + PadL(cValToChar(Month(dDtDe)), 2, '0') + "' "
                cQuery += "   AND B9.B9_ANO = '" + cValToChar(Year(dDtDe)) + "' "
            Else
                cQuery += "   AND B9.B9_MES = '" + cMesAnt + "' "
                cQuery += "   AND B9.B9_ANO = '" + cAnoAnt + "' "
            EndIf
        Else // lB9Data: pega o ultimo saldo anterior/igual a data base
            If lB9IsIni
                cQuery += "   AND B9.B9_DATA <= '" + cDtSB9Ini + "' "
            Else
                cQuery += "   AND B9.B9_DATA <= '" + cDtSB9Ant + "' "
            EndIf
        EndIf
        cQuery += cFiltB1
        If !Empty(cArmazem)
            cQuery += "   AND B9.B9_LOCAL = '" + cArmazem + "' "
        EndIf
        If lB9Data
            cQuery += " ORDER BY B9.B9_COD, B9.B9_LOCAL, B9.B9_DATA DESC "
        Else
            cQuery += " ORDER BY B9.B9_COD, B9.B9_LOCAL "
        EndIf
        cQuery := ChangeQuery(cQuery)

        DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
        TCSetField(cAlias, "QFIM", "N", 16, 4)
        TCSetField(cAlias, "VFIM", "N", 16, 2)
        (cAlias)->(DbGoTop())
        While !(cAlias)->(EoF())
            cProd  := AllTrim((cAlias)->B9_COD)
            cLocal := AllTrim((cAlias)->B9_LOCAL)
            nPos   := AScan(aBalances, {|x| x[1] == cProd .And. x[3] == cLocal})
            If nPos == 0
                aAdd(aBalances, { ;
                    cProd, ;                       // [1] Produto
                    AllTrim((cAlias)->B1_DESC), ;  // [2] Descricao
                    cLocal, ;                      // [3] Armazem
                    (cAlias)->QFIM, ;              // [4] Saldo fechamento/inicial SB9
                    (cAlias)->VFIM, ;              // [5] Valor fechamento/inicial SB9
                    AllTrim((cAlias)->DTB9) })      // [6] Data base do saldo SB9
            EndIf
            (cAlias)->(DbSkip())
        End
        (cAlias)->(DbCloseArea())
    EndIf

    // 2.5 Movimentos anteriores ao periodo para ajustar saldo SB9 ate dDtDe.
    //     Ex.: SB9 em 01/01 com saldo 3 e periodo iniciando apos baixa de 2 => abertura 1.
    IncProc("Buscando movimentos antes do periodo...")
    cAlias := GetNextAlias()
    cQuery := " SELECT D3.D3_COD COD, D3.D3_LOCAL LOC, 'S' TP, "
    cQuery += "   D3.D3_QUANT QTD, D3.D3_EMISSAO DT, "
    cQuery += "   CASE WHEN ISNULL(D3.D3_QUANT,0) > 0 THEN ISNULL(D3.D3_CUSTO1,0) / D3.D3_QUANT ELSE 0 END VLR, "
    cQuery += "   B1.B1_DESC DSC, D3.D3_DOC DOC "
    cQuery += " FROM " + RetSqlName("SD3") + " D3 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.B1_COD=D3.D3_COD AND B1.D_E_L_E_T_=' ' "
    cQuery += " WHERE D3.D3_FILIAL='" + xFilial("SD3") + "' "
    cQuery += " AND D3.D3_EMISSAO < '" + DtoS(dDtDe) + "' "
    cQuery += " AND D3.D3_TM > '499' "
    cQuery += " AND D3.D3_ESTORNO=' ' AND D3.D_E_L_E_T_=' ' " + cFiltB1
    If !Empty(cArmazem)
        cQuery += " AND D3.D3_LOCAL='" + cArmazem + "' "
    EndIf
    cQuery += " UNION ALL "
    cQuery += " SELECT D3.D3_COD COD, D3.D3_LOCAL LOC, 'E' TP, "
    cQuery += "   D3.D3_QUANT QTD, D3.D3_EMISSAO DT, "
    cQuery += "   CASE WHEN ISNULL(D3.D3_QUANT,0) > 0 THEN ISNULL(D3.D3_CUSTO1,0) / D3.D3_QUANT ELSE 0 END VLR, "
    cQuery += "   B1.B1_DESC DSC, D3.D3_DOC DOC "
    cQuery += " FROM " + RetSqlName("SD3") + " D3 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.B1_COD=D3.D3_COD AND B1.D_E_L_E_T_=' ' "
    cQuery += " WHERE D3.D3_FILIAL='" + xFilial("SD3") + "' "
    cQuery += " AND D3.D3_EMISSAO < '" + DtoS(dDtDe) + "' "
    cQuery += " AND D3.D3_TM <= '499' "
    cQuery += " AND D3.D3_ESTORNO=' ' AND D3.D_E_L_E_T_=' ' " + cFiltB1
    If !Empty(cArmazem)
        cQuery += " AND D3.D3_LOCAL='" + cArmazem + "' "
    EndIf
    cQuery += " UNION ALL "
    cQuery += " SELECT D1.D1_COD COD, D1.D1_LOCAL LOC, 'E' TP, "
    cQuery += "   D1.D1_QUANT QTD, D1.D1_DTDIGIT DT, ISNULL(D1.D1_VUNIT,0) VLR, B1.B1_DESC DSC, D1.D1_DOC DOC "
    cQuery += " FROM " + RetSqlName("SD1") + " D1 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.B1_COD=D1.D1_COD AND B1.D_E_L_E_T_=' ' "
    If lHasF4Est
        cQuery += " INNER JOIN " + RetSqlName("SF4") + " F4 ON F4.F4_FILIAL='" + xFilial("SF4") + "' AND F4.F4_CODIGO=D1.D1_TES AND F4.F4_ESTOQUE='S' AND F4.D_E_L_E_T_=' ' "
    EndIf
    cQuery += " WHERE D1.D1_FILIAL='" + xFilial("SD1") + "' "
    cQuery += " AND D1.D1_DTDIGIT < '" + DtoS(dDtDe) + "' "
    If !lHasF4Est
        cQuery += " AND LEFT(D1.D1_CF,1) IN ('1','2','3') "
    EndIf
    cQuery += " AND D1.D_E_L_E_T_=' ' " + cFiltB1
    If !Empty(cArmazem)
        cQuery += " AND D1.D1_LOCAL='" + cArmazem + "' "
    EndIf
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    (cAlias)->(DbGoTop())
    While !(cAlias)->(EoF())
        aAdd(aMovAnt, { ;
            AllTrim((cAlias)->COD), ;
            AllTrim((cAlias)->LOC), ;
            AllTrim((cAlias)->TP), ;
            (cAlias)->QTD, ;
            AllTrim((cAlias)->DT), ;
            (cAlias)->VLR, ;
            AllTrim((cAlias)->DSC), ;
            AllTrim((cAlias)->DOC) })
        (cAlias)->(DbSkip())
    End
    (cAlias)->(DbCloseArea())
    ASort(aMovAnt, , , {|a, b| a[5] < b[5]})

    // 2.1 Proximo saldo futuro SB9.
    //     Se nao existe SB9 anterior, alguns itens do Kardex nativo sao
    //     reconstruidos de tras para frente a partir do primeiro SB9 futuro.
    If lB9Data .And. !Empty(cB9QFim) .And. !Empty(cB9VFim)
        cAlias := GetNextAlias()
        cQuery := " SELECT B9.B9_COD, B9.B9_LOCAL, B9.B9_DATA, "
        cQuery += "   ISNULL(B9." + cB9QFim + ", 0) AS QFIM, "
        cQuery += "   ISNULL(B9." + cB9VFim + ", 0) AS VFIM "
        cQuery += " FROM " + RetSqlName("SB9") + " B9 "
        cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 "
        cQuery += "   ON B1.B1_COD = B9.B9_COD "
        cQuery += "   AND B1.B1_FILIAL = '" + xFilial("SB1") + "' "
        cQuery += "   AND B1.D_E_L_E_T_ = ' ' "
        cQuery += " WHERE B9.D_E_L_E_T_ = ' ' "
        cQuery += "   AND B9.B9_FILIAL = '" + xFilial("SB9") + "' "
        cQuery += "   AND B9.B9_DATA > '" + DtoS(dDtAte) + "' "
        cQuery += cFiltB1
        If !Empty(cArmazem)
            cQuery += "   AND B9.B9_LOCAL = '" + cArmazem + "' "
        EndIf
        cQuery += " ORDER BY B9.B9_COD, B9.B9_LOCAL, B9.B9_DATA ASC "
        cQuery := ChangeQuery(cQuery)

        DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
        TCSetField(cAlias, "QFIM", "N", 16, 4)
        TCSetField(cAlias, "VFIM", "N", 16, 2)
        (cAlias)->(DbGoTop())
        While !(cAlias)->(EoF())
            cProd  := AllTrim((cAlias)->B9_COD)
            cLocal := AllTrim((cAlias)->B9_LOCAL)
            nPos   := AScan(aSB9Fut, {|x| x[1] == cProd .And. x[2] == cLocal})
            If nPos == 0
                aAdd(aSB9Fut, { ;
                    cProd, ;
                    cLocal, ;
                    AllTrim((cAlias)->B9_DATA), ;
                    (cAlias)->QFIM, ;
                    (cAlias)->VFIM })
            EndIf
            (cAlias)->(DbSkip())
        End
        (cAlias)->(DbCloseArea())
    EndIf

    // Se SB9 nao tem estrutura reconhecida, os produtos com movimento no periodo
    // serao incluidos no passo 4 com saldo inicial zero

    // 3. Movimentos do periodo selecionado
    //    SD3 contem saidas (TM>499) e entradas internas (TM<=499).
    //    SD1 contem as entradas por NF de compra.
    //    JOIN SF4010 F4_ESTOQUE='S' no SD1 exclui TES que nao atualizam estoque
    //    (ex: TES 125 F4_ESTOQUE='N' — bonificacao/transferencia sem impacto no estoque).
    IncProc("Buscando movimentos do periodo (SD3+SD1)...")
    cAlias := GetNextAlias()
    // SD3: somente saidas (D3_TM > '499') — requisicoes de almoxarifado.
    // Mantem o movimento bruto do periodo para bater com o Kardex Diario nativo.
    // Duplicidades futuras nao podem alterar os totais exibidos do periodo.
    cQuery := " SELECT D3.D3_COD COD, D3.D3_LOCAL LOC, 'S' TP, "
    cQuery += "   D3.D3_QUANT QTD, D3.D3_EMISSAO DT, "
    cQuery += "   CASE WHEN ISNULL(D3.D3_QUANT,0) > 0 THEN ISNULL(D3.D3_CUSTO1,0) / D3.D3_QUANT ELSE 0 END VLR, "
    cQuery += "   B1.B1_DESC DSC, D3.D3_DOC DOC "
    cQuery += " FROM " + RetSqlName("SD3") + " D3 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.B1_COD=D3.D3_COD AND B1.D_E_L_E_T_=' ' "
    cQuery += " WHERE D3.D3_FILIAL='" + xFilial("SD3") + "' "
    cQuery += " AND D3.D3_EMISSAO >= '" + DtoS(dDtDe) + "' "
    cQuery += " AND D3.D3_EMISSAO <= '" + DtoS(dDtAte) + "' "
    cQuery += " AND D3.D3_TM > '499' "
    cQuery += " AND D3.D3_ESTORNO=' ' AND D3.D_E_L_E_T_=' ' " + cFiltB1
    If !Empty(cArmazem)
        cQuery += " AND D3.D3_LOCAL='" + cArmazem + "' "
    EndIf
    cQuery += " UNION ALL "
    cQuery += " SELECT D3.D3_COD COD, D3.D3_LOCAL LOC, 'E' TP, "
    cQuery += "   D3.D3_QUANT QTD, D3.D3_EMISSAO DT, "
    cQuery += "   CASE WHEN ISNULL(D3.D3_QUANT,0) > 0 THEN ISNULL(D3.D3_CUSTO1,0) / D3.D3_QUANT ELSE 0 END VLR, "
    cQuery += "   B1.B1_DESC DSC, D3.D3_DOC DOC "
    cQuery += " FROM " + RetSqlName("SD3") + " D3 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.B1_COD=D3.D3_COD AND B1.D_E_L_E_T_=' ' "
    cQuery += " WHERE D3.D3_FILIAL='" + xFilial("SD3") + "' "
    cQuery += " AND D3.D3_EMISSAO >= '" + DtoS(dDtDe) + "' "
    cQuery += " AND D3.D3_EMISSAO <= '" + DtoS(dDtAte) + "' "
    cQuery += " AND D3.D3_TM <= '499' "
    cQuery += " AND D3.D3_ESTORNO=' ' AND D3.D_E_L_E_T_=' ' " + cFiltB1
    If !Empty(cArmazem)
        cQuery += " AND D3.D3_LOCAL='" + cArmazem + "' "
    EndIf
    // SD1: entradas via NF, filtrando TES com F4_ESTOQUE='S' (ou CFOP como fallback)
    cQuery += " UNION ALL "
    cQuery += " SELECT D1.D1_COD COD, D1.D1_LOCAL LOC, 'E' TP, "
    cQuery += "   D1.D1_QUANT QTD, D1.D1_DTDIGIT DT, ISNULL(D1.D1_VUNIT,0) VLR, B1.B1_DESC DSC, D1.D1_DOC DOC "
    cQuery += " FROM " + RetSqlName("SD1") + " D1 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.B1_COD=D1.D1_COD AND B1.D_E_L_E_T_=' ' "
    If lHasF4Est
        cQuery += " INNER JOIN " + RetSqlName("SF4") + " F4 ON F4.F4_FILIAL='" + xFilial("SF4") + "' AND F4.F4_CODIGO=D1.D1_TES AND F4.F4_ESTOQUE='S' AND F4.D_E_L_E_T_=' ' "
    EndIf
    cQuery += " WHERE D1.D1_FILIAL='" + xFilial("SD1") + "' "
    cQuery += " AND D1.D1_DTDIGIT >= '" + DtoS(dDtDe) + "' "
    cQuery += " AND D1.D1_DTDIGIT <= '" + DtoS(dDtAte) + "' "
    If !lHasF4Est
        cQuery += " AND LEFT(D1.D1_CF,1) IN ('1','2','3') "
    EndIf
    cQuery += " AND D1.D_E_L_E_T_=' ' " + cFiltB1
    If !Empty(cArmazem)
        cQuery += " AND D1.D1_LOCAL='" + cArmazem + "' "
    EndIf
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    (cAlias)->(DbGoTop())
    While !(cAlias)->(EoF())
        aAdd(aMovs, { ;
            AllTrim((cAlias)->COD), ;   // [1] Produto
            AllTrim((cAlias)->LOC), ;   // [2] Armazem
            AllTrim((cAlias)->TP),  ;   // [3] Tipo E/S
            (cAlias)->QTD,          ;   // [4] Quantidade
            AllTrim((cAlias)->DT),  ;   // [5] Data YYYYMMDD
            (cAlias)->VLR,          ;   // [6] Custo unitario (entradas)
            AllTrim((cAlias)->DSC), ;   // [7] Descricao do produto
            AllTrim((cAlias)->DOC) })   // [8] Documento
        (cAlias)->(DbSkip())
    End
    (cAlias)->(DbCloseArea())

    // 3.1 Movimentos posteriores ao periodo.
    //     Usados apenas para reconstruir saldo retroativo por SB2/SB9 futuro.
    //     Nao entram nos totais exibidos do periodo selecionado.
    IncProc("Buscando movimentos futuros (SD3+SD1)...")
    cAlias := GetNextAlias()
    cQuery := " SELECT D3.D3_COD COD, D3.D3_LOCAL LOC, 'S' TP, "
    cQuery += "   D3.D3_QUANT QTD, D3.D3_EMISSAO DT, "
    cQuery += "   CASE WHEN ISNULL(D3.D3_QUANT,0) > 0 THEN ISNULL(D3.D3_CUSTO1,0) / D3.D3_QUANT ELSE 0 END VLR, "
    cQuery += "   B1.B1_DESC DSC, D3.D3_DOC DOC "
    cQuery += " FROM " + RetSqlName("SD3") + " D3 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.B1_COD=D3.D3_COD AND B1.D_E_L_E_T_=' ' "
    cQuery += " WHERE D3.D3_FILIAL='" + xFilial("SD3") + "' "
    cQuery += " AND D3.D3_EMISSAO > '" + DtoS(dDtAte) + "' "
    cQuery += " AND D3.D3_TM > '499' "
    cQuery += " AND D3.D3_ESTORNO=' ' AND D3.D_E_L_E_T_=' ' " + cFiltB1
    If !Empty(cArmazem)
        cQuery += " AND D3.D3_LOCAL='" + cArmazem + "' "
    EndIf
    cQuery += " UNION ALL "
    cQuery += " SELECT D3.D3_COD COD, D3.D3_LOCAL LOC, 'E' TP, "
    cQuery += "   D3.D3_QUANT QTD, D3.D3_EMISSAO DT, "
    cQuery += "   CASE WHEN ISNULL(D3.D3_QUANT,0) > 0 THEN ISNULL(D3.D3_CUSTO1,0) / D3.D3_QUANT ELSE 0 END VLR, "
    cQuery += "   B1.B1_DESC DSC, D3.D3_DOC DOC "
    cQuery += " FROM " + RetSqlName("SD3") + " D3 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.B1_COD=D3.D3_COD AND B1.D_E_L_E_T_=' ' "
    cQuery += " WHERE D3.D3_FILIAL='" + xFilial("SD3") + "' "
    cQuery += " AND D3.D3_EMISSAO > '" + DtoS(dDtAte) + "' "
    cQuery += " AND D3.D3_TM <= '499' "
    cQuery += " AND D3.D3_ESTORNO=' ' AND D3.D_E_L_E_T_=' ' " + cFiltB1
    If !Empty(cArmazem)
        cQuery += " AND D3.D3_LOCAL='" + cArmazem + "' "
    EndIf
    cQuery += " UNION ALL "
    cQuery += " SELECT D1.D1_COD COD, D1.D1_LOCAL LOC, 'E' TP, "
    cQuery += "   D1.D1_QUANT QTD, D1.D1_DTDIGIT DT, ISNULL(D1.D1_VUNIT,0) VLR, B1.B1_DESC DSC, D1.D1_DOC DOC "
    cQuery += " FROM " + RetSqlName("SD1") + " D1 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.B1_COD=D1.D1_COD AND B1.D_E_L_E_T_=' ' "
    If lHasF4Est
        cQuery += " INNER JOIN " + RetSqlName("SF4") + " F4 ON F4.F4_FILIAL='" + xFilial("SF4") + "' AND F4.F4_CODIGO=D1.D1_TES AND F4.F4_ESTOQUE='S' AND F4.D_E_L_E_T_=' ' "
    EndIf
    cQuery += " WHERE D1.D1_FILIAL='" + xFilial("SD1") + "' "
    cQuery += " AND D1.D1_DTDIGIT > '" + DtoS(dDtAte) + "' "
    If !lHasF4Est
        cQuery += " AND LEFT(D1.D1_CF,1) IN ('1','2','3') "
    EndIf
    cQuery += " AND D1.D_E_L_E_T_=' ' " + cFiltB1
    If !Empty(cArmazem)
        cQuery += " AND D1.D1_LOCAL='" + cArmazem + "' "
    EndIf
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    (cAlias)->(DbGoTop())
    While !(cAlias)->(EoF())
        aAdd(aMovs, { ;
            AllTrim((cAlias)->COD), ;
            AllTrim((cAlias)->LOC), ;
            AllTrim((cAlias)->TP), ;
            (cAlias)->QTD, ;
            AllTrim((cAlias)->DT), ;
            (cAlias)->VLR, ;
            AllTrim((cAlias)->DSC), ;
            AllTrim((cAlias)->DOC) })
        (cAlias)->(DbSkip())
    End
    (cAlias)->(DbCloseArea())

    // 3.5 Ultimo custo de entrada por produto ANTES do periodo (fallback para CM de abertura)
    //     Usa SD1 com JOIN SF4 F4_ESTOQUE='S' — mesmo criterio do Step 3.
    //     Garante que mesmo sem SB9 e sem B2_CM1 o saldo inicial tenha valor.
    IncProc("Buscando ultimo custo de entrada anterior ao periodo...")
    cAlias  := GetNextAlias()
    cQuery  := " SELECT D1.D1_COD COD, D1.D1_LOCAL LOC, AVG(ISNULL(D1.D1_VUNIT,0)) AS CUST, MAX(MX.MAXDT) AS DT "
    cQuery  += " FROM " + RetSqlName("SD1") + " D1 "
    cQuery  += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_COD=D1.D1_COD AND B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.D_E_L_E_T_=' ' "
    If lHasF4Est
        cQuery += " INNER JOIN " + RetSqlName("SF4") + " F4 ON F4.F4_FILIAL='" + xFilial("SF4") + "' AND F4.F4_CODIGO=D1.D1_TES AND F4.F4_ESTOQUE='S' AND F4.D_E_L_E_T_=' ' "
    EndIf
    cQuery  += " INNER JOIN ( "
    cQuery  += "   SELECT D1X.D1_FILIAL, D1X.D1_COD, D1X.D1_LOCAL, MAX(D1X.D1_DTDIGIT) AS MAXDT "
    cQuery  += "   FROM " + RetSqlName("SD1") + " D1X "
    cQuery  += "   INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_COD=D1X.D1_COD AND B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.D_E_L_E_T_=' ' "
    If lHasF4Est
        cQuery += "   INNER JOIN " + RetSqlName("SF4") + " F4 ON F4.F4_FILIAL='" + xFilial("SF4") + "' AND F4.F4_CODIGO=D1X.D1_TES AND F4.F4_ESTOQUE='S' AND F4.D_E_L_E_T_=' ' "
    EndIf
    cQuery  += "   WHERE D1X.D1_FILIAL='" + xFilial("SD1") + "' "
    cQuery  += "   AND D1X.D1_DTDIGIT<'" + DtoS(dDtDe) + "' "
    If !lHasF4Est
        cQuery += "   AND LEFT(D1X.D1_CF,1) IN ('1','2','3') "
    EndIf
    cQuery  += "   AND D1X.D_E_L_E_T_=' ' AND D1X.D1_VUNIT>0 " + cFiltB1
    If !Empty(cArmazem)
        cQuery += "   AND D1X.D1_LOCAL='" + cArmazem + "' "
    EndIf
    cQuery  += "   GROUP BY D1X.D1_FILIAL, D1X.D1_COD, D1X.D1_LOCAL "
    cQuery  += " ) MX ON MX.D1_FILIAL=D1.D1_FILIAL AND MX.D1_COD=D1.D1_COD AND MX.D1_LOCAL=D1.D1_LOCAL AND MX.MAXDT=D1.D1_DTDIGIT "
    cQuery  += " WHERE D1.D1_FILIAL='" + xFilial("SD1") + "' "
    cQuery  += " AND D1.D1_DTDIGIT<'" + DtoS(dDtDe) + "' "
    If !lHasF4Est
        cQuery += " AND LEFT(D1.D1_CF,1) IN ('1','2','3') "
    EndIf
    cQuery  += " AND D1.D_E_L_E_T_=' ' AND D1.D1_VUNIT>0 " + cFiltB1
    If !Empty(cArmazem)
        cQuery += " AND D1.D1_LOCAL='" + cArmazem + "' "
    EndIf
    cQuery  += " GROUP BY D1.D1_COD, D1.D1_LOCAL "
    cQuery  := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    TCSetField(cAlias, "CUST", "N", 16, 4)
    (cAlias)->(DbGoTop())
    While !(cAlias)->(EoF())
        aAdd(aLastCust, { ;
            AllTrim((cAlias)->COD), ;   // [1] Produto
            AllTrim((cAlias)->LOC), ;   // [2] Armazem
            (cAlias)->CUST, ;           // [3] Ultimo custo unitario de entrada
            AllTrim((cAlias)->DT) })    // [4] Data da ultima entrada
        (cAlias)->(DbSkip())
    End
    (cAlias)->(DbCloseArea())

    // Complementa o ultimo custo com entradas internas do SD3 antes do periodo.
    cAlias := GetNextAlias()
    cQuery := " SELECT D3.D3_COD COD, D3.D3_LOCAL LOC, "
    cQuery += "   AVG(CASE WHEN ISNULL(D3.D3_QUANT,0) > 0 THEN ISNULL(D3.D3_CUSTO1,0) / D3.D3_QUANT ELSE 0 END) AS CUST, "
    cQuery += "   MAX(MX.MAXDT) AS DT "
    cQuery += " FROM " + RetSqlName("SD3") + " D3 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_COD=D3.D3_COD AND B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.D_E_L_E_T_=' ' "
    cQuery += " INNER JOIN ( "
    cQuery += "   SELECT D3X.D3_FILIAL, D3X.D3_COD, D3X.D3_LOCAL, MAX(D3X.D3_EMISSAO) AS MAXDT "
    cQuery += "   FROM " + RetSqlName("SD3") + " D3X "
    cQuery += "   INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_COD=D3X.D3_COD AND B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.D_E_L_E_T_=' ' "
    cQuery += "   WHERE D3X.D3_FILIAL='" + xFilial("SD3") + "' "
    cQuery += "   AND D3X.D3_EMISSAO<'" + DtoS(dDtDe) + "' "
    cQuery += "   AND D3X.D3_TM <= '499' "
    cQuery += "   AND D3X.D3_ESTORNO=' ' AND D3X.D_E_L_E_T_=' ' "
    cQuery += "   AND ISNULL(D3X.D3_CUSTO1,0) > 0 " + cFiltB1
    If !Empty(cArmazem)
        cQuery += "   AND D3X.D3_LOCAL='" + cArmazem + "' "
    EndIf
    cQuery += "   GROUP BY D3X.D3_FILIAL, D3X.D3_COD, D3X.D3_LOCAL "
    cQuery += " ) MX ON MX.D3_FILIAL=D3.D3_FILIAL AND MX.D3_COD=D3.D3_COD AND MX.D3_LOCAL=D3.D3_LOCAL AND MX.MAXDT=D3.D3_EMISSAO "
    cQuery += " WHERE D3.D3_FILIAL='" + xFilial("SD3") + "' "
    cQuery += " AND D3.D3_EMISSAO<'" + DtoS(dDtDe) + "' "
    cQuery += " AND D3.D3_TM <= '499' "
    cQuery += " AND D3.D3_ESTORNO=' ' AND D3.D_E_L_E_T_=' ' "
    cQuery += " AND ISNULL(D3.D3_CUSTO1,0) > 0 " + cFiltB1
    If !Empty(cArmazem)
        cQuery += " AND D3.D3_LOCAL='" + cArmazem + "' "
    EndIf
    cQuery += " GROUP BY D3.D3_COD, D3.D3_LOCAL "
    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    TCSetField(cAlias, "CUST", "N", 16, 4)
    (cAlias)->(DbGoTop())
    While !(cAlias)->(EoF())
        cProd  := AllTrim((cAlias)->COD)
        cLocal := AllTrim((cAlias)->LOC)
        nPosLC := AScan(aLastCust, {|x| x[1] == cProd .And. x[2] == cLocal})
        If nPosLC == 0
            aAdd(aLastCust, { cProd, cLocal, (cAlias)->CUST, AllTrim((cAlias)->DT) })
        ElseIf Len(aLastCust[nPosLC]) < 4 .Or. AllTrim((cAlias)->DT) >= aLastCust[nPosLC][4]
            aLastCust[nPosLC][3] := (cAlias)->CUST
            aLastCust[nPosLC][4] := AllTrim((cAlias)->DT)
        EndIf
        (cAlias)->(DbSkip())
    End
    (cAlias)->(DbCloseArea())

    // 4. Garante que TODOS os produtos do SB2 e dos movimentos estejam em aBalances
    //    (mesmo sem SB9). Para os que entrarem aqui, o saldo inicial sera calculado
    //    retroativamente pelo SB2 no passo 5.
    For nI := 1 To Len(aSB2)
        cProd  := aSB2[nI][1]
        cLocal := aSB2[nI][2]
        nPos   := AScan(aBalances, {|x| x[1] == cProd .And. x[3] == cLocal})
        If nPos == 0
            aAdd(aBalances, {cProd, "", cLocal, 0, 0})
        EndIf
    Next nI
    For nI := 1 To Len(aMovs)
        cProd  := aMovs[nI][1]
        cLocal := aMovs[nI][2]
        nPos   := AScan(aBalances, {|x| x[1] == cProd .And. x[3] == cLocal})
        If nPos == 0
            aAdd(aBalances, {cProd, aMovs[nI][7], cLocal, 0, 0})
        ElseIf Empty(aBalances[nPos][2])
            aBalances[nPos][2] := aMovs[nI][7]
        EndIf
    Next nI

    // 5. Kardex progressivo por produto:
    //    - Filtra somente produtos com movimentacao no periodo (dDtDe..dDtAte)
    //    - Separa movimentos dentro e apos o periodo (aMovPosFim para retroativo SB2)
    //    - Ordena movimentos cronologicamente
    //    - Recalcula CM a cada entrada: CM = (VlrTotal + QtdEnt*CustoEnt) / (QtdTotal + QtdEnt)
    //    - Saida usa ultimo CM sem alterar o CM do periodo
    //    - Fallback retroativo: SaldoIni via SB2 quando nao ha SB9
    IncProc("Consolidando dados...")
    For nI := 1 To Len(aBalances)
        cProd        := aBalances[nI][1]
        cDesc        := aBalances[nI][2]
        cLocal       := aBalances[nI][3]
        nSaldoIni    := aBalances[nI][4]   // SB9_QFIM (zero se nao havia SB9)
        nValorIni    := aBalances[nI][5]   // SB9_VFIM
        lSaldoSB9    := (nSaldoIni > 0 .Or. nValorIni > 0)
        nEntPeriodo  := 0
        nSaiPeriodo  := 0
        nEntPosFim   := 0
        nSaiPosFim   := 0
        nVlrEntFut   := 0
        nVlrSaiFut   := 0
        nVlrSB2Fim   := 0
        nValorEnt    := 0
        nValorSai    := 0
        aMovProd     := {}
        aMovPosFim   := {}
        aFutKeys     := {}
        nSaldoRetro  := 0
        nSaldoHistBase := 0
        nSaldoAtualCalc := 0
        nSaldoMin    := 0
        nSaldoCalc   := 0
        nCM_abertura := 0
        lSaldoHistOk := .F.
        lEntradaAntes := .F.
        lTemSaidaPer := .F.
        nPosSB9Fut   := 0
        cDtBaseFut   := ""
        nSaldoFimBase:= 0
        nEntSB9Fut   := 0
        nSaiSB9Fut   := 0
        nUltCustoEnt := 0
        nCustoUltEnt := 0
        cDtB9Base    := ""
        If Len(aBalances[nI]) >= 6
            cDtB9Base := aBalances[nI][6]
        EndIf
        nQtdPreKdx   := 0
        nVlrPreKdx   := 0
        nCMPreKdx    := 0

        // Separa movimentos: dentro do periodo x apos dDtAte
        For nJ := 1 To Len(aMovs)
            If aMovs[nJ][1] == cProd .And. aMovs[nJ][2] == cLocal
                If StoD(aMovs[nJ][5]) <= dDtAte
                    aAdd(aMovProd, aMovs[nJ])
                    If aMovs[nJ][3] == "S"
                        lTemSaidaPer := .T.
                    EndIf
                Else
                    aAdd(aMovPosFim, aMovs[nJ])
                EndIf
            EndIf
        Next nJ

        // Os totalizadores financeiros consideram todo o estoque da conta/armazem.
        // A exibicao no browse fica restrita aos produtos com baixa/saida no periodo.

        // Ordena antes dos acumulados: em mesma data, o Kardex mostra entradas antes das saidas.
        ASort(aMovProd, , , {|a, b| a[5] + IIf(a[3] == "E", "0", "1") < b[5] + IIf(b[3] == "E", "0", "1")})

        // Quando nao existe SB9 para o mes, o retroativo por SB2 pode ser contaminado
        // por movimentos futuros duplicados. Usa o menor saldo acumulado do periodo
        // como saldo inicial minimo necessario para reproduzir o Kardex Diario.
        For nJ := 1 To Len(aMovProd)
            If aMovProd[nJ][3] == "E"
                nSaldoCalc += aMovProd[nJ][4]
            Else
                nSaldoCalc -= aMovProd[nJ][4]
            EndIf
            If nSaldoCalc < nSaldoMin
                nSaldoMin := nSaldoCalc
            EndIf
        Next nJ
        nSaldoMin := Abs(nSaldoMin)

        // Acumula totais do periodo (para nValorEnt e retroativo SB2)
        For nJ := 1 To Len(aMovProd)
            If aMovProd[nJ][3] == "E"
                nEntPeriodo += aMovProd[nJ][4]
                nValorEnt   += aMovProd[nJ][4] * aMovProd[nJ][6]
            Else
                nSaiPeriodo += aMovProd[nJ][4]
            EndIf
        Next nJ

        nPosSB9Fut := AScan(aSB9Fut, {|x| x[1] == cProd .And. x[2] == cLocal})
        If nPosSB9Fut > 0
            cDtBaseFut := aSB9Fut[nPosSB9Fut][3]
        EndIf

        nPosLC := AScan(aLastCust, {|x| x[1] == cProd .And. x[2] == cLocal})
        If nPosLC > 0
            nUltCustoEnt := aLastCust[nPosLC][3]
        EndIf

        // Se o saldo veio de SB9 anterior ao periodo, avanca esse saldo ate dDtDe
        // aplicando entradas/saidas entre a data do SB9 e o inicio do periodo.
        If lSaldoSB9 .And. !Empty(cDtB9Base) .And. cDtB9Base < DtoS(dDtDe)
            nQtdPreKdx := nSaldoIni
            nVlrPreKdx := nValorIni
            nCMPreKdx  := IIf(nQtdPreKdx > 0 .And. nVlrPreKdx <> 0, nVlrPreKdx / nQtdPreKdx, nUltCustoEnt)

            For nJ := 1 To Len(aMovAnt)
                If aMovAnt[nJ][1] == cProd .And. aMovAnt[nJ][2] == cLocal .And. ;
                   aMovAnt[nJ][5] < DtoS(dDtDe) .And. ;
                   IIf(lB9IsIni, aMovAnt[nJ][5] >= cDtB9Base, aMovAnt[nJ][5] > cDtB9Base)

                    If aMovAnt[nJ][3] == "E"
                        nVlrPreKdx += aMovAnt[nJ][4] * aMovAnt[nJ][6]
                        nQtdPreKdx += aMovAnt[nJ][4]
                        nCMPreKdx  := IIf(nQtdPreKdx > 0 .And. nVlrPreKdx <> 0, nVlrPreKdx / nQtdPreKdx, nCMPreKdx)
                    Else
                        nVlrPreKdx -= aMovAnt[nJ][4] * nCMPreKdx
                        nQtdPreKdx -= aMovAnt[nJ][4]
                    EndIf
                EndIf
            Next nJ

            nSaldoIni := nQtdPreKdx
            nValorIni := nVlrPreKdx
        EndIf

        // Acumula totais apos periodo (para retroativo SB2)
        For nJ := 1 To Len(aMovPosFim)
            cMovKey := aMovPosFim[nJ][5] + "|" + aMovPosFim[nJ][3] + "|" + aMovPosFim[nJ][8]
            If AScan(aFutKeys, cMovKey) > 0
                Loop
            EndIf
            aAdd(aFutKeys, cMovKey)

            If aMovPosFim[nJ][3] == "E"
                nEntPosFim += aMovPosFim[nJ][4]
                nVlrEntFut += aMovPosFim[nJ][4] * aMovPosFim[nJ][6]
                If !Empty(cDtBaseFut) .And. aMovPosFim[nJ][5] <= cDtBaseFut
                    nEntSB9Fut += aMovPosFim[nJ][4]
                EndIf
            Else
                nSaiPosFim += aMovPosFim[nJ][4]
                nVlrSaiFut += aMovPosFim[nJ][4] * aMovPosFim[nJ][6]
                If !Empty(cDtBaseFut) .And. aMovPosFim[nJ][5] <= cDtBaseFut
                    nSaiSB9Fut += aMovPosFim[nJ][4]
                EndIf
            EndIf
        Next nJ

        nPosSB2 := AScan(aSB2, {|x| x[1] == cProd .And. x[2] == cLocal})
        If nPosSB2 > 0
            nVlrSB2Fim := aSB2[nPosSB2][4] - nVlrEntFut + nVlrSaiFut
        EndIf

        // Primeiro custo de saida antes de qualquer entrada do periodo: quando nao
        // ha valor de SB9, este e o CM de abertura exibido pelo Kardex nativo.
        For nJ := 1 To Len(aMovProd)
            If aMovProd[nJ][3] == "E"
                lEntradaAntes := .T.
            ElseIf !lEntradaAntes .And. aMovProd[nJ][6] > 0
                nCM_abertura := aMovProd[nJ][6]
                Exit
            EndIf
        Next nJ

        If lSaldoSB9 .And. lB9IsIni .And. !Empty(cDtB9Base) .And. cDtB9Base <= DtoS(dDtDe)
            nPosHist := AScan(aSaldoHist, {|x| x[1] == cProd .And. x[2] == cLocal})
            nPosSB2  := AScan(aSB2, {|x| x[1] == cProd .And. x[2] == cLocal})
            If nPosHist > 0 .And. nPosSB2 > 0
                nSaldoHistBase := aSaldoHist[nPosHist][3]
                nSaldoAtualCalc := nSaldoHistBase + (nEntPeriodo + nEntPosFim) - (nSaiPeriodo + nSaiPosFim)
                lSaldoHistOk := (Abs(Round(nSaldoAtualCalc - aSB2[nPosSB2][3], 4)) <= 0.0001)

                If !lSaldoHistOk
                    nSaldoAtualCalc := nSaldoHistBase + nEntPeriodo - nSaiPeriodo
                    lSaldoHistOk := (nSaldoHistBase >= nSaldoMin .And. ;
                        nSaldoAtualCalc >= 0 .And. ;
                        nSaldoHistBase < nSaldoIni)
                EndIf

                If lSaldoHistOk .And. Abs(Round(nSaldoHistBase - nSaldoIni, 4)) > 0.0001
                    lSaldoSB9 := .F.
                    nValorIni := 0
                EndIf
            EndIf
        EndIf

        // Fallback sem SB9 anterior:
        // 1) usa saldo historico quando ele suporta o movimento do periodo;
        // 2) se o historico geraria saldo negativo, reconstitui por SB2;
        // 3) sem historico, usa SB9 futuro de tras para frente ou SB2.
        If !lSaldoSB9
            nPosHist := AScan(aSaldoHist, {|x| x[1] == cProd .And. x[2] == cLocal})
            nPosSB2  := AScan(aSB2, {|x| x[1] == cProd .And. x[2] == cLocal})
            If nPosHist > 0
                nSaldoHistBase := aSaldoHist[nPosHist][3]
                nSaldoAtualCalc := nSaldoHistBase + nEntPeriodo - nSaiPeriodo
                lSaldoHistOk    := (nSaldoHistBase >= nSaldoMin .And. nSaldoAtualCalc >= 0)

                If lSaldoHistOk
                    nSaldoIni := nSaldoHistBase
                ElseIf nPosSB2 > 0
                    nSaldoRetro := aSB2[nPosSB2][3] - (nEntPeriodo + nEntPosFim) + (nSaiPeriodo + nSaiPosFim)
                    nSaldoIni   := IIf(nSaldoRetro < nSaldoMin, nSaldoMin, nSaldoRetro)
                Else
                    nSaldoIni := nSaldoHistBase
                EndIf
            ElseIf nPosSB9Fut > 0
                // SaldoFim(dDtAte) = SB9 futuro - entradas futuras + saidas futuras
                nSaldoFimBase := aSB9Fut[nPosSB9Fut][4] - nEntSB9Fut + nSaiSB9Fut
                nSaldoIni     := nSaldoFimBase - nEntPeriodo + nSaiPeriodo
                nSaldoIni     := IIf(nSaldoIni < nSaldoMin, nSaldoMin, nSaldoIni)
            Else
                If nPosSB2 > 0
                    // SaldoIni(dDtDe) = SB2_QATU - (ent dDtDe..hoje) + (sai dDtDe..hoje)
                    nSaldoRetro  := aSB2[nPosSB2][3] - (nEntPeriodo + nEntPosFim) + (nSaiPeriodo + nSaiPosFim)
                    nSaldoIni    := IIf(nSaldoRetro < nSaldoMin, nSaldoMin, nSaldoRetro)
                EndIf
            EndIf

            If nCM_abertura <= 0
                nPosSB2 := AScan(aSB2, {|x| x[1] == cProd .And. x[2] == cLocal})
                If nPosSB2 > 0
                    // CM de abertura: prefere B2_CM1; se zero, calcula de B2_VATU1/B2_QATU
                    nCM_abertura := aSB2[nPosSB2][5]
                    If nCM_abertura <= 0 .And. aSB2[nPosSB2][3] > 0
                        nCM_abertura := aSB2[nPosSB2][4] / aSB2[nPosSB2][3]
                    EndIf
                EndIf
            EndIf

            If nCM_abertura > 0
                nValorIni := nSaldoIni * nCM_abertura
            EndIf
        ElseIf nValorIni <= 0  // SB9 tem qtd mas sem valor: complementa com CM disponivel
            If nCM_abertura <= 0
                nPosSB2 := AScan(aSB2, {|x| x[1] == cProd .And. x[2] == cLocal})
                If nPosSB2 > 0
                    nCM_abertura := aSB2[nPosSB2][5]
                    If nCM_abertura <= 0 .And. aSB2[nPosSB2][3] > 0
                        nCM_abertura := aSB2[nPosSB2][4] / aSB2[nPosSB2][3]
                    EndIf
                EndIf
            EndIf
            If nCM_abertura > 0
                nValorIni := nSaldoIni * nCM_abertura
            EndIf
        EndIf

        // Ultimo recurso: ultimo custo de entrada do SD1 antes do periodo (passo 3.5)
        If nValorIni <= 0 .And. nSaldoIni > 0
            If nUltCustoEnt > 0
                nValorIni := nSaldoIni * nUltCustoEnt
            EndIf
        EndIf

        If nCM_abertura <= 0 .And. nUltCustoEnt > 0
            nCM_abertura := nUltCustoEnt
        EndIf

        nCustoUltEnt := nUltCustoEnt

        // Loop Kardex: recalcula CM progressivamente a cada entrada
        nQtdKdx := nSaldoIni
        nVlrKdx := nValorIni
        nCMKdx  := IIf(nQtdKdx > 0, nVlrKdx / nQtdKdx, 0)
        nValorSai := 0

        For nJ := 1 To Len(aMovProd)
            If aMovProd[nJ][3] == "E"   // Entrada: incorpora qtd e valor, recalcula CM
                nVlrKdx += aMovProd[nJ][4] * aMovProd[nJ][6]
                nQtdKdx += aMovProd[nJ][4]
                nCMKdx  := IIf(nQtdKdx > 0, nVlrKdx / nQtdKdx, 0)
                If aMovProd[nJ][6] > 0
                    nCustoUltEnt := aMovProd[nJ][6]
                EndIf
            Else                         // Saida: baixa pelo CM atual, sem alterar CM
                nCustoSai  := IIf(nCMKdx > 0, nCMKdx, IIf(nCustoUltEnt > 0, nCustoUltEnt, aMovProd[nJ][6]))
                nValorSai += aMovProd[nJ][4] * nCustoSai
                nVlrKdx   -= aMovProd[nJ][4] * nCustoSai
                nQtdKdx -= aMovProd[nJ][4]
            EndIf
        Next nJ

        nSaldoFinal := nQtdKdx
        If nCMKdx <= 0 .And. nUltCustoEnt > 0
            nCMKdx := nUltCustoEnt
        EndIf
        nVlrFinal := nVlrKdx
        nCustoUnit  := ZSLD_CMVal(nSaldoFinal, nVlrFinal)
        nVlrFinal   := ZSLD_VFVal(nSaldoFinal, nCustoUnit)
        nValorSai   := nValorIni + nValorEnt - nVlrFinal
        nCustoUnit2 := IIf(nCustoUltEnt > 0, nCustoUltEnt, nCMKdx)

        nVlrInicial  += nValorIni
        nVlrTotal    += nVlrFinal
        nVlrEntradas += nValorEnt
        nVlrSaidas   += nValorSai

        // aDados: [1]Prod [2]Desc [3]Arm [4]SaldoIni [5]EntPer [6]SaiPer [7]SaldoFinal [8]VlrFinal [9]CustoMedio [10]CustoUnitEnt [11]VlrIni [12]VlrEnt [13]VlrSai
        If lTemSaidaPer
            nVlrSaldoSB2 += nVlrSB2Fim
            aAdd(aDados, { cProd, cDesc, cLocal, nSaldoIni, nEntPeriodo, nSaiPeriodo, nSaldoFinal, nVlrFinal, nCustoUnit, nCustoUnit2, nValorIni, nValorEnt, nValorSai })
        EndIf
    Next nI

    nTotItens  := Len(aDados)
    aDadosOrig := aClone(aDados)

    IncProc("Calculando razao dos itens do almoxarifado...")
    aRaz := ZSLD_RazItm()
    nVlrRazAnt   := aRaz[1]
    nVlrRazDeb   := aRaz[2]
    nVlrRazCred  := aRaz[3]
    nVlrRazMov   := aRaz[4]
    nVlrRazFinal := aRaz[5]

    IncProc("Dados carregados!")
Return

Static Function ZSLD_CMVal(nSaldoFinal, nVlrFinal)
    Local nCustoMed := 0

    If nSaldoFinal <> 0 .And. nVlrFinal <> 0
        nCustoMed := Round(nVlrFinal / nSaldoFinal, 2)
    EndIf
Return nCustoMed

Static Function ZSLD_VFVal(nSaldoFinal, nCustoMed)
    Local nVlrFinal := 0

    If nSaldoFinal <> 0 .And. nCustoMed <> 0
        nVlrFinal := Round(nSaldoFinal * nCustoMed, 2)
    EndIf
Return nVlrFinal

Static Function ZSLD_CMLin(aLinha)
    Local nCustoMed := 0

    If Len(aLinha) >= 10
        nCustoMed := ZSLD_CMVal(aLinha[7], aLinha[8])
    EndIf
Return nCustoMed

Static Function ZSLD_RazItm()
    Local aRet      := {0, 0, 0, 0, 0}

    aRet[1] := nVlrInicial
    aRet[2] := nVlrEntradas
    aRet[3] := nVlrSaidas
    aRet[4] := aRet[2] - aRet[3]
    aRet[5] := aRet[1] + aRet[4]
Return aRet

/*-------------------------------------------------------------------*
 | ZSLD_Tela - Tela consolidada de saldo do almoxarifado             |
 | Estrutura copiada do ZMMA01.PRW (panels com Align + FWBrowse):    |
 |   - oPanelTop  (CONTROL_ALIGN_TOP)        : info + filtros        |
 |   - oPanelBot  (CONTROL_ALIGN_BOTTOM)     : totalizadores + botoes|
 |   - oPanelMid  (CONTROL_ALIGN_ALLCLIENT)  : FWBrowse com dados    |
 *-------------------------------------------------------------------*/
Static Function ZSLD_Tela(dDtDe, dDtAte, cConta)
    Local oDlg       := Nil
    Local oPanelTop  := Nil
    Local oPanelMid  := Nil
    Local oPanelBot  := Nil
    Local oBrowse    := Nil
    Local aColunas   := {}
    Local oColumn    := Nil
    Local oFontInd   := Nil
    Local oFontTit   := Nil
    Local oGetFilt   := Nil
    Local cFiltro    := Space(40)
    Local cTitulo    := "Saldo Consolidado Almoxarifado - Conta " + cConta

    oFontTit := TFont():New("Arial",, -13, .T., .F.)
    oFontInd := TFont():New("Arial",, -12, .T., .F.)

    // Dialog grande (estilo ZMMA01) - 750 x 1800 dlu, responsivo via Align
    DEFINE MSDIALOG oDlg TITLE cTitulo FROM 000,000 TO 750,1800 PIXEL

    //==================================================================
    // PAINEL SUPERIOR - Resumo + filtros
    //==================================================================
    oPanelTop := TPanel():New(000, 000, "", oDlg,,,,,, 800, 060, .T., .T.)
    oPanelTop:Align := CONTROL_ALIGN_TOP

    @ 008, 010 SAY {|| cValToChar(nTotItens) + " produtos  |  Periodo: " + DtoC(dDtDe) + ;
        " a " + DtoC(dDtAte) + "  |  Conta: " + cConta} ;
        SIZE 700, 010 OF oPanelTop PIXEL FONT oFontTit COLOR CLR_HBLUE

    @ 028, 010 SAY "Buscar Produto / Descricao:" SIZE 130, 008 OF oPanelTop PIXEL
    @ 026, 145 MSGET oGetFilt VAR cFiltro SIZE 200, 010 OF oPanelTop PIXEL
    @ 025, 350 BUTTON "Filtrar" SIZE 060, 012 OF oPanelTop PIXEL ;
        ACTION ZSLD_Filtrar(cFiltro, oBrowse)
    @ 025, 415 BUTTON "Limpar" SIZE 060, 012 OF oPanelTop PIXEL ;
        ACTION (cFiltro := Space(40), oGetFilt:Refresh(), ZSLD_Filtrar(cFiltro, oBrowse))

    @ 045, 010 SAY "Saldo retroativo no periodo selecionado, com custo medio ponderado e comparativo SB2 na data final." ;
        SIZE 800, 008 OF oPanelTop PIXEL FONT TFont():New(,, 10, .T.) COLOR CLR_BLUE

    //==================================================================
    // PAINEL INFERIOR - Totalizadores + botoes
    //==================================================================
    oPanelBot := TPanel():New(000, 000, "", oDlg,,,,,, 800, 075, .T., .T.)
    oPanelBot:Align := CONTROL_ALIGN_BOTTOM

    @ 005, 010 SAY "Valor Inicial:" SIZE 070, 010 OF oPanelBot PIXEL FONT oFontInd
    @ 005, 080 SAY {|| "R$ " + Transform(nVlrInicial, "@E 999,999,999.99")} ;
        SIZE 130, 010 OF oPanelBot PIXEL FONT oFontInd COLOR RGB(0,128,0)

    @ 005, 220 SAY "Valor Entradas:" SIZE 090, 010 OF oPanelBot PIXEL FONT oFontInd
    @ 005, 300 SAY {|| "R$ " + Transform(nVlrEntradas, "@E 999,999,999.99")} ;
        SIZE 130, 010 OF oPanelBot PIXEL FONT oFontInd COLOR CLR_HBLUE

    @ 005, 470 SAY "Valor SB2 Final:" SIZE 090, 010 OF oPanelBot PIXEL FONT oFontInd
    @ 005, 545 SAY {|| "R$ " + Transform(nVlrSaldoSB2, "@E 999,999,999.99")} ;
        SIZE 130, 010 OF oPanelBot PIXEL FONT oFontInd COLOR RGB(180,90,0)

    @ 020, 010 SAY "Valor Final:" SIZE 070, 010 OF oPanelBot PIXEL FONT oFontInd
    @ 020, 080 SAY {|| "R$ " + Transform(nVlrTotal, "@E 999,999,999.99")} ;
        SIZE 130, 010 OF oPanelBot PIXEL FONT oFontInd COLOR CLR_HBLUE

    @ 020, 220 SAY "Valor Baixas:" SIZE 090, 010 OF oPanelBot PIXEL FONT oFontInd
    @ 020, 300 SAY {|| "R$ " + Transform(nVlrSaidas, "@E 999,999,999.99")} ;
        SIZE 130, 010 OF oPanelBot PIXEL FONT oFontInd COLOR RGB(180,0,0)

    @ 020, 470 SAY "Itens com Baixa:" SIZE 090, 010 OF oPanelBot PIXEL FONT oFontInd
    @ 020, 545 SAY {|| cValToChar(nTotItens) + " produtos"} ;
        SIZE 130, 010 OF oPanelBot PIXEL FONT oFontInd COLOR CLR_BLACK

    @ 038, 010 SAY "Razao Itens (D-C):" SIZE 095, 010 OF oPanelBot PIXEL FONT oFontInd
    @ 038, 105 SAY {|| "R$ " + Transform(nVlrRazMov, "@E 999,999,999.99")} ;
        SIZE 130, 010 OF oPanelBot PIXEL FONT oFontInd COLOR RGB(80,80,160)

    // Botoes a direita
    @ 010, 750 BUTTON "Nova Consulta" SIZE 070, 015 OF oPanelBot PIXEL ;
        ACTION (oDlg:End(), U_ZSLDEST())
    @ 010, 825 BUTTON "Imprimir" SIZE 070, 015 OF oPanelBot PIXEL ;
        ACTION ZSLD_Print(dDtDe, dDtAte, cConta)

    //==================================================================
    // PAINEL CENTRAL - FWBrowse com os dados
    //==================================================================
    oPanelMid := TPanel():New(000, 000, "", oDlg,,,,,, 800, 300, .T., .T.)
    oPanelMid:Align := CONTROL_ALIGN_ALLCLIENT

    // Monta colunas
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aDados[oBrowse:nAt][1]})
    oColumn:SetTitle("Produto")
    oColumn:SetSize(15)
    oColumn:SetAlign(CONTROL_ALIGN_LEFT)
    aAdd(aColunas, oColumn)

    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aDados[oBrowse:nAt][2]})
    oColumn:SetTitle("Descricao")
    oColumn:SetSize(40)
    oColumn:SetAlign(CONTROL_ALIGN_LEFT)
    aAdd(aColunas, oColumn)

    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aDados[oBrowse:nAt][4], "@E 999,999.99")})
    oColumn:SetTitle("Saldo Inicial")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aDados[oBrowse:nAt][5], "@E 999,999.99")})
    oColumn:SetTitle("Total Entrada")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aDados[oBrowse:nAt][6], "@E 999,999.99")})
    oColumn:SetTitle("Total Saida")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aDados[oBrowse:nAt][7], "@E 999,999.99")})
    oColumn:SetTitle("Saldo Final")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aDados[oBrowse:nAt][10], "@E 9,999.99")})
    oColumn:SetTitle("Custo Ultima Entrada")
    oColumn:SetSize(14)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(ZSLD_CMLin(aDados[oBrowse:nAt]), "@E 9,999.99")})
    oColumn:SetTitle("Custo Medio")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aDados[oBrowse:nAt][8], "@E 999,999,999.99")})
    oColumn:SetTitle("Valor Final (R$)")
    oColumn:SetSize(10)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    oBrowse := FWBrowse():New()
    oBrowse:SetOwner(oPanelMid)
    oBrowse:SetDataArray()
    oBrowse:SetArray(aDados)
    oBrowse:SetColumns(aColunas)
    oBrowse:DisableConfig()
    oBrowse:SetDoubleClick({|| ZSLD_DetItem(oBrowse:nAt, dDtDe, dDtAte, cConta)})
    oBrowse:Activate()

    ACTIVATE MSDIALOG oDlg CENTERED
Return

/*-------------------------------------------------------------------*
 | ZSLD_Filtrar - Filtra grid por produto ou descricao               |
 *-------------------------------------------------------------------*/
Static Function ZSLD_Filtrar(cFiltro, oBrowse)
    Local cBusca := AllTrim(Upper(cFiltro))
    Local nI     := 0

    aDados := {}

    If Empty(cBusca)
        aDados := aClone(aDadosOrig)
    Else
        For nI := 1 To Len(aDadosOrig)
            If (cBusca $ Upper(aDadosOrig[nI][1])) .Or. ;
               (cBusca $ Upper(aDadosOrig[nI][2]))
                aAdd(aDados, aDadosOrig[nI])
            EndIf
        Next nI
        If Len(aDados) == 0
            aDados := aClone(aDadosOrig)
            MsgInfo("Nenhum registro encontrado.", "Filtro")
        EndIf
    EndIf

    If ValType(oBrowse) == "O" .And. oBrowse != Nil
        oBrowse:SetArray(aDados)
        oBrowse:GoTop()
        oBrowse:Refresh(.T.)
    EndIf
Return

/*-------------------------------------------------------------------*
 | ZSLD_DetItem - Drill-down de movimentacao do produto selecionado  |
 *-------------------------------------------------------------------*/
Static Function ZSLD_DetItem(nLinha, dDtDe, dDtAte, cConta)
    Local oDlg       := Nil
    Local oListMov   := Nil
    Local oFont      := Nil
    Local oFontTit   := Nil
    Local oFontInd   := Nil
    Local oBtnFechar := Nil
    Local cAlias     := GetNextAlias()
    Local cQuery     := ""
    Local cAliasCol  := GetNextAlias()
    Local cTblSF4    := RetSqlName("SF4")
    Local lHasF4Est  := .F.
    Local cProd      := ""
    Local cDesc      := ""
    Local cLocal     := ""
    Local nSaldoIni  := 0
    Local nSaldoFin  := 0
    Local nValorIni  := 0
    Local nValorFin  := 0
    Local nValorEnt  := 0
    Local nValorSai  := 0
    Local nQtdKdx    := 0
    Local nVlrKdx    := 0
    Local nCMKdx     := 0
    Local nCustoMov  := 0
    Local nVlrMov    := 0
    Local aMovRaw    := {}
    Local aMovView   := {}
    Local nI         := 0
    Local cTipo      := ""
    Local cDtMov     := ""
    Local cFiltB1    := ""

    If nLinha < 1 .Or. nLinha > Len(aDados)
        MsgAlert("Selecione um produto no grid!", "Atencao")
        Return
    EndIf

    cProd     := aDados[nLinha][1]
    cDesc     := aDados[nLinha][2]
    cLocal    := aDados[nLinha][3]
    nSaldoIni := aDados[nLinha][4]
    nSaldoFin := aDados[nLinha][7]
    nValorFin := aDados[nLinha][8]
    nValorIni := aDados[nLinha][11]
    nValorEnt := aDados[nLinha][12]
    nValorSai := aDados[nLinha][13]

    cFiltB1 := " AND B1.B1_XCTAEST = '" + PadR(cConta, TamSX3("B1_XCTAEST")[1]) + "' "

    cQuery := "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS "
    cQuery += "WHERE TABLE_NAME = '" + cTblSF4 + "' AND COLUMN_NAME = 'F4_ESTOQUE'"
    DbUseArea(.T., "TOPCONN", TcGenQry(,, ChangeQuery(cQuery)), cAliasCol, .F., .T.)
    If !(cAliasCol)->(Eof())
        lHasF4Est := .T.
    EndIf
    (cAliasCol)->(DbCloseArea())

    cQuery := " SELECT * FROM ( "
    cQuery += " SELECT D3.D3_EMISSAO DT, 'S' TP, D3.D3_TM TES, ISNULL(D3.D3_CF,'') CFO, "
    cQuery += "   D3.D3_DOC DOC, '' SERIE, D3.D3_DOC IDENT, D3.D3_QUANT QTD, "
    cQuery += "   CASE WHEN ISNULL(D3.D3_QUANT,0) > 0 THEN ISNULL(D3.D3_CUSTO1,0) / D3.D3_QUANT ELSE 0 END VLR "
    cQuery += " FROM " + RetSqlName("SD3") + " D3 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.B1_COD=D3.D3_COD AND B1.D_E_L_E_T_=' ' "
    cQuery += " WHERE D3.D3_FILIAL='" + xFilial("SD3") + "' "
    cQuery += " AND D3.D3_COD='" + cProd + "' "
    cQuery += " AND D3.D3_LOCAL='" + cLocal + "' "
    cQuery += " AND D3.D3_EMISSAO >= '" + DtoS(dDtDe) + "' "
    cQuery += " AND D3.D3_EMISSAO <= '" + DtoS(dDtAte) + "' "
    cQuery += " AND D3.D3_TM > '499' "
    cQuery += " AND D3.D3_ESTORNO=' ' AND D3.D_E_L_E_T_=' ' " + cFiltB1
    cQuery += " UNION ALL "
    cQuery += " SELECT D3.D3_EMISSAO DT, 'E' TP, D3.D3_TM TES, ISNULL(D3.D3_CF,'') CFO, "
    cQuery += "   D3.D3_DOC DOC, '' SERIE, D3.D3_DOC IDENT, D3.D3_QUANT QTD, "
    cQuery += "   CASE WHEN ISNULL(D3.D3_QUANT,0) > 0 THEN ISNULL(D3.D3_CUSTO1,0) / D3.D3_QUANT ELSE 0 END VLR "
    cQuery += " FROM " + RetSqlName("SD3") + " D3 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.B1_COD=D3.D3_COD AND B1.D_E_L_E_T_=' ' "
    cQuery += " WHERE D3.D3_FILIAL='" + xFilial("SD3") + "' "
    cQuery += " AND D3.D3_COD='" + cProd + "' "
    cQuery += " AND D3.D3_LOCAL='" + cLocal + "' "
    cQuery += " AND D3.D3_EMISSAO >= '" + DtoS(dDtDe) + "' "
    cQuery += " AND D3.D3_EMISSAO <= '" + DtoS(dDtAte) + "' "
    cQuery += " AND D3.D3_TM <= '499' "
    cQuery += " AND D3.D3_ESTORNO=' ' AND D3.D_E_L_E_T_=' ' " + cFiltB1
    cQuery += " UNION ALL "
    cQuery += " SELECT D1.D1_DTDIGIT DT, 'E' TP, D1.D1_TES TES, D1.D1_CF CFO, "
    cQuery += "   D1.D1_DOC DOC, D1.D1_SERIE SERIE, D1.D1_DOC IDENT, D1.D1_QUANT QTD, ISNULL(D1.D1_VUNIT,0) VLR "
    cQuery += " FROM " + RetSqlName("SD1") + " D1 "
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL='" + xFilial("SB1") + "' AND B1.B1_COD=D1.D1_COD AND B1.D_E_L_E_T_=' ' "
    If lHasF4Est
        cQuery += " INNER JOIN " + RetSqlName("SF4") + " F4 ON F4.F4_FILIAL='" + xFilial("SF4") + "' AND F4.F4_CODIGO=D1.D1_TES AND F4.F4_ESTOQUE='S' AND F4.D_E_L_E_T_=' ' "
    EndIf
    cQuery += " WHERE D1.D1_FILIAL='" + xFilial("SD1") + "' "
    cQuery += " AND D1.D1_COD='" + cProd + "' "
    cQuery += " AND D1.D1_LOCAL='" + cLocal + "' "
    cQuery += " AND D1.D1_DTDIGIT >= '" + DtoS(dDtDe) + "' "
    cQuery += " AND D1.D1_DTDIGIT <= '" + DtoS(dDtAte) + "' "
    If !lHasF4Est
        cQuery += " AND LEFT(D1.D1_CF,1) IN ('1','2','3') "
    EndIf
    cQuery += " AND D1.D_E_L_E_T_=' ' " + cFiltB1
    cQuery += " ) MOV ORDER BY MOV.DT, CASE WHEN MOV.TP='E' THEN 0 ELSE 1 END, MOV.DOC "
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    TCSetField(cAlias, "QTD", "N", 16, 4)
    TCSetField(cAlias, "VLR", "N", 16, 6)
    (cAlias)->(DbGoTop())
    While !(cAlias)->(EoF())
        aAdd(aMovRaw, { ;
            AllTrim((cAlias)->DT), ;
            AllTrim((cAlias)->TP), ;
            AllTrim((cAlias)->TES), ;
            AllTrim((cAlias)->CFO), ;
            AllTrim((cAlias)->DOC), ;
            AllTrim((cAlias)->SERIE), ;
            AllTrim((cAlias)->IDENT), ;
            (cAlias)->QTD, ;
            (cAlias)->VLR })
        (cAlias)->(DbSkip())
    End
    (cAlias)->(DbCloseArea())

    nQtdKdx := nSaldoIni
    nVlrKdx := nValorIni
    nCMKdx  := ZSLD_CMDet(nQtdKdx, nVlrKdx)

    aAdd(aMovView, { "", "Saldo Inicial", "", "", "", "", "", nQtdKdx, nCMKdx, nVlrKdx })

    For nI := 1 To Len(aMovRaw)
        cDtMov := DtoC(StoD(aMovRaw[nI][1]))
        cTipo  := IIf(aMovRaw[nI][2] == "E", "Entrada", "Saida")

        If aMovRaw[nI][2] == "E"
            nVlrMov := aMovRaw[nI][8] * aMovRaw[nI][9]
            nVlrKdx += nVlrMov
            nQtdKdx += aMovRaw[nI][8]
            nCMKdx  := ZSLD_CMDet(nQtdKdx, nVlrKdx)
            nCustoMov := nCMKdx
        Else
            nCustoMov := IIf(nCMKdx > 0, nCMKdx, aMovRaw[nI][9])
            nVlrMov   := aMovRaw[nI][8] * nCustoMov
            nVlrKdx   -= nVlrMov
            nQtdKdx   -= aMovRaw[nI][8]
        EndIf

        aAdd(aMovView, { cDtMov, cTipo, aMovRaw[nI][3], aMovRaw[nI][4], ;
            aMovRaw[nI][5], aMovRaw[nI][6], aMovRaw[nI][7], ;
            aMovRaw[nI][8], nCustoMov, nVlrMov })
        aAdd(aMovView, { "", "Saldos", "", "", "", "", "", nQtdKdx, ;
            ZSLD_CMDet(nQtdKdx, nVlrKdx), nVlrKdx })
    Next nI

    nSaldoFin := nQtdKdx
    nValorFin := nVlrKdx
    nValorSai := nValorIni + nValorEnt - nValorFin

    oFont    := TFont():New("Arial",, -11, .F., .F.)
    oFontTit := TFont():New("Arial",, -13, .T., .F.)
    oFontInd := TFont():New("Arial",, -12, .T., .F.)

    DEFINE MSDIALOG oDlg TITLE "Consulta ao Kardex em REAL" FROM 000,000 TO 520,1550 PIXEL

    @ 008, 006 SAY "Produto:" SIZE 045, 008 OF oDlg PIXEL FONT oFontInd
    @ 008, 052 SAY cProd + " - " + cDesc SIZE 420, 008 OF oDlg PIXEL FONT oFontInd

    @ 020, 006 SAY "Armazem: " + cLocal + " - ALMOXARIFADO" SIZE 160, 008 OF oDlg PIXEL FONT oFontInd
    @ 020, 180 SAY "Periodo: " + DtoC(dDtDe) + " a " + DtoC(dDtAte) SIZE 160, 008 OF oDlg PIXEL FONT oFontInd
    @ 020, 360 SAY "Conta: " + cConta SIZE 160, 008 OF oDlg PIXEL FONT oFontInd

    @ 034, 006 SAY "Saldos Iniciais:" SIZE 075, 008 OF oDlg PIXEL FONT oFontTit
    @ 034, 090 SAY "Quantidade :" SIZE 065, 008 OF oDlg PIXEL FONT oFontInd
    @ 034, 155 SAY Transform(nSaldoIni, "@E 999,999.9999") SIZE 070, 008 OF oDlg PIXEL FONT oFontInd
    @ 034, 225 SAY "Custo Medio :" SIZE 070, 008 OF oDlg PIXEL FONT oFontInd
    @ 034, 300 SAY Transform(ZSLD_CMDet(nSaldoIni, nValorIni), "@E 999,999.9999") SIZE 070, 008 OF oDlg PIXEL FONT oFontInd
    @ 034, 380 SAY "Custo Total :" SIZE 065, 008 OF oDlg PIXEL FONT oFontInd
    @ 034, 450 SAY Transform(nValorIni, "@E 999,999,999.9999") SIZE 100, 008 OF oDlg PIXEL FONT oFontInd

    @ 047, 006 SAY "Saldos Finais:" SIZE 075, 008 OF oDlg PIXEL FONT oFontTit
    @ 047, 090 SAY "Quantidade :" SIZE 065, 008 OF oDlg PIXEL FONT oFontInd
    @ 047, 155 SAY Transform(nSaldoFin, "@E 999,999.9999") SIZE 070, 008 OF oDlg PIXEL FONT oFontInd
    @ 047, 225 SAY "Custo Medio :" SIZE 070, 008 OF oDlg PIXEL FONT oFontInd
    @ 047, 300 SAY Transform(ZSLD_CMDet(nSaldoFin, nValorFin), "@E 999,999.9999") SIZE 070, 008 OF oDlg PIXEL FONT oFontInd
    @ 047, 380 SAY "Custo Total :" SIZE 065, 008 OF oDlg PIXEL FONT oFontInd
    @ 047, 450 SAY Transform(nValorFin, "@E 999,999,999.9999") SIZE 100, 008 OF oDlg PIXEL FONT oFontInd

    @ 060, 006 SAY "Totais das Entradas:" SIZE 085, 008 OF oDlg PIXEL FONT oFontTit
    @ 060, 090 SAY "Quantidade :" SIZE 065, 008 OF oDlg PIXEL FONT oFontInd
    @ 060, 155 SAY Transform(aDados[nLinha][5], "@E 999,999.9999") SIZE 070, 008 OF oDlg PIXEL FONT oFontInd
    @ 060, 380 SAY "Custo Total :" SIZE 065, 008 OF oDlg PIXEL FONT oFontInd
    @ 060, 450 SAY Transform(nValorEnt, "@E 999,999,999.9999") SIZE 100, 008 OF oDlg PIXEL FONT oFontInd

    @ 073, 006 SAY "Totais das Saidas:" SIZE 085, 008 OF oDlg PIXEL FONT oFontTit
    @ 073, 090 SAY "Quantidade :" SIZE 065, 008 OF oDlg PIXEL FONT oFontInd
    @ 073, 155 SAY Transform(aDados[nLinha][6], "@E 999,999.9999") SIZE 070, 008 OF oDlg PIXEL FONT oFontInd
    @ 073, 380 SAY "Custo Total :" SIZE 065, 008 OF oDlg PIXEL FONT oFontInd
    @ 073, 450 SAY Transform(nValorSai, "@E 999,999,999.9999") SIZE 100, 008 OF oDlg PIXEL FONT oFontInd

    @ 090, 005 LISTBOX oListMov FIELDS HEADER ;
        "Data", "Tipo", "TES", "CFO", "Documento", "Serie", "Ident", ;
        "Quantidade", "Custo Medio", "Custo Total" ;
        COLSIZES 55, 60, 40, 45, 95, 55, 80, 80, 90, 100 ;
        SIZE 760, 145 OF oDlg PIXEL FONT oFont

    oListMov:SetArray(aMovView)
    oListMov:bLine := {|| { ;
        aMovView[oListMov:nAt][1], ;
        aMovView[oListMov:nAt][2], ;
        aMovView[oListMov:nAt][3], ;
        aMovView[oListMov:nAt][4], ;
        aMovView[oListMov:nAt][5], ;
        aMovView[oListMov:nAt][6], ;
        aMovView[oListMov:nAt][7], ;
        Transform(aMovView[oListMov:nAt][8], "@E 999,999.9999"), ;
        Transform(aMovView[oListMov:nAt][9], "@E 999,999.9999"), ;
        Transform(aMovView[oListMov:nAt][10], "@E 999,999,999.9999") }}

    @ 242, 690 BUTTON oBtnFechar PROMPT "Fechar" SIZE 070, 016 OF oDlg PIXEL ;
        ACTION oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED

    FreeObj(oFont)
    FreeObj(oFontTit)
    FreeObj(oFontInd)
Return

Static Function ZSLD_CMDet(nQtd, nValor)
    Local nCM := 0

    If nQtd <> 0 .And. nValor <> 0
        nCM := nValor / nQtd
    EndIf
Return nCM

/*-------------------------------------------------------------------*
 | ZSLD_Excel - Exporta dados para Excel via FWMSExcel               |
 *-------------------------------------------------------------------*/
Static Function ZSLD_Excel(dDtDe, dDtAte, cConta)
    Local oExcel    := Nil
    Local oExcelApp := Nil
    Local cArquivo  := "SaldoMensal_" + cConta + "_" + DtoS(Date()) + "_" + StrTran(Time(), ":", "") + ".xml"
    Local cAbaNome  := "Saldo Mensal"
    Local nI        := 0

    If Len(aDados) == 0
        MsgAlert("Nao ha dados para exportar!", "Atencao")
        Return
    EndIf

    oExcel := FWMSExcel():New()
    oExcel:AddWorkSheet(cAbaNome)
    oExcel:AddTable(cAbaNome, "Saldos")

    oExcel:AddColumn(cAbaNome, "Saldos", "Produto",           1, 1)
    oExcel:AddColumn(cAbaNome, "Saldos", "Descricao",         1, 1)
    oExcel:AddColumn(cAbaNome, "Saldos", "Saldo Inicial",     1, 2)
    oExcel:AddColumn(cAbaNome, "Saldos", "Total Entrada",     1, 2)
    oExcel:AddColumn(cAbaNome, "Saldos", "Total Saida",       1, 2)
    oExcel:AddColumn(cAbaNome, "Saldos", "Saldo Final",       1, 2)
    oExcel:AddColumn(cAbaNome, "Saldos", "Custo Ultima Entrada", 1, 2)
    oExcel:AddColumn(cAbaNome, "Saldos", "Custo Medio",       1, 2)
    oExcel:AddColumn(cAbaNome, "Saldos", "Valor Final (R$)",  1, 2)

    For nI := 1 To Len(aDados)
        oExcel:AddRow(cAbaNome, "Saldos", { ;
            aDados[nI][1], ;
            aDados[nI][2], ;
            aDados[nI][4], ;
            aDados[nI][5], ;
            aDados[nI][6], ;
            aDados[nI][7], ;
            aDados[nI][10], ;
            ZSLD_CMLin(aDados[nI]), ;
            aDados[nI][8] })
    Next nI

    oExcel:Activate()
    oExcel:GetXMLFile(cArquivo)
    MsgInfo("Planilha gerada: " + cArquivo, "Exportacao Excel")

    // Tenta abrir automaticamente
    If File(cArquivo) .And. ApOleClient("MSExcel")
        oExcelApp := MSExcel():New()
        If oExcelApp != Nil
            oExcelApp:WorkBooks:Open(cArquivo)
            oExcelApp:SetVisible(.T.)
        EndIf
    EndIf
Return

/*-------------------------------------------------------------------*
 | ZSLD_Print - Imprime via TReport (PDF/HTML/Impressora)            |
 *-------------------------------------------------------------------*/
Static Function ZSLD_Print(dDtDe, dDtAte, cConta)
    Local oReport  := Nil
    Local oSection := Nil

    If Len(aDados) == 0
        MsgAlert("Nao ha dados para imprimir!", "Atencao")
        Return
    EndIf

    oReport := TReport():New("ZSLDEST", ;       // nome unico (max 10 chars)
        "Saldo Consolidado Almoxarifado", "", ;  // titulo
        {|oReport| ZSLD_PR(oReport, dDtDe, dDtAte, cConta)}, ;  // funcao de impressao
        "Saldo consolidado por produto - Conta " + cConta)

    oReport:SetLandscape(.T.)   // paisagem para caber todas as colunas
    oReport:SetTotalInLine(.F.)

    oSection := TRSection():New(oReport, "Saldos", {})

    TRCell():New(oSection, "PRODUTO",    "", "Produto",        "@!",                15)
    TRCell():New(oSection, "DESCRICAO",  "", "Descricao",      "@!",                35)
    TRCell():New(oSection, "SALDOINI",   "", "Saldo Inicial",  "@E 999,999.9999",   13)
    TRCell():New(oSection, "TOTENT",     "", "Total Entrada",  "@E 999,999.9999",   13)
    TRCell():New(oSection, "TOTSAI",     "", "Total Saida",    "@E 999,999.9999",   13)
    TRCell():New(oSection, "SALDOFIN",   "", "Saldo Final",    "@E 999,999.9999",   13)
    TRCell():New(oSection, "CUSTOUNT",   "", "Custo Ultima Entrada", "@E 9,999.9999", 18)
    TRCell():New(oSection, "CUSTOMED",   "", "Custo Medio",    "@E 9,999.9999",     11)
    TRCell():New(oSection, "VLRFINAL",   "", "Valor Final R$", "@E 999,999,999.99", 15)

    oReport:PrintDialog()
Return

/*-------------------------------------------------------------------*
 | ZSLD_PR - Popula o TReport com os dados (chamado pelo PrintDialog)|
 *-------------------------------------------------------------------*/
Static Function ZSLD_PR(oReport, dDtDe, dDtAte, cConta)
    Local oSection  := oReport:Section(1)
    Local nI        := 0

    oReport:SetMeter(0)
    oSection:Init()

    // Cabecalho do relatorio
    oSection:SetHeaderSection(.T.)
    oReport:PrintText("Conta Contabil: " + cConta + ;
        "   |   Periodo: " + DtoC(dDtDe) + " a " + DtoC(dDtAte) + ;
        "   |   Total Itens: " + cValToChar(nTotItens), 0)
    oReport:SkipLine()

    // Linhas de dados
    For nI := 1 To Len(aDados)
        oSection:Cell("PRODUTO"):SetValue(AllTrim(aDados[nI][1]))
        oSection:Cell("DESCRICAO"):SetValue(AllTrim(aDados[nI][2]))
        oSection:Cell("SALDOINI"):SetValue(aDados[nI][4])
        oSection:Cell("TOTENT"):SetValue(aDados[nI][5])
        oSection:Cell("TOTSAI"):SetValue(aDados[nI][6])
        oSection:Cell("SALDOFIN"):SetValue(aDados[nI][7])
        oSection:Cell("CUSTOUNT"):SetValue(aDados[nI][10])
        oSection:Cell("CUSTOMED"):SetValue(ZSLD_CMLin(aDados[nI]))
        oSection:Cell("VLRFINAL"):SetValue(aDados[nI][8])

        oSection:PrintLine()
        oReport:IncMeter()

    Next nI

    // Totais no rodape
    oReport:SkipLine()
    oReport:PrintText("SALDO INICIAL: R$ " + Transform(nVlrInicial, "@E 999,999,999.99") + ;
        "   |   ENTRADAS: R$ " + Transform(nVlrEntradas, "@E 999,999,999.99") + ;
        "   |   BAIXAS: R$ " + Transform(nVlrSaidas, "@E 999,999,999.99") + ;
        "   |   SALDO FINAL: R$ " + Transform(nVlrTotal, "@E 999,999,999.99"), 0)
    oReport:PrintText("RAZAO ITENS - SALDO ANT.: R$ " + Transform(nVlrRazAnt, "@E 999,999,999.99") + ;
        "   |   ENTRADAS: R$ " + Transform(nVlrRazDeb, "@E 999,999,999.99") + ;
        "   |   BAIXAS: R$ " + Transform(nVlrRazCred, "@E 999,999,999.99") + ;
        "   |   MOV. PERIODO (D-C): R$ " + Transform(nVlrRazMov, "@E 999,999,999.99"), 0)
    oSection:Finish()
Return


