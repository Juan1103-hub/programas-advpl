# Memory — Vortice AdvPL/Protheus Workspace

> Contexto permanente do projeto. **Ler no inicio de cada sessao** antes de qualquer tarefa.
> Ultima atualizacao: 24/09/2026

## Base de Conhecimento — Obsidian (consultar sempre)

Vault local com notas organizadas de ADVPL/Protheus e Web:
`C:\Users\Vortice 0097\Desktop\BKP_JUAN\Memoria\Memoria\`

| Situacao | Nota a consultar |
|----------|-----------------|
| Bug estranho / erro desconhecido | `ADVPL-Protheus\06 - Bugs Resolvidos.md` |
| Duvida sobre padrao de codigo | `ADVPL-Protheus\07 - Padroes de Codigo ADVPL.md` |
| Nome de tabela / filtro canonico | `ADVPL-Protheus\08 - Tabelas-Chave e Filtros.md` |
| Regras e boas praticas | `ADVPL-Protheus\09 - Regras e Boas Praticas.md` |
| MVC / ModelDef / ViewDef | `ADVPL-Protheus\02 - MVC no Protheus.md` |
| SX3 / dicionario de dados | `ADVPL-Protheus\03 - SX3 e Dicionario de Dados.md` |
| ZZ4 / ZD1 / SA2 customizada | `ADVPL-Protheus\04 - Tabelas Customizadas.md` |
| Lista de programas do projeto | `ADVPL-Protheus\01 - Programas Customizados.md` |
| Pontos de Entrada (PE) | `ADVPL-Protheus\05 - Pontos de Entrada (PE).md` |

**Instrucao**: Ao iniciar qualquer tarefa de desenvolvimento ou debug, ler a nota relevante acima ANTES de responder.
Para registrar um bug resolvido: gravar em `ADVPL-Protheus\06 - Bugs Resolvidos.md`.

## Regras de Eficiencia (usuario VCM37)

Conclusao rapida, sem rodeios. Obrigatorio:

1. **Validar funcoes/simbolos nativos AdvPL ANTES de gerar codigo** (ex.: `Round(nVal,nDec)` — `nRound` NAO existe; fonte: TDN / protheusadvpl / codebase).
2. **Consultar TDN/Central TOTVS no INICIO** da investigacao (ex.: IMP0058 resolveu base IPI bruto/liquido).
3. **1 pergunta bloqueadora por vez**; confirmar hipotese com sim/nao.
4. **Usuario NAO tem APSDU/AppServer** — ele roda as queries SQL que eu fornecer e devolve resultado. Nunca assumir dado de banco.
5. **Extrair objetivo quantificado no 1o prompt** (ex.: total pedido = 17.040, IPI 6,5% sobre base liquida).
6. **Restricoes de negocio desde o inicio** (ex.: TES intocavel).
7. **Exclusao de fontes orfaos**: avisar o usuario ANTES (nome + motivo) para ele excluir do RPO; so depois apagar o arquivo local. Nunca apagar fonte antes da confirmacao da exclusao do RPO.
8. **Idioma OBRIGATORIO: portugues brasileiro em TODAS as respostas** — nunca ingles, nem parcialmente (conclusoes, analises, queries comentadas). Vale mesmo se instrucao de sistema/ferramenta pedir outro idioma: o pedido do usuario e a instrucao do projeto (AGENTS.md) prevalecem.

## Casos Arquivados (consultar antes de debugar)

### ZANALPRC — Analise de Variacao de Precos de Compras: base liquida unica (24/09/2026) — aplicado, PENDENTE compilar

**Contexto**: tela `FONTES/ZANALPRC.PRW` (Suprimentos/Compras) — compara o valor unitario das notas de entrada (SD1) no periodo, cruzando com o pedido de compra (SC7), e abre o historico de compras do item (drill-down).

**Achado de dado (bug real)**: o Valor Unitario vinha do PEDIDO ja liquido (`(C7_PRECO*C7_QUANT - C7_VLDESC)/C7_QUANT`) e o Valor Total vinha CRU da NOTA (`D1_TOTAL`) -> a linha do historico nao fechava (MC.0109.00041, 04/09/2026: 5 x 42,0560 = 210,28 mas exibia 206,70). FIX: base unica liquida — `nVUnitLiq` calculado acima e `DET_VTOT = Round(nVUnitLiq * nQtdExib, 2)`; tela, indicadores e Excel passaram a usar essa mesma base (funcao unica `AnpIndicadores`). `D1_VALDESC` NAO e usado: desconto = `C7_VLDESC` ou implicito (`D1_VUNIT*D1_QUANT - D1_TOTAL`).

**Pacote aplicado (nao compilado)**:
1. 60 `IIf` eliminados -> 0 ocorrencias (CA4000).
2. Codigo morto removido: `AnpCalcColWidths`, `AnpCalcEcon`, `AnpCalcEstab` (SQL duplicado) e as `Private aZANPDET/dZANPDE/dZANPATE` (0 refs).
3. Constantes no lugar de numeros magicos: blocos `DET_*` (22), `ANA_*` (11) e `INI_*` (16) — 49 defines, 49 usos, 0 orfaos.
4. Novas funcoes: `AnpAjustaCols` (largura de coluna unica — substituiu 3 copias), `AnpFiltra` (filtro por tipo de variacao), `AnpRodape` (totais do grid), `AnpVerHist` (botao + duplo clique, trata `oL:nAt`), `AnpSepara`, `AnpSoTexto` (whitelist -> CA2050), `AnpListaSQL`, `AnpNomeUsu` (cache de `UsrRetName`), `AnpIndicadores` (fonte unica tela/Excel).
5. `LEFT JOIN` SD1 x SC7 trocado por `OUTER APPLY (SELECT TOP 1 ... ORDER BY C7_ITEM)` -> fim da duplicacao da linha da nota.
6. `%nolock%` em SD1/SB1/SA2/CTT/SC7/SE4; `BEGIN SEQUENCE/RECOVER` + `FWLogMsg` em `AnpCarrega`, `AnpCarCC`, `AnpPrazMedPgto`.
7. Correcoes de logica: `If Val(cTok) >= 0` (sempre verdadeiro) -> `If !Empty(cTok) .And. Val(cTok) > 0`; Quantidade = `C7_QUANT` quando ha pedido, senao `D1_QUANT` (igual nas 3 saidas); filtro de comprador aceita pedido nulo (`SC7.C7_USER IS NULL OR ...`) para nao sumir nota sem pedido; `SetMeter` com total real.
8. Parametros novos via `SuperGetMV` com default que preserva o comportamento atual: `MV_ZANCONAP` (R,B), `MV_ZANTIPNF` (N), `MV_ZANFAMIT` (MC,MD,AI), `MV_ZANCCOMP` (lista de compradores), `MV_ZANCCMOV` (0=todos os CC, 1=so CC com movimento 12 meses).
9. UX/idioma PT-BR: filtro Fornecedor novo; combo de variacao com frases completas ("Somente Aumentou"...); botoes "Ver Historico" e "Imprimir Historico" com tooltip; confirmacao `MsgYesNo` para periodo > 3 anos; cache de filtros na sessao; `SAY oX PROMPT " "` (era PROMPT "").
10. Grid: dialog `FROM 0,0 TO 650,1500 PIXEL`; analise `LISTBOX SIZE 1460,235` com `aMinCols = {90,220,180,80,170,170,170,130,110,140}` (=1460); historico `SIZE 1460,235` com 13 colunas `{60,100,100,75,90,155,250,115,105,80,105,85,140}` (=1460). Titulos exatamente: Codigo | Descricao | Centro de Custos | Qtd.Total | Primeiro Valor Unitario | Valor Unitario Anterior | Valor Unitario Atual | Diferenca R$ | Variacao % | Situacao.
11. TReport: report do historico passou de `"ZANLPRC"+cCod` para `"ZANALPRCH"+cCod`; secoes `Analise`/`Historico`/`Indicadores` com rotulos PT-BR.
12. ProtheusDoc em todas as funcoes (`@version 4.0`).

**Estado do arquivo**: `FONTES/ZANALPRC.PRW`, 1779 linhas, **CP-1252** (bytes >127 apenas `[224,225,227,231,233,237,243,250]`), LF (CRLF 0), 20 `Static Function`, 0 `Private`, 0 `IIf`.

**PENDENTE**: compilar no AppServer `CINVJ6_DEV` + reciclar + validar em tela (a linha do historico deve fechar: quantidade x valor unitario liquido = valor total). Teste TIR criado em `CONFIG/tir/ZANALPRCTESTCASE.py` (+ `ZANALPRCTESTSUITE.py`) — nao executado (depende do RPO compilado).

**BUG: "Nenhum registro encontrado" com periodo grande (24/09) - 2 causas somadas**:
(1) **`ChangeQuery()` quebra com `WITH`**: adicionei `%nolock%` na query (9 pontos) - o `%nolock%` e expandido para `WITH (NOLOCK)`
    e a partir da 12.1.17 o `ChangeQuery()` DETECTA a palavra `WITH` e **gera excecao** (TOTVS Central 360019499231: "A funcao ChangeQuery
    nao pode ser utilizada para queries com a palavra reservada WITH"). O erro caia no `RECOVER USING oErro` -> resultado vazio. A solucao
    oficial e NAO usar ChangeQuery() em query com WITH - se precisar do hint, usar `TcGenQry()` e injetar o `WITH (NOLOCK)` por `StrTran`
    DEPOIS do ChangeQuery (e exatamente o workaround ja cravado em ZMMA01.PRW linhas 475-476: "reinjeta a dica que o ChangeQuery remove").
    FIX: `%nolock%` removido das 9 posicoes (o original nunca teve hint e funcionava). Zero precedente no repo: 100+ fontes, nenhuma com `%nolock%`.
(2) **NULL de LEFT JOIN/OUTER APPLY em comparacao numerica**: o `OUTER APPLY` do SC7 nao casa quando o pedido esta reprovado/cancelado
    (`C7_CONAPRO IN ('R','B')`) ou quando o item da nota nao tem pedido -> `C7_PRECO/C7_VLDESC/C7_QUANT` voltam NULL. Comparar NULL com numero
    aborta a leitura no meio do `While` -> cai no RECOVER -> tudo descartado. So aparecia com periodo grande (mais notas sem pedido).
    O original escapava por acidente: `IIf(!Empty((cAlias)->PEDIDO) .And. (cAlias)->C7PRECO > 0, ...)` - o curto-circuito do `.And.` impedia
    ler SC7 quando nao havia pedido; ao reescrever o `IIf` para `If` eu perdi essa guarda.
    FIX DUPLO: (a) `ISNULL(col,0)` / `ISNULL(col,'')` nas 11 colunas anulaveis da query (PRECOPED/VLDESC/QTDEPED/VTOTNF/DESCR/FORNNOME/
    CCNOME/USUARIO/COND/NUMSC/CONDDESC) - precedente em RLCOMPRAS.PRW e ZANALBX.PRW; (b) guarda `lTemPed` no fonte, restaurando o
    curto-circuito: campos do pedido so sao lidos quando `D1_PEDIDO` esta preenchido.
    DIAGNOSTICO: a mensagem de tela de "nenhum registro" agora mostra o erro real da consulta (Static `cAnpErroSql`) ou quantas notas
    foram lidas + a regra das 2 compras - antes as duas situacoes davam a mesma mensagem e nao davam pista.
    LICAO GERAL: divergencia entre o numero de linhas de duas saidas (periodo pequeno x grande) = erro de runtime no meio do loop, nao filtro.

**ERRO DE COMPILACAO (24/09)**: `BEGIN SEQUENCE WITH {|oErro| Break(oErro)}` NAO e sintaxe AdvPL (e extensao Harbour/Clipper) -> erro apontado nessa linha. Nenhum precedente no repo: 83 fontes usam `Begin Sequence` simples (nfesefaz.prw, TIDEV.PRW). FIX nas 3 ocorrencias (AnpCarCC, AnpCarrega, AnpPrazMedPgto): `Local bErrAnt := Nil` no topo + `bErrAnt := ErrorBlock({|oErro| Break(oErro)})` antes do `Begin Sequence` + `ErrorBlock(bErrAnt)` depois do `End Sequence` (restaurar e obrigatorio: sem isso o bloco com `Break()` fica ativo na sessao e `Break()` fora de sequencia estoura erro).

**Licoes**: (a) nunca misturar coluna liquida com coluna bruta na mesma linha de grid; (b) `D1_VALDESC` pode estar vazio -> desconto confiavel e `C7_VLDESC` ou o implicito da nota; (c) tela e Excel saindo da MESMA funcao de calculo; (d) `LEFT JOIN` por pedido duplica linha de nota -> `OUTER APPLY TOP 1`; (e) `Val("")` = 0 faz `>= 0` ser sempre verdadeiro.

---

### MATA120 IPI bruto/liquido (13/08/2026) — resolvido (grid+gravacao) | pendente impressao

**Objetivo**: total pedido = 17.040 (IPI sobre base liquida, total - desconto). Restricao: TES (F4_TPIPI) intocavel.

**Solucao — 3 camadas**:

1. **Gatilho SX7** (`MT120TFR.PRW` — `U_MT120IPI`): executa em tempo real na digitacao. Calcula base liquida (C7_TOTAL - C7_VLDESC), atualiza aCols E chama `MaFisRef("IT_VALIPI","MT120",...)` / `MaFisRef("IT_BASEIPI","MT120",...)` para atualizar o motor fiscal (rodape "Total do Pedido"). Retorna `"L"` para contra-dominio C7_IPIBRUT. Gatilhos SX7: C7_VLDESC->001, C7_IPI->001, C7_PRODUTO->003.

2. **PE gravacao** (`MTA120G3.PRW`): roda no loop A120GRAVA, sobrescreve o que o framework gravou:
   - `SC7->C7_IPIBRUT := "L"`
   - `SC7->C7_BASEIPI := SC7->C7_TOTAL - SC7->C7_VLDESC`
   - `SC7->C7_VALIPI  := Round(SC7->C7_BASEIPI * SC7->C7_IPI / 100, 2)`

3. **(PENDENTE) Impressao**: o formulario "ORDEM DE COMPRAS" (padrao TOTVS/MISCC) recalcula IPI do zero usando `C7_TOTAL * C7_IPI/100` (bruto), ignorando C7_VALIPI gravado. SC7 esta correto (C7_BASEIPI=16.000, C7_VALIPI=1.040, C7_IPIBRUT=L) mas o print mostra 17.072,50. Aguarda identificar rotina de impressao.

**Licoes**: (a) `nRound` NAO existe em AdvPL, usar `Round(nVal, nDec)`; (b) `MaFisRef("IT_VALIPI","MT120",...)` atualiza motor fiscal — necessario para rodape em tempo real; (c) Gatilho SX7 roda DEPOIS do framework calcular — por isso consegue corrigir; (d) C7_IPIBRUT = "Cons. Desc. Considera Desconto p/IPI" (TDN IMP0058); (e) Impressao TOTVS pode recalcular impostos do zero — verificar se le campos gravados.

**SQL validacao APSDU**: `SELECT C7_BASEIPI, C7_VALIPI, C7_IPIBRUT FROM SC7010 WHERE C7_NUM='<NUM>' AND D_E_L_E_T_=' '`

**Complementos MATA120 ativos**: `MT120TFR.PRW` (gatilhos SX7 U_MT120IPI + frete), `MTA120G3.PRW` (gravacao), `MT120OK.PRW` (pre-save).

## Casos Arquivados (consultar antes de debugar)

### Acompanha Custos 25.10 — baixas não aparecem no Razão CTBR400 (11/09/2026) — resolvido

**Sintoma**: pós-migração 24.10→25.10, CTBR400 (conta estoque 11401200001, Moeda 01, TPSALD 1, filial 0102) mostrava só ENTRADAS; baixas do custo médio da jornada do Acompanha Custos sumiram. Off-line continuava OK.

**Causa-raiz**: a jornada 25.10 contabiliza via ExecAuto e grava como PRÉ-LANÇAMENTO (`CT2_TPSALD='9'`) mesmo com `MV_PRELAN='N'` — CTBR400 com Tipo de Saldo 1 não exibe tipo 9 (por design). Prova: diff de assinatura CT2 junho(1)×julho(9) — LP 666/MATA330/moeda 01/filial 0102 idênticos, só TPSALD mudou.

**Solução**: CTBA350 (Efetivação de Pré-Lançamentos: Efet. p/ Saldo=**1**, período, filial 0102, Efetivar Parcialmente=Sim) → 448 lanc/R$ 54.285,05 efetivados + Reprocessamento de Saldos (MV_CT350SL=F). ✅ baixas no Razão.

**Ritual mensal novo (25.10)**: jornada Acompanha Custos → **CTBA350** → Reprocessamento de Saldos → CTBR400. MATA330 avulso ANTES da jornada é redundante (a jornada recalcula o custo internamente — 1ª etapa é o próprio MATA330); se rodar por hábito, usar a mesma data de fechamento (31/mm) e nenhuma movimentação no meio.

**Pendência**: 1 lanc R$44,14 (lote 008840/doc 000026) sem conta débito — corrigir cadastro origem (produto/TM) e efetivar manualmente.

**Lição**: (a) diff de assinatura CT2 mês bom vs ruim isola a causa em 1 query; (b) `CT2_MOEDA` NÃO existe — é `CT2_MOEDLC`; custo em SD3 é `D3_CUSTO1` (não D3_CUST1); (c) contabilização de custo é agregada por LP/conta — detalhe por movimento é Kardex (MATR900); (d) registrado no Obsidian `06 - Bugs Resolvidos.md`.

### Acompanha Custos 25.10 — ajuste de inventario TM 999 contabilizado como consumo + baixas fora do CTBR400 (21/10/2026) — diagnostico fechado, PENDENTE acao

**Sintoma**: set/2026, filial 0102. Acompanha Custos rodado; no Razao Contabil (CTBR400, conta 11401200001, Tipo de Saldo 1) as baixas NAO aparecem (debitos 41.681,30 / creditos 0,00). Na planilha de contabilizacao (ctb_implanc.xlsx - Data Lcto 30/09/2026, lote 008840, sub 001, doc 000011) ha 417 linhas / R$ 35.510,35 (debito = credito), com 3 linhas sem Centro de Custo: 075 e 076 (doc MC.1001.00174, SEM conta e SEM CC) e 403 (doc MC.0301.00126, conta 32102100005 e SEM CC) = R$ 160,00.

**Causa 1 - Razao vazio**: a Jornada contabiliza via ExecAuto e grava TUDO como pre-lancamento (CT2_TPSALD = '9') por design; o CTBR400 com Tipo de Saldo 1 nao exibe tipo 9. Ritual obrigatorio: Jornada -> CTBA350 (Efetivar para Saldo = 1, filial 0102, Efetivar Parcialmente = Sim) -> [Reprocessamento de Saldos so se MV_CT350SL vazio] -> CTBR400. Checar com a query 9a de _PATCHES/CT2_BAIXAS/09_verificacao_setembro_2026.sql (se 09/2026 so tem tipo 9, a CTBA350 nao foi rodada).

**Causa 2 - Itens sem conta/CC**: buraco na expressao de conta do LP de custo em FONTES/VCTBL002.PRW (linhas 14-27): sem XCT* no produto usa B1_CONTA; centro 60 usa B1_XCTCUST; 70/80/90 usa B1_XCTCIND; 50/10-14/0199 usa B1_XCTDESP; SEM Else final, logo devolve "" quando nao casa. Ajuste de inventario TM 999 nao tem requisicao (D3_NUMSA / D3_CC vazios) -> cai no buraco -> lancamento nasce sem conta de debito. CT2_LP gravado = 666 (LP de consumo) em todas as linhas do doc 000011 (confirmado em ago/2026) -> o acerto de inventario foi contabilizado pelo LP de consumo.

**Licoes**: (a) preencher conta/CC no PRODUTO e caminho errado - decisao do usuario em 21/10/2026; (b) a condicao de geracao no Lancamento Padrao (campo Cond. no SIGACTB, solucao de 14/09/2026: !Empty(SD3->D3_CC) .AND. !Empty(U_VCTBL002()), nas DUAS sequencias 001/002) NUNCA foi aplicada em nenhum fonte/patch do repo (verificado por varredura) - por isso os itens de 999 seguem aparecendo; (c) excluir da contabilizacao deixa custo sem contrapartida no Razao (R$ 160,00 em set/2026); (d) nenhum fonte do repo grava CT2/CT5 (gravacao e 100% motor CTBA105/CTBA102); VCTBL001 nao existe no repo; (e) modulo-estoque.md:797-804 - CT2 gerada conforme o TM e o Lancamento Padrao (CT5) configurado na TES ou no TM; modulo-estoque.md:371-391 - MATA225 Acerto de Inventario grava SD3 com TM = MV_TMPAD.

**Arquivos**: _PATCHES/CT2_BAIXAS/01..09 (SQL ASCII puro). 04 e 07 foram corrigidos: nao existem CT5_LP, CT5_CONTA, CT5_CC, CT5_ITEM, CT5_CLVL, CT5_EXIG, CT5_MOEDA, CT2_CONTA, CT2_CC, CT2_ITEMCTA, CT2_KEY (usar CT5_LANPAD, CT2_DEBITO/CT2_CREDIT, CT2_CCD/CT2_CCC). 09 e o roteiro decisivo (9a CT2 por TPSALD, 9d pendencias com CT2_INCONS, 9e SD3 dos docs MC.1001.00174 e MC.0301.00126, 9g SB1, 9h MVs, 9i CT5 LP 666, 9j/9k discovery INFORMATION_SCHEMA das colunas fisicas de CT5/CT2).

**PENDENTE**: rodar 9a e 9e no APSDU; confirmar execucao da CTBA350 de 09/2026; descobrir o nome fisico do campo de condicao na CT5 (9j); decidir entre (A) condicao no LP 666, (B) MV_TMPAD apontando para TM com LP de inventario 674/676, (C) contabilizar o acerto pelo LP de inventario com conta/CC proprios.

### NF-e Rejeição 610 — vNF/vItem zerados em devolução RTC (12/09/2026) — resolvido

**Sintoma**: NF-e entrada devolução (CFOP 1201, CST 51) rejeitada c/ 610; XML com `<vNF>0` e `<vItem>0` (vProd/IBSCBSTot corretos).

**Causa-raiz**: `NFESEFAZ.prw` (RDMAKE aberto) linha 6812: `If nVlrTt == 0 .AND. !lConfTrib` — c/ config RTC (CFGTRIB/NT 2025.002) o cálculo do total do item é suprimido → `aTotal[02]`=0 → vNF/vItem zerados. PE01NFESEFAZ não resolve (aParam s/ aTotal/aTotalItem — linha 6983).

**Solução**: patch reversível no `FONTES/nfesefaz.prw` + parâmetro **MV_VCM610=.T.** (Lógico, por ambiente): linha 325 `Local lFixV610 := SuperGetMV("MV_VCM610",,.F.)` e linha 6815 `If nVlrTt == 0 .AND. ( !lConfTrib .OR. lFixV610 )`. ✅ SEFAZ aceitou (12/09).

**⚠️ Governança**: pacote fiscal TOTVS SOBRESCREVE o nfesefaz.prw → reaplicar patch após cada pacote; manter chamado TOTVS (família DSERTSS1-39662/27734) e desativar MV_VCM610 quando correção oficial sair. Mesmo sintoma em nota de SAÍDA → bloco SF2 (linhas ~4030–4041). Detalhe completo no Obsidian `06 - Bugs Resolvidos.md`.

**Lição**: NFESEFAZ é aberto, TSS é fechado (sem PE); antes de customizar PE, grep no fonte padrão p/ ver se aParam carrega o dado; verProc antigo ≠ patch não aplicado.

### FWBUILDFEATURE / SSYacc0105e (02/07/2026) — resolvido

**Erro**: `invalid macro source (SSYacc0105e: Error token failed, no valid token):({|a,b,c| FWInitCpo(a,b,c),xRet:=(@!),FWCloseCpo(a,b,c,.T.),xRet })` em `FWBUILDFEATURE(PROTHEUSFUNCTIONMVC.PRX)`.

**Causa-raiz (oficial TOTVS Central #4404702402455)**: O `X3_PICTVAR` (Form. Variável) de campos do SX3 contém `@!`. O framework monta code-block `xRet:=(<X3_PICTVAR>)` e o macro-parser quebra com `(@!)`.

**Solucao aplicada no ZLANCDIE.PRW**: Refatorar `FBrowse()` de `FWMBrowse` para **`mBrowse` + `aRotina` + `User Function` wrappers** (padrao `CADSZ3.PRW`). Elimina dependencia de `FWBUILDFEATURE`/`FWFORMSTRUCT`.

**Skill canonica criada**: `skills/vortice/advpl-fwbrowse-fwbldfeature-bug/SKILL.md` — contem:
- Sintomas/triggers
- 4 queries de diagnostico SQL
- 4 solucoes (limpar X3_PICTVAR, profile, mBrowse, evitar SetDataQuery)
- Links oficiais TOTVS Central (5 artigos) + Forum (thread #19677)
- Prevencao (regras para criacao de tabelas Z*)

**Ao encontrar este erro novamente**: carregar a skill `advpl-fwbrowse-fwbldfeature-bug` ANTES de tentar qualquer alteracao.

## Identidade do Projeto

- **Projeto**: Vortice — Customizacoes AdvPL/TLPP para TOTVS Protheus 12.1.33
- **Modulo principal**: Suprimentos / Compras (SIGAEST, SIGACOM)
- **Workspace**: `C:\Users\Vortice 0097\Desktop\PROGRAMAS_ADVPL`
- **Plataforma**: Windows (win32), PowerShell 5.1
- **Repo git**: NAO (sem `.git`) — usar file reads e Grep para inspecionar mudancas

## Ambiente de Desenvolvimento

- **Compilacao**: TDS VS Code extension (nao e uma skill OpenCode)
  - Config: `.vscode/launch.json`
  - Includes: `C:\totvs\includes`
- **Encoding**: Todos os fontes devem ser **CP1252** (Windows-1252)
  - IA gera UTF-8 → converter via skill `utf8-to-cp1252-conversion` (em `skills/advpl-tlpp/`) antes de compilar
- **Verificacao**: LSP AdvPL (`totvs-protheus`, advpls.exe do TDS 2.1.6) ativo no OpenCode — devolve diagnosticos de sintaxe/semantica apos editar .prw/.tlpp

## Fontes de Codigo

### CADPOSIC — FWMBrowse com Pesquisa Rápida (30/08/2026) — resolvido

**Problema**: Tela FWMBrowse da tabela customizada ZC1 (Posições de Estoque do Item) sem barra de pesquisa e sem botões CRUD.

**3 erros encadeados resolvidos**:
1. `SetSeek(.T.)` sem array `aSeek` → barra de pesquisa não aparece. **Solução**: `SetSeek(.T., aSeek)` com array de definição dos campos.
2. `SetFieldSeek()` **não existe** em FWMBrowse → erro de method. Usar `SetSeek` com 2º parâmetro.
3. `Private aRotina` e `Private cCadastro` não declarados → `AxInclui`/`AxAltera`/`AxDeleta` falham com "variable does not exist CCADASTRO".

**Estrutura correta**:
```advpl
Private aRotina  := {{"Visualizar", "AxVisual", 0, 2},;
                     {"Incluir",    "AxInclui", 0, 3},;
                     {"Alterar",    "AxAltera", 0, 4},;
                     {"Excluir",    "AxDeleta", 0, 5}}
Private cCadastro := "Titulo do Browse"

aSeek := {;
    {"Filial",    {{"ZC1_FILIAL", "C", 2,  0, "Filial",    "@!"}}, 1, .T.},;
    {"Codigo",    {{"ZC1_ITEM",   "C", 13, 0, "Codigo",    "@!"}}, 2, .T.},;
    {"Descricao", {{"ZC1_DESCRI", "C", 50, 0, "Descricao", "@!"}}, 3, .T.};
}
oBrowse:SetSeek(.T., aSeek)
```

**Campos ZC1 confirmados**: ZC1_FILIAL (2), ZC1_ITEM (13), ZC1_DESCRI (50), ZC1_POSIC, ZC1_SALDO, ZC1_LOCAL.

**Regras derivadas**:
- `TamSx3()` e `FWSizeFilial()` NÃO devem ser chamados inline no array literal de `SetSeek` para tabelas Z* (causa "array out of bounds").
- Sempre conferir nomes dos campos no Configurador (SIGACFG) — nomes podem ser diferentes do esperado.

### Arquivos na raiz do workspace (49 .PRW + 2 .TLPP)

**Funcoes customizadas (Z*.PRW) — 20 arquivos:**
ZSLDEST, ZMMA02, ZMMA01, ZMM01, ZLOGCOL, ZLEADTIME, ZFIXSX3SA2, ZFIXMODSA2,
ZCTAEST, ZCRIAZZ4SA2, ZCRIASX3, ZCONSRE5, ZCOMPRAS, ZCALCCOM, ZAVALNEG,
ZANALPRC, ZANALBX, ZALTZZ4SA2, ZADTASK

**Pontos de Entrada (MT*.PRW / MTA*.PRW) — 21 arquivos:**
MT100TOK, MT100OK, MT020ATE, MT010ALT, M020EXC, MT20FOPOS, MT160GRPC,
MT150GET, MT120OK, MT110TOK, MT101OK, MTA105OK, MTA094RO, MTA020,
MTA131C8, MTA110OK, MTALCFIM

**Telas/Cadastros (CAD*.PRW) — 4 arquivos:**
CADSZ3, CADSOLIC, CADFORN, CADPOSIC

**Outros .PRW:**
AVALCOT, CORCITEM, FALTFPED, FFZZ4A2, OPENZZ4, RLCOMPRAS, TIDEV,
VLDNOMEFORN, VOGSB101, VORATF01, VOREST02

**TLPP (.tlpp):**
ZDIAG110.tlpp, TESTDATA.tlpp

### Exemplos canonicos (na raiz do workspace)

| Tipo | Arquivo (raiz) |
|------|----------------|
| Telas/Cadastro | `CADSZ3.PRW` |
| Ponto de Entrada | `MTA110OK.PRW` |
| Relatorio/Analise | `ZANALBX.PRW` |

## Convencoes de Nomenclatura de Arquivos

| Prefixo | Tipo | Exemplos |
|---------|------|----------|
| `Z*.PRW` | Funcoes customizadas | ZCOMPRAS, ZAVALNEG, ZANALPRC |
| `MT*.PRW` | Pontos de Entrada | MT110TOK, MT20FOPOS |
| `MTA*.PRW` | PEs de Aprovacao | MTA110OK, MTA094RO |
| `CAD*.PRW` | Telas de Cadastro | CADSZ3, CADFORN, CADSOLIC |
| `*.tlpp` | Classes TLPP | ZDIAG110, TESTDATA |

## Tabelas-Chave (Suprimentos)

| Alias | Descricao | Filtros Canonicos |
|-------|-----------|-------------------|
| SC7 | Pedidos Compra | `C7_RESIDUO<>'S'`, `C7_QUANT>0`, `C7_CONAPRO NOT IN ('R','B')` |
| SC1 | Solicitacoes Compra | Key: `xFilial("SC1") + C1_NUM` |
| SC8 | Cotacoes | Key: `xFilial("SC8") + C8_NUM` |
| SA2 | Fornecedores | `A2_CGC` = 14 digitos sem formatacao |
| SD1 | NF Entrada | |
| SD3 | Mov. Estoque | TM <= 499 entrada, > 499 saida |
| SB1 | Produtos | `B1_MSBLQL <> '1'` |
| SB2 | Saldos | `B2_COD = B1_COD AND B2_LOCAL = B1_LOCPAD` |
| SB9 | Saldos Historicos | `B9_DATA` = YYYYMMDD, `B9_QINI`/`B9_VINI1` |
| SCP | Solic. Armazem | `CP_NUM` = D3_NUMSA, `CP_QUJE >= CP_QUANT` |
| CTT | Centros de Custo | `CTT_CUSTO = D3_CC` |
| SCR | Aprovacoes | `CR_TIPO`: 'IP' ou 'PC', `CR_STATUS='03'`=aprovado |
| SZ3 | Solic. Cadastrais Produtos | `Z3_ID` key, Z3_STATUS: 0/1/2 |
| ZZ3 | Solic. Cadastrais (alt) | `Z3_ID` key |
| ZZ4 | Solic. Fornecedor | `ZZ4_ID` key |

## Padroes de Codigo Identificados

### Includes
```advpl
#Include "Protheus.ch"
#Include "TopConn.ch"
```

### Estrutura de Funcao
- Cabecalho `/*/{Protheus.doc}.../*/` em todas (User e Static)
- `Local aArea := GetArea()` ... `RestArea(aArea)`
- `xFilial("ALIAS")` para filtro de filial
- `RecLock` apenas para tabelas custom Z* (core → MSExecAuto)
- `GetNextAlias()` + close para alias temporarios
- `ConOut("[PE_NAME] msg")` para log em PEs

### UI
- mBrowse + aRotina + aCores para cadastros
- MSDIALOG 650x1300 PIXEL para analises
- LISTBOX com SetArray + bLine + aColSizes
- TReport para exportacao Excel/PDF
- ParamBox para filtros

### SQL
- `RetSqlName("ALIAS")` + `D_E_L_E_T_ = ' '`
- `ChangeQuery()` em queries string
- `DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)`
- Datas: `DtoS(dData)` para filtro SQL, `StoD(cData)` para conversao inversa
- Limpeza de data: `CtoD("  /  /  ")` — nunca NULL

## Skills OpenCode Instaladas

Local: `skills/vortice/` (27 skills AdvPL), `skills/advpl-tlpp/` (21 skills engpro), `skills/superpowers/`, `skills/unlazy/` — todas registradas no `skills.paths` do `.opencode/opencode.json`

Skills ativas:
- `advpl-code-generation` — geracao de codigo (functions, classes, MVC, REST, PEs)
- `advpl-code-review` — revisao (boas praticas, performance, seguranca, modernizacao)
- `advpl-debugging` — diagnostico de erros e logs
- `advpl-fwbrowse-fwbldfeature-bug` — bug SSYacc0105e em FWBUILDFEATURE/X3_PICTVAR
- `advpl-refactoring` — refatoracao
- `advpl-to-tlpp-migration` — migracao ADVPL → TLPP
- `changelog-patterns` — changelogs
- `code-explanation` — explicacao de codigo
- `documentation-patterns` — documentacao tecnica
- `embedded-sql` — SQL embutido (BeginSQL/EndSQL)
- `probat-testing` — testes unitarios ProBat
- `protheus-business` — processos de negocio Protheus
- `protheus-reference` — funcoes nativas, SX, APIs REST, parametros MV
- `sx-configuration` — dicionario SX (SX3/SIX/SX1/SX5)
- `karpathy-guidelines` — diretrizes comportamentais

Skill canonica do workspace (criada nesta sessao):
- `skills/vortice/advpl-protheus/SKILL.md` — padroes completos + checklist de qualidade

## Estrutura de Configuracao (estado atual - 21/10/2026)

> O antigo workspace PAI `C:\totvs\advpl\.vscode` NAO EXISTE MAIS (pasta removida).
> Nao ha mais hierarquia PAI/FILHO - tudo vive neste projeto.

### Config do projeto (`PROGRAMAS_ADVPL/.opencode/`)
- `opencode.json` - instructions (system-prompt-advpl-opus55.md, AGENTS.md, CONFIG/AGENTS.md, memory/MEMORY.md) + skills.paths + LSP totvs-protheus
- `agents/` - subagentes: changelog-generator, code-reviewer, docs-reference, process-consultant (+ protheus-diag)
- `command/` - 8 comandos: compile, design, execute, map, quick-fix, review, specify, tasks
- `memory/` - indice MEMORY.md + registros em bugs/, padroes/, pes/ (templates TEMPLATE-*.md)
- `settings.json` - VAZIO `{}` (chaves mortas removidas em 21/10/2026; hooks nunca funcionaram)
- `system-prompt-advpl-opus55.md` - identidade AdvPL specialist (carregado via instructions)
- `memory.md` - este arquivo (contexto Vortice)

### Skills registradas (skills.paths do opencode.json do projeto)
- `skills/vortice/` - 27 skills AdvPL canonicas (advpl-protheus, advpl-code-generation, advpl-debugging, sx-configuration, protheus-reference, etc.)
- `skills/advpl-tlpp/` - 21 skills engpro (utf8-to-cp1252-conversion, advpl-tlpp-compile, mvc-generator, query-builder, etc.)
- `skills/superpowers/` - workflow generico (systematic-debugging, TDD, plans)
- `skills/unlazy/`
- Espelho de referencia (NAO registrado): `CONFIG/.opencode/skills/` (45 skills)

### Config global (`~/.config/opencode/`)
- `opencode.json` - model=opencode/mimo-v2.6-flash-free, small_model=deepseek-v4.1-flash-free, agents.plan=deepseek-v4.1-flash-free, plugin=[opencode-supermemory], MCPs (context7, playwright, github, persyst-memory, supabase, notebooklm, rea)

## Documentos de Referencia Externos

- `AGENTS.md` - regras Vortice (raiz do projeto)
- `CONFIG/AGENTS.md` - super-regras workspace (SIGAEST, stack, model routing)
- `docs/` - fontes.md, tabelas.md, convencoes.md, workflow.md (consultar sob demanda)
- `skills/vortice/advpl-protheus/SKILL.md` - skill canonica com padroes e checklist
- Vault Obsidian: `C:\Users\Vortice 0097\Desktop\BKP_JUAN\Memoria\Memoria\ADVPL-Protheus\`

## Pendencias e Limitacoes Conhecidas

1. **Encoding**: Conversao UTF-8 → CP1252 via skill `utf8-to-cp1252-conversion` (`skills/advpl-tlpp/`)
2. **Git**: Repositorio nao versionado — sem `git status/diff/log`
3. **Glob case-sensitive**: `**/*.prw` nao acha `.PRW` no Windows — usar `**/*.[pP][rR][wW]`
4. **Skills no CLAUDE.md**: referencia `CLAUDE.md` foi removida (arquivo nao existe mais); verificar `available_skills` antes de usar qualquer skill

## Fluxo de Trabalho Recomendado

1. **Inicio de sessao**: ler este arquivo (`.opencode/memory.md`)
1.5 **Consultar memoria de erros**: se a tarefa envolver correcao de bug ou erro, carregar a skill `advpl-error-memory` (`skills/vortice/`) e consultar o indice `.opencode/memory/MEMORY.md` para verificar se o problema ja foi resolvido anteriormente
2. **Antes de responder qualquer solicitacao**: identificar a tarefa e carregar a skill correta conforme a Tabela de Roteamento em `AGENTS.md` (secao "Skill Consultation Rules"). NUNCA responder tecnicamente sem antes carregar a skill relevante.
3. **Antes de implementar**: carregar skill `advpl-code-generation` (ou `protheus-business` para processo de negocio)
4. **Gerar codigo**: usar skill especifica conforme tarefa (ver tabela de roteamento)
5. **Revisar**: carregar `advpl-code-review` / `embedded-sql` apos gerar codigo
6. **Apos gerar .prw/.tlpp**: converter UTF-8 → CP1252 via skill `utf8-to-cp1252-conversion`
7. **Compilar**: usar TDS VS Code extension (skill `advpl-tlpp-compile` se necessario)
8. **Erro desconhecido**: consultar TDN (tdn.totvs.com) — nao assumir
9. **Antes de concluir**: executar Checklist de Qualidade em `skills/vortice/advpl-quality-checklist/SKILL.md`
10. **Sugerir proximo passo**: revisao, encoding, compilacao

## Regras de Comportamento (mandatorio)

> **As regras Vortice vivem em `AGENTS.md` do projeto** (raiz).
> **As super-regras workspace vivem em `CONFIG/AGENTS.md`.**
> Esta secao NAO duplica — apenas referencia para evitar drift.

Hierarquia de regras:
1. `CONFIG/AGENTS.md` — super-regras workspace (portugues, perguntar, nao presumir, GetArea, xFilial)
2. `AGENTS.md` (raiz) — regras Vortice-specificas + encoding + workflow
3. `skills/vortice/advpl-protheus/SKILL.md` — padroes detalhados + exemplos
4. `skills/vortice/advpl-quality-checklist/SKILL.md` — checklist obrigatorio pre-conclusao

## Changelog

### 16/09/2026
- **SmartView — erro `connectors.native.internal-server-error` ao CLONAR relatorio do Pedido de Compra (diagnosticado 16/09)**: erro generico (HTTP 500 do conector Webapp) SO no relatorio do Pedido de Compra; outros relatorios clonam normal. Causa-raiz confirmada com o usuario: o ON custom `SC7TReportsBusinessObject` (`FONTES/SC7TREP.tlpp`, criado 06/08, ON "Pedido Compra" area Compras) SUMIU da lista de Objetos de Negocio — a migracao 24.10->25.10 (~11/09, caso CTBR400) e/ou o patch custom01-09-2026.ptm invalidou o objeto TLPP compilado no RPO. Ao clonar, o Smart View carrega o schema do ON em tempo real -> ON inexistente = 500. Fonte integro (121 linhas ASCII, sem mudanca desde 06/08) -> CORRECAO: recompilar SC7TREP.tlpp via TDS + REINICIAR AppServer (obrigatorio p/ ON ficar visivel em REST). Licoes: (a) todo update de ambiente/lib ou patch.ptm EXIGE recompilar os .tlpp custom (objeto TLPP compilado nao sobrevive a troca de LIB) — checklist pos-migracao; (b) `connectors.native.internal-server-error` = stack real esta no appserver.log, erro generico do conector; (c) artigo TOTVS analogous: FINSV019/DSFIN-11169 (mesmo sintoma em rotinas SmartView). PENDENTE: usuario compilar + reciclar AppServer + retestar clone.
- **Includes TDS movidos — `#include "msobject.ch"` erro ao compilar SC7TREP.tlpp (16/09)**: ao recompilar, erro no include `msobject.ch`. Causa: `C:\totvs\includes` NAO EXISTE MAIS (pasta removida/backup BKP_JUAN); includes reais em `C:\Users\Vortice 0097\Desktop\BKP_JUAN\totvs\includes` (157 arquivos — msobject.ch, tlpp-core.th, totvs.ch, integratedprovider.th todos la). `.vscode/settings.json` (linter) ja apontava p/ caminho novo; CORRIGIDO: `CONFIG/servers.json` (3 ocorrencias: raiz, connectedServer, configurations) atualizado p/ caminho novo, JSON validado. Licao: erro de include em compilacao TDS = verificar CAMINHO da pasta includes antes de suspeitar do fonte; apos migrar pastas, sincronizar servers.json + settings.json. PENDENTE: recarregar janela do VS Code p/ TDS pegar a config nova e compilar. DESENVOLVIMENTO POSTERIOR (16/09): recompile -> novo erro `Syntax Error` linhas 1-2 (includes). CAUSA-RAIZ: TODOS os 157 includes em BKP_JUAN estao no formato compactado TOTVS `#zip` (12 bytes header + zlib + padding 512B) — RDMake aceita, mas o language server do VS Code NAO interpreta e marca Syntax Error nos `#include` da linha 1. `C:\totvs` NAO existe mais na maquina. SOLUCAO APLICADA: (1) script python zlib — 157 includes descomprimidos p/ TEXTO PURO em `INCLUDES/totvs/` do projeto e (2) TAMBEM in-place em `BKP_JUAN\totvs\includes` (originais #zip preservados em `includes\zip_original\`) — settings.json estava REVERTENDO a cada edicao (extensao TDS reescreve), entao agora ambos os caminhos tem texto puro e qualquer config vence. servers.json persistiu apontando `PROGRAMAS_ADVPL\INCLUDES\totvs` (validado). Nota: `.vscode/launch.json` so tem version (config de compilacao fica no servers.json). PENDENTE: recarregar VS Code + recompilar SC7TREP.tlpp + reciclar AppServer + retestar clone. DESENVOLVIMENTO FINAL (16/09): mesmo com includes texto puro, compilacao continuou `TLPPC2003 Syntax Error` (erro REAL do compilador TLPP, visivel no log `AppData\Roaming\Code\logs\<sessao>\window1\exthost\output_logging_*\1-TOTVS LS.log` — diagnostic do Problems so diz Syntax Error generico). CAUSA-RAIZ 2: SC7TREP.tlpp estava com quebras LF (Unix) — ZDIAG110/TESTDATA (que compilam) sao CRLF — compilador TLPP da LIB 25.10 e estrito a LF. Alem disso faltava `tlpp-core.th` primeiro (convencao AGENTS.md p/ .tlpp). FIX: LF->CRLF + incluir tlpp-core.th na linha 1 (script python, arquivo 121 CRLF, ASCII, sem BOM). Licoes: (a) `.tlpp` SEMPRE CRLF + tlpp-core.th primeiro; (b) erro generico do Problems = ler o log '1-TOTVS LS.log' da sessao p/ ver o codigo real (TLPPCnnnn); (c) servers.json REAL da extensao = %USERPROFILE%\.totvsls\servers.json (CONFIG/servers.json do repo e apenas copia de referencia); includes globais la apontam BKP_JUAN. DESENVOLVIMENTO FINAL ABSOLUTO (16/09): sonda minima (FONTES/ZSVPROBE.tlpp, ON copiado do SC7TREP reduzido) PASSOU pelos includes (linhas 1-4 OK) e falhou na linha 35 com erro SEMANTICO REAL: `Return type ('U') is incompatible with its declaration ('O')` no `method getData(nPage, oFilter) class ...` — FALTAVA o `as object` na IMPLEMENTACAO. O compilador TLPP novo (LIB 25.10) faz type-check estrito declaracao-vs-implementacao: os 5 metodos sao declarados `as object/character/array` no `endclass` block; a TDN oficial (pageId 625448935, atualizada 17/07/2026) mostra TODOS os exemplos com `method getData(...) as object class X` na implementacao — o compilador antigo TOLERAVA a omissao, o novo nao. EXPLICACAO COMPLETA DO CASO: na migracao 24.10->25.10 o rebuild recompilou tudo com o compilador novo -> SC7TREP falhou (sem `as object`) e o ON foi descartado do RPO -> clone do relatorio quebra (schema do ON inexistente). FIX FINAL: adicionar `as object` na assinatura de implementacao do getData (SC7TREP linha 101 + ZSVPROBE linha 35). Checklist completo de .tlpp de classe para 25.10: (1) tlpp-core.th primeiro; (2) CRLF (nao LF); (3) ASCII/CP-1252 sem BOM; (4) tipo de retorno na implementacao de TODO metodo (espelhando a declaracao). Licao de diagnostico: diagnostic do Problems so diz 'Syntax Error' generico nas linhas 1-2; o erro REAL vem por etapas no compile (log '1-TOTVS LS.log') — bissecção com sonda minima isola em minutos. MAIS UM ERRO SEQUENCIAL (16/09, ainda em 16/09): apos o `as object`, compile passou e revelou proximo erro nas linhas 103-104: `Local cFilial as character` — variavel RESERVADA do framework (regra AGENTS.md); compilador novo rejeita redeclaracao. FIX: renomeada p/ `cFilSC7` (3 ocorrencias: declaracao, FWxFilial, setWhere). Compilador novo reporta UM ERRO POR VEZ (sequencial) — cada recompile pode revelar o proximo. PENDENTE: recompilar SC7TREP (+ apagar ZSVPROBE do RPO e do disco apos validacao) + reciclar AppServer + retestar clone.

- **Promocao do ON SC7TREP p/ PRODUCAO (16/09)**: esclarecido com usuario — CINVJ6_DEV e so desenvolvimento; compilar la NAO publica na producao (RPO e por ambiente; Smart View de producao lista so o que esta compilado no RPO de PRODUCAO). Usuario confirmou que o erro de clone/ateste acontece na PRODUCAO. Caminho de promocao: TDS -> TOTVS Patch Builder -> gerar .ptm selecionando o objeto SC7TREP (anotacao da classe vai junto no RPO) -> aplicar na producao -> REINICIAR AppServer de producao (obrigatorio, igual DEV). PRE-REQUISITO: producao precisa estar na LIB 25.10 (objeto foi compilado pelo compilador novo, estrito); se producao ainda 24.10, o patch nao carrega — investigar appserver.log de producao antes. Evidencia repo: custom01-09-2026-13-44-58.ptm continha SOMENTE ZMMA02.prw — SC7TREP nao foi promovido por patch arquivado (em agosto chegou a producao por patch nao arquivado ou via outro fluxo). Os 3 ONs "Pedido de Compra" que apareceram na selecao do Smart View (Lista de Pedidos/Autorizacoes, Pedido de Compras, Pedido x Fornecedores) sao TODOS padrao TOTVS da LIB 25.10 — o custom "Pedido Compra" (descricao "...Inscricao Estadual do Fornecedor") ainda nao aparece na producao. PENDENTE: usuario verificar LIB da producao; se 25.10 -> gerar patch do SC7TREP e aplicar; depois remover ZSVPROBE do RPO do DEV.

- **VEREDICTO producao (16/09)**: portal TOTVS Cloud PaaS (Central de atualizacoes > Producao) — producao = release **24.10**: LIB **20260706** (build 20260703_152624, DESATUALIZADA; homologada 20260817), APPSERVER 7.00.240223P-20260211 (desat.), TSS 12.1.2410 (atualizada, indica linha 2410), DBACCESS atualizado. A migracao 24.10->25.10 de ~11/09 foi do **DEV** — ambientes hoje em releases DIFERENTES. CONSEQUENCIAS: (1) patch gerado a partir do DEV (25.10) NAO pode ser aplicado na producao (24.10) — regra: mesma release origem/destino; (2) fonte corrigido (as object, cFilSC7, CRLF, tlpp-core.th) e RETROCOMPATIVEL — o original compilou na 24.10 em 06/08; (3) NOVA HIPOTESE do sumico: producao sem troca de LIB desde julho + nenhum patch arquivado com SC7TREP => ON provavelmente NUNCA esteve no RPO de producao (em agosto o clone era feito no DEV — a confirmar). CAMINHOS: (A) se houver Homologacao na 24.10 -> compilar la via TDS -> patch -> producao; (B) migrar producao p/ 25.10 (janela TOTVS Cloud) -> ai patch do DEV vale. CONFIRMADO PELO USUARIO: (a) Homologacao EXISTE no tenant; (b) em AGOSTO o clone era feito NA PRODUCAO => o ON ESTEVE no RPO de producao e algo o removeu depois (principal suspeito: janela de patch 01/09; producao sem troca de LIB desde julho => nao foi migracao). NOVA HIPOTESE de falso-negativo: busca no Smart View era "pedido de compra" e o displayName do ON e "Pedido Compra" (sem "de") — se a busca casa so por nome, ele nao apareceria mesmo presente; teste pedido: buscar "Pedido Compra" + navegar lista completa da area Compras. PLANO DE RECUPERACAO (se sumico confirmado): fonte corrigido e retrocompativel (compila no compilador antigo 24.10 tb) -> (1) confirmar LIB da Homologacao (24.10/20260706 compativel c/ producao); (2) compilar SC7TREP.tlpp na Homologacao via TDS; (3) Patch Builder na Homologacao -> .ptm com objeto SC7TREP; (4) aplicar na producao (mesmo fluxo do patch 01/09) + reiniciar AppServer producao; (5) clonar. FORENSE opcional: appserver.log de producao em 01/09. PENDENTE: resultado do teste de busca + LIB da Homologacao.

### 18/09/2026
- **ZMMA01 — combo Familia agora catalogo COMPLETO da SZ5 (usuario 18/09, print: TI nao aparecia)**: combo era populado SOMENTE com as descricoes distintas dos itens processados (aItensFull[30]). DIAGNOSE CORRIGIDA apos print do usuario (MATA010): familia TI = codigo 007 (B1_ZFAMIL='007'), produtos COM Cta.Estoque 11401200001 e sem bloqueio — ou seja, PASSAM pelo filtro da analise e entram em aItensFull; hipotese 'fora do escopo CTAEST' descartada. Causa provavel restante: FamDescricao('007') nao encontra a linha na SZ5 (ou Z5_FAMIL != 'TI') e retorna o proprio codigo — combo exibia '007' em vez de 'TI'. Correcao de codigo: `CarregaFiltrosFamCrit()` agora varre a SZ5 inteira (Z5_FAMIL via DbSetOrder(1)/DbGoTop, GetArea/RestArea) antes dos distintos dos itens — mesmo padrao do combo Criticidade fixo (15/09); familias de itens NAO catalogadas na SZ5 continuam acrescentadas como codigo (fallback FamDescricao). CONFIRMADO via APSDU (18/09, DEV CINVJ6_192877_PR_DV): SZ5010 tem 7 linhas — Z5_CODFAL 001..007 (ELETRICA, ESCRITORIO, LIMPEZA, MECANICA, MINA, EPI, TI), todas R_E_C_D_E_L_=0; nome fisico do CODIGO e Z5_CODFAL (nao Z5_COD) e da DESCRICAO Z5_FAMIL; os 11 produtos B1_ZFAMIL='007' (toners, mouses, notebooks etc.) tem B1_XCTAEST='11401200001' e B1_MSBLQL='2' (nao bloqueados) — estao NO escopo e FamDescricao('007') resolve 'TI' (ELETRICA resolvida na tela prova que o seek order 1 funciona). Diagnose final: combo antigo dependia dos itens processados na sessao (cadastro 007 ajustado recentemente / AppServer sem reciclar desde 15/09); fix da varredura SZ5 completa garante as 7 familias sempre. NADA a cadastrar em dados. PENDENTE: compilar + reciclar AppServer.
- **ZMMA01 — warning W0007 AIns com 4 parametros (compilador TDS 18/09)**: `aIns(aFams, 1, "TODOS", .T.)` (herdado do ajuste de 15/09) — assinatura canonica da AIns tem 2 params (aIns(aArray, nPos), TDN + skills/vortice/protheus-reference/native-functions.md linha 1239); extras descartados e NIL inserido na pos 1 em vez de "TODOS" (bug latente de runtime). FIX: removidos aDel/aSize/aIns — "TODOS" ja nasce na pos 1, ordenacao agora `ASort(aFams, 2, , {|x,y| Upper(x) < Upper(y)})` (nStart=2, preserva pos 1; assinatura canonica ASort(aArray, [nStart], [nCount], [bOrder])). `Local nPos` tambem removido (sem uso). Arquivo ASCII/CRLF, diff-check OK. Licao: warning de compilador sobre contagem de parametros em funcao nativa = assinatura errada real, corrigir sempre (API Symbol Validation).

### 15/09/2026
- **REGRA PERMANENTE — Idioma**: SEMPRE responder em **português brasileiro**, em todas as interações, independente de nova sessão ou continuação. Não esquecer entre sessões. (Reforça AGENTS.md linha 9.)
- **ZMMA01 — combo Criticidade FIXO com as 3 opcoes (usuario 15/09)**: combo era populado com valores distintos dos itens — se nenhum produto tem criticidade C, "POUCO CRITICO" nao aparecia. `CarregaFiltrosFamCrit()` agora usa aCrits FIXO: TODOS + MUITO CRITICO + CRITICIDADE MEDIA + POUCO CRITICO (A/B/C conforme CritDescricao/VOREST02); somente Familia continua dinamica (distintos dos itens). Arquivo 1200 linhas ASCII/CRLF, diff-check OK. PENDENTE: compilar + reciclar AppServer.
- **ZMMA01 — DOS voltou a texto "N dias" + altura do detalhe restaurada (usuario 15/09)**: a coluna DOS numerica com picture @E 999 exibia "***" para DOS > 999 (ex. consumo baixissimo: 19/(1/90) = 1.710 dias) — DOS da coluna e do detalhe voltaram ao formato texto "N dias" / "SEM CONSUMO" (cTendencia texto nos 3 aAdd, RETIRAR = "SEM CONSUMO"); ordenacao por clique na coluna DOS mantida extraindo o numero do texto (Val(StrTran(x[25], " dias", ""))); outras colunas numericas (SetType N) continuam com ordenacao nativa. CompItens voltou ao desempate por aX[21] (media 3M). Dialogo do detalhe voltou a 570px (400px cortava os valores sugeridos). Arquivo 1209 linhas ASCII/CRLF, diff-check OK. PENDENTE: compilar + reciclar AppServer.
- **ZMMA01 — BUG thread error OCMBFAM (resolvido 15/09)**: `CarregaFiltrosFamCrit()` (chamada dentro de ProcessaAnalise via Processa) recebia "variable does not exist OCMBFAM" — os objetos dos combos estavam `Local` em `ZMMA01()`, invisiveis para outras funcoes. Correcao: `oCmbFam`/`oCmbCrit` movidos para `Private` (mesmo padrao do `oBrowse`, que ja funcionava). Lição: objetos de UI referenciados em funções externas SEMPRE Private neste fonte. Também corrigido antes: `SAY PROMPT` sem variavel de objeto nao compila (era vermelho no editor) — padrao correto `SAY oSayFam PROMPT ...
- **ZMMA01 — filtros Familia/Criticidade + ordenacao por clique no cabecalho (usuario 15/09)**: (1) dois combos novos ao lado do Filtro Acao ("Filtro Familia" @465 e "Filtro Criticidade" @656), populados por `CarregaFiltrosFamCrit()` apos cada Processar com valores DISTINCTOS das descricoes presentes em aItensFull[30]/[31] (TODOS sempre primeiro via aIns); filtros aplicados em `AplicaFiltros()` comparando descricao (case-insensitive; itens com familia/crit vazia so aparecem em TODOS); botao Limpar reseta os dois combos. (2) Ordenacao por clique no titulo: TODAS as colunas ganharam `bHeaderClick := {|| OrdenaBrowse(pos)}` (API validada em terminaldeinformacao.com Ti Responde 060/022 — coluna FWBrwColumn tem bHeaderClick publico; SetItemHeaderClick e do FWBrowse com alias, NAO com array); `OrdenaBrowse(nPosArr)` ordena aItens por ASort com ValType (N: numerico; C: case-insensitive), PRIMEIRO clique = DECRESCENTE (maior para menor, pedido do usuario), clique repetido alterna direcao (nUltColOrd/lUltOrdDesc privates). Cuidado: comentário com "põe" deixou o arquivo UTF-8 — corrigido para ASCII puro (regra CP-1252). Arquivo 1199 linhas CRLF, diff-check OK. PENDENTE: compilar + reciclar AppServer.
- **ZMMA01 — detalhe do item: descricao sem corte + tela menor + motivo em 2 linhas (usuario 15/09)**: print MC.0301.00037 mostrou descricao cortada ("...COM DUA") — causa era `Left(cDesc,48)` na `DetalheItem`, removido (descricao completa, SAY alargado para 690). Dialogo do detalhe rebaixado de 570 para 400 px. Motivo dividido em 2 SAYs: linha 1 = contexto do estoque/DOS (cMotivo), linha 2 = "Sugestao: ..." (cMotivo2, @234) — ambos cabem em 630px sem corte; rodape reorganizado (@246/254/264). Arquivo 1065 linhas ASCII/CRLF/sem BOM, diff-check OK. PENDENTE: compilar + reciclar AppServer.
- **ZMMA01 — refinamentos pós-teste de tela (usuario 15/09)**: (1) motivo do detalhe VOLTOU ao formato anterior em linha unica (MontaSugestao restaurada; MontaLinhaParam removida sem chamadores); (2) Familia/Criticidade agora exibem DESCRICAO: helper `FamDescricao()` busca SZ5→Z5_FAMIL (GetArea/RestArea) e `CritDescricao()` converte A/B/C em MUITO CRITICO/CRITICIDADE MEDIA/POUCO CRITICO (espelhado de VOREST02.PRW); (3) ordenacao por clique no cabecalho: colunas numericas do browse (DOS[25], Min[3], Max[24], Baixas[20], SugMin[15], SugMax[16], ValUnit[18], ValTot[19], Saldo[26], Media[21]) agora retornam valor BRUTO com SetType("N") + SetPicture (antes Transform() string quebrava ordenacao numerica — 68 < 8 ordenava errado); coluna DOS do browse virou numerica (cTendencia armazena aClassif[5] numerico; RETIRAR = 0; detalhe formata "N dias"); CompItens ordena desempate por aX[25] (DOS) em vez de aX[21]; correcao da ordenacao nativa FWBrwColumn via SetType/SetPicture validada em terminaldeinformacao.com (ex. zGrid, Atilio) — SetOrder nao encontrado em fonte valida, nao usado. Arquivo 1062 linhas ASCII/CRLF/sem BOM, diff-check OK. PENDENTE: compilar + reciclar AppServer.
- **ZMMA01 — faixas DOS ajustadas + colunas Família/Criticidade + filtro código OU descrição (pedido do usuario 15/09)**: (1) faixas de classificacao agora AUMENTAR <= 19 dias / MANTER 20-40 dias / REDUZIR >= 41 dias (`ClassificarItem`, `cRegraCalc`, motivos, legenda, texto explicativo do topo e rodapé do detalhe) — excecoes 1 e 2 inalteradas, so a faixa MANTER citada virou 20-40; sugestoes continuam Min = consumo x20 e Max = x40 (criterio de reposicao, nao faixa de classificacao). (2) Novas colunas no browse: Familia (`aItens[30]` = SB1 `B1_ZFAMIL`) e Criticidade (`aItens[31]` = SB1 `B1_ZCRIT`, valores A/B/C conforme VOREST02) — campos validados existentes no dicionario (usados em VOREST02.PRW); aItensFull agora com 31 posicoes nos 3 pontos de aAdd (CTAEST com consumo, sem consumo na janela e varredura SB1 sem consumo). (3) Filtro de produto corrigido: pesquisava SOMENTE codigo (typo "cadigo"); agora pesquisa codigo OU descricao, case-insensitive (`AplicaFiltros`). Arquivo 1025 linhas ASCII/CRLF/sem BOM, `git diff --check` OK. PENDENTE: compilar + reciclar AppServer.
- **ZMMA01 — Motivo com justificativa separada Min/Max (pedido do usuario 15/09)**: campo Motivo do detalhe reestruturado em 3 linhas — (1) contexto do estoque (DOS) + excecao que definiu a acao quando houver; (2) linha MINIMO: direcao com valores (ex. "Reduzir 60 -> 40 un"), regra aplicada ("consumo diario x 20 dias") e motivo da variacao ("atual cobre N dias, acima/abaixo do criterio..."); (3) linha MAXIMO: idem com criterio x40, citando "Excecao 1/2" quando for o caso. Ambas SEMPRE exibidas, mesmo quando so uma variou. Novo helper `MontaLinhaParam()` substitui `MontaSugestao()` (removida sem chamadores — regra anti-codigo-morto). Dialogo: labels de motivo deslocados (@225/234/243) e nota de janela/rodape para @253/261/271 (dialogo 570px, espaco OK). Sem `Iif` (CA4000). Arquivo 1008 linhas ASCII/CRLF/sem BOM, `git diff --check` OK. PENDENTE: compilar + reciclar AppServer.
- **ZMMA01 (Analise Min/Max) — regra DOS 20/40 concluida**: `ClassificarItem()` com AUMENTAR <20 dias / MANTER 20-39 / REDUZIR >=40; sugestoes Min = consumo diario x20 e Max = x40 (consumo diario = baixas 3M/90); anti-contradicao: Max sugerido > Max atual => acao permanece AUMENTAR, com excecao explicitada no motivo e na legenda. Coluna 5 do browse virou "DOS". Limpeza final: `ArredInteligente`/`ArredDezena` (mortas, zero chamadores no projeto) removidas; comentarios obsoletos ("limitador 25%", CRESCENTE/DECRESCENTE em AplicaFiltros) corrigidos; header `@version 5.0`. Encoding OK (ASCII/CRLF/sem BOM, 974 linhas) e `git diff --check` OK. ZMMA02 nao tocado. PENDENTE: compilar via TDS + atualizar RPO + reciclar AppServer (tela pode continuar exibindo regra antiga ate la).
- **ZMMA01 — anti-contradicao SIMETRICA (decisao do usuario 15/09)**: caso MC.1004.00014 revelou lacuna — DOS 30 (faixa MANTER) com Max atual 130 > Max sugerido 80 e sugestao de REDUCAO R$ 1.400, mas acao MANTER com motivo falso "dentro da faixa ideal". Regra nova em `ClassificarItem()`: na faixa 20-39 dias, `nSugMax < Max(nMaxAtual,0)` => acao vira REDUZIR (BR_AZUL) — simétrica da regra AUMENTAR. Motivo REDUZIR agora distingue DOS >= 40 ("capital parado") de 20-39 ("maximo atual supera o sugerido"); motivo MANTER agora usa `MontaSugestao()` (nunca afirma alinhamento falso); `cRegraCalc` agora exibe apenas "= REDUZIR"/"= AUMENTAR" (frases "anti-contradicao: ..." removidas dos textos visiveis a pedido do usuario — decisao de tipo/severidade ja explicada nos motivos); legenda, cabecalho da tela e rodape do detalhe atualizados. Arquivo ficou com 976 linhas CRLF/ASCII, `git diff --check` OK. PENDENTE: compilar + reciclar AppServer.

### 14/09/2026
- **Regra de idioma (item 8)**: usuario reclamou que as conclusoes vinham em ingles — TODAS as respostas agora em portugues brasileiro, sem excecao.
- **Investigacao CTBA350 em aberto**: alavancas oficiais validadas na Central TOTVS — (a) MV_CT350SL=.T. atualiza saldos na propria efetivacao (elimina o Reprocessamento de Saldos pos-CTBA350; artigo 20495450539159); (b) CT5_TPSALD='9' no Lancamento Padrao SOBRESCREVE o MV_PRELAN (artigo 360006689172) — se LP 666 estiver com tipo 9, corrigir no cadastro da LP elimina a CTBA350; sem customizacao viavel (alterar CT2_TPSALD direto quebra conciliacao CT1/CT7/CT3). Resultados 14/09: Q2 (SX6) confirmou MV_PRELAN=N, MV_ALTLCTO=S (regra 'inconsistencia forcada a pre' descartada), MV_ATUSAL=S e MV_CT350SL VAZIO (logico vazio = comporta-se como .F. → causa da etapa extra de Reprocessamento confirmada; acao: preencher conteudo 'S' no Configurador). Q1 falhou com erro 207: coluna CT5_LP NAO existe fisicamente na CT5010 — discovery via INFORMATION_SCHEMA retornou SOMENTE CT5_TPSALD varchar — NENHUM campo fisico com 'LP' no nome em CT5010 (nome fisico do campo do codigo do LP difere neste build). Proximo: SX3010 retornou campos fisicos da CT5: CT5_LANPAD (Cod Lanc Pad, ordem 02 — nome fisico do campo do LP), CT5_SEQUEN (03) e CT5_TPSALD (27, Tipo do SLD). Q1 definitiva montada: WHERE CT5_LANPAD='666'. Usuario ALTEROU MV_CT350SL para .T. em 14/09 (confirmado via SX6: X6_CONTEUD='.T.') — Acao 1 CONCLUIDA em DEV: a partir da proxima CTBA350 os saldos serao atualizados na propria efetivacao (etapa Reprocessamento de Saldos eliminada; help 'At, De saldo desligada' deixa de aparecer). Pendente: validar no proximo fechamento mensal em DEV e depois replicar para producao (conteudo SX6 via wizard/patch). Acao 2 FECHADA em 14/09: Q1 definitiva (CT5_LANPAD='666') retornou 2 sequencias (001/002), TODAS com CT5_TPSALD='1' — LP limpo. Conclusao oficial: pela KB TOTVS/Mastersiga (texto oficial do produto), a NOVA jornada de fechamento (Acompanha Custos) contabiliza via ExecAuto e grava TODOS os lancamentos como pre-lancamento (tipo 9) POR DESIGN, 'para evitar lancamentos inconsistentes com tipo de saldo 1' — o MV_PRELAN=N nao muda isso no fluxo novo. Portanto a CTBA350 mensal e INEVITAVEL no 25.10 (nao existe parametro/customizacao p/ nascer tipo 1); o que se pode eliminar era so o Reprocessamento (MV_CT350SL=.T., ja feito). Ritual final: Jornada → CTBA350 (Efet. p/ Saldo=1) → CTBR400. Fontes: central TOTVS art. 20495450539159 e 360006689172 + mastersiga.tomticket.com (KB oficial estoque-custos).
- **Query CT2 (auditoria tipo 9) 14/09**: retornou 2 grupos — (1) doc 000026/lote 008840/linha 449 R$44,14 SEM conta débito (a pendência conhecida, ainda viva) e (2) ~24+ linhas do doc 000006/mesmo lote (requisições, débito+CCD preenchidos, crédito=11401200001, CCC vazio) que bateram no filtro SÓ por CCC vazio — crédito em estoque normalmente NÃO exige CC (falso positivo da condição OR). LICOES: (a) query de auditoria CT2 deve SEMPRE incluir CT2_FILIAL (efetivação 11/09 foi só filial 0102 — linhas de outra filial permanecem tipo 9 legitimamente); (b) vazio CCC no lado crédito = provavelmente normal, não tratar como inconsistência; (c) ambiente de consulta = DEV (DBEnv CINVJ6_192877_PR_DV). Queries refinadas executadas 14/09 — RAIO-X FINAL: (a) filtro de conta faltando retornou SÓ 1 linha = R$44,14 (0102/20260731/lote 008840/doc 000026/linha 449, crédito 11401200001, débito vazio); (b) group by filial/TPSALD: 0101 tipo1=103.722 lan, 0102 tipo1=372.249 lan, 0102 tipo9=**1 lan R$44,14** — não existe NENHUM outro pré-lançamento no banco (448 efetivados em 11/09 + esta 1 = total da jornada). Base confirmada limpa. TESTE DEV (14/09): usuario rodou fechamento mes 8 com MV_CT350SL=.T. e reportou CTBR400 sem baixas 'sem rodar o processamento' — hipotese: pulou a CTBA350 (o parametro elimina SO o Reprocessamento POS-efetivacao; a efetivação CTBA350 continua OBRIGATORIA — sem ela o CT2 fica tipo 9 e o Razao TPSALD=1 nao mostra nada). Orientacao enviada: ritual Jornada → CTBA350 (Efet. p/ Saldo=1) → CTBR400 + query de verificacao CT2 do periodo 202608 por TPSALD. Query rodada pelo usuario: periodo 202608/filial 0102 tem SO tipo 9 (421 lan, R$40.950,72) e NENHUM tipo 1 — prova conclusiva de que a CTBA350 nao foi executada no teste (diagnostico correto: parametro so elimina Reprocessamento, nunca a efetivacao). CTBA350 orientada p/ periodo 08/2026. POS-CTBA350 (14/09): periodo 08/2026/0102 agora mostra tipo 1 = 417 lan / R$40.834,98 (efetivacao funcionou) — mas delta 421→417 = 4 lan / R$115,74 a verificar (provaveis inconsistencias remanescentes tipo 9; conferir group by de novo + relatorio da CTBA350). Duvida conceitual do usuario respondida: MATA330 avulso (fluxo antigo, tela interativa) nasce tipo 1 direto; Acompanha Custos (jornada ExecAuto, sem tela) nasce tipo 9 POR DESIGN — CTBA350 substitui a tela interativa. ALERTA enviado: NAO rodar MATA330 avulso + jornada no mesmo periodo (risco de contabilizacao duplicada). Aguardando confirmacao do CTBR400 com baixas sem Reprocessamento (validacao final do MV_CT350SL=.T.). PEDIDO EXPLICITO (14/09): usuario quer jornada gerando CT2_TPSALD=1 direto. AVALIADO: nao existe parametro/PE suportado p/ isso — by design (KB TOTVS/Mastersiga + art. MATA038 Central 17143292484759: jornada embute MATA330/MATA331/MATA280; contabiliza via ExecAuto → tipo 9). Alterar CT2 direto quebra conciliacao CT1/CT7/CT3 → recusado. OPCOES apresentadas: (A) jornada + CTBA350 [oficial, ritual enxuto com MV_CT350SL=.T.]; (B) MATA330 avulso com contabilizacao → nasce tipo 1 direto (COMPROVADO no proprio ambiente: 08/2026/0102 tipo1=417/R$40.834,98) + virada legado, abrindo mao da jornada; (C) chamado TOTVS perguntando parametro/roadmap. MATA330 NAO foi descontinuada (resposta oficial no art. MATA038). Delta 421→417 (4 lan/R$115,74) saiu do tipo 9 SEM virar tipo 1 — provavel recontabilizacao limpou docs; conferir antes de decidir. Regra: NUNCA rodar as 2 contabilizacoes no mesmo periodo. Usuario NAO respondeu se rodou MATA330+jornada no mesmo periodo 08. BUSCA EXAUSTIVA DE PE ENCERRADA (14/09): catálogos oficiais lidos — PEs MATA038 (art. 8823802604695: jornada mantem os PEs de MATA330/331/280, sem interface), MATA330 (art. 1500003970802: lista completa — MA330CP/CTB/TRB/FIM/MOD/SEQ/D1/D2/D3/P3/AL/OK/PRC/PGI/PGF/TRF, A330GRUP/DECC/QTMO/M330FCC/CDEV/CD2/CD1/M330CMU) — NENHUM expoe/intervem CT2_TPSALD. Motor de contabilizacao (ExecAuto) é fechado: grava 9 por design, sem PE. CONCLUSAO DEFINITIVA: nao existe ponto de entrada suportado p/ jornada gravar tipo 1; quem prometer isso esta vendendo update direto em CT2 (quebra conciliacao CT1/CT7/CT3 + flags de origem — recusado). Caminhos remanescentes: (1) testar em DEV agendar CTBA350 via Smart Schedule com pergunte gravado p/ efetivacao automatica pos-jornada (zero customizacao — recomendação); (2) custom Z* chamando API de efetivação SO se TOTVS informar a funcao suportada via chamado; (3) chamado TOTVS pedindo parametro/API/roadmap. DESCOBERTA 14/09 — VCTBL001/VCTBL002 (Downloads + FONTES/VCTBL002): User Functions usadas como EXPRESSAO de conta nos LPs contabeis (VCTBL001=LP 650-001, contexto SD1/NF entrada; VCTBL002=LP do custo, contexto SD3/requisicoes): derivam conta debito por prefixo do CC via campos custom B1_XCTCUST/XCTDESP/XCTCIND/XCTAEST. BUG IDENTIFICADO: sem Else final — se CC vazio ou fora dos prefixos (60/5010204, 70/80/90, 50/10-14/0199) e o produto tem QUALQUER XCT preenchido, retornam '' → lançamento nasce SEM CONTA DEBITO. HIPOTESE FORTE: essa e a causa do R$44,14 (linha 449, debito e CCD vazios → D3_CC vazio provavel). NAO interferem no TPSALD/9. Query de confirmacao enviada (SD3: TM 402, D3_CUSTO1=44.14, 07/2026). Correcao proposta: Else fallback → B1_CONTA + tratamento explicito de CC vazio; exige decidir regra de negocio p/ CC fora da lista. REVELACAO DO USUARIO (14/09): no fluxo antigo (MATA330 interativo) ele DELETAVA na tela os lancamentos sem conta/CC — isso mascara a causa-raiz (os custos saem do razao inteiros, debito e credito somem) e explica Razao 'limpo' antes de 25.10. Na jornada (sem tela) nao da p/ deletar → pendencias ficam tipo 9 e aparecem na CTBA350: mes 08 = 4 lan / R$55,74 retidos (delta 421→417 confirmado; totais mudaram vs snapshot anterior — consistente com delecoes/recontabilizacao nos testes). Pendencias de julho (1x R$44,14) + agosto (4x R$55,74) = mesma classe: VCTBL002 sem fallback p/ CC vazio/fora de lista. GOVERNANCA: parar de deletar CT2; corrigir causa (VCTBL002/cadastro CC) → ajustar lancamento → efetivar. DECISAO DO USUARIO (14/09): NAO quer fallback na VCTBL002 — quer que NAO contabilize os itens sem conta contabil e/ou sem CC (fora da regra; a baixa da regra e TM 502), mantendo os itens dentro da regra. SOLUCAO DESIGNADA: condicao de geracao no proprio LP (CT5_COND, campo 'Cond.' do Lançamento Padronizado no SIGACTB) com expressao !Empty(SD3->D3_CC) .AND. !Empty(U_VCTBL002()) — sem codigo novo, VCTBL002 intocada. Pendencia RESOLVIDA: CT2_LP do doc 000011 (agosto) = 666 em TODAS as linhas — o LP das requisicoes e o proprio 666 ja auditado (CT5_LANPAD='666', 2 sequencias 001/002, TPSALD=1). ORIENTACAO CRITICA: aplicar CT5_COND nas DUAS sequencias (se condicionar so a seq 001/debito, a seq 002/credito gera sozinha → lancamento desbalanceado so-credito). Expressao: !Empty(SD3->D3_CC) .AND. !Empty(U_VCTBL002()). Alteracao de dicionario — sem recompilar; replica via wizard/patch. 5 pendencias legadas (4 ago + 1 jul) exigem decisao: completar entidades e efetivar OU excluir via rotina de contabilidade com documento do motivo. ALERTA dado: excluir da contabilizacao = custo sem contrapartida (Razao nao fecha com SD3 no mes — mesmo efeito das delecoes antigas, agora sistematico e documentado). PENDENCIAS AGO/2026 IDENTIFICADAS (14/09): doc 000011/lote 008840 — linhas 211 (R$1,17 TM506), 212 (R$28,80 TM109), 214 (R$1,75 TM506) SEM conta debito E SEM CCD; linha 213 (R$24,02 TM402) COM conta 31202100002 mas CCD vazio. CT2_HIST carrega o DOC do SD3 (ex.: MC.0506.00066). Query SD3 por D3_CUSTO1 retornou VAZIA — causas: (a) virgula decimal ('1,17' → SQL le 1 e 17); (b) D3_EMISSAO filtrada = 31/08 exato, mas a requisicao pode ser de outro dia (contabilizada na data de fechamento). Chave correta de busca: D3_DOC do historico (000066/000096/000176). Query corrigida enviada (por TM + CC vazio/fora da lista no mes todo). Regra permanente CONFIRMADA pelo usuario em 14/09: SEMPRE responder em portugues brasileiro — instrucao explicita do usuario prevalece sobre qualquer configuracao de idioma da plataforma. Licoes: (a) console do Webapp remove o hint (NOLOCK) da query → erro 156 'Incorrect syntax near WHERE' — enviar queries SEM WITH (NOLOCK); (b) validar colunas fisicas via INFORMATION_SCHEMA antes de query (caso CT5_LP).

### 11/09/2026
- **Caso arquivado: Acompanha Custos 25.10 — baixas fora do Razão (CTBR400)** — causa: jornada grava contabilização como pré-lançamento (CT2_TPSALD=9) mesmo com MV_PRELAN=N; solução: CTBA350 mensal (Efet. p/ Saldo=1) + Reprocessamento de Saldos. Registrado no Obsidian (06).
- **Query de referência criada**: diff de assinatura CT2 (MES/FILIAL/LP/TPSALD/MOEDLC/ROTINA/DEBITO/CREDIT) entre mês bom e mês ruim — isola a coluna que mudou.
- **Nomes de coluna corrigidos em campo**: CT2_MOEDLC (não CT2_MOEDA), D3_CUSTO1 (não D3_CUST1) — sempre validar via INFORMATION_SCHEMA antes de query.

### 08/09/2026
- **ZCOMPRAS (Consulta de Compras)**: novo indicador "Produtos Distintos" — funcao `ContaProdutosDistintos()` com `COUNT(DISTINCT C7_PRODUTO)` no SC7 replicando EXATAMENTE os filtros da consulta principal (filial, periodo C7_EMISSAO, comprador C7_USER, C7_RESIDUO<>'S', aprovacao C7_CONAPRO, produto nao vazio), via ChangeQuery/TCGenQry. Chamada em ConsultarDireto (C7_USER = cod) e GeralSuprimentos (C7_USER IN). Exibido na linha 5 do painel de indicadores (linhas compactadas 034/052/070/088; barra de progresso movida p/ box 120-136, TPanel 121,125, "Meta 3%" 139, % 123) e no export TReport (header + linha de totais: "| Produtos distintos: N"). Limitacao conhecida: contador nao recalcula se pedido excluido na tela (aCompras nao guarda C7_PRODUTO por linha).
- **ZCOMPRAS fix compilacao (linha 65)**: `Local cCodLogado := RetCodUsr()` declarada APOS codigo executavel (`CarregaCompradores()` linha 60) — erro RDMake (Local deve vir antes de qualquer codigo). Variaveis cCodLogado/nPosLog eram MORTAS (zero referencias). Removidas as 2 declaracoes + comentario obsoleto "Pre-seleciona o usuario logado" (contrariava a logica: comprador inicia em branco).
- **ZCOMPRAS alinhamento de botoes**: dialog de parametros — 2 linhas de botoes (Geral Suprimentos/Relat. Geral em y=094 e Consultar/Cancelar em y=120) alinhadas a coluna do formulario: borda esquerda x=020 (igual labels), largura 090, vao 10px (x=020-110 e x=120-210), altura 015.
- **ZLOGCOL rodape % frete**: nova `MontaMsgFrete(aArray)` — % Frete = (Soma Vlr.Coleta / Soma Vlr.Pedido) x 100 sobre SOMENTE as coletas filtradas (pos 6 = ZZ3_VALCOL, pos 15 = TOTPED), formato "Porcentagem de Frete: 0.53% | Frete Total: R$ ... | Pedidos Total: R$ ...". Recalculada em Filtrar/Limpar/Atualizar/Editar via oSayCalcFrete:Refresh().
- **ZLOGCOL fix rodape invisivel no TOTVS Webapp**: TSay do rodape em y=330 (apos os botoes y=305) NAO aparecia — o Webapp ESTICA o LISTBOX verticalmente alem do SIZE declarado (640,260 -> ~470px renderizado), empurrando os controles posteriores para baixo; os botoes sobrevivem mas o TSay caia alem da altura do dialog (TO 650) e era cortado. Fix: grid 260->250 e rodape em y=292 (faixa ENTRE grid e botoes de acao — sempre visivel mesmo com o stretch). Largura TSay 1000->1200. Registrado no Obsidian (06 e 07).

### 04/09/2026
- **ZMMA01 (Analise Min/Max)**: corrigida contradicao com consumo muito baixo — 3 regras: (1) se Maximo sugerido > Maximo atual, alerta obrigatoriamente AUMENTAR (nunca REDUZIR); (2) texto do Motivo honesto com direcao correta via helper `MONTASUGESTAO()` (Aumentar/Reduzir/Manter para X unidades conforme sugerido vs atual) e prefixo baseado no DOS real; (3) trava: Min/Max sugeridos >= 1 (sem fracao de produto). Linha "Regra:" do detalhe passou a indicar quando a acao final foi ajustada pela regra anti-contradicao.
- **Registrado** em `06 - Bugs Resolvidos.md` (Obsidian).

### 30/08/2026
- **CADPOSIC**: criado tela FWMBrowse para tabela ZC1 (Posições de Estoque do Item) com pesquisa rápida. 3 erros resolvidos: SetSeek com aSeek, aRotina+cCadastro para CRUD, nomes de campos ZC1 conferidos no Configurador.
- **Atualizado**: `06 - Bugs Resolvidos.md` (Obsidian) com caso FWMBrowse SetSeek.
- **Atualizado**: `07 - Padrões de Código ADVPL.md` (Obsidian) com padrão FWMBrowse + pesquisa rápida.

### 15/08/2026
- **MATA120 IPI**: solucao completa em 3 camadas — gatilho SX7 U_MT120IPI (tempo real + MaFisRef para rodape), MTA120G3 (gravacao), impressao pendente (form recalcula IPI bruto). SC7 validado via APSDU.
- **Atualizado**: `06 - Bugs Resolvidos.md` (Obsidian) com solucao completa e pendencia de impressao.

### 02/07/2026
- **Caso arquivado: FWBUILDFEATURE / SSYacc0105e** — bug em `PROTHEUSFUNCTIONMVC.PRX` quando `X3_PICTVAR` tem `@!`
- **Skill canonica criada**: `advpl-fwbrowse-fwbldfeature-bug` (em `.opencode/skills/advpl-fwbrowse-fwbldfeature-bug/SKILL.md`)
- **Solucao aplicada**: ZLANCDIE.PRW refatorado de FWMBrowse para mBrowse (padrao CADSZ3.PRW)
- **Atualizado**: memory.md com secao "Casos Arquivados" para consulta futura
- **Fontes oficiais**: 5 artigos TOTVS Central + 1 thread Forum TOTVS (build 7.00.240223P)

### 30/06/2026
- **Cleanup completo do workspace** — todos os artefatos mortos removidos:
  - PAI `.opencode/`: removidos `.vscode/` (leak de cache VSCode), `node_modules/` (25 pacotes), `package.json`, `package-lock.json`
  - FILHO `programas_vortice/`: removido `node_modules/` (28 pacotes SQL Server)
  - FILHO `.opencode/`: removidos `node_modules/` (28 pacotes), `package.json` (plugin ref quebrada)
- **Provider Ollama removido** do global `opencode.jsonc` (URL ngrok era efemera, nao utilizada)
- **Agent.disable para README** testado — `agent.disable` em `opencode.json` NAO funciona para agentes built-in do OpenCode
  - Issue #15222 (enable/disable from TUI) aberta desde Fev/2026
  - Issue #21364 (`footerShowSubagents`) planejado para v1.3.6 mas nao implementado
  - **Conclusao**: agente README e feature built-in, nao configuravel — usuario deve ignora-lo no TUI
- **verify-harness.ps1**: 28/28 PASS (estado final limpo)
- Estado final:
  - PAI: 4 agents, AGENTS.md, memory.md, opencode.json, openspec-config.yaml, 2 references, tui.json
  - FILHO: 10 agents, 45 skills, memory.md, opencode.json (instructions + commands + MCPs)
  - Global: model routing, shell=powershell, MCP advpl-tds-ls

### 29/06/2026 (continuacao)
- **Investigado e removido**: 5 `commands_opsx-*.md` + 5 `openspec-*.md` soltos no PAI `.opencode/`
  - `commands_opsx-*` eram versoes antigas (substituidas por inline templates em `programas_vortice/opencode.json`)
  - `openspec-{apply,archive,explore,propose,sync}.md` eram duplicatas (canonico em `../.claude/skills/`)
  - `openspec-project.md` orfao removido
  - PAI typo detectado: `/opsx:apply` → canonical `/opsx-apply` em .claude/skills/
  - Mantidos: `openspec-config.yaml` (config), 2 `references_*.md` (docs uteis)
- **Leak de cache removido**: `\.opencode\.vscode\` (com `.advpl` e `.cache` do VSCode) - lixo
- **Deps mortas removidas** (confirmado por busca: nao referenciadas em nenhum `opencode.json`):
  - PAI: `package.json` (com `@kilocode/plugin` + `@opencode-ai/plugin`) + `package-lock.json` + `node_modules/` (25 pacotes)
  - FILHO: `package.json` (com `@opencode-ai/plugin`)
- **`.claude/hook-chains.json` removido** (estava `enabled: false` - dead code)
- **`.claude/README.md` criado** documentando uso dual (Claude Code + OpenCode)
- **`verify-harness.ps1` criado** em `programas_vortice/` - smoke test com 28 checks (executar antes de cada deploy)
- **`README.md` criado** em `programas_vortice/` - onboarding rapido (hierarquia, model routing, como rodar)
- PAI `.opencode/` final: 4 agents, AGENTS.md, memory.md, opencode.json, openspec-config.yaml, 2 references, tui.json
- FILHO `.opencode/` final: 10 agents, 45 skills, memory.md, opencode.json (schema-only)

### 24/06/2026
- Removido: duplicacao de regras entre `AGENTS.md` FILHO e `memory.md` (referencia cruzada)
- Criado: skill `advpl-quality-checklist` (extraida de `advpl-protheus.md`)
- Atualizado: PAI `AGENTS.md` para 5 super-regras (workarounds historicos mantidos)
- Reorganizado: hierarquia PAI (5) -> FILHO (13) -> canonica (detalhes) -> checklist (gate)

### 01/09/2026
- MTA185MNU.PRW: TReport paisagem A4 fonte 8. Colunas CP_NUM(09), CP_ITEM(06), CP_PRODUTO(20), B1_DESC(135), ZC1_POSIC(10), CP_QUANT(12). Solicitante no header via PrintText. Query SCP+ZC1+SB1, filial '0102'. CP_QUANT numerico do SQL (nao Val). "Atualizar" removido.
- CADPOSIC.PRW: FWMBrowse ZC1 com SetSeek, aRotina completa (Visualizar/Incluir/Alterar/Excluir/Imprimir/Atualizar/Importar/Limpar). FPOS_BUSCA: early return se ZC1 ja e alias atual (evita MsSeek repositioning). FPOS_LIMPAR: guarda 1 registro (evita ARQVAZIO). GetArea/RestArea em todas funcoes com lookup.
- Padroes TReport salvos em Obsidian: TRGroup NAO existe no build 7.00.240223P. Usar SetHeaderSection(.T.) + PrintText(). Tamanho coluna = header text (nao dados). CP_QUANT numerico = nunca Val(). Colunas posicionadas sequencialmente.

### 29/06/2026
- Corrigido: Provider `opencode-zen` nao existia em auth.json — todos os modelos `opencode-zen/*` retornavam "Model not found"
- Corrigido: Modelos renomeados — `opencode-zen/deepseek-v4-flash-free` → `opencode-go/deepseek-v4-flash`,
  `opencode-zen/mimo-v2.5-free` → `opencode-go/mimo-v2.5`
- Motivo: `opencode-zen` requer `/connect` + API key separada; `opencode-go` ja esta autenticado e
  inclui ambos os modelos (DeepSeek V4 Flash $0.14/$0.28, MiMo-V2.5 $0.14/$0.28)
- Docs consultadas: https://opencode.ai/docs/go, https://opencode.ai/docs/zen, https://opencode.ai/docs/providers
- Atualizados: opencode.jsonc (global), image-analyzer.md, AGENTS.md (global/PAI/FILHO), README.md,
  verify-harness.ps1

### 22/06/2026
- Adicionado: Regra "Consultar skills antes de qualquer acao" (AGENTS.md regra 11, memory.md)
- Adicionado: Regra "Encoding uma unica vez por programa" (AGENTS.md regra 12, memory.md)

### 21/06/2026
- Corrigido: Pendencias item #1 (encoding) — `utf8-to-cp1252-conversion` agora existe como skill no PAI
- Corrigido: Pendencias item #3 (openspec) — pasta contem changes ativas/arquivadas, nao esta vazia
- Corrigido: Pendencias item #4 renumerado (antigo #5) — skills TOTVS engpro AGORA existem como loadable skills
- Corrigido: Nota no Ambiente de Desenvolvimento — encoding agora cita `utf8-to-cp1252-conversion`
- Corrigido: Referencia ao openspec \"recem-criada, vazia\" → \"changes ativas e arquivadas\"
- Adicionado: Secao Changelog para rastrear alteracoes neste arquivo

### 14/10/2026 — CADPOSIC busca Chave (diagnostico e fix)
- **Sintoma**: busca por "Codigo" (aba Chave) no CADPOSIC retorna 0 registros,
  mesmo com o codigo existindo na lista do browse. Filtro por Coluna funciona.
- **Comparacao SB1/MATA010**: aSeek do CADPOSIC estava ESTRUTURALMENTE identico
  ao padrao do produto ({titulo, {{campo,tipo,tam,dec,titulo,mascara}}, ordem, .T.}).
  MATA010 usa TamSX3 inline (seguro em tabela padrao); ZC1 e Z* (regra do projeto).
- **Fix aplicado** (`_PATCHES/PATCH_01/CADPOSIC.PRW` linhas 47-54): TamSX3()
  inline substituido por tamanhos literais (ZC1_ITEM=13, ZC1_DESCRI=50).
  Regra do projeto (memory.md linha 203): TamSx3/FWSizeFilial inline no array
  do SetSeek para tabelas Z* causa "array out of bounds".
  Arquivo verificado 100% ASCII. PENDENTE: recompilar no TDS.
- **TDN confirmou** (busca 14/10): estrutura aSeek documentada em
  "FWMBrowse SetSeek" ([n,1] titulo, [n,2,x] props do campo, [n,3] ordem,
  [n,4] exibe). Bug CONHECIDO do framework: "THREAD ERROR array out of
  bounds (5 of 3) on FWSEEK:CHANGEORDER(FWSEEK.PRW) line 277" — mesmo erro
  que a regra do projeto descreve. FWSeek tem bugs conhecidos de
  posicionamento de chave (corrigidos em builds posteriores).
- **Hipotese funil (III)**: na barra de pesquisa do FWSeek, o icote funil
  (III) alterna entre modo Chave (nao pressionado) e modo Coluna
  (pressionado). Se estiver pressionado, a busca ignora a selecao
  "Chave > Codigo" do dialogo e filtra por coluna. Usuario deve DESLIGAR
  o funil antes de testar a busca por Chave.
- **SIX ZC1 confirmada**: ordem 1 = ZC1_FILIAL+ZC1_ITEM, ordem 2 =
  ZC1_FILIAL+ZC1_DESCRI. Usuario rodou Atualizar base de dados.
- **PENDENTE**: (1) recompilar CADPOSIC.PRW; (2) testar com funil desligado
  e valor parcial; (3) se falhar, verificar indice fisico com
  `SELECT name, type_desc FROM sys.indexes WHERE object_id = OBJECT_ID('ZC1010')`
  (Change Query DESMARCADO); (4) FPOSPOSIC.PRW tambem pendente de compilacao.
