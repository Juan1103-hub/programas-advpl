# Modulo de Contabilidade (CTB)

## Visao Geral

O modulo de Contabilidade Gerencial (SIGACTB) do TOTVS Protheus e responsavel pelo controle e registro de todos os lancamentos contabeis da empresa. Ele centraliza a escrituracao contabil, gerando informacoes gerenciais e legais para a tomada de decisao e cumprimento das obrigacoes acessorias (SPED Contabil/ECD, ECF, LALUR). Integra-se com praticamente todos os modulos do Protheus, recebendo lancamentos automaticos (online ou offline) gerados a partir das operacoes de compras, faturamento, financeiro, estoque, fiscal, ativo fixo e folha de pagamento.

**Prefixo do modulo:** CTB
**Sigla do ambiente:** SIGACTB
**Prefixo das rotinas:** CTBA0xx (cadastros), CTBA1xx (processamentos), CTBA2xx (apuracoes), CTBR0xx (relatorios)

### Ciclo principal da contabilidade

```
Calendario Contabil → Plano de Contas → Lancamento Padrao → Lancamentos Contabeis (automaticos/manuais) → Conciliacao → Balancete → Apuracao de Resultado → DRE/Balanco → Fechamento Contabil
```

O modulo suporta contabilizacao online (lancamentos gerados automaticamente no momento da operacao) e offline (lancamentos gerados em lote sob demanda do usuario). A configuracao e feita por meio dos Lancamentos Padronizados (CT5), que definem as regras de debito, credito e valores para cada tipo de operacao.

---

## Tabelas Principais

### CT1 - Plano de Contas

Cadastro mestre das contas contabeis da empresa. Define a estrutura hierarquica do plano de contas com contas sinteticas (totalizadoras) e analiticas (que recebem lancamentos).

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| CT1_FILIAL | C | 2 | Filial |
| CT1_CONTA | C | 20 | Codigo da conta contabil |
| CT1_DESC01 | C | 40 | Descricao da conta (moeda 1) |
| CT1_CLASSE | C | 1 | Classe: 1=Sintetica, 2=Analitica |
| CT1_NORMAL | C | 1 | Natureza normal: 1=Devedora, 2=Credora |
| CT1_RES | C | 10 | Codigo reduzido |
| CT1_BLOQ | C | 1 | Bloqueio: 1=Bloqueada, 2=Ativa |
| CT1_DTBLIN | D | 8 | Data inicio bloqueio |
| CT1_DTBLFI | D | 8 | Data fim bloqueio |
| CT1_CTASUP | C | 20 | Conta superior (hierarquia) |
| CT1_HP | C | 3 | Historico padrao vinculado |
| CT1_ACITEM | C | 1 | Aceita item contabil: 1=Sim, 2=Nao |
| CT1_ACCUST | C | 1 | Aceita centro de custo: 1=Sim, 2=Nao |
| CT1_ACCLVL | C | 1 | Aceita classe de valor: 1=Sim, 2=Nao |
| CT1_CCOBRG | C | 1 | Centro de custo obrigatorio: 1=Sim, 2=Nao |
| CT1_ITOBRG | C | 1 | Item contabil obrigatorio: 1=Sim, 2=Nao |
| CT1_CLOBRG | C | 1 | Classe de valor obrigatoria: 1=Sim, 2=Nao |
| CT1_DTEXIS | D | 8 | Data inicio existencia |
| CT1_DTEXSF | D | 8 | Data fim existencia |
| CT1_CTALP | C | 20 | Conta de lucros/perdas (apuracao) |
| CT1_CTAPON | C | 20 | Conta ponte lucros/perdas |
| CT1_NATCTA | C | 2 | Natureza da conta (regulamentar) |
| CT1_NTSPED | C | 2 | Natureza da conta SPED |
| CT1_SPEDST | C | 1 | Indicador sintetica SPED |
| CT1_LALUR | C | 1 | Tipo conta LALUR (0-5) |
| CT1_TPLALU | C | 2 | Classificacao LALUR |
| CT1_CTLALU | C | 20 | Conta LALUR vinculada |
| CT1_RATEIO | C | 6 | Codigo de rateio |
| CT1_ESTOUR | C | 1 | Conta estourada/invertida: 1=Sim, 2=Nao |
| CT1_BOOK | C | 20 | Configuracao de livros |
| CT1_GRUPO | C | 8 | Grupo contabil |
| CT1_AGLSLD | C | 1 | Aglutina saldos: 1=Sim, 2=Nao |
| CT1_CC | C | 9 | Centro de custo padrao |
| CT1_CTAVM | C | 20 | Conta de variacao monetaria |
| CT1_CTARED | C | 20 | Conta redutora de variacao |
| CT1_MOEDVM | C | 2 | Moeda forte para variacao |

**Indices principais:**
- Ordem 1: `CT1_FILIAL + CT1_CONTA`
- Ordem 2: `CT1_FILIAL + CT1_RES`

---

### CT2 - Lancamentos Contabeis

Tabela central do modulo, armazena todos os lancamentos contabeis da empresa. Cada registro representa uma linha de lancamento (debito ou credito). Os lancamentos podem ser gerados manualmente (CTBA102) ou automaticamente pela integracao com outros modulos (via Lancamento Padrao - CT5).

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| CT2_FILIAL | C | 2 | Filial |
| CT2_DATA | D | 8 | Data do lancamento |
| CT2_LOTE | C | 6 | Numero do lote |
| CT2_SBLOTE | C | 3 | Sub-lote |
| CT2_DOC | C | 6 | Numero do documento |
| CT2_LINHA | C | 3 | Linha do lancamento |
| CT2_DC | C | 1 | Tipo: 1=Debito, 2=Credito, 3=Partida dobrada |
| CT2_DEBITO | C | 20 | Conta de debito |
| CT2_CREDIT | C | 20 | Conta de credito |
| CT2_VALOR | N | 14,2 | Valor do lancamento (moeda 1) |
| CT2_VALR02 | N | 14,2 | Valor na moeda 2 |
| CT2_VALR03 | N | 14,2 | Valor na moeda 3 |
| CT2_VALR04 | N | 14,2 | Valor na moeda 4 |
| CT2_VALR05 | N | 14,2 | Valor na moeda 5 |
| CT2_HP | C | 3 | Historico padrao |
| CT2_HIST | C | 40 | Historico do lancamento |
| CT2_CCD | C | 9 | Centro de custo debito |
| CT2_CCC | C | 9 | Centro de custo credito |
| CT2_ITEMD | C | 9 | Item contabil debito |
| CT2_ITEMC | C | 9 | Item contabil credito |
| CT2_CLVLDB | C | 9 | Classe de valor debito |
| CT2_CLVLCR | C | 9 | Classe de valor credito |
| CT2_MOEDLC | C | 2 | Moeda do lancamento (padrao "01") |
| CT2_TPSALD | C | 1 | Tipo de saldo |
| CT2_LP | C | 3 | Codigo do lancamento padrao origem |
| CT2_MANUAL | C | 1 | Lancamento manual (S/N) |
| CT2_ORIGEM | C | 100 | Origem do lancamento |
| CT2_ROTINA | C | 10 | Rotina geradora |
| CT2_EMPORI | C | 2 | Empresa de origem |
| CT2_FILORI | C | 2 | Filial de origem |
| CT2_INTERC | C | 1 | Indicador intercompany |
| CT2_AGLUT | C | 1 | Lancamento aglutinado |
| CT2_SEQUEN | C | 10 | Vinculo com CTK (prova contabil) |
| CT2_SEQLAN | C | 3 | Sequencia do lancamento |
| CT2_SEQHIS | C | 3 | Sequencia do historico |
| CT2_DTVENC | D | 8 | Data de vencimento |
| CT2_DTLP | D | 8 | Data apuracao lucros/perdas |
| CT2_CODCLI | C | 6 | Codigo do cliente |
| CT2_CODFOR | C | 6 | Codigo do fornecedor |
| CT2_CODPAR | C | 6 | Codigo do participante |
| CT2_CONFST | C | 1 | Status de verificacao |
| CT2_USRCNF | C | 15 | Usuario que verificou |
| CT2_DTCONF | D | 8 | Data da verificacao |
| CT2_ESTCAN | C | 1 | Indicador de estorno/cancelamento |
| CT2_IDCONC | C | 23 | Identificador de conciliacao |
| CT2_INCONS | C | 1 | Indicador de inconsistencia contabil |
| CT2_PROCES | C | 32 | Codigo do processo contabil |
| CT2_SEQIDX | C | 5 | Sequencia da chave unica |

**Indices principais:**
- Ordem 1: `CT2_FILIAL + DTOS(CT2_DATA) + CT2_LOTE + CT2_SBLOTE + CT2_DOC + CT2_LINHA + CT2_MOEDLC`
- Ordem 2: `CT2_FILIAL + CT2_DEBITO + DTOS(CT2_DATA)`
- Ordem 3: `CT2_FILIAL + CT2_CREDIT + DTOS(CT2_DATA)`

---

### CT5 - Lancamento Padrao

Define as regras de contabilizacao automatica utilizadas por todos os modulos do Protheus. Cada lancamento padrao (LP) possui uma ou mais sequencias (linhas) que determinam conta de debito, credito, valor e historico atraves de expressoes ADVPL que referenciam campos das tabelas de origem.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| CT5_FILIAL | C | 2 | Filial |
| CT5_LANPAD | C | 3 | Codigo do lancamento padrao |
| CT5_SEQUEN | C | 3 | Sequencia (linha do LP) |
| CT5_DESC | C | 40 | Descricao do lancamento padrao |
| CT5_STATUS | C | 1 | Status: Ativo/Inativo |
| CT5_DC | C | 1 | Tipo: Debito/Credito/Partida dobrada/Historico |
| CT5_DEBITO | C | 200 | Conta de debito (expressao ADVPL) |
| CT5_CREDIT | C | 200 | Conta de credito (expressao ADVPL) |
| CT5_VLR01 | C | 200 | Valor na moeda 1 (expressao ADVPL) |
| CT5_VLR02 | C | 200 | Valor na moeda 2 |
| CT5_VLR03 | C | 200 | Valor na moeda 3 |
| CT5_VLR04 | C | 200 | Valor na moeda 4 |
| CT5_VLR05 | C | 200 | Valor na moeda 5 |
| CT5_HIST | C | 200 | Historico (expressao ADVPL) |
| CT5_HAGLUT | C | 200 | Historico de aglutinacao |
| CT5_CCD | C | 200 | Centro de custo debito (expressao) |
| CT5_CCC | C | 200 | Centro de custo credito (expressao) |
| CT5_ITEMD | C | 200 | Item contabil debito (expressao) |
| CT5_ITEMC | C | 200 | Item contabil credito (expressao) |
| CT5_CLVLDB | C | 200 | Classe de valor debito (expressao) |
| CT5_CLVLCR | C | 200 | Classe de valor credito (expressao) |
| CT5_MOEDLC | C | 2 | Moeda do lancamento |
| CT5_SBLOTE | C | 3 | Sub-lote |
| CT5_TPSALD | C | 1 | Tipo de saldo |
| CT5_ORIGEM | C | 100 | Identificador da origem |
| CT5_TABORI | C | 100 | Nome da tabela de origem |
| CT5_RECORI | C | 100 | Funcao para record da tabela origem |
| CT5_ROTRAS | C | 60 | Rotina de visualizacao do rastreamento |
| CT5_INTERC | C | 1 | Lancamento intercompany |
| CT5_MOEDAS | C | 5 | Indicador de moedas utilizadas |
| CT5_DTVENC | C | 200 | Data de vencimento (expressao) |
| CT5_DIACTB | C | 50 | Codigo do diario contabil |
| CT5_OBS | M | 255 | Observacoes |

**Indices principais:**
- Ordem 1: `CT5_FILIAL + CT5_LANPAD + CT5_SEQUEN`

---

### CTT - Centro de Custo

Cadastro dos centros de custo da empresa. Os centros de custo sao entidades contabeis que permitem classificar receitas e despesas por departamento, area ou projeto. Podem ser sinteticos (totalizadores) ou analiticos (recebem lancamentos).

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| CTT_FILIAL | C | 2 | Filial |
| CTT_CUSTO | C | 9 | Codigo do centro de custo |
| CTT_DESC01 | C | 40 | Descricao (moeda 1) |
| CTT_CLASSE | C | 1 | Classe: 1=Sintetica, 2=Analitica |
| CTT_NORMAL | C | 1 | Classificacao: 1=Despesa, 2=Receita |
| CTT_BLOQ | C | 1 | Bloqueio: 1=Bloqueado, 2=Ativo |
| CTT_DTBLIN | D | 8 | Data inicio bloqueio |
| CTT_DTBLFI | D | 8 | Data fim bloqueio |
| CTT_DTEXIS | D | 8 | Data inicio existencia |
| CTT_DTEXSF | D | 8 | Data fim existencia |
| CTT_CCSUP | C | 9 | Centro de custo superior (hierarquia) |
| CTT_CCLP | C | 9 | Centro de custo de apuracao lucros/perdas |
| CTT_CCPON | C | 9 | Centro de custo ponte para resultado |
| CTT_RES | C | 10 | Codigo reduzido |
| CTT_BOOK | C | 20 | Configuracao de livros |
| CTT_STATUS | C | 1 | Status: Ativo/Inativo |
| CTT_ACITEM | C | 1 | Aceita item contabil |
| CTT_ACCLVL | C | 1 | Aceita classe de valor |
| CTT_ITOBRG | C | 1 | Item contabil obrigatorio |
| CTT_CLOBRG | C | 1 | Classe de valor obrigatoria |
| CTT_CCVM | C | 9 | Centro de custo variacao monetaria |
| CTT_CCRED | C | 9 | Centro de custo redutor |
| CTT_LOCAL | C | 2 | Codigo do armazem |
| CTT_FILMAT | C | 2 | Filial do responsavel |
| CTT_MAT | C | 6 | Matricula do responsavel |

**Indices principais:**
- Ordem 1: `CTT_FILIAL + CTT_CUSTO`
- Ordem 2: `CTT_FILIAL + CTT_RES`

---

### CTH - Classe de Valor

Cadastro das classes de valor, que representam uma classificacao adicional para os lancamentos contabeis alem da conta contabil e centro de custo. Permitem analisar receitas e despesas sob diferentes perspectivas gerenciais.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| CTH_FILIAL | C | 2 | Filial |
| CTH_CLVL | C | 9 | Codigo da classe de valor |
| CTH_DESC01 | C | 40 | Descricao (moeda 1) |
| CTH_CLASSE | C | 1 | Classe: 1=Sintetica, 2=Analitica |
| CTH_NORMAL | C | 1 | Classificacao: 0=Nenhuma, 1=Despesa, 2=Receita |
| CTH_BLOQ | C | 1 | Bloqueio: 1=Bloqueada, 2=Ativa |
| CTH_DTBLIN | D | 8 | Data inicio bloqueio |
| CTH_DTBLFI | D | 8 | Data fim bloqueio |
| CTH_DTEXIS | D | 8 | Data inicio existencia |
| CTH_DTEXSF | D | 8 | Data fim existencia |
| CTH_CLSUP | C | 9 | Classe de valor superior (hierarquia) |
| CTH_CLVLLP | C | 9 | Classe de valor apuracao resultado |
| CTH_CLPON | C | 9 | Classe de valor ponte lucros/perdas |
| CTH_RES | C | 10 | Codigo reduzido |
| CTH_BOOK | C | 20 | Configuracao de livros |
| CTH_CLVM | C | 9 | Classe de valor variacao monetaria |
| CTH_CLRED | C | 9 | Classe de valor redutora |

**Indices principais:**
- Ordem 1: `CTH_FILIAL + CTH_CLVL`
- Ordem 2: `CTH_FILIAL + CTH_RES`

---

### CT8 - Historico Padrao

Cadastro dos historicos padrao que podem ser vinculados aos lancamentos contabeis para padronizar a descricao textual dos lancamentos.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| CT8_FILIAL | C | 2 | Filial |
| CT8_HIST | C | 3 | Codigo do historico padrao |
| CT8_DESC | C | 48 | Descricao do historico |
| CT8_IDENT | C | 1 | Identificador do registro |
| CT8_SEQUEN | C | 6 | Sequencia do historico inteligente |

**Indices principais:**
- Ordem 1: `CT8_FILIAL + CT8_HIST + CT8_SEQUEN`

---

### CTG - Calendario Contabil

Define os periodos contabeis do exercicio fiscal. Controla a abertura, fechamento e bloqueio de periodos para lancamentos.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| CTG_FILIAL | C | 2 | Filial |
| CTG_CALEND | C | 3 | Codigo do calendario |
| CTG_PERIOD | C | 2 | Periodo (01 a 12) |
| CTG_DTINI | D | 8 | Data inicio do periodo |
| CTG_DTFIM | D | 8 | Data fim do periodo |
| CTG_STATUS | C | 1 | Status: Aberto/Fechado/Bloqueado |
| CTG_DESC | C | 40 | Descricao do calendario |

---

### CV1 - Itens do Orcamento Contabil

Armazena os valores orcados por conta contabil, centro de custo e periodo, permitindo a comparacao entre orcado e realizado nos relatorios contabeis.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| CV1_FILIAL | C | 2 | Filial |
| CV1_ORCMTO | C | 3 | Codigo do orcamento |
| CV1_CALEND | C | 3 | Calendario contabil |
| CV1_MOEDA | C | 2 | Moeda |
| CV1_REVISA | C | 3 | Revisao do orcamento |
| CV1_SEQUEN | C | 3 | Sequencia |
| CV1_PERIOD | C | 2 | Periodo |

**Indices principais:**
- Ordem 1: `CV1_FILIAL + CV1_ORCMTO + CV1_CALEND + CV1_MOEDA + CV1_REVISA + CV1_SEQUEN + CV1_PERIOD`

---

### CTK - Prova Contabil (Arquivo Comprovante)

Armazena os dados complementares dos lancamentos contabeis para fins de rastreabilidade. Vinculada a CT2 pelo campo CT2_SEQUEN.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| CTK_FILIAL | C | 2 | Filial |
| CTK_SEQ | C | 10 | Sequencia (vinculo com CT2_SEQUEN) |
| CTK_DATA | D | 8 | Data do lancamento |
| CTK_LOTE | C | 6 | Numero do lote |
| CTK_SBLOTE | C | 3 | Sub-lote |
| CTK_DOC | C | 6 | Documento |
| CTK_TPSALD | C | 1 | Tipo de saldo |

---

### CV3 - Rastreamento Contabil

Permite rastrear a origem dos lancamentos contabeis, identificando qual registro e modulo gerou cada lancamento na CT2.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| CV3_FILIAL | C | 2 | Filial |
| CV3_TABORI | C | 3 | Tabela de origem (ex: SD1, SE2) |
| CV3_RECORI | C | 10 | RecNo do registro de origem |
| CV3_SEQCTK | C | 10 | Sequencia do comprovante (CTK) |
| CV3_DATA | D | 8 | Data do lancamento |

---

## Rotinas Principais

### CTBA010 - Calendario Contabil

**O que faz:** Define os periodos contabeis do exercicio fiscal. Permite incluir, alterar e excluir calendarios, bem como abrir, fechar e bloquear periodos. Inclui funcionalidade de "Bloqueio por Processo" que permite bloquear movimentacoes de outros modulos durante o fechamento contabil.

**Tabelas envolvidas:**
- CTG (escrita) - Calendario Contabil
- CTE (escrita) - Moeda x Calendario
- CQD (escrita) - Bloqueio do Calendario Contabil

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_CTBPOFF | Habilita bloqueio por processo |

---

### CTBA020 - Plano de Contas (Conta Contabil)

**O que faz:** Cadastro e manutencao do plano de contas da empresa. Permite incluir, alterar, excluir, bloquear e visualizar contas contabeis. As contas podem ser sinteticas (totalizadoras) ou analiticas (recebem lancamentos). Suporta importacao de contas via arquivo TXT (acelerador MILE) e integracao via rotina automatica.

**Tabelas envolvidas:**
- CT1 (escrita) - Plano de Contas
- CVD (escrita) - Detalhe do Plano de Contas
- CVN (escrita) - Natureza do Plano de Contas

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_MASCARA | Mascara contabil (formato da conta, ex: "??.???.??.???") |
| MV_CTASUP | Geracao automatica da conta superior |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| CTA020TOK | Validacao customizada na confirmacao do cadastro de conta |
| CT020ADEL | Verificacao de integridade referencial antes da exclusao |
| CT020GRE | Execucao apos exclusao da conta contabil |

---

### CTBA030 - Centro de Custo

**O que faz:** Cadastro e manutencao dos centros de custo. Permite inclusao, alteracao, exclusao e visualizacao. Centros de custo podem ser sinteticos (totalizadores) ou analiticos (recebem lancamentos). Suporta visualizacao em arvore hierarquica e integracao via EAI.

**Tabelas envolvidas:**
- CTT (escrita) - Centro de Custo
- CT1 (leitura) - Plano de Contas (validacao)

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_CCSUP | Geracao automatica do centro de custo superior |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| CT030ADEL | Verifica integridade referencial do CC antes da exclusao |
| CT030GRE | Executado apos exclusao do centro de custo |
| CTA030TOK | Validacao customizada na confirmacao do cadastro |
| CTB030VLD | Valida confirmacao na inclusao e alteracao |
| CT030BUT | Customiza botoes na rotina de cadastro |

---

### CTBA060 - Classe de Valor

**O que faz:** Cadastro e manutencao das classes de valor. Entidade contabil complementar que permite classificar lancamentos sob perspectivas gerenciais adicionais. Suporta integracao via mensagem unica (EAI).

**Tabelas envolvidas:**
- CTH (escrita) - Classe de Valor

---

### CTBA080 - Lancamento Padrao

**O que faz:** Cadastro e manutencao dos lancamentos padronizados (LP). Os LPs sao o elo entre os diversos modulos do Protheus e a Contabilidade Gerencial, definindo regras automaticas de contabilizacao. Cada LP contem expressoes ADVPL que determinam contas de debito, credito, valores e historicos a partir dos dados da tabela de origem.

**Tabelas envolvidas:**
- CT5 (escrita) - Lancamento Padrao
- CT1 (leitura) - Plano de Contas (validacao das contas)

**Fontes relacionados:**
| Fonte | Descricao |
|-------|-----------|
| CTBA080a | Disponibiliza o LP para o modulo de origem (funcao ChkCVA) |
| CTBA086 | Visualizacao em arvore do LP |
| CTBXCTB | Determina a tabela de origem do lancamento (funcao RetRecnoLP) |
| CTBA090 | Cadastro de relacionamento para rastreamento |

**Tipos de contabilizacao:**
| Tipo | Descricao |
|------|-----------|
| Online | Lancamentos gerados automaticamente no momento da operacao |
| Offline | Lancamentos gerados em lote quando o usuario solicita via menu Miscelanea > Contabilizacao Off-Line |

---

### CTBA102 - Lancamentos Contabeis Manuais

**O que faz:** Permite incluir, alterar, excluir, copiar e estornar lancamentos contabeis manuais. Cada lancamento e composto por data, lote, sub-lote, documento e linhas de debito/credito. Tambem utilizado como rotina automatica para inclusao de lancamentos via codigo ADVPL.

**Tabelas envolvidas:**
- CT2 (escrita) - Lancamentos Contabeis
- CTK (escrita) - Prova Contabil
- CV3 (escrita) - Rastreamento Contabil
- CT1 (leitura) - Plano de Contas (validacao)
- CTT (leitura) - Centro de Custo (validacao)
- CTH (leitura) - Classe de Valor (validacao)
- CTG (leitura) - Calendario Contabil (validacao de periodo)

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_ALTLCTO | Permite alteracao de linhas no lancamento (S/N) |
| MV_LOTECON | Geracao de numero de lote: T=Tabela 09, U=Ultimo+1 |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| CT102VLENT | Validacao das entidades contabeis no momento da gravacao |
| Ct102Carr | Manipulacao da leitura do TMP na CTBA102 |
| CT102MNU | Customiza menu da rotina |
| CT102INC | Executado na inclusao de lancamentos |

---

### CTBA105 - Contabilizacao Online (Integracao Contabil)

**O que faz:** Rotina de integracao contabil utilizada por todos os modulos do Protheus para gerar lancamentos contabeis online. Processa os Lancamentos Padrao (CT5) associados a operacao e gera os registros na CT2. Utilizada internamente pelas rotinas de outros modulos (Financeiro, Compras, Faturamento, Estoque, etc.).

**Tabelas envolvidas:**
- CT2 (escrita) - Lancamentos Contabeis
- CTK (escrita) - Prova Contabil
- CV3 (escrita) - Rastreamento Contabil
- CT5 (leitura) - Lancamento Padrao
- CT1 (leitura) - Plano de Contas

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_CT105MS | Exibe mensagem na integracao contabil (S/N) |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| CT105VLENT | Validacao das entidades contabeis na gravacao |
| GRVCT3 | Manipulacao apos gravacao (performance) |
| GRVCT4 | Manipulacao apos gravacao (performance) |
| GRVCT7 | Manipulacao apos gravacao (performance) |
| GRVCTI | Manipulacao apos gravacao (performance) |

---

### CTBA211 - Apuracao de Resultado

**O que faz:** Realiza o levantamento e cruzamento dos valores de receitas e despesas em um determinado periodo para obter o resultado contabil (lucro ou prejuizo). Transfere os saldos das contas de resultado para a conta de Lucros/Perdas (CT1_CTALP) mediante lancamentos automaticos de encerramento. A rotina CTBA210 foi descontinuada em favor da CTBA211.

**Tabelas envolvidas:**
- CT2 (escrita) - Lancamentos Contabeis (lancamentos de apuracao)
- CT1 (leitura) - Plano de Contas (identifica contas de resultado)
- CTT (leitura) - Centro de Custo (apuracao por CC)
- CTH (leitura) - Classe de Valor (apuracao por CLVL)
- CQ0/CQ1 (leitura) - Saldos Contabeis

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|

---

### CTBR040 - Balancete

**O que faz:** Emite o relatorio de balancete contabil (Modelo 1), exibindo os saldos das contas contabeis em um determinado periodo. Apresenta saldo anterior, movimentacao a debito e credito, e saldo atual. Permite exportacao para Excel e impressao com margens customizaveis.

**Tabelas envolvidas:**
- CQ0/CQ1 (leitura) - Saldos Contabeis
- CT1 (leitura) - Plano de Contas
- CT2 (leitura) - Lancamentos Contabeis

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_TPVALOR | Formato de numeros no relatorio |
| MV_CTBPOFF | Customizacao de relatorios contabeis |

---

### CTBR400 - Razao Contabil

**O que faz:** Emite o relatorio de razao contabil, que apresenta todos os lancamentos de uma determinada conta contabil em um periodo, com saldo acumulado. E um dos relatorios oficiais exigidos pela legislacao brasileira.

**Tabelas envolvidas:**
- CT2 (leitura) - Lancamentos Contabeis
- CT1 (leitura) - Plano de Contas
- CTT (leitura) - Centro de Custo

---

### CTBR110 - Diario Contabil

**O que faz:** Emite o relatorio do diario contabil, que apresenta todos os lancamentos em ordem cronologica. E um dos relatorios oficiais exigidos pela legislacao brasileira, junto com o Razao e o Balancete.

**Tabelas envolvidas:**
- CT2 (leitura) - Lancamentos Contabeis
- CT1 (leitura) - Plano de Contas

---

### CTBA940 - Conciliador Backoffice

**O que faz:** Plataforma unificada de conciliacao contabil e financeira. Permite confrontar os lancamentos contabeis (CT2) com os registros dos modulos de origem (Financeiro, Compras, Faturamento, Estoque), identificando divergencias. Suporta conciliacao bancaria manual e automatica.

**Tabelas envolvidas:**
- CT2 (leitura) - Lancamentos Contabeis
- SE2 (leitura) - Titulos a Pagar
- SE1 (leitura) - Titulos a Receber
- SD1 (leitura) - Itens NF Entrada
- SD2 (leitura) - Itens NF Saida

---

### CTBA960 - Fechamento Contabil

**O que faz:** Controla o processo de fechamento contabil do periodo. Permite monitorar o status dos lancamentos de todos os modulos integrados, definir responsaveis por modulo/tabela, enviar notificacoes por e-mail em caso de atraso, e bloquear calendarios e processos contabeis do periodo selecionado ao final do fechamento.

**Tabelas envolvidas:**
- CTG (escrita) - Calendario Contabil (bloqueio do periodo)
- CQD (escrita) - Bloqueio do Calendario
- CT2 (leitura) - Lancamentos Contabeis (verificacao de completude)

---

### CTBS001 - SPED Contabil (ECD)

**O que faz:** Gera o arquivo da Escrituracao Contabil Digital (ECD) para entrega ao SPED. Requer calendario contabil com 12 periodos (ou periodos especiais), plano de contas referencial e contas com natureza SPED preenchida.

**Tabelas envolvidas:**
- CT1 (leitura) - Plano de Contas
- CT2 (leitura) - Lancamentos Contabeis
- CTG (leitura) - Calendario Contabil
- CTT (leitura) - Centro de Custo

---

## Processos de Negocio

### Fluxo Completo da Contabilidade

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  1. Calendario   │────>│  2. Plano de     │────>│  3. Entidades    │
│  Contabil        │     │  Contas          │     │  Contabeis       │
│  CTBA010 / CTG   │     │  CTBA020 / CT1   │     │  CTT, CTH, CTD   │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                          │
┌─────────────────┐     ┌─────────────────┐     ┌────────v────────┐
│  6. Balancete    │<────│  5. Conciliacao  │<────│  4. Lancamentos  │
│  e Razao         │     │                  │     │  Contabeis        │
│  CTBR040/CTBR400 │     │  CTBA940         │     │  CTBA102/CTBA105  │
└────────┬────────┘     └─────────────────┘     └─────────────────┘
         │
┌────────v────────┐     ┌─────────────────┐     ┌─────────────────┐
│  7. Apuracao de  │────>│  8. DRE / Balanco│────>│  9. Fechamento   │
│  Resultado       │     │  Patrimonial     │     │  e SPED (ECD)    │
│  CTBA211         │     │  CTBR040         │     │  CTBA960/CTBS001 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

#### Passo 1: Calendario Contabil (CTBA010)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | CTBA010 |
| **Tabelas** | CTG (escrita), CTE (escrita) |
| **O que acontece** | Definicao dos periodos contabeis do exercicio fiscal (normalmente 12 periodos mensais). O calendario controla quais periodos estao abertos para lancamentos. Deve ser criado antes de qualquer operacao contabil. |
| **Resultado** | Calendario com periodos definidos (datas inicio/fim) e status inicial "Aberto" |

#### Passo 2: Plano de Contas (CTBA020)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | CTBA020 |
| **Tabelas** | CT1 (escrita), CVD (escrita), CVN (escrita) |
| **O que acontece** | Cadastro da estrutura hierarquica de contas contabeis. Contas sinteticas agrupam contas analiticas. Cada conta analitica deve ter definida sua natureza (devedora/credora), se aceita centro de custo, item contabil e classe de valor, e a conta de lucros/perdas para apuracao de resultado. |
| **Resultado** | Plano de contas estruturado com contas sinteticas e analiticas |

#### Passo 3: Entidades Contabeis (CTBA030, CTBA060)

| Aspecto | Detalhe |
|---------|---------|
| **Rotinas** | CTBA030 (Centro de Custo), CTBA060 (Classe de Valor) |
| **Tabelas** | CTT (escrita), CTH (escrita) |
| **O que acontece** | Cadastro das entidades complementares: centros de custo por departamento/area e classes de valor para classificacao gerencial. Ambas podem ser sinteticas ou analiticas. |
| **Resultado** | Entidades contabeis disponiveis para uso nos lancamentos |

#### Passo 4: Lancamentos Contabeis (CTBA102 / CTBA105)

| Aspecto | Detalhe |
|---------|---------|
| **Rotinas** | CTBA102 (manual), CTBA105 (integracao online), Contabilizacao Off-Line (lote) |
| **Tabelas** | CT2 (escrita), CTK (escrita), CV3 (escrita) |
| **O que acontece** | Os lancamentos sao gerados de duas formas: (a) manualmente pelo usuario via CTBA102, informando data, contas, valores e historico; (b) automaticamente pela integracao com outros modulos (Compras, Financeiro, Faturamento, Estoque, Fiscal) via Lancamento Padrao (CT5). O sistema valida periodo aberto no calendario, contas existentes e desbloqueadas, e entidades obrigatorias. |
| **Resultado** | Registros na CT2 com debitos e creditos balanceados |

#### Passo 5: Conciliacao (CTBA940)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | CTBA940 |
| **Tabelas** | CT2 (leitura), tabelas de origem dos modulos (leitura) |
| **O que acontece** | Confronto entre os lancamentos contabeis e os registros de origem para identificar inconsistencias. Verifica se todos os documentos foram contabilizados e se os valores conferem. |
| **Resultado** | Relatorio de divergencias e status de conciliacao |

#### Passo 6: Balancete e Razao (CTBR040 / CTBR400)

| Aspecto | Detalhe |
|---------|---------|
| **Rotinas** | CTBR040 (Balancete), CTBR400 (Razao), CTBR110 (Diario) |
| **Tabelas** | CT2 (leitura), CQ0/CQ1 (leitura), CT1 (leitura) |
| **O que acontece** | Emissao dos relatorios contabeis oficiais. O Balancete apresenta saldos por conta. O Razao detalha os lancamentos de cada conta. O Diario lista todos os lancamentos cronologicamente. |
| **Resultado** | Relatorios contabeis para analise e cumprimento legal |

#### Passo 7: Apuracao de Resultado (CTBA211)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | CTBA211 |
| **Tabelas** | CT2 (escrita), CT1 (leitura), CQ0/CQ1 (leitura) |
| **O que acontece** | Levantamento dos saldos das contas de receita e despesa, gerando lancamentos de encerramento que transferem esses saldos para a conta de Lucros e Perdas (CT1_CTALP). As contas ponte (CT1_CTAPON) sao utilizadas como intermediarias. Pode ser executada por conta, centro de custo e classe de valor. |
| **Resultado** | Contas de resultado zeradas; lucro ou prejuizo apurado na conta de L/P |

#### Passo 8: DRE e Balanco Patrimonial

| Aspecto | Detalhe |
|---------|---------|
| **Rotinas** | CTBR040 (Balancete apos apuracao), relatorios customizados |
| **O que acontece** | Apos a apuracao de resultado, o Balancete reflete o Balanco Patrimonial (contas patrimoniais) e a DRE pode ser gerada com base nos lancamentos de apuracao. |
| **Resultado** | Demonstracoes contabeis completas do exercicio |

#### Passo 9: Fechamento Contabil e SPED (CTBA960 / CTBS001)

| Aspecto | Detalhe |
|---------|---------|
| **Rotinas** | CTBA960 (Fechamento), CTBS001 (ECD/SPED) |
| **Tabelas** | CTG (escrita - bloqueio), CT2 (leitura), CT1 (leitura) |
| **O que acontece** | Apos verificacao de completude, o periodo e fechado/bloqueado no calendario contabil, impedindo novos lancamentos. O arquivo da ECD (SPED Contabil) e gerado para entrega a Receita Federal. |
| **Resultado** | Periodo fechado; arquivo ECD gerado |

---

## Regras de Negocio

### Campos obrigatorios por rotina

**Plano de Contas (CTBA020 - CT1):**
- CT1_CONTA (Codigo da conta)
- CT1_DESC01 (Descricao)
- CT1_CLASSE (Sintetica/Analitica)
- CT1_NORMAL (Natureza: Devedora/Credora)

**Centro de Custo (CTBA030 - CTT):**
- CTT_CUSTO (Codigo do centro de custo)
- CTT_DESC01 (Descricao)
- CTT_CLASSE (Sintetica/Analitica)

**Lancamento Contabil Manual (CTBA102 - CT2):**
- CT2_DATA (Data do lancamento)
- CT2_LOTE (Lote)
- CT2_SBLOTE (Sub-lote)
- CT2_DOC (Documento)
- CT2_DC (Tipo: Debito/Credito/Partida dobrada)
- CT2_DEBITO ou CT2_CREDIT (Conta contabil)
- CT2_VALOR (Valor)
- CT2_HIST (Historico)

### Validacoes principais

| Validacao | Descricao |
|-----------|-----------|
| Periodo contabil | O lancamento so e aceito se a data estiver dentro de um periodo aberto no calendario contabil (CTG_STATUS = "Aberto") |
| Conta existente | A conta de debito/credito deve existir na CT1 e nao estar bloqueada (CT1_BLOQ <> "1") |
| Conta analitica | Somente contas analiticas (CT1_CLASSE = "2") podem receber lancamentos |
| Centro de custo | Se a conta exige CC (CT1_CCOBRG = "1"), o campo CT2_CCD/CT2_CCC e obrigatorio e deve existir na CTT |
| Classe de valor | Se a conta exige CLVL (CT1_CLOBRG = "1"), o campo CT2_CLVLDB/CT2_CLVLCR e obrigatorio e deve existir na CTH |
| Item contabil | Se a conta exige item (CT1_ITOBRG = "1"), o campo CT2_ITEMD/CT2_ITEMC e obrigatorio |
| Equilibrio | Em lancamento de partida dobrada, o total de debitos deve ser igual ao total de creditos |
| Mascara contabil | O codigo da conta deve respeitar a mascara definida em MV_MASCARA |
| Data existencia | A data do lancamento deve estar dentro do periodo de existencia da conta (CT1_DTEXIS a CT1_DTEXSF) |
| Entidade bloqueada | Centro de custo bloqueado (CTT_BLOQ = "1") ou classe de valor bloqueada (CTH_BLOQ = "1") nao aceita lancamentos |
| Conta invertida | Se CT1_ESTOUR = "1", a conta aceita saldo invertido (devedora com saldo credor ou vice-versa) |

### Gatilhos SX7 relevantes

| Campo origem | Campo destino | Regra | Tabela lookup |
|-------------|---------------|-------|---------------|
| CT2_DEBITO | CT2_DCD | Digito verificador modulo 11 | - |
| CT2_CREDIT | CT2_DCC | Digito verificador modulo 11 | - |
| CT2_HP | CT2_HIST | CT8->CT8_DESC (historico padrao) | CT8 |
| CT1_CONTA | CT1_CTASUP | Conta superior pela mascara | - |
| CT1_CONTA | CT1_DC | Digito verificador modulo 11 | - |

### Pontos de entrada mais utilizados no modulo

| Ponto de Entrada | Rotina | Descricao |
|------------------|--------|-----------|
| CT102VLENT | CTBA102/CTBA105 | Valida entidades contabeis na gravacao do lancamento |
| Ct102Carr | CTBA102 | Manipula leitura do temporario na rotina de lancamento |
| CT102MNU | CTBA102 | Customiza menu da rotina de lancamentos manuais |
| CT105VLENT | CTBA105 | Valida entidades na integracao contabil online |
| GRVCT3 | CTBA102/CTBA105 | Manipula gravacao para aumento de performance |
| GRVCT4 | CTBA102/CTBA105 | Manipula gravacao para aumento de performance |
| GRVCT7 | CTBA102/CTBA105 | Manipula gravacao para aumento de performance |
| GRVCTI | CTBA102/CTBA105 | Manipula gravacao para aumento de performance |
| CTA020TOK | CTBA020 | Validacao customizada no cadastro de conta contabil |
| CT020ADEL | CTBA020 | Verifica integridade referencial antes de excluir conta |
| CT030ADEL | CTBA030 | Verifica integridade referencial antes de excluir CC |
| CTA030TOK | CTBA030 | Validacao customizada no cadastro de centro de custo |
| CTB030VLD | CTBA030 | Valida confirmacao na inclusao e alteracao de CC |
| CT030BUT | CTBA030 | Customiza botoes no cadastro de centro de custo |

---

## Integracoes

### Compras → Contabilidade

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na classificacao do Documento de Entrada (MATA103) |
| **O que acontece** | Gera lancamentos contabeis na CT2, debitando contas de estoque/despesa e creditando contas de fornecedores/impostos, conforme Lancamento Padrao (CT5) configurado na TES |
| **Lancamentos Padrao** | LPs configurados na TES do documento de entrada |
| **Tabelas afetadas** | CT2, CTK, CV3 |

### Faturamento → Contabilidade

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na emissao da Nota Fiscal de Saida (MATA461/MATA462) |
| **O que acontece** | Gera lancamentos contabeis para reconhecimento de receita, custo da mercadoria vendida (CMV), impostos sobre vendas e contas a receber, conforme LPs configurados na TES de saida |
| **Lancamentos Padrao** | LPs do faturamento (ex: LP 500 series) |
| **Tabelas afetadas** | CT2, CTK, CV3 |

### Financeiro → Contabilidade

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na baixa de titulos a pagar (FINA080) e a receber (FINA070), bordero, compensacao, e demais movimentacoes financeiras |
| **O que acontece** | Gera lancamentos de baixa contabil (debita banco/caixa, credita contas a receber; ou debita contas a pagar, credita banco/caixa). Movimentacoes como juros, multas, descontos e variacao cambial geram lancamentos complementares |
| **Lancamentos Padrao** | LPs do financeiro (ex: LP 530, 531, 532, 540, 550 series) |
| **Tabelas afetadas** | CT2, CTK, CV3 |

### Estoque → Contabilidade

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | No calculo do custo medio (MATA330/MATA331), transferencias entre armazens, requisicoes e devolucoes |
| **O que acontece** | Gera lancamentos de movimentacao de estoque, ajuste de custo medio e transferencias entre contas de estoque |
| **Lancamentos Padrao** | LPs do estoque |
| **Tabelas afetadas** | CT2, CTK, CV3 |

### Fiscal → Contabilidade

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na apuracao de impostos (ICMS, IPI, PIS, COFINS) e geracao de obrigacoes acessorias |
| **O que acontece** | Gera lancamentos de apuracao fiscal, transferindo saldos de impostos a recuperar/recolher para contas especificas |
| **Lancamentos Padrao** | LPs do modulo fiscal |
| **Tabelas afetadas** | CT2, CTK, CV3 |

### Ativo Fixo → Contabilidade

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | No calculo da depreciacao mensal (ATFA012) e baixa de ativos |
| **O que acontece** | Gera lancamentos de depreciacao (debita despesa de depreciacao, credita depreciacao acumulada) e de baixa de ativos (zerando valor contabil) |
| **Tabelas afetadas** | CT2, CTK, CV3 |

### Folha de Pagamento → Contabilidade

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na contabilizacao da folha (GPEM620/GPEA620) |
| **O que acontece** | Gera lancamentos de salarios, encargos sociais (INSS, FGTS), provisoes de ferias e 13o salario por centro de custo |
| **Tabelas afetadas** | CT2, CTK, CV3 |

### Resumo das integracoes na Contabilidade

```
                    SIGACTB - Contabilidade Gerencial
                              CT2 / CTK / CV3
                                    ^
                                    │
          ┌──────────┬──────────┬───┴───┬──────────┬──────────┐
          │          │          │       │          │          │
    ┌─────v────┐┌───v────┐┌───v────┐┌─v────────┐┌v────────┐┌v──────────┐
    │ Compras  ││Fatura- ││Finan-  ││ Estoque  ││  Fiscal ││Ativo Fixo │
    │ SIGACOM  ││mento   ││ceiro   ││ SIGAEST  ││ SIGAFIS ││ SIGAATF   │
    │ SD1/SF1  ││SIGAFAT ││SIGAFIN ││ SD3/SB9  ││ SFT/SF3 ││ SN1/SN3   │
    └──────────┘│SD2/SF2 ││SE1/SE2 │└──────────┘└─────────┘└───────────┘
                └────────┘│SE5     │
                          └────────┘
                               ^
                               │
                         ┌─────v──────┐
                         │Folha Pgto  │
                         │ SIGAGPE    │
                         │ SRC/SRD    │
                         └────────────┘
```

---

## Cadastros Auxiliares

| Rotina | Descricao | Tabela |
|--------|-----------|--------|
| CTBA010 | Calendario Contabil | CTG |
| CTBA020 | Plano de Contas | CT1 |
| CTBA030 | Centro de Custo | CTT |
| CTBA040 | Item Contabil | CTD |
| CTBA060 | Classe de Valor | CTH |
| CTBA070 | Historico Padrao | CT8 |
| CTBA080 | Lancamento Padrao | CT5 |
| CTBA090 | Relacionamento LP (rastreamento) | CV3 |
| CTBA130 | Configuracao Contabil | - |
| CTBA140 | Moeda Contabil | CTO |
| CTBA180 | Cadastro de Entidades (CC/CLVL/Item) | CTT/CTH/CTD |
| CTBA200 | Moeda x Calendario | CTE |

---

## Parametros Globais do Modulo (MV_*)

| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| MV_MASCARA | C | Mascara contabil (formato da conta, ex: "??.???.??.???") |
| MV_MCONTAB | C | Ambiente contabil: CTB=SIGACTB, CON=SIGACON (obsoleto) |
| MV_CTASUP | C | Geracao automatica da conta superior |
| MV_LOTECON | C | Geracao de lote: T=Tabela 09, U=Ultimo+1 |
| MV_ALTLCTO | C | Permite alteracao de lancamentos (S/N) |
| MV_CT105MS | C | Exibe mensagem na integracao contabil (S/N) |
| MV_CTBPOFF | C | Habilita bloqueio por processo |
| MV_CCSUP | C | Geracao automatica do CC superior |
| MV_TPVALOR | C | Formato de valores nos relatorios contabeis |
