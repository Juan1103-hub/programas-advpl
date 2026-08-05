#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

// Arrays estaticos de dados
Static aAreas     := {}   // Top areas (visivel no grid)
Static aAreasOrig := {}   // Top areas original da consulta
Static aDados     := {}   // Movimentacoes detalhadas
Static aDadosOrig := {}   // Movimentacoes detalhadas original
Static aResumo    := {}   // Resumo agrupado por produto (pivot)
Static aResumoOrig:= {}   // Resumo original para reset de filtro

// Totalizadores estaticos
Static nTotMovs  := 0
Static nTotQuant := 0
Static nVlrTotal := 0
Static nTotEst   := 0    // Qtd itens Estoque
Static nTotNEst  := 0    // Qtd itens Nao Estoque
Static nTotFora  := 0    // Qtd baixas com D3_EMISSAO fora do periodo (SA no periodo)
Static nTotSAs   := 0    // Total SAs distintas geradas dentro do periodo
Static nLTMedio  := 0    // Leadtime medio total (dias)

/*/{Protheus.doc} ZANALBX
Analise de Baixas ao Armazem 02 - Filial 0102
Relatorio gerencial de movimentacao de saida do armazem 02,
com filtro por almoxarifes especificos e periodo selecionado.
@type User Function
@version 12.1.33
@author Copilot
@since 13/04/2026
/*/
User Function ZANALBX()
    Local aArea     := GetArea()
    Local aPar      := {}
    Local aRet      := {}
    Local dDtDe     := CtoD("  /  /    ")
    Local dDtAte    := CtoD("  /  /    ")
    Local aAlmoxOpc := {"Todos", "jose.gustavo", "Fred.caputo", "Ambos"}
    Local cAlmox1   := ""
    Local cAlmox2   := ""
    Local nSelAlmox := 1

    // Inicializa variaveis estaticas
    aAreas     := {}
    aAreasOrig := {}
    aDados     := {}
    aDadosOrig := {}
    aResumo    := {}
    aResumoOrig:= {}
    nTotMovs   := 0
    nTotQuant  := 0
    nVlrTotal  := 0
    nTotEst    := 0
    nTotNEst   := 0
    nTotFora   := 0
    nTotSAs    := 0
    nLTMedio   := 0

    // ParamBox padrao Protheus
    aAdd(aPar, {1, "Data Inicial", dDtDe,  "", "", "", "", 60, .T.})
    aAdd(aPar, {1, "Data Final",   dDtAte, "", "", "", "", 60, .T.})
    aAdd(aPar, {2, "Almoxarife",   1, aAlmoxOpc, 80, "", .F.})

    If !ParamBox(aPar, "Analise de Baixas - Armazem 02", @aRet)
        RestArea(aArea)
        Return
    EndIf

    dDtDe     := aRet[1]
    dDtAte    := aRet[2]

    // ParamBox combo pode retornar indice (N) ou texto (C)
    If ValType(aRet[3]) == "N"
        nSelAlmox := aRet[3]
    ElseIf ValType(aRet[3]) == "C"
        nSelAlmox := aScan(aAlmoxOpc, {|x| AllTrim(Upper(x)) == AllTrim(Upper(aRet[3]))})
        If nSelAlmox == 0
            nSelAlmox := 1
        EndIf
    Else
        nSelAlmox := 1
    EndIf
    nSelAlmox := Max(1, Min(nSelAlmox, Len(aAlmoxOpc)))

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

    // Define almoxarifes conforme opcao selecionada
    Do Case
        Case nSelAlmox == 1  // Todos
            cAlmox1 := ""
            cAlmox2 := ""
        Case nSelAlmox == 2  // jose.gustavo
            cAlmox1 := "jose.gustavo"
            cAlmox2 := ""
        Case nSelAlmox == 3  // Fred.caputo
            cAlmox1 := "Fred.caputo"
            cAlmox2 := ""
        Otherwise  // Ambos
            cAlmox1 := "jose.gustavo"
            cAlmox2 := "Fred.caputo"
    EndCase

    Processa({|| ZANALBX_Exec(dDtDe, dDtAte, AllTrim(cAlmox1), AllTrim(cAlmox2))}, ;
        "Processando...", "Analisando movimentacoes do armazem...")

    RestArea(aArea)
Return

/*/{Protheus.doc} ZANALBX_1D
Retorna o primeiro dia do mes da data informada
@type Static Function
/*/
Static Function ZANALBX_1D(dData)
    Local cAno := Str(Year(dData), 4)
    Local cMes := StrZero(Month(dData), 2)
Return StoD(cAno + cMes + "01")

/*/{Protheus.doc} ZANALBX_LD
Retorna o ultimo dia do mes da data informada
@type Static Function
/*/
Static Function ZANALBX_LD(dData)
    Local dProxMes  := ZANALBX_1D(dData) + 32
    Local dPrimProx := ZANALBX_1D(dProxMes)
Return dPrimProx - 1

/*/{Protheus.doc} ZANALBX_Exec
Executa a consulta principal e processa os dados
@type Static Function
@param dDtDe, Date, Data inicial
@param dDtAte, Date, Data final
@param cAlmox1, Character, Primeiro almoxarife
@param cAlmox2, Character, Segundo almoxarife
/*/
Static Function ZANALBX_Exec(dDtDe, dDtAte, cAlmox1, cAlmox2)
    Local aArea  := GetArea()
    Local cQuery := ""
    Local cAlias := GetNextAlias()
    Local aEstCods  := {}
    Local aNEstCods := {}
    Local cCodTmp   := ""
    Local nI
    Local nSomaLT   := 0
    Local nContLT   := 0
    Local aSAsNoPer := {}
    Local cSATmp    := ""
    Local dSATmp    := CtoD("  /  /    ")

    ProcRegua(4)
    IncProc("Coletando dados de movimentacao...")

    cQuery := " SELECT "
    cQuery += "   D3.D3_EMISSAO, "
    cQuery += "   D3.D3_COD, "
    cQuery += "   D3.D3_QUANT, "
    cQuery += "   D3.D3_USUARIO, "
    cQuery += "   D3.D3_TM, "
    cQuery += "   D3.D3_CC, "
    cQuery += "   D3.D3_DOC, "
    cQuery += "   D3.D3_NUMSA, "
    cQuery += "   ISNULL((SELECT TOP 1 B1.B1_DESC FROM " + RetSqlName("SB1") + " B1 "
    cQuery += "     WHERE B1.D_E_L_E_T_ = ' ' AND B1.B1_FILIAL = '" + xFilial("SB1") + "' "
    cQuery += "     AND B1.B1_COD = D3.D3_COD), '') AS B1_DESC, "
    cQuery += "   ISNULL((SELECT TOP 1 B1.B1_XCTAEST FROM " + RetSqlName("SB1") + " B1 "
    cQuery += "     WHERE B1.D_E_L_E_T_ = ' ' AND B1.B1_FILIAL = '" + xFilial("SB1") + "' "
    cQuery += "     AND B1.B1_COD = D3.D3_COD), '') AS B1_XCTAEST, "
    cQuery += "   ISNULL((SELECT TOP 1 B1.B1_UPRC FROM " + RetSqlName("SB1") + " B1 "
    cQuery += "     WHERE B1.D_E_L_E_T_ = ' ' AND B1.B1_FILIAL = '" + xFilial("SB1") + "' "
    cQuery += "     AND B1.B1_COD = D3.D3_COD), 0) AS B1_UPRC, "
    cQuery += "   ISNULL((SELECT TOP 1 CTT.CTT_DESC01 FROM " + RetSqlName("CTT") + " CTT "
    cQuery += "     WHERE CTT.D_E_L_E_T_ = ' ' AND CTT.CTT_FILIAL = '" + xFilial("CTT") + "' "
    cQuery += "     AND CTT.CTT_CUSTO = D3.D3_CC), '') AS CTT_DESC, "
    cQuery += "   ISNULL((SELECT TOP 1 CP.CP_EMISSAO FROM " + RetSqlName("SCP") + " CP "
    cQuery += "     WHERE CP.D_E_L_E_T_ = ' ' AND CP.CP_FILIAL = '" + xFilial("SCP") + "' "
    cQuery += "     AND CP.CP_NUM = D3.D3_NUMSA), '') AS CP_EMISSAO, "
    cQuery += "   ISNULL((SELECT TOP 1 CP.CP_SOLICIT FROM " + RetSqlName("SCP") + " CP "
    cQuery += "     WHERE CP.D_E_L_E_T_ = ' ' AND CP.CP_FILIAL = '" + xFilial("SCP") + "' "
    cQuery += "     AND CP.CP_NUM = D3.D3_NUMSA), '') AS CP_SOLICIT "
    cQuery += " FROM " + RetSqlName("SD3") + " D3 "
    cQuery += " WHERE D3.D_E_L_E_T_ = ' ' "
    cQuery += "   AND D3.D3_FILIAL = '0102' "
    cQuery += "   AND D3.D3_LOCAL = '02' "
    cQuery += "   AND D3.D3_EMISSAO >= '" + DtoS(dDtDe) + "' "
    cQuery += "   AND D3.D3_EMISSAO <= '" + DtoS(dDtAte) + "' "
    cQuery += "   AND D3.D3_TM = '502' "
    cQuery += "   AND D3.D3_QUANT > 0 "

    If !Empty(cAlmox1) .And. !Empty(cAlmox2)
        cQuery += "   AND D3.D3_USUARIO IN ('" + cAlmox1 + "', '" + cAlmox2 + "') "
    ElseIf !Empty(cAlmox1)
        cQuery += "   AND D3.D3_USUARIO = '" + cAlmox1 + "' "
    ElseIf !Empty(cAlmox2)
        cQuery += "   AND D3.D3_USUARIO = '" + cAlmox2 + "' "
    EndIf

    // Exclui itens de SAs encerradas (azul): somente baixadas (vermelho) = CP_QUJE >= CP_QUANT
    cQuery += "   AND ( RTRIM(D3.D3_NUMSA) = '' OR EXISTS ( "
    cQuery += "     SELECT 1 FROM " + RetSqlName("SCP") + " CP_CHK "
    cQuery += "     WHERE CP_CHK.D_E_L_E_T_ = ' ' "
    cQuery += "     AND CP_CHK.CP_FILIAL = '" + xFilial("SCP") + "' "
    cQuery += "     AND CP_CHK.CP_NUM = D3.D3_NUMSA "
    cQuery += "     AND CP_CHK.CP_PRODUTO = D3.D3_COD "
    cQuery += "     AND CP_CHK.CP_QUJE >= CP_CHK.CP_QUANT )) "

    cQuery += " ORDER BY D3.D3_EMISSAO DESC, D3.D3_COD "
    cQuery := ChangeQuery(cQuery)

    If Select(cAlias) > 0
        (cAlias)->(DbCloseArea())
    EndIf
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)

    IncProc("Processando dados...")

    aDados    := {}
    nTotMovs  := 0
    nTotQuant := 0
    nVlrTotal := 0
    nTotEst   := 0
    nTotNEst  := 0
    nTotFora  := 0

    (cAlias)->(DbGoTop())
    While !(cAlias)->(EoF())
        nTotMovs++
        nTotQuant += (cAlias)->D3_QUANT
        nVlrTotal += (cAlias)->B1_UPRC * (cAlias)->D3_QUANT

        // Conta produtos distintos por tipo (Estoque vs Nao Estoque)
        cCodTmp := AllTrim((cAlias)->D3_COD)
        If AllTrim((cAlias)->B1_XCTAEST) == "11401200001"
            If aScan(aEstCods, {|x| x == cCodTmp}) == 0
                aAdd(aEstCods, cCodTmp)
            EndIf
        Else
            If aScan(aNEstCods, {|x| x == cCodTmp}) == 0
                aAdd(aNEstCods, cCodTmp)
            EndIf
        EndIf

        aAdd(aDados, {;
            StoD((cAlias)->D3_EMISSAO),;     // [1] Data
            AllTrim((cAlias)->D3_COD),;      // [2] Codigo
            AllTrim((cAlias)->B1_DESC),;     // [3] Descricao
            (cAlias)->D3_QUANT,;             // [4] Quantidade
            AllTrim((cAlias)->D3_USUARIO),;  // [5] Usuario
            AllTrim((cAlias)->D3_CC),;       // [6] Centro Custo
            AllTrim((cAlias)->CTT_DESC),;    // [7] Descricao CC
            (cAlias)->B1_UPRC,;              // [8] Custo Unit (B1_UPRC - ultimo preco de custo)
            AllTrim((cAlias)->D3_DOC),;      // [9] Documento
            AllTrim((cAlias)->D3_TM),;       // [10] Tipo Movto
            IIf(AllTrim((cAlias)->B1_XCTAEST) == "11401200001", "Estoque", "Nao Estoque"),; // [11] Tipo Item
            AllTrim((cAlias)->D3_NUMSA),; // [12] Numero SA (Solicitacao ao Armazem = CP_NUM)
            IIf(!Empty((cAlias)->CP_EMISSAO), StoD((cAlias)->CP_EMISSAO), CtoD("  /  /    ")),; // [13] Data Solicit. (SA)
            AllTrim((cAlias)->CP_SOLICIT); // [14] Solicitante (quem abriu a SA)
        })

        (cAlias)->(DbSkip())
    End
    (cAlias)->(DbCloseArea())

    If nTotMovs == 0
        MsgAlert("Nenhuma movimentacao encontrada para o periodo e filtros selecionados.", "Aviso")
        RestArea(aArea)
        Return
    EndIf

    // Totais de produtos distintos por tipo
    nTotEst  := Len(aEstCods)
    nTotNEst := Len(aNEstCods)

    // Conta total de SAs distintas geradas dentro do periodo (CP_EMISSAO dentro do range)
    aSAsNoPer := {}
    cSATmp    := ""
    dSATmp    := CtoD("  /  /    ")
    For nI := 1 To Len(aDados)
        cSATmp := AllTrim(aDados[nI][12])  // D3_NUMSA
        dSATmp := aDados[nI][13]           // CP_EMISSAO
        If !Empty(cSATmp) .And. !Empty(dSATmp) .And. dSATmp >= dDtDe .And. dSATmp <= dDtAte
            If aScan(aSAsNoPer, {|x| x == cSATmp}) == 0
                aAdd(aSAsNoPer, cSATmp)
            EndIf
        EndIf
    Next nI
    nTotSAs := Len(aSAsNoPer)

    IncProc("Calculando estatisticas...")
    aAreas := ZANALBX_Users(aDados, dDtDe, dDtAte)
    ZANALBX_Calc(aDados)
    aResumo := ZANALBX_Agr(aDados)

    // Calcula leadtime medio total
    nSomaLT := 0
    nContLT := 0
    For nI := 1 To Len(aDados)
        If !Empty(aDados[nI][13]) .And. !Empty(aDados[nI][1]) .And. aDados[nI][1] >= aDados[nI][13]
            nSomaLT += (aDados[nI][1] - aDados[nI][13])
            nContLT++
        EndIf
    Next nI
    nLTMedio := IIf(nContLT > 0, Round(nSomaLT / nContLT, 0), 0)

    aDadosOrig  := aClone(aDados)
    aAreasOrig  := aClone(aAreas)
    aResumoOrig := aClone(aResumo)

    IncProc("Gerando tela...")
    ZANALBX_Tela(dDtDe, dDtAte, cAlmox1, cAlmox2)

    RestArea(aArea)
Return

/*/{Protheus.doc} ZANALBX_Users
Calcula o top 10 de areas/centros de custo que mais solicitaram.
Conta apenas SAs cuja data de emissao (CP_EMISSAO, idx [13]) esteja
dentro do periodo selecionado.
@type Static Function
@param aDadosArr, Array, Dados das movimentacoes
@param dDtDe, Date, Data inicial do periodo
@param dDtAte, Date, Data final do periodo
@return Array, Top areas: {Descricao, Solicitacoes, aDocs}
/*/
Static Function ZANALBX_Users(aDadosArr, dDtDe, dDtAte)
    Local aResult  := {}
    Local aCCS     := {}
    Local nI, nPos, nPosDoc
    Local cChave   := ""
    Local cDoc     := ""
    Local cSolicit := ""
    Local dDataSA  := CtoD("  /  /    ")

    // Conta solicitacoes distintas por Nr.S.A. (D3_NUMSA) por solicitante
    // Somente SAs cuja CP_EMISSAO esteja dentro do periodo selecionado
    For nI := 1 To Len(aDadosArr)
        cChave  := IIf(!Empty(aDadosArr[nI][14]), AllTrim(aDadosArr[nI][14]), "(sem solicitante)")
        cDoc    := AllTrim(aDadosArr[nI][12])  // [12] D3_NUMSA (Nr.S.A.)
        dDataSA := aDadosArr[nI][13]           // [13] Data Emissao SA (CP_EMISSAO)
        cSolicit := AllTrim(aDadosArr[nI][6]) + " - " + AllTrim(aDadosArr[nI][7])  // CC + Desc para popup

        // Sem Nr.S.A. nao conta
        If Empty(cDoc)
            Loop
        EndIf

        // Filtra: somente SAs emitidas dentro do periodo
        If Empty(dDataSA) .Or. dDataSA < dDtDe .Or. dDataSA > dDtAte
            Loop
        EndIf

        nPos := aScan(aCCS, {|x| x[1] == cChave})
        If nPos == 0
            aAdd(aCCS, {cChave, 1, {{cDoc, dDataSA, cSolicit}}})
        Else
            nPosDoc := aScan(aCCS[nPos][3], {|d| d[1] == cDoc})
            If nPosDoc == 0
                aAdd(aCCS[nPos][3], {cDoc, dDataSA, cSolicit})
                aCCS[nPos][2]++
            EndIf
        EndIf
    Next nI

    aSort(aCCS,,, {|x, y| x[2] > y[2]})

    For nI := 1 To Min(10, Len(aCCS))
        aAdd(aResult, {aCCS[nI][1], aCCS[nI][2], aCCS[nI][3]})
    Next nI

Return aResult

/*/{Protheus.doc} ZANALBX_Calc
Calcula para cada linha do aDados:
[14] = Quantidade total solicitada do mesmo codigo (soma D3_QUANT por D3_COD)
[15] = Numero de solicitacoes distintas (documentos distintos) do mesmo codigo
@type Static Function
@param aDadosArr, Array, Dados das movimentacoes
/*/
Static Function ZANALBX_Calc(aDadosArr)
    Local aProds := {}
    Local nI, nPos
    Local cCod   := ""

    // Primeiro passo: agrupa por codigo - [1]=cod [2]=qtd_total [3]=contagem_linhas
    For nI := 1 To Len(aDadosArr)
        cCod := aDadosArr[nI][2]
        nPos := aScan(aProds, {|x| x[1] == cCod})
        If nPos == 0
            aAdd(aProds, {cCod, aDadosArr[nI][4], 1})
        Else
            aProds[nPos][2] += aDadosArr[nI][4]
            aProds[nPos][3]++
        EndIf
    Next nI

    // Segundo passo: grava [14] e [15] em cada linha do aDados
    For nI := 1 To Len(aDadosArr)
        cCod := aDadosArr[nI][2]
        nPos := aScan(aProds, {|x| x[1] == cCod})
        If nPos > 0
            aAdd(aDadosArr[nI], aProds[nPos][2])  // [14] Qtd total do codigo
            aAdd(aDadosArr[nI], aProds[nPos][3])  // [15] Nro vezes que o codigo aparece
        Else
            aAdd(aDadosArr[nI], aDadosArr[nI][4])  // [14]
            aAdd(aDadosArr[nI], 1)                 // [15]
        EndIf
    Next nI
Return

/*/{Protheus.doc} ZANALBX_Agr
Agrupa movimentacoes por produto gerando resumo estilo tabela dinamica.
Cada linha do SD3 equivale a 1 baixa, portanto a contagem de linhas
por codigo e o numero real de baixas no periodo.
@type Static Function
@param aDadosArr, Array, Dados detalhados das movimentacoes
@return Array, Resumo agrupado: {Codigo, Descricao, QtdTotal, CustoUnit, VlrTotal, NoBaixas, TipoItem, QuemBaixou, Dt1aSA, DtUltBaixa, LTMedioDias}
/*/
Static Function ZANALBX_Agr(aDadosArr)
    Local aResult := {}
    Local nI, nPos, nPosU, nPosD, nU
    Local cCod    := ""
    Local cUser   := ""
    Local cUsers  := ""
    Local cDoc    := ""
    Local dDataBx := CtoD("  /  /    ")
    Local dDataSA := CtoD("  /  /    ")
    Local nLT     := 0

    For nI := 1 To Len(aDadosArr)
        cCod  := aDadosArr[nI][2]
        cUser := AllTrim(aDadosArr[nI][5])   // [5] Usuario/Almoxarife
        cDoc  := AllTrim(aDadosArr[nI][9])   // [9] Documento/Reserva
        dDataBx := aDadosArr[nI][1]          // [1] Data baixa (D3_EMISSAO)
        dDataSA := aDadosArr[nI][13]         // [13] Data SA (CP_EMISSAO)

        // Para doc vazio, cria chave sintetica unica por linha
        If Empty(cDoc)
            cDoc := "_LN_" + cValToChar(nI)
        EndIf

        nPos  := aScan(aResult, {|x| x[1] == cCod})
        If nPos == 0
            aAdd(aResult, {;
                cCod,;                                          // [1] Codigo
                AllTrim(aDadosArr[nI][3]),;                     // [2] Descricao
                aDadosArr[nI][4],;                              // [3] Qtd Total
                aDadosArr[nI][8],;                              // [4] Custo Unit (B1_UPRC)
                aDadosArr[nI][4] * aDadosArr[nI][8],;          // [5] Vlr Total
                1,;                                             // [6] No Baixas (reservas distintas)
                aDadosArr[nI][11],;                             // [7] Tipo Item
                {cUser},;                                       // [8] Array temp usuarios
                {cDoc},;                                        // [9] Array temp docs/reservas
                IIf(!Empty(dDataSA) .And. !Empty(dDataBx) .And. dDataBx >= dDataSA, dDataBx - dDataSA, 0),; // [10] Soma leadtime
                IIf(!Empty(dDataSA) .And. !Empty(dDataBx), 1, 0),; // [11] Count leadtimes validos
                dDataSA,;                                       // [12] Min data SA (1a SA)
                dDataBx})                                       // [13] Max data baixa (ult baixa)
        Else
            aResult[nPos][3] += aDadosArr[nI][4]
            aResult[nPos][5] += aDadosArr[nI][4] * aDadosArr[nI][8]
            aResult[nPos][6]++   // Conta cada linha SD3 como 1 baixa real
            // Rastreia docs distintos (para uso interno)
            nPosD := aScan(aResult[nPos][9], {|d| d == cDoc})
            If nPosD == 0
                aAdd(aResult[nPos][9], cDoc)
            EndIf
            // Conta usuarios distintos
            If !Empty(cUser)
                nPosU := aScan(aResult[nPos][8], {|u| u == cUser})
                If nPosU == 0
                    aAdd(aResult[nPos][8], cUser)
                EndIf
            EndIf
            // Acumula leadtime
            If !Empty(dDataSA) .And. !Empty(dDataBx)
                If dDataBx >= dDataSA
                    aResult[nPos][10] += (dDataBx - dDataSA)
                EndIf
                aResult[nPos][11]++
            EndIf
            // Min data SA
            If !Empty(dDataSA) .And. (Empty(aResult[nPos][12]) .Or. dDataSA < aResult[nPos][12])
                aResult[nPos][12] := dDataSA
            EndIf
            // Max data baixa
            If !Empty(dDataBx) .And. (Empty(aResult[nPos][13]) .Or. dDataBx > aResult[nPos][13])
                aResult[nPos][13] := dDataBx
            EndIf
        EndIf
    Next nI

    // Converte arrays temporarios e calcula leadtime medio
    For nI := 1 To Len(aResult)
        // [6] ja contem o numero real de baixas (linhas SD3 por produto)

        // Converte [8] array de usuarios em string
        cUsers := ""
        For nU := 1 To Len(aResult[nI][8])
            cUsers += IIf(nU > 1, " / ", "") + aResult[nI][8][nU]
        Next nU
        aResult[nI][8] := cUsers

        // Calcula leadtime medio (dias)
        nLT := IIf(aResult[nI][11] > 0, Round(aResult[nI][10] / aResult[nI][11], 0), 0)

        // Reorganiza: [9]=Dt1aSA  [10]=DtUltBaixa  [11]=LTMedioDias
        aResult[nI][9]  := aResult[nI][12]   // Min data SA
        aResult[nI][10] := aResult[nI][13]   // Max data Baixa
        aResult[nI][11] := nLT               // LT medio dias

        // Remove temporarios [12] e [13]
        aSize(aResult[nI], 11)
    Next nI

    // Ordena por valor total decrescente (maior consumo no topo)
    aSort(aResult,,, {|x, y| x[5] > y[5]})

Return aResult

/*/{Protheus.doc} ZANALBX_Tela
Tela de resultados com indicadores, grids de areas/itens e detalhe
Seguindo o mesmo padrao visual do ZCOMPRAS
@type Static Function
@param dDtDe, Date, Data inicial
@param dDtAte, Date, Data final
@param cAlmox1, Character, Primeiro almoxarife
@param cAlmox2, Character, Segundo almoxarife
/*/
Static Function ZANALBX_Tela(dDtDe, dDtAte, cAlmox1, cAlmox2)
    Local oDlg
    Local oListAreas, oListResumo
    Local oFont, oFontTit, oFontInd, oFontVal
    Local oBtnExcelRes, oBtnNova, oBtnFechar
    Local oBtnFiltrar, oBtnLimpar, oBtnMaiorVal, oBtnMaisSol
    Local oBtnEstoque, oBtnNEstoque
    Local oGetFiltro
    Local cFiltro    := Space(40)
    Local cTitulo    := "Analise de Baixas - Armazem 02 (" + DtoC(dDtDe) + " a " + DtoC(dDtAte) + ")"
    Local cDescAlmox := ""
    Local oTsayReg

    If !Empty(cAlmox1) .And. !Empty(cAlmox2)
        cDescAlmox := cAlmox1 + " / " + cAlmox2
    ElseIf !Empty(cAlmox1)
        cDescAlmox := cAlmox1
    ElseIf !Empty(cAlmox2)
        cDescAlmox := cAlmox2
    Else
        cDescAlmox := "Todos os almoxarifes"
    EndIf

    // Fontes (fora do dialog, liberadas no final)
    oFont    := TFont():New("Arial",, -11,, .F.)
    oFontTit := TFont():New("Arial",, -13, .T., .F.)
    oFontInd := TFont():New("Arial",, -12, .T., .F.)
    oFontVal := TFont():New("Arial",, -12,, .F.)

    // Dialog com STYLE DS_MODALFRAME (tamanho fixo, como ZCOMPRAS)
    DEFINE MSDIALOG oDlg TITLE cTitulo FROM 0,0 TO 650,1400 PIXEL STYLE DS_MODALFRAME

    // ================================================================
    // INDICADORES (topo)
    // ================================================================
    TSay():New(005, 010, {|| "Indicadores"}, oDlg, , ;
        oFontTit, , , , .T., CLR_HBLUE, , 200, 14)
    @ 017, 005 TO 060, 695 OF oDlg PIXEL

    // Periodo
    @ 024, 010 SAY "Periodo:" SIZE 050, 012 PIXEL OF oDlg FONT oFontInd
    TSay():New(024, 065, {|| DtoC(dDtDe) + " a " + DtoC(dDtAte)}, ;
        oDlg, , oFontVal, , , , .T., CLR_BLACK, , 160, 12)
    @ 024, 250 SAY "Almoxarife(s):" SIZE 085, 012 PIXEL OF oDlg FONT oFontInd
    TSay():New(024, 340, {|| cDescAlmox}, ;
        oDlg, , oFontVal, , , , .T., CLR_BLACK, , 200, 12)

    // Itens Estoque / Nao Estoque / Vlr Total
    @ 038, 010 SAY "Itens Estoque:" SIZE 085, 012 PIXEL OF oDlg FONT oFontInd
    TSay():New(038, 100, {|| cValToChar(nTotEst) + " (" + cValToChar(IIf((nTotEst+nTotNEst) > 0, Round(nTotEst/(nTotEst+nTotNEst)*100, 0), 0)) + "%)"}, ;
        oDlg, , oFontVal, , , , .T., CLR_BLACK, , 090, 12)
    @ 038, 250 SAY "Itens Nao Estoque:" SIZE 110, 012 PIXEL OF oDlg FONT oFontInd
    TSay():New(038, 365, {|| cValToChar(nTotNEst) + " (" + cValToChar(IIf((nTotEst+nTotNEst) > 0, Round(nTotNEst/(nTotEst+nTotNEst)*100, 0), 0)) + "%)"}, ;
        oDlg, , oFontVal, , , , .T., CLR_BLACK, , 090, 12)
    @ 038, 480 SAY "Vlr Total:" SIZE 060, 012 PIXEL OF oDlg FONT oFontInd
    TSay():New(038, 545, {|| "R$ " + Transform(nVlrTotal, "@E 999,999,999.99")}, ;
        oDlg, , oFontVal, , , , .T., CLR_HBLUE, , 145, 12)

    // Total Baixas / Produtos Distintos
    @ 048, 010 SAY "Total Baixas:" SIZE 085, 012 PIXEL OF oDlg FONT oFontInd
    TSay():New(048, 100, {|| cValToChar(nTotMovs)}, ;
        oDlg, , oFontVal, , , , .T., CLR_BLACK, , 060, 12)
    @ 048, 250 SAY "Produtos Distintos:" SIZE 105, 012 PIXEL OF oDlg FONT oFontInd
    TSay():New(048, 360, {|| cValToChar(nTotEst + nTotNEst)}, ;
        oDlg, , oFontVal, , , , .T., CLR_BLACK, , 060, 12)
    @ 048, 480 SAY "LT Medio:" SIZE 060, 012 PIXEL OF oDlg FONT oFontInd
    TSay():New(048, 545, {|| cValToChar(nLTMedio) + " dias"}, ;
        oDlg, , oFontVal, , , , .T., CLR_HBLUE, , 090, 12)

    // ================================================================
    // TOP 10 AREAS
    // ================================================================
    TSay():New(063, 010, {|| "TOP 10 - Solicitantes"}, oDlg, , ;
        oFontTit, , , , .T., CLR_HBLUE, , 430, 14)

    @ 075, 005 LISTBOX oListAreas FIELDS HEADER ;
        "#", ;
        "Solicitante", ;
        "SAs Distintas" ;
        SIZE 260, 060 OF oDlg PIXEL

    If Len(aAreas) > 0
        oListAreas:SetArray(aAreas)
        oListAreas:bLine := {|| {;
            cValToChar(oListAreas:nAt), ;
            aAreas[oListAreas:nAt][1], ;
            cValToChar(aAreas[oListAreas:nAt][2])}}
        oListAreas:aColSizes := {15, 160, 50}
        oListAreas:bLDblClick := {|| ZANALBX_SAs(aAreas[oListAreas:nAt])}
    EndIf

    // ================================================================
    // RESUMO POR PRODUTO
    // ================================================================
    oTsayReg := TSay():New(140, 010, ;
        {|| "Resumo por Produto (" + cValToChar(Len(aResumo)) + " produtos / " + cValToChar(Len(aDados)) + " baixas)"}, ;
        oDlg, , oFontTit, , , , .T., CLR_HBLUE, , 560, 14)

    // Barra de filtros
    @ 154, 005 SAY "Filtrar:" SIZE 042, 012 PIXEL OF oDlg FONT oFont
    @ 152, 053 MSGET oGetFiltro VAR cFiltro SIZE 195, 012 PIXEL OF oDlg

    @ 151, 254 BUTTON oBtnFiltrar PROMPT "Buscar"  SIZE 065, 014 OF oDlg PIXEL
    oBtnFiltrar:bLClicked := {|| ZANALBX_Fil(cFiltro, oListResumo, oDlg, oTsayReg)}

    @ 151, 325 BUTTON oBtnLimpar  PROMPT "Limpar"  SIZE 065, 014 OF oDlg PIXEL
    oBtnLimpar:bLClicked  := {|| cFiltro := Space(40), oGetFiltro:Refresh(), ;
        ZANALBX_Fil("", oListResumo, oDlg, oTsayReg)}

    @ 151, 396 BUTTON oBtnMaiorVal PROMPT "Maior Vlr" SIZE 065, 014 OF oDlg PIXEL
    oBtnMaiorVal:bLClicked := {|| aSort(aResumo,,, {|x,y| x[4] > y[4]}), ;
        oListResumo:nAt := 1, oListResumo:Refresh()}

    @ 151, 467 BUTTON oBtnMaisSol PROMPT "+ Baixas" SIZE 065, 014 OF oDlg PIXEL
    oBtnMaisSol:bLClicked := {|| aSort(aResumo,,, {|x,y| x[6] > y[6]}), ;
        oListResumo:nAt := 1, oListResumo:Refresh()}

    @ 151, 538 BUTTON oBtnEstoque PROMPT "Estoque" SIZE 065, 014 OF oDlg PIXEL
    oBtnEstoque:bLClicked := {|| ZANALBX_Fil("Estoque", oListResumo, oDlg, oTsayReg)}

    @ 151, 609 BUTTON oBtnNEstoque PROMPT "Nao Estoque" SIZE 080, 014 OF oDlg PIXEL
    oBtnNEstoque:bLClicked := {|| ZANALBX_Fil("Nao Estoque", oListResumo, oDlg, oTsayReg)}

    // Grid resumo por produto (SIZE 115 = mesmo do ZCOMPRAS)
    @ 168, 005 LISTBOX oListResumo FIELDS HEADER ;
        "Codigo", ;
        "Descricao", ;
        "Qtd Total", ;
        "Custo Unit.", ;
        "Vlr Total", ;
        "No Baixas", ;
        "Tipo", ;
        "Quem Baixou", ;
        "Data Emissao", ;
        "Data Baixa", ;
        "LT Medio" ;
        SIZE 690, 115 OF oDlg PIXEL

    oListResumo:SetArray(aResumo)
    oListResumo:bLine := {|| {;
        AllTrim(aResumo[oListResumo:nAt][1]), ;
        AllTrim(aResumo[oListResumo:nAt][2]), ;
        Transform(aResumo[oListResumo:nAt][3], "@E 999,999.99"), ;
        Transform(aResumo[oListResumo:nAt][4], "@E 99,999.99"), ;
        Transform(aResumo[oListResumo:nAt][5], "@E 999,999,999.99"), ;
        cValToChar(aResumo[oListResumo:nAt][6]), ;
        aResumo[oListResumo:nAt][7], ;
        AllTrim(aResumo[oListResumo:nAt][8]), ;
        IIf(!Empty(aResumo[oListResumo:nAt][9]), DtoC(aResumo[oListResumo:nAt][9]), ""), ;
        IIf(!Empty(aResumo[oListResumo:nAt][10]), DtoC(aResumo[oListResumo:nAt][10]), ""), ;
        cValToChar(aResumo[oListResumo:nAt][11]) + "d"}}

    oListResumo:aColSizes := {70, 165, 50, 55, 80, 40, 50, 85, 55, 55, 35}

    // Botoes no rodape
    @ 288, 015 BUTTON oBtnExcelRes PROMPT "Exportar Excel" SIZE 085, 015 OF oDlg PIXEL
    oBtnExcelRes:bLClicked := {|| ZANALBX_XR(dDtDe, dDtAte, cAlmox1, cAlmox2, aResumo)}

    @ 288, 115 BUTTON oBtnNova PROMPT "Nova Consulta" SIZE 085, 015 OF oDlg PIXEL ;
        ACTION (oDlg:End(), U_ZANALBX())

    @ 288, 600 BUTTON oBtnFechar PROMPT "Fechar" SIZE 085, 015 OF oDlg PIXEL ;
        ACTION oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED

    FreeObj(oFont)
    FreeObj(oFontTit)
    FreeObj(oFontInd)
    FreeObj(oFontVal)
Return

/*/{Protheus.doc} ZANALBX_SAs
Exibe tela com todos os numeros de SA da area selecionada no Top 10
@type Static Function
@param aAreaSel, Array, Linha da area selecionada {Descricao, NoPeriodo, ForaPeriodo, aDocsPeriodo, aDocsFora}
/*/
Static Function ZANALBX_SAs(aAreaSel)
    Local oDlgSA, oListSA, oFontSA
    Local aTodos := {}
    Local nI
    Local cArea  := aAreaSel[1]

    // Monta array unico: {Nr.SA, Data Emissao, Solicitante}
    If Len(aAreaSel) >= 3 .And. ValType(aAreaSel[3]) == "A"
        For nI := 1 To Len(aAreaSel[3])
            aAdd(aTodos, {AllTrim(aAreaSel[3][nI][1]), ;
                IIf(!Empty(aAreaSel[3][nI][2]), DtoC(aAreaSel[3][nI][2]), ""), ;
                IIf(Len(aAreaSel[3][nI]) >= 3, AllTrim(aAreaSel[3][nI][3]), "")})
        Next nI
    EndIf

    If Len(aTodos) == 0
        MsgInfo("Nenhuma SA encontrada para esta area.", "Detalhe")
        Return
    EndIf

    // Ordena por numero da SA
    aSort(aTodos,,, {|x, y| x[1] < y[1]})

    oFontSA := TFont():New("Arial",, -11,, .F.)

    DEFINE MSDIALOG oDlgSA TITLE "SAs - " + cArea + " (" + cValToChar(Len(aTodos)) + ")" ;
        FROM 0,0 TO 460,550 PIXEL

    @ 005, 005 LISTBOX oListSA FIELDS HEADER ;
        "#", ;
        "Nr. SA", ;
        "Data Emissao", ;
        "Centro de Custo" ;
        SIZE 265, 215 OF oDlgSA PIXEL

    oListSA:SetArray(aTodos)
    oListSA:bLine := {|| {;
        cValToChar(oListSA:nAt), ;
        aTodos[oListSA:nAt][1], ;
        aTodos[oListSA:nAt][2], ;
        aTodos[oListSA:nAt][3]}}
    oListSA:aColSizes := {20, 55, 55, 175}

    ACTIVATE MSDIALOG oDlgSA CENTERED

    FreeObj(oFontSA)
Return

/*/{Protheus.doc} ZANALBX_Fil
Filtra o grid de resumo pelo texto informado.
Filtra aDados (movimentos), reconstroi aResumo (pivot) e atualiza o grid.
Busca em: codigo, descricao, centro de custo e area.
@type Static Function
@param cFiltro, Character, Texto para filtrar
@param oListResumo, Object, Grid de resumo por produto
@param oDlg, Object, Dialog principal
@param oTsayReg, Object, Label com contagem de produtos/baixas
/*/
Static Function ZANALBX_Fil(cFiltro, oListResumo, oDlg, oTsayReg)
    Local cBusca := AllTrim(Upper(cFiltro))
    Local nI

    aDados := {}

    If Empty(cBusca)
        aDados := aClone(aDadosOrig)
    Else
        For nI := 1 To Len(aDadosOrig)
            If (cBusca $ Upper(aDadosOrig[nI][2])) .Or. ;
               (cBusca $ Upper(aDadosOrig[nI][3])) .Or. ;
               (cBusca $ Upper(aDadosOrig[nI][6])) .Or. ;
               (cBusca $ Upper(aDadosOrig[nI][7])) .Or. ;
               (Upper(aDadosOrig[nI][11]) == cBusca)
                aAdd(aDados, aDadosOrig[nI])
            EndIf
        Next nI

        If Len(aDados) == 0
            aDados := aClone(aDadosOrig)
            MsgInfo("Nenhum produto encontrado com o filtro aplicado.", "Filtro")
        EndIf
    EndIf

    // Reconstroi pivot a partir dos movimentos filtrados
    aResumo := ZANALBX_Agr(aDados)

    // Recalcula Vlr Total para refletir exatamente o filtro atual
    nVlrTotal := 0
    For nI := 1 To Len(aDados)
        nVlrTotal += aDados[nI][4] * aDados[nI][8]  // D3_QUANT * B1_UPRC
    Next nI

    oListResumo:nAt := 1
    oListResumo:SetArray(aResumo)
    oListResumo:bLine := {|| {;
        AllTrim(aResumo[oListResumo:nAt][1]), ;
        AllTrim(aResumo[oListResumo:nAt][2]), ;
        Transform(aResumo[oListResumo:nAt][3], "@E 999,999.99"), ;
        Transform(aResumo[oListResumo:nAt][4], "@E 99,999.99"), ;
        Transform(aResumo[oListResumo:nAt][5], "@E 999,999,999.99"), ;
        cValToChar(aResumo[oListResumo:nAt][6]), ;
        aResumo[oListResumo:nAt][7], ;
        AllTrim(aResumo[oListResumo:nAt][8]), ;
        IIf(!Empty(aResumo[oListResumo:nAt][9]), DtoC(aResumo[oListResumo:nAt][9]), ""), ;
        IIf(!Empty(aResumo[oListResumo:nAt][10]), DtoC(aResumo[oListResumo:nAt][10]), ""), ;
        cValToChar(aResumo[oListResumo:nAt][11]) + "d"}}
    oListResumo:Refresh()

    If ValType(oTsayReg) == "O" .And. oTsayReg != Nil
        oTsayReg:SetText("Resumo por Produto (" + cValToChar(Len(aResumo)) + " produtos / " + cValToChar(Len(aDados)) + " baixas)")
        oTsayReg:Refresh()
    EndIf

    If ValType(oDlg) == "O" .And. oDlg != Nil
        oDlg:Refresh()
    EndIf
Return

/*/{Protheus.doc} ZANALBX_XR
Exporta o resumo por produto para Excel/PDF/HTML usando TReport
@type Static Function
/*/
Static Function ZANALBX_XR(dDtDe, dDtAte, cAlmox1, cAlmox2, aResumoExp)
    Local oReport
    Local oSection
    Local cDescAlmox := ""

    If Len(aResumoExp) == 0
        MsgAlert("Nao ha dados para exportar!", "Atencao")
        Return
    EndIf

    If !Empty(cAlmox1) .And. !Empty(cAlmox2)
        cDescAlmox := cAlmox1 + " / " + cAlmox2
    ElseIf !Empty(cAlmox1)
        cDescAlmox := cAlmox1
    ElseIf !Empty(cAlmox2)
        cDescAlmox := cAlmox2
    Else
        cDescAlmox := "Todos"
    EndIf

    oReport := TReport():New("ZANALBX", ;
        "Analise de Baixas - Armazem 02", "", ;
        {|oReport| ZANALBX_IR(oReport, dDtDe, dDtAte, cDescAlmox, aResumoExp)}, ;
        "Resumo por produto - Filial: " + cFilAnt)

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    oSection := TRSection():New(oReport, "Resumo", {})

    TRCell():New(oSection, "CODIGO",    "", "Codigo",      "@!", 15)
    TRCell():New(oSection, "DESCRICAO", "", "Descricao",   "@!", 30)
    TRCell():New(oSection, "QTDTOTAL",  "", "Qtd Total",   "@E 999,999.99", 12)
    TRCell():New(oSection, "CUSTOUNIT", "", "Custo Unit.",  "@E 99,999.99", 12)
    TRCell():New(oSection, "VLRTOTAL",  "", "Vlr Total",   "@E 999,999,999.99", 15)
    TRCell():New(oSection, "NOBAIXAS",  "", "No Baixas",   "@!", 8)
    TRCell():New(oSection, "TIPO",      "", "Tipo",        "@!", 12)
    TRCell():New(oSection, "QUEMBAIXOU","", "Quem Baixou", "@!", 20)
    TRCell():New(oSection, "DT1ASA",    "", "Data Emissao","@!", 10)
    TRCell():New(oSection, "DTULTBX",   "", "Data Baixa",  "@!", 10)
    TRCell():New(oSection, "LTMEDIO",   "", "LT Medio",    "@!", 8)

    oReport:PrintDialog()
Return

/*/{Protheus.doc} ZANALBX_IR
Popula o TReport com os dados do resumo
@type Static Function
/*/
Static Function ZANALBX_IR(oReport, dDtDe, dDtAte, cDescAlmox, aResumoExp)
    Local oSection := oReport:Section(1)
    Local nI
    Local nTotVlr := 0
    Local nTotQtd := 0

    oReport:SetMeter(0)
    oSection:Init()

    // Cabecalho
    oSection:SetHeaderSection(.T.)
    oReport:PrintText("Almoxarife(s): " + cDescAlmox + "   |   Periodo: " + ;
        DtoC(dDtDe) + " a " + DtoC(dDtAte) + ;
        "   |   Produtos: " + cValToChar(Len(aResumoExp)), 0)
    oReport:SkipLine()

    // Dados
    For nI := 1 To Len(aResumoExp)
        oSection:Cell("CODIGO"):SetValue(aResumoExp[nI][1])
        oSection:Cell("DESCRICAO"):SetValue(aResumoExp[nI][2])
        oSection:Cell("QTDTOTAL"):SetValue(aResumoExp[nI][3])
        oSection:Cell("CUSTOUNIT"):SetValue(aResumoExp[nI][4])
        oSection:Cell("VLRTOTAL"):SetValue(aResumoExp[nI][5])
        oSection:Cell("NOBAIXAS"):SetValue(cValToChar(aResumoExp[nI][6]))
        oSection:Cell("TIPO"):SetValue(aResumoExp[nI][7])
        oSection:Cell("QUEMBAIXOU"):SetValue(aResumoExp[nI][8])
        oSection:Cell("DT1ASA"):SetValue(IIf(!Empty(aResumoExp[nI][9]), DtoC(aResumoExp[nI][9]), ""))
        oSection:Cell("DTULTBX"):SetValue(IIf(!Empty(aResumoExp[nI][10]), DtoC(aResumoExp[nI][10]), ""))
        oSection:Cell("LTMEDIO"):SetValue(cValToChar(aResumoExp[nI][11]) + "d")

        oSection:PrintLine()
        oReport:IncMeter()

        nTotVlr += aResumoExp[nI][5]
        nTotQtd += aResumoExp[nI][3]
    Next nI

    // Totais
    oReport:SkipLine()
    oReport:PrintText("TOTAL: R$ " + Transform(nTotVlr, "@E 999,999,999.99") + ;
        "   |   Qtd Total: " + Transform(nTotQtd, "@E 999,999.99") + ;
        "   |   Produtos: " + cValToChar(Len(aResumoExp)), 0)

    oSection:Finish()
Return
