# Modulo PCP - Planejamento e Controle de Producao

## Visao Geral

O modulo PCP (SIGAPCP) do TOTVS Protheus gerencia todo o ciclo de planejamento e controle da producao industrial. Ele abrange desde o cadastro da estrutura de produtos (BOM - Bill of Materials), passando pelo planejamento de necessidades de materiais (MRP), geracao e controle de ordens de producao, ate o apontamento e reporte da producao finalizada, integrando-se diretamente com os modulos de Estoque, Compras, Contabilidade e Qualidade.

**Prefixo do modulo:** PCP
**Sigla do ambiente:** SIGAPCP
**Prefixo das rotinas:** MATA2xx (ex: MATA200, MATA250), MATA6xx (ex: MATA630, MATA650, MATA681, MATA690), MATA7xx (ex: MATA700, MATA710, MATA712), PCPAxx (ex: PCPA107, PCPA712, PCPA750)

### Ciclo principal de producao

```
Estrutura do Produto (BOM) → Previsao de Vendas / Plano Mestre → MRP → Ordem de Producao → Empenho de Materiais → Requisicao / Baixa de Materiais → Apontamento de Producao → Produto Acabado em Estoque
```

O modulo permite tanto o fluxo completo (com MRP e planejamento) quanto o fluxo simplificado (criacao manual de OPs), dependendo da complexidade do processo produtivo da empresa.

---

## Tabelas Principais

### SG1 - Estrutura de Produtos (BOM)

Armazena a composicao (lista de materiais) de cada produto acabado ou intermediario. Cada registro representa um componente vinculado a um produto pai, formando uma arvore hierarquica de niveis.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| G1_FILIAL | C | 8 | Filial |
| G1_COD | C | 15 | Codigo do produto pai |
| G1_COMP | C | 15 | Codigo do componente |
| G1_QUANT | N | 12,6 | Quantidade do componente por unidade do pai |
| G1_PERDA | N | 6,2 | Indice de perda padrao (%) |
| G1_INI | D | 8 | Data de inicio de validade |
| G1_FIM | D | 8 | Data de fim de validade |
| G1_TRT | C | 3 | Sequencia do roteiro de operacao |
| G1_NIV | C | 2 | Nivel na estrutura |
| G1_REVINI | C | 3 | Revisao inicial |
| G1_REVFIM | C | 3 | Revisao final |
| G1_FIXVAR | C | 1 | Tipo do componente: F=Fixo, V=Variavel |
| G1_POTENCI | N | 6,2 | Potencia do componente |
| G1_OBSERV | C | 20 | Observacao |
| G1_FANTASM | C | 1 | Produto fantasma (S/N) |
| G1_REVATU | C | 3 | Revisao atual da estrutura |

**Indices principais:**
- Ordem 1: `G1_FILIAL + G1_COD + G1_COMP + G1_TRT`
- Ordem 2: `G1_FILIAL + G1_COMP + G1_COD`
- Ordem 3: `G1_FILIAL + G1_COD + G1_REVINI`

---

### SC2 - Ordens de Producao

Armazena as ordens de producao (OPs). Cada registro representa uma OP para fabricacao de um produto, contendo quantidade planejada, datas previstas, status e controle de producao.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| C2_FILIAL | C | 8 | Filial |
| C2_NUM | C | 6 | Numero da ordem de producao |
| C2_ITEM | C | 2 | Item da OP |
| C2_SEQUEN | C | 3 | Sequencia |
| C2_PRODUTO | C | 15 | Codigo do produto |
| C2_DESCRI | C | 30 | Descricao do produto |
| C2_UM | C | 2 | Unidade de medida |
| C2_QUANT | N | 12,2 | Quantidade planejada |
| C2_QUJE | N | 12,2 | Quantidade ja produzida |
| C2_DATPRI | D | 8 | Data prevista de inicio |
| C2_DATPRF | D | 8 | Data prevista de entrega |
| C2_EMISSAO | D | 8 | Data de emissao |
| C2_LOCAL | C | 2 | Armazem destino do produto acabado |
| C2_LOCALI | C | 2 | Armazem de requisicao dos componentes |
| C2_CC | C | 9 | Centro de custo |
| C2_DATRF | D | 8 | Data real de finalizacao |
| C2_STATUS | C | 1 | Status: P=Prevista, N=Normal, I=Iniciada, E=Encerrada |
| C2_TPOP | C | 2 | Tipo de OP |
| C2_PEDIDO | C | 6 | Pedido de venda vinculado |
| C2_ITEMPED | C | 2 | Item do pedido de venda |
| C2_OBS | C | 40 | Observacoes |
| C2_LOTE | C | 18 | Lote de producao |
| C2_RECURSO | C | 6 | Recurso alocado |
| C2_REVATU | C | 3 | Revisao da estrutura utilizada |

**Indices principais:**
- Ordem 1: `C2_FILIAL + C2_NUM + C2_ITEM + C2_SEQUEN`
- Ordem 2: `C2_FILIAL + C2_PRODUTO + C2_NUM + C2_ITEM + C2_SEQUEN`
- Ordem 3: `C2_FILIAL + C2_EMISSAO + C2_NUM + C2_ITEM`
- Ordem 4: `C2_FILIAL + C2_DATPRF + C2_NUM + C2_ITEM`

---

### SD3 - Movimentacoes Internas (Estoque)

Armazena todas as movimentacoes internas de estoque, incluindo requisicoes, devolucoes, producao, transferencias e ajustes. No contexto do PCP, registra requisicoes de materiais para producao e entrada de produto acabado.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| D3_FILIAL | C | 8 | Filial |
| D3_DOC | C | 9 | Numero do documento |
| D3_COD | C | 15 | Codigo do produto |
| D3_LOCAL | C | 2 | Armazem |
| D3_QUANT | N | 12,2 | Quantidade movimentada |
| D3_CUSTO1 | N | 14,2 | Custo unitario |
| D3_TOTAL | N | 14,2 | Valor total |
| D3_TM | C | 3 | Tipo de movimento (RE=Requisicao, PR=Producao, DE=Devolucao) |
| D3_CF | C | 3 | Codigo fiscal (RE0-RE9, DE0-DE9, etc.) |
| D3_EMISSAO | D | 8 | Data de emissao |
| D3_OP | C | 13 | Ordem de producao vinculada |
| D3_CC | C | 9 | Centro de custo |
| D3_CONTA | C | 20 | Conta contabil |
| D3_UM | C | 2 | Unidade de medida |
| D3_LOTECTL | C | 18 | Lote de controle |
| D3_NUMSERI | C | 20 | Numero de serie |
| D3_DTVALID | D | 8 | Data de validade |
| D3_PERDA | N | 12,2 | Quantidade de perda |
| D3_ESTORNO | C | 1 | Estorno (S/N) |

**Indices principais:**
- Ordem 1: `D3_FILIAL + D3_DOC + D3_COD`
- Ordem 2: `D3_FILIAL + D3_COD + D3_LOCAL + D3_DOC`
- Ordem 3: `D3_FILIAL + D3_EMISSAO + D3_COD`
- Ordem 4: `D3_FILIAL + D3_OP + D3_COD`

---

### SD4 - Empenhos (Requisicoes Empenhadas)

Armazena os empenhos de materiais vinculados as ordens de producao. Cada registro representa a necessidade de um componente para uma OP especifica, com base na estrutura do produto (SG1).

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| D4_FILIAL | C | 8 | Filial |
| D4_COD | C | 15 | Codigo do componente |
| D4_LOCAL | C | 2 | Armazem de requisicao |
| D4_OP | C | 13 | Ordem de producao |
| D4_DATA | D | 8 | Data do empenho |
| D4_QUANT | N | 12,2 | Quantidade empenhada |
| D4_QTDEORI | N | 12,2 | Quantidade original do empenho |
| D4_TRT | C | 3 | Sequencia da operacao |
| D4_PRODUTO | C | 15 | Codigo do produto pai da OP |
| D4_CC | C | 9 | Centro de custo |
| D4_CONTA | C | 20 | Conta contabil |
| D4_QTSEGUM | N | 12,2 | Quantidade na segunda unidade de medida |

**Indices principais:**
- Ordem 1: `D4_FILIAL + D4_OP + D4_COD`
- Ordem 2: `D4_FILIAL + D4_COD + D4_LOCAL + D4_OP`
- Ordem 3: `D4_FILIAL + D4_DATA + D4_COD`

---

### SH1 - Recursos

Armazena o cadastro de recursos produtivos (maquinas, equipamentos, mao de obra) utilizados nos roteiros de operacao e na carga maquina.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| H1_FILIAL | C | 8 | Filial |
| H1_CODIGO | C | 6 | Codigo do recurso |
| H1_DESCRI | C | 30 | Descricao do recurso |
| H1_TIPO | C | 1 | Tipo: 1=Maquina, 2=Mao de Obra, 3=Ferramenta |
| H1_CCUSTO | C | 9 | Centro de custo do recurso |
| H1_CAPACI | N | 6,2 | Capacidade do recurso |
| H1_EFICIEN | N | 5,2 | Eficiencia do recurso (%) |
| H1_CALEND | C | 3 | Codigo do calendario |
| H1_CUSTHR | N | 12,2 | Custo por hora |
| H1_CUTHRIM | N | 12,2 | Custo hora improdutiva |
| H1_UTIFERR | C | 1 | Utiliza ferramenta (S/N) |

**Indices principais:**
- Ordem 1: `H1_FILIAL + H1_CODIGO`
- Ordem 2: `H1_FILIAL + H1_DESCRI`

---

### SG2 - Roteiro de Operacoes

Armazena o roteiro de fabricacao de cada produto, definindo a sequencia de operacoes, recursos utilizados, tempos de preparacao e execucao. Essencial para o calculo de carga maquina e programacao da producao.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| G2_FILIAL | C | 8 | Filial |
| G2_CODIGO | C | 15 | Codigo do produto |
| G2_OPERAC | C | 3 | Numero da operacao |
| G2_RECURSO | C | 6 | Codigo do recurso |
| G2_DESCRI | C | 40 | Descricao da operacao |
| G2_TPPREP | N | 8,2 | Tempo de preparacao (setup) em horas |
| G2_TPEXEC | N | 8,4 | Tempo de execucao por unidade em horas |
| G2_LOTEPAD | N | 12,2 | Lote padrao da operacao |
| G2_FERRAM | C | 6 | Codigo da ferramenta |
| G2_SOBREP | N | 5,2 | Percentual de sobreposicao |
| G2_REQSUC | C | 1 | Requer sucata (S/N) |
| G2_ALTREC | C | 6 | Recurso alternativo |
| G2_REVINI | C | 3 | Revisao inicial |
| G2_REVFIM | C | 3 | Revisao final |

**Indices principais:**
- Ordem 1: `G2_FILIAL + G2_CODIGO + G2_OPERAC`
- Ordem 2: `G2_FILIAL + G2_RECURSO + G2_CODIGO`

---

### SHB - Operacoes (Cadastro de Operacoes)

Armazena o cadastro de operacoes padrao utilizadas nos roteiros de producao, contendo a descricao das atividades produtivas.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| HB_FILIAL | C | 8 | Filial |
| HB_CODIGO | C | 3 | Codigo da operacao |
| HB_DESCRI | C | 40 | Descricao da operacao |
| HB_TPOPER | C | 1 | Tipo de operacao: 1=Interna, 2=Externa |
| HB_CUSTHR | N | 12,2 | Custo/hora padrao da operacao |

**Indices principais:**
- Ordem 1: `HB_FILIAL + HB_CODIGO`
- Ordem 2: `HB_FILIAL + HB_DESCRI`

---

## Rotinas Principais

### MATA200 - Estrutura do Produto (BOM)

**O que faz:** Permite incluir, alterar, excluir e visualizar a estrutura de produtos (Bill of Materials). A estrutura define como um produto e montado em todos os seus niveis, apresentando componentes e quantidades em formato de arvore. Cada componente e vinculado ao produto pai (nivel superior). A estrutura e a base para que uma Ordem de Producao gere os empenhos dos componentes.

**Tabelas envolvidas:**
- SG1 (escrita) - Estrutura de Produtos
- SB1 (leitura) - Cadastro de Produtos
- SG2 (leitura/escrita) - Roteiro de Operacoes

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_REVAUT | Revisao automatica da estrutura (.T.=automatico, .F.=manual) |
| MV_REVFIL | Controle de revisao de estrutura por filial via tabela SBZ (usado com MV_ARQPROD=SBZ) |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT200ALT | Bloqueio da alteracao da estrutura do produto |
| A200BOK | Valida alteracoes na estrutura do produto |
| MTA200 | Executado em eventos de manutencao da estrutura |
| A200BOKOP | Valida inclusao de operacoes na estrutura |
| MT200GRV | Manipula gravacao da estrutura do produto |

---

### MATA650 - Ordem de Producao

**O que faz:** Permite incluir, alterar, excluir, visualizar e gerenciar ordens de producao (OPs). A OP inicia o processo de fabricacao, relacionando todos os componentes e etapas de fabricacao determinados pela estrutura do produto. Ao incluir uma OP, o sistema pode realizar automaticamente a explosao da estrutura gerando os empenhos de materiais (SD4).

**Tabelas envolvidas:**
- SC2 (escrita) - Ordens de Producao
- SD4 (escrita) - Empenhos
- SG1 (leitura) - Estrutura de Produtos
- SB1 (leitura) - Cadastro de Produtos
- SB2 (leitura) - Saldos por Armazem
- SG2 (leitura) - Roteiro de Operacoes

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_PRECISA | Precisao de calculo para planejamento (impacta processamento) |
| MV_ESTNEG | Permite estoque negativo (S=Permite, N=Nao permite) |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| A650OPI | Verifica necessidade de geracao da OP |
| EMP650 | Manipula empenhos na abertura da OP |
| A650LEMP | Altera conteudo do armazem na geracao de empenho |
| MA650MNU | Adiciona opcoes no menu da rotina |
| A650GRSC2 | Manipula dados gravados na SC2 |
| M650CAN | Cancelamento de operacoes em ordens |

---

### MATA250 - Apontamento de Producao (Producao Modelo 1)

**O que faz:** Permite executar o reporte de producao, estorno de reporte e encerramento de ordens de producao. Ao reportar a producao, o sistema da entrada do produto acabado no estoque e, conforme parametrizacao, pode requisitar automaticamente os componentes empenhados (SD4). Tambem permite registrar perdas ocorridas durante o processo produtivo.

**Tabelas envolvidas:**
- SC2 (leitura/escrita) - Ordens de Producao (atualiza C2_QUJE)
- SD3 (escrita) - Movimentacoes de Estoque (entrada producao e requisicao)
- SD4 (leitura/escrita) - Empenhos (baixa dos empenhos)
- SB2 (leitura/escrita) - Saldos por Armazem
- SB1 (leitura) - Cadastro de Produtos

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_REQAUT | Requisicao automatica: S=Automatica na producao, N=Manual via MATA241, A=Todos, D=Diretos manual/Indiretos automatico |
| MV_PRODAUT | Producao automatica de OPs intermediarias (.T./.F.) |
| MV_PERCPRM | Proporcionaliza consumo de componentes quando quantidade excede planejada |
| MV_PRODPR0 | Proporcionalizacao do custeio de producao: 1=Qtd apontada, 2=D3_RATEIO, 3=Qtd original da OP |
| MV_PERDINF | Conceito de perda no apontamento (.T.=Perda informativa/custo proporcional, .F.=Perda no saldo da OP) |
| MV_APTEMP | Valida empenhos temporarios no apontamento |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| A250ITOK | Permite customizacao antes de efetivar o apontamento |
| A250ENOP | Define encerramento das OPs intermediarias |
| A250REQAUT | Manipula parametro MV_REQAUT nos apontamentos |
| A250ARD4 | Seleciona e ordena empenhos da SD4 para consumo |
| SD3250R | Encerramento das ordens de producao |
| A250SALD | Valida saldo de estoque antes da requisicao |

---

### MATA681 - Apontamento de Producao por Operacao (Modelo 2)

**O que faz:** Realiza o apontamento de producao baseado no roteiro de operacoes (SG2). Diferente do modelo 1 (MATA250), permite reportar a producao operacao por operacao, rastreando o tempo e quantidade em cada etapa do processo produtivo. Ideal para fabricas com processos mais complexos e controle detalhado por etapa.

**Tabelas envolvidas:**
- SC2 (leitura/escrita) - Ordens de Producao
- SD3 (escrita) - Movimentacoes de Estoque
- SD4 (leitura/escrita) - Empenhos
- SG2 (leitura) - Roteiro de Operacoes
- SH6 (escrita) - Apontamentos de Producao (detalhe por operacao)
- SH1 (leitura) - Recursos

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_REQAUT | Requisicao automatica de materiais (S/N/A/D) |
| MV_PRODAUT | Producao automatica de OPs intermediarias (.T./.F.) |
| MV_PRECISA | Precisao de calculo para planejamento |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT680VAL | Validacao na inclusao das producoes |
| A680PERG | Manipula perguntas do apontamento de producao |
| A681CPO | Adiciona campos na tela de roteiro de operacoes |
| MA680TMP | Altera valor do tipo de movimentacao padrao para producao |

---

### PCPA712 / MATA712 - MRP (Planejamento de Necessidades de Materiais)

**O que faz:** Calcula a necessidade de materiais para cada produto conforme a demanda, com base nas estruturas dos produtos (SG1). Gera solicitacoes de compra (SC1) para materias-primas e ordens de producao previstas (SC2) para itens intermediarios e acabados, considerando lotes economicos, quantidades minimas e estoque de seguranca. O PCPA712 e a versao em memoria (mais performatica), enquanto MATA712 e a versao classica.

**Fontes de demanda:**
- Previsao de Vendas (MATA700 / SC4)
- Pedidos de Venda (SC5/SC6)
- Plano Mestre de Producao (PCPA750)
- Ordens de Producao existentes (SC2)

**Tabelas envolvidas:**
- SC2 (escrita) - Ordens de Producao (previstas)
- SC1 (escrita) - Solicitacoes de Compra
- SG1 (leitura) - Estrutura de Produtos
- SB1 (leitura) - Cadastro de Produtos
- SB2 (leitura) - Saldos por Armazem
- SD4 (leitura) - Empenhos existentes
- SC5/SC6 (leitura) - Pedidos de Venda
- SC4 (leitura) - Previsao de Vendas

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_QUEBROP | Quebra OPs por lote economico (S=Sim, N=Nao - gera uma unica OP) |
| MV_QUEBRSC | Quebra SCs por lote economico (S=Sim, N=Nao - gera uma unica SC) |
| MV_PRECISA | Precisao de calculo (impacta performance) |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| A712CNTSC1 | Manipula campos customizados na criacao da SC1 pelo MRP |
| PA145GER | Customizacoes na geracao de documentos do MRP |

**Rotinas auxiliares do MRP:**
| Rotina | Descricao |
|--------|-----------|
| PCPA136 | Demandas do MRP - consulta demandas calculadas |
| PCPA139 | Parametros de integracao MRP |
| PCPA140 | Sincronizador do MRP (obrigatorio antes da primeira execucao) |
| PCPA141 | Configuracao de integracao MRP por Schedule |
| PCPA144 | Geracao de documentos a partir dos resultados do MRP |

---

### MATA690 - Carga Maquina (CRP)

**O que faz:** Realiza a alocacao das operacoes nos recursos disponiveis (CRP - Capacity Requirements Planning / Planejamento das Necessidades de Capacidade). Distribui as ordens de producao nos recursos conforme roteiro de operacoes, calendarios e capacidade, gerando um cronograma detalhado de producao. Permite visualizar gargalos e otimizar a utilizacao dos recursos produtivos.

**Tabelas envolvidas:**
- SC2 (leitura) - Ordens de Producao
- SG2 (leitura) - Roteiro de Operacoes
- SH1 (leitura) - Recursos
- SH4 (leitura) - Ferramentas
- SH7 (escrita) - Carga Maquina (resultado do processamento)
- SH8 (leitura) - Calendario

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_PRECISA | Precisao do calculo (quanto maior, maior o tempo de processamento) |

---

### MATA700 - Previsao de Vendas

**O que faz:** Permite cadastrar a previsao de vendas por produto para periodos futuros (semanas, meses, trimestres). Essas previsoes alimentam o MRP como fonte de demanda, permitindo que o sistema calcule as necessidades de producao e compra antecipadamente.

**Tabelas envolvidas:**
- SC4 (escrita) - Previsao de Vendas
- SB1 (leitura) - Cadastro de Produtos

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MTA700MNU | Insere novas opcoes no menu da rotina |
| MT700EXC | Validacao na exclusao de previsao de vendas |
| MT700INC | Validacao na inclusao/modificacao de previsao |

---

### MATA380 / MATA381 - Ajuste de Empenhos

**O que faz:** Permite ajustar manualmente os empenhos de materiais de uma OP quando ha diferencas entre o material empenhado originalmente e o que sera realmente utilizado. MATA380 e o modelo simples (um item por vez) e MATA381 e o modelo 2 (multiplos itens).

**Tabelas envolvidas:**
- SD4 (escrita) - Empenhos
- SC2 (leitura) - Ordens de Producao
- SG1 (leitura) - Estrutura de Produtos
- SB2 (leitura) - Saldos por Armazem

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| M380ZEMP | Controla permissao de zerar empenho |
| MA381MNU | Adiciona opcoes no menu da rotina MATA381 |

---

### MATA630 - Operacoes

**O que faz:** Permite cadastrar, alterar e excluir as operacoes dos roteiros de producao. As operacoes definem as etapas de fabricacao de um produto, sendo fundamentais para a carga maquina e o apontamento por operacao (MATA681). Atraves das operacoes, o sistema aloca a necessidade de producao e recursos (maquinas/operadores) em um cronograma planejado.

**Tabelas envolvidas:**
- SG2 (escrita) - Roteiro de Operacoes
- SHB (leitura) - Cadastro de Operacoes
- SH1 (leitura) - Recursos
- SH4 (leitura) - Ferramentas
- SB1 (leitura) - Cadastro de Produtos

---

### MATA651 - Ordens de Producao Previstas

**O que faz:** Permite firmar (confirmar) ordens de producao previstas, geradas pelo MRP, transformando-as em OPs normais prontas para execucao. Uma OP prevista indica que ainda nao ha certeza absoluta sobre a producao do item; ao ser firmada, torna-se uma OP que sera liberada para producao.

**Tabelas envolvidas:**
- SC2 (leitura/escrita) - Ordens de Producao (altera status de Prevista para Normal)
- SD4 (escrita) - Empenhos (gerados ao firmar)
- SG1 (leitura) - Estrutura de Produtos

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MA651PRC | Validacao para firmar OPs previstas |

---

## Processos de Negocio

### Fluxo Completo de Producao (com MRP)

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  1. Estrutura    │────>│  2. Previsao /   │────>│  3. MRP          │
│  do Produto      │     │  Plano Mestre    │     │  (Calculo de     │
│  MATA200 / SG1   │     │  MATA700 / SC4   │     │  Necessidades)   │
└─────────────────┘     │  PCPA750         │     │  PCPA712/MATA712 │
                         └─────────────────┘     └────────┬────────┘
                                                          │
                    ┌─────────────────────────────────────┤
                    │                                     │
          ┌────────v────────┐               ┌────────────v────────┐
          │  4a. SC Compra   │               │  4b. OP Prevista     │
          │  (materia-prima) │               │  (prod. intermediario│
          │  SC1 → Compras   │               │  e acabado)          │
          └─────────────────┘               │  MATA651 / SC2       │
                                             └────────────┬────────┘
                                                          │
┌─────────────────┐     ┌─────────────────┐     ┌────────v────────┐
│  7. Produto      │<────│  6. Apontamento  │<────│  5. Empenho de   │
│  Acabado em      │     │  de Producao     │     │  Materiais       │
│  Estoque / SB2   │     │  MATA250/MATA681 │     │  SD4             │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

#### Passo 1: Cadastro da Estrutura do Produto (MATA200)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA200 |
| **Tabelas** | SG1 (escrita), SB1 (leitura), SG2 (opcional) |
| **O que acontece** | O engenheiro/responsavel define a arvore de componentes do produto, informando para cada nivel: componente, quantidade por unidade do produto pai, indice de perda e opcionalmente o roteiro de operacoes. A estrutura pode ter multiplos niveis (produto acabado → subconjunto → materia-prima). |
| **Resultado** | Registros na SG1 representando a BOM completa do produto |

#### Passo 2: Previsao de Vendas / Plano Mestre (MATA700 / PCPA750)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA700 (Previsao de Vendas) / PCPA750 (Plano Mestre de Producao) |
| **Tabelas** | SC4 (escrita) |
| **O que acontece** | A area comercial/planejamento informa a demanda prevista por produto e periodo. A previsao de vendas indica necessidade futura e permite ao MRP avaliar estoque antes de gerar OP. O Plano Mestre gera OP para a quantidade exata informada no plano. |
| **Resultado** | Registros na SC4 alimentando o MRP como fonte de demanda |

#### Passo 3: MRP - Calculo de Necessidades (PCPA712 / MATA712)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | PCPA712 (em memoria) ou MATA712 (classico) |
| **Tabelas** | SG1 (leitura), SB1/SB2 (leitura), SC5/SC6 (leitura), SC4 (leitura), SC2/SC1 (escrita) |
| **O que acontece** | O MRP explode a estrutura de cada produto demandado, calcula a necessidade liquida (demanda - estoque disponivel - ordens em aberto), gera OPs previstas para itens fabricados e SCs para itens comprados. Considera lead time, lote economico, estoque de seguranca e quantidade minima. |
| **Resultado** | OPs previstas na SC2 (C2_STATUS = "P") e SCs na SC1 |

#### Passo 4: Firmar OPs e Gerar Empenhos (MATA651 / MATA650)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA651 (firmar previstas) ou MATA650 (inclusao manual) |
| **Tabelas** | SC2 (escrita), SD4 (escrita), SG1 (leitura) |
| **O que acontece** | OPs previstas sao revisadas e firmadas. Ao firmar ou incluir uma OP com explosao automatica, o sistema gera empenhos (SD4) para cada componente da estrutura, reservando os materiais necessarios. O empenho considera quantidade da OP, quantidade por unidade do componente e indice de perda. |
| **Resultado** | SC2 com status Normal (C2_STATUS = "N"), SD4 com empenhos gerados |

#### Passo 5: Requisicao de Materiais (MATA241 ou automatica)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA241 (manual) ou automatica via MV_REQAUT no apontamento |
| **Tabelas** | SD3 (escrita), SD4 (escrita), SB2 (escrita) |
| **O que acontece** | Os materiais empenhados sao requisitados do estoque para a producao. Se MV_REQAUT = "S", a requisicao ocorre automaticamente no momento do apontamento. Se MV_REQAUT = "N", a requisicao deve ser feita manualmente (MATA241) antes do apontamento. Os empenhos sao baixados conforme materiais sao consumidos. |
| **Resultado** | Movimentacoes na SD3 (saida por requisicao), SB2 atualizado, SD4 baixado |

#### Passo 6: Apontamento de Producao (MATA250 / MATA681)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA250 (modelo 1) ou MATA681 (modelo 2 - por operacao) |
| **Tabelas** | SC2 (escrita), SD3 (escrita), SD4 (escrita), SB2 (escrita) |
| **O que acontece** | O operador reporta a quantidade produzida. O sistema da entrada do produto acabado no estoque (SD3 tipo producao), atualiza a quantidade produzida na OP (C2_QUJE) e, se requisicao automatica, baixa os componentes. Perdas podem ser registradas. Se MV_PRODAUT estiver ativo, OPs intermediarias sao reportadas automaticamente. |
| **Resultado** | SC2 com C2_QUJE atualizada, SD3 com entrada de producao, estoque atualizado |

#### Passo 7: Encerramento da OP

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA250 (encerramento) |
| **Tabelas** | SC2 (escrita), SD4 (escrita) |
| **O que acontece** | Quando toda a quantidade planejada foi produzida (ou quando se decide encerrar antes), a OP e encerrada (C2_STATUS = "E"). Empenhos remanescentes sao eliminados. A OP nao aceita mais apontamentos apos encerramento. |
| **Resultado** | SC2 com status Encerrada, empenhos residuais eliminados |

### Fluxo Simplificado (sem MRP)

```
Estrutura do Produto (SG1) → OP Manual (SC2) → Empenho (SD4) → Requisicao (SD3) → Apontamento (SD3) → Encerramento
```

No fluxo simplificado, o planejador cria a OP diretamente via MATA650 sem passar pelo MRP. A explosao da estrutura e feita automaticamente na inclusao da OP, gerando os empenhos. O restante do fluxo segue normalmente.

---

## Regras de Negocio

### Campos obrigatorios por rotina

**Estrutura do Produto (MATA200 - SG1):**
- G1_COD (Codigo do produto pai)
- G1_COMP (Codigo do componente)
- G1_QUANT (Quantidade por unidade)

**Ordem de Producao (MATA650 - SC2):**
- C2_PRODUTO (Codigo do produto)
- C2_QUANT (Quantidade planejada)
- C2_DATPRI (Data prevista de inicio)
- C2_DATPRF (Data prevista de entrega)
- C2_LOCAL (Armazem destino)

**Apontamento de Producao (MATA250 - SD3):**
- D3_TM (Tipo de movimento)
- D3_OP (Ordem de producao)
- D3_QUANT (Quantidade produzida)
- D3_COD (Codigo do produto)
- D3_LOCAL (Armazem)

### Validacoes principais

| Validacao | Descricao |
|-----------|-----------|
| Estrutura circular | O sistema impede que um produto seja componente de si mesmo (direta ou indiretamente) |
| Validade da estrutura | Componentes com data de validade (G1_INI/G1_FIM) sao considerados apenas no periodo vigente |
| Saldo de empenho | Na requisicao, a quantidade nao pode ultrapassar o saldo empenhado para a OP (D4_QUANT) |
| Saldo de OP | No apontamento, a quantidade produzida somada a ja reportada nao pode ultrapassar a quantidade da OP, salvo parametrizacao contraria (MV_LIBACIM/MV_GANHOPR) |
| Estoque disponivel | Requisicoes verificam saldo em estoque (SB2). Se MV_ESTNEG nao permitir, bloqueia requisicao sem saldo |
| OP encerrada | Nao permite apontamento ou requisicao em OP com status Encerrada (C2_STATUS = "E") |
| Revisao de estrutura | Se controle de revisao ativo, apenas a revisao vigente da estrutura e considerada na explosao |
| Produto fantasma | Componentes marcados como fantasma (G1_FANTASM = "S") sao explodidos automaticamente ate o nivel real |

### Gatilhos SX7 relevantes

| Campo origem | Campo destino | Regra | Tabela lookup |
|-------------|---------------|-------|---------------|
| C2_PRODUTO | C2_DESCRI | SB1->B1_DESC | SB1 |
| C2_PRODUTO | C2_UM | SB1->B1_UM | SB1 |
| C2_PRODUTO | C2_LOCAL | SB1->B1_LOCPAD | SB1 |
| D3_COD | D3_UM | SB1->B1_UM | SB1 |
| D3_COD | D3_CONTA | SB1->B1_CONTA | SB1 |
| D3_COD | D3_CC | SB1->B1_CC | SB1 |
| G1_COMP | Descricao | SB1->B1_DESC | SB1 |
| G1_COMP | UM | SB1->B1_UM | SB1 |

### Pontos de entrada mais utilizados no modulo

| Ponto de Entrada | Rotina | Descricao |
|------------------|--------|-----------|
| MT200ALT | MATA200 | Bloqueia alteracao da estrutura do produto |
| A200BOK | MATA200 | Valida alteracoes na estrutura |
| A650OPI | MATA650 | Verifica necessidade de geracao da OP |
| EMP650 | MATA650 | Manipula empenhos ao abrir OP |
| A650LEMP | MATA650 | Altera armazem na geracao de empenho |
| A250ITOK | MATA250 | Customizacao antes de efetivar apontamento |
| A250ENOP | MATA250 | Define encerramento de OPs intermediarias |
| A250REQAUT | MATA250 | Manipula MV_REQAUT nos apontamentos |
| A250ARD4 | MATA250 | Ordena empenhos da SD4 para consumo |
| MT680VAL | MATA681 | Validacao na inclusao de producao modelo 2 |
| A680PERG | MATA681 | Manipula perguntas do apontamento |
| M380ZEMP | MATA380 | Controla permissao de zerar empenho |
| MA651PRC | MATA651 | Validacao para firmar OPs previstas |
| A712CNTSC1 | PCPA712 | Manipula campos customizados na SC1 pelo MRP |
| MTA700MNU | MATA700 | Adiciona opcoes no menu da previsao de vendas |
| MT700EXC | MATA700 | Validacao na exclusao de previsao |

---

## Integracoes

### PCP → Estoque

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | No apontamento de producao (MATA250/MATA681) e na requisicao de materiais (MATA241 ou automatica) |
| **O que acontece** | O apontamento gera movimentacao de entrada na SD3 (producao do produto acabado) e saida na SD3 (requisicao dos componentes). O saldo dos armazens e atualizado na SB2. Os empenhos (SD4) sao baixados conforme consumo |
| **Tabelas afetadas** | SD3 (movimentacao), SB2 (saldo por armazem), SD4 (empenhos) |
| **Controles** | Se controle de lote/sublote estiver ativo (B1_RASTRO), exige informacao de lote. O indice de perda da estrutura (G1_PERDA) e aplicado automaticamente no calculo da requisicao |

### PCP → Compras

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na execucao do MRP (PCPA712/MATA712) ou geracao de documentos (PCPA144) |
| **O que acontece** | Para itens comprados (materia-prima), o MRP gera solicitacoes de compra (SC1) com a quantidade necessaria, data de necessidade e observacao indicando a origem como MRP. As SCs seguem o fluxo normal de compras: cotacao, pedido, recebimento |
| **Tabelas afetadas** | SC1 (Solicitacoes de Compra) |
| **Observacao** | O parametro MV_QUEBRSC define se gera uma unica SC com a quantidade total ou multiplas SCs respeitando o lote economico |

### PCP → Contabilidade

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | No apontamento de producao e na requisicao de materiais, quando contabilizacao online estiver habilitada |
| **O que acontece** | Gera lancamentos contabeis na CT2 para: (a) entrada de produto acabado debitando estoque de PA e creditando producao em processo; (b) saida de materiais debitando producao em processo e creditando estoque de MP. Os lancamentos seguem o Lancamento Padrao (CT5) configurado na TES |
| **Tabelas afetadas** | CT2 (Lancamentos Contabeis) |
| **Parametro** | MV_PRODPR0 - Proporcionalizacao do custeio de producao: 1=Qtd apontada, 2=D3_RATEIO, 3=Qtd original da OP |

### PCP → Qualidade

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na geracao de OPs e no apontamento de producao, quando modulo de qualidade (SIGAQIP) esta ativo |
| **O que acontece** | Pode gerar inspecoes de processo vinculadas as OPs e operacoes. No apontamento, valida especificacoes de qualidade do produto. Ordens de producao podem ser geradas a partir do modulo de Qualidade (MATA650 via SIGAQIP) |
| **Tabelas afetadas** | QQK (Especificacoes de Operacoes), SQA (Inspecoes) |

### PCP → Faturamento / Vendas

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na geracao de OPs a partir de Pedidos de Venda |
| **O que acontece** | OPs podem ser vinculadas a pedidos de venda (C2_PEDIDO + C2_ITEMPED), permitindo rastreabilidade da demanda ate a producao. O MRP pode considerar pedidos de venda como fonte de demanda. A tabela SGJ amarra o relacionamento entre Pedido de Venda e Ordem de Producao |
| **Tabelas afetadas** | SC2 (vinculo com pedido), SGJ (amarracao PV x OP) |

### Resumo das integracoes do PCP

```
                    Previsao de Vendas / Pedidos de Venda
                                    │
                                    v
                         ┌─────────────────┐
                         │   MRP (PCPA712)  │
                         └────────┬────────┘
                    ┌─────────────┼─────────────┐
                    │                            │
              ┌─────v─────┐              ┌──────v──────┐
              │  Compras   │              │  Producao    │
              │  SC1       │              │  SC2 / SD4   │
              └───────────┘              └──────┬──────┘
                                                │
                              ┌─────────────────┼─────────────────┐
                              │                 │                 │
                        ┌─────v─────┐    ┌─────v─────┐    ┌─────v─────┐
                        │  Estoque   │    │Contabilid.│    │ Qualidade │
                        │ SD3 / SB2  │    │    CT2    │    │ QQK / SQA │
                        └───────────┘    └───────────┘    └───────────┘
```

---

## Cadastros Auxiliares

| Rotina | Descricao | Tabela |
|--------|-----------|--------|
| MATA200 | Estrutura do Produto (BOM) | SG1 |
| MATA630 | Cadastro de Operacoes (Roteiro) | SG2 / SHB |
| MATA620 | Cadastro de Ferramentas | SH4 |
| MATA610 | Cadastro de Recursos | SH1 |
| MATA600 | Cadastro de Calendarios | SH8 |
| MATA700 | Previsao de Vendas | SC4 |
| PCPA750 | Plano Mestre de Producao | SC4 |
| MATA093 | Centro de Trabalho | SHC |
| PCPA200 | Consulta de Estrutura | SG1 (somente leitura) |
| PCPA153 | Diagnostico PCP | Validacao de pre-requisitos |

---

## Parametros Globais do Modulo (MV_*)

| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| MV_REQAUT | C | Requisicao automatica de materiais no apontamento (S=Automatica, N=Manual/MATA241, A=Todos, D=Diretos manual/Indiretos automatico) |
| MV_PRODAUT | L | Gera lancamentos automaticos de producao das OPs vinculadas a OP pai (.T./.F.) |
| MV_PRODPR0 | N | Proporcionalizacao do custeio de producao no recalculo de custo medio: 1=Qtd apontada, 2=D3_RATEIO, 3=Qtd original da OP |
| MV_PERCPRM | L | Proporcionaliza consumo de componentes em producao excedente |
| MV_PERDINF | L | Conceito de perda no apontamento (.T.=Perda informativa/custo proporcional a producao, .F.=Perda considerada no saldo da OP) |
| MV_PRECISA | N | Fracao de uma hora e nivel de precisao para calendario. Padrao=4 (15 min). Quanto maior, maior o tempo de processamento |
| MV_QUEBROP | C | Habilita lote economico para ordens de producao no MRP (S/N) |
| MV_QUEBRSC | C | Habilita lote economico para solicitacoes de compra no MRP (S/N) |
| MV_APTEMP | L | Valida empenhos temporarios no apontamento |
| MV_ESTNEG | C | Permite estoque negativo (S=Permite, N=Nao permite) |
| MV_REVFIL | L | Controle de revisao de estrutura por filial via tabela SBZ (usado com MV_ARQPROD=SBZ) |
