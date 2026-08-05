---
name: superpowers
description: Wrapper agregador das 15 skills globais do profile do usuario (using-superpowers, brainstorming, TDD, debugging, etc). Use quando precisar rotear entre multiplas skills de comportamento/fluxo antes de agir. NAO duplica conteudo - apenas referencia e roteia.
---

# Superpowers — Agregador de Skills Globais

> Wrapper local do conjunto de skills instaladas em `C:\Users\VCM37\.config\opencode\skills\`.
> Este arquivo **NAO duplica** o conteudo das skills individuais — apenas roteia para elas.
> Carregue a skill especifica via `skill("<nome>")` quando o roteamento abaixo indicar.

## Origem

- **Local de origem**: `C:\Users\VCM37\.config\opencode\skills\<nome>\SKILL.md`
- **Discovery automatica**: OpenCode ja carrega essas skills por padrao. Esta pasta existe para:
  1. Tornar a suite visivel dentro do workspace Vortice
  2. Servir como indice rapido de roteamento
  3. Permitir documentacao especifica do uso no contexto Vortice

## Indice das 15 Skills

### Meta / Fluxo de Trabalho

| Skill | Quando usar |
|-------|-------------|
| `using-superpowers` | **SEMPRE** no inicio de qualquer conversa. Define o contrato de uso. |
| `brainstorming` | Antes de qualquer trabalho criativo (feature, componente, modificacao). Explora intencao. |
| `writing-plans` | Quando tem spec/requisitos para tarefa multi-step, antes de tocar em codigo. |
| `executing-plans` | Quando tem plano escrito para executar em sessao separada com checkpoints. |
| `subagent-driven-development` | Quando tem plano para executar com tarefas independentes na sessao atual. |
| `dispatching-parallel-agents` | Quando tem 2+ tarefas independentes sem dependencia sequencial. |
| `finishing-a-development-branch` | Quando implementacao esta completa e precisa decidir merge/PR/cleanup. |

### Qualidade / Verificacao

| Skill | Quando usar |
|-------|-------------|
| `verification-before-completion` | Antes de afirmar que trabalho esta completo/correto. Evidencias antes de asserts. |
| `test-driven-development` | Antes de implementar feature ou bugfix. TDD primeiro. |
| `requesting-code-review` | Ao completar tarefas, features maiores ou antes de merge. |
| `receiving-code-review` | Ao receber feedback de code review — rigor tecnico, nao concordancia automatica. |
| `systematic-debugging` | Ao encontrar bug, falha de teste ou comportamento inesperado. |
| `refactor` | Refatoracao cirurgica para melhorar manutenibilidade sem mudar comportamento. |

### Conhecimento / Estrutura

| Skill | Quando usar |
|-------|-------------|
| `using-git-worktrees` | Ao iniciar trabalho que precisa de isolamento do workspace atual. |
| `graphify` | Para qualquer pergunta sobre codebase — especialmente quando `graphify-out/` existe. |
| `writing-skills` | Ao criar/editar skills ou verificar que funcionam antes do deploy. |

## Roteamento Rapido por Intencao

| Voce quer... | Carregue |
|--------------|----------|
| Comecar uma conversa corretamente | `using-superpowers` |
| Pensar antes de construir | `brainstorming` |
| Planejar feature multi-step | `writing-plans` |
| Executar plano em outra sessao | `executing-plans` |
| Dividir trabalho em subagentes | `subagent-driven-development` ou `dispatching-parallel-agents` |
| Garantir qualidade | `verification-before-completion` + `requesting-code-review` |
| Corrigir bug | `systematic-debugging` (+ `advpl-debugging` no Vortice) |
| Refatorar | `refactor` (+ `advpl-refactoring` no Vortice) |
| Isolar trabalho | `using-git-worktrees` |
| Entender codebase | `graphify` |
| Criar/ajustar skill | `writing-skills` |
| Finalizar feature | `finishing-a-development-branch` |
| Receber review | `receiving-code-review` |

## Convencao no Contexto Vortice

- **Skills globais (superpowers)**: comportamento, fluxo, qualidade — agem transversalmente.
- **Skills Vortice (`.opencode/skills/`)**: dominio tecnico AdvPL/Protheus — agem sobre o codigo.
- **Compor**: em uma tarefa de codigo Vortice, carregue AMBAS as dimensoes.
  Exemplo: implementar PE → `brainstorming` (intencao) + `entry-point-designer` (dominio) + `verification-before-completion` (gate) + `advpl-quality-checklist` (gate Vortice).

## Manutencao

- Adicionar skill nova no profile: `~/.config/opencode/skills/<nome>/SKILL.md` + atualizar tabela acima.
- Conflito de nome: o OpenCode prioriza a primeira skill encontrada. Em caso de duplicacao, este wrapper **perde** para a skill real do profile (correto — wrapper NAO substitui).
- Drift de versao: se uma skill do profile for editada, **NAO** precisa replicar aqui — o indice ja referencia o local de origem.
