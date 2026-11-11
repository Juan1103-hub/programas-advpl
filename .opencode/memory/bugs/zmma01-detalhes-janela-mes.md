---
name: zmma01-detalhes-janela-mes
description: Botao Detalhes (ExportarDetalhes) nao detectava aumento de valor quando o saldo subia dentro do mes e ficava estavel apos o fechamento
type: feedback
metadata:
  type: feedback
---

# Bug: Detalhes ignorava aumento de valor dentro do mes (ZMMA01 - ExportarDetalhes)

**Data**: 2026-10-01 · **Fonte**: `FONTES/ZMMA01.PRW` (funcao `ExportarDetalhes`, antigas linhas 1583-1591) · **Ambiente**: `CINVJ6_DEV`, build 7.00.240223P

## Problema

Modal "Nenhum item teve aumento de valor em estoque entre o fim do mes anterior (30/09/2026) e hoje." mesmo com item que subiu de 1 para 2 unidades DENTRO do mes e ficou estavel apos o fechamento (ex.: 1 no comeco do mes, 2 no final).

## Causa

Janela de comparacao era **fim do mes anterior -> hoje** (janela de 1 dia em 01/10/2026):
- `nValFim := nSaldoFim * nPrecoMesU` (fechamento do mes)
- `nValHoje := nSB2Qtd * nPrecoAtu` (hoje, SB2)
- Item 1->2 no mes: fechamento = 2, hoje = 2 => `nValDif = 0` => descartado no filtro `Round(nValDif,2) <= 0`.
- O aumento real aconteceu ENTRE a abertura e o fechamento do mes — invisivel para a janela de 1 dia.

## Fix

Janela nova: **inicio -> fim do mes anterior** (variacao do mes completo), ambos os lados ao preco de compra do mes (`nPrecoMesU` = ultimo D1_VUNIT de entrada no mes; sem NF no mes, usa preco atual B1_UPRC):
- `nValIni := nSaldoIni * nPrecoMesU` / `nValFim := nSaldoFim * nPrecoMesU` / `nValDif := nValFim - nValIni` / `nUnidDif := nSaldoFim - nSaldoIni`
- `nSaldoIni` = fechamento real SB9 (B9_QINI da linha de fim de mes; base CINVJ6_192877_PR_DV validada 2026-10-01: SB9 SEM B9_QFIM, B9_QINI da linha de fim de mes = fechamento) com tolerancia 01/MM-3..01/MM+1 e reconciliacao contra SB2 (tolerancia 0.05); fallback = estimativa por rollback do SB2 (`nSaldoFim := nSB2Qtd - nEntPos + nSaiPos`).
- Clamp `nSaldoIni < 0 -> 0` (simetrico ao do nSaldoFim): abertura negativa na estimativa inventaria aumento ficticio.
- Motivo unico: "Estoque maior no mes: N unidades a mais (entradas: X unidades; saidas: Y unidades)" (+ aviso "(saldo do mes estimado, sem fechamento valido no sistema)" quando !lSaldoReal).
- Version bump 6.1 -> 6.2; textos do modal/relatorio atualizados para a nova janela ("no mes anterior (dd/mm a dd/mm)").

## Como aplicar

- Janela "mes completo" com preco constante nos dois lados isola o efeito QUANTIDADE: o preco de compra de hoje nao polui o aumento e movimentos apos o fechamento nao entram na variacao.
- SB9: estrutura varia por base — detectar B9_QFIM/B9_QINI/B9_MES+B9_ANO uma unica vez (mesmo padrao do ZSLDEST); na base DV o fechamento mensal grava o saldo em B9_QINI da linha de fim de mes.
- Workflow apos editar .prw: converter UTF-8 -> CP-1252 (este arquivo ficou ASCII puro, conversao no-op) -> compilar no CINVJ6_DEV via TDS (VS Code) -> review. **Compilacao pendente nesta sessao** (advpls.exe ausente no ambiente do agente; usuario deve compilar no VS Code com totvs.tds-vscode).
- Hook `.opencode/settings.json` corrigido nesta sessao: ordem era compilar -> converter (invertida, corrompe acentos no RPO); agora converter -> compilar.

## Evidencia (planilha "teste 01.xlsx", analisada 2026-10-01)

Planilha do usuario (Planilha1, 3 blocos: A-I atual / K-R snapshot inicio do mes / T-X diferencas), 58 itens: 26 IGUAL / 32 DIFERENTE.

**Achado decisivo**: os **32 DIFERENTE sao 100% causados por alteracao de PRECO UNITARIO, com quantidade identica** entre o inicio e o fim do mes (0 itens com variacao de quantidade). Exemplos:
- MC.1003.00006 (papel higienico): 8 un -> 8 un, preco 100,00 -> 100,20 (dif. R$1,60)
- MC.1001.00027 (papel sulfite): 23 un -> 23 un, preco 28,80 -> 31,00 (dif. R$50,60)
- MC.0902.00005 (eletrodo): 2 un -> 2 un, preco 742,32 -> 826,74 (dif. R$168,84)
- MC.1001.00174: 29 un -> 29 un, preco 6,80 -> 3,12 (dif. -R$106,75 — baixa de preço também marcava)
- MC.1009.00045 (rolamento): 3 un -> 3 un, preco 354,12 -> 354,16 (dif. de apenas R$0,12!)

**Causa raiz confirmada**: a comparacao antiga valorava a abertura pelo preco antigo e o fechamento pelo preco atual — qualquer reajuste de preço de compra (ate R$0,04) poluia a diferenca. 6 itens marcados IGUAL tinham saldo 0 nos dois lados (0 x preco = 0). 2 itens com desalinhamento de centavos (preco da base tem mais casas decimais que a exibicao).

**Conclusao**: com o fix v6.2 (ambos os lados ao mesmo preco `nPrecoMesU`), os 32 dariam `nValDif = 0` e seriam filtrados — so entrariam itens com aumento REAL de quantidade no mes. Janela ja e' 31/08 -> 30/09 na pratica (abertura = fechamento SB9 de 31/08 via `B9_QINI` da linha de fim de mes, movimento 01/09-30/09, fechamento 30/09).

**Evidencia SD1 (2026-10-02, Consulta Analisador, base CINVJ6_192877_PR_DV)**: HOUVE compra — 5 NF de entrada ago/set: MC.1001.00027 (24/08 @ 31,00, 25 un; 21/09 @ 28,80, 10 un) e MC.1003.00006 (10/08 @ 100,20, 6 un; 08/09 @ 102,40, 4 un; 28/09 @ 100,00, 10 un). **Corrige conclusao anterior de 'sem movimento SD1 desde 01/09'**. Dentro da janela de movimento (01/09-30/09): sulfite 1 NF (21/09), higienico 2 NFs (08/09 e 28/09) — compras no mes, mas saldo inicio = saldo fim (8 e 23 un): o que entrou foi consumido. **Fechamento matematico da diferenca antiga**: diferenca = (B1_UPRC − ultimo D1_VUNIT do mes) × saldo — higienico 8×(100,20−100,00)=R$1,60; sulfite 23×(31,00−28,80)=R$50,60; rolamento 3×(354,16−354,12)=R$0,12. O relatorio ANTIGO comparava o fechamento do mes ao preco da ultima NF do mes contra o valor de hoje ao B1_UPRC (referencia do cadastro, nivel de agosto) — compra em preco diferente poluia a diferenca mesmo com saldo estavel. Custo medio (100,7152) e' media ponderada das NFs, nao bate com NF isolada. Com o fix, nPrecoMesU = ultimo D1_VUNIT do mes (100,00 / 28,80) nos dois lados -> nValDif = 0 -> filtrados.

**Quirks do Consulta Analisador Webapp 2.9.0005**: `WITH (NOLOCK)` e' reescrito pela ferramenta (vira `WITH` solto, erro 156); `%nolock%` NAO e' expandido fora de AdvPL (vira `%%`, erro 102) — omitir o hint em consultas avulsas. Colunas fisicas inexistentes nesta base: `B1_CM1`, `B1_ULTCOM` (erro 207) — usar so B1_COD/B1_DESC/B1_UPRC. `D_E_L_E_T_ = ' '` (espaco, nao string vazia).

Scripts de evidencia reprodutivel: `code/read_xlsx.py`, `code/analyze_xlsx.py`.

## Evolucao v6.3 (2026-10-02): colunas Custo Medio no relatorio Detalhes

Usuario pediu duas colunas novas: **Custo Medio (Mes Anterior)** e **Custo Medio (Atual)**.

- **CM Mes Anterior**: `SUM(B9_VLR)/SUM(B9_QTD)` do fechamento mensal aceito (SB9). Extensao da deteccao `INFORMATION_SCHEMA.COLUMNS` para colunas de valor, prioridade `B9_VFIM > B9_VINI1 > B9_VATU > B9_VATU1` (mesmo padrao do `ZSLDEST.PRW` linhas 328-351). `aSB9Exp` agora `{COD, QTD, DTB9, VLR}`. Gate `lCMReal` = janela de data aceita (capturada ANTES da reconciliacao que pode invalidar `lSaldoReal` — o CM do fechamento e' do proprio fechamento mesmo quando o saldo nao reconcilia). Sem coluna de valor na base ou fechamento zerado: mostra zero.
- **CM Atual**: `B2_CM1` (N14,6) do SB2; fallback `SUM(B2_VATU1)/SUM(B2_QATU)` (query SB2 ampliada para `B2_COD, B2_LOCAL, B2_QATU, B2_CM1, B2_VATU1`; `aSB2Exp` agora `{cProd, qtdSum, cm1, vatu1Sum}` — padrao `ZMM01.PRW` linhas 1080-1083).
- `aRegs` posicoes 11/12; celulas TReport `CMMESANT`/`CMATU` (`@E 999,999.99`, size 12) apos `VUNITATU`; duas linhas de explicacao no cabecalho via `oReport:PrintText`.
- **Bug evitado**: `nCMMesAnt`/`nCMAtu`/`lCMReal` zerados no init do `For nX` — sem isso, CM de item anterior vazava para item sem fechamento valido.
- Arquivo continua ASCII puro (CRLF), conversao UTF-8->CP-1252 e' no-op. **Compilacao pendente** (advpls.exe ausente no ambiente do agente; compilar no VS Code com totvs.tds-vscode contra `CINVJ6_DEV`).
- Quirk SQL Server reafirmado: `GROUP BY SB9.B9_COD, MX.MAXDT` e' exigido pela query com JOIN de maximo; no caminho MES/ANO sem B9_DATA o MX nao existe (latente pre-v6.3, nao atingido na base CINVJ6 que tem B9_DATA).

## Evolucao v6.4 (2026-10-02): valor do estoque avaliado por CUSTO MEDIO (nao preco unitario)

Usuario pediu trocar a base de valoracao das colunas de valor: em vez de multiplicar saldo pelo **preco unitario de compra do mes** (`nPrecoMesU`), usar o **Custo Medio**.

- `Valor no Inicio do Mes (R$)` = `nSaldoIni * nCMAbertura` (CM do mes anterior)
- `Valor no Fim do Mes (R$)`    = `nSaldoFim * nCMAtu` (CM atual)
- `Aumento de Valor no Mes (R$)` = `nValFim - nValIni` -> passa a ser a **diferenca dos dois valores por CM**, ou seja, **efeito quantidade + efeito custo medio** (antes era puro efeito quantidade, com preco igual nos dois lados).
- Nova Local `nCMAbertura`: fallback para `nCMAtu` quando o item nao tem CM do mes anterior (sem fechamento valido no SB9). Sem esse fallback a abertura valeria 0 e TODO item com estoque apareceria como aumento.
- `nPrecoMesU` foi **mantido** (posicao 9 do `aRegs` / coluna `VUNITMES` "Valor Unitario (Mes Anterior)") — agora serve so como preco de compra do mes, fora do calculo de valor.
- Filtro `Round(nValDif, 2) <= 0 -> Loop` inalterado **na v6.4**: passava a filtrar por aumento real de VALOR (quantidade + custo). Ver v6.5 — revertido para quantidade na v6.5 porque inflou o relatorio de 59 para 75 itens.
- Coluna `MOTIVO` reescrita: "Quantidade: N unidades no mes (entradas: X; saidas: Y). Custo medio: A -> B (variacao de R$ D por unidade)" — o texto antigo ("Estoque maior no mes: N unidades a mais") ficaria enganoso quando o aumento vem de custo e nao de quantidade.
- Cabecalho do relatorio (`DetRepMonta`): 2 linhas de `PrintText` trocadas para descrever a avaliacao por CM + 1 nova linha explicando a composicao do Aumento.
- Estrutura verificada: If/EndIf 35/35, Do Case/EndCase 1/1, For/Next 2/2, While/EndDo 4/4; ASCII puro (CRLF), conversao no-op. **Compilacao pendente** (compilar no VS Code com totvs.tds-vscode contra `CINVJ6_DEV`).

## Evolucao v6.5 (2026-10-02): filtro de SELECAO volta a ser QUANTIDADE, nao valor

Sintoma reportado pelo usuario: o relatorio Detalhes subiu de **59 para 75 itens** e "nao era isso". A regra pedida e: **mostrar somente os itens cujo ESTOQUE aumentou em relacao ao inicio do mes**.

- **Causa do salto de 59 -> 75**: a v6.4 trocou a base de valoracao de preco para Custo Medio mas deixou o filtro em `nValDif` (valor em R$). Com CM diferente dos dois lados, passavam itens com saldo **igual ou menor** cujo Custo Medio subiu — 16 itens a mais, todos legitimos quanto a valor, mas fora da regra de negocio pedida. Nao era variavel vazando entre itens: `nSaldoIni/nSaldoFim/nCMMesAnt/nCMAtu/nCMAbertura/nValDif` sao todos atribuidos a cada volta do `For nX` (init nas linhas logo apos `cProdExp`).
- **Fix**: filtro virou `If Round(nUnidDif, 2) <= 0 -> Loop`, onde `nUnidDif := nSaldoFim - nSaldoIni` ja existia. `nValDif` continua calculado e agora e **exibido, nao filtrado** — e pode ficar NEGATIVO quando o Custo Medio cai mesmo com o estoque maior.
- **Consequencia de rotulo**: com valor filtrado, a coluna sempre era positiva e o rotulo "Aumento" era correto. Com filtro por quantidade o valor pode ser negativo, entao os rotulos trocaram para nao enganar: coluna `VALAUM` "Aumento de Valor no Mes (R$)" -> **"Variacao do Valor no Mes (R$)"**; `MOTIVO` "Motivo do Aumento" -> **"Motivo da Variacao"**; titulo do TReport -> **"Itens com Estoque que Aumentou no Mes Anterior"**; rodape "AUMENTO TOTAL" -> **"VARIACAO TOTAL"**.
- **Cabecalho do relatorio ganhou 2 linhas** antes das explicacoes de coluna: (1) frase da regra de selecao com as datas; (2) aviso de que o valor em R$ pode cair quando o CM cai, mesmo com estoque maior. Sem isso o usuario le um total negativo como erro.
- **Mensagem quando zero itens**: "Nenhum item teve o estoque aumentado" (era "aumento de valor").
- Docblocks de `ExportarDetalhes` e `DetRepMonta` reescritos para dizer que a SELECAO e por QUANTIDADE e que o valor e exibido, nao filtrado.
- **Achado durante a edicao**: os caracteres `—` (travessao U+2014) entraram em dois comentarios/comentario do docblock e viraram o arquivo UTF-8 (`file` passou a reportar UTF-8). Trocados por texto ASCII; arquivo volta a `ASCII text, CRLF`. Regra do AGENTS.md: `.prw` e sempre CP-1252/ASCII — qualquer caractere > 0x7F quebra a compilacao/gera mojibake no RPO. Verificar sempre com `LC_ALL=C grep -cP '[^\x00-\x7F]'`.
- **Achado**: no momento da edicao o arquivo ja continha a correcao `D1_TIPO = 'D'` na query SD1 (docblock linha ~1304, comentario ~1379, query ~1388) — ela NAO estava presente na verificacao anterior da mesma sessao. Ou seja, a alteracao foi reaplicada entre as duas leituras. Confirmar o estado real do arquivo antes de afirmar que uma correcao esta ou nao presente.
- Estrutura verificada: If/EndIf 104/104, Do Case/EndCase 2/2, For/Next 11/11, While/EndDo 12/12 (arquivo inteiro); 12 celulas TReport x 12 `SetValue` x 12 posicoes do `aRegs`; ASCII puro com CRLF em 100% das linhas. **Compilacao pendente** (compilar no VS Code com totvs.tds-vscode contra `CINVJ6_DEV`).

## Evolucao v6.6 (2026-10-02): RODAPE reconcilia com a diferenca real do fechamento

**Sintoma**: o usuario comparou o total do relatorio Detalhes com o fechamento real do estoque (planilhas "Fechamento de estoque agosto/setembro 2026", aba REPOSICAO DE ESTOQUE) e nao entendia a diferenca: 209.832,08 -> 214.272,91 = **+4.440,83**.

**Causa**: o total do relatorio somava **apenas os itens que aumentaram** (o `Loop` descartava os demais antes de qualquer acumulo). Verificado com as planilhas (coluna O = Saldo x Custo Medio, 392 itens):

| Grupo | Itens | Variacao |
|---|---:|---:|
| Estoque aumentou | 54 | +15.620,43 |
| Estoque diminuiu | 85 | -10.921,68 |
| Quantidade igual (variou so o CM) | 254 | -257,93 |
| **Total real** | **392** | **+4.440,83** |

Ou seja, faltavam -10.921,68 de quedas e -257,93 de CM em itens parados. Decomposicao canonica da diferenca: efeito QUANTIDADE **+4.459,59**, efeito CUSTO MEDIO **-18,76** (o estoque fisico caiu de 6.597 para 6.444 unidades, mas as entradas eram mais caras).

**Fix**: acumular TODOS os itens **antes** do filtro de listagem, separando por direcao da `nUnidDif`:
- 9 novas Locals: `nSomaAum/nQtdAum`, `nSomaQueda/nQtdQueda`, `nSomaParado/nQtdParado`, `nValIniAll/nValFimAll`, `aTotais`.
- `nValIniAll/nValFimAll` acumulam `nValIni`/`nValFim` de todo item (abertura e fechamento reais).
- `aTotais := {R$ aum, qtd aum, R$ queda, qtd queda, R$ parado, qtd parado, valor abertura, valor fechamento}` — construido **antes** do `TReport():New` (o codeblock captura por referencia, mas a atribuicao precisa existir).
- `DetRepMonta` ganhou o 5o parametro `aTotais`; `MsgInfo` de "nenhum item" **removido** (mesmo sem itens listados o relatorio abre e a reconciliacao e impressa).
- Rodape novo: 3 linhas de composicao + abertura + fechamento + DIFERENCA DO PERIODO + **linha de conferencia** (`soma das tres == diferenca`) + soma dos itens listados.
- Cabecalho ganhou aviso: a listagem traz so quem aumentou; a reconciliacao completa esta no rodape.

**Regra de negocio**: a LISTAGEM continua filtrando por quantidade (`nUnidDif > 0`) — pedido anterior do usuario —, mas o RODAPE agora bate com o fechamento. Coluna `nTotAum` mantida (soma so dos listados).

**Limitacao a registrar**: os numeros do relatorio vem de SB9/SB2/SD3/SD1 no Protheus; os da planilha vem do export. Podem divergir — nao foram comparados campo a campo ainda.

## Evolucao v6.7 (2026-10-05): "Valor Estoque" do cabecalho passa a usar Custo Medio

**Sintoma**: o cabecalho em vermelho mostrava `Valor Estoque: R$ 219.339,33 | 392 itens`, que nao bate com a planilha de fechamento (coluna O = Saldo x Custo Medio = 214.272,91 em setembro).

**Causa**: `CalcValorEstoque()` somava `aItens[nX][18] * aItens[nX][26]` — [18] e `B1_UPRC` (preco de compra do cadastro **SB1**), nao custo medio. Terceira base de valoracao, diferente do CM do **SB2**.

**Fix**: nova posicao **32** em `aItensFull` = valor do estoque pelo custo medio, calculada no proprio loop SB2 que ja acumulava o saldo (3 blocos de `ProcessaAnalise`, ~linhas 531 / 588 / 631):
- `If SB2->B2_CM1 > 0 -> nValEstCM += B2_CM1 * B2_QATU`, `Else -> nValEstCM += B2_VATU1` (mesmo padrao canonico de `ZMM01.PRW` 1080-1083 e `ZSLDEST.PRW`), sem `IIF` (CA4000).
- `nValEstCM := 0` iniciado antes de cada `DbSeek` nos 3 blocos; os 3 `aAdd(aItensFull, ...)` ganharam `nValEstCM` como 32a posicao (nao mexeu nas posicoes 1..31 existentes).
- `CalcValorEstoque()` agora faz `nValorEstoque += aItens[nX][32]`; texto do `oSayEst` e do `SAY` inicial viraram **"Valor Estoque (Custo Medio): R$ ..."**.
- **Coluna 12 do browse** tambem trocou (coerencia: senao o total do cabecalho nao fecha com a soma da coluna): `Valor Total (Saldo)` (`[18]*[26]`) -> **`Valor Estoque (Custo Medio)`** (`[32]`).

**Nao alterado**: coluna `Valor Unitario` ([18] = B1_UPRC) e os calculos do `DetalheItem` ([18] x [16]/[24]) continuam em preco de compra — sao sugestao de compra, nao valoracao de estoque.

**Verificacao estrutural**: If/EndIf 108/108 (+3 If de custo medio), For/Next 11/11, While/EndDo 12/12, Case 2/2; 3 `aAdd(aItensFull` com 32 posicoes; non-ASCII 0; CRLF 100%. **Compilacao pendente** (VS Code + totvs.tds-vscode contra `CINVJ6_DEV`), apos `utf8-to-cp1252-conversion` (no-op: arquivo ja e ASCII).

## Evolucao v6.8 (2026-10-05): reconciliacao NAO saia na exportacao em planilha (TReport descarta PrintText)

**Sintoma**: o usuario exportou o relatorio Detalhes para Excel (`C:\Users\Vortice 0097\Desktop\zmma01d.xlsx`, aba `Itens`) e o rodape **RECONCILIACAO DO VALOR EM ESTOQUE** nao apareceu. Verificado com `openpyxl`: a planilha tem 1 cabecalho de coluna + linhas de dados e **nada mais** - tambem faltam as 9 linhas de explicacao do cabecalho e o titulo do relatorio, ou seja, **nenhuma** linha de `TReport:PrintText()` chega ao Excel.

**Causa**: a saida "planilha" do TReport grava apenas as **celulas das secoes** (o titulo da aba veio do nome da secao `"Itens"`) e descarta texto livre. Confirmado na Central TOTVS (artigo "Classe TReport gera planilhas com abas?"): *"O TReport tem uma opcao de impressacao em planilha... Nao ha como customizar ou alterar a forma que a impressao desses tres formatos e feita. Caso haja a necessidade de fazer algo diferente, use FWMsExcel/FWMsExcelEx."*

**Fix (duplicata zero, funciona nos dois formatos)**:
- Nova **secao 2** `TRSection():New(oReport, "Reconciliacao", {})` com uma unica celula `LINHA` (`TRCell():New(oSecRec, "LINHA", "", "", Nil, 100)` - picture `Nil` segue o padrao de `MTA185MNU.PRW`), `SetHeaderSection(.F.)`.
- `DetRepMonta` recebe `oSecRec := oReport:Section(2)` e `aLinhas`: as 13 linhas do rodape (titulo + 3 grupos + abertura/fechamento/diferenca + conferencia + itens listados, com linhas vazias no lugar dos `SkipLine`) viram `SetValue` + `PrintLine` **depois** de `oSection:Finish()`.
- Os 12 `PrintText` do rodape foram **removidos** (senao duplicariam no preview); as 9 linhas de explicacao do cabecalho continuam em `PrintText` (preview) - nao chegam ao Excel ainda.
- Resultado: preview imprime a reconciliacao logo abaixo dos itens (mesmo conteudo de antes); na planilha ela vira linhas de celula - na pior das hipoteses numa aba `Reconciliacao`, nunca "sumindo".

**Achado auxiliar**: o `zmma01d.xlsx` analisado tem **59 itens** e soma de variacao **22.774,26**, enquanto o texto colado pelo usuario dizia 54 itens / 15.620,43 - eram EXECUCOES diferentes (o arquivo e de outra data/filtro). Nao confundir: a conferencia usa os totais da propria execucao.

**Verificacao estrutural**: If/EndIf 108/108, For/Next 12/12, While/EndDo 12/12, Case 2/2, TRSection 2, TRCell 13 (12 itens + 1 linha), non-ASCII 0, CRLF 100%. **Compilacao pendente** (VS Code + totvs.tds-vscode contra `CINVJ6_DEV`) e **teste de exportacao pendente** (gerar de novo o xlsx e conferir se a aba/traco de reconciliacao aparece).

## Diagnostico v6.9 (2026-10-05): "Valor Estoque (Custo Medio)" x planilha VOREST02 — diferenca de 1.609,05 = UM item (SEM correcao de codigo ainda)

**Sintoma**: cabecalho do ZMMA01 = `Valor Estoque (Custo Medio): R$ 216.161,41 | 392 itens` (foto de 05/10) vs soma `Saldo x Custo Medio` da planilha `vorest02_20261005173343.xlsx` = **217.770,46**. Diferenca **1.609,05**.

**Achado (openpyxl)**: a diferenca e EXATAMENTE o valor de **MC.0403.00349** (ADESIVO VULCAFLEX 2600): saldo 10 x CM 160,905 = 1.609,05. As demais colunas do arquivo: col P "Valor em estoque" = 220.941,52 (e so B1_UPRC x saldo, nao e CM); 392 linhas, sem duplicatas, 4 itens com CM zero, nenhum saldo negativo. Soma com CM arredondado em 2/4/6 casas = 217.770,46 (precisao NAO e a causa).

**Cross-checks com as planilhas de fechamento**: setembro soma 214.272,91 e agosto 209.832,08 (= exatamente os totais que o relatorio Detalhes imprimiu em v6.6) — ou seja, em setembro o universo do ZMMA01 bateu 100% com o do VOREST02. Conjuntos de codigos: setembro == outubro (392 identicos); agosto x setembro teve 1 troca (MC.0801.00008 sai, MC.0801.00036 entra).

**Duas hipoteses (ambas de DADO, nao de codigo)**:
- **H1 — item fora da base do ZMMA01**: universos sao filtros diferentes: `ZMMA01.PRW` exige `B1_XCTAEST = '11401200001'` nos 3 blocos (`ProcessaAnalise`) e, no 3o bloco ("sem movimentacao"), tambem `B1_MSBLQL != '1'`; ja `VOREST02.PRW:119-127` filtra `B1_ESTSEG > 0 OU (ESTSEG = 0 E ZREPOS = 'S')` e nao trata bloqueio. Para os dois darem 392, o ZMMA01 teria de ter perdido este item e ganhado outro de valor ZERO.
- **H2 — armazem diferente**: `VOREST02.PRW:118` faz `LEFT JOIN SB2 ... AND B2_LOCAL = '02'` (so armazem 02); o `CalcValorEstoque`/`ProcessaAnalise` soma TODOS os armazens (`While` sobre SB2 por `B2_COD`). Se o item tem +10 no 02 e −10 em outro armazem, o ZMMA01 da liquido 0 e a diferenca tambem e exatamente 1.609,05. Em setembro os totais bateram, entao na data anterior nao havia armazem divergente.

**Como decidir (sem inventar estado da base)**: no proprio ZMMA01, `Filtro Produto = MC.0403.00349` + `Aplicar Filtro` → 0 itens = H1; 1 item com saldo 0 = H2 (liquido); 1 item com saldo 10 = leitura SB2 (investigar). SQL de confirmacao (APSDU/RetSqlName):
`SELECT B1_MSBLQL,B1_XCTAEST,B1_ESTSEG,B1_ZREPOS,B1_LOCPAD FROM SB1010 WHERE D_E_L_E_T_=' ' AND B1_COD='MC.0403.00349'` e `SELECT B2_FILIAL,B2_LOCAL,B2_QATU,B2_CM1,B2_VATU1 FROM SB2010 WHERE D_E_L_E_T_=' ' AND B2_COD='MC.0403.00349'`.

**Nenhuma alteracao de codigo foi feita**: as duas hipoteses pedem correcoes OPOSTAS (H1 = incluir/ajustar universo; H2 = decidir se valoriza so o armazem padrao como o VOREST02 ou todos os armazes como o relatorio Detalhes). Correcao a cega mudaria o total dos 392 itens.

[[zmma01-alias-sql-erro]] [[padroes/encoding-cp1252]] [[zanalprc-indicadores-cc]]
