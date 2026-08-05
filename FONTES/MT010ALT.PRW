#INCLUDE "PROTHEUS.CH"

#DEFINE CRLF   Chr(13)+Chr(10)
//-------------------------------------------------------------------
/*/{Protheus.doc} MT010ALT
PE - Após gravar alteração do produto
Atualiza data de alteração quando modificado Min/Max
@author Juan
@since 05/02/2026
@version 1.0
/*/
//-------------------------------------------------------------------
User Function MT010ALT()
    Local aArea    := GetArea()
    Local aAreaSB1 := SB1->(GetArea())
    
    DbSelectArea("SB1")
    SB1->(DbSetOrder(1))
    
    If SB1->(DbSeek(xFilial("SB1") + M->B1_COD))
        
        If Type("M->B1_ZDTALT") != "U" .AND. M->B1_ZDTALT == dDataBase
            
            If SB1->B1_ZDTALT != M->B1_ZDTALT
                
                RecLock('SB1', .F.)
                    SB1->B1_ZDTALT := M->B1_ZDTALT
                SB1->(MsUnlock())
                
            EndIf
            
        EndIf
        
    EndIf
    
    RestArea(aAreaSB1)
    RestArea(aArea)
    
Return
