//Bibliotecas
#Include "TOTVS.ch"

#DEFINE CRLF Chr(13)+Chr(10)

//Posicoes do Array (colunas do CSV separado por ;)
Static nPosCodigo  := 1  // Coluna A - Codigo do Item (B1_COD)
Static nPosDescRes := 2  // Coluna B - Descricao Resumida (B1_DESC)
Static nPosDescCom := 3  // Coluna C - Descricao Completa (B1_ZDESCF)

/*/{Protheus.doc} ZATUDESC
Funcao para atualizar em massa as Descricoes do Produto
(B1_DESC e B1_ZDESCF) a partir de arquivo CSV.
O conteudo e gravado exatamente como estiver na planilha.
@author  Vortice Consultoria Mineral
@since   2026/10/09
@version 1.0
@type    function
/*/

User Function ZATUDESC()
    Local aArea     := GetArea()
    Private cArqOri := ""

    // TELA 1 - Apresentacao antes de selecionar o arquivo
    If !MsgYesNo("ATUALIZACAO EM MASSA - DESCRICOES DO PRODUTO"   + CRLF + ;
                 CRLF + ;
                 "Este programa ira atualizar os campos:"           + CRLF + ;
                 "  B1_DESC  (Descricao Resumida)"                  + CRLF + ;
                 "  B1_ZDESCF (Descricao Completa)"                 + CRLF + ;
                 "no cadastro de produtos (SB1) a partir de um"     + CRLF + ;
                 "arquivo CSV."                                     + CRLF + ;
                 CRLF + ;
                 "Estrutura esperada do arquivo CSV:"               + CRLF + ;
                 "  Coluna A: Codigo do Item (B1_COD)"              + CRLF + ;
                 "  Coluna B: Descricao Resumida (B1_DESC)"         + CRLF + ;
                 "  Coluna C: Descricao Completa (B1_ZDESCF)"       + CRLF + ;
                 CRLF + ;
                 "As descricoes serao gravadas exatamente como"     + CRLF + ;
                 "estiverem na planilha."                           + CRLF + ;
                 CRLF + ;
                 "Deseja continuar?", "Atualiz. Descricoes do Produto")
        RestArea(aArea)
        Return
    EndIf

    // Seleciona o arquivo CSV
    cArqOri := tFileDialog("CSV files (*.csv)", "Selecao do Arquivo CSV", , , .F., )

    If !Empty(cArqOri)

        If File(cArqOri) .And. Upper(SubStr(cArqOri, RAt('.', cArqOri) + 1, 3)) == 'CSV'

            // TELA 2 - Deseja gravar?
            If !MsgYesNo("Deseja gravar as alteracoes?", "Confirmar Gravacao")
                RestArea(aArea)
                Return
            EndIf

            // Processa com barra de progresso
            Processa({|| fZDescProc()}, "Processando arquivo...")

        Else
            MsgStop("Arquivo e/ou extensao invalida! Use apenas .csv", "Atencao")
        EndIf

    EndIf

    RestArea(aArea)
Return

/*-------------------------------------------------------------------------------*
 | Func:  fZDescProc                                                             |
 | Desc:  Le o CSV e atualiza B1_DESC e B1_ZDESCF no SB1                        |
 *-------------------------------------------------------------------------------*/

Static Function fZDescProc()
    Local aArea      := GetArea()
    Local nTotLinhas := 0
    Local nLinhaAtu  := 0
    Local cLinAtu    := ""
    Local aLinha     := {}
    Local oArquivo
    Local aLinhas
    Local cCodItem   := ""
    Local cDescRes   := ""
    Local cDescCom   := ""
    Local nOk        := 0
    Local nErro      := 0
    Local nSkip      := 0

    // Tenta realizar a abertura do arquivo
    oArquivo := FWFileReader():New(cArqOri)

    If oArquivo:Open()

        If !oArquivo:EoF()

            // Define tamanho da regua de progresso
            aLinhas    := oArquivo:GetAllLines()
            nTotLinhas := Len(aLinhas)
            ProcRegua(nTotLinhas)

            // Fecha e reabre para voltar ao inicio
            oArquivo:Close()
            oArquivo := FWFileReader():New(cArqOri)
            oArquivo:Open()

            // Le todas as linhas
            While oArquivo:HasLine()

                nLinhaAtu++
                IncProc("Processando linha " + cValToChar(nLinhaAtu) + ;
                        " de " + cValToChar(nTotLinhas) + "...")

                // Transforma o texto da linha em array (respeita campos entre aspas)
                cLinAtu := oArquivo:GetLine()
                aLinha  := fCsvSplit(cLinAtu, ";")

// Ignora linha de cabecalho - somente a 1a linha (evita pular produtos cujo texto contenha "codigo")
                If nLinhaAtu == 1 .And. "digo" $ Lower(cLinAtu)
                    Loop
                EndIf

                // Valida se o array tem colunas suficientes
                If Len(aLinha) < 3
                    nSkip++
                    Loop
                EndIf

                cCodItem := AllTrim(aLinha[nPosCodigo])
                cDescRes := aLinha[nPosDescRes]
                cDescCom := aLinha[nPosDescCom]

                If Empty(cCodItem)
                    nSkip++
                    Loop
                EndIf

                // Ao menos uma das descricoes deve ser informada
                If Empty(AllTrim(cDescRes)) .And. Empty(AllTrim(cDescCom))
                    nErro++
                    Loop
                EndIf

                // Tenta posicionar no registro via DbSeek
                DbSelectArea("SB1")
                SB1->(DbSetOrder(1))

                If SB1->(DbSeek(FWxFilial("SB1") + PADR(cCodItem, TamSX3("B1_COD")[1])))

                    // Faz a gravacao via RecLock - conteudo exatamente como na planilha.
                    // Atribuicao direta (sem PADR): o Protheus ajusta o padding em campos C
                    // e grava o texto integral em campos MEMO - o PADR truncava a descricao
                    // completa no tamanho do SX3 (campos memo retornam 10).
                    RecLock("SB1", .F.)
                        If !Empty(AllTrim(cDescRes))
                            SB1->B1_DESC := AllTrim(cDescRes)
                        EndIf
                        If !Empty(AllTrim(cDescCom))
                            SB1->B1_ZDESCF := AllTrim(cDescCom)
                        EndIf
                    SB1->(MsUnlock())
                    nOk++

                Else
                    nErro++
                EndIf

            EndDo

        Else
            MsgStop("Arquivo nao tem conteudo!", "Atencao")
        EndIf

        oArquivo:Close()

    Else
        MsgStop("Arquivo nao pode ser aberto!", "Atencao")
    EndIf

    // Mensagem final de resultado
    MsgInfo("Processamento concluido!"                              + CRLF + ;
            CRLF + ;
            "Data/Hora : " + DToC(Date()) + " " + Time()            + CRLF + ;
            CRLF + ;
            "Ok        : " + cValToChar(nOk)                        + CRLF + ;
            "Erros     : " + cValToChar(nErro)                      + CRLF + ;
            "Ignorados : " + cValToChar(nSkip), ;
            "Atualiz. Descricoes do Produto")

    RestArea(aArea)
Return

/*-------------------------------------------------------------------------------*
 | Func:  fCsvSplit                                                             |
 | Desc:  Quebra uma linha CSV em campos respeitando campos entre aspas duplas.  |
 |        Dentro de aspas o separador nao divide o campo e aspas duplas ("")      |
 |        viram uma aspas literal no conteudo.                                   |
 *-------------------------------------------------------------------------------*/

Static Function fCsvSplit(cLinha, cSep)
    Local aCampos := {}
    Local cCampo  := ""
    Local lAspas  := .F.
    Local nI      := 1
    Local cChar   := ""

    While nI <= Len(cLinha)
        cChar := SubStr(cLinha, nI, 1)

        If cChar == '"'
            If lAspas .And. SubStr(cLinha, nI + 1, 1) == '"'
                // Aspas dupla dentro de campo entre aspas = aspas literal
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

    // Ultimo campo
    AAdd(aCampos, cCampo)
Return aCampos
