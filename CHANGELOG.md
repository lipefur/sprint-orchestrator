# CHANGELOG

Registro de mudanças da skill `sprint-orchestrator`.

Formato baseado em [Keep a Changelog](https://keepachangelog.com/).
Versionamento segue [SemVer](https://semver.org/).

## [Unreleased] — Fase 2 (workflows avançados)

### Added — 3 workflows novos

**1. Adversarial Review (`core/adversarial-review.md`)**

- 3º Claude reviewer isolado é dispatchado quando sprint chat abre PR
- Tem prompt explícito de "encontrar problemas que o implementer perdeu"
- Posta comments via `gh pr review`
- Humano vira arbitrador, não reviewer linha-por-linha
- Configurável via `profile.adversarial_review.{enabled, skip_types, reviewer_model, max_comments}`
- Suporte futuro pra N-Claude consensus em sprints críticos

**2. Preview Deploy + Auto-Validation (`addons/github-actions/preview-validation/`)**

- GitHub Action workflows pra Vercel, Fly, Railway, Coolify, generic
- Quando PR abre: deploy preview → Playwright contra preview URL → PR comment estruturado
- Formato de comment fixo (`<!-- SPRINT-ORCHESTRATOR-AUTO-VALIDATION-START -->`) que orquestrador parseia
- Aplica labels `auto-validated` / `needs-fix` / `validation-error`
- **Mata o polling de PR via scheduled task** — orquestrador acorda via GitHub notification
- Setup detalhado por plataforma em `setup.md`

**3. Capture Learnings (`checklists/capture-learnings.md`)**

- Após cada sprint mergeado + deployed, orquestrador triagia commits `fix:` do sprint
- Pra cada bug fixado: avalia se é reusable pattern (stack-specific ou cross-cutting)
- Propõe adição assistida em `addons/<X>/bug-patterns.md` ou `core/anti-patterns.md`
- Loop de auto-melhoria: skill evolui com uso real
- Integrado no checklist `deploy-prod.md` passo 10

### Changed

- `checklists/post-pr-review.md`: novo passo 0 (adversarial review) antes da revisão manual
- `checklists/deploy-prod.md`: novo passo 10 (capture learnings)
- `SKILL.md`: nova seção "Workflows avançados (opcionais)"
- Profile schema: blocos `adversarial_review` e `github-actions.preview_validation` adicionados

## [Unreleased] — Fase 1.2 (slim + agnóstico real)

### Removed
- **Zero referências SuperDB-específicas** nos arquivos de execução (`SKILL.md`, `core/`, `addons/`, `checklists/`, `templates/`, `scripts/`). Refs históricas permanecem só em `README.md`, `CHANGELOG.md` e `examples/superdb-profile.yml`.
- `checklists/deploy-prod.md` não tem mais comandos hardcoded de SSH/Coolify/host alias — agora delega a addons específicos
- `checklists/pre-dispatch.md` reescrito com checks addon-aware (sem referenciar `auth_global`, `proj_management`, `docs/landing/`)

### Changed
- **SKILL.md cortado de 152 → 126 linhas** — removida seção "Setup em projeto novo" (já está no README, não precisa carregar no contexto)
- **`core/` cortado de 683 → 451 linhas (-34%)**:
  - `content-filter-workarounds.md` movido pra `addons/legalese/content-filter.md` (carrega só quando addon ativo, não sempre)
  - `multi-agent-strategy.md` enxugado (~30 linhas removidas, mesmo conteúdo)
  - `conventional-commits.md` enxugado (~50 linhas, exemplos redundantes removidos)
- **9 addon placeholders cortados pela metade** — removida meta-info "Conteúdo previsto pra Fase 2" e "Exemplos de projetos que usariam" (não ajudam Claude a executar). Restam só: quando ativar, dependências, detecção, overrides.
- **e2e-validation consolidado**: `chrome-devtools-debug.md` + `chrome-extension-auth.md` → `alternative-tools.md` único
- `templates/memory-completion.md` e `templates/memory-deploy.md` generalizados (paths agora via `{profile.paths.memory}`)

### Added
- **Addon `legalese/`** — `content-filter.md` carregado sob demanda quando sprint vai gerar texto legal canônico (LICENSE/Code of Conduct extenso)

### Impact
- Contexto **sempre carregado** (SKILL.md + core/): 835 → **577 linhas (-31%)**
- Caso típico (profile com 5 addons + 1 template + 1 checklist): ~1155 → **~857 linhas (-26%)**

## [Unreleased] — Fase 1.1 (multi-IDE)

### Added
- **Auto-detecção de ambiente** em `scripts/create-worktree.sh` — identifica Claude Code standalone, Cursor, VS Code, Antigravity, Windsurf e adapta o dispatch
- 4 novos métodos de dispatch: `cursor`, `vscode`, `antigravity`, `windsurf`
- `dispatch.method: auto` agora é o default (recomendado)
- `copy_to_clipboard()` helper com suporte a `pbcopy` (Mac), `xclip`/`wl-copy` (Linux), `clip.exe` (WSL)
- Cada ambiente recebe instruções específicas pós-dispatch (qual atalho usar pra nova chat)

### Changed
- `dispatch.method` default mudou de `claude-cli` pra `auto`
- `init.sh` lista 8 opções de dispatch em vez de 3

## [Unreleased] — Fase 1 do redesign

### Added
- Estrutura modular `core/` + `addons/`
- 10 addons: postgres, multi-tenant, monorepo, nextjs, coolify-ssh, github-actions, nginx, docs-public, hono (placeholders), e2e-validation (completo)
- Schema do `.sprint-orchestrator.yml` versão 1
- `scripts/init.sh` — auto-discovery do perfil do projeto
- `scripts/create-worktree.sh` evoluído — lê profile + URL scheme `claude-cli://` dispatch
- `templates/plan/` com 5 variantes (feature, bugfix, refactor, migration, infra)
- `templates/prompt-dispatch.md` agnóstico
- Documentação do `.sprint-orchestrator/state.md` + scheduled task pattern em `core/workflow.md`
- README.md MIT-licensed pra OSS
- `examples/superdb-profile.yml`

### Changed
- `SKILL.md` reescrito como entry point agnóstico (lê profile + ativa addons)
- `templates/plan.md` (genérico) substituído por subpasta `templates/plan/` com variantes por tipo

### Removed
- Refs hardcoded ao SuperDB no `core/` (paths `docs/superpowers/`, Coolify, Bun, schemas `auth_global`, etc.)

### Migration notes
- Skill antiga preservada em `_legacy/` durante migração
- Projetos consumidores precisam rodar `scripts/init.sh` pra gerar `.sprint-orchestrator.yml`
- Profile sem `version: 1` é rejeitado pelo parser

---

## Profile schema versions

### v1 (atual)

Estrutura inicial. Keys obrigatórias: `version`, `project_name`.

```yaml
version: 1
project_name: string
default_branch: main

paths:
  plans: docs/superpowers/plans
  worktrees: .claude/worktrees
  memory: <path>

smoke:
  local: <command>
  ci_workflow: <filename>

git:
  worktree_prefix: sprint
  pr_title_prefix: "feat(sprint-N):"
  conventional_commits: true
  semantic_release: false

dispatch:
  method: auto         # auto | claude-cli | claude-desktop |
                       # cursor | vscode | antigravity | windsurf | clipboard-only

addons: [<addon-name>, ...]

notifications:
  github_assignee: <username>
  github_label: <label>
  macos: bool
  webhook: <url>
  email: <address>

# Overrides por addon (opcional)
<addon-name>:
  <key>: <value>
```

Defaults sensatos pra tudo exceto `version` e `project_name`.

### v2 (planejado)

Mudanças previstas pra Fase 2/3 do redesign — sujeito a alteração.

Breaking changes serão documentadas aqui antes de release.
