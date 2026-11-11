---
name: advpl-msdialog-dimensionamento
description: Dimensiona telas MSDIALOG (Modelo 1) no SmartClient/Protheus quando a moldura usa o valor literal em pixels mas as coordenadas dos controles renderizam com zoom (~2x neste ambiente). Usar quando uma tela .prw abrir cortada (ultima coluna do browse, botoes, grupo ou lista fora da janela), quando o usuario disser que o botao ficou cortado ou grande demais, quando uma lista/listbox cortar a direita por largura declarada em pixels renderizados, ou antes de escrever uma tela modal nova. Define a moldura como ~2x o bounding box dos controles, declara cada controle como px desejados / escala, confere a soma das colunas do browse e valida contra os precedentes ZANALBX, IMPSLDINI, CADSZ3 e ZSOLNF. Substitui o "aumentar um pouco a largura" e o "engordar o controle".
argument-hint: <arquivo .prw e faixa de linhas da tela>
user-invocable: true
---

# Dimensionamento de telas MSDIALOG (Modelo 1)

## Visao geral

Em `DEFINE MSDIALOG ... FROM <topo>, <esq> TO <altura>, <largura> PIXEL` a moldura e
aplicada **literalmente**, mas as coordenadas dos controles (`@ linha, coluna ... SIZE
largura, altura`) renderizam com zoom do ambiente. Neste ambiente o zoom medido e
**~2x**: um group declarado com 355 de largura ocupou ~700 px dentro de uma janela de
800. Consequencia direta: **so cabe o que estiver dentro da metade declarada da
moldura**. Tudo que passar de `largura/2` ou `altura/2` fica fora da janela.

Regra unica desta Skill:

> A moldura e declarada com ~2x o *bounding box* dos controles. Os controles ficam no
> tamanho normal. Nunca corrija o corte aumentando o controle.

## Quando disparar

- Tela `MSDIALOG` abre com a ultima coluna do browse, os botoes, o group ou a
  lista cortados.
- Lista/listbox corta a direita porque a largura foi declarada no tamanho
  renderizado (ex.: 400 achando que rende 400 px, quando rende ~800).
- O usuario diz "o botao ficou cortado", "a tela ficou cortada" ou "o botao ficou
  grande demais" depois de uma alteracao de largura.
- Vai criar ou redimensionar uma tela modal (Modelo 1) antes de compilar.
- Precisa revisar os numeros de uma moldura existente.

## Etapa 1 - medir a escala

Escolha um controle de largura declarada conhecida (group, SAY ou browse), meca a
largura dele **em pixels na captura de tela** e divida:

```
escala = px renderizados / unidades declaradas
```

Medicao do incidente que originou esta Skill: group declarado com 355 renderizou
~700 px -> escala 1,97. Use **2,0 como padrao** quando nao houver captura, e declare
no relatorio que a escala nao foi confirmada.

## Etapa 2 - bounding box e moldura

Percorra **todos** os controles da tela e calcule:

```
nBase = max(linha + altura)
nDir  = max(coluna + largura)
moldura_altura = escala * nBase
moldura_largura = escala * nDir
```

Arredonde cada valor **para cima** em multiplo de 50 - mesma granularidade dos fontes
prontos (650, 900, 1400, 800, 400). O arredondamento existe porque a moldura inclui
titulo e bordas, que nao sao escalados.

Os controles tambem renderizam com zoom: declare cada largura/altura como
**px desejados na tela / escala**. Se um controle ja foi declarado no tamanho
renderizado (lista de 400 que rende ~800 px), **reduza o controle** para o alvo
dividido pela escala e recalcule o bounding box - nunca aumente a moldura para
caber um controle gigante.

## Etapa 3 - browse e botoes: a aritmetica que precisa fechar

Antes de editar, confira as tres desigualdades:

1. `soma das colunas do browse <= largura do browse`
2. `coluna + largura do browse <= moldura_largura / 2`
3. `linha + altura do browse (ou do ultimo botao) <= moldura_altura / 2`

Falhar a 1 corta a ultima coluna; falhar a 2 ou 3 coloca o controle fora da janela.
Rode `scripts/calc_frame.py` para nao fazer essa conta de cabeca.

## Etapa 4 - precedentes verificados no repositorio

| Fonte | Moldura | Conteudo | Razao |
| --- | --- | --- | --- |
| `FONTES/ZANALBX.PRW:565` | largura 1400 | group ate 695 (`FONTES/ZANALBX.PRW:572`) | 2,01x |
| `FONTES/IMPSLDINI.PRW:1040` | largura 900 | listbox 440 (`FONTES/IMPSLDINI.PRW:1044`) | 2,05x |
| `FONTES/CADSZ3.PRW:1500` | 800 x 400 | browse em (34,12) 376x150, colunas 40+196+140 = 376 (`FONTES/CADSZ3.PRW:1505`) | 2,0x |
| `FONTES/ZSOLNF.PRW:472` | 600 x 450 | listbox em (50,10) 200x240 (`FONTES/ZSOLNF.PRW:483`), bordas 210 x 290 -> 420 x 580 arredondados | 2,0x |

O `CADSZ3` e o modelo canonico (aprovado pelo usuario em 30/10/2026): moldura 800x400,
grade 376x150, tres colunas somando exatamente 376, borda direita em 388 e borda
inferior em 184 - dentro da metade (400 e 200).

## Anti-padroes (erros medidos que originaram e reforcaram esta Skill)

1. **Botao cortado -> aumentar o botao.** O botao "Verificar Duplicidade" foi de
   080x12 para 130x12 e a moldura para 800. Resultado: botao gigante e tela ainda
   cortada. O botao nunca esteve estreito: a moldura era 735 e o fim do botao era 390,
   ou seja, precisava de 780 (2 x 390). Corrigido voltando o botao para 080 e
   mantendo a moldura em 800.
2. **"Aumentar um pouco a largura".** Ir de 700 para 800 sem recalcular o conteudo
   manteve a segunda tela cortada, porque o browse declarava 656 e so cabiam 350
   (800/2). Sem o fator 2 explicito, qualquer ajuste no olho repete o erro.
3. **Conferir so a largura e esquecer a altura.** O browse em linha 34 com altura 150
   termina em 184; a moldura minima e 368, arredondada para 400. Quando os botoes
   abaixo da grade foram removidos, a moldura caiu de 450 para 400 - e nao para 200.
4. **Declarar o controle no tamanho renderizado.** Incidente de 10/11/2026 na tela
   "Pesquisar por Usuario" do ZSOLNF: listbox declarada com 400 de largura (rende
   ~800 px) dentro de moldura 430 - a lista cortava a direita e embaixo. Corrigido
   reduzindo a listbox para 200 (rende ~400 px, o alvo visual) e declarando a
   moldura 600 x 450 = 2x o bounding box 290 x 210, arredondado. Auditoria com
   `calc_frame.py --frame 600,450`: VEREDITO OK.

## Fechamento

1. Calcule as medidas com `scripts/calc_frame.py` e use a saida no fonte.
2. Aplique a edicao preservando o encoding CP-1252 e rode a verificacao estatica com
   `python skills\vortice\advpl-padrao-fonte\scripts\auditar_padrao.py <arquivo>`
   (skill `advpl-padrao-fonte`) e com `verification-evidence`; se o host tiver a skill
   `advpl-static-verification`, rode tambem o playbook dela. Compilacao pode nao estar
   disponivel nesta maquina.
3. No relatorio final, informe a escala medida e o que ficou nao confirmado. Nunca
   declare que a tela "ficou bem dimensionada" sem uma captura do usuario.

## Checklist

- [ ] escala medida na captura (ou 2,0 declarado como suposicao)
- [ ] moldura = 2x bounding box, arredondada para cima em multiplo de 50
- [ ] soma das colunas do browse <= largura do browse
- [ ] todo controle: `coluna + largura <= moldura_largura / 2`
- [ ] todo controle: `linha + altura <= moldura_altura / 2`
- [ ] controles mantidos no tamanho original (nenhum botao "engordado")
- [ ] largura de lista/browse declarada como px desejados na tela / escala
- [ ] numeros batem com um dos precedentes da Etapa 4
- [ ] relatorio aponta a escala como nao confirmada quando nao houve captura

## Script

```powershell
python skills\vortice\advpl-msdialog-dimensionamento\scripts\calc_frame.py `
  --control 8,12,380,20 `
  --browse 34,12,376,150 `
  --columns 40,196,140
```

Saida: bounding box, moldura recomendada e as tres checagens. Com os numeros do
`CADSZ3` a resposta e `400 x 800`. Use `--frame 400,800` para auditar uma moldura que
ja existe; o script sai com codigo 1 quando alguma desigualdade falha.
