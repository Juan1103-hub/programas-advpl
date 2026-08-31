---
name: sql-safe
description: Padrao de SQL seguro para TopConnect em fontes AdvPL.
when_to_use: Use quando houver criacao ou manutencao de SQL em AdvPL, incluindo BeginSql e TCSQLExec.
allowed-tools: [Read, Grep, Glob]
paths: "**/*.PRW,**/*.prw,**/*.PRX,**/*.prx,**/*.sql"
user-invocable: true
---
Padrao recomendado para SQL:
- Usar GetNextAlias() para alias temporario.
- Em BeginSql EndSql, usar %Table:% e %NotDel% quando aplicavel.
- Filtrar filial com xFilial("ALIAS") em consultas por filial.
- Evitar concatenacao de entrada de usuario em SQL.
- Fechar area apos uso com DbCloseArea().

Validar antes de concluir:
1. Se o filtro de deletados foi aplicado corretamente.
2. Se o filtro de filial esta consistente.
3. Se ha risco de full scan desnecessario.
4. Se campos data e status respeitam regra de negocio.


