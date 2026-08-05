---
name: documentation-patterns
description: Use when generating technical documentation for ADVPL/TLPP code - Protheus.doc headers, routine docs, API docs
---

# Documentation Patterns

## Overview

Patterns and templates for generating technical documentation from ADVPL/TLPP source code on TOTVS Protheus.

## When to Use

- Generating Protheus.doc headers for functions/classes
- Creating routine documentation (tables, parameters, entry points, flow)
- Documenting REST API endpoints
- Adding documentation to undocumented legacy code

## Documentation Types

### Type: header — Protheus.doc Header

Standard documentation header following TOTVS conventions:

```advpl
/*/{Protheus.doc} NomeFuncao
Descricao breve do que a funcao faz.

@type        User Function | Static Function | Method
@author      Nome do autor
@since       DD/MM/YYYY
@version     1.0

@param       cParam1, Character, Descricao do parametro 1
@param       nParam2, Numeric, Descricao do parametro 2

@return      Tipo, Descricao do retorno

@example
    cResult := NomeFuncao("ABC", 123)

@see         FuncaoRelacionada1, FuncaoRelacionada2

@obs         Observacoes adicionais

@history     DD/MM/YYYY, Autor, Descricao da alteracao
/*/
```

Fields:
- **@type**: User Function, Static Function, Method, Main Function
- **@author**: Extracted from git blame or user input
- **@since**: Date of creation (from git log or current date)
- **@param**: One line per parameter with name, type, description
- **@return**: Return type and description
- **@example**: Usage example
- **@see**: Related functions (detected from function calls in code)
- **@history**: Change history (from git log if available)

### Type: full — Complete Routine Documentation

```markdown
# NomeDaRotina

## Objetivo
[O que essa rotina faz em 1-2 frases]

## Tipo
[User Function | Static Function | Class Method | Job | Entry Point]

## Modulo
[COM | FAT | FIN | EST | CTB | FIS | PCP | MNT]

## Tabelas

### Leitura
| Alias | Descricao | Campos usados |
|-------|-----------|---------------|
| SA1 | Clientes | A1_COD, A1_NOME, A1_CGC |

### Gravacao
| Alias | Descricao | Campos gravados |
|-------|-----------|-----------------|
| SC5 | Pedidos de venda | C5_NUM, C5_EMISSAO, C5_VALOR |

## Parametros MV_*
| Parametro | Descricao | Impacto |
|-----------|-----------|---------|
| MV_ESTADO | UF padrao | Define UF quando nao informada |

## Pontos de Entrada
| Nome | Momento | O que permite |
|------|---------|---------------|
| MT100LOK | Apos validacao do modelo | Validacao customizada |

## Fluxo de Execucao
1. Valida parametros de entrada
2. Posiciona na tabela SA1
3. Calcula valores
4. Grava na SC5
5. Retorna resultado

## Dependencias
| Funcao | Arquivo | Tipo |
|--------|---------|------|
| fCalcImposto | MATA461.prw | Static Function |

## Historico de Alteracoes
| Data | Autor | Descricao |
|------|-------|-----------|
| 01/01/2026 | Thalys Augusto | Criacao |
```

### Type: api — REST API Documentation

````markdown
# API: NomeDoEndpoint

## Endpoint
`METHOD /api/v1/recurso`

## Autenticacao
Bearer Token (Authorization header)

## Parametros

### Path Parameters
| Nome | Tipo | Obrigatorio | Descricao |
|------|------|-------------|-----------|

### Query Parameters
| Nome | Tipo | Obrigatorio | Descricao |
|------|------|-------------|-----------|

### Request Body
```json
{
    "campo1": "string",
    "campo2": 0
}
```

## Response

### 200 OK
```json
{
    "success": true,
    "data": {}
}
```

### 400 Bad Request
```json
{
    "success": false,
    "error": "descricao do erro"
}
```
````

## Process

1. Read the target file completely
2. Identify all functions/methods and their signatures
3. Analyze variable types from declarations and usage
4. Detect tables accessed (DBSelectArea, RecLock, BeginSQL, %table:%)
5. Detect MV_* parameters (GetMV, SuperGetMV)
6. Detect entry points (if the code IS an entry point, or calls them)
7. Map function call dependencies (Grep for function names)
8. Check git log for history if available
9. Generate documentation following the requested type template
