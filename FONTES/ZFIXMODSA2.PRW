#Include "Protheus.ch"

#Define CRLF Chr(13) + Chr(10)

//-------------------------------------------------------------------
/*/{Protheus.doc} ZFIXMODSA2
Corrige o X3_MODULO do campo A2_ZZ4ID na SA2 (SX3).

Copia o valor de X3_MODULO do campo A2_NOME (campo padrao SA2)
para garantir que o campo A2_ZZ4ID fique disponivel nos mesmos
modulos que os demais campos do fornecedor.

Executar quando o campo nao aparecer no MATA020 ou quando as
caixas de modulo no configurador nao puderem ser marcadas.

@type User Function
@version 12.1.33
@author  Suprimentos
@since   2026
/*/
//-------------------------------------------------------------------
User Function ZFIXMODSA2()

    Local aArea      := GetArea()
    Local cModulo    := ""
    Local cOrdemCod  := ""
    Local cNovaOrdem := ""
    Local lAcheiRef  := .F.
    Local lAcheiAlvo := .F.
    Local nPosModRef := 0
    Local nPosModAlvo:= 0
    Local nOrdemCod  := 0

    DbSelectArea("SX3")
    SX3->(DbSetOrder(2))  // Ordem por X3_CAMPO

    // Verifica se X3_MODULO existe nesta versao
    nPosModRef := SX3->(FieldPos("X3_MODULO"))

    // Busca ordem e modulo de A2_COD (referencia de posicao)
    If SX3->(DbSeek("A2_COD"))
        While !SX3->(Eof()) .And. AllTrim(SX3->X3_CAMPO) == "A2_COD"
            If AllTrim(SX3->X3_ARQUIVO) == "SA2"
                cOrdemCod := AllTrim(SX3->X3_ORDEM)
                nOrdemCod := Val(cOrdemCod)
                If nPosModRef > 0
                    cModulo   := FieldGet(nPosModRef)
                EndIf
                lAcheiRef := .T.
                Exit
            EndIf
            SX3->(DbSkip())
        EndDo
    EndIf

    If !lAcheiRef
        MsgStop("Campo A2_COD nao encontrado no SX3.", "Erro")
        RestArea(aArea)
        Return
    EndIf

    // Nova ordem = A2_COD + 1 (logo apos o codigo)
    cNovaOrdem := StrZero(nOrdemCod + 1, Len(cOrdemCod))

    // Atualiza A2_ZZ4ID: ordem, modulo e usado
    DbSelectArea("SX3")
    SX3->(DbSetOrder(2))

    If SX3->(DbSeek("A2_ZZ4ID"))
        While !SX3->(Eof()) .And. AllTrim(SX3->X3_CAMPO) == "A2_ZZ4ID"
            If AllTrim(SX3->X3_ARQUIVO) == "SA2"
                nPosModAlvo := SX3->(FieldPos("X3_MODULO"))
                RecLock("SX3", .F.)
                    SX3->X3_ORDEM := cNovaOrdem
                    If nPosModAlvo > 0 .And. !Empty(cModulo)
                        FieldPut(nPosModAlvo, cModulo)
                    EndIf
                    If SX3->(FieldPos("X3_USADO")) > 0  ;  SX3->X3_USADO := "1"  ;  EndIf
                MsUnlock()
                lAcheiAlvo := .T.
                Exit
            EndIf
            SX3->(DbSkip())
        EndDo
    EndIf

    If lAcheiAlvo
        MsgInfo("Campo A2_ZZ4ID reposicionado com sucesso!" + CRLF + CRLF + ;
                "A2_COD ordem : " + cOrdemCod + CRLF + ;
                "A2_ZZ4ID nova ordem: " + cNovaOrdem + CRLF + CRLF + ;
                "REINICIE o Protheus para aplicar a nova posicao.", "Sucesso")
    Else
        MsgStop("Campo A2_ZZ4ID nao encontrado no SX3." + CRLF + ;
                "Execute primeiro U_ZCRIAZZ4SA2.", "Erro")
    EndIf

    RestArea(aArea)

Return
