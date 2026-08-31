# Modulo de Manutencao de Ativos (MNT)

## Visao Geral

O modulo de Manutencao de Ativos (SIGAMNT) do TOTVS Protheus e uma solucao completa para o Planejamento e Controle de Manutencao (PCM) de ativos industriais e gestao de frotas. Ele abrange desde o cadastro de bens/equipamentos ate o controle de ordens de servico corretivas, preventivas, preditivas e de lubrificacao, integrando-se diretamente com os modulos de Estoque, Compras, Ativo Fixo, PCP, Financeiro, RH e TMS.

**Prefixo do modulo:** MNT
**Sigla do ambiente:** SIGAMNT
**Prefixo das rotinas:** MNTA0xx (cadastros), MNTA1xx (manutencao), MNTA2xx (solicitacoes), MNTA3xx (planos), MNTA4xx (ordens de servico), MNTC8xx (consultas/custos), MNTR6xx (relatorios)

### Ciclo principal de manutencao

```
Cadastro de Bens → Cadastro de Manutencao → Plano Preventivo → Geracao de O.S. → Execucao (Insumos/MDO) → Encerramento → Historico
```

O modulo suporta os seguintes tipos de manutencao:
- **Corretiva:** Reparo imediato apos falha (MNTA420)
- **Preventiva:** Manutencao programada por tempo ou contador (MNTA410/MNTA330)
- **Preditiva:** Baseada em monitoramento de condicao
- **Lubrificacao:** Plano especifico de lubrificacao de equipamentos

---

## Tabelas Principais

### ST9 - Bens (Ativos/Equipamentos)

Cadastro mestre de bens e equipamentos gerenciados pelo modulo de manutencao. Cada registro representa um ativo fisico que sera alvo de manutencao. Suporta categorias: equipamentos, veiculos, locais e ferramentas.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| T9_FILIAL | C | 2 | Filial |
| T9_CODBEM | C | 16 | Codigo do bem/ativo |
| T9_NOME | C | 40 | Nome do bem |
| T9_CATBEM | C | 1 | Categoria: 1=Equipamento, 2=Veiculo, 3=Local, 4=Ferramenta |
| T9_STATUS | C | 2 | Status do bem |
| T9_DESTAT | C | 30 | Descricao do status |
| T9_CCUSTO | C | 9 | Centro de custo |
| T9_NOMCUST | C | 40 | Nome do centro de custo |
| T9_CENTRAB | C | 6 | Centro de trabalho |
| T9_NOMTRAB | C | 30 | Nome do centro de trabalho |
| T9_CODFAMI | C | 6 | Codigo da familia do bem |
| T9_NOMFAMI | C | 40 | Nome da familia |
| T9_TIPMOD | C | 10 | Tipo/modelo do bem |
| T9_DESMOD | C | 20 | Descricao do tipo/modelo |
| T9_FABRICA | C | 6 | Codigo do fabricante |
| T9_NOMFABR | C | 40 | Nome do fabricante |
| T9_FORNECE | C | 6 | Codigo do fornecedor |
| T9_LOJA | C | 2 | Loja do fornecedor |
| T9_NOMFORN | C | 50 | Nome do fornecedor |
| T9_MODELO | C | 10 | Modelo do equipamento |
| T9_SERIE | C | 15 | Numero de serie |
| T9_DTCOMPR | D | 8 | Data de compra |
| T9_VALCPA | N | 12 | Valor de compra |
| T9_DTGARAN | D | 8 | Data de vencimento da garantia |
| T9_PRGARAN | N | 6 | Prazo de garantia |
| T9_UNGARAN | C | 1 | Unidade da garantia: H=Hora, D=Dia, S=Semana, M=Mes, A=Ano, K=Km |
| T9_ESTRUTU | C | 1 | Possui estrutura (S/N) |
| T9_TEMCONT | C | 1 | Controle por contador: S=Sim, N=Nao, P=Principal, I=Indireto |
| T9_TPCONTA | C | 20 | Tipo de contador (Horimetro, Odometro, etc.) |
| T9_POSCONT | N | 9 | Posicao atual do contador |
| T9_CONTACU | N | 12 | Contador acumulado |
| T9_VARDIA | N | 6 | Variacao media diaria do contador |
| T9_LIMICON | N | 9 | Limite do contador (virada) |
| T9_SITMAN | C | 1 | Situacao para manutencao: A=Ativo, I=Inativo |
| T9_SITBEM | C | 1 | Situacao do bem: A=Ativo, I=Inativo, T=Transferido |
| T9_LOCAL | C | 6 | Local fisico |
| T9_CODIMOB | C | 14 | Codigo do ativo imobilizado (SN1) |
| T9_CHAPA | C | 20 | Chapa do imobilizado |
| T9_CODESTO | C | 15 | Codigo no estoque (SB1) |
| T9_LOCPAD | C | 2 | Armazem padrao |
| T9_CUSTOHO | N | 9 | Custo hora do equipamento |
| T9_CALENDA | C | 3 | Turno/calendario de trabalho |
| T9_PRIORID | C | 3 | Prioridade de producao |
| T9_TERCEIR | C | 1 | Manutencao por terceiro: 1=Sim, 2=Nao |
| T9_MOVIBEM | C | 1 | Bem movel (S/N) |
| T9_DTINSTA | D | 8 | Data de instalacao |
| T9_DTBAIXA | D | 8 | Data de baixa |
| T9_MTBAIXA | C | 4 | Motivo da baixa |
| T9_PLACA | C | 8 | Placa do veiculo |
| T9_CAPMAX | N | 7 | Capacidade do tanque (litros) |
| T9_MEDIA | N | 9 | Media de consumo (km/litro) |
| T9_TIPVEI | C | 2 | Tipo do veiculo |
| T9_CHASSI | C | 20 | Chassi do veiculo |
| T9_RENAVAM | C | 15 | Renavam |
| T9_BARCODE | C | 20 | Codigo de barras/QR Code |
| T9_PARTEDI | C | 1 | Controle de parte diaria: 1=Sim, 2=Nao |
| T9_LUBRIFI | C | 1 | Controle de abastecimento: 1=Sim, 2=Nao |
| T9_DESCRIC | M | 10 | Descricao detalhada (memo) |

**Indices principais:**
- Ordem 1: `T9_FILIAL + T9_CODBEM`
- Ordem 2: `T9_FILIAL + T9_NOME`
- Ordem 3: `T9_FILIAL + T9_CODFAMI + T9_CODBEM`
- Ordem 4: `T9_FILIAL + T9_CCUSTO + T9_CODBEM`

---

### STJ - Ordens de Servico de Manutencao

Armazena as ordens de servico (O.S.) de manutencao. Cada registro representa uma O.S. associada a um bem, contendo datas planejadas/reais de parada e manutencao, custos apurados e status de execucao.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| TJ_FILIAL | C | 2 | Filial |
| TJ_ORDEM | C | 6 | Numero da ordem de servico |
| TJ_PLANO | C | 6 | Codigo do plano de manutencao |
| TJ_TIPOOS | C | 1 | Tipo da O.S.: B=Bem, L=Local |
| TJ_CODBEM | C | 16 | Codigo do bem/ativo |
| TJ_NOMBEM | C | 40 | Nome do bem |
| TJ_SERVICO | C | 6 | Codigo do servico de manutencao |
| TJ_NOMSERV | C | 40 | Nome do servico |
| TJ_SEQRELA | C | 3 | Sequencia da manutencao |
| TJ_TIPO | C | 3 | Tipo de manutencao |
| TJ_NOMTIPO | C | 40 | Nome do tipo de manutencao |
| TJ_CODAREA | C | 6 | Area de manutencao |
| TJ_NOMAREA | C | 40 | Nome da area de manutencao |
| TJ_CCUSTO | C | 9 | Centro de custo |
| TJ_NOMCUST | C | 40 | Nome do centro de custo |
| TJ_CENTRAB | C | 6 | Centro de trabalho |
| TJ_NOMTRAB | C | 40 | Nome do centro de trabalho |
| TJ_PRIORID | C | 3 | Prioridade da manutencao |
| TJ_SITUACA | C | 1 | Situacao: P=Pendente, C=Cancelada, L=Liberada |
| TJ_TERMINO | C | 1 | Encerrada: S=Sim, N=Nao |
| TJ_DTORIGI | D | 8 | Data original da O.S. |
| TJ_DTPPINI | D | 8 | Data prevista inicio parada |
| TJ_HOPPINI | C | 5 | Hora prevista inicio parada |
| TJ_DTPPFIM | D | 8 | Data prevista fim parada |
| TJ_HOPPFIM | C | 5 | Hora prevista fim parada |
| TJ_DTPRINI | D | 8 | Data real inicio parada |
| TJ_HOPRINI | C | 5 | Hora real inicio parada |
| TJ_DTPRFIM | D | 8 | Data real fim parada |
| TJ_HOPRFIM | C | 5 | Hora real fim parada |
| TJ_DTMPINI | D | 8 | Data prevista inicio manutencao |
| TJ_HOMPINI | C | 5 | Hora prevista inicio manutencao |
| TJ_DTMPFIM | D | 8 | Data prevista fim manutencao |
| TJ_HOMPFIM | C | 5 | Hora prevista fim manutencao |
| TJ_DTMRINI | D | 8 | Data real inicio manutencao |
| TJ_HOMRINI | C | 5 | Hora real inicio manutencao |
| TJ_DTMRFIM | D | 8 | Data real fim manutencao |
| TJ_HOMRFIM | C | 5 | Hora real fim manutencao |
| TJ_CUSTMDO | N | 14,2 | Custo total de mao de obra |
| TJ_CUSTMAT | N | 14,2 | Custo de material de reposicao |
| TJ_CUSTMAA | N | 14,2 | Custo de material de apoio |
| TJ_CUSTMAS | N | 14,2 | Custo de material de substituicao |
| TJ_CUSTTER | N | 14,2 | Custo de servico terceirizado |
| TJ_CUSTFER | N | 9,2 | Custo de ferramentas |
| TJ_POSCONT | N | 9 | Posicao do contador no encerramento |
| TJ_CONTINI | N | 9 | Posicao do contador na abertura |
| TJ_CONTFIM | N | 9 | Posicao do contador no fechamento |
| TJ_DTULTMA | D | 8 | Data da ultima manutencao |
| TJ_COULTMA | N | 12 | Posicao do contador na ultima manutencao |
| TJ_SOLICI | C | 6 | Numero da solicitacao de servico origem |
| TJ_ORDEPAI | C | 6 | Numero da O.S. pai |
| TJ_BEMPAI | C | 16 | Codigo do bem pai |
| TJ_TERCEIR | C | 1 | Servico terceirizado (S/N) |
| TJ_STFOLUP | C | 6 | Codigo do status (follow-up) |
| TJ_DESTFLU | C | 20 | Descricao do status |
| TJ_IRREGU | C | 3 | Codigo da irregularidade |
| TJ_NIRREGU | C | 40 | Nome da irregularidade |
| TJ_VALATF | C | 1 | Transferido para Ativo Fixo |
| TJ_LUBRIFI | C | 1 | Plano de lubrificacao |
| TJ_USUARIO | C | 25 | Usuario responsavel |
| TJ_USUAINI | C | 25 | Usuario na abertura |
| TJ_USUAFIM | C | 25 | Usuario no encerramento |
| TJ_QTDREP | N | 9 | Quantidade de reprogramacoes |
| TJ_MOTREPR | C | 4 | Motivo da reprogramacao |
| TJ_FATURA | C | 1 | Status de faturamento |
| TJ_APROPRI | C | 1 | Status de apropriacao |
| TJ_PROJETO | C | 22 | Numero do projeto |
| TJ_OBSERVA | M | 10 | Observacoes (memo) |

**Indices principais:**
- Ordem 1: `TJ_FILIAL + TJ_ORDEM`
- Ordem 2: `TJ_FILIAL + TJ_CODBEM + TJ_ORDEM`
- Ordem 3: `TJ_FILIAL + TJ_PLANO + TJ_ORDEM`
- Chave unica: `TJ_FILIAL + TJ_ORDEM + TJ_PLANO + TJ_TIPOOS + TJ_CODBEM + TJ_SERVICO + TJ_SEQRELA`

---

### TQB - Solicitacoes de Servico

Armazena as solicitacoes de servico (S.S.) de manutencao. E o ponto de partida para registrar a necessidade de reparo ou melhoria em um ativo, antes da abertura formal de uma Ordem de Servico.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| TQB_FILIAL | C | 2 | Filial |
| TQB_SOLICI | C | 6 | Numero da solicitacao de servico |
| TQB_TIPOSS | C | 1 | Tipo: B=Bem, L=Local |
| TQB_CODBEM | C | 16 | Codigo do bem/local |
| TQB_NOMBEM | C | 40 | Nome do bem/local |
| TQB_CCUSTO | C | 9 | Centro de custo |
| TQB_NOMCUS | C | 40 | Nome do centro de custo |
| TQB_CENTRA | C | 6 | Centro de trabalho |
| TQB_NOMCTR | C | 30 | Nome do centro de trabalho |
| TQB_LOCALI | C | 6 | Localizacao |
| TQB_NOMLOC | C | 20 | Nome da localizacao |
| TQB_DTABER | D | 8 | Data de abertura |
| TQB_HOABER | C | 5 | Hora de abertura |
| TQB_USUARI | C | 30 | Nome do solicitante |
| TQB_CDSOLI | C | 6 | Codigo do solicitante |
| TQB_NMSOLI | C | 40 | Nome do solicitante |
| TQB_EMSOLI | C | 50 | E-mail do solicitante |
| TQB_RAMAL | C | 10 | Ramal do solicitante |
| TQB_SOLUCA | C | 1 | Status: P=Pendente, D=Distribuida, F=Fechada, C=Cancelada |
| TQB_CDSERV | C | 6 | Codigo do tipo de servico |
| TQB_NMSERV | C | 20 | Nome do tipo de servico |
| TQB_DESCSS | M | 80 | Descricao do problema/servico |
| TQB_TPSERV | C | 1 | Tipo da solicitacao: 1=Incidente, 2=Melhoria |
| TQB_PRIORI | C | 1 | Prioridade: A=Alta, M=Media, B=Baixa |
| TQB_CRITIC | N | 8 | Criticidade |
| TQB_FUNEXE | C | 6 | Codigo do supervisor/aprovador |
| TQB_NOMFUN | C | 40 | Nome do supervisor |
| TQB_CDEXEC | C | 25 | Codigo do executor |
| TQB_NMEXEC | C | 20 | Nome do executor |
| TQB_ORDEM | C | 6 | Numero da O.S. gerada |
| TQB_DTFECH | D | 8 | Data de fechamento |
| TQB_HOFECH | C | 5 | Hora de fechamento |
| TQB_TEMPO | C | 10 | Tempo de atendimento (HHH:MM:SS) |
| TQB_DESCSO | M | 80 | Descricao da solucao |
| TQB_POSCON | N | 9 | Posicao do contador 1 |
| TQB_POSCO2 | N | 9 | Posicao do contador 2 |
| TQB_PSAP | C | 1 | Avaliacao de pontualidade |
| TQB_PSAN | C | 1 | Avaliacao do atendimento |
| TQB_DTCANC | D | 8 | Data de cancelamento |
| TQB_HRCANC | C | 5 | Hora de cancelamento |
| TQB_CDCANC | C | 6 | Codigo do motivo de cancelamento |
| TQB_FOTO | C | 200 | Caminho da imagem |
| TQB_ORIGEM | C | 20 | Rotina de origem |

**Indices principais:**
- Ordem 1: `TQB_FILIAL + TQB_SOLICI`
- Ordem 2: `TQB_FILIAL + TQB_CODBEM + TQB_SOLICI`
- Ordem 3: `TQB_FILIAL + TQB_DTABER + TQB_SOLICI`

---

### STL - Detalhes da Ordem de Servico (Insumos)

Armazena os insumos (materiais, mao de obra, terceiros e ferramentas) previstos e realizados de cada Ordem de Servico. Cada registro representa um recurso consumido ou planejado.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| TL_FILIAL | C | 2 | Filial |
| TL_ORDEM | C | 6 | Numero da O.S. |
| TL_PLANO | C | 6 | Numero do plano |
| TL_SEQRELA | C | 3 | Sequencia (0=previsto, >0=realizado) |
| TL_TAREFA | C | 6 | Codigo da tarefa |
| TL_NOMTAR | C | 40 | Nome da tarefa |
| TL_TIPOREG | C | 1 | Tipo do insumo: P=Mao de obra, M=Material reposicao, F=Ferramenta, T=Terceiro, E=Material apoio |
| TL_NOMTREG | C | 11 | Nome do tipo |
| TL_CODIGO | C | 15 | Codigo do insumo (funcionario/produto/ferramenta) |
| TL_NOMCODI | C | 40 | Nome do insumo |
| TL_QUANTID | N | 9,2 | Quantidade consumida |
| TL_UNIDADE | C | 2 | Unidade de consumo |
| TL_CUSTO | N | 14,2 | Custo do recurso |
| TL_DESTINO | C | 1 | Destino do produto: A=Aplicacao, S=Substituicao, T=Terceiro |
| TL_DTINICI | D | 8 | Data inicio |
| TL_HOINICI | C | 5 | Hora inicio |
| TL_DTFIM | D | 8 | Data fim |
| TL_HOFIM | C | 5 | Hora fim |
| TL_LOCAL | C | 2 | Armazem origem |
| TL_LOTECTL | C | 10 | Lote da peca de reposicao |
| TL_NUMLOTE | C | 6 | Sublote |
| TL_NUMSERI | C | 20 | Numero de serie do produto |
| TL_ETAPA | C | 6 | Etapa de consumo |
| TL_NOMETAP | C | 20 | Nome da etapa |
| TL_GARANTI | C | 1 | Em garantia (S/N) |
| TL_NUMSC | C | 6 | Numero da solicitacao de compra |
| TL_ITEMSC | C | 4 | Item da solicitacao de compra |
| TL_NUMSA | C | 6 | Numero da solicitacao de armazem |
| TL_ITEMSA | C | 2 | Item da solicitacao de armazem |
| TL_NUMSEQ | C | 6 | Sequencia no SD3 |
| TL_CODBEM | C | 16 | Codigo do bem |
| TL_SERVICO | C | 6 | Codigo do servico |
| TL_PCTHREX | N | 6,2 | Percentual hora extra |
| TL_PERMDOE | N | 6,2 | Percentual execucao MDO |
| TL_NOTFIS | C | 9 | Numero da nota fiscal |
| TL_SERIE | C | 3 | Serie da nota fiscal |
| TL_FORNEC | C | 6 | Codigo do fornecedor |
| TL_LOJA | C | 2 | Loja do fornecedor |
| TL_REPFIM | C | 1 | Relatorio final (S/N) |
| TL_QUANREC | N | 3 | Quantidade de recursos |
| TL_USACALE | C | 1 | Usa calendario (S/N) |
| TL_OBSERVA | M | 10 | Observacoes (memo) |

**Indices principais:**
- Ordem 1: `TL_FILIAL + TL_ORDEM + TL_PLANO + TL_SEQRELA + TL_TIPOREG`
- Ordem 2: `TL_FILIAL + TL_CODIGO + TL_ORDEM`

---

### STF - Manutencao (Cadastro de Manutencao)

Armazena o cadastro de manutencoes vinculadas a cada bem. Define o que deve ser feito (servico), a periodicidade (tempo ou contador) e os insumos necessarios. E a base para geracao de planos preventivos.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| TF_FILIAL | C | 2 | Filial |
| TF_CODBEM | C | 16 | Codigo do bem |
| TF_SERVICO | C | 6 | Codigo do servico |
| TF_SEQRELA | C | 3 | Sequencia da manutencao |
| TF_TIPACOM | C | 1 | Tipo de acompanhamento: T=Tempo, C=Contador, A=Ambos |
| TF_PERACOM | N | 3 | Periodo de acompanhamento |
| TF_UNIACOM | C | 1 | Unidade do periodo: D=Dia, S=Semana, M=Mes |
| TF_INTCONT | N | 9 | Intervalo por contador |
| TF_TIPO | C | 3 | Tipo de manutencao |
| TF_CODAREA | C | 6 | Area de manutencao |
| TF_PRIORID | C | 3 | Prioridade |
| TF_CENTRAB | C | 6 | Centro de trabalho |
| TF_CCUSTO | C | 9 | Centro de custo |
| TF_DTULTMA | D | 8 | Data da ultima manutencao |
| TF_COULTMA | N | 12 | Contador na ultima manutencao |
| TF_DTPROXI | D | 8 | Data da proxima manutencao |
| TF_COPROXI | N | 9 | Contador da proxima manutencao |

**Indices principais:**
- Ordem 1: `TF_FILIAL + TF_CODBEM + TF_SERVICO + TF_SEQRELA`

---

### STG - Detalhes da Manutencao (Insumos do Cadastro)

Armazena os insumos previstos para cada manutencao cadastrada (STF). Sao os materiais, mao de obra, ferramentas e terceiros necessarios para executar a manutencao. Quando a O.S. e gerada, esses insumos sao copiados para a STL.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| TG_FILIAL | C | 2 | Filial |
| TG_CODBEM | C | 16 | Codigo do bem |
| TG_SERVICO | C | 6 | Codigo do servico |
| TG_SEQRELA | C | 3 | Sequencia da manutencao |
| TG_TAREFA | C | 6 | Codigo da tarefa |
| TG_TIPOREG | C | 1 | Tipo: P=MDO, M=Material, F=Ferramenta, T=Terceiro, E=Apoio |
| TG_CODIGO | C | 15 | Codigo do insumo |
| TG_NOMCODI | C | 40 | Nome do insumo |
| TG_QUANTID | N | 9,2 | Quantidade prevista |
| TG_UNIDADE | C | 2 | Unidade |
| TG_CUSTO | N | 14,2 | Custo estimado |
| TG_LOCAL | C | 2 | Armazem de origem |
| TG_FORNECE | C | 6 | Codigo do fornecedor |
| TG_LOJA | C | 2 | Loja do fornecedor |

**Indices principais:**
- Ordem 1: `TG_FILIAL + TG_CODBEM + TG_SERVICO + TG_SEQRELA + TG_TIPOREG`

---

### SN1 - Ativo Imobilizado (referencia)

Cadastro mestre do Ativo Fixo/Imobilizado (modulo SIGAATF), consultado quando ha integracao entre Manutencao de Ativos e Ativo Fixo para controle patrimonial e depreciacao.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| N1_FILIAL | C | 2 | Filial |
| N1_CBASE | C | 10 | Codigo base do ativo |
| N1_ITEM | C | 4 | Item do ativo |
| N1_DESCRIC | C | 40 | Descricao sintetica do bem |
| N1_GRUPO | C | 4 | Grupo do ativo |
| N1_PATRIM | C | 1 | Classificacao patrimonial |
| N1_LOCAL | C | 6 | Localizacao do ativo |
| N1_AQUISIC | D | 8 | Data de aquisicao |
| N1_VLAQUIS | N | 14,2 | Valor de aquisicao |
| N1_QUANTD | N | 11,3 | Quantidade |
| N1_CHAPA | C | 20 | Chapa de identificacao |
| N1_NFISCAL | C | 9 | Nota fiscal de aquisicao |
| N1_NSERIE | C | 3 | Serie da nota fiscal |
| N1_STATUS | C | 1 | Status do ativo |
| N1_BAIXA | D | 8 | Data de baixa |
| N1_TPDEPR | C | 1 | Tipo de depreciacao |
| N1_CONSAB | C | 1 | Metodo de depreciacao |

**Indices principais:**
- Ordem 1: `N1_FILIAL + N1_CBASE + N1_ITEM`
- Ordem 2: `N1_FILIAL + N1_CHAPA`

---

### SN3 - Movimentacoes do Ativo Imobilizado (referencia)

Registra as movimentacoes do ativo fixo: depreciacao, amortizacao, correcao monetaria, baixa, transferencia, reavaliacao. Gerada automaticamente pelos processos de calculo de depreciacao (ATFA050).

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| N3_FILIAL | C | 2 | Filial |
| N3_CBASE | C | 10 | Codigo base do ativo |
| N3_ITEM | C | 4 | Item do ativo |
| N3_TIPO | C | 2 | Tipo de movimentacao: 01=Aquisicao, 02=Depreciacao, 03=Baixa, etc. |
| N3_DATA | D | 8 | Data da movimentacao |
| N3_VORIG1 | N | 14,2 | Valor original (moeda 1) |
| N3_VRDACM1 | N | 14,2 | Depreciacao acumulada (moeda 1) |
| N3_PERDEPR | N | 6,4 | Percentual de depreciacao |

**Indices principais:**
- Ordem 1: `N3_FILIAL + N3_CBASE + N3_ITEM + N3_TIPO + N3_DATA`

---

## Rotinas Principais

### MNTA080 - Cadastro de Bens (Ativos)

**O que faz:** Permite incluir, alterar, excluir e visualizar bens/equipamentos no cadastro de ativos para manutencao. E a rotina central para registrar as informacoes tecnicas, de localizacao, contadores, garantia e vinculo com o ativo imobilizado (SN1). Utiliza arquitetura MVC.

**Menu:** Atualizacoes > Controle de Oficina > Ativos > Ativos

**Tabelas envolvidas:**
- ST9 (escrita) - Bens/Ativos
- STC (leitura/escrita) - Estrutura de Bens (pai-filho)
- SN1 (leitura) - Ativo Imobilizado (vinculo)
- SB1 (leitura) - Cadastro de Produtos (vinculo estoque)

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MNTA080 | Ponto de entrada padrao MVC - chamado em diversos momentos do ciclo de vida do registro (MODELCOMMITTTS, MODELCOMMITNTTS, MODELPOS, MODELPRE, etc.) |
| MNTA084 | Ponto de entrada especifico para veiculos |

---

### MNTA120 - Cadastro de Manutencao

**O que faz:** Cadastra e mantem as manutencoes associadas a cada bem. Define o servico a ser executado, a periodicidade (por tempo, por contador ou ambos), os insumos necessarios (materiais, mao de obra, ferramentas, terceiros) e as etapas de execucao. E a base para a geracao de planos preventivos.

**Menu:** Atualizacoes > Controle de Oficina > Manutencao > Manutencao

**Tabelas envolvidas:**
- STF (escrita) - Manutencao (cabecalho)
- STG (escrita) - Detalhes da Manutencao (insumos previstos)
- STH (escrita) - Etapas da Manutencao
- ST9 (leitura) - Bens/Ativos
- SRA (leitura) - Funcionarios (para mao de obra)
- SB1 (leitura) - Produtos (para materiais)

---

### MNTA280 - Solicitacao de Servico

**O que faz:** Permite incluir, distribuir, encerrar e cancelar solicitacoes de servico (S.S.) de manutencao. A S.S. e o registro formal de uma necessidade de reparo, melhoria ou incidente em um ativo. Pode ser aberta por qualquer usuario e, apos distribuicao/aprovacao, pode gerar uma Ordem de Servico (STJ). Suporta integracao com o aplicativo mobile MNT NG.

**Menu:** Atualizacoes > Controle de Oficina > Solicitacao de Servico > Solicitacao de Servico

**Tabelas envolvidas:**
- TQB (escrita) - Solicitacoes de Servico
- ST9 (leitura) - Bens/Ativos
- STJ (escrita) - Ordens de Servico (quando gera O.S. a partir da S.S.)

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MNTA280I | Permite adicionar validacoes nos processos de solicitacao de servico |

---

### MNTA330 - Plano de Manutencao Preventiva (Geracao)

**O que faz:** Gera o plano de manutencao preventiva a partir dos cadastros de manutencao (STF). O sistema calcula as datas previstas de execucao com base na periodicidade definida (tempo ou contador) e gera as Ordens de Servico preventivas (STJ) com seus respectivos insumos previstos (STL). O plano pode considerar manutencoes atrasadas.

**Menu:** Atualizacoes > Controle de Oficina > Ordem de Servico > Plano de Manutencao

**Tabelas envolvidas:**
- STF (leitura) - Cadastro de Manutencao (origem)
- STG (leitura) - Detalhes da Manutencao (insumos modelo)
- STH (leitura) - Etapas da Manutencao (modelo)
- STI (escrita) - Plano de Manutencao (cabecalho)
- STJ (escrita) - Ordens de Servico (geradas)
- STL (escrita) - Detalhes da O.S. (insumos copiados de STG)
- ST9 (leitura) - Bens/Ativos (contador, datas)

---

### MNTA340 - Confirmacao do Plano de Manutencao

**O que faz:** Confirma o plano de manutencao preventiva gerado pela MNTA330. Ao confirmar, as Ordens de Servico pendentes do plano sao liberadas para execucao, gerando empenhos e solicitacoes de armazem para os materiais previstos. O sistema verifica saldo disponivel em estoque e gera bloqueios/empenhos de material.

**Menu:** Atualizacoes > Controle de Oficina > Ordem de Servico > Confirmacao

**Tabelas envolvidas:**
- STI (leitura/escrita) - Plano de Manutencao
- STJ (leitura/escrita) - Ordens de Servico (atualiza status)
- STL (leitura) - Detalhes da O.S. (insumos para empenho)
- SD4 (escrita) - Empenhos de Material
- SB2 (leitura) - Saldos por Armazem

---

### MNTA410 - Ordem de Servico Manual (Preventiva)

**O que faz:** Permite incluir manualmente uma Ordem de Servico preventiva, fora do fluxo automatico do Plano de Manutencao (MNTA330/MNTA331). Utilizada quando ha necessidade de executar uma manutencao preventiva avulsa que nao esta no periodo de monitoramento do cadastro de manutencao (MNTA120). As O.S. incluidas por esta rotina sao consideradas do Plano 000001.

**Menu:** Atualizacoes > Controle de Oficina > Ordem de Servico > Manual

**Tabelas envolvidas:**
- STJ (escrita) - Ordens de Servico
- STL (escrita) - Detalhes da O.S. (insumos)
- STF (leitura) - Cadastro de Manutencao
- STG (leitura) - Detalhes da Manutencao
- ST9 (leitura) - Bens/Ativos
- SD4 (escrita) - Empenhos de Material
- SB2 (leitura) - Saldos por Armazem

---

### MNTA420 - Ordem de Servico Corretiva

**O que faz:** Permite incluir, alterar, executar e encerrar Ordens de Servico corretivas, que sao geradas para atender falhas ou quebras nao previstas. A O.S. corretiva recebe maxima urgencia de atendimento. Permite o apontamento de insumos (mao de obra, materiais, terceiros, ferramentas), registro de etapas executadas, controle de parada do equipamento e encerramento com historico.

**Menu:** Atualizacoes > Controle de Oficina > Ordem de Servico > Corretiva

**Tabelas envolvidas:**
- STJ (escrita) - Ordens de Servico
- STL (escrita) - Detalhes da O.S. (insumos realizados)
- ST9 (leitura/escrita) - Bens (atualiza contador, status)
- SD3 (escrita) - Movimentacoes de Estoque (requisicao de materiais)
- SB2 (leitura/escrita) - Saldos por Armazem
- SD4 (leitura/escrita) - Empenhos de Material
- SC2 (escrita) - Ordens de Producao (quando gera OP para terceiros)

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_MNTREQ | Tipo de movimento (SF5) para requisicoes de estoque originadas pelo SIGAMNT |
| MV_MNTDEV | Tipo de movimento (SF5) para devolucoes de estoque originadas pelo SIGAMNT |
| MV_PRODMNT | Codigo do produto para gerar Ordem de Producao a partir da O.S. |
| MV_PRODTER | Codigo do produto para gerar Solicitacao de Armazem para terceiros |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MNTA420A | Inclui/altera campos no browse da O.S. Corretiva |
| MNTA420B | Recupera posicao e hora de leitura do contador na rotina de O.S. |
| MNTA420C | Adiciona opcoes ao menu da rotina de O.S. Corretiva |
| MNTA420D | Validacoes ao incluir, alterar ou excluir O.S. Corretiva |
| MNTA420E | Validacoes apos incluir insumo previsto na O.S. |
| MNTA420F | Validacao antes de excluir O.S. Corretiva |
| MNTA420G | Execucao apos exclusao de O.S. Corretiva |
| MNTA420X | Validacoes apos insercao de Ordem de Producao |
| MNTA4106 | Validacoes adicionais no processo de gravacao de O.S. manual |
| MNT40012 | Execucao na finalizacao de Ordem de Servico |

---

### ATFA010 - Cadastro de Ativo Fixo (referencia - SIGAATF)

**O que faz:** Cadastro e manutencao dos bens do ativo imobilizado no modulo Ativo Fixo (SIGAATF). Registra dados contabeis, patrimoniais, de localizacao e depreciacao de cada bem. A integracao com o SIGAMNT se da pelo campo T9_CODIMOB na ST9, que vincula o bem de manutencao ao ativo imobilizado.

**Menu:** Atualizacoes > Cadastros > Ativos (SIGAATF)

**Tabelas envolvidas:**
- SN1 (escrita) - Ativo Imobilizado
- SN3 (escrita) - Movimentacoes do Ativo

---

### ATFA012 / ATFA050 - Depreciacao (referencia - SIGAATF)

**O que faz:** ATFA012 exibe e mantem as fichas do ativo com informacoes de depreciacao. ATFA050 executa o calculo mensal de depreciacao, gerando movimentacoes na SN3 e lancamentos contabeis (CT2). A depreciacao pode ser linear, por soma de digitos ou personalizada. Os custos de manutencao podem ser capitalizados (transferidos para o ativo fixo) quando o parametro TJ_VALATF estiver habilitado na O.S.

**Tabelas envolvidas:**
- SN1 (leitura/escrita) - Ativo Imobilizado
- SN3 (escrita) - Movimentacoes do Ativo
- CT2 (escrita) - Lancamentos Contabeis

---

## Processos de Negocio

### Fluxo Completo de Manutencao Preventiva

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  1. Cadastro de  │────>│  2. Cadastro de  │────>│  3. Plano de     │
│  Bens (Ativos)   │     │  Manutencao      │     │  Manut. Prev.    │
│  MNTA080 / ST9   │     │  MNTA120 / STF   │     │  MNTA330 / STI   │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                          │
┌─────────────────┐     ┌─────────────────┐     ┌────────v────────┐
│  6. Historico    │<────│  5. Execucao +   │<────│  4. Confirmacao  │
│  e Custos        │     │  Encerramento    │     │  do Plano        │
│  MNTC510/MNTC840│     │  MNTA420 / STJ   │     │  MNTA340          │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

#### Passo 1: Cadastro de Bens (MNTA080)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MNTA080 |
| **Tabelas** | ST9 (escrita), STC (escrita) |
| **O que acontece** | O usuario cadastra o bem informando codigo, nome, familia, fabricante, centro de custo, centro de trabalho, dados do contador (tipo, posicao, variacao diaria), dados de garantia, vinculo com ativo imobilizado (SN1) e vinculo com estoque (SB1). Para bens com estrutura hierarquica, define-se a relacao pai-filho na STC. |
| **Resultado** | Registro na ST9 com todas as informacoes tecnicas e de localizacao do ativo |

#### Passo 2: Cadastro de Manutencao (MNTA120)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MNTA120 |
| **Tabelas** | STF (escrita), STG (escrita), STH (escrita) |
| **O que acontece** | Para cada bem, o usuario cadastra as manutencoes necessarias, definindo: servico, tipo de acompanhamento (tempo, contador ou ambos), periodicidade, tipo de manutencao, area responsavel, prioridade e insumos previstos (materiais, mao de obra, ferramentas, terceiros) na STG. As etapas de execucao sao registradas na STH. |
| **Resultado** | Registros na STF (manutencao), STG (insumos) e STH (etapas) |

#### Passo 3: Geracao do Plano Preventivo (MNTA330)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MNTA330 |
| **Tabelas** | STF (leitura), STG (leitura), STI (escrita), STJ (escrita), STL (escrita) |
| **O que acontece** | O sistema varre os cadastros de manutencao (STF) e calcula as datas previstas de execucao com base na periodicidade definida (tempo ou contador) e nas datas/contadores da ultima manutencao. Gera um plano (STI) com as Ordens de Servico (STJ) e seus insumos previstos (STL), que sao copias fieis dos cadastros de manutencao no momento da geracao. |
| **Resultado** | Plano na STI, O.S. na STJ (status Pendente), insumos na STL |

#### Passo 4: Confirmacao do Plano (MNTA340)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MNTA340 |
| **Tabelas** | STI (escrita), STJ (escrita), STL (leitura), SD4 (escrita), SB2 (leitura) |
| **O que acontece** | O responsavel confirma as O.S. do plano. Ao confirmar, o sistema verifica saldo de materiais em estoque (SB2), gera empenhos (SD4) para os materiais previstos e libera as O.S. para execucao (TJ_SITUACA = "L"). |
| **Resultado** | O.S. liberadas, empenhos de material gerados |

#### Passo 5: Execucao e Encerramento da O.S. (MNTA420)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MNTA420 (ou MNTA410 para preventiva manual) |
| **Tabelas** | STJ (escrita), STL (escrita), ST9 (escrita), SD3 (escrita), SB2 (escrita), SD4 (escrita) |
| **O que acontece** | O executante registra os insumos realizados (mao de obra, materiais consumidos, servicos terceirizados, ferramentas), as datas/horas reais de inicio e fim da parada e da manutencao, e a posicao do contador no momento do servico. Materiais consumidos geram movimentacao de estoque (SD3) usando o tipo de movimento configurado em MV_MNTREQ. Ao encerrar (TJ_TERMINO = "S"), o sistema atualiza o contador do bem na ST9 e registra a data da ultima manutencao. |
| **Resultado** | O.S. encerrada, custos apurados (TJ_CUSTMDO, TJ_CUSTMAT, etc.), estoque atualizado, contador do bem atualizado |

#### Passo 6: Historico e Custos (MNTC510/MNTC840)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MNTC510 (Historico de O.S.), MNTC840 (Custos por Bem) |
| **Tabelas** | STJ (leitura), STL (leitura), ST9 (leitura) |
| **O que acontece** | Consulta do historico completo de ordens de servico executadas por bem, com detalhamento de custos (mao de obra, materiais, terceiros, ferramentas), tempos de parada e tempos de manutencao. Permite analise de indicadores como MTBF (Mean Time Between Failures) e MTTR (Mean Time To Repair). |
| **Resultado** | Informacoes gerenciais para tomada de decisao sobre manutencao |

### Fluxo de Manutencao Corretiva (Demanda)

```
Solicitacao de Servico (TQB) → Abertura de O.S. Corretiva (STJ) → Execucao (STL/SD3) → Encerramento → Historico
```

Quando ocorre uma falha ou quebra inesperada, o usuario registra uma Solicitacao de Servico (MNTA280/TQB). Apos distribuicao e aprovacao, a S.S. pode gerar diretamente uma O.S. Corretiva (MNTA420/STJ), que e executada com maxima prioridade.

### Fluxo Simplificado (Corretiva Direta)

```
Abertura de O.S. Corretiva (MNTA420) → Apontamento de Insumos → Encerramento → Historico
```

O operador pode abrir diretamente uma O.S. Corretiva sem necessidade de Solicitacao de Servico previa.

---

## Regras de Negocio

### Campos obrigatorios por rotina

**Cadastro de Bens (MNTA080 - ST9):**
- T9_CODBEM (Codigo do bem)
- T9_NOME (Nome do bem)
- T9_CATBEM (Categoria do bem)
- T9_CCUSTO (Centro de custo)

**Cadastro de Manutencao (MNTA120 - STF):**
- TF_CODBEM (Codigo do bem)
- TF_SERVICO (Codigo do servico)
- TF_TIPACOM (Tipo de acompanhamento: T/C/A)
- TF_PERACOM ou TF_INTCONT (Periodicidade por tempo ou por contador)

**Solicitacao de Servico (MNTA280 - TQB):**
- TQB_CODBEM (Codigo do bem)
- TQB_DESCSS (Descricao do problema/servico)
- TQB_TPSERV (Tipo: 1=Incidente, 2=Melhoria)

**Ordem de Servico Corretiva (MNTA420 - STJ):**
- TJ_CODBEM (Codigo do bem)
- TJ_SERVICO (Codigo do servico)
- TJ_TIPO (Tipo de manutencao)
- TJ_CODAREA (Area de manutencao)
- TJ_PRIORID (Prioridade)

**Insumos da O.S. (STL):**
- TL_ORDEM (Numero da O.S.)
- TL_TIPOREG (Tipo do insumo: P/M/F/T/E)
- TL_CODIGO (Codigo do insumo)
- TL_QUANTID (Quantidade)

### Validacoes principais

| Validacao | Descricao |
|-----------|-----------|
| Bem ativo | Somente bens com T9_SITMAN = "A" (Ativo) podem receber ordens de servico |
| Contador valido | A posicao informada do contador na O.S. deve ser >= posicao anterior, exceto em caso de virada (T9_VIRADAS) |
| Saldo de estoque | Ao consumir material na O.S., o sistema verifica saldo disponivel no armazem (SB2). Se nao houver saldo, pode gerar solicitacao de armazem (SA) |
| Empenho de material | Materiais empenhados (SD4) ficam reservados para a O.S. e nao podem ser consumidos por outra operacao |
| Encerramento de O.S. | Para encerrar a O.S. (TJ_TERMINO = "S"), todas as datas reais (inicio/fim) devem ser preenchidas |
| Status da O.S. | O.S. com TJ_SITUACA = "C" (Cancelada) ou TJ_TERMINO = "S" (Encerrada) nao podem ser alteradas |
| Plano confirmado | Apos confirmacao do plano (MNTA340), alteracoes no cadastro de manutencao (STF) nao sao refletidas nas O.S. ja geradas |
| Vinculo S.S. -> O.S. | Uma S.S. (TQB) so pode gerar uma O.S.; ao gerar, o campo TQB_ORDEM e preenchido |
| Tipo de movimento | Requisicoes de estoque usam o tipo de movimento definido em MV_MNTREQ; devolucoes usam MV_MNTDEV |

### Gatilhos SX7 relevantes

| Campo origem | Campo destino | Regra | Tabela lookup |
|-------------|---------------|-------|---------------|
| T9_CODFAMI | T9_NOMFAMI | Busca nome da familia | Tabela de familias |
| T9_FABRICA | T9_NOMFABR | Busca nome do fabricante | Tabela de fabricantes |
| T9_CCUSTO | T9_NOMCUST | CTT->CTT_DESC01 | CTT |
| T9_CENTRAB | T9_NOMTRAB | Busca nome do centro de trabalho | Tabela centros de trabalho |
| T9_FORNECE | T9_NOMFORN | SA2->A2_NOME | SA2 |
| TJ_CODBEM | TJ_NOMBEM | ST9->T9_NOME | ST9 |
| TJ_SERVICO | TJ_NOMSERV | Busca nome do servico | Tabela de servicos |
| TJ_CODAREA | TJ_NOMAREA | Busca nome da area | Tabela de areas |
| TJ_CCUSTO | TJ_NOMCUST | CTT->CTT_DESC01 | CTT |
| TL_CODIGO | TL_NOMCODI | Busca nome do insumo conforme TL_TIPOREG | SRA/SB1/ST9 |
| TQB_CODBEM | TQB_NOMBEM | ST9->T9_NOME | ST9 |

### Pontos de entrada mais utilizados no modulo

| Ponto de Entrada | Rotina | Descricao |
|------------------|--------|-----------|
| MNTA080 | MNTA080 | PE padrao MVC no cadastro de bens (MODELCOMMITTTS, MODELPOS, MODELPRE, etc.) |
| MNTA084 | MNTA084 | PE especifico para cadastro de veiculos |
| MNTA280I | MNTA280 | Validacoes nos processos de solicitacao de servico |
| MNTA420A | MNTA420 | Inclui/altera campos no browse da O.S. Corretiva |
| MNTA420B | MNTA420 | Recupera posicao e hora do contador na O.S. |
| MNTA420C | MNTA420 | Adiciona opcoes ao menu da O.S. Corretiva |
| MNTA420D | MNTA420 | Validacoes ao incluir/alterar/excluir O.S. Corretiva |
| MNTA420E | MNTA420 | Validacoes apos incluir insumo previsto na O.S. |
| MNTA420F | MNTA420 | Validacao antes de excluir O.S. Corretiva |
| MNTA420G | MNTA420 | Execucao apos exclusao de O.S. Corretiva |
| MNTA420X | MNTA420 | Validacoes apos insercao de Ordem de Producao |
| MNTA4106 | MNTA410 | Validacoes na gravacao de O.S. manual |
| MNT40012 | MNTA420 | Execucao na finalizacao de O.S. |
| MNTC5101 | MNTC510 | Legenda no browse de O.S. do Historico da Manutencao |

---

## Integracoes

### Manutencao → Estoque (SIGAEST)

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | No apontamento de insumos do tipo Material (TL_TIPOREG = "M" ou "E") na O.S. (MNTA420) |
| **O que acontece** | Gera movimentacao de estoque na SD3 (tipo de movimento conforme MV_MNTREQ para requisicoes e MV_MNTDEV para devolucoes). Atualiza saldo do produto no armazem (SB2). Materiais previstos na O.S. geram empenhos (SD4) que reservam o saldo. Quando da confirmacao do plano (MNTA340), solicitacoes de armazem (SA) podem ser geradas automaticamente. |
| **Tabelas afetadas** | SD3 (movimentacao), SB2 (saldo por armazem), SD4 (empenhos) |
| **Controles** | Se o material possui controle de lote/serie (B1_RASTRO), exige informacao de lote (TL_LOTECTL) e serie (TL_NUMSERI) no apontamento |

### Manutencao → Compras (SIGACOM)

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Quando insumos previstos na O.S. nao possuem saldo em estoque ou quando servicos terceirizados precisam ser contratados |
| **O que acontece** | Gera Solicitacao de Compra (SC1) para materiais sem saldo disponivel. Para servicos terceirizados (TL_TIPOREG = "T"), pode gerar Solicitacao de Armazem usando o produto definido em MV_PRODTER. A nota fiscal de entrada do fornecedor terceirizado atualiza o custo na O.S. |
| **Tabelas afetadas** | SC1 (Solicitacao de Compra), SD3 (movimentacao via NF entrada) |

### Manutencao → PCP (SIGAPCP)

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na inclusao de O.S. com insumos de terceiros ou quando ha necessidade de producao de pecas |
| **O que acontece** | Gera Ordem de Producao (SC2) automaticamente, usando o produto definido em MV_PRODMNT. A OP e vinculada a O.S. para rastreamento de custos |
| **Tabelas afetadas** | SC2 (Ordens de Producao) |

### Manutencao → Ativo Fixo (SIGAATF)

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | No cadastro do bem (T9_CODIMOB vincula ST9 a SN1) e no encerramento de O.S. com capitalizacao (TJ_VALATF) |
| **O que acontece** | O campo T9_CODIMOB na ST9 vincula o bem de manutencao ao ativo imobilizado (SN1). Quando TJ_VALATF = "S" na O.S., os custos de manutencao sao transferidos/capitalizados para o ativo fixo, incrementando seu valor patrimonial. A depreciacao mensal (ATFA050) calcula o desgaste do ativo ao longo do tempo |
| **Tabelas afetadas** | SN1 (Ativo Imobilizado), SN3 (Movimentacoes do Ativo), CT2 (Lancamentos Contabeis) |

### Manutencao → Contabilidade (SIGACTB)

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | No apontamento de custos de manutencao (materiais, mao de obra, terceiros) e na depreciacao do ativo |
| **O que acontece** | Custos de manutencao sao contabilizados por centro de custo do bem (T9_CCUSTO / TJ_CCUSTO). A depreciacao mensal gera lancamentos contabeis (CT2), debitando despesa de depreciacao e creditando depreciacao acumulada. Custos capitalizados (TJ_VALATF) incrementam o valor do ativo |
| **Tabelas afetadas** | CT2 (Lancamentos Contabeis) |

### Manutencao → RH (SIGAGPE)

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | No apontamento de mao de obra na O.S. (TL_TIPOREG = "P") |
| **O que acontece** | Consulta o cadastro de funcionarios (SRA) para validar o executor. O custo-hora do funcionario e utilizado para calcular o custo de mao de obra da O.S. (TJ_CUSTMDO). Percentuais de hora extra (TL_PCTHREX) sao aplicados quando a manutencao ocorre fora do turno normal |
| **Tabelas afetadas** | SRA (Funcionarios - leitura) |

### Manutencao → TMS (SIGATMS)

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Para bens do tipo veiculo (T9_CATBEM = "2") com vinculo TMS (T9_CODTMS) |
| **O que acontece** | Integra com o modulo de Gestao de Transportes para controle de frota. Viagens podem ser bloqueadas quando o veiculo esta em manutencao. Informacoes de odometro/horimetro sao compartilhadas entre os modulos |
| **Tabelas afetadas** | Tabelas do SIGATMS |

### Resumo das integracoes na Ordem de Servico

```
                          MNTA420 - Ordem de Servico
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                      │
        ┌─────v─────┐         ┌─────v─────┐         ┌─────v─────┐
        │  Estoque   │         │  Compras   │         │    PCP    │
        │ SD3/SB2/SD4│         │  SC1       │         │    SC2    │
        └───────────┘         └───────────┘         └───────────┘
              │
        ┌─────v─────┐         ┌───────────┐         ┌───────────┐
        │ Ativo Fixo │         │Contabilid.│         │    RH     │
        │  SN1/SN3   │         │   CT2     │         │   SRA     │
        └───────────┘         └───────────┘         └───────────┘
```

---

## Cadastros Auxiliares

| Rotina | Descricao | Tabela |
|--------|-----------|--------|
| MNTA010 | Especialidades de Manutencao | Tabela de especialidades |
| MNTA020 | Funcionarios de Manutencao | Vinculo funcionario-especialidade |
| MNTA030 | Areas de Manutencao | Tabela de areas |
| MNTA040 | Servicos de Manutencao | Tabela de servicos |
| MNTA050 | Tarefas de Manutencao | Tabela de tarefas |
| MNTA060 | Tipos de Manutencao | Tabela de tipos |
| MNTA070 | Familias de Bens | Tabela de familias |
| MNTA080 | Cadastro de Bens/Ativos | ST9 |
| MNTA084 | Cadastro de Veiculos | ST9 (categoria veiculo) |
| MNTA090 | Centros de Trabalho | Tabela de centros |
| MNTA100 | Fabricantes | Tabela de fabricantes |
| MNTA110 | Irregularidades | Tabela de irregularidades |
| MNTA325 | Tipo de Status (Follow-up) | Tabela de status |
| MNTA876 | Acerto e Reprocessamento de Contadores | ST9 |

---

## Parametros Globais do Modulo (MV_*)

| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| MV_MNTREQ | C | Tipo de movimento (SF5) para requisicoes de estoque do SIGAMNT |
| MV_MNTDEV | C | Tipo de movimento (SF5) para devolucoes de estoque do SIGAMNT |
| MV_PRODMNT | C | Codigo do produto para gerar Ordem de Producao (SC2) a partir da O.S. |
| MV_PRODTER | C | Codigo do produto para gerar Solicitacao de Armazem para terceiros |
