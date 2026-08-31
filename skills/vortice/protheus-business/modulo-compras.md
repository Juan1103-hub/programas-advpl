# Modulo de Compras (COM)

## Visao Geral

O modulo de Compras (SIGACOM) do TOTVS Protheus gerencia todo o ciclo de aquisicao de materiais e servicos da empresa. Ele abrange desde a identificacao da necessidade de compra ate o recebimento fisico e fiscal dos materiais, integrando-se diretamente com os modulos de Estoque, Financeiro, Fiscal e Contabilidade.

**Prefixo do modulo:** COM
**Sigla do ambiente:** SIGACOM
**Prefixo das rotinas:** MATA1xx (ex: MATA110, MATA120, MATA121, MATA130, MATA131, MATA140)

### Ciclo principal de compras

```
Necessidade → Solicitacao de Compra → Cotacao → Analise de Cotacao → Pedido de Compra → Documento de Entrada → Titulo a Pagar
```

O modulo permite tanto o fluxo completo (com cotacao) quanto o fluxo simplificado (pedido direto sem cotacao), controlado pelo parametro `MV_RESTINC`.

---

## Tabelas Principais

### SC1 - Solicitacoes de Compra

Armazena as solicitacoes de compra geradas manualmente ou via MRP/Ponto de Pedido. Cada registro representa um item solicitado.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| C1_FILIAL | C | 8 | Filial |
| C1_NUM | C | 6 | Numero da solicitacao |
| C1_ITEM | C | 4 | Item da solicitacao |
| C1_PRODUTO | C | 15 | Codigo do produto |
| C1_DESCRI | C | 30 | Descricao do produto |
| C1_UM | C | 2 | Unidade de medida |
| C1_QUANT | N | 12,2 | Quantidade solicitada |
| C1_QUJE | N | 12,2 | Quantidade ja atendida |
| C1_EMISSAO | D | 8 | Data de emissao |
| C1_DATPRF | D | 8 | Data de necessidade (previsao) |
| C1_SOLICIT | C | 25 | Nome do solicitante |
| C1_OBS | C | 40 | Observacoes |
| C1_LOCAL | C | 2 | Armazem destino |
| C1_CC | C | 9 | Centro de custo |
| C1_CONTA | C | 20 | Conta contabil |
| C1_ITEMCTA | C | 9 | Item contabil |
| C1_CLVL | C | 9 | Classe de valor |
| C1_CODCOMP | C | 25 | Codigo do comprador |
| C1_APESSION | C | 1 | Status da aprovacao: L=Liberada, B=Bloqueada, R=Residuo |
| C1_QECON | N | 12,2 | Quantidade economica |
| C1_IMPORT | C | 1 | Importacao (S/N) |
| C1_OP | C | 13 | Ordem de producao vinculada |
| C1_GRUPCOM | C | 3 | Grupo de compras |
| C1_TPSC | C | 3 | Tipo de solicitacao de compra |

**Indices principais:**
- Ordem 1: `C1_FILIAL + C1_NUM + C1_ITEM`
- Ordem 2: `C1_FILIAL + C1_PRODUTO + C1_NUM + C1_ITEM`
- Ordem 3: `C1_FILIAL + C1_EMISSAO + C1_NUM + C1_ITEM`
- Ordem 4: `C1_FILIAL + C1_CODCOMP + C1_NUM + C1_ITEM`

---

### SC7 - Itens do Pedido de Compra

Armazena os itens dos pedidos de compra. Cada registro e um item do pedido, vinculado a um fornecedor.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| C7_FILIAL | C | 8 | Filial |
| C7_NUM | C | 6 | Numero do pedido |
| C7_ITEM | C | 4 | Item do pedido |
| C7_PRODUTO | C | 15 | Codigo do produto |
| C7_DESCRI | C | 30 | Descricao do produto |
| C7_UM | C | 2 | Unidade de medida |
| C7_QUANT | N | 12,2 | Quantidade |
| C7_QUJE | N | 12,2 | Quantidade ja entregue |
| C7_PRECO | N | 14,2 | Preco unitario |
| C7_TOTAL | N | 14,2 | Valor total do item |
| C7_IPI | N | 5,2 | Percentual de IPI |
| C7_VALIPI | N | 14,2 | Valor de IPI |
| C7_ICMS | N | 5,2 | Percentual de ICMS |
| C7_VALICM | N | 14,2 | Valor de ICMS |
| C7_FORNECE | C | 6 | Codigo do fornecedor |
| C7_LOJA | C | 2 | Loja do fornecedor |
| C7_COND | C | 3 | Condicao de pagamento |
| C7_CONTATO | C | 20 | Contato no fornecedor |
| C7_DATPRF | D | 8 | Data de previsao de entrega |
| C7_EMISSAO | D | 8 | Data de emissao |
| C7_NUMSC | C | 6 | Numero da SC vinculada |
| C7_ITEMSC | C | 4 | Item da SC vinculada |
| C7_CC | C | 9 | Centro de custo |
| C7_CONTA | C | 20 | Conta contabil |
| C7_ITEMCTA | C | 9 | Item contabil |
| C7_CLVL | C | 9 | Classe de valor |
| C7_RESIDUO | C | 1 | Residuo (S/N) |
| C7_COTEFET | C | 6 | Numero da cotacao efetivada |
| C7_APESSION | C | 1 | Status aprovacao: L=Liberado, B=Bloqueado, R=Residuo |
| C7_LOCAL | C | 2 | Armazem destino |
| C7_NUMCOT | C | 6 | Numero da cotacao |
| C7_ITEMCOT | C | 4 | Item da cotacao |
| C7_TES | C | 3 | Tipo de entrada/saida (TES) |
| C7_CODCOMP | C | 25 | Codigo do comprador |
| C7_GRUPCOM | C | 3 | Grupo de compras |
| C7_OBSM | M | 10 | Observacoes (memo) |
| C7_TPSC | C | 3 | Tipo de compra |

**Indices principais:**
- Ordem 1: `C7_FILIAL + C7_NUM + C7_ITEM`
- Ordem 2: `C7_FILIAL + C7_FORNECE + C7_LOJA + C7_NUM + C7_ITEM`
- Ordem 3: `C7_FILIAL + C7_EMISSAO + C7_NUM + C7_ITEM`
- Ordem 4: `C7_FILIAL + C7_PRODUTO + C7_NUM + C7_ITEM`
- Ordem 5: `C7_FILIAL + C7_NUMSC + C7_ITEMSC`

---

### SC8 - Cotacoes

Armazena os itens de cotacao enviados aos fornecedores. Cada registro representa a proposta de um fornecedor para um item cotado.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| C8_FILIAL | C | 8 | Filial |
| C8_NUM | C | 6 | Numero da cotacao |
| C8_ITEM | C | 4 | Item da cotacao |
| C8_PRODUTO | C | 15 | Codigo do produto |
| C8_DESCRI | C | 30 | Descricao do produto |
| C8_UM | C | 2 | Unidade de medida |
| C8_QUANT | N | 12,2 | Quantidade cotada |
| C8_PRECO | N | 14,2 | Preco unitario proposto |
| C8_TOTAL | N | 14,2 | Valor total do item |
| C8_FORNECE | C | 6 | Codigo do fornecedor |
| C8_LOJA | C | 2 | Loja do fornecedor |
| C8_COND | C | 3 | Condicao de pagamento |
| C8_DATPRF | D | 8 | Data prevista de entrega |
| C8_EMISSAO | D | 8 | Data de emissao |
| C8_NUMSC | C | 6 | Numero da SC origem |
| C8_ITEMSC | C | 4 | Item da SC origem |
| C8_IPI | N | 5,2 | Percentual IPI |
| C8_ICMS | N | 5,2 | Percentual ICMS |
| C8_PRAZO | N | 3 | Prazo de entrega em dias |
| C8_APROV | C | 1 | Aprovada: S=Sim, N=Nao |
| C8_TOTPCO | N | 14,2 | Valor total do pedido de cotacao |
| C8_ITEMPCO | N | 14,2 | Valor total por item do pedido de cotacao |
| C8_CODGRP | C | 3 | Grupo de compras |
| C8_CODITE | C | 4 | Item do grupo |
| C8_TAXAFIN | N | 6,2 | Taxa de financiamento |

**Indices principais:**
- Ordem 1: `C8_FILIAL + C8_NUM + C8_ITEM + C8_FORNECE + C8_LOJA`
- Ordem 2: `C8_FILIAL + C8_PRODUTO + C8_NUM`
- Ordem 3: `C8_FILIAL + C8_FORNECE + C8_LOJA + C8_NUM`

---

### SA5 - Amarracao Produto x Fornecedor

Registra o vinculo entre produtos e seus respectivos fornecedores, incluindo historico de precos, condicoes e avaliacao de qualificacao.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| A5_FILIAL | C | 8 | Filial |
| A5_FORNECE | C | 6 | Codigo do fornecedor |
| A5_LOJA | C | 2 | Loja do fornecedor |
| A5_PRODUTO | C | 15 | Codigo do produto |
| A5_NOMPROD | C | 30 | Descricao do produto |
| A5_CODPRF | C | 20 | Codigo do produto no fornecedor |
| A5_COND | C | 3 | Condicao de pagamento padrao |
| A5_PRECO | N | 14,2 | Ultimo preco praticado |
| A5_QUANT | N | 12,2 | Quantidade minima de compra |
| A5_LEATIME | N | 4 | Lead time (prazo de entrega em dias) |
| A5_QUALIF | N | 3 | Qualificacao/nota do fornecedor |
| A5_DTREF | D | 8 | Data de referencia do preco |
| A5_PRIORI | N | 2 | Prioridade do fornecedor para este produto |

**Indices principais:**
- Ordem 1: `A5_FILIAL + A5_FORNECE + A5_LOJA + A5_PRODUTO`
- Ordem 2: `A5_FILIAL + A5_PRODUTO + A5_FORNECE + A5_LOJA`

---

### SA2 - Fornecedores (referencia)

Cadastro mestre de fornecedores, consultado em todo o ciclo de compras.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| A2_FILIAL | C | 8 | Filial |
| A2_COD | C | 6 | Codigo do fornecedor |
| A2_LOJA | C | 2 | Loja |
| A2_NOME | C | 40 | Razao social |
| A2_NREDUZ | C | 20 | Nome reduzido |
| A2_CGC | C | 14 | CNPJ/CPF |
| A2_INSCR | C | 18 | Inscricao estadual |
| A2_END | C | 40 | Endereco |
| A2_EST | C | 2 | Estado |
| A2_MUN | C | 30 | Municipio |
| A2_CEP | C | 8 | CEP |
| A2_TEL | C | 15 | Telefone |
| A2_EMAIL | C | 50 | E-mail |
| A2_CONTATO | C | 20 | Nome do contato |
| A2_TIPO | C | 1 | Tipo: F=Fisico, J=Juridico, X=Exterior |
| A2_COND | C | 3 | Condicao de pagamento padrao |
| A2_MSBLQL | C | 1 | Bloqueado (1=Sim, 2=Nao) |

**Indices principais:**
- Ordem 1: `A2_FILIAL + A2_COD + A2_LOJA`
- Ordem 2: `A2_FILIAL + A2_NOME`
- Ordem 3: `A2_FILIAL + A2_CGC`

---

### SD1 - Itens de Nota Fiscal de Entrada (referencia)

Armazena os itens do documento de entrada (NF). Gerada ao classificar o documento de entrada vinculado ao pedido de compra.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| D1_FILIAL | C | 8 | Filial |
| D1_DOC | C | 9 | Numero do documento |
| D1_SERIE | C | 3 | Serie |
| D1_FORNECE | C | 6 | Codigo do fornecedor |
| D1_LOJA | C | 2 | Loja do fornecedor |
| D1_COD | C | 15 | Codigo do produto |
| D1_ITEM | C | 4 | Item |
| D1_QUANT | N | 12,2 | Quantidade |
| D1_VUNIT | N | 14,2 | Valor unitario |
| D1_TOTAL | N | 14,2 | Valor total |
| D1_TES | C | 3 | Tipo de entrada/saida |
| D1_PEDIDO | C | 6 | Numero do pedido de compra vinculado |
| D1_ITEMPC | C | 4 | Item do pedido de compra |
| D1_LOCAL | C | 2 | Armazem destino |
| D1_DTDIGIT | D | 8 | Data de digitacao |
| D1_EMISSAO | D | 8 | Data de emissao da NF |

**Indices principais:**
- Ordem 1: `D1_FILIAL + D1_DOC + D1_SERIE + D1_FORNECE + D1_LOJA + D1_COD + D1_ITEM`
- Ordem 2: `D1_FILIAL + D1_COD + D1_DOC + D1_SERIE`

---

### SF1 - Cabecalho de NF de Entrada (referencia)

Cabecalho da nota fiscal de entrada, criada no momento da classificacao do documento de entrada.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| F1_FILIAL | C | 8 | Filial |
| F1_DOC | C | 9 | Numero do documento |
| F1_SERIE | C | 3 | Serie |
| F1_FORNECE | C | 6 | Codigo do fornecedor |
| F1_LOJA | C | 2 | Loja do fornecedor |
| F1_EMISSAO | D | 8 | Data de emissao |
| F1_DTDIGIT | D | 8 | Data de digitacao |
| F1_VALBRUT | N | 14,2 | Valor bruto |
| F1_VALMERC | N | 14,2 | Valor das mercadorias |
| F1_FRETE | N | 14,2 | Valor do frete |
| F1_SEGURO | N | 14,2 | Valor do seguro |
| F1_DESPESA | N | 14,2 | Despesas acessorias |
| F1_DESCONT | N | 14,2 | Desconto |
| F1_VALICM | N | 14,2 | Valor de ICMS |
| F1_VALIPI | N | 14,2 | Valor de IPI |
| F1_TIPO | C | 1 | Tipo da NF: N=Normal, D=Devolucao, C=Complemento |
| F1_COND | C | 3 | Condicao de pagamento |
| F1_CHVNFE | C | 44 | Chave da NFe |

**Indices principais:**
- Ordem 1: `F1_FILIAL + F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA + F1_TIPO`
- Ordem 2: `F1_FILIAL + F1_FORNECE + F1_LOJA + F1_DOC`

---

### SE2 - Titulos a Pagar (referencia)

Titulos financeiros gerados automaticamente ao classificar o documento de entrada, representando as obrigacoes de pagamento ao fornecedor.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| E2_FILIAL | C | 8 | Filial |
| E2_PREFIXO | C | 3 | Prefixo do titulo |
| E2_NUM | C | 9 | Numero do titulo |
| E2_PARCELA | C | 1 | Parcela |
| E2_TIPO | C | 3 | Tipo do titulo (NF, DP, etc.) |
| E2_FORNECE | C | 6 | Codigo do fornecedor |
| E2_LOJA | C | 2 | Loja do fornecedor |
| E2_EMISSAO | D | 8 | Data de emissao |
| E2_VENCTO | D | 8 | Data de vencimento |
| E2_VALOR | N | 14,2 | Valor do titulo |
| E2_SALDO | N | 14,2 | Saldo em aberto |
| E2_HIST | C | 40 | Historico |
| E2_NATUREZ | C | 10 | Natureza financeira |

**Indices principais:**
- Ordem 1: `E2_FILIAL + E2_PREFIXO + E2_NUM + E2_PARCELA + E2_TIPO + E2_FORNECE + E2_LOJA`
- Ordem 2: `E2_FILIAL + E2_FORNECE + E2_LOJA + E2_PREFIXO + E2_NUM`

---

## Rotinas Principais

### MATA110 - Solicitacao de Compras

**O que faz:** Permite incluir, alterar, excluir e visualizar solicitacoes de compra. E o ponto de partida do ciclo de compras, formalizando a necessidade de aquisicao de materiais ou servicos.

**Tabelas envolvidas:**
- SC1 (escrita) - Solicitacoes de Compra
- SB1 (leitura) - Cadastro de Produtos
- SA2 (leitura) - Cadastro de Fornecedores
- CTT (leitura) - Centro de Custo

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_SCLCNI | Habilita controle de numeracao sequencial da SC por filial |
| MV_SEQESP | Habilita sequencia especifica para numeracao de SC |
| MV_RESTSOL | Restringe solicitantes de produtos |
| MV_RESTCOM | Restringe acesso as solicitacoes por comprador |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT110BRW | Adiciona opcoes no menu da rotina |
| MT110VLD | Valida o registro na Solicitacao de Compras |
| ITMT110 | Inclui campos customizados na SC1 |
| MT106SC1 | Apos gravacao da SC, manipula informacoes em tabelas relacionadas |

---

### MATA131 - Gerar Cotacoes

**O que faz:** Gera cotacoes a partir das solicitacoes de compra aprovadas. Envia propostas aos fornecedores vinculados (via SA5 - Produto x Fornecedor) para que informem precos, prazos e condicoes. Pode enviar e-mail automatico ao fornecedor se `MV_ENVCOT` estiver habilitado.

**Tabelas envolvidas:**
- SC1 (leitura) - Solicitacoes de Compra (origem)
- SC8 (escrita) - Cotacoes
- SA5 (leitura) - Amarracao Produto x Fornecedor
- SA2 (leitura) - Cadastro de Fornecedores

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_ENVCOT | Envia e-mail de cotacao automaticamente ao fornecedor |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT131VAL | Verifica se a cotacao pode ser gerada |
| MT131MNU | Inclusao de novas rotinas na geracao de cotacoes |
| MT131C8 | Exibe informacoes de outros campos da SC8 no grid de fornecedores |

---

### MATA130 - Analise de Cotacoes (Atualizar Cotacoes)

**O que faz:** Permite registrar as respostas dos fornecedores (precos, prazos, condicoes) nas cotacoes geradas. Compara propostas lado a lado, possibilitando selecionar a melhor oferta para cada item. Fornece historico de analise do fornecedor: saldo historico, maiores compras, titulos pagos, faturamento, informacoes fiscais, garantia estendida, ultimos pedidos e consumo medio.

**Tabelas envolvidas:**
- SC8 (leitura/escrita) - Cotacoes
- SA5 (leitura) - Amarracao Produto x Fornecedor
- SA2 (leitura) - Cadastro de Fornecedores
- SC1 (leitura) - Solicitacoes de Compra
- SC7 (escrita) - Pedido de Compra (quando gera pedido a partir da analise)

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT130COR | Regras para cores dos status na MarkBrowse |
| AVALCOT | Manipula dados da SC7 ao gerar pedido a partir da cotacao |
| MT130FIM | Executado ao finalizar a analise de cotacao |

---

### MATA120 / MATA121 - Pedido de Compras

**O que faz:** MATA120 e a rotina de processamento (backend) e MATA121 e a interface de manutencao (browse/tela). O Pedido de Compra e um contrato formal entre a empresa e o fornecedor, representando as condicoes da negociacao: material, quantidade, qualidade, frequencia de entregas, prazos, precos, local de entrega, tributacao, entre outros.

O pedido pode ser gerado:
- Manualmente (inclusao direta)
- A partir de uma Solicitacao de Compra previamente cadastrada
- Automaticamente a partir da analise da melhor cotacao (MATA130)

**Tabelas envolvidas:**
- SC7 (escrita) - Itens do Pedido de Compra
- SC1 (leitura/escrita) - Solicitacoes de Compra (atualiza saldo atendido)
- SC8 (leitura) - Cotacoes (quando originado de cotacao)
- SA2 (leitura) - Cadastro de Fornecedores
- SA5 (leitura) - Amarracao Produto x Fornecedor
- SB1 (leitura) - Cadastro de Produtos
- SE4 (leitura) - Condicoes de Pagamento

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_RESTINC | Restringe criacao de pedido sem solicitacao de compra |
| MV_RESTPED | Restringe manutencao do pedido de compra |
| MV_RESTNFE | Restringe recebimento de pedido bloqueado |
| MV_ARRPEDC | Arredondamento do valor total do Pedido de Compra |
| MV_ALTPRCC | Controla alteracao do preco na classificacao de NF/pre-nota |
| MV_PCNFE | Obrigatoriedade de informar numero do PC na pre-nota |
| MV_ALTPEDC | Controla se usuario pode modificar pedidos de compra ja atendidos |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT121BRW | Adiciona opcoes no menu da rotina MATA121 |
| MT120F | Manipula dados na SC7 apos gravacao do pedido |
| MT120OK | Validacoes especificas de usuario |
| MT120TEL | Manipula tela do pedido de compra |
| MT120APV | Manipula grupo de aprovacao e saldo de pedido |
| MT120PCOK | Valida Pedido de Compra |
| MT120VSC | Manipula array de SC ou Contrato de Parceria na busca pelo fornecedor |
| WFW120P | Manipula dados gravados na SC7 (workflow) |
| GRVSC7 | Modifica valores da tabela SC7 |
| MTA120G1 | Grava informacoes contidas nas variaveis do array |
| A120FILT | Altera a ordem de indice na tabela SC7 |
| A120F4FI | Disponibiliza filtro em tabelas SC1 e SC3 |
| CN120GSC | Grava informacoes especificas na SC7 (projeto CNI) |

---

### MATA094 - Liberacao de Documentos (Aprovacao de Compras)

**O que faz:** Controla o fluxo de aprovacao/liberacao dos documentos de compra (SC, PC, Autorização de Entrega). Somente usuarios registrados como Aprovadores (MATA095) podem liberar documentos. Utiliza o conceito de alcadas (limites de aprovacao por valor) e grupos de aprovacao (MATA114).

Documentos sujeitos a aprovacao:
- Solicitacao de Compra (SC1)
- Pedido de Compra (SC7)
- Contrato de Parceria
- Autorização de Entrega
- Documento de Entrada com divergencia

**Tabelas envolvidas:**
- SC1 (leitura/escrita) - Solicitacoes (atualiza status C1_APESSION)
- SC7 (leitura/escrita) - Pedidos de Compra (atualiza status C7_APESSION)
- SAL (leitura) - Alcadas
- SCR (leitura) - Aprovadores
- DBL (leitura) - Entidades de aprovacao

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_ALTPDOC | Determina quais documentos sao validos para o grupo de aprovacao |
| MV_APRIPPC | Aprovacao automatica via parametro |

**Rotinas auxiliares de aprovacao:**
| Rotina | Descricao |
|--------|-----------|
| MATA095 | Cadastro de Aprovadores |
| MATA114 | Cadastro de Grupos de Aprovacao |

---

### MATA140 - Pre-Nota de Entrada (Pre-Documento de Entrada)

**O que faz:** Registro preliminar dos dados basicos do documento fiscal que sera recebido pela empresa: tipo da nota, numero do documento, data de emissao, fornecedor, especie, estado de origem, produtos, quantidades, valores unitarios e totais, tributos, descontos, frete, despesas e pedidos de compra vinculados.

A pre-nota **nao gera** lancamentos fiscais, contabeis ou financeiros e **nao atualiza** o estoque. Seu objetivo e facilitar e agilizar o recebimento de materiais no Documento de Entrada (MATA103).

**Tabelas envolvidas:**
- SF1 (escrita) - Cabecalho NF Entrada (pre-nota)
- SD1 (escrita) - Itens NF Entrada (pre-nota)
- SC7 (leitura) - Pedidos de Compra (vinculo)
- SA2 (leitura) - Cadastro de Fornecedores

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_PCNFE | Obrigatoriedade de vincular pedido de compra a pre-nota |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT140CAB | Preenche automaticamente o cabecalho da pre-nota |
| MT140PC | Manipula parametro MV_PCNFE |
| CM120GR | Permite cancelar inclusao/alteracao da pre-nota |
| MT140LPC | Manipula vinculo com pedido de compra |
| A140IPED | Campos para vinculo com pedido de compras |

---

### MATA103 - Documento de Entrada (Nota Fiscal de Entrada)

**O que faz:** Classificacao e efetivacao do documento fiscal de entrada. E nesta rotina que o recebimento e consumado, gerando movimentacao de estoque (SD3), lancamento fiscal (SF3/SFT), titulo a pagar (SE2) e lancamento contabil (CT2). Pode ser vinculado a um pedido de compra (via F5/F6).

Quando o produto possui controle de qualidade e a qualificacao do fornecedor no SA5 nao atinge a nota minima do produto, o lote e direcionado para o armazem de controle de qualidade (parametro `MV_CQ`).

**Tabelas envolvidas:**
- SF1 (escrita) - Cabecalho NF Entrada
- SD1 (escrita) - Itens NF Entrada
- SC7 (leitura/escrita) - Pedido de Compra (atualiza C7_QUJE)
- SD3 (escrita) - Movimentacoes de Estoque
- SE2 (escrita) - Titulos a Pagar
- SFT (escrita) - Livros Fiscais
- CT2 (escrita) - Lancamentos Contabeis
- SA2 (leitura) - Cadastro de Fornecedores
- SB1 (leitura) - Cadastro de Produtos
- SB2 (leitura/escrita) - Saldos por Armazem

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_TESPCNF | TES que nao necessita de PC amarrado |
| MV_CQ | Armazem de controle de qualidade |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MT100F4 | Entrada de Notas Fiscais de Compra |
| A103CUST | Manipula custo de entrada |
| MT103NAT | Altera natureza no documento de entrada |
| MT103QPC | Manipula query ao selecionar Pedido de Compra no Documento de Entrada |
| MA103F4I | Importacao de pedidos de compra |

---

### MATA061 - Amarracao Produto x Fornecedor

**O que faz:** Cadastro e manutencao do vinculo entre produtos e fornecedores na tabela SA5. Registra historico dos ultimos 12 precos de compra, condicoes de pagamento acordadas, datas e valores de compras, qualificacao do fornecedor, lead time, entre outros.

Essas informacoes sao utilizadas na geracao automatica de cotacoes (MATA131) e na avaliacao de qualidade no recebimento (MATA103).

**Tabelas envolvidas:**
- SA5 (escrita) - Amarracao Produto x Fornecedor
- SA2 (leitura) - Cadastro de Fornecedores
- SB1 (leitura) - Cadastro de Produtos

---

## Processos de Negocio

### Fluxo Completo de Compras (com cotacao)

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  1. Solicitacao  │────>│  2. Cotacao      │────>│  3. Analise de   │
│  de Compra       │     │  (Gerar)         │     │  Cotacao          │
│  MATA110 / SC1   │     │  MATA131 / SC8   │     │  MATA130 / SC8    │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                          │
┌─────────────────┐     ┌─────────────────┐     ┌────────v────────┐
│  6. Titulo a     │<────│  5. Documento    │<────│  4. Pedido de    │
│  Pagar           │     │  de Entrada      │     │  Compra           │
│  SE2             │     │  MATA103/SD1/SF1 │     │  MATA120-121/SC7  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

#### Passo 1: Solicitacao de Compra (MATA110)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA110 |
| **Tabelas** | SC1 (escrita), SB1 (leitura) |
| **O que acontece** | Usuario formaliza necessidade de compra informando produto, quantidade, data de necessidade, centro de custo, armazem destino e observacoes. Se alcadas estiverem habilitadas (via cadastro de Grupos de Aprovacao - MATA114), a SC fica bloqueada (C1_APESSION = "B") aguardando liberacao. |
| **Resultado** | Registro na SC1 com status pendente ou liberado |

#### Passo 2: Geracao de Cotacao (MATA131)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA131 |
| **Tabelas** | SC1 (leitura), SC8 (escrita), SA5 (leitura), SA2 (leitura) |
| **O que acontece** | O comprador seleciona SCs liberadas e gera cotacoes para os fornecedores vinculados ao produto (SA5). Se `MV_ENVCOT` estiver ativo, e-mail e enviado automaticamente ao fornecedor. Multiplos usuarios podem gerar cotacoes simultaneamente; SCs marcadas ficam indisponiveis para outros usuarios. |
| **Resultado** | Registros na SC8 (um por item x fornecedor) |

#### Passo 3: Analise de Cotacao (MATA130)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA130 |
| **Tabelas** | SC8 (leitura/escrita), SA5 (leitura), SA2 (leitura) |
| **O que acontece** | O comprador registra os precos, prazos e condicoes recebidos de cada fornecedor. O sistema permite comparacao lado a lado e pode sugerir o melhor fornecedor. Ao aprovar a cotacao, pode gerar automaticamente o Pedido de Compra. |
| **Resultado** | SC8 atualizada com precos e cotacao aprovada (C8_APROV = "S"); opcionalmente gera SC7 |

#### Passo 4: Pedido de Compra (MATA120/MATA121)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA120 (processamento) / MATA121 (interface) |
| **Tabelas** | SC7 (escrita), SC1 (leitura/escrita), SC8 (leitura), SA2 (leitura) |
| **O que acontece** | Gerado manualmente, a partir da SC ou da cotacao aprovada. O pedido registra fornecedor, produto, quantidade, preco, condicao de pagamento, prazo de entrega e tributos. Se alcadas estiverem habilitadas, o PC fica bloqueado (C7_APESSION = "B") ate liberacao (MATA094). A SC vinculada tem C1_QUJE atualizada. |
| **Resultado** | Registros na SC7; SC1 atualizada |

#### Passo 5: Documento de Entrada (MATA103)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA103 |
| **Tabelas** | SF1 (escrita), SD1 (escrita), SC7 (escrita), SD3 (escrita), SE2 (escrita), SFT (escrita), CT2 (escrita) |
| **O que acontece** | Ao receber a NF do fornecedor, o usuario classifica o documento vinculando ao pedido de compra. A classificacao gera simultaneamente: movimentacao de estoque (SD3), titulo a pagar (SE2), escrituracao fiscal (SFT) e lancamentos contabeis (CT2). O saldo do pedido (C7_QUJE) e atualizado. |
| **Resultado** | NF registrada (SF1/SD1), estoque atualizado, financeiro gerado, fiscal escriturado |

**Nota:** Opcionalmente, antes do MATA103 pode-se usar MATA140 (Pre-Nota de Entrada) para registro preliminar dos dados da NF sem gerar lancamentos.

#### Passo 6: Titulo a Pagar (SE2)

| Aspecto | Detalhe |
|---------|---------|
| **Tabelas** | SE2 (gerada automaticamente no passo 5) |
| **O que acontece** | O titulo a pagar e gerado automaticamente na classificacao do documento de entrada, conforme condicao de pagamento (SE4). O desdobramento em parcelas segue a regra da condicao. O titulo fica disponivel para o modulo Financeiro (SIGAFIN) para baixa/pagamento. |
| **Resultado** | Titulos em SE2 com vencimentos e valores conforme condicao de pagamento |

### Fluxo Simplificado (sem cotacao)

```
Solicitacao de Compra (SC1) → Pedido de Compra (SC7) → Documento de Entrada (SD1/SF1) → Titulo a Pagar (SE2)
```

Quando `MV_RESTINC` estiver desabilitado, o pedido pode ser criado diretamente sem necessidade de SC previa. Quando habilitado, exige SC mas pode-se pular a etapa de cotacao.

---

## Regras de Negocio

### Campos obrigatorios por rotina

**Solicitacao de Compra (MATA110 - SC1):**
- C1_PRODUTO (Codigo do produto)
- C1_QUANT (Quantidade)
- C1_DATPRF (Data de necessidade)
- C1_LOCAL (Armazem)

**Pedido de Compra (MATA120/121 - SC7):**
- C7_PRODUTO (Codigo do produto)
- C7_QUANT (Quantidade)
- C7_PRECO (Preco unitario)
- C7_FORNECE + C7_LOJA (Fornecedor)
- C7_COND (Condicao de pagamento)
- C7_TES (Tipo de Entrada/Saida)

**Documento de Entrada (MATA103 - SD1):**
- D1_COD (Codigo do produto)
- D1_QUANT (Quantidade)
- D1_VUNIT (Valor unitario)
- D1_TES (Tipo de Entrada/Saida)
- D1_DOC (Numero do documento)
- D1_SERIE (Serie da NF)

### Validacoes principais

| Validacao | Descricao |
|-----------|-----------|
| Saldo de SC | Ao gerar pedido vinculado a SC, a quantidade do pedido nao pode ultrapassar o saldo disponivel (C1_QUANT - C1_QUJE) |
| Saldo de PC | Ao classificar documento de entrada, a quantidade nao pode ultrapassar o saldo do pedido (C7_QUANT - C7_QUJE), a menos que parametrizado para permitir |
| Aprovacao/Alcada | Se controle de alcada estiver ativo, documentos bloqueados nao podem seguir no fluxo ate liberacao pelo aprovador |
| Amarracao Produto x Fornecedor | Se `MV_RESTINC` exigir, o fornecedor deve estar vinculado ao produto no SA5 |
| Fornecedor bloqueado | Nao permite gerar pedido para fornecedor com A2_MSBLQL = "1" |
| Duplicidade de NF | Verifica duplicidade de numero de NF por fornecedor (validacao nativa do sistema) |
| Residuo | Itens marcados como residuo (C7_RESIDUO = "S" ou C1_APESSION = "R") nao participam de novos pedidos/cotacoes |

### Gatilhos SX7 relevantes

| Campo origem | Campo destino | Regra | Tabela lookup |
|-------------|---------------|-------|---------------|
| C7_PRODUTO | C7_DESCRI | SB1->B1_DESC | SB1 |
| C7_PRODUTO | C7_UM | SB1->B1_UM | SB1 |
| C7_FORNECE | C7_CONTATO | SA2->A2_CONTATO | SA2 |
| C1_PRODUTO | C1_DESCRI | SB1->B1_DESC | SB1 |
| C1_PRODUTO | C1_UM | SB1->B1_UM | SB1 |
| C7_QUANT * C7_PRECO | C7_TOTAL | Calculado | - |
| D1_COD | D1_DESCRI | SB1->B1_DESC | SB1 |

### Pontos de entrada mais utilizados no modulo

| Ponto de Entrada | Rotina | Descricao |
|------------------|--------|-----------|
| MT110BRW | MATA110 | Customiza menu da Solicitacao de Compras |
| MT110VLD | MATA110 | Validacao customizada na SC |
| MT121BRW | MATA121 | Customiza menu do Pedido de Compras |
| MT120F | MATA120 | Pos-gravacao do Pedido de Compras na SC7 |
| MT120OK | MATA120 | Validacao customizada no Pedido de Compras |
| MT120PCOK | MATA120 | Validacao do Pedido de Compra |
| MT131VAL | MATA131 | Validacao da geracao de cotacao |
| MT130FIM | MATA130 | Pos-analise de cotacao |
| AVALCOT | MATA130 | Manipula SC7 ao gerar pedido pela cotacao |
| MT140CAB | MATA140 | Preenche cabecalho da pre-nota |
| MT140LPC | MATA140 | Manipula vinculo com PC na pre-nota |
| A103CUST | MATA103 | Manipula custo de entrada |
| MT103QPC | MATA103 | Manipula query de selecao de PC no Documento de Entrada |
| MT097GRV | MATA094 | Substitui gravacao nos processos de compras (aprovacao) |
| GRVSC7 | MATA120 | Modifica valores gravados na SC7 |

---

## Integracoes

### Compras → Estoque

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na classificacao do Documento de Entrada (MATA103) |
| **O que acontece** | Gera movimentacao na SD3 (Movimentacoes de Estoque) do tipo Entrada. Atualiza saldo do produto no armazem (SB2). O tipo de movimento e definido pela TES (Tipo de Entrada/Saida) informada no item da NF |
| **Tabelas afetadas** | SD3 (movimentacao), SB2 (saldo por armazem), SB9 (saldo consolidado) |
| **Controles** | Se controle de lote/sublote estiver ativo (B1_RASTRO), exige informacao de lote. Se qualidade ativa, pode direcionar para armazem CQ (MV_CQ) |

### Compras → Financeiro

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na classificacao do Documento de Entrada (MATA103) |
| **O que acontece** | Gera titulo(s) a pagar na SE2, desdobrados conforme a condicao de pagamento (SE4). O prefixo e numero do titulo sao baseados no numero da NF. Natureza financeira e determinada pela TES |
| **Tabelas afetadas** | SE2 (Titulos a Pagar) |
| **Observacao** | O titulo fica disponivel para o modulo Financeiro (SIGAFIN) para bordero, pagamento e baixa |

### Compras → Fiscal

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na classificacao do Documento de Entrada (MATA103) |
| **O que acontece** | Gera escrituracao no livro de entradas (SFT/SF3). Registra valores de ICMS, IPI, PIS, COFINS e demais tributos conforme configuracao da TES e natureza de operacao (SED). NFe recebida pode ser importada via XML |
| **Tabelas afetadas** | SFT (Livros Fiscais), SF3 (Resumo de NF) |
| **Observacao** | Integra com o modulo SIGAFIS para apuracao de impostos e obrigacoes acessorias (SPED, EFD) |

### Compras → Contabilidade

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na classificacao do Documento de Entrada (MATA103), se contabilizacao online estiver habilitada |
| **O que acontece** | Gera lancamentos contabeis na CT2, debitando as contas de estoque/despesa e creditando as contas de fornecedores/impostos, conforme Lancamento Padrao (CT5) configurado na TES |
| **Tabelas afetadas** | CT2 (Lancamentos Contabeis) |
| **Parametro** | Contabilizacao on-line controlada pela configuracao da TES e Lancamento Padrao (CT5) |

### Compras → Qualidade (CQ)

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na classificacao do Documento de Entrada (MATA103) |
| **O que acontece** | Se a qualificacao do fornecedor (SA5->A5_QUALIF) nao atingir a nota minima do produto (SB1->B1_QUALIF), o lote e direcionado para o armazem de CQ (MV_CQ). Se atingir, passa pela avaliacao de Skip-lote |
| **Tabelas afetadas** | SB2 (saldo no armazem CQ), SQA (inspecao de entrada) |

### Resumo das integracoes no Documento de Entrada

```
                         MATA103 - Documento de Entrada
                                     │
                    ┌────────────────┼────────────────┐
                    │                │                │
              ┌─────v─────┐   ┌─────v─────┐   ┌─────v─────┐
              │  Estoque   │   │ Financeiro│   │   Fiscal  │
              │ SD3 / SB2  │   │    SE2    │   │ SFT / SF3 │
              └───────────┘   └───────────┘   └───────────┘
                                                     │
                                              ┌──────v──────┐
                                              │Contabilidade│
                                              │     CT2     │
                                              └─────────────┘
```

---

## Cadastros Auxiliares

| Rotina | Descricao | Tabela |
|--------|-----------|--------|
| MATA061 | Amarracao Produto x Fornecedor | SA5 |
| MATA095 | Cadastro de Aprovadores | SCR |
| MATA114 | Grupo de Aprovacao | SAL / DBL |
| MATA020 | Cadastro de Fornecedores | SA2 |
| Tipo de Compra | Define politica de compra por tipo | SX5 tabela generica |
| Grupo de Compras | Segmenta compradores por grupo | SX5 tabela generica |

---

## Parametros Globais do Modulo (MV_*)

| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| MV_RESTINC | C | Restringe criacao de PC sem SC (S/N) |
| MV_RESTPED | C | Restringe manutencao de PC (S/N) |
| MV_RESTNFE | C | Restringe recebimento de PC bloqueado (S/N) |
| MV_RESTSOL | C | Restringe solicitantes de produtos (S/N) |
| MV_RESTCOM | C | Restringe acesso as SCs por comprador (S/N) |
| MV_ENVCOT | C | Envia e-mail de cotacao ao fornecedor (S/N) |
| MV_PCNFE | C | Obrigatoriedade de PC na pre-nota (S/N) |
| MV_ARRPEDC | C | Arredondamento do valor total do PC (ROUND/NOROUND) |
| MV_ALTPRCC | C | Controla alteracao do preco na classificacao de NF/pre-nota |
| MV_ALTPEDC | C | Controla se usuario pode modificar pedidos de compra ja atendidos |
| MV_CQ | C | Codigo do armazem de controle de qualidade |
| MV_TESPCNF | C | TES que nao necessita de PC amarrado |
| MV_SCLCNI | L | Controle de numeracao sequencial da SC por filial |
| MV_SEQESP | L | Sequencia especifica para numeracao de SC |
| MV_APRIPPC | C | Aprovacao automatica via parametro |
| MV_ALTPDOC | L | Determina quais documentos sao validos para o grupo de aprovacao |
