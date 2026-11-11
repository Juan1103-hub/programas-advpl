# -*- coding: utf-8 -*-
"""
Gera um dataset de treinamento (destilacao / distillation) lendo perguntas
complexas de um arquivo texto e consultando um modelo avançado de LLM.

O objetivo e extrair a logica de raciocinio (Chain-of-Thought) do modelo
avancado para depois treinar um modelo open-source menor.

Fluxo:
    1. Le as perguntas de "perguntas.txt" (uma por linha, linhas vazias e
       iniciadas por "#" sao ignoradas).
    2. Envia cada pergunta para a API da OpenAI (gpt-4o), da Anthropic
       (claude-3-5-sonnet-20241022) ou do proprio OpenCode
       (mimo-v2.6-flash-free), com um prompt de sistema que obriga a
       resposta a seguir a tecnica de Cadeia de Pensamento.
    3. Grava cada resultado em "dataset_treino.jsonl", uma linha por pergunta,
       no formato: {"instruction": <pergunta>, "output": <resposta detalhada>}

Dependencias: apenas "tqdm" (a chamada HTTP usa a biblioteca padrao "urllib",
nao ha necessidade de instalar os SDKs da OpenAI, da Anthropic ou do OpenCode).

Instalacao da dependencia:
    pip install tqdm

Uso:
    export OPENAI_API_KEY="sk-..."           # Windows: set OPENAI_API_KEY=sk-...
    python tools/gerar_dataset_treino.py --provider openai

    export ANTHROPIC_API_KEY="sk-ant-..."
    python tools/gerar_dataset_treino.py --provider anthropic

    export OPENCODE_API_KEY="oc_sk_..."      # Console API key do OpenCode
    python tools/gerar_dataset_treino.py --provider opencode

    # Continuar de onde parou (anexa ao arquivo existente)
    python tools/gerar_dataset_treino.py --provider openai --anexar

Autor: Vortice Consultoria Mineral
Since: 2026-10-26
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid
from typing import Any, Dict, List, Optional, Tuple

from tqdm import tqdm

# ---------------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------------

URL_OPENAI = "https://api.openai.com/v1/chat/completions"
URL_ANTHROPIC = "https://api.anthropic.com/v1/messages"

MODELO_OPENAI_PADRAO = "gpt-4o"
MODELO_ANTHROPIC_PADRAO = "claude-3-5-sonnet-20241022"

# ---------------------------------------------------------------------------
# OpenCode (Console gateway)
# ---------------------------------------------------------------------------
# Fonte: https://opencode.ai/v2/docs/console/harnesses
# Pay-as-you-go -> https://opencode.ai/inference
# Go            -> https://opencode.ai/inference/go   (sobrescreva com
#                   OPENCODE_BASE_URL se o workspace for assinante do Go)
# A API do OpenCode fala a API da OpenAI em /openai/v1/chat/completions.
OPENCODE_PADRAO = "https://opencode.ai/inference"
URL_OPENCODE = (
    os.environ.get("OPENCODE_BASE_URL", OPENCODE_PADRAO).rstrip("/")
    + "/openai/v1/chat/completions"
)

# Modelo gratuito padrao do ambiente (ver CONFIG/AGENTS.md -> Model Routing).
MODELO_OPENCODE_PADRAO = "mimo-v2.6-flash-free"

# O gateway fica atras do Cloudflare e devolve 403 "error code: 1010"
# (bloqueio por assinatura de navegador) quando a requisicao nao traz
# User-Agent. Testado em 2026-10-26: sem este cabecalho a chamada falha.
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36"
)

# ID de sessao estavel por execucao: o Console usa para rotear a conversa e
# reaproveitar o cache de prompt. O plano Go exige este cabecalho.
SESSAO_OPENCODE = "ses_" + uuid.uuid4().hex[:24]

# Versao do protocolo da API da Anthropic (obrigatoria no cabecalho).
ANTHROPIC_VERSION = "2023-06-01"

# Codigos HTTP que vale a pena tentar de novo (rate limit / instabilidade).
CODIGOS_RECUPERAVEIS = (408, 409, 429, 500, 502, 503, 504)

# Codigo de tempo de espera por requisicao, em segundos.
TIMEOUT_PADRAO = 120

# Prompt de sistema que força a Cadeia de Pensamento (Chain-of-Thought).
# O marcador "RESPOSTA FINAL:" permite isolar a resposta objetiva depois.
PROMPT_SISTEMA = (
    "Voce e um assistente de raciocinio avancado. "
    "Responda sempre utilizando a tecnica de Cadeia de Pensamento "
    "(Chain-of-Thought): ANTES de apresentar a resposta final, explique "
    "detalhadamente, passo a passo, todo o raciocinio logico que leva a "
    "solucao. "
    "Nas suas explicacoes: "
    "(1) reformule o problema e identifique o que esta sendo pedido; "
    "(2) liste as informacoes disponiveis e as premissas; "
    "(3) considere hipoteses alternativas e possiveis armadilhas; "
    "(4) desenvolva cada etapa do calculo ou da deducao, justificando por que "
    "cada passo e valido; "
    "(5) verifique o resultado obtido. "
    "Escreva em portugues brasileiro claro, com frases completas, sem "
    "abreviacoes e sem termos em ingles (excecao: nomenclatura tecnica "
    "consolidada). "
    "Ao final, encerre com uma linha isolada contendo exatamente o prefixo "
    "'RESPOSTA FINAL:' seguido da resposta objetiva e concisa."
)


# ---------------------------------------------------------------------------
# Leitura das perguntas
# ---------------------------------------------------------------------------

def ler_perguntas(caminho: str) -> List[str]:
    """
    Le as perguntas do arquivo texto, uma por linha.

    Linhas vazias e linhas cujo primeiro caractere e "#" sao ignoradas
    (permite comentar exemplos sem apaga-los).

    @param  caminho : caminho do arquivo de entrada
    @return lista de perguntas na ordem do arquivo
    """
    if not os.path.isfile(caminho):
        raise FileNotFoundError(
            "Arquivo de perguntas nao encontrado: {0}\n"
            "Crie o arquivo com uma pergunta por linha.".format(caminho)
        )

    # utf-8-sig tolera BOM gravado pelo Bloco de Notas do Windows.
    with open(caminho, "r", encoding="utf-8-sig") as arquivo:
        perguntas = []
        for linha in arquivo:
            texto = linha.strip()
            if not texto or texto.startswith("#"):
                continue
            perguntas.append(texto)

    if not perguntas:
        raise ValueError(
            "Nenhuma pergunta encontrada em {0}".format(caminho)
        )

    return perguntas


# ---------------------------------------------------------------------------
# Chamadas HTTP (biblioteca padrao - sem dependencia de SDK)
# ---------------------------------------------------------------------------

def _requisitar(url: str, cabecalhos: Dict[str, str], corpo: Dict[str, Any],
                timeout: int) -> Dict[str, Any]:
    """
    Executa uma requisicao POST JSON e devolve a resposta ja interpretada.

    Levanta urllib.error.HTTPError para falhas HTTP e URLError para falhas
    de conexao (sem rede, DNS, timeout).
    """
    dados = json.dumps(corpo).encode("utf-8")
    requisicao = urllib.request.Request(
        url,
        data=dados,
        headers=cabecalhos,
        method="POST",
    )

    with urllib.request.urlopen(requisicao, timeout=timeout) as resposta:
        texto = resposta.read().decode("utf-8")

    try:
        return json.loads(texto)
    except json.JSONDecodeError as erro:
        raise RuntimeError(
            "Resposta da API nao e JSON valido: {0}".format(texto[:300])
        ) from erro


def _extrair_conteudo(provedor: str, resposta: Dict[str, Any]) -> str:
    """
    Extrai o texto gerado pelo modelo da estrutura de resposta de cada API.

    @param provedor  : "openai" ou "anthropic"
    @param resposta  : corpo JSON devolvido pela API
    @return o texto da resposta do modelo
    """
    try:
        # OpenAI e OpenCode falam a mesma API de chat/completions.
        if provedor in ("openai", "opencode"):
            conteudo = resposta["choices"][0]["message"]["content"]
        else:
            # A Anthropic devolve uma lista de blocos; interessa o de texto.
            blocos = resposta["content"]
            conteudo = "".join(
                bloco.get("text", "")
                for bloco in blocos
                if bloco.get("type") == "text"
            )
    except (KeyError, IndexError, TypeError) as erro:
        raise RuntimeError(
            "Estrutura de resposta inesperada: {0}".format(
                json.dumps(resposta, ensure_ascii=False)[:300]
            )
        ) from erro

    if not conteudo or not conteudo.strip():
        raise RuntimeError("A API devolveu uma resposta vazia.")

    return conteudo.strip()


def _montar_requisicao(provedor: str, modelo: str, api_key: str,
                       pergunta: str, temperatura: float,
                       max_tokens: int) -> Tuple[str, Dict[str, str],
                                                 Dict[str, Any]]:
    """
    Monta URL, cabecalhos e corpo da requisicao para o provedor escolhido.

    @return tupla (url, cabecalhos, corpo)
    """
    if provedor in ("openai", "opencode"):
        cabecalhos = {
            "Content-Type": "application/json",
            "Authorization": "Bearer {0}".format(api_key),
        }
        corpo = {
            "model": modelo,
            "temperature": temperatura,
            "max_tokens": max_tokens,
            "messages": [
                {"role": "system", "content": PROMPT_SISTEMA},
                {"role": "user", "content": pergunta},
            ],
        }
        if provedor == "opencode":
            # Cloudflare bloqueia com 403/1010 se faltar User-Agent, e o
            # cabecalho de sessao evita rejeicao no plano Go.
            cabecalhos["User-Agent"] = USER_AGENT
            cabecalhos["x-opencode-session"] = SESSAO_OPENCODE
            return URL_OPENCODE, cabecalhos, corpo
        return URL_OPENAI, cabecalhos, corpo

    cabecalhos = {
        "Content-Type": "application/json",
        "x-api-key": api_key,
        "anthropic-version": ANTHROPIC_VERSION,
    }
    corpo = {
        "model": modelo,
        "temperature": temperatura,
        "max_tokens": max_tokens,
        "system": PROMPT_SISTEMA,
        "messages": [{"role": "user", "content": pergunta}],
    }
    return URL_ANTHROPIC, cabecalhos, corpo


class LimiteAtingidoError(RuntimeError):
    """
    Cota do plano esgotada (ex.: FreeUsageLimitError do OpenCode).

    Nao e uma falha transitoria: repetir a pergunta nao resolve e todas as
    demais tambem falhariam. Por isso aborta o lote inteiro.
    """


def gerar_resposta(provedor: str, modelo: str, api_key: str, pergunta: str,
                   temperatura: float, max_tokens: int, tentativas: int,
                   timeout: int) -> str:
    """
    Envia uma pergunta ao modelo e devolve a resposta detalhada (CoT).

    Faz retentativa com espera exponencial para falhas de conexao, timeout,
    rate limit (429) e erros de servidor (5xx). Erros de autenticacao
    (401/403) sao fatais e interrompem a execucao imediatamente.

    @return o texto gerado pelo modelo
    """
    url, cabecalhos, corpo = _montar_requisicao(
        provedor, modelo, api_key, pergunta, temperatura, max_tokens
    )

    ultimo_erro = None
    tentativas_feitas = 0
    for tentativa in range(1, tentativas + 1):
        tentativas_feitas = tentativa
        try:
            resposta = _requisitar(url, cabecalhos, corpo, timeout)
            return _extrair_conteudo(provedor, resposta)

        except urllib.error.HTTPError as erro:
            corpo_erro = ""
            try:
                corpo_erro = erro.read().decode("utf-8", errors="replace")
            except Exception:  # noqa: BLE001 - melhor esforco na mensagem
                corpo_erro = ""

            if erro.code in (401, 403):
                raise RuntimeError(
                    "Chave de API invalida ou sem permissao (HTTP {0}). "
                    "Verifique a variavel de ambiente da chave. "
                    "Detalhe: {1}".format(erro.code, corpo_erro[:300])
                ) from erro

            # Cota esgotada: nao adianta retentar, todas as perguntas
            # seguintes falhariam igual. Aborta o lote com instrucao clara.
            if "FreeUsageLimitError" in corpo_erro:
                raise LimiteAtingidoError(
                    "Limite de uso do plano gratuito atingido (HTTP 429). "
                    "Modelos gratuitos do OpenCode so funcionam dentro do "
                    "OpenCode; para usar por script, assine o OpenCode Go "
                    "(https://opencode.ai/go) ou troque de modelo com "
                    "--model. Detalhe: {0}".format(corpo_erro[:300])
                ) from erro

            ultimo_erro = RuntimeError(
                "HTTP {0}: {1}".format(erro.code, corpo_erro[:300])
            )
            if erro.code not in CODIGOS_RECUPERAVEIS:
                break

        except (urllib.error.URLError, TimeoutError, OSError) as erro:
            # Falha de conexao: sem rede, DNS, firewall ou timeout.
            ultimo_erro = erro

        if tentativa < tentativas:
            espera = 2 ** tentativa
            tqdm.write(
                "  Tentativa {0}/{1} falhou ({2}); aguardando {3}s...".format(
                    tentativa, tentativas, ultimo_erro, espera
                )
            )
            time.sleep(espera)

    raise RuntimeError(
        "Falha apos {0} tentativa(s): {1}".format(tentativas_feitas,
                                                   ultimo_erro)
    )


# ---------------------------------------------------------------------------
# Programa principal
# ---------------------------------------------------------------------------

def processar_perguntas(perguntas: List[str], args: argparse.Namespace,
                        api_key: str) -> Tuple[int, List[str]]:
    """
    Processa todas as perguntas, gravando cada resultado no JSONL.

    @return tupla (quantidade_gravada, lista_de_falhas)
    """
    modo = "a" if args.anexar else "w"
    gravadas = 0
    falhas: List[str] = []

    with open(args.output, modo, encoding="utf-8") as arquivo:
        for indice, pergunta in enumerate(
            tqdm(perguntas, desc="Gerando dataset", unit="pergunta")
        ):
            try:
                resposta = gerar_resposta(
                    provedor=args.provider,
                    modelo=args.model,
                    api_key=api_key,
                    pergunta=pergunta,
                    temperatura=args.temperatura,
                    max_tokens=args.max_tokens,
                    tentativas=args.tentativas,
                    timeout=args.timeout,
                )
            except LimiteAtingidoError as erro:
                # Cota esgotada: parar aqui evita N falhas identicas, e
                # registra TODAS as perguntas que ficaram pendentes.
                tqdm.write("  INTERROMPIDO: {0}".format(erro))
                falhas.extend(perguntas[indice:])
                break

            except RuntimeError as erro:
                # Nao interrompe o lote: registra e segue para a proxima.
                falhas.append(pergunta)
                tqdm.write("  FALHA: {0}".format(erro))
                tqdm.write("  Pergunta: {0}".format(pergunta[:120]))
                continue

            registro = {
                "instruction": pergunta,
                "output": resposta,
            }
            arquivo.write(
                json.dumps(registro, ensure_ascii=False) + "\n"
            )
            arquivo.flush()  # garante resultado parcial em caso de queda
            gravadas += 1

    return gravadas, falhas


def resolver_chave_api(provedor: str) -> str:
    """
    Obtem a chave da API da variavel de ambiente correspondente.

    A chave nunca e lida do codigo-fonte: ela vive apenas na variavel de
    ambiente (OPENAI_API_KEY, ANTHROPIC_API_KEY ou OPENCODE_API_KEY).
    """
    variavel = {
        "openai": "OPENAI_API_KEY",
        "anthropic": "ANTHROPIC_API_KEY",
        "opencode": "OPENCODE_API_KEY",
    }[provedor]

    chave = os.environ.get(variavel, "").strip()
    if not chave:
        sys.exit(
            "ERRO: variavel de ambiente {0} nao definida.\n"
            "Windows (PowerShell):  $env:{0}=\"...\"\n"
            "Windows (CMD):         set {0}=...\n"
            "Linux/macOS:           export {0}=...".format(variavel)
        )
    return chave


def montar_argumentos() -> argparse.ArgumentParser:
    """Monta a linha de comando do script."""
    parser = argparse.ArgumentParser(
        description=(
            "Gera dataset de treinamento (instruction/output) em JSONL a "
            "partir de perguntas complexas, extraindo a logica de raciocinio "
            "de um modelo avancado."
        ),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--provider", choices=["openai", "anthropic", "opencode"],
        default="openai",
        help="Provedor da API.",
    )
    parser.add_argument(
        "--model", default=None,
        help=(
            "Modelo a consultar. Padrao: {0} (openai), {1} (anthropic) "
            "ou {2} (opencode)."
            .format(MODELO_OPENAI_PADRAO, MODELO_ANTHROPIC_PADRAO,
                    MODELO_OPENCODE_PADRAO)
        ),
    )
    parser.add_argument(
        "--input", default="perguntas.txt",
        help="Arquivo de entrada com uma pergunta por linha.",
    )
    parser.add_argument(
        "--output", default="dataset_treino.jsonl",
        help="Arquivo JSONL de saida.",
    )
    parser.add_argument(
        "--anexar", action="store_true",
        help="Anexa ao arquivo de saida existente em vez de sobrescrever.",
    )
    parser.add_argument(
        "--limit", type=int, default=0,
        help="Processa apenas as N primeiras perguntas (0 = todas).",
    )
    parser.add_argument(
        "--tentativas", type=int, default=3,
        help="Numero maximo de tentativas por pergunta.",
    )
    parser.add_argument(
        "--timeout", type=int, default=TIMEOUT_PADRAO,
        help="Timeout da requisicao, em segundos.",
    )
    parser.add_argument(
        "--temperatura", type=float, default=0.7,
        help="Temperatura de amostragem (0 = respostas mais deterministicas).",
    )
    parser.add_argument(
        "--max-tokens", type=int, default=4096,
        help="Limite maximo de tokens na resposta.",
    )
    return parser


def main() -> None:
    """Ponto de entrada do script."""
    args = montar_argumentos().parse_args()

    if args.model is None:
        # Modelo padrao por provedor.
        if args.provider == "openai":
            args.model = MODELO_OPENAI_PADRAO
        elif args.provider == "anthropic":
            args.model = MODELO_ANTHROPIC_PADRAO
        else:
            args.model = MODELO_OPENCODE_PADRAO

    try:
        perguntas = ler_perguntas(args.input)
    except (FileNotFoundError, ValueError) as erro:
        sys.exit("ERRO: {0}".format(erro))

    if args.limit > 0:
        perguntas = perguntas[:args.limit]

    api_key = resolver_chave_api(args.provider)

    print("Provedor : {0}".format(args.provider))
    print("Modelo   : {0}".format(args.model))
    if args.provider == "opencode":
        # Mostra o endpoint efetivo (permite conferir o plano pay-as-you-go
        # vs Go quando OPENCODE_BASE_URL e usado).
        print("Endpoint: {0}".format(URL_OPENCODE))
    print("Entrada  : {0} ({1} pergunta(s))".format(args.input,
                                                     len(perguntas)))
    print("Saida    : {0}{1}".format(
        args.output, " (anexando)" if args.anexar else ""
    ))
    print("")

    try:
        gravadas, falhas = processar_perguntas(perguntas, args, api_key)
    except KeyboardInterrupt:
        sys.exit("\nExecucao interrompida pelo usuario. "
                 "Resultados parciais ja estao gravados.")

    print("")
    print("Concluido: {0} registro(s) gravado(s) em {1}".format(
        gravadas, args.output
    ))
    if falhas:
        print("Falhas   : {0} pergunta(s) nao processada(s):".format(
            len(falhas)
        ))
        for pergunta in falhas:
            print("  - {0}".format(pergunta[:120]))
        print("Rode novamente com --anexar para tentar apenas as pendentes.")


if __name__ == "__main__":
    main()
