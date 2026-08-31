#Include "Protheus.ch"
#Include "TopConn.ch"

#Define CRLF Chr(13) + Chr(10)

//-------------------------------------------------------------------
/*/{Protheus.doc} FFZZ4A2
Funcao Valid do campo A2_ZZ4ID na SA2 (MATA020).

Ao sair do campo Cod ZZ4 no cadastro de fornecedor, busca o
registro correspondente na tabela ZZ4 e preenche automaticamente
os campos do SA2:

  A2_NOME    <- ZZ4_RAZAO  (Razao Social)
  A2_NREDUZ  <- ZZ4_RAZAO  (primeiros chars conforme tamanho SA2)
  A2_CGC     <- ZZ4_CNPJ   (CNPJ)
  A2_TEL     <- ZZ4_NUMERO (Telefone - truncado ao tamanho SA2)
  A2_EMAIL   <- ZZ4_EMAIL  (se campo existir)
  A2_INSEST  <- ZZ4_INSEST (Inscricao Estadual - se campo existir)

Bloqueios:
  - ZZ4 nao encontrada: erro, retorna .F.
  - ZZ4_STATUS = '2' (Rejeitada): bloqueia, retorna .F.
  - ZZ4_STATUS = '1' (ja Cadastrada): avisa, pergunta se continua

@type User Function
@version 12.1.33
@author  Suprimentos
@since   2026
/*/
//-------------------------------------------------------------------
User Function FFZZ4A2()

    Local aArea    := GetArea()
    Local aAreaZZ4 := {}
    Local cId      := AllTrim(IIF(SA2->(FieldPos("A2_ZSOLID")) > 0 .And. !Empty(M->A2_ZSOLID), M->A2_ZSOLID, M->A2_ZZ4ID))
    Local lRet     := .T.
    Local cMsg     := ""
    Local cFone    := ""
    Local nIni     := 0
    Local nFim     := 0
    Local cDDD     := ""
    Local cNumTel  := ""
    Local cSimp    := ""
    Local cAlsChk  := ""
    Local cQryChk  := ""
    Local cMsgBlk  := ""

    // Campo opcional � se vazio, libera sem validar
    If Empty(cId)
        RestArea(aArea)
        Return .T.
    EndIf

    // Garante que ZZ4 esta aberta
    If Select("ZZ4") <= 0
        ChkFile("ZZ4")
    EndIf

    If Select("ZZ4") <= 0
        MsgStop("Tabela ZZ4 nao pode ser acessada." + CRLF + ;
                "Execute U_CADFORN para verificar o dicionario.", "Erro ZZ4")
        RestArea(aArea)
        Return .F.
    EndIf

    aAreaZZ4 := ZZ4->(GetArea())

    DbSelectArea("ZZ4")
    ZZ4->(DbSetOrder(1))  // ZZ4_FILIAL + ZZ4_ID

    // Busca pelo ID informado
    If !ZZ4->(DbSeek(xFilial("ZZ4") + PadR(cId, TamSX3("ZZ4_ID")[1])))
        MsgStop("Solicitacao ZZ4 nao encontrada: [" + cId + "]" + CRLF + CRLF + ;
                "Verifique o codigo no Browse de Solicitacoes (U_CADFORN).", ;
                "ZZ4 Nao Encontrada")
        RestArea(aAreaZZ4)
        RestArea(aArea)
        Return .F.
    EndIf

    // Bloqueia se Rejeitada
    If AllTrim(ZZ4->ZZ4_STATUS) == "2"
        MsgStop("A solicitacao [" + cId + "] foi REJEITADA." + CRLF + CRLF + ;
                "Fornecedor: " + AllTrim(ZZ4->ZZ4_RAZAO) + CRLF + ;
                "Nao e possivel cadastrar a partir de uma solicitacao rejeitada.", ;
                "Solicitacao Rejeitada")
        RestArea(aAreaZZ4)
        RestArea(aArea)
        Return .F.
    EndIf

    // Avisa se ja foi Cadastrada (permite continuar) � mas valida primeiro
    // contra a SA2: se o CNPJ nao existe mais (fornecedor foi excluido),
    // auto-reverte o ZZ4 para '0' e libera sem perguntar.
    If AllTrim(ZZ4->ZZ4_STATUS) == "1"

        cAlsChk := GetNextAlias()
        cQryChk := " SELECT COUNT(*) AS QTD FROM " + RetSqlName("SA2") + " "
        cQryChk += " WHERE D_E_L_E_T_ = ' ' "
        cQryChk += "   AND A2_FILIAL = '" + xFilial("SA2") + "' "
        cQryChk += "   AND A2_CGC = REPLACE(REPLACE(REPLACE('" + AllTrim(ZZ4->ZZ4_CNPJ) + "','.',''),'/',''),'-','') "
        cQryChk := ChangeQuery(cQryChk)

        If Select(cAlsChk) > 0
            (cAlsChk)->(DbCloseArea())
        EndIf
        DbUseArea(.T., "TOPCONN", TCGenQry(,,cQryChk), cAlsChk, .F., .T.)

        If (cAlsChk)->QTD == 0
            // Fornecedor nao existe mais na SA2: reverte ZZ4 para Pendente
            (cAlsChk)->(DbCloseArea())
            DbSelectArea("ZZ4")
            If Reclock("ZZ4", .F.)
                Replace ZZ4_STATUS With '0'
                Replace ZZ4_DTREJ  With CtoD("  /  /  ")
                MsUnlock()
                ZZ4->(DbCommit())
            EndIf
        Else
            (cAlsChk)->(DbCloseArea())
            cMsg := "A solicitacao [" + cId + "] JA FOI CADASTRADA." + CRLF + CRLF + ;
                    "Fornecedor: " + AllTrim(ZZ4->ZZ4_RAZAO) + CRLF + CRLF + ;
                    "Deseja preencher os campos novamente?"
            If !MsgYesNo(cMsg, "Solicitacao Ja Cadastrada")
                RestArea(aAreaZZ4)
                RestArea(aArea)
                Return .F.
            EndIf
        EndIf
    EndIf

    // Bloqueia se o ID ZZ4 ja foi usado em outro fornecedor da SA2
    // (suporta A2_ZSOLID ou A2_ZZ4ID)
    cAlsChk := GetNextAlias()
    cQryChk := " SELECT A2_COD, A2_LOJA, A2_NOME FROM " + RetSqlName("SA2") + " "
    cQryChk += " WHERE D_E_L_E_T_ = ' ' "
    cQryChk += "   AND A2_FILIAL = '" + xFilial("SA2") + "' "
    Do Case
        Case SA2->(FieldPos("A2_ZSOLID")) > 0
            cQryChk += "   AND RTRIM(A2_ZSOLID) = '" + cId + "' "
        Case SA2->(FieldPos("A2_ZZ4ID")) > 0
            cQryChk += "   AND RTRIM(A2_ZZ4ID) = '" + cId + "' "
        Otherwise
            cQryChk := ""
    EndCase
    If !Empty(cQryChk)
        cQryChk += "   AND NOT (RTRIM(A2_COD) = '" + AllTrim(M->A2_COD) + "' "
        cQryChk += "       AND RTRIM(A2_LOJA) = '" + AllTrim(M->A2_LOJA) + "') "
        cQryChk := ChangeQuery(cQryChk)
        If Select(cAlsChk) > 0
            (cAlsChk)->(DbCloseArea())
        EndIf
        DbUseArea(.T., "TOPCONN", TCGenQry(,,cQryChk), cAlsChk, .F., .T.)
        If !(cAlsChk)->(Eof())
            cMsgBlk := "A solicitacao [" + cId + "] ja foi utilizada no fornecedor:" + CRLF + ;
                             "Codigo: " + AllTrim((cAlsChk)->A2_COD) + ;
                             "  Loja: " + AllTrim((cAlsChk)->A2_LOJA) + CRLF + ;
                             "Nome: "  + AllTrim((cAlsChk)->A2_NOME) + CRLF + CRLF + ;
                             "Cada solicitacao so pode ser vinculada a um fornecedor."
            (cAlsChk)->(DbCloseArea())
            RestArea(aAreaZZ4)
            RestArea(aArea)
            MsgStop(cMsgBlk, "Solicitacao ja utilizada")
            Return .F.
        EndIf
        (cAlsChk)->(DbCloseArea())
    EndIf

    // === PREENCHE CAMPOS DO SA2 ===

    // Razao Social (obrigatorio)
    M->A2_NOME   := PadR(UPPER(AllTrim(ZZ4->ZZ4_RAZAO)), TamSX3("A2_NOME")[1])

    // Nome Reduzido (primeiros N chars da Razao)
    M->A2_NREDUZ := PadR(UPPER(SubStr(AllTrim(ZZ4->ZZ4_RAZAO), 1, TamSX3("A2_NREDUZ")[1])), ;
                         TamSX3("A2_NREDUZ")[1])

    // CNPJ — limpa formatacao e grava apenas os 14 digitos (padrao A2_CGC)
    M->A2_CGC    := PadR(StrTran(StrTran(StrTran(AllTrim(ZZ4->ZZ4_CNPJ),".",""),"/",""),"-",""), ;
                        TamSX3("A2_CGC")[1])

    // Telefone e DDD - suporta "(31) 3193-3015"
    cFone := AllTrim(ZZ4->ZZ4_NUMERO)
    nIni  := At("(", cFone)
    nFim  := At(")", cFone)
    cDDD  := ""
    If nIni > 0 .And. nFim > nIni
        // Formato (31) 3193-3015
        cDDD    := AllTrim(SubStr(cFone, nIni + 1, nFim - nIni - 1))
        cNumTel := AllTrim(SubStr(cFone, nFim + 2))
    ElseIf Len(cFone) >= 2 .And. IsDigit(SubStr(cFone,1,1)) .And. IsDigit(SubStr(cFone,2,1))
        // Formato sem parenteses: 31 3193-3015 ou so digitos
        cDDD    := SubStr(cFone, 1, 2)
        cNumTel := AllTrim(SubStr(cFone, 3))
    Else
        cNumTel := cFone
    EndIf
    M->A2_TEL := PadR(cNumTel, TamSX3("A2_TEL")[1])
    If SA2->(FieldPos("A2_DDD")) > 0
        M->A2_DDD := PadR(cDDD, TamSX3("A2_DDD")[1])
    EndIf

    // E-mail
    If SA2->(FieldPos("A2_EMAIL")) > 0
        M->A2_EMAIL  := PadR(AllTrim(ZZ4->ZZ4_EMAIL), TamSX3("A2_EMAIL")[1])
    EndIf

    // Inscricao Estadual
    If SA2->(FieldPos("A2_INSCR")) > 0
        M->A2_INSCR  := PadR(AllTrim(ZZ4->ZZ4_INSEST), TamSX3("A2_INSCR")[1])
    EndIf
    If SA2->(FieldPos("A2_INSEST")) > 0
        M->A2_INSEST := PadR(AllTrim(ZZ4->ZZ4_INSEST), TamSX3("A2_INSEST")[1])
    EndIf

    // Inscricao Municipal
    If ZZ4->(FieldPos("ZZ4_INSMUN")) > 0
        If SA2->(FieldPos("A2_INSCRM")) > 0
            M->A2_INSCRM  := PadR(AllTrim(ZZ4->ZZ4_INSMUN), TamSX3("A2_INSCRM")[1])
        EndIf
        If SA2->(FieldPos("A2_INSPROD")) > 0
            M->A2_INSPROD := PadR(AllTrim(ZZ4->ZZ4_INSMUN), TamSX3("A2_INSPROD")[1])
        EndIf
    EndIf

    // Contato / Vendedor
    If ZZ4->(FieldPos("ZZ4_CONTAT")) > 0
        If SA2->(FieldPos("A2_CONTATO")) > 0
            M->A2_CONTATO := PadR(UPPER(AllTrim(ZZ4->ZZ4_CONTAT)), TamSX3("A2_CONTATO")[1])
        EndIf
        If SA2->(FieldPos("A2_CONTFIN")) > 0
            M->A2_CONTFIN := PadR(UPPER(AllTrim(ZZ4->ZZ4_CONTAT)), TamSX3("A2_CONTFIN")[1])
        EndIf
    EndIf

    // Simples Nacional: ZZ4 guarda "S"/"N", A2_SIMPNAC espera "1"(Sim) ou "2"(Nao)
    If ZZ4->(FieldPos("ZZ4_SIMPLE")) > 0
        cSimp := AllTrim(ZZ4->ZZ4_SIMPLE)
        If SA2->(FieldPos("A2_SIMPNAC")) > 0
            M->A2_SIMPNAC := PadR(IIf(cSimp == "S", "1", "2"), TamSX3("A2_SIMPNAC")[1])
        EndIf
        If SA2->(FieldPos("A2_SIMPLES")) > 0
            M->A2_SIMPLES := PadR(cSimp, TamSX3("A2_SIMPLES")[1])
        EndIf
        If SA2->(FieldPos("A2_OPTSIMP")) > 0
            M->A2_OPTSIMP := PadR(cSimp, TamSX3("A2_OPTSIMP")[1])
        EndIf
    EndIf

    RestArea(aAreaZZ4)
    RestArea(aArea)

Return lRet
