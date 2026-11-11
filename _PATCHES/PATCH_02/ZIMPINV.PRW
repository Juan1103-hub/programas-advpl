// --- Importacao da contagem do inventario (MATA270) a partir de planilha CSV ---

#include "totvs.ch"

#DEFINE CRLF Chr(13) + Chr(10)

/*/{Protheus.doc} ZIMPINV
Importa a contagem do inventario para a tabela SB7, a partir de um arquivo
CSV separado por ponto e virgula, aberto pela opcao "Importar Inventario
(CSV)" do menu da rotina MATA270 (Digitacao do Inventario).

Colunas esperadas no arquivo:
  A - Codigo do produto (B1_COD)
  B - Descricao (usada apenas para conferencia na tela)
  C - Armazem (B7_LOCAL)
  D - Quantidade contada (B7_QUANT)

Para cada linha:
  - se o produto ja existe no inventario da data informada, a quantidade e
    alterada pela opcao 4 da MATA270, preservando os campos da chave do
    indice 1 (lote, endereco, numero de serie e contagem);
  - se o produto ainda nao existe, a contagem e incluida pela opcao 3.
Linha invalida nao interrompe o processo: ela e listada no final da
execucao. A efetivacao do acerto continua na MATA340.

@author  Vortice Consultoria Mineral
@since   2026/11/09
@version 1.0
@type    function
/*/
User Function ZIMPINV()

    Local oDlg
    Local lOk   := .F.
    Local nI    := 0
    Local nInc  := 0
    Local nAlt  := 0
    Local nErr  := 0
    Local nSkip := 0

    Private cZInvArq  := Space(250)
    Private dZInvData := dDataBase
    Private cZInvDoc  := "INVENT"
    Private aZInvRet  := {}

    DEFINE MSDIALOG oDlg TITLE "Importar Inventario (CSV)" FROM 000, 000 TO 300, 800 COLORS 0, 16777215 PIXEL

        @ 008, 012 SAY "Arquivo CSV:" SIZE 060, 010 OF oDlg PIXEL
        @ 006, 075 MSGET cZInvArq SIZE 260, 010 OF oDlg PIXEL
        @ 005, 345 BUTTON "..." SIZE 030, 012 OF oDlg PIXEL ACTION (cZInvArq := fZInvSelArq(cZInvArq))

        @ 028, 012 SAY "Data do inventario:" SIZE 060, 010 OF oDlg PIXEL
        @ 026, 075 MSGET dZInvData SIZE 060, 010 OF oDlg PIXEL VALID !Empty(dZInvData)
        @ 028, 145 SAY "(igual a data da lista gerada)" SIZE 180, 010 OF oDlg PIXEL

        @ 048, 012 SAY "Documento:" SIZE 060, 010 OF oDlg PIXEL
        @ 046, 075 MSGET cZInvDoc SIZE 060, 010 OF oDlg PIXEL

        @ 070, 012 SAY "Planilha: coluna A = Codigo, B = Descricao, C = Armazem, D = Quantidade contada." SIZE 370, 010 OF oDlg PIXEL
        @ 082, 012 SAY "Use arquivo CSV separado por ponto e virgula. A primeira linha pode ser o cabecalho." SIZE 370, 010 OF oDlg PIXEL
        @ 094, 012 SAY "Itens ja existentes na lista sao atualizados; os demais sao incluidos." SIZE 370, 010 OF oDlg PIXEL

        @ 116, 012 BUTTON "Importar" SIZE 060, 012 OF oDlg PIXEL ACTION (lOk := .T., oDlg:End())
        @ 116, 082 BUTTON "Cancelar" SIZE 060, 012 OF oDlg PIXEL ACTION oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED

    If !lOk
        Return Nil
    EndIf

    cZInvArq := AllTrim(cZInvArq)
    cZInvDoc := AllTrim(cZInvDoc)

    If Empty(cZInvArq) .Or. !File(cZInvArq)
        MsgStop("Selecione o arquivo CSV.", "Importar Inventario")
        Return Nil
    EndIf

    If Upper(SubStr(cZInvArq, RAt(".", cZInvArq) + 1, 3)) != "CSV"
        MsgStop("O arquivo precisa ter a extensao .csv.", "Importar Inventario")
        Return Nil
    EndIf

    If Empty(dZInvData)
        MsgStop("Informe a data do inventario.", "Importar Inventario")
        Return Nil
    EndIf

    If Empty(cZInvDoc)
        MsgStop("Informe o documento.", "Importar Inventario")
        Return Nil
    EndIf

    If Len(cZInvDoc) > TamSX3("B7_DOC")[1]
        MsgStop("O documento deve ter no maximo " + cValToChar(TamSX3("B7_DOC")[1]) + " caracteres.", "Importar Inventario")
        Return Nil
    EndIf

    If !MsgYesNo("Importar a planilha para o inventario de " + DtoC(dZInvData) + "?" + CRLF + ;
                 CRLF + ;
                 "Itens que ja estao na lista terao a quantidade atualizada." + CRLF + ;
                 "Itens que nao estao serao incluidos.", "Importar Inventario (CSV)")
        Return Nil
    EndIf

    Processa({|| fZInvProcessa() }, "Importando o inventario...")

    If Empty(aZInvRet)
        MsgStop("Nenhuma linha foi lida do arquivo.", "Importar Inventario")
        Return Nil
    EndIf

    For nI := 1 To Len(aZInvRet)
        Do Case
        Case aZInvRet[nI, 4] == "Incluido"
            nInc++
        Case aZInvRet[nI, 4] == "Alterado"
            nAlt++
        Case aZInvRet[nI, 4] == "Erro"
            nErr++
        Otherwise
            nSkip++
        EndCase
    Next nI

    MsgInfo("Importacao concluida."                              + CRLF + ;
            CRLF + ;
            "Data do inventario    : " + DtoC(dZInvData)         + CRLF + ;
            "Documento             : " + cZInvDoc                + CRLF + ;
            CRLF + ;
            "Linhas processadas    : " + cValToChar(Len(aZInvRet)) + CRLF + ;
            "Contagens incluidas   : " + cValToChar(nInc)        + CRLF + ;
            "Quantidades alteradas : " + cValToChar(nAlt)        + CRLF + ;
            "Com erro              : " + cValToChar(nErr)        + CRLF + ;
            "Ignoradas             : " + cValToChar(nSkip), ;
            "Importar Inventario (CSV)")

    fZInvMostraRet(aZInvRet)

Return Nil

/*/{Protheus.doc} fZInvSelArq
Abre a janela de selecao do arquivo e devolve o caminho escolhido.
@param cAtual Caminho ja informado na tela.
@return cSel Caminho escolhido ou o caminho anterior quando cancelado.
@type    Static Function
@author  Vortice Consultoria Mineral
@since   2026/11/09
/*/
Static Function fZInvSelArq(cAtual)

    Local cSel := ""

    cSel := tFileDialog("CSV files (*.csv)", "Selecao do Arquivo CSV", , , .F., )

    If Empty(cSel)
        cSel := cAtual
    EndIf

Return cSel

/*/{Protheus.doc} fZInvProcessa
Le o arquivo CSV e grava cada linha no inventario. Usa as variaveis
privadas cZInvArq, dZInvData e cZInvDoc, e devolve o resultado em aZInvRet,
com uma linha por registro lido: { nLinha, cCodigo, cArmazem, cSituacao,
cMotivo }. A situacao pode ser Incluido, Alterado, Erro ou Ignorado.
@return Nil
@type    Static Function
@author  Vortice Consultoria Mineral
@since   2026/11/09
/*/
Static Function fZInvProcessa()

    Local oArq    := Nil
    Local aLinhas := {}
    Local nTot    := 0
    Local nLin    := 0
    Local cLinha  := ""
    Local aCampos := {}
    Local cCod    := ""
    Local cDescr  := ""
    Local cArmaz  := ""
    Local cQtd    := ""
    Local cChave  := ""
    Local nPos    := 0
    Local aChaves := {}
    Local aGrav   := {}

    Private lMsErroAuto    := .F.
    // .F. = nao abre a tela de ajuda da rotina automatica: o erro cai no
    // GetAutoGRLog e vira uma linha da grade, sem parar a importacao
    Private lMsHelpAuto    := .F.
    Private lAutoErrNoFile := .T.

    oArq := FWFileReader():New(cZInvArq)

    If !oArq:Open()
        AAdd(aZInvRet, { 0, "", "", "Erro", "Arquivo nao pode ser aberto." })
        Return Nil
    EndIf

    If oArq:EoF()
        oArq:Close()
        AAdd(aZInvRet, { 0, "", "", "Erro", "Arquivo vazio." })
        Return Nil
    EndIf

    aLinhas := oArq:GetAllLines()
    nTot    := Len(aLinhas)
    oArq:Close()

    oArq := FWFileReader():New(cZInvArq)
    oArq:Open()
    ProcRegua(nTot)

    While oArq:HasLine()

        nLin++
        IncProc("Importando linha " + cValToChar(nLin) + " de " + cValToChar(nTot) + "...")

        cLinha := oArq:GetLine()

        // Marca de BOM do UTF-8 na primeira linha (Excel salva assim em alguns casos)
        If nLin == 1
            cLinha := StrTran(cLinha, Chr(239) + Chr(187) + Chr(191), "")
        EndIf

        If Empty(AllTrim(cLinha))
            Loop
        EndIf

        // Ignora a linha de cabecalho (codigo/descricao/armazem/quantidade)
        If nLin == 1 .And. "digo" $ Lower(cLinha)
            Loop
        EndIf

        aCampos := fZInvSplit(cLinha, ";")

        If Len(aCampos) < 4
            AAdd(aZInvRet, { nLin, AllTrim(aCampos[1]), "", "Ignorado", ;
                             "Linha sem as 4 colunas (codigo;descricao;armazem;quantidade)." })
            Loop
        EndIf

        cCod   := AllTrim(aCampos[1])
        cDescr := AllTrim(aCampos[2])
        cArmaz := AllTrim(aCampos[3])
        cQtd   := AllTrim(aCampos[4])

        If Empty(cCod) .And. Empty(cArmaz) .And. Empty(cQtd)
            Loop
        EndIf

        cChave := Upper(cCod) + "|" + Upper(cArmaz)
        nPos   := AScan(aChaves, {|x| x[1] == cChave})

        If nPos > 0
            AAdd(aZInvRet, { nLin, cCod, cArmaz, "Erro", ;
                             "Produto/armazem repetido na planilha (linha " + cValToChar(aChaves[nPos, 2]) + ")." })
            Loop
        EndIf

        AAdd(aChaves, { cChave, nLin })

        aGrav := fZInvGrava(cCod, cArmaz, cQtd, cDescr)
        AAdd(aZInvRet, { nLin, cCod, cArmaz, aGrav[1], aGrav[2] })

    EndDo

    oArq:Close()

Return Nil

/*/{Protheus.doc} fZInvGrava
Valida a linha e grava no SB7 pela rotina automatica da MATA270.
Quando o produto ja existe no inventario da data (mesma filial, data,
produto e armazem), a quantidade e alterada pela opcao 4, com todos os
campos da chave do indice 1 (lote, endereco, numero de serie e contagem)
preservados. Quando nao existe, a contagem e incluida pela opcao 3.
A SB7 e tabela core: a gravacao passa por MSExecAuto, nunca por RecLock.
A contagem aceita produto bloqueado (B1_MSBLQL) e armazem sem registro no
SB2: o inventario fisico independe do bloqueio de movimentacao e da posicao
atual, e a propria MATA270 valida o que for obrigatorio.
@param cCod   Codigo do produto digitado na planilha.
@param cArmaz Armazem digitado na planilha.
@param cQtd   Quantidade contada, em texto.
@param cDescr Descricao da planilha, usada apenas em mensagem de erro.
@return aRet { cSituacao, cMotivo } com situacao Incluido, Alterado ou Erro.
@type    Static Function
@author  Vortice Consultoria Mineral
@since   2026/11/09
/*/
Static Function fZInvGrava(cCod, cArmaz, cQtd, cDescr)

    Local aArea   := GetArea()
    Local aCampos := {}
    Local aLog    := {}
    Local aDados  := {}
    Local cBusca  := ""
    Local cMotivo := ""
    Local nJ      := 0
    Local nAchou  := 0
    Local nQtd    := 0
    Local nQtdAnt := 0
    Local cCodP   := ""
    Local cLocP   := ""

    If Len(cCod) > TamSX3("B1_COD")[1]
        RestArea(aArea)
        Return { "Erro", "Codigo com mais de " + cValToChar(TamSX3("B1_COD")[1]) + " caracteres." }
    EndIf

    If Len(cArmaz) > TamSX3("B7_LOCAL")[1]
        RestArea(aArea)
        Return { "Erro", "Armazem com mais de " + cValToChar(TamSX3("B7_LOCAL")[1]) + " caracteres." }
    EndIf

    If !fZInvEhNum(cQtd)
        RestArea(aArea)
        Return { "Erro", "Quantidade invalida: [" + cQtd + "]." }
    EndIf

    nQtd := Round(fZInvNum(cQtd), 2)

    If nQtd < 0
        RestArea(aArea)
        Return { "Erro", "Quantidade negativa: [" + cQtd + "]." }
    EndIf

    cCodP := PadR(cCod, TamSX3("B1_COD")[1])
    cLocP := fZInvLocal(cArmaz)

    DbSelectArea("SB1")
    SB1->(DbSetOrder(1))

    If !SB1->(DbSeek(xFilial("SB1") + cCodP))
        cMotivo := "Produto nao encontrado no cadastro (SB1)."
        If !Empty(cDescr)
            cMotivo += " Planilha: " + Left(cDescr, 40)
        EndIf
        RestArea(aArea)
        Return { "Erro", cMotivo }
    EndIf

    // Inicio da chave 1 da SB7: filial + data + produto + armazem
    DbSelectArea("SB7")
    SB7->(DbSetOrder(1))
    cBusca := xFilial("SB7") + DtoS(dZInvData) + cCodP + cLocP

    If SB7->(DbSeek(cBusca))
        While !SB7->(Eof()) .And. fZInvChaveSb7() == cBusca
            nAchou++
            If nAchou == 1
                aDados := fZInvDadosSb7()
            EndIf
            SB7->(DbSkip())
        EndDo
    EndIf

    If nAchou > 1
        RestArea(aArea)
        Return { "Erro", "Existem " + cValToChar(nAchou) + " contagens deste item nesta data. Ajuste manualmente." }
    EndIf

    aCampos := {}

    If nAchou == 1

        nQtdAnt := aDados[14]

        // Alteracao (opcao 4): a MATA270 exige todos os campos da chave 1
        AAdd(aCampos, { "B7_FILIAL",  aDados[1],  Nil })
        AAdd(aCampos, { "B7_LOCAL",   aDados[2],  Nil })
        AAdd(aCampos, { "B7_TIPO",    aDados[3],  Nil })
        AAdd(aCampos, { "B7_DOC",     aDados[4],  Nil })
        AAdd(aCampos, { "B7_QUANT",   nQtd,       Nil })
        AAdd(aCampos, { "B7_DATA",    dZInvData,  Nil })
        AAdd(aCampos, { "B7_DTVALID", aDados[5],  Nil })
        AAdd(aCampos, { "B7_COD",     aDados[6],  Nil })
        AAdd(aCampos, { "B7_LOTECTL", aDados[7],  Nil })
        AAdd(aCampos, { "B7_NUMLOTE", aDados[8],  Nil })
        AAdd(aCampos, { "B7_LOCALIZ", aDados[9],  Nil })
        AAdd(aCampos, { "B7_NUMSERI", aDados[10], Nil })
        AAdd(aCampos, { "B7_CONTAGE", aDados[11], Nil })
        AAdd(aCampos, { "B7_ORIGEM",  aDados[12], Nil })
        AAdd(aCampos, { "B7_STATUS",  aDados[13], Nil })
        AAdd(aCampos, { "INDEX",      1,          Nil })

        // Libera trava que tenha sobrado de tentativa anterior nesta sessao
        MsUnlock()
        lMsErroAuto := .F.
        MSExecAuto({|a, b, c| MATA270(a, b, c)}, aCampos, .F., 4)

    Else

        // Inclusao (opcao 3): lote e endereco teriam de vir da planilha
        If !Empty(SB1->B1_RASTRO) .And. SB1->B1_RASTRO $ "LS"
            RestArea(aArea)
            Return { "Erro", "Produto controla lote/serie e a planilha nao tem essa coluna." }
        EndIf

        If SB1->B1_LOCALIZ == "S"
            RestArea(aArea)
            Return { "Erro", "Produto controla endereco e a planilha nao tem essa coluna." }
        EndIf

        AAdd(aCampos, { "B7_FILIAL", xFilial("SB7"),                      Nil })
        AAdd(aCampos, { "B7_COD",    cCodP,                               Nil })
        AAdd(aCampos, { "B7_LOCAL",  cLocP,                               Nil })
        AAdd(aCampos, { "B7_DATA",   dZInvData,                           Nil })
        AAdd(aCampos, { "B7_DOC",    PadR(cZInvDoc, TamSX3("B7_DOC")[1]), Nil })
        AAdd(aCampos, { "B7_QUANT",  nQtd,                                Nil })

        MsUnlock()
        lMsErroAuto := .F.
        MSExecAuto({|a, b, c| MATA270(a, b, c)}, aCampos, .T., 3)

    EndIf

    If lMsErroAuto

        // Solta o que a rotina automatica deixou travado ao falhar, para o
        // registro nao ficar em uso ate a sessao terminar
        MsUnlock()

        aLog    := GetAutoGRLog()
        cMotivo := ""

        For nJ := 1 To Len(aLog)
            cMotivo += AllTrim(aLog[nJ]) + " "
        Next nJ

        If Empty(AllTrim(cMotivo))
            cMotivo := "A rotina MATA270 recusou o registro."
        EndIf

        // Trava de registro (REGBLOQ) nao se resolve no codigo: o registro
        // esta em uso por outra sessao ou por uma tela aberta do inventario
        If "bloqueado" $ Lower(cMotivo)
            cMotivo := "Registro em uso (bloqueado). Feche as telas do inventario e importe a planilha de novo."
        EndIf

        RestArea(aArea)

        Return { "Erro", Left(AllTrim(cMotivo), 150) }

    EndIf

    RestArea(aArea)

    If nAchou == 1
        Return { "Alterado", "Quantidade alterada de " + cValToChar(nQtdAnt) + " para " + cValToChar(nQtd) + "." }
    EndIf

Return { "Incluido", "Contagem incluida com quantidade " + cValToChar(nQtd) + "." }

/*/{Protheus.doc} fZInvLocal
Normaliza o armazem digitado na planilha para o formato gravado nas tabelas:
armazem numerico recebe zeros a esquerda ("1" vira "01") e os demais valores
sao completados com espaco. Sem isso a busca no indice nao encontra o saldo
nem a contagem que ja existe para o item.
@param cArmaz Armazem como veio da planilha.
@return cLocal Armazem no tamanho do campo.
@type    Static Function
@author  Vortice Consultoria Mineral
@since   2026/11/09
/*/
Static Function fZInvLocal(cArmaz)

    Local nTam := TamSX3("B7_LOCAL")[1]
    Local cVal := AllTrim(cArmaz)
    Local nI   := 1
    Local lNum := !Empty(cVal)

    While nI <= Len(cVal)
        If !(SubStr(cVal, nI, 1) $ "0123456789")
            lNum := .F.
        EndIf
        nI++
    EndDo

    If lNum
        cVal := StrZero(Val(cVal), nTam)
    Else
        cVal := PadR(cVal, nTam)
    EndIf

Return cVal

/*/{Protheus.doc} fZInvChaveSb7
Monta o inicio da chave 1 do registro atual da SB7: filial + data +
produto + armazem. A comparacao com a chave buscada identifica os registros
do mesmo produto, armazem e data (as contagens ficam no fim da chave).
@return cChave Chave do registro atual.
@type    Static Function
@author  Vortice Consultoria Mineral
@since   2026/11/09
/*/
Static Function fZInvChaveSb7()

    Local aArea  := GetArea()
    Local cChave := ""

    cChave := SB7->B7_FILIAL + DtoS(SB7->B7_DATA) + SB7->B7_COD + SB7->B7_LOCAL

    RestArea(aArea)

Return cChave

/*/{Protheus.doc} fZInvDadosSb7
Copia os campos do registro atual da SB7 usados na alteracao da contagem.
A ordem do array segue a chave 1 documentada pela TOTVS, com os campos de
controle no final: 1 filial, 2 armazem, 3 tipo, 4 documento, 5 validade,
6 produto, 7 controle de lote, 8 numero do lote, 9 endereco, 10 numero de
serie, 11 contagem, 12 origem, 13 status e 14 quantidade atual.
@return aDados Campos do registro atual.
@type    Static Function
@author  Vortice Consultoria Mineral
@since   2026/11/09
/*/
Static Function fZInvDadosSb7()

    Local aArea  := GetArea()
    Local aDados := {}

    aDados := { SB7->B7_FILIAL,  ;
                SB7->B7_LOCAL,   ;
                SB7->B7_TIPO,    ;
                SB7->B7_DOC,     ;
                SB7->B7_DTVALID, ;
                SB7->B7_COD,     ;
                SB7->B7_LOTECTL, ;
                SB7->B7_NUMLOTE, ;
                SB7->B7_LOCALIZ, ;
                SB7->B7_NUMSERI, ;
                SB7->B7_CONTAGE, ;
                SB7->B7_ORIGEM,  ;
                SB7->B7_STATUS,  ;
                SB7->B7_QUANT }

    RestArea(aArea)

Return aDados

/*/{Protheus.doc} fZInvSplit
Quebra uma linha CSV em campos, respeitando os campos entre aspas duplas.
Dentro das aspas o separador nao divide o campo e aspas duplas ("") viram
uma aspas literal no conteudo.
@param cLinha Linha do arquivo.
@param cSep   Caractere separador (neste programa, ponto e virgula).
@return aCampos Campos da linha.
@type    Static Function
@author  Vortice Consultoria Mineral
@since   2026/11/09
/*/
Static Function fZInvSplit(cLinha, cSep)

    Local aCampos := {}
    Local cCampo  := ""
    Local lAspas  := .F.
    Local nI      := 1
    Local cChar   := ""

    While nI <= Len(cLinha)

        cChar := SubStr(cLinha, nI, 1)

        If cChar == '"'
            If lAspas .And. SubStr(cLinha, nI + 1, 1) == '"'
                cCampo += '"'
                nI += 2
                Loop
            EndIf
            lAspas := !lAspas

        ElseIf cChar == cSep .And. !lAspas
            AAdd(aCampos, cCampo)
            cCampo := ""

        Else
            cCampo += cChar
        EndIf

        nI++

    EndDo

    AAdd(aCampos, cCampo)

Return aCampos

/*/{Protheus.doc} fZInvEhNum
Informa se o texto e uma quantidade valida. Aceita virgula como decimal
(1.234,56) e ponto como decimal quando nao ha virgula (10.5). Recusa
texto vazio, letras e mais de um separador decimal.
@param cTexto Quantidade como veio da planilha.
@return lRet .T. quando o texto pode ser convertido em numero.
@type    Static Function
@author  Vortice Consultoria Mineral
@since   2026/11/09
/*/
Static Function fZInvEhNum(cTexto)

    Local cVal   := AllTrim(cTexto)
    Local nI     := 1
    Local nPonto := 0
    Local lDig   := .F.

    If Empty(cVal)
        Return .F.
    EndIf

    cVal := StrTran(cVal, " ", "")

    If "," $ cVal
        cVal := StrTran(cVal, ".", "")
        cVal := StrTran(cVal, ",", ".")
    EndIf

    While nI <= Len(cVal)

        If SubStr(cVal, nI, 1) == "."
            nPonto++
            If nPonto > 1
                Return .F.
            EndIf
        ElseIf SubStr(cVal, nI, 1) == "-" .And. nI == 1
            // sinal negativo: aceito aqui e recusado depois do calculo
        ElseIf SubStr(cVal, nI, 1) $ "0123456789"
            lDig := .T.
        Else
            Return .F.
        EndIf

        nI++

    EndDo

Return lDig

/*/{Protheus.doc} fZInvNum
Converte a quantidade digitada em numero. Remove espacos; quando existe
virgula, os pontos sao tratados como separador de milhar e a virgula como
decimal. Sem virgula, o ponto e mantido como decimal.
@param cTexto Quantidade como veio da planilha.
@return nVal Quantidade convertida.
@type    Static Function
@author  Vortice Consultoria Mineral
@since   2026/11/09
/*/
Static Function fZInvNum(cTexto)

    Local cVal := AllTrim(cTexto)

    cVal := StrTran(cVal, " ", "")

    If "," $ cVal
        cVal := StrTran(cVal, ".", "")
        cVal := StrTran(cVal, ",", ".")
    EndIf

Return Val(cVal)

/*/{Protheus.doc} fZInvMostraRet
Apresenta as linhas que nao foram importadas (Erro ou Ignorado) em uma
grade, com o motivo de cada uma. Quando todas as linhas foram importadas,
nada e exibido.
@param aRet Resultado por linha do processamento.
@return Nil
@type    Static Function
@author  Vortice Consultoria Mineral
@since   2026/11/09
/*/
Static Function fZInvMostraRet(aRet)

    Local oDlg
    Local oBrw
    Local aGrid := {}
    Local nI    := 0
    Local cTit  := ""

    For nI := 1 To Len(aRet)
        If aRet[nI, 4] == "Erro" .Or. aRet[nI, 4] == "Ignorado"
            AAdd(aGrid, { aRet[nI, 1], aRet[nI, 2], aRet[nI, 3], aRet[nI, 4], aRet[nI, 5] })
        EndIf
    Next nI

    If Empty(aGrid)
        Return Nil
    EndIf

    cTit := "Linhas nao importadas - " + cValToChar(Len(aGrid)) + " de " + cValToChar(Len(aRet))

    // A moldura usa o valor literal, mas os controles sao renderizados com
    // zoom do ambiente (~2x). Por isso a moldura e declarada com o dobro da
    // area ocupada pelos controles, como no CADSZ3.
    DEFINE MSDIALOG oDlg TITLE cTit FROM 000, 000 TO 450, 800 COLORS 0, 16777215 PIXEL

        oBrw := TCBrowse():New( 030, 012, 376, 150,,;
                                { "Linha", "Codigo", "Armazem", "Situacao", "Motivo" },;
                                { 38, 60, 46, 60, 172 },;
                                oDlg,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )

        oBrw:SetArray(aGrid)
        oBrw:bLine := {|| fZInvLinhaBrw(aGrid, oBrw:nAt) }

        TButton():New( 196, 012, "Fechar", oDlg,{|| oDlg:End() },;
         60,012,,,.F.,.T.,.F.,,.F.,,,.F. )

    ACTIVATE MSDIALOG oDlg CENTERED

Return Nil

/*/{Protheus.doc} fZInvLinhaBrw
Devolve os valores da linha atual da grade de erros.
@param aLinhas Array exibido na grade.
@param nAt     Linha atual do browse.
@return aLinha Valores da linha atual.
@type    Static Function
@author  Vortice Consultoria Mineral
@since   2026/11/09
/*/
Static Function fZInvLinhaBrw(aLinhas, nAt)

    If nAt >= 1 .And. nAt <= Len(aLinhas)
        Return { cValToChar(aLinhas[nAt, 1]), aLinhas[nAt, 2], aLinhas[nAt, 3], ;
                 aLinhas[nAt, 4], aLinhas[nAt, 5] }
    EndIf

Return { "", "", "", "", "" }
