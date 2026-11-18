// --- Ponto de Entrada: MTA270MNU - Adiciona opcao no menu da Digitacao do Inventario (MATA270) ---

#include "totvs.ch"

/*/{Protheus.doc} MTA270MNU
Ponto de Entrada executado no MenuDef da rotina MATA270 (Digitacao do
Inventario). A opcao "Importar Inventario (CSV)" e acrescentada ao array
aRotina e o proprio array e devolvido, conforme o contrato documentado no
TDN (PEST07493): o retorno obrigatorio e aRotina.

A opcao abre a rotina ZIMPINV, que le o arquivo CSV e grava a contagem na
tabela SB7 pela rotina automatica da MATA270. A efetivacao continua sendo
feita na MATA340.

@author  Vortice Consultoria Mineral
@since   2026/11/09
@version 1.0
@type    function
/*/
User Function MTA270MNU()

    Local aMenu := {}

    // aRotina e fornecido pela rotina no momento da montagem do menu.
    // Guardar com Type() para nao quebrar caso o contexto de chamada mude.
    If Type("aRotina") == "A"
        AAdd(aRotina, { "Importar Inventario (CSV)", "U_ZIMPINV()", 0, 2, 0, Nil })
        aMenu := aRotina
    Else
        FWLogMsg("ERROR", , "SUPR", FunName(), , "01", ;
                 "[MTA270MNU] Variavel aRotina indisponivel - opcao nao incluida no menu")
    EndIf

Return aMenu
