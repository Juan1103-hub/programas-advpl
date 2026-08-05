#include "protheus.ch"

/*/{Protheus.doc} MA410MNU
Ponto de entrada do MATA410 que adiciona a opcao
"Preview NF-e TSS" no menu "Outras Acoes" do Pedido de Venda.
Chama U_NFEPREVTSS() (NFEPREVTSS.tlpp) que gera o preview
fiscal com Embedded SQL estruturado por grupos XML.

aRotina ja existe como Private injetada pelo Protheus com todos
os itens padrao do MATA410. Apenas AAdd() sobre a matriz herdada
para preservar o menu nativo.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   23/06/2026
@return  aRotina, Array, Itens de menu com a opcao adicional
/*/
User Function MA410MNU()
    AAdd(aRotina, {"Preview NF-e TSS", "U_NFEPREVTS()", 0, 6, 0, NIL})
Return aRotina
