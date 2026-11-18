# PROGRAMAS_ADVPL - Central de Recursos AdvPL

> Pasta centralizada para todos os recursos AdvPL/TLPP do workspace.

## Estrutura

```
PROGRAMAS_ADVPL/
├── FONTES/              # 81 fontes (.prw e .tlpp) - fonte de verdade do código
│   ├── MT*.PRW          # Pontos de Entrada (MT100TOK, MTA110OK, etc.)
│   ├── Z*.PRW           # Rotinas customizadas (ZCOMPRAS, ZANALPRC, etc.)
│   ├── CAD*.PRW         # Cadastros (CADFORN, CADSZ3, etc.)
│   ├── V*.PRW           # Validações e rotinas Vortice
│   └── *.tlpp           # Código TLPP moderno
│
├── _PATCHES/            # Pacotes de patch já entregues (histórico)
│   ├── PATCH/           # 12 arquivos
│   ├── PATCH_01/        # 5 arquivos
│   └── PATCH_02/        # 2 arquivos
│
├── INCLUDES/            # Includes da instalação
│   └── totvs/           # 157 includes (.ch) para conferir assinaturas
│
├── skills/              # 67 skills (catálogo em skills/README.md)
│   ├── advpl-tlpp/      # 20 skills oficiais TOTVS
│   ├── superpowers/     # 14 skills de fluxo de trabalho
│   ├── vortice/         # 32 skills específicas Vortice
│   └── unlazy/          # 1 skill de disciplina de execução
│
├── docs/                # 10 arquivos de documentação
│   ├── convencoes.md    # Sintaxe e convenções
│   ├── tabelas.md       # Tabelas de Suprimentos
│   ├── fontes.md        # Índice dos fontes
│   ├── workflow.md      # SDD, LSP e memória
│   └── LISTA_PROGRAMAS_*.txt  # Listas históricas (31/05/2026)
│
└── CONFIG/              # Configurações (TDS, build e agentes)
    ├── .vscode/         # settings/launch + dumps de símbolos do TDS
    ├── .opencode/       # Configuração local do OpenCode
    ├── .advpl/          # Includes AdvPL
    ├── tir/             # Scripts TIR (testes)
    ├── agents/          # Definições de agentes
    ├── scripts/         # Build e regressão
    ├── package.json     # Dependências Node.js
    └── servers.json     # Servidores AppServer (contém token; não versionado)
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

| Pasta | Arquivos | Descrição |
|-------|----------|-----------|
| FONTES/ | 81 | 78 .PRW + 3 .tlpp |
| _PATCHES/ | 19 | 12 em PATCH, 5 em PATCH_01 e 2 em PATCH_02 |
| INCLUDES/totvs/ | 157 | Includes da instalação |
| skills/ | 67 | 20 TOTVS + 14 superpowers + 32 Vortice + 1 unlazy |
| docs/ | 10 | Documentação, listas históricas e referências |
| CONFIG/ | 40 | Configurações, scripts e agentes |
| .github/ | 2 | Instrução do TDS e workflow de CI |

## Referências

- [AGENTS.md](./AGENTS.md) - Regras gerais do workspace (AdvPL/TLPP)
- [CLAUDE-SKILLS-REF.md](./docs/CLAUDE-SKILLS-REF.md) - Lista completa de skills
- [CLAUDE-SOLUTION-PATTERNS.md](./docs/CLAUDE-SOLUTION-PATTERNS.md) - Padrões de solução

## Skills do Repositório

O catálogo completo, com descrição e roteamento por tarefa, está em
[`skills/README.md`](./skills/README.md) e em
[`skills/skills-registry.json`](./skills/skills-registry.json).

| Pasta | Skills | Conteúdo |
|-------|--------|----------|
| `skills/advpl-tlpp/` | 20 | Skills oficiais TOTVS (AdvPL/TLPP) |
| `skills/superpowers/` | 14 | Fluxo de trabalho de agentes |
| `skills/vortice/` | 32 | Skills específicas Vortice (inclui `advpl-padrao-fonte` e as de `MSDIALOG`) |
| `skills/unlazy/` | 1 | Disciplina de execução para tarefas longas |

> O registro `skills-registry.json` tem 66 entradas; `skills/unlazy/` fica fora do
> registro e deve ser lida diretamente pelo `SKILL.md`.

> O `.github/` guarda apenas a instrução do TDS
> (`.github/instructions/tds-vscode-1-0-2.instructions.md`) e o workflow de CI
> (`.github/workflows/ci.yml`).

## Uso

Ao trabalhar com AdvPL, sempre verificar:
1. Se o código ativo está em `FONTES/` e o histórico em `_PATCHES/`
2. Se há documentação relacionada em docs/
3. Se as skills em skills/ são aplicáveis
4. Se as configurações em CONFIG/ estão atualizadas

## Fontes Originais (para referência)

| Pasta Original | Conteúdo | Destino em PROGRAMAS_ADVPL |
|----------------|----------|---------------------------|
| `programas_vortice/` | 81 fontes .PRW/.tlpp | `FONTES/` |
| `PATCH/` | 12 arquivos | `_PATCHES/PATCH/` |
| `PATCH - 01/` | MT110TOK + .ptm | `_PATCHES/PATCH_01/` |
| `PATCH 01/` | (vazio) | - |
| `PATCH 02/` | 2 fontes | `_PATCHES/PATCH_02/` |
| `.advpl/` | Dumps de símbolos do TDS | `.vscode/.advpl/` e `CONFIG/.vscode/` |
| `.claude/skills/advpl/` | base das 32 skills Vortice | `skills/vortice/` |
| `CLAUDE*.md` | Documentação | `docs/` (parcial) |
| `Suprimentos/` | Listas de programas (31/05/2026) | `docs/` |

## Skills ADVPL Obrigatórias (para qualquer projeto)

> **Sempre obrigatórias (AGENTS.md):** `advpl-padrao-fonte` ao criar ou editar
> qualquer fonte; `advpl-msdialog-dimensionamento` e
> `advpl-msdialog-ciclo-de-vida` em telas `MSDIALOG`.

| # | Skill | Quando usar |
|---|-------|-------------|
| 1 | `advpl-protheus` | Toda vez que iniciar desenvolvimento ADVPL/TLPP |
| 2 | `advpl-code-generation` | Gerar qualquer novo código ADVPL/TLPP |
| 3 | `advpl-padrao-fonte` | Aplicar o molde e rodar o auditor de padrão |
| 4 | `advpl-tlpp-sdd` | Planejar e implementar funcionalidade nova no Protheus |
| 5 | `advpl-quality-checklist` | ANTES de declarar qualquer tarefa como concluída |
| 6 | `advpl-code-review` | Revisar código gerado/modificado antes de merge/deploy |
| 7 | `entry-point-designer` | Criar/documentar Pontos de Entrada Protheus |
| 8 | `advpl-debugging` | Diagnosticar erros de compilação, runtime ou lock |
| 9 | `utf8-to-cp1252-conversion` | Após cada geração de código via IA (encoding obrigatório) |
| 10 | `advpl-tlpp-compile` | Compilar contra AppServer real antes de UAT |

### Fluxo obrigatório

```
1. advpl-code-generation  → criar/modificar fonte
2. advpl-padrao-fonte      → aplicar molde e rodar o auditor
3. utf8-to-cp1252-conversion → garantir encoding CP1252
4. advpl-tlpp-sdd          → verificar fase (quick/medium/large/complex)
5. advpl-quality-checklist  → validar Regras de Ouro
6. advpl-tlpp-compile       → compilar no AppServer
7. advpl-code-review        → revisão final
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

> Estado atual (2026-08-16): a configuração principal do OpenCode não fica mais em
> `opencode.json` na raiz — foi movida/consolidada no global
> `~/.config/opencode/opencode.jsonc`.
> O `.vscode/` da raiz do projeto guarda `settings.json` e `launch.json`.

| Arquivo | Caminho | Descrição |
|---------|---------|-----------|
| Configuração OpenCode | `~/.config/opencode/opencode.jsonc` | Configuração principal OpenCode (global) |
| `opencode.json` | `.opencode/opencode.json` | Configuração do projeto (skills paths e agente `advpl`) |
| `servers.json` | `CONFIG/servers.json` | Servidores AppServer TOTVS (TDS) |
| `settings.json` | `CONFIG/settings.json` | Settings VS Code/workspace (TDS, encoding CP-1252, idioma) |
| `settings.json` | `.vscode/settings.json` | Settings locais do projeto (includes do TDS) |
| `launch.json` | `.vscode/launch.json` | Configurações de depuração |
| `package.json` | `CONFIG/package.json` | Dependências Node.js + scripts de build (`npm run build`) |
| `advpl.code-snippets` | `CONFIG/advpl.code-snippets` | Snippets VS Code |
| Skills/memória | `skills/` e `.opencode/memory/` | Catálogo ativo; o espelho antigo em `CONFIG/.opencode/skills/` foi isolado em `_backup/duplicatas_20261118/` (18/11/2026) |

## Agentes Disponíveis

| Agente | Caminho | Descrição |
|--------|---------|-----------|
| `advpl` | `.opencode/opencode.json` | Agente principal (AdvPL/TLPP), com navegador e GitHub desativados |
| `protheus-diag` | `.opencode/agents/` | Diagnóstico de bugs AdvPL/Protheus |

> Cópias antigas de quatro agentes (`changelog-generator`, `code-reviewer`,
> `docs-reference` e `process-consultant`) ficam em `CONFIG/.opencode/`, fora do
> caminho ativo. Elas não são carregadas automaticamente.

## Comandos Úteis

```bash
# Listar todas as fontes AdvPL
ls FONTES/

# Listar patches
ls _PATCHES/

# Ver skills disponíveis
ls skills/

# Ver documentação
ls docs/

# Ver configurações
ls CONFIG/

# Buscar arquivo específico
find . -name "*.PRW" | grep -i "MT100"

# Contar arquivos por tipo
find FONTES/ -name "*.PRW" | wc -l
find FONTES/ -name "*.tlpp" | wc -l
```

## Histórico

| Data | Ação |
|------|------|
| 15/07/2026 | Criação da pasta centralizada PROGRAMAS_ADVPL |
| 15/07/2026 | Consolidação inicial de 59 fontes em FONTES/ |
| 15/07/2026 | Organização dos primeiros pacotes de patch em _PATCHES/ |
| 15/07/2026 | Migração das 3 skills ADVPL iniciais para skills/vortice/ |
| 15/07/2026 | Documentação em docs/ e configurações em CONFIG/ |
| 18/11/2026 | Limpeza de node_modules, logs e __pycache__ (~105 MB) |
| 18/11/2026 | Duplicatas isoladas em _backup/duplicatas_20261118/ (nada apagado) |
| 18/11/2026 | Dumps de símbolos atualizados para a geração de 12/11/2026 |
| 18/11/2026 | MTA020.PRW alinhado ao RPO; OPENZZ4.PRW mantido (não está no RPO) |
| 18/11/2026 | README revisado: contagens, caminhos e catálogo de skills |

---

> **Nota:** Todos os caminhos deste README são relativos a esta pasta
> (`PROGRAMAS_ADVPL/`).

**Última atualização:** 18/11/2026
**Maintainer:** Vortice Consultoria Mineral Ltda
**Contato:** suporte@vortice.com.br
**Versão:** 1.1.0
**Licença:** Uso interno

> **Regra:** esta pasta é a fonte única de verdade dos recursos AdvPL/TLPP.
> Ao mover, renomear ou excluir arquivos, atualize este README e `docs/fontes.md`.

