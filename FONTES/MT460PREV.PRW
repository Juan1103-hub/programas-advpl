#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} MT460PREV
Ponto de entrada / menu para adicionar botao Preview DANFE
no SPEDNFE (SIGAFAT). Adiciona opcao "Preview DANFE" no
menu de acoes do SPEDNFE ou via customizacao de menu.

Para ativar:
1. Registrar no menu: ADD OPTION aRotina TITLE "Preview DANFE" ACTION "U_MT460PREV()" OPERATION 6 ACCESS 0
2. Ou chamar diretamente via U_MT460PREV()

O usuario seleciona a NF no browse do SPEDNFE e executa
a acao para gerar o preview antes de transmitir.

@type User Function
@version 12.1.33
@author Suprimentos
@since 23/06/2026
/*/
User Function MT460PREV(cSerie, cNumero)
    Local aArea    := GetArea()
    Local aRet     := {}
    Local aPergs   := {}

    ConOut("[MT460PREV] Chamado - Serie: [" + cValToChar(cSerie) + "] Numero: [" + cValToChar(cNumero) + "]")

    If cSerie == Nil .Or. cNumero == Nil
        cNumero := ""
        cSerie  := ""

        aAdd(aPergs, {1, "Numero NF", Space(9), "", "", "", "", 20, .T.})
        aAdd(aPergs, {1, "Serie",     Space(3), "", "", "", "", 10, .T.})

        If ParamBox(aPergs, "Preview DANFE - Informe a NF", @aRet, , , , , , , , .T., .F.)
            cNumero := AllTrim(aRet[1])
            cSerie  := AllTrim(aRet[2])

            ConOut("[MT460PREV] ParamBox - NF " + cNumero + "/" + cSerie)

            If Empty(cNumero) .Or. Empty(cSerie)
                MsgAlert("Informe o numero e a serie da NF.", "Atencao")
                RestArea(aArea)
                Return
            EndIf
        Else
            RestArea(aArea)
            Return
        EndIf
    Else
        cSerie  := AllTrim(cSerie)
        cNumero := AllTrim(cNumero)
        ConOut("[MT460PREV] Params diretos - NF " + cNumero + "/" + cSerie)
    EndIf

    u_ZPREVNFE(cSerie, cNumero)

    RestArea(aArea)
Return Nil

/*/{Protheus.doc} MenuDef
Registra a opcao no menu do SPEDNFE
@type Static Function
@return Array, aRotina
/*/
Static Function MenuDef()
    Local aRotina := {}

    aAdd(aRotina, {"Preview DANFE", "U_MT460PREV()", 0, 6})

Return aRotina
