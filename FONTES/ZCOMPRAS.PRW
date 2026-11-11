#Include "Protheus.ch"
#Include "TopConn.ch"

// Constantes de layout
#Define META_DESC     3      // Meta de desconto em %
#Define PROX_META     2.5    // Proximo da meta em %

// Variaveis estaticas do modulo
Static aCompras     := {}
Static aComprasOrig := {}
Static aComprasFull := {}
Static nTotCompra := 0
Static nTotDesc   := 0
Static nPercDesc  := 0
Static nMetaRS    := 0
Static nDifMeta   := 0
Static nQtdProd   := 0   // Qtd de produtos distintos adquiridos no periodo

// Objetos dinamicos para atualizacao de cor
Static oSayDesc   := Nil   // TSay Desconto Obtido (cor muda)
Static oSayDif    := Nil   // TSay Diferenca para Meta (cor muda)
Static oSayTotDesc:= Nil   // TSay totalizador Desc no rodape (cor muda)
Static oPnlBarraS := Nil   // TPanel barra de progresso (cor muda)
Static oSayPercBar:= Nil   // TSay percentual sobre a barra (cor muda)

// Snapshot do array filtrado para exportacao Excel
Static aComprasExp := {}

// Arrays de pedidos por fornecedor separados por tipo (Geral Suprimentos)
Static aFornMat := {}      // {cNomeForn, nQtdPedidos} - Materiais
Static aFornSvc := {}      // {cNomeForn, nQtdPedidos} - Servicos

/*/{Protheus.doc} ZCOMPRAS
Consulta de compras por periodo com analise de desconto vs meta (3%).
Permite ao usuario visualizar seus pedidos de compra (SC7) em um periodo,
calcular o percentual de desconto obtido e comparar com a meta de 3%.
Exibe tambem a quantidade de produtos distintos adquiridos no periodo.
@type User Function
@author Desenvolvimento
@since 15/02/2026
/*/
User Function ZCOMPRAS()
    Local aUsers    := {}
    Local aUserCods := {}
    Local nPos      := 0
    Local nAcao     := 0   // 0=cancelar, 1=consultar, 2=relat.geral, 3=geral suprimentos

    // Campos de filtro
    Local dDtDe    := CtoD("")
    Local dDtAte   := LastDate(Date())
    Local cCodUsr  := ""
    Local cNomeUsr := ""
    Local cSelUser := ""

    // Objetos do dialogo
    Local oDlgParam, oFontP, oFontTitP
    Local oGetDe, oGetAte, oComboUsr
    Local oBtnConsultar, oBtnRelGeral, oBtnGeralSupri, oBtnCancelar

    // Carrega lista de compradores que tem pedidos no SC7
    CarregaCompradores(@aUsers, @aUserCods)

    // Comprador inicia em branco para o usuario selecionar
    cSelUser := ""

    // Inicializa variaveis
    aCompras     := {}
    aComprasOrig := {}
    aComprasFull := {}
    nTotCompra := 0
    nTotDesc   := 0
    nPercDesc  := 0
    nQtdProd   := 0
    nMetaRS    := 0
    nDifMeta   := 0

    // Fontes
    oFontP    := TFont():New("Arial",, -12,, .F.)
    oFontTitP := TFont():New("Arial",, -14, .T., .F.)

    // Dialogo de parametros customizado (altura aumentada para caber botoes)
    DEFINE MSDIALOG oDlgParam TITLE "Consulta de Compras - Analise de Descontos" ;
        FROM 0,0 TO 310, 430 PIXEL STYLE DS_MODALFRAME

    // Titulo
    TSay():New(012, 015, {|| "Parametros da Consulta"}, oDlgParam, , ;
        oFontTitP, , , , .T., CLR_HBLUE, , 200, 16)

    // Data Inicial
    @ 038, 020 SAY "Data Inicial:" SIZE 070, 012 PIXEL OF oDlgParam FONT oFontP
    @ 036, 100 MSGET oGetDe VAR dDtDe SIZE 080, 012 PIXEL OF oDlgParam

    // Data Final
    @ 058, 020 SAY "Data Final:" SIZE 070, 012 PIXEL OF oDlgParam FONT oFontP
    @ 056, 100 MSGET oGetAte VAR dDtAte SIZE 080, 012 PIXEL OF oDlgParam

    // Comprador
    @ 078, 020 SAY "Comprador: *" SIZE 070, 012 PIXEL OF oDlgParam FONT oFontP
    @ 076, 100 MSCOMBOBOX oComboUsr VAR cSelUser ITEMS aUsers SIZE 100, 012 OF oDlgParam PIXEL

    // Botao Geral Suprimentos (5 compradores fixos do setor)
    @ 094, 020 BUTTON oBtnGeralSupri PROMPT "Geral Suprimentos" SIZE 090, 015 OF oDlgParam PIXEL ;
        ACTION (nAcao := 3, oDlgParam:End())

    // Botao Relat. Geral
    @ 094, 120 BUTTON oBtnRelGeral PROMPT "Relat. Geral" SIZE 090, 015 OF oDlgParam PIXEL ;
        ACTION (nAcao := 2, oDlgParam:End())

    // Botoes principais
    @ 120, 020 BUTTON oBtnConsultar PROMPT "Consultar" SIZE 090, 015 OF oDlgParam PIXEL ;
        ACTION (nAcao := 1, oDlgParam:End())

    @ 120, 120 BUTTON oBtnCancelar PROMPT "Cancelar" SIZE 090, 015 OF oDlgParam PIXEL ;
        ACTION (nAcao := 0, oDlgParam:End())

    ACTIVATE MSDIALOG oDlgParam CENTERED

    FreeObj(oFontP)
    FreeObj(oFontTitP)

    // Processa acao escolhida
    If nAcao == 1  // Consultar comprador individual
        nPos := aScan(aUsers, {|x| AllTrim(x) == AllTrim(cSelUser)})
        If nPos > 0
            cCodUsr  := aUserCods[nPos]
            cNomeUsr := aUsers[nPos]
        Else
            MsgAlert("Selecione um comprador valido!", "Atencao")
            Return
        EndIf
        ConsultarDireto(dDtDe, dDtAte, cCodUsr, cNomeUsr)

    ElseIf nAcao == 2  // Relatorio geral de todos os compradores
        RelatorioGeral(dDtDe, dDtAte)

    ElseIf nAcao == 3  // Geral Suprimentos (5 compradores fixos)
        GeralSuprimentos(dDtDe, dDtAte)
    EndIf
Return

/*/{Protheus.doc} FirstDate
Retorna o primeiro dia do mes da data informada
@type Static Function
/*/
Static Function FirstDate(dData)
    Local cAno := Str(Year(dData), 4)
    Local cMes := StrZero(Month(dData), 2)
Return StoD(cAno + cMes + "01")

/*/{Protheus.doc} LastDate
Retorna o ultimo dia do mes da data informada
@type Static Function
/*/
Static Function LastDate(dData)
    Local dProxMes := FirstDate(dData) + 32
    Local dPrimProx := FirstDate(dProxMes)
Return dPrimProx - 1

/*/{Protheus.doc} CarregaCompradores
Carrega lista de usuarios que possuem pedidos de compra no SC7
Retorna arrays paralelos: aUsers (nome exibicao) e aUserCods (codigos)
@type Static Function
/*/
Static Function CarregaCompradores(aUsers, aUserCods)
    Local cAlias := GetNextAlias()
    Local cCod   := ""
    Local cNome  := ""

    aUsers    := {}
    aUserCods := {}

    BeginSql Alias cAlias
        SELECT DISTINCT C7_USER
        FROM %Table:SC7%
        WHERE %NotDel%
          AND C7_FILIAL = %xFilial:SC7%
          AND C7_USER <> ''
          AND C7_USER <> ' '
        ORDER BY C7_USER
    EndSql

    While !(cAlias)->(Eof())
        cCod  := AllTrim((cAlias)->C7_USER)
        cNome := AllTrim(UsrRetName(cCod))

        If Empty(cNome)
            cNome := cCod
        EndIf

        aAdd(aUsers,    cCod + " - " + cNome)
        aAdd(aUserCods, cCod)

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    // Se nao encontrou nenhum, adiciona o usuario logado
    If Len(aUsers) == 0
        cCod  := RetCodUsr()
        cNome := UsrRetName(cCod)
        aAdd(aUsers,    AllTrim(cCod) + " - " + AllTrim(cNome))
        aAdd(aUserCods, AllTrim(cCod))
    EndIf
Return

/*/{Protheus.doc} ConsultarDireto
Executa a consulta dos pedidos de compra e abre a tela de resultados.
Chamada diretamente apos o ParamBox confirmar.
@type Static Function
/*/
Static Function ConsultarDireto(dDtDe, dDtAte, cCodUser, cNomeUser)
    Local cAlias := GetNextAlias()
    Local cQuery := ""
    Local nVlrTot, nVlrDesc, nPercIt

    // Validacoes
    If Empty(dDtDe) .Or. Empty(dDtAte)
        MsgAlert("Informe o periodo completo!", "Atencao")
        Return
    EndIf

    If dDtAte < dDtDe
        MsgAlert("Data final nao pode ser anterior a data inicial!", "Atencao")
        Return
    EndIf

    If Empty(cCodUser)
        MsgAlert("Informe o comprador!", "Atencao")
        Return
    EndIf

    // Limpa dados anteriores
    aCompras   := {}
    nTotCompra := 0
    nTotDesc   := 0
    nPercDesc  := 0
    nQtdProd   := 0

    cQuery := " SELECT"
    cQuery += "   C7_NUM,"
    cQuery += "   C7_EMISSAO,"
    cQuery += "   C7_FORNECE,"
    cQuery += "   C7_LOJA,"
    cQuery += "   A2_NOME,"
    cQuery += "   SUM(C7_TOTAL) AS VLR_TOTAL,"
    cQuery += "   SUM(C7_VLDESC) AS VLR_DESC,"
    cQuery += "   SUM(C7_QUANT) AS QTD_ITENS,"
    cQuery += "   SUM(C7_QUANT) AS QTD_PEDIDA,"
    cQuery += "   SUM(C7_QUJE) AS QTD_ENTREGUE"
    cQuery += " FROM " + RetSqlName("SC7") + " SC7"
    cQuery += " LEFT JOIN " + RetSqlName("SA2") + " SA2"
    cQuery += "   ON SA2.D_E_L_E_T_ = ' '"
    cQuery += "   AND A2_FILIAL = '" + xFilial("SA2") + "'"
    cQuery += "   AND A2_COD = C7_FORNECE"
    cQuery += "   AND A2_LOJA = C7_LOJA"
    cQuery += " WHERE SC7.D_E_L_E_T_ = ' '"
    cQuery += "   AND C7_FILIAL = '" + xFilial("SC7") + "'"
    cQuery += "   AND C7_EMISSAO BETWEEN '" + DtoS(dDtDe) + "' AND '" + DtoS(dDtAte) + "'"
    cQuery += "   AND C7_USER = '" + cCodUser + "'"
    cQuery += "   AND C7_RESIDUO <> 'S'"
    cQuery += "   AND (C7_CONAPRO = '' OR C7_CONAPRO = ' ' OR C7_CONAPRO = 'L')"
    cQuery += " GROUP BY C7_NUM, C7_EMISSAO, C7_FORNECE, C7_LOJA, A2_NOME"
    cQuery += " ORDER BY C7_EMISSAO, C7_NUM"

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        nVlrTot  := (cAlias)->VLR_TOTAL
        nVlrDesc := (cAlias)->VLR_DESC
        nPercIt  := IIF(nVlrTot > 0, Round((nVlrDesc / nVlrTot) * 100, 2), 0)

        aAdd(aCompras, {;
            AllTrim((cAlias)->C7_NUM),;                   // [1] Pedido
            StoD((cAlias)->C7_EMISSAO),;                  // [2] Data
            AllTrim((cAlias)->C7_FORNECE),;                // [3] Cod Fornecedor
            AllTrim((cAlias)->C7_LOJA),;                   // [4] Loja
            AllTrim((cAlias)->A2_NOME),;                   // [5] Nome Fornecedor
            nVlrTot,;                                      // [6] Valor Total
            nVlrDesc,;                                     // [7] Valor Desconto
            nPercIt,;                                      // [8] % Desconto
            (cAlias)->QTD_ITENS,;                          // [9] Qtd Itens
            StatusEntrega((cAlias)->QTD_PEDIDA, (cAlias)->QTD_ENTREGUE)}) // [10] Status Entrega

        nTotCompra += nVlrTot
        nTotDesc   += nVlrDesc

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    If Len(aCompras) == 0
        MsgAlert("Nenhum pedido encontrado para o periodo/comprador informado!", "Atencao")
        Return
    EndIf

    // Calculos finais
    nPercDesc := IIF(nTotCompra > 0, (nTotDesc / nTotCompra) * 100, 0)
    nMetaRS   := nTotCompra * (META_DESC / 100)
    nDifMeta  := nTotDesc - nMetaRS

    // Guarda copia original para uso do filtro
    aComprasOrig := aClone(aCompras)
    aComprasFull := aClone(aCompras)

    // Conta produtos distintos adquiridos no periodo
    nQtdProd := ContaProdutosDistintos(dDtDe, dDtAte, "C7_USER = '" + cCodUser + "'")
    // Abre tela de resultados
    TelaResultados(dDtDe, dDtAte, cNomeUser)
Return

/*/{Protheus.doc} MontaFornecedores
Monta os arrays aFornMat e aFornSvc com quantidade de pedidos distintos
por fornecedor, separando Material (B1_TIPO <> 'SV') de Servico (B1_TIPO = 'SV').
@type Static Function
@param dDtDe - Data inicial
@param dDtAte - Data final
@param cClausulaUser - clausula WHERE com filtro de usuario(s)
/*/
Static Function MontaFornecedores(dDtDe, dDtAte, cClausulaUser)
    Local cAlias := GetNextAlias()
    Local cQuery := ""
    Local cSC7   := RetSqlName("SC7")
    Local cSA2   := RetSqlName("SA2")
    Local cSB1   := RetSqlName("SB1")
    Local cTipo  := ""
    Local cNome  := ""
    Local nQtd   := 0

    aFornMat := {}
    aFornSvc := {}

    cQuery := " SELECT A2_NOME, B1_TIPO, COUNT(DISTINCT C7_NUM) AS QTDPED"
    cQuery += " FROM " + cSC7 + " SC7"
    cQuery += " LEFT JOIN " + cSA2 + " SA2"
    cQuery += "   ON SA2.D_E_L_E_T_ = ' '"
    cQuery += "   AND A2_FILIAL = '" + xFilial("SA2") + "'"
    cQuery += "   AND A2_COD  = C7_FORNECE"
    cQuery += "   AND A2_LOJA = C7_LOJA"
    cQuery += " LEFT JOIN " + cSB1 + " SB1"
    cQuery += "   ON SB1.D_E_L_E_T_ = ' '"
    cQuery += "   AND B1_FILIAL = '" + xFilial("SB1") + "'"
    cQuery += "   AND B1_COD = C7_PRODUTO"
    cQuery += " WHERE SC7.D_E_L_E_T_ = ' '"
    cQuery += "   AND C7_FILIAL = '" + xFilial("SC7") + "'"
    cQuery += "   AND C7_EMISSAO BETWEEN '" + DtoS(dDtDe) + "' AND '" + DtoS(dDtAte) + "'"
    cQuery += "   AND " + cClausulaUser
    cQuery += "   AND C7_RESIDUO <> 'S'"
    cQuery += "   AND (C7_CONAPRO = '' OR C7_CONAPRO = ' ' OR C7_CONAPRO = 'L')"
    cQuery += " GROUP BY A2_NOME, B1_TIPO"
    cQuery += " ORDER BY A2_NOME"

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        cNome := AllTrim((cAlias)->A2_NOME)
        cTipo := AllTrim((cAlias)->B1_TIPO)
        nQtd  := (cAlias)->QTDPED

        If cTipo == "SV"
            aAdd(aFornSvc, {cNome, nQtd})
        Else
            aAdd(aFornMat, {cNome, nQtd})
        EndIf

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    If Len(aFornMat) > 1
        aSort(aFornMat,,, {|x,y| x[2] > y[2]})
    EndIf
    If Len(aFornSvc) > 1
        aSort(aFornSvc,,, {|x,y| x[2] > y[2]})
    EndIf
Return

/*/{Protheus.doc} ContaProdutosDistintos
Retorna a quantidade de produtos distintos (C7_PRODUTO) adquiridos no
periodo, respeitando os mesmos filtros da consulta principal.
@type Static Function
@param dDtDe - Data inicial
@param dDtAte - Data final
@param cClausulaUser - clausula WHERE com filtro de usuario(s)
@return nQtd - Quantidade de produtos distintos
/*/
Static Function ContaProdutosDistintos(dDtDe, dDtAte, cClausulaUser)
    Local cAlias := GetNextAlias()
    Local cQuery := ""
    Local cSC7   := RetSqlName("SC7")
    Local nQtd   := 0

    cQuery := " SELECT COUNT(DISTINCT C7_PRODUTO) AS QTD_PROD"
    cQuery += " FROM " + cSC7 + " SC7"
    cQuery += " WHERE SC7.D_E_L_E_T_ = ' '"
    cQuery += "   AND C7_FILIAL = '" + xFilial("SC7") + "'"
    cQuery += "   AND C7_EMISSAO BETWEEN '" + DtoS(dDtDe) + "' AND '" + DtoS(dDtAte) + "'"
    cQuery += "   AND " + cClausulaUser
    cQuery += "   AND C7_RESIDUO <> 'S'"
    cQuery += "   AND (C7_CONAPRO = '' OR C7_CONAPRO = ' ' OR C7_CONAPRO = 'L')"
    cQuery += "   AND LTRIM(RTRIM(C7_PRODUTO)) <> ''"

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    If !(cAlias)->(Eof())
        nQtd := (cAlias)->QTD_PROD
    EndIf
    (cAlias)->(DbCloseArea())
Return nQtd

/*/{Protheus.doc} TelaResultados
Monta a tela de resultados com grid de compras, painel de indicadores,
barra de progresso visual e, para Geral Suprimentos, painel de fornecedores.
@type Static Function
/*/
Static Function TelaResultados(dDtDe, dDtAte, cUsuario)
    Local oDlg
    Local oListBox
    Local oFont, oFontTit, oFontInd, oFontVal
    Local oBtnVoltar, oBtnExcel, oBtnFiltrar, oBtnLimpar
    Local oBtnExcluir, oBtnRestaurar, oBtnFechar
    Local oGetFiltro
    Local oComboDesc, oComboStatus
    Local cFiltro      := Space(40)
    Local cFiltroDesc  := "Todos"
    Local cFiltroStat  := "Todos"
    Local aFiltrosDesc := {"Todos", "Com Desconto", "Sem Desconto", "Acima Meta (>3%)", "Abaixo Meta (<3%)"}
    Local aFiltrosStat := {"Todos", "Entregue", "Parcial", "Pendente"}
    Local nBarraLarg := 0
    Local nCorBarra  := 0
    Local nCorDesc   := 0
    Local nCorDif    := 0
    Local oListMat, oListSvc
    Local aListMatExib := {}
    Local aListSvcExib := {}
    Local nI       := 0
    Local cQtdMat  := ""
    Local cQtdSvc  := ""
    Local lGeral   := (AllTrim(cUsuario) == "Geral Suprimentos")

    // Monta arrays de exibicao do painel de fornecedores (apenas Geral Suprimentos)
    If lGeral
        For nI := 1 To Len(aFornMat)
            aAdd(aListMatExib, { SubStr(aFornMat[nI][1], 1, 25), cValToChar(aFornMat[nI][2]) })
        Next nI
        For nI := 1 To Len(aFornSvc)
            aAdd(aListSvcExib, { SubStr(aFornSvc[nI][1], 1, 25), cValToChar(aFornSvc[nI][2]) })
        Next nI
    EndIf

    cQtdMat := cValToChar(Len(aFornMat))
    cQtdSvc := cValToChar(Len(aFornSvc))

    // Fontes
    oFont    := TFont():New("Arial",, -12,, .F.)
    oFontTit := TFont():New("Arial",, -16, .T., .F.)
    oFontInd := TFont():New("Arial",, -13, .T., .F.)
    oFontVal := TFont():New("Arial",, -14,, .F.)

    // Dialogo de resultados (tamanho maior para Geral Suprimentos com painel de fornecedores)
    If lGeral
        DEFINE MSDIALOG oDlg TITLE "Resultado - Compras de " + AllTrim(cUsuario) + ;
            " (" + DtoC(dDtDe) + " a " + DtoC(dDtAte) + ")" ;
            FROM 0,0 TO 1010,870 PIXEL ;
            STYLE DS_MODALFRAME
    Else
        DEFINE MSDIALOG oDlg TITLE "Resultado - Compras de " + AllTrim(cUsuario) + ;
            " (" + DtoC(dDtDe) + " a " + DtoC(dDtAte) + ")" ;
            FROM 0,0 TO 760,870 PIXEL ;
            STYLE DS_MODALFRAME
    EndIf

    // ================================================================
    // PAINEL DE INDICADORES (topo) - linhas 012 a 148
    // ================================================================
    TSay():New(012, 015, {|| "Indicadores de Performance"}, oDlg, , ;
        oFontTit, , , , .T., CLR_HBLUE, , 250, 18)
    @ 028, 010 TO 148, 420 OF oDlg PIXEL

    // Linha 1 - Valor Total de Compras
    @ 034, 020 SAY "Valor Total de Compras:" SIZE 130, 12 PIXEL OF oDlg FONT oFontInd
    TSay():New(034, 165, ;
        {|| "R$    " + Transform(nTotCompra, "@E 999,999,999.99")}, ;
        oDlg, , oFontVal, , , , .T., CLR_BLACK, , 200, 12)

    // Linha 2 - Desconto Total Obtido
    @ 052, 020 SAY "Desconto Obtido:" SIZE 130, 12 PIXEL OF oDlg FONT oFontInd
    nCorDesc := IIF(nPercDesc >= META_DESC, CLR_HGREEN, IIF(nPercDesc >= PROX_META, RGB(180,140,0), CLR_HRED))
    oSayDesc := TSay():New(052, 165, ;
        {|| "R$    " + Transform(nTotDesc, "@E 999,999,999.99") + ;
            "  (" + Transform(nPercDesc, "@E 99.99") + "%)"}, ;
        oDlg, , oFontVal, , , , .T., ;
        nCorDesc, , 230, 12)

    // Linha 3 - Meta de Desconto
    @ 070, 020 SAY "Meta de Desconto (3%):" SIZE 130, 12 PIXEL OF oDlg FONT oFontInd
    TSay():New(070, 165, ;
        {|| "R$    " + Transform(nMetaRS, "@E 999,999,999.99")}, ;
        oDlg, , oFontVal, , , , .T., CLR_BLACK, , 200, 12)

    // Linha 4 - Diferenca para a Meta
    @ 088, 020 SAY "Diferenca para Meta:" SIZE 130, 12 PIXEL OF oDlg FONT oFontInd
    nCorDif := IIF(nPercDesc >= META_DESC, CLR_HGREEN, IIF(nPercDesc >= PROX_META, RGB(180,140,0), CLR_HRED))
    oSayDif := TSay():New(088, 165, ;
        {|| IIF(nDifMeta >= 0, "+R$   ", "-R$   ") + ;
            Transform(Abs(nDifMeta), "@E 999,999,999.99") + ;
            "  (" + IIF(nDifMeta >= 0, "+", "") + ;
            Transform(nPercDesc - META_DESC, "@E 99.99") + "%)"}, ;
        oDlg, , oFontVal, , , , .T., ;
        nCorDif, , 230, 12)

    // Linha 5 - Produtos Distintos
    @ 106, 020 SAY "Produtos Distintos:" SIZE 130, 12 PIXEL OF oDlg FONT oFontInd
    TSay():New(106, 165, ;
        {|| cValToChar(nQtdProd) + " produtos"}, ;
        oDlg, , oFontVal, , , , .T., CLR_BLACK, , 200, 12)

    // ================================================================
    // BARRA DE PROGRESSO VISUAL - linhas 116 a 148
    // ================================================================
    @ 122, 020 SAY "Progresso vs Meta:" SIZE 090, 12 PIXEL OF oDlg FONT oFont
    @ 120, 120 TO 136, 400 OF oDlg PIXEL

    nBarraLarg := Min(nPercDesc / META_DESC * 100, 150)
    nBarraLarg := Max(Int(nBarraLarg * 278 / 150), 1)

    Do Case
        Case nPercDesc >= META_DESC
            nCorBarra := CLR_GREEN
        Case nPercDesc >= PROX_META
            nCorBarra := CLR_YELLOW
        Otherwise
            nCorBarra := CLR_RED
    EndCase

    oPnlBarraS := TPanel():New(121, 125, "", oDlg, , , , , , ;
        Min(nBarraLarg, 278), 14, .F., .F.)
    oPnlBarraS:SetColor(, nCorBarra)

    @ 118, 306 TO 138, 306 OF oDlg PIXEL
    TSay():New(139, 291, {|| "Meta 3%"}, oDlg, , ;
        TFont():New("Arial",, -9,, .F.), , , , .T., CLR_BLACK, , 50, 8)
    oSayPercBar := TSay():New(123, Min(122 + nBarraLarg + 4, 385), ;
        {|| Transform(nPercDesc, "@E 99.99") + "%"}, ;
        oDlg, , TFont():New("Arial",, -10, .T., .F.), , , , .T., ;
        IIF(nPercDesc >= META_DESC, CLR_HGREEN, CLR_HRED), , 50, 10)

    // ================================================================
    // PAINEL: PEDIDOS POR FORNECEDOR (apenas Geral Suprimentos)
    // ================================================================
    If lGeral
        TSay():New(152, 015, {|| "Pedidos por Fornecedor"}, oDlg, , ;
            oFontTit, , , , .T., CLR_HBLUE, , 300, 18)

        // --- Coluna ESQUERDA: Materiais ---
        TSay():New(174, 015, {|| "Materiais" + cQtdMat + " fornecedores"}, oDlg, , ;
            oFontInd, , , , .T., CLR_BLACK, , 200, 14)

        @ 190, 010 LISTBOX oListMat FIELDS HEADER ;
            "Fornecedor", ;
            "Pedidos" ;
            SIZE 195, 080 OF oDlg PIXEL

        If Len(aListMatExib) > 0
            oListMat:SetArray(aListMatExib)
            oListMat:bLine := {|| { ;
                aListMatExib[oListMat:nAt][1], ;
                aListMatExib[oListMat:nAt][2] }}
        EndIf

        // --- Coluna DIREITA: Servicos ---
        TSay():New(174, 215, {|| "Servicos" + cQtdSvc + " fornecedores"}, oDlg, , ;
            oFontInd, , , , .T., CLR_BLACK, , 200, 14)

        @ 190, 210 LISTBOX oListSvc FIELDS HEADER ;
            "Fornecedor", ;
            "Pedidos" ;
            SIZE 195, 080 OF oDlg PIXEL

        If Len(aListSvcExib) > 0
            oListSvc:SetArray(aListSvcExib)
            oListSvc:bLine := {|| { ;
                aListSvcExib[oListSvc:nAt][1], ;
                aListSvcExib[oListSvc:nAt][2] }}
        EndIf
    EndIf

    // ================================================================
    // GRID DE COMPRAS
    // ================================================================
    If lGeral
        TSay():New(285, 015, {|| "Detalhamento das Compras (" + cValToChar(Len(aCompras)) + " pedidos)"}, ;
            oDlg, , oFontTit, , , , .T., CLR_HBLUE, , 300, 18)

        @ 305, 010 SAY "Filtrar:" SIZE 045, 014 PIXEL OF oDlg FONT oFont
        @ 303, 055 MSGET oGetFiltro VAR cFiltro SIZE 150, 12 PIXEL OF oDlg

        @ 302, 210 BUTTON oBtnFiltrar PROMPT "Buscar" SIZE 045, 014 OF oDlg PIXEL
        oBtnFiltrar:bLClicked := {|| FiltrarGrid(cFiltro, cFiltroDesc, cFiltroStat, oListBox, oDlg)}

        @ 302, 260 BUTTON oBtnLimpar PROMPT "Limpar" SIZE 045, 014 OF oDlg PIXEL
        oBtnLimpar:bLClicked := {|| cFiltro := Space(40), cFiltroDesc := "Todos", cFiltroStat := "Todos", ;
            oGetFiltro:Refresh(), oComboDesc:Refresh(), oComboStatus:Refresh(), ;
            FiltrarGrid("", "Todos", "Todos", oListBox, oDlg)}

        @ 302, 315 BUTTON oBtnExcluir PROMPT "Excluir" SIZE 045, 014 OF oDlg PIXEL
        oBtnExcluir:bLClicked := {|| ExcluirPedido(oListBox, oDlg)}

        @ 302, 365 BUTTON oBtnRestaurar PROMPT "Restaurar" SIZE 050, 014 OF oDlg PIXEL
        oBtnRestaurar:bLClicked := {|| RestaurarPedidos(cFiltro, cFiltroDesc, cFiltroStat, oListBox, oDlg)}

        @ 321, 010 SAY "Desconto:" SIZE 042, 12 PIXEL OF oDlg FONT oFont
        @ 319, 055 MSCOMBOBOX oComboDesc VAR cFiltroDesc ITEMS aFiltrosDesc SIZE 120, 012 OF oDlg PIXEL
        oComboDesc:bChange := {|| FiltrarGrid(cFiltro, cFiltroDesc, cFiltroStat, oListBox, oDlg)}

        @ 321, 185 SAY "Entrega:" SIZE 040, 12 PIXEL OF oDlg FONT oFont
        @ 319, 225 MSCOMBOBOX oComboStatus VAR cFiltroStat ITEMS aFiltrosStat SIZE 090, 012 OF oDlg PIXEL
        oComboStatus:bChange := {|| FiltrarGrid(cFiltro, cFiltroDesc, cFiltroStat, oListBox, oDlg)}

        @ 339, 010 LISTBOX oListBox FIELDS HEADER ;
            "Pedido", ;
            "Data", ;
            "Fornecedor", ;
            "Valor Total", ;
            "Desconto", ;
            "% Desc", ;
            "Entrega" ;
            SIZE 405, 115 OF oDlg PIXEL

        oListBox:SetArray(aCompras)
        oListBox:bLine := {|| {;
            aCompras[oListBox:nAt, 1],;
            DtoC(aCompras[oListBox:nAt, 2]),;
            SubStr(aCompras[oListBox:nAt, 5], 1, 25),;
            Transform(aCompras[oListBox:nAt, 6], "@E 999,999,999.99"),;
            Transform(aCompras[oListBox:nAt, 7], "@E 999,999,999.99"),;
            Transform(aCompras[oListBox:nAt, 8], "@E 99.99") + "%",;
            aCompras[oListBox:nAt, 10] }}

        @ 459, 010 TO 477, 420 OF oDlg PIXEL
        TSay():New(462, 020, ;
            {|| "TOTAL: " + cValToChar(Len(aCompras)) + " pedidos"}, ;
            oDlg, , oFontInd, , , , .T., CLR_BLACK, , 120, 12)
        TSay():New(462, 150, ;
            {|| "R$    " + Transform(nTotCompra, "@E 999,999,999.99")}, ;
            oDlg, , oFontInd, , , , .T., CLR_BLACK, , 120, 12)
        oSayTotDesc := TSay():New(462, 280, ;
            {|| "Desc: R$ " + Transform(nTotDesc, "@E 999,999,999.99") + ;
                " (" + Transform(nPercDesc, "@E 99.99") + "%)"}, ;
            oDlg, , oFontInd, , , , .T., ;
            IIF(nPercDesc >= META_DESC, CLR_HGREEN, CLR_HRED), , 150, 12)

        @ 482, 040 BUTTON oBtnExcel PROMPT "Exportar Excel" SIZE 085, 018 OF oDlg PIXEL
        oBtnExcel:bLClicked := {|| ExportarExcel(dDtDe, dDtAte, cUsuario)}
        @ 482, 155 BUTTON oBtnVoltar PROMPT "Nova Consulta" SIZE 085, 018 OF oDlg PIXEL ;
            ACTION (oDlg:End(), U_ZCOMPRAS())
        @ 482, 275 BUTTON oBtnFechar PROMPT "Fechar" SIZE 085, 018 OF oDlg PIXEL ;
            ACTION oDlg:End()
    Else
        TSay():New(158, 015, {|| "Detalhamento das Compras (" + cValToChar(Len(aCompras)) + " pedidos)"}, ;
            oDlg, , oFontTit, , , , .T., CLR_HBLUE, , 300, 18)

        @ 178, 010 SAY "Filtrar:" SIZE 045, 014 PIXEL OF oDlg FONT oFont
        @ 176, 055 MSGET oGetFiltro VAR cFiltro SIZE 150, 12 PIXEL OF oDlg

        @ 175, 210 BUTTON oBtnFiltrar PROMPT "Buscar" SIZE 045, 014 OF oDlg PIXEL
        oBtnFiltrar:bLClicked := {|| FiltrarGrid(cFiltro, cFiltroDesc, cFiltroStat, oListBox, oDlg)}

        @ 175, 260 BUTTON oBtnLimpar PROMPT "Limpar" SIZE 045, 014 OF oDlg PIXEL
        oBtnLimpar:bLClicked := {|| cFiltro := Space(40), cFiltroDesc := "Todos", cFiltroStat := "Todos", ;
            oGetFiltro:Refresh(), oComboDesc:Refresh(), oComboStatus:Refresh(), ;
            FiltrarGrid("", "Todos", "Todos", oListBox, oDlg)}

        @ 175, 315 BUTTON oBtnExcluir PROMPT "Excluir" SIZE 045, 014 OF oDlg PIXEL
        oBtnExcluir:bLClicked := {|| ExcluirPedido(oListBox, oDlg)}

        @ 175, 365 BUTTON oBtnRestaurar PROMPT "Restaurar" SIZE 050, 014 OF oDlg PIXEL
        oBtnRestaurar:bLClicked := {|| RestaurarPedidos(cFiltro, cFiltroDesc, cFiltroStat, oListBox, oDlg)}

        @ 194, 010 SAY "Desconto:" SIZE 042, 12 PIXEL OF oDlg FONT oFont
        @ 192, 055 MSCOMBOBOX oComboDesc VAR cFiltroDesc ITEMS aFiltrosDesc SIZE 120, 012 OF oDlg PIXEL
        oComboDesc:bChange := {|| FiltrarGrid(cFiltro, cFiltroDesc, cFiltroStat, oListBox, oDlg)}

        @ 194, 185 SAY "Entrega:" SIZE 040, 12 PIXEL OF oDlg FONT oFont
        @ 192, 225 MSCOMBOBOX oComboStatus VAR cFiltroStat ITEMS aFiltrosStat SIZE 090, 012 OF oDlg PIXEL
        oComboStatus:bChange := {|| FiltrarGrid(cFiltro, cFiltroDesc, cFiltroStat, oListBox, oDlg)}

        @ 212, 010 LISTBOX oListBox FIELDS HEADER ;
            "Pedido", ;
            "Data", ;
            "Fornecedor", ;
            "Valor Total", ;
            "Desconto", ;
            "% Desc", ;
            "Entrega" ;
            SIZE 405, 115 OF oDlg PIXEL

        oListBox:SetArray(aCompras)
        oListBox:bLine := {|| {;
            aCompras[oListBox:nAt, 1],;
            DtoC(aCompras[oListBox:nAt, 2]),;
            SubStr(aCompras[oListBox:nAt, 5], 1, 25),;
            Transform(aCompras[oListBox:nAt, 6], "@E 999,999,999.99"),;
            Transform(aCompras[oListBox:nAt, 7], "@E 999,999,999.99"),;
            Transform(aCompras[oListBox:nAt, 8], "@E 99.99") + "%",;
            aCompras[oListBox:nAt, 10] }}

        @ 332, 010 TO 350, 420 OF oDlg PIXEL
        TSay():New(335, 020, ;
            {|| "TOTAL: " + cValToChar(Len(aCompras)) + " pedidos"}, ;
            oDlg, , oFontInd, , , , .T., CLR_BLACK, , 120, 12)
        TSay():New(335, 150, ;
            {|| "R$    " + Transform(nTotCompra, "@E 999,999,999.99")}, ;
            oDlg, , oFontInd, , , , .T., CLR_BLACK, , 120, 12)
        oSayTotDesc := TSay():New(335, 280, ;
            {|| "Desc: R$ " + Transform(nTotDesc, "@E 999,999,999.99") + ;
                " (" + Transform(nPercDesc, "@E 99.99") + "%)"}, ;
            oDlg, , oFontInd, , , , .T., ;
            IIF(nPercDesc >= META_DESC, CLR_HGREEN, CLR_HRED), , 150, 12)

        @ 355, 040 BUTTON oBtnExcel PROMPT "Exportar Excel" SIZE 085, 018 OF oDlg PIXEL
        oBtnExcel:bLClicked := {|| ExportarExcel(dDtDe, dDtAte, cUsuario)}
        @ 355, 155 BUTTON oBtnVoltar PROMPT "Nova Consulta" SIZE 085, 018 OF oDlg PIXEL ;
            ACTION (oDlg:End(), U_ZCOMPRAS())
        @ 355, 275 BUTTON oBtnFechar PROMPT "Fechar" SIZE 085, 018 OF oDlg PIXEL ;
            ACTION oDlg:End()
    EndIf

    ACTIVATE MSDIALOG oDlg CENTERED

    // Libera fontes
    FreeObj(oFont)
    FreeObj(oFontTit)
    FreeObj(oFontInd)
    FreeObj(oFontVal)
Return

/*/{Protheus.doc} FiltrarGrid
Filtra os pedidos exibidos no grid pelo texto digitado.
Busca em: numero do pedido, nome do fornecedor.
Filtra por nivel de desconto e status de entrega.
@type Static Function
/*/
Static Function FiltrarGrid(cFiltro, cDescFiltro, cStatFiltro, oListBox, oDlg)
    Local cBusca := AllTrim(Upper(cFiltro))
    Local cDesc  := AllTrim(cDescFiltro)
    Local cStat  := AllTrim(cStatFiltro)
    Local i
    Local lAdd

    aCompras := {}

    For i := 1 To Len(aComprasOrig)
        lAdd := .T.

        // Filtro de texto (pedido ou fornecedor)
        If !Empty(cBusca)
            If !(cBusca $ Upper(aComprasOrig[i, 1])) .And. ;
               !(cBusca $ Upper(aComprasOrig[i, 5]))
                lAdd := .F.
            EndIf
        EndIf

        // Filtro por nivel de desconto
        If lAdd .And. cDesc != "Todos"
            Do Case
                Case cDesc == "Com Desconto"
                    lAdd := (aComprasOrig[i, 7] > 0)
                Case cDesc == "Sem Desconto"
                    lAdd := (aComprasOrig[i, 7] <= 0)
                Case "Acima" $ cDesc
                    lAdd := (aComprasOrig[i, 8] >= META_DESC)
                Case "Abaixo" $ cDesc
                    lAdd := (aComprasOrig[i, 8] < META_DESC)
            EndCase
        EndIf

        // Filtro por status de entrega
        If lAdd .And. cStat != "Todos"
            Do Case
                Case cStat == "Entregue"
                    lAdd := (aComprasOrig[i, 10] == "Entregue")
                Case cStat == "Parcial"
                    lAdd := (aComprasOrig[i, 10] == "Parcial")
                Case cStat == "Pendente"
                    lAdd := (aComprasOrig[i, 10] == "Pendente")
            EndCase
        EndIf

        If lAdd
            aAdd(aCompras, aComprasOrig[i])
        EndIf
    Next i

    // Ordena conforme o filtro selecionado
    If Len(aCompras) > 1
        Do Case
            Case cDesc == "Com Desconto"
                aSort(aCompras,,, {|x,y| x[8] > y[8]})
            Case cDesc == "Sem Desconto"
                aSort(aCompras,,, {|x,y| x[6] > y[6]})
            Case "Acima" $ cDesc .Or. "Abaixo" $ cDesc
                aSort(aCompras,,, {|x,y| x[8] > y[8]})
        EndCase
    EndIf

    If Len(aCompras) == 0
        aCompras := aClone(aComprasOrig)
        MsgInfo("Nenhum pedido encontrado com os filtros aplicados.", "Filtro")
    EndIf

    // Atualiza o grid
    oListBox:nAt := 1
    oListBox:SetArray(aCompras)
    oListBox:bLine := {|| {;
        aCompras[oListBox:nAt, 1],;
        DtoC(aCompras[oListBox:nAt, 2]),;
        SubStr(aCompras[oListBox:nAt, 5], 1, 25),;
        Transform(aCompras[oListBox:nAt, 6], "@E 999,999,999.99"),;
        Transform(aCompras[oListBox:nAt, 7], "@E 999,999,999.99"),;
        Transform(aCompras[oListBox:nAt, 8], "@E 99.99") + "%",;
        aCompras[oListBox:nAt, 10] }}
    oListBox:Refresh()

    If ValType(oDlg) == "O" .And. oDlg != Nil
        oDlg:Refresh()
    EndIf
Return

/*/{Protheus.doc} ExcluirPedido
Exclui o pedido selecionado no grid do calculo de descontos.
Remove tanto da lista exibida quanto da lista base (aComprasOrig).
Recalcula os indicadores automaticamente.
@type Static Function
/*/
Static Function ExcluirPedido(oListBox, oDlg)
    Local nSel    := oListBox:nAt
    Local nI
    Local cPedido := ""
    Local cForn   := ""

    If nSel < 1 .Or. nSel > Len(aCompras)
        MsgAlert("Selecione um pedido para excluir!", "Atencao")
        Return
    EndIf

    cPedido := aCompras[nSel, 1]
    cForn   := SubStr(aCompras[nSel, 5], 1, 30)

    If !MsgYesNo("Excluir o pedido " + cPedido + " - " + AllTrim(cForn) + ;
        " do calculo de descontos?", "Confirmar Exclusao")
        Return
    EndIf

    // Remove da lista base (filtro) ANTES de mexer na exibida
    For nI := Len(aComprasOrig) To 1 Step -1
        If aComprasOrig[nI, 1] == cPedido
            aDel(aComprasOrig, nI)
            aSize(aComprasOrig, Len(aComprasOrig) - 1)
            Exit
        EndIf
    Next nI

    // Remove da lista exibida
    aDel(aCompras, nSel)
    aSize(aCompras, Len(aCompras) - 1)

    // Recalcula totais automaticamente
    RecalcularTotais()
    // Atualiza cores dos indicadores conforme nova % desconto
    AtualizarCores()
    // Atualiza tela para refletir cor/meta
    If ValType(oDlg) == "O" .And. oDlg != Nil
        oDlg:Refresh()
    EndIf

    // Ajusta posicao do cursor para nao estourar o array
    If nSel > Len(aCompras)
        nSel := Len(aCompras)
    EndIf
    If nSel < 1
        nSel := 1
    EndIf

    // Atualiza grid mantendo os dados visiveis
    oListBox:nAt := nSel
    oListBox:SetArray(aCompras)
    oListBox:bLine := {|| {;
        aCompras[oListBox:nAt, 1],;
        DtoC(aCompras[oListBox:nAt, 2]),;
        SubStr(aCompras[oListBox:nAt, 5], 1, 25),;
        Transform(aCompras[oListBox:nAt, 6], "@E 999,999,999.99"),;
        Transform(aCompras[oListBox:nAt, 7], "@E 999,999,999.99"),;
        Transform(aCompras[oListBox:nAt, 8], "@E 99.99") + "%",;
        aCompras[oListBox:nAt, 10] }}
    oListBox:Refresh()
    oDlg:Refresh()
Return

/*/{Protheus.doc} RestaurarPedidos
Restaura todos os pedidos excluidos, voltando ao resultado original da consulta.
@type Static Function
/*/
Static Function RestaurarPedidos(cFiltro, cDescFiltro, cStatFiltro, oListBox, oDlg)
    Local nExcluidos := Len(aComprasFull) - Len(aComprasOrig)

    If nExcluidos <= 0
        MsgInfo("Nenhum pedido foi excluido. Nada a restaurar.", "Restaurar")
        Return
    EndIf

    If !MsgYesNo("Restaurar " + cValToChar(nExcluidos) + " pedido(s) excluido(s)?" + ;
        Chr(13) + Chr(10) + "Os indicadores serao recalculados.", "Confirmar Restauracao")
        Return
    EndIf

    // Restaura dados originais completos
    aComprasOrig := aClone(aComprasFull)
    aCompras     := aClone(aComprasFull)

    // Recalcula totais
    RecalcularTotais()
    // Atualiza cores dos indicadores
    AtualizarCores()

    // Reaplica filtros se ativos
    If !Empty(AllTrim(cFiltro)) .Or. (AllTrim(cDescFiltro) != "Todos") .Or. (AllTrim(cStatFiltro) != "Todos")
        FiltrarGrid(cFiltro, cDescFiltro, cStatFiltro, oListBox, oDlg)
    Else
        oListBox:nAt := 1
        oListBox:SetArray(aCompras)
        oListBox:Refresh()
    EndIf

    oDlg:Refresh()
    MsgInfo("Todos os pedidos foram restaurados." + Chr(13) + Chr(10) + ;
        "Total: " + cValToChar(Len(aComprasOrig)) + " pedidos.", "Restaurado")
Return

/*/{Protheus.doc} RecalcularTotais
Recalcula os indicadores (totais, percentuais, meta) com base em aComprasOrig.
@type Static Function
/*/
Static Function RecalcularTotais()
    Local nI

    nTotCompra := 0
    nTotDesc   := 0

    For nI := 1 To Len(aComprasOrig)
        nTotCompra += aComprasOrig[nI, 6]
        nTotDesc   += aComprasOrig[nI, 7]
    Next nI

    nPercDesc := IIF(nTotCompra > 0, (nTotDesc / nTotCompra) * 100, 0)
    nMetaRS   := nTotCompra * (META_DESC / 100)
    nDifMeta  := nTotDesc - nMetaRS
Return

/*/{Protheus.doc} AtualizarCores
Atualiza dinamicamente as cores dos indicadores (TSay e TPanel) conforme
o percentual de desconto atual. Muda de vermelho para verde ao atingir a meta.
@type Static Function
/*/
Static Function AtualizarCores()
    Local nCorTexto  := 0
    Local nCorBarra  := 0
    Local nBarraLarg := 0

    // Determina cor conforme percentual vs meta
    Do Case
        Case nPercDesc >= META_DESC
            nCorTexto := CLR_HGREEN
            nCorBarra := CLR_GREEN
        Case nPercDesc >= PROX_META
            nCorTexto := RGB(180, 140, 0)
            nCorBarra := CLR_YELLOW
        Otherwise
            nCorTexto := CLR_HRED
            nCorBarra := CLR_RED
    EndCase

    // Atualiza cor do TSay "Desconto Obtido"
    If ValType(oSayDesc) == "O" .And. oSayDesc != Nil
        oSayDesc:SetColor(nCorTexto)
        oSayDesc:Refresh()
    EndIf

    // Atualiza cor do TSay "Diferenca para Meta"
    If ValType(oSayDif) == "O" .And. oSayDif != Nil
        oSayDif:SetColor(nCorTexto)
        oSayDif:Refresh()
    EndIf

    // Atualiza cor do TSay totalizador do rodape
    If ValType(oSayTotDesc) == "O" .And. oSayTotDesc != Nil
        oSayTotDesc:SetColor(IIF(nPercDesc >= META_DESC, CLR_HGREEN, CLR_HRED))
        oSayTotDesc:Refresh()
    EndIf

    // Atualiza cor da barra de progresso
    If ValType(oPnlBarraS) == "O" .And. oPnlBarraS != Nil
        nBarraLarg := Min(nPercDesc / META_DESC * 100, 150)
        nBarraLarg := Max(Int(nBarraLarg * 278 / 150), 1)
        oPnlBarraS:SetColor(, nCorBarra)
        oPnlBarraS:nWidth := Min(nBarraLarg, 278)
        oPnlBarraS:Refresh()
    EndIf

    // Atualiza cor do percentual sobre a barra
    If ValType(oSayPercBar) == "O" .And. oSayPercBar != Nil
        oSayPercBar:SetColor(IIF(nPercDesc >= META_DESC, CLR_HGREEN, CLR_HRED))
        oSayPercBar:Refresh()
    EndIf
Return

/*/{Protheus.doc} StatusEntrega
Determina o status de entrega do pedido com base nas quantidades.
Entregue = toda quantidade entregue (QUJE >= QUANT)
Parcial  = parte entregue (QUJE > 0 e QUJE < QUANT)
Pendente = nada entregue (QUJE = 0)
@type Static Function
@param nQtdPedida, Quantidade total pedida
@param nQtdEntregue, Quantidade ja entregue
@return cStatus, "Entregue", "Parcial" ou "Pendente"
/*/
Static Function StatusEntrega(nQtdPedida, nQtdEntregue)
    Local nPed := IIF(ValType(nQtdPedida) == "N", nQtdPedida, 0)
    Local nEnt := IIF(ValType(nQtdEntregue) == "N", nQtdEntregue, 0)

    If nPed <= 0
        Return "Pendente"
    EndIf

    If nEnt >= nPed
        Return "Entregue"
    ElseIf nEnt > 0
        Return "Parcial"
    EndIf
Return "Pendente"

/*/{Protheus.doc} ExportarExcel
Exporta os dados da consulta para Excel usando TReport
@type Static Function
/*/
Static Function ExportarExcel(dDtDe, dDtAte, cUsuario)
    Local oReport
    Local oSection
    Local nQtdExp := Len(aCompras)

    If nQtdExp == 0
        MsgAlert("Nenhum dado para exportar!", "Atencao")
        Return
    EndIf

    // Salva snapshot do array filtrado atual para exportacao
    aComprasExp := aClone(aCompras)

    If !MsgYesNo("Exportar " + cValToChar(nQtdExp) + " pedido(s) para Excel?", "Exportar")
        Return
    EndIf

    oReport := TReport():New("ZCOMPEXP", ;
        "Analise de Descontos - " + AllTrim(cUsuario), "", ;
        {|oReport| ImprimirExcel(oReport, dDtDe, dDtAte, cUsuario)}, ;
        "Relatorio de compras e descontos - Filial: " + cFilAnt)

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    // Secao de cabecalho / resumo
    oSection := TRSection():New(oReport, "Compras", {})

    TRCell():New(oSection, "PEDIDO",      "", "Pedido",        "@!", 10)
    TRCell():New(oSection, "DATA",        "", "Data",          "@D", 10)
    TRCell():New(oSection, "FORNECEDOR",  "", "Fornecedor",    "@!", 30)
    TRCell():New(oSection, "VLRTOTAL",    "", "Valor Total",   "@E 999,999,999.99", 15)
    TRCell():New(oSection, "VLRDESC",     "", "Desconto",      "@E 999,999,999.99", 15)
    TRCell():New(oSection, "PERCDESC",    "", "% Desc",        "@E 99.99", 8)
    TRCell():New(oSection, "ENTREGA",     "", "Entrega",       "@!", 10)

    oReport:PrintDialog()
Return

/*/{Protheus.doc} ImprimirExcel
Popula o TReport com os dados da consulta
@type Static Function
/*/
Static Function ImprimirExcel(oReport, dDtDe, dDtAte, cUsuario)
    Local oSection := oReport:Section(1)
    Local i
    Local nTotExp  := 0
    Local nDescExp := 0
    Local nPercExp := 0
    Local nMetaExp := 0
    Local nDifExp  := 0

    oReport:SetMeter(0)
    oSection:Init()

    // Calcula totais do snapshot filtrado
    For i := 1 To Len(aComprasExp)
        nTotExp  += aComprasExp[i, 6]
        nDescExp += aComprasExp[i, 7]
    Next i
    nPercExp := IIF(nTotExp > 0, (nDescExp / nTotExp) * 100, 0)
    nMetaExp := nTotExp * (META_DESC / 100)
    nDifExp  := nDescExp - nMetaExp

    // Imprime resumo no cabecalho
    oSection:SetHeaderSection(.T.)
    oReport:PrintText("Comprador: " + cUsuario + "   |   Periodo: " + ;
        DtoC(dDtDe) + " a " + DtoC(dDtAte) + ;
        "   |   Pedidos: " + cValToChar(Len(aComprasExp)) + ;
        "   |   Produtos distintos: " + cValToChar(nQtdProd), 0)
    oReport:PrintText("Total: R$ " + Transform(nTotExp, "@E 999,999,999.99") + ;
        "   |   Desconto: R$ " + Transform(nDescExp, "@E 999,999,999.99") + ;
        " (" + Transform(nPercExp, "@E 99.99") + "%)" + ;
        "   |   Meta: R$ " + Transform(nMetaExp, "@E 999,999,999.99") + " (3%)", 0)
    oReport:SkipLine()

    // Imprime detalhamento do snapshot
    For i := 1 To Len(aComprasExp)
        oSection:Cell("PEDIDO"):SetValue(aComprasExp[i, 1])
        oSection:Cell("DATA"):SetValue(aComprasExp[i, 2])
        oSection:Cell("FORNECEDOR"):SetValue(aComprasExp[i, 5])
        oSection:Cell("VLRTOTAL"):SetValue(aComprasExp[i, 6])
        oSection:Cell("VLRDESC"):SetValue(aComprasExp[i, 7])
        oSection:Cell("PERCDESC"):SetValue(aComprasExp[i, 8])
        oSection:Cell("ENTREGA"):SetValue(aComprasExp[i, 10])

        oSection:PrintLine()
        oReport:IncMeter()
    Next i

    // Linha de totais
    oReport:SkipLine()
    oReport:PrintText("TOTAL COMPRAS: R$ " + Transform(nTotExp, "@E 999,999,999.99") + ;
        "   |   Pedidos: " + cValToChar(Len(aComprasExp)) + ;
        "   |   Produtos distintos: " + cValToChar(nQtdProd), 0)
    oReport:PrintText("TOTAL DESCONTO: R$ " + Transform(nDescExp, "@E 999,999,999.99") + ;
        " (" + Transform(nPercExp, "@E 99.99") + "%)", 0)
    oReport:PrintText("META 3%: R$ " + Transform(nMetaExp, "@E 999,999,999.99") + ;
        "   |   DIFERENCA: R$ " + Transform(nDifExp, "@E 999,999,999.99"), 0)

    oSection:Finish()
Return

// =============================================================================
// GERAL SUPRIMENTOS - PEDIDOS DOS 5 COMPRADORES JUNTOS
// =============================================================================

/*/{Protheus.doc} GeralSuprimentos
Consulta todos os pedidos dos 5 compradores de Suprimentos no periodo,
juntando em uma unica visao com os mesmos indicadores e tela de resultado.
@type Static Function
@param dDtDe, Data inicial do periodo
@param dDtAte, Data final do periodo
/*/
Static Function GeralSuprimentos(dDtDe, dDtAte)
    Local aUsrCods := {"000031", "000047", "000057", "000071", "000059","000093"}
    Local cAlias   := GetNextAlias()
    Local cQuery   := ""
    Local nVlrTot, nVlrDesc, nPercIt
    Local i
    Local cClsUsr  := ""
    Local nU

    // Validacao de datas
    If Empty(dDtDe) .Or. Empty(dDtAte)
        MsgAlert("Informe o periodo completo (Data Inicial e Data Final)!", "Atencao")
        Return
    EndIf

    If dDtAte < dDtDe
        MsgAlert("Data final nao pode ser anterior a data inicial!", "Atencao")
        Return
    EndIf

    // Limpa dados anteriores
    aCompras   := {}
    nTotCompra := 0
    nTotDesc   := 0
    nPercDesc  := 0
    nQtdProd   := 0

    cQuery := " SELECT"
    cQuery += "   C7_NUM,"
    cQuery += "   C7_EMISSAO,"
    cQuery += "   C7_FORNECE,"
    cQuery += "   C7_LOJA,"
    cQuery += "   A2_NOME,"
    cQuery += "   SUM(C7_TOTAL) AS VLR_TOTAL,"
    cQuery += "   SUM(C7_VLDESC) AS VLR_DESC,"
    cQuery += "   SUM(C7_QUANT) AS QTD_ITENS,"
    cQuery += "   SUM(C7_QUANT) AS QTD_PEDIDA,"
    cQuery += "   SUM(C7_QUJE) AS QTD_ENTREGUE"
    cQuery += " FROM " + RetSqlName("SC7") + " SC7"
    cQuery += " LEFT JOIN " + RetSqlName("SA2") + " SA2"
    cQuery += "   ON SA2.D_E_L_E_T_ = ' '"
    cQuery += "   AND A2_FILIAL = '" + xFilial("SA2") + "'"
    cQuery += "   AND A2_COD = C7_FORNECE"
    cQuery += "   AND A2_LOJA = C7_LOJA"
    cQuery += " WHERE SC7.D_E_L_E_T_ = ' '"
    cQuery += "   AND C7_FILIAL = '" + xFilial("SC7") + "'"
    cQuery += "   AND C7_EMISSAO BETWEEN '" + DtoS(dDtDe) + "' AND '" + DtoS(dDtAte) + "'"
    cQuery += "   AND C7_USER IN ("
    For i := 1 To Len(aUsrCods)
        If i > 1
            cQuery += ","
        EndIf
        cQuery += "'" + aUsrCods[i] + "'"
    Next i
    cQuery += ")"
    cQuery += "   AND C7_RESIDUO <> 'S'"
    cQuery += "   AND (C7_CONAPRO = '' OR C7_CONAPRO = ' ' OR C7_CONAPRO = 'L')"
    cQuery += " GROUP BY C7_NUM, C7_EMISSAO, C7_FORNECE, C7_LOJA, A2_NOME"
    cQuery += " ORDER BY C7_EMISSAO, C7_NUM"

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        nVlrTot  := (cAlias)->VLR_TOTAL
        nVlrDesc := (cAlias)->VLR_DESC
        nPercIt  := IIF(nVlrTot > 0, Round((nVlrDesc / nVlrTot) * 100, 2), 0)

        aAdd(aCompras, {;
            AllTrim((cAlias)->C7_NUM),;
            StoD((cAlias)->C7_EMISSAO),;
            AllTrim((cAlias)->C7_FORNECE),;
            AllTrim((cAlias)->C7_LOJA),;
            AllTrim((cAlias)->A2_NOME),;
            nVlrTot,;
            nVlrDesc,;
            nPercIt,;
            (cAlias)->QTD_ITENS,;
            StatusEntrega((cAlias)->QTD_PEDIDA, (cAlias)->QTD_ENTREGUE)})

        nTotCompra += nVlrTot
        nTotDesc   += nVlrDesc

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    If Len(aCompras) == 0
        MsgAlert("Nenhum pedido encontrado para os compradores de Suprimentos no periodo!", "Atencao")
        Return
    EndIf

    // Calculos finais
    nPercDesc := IIF(nTotCompra > 0, (nTotDesc / nTotCompra) * 100, 0)
    nMetaRS   := nTotCompra * (META_DESC / 100)
    nDifMeta  := nTotDesc - nMetaRS

    // Guarda copia original para uso do filtro
    aComprasOrig := aClone(aCompras)
    aComprasFull := aClone(aCompras)

    // Monta ranking de fornecedores por tipo (todos os compradores do setor)
    cClsUsr := "C7_USER IN ('" + aUsrCods[1] + "'"
    For nU := 2 To Len(aUsrCods)
        cClsUsr += ",'" + aUsrCods[nU] + "'"
    Next nU
    cClsUsr += ")"
    MontaFornecedores(dDtDe, dDtAte, cClsUsr)

    // Conta produtos distintos adquiridos no periodo
    nQtdProd := ContaProdutosDistintos(dDtDe, dDtAte, cClsUsr)

    // Abre a mesma tela de resultados com nome "Geral Suprimentos"
    TelaResultados(dDtDe, dDtAte, "Geral Suprimentos")
Return

/*/{Protheus.doc} RelatorioGeral
Gera relatorio resumo de TODOS os compradores com indicadores de desconto.
Usa o mesmo padrao TReport.
@type Static Function
/*/
Static Function RelatorioGeral(dDtDe, dDtAte)
    Local oReport
    Local oSection
    Local aGeral   := {}  // {cMesAno, cUser, cNome, nTotal, nDesc, nPerc, nMeta, nDif, nQtd, cStatus}
    Local cQuery   := ""
    Local cAlias   := GetNextAlias()
    Local cSC7     := RetSqlName("SC7")
    Local nTotGeral := 0
    Local nDescGeral := 0
    Local cMesAno  := ""
    Local cUser    := ""
    Local cNome    := ""
    Local nTotal   := 0
    Local nDesc    := 0
    Local nPerc    := 0
    Local nMeta    := 0
    Local nDif     := 0
    Local nQtd     := 0
    Local cStatus  := ""

    // Consulta agrupada por mes + usuario
    cQuery := "SELECT "
    cQuery += "SUBSTRING(C7_EMISSAO, 1, 6) AS MES_ANO, "
    cQuery += "C7_USER, "
    cQuery += "SUM(C7_TOTAL) AS TOTAL_COMPRA, "
    cQuery += "SUM(C7_VLDESC) AS TOTAL_DESC, "
    cQuery += "COUNT(DISTINCT C7_NUM) AS QTD_PEDIDOS "
    cQuery += "FROM " + cSC7 + " SC7 "
    cQuery += "WHERE SC7.D_E_L_E_T_ = ' ' "
    cQuery += "AND SC7.C7_FILIAL = '" + xFilial("SC7") + "' "

    If !Empty(dDtDe)
        cQuery += "AND SC7.C7_EMISSAO >= '" + DtoS(dDtDe) + "' "
    EndIf
    If !Empty(dDtAte)
        cQuery += "AND SC7.C7_EMISSAO <= '" + DtoS(dDtAte) + "' "
    EndIf

    cQuery += "GROUP BY SUBSTRING(C7_EMISSAO, 1, 6), C7_USER "
    cQuery += "ORDER BY SUBSTRING(C7_EMISSAO, 1, 6), SUM(C7_TOTAL) DESC"

    TCQuery cQuery New Alias (cAlias)

    While !(cAlias)->(Eof())
        cMesAno := AllTrim((cAlias)->MES_ANO)
        cUser   := AllTrim((cAlias)->C7_USER)
        nTotal  := (cAlias)->TOTAL_COMPRA
        nDesc   := (cAlias)->TOTAL_DESC
        nPerc   := IIF(nTotal > 0, (nDesc / nTotal) * 100, 0)
        nMeta   := nTotal * (META_DESC / 100)
        nDif    := nDesc - nMeta
        nQtd    := (cAlias)->QTD_PEDIDOS
        cNome   := UsrRetName(cUser)
        cStatus := IIF(nPerc >= META_DESC, "ACIMA", IIF(nPerc >= PROX_META, "PROXIMO", "ABAIXO"))

        // {1}MesAno, {2}User, {3}Nome, {4}Total, {5}Desc, {6}%Desc, {7}Meta, {8}Dif, {9}Qtd, {10}Status
        aAdd(aGeral, {cMesAno, cUser, cNome, nTotal, nDesc, nPerc, nMeta, nDif, nQtd, cStatus})

        nTotGeral  += nTotal
        nDescGeral += nDesc

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    If Len(aGeral) == 0
        MsgAlert("Nenhum dado encontrado no periodo!", "Atencao")
        Return
    EndIf

    // Gera TReport
    oReport := TReport():New("ZCOMPGER", ;
        "Relatorio Geral - Descontos por Comprador", "", ;
        {|oReport| ImprimirGeral(oReport, dDtDe, dDtAte, aGeral, nTotGeral, nDescGeral)}, ;
        "Resumo de descontos de todos os compradores - Filial: " + cFilAnt)

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    oSection := TRSection():New(oReport, "Desempenho Mensal", {})

    TRCell():New(oSection, "TIPO",       "", "Tipo",          "@!", 12)
    TRCell():New(oSection, "CODIGO",     "", "Codigo",        "@!", 8)
    TRCell():New(oSection, "COMPRADOR",  "", "Comprador",     "@!", 25)
    TRCell():New(oSection, "MESANO",     "", "Mes/Ano",       "@!", 15)
    TRCell():New(oSection, "QTDPED",     "", "Qtd Pedidos",   "@E 9999", 8)
    TRCell():New(oSection, "VLRTOTAL",   "", "Total Compras", "@E 999,999,999.99", 15)
    TRCell():New(oSection, "VLRDESC",    "", "Total Desconto","@E 999,999,999.99", 15)
    TRCell():New(oSection, "PERCDESC",   "", "% Desc",        "@E 99.99", 8)
    TRCell():New(oSection, "META",       "", "Meta 3% (R$)",  "@E 999,999,999.99", 15)
    TRCell():New(oSection, "DIFERENCA",  "", "Diferenca",     "@E 999,999,999.99", 15)
    TRCell():New(oSection, "STATUS",     "", "Status",        "@!", 10)

    oReport:PrintDialog()
Return

/*/{Protheus.doc} NomeMes
Retorna o nome do mes a partir do numero
@type Static Function
/*/
Static Function NomeMes(nMes)
    Local aMeses := {"Janeiro","Fevereiro","Marco","Abril","Maio","Junho",;
                     "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"}
    If nMes >= 1 .And. nMes <= 12
        Return aMeses[nMes]
    EndIf
Return "Mes " + cValToChar(nMes)

/*/{Protheus.doc} ImprimirGeral
Popula o TReport geral com dados de todos os compradores, agrupado mes a mes
@type Static Function
/*/
Static Function ImprimirGeral(oReport, dDtDe, dDtAte, aGeral, nTotGeral, nDescGeral)
    Local oSection := oReport:Section(1)
    Local i, j, k
    Local nPercGeral := IIF(nTotGeral > 0, (nDescGeral / nTotGeral) * 100, 0)
    Local aUsers   := {}   // Array de compradores unicos {cUser, cNome}
    Local aUserDados := {} // Dados mensais do comprador atual
    Local cUserAtual := ""
    Local cNomeAtual := ""
    Local nTotUser, nDescUser, nPercUser, nMetaUser, nDifUser
    Local nPosUser
    Local cMesLabel := ""
    Local nMes, nAno

    oReport:SetMeter(0)
    oSection:Init()

    // Identifica compradores unicos
    For i := 1 To Len(aGeral)
        nPosUser := aScan(aUsers, {|x| x[1] == aGeral[i, 2]})
        If nPosUser == 0
            aAdd(aUsers, {aGeral[i, 2], aGeral[i, 3]})
        EndIf
    Next i

    // Ordena compradores por codigo
    If Len(aUsers) > 1
        aSort(aUsers,,, {|x,y| x[1] < y[1]})
    EndIf

    // Imprime comprador a comprador
    For k := 1 To Len(aUsers)
        cUserAtual := aUsers[k, 1]
        cNomeAtual := aUsers[k, 2]

        // Filtra dados deste comprador
        aUserDados := {}
        nTotUser   := 0
        nDescUser  := 0

        For i := 1 To Len(aGeral)
            If aGeral[i, 2] == cUserAtual
                aAdd(aUserDados, aGeral[i])
                nTotUser  += aGeral[i, 4]
                nDescUser += aGeral[i, 5]
            EndIf
        Next i

        // Ordena meses do comprador cronologicamente
        If Len(aUserDados) > 1
            aSort(aUserDados,,, {|x,y| x[1] < y[1]})
        EndIf

        nPercUser := IIF(nTotUser > 0, (nDescUser / nTotUser) * 100, 0)
        nMetaUser := nTotUser * (META_DESC / 100)
        nDifUser  := nDescUser - nMetaUser

        // Linha de cabecalho do comprador (via Cell para aparecer no Excel)
        oSection:Cell("TIPO"):SetValue(">>> COMPRADOR")
        oSection:Cell("CODIGO"):SetValue(AllTrim(cUserAtual))
        oSection:Cell("COMPRADOR"):SetValue(AllTrim(cNomeAtual))
        oSection:Cell("MESANO"):SetValue("Periodo")
        oSection:Cell("QTDPED"):SetValue(0)
        oSection:Cell("VLRTOTAL"):SetValue(nTotUser)
        oSection:Cell("VLRDESC"):SetValue(nDescUser)
        oSection:Cell("PERCDESC"):SetValue(nPercUser)
        oSection:Cell("META"):SetValue(nMetaUser)
        oSection:Cell("DIFERENCA"):SetValue(nDifUser)
        oSection:Cell("STATUS"):SetValue(IIF(nPercUser >= META_DESC, "ACIMA", IIF(nPercUser >= PROX_META, "PROXIMO", "ABAIXO")))
        oSection:PrintLine()

        // Detalhamento mes a mes do comprador
        For j := 1 To Len(aUserDados)
            nMes := Val(SubStr(aUserDados[j, 1], 5, 2))
            nAno := Val(SubStr(aUserDados[j, 1], 1, 4))
            cMesLabel := NomeMes(nMes) + "/" + cValToChar(nAno)

            oSection:Cell("TIPO"):SetValue("   Detalhe")
            oSection:Cell("CODIGO"):SetValue(AllTrim(cUserAtual))
            oSection:Cell("COMPRADOR"):SetValue(AllTrim(cNomeAtual))
            oSection:Cell("MESANO"):SetValue(cMesLabel)
            oSection:Cell("QTDPED"):SetValue(aUserDados[j, 9])
            oSection:Cell("VLRTOTAL"):SetValue(aUserDados[j, 4])
            oSection:Cell("VLRDESC"):SetValue(aUserDados[j, 5])
            oSection:Cell("PERCDESC"):SetValue(aUserDados[j, 6])
            oSection:Cell("META"):SetValue(aUserDados[j, 7])
            oSection:Cell("DIFERENCA"):SetValue(aUserDados[j, 8])
            oSection:Cell("STATUS"):SetValue(aUserDados[j, 10])

            oSection:PrintLine()
            oReport:IncMeter()
        Next j

        // Linha de subtotal do comprador
        oSection:Cell("TIPO"):SetValue("   SUBTOTAL")
        oSection:Cell("CODIGO"):SetValue(AllTrim(cUserAtual))
        oSection:Cell("COMPRADOR"):SetValue(AllTrim(cNomeAtual))
        oSection:Cell("MESANO"):SetValue(cValToChar(Len(aUserDados)) + " mes(es)")
        oSection:Cell("QTDPED"):SetValue(0)
        oSection:Cell("VLRTOTAL"):SetValue(nTotUser)
        oSection:Cell("VLRDESC"):SetValue(nDescUser)
        oSection:Cell("PERCDESC"):SetValue(nPercUser)
        oSection:Cell("META"):SetValue(nMetaUser)
        oSection:Cell("DIFERENCA"):SetValue(nDifUser)
        oSection:Cell("STATUS"):SetValue(IIF(nPercUser >= META_DESC, "ACIMA", IIF(nPercUser >= PROX_META, "PROXIMO", "ABAIXO")))
        oSection:PrintLine()
    Next k

    // Linha de total geral
    oSection:Cell("TIPO"):SetValue("=== TOTAL GERAL")
    oSection:Cell("CODIGO"):SetValue("")
    oSection:Cell("COMPRADOR"):SetValue(cValToChar(Len(aUsers)) + " comprador(es)")
    oSection:Cell("MESANO"):SetValue("")
    oSection:Cell("QTDPED"):SetValue(0)
    oSection:Cell("VLRTOTAL"):SetValue(nTotGeral)
    oSection:Cell("VLRDESC"):SetValue(nDescGeral)
    oSection:Cell("PERCDESC"):SetValue(nPercGeral)
    oSection:Cell("META"):SetValue(nTotGeral * (META_DESC / 100))
    oSection:Cell("DIFERENCA"):SetValue(nDescGeral - (nTotGeral * (META_DESC / 100)))
    oSection:Cell("STATUS"):SetValue(IIF(nPercGeral >= META_DESC, "ACIMA", "ABAIXO"))
    oSection:PrintLine()

    oSection:Finish()
Return
