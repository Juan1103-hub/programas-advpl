#Include "protheus.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} M110STTS
Ponto de entrada disparado APOS a gravacao completa da Solicitacao
de Compra (SC1 / MATA110), antes de retornar para a tela de browse.

Objetivo (v5 - 11/06/2026):
  Gravar a data de emissao = hoje (Date()) APENAS nos itens NOVOS de uma SC,
  preservando a emissao original dos itens existentes. Como neste contexto MVC
  alterar aCols em PE pre-save NAO persiste, a correcao e feita aqui no pos-save
  via RecLock direto no SC1.

Logica:
  Consome os PUBLIC populados pelo MT110CON:
    aZ110Snap  = { {cItem, dEmis, dDatPrf, nRecno}, ... } dos itens que JA
                 existiam ANTES do save.
    cZ110NumSC = numero da SC.

  Varre o SC1 da SC gravada:
    - C1_EMISSAO:
        * Item NOVO (RECNO nao consta no snapshot) => Date() (hoje).
        * Item existente => nao e tocado (mantem a emissao original).
    - C1_DATPRF (necessidade): havendo inclusao de QUALQUER item novo,
      aplica a regra dos +15 dias (dDataBase+15) em TODOS os itens da SC,
      uniformizando a necessidade. Sem inclusao, nao mexe na necessidade.

  Deteccao por RECNO e imune a colisao/reuso de C1_ITEM. Sem snapshot
  confiavel, nao altera nada (seguranca).

@type     user function
@author   Suprimentos
@since    02/06/2026
@version  6.0 - 11/06/2026 - Inclusao dispara +15 (dDataBase+15) em TODOS os itens.
          5.0 - 11/06/2026 - Emissao=hoje so nos itens novos (RECNO); numero via cA110Num/SC1.
@return   Nil
@see      MT110CON
/*/
//-------------------------------------------------------------------
User Function M110STTS()

    Local aArea       := GetArea()
    Local aAreaSC1    := SC1->(GetArea())
    Local cNumSC      := ""
    Local cFilSC1     := xFilial("SC1")
    Local nRec        := 0
    Local cItemAtu    := ""
    Local dEmissNova  := Date()           // data real do servidor (nao dDataBase)
    Local dDatPrfNova := dDataBase + 15   // mesma regra do X3_RELACAO (dDataBase+15)
    Local nQtdNovo    := 0
    Local aRecsAnt    := {}            // RECNOs dos itens existentes ANTES do save
    Local lUsaRec     := .F.           // .T. = snapshot trouxe RECNO de todos
    Local lNovo       := .F.
    Local lTemNovo    := .F.           // .T. = houve inclusao de item novo nesta SC
    Local nI          := 0

    ConOut("=== M110STTS DISPAROU (pos-save MATA110) ===")

    // Pre-requisitos: publics populados pelo MT110CON
    If Type("aZ110Snap") != "A" .Or. Type("cZ110NumSC") != "C"
        ConOut("M110STTS: publics ausentes - sem acao.")
        RestArea(aAreaSC1)
        RestArea(aArea)
        Return Nil
    EndIf

    cNumSC := AllTrim(cZ110NumSC)

    // Fallback: no pos-save o alias SC1 fica posicionado num registro desta SC.
    If Empty(cNumSC) .And. Select("SC1") > 0 .And. !Empty(SC1->C1_NUM)
        cNumSC  := AllTrim(SC1->C1_NUM)
        cFilSC1 := SC1->C1_FILIAL
    EndIf

    If Empty(cNumSC)
        ConOut("M110STTS: cNumSC vazio - sem acao.")
        RestArea(aAreaSC1)
        RestArea(aArea)
        Return Nil
    EndIf

    // RECNOs dos itens que JA existiam ANTES do save (4a posicao do snapshot do
    // MT110CON). Um registro gravado cujo RECNO nao esteja aqui e item NOVO.
    For nI := 1 To Len(aZ110Snap)
        If ValType(aZ110Snap[nI]) == "A" .And. Len(aZ110Snap[nI]) >= 4 .And. ;
           ValType(aZ110Snap[nI][4]) == "N"
            AAdd(aRecsAnt, aZ110Snap[nI][4])
        EndIf
    Next nI
    lUsaRec := (Len(aRecsAnt) == Len(aZ110Snap))

    // Seguranca: sem snapshot confiavel (RECNOs) NAO altera nada, para nunca
    // sobrescrever a emissao de itens existentes por engano.
    If Len(aZ110Snap) == 0 .Or. !lUsaRec
        ConOut("M110STTS: snapshot ausente/incompleto - sem acao (seguranca).")
        RestArea(aAreaSC1)
        RestArea(aArea)
        Return Nil
    EndIf

    DbSelectArea("SC1")
    SC1->(DbSetOrder(1))
    If !SC1->(DbSeek(cFilSC1 + cNumSC))
        ConOut("M110STTS: SC nao encontrada no SC1.")
        RestArea(aAreaSC1)
        RestArea(aArea)
        Return Nil
    EndIf

    // NAO incluir !SC1->(Deleted()) na condicao do While: isso interromperia a
    // varredura no primeiro item deletado, deixando itens seguintes sem corrigir.
    // Deletados sao ignorados com Loop interno.
    While !SC1->(Eof()) .And. ;
          AllTrim(SC1->C1_FILIAL) == AllTrim(cFilSC1) .And. ;
          AllTrim(SC1->C1_NUM)    == AllTrim(cNumSC)

        If SC1->(Deleted())
            SC1->(DbSkip())
            Loop
        EndIf

        nRec     := SC1->(RecNo())
        cItemAtu := AllTrim(SC1->C1_ITEM)

        // Item NOVO = RECNO nao existia antes do save. Itens existentes nao sao
        // tocados na EMISSAO (mantem a original).
        lNovo := (aScan(aRecsAnt, {|r| r == nRec}) == 0)

        If lNovo
            lTemNovo := .T.
            If SC1->C1_EMISSAO != dEmissNova
                ConOut("M110STTS: NOVO rec=" + cValToChar(nRec) + " item=" + cItemAtu + ;
                       " EMIS " + DtoC(SC1->C1_EMISSAO) + "->" + DtoC(dEmissNova))
                RecLock("SC1", .F.)
                    SC1->C1_EMISSAO := dEmissNova
                SC1->(MsUnlock())
                nQtdNovo++
            EndIf
        EndIf

        SC1->(DbSkip())
    End

    // Houve inclusao de item novo => dispara a regra dos +15 dias (dDataBase+15)
    // para TODOS os itens da SC, deixando a necessidade uniforme.
    If lTemNovo
        SC1->(DbSetOrder(1))
        If SC1->(DbSeek(cFilSC1 + cNumSC))
            While !SC1->(Eof()) .And. ;
                  AllTrim(SC1->C1_FILIAL) == AllTrim(cFilSC1) .And. ;
                  AllTrim(SC1->C1_NUM)    == AllTrim(cNumSC)
                If !SC1->(Deleted()) .And. SC1->C1_DATPRF != dDatPrfNova
                    RecLock("SC1", .F.)
                        SC1->C1_DATPRF := dDatPrfNova
                    SC1->(MsUnlock())
                EndIf
                SC1->(DbSkip())
            End
        EndIf
    EndIf

    ConOut("M110STTS: Concluido SC=" + cNumSC + " | Novos=" + cValToChar(nQtdNovo) + ;
           " | DATPRF " + IIF(lTemNovo, "uniformizado=" + DtoC(dDatPrfNova), "inalterado"))

    RestArea(aAreaSC1)
    RestArea(aArea)

Return Nil
