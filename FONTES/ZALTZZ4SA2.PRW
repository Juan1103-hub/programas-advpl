#Include "Protheus.ch"
#Include "TopConn.ch"

#Define CRLF Chr(13) + Chr(10)

//-------------------------------------------------------------------
/*/{Protheus.doc} ZALTZZ4SA2
Adiciona fisicamente a coluna A2_ZZ4ID na tabela SA2 do banco de dados.

Usa TCSQLExec para executar o ALTER TABLE sem necessidade de acesso
direto ao SSMS. Deve ser executado UMA UNICA VEZ apos rodar ZCRIAZZ4SA2.

Verificacao automatica:
  - Descobre o nome real da tabela SA2 via RetSQLName
  - Verifica se a coluna ja existe antes de tentar criar
  - Exibe o resultado da operacao

@type User Function
@version 12.1.33
@author  Suprimentos
@since   2026
/*/
//-------------------------------------------------------------------
User Function ZALTZZ4SA2()

    Local aArea    := GetArea()
    Local cTabela  := RetSQLName("SA2")
    Local cSQL     := ""
    Local nRet     := 0
    Local lExiste  := .F.
    Local cAlias   := GetNextAlias()

    // Descobre o nome real da tabela
    If Empty(cTabela)
        MsgStop("Nao foi possivel obter o nome da tabela SA2." + CRLF + ;
                "Verifique se a tabela esta registrada no SX2.", "Erro")
        RestArea(aArea)
        Return
    EndIf

    // Verifica se a coluna A2_ZZ4ID ja existe fisicamente via INFORMATION_SCHEMA
    // (evita erro ao tentar SELECT em coluna inexistente)
    cSQL := "SELECT COUNT(*) AS QTD FROM INFORMATION_SCHEMA.COLUMNS " + ;
            "WHERE TABLE_NAME = '" + cTabela + "' AND COLUMN_NAME = 'A2_ZZ4ID'"

    dbUseArea(.T., "TOPCONN", TCGenQry(,, cSQL), cAlias, .F., .T.)

    If Select(cAlias) > 0
        If (cAlias)->QTD > 0
            lExiste := .T.
        EndIf
        (cAlias)->(DbCloseArea())
    EndIf

    If lExiste
        MsgInfo("A coluna A2_ZZ4ID JA EXISTE fisicamente na tabela " + cTabela + "!" + CRLF + CRLF + ;
                "Nenhuma alteracao foi feita." + CRLF + CRLF + ;
                "Se o campo nao aparece no MATA020, reinicie o Protheus.", ;
                "Coluna Existente")
        RestArea(aArea)
        Return
    EndIf

    // Executa o ALTER TABLE
    cSQL  := "ALTER TABLE " + cTabela + " ADD A2_ZZ4ID VARCHAR(6) DEFAULT '      '"
    nRet  := TCSQLExec(cSQL)

    If nRet == 0
        MsgInfo("Coluna A2_ZZ4ID adicionada com sucesso!" + CRLF + CRLF + ;
                "Tabela  : " + cTabela + CRLF + ;
                "Coluna  : A2_ZZ4ID  VARCHAR(6)" + CRLF + CRLF + ;
                "REINICIE o Protheus agora para ativar o campo.", ;
                "Sucesso")
    Else
        MsgStop("Erro ao executar ALTER TABLE." + CRLF + CRLF + ;
                "Tabela  : " + cTabela + CRLF + ;
                "Erro Nr : " + cValToChar(nRet) + CRLF + CRLF + ;
                "Verifique as permissoes do usuario de banco de dados.", ;
                "Erro ALTER TABLE")
    EndIf

    RestArea(aArea)

Return
