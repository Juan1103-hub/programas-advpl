#Include "Totvs.ch"
#Include "TopConn.ch"

#Define ZCC_CC_LIBERA   "5010206"
#Define ZCC_LOGIN_1     "JOSE.GUSTAVO"
#Define ZCC_LOGIN_2     "FRED.CAPUTO"

/*/{Protheus.doc} ZGASTOCC
Consulta de gastos por centro de custo.
Mostra, para um centro de custo e um periodo, o gasto dividido em tres
grupos: materiais comprados (itens de nota fiscal de entrada), servicos
(itens com codigo iniciado em SV) e materiais requisitados ao
almoxarifado (baixas de estoque). Cada grupo e totalizado por classe de
valor; itens sem classe aparecem em "Sem classe de valor". A tela mostra
apenas o resumo por classe, os subtotais e o total geral, sem listar itens.
Tabelas: SD1 (itens de nota fiscal de entrada), SC7 (classe de valor do
pedido de compra), SD3 (movimentacoes internas), SB1 (descricao do
produto), CTT (centro de custo) e CTH (classe de valor).
Premissas (padrao dos fontes do repositorio): filial atual; registros nao
excluidos; compras pela data de digitacao da nota (D1_DTDIGIT), tipo 'N' e
valor D1_TOTAL; requisicoes pela baixa de almoxarifado D3_TM = '502' com
valor D3_CUSTO1, que nestes fontes e o valor total do movimento; estornos
ignorados; devolucao nao entra na conta, como em ZMOVMES e RELCTA01.
A classe de valor e lida de C7_CLVL (pedido) e D3_CLVL (movimento) somente
quando a coluna existir na base.
@type User Function
@author Suprimentos
@since 11/11/2026
@version 12.1.33
@return nil
/*/
User Function ZGASTOCC()
    Local aArea    := GetArea()
    Local aPar     := {}
    Local aRet     := {}
    Local aChk     := {}
    Local aMat     := {}
    Local aSvc     := {}
    Local aReq     := {}
    Local dDtDe    := CtoD("")
    Local dDtAte   := Date()
    Local cCodCC   := Space(9)
    Local cDescCC  := ""
    Local lNova    := .T.

    Do While lNova
        lNova := .F.

        // --- 1) Tela padrao de parametros do Protheus -----------------
        aPar := {}
        aAdd(aPar, {1, "Data De",        dDtDe,  "", "", "", "", 60, .T.})
        aAdd(aPar, {1, "Data Ate",       dDtAte, "", "", "", "", 60, .T.})
        aAdd(aPar, {1, "Centro de Custo", cCodCC, "", "", "", "", 60, .T.})

        If !ParamBox(aPar, "Gastos por Centro de Custo", @aRet)
            RestArea(aArea)
            Return
        EndIf

        dDtDe  := aRet[1]
        dDtAte := aRet[2]
        cCodCC := aRet[3]

        // --- 2) Validacoes --------------------------------------------
        If Empty(dDtDe) .Or. Empty(dDtAte)
            MsgAlert("Informe a data inicial e a data final.", "Atencao")
            Loop
        EndIf

        If dDtAte < dDtDe
            MsgAlert("A data final nao pode ser menor que a data inicial.", "Atencao")
            Loop
        EndIf

        If Empty(AllTrim(cCodCC))
            MsgAlert("Informe o centro de custo.", "Atencao")
            Loop
        EndIf

        aChk := ZCCValCC(cCodCC)
        If !aChk[1]
            MsgAlert("Centro de custo " + AllTrim(cCodCC) + " nao encontrado no cadastro.", "Atencao")
            Loop
        EndIf

        // Codigo usado nas consultas vem do cadastro, nunca do texto digitado
        cCodCC  := aChk[2]
        cDescCC := aChk[3]

        // --- 3) Carga dos tres grupos ---------------------------------
        ZCCCarrega(dDtDe, dDtAte, cCodCC, @aMat, @aSvc, @aReq)

        If Len(aMat) + Len(aSvc) + Len(aReq) == 0
            MsgAlert("Nenhum gasto encontrado para o centro de custo " + AllTrim(cCodCC) + ;
                " no periodo informado.", "Atencao")
            Loop
        EndIf

        // --- 4) Tela de resultado -------------------------------------
        lNova := ZCCTela(dDtDe, dDtAte, cCodCC, cDescCC, aMat, aSvc, aReq)
    EndDo

    RestArea(aArea)
Return

/*/{Protheus.doc} ZCCValCC
Confere se o centro de custo existe no cadastro (CTT) e devolve o codigo
gravado no cadastro, que e o valor usado nas consultas.
@type Static Function
@param cCodCC, character, codigo informado pelo usuario
@return array, {lEncontrou, codigo do cadastro, descricao}
/*/
Static Function ZCCValCC(cCodCC)
    Local aArea  := GetArea()
    Local aRet   := {.F., "", ""}
    Local cChave := ""

    cChave := xFilial("CTT") + PadR(AllTrim(cCodCC), 9)

    DbSelectArea("CTT")
    CTT->(DbSetOrder(1))
    If CTT->(DbSeek(cChave))
        aRet := {.T., AllTrim(CTT->CTT_CUSTO), AllTrim(CTT->CTT_DESC01)}
    EndIf

    RestArea(aArea)
Return aRet

/*/{Protheus.doc} ZCCColuna
Informa se uma coluna existe na tabela fisica deste ambiente. Serve para
os campos de classe de valor, que podem nao existir em todas as bases:
sem a coluna, a classe aparece vazia em vez de derrubar a consulta.
@type Static Function
@param cTabela, character, alias da tabela (exemplo: SC7)
@param cColuna, character, nome da coluna (exemplo: C7_CLVL)
@return logical, .T. quando a coluna existe
/*/
Static Function ZCCColuna(cTabela, cColuna)
    Local aArea  := GetArea()
    Local cAlias := GetNextAlias()
    Local cQuery := ""
    Local lRet   := .F.

    cQuery := "SELECT COLUMN_NAME "
    cQuery += "FROM INFORMATION_SCHEMA.COLUMNS "
    cQuery += "WHERE TABLE_NAME = '" + RetSqlName(cTabela) + "' "
    cQuery += "AND COLUMN_NAME = '" + cColuna + "'"
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)
    If !(cAlias)->(Eof())
        lRet := .T.
    EndIf
    (cAlias)->(DbCloseArea())

    RestArea(aArea)
Return lRet

/*/{Protheus.doc} ZCCCarrega
Carrega os tres grupos de gasto do centro de custo no periodo.
Grupo 1 e 2 saem dos itens de nota fiscal de entrada (SD1), pela data de
digitacao e tipo 'N', separados pelo prefixo SV do codigo do produto;
grupo 3 sai das baixas de almoxarifado (SD3, D3_TM = '502'), com o valor no
D3_CUSTO1, seguindo ZMOVMES e RELCTA01.
@type Static Function
@param dDtDe, date, data inicial do periodo
@param dDtAte, date, data final do periodo
@param cCodCC, character, codigo do centro de custo vindo do cadastro
@param aMat, array, retorno com os materiais comprados
@param aSvc, array, retorno com os servicos comprados
@param aReq, array, retorno com os materiais requisitados ao almoxarifado
@return nil
/*/
Static Function ZCCCarrega(dDtDe, dDtAte, cCodCC, aMat, aSvc, aReq)
    Local aArea   := GetArea()
    Local cAlias  := GetNextAlias()
    Local cQuery  := ""
    Local cDe     := DtoS(dDtDe)
    Local cAte    := DtoS(dDtAte)
    Local cCod    := ""
    Local cDescr  := ""
    Local cClasse := ""
    Local cClsDes := ""
    Local cDoc    := ""
    Local cSerie  := ""
    Local cSelCls := ""
    Local cJoin   := ""
    Local lC7Clvl := .F.
    Local lD3Clvl := .F.
    Local lD1Desc := .F.
    Local cValor  := ""
    Local nQtde   := 0
    Local nValor  := 0

    aMat := {}
    aSvc := {}
    aReq := {}

    // --- 1) Compras: itens de nota fiscal de entrada (SD1) ------------
    // Classe de valor vem do pedido de compra (C7_CLVL), quando existir
    lC7Clvl := ZCCColuna("SC7", "C7_CLVL")
    If lC7Clvl
        cSelCls := "C7.C7_CLVL AS CLVL, CTH.CTH_DESC01 AS CLSDES "
        cJoin   := "LEFT JOIN " + RetSqlName("CTH") + " CTH "
        cJoin   += "ON CTH.CTH_FILIAL = '" + xFilial("CTH") + "' AND CTH.CTH_CLVL = C7.C7_CLVL "
        cJoin   += "AND CTH.D_E_L_E_T_ = ' ' "
    Else
        cSelCls := "'' AS CLVL, '' AS CLSDES "
        cJoin   := ""
    EndIf

    lD1Desc := ZCCColuna("SD1", "D1_VALDESC")
    If lD1Desc
        cValor := "(ISNULL(D1.D1_TOTAL,0) - ISNULL(D1.D1_VALDESC,0))"
    Else
        cValor := "ISNULL(D1.D1_TOTAL,0)"
    EndIf

    cQuery := "SELECT D1.D1_DOC AS DOC, D1.D1_SERIE AS SERIE, D1.D1_DTDIGIT AS DT, "
    cQuery += "D1.D1_COD AS COD, ISNULL(D1.D1_QUANT,0) AS QTDE, " + cValor + " AS VALOR, "
    cQuery += "B1.B1_DESC AS DESCR, " + cSelCls
    cQuery += "FROM " + RetSqlName("SD1") + " D1 "
    cQuery += "LEFT JOIN " + RetSqlName("SB1") + " B1 "
    cQuery += "ON B1.B1_FILIAL = '" + xFilial("SB1") + "' AND B1.B1_COD = D1.D1_COD AND B1.D_E_L_E_T_ = ' ' "
    cQuery += "LEFT JOIN " + RetSqlName("SC7") + " C7 "
    cQuery += "ON C7.C7_FILIAL = '" + xFilial("SC7") + "' AND C7.C7_NUM = D1.D1_PEDIDO "
    cQuery += "AND C7.C7_ITEM = D1.D1_ITEMPC AND C7.D_E_L_E_T_ = ' ' "
    cQuery += cJoin
    cQuery += "WHERE D1.D_E_L_E_T_ = ' ' AND D1.D1_FILIAL = '" + xFilial("SD1") + "' "
    cQuery += "AND D1.D1_CC = '" + cCodCC + "' "
    cQuery += "AND D1.D1_TIPO = 'N' AND D1.D1_QUANT > 0 "
    cQuery += "AND D1.D1_DTDIGIT BETWEEN '" + cDe + "' AND '" + cAte + "' "
    cQuery += "ORDER BY D1.D1_DTDIGIT, D1.D1_DOC, D1.D1_ITEM"

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)
    TCSetField(cAlias, "QTDE",  "N", 16, 4)
    TCSetField(cAlias, "VALOR", "N", 16, 2)

    While !(cAlias)->(Eof())
        cCod    := AllTrim((cAlias)->COD)
        cDescr  := AllTrim((cAlias)->DESCR)
        cSerie  := AllTrim((cAlias)->SERIE)
        cClasse := ""
        cClsDes := ""
        cDoc    := AllTrim((cAlias)->DOC)
        nQtde   := (cAlias)->QTDE
        nValor  := (cAlias)->VALOR

        If ValType((cAlias)->CLVL) == "C"
            cClasse := AllTrim((cAlias)->CLVL)
        EndIf

        If ValType((cAlias)->CLSDES) == "C"
            cClsDes := AllTrim((cAlias)->CLSDES)
        EndIf

        If !Empty(cSerie)
            cDoc := cDoc + "/" + cSerie
        EndIf

        // Servico e o item cujo codigo comeca com SV (regra do pedido)
        If SubStr(Upper(cCod), 1, 2) == "SV"
            aAdd(aSvc, {StoD(AllTrim((cAlias)->DT)), cDoc, cCod, cDescr, nQtde, nValor, cClasse, cClsDes})
        Else
            aAdd(aMat, {StoD(AllTrim((cAlias)->DT)), cDoc, cCod, cDescr, nQtde, nValor, cClasse, cClsDes})
        EndIf

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    // --- 2) Requisicoes ao almoxarifado (SD3) -------------------------
    cAlias := GetNextAlias()

    // Classe de valor vem da propria movimentacao (D3_CLVL), quando existir
    lD3Clvl := ZCCColuna("SD3", "D3_CLVL")
    If lD3Clvl
        cSelCls := "D3.D3_CLVL AS CLVL, CTH.CTH_DESC01 AS CLSDES "
        cJoin   := "LEFT JOIN " + RetSqlName("CTH") + " CTH "
        cJoin   += "ON CTH.CTH_FILIAL = '" + xFilial("CTH") + "' AND CTH.CTH_CLVL = D3.D3_CLVL "
        cJoin   += "AND CTH.D_E_L_E_T_ = ' ' "
    Else
        cSelCls := "'' AS CLVL, '' AS CLSDES "
        cJoin   := ""
    EndIf

    cQuery := "SELECT D3.D3_DOC AS DOC, D3.D3_EMISSAO AS DT, D3.D3_COD AS COD, "
    cQuery += "ISNULL(D3.D3_QUANT,0) AS QTDE, ISNULL(D3.D3_CUSTO1,0) AS VALOR, "
    cQuery += "B1.B1_DESC AS DESCR, " + cSelCls
    cQuery += "FROM " + RetSqlName("SD3") + " D3 "
    cQuery += "LEFT JOIN " + RetSqlName("SB1") + " B1 "
    cQuery += "ON B1.B1_FILIAL = '" + xFilial("SB1") + "' AND B1.B1_COD = D3.D3_COD AND B1.D_E_L_E_T_ = ' ' "
    cQuery += cJoin
    cQuery += "WHERE D3.D_E_L_E_T_ = ' ' AND D3.D3_FILIAL = '" + xFilial("SD3") + "' "
    cQuery += "AND D3.D3_CC = '" + cCodCC + "' "
    cQuery += "AND D3.D3_TM = '502' "
    If AllTrim(cCodCC) <> ZCC_CC_LIBERA
        cQuery += "AND UPPER(RTRIM(D3.D3_USUARIO)) NOT IN ('" + ZCC_LOGIN_1 + "','" + ZCC_LOGIN_2 + "') "
    EndIf
    cQuery += "AND ISNULL(D3.D3_ESTORNO, '') <> 'S' "
    cQuery += "AND D3.D3_QUANT > 0 "
    cQuery += "AND D3.D3_EMISSAO BETWEEN '" + cDe + "' AND '" + cAte + "' "
    cQuery += "ORDER BY D3.D3_EMISSAO, D3.D3_DOC, D3.D3_COD"

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)
    TCSetField(cAlias, "QTDE",  "N", 16, 4)
    TCSetField(cAlias, "VALOR", "N", 16, 2)

    While !(cAlias)->(Eof())
        cCod    := AllTrim((cAlias)->COD)
        cDescr  := AllTrim((cAlias)->DESCR)
        cClasse := ""
        cClsDes := ""
        cDoc    := AllTrim((cAlias)->DOC)
        nQtde   := (cAlias)->QTDE
        nValor  := (cAlias)->VALOR

        If ValType((cAlias)->CLVL) == "C"
            cClasse := AllTrim((cAlias)->CLVL)
        EndIf

        If ValType((cAlias)->CLSDES) == "C"
            cClsDes := AllTrim((cAlias)->CLSDES)
        EndIf

        aAdd(aReq, {StoD(AllTrim((cAlias)->DT)), cDoc, cCod, cDescr, nQtde, nValor, cClasse, cClsDes})

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    RestArea(aArea)
Return

/*/{Protheus.doc} ZCCResumo
Agrupa as linhas de um grupo por classe de valor e devolve o total do
grupo. A classe vazia vira "Sem classe de valor" e fica sempre por
ultimo.
@type Static Function
@param aDados, array, linhas do grupo {data, documento, codigo, descricao, quantidade, valor, classe, descricao da classe}
@return array, {resumo por classe, total do grupo}
/*/
Static Function ZCCResumo(aDados)
    Local aResumo := {}
    Local aRet    := {}
    Local aSemCls := {}
    Local nTotal  := 0
    Local nPos    := 0
    Local nPosSem := 0
    Local nI      := 0
    Local cClasse := ""
    Local cDescr  := ""
    Local nValor  := 0

    For nI := 1 To Len(aDados)
        cClasse := AllTrim(aDados[nI][7])
        cDescr  := AllTrim(aDados[nI][8])
        nValor  := aDados[nI][6]

        If Empty(cClasse)
            cDescr := "Sem classe de valor"
        EndIf

        nTotal += nValor
        nPos    := aScan(aResumo, {|x| AllTrim(x[1]) == cClasse})

        If nPos == 0
            aAdd(aResumo, {cClasse, cDescr, nValor})
        Else
            aResumo[nPos][3] += nValor
        EndIf
    Next nI

    // Separa a linha sem classe para ela ficar depois das demais
    nPosSem := aScan(aResumo, {|x| Empty(AllTrim(x[1]))})
    If nPosSem > 0
        aSemCls := aResumo[nPosSem]
        aDel(aResumo, nPosSem)
        aSize(aResumo, Len(aResumo) - 1)
    EndIf

    If Len(aResumo) > 1
        aSort(aResumo,,, {|x, y| AllTrim(x[1]) < AllTrim(y[1])})
    EndIf

    If nPosSem > 0
        aAdd(aResumo, aSemCls)
    EndIf

    aRet := {aResumo, nTotal}
Return aRet

/*/{Protheus.doc} ZCCTela
Tela virtual de resultado: cabecalho com centro de custo, periodo e total
geral; resumo por classe de valor dos tres grupos; subtotal de cada grupo e
total geral no rodape. Nao lista itens nem valores de item. O botao Nova
consulta devolve .T. para o programa voltar a tela de parametros.
@type Static Function
@param dDtDe, date, data inicial do periodo
@param dDtAte, date, data final do periodo
@param cCodCC, character, codigo do centro de custo
@param cDescCC, character, descricao do centro de custo
@param aMat, array, materiais comprados
@param aSvc, array, servicos comprados
@param aReq, array, materiais requisitados ao almoxarifado
@return logical, .T. quando o usuario pediu nova consulta
/*/
Static Function ZCCTela(dDtDe, dDtAte, cCodCC, cDescCC, aMat, aSvc, aReq)
    Local oDlg      := Nil
    Local oLRes     := Nil
    Local oBtnNova  := Nil
    Local oBtnImp   := Nil
    Local aResumo   := {}
    Local aRetMat   := {}
    Local aRetSvc   := {}
    Local aRetReq   := {}
    Local aGrupo    := {}
    Local nTotMat   := 0
    Local nTotSvc   := 0
    Local nTotReq   := 0
    Local nTotGeral := 0
    Local nGrupo    := 0
    Local nI        := 0
    Local cGrupo    := ""
    Local cClasse   := ""
    Local lNova     := .F.

    aRetMat := ZCCResumo(aMat)
    aRetSvc := ZCCResumo(aSvc)
    aRetReq := ZCCResumo(aReq)

    nTotMat   := aRetMat[2]
    nTotSvc   := aRetSvc[2]
    nTotReq   := aRetReq[2]
    nTotGeral := nTotMat + nTotSvc + nTotReq

    // Resumo por classe de valor dos tres grupos, sem detalhar itens
    For nGrupo := 1 To 3
        Do Case
            Case nGrupo == 1
                cGrupo := "Materiais"
                aGrupo := aRetMat[1]
            Case nGrupo == 2
                cGrupo := "Servicos"
                aGrupo := aRetSvc[1]
            Otherwise
                cGrupo := "Requisitados"
                aGrupo := aRetReq[1]
        EndCase

        For nI := 1 To Len(aGrupo)
            cClasse := AllTrim(aGrupo[nI][1])
            If Empty(cClasse)
                cClasse := "-"
            EndIf
            aAdd(aResumo, {cGrupo, cClasse, AllTrim(aGrupo[nI][2]), aGrupo[nI][3]})
        Next nI
    Next nGrupo

    DEFINE MSDIALOG oDlg TITLE "Gastos por Centro de Custo" FROM 0,0 TO 450,1300 PIXEL

    @5,5   SAY "Centro de custo: " + AllTrim(cCodCC) + " - " + AllTrim(cDescCC) SIZE 400,10 OF oDlg PIXEL
    @5,420 SAY "Total geral: R$ " + ZCCFmtNum(nTotGeral, 2) SIZE 210,10 OF oDlg PIXEL
    @16,5  SAY "Periodo: " + DtoC(dDtDe) + " a " + DtoC(dDtAte) SIZE 300,10 OF oDlg PIXEL
    @30,5  SAY "Resumo por classe de valor" SIZE 200,10 OF oDlg PIXEL

    @44,5 LISTBOX oLRes FIELDS HEADER "Grupo", "Classe", "Descricao da classe", "Valor" ;
        SIZE 640,110 OF oDlg PIXEL
    oLRes:aColSizes := {90, 60, 330, 140}
    oLRes:SetArray(aResumo)
    oLRes:bLine := {|| {;
        SubStr(aResumo[oLRes:nAt][1], 1, 20), ;
        AllTrim(aResumo[oLRes:nAt][2]), ;
        SubStr(aResumo[oLRes:nAt][3], 1, 50), ;
        ZCCFmtNum(aResumo[oLRes:nAt][4], 2)}}

    @162,5   SAY "Materiais comprados: R$ " + ZCCFmtNum(nTotMat, 2) SIZE 200,10 OF oDlg PIXEL
    @162,215 SAY "Servicos: R$ " + ZCCFmtNum(nTotSvc, 2) SIZE 200,10 OF oDlg PIXEL
    @162,430 SAY "Requisitados ao almoxarifado: R$ " + ZCCFmtNum(nTotReq, 2) SIZE 210,10 OF oDlg PIXEL
    @178,5   SAY "TOTAL GERAL: R$ " + ZCCFmtNum(nTotGeral, 2) SIZE 300,10 OF oDlg PIXEL

    @198,5   BUTTON oBtnNova PROMPT "Nova consulta" SIZE 90,16 OF oDlg PIXEL ACTION (lNova := .T., oDlg:End())
    @198,110 BUTTON oBtnImp  PROMPT "Imprimir Browse" SIZE 90,16 OF oDlg PIXEL ACTION ZCCImpr(aResumo)

    ACTIVATE MSDIALOG oDlg CENTERED
Return lNova

/*/{Protheus.doc} ZCCFmtNum
Formata um numero no padrao brasileiro (1.234,56), com a quantidade de
decimais informada. Monta o texto a partir de Str(), sem depender da
mascara @E do ambiente.
@type Static Function
@param nValor, numeric, valor a formatar
@param nDec, numeric, quantidade de decimais (2 para valor, 4 para quantidade)
@return character, valor formatado
/*/
Static Function ZCCFmtNum(nValor, nDec)
    Local cTexto   := ""
    Local cInteiro := ""
    Local cDecimal := ""
    Local cSaida   := ""
    Local nPos     := 0
    Local nAbs     := 0

    If ValType(nValor) <> "N"
        nValor := 0
    EndIf

    If ValType(nDec) <> "N"
        nDec := 2
    EndIf

    nAbs := Round(Abs(nValor), nDec)

    // Str() sempre usa o ponto como separador decimal
    cTexto := AllTrim(Str(nAbs, 18, nDec))

    nPos := At(".", cTexto)
    If nPos > 0
        cInteiro := Left(cTexto, nPos - 1)
        cDecimal := SubStr(cTexto, nPos + 1)
    Else
        cInteiro := cTexto
        cDecimal := ""
    EndIf

    If Empty(cInteiro)
        cInteiro := "0"
    EndIf

    // Insere o ponto de milhar da direita para a esquerda
    cSaida := ""
    Do While Len(cInteiro) > 3
        cSaida   := "." + SubStr(cInteiro, Len(cInteiro) - 2, 3) + cSaida
        cInteiro := Left(cInteiro, Len(cInteiro) - 3)
    EndDo
    cSaida := cInteiro + cSaida

    If nDec > 0
        cSaida := cSaida + "," + cDecimal
    EndIf

    If nValor < 0
        cSaida := "-" + cSaida
    EndIf

Return cSaida

/*/{Protheus.doc} ZCCImpr
 Imprime a tela de resultado (resumo por classe de valor) via TReport, com opcao de PDF e planilha (Excel).
 @type Static Function
 @param aResumo, array, linhas do resumo {grupo, classe, descricao, valor}
 @return nil
 /*/
Static Function ZCCImpr(aResumo)
    Local aArea   := GetArea()
    Local oReport
    Local oSection

    If Len(aResumo) == 0
        MsgAlert("Nenhum gasto encontrado para imprimir.", "Atencao")
        RestArea(aArea)
        Return
    EndIf

    oReport := TReport():New("ZGASTOCC", "Gastos por Centro de Custo", "", ;
        {|oReport| ZCCImprRpt(oReport, aResumo)}, ;
        "Resumo de gastos por centro de custo - Filial: " + cFilAnt)

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    oSection := TRSection():New(oReport, "Resumo", {})

    TRCell():New(oSection, "GRUPO",   "", "Grupo",    "@!", 20)
    TRCell():New(oSection, "CLASSE",  "", "Classe",   "@!", 10)
    TRCell():New(oSection, "DESCR",   "", "Descricao", "@!", 60)
    TRCell():New(oSection, "VALOR",   "", "Valor",    "@E 9,999,999,999.99", 16)

    oReport:PrintDialog()

    RestArea(aArea)
Return

/*/{Protheus.doc} ZCCImprRpt
 Callback do TReport que imprime as linhas do resumo por classe.
 @type Static Function
 @param oReport, object, Objeto TReport
 @param aResumo, array, linhas do resumo {grupo, classe, descricao, valor}
 /*/
Static Function ZCCImprRpt(oReport, aResumo)
    Local oSection := oReport:Section(1)
    Local nI := 0

    oReport:SetMeter(0)
    oSection:Init()

    For nI := 1 To Len(aResumo)
        oSection:Cell("GRUPO"):SetValue(AllTrim(aResumo[nI][1]))
        oSection:Cell("CLASSE"):SetValue(AllTrim(aResumo[nI][2]))
        oSection:Cell("DESCR"):SetValue(AllTrim(aResumo[nI][3]))
        oSection:Cell("VALOR"):SetValue(aResumo[nI][4])

        oSection:PrintLine()
        oReport:IncMeter()
    Next nI

    oSection:Finish()
Return

/*/{Protheus.doc} ZCCAnoAnt
Mesma data no ano anterior (29/02 vira 28/02).
@type Static Function
@param dData, date, data de referencia
@return date, data um ano antes
/*/
Static Function ZCCAnoAnt(dData)
    Local nAno := Year(dData) - 1
    Local nMes := Month(dData)
    Local nDia := Day(dData)

    If nMes == 2 .And. nDia == 29
        nDia := 28
    EndIf
Return StoD(StrZero(nAno, 4) + StrZero(nMes, 2) + StrZero(nDia, 2))

/*/{Protheus.doc} ZCCPeriodoAnterior
Mesmo periodo do ano anterior.
@type Static Function
@param dDtDe, date, inicio do periodo atual
@param dDtAte, date, fim do periodo atual
@return array, {inicio anterior, fim anterior}
/*/
Static Function ZCCPeriodoAnterior(dDtDe, dDtAte)
Return {ZCCAnoAnt(dDtDe), ZCCAnoAnt(dDtAte)}

/*/{Protheus.doc} ZCCVariacao
Variacao percentual, sem dividir por zero.
@type Static Function
@param nAtual, numeric, valor atual
@param nAnt, numeric, valor anterior
@return character, texto da variacao
/*/
Static Function ZCCVariacao(nAtual, nAnt)
    Local nPerc := 0
    Local cSin  := ""

    If nAnt == 0
        Return "sem base de comparacao"
    EndIf

    nPerc := ((nAtual - nAnt) / nAnt) * 100
    If nPerc > 0
        cSin := "+"
    EndIf
Return cSin + ZCCFmtNum(nPerc, 1) + "%"

/*/{Protheus.doc} ZCCMonta
Consolida atual x anterior por classe (ordenado por valor, maior primeiro)
e por mes. Nao desenha nada.
@type Static Function
@param aMat, array, materiais do periodo atual
@param aSvc, array, servicos do periodo atual
@param aReq, array, requisicoes do periodo atual
@param aMatA, array, materiais do periodo anterior
@param aSvcA, array, servicos do periodo anterior
@param aReqA, array, requisicoes do periodo anterior
@return array, {aLinhas, aTotais, aMeses}
/*/
Static Function ZCCMonta(aMat, aSvc, aReq, aMatA, aSvcA, aReqA)
    Local aAtual  := {aMat, aSvc, aReq}
    Local aAnter  := {aMatA, aSvcA, aReqA}
    Local aNomes  := {"Materiais", "Servicos", "Requisitados"}
    Local aLinhas := {}
    Local aTot    := {{0, 0}, {0, 0}, {0, 0}}
    Local aMeses  := {}
    Local aCls    := {}
    Local aRA     := {}
    Local aRB     := {}
    Local nG      := 0
    Local nI      := 0
    Local nPos    := 0
    Local nAnt    := 0
    Local cMes    := ""

    For nG := 1 To 3
        aRA := ZCCResumo(aAtual[nG])
        aRB := ZCCResumo(aAnter[nG])
        aTot[nG][1] := aRA[2]
        aTot[nG][2] := aRB[2]
        aCls := {}

        For nI := 1 To Len(aRA[1])
            nPos := aScan(aRB[1], {|x| AllTrim(x[1]) == AllTrim(aRA[1][nI][1])})
            nAnt := Iif(nPos > 0, aRB[1][nPos][3], 0)
            aAdd(aCls, {aNomes[nG], aRA[1][nI][1], aRA[1][nI][2], aRA[1][nI][3], nAnt})
        Next nI

        // Classe que so existiu no periodo anterior
        For nI := 1 To Len(aRB[1])
            nPos := aScan(aRA[1], {|x| AllTrim(x[1]) == AllTrim(aRB[1][nI][1])})
            If nPos == 0
                aAdd(aCls, {aNomes[nG], aRB[1][nI][1], aRB[1][nI][2], 0, aRB[1][nI][3]})
            EndIf
        Next nI

        aSort(aCls,,, {|x, y| x[4] > y[4]})

        For nI := 1 To Len(aCls)
            aAdd(aLinhas, {aNomes[nG], Iif(Empty(AllTrim(aCls[nI][2])), "-", AllTrim(aCls[nI][2])), ;
                AllTrim(aCls[nI][3]), aCls[nI][4], aCls[nI][5], ZCCVariacao(aCls[nI][4], aCls[nI][5])})
        Next nI

        // Meses: colunas 2..4 = atual (mat, svc, req); 5..7 = anterior
        For nI := 1 To Len(aAtual[nG])
            cMes := Left(DtoS(aAtual[nG][nI][1]), 6)
            nPos := aScan(aMeses, {|x| x[1] == cMes})
            If nPos == 0
                aAdd(aMeses, {cMes, 0, 0, 0, 0, 0, 0})
                nPos := Len(aMeses)
            EndIf
            aMeses[nPos][1 + nG] += aAtual[nG][nI][6]
        Next nI

        // Mes do periodo anterior e deslocado 12 meses para casar com o atual
        For nI := 1 To Len(aAnter[nG])
            cMes := StrZero(Year(aAnter[nG][nI][1]) + 1, 4) + StrZero(Month(aAnter[nG][nI][1]), 2)
            nPos := aScan(aMeses, {|x| x[1] == cMes})
            If nPos == 0
                aAdd(aMeses, {cMes, 0, 0, 0, 0, 0, 0})
                nPos := Len(aMeses)
            EndIf
            aMeses[nPos][4 + nG] += aAnter[nG][nI][6]
        Next nI
    Next nG

    aSort(aMeses,,, {|x, y| x[1] < y[1]})
Return {aLinhas, aTot, aMeses}
