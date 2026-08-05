#Include "Protheus.ch"

User Function ZCRIASX3()

    Local aArea := GetArea()
    Local lExiste := .F.

    DbSelectArea("SX3")
    DbSetOrder(1) // Chave: X3_ARQUIVO + X3_CAMPO (na maioria dos ambientes)

    If DbSeek("ZZA013ZZA_AJUSTA")
        lExiste := .T.
    EndIf

    If !lExiste

        RecLock("SX3", .T.)

        SX3->X3_ARQUIVO  := "ZZA013"
        SX3->X3_CAMPO    := "ZZA_AJUSTA"
        SX3->X3_TIPO     := "C"
        SX3->X3_TAMANHO  := 1
        SX3->X3_DECIMAL  := 0

        // Descrições (usa o que existir)
        If FieldPos("X3_TITULO") > 0
            SX3->X3_TITULO := "AJUSTA ESTOQUE"
        EndIf
        If FieldPos("X3_DESCRIC") > 0
            SX3->X3_DESCRIC := "AJUSTA ESTOQUE"
        EndIf
        If FieldPos("X3_DESCSPA") > 0
            SX3->X3_DESCSPA := "AJUSTA ESTOQUE"
        EndIf

        // Default / obrigatório / usado (se existirem)
        If FieldPos("X3_PADRAO") > 0
            SX3->X3_PADRAO := "N"
        EndIf
        If FieldPos("X3_OBRIGAT") > 0
            SX3->X3_OBRIGAT := "1"
        EndIf
        If FieldPos("X3_USADO") > 0
            SX3->X3_USADO := "1"
        EndIf
        If FieldPos("X3_PICTURE") > 0
            SX3->X3_PICTURE := "@!"
        EndIf

        MsUnlock()

        MsgInfo("Registro criado na SX3. Agora falta aplicar no banco (ALTER TABLE).")

    Else
        MsgInfo("Campo ZZA_AJUSTA já existe na SX3.")
    EndIf

    RestArea(aArea)

Return
