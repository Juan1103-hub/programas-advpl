#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} MTALCFIM
    Captura numero do PC e data de aprovacao do PARAMIXB e armazena
    em Public para o PE MT097APR processar o recalculo.
    Dispara a CADA aprovacao individual (MATXALC).
    O recalculo efetivo do C7_DATPRF ocorre no MT097APR, que executa
    APOS a atualizacao do C7_CONAPRO para 'L' (liberacao completa).
    @param   PARAMIXB, array, parametros do MATXALC:
             [1]=aDocto {cNumDoc,cTipoDoc,nValor,cAprov,cUser,cGrupo,...}
             [2]=dDataRef, [3]=nOper (4=aprovacao)
    @return  lRet, logical, .T. = permite liberacao
    @since   17/06/2026
/*/
User Function MTALCFIM()
    Local aArea     := GetArea()
    Local lRet      := .T.
    Local aDocto    := {}
    Local nOper     := 0
    Local cNumPed   := ""
    Local cTipoDoc  := ""
    Local dDtAprov  := dDataBase

    If Type("PARAMIXB") != "A" .Or. Len(PARAMIXB) < 3
        RestArea(aArea)
        Return .T.
    EndIf

    aDocto := PARAMIXB[1]
    nOper  := PARAMIXB[3]

    If nOper != 4
        RestArea(aArea)
        Return .T.
    EndIf

    If ValType(aDocto) == "A" .And. Len(aDocto) >= 2
        cNumPed  := AllTrim(aDocto[1])
        cTipoDoc := AllTrim(aDocto[2])
    EndIf

    If Empty(cNumPed) .Or. Empty(cTipoDoc)
        ConOut("[MTALCFIM] ERRO: numero ou tipo do documento nao identificado no PARAMIXB")
        RestArea(aArea)
        Return .T.
    EndIf

    ConOut("[MTALCFIM] Documento " + cNumPed + " | Tipo " + cTipoDoc + " | Oper " + cValToChar(nOper))
    ConOut("[MTALCFIM] DEBUG PARAMIXB[2]=" + cTipoDoc + " | Len=" + cValToChar(Len(aDocto)))

    // --- Busca data de aprovacao na SCR ---
    DbSelectArea("SCR")
    SCR->(DbSetOrder(1))
    If SCR->(DbSeek(xFilial("SCR") + cNumPed))
        While SCR->(!Eof()) .And. SCR->CR_FILIAL == xFilial("SCR") .And. SCR->CR_NUM == cNumPed
            If (SCR->CR_TIPO == cTipoDoc .Or. (cTipoDoc == "PC" .And. SCR->CR_TIPO == "IP")) .And. SCR->CR_STATUS == "03"
                If !Empty(SCR->CR_DATALIB)
                    dDtAprov := SCR->CR_DATALIB
                    Exit
                EndIf
            EndIf
            SCR->(DbSkip())
        EndDo
    EndIf

    If Empty(dDtAprov)
        dDtAprov := Date()
        ConOut("[MTALCFIM] Fallback Date(): " + DtoC(dDtAprov))
    EndIf

    ConOut("[MTALCFIM] Data aprov: " + DtoC(dDtAprov))

    // --- Armazena dados para o MT097APR via Public (entre funcoes do .PRW) ---
    // MT097APR executa APOS a liberacao completa (C7_CONAPRO = 'L')
    // e precisa saber qual PC foi aprovado
    If cTipoDoc == "PC" .Or. cTipoDoc == "IP"
        Public _zPCPara  := cNumPed
        Public _zDtAprov := dDtAprov
        ConOut("[MTALCFIM] Dados armazenados para MT097APR: PC=" + cNumPed + " Data=" + DtoC(dDtAprov))
    EndIf

    RestArea(aArea)
Return lRet

/*/{Protheus.doc} MT097APR
    Recalcula C7_DATPRF dos itens do pedido APOS a aprovacao FINAL.
    Executado APOS o campo C7_CONAPRO ser atualizado para 'L' (liberado),
    na funcao A097LIBERA do MATA097.PRW.
    Nao recebe PARAMIXB - le os dados armazenados pelo MTALCFIM via Public.
    @return  Nil (sem retorno)
    @since   17/06/2026
/*/
User Function MT097APR()
    Local aArea     := GetArea()
    Local cNumPed   := ""
    Local dDtAprov  := CtoD("")
    Local dDtEmis   := CtoD("")
    Local dDtPrf    := CtoD("")
    Local nDias     := 0
    Local dNovaPrf  := CtoD("")
    Local cAliasQ   := GetNextAlias()

    // --- Log de entrada (diagnostico) ---
    ConOut("[MT097APR] === INICIO ===")
    If Type("_zPCPara") == "C"
        ConOut("[MT097APR] _zPCPara  = " + _zPCPara)
    Else
        ConOut("[MT097APR] _zPCPara  = <indefinida>")
    EndIf
    If Type("_zDtAprov") == "D"
        ConOut("[MT097APR] _zDtAprov = " + DtoC(_zDtAprov))
    Else
        ConOut("[MT097APR] _zDtAprov = <indefinida>")
    EndIf

    // --- Le os dados armazenados pelo MTALCFIM via Public ---
    cNumPed  := _zPCPara
    dDtAprov := _zDtAprov

    // --- Fallback: se Public estiver vazia, busca na SCR ---
    If Empty(cNumPed)
        ConOut("[MT097APR] Public vazia, buscando ultimo PC aprovado na SCR")
        BeginSql Alias cAliasQ
            SELECT CR_NUM, CR_DATALIB
            FROM %Table:SCR%
            WHERE %NotDel%
              AND CR_FILIAL  = %xFilial:SCR%
              AND CR_TIPO    IN ('PC','IP')
              AND CR_STATUS  = '03'
              AND CR_DATALIB <= %exp:dDataBase%
            ORDER BY CR_DATALIB DESC
        EndSql

        If (cAliasQ)->(!Eof())
            cNumPed  := AllTrim((cAliasQ)->CR_NUM)
            dDtAprov := (cAliasQ)->CR_DATALIB
            ConOut("[MT097APR] Fallback: PC=" + cNumPed + " Data=" + DtoC(dDtAprov))
        Else
            ConOut("[MT097APR] Nenhum PC encontrado na SCR")
        EndIf
        (cAliasQ)->(DbCloseArea())
    EndIf

    If Empty(cNumPed) .Or. Empty(dDtAprov)
        ConOut("[MT097APR] ERRO: nao foi possivel identificar o PC aprovado")
        RestArea(aArea)
        Return
    EndIf

    ConOut("[MT097APR] OK - PC=" + cNumPed + " DtAprov=" + DtoC(dDtAprov))

    ConOut("[MT097APR] Recalculando C7_DATPRF do PC " + cNumPed)

    // --- Recalcula C7_DATPRF nos itens do pedido ---
DbSelectArea("SC7")
SC7->(DbSetOrder(1))
If !SC7->(DbSeek(xFilial("SC7") + cNumPed))
    ConOut("[MT097APR] AVISO: pedido " + cNumPed + " sem itens na SC7")
    RestArea(aArea)
    Return
EndIf
// Verifica se a liberação está completa (C7_CONAPRO = 'L')
If SC7->C7_CONAPRO != 'L'
    ConOut("[MT097APR] AVISO: C7_CONAPRO != 'L' (" + SC7->C7_CONAPRO + ") - pulando recalculo")
    RestArea(aArea)
    Return
EndIf

    While SC7->(!Eof()) .And. SC7->C7_FILIAL == xFilial("SC7") .And. SC7->C7_NUM == cNumPed
        dDtEmis := SC7->C7_EMISSAO
        dDtPrf  := SC7->C7_DATPRF

        If !Empty(dDtEmis) .And. !Empty(dDtPrf) .And. dDtAprov > dDtEmis
            nDias    := dDtAprov - dDtEmis
            dNovaPrf := dDtPrf + nDias

            RecLock("SC7", .F.)
            SC7->C7_DATPRF := dNovaPrf
            SC7->(MsUnlock())

            ConOut("[MT097APR] PC " + cNumPed + " Item " + SC7->C7_ITEM + ;
                   " DATPRF " + DtoC(dDtPrf) + " -> " + DtoC(dNovaPrf) + ;
                   " (+" + cValToChar(nDias) + " dias)")
        Else
            ConOut("[MT097APR] PC " + cNumPed + " Item " + SC7->C7_ITEM + ;
                   " sem alteracao (Emis: " + DtoC(dDtEmis) + ;
                   " | Prf: " + DtoC(dDtPrf) + " | Aprov: " + DtoC(dDtAprov) + ")")
        EndIf

        SC7->(DbSkip())
    EndDo

    ConOut("[MT097APR] === FIM (PC " + cNumPed + " itens processados) ===")
    RestArea(aArea)
Return

/*/{Protheus.doc} DIAGC7
    Diagnostico para verificar o estado real do pedido e aprovadores
    no momento em que a MATA094 processa a liberacao.
    Execute U_DIAGC7() durante uma aprovacao intermediaria e na final.
    @since   17/06/2026
/*/
User Function DIAGC7()
    Local aArea   := GetArea()
    Local aDocto  := {}
    Local cNumPed := ""
    Local cTipo   := ""
    Local cAliasQ := GetNextAlias()

    If Type("PARAMIXB") != "A" .Or. Len(PARAMIXB) < 1
        ConOut("[DIAGC7] PARAMIXB invalido ou ausente")
        RestArea(aArea)
        Return
    EndIf

    aDocto := PARAMIXB[1]
    If ValType(aDocto) == "A" .And. Len(aDocto) >= 2
        cNumPed := AllTrim(aDocto[1])
        cTipo   := AllTrim(aDocto[2])
    EndIf

    If Empty(cNumPed)
        ConOut("[DIAGC7] Numero do documento nao identificado")
        RestArea(aArea)
        Return
    EndIf

    ConOut("")
    ConOut("========== DIAGC7 ==========")
    ConOut("Documento: " + cNumPed + " | Tipo: " + cTipo)

    DbSelectArea("SC7")
    SC7->(DbSetOrder(1))
    If SC7->(DbSeek(xFilial("SC7") + cNumPed))
        ConOut("SC7->C7_CONAPRO = " + SC7->C7_CONAPRO)
        ConOut("SC7->C7_EMISSAO  = " + DtoC(SC7->C7_EMISSAO))
        ConOut("SC7->C7_DATPRF   = " + DtoC(SC7->C7_DATPRF))
    Else
        ConOut("SC7: pedido nao encontrado")
    EndIf

    BeginSql Alias cAliasQ
        SELECT CR_APROV, CR_STATUS, CR_DATALIB, CR_TIPO
        FROM %Table:SCR%
        WHERE %NotDel%
          AND CR_FILIAL = %xFilial:SCR%
          AND CR_NUM    = %exp:cNumPed%
    EndSql

    ConOut("--- SCR ---")
    While (cAliasQ)->(!Eof())
        ConOut("  Aprov: " + (cAliasQ)->CR_APROV + ;
               " | Status: " + (cAliasQ)->CR_STATUS + ;
               " | DataLib: " + DtoC((cAliasQ)->CR_DATALIB) + ;
               " | Tipo: " + AllTrim((cAliasQ)->CR_TIPO))
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    ConOut("=============================")
    ConOut("")

    RestArea(aArea)
Return
