#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} ZZ4PEND
    Abre browse de selecao filtrado apenas para Solicitacoes Pendentes
    (ZZ4_STATUS = '0'), usado pelo FWLookup (SXB Tipo 1 = PROG) no campo
    A2_ZSOLID do MATA020.
    Fornecedores ja cadastrados (STATUS='1') nao aparecem na consulta,
    evitando re-selecao.
    Antes de exibir, sincroniza o status com a SA2 para garantir que
    fornecedores ja registrados nao aparecam como pendentes.
    @type User Function
    @version 12.1.33
    @author  Suprimentos
    @since   12/06/2026
    @return  Character, ZZ4_ID selecionado via FWLookupRet
/*/
User Function ZZ4PEND()

    Local aArea     := GetArea()
    Local oFWBrowse := Nil
    Local cAls      := ""
    Local cQuery    := ""
    Local nRec      := 0

    DbSelectArea("ZZ4")
    ZZ4->(DbSetOrder(1))

    cAls   := GetNextAlias()
    cQuery := "SELECT Z.ZZ4_ID FROM " + RetSqlName("ZZ4") + " Z "
    cQuery += " WHERE Z.D_E_L_E_T_ = ' ' "
    cQuery += "   AND Z.ZZ4_STATUS = '0' "
    cQuery += "   AND EXISTS (SELECT 1 FROM " + RetSqlName("SA2") + " S "
    cQuery += "               WHERE S.D_E_L_E_T_ = ' ' "
    cQuery += "               AND REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(S.A2_CGC)),'.',''),'/',''),'-','') = "
    cQuery += "                   REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(Z.ZZ4_CNPJ)),'.',''),'/',''),'-','')) "
    cQuery := ChangeQuery(cQuery)

    If Select(cAls) > 0
        (cAls)->(DbCloseArea())
    EndIf
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAls, .F., .T.)

    While !(cAls)->(Eof())
        DbSelectArea("ZZ4")
        ZZ4->(DbSetOrder(1))
        If ZZ4->(DbSeek(xFilial("ZZ4") + PadR(AllTrim((cAls)->ZZ4_ID), TamSX3("ZZ4_ID")[1])))
            If RecLock("ZZ4", .F.)
                Replace ZZ4_STATUS With '1'
                If Empty(ZZ4->ZZ4_DTREJ)
                    Replace ZZ4_DTREJ With dDataBase
                EndIf
                MsUnlock()
            EndIf
        EndIf
        (cAls)->(DbSkip())
    EndDo
    (cAls)->(DbCloseArea())

    DbSelectArea("ZZ4")
    ZZ4->(DbSetOrder(1))
    ZZ4->(DbSetFilter({|| ZZ4->ZZ4_STATUS == '0'}, "ZZ4_STATUS='0'"))
    ZZ4->(DbGoTop())

    oFWBrowse := FWBrowse():New(00, 00, dSayCP(22), dSayCP(80))
    oFWBrowse:SetAlias("ZZ4")
    oFWBrowse:AddColumn("ID", "ZZ4_ID", , dSayCP(08))
    oFWBrowse:AddColumn("Razao Social", "ZZ4_RAZAO", , dSayCP(30))
    oFWBrowse:AddColumn("CNPJ", "ZZ4_CNPJ", , dSayCP(14))
    oFWBrowse:AddColumn("Status", "ZZ4_STATUS", , dSayCP(10))
    oFWBrowse:AddButton("OK", {|| nRec := RecNo(), FWBrowse():EndDialog(.T.)})
    oFWBrowse:AddButton("Cancelar", {|| nRec := 0, FWBrowse():EndDialog(.F.)})

    oFWBrowse:Show()

    If nRec > 0
        ZZ4->(DbGoTo(nRec))
        FWLookupRet(ZZ4->ZZ4_ID)
    EndIf

    ZZ4->(DbClearFilter())
    RestArea(aArea)

Return
