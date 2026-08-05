#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} U_ZTESTTEL
Tela de teste - Consulta de Pedidos (818x360).
13 colunas com larguras hardcoded mais largas que o LISTBOX
para testar HSCROLL.

LISTBOX 818x360 | Colunas somam 1420px

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   22/06/2026
/*/
User Function ZTESTTEL()
    Local aArea := GetArea()
    Local oDlg
    Local oL
    Local aTeste := {}
    Local aFinalCols := {90,160,100,60,120,150,150,120,60,60,100,100,150}

    aAdd(aTeste, {"PC001", "FORNECEDOR ALPHA LTDA", "NF-1234", "001", CtoD("15/06/2026"), 15420.50, 1234.50, "30 DDL", "0102", "BRL", 1.00, "TRP-01", "PEDIDO URGENTE"})
    aAdd(aTeste, {"PC002", "BETA DISTRIBUIDORA S.A.", "NF-5678", "002", CtoD("20/06/2026"), 8750.00, 700.00, "45 DDL", "0102", "BRL", 1.00, "TRP-02", "AGUARDANDO"})
    aAdd(aTeste, {"PC003", "GAMMA INDUSTRIA EPP", "NF-9012", "001", CtoD("22/06/2026"), 32100.00, 2568.00, "15 DDL", "0103", "USD", 4.85, "TRP-03", ""})
    aAdd(aTeste, {"PC004", "DELTA COMERCIO LTDA", "NF-3456", "003", CtoD("10/06/2026"), 5600.00, 448.00, "60 DDL", "0102", "BRL", 1.00, "TRP-01", "CANCELADO"})
    aAdd(aTeste, {"PC005", "EPSILON SERVICOS ME", "NF-7890", "001", CtoD("18/06/2026"), 1250.75, 100.06, "30 DDL", "0104", "EUR", 5.20, "TRP-04", "CONTRATO ANUAL"})

    DEFINE MSDIALOG oDlg TITLE "Consulta Pedidos - " + cValToChar(Len(aTeste)) + " registros" ;
        FROM 0,0 TO 650,1500 PIXEL

    @5,5 SAY "LISTBOX 818x360 | Colunas: 1420px (HSCROLL)" SIZE 350,10 OF oDlg PIXEL

    @20,5 BUTTON "Fechar" SIZE 50,12 OF oDlg PIXEL ACTION oDlg:End()

    @40,5 LISTBOX oL FIELDS HEADER ;
        "Pedido","Fornecedor","Num. NF","Serie","Data","Valor NF","Valor IPI","Cond. Pgto","Filial","Moeda","Tx. Moeda","Cod. Transp","Obs" ;
        SIZE 818,360 OF oDlg PIXEL HSCROLL

    oL:SetArray(aTeste)
    oL:aColSizes := aFinalCols

    oL:bLine := {|| {;
        aTeste[oL:nAt,1], ;
        aTeste[oL:nAt,2], ;
        aTeste[oL:nAt,3], ;
        aTeste[oL:nAt,4], ;
        DtoC(aTeste[oL:nAt,5]), ;
        Transform(aTeste[oL:nAt,6], "@E 99,999,999.99"), ;
        Transform(aTeste[oL:nAt,7], "@E 99,999,999.99"), ;
        aTeste[oL:nAt,8], ;
        aTeste[oL:nAt,9], ;
        aTeste[oL:nAt,10], ;
        Transform(aTeste[oL:nAt,11], "@E 999.9999"), ;
        aTeste[oL:nAt,12], ;
        aTeste[oL:nAt,13]}}

    @410,5 SAY "Larguras hardcoded: " + cValToChar(aFinalCols[1]) + "|" + cValToChar(aFinalCols[2]) + ;
        "|" + cValToChar(aFinalCols[3]) + "|" + cValToChar(aFinalCols[4]) + "|" + cValToChar(aFinalCols[5]) + ;
        "|" + cValToChar(aFinalCols[6]) + "|" + cValToChar(aFinalCols[7]) + "|" + cValToChar(aFinalCols[8]) + ;
        "|" + cValToChar(aFinalCols[9]) + "|" + cValToChar(aFinalCols[10]) + "|" + cValToChar(aFinalCols[11]) + ;
        "|" + cValToChar(aFinalCols[12]) + "|" + cValToChar(aFinalCols[13]) + ;
        " = 1420px (HSCROLL)" SIZE 700,10 OF oDlg PIXEL

    ACTIVATE MSDIALOG oDlg CENTERED

    RestArea(aArea)
Return
