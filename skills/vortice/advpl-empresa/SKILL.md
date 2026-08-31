---
name: advpl-empresa
description: 'Skill Vortice custom advpl-empresa - SC7/CINVJ6_DEV 7.00.240223P'
---

# Skill: ConvenÃ§Ãµes da Empresa â€” AdvPL/Protheus

> Regras especÃ­ficas da empresa para desenvolvimento no mÃ³dulo SIGAEST.
> Aplicar em todo cÃ³digo gerado antes de implementar.

## 1. Regras de ImplementaÃ§Ã£o

### 1.1. Banco de Dados
- **SQL Server** como banco de dados principal
- Usar `BeginSQL`/`EndSQL` com `%Table:%` e `%NotDel%` para consultas
- **Nunca** usar `SELECT *` â€” listar campos explicitamente
- Preferir `WITH (NOLOCK)` em consultas de leitura (via TopConnect)
- Limpar campo data: `Replace CAMPO_DT With CtoD("  /  /  ")` â€” nunca NULL

### 1.2. Filial
- **Sempre** usar `xFilial("ALIAS")` em filtros
- Nunca hardcodar cÃ³digo de filial (`'01'`, `'02'`, etc.)

### 1.3. ValidaÃ§Ã£o e SeguranÃ§a
- SQL com parÃ¢metros (`?` ou `:param`) â€” **nunca concatenar** entrada do usuÃ¡rio
- Validar parÃ¢metros de entrada no inÃ­cio da funÃ§Ã£o
- `GetArea()` / `RestArea()` em toda funÃ§Ã£o com alias

### 1.4. Performance
- Evitar `dbGoTop()` â€” usar `dbSeek()` ou `MsSeek()` com Ã­ndice adequado
- SX3/SIX consultas fora de loops
- `RecLock` apenas quando for gravar efetivamente

### 1.5. Tratamento de Erros
- Usar `Begin Transaction` / `End Transaction` em operaÃ§Ãµes crÃ­ticas
- Logar erros com `ConOut()` ou `FWLog()`
- Sempre verificar `lRet` de `MsExecAuto`

## 2. ConvenÃ§Ãµes de Nomenclatura

- **FunÃ§Ãµes**: Prefixo `Z` + mnemonico (ex: `ZCTAEST`, `ZSLDEST`)
- **PEs**: Prefixo do mÃ³dulo + nÃºmero + mnemonico (ex: `MTA103OK`, `MT110CON`)
- **VariÃ¡veis**: Prefixo TOTVS (`c`, `n`, `d`, `l`, `a`, `o`)
- **Tabelas temporÃ¡rias**: Prefixo `TRB` ou `TMP`

## 3. Fluxo ObrigatÃ³rio

1. Agente pergunta: "Posso implementar? Segue a abordagem..."
2. UsuÃ¡rio confirma ou ajusta
3. Agente implementa
4. Agente mostra o cÃ³digo gerado e pergunta se deseja compilar

