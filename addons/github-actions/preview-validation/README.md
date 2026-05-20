# Preview Deploy + Auto-Validation

Quando sprint chat abre PR, um GitHub Action customizado:

1. **Spinns up preview deploy** na sua plataforma (Vercel/Fly/Railway/Coolify)
2. **Roda Playwright contra a URL preview** (não localhost, não staging — preview real)
3. **Posta resultado como PR comment estruturado** com screenshots + logs
4. **Aplica label** (`auto-validated` ou `needs-fix`)

**Resultado:** orquestrador acorda via **GitHub notification** (label/comment trigger), não via polling. Mata o "scheduled task a cada 30min".

## Por que isso é diferente

| Antes | Depois |
|---|---|
| Sprint chat abre PR → você precisa lembrar de checar | PR abre → preview deploy → Playwright → comment automático |
| Você roda Playwright local antes de mergear | Playwright já rodou contra **preview deploy real** |
| Smoke prod só depois do merge | Smoke contra preview = pega bug **antes** do merge |
| "PR aberto, vou ver mais tarde" | Notification do GitHub com PASS/FAIL no celular |

## Pré-requisitos

- Repo em GitHub com Actions habilitado
- Plataforma de deploy que oferece **preview deploys por PR**:
  - **Vercel**: automático (preview deploys nativos)
  - **Fly.io**: requer `fly deploy --app preview-<sha>` ou GitHub Action oficial
  - **Railway**: preview environments habilitados no projeto
  - **Coolify**: branch deployments configurados
  - **Render**: preview environments habilitados
- Playwright MCP disponível **OU** Playwright instalado como dep do projeto
- Secrets configurados no GitHub repo:
  - `<PLATFORM>_TOKEN` (ex: `VERCEL_TOKEN`, `FLY_API_TOKEN`, `RAILWAY_TOKEN`)
  - `<PLATFORM>_PROJECT_ID` se aplicável

## Workflows fornecidos

Cada plataforma tem template próprio. Copie pra `.github/workflows/` do seu projeto, ajuste secrets:

- `vercel.yml` — apps Next.js/Vite em Vercel
- `fly.yml` — apps com Fly.io
- `railway.yml` — apps Railway
- `coolify.yml` — apps self-hosted Coolify
- `generic.yml` — qualquer URL pública (você define como sobe preview)

Veja `setup.md` pra setup detalhado por plataforma.

## Como o orquestrador detecta

Após o workflow rodar:

```bash
# Orquestrador (ou scheduled task simplificado) checa:
gh pr list --label "auto-validated" --state open       # PRs prontos pra review humano
gh pr list --label "needs-fix" --state open            # PRs com falhas detectadas
```

OU subscreve aos comments:

```bash
gh api repos/:owner/:repo/issues/comments?since=...    # lista comments recentes
```

Ainda melhor: o GitHub Action posta um comment com **estrutura conhecida** que orquestrador parseia:

```markdown
<!-- SPRINT-ORCHESTRATOR-AUTO-VALIDATION -->
## Auto-Validation Result

**Preview URL:** https://my-app-pr-42.vercel.app
**Status:** ✅ PASS / ❌ FAIL

### Playwright results

- ✅ Golden path (12.3s)
- ✅ Edge case 1: senha errada (3.1s)
- ❌ Edge case 2: criar projeto duplicado
  - Expected: error message visible
  - Actual: 500 Internal Server Error
  - [Screenshot](./screenshots/edge-case-2.png)

### Console errors

```
Uncaught TypeError: Cannot read property 'id' of undefined
  at Dashboard.tsx:42
```

### Network errors

- POST /api/projects → 500

[Full logs](./logs.txt)
```

Orquestrador faz `gh pr view --comments`, encontra esse bloco delimitado, parseia, decide próxima ação.

## Vantagens vs scheduled task polling

| Polling (Fase 2 original) | Preview validation (este addon) |
|---|---|
| Roda a cada 30min — custa tokens | Roda 1x por PR — barato |
| Só detecta que PR foi aberto | Já valida funcionalmente |
| Você ainda precisa rodar Playwright | Playwright já rodou |
| Trigger pra orchestrator: descoberta passiva | Trigger: comment estruturado + label |

## Limites

- Plataforma precisa suportar preview deploys (~80% dos PaaS modernos sim)
- Playwright suite precisa rodar em <10min (limite prático do Action)
- Custos: cada PR vira um preview deploy = $ na plataforma. Em projetos grandes pode acumular. Solução: workflow só dispara em PRs com label específica ou em branches `sprint-*`.

## Próximos passos pós-instalação

1. Copia o workflow apropriado pra `.github/workflows/`
2. Configura secrets no repo (Settings → Secrets and variables → Actions)
3. Adiciona `addons/github-actions/preview-validation/` ao seu `.sprint-orchestrator.yml`:
   ```yaml
   addons: [..., github-actions]
   github-actions:
     preview_validation: true
     preview_platform: vercel    # vercel | fly | railway | coolify | generic
   ```
4. Sprint chat futuro: ao abrir PR, workflow dispara automaticamente
5. Orquestrador: aprende a parsear o comment estruturado (ver `comment-format.md`)
