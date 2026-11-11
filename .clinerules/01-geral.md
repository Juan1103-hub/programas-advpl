# 01 - Regras Gerais (sempre ativas)

> Escopo: todo o workspace `PROGRAMAS_ADVPL`. Fonte de verdade: o codigo em `FONTES/`.
> Se doc conflitar com o codigo real, o codigo vence e a divergencia deve ser registrada.

## Projeto

- Cliente: **Vortice Consultoria Mineral** — modulo **Suprimentos/Compras** (SC7 tomadas centrais).
- ERP **TOTVS Protheus 12**, build `7.00.240223P`, banco **SQL Server**.
- Servidor: AppServer `CINVJ6_DEV` (`vortice192877.protheus.cloudtotvs.com.br:10771`).
- **Nunca** expor token de `CONFIG/servers.json` em docs, logs ou commits.

## Idioma obrigatorio

- Toda interacao, comentario, commit e revisao em **portugues brasileiro**.
- Identificadores de codigo seguem convencao tecnica (ingles/abreviacoes Protheus).
- Textos de tela (legendas, mensagens, ajuda, titulos, filtros): portugues claro e completo,
  **sem abreviacoes** (ex.: "Dias de Estoque", nunca "DOS") e **sem termos em ingles**
  (ex.: "Tempo de Reposicao", nunca "Lead Time"). Excecao minima: nomes tecnicos que o
  usuario ja ve no sistema (`B1_EMAX`, rotina MATA110).

## Hierarquia de documentacao (precedencia)

1. Instrucoes do usuario
2. Obsidian `06 - Bugs Resolvidos.md` (solucao documentada tem precedencia)
3. `CONFIG/AGENTS.md` (SUPER-regras SIGAEST — tabelas core, acesso a dados)
4. `AGENTS.md` raiz (convencoes, padroes, checklist)
5. `CLAUDE.md` / `docs/`
6. Skills em `skills/advpl-tlpp`, `skills/superpowers`, `skills/vortice` (+ `skills/unlazy` por leitura direta)
7. TDN oficial (tdn.totvs.com) + fontes web confiaveis

## Memoria tecnica

- Vault Obsidian: `C:\Users\Vortice 0097\Desktop\BKP_JUAN\Memoria\Memoria\ADVPL-Protheus\`
  (bugs em `06 - Bugs Resolvidos.md`, padroes em `07`, tabelas em `08`, PEs em `05`).
- Fallback versionado (quando o vault estiver inacessivel): `.opencode/memory/` (`MEMORY.md` + `bugs/`).
- Bug novo resolvido: registrar no Obsidian **e** no fallback, formato Problema -> Causa -> Fix -> Como aplicar.
- Antes de codar ou debugar, consultar a memoria. Antes de assumir campo/valor, validar via APSDU.
