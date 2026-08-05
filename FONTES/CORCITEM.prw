/*
//=============================================================================
// Programa  : CORCITEM
// Função    : U_CORCITEM
// Data      : 07/04/2026
// Descrição : Corrige D3_CUSTO1 na SD3 para um item em Fevereiro/2026.
//             Sem dependência de filial, índice ou SB1.
//             Varre a SD3 diretamente pelo código e data.
//=============================================================================
*/

#Include "Protheus.ch"

User Function CORCITEM()

    Local cCodItem  := Space(30)
    Local nCustoCor := 0
    Local aMovtos   := {}
    Local nI        := 0
    Local cMsg      := ""

    Local dDtIni := CtoD("01/02/2026")
    Local dDtFim := CtoD("28/02/2026")

    // Pede o código do item
    cCodItem := InputBox("Informe o Codigo do Item:", "Correcao de Custo - Fevereiro/2026", "")
    cCodItem := AllTrim(cCodItem)

    If Empty(cCodItem)
        Return
    EndIf

    // Pede o custo médio correto
    nCustoCor := Val(InputBox("Informe o Custo Medio Correto (use ponto como decimal):", ;
                              "Item: " + cCodItem, "0"))

    If nCustoCor <= 0
        MsgStop("Custo deve ser maior que zero.", "Atencao")
        Return
    EndIf

    // Busca movimentos na SD3 — varredura direta, sem MsSeek
    aMovtos := U_VarreSD3(cCodItem, dDtIni, dDtFim)

    If Len(aMovtos) == 0
        MsgStop("Nenhum movimento encontrado para [" + cCodItem + "]" + CRLF + ;
                "no periodo 01/02/2026 a 28/02/2026.", "Sem Dados")
        Return
    EndIf

    // Monta resumo para confirmação
    cMsg := "Item: " + cCodItem + CRLF + ;
            "Custo Correto: R$ " + cValToChar(nCustoCor) + CRLF + ;
            "Movimentos encontrados: " + cValToChar(Len(aMovtos)) + CRLF + CRLF + ;
            "Data       TM    Qtd      CT Atual    CT Novo" + CRLF + ;
            "---------- ----- -------- ----------- -----------" + CRLF

    For nI := 1 To Len(aMovtos)
        cMsg += aMovtos[nI][3] + "  " +              ; // Data
                PadR(aMovtos[nI][4], 5) + "  " +     ; // TM
                Transform(aMovtos[nI][6], "9,999.00") + "  " + ; // Qtd
                Transform(aMovtos[nI][7], "9,999.99") + "  " + ; // CT Atual
                Transform(aMovtos[nI][6] * nCustoCor, "9,999.99") + CRLF  // CT Novo
    Next nI

    cMsg += CRLF + "Confirma a correcao?"

    If !MsgYesNo(cMsg, "Confirmar - " + cCodItem)
        Return
    EndIf

    // Aplica a correção
    U_CorrigeSD3(aMovtos, nCustoCor, cCodItem)

Return


//-------------------------------------------
// Varre SD3 sem MsSeek — filtra por código
// e data, independente de filial ou índice
//-------------------------------------------
User Function VarreSD3(cCodItem, dDtIni, dDtFim)

    Local aRet  := {}
    Local aArea := SD3->(GetArea())

    DbSelectArea("SD3")
    DbGoTop()  // Vai para o início — sem seek, sem índice

    While !SD3->(EoF())

        If AllTrim(SD3->D3_COD)  == AllTrim(cCodItem) .And. ;
           SD3->D3_DATA           >= dDtIni            .And. ;
           SD3->D3_DATA           <= dDtFim            .And. ;
           !SD3->(IsDeleted())

            aAdd(aRet, { ;
                SD3->(RecNo()),       ;  // [1] RecNo
                SD3->D3_FILIAL,       ;  // [2] Filial
                DtoC(SD3->D3_DATA),   ;  // [3] Data
                AllTrim(SD3->D3_TM),  ;  // [4] TM
                AllTrim(SD3->D3_DOC), ;  // [5] Documento
                SD3->D3_QUANT,        ;  // [6] Quantidade
                SD3->D3_CUSTO1        ;  // [7] CT atual
            })

        EndIf

        SD3->(DbSkip())
    EndDo

    RestArea(aArea)

Return aRet


//-------------------------------------------
// Aplica RecLock e corrige D3_CUSTO1
//-------------------------------------------
User Function CorrigeSD3(aMovtos, nCustoCor, cCodItem)

    Local nI    := 0
    Local lOk   := .T.
    Local nErro := 0

    For nI := 1 To Len(aMovtos)

        DbSelectArea("SD3")
        DbGoTo(aMovtos[nI][1])  // Posiciona pelo RecNo

        Begin Sequence

            If !RecLock("SD3", .F.)
                nErro++
                U_GravaCorcLog("ERRO RecLock | RecNo:" + cValToChar(aMovtos[nI][1]) + ;
                               " | " + aMovtos[nI][3])
                DisarmTransaction()
                Break
            EndIf

            // Grava log antes/depois
            U_GravaCorcLog("OK | " + cCodItem + ;
                           " | " + aMovtos[nI][3] + ;
                           " | TM:" + aMovtos[nI][4] + ;
                           " | Qtd:" + cValToChar(aMovtos[nI][6]) + ;
                           " | CTant:" + cValToChar(aMovtos[nI][7]) + ;
                           " | CTnovo:" + cValToChar(aMovtos[nI][6] * nCustoCor))

            SD3->D3_CUSTO1 := aMovtos[nI][6] * nCustoCor  // Aplica novo custo

            SD3->(MsUnlock())

        End Sequence

    Next nI

    If nErro > 0
        MsgStop(cValToChar(nErro) + " registro(s) nao puderam ser alterados." + CRLF + ;
                "Veja: \TOTVS\CORCITEM_LOG.TXT", "Atencao")
    Else
        MsgInfo("Concluido! " + cValToChar(Len(aMovtos)) + " registro(s) corrigidos." + CRLF + ;
                "Log: \TOTVS\CORCITEM_LOG.TXT", "Sucesso")
    EndIf

Return


//-------------------------------------------
// Log
//-------------------------------------------
User Function GravaCorcLog(cMensagem)

    Local cArqLog := "\TOTVS\CORCITEM_LOG.TXT"
    Local nHandle
    Local cLinha  := DtoC(Date()) + " " + Time() + " | " + cMensagem + CRLF

    If File(cArqLog)
        nHandle := FOpen(cArqLog, 1)
        FSeek(nHandle, 0, 2)
    Else
        nHandle := FCreate(cArqLog)
    EndIf

    If nHandle >= 0
        FWrite(nHandle, cLinha)
        FClose(nHandle)
    EndIf

Return
