#Include "Protheus.ch"
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} MT20FOPOS
Ponto de Entrada executado apos a gravacao no MATA020
(Cadastro de Fornecedores / SA2). Disparado tanto na inclusao
quanto na alteracao do fornecedor.

Ao gravar um fornecedor, verifica se existe alguma solicitacao
cadastral (ZZ4) com o mesmo CNPJ ainda pendente (ZZ4_STATUS = '0')
e a marca automaticamente como Cadastrada ('1'), gravando a data
da confirmacao em ZZ4_DTREJ.

Elimina a necessidade de clicar em "Atualizar" no CADFORN.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   25/04/2026
/*/
//-------------------------------------------------------------------
User Function MT20FOPOS()

    Local aArea   := GetArea()
    Local cCnpj   := ""
    Local cTabZZ4 := ""
    Local cSql    := ""
    Local cCod    := ""
    Local cLoja   := ""
    Local cAlsZ4  := ""
    Local nRecZ4  := 0

    DbSelectArea("SA2")
    cCnpj := AllTrim(SA2->A2_CGC)
    cCod  := AllTrim(SA2->A2_COD)
    cLoja := AllTrim(SA2->A2_LOJA)

    // Fallback: tenta variavel de memoria do MATA020
    If Empty(cCnpj) .And. Type("M->A2_CGC") == "C"
        cCnpj := AllTrim(M->A2_CGC)
    EndIf

    cCnpj := StrTran(StrTran(StrTran(cCnpj,".",""),"/",""),"-","")

    ConOut("[MT20FOPOS] >>> Disparado <<< CNPJ=[" + cCnpj + ;
           "] COD=[" + cCod + "] LOJA=[" + cLoja + "] xFilSA2=[" + xFilial("SA2") + ;
           "] xFilZZ4=[" + xFilial("ZZ4") + "]")

    If Empty(cCnpj)
        ConOut("[MT20FOPOS] CNPJ vazio - abortando.")
        RestArea(aArea)
        Return
    EndIf

    cTabZZ4 := RetSqlName("ZZ4")
    If Empty(cTabZZ4)
        ConOut("[MT20FOPOS] RetSqlName(ZZ4) vazio - abortando.")
        RestArea(aArea)
        Return
    EndIf

    // Passo 1: Atualiza STATUS='1' via SQL (sem data — data vem via Replace abaixo).
    // Compara o CNPJ removendo qualquer formatacao gravada na ZZ4.
    cSql := "UPDATE " + cTabZZ4 + " SET ZZ4_STATUS = '1' " + ;
            "WHERE D_E_L_E_T_ = ' ' " + ;
            "AND ZZ4_STATUS = '0' " + ;
            "AND REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ZZ4_CNPJ)),'.',''),'/',''),'-','') = '" + cCnpj + "'"

    ConOut("[MT20FOPOS] SQL: " + cSql)
    TCSQLExec(cSql)
    ConOut("[MT20FOPOS] UPDATE STATUS executado. Erro=[" + TCSQLError() + "]")

    // Preenche ZZ4_DTREJ apenas nos registros do CNPJ salvo.
    If Select("ZZ4") <= 0
        ChkFile("ZZ4")
    EndIf

    If Select("ZZ4") <= 0
        ConOut("[MT20FOPOS] Alias ZZ4 nao abriu para gravar data.")
        RestArea(aArea)
        Return
    EndIf

    cAlsZ4 := GetNextAlias()
    cSql := " SELECT R_E_C_N_O_ AS RECNOZZ4 FROM " + cTabZZ4 + " "
    cSql += " WHERE D_E_L_E_T_ = ' ' "
    cSql += "   AND ZZ4_STATUS = '1' "
    cSql += "   AND REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ZZ4_CNPJ)),'.',''),'/',''),'-','') = '" + cCnpj + "' "
    cSql := ChangeQuery(cSql)

    If Select(cAlsZ4) > 0
        (cAlsZ4)->(DbCloseArea())
    EndIf
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cSql), cAlsZ4, .F., .T.)

    While !(cAlsZ4)->(Eof())
        nRecZ4 := (cAlsZ4)->RECNOZZ4
        DbSelectArea("ZZ4")
        ZZ4->(DbGoTo(nRecZ4))
        If !ZZ4->(Eof()) .And. Empty(ZZ4->ZZ4_DTREJ)
            If Reclock("ZZ4", .F.)
                Replace ZZ4_DTREJ With dDataBase
                MsUnlock()
                ZZ4->(DbCommit())
                ConOut("[MT20FOPOS] ZZ4_DTREJ gravado via Replace: " + DtoC(dDataBase))
            EndIf
        EndIf
        (cAlsZ4)->(DbSkip())
    EndDo

    (cAlsZ4)->(DbCloseArea())

    RestArea(aArea)

Return
