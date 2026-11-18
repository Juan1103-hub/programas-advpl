# Template de relatorio - revisao funcional de tela

## Estrutura

```
## Veredito do <NOME DA TELA> (<alias>) - <data>

Uma frase com o resultado geral: o CRUD basico esta OK? o que esta quebrado?

| Acao / botao | Veredito | Evidencia | Como testar |
| --- | --- | --- | --- |
| Incluir | OK | AxInclui + cCadastro em ARQ:40 | incluir item novo e ver na grade |
| Alterar | OK | AxAltera em ARQ:33 | alterar posicao e reabrir |
| Excluir | QUEBRADO | ARQ:233 RecNo() depois de Count To em ARQ:225 | pesquisar, selecionar e excluir |
| ... | | | |

### Nao confirmavel

- <dependencia de dicionario/permissao/dado> - como validar.

### Roteiro de teste (ordem)

1. ...
2. ...

### Status

Aguardando compilacao do usuario / aguardando teste de tela.
```

Regras:

- **uma linha por botao**, inclusive os extras;
- evidencia sempre `ARQUIVO:linha` (nome curto);
- "Como testar" em passos clicaveis, sem termo tecnico;
- nunca escrever "funciona": escrever "as mecanicas existem" / "falta X";
- achado de regra de negocio (ex.: manter 1 registro) nao e defeito: registrar como decisao.

## Exemplo real - CADPOSIC (16/11/2026)

| Acao / botao | Veredito | Evidencia | Como testar |
| --- | --- | --- | --- |
| Incluir | OK, depende do dicionario | `AxInclui` + `cCadastro` (CADPOSIC:40); gatilho `FFZC1ITM` (ZPOSITEM:27) precisa estar na SX7 | incluir codigo existente no SB1 e ver descricao/armazem/saldo preenchidos |
| Alterar | OK | `AxAltera` (CADPOSIC:33) | alterar a posicao, sair e voltar |
| Excluir | QUEBRADO (antes) / OK (depois) | antes: `Count To` (225) + `RecNo()` (233) sem `DbGoTo` -> `MSRLOCK` em EOF; depois: `nRec` (232) + `DbGoTo` (243) | pesquisar o item, excluir e limpar a pesquisa |
| Imprimir | BOTAO MORTO | `{"Imprimir","Imprimir",0,6}` (35), rotina inexistente no repo | clicar em Imprimir |
| Atualizar | OK | `FPOS_REFRESH` (357-402) confere lock (385) e da `Refresh` (399) | clicar e ver o saldo recalculado |
| Importar Planilha | 3 defeitos | sem `Refresh` (200-210); `cLocal` vazando (90/159); layout 2 colunas (138) x CSV de 3 | importar o CSV real e conferir posicao/descricao |
| Limpar Registros | 1 defeito | `RecLock` sem conferencia (440-441) | rodar com outro usuario no registro |
| Fechar / ESC | OK | `Activate` (66) + `RestArea` (68) | fechar e reabrir duas vezes |
| Filial | OK | `SetFilterDefault` com `xFilial("ZC1")` (CADPOSIC:52); exclusão e limpeza conferem a filial (CADPOSIC:282, CADPOSIC:496) | ver se aparecem itens de outra filial |
| Permissao | NAO CONFIRMAVEL | sem `cDelFunc`/`VerifyAccess` | testar com perfil sem acesso |

Saida do script na versao corrigida: `0 ERRO(s), 1 AVISO(s)` - o aviso
restante e `PERMISSAO` (decisao do usuario: o menu ja restringe o acesso ou
nao). Os avisos `AREA` e `FILIAL` foram resolvidos com `GetArea`/`RestArea`
nas funcoes auxiliares e `SetFilterDefault` no browse.
