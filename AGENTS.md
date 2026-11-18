# AGENTS.md — AdvPL/TLPP Protheus (Vortice)

## Contexto e Idioma
- **Ambiente:** TOTVS Protheus 12 (build `7.00.240223P`), SQL Server, módulo Suprimentos/Compras (`SC7`), fontes em `FONTES/` (`.prw`/`.prg`/`.prx`/`.tlpp`) [16].
- **Servidor:** AppServer `CINVJ6_DEV` (`CONFIG/servers.json` — nunca expor tokens em docs, logs ou commits) [16].
- **Idioma:** Tudo em **português brasileiro**, sem abreviações ("Dias de Estoque", não "DOS") e sem termos em inglês em textos de tela [16].

## Perfil do Usuário e Entrega
O usuário não programa. Mantenha o rigor técnico no código, mas comunique em linguagem simples:
- Explique qualquer termo técnico em uma linha [16].
- **Antes de implementar** tarefa média/grande ou com lacunas (faltando rotina ou erro literal), faça até 3 perguntas de negócio com 2–4 opções (recomendada primeiro) e aguarde [16].
- **Toda entrega tem 3 partes:** (1) o que mudou em 1 frase; (2) passos clicáveis para testar na tela (nunca peça revisão de código); (3) o que ficou **não confirmado** [16].

## Protocolo Obrigatório (anti-alucinação)
1. **Ler antes de editar:** Pesquise o código real (`arquivo:linha`). Nunca responda de memória sobre API, campo ou ponto de entrada [16].
2. **Validar símbolos:** Confira função, classe, método e campo nesta ordem: código do repo → `skills/**/SKILL.md` → `docs/` → TDN (`tdn.totvs.com`) → web confiável [16]. Se não confirmar, escreva **"não confirmado"** [16].
3. **Mudança mínima:** Altere só o necessário para o pedido; não refatore código legado sem solicitação e não crie arquivos `.md` por conta própria [16].

## Regras Críticas de ADVPL/TLPP (0 violações)
- **SQL:** Sempre `D_E_L_E_T_ = ' '`, `XX_FILIAL = xFilial('XXX')`, `RetSqlName()` e `FWExecStatement`/`ChangeQuery()` [16].
- **Lock:** `%nolock%` é **proibido**. Para leitura/relatório, reinjete `WITH (NOLOCK)` literal **após** `ChangeQuery()` [16].
- **Gravação:** `RecLock` somente em tabelas `Z*`. Tabelas core (`SC5`, `SC6`, `SC7`, `SD1`, `SD2`, `SF1`, `SF2`, `SB1`, `SA2`, etc.) apenas via `MSExecAuto` [16].
- **Transação e Loops:** Nunca usar UI (`MsgAlert`, `MsgYesNo`, `MsgInfo`, `Aviso`, `Help`, `Pergunte`, `ParamBox`) dentro de transação [16]. Nunca chamar `GetMV()`, `SuperGetMV()`, `ExistBlock()`, `Type()` ou `Pergunte()` dentro de loop [16].
- **Sintaxe e Escopo:** Proibido `Function` (use `User Function` ou `Static Function`), `IIF` (use `If/Else/EndIf`), `ConOut()`/`OutErr()`/`?` (use `FWLogMsg`), `cFilial` (use `cFilAux` ou `xFilial()`), `HTTPCGet`/`HTTPCPost`/`HTTPQuote` (use `FWRest`), e `FwFreeObj`/`FreeObj`/`FwFreeArray` (use `Destroy()` quando existir) [16].
- **Padrão:** `GetArea()`/`RestArea()` em toda função com alias; notação húngara (`c/n/d/l/a/o/b/x/j`); bloco `/*/{Protheus.doc}`; `#include "totvs.ch"` em código novo (`tlpp-core.th` primeiro em TLPP); Entry Point sem prefixo `U_` no nome da função [16].
- **SonarQube:** Sem violações CRITICAL/MAJOR (referência em `CONFIG/references_sonarqube-rules-reference.md`) [16].

## Skills e Documentação (sob demanda)
Consulte apenas quando a tarefa exigir (não carregue tudo preventivamente):
- **Roteamento de skills:** Consulte `skills/skills-registry.json` ou `skills/README.md` (§7) antes de gerar código e leia o `SKILL.md` correspondente [16].
- **Uso sempre obrigatório ao editar/criar fonte:** `advpl-padrao-fonte` (`skills/vortice/advpl-padrao-fonte/SKILL.md`) [16].
- **Uso sempre obrigatório em telas `MSDIALOG`:** `advpl-msdialog-dimensionamento` e `advpl-msdialog-ciclo-de-vida` (`skills/vortice/`) [16].
- **Docs de apoio:** `docs/fontes.md` (localizar fontes), `docs/tabelas.md` (Suprimentos), `docs/convencoes.md` (sintaxe/TLPP), `docs/workflow.md` (SDD/LSP/memória), `docs/diagnostico.md` (queries SC7) [16].

## Gate Pós-Geração (antes de entregar)
1. **Auditoria de padrão:** Rode `python skills\vortice\advpl-padrao-fonte\scripts\auditar_padrao.py FONTES\ARQUIVO.PRW --estrito` (exigido **0 ERRO**) [16]. Em `MSDIALOG`, rode também `calc_frame.py` e `check_pos_activate.py` [16].
2. **Encoding:** Converta o fonte para **CP-1252** (`utf8-to-cp1252-conversion`). Nunca entregue em UTF-8 [16].
3. **LSP e Compilação:** Cheque os diagnósticos do LSP AdvPL. **A compilação é sempre manual pelo usuário** — nunca execute `advpls.exe` ou build hooks; encerre com status **"aguardando compilação do usuário"** [16].