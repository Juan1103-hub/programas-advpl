#Include 'Protheus.ch'

/*/{Protheus.doc} MTA110OK
Ponto de entrada para validar preenchimento obrigatorio
do campo C1_EC05DB Natureza de Gastos na Solicitacao de Compra
@type User Function
@author Sistema
@since 06/02/2026
/*/
User Function MTA110OK()
    Local lRet     := .T.
    Local nPosNat  := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_EC05DB"})
    // Local nPosDat  := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_DATPRF"})  // REMOVIDO 01/06/2026
    Local nX       := 0
    // Local dNova    := dDataBase + 15  // REMOVIDO 01/06/2026

    ConOut("========================================")
    ConOut("MTA110OK - Validacao Natureza de Gastos")
    ConOut("========================================")

    /* LOGICA COMENTADA EM 01/06/2026:
       C1_DATPRF agora e gerenciado pelo X3_RELACAO (DDATABASE+15) no Configurador.
       Nao e mais necessario forcar a data via PE.
    */
    /*
    // Fallback da necessidade no momento do salvar (MATA110)
    If nPosDat > 0
        For nX := 1 To Len(aCols)
            If !aCols[nX][Len(aHeader)+1]
                aCols[nX][nPosDat] := dNova
            EndIf
        Next nX
        ConOut("MTA110OK - C1_DATPRF ajustada para " + DtoC(dNova) + " em todas as linhas ativas")
    Else
        ConOut("MTA110OK - AVISO: Campo C1_DATPRF nao encontrado no aHeader")
    EndIf
    */

    // Verifica se o campo existe no aHeader
    If nPosNat > 0

        ConOut("Campo C1_EC05DB encontrado na posicao: " + cValToChar(nPosNat))

        // Percorre todas as linhas do aCols
        For nX := 1 To Len(aCols)

            // Verifica apenas linhas nao deletadas
            If !aCols[nX][Len(aHeader)+1]

                // Valida se o campo EC05DB esta preenchido
                If Empty(aCols[nX][nPosNat])

                    Help(,, "CAMPO OBRIGATORIO",, ;
                         "O campo Natureza de Gastos e obrigatorio" + CRLF + ;
                         "Linha: " + cValToChar(nX), ;
                         1, 0,,,,,, {"Preencha o campo Nat Gastos antes de salvar"})

                    lRet := .F.
                    ConOut("ERRO: Campo C1_EC05DB vazio na linha " + cValToChar(nX))
                    Exit

                Else
                    ConOut("Linha " + cValToChar(nX) + " OK - Valor: [" + AllTrim(aCols[nX][nPosNat]) + "]")
                EndIf

            EndIf

        Next nX

    Else
        ConOut("AVISO: Campo C1_EC05DB nao encontrado no aHeader")
    EndIf

    If lRet
        ConOut("Validacao OK - Permite gravar SC")
    Else
        ConOut("Validacao FALHOU - Bloqueia gravacao")
    EndIf

    ConOut("========================================")

Return lRet


/*/{Protheus.doc} MT131WF
Ponto de entrada para replicar campo C1_EC05DB
da SC1 para C8_EC05DB na SC8 apos gerar cotacao
@type User Function
@author Sistema
@since 06/02/2026
/*/
User Function MT131WF()
    Local aArea    := GetArea()
    Local aAreaSC1 := SC1->(GetArea())
    Local aAreaSC8 := SC8->(GetArea())
    Local cNumCot  := ""
    Local nCount   := 0

    // Captura o numero da cotacao gerada
    If ValType(PARAMIXB) == "A" .And. Len(PARAMIXB) >= 1
        cNumCot := PARAMIXB[1]
    Else
        ConOut("ERRO MT131WF: Parametro invalido")
        RestArea(aAreaSC8)
        RestArea(aAreaSC1)
        RestArea(aArea)
        Return
    EndIf

    ConOut("========================================")
    ConOut("MT131WF - Replicando Natureza de Gastos")
    ConOut("Numero da Cotacao: " + cNumCot)
    ConOut("========================================")

    // Posiciona na SC8 da cotacao gerada
    DbSelectArea("SC8")
    SC8->(DbSetOrder(1))
    SC8->(DbSeek(xFilial("SC8") + cNumCot))

    // Percorre todos os itens da cotacao
    While SC8->(!Eof()) .And. ;
          SC8->C8_FILIAL == xFilial("SC8") .And. ;
          SC8->C8_NUM == cNumCot

        ConOut("Processando SC8 - Item: " + SC8->C8_NUMSC + "/" + SC8->C8_ITEMSC)

        // Busca a SC1 correspondente
        DbSelectArea("SC1")
        SC1->(DbSetOrder(1))

        If SC1->(DbSeek(xFilial("SC1") + SC8->C8_NUMSC + SC8->C8_ITEMSC))

            ConOut("SC1 encontrada - C1_EC05DB: [" + AllTrim(SC1->C1_EC05DB) + "]")

            // Verifica se o campo esta preenchido na SC1
            If !Empty(SC1->C1_EC05DB)

                // Grava o campo EC05DB na SC8
                RecLock("SC8", .F.)
                SC8->C8_EC05DB := SC1->C1_EC05DB
                SC8->(MsUnlock())

                nCount++
                ConOut("SC8 gravada - C8_EC05DB: [" + AllTrim(SC8->C8_EC05DB) + "]")

            Else
                ConOut("AVISO: Campo C1_EC05DB vazio na SC1")
            EndIf

        Else
            ConOut("ERRO: SC1 nao encontrada")
        EndIf

        // Avanca para proximo item da cotacao
        DbSelectArea("SC8")
        SC8->(DbSkip())

    EndDo

    ConOut("Total de itens replicados: " + cValToChar(nCount))
    ConOut("========================================")

    // Restaura areas anteriores
    RestArea(aAreaSC8)
    RestArea(aAreaSC1)
    RestArea(aArea)

Return


/*/{Protheus.doc} MT120GOK
Ponto de entrada para replicar campo C8_EC05DB
da SC8 para C7_EC05DB no SC7 ao gerar pedido de compra
@type User Function
@author Sistema
@since 06/02/2026
/*/
User Function MT120GOK()
    Local aArea     := GetArea()
    Local nPosNat   := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_EC05DB"})
    Local nPosCot   := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_NUMCOT"})
    Local nPosItCot := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_ITEMCOT"})
    Local cNumCot   := ""
    Local cItemCot  := ""
    Local nX        := 0

    ConOut("========================================")
    ConOut("MT120GOK - Replicando Natureza de Gastos")
    ConOut("========================================")

    // Verifica se todos os campos existem
    If nPosNat > 0 .And. nPosCot > 0 .And. nPosItCot > 0

        ConOut("Campos encontrados - C7_EC05DB: " + cValToChar(nPosNat))

        // Percorre todas as linhas do pedido
        For nX := 1 To Len(aCols)

            // Verifica se linha nao esta deletada
            If !aCols[nX][Len(aHeader)+1]

                // Captura numero e item da cotacao
                cNumCot  := aCols[nX][nPosCot]
                cItemCot := aCols[nX][nPosItCot]

                ConOut("Linha " + cValToChar(nX) + " - Cotacao: " + cNumCot + "/" + cItemCot)

                // Busca item da cotacao correspondente
                DbSelectArea("SC8")
                SC8->(DbSetOrder(2))

                If SC8->(DbSeek(xFilial("SC8") + cNumCot + cItemCot))

                    // Replica campo EC05DB para o aCols do pedido
                    aCols[nX][nPosNat] := SC8->C8_EC05DB

                    ConOut("Replicado - C7_EC05DB: [" + AllTrim(aCols[nX][nPosNat]) + "]")

                Else
                    ConOut("AVISO: SC8 nao encontrada")
                EndIf

            EndIf

        Next nX

    Else
        ConOut("AVISO: Campos nao encontrados no aHeader")
        ConOut("C7_EC05DB: " + cValToChar(nPosNat))
        ConOut("C7_NUMCOT: " + cValToChar(nPosCot))
        ConOut("C7_ITEMCOT: " + cValToChar(nPosItCot))
    EndIf

    ConOut("========================================")

    // Restaura area anterior
    RestArea(aArea)

Return .T.
