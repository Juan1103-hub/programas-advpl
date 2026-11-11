# Índice de Memórias — AdvPL/TLPP Vortice

> Uma linha por memória. Formato: `- [Título](arquivo.md) — hook`
> Pastas reais: `bugs/`, `padroes/`, `pes/` (+ templates `TEMPLATE-*.md`).

## Bugs Resolvidos

- [C7_QUANT negativo em devolução](bugs/c7-quant-negativo.md) — validação em MTA110OK
- [ZANALPRC mojibake acentos](bugs/zanalprc-mojibake-acentos.md) — UTF-8 misturado com CP-1252, normalizar pares C3xx
- [ZMMA01 erros SQL alias/GROUP BY](bugs/zmma01-alias-sql-erro.md) — SELECT B9. vs FROM SB9; MX.MAXDT fora do GROUP BY (4104/8120)
- [ZMMA01 Detalhes janela mês completo](bugs/zmma01-detalhes-janela-mes.md) — aumento dentro do mês era invisível (janela era fim do mês vs hoje)
- [Freebuff SELF_SIGNED_CERT_IN_CHAIN](bugs/freebuff-cert-kaspersky.md) — KES 14.1 MITM HTTPS; fix NODE_EXTRA_CA_CERTS + PEM CA Kaspersky
- [NFEPREVTS descrição invadia NCM](bugs/nfeprevts-descricao-invade-ncm.md) — col DESC 110<114; fix 126+ajustes 563 + StrTran espaços duplos
- [SmartView 500 profile Pedido de Compra](bugs/smartview-500-profile-pedidocompra.md) — profile corrompido no SIGACFG/PROFMGR; excluir registros do usuário resolve
- [MTA185MNU Posição cortada no PDF](bugs/mta185mnu-posicao-cortada.md) — TRCell largura 10 < conteúdo; largura fixa generosa (20); nunca confiar só no TamSx3 p/ relatório
- [MCP remoto em runtime Node/Bun falha](bugs/mcp-remoto-ipv6-quebrado.md) — 2 causas: IPv6 sem rota (fix Disable-NetAdapterBinding ms_tcpip6) + serviço `opencode serve --service` com estado de rede congelado (fix: reiniciar serviço); supabase refresh OAuth automático após reinício
- [ZMM01 crash abertura](bugs/zmm01-crash-abertura.md) — SetUseFilter(.F.) não compilado (hooks não confiáveis), ExcluirReg truncada, declaração `U_` no nome
- [ZMM01 browse vazio por filial](bugs/zmm01-browse-vazio-filial.md) — RPO antigo com filtro estrito escondia registros de ZZA_FILIAL vazia; tela vazia = cruzar com SQL + suspeitar RPO
- [ZMM01 mojibake via edit-tool](bugs/zmm01-mojibake-edit-tool.md) — edit/write nativos nunca mais em fonte CP-1252; reparo via snapshot VS Code Local History + script Python

## Padrões de Código

- [Notação húngara obrigatória](padroes/hungarian-notation.md) — prefixos c/n/d/l/a/o/b/x/j
- [SQL anti-injection canônico](padroes/sql-anti-injection.md) — FWExecStatement + ChangeQuery + RetSqlName
- [SD3 entrada/saída pela TM](padroes/sd3-tm-fronteira-500.md) — D3_TM < '500' = entrada; nunca D3_CF (RE = saída); TM 500 é saída
- [MATA300 antes do MATA330](padroes/mata300-mata330-ordem-fechamento.md) — Refaz Saldos recompoem B2_QATU; SB9 sem B9_DATA; aListaFil via SM0
- [FWMBrowse query: refresh e limpar](padroes/fwbrowse-query-refresh-limpar.md) — SetQuery+Refresh no objeto (não alias na mão); CleanFilter; ParamBox no Webapp
- [ZBLQMAS bloqueio/desbloqueio em massa](padroes/zblqmas-bloqueio-massa-csv.md) — CSV Codigo;Situacao (1/2) -> B1_MSBLQL; mesmo fluxo do ZATUDESC
- [ZATUDESC atualização em massa de descrições](padroes/zatudesc-atualizacao-descricoes-csv.md) — CSV Codigo;DescRes;DescCom -> B1_DESC/B1_ZDESCF
- [ZANALPRC indicadores e CC autorizados](padroes/zanalprc-indicadores-cc.md) — AnpInd, nZANPSO1, IN de 26 centros de custo, títulos de coluna
- [Fechamento estoque x razão reconciliação](padroes/fechamento-estoque-x-razao-reconciliacao.md) — só coluna "custo medio (total)" bate; compor diferença cruzando baixas sem lançamento + custo médio reavaliado
- [ZREGUL campo SC->PC](padroes/zregul-campo-sc-pc.md) — C1_ZREGUL/C7_ZREGUL Sim/Nao; obrigatório SC; copia SC->PC via MT120ISC+MTA120G3 (só quando vazio)
- [Replicação de campos do PC manual](padroes/pc-manual-replica-campos.md) — linha 1 -> demais (C7_XESTOQ1/C7_EC05DB/C7_ZREGUL/C7_TPFRETE), só-vazios, só-manuais; v2.4 = 4 gatilhos SX7 com RETORNO em C7_PRODUT; gatilho do frete faltava na SX7
- [PE botão via código MNU](padroes/pe-botao-codigo-mnu.md) — MA010BUT/MTA010MNU: código do PE de botão em MNU vs AddUserButton

## Pontos de Entrada

- [MA010BUT botão na MATA010](pes/ma010but-botao-mata010.md) — formato {icone, blocoDeAcao, titulo} p/ AddUserButton (NAO e aRotina), chama U_Zxxx()
- [MTA010MNU menu do browse MATA010](pes/mta010mnu-menu-browse-mata010.md) — AAdd direto no aRotina (sem PARAMIXB), abre U_ZATUDESC() e U_ZBLQMAS()

## Registros sem arquivo (entradas antigas do índice — arquivos nunca criados ou removidos)

- SC7 recálculo frete incorreto — PE MTA110INC
- ZZ4 deadlock em concorrência — FWExecAuto + GetArea
- Entry Points naming — arquivo = nome PE, sem U_, maiúsculo
- Encoding CP-1252 workflow — UTF-8 -> cp1252 -> RDMake
- SC7 tomadas centrais — filtros, índices, relacionamentos
- SB1 estoque/cobertura — B1_EMAX, B1_EMIN, B1_QEPS
- SA2 fornecedores — A2_COD, A2_LOJA, A2_MSBLQL
- ZZ4 custom Vortice — campos, chaves, triggers
- RecLock só em Z* — core usa MSExecAuto + GetArea/RestArea
- Sem UI em transação — MsgAlert/MsgYesNo/Aviso -> deadlock
- cFilial nunca direta — use cFilAux ou xFilial/FWxFilial
- IIF proibido — If/Else/EndIf explícito (CA4000)
- ModelDef FWFormModel — estrutura, campos, validações
- ViewDef FWFormView — grid, formulário, botões
- BrowseDef padrão — colunas, filtros, ações
- SX3 campos custom — X3_TIPO, X3_PICTURE, X3_VALID, X3_USADO
- Help/Explicação obrigatória — português claro, sem abreviações
- ZC7 campos extras SC7 — ZC7_DATAENT, ZC7_OBS, etc.
- ZD1 itens custom — estrutura, relacionamento SC7
- MTA110OK validação OK — pré-gravação SC7
- MTA110INC inclusão — defaults, validações
- MTA110DEL exclusão — regras, dependências
- MTA110BRW browse — colunas, filtros, ações
- AppServer CINVJ6_DEV — vortice192877.protheus.cloudtotvs.com.br:10771
- Build 7.00.240223P — versão, hotfixes conhecidos
- Módulo Suprimentos/Compras — escopo, rotinas core
- Freebuff + OpenCode stack — modelos free, CLI, skills locais

## Templates

- [TEMPLATE-BUG](TEMPLATE-BUG.md) — esqueleto para novo registro de bug
- [TEMPLATE-PADRAO](TEMPLATE-PADRAO.md) — esqueleto para novo registro de padrão
