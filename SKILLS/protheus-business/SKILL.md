---
name: protheus-business
description: Use when consulting Protheus ERP business processes, module workflows, routines, integrations, or understanding how business operations work in TOTVS Protheus
---

# Protheus Business Processes

## Overview

Reference guide for TOTVS Protheus ERP business processes. Provides understanding of how each module works, its routines, tables, business rules, and how modules integrate with each other.

## When to Use

- Understanding business processes within a Protheus module
- Looking up module functions, routines, and workflows
- Finding which tables and fields a process uses
- Understanding ERP integrations between modules
- Questions like "how does faturamento work?", "what tables does compras use?", "how do compras and estoque integrate?"

## Module Index

| Module | Prefix | Reference File |
|--------|--------|----------------|
| Compras | COM | modulo-compras.md |
| Estoque | EST | modulo-estoque.md |
| Faturamento | FAT | modulo-faturamento.md |
| Financeiro | FIN | modulo-financeiro.md |
| Contabilidade | CTB | modulo-contabilidade.md |
| Fiscal | FIS | modulo-fiscal.md |
| PCP | PCP | modulo-pcp.md |
| Manutencao de Ativos | MNT | modulo-manutencao.md |

## Lookup Strategy

```dot
digraph lookup {
    "Business process query?" [shape=diamond];
    "Identify module(s)" [shape=box];
    "Check module reference file" [shape=box];
    "Found?" [shape=diamond];
    "Return result" [shape=box];
    "Search TDN online" [shape=box];
    "WebSearch: site:tdn.totvs.com <term>" [shape=box];
    "Fetch failed?" [shape=diamond];
    "Playwright fallback" [shape=box];

    "Business process query?" -> "Identify module(s)";
    "Identify module(s)" -> "Check module reference file";
    "Check module reference file" -> "Found?";
    "Found?" -> "Return result" [label="yes"];
    "Found?" -> "Search TDN online" [label="no"];
    "Search TDN online" -> "WebSearch: site:tdn.totvs.com <term>";
    "WebSearch: site:tdn.totvs.com <term>" -> "Fetch failed?";
    "Fetch failed?" -> "Return result" [label="no"];
    "Fetch failed?" -> "Playwright fallback" [label="yes"];
    "Playwright fallback" -> "Return result";
}
```

1. **Identify module(s):** Determine which module(s) the query relates to using the Module Index above
2. **Local first:** Check the corresponding module reference file (e.g., modulo-compras.md)
3. **Online fallback:** Search TDN with `WebSearch` using query: `site:tdn.totvs.com <module> <process> protheus`
4. **WebFetch TDN page:** If URL found, use `WebFetch` to extract details
5. **Playwright fallback:** Se `WebSearch` ou `WebFetch` falhar, use Playwright MCP:
   - `browser_navigate` para a URL do TDN (se disponivel) ou buscar em `https://tdn.totvs.com`
   - `browser_snapshot` para extrair texto; se insuficiente, `browser_take_screenshot` para captura visual
   - `browser_close` ao finalizar para liberar recursos

## Response Format

Adaptive based on query type:

| Query Type | Response Structure |
|------------|-------------------|
| Process | Description -> Routines -> Tables/Fields -> Step-by-step flow -> Integrations -> Entry points |
| Routine | What it does -> Tables it moves -> Parameters -> Process it belongs to |
| Module | Overview -> Main tables -> Main routines -> Key processes -> Integrations |
| Integration | Flow between modules -> Linking tables -> Routines involved |

## Online Search Tips

When searching TDN (TOTVS Developer Network):
- Use `WebSearch` with query: `site:tdn.totvs.com <module> <process> protheus`
- For routine docs: `site:tdn.totvs.com <routine_name> advpl protheus`
- For module integration: `site:tdn.totvs.com integracao <module_a> <module_b> protheus`
- TDN base URL: `https://tdn.totvs.com`

## Cross-References

- **protheus-reference** — for native function details (syntax, parameters, return values)
- **advpl-code-generation** — for code patterns and templates
- **embedded-sql** — for query examples using Embedded SQL
