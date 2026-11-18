#Include "Protheus.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} MTA020
PE de inicializacao do MATA020 (Cadastro de Fornecedores SA2).

Garante que a tabela ZZ4 (Solicitacoes Cadastrais) esteja aberta
como alias antes do formulario de inclusao/alteracao ativar, para
que o FWLookup do campo A2_ZSOLID (F3) consiga localizar o alias.

@type User Function
@version 12.1.33
@author  Suprimentos
@since   2026
/*/
//-------------------------------------------------------------------
User Function MTA020()

    Local aArea := GetArea()

    ConOut("MTA020: PE chamado. Select(ZZ4)=" + cValToChar(Select("ZZ4")))

    If Select("ZZ4") <= 0
        ChkFile("ZZ4")
        ConOut("MTA020: Apos ChkFile. Select(ZZ4)=" + cValToChar(Select("ZZ4")))
    EndIf

    RestArea(aArea)
Return
