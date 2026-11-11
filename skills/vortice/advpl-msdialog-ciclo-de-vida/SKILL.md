---
name: advpl-msdialog-ciclo-de-vida
description: Evita o erro "variable is not an object" em telas MSDIALOG do Protheus/AdvPL. Depois que ACTIVATE MSDIALOG retorna (oDlg:End() ou X), o dialogo e seus controles sao destruidos e qualquer mensagem (oLbx:nAt, oGet:Refresh(), oDlg:...) derruba a thread. Usar quando o erro "variable is not an object" apontar para linha logo apos ACTIVATE MSDIALOG, quando um fonte .prw/.prg/.tlpp ler valor de controle depois do ACTIVATE, ou antes de escrever tela modal nova. Regra unica: capturar os valores dentro do ACTION/VALID, antes do End(); depois do ACTIVATE usar somente variaveis guardadas. Complementa a advpl-msdialog-dimensionamento (tamanho da moldura).
argument-hint: <arquivo .prw e faixa de linhas da tela>
user-invocable: true
---

# Ciclo de vida de controles em MSDIALOG (AdvPL)

## Visao geral

`ACTIVATE MSDIALOG` so retorna quando a tela fecha. Nesse momento o Protheus
destroi o dialogo e **todos os controles criados com `OF oDlg`** (GET, BUTTON,
LISTBOX, TCBrowse, combo...). A variavel Local que apontava para o controle
deixa de ser um objeto vivo: enviar mensagem a ela (`oLbx:nAt`, `oGet:Refresh()`)
gera `variable is not an object` e derruba a thread do usuario.

Regra unica desta Skill:

> Nenhum `oControle:` nem `oDlg:` depois do `ACTIVATE MSDIALOG` da mesma funcao.
> Os valores sao capturados em variaveis dentro do ACTION/VALID, enquanto a tela
> esta viva; depois do ACTIVATE usa-se apenas a variavel guardada.

## Quando disparar

- THREAD ERROR `variable is not an object` em linha logo apos `ACTIVATE MSDIALOG`.
- Fonte que le `oLbx:nAt`, `oGet:...`, `oDlg:...` depois do ACTIVATE.
- Vai criar ou revisar uma tela modal (Modelo 1) antes de compilar.

## Etapa 1 - separar objeto de variavel de tela

- **Variavel ligada no `VAR cX` do GET** (ex.: `cObs`, `cCombo`): e variavel de
  memoria, sobrevive ao fechamento. Pode ler depois do ACTIVATE.
- **Objeto do controle** (`oGet`, `oLbx`, `oBtn`, `oDlg`): morre com a tela.
  So pode receber mensagem enquanto a tela esta aberta (dentro de ACTION,
  VALID, WHEN, bLine, ou antes do ACTIVATE).
- **Objeto externo ao dialogo** (ex.: `oBrowse` recebido por parametro): nao foi
  destruido; pode usar depois do ACTIVATE.

## Etapa 2 - padrao errado e certo

Errado (incidente real na funcao PesquisaUsuario de `FONTES/ZSOLNF.PRW`,
compilado em 10/11/2026: o erro caiu na linha 490, um `nSel := oLbx:nAt` logo
apos o ACTIVATE; no fonte atual a correcao esta nas linhas 478-495):

```advpl
ACTIVATE MSDIALOG oDlg CENTERED
If lOk
    nSel := oLbx:nAt        // THREAD ERROR: a lista ja foi destruida
EndIf
```

Certo (como ficou em `FONTES/ZSOLNF.PRW:478-495`):

```advpl
Local nSel := 0
Local lOk  := .F.

@ 026,010 BUTTON oBtnOk PROMPT "Pesquisar" SIZE 70,016 OF oDlg PIXEL ;
    ACTION ( nSel := oLbx:nAt, lOk := .T., oDlg:End() )
@ 026,100 BUTTON oBtnCanc PROMPT "Cancelar" SIZE 70,016 OF oDlg PIXEL ;
    ACTION oDlg:End()

ACTIVATE MSDIALOG oDlg CENTERED

If lOk                      // fechou no X ou Cancelar: lOk fica .F.
    If nSel >= 1 .And. nSel <= Len(aUsu)
        cFiltUsu := aUsu[nSel][1]
    EndIf
EndIf
```

Pontos do padrao certo:

1. A captura (`nSel := oLbx:nAt`) roda no ACTION, com a tela viva.
2. `oDlg:End()` por ultimo, na mesma ACTION.
3. X e Cancelar nao setam `lOk`/`nSel`: o codigo pos-ACTIVATE trata como cancelamento.
4. Depois do ACTIVATE so entram `lOk`, `nSel`, `aUsu` e objetos externos.

## Etapa 3 - verificacao deterministica

Rode o script no fonte alterado (ele varre cada funcao, coleta os controles
criados entre DEFINE e ACTIVATE e acusa qualquer mensagem a eles depois do
ACTIVATE):

```powershell
python skills\vortice\advpl-msdialog-ciclo-de-vida\scripts\check_pos_activate.py FONTES\ZSOLNF.PRW
```

Saida `VEREDITO: OK` = nenhuma leitura pos-ACTIVATE detectada; codigo de saida 1
quando ha ocorrencia. O script cobre os macros `@ ... GET/BUTTON/LISTBOX/... oVar`
e `oVar := Classe():New(...)` na mesma linha do `oDlg`; `New()` multilinha pode
escapar - a revisao da Etapa 2 continua obrigatoria.

## Anti-padroes

1. **Ler o controle depois do ACTIVATE** para "pegar a escolha do usuario".
   Foi o incidente do PesquisaUsuario: funcionava ate o clique em Pesquisar,
   quando a leitura pos-fechamento derrubava a thread.
2. **Mover a leitura para uma Static Function chamada depois do End()**. O
   controle continua destruido; o erro so muda de pilha.
3. **Guardar o objeto em Private para "sobreviver"**. Private nao impede a
   destruicao do controle pelo dialogo.
4. **Confundir com a variavel do VAR**: ler `cCombo` depois do ACTIVATE e legitimo;
   ler `oCombo:cCaption` nao e.

## Checklist

- [ ] nenhuma mensagem `oControle:` / `oDlg:` apos o ACTIVATE da mesma funcao
- [ ] valores capturados em Local/Private dentro do ACTION/VALID, antes do End()
- [ ] X/Cancelar deixam a variavel de captura no valor inicial e o codigo trata como cancelamento
- [ ] pos-ACTIVATE usa so variaveis de memoria, vetores e objetos externos (oBrowse)
- [ ] `check_pos_activate.py` rodado com VEREDITO: OK
- [ ] moldura conferida com a skill advpl-msdialog-dimensionamento (tela nova)

## Recursos

- `scripts/check_pos_activate.py` - detector deterministico de leitura pos-ACTIVATE.
- Skill irma: `advpl-msdialog-dimensionamento` (moldura 2x o bounding box).