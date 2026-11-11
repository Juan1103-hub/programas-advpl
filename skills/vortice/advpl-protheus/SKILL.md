---
name: advpl-protheus
description: Skill canonica do workspace Vortice para desenvolvimento ADVPL/TLPP em Protheus 12.1.33 (Suprimentos/Compras). Inclui includes, estrutura de funcoes, padroes de banco de dados, UI e checklist de qualidade obrigatorio.
---

# ADVPL/Protheus — Skill Canonica do Workspace Vortice

## Visao Geral

Skill derivada dos padroes reais identificados nos 49 arquivos `.PRW` do workspace
`programas_vortice`. Cobertura: Protheus 12.1.33, modulo Suprimentos/Compras,
tabelas customizadas (SZ3, ZZ3, ZZ4), pontos de entrada (MATA110, MATA020,
MATA103, MATA094), telas customizadas (mBrowse + MSDIALOG + LISTBOX + TCBrowse)
e relatorios gerenciais (TReport + Excel).

Arquivos de referencia canonicos (nao modificar sem justificativa):
- **Telas/Cadastro**: `CADSZ3.PRW` — mBrowse + aRotina + aCores + MSDIALOG + TCBrowse + RecLock
- **Pontos de Entrada**: `MTA110OK.PRW` — PARAMIXB + aHeader/aCols + ConOut + replicacao SC1->SC8->SC7
- **Relatorios/Analise**: `ZANALBX.PRW` — ParamBox + SQL TopConn + LISTBOX pivot + TReport export Excel

## Quando Usar

- Criar ou revisar qualquer arquivo `.PRW` ou `.TLPP`
- Implementar pontos de entrada (PEs) para modulos Suprimentos
- Construir telas customizadas com mBrowse/MSDIALOG/LISTBOX/TCBrowse
- Gerar relatorios gerenciais com TReport ou exportacao Excel
- Escrever consultas SQL via TopConnect (TcQuery/BeginSQL)
- Configurar dicionario SX (SX3/SIX/SX1/SX5)
- Depurar erros de compilacao ou runtime em Protheus

## Includes Obrigatorios

Todo arquivo `.PRW` deve comecar com estes includes:

```advpl
#Include "Protheus.ch"
#Include "TopConn.ch"
```

Para arquivos que usam TReport, adicione:
```advpl
#Include "Report.ch"
```

Constantes auxiliares opcionais (copiar de CADSZ3.PRW se necessario):
```advpl
#Define ENTER  Chr(10) + Chr(13)  // Salto de linha
```

## Estrutura Canonica de User Function

Todo `User Function` deve seguir este padrao (baseado em `CADSZ3.PRW`):

```advpl
#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} NOME_FUNC
Descricao breve do que a funcao faz.

@type    User Function
@version 12.1.33
@author  Suprimentos
@since   DD/MM/YYYY
/*/
User Function NOME_FUNC()

    Local aArea := GetArea()

    // ... logica ...

    RestArea(aArea)

Return
```

### Pontos criticos da estrutura:
1. **Cabecalho Protheus.doc** OBRIGATORIO em todas as funcoes (User e Static)
2. **Local aArea := GetArea()** na primeira linha do corpo
3. **RestArea(aArea)** na ultima linha antes do Return
4. **Return** sem parenteses para void; `Return(xRet)` para retorno de valor
5. Funcoes auxiliares como `Static Function` (nao expostas ao roster)
6. Wrappers `User Function` necessarios quando aRotina chama Static Functions

## Estrutura Canonica de Ponto de Entrada

Baseado em `MTA110OK.PRW`:

```advpl
#Include "Protheus.ch"

/*/{Protheus.doc} NOME_PE
Descricao do que o PE faz e em qual rotina dispara.

@type User Function
@author Sistema
@since DD/MM/YYYY
/*/
User Function NOME_PE()
    Local lRet     := .T.
    Local nPosCamp := aScan(aHeader, {|x| AllTrim(x[2]) == "C1_CAMPO"})
    Local nX       := 0

    ConOut("========================================")
    ConOut("NOME_PE - Descricao da validacao")
    ConOut("========================================")

    If nPosCamp > 0
        For nX := 1 To Len(aCols)
            If !aCols[nX][Len(aHeader)+1]  // linha nao deletada
                If Empty(aCols[nX][nPosCamp])
                    Help(,, "CAMPO OBRIGATORIO",, ;
                         "O campo X e obrigatorio" + CRLF + ;
                         "Linha: " + cValToChar(nX), ;
                         1, 0,,,,,, {"Preencha o campo antes de salvar"})
                    lRet := .F.
                    Exit
                EndIf
            EndIf
        Next nX
    EndIf

    ConOut("Validacao " + IIf(lRet, "OK", "FALHOU"))

Return lRet
```

### Regras especificas de PEs:
- Sempre logar com `ConOut("[PE_NAME] mensagem")` para rastreabilidade
- Validar `ValType(PARAMIXB)` e `Len(PARAMIXB)` antes de acessar elementos
- Verificar `nPosCampo > 0` (aScan) antes de acessar aCols por posicao
- Linha deletada = `aCols[nX][Len(aHeader)+1]` == `.T.`
- Para PEs de aprovacao (MATA094/SCR): verificar `C7_CONAPRO == 'L'` antes de recalcular
- Compartilhar dados entre PEs via `Public` (nao `Private` — escopo nao cruza fronteira de PE)

## Padroes de Banco de Dados

### Filtro de Filial
SEMPRE usar `xFilial("ALIAS")` — nunca hardcoded:
```advpl
cQuery += " AND C7_FILIAL = '" + xFilial("SC7") + "'"
```

### Consulta SQL via TopConnect (TcQuery)
Padrao canonico (de `ZANALBX.PRW` e `CADSZ3.PRW`):
```advpl
Local cAlias := GetNextAlias()
Local cQuery := ""

cQuery := " SELECT D3_COD, D3_QUANT "
cQuery += " FROM " + RetSqlName("SD3") + " D3 "
cQuery += " WHERE D3.D_E_L_E_T_ = ' ' "
cQuery += "   AND D3.D3_FILIAL = '" + xFilial("SD3") + "' "
cQuery += "   AND D3.D3_EMISSAO >= '" + DtoS(dDtDe) + "' "
cQuery := ChangeQuery(cQuery)

If Select(cAlias) > 0
    (cAlias)->(DbCloseArea())
EndIf

DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)

(cAlias)->(DbGoTop())
While !(cAlias)->(Eof())
    // processar
    (cAlias)->(DbSkip())
EndDo

(cAlias)->(DbCloseArea())
```

### Consulta SQL via Embedded SQL (BeginSQL)
Alternativa moderna preferida para novas queries:
```advpl
BeginSQL Alias cAlias
    SELECT D3_COD, D3_QUANT
    FROM %Table:SD3% D3
    WHERE D3.%NotDel%
      AND D3_FILIAL = %xFilial:SD3%
      AND D3_EMISSAO >= %Exp:DtoS(dDtDe)%
    ORDER BY D3_COD
EndSQL
```

### Gravacao — RecLock (APENAS tabelas customizadas Z*)
```advpl
DbSelectArea("SZ3")
DbSetOrder(1)
If RecLock("SZ3", .T.)  // .T. = inclusao, .F. = alteracao
    Replace Z3_FILIAL With xFilial("SZ3")
    Replace Z3_ID     With cCodId
    Replace Z3_DESCRI With UPPER(AllTrim(cDescProd))
    MsUnlock()
EndIf
```

### Gravacao — MSExecAuto ( tabelas core do Protheus)
**NUNCA** use RecLock para criar/alterar registros em tabelas core (SC1, SC7, SC8,
SD1, SD2, SF1, SF2, SB1, SA2, etc.). Sempre use MSExecAuto:
```advpl
Private lMsErroAuto := .F.
Private lMsHelpAuto := .T.

aVetor := { {"C1_NUM", cNum, Nil}, {"C1_ITEM", cItem, Nil}, ... }
MSExecAuto({|x,y| MATA110(x,y)}, aVetor, 3)  // 3=Inclusao

If lMsErroAuto
    MostraErro()
EndIf
```

### Sequencial customizado (MAX+1)
Padrao de `CADSZ3.PRW:FSEQSZ3`:
```advpl
Static Function FSEQSZ3()
    Local cAls   := GetNextAlias()
    Local cQuery := ""
    Local cMax   := "000000"
    Local cNext  := "000001"

    cQuery := "SELECT MAX(Z3_ID) AS MAXID FROM " + RetSQLName("SZ3")
    cQuery += " WHERE D_E_L_E_T_ = ' ' AND Z3_FILIAL = '" + xFilial("SZ3") + "'"
    cQuery := ChangeQuery(cQuery)

    If Select(cAls) > 0
        (cAls)->(DbCloseArea())
    EndIf
    DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAls, .F., .T.)
    cMax := IIF(Empty((cAls)->MAXID), "000000", AllTrim((cAls)->MAXID))
    (cAls)->(DbCloseArea())

    If Empty(cMax) .Or. cMax == "000000"
        cNext := "000001"
    Else
        cNext := Soma1(cMax, 6)
    EndIf

Return(cNext)
```

### Limpeza de data
NUNCA usar `NULL` via SQL para limpar campo data. Usar:
```advpl
Replace Z3_DTREJ With CtoD("  /  /  ")     // AdvPL
// ou via SQL:
cQuery += " Replace Z3_DTREJ With CtoD('  /  /  ') "  // nao usar NULL
```

### Validacao antes de ler registro
```advpl
DbSelectArea("SZ3")
If SZ3->(Eof()) .Or. SZ3->(Bof())
    MsgStop("Nenhum registro selecionado.", "Atencao")
    Return
EndIf
```

## Padroes de UI

### mBrowse + aRotina + aCores (Cadastro)
Padrao de `CADSZ3.PRW`:
```advpl
Private cCadastro := "Titulo do Cadastro"
Private cString   := "SZ3"

Private aCores := { ;
    {"SZ3->Z3_STATUS == '0'", "BR_BRANCO"}, ;
    {"SZ3->Z3_STATUS == '1'", "DISABLE"  }, ;
    {"SZ3->Z3_STATUS == '2'", "BR_PRETO" } }

Private aRotina := { ;
    {"Incluir"   , "U_FUNCINC", 0, 3}, ;
    {"Alterar"   , "U_FUNCALT", 0, 3}, ;
    {"Visualizar", "U_FUNCVIS", 0, 2}, ;
    {"Pesquisar" , "AxPesqui",  0, 1}, ;
    {"Excluir"   , "U_FUNCDEL", 0, 5}, ;
    {"Legenda"   , "U_FUNCLEG", 0, 6} }

mBrowse(6, 1, 22, 75, "SZ3", , , , , , aCores)
```

### MSDIALOG + LISTBOX (Analise/Relatorio)
Padrao de `ZANALBX.PRW` (layout inviolavel):
```
MSDIALOG: FROM 0,0 TO 650,1300 PIXEL (ou 650,1400)
Filtros:  linha @5,   height 10px
Botoes:   linha @20,  height 12-14px
LISTBOX:  @40,5 SIZE 640,260 (ou 690,115 dependendo do contexto)
Botao Fechar (sub-janela): @20,1240 SIZE 50,12
Titulo deve mostrar contagem: "Title - " + cValToChar(Len(aArray))
ACTIVATE MSDIALOG ... CENTERED
```

### LISTBOX com SetArray + bLine + aColSizes
```advpl
@ 168, 005 LISTBOX oList FIELDS HEADER ;
    "Codigo", "Descricao", "Qtd Total" ;
    SIZE 690, 115 OF oDlg PIXEL

oList:SetArray(aResumo)
oList:bLine := {|| {;
    AllTrim(aResumo[oList:nAt][1]), ;
    AllTrim(aResumo[oList:nAt][2]), ;
    Transform(aResumo[oList:nAt][3], "@E 999,999.99")}}

oList:aColSizes := {70, 165, 50}
```

### Algoritmo de Largura de Colunas (apos SetArray)
```advpl
nSumMin := 0; aFinalCols := {}
For nI := 1 To Len(aMinCols): nSumMin += aMinCols[nI]: Next
If nSumMin <= nListWidth
    nExtra := nListWidth - nSumMin
    For nI := 1 To Len(aMinCols)
        nVal := aMinCols[nI] + IIf(nI == 2, nExtra, 0)
        aAdd(aFinalCols, nVal)
    Next
Else
    For nI := 1 To Len(aMinCols)
        nVal := Round(aMinCols[nI] * nListWidth / nSumMin, 0)
        aAdd(aFinalCols, nVal)
    Next
EndIf
oL:aColSizes := aFinalCols
```

Larguras minimas por tipo: Codigo=55, Descricao=160, CC=85, Qtd=55,
Vlr Unit=70-75, Vlr Total=50-60, Data=45, Pedido=40, Fornecedor=120,
Status=60, Comprador=100

### TReport (Exportacao Excel/PDF)
Padrao de `ZANALBX.PRW:ZANALBX_XR`:
```advpl
oReport := TReport():New("NOME", "Titulo", "", ;
    {|oReport| FUNC_PRINT(oReport, aDados)}, "Descricao")

oReport:SetLandscape(.T.)
oReport:SetTotalInLine(.F.)

oSection := TRSection():New(oReport, "Secao", {})
TRCell():New(oSection, "CODIGO", "", "Codigo", "@!", 15)
TRCell():New(oSection, "DESCR",  "", "Desc",   "@!", 30)

oReport:PrintDialog()
```

> **REGRA CRITICA**: Ao executar relatorios TReport via `oReport:PrintDialog()`, o usuario deve SEMPRE selecionar **"Build"** (executar/gerar) e nunca **"Plan"** (pre-visualizar). O modo Build gera o Excel/PDF/HTML direto; o modo Plan consome recursos do RPO sem necessidade. Documente esta regra sempre que criar ou modificar um TReport.

### ParamBox (Filtros de relatorio/analise)
```advpl
Local aPar := {}
Local aRet := {}

aAdd(aPar, {1, "Data Inicial", dDtDe,  "", "", "", "", 60, .T.})  // 1=get data
aAdd(aPar, {1, "Data Final",   dDtAte, "", "", "", "", 60, .T.})
aAdd(aPar, {2, "Opcao",        1, aOpcoes, 80, "", .F.})           // 2=combo

If !ParamBox(aPar, "Filtro do Relatorio", @aRet)
    Return
EndIf
```

## Notacao Hungara (OBRIGATORIA)

| Prefixo | Tipo | Exemplo |
|---------|------|---------|
| c | Character/String | `cNome`, `cQuery` |
| n | Numeric | `nTotal`, `nI` |
| d | Date | `dDtDe`, `dEmissao` |
| l | Logical/Boolean | `lRet`, `lOk` |
| a | Array | `aArea`, `aCols` |
| o | Object | `oDlg`, `oReport` |
| b | Code Block | `bLine`, `bLClicked` |
| x | Indefinido | `xRetorno`, `xParam` |

Prefixos de modulo para nomes de funcao:
COM=Compras, EST=Estoque, FAT=Faturamento, FIN=Financeiro,
CTB=Contabilidade, FIS=Fiscal, MNT=Manutencao, PCP=PCP

## Regras Criticas (MUST follow)

1. **Encoding**: Todos os fontes devem ser **CP1252** (Windows-1252). IA gera UTF-8 → converter antes de compilar
2. **Sem `;` + `/* */` na mesma linha** — causa erro C2002 do preprocessor
3. **Language**: Sempre responder em portugues
4. **Protheus.doc**: Toda funcao (User e Static) precisa de `/*/{Protheus.doc}.../*/`
5. **Area preservation**: `Local aArea := GetArea()` ... `RestArea(aArea)` ao redor de qualquer acesso a alias
6. **Filial filter**: `xFilial("ALIAS")` — nunca hardcode filial
7. **SQL**: Preferir TopConnect com `RetSqlName()` + `D_E_L_E_T_ = ' '` ou Embedded SQL com `%Table:%` + `%NotDel%`
8. **GetNextAlias**: Sempre fechar alias temporario (`If Select(cAls) > 0: (cAls)->(DbCloseArea())`)
9. **RecLock**: Apenas para tabelas customizadas (Z*). Tabelas core → MSExecAuto
10. **Date clearing**: `CtoD("  /  /  ")` — nunca `NULL` via SQL
11. **Eof/Bof**: Validar antes de ler qualquer registro posicionado
12. **ConOut**: Log de PE com prefixo `"[PE_NAME] mensagem"` para rastreabilidade
13. **Private**: Evitar. Usar apenas para ExecAuto (`lMsErroAuto`) e variaveis de tela (`oDlg`, `aHeader`, `aCols`)
14. **Public**: Apenas para compartilhar dados entre PEs (escopo cruza fronteira)
15. **Compile**: Usar TDS VS Code extension (nao skill). Config em `.vscode/launch.json`, includes em `C:\totvs\includes`

## Tabelas-Chave do Modulo Suprimentos

| Alias | Descricao | Filtros Canonicos |
|-------|-----------|-------------------|
| SC7 | Pedidos Compra | `C7_RESIDUO<>'S'`, `C7_QUANT>0`, `C7_CONAPRO NOT IN ('R','B')` |
| SC1 | Solicitacoes Compra | Key: `xFilial("SC1") + C1_NUM` |
| SC8 | Cotacoes | Key: `xFilial("SC8") + C8_NUM` |
| SA2 | Fornecedores | `A2_CGC` = 14 digitos sem formatacao |
| SD1 | NF Entrada | |
| SD3 | Mov. Estoque | TM <= 499 entrada, > 499 saida |
| SB1 | Produtos | `B1_MSBLQL <> '1'` |
| SB2 | Saldos | `B2_COD = B1_COD AND B2_LOCAL = B1_LOCPAD` |
| SB9 | Saldos Historicos | `B9_DATA` = YYYYMMDD, usar `B9_QINI`/`B9_VINI1` |
| SCP | Solic. Armazem | `CP_NUM` = D3_NUMSA, `CP_QUJE >= CP_QUANT` = encerrada |
| CTT | Centros de Custo | `CTT_CUSTO = D3_CC` |
| SCR | Aprovacoes | `CR_TIPO` pode ser `'IP'` ou `'PC'`, `CR_STATUS='03'`=aprovado |
| SZ3 | Solic. Cadastrais | `Z3_ID` key, `Z3_STATUS`: 0=Pendente, 1=Aprovado, 2=Rejeitado |
| ZZ3 | Solic. Cadastrais (alt) | `Z3_ID` key |
| ZZ4 | Solic. Fornecedor | `ZZ4_ID` key |

### CNPJ Comparison (SA2 vs ZZ4)
```sql
REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(campo)),'.',''),'/',''),'-','')
```

## Pontos de Entrada — Regras por Modulo

**MATA110 (SC)**:
- `MTA110CON` roda em A110GRAVA/A110ALTERA — sem `RetCodOp()`
- Atualizar todos os itens: scan SC1 por `xFilial("SC1") + C1_NUM` com RecLock cada
- Ler grid via `GdFieldGet("C1_CAMPO", nLinha)`

**MATA020 (Fornecedores)**:
- `MT20FOPOS` = apos save (insert/update)
- `M020EXC` = durante delete — sempre retornar `.T.`
- Dados: `SA2->A2_CGC` fallback `M->A2_CGC`
- Log com `ConOut("[M020EXC] msg")`

**MATA103 (Fechamento)**:
- `MTA103OK` = PE oficial em A103LinOk, retorna via `PARAMIXB[1]`
- `MT103NBL` = bloqueia se `.T.`, usar para "bloquear apenas estoque real"
- Bloquear NF de servico apenas se `SF4->F4_ESTOQUE == "S"`

**MATA094 / Fluxo de Aprovacao (SCR)**:
- `MTALCFIM` = roda em CADA nivel de aprovacao (MATXALC), `PARAMIXB[3]=4` = aprovacao
- `MT097APR` = apos liberacao; pode disparar em CADA aprovacao, nao apenas final
- **Guard obrigatorio**: verificar `SC7->C7_CONAPRO == 'L'` antes de recalcular
- SCR `CR_TIPO` pode ser `'IP'` (nao apenas `'PC'`) para o mesmo PC
- `CR_STATUS = '03'` = aprovado; `CR_DATALIB` pode estar vazio — fallback `Date()`

## Gotchas Comuns

- `oBrw:Refresh(.T.)` reseta cursor para topo → usar `oBrw:Refresh()` sem parametro
- `Refresh` pode disparar `bChange` recursivamente → proteger com `Private lBusy`
- TCBrowse argumentos posicionais: pos 20=uParam20(L), 21=cAlias(C), 22=lPixel(L)
- FWMBrowse usa `SetAlias()`, nao `cString` Private
- ZZ4.CNPJ pode vir formatado; SA2.A2_CGC nao — sempre normalizar ambos lados
- Glob tool e case-sensitive no Windows: `**/*.prw` nao acha `.PRW`. Usar `**/*.[pP][rR][wW]`
- Nao e repo git: `.git` ausente — usar file reads e Grep para inspecionar mudancas

## Checklist de Qualidade Obrigatorio

> Executar ANTES de concluir qualquer tarefa ADVPL. Todos os itens devem passar.
>
> **Source-of-truth**: skill `advpl-quality-checklist` (`.opencode/skills/advpl-quality-checklist/SKILL.md`).
> Carregar via `skill("advpl-quality-checklist")` para ter a versao mais recente.
> Esta secao nao duplica o checklist — apenas referencia.

## Referencias Canonicas do Workspace

| Tipo | Arquivo | Linhas-chave |
|------|---------|-------------|
| Cadastro + mBrowse | `CADSZ3.PRW` | :21 User Function, :40 aCores, :45 aRotina, :53 mBrowse, :126 MSDIALOG, :401 TCBrowse |
| Ponto de Entrada | `MTA110OK.PRW` | :10 User Function, :12 aScan aHeader, :48 aCols, :53 Help(), :92 MT131WF, :178 MT120GOK |
| Analise + LISTBOX | `ZANALBX.PRW` | :31 User Function, :59 ParamBox, :161 cQuery, :565 MSDIALOG, :659 LISTBOX, :854 TReport |
| Analise Compras | `ZCOMPRAS.PRW` | FWMarkBrowse, filtros SC7, export Excel |
| Drill-down | `ZANALPRC.PRW` | MSDIALOG 650x1500, LISTBOX SIZE 1460x235, `AnpAjustaCols` |
| Cadastro Fornec. | `CADFORN.PRW` | mBrowse SA2, campos customizados |
| PE Aprovacao | `MTALCFIM.PRW` | PARAMIXB[3]=4, guard C7_CONAPRO |

## Fontes de Verdade Externas

- `../CLAUDE.md` — documento raiz de diretrizes (ler primeiro)
- `../CLAUDE-SOLUTION-PATTERNS.md` — solucoes validadas (F3/SXB/PEs/filtros)
- TDN: https://tdn.totvs.com.br — consultar para funcoes nativas desconhecidas
- `.opencode/memory.md` — contexto do projeto (ler no inicio de cada sessao)
