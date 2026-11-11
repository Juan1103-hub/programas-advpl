---
name: smartview-500-profile-pedidocompra
description: SmartView 500 no relatorio Pedido de Compra - profile corrompido do usuario no SIGACFG/PROFMGR
type: feedback
metadata:
  type: feedback
---
**Problema:** Ao abrir no SmartView o relatorio padrao "Pedido de Compra" (SIGACOM), dialogo TOTVS "500 InternalServerError - O ERP TOTVS teve um comportamento inesperado". Ocorria todas as vezes, apenas para o usuario do relatorio; outros 4 usuarios abriam o mesmo relatorio normalmente.

**Causa:** Registro do usuario corrompido/incompativel na Manutencao de Profile (SIGACFG > Ambiente > Cadastros > Manutencao de Profile / PROFMGR). O framework TReports chama `Schema:GetValueFromProfile` (SCHEMA.TLPP line 1348) ao montar o schema do ON padrao `totvs.protheus.backoffice.com.smartview.integratedprovider.purchaseordersmartviewbusinessobject` e morria com `array out of bounds ( 13 of 12 )` -> REST 500. Evidencia no console_wsrest do AppServer PRODUCAO (08/10/2026): 17 das 18 tentativas do usuario 000047 falharam em `/schema/...purchaseorder...`; usuarios 000057/000059/000080/000095 (1 tentativa cada) abriram sem erro. O ON custom SC7TREP **nunca foi chamado** - o usuario estava usando o relatorio padrao TOTVS.

**Fix:** SIGACFG -> Ambiente -> Cadastros -> Manutenção de Profile (PROFMGR) -> localizar o usuário -> Excluir -> "Todos registros do usuário". Validado pelo usuário: "deu certo! era realmente excluir o registro do usuario na manutenção de profile". (Backup opcional prévio: `protheus_data\profile\profile.usr`.)

**Como aplicar:**
- SmartView retorna 500 só para UM usuário e outros abrem ok -> suspeitar do **profile do usuário no PROFMGR** antes de investigar ON, LIB ou patch.
- Diagnóstico via `console_wsrest` do AppServer: achar `THREAD ERROR` (a mensagem do erro está 2 linhas abaixo); correlacionar tid × usuário com a msg `TOTVSLICENSESERVER_GETLICENSE` (regex do `userId` ANTES do regex do tid — `$Matches` é sobrescrito); cada falha é logada **2×** (44 linhas = 22 falhas).
- Erro secundário no mesmo log (usuário 000097, não tratado): `variable is not array` em `MaFisRet` (MATXFIS.PRX:2516) chamado de `PurchaseOrderSmartViewBusinessObjectBRA:ProcessData:111` no getdata — array fiscal MaFis não inicializado no contexto REST; se voltar a ocorrer, investigar ausência de `MaFisIni`.
- `SC7TREP.tlpp` (ON custom "Pedido Compra") não participa deste fluxo; não confundir com o relatório padrão TOTVS.

[[smartview]] [[sc7trep]] [[perfil-usuario]]
