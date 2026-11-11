# Edit-tool corrompe acentos CP-1252 em round-trip (ZMM01.PRW)

**Data**: 2026-10-20 · **Fonte**: FONTES/ZMM01.PRW · ** Classe de bug**: mesma família de `zanalprc-mojibake-acentos`

## Problema
Arquivo `.prw` em CP-1252 (bytes E7/E3/F3 etc. corretos) foi editado pela tool `edit` do agente
(6 edições pequenas em C2051/filter queries). Cada edit fez round-trip decode/encode do arquivo
INTEIRO: os acentos CP-1252 viraram sequências UTF-8 `EF BF BD` (U+FFFD) → 368 acentos destruídos
(~1101 bytes high-byte → 1104 bytes de EFBFBD). Compilou sem erro de sintaxe, mas UI/títulos
abririam com caracteres truncados.

## Causa raiz
`edit`/`write` do agente assumem UTF-8; CP-1252 (não-UTF-8) é decodificado com replacement ou
re-encodado, destruindo acentos ao gravar de volta. Vale para QUALQUER `.prw/.prg/.prx/.tlpp/.ppx`
do workspace, pois todos devem estar em CP-1252.

## Fix (recuperação)
1. **NÃO** usar git como recuperação — a versão HEAD era antiga (54 KB, ASCII, sem as features).
2. **VS Code Local History** salvou snapshots em
   `C:\Users\Vortice 0097\AppData\Roaming\Code\User\History\<hash>\` — o mais recente
   (`xm53.PRW`, entries.json aponta recurso → FONTES/ZMM01.PRW) tinha os **368 acentos intactos**
   (bytes CP-1252, decode legível). Procurar snapshot por `entries.json` (campo `resource`).
3. Script Python de reparo: para cada linha com U+FFFD no arquivo corrompido, casar no snapshot a
   linha com mesmo esqueleto ASCII + mesma contagem de não-ASCII (match exato por estrutura) e
   trocar a linha. Linhas novas do próprio agente → patch manual com texto conhecido.
4. Gravar com `bytes.encode('cp1252')`; validação: 0 `efbfbd`, `cp1252` round-trip lossless,
   diff contra snapshot = só mudanças lógicas intencionais (9 linhas).
5. Backup do arquivo corrompido em `%TEMP%\opencode\ZMM01.PRW.broken-utf8-bak`.

## Como aplicar (regra definitiva)
- **Nunca** usar `edit`/`write` nativos do agente em fontes CP-1252.
- Para mudanças: Python com bytes (`open(path,'rb')` → decode cp1252 → edit texto → encode cp1252 →
  write binário), OU converter arquivo para UTF-8 temporariamente e reverter imediatamente — a
  primeira opção é mais segura.
- Sempre validar depois: bytes verificados (_`probe_bytes.ps1` padrão: EFBFBD=0 + high-bytes +
  valid-strict-utf8=False = CP-1252 correto_).
- VS Code Local History do usuário é fonte de resgate para acentos → nunca descartar antes de checar.
