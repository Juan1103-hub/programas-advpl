#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} ZADTASK
Cadastro de Solicitações de Tarefas - Sem Dicionário
@type function
@author Seu Nome
@since 23/01/2026
/*/
User Function ZADTASK()
    Local aArea    := GetArea()
    Local aCoors   := FWGetDialogSize(oMainWnd)
    Local oView    := ViewDef()
    Local oDlg     := Nil
    
    // Cria a dialog
    DEFINE MSDIALOG oDlg TITLE "Cadastro de Solicitação de Tarefa" FROM aCoors[1],aCoors[2] TO aCoors[3],aCoors[4] PIXEL
    
    // Renderiza a view dentro da dialog
    oView:SetOwner(oDlg)
    oView:Activate()
    
    ACTIVATE MSDIALOG oDlg CENTERED
    
    RestArea(aArea)
    
Return

/*/{Protheus.doc} ModelDef
Modelo de Dados - Estrutura Manual
@return oModel - Objeto do modelo
/*/
Static Function ModelDef()
    Local oStruct := GetModelStruct()
    Local oModel  := MPFormModel():New("ZADTASKM", /*bPreValid*/, {|oModel| ValidForm(oModel)}, /*bCommit*/, /*bCancel*/)
    Local bLoad   := {|oFieldModel, lCopy| LoadField(oFieldModel, lCopy)}
    
    // Adiciona o formulário com a estrutura criada manualmente
    oModel:AddFields("ZADMASTER", /*cOwner*/, oStruct, /*bPreValid*/, /*bPosValid*/, bLoad)
    
    // Descrições
    oModel:SetDescription("Modelo de Solicitação de Tarefa")
    oModel:GetModel("ZADMASTER"):SetDescription("Dados da Solicitação")
    
Return oModel

/*/{Protheus.doc} ViewDef
Interface/Visualização - Estrutura Manual
@return oView - Objeto da view
/*/
Static Function ViewDef()
    Local oModel  := ModelDef()
    Local oStruct := GetViewStruct()
    Local oView   := FWFormView():New()
    
    // Define o modelo de dados
    oView:SetModel(oModel)
    
    // Adiciona o formulário
    oView:AddField("VIEW_ZAD", oStruct, "ZADMASTER")
    
    // Layout - criando divisões
    oView:CreateHorizontalBox("SUPERIOR", 70)
    oView:CreateHorizontalBox("INFERIOR", 30)
    
    // Relaciona os campos com as áreas
    oView:SetOwnerView("VIEW_ZAD", "SUPERIOR")
    
    // Título
    oView:EnableTitleView("VIEW_ZAD", "Solicitação de Tarefa")
    
    // Adiciona botões personalizados
    oView:AddUserButton("Gravar", "SALVAR", {|| GravarDados(oModel)})
    oView:AddUserButton("Limpar", "LIMPAR", {|| LimparForm(oModel)})
    
Return oView

/*/{Protheus.doc} GetModelStruct
Cria estrutura do Model manualmente
@return oStruct - Estrutura de campos
/*/
Static Function GetModelStruct()
    Local oStruct := FWFormModelStruct():New()
    
    // AddField(cTitulo, cTooltip, cIdField, cTipo, nTamanho, nDecimal, bValid, bWhen, aValues, lObrigat, bInit, lKey, lNoUpd, lVirtual, cValid)
    
    oStruct:AddField("Código"          , "Código da Solicitação"  , "CODIGO"  , "C", 6 , 0, /*valid*/, /*when*/, {}, .T., {|| "000001"}, .T., .F., .F.)
    oStruct:AddField("Descrição"       , "Descrição da Tarefa"    , "DESCRI"  , "C", 100, 0, /*valid*/, /*when*/, {}, .T., /*init*/, .F., .F., .F.)
    oStruct:AddField("Solicitante"     , "Nome do Solicitante"    , "SOLICI"  , "C", 50 , 0, /*valid*/, /*when*/, {}, .T., {|| cUserName}, .F., .F., .F.)
    oStruct:AddField("Prioridade"      , "Prioridade da Tarefa"   , "PRIORI"  , "C", 1  , 0, /*valid*/, /*when*/, {"1=Baixa","2=Média","3=Alta"}, .T., {|| "2"}, .F., .F., .F.)
    oStruct:AddField("Status"          , "Status da Solicitação"  , "STATUS"  , "C", 1  , 0, /*valid*/, /*when*/, {"1=Pendente","2=Em Andamento","3=Concluída","4=Cancelada"}, .T., {|| "1"}, .F., .F., .F.)
    oStruct:AddField("Data Solicitação", "Data da Solicitação"    , "DTSOLI"  , "D", 8  , 0, /*valid*/, /*when*/, {}, .T., {|| Date()}, .F., .F., .F.)
    oStruct:AddField("Data Prevista"   , "Data Prevista Conclusão", "DTPREV"  , "D", 8  , 0, /*valid*/, /*when*/, {}, .F., /*init*/, .F., .F., .F.)
    oStruct:AddField("Data Conclusão"  , "Data de Conclusão"      , "DTCONC"  , "D", 8  , 0, /*valid*/, /*when*/, {}, .F., /*init*/, .F., .F., .F.)
    oStruct:AddField("Responsável"     , "Responsável pela Tarefa", "RESPON"  , "C", 50 , 0, /*valid*/, /*when*/, {}, .F., /*init*/, .F., .F., .F.)
    oStruct:AddField("Observações"     , "Observações Gerais"     , "OBSERV"  , "M", 10 , 0, /*valid*/, /*when*/, {}, .F., /*init*/, .F., .F., .F.)
    
Return oStruct

/*/{Protheus.doc} GetViewStruct
Cria estrutura da View manualmente
@return oStruct - Estrutura visual
/*/
Static Function GetViewStruct()
    Local oStruct := FWFormViewStruct():New()
    
    // AddField(cIdField, cOrdem, cTitulo, cDescric, aHelp, cType, cPict, bPictVar, cLookUp, lCanChange, cFolder, cGroup, aComboValues, nMaxLenCombo, cIniBrow, lVirtual, cPictVar, lInsertLine)
    
    oStruct:AddField("CODIGO" , "01", "Código"          , "Código"          , {}, "C", "@!", /*pictvar*/, /*lookup*/, .F.)
    oStruct:AddField("DESCRI" , "02", "Descrição"       , "Descrição"       , {}, "C", "@!", /*pictvar*/, /*lookup*/, .T.)
    oStruct:AddField("SOLICI" , "03", "Solicitante"     , "Solicitante"     , {}, "C", "@!", /*pictvar*/, /*lookup*/, .T.)
    oStruct:AddField("PRIORI" , "04", "Prioridade"      , "Prioridade"      , {}, "C", "@!", /*pictvar*/, /*lookup*/, .T.)
    oStruct:AddField("STATUS" , "05", "Status"          , "Status"          , {}, "C", "@!", /*pictvar*/, /*lookup*/, .T.)
    oStruct:AddField("DTSOLI" , "06", "Dt.Solicitação"  , "Data Solicitação", {}, "D", "@D", /*pictvar*/, /*lookup*/, .T.)
    oStruct:AddField("DTPREV" , "07", "Dt.Prevista"     , "Data Prevista"   , {}, "D", "@D", /*pictvar*/, /*lookup*/, .T.)
    oStruct:AddField("DTCONC" , "08", "Dt.Conclusão"    , "Data Conclusão"  , {}, "D", "@D", /*pictvar*/, /*lookup*/, .T.)
    oStruct:AddField("RESPON" , "09", "Responsável"     , "Responsável"     , {}, "C", "@!", /*pictvar*/, /*lookup*/, .T.)
    oStruct:AddField("OBSERV" , "10", "Observações"     , "Observações"     , {}, "M", "@!", /*pictvar*/, /*lookup*/, .T.)
    
Return oStruct

/*/{Protheus.doc} LoadField
Carrega os dados iniciais no formulário
@return aLoad - Array com os dados
/*/
Static Function LoadField(oFieldModel, lCopy)
    Local aLoad := {}
    
    // Estrutura: {valor campo1, valor campo2, ...}, recno
    aAdd(aLoad, {;
        Space(6),;      // CODIGO
        Space(100),;    // DESCRI
        cUserName,;     // SOLICI
        "2",;           // PRIORI - Média
        "1",;           // STATUS - Pendente
        Date(),;        // DTSOLI
        CtoD("  /  /  "),; // DTPREV
        CtoD("  /  /  "),; // DTCONC
        Space(50),;     // RESPON
        ""})            // OBSERV
    
    aAdd(aLoad, 0) // Recno fictício
    
Return aLoad

/*/{Protheus.doc} ValidForm
Validação ao confirmar o formulário
@return lRet - .T. se válido
/*/
Static Function ValidForm(oModel)
    Local lRet    := .T.
    Local cDescri := oModel:GetValue("ZADMASTER", "DESCRI")
    Local cStatus := oModel:GetValue("ZADMASTER", "STATUS")
    Local dDtConc := oModel:GetValue("ZADMASTER", "DTCONC")
    
    If Empty(cDescri)
        Help(,, "ATENÇÃO",, "A descrição da tarefa é obrigatória!", 1, 0)
        lRet := .F.
    EndIf
    
    If lRet .And. cStatus == "3" .And. Empty(dDtConc)
        Help(,, "ATENÇÃO",, "Para marcar como concluída, informe a data de conclusão!", 1, 0)
        lRet := .F.
    EndIf
    
Return lRet

/*/{Protheus.doc} GravarDados
Simula gravação dos dados (exibe mensagem)
/*/
Static Function GravarDados(oModel)
    Local cMsg := ""
    
    If oModel:VldData()
        cMsg := "Dados da Solicitação:" + CRLF + CRLF
        cMsg += "Código: " + oModel:GetValue("ZADMASTER", "CODIGO") + CRLF
        cMsg += "Descrição: " + AllTrim(oModel:GetValue("ZADMASTER", "DESCRI")) + CRLF
        cMsg += "Solicitante: " + AllTrim(oModel:GetValue("ZADMASTER", "SOLICI")) + CRLF
        cMsg += "Status: " + oModel:GetValue("ZADMASTER", "STATUS") + CRLF
        
        MsgInfo(cMsg, "Simulação de Gravação")
    EndIf
    
Return

/*/{Protheus.doc} LimparForm
Limpa o formulário
/*/
Static Function LimparForm(oModel)
    oModel:DeActivate()
    oModel:Activate()
Return
