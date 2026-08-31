#Include "Protheus.ch"

#Define CRLF Chr(13) + Chr(10)

//-------------------------------------------------------------------
/*/{Protheus.doc} ZCONSZZ4
Registra a consulta ZZ4 no SXB seguindo o padrao SA1 (funcionando).

Estrutura correta baseada na analise do SXB do SA1:
  Tipo 1: XB_DESCRI="DB" (instrui FWLookup a abrir a tabela via
          DbUseArea - SEM isso da "Alias does not exist")
          XB_CONTEM="ZZ4" (alias da tabela)
  Tipo 2: XB_CONTEM="" (vazio! campos ficam no Tipo 4)
          XB_DESCRI = titulo da coluna
  Tipo 4: XB_CONTEM = campo (mapeamento real campo-coluna por ordem)
  Tipo 5: XB_CONTEM = "ZZ4->ZZ4_ID" (campo de RETORNO)
  Tipo 6: XB_CONTEM = "@ZZ4_STATUS = '0'" (filtro SQL - TDN Protheus 12+)
          Fornecedores ja cadastrados (STATUS='1') nao aparecem na
          Consulta Padrao.

Executar UMA VEZ como admin. Reiniciar o Protheus depois.

NOTA: Este programa acessa diretamente SXB e SX3 (CA2008/CA2004) pois
e uma ferramenta de SETUP que modifica o dicionario de dados. Isso e
intencional e nao viola as regras de acesso a metadados.

@type User Function
@version 12.1.33
@author  Suprimentos
@since   2026
/*/
//-------------------------------------------------------------------
User Function ZCONSZZ4()

    Local aArea  := GetArea()
    Local lSX3OK := .F.
    Local nDel   := 0
    Local nIns   := 0
    Local nVer   := 0
    Local cMsg   := ""
    Local cCRLF  := Chr(13)+Chr(10)

    // === 1. APAGA TODOS OS REGISTROS ZZ4 NO SXB ===
    DbSelectArea("SXB")
    SXB->(DbGoTop())
    While !SXB->(Eof())
        If AllTrim(Upper(SXB->XB_ALIAS)) == "ZZ4"   .Or. ;
           AllTrim(Upper(SXB->XB_ALIAS)) == "FAMAFO" .Or. ;
           AllTrim(Upper(SXB->XB_ALIAS)) == "FAMFOR"
            RecLock("SXB", .F.)
            DbDelete()
            MsUnlock()
            nDel++
        EndIf
        SXB->(DbSkip())
    End
    SXB->(DbCommit())

    // === 2. INSERE ESTRUTURA BASEADA NO PADRAO SA1 ===

    // Tipo 1 - CABECALHO
    // XB_COLUNA = "DB" instrui FWLookup a abrir a tabela via DbUseArea (igual SA2).
    // O filtro por pendentes e feito pelo Tipo 6 (filtro SQL) abaixo.
    ZSXBAdd("ZZ4", "1", "01", "DB", "Solicitac ZZ4", "ZZ4")             ; nIns++

    // Tipo 2 - CABECALHOS DAS COLUNAS (XB_CONTEM vazio - igual SA1!)
    ZSXBAdd("ZZ4", "2", "01", "01", "ID"          , "")            ; nIns++
    ZSXBAdd("ZZ4", "2", "02", "02", "Razao Social", "")            ; nIns++
    ZSXBAdd("ZZ4", "2", "03", "03", "CNPJ"        , "")            ; nIns++
    ZSXBAdd("ZZ4", "2", "04", "04", "Status"      , "")            ; nIns++

    // Tipo 4 - ORDEM 1: mapeamento campo -> coluna (igual SA1)
    ZSXBAdd("ZZ4", "4", "01", "01", "ID"          , "ZZ4_ID")      ; nIns++
    ZSXBAdd("ZZ4", "4", "01", "02", "Razao Social", "ZZ4_RAZAO")   ; nIns++
    ZSXBAdd("ZZ4", "4", "01", "03", "CNPJ"        , "ZZ4_CNPJ")    ; nIns++
    ZSXBAdd("ZZ4", "4", "01", "04", "Status"      , "ZZ4_STATUS")  ; nIns++

    // Tipo 5 - RETORNO: campo que volta para o A2_ZSOLID (igual SA1->A1_COD)
    ZSXBAdd("ZZ4", "5", "01", "01", ""            , "ZZ4->ZZ4_ID") ; nIns++

    // Tipo 6 - FILTRO SQL (apenas pendentes, STATUS='0')
    // Conforme TDN: prefixo @ ativa filtro SQL ANSI (Protheus 12+).
    // Fornecedores ja cadastrados (STATUS='1') nao aparecem na Consulta.
    ZSXBAdd("ZZ4", "6", "01", "01", ""            , "@ZZ4_STATUS = '0'") ; nIns++

    SXB->(DbCommit())

    // === 3. VERIFICA (varredura) ===
    SXB->(DbGoTop())
    cMsg := "=== REGISTROS ZZ4 NO SXB ===" + cCRLF
    While !SXB->(Eof())
        If AllTrim(Upper(SXB->XB_ALIAS)) == "ZZ4"
            nVer++
            cMsg += "[" + AllTrim(SXB->XB_TIPO) + "/" + AllTrim(SXB->XB_SEQ) + ;
                    "/" + AllTrim(SXB->XB_COLUNA) + "] " + ;
                    AllTrim(SXB->XB_DESCRI) + " -> " + ;
                    AllTrim(SXB->XB_CONTEM) + cCRLF
        EndIf
        SXB->(DbSkip())
    End

    // === 4. ATUALIZA SX3 A2_ZSOLID ===
    DbSelectArea("SX3")
    SX3->(DbSetOrder(2))
    If SX3->(DbSeek("A2_ZSOLID"))
        While !SX3->(Eof()) .And. AllTrim(SX3->X3_CAMPO) == "A2_ZSOLID"
            RecLock("SX3", .F.)
                SX3->X3_F3      := "ZZ4"
                SX3->X3_VALID   := "U_FFZZ4A2()"
                SX3->X3_INIBRW  := "U_OPENZZ4()"
                SX3->X3_TAMANHO := 6
                SX3->X3_TITULO  := "Cod Sol."
                SX3->X3_DESCRIC := "Cod Sol.Cad"
            MsUnlock()
            lSX3OK := .T.
            SX3->(DbSkip())
        End
        SX3->(DbCommit())
    EndIf

    MsgInfo("SXB: " + cValToChar(nDel) + " apagados | " + ;
            cValToChar(nIns) + " inseridos | " + ;
            cValToChar(nVer) + " verificados" + cCRLF + ;
            "SX3 A2_ZSOLID: " + IIf(lSX3OK, "Atualizado", "NAO encontrado") + cCRLF + cCRLF + ;
            cMsg + cCRLF + ;
            "REINICIE o Protheus para ativar.", "ZCONSZZ4 - Resultado")

    ConOut(cMsg)
    RestArea(aArea)
Return


//-------------------------------------------------------------------
Static Function ZSXBAdd(cAlias, cTipo, cSeq, cColuna, cDescri, cContem)
    DbSelectArea("SXB")
    RecLock("SXB", .T.)
        SXB->XB_ALIAS  := cAlias
        SXB->XB_TIPO   := cTipo
        SXB->XB_SEQ    := cSeq
        SXB->XB_COLUNA := cColuna
        SXB->XB_DESCRI := cDescri
        SXB->XB_CONTEM := cContem
    MsUnlock()
Return
