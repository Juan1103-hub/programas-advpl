#Include "Protheus.ch"
#Include "TopConn.ch"

// Arrays estaticos de dados
Static aLeadData    := {}   // {cCodComp,cNomeComp,cNumPC,dDtPC,cNumSC,dDtSC,dDtNF,nDiasScPc,nDiasPcNf,nDiasScNf,dDtEntrada,nDiasNfEnt,dDtClassif,nDiasPnCl,dDtApro,nDiasEmApro,dDtNecess,nDiasNecPn}
Static aLeadMedia   := {}   // {cCodComp,cNomeComp,nQtdPC,nQtdComSC,nSomaSCPC,nQtdComNF,nSomaPCNF,nSomaScNf,nQtdScNf,nQtdNfEnt,nSomaNfEnt,nQtdPnCl,nSomaPnCl,nQtdComApro,nSomaEmApro,nQtdNecPn,nSomaNecPn}
Static aLeadDisp    := {}   // Array filtrado para exibicao na tela
Static cLeadFiltPC  := ""   // Filtro atual de N.PC

/*/{Protheus.doc} ZLEADTIME
Lead Time dos Compradores - Analise de Tempo de Atendimento
Calcula e exibe:
  - Dias entre a data da Solicitacao de Compra (SC1) e a geracao do Pedido de Compra (SC7)
  - Dias entre a Aprovacao do Pedido de Compra e a entrada da Pre-Nota (SD1)
Agrupa por comprador com media de atendimento.
@type User Function
@author Desenvolvimento
@since 09/04/2026
/*/
User Function ZLEADTIME()
    Local aPar      := {}
    Local aRet      := {}
    Local aUsers    := {}
    Local aUserCods := {}
    Local nIdx      := 1
    Local dDtDe     := CtoD("")
    Local dDtAte    := Date()

    CarregaCompLT(@aUsers, @aUserCods)

    aAdd(aPar, {1, "Data Inicial", dDtDe,  "", "", "", "", 60, .T.})
    aAdd(aPar, {1, "Data Final",   dDtAte, "", "", "", "", 60, .T.})
    aAdd(aPar, {2, "Comprador",    1, aUsers, 80, "", .F.})

    If !ParamBox(aPar, "Lead Time dos Compradores", @aRet)
        Return
    EndIf

    dDtDe  := aRet[1]
    dDtAte := aRet[2]
    nIdx   := IIF(ValType(aRet[3]) == "N", aRet[3], ;
                  aScan(aUsers, {|x| AllTrim(x) == AllTrim(cValToChar(aRet[3]))}))
    nIdx   := Max(1, Min(nIdx, Len(aUsers)))

    If Empty(dDtDe) .Or. Empty(dDtAte)
        MsgAlert("Informe o periodo completo!", "Atencao")
        Return
    EndIf

    If dDtAte < dDtDe
        MsgAlert("Data Final nao pode ser anterior a Data Inicial!", "Atencao")
        Return
    EndIf

    ConsultaLT(dDtDe, dDtAte, aUserCods[nIdx], aUsers[nIdx])
Return

/*/{Protheus.doc} CarregaCompLT
Carrega lista de compradores que possuem Pedidos de Compra no SC7.
Adiciona opcao "Todos os Compradores" como primeiro item.
@type Static Function
@param aUsers, Array de descricoes para o combo
@param aUserCods, Array de codigos paralelo a aUsers
/*/
Static Function CarregaCompLT(aUsers, aUserCods)
    Local cAlias := GetNextAlias()
    Local cCod   := ""
    Local cNome  := ""

    aUsers    := {"** Todos os Compradores **"}
    aUserCods := {"*"}

    BeginSql Alias cAlias
        SELECT DISTINCT C7_USER
        FROM %Table:SC7%
        WHERE %NotDel%
          AND C7_FILIAL = %xFilial:SC7%
          AND C7_USER   <> ' '
          AND C7_QUANT  > 0
        ORDER BY C7_USER
    EndSql

    While !(cAlias)->(Eof())
        cCod  := AllTrim((cAlias)->C7_USER)
        cNome := AllTrim(UsrRetName(cCod))
        If Empty(cNome)
            cNome := cCod
        EndIf
        If "ISABELA" $ Upper(cNome)
            (cAlias)->(DbSkip())
            Loop
        EndIf
        aAdd(aUsers,    cCod + " - " + cNome)
        aAdd(aUserCods, cCod)
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())
Return

/*/{Protheus.doc} ConsultaLT
Executa query SQL unindo SC7 (Pedido de Compra), SC1 (Solicitacao de Compra)
e SD1 (Pre-Nota de Entrada). Calcula dias entre cada etapa do processo.
Popula aLeadData e aLeadMedia para exibicao.
@type Static Function
@param dDtDe, Data inicial do filtro (baseado em C7_EMISSAO)
@param dDtAte, Data final do filtro
@param cCodUsr, Codigo do comprador ou "*" para todos
@param cNomeUsr, Descricao do comprador para titulo da tela
/*/
Static Function ConsultaLT(dDtDe, dDtAte, cCodUsr, cNomeUsr)

    Local cAlias        := GetNextAlias()
    Local cQuery        := ""
    Local cSC7          := RetSqlName("SC7")
    Local cSC1          := RetSqlName("SC1")
    Local cSD1          := RetSqlName("SD1")
    Local cSF1          := RetSqlName("SF1")
    Local cFil7         := xFilial("SC7")
    Local cFil1         := xFilial("SC1")
    Local cFilD1        := xFilial("SD1")
    Local cFilF1        := xFilial("SF1")
    Local cFiltUser     := ""
    Local cCodComp      := ""
    Local cNomeComp     := ""
    Local cNumPC        := ""
    Local cNumSC        := ""
    Local dDtPC         := CtoD("")
    Local dDtSC         := CtoD("")
    Local dDtNF         := CtoD("")
    Local nDiasScPc     := 0
    Local nDiasPcNf     := 0
    Local nDiasScNf     := 0
    Local nDiasNfEnt    := 0
    Local nDiasPnCl     := 0
    Local dDtEntrada    := CtoD("")
    Local dDtClassif    := CtoD("")
    Local dDtApro       := CtoD("")
    Local nDiasEmApro   := 0
    Local dDtNecess     := CtoD("")
    Local nDiasNecPn    := 0
    Local cChk          := ""
    Local cAliasMeta    := ""
    Local cCol          := ""
    Local cTbl          := ""
    Local lHasC7Datapro := .F.
    Local lHasCrDatalib := .F.
    Local cAproField    := ""
    Local cTabName      := cSC7
    Local cSCR          := RetSqlName("SCR")
    Local cScrTabName   := cSCR

    aLeadData  := {}
    aLeadMedia := {}

    If cCodUsr == "*"
        cFiltUser := "1 = 1"
    Else
        cFiltUser := "LTRIM(RTRIM(SC7.C7_USER)) = '" + cCodUsr + "'"
    EndIf

    // Remove schema/qualificador, se houver
    If At(".", cTabName) > 0
        cTabName := SubStr(cTabName, At(".", cTabName) + 1)
    EndIf
    cTabName := StrTran(cTabName, "[", "")
    cTabName := StrTran(cTabName, "]", "")

    If At(".", cScrTabName) > 0
        cScrTabName := SubStr(cScrTabName, At(".", cScrTabName) + 1)
    EndIf
    cScrTabName := StrTran(cScrTabName, "[", "")
    cScrTabName := StrTran(cScrTabName, "]", "")

    // Consulta metadados (INFORMATION_SCHEMA) - compativel com MSSQL
    cChk := "SELECT TABLE_NAME, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS " + ;
            "WHERE (TABLE_NAME = '" + cTabName + "' AND COLUMN_NAME = 'C7_DATAPRO') " + ;
            "OR (TABLE_NAME = '" + cScrTabName + "' AND COLUMN_NAME = 'CR_DATALIB')"
    cChk := ChangeQuery(cChk)

    cAliasMeta := GetNextAlias()
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cChk), cAliasMeta, .F., .T.)

    While !(cAliasMeta)->(Eof())
        cCol := AllTrim((cAliasMeta)->COLUMN_NAME)
        cTbl := AllTrim((cAliasMeta)->TABLE_NAME)
        If cCol == "C7_DATAPRO" .And. cTbl == cTabName
            lHasC7Datapro := .T.
        ElseIf cCol == "CR_DATALIB" .And. cTbl == cScrTabName
            lHasCrDatalib := .T.
        EndIf
        (cAliasMeta)->(DbSkip())
    EndDo
    (cAliasMeta)->(DbCloseArea())

    If lHasC7Datapro
        cAproField := "   MIN(SC7.C7_DATAPRO)   AS DT_APRO"
    ElseIf lHasCrDatalib
        cAproField := "   MAX(SCR.CR_DATALIB)   AS DT_APRO"
    Else
        cAproField := "   ''                    AS DT_APRO"
    EndIf

    cQuery  := " SELECT"
    cQuery  += "   LTRIM(RTRIM(SC7.C7_USER))    AS COMP,"
    cQuery  += "   LTRIM(RTRIM(SC7.C7_NUM))     AS NUM_PC,"
    cQuery  += "   SC7.C7_EMISSAO               AS DT_PC,"
    cQuery  += "   LTRIM(RTRIM(SC7.C7_NUMSC))   AS NUM_SC,"
    cQuery  += "   MIN(SC1.C1_EMISSAO)          AS DT_SC,"
    cQuery  += "   MIN(NF.DT_DIGITA)            AS DT_NF,"
    cQuery  += "   MIN(NF.DT_ENTRADA)           AS DT_ENT,"
    cQuery  += "   MIN(NF.DT_CLASSIF)           AS DT_CLASSIF,"
    cQuery  += "   MIN(SC1.C1_DATPRF)           AS DT_NECESS,"
    cQuery  += cAproField
    cQuery  += " FROM " + cSC7 + " SC7"
    cQuery  += " LEFT JOIN " + cSC1 + " SC1"
    cQuery  += "   ON LTRIM(RTRIM(SC1.C1_FILIAL)) = LTRIM(RTRIM(SC7.C7_FILIAL))"
    cQuery  += "   AND LTRIM(RTRIM(SC1.C1_NUM))   = LTRIM(RTRIM(SC7.C7_NUMSC))"
    cQuery  += "   AND SC1.D_E_L_E_T_             = ' '"
    cQuery  += " LEFT JOIN ("
    cQuery  += "   SELECT LTRIM(RTRIM(SD1.D1_PEDIDO)) AS D1_PED,"
    cQuery  += "          MIN(SD1.D1_DTDIGIT)          AS DT_DIGITA,"
    cQuery  += "          MIN(SF1.F1_RECBMTO)          AS DT_ENTRADA,"
    cQuery  += "          MIN(SF1.F1_DTDIGIT)          AS DT_CLASSIF"
    cQuery  += "   FROM " + cSD1 + " SD1"
    cQuery  += "   LEFT JOIN " + cSF1 + " SF1"
    cQuery  += "     ON SF1.D_E_L_E_T_ = ' '"
    cQuery  += "     AND LTRIM(RTRIM(SF1.F1_FILIAL)) = LTRIM(RTRIM(SD1.D1_FILIAL))"
    cQuery  += "     AND SF1.F1_DOC     = SD1.D1_DOC"
    cQuery  += "     AND SF1.F1_SERIE   = SD1.D1_SERIE"
    cQuery  += "     AND SF1.F1_FORNECE = SD1.D1_FORNECE"
    cQuery  += "     AND SF1.F1_LOJA    = SD1.D1_LOJA"
    cQuery  += "   WHERE SD1.D_E_L_E_T_ = ' '"
    cQuery  += "   GROUP BY LTRIM(RTRIM(SD1.D1_PEDIDO))"
    cQuery  += " ) NF ON NF.D1_PED = LTRIM(RTRIM(SC7.C7_NUM))"
    If lHasCrDatalib
        cQuery += " LEFT JOIN " + cSCR + " SCR"
        cQuery += "   ON SCR.CR_NUM    = LTRIM(RTRIM(SC7.C7_NUM))"
        cQuery += "   AND SCR.CR_FILIAL = LTRIM(RTRIM(SC7.C7_FILIAL))"
        cQuery += "   AND SCR.CR_TIPO   = 'IP'"
        cQuery += "   AND SCR.CR_STATUS = '03'"
        cQuery += "   AND SCR.D_E_L_E_T_ = ' '"
    EndIf
    cQuery  += " WHERE SC7.D_E_L_E_T_ = ' '"
    cQuery  += "   AND LTRIM(RTRIM(SC7.C7_FILIAL)) = '" + cFil7 + "'"
    cQuery  += "   AND SC7.C7_EMISSAO BETWEEN '" + DtoS(dDtDe) + "' AND '" + DtoS(dDtAte) + "'"
    cQuery  += "   AND SC7.C7_RESIDUO <> 'S'"
    cQuery  += "   AND SC7.C7_QUANT   >  0"
    cQuery  += "   AND " + cFiltUser
    cQuery  += " GROUP BY SC7.C7_USER, SC7.C7_NUM, SC7.C7_EMISSAO, SC7.C7_NUMSC"
    cQuery  += " ORDER BY SC7.C7_USER, SC7.C7_EMISSAO, SC7.C7_NUM"

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    If (cAlias)->(Eof())
        (cAlias)->(DbCloseArea())
        MsgAlert("Nenhum Pedido de Compra encontrado no periodo informado!", "Atencao")
        Return
    EndIf

    While !(cAlias)->(Eof())
        cCodComp  := AllTrim((cAlias)->COMP)
        cNomeComp := AllTrim(UsrRetName(cCodComp))
        If Empty(cNomeComp)
            cNomeComp := cCodComp
        EndIf

        If "ISABELA" $ Upper(cNomeComp)
            (cAlias)->(DbSkip())
            Loop
        EndIf

        cNumPC := AllTrim((cAlias)->NUM_PC)
        cNumSC := AllTrim((cAlias)->NUM_SC)

        dDtPC      := StoD((cAlias)->DT_PC)
        dDtSC      := StoD(AllTrim(cValToChar((cAlias)->DT_SC)))
        dDtNF      := StoD(AllTrim(cValToChar((cAlias)->DT_NF)))
        dDtEntrada := StoD(AllTrim(cValToChar((cAlias)->DT_ENT)))
        dDtClassif := StoD(AllTrim(cValToChar((cAlias)->DT_CLASSIF)))
        dDtApro   := StoD(AllTrim(cValToChar((cAlias)->DT_APRO)))
        dDtNecess := StoD(AllTrim(cValToChar((cAlias)->DT_NECESS)))

        // Dias SC -> PC: dias uteis; -1 se nao houver SC vinculada
        nDiasScPc := IIF(!Empty(dDtPC) .And. !Empty(dDtSC) .And. dDtPC >= dDtSC, ;
                         DiasUteis(dDtSC, dDtPC), -1)

        // Dias Aprov -> Pre-Nota: dias uteis APOS a aprovacao ate a entrada da Pre-Nota
        // Aprovacao 12/01 + Pre-Nota 13/01 = 1 dia (conta a partir do dia seguinte a aprovacao)
        nDiasPcNf := IIF(!Empty(dDtEntrada) .And. !Empty(dDtApro) .And. dDtEntrada >= dDtApro, ;
                         DiasUteis(dDtApro, dDtEntrada), -1)

        // Dias SC -> Pre-Nota (total do processo): dias uteis; -1 se SC ou NF ausentes
        // Dias Total: SC -> Pre-Nota fisica (F1_RECBMTO). NAO inclui PN-CL (classificacao)
        nDiasScNf := IIF(!Empty(dDtEntrada) .And. !Empty(dDtSC) .And. dDtEntrada >= dDtSC, ;
                         DiasUteis(dDtSC, dDtEntrada), -1)

        // Dias Recebimento -> Pre-Nota: dias uteis para digitar a pre-nota apos receber
        nDiasNfEnt := IIF(!Empty(dDtEntrada) .And. !Empty(dDtNF) .And. dDtNF >= dDtEntrada, ;
                          DiasUteis(dDtEntrada, dDtNF), -1)

        nDiasPnCl := IIF(!Empty(dDtClassif) .And. !Empty(dDtEntrada) .And. dDtClassif >= dDtEntrada, ;
                         DiasUteis(dDtEntrada, dDtClassif), -1)

        // Dias Necessidade (C1_DATPRF) -> Pre-Nota
        If !Empty(dDtNecess) .And. !Empty(dDtEntrada) .And. dDtEntrada >= dDtNecess
            nDiasNecPn := DiasUteis(dDtNecess, dDtEntrada)
        Else
            nDiasNecPn := -1
        EndIf

        // Dias emissao PC -> Aprovacao: dias uteis aguardando aprovacao (azul -> verde)
        nDiasEmApro := IIF(!Empty(dDtApro) .And. !Empty(dDtPC) .And. dDtApro >= dDtPC, ;
                           DiasUteis(dDtPC, dDtApro), -1)

        aAdd(aLeadData, {;
            cCodComp,    ;   // [1]  Cod comprador
            cNomeComp,   ;   // [2]  Nome comprador
            cNumPC,      ;   // [3]  Num Pedido de Compra
            dDtPC,       ;   // [4]  Data emissao PC
            cNumSC,      ;   // [5]  Num Solicitacao de Compra
            dDtSC,       ;   // [6]  Data emissao SC
            dDtNF,       ;   // [7]  Data digitacao Pre-Nota (SD1)
            nDiasScPc,   ;   // [8]  Dias uteis SC -> PC  (-1 = sem SC vinculada)
            nDiasPcNf,   ;   // [9]  Dias uteis Aprov -> Pre-Nota (-1 = sem aprovacao ou pre-nota)
            nDiasScNf,   ;   // [10] Dias uteis SC -> Pre-Nota total (-1 = sem SC ou NF)
            dDtEntrada,  ;   // [11] Data recebimento fisico (SF1 F1_RECBMTO)
            nDiasNfEnt,  ;   // [12] Dias uteis Recebimento -> Pre-Nota (-1 = sem recebimento)
            dDtClassif,  ;   // [13] Data classificacao final NF (SF1 F1_DTDIGIT)
            nDiasPnCl,   ;   // [14] Dias uteis Pre-Nota -> Classificacao (-1 = sem classificacao)
            dDtApro,    ;   // [15] Data aprovacao PC (C7_DATAPRO) - azul -> verde
            nDiasEmApro,;   // [16] Dias uteis emissao -> aprovacao (-1 = sem aprovacao)
            dDtNecess,  ;   // [17] Data necessidade SC1 (C1_DATPRF)
            nDiasNecPn  ;   // [18] Dias uteis necessidade -> Pre-Nota (-1 = sem dados)
        })

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    CalcMediasLT()
    TelaLeadTime(dDtDe, dDtAte, cNomeUsr)
Return

/*/{Protheus.doc} CalcMediasLT
Agrupa aLeadData por comprador e calcula medias de lead time.
@type Static Function
/*/
Static Function CalcMediasLT()
    Local nI      := 0
    Local nScPc   := 0
    Local nPcNf   := 0
    Local nScNf   := 0
    Local nNfEnt  := 0
    Local nPnCl   := 0
    Local nEmApro := 0
    Local nNecPn  := 0

    aLeadMedia := {}
    aAdd(aLeadMedia, {"*", "Equipe Compras", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})

    For nI := 1 To Len(aLeadData)
        nScPc   := aLeadData[nI, 8]
        nPcNf   := aLeadData[nI, 9]
        nScNf   := aLeadData[nI, 10]
        nNfEnt  := aLeadData[nI, 12]
        nPnCl   := aLeadData[nI, 14]
        nEmApro := aLeadData[nI, 16]

        aLeadMedia[1, 3] += 1          // Qtd PCs total

        If nScPc >= 0
            aLeadMedia[1, 4] += 1      // Qtd com SC
            aLeadMedia[1, 5] += nScPc  // Soma dias SC-PC
        EndIf

        If nPcNf >= 0
            aLeadMedia[1, 6] += 1      // Qtd com NF
            aLeadMedia[1, 7] += nPcNf  // Soma dias Aprov-PN
        EndIf

        If nScNf >= 0
            aLeadMedia[1, 9] += 1      // Qtd com SC e NF (base media total)
            aLeadMedia[1, 8] += nScNf  // Soma dias SC-NF total
        EndIf

        If nNfEnt >= 0
            aLeadMedia[1, 10] += 1       // Qtd com Pre-Nota e Entrada
            aLeadMedia[1, 11] += nNfEnt  // Soma dias NF-Entrada
        EndIf

        If nPnCl >= 0
            aLeadMedia[1, 12] += 1       // Qtd com Pre-Nota e Classificacao
            aLeadMedia[1, 13] += nPnCl   // Soma dias PN-Classificacao
        EndIf

        If nEmApro >= 0
            aLeadMedia[1, 14] += 1         // Qtd PCs aprovados
            aLeadMedia[1, 15] += nEmApro   // Soma dias emissao -> aprovacao
        EndIf

        nNecPn := aLeadData[nI, 18]
        If nNecPn >= 0
            aLeadMedia[1, 16] += 1         // Qtd com Necessidade e Pre-Nota
            aLeadMedia[1, 17] += nNecPn    // Soma dias Necessidade -> Pre-Nota
        EndIf
    Next nI
Return

/*/{Protheus.doc} TelaLeadTime
Exibe Lead Time usando MSDIALOG com TPanel (Align) para layout responsivo.
Painel inferior fixo para botoes, LISTBOX preenche todo espaco restante.
@type Static Function
@param dDtDe, Data inicial
@param dDtAte, Data final
@param cNomeUsr, Nome do comprador selecionado
/*/
Static Function TelaLeadTime(dDtDe, dDtAte, cNomeUsr)
    Local oDlg
    Local oPnlBtm
    Local oListDet
    Local oBtnExcel, oBtnResumo, oBtnFechar, oBtnBusca, oBtnLimpar
    Local oGetPC
    Local cFiltPC := Space(20)

    aLeadDisp   := aLeadData
    cLeadFiltPC := ""

    DEFINE MSDIALOG oDlg ;
        TITLE "Lead Time - " + AllTrim(cNomeUsr) + ;
            " | " + DTOC(dDtDe) + " a " + DTOC(dDtAte) + ;
            " | " + cValToChar(Len(aLeadData)) + " pedidos" ;
        FROM 0,0 TO 760, 1150 PIXEL ;
        STYLE nOR(DS_MODALFRAME, WS_SYSMENU, WS_MAXIMIZEBOX)

    // Painel inferior fixo - uma linha
    oPnlBtm := TPanel():New(0, 0, "", oDlg)
    oPnlBtm:nHeight := 55
    oPnlBtm:Align   := CONTROL_ALIGN_BOTTOM

    @ 010, 008 BUTTON oBtnExcel  PROMPT "Excel"         SIZE 065, 019 OF oPnlBtm PIXEL ;
        ACTION ExportaExcelLT(dDtDe, dDtAte, cNomeUsr)

    @ 010, 078 BUTTON oBtnResumo PROMPT "Resumo"        SIZE 065, 019 OF oPnlBtm PIXEL ;
        ACTION ResumoEquipeLT(cNomeUsr)

    @ 010, 148 BUTTON oBtnFechar PROMPT "Nova Consulta" SIZE 080, 019 OF oPnlBtm PIXEL ;
        ACTION (oDlg:End(), U_ZLEADTIME())

    @ 013, 260 SAY "Pesq. N.PC:" SIZE 055, 018 PIXEL OF oPnlBtm
    @ 010, 320 GET oGetPC VAR cFiltPC PICTURE "@!" SIZE 100, 019 PIXEL OF oPnlBtm
    @ 010, 425 BUTTON oBtnBusca PROMPT "Buscar" SIZE 060, 019 OF oPnlBtm PIXEL ;
        ACTION (cLeadFiltPC := AllTrim(cFiltPC), FiltraPC(oListDet))

    @ 010, 490 BUTTON oBtnLimpar PROMPT "Limpar" SIZE 060, 019 OF oPnlBtm PIXEL ;
        ACTION (cFiltPC := Space(20), oGetPC:Refresh(), cLeadFiltPC := "", FiltraPC(oListDet))

    // LISTBOX preenche todo o espaco restante (responsivo)
    // [ALTERADO] Coluna "Dias Aprov." movida para apos "Dt.Classif"
    // [ALTERADO] Coluna renomeada: PC-NF -> PC-PN
    @ 000, 000 LISTBOX oListDet FIELDS HEADER ;
        "Comprador", "Dt.Emis.SC", "N.SC", "Dt.Emis.PC", "N.PC", "Dt.Aprovac.PC", ;
        "Dt.Pre-Nota", "Dt.Classif", "Dt.Necess.", "Dias.Necess.", "Dias Aprov.", ;
        "Dias SC-PC", "Dias PC-PN", "Dias PN-CL", "Dias Total" ;
        SIZE 100, 100 OF oDlg PIXEL

    oListDet:Align := CONTROL_ALIGN_ALLCLIENT
    oListDet:bLDblClick := {|| DetalhePC(oListDet)}
    oListDet:SetArray(aLeadDisp)
    oListDet:bLine := {|| {;
        SubStr(aLeadDisp[oListDet:nAt, 2], 1, 30),;                                                              // Comprador
        If(Empty(aLeadDisp[oListDet:nAt, 6]),  "",         DTOC(aLeadDisp[oListDet:nAt, 6])),;                   // Dt.Emis.SC  (vazio se sem SC)
        aLeadDisp[oListDet:nAt, 5],;                                                                              // N.SC
        If(Empty(aLeadDisp[oListDet:nAt, 4]),  "N/A",      DTOC(aLeadDisp[oListDet:nAt, 4])),;                   // Dt.Emis.PC
        aLeadDisp[oListDet:nAt, 3],;                                                                              // N.PC
        If(Empty(aLeadDisp[oListDet:nAt, 15]), "Pendente", DTOC(aLeadDisp[oListDet:nAt, 15])),;                  // Dt.Aprovac.PC
        If(Empty(aLeadDisp[oListDet:nAt, 11]), "Pendente", DTOC(aLeadDisp[oListDet:nAt, 11])),;                  // Dt.Pre-Nota
        If(Empty(aLeadDisp[oListDet:nAt, 13]), "Pendente", DTOC(aLeadDisp[oListDet:nAt, 13])),;                  // Dt.Classif
        If(Empty(aLeadDisp[oListDet:nAt, 17]), "Pendente", DTOC(aLeadDisp[oListDet:nAt, 17])),;                  // Dt.Necess. (C1_DATPRF)
        If(aLeadDisp[oListDet:nAt, 18] >= 0,  cValToChar(aLeadDisp[oListDet:nAt, 18]) + " d", "-"),;            // Dias.Necess.
        If(aLeadDisp[oListDet:nAt, 16] >= 0,  cValToChar(aLeadDisp[oListDet:nAt, 16]) + " d", "-"),;            // Dias Aprov.
        If(aLeadDisp[oListDet:nAt, 8]  >= 0,  cValToChar(aLeadDisp[oListDet:nAt, 8])  + " d", "-"),;            // Dias SC-PC
        If(aLeadDisp[oListDet:nAt, 9]  >= 0,  cValToChar(aLeadDisp[oListDet:nAt, 9])  + " d", "-"),;            // Dias PC-PN
        If(aLeadDisp[oListDet:nAt, 14] >= 0,  cValToChar(aLeadDisp[oListDet:nAt, 14]) + " d", "-"),;            // Dias PN-CL
        If(aLeadDisp[oListDet:nAt, 10] >= 0,  cValToChar(aLeadDisp[oListDet:nAt, 10]) + " d", "-") }}            // Dias Total
    oListDet:aColSizes := {50, 50, 50, 50, 50, 50, 50, 50, 50, 40, 40, 45, 45, 45, 45}

    ACTIVATE MSDIALOG oDlg CENTERED
Return

/*/{Protheus.doc} FiltraPC
Filtra aLeadDisp pelo N.PC informado em cLeadFiltPC e atualiza o LISTBOX.
@type Static Function
@param oListDet, Objeto LISTBOX da tela de Lead Time
/*/
Static Function FiltraPC(oListDet)
    Local nI     := 0
    Local cBusca := AllTrim(cLeadFiltPC)
    Local aTemp  := {}

    If Empty(cBusca)
        aTemp := AClone(aLeadData)
    Else
        For nI := 1 To Len(aLeadData)
            If AllTrim(aLeadData[nI, 3]) == cBusca
                aAdd(aTemp, AClone(aLeadData[nI]))
            EndIf
        Next nI
    EndIf

    If Len(aTemp) == 0
        MsgAlert("Nenhum pedido encontrado com N.PC: " + cBusca, "Atencao")
        aTemp := AClone(aLeadData)
    EndIf

    aLeadDisp := aTemp

    oListDet:SetArray(aLeadDisp)
    oListDet:bLine := {|| {;
        SubStr(aLeadDisp[oListDet:nAt, 2], 1, 30),;
        If(Empty(aLeadDisp[oListDet:nAt, 6]),  "",         DTOC(aLeadDisp[oListDet:nAt, 6])),;
        aLeadDisp[oListDet:nAt, 5],;
        If(Empty(aLeadDisp[oListDet:nAt, 4]),  "N/A",      DTOC(aLeadDisp[oListDet:nAt, 4])),;
        aLeadDisp[oListDet:nAt, 3],;
        If(Empty(aLeadDisp[oListDet:nAt, 15]), "Pendente", DTOC(aLeadDisp[oListDet:nAt, 15])),;
        If(Empty(aLeadDisp[oListDet:nAt, 11]), "Pendente", DTOC(aLeadDisp[oListDet:nAt, 11])),;
        If(Empty(aLeadDisp[oListDet:nAt, 13]), "Pendente", DTOC(aLeadDisp[oListDet:nAt, 13])),;
        If(Empty(aLeadDisp[oListDet:nAt, 17]), "Pendente", DTOC(aLeadDisp[oListDet:nAt, 17])),;
        If(aLeadDisp[oListDet:nAt, 18] >= 0,  cValToChar(aLeadDisp[oListDet:nAt, 18]) + " d", "-"),;
        If(aLeadDisp[oListDet:nAt, 16] >= 0,  cValToChar(aLeadDisp[oListDet:nAt, 16]) + " d", "-"),;
        If(aLeadDisp[oListDet:nAt, 8]  >= 0,  cValToChar(aLeadDisp[oListDet:nAt, 8])  + " d", "-"),;
        If(aLeadDisp[oListDet:nAt, 9]  >= 0,  cValToChar(aLeadDisp[oListDet:nAt, 9])  + " d", "-"),;
        If(aLeadDisp[oListDet:nAt, 14] >= 0,  cValToChar(aLeadDisp[oListDet:nAt, 14]) + " d", "-"),;
        If(aLeadDisp[oListDet:nAt, 10] >= 0,  cValToChar(aLeadDisp[oListDet:nAt, 10]) + " d", "-") }}
    oListDet:nAt := 1
    oListDet:Refresh()
Return

/*/{Protheus.doc} ResumoEquipeLT
Exibe resumo consolidado de lead time da equipe de compras via MsgInfo.
@type Static Function
/*/
Static Function ResumoEquipeLT(cNomeUsr)
    Local cMsg      := ""
    Local nMedSP    := 0
    Local nMedPN    := 0
    Local nMedNecPn := 0
    Local nMedPnCl  := 0
    Local nMedApro  := 0
    Local nMedTot   := 0
    Local nSemSC    := 0
    Local lEquipe   := "TODOS" $ Upper(cNomeUsr)
    Local cTitulo   := ""
    Local cStatus   := ""
    Local cSep      := Replicate("-", 50)

    If Len(aLeadMedia) == 0
        MsgAlert("Nenhum dado de resumo!", "Atencao")
        Return
    EndIf

    nMedSP    := IIF(aLeadMedia[1,4]  > 0, Round(aLeadMedia[1,5]  / aLeadMedia[1,4],  1), 0)
    nMedPN    := IIF(aLeadMedia[1,6]  > 0, Round(aLeadMedia[1,7]  / aLeadMedia[1,6],  1), 0)
    nMedPnCl  := IIF(aLeadMedia[1,12] > 0, Round(aLeadMedia[1,13] / aLeadMedia[1,12], 1), 0)
    nMedApro  := IIF(aLeadMedia[1,14] > 0, Round(aLeadMedia[1,15] / aLeadMedia[1,14], 1), 0)
    nMedTot   := IIF(aLeadMedia[1,9]  > 0, Round(aLeadMedia[1,8]  / aLeadMedia[1,9],  1), 0)
    nMedNecPn := IIF(aLeadMedia[1,16] > 0, Round(aLeadMedia[1,17] / aLeadMedia[1,16], 1), 0)

    nSemSC := aLeadMedia[1,3] - aLeadMedia[1,4]

    If nMedTot <= 10
        cStatus := "NO PRAZO  (meta: ate 10 dias)"
    Else
        cStatus := "!! ACIMA DA META  (meta: ate 10 dias)"
    EndIf

    If lEquipe
        cTitulo := "Resumo da Equipe - Lead Time"
        cMsg    := "RESUMO GERAL DA EQUIPE DE COMPRAS" + CRLF
    Else
        cTitulo := "Resumo Individual - Lead Time"
        cMsg    := "RESUMO INDIVIDUAL: " + Upper(AllTrim(cNomeUsr)) + CRLF
    EndIf

    cMsg += cSep + CRLF + CRLF

    cMsg += "PEDIDOS DE COMPRA" + CRLF
    cMsg += "  Total de Pedidos               : " + cValToChar(aLeadMedia[1,3])  + CRLF
    cMsg += "  Com Solicitacao vinculada      : " + cValToChar(aLeadMedia[1,4])  + CRLF
    cMsg += "  Sem Solicitacao vinculada      : " + cValToChar(nSemSC)           + CRLF
    cMsg += "  Com Pre-Nota registrada        : " + cValToChar(aLeadMedia[1,6])  + CRLF
    cMsg += "  Com Classificacao fiscal       : " + cValToChar(aLeadMedia[1,12]) + CRLF
    cMsg += "  Com Aprovacao registrada       : " + cValToChar(aLeadMedia[1,14]) + CRLF + CRLF

    cMsg += cSep + CRLF
    cMsg += "MEDIAS DE PRAZO (em dias uteis)" + CRLF + CRLF
    cMsg += "  Aprovacao do Pedido            : " + AllTrim(Transform(nMedApro,  "@E 999.9")) + " dias" + CRLF
    cMsg += "  Solicitacao ate Pedido         : " + AllTrim(Transform(nMedSP,    "@E 999.9")) + " dias" + CRLF
    cMsg += "  Necessidade ate Pre-Nota       : " + AllTrim(Transform(nMedNecPn, "@E 999.9")) + " dias" + CRLF
    cMsg += "  Aprovacao ate Pre-Nota         : " + AllTrim(Transform(nMedPN,    "@E 999.9")) + " dias" + CRLF
    cMsg += "  Pre-Nota ate Classificacao     : " + AllTrim(Transform(nMedPnCl,  "@E 999.9")) + " dias" + CRLF
    cMsg += "  Total (Solicitacao -> Pre-Nota): " + AllTrim(Transform(nMedTot,   "@E 999.9")) + " dias" + CRLF + CRLF

    cMsg += cSep + CRLF
    cMsg += "STATUS: " + cStatus + CRLF

    MsgInfo(cMsg, cTitulo)
Return

/*/{Protheus.doc} ExportaExcelLT
Exporta os dados de Lead Time para Excel via TReport.
Gera duas secoes:
  - Secao 1: Detalhe por Pedido de Compra (SC -> PC -> Pre-Nota com dias)
  - Secao 2: Resumo de medias por comprador
@type Static Function
@param dDtDe, Data inicial
@param dDtAte, Data final
@param cNomeUsr, Nome do comprador / "Todos os Compradores"
/*/
Static Function ExportaExcelLT(dDtDe, dDtAte, cNomeUsr)
    Local oReport
    Local oSecDet, oSecMed
    Local nQtd := Len(aLeadData)

    If nQtd == 0
        MsgAlert("Nenhum dado para exportar!", "Atencao")
        Return
    EndIf

    If !MsgYesNo("Exportar " + cValToChar(nQtd) + " registro(s) para Excel?", "Lead Time - Excel")
        Return
    EndIf

    oReport := TReport():New("ZLEADEXP", ;
        "Lead Time dos Compradores - " + AllTrim(cNomeUsr), "", ;
        {|oReport| ImprimirLT(oReport, dDtDe, dDtAte, cNomeUsr)}, ;
        "Lead Time: SC -> PC -> Pre-Nota por Comprador")

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    // Secao detalhe por PC
    oSecDet := TRSection():New(oReport, "Detalhe", {})
    TRCell():New(oSecDet, "COMPRADOR",  "", "Comprador",    "@!", 25)
    TRCell():New(oSecDet, "NUM_PC",     "", "N.PC",         "@!", 8)
    TRCell():New(oSecDet, "DT_PC",      "", "Dt.Emis.PC",   "@D", 10)
    TRCell():New(oSecDet, "DT_APRO",    "", "Dt.Aprovac.",  "@D", 10)
    TRCell():New(oSecDet, "DT_NECESS",  "", "Dt.Necessidade", "@D",    10)
    TRCell():New(oSecDet, "DIAS_NECPN", "", "Dias Neces.-PN",  "@E 999", 10)
    TRCell():New(oSecDet, "DIAS_APRO",  "", "Dias Aprov.",     "@E 999",  9)
    TRCell():New(oSecDet, "NUM_SC",     "", "N.SC",            "@!",       8)
    TRCell():New(oSecDet, "DT_SC",      "", "Dt.Emis.SC",   "@D", 10)
    TRCell():New(oSecDet, "DT_NF",      "", "Dt.Pre-Nota",  "@D", 10)
    TRCell():New(oSecDet, "DIAS_SCPC",  "", "Dias SC-PC",   "@E 999", 9)
    TRCell():New(oSecDet, "DIAS_PCNF",  "", "Dias PC-PN",   "@E 999", 10)
    TRCell():New(oSecDet, "DT_CLASSIF", "", "Dt.Classif",   "@D", 10)
    TRCell():New(oSecDet, "DIAS_PNCL",  "", "Dias PN-Classif", "@E 999", 10)
    TRCell():New(oSecDet, "DIAS_SCNF",  "", "Dias SC-PreNota", "@E 999", 10)

    // Secao resumo por comprador
    oSecMed := TRSection():New(oReport, "Resumo por Comprador", {})
    TRCell():New(oSecMed, "RES_COMP",    "", "Comprador",          "@!",      30)
    TRCell():New(oSecMed, "RES_QTDPC",   "", "Qtd.PCs",            "@E 999",   7)
    TRCell():New(oSecMed, "RES_QTDAPR",  "", "Qtd.c/Aprov.",       "@E 999",   8)
    TRCell():New(oSecMed, "RES_MEDAPRO", "", "Media Aprov.(d)",    "@E 999.9", 11)
    TRCell():New(oSecMed, "RES_QTDSC",   "", "Qtd.c/SC",           "@E 999",   7)
    TRCell():New(oSecMed, "RES_MEDSC",   "", "Media SC-PC",        "@E 999.9", 10)
    TRCell():New(oSecMed, "RES_QTDNF",   "", "Qtd.c/NF",           "@E 999",   7)
    TRCell():New(oSecMed, "RES_MEDNF",   "", "Media Aprov-PN",     "@E 999.9", 11)
    TRCell():New(oSecMed, "RES_QTDCL",   "", "Qtd.c/Classif",      "@E 999",   7)
    TRCell():New(oSecMed, "RES_MEDCL",   "", "Media PN-Classif",   "@E 999.9", 11)
    TRCell():New(oSecMed, "RES_MEDTOT",  "", "Media Total SC-NF",  "@E 999.9", 12)
    TRCell():New(oSecMed, "RES_META",    "", "Meta (<=10d)",        "@!",       10)

    oReport:PrintDialog()
Return

/*/{Protheus.doc} ImprimirLT
Callback do TReport: imprime detalhe e resumo de Lead Time.
@type Static Function
@param oReport, Objeto TReport
@param dDtDe, Data inicial
@param dDtAte, Data final
@param cNomeUsr, Nome do comprador
/*/
Static Function ImprimirLT(oReport, dDtDe, dDtAte, cNomeUsr)
    Local oSecDet   := oReport:Section(1)
    Local oSecMed   := oReport:Section(2)
    Local nI        := 0
    Local nDiasScPc := 0
    Local nDiasPcNf := 0
    Local nDiasApro := 0
    Local nMedScPc  := 0
    Local nMedPcNf  := 0
    Local nMedNfEnt := 0
    Local nMedPnCl  := 0
    Local nMedApro  := 0
    Local nMedTot   := 0

    oReport:SetMeter(0)

    oReport:PrintText("Lead Time dos Compradores", 0)
    oReport:PrintText("Comprador: " + AllTrim(cNomeUsr) + ;
        "   |   Periodo: " + DTOC(dDtDe) + " a " + DTOC(dDtAte) + ;
        "   |   Total de Pedidos: " + cValToChar(Len(aLeadData)), 0)
    oReport:SkipLine()

    oSecDet:Init()

    For nI := 1 To Len(aLeadData)
        nDiasScPc := aLeadData[nI, 8]
        nDiasPcNf := aLeadData[nI, 9]
        nDiasApro := aLeadData[nI, 16]

        oSecDet:Cell("COMPRADOR"):SetValue(AllTrim(aLeadData[nI, 2]))
        oSecDet:Cell("NUM_PC"):SetValue(AllTrim(aLeadData[nI, 3]))
        oSecDet:Cell("DT_PC"):SetValue(aLeadData[nI, 4])
        oSecDet:Cell("DT_APRO"):SetValue(IIF(!Empty(aLeadData[nI, 15]), aLeadData[nI, 15], CtoD("")))
        oSecDet:Cell("DT_NECESS"):SetValue(IIF(!Empty(aLeadData[nI, 17]), aLeadData[nI, 17], CtoD("")))
        oSecDet:Cell("DIAS_NECPN"):SetValue(IIF(aLeadData[nI, 18] >= 0, aLeadData[nI, 18], 0))
        oSecDet:Cell("DIAS_APRO"):SetValue(IIF(nDiasApro >= 0, nDiasApro, 0))
        oSecDet:Cell("NUM_SC"):SetValue(AllTrim(aLeadData[nI, 5]))
        oSecDet:Cell("DT_SC"):SetValue(IIF(!Empty(aLeadData[nI, 6]),  aLeadData[nI, 6],  CtoD("")))
        oSecDet:Cell("DT_NF"):SetValue(IIF(!Empty(aLeadData[nI, 7]),  aLeadData[nI, 7],  CtoD("")))
        oSecDet:Cell("DIAS_SCPC"):SetValue(IIF(nDiasScPc >= 0, nDiasScPc, 0))
        oSecDet:Cell("DIAS_PCNF"):SetValue(IIF(nDiasPcNf >= 0, nDiasPcNf, 0))
        oSecDet:Cell("DT_CLASSIF"):SetValue(IIF(!Empty(aLeadData[nI, 13]), aLeadData[nI, 13], CtoD("")))
        oSecDet:Cell("DIAS_PNCL"):SetValue(IIF(aLeadData[nI, 14] >= 0, aLeadData[nI, 14], 0))
        oSecDet:Cell("DIAS_SCNF"):SetValue(IIF(aLeadData[nI, 10] >= 0, aLeadData[nI, 10], 0))

        oSecDet:PrintLine()
        oReport:IncMeter()
    Next nI

    oReport:SkipLine()
    oReport:PrintText("=== RESUMO - MEDIA DE LEAD TIME POR COMPRADOR ===", 0)
    oReport:SkipLine()

    oSecMed:Init()

    For nI := 1 To Len(aLeadMedia)
        nMedScPc  := IIF(aLeadMedia[nI, 4]  > 0, Round(aLeadMedia[nI, 5]  / aLeadMedia[nI, 4],  1), 0)
        nMedPcNf  := IIF(aLeadMedia[nI, 6]  > 0, Round(aLeadMedia[nI, 7]  / aLeadMedia[nI, 6],  1), 0)
        nMedNfEnt := IIF(aLeadMedia[nI, 10] > 0, Round(aLeadMedia[nI, 11] / aLeadMedia[nI, 10], 1), 0)
        nMedPnCl  := IIF(aLeadMedia[nI, 12] > 0, Round(aLeadMedia[nI, 13] / aLeadMedia[nI, 12], 1), 0)
        nMedApro  := IIF(aLeadMedia[nI, 14] > 0, Round(aLeadMedia[nI, 15] / aLeadMedia[nI, 14], 1), 0)
        nMedTot   := IIF(aLeadMedia[nI, 9]  > 0, Round(aLeadMedia[nI, 8]  / aLeadMedia[nI, 9],  1), -1)

        oSecMed:Cell("RES_COMP"):SetValue(AllTrim(aLeadMedia[nI, 2]))
        oSecMed:Cell("RES_QTDPC"):SetValue(aLeadMedia[nI, 3])
        oSecMed:Cell("RES_QTDAPR"):SetValue(aLeadMedia[nI, 14])
        oSecMed:Cell("RES_MEDAPRO"):SetValue(nMedApro)
        oSecMed:Cell("RES_QTDSC"):SetValue(aLeadMedia[nI, 4])
        oSecMed:Cell("RES_MEDSC"):SetValue(nMedScPc)
        oSecMed:Cell("RES_QTDNF"):SetValue(aLeadMedia[nI, 6])
        oSecMed:Cell("RES_MEDNF"):SetValue(nMedPcNf)
        oSecMed:Cell("RES_QTDCL"):SetValue(aLeadMedia[nI, 12])
        oSecMed:Cell("RES_MEDCL"):SetValue(nMedPnCl)
        oSecMed:Cell("RES_MEDTOT"):SetValue(IIF(nMedTot >= 0, nMedTot, 0))
        oSecMed:Cell("RES_META"):SetValue(IIF(nMedTot < 0, "s/dados", IIF(nMedTot <= 10, "OK", "AVALIAR")))

        oSecMed:PrintLine()
    Next nI
Return

/*/{Protheus.doc} DetalhePC
Exibe detalhes do Pedido de Compra e Solicitacao de Compra
selecionados ao duplo clique na LISTBOX de Lead Time.
Mostra informacoes do fornecedor, itens do PC com quantidades e valores.
@type Static Function
@param oListDet, Objeto LISTBOX com os dados de Lead Time
/*/
Static Function DetalhePC(oListDet)
    Local nAt       := oListDet:nAt
    Local cNumPC    := ""
    Local cNumSC    := ""
    Local cCompra   := ""
    Local oDlgDet
    Local oPnlInfo
    Local oListItens
    Local oFont, oFontBold
    Local aItens    := {}
    Local cAlias    := GetNextAlias()
    Local cQuery    := ""
    Local cFornec   := ""
    Local cNomFor   := ""
    Local cNumNF    := ""
    Local nTotPC    := 0

    If nAt < 1 .Or. nAt > Len(aLeadData)
        Return
    EndIf

    cNumPC  := aLeadDisp[nAt, 3]
    cNumSC  := aLeadDisp[nAt, 5]
    cCompra := aLeadDisp[nAt, 2]

    oFont     := TFont():New("Arial",, -11,, .F.)
    oFontBold := TFont():New("Arial",, -12, .T., .F.)

    // Query itens do PC com fornecedor
    cQuery := " SELECT"
    cQuery += "   LTRIM(RTRIM(SC7.C7_PRODUTO)) AS PRODUTO,"
    cQuery += "   LTRIM(RTRIM(SC7.C7_DESCRI))  AS DESCRI,"
    cQuery += "   SC7.C7_QUANT                  AS QUANT,"
    cQuery += "   SC7.C7_PRECO                  AS PRECO,"
    cQuery += "   SC7.C7_TOTAL                  AS TOTAL,"
    cQuery += "   SC7.C7_RESIDUO                AS RESIDUO,"
    cQuery += "   LTRIM(RTRIM(SC7.C7_FORNECE))  AS FORNECE,"
    cQuery += "   LTRIM(RTRIM(SC7.C7_LOJA))     AS LOJA,"
    cQuery += "   LTRIM(RTRIM(ISNULL(SA2.A2_NOME, ''))) AS NOMFOR,"
    cQuery += "   LTRIM(RTRIM(SC7.C7_UM))       AS UM"
    cQuery += " FROM " + RetSqlName("SC7") + " SC7"
    cQuery += " LEFT JOIN " + RetSqlName("SA2") + " SA2"
    cQuery += "   ON SA2.D_E_L_E_T_ = ' '"
    cQuery += "   AND LTRIM(RTRIM(SA2.A2_FILIAL)) = '" + xFilial("SA2") + "'"
    cQuery += "   AND SA2.A2_COD  = SC7.C7_FORNECE"
    cQuery += "   AND SA2.A2_LOJA = SC7.C7_LOJA"
    cQuery += " WHERE SC7.D_E_L_E_T_ = ' '"
    cQuery += "   AND LTRIM(RTRIM(SC7.C7_FILIAL)) = '" + xFilial("SC7") + "'"
    cQuery += "   AND LTRIM(RTRIM(SC7.C7_NUM)) = '" + cNumPC + "'"
    cQuery += " ORDER BY SC7.C7_ITEM"

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        If Empty(cFornec)
            cFornec := AllTrim((cAlias)->FORNECE) + "/" + AllTrim((cAlias)->LOJA)
            cNomFor := AllTrim((cAlias)->NOMFOR)
        EndIf
        nTotPC += (cAlias)->TOTAL
        aAdd(aItens, {;
            AllTrim((cAlias)->PRODUTO),;
            AllTrim((cAlias)->DESCRI),;
            (cAlias)->QUANT,;
            (cAlias)->PRECO,;
            (cAlias)->TOTAL,;
            AllTrim((cAlias)->UM),;
            AllTrim((cAlias)->RESIDUO)})
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    // Busca numero da Nota Fiscal (SD1)
    cQuery := " SELECT TOP 1 LTRIM(RTRIM(D1_DOC)) AS NF_DOC"
    cQuery += " FROM " + RetSqlName("SD1")
    cQuery += " WHERE D_E_L_E_T_ = ' '"
    cQuery += "   AND LTRIM(RTRIM(D1_FILIAL)) = '" + xFilial("SD1") + "'"
    cQuery += "   AND LTRIM(RTRIM(D1_PEDIDO)) = '" + cNumPC + "'"
    cQuery := ChangeQuery(cQuery)
    cAlias := GetNextAlias()
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)
    If !(cAlias)->(Eof())
        cNumNF := AllTrim((cAlias)->NF_DOC)
    EndIf
    (cAlias)->(DbCloseArea())

    DEFINE MSDIALOG oDlgDet ;
        TITLE "PC " + cNumPC + IIF(!Empty(cNumSC), " | SC " + cNumSC, "") + IIF(!Empty(cNumNF), " | NF " + cNumNF, "") ;
        FROM 0,0 TO 550, 1000 PIXEL ;
        STYLE nOR(DS_MODALFRAME, WS_SYSMENU)

    oPnlInfo := TPanel():New(0, 0, "", oDlgDet)
    oPnlInfo:nHeight := 105
    oPnlInfo:Align   := CONTROL_ALIGN_TOP

    @ 005, 010 SAY "PEDIDO DE COMPRA" SIZE 200, 014 PIXEL OF oPnlInfo FONT oFontBold
    @ 022, 010 SAY "N.PC:"     SIZE 035, 012 PIXEL OF oPnlInfo FONT oFontBold
    @ 022, 050 SAY cNumPC      SIZE 080, 012 PIXEL OF oPnlInfo FONT oFont
    @ 022, 140 SAY "Emissao:"  SIZE 050, 012 PIXEL OF oPnlInfo FONT oFontBold
    @ 022, 195 SAY DtoC(aLeadDisp[nAt, 4]) SIZE 070, 012 PIXEL OF oPnlInfo FONT oFont
    @ 022, 275 SAY "Comprador:" SIZE 060, 012 PIXEL OF oPnlInfo FONT oFontBold
    @ 022, 340 SAY cCompra     SIZE 150, 012 PIXEL OF oPnlInfo FONT oFont
    @ 038, 010 SAY "Fornecedor:" SIZE 060, 012 PIXEL OF oPnlInfo FONT oFontBold
    @ 038, 075 SAY cFornec + " - " + cNomFor SIZE 300, 012 PIXEL OF oPnlInfo FONT oFont
    @ 038, 340 SAY "Total PC:" SIZE 055, 012 PIXEL OF oPnlInfo FONT oFontBold
    @ 038, 400 SAY "R$ " + AllTrim(Transform(nTotPC, "@E 999,999,999.99")) SIZE 120, 012 PIXEL OF oPnlInfo FONT oFont
    @ 058, 010 SAY "N.SC:"      SIZE 035, 012 PIXEL OF oPnlInfo FONT oFontBold
    @ 058, 050 SAY IIF(!Empty(cNumSC), cNumSC, "N/A") SIZE 080, 012 PIXEL OF oPnlInfo FONT oFont
    @ 058, 140 SAY "Emissao SC:" SIZE 060, 012 PIXEL OF oPnlInfo FONT oFontBold
    @ 058, 205 SAY IIF(!Empty(aLeadDisp[nAt, 6]),  DtoC(aLeadDisp[nAt, 6]),  "N/A")      SIZE 070, 012 PIXEL OF oPnlInfo FONT oFont
    @ 058, 285 SAY "Pre-Nota:"  SIZE 055, 012 PIXEL OF oPnlInfo FONT oFontBold
    @ 058, 345 SAY IIF(!Empty(aLeadDisp[nAt, 11]), DtoC(aLeadDisp[nAt, 11]), "Pendente") SIZE 080, 012 PIXEL OF oPnlInfo FONT oFont
    @ 058, 430 SAY "Nota:"      SIZE 030, 012 PIXEL OF oPnlInfo FONT oFontBold
    @ 058, 465 SAY IIF(!Empty(cNumNF), cNumNF, "Pendente") SIZE 080, 012 PIXEL OF oPnlInfo FONT oFont
    @ 074, 010 SAY "Classif:"   SIZE 045, 012 PIXEL OF oPnlInfo FONT oFontBold
    @ 074, 060 SAY IIF(!Empty(aLeadDisp[nAt, 13]), DtoC(aLeadDisp[nAt, 13]), "Pendente") SIZE 080, 012 PIXEL OF oPnlInfo FONT oFont
    @ 074, 150 SAY "Dias PN-Classif:" SIZE 080, 012 PIXEL OF oPnlInfo FONT oFontBold
    @ 074, 235 SAY IIF(aLeadDisp[nAt, 14] >= 0, cValToChar(aLeadDisp[nAt, 14]) + " dias", "Pendente") SIZE 080, 012 PIXEL OF oPnlInfo FONT oFont
    @ 074, 330 SAY "Aprovacao:" SIZE 055, 012 PIXEL OF oPnlInfo FONT oFontBold
    @ 074, 390 SAY IIF(!Empty(aLeadDisp[nAt, 15]), DtoC(aLeadDisp[nAt, 15]), "Pendente") SIZE 080, 012 PIXEL OF oPnlInfo FONT oFont
    @ 074, 475 SAY "Dias Aprov.:" SIZE 060, 012 PIXEL OF oPnlInfo FONT oFontBold
    @ 074, 540 SAY IIF(aLeadDisp[nAt, 16] >= 0, cValToChar(aLeadDisp[nAt, 16]) + " dias uteis", "Pendente") SIZE 090, 012 PIXEL OF oPnlInfo FONT oFont

    // Grid de itens do PC (preenche espaco restante)
    @ 000, 000 LISTBOX oListItens FIELDS HEADER ;
        "Produto", "Descricao", "UM", "Quantidade", "Preco Unit.", "Total", "Nota Fiscal" ;
        SIZE 100, 100 OF oDlgDet PIXEL

    oListItens:Align := CONTROL_ALIGN_ALLCLIENT

    If Len(aItens) > 0
        oListItens:SetArray(aItens)
        oListItens:bLine := {|| {;
            aItens[oListItens:nAt, 1],;
            aItens[oListItens:nAt, 2],;
            aItens[oListItens:nAt, 6],;
            AllTrim(Transform(aItens[oListItens:nAt, 3], "@E 999,999.99")),;
            "R$ " + AllTrim(Transform(aItens[oListItens:nAt, 4], "@E 999,999.99")),;
            "R$ " + AllTrim(Transform(aItens[oListItens:nAt, 5], "@E 999,999,999.99")),;
            IIF(!Empty(cNumNF), cNumNF, "Pendente") }}
        oListItens:aColSizes := {30, 80, 15, 30, 30, 40, 20}
    EndIf

    ACTIVATE MSDIALOG oDlgDet CENTERED

    FreeObj(oFont)
    FreeObj(oFontBold)
Return

/*/{Protheus.doc} DiasUteis
Calcula dias uteis entre duas datas usando funcao nativa DateWorkDay.
Exclui sabados, domingos e feriados cadastrados no Protheus (SX5/Tabela 63).
Nao conta a data inicial, conta a data final.
@type Static Function
@param dDe, Data inicial (nao inclusa na contagem)
@param dAte, Data final (inclusa na contagem)
@return Numeric, Quantidade de dias uteis no intervalo
/*/
Static Function DiasUteis(dDe, dAte)
    // Contagem EXCLUSIVA do dia inicial (nao conta dDe, conta dAte)
    // Mesmo dia = 0 | 05/01->06/01 = 1 | 05/01->05/01 = 0
    // DateWorkDay no Protheus e INCLUSIVO dos dois lados, por isso usamos dDe+1
    // .F. = nao conta sabado | .F. = nao conta domingo | .F. = nao conta feriados (SX5/63)
    Local nDias := 0
    If dAte > dDe
        nDias := DateWorkDay(dDe + 1, dAte, .F., .F., .F.)
    EndIf
Return nDias
