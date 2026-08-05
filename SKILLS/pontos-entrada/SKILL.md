# Skill: Pontos de Entrada — SIGAEST

> Catálogo completo dos Pontos de Entrada implementados no projeto.
> Consulte esta skill antes de implementar qualquer customização nova.

---
## MATA010 — Cadastro de Produtos (SB1)

| PE | Arquivo | Descrição |
|----|---------|-----------|
| **MT010ALT** | `MT010ALT.PRW` | Pós-alteração: atualiza `B1_ZDTALT` com a data atual |
| **A010TOK** | `A010TOK.PRW` | TudoOK: validação geral ao confirmar |
| **VOGSB101** | `VOGSB101.prw` | Trigger SX7: preenche `B1_ZDTINC`, `B1_ZDTALT`, `B1_ZUSINC`, `B1_ZUSALT` |

**PARAMIXB**: Padrão MATA010 — sem PARAMIXB documentado.

---
## MATA020 — Cadastro de Fornecedores (SA2)

Rastreabilidade completa: Solicitação Cadastral (ZZ4) → Cadastro (SA2).

| PE | Arquivo | Descrição |
|----|---------|-----------|
| **MTA020** | `MTA020.PRW` | Inicialização: garante ZZ4 aberta (`ChkFile`) para FWLookup do campo A2_ZZ4ID |
| **MT020INC** | `MT020INC.PRW` | Pós-inclusão: localiza ZZ4 por ID ou CNPJ e marca `STATUS='1'` (Cadastrado) |
| **MT020ATE** | `MT020ATE.PRW` | Filtro adicional: abre ZZ4 na inicialização |
| **M020EXC** | `M020EXC.PRW` | Durante exclusão: reverte ZZ4 para `STATUS='0'` (Pendente) |
| **MT20FOPOS** | `MT20FOPOS.PRW` | Pós-gravação: marca ZZ4 como Cadastrada independente do modo |
| **FFZZ4A2** | `FFZZ4A2.PRW` | Função Valid do campo `A2_ZZ4ID`: preenche SA2 a partir da ZZ4 (nome, CNPJ, tel, email, IE, IM, contato, simples) |

**PARAMIXB MT020INC/MT20FOPOS**: `[1]=cFilial, [2]=cCodForn`. Lê dados da SA2 já posicionada.

**PARAMIXB M020EXC**: Padrão TOTVS — sem doc específica. Acessa `SA2->A2_CGC` como fallback.

---
## MATA094 — Liberação de Documentos (SCR)

| PE | Arquivo | Descrição |
|----|---------|-----------|
| **MTA094RO** | `MTA094RO.PRW` | Adiciona botão "Comparar Ult. Compra" na rotina de liberação |

**PARAMIXB MTA094RO**: `[1]=aRotina` (array de botões da rotina). Retorna `aRotina` modificado.

**COMPULT** (`U_COMPULT()`): Busca o documento na SCR, percorre SC7 e compara com SD3 para identificar itens fora do padrão de compra.

---
## MATA100 / MATA101 — Solicitação de Compra (SC1)

| PE | Arquivo | Descrição |
|----|---------|-----------|
| **MT100OK** | `MT100OK.PRW` | Pré-save (todos os modos): seta `C1_DATPRF = Date() + 15` em todos os itens do grid via `aCols` |
| **MT101OK** | `MT101OK.PRW` | Validação por linha: ajusta `C1_EMISSAO` e `C1_DATPRF` em itens novos |

**PARAMIXB MT100OK/MT101OK**: Padrão MATA100 — acessa `aHeader`/`aCols` do grid.

---
## MATA103 — Documento de Entrada (SD1)

| PE | Arquivo | Descrição |
|----|---------|-----------|
| **MT100TOK** | `MT100TOK.PRW` | TudoOK: valida conta contábil `11401200001` na linha do documento |

**PARAMIXB**: Padrão MATA103.

---
## MATA105 — Solicitação ao Armazém (CP)

| PE | Arquivo | Descrição |
|----|---------|-----------|
| **MTA105OK** | `MTA105OK.PRW` | Validação: bloqueia se saldo do produto for zero ou insuficiente |

**PARAMIXB**: Padrão MATA105.

---
## MATA110 — Manutenção de SC (SC1)

Responsável pela gestão de datas de emissão e necessidade dos itens.

| PE | Arquivo | Descrição |
|----|---------|-----------|
| **MTA110OK** | `MTA110OK.PRW` | Validação: obriga preenchimento de `C1_EC05DB` |
| **MT110TOK** | `MT110TOK.PRW` | TudoOK: bloqueia itens com `B1_ESTSEG > 0` (exceto usuarios: 000047, 000080, 000095, 000057). Ajusta `C1_EMISSAO` para `Date()` em itens novos |
| **MT110CON** | `MT110CON.PRW` | Pré-save: captura nº da SC e tira snapshot dos itens existentes (RECNO) para o PE pós-save M110STTS |
| **M110STTS** | `M110STTS.PRW` | Pós-save: corrige `C1_EMISSAO` e `C1_DATPRF` nos itens novos (identificados pelo snapshot do MT110CON) |
| **MT110EMI** | `MT110EMI.tlpp` | Trigger SX7: ao informar `C1_PROD`, preenche `C1_EMISSAO` automaticamente |
| **MT110LOK** | `_arquivos-movidos-da-patch/MT110LOK.PRW` | Validação de linha (stub/bloqueio de linha) |

**PARAMIXB MT110CON**: `[1]=cCampo, [2]=xValor, [3]=nLinha, [4]=cNumSC, [5]=lInc`. Retorna `PARAMIXB[1]` como `.T./.F.`

**PARAMIXB MT110TOK**: Padrão MATA110 — acessa `aHeader`/`aCols`.

**Fluxo MT110CON → M110STTS**: 
1. MT110CON captura `cA110Num` e tira snapshot `{C1_ITEM, C1_EMISSAO, C1_DATPRF, RECNO}` em `PUBLIC aZ110Snap`
2. Após o save, M110STTS compara snapshot com registros atuais; itens sem RECNO no snapshot são NOVOS e recebem `C1_EMISSAO` corrigida

---
## MATA120 — Pedido de Compra (SC7)

| PE | Arquivo | Descrição |
|----|---------|-----------|
| **MT120OK** | `MT120OK.PRW` | Pré-save: valida conta contábil, propaga `C7_TPFRETE` |
| **MT120TFR** | `MT120TFR.PRW` | Trigger SX7: propaga `C7_TPFRETE` para todos os itens |
| **MT120GOK** | `MTA110OK.PRW` | Replica `C8_EC05DB` da cotação para o pedido |

---
## MATA131 — Cotação (SC8)

| PE | Arquivo | Descrição |
|----|---------|-----------|
| **MTA131C8** | `MTA131C8.PRW` | `LoadValue`: carrega `C8_EC05DB` e `C8_ZUPRC` da SC1 na cotação |
| **MT131WF** | `MTA110OK.PRW` | Replica `C1_EC05DB` da SC → `C8_EC05DB` na cotação |

**PARAMIXB MTA131C8**: `[1]=oModFor` (model FW da SC8). Usa `oModFor:LoadValue("C8_EC05DB", valor)`.

**PARAMIXB MT131WF**: `[1]=cNumCot` (número da cotação).

---
## MATA150 — Parâmetros de Compra

| PE | Arquivo | Descrição |
|----|---------|-----------|
| **MT150GET** | `MT150GET.prw` | Pré-busca: preenche `C8_EC05DB` a partir da SC1 |

---
## MATA160 — Geração de Pedido de Cotação

| PE | Arquivo | Descrição |
|----|---------|-----------|
| **MT160GRPC** | `MT160GRPC.prw` | Geração: transfere `C8_XESTOC` → `C7_XESTOQ1` |

---
## Demais PEs do Projeto

| Programa | PE | Arquivo | Descrição |
|----------|----|---------|-----------|
| Vários | VOGSB101 | `VOGSB101.prw` | Trigger SX7 genérica para SB1 (datas/usuário) |
| Vários | VORATF01 | `VORATF01.prw` | Função auxiliar de rateio |
| Vários | VOREST02 | `VOREST02.PRW` | Função auxiliar de estoque |

---
## Template para Criar Novo PE

```
/*/{Protheus.doc} NOMEFUNC
    Descricao do ponto de entrada.
    @param   PARAMIXB, array, parametros do ponto de entrada
    @return  lRet, logical, .T. se sucesso
    @see     Programa chamador: SIGAXXX
/*/
User Function NOMEFUNC()
    Local aArea := GetArea()
    Local lRet  := .T.

    // Logica do PE

    RestArea(aArea)
Return lRet
```

> ⚠ **Sempre verificar se o PE já existe antes de criar um novo.**
> ⚠ **Nome máximo de 10 caracteres para User Function.**
> ⚠ **Validar PARAMIXB com `ValType()` ou `Type()` antes de usar.**
