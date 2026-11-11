---
name: ma010but-botao-mata010
description: PE MA010BUT inclui botões na barra de ferramentas da view da MATA010 (cadastro de produtos)
---

# MA010BUT — botões na barra de ferramentas da MATA010

**PE:** `FONTES/MA010BUT.PRW` — `User Function MA010BUT()`

```advpl
User Function MA010BUT()
    Local aRet := {}
    AAdd(aRet, { "NOTE", {|| U_ZATUDESC()}, "Atualizar Descricoes" })
    AAdd(aRet, { "NOTE", {|| U_ZBLQMAS()}, "Bloqueio/Desbloqueio em Massa" })
Return aRet
```

## Formato do retorno (CRÍTICO)

Cada item da lista retornada é `{ icone (cPicture), bloco de acao (bAction), titulo (cTitle) }`.
O `ViewDef` da MATA010 repassa para `FWFORMVIEW:AddUserButton(cTitle, cPicture, bAction)`:

- **Título (texto) na 3ª posição** e **ação (codeblock) na 2ª**
- NÃO é formato `aRotina` `{Label, Chamada, 0, 2, 0, Nil}` — esse formato passa `0`
  (numérico) como `cTitle` e quebra a tela com
  `argumento #0, parametro cTitle erro, previsto C->N`
- Neste build o PE é chamado **sem PARAMIXB útil** (`PARAMIXB[1]` é `U` no Incluir)
  — construir a lista do zero, sem `PARAMIXB`

## Bug corrigido em 09/10/2026

1. Incluir → `variable is not array - Type [U] on U_MA010BUT` (leitura direta de `PARAMIXB[1]`)
2. Visualizar → `previsto C->N on FWFORMVIEW:ADDUSERBUTTON` (formato `aRotina` com título na posição errada)

Solução final: formato `{ "NOTE", {|| U_ZATUDESC()}, "Atualizar Descricoes" }`.
Registro completo: vault Obsidian `06 - Bugs Resolvidos.md` (entrada 2026-10-09).

**Referências:** post "MATA010-MA010BUT - Adicionar botão na tela" (udesenv, P12);
assinatura confirmada no repo em `FONTES/ZADTASK.prw:73`.

**Ver também:** `pes/mta010mnu-menu-browse-mata010.md` (menu do browse),
`padroes/pe-botao-codigo-mnu.md` (padrão dos dois PEs),
`padroes/zatudesc-atualizacao-descricoes-csv.md`
