---
name: advpl-tela-crud-review
description: Revisao funcional (nao estetica) de tela de cadastro em browse - mBrowse ou FWMBrowse - a partir do codigo AdvPL. Responde se a tela inclui, altera, exclui, visualiza, pesquisa e fecha como deveria, botao por botao, apontando botao morto, posicao de registro perdida (Count To antes do RecNo gera MSRLOCK em EOF), lock sem conferencia, falta de Refresh, area nao restaurada, filial e permissao. Inclui scripts/revisar_tela.py (detector deterministico, exit 0/1). Usar depois de criar ou alterar tela de cadastro, antes de entregar para compilacao, ou quando o usuario perguntar "a tela esta excluindo/editando/incluindo como deveria?".
---

# Revisao funcional de tela CRUD em browse (Vortice)

> Revisa **comportamento**, nao estilo. Forma do fonte e `advpl-padrao-fonte`;
> regra SonarQube e `code-review`; regra de negocio e `protheus-business`.
> Esta skill responde: **cada botao da tela faz o que promete, de acordo com o codigo?**

## Quando usar

- Depois de criar, alterar ou corrigir tela de cadastro em `mBrowse` ou `FWMBrowse`.
- Antes de entregar o fonte para a compilacao manual do usuario.
- Quando o usuario relatar "o botao X nao funciona" e ainda nao houver causa.
- Quando o usuario perguntar se o CRUD basico "esta correto".

## Quando nao usar

- Tela `MSDIALOG` de consulta (usar `advpl-tela-consulta`, `advpl-msdialog-dimensionamento`, `advpl-msdialog-ciclo-de-vida`).
- Ponto de entrada, relatorio, REST, rotina sem tela.
- Revisao de forma/encoding (usar `advpl-padrao-fonte` + `code-review`).

## Regra de ouro

**Codigo prova mecanica; teste na tela prova comportamento.** A revisao nunca
conclui "funciona" - conclui "as mecanicas existem" ou "falta X". O que depende
de dicionario (SX7, SIX, unique key), de permissao ou de dado real entra sempre
como **NAO CONFIRMAVEL** com o roteiro de teste.

## Metodo em 5 passos

### 1. Extrair o contrato da tela

Do fonte principal, ler e listar:

- alias (`SetAlias`/`mBrowse`), `cCadastro`, `aRotina` completo;
- `SetSeek`/`aSeek` (campos, ordem do indice, tamanhos literais em tabela `Z*`);
- `SetFilter`, `cDelFunc`, privates (`oBrowse...`, flags), `SetTimer`;
- includes e o alias/tabela que a tela grava.

### 2. Mapear cada rotina do `aRotina`

Para cada item: botao -> rotina -> tipo (2 visualizar, 3 incluir, 4 alterar,
5 excluir, 6 outros). Classificar:

| Classe | Regra |
| --- | --- |
| Nativa | nome comeca com `Ax` (`AxVisual`, `AxInclui`, `AxAltera`, `AxDeleta`) - o framework cuida de lock/refresh |
| Custom | existe em `FONTES/` - aplicar o checklist da acao |
| Inexistente | nao declarada em nenhum fonte do repo - **botao morto** (confirmar se nao existe no RPO) |

### 3. Aplicar os 6 gates em toda rotina custom

| Gate | O que verificar | Erro tipico |
| --- | --- | --- |
| Posicao | a rotina guarda `RecNo()` **antes** de `Count To`/`DbGoTop`/`DbSeek` e volta com `DbGoTo` antes de gravar/excluir | `MSRLOCK` "tentativa de reservar registro em EOF" |
| Lock | `RecLock` conferido; sem lock nao grava/apaga; tabela core sempre via `MSExecAuto` | registro de outro usuario apagado sem trava |
| Refresh | rotina custom chama `Refresh()` da grade (ou reabre a query) no fim | lista nao mostra o que acabou de gravar/excluir |
| Soft-delete | `DbDelete` respeita `D_E_L_E_T_`; reinsercao de codigo excluido nao duplica chave | erro de chave duplicada na reimportacao |
| Area | `GetArea`/`RestArea` em quem troca de alias; `RestArea` depois de excluir pode reposicionar no registro apagado | alias atual errado ao voltar para a tela |
| Confirmacao | exclusao/destrutivo pede confirmacao com nome do que sera apagado | usuario apaga sem perceber |

### 4. Checklist transversal

- **Fechar/ESC**: `Activate` retorna, `RestArea` executado, privates recriadas ao reabrir, sem `SetTimer` pendente.
- **Tabela vazia**: a tela abre com 0 registros? Existe trava de "ultimo registro" (ARQVAZIO)? A trava conta o filtro da pesquisa?
- **Busca/funil**: `aSeek` com ordem existente no SIX; funil (modo coluna) pode filtrar diferente do modo chave.
- **Filial**: `SetFilterDefault` no browse (com `xFilial`) ou `DbSetFilter` no alias; sem isso a grade mostra todas as filiais.
- **Permissao**: botao destrutivo (excluir/limpar/importar) com `cDelFunc`, `MPUserHasAccess` ou `VerifyAccess`.
- **Dicionario**: gatilho SX7, indice unico, campo virtual (`X3_CONTEXT = 'R'`) - dependencia externa ao fonte.
- **Botoes extras**: Importar/Atualizar/Limpar existem, atualizam a grade e tratam erro de arquivo/lock.

### 5. Emitir o relatorio

Formato em `references/relatorio-template.md`. Uma linha por acao, com
`arquivo:linha`, veredito e o clique de teste correspondente. Fechar com
"NAO CONFIRMAVEL" e o roteiro para o usuario validar na tela.

## Script

```powershell
python skills\vortice\advpl-tela-crud-review\scripts\revisar_tela.py FONTES\CADPOSIC.PRW
python skills\vortice\advpl-tela-crud-review\scripts\revisar_tela.py FONTES --estrito
```

| Achado | Severidade | Detecta |
| --- | --- | --- |
| `BOTAO_MORTO` | AVISO | rotina do `aRotina` sem declaracao nos fontes do repo |
| `POSICAO` | ERRO | exclusao/alteracao do registro atual sem `DbGoTo`/`DbGoTop` depois de `Count To`/`RecNo()` |
| `LOCK` | ERRO | `DbDelete()` sem `RecLock` conferido |
| `REFRESH` | AVISO | rotina custom de escrita sem `Refresh()` |
| `AREA` | AVISO | `DbSelectArea` sem `GetArea`/`RestArea` |
| `FILIAL` | AVISO | browse sem `SetFilterDefault`/`DbSetFilter` |
| `PERMISSAO` | AVISO | botao destrutivo sem validacao de acesso |
| `LOOP` | AVISO | `GetMV`/`SuperGetMV`/`Pergunte`/`Type` dentro de laco |

`--estrito` eleva todo achado a ERRO (gate de tela nova). Codigo de saida 0 =
sem ERRO, 1 = com ERRO. Zero achados **nao** significa "funciona": significa
"nenhuma falha mecanica conhecida" - o teste na tela continua obrigatorio.

## Vereditos

- **OK** - mecanica presente no codigo (ex.: rotina existe, reposiciona, da `Refresh`).
- **SUSPEITO** - mecanica presente mas com risco (ex.: sem permissao, sem filtro de filial).
- **QUEBRADO** - mecanica ausente ou errada (botao morto, escrita sem posicao, sem lock).
- **NAO CONFIRMAVEL** - depende de dicionario, permissao, dado real ou comportamento do framework.

## Nao fazer

- Nao alterar o fonte durante a revisao; achado vira relatorio, correcao e entrega separada.
- Nao declarar "pronto" sem a compilacao do usuario e sem o teste de tela.
- Nao inventar API do framework (`FWMBrowse`): se o metodo nao estiver confirmado, escrever "nao confirmado".
- Nao tratar achado como defeito de negocio: regra (manter 1 registro, bloquear exclusao) e decisao do usuario.

## Arquivos de apoio

- `references/checklist-por-acao.md` - o que checar em cada botao, no codigo e na tela.
- `references/relatorio-template.md` - formato de saida com exemplo real.
- `references/casos.md` - casos ja diagnosticados (comeca pelo EOF do CADPOSIC).
- `scripts/revisar_tela.py` - detector deterministico.
