#!/usr/bin/env python3
"""Detecta mensagem a controle de dialogo apos ACTIVATE MSDIALOG (AdvPL)."""
import re
import sys
from pathlib import Path

FUNC_RE = re.compile(r'^\s*(?:Static\s+|User\s+)?Function\s+(\w+)', re.IGNORECASE)
DEFINE_RE = re.compile(r'\bDEFINE\s+MSDIALOG\s+(\w+)', re.IGNORECASE)
ACT_RE = re.compile(r'\bACTIVATE\s+MSDIALOG\s+(\w+)', re.IGNORECASE)
MACRO_RE = re.compile(
    r'@\s*[\d.,\s]+(?:MSGET|GET|BUTTON|LISTBOX|SAY|GROUP|COMBOBOX|CHECKBOX|RADIO|PANEL|FOLDER)\s+(o\w+)',
    re.IGNORECASE)
NEW_RE = re.compile(r'\b(o\w+)\s*:=\s*[\w.]+\(\)\s*:\s*New\s*\(', re.IGNORECASE)


def read_text(path):
    raw = path.read_bytes()
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return raw.decode("cp1252")


def scan(path):
    problems = []
    func = "?"
    dlg = None
    controls = set()
    dead = set()
    for n, rawline in enumerate(read_text(path).splitlines(), 1):
        line = rawline.split("//")[0]
        m = FUNC_RE.match(line)
        if m:
            func = m.group(1)
            dlg, controls, dead = None, set(), set()
            continue
        if DEFINE_RE.search(line):
            dlg = DEFINE_RE.search(line).group(1)
            controls, dead = set(), set()
        m = ACT_RE.search(line)
        if m and dlg:
            dead = controls | {dlg}
            continue
        if dlg and not dead:
            for m in MACRO_RE.finditer(line):
                controls.add(m.group(1))
            m = NEW_RE.search(line)
            if m and dlg.lower() in line.lower():
                controls.add(m.group(1))
        if dead:
            for obj in sorted(dead):
                if re.search(r'\b' + re.escape(obj) + r'\s*:', line, re.IGNORECASE):
                    problems.append((n, func, obj))
    return problems


def main():
    if len(sys.argv) < 2:
        print("uso: check_pos_activate.py <arquivo.prw> [mais arquivos...]")
        return 2
    total = 0
    for arg in sys.argv[1:]:
        path = Path(arg)
        print(f"ARQUIVO: {arg}")
        if not path.is_file():
            print("  X arquivo nao encontrado")
            total += 1
            continue
        problems = scan(path)
        for n, func, obj in problems:
            print(f"  X funcao {func} (linha {n}): mensagem para '{obj}' apos "
                  f"ACTIVATE MSDIALOG (controle destruido)")
            total += 1
        if not problems:
            print("  . nenhuma leitura de controle apos ACTIVATE")
    print("VEREDITO: " + ("REPROVADO" if total else "OK"))
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())