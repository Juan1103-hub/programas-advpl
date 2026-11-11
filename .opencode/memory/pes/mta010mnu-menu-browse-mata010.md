---
name: mta010mnu-menu-browse-mata010
description: PE MTA010MNU insere opção no menu do browse da MATA010 (cadastro de produtos)
---

# MTA010MNU — opção no menu do browse da MATA010

**PE:** `FONTES/MTA010MNU.PRW` — `User Function MTA010MNU()`

```advpl
User Function MTA010MNU()
    If Type("aRotina") == "A"
        AAdd(aRotina, { "Atualizar Descricoes", "U_ZATUDESC()", 0, 2, 0, Nil })
    EndIf
Return Nil
```

- **Diferença do MA010BUT:** `MTA010MNU` age no **browse** (tela de lista de
  produtos); `MA010BUT` age na **barra do formulário** (Incluir/Alterar/Excluir).
  Para o botão aparecer nos dois lugares, os dois PEs são necessários.
- **Chamada:** a rotina fornece `aRotina` no escopo (sem `PARAMIXB`) — ao
  contrário de `MA010BUT`/`MTA094RO`, que recebem `PARAMIXB[1] = aRotina`.
- **Guarda defensiva:** `Type("aRotina") == "A"` antes do `AAdd` (mesma aula do
  erro `variable is not array` do MA010BUT em contexto de carga de view).
- **Alvo:** Protheus 12.1.17+ (build do cliente: 7.00.240223P — compatível).
- **Fonte:** TOTVS Central — "ADVPL - Novas opções no menu de Cadastro de
  Produtos (MATA010)".

**Ver também:** `pes/ma010but-botao-mata010.md`,
`padroes/zatudesc-atualizacao-descricoes-csv.md`
