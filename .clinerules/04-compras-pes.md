---
paths:
  - "FONTES/MT*.PRW"
  - "FONTES/MTA*.PRW"
  - "FONTES/Z*.PRW"
  - "FONTES/CAD*.PRW"
  - "FONTES/VO*.PRW"
---

# 04 - Compras e Pontos de Entrada (Vortice)

## Filtros canonicos — Suprimentos

| Alias | Descricao | Filtro/Chave |
|-------|-----------|--------------|
| SC7 | Pedidos de compra | `C7_RESIDUO <> 'S'`, `C7_QUANT > 0`, `C7_CONAPRO NOT IN ('R','B')` |
| SC1 | Solicitacoes de compra | Chave `xFilial("SC1") + C1_NUM` |
| SC8 | Cotacoes | Chave `xFilial("SC8") + C8_NUM` |
| SA2 | Fornecedores | `A2_CGC` 14 digitos, sem formatacao |
| SB1 | Produtos | `B1_MSBLQL <> '1'` |
| SB2 | Saldos | `B2_COD = B1_COD AND B2_LOCAL = B1_LOCPAD` |
| SB9 | Saldos historicos | `B9_DATA` AAAAMMDD; usar `B9_QINI`/`B9_VINI1` |
| SD3 | Mov. estoque | TM <= 499 entrada; TM > 499 saida |
| SCR | Aprovacoes | `CR_TIPO` `IP`/`PC`; `CR_STATUS = '03'` aprovado |
| SZ3/ZZ3 | Solicit. cadastrais | `Z3_ID` chave; 0 pendente, 1 aprovado, 2 rejeitado |
| ZZ4 | Solicit. fornecedor | `ZZ4_ID` chave |

## PEs por rotina (Compras)

- **MATA110 (SC)**: `MTA110CON` em A110GRAVA/A110ALTERA, sem `RetCodOp()`; ler grid com
  `GdFieldGet("C1_CAMPO", nLinha)`; atualizar itens varrendo SC1 por `xFilial + C1_NUM`.
- **MATA120 (Pedido)**: `MT120OK` (conta contabil + `C7_TPFRETE`); `MT120TFR` (gatilho SX7).
- **MATA010 (Produtos)**: `A010TOK` (Min/Max, justificativa); `MT010ALT` (data modificacao).
- Workarounds build `7.00.240223P`: SXB/ZZ4 via `U_ZCONSZZ4()`; FWBrowse x `X3_WHEN` via botao
  BUTTONBAR `MT020BAR` -> `U_OPENZZ4()` -> `U_FFZZ4A2()` (ver `CONFIG/AGENTS.md`).

## Mapa de fontes

- `FONTES/` com 73 arquivos (inventario 2026-10-14; `AGENTS.md` citava 70 — divergencia registrada).
- `MT*`/`MTA*` = PE de rotinas MATA*, `Z*` = custom, `CAD*` = cadastro, `V*`/`VO*` = Vortice.
- TLPP: `SC7TREP`, `TESTDATA`, `ZDIAG110`. Orfao candidato a exclusao: `zdiag110.ppx_tlpp`.
