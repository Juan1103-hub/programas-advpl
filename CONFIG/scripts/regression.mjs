#!/usr/bin/env node
/*
 * CONFIG/scripts/regression.mjs
 *
 * Gate mecanico de regressao sobre o diff atual do workspace PROGRAMAS_ADVPL.
 * Conecta a mudanca em curso (diff vs HEAD) a suite TIR em CONFIG/tir e retem
 * o resultado de validacao atrelado a revisao (git HEAD).
 *
 * Etapas:
 *   1. diff       - computa o diff vs HEAD (arquivos, linhas, criticidade)
 *   2. suite      - verifica o modulo Python `tir` (pacote TIR/Webapp)
 *   3. run        - executa ZLANCDIETESTSUITE.py em CONFIG/tir quando possivel
 *   4. retain     - grava relatorio legivel (CONFIG/.build/regression-last-run.md)
 *
 * O resultado e SEMPRE retido de forma honesta: se a suite nao pode rodar
 * (modulo `tir` ausente, config com placeholders), a etapa fica BLOCKED/
 * UNVERIFIED com o motivo — nunca omitida nem declarada como pass.
 *
 * Uso:
 *   npm run regression              # gate completo
 *   node CONFIG/scripts/regression.mjs --json
 */

import { execFile } from "node:child_process";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

const ROOT = path.resolve(import.meta.dirname, "..", "..");
const CONFIG_DIR = path.join(ROOT, "CONFIG");
const BUILD_DIR = path.join(CONFIG_DIR, ".build");
const TIR_DIR = path.join(CONFIG_DIR, "tir");
const TIR_SUITE = path.join(TIR_DIR, "ZLANCDIETESTSUITE.py");
const TIR_CONFIG = path.join(TIR_DIR, "config.json");
const LAST_RUN_MD = path.join(BUILD_DIR, "regression-last-run.md");
const LAST_RUN_JSON = path.join(BUILD_DIR, "regression-last-run.json");

const PLACEHOLDER_TOKEN = /^\{(server|port|environment_name|username|password)\}$/u;

async function gitHead() {
  try {
    const { stdout } = await execFileAsync("git", ["-C", ROOT, "rev-parse", "--short", "HEAD"]);
    return stdout.trim() || "unknown";
  } catch {
    return "unknown";
  }
}

async function diffSummary() {
  try {
    const { stdout } = await execFileAsync("git", [
      "-C", ROOT, "diff", "--numstat", "--no-ext-diff", "--find-renames", "HEAD", "--",
    ]);
    let added = 0;
    let deleted = 0;
    const files = [];
    for (const line of stdout.split(/\r?\n/u)) {
      if (!line.trim()) continue;
      const [a, d, file] = line.split("\t");
      if (!file) continue;
      const na = Number(a) || 0;
      const nd = Number(d) || 0;
      added += na;
      deleted += nd;
      files.push({ path: file.replace(/^"|"$/gu, ""), added: na, deleted: nd });
    }
    const severity = added + deleted >= 10000 ? "critical" : added + deleted >= 1000 ? "large" : "normal";
    return { changedFiles: files.length, added, deleted, severity, files };
  } catch {
    return { changedFiles: 0, added: 0, deleted: 0, severity: "unknown", files: [] };
  }
}

async function tirAvailability() {
  const python = process.env.PYTHON || "python";
  const checks = [];
  try {
    const { stderr } = await execFileAsync(python, ["-c", "import tir; print(tir.__file__)"]);
    checks.push({ tool: "tir", available: true, detail: stderr.trim() || "modulo importado" });
  } catch (error) {
    checks.push({
      tool: "tir",
      available: false,
      detail: String(error?.stderr ?? error?.message ?? "").trim() || "modulo indisponivel",
    });
  }
  let configStatus = "ok";
  try {
    const raw = await readFile(TIR_CONFIG, "utf8");
    const config = JSON.parse(raw);
    const placeholders = Object.values(config).some((value) => typeof value === "string" && PLACEHOLDER_TOKEN.test(value));
    configStatus = placeholders ? "placeholder" : "ok";
  } catch {
    configStatus = "unreadable";
  }
  return { python, checks, configStatus };
}

async function stageDiff() {
  const summary = await diffSummary();
  return {
    status: "pass",
    detail: `Diff vs HEAD: ${summary.changedFiles} arquivo(s), +${summary.added}/-${summary.deleted} linhas (severidade ${summary.severity}).`,
    ...summary,
  };
}

async function stageSuite() {
  const availability = await tirAvailability();
  if (!availability.checks[0].available) {
    return {
      status: "blocked",
      detail: `Modulo Python 'tir' nao encontrado (${availability.checks[0].detail}). Suite TIR nao executada — resultado retido como BLOCKED (honesto).`,
      python: availability.python,
      configStatus: availability.configStatus,
    };
  }
  if (availability.configStatus === "placeholder") {
    return {
      status: "blocked",
      detail: "CONFIG/tir/config.json ainda usa placeholders {server}/{port}/{environment_name}/{username}/{password}. Preencha antes de rodar o gate.",
      python: availability.python,
      configStatus: availability.configStatus,
    };
  }
  return {
    status: "ready",
    detail: `Modulo 'tir' disponivel e config completa. Suite: ${path.relative(ROOT, TIR_SUITE)}`,
    python: availability.python,
    configStatus: availability.configStatus,
  };
}

async function stageRun(suite) {
  if (suite.status !== "ready") {
    return {
      status: suite.status,
      detail: "Suite TIR nao executada (ver etapa 'suite').",
      output: null,
    };
  }
  let output;
  let failed = false;
  try {
    const { stdout, stderr } = await execFileAsync(suite.python, [TIR_SUITE], { cwd: TIR_DIR });
    output = `${stdout}\n${stderr}`.trim();
    failed = /FAILED\b|errors=\d+|failures=\d+/u.test(output) && !/failures=\s*0.*errors=\s*0/u.test(output.replace(/\s+/gu, " "));
  } catch (error) {
    failed = true;
    output = String(error?.stdout ?? "") + "\n" + String(error?.stderr ?? error?.message ?? "");
  }
  return {
    status: failed ? "fail" : "pass",
    detail: `Suite TIR executada (${suite.python}). Resultado: ${failed ? "FALHOU" : "PASSOU"}.`,
    output,
  };
}

function short(entry) {
  return entry?.detail ?? `${entry?.status ?? "unknown"}: sem detalhe`;
}

async function main() {
  const json = process.argv.includes("--json");
  const head = await gitHead();
  const start = Date.now();

  const diff = await stageDiff();
  const suite = await stageSuite();
  const run = await stageRun(suite);

  const steps = { diff, suite, run };
  const overall = ["fail"].includes(run.status) ? "fail"
    : ["blocked"].includes(run.status) ? "warn"
    : "pass";
  const elapsedMs = Date.now() - start;
  const summary = {
    kind: "advpl-regression-run",
    status: overall,
    revision: head,
    ranAt: new Date().toISOString(),
    elapsedMs,
    steps,
  };

  await mkdir(BUILD_DIR, { recursive: true });
  await writeFile(LAST_RUN_JSON, `${JSON.stringify(summary, null, 2)}\n`);
  const lines = [
    `# Regression report — PROGRAMAS_ADVPL`,
    ``,
    `- Revisao: \`${head}\``,
    `- Execucao: ${summary.ranAt}`,
    `- Status: **${overall}**`,
    ``,
    `## diff`,
    ``,
    `- ${short(diff)}`,
    ``,
    `## suite`,
    ``,
    `- Status: ${suite.status}`,
    `- ${short(suite)}`,
    `- Python: ${suite.python} | config: ${suite.configStatus}`,
    ``,
    `## run`,
    ``,
    `- Status: ${run.status}`,
    `- ${short(run)}`,
    ...(run.output
      ? [`- Saida (ultimas linhas):`, ...run.output.split(/\r?\n/u).slice(-20).map((l) => `  \`${l}\``)]
      : []),
    ``,
    `> Resultado atrelado a revisao \`${head}\`. Rerun: \`npm run regression\`.`,
    ``,
  ];
  await writeFile(LAST_RUN_MD, lines.join("\n"));

  const artifact = path.relative(ROOT, LAST_RUN_MD).replaceAll("\\", "/");
  process.stdout.write(
    json
      ? `${JSON.stringify(summary, null, 2)}\n`
      : `Regression ${overall} (rev ${head}, ${elapsedMs}ms) — relatorio: ${artifact}\n`,
  );
}

main().catch((error) => {
  process.stderr.write(`regression.mjs falhou: ${String(error?.message ?? error)}\n`);
  process.exitCode = 1;
});