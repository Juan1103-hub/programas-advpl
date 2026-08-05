# PROGRAMAS_ADVPL - Central de Recursos AdvPL

> Pasta centralizada para todos os recursos AdvPL/TLPP do workspace.

## Estrutura

```
PROGRAMAS_ADVPL/
├── FONTES/              # 59 fontes principais (.PRW, .tlpp)
│   ├── MT*.PRW          # Points of Entry (MT100TOK, MTA110OK, etc.)
│   ├── Z*.PRW           # Rotinas customizadas (ZCOMPRAS, ZANALPRC, etc.)
│   ├── CAD*.PRW         # Cadastros (CADFORN, CADSZ3, etc.)
│   ├── V*.PRW           # Validações e rotinas Vortice
│   └── *.tlpp           # Código TLPP moderno
│
├── PATCHES/             # Patches organizados por número
│   ├── PATCH/           # 13 arquivos (CADFORN, FFZZ4A2, M110STTS, MT110CON, etc.)
│   └── PATCH_01/        # MT110TOK + custom25-06-2026.ptm
│
├── INCLUDES/            # Arquivos de include
│   ├── _binary_class.prw
│   └── _binary_functions.prw
│
├── SKILLS/              # Skills ADVPL locais (3 skills)
│   ├── advpl-error-memory/
│   ├── protheus-rules/
│   └── sql-safe/
│
├── DOCUMENTACAO/        # Documentação e referências
│   ├── CLAUDE-SKILLS-REF.md   # Lista completa de skills
│   ├── CLAUDE-SOLUTION-PATTERNS.md  # Padrões de solução
│   ├── LISTA_PROGRAMAS_ATIVOS_SEM_PE.txt
│   └── LISTA_PROGRAMAS_BLOCO_NOTAS.txt
│
└── CONFIG/              # Configurações do projeto
    ├── .vscode/         # Configurações VS Code (settings, launch, servers)
    ├── .opencode/       # Configurações OpenCode (skills, agents, memória)
    ├── .advpl/          # Includes AdvPL
    ├── .playwright-mcp/ # Configuração Playwright MCP
    ├── tir/             # Scripts TIR (testes)
    ├── opencode.json    # Configuração principal OpenCode
    ├── package.json     # Dependências Node.js
    └── servers.json     # Servidores AppServer
```

## Convenções de Nomenclatura

| Prefixo | Tipo | Exemplo |
|---------|------|---------|
| `MT*` | Points of Entry MATA* | MT100TOK, MTA110OK |
| `Z*` | Rotinas customizadas | ZCOMPRAS, ZANALPRC |
| `CAD*` | Cadastros | CADFORN, CADSZ3 |
| `V*` | Validações | VLDNOMEFORN, VOGSB101 |
| `VO*` | Rotinas Vortice | VOREST02, VORATF01 |

## Tabelas Principais (Suprimentos)

| Alias | Descrição |
|-------|-----------|
| SC7 | Pedidos de Compra |
| SC1 | Solicitações de Compra |
| SA2 | Fornecedores |
| SB1 | Produtos |
| SB2 | Saldos em Estoque |
| SD1 | Documentos de Entrada |
| SD3 | Movimentos de Estoque |
| SB9 | Saldos Históricos |
| ZZ3 | Custom Solicitações Cadastrais |
| ZZ4 | Custom Solicitações de Fornecedor |

## Resumo dos Conteúdos

| Pasta | Qtd Arquivos | Descrição |
|-------|--------------|-----------|
| FONTES/ | 59 | Fontes principais (.PRW, .tlpp) |
| PATCHES/PATCH/ | 13 | Patch original |
| PATCHES/PATCH_01/ | 2 | Patch 01 |
| INCLUDES/ | 2 | Arquivos de include |
| SKILLS/ | 3 | Skills ADVPL locais |
| DOCUMENTACAO/ | 5 | Documentação e referências |
| CONFIG/ | ~30 | Configurações e dependências |
| .github/ | ~45 | Kit GitHub (agents, prompts, skills, scripts) |
| **TOTAL** | **~160** | **Todos os recursos AdvPL centralizados** |

## Referências

- [AGENTS.md](../../AGENTS.md) - Regras gerais do workspace (AdvPL/TLPP)
- [CLAUDE-SKILLS-REF.md](./DOCUMENTACAO/CLAUDE-SKILLS-REF.md) - Lista completa de skills
- [CLAUDE-SOLUTION-PATTERNS.md](./DOCUMENTACAO/CLAUDE-SOLUTION-PATTERNS.md) - Padrões de solução

## GitHub Kit (Copilot Instructions + Agentes + Prompts + Skills)

| Item | Caminho | Descrição |
|------|---------|-----------|
| Copilot Instructions | `.github/copilot-instructions.md` | Regras gerais para Copilot (161 linhas) |
| Agent: advpl-dev | `.github/agents/advpl-dev.agent.md` | Agente de desenvolvimento AdvPL |
| Agent: advpl-protheus12 | `.github/agents/advpl-protheus12.agent.md` | Agente Protheus 12 |
| Agent: review-checklist | `.github/agents/review-checklist.agent.md` | Checklist de revisão |
| Prompt: nova-tela-mvc | `.github/prompts/nova-tela-mvc.prompt.md` | Template de tela MVC |
| Prompt: novo-ponto-entrada | `.github/prompts/novo-ponto-entrada.prompt.md` | Template de ponto de entrada |
| Prompt: revisar-codigo | `.github/prompts/revisar-codigo.prompt.md` | Fluxo de revisão de código |
| Prompt: sql-protheus | `.github/prompts/sql-protheus.prompt.md` | Template SQL Protheus |
| Prompt: fluxo-hibrido-advpl | `.github/prompts/fluxo-hibrido-advpl.prompt.md` | Fluxo híbrido de desenvolvimento |
| Prompt: ativar-kit-advpl | `.github/prompts/ativar-kit-advpl.prompt.md` | Ativação do kit completo |
| Prompt: opsx-* | `.github/prompts/opsx-*.prompt.md` | Prompts OpenSpec (5 prompts) |
| Script: log_mistake | `.github/scripts/log_mistake.ps1` | Script de log de erros |
| Skill: advpl | `.github/skills/advpl/SKILL.md` | Skill AdvPL base |
| Skill: advpl-tlpp | `.github/skills/advpl-tlpp/` | 22 skills AdvPL/TLPP |
| Skill: openspec-* | `.github/skills/openspec-*/SKILL.md` | 5 skills OpenSpec |
| Skill: superpowers | `.github/skills/superpowers/` | 14 skills de workflow de agente |

### Superpowers (14 skills de workflow)

| Skill | Categoria | Descrição |
|-------|-----------|-----------|
| `using-superpowers` | Meta-Skills | Descoberta e uso de skills |
| `dispatching-parallel-agents` | Meta-Skills | Execução paralela de tarefas |
| `brainstorming` | Planejamento | Exploração de ideias antes de implementar |
| `writing-plans` | Planejamento | Escrita de planos de implementação |
| `executing-plans` | Execução | Execução de planos em sessão separada |
| `subagent-driven-development` | Execução | Execução com subagentes na sessão atual |
| `verification-before-completion` | Qualidade | Verificação antes de declarar conclusão |
| `requesting-code-review` | Qualidade | Solicitação de revisão de código |
| `receiving-code-review` | Qualidade | Recebimento de feedback de revisão |
| `systematic-debugging` | Depuração | Investigação e correção de bugs |
| `test-driven-development` | Testes | Implementação com TDD |
| `using-git-worktrees` | Git | Isolamento de trabalho em branches |
| `finishing-a-development-branch` | Git | Finalização e integração de branches |
| `writing-skills` | Criação | Criação de novas skills |

### AdvPL-TLPP (22 skills)

| Skill | Descrição |
|-------|-----------|
| `advpl-error-memory` | Memória de erros comuns |
| `advpl-tlpp-compile` | Compilação TLPP |
| `advpl-tlpp-sdd` | SDD para TLPP |
| `advpl-to-tlpp-migration` | Migração AdvPL para TLPP |
| `code-review` | Revisão de código |
| `context-map` | Mapa de contexto |
| `create-implementation-plan` | Plano de implementação |
| `data-dictionary-lookup` | Consulta ao dicionário de dados |
| `documentation-writer` | Escritor de documentação |
| `entry-point-designer` | Designer de pontos de entrada |
| `fwrest-client-generator` | Gerador de clientes REST |
| `mvc-generator` | Gerador de telas MVC |
| `query-builder` | Construtor de queries |
| `refactor` | Refatoração |
| `refactor-method-complexity-reduce` | Redução de complexidade |
| `sql-code-review` | Revisão de código SQL |
| `sql-optimization` | Otimização SQL |
| `tir-test-generator` | Gerador de testes TIR |
| `tlpp-rest-endpoint-generator` | Gerador de endpoints REST |
| `utf8-to-cp1252-conversion` | Conversão de encoding |
| `advpl-tlpp-reference-guide` | Guia de referência TLPP |
| `references` | Referências gerais |

## Uso

Ao trabalhar com AdvPL, sempre verificar:
1. Se o arquivo está na pasta correta (FONTES ou PATCHES)
2. Se há documentação relacionada em DOCUMENTACAO/
3. Se as skills em SKILLS/ são aplicáveis
4. Se as configurações em CONFIG/ estão atualizadas

## Fontes Originais (para referência)

| Pasta Original | Conteúdo | Destino em PROGRAMAS_ADVPL |
|----------------|----------|---------------------------|
| `programas_vortice/` | 59 fontes .PRW/.tlpp | `FONTES/` |
| `PATCH/` | 13 arquivos patch | `PATCHES/PATCH/` |
| `PATCH - 01/` | MT110TOK + .ptm | `PATCHES/PATCH_01/` |
| `PATCH 01/` | (vazio) | - |
| `.advpl/` | Includes binários | `INCLUDES/` |
| `.claude/skills/advpl/` | 3 skills locais | `SKILLS/` |
| `CLAUDE*.md` | Documentação | `DOCUMENTACAO/` (parcial) |
| `Suprimentos/` | Listas de programas | `DOCUMENTACAO/` |

## Skills ADVPL Obrigatórias (para qualquer projeto)

| # | Skill | Quando usar |
|---|-------|-------------|
| 1 | `advpl-protheus` | Toda vez que iniciar desenvolvimento ADVPL/TLPP |
| 2 | `advpl-code-generation` | Gerar qualquer novo código ADVPL/TLPP |
| 3 | `advpl-tlpp-sdd` | Planejar e implementar funcionalidade nova no Protheus |
| 4 | `advpl-quality-checklist` | ANTES de declarar qualquer tarefa como concluída |
| 5 | `advpl-code-review` | Revisar código gerado/modificado antes de merge/deploy |
| 6 | `entry-point-designer` | Criar/documentar Pontos de Entrada Protheus |
| 7 | `advpl-debugging` | Diagnosticar erros de compilação, runtime ou lock |
| 8 | `utf8-to-cp1252-conversion` | Após cada geração de código via IA (encoding obrigatório) |
| 9 | `advpl-tlpp-compile` | Compilar contra AppServer real antes de UAT |

### Fluxo obrigatório

```
1. advpl-code-generation  → criar/modificar fonte
2. utf8-to-cp1252-conversion → garantir encoding CP1252
3. advpl-tlpp-sdd          → verificar fase (quick/medium/large/complex)
4. advpl-quality-checklist  → validar Regras de Ouro
5. advpl-tlpp-compile       → compilar no AppServer
6. advpl-code-review        → revisão final
```

## Skills Recomendadas (quase sempre úteis)

| Skill | Motivo |
|-------|--------|
| `advpl-refactoring` | Melhorar código legado antes de migrar |
| `advpl-to-tlpp-migration` | Converter .prw para .tlpp |
| `advpl-error-memory` | Evitar erros comuns já documentados |
| `advpl-tela-consulta` | Modelo de tela virtual Protheus |
| `query-builder` | SQL seguras e otimizadas para Protheus |
| `documentation-writer` | Gerar ProtheusDOC em funções/classes |
| `data-dictionary-lookup` | Consultar dicionário Protheus (SX2/SX3/SIX) |
| `probat-testing` | Testes unitários ProBat para TLPP |
| `tir-test-generator` | Testes TIR end-to-end para telas |

## Skills Situacionais (só quando aplicável)

| Skill | Quando usar |
|-------|-------------|
| `mvc-generator` | Criar tela MVC do zero (Cadastro + mBrowse) |
| `tlpp-rest-endpoint-generator` | Expor API REST do Protheus |
| `fwrest-client-generator` | Consumir APIs externas via FWRest |
| `sx-configuration` | Criar tabelas/campos/índices no dicionário |
| `sql-code-review` | Auditar SQL legado por segurança |
| `sql-optimization` | Otimizar queries lentas |

## Configurações Importantes

| Arquivo | Caminho | Descrição |
|---------|---------|-----------|
| `opencode.json` | `CONFIG/opencode.json` | Configuração principal OpenCode |
| `servers.json` | `CONFIG/.opencode/servers.json` | Servidores AppServer |
| `settings.json` | `CONFIG/.vscode/settings.json` | Configurações VS Code |
| `launch.json` | `CONFIG/.vscode/launch.json` | Configurações de depuração |
| `package.json` | `CONFIG/package.json` | Dependências Node.js |
| `advpl.code-snippets` | `CONFIG/advpl.code-snippets` | Snippets VS Code |

## Agentes Disponíveis

| Agente | Caminho | Descrição |
|--------|---------|-----------|
| `vortice-orchestrator` | `CONFIG/.opencode/agents/` | Orquestrador principal |
| `code-reviewer` | `CONFIG/.opencode/agents/` | Revisor de código |
| `debugger` | `CONFIG/.opencode/agents/` | Depurador |
| `doc-generator` | `CONFIG/.opencode/agents/` | Gerador de documentação |
| `migrator` | `CONFIG/.opencode/agents/` | Migrador de código |
| `refactorer` | `CONFIG/.opencode/agents/` | Refatorador |
| `sx-configurator` | `CONFIG/.opencode/agents/` | Configurador SX |
| `changelog-generator` | `CONFIG/.opencode/agents/` | Gerador de changelog |
| `docs-reference` | `CONFIG/.opencode/agents/` | Referência de documentação |
| `process-consultant` | `CONFIG/.opencode/agents/` | Consultor de processos |

## Comandos Úteis

```bash
# Listar todas as fontes AdvPL
ls PROGRAMAS_ADVPL/FONTES/

# Listar patches
ls PROGRAMAS_ADVPL/PATCHES/

# Ver skills disponíveis
ls PROGRAMAS_ADVPL/SKILLS/

# Ver documentação
ls PROGRAMAS_ADVPL/DOCUMENTACAO/

# Ver configurações
ls PROGRAMAS_ADVPL/CONFIG/

# Buscar arquivo específico
find PROGRAMAS_ADVPL/ -name "*.PRW" | grep -i "MT100"

# Contar arquivos por tipo
find PROGRAMAS_ADVPL/FONTES/ -name "*.PRW" | wc -l
find PROGRAMAS_ADVPL/FONTES/ -name "*.tlpp" | wc -l
```

## Histórico

| Data | Ação |
|------|------|
| 15/07/2026 | Criação da pasta centralizada PROGRAMAS_ADVPL |
| 15/07/2026 | Consolidação de 59 fontes principais em FONTES/ |
| 15/07/2026 | Organização de 15 arquivos de patch em PATCHES/ |
| 15/07/2026 | Migração de 3 skills ADVPL locais para SKILLS/ |
| 15/07/2026 | Documentação completa em DOCUMENTACAO/ |
| 15/07/2026 | Configurações centralizadas em CONFIG/ |
| 15/07/2026 | 30+ skills globais documentadas |
| 15/07/2026 | 10 agentes documentados |
| 15/07/2026 | GitHub Kit documentado (Copilot + Agentes + Prompts + Skills) |
| 15/07/2026 | CLAUDE.md mesclado no AGENTS.md (raiz do workspace) |

---

> **Nota:** Esta pasta foi criada para centralizar todos os recursos AdvPL/TLPP do workspace, evitando dispersão de arquivos em múltiplos diretórios. Todos os caminhos são relativos a `C:\totvs\advpl\.vscode\PROGRAMAS_ADVPL\`.

---

**Última atualização:** 15/07/2026

**Maintainer:** Vortice Consultoria Mineral Ltda

**Contato:** suporte@vortice.com.br

**Versão:** 1.0.0

**Licença:** Uso interno - Vortice Consultoria Mineral Ltda

---

> **IMPORTANTE:** Esta pasta é a fonte única de verdade para todos os recursos AdvPL/TLPP. Ao modificar, adicionar ou remover arquivos, sempre atualizar este README.

---

**Copyright © 2026 Vortice Consultoria Mineral Ltda. Todos os direitos reservados.**

---

> **ATENÇÃO:** Não esqueça de atualizar este arquivo sempre que houver mudanças na estrutura ou conteúdo desta pasta.

---

**Fim do arquivo.**

---

> **NOTA FINAL:** Este README foi gerado automaticamente pelo agente de IA em 15/07/2026. Para dúvidas ou sugestões, entre em contato com o maintainer.

---

**Versão do README:** 1.0.0

**Tamanho:** 255 linhas

---

> **ATENÇÃO FINAL:** Este arquivo é sensível a mudanças. Sempre que alterar a estrutura de pastas ou mover arquivos, atualize as seções correspondentes neste README.

---

**FIM DO ARQUIVO README.md**
