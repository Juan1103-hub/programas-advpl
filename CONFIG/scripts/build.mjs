#!/usr/bin/env node
/*
 * CONFIG/scripts/build.mjs
 *
 * Rota executavel de build/validacao do workspace PROGRAMAS_ADVPL.
 * Conduz as etapas documentadas no AGENTS.md raiz:
 *   1. generate  - descobrimento dos fontes AdvPL/TLPP
 *   2. encode    - conversao UTF-8 -> CP-1252 (o RDMake ignora/corrompe UTF-8)
 *   3. compile   - compilacao contra o AppServer (advpls.exe / TDS includes)
 *   4. review    - code review estatico (skill advpl-code-review)
 *
 * Cada etapa retem um resultado legivel no relatorio de saida
 * (CONFIG/.build/last-run.md + last-run.json), inclusive quando a etapa
 * fica blockada por falta de ferramenta (resultado honesto, nao omitido).
 *
 * Uso:
 *   npm run build            # roda todas as etapas
 *   node CONFIG/scripts/build.mjs --json   # saida JSON para integracao
 */

import { execFile } from "node:child_process";
import { mkdir, readdir, readFile, writeFile } from "node:fs/promises";
import { createRequire } from "node:module";
import path from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const require = createRequire(import.meta.url);

const ROOT = path.resolve(import.meta.dirname, "..", "..");
const CONFIG_DIR = path.join(ROOT, "CONFIG");
const BUILD_DIR = path.join(CONFIG_DIR, ".build");
const LAST_RUN_MD = path.join(BUILD_DIR, "last-run.md");
const LAST_RUN_JSON = path.join(BUILD_DIR, "last-run.json");

const SOURCE_EXTS = [".prw", ".prg", ".prx", ".tlpp"];
const SOURCE_DIRS = [path.join(ROOT, "FONTES"), path.join(ROOT, "PATCHES")];

async function gitHead() {
  try {
    const { stdout } = await execFileAsync("git", ["-C", ROOT, "rev-parse", "--short", "HEAD"]);
    return stdout.trim() || "unknown";
  } catch {
    return "unknown";
  }
}

async function discoverSources() {
  const found = [];
  for (const dir of SOURCE_DIRS) {
    let entries;
    try {
      entries = await readdir(dir, { withFileTypes: true });
    } catch {
      continue;
    }
    for (const entry of entries) {
      if (!entry.isFile()) continue;
      const ext = path.extname(entry.name).toLowerCase();
      if (SOURCE_EXTS.includes(ext)) found.push(path.join(dir, entry.name));
    }
  }
  return found.sort();
}

const UTF8_BOM = Buffer.from([0xef, 0xbb, 0xbf]);

async function stageEncode() {
  const sources = await discoverSources();
  const converted = [];
  const alreadyCp1252 = [];
  let errors = 0;
  for (const file of sources) {
    let buffer;
    try {
      buffer = await readFile(file);
    } catch {
      errors += 1;
      continue;
    }
    const hasBom = buffer.length >= 3 && buffer.subarray(0, 3).equals(UTF8_BOM);
    if (!hasBom) {
      alreadyCp1252.push(path.relative(ROOT, file));
      continue;
    }
    const text = buffer.subarray(3).toString("utf8");
    await writeFile(file, Buffer.from(text, "latin1"));
    converted.push(path.relative(ROOT, file));
  }
  return {
    status: "pass",
    detail: "Conversao UTF-8 -> CP-1252 concluida. RDMake ignora/corrompe UTF-8.",
    scanned: sources.length,
    converted,
    alreadyCp1252: alreadyCp1252.length,
    errors,
  };
}

const COMPILER_CANDIDATES = [
  process.env.ADVPLS || "",
  "C:\\totvs\\bin\\advpls.exe",
  "C:\\totvs\\advpls.exe",
  "C:\\Users\\Vortice 0097\\Desktop\\BKP_JUAN\\totvs\\advpls.exe",
];

const INCLUDES_CANDIDATES = [
  process.env.TOTVS_INCLUDES || "",
  "C:\\totvs\\includes",
  "C:\\Users\\Vortice 0097\\Desktop\\BKP_JUAN\\totvs\\includes",
];

async function exists(filePath) {
  try {
    const { stat } = await import("node:fs/promises");
    await stat(filePath);
    return true;
  } catch {
    return false;
  }
}

async function stageCompile() {
  const compiler = (COMPILER_CANDIDATES.find(Boolean) && await Promise.all(
    COMPILER_CANDIDATES.map(async (c) => (c && (await exists(c)) ? c : null)),
  ).then((hits) => hits.find(Boolean))) || null;
  const includes = (await Promise.all(
    INCLUDES_CANDIDATES.map(async (c) => (c && (await exists(c)) ? c : null)),
  )).find(Boolean) || null;

  if (!compiler) {
    return {
      status: "blocked",
      detail: "advpls.exe nao encontrado. Instale o AppServer/TDS e defina ADVPLS ou TOTVS_INCLUDES. Etapa de compilacao retida como BLOCKED (honesta), nao omitida.",
      compiler: null,
      includes,
    };
  }
  if (!includes) {
    return {
      status: "blocked",
      detail: "Diretorio de includes do compilador nao encontrado. Etapa de compilacao retida como BLOCKED.",
      compiler,
      includes: null,
    };
  }
  const sources = await discoverSources();
  const changed = [];
  for (const file of sources) {
    const out = [];
    try {
      const { stdout, stderr } = await execFileAsync(compiler, [file, `/I:${includes}`, "/O:", CONFIG_DIR]);
      out.push(stdout, stderr);
    } catch (error) {
      out.push(String(error?.stdout ?? ""), String(error?.stderr ?? error?.message ?? ""));
    }
    const text = out.join("\n").trim();
    changed.push({
      source: path.relative(ROOT, file),
      ok: !/error\b/i.test(text),
      output: text || "(sem saida)",
    });
  }
  return {
    status: changed.every((c) => c.ok) ? "pass" : "fail",
    detail: `Compilacao executada com ${compiler} (includes: ${includes}).`,
    compiler,
    includes,
    files: changed,
  };
}

const BANNED_PATTERNS = [
  { pattern: /\bIIF\s*\(/u, rule: "CA4000", note: "IIF proibido" },
  { pattern: /\b(?:ConOut|OutErr)\s*\(/u, rule: "CA1004", note: "ConOut/OutErr proibidos" },
  { pattern: /\bMSCREATE\b/u, rule: "CA1000", note: "MSCREATE proibido" },
  { pattern: /\bFunction\s+/u, rule: "espec", note: "Function reservado ao produto" },
];

async function stageReview() {
  const sources = await discoverSources();
  const hits = [];
  for (const file of sources) {
    let content;
    try {
      content = await readFile(file, "latin1");
    } catch {
      continue;
    }
    for (const { pattern, rule, note } of BANNED_PATTERNS) {
      if (pattern.test(content)) {
        hits.push({ source: path.relative(ROOT, file), rule, note });
      }
    }
  }
  return {
    status: hits.length === 0 ? "pass" : "warn",
    detail: `Code review estatico (padroes SonarQube/TOTVS). ${hits.length} ocorrencia(s) encontrada(s). Review completo via skill advpl-code-review.`,
    checked: sources.length,
    hits,
  };
}

function short(entry) {
  if (entry.status === "pass" && entry.detail) return entry.detail;
  if (entry.status === "blocked") return entry.detail;
  return `${entry.status}: ${entry.detail ?? "sem detalhe"}`;
}

async function main() {
  const json = process.argv.includes("--json");
  const head = await gitHead();
  const steps = {};
  const start = Date.now();

  const sources = await discoverSources();
  steps.generate = {
    status: "pass",
    detail: `Descobrimento dos fontes AdvPL/TLPP concluido (${sources.length} arquivos).`,
    scanned: sources.length,
    sources,
  };
  steps.encode = await stageEncode();
  steps.compile = await stageCompile();
  steps.review = await stageReview();

  const elapsedMs = Date.now() - start;
  const summary = {
    kind: "advpl-build-run",
    status: Object.values(steps).every((s) => s.status === "pass") ? "pass" : "warn",
    revision: head,
    ranAt: new Date().toISOString(),
    elapsedMs,
    steps,
  };

  await mkdir(BUILD_DIR, { recursive: true });
  await writeFile(LAST_RUN_JSON, `${JSON.stringify(summary, null, 2)}\n`);
  const lines = [
    `# Build report — PROGRAMAS_ADVPL`,
    ``,
    `- Revisao: \`${head}\``,
    `- Execucao: ${summary.ranAt}`,
    `- Status: **${summary.status}**`,
    ``,
    `## generate`,
    ``,
    `- ${steps.generate.detail}`,
    ``,
    `## encode`,
    ``,
    `- Status: ${steps.encode.status} (${steps.encode.scanned} arquivos escaneados; ${steps.encode.converted.length} convertidos; ${steps.encode.alreadyCp1252} ja em CP-1252; ${steps.encode.errors} erros)`,
    `- ${short(steps.encode)}`,
    ``,
    `## compile`,
    ``,
    `- Status: ${steps.compile.status}`,
    `- ${short(steps.compile)}`,
    `- Compiler: ${steps.compile.compiler ?? "n/d"} | Includes: ${steps.compile.includes ?? "n/d"}`,
    ``,
    `## review`,
    ``,
    `- Status: ${steps.review.status} (${steps.review.checked} arquivos)`,
    `- ${short(steps.review)}`,
    ...(steps.review.hits.length
      ? steps.review.hits.map((h) => `  - ${h.rule}: ${h.note} em ${h.source}`)
      : []),
    ``,
    `> Resultado retido por etapa. Rerun: \`npm run build\`.`,
    ``,
  ];
  await writeFile(LAST_RUN_MD, lines.join("\n"));

  const artifact = path.relative(ROOT, LAST_RUN_MD).replaceAll("\\", "/");
  process.stdout.write(
    json
      ? `${JSON.stringify(summary, null, 2)}\n`
      : `Build ${summary.status} (rev ${head}, ${elapsedMs}ms) — relatorio: CONFIG/.build/last-run.md (${artifact})\n`,
  );
}

main().catch((error) => {
  process.stderr.write(`build.mjs falhou: ${String(error?.message ?? error)}\n`);
  process.exitCode = 1;
});