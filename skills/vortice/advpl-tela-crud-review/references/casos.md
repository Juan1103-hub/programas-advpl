# Casos diagnosticados

Registro dos defeitos de funcionamento de tela ja encontrados, com causa raiz e
correcao. Consultar antes de revisar tela parecida.

---

## Caso 1 - CADPOSIC: exclusao travada com "tentativa de reservar registro alias ZC1 em EOF" (16/11/2026)

**Sintoma relatado**: "nao estou conseguindo excluir 1 item da lista" na tela de
Posicoes de Estoque do Item (ZC1). Ao clicar em Excluir aparecia erro do
framework: `TENTATIVA DE RESERVAR REGISTRO ALIAS ZC1 EM EOF - MSRLOCK`.

**Codigo com defeito** (antes):

```advpl
DbSelectArea("ZC1")
Count To nReg                       // deixa o alias em EOF
...
AxDeleta("ZC1", ZC1->(RecNo()), 5)  // RecNo() de EOF = registro inexistente
```

**Causa raiz**: `Count To` percorre a tabela e **posiciona o alias no fim do
arquivo**. O `RecNo()` lido depois nao era a linha selecionada na grade e sim o
numero do registro de EOF. O `AxDeleta` tentava travar esse registro
inexistente e estourava o `MSRLOCK`.

**Correcao** (aplicada):

```advpl
DbSelectArea("ZC1")
nRec := ZC1->(RecNo())   // guarda a linha selecionada ANTES do Count
Count To nReg
If nReg <= 1
    ...
EndIf
DbGoTo(nRec)             // volta para o registro selecionado
If ZC1->(Eof()) .Or. ZC1->(RecNo()) != nRec
    MsgStop("Registro selecionado nao encontrado. Atualize a lista.")
    Return
EndIf
AxDeleta("ZC1", nRec, 5)
If oBrowseZC1 != Nil
    oBrowseZC1:Refresh()
EndIf
```

**Licao**: nenhuma rotina custom de exclusao/alteracao pode ter `Count To`,
`DbGoTop`, `DbSeek` ou `DbSetOrder` entre a captura do registro e a gravacao.
Guardar o `RecNo()` na primeira linha e reposicionar com `DbGoTo` imediatamente
antes do `AxDeleta`/`RecLock`.

**Achados irmãos na mesma tela** (corrigidos juntos):

- `{"Imprimir","Imprimir",0,6}` no `aRotina` sem funcao `Imprimir` em nenhum
  fonte do repo - botao morto; removido.
- `FPOS_IMPORT` sem `Refresh()` no fim - a grade nao mostrava o que foi
  importado; `cLocal` reaproveitado da linha anterior e layout de 2 colunas
  contra CSV de 3; corrigidos os tres.
- `FPOS_LIMPAR` com `RecLock` sem conferir retorno - agora registro travado nao
  e apagado e entra na mensagem final.

**Pendente na epoca**: filtro de filial no browse, validacao de acesso nos
botoes destrutivos e reinsercao de codigo com registro excluido (soft-delete).

**Resolvido depois**: filtro de filial com `oBrowse:SetFilterDefault("@ZC1_FILIAL = '" + xFilial("ZC1") + "'")`
(padrao do ZLOGCOL), `GetArea`/`RestArea` em `FPOS_DELETA`, `FPOS_TabelaExiste`
e `FPOS_Saldo`, e `FPOS_LIMPAR` passou a apagar somente a filial do usuario.
Permissao continua pendente (depende de decisao de negocio).
