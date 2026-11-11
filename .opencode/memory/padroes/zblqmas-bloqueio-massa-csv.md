---
name: zblqmas-bloqueio-massa-csv
description: Rotina ZBLQMAS — bloqueio/desbloqueio em massa de produtos (B1_MSBLQL) via CSV, mesmo fluxo do ZATUDESC
---

# ZBLQMAS — bloqueio/desbloqueio em massa de cadastros (SB1)

**Rotina:** `FONTES/ZBLQMAS.PRW` — `User Function ZBLQMAS()`
**Campo atualizado:** `B1_MSBLQL` (SB1) — `1` = Sim, cadastro bloqueado; `2` = Não, cadastro desbloqueado.
**Acesso:** mesmos botões do `ZATUDESC` na MATA010 (ver abaixo).

## Estrutura do CSV (separador `;`, aspas suportadas)

| Coluna | Campo | Conteúdo |
|---|---|---|
| A | `B1_COD` | Código do produto |
| B | `B1_MSBLQL` | `1` = bloquear / `2` = desbloquear |

- Planilha salva como **"CSV Windows (ANSI)"** (CP-1252) — mesmo aviso do ZATUDESC.
- Cabeçalho ignorado **somente na 1ª linha** (checagem `"digo" $ Lower` ou `"ituacao" $ Lower`).
- **Bloquear e desbloquear na mesma importação**: vale a situação de cada linha, sem ordem obrigatória.

## Processamento (mesmo padrão do ZATUDESC)

1. `MsgYesNo` de estrutura → `tFileDialog("CSV files (*.csv)")` → `MsgYesNo` de confirmação → `Processa` com régua.
2. `FWFileReader` linha a linha → `fCsvSplit` (parser de aspas, copiado do ZATUDESC) → validações → `DbSeek` SB1 ordem 1 (`FWxFilial + PADR`) → `RecLock("SB1", .F.)` → `SB1->B1_MSBLQL := cSituacao` → `MsUnlock()`.
3. `MsgInfo` final: Ok / Bloqueados / Desbloqueados / Erros / Ignorados.

**Contadores:** situação diferente de `1`/`2` ou produto não encontrado = **Erro**; linha com menos de 2 colunas ou código vazio = **Ignorado**.

## PEs (adicionados sem alterar os existentes)

```advpl
// MA010BUT (toolbar da view) — formato {icone, blocoDeAcao, titulo}
AAdd(aRet, { "NOTE", {|| U_ZBLQMAS()}, "Bloqueio/Desbloqueio em Massa" })
// MTA010MNU (menu do browse) — formato aRotina
AAdd(aRotina, { "Bloqueio/Desbloqueio em Massa", "U_ZBLQMAS()", 0, 2, 0, Nil })
```

## Nota — divergência registrada

`CONFIG/AGENTS.md` manda `RecLock` só em tabelas `Z*` (core via MSExecAuto), mas este
registro segue **por instrução do usuário** o mesmo padrão da última funcionalidade
(`ZATUDESC`, que grava SB1 via RecLock direto e já está confirmado em produção).
MSExecAuto `MATA010` por produto seria pesado e dispararia todos os PEs de cadastro.

**Verificado em 13/10/2026:** 25 checks (estrutura AdvPL, ASCII/CP-1252, PEs com botão
novo + legados preservados) e simulação byte a byte do parser: 10 linhas → ok=5
(bloq=2/desbloq=3), erro=2, ignorado=2. **Botão em tela confirmado pelo usuário em 13/10/2026 ("deu certo")** — item no "Outras Ações" da MATA010 funcionando; compilação dos 2 PEs era o faltante quando não apareceu.

[[zatudesc-atualizacao-descricoes-csv]] [[pe-botao-codigo-mnu]] [[entry-point-naming]]
