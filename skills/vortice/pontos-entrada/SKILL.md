---
name: pontos-entrada
description: 'Skill Vortice custom pontos-entrada - SC7/CINVJ6_DEV 7.00.240223P'
---

# Skill: Pontos de Entrada â€” SIGAEST

> CatÃ¡logo completo dos Pontos de Entrada implementados no projeto.
> Consulte esta skill antes de implementar qualquer customizaÃ§Ã£o nova.

---
## MATA010 â€” Cadastro de Produtos (SB1)

| PE | Arquivo | DescriÃ§Ã£o |
|----|---------|-----------|
| **MT010ALT** | `MT010ALT.PRW` | PÃ³s-alteraÃ§Ã£o: atualiza `B1_ZDTALT` com a data atual |
| **A010TOK** | `A010TOK.PRW` | TudoOK: validaÃ§Ã£o geral ao confirmar |
| **VOGSB101** | `VOGSB101.prw` | Trigger SX7: preenche `B1_ZDTINC`, `B1_ZDTALT`, `B1_ZUSINC`, `B1_ZUSALT` |

**PARAMIXB**: PadrÃ£o MATA010 â€” sem PARAMIXB documentado.

---
## MATA020 â€” Cadastro de Fornecedores (SA2)

Rastreabilidade completa: SolicitaÃ§Ã£o Cadastral (ZZ4) â†’ Cadastro (SA2).

| PE | Arquivo | DescriÃ§Ã£o |
|----|---------|-----------|
| **MTA020** | `MTA020.PRW` | InicializaÃ§Ã£o: garante ZZ4 aberta (`ChkFile`) para FWLookup do campo A2_ZZ4ID |
| **MT020INC** | `MT020INC.PRW` | PÃ³s-inclusÃ£o: localiza ZZ4 por ID ou CNPJ e marca `STATUS='1'` (Cadastrado) |
| **MT020ATE** | `MT020ATE.PRW` | Filtro adicional: abre ZZ4 na inicializaÃ§Ã£o |
| **M020EXC** | `M020EXC.PRW` | Durante exclusÃ£o: reverte ZZ4 para `STATUS='0'` (Pendente) |
| **MT20FOPOS** | `MT20FOPOS.PRW` | PÃ³s-gravaÃ§Ã£o: marca ZZ4 como Cadastrada independente do modo |
| **FFZZ4A2** | `FFZZ4A2.PRW` | FunÃ§Ã£o Valid do campo `A2_ZZ4ID`: preenche SA2 a partir da ZZ4 (nome, CNPJ, tel, email, IE, IM, contato, simples) |

**PARAMIXB MT020INC/MT20FOPOS**: `[1]=cFilial, [2]=cCodForn`. LÃª dados da SA2 jÃ¡ posicionada.

**PARAMIXB M020EXC**: PadrÃ£o TOTVS â€” sem doc especÃ­fica. Acessa `SA2->A2_CGC` como fallback.

---
## MATA094 â€” LiberaÃ§Ã£o de Documentos (SCR)

| PE | Arquivo | DescriÃ§Ã£o |
|----|---------|-----------|
| **MTA094RO** | `MTA094RO.PRW` | Adiciona botÃ£o "Comparar Ult. Compra" na rotina de liberaÃ§Ã£o |

**PARAMIXB MTA094RO**: `[1]=aRotina` (array de botÃµes da rotina). Retorna `aRotina` modificado.

**COMPULT** (`U_COMPULT()`): Busca o documento na SCR, percorre SC7 e compara com SD3 para identificar itens fora do padrÃ£o de compra.

---
## MATA100 / MATA101 â€” SolicitaÃ§Ã£o de Compra (SC1)

| PE | Arquivo | DescriÃ§Ã£o |
|----|---------|-----------|
| **MT100OK** | `MT100OK.PRW` | PrÃ©-save (todos os modos): seta `C1_DATPRF = Date() + 15` em todos os itens do grid via `aCols` |
| **MT101OK** | `MT101OK.PRW` | ValidaÃ§Ã£o por linha: ajusta `C1_EMISSAO` e `C1_DATPRF` em itens novos |

**PARAMIXB MT100OK/MT101OK**: PadrÃ£o MATA100 â€” acessa `aHeader`/`aCols` do grid.

---
## MATA103 â€” Documento de Entrada (SD1)

| PE | Arquivo | DescriÃ§Ã£o |
|----|---------|-----------|
| **MT100TOK** | `MT100TOK.PRW` | TudoOK: valida conta contÃ¡bil `11401200001` na linha do documento |

**PARAMIXB**: PadrÃ£o MATA103.

---
## MATA105 â€” SolicitaÃ§Ã£o ao ArmazÃ©m (CP)

| PE | Arquivo | DescriÃ§Ã£o |
|----|---------|-----------|
| **MTA105OK** | `MTA105OK.PRW` | ValidaÃ§Ã£o: bloqueia se saldo do produto for zero ou insuficiente |

**PARAMIXB**: PadrÃ£o MATA105.

---
## MATA110 â€” ManutenÃ§Ã£o de SC (SC1)

ResponsÃ¡vel pela gestÃ£o de datas de emissÃ£o e necessidade dos itens.

| PE | Arquivo | DescriÃ§Ã£o |
|----|---------|-----------|
| **MTA110OK** | `MTA110OK.PRW` | ValidaÃ§Ã£o: obriga preenchimento de `C1_EC05DB` |
| **MT110TOK** | `MT110TOK.PRW` | TudoOK: bloqueia itens com `B1_ESTSEG > 0` (exceto usuarios: 000047, 000080, 000095, 000057). Ajusta `C1_EMISSAO` para `Date()` em itens novos |
| **MT110CON** | `MT110CON.PRW` | PrÃ©-save: captura nÂº da SC e tira snapshot dos itens existentes (RECNO) para o PE pÃ³s-save M110STTS |
| **M110STTS** | `M110STTS.PRW` | PÃ³s-save: corrige `C1_EMISSAO` e `C1_DATPRF` nos itens novos (identificados pelo snapshot do MT110CON) |
| **MT110EMI** | `MT110EMI.tlpp` | Trigger SX7: ao informar `C1_PROD`, preenche `C1_EMISSAO` automaticamente |
| **MT110LOK** | `_arquivos-movidos-da-patch/MT110LOK.PRW` | ValidaÃ§Ã£o de linha (stub/bloqueio de linha) |

**PARAMIXB MT110CON**: `[1]=cCampo, [2]=xValor, [3]=nLinha, [4]=cNumSC, [5]=lInc`. Retorna `PARAMIXB[1]` como `.T./.F.`

**PARAMIXB MT110TOK**: PadrÃ£o MATA110 â€” acessa `aHeader`/`aCols`.

**Fluxo MT110CON â†’ M110STTS**: 
1. MT110CON captura `cA110Num` e tira snapshot `{C1_ITEM, C1_EMISSAO, C1_DATPRF, RECNO}` em `PUBLIC aZ110Snap`
2. ApÃ³s o save, M110STTS compara snapshot com registros atuais; itens sem RECNO no snapshot sÃ£o NOVOS e recebem `C1_EMISSAO` corrigida

---
## MATA120 â€” Pedido de Compra (SC7)

| PE | Arquivo | DescriÃ§Ã£o |
|----|---------|-----------|
| **MT120OK** | `MT120OK.PRW` | PrÃ©-save: valida conta contÃ¡bil, propaga `C7_TPFRETE` |
| **MT120TFR** | `MT120TFR.PRW` | Trigger SX7: propaga `C7_TPFRETE` para todos os itens |
| **MT120GOK** | `MTA110OK.PRW` | Replica `C8_EC05DB` da cotaÃ§Ã£o para o pedido |

---
## MATA131 â€” CotaÃ§Ã£o (SC8)

| PE | Arquivo | DescriÃ§Ã£o |
|----|---------|-----------|
| **MTA131C8** | `MTA131C8.PRW` | `LoadValue`: carrega `C8_EC05DB` e `C8_ZUPRC` da SC1 na cotaÃ§Ã£o |
| **MT131WF** | `MTA110OK.PRW` | Replica `C1_EC05DB` da SC â†’ `C8_EC05DB` na cotaÃ§Ã£o |

**PARAMIXB MTA131C8**: `[1]=oModFor` (model FW da SC8). Usa `oModFor:LoadValue("C8_EC05DB", valor)`.

**PARAMIXB MT131WF**: `[1]=cNumCot` (nÃºmero da cotaÃ§Ã£o).

---
## MATA150 â€” ParÃ¢metros de Compra

| PE | Arquivo | DescriÃ§Ã£o |
|----|---------|-----------|
| **MT150GET** | `MT150GET.prw` | PrÃ©-busca: preenche `C8_EC05DB` a partir da SC1 |

---
## MATA160 â€” GeraÃ§Ã£o de Pedido de CotaÃ§Ã£o

| PE | Arquivo | DescriÃ§Ã£o |
|----|---------|-----------|
| **MT160GRPC** | `MT160GRPC.prw` | GeraÃ§Ã£o: transfere `C8_XESTOC` â†’ `C7_XESTOQ1` |

---
## Demais PEs do Projeto

| Programa | PE | Arquivo | DescriÃ§Ã£o |
|----------|----|---------|-----------|
| VÃ¡rios | VOGSB101 | `VOGSB101.prw` | Trigger SX7 genÃ©rica para SB1 (datas/usuÃ¡rio) |
| VÃ¡rios | VORATF01 | `VORATF01.prw` | FunÃ§Ã£o auxiliar de rateio |
| VÃ¡rios | VOREST02 | `VOREST02.PRW` | FunÃ§Ã£o auxiliar de estoque |

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

> âš  **Sempre verificar se o PE jÃ¡ existe antes de criar um novo.**
> âš  **Nome mÃ¡ximo de 10 caracteres para User Function.**
> âš  **Validar PARAMIXB com `ValType()` ou `Type()` antes de usar.**

