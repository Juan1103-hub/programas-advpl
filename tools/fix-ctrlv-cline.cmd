@echo off
REM =====================================================================
REM  fix-ctrlv-cline.cmd  (Vortice, 15/10/2026)
REM  Aplica o unbind de Ctrl+V no Windows Terminal para que a tecla
REM  chegue ao Cline CLI (que le o clipboard: print -> [imagem]).
REM
REM  COMO USAR (importante!):
REM   1. FECHE TODAS as janelas do Windows Terminal (o WT regrava o
REM      settings.json ao fechar e desfaz qualquer edicao feita antes).
REM   2. Abra o cmd CLASSICO: Win+R -> digite cmd -> Enter (nao abre WT).
REM   3. Rode este arquivo (duplo clique tambem serve).
REM   4. Reabra o Windows Terminal e teste o Ctrl+V com um print no Cline.
REM =====================================================================
python "%~dp0fix-ctrlv-cline.py"
