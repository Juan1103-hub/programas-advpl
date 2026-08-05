---
name: advpl-error-memory
description: Use when correcting or generating ADVPL/Protheus code and needing to avoid recurring errors in scope, queries, MsExecAuto, dbSeek, arrays, or entry points.
---

# ADVPL Error Memory Guard

## Overview

Skill de memoria de erros para correcao e geracao de codigo ADVPL/Protheus. A ideia e simples: antes de propor uma solucao, verificar se o problema ja cai em um padrao conhecido e aplicar a correcao certa sem repetir o erro.

## Core Workflow

### 1. Diagnostico antes de qualquer codigo

- Identifique a mensagem, o comportamento e a linha afetada.
- Verifique se o erro existe na base de conhecimento abaixo.
- Se existir, aplique a solucao documentada.
- Se nao existir, resolva normalmente e registre o novo padrao ao final.

### 2. Anti-Pattern Checklist

- [ ] Variaveis declaradas com Local no escopo correto?
- [ ] cQuery fechado com dbCloseArea() ou FreeObj() apos uso?
- [ ] MsExecAuto() verificado com lMsHasErro() apos chamada?
- [ ] Campos acessados via FieldGet() e nao diretamente como M->CAMPO em MaFis/MaAt*?
- [ ] dbSelectArea() chamado antes de dbSeek() ou dbSkip()?
- [ ] Alias validado com Select(cAlias) > 0 antes de usar?
- [ ] SomaSld(), ExistCpo() e Posicione() chamados com todos os parametros obrigatorios?
- [ ] Strings concatenadas com + e nao com & para variaveis?
- [ ] Array inicializado com aAdd() ou Array() antes de uso indexado?
- [ ] FWMsgRun() ou ProcRegua() chamados para operacoes longas?
- [ ] User Function com nome maximo de 10 caracteres?
- [ ] lContinua ou outra flag de controle verificada em loops criticos?

## Known Error Patterns

### ERR-001 - Variavel nao declarada / Scope leak

**Sintoma:** variavel afeta outras rotinas ou retorna valor errado em chamadas aninhadas.
**Causa raiz:** variavel declarada como Private implicito em vez de Local.
**Solucao correta:**

```advpl
// ERRADO - Private implicito
cNome := "Juan"

// CORRETO - declarar explicitamente
Local cNome := "Juan"
```

**Regra:** toda variavel deve ser declarada com Local no inicio da funcao, exceto quando o escopo compartilhado for intencional.

### ERR-002 - Query sem fechamento de area / Memory leak

**Sintoma:** lentidao progressiva, erros de muitos arquivos abertos ou dados de consultas anteriores reaparecendo.
**Causa raiz:** dbUseArea() ou TCQuery() executado sem dbCloseArea().
**Solucao correta:**

```advpl
Local cAlias := GetNextAlias()

dbUseArea(.T., "TOPCONN", "SELECT * FROM " + RetSqlName("SA1"), cAlias, .T., .T.)

// ... usa os dados ...

(cAlias)->(dbCloseArea())
```

**Regra:** todo dbUseArea() precisa de dbCloseArea() correspondente.

### ERR-003 - MsExecAuto sem verificacao de erro

**Sintoma:** inclusao ou alteracao falha sem retorno visivel.
**Causa raiz:** MsExecAuto() chamado sem lMsHasErro() e sem MostraErro().
**Solucao correta:**

```advpl
Local aRet := {}
Local lOk  := .F.

MsExecAuto({|x,y| MATA010(x,y)}, aParam, aRet)

If lMsHasErro()
    MostraErro()
    lOk := .F.
Else
    lOk := .T.
EndIf
```

**Regra:** lMsHasErro() e obrigatorio apos qualquer MsExecAuto().

### ERR-004 - dbSeek sem dbSelectArea previa

**Sintoma:** dbSeek() retorna .F. mesmo com o registro existente.
**Causa raiz:** area ativa nao e a esperada.
**Solucao correta:**

```advpl
dbSelectArea("SA1")
SA1->(dbSetOrder(1))
SA1->(dbSeek(xFilial("SA1") + cCodCliente))

If SA1->(!EOF())
    // registro encontrado
EndIf
```

**Regra:** sempre usar dbSelectArea() e alias explicito antes de navegar.

### ERR-005 - Nome de User Function com mais de 10 caracteres

**Sintoma:** ponto de entrada nao e chamado ou a funcao parece nao existir.
**Causa raiz:** limite de 10 caracteres no nome.
**Solucao correta:**

```advpl
// ERRADO
User Function ValidaClienteEspecial()

// CORRETO
User Function ValCliEsp()
```

**Regra:** User Function e ponto de entrada devem ter no maximo 10 caracteres.

### ERR-006 - Concatenacao incorreta de variaveis em strings

**Sintoma:** erro de tipo ou exibicao do nome da variavel em vez do valor.
**Causa raiz:** uso de & em vez de + para concatenacao.
**Solucao correta:**

```advpl
Local cCodigo := "000001"
Local cMsg    := ""

// ERRADO
cMsg := "Codigo: " & cCodigo

// CORRETO
cMsg := "Codigo: " + cCodigo

cMsg := "Total: " + cValToChar(nTotal)
cMsg := "Data: "  + DToC(dData)
```

**Regra:** use + para concatenar e & apenas para macro expansion intencional.

### ERR-007 - Array acessado antes de inicializado

**Sintoma:** Array index out of bounds ou Type mismatch.
**Causa raiz:** array declarado como NIL e acessado por indice sem inicializacao.
**Solucao correta:**

```advpl
// ERRADO
Local aLista
aLista[1] := "item"

// CORRETO
Local aLista := {}
aAdd(aLista, "item")

// OU
Local aLista := Array(5)
```

**Regra:** arrays devem ser inicializados com {} ou Array(n) antes do primeiro acesso por indice.

### ERR-008 - Uso de M->CAMPO fora de contexto de tela

**Sintoma:** campo nao encontrado ou valor em branco em rotinas automáticas e jobs.
**Causa raiz:** M->CAMPO so existe em contexto de tela interativa.
**Solucao correta:**

```advpl
// ERRADO em rotina automatica
Local cNome := M->A1_NOME

// CORRETO
dbSelectArea("SA1")
SA1->(dbSeek(xFilial("SA1") + cCod))
Local cNome := SA1->A1_NOME

// OU via FieldGet
Local cNome := FieldGet(FieldPos("A1_NOME"))
```

**Regra:** em automacoes, leia via alias da tabela ou FieldGet().

### ERR-009 - BEGIN SEQUENCE sem RECOVER / END SEQUENCE

**Sintoma:** erro runtime derruba o processo ao inves de ser capturado.
**Causa raiz:** estrutura incompleta.
**Solucao correta:**

```advpl
BEGIN SEQUENCE
    // codigo que pode gerar erro
    If lErro
        Break
    EndIf
RECOVER
    MsgStop("Operacao interrompida.", "Atencao")
END SEQUENCE
```

**Regra:** sempre usar BEGIN SEQUENCE / RECOVER / END SEQUENCE completo em rotinas criticas.

### ERR-010 - Posicione() com parametros errados

**Sintoma:** Posicione() retorna string vazia ou dado incorreto.
**Causa raiz:** ordem de parametros ou chave de busca incorreta.
**Solucao correta:**

```advpl
// Sintaxe: Posicione(cAlias, nOrdem, cChave, cCampo)

// ERRADO
Local cNome := Posicione("SA1", 1, cCodigo, "A1_NOME")

// CORRETO
Local cNome := Posicione("SA1", 1, xFilial("SA1") + cCodigo, "A1_NOME")
```

**Regra:** a chave de busca deve incluir xFilial() quando o indice usa filial.

## How to Add New Errors

Quando um novo padrao for identificado e corrigido, adicione ao final desta skill neste formato:

- ### ERR-NNN - Titulo curto e descritivo
- **Sintoma:** O que o usuario observa.
- **Causa raiz:** Por que acontece.
- **Solucao correta:**

```advpl
// ERRADO
...
// CORRETO
...
```

- **Regra:** Resumo da regra em uma linha.

## Response Style

Ao corrigir codigo ADVPL, siga este formato:

1. Identifique o erro encontrado, referenciando ERR-XXX quando aplicavel.
2. Explique brevemente por que estava errado.
3. Forneca o codigo corrigido completo com comentarios `// ANTES:` e `// DEPOIS:` quando necessario.
4. Liste os itens do Anti-Pattern Checklist que foram verificados.
5. Se o erro for novo, adicione a descricao no final em `## Novo padrao identificado`.
