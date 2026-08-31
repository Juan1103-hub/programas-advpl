---
name: code-explanation
description: Use when explaining ADVPL/TLPP code in plain language for developers and functional consultants
---

# Code Explanation

## Overview

Methodology for explaining ADVPL/TLPP code in plain language. Adapts the explanation depth based on the audience level: junior developer, senior developer, or functional consultant.

## When to Use

- User asks to explain what a piece of code does
- User wants to understand legacy code
- Functional consultant needs to understand a customization
- Junior developer needs line-by-line explanation
- Code documentation is missing or unclear

## Explanation Levels

| Level | Audience | Depth | Focus |
|-------|----------|-------|-------|
| `junior` | Dev iniciante | Linha por linha | Sintaxe, funcoes, fluxo de execucao |
| `senior` | Dev experiente | Resumido | Logica de negocio, decisoes de design, riscos |
| `funcional` | Consultor funcional | Sem termos tecnicos | O que a rotina faz do ponto de vista do negocio |

## Explanation Structure

### For --level junior

1. **Objetivo** — O que essa rotina faz em uma frase
2. **Includes e dependencias** — O que cada include traz
3. **Variaveis** — Lista de variaveis com tipo e proposito
4. **Fluxo passo a passo** — O que cada bloco de codigo faz, na ordem
5. **Funcoes nativas usadas** — Breve explicacao de cada funcao do Protheus usada
6. **Tabelas acessadas** — Quais tabelas sao lidas/gravadas e por que
7. **Pontos de atencao** — Armadilhas, erros comuns, trechos criticos

### For --level senior

1. **Objetivo** — O que essa rotina faz em uma frase
2. **Logica de negocio** — Regras implementadas e decisoes de design
3. **Tabelas e campos** — Resumo das operacoes de banco
4. **Dependencias externas** — Funcoes chamadas, includes, pontos de entrada
5. **Riscos e debitos tecnicos** — Problemas potenciais, melhorias sugeridas

### For --level funcional

1. **O que essa rotina faz** — Em linguagem de negocio, sem codigo
2. **Quando ela e executada** — Contexto de uso (menu, schedule, trigger)
3. **Quais dados ela consulta** — Tabelas e informacoes lidas (em linguagem de negocio)
4. **Quais dados ela altera** — O que muda no sistema quando ela roda
5. **Regras de negocio** — Validacoes, calculos, condicoes
6. **Impacto em outros modulos** — Se altera dados usados por outros processos

## Process

1. Read the target file or code snippet completely
2. Determine the explanation level (--level flag or ask)
3. Load `protheus-reference` skill if native functions need lookup
4. Load `protheus-business` skill if business context is needed
5. Load `embedded-sql` skill if SQL queries are present
6. Analyze the code structure, identify functions, variables, DB operations
7. Generate explanation following the level-appropriate structure
8. Use the user's language (Portuguese or English)
