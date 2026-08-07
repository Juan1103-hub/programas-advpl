# Protheus SmartView - Objeto de Negocio com IntegratedProvider (TLPP)

Referencia para criacao de Objetos de Negocio (Business Objects) do SmartView
usando a classe `IntegratedProvider` em TLPP. Permite expor tabelas do Protheus
como fonte de dados nativa para relatorios do SmartView/TReports.

> Fonte: TDN - "Smart View - Criacao de Objetos de Negocios" (pageId 625448935).
> Requisito: TL++ e LIB Label >= 12.1.2210 (Central de Atendimento recomenda >= 12.1.2310).

---

## 1. Visao Geral

O Objeto de Negocio (ON) e uma classe TLPP que o SmartView consome via REST para:

- Listar o schema (campos) do relatorio
- Buscar dados paginados
- Aplicar filtros definidos na interface do SmartView
- Tratar dados protegidos (LGPD)

Vantagens: paginacao automatica, filtros nativos, lookup nos campos, querys
elaboradas em varias tabelas, contextualizacao de filial via `RetSqlName`/`xFilial`.

**Importante:** usar em ambiente com dicionario no banco de dados (recomendado).

---

## 2. Estrutura Obrigatoria do Fonte

```tlpp
#include "msobject.ch"
#include "protheus.ch"
// Referencia o .th da classe
#include "totvs.framework.treports.integratedprovider.th"

// Cria um novo namespace para sua classe
namespace custom.financeiro.naturezas.integratedprovider

// Annotation que registra o ON no SmartView. Para desativar: active=.F.
@totvsFrameworkTReportsIntegratedProvider(active=.T., team="SIGAFIN", tables="SED", name="Naturezas", country="ALL", initialRelease="12.1.2210")

// Herda a classe principal com o namespace completo
class SEDTReportsBusinessObject from totvs.framework.treports.integratedprovider.IntegratedProvider
    public method new() as object
    public method getDisplayName() as character
    public method getAreas() as array
    public method getData() as object
    public method getSchema() as object
endclass
```

### Annotation `@totvsFrameworkTReportsIntegratedProvider`

| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| active | L | `.T.` ativa o ON; `.F.` desativa sem excluir fonte |
| team | C | Sigla do modulo/equipe (ex.: SIGAFIN, SIGACOM) |
| tables | C | Tabelas envolvidas (ex.: SED, SA2, SB1) |
| name | C | Nome do ON exibido no SmartView |
| country | C | Paises de disponibilidade (ex.: ALL, BRA) |
| initialRelease | C | Versao minima (ex.: 12.1.2210) |

---

## 3. Metodos Principais

### 3.1 `new()` — construtor

Cria `oData` e `oSchema`. Define area, nome e descricao (obrigatorios).

```tlpp
method new() class SEDTReportsBusinessObject
    _Super:new()
    self:appendArea("Financeiro")     // obrigatorio: pelo menos 1 area
    self:setDisplayName("Naturezas")  // obrigatorio: nome do relatorio
    self:setDescription("Naturezas financeiras do Protheus") // obrigatorio
return self
```

### 3.2 `getSchema()` — estrutura de campos

Retorna `self:oSchema`. Duas formas:

```tlpp
// Forma 1: aliasToSchema (campos do dicionario, id = nome do campo na tabela)
method getSchema() as object class SEDTReportsBusinessObject
    self:aliasToSchema("SED", {"ED_FILIAL", "ED_CODIGO", "ED_DESCRIC"})
return self:oSchema

// Forma 2: addProperty manual
method getSchema() as object class SEDTReportsBusinessObject
    self:addProperty("Codigo", "Codigo da Natureza", "string", "Natureza", "ED_CODIGO")
    self:addProperty("Descricao", "Descricao", "memo", "Descricao", "ED_DESCRIC") // memo: LIB >= 20230403
return self:oSchema
```

**Performance:** nunca enviar alias com todos os campos (`xField` vazio) no
`aliasToSchema` — filtre apenas os campos necessarios.

#### `addProperty(cId, cDescription, cType, cDisplayName, cRealName, cComboValues, lIsRequired, cRenameField, lCanFilter)`

| Param | Descricao |
|-------|-----------|
| cId | ID da propriedade (sem caracteres especiais; aceita `_`). Pode ser o nome do campo |
| cDescription | Descricao da propriedade |
| cType | Tipo: `string`, `number`, `boolean`, `date`, `memo` |
| cDisplayName | Nome de exibicao |
| cRealName | Nome real do campo no Protheus (campo manual: repetir cId) |
| cComboValues | Valores key-label estilo SX3 (ex.: `"D MG 01=Filial BH; D MG 02=Filial Uberaba"`) — LIB >= 20220321 |
| lIsRequired | `.T.` obriga preenchimento — LIB >= 20220321 |
| cRenameField | Apelido do campo p/ query com campos repetidos — LIB >= 20220905 |
| lCanFilter | `.F.` impede filtro — LIB >= 20230626, default `.T.` |

#### `addParameter(cId, cDisplayName, cType, lIsMultiValue, cUrl, lHasOptions, lHasLookUp, cIdConsult, cParamId, cDescription, lAllowNull, aDefaultValues, nMaxLength, lVisible)`

Parâmetros nativos do ON — LIB >= 20230515:

```tlpp
self:addParameter("MV_PAR01", "Codigo do Produto", "string", .F.)
self:addParameter("Xisto_Combo", "Situacao", "string", .F., "", .T., .F., "MTR110", "MV_PAR02")
self:addParameter("Xisto_Logical", "Ativo", "logical", .F., "", .F., .F., "", "", "", .T., {.F.})
```

#### Leitura dos parâmetros no `getData` (`oFilter:getParameters()`)

Exemplo validado em produção (Central de Atendimento TOTVS, artigo 25977195445911):

```tlpp
method getData(nPage as numeric, oFilter as object) class SB1TReportsBusinessObject
    Local cQuery   as character
    Local jParams  as json

    self:setPageSize(500)

    cQuery := "SELECT SB1.B1_FILIAL, SB1.B1_COD, SB1.B1_DESC, SB1.B1_TIPO, SB1.B1_UM, SB1.B1_GRUPO " +;
              "FROM " + RetSqlName("SB1") + " SB1 " +;
              "WHERE SB1.D_E_L_E_T_ = ' ' "

    if oFilter:hasFilter()
        cQuery += " AND " + oFilter:getSQLExpression()
    endif

    // Parâmetros definidos no getSchema(); recebe o retorno informado no SmartView
    if ValType(oFilter) == "O"
        jParams := oFilter:getParameters()

        if !Empty(jParams["CODIGO"][1])
            cQuery += " AND SB1.B1_COD = '" + AllTrim(jParams["CODIGO"][1]) + "'"
        endif

        if !Empty(jParams["GRUPO"][1])
            cQuery += " AND SB1.B1_GRUPO = '" + AllTrim(jParams["GRUPO"][1]) + "'"
        endif
    endif

    self:setQuery(cQuery)
    self:setOrder("SB1.B1_COD")

return self:oData

method getSchema() class SB1TReportsBusinessObject
    // Parâmetros que virão da tela do SmartView (filtros)
    self:addParameter("CODIGO", "Codigo do Produto", "string", .F., "SB1.B1_COD")
    self:addParameter("GRUPO",  "Grupo de Produtos", "string", .F., "SB1.B1_GRUPO")

    // Propriedades exibidas no relatório
    self:addProperty("B1_FILIAL", "Filial", "string", "Filial do Produto", "SB1.B1_FILIAL")
    self:addProperty("B1_COD",    "Codigo", "string", "Codigo do Produto", "SB1.B1_COD")
    self:addProperty("B1_DESC",   "Descricao", "string", "Descricao do Produto", "SB1.B1_DESC")
    self:addProperty("B1_TIPO",   "Tipo", "string", "Tipo de Produto", "SB1.B1_TIPO")
    self:addProperty("B1_UM",     "Unidade", "string", "Unidade de Medida", "SB1.B1_UM")
    self:addProperty("B1_GRUPO",  "Grupo", "string", "Grupo de Produtos", "SB1.B1_GRUPO")

return self:oSchema
```

**Regras dos parâmetros:**
- `cId` do `addParameter` é a chave do JSON retornado por `oFilter:getParameters()`
- Valores multivalue: `jParams["CHAVE"][1]`, `[2]`, ... (acessar sempre com índice)
- O 5º param (`cUrl`) aceita o campo real qualificado (ex.: `"SB1.B1_COD"`) — usar com qualificação de tabela para evitar ambiguidade em queries com join
- Sempre validar `ValType(oFilter) == "O"` antes de chamar `getParameters()`

### 3.3 `getData(nPage, oFilter)` — dados

Retorna `self:oData`. Tres formas:

#### Forma 1: `aliasToData` (paginação automatica via workarea)

```tlpp
method getData(nPage as numeric, oFilter as object) class SEDTReportsBusinessObject
    self:setPageSize(500)  // setar ANTES do aliasToData (default 100)
    self:aliasToData("SED", oFilter)
return self:oData
```

#### Forma 2: query com paginacao automatica (IDs `#QueryFields#`/`#QueryWhere#`)

```tlpp
method getData() as object class SB1TReportsBusinessObject
    Local cQuery as character

    self:setPageSize(200)
    cQuery := "SELECT #QueryFields# FROM " + RetSQLName("SB1") + " WHERE #QueryWhere#"
    self:setQuery(cQuery)
    self:setOrder("B1_COD")
    self:setWhere("B1_FILIAL = '" + FWxFilial('SB1') + "' AND D_E_L_E_T_ = ' '")
return self:oData
```

**Regras da query:**
- Se `SELECT *`, o ID `#QueryFields#` e OBRIGATORIO (campos virao do getSchema)
- `#QueryWhere#` usado quando o where sera setado depois via `setWhere`
- Sempre `D_E_L_E_T_ = ' '` e filtro de filial

#### Forma 3: query manual com loop e `appendData` (controle total)

```tlpp
method getData(nPage as numeric, oFilter as object) class SA2TReportsBusinessObject
    Local cQuery as character
    Local cAlias as character
    Local oExec  as object

    cQuery := "SELECT A2_NOME, A2_COD FROM " + RetSqlName('SA2') + " WHERE D_E_L_E_T_ = ' '"

    if oFilter:hasFilter()
        cQuery += " AND " + oFilter:getSQLExpression()
    endif

    oExec  := FwExecStatement():New(ChangeQuery(cQuery))
    cAlias := oExec:OpenAlias()

    while !(cAlias)->(Eof())
        self:appendData({"Nome": (cAlias)->A2_NOME, "Codigo": (cAlias)->A2_COD})
        (cAlias)->(DBSkip())
    enddo

    (cAlias)->(DBCloseArea())
return self:oData
```

A chave do `appendData` deve ser **exatamente** o `cId` definido no `addProperty`.

### 3.4 Paginação manual (complemento da Forma 3)

```tlpp
    Local nSkip  as numeric
    Local nCount as numeric

    if nPage == 1
        (cAlias)->(DbGoTop())
    else
        nSkip := ((nPage - 1) * self:getPageSize())
        (cAlias)->(DbSkip(nSkip))
    endif

    nCount := 0
    while !(cAlias)->(Eof()) .and. nCount < self:getPageSize()
        self:appendData({"Codigo": (cAlias)->B1_COD})
        (cAlias)->(DBSkip())
        nCount++
    enddo

    self:setHasNext(!(cAlias)->(Eof()))
    (cAlias)->(DBCloseArea())
```

| Metodo | Descricao |
|--------|-----------|
| `setPageSize(n)` | Itens por requisicao (default 100). **Depreciado na LIB >= 20240408** |
| `getPageSize()` | Retorna tamanho da pagina |
| `setQuery(cQuery)` | Seta a query (IDs `#QueryFields#`, `#QueryWhere#`) |
| `setWhere(cWhere)` | Seta o where da query |
| `setOrder(cOrder)` | Campo de ordenacao |
| `setHasNext(l)` | Indica se existe proxima pagina |

> **Referência adicional validada:** Central de Atendimento TOTVS, artigo
> "Criacao de Objeto de Negocio SmartView com TLPP" (id 25977195445911) —
> confirma versao minima 12.1.2310, obrigatoriedade de reiniciar o AppServer
> apos compilacao, e usa o mesmo exemplo da TDN (SB1TReportsBusinessObject).

---

## 4. Filtros (objeto oFilter)

Usados dentro de `getData`:

| Metodo | Retorno | Descricao |
|--------|---------|-----------|
| `oFilter:hasFilter()` | L | Existe filtro de dados |
| `oFilter:hasFields()` | L | Existe filtro de campos de retorno |
| `oFilter:getAdvplExpression()` | C | Filtro em formato ADVPL |
| `oFilter:getSQLExpression()` | C | Filtro em formato SQL |
| `oFilter:getFields()` | A | Campos solicitados p/ retorno |
| `oFilter:getRawFilter()` | J | JSON original do filtro |
| `oFilter:getParameters()` | J | Params nativos do ON (LIB >= 20230626) |

---

## 5. Datas

Campos `date` devem ser enviados no formato ISO 8601 UTC
(`aaaa-mm-ddThh:mm:ss-+TimeZone`). Usar `FWTimeStamp`:

```tlpp
"Revisao": iif(!Empty((cAlias)->B1_UREV), FwTimeStamp(5, StoD((cAlias)->B1_UREV), "00:00:00"), nil)
```

Se a data estiver vazia, enviar `nil`. LIB >= 20230807 tem funcoes de conversao
dedicadas (ver TDN "Smart View - Conversao de datas", pageId 772806491).

---

## 6. Lookup e Combo em Filtros/Campos

### Key-Label (combobox) — LIB >= 20220321

```tlpp
method new() class SB1TReportsBusinessObject
    _Super:new()
    self:setIsCBoxLookup(.T., .T.)  // lKeyLabel, lX3 (lX3=.T. usa SX3 p/ key-label de todos campos; pode afetar performance)
return self

method getSchema() as object class SB1TReportsBusinessObject
    self:addProperty("Filial", "Filial", "string", "Filial", "B1_FILIAL", "D MG 01=Filial BH; D MG 02=Filial Uberaba", .F.)
return self:oSchema
```

### Padrão LookUp (ID/Prod/Desc) — LIB >= 20220321

```tlpp
method new() class SB1TReportsBusinessObject
    _Super:new()
    self:setIsLookup(.T.)
return self
```

No `getSchema`, usar um dos metodos:

| Metodo | Descricao |
|--------|-----------|
| `setDescriptor(cId, cProd, cDesc)` | Cabecalhos do lookup (**depreciado** LIB >= 20230515; usar aDescriptor em setLookupQuery/setLookupVal) |
| `setLookUpVal(cField, aStruct, lIsRequired, aDescriptor, nFieldReturn)` | Valores manuais do lookup |
| `setX5Struct(cField, cTable, lIsRequired)` | Valores a partir da SX5 |
| `setLookUpQuery(cField, aFields, cQuery, lIsRequired, aDescriptor, cFieldReturn, cOrder)` | Valores via query |

---

## 7. Pergunte (SX1) — LIB >= 20230515

```tlpp
method new() class SRA2TReportsBusinessObject
    _Super:new()
    self:setDisplayName("Funcionarios")

    if !self:setPergunte("GPER140")
        FwLogMsg("WARN",, "SmartView",,,, "Grupo de perguntas nao encontrado",,,)
    endif
return self
```

Todos os `MV_PARxx` retornam em maiusculo. Retorno logico do `setPergunte` existe
desde LIB >= 20230918.

---

## 8. Erros — `setErrorStatus(nCodError, cMessage, cDetailedMsg)` — LIB >= 20230918

Usado em `getData`/`getSchema`; somente codigos 4xx:

```tlpp
if !self:setPergunte("GPER140")
    self:setErrorStatus(400, "Sem Pergunte", "Verifique o grupo de perguntas informado!")
endif
```

---

## 9. Dados Protegidos (LGPD)

Para obfuscar campos protegidos no `getData` (exemplo da TDN):

```tlpp
aPDFields := FwProtectedDataUtil():UsrAccessPDField(__cUserID, self:aFields)
lObfuscated := Len(aPDFields) != Len(self:aFields)

// no loop de appendData:
if lObfuscated .and. aScan(aPDFields, cCampoReal) == 0
    jItems[cId] := FwProtectedDataUtil():ValueAsteriskToAnonymize((cAlias)->(cCampoReal))
else
    jItems[cId] := (cAlias)->(cCampoReal)
endif
```

---

## 10. ON Dinamico: vincular QUALQUER tabela (schema montado via SX3)

Objetivo do projeto: vincular qualquer tabela do dicionario, inclusive as que
ainda nao existem como ON no repositorio do SmartView.

Abordagem: **uma classe unica que monta o schema em runtime via SX3**
(`GetSx3Cache`/`SX3->X3_TIPO`) e a query com `#QueryFields#`/`#QueryWhere#`
(que o framework resolve com base no schema montado).

```tlpp
method getSchema() as object class DINONBusinessObject
    Local cAliasTbl as character
    Local nX        as numeric

    // Tabela alvo definida via parametro/constante (ex.: self:cTable)
    cAliasTbl := self:cTable

    // Percorre o dicionario de campos da tabela
    For nX := 1 To Len(FWPreparedStatement("SX3"):OpenAlias())  // ou consulta SX3 direta
        // para cada campo:
        //   cId, cType (converter X3_TIPO -> string/number/boolean/date/memo),
        //   cRealName = nome do campo
        //   self:addProperty(cId, cDesc, cType, cDisplay, cRealName)
    Next nX

    // Ids: usar sempre o nome real do campo (B1_COD, A2_NOME...) para o
    // framework resolver o #QueryFields# corretamente
return self:oSchema
```

```tlpp
method getData() as object class DINONBusinessObject
    Local cQuery as character

    self:setPageSize(200)
    cQuery := "SELECT #QueryFields# FROM " + RetSQLName(self:cTable) + " WHERE #QueryWhere#"
    self:setQuery(cQuery)
    self:setOrder(self:cOrder)
    self:setWhere("D_E_L_E_T_ = ' ' AND " + cFilialSql + " = '" + FWxFilial(self:cTable) + "'")
return self:oData
```

**Pendencias para validar no momento do codigo:**
- Conversao `X3_TIPO` -> tipo schema (`C->string`, `N/F->number`, `D->date`, `L->boolean`, `M->memo`)
- Filtrar campos `MOVEIS`/`USADO` da SX3 conforme a necessidade
- `FWPreparedStatement` vs `TCQuery` direto na SX3 (seguir skill `query-builder`/`embedded-sql`)
- Cuidado com performance: pagina de schema grande = mais lentidao no design do relatorio

---

## 11. Compilacao e Disponibilizacao

1. Compilar o `.tlpp` no RPO (via `advpl-tlpp-compile`/tds-vscode)
2. **Reiniciar o AppServer** — obrigatorio para o ON ficar visivel no ambiente REST
3. Validar no SmartView: sessao "Objetos de Negocio" -> o ON aparece pela area definida
4. Logs: chave `FwTraceLog=1` no INI do ambiente p/ diagnosticar a integracao

---

## 12. Checklist de Qualidade

- [ ] Includes corretos: `msobject.ch`, `totvs.framework.treports.integratedprovider.th`
- [ ] Namespace unico: `custom.<modulo>.<nome>.integratedprovider`
- [ ] Annotation com `active=.T.`, `team`, `name`, `country`, `initialRelease`
- [ ] `_Super:new()` no construtor
- [ ] `appendArea`, `setDisplayName`, `setDescription` preenchidos (obrigatorios)
- [ ] `getSchema` retorna `self:oSchema`; `getData` retorna `self:oData`
- [ ] Query com `D_E_L_E_T_ = ' '` e filtro de filial (`FWxFilial`/`xFilial`)
- [ ] `RetSqlName()` p/ nome fisico da tabela
- [ ] `ChangeQuery()` antes de `FWExecStatement`
- [ ] Datas no formato ISO 8601 (`FwTimeStamp(5, ...)`); vazia = `nil`
- [ ] chaves `appendData` == `cId` do `addProperty`
- [ ] Paginacao tratada (automatica ou manual com `setHasNext`)
- [ ] Filial: nunca usar variavel `cFilial` (reservada)
- [ ] Nao usar `IIF()` inline — usar `If/Else/EndIf` (SonarQube CA4000)
- [ ] Arquivo em CP-1252 (Windows-1252) — nunca UTF-8
- [ ] Reiniciar AppServer apos compilacao
