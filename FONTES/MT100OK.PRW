#Include "protheus.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} MT100OK
Ponto de entrada disparado na confirmacao/gravacao da Solicitacao
de Compra (SC1 / MATA100), antes de MATA100 gravar os registros.

Regra: aplicado em todos os modos (inclusao e alteracao).
Garante que no momento do Salvar C1_DATPRF de TODOS os itens do grid
seja Date() + 15 dias. Nao altera C1_EMISSAO (responsabilidade do MT101OK).

Esta funcao complementa MT101OK: enquanto MT101OK atualiza o aCols
quando o usuario confirma cada linha, MT100OK garante a atualizacao
no momento exato do Salvar, antes do loop de gravacao do MATA100.

@type     User Function
@author   Suprimentos
@since    21/05/2026
@version  2.0 - 08/06/2026 - Date() em vez de dDataBase
@return   lRet, Logical, .T. = Permite gravar | .F. = Bloqueia gravacao
/*/
//-------------------------------------------------------------------
User Function MT100OK()

    Local lRet       := .T.  As Logical
    Local aArea      := GetArea()
    Local nPosDatPrf := 0    As Numeric
    Local nX         := 0    As Numeric
    Local dNova      := Date() + 15    // data real do servidor (nao dDataBase)

    // Verifica se as variaveis privadas do MATA100 estao disponiveis
    If Type("aHeader") == "U" .Or. Type("aCols") == "U"
        RestArea(aArea)
        Return lRet
    EndIf

    // Localiza posicao do campo C1_DATPRF no aHeader
    nPosDatPrf := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_DATPRF"})

    If nPosDatPrf <= 0
        ConOut("MT100OK: Campo C1_DATPRF nao localizado no aHeader.")
        RestArea(aArea)
        Return lRet
    EndIf

    // Atualiza C1_DATPRF de todos os itens nao deletados
    For nX := 1 To Len(aCols)
        If aCols[nX][Len(aHeader) + 1]
            Loop
        EndIf
        aCols[nX][nPosDatPrf] := dNova
    Next nX

    ConOut("MT100OK: Todos os itens com C1_DATPRF=" + DtoC(dNova))

    RestArea(aArea)

Return lRet
