#Include "Protheus.ch" 
#Include "TopConn.ch" 

#Define ENTER  Chr(10) + Chr (13) // SALTO DE LINHA (CARRIAGE RETURN + LINE FEED)
//-------------------------------------------------------------------
/*/{Protheus.doc} 

Cadastro de Solicitacao Cadastral 

@author 	
@since 		

25/04/2024

/*/
//-------------------------------------------------------------------

User Function CADSZ3_V2() 
 
Private cCadastro := "Solicitação Cadastral"

//0=Solicitar;1=Cadastrado;2=Rejeitado   

Private aCores := {{ "SZ3->Z3_STATUS == '0'","BR_BRANCO" },; 
                   { "SZ3->Z3_STATUS == '1'","DISABLE"},;
                   { "SZ3->Z3_STATUS == '2'","BR_PRETO"}}

Private aRotina := { {"Pesquisar" ,"AxPesqui"     ,0,1},; //
                     {"Incluir"   ,"U_CADINSV2()" ,0,3},; // 
                     {"Vinc.Foto" ,"AxAltera"     ,0,4},;
                     {"Excluir"   ,"AxDeleta"     ,0,5},;
                     {"Visualizar","AxVisual"     ,0,2},; //
                     {"Imprimir"  ,"FRELFLW1()"   ,0,7},;                                          
                     {"Legenda"   ,"U_CADLESV2()" ,0,6},;
                     {"Verificar Cadastros","U_CADVERZ3()",0,7}}  //                   

Private cDelFunc := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock

Private cString := "SZ3"

dbSelectArea(cString)
dbSetOrder(1)

mBrowse( 6,1,22,75,cString,,,,,,aCores)

Return




User Function CADINSV2() 

Local oButton1
Local oButton2
Local oButton3
Local oGet1
Local cGet1 := Space(120)
Local oGet2
Local cGet2 := Space(120)
Local oGet3
Local cGet3 := Space(150)
Local oGet4
Local cGet4 := Space(254)
Local oGet5
Local cGet5 := Space(02)
Local oGet6 
Local cGet6 := Space(100)
Local oGet7 
Local cGet7 := Space(100)
Local oGroup1
Local oGroup2
Local oGroup3
Local oGroup4
Local oGroup5
Local oGroup6 
Local cCombo
Local aItens:= {'Sim','Não'}

Private oMSNewGe1
Private oDlg
Private aHeaderEx := {}
Private aColsEx := {}

cCombo:= aItens[2]

DEFINE MSDIALOG oDlg TITLE "Solicitação de Cadastro de Produtos" FROM 000, 000  TO 800, 735 COLORS 0, 16777215 PIXEL

    @ 016, 011 MSGET oGet1 VAR cGet1 SIZE 253, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 003, 005 GROUP oGroup1 TO 119, 351 PROMPT "Pesquise aqui se o produto já existe no cadastro. " OF oDlg COLOR 0, 16777215 PIXEL

    fMSNewGe1()

    //oGet1:SetFocus()

    @ 015, 283 BUTTON oButton1 PROMPT "Pesquisar" SIZE 037, 012 OF oDlg PIXEL Action FPesProd(cGet1)

    @ 128, 007 GROUP oGroup2 TO 161, 355 PROMPT "Descrição do material completa, de forma clara e concisa - Exemplo: PARAFUSO SEXTAVADO AÇO 8.8 ROSCA INTEIRA M16 X 50" OF oDlg COLOR 0, 16777215 PIXEL
    @ 139, 016 MSGET oGet2 VAR cGet2 SIZE 313, 010 OF oDlg COLORS 0, 16777215 PIXEL

    @ 169, 007 GROUP oGroup3 TO 197, 355 PROMPT "PART NUMBER (PN) - No. referência ou código do material - Exemplo: Macaco Hidropneumático Tipo Garrafa 12 Toneladas - PN LPK-207Q" OF oDlg COLOR 0, 16777215 PIXEL
    @ 181, 016 MSGET oGet3 VAR cGet3 SIZE 326, 010 OF oDlg COLORS 0, 16777215 PIXEL

    @ 207, 007 GROUP oGroup4 TO 236, 355 PROMPT "LINK DE REFERÊNCIA - Informar o link do site do fabricante, exceto links de marketplaces - Exemplo:Mercado livre,Shoppe,Magazine luiza." OF oDlg COLOR 0, 16777215 PIXEL
    @ 218, 016 MSGET oGet4 VAR cGet4 SIZE 321, 010 OF oDlg COLORS 0, 16777215 PIXEL

    @ 242, 007 GROUP oGroup5 TO 270, 355 PROMPT "UNIDADE DE MEDIDA - Unidade na qual o material é medido. - Exemplo: peças, metros, litros. " OF oDlg COLOR 0, 16777215 PIXEL
    @ 253, 016 MSGET oGet5 VAR cGet5 VALID FVldSAH(cGet5) SIZE 038, 010 OF oDlg COLORS 0, 16777215 PIXEL F3 "SAH" 

    @ 276, 007 GROUP oGroup5 TO 305, 300 PROMPT "Urgente - Sim para cadastro até 24h úteis. / Não urgente até 72h úteis." OF oDlg COLOR 0, 16777215 PIXEL
    oCombo:= tComboBox():New(286,016,{|u|if(PCount()>0,cCombo:=u,cCombo)},aItens,30,10,oDlg,,,,,,.T.,,,,,,,,,'cCombo')

    @ 286, 050 MSGET oGet7 VAR cGet7 SIZE 230, 010 OF oDlg COLORS 0, 16777215 PIXEL

    @ 310, 007 GROUP oGroup6 TO 338, 300 PROMPT "APLICAÇÃO - Onde o produto será aplicado. " OF oDlg COLOR 0, 16777215 PIXEL
    @ 320, 016 MSGET oGet6 VAR cGet6 SIZE 200, 010 OF oDlg COLORS 0, 16777215 PIXEL 

    @ 282, 310 BUTTON oButton2 PROMPT "Confirmar" SIZE 037, 012 OF oDlg PIXEL Action FGravDados(cGet2,cGet3,cGet4,cGet5,SubStr(cCombo,1,1),cGet6,cGet7)  
    @ 302, 310 BUTTON oButton3 PROMPT "Cancelar" SIZE 037, 012 OF oDlg PIXEL Action oDlg:End() 


ACTIVATE MSDIALOG oDlg CENTERED

Return

Static Function FVldSAH(cGet5) 

Local lRet := .T.  

If !Empty(cGet5)
    lRet := ExistCpo("SAH",UPPER(cGet5))
EndIf 


Return(lRet)


Static Function fMSNewGe1()

Local nX
Local aFieldFill := {}
Local aFields := {"B1_COD","B1_UM","B1_GRUPO","B1_POSIPI ","B1_DESC","B2_QATU"}


  // Define field properties
  DbSelectArea("SX3")
  SX3->(DbSetOrder(2))
  For nX := 1 to Len(aFields)
    If SX3->(DbSeek(aFields[nX]))
      Aadd(aHeaderEx, {AllTrim(X3Titulo()),SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,;
                       SX3->X3_USADO,SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CONTEXT,SX3->X3_CBOX,SX3->X3_RELACAO})
    Endif
  Next nX

  // Define field values
  For nX := 1 to Len(aFields)
    If DbSeek(aFields[nX])
      Aadd(aFieldFill, CriaVar(SX3->X3_CAMPO))
    Endif
  Next nX

  Aadd(aColsEx, aFieldFill)

  oMSNewGe1 := TCBrowse():New( 34 , 11, 335, 80,,;
                              {'Codigo        ','U.M.','Grupo    ','NCM         ','Descrição','Saldo'},{20,04,10,15,100,50},;
                              oDlg,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )

  oMSNewGe1:SetArray(aColsEx)

  oMSNewGe1:bLine := {||{ aColsEx[oMSNewGe1:nAt,01],;
                          aColsEx[oMSNewGe1:nAt,02],;
                          aColsEx[oMSNewGe1:nAt,03],;
                          aColsEx[oMSNewGe1:nAt,04],;                          
                          aColsEx[oMSNewGe1:nAT,05],;
                          Transform(aColsEx[oMSNewGe1:nAT,06],PesqPict("SB2","B2_QATU"))} }
  
Return 


Static Function FPesProd(cGetPesq)

Local cQuery := "" 

aColsEx := {}

cQuery := "SELECT B1_COD, B1_DESC, B1_UM, B1_GRUPO, B1_POSIPI, "
cQuery += "(SELECT B2_QATU FROM " + RetSqlName("SB2") + " WHERE D_E_L_E_T_ <> '*' AND "
cQuery += "B2_FILIAL = '" + xFilial("SB2") + "' AND "
cQuery += "B2_COD = B1_COD AND B2_LOCAL = B1_LOCPAD) AS B2_QATU "
cQuery += "FROM " + RetSqlName("SB1") + " WHERE D_E_L_E_T_ <> '*' AND "
cQuery += "B1_MSBLQL <> '1' AND "
cQuery += "B1_FILIAL = '" + xFilial("SB1") + "' AND "
cQuery += "B1_DESC LIKE '"+AllTrim(Upper(cGetPesq))+"%' "
cQuery += "ORDER BY B1_DESC "

TcQuery cQuery Alias "TRB" New 

dbSelectArea("TRB")
dbGoTop() 
While !Eof() 
    AADD(aColsEx,{TRB->B1_COD,TRB->B1_UM,TRB->B1_GRUPO,TRB->B1_POSIPI,TRB->B1_DESC,TRB->B2_QATU})
    dbSelectArea("TRB")
    dbSkip()
EndDo 

dbSelectArea("TRB")
dbCloseArea()


cQuery := "SELECT B1_COD, B1_DESC, B1_UM, B1_GRUPO, B1_POSIPI, "
cQuery += "(SELECT B2_QATU FROM " + RetSqlName("SB2") + " WHERE D_E_L_E_T_ <> '*' AND "
cQuery += "B2_FILIAL = '" + xFilial("SB2") + "' AND "
cQuery += "B2_COD = B1_COD AND B2_LOCAL = B1_LOCPAD) AS B2_QATU "
cQuery += "FROM " + RetSqlName("SB1") + " WHERE D_E_L_E_T_ <> '*' AND "
cQuery += "B1_MSBLQL <> '1' AND "
cQuery += "B1_FILIAL = '" + xFilial("SB1") + "' AND "
cQuery += "B1_DESC LIKE '%"+AllTrim(Upper(cGetPesq))+"%' AND "
cQuery += "B1_DESC NOT LIKE '"+AllTrim(Upper(cGetPesq))+"%' "
cQuery += "ORDER BY B1_DESC "

TcQuery cQuery Alias "TRC" New 

dbSelectArea("TRC")
dbGoTop() 
While !Eof() 
    AADD(aColsEx,{TRC->B1_COD,TRC->B1_UM,TRC->B1_GRUPO,TRC->B1_POSIPI,TRC->B1_DESC,TRC->B2_QATU})
    dbSelectArea("TRC")
    dbSkip()
EndDo 

dbSelectArea("TRC")
dbCloseArea()



oMSNewGe1:SetArray(aColsEx)

oMSNewGe1:bLine := {||{ aColsEx[oMSNewGe1:nAt,01],;
                          aColsEx[oMSNewGe1:nAt,02],;
                          aColsEx[oMSNewGe1:nAt,03],;
                          aColsEx[oMSNewGe1:nAt,04],;                          
                          aColsEx[oMSNewGe1:nAT,05],;
                          Transform(aColsEx[oMSNewGe1:nAT,06],PesqPict("SB2","B2_QATU"))} }                          

oMSNewGe1:Refresh() 

Return 



Static Function FGravDados(cDescProd,cPart,cLink,cUM,cUrg,cAplic,cMotivo) 

Local cCodId := Space(06)

cUrg:= if(empty(cUrg),'S',cUrg)

If Empty(cDescProd)
   MsgStop("A descrição do produto é obrigatória!")
   Return 
EndIf 

If Empty(cUM)
   MsgStop("A unidade de medida é obrigatória!")
   Return 
EndIf 

If Empty(cPart) .And. Empty(cLink)
   MsgStop("Informe o Part Number ou o link de referência!")
   Return 
EndIf 

If Empty(cAPlic)
   MsgStop("A aplicação é obrigatória!")
   Return 
EndIf 

If 'S' $ cUrg .And. Empty(cMotivo)
   MsgStop("Se cadastro for urgente o motivo é obrigatório!")
   Return 
EndIf 

If 'S' $ cUrg .And. !Empty(cMotivo) .And. Len(AllTrim(cMotivo)) <= 10 
   MsgStop("Por favor, detalhe melhor o motivo da urgência!")
   Return 
EndIf 

oDlg:End()


cCodId := FSEQSZ3()

dbSelectArea("SZ3")
dbSetOrder(01)
If Reclock("SZ3",.T.)
   Replace Z3_FILIAL With xFilial("SZ3")
   Replace Z3_ID     With cCodId
   Replace Z3_PN     With UPPER(cPart) 
   Replace Z3_LINK   With cLink 
   Replace Z3_UM     With UPPER(cUM) 
   Replace Z3_DESCRI With UPPER(cDescProd) 
   Replace Z3_STATUS With '0'
   Replace Z3_PRAZO  With cUrg
   Replace Z3_APLIC  With UPPER(cAplic) 
   Replace Z3_USR    With Substr(cUsuario,7,15)
   Replace Z3_IDUSR  With __cUserId
   Replace Z3_ZDTSOL With dDataBase 
   If 'S' $ cUrg  
      Replace Z3_MOTIVO With cMotivo
   EndIf 
   MsUnlock() 
EndIf 
   
Return 

Static Function FSEQSZ3() 


Local cNumSZ3 := Space(01) 
Local cMayUse := '' 
Local cQuery  := "" 


cQuery := " "

//Busca sequencial do proximo cliente 
dbSelectArea("SZ3")
dbSetOrder(1)
cNumSZ3 := '000001' 
cMayUse := "SZ3" + AllTrim(xFilial("SZ3")) + cNumSZ3
		
While (MsSeek(xFilial("SZ3") + cNumSZ3)) .Or. (! MayIUseCode(cMayUse))
	cNumSZ3 := Soma1(cNumSZ3, Len(cNumSZ3))
	cMayUse := "SZ3" + AllTrim(xFilial("SZ3")) + cNumSZ3
EndDo
		
If __lSX8
	ConfirmSX8()
Endif


Return(cNumSZ3) 



User Function CADLESV2() 

BRWLEGENDA("Solicitacao Cadastral","Legenda",{{"BR_BRANCO"   ,"Solicitação aguardando cadastro de produtos."},;
                                                                          {"DISABLE"  ,"Produto cadastrado."},;
                                                                          {"BR_PRETO"  ,"Solicitação rejeitada."}})
Return 

