#Include "Protheus.ch"

/*/{Protheus.doc} NFEMNUCC
Ponto de entrada do SPEDNFE para adicionar opcao
"Preview DANFE" no menu de acoes da NF-e.

Adiciona o item "Preview DANFE" que chama U_MT460PREV()
para gerar pre-visualizacao do DANFE antes da transmissao.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   23/06/2026
@return  aRotina, Array, Itens de menu customizados
/*/
User Function NFEMNUCC()
    Local aRotina := {}

    aAdd(aRotina, {"Preview DANFE", "U_MT460PREV()", 0, 3, 0, .T.})

Return aRotina
