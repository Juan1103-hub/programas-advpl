#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} MT160GRPC
Gravação de campos adicionais no pedido quando o mesmo for gerado através de cotação
Transfere automaticamente os campos customizados da SC8 para a SC7.

@type        function
@author      Eurai Rapelli
@since       2023.01.01
@update      2026.01.21
@obs         Ponto de entrada executado na geração do pedido a partir da cotação
/*/
User Function MT160GRPC()
    Local aArea     := GetArea()
    Local aAreaSC8  := SC8->(GetArea())
    
    // Transfere os campos da cotação (SC8) para o pedido (SC7)
    If SC8->(FieldPos("C8_XESTOC")) > 0 .And. SC7->(FieldPos("C7_XESTOQ1")) > 0
        SC7->C7_XESTOQ1 := SC8->C8_XESTOC
    EndIf
    
    RestArea(aAreaSC8)
    RestArea(aArea)
    
Return Nil
