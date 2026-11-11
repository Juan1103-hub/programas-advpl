#Include "totvs.ch"
#Include "topconn.ch"

// Arrays estaticos das duas abas da planilha
Static aEntradas := {}
Static aSaidas   := {}

/*/{Protheus.doc} ZMOVMES
Relatorio de movimentacao de estoque por periodo com exportacao para
planilha Excel de duas abas:

 - Entradas (aba 1): itens que entraram no estoque no periodo, lidos da SD1
   pela data de digitacao da nota fiscal (D1_DTDIGIT), considerando apenas
   TES que atualizam estoque (SF4.F4_ESTOQUE = 'S', com fallback por CFOP
   1/2/3 quando a coluna nao existe no dicionario do cliente).
 - Baixas (aba 2): itens baixados no periodo pela SD3 pelo tipo de movimento
   (D3_TM), padrao 502, ignorando estornos (D3_ESTORNO = ' ').

A tela de periodo permite definir data inicial, data final, armazem,
codigo do movimento de baixa e se as demais filiais da empresa entram
na apuracao (padrao: somente a filial corrente via xFilial).

Padroes do repositorio adotados (base):
 - FONTES/ZSLDEST.PRW:577-592  -> query SD1 por D1_DTDIGIT + SF4.F4_ESTOQUE
 - FONTES/ZSLDEST.PRW:545-558  -> baixas por SD3 (D3_TM / D3_ESTORNO)
 - FONTES/ZSLDEST.PRW:1615-1643-> exportacao FWMSExcel com AddWorkSheet
 - FONTES/ZSLDEST.PRW:60-101   -> tela de periodo e validacoes

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   22/10/2026
@return  Nil
/*/
User Function ZMOVMES()

    Local aArea    := GetArea()
    Local dDtDe    := Date() - Day(Date()) + 1
    Local dDtAte   := Date()
    Local cArmazem := Space(2)
    Local cMov     := "502"
    Local lTodas   := .F.
    Local lGerar   := .F.

    aEntradas := {}
    aSaidas   := {}

    lGerar := ZMOV_Tela(@dDtDe, @dDtAte, @cArmazem, @cMov, @lTodas)

    If lGerar .And. (Empty(dDtDe) .Or. Empty(dDtAte))
        MsgAlert("Informe o periodo completo: data inicial e data final.", "Atencao")
        lGerar := .F.
    EndIf

    If lGerar .And. dDtAte < dDtDe
        MsgAlert("A data final nao pode ser anterior a data inicial.", "Atencao")
        lGerar := .F.
    EndIf

    If lGerar .And. Empty(AllTrim(cMov))
        MsgAlert("Informe o tipo de movimento das baixas (exemplo: 502).", "Atencao")
        lGerar := .F.
    EndIf

    // CA2050: conteudo digitado validado antes de entrar na query (anti-injection)
    If lGerar .And. !ZMOV_VldTxt(AllTrim(cMov), "tipo de movimento")
        lGerar := .F.
    EndIf

    If lGerar .And. !Empty(AllTrim(cArmazem)) .And. ;
        !ZMOV_VldTxt(AllTrim(cArmazem), "armazem")
        lGerar := .F.
    EndIf

    If lGerar
        Processa({|| ZMOV_Dados(dDtDe, dDtAte, cArmazem, cMov, lTodas)}, ;
            "Lendo movimentacao de estoque...")

        If Len(aEntradas) == 0 .And. Len(aSaidas) == 0
            MsgInfo("Nenhum movimento encontrado para o periodo informado.", ;
                "Movimentacao de Estoque")
        Else
            ZMOV_Excel(dDtDe, dDtAte, cArmazem, cMov, lTodas)
        EndIf
    EndIf

    // Libera os arrays estaticos apos a geracao da planilha
    aEntradas := {}
    aSaidas   := {}

    RestArea(aArea)

Return

/*/{Protheus.doc} ZMOV_Tela
Tela de selecao dos filtros do relatorio: periodo, armazem, tipo de
movimento de baixa e abrangencia de filiais.

@param  dDtDe   Data inicial do periodo (por referencia)
@param  dDtAte  Data final do periodo (por referencia)
@param  cArmazem Armazem do filtro, em branco = todos (por referencia)
@param  cMov    Codigo do tipo de movimento de baixa (por referencia)
@param  lTodas  Se considera todas as filiais da empresa (por referencia)
@type   Static Function
@version 12.1.33
@author Suprimentos
@since  22/10/2026
@return Logico .T. quando o usuario confirmar a geracao
/*/
Static Function ZMOV_Tela(dDtDe, dDtAte, cArmazem, cMov, lTodas)

    Local lOk   := .F.
    Local oDlg  := Nil
    Local oSay1 := Nil
    Local oSay2 := Nil
    Local oSay3 := Nil
    Local oSay4 := Nil
    Local oGet1 := Nil
    Local oGet2 := Nil
    Local oGet3 := Nil
    Local oGet4 := Nil
    Local oChk1 := Nil
    Local oBtn1 := Nil
    Local oBtn2 := Nil

    Define MSDialog oDlg From 0, 0 To 190, 420 Pixel ;
        Title "Movimentacao de Estoque - Entradas e Baixas"

    @ 014, 010 Say oSay1 Prompt "Periodo De" Of oDlg Pixel
    @ 012, 075 MSGET oGet1 Var dDtDe PICTURE "99/99/9999" ;
        SIZE 065, 010 OF oDlg PIXEL

    @ 036, 010 Say oSay2 Prompt "Periodo Ate" Of oDlg Pixel
    @ 034, 075 MSGET oGet2 Var dDtAte PICTURE "99/99/9999" ;
        SIZE 065, 010 OF oDlg PIXEL

    @ 058, 010 Say oSay3 Prompt "Armazem (vazio = todos)" Of oDlg Pixel
    @ 056, 170 MSGET oGet3 Var cArmazem PICTURE "@!" ;
        SIZE 030, 010 OF oDlg PIXEL

    @ 080, 010 Say oSay4 Prompt "Movimento de baixa (tipo de movimento SD3)" ;
        Of oDlg Pixel
    @ 078, 260 MSGET oGet4 Var cMov PICTURE "@!" ;
        SIZE 030, 010 OF oDlg PIXEL

    @ 104, 010 CHECKBOX oChk1 Var lTodas ;
        PROMPT "Considerar todas as filiais da empresa" ;
        SIZE 220, 010 OF oDlg PIXEL

    @ 135, 120 BUTTON oBtn1 PROMPT "Gerar Planilha" SIZE 090, 016 ;
        OF oDlg PIXEL ACTION {|| lOk := .T., oDlg:End() }

    @ 135, 225 BUTTON oBtn2 PROMPT "Fechar" SIZE 060, 016 ;
        OF oDlg PIXEL ACTION {|| lOk := .F., oDlg:End() }

    Activate MSDialog oDlg Centered

Return lOk

/*/{Protheus.doc} ZMOV_Dados
Carrega os dois arrays das abas da planilha (entradas SD1 e baixas SD3)
dentro da barra de progresso da tela.

@param dDtDe    Data inicial do periodo
@param dDtAte   Data final do periodo
@param cArmazem Armazem do filtro, em branco = todos
@param cMov     Codigo do tipo de movimento de baixa
@param lTodas   Se considera todas as filiais da empresa
@type   Static Function
@version 12.1.33
@author Suprimentos
@since  22/10/2026
@return Nil
/*/
Static Function ZMOV_Dados(dDtDe, dDtAte, cArmazem, cMov, lTodas)

    Local aArea    := GetArea()
    Local cAlias   := GetNextAlias()
    Local cQuery   := ""
    Local lF4Est   := ZMOV_F4Est()
    Local nQuant   := 0
    Local nCusto   := 0
    Local nUnit    := 0

    IncProc("Buscando entradas do periodo (SD1)...")

    cQuery := " SELECT D1.D1_DTDIGIT AS DT, D1.D1_DOC AS DOC, D1.D1_SERIE AS SERIE, "
    cQuery += "        D1.D1_FORNECE AS FORNECE, D1.D1_LOJA AS LOJA, A2.A2_NOME AS NOME, "
    cQuery += "        D1.D1_COD AS COD, B1.B1_DESC AS DESCR, D1.D1_LOCAL AS LOC, D1.D1_QUANT AS QUANT, "
    cQuery += "        D1.D1_VUNIT AS VUNIT, D1.D1_TOTAL AS VLTOT, D1.D1_TES AS TES, "
    cQuery += "        D1.D1_CF AS CF "
    cQuery += "   FROM " + RetSqlName("SD1") + " D1 WITH (NOLOCK) "
    If lF4Est
        cQuery += "  INNER JOIN " + RetSqlName("SF4") + " F4 WITH (NOLOCK) "
        cQuery += "          ON " + ZMOV_CondFil("SF4", "F4.F4_FILIAL", "D1.D1_FILIAL") + " "
        cQuery += "         AND F4.F4_CODIGO = D1.D1_TES "
        cQuery += "         AND F4.F4_ESTOQUE = 'S' "
        cQuery += "         AND F4.D_E_L_E_T_ = ' ' "
    EndIf
    cQuery += "   LEFT JOIN " + RetSqlName("SA2") + " A2 WITH (NOLOCK) "
    cQuery += "          ON " + ZMOV_CondFil("SA2", "A2.A2_FILIAL", "D1.D1_FILIAL") + " "
    cQuery += "         AND A2.A2_COD = D1.D1_FORNECE "
    cQuery += "         AND A2.A2_LOJA = D1.D1_LOJA "
    cQuery += "         AND A2.D_E_L_E_T_ = ' ' "
    cQuery += "   LEFT JOIN " + RetSqlName("SB1") + " B1 WITH (NOLOCK) "
    cQuery += "          ON " + ZMOV_CondFil("SB1", "B1.B1_FILIAL", "D1.D1_FILIAL") + " "
    cQuery += "         AND B1.B1_COD = D1.D1_COD "
    cQuery += "         AND B1.D_E_L_E_T_ = ' ' "
    cQuery += "  WHERE D1.D_E_L_E_T_ = ' ' "
    cQuery += "    AND D1.D1_DTDIGIT >= '" + DtoS(dDtDe) + "' "
    cQuery += "    AND D1.D1_DTDIGIT <= '" + DtoS(dDtAte) + "' "
    If !lTodas
        cQuery += "    AND D1.D1_FILIAL = '" + xFilial("SD1") + "' "
    EndIf
    If !Empty(AllTrim(cArmazem))
        cQuery += "    AND D1.D1_LOCAL = '" + AllTrim(cArmazem) + "' "
    EndIf
    If !lF4Est
        // Fallback quando a TES nao tem a coluna F4_ESTOQUE no banco
        cQuery += "    AND LEFT(D1.D1_CF, 1) IN ('1', '2', '3') "
    EndIf
    cQuery += "  ORDER BY D1.D1_DTDIGIT, D1.D1_COD, D1.D1_DOC, D1.D1_ITEM "
    cQuery := ChangeQuery(cQuery)
    cQuery := StrTran(cQuery, "(NOLOCK)", "")              // normaliza (evita dica duplicada)
    cQuery := StrTran(cQuery, " WITH ", " WITH (NOLOCK) ") // reinjeta a dica que o ChangeQuery remove

    DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)
    TCSetField(cAlias, "DT",    "D", 8, 0)
    TCSetField(cAlias, "QUANT", "N", 16, 2)
    TCSetField(cAlias, "VUNIT", "N", 16, 4)
    TCSetField(cAlias, "VLTOT", "N", 18, 4)

    (cAlias)->(DbGoTop())
    While !(cAlias)->(Eof())
        AAdd(aEntradas, { ;
            DtoC((cAlias)->DT),          ;   // [01] Data de digitacao
            AllTrim((cAlias)->DOC),      ;   // [02] Nota fiscal
            AllTrim((cAlias)->SERIE),    ;   // [03] Serie
            AllTrim((cAlias)->FORNECE) + "/" + AllTrim((cAlias)->LOJA), ; // [04] Fornecedor
            AllTrim((cAlias)->NOME),     ;   // [05] Nome do fornecedor
            AllTrim((cAlias)->COD),      ;   // [06] Codigo do produto
            AllTrim((cAlias)->DESCR),    ;   // [07] Descricao
            (cAlias)->QUANT,             ;   // [08] Quantidade
            (cAlias)->VUNIT,             ;   // [09] Valor unitario
            (cAlias)->VLTOT,             ;   // [10] Valor total do item
            AllTrim((cAlias)->TES),      ;   // [11] TES
            AllTrim((cAlias)->CF),       ;   // [12] CFOP
            AllTrim((cAlias)->LOC)})         // [13] Armazem
        (cAlias)->(DbSkip())
    End
    (cAlias)->(DbCloseArea())

    IncProc("Buscando baixas do periodo (SD3)...")

    cQuery := " SELECT D3.D3_EMISSAO AS DT, D3.D3_DOC AS DOC, D3.D3_COD AS COD, "
    cQuery += "        B1.B1_DESC AS DESCR, D3.D3_QUANT AS QUANT, D3.D3_CUSTO1 AS CUSTO, "
    cQuery += "        D3.D3_LOCAL AS LOC, D3.D3_CF AS CF, D3.D3_CC AS CC "
    cQuery += "   FROM " + RetSqlName("SD3") + " D3 WITH (NOLOCK) "
    cQuery += "   LEFT JOIN " + RetSqlName("SB1") + " B1 WITH (NOLOCK) "
    cQuery += "          ON " + ZMOV_CondFil("SB1", "B1.B1_FILIAL", "D3.D3_FILIAL") + " "
    cQuery += "         AND B1.B1_COD = D3.D3_COD "
    cQuery += "         AND B1.D_E_L_E_T_ = ' ' "
    cQuery += "  WHERE D3.D_E_L_E_T_ = ' ' "
    cQuery += "    AND D3.D3_EMISSAO >= '" + DtoS(dDtDe) + "' "
    cQuery += "    AND D3.D3_EMISSAO <= '" + DtoS(dDtAte) + "' "
    cQuery += "    AND D3.D3_TM = '" + AllTrim(cMov) + "' "
    cQuery += "    AND D3.D3_ESTORNO = ' ' "
    If !lTodas
        cQuery += "    AND D3.D3_FILIAL = '" + xFilial("SD3") + "' "
    EndIf
    If !Empty(AllTrim(cArmazem))
        cQuery += "    AND D3.D3_LOCAL = '" + AllTrim(cArmazem) + "' "
    EndIf
    cQuery += "  ORDER BY D3.D3_EMISSAO, D3.D3_COD, D3.D3_DOC "
    cQuery := ChangeQuery(cQuery)
    cQuery := StrTran(cQuery, "(NOLOCK)", "")              // normaliza (evita dica duplicada)
    cQuery := StrTran(cQuery, " WITH ", " WITH (NOLOCK) ") // reinjeta a dica que o ChangeQuery remove

    DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)
    TCSetField(cAlias, "DT",    "D", 8, 0)
    TCSetField(cAlias, "QUANT", "N", 16, 2)
    TCSetField(cAlias, "CUSTO", "N", 18, 4)

    (cAlias)->(DbGoTop())
    While !(cAlias)->(Eof())
        nQuant := (cAlias)->QUANT
        nCusto := (cAlias)->CUSTO
        nUnit  := 0
        If nQuant != 0
            nUnit := nCusto / nQuant
        EndIf
        AAdd(aSaidas, { ;
            DtoC((cAlias)->DT),       ;   // [01] Data da movimentacao
            AllTrim((cAlias)->DOC),   ;   // [02] Documento
            AllTrim((cAlias)->COD),   ;   // [03] Codigo do produto
            AllTrim((cAlias)->DESCR), ;   // [04] Descricao
            nQuant,                   ;   // [05] Quantidade
            nUnit,                    ;   // [06] Custo unitario
            nCusto,                   ;   // [07] Valor total do movimento
            AllTrim((cAlias)->LOC),   ;   // [08] Armazem
            AllTrim((cAlias)->CF),    ;   // [09] CFOP
            AllTrim((cAlias)->CC)})       // [10] Centro de custo
        (cAlias)->(DbSkip())
    End
    (cAlias)->(DbCloseArea())

    RestArea(aArea)

Return

/*/{Protheus.doc} ZMOV_F4Est
Verifica se a coluna F4_ESTOQUE existe na TES (SF4) do banco do cliente.
Usada para decidir entre filtrar por F4_ESTOQUE = 'S' ou por CFOP 1/2/3.

@type   Static Function
@version 12.1.33
@author Suprimentos
@since  22/10/2026
@return Logico .T. quando a coluna existe
/*/
Static Function ZMOV_F4Est()

    Local lTem   := .F.
    Local aArea  := GetArea()
    Local cAlias := GetNextAlias()
    Local cQuery := ""

    cQuery := " SELECT COUNT(*) AS QTD "
    cQuery += "   FROM INFORMATION_SCHEMA.COLUMNS "
    cQuery += "  WHERE TABLE_NAME = '" + RetSqlName("SF4") + "' "
    cQuery += "    AND COLUMN_NAME = 'F4_ESTOQUE' "
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)
    If (cAlias)->QTD > 0
        lTem := .T.
    EndIf
    (cAlias)->(DbCloseArea())

    RestArea(aArea)

Return lTem

/*/{Protheus.doc} ZMOV_Excel
Monta a planilha com as duas abas (Entradas e Baixas), inclui a linha de
total de cada aba, exporta via FWMSExcel e tenta abrir no Excel.

@param dDtDe    Data inicial do periodo
@param dDtAte   Data final do periodo
@param cArmazem Armazem utilizado no filtro, em branco = todos
@param cMov     Codigo do tipo de movimento de baixa
@param lTodas   Se considera todas as filiais da empresa
@type   Static Function
@version 12.1.33
@author Suprimentos
@since  22/10/2026
@return Nil
/*/
Static Function ZMOV_Excel(dDtDe, dDtAte, cArmazem, cMov, lTodas)

    Local oExcel    := Nil
    Local oExcelApp := Nil
    Local cArquivo  := "MovEstoque_" + DtoS(Date()) + "_" + ;
        StrTran(Time(), ":", "") + ".xml"
    Local cAba1     := "Entradas"
    Local cAba2     := "Baixas"
    Local cFiltro   := ""
    Local nI        := 0
    Local nQtdEnt   := 0
    Local nVlrEnt   := 0
    Local nQtdSai   := 0
    Local nVlrSai   := 0

    oExcel := FWMSExcel():New()

    // ------------------------------------------------------------------
    // Aba 1 - Entradas (SD1)
    // ------------------------------------------------------------------
    oExcel:AddWorkSheet(cAba1)
    oExcel:AddTable(cAba1, "Entradas")

    oExcel:AddColumn(cAba1, "Entradas", "Data de Digitacao",  1, 1)
    oExcel:AddColumn(cAba1, "Entradas", "Nota Fiscal",        1, 1)
    oExcel:AddColumn(cAba1, "Entradas", "Serie",              1, 1)
    oExcel:AddColumn(cAba1, "Entradas", "Fornecedor",         1, 1)
    oExcel:AddColumn(cAba1, "Entradas", "Nome do Fornecedor", 1, 1)
    oExcel:AddColumn(cAba1, "Entradas", "Codigo",             1, 1)
    oExcel:AddColumn(cAba1, "Entradas", "Descricao",          1, 1)
    oExcel:AddColumn(cAba1, "Entradas", "Quantidade",         1, 2)
    oExcel:AddColumn(cAba1, "Entradas", "Valor Unitario",     1, 2)
    oExcel:AddColumn(cAba1, "Entradas", "Valor Total do Item", 1, 2)
    oExcel:AddColumn(cAba1, "Entradas", "TES",                1, 1)
    oExcel:AddColumn(cAba1, "Entradas", "CFOP",               1, 1)
    oExcel:AddColumn(cAba1, "Entradas", "Armazem",            1, 1)

    For nI := 1 To Len(aEntradas)
        oExcel:AddRow(cAba1, "Entradas", { ;
            aEntradas[nI][1], ;
            aEntradas[nI][2], ;
            aEntradas[nI][3], ;
            aEntradas[nI][4], ;
            aEntradas[nI][5], ;
            aEntradas[nI][6], ;
            aEntradas[nI][7], ;
            aEntradas[nI][8], ;
            aEntradas[nI][9], ;
            aEntradas[nI][10], ;
            aEntradas[nI][11], ;
            aEntradas[nI][12], ;
            aEntradas[nI][13] })
        nQtdEnt += aEntradas[nI][8]
        nVlrEnt += aEntradas[nI][10]
    Next nI

    oExcel:AddRow(cAba1, "Entradas", { ;
        "TOTAL", "", "", "", "", "", "", ;
        nQtdEnt, 0, nVlrEnt, "", "", "" })

    // ------------------------------------------------------------------
    // Aba 2 - Baixas por tipo de movimento (SD3)
    // ------------------------------------------------------------------
    oExcel:AddWorkSheet(cAba2)
    oExcel:AddTable(cAba2, "Baixas")

    oExcel:AddColumn(cAba2, "Baixas", "Data",            1, 1)
    oExcel:AddColumn(cAba2, "Baixas", "Documento",       1, 1)
    oExcel:AddColumn(cAba2, "Baixas", "Codigo",          1, 1)
    oExcel:AddColumn(cAba2, "Baixas", "Descricao",       1, 1)
    oExcel:AddColumn(cAba2, "Baixas", "Quantidade",      1, 2)
    oExcel:AddColumn(cAba2, "Baixas", "Custo Unitario",  1, 2)
    oExcel:AddColumn(cAba2, "Baixas", "Valor Total",     1, 2)
    oExcel:AddColumn(cAba2, "Baixas", "Armazem",         1, 1)
    oExcel:AddColumn(cAba2, "Baixas", "CFOP",            1, 1)
    oExcel:AddColumn(cAba2, "Baixas", "Centro de Custo", 1, 1)

    For nI := 1 To Len(aSaidas)
        oExcel:AddRow(cAba2, "Baixas", { ;
            aSaidas[nI][1], ;
            aSaidas[nI][2], ;
            aSaidas[nI][3], ;
            aSaidas[nI][4], ;
            aSaidas[nI][5], ;
            aSaidas[nI][6], ;
            aSaidas[nI][7], ;
            aSaidas[nI][8], ;
            aSaidas[nI][9], ;
            aSaidas[nI][10] })
        nQtdSai += aSaidas[nI][5]
        nVlrSai += aSaidas[nI][7]
    Next nI

    oExcel:AddRow(cAba2, "Baixas", { ;
        "TOTAL", "", "", "", ;
        nQtdSai, 0, nVlrSai, "", "", "" })

    oExcel:Activate()
    oExcel:GetXMLFile(cArquivo)

    cFiltro := "Periodo: " + DtoC(dDtDe) + " a " + DtoC(dDtAte)
    If !Empty(AllTrim(cArmazem))
        cFiltro += " | Armazem: " + AllTrim(cArmazem)
    EndIf
    cFiltro += " | Movimento de baixa: " + AllTrim(cMov)
    If lTodas
        cFiltro += " | Filiais: todas as filiais da empresa"
    Else
        cFiltro += " | Filiais: somente a filial corrente"
    EndIf

    MsgInfo("Planilha gerada com " + cValToChar(Len(aEntradas)) + ;
        " entradas e " + cValToChar(Len(aSaidas)) + " baixas." + ;
        Chr(13) + Chr(10) + cFiltro + ;
        Chr(13) + Chr(10) + "Arquivo: " + cArquivo, "Movimentacao de Estoque")

    If File(cArquivo) .And. ApOleClient("MSExcel")
        oExcelApp := MSExcel():New()
        If oExcelApp != Nil
            oExcelApp:WorkBooks:Open(cArquivo)
            oExcelApp:SetVisible(.T.)
        EndIf
    ElseIf File(cArquivo)
        ShellExecute("open", cArquivo, "", "", 1)
    EndIf

    // Libera as referencias dos objetos gerados
    oExcel    := Nil
    oExcelApp := Nil

Return

/*/{Protheus.doc} ZMOV_VldTxt
Valida o conteudo digitado pelo usuario antes de o valor entrar na query
SQL (regra CA2050 - anti-injection): aceita somente letras, digitos e
espaco. Aspa e demais caracteres sao recusados com mensagem em portugues.

@param cTexto  Conteudo digitado (sem espacos nas extremidades)
@param cRotulo Rotulo do campo exibido na mensagem de erro
@type   Static Function
@version 12.1.33
@author Suprimentos
@since  22/10/2026
@return Logico .T. quando o conteudo for aceito
/*/
Static Function ZMOV_VldTxt(cTexto, cRotulo)

    Local lOk    := .T.
    Local nI     := 0
    Local nAscii := 0

    For nI := 1 To Len(cTexto)
        nAscii := Asc(SubStr(cTexto, nI, 1))
        If !((nAscii >= 48 .And. nAscii <= 57) .Or. ;    // 0 a 9
             (nAscii >= 65 .And. nAscii <= 90) .Or. ;    // A a Z
             (nAscii >= 97 .And. nAscii <= 122) .Or. ;   // a a z
             nAscii == 32)                               // espaco
            lOk := .F.
            Exit
        EndIf
    Next nI

    If !lOk .Or. Len(AllTrim(cTexto)) == 0
        MsgAlert("O campo " + cRotulo + " aceita somente letras, numeros e " + ;
            "espaco. Informe um valor valido para gerar a planilha.", "Atencao")
        lOk := .F.
    EndIf

Return lOk

/*/{Protheus.doc} ZMOV_CondFil
Monta a condicao de filial de um JOIN considerando se o arquivo e
compartilhado ou exclusivo por filial.

Arquivo compartilhado (xFilial em branco): compara com o proprio xFilial
e traz a unica linha do arquivo. Arquivo exclusivo: compara com a filial
do movimento (D1_FILIAL / D3_FILIAL), garantindo descricao da TES,
produto e fornecedor da mesma filial da nota inclusive quando o usuario
marca "todas as filiais" - evita descartar linha no INNER JOIN ou
duplicar o item por existir a mesma chave em outra filial.

@param cAlias    Tabela Protheus do arquivo (ex.: "SF4")
@param cColFilia Coluna de filial do arquivo no SQL (ex.: "F4.F4_FILIAL")
@param cCmpMov   Coluna de filial do movimento (ex.: "D1.D1_FILIAL")
@type   Static Function
@version 12.1.33
@author Suprimentos
@since  22/10/2026
@return String com a condicao de filial pronta para concatena
/*/
Static Function ZMOV_CondFil(cAlias, cColFilia, cCmpMov)

    Local cFil   := xFilial(cAlias)
    Local cCond  := ""

    If Empty(cFil)
        cCond := cColFilia + " = '" + cFil + "'"
    Else
        cCond := cColFilia + " = " + cCmpMov
    EndIf

Return cCond
