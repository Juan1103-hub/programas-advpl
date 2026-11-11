---
name: sd3-tm-fronteira-500-entrada-saida
description: Classificar entrada/saida na SD3 pela TM (D3_TM < '500' = entrada), nunca por D3_CF
type: feedback
metadata:
  type: feedback
---

**Problema**: query classificava entrada/saida por `D3_CF = 'R'` — nunca casa (D3_CF tem 3
caracteres) e o prefixo `RE` (requisicao) e SAIDA, nao entrada. Toda movimentacao virava
saida e a abertura de estoque ficava inflada em todos os itens.

**Regra correta**: fronteira na TM (D3_TM), nao no CFOP.

```sql
SUM(CASE WHEN SD3.D3_TM < '500' THEN D3_QUANT ELSE D3_QUANT * -1 END)
```

- `< 500` = entrada; `>= 500` = saida (regra TOTVS, TDN MATA241/MATA230)
- `<= 500` e ERRADO: a TM 500 e saida e movimenta quantidade
- Excluir estornos: `AND SD3.D3_ESTORNO = ' '`
- TM 499 (devolucao automatica, entrada) carrega CFOP `RE` — por isso filtrar por
  `D3_CF NOT LIKE 'RE%'` tambem quebra

**Cadastros SF5 do cliente Vortice** (MATA241, filial Morro do Ferro):
- Entradas: 001 apontamento automatico, 002 apontamento producao, 004 ajuste de valor,
  005 ajuste custo entrada, 03 devolucao de estoque
- Saidas: 500 inclusao de P.A., 501 ajuste custo saida, 502 baixa de material,
  555 req. oleo diesel, 666 quebra (oleo diesel)
- Nenhuma TM com Transf.MOD = S — nao ha transferencia entre armazens, entao o par
  RE4/DE4 nao precisa de tratamento

**Como aplicar**: sempre que calcular saldo de abertura a partir da SD3, usar a fronteira
da TM. Validar o cadastro do cliente no MATA241 antes de assumir faixa.

[[sql-anti-injection]] [[zmma01-alias-sql-erro]]
