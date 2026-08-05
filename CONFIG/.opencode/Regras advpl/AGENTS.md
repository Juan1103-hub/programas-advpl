# Regras para Projetos ADVPL/Protheus

Estas regras se aplicam exclusivamente a projetos ADVPL/TLPP em
ambiente Protheus, incluindo:

- Rotinas MVC (ModelDef, ViewDef, ControllerDef)
- Pontos de entrada e gatilhos
- Dicionário de dados (SX2, SX3, SXB, SIX)
- Relatórios (TReport, FWMSPrinter)
- Rotinas legadas (padrão 1.0/2.0)
- Consultas SQL (TCQuery, TCGetDB) e transações (RecLock/MsUnlock)
- Integrações REST/FWRest e webservices Protheus
- Customizações de módulo (SIGAEST, SIGACFG, SIGAFAT etc.)

Estas regras não se aplicam a projetos HTML, CSS, JavaScript,
TypeScript, React, Next.js, Node.js ou qualquer stack web fora do
Protheus.

Para projetos web, utilizar o AGENTS.md específico do respectivo
workspace.

---

# AGENTS.md — Global ADVPL/Protheus

## Idioma

1. Sempre responder em português (PT-BR), exceto se solicitado outro
   idioma.
2. Tom direto, sem preâmbulos.
3. Respostas longas em Markdown estruturado.

## Perguntas ao usuário

Usar a ferramenta `question` com janela interativa sempre que houver:

- Dúvida sobre tabela, campo, alias ou estrutura do dicionário de dados.
- Decisão entre abordagens técnicas (ex.: ponto de entrada vs.
  customização direta da rotina).
- Confirmação antes de alterar rotina padrão, gatilho ou ambiente de
  produção.
- Ambiguidade sobre regra de negócio do módulo (SIGAEST, SIGACFG etc.).
- Aprovação de plano, task ou qualquer ação irreversível.

Exceção: perguntas triviais sem impacto podem ser feitas em texto puro.

## Skills — consulta obrigatória

Antes de qualquer tarefa técnica em ADVPL:

1. Verificar as skills acessíveis ao OpenCode: `advpl-empresa`,
   `tabelas-protheus`, `pontos-entrada`, `solucoes-consultas` e as
   referências TOTVS/engpro configuradas.
2. Carregar apenas as skills cuja descrição corresponda à demanda.
3. Se a skill certa não cobrir o caso, consultar as referências
   TOTVS/engpro antes de decidir.
4. Se mesmo assim houver dúvida sobre dados reais do ambiente
   (tabela, campo, índice, relacionamento), não decidir sozinho.
5. Não carregar todas as skills por padrão.

## Regra crítica contra suposições no Protheus

- Nunca inventar nome de tabela, campo, alias, índice, parâmetro de
  configuração (MV_/PARAMETRO) ou regra de negócio de módulo.
- Se a skill e os arquivos existentes não confirmarem a estrutura,
  gerar uma consulta SQL/AdvPL para validação e pedir para o usuário
  confirmar no APSDU antes de decidir a implementação.
- Se a dúvida envolver comportamento de rotina padrão, verificar
  primeiro se existe ponto de entrada documentado antes de sugerir
  alteração direta da fonte padrão.

## Resolução de conflitos

1. Hierarquia: instruções do usuário > AGENTS.md do projeto >
   AGENTS.md pai > skills ADVPL específicas > referências TOTVS/engpro
   > subagentes.
2. Skill mais específica (ex.: `pontos-entrada`) vence skill mais geral
   (ex.: referência TOTVS genérica).
3. Em conflito irredutível entre skill e comportamento observado no
   ambiente real, o comportamento real do Protheus prevalece; reportar
   a divergência ao usuário.
4. Nunca sobrepor regra de negócio da empresa com prática genérica de
   mercado sem confirmar com o usuário.

## Fallback de modelo

- Erro 429/503/5xx/timeout no modelo principal: 1 retry após 5s, depois
  fallback para `small_model`, se configurado.
- Preferir modelo mais forte para: lógica de transação, pontos de
  entrada, cálculo fiscal/financeiro, integrações e debugging complexo.
- Modelo mais simples pode ser usado para tarefas repetitivas e de
  baixo risco (ex.: ajuste de layout de tela, ajuste de mensagem).

## Operações destrutivas e sensíveis

Antes de:

- Alterar rotina padrão do Protheus diretamente (sem ponto de entrada);
- Executar `MsExecAuto` em ambiente de produção;
- Rodar `UPDATE`/`DELETE` direto em tabela do banco;
- Alterar estrutura de tabela via dicionário (SX3) em produção;
- Remover ou sobrescrever fontes `.PRW`/`.TLPP` existentes;

Fazer obrigatoriamente:

1. Listar os alvos e o impacto da operação.
2. Confirmar com o usuário, mesmo que a ação pareça simples.
3. Sugerir backup do fonte (`.bak`) antes de sobrescrever.
4. Nunca executar `MsExecAuto` ou alteração de schema em produção sem
   confirmação explícita.
5. Preferir ponto de entrada, `User Function` ou customização isolada
   em vez de alterar rotina padrão, sempre que existir essa opção.

## Commits

- Só commitar quando solicitado explicitamente.
- Revisar `git status`, `git diff` e `git log --oneline -10` antes.
- Nunca commitar credenciais, strings de conexão, `.env` ou dados de
  ambiente de produção.

## Memória persistente

### Limites

- `MEMORY.md`: máximo de 2200 caracteres.
- `USER.md`: máximo de 1375 caracteres.

### Regras

1. Registrar convenções da empresa, padrões de nomenclatura, módulos
   trabalhados e decisões de arquitetura ADVPL.
2. Não salvar dados óbvios ou facilmente redescobertos no código.
3. Consolidar entradas quando atingir 80% do limite.

## Skill bundles

### Disponíveis

- `advpl-work` — ADVPL/Protheus: geração de código, review, debug,
  qualidade e dicionário de dados.

### Regras

1. Usar o bundle `advpl-work` quando a tarefa envolver múltiplas
   camadas (ex.: ponto de entrada + consulta + ajuste de tela).
2. Usar skills individuais quando a tarefa for específica e o bundle
   trouxer contexto desnecessário.

## Progressive Disclosure

1. Sempre iniciar pelo Nível 0 (lista de skills disponíveis).
2. Carregar o conteúdo completo da skill apenas quando necessário.
3. Carregar um arquivo específico da skill somente quando exigido.
4. Evitar carregar múltiplas skills e referências TOTVS ao mesmo tempo
   sem necessidade, para não poluir o contexto do modelo.

## Repo Map / Ambiente ADVPL

1. Ao iniciar em um projeto novo, identificar módulo (SIGAEST,
   SIGACFG, SIGAFAT etc.), rotinas relacionadas e pontos de entrada
   já customizados.
2. Antes de alterar uma rotina, localizar todos os pontos de entrada
   e customizações existentes que a afetam.
3. Ao debugar, identificar a cadeia de chamadas (rotina padrão →
   ponto de entrada → função customizada) antes de propor correção.
4. Ao integrar com banco, verificar o dicionário de dados (SX3/SX2)
   antes de assumir tipo, tamanho ou obrigatoriedade de campo.

## Smart Auto-Routing

| Tipo | Modelo preferencial | Quando usar |
|---|---|---|
| Simple | Local/`small_model` | Ajuste de mensagem, label, campo de tela |
| Strong | Modelo principal | Ponto de entrada, transação, cálculo, integração, debugging complexo |

---

# Fluxo obrigatório SDD — Projetos ADVPL/Protheus

Este fluxo é exclusivo para demandas ADVPL/Protheus.

Para toda nova funcionalidade, customização, ponto de entrada,
integração, alteração de regra de negócio ou correção de bug relevante,
seguir esta sequência:

1. Discovery — entender módulo, rotina, usuário, regra de negócio e
   objetivo.
2. PRD — registrar requisitos, cenários de uso e critérios de aceite.
3. PRD Validator — identificar ambiguidades e perguntas bloqueadoras.
4. Tech Decisions — definir abordagem técnica (ponto de entrada,
   customização direta, nova rotina, TLPP) e impactos.
5. SPEC — detalhar tecnicamente: tabelas, campos, funções, parâmetros
   e fluxo de execução.
6. Spec Enricher — prever exceções, transações concorrentes, falha de
   `RecLock`, dados inconsistentes e casos de borda do módulo.
7. Planner — dividir a SPEC em tarefas pequenas e ordenadas.
8. Sprint Validator — verificar cobertura, dependências, riscos e
   testes (incluindo ambiente de homologação).
9. Aguardar aprovação explícita do plano antes de editar código.
10. Coder — implementar somente uma tarefa por vez.
11. Code Review — revisar obrigatoriamente cada tarefa concluída.
12. Acceptance Review — revisar a customização completa ao final.

## Regras de bloqueio

- Não escrever, editar ou excluir fontes `.PRW`/`.TLPP` durante as
  etapas 1 a 8.
- Não inventar tabela, campo, alias, parâmetro ou regra de negócio.
- Registrar informações ausentes como `[PENDENTE]`.
- Antes de implementar, apresentar o plano e aguardar o comando:
  `APROVAR PLANO E INICIAR`.
- Implementar apenas uma TASK por vez.
- Após cada task, executar code review antes de iniciar a próxima.
- Se o code review reprovar, corrigir somente o problema apontado e
  revisar novamente.
- Nunca alterar rotina padrão sem antes verificar se existe ponto de
  entrada disponível para a customização.

---

# Uso obrigatório e seletivo de skills

1. Ler este AGENTS.md.
2. Identificar se a demanda envolve:
   - Convenção da empresa e padrão de nomenclatura;
   - Tabela, campo, índice ou relacionamento do dicionário de dados;
   - Ponto de entrada, gatilho, MVC ou rotina padrão;
   - Consulta, filtro, FWLookup, SXB ou problema já mapeado;
   - Integração REST, webservice ou serviço externo;
   - Bug, erro, log ou performance.
3. Carregar somente as skills aplicáveis.
4. Informar:

```text
Skills selecionadas: [lista].
Motivo: [motivo curto].
```

## Mapeamento de skills ADVPL

- Convenções internas e padrões da empresa:
  usar `advpl-empresa`.
- Tabelas, campos, relacionamentos e dicionário de dados:
  usar `tabelas-protheus`.
- Pontos de entrada, gatilhos, MVC e rotinas padrão:
  usar `pontos-entrada`.
- Filtros, FWLookup, SXB, consultas e problemas já resolvidos:
  usar `solucoes-consultas`.
- Demanda ADVPL/TLPP não coberta pelas skills acima:
  consultar as referências TOTVS/engpro aplicáveis.
- Bug ou falha de lógica:
  usar skill de debugging ADVPL antes de propor mudança.
- Geração de código, review, qualidade ou dicionário combinados:
  usar bundle `advpl-work`.

## Regras contra suposições

- Nunca assumir estrutura de tabela, campo, índice, tipo de dado ou
  regra de negócio sem confirmação via skill, código existente ou
  consulta ao APSDU.
- Se a dúvida persistir após consultar skills e fontes existentes,
  gerar a consulta SQL/AdvPL de verificação e pedir confirmação do
  usuário antes de decidir a implementação.
- Antes de propor alteração em rotina padrão, verificar se existe
  ponto de entrada, gatilho ou parâmetro que resolva sem alterar a
  fonte padrão.
- Não carregar todas as skills por padrão; carregar apenas as
  necessárias para a etapa e módulo envolvidos.

---

# Início automático de novas demandas

Quando o usuário descrever uma ideia, customização, ponto de entrada,
integração, bug ou melhoria em linguagem simples, interpretar como
início de uma nova demanda ADVPL/Protheus.

## Comportamento obrigatório

1. Permanecer em modo de planejamento e somente leitura.
2. Ler este AGENTS.md e inspecionar fontes, dicionário de dados e
   pontos de entrada relacionados, sem modificar nada.
3. Identificar módulo, rotina, skills aplicáveis e ambiente afetado.
4. Informar:
   - O que foi entendido;
   - Skills selecionadas;
   - O que já pode ser confirmado;
   - O que é hipótese ou está pendente (ex.: estrutura de tabela).
5. Iniciar automaticamente o Discovery.
6. Fazer somente perguntas bloqueadoras: regra de negócio, módulo,
   ambiente, dados, ponto de entrada disponível, impacto em rotina
   padrão ou criticidade em produção.
7. Uma pergunta por vez, começando pela de maior impacto.
8. Não gerar código, PRD, SPEC, tasks ou consulta destrutiva antes de
   concluir o Discovery.
9. Ao concluir o Discovery, avançar automaticamente pelas etapas do
   fluxo SDD até o Sprint Validator.
10. Encerrar com:

```text
AGUARDANDO APROVAÇÃO PARA INICIAR A IMPLEMENTAÇÃO
```

## Exceção para demandas pequenas

1. Confirmar se a causa do problema já é conhecida (ex.: erro
   reproduzido, ponto de entrada identificado).
2. Se não for conhecida, iniciar Discovery do bug.
3. Se for conhecida, criar mini-SPEC, uma única TASK, critérios de
   aceite e teste antes de alterar o fonte.
4. Mesmo em correções pequenas, executar Code Review após implementar.

---

# Planejamento de skills da demanda

1. Ler o AGENTS.md e inspecionar fontes, pontos de entrada e
   dicionário de dados relacionados, em modo somente leitura.
2. Identificar módulo, rotina, tipo de customização e ambiente.
3. Confirmar quais skills estão disponíveis nesta sessão.
4. Listar as skills previstas por etapa:
   - Discovery/PRD/SPEC/planejamento;
   - Ponto de entrada, MVC ou rotina padrão;
   - Dicionário de dados e consultas;
   - Integração externa, se houver;
   - Debugging e code review.
5. Para cada skill, informar nome, etapa e motivo.
6. Informar módulo(s) e rotina(s) detectados.

```md
## Skills previstas

| Skill | Etapa | Motivo |
|---|---|---|
| pontos-entrada | Tech Decisions | customização sem alterar fonte padrão |

## Módulo/rotina detectados
- SIGAEST — rotina MATA010

## Skills possivelmente necessárias depois
- solucoes-consultas: se surgir necessidade de filtro/FWLookup
```

## Skill adicional durante a demanda

1. Informar a skill adicional, etapa e risco que resolve.
2. Carregar automaticamente se já estiver disponível e for claramente
   necessária.
3. Pedir confirmação se a skill não estiver disponível, exigir acesso
   externo, ou alterar escopo/arquitetura da customização.
4. Registrar a skill adicionada no plano da demanda.

---

# Revisão obrigatória após cada task

Após concluir qualquer TASK, executar code review antes de considerar
a tarefa pronta.

## Seleção da skill de revisão

- Ponto de entrada, MVC, rotina padrão:
  usar `pontos-entrada`, `advpl-empresa` e skill de debugging ADVPL.
- Consulta, filtro, FWLookup, SXB:
  usar `solucoes-consultas` e `tabelas-protheus`.
- Alteração de dicionário de dados:
  usar `tabelas-protheus` obrigatoriamente.
- Integração REST/webservice:
  usar skill de integração/segurança ADVPL aplicável.
- Bug ou comportamento incorreto:
  usar skill de debugging ADVPL.

## Checklist mínimo de revisão ADVPL

1. A TASK e os critérios de aceite foram atendidos.
2. Apenas os fontes/rotinas autorizados foram alterados.
3. Ponto de entrada usado corretamente, sem alterar fonte padrão sem
   necessidade.
4. `RecLock`/`MsUnlock` e transações (`BEGIN TRANSACTION`/`END
   TRANSACTION`) tratados corretamente, sem registro travado.
5. Validações de dicionário de dados (SX3) respeitadas.
6. Sem `SELECT *` ou consulta sem filtro de empresa/filial quando
   aplicável.
7. Sem hardcode de código de empresa, filial, usuário ou ambiente.
8. Tratamento de erro e mensagens ao usuário adequados (`MsgAlert`,
   `FwAlertError` etc., conforme padrão do projeto).
9. Testado em ambiente de homologação antes de considerar concluído.
10. Sem regressão em rotina padrão ou customização existente.

## Resultado obrigatório da revisão

- Status: `APROVADO`, `REPROVADO` ou `APROVADO COM RESSALVAS`.
- Skills de revisão utilizadas.
- Critérios de aceite avaliados um por um.
- Fontes revisados.
- Problemas bloqueadores e não bloqueadores.
- Teste realizado em homologação (sim/não) e resultado.
- Próxima ação recomendada.

## Regra de continuidade

- `APROVADO`: task concluída, libera a próxima.
- `APROVADO COM RESSALVAS`: aguardar confirmação antes da próxima task.
- `REPROVADO`: criar TASK-XXX-FIX, corrigir e revisar novamente.
- Nunca iniciar a próxima task com a atual reprovada.

---

# Aceite final da customização

Após todas as tasks aprovadas:

1. Executar Acceptance Review da customização completa.
2. Comparar com PRD, Tech Decisions, SPEC e critérios de aceite.
3. Validar em ambiente de homologação: fluxo principal, exceções,
   permissões de usuário, impacto em outras rotinas do módulo.
4. Produzir matriz de rastreabilidade:

```md
| Requisito | Cenário | Task | Teste | Status |
|---|---|---|---|---|
| RF-001 | Cenário 1 | TASK-001 | TEST-001 | APROVADO |
```

5. Informar itens aprovados, pendências, riscos e recomendação:
   pronto para produção, pronto com ressalvas ou não pronto.
6. Encerrar com:

```text
AGUARDANDO ACEITE FINAL DA CUSTOMIZAÇÃO
```
