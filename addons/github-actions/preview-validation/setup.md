# Setup — Preview Validation por plataforma

Passos detalhados pra ativar o workflow.

## Geral (todas plataformas)

### 1. Copia o workflow

```bash
mkdir -p .github/workflows
cp <skill>/addons/github-actions/preview-validation/<plataforma>.yml \
   .github/workflows/sprint-preview-validation.yml
```

### 2. Ajusta secrets do GitHub

Settings → Secrets and variables → Actions → New repository secret.

Secrets por plataforma listados abaixo.

### 3. Adiciona ao profile

```yaml
addons: [..., github-actions]
github-actions:
  preview_validation: true
  preview_platform: vercel   # ou fly, railway, coolify, generic
```

### 4. Configura labels no repo

Cria 3 labels no GitHub:

- `auto-validated` (verde)
- `needs-fix` (vermelho)
- `validation-error` (laranja)

(Opcional — o workflow cria se não existir, mas pré-criar dá cor consistente.)

### 5. Configura branch protection (recomendado)

Branch `main`: requer status check `Sprint Preview Validation` passar antes de merge.
Settings → Branches → Branch protection → main → Require status checks.

---

## Vercel

**Custo do preview**: included no plano (Hobby/Pro tem preview deploys ilimitados).

### Secrets

- `VERCEL_TOKEN` — gera em vercel.com/account/tokens
- `VERCEL_PROJECT_ID` — visível em Project Settings
- `VERCEL_ORG_ID` — visível em Account Settings

### Particularidades

- Vercel cria preview deploy automaticamente em cada push. Workflow só **espera** ficar pronto.
- `BASE_URL` = `https://<project>-<hash>-<org>.vercel.app` (capturado via action `wait-for-vercel-preview`)

---

## Fly.io

**Custo do preview**: cada preview = uma app extra. Pode acumular se PRs ficarem abertos.

### Secrets

- `FLY_API_TOKEN` — `flyctl auth token`

### Particularidades

- Você precisa **deletar a app preview** após merge ou após X dias. Adiciona um job de cleanup:

```yaml
on:
  pull_request:
    types: [closed]
jobs:
  cleanup:
    if: startsWith(github.head_ref, 'sprint-')
    runs-on: ubuntu-latest
    steps:
      - name: Delete preview app
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
        run: flyctl apps destroy my-app-pr-${{ github.event.pull_request.number }} --yes
```

### Workflow snippet (substituir no `generic.yml`)

```yaml
- name: Deploy preview to Fly
  id: deploy-preview
  env:
    FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
  run: |
    APP="my-app-pr-${{ github.event.pull_request.number }}"
    flyctl deploy --app "$APP" --remote-only
    echo "url=https://$APP.fly.dev" >> $GITHUB_OUTPUT
```

---

## Railway

**Custo do preview**: included se PR Environments habilitado.

### Secrets

- `RAILWAY_TOKEN` — railway.app/account/tokens

### Particularidades

- Habilita "PR Environments" no projeto: Settings → Environments → Enable.
- Railway cria preview deployment automaticamente. Workflow espera ficar pronto.

---

## Coolify

**Custo do preview**: self-hosted, custo é do seu VPS.

### Secrets

- `COOLIFY_TOKEN` — gera em Coolify UI → API
- `COOLIFY_API_BASE` — ex: `https://coolify.example.com`

### Particularidades

- Coolify suporta "Branch Deployments". Habilita na app config.
- Cada push em branch `sprint-*` cria deploy. URL = `https://<branch-slug>.preview.example.com` (dependendo da config).

### Workflow snippet

```yaml
- name: Trigger Coolify branch deploy
  env:
    TOKEN: ${{ secrets.COOLIFY_TOKEN }}
    BASE: ${{ secrets.COOLIFY_API_BASE }}
  run: |
    curl -X POST -H "Authorization: Bearer $TOKEN" \
      "$BASE/api/v1/deploy?branch=${{ github.head_ref }}"

- name: Wait for Coolify preview
  env:
    URL: https://${{ github.head_ref }}.preview.example.com
  run: |
    for i in {1..60}; do
      if curl -sf "$URL/" >/dev/null; then
        echo "url=$URL" >> $GITHUB_OUTPUT
        exit 0
      fi
      sleep 10
    done
    echo "❌ Preview did not become ready"
    exit 1
```

---

## Generic (sem PaaS)

Use quando você tem infra custom (AWS, GCP, Docker próprio, etc.). Customize o passo "Deploy preview" no `generic.yml` pra:

1. Build Docker image
2. Push pra registry
3. `kubectl apply` ou `docker compose up` em servidor de preview
4. Output a URL

A skill não opina aqui — você define como sobe preview.

---

## Troubleshooting

### Preview deploy falha

- Verifica secret válido
- Verifica plataforma suporta a stack (Vercel não roda Python; Railway sim)
- Verifica logs do Action

### Playwright não acha o preview

- Health check passou? Se URL retorna 200 mas Playwright não acha elemento, é problema de timing
- Adiciona `wait_for` pré-test pra esperar app carregar JS

### Comment não aparece no PR

- `permissions: pull-requests: write` no workflow?
- Token tem permissão de escrever no PR?

### Multiple comments aparecem

- `peter-evans/find-comment` + `edit-mode: replace` deveria evitar
- Se acontece: o marker `SPRINT-ORCHESTRATOR-AUTO-VALIDATION-START` foi alterado entre runs?
