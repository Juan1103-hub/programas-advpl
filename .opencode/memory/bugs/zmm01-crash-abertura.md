# ZMM01 — SmartClient fecha sem mensagem na abertura

**Data**: 2026-10-20 · **Fonte**: `FONTES/ZMM01.PRW` · **Status**: corrigido no fonte (pendente reteste pós-compilação)

## Problema
ZMM01 não abria: tela carregava e o SmartClient fechava sem mensagem de erro. Duas falhas adicionais encontradas na auditoria: `ExcluirReg` truncada e botão "Busca Rápida" apontando para função inexistente.

## Causa
1. **RPO desatualizado (causa do crash)**: comentário do fonte (~linhas 164-170) documenta crash `Alias does not exist` em `FWFILTEREDIT:GETFIELDS` quando o filtro do FWMBrowse fica habilitado — o browse usa `SetDataQuery(.T.)` + `SetAlias(TMP)` via `GetNextAlias`, que não tem alias no SX3. O fix `oBrowse:SetUseFilter(.F.)` estava no fonte, mas hooks de compilação da máquina não são confiáveis (AGENTS.md) → AppServer executava a versão antiga com filtro habilitado e derrubava a thread na abertura.
2. **`ExcluirReg` truncada** (pré-existente, fora do diff do dia): após o `MsgYesNo` de confirmação não havia UPDATE de exclusão lógica nem `Return` — o fluxo caía no início de `ExportaExcel`.
3. **Nome de User Function**: declaração `User Function U_BuscaRapidaZMM01()` com botão `{|| U_BuscaRapidaZMM01() }` — em AdvPL `U_X()` resolve para a função `X`; `U_U_X` nunca seria encontrada.

## Fix
1. Mantido `SetUseFilter(.F.)` e **compilação manual** (encoding convertido UTF-8 → CP-1252 via skill `utf8-to-cp1252-conversion`; hooks da máquina não confiáveis).
2. `ExcluirReg`: bloco de exclusão lógica via `TcSqlExec` — `UPDATE ZZAcEmpAnt3 SET D_E_L_E_T_ = '*' WHERE R_E_C_N_O_ = nRecno`, com `MsgAlert(TcSqlError())` em falha e `Return`.
3. Declaracao renomeada para `User Function BuscaRapidaZMM01()` (chamada continua `U_BuscaRapidaZMM01()`).

## Como aplicar (REGRAS)
1. FWMBrowse com dados de query (`SetDataQuery` + `GetNextAlias`) deve usar `SetUseFilter(.F.)` — o filtro padrão depende de alias registrado no SX3.
2. Hooks de save da máquina (converter/compilar) NÃO são confiáveis: converter para CP-1252 e compilar sempre manualmente (skills `utf8-to-cp1252-conversion` e `advpl-tlpp-compile`). Erro que "desaparece" sem mudança visível = suspeitar de RPO antigo.
3. `U_Func()` na chamada exige `User Function Func()` na declaração — o prefixo `U_` só aparece no chamador.
4. Script `.bat` de skill com espaço no caminho: PowerShell `& "path" "arg"` (`cmd /c` falha).
