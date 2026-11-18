#!/usr/bin/env python3
"""Revisao funcional de tela CRUD em browse (mBrowse / FWMBrowse).

Le o fonte e aponta o que o codigo prova sobre o funcionamento basico da
tela: botoes mortos, posicao de registro perdida, lock sem conferencia,
falta de refresh, area nao restaurada, filial e permissao.

Uso:
    python revisar_tela.py FONTES/CADPOSIC.PRW
    python revisar_tela.py FONTES
    python revisar_tela.py FONTES/CADPOSIC.PRW --estrito

Perfis:
    padrao    -> BOTAO_MORTO, FILIAL, PERMISSAO e LOOP sao AVISO
    --estrito -> todo achado e ERRO (gate de tela nova)

Saida: achados com arquivo:linha e codigo de saida 0 (sem ERRO) ou 1.
"""

import os
import re
import sys

EXTENSOES = (".prw", ".prg", ".prx", ".tlpp")

FUNC_RE = re.compile(
    r"^\s*(?:user\s+function|static\s+function|function)\s+([A-Za-z0-9_]+)",
    re.IGNORECASE,
)
AROTINA_RE = re.compile(r"^\s*(?:private|local|public)?\s*aRotina\s*:=", re.IGNORECASE)
ITEM_RE = re.compile(
    r'\{\s*"([^"]*)"\s*,\s*"([^"]*)"\s*(?:,\s*[^,]+)?\s*,\s*(\d+)',
)
ROTINA_RE = re.compile(r'^\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*0\s*,\s*(\d+)')

# Severidade base de cada achado: E = erro, A = aviso
SEVERIDADE = {
    "BOTAO_MORTO": "A",
    "POSICAO": "E",
    "LOCK": "E",
    "REFRESH": "A",
    "AREA": "A",
    "FILIAL": "A",
    "PERMISSAO": "A",
    "LOOP": "A",
}


def limpar_comentarios(linhas):
    """Devolve as linhas com comentarios de linha e de bloco em branco,
    preservando a numeracao para o relatorio."""
    saida = []
    fecha = None
    for linha in linhas:
        if fecha:
            saida.append("")
            if fecha in linha:
                fecha = None
            continue
        texto = linha.strip()
        if texto.startswith("/*/"):
            fecha = "/*/"
            saida.append("")
            continue
        if texto.startswith("/*"):
            fecha = "*/"
            saida.append("")
            continue
        corte = linha.find("//")
        if corte >= 0:
            linha = linha[:corte]
        saida.append(linha)
    return saida


def ler_texto(caminho):
    with open(caminho, "rb") as arq:
        bruto = arq.read()
    try:
        return bruto.decode("utf-8")
    except UnicodeDecodeError:
        return bruto.decode("cp1252", errors="replace")


def sem_acento(texto):
    trocas = {
        "a": "a", "e": "e", "i": "i", "o": "o", "u": "u", "c": "c",
    }
    return texto


def normaliza_rotina(nome):
    nome = nome.strip().strip('"').replace("(", "").replace(")", "").strip()
    if nome.upper().startswith("U_"):
        nome = nome[2:]
    return nome


def coletar_funcoes(linhas):
    funcoes = []
    atual = None
    for n, linha in enumerate(linhas):
        casou = FUNC_RE.match(linha)
        if casou:
            if atual:
                atual["fim"] = n
                funcoes.append(atual)
            atual = {"nome": casou.group(1).upper(), "ini": n, "fim": len(linhas)}
    if atual:
        atual["fim"] = len(linhas)
        funcoes.append(atual)
    return funcoes


def bloco_arotina(linhas):
    ini = None
    for n, linha in enumerate(linhas):
        if AROTINA_RE.match(linha):
            ini = n
            break
    if ini is None:
        return []
    itens = []
    profundidade = 0
    for linha in linhas[ini:ini + 40]:
        for casou in ITEM_RE.finditer(linha):
            itens.append({
                "label": casou.group(1),
                "rotina": normaliza_rotina(casou.group(2)),
                "opc": int(casou.group(3)),
            })
        profundidade += linha.count("{") - linha.count("}")
        if profundidade <= 0 and itens:
            break
    return itens


def regioes_de_laco(linhas, ini, fim):
    regioes = []
    pilha = []
    for n in range(ini, fim):
        baixa = linhas[n].lower()
        if re.search(r"\b(do\s+while|while)\b", baixa):
            pilha.append(n)
        if re.search(r"\benddo\b|\bend\b", baixa) and pilha:
            regioes.append((pilha.pop(), n))
    for inicio in pilha:
        regioes.append((inicio, fim))
    return regioes


def revisar_arquivo(caminho, funcoes_conhecidas, estrito):
    linhas = ler_texto(caminho).splitlines()
    codigo = limpar_comentarios(linhas)
    nome_arq = os.path.basename(caminho)
    funcoes = coletar_funcoes(linhas)
    achados = []

    def add(codigo, numero_linha, funcao, detalhe):
        sev = SEVERIDADE[codigo]
        if estrito:
            sev = "E"
        achados.append({
            "codigo": codigo,
            "arquivo": nome_arq,
            "linha": numero_linha,
            "funcao": funcao,
            "detalhe": detalhe,
            "sev": sev,
        })

    itens = bloco_arotina(linhas)
    tem_tela = any("setalias(" in linha.lower() for linha in codigo)

    # BOTAO_MORTO ------------------------------------------------------
    for item in itens:
        rotina = item["rotina"]
        if rotina.upper().startswith("AX"):
            continue
        if rotina.upper() in funcoes_conhecidas:
            continue
        linha = next(
            (n + 1 for n, l in enumerate(linhas) if '"%s"' % rotina.lower() in l.lower()),
            0,
        )
        add("BOTAO_MORTO", linha, rotina,
            "rotina '%s' do aRotina nao declarada nos fontes do repositorio "
            "(pode existir no RPO - confirmar na tela)" % rotina)

    # Checagens por funcao --------------------------------------------
    for func in funcoes:
        ini, fim = func["ini"], func["fim"]
        corpo = codigo[ini:fim]
        baixo = "\n".join(corpo).lower()
        nome = func["nome"]

        posicional = ("dbdelete(" in baixo) or ("axdeleta(" in baixo) or \
                     bool(re.search(r"reclock\([^)]*\.f\.", baixo))
        usa_recno = "recno()" in baixo
        tem_count = "count to" in baixo
        tem_reposiciona = ("dbgoto(" in baixo) or ("dbgotop(" in baixo)

        # POSICAO ------------------------------------------------------
        if posicional and (tem_count or usa_recno) and not tem_reposiciona:
            add("POSICAO", ini + 1, nome,
                "exclusao/alteracao do registro atual sem DbGoTo/DbGoTop "
                "depois de Count To/RecNo()")

        # LOCK ---------------------------------------------------------
        if "dbdelete(" in baixo:
            checa_lock = re.search(r"if\s+.*reclock\(", baixo) or \
                         re.search(r"if\s+!.*reclock\(", baixo)
            if not checa_lock:
                add("LOCK", ini + 1, nome,
                    "DbDelete() sem conferir o retorno de RecLock "
                    "(registro de outro usuario pode ser apagado sem trava)")

        # AREA ---------------------------------------------------------
        if "dbselectarea(" in baixo:
            if ("getarea(" not in baixo) or ("restarea(" not in baixo):
                add("AREA", ini + 1, nome,
                    "DbSelectArea sem GetArea/RestArea: o alias atual nao e "
                    "restaurado na saida")

        # REFRESH ------------------------------------------------------
        if posicional and "refresh()" not in baixo:
            if nome.lower() in [i["rotina"].lower() for i in itens]:
                add("REFRESH", ini + 1, nome,
                    "rotina custom grava/exclui e nao chama Refresh() da grade")

        # LOOP ---------------------------------------------------------
        for inicio, final in regioes_de_laco(codigo, ini, fim):
            trecho = "\n".join(codigo[inicio:final]).lower()
            for proibido in ("getmv(", "supergetmv(", "pergunte(", "type("):
                if proibido in trecho:
                    add("LOOP", inicio + 1, nome,
                        "%s dentro de laco (ler uma vez fora do laco)" % proibido)
                    break

    # FILIAL / PERMISSAO ----------------------------------------------
    if tem_tela:
        texto = "\n".join(codigo).lower()
        tem_filtro = ("setfilter(" in texto) or ("setfilterdefault(" in texto) or \
                     ("dbsetfilter(" in texto)
        if not tem_filtro:
            add("FILIAL", 1, "tela",
                "browse sem SetFilterDefault/DbSetFilter: a grade mostra "
                "registros de todas as filiais (confirmar se a tabela e mono-filial)")
        destrutivo = any(
            i["opc"] == 5 or "limpar" in i["label"].lower() or "importar" in i["label"].lower()
            for i in itens
        )
        if destrutivo and not any(p in texto for p in ("cdelfunc", "mpuserhasaccess", "verifyaccess")):
            add("PERMISSAO", 1, "tela",
                "botao destrutivo (excluir/limpar/importar) sem validacao de "
                "acesso (cDelFunc / MPUserHasAccess / VerifyAccess)")

    return achados, funcoes


def arquivos_alvo(caminho):
    if os.path.isfile(caminho):
        return [caminho]
    alvos = []
    for raiz, _, nomes in os.walk(caminho):
        for nome in nomes:
            if nome.lower().endswith(EXTENSOES):
                alvos.append(os.path.join(raiz, nome))
    return sorted(alvos)


def main(argv):
    estrito = "--estrito" in argv
    args = [a for a in argv if not a.startswith("--")]
    if not args:
        print("uso: python revisar_tela.py <arquivo|pasta> [--estrito]")
        return 2

    alvos = []
    for arg in args:
        alvos.extend(arquivos_alvo(arg))
    if not alvos:
        print("nenhum fonte AdvPL encontrado")
        return 2

    # Primeira passada: nomes de funcao de todo o conjunto analisado
    conhecidas = set()
    for caminho in alvos:
        for func in coletar_funcoes(ler_texto(caminho).splitlines()):
            conhecidas.add(func["nome"].upper())

    achados = []
    for caminho in alvos:
        encontrados, _ = revisar_arquivo(caminho, conhecidas, estrito)
        achados.extend(encontrados)

    perfil = "estrito (tela nova)" if estrito else "padrao"
    print("Perfil: %s | fontes analisados: %d" % (perfil, len(alvos)))
    print("")

    for sev, titulo in (("E", "ERRO"), ("A", "AVISO")):
        grupo = [a for a in achados if a["sev"] == sev]
        if not grupo:
            continue
        print("=== %s (%d) ===" % (titulo, len(grupo)))
        for a in grupo:
            print("  [%s] %s:%d | %s | %s" % (
                a["codigo"], a["arquivo"], a["linha"], a["funcao"], a["detalhe"]))
        print("")

    erros = len([a for a in achados if a["sev"] == "E"])
    avisos = len([a for a in achados if a["sev"] == "A"])
    print("Resumo: %d ERRO(s), %d AVISO(s)" % (erros, avisos))
    if erros == 0 and avisos == 0:
        print("Codigo sem achados mecanicos. O comportamento so o teste na tela confirma.")
    return 1 if erros else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
