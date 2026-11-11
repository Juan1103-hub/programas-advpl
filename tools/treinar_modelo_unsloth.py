# -*- coding: utf-8 -*-
"""
Fine-tuning (destilacao) de um modelo open-source com Unsloth + LoRA 4-bit.

Le o dataset gerado por "gerar_dataset_treino.py" (dataset_treino.jsonl,
formato {"instruction": ..., "output": ...}) e treina um modelo base para
reproduzir a logica de raciocinio (Chain-of-Thought) do modelo avancado.

Onde rodar: Google Colab (GPU T4/A100) ou qualquer host Linux com GPU
NVIDIA. O Unsloth NAO roda nativamente no Windows e exige Python 3.10-3.12.

Instalacao no Colab (Runtime > Change runtime type > GPU):
    !pip install --upgrade --no-cache-dir unsloth

Uso:
    python treinar_modelo_unsloth.py                      # Qwen2.5 7B, 60 passos
    python treinar_modelo_unsloth.py --modelo llama       # Llama 3.1 8B
    python treinar_modelo_unsloth.py --epochs 1           # 1 epoca em vez de 60 passos
    python treinar_modelo_unsloth.py --gguf f16           # GGUF 16 bits em vez de Q4_K_M
    python treinar_modelo_unsloth.py --limit 3 --max-steps 5   # teste rapido

Saidas (na pasta --pasta, padrao "modelo_destilado_lora"):
    adapter_model.safetensors / adapter_config.json  -> pesos LoRA treinados
    tokenizer files                                 -> tokenizador
    *.gguf                                          -> para LM Studio / Ollama

Autor: Vortice Consultoria Mineral
Since: 2026-10-26
"""

import argparse
import json
import os
import sys

# ---------------------------------------------------------------------------
# Modelos base validados no Hugging Face (IDs sao CASE-SENSITIVE)
# ---------------------------------------------------------------------------

# ATENCAO: "unsloth/qwen2.5-7b-..." (minusculo) devolve 404 no Hugging Face.
MODELOS = {
    # Qwen2.5 7B - melhor em portugues, padrao deste script.
    "qwen": "unsloth/Qwen2.5-7B-Instruct-bnb-4bit",
    # Llama 3.1 8B - otimo em raciocinio, um pouco maior.
    "llama": "unsloth/Llama-3.1-8B-Instruct-bnb-4bit",
}

# Prompt de sistema usado NA DESTILACAO (gerar_dataset_treino.py) e no
# treino. Mantendo o mesmo texto aqui, o modelo aprende a produzir
# raciocinio passo a passo quando recebe este prompt na inferencia.
# IMPORTANTE: use o mesmo prompt em LM Studio / Ollama, ou o resultado
# fica pior (o template de chat precisa bater com o usado no treino).
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
# Leitura e formatacao do dataset
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Hiperparametros de treino (otimizados para GPU limitada, ex.: T4 16 GB)
# ---------------------------------------------------------------------------

# Lote efetivo = batch por dispositivo x acumulo de gradiente.
# batch 2 x acumulo 4 = 8: memoria baixa e gradiente razoavelmente estavel.
BATCH_TREINO = 2
ACUMULO_GRADIENTE = 4
LRA_TREINO = 2e-4          # taxa de aprendizado padrao para LoRA
R_LORA = 16                # rank dos adaptadores LoRA
ALPHA_LORA = 16            # escala dos adaptadores (alpha/r = 1.0)


def ler_dataset(caminho: str) -> list:
    """
    Le o JSONL gerado na etapa anterior e devolve a lista de registros.

    Cada linha deve ser um objeto JSON com "instruction" e "output".
    Linhas invalidas sao relatadas com o numero da linha e o script
    aborta (um dataset corrompido nao deve ser treinado em silencio).
    """
    if not os.path.isfile(caminho):
        sys.exit(
            "ERRO: dataset nao encontrado: {0}\n"
            "Gere-o antes com: python tools/gerar_dataset_treino.py".format(
                caminho
            )
        )

    registros = []
    erros = []
    with open(caminho, "r", encoding="utf-8") as arquivo:
        for numero, linha in enumerate(arquivo, start=1):
            texto = linha.strip()
            if not texto:
                continue
            try:
                item = json.loads(texto)
            except json.JSONDecodeError:
                erros.append("linha {0}: nao e JSON valido".format(numero))
                continue

            if not isinstance(item, dict):
                erros.append("linha {0}: nao e um objeto JSON".format(numero))
                continue

            faltando = [c for c in ("instruction", "output")
                        if not str(item.get(c, "")).strip()]
            if faltando:
                erros.append(
                    "linha {0}: campo(s) vazio(s): {1}".format(
                        numero, ", ".join(faltando)
                    )
                )
                continue

            registros.append({
                "instruction": str(item["instruction"]).strip(),
                "output": str(item["output"]).strip(),
            })

    if erros:
        sys.exit(
            "ERRO: {0} linha(s) invalida(s) em {1}:\n  {2}".format(
                len(erros), caminho, "\n  ".join(erros[:10])
            )
        )

    if not registros:
        sys.exit("ERRO: nenhuma pergunta valida em {0}".format(caminho))

    return registros


def formatar_textos(registros: list, tokenizer, usar_system: bool) -> list:
    """
    Converte cada registro no campo "text" esperado pelo SFTTrainer.

    Usa o PROPRIO chat template do modelo (tokenizer.apply_chat_template),
    montando a conversa completa:

        system    -> PROMPT_SISTEMA (opcional)
        user      -> instruction (a pergunta)
        assistant -> output (a resposta detalhada que queremos ensinar)

    add_generation_prompt=False e essencial: sem ele o template terminaria
    com "<|start_header_id|>assistant<|end_header_id|>" SEM a resposta, e o
    modelo aprenderia a prever o que nao esta escrito.

    O campo "text" e o que o SFTTrainer tokeniza por padrao
    (dataset_text_field="text").
    """
    textos = []
    for item in registros:
        mensagens = []
        if usar_system:
            mensagens.append({"role": "system", "content": PROMPT_SISTEMA})
        mensagens.append({"role": "user", "content": item["instruction"]})
        mensagens.append({"role": "assistant", "content": item["output"]})

        textos.append({
            "text": tokenizer.apply_chat_template(
                mensagens,
                tokenize=False,
                add_generation_prompt=False,
            )
        })
    return textos


# ---------------------------------------------------------------------------
# Programa principal
# ---------------------------------------------------------------------------

def montar_argumentos() -> argparse.ArgumentParser:
    """Monta a linha de comando do script."""
    parser = argparse.ArgumentParser(
        description=(
            "Fine-tuning LoRA 4-bit com Unsloth a partir de "
            "dataset_treino.jsonl."
        ),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--modelo", choices=sorted(MODELOS.keys()), default="qwen",
        help="Modelo base a treinar.",
    )
    parser.add_argument(
        "--dataset", default="dataset_treino.jsonl",
        help="Arquivo JSONL de entrada (instruction/output).",
    )
    parser.add_argument(
        "--pasta", default="modelo_destilado_lora",
        help="Pasta de saida do modelo treinado.",
    )
    parser.add_argument(
        "--max-steps", type=int, default=60,
        help="Numero maximo de passos de treino (usado se --epochs = 0).",
    )
    parser.add_argument(
        "--epochs", type=float, default=0,
        help="Epocas de treino; se > 0, substitui --max-steps.",
    )
    parser.add_argument(
        "--seq-len", type=int, default=2048,
        help="Tamanho maximo de sequencia (memoria x contexto).",
    )
    parser.add_argument(
        "--gguf", choices=["q4_k_m", "f16", "q8_0", "nao"],
        default="q4_k_m",
        help="Quantizacao do GGUF exportado; 'nao' pula a exportacao.",
    )
    parser.add_argument(
        "--limit", type=int, default=0,
        help="Usa apenas as N primeiras amostras (0 = todas).",
    )
    parser.add_argument(
        "--sem-system", action="store_true",
        help="Nao inclui o prompt de sistema no treino (nao recomendado).",
    )
    return parser


def main() -> None:
    """Ponto de entrada do script."""
    args = montar_argumentos().parse_args()

    # Importacoes pesadas DEPOIS do argparse: assim "--help" funciona mesmo
    # sem torch/unsloth instalados. A mensagem de erro diz o que instalar.
    try:
        import torch
        from datasets import Dataset
        from trl import SFTConfig, SFTTrainer
        from unsloth import FastLanguageModel, is_bfloat16_supported
    except ImportError as erro:
        sys.exit(
            "ERRO: dependencias nao instaladas ({0}).\n"
            "No Google Colab, rode primeiro:\n"
            "    !pip install --upgrade --no-cache-dir unsloth\n"
            "Em outro ambiente Linux:\n"
            "    pip install --upgrade --no-cache-dir unsloth trl datasets\n"
            "Requisitos: GPU NVIDIA, Python 3.10-3.12.".format(erro)
        )

    # --- 0. Pre-condicoes -------------------------------------------------
    if not torch.cuda.is_available():
        sys.exit(
            "ERRO: nenhuma GPU NVIDIA CUDA detectada.\n"
            "O Unsloth exige GPU. No Colab: Runtime > Change runtime type > GPU.\n"
            "Este script NAO roda na maquina local (Windows / GPU 940MX)."
        )

    nome_modelo = MODELOS[args.modelo]
    registros = ler_dataset(args.dataset)
    if args.limit > 0:
        registros = registros[:args.limit]

    print("Modelo   : {0}".format(nome_modelo))
    print("Dataset  : {0} ({1} amostra(s))".format(args.dataset,
                                                   len(registros)))
    print("Saida    : {0}".format(args.pasta))
    print("GPU      : {0}".format(torch.cuda.get_device_name(0)))
    print("")

    # --- 1. Modelo base em 4-bit (QLoRA) ---------------------------------
    # load_in_4bit=True carrega os pesos do modelo ja quantizados em 4 bits,
    # cortando em ~4x a memoria da GPU: 7B-8B cabem em GPUs de 16 GB.
    # dtype=None detecta automaticamente float16/bfloat16 conforme a GPU.
    # max_seq_length define o contexto e ativa o RoPE scaling automatico.
    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name=nome_modelo,
        max_seq_length=args.seq_len,
        dtype=None,
        load_in_4bit=True,
    )

    # --- 2. Adaptadores LoRA / PEFT --------------------------------------
    # r=16 e lora_alpha=16: rank e escala iguais (escala = alpha/r = 1.0),
    # valor de referencia estavel para datasets pequenos.
    # target_modules: projecoes de ATENCAO (q/k/v/o) + MLP (gate/up/down).
    # Incluir a MLP costuma dar mais qualidade com pouco custo extra.
    # lora_dropout=0 e bias="none": otimizados no Unsloth (mais rapidos).
    # use_gradient_checkpointing="unsloth": reduz o pico de VRAM em ~30%.
    model = FastLanguageModel.get_peft_model(
        model,
        r=R_LORA,
        target_modules=[
            "q_proj", "k_proj", "v_proj", "o_proj",
            "gate_proj", "up_proj", "down_proj",
        ],
        lora_alpha=ALPHA_LORA,
        lora_dropout=0,
        bias="none",
        use_gradient_checkpointing="unsloth",
        random_state=42,
    )

    # --- 3. Mapeamento de prompt (instruction + output -> "text") --------
    textos = formatar_textos(
        registros, tokenizer, usar_system=not args.sem_system
    )
    dataset = Dataset.from_list(textos)

    # Aviso anti-overfitting: com poucas amostras e muitos passos o modelo
    # decora as respostas em vez de generalizar o raciocinio.
    efetivo = BATCH_TREINO * ACUMULO_GRADIENTE
    passos = args.max_steps if args.epochs <= 0 else max(
        1, int(args.epochs * len(dataset) / efetivo)
    )
    epocas_estimadas = (passos * efetivo) / max(1, len(dataset))
    if epocas_estimadas > 10:
        print(
            "AVISO: {0} passos sobre {1} amostra(s) equivalem a ~{2:.0f} "
            "epocas.\n"
            "       Ha risco de decorar os dados. Use mais perguntas no "
            "dataset ou reduza --max-steps.".format(
                passos, len(dataset), epocas_estimadas
            )
        )
        print("")

    # --- 4. Hiperparametros do treino ------------------------------------
    # Otimizados para hardware limitado (GPU T4 16 GB no Colab):
    #   batch 2 x acumulo 4 = lote efetivo 8 (memoria baixa, gradiente estavel)
    #   max_steps 60 = teste rapido; troque por --epochs 1 para treino real
    #   lr 2e-4 = padrao para LoRA; adamw_8bit = otimizador 8-bit (economiza RAM)
    #   cosine + warmup = aquecimento curto e decaimento suave da taxa
    #   bf16/fp16 = precisao reduzida, obrigatoria para caber na GPU
    kwargs_treino = {}
    if args.epochs > 0:
        kwargs_treino["num_train_epochs"] = args.epochs
    else:
        kwargs_treino["max_steps"] = args.max_steps

    training_args = SFTConfig(
        output_dir=os.path.join(args.pasta, "checkpoints"),
        dataset_text_field="text",   # campo "text" criado acima
        max_length=args.seq_len,     # tokeniza ate este tamanho
        per_device_train_batch_size=BATCH_TREINO,
        gradient_accumulation_steps=ACUMULO_GRADIENTE,
        learning_rate=LRA_TREINO,
        warmup_ratio=0.03,           # ~3% dos passos aquecendo a taxa
        lr_scheduler_type="cosine",
        optim="adamw_8bit",          # otimizador em 8 bits
        bf16=is_bfloat16_supported(),
        fp16=not is_bfloat16_supported(),
        logging_steps=5,
        save_strategy="no",          # salvamos manualmente no final
        seed=42,
        report_to="none",            # sem wandb/tensorboard
        **kwargs_treino,
    )

    trainer = SFTTrainer(
        model=model,
        args=training_args,
        train_dataset=dataset,
    )

    # --- 5. Treino --------------------------------------------------------
    trainer.train()

    # --- 6. Salvamento ----------------------------------------------------
    # a) Adaptadores LoRA (arquivos pequenos, ~100 MB) + tokenizador.
    #    Esta e a pasta pedida: modelo_destilado_lora/
    os.makedirs(args.pasta, exist_ok=True)
    model.save_pretrained(args.pasta)
    tokenizer.save_pretrained(args.pasta)
    print("Adaptadores LoRA salvos em: {0}".format(args.pasta))

    # b) Exportacao para GGUF, para rodar no LM Studio / Ollama / llama.cpp.
    #    q4_k_m = recomendado (leve, boa qualidade) - ~4.5 GB para 7B.
    #    f16    = 16 bits, sem perda - ~15 GB para 7B.
    #    ATENCAO: a exportacao precisa de RAM livre; no Colab use
    #    Runtime > Change runtime type > High-RAM se der OOM.
    if args.gguf != "nao":
        try:
            model.save_pretrained_gguf(
                args.pasta,
                tokenizer,
                quantization_method=args.gguf,
            )
            print("GGUF ({0}) exportado em: {1}".format(args.gguf,
                                                        args.pasta))
        except Exception as erro:  # noqa: BLE001 - avisa sem perder o treino
            print(
                "AVISO: falha ao exportar GGUF ({0}).\n"
                "       Os adaptadores ja foram salvos. Tente:\n"
                "       - mais RAM (Colab High-RAM);\n"
                "       - outro --gguf (q4_k_m / q8_0 / f16);\n"
                "       - salvar manualmente com "
                "model.save_pretrained_merged(pasta, tokenizer, "
                'save_method="merged_16bit").'.format(erro)
            )

    print("")
    print("Concluido. Proximos passos:")
    print("  LM Studio : carregue o arquivo .gguf de {0}".format(args.pasta))
    print("  Ollama    : crie um Modelfile com FROM {0}/<arquivo>.gguf"
          .format(args.pasta))
    print("  Inferencia: use o MESMO prompt de sistema do treino "
          "(ou --sem-system, se treinou sem).")


if __name__ == "__main__":
    main()
