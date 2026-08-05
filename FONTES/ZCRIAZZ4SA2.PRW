#Include "Protheus.ch"
#Include "TopConn.ch"

#Define CRLF Chr(13) + Chr(10)

//-------------------------------------------------------------------
/*/{Protheus.doc} ZCRIAZZ4SA2
Registra o campo customizado A2_ZZ4ID na tabela SA2 (SX3).

Deve ser executado UMA UNICA VEZ pelo administrador.
Apos executar, rodar o ALTER TABLE abaixo no banco de dados
e reiniciar o Protheus:

  ALTER TABLE SA2010 ADD A2_ZZ4ID VARCHAR(6) DEFAULT '      '

O campo A2_ZZ4ID armazena o codigo da Solicitacao Cadastral (ZZ4)
vinculada ao fornecedor. Ao sair do campo no MATA020, a funcao
U_FFZZ4A2() preenche automaticamente os campos do SA2 com os dados
informados na solicitacao ZZ4.

Apos o SA2 ser salvo, o PE MT020INC atualiza ZZ4_STATUS para '1'
(Cadastrado), exibindo a linha em VERMELHO no browse CADFORN.

@type User Function
@version 12.1.33
@author  Suprimentos
@since   2026
/*/
//-------------------------------------------------------------------
User Function ZCRIAZZ4SA2()

    Local aArea   := GetArea()
    Local lExiste := .F.

    DbSelectArea("SX3")
    SX3->(DbSetOrder(2))  // Ordem 2: por X3_CAMPO

    // Verifica se ja existe (campo A2_ZZ4ID em qualquer tabela — prefixo A2_ e unico da SA2)
    If SX3->(DbSeek("A2_ZZ4ID"))
        While !SX3->(Eof()) .And. AllTrim(SX3->X3_CAMPO) == "A2_ZZ4ID"
            If AllTrim(SX3->X3_ARQUIVO) == "SA2"
                lExiste := .T.
                Exit
            EndIf
            SX3->(DbSkip())
        EndDo
    EndIf

    If lExiste
        MsgInfo("Campo A2_ZZ4ID ja existe no dicionario (SX3) para SA2." + CRLF + CRLF + ;
                "Nenhuma alteracao foi feita.", "Campo Existente")
        RestArea(aArea)
        Return
    EndIf

    // Cria o campo no SX3
    RecLock("SX3", .T.)
        SX3->X3_ARQUIVO := "SA2"
        SX3->X3_CAMPO   := "A2_ZZ4ID"
        SX3->X3_TIPO    := "C"
        SX3->X3_TAMANHO := 6
        SX3->X3_DECIMAL := 0
        SX3->X3_ORDEM   := "90"    // Aba Dados Gerais, apos campos padrao
        If FieldPos("X3_TITULO")  > 0  ;  SX3->X3_TITULO  := "Cod ZZ4"               ;  EndIf
        If FieldPos("X3_DESCRIC") > 0  ;  SX3->X3_DESCRIC := "Solicitacao Cadastral"  ;  EndIf
        If FieldPos("X3_DESCSPA") > 0  ;  SX3->X3_DESCSPA := "Solicitacao Cadastral"  ;  EndIf
        If FieldPos("X3_DESCENG") > 0  ;  SX3->X3_DESCENG := "Registration Request"   ;  EndIf
        If FieldPos("X3_USADO")   > 0  ;  SX3->X3_USADO   := "1"                      ;  EndIf
        If FieldPos("X3_BROWSE")  > 0  ;  SX3->X3_BROWSE  := "N"                      ;  EndIf
        If FieldPos("X3_PICTURE") > 0  ;  SX3->X3_PICTURE := "@!"                     ;  EndIf
        If FieldPos("X3_CONTEXT") > 0  ;  SX3->X3_CONTEXT := "V"                      ;  EndIf
        If FieldPos("X3_VALID")   > 0  ;  SX3->X3_VALID   := "U_FFZZ4A2()"            ;  EndIf
        If FieldPos("X3_PASTA")   > 0  ;  SX3->X3_PASTA   := "01"                     ;  EndIf
        If FieldPos("X3_HELP")    > 0
            SX3->X3_HELP := "Informe o codigo da Solicitacao Cadastral (ZZ4). " + ;
                            "Ao confirmar, os campos serao preenchidos automaticamente."
        EndIf
    MsUnlock()

    MsgInfo("Campo A2_ZZ4ID criado no dicionario (SX3)!" + CRLF + CRLF + ;
            "PROXIMOS PASSOS:" + CRLF + ;
            "1. Execute o comando abaixo no banco de dados:" + CRLF + ;
            "   ALTER TABLE SA2010 ADD A2_ZZ4ID VARCHAR(6) DEFAULT '      '" + CRLF + CRLF + ;
            "2. Reinicie o Protheus." + CRLF + CRLF + ;
            "Obs: Compile e ative tambem os fontes:" + CRLF + ;
            "   FFZZ4A2.PRW  (preenchimento automatico)" + CRLF + ;
            "   MT020INC.PRW (atualizacao do status ZZ4)", "Sucesso")

    RestArea(aArea)

Return
