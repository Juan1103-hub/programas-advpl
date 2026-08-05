# Pasta PATCH — Catálogo de Programas AdvPL/TLPP

> Documento de referência rápida sobre os fontes `.PRW` / `.tlpp` compilados e implantados no Protheus.
> Atualizado em: 30/06/2026

## Visão Geral

A pasta **PATCH/** concentra 14 programas (13 AdvPL + 1 TLPP) que implementam três grandes blocos funcionais do módulo **Suprimentos (SIGACOM/SIGAEST)**:

1. **Solicitação Cadastral de Fornecedores (ZZ4)** — fluxo de aprovação de novos fornecedores, com integração ao cadastro oficial (SA2 / MATA020).
2. **Solicitação de Compra (SC1 / MATA110)** — pontos de entrada para controle de data de emissão e data de necessidade.
3. **Pedido de Compra (SC7)** — recalculo de data de entrega prevista após aprovação, análise de fretes e controle logístico.

---

## Índice

| # | Arquivo | Tipo | Categoria |
|---|---------|------|-----------|
| 1 | `CADFORN.PRW` | Tela (FWMBrowse) | Solicitação Cadastral de Fornecedores |
| 2 | `FFZZ4A2.PRW` | PE — Valid | Solicitação Cadastral de Fornecedores |
| 3 | `MT020INC.PRW` | PE — Pos-include | Solicitação Cadastral de Fornecedores |
| 4 | `MTA020.PRW` | PE — Inicialização | Solicitação Cadastral de Fornecedores |
| 5 | `OPENZZ4.PRW` | Expressão X3_INIBRW | Solicitação Cadastral de Fornecedores |
| 6 | `ZZ4PEND.PRW` | Browse de seleção (SXB) | Solicitação Cadastral de Fornecedores |
| 7 | `ZCONSZZ4.PRW` | Setup de dicionário | Solicitação Cadastral de Fornecedores |
| 8 | `MT110CON.PRW` | PE — Pre-save (TudoOK) | Solicitação de Compra (MATA110) |
| 9 | `MT110EMI.tlpp` | Função User (SX7) | Solicitação de Compra (MATA110) |
| 10 | `M110STTS.PRW` | PE — Pos-save | Solicitação de Compra (MATA110) |
| 11 | `MTALCFIM.PRW` | PE — Aprovação (MATXALC) | Pedido de Compra (SC7) |
| 12 | `ZANAFRETE.PRW` | Relatório de análise | Pedido de Compra (SC7) |
| 13 | `ZLOGCOL.prw` | Tela (FWMarkBrowse) | Pedido de Compra (SC7) |

---

## Bloco 1 — Solicitação Cadastral de Fornecedores (ZZ4)

Fluxo: o usuário preenche uma **solicitação cadastral** (tabela custom `ZZ4`) → aprovação → vinculado ao criar fornecedor no **MATA020** via campo `A2_ZSOLID` (ou `A2_ZZ4ID`) → status do ZZ4 muda automaticamente.

### 1. `CADFORN.PRW` — Browse principal de solicitações ZZ4

- **Função principal:** `User Function CADFORN()`
- **Objetivo:** abrir um `FWMBrowse` na tabela `ZZ4` com legenda colorida indicando o status de cada solicitação.
- **Legenda:**
  - `BR_BRANCO` → `ZZ4_STATUS = '0'` (Pendente)
  - `BR_VERMELHO` → `ZZ4_STATUS = '1'` (Cadastrado)
- **Recursos:**
  - **Sincronização automática** do status ao mudar de linha (`bChange := FZ4SyncBrw`), verificando se o CNPJ já existe na `SA2`.
  - Flag `lZZ4SyncBusy` evita **recursão infinita** (o `Refresh` dispara `bChange`).
  - Função `FSyncZZ4Status()` varre **todos** os registros no carregamento inicial.
- **Helpers:** `FZ4SyncBrw`, `FSyncZZ4Status`, `MenuDef`.

### 2. `FFZZ4A2.PRW` — Valid do campo A2_ZZ4ID

- **Função principal:** `User Function FFZZ4A2()`
- **Objetivo:** ao sair do campo `A2_ZZ4ID` no SA2, buscar o registro na `ZZ4` e preencher automaticamente os dados do fornecedor.
- **Campos preenchidos automaticamente:**

| Campo SA2 | Origem ZZ4 |
|-----------|------------|
| `A2_NOME` | `ZZ4_RAZAO` |
| `A2_NREDUZ` | `ZZ4_RAZAO` (truncado) |
| `A2_CGC` | `ZZ4_CNPJ` |
| `A2_TEL` | `ZZ4_NUMERO` (com máscara DDD/número) |
| `A2_EMAIL` | `ZZ4_EMAIL` |
| `A2_INSEST` | `ZZ4_INSEST` |

- **Bloqueios:**
  - `ZZ4` não encontrada → erro.
  - `ZZ4_STATUS = '2'` (Rejeitada) → bloqueia.
  - `ZZ4_STATUS = '1'` (já cadastrada) → avisa e pergunta se continua.
- Suporta tanto `A2_ZSOLID` quanto `A2_ZZ4ID` (compatibilidade).

### 3. `MT020INC.PRW` — Atualiza ZZ4 após incluir fornecedor

- **Função principal:** `User Function MT020INC()`
- **Objetivo:** PE acionado **após salvar** o fornecedor no MATA020.
- **Lógica:** se houver `A2_ZSOLID`/`A2_ZZ4ID` ou CNPJ correspondente, localiza o registro na `ZZ4` e marca:
  - `ZZ4_STATUS = '1'` (Cadastrado)
  - `ZZ4_DTREJ = dDataBase`
- Resultado: a bolinha do `CADFORN` fica **vermelha** (Cadastrado).
- Sempre retorna `.T.` (PE informativo, não bloqueia).

### 4. `MTA020.PRW` — Inicialização do MATA020

- **Função principal:** `User Function MTA020()`
- **Objetivo:** garantir que o alias `ZZ4` esteja aberto **antes** do formulário ativar, para que o `FWLookup` do campo `A2_ZSOLID` consiga localizar o alias.
- Usa `ChkFile("ZZ4")` se a tabela não estiver carregada.
- Loga via `ConOut` para diagnóstico.

### 5. `OPENZZ4.PRW` — Expressão X3_INIBRW do A2_ZSOLID

- **Função principal:** `User Function OPENZZ4()`
- **Objetivo:** chamada por `FWPRESHOW()` em `PROTHEUSLOOKUP.PRW` antes de montar o `FWLookup`.
- Garante que `ZZ4` esteja aberta via `ChkFile`.
- Retorna sempre `.T.` (é uma expressão X3_INIBRW, não validador).

### 6. `ZZ4PEND.PRW` — Browse de ZZ4 pendentes para o FWLookup

- **Função principal:** `User Function ZZ4PEND()`
- **Objetivo:** browse de seleção usado pelo `FWLookup` (SXB Tipo 1 = PROG) do campo `A2_ZSOLID`.
- **Filtro:** apenas solicitações com `ZZ4_STATUS = '0'` (Pendentes).
- **Pré-processamento:** antes de exibir, varre o resultado e atualiza para `STATUS='1'` qualquer `ZZ4` cujo CNPJ já tenha sido cadastrado na `SA2` (limpeza automática).
- Retorna `ZZ4_ID` via `FWLookupRet`.

### 7. `ZCONSZZ4.PRW` — Setup de SXB (executar uma vez)

- **Função principal:** `User Function ZCONSZZ4()`
- **Objetivo:** registrar/atualizar a **consulta padrão ZZ4** no `SXB` seguindo o padrão da `SA1`.
- **Ações:**
  1. Apaga registros antigos (`ZZ4`, `FAMAFO`, `FAMFOR`).
  2. Insere estrutura completa: Tipo 1 (`XB_DESCRI="DB"`), 2, 4, 5, 6 (filtro SQL `@ZZ4_STATUS = '0'`).
- **Aviso:** modifica o dicionário de dados (acessa `SXB` via `RecLock` direto). **Executar apenas uma vez** como admin e reiniciar o Protheus depois.

---

## Bloco 2 — Solicitação de Compra (SC1 / MATA110)

Tríade de PEs/funções que controlam a **data de emissão** e **data de necessidade** dos itens da SC, especialmente em cenários de **inclusão de item novo em SC já existente**.

### 8. `MT110CON.PRW` — TudoOK (pre-save)

- **Função principal:** `User Function MT110CON()`
- **Momento:** disparado **antes da gravação** definitiva (A110GRAVA/A110ALTERA).
- **Responsabilidade:** **preparar contexto** para o PE pos-save `M110STTS`:
  - Captura o número da SC na PRIVATE `cA110Num` (única fonte confiável no contexto MVC/FWFormBrowse).
  - Tira **snapshot** dos itens já gravados (RECNO de cada) ANTES do save.
- **Publics exportados:**
  - `aZ110Snap` → `{{cItem, dEmis, dDatPrf, nRecno}, ...}`
  - `cZ110NumSC` → número da SC.
- **Nota importante:** alterar `aCols` neste PE **não persiste** (gravação via model MVC). A correção real fica no `M110STTS`.

### 9. `MT110EMI.tlpp` — Função do Gatilho SX7 (TLPP)

- **Função principal:** `User Function MT110EMI() as Date`
- **Momento:** chamada pelo **Gatilho SX7** do campo `C1_PROD` da SC1.
- **Objetivo:** retornar sempre `Date()` para `C1_EMISSAO` (data real do servidor).
- **Configuração do gatilho (SX7):**

| Campo SX7 | Valor |
|-----------|-------|
| `X7_CAMPO` | `C1_PROD` |
| `X7_SEQUENC` | `003` |
| `X7_TIPO` | `P` (Primário) |
| `X7_CDOMIN` | `C1_EMISSAO` |
| `X7_REGRA` | `U_MT110EMI()` |
| `X7_CONDIC` | *(vazio — crucial)* |
| `X7_PROPRI` | `U` |

- **Camadas de defesa (3 níveis):**
  1. **Trigger (visual):** `MT110EMI` retorna `Date()` enquanto o usuário digita.
  2. **Pre-save:** `MT110CON` corrige `aCols`.
  3. **Pos-save:** `M110STTS` reescreve no SC1 gravado (neutraliza `X3_RELACAO`).

### 10. `M110STTS.PRW` — PE Pos-save

- **Função principal:** `User Function M110STTS()`
- **Momento:** disparado **após a gravação completa** da SC, antes de voltar ao browse.
- **Objetivo:** corrigir as datas no banco via `RecLock` direto no `SC1`.
- **Regras:**
  - `C1_EMISSAO`:
    - **Item NOVO** (RECNO não consta no snapshot) → `Date()` (hoje).
    - **Item existente** → preserva a emissão original.
  - `C1_DATPRF` (necessidade): havendo **qualquer item novo**, aplica `dDataBase + 15` em **todos** os itens, uniformizando a necessidade.
- Detecção por **RECNO** (imune a colisão/reuso de `C1_ITEM`).
- Sem snapshot confiável → **não altera nada** (segurança).

---

## Bloco 3 — Pedido de Compra (SC7)

### 11. `MTALCFIM.PRW` — Recalcula C7_DATPRF após aprovação

- **Função principal:** `User Function MTALCFIM()`
- **Função auxiliar:** `User Function MT097APR()`
- **Momento de disparo:** a cada aprovação individual no `MATXALC` (controle de alçadas).
- **Fluxo:**
  1. `MTALCFIM` (executado **durante** a aprovação):
     - Captura `cNumPed` e `dDataRef` do `PARAMIXB`.
     - Lê `SCR` para descobrir a **data de aprovação** (`CR_DATALIB`).
     - Armazena em **publics** `_zPCPara` e `_zDtAprov`.
  2. `MT097APR` (executado **após** `C7_CONAPRO` ser atualizado para `'L'`):
     - Recupera os dados via `Public`.
     - **Recalcula `C7_DATPRF`** dos itens do PC com base na data de aprovação.
- **Robustez:** fallback que busca o último PC aprovado na `SCR` caso as publics estejam vazias.

### 12. `ZANAFRETE.PRW` — Relatório de Pedidos por Tipo de Frete

- **Função principal:** `User Function ZANAFRETE()`
- **Objetivo:** exibir todos os PCs do período classificados por tipo de frete.
- **Parâmetros (ParamBox):** Data Inicial e Data Final.
- **Classificação:**

| Tipo | Condição |
|------|----------|
| CIF | `C7_TPFRETE = 'C'` |
| FOB | `C7_TPFRETE = 'F'` |
| Sem Frete | `C7_TPFRETE = 'S'` |
| Vazio | `C7_TPFRETE = ''` (ou null) |

- **Recursos:**
  - Indicadores consolidados no topo (quantidade + valor por tipo).
  - **Exportação Excel** via `FWMSExcelX`.
  - Query otimizada com join em `SA2` (nome do fornecedor) e filtros `D_E_L_E_T_`, `C7_RESIDUO<>'S'`, `C7_QUANT>0`.
- **Estatísticas globais** (Static) preservam totalizadores entre chamadas.

### 13. `ZLOGCOL.prw` — Controle Logístico de Pedidos Aprovados

- **Função principal:** `User Function ZLOGCOL()`
- **Objetivo:** `FWMarkBrowse` sobre a `SC7` para controlar **coleta x recebimento** de PCs aprovados.
- **Filtro padrão:** `FiltroPendentesDBF()` (somente aprovados não totalmente recebidos).
- **Legenda:**

| Cor | Condição | Significado |
|-----|----------|-------------|
| 🟢 Verde | `C7_QUJE == 0` | Aprovado — Aguardando coleta |
| 🟡 Amarelo | `0 < C7_QUJE < C7_QUANT` | Recebimento parcial |
| 🔴 Vermelho | `C7_QUJE >= C7_QUANT` | Totalmente recebido |

- **Recursos:**
  - Marcação individual por pedido (`C7_OK`).
  - **Rascunho** persistido (status `RASC%`) e recuperação ao reabrir.
  - **Geração de solicitações de coleta** (gravação em `ZZ3`) para itens marcados.
  - Colunas customizadas definidas por `ColunasBrowse()`.
  - Múltiplas funções auxiliares (mais de 3.800 linhas no total) — interface completa de gestão logística.

---

## Resumo de Pontos de Entrada (PE)

| PE | Arquivo | Tabela | Momento |
|----|---------|--------|---------|
| `MTA020` | `MTA020.PRW` | SA2 | Inicialização |
| `MT020INC` | `MT020INC.PRW` | SA2 | Após incluir |
| `FFZZ4A2` | `FFZZ4A2.PRW` | SA2 | Valid do campo `A2_ZZ4ID` |
| `OPENZZ4` | `OPENZZ4.PRW` | SA2 | X3_INIBRW de `A2_ZSOLID` |
| `ZZ4PEND` | `ZZ4PEND.PRW` | ZZ4 | SXB (FWLookup) |
| `MT110CON` | `MT110CON.PRW` | SC1 | TudoOK (pre-save) |
| `MT110EMI` | `MT110EMI.tlpp` | SC1 | Gatilho SX7 (`C1_PROD`) |
| `M110STTS` | `M110STTS.PRW` | SC1 | Pos-save |
| `MTALCFIM` | `MTALCFIM.PRW` | SC7 | Aprovação (MATXALC) |
| `MT097APR` | `MTALCFIM.PRW` | SC7 | Pós-aprovação (A097LIBERA) |

---

## Tabelas Envolvidas

| Alias | Tipo | Observação |
|-------|------|------------|
| `SA2` | Cadastro | Fornecedores (vinculação via `A2_ZSOLID`/`A2_ZZ4ID`) |
| `SC1` | Movimento | Solicitações de Compra |
| `SC7` | Movimento | Pedidos de Compra |
| `SCR` | Movimento | Controle de alçadas (aprovações) |
| `SF4` | Cadastro | Tipos de Entrada/Saída (consultado em fluxos) |
| `ZZ3` | Custom | Solicitações de Coleta (geradas pelo ZLOGCOL) |
| `ZZ4` | Custom | Solicitações Cadastrais de Fornecedores |
| `SX2/SX3/SXB/SX7` | Dicionário | Configuração de campos/consultas/gatilhos |

---

## Convenções e Padrões Aplicados

- **Notação húngara** TOTVS: `c`=char, `n`=num, `d`=date, `l`=lógico, `a`=array, `o`=objeto.
- **Documentação** Protheus.doc em todos os fontes.
- **`GetArea()` / `RestArea()`** em todo acesso a alias.
- **`xFilial("ALIAS")`** em filtros por filial — nunca hardcoded.
- **SQL:** preferência por `BeginSql/EndSql` com `%Table:%` e `%NotDel%`. Onde concatenado, `xFilial` e `DtoS` vêm de variáveis controladas.
- **Comparação CNPJ:** `REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(campo)),'.',''),'/',''),'-','')` para unificar formato.
- **Encoding:** `CP1252` (Windows-1252) — padrão Protheus 12.

---

## Observações Operacionais

1. **Ordem de compilação recomendada:** fontes sem dependência primeiro (MTA020, OPENZZ4, ZZ4PEND, ZCONSZZ4), depois CADFORN/FFZZ4A2/MT020INC, depois bloco MATA110 (MT110EMI, MT110CON, M110STTS), depois bloco SC7 (MTALCFIM, ZANAFRETE, ZLOGCOL).
2. **`ZCONSZZ4.PRW` é SETUP único:** executar uma vez para criar a consulta no SXB e reiniciar o Appserver.
3. **`MT110EMI.tlpp` é TLPP** (resto do bloco MATA110 é AdvPL) — exigência do framework SX7 com `X7_TIPO='P'`.
4. **`MTALCFIM` + `MT097APR`:** trabalham em par via publics (`_zPCPara`, `_zDtArov`) — ambos precisam estar compilados juntos.
