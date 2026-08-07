#include "totvs.ch"

/*/{Protheus.doc} MT120IPI
Ponto de Entrada chamado via gatilho SX7 em C7_PRODUTO, no grid do
Pedido de Compra (MATA120 / SC7). Forca o campo C7_IPIBRUT sempre
igual a "L" (liquido), substituindo o valor default "B" (bruto).

Fluxo:
1. Usuario informa o C7_PRODUTO na linha do grid.
2. O gatilho SX7 em C7_PRODUTO dispara, chamando U_MT120IPI().
3. A funcao retorna "L" para o framework gravar em C7_IPIBRUT.

Parametro SX7 (SIGACFG > Atualizacoes > Base de Dados > Gatilhos):
  X7_CAMPO   = C7_PRODUTO
  X7_SEQUENC = 002                       (001 = MT120TFR)
  X7_CDOMIN  = C7_IPIBRUT
  X7_REGRA   = U_MT120IPI()
  X7_TIPO    = P (Primario)
  X7_CONDIC  = C7_IPIBRUT <> 'L'    (.T. no incluir/alterar, ex. sair do campo C7_PRODUTO)
  X7_PROPRI  = U

OBSERVACAO: este gatilho sempre retorna "L", mesmo que o usuario
informe "B" manualmente, pois o valor do Cnt. Dominio e reevaluado
a cada saida do campo C7_PRODUTO.

CAMPOS DO PEDIDO DE COMPRA:
- C7_IPIBRUT: "B" = Bruto (default) | "L" = Liquido (desconto
  integra a base de calculo do IPI).

@type     User Function
@author   Desenvolvimento
@since    07/08/2026
@version  1.0
@return   cIPIBrut, Character, "L" - liquido para o framework
/*/
User Function MT120IPI()

    Local cIPRBru := "L"

    // -------------------------------------------------------------------------
    // Validacao de contexto de grid
    // -------------------------------------------------------------------------
    If Type("aCols") == "U" .Or. Type("aHeader") == "U"
        FWLogMsg("MT120IPI - fora de contexto de grid")
        Return ""
    EndIf

    FWLogMsg("MT120IPI - retornando C7_IPIBRUT = [L]")

Return cIPRBru