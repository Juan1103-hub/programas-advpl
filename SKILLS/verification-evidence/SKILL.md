---
description: Roteiro de verificacao com evidencia objetiva para mudancas em AdvPL e frontend.
when_to_use: Use apos alteracoes para validar com comandos executados e resultado observavel.
allowed-tools: [Read, Grep, Glob, Bash]
paths: "**/*.PRW,**/*.prw,**/*.html,**/*.css,**/*.js"
user-invocable: true
---
Roteiro de verificacao:
- Nao concluir com base apenas em leitura de codigo.
- Executar comandos de validacao quando houver rotina de build, lint ou teste.
- Registrar comando e saida principal de cada check.
- Classificar cada check como PASS, FAIL ou PARTIAL.

Formato esperado:
1. Check executado.
2. Evidencia coletada.
3. Resultado.
4. Risco residual e proximo passo.

