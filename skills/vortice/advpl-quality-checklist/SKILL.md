---
name: advpl-quality-checklist
description: Checklist de qualidade obrigatorio executado ANTES de concluir qualquer tarefa ADVPL/TLPP. Cobre estrutura Protheus.doc, escopo de variaveis, acesso a banco (GetArea/RestArea, xFilial, RecLock vs MSExecAuto), UI, PEs e pre-compilacao. Use when concluding ADVPL work, reviewing code, validating implementation against workspace standards.
---

# AdvPL/TLPP Quality Checklist (Vortice)

> Executar ANTES de concluir qualquer tarefa ADVPL. Todos os itens devem passar.
> Origem: extraido de `advpl-protheus/SKILL.md` (skill canonica do workspace).
> Source-of-truth das regras: este arquivo + `AGENTS.md` do FILHO.

## Estrutura e Cabecalho

- [ ] Includes `Protheus.ch` + `TopConn.ch` no topo do arquivo
- [ ] Cabecalho `/*/{Protheus.doc}.../*/` em TODAS as funcoes (User e Static)
- [ ] `@type`, `@author`, `@since` presentes no Protheus.doc
- [ ] Notacao Hungara aplicada (c/n/d/l/a/o/b/x) em todas as variaveis
- [ ] Sem `;` + `/* */` na mesma linha (erro C2002 do preprocessor)

## Escopo e Variaveis

- [ ] Todas as variaveis declaradas como `Local` (topo da funcao)
- [ ] Nenhuma variavel `Public` desnecessaria (apenas para dados entre PEs)
- [ ] `Private` apenas para ExecAuto (`lMsErroAuto`) e controles de tela (`oDlg`, `aHeader`, `aCols`)
- [ ] Nenhum uso de variaveis nao declaradas (implicit scope)
- [ ] `Local aArea := GetArea()` ... `RestArea(aArea)` ao redor de qualquer acesso a alias

## Banco de Dados

- [ ] `xFilial("ALIAS")` usado em todos os filtros SQL e seeks
- [ ] `GetNextAlias()` + `If Select(cAls) > 0: (cAls)->(DbCloseArea())` para alias temporarios
- [ ] `RetSqlName("ALIAS")` + `D_E_L_E_T_ = ' '` em todas as queries
- [ ] `ChangeQuery()` aplicado em queries via TcQuery string
- [ ] `Eof()` / `Bof()` validados antes de ler registro posicionado
- [ ] `RecLock` apenas em tabelas customizadas (Z*); core → MSExecAuto
- [ ] Datas limpas com `CtoD("  /  /  ")` — nunca `NULL` via SQL
- [ ] **Performance**: evitar `SELECT *`, validar com EXPLAIN em queries > 1s

## UI (se aplicavel)

- [ ] MSDIALOG com `FROM 0,0 TO 650,1300 PIXEL` (ou proporcional)
- [ ] `ACTIVATE MSDIALOG ... CENTERED`
- [ ] LISTBOX com `SetArray()` + `bLine` + `aColSizes` definidos
- [ ] Titulo mostra contagem: `"Title - " + cValToChar(Len(aArray))`
- [ ] Botoes Fechar/Nova Consulta presentes no rodape

## Pontos de Entrada (se aplicavel)

- [ ] `ConOut("[PE_NAME] mensagem")` para rastreabilidade (com nivel INFO/WARN/ERROR)
- [ ] `ValType(PARAMIXB)` validado antes de acessar
- [ ] `aScan(aHeader,...) > 0` validado antes de acessar aCols
- [ ] Linha deletada checada: `aCols[nX][Len(aHeader)+1]`
- [ ] Guard de aprovacao: `C7_CONAPRO == 'L'` antes de recalcular (MATA094)

## Pre-Compilacao

- [ ] Encoding CP1252 (converter de UTF-8 se gerado por IA, skill `utf8-to-cp1252-conversion`)
- [ ] Encoding convertido APENAS na versao final (nao a cada edit intermediaria)
- [ ] Sem funcoes ficticias (validar contra TDN se duvidoso)
- [ ] Compilacao via TDS VS Code extension (nao skill)
- [ ] Reinicio do AppServer apos `TcSqlExec` em SX2/SIX (cache nao atualiza)

## Testes (recomendado, nao obrigatorio)

- [ ] ProBat para logica nao-trivial (skill `probat-testing`)
- [ ] TIR para fluxos MVC completos (skill `tir-test-generator`)

## Documentacao

- [ ] Protheus.doc atualizado em funcoes publicas ao modificar assinatura
- [ ] Tabela de roteamento (AGENTS.md) atualizada se nova categoria de tarefa surgir
- [ ] `memory.md` atualizado se novo gotcha/regra for descoberto

## Como Usar Esta Skill

1. Apos implementar, antes de declarar "concluido":
   - `skill("advpl-quality-checklist")` carrega este checklist
2. Percorrer item por item
3. Se algum falhar, corrigir antes de reportar conclusao
4. Reportar "concluido" apenas quando TODOS os obrigatorios passam
