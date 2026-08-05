# Modulo Fiscal (FIS)

## Visao Geral

O modulo Fiscal (SIGAFIS) do TOTVS Protheus, tambem conhecido como Livros Fiscais, gerencia toda a escrituracao fiscal da empresa, desde a configuracao dos Tipos de Entrada e Saida (TES) ate a apuracao de impostos e geracao de obrigacoes acessorias. Ele centraliza o calculo, escrituracao e controle dos tributos incidentes sobre as operacoes de compra, venda e prestacao de servicos, integrando-se com os modulos de Compras, Faturamento, Financeiro e Contabilidade.

**Prefixo do modulo:** FIS
**Sigla do ambiente:** SIGAFIS
**Prefixo das rotinas:** MATA9xx (ex: MATA950, MATA953, MATA952), FISAxx (ex: FISA010, FISA040, FISA170), SPDFIS, EFDCON

### Ciclo principal fiscal

```
Configuracao TES (SF4) → Escrituracao NF Entrada/Saida (SFT/SF3) → Apuracao de Impostos (ICMS/IPI/PIS/COFINS) → Obrigacoes Acessorias (SPED Fiscal, EFD Contribuicoes, GIA)
```

O modulo opera em regime especial de processamento eletronico de dados, permitindo a emissao dos Livros Fiscais (Entradas, Saidas, Apuracao de ICMS, Apuracao de IPI) e geracao de arquivos magneticos para o Fisco.

---

## Tabelas Principais

### SF4 - Tipos de Entrada e Saida (TES)

Define o tratamento fiscal, financeiro e de estoque de cada operacao. A TES e a tabela-chave que determina como cada item de nota fiscal sera processado nos diversos modulos do Protheus.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| F4_FILIAL | C | 8 | Filial |
| F4_CODIGO | C | 3 | Codigo da TES |
| F4_TIPO | C | 1 | Tipo de operacao: E=Entrada, S=Saida |
| F4_CF | C | 5 | Codigo Fiscal (CFOP) |
| F4_ICM | C | 1 | Calcula ICMS: S=Sim, N=Nao |
| F4_IPI | C | 1 | Calcula IPI: S=Sim, N=Nao |
| F4_CREDICM | C | 1 | Credita ICMS: S=Sim, N=Nao |
| F4_CREDIPI | C | 1 | Credita IPI: S=Sim, N=Nao |
| F4_LFICM | C | 1 | Livro Fiscal ICMS: T=Tributado, I=Isento, O=Outros, N=Nao |
| F4_LFIPI | C | 1 | Livro Fiscal IPI: T=Tributado, I=Isento, O=Outros, N=Nao |
| F4_LFISS | C | 1 | Livro Fiscal ISS: S=Sim, N=Nao |
| F4_ESTOQUE | C | 1 | Atualiza Estoque: S=Sim, N=Nao |
| F4_DUPLIC | C | 1 | Gera Duplicata/Titulo Financeiro: S=Sim, N=Nao |
| F4_PODER3 | C | 1 | Poder de Terceiros: R=Remessa, D=Devolucao, N=Nao |
| F4_TEXTO | C | 1 | Texto padrao na NF |
| F4_AGREG | C | 1 | Agrega Valor: S=Sim, N=Nao (define se o valor integra o total da NF) |
| F4_PISCRED | C | 1 | PIS Credito: S=Credita, D=Debita, N=Nao calcula |
| F4_COFCRED | C | 1 | COFINS Credito: S=Credita, D=Debita, N=Nao calcula |
| F4_CSTPIS | C | 2 | CST do PIS |
| F4_CSTCOF | C | 2 | CST da COFINS |
| F4_CSTICM | C | 3 | CST do ICMS |
| F4_CSTIPI | C | 2 | CST do IPI |
| F4_DESCOND | C | 1 | Desconto no item: S=Concedido, N=Nao |
| F4_VLRZERO | C | 1 | Permite valor zerado na NF |
| F4_CODOBSE | C | 6 | Codigo de Observacao Complementar (CCE) |
| F4_TRANFIL | C | 1 | Transferencia entre filiais |
| F4_CONSUMO | C | 1 | Material de uso/consumo: S=Sim, N=Nao |
| F4_COMAM | C | 1 | Complemento de ICMS por aliquota menor |
| F4_ISS | C | 1 | Calcula ISS: S=Sim, N=Nao |

**Indices principais:**
- Ordem 1: `F4_FILIAL + F4_CODIGO`

---

### SF3 - Livros Fiscais (Cabecalho)

Armazena o resumo das notas fiscais escrituradas nos livros de entradas e saidas. Cada registro representa uma nota fiscal com seus totais de impostos.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| F3_FILIAL | C | 8 | Filial |
| F3_NFISCAL | C | 9 | Numero da nota fiscal |
| F3_SERIE | C | 3 | Serie da NF |
| F3_CLIEFOR | C | 6 | Codigo do cliente ou fornecedor |
| F3_LOJA | C | 2 | Loja |
| F3_EMISSAO | D | 8 | Data de emissao |
| F3_DTCANC | D | 8 | Data de cancelamento |
| F3_CFO | C | 5 | CFOP |
| F3_ESPECIE | C | 2 | Especie do documento (NF, NFS, CT, etc.) |
| F3_TIPO | C | 1 | Tipo: N=Normal, D=Devolucao, C=Complemento |
| F3_ENTRADA | C | 1 | Tipo de movimento: E=Entrada, S=Saida |
| F3_VALCONT | N | 14,2 | Valor contabil |
| F3_BASEICM | N | 14,2 | Base de calculo do ICMS |
| F3_VALICM | N | 14,2 | Valor do ICMS |
| F3_ALIQICM | N | 5,2 | Aliquota do ICMS |
| F3_BASEIPI | N | 14,2 | Base de calculo do IPI |
| F3_VALIPI | N | 14,2 | Valor do IPI |
| F3_ICMSRET | N | 14,2 | Valor do ICMS retido (ST) |
| F3_BASERET | N | 14,2 | Base do ICMS retido (ST) |
| F3_VALISS | N | 14,2 | Valor do ISS |
| F3_ISENICM | N | 14,2 | ICMS isento |
| F3_OUTRICM | N | 14,2 | Outras de ICMS |
| F3_ISENIPI | N | 14,2 | IPI isento |
| F3_OUTRIPI | N | 14,2 | Outras de IPI |
| F3_FORMUL | C | 1 | Formulario proprio: S=Sim, N=Nao |
| F3_OBSERV | C | 50 | Observacoes |
| F3_CHVNFE | C | 44 | Chave da NFe |
| F3_CODISS | C | 5 | Codigo do servico (ISS) |
| F3_CODMOT | C | 10 | Codigo do motivo de cancelamento |
| F3_NRLIVRO | C | 3 | Numero do livro |
| F3_ESTADO | C | 2 | UF de origem/destino |

**Indices principais:**
- Ordem 1: `F3_FILIAL + F3_NFISCAL + F3_SERIE + F3_CLIEFOR + F3_LOJA`
- Ordem 2: `F3_FILIAL + F3_CLIEFOR + F3_LOJA + F3_NFISCAL`
- Ordem 3: `F3_FILIAL + F3_EMISSAO + F3_NFISCAL`

---

### SFT - Livro Fiscal por Item de NF

Armazena a escrituracao fiscal detalhada por item de nota fiscal. E a tabela central para o SPED Fiscal, contendo todos os tributos calculados para cada item.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| FT_FILIAL | C | 8 | Filial |
| FT_TIPOMOV | C | 1 | Tipo de movimento: E=Entrada, S=Saida |
| FT_ENTRADA | C | 1 | Tipo de escrituracao: 0=Proprio, 1=Terceiros |
| FT_NFISCAL | C | 9 | Numero da nota fiscal |
| FT_SERIE | C | 3 | Serie |
| FT_CLIEFOR | C | 6 | Cliente ou fornecedor |
| FT_LOJA | C | 2 | Loja |
| FT_ITEM | C | 4 | Item da NF |
| FT_PRODUTO | C | 15 | Codigo do produto |
| FT_CFOP | C | 5 | CFOP da operacao |
| FT_ESPECIE | C | 2 | Especie do documento |
| FT_TIPO | C | 1 | Tipo da NF: N=Normal, D=Devolucao, C=Complemento |
| FT_EMISSAO | D | 8 | Data de emissao |
| FT_DTCANC | D | 8 | Data de cancelamento |
| FT_VALCONT | N | 14,2 | Valor contabil |
| FT_BASEICM | N | 14,2 | Base de ICMS |
| FT_VALICM | N | 14,2 | Valor de ICMS |
| FT_ALIQICM | N | 5,2 | Aliquota de ICMS |
| FT_CSTICM | C | 3 | CST do ICMS |
| FT_BASEIPI | N | 14,2 | Base de IPI |
| FT_VALIPI | N | 14,2 | Valor de IPI |
| FT_ALIQIPI | N | 5,2 | Aliquota de IPI |
| FT_CSTIPI | C | 2 | CST do IPI |
| FT_BASEPIS | N | 14,2 | Base de PIS |
| FT_VALPIS | N | 14,2 | Valor de PIS |
| FT_ALIQPI | N | 5,2 | Aliquota de PIS |
| FT_CSTPIS | C | 2 | CST do PIS |
| FT_BASECOF | N | 14,2 | Base de COFINS |
| FT_VALCOF | N | 14,2 | Valor de COFINS |
| FT_ALIQCOF | N | 5,2 | Aliquota de COFINS |
| FT_CSTCOF | C | 2 | CST da COFINS |
| FT_ICMSRET | N | 14,2 | ICMS retido (ST) |
| FT_BASERET | N | 14,2 | Base do ICMS retido (ST) |
| FT_FORMUL | C | 1 | Formulario proprio |
| FT_NRLIVRO | C | 3 | Numero do livro fiscal |
| FT_NCM | C | 10 | NCM do produto |
| FT_CBENEF | C | 10 | Codigo de beneficio fiscal |

**Indices principais:**
- Ordem 1: `FT_FILIAL + FT_TIPOMOV + FT_ENTRADA + FT_NFISCAL + FT_SERIE + FT_CLIEFOR + FT_LOJA + FT_ITEM`
- Ordem 2: `FT_FILIAL + FT_PRODUTO + FT_NFISCAL + FT_SERIE`
- Ordem 3: `FT_FILIAL + FT_EMISSAO + FT_NFISCAL`

---

### CDA - Ajustes de Credito/Debito ICMS

Armazena os codigos de ajustes de credito e debito de ICMS vinculados a documentos fiscais, utilizados na apuracao e geracao do SPED Fiscal (registros C195/C197).

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| CDA_FILIAL | C | 8 | Filial |
| CDA_CODAJU | C | 10 | Codigo de ajuste (tabela 5.3 SPED) |
| CDA_NFISCAL | C | 9 | Numero da nota fiscal |
| CDA_SERIE | C | 3 | Serie |
| CDA_CLIEFOR | C | 6 | Cliente/Fornecedor |
| CDA_LOJA | C | 2 | Loja |
| CDA_ITEM | C | 4 | Item |
| CDA_VALOR | N | 14,2 | Valor do ajuste |
| CDA_DESCRI | C | 50 | Descricao do ajuste |
| CDA_TIPO | C | 1 | Tipo: C=Credito, D=Debito |

**Indices principais:**
- Ordem 1: `CDA_FILIAL + CDA_CODAJU + CDA_NFISCAL + CDA_SERIE`

---

### CDO - Ajustes de Saldos da Apuracao ICMS

Armazena os codigos de lancamento e ajustes dos saldos da apuracao de ICMS (tabela 5.1.1 do SPED Fiscal), utilizados nos registros E111/E220.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| CDO_FILIAL | C | 8 | Filial |
| CDO_CODAJU | C | 10 | Codigo de ajuste da apuracao |
| CDO_DTINI | D | 8 | Data inicio da apuracao |
| CDO_DTFIM | D | 8 | Data fim da apuracao |
| CDO_VALOR | N | 14,2 | Valor do ajuste |
| CDO_DESCRI | C | 50 | Descricao do ajuste |
| CDO_TIPO | C | 1 | Tipo: C=Credito, D=Debito, E=Estorno debito, F=Estorno credito |
| CDO_SUBAPU | C | 3 | Codigo de sub-apuracao ICMS |

**Indices principais:**
- Ordem 1: `CDO_FILIAL + CDO_CODAJU + CDO_DTINI`

---

### CC6 - Ajustes de Documentos Fiscais

Armazena os codigos de ajuste vinculados a documentos fiscais, controlando a relacao entre o ajuste e o documento que o originou para geracao dos registros C195/C197/D195/D197 do SPED Fiscal.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| CC6_FILIAL | C | 8 | Filial |
| CC6_CODAJU | C | 10 | Codigo de ajuste do documento |
| CC6_NFISCAL | C | 9 | Numero da NF |
| CC6_SERIE | C | 3 | Serie |
| CC6_CLIEFOR | C | 6 | Cliente/Fornecedor |
| CC6_LOJA | C | 2 | Loja |
| CC6_ITEM | C | 4 | Item |
| CC6_VALOR | N | 14,2 | Valor do ajuste |
| CC6_DESCRI | C | 50 | Descricao |

**Indices principais:**
- Ordem 1: `CC6_FILIAL + CC6_CODAJU + CC6_NFISCAL + CC6_SERIE`

---

### CCE - Informacoes Complementares (Observacoes)

Cadastro de textos de observacao complementar vinculados a documentos fiscais, utilizados na impressao de NFs e no SPED Fiscal.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| CCE_FILIAL | C | 8 | Filial |
| CCE_CODOBS | C | 6 | Codigo da observacao |
| CCE_DESCRI | C | 50 | Descricao da observacao |
| CCE_OBS | M | 10 | Texto completo da observacao |

**Indices principais:**
- Ordem 1: `CCE_FILIAL + CCE_CODOBS`

---

### CFC - CFOP (Codigo Fiscal de Operacoes e Prestacoes)

Cadastro dos codigos CFOP utilizados na escrituracao fiscal, classificando a natureza das operacoes.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| CFC_FILIAL | C | 8 | Filial |
| CFC_CFOP | C | 5 | Codigo CFOP (ex: 5102, 6101, 1102) |
| CFC_DESCRI | C | 60 | Descricao do CFOP |
| CFC_TIPO | C | 1 | Tipo: E=Entrada, S=Saida |
| CFC_GRPNAT | C | 2 | Grupo de natureza |

**Indices principais:**
- Ordem 1: `CFC_FILIAL + CFC_CFOP`

---

### SFB - Retencoes Fiscais

Controla as retencoes de impostos federais e municipais (IRRF, PIS, COFINS, CSLL, INSS, ISS) nas operacoes fiscais, gerando informacoes para o EFD-REINF e DCTF.

| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| FB_FILIAL | C | 8 | Filial |
| FB_NFISCAL | C | 9 | Numero da NF |
| FB_SERIE | C | 3 | Serie |
| FB_CLIEFOR | C | 6 | Cliente/Fornecedor |
| FB_LOJA | C | 2 | Loja |
| FB_TIPO | C | 3 | Tipo de retencao (IRRF, PIS, COFINS, CSLL, INSS, ISS) |
| FB_BASE | N | 14,2 | Base de calculo da retencao |
| FB_VALOR | N | 14,2 | Valor retido |
| FB_ALIQ | N | 5,2 | Aliquota |
| FB_EMISSAO | D | 8 | Data de emissao |
| FB_VENCTO | D | 8 | Data de vencimento do recolhimento |

**Indices principais:**
- Ordem 1: `FB_FILIAL + FB_NFISCAL + FB_SERIE + FB_CLIEFOR + FB_LOJA + FB_TIPO`

---

## Rotinas Principais

### MATA080 - Cadastro de TES (Tipos de Entrada e Saida)

**O que faz:** Permite incluir, alterar, excluir e visualizar os Tipos de Entrada e Saida na tabela SF4. A TES e o registro central que define o comportamento fiscal, financeiro e de estoque de cada operacao. Cada item de nota fiscal (entrada ou saida) deve obrigatoriamente referenciar uma TES.

**Tabelas envolvidas:**
- SF4 (escrita) - Tipos de Entrada e Saida
- SX5 (leitura) - Tabelas genericas (CFOP, CST)
- CCE (leitura) - Observacoes Complementares

**Abas de configuracao da TES:**
| Aba | Campos principais | Funcao |
|-----|-------------------|--------|
| Administrativo | F4_TIPO, F4_CF, F4_TEXTO | Define tipo (E/S), CFOP e texto padrao |
| Impostos | F4_ICM, F4_IPI, F4_ISS, F4_CREDICM, F4_CREDIPI, F4_PISCRED, F4_COFCRED | Configuracao de calculo e creditamento de impostos |
| Livros Fiscais | F4_LFICM, F4_LFIPI, F4_LFISS, F4_CSTICM, F4_CSTIPI, F4_CSTPIS, F4_CSTCOF | Classificacao nos livros fiscais e CSTs |
| Estoque | F4_ESTOQUE, F4_PODER3, F4_CONSUMO | Movimentacao de estoque |
| Financeiro | F4_DUPLIC, F4_AGREG, F4_DESCOND | Geracao de titulos financeiros |

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_CREDICM | Abatimento do valor de ICMS no custo |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| MA080BUT | Adiciona botoes customizados no cadastro de TES |
| MA080TOK | Validacao customizada na confirmacao do registro |

---

### MATXFIS - Motor de Calculo Fiscal

**O que faz:** E o motor (engine) de calculo de impostos do Protheus. Nao e uma rotina acessivel por menu; e um conjunto de funcoes ADVPL invocadas internamente pelas rotinas de Documento de Entrada (MATA103), Faturamento (MATA461/MATA462), e demais rotinas que processam notas fiscais. Responsavel por calcular ICMS, IPI, PIS, COFINS, ISS, ICMS-ST, DIFAL e demais tributos.

**Funcoes principais:**
| Funcao | Descricao |
|--------|-----------|
| MaFisIni() | Inicializa o MATXFIS. Monta o array aNFCab (cabecalho) com dados do documento, parametros SX6, dados do cliente/fornecedor (SA1/SA2) e natureza financeira (SED). Deve ser chamada obrigatoriamente antes de qualquer operacao |
| MaFisIniLoad() | Carrega um item no MATXFIS. Preferivel ao MaFisAdd() por ser mais performatico — nao recalcula todos os itens a cada inclusao |
| MaFisAdd() | Adiciona item e recalcula todos os impostos. Mais lento que MaFisIniLoad() |
| MaFisRet() | Retorna valores calculados (impostos, bases, CSTs) para o item ou cabecalho. Usada para obter resultados apos o calculo |
| MaFisEnd() | Finaliza o MATXFIS, liberando memoria e gravando dados nos livros fiscais (SFT/SF3) |
| MaFisTes() | Retorna informacoes da TES (SF4) aplicada ao item |
| MaFisLoad() | Carrega dados previamente calculados para consulta |

**Fluxo de uso do MATXFIS:**
```
MaFisIni(aNFCab)       // Inicializa com cabecalho
  → MaFisIniLoad()      // Carrega cada item (loop)
  → MaFisRet()           // Obtem valores calculados
MaFisEnd()              // Finaliza e grava nos livros
```

**Tabelas consultadas/gravadas:**
- SF4 (leitura) - TES
- SFT (escrita) - Livro Fiscal por Item
- SF3 (escrita) - Livros Fiscais (cabecalho)
- SA1/SA2 (leitura) - Clientes/Fornecedores
- SED (leitura) - Natureza financeira
- SB1 (leitura) - Cadastro de Produtos
- CDA (escrita) - Ajustes ICMS

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_ESTADO | UF da empresa (usado para determinar operacao interna/interestadual) |
| MV_ESTICM | Aliquotas de ICMS por UF (formato: UF+Aliq, ex: SP18MG18RJ20) |
| MV_BASDUPL | Base dupla para calculo de DIFAL |
| MV_ICMPAD | Aliquota padrao de ICMS |

---

### MATA953 - Apuracao de ICMS

**O que faz:** Realiza a apuracao do ICMS (debitos e creditos) do periodo, calculando o saldo devedor ou credor. Disponivel em SIGAFIS > Miscelanea > Apuracoes > Apuracao de ICMS. Processa os livros fiscais (SFT/SF3) do periodo e gera os registros de apuracao, incluindo ajustes (CDO), sub-apuracoes e informacoes adicionais para o SPED Fiscal (registros E110, E111, E115, E116).

**Tabelas envolvidas:**
- SFT (leitura) - Livro Fiscal por Item
- SF3 (leitura) - Livros Fiscais
- CDO (leitura/escrita) - Ajustes de Apuracao
- CDA (leitura) - Ajustes de Documentos
- CC6 (leitura) - Ajustes de Documentos Fiscais
- SE2 (escrita) - Titulos a Pagar (guia de recolhimento)

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_ESTADO | UF da empresa |
| MV_SUBTRIB | Habilita sub-tributacao de ICMS |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| FA953INC | Apos inclusao de registros na apuracao de ICMS |
| FA953ALT | Apos alteracao de registros na apuracao de ICMS |
| MTA953V | Validacoes customizadas na apuracao |

---

### MATA952 - Apuracao de IPI

**O que faz:** Realiza a apuracao do IPI (Imposto sobre Produtos Industrializados) do periodo. Calcula o saldo devedor ou credor do IPI com base nos livros fiscais. O IPI e apurado por periodo (mensal, decendial ou quinzenal, conforme enquadramento). Disponivel em SIGAFIS > Miscelanea > Apuracoes > Apuracao de IPI.

**Tabelas envolvidas:**
- SFT (leitura) - Livro Fiscal por Item
- SF3 (leitura) - Livros Fiscais
- SE2 (escrita) - Titulos a Pagar (guia de recolhimento)

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|

---

### EFDCON - Apuracao PIS/COFINS e EFD Contribuicoes

**O que faz:** Realiza a apuracao de PIS e COFINS nos regimes cumulativo e nao-cumulativo, e gera o arquivo digital EFD Contribuicoes (SPED Contribuicoes). Centraliza rotinas auxiliares de PIS/COFINS em uma tela unica, incluindo: apuracao de creditos e debitos, diferimento, ajustes (registros M110/M510), credito presumido e geracao do arquivo texto para transmissao ao SPED.

**Tabelas envolvidas:**
- SFT (leitura) - Livro Fiscal por Item
- CDH (leitura/escrita) - Ajustes PIS/COFINS
- CL2 (leitura) - Dados do Ativo Fixo (blocos F120/F130)
- SE2 (escrita) - Titulos a Pagar (guias de recolhimento)

**Rotinas auxiliares na EFDCON:**
| Rotina | Descricao |
|--------|-----------|
| FISA001 | Apuracao PIS/COFINS (processamento principal) |
| FISA042 | Ajuste de Creditos PIS/COFINS |
| FISA054 | Pre-processamento de Diferimento PIS/COFINS |
| FISR101 | Relatorio de conferencia EFD Contribuicoes |

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|

---

### SPDFIS - SPED Fiscal (EFD ICMS/IPI)

**O que faz:** Gera o arquivo digital SPED Fiscal (Escrituracao Fiscal Digital de ICMS/IPI) conforme leiaute definido pela Receita Federal e Secretarias de Fazenda estaduais. O arquivo contem a escrituracao completa dos documentos fiscais e a apuracao de ICMS e IPI.

**Blocos gerados:**
| Bloco | Conteudo |
|-------|----------|
| 0 | Abertura, identificacao e referencias (participantes, produtos, unidades, etc.) |
| B | Apuracao de ISS (somente Distrito Federal) |
| C | Documentos fiscais de mercadorias (NF, NFe, NFC-e) |
| D | Documentos fiscais de servicos de transporte (CT-e) |
| E | Apuracao de ICMS e IPI (registros E100, E110, E111, E115, E116, E200, E210, E220) |
| G | CIAP - Controle de Credito de ICMS do Ativo Permanente |
| H | Inventario fisico |
| K | Controle de producao e estoque |
| 1 | Informacoes complementares (operacoes com cartao de credito, combustiveis, exportacao, etc.) |
| 9 | Controle e encerramento do arquivo |

**Tabelas envolvidas:**
- SFT (leitura) - Livro Fiscal por Item
- SF3 (leitura) - Livros Fiscais
- CDO (leitura) - Ajustes de Apuracao
- CDA (leitura) - Ajustes de Documentos
- CC6 (leitura) - Ajustes de Documentos Fiscais
- CCE (leitura) - Observacoes Complementares
- SB2 (leitura) - Saldos de Estoque (Bloco H)
- SB1 (leitura) - Cadastro de Produtos
- SA1/SA2 (leitura) - Clientes/Fornecedores
- SN3 (leitura) - CIAP - Ativo Imobilizado (Bloco G)

**Parametros relevantes:**
| Parametro | Descricao |
|-----------|-----------|
| MV_USASPED | Habilita geracao do SPED Fiscal |

**Pontos de entrada:**
| Ponto de Entrada | Descricao |
|------------------|-----------|
| SPDPIS09 | Adiciona linhas nos registros F100, 0150, 0500 e 0600 |
| MTA920L | Manipulacao dos livros fiscais SF3 na escrituracao |
| XFCD2SFT | Permite alteracao do Livro Digital de Impostos (CD2) |

---

### MATA950 - Instrucoes Normativas (Arquivos Magneticos)

**O que faz:** Gera arquivos magneticos para diversas obrigacoes acessorias municipais, estaduais e federais. A rotina e parametrizada por tipo de obrigacao e permite a geracao de declaracoes eletronicas como DES (Declaracao Eletronica de Servicos), GIA, DAPI, DCTF, entre outras, conforme a legislacao de cada UF e municipio.

**Tabelas envolvidas:**
- SFT (leitura) - Livro Fiscal por Item
- SF3 (leitura) - Livros Fiscais
- SA1/SA2 (leitura) - Clientes/Fornecedores

---

### FISA170 - Configurador de Tributos (CFGTRIB)

**O que faz:** Centralizador de configuracao de regras tributarias genericas. Reune os principais elementos de uma operacao fiscal (estados de origem/destino, produtos, clientes, fornecedores, CFOPs) em registros isolados, permitindo configurar cenarios tributarios complexos sem necessidade de customizacao ADVPL. Suporta configuracao de ICMS, IPI, PIS, COFINS, ISS e impostos retidos.

**Funcionalidades:**
- Regras Fiscais: configuracao de CST, base de calculo, aliquotas por combinacao de UF/NCM/CFOP
- Regras Financeiras: configuracao de retencoes (IRRF, PIS, COFINS, CSLL, ISS, INSS)
- Tabelas progressivas para impostos retidos
- Simulador comparativo de tributacao
- Regras por NCM com MVA e aliquota por UF de origem/destino

**Tabelas envolvidas:**
- CG1/CG2/CG3 (escrita) - Regras do Configurador de Tributos
- SF4 (leitura) - TES
- SB1 (leitura) - Produtos

---

## Processos de Negocio

### Fluxo Completo Fiscal

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  1. Configuracao │────>│  2. Escrituracao │────>│  3. Apuracao de  │
│  da TES          │     │  de NF (E/S)    │     │  Impostos        │
│  MATA080 / SF4   │     │  SFT / SF3      │     │  MATA953/952     │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                          │
┌─────────────────┐     ┌─────────────────┐     ┌────────v────────┐
│  6. Recolhimento │<────│  5. Obrigacoes  │<────│  4. Apuracao     │
│  (Guias)         │     │  Acessorias     │     │  PIS/COFINS      │
│  SE2             │     │  SPDFIS/EFDCON  │     │  EFDCON          │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

#### Passo 1: Configuracao da TES (MATA080)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA080 |
| **Tabelas** | SF4 (escrita) |
| **O que acontece** | Cadastro dos Tipos de Entrada e Saida que definem o comportamento fiscal de cada operacao. Configura-se: CFOP, calculo de impostos (ICMS, IPI, PIS, COFINS, ISS), creditamento, CSTs, escrituracao nos livros fiscais, atualizacao de estoque e geracao de duplicatas. Cada operacao (venda, compra, transferencia, remessa, devolucao, consignacao) requer TES especifica. |
| **Resultado** | TES cadastrada na SF4, pronta para uso nas rotinas de NF |

#### Passo 2: Escrituracao da Nota Fiscal (MATXFIS)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | Automatico via MATXFIS (chamado por MATA103/MATA461) |
| **Tabelas** | SFT (escrita), SF3 (escrita), SF4 (leitura), CDA (escrita) |
| **O que acontece** | Ao classificar um documento de entrada (MATA103) ou emitir uma nota de saida (MATA461/MATA462), o MATXFIS e invocado automaticamente. O motor calcula todos os tributos do item com base na TES, produto, cliente/fornecedor, UF e demais parametros. Os resultados sao gravados nos livros fiscais (SFT por item, SF3 por nota). |
| **Resultado** | Documentos fiscais escriturados nos livros de entrada e saida |

#### Passo 3: Apuracao de ICMS (MATA953)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | MATA953 |
| **Tabelas** | SFT (leitura), SF3 (leitura), CDO (escrita), SE2 (escrita) |
| **O que acontece** | No encerramento do periodo (mensal), a rotina processa todos os livros fiscais e calcula: total de debitos (saidas tributadas), total de creditos (entradas com creditamento), ajustes (CDO - estornos, outros creditos/debitos), saldo credor anterior. O resultado e o saldo devedor (gera guia de recolhimento na SE2) ou saldo credor (transferido para o proximo periodo). |
| **Resultado** | Apuracao de ICMS calculada; guia de recolhimento gerada (se devedor) |

#### Passo 4: Apuracao de PIS/COFINS (EFDCON)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | EFDCON / FISA001 |
| **Tabelas** | SFT (leitura), CDH (escrita), SE2 (escrita) |
| **O que acontece** | Processa os livros fiscais e calcula: debitos de PIS/COFINS (sobre receitas), creditos (sobre aquisicoes habilitadas pelo regime nao-cumulativo), ajustes e diferimentos. Considera CSTs de PIS/COFINS configurados na TES. Gera valores de debito e credito por tipo de receita. |
| **Resultado** | Apuracao de PIS e COFINS calculada; titulos a pagar gerados |

#### Passo 5: Obrigacoes Acessorias (SPDFIS / EFDCON / MATA950)

| Aspecto | Detalhe |
|---------|---------|
| **Rotina** | SPDFIS (SPED Fiscal), EFDCON (EFD Contribuicoes), MATA950 (demais obrigacoes) |
| **Tabelas** | SFT, SF3, CDO, CDA, CC6, CCE (leitura) |
| **O que acontece** | Geracao dos arquivos digitais para transmissao ao Fisco: SPED Fiscal (EFD ICMS/IPI) contendo escrituracao completa e apuracao; EFD Contribuicoes contendo apuracao de PIS/COFINS; GIA (estadual); demais declaracoes conforme legislacao local. |
| **Resultado** | Arquivos magneticos gerados para transmissao |

#### Passo 6: Recolhimento (SE2)

| Aspecto | Detalhe |
|---------|---------|
| **Tabelas** | SE2 (gerada nos passos 3 e 4) |
| **O que acontece** | As guias de recolhimento (ICMS, IPI, PIS, COFINS) sao geradas automaticamente nas apuracoes e ficam disponiveis no modulo Financeiro (SIGAFIN) para pagamento/baixa. Os titulos seguem as datas de vencimento conforme calendario fiscal. |
| **Resultado** | Titulos de recolhimento na SE2 disponiveis para o Financeiro |

---

## Regras de Negocio

### Campos obrigatorios por rotina

**Cadastro de TES (MATA080 - SF4):**
- F4_CODIGO (Codigo da TES)
- F4_TIPO (Tipo: Entrada ou Saida)
- F4_CF (CFOP)
- F4_ICM (Calcula ICMS)
- F4_IPI (Calcula IPI)
- F4_LFICM (Livro Fiscal ICMS)
- F4_LFIPI (Livro Fiscal IPI)
- F4_ESTOQUE (Atualiza Estoque)
- F4_DUPLIC (Gera Duplicata)

**Apuracao de ICMS (MATA953):**
- Periodo de apuracao (data inicial e final)
- UF da apuracao (MV_ESTADO)
- Escrituracao dos livros fiscais (SFT/SF3) completa no periodo

**SPED Fiscal (SPDFIS):**
- Periodo de apuracao
- Apuracao de ICMS e IPI previamente processada

### Regras de configuracao da TES

| Regra | Descricao |
|-------|-----------|
| CFOP x Tipo | O CFOP (F4_CF) deve ser compativel com o tipo de operacao (F4_TIPO): CFOPs iniciados em 1/2/3 para entrada, 5/6/7 para saida |
| ICMS x Creditamento | Se F4_ICM = "S" e F4_CREDICM = "S", o ICMS sera creditado (abatido do custo). Se F4_CREDICM = "N", o ICMS sera estornado |
| IPI x Creditamento | Se F4_IPI = "S" e F4_CREDIPI = "S", o IPI sera creditado. Se F4_CREDIPI = "N", compora o custo do produto |
| Livro Fiscal | F4_LFICM determina a coluna de escrituracao no livro: T=Tributado (col. base/aliquota/imposto), I=Isento, O=Outros |
| PIS/COFINS | F4_PISCRED e F4_COFCRED definem se a operacao gera credito (S), debito (D) ou nao calcula (N) |
| Estoque | F4_ESTOQUE = "S" gera movimentacao no estoque (SD3/SB2); "N" nao movimenta |
| Financeiro | F4_DUPLIC = "S" gera titulo financeiro (SE1/SE2); "N" nao gera |
| Agrega Valor | F4_AGREG = "S" faz o item compor o total da NF; "N" nao agrega (ex: bonificacao) |
| TES Inteligente | A TES Inteligente permite selecao automatica da TES com base na operacao, produto e participante. Funciona via cadastro na tabela FM (rotina MATA089) |

### Validacoes principais

| Validacao | Descricao |
|-----------|-----------|
| Consistencia TES x CFOP | O sistema valida se o CFOP configurado na TES e compativel com a operacao realizada |
| CST x Calculo | O CST informado deve ser coerente com o calculo configurado (ex: CST 00 exige calculo de ICMS) |
| Apuracao sequencial | A apuracao de ICMS/IPI deve ser processada apos a escrituracao completa dos documentos do periodo |
| SPED x Apuracao | O SPED Fiscal so deve ser gerado apos a apuracao de ICMS e IPI |
| Chave NFe | Para notas eletronicas, a chave (F3_CHVNFE) e obrigatoria |
| Periodo bloqueado | Uma vez gerado o SPED e transmitido, o periodo fiscal nao deve ser reaberto sem procedimento de retificacao |
| Operacao interestadual | Para operacoes interestaduais, o sistema valida a UF do participante contra MV_ESTADO para aplicar aliquotas corretas |
| DIFAL | Para operacoes interestaduais destinadas a consumidor final nao contribuinte, calcula DIFAL (EC 87/2015) |

### Gatilhos SX7 relevantes

| Campo origem | Campo destino | Regra | Tabela lookup |
|-------------|---------------|-------|---------------|
| F4_CF | F4_DESCRI | Descricao do CFOP | CFC |
| D1_TES | D1_CF | SF4->F4_CF | SF4 |
| D2_TES | D2_CF | SF4->F4_CF | SF4 |
| D1_TES | D1_TIPO | SF4->F4_TIPO | SF4 |

### Pontos de entrada mais utilizados no modulo

| Ponto de Entrada | Rotina | Descricao |
|------------------|--------|-----------|
| MA080BUT | MATA080 | Adiciona botoes no cadastro de TES |
| MA080TOK | MATA080 | Validacao customizada na TES |
| MTA920L | MATA920 | Manipulacao dos livros fiscais SF3 |
| MTA920C | MATA920 | Manipulacao do cabecalho da nota no livro fiscal |
| XFCD2SFT | Escrituracao | Permite alteracao do Livro Digital de Impostos (CD2) |
| FA953INC | MATA953 | Pos-inclusao na apuracao de ICMS |
| SPDPIS09 | EFDCON | Adiciona registros F100, 0150, 0500, 0600 no EFD Contribuicoes |

---

## Integracoes

### Fiscal ← Compras (NF de Entrada)

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na classificacao do Documento de Entrada (MATA103) |
| **O que acontece** | Ao classificar a NF de entrada, o MATXFIS calcula os impostos do item com base na TES (SF4) e escreve nos livros fiscais de entrada (SFT/SF3). Os valores de ICMS, IPI, PIS, COFINS e demais tributos sao calculados automaticamente e ficam disponiveis para apuracao |
| **Tabelas afetadas** | SFT (Livro Fiscal por Item), SF3 (Livros Fiscais), CDA (Ajustes) |
| **Observacao** | A TES da NF de entrada (D1_TES) determina se havera creditamento de ICMS, IPI, PIS e COFINS |

### Fiscal ← Faturamento (NF de Saida)

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na emissao da NF de saida (MATA461/MATA462) |
| **O que acontece** | Ao gerar a NF de saida, o MATXFIS calcula os impostos e escreve nos livros fiscais de saida (SFT/SF3). Os valores de ICMS, IPI, PIS, COFINS, ISS e ICMS-ST sao calculados e escriturados conforme a TES (D2_TES) |
| **Tabelas afetadas** | SFT (Livro Fiscal por Item), SF3 (Livros Fiscais) |
| **Observacao** | A configuracao do faturamento (tipo de NF, cliente, UF) influencia diretamente o calculo fiscal |

### Fiscal → Contabilidade

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na escrituracao dos documentos fiscais e nas apuracoes |
| **O que acontece** | Os lancamentos contabeis de impostos sao gerados conforme o Lancamento Padrao (CT5) configurado na TES. Na apuracao, os saldos devedores/credores de ICMS, IPI, PIS e COFINS geram lancamentos de transferencia para as contas de imposto a recolher ou a recuperar |
| **Tabelas afetadas** | CT2 (Lancamentos Contabeis) |
| **Observacao** | A contabilizacao pode ser online (no momento da escrituracao) ou offline (por processamento em lote) |

### Fiscal → Financeiro (Guias de Recolhimento)

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Nas apuracoes de ICMS (MATA953), IPI (MATA952) e PIS/COFINS (EFDCON) |
| **O que acontece** | Quando a apuracao resulta em saldo devedor, o sistema gera automaticamente titulos a pagar na SE2, representando as guias de recolhimento dos impostos apurados. Os titulos sao gerados com vencimento conforme o calendario fiscal |
| **Tabelas afetadas** | SE2 (Titulos a Pagar) |
| **Observacao** | Os titulos ficam disponiveis no SIGAFIN para pagamento/baixa. A natureza financeira e prefixo do titulo identificam o tipo de imposto |

### Fiscal ← Ativo Fixo

| Aspecto | Detalhe |
|---------|---------|
| **Quando** | Na geracao do EFD Contribuicoes e SPED Fiscal |
| **O que acontece** | O modulo de Ativo Fixo (SIGAATF) fornece dados para os blocos F120/F130 do EFD Contribuicoes (credito de PIS/COFINS sobre ativo imobilizado) e para o Bloco G do SPED Fiscal (CIAP - credito de ICMS sobre ativo permanente) |
| **Tabelas afetadas** | CL2 (Dados Ativo p/ EFD), SN3 (CIAP) |

### Resumo das integracoes do modulo Fiscal

```
                    NF Entrada                NF Saida
                    (MATA103)                 (MATA461)
                        │                         │
                        └──────────┬──────────────┘
                                   │
                              ┌────v─────┐
                              │ MATXFIS  │
                              │ (Calculo)│
                              └────┬─────┘
                                   │
                         ┌─────────v──────────┐
                         │   SFT / SF3        │
                         │ (Livros Fiscais)   │
                         └─────────┬──────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
      ┌───────v───────┐   ┌───────v───────┐   ┌───────v───────┐
      │  Apuracao      │   │  Apuracao     │   │  Apuracao     │
      │  ICMS (953)    │   │  IPI (952)    │   │  PIS/COF      │
      │                │   │               │   │  (EFDCON)     │
      └───────┬───────┘   └───────┬───────┘   └───────┬───────┘
              │                    │                    │
              └────────────────────┼────────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
      ┌───────v───────┐   ┌───────v───────┐   ┌───────v───────┐
      │ SPED Fiscal   │   │ EFD Contrib.  │   │  Financeiro   │
      │ (SPDFIS)      │   │ (EFDCON)      │   │  SE2 (Guias)  │
      └───────────────┘   └───────────────┘   └───────────────┘
```

---

## Cadastros Auxiliares

| Rotina | Descricao | Tabela |
|--------|-----------|--------|
| MATA080 | Tipos de Entrada e Saida (TES) | SF4 |
| FISA170 | Configurador de Tributos | CG1/CG2/CG3 |
| FISA099 | Cadastro CFOP - Motivo de Ajuste | CFC |
| FISA092 | Cadastro Tabela IBPT (De Olho no Imposto) | F00 |
| CADSPED | Codigos de Lancamento e Reflexos da Apuracao | CDO/CC6/CC7 |
| CADUF | Regras UFxUF (aliquotas interestaduais) | CCE |
| MATA920 | Lancamento Fiscal Manual (escrituracao manual em SF3/SFT) | SF3/SFT |

---

## Parametros Globais do Modulo (MV_*)

| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| MV_ESTADO | C | UF da empresa (2 caracteres) |
| MV_ESTICM | C | Aliquotas de ICMS por UF (formato: UF+Aliq) |
| MV_ICMPAD | N | Aliquota padrao de ICMS |
| MV_BASDUPL | L | Base dupla para calculo de DIFAL |
| MV_SUBTRIB | L | Habilita sub-tributacao de ICMS |
| MV_CREDICM | L | Abatimento do ICMS no custo |
| MV_USASPED | L | Habilita geracao SPED Fiscal |
| MV_EASY | L | Habilita uso do EIC (Easy Import Control) |
