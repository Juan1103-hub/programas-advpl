# Skill: Soluções de Consulta / F3 / FWLookup — AdvPL/Protheus

> Soluções validadas em produção para F3, Consulta Padrão, FWLookup e SXB.
> Caso real resolvido: ZZ4 (solicitação cadastral de fornecedores) no campo A2_ZSOLID do MATA020.

---

## 1. Problema: "Alias does not exist" ao abrir F3

**Causa raiz**: FWLookup → BUILDBROWSE → SETALIAS("ZZ4") tenta acessar a tabela antes dela estar aberta na sessão.

**Solução tripla** (as três são necessárias):

| Onde | O que fazer | Exemplo |
|------|-------------|---------|
| PE de inicialização | `ChkFile("TABELA")` | `MTA020.PRW: ChkFile("ZZ4")` |
| `X3_INIBRW` no SX3 | `"U_OPENALIAS()"` | Campo que invoca F3 |
| Função User | Só `ChkFile` + `Return .T.` | `OPENZZ4.PRW` |

**Template da User Function X3_INIBRW:**
```advpl
User Function OPENZZ4()
    Local aArea := GetArea()
    If Select("ZZ4") <= 0
        If !ChkFile("ZZ4")
            RestArea(aArea)
            Return .T.
        EndIf
    EndIf
    RestArea(aArea)
Return .T.
```

---

## 2. Problema: F3 mostra todos os registros (precisa filtrar)

### Solução correta: SXB Tipo 6 com prefixo `@`

**TDN oficial:** Tipo 6 = filtro SQL ANSI com prefixo `@` (Protheus 12+).

```sql
@ZZ4_STATUS = '0'
```

**Como registrar:**
```advpl
ZSXBAdd("ZZ4", "6", "01", "01", "" , "@ZZ4_STATUS = '0'")
```

### O que NÃO funciona (testado em produção)

| Tentativa | Motivo |
|-----------|--------|
| ❌ `DbSetFilter` no alias | FWLookup monta SQL própria, ignora filtro de workarea |
| ❌ `XB_WCONTEM` | Campo não existe no SXB padrão |
| ❌ SXB Tipo 9 | Não é tipo de filtro (é "Fonte de direitos") |

---

## 3. Tabela de Tipos SXB (referência completa)

| Tipo | Finalidade | XB_COLUNA | XB_CONTEM | Obrigatório |
|------|-----------|-----------|-----------|-------------|
| 1 | Definição da tabela/alias | "DB" | Nome do alias | **SIM** |
| 2 | Índices / colunas do browse | "01","02"... | "" (vazio) | **SIM** (1 por coluna) |
| 3 | Permissão incluir via consulta | "01" | Código permissão | Opcional |
| 4 | Campos a exibir por índice | "01" | Nome do campo | **SIM** (1 por coluna) |
| 5 | Campo(s) de retorno | "01" | "ALIAS->CAMPO" | **SIM** |
| **6** | **Filtro SQL (ANSI com @)** | "01" | **"@CAMPO = 'valor'"** | **Opcional** |
| 7 | Limite superior/inferior | "01" | Valor limite | Opcional |
| 8 | Consulta analítica | "01" | SQL/função | Opcional |
| 9 | Fonte responsável | "01" | "PROG" | Opcional |

---

## 4. Estrutura SXB completa (template ZZ4)

```advpl
// Tipo 1 - CABECALHO
ZSXBAdd("ZZ4", "1", "01", "DB", "Solicitac ZZ4", "ZZ4")

// Tipo 2 - CABECALHOS DAS COLUNAS (XB_CONTEM vazio!)
ZSXBAdd("ZZ4", "2", "01", "01", "ID"          , "")
ZSXBAdd("ZZ4", "2", "02", "02", "Razao Social", "")
ZSXBAdd("ZZ4", "2", "03", "03", "CNPJ"        , "")
ZSXBAdd("ZZ4", "2", "04", "04", "Status"      , "")

// Tipo 4 - MAPEAMENTO CAMPO-COLUNA
ZSXBAdd("ZZ4", "4", "01", "01", "ID"          , "ZZ4_ID")
ZSXBAdd("ZZ4", "4", "01", "02", "Razao Social", "ZZ4_RAZAO")
ZSXBAdd("ZZ4", "4", "01", "03", "CNPJ"        , "ZZ4_CNPJ")
ZSXBAdd("ZZ4", "4", "01", "04", "Status"      , "ZZ4_STATUS")

// Tipo 5 - RETORNO
ZSXBAdd("ZZ4", "5", "01", "01", ""            , "ZZ4->ZZ4_ID")

// Tipo 6 - FILTRO SQL (opcional)
ZSXBAdd("ZZ4", "6", "01", "01", ""            , "@ZZ4_STATUS = '0'")
```

---

## 5. Points of Entry — Tabela de Contextos

| PE | Quando dispara | Uso principal |
|----|---------------|---------------|
| `MTA020` | Inicialização do MATA020 | Abrir alias, limpar filtros |
| `MT020ATE` | Ativação do browse MATA020 | Filtro adicional SA2 |
| `MT020INC` | Após incluir fornecedor | Atualizar status ZZ4 |
| `MT20FOPOS` | Após gravar (incluir/alterar) | Pós-processamento |
| `M020EXC` | Durante exclusão | Reverter status |

**Regras obrigatórias para PEs:**
```advpl
User Function MTA020()
    Local aArea := GetArea()
    // ... lógica ...
    RestArea(aArea)
Return
```
- Sempre `GetArea()`/`RestArea()`
- Nome máximo 10 caracteres
- Sempre retornar `.T.` em PEs que não devem bloquear

---

## 6. Diagnóstico em Produção

```advpl
User Function DIAGXXX()
    Local aArea  := GetArea()
    Local cAls   := GetNextAlias()
    Local cQuery := ""

    BeginSql Alias cAls
        SELECT * FROM %Table:ZZ4% WHERE %NotDel%
    EndSql

    While !(cAls)->(Eof())
        ConOut(AllTrim((cAls)->ZZ4_ID) + " - " + AllTrim((cAls)->ZZ4_STATUS))
        (cAls)->(DbSkip())
    EndDo
    (cAls)->(DbCloseArea())

    RestArea(aArea)
Return
```

---

## 7. Checklist de Verificação Rápida

```text
1. Select("ALIAS") > 0?    → alias está aberto?
2. DbSeek funciona?         → índice correto?
3. SXB existe?              → DbSeek("ALIAS"+"1"+"01")?
4. SX3 X3_F3 correto?       → aponta para o alias correto?
5. X3_VALID/X3_INIBRW existe? → U_FFXX() compilada?
```

---

## 8. FWMBrowse com Cores (CADFORN — caso real)

```advpl
oBrw := FWMBrowse():New()
oBrw:SetAlias("ZZ4")
oBrw:SetDescription("Solicitacao Cadastral de Fornecedores")
oBrw:SetMenuDef("CADFORN")
oBrw:DisableDetails()

// Cores: BR_BRANCO = pendente, BR_VERMELHO = cadastrado
oBrw:AddLegend("ZZ4_STATUS == '0'", "BR_BRANCO"  , "Pendente")
oBrw:AddLegend("ZZ4_STATUS == '1'", "BR_VERMELHO", "Cadastrado")

// bChange para sincronizar status automaticamente
oBrw:bChange := {|| FZ4SyncBrw(oBrw) }

// NÃO usar SetFilterDefault - esconderia registros cadastrados
oBrw:Activate()
```

---

## 9. Workflow de Resolução (sequência testada)

```
1. IDENTIFICAR o erro
   - "Alias does not exist"? → Item 1 (X3_INIBRW + ChkFile)
   - F3 abre mas dados errados? → Item 2 (SXB Tipo 6)
   - Browse não mostra todos? → Item 8 (SetFilterDefault)

2. CONSULTAR TDN oficial (tdn.totvs.com)
   - SXB: https://tdn.totvs.com/pages/viewpage.action?pageId=22479707
   - FWLookup: documentação do framework

3. CRIAR DIAG function
   - SQL direto para verificar estado real

4. APLICAR solução documentada acima

5. REINICIAR Protheus (SXB precisa de restart)

6. TESTAR
```
