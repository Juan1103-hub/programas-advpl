#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"

User Function VldNomeForn()
    Local lRet := .T.
    Local cNome := ""
    Local cAlias := GetNextAlias()
    Local cCodigo := ""
    Local cLoja := ""
    
    // Pega o valor do campo (pode ser M->A2_NOME ou através de variável)
    If Type("M->A2_NOME") <> "U"
        cNome := AllTrim(M->A2_NOME)
        cCodigo := If(Type("M->A2_COD")<>"U", M->A2_COD, "")
        cLoja := If(Type("M->A2_LOJA")<>"U", M->A2_LOJA, "")
    Else
        Return .T.
    EndIf
    
    // Verifica se o campo está vazio
    If Empty(cNome)
        Return .T.
    EndIf
    
    // Busca por descrição igual
    BeginSql Alias cAlias
        SELECT A2_COD, A2_LOJA, A2_NOME
        FROM %Table:SA2% SA2
        WHERE SA2.%NotDel%
            AND SA2.A2_FILIAL = %xFilial:SA2%
            AND UPPER(RTRIM(SA2.A2_NOME)) = %Exp:Upper(cNome)%
    EndSql
    
    // Verifica se encontrou registros
    If (cAlias)->(!Eof())
        // Se for alteração, ignora o próprio registro
        If !Empty(cCodigo) .And. !Empty(cLoja)
            If (cAlias)->A2_COD == cCodigo .And. (cAlias)->A2_LOJA == cLoja
                (cAlias)->(DbCloseArea())
                Return .T.
            EndIf
        EndIf
        
        lRet := .F.
        MsgStop('Ja existe um fornecedor cadastrado com este nome:' + CRLF + ;
                'Codigo: ' + AllTrim((cAlias)->A2_COD) + '/' + AllTrim((cAlias)->A2_LOJA) + CRLF + ;
                'Nome: ' + AllTrim((cAlias)->A2_NOME), 'FORNECEDOR JA EXISTE')
    EndIf
    
    (cAlias)->(DbCloseArea())
    
Return lRet
