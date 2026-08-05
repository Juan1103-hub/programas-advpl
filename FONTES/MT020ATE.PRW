#Include "Protheus.ch"

/*/{Protheus.doc} MT020ATE
    PE de filtro adicional do MATA020 (Browse SA2 - Cadastro de Fornecedores).
    Usado para garantir que a tabela ZZ4 esteja aberta na sessao do usuario
    antes de qualquer interacao com o formulario SA2.

    Causa raiz do problema: FWLOOKUP:OPEN12 (build 7.00.240223P) chama
    BUILDBROWSE:SETALIAS("ZZ4") antes de abrir a tabela. ZZ4 e customizada
    e nunca e aberta pelo MATA020 automaticamente. X3_WHEN nao persiste na
    thread do lookup neste build. MT020ATE dispara no MATA020:Activate(),
    antes de qualquer form, garantindo ZZ4 aberta para toda a sessao.

    @type User Function
    @version 12.1.33
    @author  Suprimentos
    @since   12/06/2026
    @return  cFiltro, character, filtro adicional SA2 (vazio = sem restricao)
/*/
User Function MT020ATE()
    If Select("ZZ4") <= 0
        ChkFile("ZZ4")
    EndIf
Return ""
