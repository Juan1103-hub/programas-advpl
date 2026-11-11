---
name: freebuff-cert-kaspersky
description: Freebuff (Bun) falha com SELF_SIGNED_CERT_IN_CHAIN porque Kaspersky re-assina HTTPS; fix via NODE_EXTRA_CA_CERTS
type: feedback
metadata:
  type: feedback
---

# Bug: Freebuff "Can't reach Freebuff's servers" (Kaspersky MITM de TLS)

**Data**: 2026-10-08 · **Fonte**: Freebuff CLI/app desktop (runtime Bun) · **Ambiente**: Windows, Kaspersky Endpoint Security 14.1 (gerenciado por política/NetworkAgent)

## Problema

TUI Freebuff exibia "Can't reach Freebuff's servers. Retrying.. Try another network."
Log `C:\Users\Vortice 0097\AppData\Roaming\freebuff\logs\orchestrator-stderr.log`:

```
TypeError: self signed certificate in certificate chain
code: "SELF_SIGNED_CERT_IN_CHAIN"
path: "https://us.i.posthog.com/batch/"
PostHogFetchNetworkError
[shell-lifetime] the Freebuff shell is quitting
```

## Causa raiz

KES 14.1 intercepta (MITM) conexões HTTPS e re-assina os certificados com a própria CA
(`CN=Kaspersky Endpoint Security Personal Certification Authority`, thumbprint
`34776D889409F47BFFF04DDCA3E55B8E7F921A78`, válida até 30/09/2036).
O runtime **Bun** do Freebuff não usa o store do Windows e não confia nessa CA → erro.
(PowerShell/schannel também via Kaspersky; Node retornava o cert real — stacks diferentes.)

## Fix aplicado e validado

1. Exportar CA Kaspersky em PEM: `C:\Users\Vortice 0097\.freebuff\kaspersky-ca.pem`
   (obtida de `Cert:\LocalMachine\Root` / `Cert:\CurrentUser\Root`).
2. Variável de usuário `NODE_EXTRA_CA_CERTS=C:\Users\Vortice 0097\.freebuff\kaspersky-ca.pem`
   (`[Environment]::SetEnvironmentVariable(...,'User')` + broadcast `WM_SETTINGCHANGE`).
3. Reabrir o Freebuff (processos antigos morrem sem a var).

**Validação**: `bun -e "fetch('https://freebuff.com').then(r=>console.log(r.status))"` → `200`
(antes: `SELF_SIGNED_CERT_IN_CHAIN`).

## Como aplicar / alternativas

- Se a CA do KES for trocada/renovada → re-exportar o PEM e revalidar.
- Alternativa definitiva: desativar "Análise de conexões criptografadas" no KES para o
  Freebuff (provavelmente bloqueado por política — abrir chamado/TI).
- Padrão geral: qualquer runtime que não leia o store Windows (Bun, Go, Python com SSL
  próprio) precisa dos roots explícitos quando há MITM corporativo.
