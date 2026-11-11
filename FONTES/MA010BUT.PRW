// --- Ponto de Entrada: MA010BUT - Inclui botao de atualizacao em massa na MATA010 ---

#include "totvs.ch"

/*/{Protheus.doc} MA010BUT
Ponto de Entrada que inclui botoes na barra de ferramentas da view da
MATA010 (cadastro de produtos):
  - "Atualizar Descricoes"           -> rotina ZATUDESC
  - "Bloqueio/Desbloqueio em Massa"  -> rotina ZBLQMAS
Roda nas funcoes A010Inclui / A010Altera / A010Deleta / A010Visul.

Formato exigido pelo ViewDef da MATA010 (P12) - cada item da lista e:
    { icone (cPicture), bloco de acao (bAction), titulo (cTitle) }

O ViewDef repassa o item para FWFORMVIEW:AddUserButton(cTitle, cPicture,
bAction), por isso o titulo (texto) deve ficar na 3a posicao e a acao
(codeblock) na 2a. Formato legado de aRotina {label, exec, 0, 2, 0, Nil}
quebra a visualizacao com "argumento #0, parametro cTitle erro, previsto C->N".

@author  Vortice Consultoria Mineral
@since   2026/10/09
@version 1.1
@return array, lista de botoes de usuario no formato { icone, blocoDeAcao, titulo }
@type    function
/*/
User Function MA010BUT()
    Local aRet := {}

    AAdd(aRet, { "NOTE", {|| U_ZATUDESC()}, "Atualizar Descricoes" })
    AAdd(aRet, { "NOTE", {|| U_ZBLQMAS()}, "Bloqueio/Desbloqueio em Massa" })

Return aRet
