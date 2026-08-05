#Include "Protheus.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} MT110CON
Ponto de entrada (TudoOK) da MATA110, disparado ANTES da gravacao
definitiva da Solicitacao de Compra (A110GRAVA / A110ALTERA).

Responsabilidade (v10 - 11/06/2026):
  Apenas PREPARAR o contexto para o PE pos-save M110STTS, que e quem
  efetivamente corrige a data de emissao do item novo (gravacao direta
  no SC1 via RecLock). Aqui:
    - Captura o numero da SC na PRIVATE cA110Num da MATA110 (visivel ao
      PE por escopo dinamico). Neste contexto MVC/FWFormBrowse, M->C1_NUM,
      GdFieldGet e FwModelActive sao indisponiveis e C1_NUM nao esta no
      grid; cA110Num e a unica fonte confiavel pre-save.
    - Tira um SNAPSHOT dos itens JA gravados (RECNO de cada um) ANTES do
      save. No pos-save, todo item cujo RECNO nao esteja no snapshot e NOVO.

  NOTA: alterar aCols neste PE NAO persiste (a gravacao e via model MVC).
        Por isso toda a correcao de data fica no M110STTS (pos-save).
        A data de necessidade (C1_DATPRF +15) e regra de dicionario
        (X3_RELACAO do campo), nao tratada aqui.

Publics consumidos pelo M110STTS:
    PUBLIC aZ110Snap  := { {cItem, dEmis, dDatPrf, nRecno}, ... }
    PUBLIC cZ110NumSC := numero da SC

@type     user function
@author   Suprimentos
@since    02/06/2026
@version  10.0 - 11/06/2026 - Numero via cA110Num; snapshot por RECNO; correcao no M110STTS
@return   logical, .T. = Permite gravar | .F. = Bloqueia
@see      M110STTS
/*/
//-------------------------------------------------------------------
User Function MT110CON()

    Local lRet      := .T.
    Local aArea     := GetArea()
    Local aAreaSC1  := SC1->(GetArea())
    Local cNumSC    := ""
    Local cFilSC1   := xFilial("SC1")
    Local aSnap     := {}           // {cItem, dEmis, dDatPrf, nRecno} dos existentes

    // Publics consumidos pelo M110STTS apos o save
    PUBLIC aZ110Snap, cZ110NumSC
    aZ110Snap  := {}
    cZ110NumSC := ""

    // --- 1) Captura numero da SC -----------------------------------
    If Type("cA110Num") == "C" .And. !Empty(cA110Num)
        cNumSC := AllTrim(cA110Num)
    EndIf
    If Empty(cNumSC) .And. Type("M->C1_NUM") != "U"
        cNumSC := AllTrim(cValToChar(M->C1_NUM))
    EndIf
    If Empty(cNumSC) .And. Select("SC1") > 0 .And. !Empty(SC1->C1_NUM)
        cNumSC := AllTrim(SC1->C1_NUM)
    EndIf
    cZ110NumSC := cNumSC

    // --- 2) Snapshot dos itens existentes (banco) ------------------
    // {C1_ITEM, C1_EMISSAO, C1_DATPRF, RECNO} de cada item JA gravado.
    // NAO usar !Deleted() na condicao do While (pararia no 1o deletado);
    // pula deletados com Loop interno para nao perder itens seguintes.
    If !Empty(cNumSC)
        DbSelectArea("SC1")
        SC1->(DbSetOrder(1))  // C1_FILIAL + C1_NUM + C1_ITEM
        If SC1->(DbSeek(cFilSC1 + cNumSC))
            While !SC1->(Eof()) .And. ;
                  AllTrim(SC1->C1_FILIAL) == AllTrim(cFilSC1) .And. ;
                  AllTrim(SC1->C1_NUM)    == AllTrim(cNumSC)
                If !SC1->(Deleted())
                    AAdd(aSnap, { AllTrim(SC1->C1_ITEM), SC1->C1_EMISSAO, SC1->C1_DATPRF, SC1->(RecNo()) })
                EndIf
                SC1->(DbSkip())
            End
        EndIf
    EndIf
    aZ110Snap := aClone(aSnap)

    ConOut("MT110CON: SC=[" + cNumSC + "] existentes=" + cValToChar(Len(aSnap)))

    RestArea(aAreaSC1)
    RestArea(aArea)

Return lRet
