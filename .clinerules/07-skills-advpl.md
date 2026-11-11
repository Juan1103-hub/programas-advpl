---
paths:
  - "FONTES/**"
  - "**/*.prw"
  - "**/*.tlpp"
  - "CONFIG/tir/**"
---

# 07 - Skills ADVPL (roteamento obrigatorio)

> **Restricao**: usar SOMENTE `skills/advpl-tlpp`, `skills/superpowers`, `skills/vortice`
> (+ `skills/unlazy` por leitura direta de `skills/unlazy/SKILL.md`).
> Nunca assumir skill sem localiza-la em `skills/`. Catalogo com descricao de todas: `skills/README.md` (65 skills); versao maquina: `skills/skills-registry.json`.

## Tarefa -> skill

| Tarefa | Skill | Pasta |
|---|---|---|
| Spec/planejar feature | `advpl-tlpp-sdd` (SPECIFY->DESIGN->TASKS->EXECUTE) | advpl-tlpp |
| Mapear arquivos afetados | `context-map` | advpl-tlpp |
| Plano de implementacao | `create-implementation-plan` | advpl-tlpp |
| Criar PE | `entry-point-designer` | advpl-tlpp |
| Gerar MVC | `mvc-generator` | advpl-tlpp |
| REST TLPP / cliente FWRest | `tlpp-rest-endpoint-generator` / `fwrest-client-generator` | advpl-tlpp |
| SQL seguro / otimizar | `query-builder` / `sql-optimization` / `sql-safe` / `embedded-sql` | advpl-tlpp / vortice |
| Revisar codigo/SQL | `code-review` / `advpl-code-review` / `sql-code-review` / `advpl-quality-checklist` | advpl-tlpp / vortice |
| Converter encoding | `utf8-to-cp1252-conversion` | advpl-tlpp |
| Compilar | `advpl-tlpp-compile` | advpl-tlpp |
| Migrar PRW->TLPP | `advpl-to-tlpp-migration` | advpl-tlpp |
| Testes TIR / ProBat | `tir-test-generator` / `probat-testing` | advpl-tlpp / vortice |
| Doc ProtheusDOC | `documentation-writer` | advpl-tlpp |
| Regras/tabelas/PEs Vortice | `vortice-workflow`, `protheus-rules`, `tabelas-protheus`, `pontos-entrada` | vortice |
| Padrao do fonte (header, layout, SQL, PE, tela) | `advpl-padrao-fonte` (auditar com `scripts/auditar_padrao.py --estrito`) | vortice |
| Tela modal MSDIALOG (moldura/corte e valores pos-ACTIVATE) | `advpl-msdialog-dimensionamento`, `advpl-msdialog-ciclo-de-vida` (scripts em `scripts/`) | vortice |
| SX3/SXB/F3 | `sx-configuration`, `data-dictionary-lookup` | vortice / advpl-tlpp |
| Workaround FWBrowse build atual | `advpl-fwbrowse-fwbldfeature-bug` | vortice |
| Debugar | `advpl-debugging`, `advpl-error-memory`, `systematic-debugging` | vortice / superpowers |
| Evidencia antes de declarar pronto | `verification-before-completion`, `verification-evidence` | superpowers / vortice |

## Fluxo pos-geracao obrigatorio

1. Gerar (UTF-8) -> 2. `utf8-to-cp1252-conversion` -> 3. `advpl-tlpp-compile` (perguntar antes do Gate)
   -> 4. review (`advpl-code-review`/`code-review`) -> 5. gap analysis antes de concluir.
