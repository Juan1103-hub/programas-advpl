#Include "Protheus.ch"

/*/{Protheus.doc} OPENZZ4
    Expressao X3_INIBRW do campo A2_ZSOLID no MATA020.
    Executada por FWPRESHOW() em PROTHEUSLOOKUP.PRW, ANTES de
    FWLOOKUP:SHOW->OPEN12->BUILDBROWSE:SETALIAS("ZZ4").

    Abre ZZ4 via ChkFile para garantir que o alias esteja disponivel
    quando FWLookup monta o browse. O filtro por pendentes (STATUS='0')
    e feito pelo SXB Tipo 9 (filtro SQL).

    @type User Function
    @version 12.1.33
    @author  Suprimentos
    @since   15/06/2026
    @return  lRet, .T. sempre (expressao X3_INIBRW)
/*/
User Function OPENZZ4()

    Local aArea := GetArea()

    If Select("ZZ4") <= 0
        If !ChkFile("ZZ4")
            RestArea(aArea)
            Return .T.
        EndIf
    EndIf

    RestArea(aArea)
Return .T.
