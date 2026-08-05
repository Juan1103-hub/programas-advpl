# Skill: Convenções da Empresa — AdvPL/Protheus

> Regras específicas da empresa para desenvolvimento no módulo SIGAEST.
> Aplicar em todo código gerado antes de implementar.

## 1. Regras de Implementação

### 1.1. Banco de Dados
- **SQL Server** como banco de dados principal
- Usar `BeginSQL`/`EndSQL` com `%Table:%` e `%NotDel%` para consultas
- **Nunca** usar `SELECT *` — listar campos explicitamente
- Preferir `WITH (NOLOCK)` em consultas de leitura (via TopConnect)
- Limpar campo data: `Replace CAMPO_DT With CtoD("  /  /  ")` — nunca NULL

### 1.2. Filial
- **Sempre** usar `xFilial("ALIAS")` em filtros
- Nunca hardcodar código de filial (`'01'`, `'02'`, etc.)

### 1.3. Validação e Segurança
- SQL com parâmetros (`?` ou `:param`) — **nunca concatenar** entrada do usuário
- Validar parâmetros de entrada no início da função
- `GetArea()` / `RestArea()` em toda função com alias

### 1.4. Performance
- Evitar `dbGoTop()` — usar `dbSeek()` ou `MsSeek()` com índice adequado
- SX3/SIX consultas fora de loops
- `RecLock` apenas quando for gravar efetivamente

### 1.5. Tratamento de Erros
- Usar `Begin Transaction` / `End Transaction` em operações críticas
- Logar erros com `ConOut()` ou `FWLog()`
- Sempre verificar `lRet` de `MsExecAuto`

## 2. Convenções de Nomenclatura

- **Funções**: Prefixo `Z` + mnemonico (ex: `ZCTAEST`, `ZSLDEST`)
- **PEs**: Prefixo do módulo + número + mnemonico (ex: `MTA103OK`, `MT110CON`)
- **Variáveis**: Prefixo TOTVS (`c`, `n`, `d`, `l`, `a`, `o`)
- **Tabelas temporárias**: Prefixo `TRB` ou `TMP`

## 3. Fluxo Obrigatório

1. Agente pergunta: "Posso implementar? Segue a abordagem..."
2. Usuário confirma ou ajusta
3. Agente implementa
4. Agente mostra o código gerado e pergunta se deseja compilar
