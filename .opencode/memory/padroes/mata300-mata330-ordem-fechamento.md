---
name: mata300-mata330-ordem-fechamento
description: Ordem MATA300 (Refaz Saldos) antes do MATA330; B9_DATA vazio na SB9
type: feedback
metadata:
  type: feedback
---

**Problema**: rotina de ajuste de saldo gravava só SB9+SB2 e chamava a MATA330. O saldo
em quantidade (B2_QATU) continuava errado, porque quem recompoem a quantidade pelos
movimentos é o MATA300 (Refaz Saldos), não o MATA330. Log acusava "DIVERGENCIA DE
QUANTIDADE: esperado 2.0000 | encontrado 3.0000".

**Regra**: ordem oficial do fechamento de estoque (roteiro TOTVS, Central 360048372754):

```
MATA300 (Refaz Saldos)  ->  MATA330 (Recalculo Custo Medio)  ->  MATA280 (Virada)
   quantidade B2_QATU         custo B2_CM1 + CT2
```

- **MATA300** = `MSExecAuto({|x| MATA300(x)}, .T.)` — **um único parâmetro lógico**
  (lBatch). **Retorno documentado: `Nil`** — não dá pra checar `.T.`/`.F.`; o resultado
  só se vê na validação do SB2. Exige `PREPARE ENVIRONMENT ... MODULO "EST"`.
  Recompõe B2_QATU/B2_VATU1 a partir da SB9 + SD1/SD2/SD3 desde MV_ULMES.
  (Central 1500003684662)
- **MATA330** = `MATA330(lBatch, aListaFil, lCustoPartes, aParAuto)`. Formato oficial de
  `aListaFil` (artigo 1500010494141, exemplo JOBM330):
  `{lMarcado, M0_CODFIL, M0_FILIAL, M0_CGC}` — **não** `{lMarcado, xFilial("SB2"), "", ""}`.
  `aParAuto` segue a ordem das 21 perguntas SX1: **1 = Data Limite Final, 4 = Atualizar
  Arq. de Movimentos (obrigatório "Sim"), 10 = Gerar Lancto. Contabil**.

**SB9 — regra que quebra expectativa**: `B9_DATA` **deve permanecer VAZIO** no saldo
inicial, inclusive via ExecAuto (Central 360016346632). `B9_CM1` fica **zerado**; grava-se
`B9_QINI` (qtd) + `B9_VINI1` (valor total, moeda 1) — **não existe campo `B9_VINI`**.
Os 2 índices da SB9 têm `DTOS(B9_DATA)`, então o seek por produto+local é **parcial**:
`DbSeek(xFilial("SB9") + cProd + cLocal, .T.)`.
Inclusão: `MSExecAuto({|x,y| MATA220(x,y)}, aVetor, 3)` com `B9_FILIAL, B9_COD, B9_LOCAL,
B9_QINI, B9_VINI1`; erro checado por `lMsErroAuto` + `GetAutoGrLog()` (não há retorno
direto). Operação 4 (alteração) do ExecAuto MATA220 **não é documentada** — usar RecLock.

**Na 12.1.33+**: MATA280 (Virada) foi descontinuada avulsa em favor da **MATA038
(Acompanha Custos)**, que orquestra MATA330+MATA331+MATA280.

**Como aplicar**: em qualquer rotina que ajuste saldo/custo e queira consistência
estoque+razão, rodar MATA300 → MATA330 e validar lendo o SB2 (não confiar no retorno).

[[sd3-tm-fronteira-500]] [[fechamento-estoque-x-razao-reconciliacao]]
