# Checklist por acao - tela CRUD em browse

Um bloco por botao. Cada bloco tem o que verificar **no codigo** e o que pedir
para o usuario testar **na tela**. Nada aqui substitui o teste real.

## Visualizar (tipo 2)

**Codigo**

- rotina nativa `AxVisual` ou custom que so reposiciona e chama `AxVisual`/`MsDialog`;
- nao grava nada (sem `RecLock`, `DbDelete`, `MSExecAuto`);
- devolve o alias e a posicao ao sair (`GetArea`/`RestArea`).

**Tela**

- abrir um registro e fechar: os campos aparecem preenchidos e nada muda na lista.

## Incluir (tipo 3)

**Codigo**

- `Private cCadastro` declarado (sem ele `AxInclui` falha com "variable does not exist CCADASTRO");
- `Private aRotina` declarado antes de `FWMBrowse():New()`;
- campos obrigatorios/unicos vem do dicionario (SX3) ou de gatilho SX7;
- se ha gatilho (ex.: `FFZC1ITM`), ele **precisa estar cadastrado na SX7** - fora do fonte, NAO CONFIRMAVEL;
- apos gravar, a grade atualiza (framework faz no `AxInclui`; rotina custom precisa de `Refresh()`);
- **reinsercao de codigo ja excluido**: `DbSeek` nao acha registro com `D_E_L_E_T_`, entao a inclusao pode colidir com o indice unico fisico. Verificar o indice no banco antes de afirmar que funciona.

**Tela**

1. Incluir um item novo com codigo existente no SB1.
2. Conferir descricao/armazem/saldo preenchidos automaticamente.
3. Gravar e ver a linha na grade sem clicar em Atualizar.
4. Tentar incluir o mesmo codigo de novo: deve recusar (indice unico) ou avisar.

## Alterar (tipo 4)

**Codigo**

- `AxAltera` ou rotina custom posicionando **o registro selecionado** antes de abrir o formulario;
- lock conferido quando a gravacao e manual (`RecLock` em tabela `Z*`, `MSExecAuto` em tabela core);
- `Refresh()` no fim quando a rotina e custom;
- campos calculados (`SALDO`, totais) nao podem ser digitados se sao recalculados por botao.

**Tela**

1. Alterar a posicao de um item e gravar.
2. Sair da tela, voltar e conferir que a alteracao persistiu.
3. Conferir que a linha alterada continua selecionada (ou ao menos visivel).

## Excluir (tipo 5)

**Codigo**

- **a rotina guarda `RecNo()` antes de qualquer `Count To`/`DbGoTop`/`DbSeek`**;
- reposiciona com `DbGoTo` antes de excluir;
- `AxDeleta` (nativo) ou `RecLock`+`DbDelete`+`MsUnlock` (Z*);
- `Refresh()` no fim quando a rotina e custom;
- trava de "ultimo registro" conta o **total fisico**, nao a lista filtrada pela pesquisa;
- `cDelFunc` quando a exclusao depende de status.

**Tela**

1. Pesquisar o item (lista com 1 linha), selecionar e excluir.
2. Repetir sem pesquisa, com a lista completa.
3. Limpar a pesquisa e conferir que o item nao voltou.
4. Clicar excluir em registro travado por outro usuario: deve avisar, nao apagar.

## Pesquisar / funil

**Codigo**

- `SetSeek(.T., aSeek)` com array; em tabela `Z*` usar tamanho **literal** ( `TamSX3()` inline estoura "array out of bounds");
- a ordem informada no `aSeek` precisa existir no SIX da tabela;
- `FWSeek` tem bug conhecido de posicionamento em alguns builds: depois de pesquisar, a posicao do alias pode nao ser a linha exibida.

**Tela**

1. Pesquisar por chave (codigo) e por coluna (descricao).
2. Alternar o funil ligado/desligado e repetir.
3. Depois de pesquisar, excluir a linha encontrada - este e o teste que expos o `MSRLOCK` no CADPOSIC.

## Imprimir (tipo 6)

**Codigo**

- a rotina citada no `aRotina` **existe** (`User Function`, `Static Function` ou funcao de produto);
- usa TReport/FwMsExcel conforme o padrao do repo (`advpl-lista-itens-consulta`);
- nao imprime direto dentro de transacao.

**Tela**

- clicar e ver o relatorio/arquivo; se nao houver rotina, remover o botao.

## Botoes extras (Atualizar, Importar, Limpar)

**Codigo**

- rotina existe e esta no `aRotina` com tipo 6;
- atualiza a grade no fim (`Refresh()`);
- **conta/grava por linha**: variavel de trabalho reiniciada a cada iteracao (ex.: armazem do item anterior vazando);
- importacao aceita o layout que o usuario realmente tem na mao (2 ou 3 colunas);
- `RecLock` conferido no laco; registro travado entra na mensagem final;
- botao destrutivo pede confirmacao com a quantidade.

**Tela**

1. Importar a planilha real usada pelo usuario.
2. Conferir na grade se posicao e descricao cairam nas colunas certas.
3. Rodar Atualizar e ver a coluna de saldo recalculada.
4. Limpar registros e conferir que sobrou 1 e que a grade atualizou.

## Fechar / ESC

**Codigo**

- `oBrowse:Activate()` seguido de `RestArea(aArea)`;
- privates (`aRotina`, `cCadastro`, `oBrowse...`) recriadas ao reabrir;
- sem `SetTimer` ativo apontando para rotina da tela.

**Tela**

- fechar pelo X e pelo ESC; reabrir a tela duas vezes e conferir que a grade e os botoes continuam funcionando.

## Tabela vazia

**Codigo**

- se existe trava de "ultimo registro", ela precisa deixar excluir quando ha mais de um registro **na tabela** (nao na lista filtrada);
- mensagem clara em vez de erro do framework (`ARQVAZIO`, `MSRLOCK`).

**Tela**

- excluir ate sobrar 1; tentar excluir o ultimo e ler a mensagem.

## Filial

**Codigo**

- `SetFilterDefault` no browse (padrao `oBrowse:SetFilterDefault("@ZC1_FILIAL = '" + xFilial("ZC1") + "'")`) ou `DbSetFilter` no alias;
- sem filtro, a grade mostra registros de todas as filiais e a exclusao pode atingir outra filial.
- botao destrutivo (Limpar) que percorre o alias inteiro precisa pular registros de outras filiais.

**Tela**

- conferir se aparecem itens de outra filial; se sim, decidir com o usuario se e intencional.

## Permissao

**Codigo**

- `cDelFunc`, `MPUserHasAccess` ou `VerifyAccess` nos botoes destrutivos;
- "Limpar Registros" e "Importar Planilha" sao os mais perigosos.

**Tela**

- testar com usuario sem permissao (ou perguntar ao usuario qual perfil deve ter acesso).
