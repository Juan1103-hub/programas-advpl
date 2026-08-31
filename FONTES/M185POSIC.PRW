#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} M185POSIC
Dialog customizado de Baixa de Pre-Requisicao com campo ZC1_POSIC.

Recria o dialog da MATA185 (A185Manual) acrescentando o campo
Posicao do Estoque (ZC1_POSIC) para consulta direta do operador.

@param aParam - Array com dados da pre-requisicao:
         [1] = CP_NUM     (Numero da SA)
         [2] = CP_ITEM    (Item da SA)
         [3] = CP_PRODUTO (Codigo do Produto)
         [4] = CP_LOCAL   (Armazem)
         [5] = CP_QUANT   (Quantidade original)

@author  Vortice
@since   30/08/2026
/*/
User Function M185POSIC(aParam)

    Local aArea     := GetArea()
    Local aAreaSCP  := SCP->(GetArea())
    Local aAreaSB1  := SB1->(GetArea())
    Local aAreaSB2  := SB2->(GetArea())
    Local aAreaZC1  := ZC1->(GetArea())

    Local oDlg      := Nil
    Local oFont     := TFont():New("Arial",, 14,, .T.)

    // --- Dados da Pre-Requisicao ---
    Local cNumSA    := ""
    Local cItemSA   := ""
    Local cProduto  := ""
    Local cDescProd := ""
    Local cArmazem  := ""
    Local nQtdOrig  := 0

    // --- Saldo / Estoque ---
    Local nQAtu     := 0
    Local nQtRes    := 0
    Local nQtSal    := 0
    Local nQtRequ   := 0
    Local cPosic    := Space(50)

    // --- TM ---
    Local cTM       := Space(3)

    // --- Controle ---
    Local nOpc      := 0

    Default aParam := {}

    If Len(aParam) < 5
        MsgStop("Parametros incompletos. Uso: U_M185POSIC({CP_NUM, CP_ITEM, CP_PRODUTO, CP_LOCAL, CP_QUANT})", "M185POSIC")
        Return
    EndIf

    // ==========================================
    // 1. Recebe parametros
    // ==========================================
    cNumSA    := aParam[1]
    cItemSA   := aParam[2]
    cProduto  := aParam[3]
    cArmazem  := aParam[4]
    nQtdOrig  := aParam[5]

    // ==========================================
    // 2. Busca descricao do produto (SB1)
    // ==========================================
    dbSelectArea("SB1")
    SB1->(dbSetOrder(1))
    If SB1->(dbSeek(xFilial("SB1") + cProduto))
        cDescProd := SB1->B1_DESC
    Else
        cDescProd := "*** Produto nao encontrado ***"
    EndIf

    // ==========================================
    // 3. Busca saldos (SB2)
    // ==========================================
    dbSelectArea("SB2")
    SB2->(dbSetOrder(1))
    If SB2->(dbSeek(xFilial("SB2") + cProduto + cArmazem))
        nQAtu  := SB2->B2_QATU
        nQtRes := SB2->B2_RESERVA + SB2->B2_QEMP + SB2->B2_QEMPSA + SB2->B2_QACLASS
        nQtSal := nQAtu - nQtRes
    EndIf

    // ==========================================
    // 4. Busca Posicao do Estoque (ZC1)
    // ==========================================
    cPosic := Space(50)
    If FPOS_TabelaExiste("ZC1")
        dbSelectArea("ZC1")
        ZC1->(dbSetOrder(1))
        If ZC1->(dbSeek(xFilial("ZC1") + cProduto))
            cPosic := ZC1->ZC1_POSIC
        EndIf
    EndIf

    // ==========================================
    // 5. Monta Dialog
    // ==========================================
    Define MSDialog oDlg Title "Baixa Pre-Requisicao - Com ZC1 Posicao" ;
        From 000, 000 To 430, 700 Pixel

    // --- GRUPO: Resumo do Produto (esquerda) ---
    @ 010, 010 Say "Produto:"          Of oDlg Pixel
    @ 010, 080 Say AllTrim(cProduto)   Of oDlg Font oFont Pixel COLOR CLR_BLUE

    @ 025, 010 Say "Descricao:"        Of oDlg Pixel
    @ 025, 080 Say SubStr(cDescProd, 1, 50) Of oDlg Pixel

    @ 040, 010 Say "Armazem:"          Of oDlg Pixel
    @ 040, 080 Say cArmazem            Of oDlg Pixel

    // --- Separador ---
    @ 055, 010 Say "Resumo do Estoque" Of oDlg Font oFont Pixel COLOR CLR_HRED

    @ 070, 010 Say "Estoque Atual:"    Of oDlg Pixel
    @ 070, 080 Say Transform(nQAtu, "@E 999,999.99") Of oDlg Pixel

    @ 085, 010 Say "Reservas PV/OP:"   Of oDlg Pixel
    @ 085, 080 Say Transform(nQtRes, "@E 999,999.99") Of oDlg Pixel

    @ 100, 010 Say "Saldo Disponivel:" Of oDlg Pixel
    @ 100, 080 Say Transform(nQtSal, "@E 999,999.99") Of oDlg Font oFont Pixel COLOR CLR_GREEN

    // --- GRUPO: Dados da Pre-Requisicao (direita) ---
    @ 010, 310 Say "Nr. SA:"           Of oDlg Pixel
    @ 010, 370 Say cNumSA              Of oDlg Pixel

    @ 025, 310 Say "Item SA:"          Of oDlg Pixel
    @ 025, 370 Say cItemSA             Of oDlg Pixel

    @ 040, 310 Say "Qtd. Original:"    Of oDlg Pixel
    @ 040, 370 Say Transform(nQtdOrig, "@E 999,999.99") Of oDlg Pixel

    @ 070, 310 Say "Saldo Pre-Requisicao:" Of oDlg Pixel
    @ 070, 430 Say Transform(nQtSal, "@E 999,999.99") Of oDlg Font oFont Pixel COLOR CLR_HBLUE

    // --- Campo: Posicao ZC1 (NOVO) ---
    @ 115, 010 Say "Posicao Estoque (ZC1):" Of oDlg Pixel
    @ 115, 120 MsGet cPosic Size 200, 10 Of oDlg Pixel When .F.

    // --- Campo: Quantidade a Requisitar ---
    @ 135, 010 Say "Quantidade a Requisitar:" Of oDlg Pixel
    @ 135, 150 MsGet nQtRequ ;
        Valid (nQtRequ > 0 .And. nQtRequ <= nQtSal) ;
        Size 60, 10 Of oDlg Pixel

    // --- Campo: TM (Tipo de Movimentacao) ---
    @ 155, 010 Say "TM (Tipo Movimento):" Of oDlg Pixel
    @ 155, 150 MsGet cTM ;
        Valid !Vazio(cTM) .And. ExistCpo("SX5", "DJ" + cTM) ;
        F3 "DJ" ;
        Size 30, 10 Of oDlg Pixel

    // --- Botoes ---
    Define SButton From 180, 250 Type 1 Action (nOpc := 1, oDlg:End()) Enable Of oDlg
    Define SButton From 180, 290 Type 2 Action (oDlg:End()) Enable Of oDlg

    Activate MSDialog oDlg Centered

    // ==========================================
    // 6. Processa Baixa
    // ==========================================
    If nOpc == 1
        If nQtRequ <= 0
            MsgAlert("Quantidade a requisitar deve ser maior que zero.", "M185POSIC")
        ElseIf nQtRequ > nQtSal
            MsgAlert("Quantidade excede o saldo disponivel.", "M185POSIC")
        Else
            Processa({|| M185Grava(cNumSA, cItemSA, cProduto, cArmazem, cTM, nQtRequ, cPosic)},;
                "Processando Baixa...", "Gerando movimentacao interna...", .T.)
        EndIf
    EndIf

    // ==========================================
    // 7. Restaura areas
    // ==========================================
    RestArea(aAreaZC1)
    RestArea(aAreaSB2)
    RestArea(aAreaSB1)
    RestArea(aAreaSCP)
    RestArea(aArea)

Return

/*/{Protheus.doc} M185Grava
Grava a movimentacao interna (SD3) e atualiza a pre-requisicao (SCP).
Utiliza MSExecAuto com MATA241 para manter integridade de regras de negocio.
/*/
Static Function M185Grava(cNumSA, cItemSA, cProduto, cArmazem, cTM, nQtRequ, cPosic)

    Local aCabec    := {}
    Local aItens    := {}
    Local aLinha    := {}
    Local lOk       := .T.
    Local cDoc      := ""

    Private lMsErroAuto  := .F.
    Private lMsHelpAuto  := .T.

    ProcRegua(3)

    // --- Gerar numero do documento ---
    IncProc("Gerando numero do documento...")
    cDoc := GetSX8Num("SD3", "D3_DOC")
    ConfirmSX8()

    // --- Montar cabecalho ---
    IncProc("Montando cabecalho...")
    aAdd(aCabec, {"D3_DOC",     cDoc,      Nil})
    aAdd(aCabec, {"D3_EMISSAO", dDataBase, Nil})

    // --- Montar itens ---
    aLinha := {}
    aAdd(aLinha, {"D3_COD",     cProduto,  Nil})
    aAdd(aLinha, {"D3_UM",      Posicione("SB1", 1, xFilial("SB1") + cProduto, "B1_UM"), Nil})
    aAdd(aLinha, {"D3_QUANT",   nQtRequ,   Nil})
    aAdd(aLinha, {"D3_LOCAL",   cArmazem,  Nil})
    aAdd(aLinha, {"D3_TM",      cTM,       Nil})
    aAdd(aLinha, {"D3_NUMSA",   cNumSA,    Nil})
    aAdd(aLinha, {"D3_ITEMSA",  cItemSA,   Nil})
    aAdd(aItens, aLinha)

    // --- Executar MATA241 via MSExecAuto ---
    IncProc("Gerando movimentacao interna (SD3)...")
    MSExecAuto({|x, y, z| MATA241(x, y, z)}, aCabec, aItens, 3)

    If lMsErroAuto
        lOk := .F.
        MostraErro()
        DisarmTransaction()
    Else
        // --- Atualizar SCP: decrementar saldo e marcar como baixado ---
        dbSelectArea("SCP")
        SCP->(dbSetOrder(1))
        If SCP->(dbSeek(xFilial("SCP") + cNumSA + cItemSA))
            RecLock("SCP", .F.)
            SCP->CP_QUANT := SCP->CP_QUANT - nQtRequ
            If SCP->CP_QUANT <= 0
                SCP->CP_QUANT := 0
            EndIf
            MsUnlock()
        EndIf

        // --- Gravar ZC1_POSIC no campo customizado CP_POSIC ---
        If !Empty(cPosic) .And. SCP->(ColumnPos("CP_POSIC")) > 0
            RecLock("SCP", .F.)
            SCP->CP_POSIC := cPosic
            MsUnlock()
        EndIf

        MsgInfo("Baixa realizada com sucesso!" + CRLF +;
            "Documento: " + cDoc + CRLF +;
            "Produto: " + cProduto + CRLF +;
            "Quantidade: " + Transform(nQtRequ, "@E 999,999.99") + CRLF +;
            "Posicao ZC1: " + AllTrim(cPosic), "M185POSIC")
    EndIf

Return lOk

/*/{Protheus.doc} FPOS_TabelaExiste
Verifica se uma tabela existe no dicionario (SX2).
/*/
Static Function FPOS_TabelaExiste(cArq)
    Local lExiste := .F.
    dbSelectArea("SX2")
    SX2->(dbSetOrder(1))
    lExiste := SX2->(dbSeek(cArq))
Return lExiste
