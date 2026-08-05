#Include "PROTHEUS.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} MT101OK
Ponto de entrada disparado na validacao de cada item (linha) do
grid da Solicitacao de Compra (SC1 / MATA100).

Regra: aplicado em todos os modos (inclusao e alteracao).
- C1_DATPRF  da linha atual := Date() + 15 dias (somente itens NOVOS)
- C1_EMISSAO da linha atual := Date()        (somente itens NOVOS)
Linhas existentes preservam C1_DATPRF e C1_EMISSAO originais.
Deteccao de item novo via DbSeek em SC1 por C1_NUM+C1_ITEM.
Se a chave nao existir no banco => item novo. Se existir => item existente.

@type     function
@author   Suprimentos
@since    21/05/2026
@version  2.0 - 08/06/2026 - Date() em vez de dDataBase
@return   Logical, .T. = Permite gravar | .F. = Bloqueia gravacao
/*/
//-------------------------------------------------------------------
User Function MT101OK() As Logical

    Local lRet       := .T.  As Logical
    Local aArea      := GetArea()
    Local aAreaSC1   := SC1->(GetArea())
    Local nPosDatPrf := 0    As Numeric
    Local nPosEmissao:= 0    As Numeric
    Local nPosNum    := 0    As Numeric
    Local nPosItem   := 0    As Numeric
    Local lLinNova   := .T.  As Logical
    Local cNumSC     := ""   As Character
    Local cItemSC    := ""   As Character
    Local dNova      := Date() + 15    // data real do servidor (nao dDataBase)

    // Verifica se as variaveis privadas do MATA100 estao disponiveis
    If Type("aHeader") == "U" .Or. Type("aCols") == "U" .Or. Type("nLin") == "U"
        RestArea(aAreaSC1)
        RestArea(aArea)
        Return lRet
    EndIf

    // Localiza posicoes dos campos necessarios no aHeader
    nPosDatPrf  := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_DATPRF" })
    nPosEmissao := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_EMISSAO"})
    nPosNum     := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_NUM"    })
    nPosItem    := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_ITEM"   })

    If nPosDatPrf <= 0
        ConOut("MT101OK: Campo C1_DATPRF nao localizado no aHeader.")
        RestArea(aAreaSC1)
        RestArea(aArea)
        Return lRet
    EndIf

    // Detecta se a linha e nova via DbSeek em SC1 por C1_NUM + C1_ITEM
    // Metodo confiavel independente da estrutura do aCols (com ou sem RecNo)
    // Se a chave nao for encontrada => item novo. Se encontrada => item existente.
    lLinNova := .T.
    If nPosNum > 0 .And. nPosItem > 0
        cNumSC  := AllTrim(cValToChar(aCols[nLin][nPosNum]))
        cItemSC := AllTrim(cValToChar(aCols[nLin][nPosItem]))
        ConOut("MT101OK: nLin=" + cValToChar(nLin) + " C1_NUM=[" + cNumSC + "] C1_ITEM=[" + cItemSC + "] Filial=[" + xFilial("SC1") + "]")
        If !Empty(cNumSC) .And. !Empty(cItemSC)
            SC1->(DbSetOrder(1))
            If SC1->(DbSeek(xFilial("SC1") + cNumSC + cItemSC))
                lLinNova := .F. // Item ja existe no banco
                ConOut("MT101OK: DbSeek ACHOU rec=" + cValToChar(SC1->(RecNo())) + " EMISSAO=" + DtoC(SC1->C1_EMISSAO))
            Else
                ConOut("MT101OK: DbSeek NAO ACHOU -> item novo")
            EndIf
        Else
            ConOut("MT101OK: C1_NUM ou C1_ITEM vazios -> tratado como NOVO")
        EndIf
    Else
        ConOut("MT101OK: nPosNum=" + cValToChar(nPosNum) + " nPosItem=" + cValToChar(nPosItem) + " -> sem chave, tratado como NOVO")
    EndIf

    // Atualiza C1_DATPRF somente em itens novos; existentes preservam data original
    // C1_EMISSAO tambem somente nos novos
    If lLinNova
        aCols[nLin][nPosDatPrf] := dNova
        If nPosEmissao > 0
            aCols[nLin][nPosEmissao] := Date()
        EndIf
        ConOut("MT101OK: Linha " + cValToChar(nLin) + " NOVA - C1_DATPRF=" + DtoC(dNova) + ;
               " | C1_EMISSAO=" + DtoC(Date()))
    Else
        ConOut("MT101OK: Linha " + cValToChar(nLin) + " EXISTENTE [" + cNumSC + "/" + cItemSC + "]" + ;
               " - C1_DATPRF preservado=" + DtoC(aCols[nLin][nPosDatPrf]))
    EndIf

    RestArea(aAreaSC1)
    RestArea(aArea)

Return lRet
