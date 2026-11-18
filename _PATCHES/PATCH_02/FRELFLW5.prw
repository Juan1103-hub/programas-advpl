#Include "Protheus.ch"
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} 

Custos com  compras - analitico - Inclui pedidos em aberto não vincu

@author 	
@since 		

12/07/2024

/*/
//-------------------------------------------------------------------

User Function FRELFLW5()

Local cPerg   := "FRELFLW3"  

Private oReport


If !Pergunte(cPerg,.T.)
	Return 
EndIf 
 

FCabRep()
ReportDef()
oReport:PrintDialog()

Return



Static Function FCabRep()

oReport := TReport():New("FRELFLW3","Custos - Analitico","FRELFLW3",{|oReport| PrintReport(oReport)},"Este programa irá emitir uma relação dos custos de aquisição de materiais, no detalhe.")
oReport:lDisableOrientation:= .T. 
oReport:SetLandscape() 

Return 




Static Function ReportDef()

Local oSection1

oSection1 := TRSection():New(oReport,"PedidosCompras","TRB")                                                                          

TRCell():New(oSection1,"D1_PEDIDO"    ,"TRB")
TRCell():New(oSection1,"D1_ITEM"   ,"TRB")
TRCell():New(oSection1,"D1_COD"   ,"TRB")
TRCell():New(oSection1,"B1_DESC"  ,"TRB")
TRCell():New(oSection1,"D1_EMISSAO"     ,"TRB","Data Nfe")
TRCell():New(oSection1,"D1_TOTAL"  ,"TRB")
TRCell():New(oSection1,"D1_VALFRE"  ,"TRB")
TRCell():New(oSection1,"D1_DESPESA"  ,"TRB")
TRCell():New(oSection1,"D1_VALIPI"  ,"TRB")
TRCell():New(oSection1,"D1_ICMSRET"  ,"TRB")
TRCell():New(oSection1,"D1_VALDESC"  ,"TRB")
TRCell():New(oSection1,"D1_VALFIN"  ,"TRB","Custo Unit.Total",,20)
TRCell():New(oSection1,"D1_FORNECE"   ,"TRB")
TRCell():New(oSection1,"A2_NOME"   ,"TRB")
TRCell():New(oSection1,"D1_CC"   ,"TRB") 
TRCell():New(oSection1,"CTT_DESC01"   ,"TRB","Nome C.Custo")
TRCell():New(oSection1,"D1_EC05DB", "TRB") 
TRCell():New(oSection1,"CV0_DESC"   ,"TRB","Nome Nat.Gasto")
TRCell():New(oSection1,"D1_CLVL"   ,"TRB")
TRCell():New(oSection1,"CTH_DESC01"   ,"TRB","Nome C.Valor")
TRCell():New(oSection1,"C7_USER"   ,"TRB","Responsável")
TRCell():New(oSection1,"C7_EMISSAO"     ,"TRB","Data PC")

/*
oSection1:Cell("VAL0101"):SetHeaderAlign("RIGHT")
oSection1:Cell("VAL0102"):SetHeaderAlign("RIGHT")
oSection1:Cell("VAL0103"):SetHeaderAlign("RIGHT")
oSection1:Cell("VALTOT"):SetHeaderAlign("RIGHT")
*/ 
oSection1:lAutoSize := .T.
oSection1:SetNoFilter("") //Desabilitei os filtros desta seção. 

Return(oReport)




Static Function PrintReport(oReport)

Local oSection1 := oReport:Section(1)

FBuscaDados() 

oSection1:Init()

dbSelectArea("TRB")
dbGoTop() 

While !Eof() 

	oSection1:Cell("C7_USER"):SetValue(FwGetUserName(TRB->C7_USER))
	oSection1:Cell("D1_EMISSAO"):SetValue(STOD(TRB->D1_EMISSAO))
	oSection1:Cell("C7_EMISSAO"):SetValue(STOD(TRB->C7_EMISSAO))
	oSection1:Cell("D1_VALFIN"):SetValue(Transform(TRB->D1_VALFIN,PesqPict("SD1","D1_TOTAL")))	
	oSection1:PrintLine()

	dbSelectArea("TRB")
	dbSkip() 
EndDo 

oSection1:Finish()		

dbSelectArea("TRB")
dbCloseArea() 

Return


Static Function FBuscaDados() 

Local cQuery := ""
Local cFator := "" 

cFator := "CASE WHEN C7_QUJE > 0 THEN (C7_QUANT - C7_QUJE) / NULLIF(C7_QUANT, 0) ELSE 1 END"

cQuery := "SELECT D1_PEDIDO, D1_ITEM, D1_COD, D1_EMISSAO, D1_TOTAL, D1_FORNECE, D1_CC, "
cQuery += "(SELECT B1_DESC FROM " + RetSqlName("SB1") + " WHERE D_E_L_E_T_ <> '*' AND B1_COD = D1_COD) AS B1_DESC, " 
cQuery += "D1_VALFRE, D1_DESPESA, D1_VALIPI, D1_ICMSRET, D1_VALDESC, "   
cQuery += "(D1_TOTAL - D1_VALDESC + D1_VALFRE  + D1_DESPESA + D1_VALIPI + D1_ICMSRET) AS D1_VALFIN, "
cQuery += "(SELECT A2_NOME FROM " + RetSQlName("SA2") + " WHERE D_E_L_E_T_ <> '*' AND D1_FORNECE = A2_COD AND D1_LOJA = A2_LOJA ) AS A2_NOME, "
cQuery += "(SELECT CTT_DESC01 FROM " + RetSqlName("CTT") + " WHERE D_E_L_E_T_  <> '*'  AND CTT_CUSTO = D1_CC ) AS CTT_DESC01, " 
cQuery += "D1_CLVL, (SELECT CTH_DESC01 FROM " + RetSqlName("CTH") + " WHERE D_E_L_E_T_  <> '*'  AND CTH_CLVL = D1_CLVL) AS CTH_DESC01, "
cQuery += "D1_EC05DB,  (SELECT CV0_DESC FROM " + RetSqlName("CV0") + " WHERE D_E_L_E_T_ <> '*' AND CV0_CODIGO = D1_EC05DB) AS CV0_DESC, " 
cQuery += "(SELECT C7_USER FROM " + RetSqlName("SC7") + " WHERE D_E_L_E_T_ <> '*' AND C7_FILIAL = '" + xFilial("SC7") + "' AND " 
cQuery += "C7_NUM = D1_PEDIDO AND C7_ITEM = D1_ITEMPC AND C7_PRODUTO = D1_COD) AS C7_USER, "
cQuery += "(SELECT C7_EMISSAO FROM " + RetSqlName("SC7") + " WHERE D_E_L_E_T_ <> '*' AND C7_FILIAL = '" + xFilial("SC7") + "' AND " 
cQuery += "C7_NUM = D1_PEDIDO AND C7_ITEM = D1_ITEMPC AND C7_PRODUTO = D1_COD) AS C7_EMISSAO "
cQuery += "FROM " + RetSqlName("SD1") + " WHERE D_E_L_E_T_ <> '*' AND " 
cQuery += "D1_FILIAL = '" + xFilial("SD1") + "' AND "
cQuery += "D1_EMISSAO BETWEEN '" + DTOS(MV_PAR01) + "' AND '" + DTOS(MV_PAR02) + "' AND D1_TES <> '' " 
cQuery += "UNION "
cQuery += "SELECT C7_NUM AS D1_PEDIDO, C7_ITEM AS D1_ITEM, C7_PRODUTO AS D1_COD, '' AS D1_EMISSAO, C7_TOTAL * " + cFator + " AS D1_TOTAL, C7_FORNECE AS D1_FORNECE, C7_CC AS D1_CC, "
cQuery += "(SELECT B1_DESC FROM " + RetSqlName("SB1") + " WHERE D_E_L_E_T_ <> '*' AND B1_COD = C7_PRODUTO) AS B1_DESC, " 
cQuery += "C7_VALFRE * " + cFator + " AS D1_VALFRE, C7_DESPESA * " + cFator + " AS D1_DESPESA, C7_VALIPI * " + cFator + " AS D1_VALIPI, C7_ICMSRET * " + cFator + " AS D1_ICMSRET, C7_VLDESC * " + cFator + " AS D1_VALDESC, "   
cQuery += "(C7_TOTAL - C7_VLDESC + C7_VALFRE  + C7_DESPESA + C7_VALIPI + C7_ICMSRET) * " + cFator + " AS D1_VALFIN, "
cQuery += "(SELECT A2_NOME FROM " + RetSQlName("SA2") + " WHERE D_E_L_E_T_ <> '*' AND C7_FORNECE = A2_COD AND C7_LOJA = A2_LOJA ) AS A2_NOME, "
cQuery += "(SELECT CTT_DESC01 FROM " + RetSqlName("CTT") + " WHERE D_E_L_E_T_  <> '*'  AND CTT_CUSTO = C7_CC ) AS CTT_DESC01, " 
cQuery += "C7_CLVL, (SELECT CTH_DESC01 FROM " + RetSqlName("CTH") + " WHERE D_E_L_E_T_  <> '*'  AND CTH_CLVL = C7_CLVL) AS CTH_DESC01, "
cQuery += "C7_EC05DB,  (SELECT CV0_DESC FROM " + RetSqlName("CV0") + " WHERE D_E_L_E_T_ <> '*' AND CV0_CODIGO = C7_EC05DB) AS CV0_DESC, " 
cQuery += "C7_USER, "
cQuery += "C7_EMISSAO "
cQuery += "FROM " + RetSqlName("SC7") + " WHERE D_E_L_E_T_ <> '*' AND " 
cQuery += "C7_FILIAL = '" + xFilial("SC7") + "' AND "
cQuery += "C7_RESIDUO = '' AND C7_TIPO = 1 AND C7_QUJE < C7_QUANT AND ISNULL(C7_ENCER,'') <> 'E' "
cQuery += "AND (C7_QTDACLA = 0 OR NOT EXISTS ( "
cQuery += "SELECT 1 FROM " + RetSqlName("SD1") + " P WHERE P.D_E_L_E_T_ <> '*' "
cQuery += "AND P.D1_FILIAL = '" + xFilial("SD1") + "' "
cQuery += "AND P.D1_PEDIDO = C7_NUM AND P.D1_ITEMPC = C7_ITEM "
cQuery += "AND P.D1_TES <> '' "
cQuery += "AND P.D1_EMISSAO BETWEEN '" + DTOS(MV_PAR01) + "' AND '" + DTOS(MV_PAR02) + "' )) "
cQuery += " AND ISNULL(C7_CONAPRO,'') <> 'R' "

TcQuery cQuery Alias "TRB" New 

Return 
