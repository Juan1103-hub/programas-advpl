# Padrao: Replicacao de campos do PC MANUAL (linha 1 -> demais linhas)

> Implementado em 15/10/2026, revisado em 19/10/2026 (v2.4).
> Exigencia do usuario: pedido de compra manual com varias linhas -
> ao preencher a primeira linha, replicar C7_XESTOQ1, C7_EC05DB,
> C7_ZREGUL e C7_TPFRETE nas demais, SOMENTE quando o pedido nao
> vier de Solicitacao de Compra.

## Regras

1. **Somente pedido manual**: linha so recebe copia se `Empty(C7_NUMSC)`.
   Linhas de SC ficam intocadas (valor delas vem de MT120ISC/MTA120G3).
2. **So preencher vazios**: se o destino ja tem valor, nao sobrescreve
   (preserva edicao manual). O C7_TPFRETE segue o fluxo original do
   MT120TFR (propaga e alimenta M->C7_TPFRETE).
3. **Fonte = linha 1 do aCols** (e so se a linha 1 for manual e nao-deletada).
4. Campos fora do aHeader (X3_BROWSE desmarcado) sao ignorados via guard
   `MT120Pos() > 0`.

## Mecanismo (3 camadas)

| Camada | Onde | Quando roda |
|---|---|---|
| **Retorno (linhas 2+ imediato)** | `_PATCHES/PATCH_01/MT120TFR.PRW` v2.4: `U_MT120RX1/2/3()` -> `Static MT120RepVal(cCampo)` | Gatilhos SX7 em C7_PRODUT (contra-dominio do campo): o RETORNO da regra preenche a LINHA CORRENTE via framework |
| Direta (demais linhas nao-correntes) | `_PATCHES/PATCH_01/MT120TFR.PRW`: `Static MT120Replica()` chamada no inicio de `U_MT120TFR()` | Mesma chamada do gatilho - copia linhas que NAO sao a corrente (essas escritas persistem) |
| Seguranca (pre-save) | `_PATCHES/PATCH_01/MT120OK.PRW`: `Static MT120ReplicaSeg()` (BLOCO 2) | Antes da gravacao - cobre linha 1 preenchida DEPOIS das demais ja criadas |

### Por que gatilho de RETORNO (licao central, 19/10/2026)

Escrita direta em `aCols[i][pos]` da **LINHA CORRENTE** durante o gatilho
de C7_PRODUTO **e descartada**: ao terminar a validacao do campo, o
MSGETDADOS/webapp re-sincroniza a linha em edicao e sobrescreve. O C7_TPFRETE
sempre funcionou porque o RETORNO de `U_MT120TFR()` alimenta o contra-dominio
via framework. Regra de ouro: campo da linha corrente => retorno + contra-dominio.

## Gatilhos SX7 (SC7, campo C7_PRODUT) - criados/regularizados 19/10/2026

| Cnt. Dominio | Regra | Obs |
|---|---|---|
| C7_TPFRETE | U_MT120TFR() | **Nunca tinha sido cadastrado** - confirmado no browse em 19/10 (causa do frete nao replicar) |
| C7_XESTOQ1 | U_MT120RX1() | Atua.Estoque |
| C7_EC05DB | U_MT120RX2() | Nat.Gastos |
| C7_ZREGUL | U_MT120RX3() | Regulariza |

Todos Tipo Primario, Posiciona Nao. Chave SX7 = X7_FILIAL+X7_CAMPO+X7_SEQUENC -
sempre usar proxima sequencia livre (registro posicionado no browse pode ser
ALTERADO em vez de inserido). Gatilho so dispara com X3_TRIGGER='S' no SX3.

## Cenario de borda

- PC misto (linhas de SC + manuais): so as manuais recebem copia.
- Linha 1 com C7_NUMSC (PC de SC): replicacao inteira cancelada.
- MT120RepVal retorna o proprio valor da linha (retorno neutro) quando
  nao deve replicar - nunca zera o campo.

## Estado (19/10/2026)

- Fontes em `_PATCHES/PATCH_01/` (MT120TFR, MT120OK, MT120ISC, MTA120G3, MTA110OK).
- MT120TFR v2.4 compilado no CINVJ6_DEV; 3 gatilhos custom criados e testados OK
  (linha 1 -> linhas 2/3 replicam no webapp).
- Pendencia: cadastrar/validar o gatilho do frete (C7_TPFRETE -> U_MT120TFR()) e re-testar.
- Registrado tambem no Obsidian: `06 - Bugs Resolvidos.md` (2026-10-19) e
  `03 - SX3 e Dicionario de Dados.md` (secao dos 4 gatilhos).
