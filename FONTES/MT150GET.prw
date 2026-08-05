#Include 'Protheus.ch'

User Function MT150GET()
    Local aArea := GetArea()
    Local aAreaSC1 := SC1->(GetArea())
    Local nPosNumSC := aScan(aHeader, {|x| AllTrim(x[2]) == "C8_NUMSC"})
    Local nPosItemSC := aScan(aHeader, {|x| AllTrim(x[2]) == "C8_ITEMSC"})
    Local nPosNatGas := aScan(aHeader, {|x| AllTrim(x[2]) == "C8_EC05DB"})
    Local nLinha := 0
    Local cNumSC := ""
    Local cItemSC := ""
    
    // Valida se encontrou as posições dos campos
    If nPosNumSC > 0 .And. nPosItemSC > 0 .And. nPosNatGas > 0
        
        // Percorre todas as linhas do aCols
        For nLinha := 1 To Len(aCols)
            
            // Verifica se a linha não está deletada
            If !aCols[nLinha][Len(aHeader)+1]
                
                cNumSC := aCols[nLinha][nPosNumSC]
                cItemSC := aCols[nLinha][nPosItemSC]
                
                If !Empty(cNumSC) .And. !Empty(cItemSC)
                    DbSelectArea("SC1")
                    SC1->(DbSetOrder(1)) // C1_FILIAL+C1_NUM+C1_ITEM
                    
                    If SC1->(DbSeek(xFilial("SC1") + cNumSC + cItemSC))
                        // Preenche o campo Natureza de Gastos no aCols
                        aCols[nLinha][nPosNatGas] := SC1->C1_EC05DB
                    EndIf
                EndIf
            EndIf
        Next nLinha
    EndIf
    
    RestArea(aAreaSC1)
    RestArea(aArea)
    
Return
