---
paths:
  - "CONFIG/tir/**"
  - "**/test*.py"
  - "**/*.md"
---

# 06 - Testes e Documentacao

## TIR (e2e Webapp/SmartClient)

- Scripts em `CONFIG/tir/`; padrao `unittest.TestCase` com `setUpClass()`, `test_CTNNN()`, `tearDownClass()`.
- Rodar a partir de `CONFIG/tir/`: `python -m unittest <Classe>.<test_...>`.
- Pre-requisitos hoje: pacote `tir` NAO instalado (`pip install tir`) e `CONFIG/tir/config.json`
  com placeholders `{server}:{port}` — preencher antes de rodar.
- Gerar com a skill `tir-test-generator`. Unit TLPP com `probat-testing`.

## ProtheusDOC (obrigatorio em codigo novo)

Toda funcao publica com bloco `/*/{Protheus.doc}` minimo: `@type`, `@author`, `@since`,
`@param` (se houver), `@return` (se houver). Ver skill `documentation-writer`.

## Debug — fluxo obrigatorio

1. Reproduzir e isolar (rotina, PE no fluxo, mensagem exata do AppServer).
2. Consultar memoria antes de hipoteses (Obsidian `06` ou `.opencode/memory/MEMORY.md`).
3. Validar dados via APSDU (gerar query, pedir execucao ao usuario, aguardar resultado).
4. Citar causa como `arquivo:linha`. Log de PE com `FWLogMsg` (prefixo `[PE_NAME]` em legados).
5. Apos resolver, registrar no Obsidian + `.opencode/memory/`.

## UI do projeto

- Visualizacao: botao "Fechar" a direita. Inclusao/edicao: "Confirmar" esquerda + "Cancelar/Fechar" direita.
- Browse simples `mBrowse`; com logica ao trocar linha `FWMBrowse`; `oBrw:Refresh()` sem `.T.`
  (com `.T.` volta ao topo); flag `Private lBusy` contra recursao `bChange` (stack overflow).
