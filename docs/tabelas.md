# Tabelas-Chave de Suprimentos e Regras de Pontos de Entrada

> **Consulte este arquivo quando** for escrever SQL/queries contra tabelas do módulo Compras/Suprimentos, ou quando for implementar/ajustar ponto de entrada de rotina MATA*. Não é contexto fixo — leia sob demanda.

## Tabelas-Chave — Suprimentos (filtros canônicos)

| Alias | Descrição | Filtro/Chave canônica |
|-------|-----------|----------------------|
| SC7 | Pedidos de compra | `C7_RESIDUO <> 'S'`, `C7_QUANT > 0`, `C7_CONAPRO NOT IN ('R','B')` |
| SC1 | Solicitações de compra | Chave: `xFilial("SC1") + C1_NUM` |
| SC8 | Cotações | Chave: `xFilial("SC8") + C8_NUM` |
| SA2 | Fornecedores | `A2_CGC` com 14 dígitos, sem formatação |
| SD1 | NF de entrada | — |
| SD3 | Movimentação de estoque | TM ≤ 499 = entrada; TM > 499 = saída |
| SB1 | Produtos | `B1_MSBLQL <> '1'` |
| SB2 | Saldos | `B2_COD = B1_COD AND B2_LOCAL = B1_LOCPAD` |
| SB9 | Saldos históricos | `B9_DATA` AAAAMMDD; usar `B9_QINI`/`B9_VINI1` |
| SCP | Solicitação ao armazém | `CP_NUM = D3_NUMSA`; `CP_QUJE >= CP_QUANT` = encerrada |
| CTT | Centros de custo | `CTT_CUSTO = D3_CC` |
| SCR | Aprovações | `CR_TIPO` = `'IP'` ou `'PC'`; `CR_STATUS = '03'` = aprovado |
| SZ3/ZZ3 | Solicitações cadastrais | `Z3_ID` = chave; status 0 = pendente, 1 = aprovado, 2 = rejeitado |
| ZZ4 | Solicitação ao fornecedor | `ZZ4_ID` = chave |

## Comparação de CNPJ (SA2 × ZZ4) em SQL

```sql
REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(campo)),'.',''),'/',''),'-','')
```

## Regras de PEs por rotina (módulo Compras)

- **MATA110 (SC)**: `MTA110CON` roda em A110GRAVA/A110ALTERA — sem `RetCodOp()`; ler grid com `GdFieldGet("C1_CAMPO", nLinha)`; atualizar itens varrendo SC1 por `xFilial("SC1") + C1_NUM` com RecLock por registro.
- Nome do arquivo fonte = nome do PE (ex.: `MT110TOK.PRW`, `MTA110OK.PRW`).

## Regras de acesso a dados (reuso rápido)

- `GetArea()` / `RestArea()` obrigatório em toda função que acessar alias.
- `xFilial("ALIAS")` em todo filtro por filial — nunca hardcode.
- RecLock **APENAS** em tabelas `Z*`; tabelas core (SC5, SC6, SC7, SD1, SD2, SF1, SF2, SB1, SA2, …) → **MSExecAuto**.
- SQL seguro: `%Table:%`, `%NotDel%`, parâmetros (`?`/`:param`). Nunca concatenar entrada do usuário.

## Validação de dados via APSDU

Quando houver dúvida sobre estrutura/campos/valores na base: **não assumir**; gere query SQL e peça para o usuário executar no APSDU; aguarde o resultado antes de gerar código.

Ex.:
```sql
SELECT * FROM SB1010 WHERE B1_COD = 'XXXXX' AND D_E_L_E_T_ = ' '
```
