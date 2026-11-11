## Protocolo de Raciocínio (prioridade máxima, acima de qualquer outra regra)

Você pode estar rodando num modelo gratuito, que erra por atalho e por
invenção. Para se aproximar de um modelo de raciocínio profundo, o
raciocínio precisa ser **explícito e visível**: pense em etapas ANTES de
escrever qualquer resposta ou código.

Este protocolo vale para qualquer modelo (gratuito ou não) e qualquer
plataforma que leia `AGENTS.md`: opencode, Claude Code, Cursor, Codex,
Cline, Aider, Freebuff.

### Proporção ao tamanho da tarefa

- **Tarefa pequena** (um arquivo, mudança óbvia e localizada): faça só os
  passos **1, 4, 5, 10 e 11**.
- **Tarefa média ou grande** (vários arquivos, dados, transação, rotina
  crítica, causa desconhecida): faça **todos os passos de 1 a 11**.
- Na dúvida sobre o tamanho, trate como média.

Pular um passo exigido pelo tamanho da tarefa é falha e a resposta deve
ser refeita.

### 1. Reformulação — 1 linha
Resuma o problema em uma frase. Se não conseguir, você ainda não
entendeu o problema.

### 2. Inventário de conhecimento
- **JÁ SEI** — cada item com fonte: `arquivo:linha`, tabela ou TDN.
- **NÃO SEI** — lista explícita. Nada desta lista pode ser preenchido
  por palpite; vira pergunta (passo 3) ou pesquisa (passo 5).

### 3. Lacunas críticas → perguntar antes de propor
Se a rotina, o sintoma ou o fluxo não estiverem claros, faça até 3
perguntas objetivas, em lista numerada, e PARE. Só investigue depois da resposta.

### 4. Evidência no código real
Leia o código do repositório e cite no formato `arquivo:linha`.
**Nunca** responda apenas de memória sobre API, campo ou ponto de entrada.
Antes de afirmar que algo não existe, repita a busca com variações
(maiúsculas e minúsculas, aspas simples e duplas, dbAppend, MsExecAuto).

### 5. Validação de símbolos
Valide cada função, classe, método, ponto de entrada e campo **antes** de
usar, nesta ordem: código existente do repo → `skills/**/SKILL.md` e
`skills/**/references/**` → este `AGENTS.md` → TDN (`tdn.totvs.com`) → web
confiável → perguntar ao usuário. Confira também a assinatura completa
(ordem, tipos, retorno) e o contexto de execução. Se não confirmar,
escreva literalmente **"não confirmado"**. Nunca invente símbolo,
assinatura ou parâmetro.

### 6. Decomposição (somente tarefa média ou grande)
Quebre o problema em sub-problemas independentes e resolva um de cada
vez. Problema grande entregue sem decomposição é resposta errada.

### 7. Hipóteses — 2 ou 3, ordenadas por probabilidade
Para cada hipótese, diga **como confirmar**: query SQL para rodar no
APSAU/APSDU, log, ou passo de debug. Hipótese sem método de confirmação
não vale como hipótese.

### 8. Ataque destrutivo às suas próprias premissas
Antes de propor, tente derrubar a sua própria solução:
- O que quebra em filial com dados diferentes?
- E se o registro não existir, estiver duplicado ou com `D_E_L_E_T_` preenchido?
- E se rodar com 50 usuários ao mesmo tempo (deadlock, lock de tabela)?
- Alguma premissa minha está sem evidência? Mova para **NÃO SEI**.

### 9. Correção na causa raiz
Só depois dos passos anteriores proponha a correção, atacando a **causa
raiz** e nunca o sintoma.

### 10. Autoverificação obrigatória — antes de declarar pronto
Confira o código que você mesmo escreveu:
- [ ] `D_E_L_E_T_ = ' '` e `xx_FILIAL = xFilial(...)` em toda query
- [ ] `GetArea()` / `RestArea()` em toda função que acessa alias
- [ ] `RecLock` só em tabela `Z*`; tabela core via `MSExecAuto`
- [ ] nenhum `GetMV` / `SuperGetMV` / `Pergunte` / `ExistBlock` dentro de loop
- [ ] nenhum `MsgAlert` / `MsgYesNo` / `Aviso` / `Help` dentro de transação
- [ ] nenhum `IIF`, nenhum `Function`, nenhum `ConOut()` / `OutErr()` / `?`
- [ ] nenhum `cFilial` direto (usar `cFilAux` ou `xFilial(...)`)
- [ ] nenhum `%nolock%`; leitura com hint usa `WITH (NOLOCK)` literal
- [ ] objeto destruído com `Destroy()` quando a classe tem `Destroy()`
- [ ] nenhum `HTTPCGet` / `HTTPCPost` / `HTTPQuote` em código novo
- [ ] ordem `Local` → `Private` → código respeitada; sintaxe TLPP conferida
- [ ] notação húngara e bloco `/*/{Protheus.doc}` presentes
- [ ] nenhum símbolo usado sem ter passado pelo passo 5
- [ ] fonte em CP-1252, não UTF-8

### 11. Relatório final
Termine informando explicitamente as duas coisas:
- **Verificado no código** — com `arquivo:linha`.
- **Não confirmado / suposição** — o que ainda precisa de validação.

---

Resposta genérica, sem citar rotina, tabela ou arquivo concreto deste
projeto, é considerada falha e deve ser refeita. Idem a resposta que
entrega código sem os passos exigidos pelo tamanho da tarefa ou que pula
a autoverificação do passo 10.

---

# Diretrizes de Desenvolvimento AdvPL/TLPP — Protheus (Vortice)

## Contexto do projeto

- **ERP**: TOTVS Protheus 12, build `7.00.240223P`, banco **SQL Server**.
- **Módulo**: Suprimentos/Compras (SC7 — tomadas centrais).
- **Cliente**: Vortice Consultoria Mineral.
- **Fontes**: `FONTES/` (AdvPL `.prw`/`.prg`/`.prx` e TLPP `.tlpp`).
- **Servidor**: AppServer TOTVS `CINVJ6_DEV` (config em `CONFIG/servers.json` — contém token de sessão; nunca imprimir em docs, logs ou commits; URL e includes em `docs/workflow.md`).

## Idioma padrão

Todas as interações, documentação, comentários, mensagens de commit e revisões em **português brasileiro**. Textos de tela (legendas, mensagens, labels, títulos, motivos) também em português claro e completo — **sem abreviações** (usar "Dias de Estoque", nunca "DOS"; "Tempo de Reposição", nunca "Lead Time") e **sem termos em inglês**. Exceção mínima: nomenclatura técnica do sistema (ex.: `B1_EMAX`, MATA110) — explicação ao redor em português. Aplica-se a código novo e a manutenção.

## Perfil do usuário — vibe coding

O usuário **não programa e não conhece AdvPL/Protheus**. Ele descreve o objetivo
em português comum e delega a parte técnica. Isso muda a **comunicação**, não a
**rigorosidade**:

- **Linguagem leiga.** Todo termo técnico (alias, ponto de entrada, `MSExecAuto`,
  RPO, browse) vem acompanhado de uma linha dizendo o que é e para que serve.
  Sem abreviação e sem inglês, conforme a seção acima.
- **Toda entrega tem 3 partes:** (1) o que mudou, em uma frase; (2) o que ele deve
  testar na tela, em passos clicáveis; (3) o que ficou **não confirmado**.
- **Nunca pedir revisão de código.** Pedir validação de **comportamento** —
  "abra a rotina X, informe Y e veja se aparece Z".
- **Perguntas só de negócio**, em português comum, com 2–4 opções e a
  recomendada primeiro. Decisão técnica é do agente; decisão de regra, exceção
  ou de o que aparece na tela é do usuário.
- **Mostrar o que entendeu antes de implementar** (Passo 1 do protocolo) — o
  usuário corrige o entendimento, não o código.
- **"Não entendo" não autoriza atalho.** As regras críticas de dados, o gate
  pós-geração e a autoverificação continuam obrigatórios; só a explicação muda.

### Template do pedido

Todo pedido segue este formato. Se faltar o item 1 ou o 4, perguntar antes de
implementar:

1. **Onde** — rotina/tela/relatório pelo nome do menu (print ajuda).
2. **O que eu faço** — passos do clique/informação.
3. **O que deveria acontecer** — resultado esperado, em linguagem de negócio.
4. **O que acontece hoje** — mensagem de erro literal ou print.
5. **Impacto** — quem usa, frequência, se trava o trabalho.
6. **O que não pode mudar** (opcional) — rotina dependente.
7. **Modo** (opcional) — "com teste" ou "urgente".

Exemplo: "Tela CADSZ3; incluo item e clico em Gravar; deveria gravar; aparece
'Registro duplicado' mesmo em item novo; acontece com todos; trava o cadastro."

Regras: erro sempre literal/print; pedir **resultado**, não solução técnica; um
pedido por entrega.

## Regras críticas de dados (não podem ser violadas)

- **SQL**: sempre `D_E_L_E_T_ = ' '` (soft-delete); filtro de filial com `XX_FILIAL = xFilial('XXX')` (nunca hardcode); `FWExecStatement`/`ChangeQuery()` (anti-injection); `RetSqlName()` na tabela física.
- **Lock**: `%nolock%` é **proibido**. Em AdvPL ele é expandido pelo TOPConnect, mas neste build resolve para `%` literal e gera `WITH (%%)` (SQL inválido); fora do AdvPL nunca é expandido. Para leitura/relatório, o padrão deste repo é o hint literal `WITH (NOLOCK)` reinjetado **depois** do `ChangeQuery()` (que remove a dica) — ver `FONTES/CADSZ3.PRW`. Nunca em leitura que alimenta gravação ou cálculo financeiro.
- **RecLock somente em tabelas `Z*`** (customizadas). Tabelas core (SC5, SC6, SC7, SD1, SD2, SF1, SF2, SB1, SA2, etc) → **MSExecAuto**.
- **Sem UI dentro de transação** (`MsgAlert`, `MsgYesNo`, `MsgInfo`, `Aviso`, `Help`, `Pergunte`, `ParamBox`) — deadlock multi-user (CA1002).
- **Nunca** chamar `GetMV()`, `SuperGetMV()`, `ExistBlock()`, `Type()`, `Pergunte()` dentro de loop.
- **`Function` proibido** em customização — use `User Function` (público) ou `Static Function` (interno ao arquivo). Escopo `Function` é reservado ao produto.
- **`FWLogMsg` em vez de `ConOut()`/`OutErr()`/`?`** (CA1004). Assinatura: `FWLogMsg(cLevel, cGroup, cCategory, cSource, cDetail, cLogId, cMessage)`.
- `GetArea()`/`RestArea()` obrigatório em toda função que acessar alias. Nunca use a variável reservada `cFilial` — use `cFilAux` ou `xFilial('XXX')`.

## Encoding e fluxo de compilação

Fontes `.prw/.prg/.prx/.tlpp/.ch/.aph` em **CP-1252** — nunca UTF-8 (o RDMake ignora/corrompe UTF-8 no RPO). Fluxo obrigatório: **gerar (UTF-8) → converter para CP-1252 → compilação manual do usuário → review**.

> **Compilação é sempre manual, feita pelo usuário.** O agente **nunca** dispara compilação, envia fonte ao RPO ou automatiza esse passo (não executa `advpl-tlpp-compile`, `advpls.exe` nem hook de build). Entrega o fonte já em CP-1252 e pede que o usuário compile no VS Code/TDS, devolvendo o resultado. Até esse retorno, o status é **"aguardando compilação do usuário"** — nunca "pronto".

> **Sem hooks automáticos**: os hooks antigos de conversão/revisão/compilação foram **removidos** do `.opencode/settings.json` (nunca funcionaram — comandos fora do PATH e `C:\totvs` inexistente). O agente executa apenas a conversão, pela skill `utf8-to-cp1252-conversion` (`skills/advpl-tlpp/`). O **LSP AdvPL** (`totvs-protheus`) está ativo e devolve diagnósticos de sintaxe/semântica após editar `.prw`/`.tlpp` — usá-los como verificação. Detalhes em `docs/workflow.md`.

## Sintaxe que quebra compilação (AdvPL/TLPP)

Regras com exemplos certo/errado em `docs/convencoes.md` (§TLPP Types, §Ordem
obrigatória em toda função/método, §Classes, §Include Files). Em `.prw` não
existe `as` — tipagem só por prefixo húngaro.

## Memória e documentação

Consultar `.opencode/memory/` (índice `MEMORY.md`) e, se disponível, o vault Obsidian em `C:\Users\Vortice 0097\Desktop\BKP_JUAN\Memoria\Memoria\ADVPL-Protheus\`. Ver `docs/workflow.md` para a precedência e a cadeia de fallback.

## Arquivos de apoio (consultar sob demanda, não são contexto fixo)

- **`docs/fontes.md`** — ler para localizar um fonte em `FONTES/`, ver a árvore de diretórios e convenções de nome/case.
- **`docs/tabelas.md`** — ler para tabelas-chave de Suprimentos, filtros canônicos, comparação de CNPJ e regras de pontos de entrada.
- **`docs/convencoes.md`** — ler para notação húngara, tipos AdvPL/TLPP, ordem de declaração, classes, includes, padrões SonarQube, MSExecAuto, MVC, API Symbol Validation e SmartView.
- **`docs/workflow.md`** — ler para SDD, compilação, hooks, unlazy, testes, debugging e a cadeia de fallback de documentação.
- **`docs/agents-totvs-oficial.md`** — espelho de `instructions/AGENTS.md` do repo `totvs/engpro-advpl-tlpp-skills` (verificado idêntico ao HEAD em 30/10/2026), com os caminhos corrigidos para esta máquina. Consultar sob demanda — **não substitui** as regras críticas deste arquivo.
- **`CONFIG/references_sonarqube-rules-reference.md`** — regras SonarQube G1–G5 (segurança, performance, legado, metadados, compilação) com IDs e severidade. Ler antes de gerar ou revisar código.
- **`CONFIG/tir/`** — testes TIR (Python, `unittest` + `tir.Webapp`) E2E de SmartClient/Webapp; padrão em `tir-test-generator`.
- **`docs/diagnostico.md`** — ler quando o assunto for diagnóstico de duplicidade ou erro de dados: queries de conferência em SC7, padrões de grep para gravações em SC7/SC1/SC8 e fatos já verificados com `arquivo:linha`.

## Roteamento obrigatório de skills

Antes de gerar código, **localize** a skill em `skills/` e leia o `SKILL.md`.
Roteamento por tarefa: `skills/README.md` §"Referência rápida: qual skill usar";
catálogo legível por máquina: `skills/skills-registry.json`. **Nunca invente nome
de skill.** As skills de usuário ficam em `C:\Users\Vortice 0097\.qoder\skills\`
(carregadas pelo host, fora do registry) e seguem o mesmo roteamento.

Rota por tarefa (espelho de `skills/README.md` §7 — se divergir, o README vence):

| Eu quero... | Skill |
| --- | --- |
| Criar tela CRUD MVC (Modelo 1 / Modelo 3) | `mvc-generator` |
| Tela virtual de consulta (não MVC) | `advpl-tela-consulta` |
| Dimensionar tela modal / tela abrindo cortada | `advpl-msdialog-dimensionamento` |
| Erro `variable is not an object` após `ACTIVATE MSDIALOG` | `advpl-msdialog-ciclo-de-vida` |
| Ponto de entrada novo ou alterado | `entry-point-designer` · catálogo em `pontos-entrada` |
| Expor API REST | `tlpp-rest-endpoint-generator` |
| Consumir API REST externa | `fwrest-client-generator` |
| Exportar dados para `.xlsx` | `fwmsexcelxlsx-generator` |
| SQL embarcado / escolher entre SQL e workarea | `query-builder` · `embedded-sql` |
| Garantir SQL seguro (TopConnect) | `sql-safe` · `query-builder` |
| Otimizar consulta lenta | `sql-optimization` |
| Consultar dicionário (SX2/SX3/SIX/SX6/SX5/SX7) | `data-dictionary-lookup` · `tabelas-protheus` |
| Gerar script de configuração SX | `sx-configuration` |
| Consultar função nativa / parâmetro MV | `protheus-reference` |
| Entender processo de negócio do ERP | `protheus-business` |
| Convenções da empresa (SIGAEST, banco, UI) | `advpl-empresa` |
| Regra de implementação segura em Suprimentos | `protheus-rules` |
| Resolver F3 / Consulta Padrão / FWLookup | `solucoes-consultas` |
| Revisar código | `code-review` · `advpl-code-review` |
| Revisar SQL | `sql-code-review` |
| Refatorar / reduzir complexidade | `refactor` · `refactor-method-complexity-reduce` · `advpl-refactoring` |
| Migrar `.prw` para `.tlpp` | `advpl-to-tlpp-migration` |
| Teste E2E de tela | `tir-test-generator` |
| Teste unitário TLPP | `probat-testing` |
| Validar antes de concluir | `advpl-quality-checklist` · `verification-evidence` |
| Debugar erro em execução | `advpl-debugging` · `systematic-debugging` |
| Erro `SSYacc0105e` em FWMBrowse/MVC | `advpl-fwbrowse-fwbldfeature-bug` |
| Evitar repetir erro já conhecido | `advpl-error-memory` |
| Mapear arquivos antes de implementar | `context-map` |
| Planejar implementação | `create-implementation-plan` · `writing-plans` |
| Conduzir feature com SDD | `advpl-tlpp-sdd` |
| Documentar com ProtheusDOC | `documentation-writer` · `documentation-patterns` |
| Gerar código AdvPL/TLPP do zero | `advpl-code-generation` · `advpl-protheus` · `advpl-tlpp-reference-guide` |
| Explicar código em linguagem simples | `code-explanation` |
| Gerar changelog | `changelog-patterns` |
| HTML/CSS/JS de tela WebApp | `frontend-quality` |
| Rotina do cliente (fluxo completo) | `vortice-workflow` |
| Método — pensar antes de criar | `brainstorming` · `writing-plans` · `executing-plans` · `subagent-driven-development` · `dispatching-parallel-agents` |
| Método — qualidade antes de concluir | `test-driven-development` · `verification-before-completion` · `requesting-code-review` · `receiving-code-review` · `finishing-a-development-branch` · `using-git-worktrees` |
| Criar ou editar skill | `writing-skills` · `using-superpowers` |

**Telas MSDIALOG — uso sempre obrigatório (pedido do usuário em 10/11/2026):**
antes de criar, redimensionar ou corrigir corte em qualquer tela modal, carregue
e siga `advpl-msdialog-dimensionamento` (moldura = 2x o bounding box dos
controles; cada controle declarado como px desejados / escala; auditar com
`skills/vortice/advpl-msdialog-dimensionamento/scripts/calc_frame.py`) e
`advpl-msdialog-ciclo-de-vida` (capturar valores dos controles no ACTION antes do
`oDlg:End()`; nada de `oControle:` após o `ACTIVATE`; auditar com
`skills/vortice/advpl-msdialog-ciclo-de-vida/scripts/check_pos_activate.py`).
As duas skills e os dois scripts estão **dentro do repositório** (`skills/vortice/`),
não dependem de pasta do host. Valem mesmo quando o pedido não mencionar corte:
toda tela nova passa pelas duas skills e pelos dois scripts antes de ser entregue.

**Fonte AdvPL/TLPP — uso sempre obrigatório:** antes de criar ou alterar
qualquer `.prw`/`.prg`/`.prx`/`.tlpp`, carregue `advpl-padrao-fonte`
(`skills/vortice/advpl-padrao-fonte/SKILL.md`). É o molde medido dos 79 fontes
de `FONTES/` — header `/*/{Protheus.doc}`, ordem dos blocos, `GetArea`/`RestArea`,
SQL TopConnect, ponto de entrada, tela `mBrowse`, classe TLPP; os 6 moldes
prontos (A–F) estão em `references/templates.md`. Copie a forma do fonte mais
parecido antes de escrever. Antes de entregar, rode a auditoria no arquivo
alterado:

```powershell
python skills\vortice\advpl-padrao-fonte\scripts\auditar_padrao.py FONTES\ARQUIVO.PRW --estrito
```

Entregue só com **0 ERRO** (código de saída 0). `ENC`, `NOLK`, `FUNC`, `AREA`,
`INC`, `TXUI` e `FILI` são erro em qualquer perfil; com `--estrito`,
`DOC`/`TYPE`/`DECL`/`ALGN` também são erro — regra de fonte **novo**. Em fonte
existente, `AVISO` é dívida de legado: não justifica reformatar o arquivo
(regra de mudança mínima), corrija só o que o pedido toca.

## Regras de geração de código (resumo — detalhe em `docs/convencoes.md`)

- **Entry Points**: nome sem prefixo `U_` (`User Function MT410INC()`, nunca `U_MT410INC()`); nome do arquivo = nome do PE, maiúsculo.
- **Notação húngara obrigatória**: `c`/`n`/`d`/`l`/`a`/`o`/`b`/`x`/`j`.
- **Includes**: código novo `#include "totvs.ch"`; legado que já usa `Protheus.ch` mantém (migrar só se tocado em refactor). TLPP: `tlpp-core.th` primeiro.
- **`IIF` proibido** (use `If/Else/EndIf`, CA4000); sem ISAM/`MSCREATE`/`DBCREATE`/`CRIATRAB` (use `FWTemporaryTable`, CA1000).
- **REST**: para **consumir** API externa use `FWRest` (`SetTimeOut`, `GetHTTPCode`, `SetLegacySuccess(.F.)`) e leia segredos de `GetMV()`. `HTTPCGet`/`HTTPCPost`/`HTTPQuote` só em chamada workstation com WebAgent ou quando precisar de PATCH. Para **expor** endpoint, TLPP com `@Get`/`@Post`/`@Put`/`@Patch`/`@Delete`.
- **Objetos**: destruir com `Destroy()` da própria classe quando existir; nunca `FwFreeObj()`, `FreeObj()` ou `FwFreeArray()` como substituto.
- **SonarQube**: gerar/revisar sem violação CRITICAL/MAJOR; apontar violação pelo ID da regra (ex.: `CA2050 — SQL Injection`). Referência G1–G5: `CONFIG/references_sonarqube-rules-reference.md`.
- **Padrão do fonte**: toda entrega de `.prw`/`.tlpp` segue `advpl-padrao-fonte` e passa por `scripts/auditar_padrao.py <arquivo> --estrito` com 0 ERRO (§"Roteamento obrigatório de skills").
- Todo código novo com bloco `/*/{Protheus.doc}` (`@type`, `@author`, `@since`, `@param`, `@return`).

## Gate pós-geração (antes de declarar pronto)

1. **Encoding** — converter o fonte para CP-1252 (`utf8-to-cp1252-conversion`). UTF-8 corrompe acento no RPO.
2. **Compilação** — LSP AdvPL pelo agente; a compilação real é executada **pelo usuário** (seção "Encoding e fluxo de compilação"). Erros como retorno incompatível com a declaração do `static method` **não** aparecem no LSP: só na compilação real — registrar aqui o retorno do usuário.
3. **Review** — `code-review`/`advpl-code-review`; apontar cada violação com o ID SonarQube.
4. **Gap analysis** — comparar item a item o original/requisito com o entregue: ✅ migrado, ⚠️ não-migrável (com a limitação documentada), 🔄 preservado no legado. Acesso (`VerifyAccess`, `MPUserHasAccess`), parâmetro (`SuperGetMV`), modo de acesso (`FWModeAccess`), módulo/país (`cPaisLoc`) e `FindFunction` **não** são tratados pelo framework — se existiam, precisam estar explícitos. Nunca omitir comportamento em silêncio.
5. **Relatório** — apresentar o gap analysis e o que ficou "não confirmado" antes de encerrar.

## Regras de trabalho

Extraídas dos prompts de referência (Codex GPT-5 e Claude Code) — apenas o que se aplica ao OpenCode.

- **Ler antes de editar.** Pesquisar o código real antes de escrever: busca por padrão/conteúdo, leitura dos arquivos envolvidos, das rotinas parecidas e das convenções locais. Nada de resposta de memória.
- **Mudança mínima.** Tocar somente o que o pedido exige; preservar edições pré-existentes do usuário (não sobrescrever, não "limpar" o que não foi pedido); sem refactors, comentários ou arquivos extras não solicitados.
- **Preferir editar a criar.** Editar arquivo existente sempre que possível; criar arquivo novo só quando indispensável; nunca criar documentação (`.md`, `README`, relatórios) por conta própria.
- **Planejar antes de executar.** Tarefa média/grande: decompor, definir abordagem, listar arquivos críticos, dependências, ordem de execução e riscos. Durante o planejamento, somente ações de leitura — nada de edição, formatação ou comando que altere estado.
- **Explorar antes de perguntar.** Dúvida sobre fato do repositório (arquivo, símbolo, convenção, configuração, parâmetro) se resolve com busca, não com pergunta. Perguntar só preferência ou trade-off real: 2–4 opções mutuamente exclusivas, a recomendada em primeiro, com justificativa.
- **Não inventar nada.** Nome de arquivo, função, campo, parâmetro, API, caminho ou constante só se confirmado no repo ou na documentação oficial. Sem confirmação, escrever literalmente "não confirmado". Plano/spec sai completo: quem for implementar não pode precisar decidir nada.
- **Verificar na proporção do risco.** Mudança pequena: leitura e validação lógica. Mudança em dados, transação ou rotina crítica: checar os diagnósticos do LSP AdvPL, compilar e revisar antes de declarar pronto.
- **Escopo e autorização.** Pedir, explorar, explicar, revisar ou diagnosticar não autoriza alteração de arquivo — implementar somente quando o pedido incluir a mudança. Ação destrutiva (reset, exclusão, sobrescrita, commit, push) só com confirmação explícita e alvo exato; preferir operações reversíveis.
- **Concisão sem perder correção.** Liderar a resposta final pelo resultado, sem preâmbulo nem reprise dos passos. Relato de erro, saída de teste que falhou, aviso de segurança e confirmação de ação destrutiva mantêm o conteúdo completo.
- **Comunicação direta.** Sem elogiar o próprio plano por contraste com uma alternativa ruim. Crítica ou objeção do usuário é respondida com evidência concreta (`arquivo:linha`) e raciocínio, não com concordância genérica.
- **Não delegar o que dá para fazer direto.** Subagente só para busca ampla/paralela ou tarefa independente. Ao concluir: relatório curto — o que foi feito, arquivos tocados (`arquivo:linha`) e o que ficou pendente.
- **Concisão não substitui o Protocolo.** A concisão vale para o texto da resposta final. O raciocínio do Protocolo de Raciocínio (nos passos exigidos pelo tamanho da tarefa) continua obrigatório e não conta como preâmbulo.

## Ferramentas de ambiente (instaladas nesta máquina)

- **`agent-desktop`** v1.2.0 (npm global, `C:\Users\Vortice 0097\AppData\Roaming\npm\agent-desktop`) — deixa o agente **ver e operar janelas do Windows** pela árvore de acessibilidade (UI Automation), sem print e sem clique físico. Usar quando o pedido citar o que está escrito na tela, clicar/preencher em app desktop (ex.: Excel, Bloco de notas) ou conferir o resultado de uma ação.
  - Observar: `agent-desktop list-apps`, `list-windows`, `snapshot --app <nome> -i --compact`; agir: `click`, `set-value`, `find --app <nome> --name <texto>`; guias embutidos: `agent-desktop skills get desktop` e `agent-desktop skills get platform`.
  - No PowerShell, ref sempre entre aspas simples (`agent-desktop click '@s1abc:e8'`), senão o `@` solto é lido como operador de splatting.
  - Ref pertence ao snapshot: se a tela mudou, gerar snapshot novo. `type`, `double-click` e `focus` exigem `--headed` (mouse/teclado físico); os demais cliques são semânticos e não roubam o foco.
  - Snapshot, clipboard e print podem conter dado pessoal/financeiro: nunca colar em log, doc ou commit.
  - Falha `INTERNAL — a window-owning process is absent` é restrição do sandbox do processo que chama (não do app): rodar fora do sandbox resolve.
  - Janelas do Protheus (SmartClient) via árvore de acessibilidade: **não confirmado** — testar com uma rotina aberta antes de prometer essa automação.
