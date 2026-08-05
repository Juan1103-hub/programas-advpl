# Referência Rápida: Skills AdvPL/TLPP (TOTVS)

> Fonte: https://github.com/totvs/engpro-advpl-tlpp-skills/tree/main/skills/advpl-tlpp
> Salvo em: 15/06/2026

---

## 20 Skills Disponíveis

### Geração de Código

| Skill | Quando Usar |
|-------|-------------|
| `mvc-generator` | Criar tela CRUD MVC (ModelDef, ViewDef, MenuDef, BrowseDef) — Modelo 1 e Modelo 3 |
| `tlpp-rest-endpoint-generator` | Criar endpoint REST com anotações @Get/@Post/@Put/@Patch/@Delete + oRest |
| `fwrest-client-generator` | Consumir API REST externa com FWRest (GET/POST/PUT/DELETE, auth, JSON) |
| `entry-point-designer` | Criar/customizar Ponto de Entrada (User Function, PARAMIXB, retorno) |
| `query-builder` | Montar SQL otimizado para tabelas Protheus (filtros obrigatórios, índices, SQL injection) |

### Migração e Modernização

| Skill | Quando Usar |
|-------|-------------|
| `advpl-to-tlpp-migration` | Migrar .prw para .tlpp (não .prx), namespaces, Try-Catch, REST, JSON inline |

### Qualidade de Código e Revisão

| Skill | Quando Usar |
|-------|-------------|
| `code-review` | Revisão completa: 8 categorias (Segurança, Performance, Legado, Metadados, Doc, Clean Code, TLPP, Compilação) |
| `sql-code-review` | Revisão focada em SQL: injection, acesso, anti-patterns, performance |
| `refactor` | Refatoração cirúrgica: 15 code smells (métodos longos, duplicação, condicionais aninhados) |
| `refactor-method-complexity-reduce` | Reduzir complexidade cognitiva de um método específico |
| `sql-optimization` | Otimizar SQL: tuning, índices, paginação, plano de execução |
| `utf8-to-cp1252-conversion` | Converter .prw de UTF-8 para CP1252 (obrigatório para compilador Protheus) |

### Testes

| Skill | Quando Usar |
|-------|-------------|
| `tir-test-generator` | Gerar scripts TIR (Python) para testes end-to-end de telas Protheus |

### Documentação e Planejamento

| Skill | Quando Usar |
|-------|-------------|
| `documentation-writer` | Gerar ProtheusDOC (/*/{Protheus.doc} */) com todas as tags |
| `data-dictionary-lookup` | Consultar dicionário: SX2, SX3, SIX, SX6, SX5, SX7, SX1, SX9, SXB, SXG/SXA |
| `context-map` | Mapear arquivos afetados, dependências, testes e padrões antes de implementar |
| `create-implementation-plan` | Criar plano de implementação faseado com tarefas atômicas |
| `advpl-tlpp-sdd` | Spec-Driven Development: Specify → Design → Tasks → Execute (4 fases) |

---

## Referência Rápida: Qual Skill Usar?

```
Eu quero...                              → Usar esta skill
─────────────────────────────────────────────────────────────
Criar tela CRUD MVC                      → mvc-generator
Criar API REST                           → tlpp-rest-endpoint-generator
Consumir API REST                        → fwrest-client-generator
Customizar Ponto de Entrada              → entry-point-designer
Escrever SQL Protheus                    → query-builder
Migrar .prw → .tlpp                      → advpl-to-tlpp-migration
Revisar qualidade de código              → code-review
Revisar SQL                              → sql-code-review
Melhorar estrutura de código             → refactor
Reduzir complexidade de método           → refactor-method-complexity-reduce
Otimizar performance SQL                 → sql-optimization
Criar testes UI/E2E                      → tir-test-generator
Documentar com ProtheusDOC               → documentation-writer
Consultar dicionário de dados            → data-dictionary-lookup
Mapear arquivos antes de mudar           → context-map
Planejar implementação                   → create-implementation-plan
Projeto/feature com SDD                  → advpl-tlpp-sdd
Converter encoding para CP1252           → utf8-to-cp1252-conversion
```

---

## Referências por Skill (detalhadas)

### code-review
- `references/code-quality-patterns.md` — Performance, legado, metadados, compilação
- `references/documentation-and-conventions.md` — ProtheusDOC, Clean Code, TLPP
- `references/security-review-patterns.md` — SQL injection, vulnerabilidades (G1)
- `references/sonarqube-rules-reference.md` — Regras SonarQube completas (G1-G5)

### data-dictionary-lookup
- `references/column-reference.md` — Colunas SX2, SX3, SIX, SX6, SX5, SX7, SX1, SX9, SXB
- `references/sql-queries.md` — Consultas SQL para 9 tabelas do dicionário

### query-builder
- `references/cross-database-compatibility.md` — Compatibilidade PostgreSQL/MSSQL/Oracle
- `references/query-patterns-and-examples.md` — Padrões e exemplos de consultas

### entry-point-designer
- Assinaturas USER FUNCTION, layouts PARAMIXB, valores de retorno

### mvc-generator
- `references/mvc-api-reference.md` — API MVC (FWFormStruct, View, MenuDef)
- `references/mvc-code-templates.md` — Templates Modelo 1 e Modelo 3

### refactor
- `references/code-smells-and-patterns.md` — 15 code smells + 4 design patterns

### advpl-tlpp-sdd
- `references/specify.md`, `discuss.md`, `design.md`, `tasks.md` — Fases do pipeline
- `references/implement.md`, `validate.md`, `quick-mode.md` — Execução
- `references/state-management.md`, `session-handoff.md` — Gestão entre sessões

### fwrest-client-generator
- `references/fwrest-api-reference.md` — API da classe FWRest
- `references/fwrest-authentication-patterns.md` — Auth (Basic, Bearer, OAuth)
- `references/fwrest-client-templates.md` — Templates GET/POST/PUT/DELETE

### tlpp-rest-endpoint-generator
- `references/ttalk-standards-and-configuration.md` — Padrões TOTVS TTALK
- `references/tlpp-rest-endpoint-templates.md` — Templates CRUD endpoints

### tir-test-generator
- `references/tir-setup-and-best-practices.md` — Setup TIR
- `references/tir-webapp-methods-reference.md` — Métodos tir.Webapp

### sql-code-review
- `references/sql-security-patterns.md` — Segurança SQL
- `references/sql-performance-and-quality-patterns.md` — Performance SQL
- `references/database-specific-best-practices.md` — Boas práticas por banco

### sql-optimization
- `references/sql-optimization.md` — Otimização Protheus
- `references/sql-optimization-patterns.md` — Padrões de otimização
