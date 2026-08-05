#Include "Protheus.ch"
#Include "TopConn.ch"

#Define CRLF Chr(13) + Chr(10)

//-------------------------------------------------------------------
/*/{Protheus.doc} ZFIXSX3SA2
Corrige flags do campo A2_ZZ4ID no SX3 via UPDATE SQL direto.

Copia X3_USADO, X3_MODULO (e demais flags de visibilidade) do
campo A2_COD para o A2_ZZ4ID, garantindo que o campo apareca
no formulario MATA020.

@type User Function
@version 12.1.33
@author  Suprimentos
@since   2026
/*/
//-------------------------------------------------------------------
User Function ZFIXSX3SA2()

    Local aArea   := GetArea()
    Local cTabSX3 := RetSQLName("SX3")
    Local cSQL    := ""
    Local nRet    := 0
    Local cAlias  := GetNextAlias()
    Local cInfo   := ""

    If Empty(cTabSX3)
        MsgStop("Nao foi possivel obter o nome da tabela SX3.", "Erro")
        RestArea(aArea)
        Return
    EndIf

    // Mostra os valores atuais de A2_COD e A2_ZZ4ID para diagnostico
    cSQL := "SELECT X3_CAMPO, X3_USADO, X3_ORDEM " + ;
            "FROM " + cTabSX3 + " " + ;
            "WHERE D_E_L_E_T_ = ' ' " + ;
            "AND X3_ARQUIVO = 'SA2' " + ;
            "AND X3_CAMPO IN ('A2_COD','A2_ZZ4ID') " + ;
            "ORDER BY X3_CAMPO"

    dbUseArea(.T., "TOPCONN", TCGenQry(,, cSQL), cAlias, .F., .T.)
    If Select(cAlias) > 0
        (cAlias)->(DbGoTop())
        While !(cAlias)->(Eof())
            cInfo += "Campo: " + AllTrim((cAlias)->X3_CAMPO) + ;
                     "  Usado: [" + AllTrim((cAlias)->X3_USADO) + "]" + ;
                     "  Ordem: [" + AllTrim((cAlias)->X3_ORDEM) + "]" + CRLF
            (cAlias)->(DbSkip())
        EndDo
        (cAlias)->(DbCloseArea())
    EndIf

    MsgInfo("Estado atual no banco:" + CRLF + CRLF + cInfo + CRLF + ;
            "Clique OK para aplicar o UPDATE.", "Diagnostico")

    // UPDATE: copia X3_USADO de A2_COD e ajusta ordem para 03 (logo apos A2_COD=02)
    cSQL := "UPDATE " + cTabSX3 + " " + ;
            "SET X3_USADO = (SELECT TOP 1 X3_USADO FROM " + cTabSX3 + " " + ;
            "                WHERE D_E_L_E_T_ = ' ' AND X3_ARQUIVO = 'SA2' AND X3_CAMPO = 'A2_COD'), " + ;
            "    X3_ORDEM  = '03' " + ;
            "WHERE D_E_L_E_T_ = ' ' " + ;
            "AND X3_ARQUIVO = 'SA2' " + ;
            "AND X3_CAMPO   = 'A2_ZZ4ID'"

    nRet := TCSQLExec(cSQL)

    If nRet == 0

        // Verifica resultado
        cAlias := GetNextAlias()
        cSQL   := "SELECT X3_CAMPO, X3_USADO, X3_ORDEM " + ;
                  "FROM " + cTabSX3 + " " + ;
                  "WHERE D_E_L_E_T_ = ' ' " + ;
                  "AND X3_ARQUIVO = 'SA2' " + ;
                  "AND X3_CAMPO IN ('A2_COD','A2_ZZ4ID') " + ;
                  "ORDER BY X3_CAMPO"

        dbUseArea(.T., "TOPCONN", TCGenQry(,, cSQL), cAlias, .F., .T.)
        cInfo := ""
        If Select(cAlias) > 0
            (cAlias)->(DbGoTop())
            While !(cAlias)->(Eof())
                cInfo += "Campo: " + AllTrim((cAlias)->X3_CAMPO) + ;
                         "  Usado: [" + AllTrim((cAlias)->X3_USADO) + "]" + ;
                         "  Ordem: [" + AllTrim((cAlias)->X3_ORDEM) + "]" + CRLF
                (cAlias)->(DbSkip())
            EndDo
            (cAlias)->(DbCloseArea())
        EndIf

        MsgInfo("UPDATE executado com sucesso!" + CRLF + CRLF + ;
                "Estado apos UPDATE:" + CRLF + cInfo + CRLF + ;
                "REINICIE o Protheus agora.", "Sucesso")
    Else
        MsgStop("Erro no UPDATE. Codigo: " + cValToChar(nRet), "Erro")
    EndIf

    RestArea(aArea)

Return
