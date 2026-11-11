# Padrões de Solução — Suprimentos AdvPL/Protheus

> Soluções validadas em produção para problemas recorrentes.
> Atualizado: 15/06/2026

---

## F3 / Consulta Padrão / FWLookup

### Problema: "Alias does not exist" ao abrir F3 em tabela customizada

**Causa raiz**: FWLookup:OPEN12 → BUILDBROWSE → SETALIAS("ALIAS") tenta acessar a tabela antes dela estar aberta na sessão.

**Árvore de decisão**:

```
1. O alias existe no SX2 (dicionário)?
   ├── NÃO → ChkFile() falha. Precisa registrar a tabela no SX2 primeiro.
   └── SIM → vá para 2

2. O F3 abre mas mostra todos os registros (precisa filtrar)?
   ├── NÃO → vá para 3
   └── SIM → usar SXB Tipo 6 (NÃO DbSetFilter, NÃO Tipo 9)
           └── XB_CONTEM = "@CAMPO = 'valor'" (SQL ANSI, Protheus 12+)
           └── Ou XB_CONTEM = "Alias->CAMPO == 'valor'" (AdvPL filter)

3. A tabela está aberta quando FWLookup tenta SETALIAS?
   ├── NÃO → solução tripla:
   │   ├── PE MTA020: ChkFile("ALIAS") na inicialização
   │   ├── X3_INIBRW: "U_OPENALIAS()" para garantir antes do FWLookup
   │   └── OPENALIAS.PRW: User Function que só faz ChkFile + Return .T.
   │
   └── SIM → provavelmente outro problema (verificar SXB, índices)
```

### Estrutura SXB correta para consulta padrão

| Tipo | XB_COLUNA | XB_CONTEM | Obrigatório |
|------|-----------|-----------|-------------|
| 1 | "DB" | Alias da tabela | SIM |
| 2 | "01","02"... | "" (vazio) | SIM (1 por coluna) |
| 4 | "01","02"... | Nome do campo | SIM (1 por coluna) |
| 5 | "01" | "Alias->CAMPO" | SIM (retorno) |
| 6 | "01" | "@CAMPO = 'valor'" | Opcional (filtro SQL) |

### O que NÃO funciona (já testado)

| Tentativa | Motivo |
|-----------|--------|
| ❌ `DbSetFilter` no alias | FWLookup monta SQL própria, ignora filtro de workarea |
| ❌ `XB_WCONTEM` | Campo não existe no SXB padrão |
| ❌ SXB Tipo 9 | Não é tipo de filtro (é "Fonte de direitos") |
| ❌ SXB Tipo 1 = "PROG" + função que retorna alias | FWLookup ainda chama BUILDBROWSE internamente (build 7.00.240223P) |

### Tabela de Tipos SXB (Referência TDN oficial)

| Tipo | Finalidade | Quantidade |
|------|-----------|------------|
| 1 | Definição da tabela/alias | 1 |
| 2 | Índices / colunas do browse | Vários |
| 3 | Permissão de incluir via consulta | Opcional |
| 4 | Campos a exibir por índice | Vários |
| 5 | Campo(s) de retorno | 1+ |
| **6** | **Filtro (AdvPL ou SQL com prefixo @)** | **1** |
| 7 | Limite superior/inferior | Opcional |
| 8 | Consulta analítica | Opcional |
| 9 | Fonte responsável pela tabela | Opcional |

---

## Points of Entry (PE) — Tabela de Contextos

| PE | Quando dispara | Uso principal |
|----|---------------|---------------|
| `MTA020` | Inicialização do MATA020 (browse) | Abrir alias, limpar filtros |
| `MT020ATE` | Ativação do browse MATA020 | Filtro adicional SA2 |
| `MT020INC` | Após incluir fornecedor | Atualizar status ZZ4 |
| `MT20FOPOS` | Após gravar (incluir/alterar) | Pós-processamento |
| `M020EXC` | Durante exclusão | Reverter status |

### Regras obrigatórias para PEs

```advpl
User Function MTA020()
    Local aArea := GetArea()
    // ... lógica ...
    RestArea(aArea)
Return
```

- Sempre usar `GetArea()`/`RestArea()`
- Nome máximo de 10 caracteres
- Sempre retornar `.T.` em PEs que não devem bloquear a rotina

---

## Diagnóstico em Produção

### Template de User Function DIAG

```advpl
User Function DIAGXXX()
    Local aArea := GetArea()
    Local cSql  := ""
    Local cAlias := GetNextAlias()

    // SQL direto para verificar estado real
    BeginSql Alias cAlias
        SELECT * FROM %Table:ZZ4% WHERE %NotDel%
    EndSql

    // Exibir resultado
    DbSelectArea(cAlias)
    While !(cAlias)->(Eof())
        ConOut(AllTrim((cAlias)->ZZ4_ID) + " - " + AllTrim((cAlias)->ZZ4_STATUS))
        (cAlias)->(DbSkip())
    EndDo
    DbCloseArea()

    RestArea(aArea)
Return
```

### Checklist de verificação rápida

```text
1. Select("ALIAS") > 0? → alias está aberto?
2. DbSeek funciona?     → índice correto?
3. SXB existe?          → DbSeek("ALIAS"+"1"+"01")?
4. SX3 X3_F3 correto?   → aponta para o alias correto?
5. Função X3_VALID/X3_INIBRW existe? → U_FFXX() compilada?
```

---

## Segurança e Boas Práticas

| Regra | Descrição |
|-------|-----------|
| `GetArea()`/`RestArea()` | Toda função que acessa alias deve preservar contexto |
| `Select(cAlias) > 0` | Validar alias antes de usar |
| `User Function` ≤ 10 chars | Limite do Protheus |
| `PCount()` para parâmetros opcionais | Validar antes de usar parâmetros |
| SXB nunca via `DbSetFilter` | Não funciona no FWLookup |
| SXB Tipo 6 com `@` prefix | Única forma de filtro SQL que funciona |
| `RecLock` + `MsUnlock` sempre | Nunca esquecer de destravar |
| `DbCommit()` após alterações | Garantir persistência |

---

## Workflow para problemas novos

```
1. IDENTIFICAR o erro (mensagem, stack trace, comportamento)
2. CONSULTAR skills (context-map, data-dictionary-lookup, code-review)
3. PESQUISAR TDN oficial (tdn.totvs.com) para documentação padrão
4. CRIAR DIAG function para verificar estado real (SQL + ConOut)
5. APLICAR solução documentada neste guia
6. REGISTRAR novo padrão se não existir
```
