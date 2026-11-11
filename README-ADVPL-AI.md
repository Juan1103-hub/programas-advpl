# Guia Diário — IA Free para AdvPL/TLPP (Vortice)

## Setup Feito
```
.opencode/
├── system-prompt-advpl.md      # System prompt para freebuff/opencode
├── settings.json               # Hooks: auto compile + review + encoding
├── command/                    # Slash commands SDD
│   ├── specify.md
│   ├── map.md
│   ├── quick-fix.md
│   ├── compile.md
│   ├── review.md
│   ├── design.md
│   ├── tasks.md
│   └── execute.md
└── memory/                     # Knowledge base local
    ├── MEMORY.md               # Índice
    ├── TEMPLATE-BUG.md
    ├── TEMPLATE-PADRAO.md
    ├── bugs/
    ├── padroes/
    ├── tabelas/
    ├── regras/
    ├── mvc/
    ├── sx3/
    ├── custom/
    ├── pes/
    └── projeto/
```

---

## Como Usar no freebuff

### 1. **Carregue o system prompt**
No freebuff, cole o conteúdo de `.opencode/system-prompt-advpl.md` como **system prompt** do modelo.

### 2. **Referencie arquivos com code citing**
```
"Veja 12:45:FONTES/MTA110OK.PRW"
```
Não cole código — cite localização. A IA lê só o trecho.

### 3. **Use memory para contexto**
```
"Consulte memory bug-c7-quant-negativo"
"Crie memory para o fix de hoje usando TEMPLATE-BUG.md"
```

---

## Fluxo Diário (5 minutos setup → coding assertivo)

### Manhã — Contexto
```bash
# No opencode terminal:
/map "MTA110"           # Vê todos PEs MATA110
/map "FWRest"           # Acha integrações REST
memory bug-c7-quant-negativo  # Contexto de bug conhecido
```

### Durante — Coding
```bash
# Edita arquivo → hooks fazem TUDO auto:
# 1. utf8-to-cp1252-conversion
# 2. advpl-tlpp-compile (AppServer CINVJ6_DEV)
# 3. advpl-code-review --level high

# Se erro compilação/review → PARA e mostra na hora

# Fix rápido (≤3 arquivos):
/quick-fix MTA110OK.PRW "CA2050 SQL injection linha 45"

# Compila manual se quiser:
/compile MTA110OK.PRW

# Review profundo:
/review MTA110OK.PRW --level high
```

### Feature Nova — SDD
```bash
# 1. Spec (obrigatório)
/specify "novo campo ZC7_DATAENT em SC7 para data entrega prevista"

# 2. Design (se >3 arquivos ou ambíguo)
/design "novo campo ZC7_DATAENT em SC7"

# 3. Tasks (breakdown)
/tasks "novo campo ZC7_DATAENT em SC7"

# 4. Execute (com validação gate a gate)
/execute wave 1      # Data layer (paralelo)
/execute wave 2      # PEs (sequencial)
/execute wave 3      # MVC/TLPP
/execute wave 4      # Testes + deploy
# OU tudo:
/execute all
```

### Fim — Gap Analysis
Ao finalizar `/execute all`, a IA **apresenta gap analysis** antes de declarar pronto:
| Item | Status | Evidência |
|------|--------|-----------|
| Regra 1 | ✅ | MTA110OK.PRW:85 |
| CT001 | ✅ | TIR test_CT001 passed |
| VerifyAccess | ⚠️ | Não replicado — documentado |

---

## Comandos Rápidos (cola no terminal)

```bash
# Busca
/map "RetSqlName"
/map "MSExecAuto.*SC7"
/map "User Function.*OK"

# Fix + validação
/quick-fix ZC7DATAENT.tlpp "encoding"
/quick-fix MTA110INC.PRW "IIF linha 33"

# Compila + review
/compile "FONTES/*.prw"
/review MTA110OK.PRW --level high

# Feature completa
/specify "validação lead time fornecedores internacionais no MTA110OK"
/design "validação lead time fornecedores internacionais"
/tasks "validação lead time fornecedores internacionais"
/execute all
```

---

## Memory — Como Alimentar

### Bug resolvido hoje
```bash
# Copie TEMPLATE-BUG.md → memory/bugs/nome-bug.md
# Preencha:
---
name: bug-sc7-frete-incorreto
description: Frete recalculado errado em devolução
type: feedback
---
**Problema:** ...
**Causa:** ...
**Fix:** FONTES/MTA110INC.PRW:45 — adicionado validação C7_TIPO='D'
**Como aplicar:** Em todo PE que calcule frete, checar C7_TIPO antes
[[mta110inc-inclusao]] [[tabelas-sc7-tomadas-centrais]]
```

### Padrão novo descoberto
```bash
# Copie TEMPLATE-PADRAO.md → memory/padroes/nome-padrao.md
# Preencha com código canônico + regras + SonarQube IDs
```

---

## freebuff + opencode — Integração

| freebuff (chat) | opencode (terminal) |
|-----------------|---------------------|
| System prompt = `.opencode/system-prompt-advpl.md` | `opencode` carrega `.opencode/settings.json` + commands + skills |
| Code citing `12:45:FONTES/MTA110OK.PRW` | `read`/`edit`/`bash` direto nos fontes |
| Memory consultada via chat | `memory/` files lidos/escritos via tools |
| Pergunta "como faz X no AdvPL?" | `/map "X"` → busca real no codebase |
| "Revisa esse código" | `/review arquivo.prw --level high` |

---

## Dicas de Ouro

1. **Sempre cite, nunca cole** — `12:45:FONTES/MTA110OK.PRW` economiza 90% tokens
2. **Hooks salvam você** — edite `.prw` → compila+review auto → erro na hora, não no deploy
3. **Memory = conhecimento persistente** — bug resolvido hoje = memory amanhã = não repete
4. **SDD para features reais** — `/specify` → `/design` → `/tasks` → `/execute` = zero "esqueci de validar X"
5. **Gap analysis é lei** — se não tem ✅ em tudo, **não está pronto**
6. **freebuff para arquitetura/decisões, opencode para execução** — use os dois juntos

---

## Troubleshooting

| Problema | Solução |
|----------|---------|
| Compila mas erro runtime | `/review --level ultra` (precisa claude.ai) ou `/map "RecLock.*SC7"` |
| Encoding lixo no RDMake | `utf8-to-cp1252-conversion` rodou? Verifique hook PostToolUse |
| IA inventa API Protheus | "Valide símbolo no codebase + skills + TDN antes de gerar" (está no system prompt) |
| Esqueci regra de negócio | `memory` + `/map` + `spec.md` gap analysis |
| PR grande, review manual chato | `/review "FONTES/*.prw" --level high` → relatório SonarQube completo |

---

## Próximos Passos (quando quiser evoluir)

1. **Migre Obsidian vault** → `.opencode/memory/` (scripts em `CONFIG/tir/`)
2. **Adicione skills custom** → `skills/advpl-tlpp/<nova-skill>/SKILL.md`
3. **TIR tests auto** → `/execute wave 4` gera `CONFIG/tir/test_CTNNN.py` via `tir-test-generator`
4. **MVC generator** → `mvc-generator` skill para ModelDef/ViewDef/BrowseDef boilerplate
5. **FWRest client** → `fwrest-client-generator` para integrações externas tipadas