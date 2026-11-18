# Mapa de Fontes e Estrutura do Projeto

> **Consulte este arquivo quando** precisar localizar um fonte em `FONTES/`, entender a árvore de diretórios, ou confirmar convenção de nome/case de arquivo. Não é contexto fixo — leia sob demanda.

## Project Structure (real)

```
PROGRAMAS_ADVPL/                   # raiz deste workspace
├── FONTES/              # fontes principais: MT*/MTA* (Entry Points), Z* (custom),
│                        #   CAD* (cadastros), VO*/V* (Vortice), *.tlpp (TLPP moderno), PE*
│                        #   nome arquivo = nome do PE. Ex.: MTA110OK.PRW, MT110TOK.PRW
├── INCLUDES/            # includes da instalação
│   └── totvs/           # includes .ch em texto puro (157 arquivos)
├── _PATCHES/            # PATCH/, PATCH_01/ e PATCH_02/ (histórico)
│   ├── PATCH/           # patch original
│   ├── PATCH_01/        # MT110TOK + custom25-06-2026.ptm
│   └── PATCH_02/        # FRELFLW5 + VOREST03
├── skills/              # skills lowercase — usar somente advpl-tlpp, superpowers, vortice
│   ├── advpl-tlpp/      # mirror oficial totvs/engpro-advpl-tlpp-skills
│   ├── superpowers/     # mirror oficial
│   ├── vortice/         # skills específicas Vortice
│   └── unlazy/          # NÃO registrada em skills.paths — ler SKILL.md diretamente
├── instructions/        # mirror oficial (AGENTS.md, CLAUDE.md, README.md)
├── .github/workflows/   # ci.yml oficial
├── ci/scripts/          # validation-scan.sh, security-scan.sh, build.sh (oficial)
├── skills/skills-registry.json # catálogo de skills
├── docs/        # CLAUDE-SKILLS-REF.md, CLAUDE-SOLUTION-PATTERNS.md, listas (*.txt)
├── CONFIG/              # configuração do workspace:
│   ├── servers.json     # AppServer TOTVS (conexão/compilação) — contém token; nunca imprimir
│   ├── references_sonarqube-rules-reference.md
│   ├── references_advpl-tlpp-skills-reference.md
│   ├── agents/          # advpl-dev.md (definições de agentes)
│   ├── tir/             # scripts TIR (testes python)
│   ├── .advpl/          # includes AdvPL (legado)
│   └── .opencode/       # agents OpenCode + README.md
├── docs/                # apoio de contexto (fontes, tabelas, convencoes, workflow)
├── code/                # utilitários NÃO-AdvPL (freebuff-proxy, scripts python) — ignorar em tarefas AdvPL
├── .opencode/           # settings.json (hooks/commands/memory) + opencode.json + agents/ + memory/
└── .vscode/             # settings.json, launch.json, .advpl/_binary_*.tlpp (projeto)
```

> Config OpenCode: `.opencode/opencode.json` (projeto) com `skills.paths` locais + global `~/.config/opencode/opencode.jsonc` (fallback). Ver `CONFIG/.opencode/README.md`.

## Mapa de fontes (`FONTES/` — nome do arquivo = nome do PE)

- **PEs MATA/MATA1xx (Compras)**: `MT110TOK`, `MT100OK`, `MT100TOK`, `MT101OK`, `MTA131C8`, `MTA105OK`, `MT150GET`, `MT160GRPC`, `MT460PREV`, `M020EXC`, `M185POSIC`, `MT010ALT`, `MT020ATE`, `MT20FOPOS`, `MTA020`, `MTA094RO`, `MTA185MNU`, `A010TOK`, `AVALCOT`, `MA410MNU`.
  > `MT120OK`, `MT120TFR`, `MTA110OK` e `MTA120G3` não estão em `FONTES/`: ficam em `_PATCHES/PATCH_01/`.
- **Custom Z* (Vortice)**: `ZCOMPRAS`, `ZANALPRC`, `ZANALBX`, `ZAVALNEG`, `ZLEADTIME`, `ZCTAEST`, `ZPOSITEM`, `ZSLDEST`, `ZPREVNFE`, `ZRPCPDF`, `ZRPCPED`, `ZLANCDIE`, `ZMM01`, `ZMMA01`, `ZMMA02`, `ZADTASK`, `ZCONSRE5`, `ZTESTTEL`, `ZDIAG110` (TLPP).
- **ZZ4 (solicitação ao fornecedor)**: `OPENZZ4`, `FFZZ4A2`, `ZALTZZ4SA2`, `ZCRIAZZ4SA2`, `ZFIXMODSA2`, `ZFIXSX3SA2`.
- **Cadastros/utilitários**: `CADFORN`, `CADPOSIC`, `CADSOLIC`, `CADSZ3`, `CORCITEM`, `VLDNOMEFORN`, `VOGSB101`, `VORATF01`, `VOREST02`, `ZCRIASX3`, `ZZ3NORM`.
- **NFE/faturamento**: `NFEMNUCC`, `NFEPREVTS`, `nfesefaz` (atenção: minúsculas), `FALTFPED`, `VCTBL002`, `RLCOMPRAS`, `TIDEV`.
- **TLPP**: `SC7TREP`, `TESTDATA`, `ZDIAG110`.

## Convenções de nome/case de arquivo

- Convenção de case: novos `.prw` em maiúsculo (padrão do repo). `nfesefaz.prw`, `CORCITEM.prw` etc. em minúsculo/misto são legados — não renomear sem necessidade (RPO/patch referenciam).

## Nota sobre o catálogo

O `README.md` e este mapa foram revisados em 18/11/2026. Se houver divergência,
vale a árvore acima. Referências OpenSpec (`opsx-*`) foram removidas do
`opencode.json` (não usadas).
