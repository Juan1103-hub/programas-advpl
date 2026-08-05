#Include "Protheus.ch"

/*/{Protheus.doc} OPENZZ4
    Expressao de X3_INIBRW do campo A2_ZSOLID no MATA020.
    Avaliada por FWPRESHOW(X,Y) em PROTHEUSLOOKUP.PRW linha 160,
    ANTES de FWLOOKUP:SHOW->OPEN12->BUILDBROWSE:SETALIAS("ZZ4").
    Garante que ZZ4 esteja aberta antes do SETALIAS ser invocado.

    Fluxo corrigido:
      FWLOOKUP:ACTIVATE -> PROTHEUSLOOKUP codeblock -> FWPRESHOW("U_OPENZZ4()")
        -> U_OPENZZ4() -> ChkFile("ZZ4") -> ZZ4 aberta
      -> FWLOOKUP:SHOW -> OPEN12 -> BUILDBROWSE -> SETALIAS("ZZ4") -> OK

    @type User Function
    @version 12.1.33
    @author  Suprimentos
    @since   12/06/2026
    @return  cRet, character, valor inicial do campo (vazio = sem alteracao)
/*/
User Function OPENZZ4()
    If Select("ZZ4") <= 0
        ChkFile("ZZ4")
    EndIf
Return .T.
