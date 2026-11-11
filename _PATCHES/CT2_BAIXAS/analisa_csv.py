#!/usr/bin/env python3
# -*- coding: ascii -*-
"""
Le os CSVs exportados do APSDU/SSMS e resume os resultados das queries
decisivas do caso "Razao CTBR400 x CTBA350 - set/2026".

Uso:
    python analiza_csv.py [pasta]

Pasta padrao: C:\\Users\\Vortice 0097\\Desktop\\apsdu_resultados

Para cada CSV encontrado:
  - le com utf-8-sig / cp1252 / latin-1 (nunca falha);
  - imprime cabecalho + todas as linhas (ate 300) em formato "|";
  - destaca colunas-chave: TPSALD, MES, DEBITO, CREDITO, CT2_LINHA.
"""

import csv
import io
import os
import sys

PADRAO = r"C:\Users\Vortice 0097\Desktop\apsdu_resultados"
MAX_LINHAS = 300
CHAVES = ("TPSALD", "MES", "DEBITO", "CREDITO", "LINHA", "QTDE", "VALOR")


def ler(caminho):
    with open(caminho, "rb") as fh:
        bruto = fh.read()
    for enc in ("utf-8-sig", "cp1252", "latin-1"):
        try:
            texto = bruto.decode(enc)
            break
        except UnicodeDecodeError:
            continue
    else:
        texto = bruto.decode("latin-1", errors="replace")

    # detecta separador
    amostra = texto[:4096]
    try:
        sep = csv.Sniffer().sniff(amostra, delimiters=",;\t|").delimiter
    except csv.Error:
        sep = ","

    linhas = list(csv.reader(io.StringIO(texto), delimiter=sep))
    linhas = [l for l in linhas if any(c.strip() for c in l)]
    if not linhas:
        return [], []
    return linhas[0], linhas[1:]


def main():
    pasta = sys.argv[1] if len(sys.argv) > 1 else PADRAO
    if not os.path.isdir(pasta):
        print("PASTA NAO ENCONTRADA: %s" % pasta)
        print("Crie a pasta e coloque la os .csv exportados do APSDU.")
        return 1

    arquivos = sorted(
        f for f in os.listdir(pasta) if f.lower().endswith((".csv", ".txt"))
    )
    if not arquivos:
        print("Nenhum .csv/.txt em: %s" % pasta)
        return 1

    for nome in arquivos:
        cabecalho, dados = ler(os.path.join(pasta, nome))
        print("=" * 100)
        print("ARQUIVO: %s   (linhas: %d)" % (nome, len(dados)))
        print("CABECALHO: " + " | ".join(c.strip() for c in cabecalho))
        idx_chave = [
            i for i, c in enumerate(cabecalho)
            if any(k in c.strip().upper() for k in CHAVES)
        ]
        if idx_chave:
            print("COLUNAS-CHAVE: " + " | ".join(
                "%d=%s" % (i, cabecalho[i].strip()) for i in idx_chave))
        print("-" * 100)
        for i, linha in enumerate(dados[:MAX_LINHAS], start=1):
            print("%3d | %s" % (i, " | ".join(c.strip() for c in linha)))
        if len(dados) > MAX_LINHAS:
            print("... (%d linhas omitidas)" % (len(dados) - MAX_LINHAS))
        print("")

    return 0


if __name__ == "__main__":
    sys.exit(main())
