#Include "Protheus.ch"

/*/{Protheus.doc} FPOSPOSIC
Regra do gatilho SX7 (CP_PRODUTO -> CP_POSIC) da Pre-Requisicao (SCP).
Retorna a Posicao do Estoque do produto cadastrado na ZC1, preenchendo
o campo CP_POSIC para exibicao na coluna Posicao da rotina
Baixa de Pre-Requisicoes (MATA185).

Fluxo: solicitante cria a SA -> gatilho grava CP_POSIC -> almoxarife
abre a Baixa de Pre-Requisicoes com a Posicao ja visivel.

Configuracao SX7 (SIGACFG > Base de Dados > Dicionario > Gatilhos):
  Campo       (X7_CAMPO)   : CP_PRODUTO
  Sequencia   (X7_SEQUENC) : 001 (ou proxima disponivel)
  Cnt. Dominio(X7_CDOMIN)  : CP_POSIC
  Tipo        (X7_TIPO)    : 1 - Primario
  Regra       (X7_REGRA)   : U_FPOSPOSIC()
  Posiciona   (X7_SEEK)    : 2 - Nao
  Alias/Ordem/Chave/Condicao : (vazios)

@type    User Function
@author  Suprimentos
@since   2026
@return  cPosic, Character, Posicao do estoque do produto (ZC1_POSIC)
         ou string vazia quando o produto nao tem posicao cadastrada
/*/
User Function FPOSPOSIC()

    Local aArea  := GetArea()
    Local cProd  := ""
    Local cPosic := ""
    Local nPos   := 0

    // Contexto grid (Modelo 2): produto da linha corrente do aCols
    If Type("aCols") == "A" .And. Type("aHeader") == "A"
        nPos := aScan(aHeader, {|x| AllTrim(x[2]) == "CP_PRODUTO"})
        If nPos > 0 .And. Type("n") == "N" .And. n >= 1 .And. n <= Len(aCols)
            cProd := aCols[n][nPos]
        EndIf
    EndIf

    // Contexto formulario simples: memoria M->
    If Empty(cProd) .And. Type("M->CP_PRODUTO") == "C"
        cProd := M->CP_PRODUTO
    EndIf

    // Busca a posicao na ZC1 (indice 1: ZC1_FILIAL + ZC1_ITEM)
    If !Empty(cProd)
        DbSelectArea("ZC1")
        ZC1->(DbSetOrder(1))
        If ZC1->(MsSeek(xFilial("ZC1") + PadR(AllTrim(cProd), TamSX3("ZC1_ITEM")[1])))
            cPosic := ZC1->ZC1_POSIC
        EndIf
    EndIf

    RestArea(aArea)

Return cPosic
