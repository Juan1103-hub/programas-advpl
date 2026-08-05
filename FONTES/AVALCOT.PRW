#Include 'Protheus.ch'

User Function AVALCOT()
Local nEvento := PARAMIXB[1]
Local aArea := GetArea()

If nEvento == 4 .And. Select("SC8") > 0
    dbSelectArea('SC7')
    If RecLock('SC7',.F.)
        SC7->C7_TPFRETE := SC8->C8_TPFRETE
        MsUnlock()
    EndIf
EndIf
RestArea(aArea)
Return
