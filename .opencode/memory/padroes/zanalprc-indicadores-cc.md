# ZANALPRC — padrões da tela de Análise de Variação de Preços (v3)

- **Arquivo**: `FONTES/ZANALPRC.PRW`
- **Data da sessão**: 2026-09-24
- **Contexto**: consulta virtual de variação de preços SD1 (prefixos MC/MD/AI), duplo clique = histórico, botões Excel/Indicadores.

## Indicadores (AnpInd)
- Maior aumento/redução exibem **código do item** junto do %; tooltip = cód + descrição + aviso de outlier (erro de lançamento/unidade de medida).
- Legenda fixa de economia: `(+) ganho, preco caiu | (-) perda, preco subiu`.
- Contagem **"Itens sem comparacao (1 compra)"**:
  - `Private nZANPSO1` (inicializada 0 na U_ZANALPRC e em AnpCarrega);
  - contada em AnpCarrega quando `aAgrup[nI,9] < 2` (antes do `Loop`);
  - exibida em AnpInd com tooltip explicando por que não aparece no grid.
- Diálogo: `FROM 0,0 TO 340,530 PIXEL` — último SAY em Y=290; valores em X=165 SIZE 290.
- Linhas novas: sem `IIf` (CA4000) — pré-montar textos em Locais (`cTxtMaxAum`/`cTxtMaxDim`).
- Protheus.doc obrigatório ao criar/editar Static Function.

## Combo Centro de Custo (AnpCarCC)
- Filtro fixo na query: `AND CTT.CTT_CUSTO IN (...)` com os **26 CCs autorizados**:
  - 5010201–5010207 (ADM..TI), 6010201–6010210, 6010212–6010214 (operação/manutenção),
    7010201–7010202 (meio ambiente), 8010201–8010202 (geologia), 9010201–9010202 (sondagem).
  - **6010211 fora da lista** (não existe no quadro autorizado).
- Primeira opção do combo permanece `** Todos os Centros **` (`*`).

## Títulos de coluna da análise (grid + Excel)
- `Primeiro Valor Unitário` (VINI) / `Valor Unitário Anterior` (VPEN) / `Valor Unitário Atual` (VFIN).
- Manter grid e TRCells **sincronizados** — mesmo texto nos dois.

## Review da query do histórico (decisão do usuário: manter)
- Mapeamento coluna↔campo conferido OK (D1_* + joins SB1/SA2/CTT/SC7/SE4).
- Pendências aceitas: unitário/desconto vêm do PC quando há pedido; `C7_CONAPRO` no
  LEFT JOIN SC7; sem NOLOCK; `LIKE 'MC%|MD%|AI%'` hardcoded.

## Encoding
- Arquivo em CP-1252; após edição: converter e validar 0 pares UTF-8 (ver bug
  `bugs/zanalprc-mojibake-acentos.md`).
