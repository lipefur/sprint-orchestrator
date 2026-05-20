# Conventional Commits + Semantic Release

## Por que importam

Com `semantic-release` configurado, commits em main geram automaticamente:

- Tags semver (v0.5.0, v0.5.1)
- CHANGELOG.md
- GitHub Releases
- Docker images com tag

Pra funcionar, **toda mensagem de commit precisa seguir convenção**.

## Formato

```
<type>(<scope>): <subject>

[body opcional]

[footer opcional: BREAKING CHANGE / Closes #N / Co-Authored-By]
```

## Types

| Type | Quando | Bump |
|---|---|---|
| `feat` | Nova funcionalidade visível | minor (0.4 → 0.5) |
| `fix` | Bug fix | patch (0.4.0 → 0.4.1) |
| `feat!` / `BREAKING CHANGE:` no body | Mudança incompatível | major (0.4 → 1.0) |
| `docs` | Só docs | nenhum |
| `chore` | Manutenção (deps, configs) | nenhum |
| `refactor` | Refactor sem mudar comportamento | nenhum |
| `test` | Add/melhorar testes | nenhum |
| `perf` | Otimização | patch |
| `style` | Formatação, lint | nenhum |
| `build` | Build system, Dockerfile | nenhum |
| `ci` | CI/workflows | nenhum |

## Scopes

Scopes são project-specific. Mantenha a lista pequena (<10) pra não virar bikeshed:

- Por service/app: `auth`, `dashboard`, `api`
- Por package/lib: `billing`, `license`
- Por infra: `compose`, `ci`, `docker`
- Por sprint: `sprint-N`

## Subject rules

- Imperativo presente: "add", "fix", "remove" (não "added"/"fixes")
- Letra minúscula (exceto nomes próprios)
- Sem ponto final
- Máximo ~80 chars

## Body rules

- Linha em branco entre subject e body
- Explica o "por quê" (não só o "o quê")
- Causa raiz se for bugfix
- Sem limite de linha

## Footer

```
Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>

BREAKING CHANGE: API endpoint /api/v1/X removed. Use /api/v2/X.

Closes #42
Fixes #43, #44
```

## Merge strategy

Padrão recomendado: **merge commit** (não squash) pra preservar history dos sprints. Configure via política do time ou GitHub branch protection.

Sprint chat: cada commit individual segue convencional. PR title: `feat(sprint-N): tema curto`. Orchestrator merge: merge commit aparece em `git log --oneline main`. CI `release.yml` em main: semantic-release lê commits desde última tag, gera nova tag + CHANGELOG + Release.
