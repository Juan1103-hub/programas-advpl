#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} ZPREVNFE
Preview do DANFE antes da transmissao NF-e.
Tela de pre-visualizacao tabular (MSDIALOG + LISTBOX) com os
dados da NF para conferencia visual antes de transmitir a
NF-e para SEFAZ.

Comportamento:
- Pre-transmissao (F2_CHVNFE vazia): tela de conferencia com
  todos os dados da NF, itens e totais, com tarja
  "PREVIEW - SEM VALOR FISCAL" destacada.
- Pos-transmissao (F2_CHVNFE preenchida): se parametro
  MV_ZPRTDANFE == .T. e cIdEnt configurado, chama U_PrtNfeSef()
  para gerar o DANFE oficial do TSS. Caso contrario, mostra
  a mesma tela de conferencia com chave/protocolo preenchidos.

Pode ser chamado do SPEDNFE (via U_MT460PREV) ou diretamente
de um menu (U_ZPREVNFE(serie, numero)).

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   24/06/2026
@param   cSerie,  Caractere, Serie da NF
@param   cNumero, Caractere, Numero da NF
@example U_ZPREVNFE("1", "000123")
/*/
User Function ZPREVNFE(cSerie, cNumero)
    Local aArea   := GetArea()
    Local cChave  := ""
    Local lUsarPrtNfeSef := .F.
    Local cIdEnt  := ""

    If cSerie == Nil .Or. cNumero == Nil
        MsgAlert("Parametros obrigatorios: Serie, Numero NF", "Atencao")
        RestArea(aArea)
        Return
    EndIf

    cSerie  := AllTrim(cSerie)
    cNumero := AllTrim(cNumero)

    DbSelectArea("SF2")
    DbSetOrder(1)
    If !DbSeek(xFilial("SF2") + cNumero + cSerie)
        MsgAlert("Nota Fiscal nao encontrada: " + cNumero + "/" + cSerie, "Atencao")
        RestArea(aArea)
        Return
    EndIf

    cChave := ""
    If SF2->(FieldPos("F2_CHVNFE")) > 0
        cChave := AllTrim(SF2->F2_CHVNFE)
    EndIf

    lUsarPrtNfeSef := .F.
    If !Empty(cChave)
        lUsarPrtNfeSef := (SuperGetMV("MV_ZPRTDANFE", .F., .F.) == .T.)
    EndIf

    If lUsarPrtNfeSef
        cIdEnt := ZPRVGetId()
        If !Empty(cIdEnt)
            ConOut("[ZPREVNFE] Pos-transmissao - chamando U_PrtNfeSef cIdEnt=" + cIdEnt)
            ZPRVPrtNfeSef(cIdEnt, cSerie, cNumero)
            RestArea(aArea)
            Return
        Else
            ConOut("[ZPREVNFE] MV_ZPRTDANFE=.T. mas cIdEnt vazio - usando tela tabular")
        EndIf
    EndIf

    ZPRVShow(cSerie, cNumero, cChave)

    RestArea(aArea)
Return

/*/{Protheus.doc} ZPRVGetId
Retorna o cIdEnt (identificador TSS) para a empresa/filial atual.
Tenta obter via MV_NFEID; em caso negativo tenta MV_SPEDID;
em caso negativo retorna vazio (sistema usa tela tabular).

@type  Static Function
@return cIdEnt, Caractere, ID da entidade no TSS (vazio se nao configurado)
/*/
Static Function ZPRVGetId()
    Local cIdEnt := ""

    cIdEnt := AllTrim(SuperGetMV("MV_NFEID", .F., ""))

    If Empty(cIdEnt)
        cIdEnt := AllTrim(SuperGetMV("MV_SPEDID", .F., ""))
    EndIf

Return cIdEnt

/*/{Protheus.doc} ZPRVPrtNfeSef
Chama U_PrtNfeSef (DANFEII) com os parametros minimos para
gerar a DANFE oficial pos-transmissao. Preenche as variaveis
private MV_PAR usadas internamente pela PrtNfeSef/DANFEProc.

@type  Static Function
@param cIdEnt,  Caractere, ID da entidade no TSS
@param cSerie,  Caractere, Serie da NF
@param cNumero, Caractere, Numero da NF
/*/
Static Function ZPRVPrtNfeSef(cIdEnt, cSerie, cNumero)
    Local aArea      := GetArea()
    Local aPerguntas := {}
    Local aRet       := {}
    Local lRet       := .F.
    Local oDanfe     := Nil
    Local oSetup     := Nil

    aAdd(aPerguntas, {1, "NF de",  cNumero,  "", "", "", "", 60, .T.})
    aAdd(aPerguntas, {1, "NF ate", cNumero,  "", "", "", "", 60, .T.})
    aAdd(aPerguntas, {1, "Serie",  cSerie,   "", "", "", "", 30, .T.})
    aAdd(aPerguntas, {2, "Operacao",   2, {"Entrada", "Saida"},            50, "", .F.})
    aAdd(aPerguntas, {2, "F/Verso",    1, {"Sim", "Nao"},                  50, "", .F.})
    aAdd(aPerguntas, {2, "Simplif.",   2, {"Sim", "Nao"},                  50, "", .F.})

    If !ParamBox(aPerguntas, "DANFE - " + cNumero + "/" + cSerie, @aRet)
        RestArea(aArea)
        Return
    EndIf

    MV_PAR01 := aRet[1]
    MV_PAR02 := aRet[2]
    MV_PAR03 := aRet[3]
    MV_PAR04 := aRet[4]
    MV_PAR05 := aRet[5]
    MV_PAR06 := aRet[6]

    oSetup := FWPrintSetup():New()
    oSetup:SetPropert(PD_PRINTTYPE, IMP_PDF)
    oSetup:SetPropert(PD_DESTINATION, IMP_SPOOL)
    oSetup:SetPropert(PD_VALUETYPE, "\SPOOL\")

    oDanfe := FWMSPrinter():New("DANFE_" + cNumero, IMP_PDF, .F., , .T., , , , .T., .F.)
    oDanfe:SetResolution(78)
    oDanfe:SetPortrait()
    oDanfe:SetPaperSize(DMPAPER_A4)
    oDanfe:SetMargin(60, 60, 60, 60)

    lRet := U_PrtNfeSef(cIdEnt, "", "", oDanfe, oSetup, "DANFE_" + cNumero, .F., 0, .F., Nil)

    If oDanfe != Nil
        FreeObj(oDanfe)
        oDanfe := Nil
    EndIf
    If oSetup != Nil
        FreeObj(oSetup)
        oSetup := Nil
    EndIf

    ConOut("[ZPREVNFE] U_PrtNfeSef retornou " + cValToChar(lRet))

    RestArea(aArea)
Return

/*/{Protheus.doc} ZPRVShow
Exibe a tela de pre-visualizacao tabular (MSDIALOG + LISTBOX)
com os dados da NF para conferencia visual. Sem botoes de acao
(apenas X para fechar, conforme padrao advpl-tela-consulta).

@type  Static Function
@param cSerie,  Caractere, Serie da NF
@param cNumero, Caractere, Numero da NF
@param cChave,  Caractere, Chave de acesso (vazio = pre-transmissao)
/*/
Static Function ZPRVShow(cSerie, cNumero, cChave)
    Local aArea   := GetArea()
    Local aItens  := {}
    Local aCabec  := {}
    Local oDlg
    Local oL
    Local cTitulo    := ""
    Local cTarja     := ""
    Local cProtocolo := ""

    aCabec := ZPRVCab(cSerie, cNumero)
    aItens := ZPRVIt(cSerie, cNumero)

    If Len(aCabec) == 0
        MsgAlert("NF nao encontrada: " + cNumero + "/" + cSerie, "Atencao")
        RestArea(aArea)
        Return
    EndIf

    If Empty(cChave)
        cTitulo := "Preview DANFE - NF " + cNumero + "/" + cSerie + ;
                   " - " + AllTrim(aCabec[14]) + ;
                   " - PRE-TRANSMISSAO (SEM VALOR FISCAL)"
        cTarja  := "*** PREVIEW - NF-e NAO TRANSMITIDA - SEM VALOR FISCAL ***"
    Else
        cTitulo := "Preview DANFE - NF " + cNumero + "/" + cSerie + ;
                   " - " + AllTrim(aCabec[14]) + ;
                   " - POS-TRANSMISSAO (DANFE OFICIAL NAO GERADO)"
        cTarja  := "*** DANFE OFICIAL: transmita a NF e use o botao DANFE do SPEDNFE ***"
    EndIf

    If aCabec[19] != Nil
        cProtocolo := aCabec[19]
    EndIf

    DEFINE MSDIALOG oDlg TITLE cTitulo FROM 0,0 TO 650,1300 PIXEL

    // ====== LINHA @5 - Identificacao da NF ======
    @ 005, 005 SAY "NUMERO:"     SIZE 50,10 OF oDlg PIXEL
    @ 005, 055 SAY aCabec[01]    SIZE 60,10 OF oDlg PIXEL
    @ 005, 120 SAY "SERIE:"      SIZE 35,10 OF oDlg PIXEL
    @ 005, 155 SAY aCabec[02]    SIZE 30,10 OF oDlg PIXEL
    @ 005, 190 SAY "TIPO NF:"    SIZE 50,10 OF oDlg PIXEL
    @ 005, 240 SAY aCabec[03]    SIZE 15,10 OF oDlg PIXEL
    @ 005, 260 SAY "DATA EMISSAO:" SIZE 75,10 OF oDlg PIXEL
    @ 005, 335 SAY aCabec[04]    SIZE 70,10 OF oDlg PIXEL
    @ 005, 410 SAY "HORA:"       SIZE 30,10 OF oDlg PIXEL
    @ 005, 440 SAY aCabec[05]    SIZE 60,10 OF oDlg PIXEL
    @ 005, 505 SAY "CLIENTE:"    SIZE 45,10 OF oDlg PIXEL
    @ 005, 550 SAY aCabec[06] + "/" + aCabec[07] SIZE 80,10 OF oDlg PIXEL
    @ 005, 640 SAY "LOJA:"       SIZE 30,10 OF oDlg PIXEL
    @ 005, 670 SAY aCabec[07]    SIZE 25,10 OF oDlg PIXEL

    @ 015, 005 SAY "CHAVE ACESSO:" SIZE 80,10 OF oDlg PIXEL
    If Empty(cChave)
        @ 015, 085 SAY "[A GERAR - NAO TRANSMITIDA]" SIZE 250,10 OF oDlg PIXEL
    Else
        @ 015, 085 SAY cChave SIZE 600,10 OF oDlg PIXEL
    EndIf
    @ 015, 695 SAY "PROTOCOLO:" SIZE 60,10 OF oDlg PIXEL
    If Empty(cProtocolo)
        @ 015, 755 SAY "[PENDENTE DE TRANSMISSAO]" SIZE 200,10 OF oDlg PIXEL
    Else
        @ 015, 755 SAY cProtocolo SIZE 200,10 OF oDlg PIXEL
    EndIf

    // ====== LINHA @30 - Emitente ======
    @ 030, 005 SAY "EMITENTE" SIZE 100,10 OF oDlg PIXEL
    @ 035, 005 SAY aCabec[08]   SIZE 600,10 OF oDlg PIXEL
    @ 045, 005 SAY "CNPJ: " + aCabec[09] + "   IE: " + aCabec[10] SIZE 600,10 OF oDlg PIXEL
    @ 055, 005 SAY aCabec[11] + " - " + aCabec[12] + " - " + aCabec[13] SIZE 800,10 OF oDlg PIXEL

    // ====== LINHA @70 - Destinatario ======
    @ 070, 005 SAY "DESTINATARIO" SIZE 100,10 OF oDlg PIXEL
    @ 075, 005 SAY aCabec[14]    SIZE 600,10 OF oDlg PIXEL
    @ 085, 005 SAY "CNPJ/CPF: " + aCabec[15] + "   IE: " + aCabec[16] SIZE 600,10 OF oDlg PIXEL
    @ 095, 005 SAY aCabec[17] + " - " + aCabec[18] SIZE 800,10 OF oDlg PIXEL

    // ====== LINHA @110 - Itens ======
    @ 110, 005 SAY "ITENS DA NOTA (" + cValToChar(Len(aItens)) + ")" SIZE 200,10 OF oDlg PIXEL

    @ 115, 005 LISTBOX oL FIELDS HEADER ;
        "Item", "Codigo", "Descricao", "NCM", "CST", "CFOP", "UN", ;
        "Qtd", "Vlr Unit", "Vlr Total", "BC ICMS", "Vlr ICMS", "Vlr IPI" ;
        SIZE 1290,200 OF oDlg PIXEL

    If Len(aItens) > 0
        oL:SetArray(aItens)
        oL:aColSizes := {30, 70, 250, 60, 30, 40, 25, 70, 80, 90, 80, 80, 80}
        oL:bLine := {|| {;
            aItens[oL:nAt, 01], ;
            aItens[oL:nAt, 02], ;
            SubStr(aItens[oL:nAt, 03], 1, 35), ;
            aItens[oL:nAt, 04], ;
            aItens[oL:nAt, 05], ;
            aItens[oL:nAt, 06], ;
            aItens[oL:nAt, 07], ;
            Transform(aItens[oL:nAt, 08], "@E 9,999.99"), ;
            Transform(aItens[oL:nAt, 09], "@E 9,999,999.99"), ;
            Transform(aItens[oL:nAt, 10], "@E 9,999,999.99"), ;
            Transform(aItens[oL:nAt, 11], "@E 9,999,999.99"), ;
            Transform(aItens[oL:nAt, 12], "@E 9,999,999.99"), ;
            Transform(aItens[oL:nAt, 13], "@E 9,999,999.99")}}
    EndIf

    // ====== LINHA @320 - Totais ======
    @ 320, 005 SAY "TOTAIS DA NOTA" SIZE 150,10 OF oDlg PIXEL
    @ 325, 005 SAY "Base ICMS:"    SIZE 70,10 OF oDlg PIXEL
    @ 325, 075 SAY aCabec[20]      SIZE 100,10 OF oDlg PIXEL
    @ 325, 180 SAY "Vlr ICMS:"     SIZE 60,10 OF oDlg PIXEL
    @ 325, 240 SAY aCabec[21]      SIZE 100,10 OF oDlg PIXEL
    @ 325, 345 SAY "BC ICMS ST:"   SIZE 70,10 OF oDlg PIXEL
    @ 325, 415 SAY aCabec[22]      SIZE 100,10 OF oDlg PIXEL
    @ 325, 520 SAY "Vlr ICMS ST:"  SIZE 70,10 OF oDlg PIXEL
    @ 325, 590 SAY aCabec[23]      SIZE 100,10 OF oDlg PIXEL

    @ 335, 005 SAY "Vlr Produtos:" SIZE 70,10 OF oDlg PIXEL
    @ 335, 075 SAY aCabec[24]      SIZE 100,10 OF oDlg PIXEL
    @ 335, 180 SAY "Vlr Frete:"    SIZE 60,10 OF oDlg PIXEL
    @ 335, 240 SAY aCabec[25]      SIZE 100,10 OF oDlg PIXEL
    @ 335, 345 SAY "Vlr Seguro:"   SIZE 70,10 OF oDlg PIXEL
    @ 335, 415 SAY aCabec[26]      SIZE 100,10 OF oDlg PIXEL
    @ 335, 520 SAY "Vlr Desconto:" SIZE 70,10 OF oDlg PIXEL
    @ 335, 590 SAY aCabec[27]      SIZE 100,10 OF oDlg PIXEL

    @ 345, 005 SAY "Vlr Despesa:"  SIZE 70,10 OF oDlg PIXEL
    @ 345, 075 SAY aCabec[28]      SIZE 100,10 OF oDlg PIXEL
    @ 345, 180 SAY "Vlr IPI:"      SIZE 60,10 OF oDlg PIXEL
    @ 345, 240 SAY aCabec[29]      SIZE 100,10 OF oDlg PIXEL
    @ 345, 345 SAY "Vlr TOTAL:"    SIZE 70,10 OF oDlg PIXEL
    @ 345, 415 SAY aCabec[30]      SIZE 120,10 OF oDlg PIXEL

    // ====== LINHA @365 - Transporte ======
    @ 365, 005 SAY "TRANSPORTE" SIZE 100,10 OF oDlg PIXEL
    @ 370, 005 SAY aCabec[31]    SIZE 600,10 OF oDlg PIXEL
    @ 380, 005 SAY "CNPJ: " + aCabec[32] + "   IE: " + aCabec[33] + "   " + aCabec[34] SIZE 800,10 OF oDlg PIXEL

    // ====== LINHA @395 - Tarja ======
    @ 395, 005 SAY cTarja SIZE 1290,12 OF oDlg PIXEL
    @ 410, 005 SAY "Documento gerado em " + DtoC(Date()) + " as " + Time() + " - NAO POSSUI VALIDADE FISCAL" SIZE 800,10 OF oDlg PIXEL

    ACTIVATE MSDIALOG oDlg CENTERED

    RestArea(aArea)
Return

/*/{Protheus.doc} ZPRVCab
Carrega os dados do cabecalho da NF (SF2 + SM0 + SA1/SA2) em
um array posicional para exibicao na tela de preview.

Estrutura do array retornado (34 posicoes):
[01] F2_DOC               [02] F2_SERIE          [03] F2_TIPO
[04] F2_EMISSAO           [05] F2_HORA           [06] F2_CLIENTE
[07] F2_LOJA              [08] Emitente Nome     [09] Emitente CNPJ
[10] Emitente IE          [11] Emitente Endereco [12] Emitente Bairro
[13] Emitente Mun/UF      [14] Cliente Nome      [15] Cliente CNPJ
[16] Cliente IE           [17] Cliente Endereco  [18] Cliente Mun/UF
[19] F2_PROT (protocolo)  [20] Base ICMS         [21] Vlr ICMS
[22] Base ICMS ST         [23] Vlr ICMS ST       [24] Vlr Produtos
[25] Vlr Frete            [26] Vlr Seguro        [27] Vlr Desconto
[28] Vlr Despesa          [29] Vlr IPI           [30] Vlr Total
[31] Transp Nome          [32] Transp CNPJ       [33] Transp IE
[34] Transp Endereco

@type  Static Function
@param cSerie,  Caractere, Serie da NF
@param cNumero, Caractere, Numero da NF
@return aCabec, Array, Dados do cabecalho (vazio se NF nao encontrada)
/*/
Static Function ZPRVCab(cSerie, cNumero)
    Local aCabec    := {}
    Local aArea     := GetArea()
    Local cProtocolo := ""

    DbSelectArea("SF2")
    DbSetOrder(1)
    If !DbSeek(xFilial("SF2") + cNumero + cSerie)
        RestArea(aArea)
        Return aCabec
    EndIf

    If SF2->(Eof()) .Or. SF2->(Bof())
        RestArea(aArea)
        Return aCabec
    EndIf

    cProtocolo := ""
    If SF2->(FieldPos("F2_PROT")) > 0
        cProtocolo := AllTrim(SF2->F2_PROT)
    EndIf

    aAdd(aCabec, SF2->F2_DOC)                            // [01]
    aAdd(aCabec, SF2->F2_SERIE)                          // [02]
    aAdd(aCabec, SF2->F2_TIPO)                           // [03]
    aAdd(aCabec, DtoC(SF2->F2_EMISSAO))                  // [04]
    aAdd(aCabec, SF2->F2_HORA)                           // [05]
    aAdd(aCabec, SF2->F2_CLIENTE)                        // [06]
    aAdd(aCabec, SF2->F2_LOJA)                           // [07]

    // [08-13] Emitente (SM0)
    aAdd(aCabec, "")                                     // [08] nome
    aAdd(aCabec, "")                                     // [09] cnpj
    aAdd(aCabec, "")                                     // [10] ie
    aAdd(aCabec, "")                                     // [11] end
    aAdd(aCabec, "")                                     // [12] bairro
    aAdd(aCabec, "")                                     // [13] mun/uf

    DbSelectArea("SM0")
    DbSetOrder(1)
    If DbSeek(cEmpAnt + cFilAnt)
        If SM0->(FieldPos("M0_NOME"))  > 0; aCabec[08] := AllTrim(SM0->M0_NOME); EndIf
        If SM0->(FieldPos("M0_CGC"))   > 0; aCabec[09] := SM0->M0_CGC;         EndIf
        If SM0->(FieldPos("M0_INSC"))  > 0; aCabec[10] := SM0->M0_INSC;        EndIf

        cEnd := ""
        If SM0->(FieldPos("M0_END")) > 0
            cEnd := AllTrim(SM0->M0_END)
        EndIf
        If SM0->(FieldPos("M0_NR")) > 0 .And. !Empty(cEnd)
            cEnd += ", " + AllTrim(SM0->M0_NR)
        EndIf
        aCabec[11] := cEnd

        cBairro := ""
        If SM0->(FieldPos("M0_BAIRRO")) > 0; cBairro := SM0->M0_BAIRRO; EndIf
        aCabec[12] := AllTrim(cBairro)

        cMun := ""
        cEst := ""
        If SM0->(FieldPos("M0_MUN")) > 0; cMun := AllTrim(SM0->M0_MUN); EndIf
        If SM0->(FieldPos("M0_EST")) > 0; cEst := SM0->M0_EST; EndIf
        aCabec[13] := cMun + "/" + cEst
    EndIf

    // [14-18] Destinatario (SA1)
    aAdd(aCabec, "")                                     // [14] nome
    aAdd(aCabec, "")                                     // [15] cnpj
    aAdd(aCabec, "")                                     // [16] ie
    aAdd(aCabec, "")                                     // [17] end
    aAdd(aCabec, "")                                     // [18] mun/uf

    If !Empty(SF2->F2_CLIENTE) .And. !Empty(SF2->F2_LOJA)
        DbSelectArea("SA1")
        DbSetOrder(1)
        If DbSeek(xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA)
            aCabec[14] := AllTrim(SA1->A1_NOME)
            aCabec[15] := SA1->A1_CGC
            aCabec[16] := SA1->A1_INSCR

            cEnd := AllTrim(SA1->A1_END)
            If SA1->(FieldPos("A1_NR")) > 0
                cEnd += ", " + AllTrim(SA1->A1_NR)
            EndIf
            aCabec[17] := cEnd
            aCabec[18] := AllTrim(SA1->A1_MUN) + "/" + SA1->A1_EST
        EndIf
    EndIf

    // [19] protocolo
    aAdd(aCabec, cProtocolo)

    // [20-23] Impostos
    aAdd(aCabec, Transform(SF2->F2_BASEICM, "@E 9,999,999.99"))   // [20] base icms
    aAdd(aCabec, Transform(SF2->F2_VALICM,  "@E 9,999,999.99"))   // [21] vlr icms

    If SF2->(FieldPos("F2_BASEICMS")) > 0
        aAdd(aCabec, Transform(SF2->F2_BASEICMS, "@E 9,999,999.99"))
    Else
        aAdd(aCabec, "0,00")
    EndIf

    If SF2->(FieldPos("F2_VALICMST")) > 0
        aAdd(aCabec, Transform(SF2->F2_VALICMST, "@E 9,999,999.99"))
    Else
        aAdd(aCabec, "0,00")
    EndIf

    // [24-30] Totais
    aAdd(aCabec, Transform(SF2->F2_VALMERC, "@E 9,999,999.99"))   // [24] vlr produtos
    aAdd(aCabec, Transform(SF2->F2_FRETE,   "@E 9,999,999.99"))   // [25] vlr frete
    aAdd(aCabec, Transform(SF2->F2_SEGURO,  "@E 9,999,999.99"))   // [26] vlr seguro
    aAdd(aCabec, Transform(SF2->F2_DESCONT, "@E 9,999,999.99"))   // [27] vlr desconto
    aAdd(aCabec, Transform(SF2->F2_DESPESA, "@E 9,999,999.99"))   // [28] vlr despesa
    aAdd(aCabec, Transform(SF2->F2_VALIPI,  "@E 9,999,999.99"))   // [29] vlr ipi
    aAdd(aCabec, Transform(SF2->F2_VALBRUT, "@E 9,999,999.99"))   // [30] vlr total

    // [31-34] Transportador (SA2)
    aAdd(aCabec, "")                                     // [31] transp nome
    aAdd(aCabec, "")                                     // [32] transp cnpj
    aAdd(aCabec, "")                                     // [33] transp ie
    aAdd(aCabec, "")                                     // [34] transp end

    If !Empty(SF2->F2_TRANSP)
        DbSelectArea("SA2")
        DbSetOrder(1)
        If DbSeek(xFilial("SA2") + SF2->F2_TRANSP)
            aCabec[31] := AllTrim(SA2->A2_NOME)
            aCabec[32] := SA2->A2_CGC
            aCabec[33] := SA2->A2_INSCR
            cEnd := AllTrim(SA2->A2_END)
            If SA2->(FieldPos("A2_NR")) > 0
                cEnd += ", " + AllTrim(SA2->A2_NR)
            EndIf
            aCabec[34] := cEnd
        EndIf
    EndIf

    RestArea(aArea)
Return aCabec

/*/{Protheus.doc} ZPRVIt
Carrega os itens da NF (SD2 + SB1) em um array posicional
para exibicao no LISTBOX da tela de preview.

Estrutura do array retornado (13 colunas por item):
[01] D2_ITEM      [02] D2_COD       [03] B1_DESC
[04] D2_POSIPI    [05] D2_CST       [06] D2_CF
[07] D2_UM        [08] D2_QUANT     [09] D2_PRCVEN
[10] D2_TOTAL     [11] D2_BASEICM   [12] D2_VALICM
[13] D2_VALIPI

@type  Static Function
@param cSerie,  Caractere, Serie da NF
@param cNumero, Caractere, Numero da NF
@return aItens, Array, Itens da NF (vazio se nao encontrados)
/*/
Static Function ZPRVIt(cSerie, cNumero)
    Local aItens  := {}
    Local aArea   := GetArea()
    Local cDescri := ""

    DbSelectArea("SD2")
    DbSetOrder(1)
    If !DbSeek(xFilial("SD2") + cNumero + cSerie)
        RestArea(aArea)
        Return aItens
    EndIf

    While !SD2->(Eof()) .And. SD2->D2_DOC == cNumero .And. SD2->D2_SERIE == cSerie
        If SD2->(FieldPos("D_E_L_E_T_")) > 0
            If SD2->D_E_L_E_T_ != " "
                SD2->(DbSkip())
                Loop
            EndIf
        EndIf

        cDescri := Posicione("SB1", 1, xFilial("SB1") + SD2->D2_COD, "B1_DESC")

        aAdd(aItens, { ;
            SD2->D2_ITEM, ;
            SD2->D2_COD, ;
            cDescri, ;
            Posicione("SB1", 1, xFilial("SB1") + SD2->D2_COD, "B1_POSIPI"), ;
            SD2->D2_CST, ;
            SD2->D2_CF, ;
            SD2->D2_UM, ;
            SD2->D2_QUANT, ;
            SD2->D2_PRCVEN, ;
            SD2->D2_TOTAL, ;
            SD2->D2_BASEICM, ;
            SD2->D2_VALICM, ;
            SD2->D2_VALIPI ;
        })

        SD2->(DbSkip())
    EndDo

    RestArea(aArea)
Return aItens
