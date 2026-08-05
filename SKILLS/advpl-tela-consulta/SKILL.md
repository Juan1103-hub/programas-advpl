---
name: advpl-tela-consulta
description: >
  Use quando criar telas virtuais de consulta (browse/listagem) em ADVPL/Protheus.
  Aplica o modelo padrão da tela ZLGCONS: MSDIALOG 650x1300 PIXEL, linha de filtros
  (datas, campo texto, MSCOMBOBOX), botões Filtrar/Limpar/Atualizar, LISTBOX com
  largura 640x260 posicionado em @40,5, bLine dinâmico via array. SEM botões de ação
  (Editar, Excluir, Excel, Visualizar, Fechar). Palavras-chave: tela virtual, consulta,
  listagem, browse ADVPL, LISTBOX Protheus.
---

# Skill: Tela Virtual de Consulta ADVPL (Modelo ZLGCONS)

Toda tela virtual de consulta gerada em ADVPL/Protheus **deve seguir exatamente esta estrutura**.

---

## 1. Dimensões obrigatórias do diálogo

```advpl
DEFINE MSDIALOG oDlg TITLE "<Título> - " + cValToChar(Len(aArray)) ;
    FROM 0,0 TO 650,1300 PIXEL
```

- **Altura:** 650 px
- **Largura:** 1300 px
- O título deve conter a contagem de registros: `cValToChar(Len(aArray))`
- Sempre `ACTIVATE MSDIALOG oDlg CENTERED` no final

---

## 2. Linha de filtros — posição @5

| Elemento                         | Posição | SIZE  |
|----------------------------------|---------|-------|
| SAY "Data Coleta DE:"            | @5,5    | 50,10 |
| MSGET dDtDe                      | @5,60   | 50,10 |
| SAY "ATE:"                       | @5,115  | 20,10 |
| MSGET dDtAte                     | @5,140  | 50,10 |
| SAY campo-texto (ex.: "Pedido:") | @5,200  | 30,10 |
| MSGET campo-texto                | @5,225  | 40,10 |
| SAY "Status:"                    | @5,285  | 30,10 |
| MSCOMBOBOX oStatus               | @5,310  | 80,10 |

Adapte os rótulos dos campos de acordo com o contexto da tela, mantendo as posições.

---

## 3. Botões de navegação — posição @20

```advpl
@20,5  BUTTON "Filtrar"   SIZE 40,12 OF oDlg PIXEL ACTION (/* aplicar filtro */)
@20,50 BUTTON "Limpar"    SIZE 40,12 OF oDlg PIXEL ACTION (/* limpar filtros */)
@20,95 BUTTON "Atualizar" SIZE 40,12 OF oDlg PIXEL ACTION (/* recarregar array */)
```

- **Nenhum outro botão de ação** deve aparecer na tela (sem Editar, Excluir, Excel, Visualizar, Fechar).
- A tela fecha somente via o X da janela.

---

## 4. LISTBOX principal — posição @40,5

```advpl
@40,5 LISTBOX oL FIELDS HEADER <cabecalhos> SIZE 640,260 OF oDlg PIXEL
oL:SetArray(aArray)
oL:bLine := {|| { /* colunas derivadas de aArray[oL:nAt, N] */ }}
```

- **Posição:** @40,5 — imutável
- **SIZE:** 640,260 — imutável
- Colunas via `HEADER` separadas por vírgula
- `oL:bLine` deve ser bloco de código que deriva os valores do array `aArray`
- Usar `SubStr(campo, 1, N)` para limitar colunas de texto longo
- Usar `Transform(campo,"@E 999,999.99")` para colunas numéricas/moeda
- Usar `DtoC(campo)` para colunas de data

---

## 5. Carregamento de dados — padrão obrigatório

```advpl
Local aArray := CarregaDados()  // BeginSql + loop para montar array

If Len(aArray) == 0
    MsgAlert("Nenhum registro encontrado!", "Atencao")
    Return
EndIf
```

- Sempre validar array vazio **antes** de abrir o diálogo.
- Usar `BeginSql Alias cAlias ... EndSql` para leitura (nunca loop direto em tabela).

---

## 6. Filtro dinâmico — padrão ACTION dos botões

O bloco `ACTION` dos botões Filtrar, Limpar e Atualizar deve:
1. Recalcular `aArray` chamando a função de filtro/carga
2. Resetar `oL:nAt := 1`
3. Chamar `oL:SetArray(aArray)`
4. Reatribuir `oL:bLine` (bloco idêntico ao original)
5. Chamar `oL:Refresh()` e `oDlg:Refresh()`

---

## 7. Larguras de colunas — referência da ZLGCONS

| Coluna             | Derivação                                     | Truncamento |
|--------------------|-----------------------------------------------|-------------|
| Status / Código    | campo direto ou função de status              | sem truncar |
| Número / Pedido    | campo direto                                  | sem truncar |
| Data               | `DtoC(campo)`                                 | sem truncar |
| Fornecedor / Nome  | `SubStr(campo,1,30)`                          | 30 chars    |
| Transportadora     | `SubStr(campo,1,25)`                          | 25 chars    |
| Valor Coleta       | `Transform(campo,"@E 999,999.99")`            | —           |
| Valor Pedido       | `Transform(campo,"@E 999,999.99")`            | —           |
| CTE / código curto | campo direto                                  | sem truncar |
| Tipo Frete         | campo direto                                  | sem truncar |
| Observação         | `SubStr(campo,1,30)`                          | 30 chars    |

---

## 8. Template mínimo completo

```advpl
User Function ZMINHACONS()
    Local oDlg, oL
    Local dDtDe         := CtoD("")
    Local dDtAte        := CtoD("")
    Local cCampoFiltro  := Space(6)
    Local cStatusFiltro := "TODOS"
    Local oDtDe, oDtAte, oFiltro, oStatus
    Local aArray        := {}

    aArray := CarregaMeusDados()

    If Len(aArray) == 0
        MsgAlert("Nenhum registro encontrado!","Atencao")
        Return
    EndIf

    DEFINE MSDIALOG oDlg TITLE "Minha Consulta - " + cValToChar(Len(aArray)) FROM 0,0 TO 650,1300 PIXEL

    // Filtros
    @5,5   SAY "Data DE:"   SIZE 50,10 OF oDlg PIXEL
    @5,60  MSGET oDtDe  VAR dDtDe  SIZE 50,10 OF oDlg PIXEL
    @5,115 SAY "ATE:"       SIZE 20,10 OF oDlg PIXEL
    @5,140 MSGET oDtAte VAR dDtAte SIZE 50,10 OF oDlg PIXEL
    @5,200 SAY "Código:"    SIZE 30,10 OF oDlg PIXEL
    @5,225 MSGET oFiltro VAR cCampoFiltro SIZE 40,10 OF oDlg PIXEL
    @5,285 SAY "Status:"    SIZE 30,10 OF oDlg PIXEL
    @5,310 MSCOMBOBOX oStatus VAR cStatusFiltro ITEMS {"TODOS","Pendente","Concluido"} SIZE 80,10 OF oDlg PIXEL

    // LISTBOX
    @40,5 LISTBOX oL FIELDS HEADER "Código","Data","Descrição","Valor","Observação" SIZE 640,260 OF oDlg PIXEL
    oL:SetArray(aArray)
    oL:bLine := {|| {;
        aArray[oL:nAt,1], ;
        DtoC(aArray[oL:nAt,2]), ;
        SubStr(aArray[oL:nAt,3],1,30), ;
        Transform(aArray[oL:nAt,4],"@E 999,999.99"), ;
        SubStr(aArray[oL:nAt,5],1,30)}}

    // Botões de navegação (únicos permitidos: Filtrar, Limpar, Atualizar)
    @20,5  BUTTON "Filtrar"   SIZE 40,12 OF oDlg PIXEL ACTION (;
        aArray := AplicaMeuFiltro(dDtDe, dDtAte, cCampoFiltro, cStatusFiltro), ;
        oL:nAt := 1, oL:SetArray(aArray), ;
        oL:bLine := {|| {;
            aArray[oL:nAt,1], DtoC(aArray[oL:nAt,2]), ;
            SubStr(aArray[oL:nAt,3],1,30), ;
            Transform(aArray[oL:nAt,4],"@E 999,999.99"), ;
            SubStr(aArray[oL:nAt,5],1,30)}}, ;
        oL:Refresh(), oDlg:Refresh())

    @20,50 BUTTON "Limpar"    SIZE 40,12 OF oDlg PIXEL ACTION (;
        dDtDe := CtoD(""), dDtAte := CtoD(""), ;
        cCampoFiltro := Space(6), cStatusFiltro := "TODOS", ;
        oDtDe:Refresh(), oDtAte:Refresh(), oFiltro:Refresh(), oStatus:Refresh(), ;
        aArray := CarregaMeusDados(), oL:nAt := 1, oL:SetArray(aArray), ;
        oL:bLine := {|| {;
            aArray[oL:nAt,1], DtoC(aArray[oL:nAt,2]), ;
            SubStr(aArray[oL:nAt,3],1,30), ;
            Transform(aArray[oL:nAt,4],"@E 999,999.99"), ;
            SubStr(aArray[oL:nAt,5],1,30)}}, ;
        oL:Refresh(), oDlg:Refresh())

    @20,95 BUTTON "Atualizar" SIZE 40,12 OF oDlg PIXEL ACTION (;
        aArray := CarregaMeusDados(), oL:nAt := 1, oL:SetArray(aArray), ;
        oL:bLine := {|| {;
            aArray[oL:nAt,1], DtoC(aArray[oL:nAt,2]), ;
            SubStr(aArray[oL:nAt,3],1,30), ;
            Transform(aArray[oL:nAt,4],"@E 999,999.99"), ;
            SubStr(aArray[oL:nAt,5],1,30)}}, ;
        oL:Refresh(.T.), oDlg:Refresh())

    ACTIVATE MSDIALOG oDlg CENTERED
Return

//=============================================================================
// Static Function CarregaMeusDados
// Retorna array com os registros para exibição
//=============================================================================
Static Function CarregaMeusDados()
    Local aRet   := {}
    Local cAlias := GetNextAlias()

    BeginSql Alias cAlias
        SELECT campo1, campo2, campo3, campo4, campo5
        FROM %Table:TABELA%
        WHERE %NotDel%
          AND FILIAL = %xFilial:TABELA%
        ORDER BY campo1
    EndSql

    While !(cAlias)->(Eof())
        aAdd(aRet, {;
            AllTrim((cAlias)->campo1), ;
            StoD((cAlias)->campo2), ;
            AllTrim((cAlias)->campo3), ;
            (cAlias)->campo4, ;
            AllTrim((cAlias)->campo5)})
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

Return aRet
```

---

## 9. Regras invioláveis

1. **Nunca adicionar botões de ação** (Editar, Excluir, Excel, Visualizar, Fechar) — tela é somente consulta.
2. **Dimensões do diálogo:** sempre `FROM 0,0 TO 650,1300 PIXEL`.
3. **LISTBOX:** sempre `@40,5 ... SIZE 640,260`.
4. **Filtros:** sempre na linha @5; botões sempre na linha @20.
5. **Array vazio:** sempre validar antes de abrir `MSDIALOG`.
6. **Dados:** sempre via `BeginSql`; nunca loop direto com `DbSkip` na tabela original.
7. **Ativar:** sempre `ACTIVATE MSDIALOG oDlg CENTERED`.

---

## 10. LISTBOX largo (13+ colunas)

Para listboxes com **13 ou mais colunas**, aplicar estas regras:

### SIZE vs soma das colunas

- **Com scroll horizontal forçado:** `SIZE` do LISTBOX = soma de `aColSizes` + 1

  ```advpl
  @40,5 LISTBOX oL FIELDS HEADER "Data","Sol.","Ped.","Item","CC","NomeCC","Forn.","Cond.","Comp.","Qtd","VUnit","Desc","VTotal" ;
      SIZE 1270,260 OF oDlg PIXEL

  oL:aColSizes := {62,40,50,32,48,82,120,82,78,60,80,80,75}
  // soma = 889, SIZE 1270 → todas visíveis sem scroll
  ```

- **Sem scroll horizontal (tudo visível):** `SIZE` maior que a soma das colunas (ex.: `SIZE 1270` para 971px de colunas)

### Configuração obrigatória

```advpl
oL:lHScroll := .T.
oL:lVScroll := .T.
```

### SubStr proporcional

Calcular `SubStr` como `largura_coluna / 7` arredondado:

| Coluna | Largura | SubStr (÷7) | Código |
|--------|---------|-------------|--------|
| NomeCC | 82px | 12 | `SubStr(campo, 1, 12)` |
| Forn. | 120px | 17 | `SubStr(campo, 1, 17)` |
| Cond. | 82px | 12 | `SubStr(campo, 1, 12)` |
| Comp. | 78px | 11 | `SubStr(campo, 1, 11)` |
| Qtd | 60px | 9 | `Transform(campo,"@E 999,999.99")` |

### Exemplo completo — 13 colunas

```advpl
@40,5 LISTBOX oL FIELDS HEADER ;
    "Data","Sol.","Ped.","Item","CC","NomeCC","Forn.","Cond.","Comp.","Qtd","VUnit","Desc","VTotal" ;
    SIZE 1270,260 OF oDlg PIXEL

oL:SetArray(aArray)
oL:aColSizes := {62,40,50,32,48,82,120,82,78,60,80,80,75}
oL:lHScroll  := .T.
oL:lVScroll  := .T.
oL:bLine := {|| {;
    DtoC(aArray[oL:nAt,1]), ;
    AllTrim(aArray[oL:nAt,2]), ;
    AllTrim(aArray[oL:nAt,3]), ;
    AllTrim(aArray[oL:nAt,4]), ;
    AllTrim(aArray[oL:nAt,5]), ;
    SubStr(AllTrim(aArray[oL:nAt,6]), 1, 12), ;
    SubStr(AllTrim(aArray[oL:nAt,7]) + "/" + AllTrim(aArray[oL:nAt,8]), 1, 17), ;
    SubStr(AllTrim(aArray[oL:nAt,9]), 1, 12), ;
    SubStr(AllTrim(aArray[oL:nAt,10]), 1, 11), ;
    Transform(aArray[oL:nAt,11], "@E 999,999.99"), ;
    Transform(aArray[oL:nAt,12], "@E 9,999,999.99"), ;
    Transform(aArray[oL:nAt,13], "@E 9,999,999.99"), ;
    Transform(aArray[oL:nAt,14], "@E 9,999,999.99") }}
