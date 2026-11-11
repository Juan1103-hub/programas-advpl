# MTA185MNU: coluna Posicao cortada no PDF do TReport (ZC1_POSIC)

**Data**: 2026-10-15 | **Fonte**: FONTES/MTA185MNU.PRW | **Status**: resolvido (confirmado pelo usuário)

## Problema
No relatorio "Baixa de Pre-Requisicao ao Armazem" (PE MTA185MNU -> U_f185ImpRel),
o valor de ZC1_POSIC (ex.: "PRT-06B-C-D", 13 caracteres) aparecia cortado no PDF
como "PRT-05C" / "PRT-06B-C-" (exatamente 10 caracteres).

## Causa
TRCell da celula ZC1_POSIC definida com largura fixa 10, MENOR que o conteudo real
gravado em banco. TReport trunca a string na largura da celula - nao quebra linha.
Duas armadilhas presentes:
1. Largura hardcoded menor que o conteudo real (10 vs 13/15).
2. Confiar em TamSx3()[1] NAO garante nada: o campo custom pode ter X3_TAMANHO
   menor que o conteudo real gravado (dicionario desatualizado vs dado de banco).

## Fix
FONTES/MTA185MNU.PRW:50 - largura fixa generosa de 20:
```advpl
TRCell():New(oSection, "ZC1_POSIC", "QRY_SA", "Posicao", Nil, 20, .F., Nil, "LEFT", Nil, "LEFT")
```
Confirmado pelo usuario ("deu certo") apos recompilar e reimprimir a SA 009006.

## Como aplicar (REGRAS para largura de texto/celula em todas as IAs)
1. Largura de TRCell / coluna de relatorio / grid SEMPRE precisa caber o CONTEUDO
   REAL exibido - verificar o maior valor possivel antes de fixar (APSDU/SQL no maximo).
2. NUNCA confiar so no TamSx3(campo)[1] para tamanho de coluna de relatorio: se o
   campo custom tem conteudo maior que o X3_TAMANHO, corta igual. Preferir largura
   fixa generosa (ex.: 20) quando ha folga no layout.
3. Report paisagem A4 tem folga: maior largura de coluna nao quebra as outras -
   mas conferir soma antes, e nunca reduzir as demais colunas sem conferir o
   maior valor delas tambem.
4. Mesmo sintoma, causa diferente (ZATUDESC): campo custom cortado em 10 caracteres
   na TELA = suspeitar de campo MEMO + PADR(texto, TamSX3[1]) - NUNCA usar PADR
   com TamSX3 em campo possivelmente MEMO.
5. Depois de mudar largura de celula: SEMPRE recompilar antes de concluir teste -
   RPO antigo executa a largura velha e o sintoma parece nao ter mudado.
