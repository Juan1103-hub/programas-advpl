# MCP context7/supabase não conectam no OpenCode — IPv6 quebrado + serviço com estado congelado

**Data:** 2026-10-19 (atualizado 2026-10-19 à noite)

## Problema
MCPs remotos `context7` e `supabase` (config em `~/.config/opencode/opencode.json`, `enabled: true`) não carregavam na sessão do OpenCode — só os MCPs locais (playwright, github, persyst-memory, notebooklm) subiam.

## Diagnóstico (fase 1 — IPv6, 2026-10-19 manhã)
1. Log do OpenCode (`~/.local/share/opencode/log/opencode.log`) mostrava:
   - `context7`: `getaddrinfo ENOTFOUND mcp.context7.com` → `ConnectionRefused` → `mcp connect failed`
   - `supabase`: `mcp connect failed ... (ConnectionRefused)`
2. PowerShell (`Invoke-WebRequest`) chegava aos dois endpoints normalmente — o Windows prefere IPv4.
3. `fetch` do **Node**: `connect timeout` nos dois. Teste com `dns.setDefaultResultOrder('ipv4first')` → funcionava.
4. **Causa raiz 1:** runtime Node/Bun tenta IPv6 (AAAA) primeiro; a rede não tinha rota IPv6 funcional.

**Correção fase 1** (requer UAC):
```powershell
Disable-NetAdapterBinding -Name "Wi-Fi" -ComponentID ms_tcpip6
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6
```

## Diagnóstico (fase 2 — serviço congelado, 2026-10-19 noite)
Após o fix de IPv6 os MCPs **continuavam** falhando. Novo achado:
1. `opencode mcp list` continuava reportando `ConnectionRefused` para context7 e supabase, mas `bun -e "fetch(...)"` e `node -e "fetch(...)"` em processos NOVOS conectavam direto (context7 = HTTP 200, supabase = HTTP 401 = só falta OAuth).
2. O `mcp list` **não tenta rede no processo do CLI** — delega ao serviço `opencode serve --service` (processo de longa duração, no caso rodando desde 09:25, antes do fix de rede). Esse processo herdou o estado de rede antigo (DNS/socket cache) e continuava recusando conexão para sempre.
3. Confirmação: variáveis de ambiente do processo de serviço **não** tinham proxy; a única diferença era o horário de criação (pré-fix).

**Causa raiz 2:** o serviço de longa duração do OpenCode mantém estado de rede congelado; qualquer fix de rede (IPv6, proxy, VPN, firewall) só efeito em processos novos.

**Correção fase 2:** reiniciar o serviço (matar o processo; o próximo comando `opencode` sobe um novo):
```powershell
Get-CimInstance Win32_Process -Filter "Name='opencode.exe'" |
  Where-Object { $_.CommandLine -match 'serve --service' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
# depois: opencode mcp list  (sobe serviço novo e reconecta tudo)
```

## Detalhe adicional do Supabase
O OAuth token em `~/.local/share/opencode/mcp-auth.json` estava expirado (~15/10/2026, `expiresAt` 1792162983). Após o reinício do serviço o `connected` veio **sem re-auth manual** (refresh automático). Se um dia não renovar sozinho: no TUI `/mcp` → supabase → autenticar (abre browser).

## Como aplicar em futuros problemas de MCP remoto
1. Checar log: `Select-String -Path "$env:USERPROFILE\.local\share\opencode\log\opencode.log" -Pattern "mcp connect failed"`.
2. Comparar PowerShell vs `node -e "fetch(...)"` — se PowerShell funciona e Node não, é caminho de rede do runtime (proxy/IPv6/cert).
3. **Se processos novos conectam mas o OpenCode não: reiniciar o serviço `opencode serve --service` antes de qualquer outra investigação.**
4. MCP OAuth: conferir `expiresAt` em `~/.local/share/opencode/mcp-auth.json`.

## Verificação final (2026-10-19 19:57)
```
✓ context7 ✓ github ✓ notebooklm ✓ opencode_console ✓ persyst-memory ✓ playwright ✓ supabase
```
[[stack-freebuff-opencode]]
