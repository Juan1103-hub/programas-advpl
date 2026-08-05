# CLAUDE.md — Kit AdvPL/Protheus · Módulo Suprimentos

> **Instruções permanentes para o Claude Code neste workspace.**
> Leia este arquivo completamente antes de gerar qualquer código.

---

## 1. Regras Gerais do Workspace

- Responder **sempre em português**.
- Priorizar **AdvPL/Protheus 12** com foco em Suprimentos.
- Em código novo, incluir cabeçalho **Protheus.doc** (`/*/{Protheus.doc} ... /*/`).
- Preservar `GetArea()` / `RestArea()` quando houver acesso a alias.
- Usar `xFilial("ALIAS")` em filtros por filial — nunca hardcodar.
- Em SQL, preferir TopConnect com `%Table:%` e `%NotDel%` quando aplicável.
- **Nunca** alterar comportamento fora do escopo pedido.
- Em revisão, listar findings por severidade antes do resumo.

---

## 2. Checklist de Qualidade (aplicar em todo código gerado)

1. **Documentação** — Protheus.doc presente e clara; comentários nos pontos críticos.
2. **Nomenclatura** — variáveis, funções e aliases no padrão TOTVS (prefixos: `c`=char, `n`=num, `d`=date, `l`=lógico, `a`=array, `o`=objeto).
3. **Performance** — evitar loops desnecessários; SX table access fora de loops; DBSeek/MsSeek otimizados.
4. **Segurança** — SQL sem concatenação de entrada do usuário; sem expor dados sensíveis; validar parâmetros.
5. **Manutenção** — funções separadas por responsabilidade; sem duplicidade de lógica.
6. **UI/UX** — mensagens claras; telas responsivas (MSDIALOG, TPanel, ListBox).
7. **Exportação/Relatórios** — cabeçalhos e totais corretos; padrão FWMSExcelX.
8. **Testes** — cobrir datas invertidas/vazias, limites, exceções.
9. **Impacto em Produção** — sem funções temporárias; pronto para deploy.
10. **Pensar além** — simplificação, usabilidade, segurança ou performance não solicitada?

---

## 3. Padrões de Código Obrigatórios

```advpl
// Documentação obrigatória
/*/{Protheus.doc} NomeFuncao
    Descricao breve da funcao.
    @author  Seu Nome
    @since   DD/MM/AAAA
    @version 1.0
    @param   cParam, character, descricao do parametro
    @return  lRet, logical, .T. se sucesso, .F. se erro
/*/

// Includes padrao
#Include "Protheus.ch"
#Include "TopConn.ch"    // quando usar SQL

// Estrutura minima de funcao com alias
User Function MINHAFUNC()
    Local aArea := GetArea()
    // ... logica ...
    RestArea(aArea)
Return
```

### Regras críticas de sintaxe AdvPL

- **NÃO colocar comentários `/* ... */` na mesma linha de `;` de continuação** — quebra o pré-processador com erro C2002. O `;` deve ser o último caractere da linha.
- Lock: `RecLock('ALIAS',.F.)` ... `ALIAS->(MsUnlock())`
- SQL: `GetNextAlias()` + `BeginSql/EndSql` + fechar com `DbCloseArea()`
- Limpar campo data: usar `Replace CAMPO_DT With CtoD("  /  /  ")` — nunca `UPDATE ... SET CAMPO = NULL`.
- Gravar data em campo tipo "D": via AdvPL `RecLock + Replace` (não via `TCSQLExec` com CONVERT).

---

## 4. Tabelas Principais (Suprimentos)

| Alias | Descrição | Observações |
|-------|-----------|-------------|
| SC7   | Pedidos de Compra | Filtros: `NotDel`, `C7_RESIDUO<>'S'`, `C7_QUANT>0`, `C7_CONAPRO NOT IN ('R','B')` |
| SC1   | Solicitações de Compra | Chave: `xFilial("SC1") + C1_NUM` |
| SA2   | Fornecedores | `A2_CGC` = 14 dígitos sem formatação |
| SB1   | Produtos | |
| SB2   | Saldos em Estoque | |
| SD1   | Documentos de Entrada (NF) | |
| SD3   | Movimentos de Estoque | TM ? 499 = entrada; TM > 499 = saída |
| SB9   | Saldos Históricos | `B9_DATA` formato `YYYYMMDD`; usar `B9_QINI`/`B9_VINI1` |
| SA3   | Compradores | |
| SF4   | Tipos de Entrada/Saída (TES) | `F4_ESTOQUE='S'` |
| ZZ3   | Custom Solicitações Cadastrais | chave: `Z3_ID`; campos: `Z3_USR`, `Z3_PRAZO`, `Z3_DESCRI`, `Z3_PN`, `Z3_STATUS`, `Z3_ZDTSOL`, `Z3_DTREJ`, `Z3_APLIC`, `Z3_MOTIVO`, `Z3_UM`, `Z3_LINK` |
| ZZ4   | Custom Solicitações de Fornecedor | campos: `ZZ4_ID`, `ZZ4_USR`, `ZZ4_RAZAO`, `ZZ4_CNPJ`, `ZZ4_NUMERO`, `ZZ4_EMAIL`, `ZZ4_INSEST`, `ZZ4_INSMUN`, `ZZ4_CONTAT`, `ZZ4_SIMPLE`, `ZZ4_STATUS`, `ZZ4_ZDTSOL`, `ZZ4_DTREJ` (sem campo PRAZO) |

### Comparação CNPJ entre tabelas
SA2 grava `A2_CGC` sem formatação; ZZ4 pode gravar `ZZ4_CNPJ` formatado.
**Comparar sempre removendo formatação dos dois lados:**
```sql
REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(campo)),'.',''),'/',''),'-','')
```

### Desconto implícito em SD1
Quando não houver campo de desconto explícito: `desconto_item = (D1_VUNIT * D1_QUANT) - D1_TOTAL`
VUnit líquido = `D1_TOTAL / D1_QUANT` (clamp para não superar `D1_VUNIT`).

---

## 5. Programas Modelo — Ler Antes de Criar Qualquer Tela

| Categoria | Arquivo de referência | O que copiar |
|-----------|----------------------|--------------|
| Cadastro com browse | `CADSZ3.PRW` | mBrowse, aCores, aRotina, DEFINE MSDIALOG, GROUP, MSGET, TCBrowse |
| Análise / listagem | `ZANALBX.PRW` | Dialog grande, LISTBOX, botões Fechar/Exportar |
| Análise de compras | `ZCOMPRAS.PRW` | FWMarkBrowse, filtros SC7, exportação Excel |
| Avaliação / ranking | `ZAVALNEG.PRW` | ParamBox, grid com coloração, indicadores |
| Consulta REST | `VOREST02.PRW` | Chamadas API, tratamento JSON |
| Análise com drill-down | `ZANALPRC.PRW` | MSDIALOG 650×1300, LISTBOX @40,5 SIZE 640×260, colunas proporcionais |

---

## 6. Padrões de Tela

```advpl
// Dialog padrão
DEFINE MSDIALOG oDlg TITLE "Titulo" FROM 0,0 TO 650,1300 PIXEL
ACTIVATE MSDIALOG oDlg CENTERED

// Grupos
@ L, C GROUP oGroup TO L2, C2 PROMPT "Titulo" OF oDlg COLOR 0,16777215 PIXEL

// Botão Fechar (SEMPRE em telas de visualização/análise)
@ L, C BUTTON oBtn PROMPT "Fechar" SIZE 50,12 OF oDlg PIXEL ACTION oDlg:End()

// Fontes — criar e liberar
oFont := TFont():New("Arial",,-11,,.F.)
// ... uso ...
FreeObj(oFont)

// Cores de linha browse
aCores := {{"ALIAS->CAMPO=='V'","BR_BRANCO"}, ...}
```

### Regras de layout
- **Telas de visualização** — SEMPRE têm botão "Fechar" alinhado à direita.
- **Telas de inclusão/edição** — dois botões: "Confirmar" à esquerda + "Cancelar/Fechar" à direita.
- Botões de ação: Confirmar/Processar à ESQUERDA — Cancelar/Fechar à DIREITA ou ABAIXO.

### Browse — escolha do componente
- **Browse simples** com aRotina/aCores ? `mBrowse`.
- **Browse com lógica ao mudar de linha** ? usar `FWMBrowse`:
  - `MenuDef()` Static Function retornando `aRot` substitui o `aRotina` Private.
  - `oBrw:AddLegend("CONDICAO", "BR_COR", "Texto")` substitui `aCores`.
  - `oBrw:bChange := {|| MinhaFunc(oBrw) }` — disparado a cada navegação.
  - **Não usar `cString` Private** — `FWMBrowse` usa `SetAlias()`.

### TCBrowse — assinatura posicional (build 7.00.240223P)
Posições: 1=nRow, 2=nCol, 3=nWidth, 4=nHeight, 5=bLine, 6=aHeaders, 7=aColSizes, 8=oWnd, 9=cField, 10=uVal1, 11=uVal2, 12=bChange, **13=bLDblClick**, 14=bRClick, 15=oFont, 16=oCursor, 17=nClrFore, 18=nClrBack, 19=cMsg, **20=uParam20 (L)**, **21=cAlias (C)**, **22=lPixel (L)**.
Confundir pos 20/21 gera erro `"argument #20 expected C->L"`.

### bChange / Refresh — armadilhas
- `oBrw:Refresh(.T.)` **reposiciona o cursor para o topo** ? quebra navegação. Usar `oBrw:Refresh()` sem parâmetro.
- `Refresh` pode disparar `bChange` recursivamente ? **stack overflow**. SEMPRE usar flag de guarda (`Private lBusy`).

---

## 7. Skill: Tela de Análise com Drill-down (Modelo ZANALPRC)

Toda tela de análise com drill-down deve seguir exatamente esta estrutura.

### Dimensões obrigatórias

| Propriedade | Valor |
|-------------|-------|
| MSDIALOG | `FROM 0,0 TO 650,1300 PIXEL` |
| LISTBOX pos | `@40,5` |
| LISTBOX size | `SIZE 640,260` |
| Filtros | linha `@5`, altura `10 px` |
| Botões | linha `@20`, altura `12 px` |
| Botão Fechar sub-janela | `@20,1240 SIZE 50,12` |
| Título | sempre exibir contagem: `cValToChar(Len(aArray))` |

### Variáveis de layout (declarar no topo da função)
```advpl
Local nListWidth := 640
Local aMinCols   := { /* larguras minimas de cada coluna em pixels */ }
Local nSumMin    := 0
Local nI         := 0
Local aFinalCols := {}
Local nVal       := 0
Local nExtra     := 0
```

### Ajuste dinâmico de largura de colunas (OBRIGATÓRIO após SetArray)
```advpl
oL:SetArray(aArray)

nSumMin := 0
aFinalCols := {}
For nI := 1 To Len(aMinCols)
    nSumMin += aMinCols[nI]
Next

If nSumMin <= nListWidth
    nExtra := nListWidth - nSumMin
    For nI := 1 To Len(aMinCols)
        nVal := aMinCols[nI] + IIf(nI = 2, nExtra, 0)
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

### Referência de larguras mínimas por tipo de coluna

| Tipo | Largura mínima |
|------|---------------|
| Código item (6 chars) | 55 px |
| Descrição (30–40 chars) | 160 px |
| Centro de Custo | 85 px |
| Quantidade | 55 px |
| Valor unitário | 70–75 px |
| Valor total / diferença | 50–60 px |
| Data | 45 px |
| Pedido / SC (6 chars) | 40 px |
| Fornecedor (nome) | 120 px |
| Situação / Status | 60 px |
| Comprador (nome) | 100 px |

### bLine — formatações padrão

| Tipo | Máscara Transform |
|------|------------------|
| Quantidade inteira | `"@E 999,999.99"` |
| Valor unitário | `"@E 9,999,999.9999"` |
| Valor total / diff | `"@E 9,999,999.99"` |
| Percentual | `Str(campo,7,1) + "%"` |
| Texto | `AllTrim(campo)` |
| Data | `DtoC(campo)` |

### Função de re-grid (padrão obrigatório)
```advpl
Static Function AnpReGrid(oDlg, oL, aArray)
    // ...mesmas variaveis de layout...
    oL:nAt := 1
    oL:SetArray(aArray)
    // ...mesmo bloco de calculo aColSizes...
    oL:bLine      := {|| { /* idem ao bloco principal */ }}
    oL:bLDblClick := {|| /* idem */ }
    oL:Refresh()
    oDlg:SetText("<Titulo> - " + cValToChar(Len(aArray)))
    oDlg:Refresh()
Return
```

### Checklist de conformidade
- [ ] `FROM 0,0 TO 650,1300 PIXEL` no diálogo principal e sub-janelas
- [ ] Filtros na linha `@5`, altura `10`
- [ ] Botões na linha `@20`, altura `12`
- [ ] LISTBOX em `@40,5 SIZE 640,260`
- [ ] Bloco de cálculo dinâmico de `aColSizes` após `SetArray`
- [ ] `oL:nAt := 1` antes de `SetArray` no re-grid
- [ ] `bLine` e `bLDblClick` reatribuídos no re-grid
- [ ] `oL:Refresh()` e `oDlg:Refresh()` ao final do re-grid
- [ ] Botão Fechar da sub-janela em `@20,1240 SIZE 50,12`
- [ ] `ACTIVATE MSDIALOG ... CENTERED` em todos os diálogos

---

## 8. Points of Entry — Regras por Módulo

### MATA110 / Solicitação de Compra
- `MT110CON` roda no fluxo `A110GRAVA/A110ALTERA`; não usar `RetCodOp()` (indisponível no contexto FWFormBrowse).
- Para garantir update de todos os itens da SC: identificar `C1_NUM` pelo grid/M->C1_NUM e varrer `SC1` por `xFilial("SC1") + C1_NUM`, aplicando `RecLock` em cada item.
- Preferir `GdFieldGet("C1_CAMPO", nLinha)` para ler campos do grid; `aHeader` pode variar.
- Para valor padrão da Necessidade em tempo de edição: usar PE `MT110DTN` (A110DtNec).
- `MT110LOK` — versão atual é stub `Return .T.` (LinhaTudoOK dispara 2x, impossível detectar "linha nova" via RECNO).
- `MT110EMI.tlpp` — User Function chamada pelo SX7 em C1_PROD, retorna `dDataBase`. Configurar gatilho: `X7_CAMPO=C1_PROD`, `X7_TIPO=P`, `X7_CDOMIN=C1_EMISSAO`, `X7_REGRA=MT110EMI()`, `X7_CONDIC=IsInclui() .And. Empty(C1_EMISSAO)`, `X7_PROPRI=U`.
- Arquitetura final C1_EMISSAO MATA110: `SX7(MT110EMI)` ? tempo real + `MT110CON` ? correção pré-save + `M110STTS` ? correção pós-save (X3_RELACAO).

### MATA020 / Cadastro de Fornecedores
- `MT20FOPOS` ? executa APÓS gravar fornecedor (inclusão e alteração).
- `M020EXC` ? executa durante exclusão — sempre retornar `.T.` para não bloquear.
- Acessar dados: `SA2->A2_CGC`, com fallback `M->A2_CGC` se vazio.
- Sempre `GetArea()` no início e `RestArea()` no fim.
- Logar com `ConOut("[NOME_PE] mensagem")` para diagnóstico no `console.dlg`.

### MATA103 / FECHTO
- `MTA103OK` é o PE oficial da MATA103 em `A103LinOk`; recebe retorno em `PARAMIXB[1]`; pode liberar FECHTO retornando `.T.`.
- `MT103NBL` é PE oficial em `A103TemBlq/TudoOk`; `.T.` bloqueia, `.F.` não bloqueia — usar para "só bloqueia estoque real".
- `MT103CTB` é chamado antes da tela contábil; retorna `aCtbInf` — usar primeiro para diagnóstico/log.
- Para liberar nota de serviço do FECHTO: bloquear **somente** se `SF4->F4_ESTOQUE == "S"`. TES vazia/não encontrada = não bloqueia.

---

## 9. ZSLDEST / Kardex Almoxarifado

- `B9_DATA` formato `YYYYMMDD`; usar `B9_QINI`/`B9_VINI1`; **não** filtrar apenas por `YYYYMM`.
- Saldo inicial: `B9_DATA <= DtoS(dDtDe)`; se SB9 anterior ao período, avançar saldo com movimentos entre data do SB9 e `dDtDe`.
- Sem SB9 anterior: calcular saldo histórico por `SD1 entradas + SD3 entradas internas - SD3 saídas`.
- Entradas do Kardex: `SD1` + `SF4->F4_ESTOQUE='S'` e `SD3->D3_TM <= '499'`; saídas: `SD3->D3_TM > '499'`.
- Valor Final = Saldo Inicial + Entradas - Baixas (espelhar razão contábil).
- `D3_CUSTO1` = valor total da saída; custo unitário = `D3_CUSTO1 / D3_QUANT`.
- Manter queries separadas para movimentos do período e movimentos futuros.
- Exibir somente produtos com saída/baixa no período.

---

## 10. Nomenclatura de Arquivos

| Prefixo | Tipo |
|---------|------|
| `Z*.PRW` | Funções customizadas (ZCOMPRAS, ZAVALNEG, ZLOGCOL, ZANALBX) |
| `MT*.PRW` | Points of Entry (MT010ALT, MTA094RO, MTA110OK) |
| `MTA*.PRW` | Points of Entry de aprovação |

---

## 11. Componentes UI / Framework

- `FWMarkBrowse` — browse com marcação (SC7 principal)
- `TReport` / `ReportDef` — relatórios padrão
- `ParamBox` — caixa de parâmetros
- `FWMSExcelX` — exportação Excel

---

## 12. Constantes de Negócio

```advpl
#DEFINE META_DESC   3   // meta 3% desconto
#DEFINE LIM_ALERTA  5   // % limite alerta
```

---

## 13. Diagnóstico (regra de ouro)

Sempre criar uma `User Function DIAG*()` separada que mostra estado real via SQL quando o comportamento esperado não acontece.

```advpl
User Function DIAGZZ4()
    Local cSQL := ""
    Local cAlias := GetNextAlias()
    BeginSql Alias cAlias
        SELECT ZZ4_ID, ZZ4_STATUS, ZZ4_CNPJ FROM %Table:ZZ4% WHERE %NotDel%
    EndSql
    // exibir com MsgInfo ou ConOut
    DbSelectArea(cAlias)
    DbCloseArea()
Return
```

---

## 17. Skill Karpathy Guidelines — Diretrizes Comportamentais

> Fonte: `andrej-karpathy-skills` / `karpathy-guidelines`.
> Aplicar principalmente em tarefas não triviais; usar bom senso em correções simples.

### 17.1. Think Before Coding

**Não assuma. Não esconda confusão. Explicite tradeoffs.**

Antes de implementar:
- Declare suposições explicitamente. Se estiver incerto, pergunte.
- Se existirem múltiplas interpretações, apresente-as — não escolha uma em silêncio.
- Se houver uma abordagem mais simples, diga. Proponha quando fizer sentido.
- Se algo estiver pouco claro, pare. Nomeie a dúvida e pergunte.

### 17.2. Simplicity First

**Mínimo de código que resolve o problema. Nada especulativo.**

- Sem funcionalidades além do solicitado.
- Sem abstrações para código de uso único.
- Sem "flexibilidade" ou "configurabilidade" não pedidas.
- Sem tratamento de erro para cenários impossíveis.
- Se uma solução de 200 linhas poderia ter 50, simplifique.

Pergunta de controle: um engenheiro sênior diria que está complicado demais? Se sim, simplifique.

### 17.3. Surgical Changes

**Toque apenas no necessário. Limpe apenas a própria bagunça.**

Ao editar código existente:
- Não "melhore" código, comentários ou formatação adjacentes.
- Não refatore o que não está quebrado.
- Mantenha o estilo existente, mesmo que você faria diferente.
- Se encontrar código morto não relacionado, mencione — não remova.

Quando as mudanças criarem dependências órfãs:
- Remova imports, variáveis ou funções que as suas mudanças tornaram inúteis.
- Não remova código morto preexistente salvo se solicitado.

Teste: cada linha alterada deve ter relação direta com o pedido do usuário.

### 17.4. Goal-Driven Execution

**Defina critérios de sucesso. Repita até verificar.**

Transforme tarefas imperativas em metas verificáveis:
- "Adicionar validação" ? "Criar testes para entradas inválidas e fazê-los passar".
- "Corrigir bug" ? "Criar teste que reproduz o bug e fazê-lo passar".
- "Refatorar X" ? "Garantir que testes passem antes e depois".

Para tarefas multi-etapa, declarar plano breve:

```text
1. [Etapa] -> verificar: [checagem]
2. [Etapa] -> verificar: [checagem]
3. [Etapa] -> verificar: [checagem]
```

Critérios de sucesso fortes permitem execução autônoma. Critérios fracos como "fazer funcionar" exigem nova clarificação.

---

## 18. Encoding / Caracteres Especiais

- `.editorconfig` configurado: `charset=latin1` para `*.prw/*.PRW/*.prx/*.PRX`.
- `Suprimentos/.vscode/settings.json`: `files.encoding=windows1252`, `files.autoGuessEncoding=true`.
- Quando aparecer texto como `DescriÃ§Ã£o`: validar encoding (UTF-8 lido como ANSI/CP1252). Substituir apenas tokens mojibake e salvar no encoding correto.

---

## 18. Workflow Beast Mode — AdvPL/Protheus

Para qualquer implementação ADVPL, seguir este formato de resposta:

### ANÁLISE
- Objetivo de negócio
- Tabelas envolvidas
- Points of Entry disponíveis
- Abordagem recomendada

### IMPLEMENTAÇÃO
- Código completo e funcional
- Explicação detalhada

### PLANO DE TESTES
- Cenário 1 / Cenário 2 / Resultados esperados

### RISCOS E CONSIDERAÇÕES
- Impacto de performance / upgrade / segurança / manutenção

### RECOMENDAÇÃO FINAL
- Melhor estratégia e razão da escolha

---

## 19. Estrutura do Workspace

```
c:\totvs\advpl\.vscode\
??? PATCH/          ? artefatos de produção (.ptm, fontes prontos)
??? Suprimentos/    ? desenvolvimento (fontes .PRW/.tlpp, skills, prompts)
    ??? .github/
    ?   ??? copilot-instructions.md
    ?   ??? agents/
    ?   ??? prompts/
    ??? _arquivos-movidos-da-patch/
```

> A pasta `PATCH/` é reservada para artefatos de produção. Configurações auxiliares devem ficar fora dela.

---

## 20. Skills TOTVS (referência completa)

> Arquivo detalhado: `CLAUDE-SKILLS-REF.md` neste diretório.
> Repositório oficial: https://github.com/totvs/engpro-advpl-tlpp-skills/tree/main/skills/advpl-tlpp

### Qual Skill Usar?

| Tarefa | Skill |
|--------|-------|
| Tela CRUD MVC | `mvc-generator` |
| Endpoint REST (TLPP) | `tlpp-rest-endpoint-generator` |
| Consumir API REST | `fwrest-client-generator` |
| Ponto de Entrada | `entry-point-designer` |
| SQL Protheus | `query-builder` |
| Migrar .prw → .tlpp | `advpl-to-tlpp-migration` |
| Revisão de código | `code-review` |
| Revisão SQL | `sql-code-review` |
| Refatorar código | `refactor` |
| Reduzir complexidade | `refactor-method-complexity-reduce` |
| Otimizar SQL | `sql-optimization` |
| Testes TIR (UI) | `tir-test-generator` |
| Documentação ProtheusDOC | `documentation-writer` |
| Dicionário de dados | `data-dictionary-lookup` |
| Mapear arquivos | `context-map` |
| Plano de implementação | `create-implementation-plan` |
| Projeto SDD | `advpl-tlpp-sdd` |
| Converter UTF-8 → CP1252 | `utf8-to-cp1252-conversion` |

### Workflow Obrigatório

1. **Antes de implementar**: carregar `context-map` para mapear arquivos afetados
2. **Ao gerar código**: carregar skill específica (entry-point-designer, mvc-generator, etc.)
3. **Ao revisar**: carregar `code-review` ou `sql-code-review`
4. **Após gerar .prw/.tlpp**: executar `utf8-to-cp1252-conversion` para encoding CP1252
5. **Ao compilar**: usar `advpl-tlpp-compile` (se disponível)
6. **Antes de tentar soluções novas**: carregar skill `solucoes-consultas` (F3/SXB/FWLookup) ou consultar `CLAUDE-SOLUTION-PATTERNS.md` — contém soluções validadas para consultas, PEs, filtros e armadilhas conhecidas
7. **Ao enfrentar erro desconhecido**: verificar documentação oficial TDN (tdn.totvs.com) em vez de assumir comportamento do framework


