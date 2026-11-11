#Include "totvs.ch"

/*/{Protheus.doc} ZRPCPED
Relatorio de Pedido de Compra - layout padrao Protheus/TOTVS.

Reproduz o formato de impressao padrao do pedido de compra (MATA120):
cabecalho com dados da empresa e do fornecedor, grade de itens,
demais informacoes (descontos, condicao de pagamento, locais de
entrega/cobranca e observacoes), valores e impostos e bloco de
aprovacao (comprador, aprovadores e status).

Permite filtrar por faixa de pedido, faixa de emissao, ordenacao e
status de aprovacao (Liberados / Bloqueados / Todos).

@type     User Function
@author   Suprimentos
@since    17/09/2026
@version  1.0
@return   NIL, Executa o dialogo de impressao (PDF/impressora)
@example  U_ZRPCPED()
/*/

User Function ZRPCPED()

    Local aPergs   := {}
    Local oReport  := Nil
    Local aArea    := GetArea()
    Private aResps := {}

    aAdd(aPergs, {1, "Pedido De:"    , Space(TamSX3("C7_NUM")[1])    , "", ".T.", "", ".T.", 60, .F.})
    aAdd(aPergs, {1, "Pedido Ate:"   , Replicate("Z", TamSX3("C7_NUM")[1]), "", ".T.", "", ".T.", 60, .T.})
    aAdd(aPergs, {1, "Emissao De:"   , CtoD("")                       , "", ".T.", "", ".T.", 60, .F.})
    aAdd(aPergs, {1, "Emissao Ate:"  , CtoD("")                       , "", ".T.", "", ".T.", 60, .T.})
    aAdd(aPergs, {2, "Ordenar por:"  , 1, {"1=Numero do Pedido", "2=Data de Emissao"}, 120, ".T.", .T.})
    aAdd(aPergs, {2, "Status:"       , 1, {"1=Liberados", "2=Bloqueados", "3=Todos"}, 120, ".T.", .T.})

    If ParamBox(aPergs, "Relatorio Pedido de Compra", @aResps, , , , , , , "ZRPCPED", .T., .T.)
        oReport := fReportDef()
        oReport:PrintDialog()
    EndIf

    RestArea(aArea)
Return Nil

/*/{Protheus.doc} fReportDef
Monta a estrutura do relatorio TReport.

Secao 1 (Cabecalho): duas colunas de texto livre (COLESQ/COLDIR)
para reproduzir o layout de duas colunas do padrao Protheus.
Secao 2 (Itens): grade de colunas do item do pedido.

@type   Static Function
@return object, Objeto TReport montado
/*/
Static Function fReportDef()

    Local oReport := Nil
    Local oSecCab := Nil
    Local oSecItm := Nil

    oReport := TReport():New("ZRPCPED", "Pedido de Compra", "", ;
        {|oReport| ReportPrint(oReport)}, ;
        "Imprime o Pedido de Compra no layout padrao Protheus.", .F.)

    oReport:SetTotalInLine(.F.)
    oReport:lParamPage := .F.
    oReport:oPage:SetPaperSize(9)  // A4 retrato

    // Secao de texto livre (cabecalho/rodape do pedido) - sem header
    oSecCab := TRSection():New(oReport, "Cabecalho", {})
    oSecCab:SetHeaderSection(.F.)
    TRCell():New(oSecCab, "COLESQ", "", "", "", 55, .F.)
    TRCell():New(oSecCab, "COLDIR", "", "", "", 55, .F.)
    oSecCab:Cell("COLESQ"):SetAlign("LEFT")
    oSecCab:Cell("COLDIR"):SetAlign("LEFT")

    // Secao de itens do pedido
    oSecItm := TRSection():New(oReport, "Itens", {})
    oSecItm:SetHeaderSection(.T.)
    TRCell():New(oSecItm, "ITEM",    "", "Item"      , "@!",  6, .F.)
    TRCell():New(oSecItm, "PRODUTO", "", "Produto"   , "@!", 18, .F.)
    TRCell():New(oSecItm, "DESCRI",  "", "Descricao" , "@!", 30, .F.)
    TRCell():New(oSecItm, "UM",      "", "Un."       , "@!",  4, .F.)
    TRCell():New(oSecItm, "QUANT",   "", "Qtde."     , "@E 999,999.99", 10, .F.)
    TRCell():New(oSecItm, "PRECO",   "", "Prc. Un."  , "@E 999,999,999.99", 12, .F.)
    TRCell():New(oSecItm, "TOTAL",   "", "Vl. Total" , "@E 999,999,999.99", 12, .F.)
    TRCell():New(oSecItm, "ENTREGA", "", "Dt. Entrega", "@!", 12, .F.)
    TRCell():New(oSecItm, "CCUSTO",  "", "C. Custo"  , "@!", 12, .F.)

    oSecItm:Cell("QUANT"):SetAlign("RIGHT")
    oSecItm:Cell("PRECO"):SetAlign("RIGHT")
    oSecItm:Cell("TOTAL"):SetAlign("RIGHT")

Return oReport

/*/{Protheus.doc} ReportPrint
Processa a impressao: abre a query de itens do pedido (SC7), agrupa
por numero de pedido e imprime cabecalho, itens e rodape de cada
pedido, com regua de processamento.

@type   Static Function
@param  oReport, object, Objeto TReport
@return NIL
/*/
Static Function ReportPrint(oReport)

    Local cAliasQry := "QRY_ZRPC"
    Local cQuery    := ""
    Local cNumAtu   := ""
    Local cConApro  := ""
    Local cObs      := ""
    Local aArea     := GetArea()
    Local aPed      := {}
    Local aTot      := {}
    Local nTotal    := 0
    Local oSecCab   := oReport:Section(1)
    Local oSecItm   := oReport:Section(2)
    Private lTemFrete := .F.
    Private lTemDesp  := .F.
    Private lTemSeg   := .F.
    Private lTemMoeda := .F.
    Private lTemObs   := .F.
    Private lTemSCR   := .F.
    Private lTemSY1   := .F.

    // Verificacao de campos opcionais no dicionario (executa 1x fora do loop)
    lTemFrete := FieldPos("C7_FRETE")   > 0
    lTemDesp  := FieldPos("C7_DESPESA") > 0
    lTemSeg   := FieldPos("C7_SEGURO")  > 0
    lTemMoeda := FieldPos("C7_MOEDA")   > 0
    lTemObs   := FieldPos("C7_OBS")     > 0
    lTemSCR   := FieldPos("CR_TIPO")    > 0 .And. FieldPos("CR_STATUS") > 0 .And. FieldPos("CR_USER") > 0
    lTemSY1   := FieldPos("Y1_NOME")    > 0

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
    cQuery += "  AND SC7.C7_NUM BETWEEN '" + aResps[1] + "' AND '" + aResps[2] + "' "
    If !Empty(aResps[3]) .And. !Empty(aResps[4])
        cQuery += "  AND SC7.C7_EMISSAO BETWEEN '" + DtoS(aResps[3]) + "' AND '" + DtoS(aResps[4]) + "' "
    ElseIf !Empty(aResps[3])
        cQuery += "  AND SC7.C7_EMISSAO >= '" + DtoS(aResps[3]) + "' "
    ElseIf !Empty(aResps[4])
        cQuery += "  AND SC7.C7_EMISSAO <= '" + DtoS(aResps[4]) + "' "
    EndIf
    If aResps[6] == 1
        cQuery += "  AND (RTRIM(C7_CONAPRO) IN ('', 'L')) "
    ElseIf aResps[6] == 2
        cQuery += "  AND RTRIM(C7_CONAPRO) = 'B' "
    EndIf
    If aResps[5] == 2
        cQuery += "ORDER BY C7_FILIAL, C7_EMISSAO, C7_NUM, C7_ITEM "
    Else
        cQuery += "ORDER BY C7_FILIAL, C7_NUM, C7_ITEM "
    EndIf

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
    Count To nTotal
    (cAliasQry)->(DbGoTop())

    If nTotal == 0
        oReport:SetMsgPrint("Nenhum pedido de compra encontrado para os parametros informados.")
        (cAliasQry)->(DbCloseArea())
        RestArea(aArea)
        Return Nil
    EndIf

    oReport:SetMeter(nTotal)
    oSecCab:Init()
    oSecItm:Init()

    While (cAliasQry)->(!Eof())

        If oReport:Cancel()
            Exit
        EndIf

        cNumAtu  := (cAliasQry)->C7_NUM
        cConApro := AllTrim((cAliasQry)->C7_CONAPRO)
        cObs     := ""
        If lTemObs
            cObs := AllTrim((cAliasQry)->C7_OBS)
        EndIf

        aPed := fDadosPedido(cAliasQry, cNumAtu, cConApro)
        // [1]Mercadoria [2]Descontos [3]IPI [4]ICMS [5]Frete [6]Despesas [7]Seguro
        aTot := {0, 0, 0, 0, 0, 0, 0}

        oReport:SkipLine(2)
        fCabPed(oReport, oSecCab, aPed)

        While (cAliasQry)->(!Eof()) .And. (cAliasQry)->C7_NUM == cNumAtu

            oSecItm:Cell("ITEM"):SetValue((cAliasQry)->C7_ITEM)
            oSecItm:Cell("PRODUTO"):SetValue(AllTrim((cAliasQry)->C7_PRODUTO))
            oSecItm:Cell("DESCRI"):SetValue(AllTrim((cAliasQry)->C7_DESCRI))
            oSecItm:Cell("UM"):SetValue(AllTrim((cAliasQry)->C7_UM))
            oSecItm:Cell("QUANT"):SetValue((cAliasQry)->C7_QUANT)
            oSecItm:Cell("PRECO"):SetValue((cAliasQry)->C7_PRECO)
            oSecItm:Cell("TOTAL"):SetValue((cAliasQry)->C7_TOTAL)
            oSecItm:Cell("ENTREGA"):SetValue(DtoC((cAliasQry)->C7_DATPRF))
            oSecItm:Cell("CCUSTO"):SetValue(AllTrim((cAliasQry)->C7_CC))
            oSecItm:PrintLine()

            aTot[1] += (cAliasQry)->C7_TOTAL
            aTot[2] += (cAliasQry)->C7_VLDESC
            aTot[3] += (cAliasQry)->C7_VALIPI
            aTot[4] += (cAliasQry)->C7_VALICM
            aTot[5] += (cAliasQry)->C7_FRETE
            aTot[6] += (cAliasQry)->C7_DESPESA
            aTot[7] += (cAliasQry)->C7_SEGURO

            oReport:IncMeter()
            (cAliasQry)->(DbSkip())
        End

        fRodapePed(oReport, oSecCab, aPed, aTot, cObs)
        oReport:SetMsgPrint("Imprimindo pedido " + AllTrim(cNumAtu) + "...")
    End

    oSecItm:Finish()
    oSecCab:Finish()
    (cAliasQry)->(DbCloseArea())
    RestArea(aArea)
Return Nil

/*/{Protheus.doc} fDadosPedido
Reune os dados de cabecalho do pedido: empresa (SM0), fornecedor (SA2),
condicao de pagamento (SE4), comprador (SY1), aprovadores (SCR), moeda
e status de aprovacao.

@type   Static Function
@param  cAliasQry, character, Alias da query de itens
@param  cNumPed  , character, Numero do pedido
@param  cConApro , character, Status de aprovacao do pedido (C7_CONAPRO)
@return array, Dados do pedido para impressao
/*/
Static Function fDadosPedido(cAliasQry, cNumPed, cConApro)

    Local aArea     := GetArea()
    Local aPed      := {}
    Local cRazEmp   := ""
    Local cCnpjEmp  := ""
    Local cEndEmp   := ""
    Local cCepEmp   := ""
    Local cCidEmp   := ""
    Local cTelEmp   := ""
    Local cLocEnt   := ""
    Local cLocCob   := ""
    Local cRazFor   := ""
    Local cCnpjFor  := ""
    Local cEndFor   := ""
    Local cCepFor   := ""
    Local cCodLoja  := ""
    Local cCond     := ""
    Local cComprad  := ""
    Local cAprov    := ""
    Local cNomeApr  := ""
    Local cStatus   := ""
    Local cMoeda    := "REAL"
    Local nMoeda    := 1

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

    // Comprador responsavel
    cComprad := AllTrim((cAliasQry)->C7_CODCOMP)
    If lTemSY1
        DbSelectArea("SY1")
        SY1->(DbSetOrder(1))  // Y1_COD
        If SY1->(DbSeek(PadR((cAliasQry)->C7_CODCOMP, TamSX3("Y1_COD")[1])))
            cComprad := AllTrim(SY1->Y1_NOME)
        EndIf
    EndIf

    // Aprovadores do pedido (workflow - SCR)
    cAprov := ""
    If lTemSCR
        DbSelectArea("SCR")
        SCR->(DbSetOrder(1))  // CR_FILIAL + CR_NUM + CR_TIPO + CR_NIVEL
        If SCR->(DbSeek(xFilial("SCR") + PadR(cNumPed, TamSX3("CR_NUM")[1]) + "SC"))
            While SCR->(!Eof()) ;
                  .And. SCR->CR_FILIAL == xFilial("SCR") ;
                  .And. PadR(SCR->CR_NUM, TamSX3("CR_NUM")[1]) == PadR(cNumPed, TamSX3("CR_NUM")[1]) ;
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
    If cConApro == "L"
        cStatus := "Liberado"
    ElseIf cConApro == "B"
        cStatus := "Bloqueado"
    ElseIf cConApro == "R"
        cStatus := "Residuo"
    Else
        cStatus := "Pendente"
    EndIf

    // Moeda
    If lTemMoeda
        nMoeda := (cAliasQry)->C7_MOEDA
    EndIf
    If nMoeda != 1
        cMoeda := "MOEDA " + cValToChar(nMoeda)
    EndIf

    // [1]Numero [2]Emissao [3]RazaoEmpresa [4]CnpjEmpresa [5]EndEmpresa [6]CepEmpresa
    // [7]CidadeEmpresa [8]TelEmpresa [9]RazaoForn [10]CnpjForn [11]EndForn [12]CepForn
    // [13]Cod/Loja [14]Moeda [15]CondPagto [16]Comprador [17]Aprovadores
    // [18]Status [19]LocalEntrega [20]LocalCobranca
    aPed := {;
        AllTrim(cNumPed)                      ,;
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

/*/{Protheus.doc} fCabPed
Imprime o cabecalho do pedido: identificacao, empresa e fornecedor
em duas colunas, conforme layout padrao Protheus.

@type   Static Function
@param  oReport, object, Objeto TReport
@param  oSecCab, object, Secao de texto livre (COLESQ/COLDIR)
@param  aPed   , array , Dados do pedido montados em fDadosPedido
@return NIL
/*/
Static Function fCabPed(oReport, oSecCab, aPed)

    oReport:SkipLine(1)
    fLinha(oSecCab, "Pedido de compra"  , aPed[14])
    fLinha(oSecCab, "Numero: " + aPed[1], "Data base: " + DtoC(dDataBase) + "  Data Emissao: " + aPed[2])
    fLinha(oSecCab, "", "")
    fLinha(oSecCab, "Informacoes da Empresa", "Informacoes do Fornecedor")
    fLinha(oSecCab, "Razao Social: " + aPed[3], "Razao Social: " + aPed[9])
    fLinha(oSecCab, "CNPJ/CPF: " + aPed[4]   , "CNPJ/CPF: " + aPed[10])
    fLinha(oSecCab, "Endereco: " + aPed[5]   , "Endereco: " + aPed[11])
    fLinha(oSecCab, "CEP: " + aPed[6]        , "CEP: " + aPed[12])
    fLinha(oSecCab, "Cidade: " + aPed[7]     , "Codigo/Loja: " + aPed[13])
    fLinha(oSecCab, "Telefone: " + aPed[8]   , "")
    fLinha(oSecCab, "", "")
Return Nil

/*/{Protheus.doc} fRodapePed
Imprime o rodape do pedido: demais informacoes, valores e impostos
e bloco de aprovacao, conforme layout padrao Protheus.

@type   Static Function
@param  oReport, object, Objeto TReport
@param  oSecCab, object, Secao de texto livre (COLESQ/COLDIR)
@param  aPed   , array , Dados do pedido montados em fDadosPedido
@param  aTot   , array , Totais acumulados [1]Mercadoria [2]Descontos
                          [3]IPI [4]ICMS [5]Frete [6]Despesas [7]Seguro
@param  cObs   , character, Observacoes do pedido
@return NIL
/*/
Static Function fRodapePed(oReport, oSecCab, aPed, aTot, cObs)

    Local nTotImp := 0

    nTotImp := (aTot[1] + aTot[3] + aTot[4] + aTot[5] + aTot[6] + aTot[7]) - aTot[2]

    fLinha(oSecCab, "Demais Informacoes", "")
    fLinha(oSecCab, "Vlr. Total Descontos: " + Transform(aTot[2], "@E 999,999,999.99"), "Cond. Pagamento: " + aPed[15])
    fLinha(oSecCab, "Local de Entrega: " + aPed[19], "")
    fLinha(oSecCab, "Local de Cobranca: " + aPed[20], "")
    fLinha(oSecCab, "Observacoes: " + cObs, "")
    fLinha(oSecCab, "", "")
    fLinha(oSecCab, "Valores e Impostos", "")
    fLinha(oSecCab, "Despesas: " + Transform(aTot[6], "@E 999,999,999.99"), "Vlr. IPI: "   + Transform(aTot[3], "@E 999,999,999.99"))
    fLinha(oSecCab, "Seguro: "   + Transform(aTot[7], "@E 999,999,999.99"), "Vlr. ICMS: " + Transform(aTot[4], "@E 999,999,999.99"))
    fLinha(oSecCab, "Frete: "    + Transform(aTot[5], "@E 999,999,999.99"), "")
    fLinha(oSecCab, "Total Mercadoria: "    + Transform(aTot[1], "@E 999,999,999.99"), "Total C/ Impostos: " + Transform(nTotImp, "@E 999,999,999.99"))
    fLinha(oSecCab, "", "")
    fLinha(oSecCab, "Aprovacao", "")
    fLinha(oSecCab, "Comprador Responsavel: " + aPed[16], "")
    fWrap(oSecCab, "Aprovadores: " + aPed[17])
    fLinha(oSecCab, "Status: " + aPed[18], "")
Return Nil

/*/{Protheus.doc} fLinha
Imprime uma linha do bloco de texto livre: coluna esquerda e coluna
direita, reproduzindo o layout de duas colunas do padrao.

@type   Static Function
@param  oSecCab, object, Secao de texto livre
@param  cEsq   , character, Texto da coluna esquerda
@param  cDir   , character, Texto da coluna direita
@return NIL
/*/
Static Function fLinha(oSecCab, cEsq, cDir)
    oSecCab:Cell("COLESQ"):SetValue(cEsq)
    oSecCab:Cell("COLDIR"):SetValue(cDir)
    oSecCab:PrintLine()
Return Nil

/*/{Protheus.doc} fWrap
Imprime um texto longo (ex.: lista de aprovadores) quebrando em
linhas de ate 56 caracteres na coluna esquerda.

@type   Static Function
@param  oSecCab, object, Secao de texto livre
@param  cTexto , character, Texto a quebrar e imprimir
@return NIL
/*/
Static Function fWrap(oSecCab, cTexto)

    Local cRest := cTexto

    While Len(cRest) > 55
        fLinha(oSecCab, SubStr(cRest, 1, 55), "")
        cRest := SubStr(cRest, 56)
    End
    fLinha(oSecCab, cRest, "")
Return Nil
