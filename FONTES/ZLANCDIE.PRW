#Include "Protheus.ch"
#Include "TopConn.ch"


//-------------------------------------------------------------------
/*/{Protheus.doc} ZLANCDIE
Cadastro de Lancamento de Diesel (ZD1).
Utiliza AxCadastro padrao do Protheus com browse, inclusao,
alteracao, exclusao e visualizacao nativos via SX3.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   02/07/2026
@return  Void
@table   ZD1

@history 03/07/2026, Suprimentos, Substituido por AxCadastro padrao.
                          Remove toda a logica customizada de MSDIALOG,
                          LISTBOX, MVC, validacoes e wrappers.
/*/
//-------------------------------------------------------------------
User Function ZLANCDIE()
    AxCadastro("ZD1", "Lancamento de Diesel")
Return
