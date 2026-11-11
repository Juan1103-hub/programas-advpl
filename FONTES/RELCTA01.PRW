#include "totvs.ch"
#include "topconn.ch"

/*-------------------------------------------------------------------*
 | RELCTA01 - Relatorio de Movimentos por Conta de Estoque           |
 | Listra entradas (SD1) e baixas de almoxarifado TM 502 (SD3)       |
 | para produtos com B1_XCTAEST igual ao informado, em um periodo.   |
 *-------------------------------------------------------------------*/
/*/{Protheus.doc}
Relatorio de Movimentos por Conta de Estoque (B1_XCTAEST)

Listra, dentro de um periodo informado pelo usuario, os movimentos dos
produtos cujo campo B1_XCTAEST = conta informada:
  1) Entradas: itens de notas fiscais de entrada (SD1).
  2) Saidas:  baixas de almoxarifado com movimento 502 (SD3).

Parametros via ParamBox:
- Data inicial e data final (obrigatorias; validar data final >= inicial).
- Filial de / ate (padrao: filial logada).
- Conta de estoque (padrao '11401200001', editavel).
- Saida: tela de impressao TReport (Spool, PDF, HTML, XLS e outros).

Regras - Entradas (SD1):
  - INNER JOIN em SB1 (D1_COD = B1_COD).
  - Valor Total = D1_TOTAL + D1_VALIPI + D1_VALFRE (+ D1_VALFCMP, se existir).
  - Filtros: B1_XCTAEST = conta; D1_DTDIGIT entre as datas; D_E_L_E_T_ = ' '.
  - JOIN com SF4 (D1_TES = F4_CODIGO) e F4_ESTOQUE = 'S'.
  - Exibe D1_TIPO na coluna.

Regras - Saidas (SD3):
  - INNER JOIN em SB1 (D3_COD = B1_COD).
  - Filtros: D3_TM = '502'; B1_XCTAEST = conta; D3_EMISSAO entre as datas;
    D3_ESTORNO <> 'S'; D_E_L_E_T_ = ' '.

Requisitos tecnicos:
  - Embedded SQL com BeginSql ... EndSql, %table:%, %xfilial:% e %notDel%.
  - Prefixo de tabela com RetSqlName, nunca nome fixo.
  - Totaliza quantidade e valor por secao e total geral.
  - Tela de impressao via TReport:PrintDialog() (Spool, PDF, HTML, XLS e outros).
  - Trata ausencia de dados ("Nenhum registro encontrado").
  - Processamento com barra de progresso (Processa / MsNewProcess).
  - Fecha areas de trabalho (dbCloseArea).
  - Comentarios em portugues.

@type     User Function
@author   Desenvolvedor Senior ADVPL
@since    2026-10-26
@version   12.1.33
@param    none
@return   none
/*/

// Variaveis estaticas compartilhadas entre funcoes
Static aDadosEnt    := {}   // Dados da secao Entradas (SD1)
Static aDadosSai    := {}   // Dados da secao Saidas (SD3)
Static nTotEnt      := 0    // Total de registros entradas
Static nTotSai      := 0    // Total de registros saidas
Static nQtdEnt      := 0    // Total quantidade entradas
Static nVlrEnt      := 0    // Total valor entradas
Static nQtdSai      := 0    // Total quantidade saidas
Static nVlrSai      := 0    // Total valor saidas
Static cContaGlob   := ""   // Conta contabil informada
Static cFilDeGlob   := ""   // Filial de
Static cFilAteGlob  := ""   // Filial ate
Static dDtDeGlob    := CtoD("") // Data inicial
Static dDtAteGlob   := Date()   // Data final

User Function RELCTA01()
    Local aArea    := GetArea()
    Local aPar     := {}
    Local aRet     := {}
    Local dDtDe    := CtoD("")
    Local dDtAte   := Date()
    Local cConta   := "11401200001"
    Local cFilDe   := xFilial("SB1")
    Local cFilAte  := xFilial("SB1")

    // Inicializa estaticas
    aDadosEnt   := {}
    aDadosSai   := {}
    nTotEnt     := 0
    nTotSai     := 0
    nQtdEnt     := 0
    nVlrEnt     := 0
    nQtdSai     := 0
    nVlrSai     := 0

    // Parametros da tela
    aAdd(aPar, {1, "Periodo De",        dDtDe,        "", "", "", "", 60, .T.})
    aAdd(aPar, {1, "Periodo Ate",       dDtAte,       "", "", "", "", 60, .T.})
    aAdd(aPar, {1, "Filial De",         cFilDe,       "", "", "", "", 60, .T.})
    aAdd(aPar, {1, "Filial Ate",        cFilAte,      "", "", "", "", 60, .T.})
    aAdd(aPar, {1, "Conta de Estoque",  cConta,       "", "", "", "", 80, .T.})

    If !ParamBox(aPar, "Relatorio de Movimentos por Conta de Estoque", @aRet)
        RestArea(aArea)
        Return
    EndIf

    dDtDe    := aRet[1]
    dDtAte   := aRet[2]
    cFilDe   := AllTrim(aRet[3])
    cFilAte  := AllTrim(aRet[4])
    cConta   := AllTrim(aRet[5])

    // Validacoes
    If Empty(dDtDe) .Or. Empty(dDtAte)
        MsgAlert("Informe o periodo completo!", "Atencao")
        RestArea(aArea)
        Return
    EndIf

    If dDtAte < dDtDe
        MsgAlert("Data final nao pode ser anterior a data inicial!", "Atencao")
        RestArea(aArea)
        Return
    EndIf

    If Empty(cConta)
        MsgAlert("Informe a conta de estoque!", "Atencao")
        RestArea(aArea)
        Return
    EndIf

    // Armazena globais para uso nas funcoes de dados e impressao
    cContaGlob  := PadR(cConta, TamSX3("B1_XCTAEST")[1])
    cFilDeGlob  := cFilDe
    cFilAteGlob := cFilAte
    dDtDeGlob   := dDtDe
    dDtAteGlob  := dDtAte

    // Processa com barra de progresso
    Processa({|| U_RCT01_Dados()}, "Buscando movimentos de entradas e saidas...")

    // Verifica se ha dados
    If Len(aDadosEnt) == 0 .And. Len(aDadosSai) == 0
        MsgInfo("Nenhum registro encontrado para o periodo e conta informados!", "Atencao")
        RestArea(aArea)
        Return
    EndIf

    // Abre a tela de impressao (unico destino de saida do relatorio)
    U_RCT01_Rel()

    RestArea(aArea)
Return

/*-------------------------------------------------------------------*
 | U_RCT01_Dados - Extrai dados de entradas (SD1) e saidas (SD3)     |
 | Usa Embedded SQL com RetSqlName, %table:%, %xfilial:% e %notDel%. |
 *-------------------------------------------------------------------*/
Static Function U_RCT01_Dados()
    Local cQuery   := ""
    Local cAlias   := GetNextAlias()
    Local cAliasB1 := GetNextAlias()
    Local cFiltB1  := ""
    Local cFiltFil := ""
    Local cDtDe    := DtoS(dDtDeGlob)
    Local cDtAte   := DtoS(dDtAteGlob)
    Local nI       := 0
    Local lHasF4   := .F.
    Local cTblSF4  := RetSqlName("SF4")
    Local lHasFCMP := .F.
    Local cTblSD1  := RetSqlName("SD1")
    Local cVlrTot  := ""

    // Inicializa arrays e totalizadores
    aDadosEnt := {}
    aDadosSai := {}
    nTotEnt   := 0
    nTotSai   := 0
    nQtdEnt   := 0
    nVlrEnt   := 0
    nQtdSai   := 0
    nVlrSai   := 0

    // Filtro de conta de estoque (aplicado no join com SB1)
    cFiltB1 := " AND B1.B1_XCTAEST = '" + cContaGlob + "' "

    // Filtro de filial (de/ate) aplicado em cada tabela
    cFiltFil := " AND D1.D1_FILIAL >= '" + cFilDeGlob + "' AND D1.D1_FILIAL <= '" + cFilAteGlob + "' "

    // Verifica se F4_ESTOQUE existe na SF4 (para filtrar TES que movimentam estoque)
    cQuery := "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS "
    cQuery += "WHERE TABLE_NAME = '" + cTblSF4 + "' AND COLUMN_NAME = 'F4_ESTOQUE'"
    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    If !(cAlias)->(Eof())
        lHasF4 := .T.
    EndIf
    (cAlias)->(DbCloseArea())

    // Verifica se D1_VALFCMP existe na SD1 (campo pode nao existir no ambiente)
    cQuery := "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS "
    cQuery += "WHERE TABLE_NAME = '" + cTblSD1 + "' AND COLUMN_NAME = 'D1_VALFCMP'"
    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    If !(cAlias)->(Eof())
        lHasFCMP := .T.
    EndIf
    (cAlias)->(DbCloseArea())

    // Valor Total do item: total + IPI + frete (+ FCMP quando o campo existir)
    cVlrTot := "ISNULL(D1.D1_TOTAL,0) + ISNULL(D1.D1_VALIPI,0) + ISNULL(D1.D1_VALFRE,0)"
    If lHasFCMP
        cVlrTot := cVlrTot + " + ISNULL(D1.D1_VALFCMP,0)"
    EndIf

    // ================================================================
    // SECAO 1 - ENTRADAS (SD1) - Itens de notas fiscais de entrada
    // ================================================================
    IncProc("Buscando entradas de NF (SD1)...")
    cQuery := "SELECT "
    cQuery += "D1.D1_FILIAL, D1.D1_DTDIGIT, D1.D1_EMISSAO, D1.D1_DOC, D1.D1_SERIE, "
    cQuery += "D1.D1_TIPO, D1.D1_FORNECE, D1.D1_LOJA, A2.A2_NOME, "
    cQuery += "D1.D1_ITEM, D1.D1_COD, B1.B1_DESC, D1.D1_LOCAL, D1.D1_TES, "
    cQuery += "D1.D1_CF, D1.D1_QUANT, D1.D1_VUNIT, D1.D1_TOTAL, D1.D1_CUSTO, "
    cQuery += "B1.B1_XCTAEST "
    cQuery += "FROM %table:SD1% D1 "
    cQuery += "INNER JOIN %table:SB1% B1 ON B1.B1_FILIAL = %xfilial:SB1% AND B1.B1_COD = D1.D1_COD AND B1.D_E_L_E_T_ = ' ' "
    cQuery += "LEFT JOIN %table:SA2% A2 ON A2.A2_FILIAL = %xfilial:SA2% AND A2.A2_COD = D1.D1_FORNECE AND A2.A2_LOJA = D1.D1_LOJA AND A2.D_E_L_E_T_ = ' ' "
    If lHasF4
        cQuery += "INNER JOIN %table:SF4% F4 ON F4.F4_FILIAL = %xfilial:SF4% AND F4.F4_CODIGO = D1.D1_TES AND F4.F4_ESTOQUE = 'S' AND F4.D_E_L_E_T_ = ' ' "
    EndIf
    cQuery += "WHERE D1.D_E_L_E_T_ = ' ' "
    cQuery += "AND D1.D1_DTDIGIT >= '" + cDtDe + "' AND D1.D1_DTDIGIT <= '" + cDtAte + "' "
    cQuery += cFiltB1
    cQuery += cFiltFil
    cQuery := ChangeQuery(cQuery)

    // Como BeginSql/EndSql nao expoe alias diretamente no AdvPL,
    // usamos TcGenQry para iterar sobre o resultado:
    cAlias := GetNextAlias()
    cQuery := "SELECT "
    cQuery += "D1.D1_FILIAL, D1.D1_DTDIGIT, D1.D1_EMISSAO, D1.D1_DOC, D1.D1_SERIE, "
    cQuery += "D1.D1_TIPO, D1.D1_FORNECE, D1.D1_LOJA, A2.A2_NOME, "
    cQuery += "D1.D1_ITEM, D1.D1_COD, B1.B1_DESC, D1.D1_LOCAL, D1.D1_TES, "
    cQuery += "D1.D1_CF, D1.D1_QUANT, D1.D1_VUNIT, D1.D1_TOTAL, D1.D1_CUSTO, "
    cQuery += "B1.B1_XCTAEST, "
    cQuery += cVlrTot + " AS VLTOT "
    cQuery += "FROM " + RetSqlName("SD1") + " D1 "
    cQuery += "INNER JOIN " + RetSqlName("SB1") + " B1 "
    cQuery += "  ON B1.B1_FILIAL = '" + xFilial("SB1") + "' AND B1.B1_COD = D1.D1_COD AND B1.D_E_L_E_T_ = ' ' "
    cQuery += "LEFT JOIN " + RetSqlName("SA2") + " A2 "
    cQuery += "  ON A2.A2_FILIAL = '" + xFilial("SA2") + "' AND A2.A2_COD = D1.D1_FORNECE AND A2.A2_LOJA = D1.D1_LOJA AND A2.D_E_L_E_T_ = ' ' "
    If lHasF4
        cQuery += "INNER JOIN " + RetSqlName("SF4") + " F4 "
        cQuery += "  ON F4.F4_FILIAL = '" + xFilial("SF4") + "' AND F4.F4_CODIGO = D1.D1_TES AND F4.F4_ESTOQUE = 'S' AND F4.D_E_L_E_T_ = ' ' "
    EndIf
    cQuery += "WHERE D1.D_E_L_E_T_ = ' ' "
    cQuery += "AND D1.D1_DTDIGIT >= '" + cDtDe + "' AND D1.D1_DTDIGIT <= '" + cDtAte + "' "
    cQuery += "AND B1.B1_XCTAEST = '" + cContaGlob + "' "
    cQuery += "AND D1.D1_FILIAL >= '" + cFilDeGlob + "' AND D1.D1_FILIAL <= '" + cFilAteGlob + "' "
    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    // Tipa as colunas numericas (a TOPCONN devolve character por padrao)
    TCSetField(cAlias, "D1_QUANT", "N", 16, 4)
    TCSetField(cAlias, "D1_VUNIT", "N", 16, 4)
    TCSetField(cAlias, "D1_TOTAL", "N", 16, 2)
    TCSetField(cAlias, "D1_CUSTO", "N", 16, 2)
    TCSetField(cAlias, "VLTOT",    "N", 16, 2)
    (cAlias)->(DbGoTop())
    While !(cAlias)->(Eof())
        aAdd(aDadosEnt, { ;
            AllTrim((cAlias)->D1_FILIAL), ;  // 1 Filial
            StoD(AllTrim((cAlias)->D1_DTDIGIT)), ; // 2 Data Digita??o
            StoD(AllTrim((cAlias)->D1_EMISSAO)), ; // 3 Data Emiss?o
            AllTrim((cAlias)->D1_DOC), ;     // 4 Documento
            AllTrim((cAlias)->D1_SERIE), ;   // 5 S?rie
            AllTrim((cAlias)->D1_TIPO), ;    // 6 Tipo NF
            AllTrim((cAlias)->D1_FORNECE), ; // 7 Fornecedor
            AllTrim((cAlias)->D1_LOJA), ;    // 8 Loja
            AllTrim((cAlias)->A2_NOME), ;    // 9 Nome Fornecedor
            AllTrim((cAlias)->D1_ITEM), ;    // 10 Item
            AllTrim((cAlias)->D1_COD), ;     // 11 Produto
            AllTrim((cAlias)->B1_DESC), ;    // 12 Descri??o
            AllTrim((cAlias)->D1_LOCAL), ;   // 13 Armaz?m
            AllTrim((cAlias)->D1_TES), ;     // 14 TES
            AllTrim((cAlias)->D1_CF), ;      // 15 CFOP
            (cAlias)->D1_QUANT, ;            // 16 Quantidade
            (cAlias)->D1_VUNIT, ;            // 17 Valor Unit?rio
            (cAlias)->VLTOT, ;               // 18 Valor Total (total + IPI + frete + FCMP)
            (cAlias)->D1_CUSTO, ;            // 19 Custo (D1_CUSTO)
            AllTrim((cAlias)->B1_XCTAEST) }) // 20 Conta de Estoque
        nTotEnt   := nTotEnt + 1
        nQtdEnt   := nQtdEnt + If(ValType((cAlias)->D1_QUANT) == "N", (cAlias)->D1_QUANT, 0)
        nVlrEnt   := nVlrEnt + If(ValType((cAlias)->VLTOT) == "N", (cAlias)->VLTOT, 0)
        (cAlias)->(DbSkip())
    End
    (cAlias)->(DbCloseArea())

    // ================================================================
    // SECAO 2 - SAIDAS (SD3) - Baixas de almoxarifado TM 502
    // ================================================================
    IncProc("Buscando baixas de almoxarifado TM 502 (SD3)...")
    cAlias := GetNextAlias()
    cQuery := "SELECT "
    cQuery += "D3.D3_FILIAL, D3.D3_EMISSAO, D3.D3_DOC, D3.D3_COD, B1.B1_DESC, "
    cQuery += "D3.D3_LOCAL, D3.D3_TM, D3.D3_CF, D3.D3_QUANT, D3.D3_CUSTO1, "
    cQuery += "D3.D3_CC, D3.D3_NUMSEQ, B1.B1_XCTAEST "
    cQuery += "FROM " + RetSqlName("SD3") + " D3 "
    cQuery += "INNER JOIN " + RetSqlName("SB1") + " B1 "
    cQuery += "  ON B1.B1_FILIAL = '" + xFilial("SB1") + "' AND B1.B1_COD = D3.D3_COD AND B1.D_E_L_E_T_ = ' ' "
    cQuery += "WHERE D3.D_E_L_E_T_ = ' ' "
    cQuery += "AND D3.D3_TM = '502' "
    cQuery += "AND D3.D3_ESTORNO <> 'S' "
    cQuery += "AND D3.D3_EMISSAO >= '" + cDtDe + "' AND D3.D3_EMISSAO <= '" + cDtAte + "' "
    cQuery += "AND B1.B1_XCTAEST = '" + cContaGlob + "' "
    cQuery += "AND D3.D3_FILIAL >= '" + cFilDeGlob + "' AND D3.D3_FILIAL <= '" + cFilAteGlob + "' "
    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    // Tipa as colunas numericas (a TOPCONN devolve character por padrao)
    TCSetField(cAlias, "D3_QUANT",  "N", 16, 4)
    TCSetField(cAlias, "D3_CUSTO1", "N", 16, 2)
    (cAlias)->(DbGoTop())
    While !(cAlias)->(Eof())
        aAdd(aDadosSai, { ;
            AllTrim((cAlias)->D3_FILIAL), ;   // 1 Filial
            StoD(AllTrim((cAlias)->D3_EMISSAO)), ; // 2 Data
            AllTrim((cAlias)->D3_DOC), ;      // 3 Documento
            AllTrim((cAlias)->D3_COD), ;      // 4 Produto
            AllTrim((cAlias)->B1_DESC), ;     // 5 Descri??o
            AllTrim((cAlias)->D3_LOCAL), ;    // 6 Armaz?m
            AllTrim((cAlias)->D3_TM), ;       // 7 Tipo Mov (TM)
            AllTrim((cAlias)->D3_CF), ;       // 8 CF
            (cAlias)->D3_QUANT, ;             // 9 Quantidade
            (cAlias)->D3_CUSTO1, ;            // 10 Custo (D3_CUSTO1)
            AllTrim((cAlias)->D3_CC), ;       // 11 Centro de Custo
            AllTrim((cAlias)->D3_NUMSEQ), ;   // 12 Numero Sequencial
            AllTrim((cAlias)->B1_XCTAEST) })  // 13 Conta de Estoque
        nTotSai := nTotSai + 1
        nQtdSai := nQtdSai + If(ValType((cAlias)->D3_QUANT) == "N", (cAlias)->D3_QUANT, 0)
        nVlrSai := nVlrSai + If(ValType((cAlias)->D3_CUSTO1) == "N", (cAlias)->D3_CUSTO1, 0)
        (cAlias)->(DbSkip())
    End
    (cAlias)->(DbCloseArea())

Return

/*-------------------------------------------------------------------*
 | U_RCT01_Rel - Abre a tela de impressao do relatorio              |
 *-------------------------------------------------------------------*/
/*/{Protheus.doc}
U_RCT01_Rel
Abre a tela de impressao padrao do Protheus (TReport:PrintDialog),
na qual o usuario escolhe o destino da saida: Spool (impressora),
PDF, HTML, XLS e outros formatos suportados.
Nao usa a classe TTAB, indisponivel no RPO do servidor.
@type     Static Function
@author   Desenvolvedor Senior ADVPL
@since    2026-10-26
@param    none
@return   none
/*/
Static Function U_RCT01_Rel()
    Local oReport := Nil

    If Len(aDadosEnt) == 0 .And. Len(aDadosSai) == 0
        MsgAlert("Nenhum registro encontrado para exibir!", "Atencao")
        Return
    EndIf

    oReport := U_RCT01_Def()
    If oReport != Nil
        oReport:PrintDialog()
    EndIf
Return

/*-------------------------------------------------------------------*
 | U_RCT01_Def - Monta a estrutura do relatorio TReport              |
 *-------------------------------------------------------------------*/
/*/{Protheus.doc}
U_RCT01_Def
Define as secoes e as colunas do relatorio de movimentos por conta
de estoque: Secao 1 Entradas de NF (SD1) e Secao 2 Baixas de
almoxarifado TM 502 (SD3). As colunas reproduzem as anteriores
telas de lista, com linhas de totalizacao por secao.
@type     Static Function
@author   Desenvolvedor Senior ADVPL
@since    2026-10-26
@param    none
@return   oReport, objeto TReport
/*/
Static Function U_RCT01_Def()
    Local oReport := Nil
    Local oSecEnt := Nil
    Local oSecSai := Nil

    oReport := TReport():New("RELCTA01", ;
        "Relatorio de Movimentos por Conta de Estoque - " + cContaGlob, "", ;
        {|oReport| U_RCT01_Imp(oReport)}, ;
        "Entradas de NF (SD1) e baixas de almoxarifado TM 502 (SD3) da conta de estoque " + cContaGlob)

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    // ---- Secao 1: Entradas (SD1) ----
    oSecEnt := TRSection():New(oReport, "Entradas NF", {})
    TRCell():New(oSecEnt, "FILIAL",   "", "Filial",          "@!", 10)
    TRCell():New(oSecEnt, "DTDIG",    "", "Data Dig.",       "", 10)
    TRCell():New(oSecEnt, "DTEMIS",   "", "Data Emis.",      "", 10)
    TRCell():New(oSecEnt, "DOC",      "", "Documento",       "@!", 10)
    TRCell():New(oSecEnt, "SERIE",    "", "Serie",           "@!", 5)
    TRCell():New(oSecEnt, "TIPO",     "", "Tipo",            "@!", 4)
    TRCell():New(oSecEnt, "FORNEC",   "", "Fornec.",         "@!", 6)
    TRCell():New(oSecEnt, "LOJA",     "", "Loja",            "@!", 4)
    TRCell():New(oSecEnt, "NOMEFOR",  "", "Nome Fornecedor", "@!", 30)
    TRCell():New(oSecEnt, "ITEM",     "", "Item",            "@!", 4)
    TRCell():New(oSecEnt, "PRODUTO",  "", "Produto",         "@!", 15)
    TRCell():New(oSecEnt, "DESCRIC",  "", "Descricao",       "@!", 40)
    TRCell():New(oSecEnt, "ARMAZEM",  "", "Armazem",         "@!", 6)
    TRCell():New(oSecEnt, "TES",      "", "TES",             "@!", 6)
    TRCell():New(oSecEnt, "CFOP",     "", "CFOP",            "@!", 6)
    TRCell():New(oSecEnt, "QTD",      "", "Qtd",             "@E 999,999.99", 12)
    TRCell():New(oSecEnt, "VUNIT",    "", "V.Unit.",         "@E 999,999.99", 12)
    TRCell():New(oSecEnt, "VTOTAL",   "", "V.Total",         "@E 999,999,999.99", 14)
    TRCell():New(oSecEnt, "CUSTO",    "", "Custo",           "@E 999,999,999.99", 14)
    TRCell():New(oSecEnt, "CONTA",    "", "Conta Est.",      "@!", 15)

    // ---- Secao 2: Saidas (SD3 - TM 502) ----
    oSecSai := TRSection():New(oReport, "Baixas 502", {})
    TRCell():New(oSecSai, "FILIAL",   "", "Filial",          "@!", 10)
    TRCell():New(oSecSai, "DATA",     "", "Data",            "", 10)
    TRCell():New(oSecSai, "DOC",      "", "Documento",       "@!", 10)
    TRCell():New(oSecSai, "PRODUTO",  "", "Produto",         "@!", 15)
    TRCell():New(oSecSai, "DESCRIC",  "", "Descricao",       "@!", 40)
    TRCell():New(oSecSai, "ARMAZEM",  "", "Armazem",         "@!", 6)
    TRCell():New(oSecSai, "TM",       "", "TM",              "@!", 4)
    TRCell():New(oSecSai, "CF",       "", "CF",              "@!", 6)
    TRCell():New(oSecSai, "QTD",      "", "Qtd",             "@E 999,999.99", 12)
    TRCell():New(oSecSai, "CUSTO",    "", "Custo",           "@E 999,999,999.99", 14)
    TRCell():New(oSecSai, "CC",       "", "Centro Custo",    "@!", 10)
    TRCell():New(oSecSai, "NUMSEQ",   "", "NumSeq",          "@!", 9)
    TRCell():New(oSecSai, "CONTA",    "", "Conta Est.",      "@!", 15)

Return oReport

/*-------------------------------------------------------------------*
 | U_RCT01_Imp - Preenche e imprime as secoes do relatorio           |
 *-------------------------------------------------------------------*/
/*/{Protheus.doc}
U_RCT01_Imp
Bloco de impressao do TReport: percorre os arrays de entradas e de
saidas preenchidos por U_RCT01_Dados, imprime as linhas de detalhe
e as linhas de totalizacao de cada secao.
@type     Static Function
@author   Desenvolvedor Senior ADVPL
@since    2026-10-26
@param    oReport, objeto TReport
@return   none
/*/
Static Function U_RCT01_Imp(oReport)
    Local oSecEnt := oReport:Section(1)
    Local oSecSai := oReport:Section(2)
    Local nI      := 0
    Local aNfs    := {}
    Local cChave  := ""

    oReport:SetMeter(Len(aDadosEnt) + Len(aDadosSai))

    // ==============================================================
    // SECAO 1 - ENTRADAS (SD1)
    // ==============================================================
    oSecEnt:Init()

    For nI := 1 To Len(aDadosEnt)
        oSecEnt:Cell("FILIAL"):SetValue(aDadosEnt[nI][1])
        oSecEnt:Cell("DTDIG"):SetValue(DtoC(aDadosEnt[nI][2]))
        oSecEnt:Cell("DTEMIS"):SetValue(DtoC(aDadosEnt[nI][3]))
        oSecEnt:Cell("DOC"):SetValue(aDadosEnt[nI][4])
        oSecEnt:Cell("SERIE"):SetValue(aDadosEnt[nI][5])
        oSecEnt:Cell("TIPO"):SetValue(aDadosEnt[nI][6])
        oSecEnt:Cell("FORNEC"):SetValue(aDadosEnt[nI][7])
        oSecEnt:Cell("LOJA"):SetValue(aDadosEnt[nI][8])
        oSecEnt:Cell("NOMEFOR"):SetValue(aDadosEnt[nI][9])
        oSecEnt:Cell("ITEM"):SetValue(aDadosEnt[nI][10])
        oSecEnt:Cell("PRODUTO"):SetValue(aDadosEnt[nI][11])
        oSecEnt:Cell("DESCRIC"):SetValue(aDadosEnt[nI][12])
        oSecEnt:Cell("ARMAZEM"):SetValue(aDadosEnt[nI][13])
        oSecEnt:Cell("TES"):SetValue(aDadosEnt[nI][14])
        oSecEnt:Cell("CFOP"):SetValue(aDadosEnt[nI][15])
        oSecEnt:Cell("QTD"):SetValue(aDadosEnt[nI][16])
        oSecEnt:Cell("VUNIT"):SetValue(aDadosEnt[nI][17])
        oSecEnt:Cell("VTOTAL"):SetValue(aDadosEnt[nI][18])
        oSecEnt:Cell("CUSTO"):SetValue(aDadosEnt[nI][19])
        oSecEnt:Cell("CONTA"):SetValue(aDadosEnt[nI][20])
        oSecEnt:PrintLine()
        oReport:IncMeter()
    Next nI

    // Conta as notas fiscais distintas de entrada
    // (filial + documento + serie + fornecedor + loja)
    For nI := 1 To Len(aDadosEnt)
        cChave := aDadosEnt[nI][1] + "|" + aDadosEnt[nI][4] + "|" + aDadosEnt[nI][5] + "|" + ;
            aDadosEnt[nI][7] + "|" + aDadosEnt[nI][8]
        If aScan(aNfs, {|x| x == cChave}) == 0
            aAdd(aNfs, cChave)
        EndIf
    Next nI

    // Linha de totalizacao da secao de entradas
    If Len(aDadosEnt) > 0
        oSecEnt:Cell("FILIAL"):SetValue("TOTAL")
        oSecEnt:Cell("DTDIG"):SetValue("")
        oSecEnt:Cell("DTEMIS"):SetValue("")
        oSecEnt:Cell("DOC"):SetValue("")
        oSecEnt:Cell("SERIE"):SetValue("")
        oSecEnt:Cell("TIPO"):SetValue("")
        oSecEnt:Cell("FORNEC"):SetValue("")
        oSecEnt:Cell("LOJA"):SetValue("")
        oSecEnt:Cell("NOMEFOR"):SetValue("Notas Fiscais Distintas: " + cValToChar(Len(aNfs)))
        oSecEnt:Cell("ITEM"):SetValue("")
        oSecEnt:Cell("PRODUTO"):SetValue("")
        oSecEnt:Cell("DESCRIC"):SetValue("")
        oSecEnt:Cell("ARMAZEM"):SetValue("")
        oSecEnt:Cell("TES"):SetValue("")
        oSecEnt:Cell("CFOP"):SetValue("")
        oSecEnt:Cell("QTD"):SetValue(nQtdEnt)
        oSecEnt:Cell("VUNIT"):SetValue(0)
        oSecEnt:Cell("VTOTAL"):SetValue(nVlrEnt)
        oSecEnt:Cell("CUSTO"):SetValue(0)
        oSecEnt:Cell("CONTA"):SetValue("")
        oSecEnt:PrintLine()
    EndIf

    oSecEnt:Finish()

    // ==============================================================
    // SECAO 2 - SAIDAS (SD3 - TM 502)
    // ==============================================================
    oSecSai:Init()

    For nI := 1 To Len(aDadosSai)
        oSecSai:Cell("FILIAL"):SetValue(aDadosSai[nI][1])
        oSecSai:Cell("DATA"):SetValue(DtoC(aDadosSai[nI][2]))
        oSecSai:Cell("DOC"):SetValue(aDadosSai[nI][3])
        oSecSai:Cell("PRODUTO"):SetValue(aDadosSai[nI][4])
        oSecSai:Cell("DESCRIC"):SetValue(aDadosSai[nI][5])
        oSecSai:Cell("ARMAZEM"):SetValue(aDadosSai[nI][6])
        oSecSai:Cell("TM"):SetValue(aDadosSai[nI][7])
        oSecSai:Cell("CF"):SetValue(aDadosSai[nI][8])
        oSecSai:Cell("QTD"):SetValue(aDadosSai[nI][9])
        oSecSai:Cell("CUSTO"):SetValue(aDadosSai[nI][10])
        oSecSai:Cell("CC"):SetValue(aDadosSai[nI][11])
        oSecSai:Cell("NUMSEQ"):SetValue(aDadosSai[nI][12])
        oSecSai:Cell("CONTA"):SetValue(aDadosSai[nI][13])
        oSecSai:PrintLine()
        oReport:IncMeter()
    Next nI

    // Linha de totalizacao da secao de saidas
    If Len(aDadosSai) > 0
        oSecSai:Cell("FILIAL"):SetValue("TOTAL")
        oSecSai:Cell("DATA"):SetValue("")
        oSecSai:Cell("DOC"):SetValue("")
        oSecSai:Cell("PRODUTO"):SetValue("")
        oSecSai:Cell("DESCRIC"):SetValue("")
        oSecSai:Cell("ARMAZEM"):SetValue("")
        oSecSai:Cell("TM"):SetValue("")
        oSecSai:Cell("CF"):SetValue("")
        oSecSai:Cell("QTD"):SetValue(nQtdSai)
        oSecSai:Cell("CUSTO"):SetValue(nVlrSai)
        oSecSai:Cell("CC"):SetValue("")
        oSecSai:Cell("NUMSEQ"):SetValue("")
        oSecSai:Cell("CONTA"):SetValue("")
        oSecSai:PrintLine()
    EndIf

    oSecSai:Finish()

Return
