---
name: advpl-lista-itens-consulta
description: Monta listas de itens de consultas e relatorios analiticos em AdvPL/Protheus (LISTBOX na tela e TReport em PDF/planilha) com ordenacao por data de emissao, desempate pelo documento, contadores de itens e documentos distintos, rodape igual na tela e na impressao, linha de aviso para lista vazia, colunas sem barra horizontal, comparativo de periodos e ParamBox com datas em branco. Usar quando a tela detalhar materiais, servicos, pedidos ou requisitados ao armazem e precisar de totais coerentes com o que aparece na tela.
argument-hint: <arquivo .prw e funcao que monta a lista de itens>
user-invocable: true
---

# Lista de itens de consulta (AdvPL)

## Visao geral

Esta Skill cobre a **lista de detalhe** de uma consulta analitica: o array de
itens que alimenta um `LISTBOX` na tela e o mesmo conteudo impresso por
`TReport` em PDF ou planilha. O objetivo e a tela, o rodape e a impressao
contarem a mesma historia - sem item cortado, sem contador inventado e sem
diferenca entre o que o usuario ve e o que ele imprime.

Nao substitui:

- `advpl-tela-consulta` - tela inicial de filtros e consulta virtual (modelo ZLGCONS);
- `advpl-msdialog-dimensionamento` - moldura e escala da tela modal;
- `advpl-msdialog-ciclo-de-vida` - leitura de controles depois do `ACTIVATE`.

## Quando disparar

- A tela mostra itens de pedidos, notas, requisicoes ou movimentos e precisa de
  rodape com quantidade de itens, documentos e valor total.
- O PDF precisa sair com as mesmas colunas, a mesma ordem e o mesmo rodape da tela.
- A lista tem comparativo entre periodo atual e periodo anterior.
- Alguma lista pode vir vazia (classe que so existe em um dos periodos).
- A ultima coluna da grade esta cortada ou a soma das colunas empata com a largura.

## Etapa 1 - separe o array bruto do array de exibicao

Guarde o item **como veio da consulta** e monte um segundo array so com o texto
formatado. O array bruto e a fonte da verdade para ordenar, contar e somar; o
formatado e descartavel.

Modelo de item para compras (materiais e servicos):

```advpl
// {dEmissao, cPedido, cCodigo, cDescricao, nQtde, nValor, cClasse, cDescrClasse, cSC}
aAdd(aMat, {StoD((cAlias)->DT), cDoc, cCod, cDescr, nQtde, nValor, cClasse, cDesCls, cSC})
```

Modelo de item para requisitados ao armazem (a posicao 10 e a quantidade atendida):

```advpl
// posicao 9 = CP_NUM (solicitacao ao armazem), posicao 10 = quantidade atendida
aAdd(aReq, {StoD((cAlias)->DT), cDoc, cCod, cDescr, nQtde, nValor, cClasse, cDesCls, cSC, nQtat})
```

Regras:

- `aClone()` antes de ordenar ou filtrar, para nao reordenar o array original do grupo.
- O array formatado (`aItens`) recebe `DtoC()` e a funcao de formatacao numerica
  da rotina (`FmtNum()`) somente na hora de exibir.
- Contadores e somas sempre no array bruto, nunca no array formatado.
- Linha de aviso de lista vazia nao entra no array bruto.

## Etapa 2 - ordenacao: data mais antiga primeiro, empate pelo documento

Ordene **antes** de formatar, com a data em `DtoS()`:

```advpl
nPosDoc := 2                  // pedido de compra
If nGrupo == 3
    nPosDoc := 9              // solicitacao ao armazem (CP_NUM)
EndIf

aSort(aDados,,, {|x, y| DtoS(x[1]) + x[nPosDoc] < DtoS(y[1]) + y[nPosDoc]})
```

- Mais antiga primeiro; empate resolvido pelo documento que aparece na coluna.
- `DtoC()` gera texto e nao ordena cronologicamente - use `DtoS()`.
- Ordene a lista atual e a do periodo anterior com o mesmo criterio.
- Se a lista junta varios grupos (materiais + servicos + requisitados), ordene
  depois de montar o array unico e use a posicao do documento exibido.
- Nao confie so no `ORDER BY` do SQL quando o array final e montado no AdvPL.

## Etapa 3 - contadores do rodape

Conte **documentos distintos e nao vazios** no array bruto:

```advpl
Static Function ContaDoc(aDados, nPos)
    Local aVistos := {}
    Local nI      := 0
    Local cValor  := ""

    For nI := 1 To Len(aDados)
        cValor := AllTrim(cValToChar(aDados[nI][nPos]))
        If !Empty(cValor)
            If aScan(aVistos, {|x| x == cValor}) == 0
                aAdd(aVistos, cValor)
            EndIf
        EndIf
    Next nI
Return Len(aVistos)
```

Para o total geral, pedidos e SCs contam **apenas materiais e servicos**:

```advpl
nPed := ContaDocCompras(aMat, aSvc, 2)   // C7_NUM
nSc  := ContaDocCompras(aMat, aSvc, 9)   // C7_NUMSC
```

`ContaDocCompras` e a mesma contagem aplicada aos dois arrays, com um unico
conjunto de valores vistos (assim um documento que aparece em material e em
servico conta uma vez):

```advpl
Static Function ContaDocCompras(aMat, aSvc, nPos)
    Local aVistos := {}
    Local aFontes := {aMat, aSvc}
    Local nJ      := 0
    Local nI      := 0
    Local cValor  := ""

    For nJ := 1 To Len(aFontes)
        For nI := 1 To Len(aFontes[nJ])
            cValor := AllTrim(cValToChar(aFontes[nJ][nI][nPos]))
            If !Empty(cValor)
                If aScan(aVistos, {|x| x == cValor}) == 0
                    aAdd(aVistos, cValor)
                EndIf
            EndIf
        Next nI
    Next nJ
Return Len(aVistos)
```

Rotulos:

| Lista | Rodape |
| --- | --- |
| Materiais e servicos | `Itens`, `Pedidos`, `SCs`, `Valor total` |
| Requisitados ao armazem | `Itens`, `Solicitacoes`, `Valor total` |
| Total geral | `Itens`, `Pedidos`, `SCs`, `Valor total` |

Regras:

- `Itens` = `Len(aItens)` da lista exibida, sem a linha de aviso.
- `SCs` de compra = `C7_NUMSC`; nunca contar `C7_NUM` como SC.
- Solicitacao ao armazem = `CP_NUM`; nunca chamar de "SC".
- Some `nValor` do array bruto e formate com 2 decimais.
- Monte o texto do rodape **uma vez** e reutilize na tela e na impressao.
- Requisitados nao entram na contagem de pedidos nem de SCs de compra.

## Etapa 4 - lista vazia

Antes de abrir a tela, se todos os grupos estiverem vazios:

```advpl
If Len(aMat) + Len(aSvc) + Len(aReq) == 0
    MsgAlert("Nenhum item encontrado para o filtro informado.", "Atencao")
    Return
EndIf
```

No detalhamento comparativo, um dos periodos pode estar vazio. Nesse caso, a
grade recebe uma **linha de aviso apenas na tela**; a impressao usa so os itens
reais. O exemplo abaixo e de uma grade de 6 colunas - a linha de aviso precisa
ter o mesmo numero de colunas da grade:

```advpl
aVisAtu := aClone(aItAtu)
If Len(aVisAtu) == 0
    aAdd(aVisAtu, {"", "", "", "Nenhum item no periodo atual", "", ""})
EndIf

aVisAnt := aClone(aItAnt)
If Len(aVisAnt) == 0
    aAdd(aVisAnt, {"", "", "", "Nenhum item no periodo anterior", "", ""})
EndIf
```

Regras:

- Se **os dois** periodos estiverem vazios, avise e nao abra a grade.
- A linha de aviso nao entra em `Len(aItens)`, nos contadores nem no PDF.
- O array de impressao e o array real (`aItAtu`/`aItAnt`), nao o de exibicao.

## Etapa 5 - colunas que cabem sem barra horizontal

A soma de `aColSizes` precisa ser **menor** que a largura do `LISTBOX`, com folga
de 30 a 40 para a barra de rolagem vertical:

| Lista | Colunas | Soma | Largura da grade | Folga |
| --- | --- | --- | --- | --- |
| Materiais e servicos | `{55,60,60,110,45,35,85,75}` | 525 | 565 | 40 |
| Requisitados | `{65,75,60,165,90,90}` | 545 | 590 | 45 |
| Total geral | `{55,55,60,65,135,55,95,75}` | 595 | 640 | 45 |

- Nao declare `SIZE` igual a soma: a barra vertical come a ultima coluna.
- Audite com `advpl-msdialog-dimensionamento/scripts/calc_frame.py`; folga abaixo
  de 30 gera `AVISO` (nao falha).
- Grade sem barra vertical pode usar `--min-slack 0`.
- Mantenha a mesma ordem de colunas na tela e no PDF.

## Etapa 6 - impressao igual a tela

Padrao de impressao da lista (PDF ou planilha):

```advpl
oReport := TReport():New("MINHALISTA", cTit, "", ;
    {|oReport| DetRpt(oReport, aItens, cRodape)}, cSub)

oReport:SetLandscape(.T.)
oReport:SetTotalInLine(.F.)

oSection := TRSection():New(oReport, cTit, {})

For nI := 1 To Len(aCabec)
    TRCell():New(oSection, "C" + cValToChar(nI), "", aCabec[nI], "@!", aLarg[nI])
Next nI

oReport:PrintDialog()
```

No callback, imprima as linhas e escreva o rodape como texto corrido:

```advpl
For nI := 1 To Len(aItens)
    For nJ := 1 To Len(aItens[nI])
        oSection:Cell("C" + cValToChar(nJ)):SetValue(aItens[nI][nJ])
    Next nJ
    oSection:PrintLine()
Next nI

oReport:SkipLine()
oReport:PrintText(cRodape, 0)
```

Regras:

- Reutilize `aCabec`, `aLarg`, `aItens` e `cRodape` da tela.
- Imprima o rodape como texto, nao como coluna: total longo corta na largura.
- A linha de aviso de lista vazia nao vai para a impressao.
- Larguras do PDF sao em caracteres (`TRCell`), diferentes dos pixels do `LISTBOX`;
  ajuste as duas listas separadamente.

## Etapa 7 - comparativo de periodos

O resumo mostra a **uniao** das classes do periodo atual e do mesmo periodo do
ano anterior; o detalhe mostra somente a classe clicada, em cada periodo.

No trecho abaixo, `aRA[1]`/`aRB[1]` sao as listas `{classe, descricao, valor}` do
periodo atual e do anterior (o primeiro elemento do retorno da funcao de resumo),
e `aNomes[nG]` e o rotulo do grupo (materiais, servicos ou requisitados):

```advpl
// Classe que so existiu no periodo de comparacao entra com valor atual 0
For nI := 1 To Len(aRB[1])
    nPos := aScan(aRA[1], {|x| AllTrim(x[1]) == AllTrim(aRB[1][nI][1])})
    If nPos == 0
        aAdd(aCls, {aNomes[nG], aRB[1][nI][1], aRB[1][nI][2], 0, aRB[1][nI][3]})
    EndIf
Next nI
```

- Nao esconda a classe so porque o valor atual e zero: ela e a prova da queda.
- Variacao percentual sem divisao por zero:

```advpl
If nAnt == 0
    Return "sem base de comparacao"
EndIf
nPerc := ((nAtual - nAnt) / nAnt) * 100
```

- Periodo anterior = mesmas datas um ano antes; `29/02` vira `28/02`.
- O detalhe por classe filtra os dois arrays pelo codigo da classe **depois** de
  ordenar, para as duas listas sairem na mesma ordem.

## Etapa 8 - ParamBox com datas em branco

**Nao use data como tipo do campo do `ParamBox` para abrir em branco.**
Verificado em 13/11/2026 no `ZGASTOCC`: quando o campo e do tipo data e o valor
inicial e a data vazia (`CtoD("")`), o `ParamBox` **preenche o campo com a data
base do ambiente** (31/01/2026 no ambiente CINVJ6_DEV). O usuario ve a data
preenchida sem ter digitado nada.

Use **campo de texto com mascara de data** e converta depois do OK:

```advpl
Local cDtDe  := Space(10)
Local cDtAte := Space(10)

aAdd(aPar, {1, "Data De",  cDtDe,  "@R 99/99/9999", "", "", "", 60, .T.})
aAdd(aPar, {1, "Data Ate", cDtAte, "@R 99/99/9999", "", "", "", 60, .T.})
```

Depois do retorno, leia o texto e converta com uma funcao que aceite o texto
com ou sem barras (o campo pode vir sem mascara se o `ParamBox` ignorar a
mascara):

```advpl
cDtDe  := AllTrim(cValToChar(aRet[1]))
cDtAte := AllTrim(cValToChar(aRet[2]))

If Empty(cDtDe) .Or. Empty(cDtAte)
    MsgAlert("Informe a data inicial e a data final.", "Atencao")
    lNova := .T.
    Loop
EndIf

dDtDe  := ZCCData(cDtDe)
dDtAte := ZCCData(cDtAte)

If Empty(dDtDe) .Or. Empty(dDtAte)
    MsgAlert("Data invalida. Informe no formato dia/mes/ano.", "Atencao")
    lNova := .T.
    Loop
EndIf

If dDtAte < dDtDe
    MsgAlert("A data inicial nao pode ser maior que a data final.", "Atencao")
    lNova := .T.
    Loop
EndIf
```

Conversao com conferencia de data inexistente (31/02/2026):

```advpl
Static Function ZCCData(cData)
    Local cNum  := StrTran(StrTran(AllTrim(cValToChar(cData)), "/", ""), " ", "")
    Local dData := CtoD("")

    If Len(cNum) == 8
        dData := StoD(SubStr(cNum, 1, 2) + "/" + SubStr(cNum, 3, 2) + "/" + SubStr(cNum, 5, 4))
        If DtoS(dData) != SubStr(cNum, 5, 4) + SubStr(cNum, 3, 2) + SubStr(cNum, 1, 2)
            dData := CtoD("")
        EndIf
    EndIf

Return dData
```

- O `ParamBox` so grava e recupera as respostas quando recebe um **nome de
  gravacao** no 10o parametro (precedente: `VORATF01.prw:73`, `ZRPCPDF.PRW:45`);
  sem ele nao ha memoria de valores entre execucoes.
- "Nova consulta" deve voltar ao `ParamBox` **mantendo as datas digitadas**;
  limpe para branco somente na primeira entrada da rotina.
- O periodo de comparacao e derivado das datas informadas, nao de parametro fixo.
- `ParamBox` fica fora de transacao e fora de loop que percorre registros; o
  `Do While` que reabre a tela depois de "Nova consulta" e permitido.

## Checklist

- [ ] array bruto separado do array formatado
- [ ] ordenacao por `DtoS(data) + documento`, mais antiga primeiro
- [ ] lista atual e lista anterior ordenadas pelo mesmo criterio
- [ ] contadores distintos e nao vazios sobre o array bruto
- [ ] `SCs` de compra = `C7_NUMSC`; solicitacao ao armazem = `CP_NUM`
- [ ] rodape com `Itens`, `Pedidos`, `SCs`, `Solicitacoes` e `Valor total` conforme a lista
- [ ] total geral conta pedidos e SCs somente em materiais e servicos
- [ ] linha de aviso de lista vazia so na tela, fora de contadores e PDF
- [ ] soma das colunas + folga de 30 a 40 cabe na grade
- [ ] mesma ordem de colunas e mesmo rodape na tela e na impressao
- [ ] comparativo mostra classes que so existem no ano anterior
- [ ] variacao percentual sem divisao por zero
- [ ] `ParamBox` abre com as duas datas em branco
- [ ] "Nova consulta" preserva as datas digitadas

## Precedente verificado no repositorio

`FONTES/ZGASTOCC.PRW` (rotina de gastos por centro de custo):

| Assunto | Linhas |
| --- | --- |
| `ParamBox` com datas em branco (campo de texto com mascara) | `:93-94`, `:102-103` |
| Validacao de data vazia, invalida e periodo invertido | `:113-127` |
| Conversao do texto digitado em data (`ZCCData`) | `:180-198` |
| Ordenacao das listas de grupo | `:730`, `:886` |
| Ordenacao das listas por classe | `:1102-1103` |
| Contagem de documentos distintos | `:518`, `:544` |
| Rodape dos grupos | `:766-773` |
| Rodape do total geral | `:897-902` |
| Linha de aviso so na tela | `:1135-1145` |
| Larguras das colunas | `:781`, `:794`, `:913` |
| Impressao da lista | `:935-983` |
| Uniao de classes no comparativo | `:1527-1533` |
| Variacao sem divisao por zero | `:1440-1452` |
