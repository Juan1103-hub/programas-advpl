---
name: pe-botao-codigo-mnu
description: Padrão para incluir botões/opções em telas Protheus via PE (toolbar da view x menu do browse)
type: reference
metadata:
  type: reference
---

# Padrão — botões via Ponto de Entrada (MATA010 como referência)

Existem **dois PEs diferentes** com funções parecidas. Não trocar os formatos!

## 1) Toolbar da VIEW (formulário Incluir/Alterar/Excluir/Visualizar) — `MA010BUT`

**Quando usar:** botão na barra de ferramentas do formulário MVC.

```
#include "totvs.ch"

/*/{Protheus.doc} MA010BUT
    Inclui botao na barra de ferramentas da view da MATA010.
    @type function
/*/
User Function MA010BUT()
    Local aRet := {}
    AAdd(aRet, { "NOTE", {|| U_ZMINHAROTINA()}, "Titulo do Botao" })
Return aRet
```

**Regras:**
- Formato do item: `{ icone (cPicture), bloco de acao (bAction), titulo (cTitle) }`
  — **título (texto) na 3ª posição, codeblock na 2ª**
- O `ViewDef` chama `FWFORMVIEW:AddUserButton(cTitle, cPicture, bAction)`
  (assinatura confirmada em `FONTES/ZADTASK.prw:73`)
- **NUNCA** usar formato `aRotina` `{Label, Chamada, 0, 2, 0, Nil}` aqui — passa `0`
  como `cTitle` e quebra a tela com `previsto C->N`
- Neste build o PE é chamado **sem PARAMIXB** — construir a lista do zero

## 2) Menu do BROWSE (tela de lista) — `MTA010MNU` (e congêneres `*MNU`)

**Quando usar:** opção no menu/aRotina do browse da rotina.

```
#include "totvs.ch"

User Function MTA010MNU()
    If Type("aRotina") == "A"
        AAdd(aRotina, { "Titulo da Opcao", "U_ZMINHAROTINA()", 0, 2, 0, Nil })
    EndIf
Return Nil
```

**Regras:**
- Formato **aRotina** `{Label, Chamada, BitmapIndex, Shortcut, ...}` — chamada em
  string com `U_` e `()`
- `aRotina` vem **no escopo** da rotina (sem `PARAMIXB`) — solução oficial TOTVS;
  guardar com `Type("aRotina") == "A"` antes do `AAdd`
- Outros PEs de menu: `MTA094RO` (liberação docs), `MTA185MNU` (SA),
  `MTA020` (fornecedores), `OM010MNU` (SIGAFAT)

## Regras gerais
- Nome do arquivo fonte = nome do PE, maiúsculo (ex.: `MA010BUT.PRW`)
- Encoding CP-1252 (ASCII puro evita conversão)

**SonarQube:** nenhuma regra específica — respeitar `Function` proibido (use `User Function`), entry-point naming

**Referências:** vault `06 - Bugs Resolvidos.md` (entrada 2026-10-09 — troca de formatos);
post "MATA010-MA010BUT - Adicionar botão na tela" (udesenv); TOTVS Central "Novas
opções no menu de Cadastro de Produtos (MATA010)"
[[entry-point-naming]] [[encoding-cp1252]]
