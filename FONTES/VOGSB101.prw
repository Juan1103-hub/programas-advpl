#Include 'Protheus.ch'
#Include 'Topconn.ch'
#include "rwmake.ch"

#DEFINE CRLF   Chr(13)+Chr(10)
// Gatilho para validar a ZA3
// @type function
// @version P12.1.2310 
// @author Juveni
// @since 11/10/2024

User Function VOGSB101(pCampo)
	Local cRetorno
	Local cPrograma  := ProcName(22)

	If substr(cPrograma,1,7) = "MATA010"
		If pCampo == "B1_ZDTINC"
			If SB1->B1_ZDTINC == ctod("//")
				cRetorno := date()
			Else
				cRetorno := SB1->B1_ZDTINC
			Endif
		Endif

		If pCampo == "B1_ZDTALT"
			If SB1->B1_ZDTINC == ctod("//")
				cRetorno := ctod("//")
			Else
				cRetorno := date()
			Endif
		Endif

		If pCampo == "B1_ZUSINC"
			If ALLTRIM(M->B1_ZUSINC) == ""
				cRetorno  := UsrRetName(RetCodUsr())
			Else
				cRetorno  := M->B1_ZUSINC
			Endif
		Endif

		If pCampo == "B1_ZUSALT"
			If ALLTRIM(SB1->B1_ZUSINC) <> ""
				cRetorno  := UsrRetName(RetCodUsr())
			Else
				cRetorno  := ""
			Endif
		Endif
	Endif


Return cRetorno

