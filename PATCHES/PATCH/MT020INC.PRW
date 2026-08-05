#Include "Protheus.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} MT020INC
Ponto de entrada — atualiza ZZ4_STATUS apos incluir fornecedor.
Acionado apos salvar (incluir) no MATA020 (Cadastro de Fornecedores).

Quando um fornecedor e cadastrado com vinculo a uma solicitacao ZZ4
(campo A2_ZSOLID ou A2_ZZ4ID), este PE busca o registro na ZZ4
e marca STATUS='1' (Cadastrado) e ZZ4_DTREJ com a data atual.

Isso faz com que a bolinha da solicitacao fique VERMELHA no browse
CADFORN.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   12/06/2026
@param   aParam, Array, PARAMIXB padrao do MATA020
@return  Logical, sempre .T. (PE informativo, nao bloqueia)
@see     MATA020
/*/
//-------------------------------------------------------------------
User Function MT020INC()

    Local aArea    := GetArea()
    Local cA2Zolid := ""
    Local cCnpj    := ""
    Local aParam   := PARAMIXB
    Local lAtuou   := .F.

    If Type("PARAMIXB") <> "A" .Or. Len(aParam) < 2
        RestArea(aArea)
        Return .T.
    EndIf

    // Tenta obter A2_ZSOLID/A2_ZZ4ID e CNPJ da SA2
    If Select("SA2") > 0 .And. !SA2->(Eof()) .And. !SA2->(Bof())
        Do Case
            Case SA2->(FieldPos("A2_ZSOLID")) > 0
                cA2Zolid := AllTrim(SA2->A2_ZSOLID)
            Case SA2->(FieldPos("A2_ZZ4ID")) > 0
                cA2Zolid := AllTrim(SA2->A2_ZZ4ID)
        EndCase
        If SA2->(FieldPos("A2_CGC")) > 0
            cCnpj := StrTran(StrTran(StrTran(AllTrim(SA2->A2_CGC),".",""),"/",""),"-","")
        EndIf
    EndIf

    // Garante que ZZ4 esta aberta
    If Select("ZZ4") <= 0
        ChkFile("ZZ4")
    EndIf

    If Select("ZZ4") <= 0
        RestArea(aArea)
        Return .T.
    EndIf

    // 1a tentativa: localiza ZZ4 pelo ID (A2_ZSOLID/A2_ZZ4ID)
    If !Empty(cA2Zolid)
        DbSelectArea("ZZ4")
        ZZ4->(DbSetOrder(1))
        If ZZ4->(DbSeek(xFilial("ZZ4") + PadR(cA2Zolid, TamSX3("ZZ4_ID")[1])))
            If AllTrim(ZZ4->ZZ4_STATUS) != '1'
                If Reclock("ZZ4", .F.)
                    Replace ZZ4_STATUS With '1'
                    Replace ZZ4_DTREJ  With dDataBase
                    MsUnlock()
                    ZZ4->(DbCommit())
                    lAtuou := .T.
                EndIf
            Else
                lAtuou := .T.
            EndIf
        EndIf
    EndIf

    // 2a tentativa: se nao achou por ID, tenta pelo CNPJ
    If !lAtuou .And. !Empty(cCnpj)
        DbSelectArea("ZZ4")
        ZZ4->(DbSetOrder(1))
        ZZ4->(DbGoTop())
        While !ZZ4->(Eof()) .And. !lAtuou
            If AllTrim(ZZ4->ZZ4_STATUS) == '0'
                If StrTran(StrTran(StrTran(AllTrim(ZZ4->ZZ4_CNPJ),".",""),"/",""),"-","") == cCnpj
                    If Reclock("ZZ4", .F.)
                        Replace ZZ4_STATUS With '1'
                        Replace ZZ4_DTREJ  With dDataBase
                        MsUnlock()
                        ZZ4->(DbCommit())
                        lAtuou := .T.
                    EndIf
                EndIf
            EndIf
            ZZ4->(DbSkip())
        EndDo
    EndIf

    RestArea(aArea)

Return .T.
