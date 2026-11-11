// ============================================================================
// AJUSTCUST.PRW - Ajuste de saldo fisico e custo medio via movimentacao interna
// ============================================================================
// Programa: U_AJUSTCUST() (User Function maximo 10 caracteres)
// Objetivo: ler planilha CSV com saldo desejado e custo medio desejado por
//           filial + produto + armazem, mostrar preview da diferenca e, sob
//           confirmacao do usuario, gravar movimentos internos via MATA241.
// ----------------------------------------------------------------------------
// FLUXO:
//   1. Tela (MsDialog): mes competencia (MM/AAAA), arquivo da planilha, TM
//      entrada, TM saida, TM acerto custo maior (valorizado, qtd zero), TM
//      acerto custo menor (valorizado, qtd zero), prefixo do documento,
//      centro de custo, conta contabil, tolerancia, armazens de CQ.
//   2. VALIDAR: le a planilha, valida as linhas, calcula saldo/custo de
//      referencia e deltas, monta o grid de preview. Nao grava nada.
//   3. PROCESSAR: pergunta Sim/Nao e, para cada linha validada:
//        - delta qtd > 0  -> entrada interna na TM de entrada, quantidade =
//          delta, custo unitario igual ao custo medio desejado.
//        - delta qtd < 0  -> saida interna na TM de saida, quantidade =
//          abs(delta). Nunca deixa saldo negativo nem saida maior que a
//          referencia.
//        - diferenca de valor restante -> movimento valorizado sem
//          quantidade (TM acerto a maior se delta > 0, TM a menor se delta
//          < 0), somente com valor, na mesma data do mes.
//        - saldo desejado zero -> apenas saida da quantidade de referencia.
//          Nao gera acerto de valor sobre quantidade zero.
//   4. Toda gravacao nasce de MsExecAuto("MATA241", aCab, aItens, 3), dentro
//      de Begin Transaction POR LINHA, com DisarmTransaction em falha.
//      Uma transacao por linha: falha em uma linha nao desfaz as anteriores
//      ja gravadas; registra no log e segue a proxima.
//   5. Log CSV no mesmo diretorio do arquivo de entrada, com chave da linha,
//      documento, TM, quantidade, valor, movimento e mensagem de erro.
//   6. Se a data da coluna DATA cair dentro do mes informado, e usada;
//      senao, ultimo dia util do mes (domingo nao considerado util).
//   7. Mes aberto: referencia SB2 (mes corrente) ou posicao calculada ate o
//      ultimo dia do mes (mes anterior aberto: SB9 + SD1/SD2/SD3).
//      Mes fechado (ate MV_ULMES): linha entra como erro "periodo fechado";
//      o programa NAO reabre estoque.
//   8. Nao contabiliza por fora: a contabilizacao segue o padrao da MATA241.
// ----------------------------------------------------------------------------
// PROIBIDO: RecLock, Replace ou SQL de update em SB1, SB2, SB9, SD1, SD2, SD3,
// SF5 ou qualquer tabela de saldo. PROIBIDO alterar B2_QATU, B2_VATU1, B2_CM1,
// B2_QFIM, B2_VFIM1, B2_CMFIM1, B9_QINI,B9_VINI1, B9_CM1 direto.
// Toda alteracao de quantidade ou valor nasce EXCLUSIVAMENTE de movimentacao
// interna via MsExecAuto("MATA241").
// NAO chama MATA330 nem Refaz Saldos. No final, o aviso informa que B2_CM1
// fica atualizado pelo Refaz Saldos e B2_CMFIM1 pelo Recalculo do Custo Medio
// (MATA330), que devem ser executados pelo usuario, fora do horario de
// movimento, depois de conferir os logs.
// ===========================================================

#include "protheus.ch"
#include "Tbiconn.ch"

#Define cCrLf   Chr(13) + Chr(10)

// Situacoes das linhas do preview
#Define ST_OK        "OK"
#Define ST_ERRO      "ERRO"
#Define ST_PROC      "PROCESSADO"

// Tipos de movimento previstos (preview / log)
#Define MV_ENTRA     "ENTRADA DE QTD"
#Define MV_SAIDA     "SAIDA DE QTD"
#Define MV_ENTMA     "ENTRADA + ACERTO CUSTO A MAIOR"
#Define MV_ENTME     "ENTRADA + ACERTO CUSTO A MENOR"
#Define MV_SAIMA     "SAIDA + ACERTO CUSTO A MAIOR"
#Define MV_SAIME     "SAIDA + ACERTO CUSTO A MENOR"
#Define MV_AVMA      "APENAS ACERTO CUSTO A MAIOR"
#Define MV_AVME      "APENAS ACERTO CUSTO A MENOR"
#Define MV_SOREF     "APENAS SAIDA DA QTD DE REFERENCIA"
#Define MV_NADA      "SEM DIFERENCA"

// Colunas do array de preview (aPrev)
#Define PL_LINHA     1
#Define PL_FILIAL    2
#Define PL_PROD      3
#Define PL_DESCR     4
#Define PL_LOCAL     5
#Define PL_QTDREF    6
#Define PL_CUSTREF   7
#Define PL_VALREF    8
#Define PL_QTDDES    9
#Define PL_CUSTDES   10
#Define PL_VALDES    11
#Define PL_DELTAQ    12
#Define PL_DELTAV    13
#Define PL_TIPOMV    14
#Define PL_DATA      15
#Define PL_QTDHJ     16
#Define PL_CUSTHJ    17
#Define PL_STATUS    18
#Define PL_MSG       19
#Define PL_DOC       20

/*/{Protheus.doc} AJUSTCUST
Ajuste de saldo fisico e custo medio (moeda 1) via movimentacao interna MATA241
gerado por planilha CSV. Nenhum update direto em tabelas de saldo.
@author  Vortice Consultoria Mineral
@since   2026/10/23
@version 1
@type    function
/*/

User Function AJUSTCUST()

    Local aArea    := GetArea()
    Local oMes     := Nil
    Local oArq     := Nil
    Local oBtnArq  := Nil
    Local oTmE     := Nil
    Local oTmS     := Nil
    Local oTmMa    := Nil
    Local oTmMe    := Nil
    Local oDoc     := Nil
    Local oCC      := Nil
    Local oCta     := Nil
    Local oTol     := Nil
    Local oCQ      := Nil
    Local lProcQue := .F.

    // Parametros da rotina (passados para as funcoes Static via Private)
    Private cMesComp  := Space(7)
    Private cPathFile := Space(200)
    Private cTmEntM   := Space(3)
    Private cTmSaiM   := Space(3)
    Private cTmAMaiM  := Space(3)
    Private cTmAMenM  := Space(3)
    Private cDocPref  := Space(6)
    Private cCCUser   := Space(9)
    Private cCtaCusto := Space(9)
    Private cArmsCQ   := Space(60)
    Private nToler    := 0.001

    // Estado interno
    Private aPrev      := {}
    Private aLogCust   := {}
    Private aLocCq     := {}
    Private dMesRefIni := CToD("")   // primeiro dia do mes informado
    Private dMesRefFim := CToD("")   // ultimo dia do mes informado
    Private dMesRefDt  := CToD("")   // data do movimento (ult. dia util ou coluna DATA)
    Private dUlMesFech := CToD("")   // MV_ULMES
    Private cMsgInfo   := ""
    Private lLastValid := .F.
    Private nQtdLidos  := 0
    Private nQtdOk     := 0
    Private nQtdErro   := 0
    Private nQtdProc   := 0
    Private cPathLog   := ""

    // Controle de ExecAuto
    Private lMsErroAuto := .F.
    Private lMsHelpAuto := .F.

    // Objetos de tela compartilhados com as Statics
    Private oPrwMain := Nil
    Private oLbx     := Nil
    Private oSayInfo := Nil
    Private oBtnProc := Nil
    Private oBtnExp  := Nil

    dUlMesFech := SuperGetMV("MV_ULMES", , CToD("01/01/1990"))

    DEFINE MSDIALOG oPrwMain TITLE "Ajuste de Saldo/Custo Medio via Movimento Interno (MATA241)" ;
        FROM 000, 000 TO 650, 1340 PIXEL OF oMainWnd

    // Linha de parametros
    @ 5, 5 SAY "Mes competencia (MM/AAAA):" SIZE 90, 10 OF oPrwMain PIXEL
    @ 5, 100 MSGET oMes VAR cMesComp SIZE 45, 10 PICTURE "@R 99/9999" OF oPrwMain PIXEL

    @ 5, 150 SAY "Arquivo:" SIZE 40, 10 OF oPrwMain PIXEL
    @ 5, 192 MSGET oArq VAR cPathFile SIZE 195, 10 OF oPrwMain PIXEL
    @ 5, 392 BUTTON oBtnArq PROMPT "Buscar" SIZE 42, 12 OF oPrwMain PIXEL ;
        ACTION ( cPathFile := tFileDialog("CSV files (*.csv)", "Selecao do Arquivo CSV", , , .F., ), oArq:Refresh() )

    @ 5, 440 SAY "TM entrada:" SIZE 50, 10 OF oPrwMain PIXEL
    @ 5, 492 MSGET oTmE VAR cTmEntM SIZE 20, 10 PICTURE "@!" OF oPrwMain PIXEL
    @ 5, 518 SAY "TM saida:" SIZE 43, 10 OF oPrwMain PIXEL
    @ 5, 563 MSGET oTmS VAR cTmSaiM SIZE 20, 10 PICTURE "@!" OF oPrwMain PIXEL
    @ 5, 590 SAY "TM cus maior:" SIZE 58, 10 OF oPrwMain PIXEL
    @ 5, 650 MSGET oTmMa VAR cTmAMaiM SIZE 20, 10 PICTURE "@!" OF oPrwMain PIXEL
    @ 5, 678 SAY "TM cus menor:" SIZE 58, 10 OF oPrwMain PIXEL
    @ 5, 738 MSGET oTmMe VAR cTmAMenM SIZE 20, 10 PICTURE "@!" OF oPrwMain PIXEL

    @ 5, 766 SAY "Doc prefixo:" SIZE 51, 10 OF oPrwMain PIXEL
    @ 5, 818 MSGET oDoc VAR cDocPref SIZE 26, 10 PICTURE "@!" OF oPrwMain PIXEL
    @ 5, 852 SAY "Centro custo:" SIZE 52, 10 OF oPrwMain PIXEL
    @ 5, 904 MSGET oCC VAR cCCUser SIZE 26, 10 OF oPrwMain PIXEL
    @ 5, 938 SAY "Conta contabil:" SIZE 58, 10 OF oPrwMain PIXEL
    @ 5, 998 MSGET oCta VAR cCtaCusto SIZE 30, 10 OF oPrwMain PIXEL
    @ 5, 1036 SAY "Tolerancia:" SIZE 47, 10 OF oPrwMain PIXEL
    @ 5, 1084 MSGET oTol VAR nToler SIZE 42, 10 PICTURE "@E 999.999999" OF oPrwMain PIXEL
    @ 5, 1134 SAY "Armazens CQ:" SIZE 50, 10 OF oPrwMain PIXEL
    @ 5, 1186 MSGET oCQ VAR cArmsCQ SIZE 60, 10 OF oPrwMain PIXEL

    // Botoes
    @ 20, 5   BUTTON PROMPT "Validar"     SIZE 45, 12 OF oPrwMain PIXEL ACTION ( fValidar() )
    @ 20, 55  BUTTON oBtnExp  PROMPT "Exportar log" SIZE 45, 12 OF oPrwMain PIXEL ACTION ( fExportar() )
    @ 20, 105 BUTTON oBtnProc PROMPT "Processar"    SIZE 45, 12 OF oPrwMain PIXEL ACTION ( fProcessa() )
    oBtnExp:Disable()
    oBtnProc:Disable()
    @ 20, 155 BUTTON PROMPT "Cancelar"    SIZE 45, 12 OF oPrwMain PIXEL ACTION ( oPrwMain:End() )

    // Grid de preview (padrao LISTBOX do skill advpl-tela-consulta)
    @ 40, 5 LISTBOX oLbx FIELDS HEADER ;
        "Linha", "Filial", "Produto", "Descricao", "Armazem", "Qtd Ref", "Custo Ref", "Valor Ref", "Qtd Desejada", "Custo Desejado", "Valor Desejado", "Delta Qtd", "Delta Valor", "Movimento Previsto", "Data Movto", "Qtd Hoje B2", "Custo Hoje B2", "Status", "Mensagem", "Doc" ;
        SIZE 1335, 270 OF oPrwMain PIXEL
    oLbx:SetArray(aPrev)
    oLbx:aColSizes := {36, 40, 80, 110, 50, 55, 55, 65, 55, 55, 65, 55, 55, 100, 55, 55, 55, 40, 190, 60}
    oLbx:lHScroll := .T.
    oLbx:lVScroll := .T.
    oLbx:bLine := {|| fPrevLine(oLbx:nAt)}

    @ 316, 5 SAY oSayInfo VAR cMsgInfo SIZE 1300, 12 OF oPrwMain PIXEL
    cMsgInfo := "Antes de processar: informe mes, arquivo e TMs e clique Validar."

    ACTIVATE MSDIALOG oPrwMain CENTERED

    RestArea(aArea)
Return

// =============================== FIM PARTE 1 ===============================

/* ==============================================================================
fValidar: le as linhas do arquivo, valida cada uma e monta o array de
preview aPrev (10 colunas visuais + extras). Nao gava nada no banco.
============================================================================== */
Static Function fValidar()

    Local aArea     := GetArea()
    Local aRows     := {}
    Local aIdxHead  := {}
    Local aLinhaOut := {}
    Local cMsgErr   := ""
    Local cObs      := ""
    Local nI        := 0
    Local nLinhaF   := 0
    Local dMvto     := CToD("")
    Local nQtdDes   := 0
    Local nCusDes   := 0
    Local nValDes   := 0
    Local nQtdRef   := 0
    Local nCusRef   := 0
    Local nValRef   := 0
    Local nQtHj     := 0
    Local nCuHoj    := 0
    Local nDeltaQ   := 0
    Local nDeltaV   := 0
    Local nValAdj   := 0
    Local lOk       := .F.

    aPrev    := {}
    aLogCust := {}
    aLocCq   := fConvArray(cArmsCQ)
    nQtdLidos := 0
    nQtdOk    := 0
    nQtdErro  := 0
    nQtdProc  := 0
    cPathLog  := ""
    lLastValid := .F.

    If !fValMes(@cMsgErr)
        If oSayInfo != Nil
            oSayInfo:SetText(cMsgErr)
        EndIf
        MsgAlert(cMsgErr, "Parametro invalido")
        RestArea(aArea)
        Return
    EndIf

    If !fValTms(@cMsgErr)
        If oSayInfo != Nil
            oSayInfo:SetText(cMsgErr)
        EndIf
        MsgAlert(cMsgErr, "Parametro invalido")
        RestArea(aArea)
        Return
    EndIf

    If nToler <= 0
        nToler := 0.001
    EndIf

    cMsgErr := ""
    aRows := fLePlanilha(@cMsgErr)

    If !Empty(cMsgErr)
        If oSayInfo != Nil
            oSayInfo:SetText(cMsgErr)
        EndIf
        MsgAlert(cMsgErr, "Arquivo invalido")
        RestArea(aArea)
        Return
    EndIf
    If Len(aRows) < 2
        cMsgErr := "Planilha sem cabecalho ou sem linhas de dados."
        If oSayInfo != Nil
            oSayInfo:SetText(cMsgErr)
        EndIf
        MsgAlert(cMsgErr, "Arquivo invalido")
        RestArea(aArea)
        Return
    EndIf

    aIdxHead := fMapHead(aRows[1], @cMsgErr)
    If !Empty(cMsgErr)
        MsgAlert(cMsgErr, "Cabecalho invalido")
        RestArea(aArea)
        Return
    EndIf

    // Linha 1 do array aRows e o cabecalho; lidos serao das linhas seguintes
    For nI := 2 To Len(aRows)
        nLinhaF := nI
        aLinhaOut := fValLinha(aRows[nI], aIdxHead, nLinhaF, @lOk)
        aAdd(aPrev, aLinhaOut)
        If lOk
            nQtdOk++
        Else
            nQtdErro++
        EndIf
        nQtdLidos++
    Next nI

    If nQtdLidos == 0
        cMsgErr := "Nenhuma linha valida para processar no arquivo."
        If oSayInfo != Nil
            oSayInfo:SetText(cMsgErr)
        EndIf
        RestArea(aArea)
        Return
    EndIf

    If nQtdOk > 0
        lLastValid := .T.
        oBtnProc:Enable()
        oBtnExp:Enable()
    Else
        oBtnProc:Disable()
        oBtnExp:Enable()
    EndIf

    If oSayInfo != Nil
        oSayInfo:SetText("Lidas: " + cValToChar(nQtdLidos) + " | OK: " + cValToChar(nQtdOk) + " | Erros: " + cValToChar(nQtdErro) + ;
                         " | Processadas: " + cValToChar(nQtdProc))
    EndIf
    If oLbx != Nil
        oLbx:nAt := 1
        oLbx:SetArray(aPrev)
        oLbx:bLine := {|| fPrevLine(oLbx:nAt)}
        oLbx:Refresh()
    EndIf
    If oPrwMain != Nil
        oPrwMain:Refresh()
    EndIf

    RestArea(aArea)
Return

/* ==============================================================================
fValLinha: valida uma linha da planilha e monta a linha do preview.
Retorno: array do preview com status OK ou ERRO.
============================================================================== */
Static Function fValLinha(aCells, aIdxHead, nLinF, lRefOk)

    Local aRowOut  := {}
    Local lValido  := .T.
    Local cMsgErro := ""
    Local cFilX    := ""
    Local cProdX   := ""
    Local cLocX    := ""
    Local cDescrX  := ""
    Local cUMX     := ""
    Local cLoteX   := ""
    Local cEndX    := ""
    Local cSerieX  := ""
    Local cDocX    := ""
    Local cDataX   := ""
    Local dMvto    := CToD("")
    Local nQtdDes  := 0
    Local nCusDes  := 0
    Local nValDes  := 0
    Local nQtdRef  := 0
    Local nCusRef  := 0
    Local nValRef  := 0
    Local nQtHj    := 0
    Local nCuHoj   := 0
    Local nDeltaQ  := 0
    Local nDeltaV  := 0
    Local nValAdj  := 0
    Local lOk      := .F.
    Local nPos     := 0

    lOk := .T.

    // Colunas minimas
    If Len(aCells) < 5 .Or. Len(aCells) < aIdxHead[5]
        cMsgErro := "Linha com menos de 5 colunas (obrigatorias)."
        lOk := .F.
    EndIf

    If lOk
        cFilX  := AllTrim(Upper(aCells[aIdxHead[1]]))
        cProdX := AllTrim(aCells[aIdxHead[2]])
        cLocX  := AllTrim(Upper(aCells[aIdxHead[3]]))
        nQtdDes := fStr2Num(AllTrim(aCells[aIdxHead[4]]))
        nCusDes := fStr2Num(AllTrim(aCells[aIdxHead[5]]))

        // Colunas opcionais
        cLoteX  := ""
        cEndX   := ""
        cSerieX := ""
        cDocX   := ""
        dMvto   := CToD("")
        If aIdxHead[6] > 0 .And. aIdxHead[6] <= Len(aCells)
            cDataX := AllTrim(aCells[aIdxHead[6]])
            dMvto  := fCvDt(cDataX)
        EndIf
        If aIdxHead[7] > 0 .And. aIdxHead[7] <= Len(aCells)
            cDocX := AllTrim(aCells[aIdxHead[7]])
        EndIf
        If aIdxHead[8] > 0 .And. aIdxHead[8] <= Len(aCells)
            cObs := AllTrim(aCells[aIdxHead[8]])
        EndIf
        If aIdxHead[9] > 0 .And. aIdxHead[9] <= Len(aCells)
            cLoteX := AllTrim(aCells[aIdxHead[9]])
        EndIf
        If aIdxHead[10] > 0 .And. aIdxHead[10] <= Len(aCells)
            cEndX := AllTrim(aCells[aIdxHead[10]])
        EndIf
        If aIdxHead[11] > 0 .And. aIdxHead[11] <= Len(aCells)
            cSerieX := AllTrim(aCells[aIdxHead[11]])
        EndIf
    EndIf

    // Validacoes de preenchimento
    If lOk .And. Empty(cFilX)
        cMsgErro := "Filial vazia."
        lOk := .F.
    EndIf
    If lOk .And. Empty(cProdX)
        cMsgErro := "Produto vazio."
        lOk := .F.
    EndIf
    If lOk .And. Empty(cLocX)
        cMsgErro := "Armazem vazio."
        lOk := .F.
    EndIf
    If lOk .And. Empty(nQtdDes) .And. Empty(nCusDes)
        cMsgErro := "Quantidade e custo desejados vazios ou invalidos."
        lOk := .F.
    EndIf
    If lOk .And. nQtdDes < 0
        cMsgErro := "Quantidade desejada negativa."
        lOk := .F.
    EndIf
    If lOk .And. nCusDes < 0
        cMsgErro := "Custo medio desejado negativo."
        lOk := .F.
    EndIf

    // Filial da planilha precisa bater com a filial logada (cFilAnt)
    If lOk .And. !Empty(cFilX)
        If cFilX != AllTrim(Upper(cFilAnt))
            cMsgErro := "Filial da planilha (" + cFilX + ") diferente da filial logada (" + AllTrim(Upper(cFilAnt)) + ")."
            lOk := .F.
        EndIf
    EndIf

    // Armazem de CQ/qualidade nao permitido
    If lOk .And. Len(aLocCq) > 0
        nPos := aScan(aLocCq, {|x| x == cLocX})
        If nPos > 0
            cMsgErro := "Armazem de CQ/qualidade nao permitido (" + cLocX + ")."
            lOk := .F.
        EndIf
    EndIf

    // Mes fechado (ate MV_ULMES): nao reabre estoque
    If lOk .And. dMesRefFim <= dUlMesFech
        cMsgErro := "Mes fechado ate " + DToC(dUlMesFech) + "; o programa nao reabre estoque."
        lOk := .F.
    EndIf

    // Produto no cadastro
    If lOk
        DbSelectArea("SB1")
        SB1->(DbSetOrder(1))
        If !SB1->(DbSeek(xFilial("SB1") + Padr(cProdX, TamSX3("B1_COD")[1])))
            cMsgErro := "Produto " + cProdX + " nao encontrado no cadastro SB1."
            lOk := .F.
        Else
            If SB1->B1_MSBLQL == "1"
                cMsgErro := "Produto " + cProdX + " esta bloqueado no cadastro."
                lOk := .F.
            EndIf
            cDescrX := AllTrim(SB1->B1_DESC)
            cUMX    := AllTrim(SB1->B1_UM)
            // Lote/serie/endereco: produto controla e coluna valida vem vazia
            If SB1->B1_RASTR == "L" .And. Empty(cLoteX)
                cMsgErro := "Produto " + cProdX + " controla lote e a coluna LOTE esta vazia."
                lOk := .F.
            EndIf
            If SB1->B1_RASTR == "S" .And. Empty(cSerieX)
                cMsgErro := "Produto " + cProdX + " controla numero de serie e a coluna NUMSERIE esta vazia."
                lOk := .F.
            EndIf
            If SB1->B1_LOCALIZ == "S" .And. Empty(cEndX)
                cMsgErro := "Produto " + cProdX + " controla endereco e a coluna ENDERECO esta vazia."
                lOk := .F.
            EndIf
        EndIf
    EndIf

    // Armazem cadastrado: NNR ou com saldo SB2
    If lOk
        DbSelectArea("NNR")
        NNR->(DbSetOrder(1))
        If !NNR->(DbSeek(xFilial("NNR") + Padr(cLocX, TamSX3("NR_CODIGO")[1])))
            DbSelectArea("SB2")
            SB2->(DbSetOrder(1))
            If !SB2->(DbSeek(xFilial("SB2") + Padr(cProdX, TamSX3("B2_COD")[1]) + Padr(cLocX, TamSX3("B2_LOCAL")[1])))
                cMsgErro := "Armazem " + cLocX + " nao cadastrado no NNR e sem saldo no SB2."
                lOk := .F.
            EndIf
        EndIf
    EndIf

    // Data: da coluna DATA se cair dentro do mes; senao ultimo dia util do mes
    If lOk
        If !Empty(dMvto)
            If Month(dMvto) != Month(dMesRefFim) .Or. Year(dMvto) != Year(dMesRefFim)
                cMsgErro := "Data da coluna DATA (" + DToC(dMvto) + ") fora do mes informado."
                lOk := .F.
            EndIf
        Else
            dMvto := fUltDiaUtil(dMesRefFim)
        EndIf
    EndIf

    // Saldo de referencia
    If lOk
        fCalcSalado(cProdX, cLocX, @nQtdRef, @nCusRef, @nValRef, @nQtHj, @nCuHoj, @cMsgErro)
        If !Empty(cMsgErro)
            lOk := .F.
        EndIf
    EndIf

    // Deltas e movimento previsto
    If lOk
        nValDes := Round(nQtdDes * nCusDes, 2)
        nDeltaQ := Round(nQtdDes - nQtdRef, 6)
        nDeltaV := Round(nValDes - nValRef, 2)
        cMsgErro := fMontaSteps(nQtdRef, nCusRef, nValRef, nQtdDes, nCusDes, nValDes, nDeltaQ, nDeltaV, @nValAdj, @cTipoMov)
        If !Empty(cMsgErro)
            lOk := .F.
        EndIf
    EndIf

    // Monta a linha do preview
    aRowOut := Array(20)
    aFill(aRowOut, "")
    aRowOut[PL_LINHA]  := nLinF
    aRowOut[PL_FILIAL] := cFilX
    aRowOut[PL_PROD]   := cProdX
    aRowOut[PL_DESCR]  := cDescrX
    aRowOut[PL_LOCAL]  := cLocX
    aRowOut[PL_QTDREF] := nQtdRef
    aRowOut[PL_CUSTREF] := nCusRef
    aRowOut[PL_VALREF] := nValRef
    aRowOut[PL_QTDDES] := nQtdDes
    aRowOut[PL_CUSTDES] := nCusDes
    aRowOut[PL_VALDES] := nValDes
    aRowOut[PL_DELTAQ] := nDeltaQ
    aRowOut[PL_DELTAV] := nDeltaV
    aRowOut[PL_TIPOMV] := cTipoMov
    aRowOut[PL_DATA]   := dMvto
    aRowOut[PL_QTDHJ]  := nQtHj
    aRowOut[PL_CUSTHJ] := nCuHoj
    aRowOut[PL_STATUS] := If(lOk, ST_OK, ST_ERRO)
    aRowOut[PL_MSG]    := cMsgErro
    aRowOut[PL_DOC]    := cDocX

    lRefOk := lOk
Return aRowOut

/* ==============================================================================
fValMes: parse do mes informado (MM/AAAA). Define dMesRefIni e dMesRefFim.
============================================================================== */
Static Function fValMes(cMsgErr)

    Local lRet    := .T.
    Local cTex    := ""
    Local nMes    := 0
    Local nAno    := 0
    Local nMesPro := 0
    Local nAnoPro := 0
    Local dPriPro := CToD("")

    cMsgErr := ""
    cTex := AllTrim(cMesComp)
    If Len(cTex) != 7 .Or. SubStr(cTex, 3, 1) != "/"
        lRet := .F.
    Else
        nMes := Val(SubStr(cTex, 1, 2))
        nAno := Val(SubStr(cTex, 4, 4))
        If nMes < 1 .Or. nMes > 12
            lRet := .F.
        ElseIf nAno < 2000 .Or. nAno > 2100
            lRet := .F.
        EndIf
    EndIf

    If !lRet
        cMsgErr := "Mes competencia invalido. Informe MM/AAAA (ex.: 03/2026)."
        Return lRet
    EndIf

    dMesRefIni := SToD(StrZero(nAno, 4) + StrZero(nMes, 2) + "01")
    nMesPro := nMes + 1
    nAnoPro := nAno
    If nMesPro == 13
        nMesPro := 1
        nAnoPro := nAno + 1
    EndIf
    dPriPro := SToD(StrZero(nAnoPro, 4) + StrZero(nMesPro, 2) + "01")
    dMesRefFim := dPriPro - 1

Return lRet

/* ==============================================================================
fValTms: valida as 4 TMs e suas direcoes regras de fronteira TM:
TM <= 499 = entrada (quantidade ou valor +); TM >= 500 = saida.
TMs de acerto de custo precisam estar com quantidade zero permitida e
valorizado no cadastro SF5 quando os campos existirem. Guarda em privates.
============================================================================== */
Static Function fValTms(cMsgErr)

    Local lRet      := .T.
    Local cTmPdd    := ""
    Local lPosCampo := .F.

    cMsgErr := ""

    cTmPdd := fTmSeek(cTmEntM)
    If Empty(cTmPdd)
        lRet   := .F.
        cMsgErr := "TM de entrada " + AllTrim(cTmEntM) + " nao cadastrada no SF5."
    ElseIf Val(cTmPdd) > 499
        lRet   := .F.
        cMsgErr := "TM de entrada " + AllTrim(cTmPdd) + " precisa ser menor ou igual a 499."
    Else
        cTmEntM := cTmPdd
    EndIf

    If lRet
        cTmPdd := fTmSeek(cTmSaiM)
        If Empty(cTmPdd)
            lRet   := .F.
            cMsgErr := "TM de saida " + AllTrim(cTmSaiM) + " nao cadastrada no SF5."
        ElseIf Val(cTmPdd) < 500
            lRet   := .F.
            cMsgErr := "TM de saida " + AllTrim(cTmPdd) + " precisa ser maior ou igual a 500."
        Else
            cTmSaiM := cTmPdd
        EndIf
    EndIf

    If lRet
        cTmPdd := fTmSeek(cTmAMaiM)
        If Empty(cTmPdd)
            lRet   := .F.
            cMsgErr := "TM de acerto custo a maior " + AllTrim(cTmAMaiM) + " nao cadastrada no SF5."
        ElseIf Val(cTmPdd) > 499
            lRet   := .F.
            cMsgErr := "TM de acerto custo a maior " + AllTrim(cTmPdd) + " precisa ser menor ou igual a 499 (tipo entrada)."
        Else
            lPosCampo := fTmBaixa(cTmPdd, @cMsgErr)
            If lRet .And. !lPosCampo .And. !Empty(cMsgErr)
                lRet := .F.
            EndIf
            cTmAMaiM := cTmPdd
        EndIf
    EndIf

    If lRet
        cTmPdd := fTmSeek(cTmAMenM)
        If Empty(cTmPdd)
            lRet   := .F.
            cMsgErr := "TM de acerto custo a menor " + AllTrim(cTmAMenM) + " nao cadastrada no SF5."
        ElseIf Val(cTmPdd) < 500
            lRet   := .F.
            cMsgErr := "TM de acerto custo a menor " + AllTrim(cTmPdd) + " precisa ser maior ou igual a 500 (tipo saida)."
        Else
            lPosCampo := fTmBaixa(cTmPdd, @cMsgErr)
            If lRet .And. !lPosCampo .And. !Empty(cMsgErr)
                lRet := .F.
            EndIf
            cTmAMenM := cTmPdd
        EndIf
    EndIf

Return lRet

/* ==============================================================================
fTmSeek: normaliza o codigo da TM (SF5.F5_COD) procurando repetido em fila
de SF5 com padrao de filial ou codigo. Retorna codigo normalizado ("" se
nao localizar). Valores de 2 caracteres recebem padding de zeros a esquerda
na volta de busca (ex.: 03 -> 003).
============================================================================== */
Static Function fTmSeek(cTmTxt)

    Local lRet      := .F.
    Local cTmPdd    := ""
    Local lPosCampo := .F.

    If Empty(AllTrim(cTmTxt))
        Return cTmPdd
    EndIf

    DbSelectArea("SF5")
    SF5->(DbSetOrder(1))

    cTmPdd := PadL(AllTrim(cTmTxt), TamSX3("F5_COD")[1], "0")
    If SF5->(DbSeek(xFilial("SF5") + cTmPdd))
        lRet := .T.
    EndIf

    If !lRet .And. Len(AllTrim(cTmTxt)) != TamSX3("F5_COD")[1]
        cTmPdd := Padr(AllTrim(cTmTxt), TamSX3("F5_COD")[1])
        If SF5->(DbSeek(xFilial("SF5") + cTmPdd))
            lRet := .T.
        EndIf
    EndIf

    If !lRet
        cTmPdd := ""
    EndIf

Return cTmPdd

/* ==============================================================================
fTmBaixa: valida se a TM de acerto de custo esta valorizada e com
quantidade zero permitida no cadastro SF5 (campos F5_VAL e F5_QTDZERO).
So valida quando os campos existirem no dicionario deste ambiente.
============================================================================== */
Static Function fTmBaixa(cTmCod, cMsgErr)

    Local lRet    := .T.
    Local lF5Val  := .F.
    Local lF5Qtz  := .F.

    cMsgErr := ""
    lF5Val := SX3->(FieldPos("F5_VAL")) > 0
    lF5Qtz := SX3->(FieldPos("F5_QTDZERO")) > 0

    If lF5Val .Or. lF5Qtz
        DbSelectArea("SF5")
        SF5->(DbSetOrder(1))
        If SF5->(DbSeek(xFilial("SF5") + cTmCod))
            If lF5Val .And. SF5->F5_VAL != "S"
                cMsgErr := "TM " + AllTrim(cTmCod) + " precisa estar valorizada (F5_VAL = Sim)."
                lRet := .F.
            EndIf
            If lF5Qtz .And. SF5->F5_QTDZERO != "S"
                cMsgErr := "TM " + AllTrim(cTmCod) + " precisa permitir quantidade zero (F5_QTDZERO = Sim)."
                lRet := .F.
            EndIf
        Else
            cMsgErr := "TM " + AllTrim(cTmCod) + " nao encontrada no SF5."
            lRet := .F.
        EndIf
    EndIf

Return lRet

/* ==============================================================================
fMapHead: recebe a linha de cabecalho e retorna indices de cada coluna.
Retorno: {iFILIAL, iPRODUTO, iLOCAL, iQTD, iCUSTO, iDATA, iDOC, iOBS, iLOTE, iEND, iNUMSERIE}
============================================================================== */
Static Function fMapHead(aHeader, cMsgErr)

    Local aIdx := {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    Local nI   := 0
    Local cTxt := ""

    cMsgErr := ""
    For nI := 1 To Len(aHeader)
        cTxt := Upper(AllTrim(fSubStr(aHeader[nI], 30)))
        Do Case
            Case cTxt == "FILIAL"
                aIdx[1] := nI
            Case cTxt == "PRODUTO"
                aIdx[2] := nI
            Case cTxt == "LOCAL"
                aIdx[3] := nI
            Case cTxt == "QTD_DESEJADA" .Or. cTxt == "QTD DESEJADA"
                aIdx[4] := nI
            Case cTxt == "CUSTO_MEDIO_DESEJADO" .Or. cTxt == "CUSTO MEDIO DESEJADO"
                aIdx[5] := nI
            Case cTxt == "DATA"
                aIdx[6] := nI
            Case cTxt == "DOCUMENTO"
                aIdx[7] := nI
            Case cTxt == "OBSERVACAO"
                aIdx[8] := nI
            Case cTxt == "LOTE"
                aIdx[9] := nI
            Case cTxt == "ENDERECO"
                aIdx[10] := nI
            Case cTxt == "NUMSERIE" .Or. cTxt == "NUM SERIE"
                aIdx[11] := nI
        EndCase
    Next nI

    If aIdx[1] == 0
        cMsgErr := "Coluna FILIAL nao encontrada no cabecalho."
    ElseIf aIdx[2] == 0
        cMsgErr := "Coluna PRODUTO nao encontrada no cabecalho."
    ElseIf aIdx[3] == 0
        cMsgErr := "Coluna LOCAL nao encontrada no cabecalho."
    ElseIf aIdx[4] == 0
        cMsgErr := "Coluna QTD_DESEJADA nao encontrada no cabecalho."
    ElseIf aIdx[5] == 0
        cMsgErr := "Coluna CUSTO_MEDIO_DESEJADO nao encontrada no cabecalho."
    EndIf

Return aIdx

/* ==============================================================================
fPrevLine: monta linha visual para o listbox a partir do indice atual.
============================================================================== */
Static Function fPrevLine(nAt)

    Local aRow := Nil
    Local aRet := {}
    Local cRet := ""

    If nAt < 1 .Or. nAt > Len(aPrev)
        Return aRet
    EndIf
    aRow := aPrev[nAt]

    aAdd(aRet, cValToChar(aRow[PL_LINHA]))
    aAdd(aRet, AllTrim(aRow[PL_FILIAL]))
    aAdd(aRet, SubStr(AllTrim(aRow[PL_PROD]), 1, 11))
    aAdd(aRet, SubStr(AllTrim(aRow[PL_DESCR]), 1, 15))
    aAdd(aRet, SubStr(AllTrim(aRow[PL_LOCAL]), 1, 7))
    aAdd(aRet, Transform(aRow[PL_QTDREF], "@E 999,999.9999"))
    aAdd(aRet, Transform(aRow[PL_CUSTREF], "@E 999,999.9999"))
    aAdd(aRet, Transform(aRow[PL_VALREF], "@E 999,999,999.99"))
    aAdd(aRet, Transform(aRow[PL_QTDDES], "@E 999,999.9999"))
    aAdd(aRet, Transform(aRow[PL_CUSTDES], "@E 999,999.9999"))
    aAdd(aRet, Transform(aRow[PL_VALDES], "@E 999,999,999.99"))
    aAdd(aRet, Transform(aRow[PL_DELTAQ], "@E 999,999.9999"))
    aAdd(aRet, Transform(aRow[PL_DELTAV], "@E 999,999,999.99"))
    aAdd(aRet, SubStr(AllTrim(aRow[PL_TIPOMV]), 1, 14))
    aAdd(aRet, If(ValType(aRow[PL_DATA]) == "D" .And. !Empty(aRow[PL_DATA]), DToC(aRow[PL_DATA]), ""))
    aAdd(aRet, Transform(aRow[PL_QTDHJ], "@E 999,999.9999"))
    aAdd(aRet, Transform(aRow[PL_CUSTHJ], "@E 999,999.9999"))
    aAdd(aRet, AllTrim(aRow[PL_STATUS]))
    aAdd(aRet, SubStr(AllTrim(aRow[PL_MSG]), 1, 27))
    aAdd(aRet, SubStr(AllTrim(aRow[PL_DOC]), 1, 8))

Return aRet
