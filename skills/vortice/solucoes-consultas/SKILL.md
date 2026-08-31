---
name: solucoes-consultas
description: 'Skill Vortice custom solucoes-consultas - SC7/CINVJ6_DEV 7.00.240223P'
---

# Skill: SoluÃ§Ãµes de Consulta / F3 / FWLookup â€” AdvPL/Protheus

> SoluÃ§Ãµes validadas em produÃ§Ã£o para F3, Consulta PadrÃ£o, FWLookup e SXB.
> Caso real resolvido: ZZ4 (solicitaÃ§Ã£o cadastral de fornecedores) no campo A2_ZSOLID do MATA020.

---

## 1. Problema: "Alias does not exist" ao abrir F3

**Causa raiz**: FWLookup â†’ BUILDBROWSE â†’ SETALIAS("ZZ4") tenta acessar a tabela antes dela estar aberta na sessÃ£o.

**SoluÃ§Ã£o tripla** (as trÃªs sÃ£o necessÃ¡rias):

| Onde | O que fazer | Exemplo |
|------|-------------|---------|
| PE de inicializaÃ§Ã£o | `ChkFile("TABELA")` | `MTA020.PRW: ChkFile("ZZ4")` |
| `X3_INIBRW` no SX3 | `"U_OPENALIAS()"` | Campo que invoca F3 |
| FunÃ§Ã£o User | SÃ³ `ChkFile` + `Return .T.` | `OPENZZ4.PRW` |

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

### SoluÃ§Ã£o correta: SXB Tipo 6 com prefixo `@`

**TDN oficial:** Tipo 6 = filtro SQL ANSI com prefixo `@` (Protheus 12+).

```sql
@ZZ4_STATUS = '0'
```

**Como registrar:**
```advpl
ZSXBAdd("ZZ4", "6", "01", "01", "" , "@ZZ4_STATUS = '0'")
```

### O que NÃƒO funciona (testado em produÃ§Ã£o)

| Tentativa | Motivo |
|-----------|--------|
| âŒ `DbSetFilter` no alias | FWLookup monta SQL prÃ³pria, ignora filtro de workarea |
| âŒ `XB_WCONTEM` | Campo nÃ£o existe no SXB padrÃ£o |
| âŒ SXB Tipo 9 | NÃ£o Ã© tipo de filtro (Ã© "Fonte de direitos") |

---

## 3. Tabela de Tipos SXB (referÃªncia completa)

| Tipo | Finalidade | XB_COLUNA | XB_CONTEM | ObrigatÃ³rio |
|------|-----------|-----------|-----------|-------------|
| 1 | DefiniÃ§Ã£o da tabela/alias | "DB" | Nome do alias | **SIM** |
| 2 | Ãndices / colunas do browse | "01","02"... | "" (vazio) | **SIM** (1 por coluna) |
| 3 | PermissÃ£o incluir via consulta | "01" | CÃ³digo permissÃ£o | Opcional |
| 4 | Campos a exibir por Ã­ndice | "01" | Nome do campo | **SIM** (1 por coluna) |
| 5 | Campo(s) de retorno | "01" | "ALIAS->CAMPO" | **SIM** |
| **6** | **Filtro SQL (ANSI com @)** | "01" | **"@CAMPO = 'valor'"** | **Opcional** |
| 7 | Limite superior/inferior | "01" | Valor limite | Opcional |
| 8 | Consulta analÃ­tica | "01" | SQL/funÃ§Ã£o | Opcional |
| 9 | Fonte responsÃ¡vel | "01" | "PROG" | Opcional |

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

## 5. Points of Entry â€” Tabela de Contextos

| PE | Quando dispara | Uso principal |
|----|---------------|---------------|
| `MTA020` | InicializaÃ§Ã£o do MATA020 | Abrir alias, limpar filtros |
| `MT020ATE` | AtivaÃ§Ã£o do browse MATA020 | Filtro adicional SA2 |
| `MT020INC` | ApÃ³s incluir fornecedor | Atualizar status ZZ4 |
| `MT20FOPOS` | ApÃ³s gravar (incluir/alterar) | PÃ³s-processamento |
| `M020EXC` | Durante exclusÃ£o | Reverter status |

**Regras obrigatÃ³rias para PEs:**
```advpl
User Function MTA020()
    Local aArea := GetArea()
    // ... lÃ³gica ...
    RestArea(aArea)
Return
```
- Sempre `GetArea()`/`RestArea()`
- Nome mÃ¡ximo 10 caracteres
- Sempre retornar `.T.` em PEs que nÃ£o devem bloquear

---

## 6. DiagnÃ³stico em ProduÃ§Ã£o

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

## 7. Checklist de VerificaÃ§Ã£o RÃ¡pida

```text
1. Select("ALIAS") > 0?    â†’ alias estÃ¡ aberto?
2. DbSeek funciona?         â†’ Ã­ndice correto?
3. SXB existe?              â†’ DbSeek("ALIAS"+"1"+"01")?
4. SX3 X3_F3 correto?       â†’ aponta para o alias correto?
5. X3_VALID/X3_INIBRW existe? â†’ U_FFXX() compilada?
```

---

## 8. FWMBrowse com Cores (CADFORN â€” caso real)

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

// NÃƒO usar SetFilterDefault - esconderia registros cadastrados
oBrw:Activate()
```

---

## 9. Workflow de ResoluÃ§Ã£o (sequÃªncia testada)

```
1. IDENTIFICAR o erro
   - "Alias does not exist"? â†’ Item 1 (X3_INIBRW + ChkFile)
   - F3 abre mas dados errados? â†’ Item 2 (SXB Tipo 6)
   - Browse nÃ£o mostra todos? â†’ Item 8 (SetFilterDefault)

2. CONSULTAR TDN oficial (tdn.totvs.com)
   - SXB: https://tdn.totvs.com/pages/viewpage.action?pageId=22479707
   - FWLookup: documentaÃ§Ã£o do framework

3. CRIAR DIAG function
   - SQL direto para verificar estado real

4. APLICAR soluÃ§Ã£o documentada acima

5. REINICIAR Protheus (SXB precisa de restart)

6. TESTAR
```

