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

A partir da versao 2.3 a rotina chama tambem MT120Replica(), que
propaga C7_XESTOQ1, C7_EC05DB e C7_ZREGUL da primeira linha do grid
para as demais linhas MANUAIS (sem C7_NUMSC), somente quando o campo
destino esta vazio - preserva edicoes manuais e nao toca em linhas
originadas de Solicitacao de Compra. O C7_TPFRETE continua propagado
pelo fluxo original desta funcao.

Versao 2.4: o preenchimento IMEDIATO da LINHA CORRENTE passou a ser
feito por gatilhos de RETORNO (contra-dominio) - U_MT120RX1/2/3 -,
porque a escrita direta no aCols da linha em edicao durante o gatilho
de C7_PRODUTO e descartada pelo MSGETDADOS (webapp). A escrita direta
para as DEMAIS linhas (MT120Replica) e a copia de seguranca pre-save
(PE MT120OK) permanecem inalteradas.

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
@version  2.4
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

    // -------------------------------------------------------------------------
    // Replica C7_XESTOQ1 / C7_EC05DB / C7_ZREGUL da linha 1 para as
    // demais linhas manuais (somente campos vazios). Roda sempre.
    // -------------------------------------------------------------------------
    MT120Replica()

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
// MT120Replica - Propaga C7_XESTOQ1, C7_EC05DB e C7_ZREGUL da linha 1
// para as demais linhas NAO-deletadas que sejam MANUAIS (C7_NUMSC vazio).
// Somente copia quando o campo destino esta vazio - preserva edicoes
// manuais ja digitadas nas demais linhas e nao toca em linhas originadas
// de Solicitacao de Compra (essas recebem o valor via MT120ISC/MTA120G3).
// -------------------------------------------------------------------------
Static Function MT120Replica()
    Local aCampos  := {"C7_XESTOQ1", "C7_EC05DB", "C7_ZREGUL"}
    Local aPos     := {}
    Local nPosSC   := 0
    Local nI       := 0
    Local nC       := 0
    Local nCopias  := 0
    Local xOrigem  := Nil

    If Type("aCols") == "U" .Or. Type("aHeader") == "U"
        Return
    EndIf

    If Len(aCols) < 2
        Return
    EndIf

    // Sem coluna C7_NUMSC nao e possivel garantir "somente pedido manual"
    nPosSC := MT120Pos("C7_NUMSC")
    If nPosSC <= 0 .Or. nPosSC > Len(aCols[1])
        FWLogMsg("WARN", , "SUPR", "MT120TFR", , "01", ;
                 "MT120Replica - coluna C7_NUMSC nao encontrada no aHeader; replicacao cancelada")
        Return
    EndIf

    // Localiza as colunas dos campos a propagar
    For nC := 1 To Len(aCampos)
        AAdd(aPos, MT120Pos(aCampos[nC]))
    Next nC

    // Linha 1 deletada ou veio de SC -> nada a replicar como fonte manual
    If aCols[1][Len(aCols[1])]
        Return
    EndIf

    If !Empty(aCols[1][nPosSC])
        Return
    EndIf

    For nC := 1 To Len(aCampos)

        If aPos[nC] <= 0 .Or. aPos[nC] > Len(aCols[1])
            Loop
        EndIf

        xOrigem := aCols[1][aPos[nC]]

        // Origem vazia ou de tipo inesperado -> nao propaga este campo
        If ValType(xOrigem) != "C" .Or. Empty(xOrigem)
            Loop
        EndIf

        For nI := 2 To Len(aCols)

            // Pula linhas deletadas
            If aCols[nI][Len(aCols[nI])]
                Loop
            EndIf

            // Pula linhas originadas de Solicitacao de Compra
            If !Empty(aCols[nI][nPosSC])
                Loop
            EndIf

            // So preenche onde esta vazio (preserva edicao manual)
            If Empty(aCols[nI][aPos[nC]])
                aCols[nI][aPos[nC]] := xOrigem
                nCopias++
            EndIf

        Next nI

    Next nC

    If nCopias > 0
        FWLogMsg("INFO", , "SUPR", "MT120TFR", , "01", ;
                 "MT120Replica - " + cValToChar(nCopias) + " campo(s) copiado(s) da linha 1 para linhas manuais")
    EndIf

Return

// -------------------------------------------------------------------------
// Gatilhos de RETORNO (contra-dominio) para preenchimento IMEDIATO da
// LINHA CORRENTE. O framework SX7 preenche o campo da linha em edicao
// com o retorno da regra - mecanismo que sobrevive a re-sincronizacao
// da linha pelo MSGETDADOS (webapp), ao contrario da escrita direta no
// aCols durante o gatilho de C7_PRODUTO.
// Configuracao SX7 (Configurador > Gatilhos, tabela SC7, campo C7_PRODUTO):
//   Cnt. dominio C7_XESTOQ1 -> Regra U_MT120RX1()
//   Cnt. dominio C7_EC05DB  -> Regra U_MT120RX2()
//   Cnt. dominio C7_ZREGUL  -> Regra U_MT120RX3()
// -------------------------------------------------------------------------

User Function MT120RX1()
Return MT120RepVal("C7_XESTOQ1")

User Function MT120RX2()
Return MT120RepVal("C7_EC05DB")

User Function MT120RX3()
Return MT120RepVal("C7_ZREGUL")

// -------------------------------------------------------------------------
// MT120RepVal - Retorna o valor do campo da linha 1 do aCols para o
// framework preencher a linha corrente (contra-dominio do gatilho em
// C7_PRODUTO). Preserva: linha 1 deletada ou originada de SC, linha
// corrente originada de SC e campo corrente ja preenchido manualmente
// (retorna o proprio valor - nao sobrescreve edicao).
// Sem a coluna C7_NUMSC no aHeader assume pedido manual.
// -------------------------------------------------------------------------
Static Function MT120RepVal(cCampo)
    Local nPosCpo := 0
    Local nPosSC  := 0
    Local nLinha  := 1
    Local xOrigem := Nil
    Local xAtual  := Nil

    If Type("aCols") == "U" .Or. Type("aHeader") == "U"
        Return Nil
    EndIf

    nPosCpo := MT120Pos(cCampo)
    If nPosCpo <= 0 .Or. nPosCpo > Len(aCols[1])
        Return Nil
    EndIf

    // Identifica a linha corrente (fallback linha 1)
    If Type("n") != "U" .And. ValType(n) == "N"
        nLinha := n
    ElseIf Type("nLin") != "U" .And. ValType(nLin) == "N"
        nLinha := nLin
    Else
        nLinha := 1
    EndIf
    If nLinha < 1 .Or. nLinha > Len(aCols)
        nLinha := 1
    EndIf

    // Valor atual da propria linha = retorno neutro quando nao deve replicar
    xAtual := aCols[nLinha][nPosCpo]

    // Linha 1 deletada -> nao replica
    If aCols[1][Len(aCols[1])]
        Return xAtual
    EndIf

    // Localiza C7_NUMSC; sem a coluna no aHeader assume pedido manual
    nPosSC := MT120Pos("C7_NUMSC")
    If nPosSC > 0 .And. nPosSC <= Len(aCols[1])
        // Linha 1 ou linha corrente originadas de SC -> nao replica
        If !Empty(aCols[1][nPosSC]) .Or. !Empty(aCols[nLinha][nPosSC])
            Return xAtual
        EndIf
    EndIf

    xOrigem := aCols[1][nPosCpo]

    // Origem vazia ou tipo incompativel -> mantem o valor atual
    If Empty(xOrigem) .Or. ValType(xOrigem) != ValType(xAtual)
        Return xAtual
    EndIf

    // Campo corrente ja preenchido -> preserva edicao manual
    If !Empty(xAtual)
        Return xAtual
    EndIf

Return xOrigem

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
