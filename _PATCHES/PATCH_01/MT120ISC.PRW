#Include "totvs.ch"

/*/{Protheus.doc} MT120ISC
Ponto de entrada executado ao vincular item da Solicitacao de Compra (SC1)
ao grid do Pedido de Compras (MATA120 / SC7). Permite manipular o aCols do
pedido antes da apresentacao ao usuario.

Objetivo: copiar o campo Regularizacao (C1_ZREGUL) da SC vinculada para a
coluna C7_ZREGUL do grid, quando esta estiver vazia. Assim o valor digitado
na solicitacao aparece na tela do pedido no momento do vinculo. Se o usuario
editar o valor direto no pedido, a copia nao sobrescreve (guard Empty()).

Uso: funcao sem parametros; acessa as variaveis de memoria aHeader, aCols e
n (linha corrente) da MATA120 e o alias SC1 posicionado no item vinculado.

@type     User Function
@author   Desenvolvimento
@since    15/10/2026
@version  1.0
@return   Logico, .T. = prossegue o fluxo padrao da rotina
/*/
User Function MT120ISC()
    Local aArea   := GetArea()
    Local nPosReg := aScan(aHeader, {|x| AllTrim(x[2]) == "C7_ZREGUL"})

    If nPosReg > 0 .And. SC1->(FieldPos("C1_ZREGUL")) > 0
        If Empty(aCols[n][nPosReg]) .And. !Empty(SC1->C1_ZREGUL)

            aCols[n][nPosReg] := SC1->C1_ZREGUL

            FWLogMsg("INFO", , "SUPR", "MT120ISC", , "01", ;
                     "C7_ZREGUL=[" + AllTrim(aCols[n][nPosReg]) + ;
                     "] preenchido no grid a partir da SC " + ;
                     SC1->C1_NUM + "/" + SC1->C1_ITEM, 0, 0, {})

        EndIf
    EndIf

    RestArea(aArea)
Return .T.
