//=================================================================================
// Programa: ZMM01.PRW
// Autor: Sistema
// Data: 26/01/2026
// Descrição: Amostragem Mensal de Estoque com Browse MVC
//=================================================================================

#Include "PROTHEUS.CH"
#Include "TOTVS.CH"
#Include "FWMBROWSE.CH"
#Include "FWMVCDEF.CH"
#Include "TopConn.ch"

//=================================================================================
// Função Principal - Chama o Browse MVC
//=================================================================================
User Function ZMM01()
    Local cTable := "ZZA" + cEmpAnt + "3"
    
    // Verifica se a tabela existe, se não, cria
    If !TabelaExiste(cTable)
        CriaTabZZA()
    EndIf
    
    // *** ADICIONE ESTA LINHA ***
    // Verifica e adiciona campos novos se necessário
    VerificaCampos()
    
    // Chama o browse principal
    MostraBrowse()
Return

//=================================================================================
// Função: TabelaExiste
// Descrição: Verifica se a tabela customizada ZZA existe no banco de dados
// Parâmetros: cTable - Nome da tabela a verificar
// Retorno: lExiste - .T. se existe, .F. se não existe
//=================================================================================
Static Function TabelaExiste(cTable)
    Local lExiste := .F.
    Local cQuery := ""
    
    // Monta query para verificar existência da tabela no SQL Server
    cQuery := "SELECT COUNT(*) AS QTD "
    cQuery += "FROM INFORMATION_SCHEMA.TABLES "
    cQuery += "WHERE TABLE_NAME = '" + cTable + "' "
    
    // Fecha área temporária se estiver aberta
    If Select("TMPCHK") > 0
        TMPCHK->(DbCloseArea())
    EndIf
    
    // Executa a query de verificação
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TMPCHK", .F., .T.)
    
    // Se retornou registros, a tabela existe
    If TMPCHK->QTD > 0
        lExiste := .T.
    EndIf
    
    // Fecha a área temporária
    TMPCHK->(DbCloseArea())
Return lExiste

//=================================================================================
// Função: CriaTabZZA
// Descrição: Cria a tabela customizada ZZA no banco de dados SQL Server
// Campos criados:
//   - ZZA_FILIAL: Filial
//   - ZZA_DATA: Data da amostragem
//   - ZZA_PROD: Código do produto
//   - ZZA_DESCRI: Descrição do produto
//   - ZZA_LOCAL: Armazém
//   - ZZA_SLDSYS: Saldo do sistema
//   - ZZA_QTDCNT: Quantidade contada
//   - ZZA_DIFER: Diferença entre contado e sistema
//   - ZZA_OBS: Observação
//   - ZZA_MOTIVO: Motivos da divergência
//   - ZZA_STATUS: Status (ESTOQUE CORRETO / FURO DE ESTOQUE)
//   - ZZA_INDSIT: Indicador de situação (C=Correto, P=Pendente)
//   - ZZA_USER: Usuário que fez o registro
//   - ZZA_HORA: Hora do registro
//   - D_E_L_E_T_: Flag de exclusão lógica
//   - R_E_C_N_O_: Número do registro (chave primária auto-incremento)
//=================================================================================
Static Function CriaTabZZA()
    Local cTable := "ZZA" + cEmpAnt + "3"
    Local cQuery := ""
    
    cQuery := "CREATE TABLE " + cTable + " ("
    cQuery += "ZZA_FILIAL VARCHAR(4) NOT NULL DEFAULT '    ', "
    cQuery += "ZZA_DATA VARCHAR(8) NOT NULL DEFAULT '        ', "
    cQuery += "ZZA_PROD VARCHAR(15) NOT NULL DEFAULT '               ', "
    cQuery += "ZZA_DESCRI VARCHAR(200) NOT NULL DEFAULT '', "
    cQuery += "ZZA_LOCAL VARCHAR(2) NOT NULL DEFAULT '  ', "
    cQuery += "ZZA_SLDSYS FLOAT NOT NULL DEFAULT 0, "
    cQuery += "ZZA_QTDCNT FLOAT NOT NULL DEFAULT 0, "
    cQuery += "ZZA_DIFER FLOAT NOT NULL DEFAULT 0, "
    cQuery += "ZZA_VLRUNI FLOAT NOT NULL DEFAULT 0, "  // *** NOVO CAMPO ***
    cQuery += "ZZA_OBS VARCHAR(MAX) NULL, "
    cQuery += "ZZA_MOTIVO VARCHAR(500) NULL, "
    cQuery += "ZZA_STATUS VARCHAR(20) NOT NULL DEFAULT 'PENDENTE', "
    cQuery += "ZZA_INDSIT VARCHAR(1) NOT NULL DEFAULT 'P', "
    cQuery += "ZZA_DTAJUS VARCHAR(8) NULL, "  // *** NOVO CAMPO ***
    cQuery += "ZZA_USER VARCHAR(25) NOT NULL DEFAULT '', "
    cQuery += "ZZA_HORA VARCHAR(8) NOT NULL DEFAULT '        ', "
    cQuery += "D_E_L_E_T_ VARCHAR(1) NOT NULL DEFAULT ' ', "
    cQuery += "R_E_C_N_O_ INT IDENTITY(1,1) NOT NULL, "
    cQuery += "CONSTRAINT PK_" + cTable + " PRIMARY KEY (R_E_C_N_O_)"
    cQuery += ")"
    
    If TcSqlExec(cQuery) < 0
        MsgAlert("Erro ao criar tabela: " + TcSqlError(), "Erro")
        Return .F.
    EndIf
    
    CriaIndice(cTable)
    MsgInfo("Tabela " + cTable + " criada com sucesso!", "Sucesso")
Return .T.

//=================================================================================
// Função: CriaIndice
// Descrição: Cria índices na tabela para otimizar consultas
// Índice 01: ZZA_FILIAL + ZZA_PROD + ZZA_LOCAL + ZZA_DATA
// Índice 02: ZZA_FILIAL + ZZA_DATA
//=================================================================================
Static Function CriaIndice(cTable)
    Local cQuery := ""
    
    // Índice composto para busca por produto/armazém/data
    cQuery := "CREATE INDEX IDX_" + cTable + "_01 ON " + cTable
    cQuery += " (ZZA_FILIAL, ZZA_PROD, ZZA_LOCAL, ZZA_DATA)"
    TcSqlExec(cQuery)
    
    // Índice para busca por filial e data
    cQuery := "CREATE INDEX IDX_" + cTable + "_02 ON " + cTable
    cQuery += " (ZZA_FILIAL, ZZA_DATA)"
    TcSqlExec(cQuery)
Return

//=================================================================================
// Função: MostraBrowse
// Descrição: Monta e exibe o browse MVC com os registros de amostragem
//=================================================================================
Static Function MostraBrowse()
    Local oBrowse
    
    Private cAliasQry := GetNextAlias()
    Private cBuscaProd := ""  // codigo digitado na Pesquisa (vazio = lista tudo)
    
    // Cria objeto do browse
    oBrowse := FWMBrowse():New()
    oBrowse:SetDescription("Amostragem Mensal de Estoque")
    oBrowse:SetFontBrowse(TFont():New("Arial",,-12,.F.))
    
    // Configuração de dados
    oBrowse:SetDataQuery(.T.)
    oBrowse:SetQuery(MontaQuery())
    oBrowse:SetAlias(cAliasQry)
    oBrowse:SetProfileID("ZMM1")  // obrigatorio p/ browse com GetNextAlias (TDN)
    
    // 21/10/2026: filtro nativo REATIVADO a pedido (botao Filtrar visivel,
    // como na producao), junto com o Pesquisar customizado de Outras Acoes.
    // RISCO documentado (zmm01-crash-abertura.md): a query nao tem alias no
    // SX3 e clicar em Filtrar pode derrubar a thread (FWFILTEREDIT:GETFIELDS).
    // Para voltar ao estado seguro, descomentar a linha abaixo e recompilar:
    // oBrowse:SetUseFilter(.F.)
    
    // *** NÃO ADICIONE SetChange() AQUI ***
    
    // Legendas
    oBrowse:AddLegend("ZZA_INDSIT == 'C'", "GREEN", "Estoque Correto")
    oBrowse:AddLegend("ZZA_INDSIT == 'P'", "RED", "Furo de Estoque")
    oBrowse:AddLegend("ZZA_INDSIT == 'A'", "BLUE", "Ajustado")
    
    // Botões com atualização correta
    oBrowse:AddButton("Incluir", {|| U_IncluirReg(), AtualizaBrowse(oBrowse) }, , 2)
    oBrowse:AddButton("Alterar", {|| U_AlterarReg(), AtualizaBrowse(oBrowse) }, , 2)
    oBrowse:AddButton("Excluir", {|| U_ExcluirReg(), AtualizaBrowse(oBrowse) }, , 2)
    oBrowse:AddButton("Marcar Ajustado", {|| U_MarcarAjust(oBrowse) }, , 2)
    oBrowse:AddButton("Atualizar Valores", {|| U_AtuVlrUnit(), AtualizaBrowse(oBrowse) }, , 2)
    oBrowse:AddButton("Pesquisar", {|| BuscaRapida(oBrowse) }, , 2)
    oBrowse:AddButton("Limpar", {|| LimparFiltro(oBrowse) }, , 2)
    
    // Define colunas
    oBrowse:SetColumns(MontaColunas())
    
    // Ativa o browse
    oBrowse:Activate()
    
    // Fecha alias ao sair
    If Select(cAliasQry) > 0
        (cAliasQry)->(DbCloseArea())
    EndIf
    
Return
//=================================================================================
// Função: MontaQuery
// Descrição: Monta a query SQL que alimenta o browse
// Filtros aplicados:
//   - Somente registros não deletados (D_E_L_E_T_ = ' ')
//   - Filial logada OU filial vazia (registros legados gravados sem filial)
//   - SEM filtro de mês/ano: sempre exibe todos os registros disponiveis
//     (o ultimo mes pode ainda nao ter amostragem gerada)
// Ordenação: Data decrescente + Hora decrescente
//=================================================================================
Static Function MontaQuery()
    Local cQuery := ""
    Local cTable := "ZZA" + cEmpAnt + "3"
    
    cQuery := "SELECT "
    cQuery += "R_E_C_N_O_ AS NRECZZA, "
    cQuery += "ZZA_FILIAL, "
    cQuery += "ZZA_DATA, "
    cQuery += "ZZA_DTAJUS, "
    cQuery += "ZZA_PROD, "
    cQuery += "ZZA_DESCRI, "
    cQuery += "ZZA_LOCAL, "
    cQuery += "ZZA_SLDSYS, "
    cQuery += "ZZA_QTDCNT, "
    cQuery += "ZZA_DIFER, "
    cQuery += "ZZA_VLRUNI, "
    cQuery += "ZZA_VLRTOT, "
    cQuery += "ZZA_STATUS, "
    cQuery += "CAST(ZZA_MOTIVO AS VARCHAR(500)) AS ZZA_MOTIVO, "
    cQuery += "CAST(ZZA_OBS AS VARCHAR(500)) AS ZZA_OBS, "
    cQuery += "ZZA_INDSIT, "
    cQuery += "ZZA_USER, "
    cQuery += "ZZA_HORA "
    cQuery += "FROM " + cTable + " "
    cQuery += "WHERE D_E_L_E_T_ = '' "
    cQuery += "AND (ZZA_FILIAL = '" + xFilial("SB1") + "' OR ZZA_FILIAL = '') "
    If !Empty(cBuscaProd)
        cQuery += "AND ZZA_PROD LIKE '" + AllTrim(cBuscaProd) + "%' "
    EndIf
    
    cQuery += "ORDER BY ZZA_DATA DESC, ZZA_HORA DESC"
    
Return cQuery
//=================================================================================
// Função: MontaColunas
// Descrição: Define as colunas que serão exibidas no browse
// Retorno: aColumns - Array com objetos FWBrwColumn
//=================================================================================
Static Function MontaColunas()
    Local aColumns := {}
    Local oColumn
    
    // Coluna 1: Data
    oColumn := FWBrwColumn():New()
    oColumn:SetData(&("{|| STOD(" + cAliasQry + "->ZZA_DATA) }"))
    oColumn:SetTitle("Data")
    oColumn:SetSize(10)
    oColumn:SetDecimal(0)
    oColumn:SetPicture("@D")
    aAdd(aColumns, oColumn)
    
    // Coluna 2: Data de Ajuste
    oColumn := FWBrwColumn():New()
    oColumn:SetData(&("{|| IIF(Empty(" + cAliasQry + "->ZZA_DTAJUS), '', DTOC(STOD(" + cAliasQry + "->ZZA_DTAJUS))) }"))
    oColumn:SetTitle("Dt Ajuste")
    oColumn:SetSize(10)
    oColumn:SetDecimal(0)
    oColumn:SetPicture("@D")
    aAdd(aColumns, oColumn)
    
    // Coluna 3: Produto
    oColumn := FWBrwColumn():New()
    oColumn:SetData(&("{|| " + cAliasQry + "->ZZA_PROD }"))
    oColumn:SetTitle("Produto")
    oColumn:SetSize(15)
    oColumn:SetDecimal(0)
    oColumn:SetPicture("@!")
    aAdd(aColumns, oColumn)
    
    // Coluna 4: Descrição **** IMPORTANTE - SINTAXE CORRIGIDA ****
    oColumn := FWBrwColumn():New()
    oColumn:SetData(&("{|| AllTrim(" + cAliasQry + "->ZZA_DESCRI) }"))
    oColumn:SetTitle("Descricao")
    oColumn:SetSize(60)
    oColumn:SetDecimal(0)
    oColumn:SetPicture("@!")
    aAdd(aColumns, oColumn)
    
    // Coluna 5: Armazém
    oColumn := FWBrwColumn():New()
    oColumn:SetData(&("{|| " + cAliasQry + "->ZZA_LOCAL }"))
    oColumn:SetTitle("Arm")
    oColumn:SetSize(3)
    oColumn:SetDecimal(0)
    oColumn:SetPicture("@!")
    aAdd(aColumns, oColumn)
    
    // Coluna 6: Saldo Sistema
    oColumn := FWBrwColumn():New()
    oColumn:SetData(&("{|| " + cAliasQry + "->ZZA_SLDSYS }"))
    oColumn:SetTitle("Sld Sistema")
    oColumn:SetSize(12)
    oColumn:SetDecimal(2)
    oColumn:SetPicture("@E 999,999.99")
    aAdd(aColumns, oColumn)
    
    // Coluna 7: Quantidade Contada
    oColumn := FWBrwColumn():New()
    oColumn:SetData(&("{|| " + cAliasQry + "->ZZA_QTDCNT }"))
    oColumn:SetTitle("Qtd Contada")
    oColumn:SetSize(12)
    oColumn:SetDecimal(2)
    oColumn:SetPicture("@E 999,999.99")
    aAdd(aColumns, oColumn)
    
    // Coluna 8: Diferença
    oColumn := FWBrwColumn():New()
    oColumn:SetData(&("{|| " + cAliasQry + "->ZZA_DIFER }"))
    oColumn:SetTitle("Diferenca")
    oColumn:SetSize(12)
    oColumn:SetDecimal(2)
    oColumn:SetPicture("@E 999,999.99")
    aAdd(aColumns, oColumn)
    
    // Coluna 9: Valor Unitário
    oColumn := FWBrwColumn():New()
    oColumn:SetData(&("{|| " + cAliasQry + "->ZZA_VLRUNI }"))
    oColumn:SetTitle("Vlr Unit")
    oColumn:SetSize(12)
    oColumn:SetDecimal(2)
    oColumn:SetPicture("@E 999,999.99")
    aAdd(aColumns, oColumn)

    // COLUNA 10: TOTAL DO AJUSTE
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| (cAliasQry)->ZZA_VLRTOT })
    oColumn:SetTitle("Total Ajuste")
    oColumn:SetSize(14)
    oColumn:SetDecimal(2)
    oColumn:SetPicture("@E 999,999.99")
    aAdd(aColumns, oColumn)
    
    // Coluna 10: Status
    oColumn := FWBrwColumn():New()
    oColumn:SetData(&("{|| " + cAliasQry + "->ZZA_STATUS }"))
    oColumn:SetTitle("Status")
    oColumn:SetSize(20)
    oColumn:SetDecimal(0)
    oColumn:SetPicture("@!")
    aAdd(aColumns, oColumn)
    
    // Coluna 11: Motivo
    oColumn := FWBrwColumn():New()
    oColumn:SetData(&("{|| AllTrim(" + cAliasQry + "->ZZA_MOTIVO) }"))
    oColumn:SetTitle("Motivo")
    oColumn:SetSize(60)
    oColumn:SetDecimal(0)
    oColumn:SetPicture("@!")
    aAdd(aColumns, oColumn)
    
    // Coluna 12: Observação
    oColumn := FWBrwColumn():New()
    oColumn:SetData(&("{|| AllTrim(" + cAliasQry + "->ZZA_OBS) }"))
    oColumn:SetTitle("Observacao")
    oColumn:SetSize(60)
    oColumn:SetDecimal(0)
    oColumn:SetPicture("@!")
    aAdd(aColumns, oColumn)
    
    // Coluna 13: Usuário
    oColumn := FWBrwColumn():New()
    oColumn:SetData(&("{|| " + cAliasQry + "->ZZA_USER }"))
    oColumn:SetTitle("Usuario")
    oColumn:SetSize(15)
    oColumn:SetDecimal(0)
    oColumn:SetPicture("@!")
    aAdd(aColumns, oColumn)
    
Return aColumns
//=================================================================================
// Função: IncluirReg
// Descrição: Abre tela para inclusão de novo registro de amostragem
// Funcionalidades:
//   - Campos para preenchimento
//   - Validação de produto cadastrado
//   - Busca automática do saldo do sistema
//   - Check boxes para motivos da divergência
//   - Validação de estoque (correto ou furo)
//=================================================================================
User Function IncluirReg()
    MontaTela(3) // 3 = Inclusão
Return

//=================================================================================
// Função: AlterarReg
// Descrição: Abre tela para alteração de registro existente
// Carrega dados do registro selecionado no browse
// Não permite alterar produto e armazém
//=================================================================================
User Function AlterarReg()
    Local cTable := "ZZA" + cEmpAnt + "3"
    Local cQuery := ""
    Local nRecno := 0
    Local cMotivoTmp := ""
    Local cObsTmp := ""
    Local cStatusReg := ""
    
    // VALIDA SE HÁ REGISTRO SELECIONADO
    If (cAliasQry)->(Eof()) .Or. (cAliasQry)->(Bof())
        MsgAlert("Nenhum registro selecionado", "Atencao")
        Return
    EndIf
    
    // *** VALIDAÇÃO: Verifica se o registro está AJUSTADO ***
    cStatusReg := AllTrim((cAliasQry)->ZZA_INDSIT)
    
    If cStatusReg == "A"  // A = Ajustado
        MsgAlert("Este registro ja foi AJUSTADO e nao pode ser alterado!", "Atencao")
        Return
    EndIf
    
    // Obtém o RECNO da linha selecionada no browse
    nRecno := (cAliasQry)->NRECZZA
    
    If nRecno == 0 .Or. nRecno == Nil
        MsgAlert("RECNO invalido", "Atencao")
        Return
    EndIf
    
    // Busca dados completos diretamente do banco sem alias temporário
    cQuery := "SELECT TOP 1 "
    cQuery += "CAST(ZZA_MOTIVO AS VARCHAR(500)) AS MOTIVO, "
    cQuery += "CAST(ZZA_OBS AS VARCHAR(8000)) AS OBSERVACAO "
    cQuery += "FROM " + cTable + " "
    cQuery += "WHERE R_E_C_N_O_ = " + cValToChar(nRecno)
    
    If Select("TMPMOT") > 0
        TMPMOT->(DbCloseArea())
    EndIf
    
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TMPMOT", .F., .T.)
    
    If !TMPMOT->(Eof())
        cMotivoTmp := AllTrim(TMPMOT->MOTIVO)
        cObsTmp := AllTrim(TMPMOT->OBSERVACAO)
    EndIf
    
    TMPMOT->(DbCloseArea())
    
    // Busca dados completos do registro (SEM ZZA_OBS e ZZA_MOTIVO)
    If Select("TMPALT") > 0
        TMPALT->(DbCloseArea())
    EndIf
    
    cQuery := "SELECT "
    cQuery += "R_E_C_N_O_ AS R_E_C_N_O_, "
    cQuery += "ZZA_FILIAL, "
    cQuery += "ZZA_DATA, "
    cQuery += "ZZA_PROD, "
    cQuery += "ZZA_DESCRI, "
    cQuery += "ZZA_LOCAL, "
    cQuery += "ZZA_SLDSYS, "
    cQuery += "ZZA_QTDCNT, "
    cQuery += "ZZA_DIFER, "
    cQuery += "ZZA_VLRUNI, "
    cQuery += "ZZA_VLRTOT, "
    cQuery += "ZZA_STATUS, "
    cQuery += "ZZA_INDSIT, "
    cQuery += "ZZA_USER, "
    cQuery += "ZZA_HORA "
    cQuery += "FROM " + cTable + " "
    cQuery += "WHERE R_E_C_N_O_ = " + cValToChar(nRecno)
    
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TMPALT", .F., .T.)
    
    If TMPALT->(Eof())
        MsgAlert("Registro nao encontrado", "Erro")
        TMPALT->(DbCloseArea())
        Return
    EndIf
    
    // Chama tela de alteração passando motivo e observação separadamente
    MontaTela(4, "TMPALT", cMotivoTmp, cObsTmp) // 4 = Alteração
    
    TMPALT->(DbCloseArea())
Return

//=================================================================================
// Função: ExcluirReg
// Descrição: Realiza exclusão lógica do registro selecionado
// Não apaga fisicamente, apenas marca D_E_L_E_T_ = '*'
// Solicita confirmação antes de excluir
//=================================================================================
User Function ExcluirReg()
    Local cTable := "ZZA" + cEmpAnt + "3"
    Local cQuery := ""
    Local nRecno := 0
    Local cStatusReg := ""
    
    // Obtém o RECNO da linha selecionada
    nRecno := (cAliasQry)->NRECZZA
    
    If nRecno <= 0
        MsgAlert("Nenhum registro selecionado", "Atencao")
        Return
    EndIf
    
    // *** VALIDAÇÃO: Verifica se o registro está AJUSTADO ***
    cStatusReg := AllTrim((cAliasQry)->ZZA_INDSIT)
    
    If cStatusReg == "A"  // A = Ajustado
        MsgAlert("Este registro ja foi AJUSTADO e nao pode ser excluido!", "Atencao")
        Return
    EndIf
    
    // Solicita confirmação
    If !MsgYesNo("Confirma a exclusao deste registro?", "Atencao")
        Return
    EndIf

    // Exclusao logica via TcSqlExec (alias de query nao permite RecLock)
    cQuery := "UPDATE " + cTable + " "
    cQuery += "SET D_E_L_E_T_ = '*' "
    cQuery += "WHERE R_E_C_N_O_ = " + cValToChar(nRecno)
    
    If TcSqlExec(cQuery) < 0
        MsgAlert("Erro ao excluir o registro: " + TcSqlError(), "Erro")
        Return
    EndIf
    
    MsgInfo("Registro excluido com sucesso!", "Sucesso")
Return

//=================================================================================
// Função: ExportaExcel
// Descrição: Exporta dados do browse para arquivo CSV (Excel)
// Arquivo gerado: C:\TEMP\Amostragem_Estoque_AAAAMMDD_HHMMSS.csv
// Colunas exportadas: Todas as colunas visíveis no browse
//=================================================================================
User Function ExportaExcel()
    Local cArquivo := ""
    Local cQuery := ""
    Local cTable := "ZZA" + cEmpAnt + "3"
    Local nHandle := 0
    Local cLinha := ""
    
    // Define nome do arquivo com data/hora
    cArquivo := "C:\TEMP\Amostragem_Estoque_" + DtoS(Date()) + "_" + StrTran(Time(),":","") + ".csv"
    
    // Fecha área temporária se estiver aberta
    If Select("TMPEXP") > 0
        TMPEXP->(DbCloseArea())
    EndIf
    
    // Monta query para exportação
    cQuery := "SELECT "
    cQuery += "ZZA_DATA AS Data, "
    cQuery += "ZZA_PROD AS Produto, "
    cQuery += "ZZA_DESCRI AS Descricao, "
    cQuery += "ZZA_LOCAL AS Armazem, "
    cQuery += "ZZA_SLDSYS AS Saldo_Sistema, "
    cQuery += "ZZA_QTDCNT AS Qtd_Contada, "
    cQuery += "ZZA_DIFER AS Diferenca, "
    cQuery += "ZZA_STATUS AS Status, "
    cQuery += "ZZA_MOTIVO AS Motivo, "
    cQuery += "ZZA_OBS AS Observacao, "
    cQuery += "ZZA_USER AS Usuario, "
    cQuery += "ZZA_HORA AS Hora "
    cQuery += "FROM " + cTable + " "
    cQuery += "WHERE D_E_L_E_T_ = ' ' "
    cQuery += "AND (ZZA_FILIAL = '" + xFilial("SB1") + "' OR ZZA_FILIAL = '') "
    cQuery += "ORDER BY ZZA_DATA DESC, ZZA_HORA DESC"
    
    // Executa query
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TMPEXP", .F., .T.)
    
    // Valida se há dados para exportar
    If TMPEXP->(Eof())
        MsgAlert("Nenhum registro para exportar", "Atencao")
        TMPEXP->(DbCloseArea())
        Return
    EndIf
    
    // Cria diretório se não existir
    If !ExistDir("C:\TEMP")
        MakeDir("C:\TEMP")
    EndIf
    
    // Cria arquivo CSV
    nHandle := FCreate(cArquivo)
    
    If nHandle == -1
        MsgAlert("Erro ao criar arquivo", "Erro")
        TMPEXP->(DbCloseArea())
        Return
    EndIf
    
    // Escreve cabeçalho do CSV
    cLinha := "Data;Produto;Descricao;Armazem;Saldo Sistema;Qtd Contada;Diferenca;Status;Motivo;Observacao;Usuario;Hora" + CRLF
    FWrite(nHandle, cLinha)
    
    // Loop pelos registros e escreve no arquivo
    TMPEXP->(DbGoTop())
    While !TMPEXP->(Eof())
        cLinha := Transform(StoD(TMPEXP->Data), "@D") + ";"
        cLinha += AllTrim(TMPEXP->Produto) + ";"
        cLinha += AllTrim(TMPEXP->Descricao) + ";"
        cLinha += AllTrim(TMPEXP->Armazem) + ";"
        cLinha += Transform(TMPEXP->Saldo_Sistema, "@E 999999.99") + ";"
        cLinha += Transform(TMPEXP->Qtd_Contada, "@E 999999.99") + ";"
        cLinha += Transform(TMPEXP->Diferenca, "@E 999999.99") + ";"
        cLinha += AllTrim(TMPEXP->Status) + ";"
        cLinha += AllTrim(TMPEXP->Motivo) + ";"
        cLinha += AllTrim(TMPEXP->Observacao) + ";"
        cLinha += AllTrim(TMPEXP->Usuario) + ";"
        cLinha += AllTrim(TMPEXP->Hora) + CRLF
        
        FWrite(nHandle, cLinha)
        TMPEXP->(DbSkip())
    EndDo
    
    // Fecha arquivo e área temporária
    FClose(nHandle)
    TMPEXP->(DbCloseArea())
    
    // Pergunta se deseja abrir o arquivo
    If MsgYesNo("Arquivo exportado com sucesso em " + cArquivo + CRLF + CRLF + "Deseja abrir o arquivo?", "Sucesso")
        ShellExecute("open", cArquivo, "", "", 1)
    EndIf
Return
//=================================================================================
// Função: ValidaGravacao
// Descrição: Valida dados antes de gravar (chamada pelo botão Confirmar)
// Retorno: .T. se gravou com sucesso, .F. se houve erro
//=================================================================================
Static Function ValidaGravacao(lAlterar, nRecno, oDlg)
    Local lRet := .T.
    Local nDiferenca := nQtdCont - nSaldoSis
    Local cMotivos := ""
    Local nMarcados := 0
    
    // Validação 1: Produto
    If Empty(AllTrim(cProduto))
        MsgAlert("Informe o codigo do produto!", "Atencao")
        Return .F.
    EndIf
    
    // Validação 2: Armazém
    If Empty(AllTrim(cLocal))
        MsgAlert("Informe o armazem!", "Atenção")
        Return .F.
    EndIf
    
    // Validação 3: Se há divergência, exige motivo
    If nDiferenca != 0
        // *** NOVA VALIDAÇÃO: Conta quantos checkboxes estão marcados ***
        nMarcados := 0
        If lChk1
            nMarcados++
        EndIf
        If lChk2
            nMarcados++
        EndIf
        If lChk3
            nMarcados++
        EndIf
        If lChk4
            nMarcados++
        EndIf
        If lChk5
            nMarcados++
        EndIf
        If lChk6
            nMarcados++
        EndIf
        If lChk7
            nMarcados++
        EndIf
        If lChk8
            nMarcados++
        EndIf
        If lChk9
            nMarcados++
        EndIf
        
        // *** VALIDAÇÃO: Verifica se há MAIS DE UMA justificativa marcada ***
        If nMarcados > 1
            MsgAlert("So pode ter apenas uma justificativa marcada.", "Atencao")
            Return .F.
        EndIf
        
        // *** VALIDAÇÃO: Verifica se há PELO MENOS UMA justificativa ***
        cMotivos := MontaMotivos()
        If Empty(AllTrim(cMotivos))
            MsgAlert("Selecione ao menos um motivo para a divergencia!", "Atencao")
            Return .F.
        EndIf
    EndIf
    
    // Se passou nas validações, grava
    lRet := GravaAmost(lAlterar, nRecno)
    
    // Se gravou com sucesso, fecha a tela
    If lRet
        oDlg:End()
    EndIf
    
Return lRet
//=================================================================================
// Função: MontaTela
// Descrição: Monta tela de inclusão/alteração de registro
// Parâmetros: 
//   nOpc - 3=Inclusão, 4=Alteração
//   cAliasReg - Alias com dados do registro (usado na alteração)
//   cMotivoAux - Motivo da divergência (opcional)
//   cObsAux - Observação (opcional)
//=================================================================================
Static Function MontaTela(nOpc, cAliasReg, cMotivoAux, cObsAux)
    Local oDlg, oPanel, oGroup
    Local oGetProd, oGetLocal, oGetDesc, oGetSldo, oGetQtCont, oGetObs, oGetVlrUni
    Local oGetVlrTot
    Local oBtn1, oBtn2
    Local oChk1, oChk2, oChk3, oChk4, oChk5, oChk6, oChk7, oChk8, oChk9, oGetOutro
    Local cTitulo := IIF(nOpc == 3, "Incluir Amostragem de Estoque", "Alterar Amostragem de Estoque")
    Local lAlterar := (nOpc == 4)
    Local nRecno := 0
    
    Default cAliasReg := ""
    Default cMotivoAux := ""
    Default cObsAux := ""
    
    // Inicializa variáveis privadas
    Private cProduto  := Space(15)
    Private cLocal    := "02"
    Private cDescri   := Space(200)
    Private nSaldoSis := 0
    Private nQtdCont  := 0
    Private nVlrUni   := 0
    Private nVlrTot := 0
    Private cObserv   := cObsAux
    Private cStatus   := ""
    Private cIndSit   := "P"
    Private lChk1     := .F.
    Private lChk2     := .F.
    Private lChk3     := .F.
    Private lChk4     := .F.
    Private lChk5     := .F.
    Private lChk6     := .F.
    Private lChk7     := .F.
    Private lChk8     := .F.
    Private lChk9     := .F.
    Private cOutro    := Space(100)
    
    // Se for alteração, carrega dados do registro
    If lAlterar .And. !Empty(cAliasReg)
        nRecno    := (cAliasReg)->R_E_C_N_O_
        cProduto  := (cAliasReg)->ZZA_PROD
        cLocal    := (cAliasReg)->ZZA_LOCAL
        cDescri   := (cAliasReg)->ZZA_DESCRI
        nSaldoSis := (cAliasReg)->ZZA_SLDSYS
        nQtdCont  := (cAliasReg)->ZZA_QTDCNT
        nVlrUni   := (cAliasReg)->ZZA_VLRUNI
        nVlrTot := (cAliasReg)->ZZA_VLRTOT
        
        CarregaMotivos(cMotivoAux)
    EndIf
    
    // Cria janela de diálogo - AUMENTEI A ALTURA PARA 680 pixels
    DEFINE MSDIALOG oDlg TITLE cTitulo FROM 000,000 TO 700,600 PIXEL
    
    oPanel := TPanel():New(0, 0, , oDlg,,,,,, 0, 0)
    oPanel:Align := CONTROL_ALIGN_ALLCLIENT
    // ========== CAMPOS DE ENTRADA ==========

    // Linha 1: Código do Item
    @ 015, 010 SAY "Codigo do Item" SIZE 055, 007 OF oPanel PIXEL
    @ 013, 080 MSGET oGetProd VAR cProduto SIZE 080, 010 OF oPanel PIXEL ;
               VALID ValidProd(oGetDesc, oGetSldo, oGetLocal, oGetVlrUni) ;
               F3 "SB1" WHEN !lAlterar
    
    // Linha 2: Armazém
    @ 030, 010 SAY "Armazem" SIZE 055, 007 OF oPanel PIXEL
    @ 028, 080 MSGET oGetLocal VAR cLocal SIZE 030, 010 OF oPanel PIXEL ;
               VALID ValidLocal(oGetSldo, oGetVlrUni) WHEN !lAlterar
    
    // Linha 3: Descrição
    @ 045, 010 SAY "Descricao" SIZE 055, 007 OF oPanel PIXEL
    @ 043, 080 MSGET oGetDesc VAR cDescri SIZE 210, 010 OF oPanel PIXEL ;
               WHEN .F. COLOR CLR_BLACK, RGB(240,240,240)
    
    // Linha 4: Saldo Sistema
    @ 060, 010 SAY "Saldo Sistema" SIZE 055, 007 OF oPanel PIXEL FONT TFont():New("Arial",,-12,.T.)
    @ 058, 080 MSGET oGetSldo VAR nSaldoSis PICTURE "@E 999,999.99" SIZE 080, 010 OF oPanel PIXEL ;
               WHEN .F. COLOR CLR_BLACK, RGB(255,255,200)
    
    // Linha 5: Quantidade Contada
    @ 075, 010 SAY "Qtd Contada" SIZE 055, 007 OF oPanel PIXEL FONT TFont():New("Arial",,-12,.T.)
    @ 073, 080 MSGET oGetQtCont VAR nQtdCont PICTURE "@E 999,999.99" SIZE 080, 010 OF oPanel PIXEL ;
               VALID ValidaContagem()
    
    // Linha 6: Valor Unitário
    @ 090, 010 SAY "Vlr Unitario (R$)" SIZE 055, 007 OF oPanel PIXEL
    @ 088, 080 MSGET oGetVlrUni VAR nVlrUni PICTURE "@E 999,999.99" SIZE 080, 010 OF oPanel PIXEL ;
               WHEN .F. COLOR CLR_BLACK, RGB(240,240,240)
    
    // Linha 7: Total do Ajuste (NOVO)
    @ 105, 010 SAY "Total Ajuste (R$)" SIZE 055, 007 OF oPanel PIXEL FONT TFont():New("Arial",,-12,.T.)
    @ 103, 080 MSGET oGetVlrTot VAR nVlrTot PICTURE "@E 999,999.99" SIZE 080, 010 OF oPanel PIXEL ;
               WHEN .F. COLOR CLR_BLACK, RGB(200,255,200)
    
    // ========== GRUPO DE CHECKBOXES ==========
    // Ajustado para começar em Y=125 (20 pixels abaixo do Total Ajuste)
    
    @ 125, 010 GROUP oGroup TO 260, 290 PROMPT "Motivo da Divergencia (selecione apenas 1)" OF oPanel PIXEL
    
    // Coluna 1 de Checkboxes - Y inicial 137
    @ 137, 020 CHECKBOX oChk1 VAR lChk1 PROMPT "Falta de Baixa" SIZE 120, 010 OF oPanel PIXEL ;
               VALID ValidaCheckUnico(1, oChk1, oChk2, oChk3, oChk4, oChk5, oChk6, oChk7, oChk8, oChk9)
    
    @ 152, 020 CHECKBOX oChk2 VAR lChk2 PROMPT "Retirada Sem Requisicao" SIZE 120, 010 OF oPanel PIXEL ;
               VALID ValidaCheckUnico(2, oChk1, oChk2, oChk3, oChk4, oChk5, oChk6, oChk7, oChk8, oChk9)
    
    @ 167, 020 CHECKBOX oChk3 VAR lChk3 PROMPT "Retirada Emergencial" SIZE 120, 010 OF oPanel PIXEL ;
               VALID ValidaCheckUnico(3, oChk1, oChk2, oChk3, oChk4, oChk5, oChk6, oChk7, oChk8, oChk9)
    
    @ 182, 020 CHECKBOX oChk4 VAR lChk4 PROMPT "Unidade de Medida Incorreta" SIZE 120, 010 OF oPanel PIXEL ;
               VALID ValidaCheckUnico(4, oChk1, oChk2, oChk3, oChk4, oChk5, oChk6, oChk7, oChk8, oChk9)
    
    @ 197, 020 CHECKBOX oChk5 VAR lChk5 PROMPT "Pedido de Compra Nao Gerado" SIZE 120, 010 OF oPanel PIXEL ;
               VALID ValidaCheckUnico(5, oChk1, oChk2, oChk3, oChk4, oChk5, oChk6, oChk7, oChk8, oChk9)
    
    @ 212, 020 CHECKBOX oChk6 VAR lChk6 PROMPT "Perda ou Extravio" SIZE 120, 010 OF oPanel PIXEL ;
               VALID ValidaCheckUnico(6, oChk1, oChk2, oChk3, oChk4, oChk5, oChk6, oChk7, oChk8, oChk9)
    
    @ 227, 020 CHECKBOX oChk7 VAR lChk7 PROMPT "Avaria de Material" SIZE 120, 010 OF oPanel PIXEL ;
               VALID ValidaCheckUnico(7, oChk1, oChk2, oChk3, oChk4, oChk5, oChk6, oChk7, oChk8, oChk9)
    
    // Coluna 2 de Checkboxes - Y inicial 137
    @ 137, 150 CHECKBOX oChk8 VAR lChk8 PROMPT "Ajuste Estoque Nao Realizado" SIZE 130, 010 OF oPanel PIXEL ;
               VALID ValidaCheckUnico(8, oChk1, oChk2, oChk3, oChk4, oChk5, oChk6, oChk7, oChk8, oChk9)
    
    @ 152, 150 CHECKBOX oChk9 VAR lChk9 PROMPT "Outro:" SIZE 030, 010 OF oPanel PIXEL ;
               VALID ValidaCheckUnico(9, oChk1, oChk2, oChk3, oChk4, oChk5, oChk6, oChk7, oChk8, oChk9)
    
    @ 150, 185 MSGET oGetOutro VAR cOutro SIZE 100, 010 OF oPanel PIXEL
    
    // ========== CAMPO DE OBSERVAÇÃO ==========
    // Ajustado para começar em Y=265
    
    @ 265, 010 SAY "Observacao" SIZE 055, 007 OF oPanel PIXEL
    @ 263, 080 GET oGetObs VAR cObserv SIZE 210, 060 OF oPanel PIXEL MULTILINE
    
    // ========== BOTÕES ==========
    // Ajustado para Y=328
    
    @ 328, 120 BUTTON oBtn1 PROMPT "Confirmar" SIZE 060, 014 OF oPanel PIXEL ;
               ACTION IIf(ValidaGravacao(lAlterar, nRecno, oDlg), oDlg:End(), Nil)
    
    @ 328, 185 BUTTON oBtn2 PROMPT "Cancelar" SIZE 060, 014 OF oPanel PIXEL ;
               ACTION oDlg:End()
    
    ACTIVATE MSDIALOG oDlg CENTERED
Return


//=================================================================================
// Função: CarregaMotivos
// Descrição: Carrega os motivos selecionados ao editar um registro
// Marca os check boxes correspondentes aos motivos salvos
// Parâmetro: cMotivos - String com motivos separados por ';'
//=================================================================================
Static Function CarregaMotivos(cMotivos)
    // Verifica se tem campo "Outro" preenchido
    Local nPos := At("Outro:", cMotivos)

    // Verifica cada motivo na string e marca o check box correspondente
    lChk1 := ("Falta de Baixa" $ cMotivos)
    lChk2 := ("Retirada Sem Requisicao" $ cMotivos)
    lChk3 := ("Retirada Emergencial" $ cMotivos)
    lChk4 := ("Unidade de Medida Incorreta" $ cMotivos)
    lChk5 := ("Pedido de Compra Nao Gerado" $ cMotivos)
    lChk6 := ("Perda ou Extravio" $ cMotivos)
    lChk7 := ("Avaria de Material" $ cMotivos)
    lChk8 := ("Ajuste de Estoque Nao Realizado" $ cMotivos)
    
    If nPos > 0
        lChk9 := .T.
        cOutro := SubStr(cMotivos, nPos + 7)
        cOutro := StrTran(cOutro, ";", "")
        cOutro := AllTrim(cOutro)
    EndIf
Return

//=================================================================================
// Função: ValidProd
// Descrição: Valida se o produto informado existe no cadastro (tabela SB1)
// Se existir, preenche automaticamente a descrição e busca o saldo
// CORRIGIDO: Permite campo vazio (para poder cancelar sem preencher)
// Parâmetros: 
//   oGetDesc - Objeto do campo Descrição
//   oGetSldo - Objeto do campo Saldo Sistema
//   oGetLocal - Objeto do campo Armazém
// Retorno: .T. se válido, .F. se inválido
//=================================================================================
Static Function ValidProd(oGetDesc, oGetSldo, oGetLocal, oGetVlrUni)
    Local lRet := .T.
    Local aArea := GetArea()
    
    If Empty(AllTrim(cProduto))
        cDescri := Space(200)
        nSaldoSis := 0
        nVlrUni := 0
        oGetDesc:Refresh()
        oGetSldo:Refresh()
        oGetVlrUni:Refresh()  // *** ADICIONE ***
        RestArea(aArea)
        Return .T.
    EndIf
    
    DbSelectArea("SB1")
    SB1->(DbSetOrder(1))
    
    If !SB1->(DbSeek(xFilial("SB1") + cProduto))
        MsgAlert("Produto nao cadastrado", "Erro")
        cDescri := Space(200)
        nSaldoSis := 0
        nVlrUni := 0
        lRet := .F.
    Else
        cDescri := SB1->B1_DESC
        
        If Empty(cLocal)
            cLocal := "02"
            oGetLocal:Refresh()
        EndIf
        
        BuscaSaldoValor()
        oGetSldo:Refresh()
        oGetVlrUni:Refresh()  // *** ADICIONE ***
    EndIf
    
    oGetDesc:Refresh()
    RestArea(aArea)
Return lRet
//=================================================================================
// Função: ValidLocal
// Descrição: Valida se o armazém foi informado e atualiza o saldo
// CORRIGIDO: Permite campo vazio (para poder cancelar sem preencher)
// Parâmetros:
//   oGetSldo - Objeto do campo Saldo Sistema
// Retorno: .T. se válido, .F. se inválido
//=================================================================================
Static Function ValidLocal(oGetSldo, oGetVlrUni)
    If Empty(AllTrim(cLocal))
        nSaldoSis := 0
        nVlrUni := 0
        oGetSldo:Refresh()
        oGetVlrUni:Refresh()  // *** ADICIONE ***
        Return .T.
    EndIf
    
    If Empty(AllTrim(cProduto))
        MsgAlert("Informe o produto primeiro", "Atenção")
        Return .F.
    EndIf
    
    BuscaSaldoValor()
    oGetSldo:Refresh()
    oGetVlrUni:Refresh()  // *** ADICIONE ***
Return .T.

//=================================================================================
// Função: BuscaSaldo
// Descrição: Busca o saldo atual do produto no armazém (tabela SB2)
// Atualiza a variável nSaldoSis com o saldo encontrado
//=================================================================================
Static Function BuscaSaldoValor()
    Local aArea := GetArea()
    Local cQueryD1 := ""
    
    nSaldoSis := 0
    nVlrUni := 0
    
    If Empty(cProduto) .Or. Empty(cLocal)
        RestArea(aArea)
        Return
    EndIf
    
    // Busca saldo no SB2
    DbSelectArea("SB2")
    SB2->(DbSetOrder(1))
    
    If SB2->(DbSeek(xFilial("SB2") + cProduto + cLocal))
        nSaldoSis := SB2->B2_QATU
    EndIf
    
    // *** PRIORIDADE 1: D1_VUNIT (ÚLTIMA ENTRADA) ***
    If Select("TMPD1") > 0
        TMPD1->(DbCloseArea())
    EndIf
    
    cQueryD1 := "SELECT TOP 1 D1_VUNIT "
    cQueryD1 += "FROM " + RetSqlName("SD1") + " SD1 "
    cQueryD1 += "WHERE SD1.D_E_L_E_T_ = ' ' "
    cQueryD1 += "AND D1_FILIAL = '" + xFilial("SD1") + "' "
    cQueryD1 += "AND D1_COD = '" + cProduto + "' "
    cQueryD1 += "AND D1_LOCAL = '" + cLocal + "' "
    cQueryD1 += "AND D1_VUNIT > 0 "
    cQueryD1 += "ORDER BY D1_DTDIGIT DESC, D1_EMISSAO DESC"
    
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQueryD1), "TMPD1", .F., .T.)
    
    If !TMPD1->(Eof())
        nVlrUni := TMPD1->D1_VUNIT
    EndIf
    
    TMPD1->(DbCloseArea())
    
    // Prioridade 2: Custo médio (se não encontrou entrada)
    If nVlrUni == 0
        DbSelectArea("SB2")
        SB2->(DbSetOrder(1))
        
        If SB2->(DbSeek(xFilial("SB2") + cProduto + cLocal))
            If SB2->B2_CM1 > 0
                nVlrUni := SB2->B2_CM1
            ElseIf SB2->B2_VATU1 > 0 .And. SB2->B2_QATU > 0
                nVlrUni := SB2->B2_VATU1 / SB2->B2_QATU
            EndIf
        EndIf
    EndIf
    
    // Prioridade 3: Cadastro de produtos
    If nVlrUni == 0
        DbSelectArea("SB1")
        SB1->(DbSetOrder(1))
        
        If SB1->(DbSeek(xFilial("SB1") + cProduto))
            If SB1->B1_UPRC > 0
                nVlrUni := SB1->B1_UPRC
            ElseIf SB1->B1_CUSTD > 0
                nVlrUni := SB1->B1_CUSTD
            EndIf
        EndIf
    EndIf
    
    RestArea(aArea)
Return

//=================================================================================
// Função: ValidaContagem
// Descrição: Valida a quantidade contada e compara com o saldo do sistema
//            Define o status e indicador de situação do registro
//            VERSÃO SILENCIOSA - Sem mensagens (validação no botão Confirmar)
// Retorno: Sempre .T. (validação não bloqueia o campo)
//=================================================================================
Static Function ValidaContagem()
    Local nDiferenca := nQtdCont - nSaldoSis
    
    // Calcula o total do ajuste
    nVlrTot := nVlrUni * nDiferenca
    
    // Atualiza o campo na tela se existir
    If Type("oGetVlrTot") == "O"
        oGetVlrTot:Refresh()
    EndIf
    
    // Compara quantidade contada com saldo do sistema
    If nDiferenca == 0
        // Estoque correto
        cStatus := "ESTOQUE CORRETO"
        cIndSit := "C"
    Else
        // Furo de estoque
        cStatus := "FURO DE ESTOQUE"
        cIndSit := "P"
    EndIf
    
Return .T.

//=================================================================================
// Função: GravaAmost
// Descrição: Grava o registro de amostragem no banco de dados
// Realiza todas as validações necessárias antes de gravar
// Parâmetros:
//   lAlterar - .T. se é alteração, .F. se é inclusão
//   nRecno - Número do registro a ser alterado (usado apenas em alteração)
// Retorno: .T. se gravou com sucesso, .F. se houve erro
//=================================================================================
Static Function GravaAmost(lAlterar, nRecno)
    Local cQuery := ""
    Local cTable := "ZZA" + cEmpAnt + "3"
    Local nDiferenca := 0
    Local cMotivos := ""
    Local nTotal := 0  
    
    // Validação 1: Produto
    If Empty(AllTrim(cProduto))
        MsgAlert("Informe o código do produto!", "Atenção")
        Return .F.
    EndIf
    
    // Validação 2: Armazém
    If Empty(AllTrim(cLocal))
        MsgAlert("Informe o armazém!", "Atenção")
        Return .F.
    EndIf
    
    // Calcula diferença e total
    nDiferenca := nQtdCont - nSaldoSis
    nTotal := nVlrUni * nDiferenca  
    
    // Define status conforme divergência
    If nDiferenca != 0
        cMotivos := MontaMotivos()
        If Empty(AllTrim(cMotivos))
            MsgAlert("Selecione ao menos um motivo para a divergência!", "Atenção")
            Return .F.
        EndIf
        cStatus := "FURO DE ESTOQUE"
        cIndSit := "P"
    Else
        cStatus := "ESTOQUE CORRETO"
        cIndSit := "C"
        cMotivos := ""
    EndIf
    
    If lAlterar
        // *** UPDATE para alteração ***
        cQuery := "UPDATE " + cTable + " SET "
        cQuery += "ZZA_QTDCNT = " + cValToChar(nQtdCont) + ", "
        cQuery += "ZZA_DIFER = " + cValToChar(nDiferenca) + ", "
        cQuery += "ZZA_VLRUNI = " + cValToChar(nVlrUni) + ", "
        cQuery += "ZZA_VLRTOT = " + cValToChar(nTotal) + ", "  
        cQuery += "ZZA_MOTIVO = '" + StrTran(cMotivos, "'", "") + "', "
        cQuery += "ZZA_OBS = '" + StrTran(AllTrim(cObserv), "'", "") + "', "
        cQuery += "ZZA_STATUS = '" + cStatus + "', "
        cQuery += "ZZA_INDSIT = '" + cIndSit + "', "
        cQuery += "ZZA_USER = '" + AllTrim(cUserName) + "', "
        cQuery += "ZZA_HORA = '" + Time() + "' "
        cQuery += "WHERE R_E_C_N_O_ = " + cValToChar(nRecno)
    Else
        // *** INSERT para inclusão ***
        cQuery := "INSERT INTO " + cTable + " "
        cQuery += "(ZZA_FILIAL, ZZA_DATA, ZZA_PROD, ZZA_DESCRI, ZZA_LOCAL, ZZA_SLDSYS, "
        cQuery += "ZZA_QTDCNT, ZZA_DIFER, ZZA_VLRUNI, ZZA_VLRTOT, ZZA_MOTIVO, ZZA_OBS, ZZA_STATUS, ZZA_INDSIT, ZZA_USER, ZZA_HORA, D_E_L_E_T_) "
        cQuery += "VALUES ("
        cQuery += "'" + xFilial("SB1") + "', "
        cQuery += "'" + DtoS(dDataBase) + "', "
        cQuery += "'" + AllTrim(cProduto) + "', "
        cQuery += "'" + StrTran(AllTrim(cDescri), "'", "") + "', "
        cQuery += "'" + AllTrim(cLocal) + "', "
        cQuery += cValToChar(nSaldoSis) + ", "
        cQuery += cValToChar(nQtdCont) + ", "
        cQuery += cValToChar(nDiferenca) + ", "
        cQuery += cValToChar(nVlrUni) + ", "
        cQuery += cValToChar(nTotal) + ", "
        cQuery += "'" + StrTran(AllTrim(cMotivos), "'", "") + "', "
        cQuery += "'" + StrTran(AllTrim(cObserv), "'", "") + "', "
        cQuery += "'" + cStatus + "', "
        cQuery += "'" + cIndSit + "', "
        cQuery += "'" + AllTrim(cUserName) + "', "
        cQuery += "'" + Time() + "', "
        cQuery += "'')"
    EndIf
    
    // Executa a query
    If TcSqlExec(cQuery) < 0
        MsgAlert("Erro ao gravar!" + CRLF + TcSqlError(), "Erro SQL")
        Return .F.
    EndIf
    
    MsgInfo("Registro gravado com sucesso!", "Sucesso")
    
Return .T.
//=================================================================================
// Função: MontaMotivos
// Descrição: Monta string com os motivos de divergência selecionados
// Percorre todos os check boxes e concatena os motivos marcados
// Retorno: cMotivos - String com motivos separados por ';'
//=================================================================================
Static Function MontaMotivos()
    Local cMotivos := ""
    
    // Verifica cada check box e adiciona o motivo correspondente
    If lChk1
        cMotivos += "Falta de Baixa; "
    EndIf
    If lChk2
        cMotivos += "Retirada Sem Requisicao; "
    EndIf
    If lChk3
        cMotivos += "Retirada Emergencial; "
    EndIf
    If lChk4
        cMotivos += "Unidade de Medida Incorreta; "
    EndIf
    If lChk5
        cMotivos += "Pedido de Compra Nao Gerado; "
    EndIf
    If lChk6
        cMotivos += "Perda ou Extravio; "
    EndIf
    If lChk7
        cMotivos += "Avaria de Material; "
    EndIf
    If lChk8
        cMotivos += "Ajuste de Estoque Nao Realizado; "
    EndIf
    If lChk9 .And. !Empty(cOutro)
        cMotivos += "Outro: " + AllTrim(cOutro) + "; "
    EndIf
Return cMotivos
//=================================================================================
// Função: ValidaCheckUnico
// Descrição: Garante que apenas 1 checkbox fique marcado (comportamento radio)
//            CORRIGIDO: Não bloqueia mais os botões Confirmar/Cancelar
// Parâmetros: nCheck - Número do checkbox marcado (1 a 9)
//             oChk1 a oChk9 - Referência aos objetos checkbox
//=================================================================================
Static Function ValidaCheckUnico(nCheck, oChk1, oChk2, oChk3, oChk4, oChk5, oChk6, oChk7, oChk8, oChk9)
    Local nDiferenca := nQtdCont - nSaldoSis
    
    // Se estoque está correto, desmarca SILENCIOSAMENTE (não pode ter justificativa)
    If nDiferenca == 0
        Do Case
            Case nCheck == 1
                lChk1 := .F.
                oChk1:Refresh()
            Case nCheck == 2
                lChk2 := .F.
                oChk2:Refresh()
            Case nCheck == 3
                lChk3 := .F.
                oChk3:Refresh()
            Case nCheck == 4
                lChk4 := .F.
                oChk4:Refresh()
            Case nCheck == 5
                lChk5 := .F.
                oChk5:Refresh()
            Case nCheck == 6
                lChk6 := .F.
                oChk6:Refresh()
            Case nCheck == 7
                lChk7 := .F.
                oChk7:Refresh()
            Case nCheck == 8
                lChk8 := .F.
                oChk8:Refresh()
            Case nCheck == 9
                lChk9 := .F.
                oChk9:Refresh()
        EndCase
    EndIf
    
    // Sempre retorna .T. para permitir marcação livre
    // A validação de "apenas 1" acontecerá no botão Confirmar
Return .T.

// SEMPRE retorna .T. para não bloquear
//-------------------------------------------------------------------
/*/{Protheus.doc} AtualizaCheckboxes
Habilita/desabilita checkboxes conforme divergência
@param oChk1 a oChk9 - Objetos checkbox
@return Nil
/*/
//-------------------------------------------------------------------
Static Function AtualizaCheckboxes(oChk1, oChk2, oChk3, oChk4, oChk5, oChk6, oChk7, oChk8, oChk9, oGetOutro)
    Local nDiferenca := nQtdCont - nSaldoSis
    Local lHabilita  := (nDiferenca != 0)  // Só habilita se houver divergência
    
    // Habilita/desabilita todos os checkboxes
    oChk1:lActive := lHabilita
    oChk2:lActive := lHabilita
    oChk3:lActive := lHabilita
    oChk4:lActive := lHabilita
    oChk5:lActive := lHabilita
    oChk6:lActive := lHabilita
    oChk7:lActive := lHabilita
    oChk8:lActive := lHabilita
    oChk9:lActive := lHabilita
    
    // Desabilita campo "Outro" também
    oGetOutro:lActive := lHabilita
    
    // Se ficou desabilitado, limpa as marcações
    If !lHabilita
        lChk1 := .F. ; oChk1:Refresh()
        lChk2 := .F. ; oChk2:Refresh()
        lChk3 := .F. ; oChk3:Refresh()
        lChk4 := .F. ; oChk4:Refresh()
        lChk5 := .F. ; oChk5:Refresh()
        lChk6 := .F. ; oChk6:Refresh()
        lChk7 := .F. ; oChk7:Refresh()
        lChk8 := .F. ; oChk8:Refresh()
        lChk9 := .F. ; oChk9:Refresh()
        cOutro := Space(100)
        oGetOutro:Refresh()
    EndIf
    
Return
//=================================================================================
// Função: MarcarAjust
// Descrição: Marca o registro selecionado como "Ajustado"
//            Altera o status para "AJUSTADO" e o indicador para "A"
// Retorno: Nil
//=================================================================================
User Function MarcarAjust(oBrowse)
    Local cTable := "ZZA" + cEmpAnt + "3"
    Local cQuery := ""
    Local nRecno := 0
    
    // Valida se há registro selecionado
    If (cAliasQry)->(Eof()) .Or. (cAliasQry)->(Bof())
        MsgAlert("Nenhum registro selecionado", "Atencao")
        Return
    EndIf
    
    // Obtém o RECNO da linha selecionada
    nRecno := (cAliasQry)->NRECZZA
    
    If nRecno <= 0 .Or. nRecno == Nil
        MsgAlert("RECNO invalido", "Atencao")
        Return
    EndIf
    
    // Solicita confirmação
    If !MsgYesNo("Confirma marcar este registro como AJUSTADO?", "Confirmacao")
        Return
    EndIf
    
    // Monta UPDATE para marcar como ajustado
    cQuery := "UPDATE " + cTable + " "
    cQuery += "SET ZZA_STATUS = 'AJUSTADO', "
    cQuery += "    ZZA_INDSIT = 'A', "
    cQuery += "    ZZA_DTAJUS = '" + DtoS(Date()) + "' "
    cQuery += "WHERE R_E_C_N_O_ = " + cValToChar(nRecno)
    
    // Executa o UPDATE
    If TcSqlExec(cQuery) < 0
        MsgAlert("Erro ao marcar como ajustado: " + TcSqlError(), "Erro")
        Return
    EndIf
    
    MsgInfo("Registro marcado como AJUSTADO com sucesso!", "Sucesso")
    
    // *** ATUALIZAÇÃO CORRETA - REEXECUTA A QUERY ***
    AtualizaBrowse(oBrowse)
    
Return
//=================================================================================
// Função: VerificaCampos
// Descrição: Verifica e adiciona campos novos na tabela ZZA caso não existam
// Campos adicionados:
//   - ZZA_VLRUNI: Valor unitário do produto (custo médio)
//   - ZZA_DTAJUS: Data em que o item foi marcado como ajustado
// Retorno: .T. se verificação foi bem sucedida
//=================================================================================
Static Function VerificaCampos()
    Local cTable := "ZZA" + cEmpAnt + "3"
    Local cQuery := ""
    Local lTemVlrTot := .F.  // *** NOVO ***
    
    // *** ADICIONE ESTA VERIFICAÇÃO ***
    // Verifica se campo ZZA_VLRTOT existe
    cQuery := "SELECT COUNT(*) AS QTD "
    cQuery += "FROM INFORMATION_SCHEMA.COLUMNS "
    cQuery += "WHERE TABLE_NAME = '" + cTable + "' "
    cQuery += "AND COLUMN_NAME = 'ZZA_VLRTOT'"
    
    If Select("TMPCHK3") > 0
        TMPCHK3->(DbCloseArea())
    EndIf
    
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TMPCHK3", .F., .T.)
    
    If TMPCHK3->QTD > 0
        lTemVlrTot := .T.
    EndIf
    
    TMPCHK3->(DbCloseArea())
    
    // Se não existir ZZA_VLRTOT, cria
    If !lTemVlrTot
        cQuery := "ALTER TABLE " + cTable + " "
        cQuery += "ADD ZZA_VLRTOT FLOAT NOT NULL DEFAULT 0"
        
        If TcSqlExec(cQuery) < 0
            MsgAlert("Erro ao criar campo ZZA_VLRTOT: " + TcSqlError(), "Erro")
            Return .F.
        Else
            MsgInfo("Campo ZZA_VLRTOT criado com sucesso!", "Sucesso")
        EndIf
    EndIf
    
Return .T.

//=================================================================================
// Função: AtuVlrUnit
// Descrição: Atualiza valor unitário de todos os registros zerados
// Executar após adicionar o campo ZZA_VLRUNI pela primeira vez
// Pode ser executada quantas vezes for necessário
//=================================================================================
User Function AtuVlrUnit()
    Local cTable := "ZZA" + cEmpAnt + "3"
    Local cQuery := ""
    Local nCont := 0
    Local nTotal := 0
    Local nVlr := 0
    
    If !MsgYesNo("Esta rotina vai atualizar o valor unitario de todos os registros zerados." + CRLF + CRLF + ;
                 "Isso pode demorar alguns minutos dependendo da quantidade de registros." + CRLF + CRLF + ;
                 "Confirma a execucao?", "Confirmacao")
        Return
    EndIf
    
    // Busca registros com valor unitário zerado
    cQuery := "SELECT R_E_C_N_O_ AS RECNO, ZZA_PROD, ZZA_LOCAL "
    cQuery += "FROM " + cTable + " "
    cQuery += "WHERE D_E_L_E_T_ = ' ' "
    cQuery += "AND (ZZA_VLRUNI = 0 OR ZZA_VLRUNI IS NULL) "
    
    If Select("TMPATU") > 0
        TMPATU->(DbCloseArea())
    EndIf
    
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TMPATU", .F., .T.)
    
    If TMPATU->(Eof())
        MsgInfo("Nao ha registros com valor unitario zerado para atualizar.", "Informacao")
        TMPATU->(DbCloseArea())
        Return
    EndIf
    
    // Conta total de registros
    TMPATU->(DbGoTop())
    TMPATU->(DbEval({|| nTotal++}))
    TMPATU->(DbGoTop())
    
    // Processa cada registro
    ProcRegua(nTotal)
    
    While !TMPATU->(Eof())
        nVlr := 0
        
        IncProc("Atualizando registro " + cValToChar(nCont+1) + " de " + cValToChar(nTotal) + "...")
        
        // Tenta buscar valor unitário do produto no SB2
        DbSelectArea("SB2")
        SB2->(DbSetOrder(1)) // Filial + Produto + Armazém
        
        If SB2->(DbSeek(xFilial("SB2") + TMPATU->ZZA_PROD + TMPATU->ZZA_LOCAL))
            // Prioridade 1: Custo médio
            If SB2->B2_CM1 > 0
                nVlr := SB2->B2_CM1
            // Prioridade 2: Valor atual / quantidade
            ElseIf SB2->B2_VATU1 > 0 .And. SB2->B2_QATU > 0
                nVlr := SB2->B2_VATU1 / SB2->B2_QATU
            EndIf
        EndIf
        
        // Se não encontrou no SB2, busca no cadastro de produtos (SB1)
        If nVlr == 0
            DbSelectArea("SB1")
            SB1->(DbSetOrder(1)) // Filial + Código
            
            If SB1->(DbSeek(xFilial("SB1") + TMPATU->ZZA_PROD))
                // Prioridade 3: Custo standard
                If SB1->B1_CUSTD > 0
                    nVlr := SB1->B1_CUSTD
                // Prioridade 4: Último preço de compra
                ElseIf SB1->B1_UPRC > 0
                    nVlr := SB1->B1_UPRC
                // Prioridade 5: Preço de venda / 1.5 (estimativa de custo)
                ElseIf SB1->B1_PRV1 > 0
                    nVlr := SB1->B1_PRV1 / 1.5
                EndIf
            EndIf
        EndIf
        
        // Se encontrou algum valor, atualiza o registro
        If nVlr > 0
            cQuery := "UPDATE " + cTable + " "
            cQuery += "SET ZZA_VLRUNI = " + cValToChar(nVlr) + " "
            cQuery += "WHERE R_E_C_N_O_ = " + cValToChar(TMPATU->RECNO)
            
            If TcSqlExec(cQuery) >= 0
                nCont++
            EndIf
        EndIf
        
        TMPATU->(DbSkip())
    EndDo
    
    TMPATU->(DbCloseArea())
    
    MsgInfo("Atualizacao concluida!" + CRLF + CRLF + ;
            "Total de registros processados: " + cValToChar(nTotal) + CRLF + ;
            "Registros atualizados: " + cValToChar(nCont) + CRLF + ;
            "Registros sem custo: " + cValToChar(nTotal - nCont), "Sucesso")
Return
//=================================================================================
// Função: AtualizaBrowse
// Descrição: Atualiza o browse reexecutando a query completa
// Parâmetro: oBrowse - Objeto do browse FWMBrowse
//=================================================================================
Static Function AtualizaBrowse(oBrowse)
    // O browse executa a propria query (SetDataQuery): troca a query
    // no objeto e provoca o refresh. Serve para Inclusao/Alteracao/
    // Exclusao/Marcar Ajustado e Atualizar Valores.
    oBrowse:SetQuery(MontaQuery())
    oBrowse:Refresh(.T.)
    oBrowse:GoTop()
Return
//=================================================================================
// Função: AdicionaCampoTotal
// Descrição: Adiciona o campo ZZA_VLRTOT (Valor Total do Ajuste) na tabela
// Execução: Rodar UMA VEZ ou adicionar no VerificaCampos()
//=================================================================================
User Function AddTotal()
    Local cTable := "ZZA" + cEmpAnt + "3"
    Local cQuery := ""
    Local lTemVlrTot := .F.
    
    // Verifica se campo ZZA_VLRTOT existe
    cQuery := "SELECT COUNT(*) AS QTD "
    cQuery += "FROM INFORMATION_SCHEMA.COLUMNS "
    cQuery += "WHERE TABLE_NAME = '" + cTable + "' "
    cQuery += "AND COLUMN_NAME = 'ZZA_VLRTOT'"
    
    If Select("TMPCHK") > 0
        TMPCHK->(DbCloseArea())
    EndIf
    
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TMPCHK", .F., .T.)
    
    If TMPCHK->QTD > 0
        lTemVlrTot := .T.
    EndIf
    
    TMPCHK->(DbCloseArea())
    
    // Se não existir, cria
    If !lTemVlrTot
        cQuery := "ALTER TABLE " + cTable + " "
        cQuery += "ADD ZZA_VLRTOT FLOAT NOT NULL DEFAULT 0"
        
        If TcSqlExec(cQuery) < 0
            MsgAlert("Erro ao criar campo ZZA_VLRTOT: " + TcSqlError(), "Erro")
            Return .F.
        Else
            MsgInfo("Campo ZZA_VLRTOT criado com sucesso!", "Sucesso")
        EndIf
    Else
        MsgInfo("Campo ZZA_VLRTOT já existe!", "Informação")
    EndIf
    
Return .T.
//=================================================================================
/*/{Protheus.doc} BuscaRapida
Pesquisa por codigo de produto (igual a busca do AxCadastro).
Com o codigo informado, o browse fica somente com o produto pesquisado
(e codigos que iniciam com o mesmo trecho). Com o codigo vazio,
restaura a listagem completa de todos os meses.
@param oBrowse - Objeto do browse FWMBrowse
@return Nil
/*/
//=================================================================================
Static Function BuscaRapida(oBrowse)
    Local aPar  := {}
    Local aRet  := {}
    Local aArea := GetArea()
    
    aAdd(aPar, {1, "Codigo do Produto", Space(15), "@!", "", "", "", 60, .T.})
    
    If !ParamBox(aPar, "Pesquisar Produto", @aRet)
        RestArea(aArea)
        Return
    EndIf
    
    // Sanitiza contra aspas simples (a query e montada por concatenação)
    cBuscaProd := StrTran(AllTrim(aRet[1]), "'", "")
    
    // O browse executa a propria query (SetDataQuery): troca a query
    // no objeto e provoca o refresh para o filtro valer
    oBrowse:SetQuery(MontaQuery())
    oBrowse:Refresh(.T.)
    oBrowse:GoTop()
    
    // Nao achou nenhum registro: avisa e restaura a listagem completa
    If !Empty(cBuscaProd) .And. Select(cAliasQry) > 0 .And. (cAliasQry)->(Eof())
        MsgAlert("Nenhum registro encontrado para o código '" + cBuscaProd + "'.", "Atenção")
        cBuscaProd := ""
        oBrowse:SetQuery(MontaQuery())
        oBrowse:Refresh(.T.)
    EndIf
    
    RestArea(aArea)
Return
//=================================================================================
/*/{Protheus.doc} LimparFiltro
Limpa os filtros e restaura a listagem completa do browse de amostragem.
Remove o filtro nativo do browse (botao Filtrar), via CleanFilter()
documentado no TDN (classe FWFormBrowse, herdada pelo FWMBrowse),
e a pesquisa por codigo de produto (BuscaRapida). Depois reexecuta
a query completa, com todos os meses.
@param oBrowse - Objeto do browse FWMBrowse
@return Nil
/*/
//=================================================================================
Static Function LimparFiltro(oBrowse)
    Local aArea := GetArea()
    
    oBrowse:CleanFilter()
    
    cBuscaProd := ""
    oBrowse:SetQuery(MontaQuery())
    oBrowse:Refresh(.T.)
    oBrowse:GoTop()
    
    RestArea(aArea)
Return
