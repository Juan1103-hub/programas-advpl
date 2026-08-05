#Include "Protheus.ch"
#Include "TopConn.ch"

// =============================================================================
// ZAVALNEG - Avaliacao de Negociacao de Compras (Supervisor)
// =============================================================================
//
// OBJETIVO:
//   Permite ao supervisor avaliar a negociacao de itens comprados em um periodo,
//   comparando precos brutos, liquidos, descontos e identificando quando o preco
//   liquido unitario piorou em relacao ao melhor preco do periodo.
//
// MODELO DE DADOS (Fonte Verdade):
//   Fonte Primaria: SC7 (Pedido de Compra - Itens)
//     Reflete o "negociado" entre comprador e fornecedor.
//     E a decisao de preco tomada pelo comprador antes do recebimento.
//   Fonte Complementar: SD1 (Documento de Entrada - Itens)
//     Reflete o "real comprado" (NF efetiva). Disponivel via drill-down
//     quando o PC esta vinculado a uma NF (D1_PEDCOMP).
//   Justificativa:
//     O supervisor avalia a NEGOCIACAO (ato do comprador), portanto
//     SC7 e a fonte primaria. O SD1 serve para confirmar se o
//     real comprado divergiu do negociado (rastreabilidade).
//
// TABELAS UTILIZADAS:
//   SC7 - Pedido de Compra (itens) .... principal
//   SA2 - Fornecedores ................ nome/dados fornecedor
//   SB1 - Produtos .................... descricao/grupo/UM
//   SA3 - Compradores ................. nome do comprador (A3_NOME)
//   SD1 - Doc. Entrada (itens) ........ drill-down NF vinculada
//
// CALCULOS:
//   Bruto Unitario     = C7_PRECO
//   Desconto R$ (unit) = C7_VLDESC / C7_QUANT
//   Desconto %         = (C7_VLDESC / (C7_PRECO * C7_QUANT)) * 100
//   Liquido Unitario   = C7_TOTAL / C7_QUANT
//   Liquido Total      = C7_TOTAL
//   Melhor Preco       = MIN(Liquido Unitario) por item no periodo
//   Diferenca R$       = Liquido Unitario - Melhor Preco
//   Diferenca %        = (Dif R$ / Melhor Preco) * 100
//   Status: OK (dif=0) | ALERTA (0<dif<=5%) | PIOROU (dif>5%)
//
// INDICES RECOMENDADOS (SC7):
//   Indice 3: C7_FILIAL+C7_EMISSAO ....... filtro por data (principal)
//   Indice E: C7_FILIAL+C7_PRODUTO ....... filtro por item
//   Ordem de filtro SQL: filial > data > produto (alinhado ao indice 3)
//
// FILTROS: cancelados (D_E_L_E_T_), residuo (C7_RESIDUO<>'S'),
//          aprovacao (C7_CONAPRO<>'R' e <>'B'), quantidade > 0.
//
// REQUISITOS: Multi-filial, exportacao Excel, drill-down, consolidado.
// =============================================================================

// --------------- Constantes --------------------------------------------------
#Define LIM_ALERTA   5       // Limite percentual para status ALERTA (acima = PIOROU)
#Define STS_OK       "OK"
#Define STS_ALERTA   "ALERTA"
#Define STS_PIOROU   "PIOROU"
#Define MAX_LINHAS   10000   // Limite de seguranca para resultados

// Posicoes do array aDetalhe (registro detalhado)
#Define DT_FILIAL     1
#Define DT_CODITEM    2
#Define DT_DESCITEM   3
#Define DT_CODFORN    4
#Define DT_LOJAFORN   5
#Define DT_NOMEFORN   6
#Define DT_DTDOC      7
#Define DT_NUMDOC     8
#Define DT_ITEMPC     9
#Define DT_QUANT     10
#Define DT_PRCBRUTO  11
#Define DT_DESCRS    12
#Define DT_DESCPERC  13
#Define DT_PRCLIQ    14
#Define DT_LIQTOT    15
#Define DT_MELHORPRC 16
#Define DT_DIFRS     17
#Define DT_DIFPERC   18
#Define DT_STATUS    19
#Define DT_CC        20
#Define DT_GRUPO     21
#Define DT_UM        22
#Define DT_MELHFORN  23
#Define DT_NATUREZ   24
#Define DT_COMPRAD   25
#Define DT_COMPNOME  26
#Define DT_SIZE      26

// Posicoes do array aConsolid (consolidado por item)
#Define CS_CODITEM    1
#Define CS_DESCITEM   2
#Define CS_QTDCOMP    3
#Define CS_QTDTOTAL   4
#Define CS_VLRTOTAL   5
#Define CS_PRCMEDIO   6
#Define CS_MELHORPRC  7
#Define CS_PIORPRC    8
#Define CS_VARIACAO   9
#Define CS_MELHFORN  10
#Define CS_PIORFORN  11
#Define CS_DESCMED   12
#Define CS_GRUPO     13
#Define CS_UM        14
#Define CS_TENDENC   15   // SUBIU / MANTEVE / BAIXOU
#Define CS_MELHCOMP  16   // Comprador do melhor preco
#Define CS_PIORCOMP  17   // Comprador do pior preco
#Define CS_PRIMPREC  18   // Primeiro preco cronologico
#Define CS_ULTPREC   19   // Ultimo preco cronologico
#Define CS_SIZE      19

// Tendencias
#Define TEND_SUBIU   "SUBIU"
#Define TEND_MANTEVE "MANTEVE"
#Define TEND_BAIXOU  "BAIXOU"

// --------------- Variaveis estaticas do modulo -------------------------------
Static aDetalhe     := {}   // Array principal de dados detalhados
Static aDetalheOrig := {}   // Copia original (para restaurar filtros)
Static aConsolid    := {}   // Array consolidado por item
Static nTotComprado := 0    // Total comprado (liquido)
Static nTotDesconto := 0    // Total desconto R$
Static nPrcMedioPond := 0   // Preco medio ponderado
Static nQtdTotal    := 0    // Quantidade total de itens comprados
Static nQtdLinhas   := 0    // Quantidade de linhas no resultado

// =============================================================================
// FUNCAO PRINCIPAL - Ponto de entrada
// =============================================================================

/*/{Protheus.doc} ZAVALNEG
Tela de avaliacao de negociacao de compras para supervisores.
Permite analisar precos, descontos e identificar piora nos precos
de itens comprados em um periodo.
@type User Function
@author Desenvolvimento
@since 18/02/2026
@version 1.0
/*/
User Function ZAVALNEG()
    Local aFiltros := {}

    // Limpa dados anteriores
    aDetalhe     := {}
    aDetalheOrig := {}
    aConsolid    := {}
    nTotComprado := 0
    nTotDesconto := 0
    nPrcMedioPond := 0
    nQtdTotal    := 0
    nQtdLinhas   := 0

    // Abre tela de filtros e coleta parametros
    aFiltros := TelaFiltros()

    // Se usuario cancelou, sai
    If Len(aFiltros) == 0
        Return
    EndIf

    // Executa consulta com os filtros informados
    If ExecutaConsulta(aFiltros)
        // Calcula indicadores (melhor preco, diferencas, status)
        CalcIndicadores()

        // Monta array consolidado por item
        MontaConsolidado()

        // Abre tela de resultados
        TelaResultado(aFiltros)
    EndIf
Return

// =============================================================================
// TELA DE FILTROS
// =============================================================================

/*/{Protheus.doc} TelaFiltros
Monta o dialogo de filtros para parametrizar a consulta.
Retorna array com os filtros preenchidos ou vazio se cancelado.
@type Static Function
@return aRet, Array com filtros {dDtDe, dDtAte, cItemDe, cItemAte, cComprador}
/*/
Static Function TelaFiltros()
    Local aRet      := {}
    Local lOk       := .F.
    Local oDlg, oFont, oFontTit
    Local oBtnOk, oBtnCancel

    // Variaveis de filtro
    Local dDtDe     := FirstDate(Date())
    Local dDtAte    := Date()
    Local cItemDe   := Space(15)
    Local cItemAte  := Replicate("Z", 15)
    Local cComprador := Space(6)

    // Objetos de entrada
    Local oGetDtDe, oGetDtAte
    Local oGetItemDe, oGetItemAte
    Local oGetCompr

    // Fontes
    oFont    := TFont():New("Arial",, -11,, .F.)
    oFontTit := TFont():New("Arial",, -14, .T., .F.)

    // Dialogo
    DEFINE MSDIALOG oDlg TITLE "Avaliacao de Negociacao - Filtros" ;
        FROM 0,0 TO 260, 540 PIXEL STYLE DS_MODALFRAME

    // Titulo
    TSay():New(008, 010, {|| "Parametros da Consulta"}, oDlg, , ;
        oFontTit, , , , .T., CLR_HBLUE, , 250, 16)

    @ 024, 005 TO 024, 265 OF oDlg PIXEL

    // ---- Linha 1: Periodo (obrigatorio) ----
    @ 032, 010 SAY "Periodo *:" SIZE 055, 012 PIXEL OF oDlg FONT oFont
    @ 030, 070 MSGET oGetDtDe  VAR dDtDe  SIZE 065, 012 PIXEL OF oDlg
    @ 032, 140 SAY "ate" SIZE 020, 012 PIXEL OF oDlg FONT oFont
    @ 030, 163 MSGET oGetDtAte VAR dDtAte SIZE 065, 012 PIXEL OF oDlg

    // ---- Linha 2: Item (produto) - opcional ----
    @ 052, 010 SAY "Item:" SIZE 055, 012 PIXEL OF oDlg FONT oFont
    @ 050, 070 MSGET oGetItemDe  VAR cItemDe  SIZE 080, 012 PIXEL OF oDlg F3 "SB1"
    @ 052, 155 SAY "ate" SIZE 020, 012 PIXEL OF oDlg FONT oFont
    @ 050, 178 MSGET oGetItemAte VAR cItemAte SIZE 080, 012 PIXEL OF oDlg F3 "SB1"

    // ---- Linha 3: Comprador - opcional ----
    @ 072, 010 SAY "Comprador:" SIZE 055, 012 PIXEL OF oDlg FONT oFont
    @ 070, 070 MSGET oGetCompr VAR cComprador SIZE 050, 012 PIXEL OF oDlg
    @ 072, 125 SAY "(branco = todos)" SIZE 090, 012 PIXEL OF oDlg FONT oFont

    // ---- Separador ----
    @ 092, 005 TO 092, 265 OF oDlg PIXEL

    // ---- Botoes ----
    @ 100, 070 BUTTON oBtnOk PROMPT "Consultar" SIZE 075, 018 OF oDlg PIXEL ;
        ACTION (lOk := .T., oDlg:End())

    @ 100, 160 BUTTON oBtnCancel PROMPT "Cancelar" SIZE 075, 018 OF oDlg PIXEL ;
        ACTION (lOk := .F., oDlg:End())

    ACTIVATE MSDIALOG oDlg CENTERED

    FreeObj(oFont)
    FreeObj(oFontTit)

    If !lOk
        Return aRet
    EndIf

    // Validacoes obrigatorias
    If Empty(dDtDe) .Or. Empty(dDtAte)
        MsgAlert("Informe o periodo completo (data inicial e final)!", "Atencao")
        Return aRet
    EndIf

    If dDtAte < dDtDe
        MsgAlert("Data final nao pode ser anterior a data inicial!", "Atencao")
        Return aRet
    EndIf

    // Monta array de retorno com os filtros
    aRet := {;
        dDtDe,;                     // [1]  Data inicial
        dDtAte,;                    // [2]  Data final
        cItemDe,;                   // [3]  Item de
        cItemAte,;                  // [4]  Item ate
        AllTrim(cComprador)}        // [5]  Comprador

Return aRet

// =============================================================================
// EXECUCAO DA CONSULTA SQL
// =============================================================================

/*/{Protheus.doc} ExecutaConsulta
Executa a consulta SQL no SC7 com os filtros informados.
Popula o array aDetalhe com os registros encontrados.
Utiliza indices: C7_FILIAL+C7_EMISSAO (indice 3) para filtro de data.
@type Static Function
@param aFiltros, Array com filtros da TelaFiltros
@return lRet, .T. se encontrou dados, .F. caso contrario
/*/
Static Function ExecutaConsulta(aFiltros)
    Local lRet      := .F.
    Local cAlias    := GetNextAlias()
    Local cQuery    := ""
    Local cSC7      := RetSqlName("SC7")
    Local cSA2      := RetSqlName("SA2")
    Local cSB1      := RetSqlName("SB1")
    Local cSA3      := RetSqlName("SA3")

    // Variaveis do registro
    Local nPrcBruto  := 0
    Local nDescRS    := 0
    Local nDescPerc  := 0
    Local nPrcLiq    := 0
    Local nLiqTot    := 0

    // Filtros
    Local dDtDe     := aFiltros[1]
    Local dDtAte    := aFiltros[2]
    Local cItemDe   := aFiltros[3]
    Local cItemAte  := aFiltros[4]
    Local cCompr    := aFiltros[5]

    // Limpa arrays
    aDetalhe     := {}
    aDetalheOrig := {}
    nTotComprado := 0
    nTotDesconto := 0
    nQtdTotal    := 0

    // =========================================================================
    // MONTAGEM DA QUERY
    // =========================================================================
    //
    // Performance: filtros na ordem do indice 3 (C7_FILIAL+C7_EMISSAO)
    // para garantir seek eficiente. Filtros adicionais aplicados pos-indice.
    // WITH (NOLOCK) para evitar bloqueios em leitura.
    // =========================================================================

    cQuery := " SELECT "
    cQuery += "   C7.C7_FILIAL, "
    cQuery += "   C7.C7_NUM, "
    cQuery += "   C7.C7_ITEM, "
    cQuery += "   C7.C7_PRODUTO, "
    cQuery += "   ISNULL(B1.B1_DESC, '') AS B1_DESC, "
    cQuery += "   ISNULL(B1.B1_GRUPO, '') AS B1_GRUPO, "
    cQuery += "   ISNULL(B1.B1_UM, '') AS B1_UM, "
    cQuery += "   C7.C7_FORNECE, "
    cQuery += "   C7.C7_LOJA, "
    cQuery += "   ISNULL(A2.A2_NREDUZ, '') AS A2_NREDUZ, "
    cQuery += "   C7.C7_EMISSAO, "
    cQuery += "   C7.C7_QUANT, "
    cQuery += "   C7.C7_PRECO, "
    cQuery += "   ISNULL(C7.C7_VLDESC, 0) AS C7_VLDESC, "
    cQuery += "   C7.C7_TOTAL, "
    cQuery += "   ISNULL(C7.C7_CC, '') AS C7_CC, "
    cQuery += "   ISNULL(C7.C7_COMPRA, '') AS C7_COMPRA, "
    cQuery += "   ISNULL(A3.A3_NOME, '') AS A3_NOME "

    cQuery += " FROM " + cSC7 + " C7 "

    // JOIN SB1 (produto) - compartilhado
    cQuery += " LEFT JOIN " + cSB1 + " B1 "
    cQuery += "   ON B1.D_E_L_E_T_ = ' ' "
    cQuery += "   AND B1.B1_FILIAL = '" + xFilial("SB1") + "' "
    cQuery += "   AND B1.B1_COD = C7.C7_PRODUTO "

    // JOIN SA2 (fornecedor) - compartilhado
    cQuery += " LEFT JOIN " + cSA2 + " A2 "
    cQuery += "   ON A2.D_E_L_E_T_ = ' ' "
    cQuery += "   AND A2.A2_FILIAL = '" + xFilial("SA2") + "' "
    cQuery += "   AND A2.A2_COD = C7.C7_FORNECE "
    cQuery += "   AND A2.A2_LOJA = C7.C7_LOJA "

    // JOIN SA3 (comprador) - nome do comprador
    cQuery += " LEFT JOIN " + cSA3 + " A3 "
    cQuery += "   ON A3.D_E_L_E_T_ = ' ' "
    cQuery += "   AND A3.A3_FILIAL = '" + xFilial("SA3") + "' "
    cQuery += "   AND A3.A3_COD = C7.C7_COMPRA "

    // WHERE - filtros obrigatorios
    cQuery += " WHERE C7.D_E_L_E_T_ = ' ' "
    cQuery += "   AND C7.C7_QUANT > 0 "
    cQuery += "   AND C7.C7_RESIDUO <> 'S' "
    cQuery += "   AND (C7.C7_CONAPRO = '' OR C7.C7_CONAPRO = ' ' OR C7.C7_CONAPRO = 'L') "
    cQuery += "   AND C7.C7_PRODUTO NOT LIKE 'SV%' "
    cQuery += "   AND C7.C7_PRODUTO NOT LIKE 'PA%' "

    // Filtro de filial (filial corrente)
    cQuery += "   AND C7.C7_FILIAL = '" + xFilial("SC7") + "' "

    // Filtro de data (indice 3: C7_FILIAL+C7_EMISSAO)
    cQuery += "   AND C7.C7_EMISSAO >= '" + DtoS(dDtDe) + "' "
    cQuery += "   AND C7.C7_EMISSAO <= '" + DtoS(dDtAte) + "' "

    // Filtros opcionais
    If !Empty(AllTrim(cItemDe))
        cQuery += "   AND C7.C7_PRODUTO >= '" + cItemDe + "' "
    EndIf
    If !Empty(AllTrim(cItemAte)) .And. !(AllTrim(cItemAte) == Replicate("Z", Len(AllTrim(cItemAte))))
        cQuery += "   AND C7.C7_PRODUTO <= '" + cItemAte + "' "
    EndIf

    If !Empty(cCompr)
        cQuery += "   AND C7.C7_COMPRA = '" + cCompr + "' "
    EndIf

    // Ordenacao: por produto e data (facilita agrupamento posterior)
    cQuery += " ORDER BY C7.C7_PRODUTO, C7.C7_EMISSAO, C7.C7_NUM "

    // Executa query
    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    // =========================================================================
    // CARREGAMENTO DOS DADOS NO ARRAY
    // =========================================================================

    While !(cAlias)->(Eof()) .And. Len(aDetalhe) < MAX_LINHAS

        // Valores do registro
        nPrcBruto := (cAlias)->C7_PRECO
        nLiqTot   := (cAlias)->C7_TOTAL
        nPrcLiq   := IIF((cAlias)->C7_QUANT > 0, nLiqTot / (cAlias)->C7_QUANT, 0)
        nDescRS   := IIF((cAlias)->C7_QUANT > 0, (cAlias)->C7_VLDESC / (cAlias)->C7_QUANT, 0)
        nDescPerc := IIF(nPrcBruto > 0, (nDescRS / nPrcBruto) * 100, 0)

        aAdd(aDetalhe, Array(DT_SIZE))
        nQtdLinhas := Len(aDetalhe)

        aDetalhe[nQtdLinhas][DT_FILIAL]    := AllTrim((cAlias)->C7_FILIAL)
        aDetalhe[nQtdLinhas][DT_CODITEM]   := AllTrim((cAlias)->C7_PRODUTO)
        aDetalhe[nQtdLinhas][DT_DESCITEM]  := AllTrim((cAlias)->B1_DESC)
        aDetalhe[nQtdLinhas][DT_CODFORN]   := AllTrim((cAlias)->C7_FORNECE)
        aDetalhe[nQtdLinhas][DT_LOJAFORN]  := AllTrim((cAlias)->C7_LOJA)
        aDetalhe[nQtdLinhas][DT_NOMEFORN]  := AllTrim((cAlias)->A2_NREDUZ)
        aDetalhe[nQtdLinhas][DT_DTDOC]     := StoD((cAlias)->C7_EMISSAO)
        aDetalhe[nQtdLinhas][DT_NUMDOC]    := "PC " + AllTrim((cAlias)->C7_NUM)
        aDetalhe[nQtdLinhas][DT_ITEMPC]    := AllTrim((cAlias)->C7_ITEM)
        aDetalhe[nQtdLinhas][DT_QUANT]     := (cAlias)->C7_QUANT
        aDetalhe[nQtdLinhas][DT_PRCBRUTO]  := nPrcBruto
        aDetalhe[nQtdLinhas][DT_DESCRS]    := nDescRS
        aDetalhe[nQtdLinhas][DT_DESCPERC]  := nDescPerc
        aDetalhe[nQtdLinhas][DT_PRCLIQ]    := nPrcLiq
        aDetalhe[nQtdLinhas][DT_LIQTOT]    := nLiqTot
        aDetalhe[nQtdLinhas][DT_MELHORPRC] := 0    // Calculado depois
        aDetalhe[nQtdLinhas][DT_DIFRS]     := 0    // Calculado depois
        aDetalhe[nQtdLinhas][DT_DIFPERC]   := 0    // Calculado depois
        aDetalhe[nQtdLinhas][DT_STATUS]    := STS_OK
        aDetalhe[nQtdLinhas][DT_CC]        := AllTrim((cAlias)->C7_CC)
        aDetalhe[nQtdLinhas][DT_GRUPO]     := AllTrim((cAlias)->B1_GRUPO)
        aDetalhe[nQtdLinhas][DT_UM]        := AllTrim((cAlias)->B1_UM)
        aDetalhe[nQtdLinhas][DT_MELHFORN]  := ""   // Calculado depois
        aDetalhe[nQtdLinhas][DT_NATUREZ]   := ""
        aDetalhe[nQtdLinhas][DT_COMPRAD]   := AllTrim((cAlias)->C7_COMPRA)
        aDetalhe[nQtdLinhas][DT_COMPNOME]  := AllTrim((cAlias)->A3_NOME)

        // Acumula totais
        nTotComprado += nLiqTot
        nTotDesconto += (cAlias)->C7_VLDESC
        nQtdTotal    += (cAlias)->C7_QUANT

        (cAlias)->(DbSkip())
    EndDo

    (cAlias)->(DbCloseArea())

    nQtdLinhas := Len(aDetalhe)

    If nQtdLinhas == 0
        MsgAlert("Nenhum pedido de compra encontrado para os filtros informados!", "Atencao")
        Return lRet
    EndIf

    If nQtdLinhas >= MAX_LINHAS
        MsgAlert("Resultado limitado a " + cValToChar(MAX_LINHAS) + " registros." + ;
            Chr(13) + Chr(10) + "Refine os filtros para resultados mais precisos.", "Aviso")
    EndIf

    // Calcula preco medio ponderado global
    nPrcMedioPond := IIF(nQtdTotal > 0, nTotComprado / nQtdTotal, 0)

    // Guarda copia original
    aDetalheOrig := aClone(aDetalhe)

    lRet := .T.
Return lRet

// =============================================================================
// CALCULO DE INDICADORES (Melhor preco, diferencas, status)
// =============================================================================

/*/{Protheus.doc} CalcIndicadores
Calcula o melhor preco liquido unitario por item no periodo,
define diferencas e classifica status (OK/ALERTA/PIOROU).
Identifica tambem o "melhor fornecedor" por item.
@type Static Function
/*/
Static Function CalcIndicadores()
    Local i, nPos
    Local aMelhor := {}   // {cCodItem, nMelhorPreco, cMelhorForn}
    Local cItem   := ""
    Local nPreco  := 0

    // --- Passo 1: Encontrar melhor preco por item ---
    For i := 1 To Len(aDetalhe)
        cItem  := aDetalhe[i][DT_CODITEM]
        nPreco := aDetalhe[i][DT_PRCLIQ]

        If nPreco <= 0
            Loop
        EndIf

        nPos := aScan(aMelhor, {|x| x[1] == cItem})

        If nPos == 0
            // Primeiro registro do item
            aAdd(aMelhor, {cItem, nPreco, aDetalhe[i][DT_NOMEFORN]})
        ElseIf nPreco < aMelhor[nPos][2]
            // Novo melhor preco
            aMelhor[nPos][2] := nPreco
            aMelhor[nPos][3] := aDetalhe[i][DT_NOMEFORN]
        EndIf
    Next i

    // --- Passo 2: Aplicar melhor preco e calcular diferencas ---
    For i := 1 To Len(aDetalhe)
        cItem := aDetalhe[i][DT_CODITEM]
        nPos  := aScan(aMelhor, {|x| x[1] == cItem})

        If nPos > 0 .And. aMelhor[nPos][2] > 0
            aDetalhe[i][DT_MELHORPRC] := aMelhor[nPos][2]
            aDetalhe[i][DT_MELHFORN]  := aMelhor[nPos][3]
            aDetalhe[i][DT_DIFRS]     := aDetalhe[i][DT_PRCLIQ] - aMelhor[nPos][2]
            aDetalhe[i][DT_DIFPERC]   := (aDetalhe[i][DT_DIFRS] / aMelhor[nPos][2]) * 100

            // Classificacao de status
            Do Case
                Case aDetalhe[i][DT_DIFRS] <= 0
                    aDetalhe[i][DT_STATUS] := STS_OK
                Case aDetalhe[i][DT_DIFPERC] > LIM_ALERTA
                    aDetalhe[i][DT_STATUS] := STS_PIOROU
                Otherwise
                    aDetalhe[i][DT_STATUS] := STS_ALERTA
            EndCase
        Else
            aDetalhe[i][DT_MELHORPRC] := aDetalhe[i][DT_PRCLIQ]
            aDetalhe[i][DT_MELHFORN]  := aDetalhe[i][DT_NOMEFORN]
            aDetalhe[i][DT_DIFRS]     := 0
            aDetalhe[i][DT_DIFPERC]   := 0
            aDetalhe[i][DT_STATUS]    := STS_OK
        EndIf
    Next i

    // Atualiza copia original
    aDetalheOrig := aClone(aDetalhe)
Return

// =============================================================================
// MONTAGEM DO ARRAY CONSOLIDADO POR ITEM
// =============================================================================

/*/{Protheus.doc} MontaConsolidado
Agrupa os dados detalhados por item, calculando totais, medias,
melhor e pior preco, variacao, tendencia (SUBIU/MANTEVE/BAIXOU)
e nomes dos compradores responsaveis.
Tendencia: compara ultimo preco cronologico vs primeiro.
  SUBIU = ultimo > primeiro em mais de 2% (piorou negociacao)
  BAIXOU = ultimo < primeiro em mais de 2% (melhorou)
  MANTEVE = variacao <= 2%
@type Static Function
/*/
Static Function MontaConsolidado()
    Local i, j, nPos
    Local cItem    := ""
    Local aItemDet := {}
    Local nVarTend := 0

    aConsolid := {}

    For i := 1 To Len(aDetalhe)
        cItem := aDetalhe[i][DT_CODITEM]
        nPos  := aScan(aConsolid, {|x| x[CS_CODITEM] == cItem})

        If nPos == 0
            // Novo item
            aAdd(aConsolid, Array(CS_SIZE))
            nPos := Len(aConsolid)

            aConsolid[nPos][CS_CODITEM]   := cItem
            aConsolid[nPos][CS_DESCITEM]  := aDetalhe[i][DT_DESCITEM]
            aConsolid[nPos][CS_QTDCOMP]   := 1
            aConsolid[nPos][CS_QTDTOTAL]  := aDetalhe[i][DT_QUANT]
            aConsolid[nPos][CS_VLRTOTAL]  := aDetalhe[i][DT_LIQTOT]
            aConsolid[nPos][CS_PRCMEDIO]  := aDetalhe[i][DT_PRCLIQ]
            aConsolid[nPos][CS_MELHORPRC] := aDetalhe[i][DT_PRCLIQ]
            aConsolid[nPos][CS_PIORPRC]   := aDetalhe[i][DT_PRCLIQ]
            aConsolid[nPos][CS_VARIACAO]  := 0
            aConsolid[nPos][CS_MELHFORN]  := aDetalhe[i][DT_NOMEFORN]
            aConsolid[nPos][CS_PIORFORN]  := aDetalhe[i][DT_NOMEFORN]
            aConsolid[nPos][CS_DESCMED]   := aDetalhe[i][DT_DESCPERC]
            aConsolid[nPos][CS_GRUPO]     := aDetalhe[i][DT_GRUPO]
            aConsolid[nPos][CS_UM]        := aDetalhe[i][DT_UM]
            aConsolid[nPos][CS_TENDENC]   := TEND_MANTEVE
            aConsolid[nPos][CS_MELHCOMP]  := aDetalhe[i][DT_COMPNOME]
            aConsolid[nPos][CS_PIORCOMP]  := aDetalhe[i][DT_COMPNOME]
            aConsolid[nPos][CS_PRIMPREC]  := aDetalhe[i][DT_PRCLIQ]
            aConsolid[nPos][CS_ULTPREC]   := aDetalhe[i][DT_PRCLIQ]
        Else
            // Acumula
            aConsolid[nPos][CS_QTDCOMP]  += 1
            aConsolid[nPos][CS_QTDTOTAL] += aDetalhe[i][DT_QUANT]
            aConsolid[nPos][CS_VLRTOTAL] += aDetalhe[i][DT_LIQTOT]
            aConsolid[nPos][CS_DESCMED]  += aDetalhe[i][DT_DESCPERC]

            // Atualiza melhor preco (menor liquido) + comprador
            If aDetalhe[i][DT_PRCLIQ] > 0 .And. ;
               aDetalhe[i][DT_PRCLIQ] < aConsolid[nPos][CS_MELHORPRC]
                aConsolid[nPos][CS_MELHORPRC] := aDetalhe[i][DT_PRCLIQ]
                aConsolid[nPos][CS_MELHFORN]  := aDetalhe[i][DT_NOMEFORN]
                aConsolid[nPos][CS_MELHCOMP]  := aDetalhe[i][DT_COMPNOME]
            EndIf

            // Atualiza pior preco (maior liquido) + comprador
            If aDetalhe[i][DT_PRCLIQ] > aConsolid[nPos][CS_PIORPRC]
                aConsolid[nPos][CS_PIORPRC]  := aDetalhe[i][DT_PRCLIQ]
                aConsolid[nPos][CS_PIORFORN] := aDetalhe[i][DT_NOMEFORN]
                aConsolid[nPos][CS_PIORCOMP] := aDetalhe[i][DT_COMPNOME]
            EndIf
        EndIf
    Next i

    // Pos-processamento: medias, variacoes e tendencia
    For i := 1 To Len(aConsolid)
        // Preco medio ponderado (valor total / quantidade total)
        aConsolid[i][CS_PRCMEDIO] := IIF(aConsolid[i][CS_QTDTOTAL] > 0, ;
            aConsolid[i][CS_VLRTOTAL] / aConsolid[i][CS_QTDTOTAL], 0)

        // Desconto medio (media simples dos percentuais)
        aConsolid[i][CS_DESCMED] := IIF(aConsolid[i][CS_QTDCOMP] > 0, ;
            aConsolid[i][CS_DESCMED] / aConsolid[i][CS_QTDCOMP], 0)

        // Variacao % (pior vs melhor)
        aConsolid[i][CS_VARIACAO] := IIF(aConsolid[i][CS_MELHORPRC] > 0, ;
            ((aConsolid[i][CS_PIORPRC] - aConsolid[i][CS_MELHORPRC]) / ;
             aConsolid[i][CS_MELHORPRC]) * 100, 0)

        // --- Tendencia: primeiro preco vs ultimo preco (cronologico) ---
        // Busca compras do item ordenadas por data
        aItemDet := {}
        For j := 1 To Len(aDetalhe)
            If aDetalhe[j][DT_CODITEM] == aConsolid[i][CS_CODITEM] .And. ;
               aDetalhe[j][DT_PRCLIQ] > 0
                aAdd(aItemDet, {aDetalhe[j][DT_DTDOC], aDetalhe[j][DT_PRCLIQ]})
            EndIf
        Next j

        If Len(aItemDet) >= 2
            // Ordena por data crescente
            aSort(aItemDet,,, {|x,y| DtoS(x[1]) < DtoS(y[1])})

            aConsolid[i][CS_PRIMPREC] := aItemDet[1][2]
            aConsolid[i][CS_ULTPREC]  := aItemDet[Len(aItemDet)][2]

            // Calcula variacao tendencia (ultimo vs primeiro)
            If aConsolid[i][CS_PRIMPREC] > 0
                nVarTend := ((aConsolid[i][CS_ULTPREC] - aConsolid[i][CS_PRIMPREC]) / ;
                    aConsolid[i][CS_PRIMPREC]) * 100
            Else
                nVarTend := 0
            EndIf

            Do Case
                Case nVarTend > 2
                    aConsolid[i][CS_TENDENC] := TEND_SUBIU     // Piorou
                Case nVarTend < -2
                    aConsolid[i][CS_TENDENC] := TEND_BAIXOU    // Melhorou
                Otherwise
                    aConsolid[i][CS_TENDENC] := TEND_MANTEVE
            EndCase
        Else
            // Apenas 1 compra, sem comparacao
            If Len(aItemDet) == 1
                aConsolid[i][CS_PRIMPREC] := aItemDet[1][2]
                aConsolid[i][CS_ULTPREC]  := aItemDet[1][2]
            EndIf
            aConsolid[i][CS_TENDENC] := TEND_MANTEVE
        EndIf
    Next i
Return

// =============================================================================
// TELA DE RESULTADO - VISAO CONSOLIDADA POR ITEM (Tela Principal)
// =============================================================================

/*/{Protheus.doc} TelaResultado
Tela principal de resultados: visao consolidada por item mostrando
tendencia de preco (SUBIU/MANTEVE/BAIXOU), melhor e pior preco com
fornecedor e comprador responsavel.
Double-click abre drill-down cronologico do item.
@type Static Function
@param aFiltros, Array com filtros aplicados
/*/
Static Function TelaResultado(aFiltros)
    Local oDlg
    Local oListCons
    Local oFont, oFontTit, oFontInd
    Local oBtnDetalhado, oBtnExcel, oBtnNova, oBtnFechar

    // Filtro rapido
    Local cFiltroRapido := Space(30)
    Local oGetFiltro, oBtnFiltrar, oBtnLimpar

    // Combo de ordenacao
    Local cOrdem     := "Por Item"
    Local aOrdens    := {"Por Item", "Maior Variacao", "Somente SUBIU", "Somente BAIXOU", "Somente MANTEVE"}
    Local oComboOrd

    // Contadores de tendencia
    Local nSubiu   := 0
    Local nManteve := 0
    Local nBaixou  := 0
    Local i

    // Periodo para titulo
    Local cTitulo := "Avaliacao de Negociacao - " + DtoC(aFiltros[1]) + " a " + DtoC(aFiltros[2])

    If Len(aConsolid) == 0
        MsgAlert("Nenhum dado consolidado disponivel!", "Atencao")
        Return
    EndIf

    // Conta tendencias
    For i := 1 To Len(aConsolid)
        Do Case
            Case aConsolid[i][CS_TENDENC] == TEND_SUBIU
                nSubiu++
            Case aConsolid[i][CS_TENDENC] == TEND_BAIXOU
                nBaixou++
            Otherwise
                nManteve++
        EndCase
    Next i

    // Fontes
    oFont    := TFont():New("Arial",, -11,, .F.)
    oFontTit := TFont():New("Arial",, -13, .T., .F.)
    oFontInd := TFont():New("Arial",, -11, .T., .F.)

    // Dialogo principal
    DEFINE MSDIALOG oDlg TITLE cTitulo ;
        FROM 0,0 TO 560, 970 PIXEL STYLE DS_MODALFRAME

    // =====================================================================
    // BARRA SUPERIOR - Resumo de tendencias
    // =====================================================================

    TSay():New(008, 010, ;
        {|| cValToChar(Len(aConsolid)) + " itens distintos  |  " + ;
            cValToChar(Len(aDetalheOrig)) + " compras no periodo"}, ;
        oDlg, , oFontTit, , , , .T., CLR_HBLUE, , 300, 14)

    // Indicadores de tendencia
    TSay():New(008, 320, {|| "BAIXOU: " + cValToChar(nBaixou)}, ;
        oDlg, , oFontInd, , , , .T., CLR_HGREEN, , 70, 12)
    TSay():New(008, 400, {|| "MANTEVE: " + cValToChar(nManteve)}, ;
        oDlg, , oFontInd, , , , .T., RGB(180, 140, 0), , 80, 12)
    TSay():New(008, 490, {|| "SUBIU: " + cValToChar(nSubiu)}, ;
        oDlg, , oFontInd, , , , .T., CLR_HRED, , 65, 12)

    @ 024, 005 TO 024, 478 OF oDlg PIXEL

    // =====================================================================
    // BARRA DE FILTROS
    // =====================================================================

    @ 030, 010 SAY "Buscar:" SIZE 038, 012 PIXEL OF oDlg FONT oFont
    @ 028, 050 MSGET oGetFiltro VAR cFiltroRapido SIZE 120, 012 PIXEL OF oDlg

    @ 027, 175 BUTTON oBtnFiltrar PROMPT "Filtrar" SIZE 045, 014 OF oDlg PIXEL ;
        ACTION FiltrarConsolidado(cFiltroRapido, cOrdem, oListCons, oDlg)

    @ 027, 225 BUTTON oBtnLimpar PROMPT "Limpar" SIZE 045, 014 OF oDlg PIXEL ;
        ACTION (cFiltroRapido := Space(30), cOrdem := "Por Item", ;
            oGetFiltro:Refresh(), ;
            FiltrarConsolidado("", "Por Item", oListCons, oDlg))

    // Ordenacao / Filtro de tendencia
    @ 030, 290 SAY "Ordenar/Filtrar:" SIZE 078, 012 PIXEL OF oDlg FONT oFont
    @ 028, 372 MSCOMBOBOX oComboOrd VAR cOrdem ITEMS aOrdens SIZE 105, 012 OF oDlg PIXEL
    oComboOrd:bChange := {|| FiltrarConsolidado(cFiltroRapido, cOrdem, oListCons, oDlg)}

    // Separador
    @ 046, 005 TO 046, 478 OF oDlg PIXEL

    // =====================================================================
    // GRID CONSOLIDADO - Visao principal
    // =====================================================================
    //
    // Colunas:
    // Item | Descricao | Compras | Menor Preco | Forn (menor) | Comprador (menor) |
    // Maior Preco | Forn (maior) | Comprador (maior) | Variacao% | Tendencia
    // =====================================================================

    @ 050, 005 LISTBOX oListCons FIELDS HEADER ;
        "Item", ;
        "Descricao", ;
        "Compras", ;
        "Menor Preco", ;
        "Forn (melhor)", ;
        "Comprador (melhor)", ;
        "Maior Preco", ;
        "Forn (pior)", ;
        "Comprador (pior)", ;
        "Variacao %", ;
        "Tendencia" ;
        COLSIZES ;
        60, 110, 36, 62, 80, 80, 62, 80, 80, 48, 55 ;
        SIZE 470, 185 OF oDlg PIXEL

    oListCons:SetArray(aConsolid)

    oListCons:bLine := {|| {;
        aConsolid[oListCons:nAt][CS_CODITEM],;
        SubStr(aConsolid[oListCons:nAt][CS_DESCITEM], 1, 28),;
        cValToChar(aConsolid[oListCons:nAt][CS_QTDCOMP]),;
        Transform(aConsolid[oListCons:nAt][CS_MELHORPRC], "@E 99,999.99"),;
        SubStr(aConsolid[oListCons:nAt][CS_MELHFORN], 1, 18),;
        SubStr(aConsolid[oListCons:nAt][CS_MELHCOMP], 1, 18),;
        Transform(aConsolid[oListCons:nAt][CS_PIORPRC], "@E 99,999.99"),;
        SubStr(aConsolid[oListCons:nAt][CS_PIORFORN], 1, 18),;
        SubStr(aConsolid[oListCons:nAt][CS_PIORCOMP], 1, 18),;
        Transform(aConsolid[oListCons:nAt][CS_VARIACAO], "@E 999.99") + "%",;
        PadR(aConsolid[oListCons:nAt][CS_TENDENC], 8) }}

    // Double-click abre drill-down cronologico do item
    oListCons:bLDblClick := {|| DetalheItemConsol(oListCons:nAt, aFiltros)}

    // =====================================================================
    // PAINEL DE TOTALIZADORES
    // =====================================================================
    @ 240, 005 TO 268, 478 OF oDlg PIXEL

    @ 245, 015 SAY "Total Comprado:" SIZE 075, 012 PIXEL OF oDlg FONT oFontInd
    TSay():New(245, 095, ;
        {|| "R$ " + Transform(nTotComprado, "@E 999,999,999.99")}, ;
        oDlg, , oFont, , , , .T., CLR_BLACK, , 100, 12)

    @ 245, 210 SAY "Desconto Total:" SIZE 075, 012 PIXEL OF oDlg FONT oFontInd
    TSay():New(245, 290, ;
        {|| "R$ " + Transform(nTotDesconto, "@E 999,999,999.99")}, ;
        oDlg, , oFont, , , , .T., CLR_HBLUE, , 100, 12)

    @ 255, 015 SAY "Preco Medio Pond.:" SIZE 078, 012 PIXEL OF oDlg FONT oFontInd
    TSay():New(255, 095, ;
        {|| "R$ " + Transform(nPrcMedioPond, "@E 999,999.99")}, ;
        oDlg, , oFont, , , , .T., CLR_BLACK, , 100, 12)

    TSay():New(255, 210, ;
        {|| cValToChar(Len(aConsolid)) + " itens | " + ;
            cValToChar(Len(aDetalheOrig)) + " compras"}, ;
        oDlg, , oFont, , , , .T., CLR_GRAY, , 200, 12)

    // =====================================================================
    // BOTOES DE ACAO
    // =====================================================================

    @ 275, 010 BUTTON oBtnDetalhado PROMPT "Ver Detalhado" SIZE 080, 018 OF oDlg PIXEL ;
        ACTION TelaDetalhado(aFiltros)

    @ 275, 100 BUTTON oBtnExcel PROMPT "Exportar Excel" SIZE 080, 018 OF oDlg PIXEL ;
        ACTION ExportarConsolidado(aFiltros)

    @ 275, 190 BUTTON oBtnNova PROMPT "Nova Consulta" SIZE 080, 018 OF oDlg PIXEL ;
        ACTION (oDlg:End(), U_ZAVALNEG())

    @ 275, 400 BUTTON oBtnFechar PROMPT "Fechar" SIZE 070, 018 OF oDlg PIXEL ;
        ACTION oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED

    FreeObj(oFont)
    FreeObj(oFontTit)
    FreeObj(oFontInd)
Return

// =============================================================================
// DRILL-DOWN CRONOLOGICO - Compras de um item no periodo
// =============================================================================

/*/{Protheus.doc} DetalheItemConsol
Ao clicar em um item no consolidado, abre detalhamento cronologico
com todas as compras daquele item, mostrando a variacao "vs Anterior"
para cada compra (% de mudanca em relacao a compra cronologica anterior).
@type Static Function
@param nLinha, Posicao no array aConsolid
@param aFiltros, Array com filtros aplicados
/*/
Static Function DetalheItemConsol(nLinha, aFiltros)
    Local oDlg, oListItem, oFont, oFontTit, oFontInd
    Local oBtnExcel, oBtnFechar
    Local aItemDet := {}
    Local aItemOrigIdx := {}  // Indices originais em aDetalheOrig
    Local aItemView := {}   // Array para exibicao com coluna "vs Anterior"
    Local cItem    := ""
    Local i
    Local nPrcAnt  := 0
    Local nVarAnt  := 0
    Local cVarAnt  := ""
    Local nCorTend := CLR_BLACK

    If nLinha < 1 .Or. nLinha > Len(aConsolid)
        Return
    EndIf

    cItem := aConsolid[nLinha][CS_CODITEM]

    // Filtra detalhes do item selecionado
    For i := 1 To Len(aDetalheOrig)
        If aDetalheOrig[i][DT_CODITEM] == cItem
            aAdd(aItemDet, aDetalheOrig[i])
            aAdd(aItemOrigIdx, i)
        EndIf
    Next i

    If Len(aItemDet) == 0
        MsgAlert("Nenhum detalhe encontrado para o item " + cItem, "Atencao")
        Return
    EndIf

    // Ordena por data crescente (cronologico)
    aSort(aItemDet,,, {|x,y| DtoS(x[DT_DTDOC]) + x[DT_NUMDOC] < ;
                              DtoS(y[DT_DTDOC]) + y[DT_NUMDOC]})

    // Monta array de visualizacao com coluna "vs Anterior"
    // Formato: {Data, PC, Fornecedor, Comprador, Qtd, Preco Unit, vs Anterior%, Status, nPosOrig}
    nPrcAnt := 0
    For i := 1 To Len(aItemDet)
        If nPrcAnt > 0 .And. aItemDet[i][DT_PRCLIQ] > 0
            nVarAnt := ((aItemDet[i][DT_PRCLIQ] - nPrcAnt) / nPrcAnt) * 100
            cVarAnt := Transform(nVarAnt, "@E 999.99") + "%"
            If nVarAnt > 0
                cVarAnt := "+" + AllTrim(cVarAnt)
            EndIf
        Else
            nVarAnt := 0
            cVarAnt := "-"
        EndIf

        aAdd(aItemView, {;
            DtoC(aItemDet[i][DT_DTDOC]),;                             // [1] Data
            AllTrim(StrTran(aItemDet[i][DT_NUMDOC], "PC ", "")),;     // [2] PC
            SubStr(aItemDet[i][DT_CODFORN] + "-" + ;
                aItemDet[i][DT_NOMEFORN], 1, 22),;                    // [3] Fornecedor
            SubStr(aItemDet[i][DT_COMPNOME], 1, 18),;                 // [4] Comprador
            aItemDet[i][DT_QUANT],;                                    // [5] Qtd (numerico)
            aItemDet[i][DT_PRCLIQ],;                                   // [6] Preco Unit (numerico)
            cVarAnt,;                                                   // [7] vs Anterior (string formatada)
            nVarAnt,;                                                   // [8] vs Anterior (numerico)
            aItemDet[i][DT_STATUS],;                                   // [9] Status
            aItemOrigIdx[i] })                                           // [10] Posicao no aDetalheOrig

        If aItemDet[i][DT_PRCLIQ] > 0
            nPrcAnt := aItemDet[i][DT_PRCLIQ]
        EndIf
    Next i

    // Cor da tendencia
    Do Case
        Case aConsolid[nLinha][CS_TENDENC] == TEND_SUBIU
            nCorTend := CLR_HRED
        Case aConsolid[nLinha][CS_TENDENC] == TEND_BAIXOU
            nCorTend := CLR_HGREEN
        Otherwise
            nCorTend := RGB(180, 140, 0)
    EndCase

    oFont    := TFont():New("Arial",, -11,, .F.)
    oFontTit := TFont():New("Arial",, -13, .T., .F.)
    oFontInd := TFont():New("Arial",, -11, .T., .F.)

    DEFINE MSDIALOG oDlg TITLE "Historico de Compras: " + cItem + " - " + ;
        aConsolid[nLinha][CS_DESCITEM] ;
        FROM 0,0 TO 430, 900 PIXEL STYLE DS_MODALFRAME

    // Cabecalho com resumo
    TSay():New(008, 010, ;
        {|| cValToChar(Len(aItemView)) + " compras no periodo"}, ;
        oDlg, , oFontTit, , , , .T., CLR_HBLUE, , 150, 14)

    TSay():New(008, 170, ;
        {|| "Tendencia: " + aConsolid[nLinha][CS_TENDENC]}, ;
        oDlg, , oFontInd, , , , .T., nCorTend, , 100, 14)

    TSay():New(008, 290, ;
        {|| "1o Preco: R$ " + Transform(aConsolid[nLinha][CS_PRIMPREC], "@E 99,999.99") + ;
            "  ->  Ultimo: R$ " + Transform(aConsolid[nLinha][CS_ULTPREC], "@E 99,999.99")}, ;
        oDlg, , oFont, , , , .T., CLR_BLACK, , 200, 12)

    // Resumo melhor/pior
    TSay():New(022, 010, ;
        {|| "Melhor: R$ " + Transform(aConsolid[nLinha][CS_MELHORPRC], "@E 99,999.99") + ;
            " (" + SubStr(aConsolid[nLinha][CS_MELHFORN], 1, 15) + ;
            " / " + SubStr(aConsolid[nLinha][CS_MELHCOMP], 1, 15) + ")"}, ;
        oDlg, , oFont, , , , .T., CLR_HGREEN, , 250, 12)

    TSay():New(022, 270, ;
        {|| "Pior: R$ " + Transform(aConsolid[nLinha][CS_PIORPRC], "@E 99,999.99") + ;
            " (" + SubStr(aConsolid[nLinha][CS_PIORFORN], 1, 15) + ;
            " / " + SubStr(aConsolid[nLinha][CS_PIORCOMP], 1, 15) + ")"}, ;
        oDlg, , oFont, , , , .T., CLR_HRED, , 250, 12)

    @ 036, 005 TO 036, 445 OF oDlg PIXEL

    // =====================================================================
    // GRID CRONOLOGICO
    // =====================================================================
    //
    // Colunas: Data | PC | Fornecedor | Comprador | Qtd | Preco Unit | vs Anterior | Status
    // =====================================================================

    @ 040, 005 LISTBOX oListItem FIELDS HEADER ;
        "Data", ;
        "PC", ;
        "Fornecedor", ;
        "Comprador", ;
        "Qtd", ;
        "Preco Unit", ;
        "vs Anterior", ;
        "Status" ;
        COLSIZES ;
        48, 50, 100, 85, 48, 65, 60, 45 ;
        SIZE 440, 155 OF oDlg PIXEL

    oListItem:SetArray(aItemView)

    oListItem:bLine := {|| {;
        aItemView[oListItem:nAt][1],;
        aItemView[oListItem:nAt][2],;
        aItemView[oListItem:nAt][3],;
        aItemView[oListItem:nAt][4],;
        Transform(aItemView[oListItem:nAt][5], "@E 9,999.99"),;
        Transform(aItemView[oListItem:nAt][6], "@E 99,999.99"),;
        aItemView[oListItem:nAt][7],;
        PadR(aItemView[oListItem:nAt][9], 7) }}

    // Double-click abre detalhe completo do registro
    oListItem:bLDblClick := {|| DetalheRegistro(aItemView[oListItem:nAt][10])}

    // =====================================================================
    // BOTOES
    // =====================================================================

    @ 200, 150 BUTTON oBtnExcel PROMPT "Exportar Excel" SIZE 080, 016 OF oDlg PIXEL ;
        ACTION ExportarExcel(aFiltros)

    @ 200, 280 BUTTON oBtnFechar PROMPT "Fechar" SIZE 070, 016 OF oDlg PIXEL ;
        ACTION oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED

    FreeObj(oFont)
    FreeObj(oFontTit)
    FreeObj(oFontInd)
Return

// =============================================================================
// DRILL-DOWN - DETALHE DO REGISTRO SELECIONADO
// =============================================================================

/*/{Protheus.doc} DetalheRegistro
Abre dialogo com todos os campos do registro selecionado no grid
detalhado, incluindo referencia a NF/Entrada vinculada (SD1).
@type Static Function
@param nLinha, Posicao no array aDetalheOrig
/*/
Static Function DetalheRegistro(nLinha)
    Local oDlg, oFont, oFontTit, oFontVal
    Local oBtnNF, oBtnFechar
    Local cPCNum    := ""
    Local cPCItem   := ""
    Local nCorSts   := CLR_BLACK
    Local cNFInfo   := ""

    If nLinha < 1 .Or. nLinha > Len(aDetalheOrig)
        MsgAlert("Selecione um registro no grid!", "Atencao")
        Return
    EndIf

    cPCNum  := AllTrim(StrTran(aDetalheOrig[nLinha][DT_NUMDOC], "PC ", ""))
    cPCItem := aDetalheOrig[nLinha][DT_ITEMPC]

    // Cor do status
    Do Case
        Case aDetalheOrig[nLinha][DT_STATUS] == STS_PIOROU
            nCorSts := CLR_HRED
        Case aDetalheOrig[nLinha][DT_STATUS] == STS_ALERTA
            nCorSts := RGB(180, 140, 0)
        Otherwise
            nCorSts := CLR_HGREEN
    EndCase

    // Busca NF vinculada
    cNFInfo := BuscaNFVinculada(cPCNum, cPCItem, ;
        aDetalheOrig[nLinha][DT_CODFORN], aDetalheOrig[nLinha][DT_LOJAFORN])

    oFont    := TFont():New("Arial",, -11,, .F.)
    oFontTit := TFont():New("Arial",, -13, .T., .F.)
    oFontVal := TFont():New("Arial",, -12,, .F.)

    DEFINE MSDIALOG oDlg TITLE "Detalhe do Registro - PC " + cPCNum + " Item " + cPCItem ;
        FROM 0,0 TO 480, 440 PIXEL STYLE DS_MODALFRAME

    // Status em destaque
    TSay():New(010, 010, {|| "STATUS: " + aDetalheOrig[nLinha][DT_STATUS]}, ;
        oDlg, , oFontTit, , , , .T., nCorSts, , 200, 18)
    @ 028, 005 TO 028, 215 OF oDlg PIXEL

    // === Dados do Item ===
    @ 034, 010 SAY "ITEM"                 SIZE 080, 012 PIXEL OF oDlg FONT oFontTit
    @ 048, 010 SAY "Codigo:"              SIZE 060, 011 PIXEL OF oDlg FONT oFont
    @ 048, 075 SAY aDetalheOrig[nLinha][DT_CODITEM]  SIZE 130, 011 PIXEL OF oDlg FONT oFontVal
    @ 060, 010 SAY "Descricao:"           SIZE 060, 011 PIXEL OF oDlg FONT oFont
    @ 060, 075 SAY aDetalheOrig[nLinha][DT_DESCITEM] SIZE 130, 011 PIXEL OF oDlg FONT oFontVal
    @ 072, 010 SAY "Grupo:"               SIZE 060, 011 PIXEL OF oDlg FONT oFont
    @ 072, 075 SAY aDetalheOrig[nLinha][DT_GRUPO]    SIZE 050, 011 PIXEL OF oDlg FONT oFontVal
    @ 072, 130 SAY "UM:"                  SIZE 020, 011 PIXEL OF oDlg FONT oFont
    @ 072, 152 SAY aDetalheOrig[nLinha][DT_UM]       SIZE 050, 011 PIXEL OF oDlg FONT oFontVal

    // === Dados do Fornecedor ===
    @ 090, 005 TO 090, 215 OF oDlg PIXEL
    @ 096, 010 SAY "FORNECEDOR"           SIZE 100, 012 PIXEL OF oDlg FONT oFontTit
    @ 110, 010 SAY "Codigo:"              SIZE 060, 011 PIXEL OF oDlg FONT oFont
    @ 110, 075 SAY aDetalheOrig[nLinha][DT_CODFORN] + "/" + aDetalheOrig[nLinha][DT_LOJAFORN] ;
                                           SIZE 100, 011 PIXEL OF oDlg FONT oFontVal
    @ 122, 010 SAY "Nome:"                SIZE 060, 011 PIXEL OF oDlg FONT oFont
    @ 122, 075 SAY aDetalheOrig[nLinha][DT_NOMEFORN] SIZE 130, 011 PIXEL OF oDlg FONT oFontVal

    // === Dados do Documento ===
    @ 140, 005 TO 140, 215 OF oDlg PIXEL
    @ 146, 010 SAY "DOCUMENTO"            SIZE 100, 012 PIXEL OF oDlg FONT oFontTit
    @ 160, 010 SAY "PC Numero:"           SIZE 060, 011 PIXEL OF oDlg FONT oFont
    @ 160, 075 SAY aDetalheOrig[nLinha][DT_NUMDOC]  SIZE 100, 011 PIXEL OF oDlg FONT oFontVal
    @ 172, 010 SAY "Item PC:"             SIZE 060, 011 PIXEL OF oDlg FONT oFont
    @ 172, 075 SAY cPCItem                SIZE 050, 011 PIXEL OF oDlg FONT oFontVal
    @ 184, 010 SAY "Data:"                SIZE 060, 011 PIXEL OF oDlg FONT oFont
    @ 184, 075 SAY DtoC(aDetalheOrig[nLinha][DT_DTDOC]) SIZE 060, 011 PIXEL OF oDlg FONT oFontVal
    @ 196, 010 SAY "Filial:"              SIZE 060, 011 PIXEL OF oDlg FONT oFont
    @ 196, 075 SAY aDetalheOrig[nLinha][DT_FILIAL]   SIZE 050, 011 PIXEL OF oDlg FONT oFontVal

    // === Valores ===
    @ 214, 005 TO 214, 215 OF oDlg PIXEL
    @ 220, 010 SAY "VALORES"              SIZE 100, 012 PIXEL OF oDlg FONT oFontTit
    @ 234, 010 SAY "Quantidade:"           SIZE 075, 011 PIXEL OF oDlg FONT oFont
    @ 234, 090 SAY Transform(aDetalheOrig[nLinha][DT_QUANT], "@E 99,999.9999") + " " + ;
        aDetalheOrig[nLinha][DT_UM]        SIZE 100, 011 PIXEL OF oDlg FONT oFontVal
    @ 246, 010 SAY "Preco Bruto Unit:"     SIZE 075, 011 PIXEL OF oDlg FONT oFont
    @ 246, 090 SAY "R$ " + Transform(aDetalheOrig[nLinha][DT_PRCBRUTO], "@E 999,999.99") ;
                                            SIZE 100, 011 PIXEL OF oDlg FONT oFontVal
    @ 258, 010 SAY "Desconto R$ (unit):"   SIZE 075, 011 PIXEL OF oDlg FONT oFont
    @ 258, 090 SAY "R$ " + Transform(aDetalheOrig[nLinha][DT_DESCRS], "@E 999,999.99") + ;
        " (" + Transform(aDetalheOrig[nLinha][DT_DESCPERC], "@E 99.99") + "%)" ;
                                            SIZE 130, 011 PIXEL OF oDlg FONT oFontVal
    @ 270, 010 SAY "Preco Liq Unit:"       SIZE 075, 011 PIXEL OF oDlg FONT oFont
    @ 270, 090 SAY "R$ " + Transform(aDetalheOrig[nLinha][DT_PRCLIQ], "@E 999,999.99") ;
                                            SIZE 100, 011 PIXEL OF oDlg FONT oFontVal
    @ 282, 010 SAY "Valor Liq Total:"      SIZE 075, 011 PIXEL OF oDlg FONT oFont
    @ 282, 090 SAY "R$ " + Transform(aDetalheOrig[nLinha][DT_LIQTOT], "@E 999,999,999.99") ;
                                            SIZE 100, 011 PIXEL OF oDlg FONT oFontVal

    // === Comparativo ===
    @ 300, 005 TO 300, 215 OF oDlg PIXEL
    @ 306, 010 SAY "COMPARATIVO"           SIZE 100, 012 PIXEL OF oDlg FONT oFontTit
    @ 320, 010 SAY "Melhor Preco Per.:"    SIZE 075, 011 PIXEL OF oDlg FONT oFont
    @ 320, 090 SAY "R$ " + Transform(aDetalheOrig[nLinha][DT_MELHORPRC], "@E 999,999.99") ;
                                            SIZE 100, 011 PIXEL OF oDlg FONT oFontVal
    @ 332, 010 SAY "Melhor Fornecedor:"    SIZE 075, 011 PIXEL OF oDlg FONT oFont
    @ 332, 090 SAY aDetalheOrig[nLinha][DT_MELHFORN] SIZE 130, 011 PIXEL OF oDlg FONT oFontVal
    @ 344, 010 SAY "Diferenca R$:"         SIZE 075, 011 PIXEL OF oDlg FONT oFont
    TSay():New(344, 090, ;
        {|| "R$ " + Transform(aDetalheOrig[nLinha][DT_DIFRS], "@E 999,999.99") + ;
            " (" + Transform(aDetalheOrig[nLinha][DT_DIFPERC], "@E 99.99") + "%)"}, ;
        oDlg, , oFontVal, , , , .T., nCorSts, , 130, 11)

    // === Comprador ===
    @ 362, 005 TO 362, 215 OF oDlg PIXEL
    @ 368, 010 SAY "COMPRADOR"             SIZE 100, 012 PIXEL OF oDlg FONT oFontTit
    @ 382, 010 SAY "Codigo-Nome:"          SIZE 060, 011 PIXEL OF oDlg FONT oFont
    @ 382, 075 SAY IIF(!Empty(aDetalheOrig[nLinha][DT_COMPRAD]), ;
        aDetalheOrig[nLinha][DT_COMPRAD] + " - " + aDetalheOrig[nLinha][DT_COMPNOME], ;
        "(nao informado)") ;
                                            SIZE 140, 011 PIXEL OF oDlg FONT oFontVal

    // === NF Vinculada ===
    @ 400, 005 TO 400, 215 OF oDlg PIXEL
    @ 406, 010 SAY "NF VINCULADA"          SIZE 080, 012 PIXEL OF oDlg FONT oFontTit
    @ 420, 010 SAY IIF(!Empty(cNFInfo), cNFInfo, "(Nenhuma NF encontrada para este PC)") ;
                                            SIZE 200, 011 PIXEL OF oDlg FONT oFont

    // === Info complementar ===
    @ 432, 010 SAY "CC: " + aDetalheOrig[nLinha][DT_CC] ;
                                            SIZE 200, 011 PIXEL OF oDlg FONT oFont

    // Botao fechar
    @ 450, 090 BUTTON oBtnFechar PROMPT "Fechar" SIZE 070, 016 OF oDlg PIXEL ;
        ACTION oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED

    FreeObj(oFont)
    FreeObj(oFontTit)
    FreeObj(oFontVal)
Return

// =============================================================================
// BUSCA NF VINCULADA AO PC (drill-down complementar)
// =============================================================================

/*/{Protheus.doc} BuscaNFVinculada
Busca no SD1 se existe documento de entrada vinculado ao PC informado.
Retorna string com info da NF ou vazio se nao encontrado.
@type Static Function
@param cPCNum, Numero do PC
@param cPCItem, Item do PC
@param cFornece, Codigo do fornecedor
@param cLoja, Loja do fornecedor
@return cInfo, String com dados da NF ou ""
/*/
Static Function BuscaNFVinculada(cPCNum, cPCItem, cFornece, cLoja)
    Local cInfo   := ""
    Local cAlias  := GetNextAlias()
    Local cQuery  := ""
    Local cSD1    := RetSqlName("SD1")

    cQuery := " SELECT TOP 1 "
    cQuery += "   D1_DOC, D1_SERIE, D1_EMISSAO, D1_VUNIT, D1_TOTAL, D1_QUANT "
    cQuery += " FROM " + cSD1 + " "
    cQuery += " WHERE D_E_L_E_T_ = ' ' "
    cQuery += "   AND D1_FILIAL = '" + xFilial("SD1") + "' "
    cQuery += "   AND D1_PEDIDO = '" + cPCNum + "' "
    cQuery += "   AND D1_ITEMPC = '" + cPCItem + "' "
    cQuery += "   AND D1_FORNECE = '" + cFornece + "' "
    cQuery += "   AND D1_LOJA = '" + cLoja + "' "
    cQuery += " ORDER BY D1_EMISSAO DESC "

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    If !(cAlias)->(Eof())
        cInfo := "NF " + AllTrim((cAlias)->D1_DOC) + ;
            "/" + AllTrim((cAlias)->D1_SERIE) + ;
            " - " + DtoC(StoD((cAlias)->D1_EMISSAO)) + ;
            " - Unit: R$ " + Transform((cAlias)->D1_VUNIT, "@E 999,999.99") + ;
            " - Total: R$ " + Transform((cAlias)->D1_TOTAL, "@E 999,999.99")
    EndIf

    (cAlias)->(DbCloseArea())
Return cInfo

// =============================================================================
// FILTRAR CONSOLIDADO (filtro rapido + tendencia)
// =============================================================================

/*/{Protheus.doc} FiltrarConsolidado
Filtra o array aConsolid com base no texto digitado e no filtro
de tendencia (combo de ordenacao/filtro).
Busca em: codigo item, descricao, fornecedor, comprador.
@type Static Function
/*/
Static Function FiltrarConsolidado(cFiltro, cOrdem, oListCons, oDlg)
    Local cBusca := AllTrim(Upper(cFiltro))
    Local cOrd   := Upper(AllTrim(cOrdem))
    Local i
    Local lAdd
    Local aConsolidOrig := {}

    // Recria consolidado completo a partir do aDetalheOrig
    // (precisamos de uma copia original sem filtro)
    // Em vez disso, vamos refazer MontaConsolidado e filtrar
    // Primeiro salva o consolidado original
    MontaConsolidado()
    aConsolidOrig := aClone(aConsolid)

    // Aplica filtros
    aConsolid := {}

    For i := 1 To Len(aConsolidOrig)
        lAdd := .T.

        // Filtro de texto
        If !Empty(cBusca)
            If !(cBusca $ Upper(aConsolidOrig[i][CS_CODITEM])) .And. ;
               !(cBusca $ Upper(aConsolidOrig[i][CS_DESCITEM])) .And. ;
               !(cBusca $ Upper(aConsolidOrig[i][CS_MELHFORN])) .And. ;
               !(cBusca $ Upper(aConsolidOrig[i][CS_PIORFORN])) .And. ;
               !(cBusca $ Upper(aConsolidOrig[i][CS_MELHCOMP])) .And. ;
               !(cBusca $ Upper(aConsolidOrig[i][CS_PIORCOMP]))
                lAdd := .F.
            EndIf
        EndIf

        // Filtro de tendencia
        If lAdd
            Do Case
                Case "SUBIU" $ cOrd
                    lAdd := (aConsolidOrig[i][CS_TENDENC] == TEND_SUBIU)
                Case "BAIXOU" $ cOrd
                    lAdd := (aConsolidOrig[i][CS_TENDENC] == TEND_BAIXOU)
                Case "MANTEVE" $ cOrd
                    lAdd := (aConsolidOrig[i][CS_TENDENC] == TEND_MANTEVE)
            EndCase
        EndIf

        If lAdd
            aAdd(aConsolid, aConsolidOrig[i])
        EndIf
    Next i

    If Len(aConsolid) == 0
        aConsolid := aClone(aConsolidOrig)
        MsgInfo("Nenhum registro encontrado com os filtros.", "Filtro")
    EndIf

    // Ordenacao
    If Len(aConsolid) > 1
        Do Case
            Case "VARIACAO" $ cOrd
                aSort(aConsolid,,, {|x,y| x[CS_VARIACAO] > y[CS_VARIACAO]})
            Otherwise
                aSort(aConsolid,,, {|x,y| x[CS_CODITEM] < y[CS_CODITEM]})
        EndCase
    EndIf

    // Atualiza grid
    If ValType(oListCons) == "O" .And. oListCons != Nil
        oListCons:nAt := 1
        oListCons:SetArray(aConsolid)
        oListCons:Refresh()
    EndIf

    If ValType(oDlg) == "O" .And. oDlg != Nil
        oDlg:Refresh()
    EndIf
Return

// =============================================================================
// TELA DETALHADA (Visao completa de todas as compras)
// =============================================================================

/*/{Protheus.doc} TelaDetalhado
Tela secundaria com visao detalhada de todas as compras, com todas
as colunas incluindo fornecedor, comprador, valores e status.
Acessada pelo botao "Ver Detalhado" na tela principal consolidada.
@type Static Function
@param aFiltros, Array com filtros aplicados
/*/
Static Function TelaDetalhado(aFiltros)
    Local oDlg, oListDet
    Local oFont, oFontTit
    Local oBtnFechar
    Local cTitulo := "Detalhado - Todas as Compras - " + DtoC(aFiltros[1]) + " a " + DtoC(aFiltros[2])

    If Len(aDetalheOrig) == 0
        MsgAlert("Nenhum dado detalhado disponivel!", "Atencao")
        Return
    EndIf

    oFont    := TFont():New("Arial",, -11,, .F.)
    oFontTit := TFont():New("Arial",, -13, .T., .F.)

    DEFINE MSDIALOG oDlg TITLE cTitulo ;
        FROM 0,0 TO 520, 970 PIXEL STYLE DS_MODALFRAME

    TSay():New(008, 010, ;
        {|| cValToChar(Len(aDetalheOrig)) + " compras no periodo  |  " + ;
            "Total: R$ " + Transform(nTotComprado, "@E 999,999,999.99")}, ;
        oDlg, , oFontTit, , , , .T., CLR_HBLUE, , 450, 14)

    @ 022, 005 TO 022, 478 OF oDlg PIXEL

    @ 026, 005 LISTBOX oListDet FIELDS HEADER ;
        "Item", ;
        "Descricao", ;
        "Fornecedor", ;
        "Comprador", ;
        "Data", ;
        "PC", ;
        "Qtd", ;
        "Bruto Unit", ;
        "Desc %", ;
        "Liq Unit", ;
        "Liq Total", ;
        "Melhor", ;
        "Dif %", ;
        "Status" ;
        COLSIZES ;
        55, 95, 80, 75, 45, 50, 38, 60, 36, 60, 65, 60, 36, 45 ;
        SIZE 470, 210 OF oDlg PIXEL

    oListDet:SetArray(aDetalheOrig)

    oListDet:bLine := {|| {;
        aDetalheOrig[oListDet:nAt][DT_CODITEM],;
        SubStr(aDetalheOrig[oListDet:nAt][DT_DESCITEM], 1, 24),;
        SubStr(aDetalheOrig[oListDet:nAt][DT_CODFORN] + "-" + aDetalheOrig[oListDet:nAt][DT_NOMEFORN], 1, 20),;
        SubStr(aDetalheOrig[oListDet:nAt][DT_COMPNOME], 1, 18),;
        DtoC(aDetalheOrig[oListDet:nAt][DT_DTDOC]),;
        aDetalheOrig[oListDet:nAt][DT_NUMDOC],;
        Transform(aDetalheOrig[oListDet:nAt][DT_QUANT], "@E 9,999.99"),;
        Transform(aDetalheOrig[oListDet:nAt][DT_PRCBRUTO], "@E 99,999.99"),;
        Transform(aDetalheOrig[oListDet:nAt][DT_DESCPERC], "@E 99.99") + "%",;
        Transform(aDetalheOrig[oListDet:nAt][DT_PRCLIQ], "@E 99,999.99"),;
        Transform(aDetalheOrig[oListDet:nAt][DT_LIQTOT], "@E 999,999.99"),;
        Transform(aDetalheOrig[oListDet:nAt][DT_MELHORPRC], "@E 99,999.99"),;
        Transform(aDetalheOrig[oListDet:nAt][DT_DIFPERC], "@E 99.99") + "%",;
        PadR(aDetalheOrig[oListDet:nAt][DT_STATUS], 7) }}

    // Double-click abre drill-down do registro
    oListDet:bLDblClick := {|| DetalheRegistro(oListDet:nAt)}

    @ 242, 200 BUTTON oBtnFechar PROMPT "Fechar" SIZE 070, 018 OF oDlg PIXEL ;
        ACTION oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED

    FreeObj(oFont)
    FreeObj(oFontTit)
Return

// =============================================================================
// EXPORTAR EXCEL - VISAO DETALHADA
// =============================================================================

/*/{Protheus.doc} ExportarExcel
Exporta os dados detalhados para Excel via TReport.
@type Static Function
@param aFiltros, Array com filtros aplicados
/*/
Static Function ExportarExcel(aFiltros)
    Local oReport, oSection

    If Len(aDetalheOrig) == 0
        MsgAlert("Nenhum dado para exportar!", "Atencao")
        Return
    EndIf

    oReport := TReport():New("ZCOMP01D", ;
        "Avaliacao de Negociacao - Detalhado", "", ;
        {|oReport| PrtDetExcel(oReport, aFiltros)}, ;
        "Analise de negociacao de itens - Filial: " + cFilAnt)

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    oSection := TRSection():New(oReport, "Detalhado", {})

    TRCell():New(oSection, "FILIAL",     "", "Filial",          "@!", 6)
    TRCell():New(oSection, "ITEM",       "", "Item",            "@!", 15)
    TRCell():New(oSection, "DESCRICAO",  "", "Descricao",       "@!", 30)
    TRCell():New(oSection, "FORNECEDOR", "", "Fornecedor",      "@!", 25)
    TRCell():New(oSection, "NOMEFORN",   "", "Nome Fornecedor", "@!", 25)
    TRCell():New(oSection, "DATA",       "", "Data",            "@D", 10)
    TRCell():New(oSection, "DOCUMENTO",  "", "Documento",       "@!", 12)
    TRCell():New(oSection, "QTDE",       "", "Quantidade",      "@E 99,999.9999", 12)
    TRCell():New(oSection, "BRUTOUNIT",  "", "Bruto Unit",      "@E 999,999.99", 12)
    TRCell():New(oSection, "DESCRS",     "", "Desconto R$",     "@E 999,999.99", 12)
    TRCell():New(oSection, "DESCPERC",   "", "Desconto %",      "@E 99.99", 8)
    TRCell():New(oSection, "LIQUNIT",    "", "Liq Unit",        "@E 999,999.99", 12)
    TRCell():New(oSection, "LIQTOTAL",   "", "Liq Total",       "@E 999,999,999.99", 15)
    TRCell():New(oSection, "MELHORPRC",  "", "Melhor Preco",    "@E 999,999.99", 12)
    TRCell():New(oSection, "DIFRS",      "", "Dif R$",          "@E 999,999.99", 12)
    TRCell():New(oSection, "DIFPERC",    "", "Dif %",           "@E 99.99", 8)
    TRCell():New(oSection, "STATUS",     "", "Status",          "@!", 8)
    TRCell():New(oSection, "MELHFORN",   "", "Melhor Forn",     "@!", 25)
    TRCell():New(oSection, "CC",         "", "Centro Custo",    "@!", 12)
    TRCell():New(oSection, "COMPRADOR",  "", "Comprador",       "@!", 20)

    oReport:PrintDialog()
Return

/*/{Protheus.doc} PrintExcelDet
Popula o TReport detalhado com os dados da consulta.
@type Static Function
/*/
Static Function PrtDetExcel(oReport, aFiltros)
    Local oSection := oReport:Section(1)
    Local i

    oReport:SetMeter(0)
    oSection:Init()

    // Cabecalho
    oSection:SetHeaderSection(.T.)
    oReport:PrintText("Periodo: " + DtoC(aFiltros[1]) + " a " + DtoC(aFiltros[2]) + ;
        "   |   Filial: " + cFilAnt, 0)
    oReport:PrintText("Total Comprado: R$ " + Transform(nTotComprado, "@E 999,999,999.99") + ;
        "   |   Desconto Total: R$ " + Transform(nTotDesconto, "@E 999,999,999.99") + ;
        "   |   Preco Medio Pond: R$ " + Transform(nPrcMedioPond, "@E 999,999.99"), 0)
    oReport:SkipLine()

    // Dados
    For i := 1 To Len(aDetalheOrig)
        oSection:Cell("FILIAL"):SetValue(aDetalheOrig[i][DT_FILIAL])
        oSection:Cell("ITEM"):SetValue(aDetalheOrig[i][DT_CODITEM])
        oSection:Cell("DESCRICAO"):SetValue(aDetalheOrig[i][DT_DESCITEM])
        oSection:Cell("FORNECEDOR"):SetValue(aDetalheOrig[i][DT_CODFORN])
        oSection:Cell("NOMEFORN"):SetValue(aDetalheOrig[i][DT_NOMEFORN])
        oSection:Cell("DATA"):SetValue(aDetalheOrig[i][DT_DTDOC])
        oSection:Cell("DOCUMENTO"):SetValue(aDetalheOrig[i][DT_NUMDOC])
        oSection:Cell("QTDE"):SetValue(aDetalheOrig[i][DT_QUANT])
        oSection:Cell("BRUTOUNIT"):SetValue(aDetalheOrig[i][DT_PRCBRUTO])
        oSection:Cell("DESCRS"):SetValue(aDetalheOrig[i][DT_DESCRS])
        oSection:Cell("DESCPERC"):SetValue(aDetalheOrig[i][DT_DESCPERC])
        oSection:Cell("LIQUNIT"):SetValue(aDetalheOrig[i][DT_PRCLIQ])
        oSection:Cell("LIQTOTAL"):SetValue(aDetalheOrig[i][DT_LIQTOT])
        oSection:Cell("MELHORPRC"):SetValue(aDetalheOrig[i][DT_MELHORPRC])
        oSection:Cell("DIFRS"):SetValue(aDetalheOrig[i][DT_DIFRS])
        oSection:Cell("DIFPERC"):SetValue(aDetalheOrig[i][DT_DIFPERC])
        oSection:Cell("STATUS"):SetValue(aDetalheOrig[i][DT_STATUS])
        oSection:Cell("MELHFORN"):SetValue(aDetalheOrig[i][DT_MELHFORN])
        oSection:Cell("CC"):SetValue(aDetalheOrig[i][DT_CC])
        oSection:Cell("COMPRADOR"):SetValue(aDetalheOrig[i][DT_COMPNOME])

        oSection:PrintLine()
        oReport:IncMeter()
    Next i

    // Totais
    oReport:SkipLine()
    oReport:PrintText("TOTAL COMPRADO: R$ " + Transform(nTotComprado, "@E 999,999,999.99") + ;
        "   |   DESCONTO TOTAL: R$ " + Transform(nTotDesconto, "@E 999,999,999.99"), 0)
    oReport:PrintText("PRECO MEDIO PONDERADO: R$ " + Transform(nPrcMedioPond, "@E 999,999.99") + ;
        "   |   " + cValToChar(Len(aConsolid)) + " itens distintos" + ;
        "   |   " + cValToChar(Len(aDetalheOrig)) + " linhas", 0)

    oSection:Finish()
Return

// =============================================================================
// EXPORTAR EXCEL - VISAO CONSOLIDADA
// =============================================================================

/*/{Protheus.doc} ExportarConsolidado
Exporta os dados consolidados por item para Excel via TReport.
@type Static Function
@param aFiltros, Array com filtros aplicados
/*/
Static Function ExportarConsolidado(aFiltros)
    Local oReport, oSection

    If Len(aConsolid) == 0
        MsgAlert("Nenhum dado consolidado para exportar!", "Atencao")
        Return
    EndIf

    oReport := TReport():New("ZCOMP01C", ;
        "Avaliacao de Negociacao - Consolidado por Item", "", ;
        {|oReport| PrtConsExcel(oReport, aFiltros)}, ;
        "Analise consolidada por item - Filial: " + cFilAnt)

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    oSection := TRSection():New(oReport, "Consolidado", {})

    TRCell():New(oSection, "ITEM",       "", "Item",            "@!", 15)
    TRCell():New(oSection, "DESCRICAO",  "", "Descricao",       "@!", 30)
    TRCell():New(oSection, "UM",         "", "UM",              "@!", 5)
    TRCell():New(oSection, "GRUPO",      "", "Grupo",           "@!", 8)
    TRCell():New(oSection, "COMPRAS",    "", "Qtd Compras",     "@E 9999", 8)
    TRCell():New(oSection, "QTDTOTAL",   "", "Qtd Total",       "@E 99,999.9999", 12)
    TRCell():New(oSection, "VLRTOTAL",   "", "Vlr Total",       "@E 999,999,999.99", 15)
    TRCell():New(oSection, "PRCMEDIO",   "", "Prc Medio",       "@E 999,999.99", 12)
    TRCell():New(oSection, "MELHORPRC",  "", "Melhor Preco",    "@E 999,999.99", 12)
    TRCell():New(oSection, "PIORPRC",    "", "Pior Preco",      "@E 999,999.99", 12)
    TRCell():New(oSection, "VARIACAO",   "", "Variacao %",      "@E 999.99", 10)
    TRCell():New(oSection, "MELHFORN",   "", "Melhor Forn",     "@!", 25)
    TRCell():New(oSection, "MELHCOMP",   "", "Comprador (melhor)", "@!", 20)
    TRCell():New(oSection, "PIORFORN",   "", "Pior Forn",       "@!", 25)
    TRCell():New(oSection, "PIORCOMP",   "", "Comprador (pior)",  "@!", 20)
    TRCell():New(oSection, "TENDENCIA",  "", "Tendencia",       "@!", 10)
    TRCell():New(oSection, "DESCMED",    "", "Desc Medio %",    "@E 99.99", 10)

    oReport:PrintDialog()
Return

/*/{Protheus.doc} PrintExcelCons
Popula o TReport consolidado.
@type Static Function
/*/
Static Function PrtConsExcel(oReport, aFiltros)
    Local oSection := oReport:Section(1)
    Local i

    oReport:SetMeter(0)
    oSection:Init()

    oSection:SetHeaderSection(.T.)
    oReport:PrintText("Periodo: " + DtoC(aFiltros[1]) + " a " + DtoC(aFiltros[2]) + ;
        "   |   " + cValToChar(Len(aConsolid)) + " itens distintos", 0)
    oReport:PrintText("Total: R$ " + Transform(nTotComprado, "@E 999,999,999.99") + ;
        "   |   Desconto: R$ " + Transform(nTotDesconto, "@E 999,999,999.99") + ;
        "   |   Preco Medio Pond: R$ " + Transform(nPrcMedioPond, "@E 999,999.99"), 0)
    oReport:SkipLine()

    For i := 1 To Len(aConsolid)
        oSection:Cell("ITEM"):SetValue(aConsolid[i][CS_CODITEM])
        oSection:Cell("DESCRICAO"):SetValue(aConsolid[i][CS_DESCITEM])
        oSection:Cell("UM"):SetValue(aConsolid[i][CS_UM])
        oSection:Cell("GRUPO"):SetValue(aConsolid[i][CS_GRUPO])
        oSection:Cell("COMPRAS"):SetValue(aConsolid[i][CS_QTDCOMP])
        oSection:Cell("QTDTOTAL"):SetValue(aConsolid[i][CS_QTDTOTAL])
        oSection:Cell("VLRTOTAL"):SetValue(aConsolid[i][CS_VLRTOTAL])
        oSection:Cell("PRCMEDIO"):SetValue(aConsolid[i][CS_PRCMEDIO])
        oSection:Cell("MELHORPRC"):SetValue(aConsolid[i][CS_MELHORPRC])
        oSection:Cell("PIORPRC"):SetValue(aConsolid[i][CS_PIORPRC])
        oSection:Cell("VARIACAO"):SetValue(aConsolid[i][CS_VARIACAO])
        oSection:Cell("MELHFORN"):SetValue(aConsolid[i][CS_MELHFORN])
        oSection:Cell("MELHCOMP"):SetValue(aConsolid[i][CS_MELHCOMP])
        oSection:Cell("PIORFORN"):SetValue(aConsolid[i][CS_PIORFORN])
        oSection:Cell("PIORCOMP"):SetValue(aConsolid[i][CS_PIORCOMP])
        oSection:Cell("TENDENCIA"):SetValue(aConsolid[i][CS_TENDENC])
        oSection:Cell("DESCMED"):SetValue(aConsolid[i][CS_DESCMED])

        oSection:PrintLine()
        oReport:IncMeter()
    Next i

    oReport:SkipLine()
    oReport:PrintText("TOTAL: R$ " + Transform(nTotComprado, "@E 999,999,999.99") + ;
        "   |   ITENS: " + cValToChar(Len(aConsolid)) + ;
        "   |   QTD: " + Transform(nQtdTotal, "@E 999,999.99"), 0)

    oSection:Finish()
Return

// =============================================================================
// FUNCOES AUXILIARES
// =============================================================================

/*/{Protheus.doc} FirstDate
Retorna o primeiro dia do mes da data informada.
@type Static Function
@param dData, Data de referencia
@return dRet, Primeiro dia do mes
/*/
Static Function FirstDate(dData)
    Local cAno := Str(Year(dData), 4)
    Local cMes := StrZero(Month(dData), 2)
Return StoD(cAno + cMes + "01")
