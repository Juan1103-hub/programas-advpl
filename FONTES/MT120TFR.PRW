#Include "Protheus.ch"

/*/{Protheus.doc} MT120TFR
Ponto de Entrada chamado via gatilho SX7 em C7_PRODUTO.
Propaga o C7_TPFRETE da primeira linha do grid para todas as demais
linhas e alimenta o M->C7_TPFRETE (cabecalho do pedido) para gravacao
no SC7 cabecalho (item 0000) pelo MATA121.

Fluxo:
1. Usuario informa o C7_TPFRETE na linha 1 (manualmente).
2. Usuario vai para a linha 2 e informa o C7_PRODUTO.
3. O gatilho SX7 em C7_PRODUTO dispara, chamando U_MT120TFR().
4. Esta funcao:
   a) Le o C7_TPFRETE da linha 1 do aCols.
   b) Atribui o valor a M->C7_TPFRETE (cabecalho) - se ainda vazio.
   c) Propaga o valor para todas as linhas nao-deletadas do aCols.
   d) Retorna o valor para o framework preencher a linha atual.

Configuracao SX7 necessaria (SIGACFG > Base de Dados > Gatilhos):
  Tabela:         SC7
  Campo (origem): C7_PRODUTO
  Cnt. Dominio:   C7_TPFRETE
  Regra:          U_MT120TFR()
  Tipo:           1 - Primario

Resultado: usuario preenche o Tp. Frete apenas na primeira linha;
todas as demais linhas herdam o valor automaticamente, e o SC7
cabecalho (item 0000) grava corretamente.

@type     User Function
@author   Desenvolvimento
@since    25/05/2026
@version  2.0
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
        Next nC
    Next nH

Return 0
