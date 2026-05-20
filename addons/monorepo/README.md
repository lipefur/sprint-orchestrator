# Addon: monorepo

## Quando ativar

Repositório monorepo com múltiplos pacotes/apps compartilhando dependências (bun/pnpm/yarn workspaces, Nx, Turborepo, Lerna).

## Dependências

Nenhuma.

## Detecção automática

- Campo `workspaces` em `package.json`
- Arquivos `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`

## Overrides

```yaml
monorepo:
  workspaces_root: .         # raiz do monorepo (default: repo root)
```
