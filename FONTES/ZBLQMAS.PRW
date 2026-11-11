//Bibliotecas
#Include "TOTVS.ch"

#DEFINE CRLF Chr(13)+Chr(10)

//Posicoes do Array (colunas do CSV separado por ;)
Static nPosCodigo   := 1  // Coluna A - Codigo do Item (B1_COD)
Static nPosSituacao := 2  // Coluna B - Situacao desejada (B1_MSBLQL): 1 = bloqueado / 2 = desbloqueado

/*/{Protheus.doc} ZBLQMAS
Funcao para bloquear ou desbloquear em massa cadastros de produtos
atualizando o campo B1_MSBLQL (Situacao do Cadastro) da tabela SB1
a partir de arquivo CSV.
Cada linha traz o codigo do produto e a situacao desejada, permitindo
bloquear e desbloquear produtos na mesma importacao.
Segue o mesmo padrao de funcionamento, importacao e processamento
da rotina ZATUDESC (Atualizar Descricoes).
@author  Vortice Consultoria Mineral
@since   2026/10/13
@version 1.0
@type    function
/*/

User Function ZBLQMAS()
    Local aArea     := GetArea()
    Private cArqOri := ""

    // TELA 1 - Apresentacao antes de selecionar o arquivo
    If !MsgYesNo("BLOQUEIO / DESBLOQUEIO EM MASSA - CADASTROS DE PRODUTO"   + CRLF + ;
                 CRLF + ;
                 "Este programa ira atualizar o campo:"                     + CRLF + ;
                 "  B1_MSBLQL (Situacao do Cadastro, tabela SB1)"           + CRLF + ;
                 CRLF + ;
                 "Estrutura esperada do arquivo CSV:"                       + CRLF + ;
                 "  Coluna A: Codigo do Item (B1_COD)"                      + CRLF + ;
                 "  Coluna B: Situacao desejada (B1_MSBLQL)"                + CRLF + ;
                 "            1 = Sim - cadastro bloqueado"                 + CRLF + ;
                 "            2 = Nao - cadastro desbloqueado"              + CRLF + ;
                 CRLF + ;
                 "E permitido bloquear e desbloquear produtos"              + CRLF + ;
                 "na mesma importacao, respeitando a situacao"              + CRLF + ;
                 "informada em cada linha da planilha."                     + CRLF + ;
                 CRLF + ;
                 "Deseja continuar?", "Bloqueio/Desbloqueio em Massa")
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
            Processa({|| fZBlqProc()}, "Processando arquivo...")

        Else
            MsgStop("Arquivo e/ou extensao invalida! Use apenas .csv", "Atencao")
        EndIf

    EndIf

    RestArea(aArea)
Return

/*-------------------------------------------------------------------------------*
 | Func:  fZBlqProc                                                             |
 | Desc:  Le o CSV e atualiza B1_MSBLQL no SB1 (bloqueia/desbloqueia)           |
 *-------------------------------------------------------------------------------*/

Static Function fZBlqProc()
    Local aArea      := GetArea()
    Local nTotLinhas := 0
    Local nLinhaAtu  := 0
    Local cLinAtu    := ""
    Local aLinha     := {}
    Local oArquivo
    Local aLinhas
    Local cCodItem   := ""
    Local cSituacao  := ""
    Local nOk        := 0
    Local nBloq      := 0
    Local nDesbloq   := 0
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
                If nLinhaAtu == 1 .And. ("digo" $ Lower(cLinAtu) .Or. "ituacao" $ Lower(cLinAtu))
                    Loop
                EndIf

                // Valida se o array tem colunas suficientes
                If Len(aLinha) < 2
                    nSkip++
                    Loop
                EndIf

                cCodItem  := AllTrim(aLinha[nPosCodigo])
                cSituacao := AllTrim(aLinha[nPosSituacao])

                If Empty(cCodItem)
                    nSkip++
                    Loop
                EndIf

                // A situacao deve ser 1 (bloqueado) ou 2 (desbloqueado)
                If cSituacao <> "1" .And. cSituacao <> "2"
                    nErro++
                    Loop
                EndIf

                // Tenta posicionar no registro via DbSeek
                DbSelectArea("SB1")
                SB1->(DbSetOrder(1))

                If SB1->(DbSeek(FWxFilial("SB1") + PADR(cCodItem, TamSX3("B1_COD")[1])))

                    // Gravacao direta do flag de situacao - mesmo padrao do ZATUDESC
                    // (a atribuicao direta permite bloquear e desbloquear na mesma
                    //  importacao, respeitando a situacao de cada linha)
                    RecLock("SB1", .F.)
                        SB1->B1_MSBLQL := cSituacao
                    SB1->(MsUnlock())

                    nOk++
                    If cSituacao == "1"
                        nBloq++
                    Else
                        nDesbloq++
                    EndIf

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
    MsgInfo("Processamento concluido!"                                  + CRLF + ;
            CRLF + ;
            "Data/Hora    : " + DToC(Date()) + " " + Time()             + CRLF + ;
            CRLF + ;
            "Ok           : " + cValToChar(nOk)                         + CRLF + ;
            "Bloqueados   : " + cValToChar(nBloq)                       + CRLF + ;
            "Desbloqueados: " + cValToChar(nDesbloq)                    + CRLF + ;
            "Erros        : " + cValToChar(nErro)                       + CRLF + ;
            "Ignorados    : " + cValToChar(nSkip), ;
            "Bloqueio/Desbloqueio em Massa")

    RestArea(aArea)
Return

/*-------------------------------------------------------------------------------*
 | Func:  fCsvSplit                                                             |
 | Desc:  Quebra uma linha CSV em campos respeitando campos entre aspas duplas.  |
 |        Dentro de aspas o separador nao divide o campo e aspas duplas (""      |
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
