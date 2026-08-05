#INCLUDE "PROTHEUS.CH"

#DEFINE CRLF   Chr(13)+Chr(10)
//-------------------------------------------------------------------
//-------------------------------------------------------------------
/*/{Protheus.doc} A010TOK
PE - Validação final antes de gravar produto (MATA010)
Valida:
1. Máximo >= Mínimo
2. Justificativa obrigatória ao alterar Min/Max
3. Se Min ou Max > 0, B1_ZREPOS deve ser "S"
@author Juvenil G. Souza
@since 05/02/2026
@version 3.0
@return lRet - .T. permite gravar, .F. bloqueia
/*/
//-------------------------------------------------------------------
User Function A010TOK()
    Local lRet        := .T.
    Local nMinAnt     := 0
    Local nMaxAnt     := 0
    Local nMinNovo    := M->B1_ESTSEG
    Local nMaxNovo    := M->B1_EMAX
    Local cRepos      := M->B1_ZREPOS
    Local lAlterouMin := .F.
    Local lAlterouMax := .F.
    Local cMsg        := ""
    Local aArea       := GetArea()
    Local aAreaSB1    := SB1->(GetArea())
    
    // === VALIDAÇÃO 1: Máximo >= Mínimo ===
    If nMaxNovo < nMinNovo
        cMsg := "ERRO DE VALIDAÇAO:" + CRLF + CRLF
        cMsg += "Estoque Maximo (" + cValToChar(nMaxNovo) + ") deve ser maior ou igual ao Minimo (" + cValToChar(nMinNovo) + ")."
        MsgStop(cMsg, "VALIDACAO DE ESTOQUE")
        RestArea(aAreaSB1)
        RestArea(aArea)
        lRet        := .F.
    EndIf
    
    // === VALIDAÇÃO 2: Se Min ou Max > 0, B1_ZREPOS deve ser "S" ===
    If (nMinNovo > 0 .OR. nMaxNovo > 0) .And. lRet
        If UPPER(AllTrim(cRepos)) != "S"
            cMsg := "REPOSICAO OBRIGATORIA!" + CRLF + CRLF
            cMsg += "Quando Minimo ou Maximo for maior que zero," + CRLF
            cMsg += "o campo 'Reposicao'deve estar como 'SIM'." + CRLF + CRLF
            cMsg += "Valores informados:" + CRLF
            cMsg += "Estoque Minimo: " + cValToChar(nMinNovo) + CRLF
            cMsg += "Estoque Maximo: " + cValToChar(nMaxNovo) + CRLF
            cMsg += "Reposicao: " + If(Empty(cRepos), "[VAZIO]", cRepos)
            MsgStop(cMsg, "ATENCAO")
            RestArea(aAreaSB1)
            RestArea(aArea)
            lRet        := .F.
        EndIf
    EndIf
    
    // === VALIDAÇÃO 3: Justificativa quando Altera Min/Max ===
    If Type("ALTERA") == "L" .AND. ALTERA .And. lRet
        
        DbSelectArea("SB1")
        SB1->(DbSetOrder(1))
        
        If SB1->(DbSeek(xFilial("SB1") + M->B1_COD))
            
            nMinAnt := SB1->B1_ESTSEG
            nMaxAnt := SB1->B1_EMAX
            
            lAlterouMin := (nMinNovo != nMinAnt)
            lAlterouMax := (nMaxNovo != nMaxAnt)
            
            If lAlterouMin .OR. lAlterouMax
                
                If Empty(AllTrim(M->B1_ZJUSTIF))
                    
                    cMsg := "JUSTIFICATIVA OBRIGATORIA" + CRLF + CRLF
                    cMsg += "Detectada alteracao de estoque:" + CRLF
                    
                    If lAlterouMin
                        cMsg += "Estoque Minimo:" + cValToChar(nMinAnt) + "-" + cValToChar(nMinNovo) + CRLF
                    EndIf
                    
                    If lAlterouMax
                        cMsg += "Estoque Maximo:" + cValToChar(nMaxAnt) + "-" + cValToChar(nMaxNovo) + CRLF
                    EndIf
                    
                    cMsg += CRLF + "Informe a Justificativa para prosseguir com a gravacao."
                    
                    MsgStop(cMsg, "ATENCAO")
                    lRet := .F.
                    
                Else
                    // Atualiza data de alteração
                    M->B1_ZDTALT := dDataBase
                EndIf
                
            EndIf
            
        EndIf
        
    EndIf
    
    RestArea(aAreaSB1)
    RestArea(aArea)

Return lRet
