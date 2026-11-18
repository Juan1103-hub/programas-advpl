#Include "Totvs.ch"
#Include "TopConn.ch"

// Centro de custo do almoxarifado (as regras de usuarios abaixo dependem dele)
#Define ZCC_CC_LIBERA     "5010206"
// Centros de custo que a rotina aceita (aparecem na lista do campo Centro de Custo)
#Define ZCC_CC_LISTA      "'5010201','5010202','5010203','5010204','5010205','5010206','5010207','6010201','6010202','6010203','6010204','6010205','6010206','6010207','6010208','6010209','6010210','6010212','6010213','6010214','7010201','7010202','8010201','8010202','9010201','9010202'"
// Equipe do almoxarifado. Fora do 5010206, a baixa pedida (CP_SOLICIT) e lancada
// (D3_USUARIO) por estes usuarios e compra direta: o valor ja entrou no centro
// de custo na compra, entao sai das requisicoes para nao contar duas vezes.
// Baixa lancada por eles para outro solicitante e consumo de estoque e entra.
#Define ZCC_LOGINS_EXCL   "'JOSE.GUSTAVO','FRED.CAPUTO','GUSTAVO.ALMEIDA','JOAO.PEDRO'"
// No almoxarifado (5010206): baixas lancadas ou pedidas por estes usuarios nao entram
#Define ZCC_LOGINS_ALMOX  "'JUAN.ALMEIDA','PEDRO.OLIVEIRA'"

/*/{Protheus.doc} ZGASTOCC
Consulta de gastos por centro de custo.
Mostra, para um centro de custo e um periodo, o gasto dividido em tres
grupos: materiais comprados (itens de pedido de compra), servicos (itens
com codigo iniciado em SV) e materiais requisitados ao almoxarifado
(baixas de estoque). Cada grupo e totalizado por classe de valor; itens sem
classe aparecem em "Sem classe de valor". O periodo vai da data inicial ate
a data final informadas (a final sugerida e a data base do sistema) e e comparado
sempre com o mesmo periodo do ano anterior.
Tabelas: SC7 (itens de pedido de compra), SD3 (movimentacoes internas), SCP
(solicitacao ao armazem), SB1 (descricao e ultimo preco do produto), CTT
(centro de custo) e CTH (classe de valor).
Premissas: filial atual; registros nao excluidos; compras pela data de
emissao do pedido (C7_EMISSAO), com valor C7_TOTAL menos C7_VLDESC. Cada
linha do pedido e tratada sozinha: a linha com residuo eliminado
(C7_RESIDUO = 'S') conta so a parte ja recebida (C7_QUJE sobre C7_QUANT);
linhas rejeitadas ou bloqueadas (C7_CONAPRO 'R' ou 'B') ficam de fora.
Requisicoes pela baixa de almoxarifado D3_TM = '502', valorizadas pela
quantidade baixada vezes o ultimo preco de compra do produto (B1_UPRC);
produto sem B1_UPRC no cadastro vale zero.
Estornos ignorados. Fora do 5010206, a SC pedida por jose.gustavo,
fred.caputo, gustavo.almeida ou joao.pedro e compra direta (o valor ja
entrou na compra) e nao entra nas requisicoes, nao importa quem fez a
baixa; SC pedida por outro solicitante e consumo de estoque e entra. No
5010206 nao entram as baixas lancadas ou pedidas por juan.almeida e
pedro.oliveira.
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
    Local aCC      := ZCCListaCC()
    Local aItens   := {}
    Local aMat     := {}
    Local aSvc     := {}
    Local aReq     := {}
    Local aMatA    := {}
    Local aSvcA    := {}
    Local aReqA    := {}
    Local aPerAnt  := {}
    // Data inicial em branco (informada pelo usuario); final sugerida com a data base
    Local dDtDe    := CtoD("")
    Local dDtAte   := dDataBase
    Local dCmpDe   := CtoD("")
    Local dCmpAte  := CtoD("")
    Local cCodCC   := ""
    Local cDescCC  := ""
    Local xSel     := Nil
    Local nIdx     := 1
    Local nI       := 0
    Local lNova    := .T.

    If Len(aCC) == 0
        MsgAlert("Nenhum dos centros de custo liberados foi encontrado no cadastro da filial atual.", "Atencao")
        RestArea(aArea)
        Return
    EndIf

    // Texto curto na lista para o campo caber na janela
    For nI := 1 To Len(aCC)
        aAdd(aItens, aCC[nI][1] + " - " + Left(aCC[nI][2], 20))
    Next nI

    Do While lNova
        lNova := .F.

        // --- 1) Tela padrao de parametros do Protheus -----------------
        aPar := {}
        aAdd(aPar, {1, "Data De",  dDtDe,  "", "", "", "", 60, .T.})
        aAdd(aPar, {1, "Data Ate", dDtAte, "", "", "", "", 60, .T.})
        aAdd(aPar, {2, "Centro de Custo", nIdx, aItens, 110, "", .T.})

        If !ParamBox(aPar, "Gastos por Centro de Custo", @aRet)
            RestArea(aArea)
            Return
        EndIf

        dDtDe  := ZCCData(aRet[1])
        dDtAte := ZCCData(aRet[2])
        xSel   := aRet[3]

        // A lista pode devolver o numero da opcao ou o texto escolhido
        If ValType(xSel) == "N"
            nIdx := xSel
        Else
            nIdx := aScan(aItens, {|x| AllTrim(x) == AllTrim(xSel)})
        EndIf

        // --- 2) Validacoes --------------------------------------------
        // As duas datas vem do campo de data do ParamBox, que ja confere se
        // a data existe; ZCCData mantem a conversao do texto dia/mes/ano
        If Empty(dDtDe) .Or. Empty(dDtAte)
            MsgAlert("Informe a data inicial e a data final.", "Atencao")
            lNova := .T.
            Loop
        EndIf

        If dDtAte < dDtDe
            MsgAlert("A data inicial nao pode ser maior que a data final.", "Atencao")
            lNova := .T.
            Loop
        EndIf

        If nIdx < 1 .Or. nIdx > Len(aCC)
            nIdx := 1
            MsgAlert("Selecione o centro de custo.", "Atencao")
            lNova := .T.
            Loop
        EndIf

        cCodCC := aCC[nIdx][1]

        aChk := ZCCValCC(cCodCC)
        If !aChk[1]
            MsgAlert("Centro de custo " + AllTrim(cCodCC) + " nao encontrado no cadastro.", "Atencao")
            lNova := .T.
            Loop
        EndIf

        // Codigo usado nas consultas e descricao do cabecalho vem do cadastro
        cCodCC  := aChk[2]
        cDescCC := aChk[3]

        // Comparacao: sempre o mesmo periodo do ano anterior
        aPerAnt := ZCCPeriodoAnterior(dDtDe, dDtAte)
        dCmpDe  := aPerAnt[1]
        dCmpAte := aPerAnt[2]

        // --- 3) Carga dos tres grupos: periodo atual e comparacao -----
        ZCCCarrega(dDtDe, dDtAte, cCodCC, @aMat, @aSvc, @aReq)

        If Len(aMat) + Len(aSvc) + Len(aReq) == 0
            MsgAlert("Nenhum gasto encontrado para o centro de custo " + AllTrim(cCodCC) + ;
                " no periodo informado.", "Atencao")
            lNova := .T.
            Loop
        EndIf

        ZCCCarrega(dCmpDe, dCmpAte, cCodCC, @aMatA, @aSvcA, @aReqA)

        // --- 4) Tela de resultado -------------------------------------
        lNova := ZCCTela(dDtDe, dDtAte, dCmpDe, dCmpAte, cCodCC, cDescCC, ;
            aMat, aSvc, aReq, aMatA, aSvcA, aReqA)
    EndDo

    RestArea(aArea)
Return

/*/{Protheus.doc} ZCCData
Devolve a data informada no ParamBox. Quando o campo ja devolve data, usa o
valor direto; quando devolve texto, aceita com ou sem as barras.
@type Static Function
@param xData, date ou character, data do campo ou texto dia/mes/ano (ddmmaaaa)
@return date, data convertida ou data vazia quando o valor e invalido
/*/
Static Function ZCCData(xData)
    Local cNum  := ""
    Local dData := CtoD("")

    If ValType(xData) == "D"
        Return xData
    EndIf

    cNum := StrTran(StrTran(AllTrim(cValToChar(xData)), "/", ""), " ", "")

    If Len(cNum) == 8
        dData := StoD(SubStr(cNum, 1, 2) + "/" + SubStr(cNum, 3, 2) + "/" + SubStr(cNum, 5, 4))
        If DtoS(dData) != SubStr(cNum, 5, 4) + SubStr(cNum, 3, 2) + SubStr(cNum, 1, 2)
            dData := CtoD("")
        EndIf
    EndIf

Return dData

/*/{Protheus.doc} ZCCListaCC
Lista os centros de custo liberados (ZCC_CC_LISTA) que existem no cadastro
da filial atual, com codigo e descricao.
@type Static Function
@return array, {{codigo, descricao}}
/*/
Static Function ZCCListaCC()
    Local aArea  := GetArea()
    Local aRet   := {}
    Local cAlias := GetNextAlias()
    Local cQuery := ""

    cQuery := "SELECT CTT_CUSTO, CTT_DESC01 FROM " + RetSqlName("CTT") + " "
    cQuery += "WHERE D_E_L_E_T_ = ' ' AND CTT_FILIAL = '" + xFilial("CTT") + "' "
    cQuery += "AND RTRIM(CTT_CUSTO) IN (" + ZCC_CC_LISTA + ") "
    cQuery += "ORDER BY CTT_CUSTO"
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)
    While !(cAlias)->(Eof())
        aAdd(aRet, {AllTrim((cAlias)->CTT_CUSTO), AllTrim((cAlias)->CTT_DESC01)})
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    RestArea(aArea)
Return aRet

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
Grupo 1 e 2 saem dos itens de pedido de compra (SC7), pela data de emissao,
separados pelo prefixo SV do codigo do produto; grupo 3 sai das baixas de
almoxarifado (SD3, D3_TM = '502'), valorizadas pelo ultimo preco de compra
(B1_UPRC) e ligadas a solicitacao ao armazem (SCP) para identificar o
solicitante.
Cada item de materiais e servicos tem nove posicoes: data de emissao,
documento, codigo, descricao, quantidade, valor, classe de valor, descricao
da classe e SC de origem do pedido (vazia na compra direta). Requisitados
tem dez: as oito primeiras iguais, numero da solicitacao ao armazem na nona e
quantidade atendida na decima.
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
    Local cSC     := ""
    Local cNumSC  := ""
    Local cSelCls := ""
    Local cJoin   := ""
    Local lC7Clvl := .F.
    Local lD3Clvl := .F.
    Local lC7Desc := .F.
    Local cLiq    := ""
    Local cValor  := ""
    Local nQtde   := 0
    Local nQtat   := 0
    Local nValor  := 0

    aMat := {}
    aSvc := {}
    aReq := {}

    // --- 1) Compras: itens de pedido de compra (SC7) ------------------
    // Classe de valor vem do proprio pedido (C7_CLVL), quando existir
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

    // Valor liquido da linha = total do item menos o desconto (C7_VLDESC)
    lC7Desc := ZCCColuna("SC7", "C7_VLDESC")
    If lC7Desc
        cLiq := "(ISNULL(C7.C7_TOTAL,0) - ISNULL(C7.C7_VLDESC,0))"
    Else
        cLiq := "ISNULL(C7.C7_TOTAL,0)"
    EndIf

    // Linha com residuo eliminado conta so a parte ja recebida (C7_QUJE);
    // as outras linhas do mesmo pedido nao sao afetadas
    cValor := "(CASE WHEN ISNULL(C7.C7_RESIDUO,'') = 'S' THEN "
    cValor += "(CASE WHEN ISNULL(C7.C7_QUANT,0) > 0 THEN " + cLiq + " * ISNULL(C7.C7_QUJE,0) / C7.C7_QUANT ELSE 0 END) "
    cValor += "ELSE " + cLiq + " END)"

    cQuery := "SELECT C7.C7_NUM AS DOC, C7.C7_EMISSAO AS DT, "
    // Quantidade exibida e a mesma que o valor representa: no item com residuo,
    // so a parte ja recebida (C7_QUJE)
    cQuery += "C7.C7_PRODUTO AS COD, "
    cQuery += "(CASE WHEN ISNULL(C7.C7_RESIDUO,'') = 'S' THEN ISNULL(C7.C7_QUJE,0) "
    cQuery += "ELSE ISNULL(C7.C7_QUANT,0) END) AS QTDE, "
    cQuery += cValor + " AS VALOR, "
    cQuery += "B1.B1_DESC AS DESCR, " + cSelCls
    cQuery += ", ISNULL(C7.C7_NUMSC,'') AS NUMSC "
    cQuery += "FROM " + RetSqlName("SC7") + " C7 "
    cQuery += "LEFT JOIN " + RetSqlName("SB1") + " B1 "
    cQuery += "ON (B1.B1_FILIAL = '" + xFilial("SB1") + "' OR B1.B1_FILIAL = '') "
    cQuery += "AND B1.B1_COD = C7.C7_PRODUTO AND B1.D_E_L_E_T_ = ' ' "
    cQuery += cJoin
    cQuery += "WHERE C7.D_E_L_E_T_ = ' ' AND C7.C7_FILIAL = '" + xFilial("SC7") + "' "
    cQuery += "AND C7.C7_CC = '" + cCodCC + "' "
    cQuery += "AND C7.C7_QUANT > 0 "
    cQuery += "AND (ISNULL(C7.C7_RESIDUO,'') <> 'S' OR ISNULL(C7.C7_QUJE,0) > 0) "
    cQuery += "AND ISNULL(C7.C7_CONAPRO, '') NOT IN ('R','B') "
    cQuery += "AND C7.C7_EMISSAO BETWEEN '" + cDe + "' AND '" + cAte + "' "
    cQuery += "ORDER BY C7.C7_EMISSAO, C7.C7_NUM, C7.C7_ITEM, C7.C7_SEQUEN"

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
        cNumSC  := ""

        If ValType((cAlias)->NUMSC) == "C"
            cNumSC := AllTrim((cAlias)->NUMSC)
        EndIf

        If ValType((cAlias)->CLVL) == "C"
            cClasse := AllTrim((cAlias)->CLVL)
        EndIf

        If ValType((cAlias)->CLSDES) == "C"
            cClsDes := AllTrim((cAlias)->CLSDES)
        EndIf

        // Servico e o item cujo codigo comeca com SV (regra do pedido).
        // O 9o elemento e a SC de origem do pedido (vazia na compra direta)
        If SubStr(Upper(cCod), 1, 2) == "SV"
            aAdd(aSvc, {StoD(AllTrim((cAlias)->DT)), cDoc, cCod, cDescr, nQtde, nValor, cClasse, cClsDes, cNumSC})
        Else
            aAdd(aMat, {StoD(AllTrim((cAlias)->DT)), cDoc, cCod, cDescr, nQtde, nValor, cClasse, cClsDes, cNumSC})
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
    // Valor = quantidade baixada x ultimo preco de compra (B1_UPRC).
    // Produto sem B1_UPRC no cadastro vale zero.
    cQuery += "ISNULL(D3.D3_QUANT,0) AS QTDE, "
    cQuery += "ISNULL(D3.D3_QUANT,0) * ISNULL(B1.B1_UPRC,0) AS VALOR, "
    cQuery += "B1.B1_DESC AS DESCR, " + cSelCls
    cQuery += ", ISNULL(CP.CP_NUM,'') AS NUMSA, ISNULL(CP.CP_QUJE,0) AS QTAT "
    cQuery += "FROM " + RetSqlName("SD3") + " D3 "
    cQuery += "LEFT JOIN " + RetSqlName("SB1") + " B1 "
    cQuery += "ON (B1.B1_FILIAL = '" + xFilial("SB1") + "' OR B1.B1_FILIAL = '') "
    cQuery += "AND B1.B1_COD = D3.D3_COD AND B1.D_E_L_E_T_ = ' ' "
    cQuery += cJoin
    cQuery += "LEFT JOIN " + RetSqlName("SCP") + " CP "
    cQuery += "ON CP.CP_FILIAL = D3.D3_FILIAL AND CP.CP_NUM = D3.D3_NUMSA "
    cQuery += "AND CP.CP_ITEM = D3.D3_ITEMSA AND CP.D_E_L_E_T_ = ' ' "
    cQuery += "WHERE D3.D_E_L_E_T_ = ' ' AND D3.D3_FILIAL = '" + xFilial("SD3") + "' "
    cQuery += "AND D3.D3_CC = '" + cCodCC + "' "
    cQuery += "AND D3.D3_TM = '502' "
    If AllTrim(cCodCC) == ZCC_CC_LIBERA
        // Almoxarifado: baixas lancadas ou pedidas por estes usuarios nao entram
        cQuery += "AND UPPER(RTRIM(D3.D3_USUARIO)) NOT IN (" + ZCC_LOGINS_ALMOX + ") "
        cQuery += "AND UPPER(RTRIM(ISNULL(CP.CP_SOLICIT,''))) NOT IN (" + ZCC_LOGINS_ALMOX + ") "
    Else
        // Demais centros de custo: quem decide e o solicitante da SC. SC pedida
        // pela equipe e compra direta (ja contada na compra) e nao entra, mesmo
        // que a baixa tenha sido lancada por outra pessoa
        cQuery += "AND UPPER(RTRIM(ISNULL(CP.CP_SOLICIT,''))) NOT IN (" + ZCC_LOGINS_EXCL + ") "
    EndIf
    cQuery += "AND ISNULL(D3.D3_ESTORNO, '') <> 'S' "
    cQuery += "AND D3.D3_QUANT > 0 "
    cQuery += "AND D3.D3_EMISSAO BETWEEN '" + cDe + "' AND '" + cAte + "' "
    cQuery += "ORDER BY D3.D3_EMISSAO, D3.D3_DOC, D3.D3_COD"

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)
    TCSetField(cAlias, "QTDE",  "N", 16, 4)
    TCSetField(cAlias, "VALOR", "N", 16, 2)
    TCSetField(cAlias, "QTAT",  "N", 16, 4)

    While !(cAlias)->(Eof())
        cCod    := AllTrim((cAlias)->COD)
        cDescr  := AllTrim((cAlias)->DESCR)
        cClasse := ""
        cClsDes := ""
        cDoc    := AllTrim((cAlias)->DOC)
        cSC     := AllTrim((cAlias)->NUMSA)
        nQtde   := (cAlias)->QTDE
        nQtat   := (cAlias)->QTAT
        nValor  := (cAlias)->VALOR

        If ValType((cAlias)->CLVL) == "C"
            cClasse := AllTrim((cAlias)->CLVL)
        EndIf

        If ValType((cAlias)->CLSDES) == "C"
            cClsDes := AllTrim((cAlias)->CLSDES)
        EndIf

        aAdd(aReq, {StoD(AllTrim((cAlias)->DT)), cDoc, cCod, cDescr, nQtde, nValor, cClasse, cClsDes, cSC, nQtat})

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    RestArea(aArea)
Return

/*/{Protheus.doc} ZCCResumo
Agrupa as linhas de um grupo por classe de valor e devolve o total do
grupo. A classe vazia vira "Sem classe de valor". A ordem final por
valor e feita em ZCCMonta.
@type Static Function
@param aDados, array, linhas do grupo {data, documento, codigo, descricao, quantidade, valor, classe, descricao da classe}; requisitados trazem tambem numero da solicitacao ao armazem e quantidade atendida
@return array, {resumo por classe, total do grupo}
/*/
Static Function ZCCResumo(aDados)
    Local aResumo := {}
    Local aRet    := {}
    Local nTotal  := 0
    Local nPos    := 0
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

    aRet := {aResumo, nTotal}
Return aRet

/*/{Protheus.doc} ZCCConta
Conta quantos valores distintos e nao vazios existem numa posicao do array de
itens. Serve para o rodape informar quantos documentos diferentes a lista tem
(pedido de compra, SC de compra ou solicitacao ao armazem).
@type Static Function
@param aDados, array, itens carregados por ZCCCarrega
@param nPos, numeric, posicao do documento no item
@return numeric, quantidade de valores distintos nao vazios
/*/
Static Function ZCCConta(aDados, nPos)
    Local aVistos := {}
    Local nI      := 0
    Local cValor  := ""

    For nI := 1 To Len(aDados)
        cValor := AllTrim(cValToChar(aDados[nI][nPos]))
        If !Empty(cValor)
            If aScan(aVistos, {|x| x == cValor}) == 0
                aAdd(aVistos, cValor)
            EndIf
        EndIf
    Next nI
Return Len(aVistos)

/*/{Protheus.doc} ZCCContaCompras
Conta quantos documentos distintos e nao vazios existem numa posicao dos itens
de materiais e de servicos. Serve para o rodape do total geral informar quantos
pedidos de compra e quantas SCs de compra diferentes a lista tem, sem contar
os requisitados (que nao tem pedido nem SC de compra).
@type Static Function
@param aMat, array, itens de materiais comprados
@param aSvc, array, itens de servicos
@param nPos, numeric, posicao do documento no item
@return numeric, quantidade de valores distintos nao vazios
/*/
Static Function ZCCContaCompras(aMat, aSvc, nPos)
    Local aVistos := {}
    Local aFontes := {aMat, aSvc}
    Local nJ      := 0
    Local nI      := 0
    Local cValor  := ""

    For nJ := 1 To Len(aFontes)
        For nI := 1 To Len(aFontes[nJ])
            cValor := AllTrim(cValToChar(aFontes[nJ][nI][nPos]))
            If !Empty(cValor)
                If aScan(aVistos, {|x| x == cValor}) == 0
                    aAdd(aVistos, cValor)
                EndIf
            EndIf
        Next nI
    Next nJ
Return Len(aVistos)

/*/{Protheus.doc} ZCCTela
Tela de resultado: cabecalho com centro de custo e periodos; lista de 6
colunas (grupo, classe, descricao, valor, ano anterior, variacao) sempre
comparando o periodo atual com o mesmo periodo do ano anterior; e, abaixo,
uma tabela de totais (materiais, servicos, requisitados e total geral).
Ao abrir, a tabela mostra so o periodo atual. Comparativo Anual traz ao lado
o mesmo periodo do ano anterior, com diferenca e variacao; Comparativo
Mensal compara o mes final do periodo com o mes anterior. Duplo clique numa
linha do resumo abre os itens daquela classe de valor nos dois periodos (o
atual em cima e o mesmo periodo do ano anterior embaixo); duplo clique numa
linha da tabela de totais abre a lista de itens do grupo (materiais e
servicos com data de emissao e numero do pedido, codigo, descricao,
quantidade, classe de valor e valor total; requisitados com data de emissao,
numero da solicitacao ao armazem, codigo, descricao, quantidade atendida e
valor total), e a linha do total geral abre os tres grupos numa lista unica
com a coluna Tipo. Nas listas, o rodape traz a quantidade de itens, de
pedidos de compra distintos e de SCs de compra distintas (nos requisitados,
de solicitacoes ao armazem), e o botao Imprimir Browse gera o PDF ou a
planilha. O botao
Nova consulta devolve .T. para voltar a tela de parametros.
@type Static Function
@param dDtDe, date, inicio do periodo atual
@param dDtAte, date, fim do periodo atual
@param dCmpDe, date, inicio do periodo de comparacao
@param dCmpAte, date, fim do periodo de comparacao
@param cCodCC, character, codigo do centro de custo
@param cDescCC, character, descricao do centro de custo
@param aMat, array, materiais comprados (atual)
@param aSvc, array, servicos (atual)
@param aReq, array, requisitados (atual)
@param aMatA, array, materiais comprados (comparacao)
@param aSvcA, array, servicos (comparacao)
@param aReqA, array, requisitados (comparacao)
@return logical, .T. quando o usuario pediu nova consulta
/*/
Static Function ZCCTela(dDtDe, dDtAte, dCmpDe, dCmpAte, cCodCC, cDescCC, aMat, aSvc, aReq, aMatA, aSvcA, aReqA)
    Local oDlg      := Nil
    Local oLRes     := Nil
    Local oLTot     := Nil
    Local oSayTot   := Nil
    Local oBtnNova  := Nil
    Local oBtnAnu   := Nil
    Local oBtnMen   := Nil
    Local oBtnImp   := Nil
    Local aMonta    := {}
    Local aResumo   := {}
    Local aTot      := {}
    Local aMeses    := {}
    Local nOff      := 0
    Local nTotGeral := 0
    Local cPer      := ""
    Local lNova     := .F.

    // Meses entre o inicio do periodo atual e o inicio da comparacao
    nOff := ((Year(dDtDe) * 12) + Month(dDtDe)) - ((Year(dCmpDe) * 12) + Month(dCmpDe))

    aMonta  := ZCCMonta(aMat, aSvc, aReq, aMatA, aSvcA, aReqA, nOff)
    aResumo := aMonta[1]
    aTot    := aMonta[2]
    aMeses  := aMonta[3]

    nTotGeral := aTot[1][1] + aTot[2][1] + aTot[3][1]

    cPer := "Periodo: " + DtoC(dDtDe) + " a " + DtoC(dDtAte) + ;
        "   Ano anterior: " + DtoC(dCmpDe) + " a " + DtoC(dCmpAte)

    DEFINE MSDIALOG oDlg TITLE "Gastos por Centro de Custo" FROM 0,0 TO 550,1300 PIXEL

    @5,5   SAY "Centro de custo: " + AllTrim(cCodCC) + " - " + AllTrim(cDescCC) SIZE 400,10 OF oDlg PIXEL
    @5,420 SAY "Total geral: R$ " + ZCCFmtNum(nTotGeral, 2) SIZE 210,10 OF oDlg PIXEL
    @16,5  SAY cPer SIZE 600,10 OF oDlg PIXEL
    @30,5  SAY "Resumo por classe de valor (periodo atual contra o mesmo periodo do ano anterior)" SIZE 500,10 OF oDlg PIXEL

    @44,5 LISTBOX oLRes FIELDS HEADER "Grupo", "Classe", "Descricao", "Valor", "Ano anterior", "Variacao %" ;
        SIZE 640,120 OF oDlg PIXEL
    oLRes:aColSizes := {80, 50, 240, 90, 90, 90}
    oLRes:SetArray(aResumo)
    oLRes:bLine := {|| {;
        SubStr(aResumo[oLRes:nAt][1], 1, 20), ;
        AllTrim(aResumo[oLRes:nAt][2]), ;
        SubStr(aResumo[oLRes:nAt][3], 1, 40), ;
        ZCCFmtNum(aResumo[oLRes:nAt][4], 2), ;
        ZCCFmtNum(aResumo[oLRes:nAt][5], 2), ;
        aResumo[oLRes:nAt][6]}}
    // Duplo clique na linha do resumo abre os itens daquela classe de valor no
    // periodo atual e no mesmo periodo do ano anterior
    oLRes:bLDblClick := {|| ZCCDetCls(aResumo[oLRes:nAt][1], aResumo[oLRes:nAt][2], ;
        aResumo[oLRes:nAt][3], {aMat, aSvc, aReq}, {aMatA, aSvcA, aReqA}, ;
        cCodCC, cDescCC, dDtDe, dDtAte, dCmpDe, dCmpAte)}

    // Tabela de totais: titulo dinamico e 4 linhas
    @172,5 SAY oSayTot PROMPT " " SIZE 635,10 OF oDlg PIXEL
    @184,5 LISTBOX oLTot FIELDS HEADER "Totais", "Atual", "Comparado", "Diferenca", "Variacao %" ;
        SIZE 640,60 OF oDlg PIXEL
    oLTot:aColSizes := {220, 100, 100, 100, 110}
    ZCCTotAtualiza(oSayTot, oLTot, ZCCTotBase(dDtDe, dDtAte, aTot))
    // Duplo clique na linha abre a lista de itens do grupo (1 materiais,
    // 2 servicos, 3 requisitados) e a linha 4 abre a lista do total geral
    oLTot:bLDblClick := {|| ZCCDetAbre(oLTot:nAt, aMat, aSvc, aReq, cCodCC, cDescCC, dDtDe, dDtAte)}

    @252,5   BUTTON oBtnNova PROMPT "Nova consulta" SIZE 90,16 OF oDlg PIXEL ACTION (lNova := .T., oDlg:End())
    @252,110 BUTTON oBtnAnu  PROMPT "Comparativo Anual" SIZE 90,16 OF oDlg PIXEL ;
        ACTION ZCCTotAtualiza(oSayTot, oLTot, ZCCTotAnual(dDtDe, dDtAte, dCmpDe, dCmpAte, aTot))
    @252,215 BUTTON oBtnMen  PROMPT "Comparativo Mensal" SIZE 90,16 OF oDlg PIXEL ;
        ACTION ZCCTotAtualiza(oSayTot, oLTot, ZCCTotMensal(dDtAte, aMeses))
    @252,320 BUTTON oBtnImp  PROMPT "Imprimir Browse" SIZE 90,16 OF oDlg PIXEL ACTION ZCCImpr(aResumo, aTot, cPer)

    ACTIVATE MSDIALOG oDlg CENTERED
Return lNova

/*/{Protheus.doc} ZCCDetalhe
Abre a lista de itens de um grupo da tabela de totais. Materiais comprados e
servicos mostram data de emissao do pedido, numero do pedido, codigo,
descricao, quantidade, classe de valor e valor total; requisitados ao
almoxarifado mostram data de emissao, numero da solicitacao ao armazem,
codigo, descricao, quantidade atendida e valor total. A lista sai sempre da
data de emissao mais antiga para a mais nova, com empate resolvido pelo
documento. O rodape traz a quantidade de itens, de pedidos de compra distintos
(menos em requisitados, que nao tem pedido) e de SCs de compra distintas (nos
requisitados, de solicitacoes ao armazem), alem do valor total. O botao
Imprimir Browse gera a mesma lista em PDF ou planilha.
@type Static Function
@param nGrupo, numeric, linha da tabela de totais (1 materiais, 2 servicos, 3 requisitados)
@param aMat, array, itens de materiais comprados
@param aSvc, array, itens de servicos
@param aReq, array, itens requisitados ao almoxarifado
@param cCodCC, character, codigo do centro de custo
@param cDescCC, character, descricao do centro de custo
@param dDtDe, date, inicio do periodo
@param dDtAte, date, fim do periodo
@return nil
/*/
Static Function ZCCDetalhe(nGrupo, aMat, aSvc, aReq, cCodCC, cDescCC, dDtDe, dDtAte)
    Local oDlg    := Nil
    Local oLst    := Nil
    Local oBtnImp := Nil
    Local aDados  := {}
    Local aItens  := {}
    Local aCabec  := {}
    Local aLarg   := {}
    Local nTotal  := 0
    Local nI      := 0
    Local nPosDoc := 2
    Local cTit    := ""
    Local cSub    := ""
    Local cRodape := ""

    If nGrupo < 1 .Or. nGrupo > 3
        Return
    EndIf

    If nGrupo == 1
        aDados := aClone(aMat)
        cTit   := "Materiais comprados"
    ElseIf nGrupo == 2
        aDados := aClone(aSvc)
        cTit   := "Servicos"
    Else
        aDados := aClone(aReq)
        cTit   := "Requisitados ao almoxarifado"
    EndIf

    // Lista sempre da data de emissao mais antiga para a mais nova; quando duas
    // linhas tem a mesma data, o desempate e pelo documento exibido na lista
    If nGrupo == 3
        nPosDoc := 9
    EndIf
    aSort(aDados,,, {|x, y| DtoS(x[1]) + x[nPosDoc] < DtoS(y[1]) + y[nPosDoc]})

    cSub := "Centro de custo: " + AllTrim(cCodCC) + " - " + AllTrim(cDescCC) + ;
        "   Periodo: " + DtoC(dDtDe) + " a " + DtoC(dDtAte)

    If nGrupo == 3
        // Requisitados: data da baixa, numero da solicitacao ao armazem,
        // produto, quantidade atendida e valor total
        aCabec := {"Emissao", "Solicitacao", "Codigo", "Descricao", "Qtde atendida", "Valor total"}
        aLarg  := {12, 12, 15, 45, 15, 16}
        For nI := 1 To Len(aDados)
            nTotal += aDados[nI][6]
            aAdd(aItens, {DtoC(aDados[nI][1]), AllTrim(aDados[nI][9]), ;
                AllTrim(aDados[nI][3]), AllTrim(aDados[nI][4]), ;
                ZCCFmtNum(aDados[nI][10], 4), ZCCFmtNum(aDados[nI][6], 2)})
        Next nI
    Else
        // Materiais e servicos: emissao e numero do pedido, produto, quantidade,
        // classe de valor e valor total
        aCabec := {"Emissao", "Pedido", "Codigo", "Descricao", "Quantidade", ;
            "Classe", "Classe de valor", "Valor total"}
        aLarg  := {12, 12, 15, 35, 12, 8, 25, 16}
        For nI := 1 To Len(aDados)
            nTotal += aDados[nI][6]
            aAdd(aItens, {DtoC(aDados[nI][1]), AllTrim(aDados[nI][2]), ;
                AllTrim(aDados[nI][3]), AllTrim(aDados[nI][4]), ;
                ZCCFmtNum(aDados[nI][5], 4), AllTrim(aDados[nI][7]), ;
                ZCCDesCls(aDados[nI][7], aDados[nI][8]), ZCCFmtNum(aDados[nI][6], 2)})
        Next nI
    EndIf

    If Len(aItens) == 0
        MsgAlert("Nenhum item encontrado para este grupo no periodo.", "Atencao")
        Return
    EndIf

    cRodape := "Itens: " + cValToChar(Len(aItens))
    If nGrupo == 3
        cRodape += "   Solicitacoes: " + cValToChar(ZCCConta(aDados, 9))
    Else
        cRodape += "   Pedidos: " + cValToChar(ZCCConta(aDados, 2))
        cRodape += "   SCs: " + cValToChar(ZCCConta(aDados, 9))
    EndIf
    cRodape += "   Valor total: R$ " + ZCCFmtNum(nTotal, 2)

    If nGrupo == 3
        DEFINE MSDIALOG oDlg TITLE cTit FROM 0,0 TO 500,1250 PIXEL
        @5,5 SAY cSub SIZE 590,10 OF oDlg PIXEL
        @20,5 LISTBOX oLst FIELDS HEADER "Emissao", "Solicitacao", "Codigo", "Descricao", ;
            "Qtde atendida", "Valor total" ;
            SIZE 590,180 OF oDlg PIXEL
        oLst:aColSizes := {65, 75, 60, 165, 90, 90}
        oLst:SetArray(aItens)
        oLst:bLine := {|| aItens[oLst:nAt]}
        @205,5 SAY cRodape SIZE 590,10 OF oDlg PIXEL
        @220,520 BUTTON oBtnImp PROMPT "Imprimir Browse" SIZE 90,16 OF oDlg PIXEL ;
            ACTION ZCCImpLis(cTit, cSub, aCabec, aLarg, aItens, cRodape)
        ACTIVATE MSDIALOG oDlg CENTERED
    Else
        DEFINE MSDIALOG oDlg TITLE cTit FROM 0,0 TO 500,1250 PIXEL
        @5,5 SAY cSub SIZE 565,10 OF oDlg PIXEL
        @20,5 LISTBOX oLst FIELDS HEADER "Emissao", "Pedido", "Codigo", "Descricao", ;
            "Quantidade", "Classe", "Classe de valor", "Valor total" ;
            SIZE 565,180 OF oDlg PIXEL
        oLst:aColSizes := {55, 60, 60, 110, 45, 35, 85, 75}
        oLst:SetArray(aItens)
        oLst:bLine := {|| aItens[oLst:nAt]}
        @205,5 SAY cRodape SIZE 565,10 OF oDlg PIXEL
        @220,520 BUTTON oBtnImp PROMPT "Imprimir Browse" SIZE 90,16 OF oDlg PIXEL ;
            ACTION ZCCImpLis(cTit, cSub, aCabec, aLarg, aItens, cRodape)
        ACTIVATE MSDIALOG oDlg CENTERED
    EndIf
Return

/*/{Protheus.doc} ZCCDetAbre
Decide qual lista abrir no duplo clique da tabela de totais: as linhas 1 a 3
abrem o grupo correspondente (materiais, servicos ou requisitados) e a linha
4, do total geral, abre os tres grupos juntos.
@type Static Function
@param nLinha, numeric, linha clicada na tabela de totais (1 a 4)
@param aMat, array, itens de materiais comprados
@param aSvc, array, itens de servicos
@param aReq, array, itens requisitados ao almoxarifado
@param cCodCC, character, codigo do centro de custo
@param cDescCC, character, descricao do centro de custo
@param dDtDe, date, inicio do periodo
@param dDtAte, date, fim do periodo
@return nil
/*/
Static Function ZCCDetAbre(nLinha, aMat, aSvc, aReq, cCodCC, cDescCC, dDtDe, dDtAte)
    If nLinha == 4
        ZCCDetGeral(aMat, aSvc, aReq, cCodCC, cDescCC, dDtDe, dDtAte)
    Else
        ZCCDetalhe(nLinha, aMat, aSvc, aReq, cCodCC, cDescCC, dDtDe, dDtAte)
    EndIf
Return

/*/{Protheus.doc} ZCCDetGeral
Abre a lista do total geral: materiais comprados, servicos e requisitados ao
almoxarifado numa lista unica, com a coluna Tipo. Materiais e servicos
mostram data de emissao, numero do pedido, codigo, descricao, quantidade,
classe de valor e valor total; requisitados mostram data de emissao, numero
da solicitacao ao armazem, codigo, descricao, quantidade atendida e valor
total. A lista sai da data de emissao mais antiga para a mais nova, com
empate resolvido pelo documento. O rodape traz a quantidade de itens, de
pedidos de compra distintos, de SCs de compra distintas e o valor total. O
botao Imprimir Browse gera a mesma lista em PDF ou planilha.
@type Static Function
@param aMat, array, itens de materiais comprados
@param aSvc, array, itens de servicos
@param aReq, array, itens requisitados ao almoxarifado
@param cCodCC, character, codigo do centro de custo
@param cDescCC, character, descricao do centro de custo
@param dDtDe, date, inicio do periodo
@param dDtAte, date, fim do periodo
@return nil
/*/
Static Function ZCCDetGeral(aMat, aSvc, aReq, cCodCC, cDescCC, dDtDe, dDtAte)
    Local oDlg    := Nil
    Local oLst    := Nil
    Local oBtnImp := Nil
    Local aDados  := {}
    Local aItens  := {}
    Local aCabec  := {}
    Local aLarg   := {}
    Local nTotal  := 0
    Local nPed    := 0
    Local nSc     := 0
    Local nI      := 0
    Local cTit    := "Total geral"
    Local cSub    := ""
    Local cRodape := ""

    // Lista unica: data, tipo, documento, codigo, descricao, quantidade,
    // classe de valor, descricao da classe e valor
    For nI := 1 To Len(aMat)
        aAdd(aDados, {aMat[nI][1], "Material", aMat[nI][2], aMat[nI][3], ;
            aMat[nI][4], aMat[nI][5], aMat[nI][7], aMat[nI][8], aMat[nI][6]})
    Next nI

    For nI := 1 To Len(aSvc)
        aAdd(aDados, {aSvc[nI][1], "Servico", aSvc[nI][2], aSvc[nI][3], ;
            aSvc[nI][4], aSvc[nI][5], aSvc[nI][7], aSvc[nI][8], aSvc[nI][6]})
    Next nI

    For nI := 1 To Len(aReq)
        aAdd(aDados, {aReq[nI][1], "Requisitado", aReq[nI][9], aReq[nI][3], ;
            aReq[nI][4], aReq[nI][10], aReq[nI][7], aReq[nI][8], aReq[nI][6]})
    Next nI

    If Len(aDados) == 0
        MsgAlert("Nenhum item encontrado no periodo.", "Atencao")
        Return
    EndIf

    // Data de emissao mais antiga primeiro; empate pelo documento exibido
    aSort(aDados,,, {|x, y| DtoS(x[1]) + x[3] < DtoS(y[1]) + y[3]})

    For nI := 1 To Len(aDados)
        nTotal += aDados[nI][9]
        aAdd(aItens, {DtoC(aDados[nI][1]), aDados[nI][2], AllTrim(aDados[nI][3]), ;
            AllTrim(aDados[nI][4]), AllTrim(aDados[nI][5]), ZCCFmtNum(aDados[nI][6], 4), ;
            ZCCDesCls(aDados[nI][7], aDados[nI][8]), ZCCFmtNum(aDados[nI][9], 2)})
    Next nI

    cSub := "Centro de custo: " + AllTrim(cCodCC) + " - " + AllTrim(cDescCC) + ;
        "   Periodo: " + DtoC(dDtDe) + " a " + DtoC(dDtAte)
    nPed := ZCCContaCompras(aMat, aSvc, 2)
    nSc  := ZCCContaCompras(aMat, aSvc, 9)
    cRodape := "Itens: " + cValToChar(Len(aItens))
    cRodape += "   Pedidos: " + cValToChar(nPed)
    cRodape += "   SCs: " + cValToChar(nSc)
    cRodape += "   Valor total: R$ " + ZCCFmtNum(nTotal, 2)

    aCabec := {"Emissao", "Tipo", "Documento", "Codigo", "Descricao", ;
        "Quantidade", "Classe de valor", "Valor total"}
    aLarg  := {12, 12, 12, 15, 40, 12, 25, 16}

    DEFINE MSDIALOG oDlg TITLE cTit FROM 0,0 TO 500,1300 PIXEL
    @5,5 SAY cSub SIZE 640,10 OF oDlg PIXEL
    @20,5 LISTBOX oLst FIELDS HEADER "Emissao", "Tipo", "Documento", "Codigo", "Descricao", ;
        "Quantidade", "Classe de valor", "Valor total" ;
        SIZE 640,180 OF oDlg PIXEL
    oLst:aColSizes := {55, 55, 60, 65, 135, 55, 95, 75}
    oLst:SetArray(aItens)
    oLst:bLine := {|| aItens[oLst:nAt]}
    @205,5 SAY cRodape SIZE 640,10 OF oDlg PIXEL
    @220,520 BUTTON oBtnImp PROMPT "Imprimir Browse" SIZE 90,16 OF oDlg PIXEL ;
        ACTION ZCCImpLis(cTit, cSub, aCabec, aLarg, aItens, cRodape)
    ACTIVATE MSDIALOG oDlg CENTERED
Return

/*/{Protheus.doc} ZCCImpLis
Imprime uma lista de itens em PDF ou planilha. Serve as listas de detalhe
(grupo, classe e requisitados): recebe os titulos das colunas, as larguras,
as linhas ja formatadas e o texto de fechamento.
@type Static Function
@param cTit, character, titulo do relatorio
@param cSub, character, subtitulo (centro de custo e periodo)
@param aCabec, array, titulos das colunas
@param aLarg, array, largura de cada coluna em caracteres
@param aItens, array, linhas ja formatadas
@param cRodape, character, texto do fechamento
@return nil
/*/
Static Function ZCCImpLis(cTit, cSub, aCabec, aLarg, aItens, cRodape)
    Local oReport
    Local oSection
    Local nI      := 0

    oReport := TReport():New("ZGASTOCC", cTit, "", ;
        {|oReport| ZCCDetRpt(oReport, aItens, cRodape)}, ;
        cSub)

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    oSection := TRSection():New(oReport, cTit, {})

    For nI := 1 To Len(aCabec)
        TRCell():New(oSection, "C" + cValToChar(nI), "", aCabec[nI], "@!", aLarg[nI])
    Next nI

    oReport:PrintDialog()
Return

/*/{Protheus.doc} ZCCDetRpt
Callback do TReport das listas de detalhe: imprime as linhas e escreve o
fechamento em texto corrido, abaixo delas.
@type Static Function
@param oReport, object, objeto TReport
@param aItens, array, linhas ja formatadas
@param cRodape, character, texto do fechamento
/*/
Static Function ZCCDetRpt(oReport, aItens, cRodape)
    Local oSection := oReport:Section(1)
    Local nI       := 0
    Local nJ       := 0

    oReport:SetMeter(0)
    oSection:Init()

    For nI := 1 To Len(aItens)
        For nJ := 1 To Len(aItens[nI])
            oSection:Cell("C" + cValToChar(nJ)):SetValue(aItens[nI][nJ])
        Next nJ
        oSection:PrintLine()
        oReport:IncMeter()
    Next nI

    // Fechamento em texto corrido, para nao cortar o total na largura da coluna
    oReport:SkipLine()
    oReport:PrintText(cRodape, 0)
Return

/*/{Protheus.doc} ZCCDesCls
Devolve a descricao da classe de valor para exibicao. Classe sem cadastro na
CTH mostra o proprio codigo; item sem classe mostra "Sem classe de valor",
o mesmo texto usado no resumo da tela principal.
@type Static Function
@param cCod, character, codigo da classe de valor
@param cDescr, character, descricao da classe vinda da base
@return character, descricao para exibir
/*/
Static Function ZCCDesCls(cCod, cDescr)
    Local cRet := AllTrim(cDescr)

    If Empty(cRet)
        If Empty(AllTrim(cCod))
            cRet := "Sem classe de valor"
        Else
            cRet := AllTrim(cCod)
        EndIf
    EndIf
Return cRet

/*/{Protheus.doc} ZCCLinhaDet
Monta uma linha de seis colunas (emissao, documento, codigo, descricao,
quantidade e valor total) a partir de um item carregado por ZCCCarrega.
@type Static Function
@param nGrupo, numeric, grupo do item (1 materiais, 2 servicos, 3 requisitados)
@param aItem, array, item carregado por ZCCCarrega
@return array, linha pronta para a lista
/*/
Static Function ZCCLinhaDet(nGrupo, aItem)
    Local aRet := {}

    If nGrupo == 3
        aRet := {DtoC(aItem[1]), AllTrim(aItem[9]), AllTrim(aItem[3]), ;
            AllTrim(aItem[4]), ZCCFmtNum(aItem[10], 4), ZCCFmtNum(aItem[6], 2)}
    Else
        aRet := {DtoC(aItem[1]), AllTrim(aItem[2]), AllTrim(aItem[3]), ;
            AllTrim(aItem[4]), ZCCFmtNum(aItem[5], 4), ZCCFmtNum(aItem[6], 2)}
    EndIf
Return aRet

/*/{Protheus.doc} ZCCDetCls
Abre os itens de uma classe de valor do resumo, em duas listas: o periodo
atual em cima e o mesmo periodo do ano anterior embaixo. Materiais e
servicos mostram emissao, pedido, codigo, descricao, quantidade e valor
total; requisitados mostram emissao, numero da solicitacao ao armazem, codigo,
descricao, quantidade atendida e valor total. Cada lista sai da data de
emissao mais antiga para a mais nova. Quando a classe so tem itens em um dos
periodos, a outra lista mostra uma linha de aviso, que nao vai para a
impressao. O rodape traz, por periodo, a quantidade de itens, de pedidos de
compra distintos (menos em requisitados) e de SCs de compra distintas (nos
requisitados, de solicitacoes ao armazem), alem do valor total. O botao
Imprimir Browse gera uma lista unica com a coluna Periodo.
@type Static Function
@param cGrupo, character, grupo do resumo (Materiais, Servicos ou Requisitados)
@param cClasse, character, codigo da classe de valor ("-" quando sem classe)
@param cDescr, character, descricao da classe de valor
@param aAtu, array, itens do periodo atual {materiais, servicos, requisitados}
@param aAnt, array, itens do periodo de comparacao {materiais, servicos, requisitados}
@param cCodCC, character, codigo do centro de custo
@param cDescCC, character, descricao do centro de custo
@param dDtDe, date, inicio do periodo atual
@param dDtAte, date, fim do periodo atual
@param dCmpDe, date, inicio do periodo anterior
@param dCmpAte, date, fim do periodo anterior
@return nil
/*/
Static Function ZCCDetCls(cGrupo, cClasse, cDescr, aAtu, aAnt, cCodCC, cDescCC, dDtDe, dDtAte, dCmpDe, dCmpAte)
    Local oDlg       := Nil
    Local oLAtu      := Nil
    Local oLAnt      := Nil
    Local oBtnImp    := Nil
    Local aDAtu      := {}
    Local aDAnt      := {}
    Local aSelAtu    := {}
    Local aSelAnt    := {}
    Local aItAtu     := {}
    Local aItAnt     := {}
    Local aVisAtu    := {}
    Local aVisAnt    := {}
    Local aImp       := {}
    Local aCabec     := {}
    Local aLarg      := {}
    Local nG         := 0
    Local nAtu       := 0
    Local nAnt       := 0
    Local nPedAtu    := 0
    Local nPedAnt    := 0
    Local nScAtu     := 0
    Local nScAnt     := 0
    Local nI         := 0
    Local nPosDoc    := 2
    Local cCod       := ""
    Local cTit       := ""
    Local cSub       := ""
    Local cRodape    := ""
    Local cRodapeAtu := ""
    Local cRodapeAnt := ""

    nG := aScan({"Materiais", "Servicos", "Requisitados"}, {|x| x == cGrupo})
    If nG == 0
        Return
    EndIf

    // No resumo a classe vazia aparece como "-"
    cCod := AllTrim(cClasse)
    If cCod == "-"
        cCod := ""
    EndIf

    // Cada lista sai da data de emissao mais antiga para a mais nova; quando
    // duas linhas tem a mesma data, o desempate e pelo documento exibido
    If nG == 3
        nPosDoc := 9
    EndIf
    aDAtu := aClone(aAtu[nG])
    aDAnt := aClone(aAnt[nG])
    aSort(aDAtu,,, {|x, y| DtoS(x[1]) + x[nPosDoc] < DtoS(y[1]) + y[nPosDoc]})
    aSort(aDAnt,,, {|x, y| DtoS(x[1]) + x[nPosDoc] < DtoS(y[1]) + y[nPosDoc]})

    For nI := 1 To Len(aDAtu)
        If AllTrim(aDAtu[nI][7]) == cCod
            nAtu += aDAtu[nI][6]
            aAdd(aSelAtu, aDAtu[nI])
            aAdd(aItAtu, ZCCLinhaDet(nG, aDAtu[nI]))
        EndIf
    Next nI

    For nI := 1 To Len(aDAnt)
        If AllTrim(aDAnt[nI][7]) == cCod
            nAnt += aDAnt[nI][6]
            aAdd(aSelAnt, aDAnt[nI])
            aAdd(aItAnt, ZCCLinhaDet(nG, aDAnt[nI]))
        EndIf
    Next nI

    If Len(aItAtu) == 0 .And. Len(aItAnt) == 0
        MsgAlert("Nenhum item encontrado para esta classe no periodo.", "Atencao")
        Return
    EndIf

    // O rodape conta os documentos distintos da lista: pedido de compra e SC
    // de origem (requisitados nao tem pedido, so a SC)
    nScAtu := ZCCConta(aSelAtu, 9)
    nScAnt := ZCCConta(aSelAnt, 9)
    If nG <> 3
        nPedAtu := ZCCConta(aSelAtu, 2)
        nPedAnt := ZCCConta(aSelAnt, 2)
    EndIf

    // Quando a classe so existe em um dos periodos, a lista vazia recebe uma
    // linha de aviso apenas na tela; a impressao usa so os itens reais
    aVisAtu := aClone(aItAtu)
    If Len(aVisAtu) == 0
        aAdd(aVisAtu, {"", "", "", "Nenhum item no periodo atual", "", ""})
    EndIf

    aVisAnt := aClone(aItAnt)
    If Len(aVisAnt) == 0
        aAdd(aVisAnt, {"", "", "", "Nenhum item no periodo anterior", "", ""})
    EndIf

    cTit := "Materiais comprados"
    If nG == 2
        cTit := "Servicos"
    ElseIf nG == 3
        cTit := "Requisitados ao almoxarifado"
    EndIf

    If Empty(cCod)
        cTit += " - sem classe de valor"
    Else
        cTit += " - classe " + cCod
        If !Empty(AllTrim(cDescr))
            cTit += " - " + AllTrim(cDescr)
        EndIf
    EndIf

    cSub := "Centro de custo: " + AllTrim(cCodCC) + " - " + AllTrim(cDescCC)

    cRodapeAtu := "Itens atual: " + cValToChar(Len(aItAtu))
    If nG == 3
        cRodapeAtu += " (Solicitacoes: " + cValToChar(nScAtu) + ")"
    Else
        cRodapeAtu += " (Pedidos: " + cValToChar(nPedAtu) + ", SCs: " + cValToChar(nScAtu) + ")"
    EndIf
    cRodapeAtu += " - R$ " + ZCCFmtNum(nAtu, 2)

    cRodapeAnt := "Itens anterior: " + cValToChar(Len(aItAnt))
    If nG == 3
        cRodapeAnt += " (Solicitacoes: " + cValToChar(nScAnt) + ")"
    Else
        cRodapeAnt += " (Pedidos: " + cValToChar(nPedAnt) + ", SCs: " + cValToChar(nScAnt) + ")"
    EndIf
    cRodapeAnt += " - R$ " + ZCCFmtNum(nAnt, 2)

    // Na tela cada periodo ocupa uma linha; a impressao usa as duas juntas
    cRodape := cRodapeAtu + "   " + cRodapeAnt

    // Impressao: lista unica com a coluna Periodo
    For nI := 1 To Len(aItAtu)
        aAdd(aImp, {"Atual", aItAtu[nI][1], aItAtu[nI][2], aItAtu[nI][3], ;
            aItAtu[nI][4], aItAtu[nI][5], aItAtu[nI][6]})
    Next nI
    For nI := 1 To Len(aItAnt)
        aAdd(aImp, {"Anterior", aItAnt[nI][1], aItAnt[nI][2], aItAnt[nI][3], ;
            aItAnt[nI][4], aItAnt[nI][5], aItAnt[nI][6]})
    Next nI

    If nG == 3
        aCabec := {"Periodo", "Emissao", "Solicitacao", "Codigo", "Descricao", "Qtde atendida", "Valor total"}
        aLarg  := {10, 12, 12, 15, 40, 15, 16}

        DEFINE MSDIALOG oDlg TITLE cTit FROM 0,0 TO 650,1250 PIXEL
        @5,5 SAY cSub SIZE 550,10 OF oDlg PIXEL
        @20,5 SAY "Ano atual: " + DtoC(dDtDe) + " a " + DtoC(dDtAte) SIZE 400,10 OF oDlg PIXEL
        @32,5 LISTBOX oLAtu FIELDS HEADER "Emissao", "Solicitacao", "Codigo", "Descricao", ;
            "Qtde atendida", "Valor total" ;
            SIZE 550,110 OF oDlg PIXEL
        oLAtu:aColSizes := {60, 65, 70, 165, 65, 80}
        oLAtu:SetArray(aVisAtu)
        oLAtu:bLine := {|| aVisAtu[oLAtu:nAt]}
        @155,5 SAY "Ano anterior: " + DtoC(dCmpDe) + " a " + DtoC(dCmpAte) SIZE 400,10 OF oDlg PIXEL
        @167,5 LISTBOX oLAnt FIELDS HEADER "Emissao", "Solicitacao", "Codigo", "Descricao", ;
            "Qtde atendida", "Valor total" ;
            SIZE 550,110 OF oDlg PIXEL
        oLAnt:aColSizes := {60, 65, 70, 165, 65, 80}
        oLAnt:SetArray(aVisAnt)
        oLAnt:bLine := {|| aVisAnt[oLAnt:nAt]}
        @279,5 SAY cRodapeAtu SIZE 550,10 OF oDlg PIXEL
        @291,5 SAY cRodapeAnt SIZE 550,10 OF oDlg PIXEL
        @305,520 BUTTON oBtnImp PROMPT "Imprimir Browse" SIZE 90,16 OF oDlg PIXEL ;
            ACTION ZCCImpLis(cTit, cSub, aCabec, aLarg, aImp, cRodape)
        ACTIVATE MSDIALOG oDlg CENTERED
    Else
        aCabec := {"Periodo", "Emissao", "Pedido", "Codigo", "Descricao", "Quantidade", "Valor total"}
        aLarg  := {10, 12, 12, 15, 40, 12, 16}

        DEFINE MSDIALOG oDlg TITLE cTit FROM 0,0 TO 650,1250 PIXEL
        @5,5 SAY cSub SIZE 550,10 OF oDlg PIXEL
        @20,5 SAY "Ano atual: " + DtoC(dDtDe) + " a " + DtoC(dDtAte) SIZE 400,10 OF oDlg PIXEL
        @32,5 LISTBOX oLAtu FIELDS HEADER "Emissao", "Pedido", "Codigo", "Descricao", ;
            "Quantidade", "Valor total" ;
            SIZE 550,110 OF oDlg PIXEL
        oLAtu:aColSizes := {60, 65, 70, 175, 55, 80}
        oLAtu:SetArray(aVisAtu)
        oLAtu:bLine := {|| aVisAtu[oLAtu:nAt]}
        @155,5 SAY "Ano anterior: " + DtoC(dCmpDe) + " a " + DtoC(dCmpAte) SIZE 400,10 OF oDlg PIXEL
        @167,5 LISTBOX oLAnt FIELDS HEADER "Emissao", "Pedido", "Codigo", "Descricao", ;
            "Quantidade", "Valor total" ;
            SIZE 550,110 OF oDlg PIXEL
        oLAnt:aColSizes := {60, 65, 70, 175, 55, 80}
        oLAnt:SetArray(aVisAnt)
        oLAnt:bLine := {|| aVisAnt[oLAnt:nAt]}
        @279,5 SAY cRodapeAtu SIZE 550,10 OF oDlg PIXEL
        @291,5 SAY cRodapeAnt SIZE 550,10 OF oDlg PIXEL
        @305,520 BUTTON oBtnImp PROMPT "Imprimir Browse" SIZE 90,16 OF oDlg PIXEL ;
            ACTION ZCCImpLis(cTit, cSub, aCabec, aLarg, aImp, cRodape)
        ACTIVATE MSDIALOG oDlg CENTERED
    EndIf
Return

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
 Imprime a tela de resultado via TReport (PDF e planilha), com as mesmas 6
 colunas da lista e 4 linhas de fechamento. O cabecalho traz os periodos.
 @type Static Function
 @param aResumo, array, linhas {grupo, classe, descricao, valor, anterior, variacao}
 @param aTot, array, totais {{atual, anterior}} de materiais, servicos e requisitados
 @param cPer, character, texto dos periodos (atual e ano anterior)
 @return nil
 /*/
Static Function ZCCImpr(aResumo, aTot, cPer)
    Local aArea   := GetArea()
    Local oReport
    Local oSection

    If Len(aResumo) == 0
        MsgAlert("Nenhum gasto encontrado para imprimir.", "Atencao")
        RestArea(aArea)
        Return
    EndIf

    oReport := TReport():New("ZGASTOCC", "Gastos por Centro de Custo", "", ;
        {|oReport| ZCCImprRpt(oReport, aResumo, aTot)}, ;
        "Resumo de gastos por centro de custo - Filial: " + cFilAnt + " - " + cPer)

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    oSection := TRSection():New(oReport, "Resumo", {})

    TRCell():New(oSection, "GRUPO",  "", "Grupo",        "@!", 28)
    TRCell():New(oSection, "CLASSE", "", "Classe",       "@!", 10)
    TRCell():New(oSection, "DESCR",  "", "Descricao",    "@!", 40)
    TRCell():New(oSection, "VALOR",  "", "Valor",        "@E 9,999,999,999.99", 16)
    TRCell():New(oSection, "ANTER",  "", "Ano anterior", "@E 9,999,999,999.99", 16)
    TRCell():New(oSection, "VARIA",  "", "Variacao %",   "@!", 24)

    oReport:PrintDialog()

    RestArea(aArea)
Return

/*/{Protheus.doc} ZCCImprRpt
 Callback do TReport: imprime as linhas por classe e as 4 linhas de
 fechamento (materiais, servicos, requisitados e total geral).
 @type Static Function
 @param oReport, object, Objeto TReport
 @param aResumo, array, linhas {grupo, classe, descricao, valor, anterior, variacao}
 @param aTot, array, totais {{atual, anterior}} de materiais, servicos e requisitados
 /*/
Static Function ZCCImprRpt(oReport, aResumo, aTot)
    Local oSection := oReport:Section(1)
    Local aNomes   := {"Materiais comprados", "Servicos", "Requisitados ao almoxarifado"}
    Local nAtuG    := 0
    Local nAntG    := 0
    Local nI       := 0

    oReport:SetMeter(0)
    oSection:Init()

    For nI := 1 To Len(aResumo)
        oSection:Cell("GRUPO"):SetValue(AllTrim(aResumo[nI][1]))
        oSection:Cell("CLASSE"):SetValue(AllTrim(aResumo[nI][2]))
        oSection:Cell("DESCR"):SetValue(AllTrim(aResumo[nI][3]))
        oSection:Cell("VALOR"):SetValue(aResumo[nI][4])
        oSection:Cell("ANTER"):SetValue(aResumo[nI][5])
        oSection:Cell("VARIA"):SetValue(aResumo[nI][6])

        oSection:PrintLine()
        oReport:IncMeter()
    Next nI

    // Linhas de fechamento
    For nI := 1 To 3
        nAtuG += aTot[nI][1]
        nAntG += aTot[nI][2]
        oSection:Cell("GRUPO"):SetValue(aNomes[nI])
        oSection:Cell("CLASSE"):SetValue("")
        oSection:Cell("DESCR"):SetValue("")
        oSection:Cell("VALOR"):SetValue(aTot[nI][1])
        oSection:Cell("ANTER"):SetValue(aTot[nI][2])
        oSection:Cell("VARIA"):SetValue(ZCCVariacao(aTot[nI][1], aTot[nI][2]))
        oSection:PrintLine()
    Next nI

    oSection:Cell("GRUPO"):SetValue("TOTAL GERAL")
    oSection:Cell("CLASSE"):SetValue("")
    oSection:Cell("DESCR"):SetValue("")
    oSection:Cell("VALOR"):SetValue(nAtuG)
    oSection:Cell("ANTER"):SetValue(nAntG)
    oSection:Cell("VARIA"):SetValue(ZCCVariacao(nAtuG, nAntG))
    oSection:PrintLine()

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

    If Empty(dData)
        Return CtoD("")
    EndIf

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

/*/{Protheus.doc} ZCCFmtDif
Diferenca em reais com sinal (+ ou -).
@type Static Function
@param nDif, numeric, diferenca entre atual e comparado
@return character, texto formatado
/*/
Static Function ZCCFmtDif(nDif)
    Local cSin := ""

    If nDif > 0
        cSin := "+"
    EndIf
Return cSin + ZCCFmtNum(nDif, 2)

/*/{Protheus.doc} ZCCMesDesloca
Soma (ou subtrai) meses a um mes no formato AAAAMM.
@type Static Function
@param cMes, character, mes no formato AAAAMM
@param nMeses, numeric, quantidade de meses (pode ser negativa)
@return character, mes resultante no formato AAAAMM
/*/
Static Function ZCCMesDesloca(cMes, nMeses)
    Local nTotal := (Val(Left(cMes, 4)) * 12) + (Val(SubStr(cMes, 5, 2)) - 1) + nMeses
    Local nAno   := Int(nTotal / 12)
    Local nMes   := nTotal - (nAno * 12) + 1
Return StrZero(nAno, 4) + StrZero(nMes, 2)

/*/{Protheus.doc} ZCCMonta
Consolida atual x anterior por classe (ordenado por valor, maior primeiro)
e por mes. Nao desenha nada.
@type Static Function
@param aMat, array, materiais do periodo atual
@param aSvc, array, servicos do periodo atual
@param aReq, array, requisicoes do periodo atual
@param aMatA, array, materiais do periodo de comparacao
@param aSvcA, array, servicos do periodo de comparacao
@param aReqA, array, requisicoes do periodo de comparacao
@param nOff, numeric, meses entre o inicio atual e o inicio da comparacao
@return array, {aLinhas, aTotais, aMeses}
/*/
Static Function ZCCMonta(aMat, aSvc, aReq, aMatA, aSvcA, aReqA, nOff)
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
    Local cClasse := ""

    For nG := 1 To 3
        aRA := ZCCResumo(aAtual[nG])
        aRB := ZCCResumo(aAnter[nG])
        aTot[nG][1] := aRA[2]
        aTot[nG][2] := aRB[2]
        aCls := {}

        For nI := 1 To Len(aRA[1])
            nPos := aScan(aRB[1], {|x| AllTrim(x[1]) == AllTrim(aRA[1][nI][1])})
            nAnt := 0
            If nPos > 0
                nAnt := aRB[1][nPos][3]
            EndIf
            aAdd(aCls, {aNomes[nG], aRA[1][nI][1], aRA[1][nI][2], aRA[1][nI][3], nAnt})
        Next nI

        // Classe que so existiu no periodo de comparacao
        For nI := 1 To Len(aRB[1])
            nPos := aScan(aRA[1], {|x| AllTrim(x[1]) == AllTrim(aRB[1][nI][1])})
            If nPos == 0
                aAdd(aCls, {aNomes[nG], aRB[1][nI][1], aRB[1][nI][2], 0, aRB[1][nI][3]})
            EndIf
        Next nI

        aSort(aCls,,, {|x, y| x[4] > y[4]})

        For nI := 1 To Len(aCls)
            cClasse := AllTrim(aCls[nI][2])
            If Empty(cClasse)
                cClasse := "-"
            EndIf
            aAdd(aLinhas, {aNomes[nG], cClasse, AllTrim(aCls[nI][3]), aCls[nI][4], aCls[nI][5], ;
                ZCCVariacao(aCls[nI][4], aCls[nI][5])})
        Next nI

        // Meses: colunas 2..4 = atual (mat, svc, req); 5..7 = comparacao
        For nI := 1 To Len(aAtual[nG])
            cMes := Left(DtoS(aAtual[nG][nI][1]), 6)
            nPos := aScan(aMeses, {|x| x[1] == cMes})
            If nPos == 0
                aAdd(aMeses, {cMes, 0, 0, 0, 0, 0, 0})
                nPos := Len(aMeses)
            EndIf
            aMeses[nPos][1 + nG] += aAtual[nG][nI][6]
        Next nI

        // Mes da comparacao e deslocado nOff meses para casar com o atual
        For nI := 1 To Len(aAnter[nG])
            cMes := ZCCMesDesloca(Left(DtoS(aAnter[nG][nI][1]), 6), nOff)
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

/*/{Protheus.doc} ZCCTotLinhas
Monta as 4 linhas da tabela de totais (materiais, servicos, requisitados e
total geral). Sem comparacao, so a coluna Atual vem preenchida.
@type Static Function
@param aAtu, array, {materiais, servicos, requisitados} atuais
@param aComp, array, {materiais, servicos, requisitados} comparados (ou Nil)
@return array, linhas {item, atual, comparado, diferenca, variacao}
/*/
Static Function ZCCTotLinhas(aAtu, aComp)
    Local aRot   := {"Materiais comprados", "Servicos", "Requisitados ao almoxarifado", "TOTAL GERAL"}
    Local aLin   := {}
    Local nAtu   := 0
    Local nCmp   := 0
    Local nI     := 0
    Local lComp  := ValType(aComp) == "A"

    For nI := 1 To 4
        If nI == 4
            nAtu := aAtu[1] + aAtu[2] + aAtu[3]
            If lComp
                nCmp := aComp[1] + aComp[2] + aComp[3]
            EndIf
        Else
            nAtu := aAtu[nI]
            If lComp
                nCmp := aComp[nI]
            EndIf
        EndIf

        If lComp
            aAdd(aLin, {aRot[nI], ZCCFmtNum(nAtu, 2), ZCCFmtNum(nCmp, 2), ZCCFmtDif(nAtu - nCmp), ZCCVariacao(nAtu, nCmp)})
        Else
            aAdd(aLin, {aRot[nI], ZCCFmtNum(nAtu, 2), "", "", ""})
        EndIf
    Next nI
Return aLin

/*/{Protheus.doc} ZCCTotBase
Totais iniciais: so o periodo atual.
@type Static Function
@param dDtDe, date, inicio do periodo atual
@param dDtAte, date, fim do periodo atual
@param aTot, array, totais {{atual, anterior}} dos tres grupos
@return array, {titulo, linhas}
/*/
Static Function ZCCTotBase(dDtDe, dDtAte, aTot)
    Local cTit := "Totais do periodo atual: " + DtoC(dDtDe) + " a " + DtoC(dDtAte)
Return {cTit, ZCCTotLinhas({aTot[1][1], aTot[2][1], aTot[3][1]}, Nil)}

/*/{Protheus.doc} ZCCTotAnual
Totais do comparativo anual: periodo atual contra o mesmo periodo do ano
anterior.
@type Static Function
@param dDtDe, date, inicio do periodo atual
@param dDtAte, date, fim do periodo atual
@param dCmpDe, date, inicio do ano anterior
@param dCmpAte, date, fim do ano anterior
@param aTot, array, totais {{atual, anterior}} dos tres grupos
@return array, {titulo, linhas}
/*/
Static Function ZCCTotAnual(dDtDe, dDtAte, dCmpDe, dCmpAte, aTot)
    Local cTit := "Comparativo anual:  Atual = " + DtoC(dDtDe) + " a " + DtoC(dDtAte) + ;
        "   |   Comparado = " + DtoC(dCmpDe) + " a " + DtoC(dCmpAte)
Return {cTit, ZCCTotLinhas({aTot[1][1], aTot[2][1], aTot[3][1]}, {aTot[1][2], aTot[2][2], aTot[3][2]})}

/*/{Protheus.doc} ZCCTotMensal
Totais do comparativo mensal: mes final do periodo contra o mes anterior.
@type Static Function
@param dDtAte, date, fim do periodo atual (define o mes)
@param aMeses, array, {mes AAAAMM, atual x3, comparacao x3}
@return array, {titulo, linhas}
/*/
Static Function ZCCTotMensal(dDtAte, aMeses)
    Local cMes    := Left(DtoS(dDtAte), 6)
    Local cMesAnt := ZCCMesDesloca(cMes, -1)
    Local nPos    := aScan(aMeses, {|x| x[1] == cMes})
    Local nPosAnt := aScan(aMeses, {|x| x[1] == cMesAnt})
    Local aAtu    := {0, 0, 0}
    Local aAnt    := {0, 0, 0}
    Local cTit    := ""

    If nPos > 0
        aAtu := {aMeses[nPos][2], aMeses[nPos][3], aMeses[nPos][4]}
    EndIf

    If nPosAnt > 0
        aAnt := {aMeses[nPosAnt][2], aMeses[nPosAnt][3], aMeses[nPosAnt][4]}
    EndIf

    cTit := "Comparativo mensal:  Atual = " + SubStr(cMes, 5, 2) + "/" + Left(cMes, 4) + ;
        "   |   Comparado = mes anterior " + SubStr(cMesAnt, 5, 2) + "/" + Left(cMesAnt, 4)
Return {cTit, ZCCTotLinhas(aAtu, aAnt)}

/*/{Protheus.doc} ZCCTotAtualiza
Troca o titulo e as linhas da tabela de totais e redesenha.
@type Static Function
@param oSay, object, texto do titulo acima da tabela
@param oLst, object, listbox dos totais
@param aTxt, array, {titulo, linhas}
@return nil
/*/
Static Function ZCCTotAtualiza(oSay, oLst, aTxt)
    Local aLin := aTxt[2]

    oSay:SetText(aTxt[1])
    oLst:SetArray(aLin)
    oLst:bLine := {|| {aLin[oLst:nAt][1], aLin[oLst:nAt][2], aLin[oLst:nAt][3], aLin[oLst:nAt][4], aLin[oLst:nAt][5]}}
    oLst:GoTop()
    oLst:Refresh()
Return
