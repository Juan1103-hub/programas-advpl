#include "protheus.ch"
#include "topconn.ch"
#include "rptdef.ch"
#include "fwprintsetup.ch"

/*/{Protheus.doc} NFEPREVTS
Ponto de entrada acionado pelo menu "Outras Acoes" do Pedido de
Venda (MATA410). Gera preview do DANFE oficial a partir do XML
montado diretamente das tabelas Protheus (SF2, SD2, SA1, SA4, SM0),
parseado via XmlParser, e renderizado com layout identico ao danfeii.prw.

Fluxo:
1. ParamBox - Numero NF (9) + Serie (3)
2. Busca SF2 - cTipo, cCliFor, cLoja, cChave
3. NPT_MontaXml() - monta XML NFe 4.00 das tabelas
4. XmlParser() - parse XML em objeto com alias "_"
5. NFPS_RenderDanfe() - renderiza DANFE oficial

@type    User Function
@version 12.1.33
@author  Vortice
@since   03/07/2026
@example U_NFEPREVTS()
/*/
User Function NFEPREVTS(cSerie, cNumero, lChamaPrev)
    Local aArea   := GetArea()
    Local aRet    := {}
    Local aPergs  := {}
    Local lRet    := .T.
    Local cTipo   := "1"
    Local cCliFo  := ""
    Local cLoja   := ""
    Local cChave  := ""
    Local cXml    := ""
    Local cAviso  := ""
    Local cErro   := ""
    Local oNFe    := Nil

    ConOut("[NFEPREVTS] >>>>> INICIO <<<<<")

    If lChamaPrev == Nil
        lChamaPrev := .T.
    EndIf

    If cSerie == Nil .Or. cNumero == Nil
        cNumero := ""
        cSerie  := ""

        aAdd(aPergs, {1, "Numero NF", Space(9), "", "", "", "", 20, .T.})
        aAdd(aPergs, {1, "Serie", Space(3), "", "", "", "", 10, .T.})

        If ParamBox(aPergs, "Preview NF-e - Informe a NF", @aRet, , , , , , , , .T., .F.)
            cNumero := AllTrim(aRet[1])
            cSerie  := AllTrim(aRet[2])

            If Empty(cNumero) .Or. Empty(cSerie)
                MsgAlert("Informe o numero e a serie da NF.", "Atencao")
                RestArea(aArea)
                Return
            EndIf
        Else
            RestArea(aArea)
            Return
        EndIf
    Else
        cSerie  := AllTrim(cSerie)
        cNumero := AllTrim(cNumero)
        ConOut("[NFEPREVTS] Parametros via argumento: NF " + cNumero + "/" + cSerie)
    EndIf

    ConOut("[NFEPREVTS] Buscando SF2: NF=" + cNumero + " Serie=" + cSerie)

    DbSelectArea("SF2")
    DbSetOrder(1)
    If DbSeek(xFilial("SF2") + cNumero + cSerie)
        cCliFo := AllTrim(SF2->F2_CLIENTE)
        cLoja  := AllTrim(SF2->F2_LOJA)
        If SF2->F2_TIPO == "D"
            cTipo := "0"
        Else
            cTipo := "1"
        EndIf
        If SF2->(FieldPos("F2_CHVNFE")) > 0
            cChave := AllTrim(SF2->F2_CHVNFE)
        EndIf
        ConOut("[NFEPREVTS] SF2 OK - Cliente=" + cCliFo + " Loja=" + cLoja + " Tipo=" + cTipo)
    Else
        ConOut("[NFEPREVTS] SF2 NAO encontrado para NF " + cNumero + "/" + cSerie)
        MsgAlert("NF " + cNumero + "/" + cSerie + " nao encontrada no SF2.", "Atencao")
        RestArea(aArea)
        Return
    EndIf

    If lChamaPrev
        ConOut("[NFEPREVTS] Montando XML das tabelas...")

        cXml := NPT_MontaXml(cSerie, cNumero, cTipo, cCliFo, cLoja)

        If Empty(cXml)
            ConOut("[NFEPREVTS] ERRO: XML vazio para NF " + cNumero + "/" + cSerie)
            MsgAlert("Falha ao montar XML da NF-e. NF " + cNumero + "/" + cSerie, "Atencao")
            RestArea(aArea)
            Return
        EndIf

        ConOut("[NFEPREVTS] XML montado: " + cValToChar(Len(cXml)) + " bytes. Parseando...")

        oNFe := XmlParser(cXml, "_", @cAviso, @cErro)

        If !Empty(cAviso) .Or. !Empty(cErro)
            ConOut("[NFEPREVTS] ERRO XmlParser - Aviso=" + cAviso + " Erro=" + cErro)
            MsgAlert("Falha ao interpretar XML montado." + CRLF + ;
                     "Aviso: " + cAviso + CRLF + ;
                     "Erro: " + cErro, "Atencao")
            RestArea(aArea)
            Return
        EndIf

        ConOut("[NFEPREVTS] XML parseado OK - Renderizando DANFE")

        NFPS_RenderDanfe(cSerie, cNumero, cTipo, cChave, oNFe)

        ConOut("[NFEPREVTS] DANFE renderizado - concluido")

        If oNFe != Nil
            FreeObj(oNFe)
            oNFe := Nil
        EndIf
    EndIf

    ConOut("[NFEPREVTS] <<<<< FIM <<<<<")

    RestArea(aArea)
Return lRet

/*/{Protheus.doc} NPT_MontaXml
Monta XML NFe 4.00 a partir das tabelas Protheus (SF2, SD2, SA1, SA4, SM0).
O XML segue a estrutura padrao da NFe para que seja parseado por XmlParser
e renderizado por NFPS_RenderDanfe.

@type  Static Function
@param cSerie,   Caractere, Serie NF
@param cNumero,  Caractere, Numero NF
@param cTipo,    Caractere, "1"=Saida "0"=Entrada
@param cCliFor,  Caractere, Codigo cliente/fornecedor
@param cLoja,    Caractere, Loja
@return Caractere, XML da NFe ou vazio
/*/
Static Function NPT_MontaXml(cSerie, cNumero, cTipo, cCliFor, cLoja)
    Local cXml     := ""
    Local cItem    := ""
    Local cQuery   := ""
    Local cTabSD2  := RetSqlName("SD2")
    Local cFilSD2  := xFilial("SD2")
    Local cFilSB1  := xFilial("SB1")
    Local cFilSA1  := xFilial("SA1")
    Local cFilSA4  := xFilial("SA4")
    Local cDescItem := ""
    Local nItem    := 0
    Local nTotProd := 0
    Local nTotBC   := 0
    Local nTotICMS := 0
    Local nTotIPI  := 0
    Local nTotPIS  := 0
    Local nTotCOF  := 0
    Local nTotDesc := 0
    Local cDhEmi   := ""
    Local cNNF     := ""
    Local cSer     := ""
    Local cEmitNome := ""
    Local cEmitCNPJ := ""
    Local cEmitIE   := ""
    Local cEmitEnd  := ""
    Local cEmitNro  := ""
    Local cEmitBair := ""
    Local cEmitMun  := ""
    Local cEmitUF   := ""
    Local cEmitCEP  := ""
    Local cEmitFone := ""
    Local cDestNome := ""
    Local cDestCNPJ := ""
    Local cDestIE   := ""
    Local cDestEnd  := ""
    Local cDestNro  := ""
    Local cDestBair := ""
    Local cDestMun  := ""
    Local cDestUF   := ""
    Local cDestCEP  := ""
    Local cTransNome := ""
    Local cTransCNPJ := ""
    Local cTransIE   := ""
    Local cTransEnd  := ""
    Local cTransMun  := ""
    Local cTransUF   := ""
    Local cModFrete  := "0"
    Local aArea      := GetArea()

    cNNF := AllTrim(cNumero)
    cSer := AllTrim(cSerie)

    ConOut("[NPT_MontaXml] Inicio - NF=" + cNNF + " Serie=" + cSer)

    // Emitente - dados da empresa atual (SM0)
    SM0->(DbSetOrder(1))
    If SM0->(DbSeek(FwGrpCompany() + FwCodFil()))
        cEmitNome := AllTrim(SM0->M0_NOMECOM)
        cEmitCNPJ := AllTrim(SM0->M0_CGC)
        cEmitIE   := AllTrim(SM0->M0_INSC)
        cEmitEnd  := IIf(SM0->(FieldPos("M0_ENDENT"))  > 0, AllTrim(SM0->M0_ENDENT), "")
        cEmitBair := IIf(SM0->(FieldPos("M0_BAIRRENT"))> 0, AllTrim(SM0->M0_BAIRRENT), "")
        cEmitMun  := IIf(SM0->(FieldPos("M0_CIDENT"))  > 0, AllTrim(SM0->M0_CIDENT), "")
        cEmitUF   := IIf(SM0->(FieldPos("M0_ESTENT"))  > 0, AllTrim(SM0->M0_ESTENT), "")
        cEmitCEP  := IIf(SM0->(FieldPos("M0_CEPENT"))  > 0, AllTrim(SM0->M0_CEPENT), "")
        cEmitFone := IIf(SM0->(FieldPos("M0_TEL"))     > 0, AllTrim(SM0->M0_TEL), "")
        ConOut("[NPT_MontaXml] Emitente: " + cEmitNome + " CNPJ=" + cEmitCNPJ)
    Else
        ConOut("[NPT_MontaXml] ERRO: SM0 nao encontrou empresa atual")
    EndIf

    // Separar endereco do emitente em rua + numero
    cEmitNro := "S/N"
    If "," $ cEmitEnd
        cEmitNro := AllTrim(SubStr(cEmitEnd, RAt(",", cEmitEnd) + 1))
        cEmitEnd := AllTrim(SubStr(cEmitEnd, 1, RAt(",", cEmitEnd) - 1))
    EndIf

    // Destinatario - cliente (SA1)
    DbSelectArea("SA1")
    DbSetOrder(1)
    If DbSeek(cFilSA1 + cCliFor + cLoja)
        cDestNome := AllTrim(SA1->A1_NOME)
        cDestCNPJ := AllTrim(SA1->A1_CGC)
        cDestIE   := AllTrim(SA1->A1_INSCR)
        cDestEnd  := AllTrim(SA1->A1_END)
        cDestBair := AllTrim(SA1->A1_BAIRRO)
        cDestMun  := AllTrim(SA1->A1_MUN)
        cDestUF   := AllTrim(SA1->A1_EST)
        cDestCEP  := AllTrim(SA1->A1_CEP)
        ConOut("[NPT_MontaXml] Destinatario: " + cDestNome + " CNPJ=" + cDestCNPJ)
    Else
        ConOut("[NPT_MontaXml] SA1 nao encontrou cliente " + cCliFor + "/" + cLoja)
    EndIf

    // Separar endereco do destinatario em rua + numero
    cDestNro := "S/N"
    If "," $ cDestEnd
        cDestNro := AllTrim(SubStr(cDestEnd, RAt(",", cDestEnd) + 1))
        cDestEnd := AllTrim(SubStr(cDestEnd, 1, RAt(",", cDestEnd) - 1))
    EndIf

    // Transportadora (SA4)
    If !Empty(SF2->F2_TRANSP)
        DbSelectArea("SA4")
        DbSetOrder(1)
        If DbSeek(cFilSA4 + SF2->F2_TRANSP)
            cTransNome := AllTrim(SA4->A4_NOME)
            cTransCNPJ := AllTrim(SA4->A4_CGC)
            cTransIE   := AllTrim(SA4->A4_INSEST)
            cTransEnd  := AllTrim(SA4->A4_END) + " - " + AllTrim(SA4->A4_MUN) + "/" + AllTrim(SA4->A4_EST)
            cTransMun  := AllTrim(SA4->A4_MUN)
            cTransUF   := AllTrim(SA4->A4_EST)
            ConOut("[NPT_MontaXml] Transportadora: " + cTransNome)
        EndIf
    EndIf

    // Data/hora emissao formato ISO
    cDhEmi := SubStr(DtoS(Date()), 1, 4) + "-" + ;
              SubStr(DtoS(Date()), 5, 2) + "-" + ;
              SubStr(DtoS(Date()), 7, 2) + "T" + Time() + "-03:00"

    // Itens - consulta SD2 com descricao e NCM do cadastro (SB1)
    cQuery := "SELECT D2_COD, B1_DESC, B1_POSIPI, D2_CF, D2_UM, D2_QUANT, D2_TOTAL,"
    cQuery += " D2_BASEICM, D2_PICM, D2_VALIPI, D2_BASEIPI,"
    cQuery += " D2_TES, D2_LOCAL, D2_CLASFIS, D2_DESCON"
    cQuery += " FROM " + cTabSD2 + " D2"
    cQuery += " LEFT JOIN " + RetSqlName("SB1") + " B1"
    cQuery += " ON B1.B1_COD = D2.D2_COD AND B1.B1_FILIAL = '" + cFilSB1 + "' AND B1.D_E_L_E_T_ = ''"
    cQuery += " WHERE D2.D2_FILIAL = '" + cFilSD2 + "'"
    cQuery += " AND D2.D2_DOC = '" + cNNF + "'"
    cQuery += " AND D2.D2_SERIE = '" + cSer + "'"
    cQuery += " AND D2.D_E_L_E_T_ = ''"
    cQuery += " ORDER BY D2_ITEM"

    cQuery := ChangeQuery(cQuery)
    dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), "TRB_SD2", .T., .T.)

    nItem    := 0
    nTotProd := 0
    nTotBC   := 0
    nTotICMS := 0
    nTotIPI  := 0
    nTotPIS  := 0
    nTotCOF  := 0
    nTotDesc := 0

    // --- Cabecalho XML NFe 4.00 ---
    cXml := '<NFe>'
    cXml += '<infNfe versao="4.00">'
    cXml += '<ID>00000000000000000000000000000000000000000000</ID>'
    cXml += '<IDE>'
    cXml += '<natOp>VENDA DE MERCADORIA</natOp>'
    cXml += '<dhEmi>' + cDhEmi + '</dhEmi>'
    cXml += '<nNF>' + cNNF + '</nNF>'
    cXml += '<serie>' + cSer + '</serie>'
    cXml += '<tpNF>' + cTipo + '</tpNF>'
    cXml += '</IDE>'

    // Emitente
    cXml += '<Emit>'
    cXml += '<xNome>' + cEmitNome + '</xNome>'
    cXml += '<CNPJ>' + cEmitCNPJ + '</CNPJ>'
    cXml += '<IE>' + cEmitIE + '</IE>'
    cXml += '<EnderEmit>'
    cXml += '<xLgr>' + cEmitEnd + '</xLgr>'
    cXml += '<Nro>' + cEmitNro + '</Nro>'
    cXml += '<xBairro>' + cEmitBair + '</xBairro>'
    cXml += '<xMun>' + cEmitMun + '</xMun>'
    cXml += '<UF>' + cEmitUF + '</UF>'
    cXml += '<CEP>' + cEmitCEP + '</CEP>'
    cXml += '<Fone>' + cEmitFone + '</Fone>'
    cXml += '</EnderEmit>'
    cXml += '</Emit>'

    // Destinatario
    cXml += '<Dest>'
    cXml += '<xNome>' + cDestNome + '</xNome>'
    If Len(AllTrim(cDestCNPJ)) > 11
        cXml += '<CNPJ>' + cDestCNPJ + '</CNPJ>'
    Else
        cXml += '<CPF>' + cDestCNPJ + '</CPF>'
    EndIf
    cXml += '<IE>' + cDestIE + '</IE>'
    cXml += '<EnderDest>'
    cXml += '<xLgr>' + cDestEnd + '</xLgr>'
    cXml += '<Nro>' + cDestNro + '</Nro>'
    cXml += '<xBairro>' + cDestBair + '</xBairro>'
    cXml += '<xMun>' + cDestMun + '</xMun>'
    cXml += '<UF>' + cDestUF + '</UF>'
    cXml += '<CEP>' + cDestCEP + '</CEP>'
    cXml += '</EnderDest>'
    cXml += '</Dest>'

    // Itens
    ConOut("[NPT_MontaXml] Processando itens...")

    While !TRB_SD2->(Eof())
        nItem++
        nTotProd += TRB_SD2->D2_TOTAL
        nTotBC   += TRB_SD2->D2_BASEICM
        nTotICMS += 0
        nTotIPI  += TRB_SD2->D2_VALIPI
        nTotPIS  += 0
        nTotCOF  += 0
        nTotDesc += TRB_SD2->D2_DESCON

        cDescItem := AllTrim(TRB_SD2->B1_DESC)

        cItem := '<det nItem="' + cValToChar(nItem) + '">'
        cItem += '<prod>'
        cItem += '<cProd>' + AllTrim(TRB_SD2->D2_COD) + '</cProd>'
        cItem += '<xProd>' + cDescItem + '</xProd>'
        cItem += '<NCM>' + AllTrim(TRB_SD2->B1_POSIPI) + '</NCM>'
        cItem += '<CFOP>' + AllTrim(TRB_SD2->D2_CF) + '</CFOP>'
        cItem += '<uCom>' + AllTrim(TRB_SD2->D2_UM) + '</uCom>'
        cItem += '<qCom>' + NPT_FmtVal(TRB_SD2->D2_QUANT) + '</qCom>'
        cItem += '<vUnCom>' + NPT_FmtVal(IIf(TRB_SD2->D2_QUANT > 0, TRB_SD2->D2_TOTAL / TRB_SD2->D2_QUANT, 0)) + '</vUnCom>'
        cItem += '<vProd>' + NPT_FmtVal(TRB_SD2->D2_TOTAL) + '</vProd>'
        cItem += '</prod>'
        cItem += '<imposto>'
        cItem += '<ICMS>'
        cItem += '<ICMS00>'
        cItem += '<vBC>' + NPT_FmtVal(TRB_SD2->D2_BASEICM) + '</vBC>'
        cItem += '<pICMS>' + NPT_FmtVal(TRB_SD2->D2_PICM) + '</pICMS>'
        cItem += '<vICMS>0</vICMS>'
        cItem += '</ICMS00>'
        cItem += '</ICMS>'
        cItem += '</imposto>'
        cItem += '</det>'
        cXml += cItem

        TRB_SD2->(DbSkip())
    EndDo

    ConOut("[NPT_MontaXml] " + cValToChar(nItem) + " itens processados")

    TRB_SD2->(DbCloseArea())

    // Totais
    cXml += '<total>'
    cXml += '<ICMSTot>'
    cXml += '<vBC>' + NPT_FmtVal(nTotBC) + '</vBC>'
    cXml += '<vICMS>' + NPT_FmtVal(nTotICMS) + '</vICMS>'
    cXml += '<vProd>' + NPT_FmtVal(nTotProd) + '</vProd>'
    cXml += '<vFrete>' + NPT_FmtVal(SF2->F2_FRETE) + '</vFrete>'
    cXml += '<vSeg>' + NPT_FmtVal(SF2->F2_SEGURO) + '</vSeg>'
    cXml += '<vDesc>' + NPT_FmtVal(nTotDesc) + '</vDesc>'
    cXml += '<vIPI>' + NPT_FmtVal(nTotIPI) + '</vIPI>'
    cXml += '<vNF>' + NPT_FmtVal(SF2->F2_VALFAT) + '</vNF>'
    cXml += '<vPIS>' + NPT_FmtVal(nTotPIS) + '</vPIS>'
    cXml += '<vCOFINS>' + NPT_FmtVal(nTotCOF) + '</vCOFINS>'
    cXml += '</ICMSTot>'
    cXml += '</total>'

    // Transporte
    cXml += '<transp>'
    If !Empty(cTransNome)
        cXml += '<Transporta>'
        cXml += '<xNome>' + cTransNome + '</xNome>'
        cXml += '<CNPJ>' + cTransCNPJ + '</CNPJ>'
        cXml += '<IE>' + cTransIE + '</IE>'
        cXml += '<xEnder>' + cTransEnd + '</xEnder>'
        cXml += '<xMun>' + cTransMun + '</xMun>'
        cXml += '<UF>' + cTransUF + '</UF>'
        cXml += '</Transporta>'
    EndIf
    cXml += '<modFrete>' + cModFrete + '</modFrete>'
    cXml += '</transp>'

    // Informacoes Adicionais
    cXml += '<infAdic>'
    cXml += '<infCpl>Preview gerado em ' + DtoC(Date()) + ' as ' + Time() + " - NAO POSSUI VALIDADE FISCAL"
    cXml += '</infCpl>'
    cXml += '</infAdic>'

    cXml += '</infNfe>'
    cXml += '<infProt>'
    cXml += '<nProt></nProt>'
    cXml += '</infProt>'
    cXml += '</NFe>'

    ConOut("[NPT_MontaXml] XML final: " + cValToChar(Len(cXml)) + " bytes")

    RestArea(aArea)
Return cXml

/*/{Protheus.doc} NPT_FmtVal
Formata valor numerico para formato XML NFe (decimal com ponto,
sem separador de milhar). Exemplo: 1234.56

@type  Static Function
@param nVal, Numerico, Valor a formatar
@return Caractere, Valor formatado para XML
/*/
Static Function NPT_FmtVal(nVal)
    Local cRet := ""
    Local nInt := 0
    Local nDec := 0
    Local lNeg := .F.

    If ValType(nVal) <> "N"
        nVal := Val(AllTrim(cValToChar(nVal)))
    EndIf

    If nVal < 0
        lNeg := .T.
        nVal := Abs(nVal)
    EndIf

    nInt := Int(nVal)
    nDec := Round((nVal - nInt) * 100, 0)

    If nDec >= 100
        nInt := nInt + 1
        nDec := nDec - 100
    EndIf

    If lNeg
        cRet := "-" + AllTrim(Str(nInt)) + "." + StrZero(nDec, 2)
    Else
        cRet := AllTrim(Str(nInt)) + "." + StrZero(nDec, 2)
    EndIf
Return cRet

Static Function NFPS_RenderDanfe(cSerie, cNumero, cTipo, cChave, oNFe)
    Local oDanfe   := Nil
    Local oFont07  := Nil
    Local oFont07N := Nil
    Local oFont08  := Nil
    Local oFont08N := Nil
    Local oFont09  := Nil
    Local oFont09N := Nil
    Local oFont10  := Nil
    Local oFont10N := Nil
    Local oFont12N := Nil
    Local oFont18N := Nil
    Local cTitulo  := ""
    Local cLogo    := ""
    Local cLogoTvs := ""
    Local cStartP  := ""
    Local nLin     := 0
    Local nX       := 0
    Local nY       := 0
    Local nPag     := 1
    Local nTotPag  := 1
    Local oNF      := Nil
    Local oEmit    := Nil
    Local oIdent   := Nil
    Local oDest    := Nil
    Local oTotal   := Nil
    Local oTransp  := Nil
    Local oDet     := Nil
    Local oImp     := Nil
    Local cEmitNome := ""
    Local cEmitCNPJ := ""
    Local cEmitIE   := ""
    Local cEmitEnd  := ""
    Local cEmitBair := ""
    Local cEmitMun  := ""
    Local cEmitUF   := ""
    Local cEmitCEP  := ""
    Local cEmitFone := ""
    Local cDestNome := ""
    Local cDestCNPJ := ""
    Local cDestIE   := ""
    Local cDestEnd  := ""
    Local cDestBair := ""
    Local cDestMun  := ""
    Local cDestUF   := ""
    Local cDestCEP  := ""
    Local cChaveCont := ""
    Local cNatOp    := ""
    Local cDhEmi    := ""
    Local cNNF      := ""
    Local cSer      := ""
    Local cTpNF     := ""
    Local cProt     := ""
    Local cDadosProt := ""
    Local aItens    := {}
    Local aItem     := {}
    Local nTotVProd := 0
    Local nTotVFrete := 0
    Local nTotVSeg  := 0
    Local nTotVDesc := 0
    Local nTotVIPI  := 0
    Local nTotVNF   := 0
    Local nTotVBC   := 0
    Local nTotVICMS := 0
    Local nTotVPIS  := 0
    Local nTotVCOF  := 0
    Local nQtd       := 0
    Local nVUn       := 0
    Local nVProd     := 0
    Local cProd      := ""
    Local cDesc      := ""
    Local cNCM       := ""
    Local cCFOP      := ""
    Local cUN        := ""
    Local cCST       := ""
    Local nVBC       := 0
    Local nVICMS     := 0
    Local nVIPI      := 0
    Local nPICMS     := 0
    Local cTransNome := ""
    Local cTransCNPJ := ""
    Local cTransIE   := ""
    Local cTransEnd  := ""
    Local cModFrete  := ""
    Local cInfAd     := ""
    Local cInfFisco  := ""
    Local nMaxItem   := 18
    Local lNFCE      := .F.
    Local cAux       := ""
    Local nLinCalc   := 0
    Local cStrAux    := ""
    Local nForTo     := 0
    Local nAltura    := 16
    Local aDescLin   := {}

    If Empty(cChave)
        cTitulo := "DANFE - PREVIEW - NF-e " + cNumero + "/" + cSerie + " - PRE-TRANSMISSAO"
    Else
        cTitulo := "DANFE - NF-e " + cNumero + "/" + cSerie
    EndIf

    oNF     := oNFe:_NFe
    oIdent  := oNF:_InfNfe:_IDE
    oEmit   := oNF:_InfNfe:_Emit

    If AttIsMemberOf(oNF:_InfNfe, "_Dest")
        oDest := oNF:_InfNfe:_Dest
    EndIf
    oTotal  := oNF:_InfNfe:_Total
    If AttIsMemberOf(oNF:_InfNfe, "_Transp")
        oTransp := oNF:_InfNfe:_Transp
    EndIf
    oDet := oNF:_InfNfe:_Det
    If ValType(oDet) <> "A"
        oDet := {oDet}
    EndIf

    If AttIsMemberOf(oNF:_InfNfe, "_ID")
        lNFCE := SubStr(NPT_GetTxt(oNF:_InfNfe, "_ID"), 24, 2) == "65"
    Else
        lNFCE := .F.
    EndIf

    cEmitNome := NPT_GetTxt(oEmit, "_xNome")
    If AttIsMemberOf(oEmit, "_CNPJ")
        cEmitCNPJ := Transform(NPT_GetTxt(oEmit, "_CNPJ"), "@R! NN.NNN.NNN/NNNN-99")
    ElseIf AttIsMemberOf(oEmit, "_CPF")
        cEmitCNPJ := Transform(NPT_GetTxt(oEmit, "_CPF"), "@r 999.999.999-99")
    EndIf
    cEmitIE  := NPT_GetTxt(oEmit, "_IE")
    cEmitEnd := AllTrim(NPT_GetTxt(oEmit:_EnderEmit, "_xLgr")) + ", " + NPT_GetTxt(oEmit:_EnderEmit, "_Nro")
    cEmitBair:= NPT_GetTxt(oEmit:_EnderEmit, "_xBairro")
    cEmitMun := NPT_GetTxt(oEmit:_EnderEmit, "_xMun")
    cEmitUF  := NPT_GetTxt(oEmit:_EnderEmit, "_UF")
    cEmitCEP := Transform(NPT_GetTxt(oEmit:_EnderEmit, "_Cep"), "@R 99999-999")
    cEmitFone:= NPT_GetTxt(oEmit:_EnderEmit, "_Fone")

    If oDest <> Nil
        cDestNome := NPT_GetTxt(oDest, "_xNome")
        If AttIsMemberOf(oDest, "_CNPJ")
            cDestCNPJ := Transform(NPT_GetTxt(oDest, "_CNPJ"), "@R! NN.NNN.NNN/NNNN-99")
        ElseIf AttIsMemberOf(oDest, "_CPF")
            cDestCNPJ := Transform(NPT_GetTxt(oDest, "_CPF"), "@r 999.999.999-99")
        EndIf
        cDestIE   := NPT_GetTxt(oDest, "_IE")
        cDestEnd  := AllTrim(NPT_GetTxt(oDest:_EnderDest, "_xLgr")) + ", " + NPT_GetTxt(oDest:_EnderDest, "_Nro")
        cDestBair := NPT_GetTxt(oDest:_EnderDest, "_xBairro")
        cDestMun  := NPT_GetTxt(oDest:_EnderDest, "_xMun")
        cDestUF   := NPT_GetTxt(oDest:_EnderDest, "_UF")
        cDestCEP  := Transform(NPT_GetTxt(oDest:_EnderDest, "_Cep"), "@R 99999-999")
    EndIf

    cNatOp  := NPT_GetTxt(oIdent, "_NATOP")
    cDhEmi  := ""
    If AttIsMemberOf(oIdent, "_dhEmi")
        cDhEmi := oIdent:_dhEmi:Text
    EndIf
    If Empty(cDhEmi) .And. AttIsMemberOf(oIdent, "_dEmi")
        cDhEmi := oIdent:_dEmi:Text
    EndIf
    cNNF    := NPT_GetTxt(oIdent, "_nNF")
    cSer    := NPT_GetTxt(oIdent, "_serie")
    cTpNF   := NPT_GetTxt(oIdent, "_tpNF")
    cProt   := ""
    If AttIsMemberOf(oNF:_InfNfe, "_infProt")
        cProt := NPT_GetTxt(oNF:_InfNfe:_infProt, "_nProt")
    EndIf

    If AttIsMemberOf(oTotal, "_ICMSTot")
        nTotVBC   := Val(StrTran(NPT_GetTxt(oTotal:_ICMSTot, "_vBC"), ".", "")) / 100
        nTotVICMS := Val(StrTran(NPT_GetTxt(oTotal:_ICMSTot, "_vICMS"), ".", "")) / 100
        nTotVProd := Val(StrTran(NPT_GetTxt(oTotal:_ICMSTot, "_vProd"), ".", "")) / 100
        nTotVFrete:= Val(StrTran(NPT_GetTxt(oTotal:_ICMSTot, "_vFrete"), ".", "")) / 100
        nTotVSeg  := Val(StrTran(NPT_GetTxt(oTotal:_ICMSTot, "_vSeg"), ".", "")) / 100
        nTotVDesc := Val(StrTran(NPT_GetTxt(oTotal:_ICMSTot, "_vDesc"), ".", "")) / 100
        nTotVIPI  := Val(StrTran(NPT_GetTxt(oTotal:_ICMSTot, "_vIPI"), ".", "")) / 100
        nTotVNF   := Val(StrTran(NPT_GetTxt(oTotal:_ICMSTot, "_vNF"), ".", "")) / 100
        nTotVPIS  := Val(StrTran(NPT_GetTxt(oTotal:_ICMSTot, "_vPIS"), ".", "")) / 100
        nTotVCOF  := Val(StrTran(NPT_GetTxt(oTotal:_ICMSTot, "_vCOFINS"), ".", "")) / 100
    EndIf

    For nY := 1 To Len(oDet)
        oImp := oDet[nY]:_Imposto

        cProd  := NPT_GetTxt(oDet[nY]:_Prod, "_cProd")
        cDesc  := NPT_GetTxt(oDet[nY]:_Prod, "_xProd")
        cNCM   := NPT_GetTxt(oDet[nY]:_Prod, "_NCM")
        cCFOP  := NPT_GetTxt(oDet[nY]:_Prod, "_CFOP")
        cUN    := NPT_GetTxt(oDet[nY]:_Prod, "_uCom")
        nQtd   := Val(StrTran(NPT_GetTxt(oDet[nY]:_Prod, "_qCom"), ".", "")) / 100
        nVUn   := Val(StrTran(NPT_GetTxt(oDet[nY]:_Prod, "_vUnCom"), ".", "")) / 100
        nVProd := Val(StrTran(NPT_GetTxt(oDet[nY]:_Prod, "_vProd"), ".", "")) / 100

        nVBC   := NPT_ICMSBC(oImp)
        nVICMS := NPT_ICMSV(oImp)
        nPICMS := NPT_ICMSP(oImp)
        nVIPI  := NPT_IPIV(oImp)

        cCST := ""
        If AttIsMemberOf(oImp, "_ICMS")
            If AttIsMemberOf(oImp:_ICMS, "_ICMS00")
                cCST := "00"
            ElseIf AttIsMemberOf(oImp:_ICMS, "_ICMS10")
                cCST := "10"
            ElseIf AttIsMemberOf(oImp:_ICMS, "_ICMS20")
                cCST := "20"
            ElseIf AttIsMemberOf(oImp:_ICMS, "_ICMS30")
                cCST := "30"
            ElseIf AttIsMemberOf(oImp:_ICMS, "_ICMS40")
                cCST := "40"
            ElseIf AttIsMemberOf(oImp:_ICMS, "_ICMS51")
                cCST := "51"
            ElseIf AttIsMemberOf(oImp:_ICMS, "_ICMS60")
                cCST := "60"
            ElseIf AttIsMemberOf(oImp:_ICMS, "_ICMS70")
                cCST := "70"
            ElseIf AttIsMemberOf(oImp:_ICMS, "_ICMS90")
                cCST := "90"
            ElseIf AttIsMemberOf(oImp:_ICMS, "_ICMSSN101")
                cCST := "101"
            ElseIf AttIsMemberOf(oImp:_ICMS, "_ICMSSN102")
                cCST := "102"
            ElseIf AttIsMemberOf(oImp:_ICMS, "_ICMSSN201")
                cCST := "201"
            ElseIf AttIsMemberOf(oImp:_ICMS, "_ICMSSN202")
                cCST := "202"
            ElseIf AttIsMemberOf(oImp:_ICMS, "_ICMSSN500")
                cCST := "500"
            EndIf
        EndIf

        AAdd(aItens, {PadR(cProd, 15), SubStr(cDesc, 1, 102), PadR(cNCM, 8), PadR(cCFOP, 4), PadR(cCST, 4), ;
                       PadR(cUN, 4), AllTrim(Str(nQtd, 12, 4)), StrTran(AllTrim(Str(nVUn, 14, 4)), ".", ","), ;
                       Transform(nVProd, "@E 9,999,999.99"), Transform(nVBC, "@E 9,999,999.99"), ;
                       Transform(nVICMS, "@E 999,999.99"), AllTrim(Str(nPICMS, 7, 2)) + "%", ;
                       AllTrim(Str(nVIPI, 14, 2)), AllTrim(Str(0, 4, 2)) + "%"})
    Next

    If oTransp <> Nil
        If AttIsMemberOf(oTransp, "_Transporta")
            cTransNome := NPT_GetTxt(oTransp:_Transporta, "_xNome")
            If AttIsMemberOf(oTransp:_Transporta, "_CNPJ")
                cTransCNPJ := Transform(NPT_GetTxt(oTransp:_Transporta, "_CNPJ"), "@R! NN.NNN.NNN/NNNN-99")
            EndIf
            cTransIE  := NPT_GetTxt(oTransp:_Transporta, "_IE")
            cTransEnd := AllTrim(NPT_GetTxt(oTransp:_Transporta, "_xEnder")) + " - " + ;
                         NPT_GetTxt(oTransp:_Transporta, "_xMun") + "/" + NPT_GetTxt(oTransp:_Transporta, "_UF")
        EndIf
        If AttIsMemberOf(oTransp, "_modFrete")
            cModFrete := oTransp:_modFrete:Text
        EndIf
    EndIf

    If AttIsMemberOf(oNF:_InfNfe, "_infAdic")
        cInfAd    := NPT_GetTxt(oNF:_InfNfe:_infAdic, "_infCpl")
        cInfFisco := NPT_GetTxt(oNF:_InfNfe:_infAdic, "_infAdFisco")
    EndIf

    cLogo    := FisxLogo("1")
    cLogoTvs := "Powered_by_TOTVS.bmp"
    cStartP  := GetSrvProfString("Startpath", "")

    oDanfe := FWMSPrinter():New(cTitulo, IMP_PDF, .F., , .T.)
    oDanfe:SetPortrait()
    oDanfe:SetPaperSize(DMPAPER_A4)
    oDanfe:SetMargin(15, 15, 15, 15)
    oDanfe:SetResolution(72)

    oFont07  := TFontEx():New(oDanfe, "Times New Roman", 06, 06, .F., .F., .F.)
    oFont07N := TFontEx():New(oDanfe, "Times New Roman", 06, 06, .T., .F., .F.)
    oFont08  := TFontEx():New(oDanfe, "Times New Roman", 07, 07, .F., .F., .F.)
    oFont08N := TFontEx():New(oDanfe, "Times New Roman", 07, 07, .T., .F., .F.)
    oFont09  := TFontEx():New(oDanfe, "Times New Roman", 08, 08, .F., .F., .F.)
    oFont09N := TFontEx():New(oDanfe, "Times New Roman", 08, 08, .T., .F., .F.)
    oFont10  := TFontEx():New(oDanfe, "Times New Roman", 09, 09, .F., .F., .F.)
    oFont10N := TFontEx():New(oDanfe, "Times New Roman", 09, 09, .T., .F., .F.)
    oFont12N := TFontEx():New(oDanfe, "Times New Roman", 11, 11, .T., .F., .F.)
    oFont18N := TFontEx():New(oDanfe, "Times New Roman", 17, 17, .T., .F., .F.)
    oDanfe:StartPage()

    // === RECIBO DE ENTREGA (Y=0-37) ===
    oDanfe:Box(000, 000, 010, 501)
    oDanfe:Say(006, 002, "RECEBEMOS DE " + cEmitNome + " OS PRODUTOS CONSTANTES DA NOTA FISCAL INDICADA AO LADO", oFont07:oFont)
    oDanfe:Box(009, 000, 037, 101)
    oDanfe:Say(017, 002, "DATA DE RECEBIMENTO", oFont07N:oFont)
    oDanfe:Box(009, 100, 037, 500)
    oDanfe:Say(017, 102, "IDENTIFICACAO E ASSINATURA DO RECEBEDOR", oFont07N:oFont)
    oDanfe:Box(000, 500, 037, 563)
    oDanfe:Say(007, 542, iif(lNFCE, "NFC-e", "NF-e"), oFont08N:oFont)
    oDanfe:Say(017, 510, "N. " + StrZero(Val(cNNF), 9), oFont08:oFont)
    oDanfe:Say(027, 510, "SERIE " + SubStr(cSer, 1, 3), oFont08:oFont)

    // === EMITENTE (Y=42-137, X=0-250) ===
    oDanfe:Box(042, 000, 137, 250)
    oDanfe:Say(052, 096, "Identificacao do emitente", oFont12N:oFont)
    nLinCalc := 065
    cStrAux := cEmitNome
    nForTo := Len(cStrAux) / 32
    nForTo := Iif(nForTo > Round(nForTo, 0), Round(nForTo, 0) + 1, Round(nForTo, 0))
    For nX := 1 To nForTo
        oDanfe:Say(nLinCalc, 096, SubStr(cStrAux, Iif(nX == 1, 1, ((nX - 1) * 32) + 1), 32), oFont08N:oFont)
        nLinCalc += 10
    Next nX

    cStrAux := cEmitEnd
    nForTo := Len(cStrAux) / 40
    nForTo += Iif(nForTo > Round(nForTo, 0), Round(nForTo, 0) + 1 - nForTo, nForTo)
    For nX := 1 To nForTo
        oDanfe:Say(nLinCalc, 096, SubStr(cStrAux, Iif(nX == 1, 1, ((nX - 1) * 40) + 1), 40), oFont08N:oFont)
        nLinCalc += 10
    Next nX

    oDanfe:Say(nLinCalc, 096, cEmitBair + " Cep: " + cEmitCEP, oFont08N:oFont)
    nLinCalc += 10
    oDanfe:Say(nLinCalc, 096, cEmitMun + "/" + cEmitUF, oFont08N:oFont)
    nLinCalc += 9
    oDanfe:Say(nLinCalc, 096, "Fone: " + cEmitFone, oFont08N:oFont)

    // === DANFE BOX (Y=42-137, X=248-351) ===
    oDanfe:Box(042, 248, 137, 351)
    oDanfe:Say(055, 275, "DANFE", oFont12N:oFont)
    oDanfe:Say(065, 258, "DOCUMENTO AUXILIAR DA", oFont07:oFont)
    If lNFCE
        oDanfe:Say(075, 258, "NOTA FISCAL DE CONSUMIDOR", oFont07:oFont)
    Else
        oDanfe:Say(075, 258, "NOTA FISCAL ELETRONICA", oFont07:oFont)
    EndIf
    oDanfe:Say(085, 266, "0-ENTRADA", oFont08:oFont)
    oDanfe:Say(095, 266, "1-SAIDA", oFont08:oFont)
    oDanfe:Box(078, 315, 095, 325)
    oDanfe:Say(089, 318, cTpNF, oFont08N:oFont)
    oDanfe:Say(110, 255, "N. " + StrZero(Val(cNNF), 9), oFont10N:oFont)
    oDanfe:Say(120, 255, "SERIE " + SubStr(cSer, 1, 3), oFont10N:oFont)
    oDanfe:Say(130, 255, "FOLHA " + StrZero(nPag, 2) + "/" + StrZero(nTotPag, 2), oFont10N:oFont)

    // === CHAVE DE ACESSO (Y=42-137, X=350-563) ===
    oDanfe:Box(042, 350, 076, 563)
    oDanfe:Box(076, 350, 108, 563)
    oDanfe:Box(108, 350, 137, 563)
    If nPag == 1
        oDanfe:Say(079, 355, "CHAVE DE ACESSO DA " + IIf(lNFCE, "NFC-E", "NF-E"), oFont09N:oFont)
    EndIf
    If !Empty(cChave)
        oDanfe:Say(093, 352, Transform(SubStr(cChave, 1), "@r 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999"), oFont09N:oFont)
    Else
        oDanfe:Say(093, 352, "[NF-E NAO TRANSMITIDA - PREVIEW SEM VALOR FISCAL]", oFont09N:oFont)
    EndIf
    oDanfe:Say(113, 355, "Consulta de autenticidade no portal nacional da " + IIf(lNFCE, "NFC-e", "NF-e"), oFont09:oFont)
    oDanfe:Say(125, 355, "www.nfe.fazenda.gov.br/portal ou no site da SEFAZ Autorizada", oFont09:oFont)

    // === LOGO ===
    If nPag == 1
        oDanfe:SayBitmap(045, 003, cLogo, 090, 090)
    EndIf

    // === NATUREZA DA OPERACAO (Y=139-162) ===
    oDanfe:Box(139, 000, 162, 563)
    oDanfe:Box(139, 000, 162, 350)
    oDanfe:Say(148, 002, "NATUREZA DA OPERACAO", oFont08N:oFont)
    oDanfe:Say(158, 002, cNatOp, oFont08:oFont)

    If !Empty(cChave) .And. !Empty(cProt)
        oDanfe:Say(148, 352, "PROTOCOLO DE AUTORIZACAO DE USO", oFont08N:oFont)
        oDanfe:Say(158, 354, cProt + " - " + ConvDate(cDhEmi), oFont08:oFont)
    Else
        oDanfe:Say(148, 352, "PROTOCOLO DE AUTORIZACAO DE USO", oFont08N:oFont)
        oDanfe:Say(158, 354, "[PENDENTE DE TRANSMISSAO]", oFont08:oFont)
    EndIf

    // === INSCRICAO ESTADUAL (Y=164-187) ===
    oDanfe:Box(164, 000, 187, 563)
    oDanfe:Box(164, 000, 187, 200)
    oDanfe:Box(164, 200, 187, 400)
    oDanfe:Box(164, 400, 187, 563)
    oDanfe:Say(172, 002, "INSCRICAO ESTADUAL", oFont08N:oFont)
    oDanfe:Say(180, 002, cEmitIE, oFont08:oFont)
    oDanfe:Say(172, 205, "INSC.ESTADUAL DO SUBST.TRIB.", oFont08N:oFont)
    oDanfe:Say(180, 205, "", oFont08:oFont)
    oDanfe:Say(172, 405, "CNPJ/CPF", oFont08N:oFont)
    oDanfe:Say(180, 405, cEmitCNPJ, oFont08:oFont)

    // === DESTINATARIO (Y=195-257) ===
    oDanfe:Say(195, 002, "DESTINATARIO/REMETENTE", oFont08N:oFont)

    If oDest <> Nil
        // Nome/Razao Social
        oDanfe:Box(197, 000, 217, 280)
        oDanfe:Say(205, 002, "NOME/RAZAO SOCIAL", oFont08N:oFont)
        oDanfe:Say(215, 002, cDestNome, oFont08:oFont)

        // CNPJ/CPF
        oDanfe:Box(197, 280, 217, 490)
        oDanfe:Say(205, 283, "CNPJ/CPF", oFont08N:oFont)
        oDanfe:Say(215, 283, cDestCNPJ, oFont08:oFont)

        // Endereco
        oDanfe:Box(217, 000, 237, 490)
        oDanfe:Box(217, 000, 237, 260)
        oDanfe:Say(224, 002, "ENDERECO", oFont08N:oFont)
        oDanfe:Say(234, 002, cDestEnd, oFont08:oFont)

        // Bairro
        oDanfe:Box(217, 230, 237, 380)
        oDanfe:Say(224, 232, "BAIRRO/DISTRITO", oFont08N:oFont)
        oDanfe:Say(234, 232, cDestBair, oFont08:oFont)

        // CEP
        oDanfe:Box(217, 380, 237, 490)
        oDanfe:Say(224, 382, "CEP", oFont08N:oFont)
        oDanfe:Say(234, 382, cDestCEP, oFont08:oFont)

        // Municipio
        oDanfe:Box(236, 000, 257, 490)
        oDanfe:Box(236, 000, 257, 180)
        oDanfe:Say(245, 002, "MUNICIPIO", oFont08N:oFont)
        oDanfe:Say(255, 002, cDestMun, oFont08:oFont)

        // Fone
        oDanfe:Box(236, 150, 257, 256)
        oDanfe:Say(245, 152, "FONE/FAX", oFont08N:oFont)
        oDanfe:Say(255, 152, "", oFont08:oFont)

        // UF
        oDanfe:Box(236, 255, 257, 341)
        oDanfe:Say(245, 257, "UF", oFont08N:oFont)
        oDanfe:Say(255, 257, cDestUF, oFont08:oFont)

        // Inscricao Estadual
        oDanfe:Box(236, 340, 257, 490)
        oDanfe:Say(245, 342, "INSCRICAO ESTADUAL", oFont08N:oFont)
        oDanfe:Say(255, 342, cDestIE, oFont08:oFont)

        // Data Emissao
        oDanfe:Box(197, 490, 217, 563)
        oDanfe:Say(205, 492, "DATA DE EMISSAO", oFont08N:oFont)
        oDanfe:Say(215, 492, ConvDate(cDhEmi), oFont08:oFont)

        // Data Entrada/Saida
        oDanfe:Box(217, 490, 237, 563)
        oDanfe:Say(224, 492, "DATA ENTRADA/SAIDA", oFont08N:oFont)
        oDanfe:Say(233, 492, "", oFont08:oFont)

        // Hora Entrada/Saida
        oDanfe:Box(236, 490, 257, 563)
        oDanfe:Say(243, 491, "HORA ENTRADA/SAIDA", oFont08N:oFont)
        oDanfe:Say(252, 491, "", oFont08:oFont)
    EndIf

    // === FATURA (Y=259-297) ===
    oDanfe:Say(262, 002, "FATURA", oFont08N:oFont)
    oDanfe:Box(268, 000, 296, 094)
    oDanfe:Box(268, 094, 296, 188)
    oDanfe:Box(268, 188, 296, 282)
    oDanfe:Box(268, 282, 296, 376)
    oDanfe:Box(268, 376, 296, 470)
    oDanfe:Box(268, 470, 296, 563)

    // === CALCULO DO IMPOSTO (Y=305-353) ===
    oDanfe:Say(305, 002, "CALCULO DO IMPOSTO", oFont08N:oFont)

    oDanfe:Box(307, 000, 330, 121)
    oDanfe:Say(316, 002, "BASE DE CALCULO DO ICMS", oFont08N:oFont)
    oDanfe:Say(326, 002, Transform(nTotVBC, "@E 9,999,999.99"), oFont08:oFont)

    oDanfe:Box(307, 120, 330, 200)
    oDanfe:Say(316, 125, "VALOR DO ICMS", oFont08N:oFont)
    oDanfe:Say(326, 125, Transform(nTotVICMS, "@E 9,999,999.99"), oFont08:oFont)

    oDanfe:Box(307, 199, 330, 360)
    oDanfe:Say(316, 200, "BASE DE CALCULO DO ICMS SUBSTITUICAO", oFont08N:oFont)
    oDanfe:Say(326, 202, "0,00", oFont08:oFont)

    oDanfe:Box(307, 360, 330, 470)
    oDanfe:Say(316, 363, "VALOR DO ICMS SUBSTITUICAO", oFont08N:oFont)
    oDanfe:Say(326, 363, "0,00", oFont08:oFont)

    oDanfe:Box(307, 470, 330, 563)
    oDanfe:Say(316, 472, "VALOR TOTAL DOS PRODUTOS", oFont07N:oFont)
    oDanfe:Say(327, 472, Transform(nTotVProd, "@E 9,999,999.99"), oFont08:oFont)

    oDanfe:Box(330, 000, 353, 110)
    oDanfe:Say(339, 002, "VALOR DO FRETE", oFont08N:oFont)
    oDanfe:Say(349, 002, Transform(nTotVFrete, "@E 9,999,999.99"), oFont08:oFont)

    oDanfe:Box(330, 100, 353, 190)
    oDanfe:Say(339, 102, "VALOR DO SEGURO", oFont08N:oFont)
    oDanfe:Say(349, 102, Transform(nTotVSeg, "@E 9,999,999.99"), oFont08:oFont)

    oDanfe:Box(330, 190, 353, 290)
    oDanfe:Say(339, 194, "DESCONTO", oFont08N:oFont)
    oDanfe:Say(349, 194, Transform(nTotVDesc, "@E 9,999,999.99"), oFont08:oFont)

    oDanfe:Box(330, 290, 353, 415)
    oDanfe:Say(339, 295, "OUTRAS DESPESAS ACESSORIAS", oFont08N:oFont)
    oDanfe:Say(349, 295, "0,00", oFont08:oFont)

    oDanfe:Box(330, 414, 353, 490)
    oDanfe:Say(339, 420, "VALOR DO IPI", oFont08N:oFont)
    oDanfe:Say(349, 420, Transform(nTotVIPI, "@E 9,999,999.99"), oFont08:oFont)

    oDanfe:Box(330, 490, 353, 563)
    oDanfe:Say(339, 492, "VALOR TOTAL DA NOTA", oFont07N:oFont)
    oDanfe:Say(349, 492, Transform(nTotVNF, "@E 9,999,999.99"), oFont08:oFont)

    // === TRANSPORTADOR (Y=361-432) ===
    oDanfe:Say(361, 002, "TRANSPORTADOR/VOLUMES TRANSPORTADOS", oFont08N:oFont)

    oDanfe:Box(363, 000, 386, 563)
    oDanfe:Say(372, 002, "RAZAO SOCIAL", oFont08N:oFont)
    oDanfe:Say(382, 002, cTransNome, oFont08:oFont)

    oDanfe:Box(363, 243, 386, 315)
    oDanfe:Say(372, 245, "FRETE POR CONTA", oFont08N:oFont)
    Do Case
        Case cModFrete == "0"
            oDanfe:Say(382, 245, "0-REMETENTE", oFont08:oFont)
        Case cModFrete == "1"
            oDanfe:Say(382, 245, "1-DESTINATARIO", oFont08:oFont)
        Case cModFrete == "2"
            oDanfe:Say(382, 245, "2-TERCEIROS", oFont08:oFont)
        Case cModFrete == "9"
            oDanfe:Say(382, 245, "9-SEM FRETE", oFont08:oFont)
        OtherWise
            oDanfe:Say(382, 245, "", oFont08:oFont)
    EndCase

    oDanfe:Box(363, 315, 386, 370)
    oDanfe:Say(372, 317, "CODIGO ANTT", oFont08N:oFont)
    oDanfe:Say(382, 319, "", oFont08:oFont)

    oDanfe:Box(363, 370, 386, 450)
    oDanfe:Say(372, 375, "PLACA DO VEICULO", oFont08N:oFont)
    oDanfe:Say(382, 375, "", oFont08:oFont)

    oDanfe:Box(363, 450, 386, 495)
    oDanfe:Say(372, 452, "UF", oFont08N:oFont)
    oDanfe:Say(382, 452, "", oFont08:oFont)

    oDanfe:Box(363, 495, 386, 563)
    oDanfe:Say(372, 497, "CNPJ/CPF", oFont08N:oFont)
    oDanfe:Say(382, 497, cTransCNPJ, oFont08:oFont)

    oDanfe:Box(385, 000, 409, 563)
    oDanfe:Box(385, 000, 409, 241)
    oDanfe:Say(393, 002, "ENDERECO", oFont08N:oFont)
    oDanfe:Say(404, 002, cTransEnd, oFont08:oFont)

    oDanfe:Box(385, 240, 409, 341)
    oDanfe:Say(393, 242, "MUNICIPIO", oFont08N:oFont)
    oDanfe:Say(404, 242, "", oFont08:oFont)

    oDanfe:Box(385, 340, 409, 440)
    oDanfe:Say(393, 342, "UF", oFont08N:oFont)
    oDanfe:Say(404, 342, "", oFont08:oFont)

    oDanfe:Box(385, 440, 409, 563)
    oDanfe:Say(393, 442, "INSCRICAO ESTADUAL", oFont08N:oFont)
    oDanfe:Say(404, 442, cTransIE, oFont08:oFont)

    oDanfe:Box(408, 000, 432, 563)
    oDanfe:Box(408, 000, 432, 070)
    oDanfe:Say(418, 002, "QUANTIDADE", oFont08N:oFont)
    oDanfe:Say(428, 002, "", oFont08:oFont)

    oDanfe:Box(408, 070, 432, 200)
    oDanfe:Say(418, 072, "ESPECIE", oFont08N:oFont)
    oDanfe:Say(428, 072, "", oFont08:oFont)

    oDanfe:Box(408, 200, 432, 300)
    oDanfe:Say(418, 202, "MARCA", oFont08N:oFont)
    oDanfe:Say(428, 202, "", oFont08:oFont)

    oDanfe:Box(408, 300, 432, 400)
    oDanfe:Say(418, 302, "NUMERACAO", oFont08N:oFont)
    oDanfe:Say(428, 302, "", oFont08:oFont)

    oDanfe:Box(408, 400, 432, 480)
    oDanfe:Say(418, 402, "PESO BRUTO", oFont08N:oFont)
    oDanfe:Say(428, 402, "", oFont08:oFont)

    oDanfe:Box(408, 480, 432, 563)
    oDanfe:Say(418, 482, "PESO LIQUIDO", oFont08N:oFont)
    oDanfe:Say(428, 482, "", oFont08:oFont)

    // === DADOS DO PRODUTO (Y=440-678) ===
    NPT_GridCab(oDanfe, oFont08N)

    // Itens do grid
    nLinha := 460
    For nY := 1 To Len(aItens)
        aItem := aItens[nY]

		aDescLin := NPT_QuebraDesc(aItem[2], 36)

        nAltura := 16
        If Len(aDescLin) == 2
            nAltura := 18
        ElseIf Len(aDescLin) >= 3
            nAltura := 26
        EndIf

        If nLinha + nAltura - 1 > 676
            oDanfe:EndPage()
            oDanfe:StartPage()
            NPT_GridCab(oDanfe, oFont08N)
            nLinha := 460
            nTotPag++
        EndIf

        nAuxH := 0
        oDanfe:Say(nLinha, nAuxH + 2, aItem[1], oFont08:oFont)
        nAuxH += 48

        For nForTo := 1 To Len(aDescLin)
            oDanfe:Say(nLinha + (nForTo - 1) * 8, nAuxH + 2, aDescLin[nForTo], oFont08:oFont)
        Next
        nAuxH += 126

        oDanfe:Say(nLinha, nAuxH + 2, aItem[3], oFont08:oFont)
        nAuxH += 42

        oDanfe:Say(nLinha, nAuxH + 2, aItem[5], oFont08:oFont)
        nAuxH += 22

        oDanfe:Say(nLinha, nAuxH + 2, aItem[4], oFont08:oFont)
        nAuxH += 28

        oDanfe:Say(nLinha, nAuxH + 2, aItem[6], oFont08:oFont)
        nAuxH += 18

        oDanfe:Say(nLinha, nAuxH + 2, aItem[7], oFont08:oFont)
        nAuxH += 30

        oDanfe:Say(nLinha, nAuxH + 2, aItem[8], oFont08:oFont)
        nAuxH += 40

        oDanfe:Say(nLinha, nAuxH + 2, aItem[9], oFont08:oFont)
        nAuxH += 42

        oDanfe:Say(nLinha, nAuxH + 2, aItem[10], oFont08:oFont)
        nAuxH += 36

        oDanfe:Say(nLinha, nAuxH + 2, aItem[11], oFont08:oFont)
        nAuxH += 36

        oDanfe:Say(nLinha, nAuxH + 2, aItem[13], oFont08:oFont)
        nAuxH += 32

        oDanfe:Say(nLinha, nAuxH + 2, aItem[12], oFont08:oFont)
        nAuxH += 32

        oDanfe:Say(nLinha, nAuxH + 2, aItem[14], oFont08:oFont)

        If nLinha + nAltura - 1 <= 676
            oDanfe:Line(nLinha + nAltura - 1, 000, nLinha + nAltura - 1, 563)
        EndIf

        nLinha += nAltura
    Next

    // === CALCULO DO ISSQN (Y=684-715) ===
    oDanfe:Say(684, 002, "CALCULO DO ISSQN", oFont08N:oFont)
    oDanfe:Box(691, 000, 715, 141)
    oDanfe:Say(699, 002, "INSCRICAO MUNICIPAL", oFont08N:oFont)
    oDanfe:Box(691, 141, 715, 282)
    oDanfe:Say(699, 143, "VALOR TOTAL DOS SERVICOS", oFont08N:oFont)
    oDanfe:Box(691, 282, 715, 423)
    oDanfe:Say(699, 284, "BASE DE CALCULO DO ISSQN", oFont08N:oFont)
    oDanfe:Box(691, 423, 715, 563)
    oDanfe:Say(699, 425, "VALOR DO ISSQN", oFont08N:oFont)

    // === DADOS ADICIONAIS (Y=721-800) ===
    oDanfe:Say(721, 002, "DADOS ADICIONAIS", oFont08N:oFont)
    oDanfe:Box(730, 000, 800, 310)
    oDanfe:Say(738, 002, "INFORMACOES COMPLEMENTARES", oFont08N:oFont)

    If !Empty(cInfAd)
        oDanfe:Say(750, 002, cInfAd, oFont08:oFont)
    EndIf

    If Empty(cChave)
        oDanfe:Say(780, 002, "*** DOCUMENTO SEM VALOR FISCAL - NF-e NAO TRANSMITIDA ***", oFont10N:oFont)
        oDanfe:Say(792, 002, "Preview gerado em " + DtoC(Date()) + " as " + Time() + " - NAO POSSUI VALIDADE FISCAL", oFont08:oFont)
    EndIf

    oDanfe:Box(730, 310, 800, 563)
    oDanfe:Say(738, 312, "RESERVADO AO FISCO", oFont08N:oFont)

    If File(cLogoTvs) .Or. Resource2File(cLogoTvs, cStartP + cLogoTvs)
        oDanfe:SayBitmap(776, 468, cLogoTvs, 085, 18)
    EndIf

    oDanfe:EndPage()
    oDanfe:Preview()

    FreeObj(oFont07)
    FreeObj(oFont07N)
    FreeObj(oFont08)
    FreeObj(oFont08N)
    FreeObj(oFont09)
    FreeObj(oFont09N)
    FreeObj(oFont10)
    FreeObj(oFont10N)
    FreeObj(oFont12N)
    FreeObj(oFont18N)

    If oDanfe != Nil
        FreeObj(oDanfe)
        oDanfe := Nil
    EndIf

Return
/*/{Protheus.doc} NPT_QuebraDesc
Quebra a descricao do item em linhas que caibam na coluna do grid.
Corta sempre nos espacos, para nao partir palavras ao meio.
@type : Function
@author Vortice
@since 08/10/2026
@param cTexto, character, texto completo da descricao
@param nLarg, numeric, maximo de caracteres por linha
@return array, linhas da descricao (maximo 3)
/*/
Static Function NPT_QuebraDesc(cTexto, nLarg)
    Local aLinhas := {}
    Local cLinha  := ""
    Local cPal    := ""
    Local nSep    := 0

    cTexto := AllTrim(cTexto)
    While "  " $ cTexto
        cTexto := StrTran(cTexto, "  ", " ")
    EndDo
    While Len(cTexto) > 0
        nSep := At(" ", cTexto)
        If nSep == 0
            cPal   := cTexto
            cTexto := ""
        Else
            cPal   := SubStr(cTexto, 1, nSep - 1)
            cTexto := AllTrim(SubStr(cTexto, nSep + 1))
        EndIf

        If Len(cLinha) == 0
            cLinha := cPal
        ElseIf Len(cLinha) + 1 + Len(cPal) <= nLarg
            cLinha += " " + cPal
        Else
            AAdd(aLinhas, cLinha)
            cLinha := cPal
        EndIf

        While Len(cLinha) > nLarg
            AAdd(aLinhas, SubStr(cLinha, 1, nLarg))
            cLinha := SubStr(cLinha, nLarg + 1)
        EndDo
    EndDo

    If !Empty(cLinha)
        AAdd(aLinhas, cLinha)
    EndIf

    If Len(aLinhas) > 3
        aSize(aLinhas, 3)
    EndIf

Return aLinhas
/*/{Protheus.doc} NPT_GridCab
Desenha o cabecalho do grid de itens do DANFE (titulo, moldura e colunas).
Chamada na primeira pagina e a cada virada de pagina para repetir o cabecalho.
@type : Function
@author Vortice
@since 07/10/2026
@param oPrn, object, objeto FWMsPrinter
@param oFontCab, object, fonte negrito dos titulos das colunas
/*/
Static Function NPT_GridCab(oPrn, oFontCab)
    Local nAuxG := 0

    oPrn:Say(440, 002, "DADOS DO PRODUTO / SERVICO", oFontCab:oFont)
    oPrn:Box(442, 000, 678, 563)

    oPrn:Box(442, nAuxG, 678, nAuxG + 48)
    oPrn:Say(450, nAuxG + 2, "COD. PROD", oFontCab:oFont)
    nAuxG += 48

    oPrn:Box(442, nAuxG, 678, nAuxG + 126)
    oPrn:Say(450, nAuxG + 2, "DESCRICAO DO PROD./SERV.", oFontCab:oFont)
    nAuxG += 126

    oPrn:Box(442, nAuxG, 678, nAuxG + 42)
    oPrn:Say(450, nAuxG + 2, "NCM/SH", oFontCab:oFont)
    nAuxG += 42

    oPrn:Box(442, nAuxG, 678, nAuxG + 22)
    oPrn:Say(450, nAuxG + 2, "CST", oFontCab:oFont)
    nAuxG += 22

    oPrn:Box(442, nAuxG, 678, nAuxG + 28)
    oPrn:Say(450, nAuxG + 2, "CFOP", oFontCab:oFont)
    nAuxG += 28

    oPrn:Box(442, nAuxG, 678, nAuxG + 18)
    oPrn:Say(450, nAuxG + 2, "UN", oFontCab:oFont)
    nAuxG += 18

    oPrn:Box(442, nAuxG, 678, nAuxG + 30)
    oPrn:Say(450, nAuxG + 2, "QUANT.", oFontCab:oFont)
    nAuxG += 30

    oPrn:Box(442, nAuxG, 678, nAuxG + 40)
    oPrn:Say(450, nAuxG + 2, "V.UNITARIO", oFontCab:oFont)
    nAuxG += 40

    oPrn:Box(442, nAuxG, 678, nAuxG + 42)
    oPrn:Say(450, nAuxG + 2, "V.TOTAL", oFontCab:oFont)
    nAuxG += 42

    oPrn:Box(442, nAuxG, 678, nAuxG + 36)
    oPrn:Say(450, nAuxG + 2, "BC.ICMS", oFontCab:oFont)
    nAuxG += 36

    oPrn:Box(442, nAuxG, 678, nAuxG + 36)
    oPrn:Say(450, nAuxG + 2, "V.ICMS", oFontCab:oFont)
    nAuxG += 36

    oPrn:Box(442, nAuxG, 678, nAuxG + 32)
    oPrn:Say(450, nAuxG + 2, "V.IPI", oFontCab:oFont)
    nAuxG += 32

    oPrn:Box(442, nAuxG, 678, nAuxG + 32)
    oPrn:Say(450, nAuxG + 2, "A.ICMS", oFontCab:oFont)
    nAuxG += 32

    oPrn:Box(442, nAuxG, 678, nAuxG + 31)
    oPrn:Say(450, nAuxG + 2, "A.IPI", oFontCab:oFont)

Return
/*/{Protheus.doc} NPT_GetTxt
Extrai texto de node XML parseado com seguranca.
Recebe o objeto pai e o nome da propriedade como string.
Usa AttIsMemberOf() para verificar se a propriedade existe antes de acessar.

@type  Static Function
@param oParent, Objeto, Objeto pai do XML parseado
@param cProp,   Caractere, Nome da propriedade (ex: "_xNome")
@return Caractere, Texto do node ou vazio
/*/
Static Function NPT_GetTxt(oParent, cProp)
    Local cRet := ""
    If oParent == Nil
        Return ""
    EndIf
    If AttIsMemberOf(oParent, cProp)
        cRet := &("oParent:" + cProp + ":Text")
    EndIf
Return cRet

/*/{Protheus.doc} NPT_GetNum
Extrai valor numerico de node XML parseado com seguranca.
Usado para valores formatados pelo NPT_FmtVal (ex: "1234.56").

@type  Static Function
@param oParent, Objeto, Objeto pai do XML parseado
@param cProp,   Caractere, Nome da propriedade (ex: "_vBC")
@return Numerico, Valor ou 0
/*/
Static Function NPT_GetNum(oParent, cProp)
    Local cVal := NPT_GetTxt(oParent, cProp)
    Local nRet := 0
    If !Empty(cVal)
        nRet := Val(cVal)
    EndIf
Return nRet

/*/{Protheus.doc} NPT_ICMSBC
Extrai vBC do node ICMS tentando todos os tipos possiveis.

@type  Static Function
@param oImp, Objeto, Objeto imposto
@return Numerico, Valor ou 0
/*/
Static Function NPT_ICMSBC(oImp)
    Local cVal := ""
    Local oICMS

    If oImp == Nil .Or. !AttIsMemberOf(oImp, "_ICMS")
        Return 0
    EndIf

    oICMS := oImp:_ICMS:_ICMS00
    If oICMS != Nil
        cVal := NPT_GetTxt(oICMS, "_vBC")
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS10
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vBC")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS20
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vBC")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS30
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vBC")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS40
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vBC")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS51
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vBC")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS60
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vBC")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS70
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vBC")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS90
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vBC")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMSSN101
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vBC")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMSSN102
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vBC")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMSSN201
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vBC")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMSSN202
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vBC")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMSSN500
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vBC")
        EndIf
    EndIf

    If Empty(cVal)
        Return 0
    EndIf

Return Val(cVal)

/*/{Protheus.doc} NPT_ICMSV
Extrai vICMS do node ICMS tentando todos os tipos possiveis.

@type  Static Function
@param oImp, Objeto, Objeto imposto
@return Numerico, Valor ou 0
/*/
Static Function NPT_ICMSV(oImp)
    Local cVal := ""
    Local oICMS

    If oImp == Nil .Or. !AttIsMemberOf(oImp, "_ICMS")
        Return 0
    EndIf

    oICMS := oImp:_ICMS:_ICMS00
    If oICMS != Nil
        cVal := NPT_GetTxt(oICMS, "_vICMS")
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS10
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vICMS")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS20
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vICMS")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS30
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vICMS")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS51
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vICMS")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS70
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vICMS")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS90
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vICMS")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMSSN500
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_vICMS")
        EndIf
    EndIf

    If Empty(cVal)
        Return 0
    EndIf

Return Val(cVal)

/*/{Protheus.doc} NPT_ICMSP
Extrai pICMS do node ICMS tentando tipos que tem aliquota.

@type  Static Function
@param oImp, Objeto, Objeto imposto
@return Numerico, Valor ou 0
/*/
Static Function NPT_ICMSP(oImp)
    Local cVal := ""
    Local oICMS

    If oImp == Nil .Or. !AttIsMemberOf(oImp, "_ICMS")
        Return 0
    EndIf

    oICMS := oImp:_ICMS:_ICMS00
    If oICMS != Nil
        cVal := NPT_GetTxt(oICMS, "_pICMS")
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS51
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_pICMS")
        EndIf
    EndIf
    If Empty(cVal)
        oICMS := oImp:_ICMS:_ICMS70
        If oICMS != Nil
            cVal := NPT_GetTxt(oICMS, "_pICMS")
        EndIf
    EndIf

    If Empty(cVal)
        Return 0
    EndIf

Return Val(cVal)

/*/{Protheus.doc} NPT_IPIV
Extrai valor de node IPI tentando IPITrib e IPINT.

@type  Static Function
@param oImp, Objeto, Objeto imposto
@return Numerico, Valor ou 0
/*/
Static Function NPT_IPIV(oImp)
    Local cVal := ""
    Local oIPI

    If oImp == Nil .Or. !AttIsMemberOf(oImp, "_IPI")
        Return 0
    EndIf

    oIPI := oImp:_IPI:_IPITrib
    If oIPI != Nil
        cVal := NPT_GetTxt(oIPI, "_vIPI")
    EndIf

    If Empty(cVal)
        oIPI := oImp:_IPI:_IPINT
        If oIPI != Nil
            cVal := NPT_GetTxt(oIPI, "_vIPI")
        EndIf
    EndIf

    If Empty(cVal)
        Return 0
    EndIf

Return Val(cVal)

/*/{Protheus.doc} ConvDate
Converte data ISO (AAAAMMDD ou AAAA-MM-DDThh:mm:ss) para
formato DD/MM/AAAA.

@type  Static Function
@param cData, Caractere, Data em formato ISO
@return cData, Caractere, Data formatada DD/MM/AAAA
/*/
Static Function ConvDate(cData)
    Local dData := CToD("")
    Local cRet  := ""

    If Empty(cData)
        Return Space(10)
    EndIf

    cData := SubStr(StrTran(cData, "-", ""), 1, 8)
    dData := StoD(cData)

    If dData <> CToD("")
        cRet := StrZero(Day(dData), 2) + "/" + StrZero(Month(dData), 2) + "/" + StrZero(Year(dData), 4)
    Else
        cRet := Space(10)
    EndIf

Return cRet














