# /execute <task|wave|all> — Implementa tasks com validação

## Uso
```
/execute T1.1
/execute wave 1
/execute all
```

## Fluxo por task
1. **Read** spec/design/tasks contexto
2. **Implement** código (AdvPL/TLPP)
3. **utf8-to-cp1252-conversion** no arquivo
4. **advpl-tlpp-compile** no AppServer
5. **advpl-code-review --level high**
6. Se erro → **para, mostra, não continua**
7. Se OK → **marca task concluída** em tasks.md
8. Se bug novo descoberto → cria memory (`TEMPLATE-BUG.md`)

## Wave execution (paralelo)
```
/execute wave 1
```
- Dispara tasks T1.1, T1.2, T1.3, T1.4 **em paralelo** (subagents `explore`/`general`)
- Aguarda **todas** passarem compile+review
- Só avança se **100% verde**

## All execution (sequencial por wave)
```
/execute all
```
- Wave 1 → Wave 2 → Wave 3 → Wave 4
- Para no primeiro erro de qualquer task
- Gap analysis final em spec.md

## Validação final (obrigatória)
Ao concluir `/execute all`:
1. **Gap analysis** em spec.md — preenche ✅/⚠️/🔄 item a item
2. **Completeness check**:
   - [ ] VerifyAccess/MPUserHasAccess replicados
   - [ ] SuperGetMV/FWModeAccess/FwAliasInDic replicados
   - [ ] nModulo/cPaisLoc/FindFunction replicados
   - [ ] Lógica condicional idêntica ao original
3. **Memory update** — bugs/padrões novos registrados
4. **Apresenta gap analysis** antes de declarar fim

## Rollback
Se task falhar irrecuperavelmente:
```
/undo T2.2
```
- Reverte arquivos modificados pela task
- Atualiza tasks.md (marca ⬜)
- Não afeta tasks já concluídas de outras waves