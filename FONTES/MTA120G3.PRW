#Include "totvs.ch"

/*/{Protheus.doc} MTA120G3
Ponto de Entrada executado no loop de gravacao dos itens do Pedido de
Compras (MATA120 / SC7), com o item do pedido ja posicionado no alias.

Objetivos:
1. Forcar C7_IPIBRUT = "L" (IPI liquido) em cada item durante a propria
   gravacao, vencendo a sobrescrita do calculo fiscal (MaFisRef), que roda
   durante o processamento dos itens e reescreve o C7_IPIBRUT conforme o
   F4_TPIPI da TES / parametro global (valor "B" bruto).

2. Recalcular a base e o valor do IPI considerando o desconto
   (C7_VLDESC), conforme o flag C7_IPIBRUT = "L". O MaFisRef calcula o IPI
   sobre a base bruta (C7_TOTAL) porque a TES nao considera o desconto
   (F4_TPIPI = Bruto) e o setor fiscal nao autoriza alteracao da TES.
   Com o flag "L", a base do IPI passa a ser C7_TOTAL - C7_VLDESC, em
   conformidade com o campo C7_IPIBRUT ("Determina se o Valor do IPI sera
   calculado pelo valor total menos o desconto").

   Base de calculo:  C7_BASEIPI = C7_TOTAL - C7_VLDESC
   Valor do IPI:     C7_VALIPI  = C7_BASEIPI * C7_IPI / 100

3. Registrar log via FWLogMsg para diagnostico em producao.

Diferente de PEs pos-gravacao (MT120F, WFW120P), este PE roda DENTRO do
fluxo de gravacao, com o alias SC7 posicionado no item que esta sendo
gravado ? a alteracao direta do campo e persistida pelo proprio MATA120,
sem risco de "dado fantasma" (UPDATE externo em item nao commitado).

Padrao oficial: exemplo MTA120G2 (TDN pageId 6085572) usa
SC7->C7_OBS := <valor> sem RecLock, dentro do loop de gravacao.

Campos SC7 envolvidos (dicionario SX3):
  C7_IPIBRUT: "Cons. Desc. Considera Desconto p/IPI"
  C7_BASEIPI: "Valor Base de Calc. IPI"
  C7_VALIPI:  "Valor do IPI do Item"
  C7_VLDESC:  "Valor do Desconto do item"
  C7_TOTAL:   "Valor total do item" (preco x quantidade, base bruta)

@type     User Function
@author   Desenvolvimento
@since    13/08/2026
@version  2.0
@return   Nil, Sem retorno (PE de gravacao de item)
/*/
User Function MTA120G3()
    Local aArea    := GetArea()
    Local nDesc    := 0
    Local nBaseIPI := 0
    Local nValIPI  := 0

    SC7->C7_IPIBRUT := "L"

    If SC7->C7_IPI > 0
        nDesc := SC7->C7_VLDESC
        If ValType(nDesc) != "N" .Or. nDesc < 0
            nDesc := 0
        EndIf

        nBaseIPI := SC7->C7_TOTAL - nDesc
        If nBaseIPI < 0
            nBaseIPI := 0
        EndIf

        nValIPI := Round(nBaseIPI * SC7->C7_IPI / 100, 2)

        SC7->C7_BASEIPI := nBaseIPI
        SC7->C7_VALIPI  := nValIPI

        FWLogMsg("MTA120G3 - Pedido [" + SC7->C7_NUM + "] Item [" + SC7->C7_ITEM + "] C7_IPIBRUT='L' BaseIPI=" + cValToChar(nBaseIPI) + " ValIPI=" + cValToChar(nValIPI))
    Else
        FWLogMsg("MTA120G3 - Pedido [" + SC7->C7_NUM + "] Item [" + SC7->C7_ITEM + "] C7_IPIBRUT='L' sem aliquota IPI")
    EndIf

    RestArea(aArea)
Return
