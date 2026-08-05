---
description: Checklist de qualidade para alteracoes em HTML CSS JS com foco em responsividade e acessibilidade.
when_to_use: Use quando editar interface web, estilos ou scripts.
allowed-tools: [Read, Grep, Glob]
paths: "**/*.html,**/*.css,**/*.js,**/*.ts,**/*.tsx,**/*.jsx"
user-invocable: true
---
Checklist de frontend:
- Confirmar layout responsivo em desktop e mobile.
- Usar HTML semantico e rotulos acessiveis para campos e botoes.
- Evitar estilos duplicados; priorizar variaveis CSS e regras reutilizaveis.
- Garantir contraste e legibilidade.
- Preservar padrao visual existente quando houver design system.
- Evitar micro-ajustes que alterem telas fora do escopo.

Validacao minima:
1. Fluxo principal funcionando sem erro JS critico.
2. Estados vazios e mensagens de erro tratados.
3. Sem regressao visual evidente em componentes alterados.

