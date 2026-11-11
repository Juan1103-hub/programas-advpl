#Include "Protheus.ch"
#Include "TopConn.ch"

Static aPedidosSel := {}
Static oBrowseMark
Static lRascSalvo := .F.
Static aColetasCalc := {}   // Array de coletas filtrado usado no calculo de % de frete
Static oSayCalcFrete := Nil // TSay rodape com o calculo de % de frete


/*/{Protheus.doc} NextZZ3
Gera o proximo numero sequencial para ZZ3 (string com zeros a esquerda).
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@return   cNum, character, Proximo numero (ex.: "000123")
/*/
Static Function NextZZ3()
    Local cAlias := GetNextAlias()
    Local nMax := 0

    BeginSql Alias cAlias
        SELECT MAX(ZZ3_NUM) AS MAXNUM
        FROM %Table:ZZ3%
        WHERE %NotDel%
          AND ZZ3_FILIAL = %xFilial:ZZ3%
          AND ZZ3_NUM NOT LIKE 'RASC%'
    EndSql

    If !(cAlias)->(Eof()) .And. !Empty((cAlias)->MAXNUM)
        nMax := Val((cAlias)->MAXNUM)
    EndIf
    (cAlias)->(DbCloseArea())

Return StrZero(nMax + 1, 6)

/*/{Protheus.doc} ZLOGCOL
Entrada principal - abre o browse de controle logistico.
Monta filtro inicial, legenda e ativa o componente de marcacao.
@author  Suprimentos
@since   25/06/2026
/*/
User Function ZLOGCOL()
    Local aColunas := {}

    aColunas := ColunasBrowse()

    oBrowseMark := FWMarkBrowse():New()
    oBrowseMark:SetAlias("SC7")
    oBrowseMark:SetDescription("Controle Logistico - Pedidos APROVADOS - Filial: " + cFilAnt)
    oBrowseMark:SetFieldMark("C7_OK")
    oBrowseMark:SetMark(GetMark(), "SC7", "C7_OK")
    oBrowseMark:SetFilterDefault(FiltroPendentesDBF())

    // Legendas
    oBrowseMark:AddLegend("C7_QUJE==0", "GREEN", "Aprovado - Aguardando coleta")
    oBrowseMark:AddLegend("C7_QUJE>0.And.C7_QUJE<C7_QUANT", "YELLOW", "Aprovado - Recebimento parcial")
    oBrowseMark:AddLegend("C7_QUJE>=C7_QUANT", "RED", "Coletado - Totalmente recebido")

    oBrowseMark:SetColumns(aColunas)

    oBrowseMark:SetMenuDef("ZLOGCOL")

    // Atualizacao leve: nao refaz filtro para nao derrubar pesquisa/posicao do usuario
    oBrowseMark:SetTimer({|| AtualizaBrowse() }, 300000)  // 300000ms = 5 minutos

    oBrowseMark:Activate()
Return

/*/{Protheus.doc} ColunasBrowse
Monta array de colunas para o browse com alias SC7.
Campos lidos diretamente de SC7.

@type Static Function
@author Suprimentos
@since 20/06/2026
/*/
Static Function ColunasBrowse()
    Local aColunas := {}
    Local oColumn

    
// Emissao
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_EMISSAO })
    oColumn:SetTitle("Emissao"); oColumn:SetType("D"); oColumn:SetSize(8); oColumn:SetPicture("@D")
    aAdd(aColunas, oColumn)

    
// Entrega
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_DATPRF })
    oColumn:SetTitle("Entrega"); oColumn:SetType("D"); oColumn:SetSize(8); oColumn:SetPicture("@D")
    aAdd(aColunas, oColumn)

    
// Pedido
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_NUM })
    oColumn:SetTitle("Pedido"); oColumn:SetType("C"); oColumn:SetSize(6); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Fornec
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_FORNECE })
    oColumn:SetTitle("Fornec"); oColumn:SetType("C"); oColumn:SetSize(6); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Loja
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_LOJA })
    oColumn:SetTitle("Loja"); oColumn:SetType("C"); oColumn:SetSize(2); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Produto
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_PRODUTO })
    oColumn:SetTitle("Produto"); oColumn:SetType("C"); oColumn:SetSize(15); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Descricao
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| AllTrim(SC7->C7_DESCRI) })
    oColumn:SetTitle("Descricao"); oColumn:SetType("C"); oColumn:SetSize(40); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Filial
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_FILIAL })
    oColumn:SetTitle("Filial"); oColumn:SetType("C"); oColumn:SetSize(4); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Tipo
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_TIPO })
    oColumn:SetTitle("Tipo"); oColumn:SetType("N"); oColumn:SetSize(1); oColumn:SetPicture("9")
    aAdd(aColunas, oColumn)

    
// Item
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_ITEM })
    oColumn:SetTitle("Item"); oColumn:SetType("C"); oColumn:SetSize(4); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Quantidade
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_QUANT })
    oColumn:SetTitle("Quantidade"); oColumn:SetType("N"); oColumn:SetSize(16); oColumn:SetDecimal(4)
    oColumn:SetPicture("@E 999,999.9999")
    aAdd(aColunas, oColumn)

    
// Unidade
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_UM })
    oColumn:SetTitle("Unidade"); oColumn:SetType("C"); oColumn:SetSize(2); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Atua.Estoque
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_XESTOQ1 })
    oColumn:SetTitle("Atua.Estoque"); oColumn:SetType("C"); oColumn:SetSize(1); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Nat.Gastos
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| AllTrim(SC7->C7_EC05DB) })
    oColumn:SetTitle("Nat.Gastos"); oColumn:SetType("C"); oColumn:SetSize(16); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    // 15 - Tipo Frete
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_TPFRETE })
    oColumn:SetTitle("Tipo Frete"); oColumn:SetType("C"); oColumn:SetSize(1); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Inf. Adic.
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| AllTrim(SC7->C7_ZINFADI) })
    oColumn:SetTitle("Inf. Adic."); oColumn:SetType("C"); oColumn:SetSize(50); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Numero da SC
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_NUMSC })
    oColumn:SetTitle("Numero da SC"); oColumn:SetType("C"); oColumn:SetSize(6); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Segunda UM
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_SEGUM })
    oColumn:SetTitle("Segunda UM"); oColumn:SetType("C"); oColumn:SetSize(2); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Qtd.Entregue
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_QUJE })
    oColumn:SetTitle("Qtd.Entregue"); oColumn:SetType("N"); oColumn:SetSize(16); oColumn:SetDecimal(4)
    oColumn:SetPicture("@E 999,999.9999")
    aAdd(aColunas, oColumn)

    
// Cod. Usuario
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_USER })
    oColumn:SetTitle("Cod. Usuario"); oColumn:SetType("C"); oColumn:SetSize(15); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Status do ME
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_CONAPRO })
    oColumn:SetTitle("Status do ME"); oColumn:SetType("C"); oColumn:SetSize(1); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Grupo (lido de SB1 sob demanda)
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SB1->(Posicione("SB1", 1, xFilial("SB1") + SC7->C7_PRODUTO, "B1_GRUPO")) })
    oColumn:SetTitle("Grupo"); oColumn:SetType("C"); oColumn:SetSize(6); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Origem
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_ORIGEM })
    oColumn:SetTitle("Origem"); oColumn:SetType("C"); oColumn:SetSize(1); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// Incoterm
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| AllTrim(SC7->C7_INCOTER) })
    oColumn:SetTitle("Incoterm"); oColumn:SetType("C"); oColumn:SetSize(5); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

    
// ACC?
    oColumn := FWBrwColumn():New()
    oColumn:SetData({|| SC7->C7_ACCPROC })
    oColumn:SetTitle("ACC?"); oColumn:SetType("C"); oColumn:SetSize(1); oColumn:SetPicture("@!")
    aAdd(aColunas, oColumn)

Return aColunas

//=============================================================================

/*/{Protheus.doc} AtualizaBrowse
Atualiza browse automaticamente (chamada pelo timer).
@type     Static Function
@author   Suprimentos
@since    25/06/2026
/*/
Static Function AtualizaBrowse()
    If oBrowseMark != Nil
        If !TemMarcaAtiva()
            oBrowseMark:Refresh()
        EndIf
    EndIf
Return

/*/{Protheus.doc} MontaFiltroPendentes
Monta filtro base para exibir apenas pedidos pendentes (nao recebidos).
Espelho do FiltroPendentesDBF() para uso em TReport (ZLGPRINT).

Pedidos que ja possuem registro na ZZ3 (rascunho salvo ou coleta
definitiva) NAO sao considerados pendentes: enquanto o pedido estiver
programado ele nao aparece no browse nem na impressao. O pedido volta
a aparecer somente quando o rascunho/coleta for excluido da ZZ3.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@return   cFiltro, character, Filtro SQL para pedidos pendentes
/*/
Static Function MontaFiltroPendentes()
    Local cFiltro := ""
    Local cFilSC7 := xFilial("SC7")

    cFiltro := "C7_RESIDUO <> 'S'"
    cFiltro += " AND C7_FILIAL = '" + cFilSC7 + "'"
    cFiltro += " AND C7_QUJE < C7_QUANT"
    cFiltro += " AND (RTRIM(C7_CONAPRO) IN ('', 'L'))"  // RTRIM cobre campos gravados com espacos
    cFiltro += " AND C7_ENCER <> 'E'"

    // Bloqueia pedidos com PRE-NOTA (C7_QTDACLA), se campo existir
    DbSelectArea("SC7")
    If SC7->(FieldPos("C7_QTDACLA")) > 0
        cFiltro += " AND C7_QTDACLA = 0"
    EndIf

    // Exclui pedidos ja programados (rascunho salvo ou coleta definitiva)
    cFiltro += " AND RTRIM(C7_NUM) NOT IN ("
    cFiltro += "     SELECT RTRIM(ZZ3P.ZZ3_PEDIDO)"
    cFiltro += "     FROM " + RetSqlName("ZZ3") + " ZZ3P"
    cFiltro += "     WHERE ZZ3P.D_E_L_E_T_ = ' '"
    cFiltro += "       AND ZZ3P.ZZ3_FILIAL = '" + xFilial("ZZ3") + "'"
    cFiltro += "       AND RTRIM(ZZ3P.ZZ3_PEDIDO) <> ''"
    cFiltro += " )"

Return cFiltro

/*/{Protheus.doc} FiltroPendentesDBF
Filtro padrao do browse de pedidos aprovados (alias SC7).

O filtro e a mesma regra do MontaFiltroPendentes(), mas devolvido com o
prefixo "@": no TopConnect o "@" indica que a expressao e SQL e deve ser
resolvida direto no banco (aceito pelo SetFilterDefault da FWBrowse).

Motivo: o filtro AdvPL do browse tem limite de 2000 bytes (erro
"SC7010: Filter greater than 2000 bytes" em FWBRWTABLE:EXECUTEFILTER) e a
lista de pedidos programados da ZZ3 estourava esse limite. Com a SQL abaixo
a exclusao dos pedidos ja programados e feita por subconsulta, sem lista de
pedidos no texto do filtro.
@type Static Function
@author Suprimentos
@since 20/06/2026
/*/
Static Function FiltroPendentesDBF()
Return "@" + MontaFiltroPendentes()


/*/{Protheus.doc} MenuDef
Definicao do menu para o browse principal (retorna array de acoes).
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@return   aMenu, array, Array de opcoes do menu
/*/
Static Function MenuDef()
Return {;
    {"Pesquisar","AxPesqui",0,1},;
    {"Programar","U_ZLGPROC()",0,4},;
    {"Consultar","U_ZLGCONS()",0,2},;
    {"Incluir","U_ZLGINC()",0,3},;
    {"Marcar Pedido","U_ZLGMPED()",0,6},;
    {"Desmarcar Pedido","U_ZLGDPED()",0,6},;
    {"Atualizar","U_ZLGFTODOS()",0,6},;
    {"Imprimir Browse","U_ZLGPRINT()",0,6},;
    {"Legenda","U_ZLGLGD()",0,6}}

/*/{Protheus.doc} ZLGFPARC
Aplica filtro para exibir apenas pedidos parciais.
Atualiza descricao e aplica filtro no componente de marcacao.
@author  Suprimentos
@since   25/06/2026
/*/
User Function ZLGFPARC()
    If oBrowseMark != Nil
        oBrowseMark:SetFilterDefault("C7_QUJE > 0 .And. C7_QUJE < C7_QUANT")
        oBrowseMark:ExecuteFilter()
        oBrowseMark:GoTop(.T.)
        oBrowseMark:Refresh(.T.)
        oBrowseMark:SetDescription("Controle Logistico - Pedidos PARCIAIS - Filial: " + cFilAnt)
        MsgInfo("Exibindo apenas pedidos PARCIAIS!", "Filtro Aplicado")
    EndIf
Return

/*/{Protheus.doc} ZLGFTODOS
Restaura filtro padrao (pendentes) no browse.
@author  Suprimentos
@since   25/06/2026
/*/
User Function ZLGFTODOS()
    If oBrowseMark != Nil
        oBrowseMark:SetFilterDefault(FiltroPendentesDBF())
        oBrowseMark:ExecuteFilter()
        oBrowseMark:GoTop(.T.)
        oBrowseMark:Refresh(.T.)

        oBrowseMark:SetDescription("Controle Logistico - Pedidos APROVADOS - Filial: " + cFilAnt)
        MsgInfo("Browse atualizado! Pedidos vermelhos/azuis foram removidos.", "Filtro Aplicado")
    EndIf
Return

/*/{Protheus.doc} ZLGVIS
Exibe dados do fornecedor / item do registro SC7 atual.
@author  Suprimentos
@since   25/06/2026
/*/
User Function ZLGVIS()
    SA2->(DbSetOrder(1))
    If SA2->(DbSeek(xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA))
        MsgInfo("PEDIDO: "+SC7->C7_NUM+" - ITEM: "+SC7->C7_ITEM+CRLF+CRLF+;
                "Produto: "+SC7->C7_PRODUTO+" - "+SC7->C7_DESCRI+CRLF+;
                "Fornecedor: "+SC7->C7_FORNECE+"/"+SC7->C7_LOJA+" - "+SA2->A2_NOME+CRLF+;
                "Emissao: "+DtoC(SC7->C7_EMISSAO)+" | Entrega: "+DtoC(SC7->C7_DATPRF)+CRLF+CRLF+;
                "Qtd: "+Transform(SC7->C7_QUANT,"@E 999,999.99")+" "+SC7->C7_UM+CRLF+;
                "Entregue: "+Transform(SC7->C7_QUJE,"@E 999,999.99"),"Pedido "+SC7->C7_NUM)
    EndIf
Return
//=============================================================================

/*/{Protheus.doc} ValidaFornec
Valida fornecedor e busca dados no SA2.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    cFornec, character, Codigo do fornecedor
@param    cLojaFor, character, Loja do fornecedor (retornada)
@param    cNomeFor, character, Nome do fornecedor (retornado)
@param    oLojaFor, object, Objeto MSGET da loja
@param    oNomeFor, object, Objeto MSGET do nome
@return   lRet, logical, .T. se fornecedor encontrado
/*/
Static Function ValidaFornec(cFornec, cLojaFor, cNomeFor, oLojaFor, oNomeFor)
    Local lRet := .T.

    If !Empty(cFornec)
        DbSelectArea("SA2")
        SA2->(DbSetOrder(1))

        If SA2->(DbSeek(xFilial("SA2") + cFornec))
            cLojaFor := SA2->A2_LOJA
            cNomeFor := SA2->A2_NOME

            oLojaFor:Refresh()
            oNomeFor:Refresh()
        Else
            MsgAlert("Fornecedor nao encontrado!", "")
            lRet := .F.
        EndIf
    Else
        cLojaFor := Space(2)
        cNomeFor := Space(40)
        oLojaFor:Refresh()
        oNomeFor:Refresh()
    EndIf

Return lRet

//=============================================================================

/*/{Protheus.doc} ZLGINC
Inclusao manual de coleta.
@author  Suprimentos
@since   25/06/2026
/*/
User Function ZLGINC()
    Local oDlg
    Local nOpcao := 0

    Local cPedido    := ""
    Local cFornec    := Space(6)
    Local cLojaFor   := Space(2)
    Local cNomeFor   := Space(40)
    Local nPeso      := 0
    Local nVolume    := 0
    Local nValColeta := 0
    Local dColeta    := CToD("")
    Local cTpFrete   := "Dedicado"
    Local cTransp    := Space(6)
    Local cLojaTransp:= Space(2)
    Local cNomeTr    := Space(40)
    Local cObs       := Space(200)
    Local cTpFrete2  := ""

    Local oFornec, oLojaFor, oNomeFor
    Local oPeso, oVolume, oValColeta, oColeta
    Local oTpFrete, oTransp, oLojaTransp, oNomeTr

    DEFINE MSDIALOG oDlg TITLE "Inclusao Manual de Coleta" FROM 0,0 TO 480,500 PIXEL

    // FORNECEDOR (pode manter)
    @ 010,010 SAY "Fornecedor:" SIZE 050,010 PIXEL OF oDlg
    @ 008,070 MSGET oFornec VAR cFornec SIZE 040,010 PIXEL OF oDlg F3 "SA2" ;
              VALID ValidaFornec(@cFornec, @cLojaFor, @cNomeFor, oLojaFor, oNomeFor)
    @ 010,115 SAY "Loja:" SIZE 020,010 PIXEL OF oDlg
    @ 008,135 MSGET oLojaFor VAR cLojaFor SIZE 025,010 WHEN .F. PIXEL OF oDlg
    @ 022,070 MSGET oNomeFor VAR cNomeFor SIZE 150,010 WHEN .F. PIXEL OF oDlg

    // PESO
    @ 036,010 SAY "Peso:" SIZE 050,010 PIXEL OF oDlg
    @ 034,070 MSGET oPeso VAR nPeso SIZE 060,010 PICTURE "@E 999,999.9" PIXEL OF oDlg

    // VOLUME
    @ 050,010 SAY "Volume:" SIZE 050,010 PIXEL OF oDlg
    @ 048,070 MSGET oVolume VAR nVolume SIZE 060,010 PICTURE "@E 999999" PIXEL OF oDlg

    // VALOR COLETA
    @ 064,010 SAY "Valor Coleta:" SIZE 050,010 PIXEL OF oDlg
    @ 062,070 MSGET oValColeta VAR nValColeta SIZE 060,010 PICTURE "@E 999,999.99" PIXEL OF oDlg

    // DT. COLETA
    @ 078,010 SAY "Dt. Coleta:" SIZE 050,010 PIXEL OF oDlg
    @ 076,070 MSGET oColeta VAR dColeta SIZE 060,010 ;
              VALID IIf(Empty(dColeta), (MsgAlert("Data de coleta obrigatoria!",""), .F.), ;
                    IIf(dColeta < dDataBase, (MsgAlert("Data invalida!",""), .F.), .T.)) ;
              PIXEL OF oDlg

    // TIPO FRETE
    @ 092,010 SAY "Tipo Frete:" SIZE 050,010 PIXEL OF oDlg
    @ 090,070 COMBOBOX oTpFrete VAR cTpFrete ITEMS {"Dedicado","Fracionado"} ;
              SIZE 080,010 PIXEL OF oDlg

    // TRANSPORTADORA
    @ 106,010 SAY "Transportadora:" SIZE 055,010 PIXEL OF oDlg
    @ 104,070 MSGET oTransp VAR cTransp SIZE 040,010 PIXEL OF oDlg F3 "SA2" ;
              VALID ValidaTransp(@cTransp, @cLojaTransp, @cNomeTr, oLojaTransp, oNomeTr)
    @ 106,115 SAY "Loja:" SIZE 020,010 PIXEL OF oDlg
    @ 104,135 MSGET oLojaTransp VAR cLojaTransp SIZE 020,010 WHEN .F. PIXEL OF oDlg
    @ 118,070 MSGET oNomeTr VAR cNomeTr SIZE 165,010 WHEN .F. PIXEL OF oDlg

    // OBS
    @ 134,010 SAY "Obs:" SIZE 050,010 PIXEL OF oDlg
    @ 146,010 GET cObs MEMO SIZE 230,050 OF oDlg PIXEL

    // BOTOES (ok, cancelar)
    @ 181,120 BUTTON "OK"       SIZE 040,012 PIXEL OF oDlg ACTION (nOpcao := 1, oDlg:End())
    @ 181,170 BUTTON "Cancelar" SIZE 040,012 PIXEL OF oDlg ACTION (nOpcao := 0, oDlg:End())

    ACTIVATE MSDIALOG oDlg CENTERED

    If nOpcao == 1
        If Empty(dColeta)
            MsgAlert("Informe a data de coleta!", "Atencao")
            Return
        EndIf

        If dColeta < dDataBase
            MsgAlert("Data de coleta nao pode ser anterior a data atual!", "Atencao")
            Return
        EndIf

        If Empty(cTransp)
            MsgAlert("Informe a transportadora!", "Atencao")
            Return
        EndIf

        cPedido := NextZZ3()

        If GrvIncManual(cPedido, cFornec, cLojaFor, cNomeFor, nPeso, nVolume, nValColeta, dColeta, cTpFrete, cTransp, cLojaTransp, cNomeTr, cObs, cTpFrete2)
            MsgInfo("Coleta incluida com sucesso!" + CRLF + "Numero: " + cPedido, "Sucesso")

            If oBrowseMark != Nil
                oBrowseMark:SetFilterDefault(FiltroPendentesDBF())
                oBrowseMark:ExecuteFilter()
                oBrowseMark:GoTop(.T.)
                oBrowseMark:Refresh(.T.)
            EndIf
        Else
            MsgAlert("Erro ao incluir coleta!", "Erro")
        EndIf
    EndIf

Return


/*/{Protheus.doc} GrvIncManual
Grava coleta manual na tabela ZZ3.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    cPedido, character, Numero do pedido de coleta
@param    cFornec, character, Codigo do fornecedor
@param    cLojaFor, character, Loja do fornecedor
@param    cNomeFor, character, Nome do fornecedor
@param    nPeso, numeric, Peso da coleta
@param    nVolume, numeric, Volume da coleta
@param    nValColeta, numeric, Valor da coleta
@param    dColeta, date, Data da coleta
@param    cTpFrete, character, Tipo de frete
@param    cTransp, character, Codigo da transportadora
@param    cLojaTransp, character, Loja da transportadora
@param    cNomeTr, character, Nome da transportadora
@param    cObs, character, Observacao
@param    cTpFrete2, character, Tipo de frete 2
@return   lRet, logical, .T. se gravou com sucesso
/*/
Static Function GrvIncManual(cPedido, cFornec, cLojaFor, cNomeFor, nPeso, nVolume, nValColeta, dColeta, cTpFrete, cTransp, cLojaTransp, cNomeTr, cObs, cTpFrete2)

    Local lRet := .T.

    Begin Transaction

    DbSelectArea("ZZ3")
    RecLock("ZZ3", .T.)

    ZZ3->ZZ3_FILIAL := xFilial("ZZ3")
    ZZ3->ZZ3_NUM    := cPedido

    // PEDIDO E STATUS - deixados vazios intencionalmente
    ZZ3->ZZ3_PEDIDO := ""
    ZZ3->ZZ3_STATUS := ""

    // FORNECEDOR
    ZZ3->ZZ3_FORNEC := cFornec
    ZZ3->ZZ3_LOJA   := cLojaFor
    ZZ3->ZZ3_NOMFOR := cNomeFor

    // DATAS
    ZZ3->ZZ3_DTCOLE := dColeta

    // DADOS COLETA
    ZZ3->ZZ3_PESO   := nPeso
    ZZ3->ZZ3_VOLUME := Int(nVolume)
    ZZ3->ZZ3_VALCOL := nValColeta

    // FRETE E TRANSPORTADORA
    ZZ3->ZZ3_TPFRET := cTpFrete
    ZZ3->ZZ3_TRANSP := cTransp
    ZZ3->ZZ3_LOJTRA := cLojaTransp
    ZZ3->ZZ3_NOMTRA := cNomeTr

    // OBS
    ZZ3->ZZ3_OBS := cObs

    // CONTROLE
    ZZ3->ZZ3_USUPRO := UsrRetName(RetCodUsr())
    ZZ3->ZZ3_DTPROG := Date()
    ZZ3->ZZ3_HRPROG := Time()

    MsUnlock()

    End Transaction

Return lRet




/*/{Protheus.doc} ZLGMALL
Marca todos os pedidos pendentes (item-nivel).
Criterio: C7_QUJE < C7_QUANT E C7_QTDACLA == 0 (se campo existir).
A PRESENCA em ZZ3 NAO bloqueia: itens que ja foram programados mas
continuam pendentes (sem pre-nota) tambem sao marcados para a 2a coleta.
@author  Suprimentos
@since   25/06/2026
/*/
User Function ZLGMALL()
    Local aArea := GetArea()
    Local cM:=MarcaBrowse()
    Local cAlias := GetNextAlias()
    Local lTemQtdAc := .F.
    Local lPodeMarcar := .T.
    Local nMarcados := 0

    If !MsgYesNo("Confirma marcar todos os pedidos pendentes da filial?", "Confirmar")
        RestArea(aArea)
        Return
    EndIf

    DbSelectArea("SC7")
    lTemQtdAc := (SC7->(FieldPos("C7_QTDACLA")) > 0)

    // Busca registros elegiveis via SQL e marca via RECNO
    cAlias := GetNextAlias()
    BeginSql Alias cAlias
        SELECT R_E_C_N_O_ AS RECNO, C7_NUM
        FROM %Table:SC7%
        WHERE %NotDel%
          AND C7_FILIAL = %xFilial:SC7%
          AND C7_RESIDUO <> 'S'
          AND C7_QUJE < C7_QUANT
          AND (RTRIM(C7_CONAPRO) IN ('', 'L'))
          AND C7_ENCER <> 'E'
          AND RTRIM(C7_OK) = ''
    EndSql

    DbSelectArea("SC7")
    While !(cAlias)->(Eof())
        SC7->(DbGoTo((cAlias)->RECNO))
        lPodeMarcar := .T.
        If lTemQtdAc
            lPodeMarcar := (SC7->C7_QTDACLA == 0)
        EndIf

        If lPodeMarcar
            RecLock("SC7",.F.)
            SC7->C7_OK:=cM
            MsUnlock()
            nMarcados++
        EndIf
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    oBrowseMark:Refresh()
    MsgInfo("Marcados! Total: " + cValToChar(nMarcados) + " item(ns).","Sucesso")
    RestArea(aArea)
Return


/*/{Protheus.doc} ZLGDALL
Desmarca todos os pedidos (limpa C7_OK) - usa SQL para buscar apenas marcados.
@author  Suprimentos
@since   25/06/2026
/*/
User Function ZLGDALL()
    Local aArea := GetArea()
    Local cAlias := GetNextAlias()
    Local cM := MarcaBrowse()

    If !MsgYesNo("Confirma desmarcar todos os pedidos marcados por ", "Confirmar")
        RestArea(aArea)
        Return
    EndIf

    BeginSql Alias cAlias
        SELECT R_E_C_N_O_ AS RECNO
        FROM %Table:SC7%
        WHERE %NotDel%
          AND C7_FILIAL = %xFilial:SC7%
          AND RTRIM(C7_OK) = %Exp:AllTrim(cM)%
    EndSql

    DbSelectArea("SC7")
    While !(cAlias)->(Eof())
        SC7->(DbGoTo((cAlias)->RECNO))
        RecLock("SC7",.F.)
        SC7->C7_OK:=Space(2)
        MsUnlock()
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    oBrowseMark:Refresh()
    MsgInfo("Desmarcados!","Sucesso")
    RestArea(aArea)
Return


/*/{Protheus.doc} ZLGMPED
Marca todos os itens elegiveis do pedido atual, preservando o filtro/pesquisa do browse.
@author  Suprimentos
@since   25/06/2026
/*/
User Function ZLGMPED()
    MarcaPedidoAtual(.T.)
Return


/*/{Protheus.doc} ZLGDPED
Desmarca todos os itens do pedido atual marcados pelo usuario atual.
@author  Suprimentos
@since   25/06/2026
/*/
User Function ZLGDPED()
    MarcaPedidoAtual(.F.)
Return


/*/{Protheus.doc} MarcaPedidoAtual
Marca/desmarca itens do pedido atual com validacao item-nivel.

REGRAS (item-nivel):
 - Ao marcar: pula itens ja presentes em ZZ3_ITENS definitivo E itens
   com C7_QTDACLA > 0 (em pre-nota).
 - Permite marcar itens que ja tiveram coleta anterior mas continuam
   pendentes (sem pre-nota), viabilizando 2a coleta.
 - Ao desmarcar: remove apenas a marca do usuario atual (igual antes).
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    lMarcar, logical, .T. para marcar, .F. para desmarcar
/*/
Static Function MarcaPedidoAtual(lMarcar)
    Local aArea := GetArea()
    Local cPedido := ""
    Local cMarca := ""
    Local nQtd := 0
    Local nQtdJaProg := 0
    Local lTemQtdAc := .F.
    Local cAlias
    Local cQuery := ""
    Local cItemSC7 := ""

    Default lMarcar := .T.

    If oBrowseMark == Nil
        MsgAlert("Browse nao inicializado!", "")
        RestArea(aArea)
        Return
    EndIf

    DbSelectArea("SC7")
    cPedido := AllTrim(SC7->C7_NUM)
    cMarca := MarcaBrowse()

    If Empty(cMarca)
        MsgAlert("Nao foi possivel identificar a marca do usuario para marcar/desmarcar o pedido.", "")
        RestArea(aArea)
        Return
    EndIf

    If Empty(cPedido)
        MsgAlert("Nenhum pedido posicionado no browse!", "")
        RestArea(aArea)
        Return
    EndIf

    lTemQtdAc := (SC7->(FieldPos("C7_QTDACLA")) > 0)
    cAlias := GetNextAlias()

    // Busca registros elegiveis via SQL (bypassa filtro @ do FWMarkBrowse)
    cQuery := "SELECT R_E_C_N_O_ AS RECNO, C7_ITEM, C7_QTDACLA FROM " + RetSqlName("SC7")
    cQuery += " WHERE D_E_L_E_T_ = ' '"
    cQuery += "   AND C7_FILIAL = '" + xFilial("SC7") + "'"
    cQuery += "   AND C7_NUM = '" + cPedido + "'"

    If lMarcar
        cQuery += " AND C7_RESIDUO <> 'S'"
        cQuery += " AND C7_QUJE < C7_QUANT"
        cQuery += " AND (RTRIM(C7_CONAPRO) IN ('', 'L'))"
        cQuery += " AND C7_ENCER <> 'E'"
        If lTemQtdAc
            cQuery += " AND C7_QTDACLA = 0"
        EndIf
    Else
        cQuery += " AND RTRIM(C7_OK) = '" + AllTrim(cMarca) + "'"
    EndIf

    cQuery := ChangeQuery(cQuery)

    If Select(cAlias) > 0
        (cAlias)->(DbCloseArea())
    EndIf
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    If (cAlias)->(Eof())
        (cAlias)->(DbCloseArea())
        RestArea(aArea)
        If lMarcar
            MsgAlert("Pedido " + cPedido + " nao possui itens disponiveis para marcar (todos em pre-nota, entregues ou ja programados).", "")
        Else
            MsgInfo("Pedido " + cPedido + ": nenhum item desmarcado.", "Desmarcar Pedido")
        EndIf
        Return
    EndIf

    BEGIN TRANSACTION
    DbSelectArea("SC7")
    While !(cAlias)->(Eof())
        SC7->(DbGoTo((cAlias)->RECNO))
        cItemSC7 := AllTrim((cAlias)->C7_ITEM)

        If lMarcar
            // Pula item ja em ZZ3_ITENS definitivo (ja programado)
            If ItemEmZZ3(cPedido, cItemSC7)
                nQtdJaProg++
                (cAlias)->(DbSkip())
                Loop
            EndIf
        EndIf

        RecLock("SC7", .F.)
        If lMarcar
            SC7->C7_OK := cMarca
        Else
            SC7->C7_OK := Space(2)
        EndIf
        MsUnlock()
        nQtd++
        (cAlias)->(DbSkip())
    EndDo
    END TRANSACTION
    (cAlias)->(DbCloseArea())

    RestArea(aArea)

    If oBrowseMark != Nil
        // Reconstroi o browse (filtro padrao + filtros do usuario) para que a
        // coluna de marca/desmarca seja lida novamente do SC7. O Refresh()
        // sozinho nao repintava as marcas quando o browse estava filtrado.
        oBrowseMark:SetFilterDefault(FiltroPendentesDBF())
        oBrowseMark:ExecuteFilter()
        oBrowseMark:GoTop(.T.)
        oBrowseMark:Refresh(.T.)
    EndIf

    If lMarcar
        If nQtd == 0
            MsgAlert("Nenhum item foi marcado!" + CRLF + CRLF + ;
                     "Pedido " + cPedido + ": os itens disponiveis deste pedido ja estao programados (possuem coleta), em pre-nota ou ja foram entregues." + CRLF + CRLF + ;
                     "Pedido ja programado nao deve ser marcado novamente: ele sai do browse quando a coleta e gravada.", "Marcar Pedido")
        ElseIf nQtdJaProg > 0
            MsgInfo("Pedido " + cPedido + ": " + cValToChar(nQtd) + " item(ns) marcado(s)." + CRLF + ;
                    cValToChar(nQtdJaProg) + " item(ns) ja programado(s) foram ignorados.", "Marcar Pedido")
        Else
            MsgInfo("Pedido " + cPedido + ": " + cValToChar(nQtd) + " item(ns) marcado(s).", "Marcar Pedido")
        EndIf
    Else
        If nQtd == 0
            MsgInfo("Pedido " + cPedido + ": nenhum item estava marcado para desmarcar.", "Desmarcar Pedido")
        Else
            MsgInfo("Pedido " + cPedido + ": " + cValToChar(nQtd) + " item(ns) desmarcado(s).", "Desmarcar Pedido")
        EndIf
    EndIf
Return

/*/{Protheus.doc} ItemEmZZ3
Verifica se um item especifico do pedido ja esta programado em
alguma coleta definitiva (nao-rascunho) na ZZ3.

Importante: o match usa zero-fill de 2 digitos (padrao C7_ITEM) e
delimitadores "," para evitar match parcial (ex: item "01" NAO
deve casar com "10" ou "11").

@param cPedido  Numero do pedido de compra (SC7)
@param cItem    Item do pedido (com ou sem zero-fill)
@return Logical .T. se o item esta em qualquer coleta definitiva
@since  25/06/2026
/*/
Static Function ItemEmZZ3(cPedido, cItem)
    Local cAlias   := GetNextAlias()
    Local lExiste  := .F.
    Local cItens   := ""
    Local cItemZ   := ""
    Local cProcur  := ""

    If Empty(AllTrim(cPedido)) .Or. Empty(AllTrim(cItem))
        Return .F.
    EndIf

    // Garante zero-fill de 2 digitos para o item buscado
    cItemZ  := StrZero(Val(AllTrim(cItem)), 2)
    cProcur := "," + cItemZ + ","

    BeginSql Alias cAlias
        SELECT ZZ3_ITENS
        FROM %Table:ZZ3%
        WHERE %NotDel%
          AND ZZ3_FILIAL = %xFilial:ZZ3%
          AND ZZ3_PEDIDO = %Exp:AllTrim(cPedido)%
          AND ZZ3_NUM NOT LIKE 'RASC%'
    EndSql

    While !(cAlias)->(Eof())
        cItens := "," + AllTrim((cAlias)->ZZ3_ITENS) + ","
        If cProcur $ cItens
            lExiste := .T.
            Exit
        EndIf
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

Return lExiste

Static Function TemMarcaAtiva()
    Local cAlias := GetNextAlias()
    Local cMarca := ""
    Local lRet := .F.

    If oBrowseMark == Nil
        Return .F.
    EndIf

    cMarca := MarcaBrowse()

    If Empty(cMarca)
        Return .F.
    EndIf

    BeginSql Alias cAlias
        SELECT COUNT(*) AS QTD
        FROM %Table:SC7%
        WHERE %NotDel%
          AND C7_FILIAL = %xFilial:SC7%
          AND RTRIM(C7_OK) = %Exp:cMarca%
    EndSql

    If !(cAlias)->(Eof())
        lRet := ((cAlias)->QTD > 0)
    EndIf

    (cAlias)->(DbCloseArea())
Return lRet

/*/{Protheus.doc} MarcaBrowse
Retorna a marca usada pelo FWMarkBrowse para identificar os registros
marcados pelo usuario atual. A marca configurada no browse vem de
GetMark(); se o metodo Mark() nao devolver nada, usa GetMark() para nao
gravar marca vazia no registro.
@type     Static Function
@author   Suprimentos
@since    05/11/2026
@return   cMarca, character, Marca do usuario atual
/*/
Static Function MarcaBrowse()
    Local cMarca := ""

    If oBrowseMark != Nil
        cMarca := AllTrim(oBrowseMark:Mark())
    EndIf

    If Empty(cMarca)
        cMarca := AllTrim(GetMark())
    EndIf

Return cMarca


/*/{Protheus.doc} ZLGPROC
Inicia processo de programacao e montagem do array aPedidosSel.
@author  Suprimentos
@since   25/06/2026
/*/
User Function ZLGPROC()
    Local cM := MarcaBrowse()
    Local cAlias := GetNextAlias()
    Local cAliasVal := GetNextAlias()
    Local cAliasProg := GetNextAlias()
    Local cAliasRasc := GetNextAlias()
    Local aPedIncompletos := {}
    Local aPedProgramados := {}
    Local cMsg := ""
    Local i
    Local nQtdMarcados := 0
    Local nQtdRasc := 0
    Local lTemQtdAc := .F.
    Local lPodeMarcar := .F.

    DbSelectArea("SC7")
    lTemQtdAc := (SC7->(FieldPos("C7_QTDACLA")) > 0)

    // Verifica se existem pedidos marcados no browse
    BeginSql Alias cAliasRasc
        SELECT COUNT(DISTINCT C7_NUM) AS QTD
        FROM %Table:SC7% SC7
        WHERE %NotDel%
          AND C7_FILIAL = %xFilial:SC7%
          AND C7_RESIDUO <> 'S'
          AND RTRIM(C7_OK) = %Exp:AllTrim(cM)%
          AND NOT EXISTS (
              SELECT 1
              FROM %Table:ZZ3% ZZ3R
              WHERE ZZ3R.D_E_L_E_T_ = ' '
                AND ZZ3R.ZZ3_FILIAL = %xFilial:ZZ3%
                AND ZZ3R.ZZ3_PEDIDO = SC7.C7_NUM
                AND ZZ3R.ZZ3_NUM LIKE 'RASC%'
          )
    EndSql
    If !(cAliasRasc)->(Eof())
        nQtdMarcados := (cAliasRasc)->QTD
    EndIf
    (cAliasRasc)->(DbCloseArea())

    // Se nenhum pedido marcado, verifica se existe rascunho salvo
    If nQtdMarcados == 0
        cAliasRasc := GetNextAlias()
        BeginSql Alias cAliasRasc
            SELECT COUNT(*) AS QTD
            FROM %Table:ZZ3%
            WHERE %NotDel%
              AND ZZ3_FILIAL = %xFilial:ZZ3%
              AND ZZ3_NUM LIKE 'RASC%'
              AND ZZ3_USUPRO = %Exp:UsrRetName(RetCodUsr())%
        EndSql
        If !(cAliasRasc)->(Eof())
            nQtdRasc := (cAliasRasc)->QTD
        EndIf
        (cAliasRasc)->(DbCloseArea())

        If nQtdRasc > 0
            // Tem rascunho salvo - abre direto a tela de programacao com os rascunhos
            aPedidosSel := {}
            CarregarRascunho()
            If Len(aPedidosSel) > 0
                U_ZLGPROG2()
                Return
            EndIf
        Else
            MsgAlert("Nenhum pedido marcado!", "")
            Return
        EndIf
    EndIf

    // Verifica pedidos com itens ja "andando" (pre-nota) - estes serao
    // desmarcados automaticamente pois o item ja nao pode ser reprogramado.
    // Itens com coleta anterior mas SEM pre-nota permanecem validos para
    // 2a coleta (serao tratados na validacao de "selecao completa").
    BeginSql Alias cAliasProg
        SELECT DISTINCT C7_NUM
        FROM %Table:SC7% SC7
        WHERE %NotDel%
          AND C7_FILIAL = %xFilial:SC7%
          AND C7_RESIDUO <> 'S'
          AND RTRIM(C7_OK) = %Exp:AllTrim(cM)%
          AND (
              (C7_QTDACLA > 0)
              OR C7_QUJE >= C7_QUANT
          )
    EndSql

    While !(cAliasProg)->(Eof())
        aAdd(aPedProgramados, AllTrim((cAliasProg)->C7_NUM))
        (cAliasProg)->(DbSkip())
    EndDo
    (cAliasProg)->(DbCloseArea())

    // Se encontrou pedidos com itens "andando", desmarca automaticamente
    If Len(aPedProgramados) > 0
        For i := 1 To Len(aPedProgramados)
            DbSelectArea("SC7")
            SC7->(DbSetOrder(1))
            SC7->(DbSeek(xFilial("SC7") + aPedProgramados[i]))
            While !SC7->(Eof()) .And. AllTrim(SC7->C7_NUM) == aPedProgramados[i]
                // Desmarca apenas itens que estao andando (pre-nota ou totalmente recebidos)
                lPodeMarcar := .T.
                If lTemQtdAc
                    lPodeMarcar := (SC7->C7_QTDACLA == 0)
                EndIf
                If lPodeMarcar .And. SC7->C7_QUJE < SC7->C7_QUANT
                    SC7->(DbSkip())
                    Loop
                EndIf
                If AllTrim(SC7->C7_OK) == AllTrim(cM)
                    RecLock("SC7", .F.)
                    SC7->C7_OK := Space(2)
                    MsUnlock()
                EndIf
                SC7->(DbSkip())
            EndDo
        Next

        cMsg := "Os seguintes pedidos possuem itens com -nota ou ja entregues." + CRLF
        cMsg += "Esses itens foram desmarcados e nao podem ser reprogramados:" + CRLF + CRLF
        For i := 1 To Len(aPedProgramados)
            cMsg += "- " + aPedProgramados[i] + CRLF
        Next
        MsgInfo(cMsg, "Itens Desmarcados")

        // Atualiza browse apos desmarcar
        If oBrowseMark != Nil
            oBrowseMark:Refresh(.T.)
        EndIf
    EndIf

    // Valida que todos os itens DISPONIVEIS do pedido foram marcados.
    // Itens programados em ZZ3_ITENS (mas sem pre-nota) sao contados
    // no TOTAL - eles estao em rascunho/2a-coleta e o usuario nao precisa
    // marca-los novamente.
    // Aplica os mesmos filtros do browse, com ou sem C7_QTDACLA conforme ambiente.
    If lTemQtdAc
        BeginSql Alias cAliasVal
            SELECT C7_NUM,
                   COUNT(*) AS TOTAL,
                   SUM(CASE WHEN RTRIM(C7_OK) = %Exp:AllTrim(cM)% THEN 1 ELSE 0 END) AS MARCADOS
            FROM %Table:SC7% SC7
            WHERE %NotDel%
              AND C7_FILIAL = %xFilial:SC7%
              AND C7_RESIDUO <> 'S'
              AND C7_QUJE < C7_QUANT
              AND (C7_CONAPRO = '' OR C7_CONAPRO = ' ' OR C7_CONAPRO = 'L')
              AND C7_ENCER <> 'E'
              AND C7_QTDACLA = 0
              AND C7_NUM IN (
                  SELECT DISTINCT SC7M.C7_NUM
                  FROM %Table:SC7% SC7M
                  WHERE SC7M.D_E_L_E_T_ = ' '
                    AND SC7M.C7_FILIAL = %xFilial:SC7%
                    AND SC7M.C7_RESIDUO <> 'S'
                    AND SC7M.C7_QUJE < SC7M.C7_QUANT
                    AND SC7M.C7_QTDACLA = 0
                    AND RTRIM(SC7M.C7_OK) = %Exp:AllTrim(cM)%
                    AND NOT EXISTS (
                        SELECT 1
                        FROM %Table:ZZ3% ZZ3R
                        WHERE ZZ3R.D_E_L_E_T_ = ' '
                          AND ZZ3R.ZZ3_FILIAL = %xFilial:ZZ3%
                          AND ZZ3R.ZZ3_PEDIDO = SC7M.C7_NUM
                          AND ZZ3R.ZZ3_NUM LIKE 'RASC%'
                    )
              )
            GROUP BY C7_NUM
        EndSql
    Else
        BeginSql Alias cAliasVal
            SELECT C7_NUM,
                   COUNT(*) AS TOTAL,
                   SUM(CASE WHEN RTRIM(C7_OK) = %Exp:AllTrim(cM)% THEN 1 ELSE 0 END) AS MARCADOS
            FROM %Table:SC7% SC7
            WHERE %NotDel%
              AND C7_FILIAL = %xFilial:SC7%
              AND C7_RESIDUO <> 'S'
              AND C7_QUJE < C7_QUANT
              AND (C7_CONAPRO = '' OR C7_CONAPRO = ' ' OR C7_CONAPRO = 'L')
              AND C7_ENCER <> 'E'
              AND C7_NUM IN (
                  SELECT DISTINCT SC7M.C7_NUM
                  FROM %Table:SC7% SC7M
                  WHERE SC7M.D_E_L_E_T_ = ' '
                    AND SC7M.C7_FILIAL = %xFilial:SC7%
                    AND SC7M.C7_RESIDUO <> 'S'
                    AND SC7M.C7_QUJE < SC7M.C7_QUANT
                    AND RTRIM(SC7M.C7_OK) = %Exp:AllTrim(cM)%
                    AND NOT EXISTS (
                        SELECT 1
                        FROM %Table:ZZ3% ZZ3R
                        WHERE ZZ3R.D_E_L_E_T_ = ' '
                          AND ZZ3R.ZZ3_FILIAL = %xFilial:ZZ3%
                          AND ZZ3R.ZZ3_PEDIDO = SC7M.C7_NUM
                          AND ZZ3R.ZZ3_NUM LIKE 'RASC%'
                    )
              )
            GROUP BY C7_NUM
        EndSql
    EndIf

    While !(cAliasVal)->(Eof())
        If (cAliasVal)->MARCADOS < (cAliasVal)->TOTAL
            aAdd(aPedIncompletos, AllTrim((cAliasVal)->C7_NUM))
        EndIf
        (cAliasVal)->(DbSkip())
    EndDo
    (cAliasVal)->(DbCloseArea())

    If Len(aPedIncompletos) > 0
        cMsg := "ATENCAO!" + CRLF + CRLF
        cMsg += "E necessario selecionar TODOS os itens DISPONIVEIS (verdes) do pedido!" + CRLF + CRLF
        cMsg += "Pedidos com selecao incompleta:" + CRLF
        For i := 1 To Len(aPedIncompletos)
            cMsg += "- " + aPedIncompletos[i] + CRLF
        Next
        MsgAlert(cMsg, "Selecao Incompleta")
        Return
    EndIf

    // Monta array aPedidosSel com dados e campos adicionais para programacao posterior
    aPedidosSel := {}

    BeginSql Alias cAlias
        SELECT C7_NUM,
               MIN(C7_EMISSAO) AS C7_EMISSAO,
               MIN(C7_DATPRF)  AS C7_DATPRF,
               C7_FORNECE, C7_LOJA,
               MIN(C7_TPFRETE) AS C7_TPFRETE
        FROM %Table:SC7% SC7
        WHERE %NotDel%
          AND C7_FILIAL = %xFilial:SC7%
          AND C7_RESIDUO <> 'S'
          AND RTRIM(C7_OK) = %Exp:AllTrim(cM)%
          AND NOT EXISTS (
              SELECT 1
              FROM %Table:ZZ3% ZZ3R
              WHERE ZZ3R.D_E_L_E_T_ = ' '
                AND ZZ3R.ZZ3_FILIAL = %xFilial:ZZ3%
                AND ZZ3R.ZZ3_PEDIDO = SC7.C7_NUM
                AND ZZ3R.ZZ3_NUM LIKE 'RASC%'
          )
        GROUP BY C7_NUM, C7_FORNECE, C7_LOJA
        ORDER BY C7_NUM
    EndSql

    While !(cAlias)->(Eof())
        SA2->(DbSetOrder(1))
        If SA2->(DbSeek(xFilial("SA2")+(cAlias)->C7_FORNECE+(cAlias)->C7_LOJA))
            aAdd(aPedidosSel, {;
                (cAlias)->C7_NUM,;
                StoD((cAlias)->C7_EMISSAO),;
                (cAlias)->C7_FORNECE,;
                (cAlias)->C7_LOJA,;
                SA2->A2_NOME,;
                AllTrim(SA2->A2_END),;
                AllTrim(SA2->A2_MUN),;
                SA2->A2_EST,;
                AllTrim(SA2->A2_BAIRRO),;
                StoD((cAlias)->C7_DATPRF),;
                IIF((cAlias)->C7_TPFRETE=="C","CIF",IIF((cAlias)->C7_TPFRETE=="F","FOB","Terceiros")),;
                0, 0, CtoD(""), "",;
                Space(6), Space(2), Space(40), 0,;
                Space(15),;
                ""})
        EndIf
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    If Len(aPedidosSel) == 0
        MsgAlert("Nenhum pedido marcado!", "")
        Return
    EndIf

    U_ZLGPROG2()
Return


/*/{Protheus.doc} ZLGPROG2
Tela de programacao: lista pedidos (aPedidosSel) e permite editar/gravar.
@author  Suprimentos
@since   25/06/2026
/*/
User Function ZLGPROG2()
    Local oDlg, oL, cU := UsrRetName(RetCodUsr())

    // Carrega rascunhos salvos anteriormente (se existir)
    CarregarRascunho()

    DEFINE MSDIALOG oDlg TITLE "Programacao - "+cValToChar(Len(aPedidosSel))+" Pedidos" FROM 0,0 TO 700,1400 PIXEL

    @5,5 LISTBOX oL FIELDS HEADER ;
        "Status",;
        "Dt.Emissao",;
        "Pedido",;
        "Fornecedor",;
        "UF",;
        "Cidade",;
        "Bairro",;
        "Endereco",;
        "Transportadora",;
        "Peso",;
        "Volume",;
        "PV",;
        "Vlr.Coleta",;
        "Dt.Coleta",;
        "Tipo Frete",;
        "Observacao";
        SIZE 690,270 OF oDlg PIXEL

    oL:SetArray(aPedidosSel)
    oL:bLine := {||{;
    GetStatusProg(aPedidosSel[oL:nAt,1]),;
    DtoC(aPedidosSel[oL:nAt,2]),;
    aPedidosSel[oL:nAt,1],;
    SubStr(aPedidosSel[oL:nAt,5],1,25),;
    aPedidosSel[oL:nAt,8],;
    SubStr(aPedidosSel[oL:nAt,7],1,20),;
    SubStr(aPedidosSel[oL:nAt,9],1,20),;
    SubStr(aPedidosSel[oL:nAt,6],1,40),;
    SubStr(aPedidosSel[oL:nAt,18],1,25),;
    Transform(aPedidosSel[oL:nAt,12],"@E 999999"),;
    Transform(aPedidosSel[oL:nAt,13],"@E 999,999.99"),;
    aPedidosSel[oL:nAt,20],;
    Transform(aPedidosSel[oL:nAt,19],"@E 999,999.99"),;
    DtoC(aPedidosSel[oL:nAt,14]),;
    If(Len(aPedidosSel[oL:nAt])>=21,aPedidosSel[oL:nAt,21],""),;
    SubStr(aPedidosSel[oL:nAt,15],1,30)}}

    oL:bLDblClick := {||EditProg(oL:nAt), oL:Refresh()}

    @280,5 BUTTON "Visualizar" SIZE 40,12 OF oDlg PIXEL ACTION VisuPed(oL:nAt)
    @280,50 BUTTON "Editar" SIZE 40,12 OF oDlg PIXEL ACTION (EditProg(oL:nAt), oL:Refresh())
    @280,95 BUTTON "Excluir" SIZE 40,12 OF oDlg PIXEL ACTION (ExcluirProg(oL:nAt), oL:Refresh())
    @280,140 BUTTON "Atualizar Forn" SIZE 50,12 OF oDlg PIXEL ACTION (AtualizaFornecedor(oL:nAt), lRascSalvo := .F., oL:Refresh())
    @280,195 BUTTON "Salvar Rascunho" SIZE 60,12 OF oDlg PIXEL ACTION (SalvarRascunhoEAtualiza(), lRascSalvo := .T.)
    @280,260 BUTTON "Gravar" SIZE 40,12 OF oDlg PIXEL ACTION (IIF(ValidaGravar(), (Gravar(cU), LimparRascunho(), lRascSalvo := .T., oDlg:End()), Nil))
    @280,600 BUTTON "Voltar" SIZE 40,12 OF oDlg PIXEL ACTION VoltarProg(oDlg)

    lRascSalvo := .F.

    ACTIVATE MSDIALOG oDlg CENTERED

Return

/*/{Protheus.doc} VoltarProg
Valida se precisa salvar rascunho antes de voltar.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    oDlg, object, Dialog a ser fechado
/*/
Static Function VoltarProg(oDlg)
    
    // Se nao tem pedidos, volta direto
    If Len(aPedidosSel) == 0
        oDlg:End()
        Return
    EndIf

    // Se ja salvou rascunho, pode voltar
    If lRascSalvo
        oDlg:End()
        Return
    EndIf

    // Tem pedidos e nao salvou - avisa
    MsgAlert("Existem pedidos na programacao!" + CRLF + CRLF + ;
             "Clique em 'Salvar Rascunho' antes de voltar" + CRLF + ;
             "para nao perder os dados.", "")
Return

/*/{Protheus.doc} SalvarRascunhoEAtualiza
Salva rascunho na ZZ3 e atualiza browse removendo pedidos programados.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    lSilencioso, logical, .T. nao exibe mensagem de confirmacao
/*/
Static Function SalvarRascunhoEAtualiza(lSilencioso)
    Local i
    Local cAlias := GetNextAlias()
    Local cUsuario := UsrRetName(RetCodUsr())
    Local cItens := ""

    Default lSilencioso := .F.

    If Len(aPedidosSel) == 0
        If !lSilencioso
            MsgInfo("Nenhum pedido para salvar!", "")
        EndIf
        Return
    EndIf

    BEGIN TRANSACTION

    // Limpa rascunhos antigos deste usuario
    BeginSql Alias cAlias
        SELECT R_E_C_N_O_ AS RECNO
        FROM %Table:ZZ3%
        WHERE %NotDel%
          AND ZZ3_FILIAL = %xFilial:ZZ3%
          AND ZZ3_NUM LIKE 'RASC%'
          AND ZZ3_USUPRO = %Exp:cUsuario%
    EndSql

    While !(cAlias)->(Eof())
        DbSelectArea("ZZ3")
        ZZ3->(DbGoTo((cAlias)->RECNO))
        RecLock("ZZ3", .F.)
        ZZ3->(DbDelete())
        MsUnlock()
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    // Salva cada pedido como rascunho
    For i := 1 To Len(aPedidosSel)
        cItens := BuscaItensProg(aPedidosSel[i,1])

        RecLock("ZZ3", .T.)
        ZZ3->ZZ3_FILIAL := xFilial("ZZ3")
        ZZ3->ZZ3_NUM    := "RASC" + cUsuario + StrZero(i, 3)
        ZZ3->ZZ3_PEDIDO := aPedidosSel[i,1]
        ZZ3->ZZ3_DTEMIS := aPedidosSel[i,2]
        ZZ3->ZZ3_FORNEC := aPedidosSel[i,3]
        ZZ3->ZZ3_LOJA   := aPedidosSel[i,4]
        ZZ3->ZZ3_NOMFOR := aPedidosSel[i,5]
        ZZ3->ZZ3_ENDERE := aPedidosSel[i,6]
        ZZ3->ZZ3_CIDADE := aPedidosSel[i,7]
        ZZ3->ZZ3_UF     := aPedidosSel[i,8]
        ZZ3->ZZ3_BAIRRO := aPedidosSel[i,9]
        ZZ3->ZZ3_DTPREV := aPedidosSel[i,10]
        ZZ3->ZZ3_TPFRET := SubStr(aPedidosSel[i,11], 1, 1)
        ZZ3->ZZ3_PESO   := aPedidosSel[i,12]
        ZZ3->ZZ3_VOLUME := Int(aPedidosSel[i,13])
        ZZ3->ZZ3_DTCOLE := aPedidosSel[i,14]
        ZZ3->ZZ3_OBS    := aPedidosSel[i,15]
        ZZ3->ZZ3_TRANSP := aPedidosSel[i,16]
        ZZ3->ZZ3_LOJTRA := aPedidosSel[i,17]
        ZZ3->ZZ3_NOMTRA := aPedidosSel[i,18]
        ZZ3->ZZ3_VALCOL := aPedidosSel[i,19]
        ZZ3->ZZ3_PEDVEN := aPedidosSel[i,20]
        ZZ3->ZZ3_TPFRE2 := If(Len(aPedidosSel[i]) >= 21, aPedidosSel[i,21], "")
        ZZ3->ZZ3_ITENS  := cItens
        ZZ3->ZZ3_USUPRO := cUsuario
        ZZ3->ZZ3_DTPROG := Date()
        ZZ3->ZZ3_HRPROG := Time()
        MsUnlock()

        LimpaMarcaPedido(aPedidosSel[i,1])
    Next i

    END TRANSACTION

    // Atualiza browse para remover pedidos em rascunho
    If oBrowseMark != Nil
        oBrowseMark:SetFilterDefault(FiltroPendentesDBF())
        oBrowseMark:ExecuteFilter()
        oBrowseMark:GoTop(.T.)
        oBrowseMark:Refresh(.T.)
    EndIf

    If !lSilencioso
        MsgInfo("Rascunho salvo! Pedidos removidos do browse.", "Salvo")
    EndIf

Return


/*/{Protheus.doc} LimpaMarcaPedido
Limpa a marca temporaria do FWMarkBrowse para evitar que rascunhos sejam remontados pelo SC7.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    cPedido, character, Numero do pedido a desmarcar
/*/
Static Function LimpaMarcaPedido(cPedido)
    Local aArea := GetArea()
    Local cFilSC7 := xFilial("SC7")
    Local cPed := AllTrim(cPedido)
    Local cPedKey := PadR(cPed, TamSX3("C7_NUM")[1])

    If Empty(cPed)
        RestArea(aArea)
        Return
    EndIf

    DbSelectArea("SC7")
    SC7->(DbSetOrder(1))

    If SC7->(DbSeek(cFilSC7 + cPedKey))
        While !SC7->(Eof()) .And. SC7->C7_FILIAL == cFilSC7 .And. AllTrim(SC7->C7_NUM) == cPed
            If !Empty(AllTrim(SC7->C7_OK))
                RecLock("SC7", .F.)
                SC7->C7_OK := Space(2)
                MsUnlock()
            EndIf
            SC7->(DbSkip())
        EndDo
    EndIf

    RestArea(aArea)
Return


/*/{Protheus.doc} EditProg
Edita um pedido da programacao (com dados locais).
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    n, numeric, Indice no array aPedidosSel
/*/
Static Function EditProg(n)
    Local oDlg
    Local nP := aPedidosSel[n,12]
    Local nV := Int(aPedidosSel[n,13])  // Volume como inteiro
    Local dC := aPedidosSel[n,14]
    Local cO := aPedidosSel[n,15]
    Local cTransp := aPedidosSel[n,16]
    Local cLojaTr := aPedidosSel[n,17]
    Local cNomeTr := aPedidosSel[n,18]
    Local nVlrCol := aPedidosSel[n,19]
    Local cPedVenda := PadR(AllTrim(aPedidosSel[n,20]), 15)
    Local cTpFrete2 := If(Len(aPedidosSel[n]) >= 21, aPedidosSel[n,21], "")
    Local oTransp, oLojaTr, oNomeTr

    DEFINE MSDIALOG oDlg TITLE "Editar Pedido "+aPedidosSel[n,1] FROM 0,0 TO 480,500 PIXEL

    @10,10 SAY "Pedido Venda:" SIZE 50,10 OF oDlg PIXEL
    @10,70 MSGET cPedVenda SIZE 80,10 OF oDlg PIXEL

    @25,10 SAY "Peso:" SIZE 40,10 OF oDlg PIXEL
    @25,70 MSGET nP PICTURE "@E 999,999.99" SIZE 60,10 OF oDlg PIXEL

    @40,10 SAY "Volume:" SIZE 40,10 OF oDlg PIXEL
    @40,70 MSGET nV PICTURE "@E 999999" SIZE 60,10 OF oDlg PIXEL VALID ValidaVolume(@nV)

    @55,10 SAY "Valor Coleta:" SIZE 50,10 OF oDlg PIXEL
    @55,70 MSGET nVlrCol PICTURE "@E 999,999.99" SIZE 60,10 OF oDlg PIXEL

    @70,10 SAY "Coleta:" SIZE 40,10 OF oDlg PIXEL
    @70,70 MSGET dC SIZE 60,10 OF oDlg PIXEL VALID ValidaDataColeta(dC)

    @85,10 SAY "Tipo Frete:" SIZE 50,10 OF oDlg PIXEL
    @85,70 MSCOMBOBOX cTpFrete2 ITEMS {"","DEDICADO","FRACIONADO"} SIZE 80,10 OF oDlg PIXEL

    @100,10 SAY "Transportadora:" SIZE 60,10 OF oDlg PIXEL
    @100,75 MSGET oTransp VAR cTransp F3 "SA2" SIZE 40,10 OF oDlg PIXEL VALID ValidaTransp(@cTransp, @cLojaTr, @cNomeTr, oLojaTr, oNomeTr)

    @100,120 SAY "Loja:" SIZE 20,10 OF oDlg PIXEL
    @100,140 MSGET oLojaTr VAR cLojaTr SIZE 20,10 OF oDlg PIXEL VALID ValidaTransp(@cTransp, @cLojaTr, @cNomeTr, oLojaTr, oNomeTr)

    @115,75 MSGET oNomeTr VAR cNomeTr WHEN .F. SIZE 165,10 OF oDlg PIXEL

    @130,10 SAY "Obs:" SIZE 40,10 OF oDlg PIXEL
    @145,10 GET cO MULTILINE SIZE 230,50 OF oDlg PIXEL

    @200,170 BUTTON "OK" SIZE 30,12 OF oDlg PIXEL ACTION (SalvaEditProg(n, nP, nV, dC, cO, cTransp, cLojaTr, cNomeTr, nVlrCol, cPedVenda, cTpFrete2), oDlg:End())
    @200,205 BUTTON "Cancelar" SIZE 30,12 OF oDlg PIXEL ACTION oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED
Return


/*/{Protheus.doc} ValidaVolume
Valida volume, garante inteiro e nao negativo.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    nV, numeric, Volume a validar
@return   lRet, logical, .T. se valido
/*/
Static Function ValidaVolume(nV)
    Local lRet := .T.

    
    // Remove casas decimais se digitou
    nV := Int(nV)

    If nV < 0
        MsgAlert("Volume nao pode ser negativo!", "")
        nV := 0
        lRet := .F.
    EndIf

Return lRet


/*/{Protheus.doc} ValidaDataColeta
Valida data de coleta (nao permite anterior a data atual). Permite vazio.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    dC, date, Data de coleta a validar
@return   lRet, logical, .T. se valida
/*/
Static Function ValidaDataColeta(dC)
    Local lRet := .T.
    Local dHoje := Date()

    // Permite data vazia
    If Empty(dC)
        Return .T.
    EndIf

    // Valida se a data e anterior a hoje
    If dC < dHoje
        MsgAlert("Data de coleta nao pode ser anterior a data atual!" + CRLF + CRLF + ;
                 "Data atual: " + DtoC(dHoje) + CRLF + ;
                 "Data informada: " + DtoC(dC) + CRLF + CRLF + ;
                 "Por favor, informe uma data igual ou posterior a hoje.", "Data Invalida")
        dC := dHoje
        lRet := .F.
    EndIf

Return lRet


/*/{Protheus.doc} ValidaTransp
Valida transportadora: preenche nome se encontrada; permite limpar se ambos campos vazios.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    cTransp, character, Codigo da transportadora
@param    cLojaTr, character, Loja da transportadora
@param    cNomeTr, character, Nome da transportadora (retornado)
@param    oLojaTr, object, Objeto MSGET da loja
@param    oNomeTr, object, Objeto MSGET do nome
@return   lRet, logical, .T. se encontrada
/*/
Static Function ValidaTransp(cTransp, cLojaTr, cNomeTr, oLojaTr, oNomeTr)
    Local lRet := .T.

    // Limpa se ambos vazios
    If Empty(AllTrim(cTransp)) .And. Empty(AllTrim(cLojaTr))
        cNomeTr := Space(40)
        If oNomeTr != Nil
            oNomeTr:Refresh()
        EndIf
        Return .T.
    EndIf

    // Se digitou transportadora mas nao loja, preenche loja "01"
    If !Empty(AllTrim(cTransp)) .And. Empty(AllTrim(cLojaTr))
        cLojaTr := "01"
        If oLojaTr != Nil
            oLojaTr:Refresh()
        EndIf
    EndIf

    // Busca no SA2 usando a mesma ordem do BuscTr
    DbSelectArea("SA2")
    SA2->(DbSetOrder(1))  // mesma ordem usada no BuscTr

    If SA2->(DbSeek(xFilial("SA2") + cTransp + cLojaTr))
        cNomeTr := SA2->A2_NOME
        lRet    := .T.
    Else
        MsgAlert("Transportadora " + cTransp + "/" + cLojaTr + " nao encontrada!" + CRLF + CRLF + ;
                 "Verifique o codigo e a loja ou use F3 para buscar.", "")
        cNomeTr := Space(40)
        lRet    := .F.
    EndIf

    If oNomeTr != Nil
        oNomeTr:Refresh()
    EndIf

Return lRet


/*/{Protheus.doc} SalvaEditProg
Salva alteracao feita na tela de edicao no array aPedidosSel.
Nao persiste em banco aqui; apenas atualiza array em memoria.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    n, numeric, Indice no array
@param    nP, numeric, Peso
@param    nV, numeric, Volume
@param    dC, date, Data de coleta
@param    cO, character, Observacao
@param    cTransp, character, Codigo transportadora
@param    cLojaTr, character, Loja transportadora
@param    cNomeTr, character, Nome transportadora
@param    nVlrCol, numeric, Valor coleta
@param    cPedVenda, character, Pedido venda
@param    cTpFrete2, character, Tipo frete 2
/*/
Static Function SalvaEditProg(n, nP, nV, dC, cO, cTransp, cLojaTr, cNomeTr, nVlrCol, cPedVenda, cTpFrete2)
    Local dHoje := Date()

    // Valida transportadora
    If !Empty(AllTrim(cTransp)) .Or. !Empty(AllTrim(cLojaTr))
        SA2->(DbSetOrder(1))
        If !SA2->(DbSeek(xFilial("SA2")+cTransp+cLojaTr))
            MsgAlert("Transportadora invalida! Corrija antes de salvar.", "Erro")
            Return
        EndIf
        cNomeTr := SA2->A2_NOME
    EndIf

    // Valida data de coleta antes de salvar
    If !Empty(dC) .And. dC < dHoje
        MsgAlert("Data de coleta nao pode ser anterior a data atual (" + DtoC(dHoje) + ")!", "Erro")
        Return
    EndIf

    // Garante que volume e inteiro
    nV := Int(nV)

    aPedidosSel[n,12] := nP
    aPedidosSel[n,13] := nV
    aPedidosSel[n,14] := dC
    aPedidosSel[n,15] := cO
    aPedidosSel[n,16] := cTransp
    aPedidosSel[n,17] := cLojaTr
    aPedidosSel[n,18] := cNomeTr
    aPedidosSel[n,19] := nVlrCol
    aPedidosSel[n,20] := cPedVenda

    If Len(aPedidosSel[n]) >= 21
        aPedidosSel[n,21] := cTpFrete2
    Else
        aAdd(aPedidosSel[n], cTpFrete2)
    EndIf

    MsgInfo("Dados atualizados!", "Sucesso")
Return


/*/{Protheus.doc} GetStatusProg
Calcula status do pedido para a tela de programacao.
Verifica quantidades recebidas e existencia de pre-nota (SD1). Query unificada.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    cPedido, character, Numero do pedido
@return   cStatus, character, Status calculado
/*/
Static Function GetStatusProg(cPedido)
    Local cStatus := ""
    Local cAlias := GetNextAlias()
    Local nTotQuant := 0
    Local nTotQuje := 0
    Local lTemPreNota := .F.
    Local nItensAmarelos := 0
    Local cQuery := ""

    cQuery := " SELECT"
    cQuery += "   ISNULL(SC7D.AMARELOS, 0) AS AMARELOS,"
    cQuery += "   ISNULL(SC7D.TOTQUANT, 0) AS TOTQUANT,"
    cQuery += "   ISNULL(SC7D.TOTQUJE, 0) AS TOTQUJE,"
    cQuery += "   ISNULL(PRE.QTDPRE, 0) AS QTDPRE"
    cQuery += " FROM ("
    cQuery += "   SELECT"
    cQuery += "     COUNT(CASE WHEN C7_QUJE > 0 AND C7_QUJE < C7_QUANT THEN 1 END) AS AMARELOS,"
    cQuery += "     SUM(C7_QUANT) AS TOTQUANT,"
    cQuery += "     SUM(C7_QUJE) AS TOTQUJE"
    cQuery += "   FROM " + RetSqlName("SC7")
    cQuery += "   WHERE D_E_L_E_T_ = ' '"
    cQuery += "     AND C7_FILIAL = '" + xFilial("SC7") + "'"
    cQuery += "     AND C7_NUM = '" + cPedido + "'"
    cQuery += "     AND C7_RESIDUO <> 'S'"
    cQuery += " ) SC7D"
    cQuery += " CROSS JOIN ("
    cQuery += "   SELECT COUNT(*) AS QTDPRE"
    cQuery += "   FROM " + RetSqlName("SD1") + " SD1"
    cQuery += "   WHERE SD1.D_E_L_E_T_ = ' '"
    cQuery += "     AND D1_FILIAL = '" + xFilial("SD1") + "'"
    cQuery += "     AND D1_PEDIDO = '" + cPedido + "'"
    cQuery += "     AND D1_TIPO = 'B'"
    cQuery += " ) PRE"

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    If !(cAlias)->(Eof())
        nItensAmarelos := (cAlias)->AMARELOS
        nTotQuant := (cAlias)->TOTQUANT
        nTotQuje := (cAlias)->TOTQUJE
        lTemPreNota := ((cAlias)->QTDPRE > 0)
    EndIf
    (cAlias)->(DbCloseArea())

    Do Case
        Case nTotQuje > 0 .And. nTotQuje >= nTotQuant
            cStatus := "Coletado"
        Case lTemPreNota
            cStatus := "Pre Nota"
        Case nItensAmarelos > 0 .Or. (nTotQuje > 0 .And. nTotQuje < nTotQuant)
            cStatus := "Parcial"
        Otherwise
            cStatus := "Pendente"
    EndCase

Return cStatus


/*/{Protheus.doc} VisuPed
Exibe detalhes do pedido em mensagem com todos os campos.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    n, numeric, Indice no array aPedidosSel
/*/
Static Function VisuPed(n)
    Local cMsg := ""
    Local cAlias := GetNextAlias()
    Local nTotPed := 0

    BeginSql Alias cAlias
        SELECT SUM(C7_TOTAL) AS TOTAL
        FROM %Table:SC7%
        WHERE %NotDel%
          AND C7_FILIAL = %xFilial:SC7%
          AND C7_NUM = %Exp:aPedidosSel[n,1]%
    EndSql

    If !(cAlias)->(Eof())
        nTotPed := (cAlias)->TOTAL
    EndIf
    (cAlias)->(DbCloseArea())

    cMsg := "Pedido: " + aPedidosSel[n,1] + CRLF
    cMsg += "PV: " + aPedidosSel[n,20] + CRLF
    cMsg += "Emissao: " + DtoC(aPedidosSel[n,2]) + CRLF
    cMsg += "Entrega: " + DtoC(aPedidosSel[n,10]) + CRLF
    cMsg += "Coleta: " + DtoC(aPedidosSel[n,14]) + CRLF + CRLF
    cMsg += "Fornecedor: " + aPedidosSel[n,3] + "/" + aPedidosSel[n,4] + " - " + aPedidosSel[n,5] + CRLF
    cMsg += "Endereco: " + aPedidosSel[n,6] + CRLF
    cMsg += "Bairro: " + aPedidosSel[n,9] + CRLF
    cMsg += "Cidade: " + aPedidosSel[n,7] + " - " + aPedidosSel[n,8] + CRLF + CRLF
    cMsg += "Peso: " + Transform(aPedidosSel[n,12],"@E 999,999.99") + CRLF
    cMsg += "Volume: " + Transform(aPedidosSel[n,13],"@E 999,999.99") + CRLF
    cMsg += "Total: R$ " + Transform(nTotPed,"@E 999,999.99")

    MsgInfo(cMsg, "Detalhes do Pedido " + aPedidosSel[n,1])
Return




/*/{Protheus.doc} ExcluirProg
Remove pedido da programacao (array) e do banco.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    nPos, numeric, Indice no array aPedidosSel
/*/
Static Function ExcluirProg(nPos)
    Local cPedido := aPedidosSel[nPos,1]
    Local cStatus := GetStatusProg(cPedido)
    Local cAlias := GetNextAlias()

    // Bloqueia exclusao de pedidos com Pre Nota ou Coletado
    If AllTrim(cStatus) == "Pre Nota" .Or. AllTrim(cStatus) == "Coletado"
        MsgAlert("ATENCAO!" + CRLF + CRLF + ;
                 "Nao e permitido excluir pedidos com status:" + CRLF + ;
                 AllTrim(cStatus) + CRLF + CRLF + ;
                 "Somente pedidos com status 'Pendente', 'Incluido' ou 'Parcial' podem ser excluidos!", ;
                 "Exclusao Bloqueada")
        Return
    EndIf

    BEGIN TRANSACTION

    // 1. Desmarca o pedido no SC7 (limpa C7_OK) para que volte ao browse
    DbSelectArea("SC7")
    SC7->(DbSetOrder(1))  // Ordem: C7_FILIAL + C7_NUM + C7_ITEM
    SC7->(DbSeek(xFilial("SC7") + cPedido))
    While !SC7->(Eof()) .And. SC7->C7_NUM == cPedido
        RecLock("SC7", .F.)
        SC7->C7_OK := Space(2)
        MsUnlock()
        SC7->(DbSkip())
    EndDo

    // 2. Exclui rascunhos do ZZ3 relacionados a este pedido (se existir)
    BeginSql Alias cAlias
        SELECT R_E_C_N_O_ AS RECNO
        FROM %Table:ZZ3%
        WHERE %NotDel%
          AND ZZ3_FILIAL = %xFilial:ZZ3%
          AND ZZ3_PEDIDO = %Exp:cPedido%
          AND ZZ3_NUM LIKE 'RASC%'
    EndSql

    While !(cAlias)->(Eof())
        DbSelectArea("ZZ3")
        ZZ3->(DbGoTo((cAlias)->RECNO))
        RecLock("ZZ3", .F.)
        ZZ3->(DbDelete())
        MsUnlock()
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    END TRANSACTION

    // 3. Remove do array
    aDel(aPedidosSel, nPos)
    aSize(aPedidosSel, Len(aPedidosSel) - 1)

    // 4. Re-salva rascunho silenciosamente com os pedidos restantes
    If Len(aPedidosSel) > 0
        SalvarRascunhoEAtualiza(.T.)
    Else
        // Se nao tem mais pedidos, limpa rascunhos
        LimparRascunho()
    EndIf

    // 5. Atualiza browse principal para que o pedido volte a aparecer
    If oBrowseMark != Nil
        oBrowseMark:SetFilterDefault(FiltroPendentesDBF())
        oBrowseMark:ExecuteFilter()
        oBrowseMark:GoTop(.T.)
        oBrowseMark:Refresh(.T.)  // Atualiza tela
    EndIf

    MsgInfo("Pedido " + cPedido + " removido com sucesso!" + CRLF + CRLF + ;
            "O pedido voltou para o browse principal.", "Sucesso")
Return


/*/{Protheus.doc} BuscaItensProg
Monta lista de itens do pedido que serao programados (itens disponiveis
ou parcialmente entregues). Retorna string CSV com zero-fill de 2 digitos
(padrao C7_ITEM) para garantir match seguro em ItemEmZZ3.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    cPedido, character, Numero do pedido
@return   cItens, character, Itens em formato CSV
/*/
Static Function BuscaItensProg(cPedido)
    Local cAlias := GetNextAlias()
    Local cItens := ""

    BeginSql Alias cAlias
        SELECT C7_ITEM
        FROM %Table:SC7%
        WHERE %NotDel%
          AND C7_FILIAL = %xFilial:SC7%
          AND C7_NUM = %Exp:cPedido%
          AND C7_RESIDUO <> 'S'
          AND (C7_QUJE = 0 OR (C7_QUJE > 0 AND C7_QUJE < C7_QUANT))
        ORDER BY C7_ITEM
    EndSql

    While !(cAlias)->(Eof())
        If !Empty(cItens)
            cItens += ","
        EndIf
        // Zero-fill 2 digitos - evita match parcial em ItemEmZZ3
        cItens += StrZero(Val(AllTrim((cAlias)->C7_ITEM)), 2)
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

Return cItens


/*/{Protheus.doc} Gravar
Persiste programacao: grava registros em ZZ3 e atualiza SC7.
Executa em transacao e atualiza o browse ao final.

Para cada pedido:
  1. Valida que NENHUM item esta em pre-nota (C7_QTDACLA > 0)
  2. Busca itens pendentes (C7_QUJE = 0 OU C7_QUJE < C7_QUANT) e
     EXCLUI os que ja estao em ZZ3_ITENS definitivo (ja programados)
     para evitar coleta duplicada.
  3. Se nao ha itens novos, NAO cria registro na ZZ3 (cobre o caso
     "2a coleta sem itens pendentes").
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    cU, character, Nome do usuario
/*/
Static Function Gravar(cU)
    Local i, cN, cItens, cItensNovos
    Local cObs := ""
    Local cPedVenda := ""
    Local cTpFrete2 := ""
    Local aItensPend := {}
    Local aItensJaProg := {}
    Local aPedComPreNota := {}
    Local nI := 0
    Local nGravados := 0
    Local cItem := ""
    Local cMsg := ""
    Local lTemQtdAc := .F.

    DbSelectArea("SC7")
    lTemQtdAc := (SC7->(FieldPos("C7_QTDACLA")) > 0)

    BEGIN TRANSACTION

    For i := 1 To Len(aPedidosSel)
        cObs := aPedidosSel[i,15]
        cPedVenda := aPedidosSel[i,20]
        cTpFrete2 := If(Len(aPedidosSel[i]) >= 21, aPedidosSel[i,21], "")

        // Validacao de pre-nota: se houver QUALQUER item do pedido com
        // C7_QTDACLA > 0, o pedido ja esta "andando" no recebimento.
        // Bloqueia TODA a gravacao (atomicidade).
        If lTemQtdAc .And. TemItemEmPreNota(aPedidosSel[i,1])
            // DisarmTransaction dentro do loop; UI movida para apos END TRANSACTION
            DisarmTransaction()
            nGravados := 0
            aAdd(aPedComPreNota, aPedidosSel[i,1])
            Exit
        EndIf

        // Busca itens pendentes e separa os que ja estao em ZZ3_ITENS
        aItensPend   := {}
        aItensJaProg := {}
        cItens := BuscaItensProg(aPedidosSel[i,1])

        If !Empty(cItens)
            aItensPend := StrTokArr(cItens, ",")
            For nI := 1 To Len(aItensPend)
                cItem := aItensPend[nI]
                If ItemEmZZ3(aPedidosSel[i,1], cItem)
                    aAdd(aItensJaProg, cItem)
                EndIf
            Next nI
        EndIf

        // Monta ZZ3_ITENS apenas com os itens NOVOS (nao programados)
        cItensNovos := ""
        For nI := 1 To Len(aItensPend)
            cItem := aItensPend[nI]
            If aScan(aItensJaProg, cItem) == 0
                If !Empty(cItensNovos)
                    cItensNovos += ","
                EndIf
                cItensNovos += cItem
            EndIf
        Next nI

        // Se nao ha itens novos, pula este pedido (ja esta 100% programado)
        If Empty(cItensNovos)
            // Apenas desmarca os itens do pedido no SC7
            DbSelectArea("SC7")
            SC7->(DbSetOrder(1))
            SC7->(DbSeek(xFilial("SC7")+aPedidosSel[i,1]))
            While !SC7->(Eof()) .And. SC7->C7_NUM == aPedidosSel[i,1]
                If !Empty(AllTrim(SC7->C7_OK))
                    RecLock("SC7", .F.)
                    SC7->C7_OK := Space(2)
                    MsUnlock()
                EndIf
                SC7->(DbSkip())
            EndDo
            Loop
        EndIf

        cN := NextZZ3()

        RecLock("ZZ3",.T.)
        ZZ3->ZZ3_FILIAL := xFilial("ZZ3")
        ZZ3->ZZ3_NUM    := cN
        ZZ3->ZZ3_PEDIDO := aPedidosSel[i,1]
        ZZ3->ZZ3_DTEMIS := aPedidosSel[i,2]
        ZZ3->ZZ3_FORNEC := aPedidosSel[i,3]
        ZZ3->ZZ3_LOJA   := aPedidosSel[i,4]
        ZZ3->ZZ3_NOMFOR := aPedidosSel[i,5]
        ZZ3->ZZ3_ENDERE := aPedidosSel[i,6]
        ZZ3->ZZ3_CIDADE := aPedidosSel[i,7]
        ZZ3->ZZ3_UF     := aPedidosSel[i,8]
        ZZ3->ZZ3_BAIRRO := aPedidosSel[i,9]
        ZZ3->ZZ3_DTPREV := aPedidosSel[i,10]
        ZZ3->ZZ3_TPFRET := aPedidosSel[i,11]
        ZZ3->ZZ3_PESO   := aPedidosSel[i,12]
        ZZ3->ZZ3_VOLUME := Int(aPedidosSel[i,13])
        ZZ3->ZZ3_DTCOLE := aPedidosSel[i,14]
        ZZ3->ZZ3_OBS    := cObs
        ZZ3->ZZ3_TRANSP := aPedidosSel[i,16]
        ZZ3->ZZ3_LOJTRA := aPedidosSel[i,17]
        ZZ3->ZZ3_NOMTRA := aPedidosSel[i,18]
        ZZ3->ZZ3_VALCOL := aPedidosSel[i,19]
        ZZ3->ZZ3_PEDVEN := cPedVenda
        ZZ3->ZZ3_TPFRE2 := cTpFrete2
        ZZ3->ZZ3_USUPRO := cU
        ZZ3->ZZ3_DTPROG := Date()
        ZZ3->ZZ3_HRPROG := Time()
        ZZ3->ZZ3_ITENS  := cItensNovos
        MsUnlock()
        nGravados++

        // Desmarca apenas os itens NOVOS (cItensNovos) no SC7
        DbSelectArea("SC7")
        SC7->(DbSetOrder(1))
        SC7->(DbSeek(xFilial("SC7")+aPedidosSel[i,1]))
        While !SC7->(Eof()) .And. SC7->C7_NUM == aPedidosSel[i,1]
            cItem := StrZero(Val(AllTrim(SC7->C7_ITEM)), 2)
            // Verifica se o item esta em cItensNovos usando match CSV seguro
            If ("," + cItem + ",") $ ("," + cItensNovos + ",")
                If !Empty(AllTrim(SC7->C7_OK))
                    RecLock("SC7", .F.)
                    SC7->C7_OK := Space(2)
                    MsUnlock()
                EndIf
            EndIf
            SC7->(DbSkip())
        EndDo
    Next

    END TRANSACTION

    // UI deve ficar FORA da transacao (CA1002)
    If Len(aPedComPreNota) > 0
        cMsg := "Pedido " + aPedComPreNota[1] + " possui item(ns) em pré-nota." + CRLF
        cMsg += "Aguarde o recebimento antes de programar." + CRLF + CRLF
        cMsg += "Gravacao abortada. Nenhuma coleta foi criada."
        MsgAlert(cMsg, "Atenção")
        Return
    EndIf

    If nGravados > 0
        MsgInfo("Gravado! " + cValToChar(nGravados) + " coleta(s) criada(s).", "Sucesso")

        // Atualiza o browse removendo pedidos programados
        If oBrowseMark != Nil
            oBrowseMark:SetFilterDefault(FiltroPendentesDBF())
            oBrowseMark:ExecuteFilter()
            oBrowseMark:GoTop(.T.)
            oBrowseMark:Refresh(.T.)
        EndIf
    EndIf

Return

/*/{Protheus.doc} TemItemEmPreNota
Verifica se o pedido possui ao menos 1 item com C7_QTDACLA > 0
(-nota lancada no SC7 - indica que o item ja esta em
processo de recebimento).

@param cPedido  Numero do pedido de compra
@return Logical .T. se existe item com -nota
@since  25/06/2026
/*/
Static Function TemItemEmPreNota(cPedido)
    Local cAlias := GetNextAlias()
    Local lTem := .F.

    If SC7->(FieldPos("C7_QTDACLA")) == 0
        Return .F.
    EndIf

    BeginSql Alias cAlias
        SELECT COUNT(*) AS QTD
        FROM %Table:SC7%
        WHERE %NotDel%
          AND C7_FILIAL = %xFilial:SC7%
          AND C7_NUM = %Exp:AllTrim(cPedido)%
          AND C7_QTDACLA > 0
    EndSql

    If !(cAlias)->(Eof())
        lTem := ((cAlias)->QTD > 0)
    EndIf
    (cAlias)->(DbCloseArea())

Return lTem


/*/{Protheus.doc} MontaMsgFrete
Monta a linha de rodape com o calculo da porcentagem de frete sobre o
valor total dos pedidos, considerando SOMENTE as coletas filtradas.
% Frete = (Valor Total do Frete / Valor Total dos Pedidos) * 100
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    aArray, array, Array de coletas filtrado (pos 6 = Vlr.Coleta, 15 = Vlr.Pedido)
@return   cMsg, character, Texto formatado com a porcentagem e os totais
/*/
Static Function MontaMsgFrete(aArray)
    Local nI     := 0
    Local nFrete := 0
    Local nPed   := 0
    Local nPerc  := 0

    For nI := 1 To Len(aArray)
        nFrete += aArray[nI,6]
        If Len(aArray[nI]) >= 15
            nPed += aArray[nI,15]
        EndIf
    Next nI

    If nPed > 0
        nPerc := (nFrete / nPed) * 100
    EndIf

Return "Porcentagem de Frete: " + Transform(nPerc, "@E 99.99") + "%   |   " + ;
    "Frete Total: R$ " + Transform(nFrete, "@E 999,999.99") + "   |   " + ;
    "Pedidos Total: R$ " + Transform(nPed, "@E 999,999,999.99")

/*/{Protheus.doc} ZLGCONS
Abre a tela de consulta de coletas (carrega array via CarregaColetas).
@author  Suprimentos
@since   25/06/2026
/*/
User Function ZLGCONS()
    Local oDlg, oL
    Local dDtColetaDe := CtoD("")
    Local dDtColetaAte := CtoD("")
    Local cPedFiltro := Space(6)
    Local cStatusFiltro := "TODOS"
    Local oDtDe, oDtAte, oPed, oStatus
    Local aC := {}

    aC := CarregaColetas()

    If Len(aC) == 0
        MsgAlert("Nenhuma coleta!","")
        Return
    EndIf

    // Guarda array filtrado para o calculo de % de frete no rodape
    aColetasCalc := aC

    DEFINE MSDIALOG oDlg TITLE "Coletas - "+cValToChar(Len(aC)) FROM 0,0 TO 650,1300 PIXEL

    // Filtros
    @5,5 SAY "Data Coleta DE:" SIZE 50,10 OF oDlg PIXEL
    @5,60 MSGET oDtDe VAR dDtColetaDe SIZE 50,10 OF oDlg PIXEL

    @5,115 SAY "ATE:" SIZE 20,10 OF oDlg PIXEL
    @5,140 MSGET oDtAte VAR dDtColetaAte SIZE 50,10 OF oDlg PIXEL

    @5,200 SAY "Pedido:" SIZE 30,10 OF oDlg PIXEL
    @5,225 MSGET oPed VAR cPedFiltro SIZE 40,10 OF oDlg PIXEL

    @5,285 SAY "Status:" SIZE 30,10 OF oDlg PIXEL
    @5,310 MSCOMBOBOX oStatus VAR cStatusFiltro ITEMS {"TODOS","Pendente","Parcial","Pre Nota","Coletado","Incluido"} SIZE 80,10 OF oDlg PIXEL

    
    // ListBox principal
    @40,5 LISTBOX oL FIELDS HEADER "Status","Pedido","Dt.Coleta","Fornecedor","Transportadora","Vlr.Coleta","Vlr.Pedido","CTE","Tipo Frete","Observacao" SIZE 640,250 OF oDlg PIXEL
    oL:SetArray(aC)
    oL:bLine := {|| {;
        GetStatusColeta(aC[oL:nAt,1]), ;
        aC[oL:nAt,1], ;
        DtoC(aC[oL:nAt,10]), ;
        SubStr(aC[oL:nAt,3],1,30), ;
        SubStr(aC[oL:nAt,5],1,25), ;
        Transform(aC[oL:nAt,6],"@E 999,999.99"), ;
        Transform(If(Len(aC[oL:nAt])>=15, aC[oL:nAt,15], 0),"@E 999,999.99"), ;
        aC[oL:nAt,11], ;
        If(Len(aC[oL:nAt])>=13, aC[oL:nAt,13], ""), ;
        SubStr(aC[oL:nAt,7],1,30)}}

    // Botao Filtrar
    @20,5 BUTTON "Filtrar" SIZE 40,12 OF oDlg PIXEL ACTION (;
    aC := AplicaFiltro(dDtColetaDe, dDtColetaAte, cPedFiltro, cStatusFiltro), ;
    aColetasCalc := aC, ;
    oSayCalcFrete:Refresh(), ;
    oL:nAt := 1, ;
    oL:SetArray(aC), ;
    oL:bLine := {|| If(Len(aC)>0 .And. oL:nAt <= Len(aC), ;
        {GetStatusColeta(aC[oL:nAt,1]), ;
         aC[oL:nAt,1], ;
         DtoC(aC[oL:nAt,10]), ;
         SubStr(aC[oL:nAt,3],1,30), ;
         SubStr(aC[oL:nAt,5],1,25), ;
         Transform(aC[oL:nAt,6],"@E 999,999.99"), ;
         Transform(If(Len(aC[oL:nAt])>=15, aC[oL:nAt,15], 0),"@E 999,999.99"), ;
         aC[oL:nAt,11], ;
         If(Len(aC[oL:nAt])>=13, aC[oL:nAt,13], ""), ;
         SubStr(aC[oL:nAt,7],1,30)}, ;
        {"","","","","","","","","",""})}, ;
    oL:Refresh(), ;
    oDlg:Refresh())

    @20,50 BUTTON "Limpar" SIZE 40,12 OF oDlg PIXEL ACTION (;
    dDtColetaDe := CtoD(""), ;
    dDtColetaAte := CtoD(""), ;
    cPedFiltro := Space(6), ;
    cStatusFiltro := "TODOS", ;
    oDtDe:Refresh(), ;
    oDtAte:Refresh(), ;
    oPed:Refresh(), ;
    oStatus:Refresh(), ;
    aC := CarregaColetas(), ;
    aColetasCalc := aC, ;
    oSayCalcFrete:Refresh(), ;
    oL:nAt := 1, ;
    oL:SetArray(aC), ;
    oL:bLine := {|| If(Len(aC)>0 .And. oL:nAt <= Len(aC), ;
        {GetStatusColeta(aC[oL:nAt,1]), ;
         aC[oL:nAt,1], ;
         DtoC(aC[oL:nAt,10]), ;
         SubStr(aC[oL:nAt,3],1,30), ;
         SubStr(aC[oL:nAt,5],1,25), ;
         Transform(aC[oL:nAt,6],"@E 999,999.99"), ;
         Transform(If(Len(aC[oL:nAt])>=15, aC[oL:nAt,15], 0),"@E 999,999.99"), ;
         aC[oL:nAt,11], ;
         If(Len(aC[oL:nAt])>=13, aC[oL:nAt,13], ""), ;
         SubStr(aC[oL:nAt,7],1,30)}, ;
        {"","","","","","","","","",""})}, ;
    oL:Refresh(), ;
    oDlg:Refresh())

    @20,95 BUTTON "Atualizar" SIZE 40,12 OF oDlg PIXEL ACTION (;
        aC := CarregaColetas(), ;
        aColetasCalc := aC, ;
        oSayCalcFrete:Refresh(), ;
        oL:nAt := If(Len(aC)>0, 1, 1), ;
        oL:SetArray(If(Len(aC)>0, aC, {{"","",CtoD(""),"","",0,"","","",CtoD(""),"","","",0,0}})), ;
        oL:bLine := {|| If(Len(aC)>0, ;
            {GetStatusColeta(aC[oL:nAt,1]), ;
             aC[oL:nAt,1], ;
             DtoC(aC[oL:nAt,10]), ;
             SubStr(aC[oL:nAt,3],1,30), ;
             SubStr(aC[oL:nAt,5],1,25), ;
             Transform(aC[oL:nAt,6],"@E 999,999.99"), ;
             Transform(If(Len(aC[oL:nAt])>=15, aC[oL:nAt,15], 0),"@E 999,999.99"), ;
             aC[oL:nAt,11], ;
             If(Len(aC[oL:nAt])>=13, aC[oL:nAt,13], ""), ;
             SubStr(aC[oL:nAt,7],1,30)}, ;
            {"","","","","","","","","",""})}, ;
        oL:Refresh(.T.), ;
        oDlg:Refresh(), ;
        MsgInfo("Lista atualizada!" + CRLF + CRLF + ;
                "Total: " + cValToChar(Len(aC)) + " coletas" + CRLF + ;
                "Data/Hora: " + DtoC(Date()) + " - " + Time(), "Atualizado"))

    // Botoes de acao
    @305,5 BUTTON "Editar" SIZE 60,12 OF oDlg PIXEL ACTION (;
        EditCons(aC, oL:nAt, oL), ;
        aColetasCalc := aC, ;
        oSayCalcFrete:Refresh())

    @305,70 BUTTON "Excluir" SIZE 60,12 OF oDlg PIXEL ACTION (;
        ValidaExclusao(aC, oL:nAt, oDlg))

    @305,135 BUTTON "Excel" SIZE 60,12 OF oDlg PIXEL ACTION (;
        ExportExcel(aC))

    @305,200 BUTTON "Visualizar" SIZE 60,12 OF oDlg PIXEL ACTION (;
        VisualizarColeta(aC, oL:nAt))

    @305,580 BUTTON "Fechar" SIZE 60,12 OF oDlg PIXEL ACTION (;
        oDlg:End())

    // Rodape: calculo da porcentagem de frete sobre as coletas filtradas
    // (entre o grid e os botoes de acao - y=330 ficou fora da area visivel no Webapp)
    oSayCalcFrete := TSay():New(292, 5, {|| MontaMsgFrete(aColetasCalc)}, oDlg, , ;
        TFont():New("Arial",, -11, .T., .F.), , , , .T., CLR_HBLUE, , 1200, 14)

    ACTIVATE MSDIALOG oDlg CENTERED

Return


/*/{Protheus.doc} VisualizarColeta
Visualiza dados completos da coleta (consulta ZZ3 e SC7 para totais).
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    aArray, array, Array de coletas
@param    nPos, numeric, Indice no array
/*/
Static Function VisualizarColeta(aArray, nPos)
    Local cPedido := aArray[nPos,1]
    Local cNumZZ3 := aArray[nPos,2]
    Local cStatus := GetStatusColeta(cPedido)
    Local cMsg := ""
    Local cAlias := GetNextAlias()
    Local cAlias2 := GetNextAlias()
    Local nTotPed := 0

    // Busca dados completos da ZZ3 pelo NUMERO da coleta (unico)
    BeginSql Alias cAlias
        SELECT ZZ3_NUM, ZZ3_PEDIDO, ZZ3_FORNEC, ZZ3_LOJA, ZZ3_NOMFOR,
               ZZ3_ENDERE, ZZ3_BAIRRO, ZZ3_CIDADE, ZZ3_UF,
               ZZ3_DTEMIS, ZZ3_DTPREV, ZZ3_DTCOLE, ZZ3_TPFRET,
               ZZ3_PESO, ZZ3_VOLUME, ZZ3_VALCOL, ZZ3_CTE,
               ZZ3_TRANSP, ZZ3_LOJTRA, ZZ3_NOMTRA, ZZ3_TPFRE2,
               ZZ3_PEDVEN, ZZ3_OBS, ZZ3_USUPRO, ZZ3_DTPROG, ZZ3_HRPROG, ZZ3_ITENS
        FROM %Table:ZZ3%
        WHERE %NotDel%
          AND ZZ3_FILIAL = %xFilial:ZZ3%
          AND ZZ3_NUM = %Exp:cNumZZ3%
    EndSql

    If (cAlias)->(Eof())
        MsgAlert("Dados da coleta nao encontrados!", "")
        (cAlias)->(DbCloseArea())
        Return
    EndIf

    // Busca valor total do pedido
    BeginSql Alias cAlias2
        SELECT SUM(C7_TOTAL) AS TOTAL
        FROM %Table:SC7%
        WHERE %NotDel%
          AND C7_FILIAL = %xFilial:SC7%
          AND C7_NUM = %Exp:cPedido%
    EndSql

    If !(cAlias2)->(Eof())
        nTotPed := (cAlias2)->TOTAL
    EndIf
    (cAlias2)->(DbCloseArea())

    // Monta mensagem com todos os dados
    cMsg := "========== DADOS DA COLETA ==========" + CRLF + CRLF

    cMsg += "NUMERO COLETA: " + (cAlias)->ZZ3_NUM + CRLF
    cMsg += "STATUS ATUAL: " + cStatus + CRLF + CRLF

    cMsg += "------- PEDIDO -------" + CRLF
    cMsg += "Pedido Compra: " + (cAlias)->ZZ3_PEDIDO + CRLF
    cMsg += "Pedido Venda: " + (cAlias)->ZZ3_PEDVEN + CRLF
    cMsg += "Valor Total: R$ " + Transform(nTotPed,"@E 999,999,999.99") + CRLF + CRLF

    cMsg += "------- FORNECEDOR -------" + CRLF
    cMsg += "Codigo: " + (cAlias)->ZZ3_FORNEC + "/" + (cAlias)->ZZ3_LOJA + CRLF
    cMsg += "Nome: " + AllTrim((cAlias)->ZZ3_NOMFOR) + CRLF
    cMsg += "Endereco: " + AllTrim((cAlias)->ZZ3_ENDERE) + CRLF
    cMsg += "Bairro: " + AllTrim((cAlias)->ZZ3_BAIRRO) + CRLF
    cMsg += "Cidade: " + AllTrim((cAlias)->ZZ3_CIDADE) + " - " + (cAlias)->ZZ3_UF + CRLF + CRLF

    cMsg += "------- DATAS -------" + CRLF
    cMsg += "Emissao: " + DtoC(StoD((cAlias)->ZZ3_DTEMIS)) + CRLF
    cMsg += "Entrega Prevista: " + DtoC(StoD((cAlias)->ZZ3_DTPREV)) + CRLF
    cMsg += "Data Coleta: " + DtoC(StoD((cAlias)->ZZ3_DTCOLE)) + CRLF + CRLF

    cMsg += "------- TRANSPORTE -------" + CRLF
    cMsg += "Tipo Frete: " + (cAlias)->ZZ3_TPFRET + CRLF
    cMsg += "Tipo Frete 2: " + (cAlias)->ZZ3_TPFRE2 + CRLF
    cMsg += "Transportadora: " + (cAlias)->ZZ3_TRANSP + "/" + (cAlias)->ZZ3_LOJTRA + CRLF
    cMsg += "Nome Transp: " + AllTrim((cAlias)->ZZ3_NOMTRA) + CRLF
    cMsg += "Peso: " + Transform((cAlias)->ZZ3_PESO,"@E 999,999.99") + " kg" + CRLF
    cMsg += "Volume: " + Transform((cAlias)->ZZ3_VOLUME,"@E 999,999.99") + CRLF
    cMsg += "Valor Coleta: R$ " + Transform((cAlias)->ZZ3_VALCOL,"@E 999,999.99") + CRLF
    cMsg += "CTE: " + (cAlias)->ZZ3_CTE + CRLF + CRLF

    cMsg += "------- PROGRAMACAO -------" + CRLF
    cMsg += "Usuario: " + (cAlias)->ZZ3_USUPRO + CRLF
    cMsg += "Data/Hora: " + DtoC(StoD((cAlias)->ZZ3_DTPROG)) + " " + (cAlias)->ZZ3_HRPROG + CRLF + CRLF

    cMsg += "------- OBSERVACOES -------" + CRLF
    cMsg += AllTrim((cAlias)->ZZ3_OBS) + CRLF

    (cAlias)->(DbCloseArea())

    MsgInfo(cMsg, "Visualizacao Completa - Pedido " + cPedido)
Return


/*/{Protheus.doc} ValidaExclusao
Permite exclusao somente se status da coleta for 'Pendente'.
Usa ZZ3_NUM (posicao 2 do array) como identificador.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    aArray, array, Array de coletas
@param    nPos, numeric, Indice no array
@param    oDlg, object, Dialog a ser atualizado
/*/
Static Function ValidaExclusao(aArray, nPos, oDlg)
    Local cPedido  := ""
    Local cNumZZ3  := ""
    Local cStatus  := ""
    Local cIdentif := ""
    Local cNomeFor := ""

    If nPos <= 0 .Or. nPos > Len(aArray)
        MsgAlert("Selecione uma coleta valida para exclusao.", "")
        Return
    EndIf

    cPedido  := aArray[nPos,1]
    cNumZZ3  := aArray[nPos,2]  // Identificador unico da coleta
    cNomeFor := AllTrim(aArray[nPos,3])

    // Monta identificador para exibir ao usuario
    If !Empty(AllTrim(cPedido))
        cIdentif := "pedido " + AllTrim(cPedido) + " (coleta " + AllTrim(cNumZZ3) + ")"
        cStatus  := GetStatusColeta(cPedido)
    Else
        cIdentif := "coleta " + AllTrim(cNumZZ3) + " (Fornec: " + cNomeFor + ")"
        cStatus  := "Incluido"
    EndIf

    // Verifica se o status permite exclusao
    If !(AllTrim(cStatus) $ "Pendente/Incluido/Parcial")
        MsgAlert("ATENCAO!" + CRLF + CRLF + ;
                 "Nao e permitido excluir pedidos com status:" + CRLF + ;
                 cStatus + CRLF + CRLF + ;
                 "Somente pedidos com status 'Pendente', 'Incluido' ou 'Parcial' podem ser excluidos!", "Exclusao Bloqueada")
        Return
    EndIf

    // Pergunta confirmacao com mensagem diferente para Incluido vs Pedido
    If !Empty(AllTrim(cPedido))
        If !MsgYesNo("Confirma a exclusao do pedido " + AllTrim(cPedido) + "?" + CRLF + ;
                     "Coleta: " + AllTrim(cNumZZ3) + CRLF + CRLF + ;
                     "O pedido voltara para o browse principal.", "Confirmar Exclusao")
            Return
        EndIf
    Else
        If !MsgYesNo("Confirma a exclusao da coleta manual " + AllTrim(cNumZZ3) + "?" + CRLF + CRLF + ;
                     "Fornecedor: " + cNomeFor + CRLF + ;
                     "Este registro sera removido permanentemente.", "Confirmar Exclusao")
            Return
        EndIf
    EndIf

    // Executa exclusao no ZZ3 pelo ZZ3_NUM (unico)
    ExcluirColeta(cNumZZ3)

    // Atualiza browse principal ANTES de fechar a tela
    If oBrowseMark != Nil
        oBrowseMark:SetFilterDefault(FiltroPendentesDBF())
        oBrowseMark:ExecuteFilter()
        oBrowseMark:GoTop(.T.)
        oBrowseMark:Refresh(.T.)
    EndIf

    // Remove do array
    aDel(aArray, nPos)
    aSize(aArray, Len(aArray) - 1)

    // Recarrega array completo apos exclusao
    aArray := CarregaColetas()

    If !Empty(AllTrim(cPedido))
        MsgInfo("Pedido " + AllTrim(cPedido) + " excluido com sucesso!" + CRLF + CRLF + ;
                "O pedido voltou para o browse principal." + CRLF + ;
                "Total de coletas restantes: " + cValToChar(Len(aArray)), "Sucesso")
    Else
        MsgInfo("Coleta manual " + AllTrim(cNumZZ3) + " excluida com sucesso!" + CRLF + CRLF + ;
                "Fornecedor: " + cNomeFor + CRLF + ;
                "Total de coletas restantes: " + cValToChar(Len(aArray)), "Sucesso")
    EndIf

    // Fecha e reabre a tela de consulta automaticamente
    If Len(aArray) > 0
        oDlg:End()
        U_ZLGCONS()
    Else
        MsgInfo("Nenhuma coleta restante! A tela sera fechada.", "Informacao")
        oDlg:End()
    EndIf

Return


/*/{Protheus.doc} ExcluirColeta
Exclui entrada em ZZ3 pelo ZZ3_NUM (identificador unico).
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    cNumZZ3, character, Numero da coleta a excluir
/*/
Static Function ExcluirColeta(cNumZZ3)
    Local cAlias := GetNextAlias()

    BeginSql Alias cAlias
        SELECT R_E_C_N_O_ AS RECNO
        FROM %Table:ZZ3%
        WHERE %NotDel%
          AND ZZ3_FILIAL = %xFilial:ZZ3%
          AND ZZ3_NUM = %Exp:cNumZZ3%
    EndSql

    If !(cAlias)->(Eof())
        DbSelectArea("ZZ3")
        ZZ3->(DbGoTo((cAlias)->RECNO))
        RecLock("ZZ3",.F.)
        ZZ3->(DbDelete())
        MsUnlock()
    EndIf

    (cAlias)->(DbCloseArea())
Return


/*/{Protheus.doc} GetStatusColeta
Calcula status da coleta a partir de itens programados (ZZ3.ITENS) e recebimento (SC7/SD1).
Query unificada: SC7 totais + SD1 pre-nota + SC7 pre-nota (QTDACLA) em uma consulta.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    cPedido, character, Numero do pedido
@return   cStatus, character, Status calculado
/*/
Static Function GetStatusColeta(cPedido)
    Local aArea       := GetArea()
    Local cStatus     := "Pendente"
    Local cAliasZZ3   := GetNextAlias()
    Local cAlias      := GetNextAlias()
    Local nTotQuant   := 0
    Local nTotQuje    := 0
    Local lTemPreNota := .F.
    Local lTemParcial := .F.
    Local lTemPrenSC7 := .F.
    Local cItens      := ""
    Local cQuery      := ""
    Local lTemQtdAc   := .F.

    DbSelectArea("SC7")
    lTemQtdAc := (SC7->(FieldPos("C7_QTDACLA")) > 0)

    // Busca itens da coleta na ZZ3
    BeginSql Alias cAliasZZ3
        SELECT ZZ3_ITENS
          FROM %Table:ZZ3%
         WHERE %NotDel%
           AND ZZ3_FILIAL = %xFilial:ZZ3%
           AND ZZ3_PEDIDO = %Exp:cPedido%
    EndSql

    If !(cAliasZZ3)->(Eof())
        cItens := AllTrim((cAliasZZ3)->ZZ3_ITENS)
    EndIf
    (cAliasZZ3)->(DbCloseArea())

    If Empty(cItens)
        RestArea(aArea)
        Return "Incluido"
    EndIf

    cItens := FormataItensSQL(cItens)

    // Query unificada: SC7 totais + SD1 pre-nota + SC7 pre-nota legenda (C7_QTDACLA)
    cQuery := ""
    cQuery += " SELECT"
    cQuery += "   ISNULL(SC7D.TOTQUANT, 0) AS TOTQUANT,"
    cQuery += "   ISNULL(SC7D.TOTQUJE, 0) AS TOTQUJE,"
    cQuery += "   ISNULL(SC7D.PARCIAIS, 0) AS PARCIAIS,"
    cQuery += "   ISNULL(PRE.QTDPRE, 0) AS QTDPRE,"
    If lTemQtdAc
        cQuery += "   ISNULL(PRESC7.QTDPRELEG, 0) AS QTDPRELEG"
    Else
        cQuery += "   0 AS QTDPRELEG"
    EndIf
    cQuery += " FROM ("
    cQuery += "   SELECT"
    cQuery += "     SUM(C7_QUANT) AS TOTQUANT,"
    cQuery += "     SUM(C7_QUJE) AS TOTQUJE,"
    cQuery += "     COUNT(CASE WHEN C7_QUJE > 0 AND C7_QUJE < C7_QUANT THEN 1 END) AS PARCIAIS"
    cQuery += "   FROM " + RetSqlName("SC7")
    cQuery += "   WHERE D_E_L_E_T_ = ' '"
    cQuery += "     AND C7_FILIAL = '" + xFilial("SC7") + "'"
    cQuery += "     AND C7_NUM = '" + cPedido + "'"
    cQuery += "     AND C7_RESIDUO <> 'S'"
    cQuery += "     AND C7_ITEM IN (" + cItens + ")"
    cQuery += " ) SC7D"
    cQuery += " CROSS JOIN ("
    cQuery += "   SELECT COUNT(*) AS QTDPRE"
    cQuery += "   FROM " + RetSqlName("SD1") + " SD1"
    cQuery += "   WHERE SD1.D_E_L_E_T_ = ' '"
    cQuery += "     AND D1_FILIAL = '" + xFilial("SD1") + "'"
    cQuery += "     AND D1_PEDIDO = '" + cPedido + "'"
    cQuery += "     AND D1_ITEMPC IN (" + cItens + ")"
    cQuery += "     AND D1_TIPO = 'B'"
    cQuery += " ) PRE"
    If lTemQtdAc
        cQuery += " CROSS JOIN ("
        cQuery += "   SELECT COUNT(*) AS QTDPRELEG"
        cQuery += "   FROM " + RetSqlName("SC7")
        cQuery += "   WHERE D_E_L_E_T_ = ' '"
        cQuery += "     AND C7_FILIAL = '" + xFilial("SC7") + "'"
        cQuery += "     AND C7_NUM = '" + cPedido + "'"
        cQuery += "     AND C7_ITEM IN (" + cItens + ")"
        cQuery += "     AND C7_RESIDUO <> 'S'"
        cQuery += "     AND C7_QTDACLA > 0"
        cQuery += " ) PRESC7"
    EndIf

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    If !(cAlias)->(Eof())
        nTotQuant   := (cAlias)->TOTQUANT
        nTotQuje    := (cAlias)->TOTQUJE
        lTemParcial := ((cAlias)->PARCIAIS > 0)
        lTemPreNota := ((cAlias)->QTDPRE > 0)
        lTemPrenSC7 := ((cAlias)->QTDPRELEG > 0)
    EndIf
    (cAlias)->(DbCloseArea())

    Do Case
        Case nTotQuje >= nTotQuant .And. nTotQuant > 0
            cStatus := "Coletado"
        Case lTemPreNota .Or. lTemPrenSC7
            cStatus := "Pre Nota"
        Case lTemParcial
            cStatus := "Parcial"
        Otherwise
            cStatus := "Pendente"
    EndCase

    RestArea(aArea)
Return cStatus



/*/{Protheus.doc} AplicaFiltro
Aplica filtros sobre o array retornado por CarregaColetas (data, pedido, status).
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    dDtColetaDe, date, Data inicio
@param    dDtColetaAte, date, Data fim
@param    cPedFiltro, character, Filtro de pedido
@param    cStatusFiltro, character, Filtro de status
@return   aResult, array, Array filtrado
/*/
Static Function AplicaFiltro(dDtColetaDe, dDtColetaAte, cPedFiltro, cStatusFiltro)
    Local aTemp := CarregaColetas()
    Local aResult := {}
    Local i
    Local lOk := .T.
    Local cStatus := ""

    For i := 1 To Len(aTemp)
        lOk := .T.

        // Filtro de data DE
        If !Empty(dDtColetaDe) .And. aTemp[i,10] < dDtColetaDe
            lOk := .F.
        EndIf


        // Filtro de data ATE
        If !Empty(dDtColetaAte) .And. aTemp[i,10] > dDtColetaAte
            lOk := .F.
        EndIf

        // Filtro de pedido
        If !Empty(AllTrim(cPedFiltro)) .And. !(AllTrim(cPedFiltro) $ AllTrim(aTemp[i,1]))
            lOk := .F.
        EndIf

        // Filtro de status
        If cStatusFiltro <> "TODOS"
            cStatus := GetStatusColeta(aTemp[i,1])
            If AllTrim(cStatus) <> AllTrim(cStatusFiltro)
                lOk := .F.
            EndIf
        EndIf

        If lOk
            aAdd(aResult, aTemp[i])
        EndIf
    Next

    If Len(aResult) == 0
        FWAlertInfo("Nenhum registro encontrado")
        Return aTemp
    EndIf

Return aResult


/*/{Protheus.doc} CarregaColetas
Carrega coletas registradas em ZZ3 para exibicao na consulta.
Retorna array com campos selecionados. Usa JOIN para evitar N+1 queries.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@return   aC, array, Array de coletas carregado
/*/
Static Function CarregaColetas()
    Local aC := {}
    Local cAlias := GetNextAlias()
    Local cQuery := ""

    cQuery := " SELECT ZZ3.ZZ3_NUM, ZZ3.ZZ3_PEDIDO, ZZ3.ZZ3_NOMFOR, ZZ3.ZZ3_DTEMIS, ZZ3.ZZ3_TRANSP,"
    cQuery += "        ZZ3.ZZ3_NOMTRA, ZZ3.ZZ3_VALCOL, ZZ3.ZZ3_OBS, ZZ3.ZZ3_FORNEC, ZZ3.ZZ3_LOJA,"
    cQuery += "        ZZ3.ZZ3_CTE, ZZ3.ZZ3_DTCOLE, ZZ3.ZZ3_TPFRE2, ZZ3.ZZ3_PEDVEN,"
    cQuery += "        ISNULL(SC7T.TOTPED, 0) AS TOTPED"
    cQuery += " FROM " + RetSqlName("ZZ3") + " ZZ3"
    cQuery += " LEFT JOIN ("
    cQuery += "   SELECT C7_NUM, SUM(C7_TOTAL) AS TOTPED"
    cQuery += "   FROM " + RetSqlName("SC7")
    cQuery += "   WHERE D_E_L_E_T_ = ' '"
    cQuery += "     AND C7_FILIAL = '" + xFilial("SC7") + "'"
    cQuery += "   GROUP BY C7_NUM"
    cQuery += " ) SC7T ON SC7T.C7_NUM = ZZ3.ZZ3_PEDIDO"
    cQuery += " WHERE ZZ3.D_E_L_E_T_ = ' '"
    cQuery += "   AND ZZ3.ZZ3_FILIAL = '" + xFilial("ZZ3") + "'"
    cQuery += "   AND ZZ3.ZZ3_NUM NOT LIKE 'RASC%'"
    cQuery += " ORDER BY ZZ3.ZZ3_DTPROG DESC, ZZ3.ZZ3_HRPROG DESC"

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        aAdd(aC, {;
            (cAlias)->ZZ3_PEDIDO,;
            (cAlias)->ZZ3_NUM,;
            (cAlias)->ZZ3_NOMFOR,;
            (cAlias)->ZZ3_FORNEC,;
            (cAlias)->ZZ3_NOMTRA,;
            (cAlias)->ZZ3_VALCOL,;
            (cAlias)->ZZ3_OBS,;
            (cAlias)->ZZ3_DTEMIS,;
            (cAlias)->ZZ3_TRANSP,;
            StoD((cAlias)->ZZ3_DTCOLE),;
            (cAlias)->ZZ3_CTE,;
            (cAlias)->ZZ3_LOJA,;
            (cAlias)->ZZ3_TPFRE2,;
            (cAlias)->ZZ3_PEDVEN,;
            (cAlias)->TOTPED})

        (cAlias)->(DbSkip())
    EndDo

    (cAlias)->(DbCloseArea())

Return aC



/*/{Protheus.doc} EditCons
Edicao na consulta: tela para editar registros carregados na consulta.
Atualiza registro em ZZ3 e o array local.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    aArray, array, Array de coletas
@param    nPos, numeric, Indice no array
@param    oListBox, object, Objeto LISTBOX para refresh
/*/
Static Function EditCons(aArray, nPos, oListBox)
    Local oDlg
    Local cPedido  := aArray[nPos,1]
    Local cNomeTr  := aArray[nPos,5]
    Local nVlrCol  := aArray[nPos,6]
    Local cObs     := aArray[nPos,7]
    Local cTransp  := aArray[nPos,9]
    Local cLojaTr  := aArray[nPos,12]
    Local dColeta  := aArray[nPos,10]
    Local cCTE     := aArray[nPos,11]
    Local cTpFrete2:= If(Len(aArray[nPos]) >= 13, aArray[nPos,13], "")
    Local cStatusAtual := GetStatusColeta(cPedido)
    Local oTransp, oLojaTr, oNomeTr

    DEFINE MSDIALOG oDlg TITLE "Editar Coleta - Pedido " + cPedido FROM 0,0 TO 470,500 PIXEL

    @10,10 SAY "Status Atual:" SIZE 50,10 OF oDlg PIXEL
    @10,70 SAY cStatusAtual SIZE 80,10 OF oDlg PIXEL COLOR CLR_BLUE FONT TFont():New("Arial",,-12,.T.)

    @25,10 SAY "Valor Coleta:" SIZE 50,10 OF oDlg PIXEL
    @25,70 MSGET nVlrCol PICTURE "@E 999,999.99" SIZE 60,10 OF oDlg PIXEL

    @40,10 SAY "Data Coleta:" SIZE 50,10 OF oDlg PIXEL
    @40,70 MSGET dColeta SIZE 60,10 OF oDlg PIXEL

    @55,10 SAY "CTE:" SIZE 40,10 OF oDlg PIXEL
    @55,70 MSGET cCTE SIZE 80,10 OF oDlg PIXEL

    @70,10 SAY "Tipo Frete:" SIZE 50,10 PIXEL OF oDlg
    @70,70 MSCOMBOBOX cTpFrete2 ITEMS {"","DEDICADO","FRACIONADO"} SIZE 80,10 OF oDlg PIXEL

    // CAMPOS IGUAIS AOS DA TELA EDITAR PEDIDO

    @85,10  SAY "Transportadora:" SIZE 60,10 OF oDlg PIXEL
    @85,75  MSGET oTransp VAR cTransp F3 "SA2" SIZE 40,10 OF oDlg PIXEL VALID BuscTr(@cTransp, @cLojaTr, @cNomeTr)

    @85,120 SAY "Loja:" SIZE 20,10 OF oDlg PIXEL
    @85,140 MSGET oLojaTr VAR cLojaTr SIZE 20,10 OF oDlg PIXEL VALID BuscTr(@cTransp, @cLojaTr, @cNomeTr)

    @100,75 MSGET oNomeTr VAR cNomeTr WHEN .F. SIZE 165,10 OF oDlg PIXEL

// FIM DOS CAMPOS IGUAIS

    @115,10 SAY "Obs:" SIZE 40,10 OF oDlg PIXEL
    @130,10 GET cObs MULTILINE SIZE 230,55 OF oDlg PIXEL

    @190,120 BUTTON "Salvar" SIZE 40,12 OF oDlg PIXEL ;
             ACTION (SalvarEdit(cPedido, nVlrCol, dColeta, cTransp, cLojaTr, cNomeTr, ;
                                cObs, cCTE, cTpFrete2, aArray, nPos, oListBox), oDlg:End())
    @190,165 BUTTON "Cancelar" SIZE 40,12 OF oDlg PIXEL ACTION oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED
Return


/*/{Protheus.doc} SalvarEdit
Salva as alteracoes feitas na consulta: atualiza SOMENTE o registro ZZ3 correspondente (por ZZ3_NUM).
Valida campos obrigatorios antes de gravar.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    cPedido, character, Numero do pedido
@param    nVlrCol, numeric, Valor da coleta
@param    dColeta, date, Data da coleta
@param    cTransp, character, Codigo transportadora
@param    cLojaTr, character, Loja transportadora
@param    cNomeTr, character, Nome transportadora
@param    cObs, character, Observacao
@param    cCTE, character, CTE
@param    cTpFrete2, character, Tipo frete 2
@param    aArray, array, Array de coletas
@param    nPos, numeric, Indice no array
@param    oListBox, object, Objeto LISTBOX
/*/
Static Function SalvarEdit(cPedido, nVlrCol, dColeta, cTransp, cLojaTr, cNomeTr, cObs, cCTE, cTpFrete2, aArray, nPos, oListBox)
    Local cAliasSav := GetNextAlias()
    Local cNumZZ3   := aArray[nPos,2]  // ZZ3_NUM - identificador unico da coleta

    If Empty(dColeta) .Or. Empty(cTransp)
        MsgAlert("Data de Coleta e Transportadora sao obrigatorios!", "")
        Return
    EndIf

    // Busca SOMENTE o registro especifico pelo ZZ3_NUM (unico)
    BeginSql Alias cAliasSav
        SELECT R_E_C_N_O_ AS RECNO
        FROM %Table:ZZ3%
        WHERE %NotDel%
          AND ZZ3_FILIAL = %xFilial:ZZ3%
          AND ZZ3_NUM = %Exp:cNumZZ3%
    EndSql

    If !(cAliasSav)->(Eof())
        DbSelectArea("ZZ3")
        ZZ3->(DbGoTo((cAliasSav)->RECNO))
        RecLock("ZZ3", .F.)
        ZZ3->ZZ3_VALCOL := nVlrCol
        ZZ3->ZZ3_DTCOLE := dColeta
        ZZ3->ZZ3_TRANSP := cTransp
        ZZ3->ZZ3_LOJTRA := cLojaTr
        ZZ3->ZZ3_NOMTRA := cNomeTr
        ZZ3->ZZ3_OBS    := cObs
        ZZ3->ZZ3_CTE    := cCTE
        ZZ3->ZZ3_TPFRE2 := cTpFrete2
        MsUnlock()
    EndIf
    (cAliasSav)->(DbCloseArea())

    aArray[nPos,5]  := cNomeTr
    aArray[nPos,6]  := nVlrCol
    aArray[nPos,7]  := cObs
    aArray[nPos,9]  := cTransp
    aArray[nPos,10] := dColeta
    aArray[nPos,11] := cCTE
    aArray[nPos,12] := cLojaTr
    If Len(aArray[nPos]) >= 13
        aArray[nPos,13] := cTpFrete2
    EndIf

    If oListBox != Nil
        oListBox:Refresh()
    EndIf

    MsgInfo("Dados atualizados com sucesso!", "Sucesso")
Return

/*/{Protheus.doc} ExportExcel
Exporta para Excel - Usa TReport para gerar saida com exportacao Excel nativa.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    aDados, array, Array de dados a exportar
/*/
Static Function ExportExcel(aDados)
    Local oReport
    Local oSection
    
    // Valida se tem dados
    If Len(aDados) == 0
        MsgAlert("Nenhum dado para exportar!", "")
        Return
    EndIf

    // Cria o objeto TReport
    oReport := TReport():New("ZLOGEXCEL", "Controle Logistico - Coletas", "", ;
        {|oReport| PrintExcelData(oReport, aDados)}, ;
        "Relatorio de coletas logisticas - Filial: " + cFilAnt)

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    // Configura as colunas
    oSection := TRSection():New(oReport, "Coletas", {})

    TRCell():New(oSection, "STATUS",        "", "Status",          "@!", 12)
    TRCell():New(oSection, "PEDIDO",        "", "Pedido",          "@!", 10)
    TRCell():New(oSection, "DTCOLETA",      "", "Dt.Coleta",       "@D", 10)
    TRCell():New(oSection, "FORNECEDOR",    "", "Fornecedor",      "@!", 30)
    TRCell():New(oSection, "TRANSPORTADORA","", "Transportadora",  "@!", 25)
    TRCell():New(oSection, "VLRCOLETA",     "", "Vlr.Coleta",      "@E 999,999.99", 12)
    TRCell():New(oSection, "VLRPEDIDO",     "", "Vlr.Pedido",      "@E 999,999.99", 12)
    TRCell():New(oSection, "CTE",           "", "CTE",             "@!", 10)
    TRCell():New(oSection, "TIPOFRETE",     "", "Tipo Frete",      "@!", 12)
    TRCell():New(oSection, "OBSERVACAO",    "", "Observacao",      "@!", 30)

    oReport:PrintDialog()

Return


/*/{Protheus.doc} PrintExcelData
Imprime os dados do Excel via TReport (chamado automaticamente).
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    oReport, object, Objeto TReport
@param    aDados, array, Array de dados a imprimir
/*/
Static Function PrintExcelData(oReport, aDados)
    Local oSection := oReport:Section(1)
    Local i

    oReport:SetMeter(0)
    oSection:Init()

    For i := 1 To Len(aDados)
        oSection:Cell("STATUS"):SetValue(GetStatusColeta(aDados[i,1]))
        oSection:Cell("PEDIDO"):SetValue(AllTrim(aDados[i,1]))
        oSection:Cell("DTCOLETA"):SetValue(aDados[i,10])
        oSection:Cell("FORNECEDOR"):SetValue(AllTrim(aDados[i,3]))
        oSection:Cell("TRANSPORTADORA"):SetValue(AllTrim(aDados[i,5]))
        oSection:Cell("VLRCOLETA"):SetValue(aDados[i,6])
        oSection:Cell("VLRPEDIDO"):SetValue(If(Len(aDados[i])>=15, aDados[i,15], 0))
        oSection:Cell("CTE"):SetValue(AllTrim(aDados[i,11]))
        oSection:Cell("TIPOFRETE"):SetValue(If(Len(aDados[i])>=13, AllTrim(aDados[i,13]), ""))
        oSection:Cell("OBSERVACAO"):SetValue(AllTrim(aDados[i,7]))

        oSection:PrintLine()
        oReport:IncMeter()
    Next i

    oSection:Finish()
Return

/*/{Protheus.doc} ZLGPRINT
Imprime o browse atual (pedidos pendentes) via TReport com opcao de PDF/Excel.
@author  Suprimentos
@since   25/06/2026
/*/
User Function ZLGPRINT()
    Local aArea    := GetArea()
    Local oReport
    Local oSection
    Local cAlias   := GetNextAlias()
    Local cQuery   := ""
    Local cFiltro  := ""

    cFiltro := MontaFiltroPendentes()
    cFiltro := StrTran(cFiltro, "@", "")

    cQuery := "SELECT C7_NUM, C7_ITEM, C7_EMISSAO, C7_DATPRF, C7_FORNECE,"
    cQuery += " C7_LOJA, C7_PRODUTO, C7_DESCRI, C7_QUANT, C7_QUJE"
    cQuery += " FROM " + RetSqlName("SC7") + " SC7"
    cQuery += " WHERE SC7.D_E_L_E_T_ = ' '"
    cQuery += " AND " + cFiltro
    cQuery += " ORDER BY SC7.C7_NUM, SC7.C7_ITEM"

    cQuery := ChangeQuery(cQuery)

    If Select(cAlias) > 0
        (cAlias)->(DbCloseArea())
    EndIf

    DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)

    If (cAlias)->(Eof())
        MsgAlert("Nenhum pedido pendente para imprimir!", "")
        If Select(cAlias) > 0
            (cAlias)->(DbCloseArea())
        EndIf
        RestArea(aArea)
        Return
    EndIf

    oReport := TReport():New("ZLGBROWSE", "Pedidos Aprovados - Controle Logistico", "", ;
        {|oReport| PrintBrowseRpt(oReport, cAlias)}, ;
        "Lista de pedidos pendentes de coleta - Filial: " + cFilAnt)

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    oSection := TRSection():New(oReport, "Pedidos", {})

    TRCell():New(oSection, "PEDIDO",   "", "Pedido",   "@!", 10)
    TRCell():New(oSection, "ITEM",     "", "Item",     "@!", 4)
    TRCell():New(oSection, "EMISSAO",  "", "Emissao",  "@D", 10)
    TRCell():New(oSection, "ENTREGA",  "", "Entrega",  "@D", 10)
    TRCell():New(oSection, "FORNECE",  "", "Fornec",    "@!", 10)
    TRCell():New(oSection, "LOJA",     "", "Loja",     "@!", 4)
    TRCell():New(oSection, "PRODUTO",  "", "Produto",  "@!", 15)
    TRCell():New(oSection, "DESCRICAO","", "Descricao","@!", 30)
    TRCell():New(oSection, "QUANT",    "", "Qtd",      "@E 999,999.99", 12)
    TRCell():New(oSection, "ENTREGUE", "", "Entregue", "@E 999,999.99", 12)

    oReport:PrintDialog()

    If Select(cAlias) > 0
        (cAlias)->(DbCloseArea())
    EndIf

    RestArea(aArea)
Return

/*/{Protheus.doc} PrintBrowseRpt
Callback do TReport que imprime os registros do alias.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    oReport, object, Objeto TReport
@param    cAlias, character, Alias dos dados a imprimir
/*/
Static Function PrintBrowseRpt(oReport, cAlias)
    Local oSection := oReport:Section(1)

    (cAlias)->(DbGoTop())
    oReport:SetMeter(0)
    oSection:Init()

    While !(cAlias)->(Eof())
        oSection:Cell("PEDIDO"):SetValue(AllTrim((cAlias)->C7_NUM))
        oSection:Cell("ITEM"):SetValue(AllTrim((cAlias)->C7_ITEM))
        oSection:Cell("EMISSAO"):SetValue((cAlias)->C7_EMISSAO)
        oSection:Cell("ENTREGA"):SetValue((cAlias)->C7_DATPRF)
        oSection:Cell("FORNECE"):SetValue(AllTrim((cAlias)->C7_FORNECE))
        oSection:Cell("LOJA"):SetValue(AllTrim((cAlias)->C7_LOJA))
        oSection:Cell("PRODUTO"):SetValue(AllTrim((cAlias)->C7_PRODUTO))
        oSection:Cell("DESCRICAO"):SetValue(AllTrim((cAlias)->C7_DESCRI))
        oSection:Cell("QUANT"):SetValue((cAlias)->C7_QUANT)
        oSection:Cell("ENTREGUE"):SetValue((cAlias)->C7_QUJE)

        oSection:PrintLine()
        oReport:IncMeter()
        (cAlias)->(DbSkip())
    EndDo

    oSection:Finish()
Return


/*/{Protheus.doc} ZLGLGD
Abre legenda simples para o menu principal.
@type     User Function
@author   Suprimentos
@since    25/06/2026
/*/
User Function ZLGLGD()
    BrwLegenda("Controle Logistico","Legenda",{{"BR_VERDE","Pendente"},{"BR_AMARELO","Parcial"}})
Return


/*/{Protheus.doc} CarregarRascunho
Carrega rascunhos salvos anteriormente na tabela ZZ3.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
/*/
Static Function CarregarRascunho()
    Local cAlias := GetNextAlias()
    Local cUsuario := UsrRetName(RetCodUsr())
    Local nQtdRasc := 0
    Local nPos := 0
    Local cPedRasc := ""

    // Verifica se existe rascunho
    BeginSql Alias cAlias
        SELECT COUNT(*) AS QTD
        FROM %Table:ZZ3%
        WHERE %NotDel%
          AND ZZ3_FILIAL = %xFilial:ZZ3%
          AND ZZ3_NUM LIKE 'RASC%'
          AND ZZ3_USUPRO = %Exp:cUsuario%
    EndSql

    If !(cAlias)->(Eof())
        nQtdRasc := (cAlias)->QTD
    EndIf
    (cAlias)->(DbCloseArea())

    If nQtdRasc == 0
        Return
    EndIf

    // Carrega rascunhos e mescla com pedidos existentes no array
    BeginSql Alias cAlias
        SELECT *
        FROM %Table:ZZ3%
        WHERE %NotDel%
          AND ZZ3_FILIAL = %xFilial:ZZ3%
          AND ZZ3_NUM LIKE 'RASC%'
          AND ZZ3_USUPRO = %Exp:cUsuario%
        ORDER BY ZZ3_NUM
    EndSql

    While !(cAlias)->(Eof())
        cPedRasc := AllTrim((cAlias)->ZZ3_PEDIDO)

        // Verifica se o pedido do rascunho ja existe no array (evita duplicata)
        nPos := 0
        If Len(aPedidosSel) > 0
            nPos := aScan(aPedidosSel, {|x| AllTrim(x[1]) == cPedRasc})
        EndIf

        If nPos == 0
            // Pedido nao existe no array - adiciona completo do rascunho
            aAdd(aPedidosSel, {;
                (cAlias)->ZZ3_PEDIDO,;
                StoD((cAlias)->ZZ3_DTEMIS),;
                (cAlias)->ZZ3_FORNEC,;
                (cAlias)->ZZ3_LOJA,;
                (cAlias)->ZZ3_NOMFOR,;
                (cAlias)->ZZ3_ENDERE,;
                (cAlias)->ZZ3_CIDADE,;
                (cAlias)->ZZ3_UF,;
                (cAlias)->ZZ3_BAIRRO,;
                StoD((cAlias)->ZZ3_DTPREV),;
                IIF((cAlias)->ZZ3_TPFRET=="C","CIF",IIF((cAlias)->ZZ3_TPFRET=="F","FOB","Terceiros")),;
                (cAlias)->ZZ3_PESO,;
                (cAlias)->ZZ3_VOLUME,;
                StoD((cAlias)->ZZ3_DTCOLE),;
                (cAlias)->ZZ3_OBS,;
                (cAlias)->ZZ3_TRANSP,;
                (cAlias)->ZZ3_LOJTRA,;
                (cAlias)->ZZ3_NOMTRA,;
                (cAlias)->ZZ3_VALCOL,;
                (cAlias)->ZZ3_PEDVEN,;
                (cAlias)->ZZ3_TPFRE2})
        Else
            // Pedido ja existe no array - atualiza campos editaveis com dados do rascunho
            aPedidosSel[nPos,10] := StoD((cAlias)->ZZ3_DTPREV)
            aPedidosSel[nPos,11] := IIF((cAlias)->ZZ3_TPFRET=="C","CIF",IIF((cAlias)->ZZ3_TPFRET=="F","FOB","Terceiros"))
            aPedidosSel[nPos,12] := (cAlias)->ZZ3_PESO
            aPedidosSel[nPos,13] := (cAlias)->ZZ3_VOLUME
            aPedidosSel[nPos,14] := StoD((cAlias)->ZZ3_DTCOLE)
            aPedidosSel[nPos,15] := (cAlias)->ZZ3_OBS
            aPedidosSel[nPos,16] := (cAlias)->ZZ3_TRANSP
            aPedidosSel[nPos,17] := (cAlias)->ZZ3_LOJTRA
            aPedidosSel[nPos,18] := (cAlias)->ZZ3_NOMTRA
            aPedidosSel[nPos,19] := (cAlias)->ZZ3_VALCOL
            aPedidosSel[nPos,20] := (cAlias)->ZZ3_PEDVEN
            If Len(aPedidosSel[nPos]) >= 21
                aPedidosSel[nPos,21] := (cAlias)->ZZ3_TPFRE2
            Else
                aAdd(aPedidosSel[nPos], (cAlias)->ZZ3_TPFRE2)
            EndIf
        EndIf

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

Return

//=============================================================================

/*/{Protheus.doc} LimparRascunho
Remove todos os rascunhos do usuario na tabela ZZ3.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
/*/
Static Function LimparRascunho()
    Local cAlias := GetNextAlias()
    Local cUsuario := UsrRetName(RetCodUsr())

    BEGIN TRANSACTION

    BeginSql Alias cAlias
        SELECT R_E_C_N_O_ AS RECNO
        FROM %Table:ZZ3%
        WHERE %NotDel%
          AND ZZ3_FILIAL = %xFilial:ZZ3%
          AND ZZ3_NUM LIKE 'RASC%'
          AND ZZ3_USUPRO = %Exp:cUsuario%
    EndSql

    While !(cAlias)->(Eof())
        DbSelectArea("ZZ3")
        ZZ3->(DbGoTo((cAlias)->RECNO))
        RecLock("ZZ3", .F.)
        ZZ3->(DbDelete())
        MsUnlock()
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    END TRANSACTION

Return


/*/{Protheus.doc} BuscTr
Busca transportadora no SA2 e preenche nome; aceita limpar se vazio.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    cTransp, character, Codigo da transportadora
@param    cLojaTr, character, Loja da transportadora
@param    cNomeTr, character, Nome da transportadora (retornado)
@return   lRet, logical, .T. se encontrada
/*/
Static Function BuscTr(cTransp, cLojaTr, cNomeTr)
    Local lRet := .F.
    If Empty(AllTrim(cTransp))
        cNomeTr := Space(40)
        Return .T.
    EndIf

    If Empty(AllTrim(cLojaTr))
        cLojaTr := "01"
    EndIf

SA2->(DbSetOrder(1))  // Ajuste para a ordem correta
    If SA2->(DbSeek(xFilial("SA2")+cTransp+cLojaTr))
        cNomeTr := SA2->A2_NOME
        lRet := .T.
    EndIf

    If !lRet
        MsgAlert("Transportadora nao encontrada!", "")
    EndIf
Return lRet


/*/{Protheus.doc} ValidaGravar
Valida antes de gravar programacao: garante data de coleta e transportadora preenchidas.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@return   lRet, logical, .T. se dados validos
/*/
Static Function ValidaGravar()
    Local i
    Local cMsg := ""
    Local aPendentes := {}

    For i := 1 To Len(aPedidosSel)
        If Empty(aPedidosSel[i,14]) .Or. Empty(aPedidosSel[i,16])
            aAdd(aPendentes, aPedidosSel[i,1])
        EndIf
    Next

    If Len(aPendentes) > 0
        cMsg := "ATENCAO!" + CRLF + CRLF
        cMsg += "Os seguintes pedidos precisam ter:" + CRLF
        cMsg += "- Data de Coleta preenchida" + CRLF
        cMsg += "- Transportadora informada" + CRLF + CRLF
        cMsg += "Pedidos pendentes:" + CRLF
        For i := 1 To Len(aPendentes)
            cMsg += "- " + aPendentes[i] + CRLF
        Next
        MsgAlert(cMsg, "Dados Incompletos")
        Return .F.
    EndIf

Return .T.



/*/{Protheus.doc} FormataItensSQL
Recebe string de itens "001,002,003" ou "001|002|003"
e devolve "'001','002','003'" para usar no IN() do SQL.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    cItens, character, Itens em formato CSV
@return   cResult, character, Itens formatados para SQL
/*/
Static Function FormataItensSQL(cItens)
    Local aItens  := {}
    Local cSep    := ","
    Local nI      := 0
    Local cResult := ""

    cItens := AllTrim(cItens)

    If Empty(cItens)
        Return "''"
    EndIf

    // Se vier separado por pipe, troca para vírgula
    If At("|", cItens) > 0
        cSep := "|"
    EndIf

    aItens := StrTokArr(cItens, cSep)

    For nI := 1 To Len(aItens)
        aItens[nI] := AllTrim(aItens[nI])
        If !Empty(aItens[nI])
            If !Empty(cResult)
                cResult += ","
            EndIf
            cResult += "'" + aItens[nI] + "'"
        EndIf
    Next nI

    If Empty(cResult)
        cResult := "''"
    EndIf

Return cResult
/*/{Protheus.doc} AtualizaFornecedor
Exibe tela para atualizar dados cadastrais do fornecedor do pedido selecionado.
@type     Static Function
@author   Suprimentos
@since    25/06/2026
@param    nPos, numeric, Posicao no array aPedidosSel
/*/
Static Function AtualizaFornecedor(nPos)
    Local oDlgForn, oPanel
    Local oSay1, oSay2, oSay3, oSay4, oSay5, oSay6, oSay7, oSay8, oSay9
    Local oGet1, oGet2, oGet3, oGet4, oGet5, oGet6, oGet7, oGet8
    Local oBtn1, oBtn2

    // Variáveis dos campos do fornecedor
    Local cCodFor := ""
    Local cLojaFor := ""
    Local cNomeFor := ""
    Local cEndFor := Space(80)
    Local cBairFor := Space(60)
    Local cMunFor := Space(60)      // NOVO - Municipio
    Local cEstFor := Space(2)       // NOVO - UF
    Local cCEPFor := Space(8)
    Local cEmailFor := Space(100)
    Local cTelFor := Space(40)

    Local lAlterou := .F.

    // Valida posição
    If nPos <= 0 .Or. nPos > Len(aPedidosSel)
        MsgStop("Selecione um pedido valido!", "")
        Return
    EndIf

    // Busca código do fornecedor do pedido
    DbSelectArea("SC7")
    SC7->(DbSetOrder(1))  // Ordem: C7_FILIAL + C7_NUM

    If SC7->(DbSeek(xFilial("SC7") + aPedidosSel[nPos,1]))
        cCodFor := SC7->C7_FORNECE
        cLojaFor := SC7->C7_LOJA
    Else
        MsgStop("Pedido nao encontrado!", "Erro")
        Return
    EndIf

    DbSelectArea("SA2")
    SA2->(DbSetOrder(1))  // Ordem: A2_FILIAL + A2_COD + A2_LOJA

    If !SA2->(DbSeek(xFilial("SA2") + cCodFor + cLojaFor))
        MsgStop("Fornecedor nao encontrado!", "Erro")
        Return
    EndIf

    // Carrega dados atuais
    cNomeFor := AllTrim(SA2->A2_NOME)
    cEndFor := SA2->A2_END
    cBairFor := SA2->A2_BAIRRO
    cMunFor := SA2->A2_MUN        // NOVO - Municipio
    cEstFor := SA2->A2_EST        // NOVO - UF
    cCEPFor := SA2->A2_CEP
    cEmailFor := SA2->A2_EMAIL
    cTelFor := SA2->A2_TEL

    // Monta tela de edição (altura aumentada)
    DEFINE MSDIALOG oDlgForn TITLE "Atualizar Dados do Fornecedor - " + cCodFor + "/" + cLojaFor FROM 000,000 TO 420,600 PIXEL

    // Painel principal
    oPanel := TPanel():New(000, 000, "", oDlgForn, , , , , , 300, 210, .T., .T.)
    oPanel:Align := CONTROL_ALIGN_ALLCLIENT

    // Linha 1 - Nome (somente leitura)
    @ 010, 010 SAY oSay1 PROMPT "Fornecedor:" SIZE 050, 007 OF oPanel PIXEL
    @ 008, 070 MSGET oGet1 VAR cNomeFor SIZE 200, 010 OF oPanel PIXEL WHEN .F.


    // Linha 2 - Endereço
    @ 028, 010 SAY oSay2 PROMPT "Endereco:" SIZE 050, 007 OF oPanel PIXEL
    @ 026, 070 MSGET oGet2 VAR cEndFor SIZE 200, 010 OF oPanel PIXEL VALID !Empty(cEndFor)

    // Linha 3 - Bairro
    @ 046, 010 SAY oSay3 PROMPT "Bairro:" SIZE 050, 007 OF oPanel PIXEL
    @ 044, 070 MSGET oGet3 VAR cBairFor SIZE 200, 010 OF oPanel PIXEL

    // Linha 4 - Município
    @ 064, 010 SAY oSay4 PROMPT "Municipio:" SIZE 050, 007 OF oPanel PIXEL
    @ 062, 070 MSGET oGet4 VAR cMunFor SIZE 200, 010 OF oPanel PIXEL

    // Linha 5 - UF
    @ 082, 010 SAY oSay5 PROMPT "UF:" SIZE 050, 007 OF oPanel PIXEL
    @ 080, 070 MSGET oGet5 VAR cEstFor SIZE 030, 010 OF oPanel PIXEL PICTURE "@!" F3 "12" VALID ValidaUF(cEstFor)

    // Linha 6 - CEP
    @ 100, 010 SAY oSay6 PROMPT "CEP:" SIZE 050, 007 OF oPanel PIXEL
    @ 098, 070 MSGET oGet6 VAR cCEPFor SIZE 080, 010 OF oPanel PIXEL PICTURE "@R 99999-999" VALID ValidaCEP(cCEPFor)

    // Linha 7 - Email
    @ 118, 010 SAY oSay7 PROMPT "E-mail:" SIZE 050, 007 OF oPanel PIXEL
    @ 116, 070 MSGET oGet7 VAR cEmailFor SIZE 200, 010 OF oPanel PIXEL VALID ValidaEmail(cEmailFor)

    // Linha 8 - Telefone
    @ 136, 010 SAY oSay8 PROMPT "Telefone:" SIZE 050, 007 OF oPanel PIXEL
    @ 134, 070 MSGET oGet8 VAR cTelFor SIZE 100, 010 OF oPanel PIXEL

    // Mensagem de confirmação
    @ 154, 010 SAY oSay9 PROMPT "Os dados serao atualizados diretamente no cadastro do fornecedor." SIZE 280, 007 OF oPanel PIXEL FONT TFont():New(, , 10, .T.) COLOR CLR_RED

    // Botões
    @ 174, 070 BUTTON oBtn1 PROMPT "Confirmar" SIZE 050, 015 OF oPanel PIXEL ACTION (lAlterou := .T., oDlgForn:End())
    @ 174, 130 BUTTON oBtn2 PROMPT "Cancelar" SIZE 050, 015 OF oPanel PIXEL ACTION oDlgForn:End()

    ACTIVATE MSDIALOG oDlgForn CENTERED

    // Se confirmou, atualiza o cadastro
    If lAlterou
        If MsgYesNo("Confirma a atualizacao dos dados do fornecedor " + cCodFor + "/" + cLojaFor + "?", "Confirmacao")

            DbSelectArea("SA2")
            SA2->(DbSetOrder(1))

            If SA2->(DbSeek(xFilial("SA2") + cCodFor + cLojaFor))

                RecLock("SA2", .F.)
                SA2->A2_END := cEndFor
                SA2->A2_BAIRRO := cBairFor
                SA2->A2_MUN := cMunFor      // NOVO - Municipio
                SA2->A2_EST := cEstFor      // NOVO - UF
                SA2->A2_CEP := cCEPFor
                SA2->A2_EMAIL := cEmailFor
                SA2->A2_TEL := cTelFor
                SA2->(MsUnlock())

                MsgInfo("Dados do fornecedor atualizados com sucesso!", "Sucesso")

                // Atualiza o array com os novos dados (ajuste conforme sua estrutura)
                aPedidosSel[nPos,6] := cEndFor      // Endereço
                aPedidosSel[nPos,7] := cMunFor      // Município
                aPedidosSel[nPos,8] := cEstFor      // UF
                aPedidosSel[nPos,9] := cBairFor     // Bairro

            Else
                MsgStop("Erro ao localizar fornecedor para gravacao!", "Erro")
            EndIf

        EndIf
    EndIf

Return


/*/{Protheus.doc} ValidaUF
Valida sigla da UF (2 caracteres)
@type     function
@author   Juan Almeida
@since    2026.02.03
/*/
Static Function ValidaUF(cUF)
    Local lRet := .T.
    Local aUFs := {"AC","AL","AP","AM","BA","CE","DF","ES","GO","MA","MT","MS","MG","PA","PB","PR","PE","PI","RJ","RN","RS","RO","RR","SC","SP","SE","TO"}

    cUF := Upper(AllTrim(cUF))

    If !Empty(cUF)
        If Len(cUF) <> 2
            MsgStop("UF invalida! Deve conter 2 caracteres.", "")
            lRet := .F.
        ElseIf aScan(aUFs, cUF) == 0
            MsgStop("UF invalida! Sigla nao encontrada.", "")
            lRet := .F.
        EndIf
    EndIf

Return lRet


/*/{Protheus.doc} ValidaCEP
Valida formato do CEP
@type     function
@author   Juan Almeida
@since    2026.02.03
/*/
Static Function ValidaCEP(cCEP)
    Local lRet := .T.

    // Remoção de caracteres não numéricos
    cCEP := StrTran(cCEP, "-", "")
    cCEP := StrTran(cCEP, ".", "")

    // Valida se tem 8 dígitos
    If !Empty(cCEP) .And. Len(AllTrim(cCEP)) <> 8
        MsgStop("CEP invalido! Deve conter 8 digitos.", "")
        lRet := .F.
    EndIf

Return lRet


/*/{Protheus.doc} ValidaEmail
Valida formato do email
@type     function
@author   Juan Almeida
@since    2026.02.03
/*/
Static Function ValidaEmail(cEmail)
    Local lRet := .T.

    cEmail := AllTrim(cEmail)

    // Valida formato esperado (arroba e ponto após o arroba)
    If !Empty(cEmail)
        If !("@" $ cEmail) .Or. !("." $ SubStr(cEmail, At("@", cEmail), Len(cEmail)))
            MsgStop("E-mail invalido! Formato esperado: exemplo@dominio.com", "")
            lRet := .F.
        EndIf
    EndIf

Return lRet

//=============================================================================
// User Function ZLGRESUMO
// Descricao: Exibe resumo de pedidos pendentes por fornecedor.
//=============================================================================
User Function ZLGRESUMO()
    Local aR           := {}
    Local oDlg
    Local oL
    Local cFornFiltro  := Space(6)
    Local dEntDe       := CtoD("")
    Local dEntAte      := CtoD("")
    Local cFreteFiltro := "TODOS"
    Local oForn, oDtDe, oDtAte, oFrete

    aR := CarregaResumoFornec()

    If Len(aR) == 0
        MsgAlert("Nenhum pedido pendente encontrado.", "Resumo Pedidos")
        Return
    EndIf

    DEFINE MSDIALOG oDlg TITLE "Resumo Pedidos Pendentes - " + cValToChar(Len(aR)) + " itens" ;
        FROM 0,0 TO 420,1100 PIXEL

    // Filtros
    @005,005 SAY "Fornecedor:"  SIZE 045,010 OF oDlg PIXEL
    @005,055 MSGET oForn  VAR cFornFiltro SIZE 045,010 OF oDlg PIXEL
    @005,105 SAY "Entrega DE:" SIZE 045,010 OF oDlg PIXEL
    @005,155 MSGET oDtDe VAR dEntDe SIZE 050,010 OF oDlg PIXEL
    @005,210 SAY "ATE:" SIZE 020,010 OF oDlg PIXEL
    @005,235 MSGET oDtAte VAR dEntAte SIZE 050,010 OF oDlg PIXEL
    @005,295 SAY "Tp.Frete:" SIZE 040,010 OF oDlg PIXEL
    @005,340 MSCOMBOBOX oFrete VAR cFreteFiltro ITEMS {"TODOS","CIF","FOB"} SIZE 060,010 OF oDlg PIXEL

    // ListBox principal
    @040,005 LISTBOX oL FIELDS HEADER ;
        "Fornec/Loja",    ;
        "Nome Fornecedor",;
        "Pedidos",        ;
        "Qtd.Pend.",      ;
        "Vlr.Total",      ;
        "Entrega",        ;
        "Tp.Frete"        ;
        SIZE 1000,260 OF oDlg PIXEL
    oL:aColSizes := {100, 330, 70, 105, 135, 90, 70}
    oL:SetArray(aR)
    oL:bLine := {|| ZLGRESUMO_Linha(aR, oL:nAt)}
    oL:nLen := Len(aR)

    // Botões - linha 1
    @020,005 BUTTON "Filtrar" SIZE 040,012 OF oDlg PIXEL ACTION (;
        aR := FiltraResumo(CarregaResumoFornec(), cFornFiltro, dEntDe, dEntAte, cFreteFiltro), ;
        oL:nAt := 1, ;
        oL:SetArray(aR), ;
        oL:bLine := {|| ZLGRESUMO_Linha(aR, oL:nAt)}, ;
        oL:Refresh(), ;
        oDlg:Refresh())

    @020,050 BUTTON "Limpar" SIZE 040,012 OF oDlg PIXEL ACTION (;
        cFornFiltro := Space(6), ;
        dEntDe := CtoD(""), ;
        dEntAte := CtoD(""), ;
        cFreteFiltro := "TODOS", ;
        oForn:Refresh(), ;
        oDtDe:Refresh(), ;
        oDtAte:Refresh(), ;
        oFrete:Refresh(), ;
        aR := CarregaResumoFornec(), ;
        oL:nAt := 1, ;
        oL:SetArray(aR), ;
        oL:bLine := {|| ZLGRESUMO_Linha(aR, oL:nAt)}, ;
        oL:Refresh(), ;
        oDlg:Refresh())

    @020,095 BUTTON "Atualizar" SIZE 050,012 OF oDlg PIXEL ACTION (;
        aR := CarregaResumoFornec(), ;
        oL:nAt := 1, ;
        oL:SetArray(aR), ;
        oL:bLine := {|| ZLGRESUMO_Linha(aR, oL:nAt)}, ;
        oL:Refresh(.T.), ;
        oDlg:Refresh())

    // Botões - linha 2
    @305,005  BUTTON "Excel"  SIZE 060,012 OF oDlg PIXEL ACTION ExportaResumoFornec(aR)
    @305,1210 BUTTON "Fechar" SIZE 085,012 OF oDlg PIXEL ACTION oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED

Return

//=============================================================================

//=============================================================================
// Static Function CarregaResumoFornec
// Descricao: Retorna resumo agrupado por fornecedor e pedido.
//=============================================================================
Static Function CarregaResumoFornec()
    Local aR      := {}
    Local cAlias  := GetNextAlias()
    Local cQuery  := ""
    Local cTabSC7 := RetSqlName("SC7")
    Local cTabSA2 := RetSqlName("SA2")
    Local cTabZZ3 := RetSqlName("ZZ3")
    Local cFilSC7 := xFilial("SC7")
    Local cFilSA2 := xFilial("SA2")
    Local cFilZZ3 := xFilial("ZZ3")

    cQuery := " SELECT SC7.C7_FORNECE,"
    cQuery += "        SC7.C7_LOJA,"
    cQuery += "        ISNULL(RTRIM(SA2.A2_NOME), '') AS NOMFOR,"
    cQuery += "        COUNT(DISTINCT SC7.C7_NUM)      AS PEDIDOS,"
    cQuery += "        SUM(SC7.C7_QUANT - SC7.C7_QUJE) AS SALDO,"
    cQuery += "        SUM(SC7.C7_TOTAL)               AS TOTAL,"
    cQuery += "        MIN(SC7.C7_DATPRF)              AS DTPRF,"
    cQuery += "        MAX(CASE SC7.C7_TPFRETE WHEN 'C' THEN 'CIF'"
    cQuery += "                                WHEN 'F' THEN 'FOB'"
    cQuery += "             ELSE RTRIM(SC7.C7_TPFRETE) END) AS TPFRETE"
    cQuery += " FROM " + cTabSC7 + " SC7"
    cQuery += " LEFT JOIN " + cTabSA2 + " SA2"
    cQuery += "   ON SA2.D_E_L_E_T_ = ' '"
    cQuery += "  AND SA2.A2_FILIAL  = '" + cFilSA2 + "'"
    cQuery += "  AND SA2.A2_COD     = SC7.C7_FORNECE"
    cQuery += "  AND SA2.A2_LOJA    = SC7.C7_LOJA"
    cQuery += " WHERE SC7.D_E_L_E_T_ = ' '"
    cQuery += "   AND SC7.C7_FILIAL  = '" + cFilSC7 + "'"
    cQuery += "   AND SC7.C7_RESIDUO <> 'S'"
    cQuery += "   AND SC7.C7_QUJE    < SC7.C7_QUANT"
    cQuery += "   AND RTRIM(SC7.C7_CONAPRO) IN ('', 'L')"
    cQuery += "   AND SC7.C7_ENCER   <> 'E'"

    DbSelectArea("SC7")
    If SC7->(FieldPos("C7_QTDACLA")) > 0
        cQuery += "   AND SC7.C7_QTDACLA = 0"
    EndIf

    cQuery += "   AND NOT EXISTS ("
    cQuery += "       SELECT 1"
    cQuery += "       FROM " + cTabZZ3 + " ZZZ"
    cQuery += "       WHERE ZZZ.D_E_L_E_T_ = ' '"
    cQuery += "         AND ZZZ.ZZ3_FILIAL = '" + cFilZZ3 + "'"
    cQuery += "         AND RTRIM(ZZZ.ZZ3_PEDIDO) = SC7.C7_NUM"
    cQuery += "   )"
    cQuery += " GROUP BY SC7.C7_FORNECE, SC7.C7_LOJA, SA2.A2_NOME"
    cQuery += " ORDER BY ISNULL(RTRIM(SA2.A2_NOME), SC7.C7_FORNECE),"
    cQuery += "          SC7.C7_FORNECE, SC7.C7_LOJA,"
    cQuery += "          MIN(SC7.C7_DATPRF)"

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        aAdd(aR, {;
            RTRIM((cAlias)->C7_FORNECE),;
            RTRIM((cAlias)->C7_LOJA),;
            RTRIM((cAlias)->NOMFOR),;
            (cAlias)->PEDIDOS,;
            (cAlias)->SALDO,;
            (cAlias)->TOTAL,;
            IIf(!Empty(RTRIM((cAlias)->DTPRF)), StoD(RTRIM((cAlias)->DTPRF)), CtoD("  /  /  ")),;
            RTRIM((cAlias)->TPFRETE)})

        (cAlias)->(DbSkip())
    EndDo

    (cAlias)->(DbCloseArea())

Return aR

//=============================================================================

//=============================================================================
// Static Function FiltraResumo
// Descricao: Filtra o array de resumo por fornecedor, data e frete.
//=============================================================================
Static Function FiltraResumo(aFull, cForn, dDe, dAte, cFrete)
    Local aResult := {}
    Local i
    Local lOk

    For i := 1 To Len(aFull)
        lOk := .T.

        If !Empty(AllTrim(cForn))
            If !(Upper(AllTrim(cForn)) $ Upper(AllTrim(aFull[i,1]))) .And. ;
               !(Upper(AllTrim(cForn)) $ Upper(AllTrim(aFull[i,3])))
                lOk := .F.
            EndIf
        EndIf

        If !Empty(dDe) .And. aFull[i,7] < dDe
            lOk := .F.
        EndIf

        If !Empty(dAte) .And. aFull[i,7] > dAte
            lOk := .F.
        EndIf

        If cFrete <> "TODOS"
            If AllTrim(aFull[i,8]) <> cFrete
                lOk := .F.
            EndIf
        EndIf

        If lOk
            aAdd(aResult, aFull[i])
        EndIf
    Next i

    If Len(aResult) == 0
        FWAlertInfo("Nenhum registro encontrado com os filtros informados.")
        Return aFull
    EndIf

Return aResult

//=============================================================================

//=============================================================================
// Static Function ExportaResumoFornec
// Descricao: Exporta resumo agrupado por fornecedor via TReport.
//=============================================================================
Static Function ExportaResumoFornec(aRez)
    Local oReport
    Local oSection

    If Len(aRez) == 0
        MsgAlert("Nenhum dado para exportar!", "")
        Return
    EndIf

    oReport := TReport():New("ZLGRESXL", ;
        "Resumo Pedidos Pendentes por Fornecedor", "", ;
        {|oReport| PrintResumoFornec(oReport, aRez)}, ;
        "Pedidos Pendentes por Fornecedor - Filial: " + cFilAnt)

    oReport:SetLandscape(.T.)
    oReport:SetTotalInLine(.F.)

    oSection := TRSection():New(oReport, "Pedidos", {})

    TRCell():New(oSection, "FORNECLOJA", "", "Fornec/Loja",     "@!",                12)
    TRCell():New(oSection, "NOMFOR",     "", "Nome Fornecedor", "@!",                40)
    TRCell():New(oSection, "PEDIDOS",    "", "Pedidos",         "@E 999",            10)
    TRCell():New(oSection, "SALDO",      "", "Qtd.Pend.",       "@E 999,999.99",     14)
    TRCell():New(oSection, "VALOR",      "", "Vlr.Total",       "@E 999,999,999.99", 18)
    TRCell():New(oSection, "ENTREGA",    "", "Entrega",         "@D",                10)
    TRCell():New(oSection, "TPFRETE",    "", "Tp.Frete",        "@!",                 8)

    oReport:PrintDialog()

Return

//=============================================================================

//=============================================================================
// Static Function PrintResumoFornec
// Descricao: Impressao via TReport do resumo agrupado.
//=============================================================================
Static Function PrintResumoFornec(oReport, aRez)
    Local oSection := oReport:Section(1)
    Local i

    oReport:SetMeter(0)
    oSection:Init()

    For i := 1 To Len(aRez)
        oSection:Cell("FORNECLOJA"):SetValue(AllTrim(aRez[i][1]) + "/" + AllTrim(aRez[i][2]))
        oSection:Cell("NOMFOR"):SetValue(AllTrim(aRez[i][3]))
        oSection:Cell("PEDIDOS"):SetValue(aRez[i][4])
        oSection:Cell("SALDO"):SetValue(aRez[i][5])
        oSection:Cell("VALOR"):SetValue(aRez[i][6])
        oSection:Cell("ENTREGA"):SetValue(aRez[i][7])
        oSection:Cell("TPFRETE"):SetValue(AllTrim(aRez[i][8]))

        oSection:PrintLine()
        oReport:IncMeter()
    Next i

    oSection:Finish()

Return

//=============================================================================

//=============================================================================
// Static Function ZLGRESUMO_Linha
// Descricao: Monta array de exibicao de uma linha do listbox de resumo.
//            Separada da closure para evitar problemas de escopo em builds
//            antigos do Protheus com variaveis LOCAL em code blocks.
//            Retorna array de 7 strings (uma por coluna do listbox).
//=============================================================================
Static Function ZLGRESUMO_Linha(aRez, nAt)
    Local aRet := {"","","","","","",""}

    If nAt >= 1 .And. nAt <= Len(aRez)
        aRet[1]  := AllTrim(aRez[nAt][1]) + "/" + AllTrim(aRez[nAt][2])
        aRet[2]  := AllTrim(aRez[nAt][3])
        aRet[3]  := AllTrim(aRez[nAt][4])
        aRet[4]  := AllTrim(aRez[nAt][5])
        aRet[5]  := AllTrim(aRez[nAt][6])
        aRet[6]  := AllTrim(aRez[nAt][7])
        aRet[7]  := AllTrim(aRez[nAt][8])
    EndIf

Return aRet