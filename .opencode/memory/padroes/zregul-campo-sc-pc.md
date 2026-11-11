# Padrão: Campo Regularização (C1_ZREGUL / C7_ZREGUL) — SC→PC

> Feature implementada em 15/10/2026. Campo "Regulariza" (Sim/Não) por item.

## Decisões do usuário (2026-10-15)

- Campo **por item** (grid), não no cabeçalho.
- SC1: **obrigatório**. SC7: **editável, não obrigatório**.
- Propagação por **rota direta SC1→SC7** (sem passar por cotação/SC8).
- Criação dos campos: **Configurador do Protheus** (SIGACFG) feita pelo usuário — sem rotina U_ZCRIA.

## Dicionário (criado pelo usuário no Configurador)

| Campo | Tabela | Tipo/Tam | Combo (X3_CBOX) | Val. Usuário | Obrigatório |
|---|---|---|---|---|---|
| `C1_ZREGUL` | SC1010 | C(1) | `S=Sim;N=Não` | `Pertence("S;N")` | **Sim** |
| `C7_ZREGUL` | SC7010 | C(1) | `S=Sim;N=Não` | `Vazio() .Or. Pertence("S;N")` | Não |

- Título: `Regulariza` (máx 10 chars). Demais abas: Inic.Padrão/Browse/When vazios; X3_PICTVAR vazio; Regras de dependência vazia.
- **Gatilho SX7: NÃO** — origem (SC1) e destino (SC7) em tabelas/momentos diferentes; SX7 só age no mesmo formulário.
- Linha vazia no dropdown do combo = comportamento padrão do Protheus, não removível via SX3; bloqueio real é Obrigatório + Pertence.
- Nota 10 do Obsidian (`10 - Configurador`) está **incompleta**: não lista "Lista de Opção" (X3_CBOX) na aba Opções — pendente atualizar vault.

## Código (3 fontes)

| Arquivo | Função | Papel |
|---|---|---|
| `FONTES/MTA110OK.PRW` | `MTA110OK()` | Backstop: valida `C1_ZREGUL` preenchido em toda linha não-deletada (padrão `Help()` + `lRet:=.F.` do C1_EC05DB; guarda `aScan` nPosReg>0) |
| `FONTES/MT120ISC.PRW` (**novo**) | `MT120ISC()` | Ao vincular SC ao PC: `aCols[n][nPosReg] := SC1->C1_ZREGUL` se vazio (valor visível na tela) |
| `FONTES/MTA120G3.PRW` | `MTA120G3()` | No loop de gravação (SC7 posicionado, sem RecLock — padrão MTA120G2): se `C7_NUMSC` preenchido e `C7_ZREGUL` vazio → DbSeek SC1 ordem 1 (`xFilial("SC1")+C7_NUMSC+C7_ITEMSC`) → copia. **Não sobrescreve** edição manual no PC |

- Guards `FieldPos` em ambos os lados em todos os PEs (não quebra se campo faltar em ambiente).
- PC criado direto sem SC: `C7_ZREGUL` fica vazio (usuário preenche se quiser).
- Encoding: 3 arquivos 100% ASCII → CP-1252 compatível (verificado via convert-encoding.bat 15/10/2026).

## Como reaproveitar

Campo flag Sim/Não novo em SC1/SC7: mesmo desenho (Configurador combo `S=Sim;N=Não` + Pertence; backstop no PE *OK da rotina; propagação via MTA120G3 com guarda Empty() + FieldPos; exibição no grid via MT120ISC).

## Pendências

- Compilar as 3 fontes no AppServer CINVJ6_DEV (TDS/VS Code).
- Teste: SC sem preencher → bloqueia; PC a partir de SC → campo preenchido; alterar no PC → persiste; PC direto sem SC → vazio.
- Quando vault Obsidian disponível: registrar no `06 - Bugs Resolvidos.md`? não é bug — registrar em `03 - SX3`/padrões + corrigir nota 10 (Lista de Opção).
