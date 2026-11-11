// --- Ponto de Entrada: MTA010MNU - Adiciona opcao no menu do browse da MATA010 ---

#include "totvs.ch"

/*/{Protheus.doc} MTA010MNU
Ponto de Entrada que insere novas opcoes no array aRotina do browse do
Cadastro de Produtos (MATA010):
  - "Atualizar Descricoes"            -> rotina ZATUDESC
  - "Bloqueio/Desbloqueio em Massa"   -> rotina ZBLQMAS

Solucao oficial TOTVS (Central de Atendimento): "ADVPL - Novas opcoes no
menu de Cadastro de Produtos (MATA010)" - Protheus 12.1.17 ou superior.

@author  Vortice Consultoria Mineral
@since   2026/10/09
@version 1.0
@type    function
/*/
User Function MTA010MNU()

    // aRotina e fornecido pela rotina no momento da montagem do menu.
    // Guardar com Type() para nao quebrar caso o contexto de chamada mude.
    If Type("aRotina") == "A"
        AAdd(aRotina, { "Atualizar Descricoes", "U_ZATUDESC()", 0, 2, 0, Nil })
        AAdd(aRotina, { "Bloqueio/Desbloqueio em Massa", "U_ZBLQMAS()", 0, 2, 0, Nil })
    Else
        FWLogMsg("ERROR", , "SUPR", FunName(), , "01", ;
                 "[MTA010MNU] Variavel aRotina indisponivel - opcao nao incluida no menu")
    EndIf

Return Nil
