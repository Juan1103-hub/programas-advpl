#include "protheus.ch"
#Include "TopConn.ch"

//--------------------------------------------------------------
/*/{Protheus.doc} FAMAPROD

Visualizar o pedido de cadastro de pre-cadastro e aprovar/rejeitar o
pedido de cadastro. 

@param 
@return 
@author  
@since 

08/03/2024

/*/
//--------------------------------------------------------------

User Function FAMAPROD()

Local cQuery := ''
Local oOK   := LoadBitmap(GetResources(),'br_verde')
Local oNO   := LoadBitmap(GetResources(),'br_vermelho')
Local oSayLeg 
Local aBrowse := {} 
Local cSayLeg := "Legenda: Verde - Aprovado / Vermelho - Rejeitado"
Private oBrowse 
Private oDlg 
Private nSelFam := 0

Public cVortId := Space(06)

cQuery := "SELECT * FROM " + RetSqlName("SZ3") + " WHERE D_E_L_E_T_ <> '*' AND "
cQuery += "Z3_STATUS = '0' "
cQuery += "ORDER BY Z3_PRAZO DESC"

TcQuery cQuery Alias "TRB" New 

dbSelectArea("TRB")
dbGoTop() 
While !Eof() 

  AADD(aBrowse,{.T.,TRB->Z3_ID,IIF(TRB->Z3_PRAZO=='S','URGENTE','NORMAL'),TRB->Z3_DESCRI,TRB->Z3_UM,TRB->Z3_PN,TRB->Z3_LINK})

  dbSelectArea("TRB")  
  dbSkip()
EndDo 

dbSelectArea("TRB")
dbCloseArea() 


  DEFINE MSDIALOG oDlg TITLE "Solicitação Cadastral" FROM 000, 000  TO 550, 1300 COLORS 0, 16777215 PIXEL
	                 
    // Cria Browse
    oBrowse := TCBrowse():New( 008 , 009, 633, 232,,;
                              {'','id','Prazo','Descrição','UM','PartNumber','Link'},{20,50,50,120,20,150,254},;
                              oDlg,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
    // Seta vetor para a browse                            
    oBrowse:SetArray(aBrowse) 
    
    // Monta a linha a ser exibida no Browse
    // O browse avalia a bLine mesmo com o vetor vazio (nAt = 1), por isso a
    // montagem da linha fica num bloco com guarda de limite.
    oBrowse:bLine := {|| FBlocoFam(aBrowse, oBrowse:nAt, oOK, oNO) }

    // O objeto do browse e destruido quando a janela fecha (o X nao passa por
    // botao), por isso a linha corrente e guardada a cada troca de registro.
    oBrowse:bChange := {|| nSelFam := oBrowse:nAt }

    If Len(aBrowse) > 0
        nSelFam := 1
    EndIf


      @ 250,015 SAY oSayLeg PROMPT cSayLeg SIZE 206, 010 OF oDlg COLORS 0, 16777215 PIXEL

    // Evento de duplo click na celula
    oBrowse:bLDblClick   := {|| FDuploClick(aBrowse) }
    
    // Mesma regra do botao Verificar Duplicidade, agora sobre todas as
    // solicitacoes pendentes de uma vez.
    TButton():New( 252, 565, "Verificar Cadastros", oDlg,{|| U_CADVERZ3() },;
     65,010,,,.F.,.T.,.F.,,.F.,,,.F. )


    
  ACTIVATE DIALOG oDlg CENTERED

  // A janela fecha pelo X do titulo: a solicitacao escolhida e resolvida aqui.
  FFechaTela(aBrowse) 


Return(.T.) 


/*/{Protheus.doc} FBlocoFam
Monta a linha exibida na browse de solicitações cadastrais com guarda de limite.

A browse avalia a bLine mesmo com o vetor vazio (nAt = 1), o que gerava
'array out of bounds ( 1 of 0 )' quando não havia solicitação pendente.

@param aLinhas Vetor de solicitações carregado do SZ3.
@param nAt     Posição corrente da browse.
@param oOk     Bitmap de aprovado.
@param oNo     Bitmap de rejeitado.
@return aLinha Linha pronta para a browse, ou linha vazia quando a posição não existe.
@type    Static Function
@author  Suprimentos
@since   30/10/2026
/*/
//-------------------------------------------------------------------
Static Function FBlocoFam(aLinhas, nAt, oOk, oNo)

    Local aLinha := {'', '', '', '', '', '', ''}
    Local aIcone := oNo

    If nAt >= 1 .And. nAt <= Len(aLinhas)
        If aLinhas[nAt,01]
            aIcone := oOk
        EndIf

        aLinha := { aIcone,;
                    aLinhas[nAt,02],;
                    aLinhas[nAt,03],;
                    aLinhas[nAt,04],;
                    aLinhas[nAt,05],;
                    aLinhas[nAt,06],;
                    aLinhas[nAt,07] }
    EndIf

Return aLinha


Static Function FFechaTela(aBrowse) 

Local lAprov := .T.
Local nAt    := nSelFam

cVortId := Space(06)

If nAt >= 1 .And. nAt <= Len(aBrowse)
   lAprov := aBrowse[nAt][1]
   If lAprov
      cVortId := aBrowse[nAt][2]
   EndIf
EndIf

If !lAprov
   MsgInfo("Solicitação de cadastro rejeitada não pode ser cadastrada!")
   cVortId := Space(06)
EndIf

Return



Static Function FDuploClick(aBrowse)
Local cValColun := .F.
Local oDlgMemo, oMemo, cMemo:= space(300) 

If oBrowse:nAt < 1 .Or. oBrowse:nAt > Len(aBrowse)
   Return
EndIf

// A linha com que o usuario acabou de interagir e a que sera lida no
// fechamento da janela.
nSelFam := oBrowse:nAt

cValColun := aBrowse[oBrowse:nAt][1]

If cValColun == .T. 


   If MsgYesNo("Deseja rejeitar a solicitação de cadastro? Sim/Não")

      DEFINE MSDIALOG oDlgMemo TITLE "Motivo da Rejeição" FROM 000, 000  TO 300, 500 COLORS 0, 16777215 PIXEL
      oMemo:= tMultiget():New(10,10,{|u|if(Pcount()>0,cMemo:=u,cMemo)};
      ,oDlgMemo,230,120,,,,,,.T.)
      @ 133,160 BUTTON oBtn PROMPT "Salvar" OF oDlgMemo PIXEL ACTION oDlgMemo:End()
      ACTIVATE MSDIALOG oDlgMemo CENTERED

      aBrowse[oBrowse:nAt][1] := .F. 

      dbSelectArea("SZ3")
      dbSetOrder(01)
      If dbSeek(xFilial("SZ3")+aBrowse[oBrowse:nAt][2])
          If Reclock("SZ3",.F.)
             Replace Z3_OBS    With AllTrim(cMemo) 
             Replace Z3_STATUS With '2'
             MsUnlock() 
          EndIf
          u_CNTCOM01("R")
      EndIf   
   EndIf 
    
Else 

   If MsgYesNo("Deseja reativar a solicitação de cadastro? Sim/Não")

      dbSelectArea("SZ3")
      dbSetOrder(01)
      If dbSeek(xFilial("SZ3")+aBrowse[oBrowse:nAt][2])
         If Reclock("SZ3",.F.)
            Replace Z3_OBS With Space(01)
            Replace Z3_STATUS With '0'           
            MsUnlock() 
         EndIf 
      EndIf   

      aBrowse[oBrowse:nAt][1] := .T.     
   EndIf       
EndIf 

oBrowse:Refresh() 

Return 
