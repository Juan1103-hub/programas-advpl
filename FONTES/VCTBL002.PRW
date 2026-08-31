#include "rwmake.ch" 
#include "Protheus.ch"
#INCLUDE "TBICONN.CH"
#INCLUDE "topconn.CH"  

/*/{Protheus.doc} VCTBL002.PRW

@type function
@author Geraldo E. Franciscon - Conti
@since 03/02/2025
@version 1.0
/*/

User Function VCTBL002()
    Local cContaRet := ""

    If Empty(SB1->B1_XCTCUST) .AND. Empty(SB1->B1_XCTDESP) .AND. Empty(SB1->B1_XCTCIND)
        cContaRet := SB1->B1_CONTA
    ElseIf SubStr(SD3->D3_CC,1,2) $ "60" .OR. AllTrim(SD3->D3_CC) $ "5010204"
        cContaRet := SB1->B1_XCTCUST
    ElseIf SubStr(SD3->D3_CC,1,2) $ "70/80/90"
        cContaRet := SB1->B1_XCTCIND
    ElseIf SubStr(SD3->D3_CC,1,2) $ "50/10/11/12/13/14" .Or. SubStr(SD3->D3_CC,1,4) $ "0199"
        cContaRet := SB1->B1_XCTDESP
    EndIf

    Return cContaRet
