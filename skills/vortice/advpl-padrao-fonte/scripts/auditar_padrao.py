#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Audita fontes AdvPL/TLPP contra o padrao dos fontes deste repositorio.

Uso:
    python auditar_padrao.py <arquivo-ou-pasta> [--json] [--estrito]

Perfis:
    padrao    (default)  -> ERRO so o que quebra compilacao/dado; o resto e AVISO agregado
    --estrito            -> DOC/TYPE/DECL/ALGN tambem viram ERRO (gate de fonte NOVO)

Saida:
    ERRO  = corrigir antes de compilar/entregar
    AVISO = divida de legado: tolerada no que ja existe, proibida em codigo novo

Codigo de saida: 0 = sem ERRO; 1 = pelo menos um ERRO; 2 = caminho invalido.

Sem dependencia externa. Le cada fonte como CP-1252 (encoding obrigatorio do RPO).
"""

import json
import os
import re
import sys

EXTS = (".prw", ".prg", ".prx", ".tlpp", ".ppx", ".apw", ".aph")
IGNORAR_DIR = (".vscode", ".advpl", ".git", "__pycache__")
INCLUDE_RE = re.compile(r'^\s*#\s*include\s+"([^"]+)"', re.I)
FUNC_RE = re.compile(r'^[ \t]*(user\s+function|static\s+function|function)\s+(\w+)\s*\(', re.I)
CLASS_RE = re.compile(r'^[ \t]*(class|method)\s+(\w+)\s*[\(\.:]', re.I)
DECL_RE = re.compile(r'^\s*(local|private|public)\b', re.I)
DOC_OPEN = "/*/{protheus.doc}"

# regra: (severidade padrao, severidade --estrito, descricao)
REGRAS = {
    "ENC":  ("ERRO",  "ERRO",  "fonte nao esta em CP-1252 (o RPO corrompe acento)"),
    "NOLK": ("ERRO",  "ERRO",  "%nolock% proibido neste build (vira WITH (%%) ) - use WITH (NOLOCK) literal"),
    "FUNC": ("ERRO",  "ERRO",  "Function puro proibido em customizacao - use User Function ou Static Function"),
    "AREA": ("ERRO",  "ERRO",  "GetArea() sem RestArea() correspondente"),
    "INC":  ("ERRO",  "ERRO",  "sem include de Protheus (totvs.ch / protheus.ch / tlpp-core.th)"),
    "TXUI": ("ERRO",  "ERRO",  "UI (Msg*/Pergunte/Help) dentro de Begin Transaction - risco de deadlock"),
    "FILI": ("ERRO",  "ERRO",  "variavel reservada cFilial usada direto - use cFilAux ou xFilial()"),
    "DOC":  ("AVISO", "ERRO",  "funcao/classe/metodo sem bloco /*/{Protheus.doc}"),
    "TYPE": ("AVISO", "ERRO",  "bloco Protheus.doc sem @type"),
    "DECL": ("AVISO", "ERRO",  "Local declarado depois do inicio da logica"),
    "ALGN": ("AVISO", "ERRO",  "bloco Local com ':=' desalinhado"),
    "NAME": ("AVISO", "AVISO", "nome do arquivo diferente da primeira funcao declarada"),
    "NOQL": ("AVISO", "AVISO", "query com RetSqlName/FROM sem D_E_L_E_T_ = ' ' (ou <> '*')"),
    "STAR": ("AVISO", "AVISO", "SELECT * - listar campos explicitamente"),
    "IIF":  ("AVISO", "AVISO", "IIF() - regra CA4000 pede If/Else/EndIf"),
    "CONO": ("AVISO", "AVISO", "ConOut/OutErr/? em vez de FWLogMsg()"),
    "TAB":  ("AVISO", "AVISO", "indentacao com TAB - padrao do repo e 4 espacos"),
    "SEMI": ("AVISO", "AVISO", "';' seguido de comentario na mesma linha (erro C2002)"),
    "HTTP": ("AVISO", "AVISO", "HTTPCGet/HTTPCPost - codigo novo deve usar FWRest"),
}


class Achado(object):
    __slots__ = ("regra", "arquivo", "linha", "detalhe", "sev")

    def __init__(self, regra, arquivo, linha, detalhe=""):
        self.regra = regra
        self.arquivo = arquivo
        self.linha = linha
        self.detalhe = detalhe
        self.sev = REGRAS[regra][0]

    def as_dict(self):
        return {"regra": self.regra, "severidade": self.sev, "arquivo": self.arquivo,
                "linha": self.linha, "mensagem": REGRAS[self.regra][2], "detalhe": self.detalhe}


def ler_fonte(caminho, achados):
    bruto = open(caminho, "rb").read()
    if any(b > 127 for b in bruto):
        try:
            bruto.decode("utf-8")
            achados.append(Achado("ENC", caminho, 0, "decodifica como UTF-8 com acento"))
            return bruto.decode("utf-8", "replace")
        except UnicodeDecodeError:
            pass
    return bruto.decode("cp1252", "replace")


def blocos_logicos(linhas):
    bloco, inicio = [], 0
    for i, linha in enumerate(linhas, 1):
        if not bloco:
            inicio = i
        bloco.append(linha)
        texto = linha.rstrip()
        if texto.endswith((";", "+", ",")):
            continue
        yield inicio, " ".join(bloco)
        bloco = []
    if bloco:
        yield inicio, " ".join(bloco)


def doc_antes(linhas, idx):
    i = idx - 1
    while i >= 0 and i >= idx - 40:
        if DOC_OPEN in linhas[i].lower():
            return i
        if FUNC_RE.match(linhas[i]) or CLASS_RE.match(linhas[i]):
            return -1
        i -= 1
    return -1


def auditar(caminho, estrito=False):
    nome = os.path.basename(caminho)
    achados = []
    linhas = ler_fonte(caminho, achados).splitlines()

    includes = [m.group(1).lower() for m in (INCLUDE_RE.match(l) for l in linhas) if m]
    if not any(i in ("totvs.ch", "protheus.ch", "tlpp-core.th") for i in includes):
        achados.append(Achado("INC", nome, 0, "includes: %s" % (includes or "nenhum")))

    primeira = next((FUNC_RE.match(l).group(2) for l in linhas if FUNC_RE.match(l)), None)
    if primeira and os.path.splitext(nome)[0].upper() != primeira.upper():
        achados.append(Achado("NAME", nome, 0, "arquivo=%s funcao=%s"
                              % (os.path.splitext(nome)[0], primeira)))

    em_funcao, fase_decl = False, False
    getarea = restarea = 0
    inicio_funcao = 0

    for i, linha in enumerate(linhas):
        n, baixa = i + 1, linha.lower()
        m_func, m_class = FUNC_RE.match(linha), CLASS_RE.match(linha)

        if m_func or m_class:
            if m_func and m_func.group(1).strip().lower() == "function":
                achados.append(Achado("FUNC", nome, n, "function %s" % m_func.group(2)))
            if em_funcao and getarea > restarea:
                achados.append(Achado("AREA", nome, inicio_funcao,
                                      "GetArea=%d RestArea=%d" % (getarea, restarea)))
            em_funcao, fase_decl = True, True
            getarea = restarea = 0
            inicio_funcao = n

            ini = doc_antes(linhas, i)
            if ini < 0:
                achados.append(Achado("DOC", nome, n, linha.strip()[:70]))
            elif "@type" not in "\n".join(linhas[ini:i]).lower():
                achados.append(Achado("TYPE", nome, ini + 1, "bloco de %s" % (m_func or m_class).group(2)))
            continue

        if not em_funcao:
            continue

        if DECL_RE.match(linha):
            if not fase_decl and linha.lstrip().lower().startswith("local"):
                achados.append(Achado("DECL", nome, n, linha.strip()[:70]))
            getarea += baixa.count("getarea(")
            restarea += baixa.count("restarea(")
            continue

        if fase_decl:
            if not linha.strip() or linha.strip().startswith(("//", "*", "/*")):
                continue
            if linha.rstrip().endswith((";", "+", ",")):
                continue
            fase_decl = False

        getarea += baixa.count("getarea(")
        restarea += baixa.count("restarea(")

    if em_funcao and getarea > restarea:
        achados.append(Achado("AREA", nome, inicio_funcao, "GetArea=%d RestArea=%d" % (getarea, restarea)))

    dentro_transacao = False
    for i, linha in enumerate(linhas, 1):
        baixa = linha.lower()
        if re.search(r"\bbegin\s+transaction\b", baixa):
            dentro_transacao = True
        elif re.search(r"\bend\s+transaction\b", baixa):
            dentro_transacao = False

        if "%nolock%" in baixa:
            achados.append(Achado("NOLK", nome, i, linha.strip()[:70]))
        if linha[:len(linha) - len(linha.lstrip())].count("\t"):
            achados.append(Achado("TAB", nome, i))
        if re.search(r"\biif\s*\(", baixa):
            achados.append(Achado("IIF", nome, i))
        if re.search(r"\b(conout|outerr)\s*\(", baixa) or re.match(r"^\s*\?\s", linha):
            achados.append(Achado("CONO", nome, i))
        if re.search(r"\bc?filial\s*:=", linha) and "cfilet" not in baixa:
            achados.append(Achado("FILI", nome, i, linha.strip()[:70]))
        if re.search(r"\bhttpc(get|post|quote)\s*\(", baixa):
            achados.append(Achado("HTTP", nome, i))
        if re.search(r";\s*(//|/\*)", linha):
            achados.append(Achado("SEMI", nome, i))
        if dentro_transacao and re.search(r"\b(msgalert|msgyesno|msgstop|msginfo|aviso|help|pergunte|parambox)\s*\(", baixa):
            achados.append(Achado("TXUI", nome, i, linha.strip()[:70]))

    for inicio, cmd in blocos_logicos(linhas):
        baixa = cmd.lower()
        if "select" not in baixa:
            continue
        if re.search(r"select\s+\*", baixa):
            achados.append(Achado("STAR", nome, inicio))
        if ("retsqlname" in baixa or re.search(r"\bfrom\b", baixa)) and not re.search(
                r"d_e_l_e_t_\s*(=\s*'\s*'|<>|!=)", baixa) and "%notdel%" not in baixa:
            achados.append(Achado("NOQL", nome, inicio, cmd.strip()[:60]))

    if estrito:
        grupo, linha_ini = [], 0
        for i, linha in enumerate(linhas, 1):
            if DECL_RE.match(linha):
                if not grupo:
                    linha_ini = i
                grupo.append(linha)
                continue
            if grupo:
                _checar_alinhamento(grupo, linha_ini, nome, achados)
                grupo = []
        if grupo:
            _checar_alinhamento(grupo, linha_ini, nome, achados)

    return achados


def _checar_alinhamento(grupo, linha_ini, nome, achados):
    if len(grupo) < 3:
        return
    colunas = {m.start() for m in (re.search(r":=", l) for l in grupo) if m}
    if len(colunas) > 1:
        achados.append(Achado("ALGN", nome, linha_ini, "colunas do ':=' %s" % sorted(colunas)))


def coletar(caminho):
    if os.path.isfile(caminho):
        return [caminho]
    fontes = []
    for raiz, dirs, arquivos in os.walk(caminho):
        dirs[:] = [d for d in dirs if d.lower() not in IGNORAR_DIR]
        for a in sorted(arquivos):
            if a.lower().endswith(EXTS) and not a.lower().endswith(".bak") and not a.startswith("_binary"):
                fontes.append(os.path.join(raiz, a))
    return fontes


def _formatar(itens, severidade):
    """Agrupa por regra; dentro da regra, agrega por arquivo (evita 13k linhas de TAB)."""
    por_regra = {}
    for a in itens:
        por_regra.setdefault(a.regra, []).append(a)

    print("\n=== %s (%d) ===" % (severidade, len(itens)))
    for regra in sorted(por_regra):
        lista = por_regra[regra]
        print("\n  [%s] %s" % (regra, REGRAS[regra][2]))
        por_arq = {}
        for a in lista:
            por_arq.setdefault(a.arquivo, []).append(a)
        for arq in sorted(por_arq):
            ocorrencias = por_arq[arq]
            primeira = ocorrencias[0]
            detalhe = (" | " + primeira.detalhe) if primeira.detalhe else ""
            if len(ocorrencias) == 1:
                print("    %s:%s%s" % (arq, primeira.linha or "-", detalhe))
            else:
                linhas = ", ".join(str(o.linha) for o in ocorrencias[:3] if o.linha)
                print("    %s (%d ocorrencias; 1a em %s)%s"
                      % (arq, len(ocorrencias), linhas or "-", detalhe))


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    alvo = argv[1]
    if not os.path.exists(alvo):
        print("caminho invalido: %s" % alvo)
        return 2

    estrito = "--estrito" in argv
    como_json = "--json" in argv
    fontes = coletar(alvo)

    todos = []
    for f in fontes:
        todos.extend(auditar(f, estrito))

    if estrito:
        for a in todos:
            if REGRAS[a.regra][1] == "ERRO":
                a.sev = "ERRO"
            else:
                a.sev = REGRAS[a.regra][1]

    erros = [a for a in todos if a.sev == "ERRO"]
    avisos = [a for a in todos if a.sev == "AVISO"]

    if como_json:
        print(json.dumps({"perfil": "estrito" if estrito else "padrao",
                          "fontes": len(fontes), "erros": len(erros), "avisos": len(avisos),
                          "achados": [a.as_dict() for a in todos]},
                         ensure_ascii=False, indent=1))
    else:
        print("Perfil: %s | fontes analisados: %d" % ("estrito (fonte novo)" if estrito else "padrao (legado)", len(fontes)))
        if erros:
            _formatar(erros, "ERRO")
        if avisos:
            _formatar(avisos, "AVISO")
        print("\nResumo: %d ERRO(s), %d AVISO(s)" % (len(erros), len(avisos)))
        if erros:
            print("Corrija os ERROs antes de compilar; AVISOs nao se replicam em codigo novo.")

    return 1 if erros else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
