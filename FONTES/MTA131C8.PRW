#Include 'Protheus.ch'

User Function MTA131C8()
 
Local oModFor := PARAMIXB[1] //Modelo da SC8 posicionado na linha que está sendo gravada. Poderá resgatar o valor de qualquer campo da SC8, exemplo: oModFor:GetValue("C8_PRODUTO")

oModFor:LoadValue("C8_EC05DB",SC1->C1_EC05DB)
oModFor:LoadValue("C8_ZUPRC",SC1->C1_ZUPRC)

Return
