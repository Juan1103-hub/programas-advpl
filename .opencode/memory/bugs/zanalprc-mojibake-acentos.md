# ZANALPRC — acentos quebrados (mojibake) em títulos de coluna

- **Data**: 2026-09-24
- **Arquivo**: `FONTES/ZANALPRC.PRW`
- **Severidade**: média (tela/Excel com caracteres inválidos)

## Problema
Títulos das colunas de valor unitário apareciam errados:
- Grid: `V.Unit Pen?ltimo` (o `ú` virou `?` = byte 0x3F)
- Excel (TRCell VINI/VPEN/VFIN): `á` gravado como par UTF-8 `C3 A1` em vez de `E1` CP-1252

## Causa
Mistura de encoding: fonte é CP-1252 (obrigatório Protheus/RDMake), mas edições
UTF-8 deixaram bytes multibyte no arquivo. Reedição/normalização indevida converteu
`ú` inválido em `?`.

## Fix
1. Títulos definidos (grid L146 + TRCells ~L1149-1151):
   - `Primeiro Valor Unitário`
   - `Valor Unitário Anterior`
   - `Valor Unitário Atual`
2. Normalização byte-a-byte: pares UTF-8 `C3 xx` → CP-1252 (ex.: `C3 A1` → `E1`);
   gravação final com `Encoding.GetEncoding(1252)`.
3. Validação: contagem de `0xC3` + byte>=0x80 deve ser **0**.

## Como aplicar / prevenir
- Após qualquer edição em `.prw`: converter UTF-8 → CP-1252 (skill
  `utf8-to-cp1252-conversion`) **antes** de compilar.
- Check rápido PowerShell:
  ```powershell
  $b=[IO.File]::ReadAllBytes($f); $n=0
  for($i=0;$i-lt$b.Length-1;$i++){ if($b[$i]-eq 0xC3 -and $b[$i+1]-ge 0x80){$n++} }
  $n  # deve ser 0
  ```
- Nunca gravar UTF-8 sobre fonte legado CP-1252.
