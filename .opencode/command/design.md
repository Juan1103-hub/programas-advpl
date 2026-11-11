# /design <feature> — Arquitetura para features médias/grandes

## Uso
```
/design "novo campo ZC7_DATAENT em SC7"
/design "integração FWRest com API externa de cotação"
```

## Quando usar
- Feature >3 arquivos
- Múltiplos PEs afetados
- Nova tabela custom (Z*)
- Integração externa (FWRest)
- Migração AdvPL → TLPP

## Output (design.md)
```markdown
# Design: <slug>

## Arquitetura
- **Camadas**: ModelDef → ViewDef → BrowseDef (MVC) / TLPP class + REST endpoint
- **PEs impactados**: MTA110OK, MTA110INC, MTA110BRW
- **Tabelas**: SC7 (core), ZC7 (custom), <outras>

## Decisões Técnicas
| Decisão | Opção Escolhida | Justificativa |
|---------|-----------------|---------------|
| Validação ZC7_DATAENT | PE MTA110OK linha 78+ | Centraliza validação OK |
| Índice SC7 | SC7_FILIAL + C7_NUM + ZC7_DATAENT | Filtro padrão + novo campo |
| Migração dados | Script SQL + job batch | 2.3M rows, janela noturna |

## Riscos
- [ ] Lock escalation em SC7 durante migração
- [ ] PE MTA110OK já tem 340 linhas — risco regressão
- [ ] API externa: timeout 30s, retry 3x, circuit breaker

## Plano de Testes
- Unit: ProBat (TLPP) / TIR (Webapp)
- Integração: MATA110 fluxo completo
- Carga: 10k pedidos simultâneos
```