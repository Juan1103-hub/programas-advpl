---
description: Regras de implementacao segura para AdvPL Protheus no modulo de Suprimentos.
when_to_use: Use quando editar fontes PRW PRX de regras de negocio, pontos de entrada ou telas Protheus.
allowed-tools: [Read, Grep, Glob]
paths: "**/*.PRW,**/*.prw,**/*.PRX,**/*.prx"
user-invocable: true
---
Aplicar sempre:
- Em funcao nova, incluir bloco Protheus.doc.
- Preservar GetArea()/RestArea() quando houver acesso a alias.
- Usar xFilial("ALIAS") em filtros por filial.
- Em SQL, priorizar TopConnect com %Table:% e %NotDel% quando aplicavel.
- Evitar alteracao de comportamento funcional fora do escopo pedido.
- Em revisao, listar findings por severidade antes de resumo.

Checklist rapido:
1. Validacoes de parametros e retornos.
2. Tratamento de erro sem quebrar fluxo existente.
3. Impacto em performance e manutencao.
4. Risco de regressao e cenarios de teste.

