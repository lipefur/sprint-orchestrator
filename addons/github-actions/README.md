# Addon: github-actions

## Quando ativar

CI/CD via GitHub Actions. Workflows em `.github/workflows/*.yml`.

## Dependências

Nenhuma.

## Detecção automática

- Diretório `.github/workflows/` com arquivos `.yml`

## Overrides

```yaml
github-actions:
  smoke_workflow: smoke-e2e.yml          # workflow que roda smoke em PR
  preview_validation: true               # ativa preview-deploy + Playwright auto (ver preview-validation/)
  preview_platform: vercel               # vercel | fly | railway | coolify | generic
```

## Subsystems

- **`preview-validation/`** — preview deploy automático + Playwright contra preview URL + PR comment estruturado. Mata o "scheduled task polling". Ver `preview-validation/README.md`.
