#Include "Protheus.ch"
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} M020EXC
Ponto de Entrada executado durante a exclusao do fornecedor no
MATA020 (Cadastro de Fornecedores / SA2).

Quando um fornecedor e excluido, reverte o ZZ4 correspondente
(que tinha STATUS='1') de volta para Pendente ('0'), limpando
a data ZZ4_DTREJ. Isto permite que a solicitacao seja
recadastrada sem o alerta "JA FOI CADASTRADA".

Sempre retorna .T. � nao bloqueia a exclusao.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   25/04/2026
/*/
//-------------------------------------------------------------------
User Function M020EXC()

    Local aArea   := GetArea()
    Local cCnpj   := ""
    Local cTabZZ4 := ""
    Local cFil    := ""
    Local cSql    := ""
    Local cAls    := ""

    DbSelectArea("SA2")
    cCnpj := AllTrim(SA2->A2_CGC)

    ConOut("[M020EXC] Excluindo fornecedor CNPJ=[" + cCnpj + "]")

    If Empty(cCnpj)
        RestArea(aArea)
        Return .T.
    EndIf

    cTabZZ4 := RetSqlName("ZZ4")

    If Empty(cTabZZ4)
        RestArea(aArea)
        Return .T.
    EndIf

    cFil := xFilial("ZZ4")

    // Passo unico: SELECT dos ZZ4 com STATUS='1' + RecLock para reverter a Pendente
    cAls   := GetNextAlias()
    cSql := "SELECT Z.ZZ4_ID FROM " + RetSqlName("ZZ4") + " Z "
    cSql += " WHERE Z.D_E_L_E_T_ = ' ' "
    cSql += "   AND Z.ZZ4_STATUS = '1' "
    cSql += "   AND REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(Z.ZZ4_CNPJ)),'.',''),'/',''),'-','') = '" + cCnpj + "' "
    cSql := ChangeQuery(cSql)

    If Select(cAls) > 0
        (cAls)->(DbCloseArea())
    EndIf
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cSql), cAls, .F., .T.)

    While !(cAls)->(Eof())
        DbSelectArea("ZZ4")
        ZZ4->(DbSetOrder(1))
        If ZZ4->(DbSeek(xFilial("ZZ4") + PadR(AllTrim((cAls)->ZZ4_ID), TamSX3("ZZ4_ID")[1])))
            If Reclock("ZZ4", .F.)
                Replace ZZ4_STATUS With '0'
                Replace ZZ4_DTREJ  With CtoD("  /  /  ")
                MsUnlock()
                ZZ4->(DbCommit())
            EndIf
        EndIf
        (cAls)->(DbSkip())
    EndDo
    (cAls)->(DbCloseArea())

    ConOut("[M020EXC] ZZ4 revertido para Pendente.")

    RestArea(aArea)

Return .T.
