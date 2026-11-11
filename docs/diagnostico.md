# Diagnóstico de duplicidade / erro de dados — Pedido de Compra (SC7)

> Uso: conferir dados no banco (APSAU/APSDU) e localizar gravações custom
> em SC7/SC1/SC8. Só consta aqui o que foi verificado no código do repo.
> O que não foi confirmado está marcado como **não confirmado**.

## 1. Queries SQL de conferência de duplicidade em SC7

As tabelas físicas ganham sufixo de empresa/filial (ex.: `SC7010`).
**Ajustar o sufixo conforme a empresa/filial do ambiente** — o nome físico
correto em código é `RetSqlName("SC7")`; o `010` abaixo é apenas exemplo.
Toda query usa `D_E_L_E_T_ = ' '` (soft-delete).

**H1 — mesma cotação, mesmo produto e mesmo fornecedor, em pedidos
diferentes (geração via MATA130):**

```sql
SELECT C7_NUMCOT, C7_PRODUTO, C7_FORNECE, C7_LOJA,
       COUNT(DISTINCT C7_NUM) AS QTD_PEDIDOS, COUNT(*) AS QTD_LINHAS
FROM SC7010
WHERE D_E_L_E_T_ = ' ' AND C7_NUMCOT <> ''
GROUP BY C7_NUMCOT, C7_PRODUTO, C7_FORNECE, C7_LOJA
HAVING COUNT(DISTINCT C7_NUM) > 1
```

> Uma cotação gerar vários pedidos para fornecedores diferentes é normal.
> Duplicidade real é o mesmo produto e o mesmo fornecedor em pedidos
> diferentes. Verifique no SX3 se existe `C7_ITEMCOT` e, se existir, use no
> lugar de `C7_PRODUTO`.

> **Resultado já observado:** a H1 antiga (agrupando só por `C7_NUMCOT`)
> retornou mais de 29 cotações com 2 a 4 pedidos cada (ex.: cotações 000004
> e 000106 com 4 pedidos cada). Como uma cotação pode gerar um pedido por
> fornecedor, isso é **ainda não confirmado como duplicidade**.

**H2 — mesmo item de SC virando mais de um pedido:**

```sql
SELECT C7_NUMSC, C7_ITEMSC, COUNT(*) AS QTD
FROM SC7010
WHERE D_E_L_E_T_ = ' ' AND C7_NUMSC <> ''
GROUP BY C7_NUMSC, C7_ITEMSC
HAVING COUNT(*) > 1
```

**H3 — mesmo produto repetido dentro do mesmo pedido:**

```sql
SELECT C7_NUM, C7_PRODUTO, COUNT(*) AS QTD
FROM SC7010
WHERE D_E_L_E_T_ = ' '
GROUP BY C7_NUM, C7_PRODUTO
HAVING COUNT(*) > 1
```

## 2. Padrões de busca (grep) para localizar gravações em SC7 / SC1 / SC8

Rodar com variações de maiúsculas/minúsculas e aspas simples/duplas
(extensões `.prw/.PRW/.tlpp/.TLPP` em `FONTES/` e `_PATCHES/`):

| Padrão | O que procura |
|---|---|
| `RecLock("SC7` / `RecLock('SC7` | Gravação direta em SC7 (proibida fora de Z*) |
| `RecLock("SC1` / `RecLock('SC1` | Gravação direta em SC1 |
| `RecLock("SC8` / `RecLock('SC8` | Gravação direta em SC8 |
| `dbAppend` (variações `DbAppend`, `DBAPPEND`) | Inclusão ISAM de registro |
| `MsExecAuto` / `MSExecAuto` | Rotinas automáticas (MATA120, MATA241 etc.) |
| `A110Inclui` / `a110inclui` | Inclusão de SC por rotina |
| `Ma110GerPC` / `M110GerPC` | Geração de PC a partir de SC — **não confirmado** se existe no projeto |
| `MsUnlock` próximo a `SC7` | Fim de gravação direta em SC7 |
| `GdFieldPut` / `GdAppend` / `GdAddLine` | Manipulação de grid que pode criar linha |

## 3. Fatos já verificados no código

1. **Nenhum custom do projeto INSERE registros em SC7** — grep por
   `MsExecAuto`/`A110Inclui`/`RecLock("SC7"`: só atualizações de campo
   pontuais. A duplicidade, se confirmada, não vem de insert customizado
   rodando duas vezes.
2. **`FONTES/AVALCOT.PRW:9`** — no evento 4 faz `RecLock('SC7',.F.)` e
   grava `C7_TPFRETE := SC8->C8_TPFRETE` **sem validar em qual registro o
   alias SC7 está posicionado** (condição é apenas `Select("SC8") > 0`).
   Pode gravar em registro errado; não cria registro novo.
3. **`_PATCHES/PATCH_01/MTA110OK.PRW:244`** (`MT120GOK`) —
   `SC8->(DbSeek(xFilial("SC8") + cNumCot + cItemCot))` com
   `cNumCot`/`cItemCot` vindos do aCols **sem tratar chave vazia**
   (linhas 235-236); se a linha não tiver cotação, o DbSeek recebe chave
   vazia e a cópia de `C8_EC05DB` sai da cotação errada.
   Qual índice corresponde à ordem 2 do SC8 — **não confirmado** (validar no SIX).
4. **`_PATCHES/PATCH_01/MT120TFR.PRW:181-188`** — o gatilho SX7 em
   `C7_PRODUTO` propaga `C7_TPFRETE` para todas as linhas não-deletadas,
   **explicitamente incluindo a linha em branco do grid** (comentário da
   própria linha 181). Efeito sobre gravação de linha sem produto —
   **não confirmado** (depende do comportamento do MATA120 nesta build).

## 4. Hipóteses abertas (do último diagnóstico)

- H1: geração via cotação executada 2x (duplo clique/concorrência) — confirmar com query H1.
- H2: fluxo misto SC→PC manual + SC→cotação→PC — confirmar com query H2.
- H3: itens repetidos dentro do mesmo PC — confirmar com query H3.
- Nenhuma delas foi confirmada; as queries acima são o próximo passo.
