# CONFIG/.opencode — Configuração local do OpenCode

Este diretório guarda a configuração **local do projeto** para o OpenCode
(sobre regras, skills espelhadas, memória e convenções por projeto). A configuração
**principal** fica no global:

- `~/.config/opencode/opencode.json` — configuração principal OpenCode
  (modelos free, plugins, MCP, skills paths)

## Estado real da configuração (2026-08-16)

| Artefato | Onde fica | Observação |
|----------|-----------|------------|
| Config principal OpenCode | `~/.config/opencode/opencode.json` | NÃO versionar (global) |
| Instruções do projeto | `.opencode/opencode.json` (`instructions`) + `AGENTS.md` raiz | versionados |
| Skills locais espelhadas | `CONFIG/.opencode/skills/<nome>/` | Mirror das skills deste workspace |
| Regras por projeto | `CONFIG/.opencode/Regras advpl/AGENTS.md` | Candidata (activation: candidate) |
| Memória OpenCode | `.opencode/memory.md` (raiz) | Versionada neste repo |
| Agents | `.opencode/agents/` (raiz) | Versionados neste repo |
| Settings workspace | `CONFIG/settings.json` | TDS, encoding windows-1252, idioma pt-br |
| Settings projeto | `.vscode/settings.json` | includes do TDS |
| Launch | `.vscode/launch.json` | Depuração |
| Servidores AppServer | `CONFIG/servers.json` | Contém token (não versionar/expandir) |
| Scripts de build | `CONFIG/scripts/build.mjs` | Rota executável de build (`npm run build`) |

## Regra de sincronização

Qualquer mudança nos arquivos de configuração acima (`CONFIG/settings.json`,
`.vscode/*`, remoção/movimentação de `opencode.json`, `CONFIG/servers.json`,
novos scripts de build) **deve** vir acompanhada de atualização deste README ou
do `README.md` da raiz — é o companion de documentação exigido pelo
core-change-watch (`config-setup-doc-sync`).