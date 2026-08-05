//=================================================================================
// Ponto de Entrada: MTA105OK
// Descrição: Validação na confirmação da Solicitação ao Armazém (MATA105)
// Objetivo: 1) Bloquear solicitação de itens com saldo zero
//           2) Alertar quando quantidade solicitada > saldo disponível
// Retorno: .T. = Permite gravar | .F. = Bloqueia gravação
//=================================================================================
#Include "Protheus.ch"

User Function MTA105OK()
    Local lRet := .T.
    Local aArea := GetArea()
    Local aAreaSB2 := SB2->(GetArea())
    Local nX := 0
    Local cProduto := ""
    Local cLocal := ""
    Local nQuant := 0
    Local nSaldo := 0
    Local cMsgSemSaldo := ""      // Itens com saldo ZERO
    Local cMsgInsuficiente := ""  // Itens com saldo INSUFICIENTE
    Local cMsgFinal := ""         // Declarar AQUI no início
    Local lBloqueado := .F.
    
    // Percorre todos os itens da solicitação
    For nX := 1 To Len(aCols)
        
        // Ignora linhas deletadas
        If aCols[nX][Len(aCols[nX])]
            Loop
        EndIf
        
        // Obtém os dados do item
        cProduto := GdFieldGet("CP_PRODUTO", nX)
        cLocal   := GdFieldGet("CP_LOCAL", nX)
        nQuant   := GdFieldGet("CP_QUANT", nX)
        
        // Busca saldo disponível
        nSaldo := BuscaSaldoDisp(cProduto, cLocal)
        
        // *** VALIDAÇÃO 1: Saldo Zero ou Negativo ***
        If nSaldo <= 0
            cMsgSemSaldo += AllTrim(cProduto) + " | Armazem: " + AllTrim(cLocal) + " | Saldo: " + Transform(nSaldo,"@E 999,999.99") + CRLF
            lBloqueado := .T.
        
        // *** VALIDAÇÃO 2: Quantidade maior que saldo ***
        ElseIf nQuant > nSaldo
        cMsgInsuficiente += AllTrim(cProduto) + " | Armazem: " + AllTrim(cLocal)
        cMsgInsuficiente += " | Solicitado: " + Transform(nQuant,"@E 999,999.99")
        cMsgInsuficiente += " | Disponivel: " + Transform(nSaldo,"@E 999,999.99") + CRLF
        lBloqueado := .T.
    EndIf
        Next nX
    
    // Se encontrou algum bloqueio, exibe mensagem
    If lBloqueado
        
        cMsgFinal := "SOLICITACAO BLOQUEADA!" + CRLF + CRLF  // Agora só atribui valor
        
        // Monta mensagem de itens sem saldo
        If !Empty(cMsgSemSaldo)
            cMsgFinal += "Itens SEM SALDO:" + CRLF + CRLF
            cMsgFinal += cMsgSemSaldo + CRLF
        EndIf
        
        // Monta mensagem de itens com quantidade insuficiente
        If !Empty(cMsgInsuficiente)
            cMsgFinal += "Itens com SALDO INSUFICIENTE:" + CRLF + CRLF
            cMsgFinal += cMsgInsuficiente + CRLF
        EndIf
        
        cMsgFinal += "Por favor, ajuste as quantidades ou remova os itens."
        
        Aviso("Saldo Insuficiente", cMsgFinal, {"OK"}, 3)
        lRet := .F.
    EndIf
    
    // Restaura áreas
    RestArea(aAreaSB2)
    RestArea(aArea)
    
Return lRet

Static Function BuscaSaldoDisp(cProduto, cLocal)
    Local nSaldo := 0
    Local aArea := GetArea()
    
    DbSelectArea("SB2")
    SB2->(DbSetOrder(1))
    
    If SB2->(DbSeek(xFilial("SB2") + cProduto + cLocal))
        nSaldo := SB2->B2_QATU
    EndIf
    
    RestArea(aArea)
    
Return nSaldo
