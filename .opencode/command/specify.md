# /specify <feature> — Cria especificação SDD

## Uso
```
/specify "novo campo ZC7_DATAENT em SC7 para data de entrega prevista"
/specify "validação de lead time no PE MTA110OK para fornecedores internacionais"
```

## O que faz
1. Cria `.specs/features/<slug>/spec.md` com:
   - **Contexto**: tabelas, PEs, rotinas envolvidas
   - **Regras de negócio**: português claro, sem abreviações/inglês
   - **Critérios de aceite**: testáveis, binários
   - **Riscos/dependências**: PEs afetados, migração dados, performance
   - **Gap analysis template**: ✅/⚠️/🔄 para verificação final

2. Atualiza `.specs/project/STATE.md` com feature ativa

## Template gerado (spec.md)
```markdown
# Spec: <slug>

## Contexto
- **Módulo**: Suprimentos/Compras (SC7)
- **Tabelas**: SC7, <outras>
- **PEs**: MTA110OK, MTA110INC, <outros>
- **Rotinas**: MATA110, <outras>

## Regras de Negócio
1. <regra 1 em português claro, frase completa>
2. <regra 2...>

## Critérios de Aceite
- [ ] CT001: <cenário> → <resultado esperado>
- [ ] CT002: <cenário> → <resultado esperado>

## Riscos & Dependências
- PE MTA110OK: validação existente linha 78
- Migração: script SQL para ZC7_DATAENT existing rows
- Performance: índice SC7_FILIAL + C7_NUM + ZC7_DATAENT

## Gap Analysis (preenchido no EXECUTE)
| Item | Status | Evidência |
|------|--------|-----------|
| Regra 1 | ⬜ | |
| Regra 2 | ⬜ | |
| CT001 | ⬜ | |
| CT002 | ⬜ | |
```

## Pós-criação
- Rode `/design` se feature >3 arquivos ou ambígua
- Rode `/tasks` para breakdown
- Rode `/execute` para implementar