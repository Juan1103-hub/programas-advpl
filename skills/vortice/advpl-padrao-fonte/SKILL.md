---
name: advpl-padrao-fonte
description: Molde do fonte AdvPL/TLPP deste repositorio (header Protheus.doc, layout, GetArea/RestArea, SQL TopConnect, PE, tela mBrowse, classe TLPP) extraido dos 79 fontes de FONTES/, com script de auditoria. Use ao criar, editar ou revisar qualquer .prw/.tlpp/.prg, ao responder "segue o padrao do repositorio", ou antes de entregar fonte para compilacao. Nao use para regra de negocio (protheus-business) nem para dicionario SX (sx-configuration).
---

# Padrao de fonte AdvPL/TLPP — Vortice

> **Fonte de verdade: `FONTES/`.** Este documento e o molde tirado do codigo real
> (79 arquivos, 57.021 linhas). Se este arquivo divergir do codigo, o codigo vence —
> e a divergencia deve virar uma linha em `references/evidencias.md`.

## Quando usar

- Criar fonte novo em `FONTES/` (PE, rotina, relatorio, tela, classe TLPP).
- Editar fonte existente e precisar saber o que e estilo do repo e o que e acidente.
- Revisar entrega antes da compilacao manual do usuario.
- Auditar divida: `python skills/vortice/advpl-padrao-fonte/scripts/auditar_padrao.py FONTES`.

**Nao** substitui: `protheus-business` (regra de negocio), `sx-configuration`
(dicionario), `advpl-code-review` (achados de seguranca/performance por regra
SonarQube). Rode este skill **antes** do review: aqui e forma, la e conteudo.

## Regra de ouro

1. **Codigo existente manda.** Antes de escrever, abra o fonte mais parecido em
   `FONTES/` e copie a forma dele.
2. **Legado nao se replica.** O repo tem divida medida (789 `IIF`, 56 `ConOut`,
   60 arquivos em `Protheus.ch`). Fonte novo nasce no padrao-alvo, nao no padrao medio.
3. **Mudanca minima.** Nao reformatar, nao renomear e nao "limpar" o que o pedido
   nao pediu — inclusive comentario e alinhamento.
4. **Sem `U_` no nome da funcao.** `U_` e forma de *chamada* (`"U_CSOLINC()"` no
   menu), nunca de declaracao (`User Function CSOLINC()`).

## Anatomia do fonte (7 blocos, nesta ordem)

```advpl
#Include "Protheus.ch"              // 1. includes
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} NOME             // 2. bloco Protheus.doc (obrigatorio)
Resumo em uma linha.
                                       // 3. corpo: o que faz, premissas, tabelas
@type    User Function
@author  Suprimentos
@since   20/04/2026
@version 12.1.33
@return  logical, .T. = permite | .F. = bloqueia
/*/
//-------------------------------------------------------------------
User Function NOME()                  // 4. assinatura (nome = nome do arquivo)

    Local aArea := GetArea()          // 5. declaracoes alinhadas, todas no topo
    Local lRet  := .T.
    Local nX    := 0

    // --- 1) Guarda de entrada -------------------------------------
    If Empty(cParam)                  // 6. logica: guarda -> processo -> saida
        RestArea(aArea)
        Return .F.
    EndIf

    // --- 2) Processo ----------------------------------------------
    ...

    RestArea(aArea)                   // 7. saida: RestArea nos dois caminhos
Return lRet
```

### Bloco 2 — Protheus.doc (o que o repo realmente escreve)

O cabecalho deste repo e **documentacao funcional**, nao burocracia de tag:
titulo, descricao do problema, premissas, "responsabilidade unica", tabelas
tocadas e observacao de versao. Ordem de tags:

`@type` → `@author` → `@since` → `@version` → `@param` → `@return` → `@see`/`@obs`

- `@type` aceita `User Function`, `Static Function`, `class`, `Method` (o repo usa
  capitalizacao variada — siga a do arquivo que esta editando).
- `@author` neste repo e `Suprimentos` (ou `Eurai Rapelli / Suprimentos`).
- `@since`/`@version`: `dd/mm/aaaa` e `12.1.33` (ou `@version 4.2 - 07/06/2026 - o
  que mudou`, quando o arquivo versiona no proprio header).
- `@return logical, .T. = permite gravar | .F. = bloqueia` — diga o **significado**,
  nao so o tipo.

Referencias: `FONTES/MT110TOK.PRW:3-21`, `FONTES/CADSOLIC.PRW:5-28`,
`FONTES/ZDIAG110.tlpp:8-25`.

### Bloco 5 — Declaracoes

- 4 espacos, nunca TAB (9 dos 79 arquivos usam TAB: e divida, nao padrao).
- `Local` **todos no topo**, antes de qualquer comando. `Local` no meio do fluxo so
  existe em legado (`nfesefaz.prw`: 128 ocorrencias) — nao copie.
- `Private` tambem vai no topo, exceto os de tela (`cCadastro`, `cString`, `aRotina`,
  `aCores`) e os de `MSExecAuto` (`lMsErroAuto`, `lMsHelpAuto`, `lAutoErrNoFile`), que
  precisam existir no momento da chamada — ver `CADSOLIC.PRW:45-63`.
- `:=` alinhado em coluna por bloco de declaracao.
- Primeira declaracao de funcao que toca alias: `Local aArea := GetArea()`;
  por alias: `Local aAreaSC1 := SC1->(GetArea())`.
- Ordem no bloco: areas, retorno, contadores, textos, datas, flags.

### Bloco 6 — Logica

- Guarda de entrada primeiro (usuario liberado, parametro vazio, permissao) → `Return`.
- Separadores de secao: `// --- 1) Descricao -----------------------------` (usado em
  `ZDIAG110.tlpp`, `ZPOSITEM.PRW`, `MT110TOK.PRW`).
- `If`/`ElseIf`/`EndIf` **sempre**; `IIF()` nao entra em codigo novo (CA4000).
- `Do Case` para leque de opcoes (ver `ZANALBX.PRW`, selecao de almoxarife).
- Comentario explica **por que** e qual e a regra de negocio, em portugues; nao
  repete a linha de codigo.

### Bloco 7 — Saida

- `RestArea()` nos dois caminhos (inclusive nos `Return` antecipados). O padrao-alvo
  e ordem inversa da aquisicao (LIFO), como em `MT110TOK.PRW:50-51`; o exit final do
  mesmo arquivo (`:138-139`) nao segue essa ordem — e divida, nao molde.
- Retorno com significado: `.T./.F.` documentado no `@return`; `Return Nil`/`Return`
  seco quando a funcao e procedimento.
- Fechar alias temporario: `If Select(cAlias) > 0` → `(cAlias)->(DbCloseArea())`.

## Acesso a dados — a receita do repo

O idioma dominante e **TopConnect montado em string** (29 dos 79 arquivos), nao
`FWExecStatement` (1 arquivo) nem `BeginSQL` (7):

```advpl
Local cAlias := GetNextAlias()
Local cQuery := ""

cQuery := "SELECT Z3_ID, Z3_DESC FROM " + RetSqlName("SZ3") + " "
cQuery += "WHERE D_E_L_E_T_ = ' ' AND Z3_FILIAL = '" + xFilial("SZ3") + "' "
cQuery := ChangeQuery(cQuery)

If Select(cAlias) > 0
    (cAlias)->(DbCloseArea())
EndIf
DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)

If (cAlias)->(Eof())
    (cAlias)->(DbCloseArea())
    RestArea(aArea)
    Return
EndIf
```

Regras que nao mudam:

| Regra | Certo | Errado |
| --- | --- | --- |
| Soft-delete | `D_E_L_E_T_ = ' '` (ou `<> '*'` no legado) | esquecer o filtro |
| Filial | `xFilial("SZ3")` | `'01'`, `cFilial` |
| Nome fisico | `RetSqlName("SZ3")` | `SZ3` cru |
| Hint de leitura | `WITH (NOLOCK)` literal + `StrTran` normalizando/reinjetando apos `ChangeQuery()` | `%nolock%` (vira `WITH (%%)`) |
| Alias temporario | `GetNextAlias()` + fechar | reutilizar alias fixo |
| Campo | listar campos | `SELECT *` |
| Gravacao core | `MSExecAuto` | `RecLock` em SC5/SC6/SC7/SD1... |
| Gravacao Z* | `RecLock` | `MSExecAuto` em tabela Z |

Excecao legitima: leitura que alimenta gravacao ou calculo financeiro **nao** leva
`NOLOCK`. Ver `FONTES/CADSZ3.PRW:586-600` (padrao de query), `:3948-3950` (receita
do hint literal) e `:911-920` (relatorio).

## Nomenclatura

| Elemento | Padrao | Exemplo |
| --- | --- | --- |
| Arquivo | igual a funcao principal (72/79) | `MT110TOK.PRW`, `CADSOLIC.PRW` |
| PE de rotina MATA* | `MT`/`MTA` + numero + mnemonico | `MT110TOK`, `MTA110OK` |
| Customizacao | `Z` + mnemonico | `ZANALBX`, `ZLEADTIME` |
| Tela de cadastro | `CAD*` | `CADSZ3`, `CADSOLIC` |
| Rotina Vortice | `VO*`/`V*` | `VOREST02`, `VCTBL002` |
| Variavel | húngara `c n d l a o b x j` | `cProduto`, `nSaldo`, `aCols` |
| Tabela/campo | prefixo + `_` | `SZ3`, `C7_QUANT` |
| Titulo de menu | `U_FUNCAO()` | `"U_NFEPREVTS()"` |

Arquivo em MAIUSCULO, `.prw` para AdvPL, `.tlpp` para TLPP. Legado em minusculo
(`nfesefaz.prw`) **nao renomeia** por causa do RPO.

## Interface

- Tela de consulta/browse: `mBrowse(...)` com `Private aRotina` logo antes
  (`CADSOLIC.PRW:45-72`). Os 3 primeiros itens de `aRotina` ficam na barra; o resto
  vai para "Outras Acoes".
- Parametros de relatorio: `ParamBox(aPar, "Titulo", @aRet)` + `RestArea` no
  cancelamento (`ZANALBX.PRW:58-66`).
- Mensagem: `MsgStop`/`MsgAlert`/`MsgInfo` com **titulo curto** e texto em portugues
  claro, sem abreviacao e sem ingles (`"ITEM CONTROLADO POR MINIMO/MAXIMO."`).
  Dentro de transacao, nenhuma mensagem — devolva erro e mostre fora.
- Tela modal MSDIALOG: carregue tambem `advpl-msdialog-dimensionamento` e
  `advpl-msdialog-ciclo-de-vida`, exigidas pelo `AGENTS.md`.

## Templates prontos

`references/templates.md` traz 6 moldes completos, tirados dos fontes de referencia
deste repo (a forma foi normalizada onde o original tinha divida):

| Molde | Base no repo | Use para |
| --- | --- | --- |
| A. PE de validacao | `MT110TOK.PRW` | validar `aCols`/`aHeader` antes de gravar |
| B. PE de menu | `MA410MNU.PRW` | adicionar opcao em `aRotina` de rotina padrao |
| C. PE de gatilho SX7 | `ZPOSITEM.PRW` | preencher `M->` em AxCadastro |
| D. Rotina/relatorio | `ZANALBX.PRW` + `CADSZ3.PRW` | ParamBox + query + TReport |
| E. Tela mBrowse | `CADSOLIC.PRW` | browse sobre query UNION/alias |
| F. Classe TLPP | `SC7TREP.tlpp` | SmartView/ON, REST, servico |

## Divida conhecida — nao replicar

Medido em `references/evidencias.md`. Resumo: `IIF` em 22 arquivos (789 usos),
`ConOut` em 10 (56 usos), `Protheus.ch` em 60 (contra 22 em `totvs.ch`),
`Function` puro: 0 (regra ja consolidada), `RecLock`: 56 usos, `MSExecAuto`: apenas 5,
`FWLogMsg`: 4. Cobertura de Protheus.doc: 48% das declaracoes.
**4 fontes estao em UTF-8 hoje** (`FFZZ4A2.PRW`, `M020EXC.PRW`, `VLDNOMEFORN.prw`,
`ZANALPRC.PRW`) — precisam de conversao antes da proxima compilacao.

## Auditoria (gate antes de entregar)

```powershell
# fonte novo ou alterado: perfil estrito (DOC/TYPE/DECL tambem sao ERRO)
python skills\vortice\advpl-padrao-fonte\scripts\auditar_padrao.py FONTES\MEU_FONTE.PRW --estrito

# pastas: perfil padrao, so o que quebra compilacao/dado e ERRO
python skills\vortice\advpl-padrao-fonte\scripts\auditar_padrao.py FONTES
```

- `ENC`: arquivo nao e CP-1252 → converter com `utf8-to-cp1252-conversion`.
- `AREA`: `GetArea()` sem `RestArea()` → aponta a funcao.
- `TXUI`: `Msg*` dentro de `Begin Transaction` → mover para fora.
- `INC`: sem include de Protheus (ou so `rwmake.ch`).
- `NOLK`, `FUNC`, `FILI`: proibicoes absolutas.

## Definicao de pronto

- [ ] Arquivo novo: nome = funcao principal, extensao e caixa corretas.
- [ ] Cabecalho Protheus.doc com `@type`, `@author Suprimentos`, `@since`, `@return` significativo.
- [ ] Includes corretos; `tlpp-core.th` primeiro em `.tlpp`.
- [ ] Bloco de declaracao no topo, alinhado, 4 espacos, sem TAB.
- [ ] `GetArea()`/`RestArea()` balanceados nos dois caminhos.
- [ ] SQL com `RetSqlName` + `xFilial` + `D_E_L_E_T_`; alias fechado.
- [ ] Sem `IIF`, sem `ConOut`, sem `%nolock%`, sem UI em transacao.
- [ ] Textos de tela em portugues claro, sem abreviacao.
- [ ] `auditar_padrao.py <arquivo> --estrito` com 0 ERRO.
- [ ] Fonte convertido para CP-1252 **depois** da ultima edicao.
- [ ] Compilacao: manual, pelo usuario (o agente nao compila). Ate o retorno, status
      e "aguardando compilacao do usuario".
