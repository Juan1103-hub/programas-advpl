#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} ZZ3NORM
Rotina de normalizacao do campo ZZ3_ITENS para garantir zero-fill
de 2 digitos em todos os itens (padrao C7_ITEM).

Esta rotina DEVE ser executada ANTES de subir o patch ZLOGCOL.PRW
que altera a logica de filtro/programacao para item-nivel, pois
a funcao ItemEmZZ3() depende do match exato ",XX," para evitar
falsos positivos (ex: item "01" casar com "10" ou "11").

Pre-requisitos:
  - Backup da tabela ZZ3: SELECT * INTO ZZ3_BKP FROM ZZ3010
  - Rodar em homologacao ANTES de producao
  - Recomendado rodar FORA do horario de pico

@type User Function
@author Suprimentos
@since 25/06/2026
@example
    u_ZZ3NORM()
/*/
User Function ZZ3NORM()
    Local aArea     := GetArea()
    Local cAlias    := GetNextAlias()
    Local cItens    := ""
    Local cItensNew := ""
    Local aItens    := {}
    Local nI        := 0
    Local nTotal    := 0
    Local nAtu      := 0
    Local nPulados  := 0
    Local cMsg      := ""

    cMsg := "Normalizacao de ZZ3_ITENS (zero-fill 2 digitos)" + CRLF + CRLF
    cMsg += "Esta rotina ira percorrer TODOS os registros nao-rascunho" + CRLF
    cMsg += "da ZZ3 e normalizar o campo ZZ3_ITENS." + CRLF + CRLF
    cMsg += "Recomendacao: faca backup da tabela antes de continuar." + CRLF + CRLF
    cMsg += "Deseja prosseguir?"
    If !MsgYesNo(cMsg, "Confirmar")
        RestArea(aArea)
        Return
    EndIf

    BEGIN TRANSACTION

    BeginSql Alias cAlias
        SELECT R_E_C_N_O_ AS RECNO, ZZ3_ITENS
        FROM %Table:ZZ3%
        WHERE %NotDel%
          AND ZZ3_NUM NOT LIKE 'RASC%'
          AND ZZ3_ITENS <> ' '
          AND ZZ3_ITENS IS NOT NULL
    EndSql

    While !(cAlias)->(Eof())
        nTotal++
        cItens    := AllTrim((cAlias)->ZZ3_ITENS)
        cItensNew := ""

        If Empty(cItens)
            nPulados++
            (cAlias)->(DbSkip())
            Loop
        EndIf

        // Quebra CSV (suporta virgula ou pipe como separador)
        If At("|", cItens) > 0
            aItens := StrTokArr(cItens, "|")
        Else
            aItens := StrTokArr(cItens, ",")
        EndIf

        For nI := 1 To Len(aItens)
            If !Empty(cItensNew)
                cItensNew += ","
            EndIf
            cItensNew += StrZero(Val(AllTrim(aItens[nI])), 2)
        Next nI

        // Atualiza apenas se houve mudanca
        If cItensNew <> cItens
            DbSelectArea("ZZ3")
            ZZ3->(DbGoTo((cAlias)->RECNO))
            RecLock("ZZ3", .F.)
            ZZ3->ZZ3_ITENS := cItensNew
            MsUnlock()
            nAtu++
        Else
            nPulados++
        EndIf

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    END TRANSACTION

    cMsg := "Normalizacao concluida!" + CRLF + CRLF
    cMsg += "Total de registros verificados: " + cValToChar(nTotal) + CRLF
    cMsg += "Registros atualizados:          " + cValToChar(nAtu) + CRLF
    cMsg += "Registros pulados (ja OK):      " + cValToChar(nPulados) + CRLF + CRLF
    cMsg += "Proximo passo: compilar e subir o patch ZLOGCOL.PRW."
    MsgInfo(cMsg, "Concluido")

    RestArea(aArea)
Return
