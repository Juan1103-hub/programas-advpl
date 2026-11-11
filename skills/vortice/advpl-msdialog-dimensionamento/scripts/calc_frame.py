#!/usr/bin/env python3
"""Calcula a moldura de um MSDIALOG a partir do bounding box dos controles.

A moldura do MSDIALOG e aplicada literalmente, mas os controles renderizam com
zoom do ambiente (~2x). Por isso a moldura precisa ser ~2x a area ocupada pelos
controles. Este script faz a conta e valida as tres desigualdades do playbook.

Uso:
  python calc_frame.py --control 8,12,380,20 --browse 34,12,376,150 \
      --columns 40,196,140 [--frame 400,800] [--scale 2.0] [--round-to 50]
"""

import argparse
import math
import sys


def parse_control(text):
    try:
        parts = [float(p) for p in text.split(",")]
    except ValueError:
        sys.exit("ERRO: --control espera linha,coluna,largura,altura; recebeu '%s'" % text)
    if len(parts) != 4:
        sys.exit("ERRO: --control espera 4 numeros; recebeu '%s'" % text)
    return parts


def parse_columns(text):
    try:
        parts = [float(p) for p in text.split(",")]
    except ValueError:
        sys.exit("ERRO: --columns espera numeros separados por virgula; recebeu '%s'" % text)
    if not parts:
        sys.exit("ERRO: --columns vazio")
    return parts


def parse_frame(text):
    try:
        parts = [float(p) for p in text.split(",")]
    except ValueError:
        sys.exit("ERRO: --frame espera altura,largura; recebeu '%s'" % text)
    if len(parts) != 2:
        sys.exit("ERRO: --frame espera 2 numeros (altura,largura); recebeu '%s'" % text)
    return parts


def round_up(value, step):
    return int(math.ceil(value / step) * step)


def fmt(value):
    return ("%g" % value)


def main():
    parser = argparse.ArgumentParser(description="Dimensiona moldura de MSDIALOG")
    parser.add_argument("--control", action="append", default=[],
                        help="linha,coluna,largura,altura (repetivel)")
    parser.add_argument("--browse", default=None,
                        help="linha,coluna,largura,altura da grade")
    parser.add_argument("--columns", default=None,
                        help="larguras das colunas da grade, separadas por virgula")
    parser.add_argument("--frame", default=None, help="altura,largura da moldura atual")
    parser.add_argument("--scale", type=float, default=2.0, help="zoom medido (padrao 2.0)")
    parser.add_argument("--round-to", type=int, default=50, help="multiplo do arredondamento (padrao 50)")
    args = parser.parse_args()

    if args.scale <= 0:
        sys.exit("ERRO: --scale deve ser maior que zero")
    if args.round_to <= 0:
        sys.exit("ERRO: --round-to deve ser maior que zero")

    controls = [parse_control(c) for c in args.control]
    browse = parse_control(args.browse) if args.browse else None
    if browse:
        controls.append(browse)

    if not controls:
        sys.exit("ERRO: informe ao menos um --control ou --browse")

    columns = parse_columns(args.columns) if args.columns else None
    frame = parse_frame(args.frame) if args.frame else None

    max_row = max(c[0] + c[3] for c in controls)
    max_col = max(c[1] + c[2] for c in controls)

    rec_rows = round_up(args.scale * max_row, args.round_to)
    rec_cols = round_up(args.scale * max_col, args.round_to)

    print("BOUNDING BOX: linha %s x coluna %s" % (fmt(max_row), fmt(max_col)))
    print("MOLDURA RECOMENDADA: %d (altura) x %d (largura)  [escala %s, multiplo %d]"
          % (rec_rows, rec_cols, fmt(args.scale), args.round_to))

    final_rows, final_cols = (frame[0], frame[1]) if frame else (rec_rows, rec_cols)
    if frame:
        print("MOLDURA INFORMADA: %s (altura) x %s (largura)" % (fmt(final_rows), fmt(final_cols)))

    errors = []

    if final_rows < rec_rows or final_cols < rec_cols:
        errors.append("moldura menor que o recomendado: precisa de %d x %d"
                      % (rec_rows, rec_cols))

    for idx, ctrl in enumerate(controls):
        linha, coluna, largura, altura = ctrl
        rotulo = "browse" if (browse and idx == len(controls) - 1 and args.browse) else "controle %d" % (idx + 1)
        if coluna + largura > final_cols / 2.0:
            errors.append("%s termina em %s na horizontal; limite %s (moldura/2)"
                          % (rotulo, fmt(coluna + largura), fmt(final_cols / 2.0)))
        if linha + altura > final_rows / 2.0:
            errors.append("%s termina em %s na vertical; limite %s (moldura/2)"
                          % (rotulo, fmt(linha + altura), fmt(final_rows / 2.0)))

    if browse and columns:
        soma = sum(columns)
        print("COLUNAS: soma %s / largura do browse %s" % (fmt(soma), fmt(browse[2])))
        if soma > browse[2]:
            errors.append("colunas somam %s e estouram a largura do browse (%s)"
                          % (fmt(soma), fmt(browse[2])))

    if errors:
        print("")
        print("FALHA (%d)" % len(errors))
        for err in errors:
            print("  - " + err)
        return 1

    print("")
    print("VEREDITO: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
