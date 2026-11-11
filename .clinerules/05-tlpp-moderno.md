---
paths:
  - "**/*.tlpp"
---

# 05 - TLPP Moderno (preferido p/ codigo novo)

- `using namespace` obrigatorio no topo; nunca namespace fully qualified no call.
- Declaracao de variavel com `as` **depois** da atribuicao:
  `Local cName := "" as Character` (certo); `Local cX as Character := ""` (**nao compila**).
- Tipos: `numeric`/`integer`/`decimal` (dinheiro)/`character`/`logical`/`date`/`json`/`array`/`object`.
- `class`/`endclass`: modificadores so na declaracao; implementacao sem modificador e sem `static`.
- Heranca com **`from`** (nunca `extends`/`inherits`); construtor filha chama `_Super:new()`.
- `static method`: na declaracao so `()` vazio; params/retorno vao na implementacao.
- REST por anotacao (`@Get`, `@Post`, `@Put`, `@Patch`, `@Delete`); cliente externo via `FWRest`.
- Try-Catch; `FWTemporaryTable` para temporarias; `Destroy()` da propria classe.
- Novo `.tlpp` em maiusculo; compilar contra AppServer apos converter UTF-8 -> CP-1252.
