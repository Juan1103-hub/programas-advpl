//Bibliotecas
#Include "TOTVS.ch"
#Include "TopConn.ch"

#DEFINE CRLF Chr(13)+Chr(10)

//Posicoes do Array (colunas do CSV separado por ;)
Static nPosCodigo := 1  // Coluna A - Codigo do Item
Static nPosConta  := 2  // Coluna B - Conta Contabil (B1_XCTAEST)

/*/{Protheus.doc} ZCTAEST
Funcao para atualizar em massa a Conta Contabil de Estoque (B1_XCTAEST)
a partir de arquivo CSV
@author  Equipe de Desenvolvimento
@since   2025
@version 1.0
@type    function
/*/

User Function ZCTAEST()
    Local aArea     := GetArea()
    Private cArqOri := ""
    Private lSimula := .F.

    // TELA 1 - Apresentacao antes de selecionar o arquivo
    If !MsgYesNo("ATUALIZACAO EM MASSA - CONTA CONTABIL DE ESTOQUE"  + CRLF + ;
                 CRLF + ;
                 "Este programa ira atualizar o campo"                + CRLF + ;
                 "B1_XCTAEST (Conta Contabil de Estoque) no cadastro" + CRLF + ;
                 "de produtos (SB1) a partir de um arquivo CSV."      + CRLF + ;
                 CRLF + ;
                 "Estrutura esperada do arquivo CSV:"                 + CRLF + ;
                 "  Coluna A: Codigo do Item (B1_COD)"                + CRLF + ;
                 "  Coluna B: Conta Contabil (B1_XCTAEST)"            + CRLF + ;
                 CRLF + ;
                 "Deseja continuar?", "Atualiz. Conta Contabil de Estoque")
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

            lSimula := .F.

            // Processa com barra de progresso
            Processa({|| fZCTAProc()}, "Processando arquivo...")

        Else
            MsgStop("Arquivo e/ou extensao invalida! Use apenas .csv", "Atencao")
        EndIf

    EndIf

    RestArea(aArea)
Return

/*-------------------------------------------------------------------------------*
 | Func:  fZCTAProc                                                              |
 | Desc:  Le o CSV e atualiza o campo B1_XCTAEST no SB1                         |
 *-------------------------------------------------------------------------------*/

Static Function fZCTAProc()
    Local aArea      := GetArea()
    Local nTotLinhas := 0
    Local nLinhaAtu  := 0
    Local cLinAtu    := ""
    Local aLinha     := {}
    Local oArquivo
    Local aLinhas
    Local cCodItem   := ""
    Local cConta     := ""
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

                // Transforma o texto da linha em array
                cLinAtu := oArquivo:GetLine()
                aLinha  := StrTokArr(cLinAtu, ";")

                // Ignora linha de cabecalho
                If "codigo" $ Lower(cLinAtu) .Or. "código" $ Lower(cLinAtu)
                    Loop
                EndIf

                // Valida se o array tem colunas suficientes
                If Len(aLinha) < 2
                    nSkip++
                    Loop
                EndIf

                cCodItem := AllTrim(aLinha[nPosCodigo])
                cConta   := AllTrim(aLinha[nPosConta])

                If Empty(cCodItem)
                    nSkip++
                    Loop
                EndIf

                If Empty(cConta)
                    nErro++
                    Loop
                EndIf

                // Tenta posicionar no registro via DbSeek
                DbSelectArea("SB1")
                SB1->(DbSetOrder(1))

                If SB1->(DbSeek(FWxFilial("SB1") + PADR(cCodItem, TamSX3("B1_COD")[1])))

                    // Faz a gravacao via RecLock
                    If !lSimula
                        RecLock("SB1", .F.)
                            SB1->B1_XCTAEST := PADR(cConta, TamSX3("B1_XCTAEST")[1])
                        SB1->(MsUnlock())
                    EndIf
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
            "Modo      : " + IIF(lSimula, "SIMULACAO", "GRAVADO")  + CRLF + ;
            "Data/Hora : " + DToC(Date()) + " " + Time()           + CRLF + ;
            CRLF + ;
            "Ok        : " + cValToChar(nOk)                       + CRLF + ;
            "Erros     : " + cValToChar(nErro)                     + CRLF + ;
            "Ignorados : " + cValToChar(nSkip), ;
            "Atualiz. Conta Contabil de Estoque")

    RestArea(aArea)
Return
