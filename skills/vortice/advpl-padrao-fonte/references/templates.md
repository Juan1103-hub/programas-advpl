# Templates de fonte — padrao Vortice

> Todos tirados dos fontes de referencia deste repositorio. Onde o original tinha
> divida (nome de arquivo, `IIF`), a forma foi normalizada — o molde e o alvo, nao a
> copia literal do legado.
> Troque apenas nome, tabela e regra; **a forma fica**.
> Antes de usar, abra o fonte de origem citado e confira se ele nao mudou.

---

## A. Ponto de entrada de validacao (grid `aCols`)

Origem: `FONTES/MT110TOK.PRW` (validacao do TudoOK do MATA110).

```advpl
#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} MT110TOK
Validacao TudoOK da Solicitacao de Compra (MATA110).

Responsabilidade unica:
  Bloquear inclusao/alteracao de itens cujo produto possui estoque
  de seguranca (B1_ESTSEG > 0), exceto para usuarios autorizados.

Usuarios liberados: 000047, 000080, 000095, 000057.

@type     user function
@author   Eurai Rapelli / Suprimentos
@since    2023.01.01
@version  4.2 - 07/06/2026 - Date() em vez de dDataBase para C1_EMISSAO de novos
@return   logical, .T. = Permite gravar | .F. = Bloqueia
/*/
User Function MT110TOK()
    Local aArea      := GetArea()
    Local aAreaSC1   := SC1->(GetArea())
    Local lRet       := .T.
    Local nX         := 0
    Local nPosEmiss  := 0
    Local cProduto   := ""
    Local nEstSeg    := 0
    Local aUsersLib  := {"000047", "000080", "000095", "000057"}
    Local lUserLib   := .F.
    Local cMsgItens  := ""
    Local lBloqueado := .F.

    // Usuario liberado: nao valida nada
    lUserLib := (aScan(aUsersLib, {|x| AllTrim(x) == AllTrim(RetCodUsr())}) > 0)
    If lUserLib
        RestArea(aAreaSC1)
        RestArea(aArea)
        Return .T.
    EndIf

    // --- 1) Localiza as colunas do grid (nunca assumir posicao fixa) ---
    nPosEmiss := aScan(aHeader, {|x| AllTrim(Upper(x[2])) == "C1_EMISSAO"})

    // --- 2) Percorre as linhas validas ---
    For nX := 1 To Len(aCols)

        // Linha marcada como deletada no grid
        If aCols[nX][Len(aCols[nX])]
            Loop
        EndIf

        cProduto := GdFieldGet("C1_PRODUTO", nX)
        If Empty(cProduto)
            Loop
        EndIf

        DbSelectArea("SB1")
        SB1->(DbSetOrder(1))
        If SB1->(DbSeek(xFilial("SB1") + cProduto))
            nEstSeg := SB1->B1_ESTSEG
            If nEstSeg > 0
                cMsgItens  += AllTrim(cProduto) + CRLF
                lBloqueado := .T.
            EndIf
        EndIf

    Next nX

    // --- 3) Mensagem fora do laco, uma vez so ---
    If lBloqueado
        MsgStop("ITEM CONTROLADO POR MINIMO/MAXIMO." + CRLF + CRLF + ;
                "COMPRA BLOQUEADA PARA SEU USUARIO." + CRLF + CRLF + ;
                "Itens bloqueados:" + CRLF + CRLF + ;
                cMsgItens, ;
                "Acesso Negado")
        lRet := .F.
    EndIf

    RestArea(aArea)
    RestArea(aAreaSC1)

Return lRet
```

**Nao esqueca:** `aHeader`/`aCols`/`PARAMIXB` sao injetados — valide `ValType`
antes de usar (`If ValType(PARAMIXB) == "A"`). Mensagem no fim, nunca dentro do `For`.

---

## B. Ponto de entrada de menu (`aRotina`)

Origem: `FONTES/MA410MNU.PRW`.

```advpl
#include "protheus.ch"

/*/{Protheus.doc} MA410MNU
Ponto de entrada do MATA410 que adiciona a opcao
"Preview NF-e TSS" no menu "Outras Acoes" do Pedido de Venda.

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
```

**Nao esqueca:** item 2 da tupla e a **chamada** com `U_`; item 4 e o tipo de
acao (1=pesquisa, 2=visualizar, 3=incluir/alterar, 5=excluir, 6=outros).

---

## C. Ponto de entrada de gatilho SX7 (`M->`)

Origem: `FONTES/ZPOSITEM.PRW` (gatilho `FFZC1ITM`, campo `ZC1_ITEM`).

```advpl
#Include "Protheus.ch"
#Include "TopConn.ch"

#Define CRLF Chr(13) + Chr(10)

//-------------------------------------------------------------------
/*/{Protheus.doc} FFZC1ITM
Regra de gatilho SX7 no campo ZC1_ITEM do AxCadastro ZC1.

Ao informar o item, preenche automaticamente:
  ZC1_DESCRI <- SB1->B1_DESC
  ZC1_LOCAL  <- armazem da SB2 com B2_QATU > 0, ou o 1o existente

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   2026
@return  nSaldo, numeric, saldo do armazem escolhido (para X7_CDOMIN)
/*/
//-------------------------------------------------------------------
User Function FFZC1ITM()

    Local aArea    := GetArea()
    Local aAreaSB1 := {}
    Local aAreaSB2 := {}
    Local cItem    := ""
    Local cLocal   := ""
    Local nSaldo   := 0

    // Campo origem vazio: nada a preencher
    If Empty(M->ZC1_ITEM)
        RestArea(aArea)
        Return 0
    EndIf

    // --- SB1: descricao (ordem 1 = B1_FILIAL + B1_COD) ---
    If Select("SB1") <= 0
        ChkFile("SB1")
    EndIf

    If Select("SB1") > 0
        aAreaSB1 := SB1->(GetArea())
        DbSelectArea("SB1")
        SB1->(DbSetOrder(1))
        cItem := PadR(AllTrim(M->ZC1_ITEM), TamSX3("B1_COD")[1])
        If SB1->(DbSeek(xFilial("SB1") + cItem))
            M->ZC1_DESCRI := PadR(SB1->B1_DESC, TamSX3("ZC1_DESCRI")[1])
        Else
            M->ZC1_DESCRI := Space(TamSX3("ZC1_DESCRI")[1])
        EndIf
        RestArea(aAreaSB1)
    EndIf

    M->ZC1_LOCAL := PadR(cLocal, TamSX3("ZC1_LOCAL")[1])
    M->ZC1_SALDO := nSaldo

    RestArea(aArea)

Return nSaldo
```

**Nao esqueca:** gatilho alimenta `M->` (buffer do formulario), nao `Alias->`;
`PadR(..., TamSX3("campo")[1])` para respeitar o tamanho do dicionario.

---

## D. Rotina/relatorio com query TopConnect

Origem: `FONTES/ZANALBX.PRW` (ParamBox) + `FONTES/CADSZ3.PRW:586-600` (query).

```advpl
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} ZSLDEST
Saldo de estoque por armazem no periodo.

Premissas:
  - Somente registros ativos (D_E_L_E_T_ = ' ').
  - Filial corrente (xFilial), nunca filial fixa.
  - Leitura de relatorio: hint WITH (NOLOCK) reaplicado apos ChangeQuery().

@type    User Function
@author  Suprimentos
@since   01/09/2026
@version 12.1.33
@return  nil
/*/
User Function ZSLDEST()

    Local aArea  := GetArea()
    Local aPar   := {}
    Local aRet   := {}
    Local dDtDe  := CtoD("  /  /    ")
    Local dDtAte := CtoD("  /  /    ")
    Local cAlias := GetNextAlias()
    Local cQuery := ""

    aAdd(aPar, {1, "Data Inicial", dDtDe,  "", "", "", "", 60, .T.})
    aAdd(aPar, {1, "Data Final",   dDtAte, "", "", "", "", 60, .T.})

    If !ParamBox(aPar, "Saldo de Estoque por Armazem", @aRet)
        RestArea(aArea)
        Return
    EndIf

    dDtDe  := aRet[1]
    dDtAte := aRet[2]

    // --- Validacoes de negocio ---
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

    // --- 1) Query (campos explicitos, filial, soft-delete) ---
    cQuery := "SELECT Z3_ID, Z3_DESCRI, Z3_UM, Z3_ZDTSOL "
    cQuery += "  FROM " + RetSqlName("SZ3") + " Z3 WITH (NOLOCK) "
    cQuery += " WHERE D_E_L_E_T_ = ' ' "
    cQuery += "   AND Z3_FILIAL = '" + xFilial("SZ3") + "' "
    cQuery += "   AND Z3_ZDTSOL BETWEEN '" + DtoS(dDtDe) + "' AND '" + DtoS(dDtAte) + "' "
    cQuery += " ORDER BY Z3_ZDTSOL, Z3_ID "
    cQuery := ChangeQuery(cQuery)
    cQuery := StrTran(cQuery, "(NOLOCK)", "")              // normaliza (evita dica duplicada)
    cQuery := StrTran(cQuery, " WITH ", " WITH (NOLOCK) ") // reinjeta a dica que o ChangeQuery remove

    // --- 2) Abre o alias ---
    If Select(cAlias) > 0
        (cAlias)->(DbCloseArea())
    EndIf
    DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)

    If (cAlias)->(Eof())
        MsgAlert("Nenhum registro encontrado para o periodo informado.", "Atencao")
        (cAlias)->(DbCloseArea())
        RestArea(aArea)
        Return
    EndIf

    // --- 3) Processa ---
    While !(cAlias)->(Eof())
        // ... acumula em array / monta TReport
        (cAlias)->(DbSkip())
    EndDo

    (cAlias)->(DbCloseArea())
    RestArea(aArea)

Return
```

**Nao esqueca:** `NOLOCK` nao entra em leitura que alimenta gravacao ou calculo
financeiro; `TCGenQry` recebe a query ja com tabela fisica (`RetSqlName`).

---

## E. Tela mBrowse sobre query

Origem: `FONTES/CADSOLIC.PRW`.

```advpl
#Include "Protheus.ch"
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} CADSOLIC
Browse unificado de Solicitacoes Cadastrais - Produtos e Fornecedores.

Utiliza mBrowse padrao do Protheus sobre uma query TOPCONN UNION ALL
que combina os registros de SZ3 (Produtos) e SZ4 (Fornecedores).

Colunas do alias ZU_SOL:
  ZU_TIPO  - "P"=Produto  / "F"=Fornecedor
  ZU_ID    - ID da solicitacao
  ZU_STS   - "0"=Pendente / "1"=Cadastrado / "2"=Rejeitado

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   20/04/2026
/*/
//-------------------------------------------------------------------
User Function CADSOLIC()

    Local cAlias := "ZU_SOL"
    Local aArea  := GetArea()

    FSOL_AbreQuery(cAlias)

    If Select(cAlias) == 0
        MsgStop("Erro ao abrir consulta de solicitacoes.", "Solicitacao Cadastral")
        RestArea(aArea)
        Return
    EndIf

    // Privates obrigatorias para mBrowse
    Private cCadastro := "Solicitacao Cadastral"
    Private cDelFunc  := "U_CSOLPODEXC()"
    Private cString   := cAlias

    // Cores: branco=Pendente / cinza=Cadastrado / preto=Rejeitado
    Private aCores := {{ cAlias + "->ZU_STS == '0'", "BR_BRANCO" },;
                       { cAlias + "->ZU_STS == '1'", "DISABLE"   },;
                       { cAlias + "->ZU_STS == '2'", "BR_PRETO"  }}

    // Menu: os 3 primeiros ficam na barra; o resto em "Outras Acoes"
    Private aRotina := { {"Incluir"   , "U_CSOLINC()" , 0, 3},;
                         {"Alterar"   , "U_CSOLALT()" , 0, 3},;
                         {"Visualizar", "U_CSOLVIZ()" , 0, 3},;
                         {"Pesquisar" , "AxPesqui"    , 0, 1},;
                         {"Excluir"   , "U_CSOLEXC()" , 0, 5},;
                         {"Legenda"   , "U_CSOLLES()" , 0, 6}}

    (cAlias)->(dbSetOrder(1))
    (cAlias)->(dbGoTop())

    // Parametro 7 = cColunas: campos do alias a exibir
    mBrowse(6, 1, 22, 75, cAlias, ,;
        "ZU_TIPO;ZU_ID;ZU_USR;ZU_PRAZO;ZU_DESC;ZU_STS;ZU_DTSOL",;
        , , , aCores)

    If Select(cAlias) > 0
        (cAlias)->(dbCloseArea())
    EndIf

    RestArea(aArea)

Return
```

**Nao esqueca:** `Private` de tela (`cCadastro`, `cString`, `aRotina`, `aCores`)
pode vir **depois** do codigo — e injecao para o framework, nao declaracao comum.
Acoes de `aRotina` sao `User Function` no mesmo arquivo ou em arquivo proprio.

---

## F. Classe TLPP (SmartView / ON / REST)

Origem: `FONTES/SC7TREP.tlpp`.

```tlpp
#include "tlpp-core.th"
#include "msobject.ch"
#include "totvs.ch"
#Include "totvs.framework.treports.integratedprovider.th"

/*/{Protheus.doc} SC7TREP
Objeto de Negocio (ON) SmartView para o Pedido de Compra (SC7).

Requisito: TL++ e LIB Label >= 12.1.2210 (recomendado >= 12.1.2310).
Apos compilar, reiniciar o AppServer para o ON ficar disponivel em REST.

@type    class
@author  Suprimentos
@since   06/08/2026
@version 2.2
@see     patterns-smartview-integratedprovider.md
/*/

namespace custom.compras.pedidocompra.integratedprovider

@totvsFrameworkTReportsIntegratedProvider(active=.T., team="SIGACOM", tables="SC7,SA2,SE4,SY1", name="Pedido de Compra", country="ALL", initialRelease="12.1.2210")

class SC7TReportsBusinessObject from totvs.framework.treports.integratedprovider.IntegratedProvider
    public method new() as object
    public method getDisplayName() as character
    public method getAreas() as array
    public method getData() as object
    public method getSchema() as object
endclass

/*/{Protheus.doc} new
Construtor padrao do ON: define area, nome e descricao.

@type   Method
@return Object, self
/*/
method new() as object class SC7TReportsBusinessObject
    _Super:new()
    self:appendArea("Compras")
    self:setDisplayName("Pedido de Compra")
    self:setDescription("Pedido de Compra completo: itens, valores, impostos, fornecedor e comprador")
return self

/*/{Protheus.doc} getDisplayName
Retorna o nome de exibicao do ON no SmartView.

@type   Method
@return character, Nome de exibicao
/*/
method getDisplayName() as character class SC7TReportsBusinessObject
return "Pedido de Compra"
```

**Nao esqueca:** em TLPP o tipo vem **depois** da atribuicao
(`Local cNome := "" as Character`); na declaracao, `static method` vai sem
parametros; implementacao nunca repete modificador de acesso.
