# /tasks <feature> — Breakdown em tasks executáveis

## Uso
```
/tasks "novo campo ZC7_DATAENT em SC7"
```

## Input
- `spec.md` existente (via `/specify`)
- `design.md` se existir (via `/design`)

## Output (tasks.md)
```markdown
# Tasks: <slug>

## Wave 1 — Data Layer (paralelo)
- [ ] T1.1: Criar ZC7_DATAENT no SX3 (tipo D, picture 99/99/9999, obrigatório .F.)
- [ ] T1.2: Alter table SC7 add ZC7_DATAENT date null (SQL Server)
- [ ] T1.3: Script migração: UPDATE SC7 SET ZC7_DATAENT = DATEADD(day, 7, C7_EMISSAO) WHERE D_E_L_E_T_ = ' '
- [ ] T1.4: Criar índice SC7_FILIAL + C7_NUM + ZC7_DATAENT

## Wave 2 — PEs (sequencial, ordem de dependência)
- [ ] T2.1: MTA110INC.PRW — default ZC7_DATAENT = Date() + 7 na inclusão
- [ ] T2.2: MTA110OK.PRW — validação ZC7_DATAENT >= C7_EMISSAO (linha 78+)
- [ ] T2.3: MTA110BRW.PRW — coluna ZC7_DATAENT no browse + filtro
- [ ] T2.4: MTA110DEL.PRW — log exclusão com ZC7_DATAENT

## Wave 3 — MVC/TLPP (paralelo)
- [ ] T3.1: ModelDef — addField ZC7_DATAENT (type date, required .F.)
- [ ] T3.2: ViewDef — campo ZC7_DATAENT no formulário + grid
- [ ] T3.3: BrowseDef — coluna + filtro + ordenação

## Wave 4 — Testes & Deploy
- [ ] T4.1: TIR test_CT001_CT005.py (fluxo inclusão/alteração/exclusão)
- [ ] T4.2: ProBat unit tests (validação ZC7_DATAENT)
- [ ] T4.3: /compile all → /review all → /specify gap-analysis
- [ ] T4.4: Deploy homologação → validação usuário-chave
```

## Dependencies
```mermaid
T1.1 → T1.2 → T1.3 → T1.4
T1.4 → T2.1, T2.2, T2.3, T2.4
T2.1 → T3.1
T2.2 → T3.2
T2.3 → T3.3
T3.* → T4.1
T4.1 → T4.2 → T4.3 → T4.4
```

## Execução
- Rode `/execute T1.1` para task única
- Rode `/execute wave 1` para wave inteira (paralelo)
- Rode `/execute all` para tudo (sequencial por wave)