# AGENTS.md — SIGAEST (Workspace-wide)

> Super-regras compartilhadas por TODOS os projetos do workspace
> `C:\totvs\advpl\.vscode\` (programas_vortice, Suprimentos, PATCH, etc).
> Regras de projeto especifico estao em cada `AGENTS.md` de FILHO.

## Base de Conhecimento — Obsidian

Vault com bugs resolvidos, padroes e tabelas do projeto — consultar ANTES de codar ou debugar:
`C:\Users\Vortice 0097\Desktop\BKP_JUAN\Memoria\Memoria\ADVPL-Protheus\`

| Situacao | Nota |
|----------|------|
| Bug / erro desconhecido | `06 - Bugs Resolvidos.md` |
| Padrao de codigo | `07 - Padroes de Codigo ADVPL.md` |
| Tabelas e filtros canonicos | `08 - Tabelas-Chave e Filtros.md` |
| MVC / ModelDef / ViewDef | `02 - MVC no Protheus.md` |
| SX3 / dicionario | `03 - SX3 e Dicionario de Dados.md` |
| ZZ4 / ZD1 / SA2 custom | `04 - Tabelas Customizadas.md` |
| Pontos de Entrada | `05 - Pontos de Entrada (PE).md` |

Ao resolver bug novo → registrar em `06 - Bugs Resolvidos.md`.

## Model Routing (referencia)

Modelos configurados globalmente em `~/.config/opencode/opencode.jsonc`:
- **Planejamento**: `opencode-go/deepseek-v4-pro`
- **Execucao**: `opencode-go/deepseek-v4-flash`
- **Visao**: `opencode-go/mimo-v2.5-pro` (via `image-analyzer`)

Para detalhes do fluxo, ver `~/.config/opencode/AGENTS.md` (Global).

## Stack Tecnologica Padrao

- **ERP**: TOTVS Protheus 12
- **Linguagem**: AdvPL e TLPP
- **Banco**: SQL Server (TopConnect via `TcQuery` ou `BeginSQL`)
- **UI**: FWFormModel/FWFormView (MVC) para novos; mBrowse/MSDIALOG para legados
- **Relatorios**: TReport
- **Encoding fonte**: CP1252 (IA gera UTF-8 → converter via `utf8-to-cp1252-conversion`)

## Regras de Acesso a Dados

1. **`GetArea()` / `RestArea()`** — obrigatorio em toda funcao que acessar alias.
   ```advpl
   Local aArea := GetArea()
   // ... acesso a dados ...
   RestArea(aArea)
   Return
   ```

2. **`xFilial("ALIAS")`** — em todos os filtros por filial. Nunca hardcode.

3. **RecLock APENAS para tabelas Z\*** (customizadas). Tabelas core (SC5, SC6, SC7, SD1, SD2, SF1, SF2, SB1, SA2, etc) → **MSExecAuto**.

4. **SQL seguro**: `%Table:%`, `%NotDel%`, parametros (`?` ou `:param`). Nunca concatenar entrada do usuario.

5. **Documentacao obrigatoria**: `/*/{Protheus.doc} ... /*/` em toda funcao publica.

6. **Notacao hungara**: `c`=char, `n`=num, `d`=date, `l`=logico, `a`=array, `o`=objeto, `b`=codeblock.

## Validacao de Dados via APSDU

Quando houver duvida sobre estrutura, campos ou valores na base:

1. **NAO assumir** — nao inventar campos, aliases ou valores.
2. **Gerar query SQL** e pedir que o usuario execute no APSDU:
   ```sql
   SELECT * FROM SB1010 WHERE B1_COD = 'XXXXX' AND D_E_L_E_T_ = ' '
   ```
3. **Aguardar o resultado** antes de gerar codigo.

## Historico de Workarounds

### FWLookup:BuildBrowse:SetAlias — Build 7.00.240223P
**Problema**: `Thread Error: Alias does not exist on FWBRWTABLE:SETALIAS`. Causa: SXB corrompida com 11 registros para alias `ZZ4`.
**Solucao**: `U_ZCONSZZ4()` limpa SXB + remove `X3_F3` + seta `X3_WHEN = "U_ZZ4SEL()"` + `X3_VALID = "U_FFZZ4A2()"`.

### U_ZZ4SEL / U_OPENZZ4 — FWBrowse incompativel com X3_WHEN no MVC
**Problema**: FWBrowse dentro de X3_WHEN conflita com `FWFormView:CanSetValue`. Solucao: BUTTONBAR entry point (`MT020BAR.PRW`) com botao "Solic." → `U_OPENZZ4()` → seta `M->A2_ZSOLID` → `U_FFZZ4A2()`.

### SXB + FWLookup (F3/lupa) — retorno a consulta padrao
**Problema**: Crash original era SXB corrompida, nao FWLookup. Solucao: SXB limpas com `ZCONSZZ4.PRW` (7 registros: PROG, colunas, retorno, filtro SQL) + `X3_INIBRW = "U_OPENZZ4()"`.
