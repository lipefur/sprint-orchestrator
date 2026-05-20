# Addon: nextjs

## Quando ativar

App Next.js (qualquer versão 13+). Server Components, App Router, SSR, ISR.

## Dependências

Nenhuma. Ativa automaticamente `e2e-validation`.

## Detecção automática

- Arquivo `next.config.{js,mjs,ts}`
- Dependência `next` em `package.json`
- Diretórios `app/` ou `pages/`

## Overrides

```yaml
nextjs:
  apps: [apps/dashboard]     # onde apps Next.js vivem (apenas em monorepo)
```
