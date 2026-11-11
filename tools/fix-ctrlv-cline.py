import json, os

p = os.path.expandvars(
    r"%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
)

raw = open(p, encoding="utf-8-sig").read()
cfg = json.loads(raw)
acts = cfg.setdefault("actions", [])

# Remove sendInput de ctrl+enter duplicado (nao toca) e garante unbind ctrl+v
has = any(a.get("command") == "unbind" and "ctrl+v" in str(a.get("keys", "")).lower() for a in acts)
if not has:
    acts.append({"command": "unbind", "keys": "ctrl+v"})
    json.dump(cfg, open(p, "w", encoding="utf-8"), indent=4, ensure_ascii=False)

# Confirma lendo de volta
cfg2 = json.load(open(p, encoding="utf-8-sig"))
u = [a for a in cfg2["actions"] if a.get("command") == "unbind" and "ctrl+v" in str(a.get("keys", "")).lower()]
print("unbind ctrl+v aplicado e CONFIRMADO em disco:", bool(u))
print("Arquivo:", p)
print()
print("Agora: reabra o Windows Terminal -> abra o Cline -> tire print -> Ctrl+V")
print("(Se ja tiver WT aberto, feche TODAS as janelas antes de rodar este script)")
input("Enter para sair... ")
