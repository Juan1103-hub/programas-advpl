#Include "totvs.ch"
#Include "rptdef.ch"

/*/{Protheus.doc} ZRPCPDF
Gera o PDF do Pedido de Compra no layout padrao Protheus (MATA120),
desenhado graficamente com FWMSPrinter (caixas, colunas e textos nas
posicoes exatas do padrao) - 100% editavel por codigo.

Blocos reproduzidos (mesma ordem do padrao):
  1. Titulo: "Pedido de compra" | Moeda / Data base / Numero / Emissao
  2. Informacoes da Empresa x Informacoes do Fornecedor (2 colunas)
  3. Grade de Itens (Item, Produto, Descricao, Unid., Qtde., Prc. Un.,
     Vl. Total, Dt. Entrega, C. Custo)
  4. Demais Informacoes (Descontos, Cond. Pagamento, Locais, Obs.)
  5. Valores e Impostos (Despesas, Seguro, Frete, IPI, ICMS, Totais)
  6. Aprovacao (Comprador, Comprador Alternativo, Aprovadores, Status)

O PDF e aberto no visualizador do SmartClient (permite salvar/enviar).
Paginacao automatica quando o pedido tem mais itens do que cabe na pagina.

Uso: U_ZRPCPDF()          - pede o numero do pedido e gera o PDF.
     U_ZRPCPDF("012564")  - gera direto para o numero informado.

@type     User Function
@author   Suprimentos
@since    17/09/2026
@version  1.0
@param    cNumPed, character, (opcional) Numero do pedido a imprimir
@return   NIL
@example  U_ZRPCPDF("012564")
/*/

User Function ZRPCPDF(cNumPed)

    Local aPergs  := {}
    Local aResps  := {}
    Local aArea   := GetArea()
    Local cPedido := ""

    // Aceita chamada direta com o numero do pedido
    If ValType(cNumPed) == "C" .And. !Empty(cNumPed)
        cPedido := PadR(cNumPed, TamSX3("C7_NUM")[1])
    Else
        aAdd(aPergs, {1, "Pedido:", Space(TamSX3("C7_NUM")[1]), "", ".T.", "", ".T.", 60, .F.})
        If !ParamBox(aPergs, "PDF do Pedido de Compra", @aResps, , , , , , , "ZRPCPDF", .T., .T.)
            RestArea(aArea)
            Return Nil
        EndIf
        cPedido := aResps[1]
    EndIf

    fGeraPdf(cPedido)

    RestArea(aArea)
Return Nil

/*/{Protheus.doc} fGeraPdf
Localiza o pedido na SC7, monta cabecalho, itens e totais e desenha
o PDF com FWMSPrinter, paginando quando necessario.

@type   Static Function
@param  cPedido, character, Numero do pedido (C7_NUM)
@return NIL
/*/
Static Function fGeraPdf(cPedido)

    Local cAliasQry := "QRY_PDF"
    Local cQuery    := ""
    Local cObs      := ""
    Local aArea     := GetArea()
    Local aPed      := Nil
    Local aItens    := {}
    Local aTot      := Nil
    Local aLinha    := Nil
    Local lTemFrete := .F.
    Local lTemDesp  := .F.
    Local lTemSeg   := .F.
    Local lTemMoeda := .F.
    Local lTemObs   := .F.

    // Verificacao de campos opcionais no dicionario (executa 1x, fora de loop)
    lTemFrete := FieldPos("C7_FRETE")   > 0
    lTemDesp  := FieldPos("C7_DESPESA") > 0
    lTemSeg   := FieldPos("C7_SEGURO")  > 0
    lTemMoeda := FieldPos("C7_MOEDA")   > 0
    lTemObs   := FieldPos("C7_OBS")     > 0

    cQuery := "SELECT C7_FILIAL, C7_NUM, C7_ITEM, C7_EMISSAO, C7_PRODUTO, C7_DESCRI, "
    cQuery += "       C7_UM, C7_QUANT, C7_PRECO, C7_TOTAL, C7_DATPRF, C7_CC, "
    cQuery += "       C7_FORNECE, C7_LOJA, C7_COND, C7_CONAPRO, C7_CODCOMP, "
    cQuery += "       C7_VALIPI, C7_VALICM, C7_VLDESC, "
    If lTemFrete
        cQuery += "       C7_FRETE, "
    Else
        cQuery += "       0 AS C7_FRETE, "
    EndIf
    If lTemDesp
        cQuery += "       C7_DESPESA, "
    Else
        cQuery += "       0 AS C7_DESPESA, "
    EndIf
    If lTemSeg
        cQuery += "       C7_SEGURO, "
    Else
        cQuery += "       0 AS C7_SEGURO, "
    EndIf
    If lTemMoeda
        cQuery += "       C7_MOEDA, "
    Else
        cQuery += "       1 AS C7_MOEDA, "
    EndIf
    If lTemObs
        cQuery += "       C7_OBS "
    Else
        cQuery += "       '' AS C7_OBS "
    EndIf
    cQuery += "FROM " + RetSqlName("SC7") + " SC7 WITH (NOLOCK) "
    cQuery += "WHERE SC7.D_E_L_E_T_ = ' ' "
    cQuery += "  AND SC7.C7_FILIAL = '" + xFilial("SC7") + "' "
    cQuery += "  AND SC7.C7_NUM    = '" + cPedido + "' "
    cQuery += "ORDER BY C7_FILIAL, C7_NUM, C7_ITEM "

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasQry, .F., .T.)

    TCSetField(cAliasQry, "C7_EMISSAO", "D",  8, 0)
    TCSetField(cAliasQry, "C7_DATPRF" , "D",  8, 0)
    TCSetField(cAliasQry, "C7_QUANT"  , "N", 12, 2)
    TCSetField(cAliasQry, "C7_PRECO"  , "N", 14, 2)
    TCSetField(cAliasQry, "C7_TOTAL"  , "N", 14, 2)
    TCSetField(cAliasQry, "C7_VALIPI" , "N", 14, 2)
    TCSetField(cAliasQry, "C7_VALICM" , "N", 14, 2)
    TCSetField(cAliasQry, "C7_VLDESC" , "N", 14, 2)
    TCSetField(cAliasQry, "C7_FRETE"  , "N", 14, 2)
    TCSetField(cAliasQry, "C7_DESPESA", "N", 14, 2)
    TCSetField(cAliasQry, "C7_SEGURO" , "N", 14, 2)
    TCSetField(cAliasQry, "C7_MOEDA"  , "N",  2, 0)

    DbSelectArea(cAliasQry)
    (cAliasQry)->(DbGoTop())

    If (cAliasQry)->(Eof())
        (cAliasQry)->(DbCloseArea())
        MsgAlert("Pedido " + AllTrim(cPedido) + " nao encontrado na filial " + xFilial("SC7") + ".", "ZRPCPDF")
        RestArea(aArea)
        Return Nil
    EndIf

    cObs := ""
    If lTemObs
        cObs := AllTrim((cAliasQry)->C7_OBS)
    EndIf

    aPed   := fDadosPedido(cAliasQry, cPedido)
    aItens := {}
    aTot   := {0, 0, 0, 0, 0, 0, 0}

    While (cAliasQry)->(!Eof())
        aLinha := {;
            AllTrim((cAliasQry)->C7_ITEM),;
            AllTrim((cAliasQry)->C7_PRODUTO),;
            AllTrim((cAliasQry)->C7_DESCRI),;
            AllTrim((cAliasQry)->C7_UM),;
            (cAliasQry)->C7_QUANT,;
            (cAliasQry)->C7_PRECO,;
            (cAliasQry)->C7_TOTAL,;
            DtoC((cAliasQry)->C7_DATPRF),;
            AllTrim((cAliasQry)->C7_CC)}
        aAdd(aItens, aLinha)

        aTot[1] += (cAliasQry)->C7_TOTAL
        aTot[2] += (cAliasQry)->C7_VLDESC
        aTot[3] += (cAliasQry)->C7_VALIPI
        aTot[4] += (cAliasQry)->C7_VALICM
        aTot[5] += (cAliasQry)->C7_FRETE
        aTot[6] += (cAliasQry)->C7_DESPESA
        aTot[7] += (cAliasQry)->C7_SEGURO
        (cAliasQry)->(DbSkip())
    End
    (cAliasQry)->(DbCloseArea())

    fDesenha(aPed, aItens, aTot, cObs)

    RestArea(aArea)
Return Nil

/*/{Protheus.doc} fDadosPedido
Reune os dados de cabecalho: empresa (SM0), fornecedor (SA2),
condicao de pagamento (SE4), comprador (SY1), aprovadores (SCR),
moeda e status de aprovacao.

@type   Static Function
@param  cAliasQry, character, Alias da query de itens
@param  cPedido  , character, Numero do pedido
@return array, Dados do pedido
/*/
Static Function fDadosPedido(cAliasQry, cPedido)

    Local aArea    := GetArea()
    Local aPed     := Nil
    Local cRazEmp  := ""
    Local cCnpjEmp := ""
    Local cEndEmp  := ""
    Local cCepEmp  := ""
    Local cCidEmp  := ""
    Local cTelEmp  := ""
    Local cLocEnt  := ""
    Local cLocCob  := ""
    Local cRazFor  := ""
    Local cCnpjFor := ""
    Local cEndFor  := ""
    Local cCepFor  := ""
    Local cCodLoja := ""
    Local cCond    := ""
    Local cComprad := ""
    Local cAprov   := ""
    Local cNomeApr := ""
    Local cStatus  := ""
    Local cMoeda   := "REAL"
    Local nMoeda   := 1
    Local lTemSY1  := FieldPos("Y1_NOME") > 0
    Local lTemSCR  := FieldPos("CR_TIPO") > 0 .And. FieldPos("CR_STATUS") > 0 .And. FieldPos("CR_USER") > 0

    // Empresa (dados da filial corrente)
    cRazEmp  := AllTrim(SM0->M0_NOMECOM)
    cCnpjEmp := AllTrim(SM0->M0_CGC)
    cEndEmp  := AllTrim(SM0->M0_ENDENT)
    cCepEmp  := AllTrim(SM0->M0_CEPENT)
    cCidEmp  := AllTrim(SM0->M0_CIDENT)
    cTelEmp  := AllTrim(SM0->M0_TEL)
    cLocEnt  := cEndEmp + " - " + cCidEmp + " - " + cCepEmp
    cLocCob  := AllTrim(SM0->M0_ENDCOB)

    // Fornecedor
    DbSelectArea("SA2")
    SA2->(DbSetOrder(1))  // A2_FILIAL + A2_COD + A2_LOJA
    If SA2->(DbSeek(xFilial("SA2") + (cAliasQry)->C7_FORNECE + (cAliasQry)->C7_LOJA))
        cRazFor  := AllTrim(SA2->A2_NOME)
        cCnpjFor := AllTrim(SA2->A2_CGC)
        cEndFor  := AllTrim(SA2->A2_END)
        cCepFor  := AllTrim(SA2->A2_CEP)
    EndIf
    cCodLoja := AllTrim((cAliasQry)->C7_FORNECE) + " " + AllTrim((cAliasQry)->C7_LOJA)

    // Condicao de pagamento
    DbSelectArea("SE4")
    SE4->(DbSetOrder(1))  // E4_FILIAL + E4_CODIGO
    If SE4->(DbSeek(xFilial("SE4") + (cAliasQry)->C7_COND))
        cCond := AllTrim(SE4->E4_DESCRI)
    EndIf

    // Comprador responsavel (nome via SY1)
    cComprad := AllTrim((cAliasQry)->C7_CODCOMP)
    If lTemSY1
        DbSelectArea("SY1")
        SY1->(DbSetOrder(1))
        If SY1->(DbSeek(PadR((cAliasQry)->C7_CODCOMP, TamSX3("Y1_COD")[1])))
            cComprad := AllTrim(SY1->Y1_NOME)
        EndIf
    EndIf

    // Aprovadores do pedido (workflow - SCR)
    cAprov := ""
    If lTemSCR
        DbSelectArea("SCR")
        SCR->(DbSetOrder(1))  // CR_FILIAL + CR_NUM + CR_TIPO + CR_NIVEL
        If SCR->(DbSeek(xFilial("SCR") + PadR(cPedido, TamSX3("CR_NUM")[1]) + "SC"))
            While SCR->(!Eof()) ;
                  .And. SCR->CR_FILIAL == xFilial("SCR") ;
                  .And. PadR(SCR->CR_NUM, TamSX3("CR_NUM")[1]) == PadR(cPedido, TamSX3("CR_NUM")[1]) ;
                  .And. SCR->CR_TIPO == "SC"

                cNomeApr := AllTrim(SCR->CR_USER)
                If lTemSY1
                    SY1->(DbSetOrder(1))
                    If SY1->(DbSeek(PadR(SCR->CR_USER, TamSX3("Y1_COD")[1])))
                        cNomeApr := AllTrim(SY1->Y1_NOME)
                    EndIf
                EndIf
                If SCR->CR_STATUS == "02"
                    cAprov += cNomeApr + " [Ok] - "
                Else
                    cAprov += cNomeApr + " [##] - "
                EndIf
                SCR->(DbSkip())
            End
            If Len(cAprov) >= 3
                cAprov := SubStr(cAprov, 1, Len(cAprov) - 3)
            EndIf
        EndIf
    EndIf

    // Status geral do pedido
    If (cAliasQry)->C7_CONAPRO == "L"
        cStatus := "Liberado"
    ElseIf (cAliasQry)->C7_CONAPRO == "B"
        cStatus := "Bloqueado"
    ElseIf (cAliasQry)->C7_CONAPRO == "R"
        cStatus := "Residuo"
    Else
        cStatus := "Pendente"
    EndIf

    // Moeda
    If lTemMoeda
        nMoeda := (cAliasQry)->C7_MOEDA
    EndIf
    If nMoeda != 1
        cMoeda := "Moeda " + cValToChar(nMoeda)
    EndIf

    // [1]N.Pedido [2]Emissao [3]RazEmp [4]CnpjEmp [5]EndEmp [6]CepEmp [7]CidEmp
    // [8]TelEmp [9]RazForn [10]CnpjForn [11]EndForn [12]CepForn [13]Cod/Loja
    // [14]Moeda [15]CondPagto [16]Comprador [17]Aprovadores [18]Status
    // [19]LocalEntrega [20]LocalCobranca
    aPed := {;
        AllTrim((cAliasQry)->C7_NUM)          ,;
        DtoC((cAliasQry)->C7_EMISSAO)         ,;
        cRazEmp                               ,;
        cCnpjEmp                              ,;
        cEndEmp                               ,;
        cCepEmp                               ,;
        cCidEmp                               ,;
        cTelEmp                               ,;
        cRazFor                               ,;
        cCnpjFor                              ,;
        cEndFor                               ,;
        cCepFor                               ,;
        cCodLoja                              ,;
        "Moeda: " + cMoeda                    ,;
        cCond                                 ,;
        cComprad                              ,;
        cAprov                                ,;
        cStatus                               ,;
        cLocEnt                               ,;
        cLocCob}

    RestArea(aArea)
Return aPed

/*/{Protheus.doc} fDesenha
Desenha o PDF com FWMSPrinter replicando o layout do MATA120:
titulo, empresa x fornecedor, grade de itens, demais informacoes,
valores e impostos e aprovacao. Pagina A4 retrato, com paginacao
automatica para pedidos com muitos itens.

@type   Static Function
@param  aPed  , array, Dados do cabecalho (fDadosPedido)
@param  aItens, array, Itens do pedido
@param  aTot  , array, Totais [1]Mercadoria [2]Desc [3]IPI [4]ICMS
                       [5]Frete [6]Despesas [7]Seguro
@param  cObs  , character, Observacoes do pedido
@return NIL
/*/
Static Function fDesenha(aPed, aItens, aTot, cObs)

    Local oPrinter  := Nil
    Local oFont07   := Nil
    Local oFont08   := Nil
    Local oFont08N  := Nil
    Local oFont09   := Nil
    Local oFont10N  := Nil
    Local oFont12N  := Nil
    Local cArqPdf   := ""
    Local nLinha    := 0
    Local nX        := 0
    Local nTotImp   := 0
    Local nItensPag := 16
    Local nPag      := 1
    Local nTotPag   := 0

    nTotPag := Int((Len(aItens) + nItensPag - 1) / nItensPag)
    If nTotPag == 0
        nTotPag := 1
    EndIf

    nTotImp := (aTot[1] + aTot[3] + aTot[4] + aTot[5] + aTot[6] + aTot[7]) - aTot[2]

    cArqPdf  := "PEDIDO_" + AllTrim(aPed[1])
    oPrinter := FWMSPrinter():New(cArqPdf, IMP_PDF, .F., , .T.)
    oPrinter:SetPortrait()
    oPrinter:SetPaperSize(DMPAPER_A4)
    oPrinter:SetMargin(15, 15, 15, 15)
    oPrinter:SetResolution(72)

    oFont07  := TFontEx():New(oPrinter, "Arial", 06, 06, .F., .F., .F.)
    oFont08  := TFontEx():New(oPrinter, "Arial", 07, 07, .F., .F., .F.)
    oFont08N := TFontEx():New(oPrinter, "Arial", 07, 07, .T., .F., .F.)
    oFont09  := TFontEx():New(oPrinter, "Arial", 08, 08, .F., .F., .F.)
    oFont10N := TFontEx():New(oPrinter, "Arial", 09, 09, .T., .F., .F.)
    oFont12N := TFontEx():New(oPrinter, "Arial", 10, 10, .T., .F., .F.)

    For nPag := 1 To nTotPag

        oPrinter:StartPage()
        nLinha := 6

        // === 1. TITULO E IDENTIFICACAO ===
        oPrinter:Say(nLinha,      002, "Pedido de compra", oFont12N:oFont)
        oPrinter:Say(nLinha,      340, aPed[14] + "      Data base: " + DtoC(dDataBase), oFont08:oFont)
        oPrinter:Say(nLinha + 12, 002, "N?mero: " + aPed[1] + "      Data Emiss?o: " + aPed[2], oFont08:oFont)

        nLinha += 26

        // === 2. EMPRESA x FORNECEDOR ===
        oPrinter:Say(nLinha, 002, "Informa??es da Empresa", oFont08N:oFont)
        oPrinter:Say(nLinha, 165, "Informa??es do Fornecedor", oFont08N:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "Raz?o Social: " + aPed[3], oFont08:oFont)
        oPrinter:Say(nLinha, 165, "Raz?o Social: " + aPed[9], oFont08:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "CNPJ/CPF: " + aPed[4], oFont08:oFont)
        oPrinter:Say(nLinha, 165, "CNPJ/CPF: " + aPed[10], oFont08:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "Endere?o: " + aPed[5], oFont08:oFont)
        oPrinter:Say(nLinha, 165, "Endere?o: " + aPed[11], oFont08:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "CEP: " + aPed[6], oFont08:oFont)
        oPrinter:Say(nLinha, 165, "CEP: " + aPed[12], oFont08:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "Cidade: " + aPed[7], oFont08:oFont)
        oPrinter:Say(nLinha, 165, "C?digo/Loja: " + aPed[13], oFont08:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "Telefone: " + aPed[8], oFont08:oFont)
        nLinha += 14

        // === 3. GRADE DE ITENS ===
        oPrinter:Say(nLinha, 002, "Item", oFont08N:oFont)
        oPrinter:Say(nLinha, 018, "Produto", oFont08N:oFont)
        oPrinter:Say(nLinha, 070, "Descri??o", oFont08N:oFont)
        oPrinter:Say(nLinha, 178, "Unid.", oFont08N:oFont)
        oPrinter:Say(nLinha, 196, "Qtde.", oFont08N:oFont)
        oPrinter:Say(nLinha, 220, "Prc. Un.", oFont08N:oFont)
        oPrinter:Say(nLinha, 260, "Vl. Total", oFont08N:oFont)
        oPrinter:Say(nLinha, 300, "Dt. Entrega", oFont08N:oFont)
        oPrinter:Say(nLinha, 340, "C. Custo", oFont08N:oFont)
        nLinha += 3
        oPrinter:Line(nLinha, 002, nLinha, 430, CLR_BLACK, "-6")
        nLinha += 6

        // Itens desta pagina
        For nX := ((nPag - 1) * nItensPag) + 1 To Min(nPag * nItensPag, Len(aItens))
            oPrinter:Say(nLinha, 002, aItens[nX][1], oFont08:oFont)
            oPrinter:Say(nLinha, 018, aItens[nX][2], oFont08:oFont)
            nLinha := fSayWrap(oPrinter, nLinha, 070, 105, aItens[nX][3], oFont08)
            oPrinter:Say(nLinha, 178, aItens[nX][4], oFont08:oFont)
            oPrinter:Say(nLinha, 196, Transform(aItens[nX][5], "@E 999,999.99"), oFont08:oFont)
            oPrinter:Say(nLinha, 220, Transform(aItens[nX][6], "@E 999,999,999.99"), oFont08:oFont)
            oPrinter:Say(nLinha, 260, Transform(aItens[nX][7], "@E 999,999,999.99"), oFont08:oFont)
            oPrinter:Say(nLinha, 300, aItens[nX][8], oFont08:oFont)
            oPrinter:Say(nLinha, 340, aItens[nX][9], oFont08:oFont)
            nLinha += 10
        Next nX

        If nPag < nTotPag
            // Itens continuam na proxima pagina; rodape fica na ultima
            oPrinter:EndPage()
            Loop
        EndIf

        nLinha += 8

        // === 4. DEMAIS INFORMACOES ===
        oPrinter:Say(nLinha, 002, "Demais Informa??es", oFont08N:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "Vlr. Total Descontos: " + Transform(aTot[2], "@E 999,999,999.99"), oFont08:oFont)
        oPrinter:Say(nLinha, 220, "Cond. Pagamento: " + aPed[15], oFont08:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "Local de Entrega: " + aPed[19], oFont08:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "Local de Cobran?a: " + aPed[20], oFont08:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "Observa??es: " + cObs, oFont08:oFont)
        nLinha += 14

        // === 5. VALORES E IMPOSTOS ===
        oPrinter:Say(nLinha, 002, "Valores e Impostos", oFont08N:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "Despesas: " + Transform(aTot[6], "@E 999,999,999.99"), oFont08:oFont)
        oPrinter:Say(nLinha, 220, "Vlr. IPI: " + Transform(aTot[3], "@E 999,999,999.99"), oFont08:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "Seguro: " + Transform(aTot[7], "@E 999,999,999.99"), oFont08:oFont)
        oPrinter:Say(nLinha, 220, "Vlr. ICMS: " + Transform(aTot[4], "@E 999,999,999.99"), oFont08:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "Frete: " + Transform(aTot[5], "@E 999,999,999.99"), oFont08:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "Total Mercadoria: " + Transform(aTot[1], "@E 999,999,999.99"), oFont08:oFont)
        oPrinter:Say(nLinha, 220, "Total C/ Impostos: " + Transform(nTotImp, "@E 999,999,999.99"), oFont08N:oFont)
        nLinha += 14

        // === 6. APROVACAO ===
        oPrinter:Say(nLinha, 002, "Aprova??o", oFont08N:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "Comprador Respons?vel: " + aPed[16], oFont08:oFont)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "Comprador Alternativo:", oFont08:oFont)
        nLinha += 10
        nLinha := fSayWrap(oPrinter, nLinha, 002, 105, "Aprovadores: " + aPed[17], oFont08)
        nLinha += 10
        oPrinter:Say(nLinha, 002, "Status: " + aPed[18], oFont08:oFont)

        oPrinter:EndPage()
    Next nPag

    oPrinter:Preview()

    FreeObj(oFont07)
    FreeObj(oFont08)
    FreeObj(oFont08N)
    FreeObj(oFont09)
    FreeObj(oFont10N)
    FreeObj(oFont12N)
    FreeObj(oPrinter)
    oPrinter := Nil
Return Nil

/*/{Protheus.doc} fSayWrap
Imprime um texto quebrando em linhas de ate nLarg caracteres,
avancando a linha a cada quebra.

@type   Static Function
@param  oPrinter, object   , Objeto FWMSPrinter
@param  nLinha  , numeric  , Linha inicial
@param  nCol    , numeric  , Coluna inicial
@param  nLarg   , numeric  , Largura maxima em caracteres
@param  cTexto  , character, Texto a imprimir
@param  oFont   , object   , Fonte (TFontEx)
@return numeric, Linha apos a impressao
/*/
Static Function fSayWrap(oPrinter, nLinha, nCol, nLarg, cTexto, oFont)

    Local cRest := cTexto

    While Len(cRest) > nLarg
        oPrinter:Say(nLinha, nCol, SubStr(cRest, 1, nLarg), oFont:oFont)
        nLinha += 10
        cRest := SubStr(cRest, nLarg + 1)
    End
    oPrinter:Say(nLinha, nCol, cRest, oFont:oFont)
Return nLinha
