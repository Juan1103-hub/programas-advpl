#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TopConn.ch"

/*/{Protheus.doc} ZMMA01
Análise de Recorrência de Compras x Mínimo/Máximo
Identifica produtos com recorrência de compras que não estão no controle de estoque
@type     function
@author   Juan
@since    2026.02.05
@version  6.2 - Botao Detalhes: aumento de valor do INICIO para o FIM do mes anterior
               (variacao do mes completo; antes comparava fim do mes com hoje e so
               pegava movimentos apos o fechamento do mes)
/*/

User Function ZMMA01()
    Local aArea := GetArea()
    Local oDlg
    Local oPanel1
    Local oPanel2
    Local oSay1, oSay3, oSay4, oSayFam, oSayCrit
    Local oGet1, oGet3
    Local oCmbAcao
    Local oBtn1, oBtn3, oBtn4, oBtnDet

    // Variaveis compartilhadas - 1 data referencia (janela fixa 3M)
    Private dDataAte := Date()
    Private cFiltroProd := Space(20)  // Filtro por produto
    Private cFiltroAcao := "TODOS"    // Filtro por acao
    Private cFiltroFam  := "TODOS"    // Filtro por familia (descricao SZ5)
    Private cFiltroCrit := "TODOS"    // Filtro por criticidade (descricao)
    Private aItens := {}                  // Array filtrado
    Private aItensFull := {}              // Array completo (antes dos filtros)
    Private aColunas := {}
    Private oBrowse
    Private oCmbFam                              // Combo filtro familia (usado em CarregaFiltrosFamCrit)
    Private oCmbCrit                             // Combo filtro criticidade (usado em CarregaFiltrosFamCrit)
    Private dIniEf := CtoD("")                // Inicio efetivo janela 3M (compartilhado ProcessaAnalise/DetalheItem)
    Private dDataFim := CtoD("")               // Fim efetivo janela 3M (ultimo dia do mes anterior)
    Private oSayEst                              // SAY do valor de estoque no cabecalho
    Private aFamiliasCache := {}                 // Cache memoizado de familias SZ5 (codigo -> descricao)
    Private nUltColOrd := 0                      // Ultima coluna clicada para ordenacao (0 = nenhuma)
    Private lUltOrdDesc := .F.                   // .T. se a ultima ordenacao foi decrescente
    // nSlopeRet removido - classificacao agora usa DOS (Days of Supply)

    // Define a tela principal
    DEFINE MSDIALOG oDlg TITLE "Analise no controle de Min/Max" FROM 000,000 TO 750,1800 PIXEL

    // Painel superior - Parametros e Filtros
    oPanel1 := TPanel():New(000, 000, "", oDlg, , , , , , 800, 055, .T., .T.)
    oPanel1:Align := CONTROL_ALIGN_TOP

    // Linha 1 - Data referencia (janela fixa 3M)
    @ 008, 010 SAY oSay1 PROMPT "Data Referencia:" SIZE 065, 007 OF oPanel1 PIXEL
    @ 006, 080 MSGET oGet1 VAR dDataAte SIZE 050, 010 OF oPanel1 PIXEL VALID !Empty(dDataAte)

    // Botoes de acao - AJUSTADO O ESPACAMENTO
    @ 006, 210 BUTTON oBtn1 PROMPT "Processar" SIZE 050, 012 OF oPanel1 PIXEL ACTION Processa({|| ProcessaAnalise()}, "Processando...")
    @ 006, 265 BUTTON oBtn3 PROMPT "Legenda" SIZE 050, 012 OF oPanel1 PIXEL ACTION MostraLegenda()
    @ 006, 320 BUTTON oBtnDet PROMPT "Detalhes" SIZE 050, 012 OF oPanel1 PIXEL ACTION ExportarDetalhes()
    @ 006, 375 BUTTON oBtn4 PROMPT "Sair" SIZE 050, 012 OF oPanel1 PIXEL ACTION oDlg:End()

    // Linha 2 - Filtros
    @ 023, 010 SAY oSay3 PROMPT "Filtro Produto:" SIZE 050, 007 OF oPanel1 PIXEL
    @ 021, 065 MSGET oGet3 VAR cFiltroProd SIZE 080, 010 OF oPanel1 PIXEL
    @ 021, 150 BUTTON "Aplicar Filtro" SIZE 050, 012 OF oPanel1 PIXEL ACTION AplicaFiltros()
    @ 021, 203 BUTTON "Limpar" SIZE 045, 012 OF oPanel1 PIXEL ACTION {||(cFiltroProd := Space(20), oGet3:VarPut(cFiltroProd), oGet3:Refresh(), cFiltroAcao := "TODOS", oCmbAcao:nAt := 1, oCmbAcao:Refresh(), cFiltroFam := "TODOS", oCmbFam:nAt := 1, oCmbFam:Refresh(), cFiltroCrit := "TODOS", oCmbCrit:nAt := 1, oCmbCrit:Refresh(), AplicaFiltros())}

    @ 023, 255 SAY oSay4 PROMPT "Filtro Acao:" SIZE 040, 007 OF oPanel1 PIXEL
    @ 021, 298 COMBOBOX oCmbAcao VAR cFiltroAcao ITEMS {"TODOS","RETIRAR DO CONTROLE","REDUZIR","MANTER","AUMENTAR","SEM SALDO ATUAL"} SIZE 100, 012 OF oPanel1 PIXEL ON CHANGE AplicaFiltros()

    @ 023, 405 SAY oSayFam PROMPT "Filtro Familia:" SIZE 055, 007 OF oPanel1 PIXEL
    @ 021, 465 COMBOBOX oCmbFam VAR cFiltroFam ITEMS CarregaFamiliasSZ5() SIZE 110, 012 OF oPanel1 PIXEL ON CHANGE AplicaFiltros()

    @ 023, 582 SAY oSayCrit PROMPT "Filtro Criticidade:" SIZE 070, 007 OF oPanel1 PIXEL
    @ 021, 656 COMBOBOX oCmbCrit VAR cFiltroCrit ITEMS {"TODOS"} SIZE 110, 012 OF oPanel1 PIXEL ON CHANGE AplicaFiltros()

    // Texto explicativo
    @ 038, 010 SAY "RETIRAR: sem consumo 3M  |  Cobertura Min/Max < 20 dias: AUMENTAR (alvo 20/40d)  |  20-40 dias: MANTER  |  > 40 dias: REDUZIR  |  Min e Max independentes  |  Saldo zerado: SEM SALDO ATUAL  |  Janela 3M" SIZE 800, 007 OF oPanel1 PIXEL FONT TFont():New(, , 10, .T.) COLOR CLR_BLUE

    // Valor de estoque (saldo x valor unitario)
    @ 046, 010 SAY oSayEst PROMPT "Valor Estoque (Custo Medio): R$ 0,00" SIZE 300, 018 OF oPanel1 PIXEL FONT TFont():New(, , 16, .T., .T.) COLOR CLR_RED

    // Painel inferior - Browse de dados
    oPanel2 := TPanel():New(000, 000, "", oDlg, , , , , , 800, 300, .T., .T.)
    oPanel2:Align := CONTROL_ALIGN_ALLCLIENT

    // Monta as colunas do browse
    MontaColunas()

    // Cria o browse
    oBrowse := FWBrowse():New()
    oBrowse:SetOwner(oPanel2)
    oBrowse:SetDataArray()
    oBrowse:SetArray(aItens)
    oBrowse:SetColumns(aColunas)
    oBrowse:DisableConfig()
    oBrowse:SetDoubleClick({|| DetalheItem()})
    oBrowse:Activate()

    ACTIVATE MSDIALOG oDlg CENTERED

    RestArea(aArea)

Return


/*/{Protheus.doc} MontaColunas
Monta as colunas do browse com os novos campos
@type     function
@author   Juan
@since    2026.02.05
/*/
Static Function MontaColunas()
    Local oColumn

    aColunas := {}

    // Coluna 1: Status (acone)
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| ""})
    oColumn:SetTitle("!")
    oColumn:SetSize(2)
    oColumn:SetAlign(CONTROL_ALIGN_CENTER)
    oColumn:SetImage(.T., {|| aItens[oBrowse:nAt][12]})
    aAdd(aColunas, oColumn)

    // Coluna 2: Produto
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][1]})
    oColumn:SetTitle("Produto")
    oColumn:SetSize(15)
    oColumn:SetAlign(CONTROL_ALIGN_LEFT)
    oColumn:bHeaderClick := {|| OrdenaBrowse(2)}
    aAdd(aColunas, oColumn)

    // Coluna 3: Descricao
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][2]})
    oColumn:SetTitle("Descricao")
    oColumn:SetSize(30)
    oColumn:SetAlign(CONTROL_ALIGN_LEFT)
    oColumn:bHeaderClick := {|| OrdenaBrowse(3)}
    aAdd(aColunas, oColumn)

    // Coluna 4: Acao Sugerida
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][11]})
    oColumn:SetTitle("Acao Sugerida")
    oColumn:SetSize(30)
    oColumn:SetAlign(CONTROL_ALIGN_LEFT)
    oColumn:bHeaderClick := {|| OrdenaBrowse(11)}
    aAdd(aColunas, oColumn)

    // Coluna 5: Dias de Estoque (DOS) - texto "N dias"
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][25]})
    oColumn:SetTitle("Dias de estoque")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_CENTER)
    oColumn:bHeaderClick := {|| OrdenaBrowse(25)}
    aAdd(aColunas, oColumn)

    // Coluna 6: Min Atual (SB1 B1_ESTSEG) - tipo numerico para ordenar ao clicar no titulo
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][3]})
    oColumn:SetTitle("Min Atual")
    oColumn:SetType("N")
    oColumn:SetPicture("@E 999,999")
    oColumn:SetSize(11)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    oColumn:bHeaderClick := {|| OrdenaBrowse(3)}
    aAdd(aColunas, oColumn)

    // Coluna 7: Max Atual (SB1 B1_EMAX) - tipo numerico para ordenar ao clicar no titulo
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][24]})
    oColumn:SetTitle("Max Atual")
    oColumn:SetType("N")
    oColumn:SetPicture("@E 999,999")
    oColumn:SetSize(11)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    oColumn:bHeaderClick := {|| OrdenaBrowse(24)}
    aAdd(aColunas, oColumn)

    // Coluna 8: Baixas 3M (SD3 TM502 janela) - tipo numerico para ordenar ao clicar no titulo
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][20]})
    oColumn:SetTitle("Baixas 3M")
    oColumn:SetType("N")
    oColumn:SetPicture("@E 999,999.99")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    oColumn:bHeaderClick := {|| OrdenaBrowse(20)}
    aAdd(aColunas, oColumn)

    // Coluna 9: Sugestao Minimo - tipo numerico para ordenar ao clicar no titulo
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][15]})
    oColumn:SetTitle("Sugestao Minimo")
    oColumn:SetType("N")
    oColumn:SetPicture("@E 999,999")
    oColumn:SetSize(14)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    oColumn:bHeaderClick := {|| OrdenaBrowse(15)}
    aAdd(aColunas, oColumn)

    // Coluna 10: Sugestao Maximo - tipo numerico para ordenar ao clicar no titulo
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][16]})
    oColumn:SetTitle("Sugestao Maximo")
    oColumn:SetType("N")
    oColumn:SetPicture("@E 999,999")
    oColumn:SetSize(14)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    oColumn:bHeaderClick := {|| OrdenaBrowse(16)}
    aAdd(aColunas, oColumn)

    // Coluna 11: Valor Unitario - tipo numerico para ordenar ao clicar no titulo
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][18]})
    oColumn:SetTitle("Valor Unitario")
    oColumn:SetType("N")
    oColumn:SetPicture("@E 9,999,999.99")
    oColumn:SetSize(15)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    oColumn:bHeaderClick := {|| OrdenaBrowse(18)}
    aAdd(aColunas, oColumn)

    // Coluna 12: Valor do estoque pelo custo medio (posicao 32 do item)
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][32]})
    oColumn:SetTitle("Valor Estoque (Custo Medio)")
    oColumn:SetType("N")
    oColumn:SetPicture("@E 9,999,999.99")
    oColumn:SetSize(15)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    // Coluna 13: Valor Total Maximo Sugerido - tipo numerico para ordenar ao clicar no titulo
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][19]})
    oColumn:SetTitle("Valor Total Max. Sug.")
    oColumn:SetType("N")
    oColumn:SetPicture("@E 9,999,999.99")
    oColumn:SetSize(15)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    oColumn:bHeaderClick := {|| OrdenaBrowse(19)}
    aAdd(aColunas, oColumn)

    // Coluna 14: Saldo Atual (SB2 B2_QATU) - tipo numerico para ordenar ao clicar no titulo
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][26]})
    oColumn:SetTitle("Saldo Atual")
    oColumn:SetType("N")
    oColumn:SetPicture("@E 999,999.99")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    oColumn:bHeaderClick := {|| OrdenaBrowse(26)}
    aAdd(aColunas, oColumn)

    // Coluna 15: Media 3M - tipo numerico para ordenar ao clicar no titulo
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][21]})
    oColumn:SetTitle("Media 3M")
    oColumn:SetType("N")
    oColumn:SetPicture("@E 999,999.99")
    oColumn:SetSize(11)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    oColumn:bHeaderClick := {|| OrdenaBrowse(21)}
    aAdd(aColunas, oColumn)

    // Coluna 16: Familia (descricao de B1_ZFAMIL via SZ5)
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][30]})
    oColumn:SetTitle("Familia")
    oColumn:SetSize(25)
    oColumn:SetAlign(CONTROL_ALIGN_LEFT)
    oColumn:bHeaderClick := {|| OrdenaBrowse(30)}
    aAdd(aColunas, oColumn)

    // Coluna 17: Criticidade (descricao de B1_ZCRIT)
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][31]})
    oColumn:SetTitle("Criticidade")
    oColumn:SetSize(18)
    oColumn:SetAlign(CONTROL_ALIGN_LEFT)
    oColumn:bHeaderClick := {|| OrdenaBrowse(31)}
    aAdd(aColunas, oColumn)

Return

/*/{Protheus.doc} CarregaFamiliasSZ5
Carrega todas as familias da SZ5 para o combo de filtro, incluindo opcao em branco.
Retorna array com TODOS, vazio, e todas as familias catalogadas (ordem alfabetica).
Chamada na inicializacao da tela para mostrar todas as familias antes de processar.
@type function
@author Juan
@since 2026.09.15
@return array - lista de itens do combo de familia
/*/
Static Function CarregaFamiliasSZ5()
    Local aFams := {"TODOS", ""}
    Local aAreaSZ5 := GetArea()

    DbSelectArea("SZ5")
    SZ5->(DbSetOrder(1))
    SZ5->(DbGoTop())
    While SZ5->(!Eof())
        If !Empty(AllTrim(SZ5->Z5_FAMIL)) .And. aScan(aFams, {|z| Upper(AllTrim(z)) == Upper(AllTrim(SZ5->Z5_FAMIL))}) == 0
            aAdd(aFams, AllTrim(SZ5->Z5_FAMIL))
        EndIf
        SZ5->(DbSkip())
    EndDo
    RestArea(aAreaSZ5)

    // Ordena em ordem alfabetica mantendo TODOS (pos 1) e vazio (pos 2) na frente
    If Len(aFams) > 2
        ASort(aFams, 3, , {|x, y| Upper(x) < Upper(y)})
    EndIf

Return aFams

/*/{Protheus.doc} CarregaFiltrosFamCrit
Popula o combo de Familia com o catalogo completo da SZ5 (descricao Z5_FAMIL)
unido as descricoes dos itens processados (pos 30) nao catalogadas, e o combo
de Criticidade com as 3 opcoes fixas (A/B/C). Sempre com TODOS na primeira opcao.
@type function
@author Juan
@since 2026.09.15
/*/
Static Function CarregaFiltrosFamCrit()
    Local nX
    Local aFams := CarregaFamiliasSZ5()
    Local aCrits := {"TODOS", "MUITO CRITICO", "CRITICIDADE MEDIA", "POUCO CRITICO"}

    // Adiciona familias dos itens processados que nao estao na SZ5
    For nX := 1 To Len(aItensFull)
        If !Empty(AllTrim(aItensFull[nX][30])) .And. aScan(aFams, {|z| Upper(AllTrim(z)) == Upper(AllTrim(aItensFull[nX][30]))}) == 0
            aAdd(aFams, AllTrim(aItensFull[nX][30]))
        EndIf
    Next nX

    oCmbFam:SetItems(aFams)
    oCmbCrit:SetItems(aCrits)
    oCmbFam:nAt := 1
    oCmbCrit:nAt := 1
    cFiltroFam := "TODOS"
    cFiltroCrit := "TODOS"
    oCmbFam:Refresh()
    oCmbCrit:Refresh()

Return

/*/{Protheus.doc} OrdenaBrowse
Ordena o array do browse pela posicao indicada (clique no cabecalho da coluna).
Primeiro clique: decrescente (maior para menor). Clique repetido: alterna
entre decrescente e crescente. Acoes (texto) ordenam alfabeticamente.
@param nPosArr - posicao do array aItens a ordenar
@type function
@author Juan
@since 2026.09.15
/*/
Static Function OrdenaBrowse(nPosArr)
    Local lDesc

    If nUltColOrd == nPosArr
        // Mesma coluna: alterna a direcao
        lUltOrdDesc := !lUltOrdDesc
    Else
        // Coluna nova: comeca decrescente (maior para menor)
        nUltColOrd  := nPosArr
        lUltOrdDesc := .T.
    EndIf
    lDesc := lUltOrdDesc

    // DOS (pos 25) agora e texto "N dias" - ordena pelo numero extraido do texto
    If nPosArr == 25
        If lDesc
            ASort(aItens, , , {|x, y| Val(StrTran(x[25], " dias", "")) > Val(StrTran(y[25], " dias", ""))})
        Else
            ASort(aItens, , , {|x, y| Val(StrTran(x[25], " dias", "")) < Val(StrTran(y[25], " dias", ""))})
        EndIf
        oBrowse:GoTop()
        oBrowse:Refresh()
        Return
    EndIf

    If ValType(aItens[1][nPosArr]) == "N"
        If lDesc
            ASort(aItens, , , {|x, y| x[nPosArr] > y[nPosArr]})
        Else
            ASort(aItens, , , {|x, y| x[nPosArr] < y[nPosArr]})
        EndIf
    Else
        If lDesc
            ASort(aItens, , , {|x, y| Upper(x[nPosArr]) > Upper(y[nPosArr])})
        Else
            ASort(aItens, , , {|x, y| Upper(x[nPosArr]) < Upper(y[nPosArr])})
        EndIf
    EndIf

    oBrowse:GoTop()
    oBrowse:Refresh()

Return

/*/{Protheus.doc} ProcessaAnalise
Processa a analise de recorrancia - Versao otimizada
@type     function
@author   Juan
@since    2026.02.05
/*/
Static Function ProcessaAnalise()
    Local aAreaProc := GetArea()
    Local cQuery
    Local cAlias := GetNextAlias()
    Local cAlias2
    Local cProduto
    Local nTotalBaixas
    Local nMesesBaixas
    Local nMediaMensal
    Local nValorUnit
    Local nValorTotal
    Local nSugMin
    Local nSugMax
    Local aClassif
    Local nCons1
    Local nCons2
    Local nCons3
    Local cTendencia
    Local cAcao
    Local cIcone
    Local nSaldoAtual
    Local nValEstCM
    Local dMes
    Local aMeses3M
    Local aConsPorMes
    Local aBaixasProd
    Local nX
    Local nPosBaixas
    Local cMesesSQL
    Local nTotalFull

    If Empty(dDataAte)
        MsgStop('Informe a Data de Referencia!', 'Atencao')
        RestArea(aAreaProc)
        Return
    EndIf
    // Janela = 3 meses COMPLETOS anteriores a Data Referencia (exclui mes corrente)
    dIniEf := PrimeiroDiaMes(MonthSub(dDataAte, 3))
    dDataFim := PrimeiroDiaMes(dDataAte) - 1  // ultimo dia do mes anterior
    aMeses3M := {}
    For nX := 3 To 1 Step -1
        dMes := MonthSub(dDataAte, nX)
        aAdd(aMeses3M, StrZero(Year(dMes),4)+StrZero(Month(dMes),2))
    Next nX
    // Monta IN clause para filtrar apenas os3 meses de aMeses3M
    cMesesSQL := ""
    For nX := 1 To Len(aMeses3M)
        If nX > 1
            cMesesSQL += ","
        EndIf
        cMesesSQL += "'" + aMeses3M[nX] + "'"
    Next nX
    aItensFull := {}
    aBaixasProd := {}
    aFamiliasCache := {}  // Cache memoizado: seek na SZ5 so no 1o acesso de cada codigo
    cQuery := " SELECT D3_COD, SUM(D3_QUANT) QTD, COUNT(DISTINCT LEFT(D3_EMISSAO,6)) MESES "
    cQuery += " FROM " + RetSqlName('SD3') + " SD3 WITH (NOLOCK) "
    cQuery += " WHERE D_E_L_E_T_ = ' ' AND D3_FILIAL='" + xFilial('SD3') + "' AND D3_TM='502' AND D3_ESTORNO <> 'S' "
    cQuery += "   AND LEFT(D3_EMISSAO,6) IN (" + cMesesSQL + ") "
    cQuery += " GROUP BY D3_COD "
    cQuery := ChangeQuery(cQuery)
    cQuery := StrTran(cQuery, "(NOLOCK)", "")              // normaliza (evita dica duplicada)
    cQuery := StrTran(cQuery, " WITH ", " WITH (NOLOCK) ") // reinjeta a dica que o ChangeQuery remove
    cAlias2 := GetNextAlias()
    DbUseArea(.T.,'TOPCONN',TCGenQry(,,cQuery),cAlias2,.F.,.T.)
    TCSetField(cAlias2,'QTD','N',12,2)
    While (cAlias2)->(!Eof())
        aAdd(aBaixasProd, {(cAlias2)->D3_COD, (cAlias2)->QTD, (cAlias2)->MESES})
        (cAlias2)->(DbSkip())
    EndDo
    (cAlias2)->(DbCloseArea())
    cQuery := " SELECT C7_PRODUTO, SUM(C7_QUANT) QTD_TOT, COUNT(*) OCORR, MIN(C7_EMISSAO) DT_INI, MAX(C7_EMISSAO) DT_FIM "
    cQuery += " FROM " + RetSqlName('SC7') + " SC7 WITH (NOLOCK) "
    cQuery += " WHERE D_E_L_E_T_ = ' ' AND C7_FILIAL='" + xFilial('SC7') + "' "
    cQuery += "   AND LEFT(C7_EMISSAO,6) IN (" + cMesesSQL + ") "
    cQuery += " GROUP BY C7_PRODUTO "
    cQuery := ChangeQuery(cQuery)
    cQuery := StrTran(cQuery, "(NOLOCK)", "")              // normaliza (evita dica duplicada)
    cQuery := StrTran(cQuery, " WITH ", " WITH (NOLOCK) ") // reinjeta a dica que o ChangeQuery remove
    cAlias := GetNextAlias()
    DbUseArea(.T.,'TOPCONN',TCGenQry(,,cQuery),cAlias,.F.,.T.)
    TCSetField(cAlias,'DT_INI','D')
    TCSetField(cAlias,'DT_FIM','D')
    While (cAlias)->(!Eof())
        cProduto := (cAlias)->C7_PRODUTO
        DbSelectArea('SB1')
        SB1->(DbSetOrder(1))
        If !SB1->(DbSeek(xFilial('SB1')+cProduto))
            (cAlias)->(DbSkip())
            Loop
        EndIf
        If AllTrim(SB1->B1_XCTAEST) != '11401200001'
            (cAlias)->(DbSkip())
            Loop
        EndIf
        // ponytail: SD3 primario - se tem baixa no periodo, deixa para loop SD3 primario tratar
        If aScan(aBaixasProd, {|x| x[1]==cProduto}) > 0
            (cAlias)->(DbSkip())
            Loop
        EndIf
        nTotalBaixas := 0
        nMesesBaixas := 0
        nPosBaixas := aScan(aBaixasProd, {|x| x[1]==cProduto})
        If nPosBaixas > 0
            nTotalBaixas := aBaixasProd[nPosBaixas][2]
            nMesesBaixas := aBaixasProd[nPosBaixas][3]
        EndIf        // Consumo por mes da janela 3M (funcao unica - antigos blocos duplicados SC7/SD3)
        aConsPorMes := GetConsPorMes(cProduto, aMeses3M)
        nCons1 := aConsPorMes[1]
        nCons2 := aConsPorMes[2]
        nCons3 := aConsPorMes[3]
        nMediaMensal := Round(nTotalBaixas / 3, 2)
        // Saldo atual (necessario para DOS)
        nSaldoAtual := 0
        nValEstCM   := 0
        DbSelectArea("SB2")
        SB2->(DbSetOrder(1))
        If SB2->(DbSeek(xFilial("SB2")+cProduto))
            While SB2->(!Eof()) .And. SB2->B2_FILIAL==xFilial("SB2") .And. SB2->B2_COD==cProduto
                nSaldoAtual += SB2->B2_QATU
                // Valor do estoque pelo custo medio (B2_CM1 x B2_QATU; sem CM, B2_VATU1)
                If SB2->B2_CM1 > 0
                    nValEstCM += SB2->B2_CM1 * SB2->B2_QATU
                Else
                    nValEstCM += SB2->B2_VATU1
                EndIf
                SB2->(DbSkip())
            EndDo
        EndIf
        // Resto fracionario (ex.: 0,001 exibido como 0,00) deve contar como saldo zerado
        nSaldoAtual := Round(nSaldoAtual, 2)
        // Classificacao por cobertura Min/Max (entre 20/40 dias)
        aClassif := ClassificarItem(nSaldoAtual, nTotalBaixas, SB1->B1_EMAX, SB1->B1_ESTSEG)
        cAcao     := aClassif[1]
        cIcone    := aClassif[2]
        nSugMin   := aClassif[3]
        nSugMax   := aClassif[4]
        cTendencia := AllTrim(Str(aClassif[5])) + " dias"
        If nTotalBaixas <= 0
            nMediaMensal := 0
            cTendencia := "SEM CONSUMO"
        EndIf
        nValorUnit  := SB1->B1_UPRC
        nValorTotal := nValorUnit * nSugMax
        aAdd(aItensFull, {cProduto, SB1->B1_DESC, SB1->B1_ESTSEG, 0, 0, CtoD(''), CtoD(''), 0, '', '', cAcao, cIcone, 0, 0, nSugMin, nSugMax, {}, nValorUnit, nValorTotal, nTotalBaixas, nMediaMensal, nMesesBaixas, 0, SB1->B1_EMAX, cTendencia, nSaldoAtual, nCons1, nCons2, nCons3, FamDescricao(SB1->B1_ZFAMIL), CritDescricao(SB1->B1_ZCRIT), nValEstCM})
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())
    For nX := 1 To Len(aBaixasProd)
        cProduto := aBaixasProd[nX][1]
        If aScan(aItensFull, {|x| x[1]==cProduto}) > 0
            Loop
        EndIf
        DbSelectArea('SB1')
        SB1->(DbSetOrder(1))
        If !SB1->(DbSeek(xFilial('SB1') + cProduto))
            Loop
        EndIf
        If AllTrim(SB1->B1_XCTAEST) != '11401200001'
            Loop
        EndIf
        nTotalBaixas := aBaixasProd[nX][2]
        nMesesBaixas := aBaixasProd[nX][3]
        // Consumo por mes da janela 3M (funcao unica - antigos blocos duplicados SC7/SD3)
        aConsPorMes := GetConsPorMes(cProduto, aMeses3M)
        nCons1 := aConsPorMes[1]
        nCons2 := aConsPorMes[2]
        nCons3 := aConsPorMes[3]
        nMediaMensal := Round(nTotalBaixas/3,2)
        nSaldoAtual := 0
        nValEstCM   := 0
        DbSelectArea("SB2")
        SB2->(DbSetOrder(1))
        If SB2->(DbSeek(xFilial("SB2")+cProduto))
            While SB2->(!Eof()) .And. SB2->B2_FILIAL==xFilial("SB2") .And. SB2->B2_COD==cProduto
                nSaldoAtual += SB2->B2_QATU
                // Valor do estoque pelo custo medio (B2_CM1 x B2_QATU; sem CM, B2_VATU1)
                If SB2->B2_CM1 > 0
                    nValEstCM += SB2->B2_CM1 * SB2->B2_QATU
                Else
                    nValEstCM += SB2->B2_VATU1
                EndIf
                SB2->(DbSkip())
            EndDo
        EndIf
        // Resto fracionario (ex.: 0,001 exibido como 0,00) deve contar como saldo zerado
        nSaldoAtual := Round(nSaldoAtual, 2)
        nValorUnit := SB1->B1_UPRC
        // Classificacao por cobertura Min/Max (entre 20/40 dias)
        aClassif := ClassificarItem(nSaldoAtual, nTotalBaixas, SB1->B1_EMAX, SB1->B1_ESTSEG)
        cAcao     := aClassif[1]
        cIcone    := aClassif[2]
        nSugMin   := aClassif[3]
        nSugMax   := aClassif[4]
        cTendencia := AllTrim(Str(aClassif[5])) + " dias"
        If nTotalBaixas <= 0
            nMediaMensal := 0
            cTendencia := "SEM CONSUMO"
        EndIf
        nValorTotal := nValorUnit * nSugMax
        aAdd(aItensFull, {cProduto, SB1->B1_DESC, SB1->B1_ESTSEG, 0, 0, CtoD(''), CtoD(''), 0, '', '', cAcao, cIcone, 0, 0, nSugMin, nSugMax, {}, nValorUnit, nValorTotal, nTotalBaixas, nMediaMensal, nMesesBaixas, 0, SB1->B1_EMAX, cTendencia, nSaldoAtual, nCons1, nCons2, nCons3, FamDescricao(SB1->B1_ZFAMIL), CritDescricao(SB1->B1_ZCRIT), nValEstCM})
    Next nX

    // Inclui demais itens CTAEST 114012 sem movimentacao na janela (para completar 392)
    // ponytail: varre SB1 para itens nao processados
    DbSelectArea("SB1")
    SB1->(DbSetOrder(1))
    SB1->(DbSeek(xFilial("SB1")))
    While SB1->(!Eof()) .And. SB1->B1_FILIAL == xFilial("SB1")
        If AllTrim(SB1->B1_XCTAEST) == "11401200001" .And. SB1->B1_MSBLQL != "1"
            cProduto := SB1->B1_COD
            If aScan(aItensFull, {|x| x[1]==cProduto}) == 0
                nSaldoAtual := 0
                nValEstCM   := 0
                DbSelectArea("SB2")
                SB2->(DbSetOrder(1))
                If SB2->(DbSeek(xFilial("SB2")+cProduto))
                    While SB2->(!Eof()) .And. SB2->B2_FILIAL==xFilial("SB2") .And. SB2->B2_COD==cProduto
                        nSaldoAtual += SB2->B2_QATU
                        // Valor do estoque pelo custo medio (B2_CM1 x B2_QATU; sem CM, B2_VATU1)
                        If SB2->B2_CM1 > 0
                            nValEstCM += SB2->B2_CM1 * SB2->B2_QATU
                        Else
                            nValEstCM += SB2->B2_VATU1
                        EndIf
                        SB2->(DbSkip())
                    EndDo
                EndIf
                // Resto fracionario (ex.: 0,001 exibido como 0,00) deve contar como saldo zerado
                nSaldoAtual := Round(nSaldoAtual, 2)
                DbSelectArea("SB1")
                nValorUnit := SB1->B1_UPRC
                cAcao  := "RETIRAR DO CONTROLE"
                cIcone := "BR_PRETO"
                nSugMin := 0
                nSugMax := 0
                nValorTotal := 0
                nTotalBaixas := 0
                nMediaMensal := 0
                nMesesBaixas := 0
        cTendencia := "SEM CONSUMO"
                aAdd(aItensFull, {cProduto, SB1->B1_DESC, SB1->B1_ESTSEG, 0, 0, CtoD(""), CtoD(""), 0, "", "", cAcao, cIcone, 0, 0, nSugMin, nSugMax, {}, nValorUnit, nValorTotal, nTotalBaixas, nMediaMensal, nMesesBaixas, 0, SB1->B1_EMAX, cTendencia, nSaldoAtual, 0, 0, 0, FamDescricao(SB1->B1_ZFAMIL), CritDescricao(SB1->B1_ZCRIT), nValEstCM})
            EndIf
        EndIf
        SB1->(DbSkip())
    EndDo
    aSort(aItensFull, , , {|x, y| CompItens(x, y)})
    RestArea(aAreaProc)

    nTotalFull := Len(aItensFull)
    If nTotalFull == 0
        aItens := {}
        MsgInfo('Nenhum produto 11401200001 encontrado na janela 3M.', 'Aviso')
        oBrowse:SetArray(aItens)
        oBrowse:Refresh()
        CalcValorEstoque()
    Else
        // Atualiza os combos de Familia/Criticidade com os valores dos itens processados
        CarregaFiltrosFamCrit()
        AplicaFiltros()
        If Len(aItens) == 0
            MsgInfo("Encontrados " + cValToChar(nTotalFull) + " produto(s) 114012, mas nenhum corresponde ao filtro '" + cFiltroAcao + "'.", "Aviso")
        Else
            MsgInfo("Encontrados " + cValToChar(nTotalFull) + " produto(s) 114012 | Exibindo " + cValToChar(Len(aItens)) + " com filtro '" + cFiltroAcao + "'. (Janela 3M: " + DtoC(dIniEf) + " a " + DtoC(dDataFim) + ")", "Sucesso")
        EndIf
    EndIf
Return

/*/{Protheus.doc} GetConsPorMes
Consulta o consumo do produto em cada mes da janela 3M (SD3, TM 502, sem
estorno) e retorna a quantidade de cada mes, na mesma ordem do array de
meses recebido. Substitui os blocos duplicados das rotas SC7 e SD3.
@param cProduto - codigo do produto
@param aMeses - meses da janela no formato AAAAMM (mais antigo ao recente)
@return array - {consumo mes 1, consumo mes 2, consumo mes 3}
@type function
@author Juan
@since 2026.09.22
/*/
Static Function GetConsPorMes(cProduto, aMeses)
    Local cQueryCons
    Local cAliasCons
    Local cMesesIn := ""
    Local aConsMes := {}
    Local aRet := {0, 0, 0}
    Local nX
    Local nPos

    For nX := 1 To Len(aMeses)
        If nX > 1
            cMesesIn += ","
        EndIf
        cMesesIn += "'" + aMeses[nX] + "'"
    Next nX

    cQueryCons := " SELECT LEFT(D3_EMISSAO,6) MES, SUM(D3_QUANT) QTD "
    cQueryCons += " FROM " + RetSqlName('SD3') + " SD3 WITH (NOLOCK) "
    cQueryCons += " WHERE D_E_L_E_T_ = ' ' AND D3_FILIAL='"+xFilial('SD3')+"' AND D3_COD='"+cProduto+"' AND D3_ESTORNO <> 'S' "
    cQueryCons += "   AND LEFT(D3_EMISSAO,6) IN (" + cMesesIn + ") AND D3_TM='502' "
    cQueryCons += " GROUP BY LEFT(D3_EMISSAO,6)"
    cQueryCons := ChangeQuery(cQueryCons)
    cQueryCons := StrTran(cQueryCons, "(NOLOCK)", "")              // normaliza (evita dica duplicada)
    cQueryCons := StrTran(cQueryCons, " WITH ", " WITH (NOLOCK) ") // reinjeta a dica que o ChangeQuery remove
    cAliasCons := GetNextAlias()
    DbUseArea(.T.,'TOPCONN',TCGenQry(,,cQueryCons),cAliasCons,.F.,.T.)
    TCSetField(cAliasCons,'QTD','N',12,2)
    While (cAliasCons)->(!Eof())
        aAdd(aConsMes, {(cAliasCons)->MES, (cAliasCons)->QTD})
        (cAliasCons)->(DbSkip())
    EndDo
    (cAliasCons)->(DbCloseArea())

    For nX := 1 To 3
        nPos := aScan(aConsMes, {|x| x[1] == aMeses[nX]})
        If nPos > 0
            aRet[nX] := aConsMes[nPos][2]
        EndIf
    Next nX

Return aRet

/*/{Protheus.doc} CompItens
Compara itens para ordenacao (substitui IIF em codeblock)
@type     function
@author   Juan
@since    2026.02.05
@param    aX, aY - arrays de itens
@return   logical - .T. se aX < aY
/*/
Static Function CompItens(aX, aY)
    Local lRet := .F.
    If aX[11] != aY[11]
        lRet := aX[11] < aY[11]
    Else
        lRet := aX[21] > aY[21]
    EndIf
Return lRet

/*/{Protheus.doc} ClassificarItem
 Classifica item em 4 categorias avaliando Minimo/Maximo em DIAS DE COBERTURA
 (valor cadastrado / media diaria de consumo), cada campo de forma INDEPENDENTE:
 - Cobertura < 20 dias  => AUMENTAR o campo (alvo: Min = 20 dias, Max = 40 dias)
 - Cobertura 20-40 dias => MANTER o campo
 - Cobertura > 40 dias  => REDUZIR o campo (alvo: Min = 20 dias, Max = 40 dias)
 Acao da linha reflete exatamente as sugestoes: aumento tem prioridade sobre
 reducao; sem consumo 3M => RETIRAR. Saldo fisico zerado => SEM SALDO ATUAL
 (prioridade de exibicao; analise dos parametros permanece na sugestao).
 Campos independentes: pode sugerir o ajuste de um e manter o outro.
 @type     function
 @author   Juan
 @since    2026.09.04
 @param    nSaldoAtual - Saldo atual em estoque (B2_QATU)
 @param    nConsumo3M - Consumo total dos ultimos 3 meses
 @param    nMaxAtual - Maximo cadastrado hoje (B1_EMAX)
 @param    nMinAtual - Minimo cadastrado hoje (B1_ESTSEG)
 @return   array - {cAcao, cIcone, nSugMin, nSugMax, nDiasEstoque}
/*/
Static Function ClassificarItem(nSaldoAtual, nConsumo3M, nMaxAtual, nMinAtual)
    Local nMediaDiaria
    Local nDiasEstoque
    Local nDiasMin
    Local nDiasMax
    Local nAlvoMin
    Local nAlvoMax
    Local nMinBase
    Local nMaxBase
    Local cAcao
    Local cIcone
    Local nSugMin
    Local nSugMax

    nDiasEstoque := 0
    nSugMin := 0
    nSugMax := 0

    // RETIRAR: zero consumo = dead stock
    If nConsumo3M <= 0
        Return {"RETIRAR DO CONTROLE", "BR_PRETO", 0, 0, 0}
    EndIf

    nMediaDiaria := nConsumo3M / 90
    nDiasEstoque := Round(nSaldoAtual / nMediaDiaria, 0)  // DOS do saldo (exibicao)

    nMinBase := Max(nMinAtual, 0)
    nMaxBase := Max(nMaxAtual, 0)

    // Dias de cobertura de cada parametro cadastrado (valor / media diaria)
    nDiasMin := Round(nMinBase / nMediaDiaria, 0)
    nDiasMax := Round(nMaxBase / nMediaDiaria, 0)

    // Avaliacao INDEPENDENTE por campo (cobertura entre 20/40 dias):
    // fora da faixa sugere o alvo do campo; dentro dela mantem o valor atual.
    // Alvos: Minimo = 20 dias de consumo, Maximo = 40 dias de consumo.
    // Abaixo da faixa: arredonda o alvo para CIMA (garante sugestao > atual);
    // acima da faixa: trunca para BAIXO (garante sugestao < atual).
    nAlvoMin := Int(nMediaDiaria * 20)
    If nAlvoMin < nMediaDiaria * 20
        nAlvoMin += 1
    EndIf
    nAlvoMax := Int(nMediaDiaria * 40)

    If nDiasMin < 20 .Or. nDiasMin > 40
        nSugMin := Max(nAlvoMin, 1)    // alvo do Minimo: 20 dias (trava: min. 1 un)
    Else
        nSugMin := nMinBase
    EndIf
    If nDiasMax < 20 .Or. nDiasMax > 40
        nSugMax := Max(nAlvoMax, 1)    // alvo do Maximo: 40 dias (trava: min. 1 un)
    Else
        nSugMax := nMaxBase
    EndIf

    // Acao da linha espelha as sugestoes (garante coerencia acao x sugestao:
    // aumento tem prioridade sobre reducao; campos independentes)
    If nSugMin > nMinBase .Or. nSugMax > nMaxBase
        cAcao  := "AUMENTAR"
        cIcone := "BR_VERMELHO"
    ElseIf nSugMin < nMinBase .Or. nSugMax < nMaxBase
        cAcao  := "REDUZIR"
        cIcone := "BR_AZUL"
    Else
        cAcao  := "MANTER"
        cIcone := "BR_VERDE"
    EndIf

    // Saldo fisico zerado tem prioridade de exibicao: item vai para a aba
    // SEM SALDO ATUAL (BR_AMARELO). As sugestoes de parametro permanecem
    // intactas para a tela de detalhe.
    If Round(nSaldoAtual, 2) == 0
        cAcao  := "SEM SALDO ATUAL"
        cIcone := "BR_AMARELO"
    EndIf

Return {cAcao, cIcone, nSugMin, nSugMax, nDiasEstoque}

/*/{Protheus.doc} MontaSugestao
Monta a sugestao do campo com a direcao correta, sem contradicao:
- Aumentar <campo> para X unidades quando o sugerido supera o atual
- Reduzir <campo> para X unidades quando o sugerido fica abaixo do atual
- Manter <campo> em X unidades quando o sugerido iguala o atual
@type     function
@author   Juan
@since    2026.09.04
@param    nSug - valor sugerido
@param    nAtual - valor atual cadastrado
@param    cCampo - "minimo" ou "maximo"
@return   character - texto da sugestao
/*/
Static Function MontaSugestao(nSug, nAtual, cCampo)
    Local cUnidade := "unidades"
    Local cRet

    nAtual := Max(nAtual, 0)

    If nSug == 1
        cUnidade := "unidade"
    EndIf

    If nSug > nAtual
        cRet := "Aumentar " + cCampo + " para " + AllTrim(Transform(nSug,"@E 9,999")) + " " + cUnidade
    ElseIf nSug < nAtual
        cRet := "Reduzir " + cCampo + " para " + AllTrim(Transform(nSug,"@E 9,999")) + " " + cUnidade
    Else
        cRet := "Manter " + cCampo + " em " + AllTrim(Transform(nSug,"@E 9,999")) + " " + cUnidade
    EndIf

Return cRet

/*/{Protheus.doc} FamDescricao
Retorna a descricao da familia a partir do codigo B1_ZFAMIL (tabela SZ5),
com cache memoizado em aFamiliasCache: o seek na SZ5 ocorre apenas no
primeiro acesso de cada codigo distinto; os demais itens reaproveitam o
resultado em memoria. Codigo inexistente na SZ5 tambem e memoizado (retorna
o proprio codigo). Se nao encontrar, retorna o proprio codigo.
@type     function
@author   Juan
@since    2026.09.15
@param    cCodFam - codigo da familia (B1_ZFAMIL)
@return   character - descricao da familia (Z5_FAMIL) ou o codigo
/*/
Static Function FamDescricao(cCodFam)
    Local cRet := AllTrim(cCodFam)
    Local aAreaSZ5 := GetArea()
    Local nPosFam

    If !Empty(cRet)
        nPosFam := aScan(aFamiliasCache, {|x| x[1] == cRet})
        If nPosFam > 0
            cRet := aFamiliasCache[nPosFam][2]
        Else
            // Primeiro acesso a este codigo: consulta SZ5 e memoiza o resultado
            DbSelectArea("SZ5")
            SZ5->(DbSetOrder(1))
            If SZ5->(DbSeek(xFilial("SZ5") + cCodFam))
                cRet := AllTrim(SZ5->Z5_FAMIL)
            EndIf
            aAdd(aFamiliasCache, {cCodFam, cRet})
        EndIf
    EndIf

    RestArea(aAreaSZ5)

Return cRet

/*/{Protheus.doc} CritDescricao
Retorna a descricao da criticidade a partir do codigo B1_ZCRIT.
A = MUITO CRITICO, B = CRITICIDADE MEDIA, C = POUCO CRITICO.
Se vazio ou invalido, retorna o proprio codigo.
@type     function
@author   Juan
@since    2026.09.15
@param    cCodCrit - codigo da criticidade (B1_ZCRIT)
@return   character - descricao da criticidade
/*/
Static Function CritDescricao(cCodCrit)
    Local cRet := AllTrim(cCodCrit)

    Do Case
        Case cCodCrit == "A"
            cRet := "MUITO CRITICO"
        Case cCodCrit == "B"
            cRet := "CRITICIDADE MEDIA"
        Case cCodCrit == "C"
            cRet := "POUCO CRITICO"
    EndCase

Return cRet

/*/{Protheus.doc} PrimeiroDiaMes
Retorna o primeiro dia do mes de uma data
@param dData - Data de referencia
@return date - Primeiro dia do mes
/*/
Static Function PrimeiroDiaMes(dData)
    Return CTOD('01/' + StrZero(Month(dData),2) + '/' + StrZero(Year(dData),4))

/*/{Protheus.doc} AplicaFiltros
Aplica filtros de produto e acao sugerida
@type function
@author Juan
@since 2026.02.05
/*/
Static Function AplicaFiltros()
    Local nX
    Local lIncluir

    aItens := {}

    For nX := 1 To Len(aItensFull)
        lIncluir := .T.

        // Filtro por ACAO SUGERIDA - comparacao por substring na acao (pos 11)
        // Acoes geradas por ClassificarItem(): AUMENTAR (min ou max com cobertura < 20 dias),
        // MANTER (ambos entre 20/40 dias), REDUZIR (min ou max com cobertura > 40 dias),
        // RETIRAR (sem consumo 3M) e SEM SALDO ATUAL (saldo fisico zerado, com consumo)
        // Opcao especial SEM SALDO ATUAL: filtra pelo saldo (pos 26 = B2_QATU) zerado
        If cFiltroAcao == "TODOS"
            lIncluir := .T.
        ElseIf cFiltroAcao == "SEM SALDO ATUAL"
            // Round: trata resto fracionario (ex.: 0,001 exibido como 0,00) como saldo zerado
            If Round(aItensFull[nX][26], 2) != 0
                lIncluir := .F.
            EndIf
        ElseIf "RETIRAR" $ Upper(cFiltroAcao)
            If !("RETIRAR" $ Upper(aItensFull[nX][11]))
                lIncluir := .F.
            EndIf
        ElseIf "REDUZIR" $ Upper(cFiltroAcao)
            If !("REDUZIR" $ Upper(aItensFull[nX][11]))
                lIncluir := .F.
            EndIf
        ElseIf "MANTER" $ Upper(cFiltroAcao)
            If !("MANTER" $ Upper(aItensFull[nX][11]))
                lIncluir := .F.
            EndIf
        ElseIf "AUMENTAR" $ Upper(cFiltroAcao)
            If !("AUMENTAR" $ Upper(aItensFull[nX][11]))
                lIncluir := .F.
            EndIf
        Else
            If !(AllTrim(cFiltroAcao) $ Upper(aItensFull[nX][11]))
                lIncluir := .F.
            EndIf
        EndIf

        // Filtro por codigo OU descricao do produto (case-insensitive)
        If lIncluir .And. !Empty(AllTrim(cFiltroProd))
            If !(Upper(AllTrim(cFiltroProd)) $ Upper(aItensFull[nX][1])) .And. ;
               !(Upper(AllTrim(cFiltroProd)) $ Upper(aItensFull[nX][2]))
                lIncluir := .F.
            EndIf
        EndIf

        // Filtro por familia (descricao na pos 30; vazio so passa em TODOS)
        If lIncluir .And. cFiltroFam != "TODOS"
            If Upper(AllTrim(aItensFull[nX][30])) != Upper(AllTrim(cFiltroFam))
                lIncluir := .F.
            EndIf
        EndIf

        // Filtro por criticidade (descricao na pos 31; vazio so passa em TODOS)
        If lIncluir .And. cFiltroCrit != "TODOS"
            If Upper(AllTrim(aItensFull[nX][31])) != Upper(AllTrim(cFiltroCrit))
                lIncluir := .F.
            EndIf
        EndIf

        If lIncluir
            aAdd(aItens, aClone(aItensFull[nX]))
        EndIf
    Next nX

    oBrowse:SetArray(aItens)
    oBrowse:GoTop()
    oBrowse:Refresh()
    CalcValorEstoque()

Return

/*/{Protheus.doc} MostraLegenda
Exibe legenda completa da analise de Estoque Minimo e Maximo por cobertura de
consumo, em janela com area de rolagem vertical (o texto completo nunca e cortado,
independentemente da escala de tela do ambiente)
@type function
@author Juan
@since 2026.09.21
/*/
Static Function MostraLegenda()
    Local oDlgLeg
    Local oScroll
    Local oBmp
    Local oBtnFechar

    // Janela com area rolavel (TScrollBox): o texto completo da legenda nunca e
    // cortado, em qualquer resolucao/escala. Linhas estaticas (literais), sem loop
    // nem codeblock indexado, que causava "array out of bounds" no ACTIVATE.
    // Botao Fechar fora da area de rolagem, sempre visivel.
    // Textos sem abreviacoes e sem termos em ingles (regra de idioma do AGENTS.md).
    DEFINE MSDIALOG oDlgLeg TITLE "Legenda da Analise de Estoque" FROM 000,000 TO 720,560 PIXEL

        @ 004, 008 SCROLLBOX oScroll SIZE 674, 544 OF oDlgLeg VERTICAL

        // Conceito e objetivos
        @ 010, 010 SAY "Cobertura de Consumo = Quantidade cadastrada / Consumo medio diario" SIZE 510, 010 OF oScroll PIXEL
        @ 022, 010 SAY "(saidas dos ultimos 3 meses / 90 dias)." SIZE 510, 010 OF oScroll PIXEL

        @ 042, 010 SAY "Objetivos:" SIZE 510, 010 OF oScroll PIXEL
        @ 054, 010 SAY "Estoque Minimo: 20 dias de consumo" SIZE 510, 010 OF oScroll PIXEL
        @ 066, 010 SAY "Estoque Maximo: 40 dias de consumo" SIZE 510, 010 OF oScroll PIXEL
        @ 078, 010 SAY "A coluna Dias de Cobertura do Saldo Atual indica a situacao" SIZE 510, 010 OF oScroll PIXEL
        @ 090, 010 SAY "do estoque fisico disponivel." SIZE 510, 010 OF oScroll PIXEL

        // AUMENTAR - icone vermelho, igual ao browse
        @ 114, 010 BITMAP oBmp RESOURCE "BR_VERMELHO" SIZE 010, 010 OF oScroll PIXEL NOBORDER
        @ 114, 028 SAY "AUMENTAR" SIZE 490, 010 OF oScroll PIXEL
        @ 128, 010 SAY "Cobertura abaixo do objetivo." SIZE 510, 010 OF oScroll PIXEL
        @ 140, 010 SAY "Risco de falta de material." SIZE 510, 010 OF oScroll PIXEL
        @ 152, 010 SAY "Ajustar o Estoque Minimo para 20 dias e o Estoque Maximo para 40 dias." SIZE 510, 010 OF oScroll PIXEL

        // REDUZIR - icone azul, igual ao browse
        @ 178, 010 BITMAP oBmp RESOURCE "BR_AZUL" SIZE 010, 010 OF oScroll PIXEL NOBORDER
        @ 178, 028 SAY "REDUZIR" SIZE 490, 010 OF oScroll PIXEL
        @ 192, 010 SAY "Cobertura acima de 40 dias." SIZE 510, 010 OF oScroll PIXEL
        @ 204, 010 SAY "Estoque excessivo e capital parado." SIZE 510, 010 OF oScroll PIXEL
        @ 216, 010 SAY "Reduzir o Estoque Minimo para 20 dias e o Estoque Maximo para 40 dias." SIZE 510, 010 OF oScroll PIXEL

        // MANTER - icone verde, igual ao browse
        @ 242, 010 BITMAP oBmp RESOURCE "BR_VERDE" SIZE 010, 010 OF oScroll PIXEL NOBORDER
        @ 242, 028 SAY "MANTER" SIZE 490, 010 OF oScroll PIXEL
        @ 256, 010 SAY "Cobertura entre 20 e 40 dias." SIZE 510, 010 OF oScroll PIXEL
        @ 268, 010 SAY "Parametros adequados." SIZE 510, 010 OF oScroll PIXEL
        @ 280, 010 SAY "Nenhuma acao necessaria." SIZE 510, 010 OF oScroll PIXEL

        // RETIRAR DO CONTROLE - icone preto, igual ao browse
        @ 306, 010 BITMAP oBmp RESOURCE "BR_PRETO" SIZE 010, 010 OF oScroll PIXEL NOBORDER
        @ 306, 028 SAY "RETIRAR DO CONTROLE" SIZE 490, 010 OF oScroll PIXEL
        @ 320, 010 SAY "Sem consumo nos ultimos 3 meses." SIZE 510, 010 OF oScroll PIXEL
        @ 332, 010 SAY "Zerar Estoque Minimo e Estoque Maximo." SIZE 510, 010 OF oScroll PIXEL
        @ 344, 010 SAY "Avaliar a necessidade de manter o item ativo e estocado." SIZE 510, 010 OF oScroll PIXEL

        // Botao Fechar fixo fora da area de rolagem, sempre visivel
        @ 692, 490 BUTTON oBtnFechar PROMPT "Fechar" SIZE 060, 018 OF oDlgLeg PIXEL ACTION oDlgLeg:End()

    ACTIVATE MSDIALOG oDlgLeg CENTERED

Return
/*/{Protheus.doc} DetalheItem
Exibe detalhes do item selecionado
@type function
/*/
Static Function DetalheItem()
    Local oDlgDet
    Local oPanel
    Local nLinha
    Local cAcao
    Local cProd
    Local cDesc
    Local cMotivo
    Local cMotivo2
    Local cMotivo3
    Local nValAtu
    Local nValSug
    Local nDelta
    Local cDeltaTxt
    Local nC1
    Local nC2
    Local nC3
    Local cRegraCalc
    Local nSaldoCalc
    Local nConsCalc
    Local nMediaCalc
    Local nDiasCalc
    Local nDiasMinCalc
    Local nDiasMaxCalc
    Local cVerMin
    Local cVerMax
    Local aNomesMes
    Local dMes1
    Local dMes2
    Local dMes3

    If Len(aItens) == 0
        Return
    EndIf

    nLinha := oBrowse:nAt
    cAcao  := aItens[nLinha][11]
    cProd  := AllTrim(aItens[nLinha][1])
    cDesc  := AllTrim(aItens[nLinha][2])  // descricao completa, sem corte
    If Len(aItens[nLinha])>=27
        nC1 := aItens[nLinha][27]
    Else
        nC1 := 0
    EndIf
    If Len(aItens[nLinha])>=28
        nC2 := aItens[nLinha][28]
    Else
        nC2 := 0
    EndIf
    If Len(aItens[nLinha])>=29
        nC3 := aItens[nLinha][29]
    Else
        nC3 := 0
    EndIf
    // Monta texto da regra DOS aplicada
    cRegraCalc := ""
    If "RETIRAR" $ Upper(cAcao)
        cRegraCalc := "DOS = 0 dias | Sem consumo 3M = RETIRAR"
    Else
        nSaldoCalc := aItens[nLinha][26]
        nConsCalc  := aItens[nLinha][20]
        nMediaCalc := nConsCalc / 90
        If nMediaCalc > 0
            nDiasCalc := Round(nSaldoCalc / nMediaCalc, 0)
            cRegraCalc := AllTrim(Transform(nSaldoCalc,"@E 9,999,999")) + " / (" + AllTrim(Transform(nConsCalc,"@E 9,999,999")) + " / 90) = " + AllTrim(Transform(nDiasCalc,"@E 9,999")) + " dias (saldo)"
            // Cobertura de cada parametro em dias (avaliacao independente entre 20/40)
            nDiasMinCalc := Round(Max(aItens[nLinha][3], 0) / nMediaCalc, 0)
            nDiasMaxCalc := Round(Max(aItens[nLinha][24], 0) / nMediaCalc, 0)
            cRegraCalc += " | Min: " + AllTrim(Transform(nDiasMinCalc, "@E 9,999")) + "d"
            cRegraCalc += " | Max: " + AllTrim(Transform(nDiasMaxCalc, "@E 9,999")) + "d"
            cRegraCalc += " => " + AllTrim(cAcao)
        Else
            cRegraCalc := "Sem consumo 3M = RETIRAR"
        EndIf
    EndIf

    // Valor financeiro: maximo atual vs maximo sugerido x valor unitario
    nValAtu := aItens[nLinha][18] * aItens[nLinha][24]
    nValSug := aItens[nLinha][18] * aItens[nLinha][16]
    nDelta  := nValSug - nValAtu
    If aItens[nLinha][16] == 0
        cDeltaTxt := "(RETIRADA)"
    ElseIf nDelta > 0
        cDeltaTxt := "(AUMENTO R$ " + AllTrim(Transform(Abs(nDelta),"@E 9,999,999.99")) + ")"
    ElseIf nDelta < 0
        cDeltaTxt := "(REDUCAO R$ " + AllTrim(Transform(Abs(nDelta),"@E 9,999,999.99")) + ")"
    Else
        cDeltaTxt := "(SEM ALTERACAO)"
    EndIf
    // Monta motivo detalhado - avaliacao INDEPENDENTE por campo (entre 20/40 dias):
    // uma linha por parametro com a cobertura em dias, o veredito e a sugestao
    cMotivo := ""
    cMotivo2 := ""
    cMotivo3 := ""
    If "RETIRAR" $ Upper(cAcao)
        cMotivo := "Item sem consumo nos ultimos 3 meses. Candidato a descontinuacao ou transferencia."
    ElseIf nMediaCalc > 0
        If nDiasMinCalc < 20
            cVerMin := "AUMENTAR (abaixo de 20d)"
        ElseIf nDiasMinCalc > 40
            If aItens[nLinha][15] < aItens[nLinha][3]
                cVerMin := "REDUZIR (acima de 40d)"
            Else
                // Alvo arredondou para o proprio valor atual (min. sugerivel = 1 un) - nada a reduzir
                cVerMin := "REDUZIR (acima de 40d, ja no minimo sugerivel)"
            EndIf
        Else
            cVerMin := "MANTER (entre 20/40 dias)"
        EndIf
        If nDiasMaxCalc < 20
            cVerMax := "AUMENTAR (abaixo de 20d)"
        ElseIf nDiasMaxCalc > 40
            If aItens[nLinha][16] < aItens[nLinha][24]
                cVerMax := "REDUZIR (acima de 40d)"
            Else
                // Alvo arredondou para o proprio valor atual (min. sugerivel = 1 un) - nada a reduzir
                cVerMax := "REDUZIR (acima de 40d, ja no minimo sugerivel)"
            EndIf
        Else
            cVerMax := "MANTER (entre 20/40 dias)"
        EndIf
        cMotivo := "Minimo: " + AllTrim(Transform(nDiasMinCalc,"@E 9,999")) + " dias de cobertura => " + cVerMin
        cMotivo += " - " + MontaSugestao(aItens[nLinha][15], aItens[nLinha][3], "minimo") + "."
        cMotivo2 := "Maximo: " + AllTrim(Transform(nDiasMaxCalc,"@E 9,999")) + " dias de cobertura => " + cVerMax
        cMotivo2 += " - " + MontaSugestao(aItens[nLinha][16], aItens[nLinha][24], "maximo") + "."
    Else
        cMotivo := AllTrim(cAcao)
    EndIf
    // SEM SALDO ATUAL: aviso de reposicao na 1a linha; a analise pelo
    // Minimo/Maximo cadastrado (cada campo em uma linha) segue completa
    // nas linhas seguintes, sem corte de texto
    If "SEM SALDO ATUAL" $ Upper(cAcao)
        cMotivo3 := cMotivo2
        cMotivo2 := cMotivo
        cMotivo  := "Item sem saldo fisico em estoque - avaliar reposicao. Sugestao pelo Minimo/Maximo cadastrado:"
    EndIf

    // Monta nomes dos meses para exibicao em linhas separadas
    aNomesMes := {"janeiro","fevereiro","marco","abril","maio","junho",;
                  "julho","agosto","setembro","outubro","novembro","dezembro"}
    dMes1 := MonthSub(dDataAte, 3)  // mes mais antigo da janela (ex: Junho)
    dMes2 := MonthSub(dDataAte, 2)  // mes intermediario (ex: Julho)
    dMes3 := MonthSub(dDataAte, 1)  // mes mais recente da janela (ex: Agosto)

    DEFINE MSDIALOG oDlgDet TITLE "Produto: " + cProd FROM 000,000 TO 570,700 PIXEL

        oPanel := TPanel():New(000, 000, "", oDlgDet, , , , , , 700, 570, .F., .F.)
        oPanel:Align := CONTROL_ALIGN_ALLCLIENT

        // === IDENTIFICACAO ===
        @ 005, 010 SAY cProd + "  |  " + cDesc SIZE 690, 008 OF oPanel PIXEL
        @ 015, 010 SAY ">> " + cAcao           SIZE 680, 008 OF oPanel PIXEL
        @ 025, 008 SAY Replicate("=", 105)      SIZE 690, 006 OF oPanel PIXEL

        // === COLUNA ESQUERDA: JANELA 3M / CONSUMO ===
        @ 033, 010 SAY "[ JANELA 3M - CONSUMO ]"                                             SIZE 340, 008 OF oPanel PIXEL
        @ 043, 010 SAY "Dias de Estoque (DOS)    :"                                          SIZE 125, 008 OF oPanel PIXEL
        @ 043, 138 SAY aItens[nLinha][25]                                                    SIZE 200, 008 OF oPanel PIXEL
        @ 053, 010 SAY "Regra:                   :"                                          SIZE 125, 008 OF oPanel PIXEL COLOR CLR_BLUE
        @ 053, 138 SAY cRegraCalc                                                            SIZE 550, 008 OF oPanel PIXEL COLOR CLR_BLUE
        @ 063, 010 SAY "Saldo Atual              :"                                          SIZE 125, 008 OF oPanel PIXEL
        @ 063, 138 SAY Transform(aItens[nLinha][26], "@E 9,999,999.99") + " un"              SIZE 200, 008 OF oPanel PIXEL
        @ 073, 010 SAY "Baixas nos ultimos 3M    :"                                          SIZE 125, 008 OF oPanel PIXEL
        @ 073, 138 SAY Transform(aItens[nLinha][20], "@E 9,999,999.99") + " un"             SIZE 200, 008 OF oPanel PIXEL
        @ 083, 010 SAY "Media mensal 3M          :"                                          SIZE 125, 008 OF oPanel PIXEL
        @ 083, 138 SAY Transform(aItens[nLinha][21], "@E 9,999,999.99") + " un/mes"         SIZE 200, 008 OF oPanel PIXEL
        @ 093, 010 SAY "Meses com baixas         :"                                          SIZE 125, 008 OF oPanel PIXEL
        @ 093, 138 SAY cValToChar(aItens[nLinha][22]) + " / 3 meses"                         SIZE 200, 008 OF oPanel PIXEL
        @ 103, 010 SAY "Valor unitario           :"                                          SIZE 125, 008 OF oPanel PIXEL
        @ 103, 138 SAY "R$ " + Transform(aItens[nLinha][18], "@E 9,999,999.99")              SIZE 200, 008 OF oPanel PIXEL
        @ 113, 010 SAY "Janela considerada       :"                                          SIZE 125, 008 OF oPanel PIXEL
        @ 113, 138 SAY DtoC(dIniEf) + " a " + DtoC(dDataFim)                  SIZE 200, 008 OF oPanel PIXEL
        @ 123, 010 SAY "Minimo atual             :"                                          SIZE 125, 008 OF oPanel PIXEL
        @ 123, 138 SAY Transform(aItens[nLinha][3], "@E 9,999,999")                          SIZE 200, 008 OF oPanel PIXEL
        @ 133, 010 SAY "Maximo atual             :"                                          SIZE 125, 008 OF oPanel PIXEL
        @ 133, 138 SAY Transform(aItens[nLinha][24], "@E 9,999,999")                         SIZE 200, 008 OF oPanel PIXEL
        @ 143, 010 SAY "Baixas por mes           :"                                          SIZE 125, 008 OF oPanel PIXEL
        @ 143, 138 SAY AllTrim(aNomesMes[Month(dMes1)]) + ": " + AllTrim(Transform(nC1,"@E 999,999.99")) + "  " + AllTrim(aNomesMes[Month(dMes2)]) + ": " + AllTrim(Transform(nC2,"@E 999,999.99")) + "  " + AllTrim(aNomesMes[Month(dMes3)]) + ": " + AllTrim(Transform(nC3,"@E 999,999.99")) SIZE 550, 008 OF oPanel PIXEL

        // === BLOCO 2: PARAMETRIZACAO ===
        @ 155, 010 SAY Replicate("-", 97)       SIZE 640, 006 OF oPanel PIXEL
        @ 163, 010 SAY "[ PARAMETRIZACAO SUGERIDA ]"                                         SIZE 630, 008 OF oPanel PIXEL
        @ 173, 010 SAY "Minimo sugerido            :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 173, 138 SAY Transform(aItens[nLinha][15], "@E 9,999,999")                         SIZE 172, 008 OF oPanel PIXEL
        @ 183, 010 SAY "Maximo sugerido            :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 183, 138 SAY Transform(aItens[nLinha][16], "@E 9,999,999")                         SIZE 172, 008 OF oPanel PIXEL
        @ 193, 010 SAY "Valor com maximo atual     :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 193, 138 SAY "R$ " + Transform(nValAtu, "@E 9,999,999.99") + " (" + AllTrim(Transform(aItens[nLinha][24],"@E 999,999")) + " x R$ " + AllTrim(Transform(aItens[nLinha][18],"@E 9,999.99")) + ")" SIZE 380, 008 OF oPanel PIXEL
        @ 203, 010 SAY "Valor com maximo sugerido  :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 203, 138 SAY "R$ " + Transform(nValSug, "@E 9,999,999.99") + " (" + AllTrim(Transform(aItens[nLinha][16],"@E 999,999")) + " x R$ " + AllTrim(Transform(aItens[nLinha][18],"@E 9,999.99")) + ") " + Left(cDeltaTxt,30) SIZE 380, 008 OF oPanel PIXEL
        @ 215, 010 SAY "Motivo:"                                                            SIZE 630, 008 OF oPanel PIXEL COLOR CLR_HRED
        @ 225, 010 SAY cMotivo                                                             SIZE 630, 008 OF oPanel PIXEL
        @ 234, 010 SAY cMotivo2                                                            SIZE 630, 008 OF oPanel PIXEL
        @ 243, 010 SAY cMotivo3                                                            SIZE 630, 008 OF oPanel PIXEL

        // === NOTA JANELA ===
        @ 256, 008 SAY Replicate("=", 97)     SIZE 640, 006 OF oPanel PIXEL
        @ 264, 010 SAY "Janela 3M: " + DtoC(dIniEf) + " a " + DtoC(dDataFim) + " | 3 meses completos anteriores a Data Referencia" SIZE 630, 008 OF oPanel PIXEL

    ACTIVATE MSDIALOG oDlgDet CENTERED

Return


/*/{Protheus.doc} ExportarDetalhes
Gera relatorio (dialogo padrao: impressora, PDF, HTML ou planilha/Excel) com os
itens filtrados no browse cujo ESTOQUE aumentou no mes anterior completo (do
saldo de abertura em 01/MM para o fechamento no fim do mes). A SELECAO e por
QUANTIDADE: entra o item cujo saldo do fim do mes e maior que o saldo de
abertura, seja o valor em R$ maior ou menor (um Custo Medio menor pode reduzir
o valor mesmo com o estoque maior). Para cada item mostra a variacao do valor em
estoque (R$) e o motivo em frase clara (entradas, saidas e variacao do Custo
Medio), do maior para o menor efeito em R$. No rodape, a soma das variacoes de
valor em estoque no mes.

Fonte de dados: SD3 (D3_TM <= 499 = entrada, D3_TM > 499 = saida; regra canonica
MovIntFis do Protheus) + SD1 (NF de entrada, que NAO gera SD3), sem estorno e
sem delecao. No SD1 entra somente TES que movimenta estoque (F4_ESTOQUE = 'S');
D1_TIPO = 'D' (devolucao de compra) e contado como saida, nao como entrada.
F4_TIPO NAO classifica entrada/saida (e o tipo do TES: P=produto, S=servico);
usar esse campo quebrava a separacao: nenhuma NF de compra caia no ramo de
entrada, entao o preco de compra do mes nunca era lido (colunas de Valor
Unitario ficavam iguais) e as compras eram somadas como SAIDA. Mesmo padrao
do ZSLDEST: toda linha SD1 com TES que movimenta estoque e entrada, exceto
devolucao (D1_TIPO = 'D').
Saldo no inicio do mes: valor REAL do fechamento mensal do estoque (SB9, saldo
de abertura do mes); itens sem fechamento no mes, ou com fechamento que nao
explica o saldo atual, usam saldo estimado a partir do saldo atual (SB2)
corrigido pelo movimento posterior ao mes.
@type function
@author Juan
@since 2026.10.01
/*/
Static Function ExportarDetalhes()
    Local aAreaExp   := GetArea()
    Local cQueryDet  := ""
    Local cAliasDet  := GetNextAlias()
    Local dIniMes    := CtoD("")
    Local dFimMes    := CtoD("")
    Local cProdExp   := ""
    Local aMovsDet   := {}
    Local aRegs      := {}
    Local aSB2Exp    := {}
    Local nX         := 0
    Local nPosDet    := 0
    Local nEntPos    := 0
    Local nSaiPos    := 0
    Local nSB2Qtd    := 0
    Local nSB2Pos    := 0
    Local nSaldoIni  := 0
    Local nEntMes    := 0
    Local nSaiMes    := 0
    Local nSaldoFim  := 0
    Local nValIni    := 0
    Local nValFim    := 0
    Local nValDif    := 0
    Local nUnidDif   := 0
    Local nPrecoMesU := 0
    Local cMotivo    := ""
    Local oReport    := Nil
    Local oSection   := Nil
    Local nPrecoMes  := 0
    Local nPrecoAtu  := 0
    Local dPrecoDia  := CtoD("")
    Local aSB9Exp    := {}
    Local lB9Data    := .F.
    Local lB9MesAno  := .F.
    Local cB9Qtd     := ""
    Local cB9Vlr     := ""
    Local lB9Qfim    := .F.
    Local dLimB9     := CtoD("")
    Local lSaldoReal := .F.
    Local nPosB9     := 0
    Local nSaldoCalc := 0
    Local lCMReal    := .F.
    Local nCMMesAnt  := 0
    Local nCMAtu     := 0
    Local nCMAbertura := 0
    Local nSomaAum    := 0
    Local nQtdAum     := 0
    Local nSomaQueda  := 0
    Local nQtdQueda   := 0
    Local nSomaParado := 0
    Local nQtdParado  := 0
    Local nValIniAll  := 0
    Local nValFimAll  := 0
    Local aTotais     := {}
    Local oSecRec     := Nil

    If Len(aItens) == 0
        MsgStop("Processe a analise antes de exportar os detalhes (botao Processar).", "Detalhes")
        RestArea(aAreaExp)
        Return
    EndIf

    // Mes anterior completo (ex.: data referencia em out/2026 => 01/09 a 30/09/2026)
    dIniMes := PrimeiroDiaMes(MonthSub(dDataAte, 1))
    dFimMes := PrimeiroDiaMes(dDataAte) - 1

    // 1) Movimentos do mes anterior ate a data de referencia:
    //    SD3 (movimentos internos: TM<=499 entrada, TM>499 saida) +
    //    SD1 (NF de entrada com TES que movimenta estoque). Toda linha SD1
    //    conta como ENTRADA, exceto devolucao de compra (D1_TIPO = 'D'),
    //    que conta como SAIDA, mesmo padrao do ZSLDEST. Nao usar F4_TIPO
    //    aqui: e o tipo do TES (P=produto), nao o sentido do movimento.
    cQueryDet := " SELECT MOV.COD, MOV.TIPO, MOV.QTD, MOV.DATA, MOV.VUNIT FROM ( "
    cQueryDet += " SELECT D3_COD COD, CASE WHEN D3_TM <= '499' THEN 'E' ELSE 'S' END TIPO, D3_QUANT QTD, D3_EMISSAO DATA, 0 VUNIT "
    cQueryDet += " FROM " + RetSqlName("SD3") + " SD3 WITH (NOLOCK) "
    cQueryDet += " WHERE D_E_L_E_T_ = ' ' AND D3_FILIAL = '" + xFilial("SD3") + "' AND D3_ESTORNO <> 'S' AND D3_QUANT > 0 "
    cQueryDet += "   AND D3_EMISSAO >= '" + DtoS(dIniMes) + "' AND D3_EMISSAO <= '" + DtoS(dDataAte) + "' "
    cQueryDet += " UNION ALL "
    cQueryDet += " SELECT D1_COD COD, CASE WHEN D1_TIPO = 'D' THEN 'S' ELSE 'E' END TIPO, D1_QUANT QTD, D1_DTDIGIT DATA, D1_VUNIT VUNIT "
    cQueryDet += " FROM " + RetSqlName("SD1") + " SD1 WITH (NOLOCK) "
    cQueryDet += " INNER JOIN " + RetSqlName("SF4") + " SF4 WITH (NOLOCK) "
    cQueryDet += "   ON F4_FILIAL = '" + xFilial("SF4") + "' AND F4_CODIGO = D1_TES AND SF4.D_E_L_E_T_ = ' ' "
    cQueryDet += " WHERE SD1.D_E_L_E_T_ = ' ' AND D1_FILIAL = '" + xFilial("SD1") + "' AND D1_QUANT > 0 "
    cQueryDet += "   AND F4_ESTOQUE = 'S' "
    cQueryDet += "   AND D1_DTDIGIT >= '" + DtoS(dIniMes) + "' AND D1_DTDIGIT <= '" + DtoS(dDataAte) + "' "
    cQueryDet += " ) MOV "
    cQueryDet := ChangeQuery(cQueryDet)
    cQueryDet := StrTran(cQueryDet, "(NOLOCK)", "")              // normaliza (evita dica duplicada)
    cQueryDet := StrTran(cQueryDet, " WITH ", " WITH (NOLOCK) ") // reinjeta a dica que o ChangeQuery remove
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQueryDet), cAliasDet, .F., .T.)
    TCSetField(cAliasDet, "QTD", "N", 12, 2)
    TCSetField(cAliasDet, "VUNIT", "N", 12, 4)
    While (cAliasDet)->(!Eof())
        aAdd(aMovsDet, {AllTrim((cAliasDet)->COD), AllTrim((cAliasDet)->TIPO), (cAliasDet)->QTD, StoD(AllTrim((cAliasDet)->DATA)), (cAliasDet)->VUNIT})
        (cAliasDet)->(DbSkip())
    EndDo
    (cAliasDet)->(DbCloseArea())

    // 2) SB2 atual (apos o periodo) - base para estimar o saldo no fim do
    //    mes e para o custo medio atual (B2_CM1; sem ele, B2_VATU1/B2_QATU)
    cQueryDet := " SELECT B2_COD, B2_LOCAL, B2_QATU, B2_CM1, B2_VATU1 "
    cQueryDet += " FROM " + RetSqlName("SB2") + " SB2 WITH (NOLOCK) "
    cQueryDet += " WHERE D_E_L_E_T_ = ' ' AND B2_FILIAL = '" + xFilial("SB2") + "' "
    cQueryDet := ChangeQuery(cQueryDet)
    cQueryDet := StrTran(cQueryDet, "(NOLOCK)", "")
    cQueryDet := StrTran(cQueryDet, " WITH ", " WITH (NOLOCK) ")
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQueryDet), cAliasDet, .F., .T.)
    TCSetField(cAliasDet, "B2_QATU", "N", 12, 2)
    TCSetField(cAliasDet, "B2_CM1", "N", 14, 6)
    TCSetField(cAliasDet, "B2_VATU1", "N", 14, 2)
    While (cAliasDet)->(!Eof())
        cProdExp := AllTrim((cAliasDet)->B2_COD)
        nSB2Pos := aScan(aSB2Exp, {|x| x[1] == cProdExp})
        If nSB2Pos > 0
            aSB2Exp[nSB2Pos][2] += (cAliasDet)->B2_QATU  // soma todas as linhas de estoque do produto
            aSB2Exp[nSB2Pos][4] += (cAliasDet)->B2_VATU1 // soma o valor em estoque de todas as linhas
        Else
            aAdd(aSB2Exp, {cProdExp, (cAliasDet)->B2_QATU, (cAliasDet)->B2_CM1, (cAliasDet)->B2_VATU1})
        EndIf
        (cAliasDet)->(DbSkip())
    EndDo
    (cAliasDet)->(DbCloseArea())

    // 3) Saldo REAL no inicio do mes anterior via SB9 (fechamento mensal do
    //    estoque). A estrutura do SB9 varia entre bases; detecta uma unica vez
    //    (mesmo padrao do ZSLDEST): B9_DATA + B9_QINI (abertura) ou B9_QFIM
    //    (fechamento do mes anterior = saldo em 01/MM), ou B9_MES + B9_ANO.
    //    Base CINVJ6_192877_PR_DV (validado 2026-10-01): SB9 SEM B9_QFIM;
    //    B9_QINI da linha de fim de mes = fechamento do mes (confrontado
    //    com SB2/B2_QATU de itens sem movimento desde 01/MM). Datas em
    //    branco do SB9 sao excluidas (109 linhas sujas; '' <= data eh
    //    verdadeiro no SQL Server e poluia o somatorio).
    cQueryDet := " SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS "
    cQueryDet += " WHERE TABLE_NAME = '" + RetSqlName("SB9") + "' "
    cQueryDet += "   AND COLUMN_NAME IN ('B9_MES','B9_ANO','B9_DATA','B9_QFIM','B9_QINI',"
    cQueryDet += "                         'B9_VFIM','B9_VINI1','B9_VATU','B9_VATU1') "
    cQueryDet := ChangeQuery(cQueryDet)
    DbUseArea(.T.,"TOPCONN",TCGenQry(,,cQueryDet),cAliasDet,.F.,.T.)
    While (cAliasDet)->(!Eof())
        Do Case
            Case AllTrim((cAliasDet)->COLUMN_NAME) == "B9_DATA"
                lB9Data := .T.
            Case AllTrim((cAliasDet)->COLUMN_NAME) == "B9_MES"
                lB9MesAno := .T.
            Case AllTrim((cAliasDet)->COLUMN_NAME) == "B9_QFIM"
                cB9Qtd  := "B9_QFIM"
                lB9Qfim := .T.
            Case AllTrim((cAliasDet)->COLUMN_NAME) == "B9_QINI"
                If Empty(cB9Qtd)
                    cB9Qtd  := "B9_QINI"
                    lB9Qfim := .F.
                EndIf
            // Valor do fechamento: prioridade VFIM > VINI1 > VATU > VATU1
            // (mesmo padrao do ZSLDEST)
            Case AllTrim((cAliasDet)->COLUMN_NAME) == "B9_VFIM"
                cB9Vlr := "B9_VFIM"
            Case AllTrim((cAliasDet)->COLUMN_NAME) == "B9_VINI1"
                If Empty(cB9Vlr)
                    cB9Vlr := "B9_VINI1"
                EndIf
            Case AllTrim((cAliasDet)->COLUMN_NAME) == "B9_VATU"
                If Empty(cB9Vlr)
                    cB9Vlr := "B9_VATU"
                EndIf
            Case AllTrim((cAliasDet)->COLUMN_NAME) == "B9_VATU1"
                If Empty(cB9Vlr)
                    cB9Vlr := "B9_VATU1"
                EndIf
        EndCase
        (cAliasDet)->(DbSkip())
    EndDo
    (cAliasDet)->(DbCloseArea())

    // B9_DATA e o criterio mais preciso; quando existe, ignora B9_MES/B9_ANO
    // (as duas estruturas podem coexistir na mesma tabela)
    If lB9Data
        lB9MesAno := .F.
    EndIf

    If !Empty(cB9Qtd)
        // QINI = saldo de abertura em 01/MM; QFIM = fechamento no ultimo dia do
        // mes anterior, que e o mesmo saldo fisico de 01/MM
        If lB9Qfim
            dLimB9 := dIniMes - 1
        Else
            dLimB9 := dIniMes
        EndIf
        If lB9Data
            cQueryDet := " SELECT SB9.B9_COD COD, SUM(SB9." + cB9Qtd + ") QTD, MX.MAXDT DTB9 "
        Else
            cQueryDet := " SELECT SB9.B9_COD COD, SUM(SB9." + cB9Qtd + ") QTD, '' DTB9 "
        EndIf
        // Valor do fechamento (custo medio do mes anterior = valor / qtd).
        // Sem coluna de valor no SB9 desta base, traz 0 e o custo medio
        // do mes anterior fica zerado no relatorio.
        If !Empty(cB9Vlr)
            cQueryDet += " , SUM(SB9." + cB9Vlr + ") VLR "
        Else
            cQueryDet += " , 0 VLR "
        EndIf
        cQueryDet += " FROM " + RetSqlName("SB9") + " SB9 WITH (NOLOCK) "
        If lB9Data
            cQueryDet += " INNER JOIN ( SELECT B9X.B9_COD CODX, MAX(B9X.B9_DATA) MAXDT "
            cQueryDet += "   FROM " + RetSqlName("SB9") + " B9X WITH (NOLOCK) "
            cQueryDet += "   WHERE B9X.D_E_L_E_T_ = ' ' AND B9X.B9_FILIAL = '" + xFilial("SB9") + "' "
            cQueryDet += "     AND B9X.B9_DATA <= '" + DtoS(dLimB9) + "' "
            cQueryDet += "     AND LTRIM(RTRIM(B9X.B9_DATA)) <> '' "
            cQueryDet += "   GROUP BY B9X.B9_COD ) MX ON MX.CODX = SB9.B9_COD AND MX.MAXDT = SB9.B9_DATA "
        EndIf
        cQueryDet += " WHERE SB9.D_E_L_E_T_ = ' ' AND SB9.B9_FILIAL = '" + xFilial("SB9") + "' "
        If lB9MesAno
            cQueryDet += "   AND SB9.B9_MES = '" + StrZero(Month(dLimB9), 2) + "' AND SB9.B9_ANO = '" + StrZero(Year(dLimB9), 4) + "' "
        ElseIf lB9Data
            cQueryDet += "   AND SB9.B9_DATA <= '" + DtoS(dLimB9) + "' "
            cQueryDet += "   AND LTRIM(RTRIM(SB9.B9_DATA)) <> '' "
        EndIf
        cQueryDet += " GROUP BY SB9.B9_COD, MX.MAXDT "  // MAXDT no group: exigido pelo SQL Server; JOIN ja restringe ao maximo por produto
        cQueryDet := ChangeQuery(cQueryDet)
        cQueryDet := StrTran(cQueryDet, "(NOLOCK)", "")              // normaliza (evita dica duplicada)
        cQueryDet := StrTran(cQueryDet, " WITH ", " WITH (NOLOCK) ") // reinjeta a dica que o ChangeQuery remove
        DbUseArea(.T.,"TOPCONN",TCGenQry(,,cQueryDet),cAliasDet,.F.,.T.)
        TCSetField(cAliasDet, "QTD", "N", 12, 2)
        TCSetField(cAliasDet, "VLR", "N", 14, 2)
        While (cAliasDet)->(!Eof())
            aAdd(aSB9Exp, {AllTrim((cAliasDet)->COD), (cAliasDet)->QTD, StoD(AllTrim((cAliasDet)->DTB9)), (cAliasDet)->VLR})
            (cAliasDet)->(DbSkip())
        EndDo
        (cAliasDet)->(DbCloseArea())
    EndIf

    // 4) Detalha cada item filtrado no browse (aItens)
    For nX := 1 To Len(aItens)
        cProdExp  := AllTrim(aItens[nX][1])
        nSB2Qtd   := 0
        nEntMes   := 0
        nSaiMes   := 0
        nEntPos   := 0
        nSaiPos   := 0
        nPrecoMes := 0
        nPrecoAtu := aItens[nX][18]
        dPrecoDia := CtoD("")
        nCMMesAnt := 0
        nCMAtu    := 0
        lCMReal   := .F.

        // Movimento do produto: dentro do mes anterior (para o relatorio) e apos o
        // mes (para reconciliar o saldo de hoje do SB2 com o saldo no fim do mes).
        // Preco no Mes: ultimo D1_VUNIT de entrada dentro do periodo.
        For nPosDet := 1 To Len(aMovsDet)
            If aMovsDet[nPosDet][1] == cProdExp
                If aMovsDet[nPosDet][4] <= dFimMes
                    If aMovsDet[nPosDet][2] == "E"
                        nEntMes += aMovsDet[nPosDet][3]
                        If aMovsDet[nPosDet][5] > 0 .And. aMovsDet[nPosDet][4] >= dPrecoDia
                            nPrecoMes := aMovsDet[nPosDet][5]
                            dPrecoDia := aMovsDet[nPosDet][4]
                        EndIf
                    Else
                        nSaiMes += aMovsDet[nPosDet][3]
                    EndIf
                Else
                    If aMovsDet[nPosDet][2] == "E"
                        nEntPos += aMovsDet[nPosDet][3]
                    Else
                        nSaiPos += aMovsDet[nPosDet][3]
                    EndIf
                EndIf
            EndIf
        Next nPosDet

        // Saldo atual do SB2 (todas as linhas de estoque do produto, mesma filial da analise)
        nSB2Pos := aScan(aSB2Exp, {|x| x[1] == cProdExp})
        If nSB2Pos > 0
            nSB2Qtd := aSB2Exp[nSB2Pos][2]
        EndIf

        // Saldo no inicio do mes: valor REAL do fechamento mensal (SB9) quando o
        // item tem fechamento do proprio mes; um registro antigo (fechamento de
        // 2+ meses atras) NAO vale como saldo de 01/MM e cai no fallback estimado.
        // Janela aceita: 3 dias antes ate 1 dia depois de 01/MM (fechamentos
        // rodados com data de processamento no inicio do mes continuam validos).
        nPosB9 := aScan(aSB9Exp, {|x| x[1] == cProdExp})
        lSaldoReal := .F.
        If nPosB9 > 0
            If Empty(aSB9Exp[nPosB9][3])
                // Estrutura B9_MES/B9_ANO: a chave do mes e exata, nao ha risco
                lSaldoReal := .T.
            ElseIf aSB9Exp[nPosB9][3] >= dIniMes - 3 .And. aSB9Exp[nPosB9][3] <= dIniMes + 1
                lSaldoReal := .T.
            EndIf
        EndIf
        // A janela de data valida tambem habilita o custo medio do mes
        // anterior: a conferencia de movimento abaixo pode invalidar o
        // SALDO, mas o custo medio do fechamento continua sendo o do
        // proprio fechamento, entao lCMReal preserva a data aceita
        lCMReal := lSaldoReal
        If lSaldoReal
            nSaldoIni := aSB9Exp[nPosB9][2]
            // Conta direta a partir do saldo real: fim do mes = inicio + entradas - saidas
            nSaldoFim := nSaldoIni + nEntMes - nSaiMes
            // Conferencia (mesmo padrao do ZSLDEST): o saldo do SB9 + todo o
            // movimento do periodo (do inicio do mes ate hoje) precisa explicar
            // o saldo atual do SB2. Fechamento zerado, antigo ou de outro mes nao
            // explica o estoque de hoje e e descartado (o item entao usa o saldo
            // estimado a partir do SB2). Tolerancia de 0.05 cobre arredondamento.
            nSaldoCalc := nSaldoIni + (nEntMes + nEntPos) - (nSaiMes + nSaiPos)
            If Abs(Round(nSaldoCalc - nSB2Qtd, 2)) > 0.05
                lSaldoReal := .F.
            EndIf
        EndIf
        If !lSaldoReal
            nSaldoFim := nSB2Qtd - nEntPos + nSaiPos
            nSaldoIni := nSaldoFim - nEntMes + nSaiMes
        EndIf
        // Estoque nao fica negativo: saldo negativo no fim do mes indica movimento
        // que o SB2 nao reflete; o relatorio mostra zero (estoque esgotado no mes)
        If nSaldoFim < 0
            nSaldoFim := 0
        EndIf
        // Idem para a abertura: abertura negativa (so na estimativa) inventaria
        // aumento ficticio (fechamento menos abertura negativa); mostra zero
        If nSaldoIni < 0
            nSaldoIni := 0
        EndIf
        // Custo medio do mes anterior: valor / quantidade do fechamento
        // mensal aceito (SB9). Sem fechamento valido na janela, sem
        // coluna de valor nesta base ou fechamento zerado: mostra zero.
        If lCMReal
            If aSB9Exp[nPosB9][2] > 0 .And. aSB9Exp[nPosB9][4] > 0
                nCMMesAnt := aSB9Exp[nPosB9][4] / aSB9Exp[nPosB9][2]
            EndIf
        EndIf
        // Custo medio atual: B2_CM1 (custo medio ponderado do SB2); quando
        // zerado, deriva do valor atual acumulado / quantidade atual do SB2
        If nSB2Pos > 0
            nCMAtu := aSB2Exp[nSB2Pos][3]
            If nCMAtu <= 0 .And. aSB2Exp[nSB2Pos][2] > 0
                nCMAtu := aSB2Exp[nSB2Pos][4] / aSB2Exp[nSB2Pos][2]
            EndIf
        Else
            nCMAtu := 0
        EndIf
        // Preco de compra do mes (colunas "Valor Unitario"): ultimo D1_VUNIT
        // de entrada dentro do mes; sem NF no mes, usa o preco atual (B1_UPRC).
        If nPrecoMes > 0
            nPrecoMesU := nPrecoMes
        Else
            nPrecoMesU := nPrecoAtu
        EndIf
        // Valor em estoque do item (colunas "Valor ..." e "Aumento de
        // Valor"): avaliado pelo CUSTO MEDIO, nao pelo preco de compra.
        // Abertura (01/MM) x Custo Medio do mes anterior; fechamento
        // (fim do mes) x Custo Medio atual. O Aumento e, portanto, a soma
        // do efeito QUANTIDADE (estoque maior) com o efeito CUSTO
        // (variacao do Custo Medio entre o mes anterior e hoje).
        // Sem Custo Medio do mes anterior (item sem fechamento valido no
        // SB9), avalia a abertura pelo Custo Medio atual: assim a diferenca
        // mede so o efeito quantidade, em vez de inflar o valor inteiro
        // do estoque como se fosse aumento.
        If nCMMesAnt > 0
            nCMAbertura := nCMMesAnt
        Else
            nCMAbertura := nCMAtu
        EndIf
        nValIni  := nSaldoIni * nCMAbertura
        nValFim  := nSaldoFim * nCMAtu
        nValDif  := nValFim - nValIni
        nUnidDif := nSaldoFim - nSaldoIni

        // Reconciliacao do rodape: acumula TODOS os itens ANTES do filtro de
        // listagem, separados pela direcao da QUANTIDADE (nUnidDif). Sem este
        // acumulo o total do relatorio so somava quem aumentou e nunca batia
        // com a diferenca real entre um fechamento e o outro.
        nValIniAll += nValIni
        nValFimAll += nValFim
        If Round(nUnidDif, 2) > 0
            nSomaAum += nValDif
            nQtdAum  += 1
        ElseIf Round(nUnidDif, 2) < 0
            nSomaQueda += nValDif
            nQtdQueda  += 1
        Else
            // Quantidade igual: a variacao de valor vem so do Custo Medio
            nSomaParado += nValDif
            nQtdParado  += 1
        EndIf

        // Somente itens cujo ESTOQUE aumentou no mes (fechamento > abertura).
        // O filtro e por QUANTIDADE (nUnidDif) e vale so para a LISTAGEM; o
        // rodape reconcilia com a base inteira acumulada acima.
        If Round(nUnidDif, 2) <= 0
            Loop
        EndIf

        // Motivo em frase clara do Aumento (que agora combina quantidade e
        // Custo Medio): mostra o que mudou na quantidade de estoque e no
        // Custo Medio praticado, para o usuario entender o aumento.
        cMotivo := "Quantidade: " + AllTrim(Transform(nUnidDif, "@E 999,999")) + " unidades no mes (entradas: " + ;
            AllTrim(Transform(nEntMes, "@E 999,999.99")) + "; saidas: " + AllTrim(Transform(nSaiMes, "@E 999,999.99")) + ")"
        cMotivo += ". Custo medio: " + AllTrim(Transform(nCMAbertura, "@E 999,999.99")) + " -> " + ;
            AllTrim(Transform(nCMAtu, "@E 999,999.99")) + " (variacao de R$ " + AllTrim(Transform(nCMAtu - nCMAbertura, "@E 999,999.99")) + " por unidade)"
        If !lSaldoReal
            cMotivo += " (saldo do mes estimado, sem fechamento valido no sistema)"
        EndIf

        // aRegs: 1=Produto 2=Descricao 3=Valor Inicio do Mes 4=Valor Fim do Mes
        //        5=Variacao do Valor no Mes 6=Motivo 7=Saldo Inicio do Mes
        //        8=Saldo Fim do Mes 9=Preco do Mes 10=Preco Atual
        //        11=Custo Medio (Mes Anterior) 12=Custo Medio (Atual)
        aAdd(aRegs, {cProdExp, AllTrim(aItens[nX][2]), nValIni, nValFim, nValDif, cMotivo, nSaldoIni, nSaldoFim, nPrecoMesU, nPrecoAtu, nCMMesAnt, nCMAtu})
    Next nX

    // Maior variacao de valor primeiro (leitura clara)
    ASort(aRegs, , , {|x, y| x[5] > y[5]})

    // aTotais: base da reconciliacao impressa no rodape do relatorio.
    //  1 = R$ dos itens que AUMENTARAM      2 = qtde deles
    //  3 = R$ dos itens que DIMINUIRAM      4 = qtde deles
    //  5 = R$ dos itens com qtde IGUAL      6 = qtde deles (variou so o CM)
    //  7 = valor total na ABERTURA do mes   8 = valor total no FECHAMENTO
    // Conferencia obrigatoria: 1 + 3 + 5  ==  8 - 7
    aTotais := {nSomaAum, nQtdAum, nSomaQueda, nQtdQueda, nSomaParado, nQtdParado, nValIniAll, nValFimAll}

    // 4) Relatorio via TReport (mesmo padrao do ZCOMPRAS/ZSLDEST): o dialogo
    //    padrao permite imprimir, salvar em PDF, HTML ou planilha (Excel).
    //    ATENCAO: na saida planilha o TReport grava apenas as celulas das
    //    secoes - linhas de PrintText() sao descartadas. Por isso a
    //    reconciliacao do rodape e uma secao de celulas propria (abaixo).
    oReport := TReport():New("ZMMA01D", "Itens com Estoque que Aumentou no Mes Anterior", "", ;
        {|oReport| DetRepMonta(oReport, dIniMes, dFimMes, aRegs, aTotais)}, ;
        "Itens cujo estoque aumentou no mes anterior (" + DtoC(dIniMes) + " a " + DtoC(dFimMes) + "); valor em R$ avaliado pelo Custo Medio")
    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    oSection := TRSection():New(oReport, "Itens", {})

    TRCell():New(oSection, "PRODUTO",    "", "Produto",                        "@!",              15)
    TRCell():New(oSection, "DESCRICAO",  "", "Descricao",                      "@!",              30)
    TRCell():New(oSection, "SALDOMES",   "", "Saldo de Estoque (Inicio do Mes)", "@E 999,999.99",   12)
    TRCell():New(oSection, "SALDOATU",   "", "Saldo de Estoque (Fim do Mes)",    "@E 999,999.99",   12)
    TRCell():New(oSection, "VUNITMES",   "", "Valor Unitario (Mes Anterior)",    "@E 999,999.99",   12)
    TRCell():New(oSection, "VUNITATU",   "", "Valor Unitario (Atual)",           "@E 999,999.99",   12)
    TRCell():New(oSection, "CMMESANT",   "", "Custo Medio (Mes Anterior)",       "@E 999,999.99",   12)
    TRCell():New(oSection, "CMATU",      "", "Custo Medio (Atual)",              "@E 999,999.99",   12)
    TRCell():New(oSection, "SALDTOTMES", "", "Valor no Inicio do Mes (R$)",       "@E 999,999,999.99", 16)
    TRCell():New(oSection, "SALDTOTATU", "", "Valor no Fim do Mes (R$)",          "@E 999,999,999.99", 16)
    TRCell():New(oSection, "VALAUM",     "", "Variacao do Valor no Mes (R$)",    "@E 999,999,999.99", 16)
    TRCell():New(oSection, "MOTIVO",     "", "Motivo da Variacao",               "@!",              60)

    // Secao 2: RECONCILIACAO em linhas de CELULA.
    // Causa do problema: a exportacao em planilha do TReport grava somente as
    // celulas das secoes e DESCARTA as linhas de TReport:PrintText() (por isso
    // nem o titulo nem as linhas de explicacao saiam no Excel). Cada linha da
    // reconciliacao vira uma linha desta secao: no preview imprime logo abaixo
    // dos itens e na planilha abre a aba "Reconciliacao".
    oSecRec := TRSection():New(oReport, "Reconciliacao", {})
    oSecRec:SetHeaderSection(.F.)
    TRCell():New(oSecRec, "LINHA", "", "", Nil, 100)

    oReport:PrintDialog()

    RestArea(aAreaExp)

Return

/*/{Protheus.doc} DetRepMonta
Popula o TReport do botao Detalhes com os itens cujo estoque aumentou do inicio
para o fim do mes anterior, do maior para o menor efeito em R$. No rodape imprime
a RECONCILIACAO: soma dos itens que aumentaram, dos que diminuiram e dos que
ficaram com a mesma quantidade, fechando com a diferenca real entre o valor do
inicio e do fim do mes. O rodape e impresso como LINHAS DA SECAO 2 (celulas)
e NAO via PrintText: a exportacao em planilha do TReport grava so as celulas das
secoes e descarta as linhas de texto, e era por isso que a reconciliacao nao
aparecia no Excel. Chamada pelo PrintDialog de ExportarDetalhes.
@type function
@author Juan
@since 2026.10.01
@param oReport - objeto TReport criado em ExportarDetalhes
@param dIniMes - inicio do mes anterior (Local da chamadora, via codeblock)
@param dFimMes - fim do mes anterior (Local da chamadora, via codeblock)
@param aRegs - itens cujo estoque aumentou (Local da chamadora, via codeblock)
@param aTotais - 8 posicoes da reconciliacao: {R$ aumentou, qtde, R$ diminiu,
        qtde, R$ qtde igual, qtde, valor abertura, valor fechamento}
*/
Static Function DetRepMonta(oReport, dIniMes, dFimMes, aRegs, aTotais)
    Local oSection := oReport:Section(1)
    Local oSecRec  := oReport:Section(2)
    Local aLinhas  := {}
    Local nI
    Local nTotAum := 0

    oReport:SetMeter(Len(aRegs))
    oSection:Init()
    oSection:SetHeaderSection(.T.)
    oReport:PrintText("Selecao: somente itens cujo ESTOQUE aumentou do inicio para o fim do mes (saldo em " + DtoC(dFimMes) + " maior que a abertura em " + DtoC(dIniMes) + ").", 0)
    oReport:PrintText("O valor em R$ pode diminuir quando o Custo Medio cai, mesmo com o estoque maior.", 0)
    oReport:PrintText("Datas avaliadas: " + DtoC(dIniMes) + " a " + DtoC(dFimMes) + " (mes anterior completo)", 0)
    oReport:PrintText("Valor no Inicio do Mes: saldo em " + DtoC(dIniMes) + " x Custo Medio do mes anterior (fechamento SB9).", 0)
    oReport:PrintText("Valor no Fim do Mes: saldo em " + DtoC(dFimMes) + " x Custo Medio atual (SB2).", 0)
    oReport:PrintText("Variacao do Valor no Mes: diferenca entre o valor do fim e o do inicio do mes; soma o efeito quantidade (estoque maior) e o efeito Custo Medio (variacao do custo).", 0)
    oReport:PrintText("Custo Medio (Mes Anterior): valor em estoque / quantidade no fechamento do mes anterior (SB9). Sem fechamento valido, mostra zero.", 0)
    oReport:PrintText("Custo Medio (Atual): custo medio ponderado atual (SB2 B2_CM1; se zero, valor atual / quantidade atual).", 0)
    oReport:PrintText("ATENCAO: a listagem acima traz SOMENTE os itens que aumentaram. A reconciliacao completa, com as quedas e o total real, esta no rodape.", 0)
    oReport:SkipLine()

    For nI := 1 To Len(aRegs)
        oSection:Cell("PRODUTO"):SetValue(aRegs[nI][1])
        oSection:Cell("DESCRICAO"):SetValue(aRegs[nI][2])
        oSection:Cell("SALDOMES"):SetValue(aRegs[nI][7])
        oSection:Cell("SALDOATU"):SetValue(aRegs[nI][8])
        oSection:Cell("VUNITMES"):SetValue(aRegs[nI][9])
        oSection:Cell("VUNITATU"):SetValue(aRegs[nI][10])
        oSection:Cell("CMMESANT"):SetValue(aRegs[nI][11])
        oSection:Cell("CMATU"):SetValue(aRegs[nI][12])
        oSection:Cell("SALDTOTMES"):SetValue(aRegs[nI][3])
        oSection:Cell("SALDTOTATU"):SetValue(aRegs[nI][4])
        oSection:Cell("VALAUM"):SetValue(aRegs[nI][5])
        oSection:Cell("MOTIVO"):SetValue(aRegs[nI][6])
        oSection:PrintLine()
        nTotAum += aRegs[nI][5]
        oReport:IncMeter()
    Next nI

    oSection:Finish()

    // Rodape em CELULAS (secao 2) e NAO em PrintText: a exportacao em
    // planilha do TReport grava apenas as celulas das secoes e descarta as
    // linhas de texto, e era por isso que a reconciliacao nao aparecia no Excel.
    aLinhas := {}
    aAdd(aLinhas, "")
    aAdd(aLinhas, "RECONCILIACAO DO VALOR EM ESTOQUE - " + DtoC(dIniMes) + " x " + DtoC(dFimMes))
    If Len(aRegs) == 0
        aAdd(aLinhas, "NENHUM item teve o estoque aumentado neste periodo. A reconciliacao abaixo continua valida.")
    EndIf
    aAdd(aLinhas, "  Itens com estoque AUMENTOU ............ " + Transform(aTotais[2], "@E 9,999") + " itens   R$ " + Transform(aTotais[1], "@E 999,999,999.99"))
    aAdd(aLinhas, "  Itens com estoque DIMINUIU ............ " + Transform(aTotais[4], "@E 9,999") + " itens   R$ " + Transform(aTotais[3], "@E 999,999,999.99"))
    aAdd(aLinhas, "  Itens com quantidade IGUAL ............ " + Transform(aTotais[6], "@E 9,999") + " itens   R$ " + Transform(aTotais[5], "@E 999,999,999.99") + "  (variou so o Custo Medio)")
    aAdd(aLinhas, "")
    aAdd(aLinhas, "  Valor total em " + DtoC(dIniMes) + " (abertura) .... R$ " + Transform(aTotais[7], "@E 999,999,999.99"))
    aAdd(aLinhas, "  Valor total em " + DtoC(dFimMes) + " (fechamento) ... R$ " + Transform(aTotais[8], "@E 999,999,999.99"))
    aAdd(aLinhas, "  DIFERENCA DO PERIODO .................. R$ " + Transform(aTotais[8] - aTotais[7], "@E 999,999,999.99"))
    aAdd(aLinhas, "")
    aAdd(aLinhas, "  Conferencia (soma das tres linhas) .... R$ " + Transform(aTotais[1] + aTotais[3] + aTotais[5], "@E 999,999,999.99") + "  = diferenca acima")
    aAdd(aLinhas, "  Itens listados acima: " + cValToChar(Len(aRegs)) + " (somente os que aumentaram) | Soma deles: R$ " + Transform(nTotAum, "@E 999,999,999.99"))

    oSecRec:Init()
    For nI := 1 To Len(aLinhas)
        oSecRec:Cell("LINHA"):SetValue(aLinhas[nI])
        oSecRec:PrintLine()
    Next nI
    oSecRec:Finish()
Return

/*/{Protheus.doc} CalcValorEstoque
Calcula e exibe o valor total de estoque (saldo x custo medio) dos itens filtrados
@type function
@author Juan
@since 2026.09.02
/*/
Static Function CalcValorEstoque()
    Local nX
    Local nValorEstoque := 0

    For nX := 1 To Len(aItens)
        // [32] = valor do estoque pelo custo medio (SB2: B2_CM1 x B2_QATU; sem CM, B2_VATU1)
        nValorEstoque += aItens[nX][32]
    Next nX

    If oSayEst != NIL
        oSayEst:SetText("Valor Estoque (Custo Medio): R$ " + AllTrim(Transform(nValorEstoque, "@E 9,999,999,999.99")) + " | " + cValToChar(Len(aItens)) + " itens")
    EndIf

Return
