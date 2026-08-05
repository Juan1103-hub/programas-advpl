#include "protheus.ch"
#Include "TopConn.ch"

//--------------------------------------------------------------
/*/{Protheus.doc} FALTFPED

Rotina para alteracao direta do fornecedor e/ou tipo de frete
do pedido de compras (SC7), sem necessidade de aprovacao.
Permite ao comprador localizar o pedido, visualizar o fornecedor
atual e o tipo de frete, e substitui-los por novos valores.
Fornecedor e frete sao independentes: pode alterar um sem o outro.
A gravacao e feita via UPDATE direto no banco de dados.

@param  Nenhum
@return Nenhum
@author
@since  02/11/2023
/*/
//--------------------------------------------------------------

User Function FALTFPED()

// Variaveis locais da interface
Local oButCanc                                                                // Botao Cancelar
Local oFont1 := TFont():New("Microsoft YaHei",,022,,.F.,,,,,.F.,.F.)          // Fonte padrao dos textos
Local oGetLojaNew                                                             // Objeto GET da loja do novo fornecedor

// Variaveis de controle do fornecedor anterior (antes da alteracao)
Private cCodAnt := ''                // Codigo do fornecedor anterior
Private cLojAnt := ''                // Loja do fornecedor anterior

// Objetos e variaveis dos campos de entrada
Private oGetPed                      // Objeto GET do numero do pedido
Private oSayNewFor                   // Objeto SAY do nome do novo fornecedor
Private cGetForNew := Space(06)      // Codigo do novo fornecedor digitado
Private cGetLojaNew := Space(02)     // Loja do novo fornecedor digitada
Private oButConf                     // Botao Alterar (confirmar)
Private oGetForNew                   // Objeto GET do novo fornecedor

// Objetos dos grupos visuais (molduras)
Private oGroup1                      // Grupo "Numero do Pedido"
Private oGroup2                      // Grupo "Fornecedor do Pedido"
Private oGroup3                      // Grupo "Alterar Para"
Private oDlgPed                      // Dialogo principal

// Variaveis de exibicao do pedido/fornecedor atual
Private cGetPed := Space(06)         // Numero do pedido digitado pelo usuario
Private cSayForA := ''               // Texto com codigo/loja/CNPJ do fornecedor atual
Private cSayLojA := ''               // Nome reduzido do fornecedor atual
Private cSayNewFor := ''             // Nome reduzido + CNPJ do novo fornecedor
Private oSayFor1                     // Objeto SAY - linha 1 do fornecedor atual
Private oSayFor2                     // Objeto SAY - linha 2 do fornecedor atual
Private lWhen := .F.                 // Controle de habilitacao dos campos de edicao
Private cGetCond := Space(03)         // Nova condicao de pagamento
Private oGetCond                     // Objeto GET da condicao
Private oChkEst                      // Checkbox atualiza estoque

// Variaveis do tipo de frete
Private oGroup4                      // Grupo "Tipo de Frete"
Private oSayFreteAtu                 // Objeto SAY do frete atual
Private oComboFrete                  // Combobox de selecao do novo frete
Private cSayFreteAtu := ''           // Texto do tipo de frete atual
Private aItemsFrete := {"C - CIF","F - FOB","S - Sem Frete"}  // Opcoes do combobox de frete
Private nTpFreteNew := 1             // Indice da opcao selecionada no combo de frete
Private cFreteOrig := ''             // Letra do frete original do pedido (para comparacao)

// Variaveis da condicao de pagamento e atualizacao de estoque
Private oGroup5                      // Grupo "Condicao Pagto / Estoque"
Private oSayCondAtu                  // Objeto SAY da condicao atual
Private oComboCond                   // Combobox de selecao da nova condicao
Private cSayCondAtu := ''            // Texto da condicao de pagamento atual
Private nCondNew := 1                // Indice da condicao selecionada
Private cCondOrig := ''              // Condicao original do pedido
Private lEstoqueNew := .F.           // Atualiza estoque (C7_XESTOQ1)
Private cEstoqueOrig := ''           // Valor original de C7_XESTOQ1

  // Criacao do dialogo principal
  DEFINE MSDIALOG oDlgPed TITLE "Atualizar Fornecedor" FROM 000, 000  TO 430, 500 COLORS 0, 16777215 PIXEL

    //--- Grupo 1: Campo para informar o numero do pedido de compras (SC7) ---
    @ 007, 007 GROUP oGroup1 TO 032, 242 PROMPT "Numero do Pedido:" OF oDlgPed COLOR 0, 16777215 PIXEL
    @ 017, 015 MSGET oGetPed VAR cGetPed SIZE 060, 010 OF oDlgPed COLORS 0, 16777215 PIXEL F3 "SC7" Valid FTemPed()


    //--- Grupo 2: Exibe dados do fornecedor atual do pedido ---
    @ 037, 007 GROUP oGroup2 TO 089, 242 PROMPT "Fornecedor do Pedido:" OF oDlgPed COLOR 0, 16777215 PIXEL

    // Exibicao do codigo/loja/CNPJ e nome do fornecedor atual
    @ 050, 015 SAY oSayFor1 PROMPT cSayForA SIZE 206, 010 OF oDlgPed FONT oFont1 COLORS 0, 16777215 PIXEL
    @ 068, 015 SAY oSayFor2 PROMPT cSayLojA SIZE 215, 014 OF oDlgPed FONT oFont1 COLORS 0, 16777215 PIXEL

    //--- Grupo 3: Campos para informar o novo fornecedor ---
    @ 092, 008 GROUP oGroup3 TO 145, 241 PROMPT "Alterar Para: " OF oDlgPed COLOR 0, 16777215 PIXEL
    @ 106, 014 MSGET oGetForNew VAR cGetForNew SIZE 060, 010 OF oDlgPed COLORS 0, 16777215 PIXEL F3 "SA2" When lWhen Valid FNewForn()  // Consulta F3 no cadastro SA2
    @ 105, 083 MSGET oGetLojaNew VAR cGetLojaNew SIZE 045, 010 OF oDlgPed COLORS 0, 16777215 PIXEL When .F.  // Loja preenchida automaticamente, nao editavel

    // Exibe nome reduzido e CNPJ do novo fornecedor selecionado
    @ 126, 014 SAY oSayNewFor PROMPT cSayNewFor SIZE 214, 012 OF oDlgPed FONT oFont1 COLORS 0, 16777215 PIXEL

    //--- Grupo 4: Selecao do tipo de frete (independente do fornecedor) ---
    @ 148, 008 GROUP oGroup4 TO 198, 241 PROMPT "Tipo de Frete:" OF oDlgPed COLOR 0, 16777215 PIXEL
    @ 160, 014 SAY oSayFreteAtu PROMPT cSayFreteAtu SIZE 214, 012 OF oDlgPed FONT oFont1 COLORS 0, 16777215 PIXEL  // Exibe o frete atual do pedido
    @ 178, 014 COMBOBOX oComboFrete VAR nTpFreteNew ITEMS aItemsFrete SIZE 100, 012 OF oDlgPed PIXEL When lWhen  // Combobox para selecionar novo tipo de frete (habilitado ao localizar pedido)

    //--- Grupo 5: Condicao de pagamento e atualizacao de estoque ---
    @ 200, 008 GROUP oGroup5 TO 260, 241 PROMPT "Condicao Pgto / Estoque:" OF oDlgPed COLOR 0, 16777215 PIXEL
    @ 212, 014 SAY oSayCondAtu PROMPT cSayCondAtu SIZE 214, 012 OF oDlgPed FONT oFont1 COLORS 0, 16777215 PIXEL  // Exibe a condicao atual
    @ 230, 014 SAY "Condicao Pgto:" SIZE 060, 010 OF oDlgPed PIXEL
    @ 230, 074 MSGET oGetCond SIZE 045, 010 OF oDlgPed COLORS 0, 16777215 PIXEL When lWhen F3 "SE4" Valid FValCond()
    @ 230, 125 SAY "Atualiza Estoque:" SIZE 070, 010 OF oDlgPed PIXEL
    @ 230, 195 CHECKBOX oChkEst VAR lEstoqueNew SIZE 015, 010 OF oDlgPed PIXEL When lWhen

    // Botoes de acao
    @ 268, 141 BUTTON oButConf PROMPT "Alterar" SIZE 037, 012 OF oDlgPed PIXEL Action fGrava()       // Executa a gravacao no banco
    @ 268, 192 BUTTON oButCanc PROMPT "Cancelar" SIZE 037, 012 OF oDlgPed PIXEL Action oDlgPed:End() // Fecha o dialogo sem salvar

  ACTIVATE MSDIALOG oDlgPed CENTERED

Return
//--------------------------------------------------------------
// fGrava() - Executa UPDATE direto na SC7 atualizando:
//   - Fornecedor (C7_FORNECE / C7_LOJA)
//   - Fornecedor anterior (C7_CODANT / C7_LOJANT)
//   - Tipo de frete (C7_TPFRETE)
//   - Usuario e data da alteracao (C7_USERALT / C7_DTALTE)
// Filtra pelo numero do pedido e filial corrente.
//--------------------------------------------------------------
Static Function fGrava()

Local cQuery       := ""
Local nQueryRet    := 0
Local lAltFor      := !Empty(AllTrim(cGetForNew))  // Verifica se informou novo fornecedor
Local lAltCond     := .F.   // Indica se a condicao foi alterada
Local cEstoqueNew  := ""    // Novo valor para C7_XESTOQ1
Local lAltEstoque  := .F.   // Indica se o flag de estoque foi alterado

// Extrai a letra do tipo de frete a partir do item selecionado no combobox (ex: "C" de "C=CIF")
Local cTpFreteGrava := ""
Local lAltFrete := .F.                // Indica se o frete foi alterado

If ValType(nTpFreteNew) == "C"
    cTpFreteGrava := Left(nTpFreteNew, 1)
Else
    cTpFreteGrava := Left(aItemsFrete[nTpFreteNew], 1)
EndIf

// Verifica se o frete foi alterado em relacao ao original
lAltFrete := (cTpFreteGrava <> cFreteOrig)

// Verifica se a condicao ou estoque foi alterado
lAltCond    := !Empty(AllTrim(cGetCond)) .And. AllTrim(cGetCond) <> AllTrim(cCondOrig)
cEstoqueNew := If(lEstoqueNew, "1", "2")
lAltEstoque := cEstoqueNew <> cEstoqueOrig

// Nao permite alterar fornecedor e frete ao mesmo tempo
If lAltFor .And. lAltFrete
    MsgStop("Nao e permitido alterar fornecedor e frete ao mesmo tempo. Altere um de cada vez!")
    Return(.F.)
EndIf

// Verifica se ao menos um foi alterado
If !lAltFor .And. !lAltFrete .And. !lAltCond .And. !lAltEstoque
    MsgStop("Nenhuma alteracao foi informada!")
    Return(.F.)
EndIf

// Monta o UPDATE
cQuery := "UPDATE " + RetSqlName("SC7") + " SET "

// Atualiza fornecedor somente se foi informado um novo
If lAltFor
    cQuery += "C7_FORNECE = '" + cGetForNew  + "', "
    cQuery += "C7_LOJA = '"    + cGetLojaNew + "', "
    cQuery += "C7_CODANT = '"  + cCodAnt     + "', "
    cQuery += "C7_LOJANT = '"  + cLojAnt     + "', "
EndIf

// Atualiza frete somente se foi alterado
If lAltFrete
    cQuery += "C7_TPFRETE = '" + cTpFreteGrava + "', "
EndIf

// Atualiza condicao de pagamento se foi alterada
If lAltCond
    cQuery += "C7_COND = '" + cGetCond + "', "
EndIf

// Atualiza flag de estoque se foi alterada (1=Sim, 2=Nao)
If lAltEstoque
    cQuery += "C7_XESTOQ1 = '" + cEstoqueNew + "', "
EndIf

// Sempre grava usuario e data da alteracao
cQuery += "C7_USERALT = '" + UsrRetName(RetCodUsr()) + "', "
cQuery += "C7_DTALTE = '"  + DTOS(dDataBase) + "' "
cQuery += "WHERE D_E_L_E_T_ <> '*' AND "
cQuery += "C7_FILIAL = '" + xFilial("SC7") + "' AND "
cQuery += "C7_NUM = '" + cGetPed + "' "

nQueryRet := TCSQLEXEC(cQuery)

// Verifica se houve erro na execucao
If nQueryRet < 0
    MsgStop("Erro na query: " + Chr(10) + TCSQLError())
    Return(.F.)
Endif

MsgInfo("Pedido " + AllTrim(cGetPed) + " atualizado com sucesso!", "Concluido")

// Fecha o dialogo apos a gravacao
oDlgPed:End()

Return(.T.)
//--------------------------------------------------------------
// FLocPed() - Localiza o pedido informado e carrega na tela:
//   - Dados do fornecedor atual (codigo, loja, CNPJ, nome)
//   - Tipo de frete atual do pedido
// Apos carregar, habilita os campos de edicao (lWhen = .T.)
//--------------------------------------------------------------
Static Function FLocPed()

Local cAlias   := GetNextAlias()
Local cQuery   := ""
Local cFornece := ""
Local cLoja    := ""
Local cTpFrete := ""
Local nQuant   := 0
Local nQuje    := 0
Local cResiduo := ""
Local cConapro := ""
Local cMotivo  := ""

// Valida se o numero do pedido foi preenchido
If Empty(cGetPed)
   MsgStop("Informe o numero do pedido de compras!")
   Return
EndIf

// Busca dados do pedido via SQL para garantir dados corretos
cQuery := " SELECT TOP 1"
cQuery += "   LTRIM(RTRIM(C7_FORNECE)) AS FORNECE,"
cQuery += "   LTRIM(RTRIM(C7_LOJA))    AS LOJA,"
cQuery += "   LTRIM(RTRIM(C7_TPFRETE)) AS TPFRETE,"
cQuery += "   C7_QUANT                  AS QUANT,"
cQuery += "   C7_QUJE                   AS QUJE,"
cQuery += "   LTRIM(RTRIM(C7_RESIDUO))  AS RESIDUO,"
cQuery += "   LTRIM(RTRIM(C7_CONAPRO)) AS CONAPRO,"
cQuery += "   LTRIM(RTRIM(C7_COND))    AS CONDICAO,"
cQuery += "   LTRIM(RTRIM(C7_XESTOQ1)) AS XESTOQ1"
cQuery += " FROM " + RetSqlName("SC7")
cQuery += " WHERE D_E_L_E_T_ = ' '"
cQuery += "   AND C7_FILIAL = '" + xFilial("SC7") + "'"
cQuery += "   AND C7_NUM = '" + cGetPed + "'"
cQuery := ChangeQuery(cQuery)
DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

If (cAlias)->(Eof())
   (cAlias)->(DbCloseArea())
   MsgStop("Pedido nao encontrado!", "Atencao")
   Return
EndIf

cFornece   := AllTrim((cAlias)->FORNECE)
cLoja      := AllTrim((cAlias)->LOJA)
cTpFrete   := AllTrim((cAlias)->TPFRETE)
nQuant     := (cAlias)->QUANT
nQuje      := (cAlias)->QUJE
cResiduo   := AllTrim((cAlias)->RESIDUO)
cConapro   := AllTrim((cAlias)->CONAPRO)
cCondOrig  := AllTrim((cAlias)->CONDICAO)
cEstoqueOrig := AllTrim((cAlias)->XESTOQ1)
(cAlias)->(DbCloseArea())

// Somente pedidos PENDENTES (verde) podem ser alterados
// Verde = Aprovado (C7_CONAPRO = "L"), sem recebimento (C7_QUJE = 0), sem residuo (C7_RESIDUO <> "S")
If cConapro <> "L" .Or. nQuje > 0 .Or. cResiduo == "S"
   cMotivo := ""
   Do Case
      Case cConapro == "B"
         cMotivo := "Pedido em aprovacao."
      Case cConapro == "R"
         cMotivo := "Pedido rejeitado pelo aprovador."
      Case cResiduo == "S"
         cMotivo := "Pedido eliminado por residuo."
      Case nQuje > 0 .And. nQuje >= nQuant
         cMotivo := "Pedido ja recebido."
      Case nQuje > 0
         cMotivo := "Pedido recebido parcialmente."
      OtherWise
         cMotivo := "Pedido nao esta com status Pendente."
   EndCase
   MsgStop(cMotivo + CRLF + "Somente pedidos Pendentes (verde) podem ser alterados!", "Bloqueado")
   lWhen := .F.
   Return
EndIf

// Busca o fornecedor atual do pedido na tabela SA2
dbSelectArea("SA2")
dbSetOrder(01)
If dbSeek(xFilial("SA2") + PadR(cFornece, TamSX3("A2_COD")[1]) + PadR(cLoja, TamSX3("A2_LOJA")[1]))
   cCodAnt := SA2->A2_COD
   cLojAnt := SA2->A2_LOJA

   cSayForA := AllTrim(SA2->A2_COD) + "/" + AllTrim(SA2->A2_LOJA) + " - " + "CPF/CNPJ: " + AllTrim(SA2->A2_CGC)
   cSayLojA := SubStr(SA2->A2_NREDUZ,1,45)

   Do Case
      Case cTpFrete == "C"
         cSayFreteAtu := "Frete atual: CIF"
         nTpFreteNew := 1
      Case cTpFrete == "F"
         cSayFreteAtu := "Frete atual: FOB"
         nTpFreteNew := 2
      Case cTpFrete == "S"
         cSayFreteAtu := "Frete atual: Sem Frete"
         nTpFreteNew := 3
      OtherWise
         cSayFreteAtu := "Frete atual: " + cTpFrete
         nTpFreteNew := 1
   EndCase

cFreteOrig := cTpFrete

    // Exibe condicao de pagamento atual
    cSayCondAtu := "Condicao atual: " + cCondOrig
    lEstoqueNew := (cEstoqueOrig == "1")

    lWhen := .T.
   oComboFrete:SetFocus()
Else
   MsgStop("Fornecedor nao localizado. Verifique o numero do pedido de compras informado!")
   Return
EndIf

// Atualiza todos os componentes visuais da tela
oSayFor1:Refresh()
oSayFor2:Refresh()
oGetForNew:Refresh()
oSayFreteAtu:Refresh()
oComboFrete:Refresh()
oGroup1:Refresh()
oGroup3:Refresh()
oGroup4:Refresh()
oGroup5:Refresh()
oSayCondAtu:Refresh()
oGetCond:Refresh()
oChkEst:Refresh()
oDlgPed:Refresh()
Return
//--------------------------------------------------------------
// FTemPed() - Validacao do campo numero do pedido.
// Quando o usuario troca o pedido, limpa os dados exibidos
// do fornecedor e frete anteriores para forcar nova busca.
// Se nao havia dados carregados, carrega automaticamente via FLocPed().
//--------------------------------------------------------------
Static Function FTemPed()

// Limpa os campos de exibicao ao trocar de pedido
cSayForA := ''
cSayLojA := ''
cSayNewFor := ''
cGetForNew := Space(06)
cGetLojaNew := Space(02)
cSayFreteAtu := ''
nTpFreteNew := 1
cFreteOrig := ''
cSayCondAtu := ''
cGetCond := Space(03)
lEstoqueNew := .F.
cCondOrig := ''
cEstoqueOrig := ''
lWhen := .F.

// Atualiza os componentes visuais
oSayFor1:Refresh()
oSayFor2:Refresh()
oSayNewFor:Refresh()
oGetForNew:Refresh()
oSayFreteAtu:Refresh()
oComboFrete:Refresh()
oSayCondAtu:Refresh()
oGetCond:Refresh()
oChkEst:Refresh()
oGroup1:Refresh()
oGroup5:Refresh()
oDlgPed:Refresh()

// Carrega automaticamente os dados do pedido informado
If !Empty(cGetPed)
   FLocPed()
EndIf

Return(.T.)

//--------------------------------------------------------------
// FNewForn() - Validacao do campo do novo fornecedor.
// Busca o fornecedor digitado na SA2 e exibe seus dados.
// Retorna .T. se o fornecedor foi encontrado, .F. caso contrario.
//--------------------------------------------------------------
Static Function FNewForn()

Local lRet := .F.

// Se o campo estiver vazio, permite sair (frete pode ser alterado sem fornecedor)
If Empty(AllTrim(cGetForNew))
   cSayNewFor := ''
   oSayNewFor:Refresh()
   Return(.T.)
EndIf

// Busca o novo fornecedor informado na SA2
dbSelectArea("SA2")
dbSetOrder(01)  // Indice por Filial + Codigo + Loja
If dbSeek(xFilial("SA2")+cGetForNew+cGetLojaNew)
   // Monta texto de exibicao com nome reduzido e CNPJ do novo fornecedor
   cSayNewFor := SubStr(SA2->A2_NREDUZ,1,45) + " - " + "CPF/CNPJ: " + SA2->A2_CGC
   oButConf:SetFocus()  // Posiciona foco no botao Alterar
   lRet := .T.
Else
   MsgStop("Fornecedor nao localizado. Verifique o codigo informado!")
EndIf

// Atualiza os componentes visuais
oSayNewFor:Refresh()
oGroup3:Refresh()
oDlgPed:Refresh()

Return(lRet)

//--------------------------------------------------------------
// FValCond() - Validacao do campo condicao de pagamento.
// Busca a condicao informada na SE4 e exibe seus dados.
// Retorna .T. se a condicao foi encontrada, .F. caso contrario.
//--------------------------------------------------------------
Static Function FValCond()

Local lRet := .F.

// Se o campo estiver vazio, permite sair
If Empty(AllTrim(cGetCond))
   Return(.T.)
EndIf

// Busca a condicao de pagamento informada na SE4
dbSelectArea("SE4")
dbSetOrder(01)  // Indice por Filial + Codigo
If dbSeek(xFilial("SE4") + cGetCond)
   // Valida se a condicao esta ativa
   If SE4->E4_MSBLQL == "1"
      MsgStop("Condicao de pagamento inativa. Verifique o codigo informado!")
      Return(.F.)
   EndIf
   oChkEst:SetFocus()  // Posiciona foco no checkbox
   lRet := .T.
Else
   MsgStop("Condicao de pagamento nao localizada. Verifique o codigo informado!")
EndIf

Return(lRet)
