#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} ZMMA01
Análise de Recorrência de Compras x Mínimo/Máximo
Identifica produtos com recorrência de compras que não estão no controle de estoque
@type     function
@author   Juan
@since    2026.02.05
@version  2.0 - Versão otimizada
/*/

User Function ZMMA01()
    Local aArea := GetArea() as array
    Local oDlg as object
    Local oPanel1 as object
    Local oPanel2 as object
    Local oSay1, oSay2, oSay3, oSay4 as object
    Local oGet1, oGet2, oGet3 as object
    Local oCmbAcao as object
    Local oBtn1, oBtn3, oBtn4 as object

    // Variáveis compartilhadas entre funções
    Private dDataDe := CtoD("") as date
    Private dDataAte := Date() as date
    Private cFiltroProd := Space(20) as character  // Filtro por produto
    Private cFiltroAcao := "TODOS" as character    // Filtro por acao
    Private aItens := {} as array                  // Array filtrado
    Private aItensFull := {} as array              // Array completo (antes dos filtros)
    Private aColunas := {} as array
    Private oBrowse as object
    Private lSilentFilter := .F. as logical        // Suprime MsgInfo em AplicaFiltros quando chamado internamente

    // Define a tela principal
    DEFINE MSDIALOG oDlg TITLE "Analise de Recorrencia de Compras - Produtos sem Controle Min/Max" FROM 000,000 TO 750,1800 PIXEL

    // Painel superior - Parâmetros e Filtros
    oPanel1 := TPanel():New(000, 000, "", oDlg, , , , , , 800, 055, .T., .T.)
    oPanel1:Align := CONTROL_ALIGN_TOP

    // Linha 1 - Parâmetros de data
    @ 008, 010 SAY oSay1 PROMPT "Data De:" SIZE 040, 007 OF oPanel1 PIXEL
    @ 006, 050 MSGET oGet1 VAR dDataDe SIZE 050, 010 OF oPanel1 PIXEL VALID !Empty(dDataDe)

    @ 008, 110 SAY oSay2 PROMPT "Data Ate:" SIZE 040, 007 OF oPanel1 PIXEL
    @ 006, 150 MSGET oGet2 VAR dDataAte SIZE 050, 010 OF oPanel1 PIXEL VALID !Empty(dDataAte) .And. dDataAte >= dDataDe

    // Botões de ação - AJUSTADO O ESPAÇAMENTO
    @ 006, 210 BUTTON oBtn1 PROMPT "Processar" SIZE 050, 012 OF oPanel1 PIXEL ACTION Processa({|| ProcessaAnalise()}, "Processando...")
    @ 006, 265 BUTTON oBtn3 PROMPT "Legenda" SIZE 050, 012 OF oPanel1 PIXEL ACTION MostraLegenda()
    @ 006, 320 BUTTON oBtn4 PROMPT "Sair" SIZE 050, 012 OF oPanel1 PIXEL ACTION oDlg:End()

    // Linha 2 - Filtros
    @ 023, 010 SAY oSay3 PROMPT "Filtro Produto:" SIZE 050, 007 OF oPanel1 PIXEL
    @ 021, 065 MSGET oGet3 VAR cFiltroProd SIZE 080, 010 OF oPanel1 PIXEL
    @ 021, 150 BUTTON "Aplicar Filtro" SIZE 050, 012 OF oPanel1 PIXEL ACTION AplicaFiltros()
    @ 021, 203 BUTTON "Limpar" SIZE 045, 012 OF oPanel1 PIXEL ACTION {||(cFiltroProd := Space(20), oGet3:VarPut(cFiltroProd), oGet3:Refresh(), cFiltroAcao := "TODOS", oCmbAcao:SelectItem(1), AplicaFiltros())}

    @ 023, 255 SAY oSay4 PROMPT "Filtro Acao:" SIZE 040, 007 OF oPanel1 PIXEL
    @ 021, 298 COMBOBOX oCmbAcao VAR cFiltroAcao ITEMS {"TODOS","CRITICO","IMPORTANTE","AVALIAR","OBSERVAR","CONSECUTIVO","RECORRENTE"} SIZE 110, 012 OF oPanel1 PIXEL ON CHANGE AplicaFiltros()

    // Texto explicativo
    @ 038, 010 SAY "CRITICO: 5+ meses seguidos  |  IMPORTANTE: 4 seguidos ou 5+ total  |  AVALIAR: 3 seguidos ou 3-4 total  |  OBSERVAR: 1 ou 2 meses de compra  |  Sugestao Min/Max baseada em baixas (SD3 TM=502) ou media dos pedidos de compra" SIZE 800, 007 OF oPanel1 PIXEL FONT TFont():New(, , 10, .T.) COLOR CLR_BLUE

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
    Local oColumn as object

    aColunas := {}

    // Coluna 1: Status (ícone)
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
    aAdd(aColunas, oColumn)

    // Coluna 3: Descrição
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][2]})
    oColumn:SetTitle("Descricao")
    oColumn:SetSize(30)
    oColumn:SetAlign(CONTROL_ALIGN_LEFT)
    aAdd(aColunas, oColumn)

    // Coluna 4: Ação Sugerida
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][11]})
    oColumn:SetTitle("Acao Sugerida")
    oColumn:SetSize(30)
    oColumn:SetAlign(CONTROL_ALIGN_LEFT)
    aAdd(aColunas, oColumn)

    // Coluna 5: Meses Consecutivos
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aItens[oBrowse:nAt][13], "@E 99")})
    oColumn:SetTitle("Consecutivos")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    // Coluna 5b: Total meses com compras (consecutivos ou nao)
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aItens[oBrowse:nAt][23], "@E 99")})
    oColumn:SetTitle("Total Meses")
    oColumn:SetSize(11)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    // Coluna 6: Numero Total de Compras
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aItens[oBrowse:nAt][4], "@E 999")})
    oColumn:SetTitle("Num. Compras")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    // Coluna 7: Qtd Media por OC - oculta do browse, disponivel no array [14] para calculo
    // Coluna 7b: Media mensal de baixas - oculta do browse, disponivel no array [21] para calculo

    // Coluna 8: Sugestao Minimo
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aItens[oBrowse:nAt][15], "@E 999,999")})
    oColumn:SetTitle("Sugestao Minimo")
    oColumn:SetSize(14)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    // Coluna 9: Sugestao Maximo
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aItens[oBrowse:nAt][16], "@E 999,999")})
    oColumn:SetTitle("Sugestao Maximo")
    oColumn:SetSize(14)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    // Coluna 10: Valor Unitario
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aItens[oBrowse:nAt][18], "@E 9,999,999.99")})
    oColumn:SetTitle("Valor Unitario")
    oColumn:SetSize(15)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    // Coluna 11: Valor Total Maximo Sugerido
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| Transform(aItens[oBrowse:nAt][19], "@E 9,999,999.99")})
    oColumn:SetTitle("Valor Total Max. Sug.")
    oColumn:SetSize(15)
    oColumn:SetAlign(CONTROL_ALIGN_RIGHT)
    aAdd(aColunas, oColumn)

    // Coluna 12: Última Compra
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| DtoC(aItens[oBrowse:nAt][6])})
    oColumn:SetTitle("Ultima Compra")
    oColumn:SetSize(12)
    oColumn:SetAlign(CONTROL_ALIGN_CENTER)
    aAdd(aColunas, oColumn)

    // Coluna 13: Fornecedor Principal
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| aItens[oBrowse:nAt][9] + " - " + Left(aItens[oBrowse:nAt][10], 15)})
    oColumn:SetTitle("Fornecedor Principal")
    oColumn:SetSize(25)
    oColumn:SetAlign(CONTROL_ALIGN_LEFT)
    aAdd(aColunas, oColumn)

Return

/*/{Protheus.doc} ProcessaAnalise
Processa a análise de recorrência - Versão otimizada
@type     function
@author   Juan
@since    2026.02.05
/*/
Static Function ProcessaAnalise()
    Local cQuery := "" as character
    Local cAlias := GetNextAlias() as character
    Local cProduto as character
    Local nQtdTotal as numeric
    Local nOcorrencias as numeric
    Local dPrimeira as date
    Local dUltima as date
    Local aFornec as array
    Local aMeses as array
    Local cMesAno as character
    Local nPosForn as numeric
    Local nMesesConsecutivos as numeric
    Local cFornPrinc as character
    Local cNomeForn as character
    Local cLojaForn as character
    Local nQtdMedia as numeric
    Local nSugMin as numeric
    Local nSugMax as numeric
    Local nValorUnit as numeric
    Local nValorTotal as numeric
    Local cAcao as character
    Local cIcone as character
    Local nTotalFull as numeric
    // --- Variaveis para baixas (consumo SD3) ---
    Local cQueryBaixas  := "" as character
    Local cAliasBaixas  as character
    Local aBaixasProd   := {} as array   // {cProduto, nTotal, nMeses}
    Local cProdBx       := "" as character
    Local nTotBx        := 0  as numeric
    Local aMesBx        := {} as array
    Local cMesBxMes     := "" as character
    Local nPosBaixas    := 0  as numeric
    Local nTotalBaixas  := 0  as numeric
    Local nMediaMensal  := 0  as numeric
    Local nMesesBaixas  := 0  as numeric
    Local nTotalMeses   := 0  as numeric
    Local nBaseCalc     := 0  as numeric

    // Validação de datas
    If Empty(dDataDe)
        MsgStop("Informe a Data De!", "Atenção")
        Return
    EndIf

    If Empty(dDataAte)
        MsgStop("Informe a Data Ate!", "Atenção")
        Return
    EndIf

    If dDataAte < dDataDe
        MsgStop("Data Ate deve ser maior ou igual a Data De!", "Atenção")
        Return
    EndIf

    aItens := {}
    aItensFull := {}

    // Carrega baixas (SD3 - saidas de estoque com TM = 502) no periodo para calculo de Min/Max
    cAliasBaixas := GetNextAlias()
    cQueryBaixas := " SELECT "
    cQueryBaixas += "   D3_COD, "
    cQueryBaixas += "   D3_EMISSAO, "
    cQueryBaixas += "   SUM(D3_QUANT) AS QUANT "
    cQueryBaixas += " FROM " + RetSqlName("SD3") + " SD3 "
    cQueryBaixas += " WHERE SD3.D_E_L_E_T_ = '' "
    cQueryBaixas += "   AND D3_FILIAL = '" + xFilial("SD3") + "' "
    cQueryBaixas += "   AND D3_EMISSAO BETWEEN '" + DtoS(dDataDe) + "' AND '" + DtoS(dDataAte) + "' "
    cQueryBaixas += "   AND D3_TM = '502' "
    cQueryBaixas += "   AND D3_COD NOT LIKE 'SV%' "
    cQueryBaixas += " GROUP BY D3_COD, D3_EMISSAO "
    cQueryBaixas += " ORDER BY D3_COD, D3_EMISSAO "
    cQueryBaixas := ChangeQuery(cQueryBaixas)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQueryBaixas), cAliasBaixas, .F., .T.)
    TCSetField(cAliasBaixas, "D3_EMISSAO", "D")
    TCSetField(cAliasBaixas, "QUANT", "N", 12, 2)

    aBaixasProd := {}
    (cAliasBaixas)->(DbGoTop())
    While (cAliasBaixas)->(!Eof())
        cProdBx := (cAliasBaixas)->D3_COD
        nTotBx  := 0
        aMesBx  := {}
        While (cAliasBaixas)->(!Eof()) .And. (cAliasBaixas)->D3_COD == cProdBx
            nTotBx    += (cAliasBaixas)->QUANT
            cMesBxMes := SubStr(DtoS((cAliasBaixas)->D3_EMISSAO), 1, 6)
            If aScan(aMesBx, cMesBxMes) == 0
                aAdd(aMesBx, cMesBxMes)
            EndIf
            (cAliasBaixas)->(DbSkip())
        EndDo
        aAdd(aBaixasProd, {cProdBx, nTotBx, Len(aMesBx)})
    EndDo
    (cAliasBaixas)->(DbCloseArea())

    // Query para buscar compras no período
    cQuery := " SELECT "
    cQuery += "   C7_PRODUTO, "
    cQuery += "   C7_FORNECE, "
    cQuery += "   C7_LOJA, "
    cQuery += "   C7_QUANT, "
    cQuery += "   C7_PRECO, "
    cQuery += "   C7_EMISSAO "
    cQuery += " FROM " + RetSqlName("SC7") + " SC7 "
    cQuery += " WHERE SC7.D_E_L_E_T_ = '' "
    cQuery += "   AND C7_FILIAL = '" + xFilial("SC7") + "' "
    cQuery += "   AND C7_EMISSAO BETWEEN '" + DtoS(dDataDe) + "' AND '" + DtoS(dDataAte) + "' "
    cQuery += "   AND C7_PRODUTO NOT LIKE 'SV%' "
    cQuery += "   AND C7_RESIDUO = '' "
    cQuery += "   AND C7_CONAPRO <> 'B' "
    cQuery += " ORDER BY C7_PRODUTO, C7_EMISSAO "

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    TCSetField(cAlias, "C7_EMISSAO", "D")
    TCSetField(cAlias, "C7_QUANT", "N", 12, 2)
    TCSetField(cAlias, "C7_PRECO", "N", 12, 2)

    // Agrupa por produto
    (cAlias)->(DbGoTop())
    While (cAlias)->(!Eof())

        cProduto := (cAlias)->C7_PRODUTO
        nQtdTotal := 0
        nOcorrencias := 0
        nValorUnit := 0
        dPrimeira := CtoD("")
        dUltima := CtoD("")
        aFornec := {}
        aMeses := {}

        // Agrupa todas as compras deste produto
        While (cAlias)->(!Eof()) .And. (cAlias)->C7_PRODUTO == cProduto

            nQtdTotal += (cAlias)->C7_QUANT
            nOcorrencias++

            // Captura último preço unitário
            nValorUnit := (cAlias)->C7_PRECO

            If Empty(dPrimeira)
                dPrimeira := (cAlias)->C7_EMISSAO
            EndIf
            dUltima := (cAlias)->C7_EMISSAO

            // Registra o mês/ano da compra
            cMesAno := SubStr(DtoS((cAlias)->C7_EMISSAO), 1, 6)
            If aScan(aMeses, cMesAno) == 0
                aAdd(aMeses, cMesAno)
            EndIf

            // Conta fornecedores
            nPosForn := aScan(aFornec, {|x| x[1] == (cAlias)->C7_FORNECE + (cAlias)->C7_LOJA})
            If nPosForn == 0
                aAdd(aFornec, {(cAlias)->C7_FORNECE + (cAlias)->C7_LOJA, 1})
            Else
                aFornec[nPosForn][2]++
            EndIf

            (cAlias)->(DbSkip())
        EndDo

        // Verifica consecutividade de meses
        nMesesConsecutivos := VerificaMesesConsecutivos(aMeses)
        nTotalMeses        := Len(aMeses)

        // Inclui todos os produtos comprados no periodo (1+ compra)
        // Busca dados do produto
        DbSelectArea("SB1")
        SB1->(DbSetOrder(1))

            If SB1->(DbSeek(xFilial("SB1") + cProduto))

                // Só adiciona se B1_ESTSEG = 0 (não controlado)
                If SB1->B1_ESTSEG <= 0

                    // Identifica fornecedor principal
                    aSort(aFornec, , , {|x, y| x[2] > y[2]})
                    cFornPrinc := ""
                    cNomeForn := ""
                    If Len(aFornec) > 0
                        cFornPrinc := SubStr(aFornec[1][1], 1, 6)
                        cLojaForn := SubStr(aFornec[1][1], 7, 2)
                        cNomeForn := Posicione("SA2", 1, xFilial("SA2") + cFornPrinc + cLojaForn, "A2_NOME")
                    EndIf

// Busca baixas reais do produto (SD3 - saidas de estoque com TM = 502)
                    nPosBaixas   := aScan(aBaixasProd, {|x| x[1] == cProduto})
                    nTotalBaixas := 0
                    nMesesBaixas := 0
                    nMediaMensal := 0
                    If nPosBaixas > 0
                        nTotalBaixas := aBaixasProd[nPosBaixas][2]
                        nMesesBaixas := aBaixasProd[nPosBaixas][3]
                        If nMesesBaixas > 0
                            nMediaMensal := Round(nTotalBaixas / nMesesBaixas, 2)
                        EndIf
                    EndIf

                    // Calcula Min/Max
                    // Base: media mensal de baixas (consumo real); fallback: media qty por OC
                    nQtdMedia := Round(nQtdTotal / nOcorrencias, 2)
                    nBaseCalc := If(nMediaMensal > 0, nMediaMensal, nQtdMedia)

                    If nMesesConsecutivos >= 5 .Or. (nMesesConsecutivos < 3 .And. nTotalMeses >= 5)
                        nSugMin := Max(ArredInteligente(nBaseCalc * 2), 5)
                        nSugMax := Max(ArredInteligente(nBaseCalc * 4), 10)
                    ElseIf nMesesConsecutivos >= 4 .Or. (nMesesConsecutivos < 3 .And. nTotalMeses >= 4)
                        nSugMin := Max(ArredInteligente(nBaseCalc * 1.5), 3)
                        nSugMax := Max(ArredInteligente(nBaseCalc * 3), 6)
                    Else
                        nSugMin := Max(ArredInteligente(nBaseCalc), 2)
                        nSugMax := Max(ArredInteligente(nBaseCalc * 2), 4)
                    EndIf

                    // Calcula valor total maximo sugerido
                    nValorTotal := nValorUnit * nSugMax

                    // Define acao sugerida
                    cAcao  := ""
                    cIcone := ""

                    If nMesesConsecutivos >= 5
                        cAcao  := "CRITICO: Incluir Min/Max Imediatamente"
                        cIcone := "BR_VERMELHO"
                    ElseIf nMesesConsecutivos >= 4
                        cAcao  := "IMPORTANTE: Incluir Min/Max"
                        cIcone := "BR_AMARELO"
                    ElseIf nMesesConsecutivos >= 3
                        cAcao  := "AVALIAR: Candidato a Min/Max"
                        cIcone := "BR_AZUL"
                    ElseIf nTotalMeses >= 5
                        cAcao  := "IMPORTANTE: " + cValToChar(nTotalMeses) + " meses recorrentes (nao consecutivos)"
                        cIcone := "BR_AMARELO"
                    ElseIf nTotalMeses >= 3
                        cAcao  := "AVALIAR: " + cValToChar(nTotalMeses) + " meses recorrentes (nao consecutivos)"
                        cIcone := "BR_AZUL"
                    ElseIf nTotalMeses == 2
                        cAcao  := "OBSERVAR: 2 meses com compra no periodo"
                        cIcone := "BR_VERDE"
                    Else
                        cAcao  := "OBSERVAR: compra unica no periodo"
                        cIcone := "BR_VERDE"
                    EndIf

                    // Adiciona no array completo
                    aAdd(aItensFull, {;
                        cProduto,              ; // 1  - Produto
                        SB1->B1_DESC,          ; // 2  - Descrição
                        SB1->B1_ESTSEG,        ; // 3  - Estoque Segurança
                        nOcorrencias,          ; // 4  - Nº Ocorrências
                        nQtdTotal,             ; // 5  - Qtd Total
                        dUltima,               ; // 6  - Última Compra
                        dPrimeira,             ; // 7  - Primeira Compra
                        0,                     ; // 8  - (não usado)
                        cFornPrinc,            ; // 9  - Fornecedor Principal
                        cNomeForn,             ; // 10 - Nome Fornecedor
                        cAcao,                 ; // 11 - Ação Sugerida
                        cIcone,                ; // 12 - Ícone de status
                        nMesesConsecutivos,    ; // 13 - Meses CONSECUTIVOS
                        nQtdMedia,             ; // 14 - Qtd Média por Compra
                        nSugMin,               ; // 15 - Sugestão Mínimo
                        nSugMax,               ; // 16 - Sugestão Máximo
                        aClone(aMeses),        ; // 17 - Array dos meses com compras
                        nValorUnit,            ; // 18 - Valor Unitario
                        nValorTotal,           ; // 19 - Valor Total Max Sug
                        nTotalBaixas,          ; // 20 - Total baixas no periodo (SD3)
                        nMediaMensal,          ; // 21 - Media mensal de baixas
                        nMesesBaixas,          ; // 22 - Meses com baixas
                        nTotalMeses            ; // 23 - Total de meses com compras
                    })
                EndIf
            EndIf

    EndDo

    (cAlias)->(DbCloseArea())

    // Ordena por prioridade (meses consecutivos - maior primeiro)
    aSort(aItensFull, , , {|x, y| If(x[13] != y[13], x[13] > y[13], x[23] > y[23])})

    nTotalFull := Len(aItensFull)

    If nTotalFull == 0
        aItens := {}
        MsgInfo("Nenhum produto encontrado no periodo selecionado.", "Aviso")
        oBrowse:SetArray(aItens)
        oBrowse:Refresh()
    Else
        // Aplica o filtro atual sem exibir mensagem de filtro
        lSilentFilter := .T.
        AplicaFiltros()
        lSilentFilter := .F.

        If Len(aItens) == 0
            MsgInfo("Encontrados " + cValToChar(nTotalFull) + " produto(s), mas nenhum corresponde ao filtro '" + cFiltroAcao + "'.", "Aviso")
        Else
            MsgInfo("Encontrados " + cValToChar(nTotalFull) + " produto(s) | Exibindo " + cValToChar(Len(aItens)) + " com filtro '" + cFiltroAcao + "'.", "Sucesso")
        EndIf
    EndIf

Return

/*/{Protheus.doc} VerificaMesesConsecutivos
Verifica a maior sequência de meses consecutivos
@param aMeses - Array com meses no formato AAAAMM
@return nMesesConsecutivos
@author Juan
@since 2026.02.05
/*/
Static Function VerificaMesesConsecutivos(aMeses)
    Local nConsecutivos := 1 as numeric
    Local nMaxConsec := 1 as numeric
    Local nX as numeric
    Local nAnoAnt as numeric
    Local nMesAnt as numeric
    Local nAnoAtual as numeric
    Local nMesAtual as numeric

    If Len(aMeses) < 2
        Return Len(aMeses)
    EndIf

    aSort(aMeses)

    For nX := 2 To Len(aMeses)
        nAnoAnt := Val(SubStr(aMeses[nX-1], 1, 4))
        nMesAnt := Val(SubStr(aMeses[nX-1], 5, 2))

        nAnoAtual := Val(SubStr(aMeses[nX], 1, 4))
        nMesAtual := Val(SubStr(aMeses[nX], 5, 2))

        // Verifica se é o próximo mês
        If (nAnoAtual == nAnoAnt .AND. nMesAtual == nMesAnt + 1) .OR. ;
           (nAnoAtual == nAnoAnt + 1 .AND. nMesAnt == 12 .AND. nMesAtual == 1)
            nConsecutivos++
            nMaxConsec := Max(nMaxConsec, nConsecutivos)
        Else
            nConsecutivos := 1
        EndIf
    Next nX

Return nMaxConsec

/*/{Protheus.doc} AplicaFiltros
Aplica filtros de produto e ação sugerida
@type function
@author Juan
@since 2026.02.05
/*/
Static Function AplicaFiltros()
    Local nX as numeric
    Local lIncluir as logical

    aItens := {}

    For nX := 1 To Len(aItensFull)
        lIncluir := .T.

        // Filtro por acao sugerida / tipo de recorrencia
        If cFiltroAcao == "TODOS"
            // Mostra apenas os recorrentes (3+ meses consecutivos ou totais)
            If aItensFull[nX][23] < 3 .And. aItensFull[nX][13] < 3
                lIncluir := .F.
            EndIf
        ElseIf cFiltroAcao == "CONSECUTIVO"
            // So itens com meses consecutivos >= 3
            If aItensFull[nX][13] < 3
                lIncluir := .F.
            EndIf
        ElseIf cFiltroAcao == "RECORRENTE"
            // So itens recorrentes nao consecutivos
            If aItensFull[nX][13] >= 3
                lIncluir := .F.
            EndIf
        Else
            If !(cFiltroAcao $ aItensFull[nX][11])
                lIncluir := .F.
            EndIf
        EndIf

        // Filtro por código do produto
        If lIncluir .And. !Empty(AllTrim(cFiltroProd))
            If !(AllTrim(cFiltroProd) $ aItensFull[nX][1])
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

Return

/*/{Protheus.doc} MostraLegenda
Exibe legenda de cores e acoes - usa MSEDIT rolavel para exibir todo o conteudo
@type function
/*/
Static Function MostraLegenda()
    Local oDlgLeg as object
    Local oPanel  as object
    Local oEdit   as object
    Local oBtn    as object
    Local cTexto  as character

    cTexto := "--- CLASSIFICACAO POR CRITICIDADE ---"                                                         + Chr(13)+Chr(10)
    cTexto += Chr(13)+Chr(10)
    cTexto += "CRITICO - 5+ meses CONSECUTIVOS de compras"                                                    + Chr(13)+Chr(10)
    cTexto += "   Minimo = Base x 2  |  Maximo = Base x 4"                                                   + Chr(13)+Chr(10)
    cTexto += "   Acao: Incluir controle Min/Max IMEDIATAMENTE"                                               + Chr(13)+Chr(10)
    cTexto += Chr(13)+Chr(10)
    cTexto += "IMPORTANTE - 4 meses consecutivos  OU  5+ meses recorrentes"                                   + Chr(13)+Chr(10)
    cTexto += "   Minimo = Base x 1,5  |  Maximo = Base x 3"                                                 + Chr(13)+Chr(10)
    cTexto += "   Acao: Incluir controle Min/Max"                                                             + Chr(13)+Chr(10)
    cTexto += Chr(13)+Chr(10)
    cTexto += "AVALIAR - 3 meses consecutivos  OU  3-4 meses recorrentes"                                     + Chr(13)+Chr(10)
    cTexto += "   Minimo = Base x 1  |  Maximo = Base x 2"                                                   + Chr(13)+Chr(10)
    cTexto += "   Acao: Avaliar candidato a controle"                                                         + Chr(13)+Chr(10)
    cTexto += Chr(13)+Chr(10)
    cTexto += "OBSERVAR - 1 ou 2 meses de compra no periodo"                                                  + Chr(13)+Chr(10)
    cTexto += "   Produto monitorado, ainda sem recorrencia suficiente para Min/Max"                          + Chr(13)+Chr(10)
    cTexto += Chr(13)+Chr(10)
    cTexto += "--- CALCULO DO MINIMO E MAXIMO ---"                                                            + Chr(13)+Chr(10)
    cTexto += Chr(13)+Chr(10)
    cTexto += "Base = Media mensal de BAIXAS (SD3 - saidas com TM = 502 no periodo)"                         + Chr(13)+Chr(10)
    cTexto += "Se sem baixas, usa media de quantidade por pedido de compra (SC7)"                             + Chr(13)+Chr(10)
    cTexto += Chr(13)+Chr(10)
    cTexto += "CRITICO    -> Min = Base x 2,0  |  Max = Base x 4,0"                                          + Chr(13)+Chr(10)
    cTexto += "   Ex: Base = 100  ->  Min = 200   Max = 400"                                                 + Chr(13)+Chr(10)
    cTexto += "IMPORTANTE -> Min = Base x 1,5  |  Max = Base x 3,0"                                          + Chr(13)+Chr(10)
    cTexto += "   Ex: Base = 100  ->  Min = 150   Max = 300"                                                 + Chr(13)+Chr(10)
    cTexto += "AVALIAR    -> Min = Base x 1,0  |  Max = Base x 2,0"                                          + Chr(13)+Chr(10)
    cTexto += "   Ex: Base = 100  ->  Min = 100   Max = 200"                                                 + Chr(13)+Chr(10)
    cTexto += Chr(13)+Chr(10)
    cTexto += "--- COLUNAS DO BROWSE ---"                                                                     + Chr(13)+Chr(10)
    cTexto += Chr(13)+Chr(10)
    cTexto += "Consecutivos  = quantidade de meses consecutivos com compra"                                   + Chr(13)+Chr(10)
    cTexto += "Total Meses   = total de meses distintos com compra no periodo"                                + Chr(13)+Chr(10)
    cTexto += "Num. Compras  = numero de pedidos de compra no periodo"                                        + Chr(13)+Chr(10)
    cTexto += Chr(13)+Chr(10)
    cTexto += "--- FILTROS DISPONIVEIS ---"                                                                   + Chr(13)+Chr(10)
    cTexto += Chr(13)+Chr(10)
    cTexto += "TODOS       = produtos com 3+ meses consecutivos ou recorrentes"                               + Chr(13)+Chr(10)
    cTexto += "CONSECUTIVO = apenas sequencias de 3+ meses seguidos"                                         + Chr(13)+Chr(10)
    cTexto += "RECORRENTE  = 3+ meses recorrentes nao consecutivos"                                          + Chr(13)+Chr(10)
    cTexto += "CRITICO     = 5+ meses consecutivos"                                                          + Chr(13)+Chr(10)
    cTexto += "IMPORTANTE  = 4 meses consecutivos ou 5+ recorrentes"                                         + Chr(13)+Chr(10)
    cTexto += "AVALIAR     = 3 meses consecutivos ou 3-4 recorrentes"                                        + Chr(13)+Chr(10)
    cTexto += "1+ COMPRA   = todos os produtos comprados no periodo (sem limite de meses)"                    + Chr(13)+Chr(10)
    cTexto += "              Inclui OBSERVAR: produtos com 1 ou 2 meses de compra"                           + Chr(13)+Chr(10)

    DEFINE MSDIALOG oDlgLeg TITLE "Criterios de Classificacao" FROM 000,000 TO 320,620 PIXEL

        oPanel := TPanel():New(000, 000, "", oDlgLeg, , .T., , , , 620, 320, .F., .F.)
        oPanel:Align := CONTROL_ALIGN_ALLCLIENT

        oEdit := TMultiGet():New(005, 005, {|u| If(PCount() > 0, cTexto := u, cTexto)}, oPanel, NIL, NIL, 608, 290, NIL, NIL, .T., NIL, .T.)

        @ 300, 277 BUTTON oBtn PROMPT "Fechar" SIZE 065, 013 OF oPanel PIXEL ACTION oDlgLeg:End()

    ACTIVATE MSDIALOG oDlgLeg CENTERED

Return
/*/{Protheus.doc} DetalheItem
Exibe detalhes do item selecionado
@type function
/*/
Static Function DetalheItem()
    Local oDlgDet    as object
    Local oPanel     as object
    Local oBtn       as object
    Local nLinha     as numeric
    Local aMesesItem as array
    Local nX         as numeric
    Local cMesesStr  as character
    Local cBaseDesc  as character
    Local cMesLinha1 as character
    Local cMesLinha2 as character
    Local cMesLinha3 as character
    Local nTotMeses  as numeric
    Local cAcao      as character
    Local cProd      as character
    Local cDesc      as character

    If Len(aItens) == 0
        Return
    EndIf

    nLinha    := oBrowse:nAt
    aMesesItem := aItens[nLinha][17]
    nTotMeses  := Len(aMesesItem)
    cAcao      := aItens[nLinha][11]
    cProd      := AllTrim(aItens[nLinha][1])
    cDesc      := Left(AllTrim(aItens[nLinha][2]), 48)

    If aItens[nLinha][21] > 0
        cBaseDesc := "Baixas SD3: " + Transform(aItens[nLinha][21],"@E 999,999.99") + " un/mes"
    Else
        cBaseDesc := "Media por OC (sem baixas)"
    EndIf

    // Monta periodos em linhas de 6
    cMesLinha1 := ""
    cMesLinha2 := ""
    cMesLinha3 := ""
    For nX := 1 To Min(nTotMeses, 18)
        cMesesStr := aMesesItem[nX]
        If nX <= 6
            cMesLinha1 += SubStr(cMesesStr,5,2) + "/" + SubStr(cMesesStr,1,4) + "  "
        ElseIf nX <= 12
            cMesLinha2 += SubStr(cMesesStr,5,2) + "/" + SubStr(cMesesStr,1,4) + "  "
        Else
            cMesLinha3 += SubStr(cMesesStr,5,2) + "/" + SubStr(cMesesStr,1,4) + "  "
        EndIf
    Next nX

    DEFINE MSDIALOG oDlgDet TITLE "Produto: " + cProd FROM 000,000 TO 285,665 PIXEL

        oPanel := TPanel():New(000, 000, "", oDlgDet, , .T., , , , 665, 285, .F., .F.)
        oPanel:Align := CONTROL_ALIGN_ALLCLIENT

        // === IDENTIFICACAO ===
        @ 006, 010 SAY cProd + "  |  " + cDesc SIZE 630, 010 OF oPanel PIXEL
        @ 018, 010 SAY ">> " + cAcao           SIZE 630, 010 OF oPanel PIXEL
        @ 030, 008 SAY Replicate("=", 97)       SIZE 640, 007 OF oPanel PIXEL

        // === COLUNA ESQUERDA: COMPRAS ===
        @ 038, 010 SAY "[ COMPRAS NO PERIODO ]"                                              SIZE 298, 009 OF oPanel PIXEL
        @ 049, 010 SAY "Meses com compra           :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 049, 138 SAY cValToChar(aItens[nLinha][23]) + "  (" + cValToChar(aItens[nLinha][13]) + " consecutivos)" SIZE 172, 008 OF oPanel PIXEL
        @ 060, 010 SAY "Pedidos de compra          :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 060, 138 SAY cValToChar(aItens[nLinha][4]) + " pedidos"                            SIZE 172, 008 OF oPanel PIXEL
        @ 071, 010 SAY "Quantidade total comprada  :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 071, 138 SAY Transform(aItens[nLinha][5], "@E 9,999,999.99") + " un"              SIZE 172, 008 OF oPanel PIXEL
        @ 082, 010 SAY "Media de qtd por pedido    :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 082, 138 SAY Transform(aItens[nLinha][14], "@E 9,999,999.99") + " un"             SIZE 172, 008 OF oPanel PIXEL
        @ 093, 010 SAY "Valor unitario             :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 093, 138 SAY "R$ " + Transform(aItens[nLinha][18], "@E 9,999,999.99")              SIZE 172, 008 OF oPanel PIXEL
        @ 104, 010 SAY "Primeira compra            :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 104, 138 SAY DtoC(aItens[nLinha][7])                                               SIZE 172, 008 OF oPanel PIXEL
        @ 115, 010 SAY "Ultima compra              :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 115, 138 SAY DtoC(aItens[nLinha][6])                                               SIZE 172, 008 OF oPanel PIXEL
        @ 126, 010 SAY "Ultimo fornecedor          :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 126, 138 SAY Left(aItens[nLinha][9] + " " + aItens[nLinha][10], 34)               SIZE 172, 008 OF oPanel PIXEL

        // === COLUNA DIREITA: PARAMETRIZACAO ===
        @ 038, 338 SAY "[ PARAMETRIZACAO SUGERIDA ]"                                         SIZE 298, 009 OF oPanel PIXEL
        @ 049, 338 SAY "Base de calculo            :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 049, 466 SAY Left(cBaseDesc, 34)                                                   SIZE 172, 008 OF oPanel PIXEL
        @ 060, 338 SAY "Estoque minimo sugerido    :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 060, 466 SAY Transform(aItens[nLinha][15], "@E 9,999,999")                         SIZE 172, 008 OF oPanel PIXEL
        @ 071, 338 SAY "Estoque maximo sugerido    :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 071, 466 SAY Transform(aItens[nLinha][16], "@E 9,999,999")                         SIZE 172, 008 OF oPanel PIXEL
        @ 082, 338 SAY "Valor total maximo sugerido:"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 082, 466 SAY "R$ " + Transform(aItens[nLinha][19], "@E 9,999,999.99")              SIZE 172, 008 OF oPanel PIXEL

        @ 098, 338 SAY "[ BAIXAS NO ALMOXARIFADO (SD3 - TM=502) ]"                          SIZE 298, 009 OF oPanel PIXEL
        @ 109, 338 SAY "Itens baixados no almox.   :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 109, 466 SAY Transform(aItens[nLinha][20], "@E 9,999,999.99") + " un"             SIZE 172, 008 OF oPanel PIXEL
        @ 120, 338 SAY "Meses com baixas           :"                                        SIZE 125, 008 OF oPanel PIXEL
        @ 120, 466 SAY cValToChar(aItens[nLinha][22]) + " meses"                             SIZE 172, 008 OF oPanel PIXEL
        @ 131, 338 SAY "Media mensal de consumo    :"                                        SIZE 125, 008 OF oPanel PIXEL
        If aItens[nLinha][22] > 0
            @ 131, 466 SAY Transform(aItens[nLinha][21], "@E 999,999.99") + " un/mes"        SIZE 172, 008 OF oPanel PIXEL
        Else
            @ 131, 466 SAY "(sem baixas no periodo)"                                         SIZE 172, 008 OF oPanel PIXEL
        EndIf

        // === PERIODOS COM COMPRAS ===
        @ 143, 008 SAY Replicate("=", 97)     SIZE 640, 007 OF oPanel PIXEL
        @ 152, 010 SAY "[ PERIODOS COM COMPRAS ]" SIZE 300, 009 OF oPanel PIXEL
        @ 163, 010 SAY AllTrim(cMesLinha1)    SIZE 630, 009 OF oPanel PIXEL
        If !Empty(AllTrim(cMesLinha2))
            @ 174, 010 SAY AllTrim(cMesLinha2) SIZE 630, 009 OF oPanel PIXEL
        EndIf
        If !Empty(AllTrim(cMesLinha3))
            @ 185, 010 SAY AllTrim(cMesLinha3) SIZE 630, 009 OF oPanel PIXEL
        EndIf

        // === BOTAO ===
        @ 258, 293 BUTTON oBtn PROMPT "Fechar" SIZE 065, 013 OF oPanel PIXEL ACTION oDlgDet:End()

    ACTIVATE MSDIALOG oDlgDet CENTERED

Return


/*/{Protheus.doc} ArredInteligente
Arredonda baseado na parte decimal
@param nValor - Valor a ser arredondado
@return nValorArredondado
/*/
Static Function ArredInteligente(nValor)
    Local nParteInteira as numeric
    Local nParteDecimal as numeric
    Local nResultado as numeric

    nParteInteira := Int(nValor)
    nParteDecimal := nValor - nParteInteira

    If nParteDecimal < 0.50
        nResultado := nParteInteira
    Else
        nResultado := nParteInteira + 1
    EndIf

Return nResultado
