#Include "Protheus.ch"

/*/{Protheus.doc} MT120TFR
Ponto de Entrada chamado via gatilho SX7 em C7_PRODUTO.
Propaga o C7_TPFRETE da primeira linha do grid para todas as demais
linhas e alimenta o M->C7_TPFRETE (cabecalho do pedido) para gravacao
no SC7 cabecalho (item 0000) pelo MATA121.

Tambem forca C7_IPIBRUT = "L" (liquido) em todas as linhas do grid,
garantindo que o calculo do IPI utilize base com desconto integrado
quando o comprador informar a aliquota.

Fluxo:
1. Usuario informa o C7_TPFRETE na linha 1 (manualmente).
2. Usuario vai para a linha 2 e informa o C7_PRODUTO.
3. O gatilho SX7 em C7_PRODUTO dispara, chamando U_MT120TFR().
4. Esta funcao:
   a) Le o C7_TPFRETE da linha 1 do aCols.
   b) Atribui o valor a M->C7_TPFRETE (cabecalho) - se ainda vazio.
   c) Propaga o valor para todas as linhas nao-deletadas do aCols.
   d) Seta C7_IPIBRUT = "L" em todas as linhas + M->C7_IPIBRUT.
   e) Retorna o C7_TPFRETE para o framework preencher a linha atual.

Configuracao SX7 necessaria (SIGACFG > Base de Dados > Gatilhos):
  Tabela:         SC7
  Campo (origem): C7_PRODUTO
  Cnt. Dominio:   C7_TPFRETE
  Regra:          U_MT120TFR()
  Tipo:           1 - Primario

O gatilho SX7 separado para C7_IPIBRUT (seq 002) NAO e mais
necessario - esta funcao assume o set de C7_IPIBRUT = "L".

A mesma rotina tambem disponibiliza U_MT120IPI(), regra para gatilhos
SX7 adicionais em C7_VLDESC e C7_IPI: recalcula o IPI da linha corrente
(C7_BASEIPI/C7_VALIPI) sobre a base liquida (C7_TOTAL - C7_VLDESC),
escrevendo direto no aCols. Assim a tela mostra o valor correto DURANTE
a digitacao, sem depender de gravacao/reabertura. O retorno "L" alimenta
o contra-dominio C7_IPIBRUT (base liquida). O MTA120G3 permanece como
camada de seguranca na gravacao (padrao de camadas do projeto).

Configuracao SX7 adicional (SIGACFG > Base de Dados > Gatilhos):
  Gatilho 2 (C7_VLDESC):
    Tabela:         SC7
    Campo (origem): C7_VLDESC
    Cnt. Dominio:   C7_IPIBRUT
    Regra:          U_MT120IPI()
    Tipo:           1 - Primario
    Sequencia:      proxima disponivel (ex.: 004)
  Gatilho 3 (C7_IPI):
    Tabela:         SC7
    Campo (origem): C7_IPI
    Cnt. Dominio:   C7_IPIBRUT
    Regra:          U_MT120IPI()
    Tipo:           1 - Primario
    Sequencia:      proxima disponivel (ex.: 005)

@type     User Function
@author   Desenvolvimento
@since    25/05/2026
@version  2.2
@return   cTpFrete, Character, Tipo de frete (C/F/S) para o framework
/*/
User Function MT120TFR()
    Local cTpFrete  := ""
    Local cTpFrete1 := ""
    Local nPos      := 0
    Local nI        := 0
    Local nLinhaAtu := 0

    // -------------------------------------------------------------------------
    // Validacao de contexto
    // -------------------------------------------------------------------------
    If Type("aCols") == "U" .Or. Type("aHeader") == "U"
        ConOut("MT120TFR - fora de contexto de grid")
        Return ""
    EndIf

    // -------------------------------------------------------------------------
    // FORCA C7_IPIBRUT = "L" (liquido) em todas as linhas do grid.
    // Chamado no inicio para rodar SEMPRE, independente do frete.
    // -------------------------------------------------------------------------
    MT120SetIPI()

    // Identifica a linha corrente
    If Type("n") != "U" .And. ValType(n) == "N"
        nLinhaAtu := n
    ElseIf Type("nLin") != "U" .And. ValType(nLin) == "N"
        nLinhaAtu := nLin
    Else
        nLinhaAtu := 1
    EndIf

    // -------------------------------------------------------------------------
    // Localiza a coluna C7_TPFRETE no aHeader
    // -------------------------------------------------------------------------
    nPos := MT120Pos("C7_TPFRETE")
    If nPos <= 0
        ConOut("MT120TFR - coluna C7_TPFRETE nao encontrada no aHeader")
        Return ""
    EndIf

    If nPos > Len(aCols[1])
        ConOut("MT120TFR - nPos fora do range do aCols")
        Return ""
    EndIf

    // -------------------------------------------------------------------------
    // CASO 1: Linha 1 - usuario acabou de digitar o Tp. Frete
    //         Apenas propaga para M->C7_TPFRETE (cabecalho) para gravacao
    // -------------------------------------------------------------------------
    If nLinhaAtu == 1
        If ValType(aCols[1][nPos]) == "C"
            cTpFrete1 := Upper(AllTrim(aCols[1][nPos]))
            If !Empty(cTpFrete1)
                cTpFrete1 := Left(cTpFrete1, 1)
            EndIf
        EndIf

        If aScan({"C","F","S"}, {|x| x == cTpFrete1}) > 0
            // Seta o M->C7_TPFRETE (cabecalho) para gravacao no SC7
            If Type("M->C7_TPFRETE") == "C" .And. Empty(M->C7_TPFRETE)
                M->C7_TPFRETE := cTpFrete1
                ConOut("MT120TFR - linha 1: M->C7_TPFRETE = [" + cTpFrete1 + "]")
            EndIf
            // Forca C7_IPIBRUT = "L" em todas as linhas
            Return cTpFrete1
        EndIf

        Return ""
    EndIf

    // -------------------------------------------------------------------------
    // CASO 2: Linhas 2+ - usuario esta digitando o produto
    //         Le da linha 1, propaga para M-> e para todas as linhas
    // -------------------------------------------------------------------------
    If ValType(aCols[1][nPos]) != "C"
        ConOut("MT120TFR - aCols[1][" + cValToChar(nPos) + "] nao e character")
        Return ""
    EndIf

    cTpFrete1 := Upper(AllTrim(aCols[1][nPos]))
    If !Empty(cTpFrete1)
        cTpFrete1 := Left(cTpFrete1, 1)
    EndIf

    ConOut("MT120TFR - linha " + cValToChar(nLinhaAtu) + ": propagando [" + cTpFrete1 + "] da linha 1")

    // Valida que o valor e um codigo valido
    If aScan({"C","F","S"}, {|x| x == cTpFrete1}) == 0
        ConOut("MT120TFR - valor [" + cTpFrete1 + "] invalido, propagacao cancelada")
        Return ""
    EndIf

    // Seta o M->C7_TPFRETE (cabecalho) para gravacao no SC7
    If Type("M->C7_TPFRETE") == "C" .And. Empty(M->C7_TPFRETE)
        M->C7_TPFRETE := cTpFrete1
        ConOut("MT120TFR - M->C7_TPFRETE = [" + cTpFrete1 + "]")
    EndIf

    // Propaga para todas as linhas nao-deletadas (incluindo a atual e a linha em branco)
    For nI := 2 To Len(aCols)
        If Len(aCols[nI]) >= nPos .And. !aCols[nI][Len(aCols[nI])]
            If ValType(aCols[nI][nPos]) == "C"
                aCols[nI][nPos] := cTpFrete1
            EndIf
        EndIf
    Next nI

    ConOut("MT120TFR - propagado para " + cValToChar(Len(aCols) - 1) + " linha(s). Retorno: [" + cTpFrete1 + "]")

Return cTpFrete1

// -------------------------------------------------------------------------
// MT120SetIPI - Forca C7_IPIBRUT = "L" (liquido) em todas as linhas
// -------------------------------------------------------------------------
Static Function MT120SetIPI()
    Local nPosIPI := 0
    Local nI      := 0

    nPosIPI := MT120Pos("C7_IPIBRUT")
    If nPosIPI <= 0
        ConOut("MT120TFR - coluna C7_IPIBRUT nao encontrada no aHeader")
        Return
    EndIf

    If nPosIPI > Len(aCols[1])
        ConOut("MT120TFR - nPosIPI fora do range do aCols")
        Return
    EndIf

    // Seta M->C7_IPIBRUT para o cabecalho
    If Type("M->C7_IPIBRUT") == "C"
        M->C7_IPIBRUT := "L"
    EndIf

    // Propaga C7_IPIBRUT = "L" para todas as linhas nao-deletadas
    For nI := 1 To Len(aCols)
        If Len(aCols[nI]) >= nPosIPI .And. !aCols[nI][Len(aCols[nI])]
            If ValType(aCols[nI][nPosIPI]) == "C"
                aCols[nI][nPosIPI] := "L"
            EndIf
        EndIf
    Next nI

    ConOut("MT120TFR - C7_IPIBRUT setado para [L] em " + cValToChar(Len(aCols)) + " linha(s)")

Return

// -------------------------------------------------------------------------
// MT120Pos - Localiza a posicao de um campo no aHeader
// -------------------------------------------------------------------------
Static Function MT120Pos(cCampo)
    Local nH := 0
    Local nC := 0

    If Type("aHeader") == "U"
        Return 0
    EndIf

    For nH := 1 To Len(aHeader)
        If ValType(aHeader[nH]) != "A"
            Loop
        EndIf
        For nC := 1 To Len(aHeader[nH])
            If ValType(aHeader[nH][nC]) == "C" .And. Upper(AllTrim(aHeader[nH][nC])) == Upper(cCampo)
                Return nH
            EndIf
        Next nC
    Next nH

Return 0

// -------------------------------------------------------------------------
// MT120IPI - Recalcula o IPI da linha corrente do grid sobre a base
// liquida (C7_TOTAL - C7_VLDESC), escrevendo direto no aCols. A tela
// reflete o novo C7_BASEIPI/C7_VALIPI imediatamente, sem depender de
// gravacao. Usada como regra dos gatilhos SX7 em C7_VLDESC e C7_IPI.
// O retorno "L" alimenta o contra-dominio C7_IPIBRUT (base liquida).
// O C7_IPI (aliquota) deve estar preenchido (via TES/produto ou manual).
// -------------------------------------------------------------------------
User Function MT120IPI()
    Local nPosIpi    := 0
    Local nPosDesc   := 0
    Local nPosTotal  := 0
    Local nPosBase   := 0
    Local nPosValIpi := 0
    Local nLinha     := 0
    Local nIpi       := 0
    Local nDesc      := 0
    Local nTotal     := 0
    Local nBase      := 0
    Local nValIPI    := 0

    If Type("aCols") == "U" .Or. Type("aHeader") == "U"
        ConOut("MT120IPI - fora de contexto de grid")
        Return "L"
    EndIf

    // Forca C7_IPIBRUT = "L" (liquido) em todas as linhas
    MT120SetIPI()

    // Identifica a linha corrente
    If Type("n") != "U" .And. ValType(n) == "N"
        nLinha := n
    ElseIf Type("nLin") != "U" .And. ValType(nLin) == "N"
        nLinha := nLin
    Else
        nLinha := 1
    EndIf

    If nLinha < 1 .Or. nLinha > Len(aCols)
        Return "L"
    EndIf

    // Localiza as colunas no aHeader
    nPosIpi    := MT120Pos("C7_IPI")
    nPosDesc   := MT120Pos("C7_VLDESC")
    nPosTotal  := MT120Pos("C7_TOTAL")
    nPosBase   := MT120Pos("C7_BASEIPI")
    nPosValIpi := MT120Pos("C7_VALIPI")

    // Aliquota do IPI
    If nPosIpi > 0 .And. nPosIpi <= Len(aCols[nLinha])
        nIpi := aCols[nLinha][nPosIpi]
        If ValType(nIpi) != "N"
            nIpi := 0
        EndIf
    EndIf

    // Desconto da linha
    If nPosDesc > 0 .And. nPosDesc <= Len(aCols[nLinha])
        nDesc := aCols[nLinha][nPosDesc]
        If ValType(nDesc) != "N" .Or. nDesc < 0
            nDesc := 0
        EndIf
    EndIf

    // Total bruto da linha
    If nPosTotal > 0 .And. nPosTotal <= Len(aCols[nLinha])
        nTotal := aCols[nLinha][nPosTotal]
        If ValType(nTotal) != "N" .Or. nTotal < 0
            nTotal := 0
        EndIf
    EndIf

    If nIpi > 0
        nBase := nTotal - nDesc
        If nBase < 0
            nBase := 0
        EndIf

        nValIPI := Round(nBase * nIpi / 100, 2)

        If nPosBase > 0 .And. nPosBase <= Len(aCols[nLinha])
            aCols[nLinha][nPosBase] := nBase
        EndIf

        If nPosValIpi > 0 .And. nPosValIpi <= Len(aCols[nLinha])
            aCols[nLinha][nPosValIpi] := nValIPI
        EndIf

        // Atualiza o motor fiscal (MaFis) para que o Total do Pedido
        // no rodape tambem use o IPI liquido (senao o framework usa o bruto).
        If FindFunction("MaFisRef")
            MaFisRef("IT_VALIPI", "MT120", nValIPI)
            MaFisRef("IT_BASEIPI", "MT120", nBase)
        EndIf

        ConOut("MT120IPI - linha " + cValToChar(nLinha) + " BaseIPI=" + cValToChar(nBase) + " ValIPI=" + cValToChar(nValIPI))
    EndIf

Return "L"
