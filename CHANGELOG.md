# CHANGELOG

Registro de mudanças da skill `sprint-orchestrator`.

Formato baseado em [Keep a Changelog](https://keepachangelog.com/).
Versionamento segue [SemVer](https://semver.org/).

## [v1.2.3] — Gate de evidência de validação prod

### Added

- **`fase=DONE` agora exige evidência de validação prod no `state.md`.** Operacionaliza o anti-pattern #10: quando o sprint mexeu em UI (ou `e2e-validation` ativo), o orquestrador não fecha o sprint sem registrar no `state.md` a URL prod **navegada** + o que foi checado (login/render/console) + PASS/FAIL — ou o **motivo explícito** se foi pulado (gap conhecido, não suposição). `curl`/preview não fecham o gate. Reforçado em `checklists/deploy-prod.md` (§8), no schema do `state.md` (`core/workflow.md`) e no template `memory-deploy.md` (§6 distingue liveness `curl` vs navegado Playwright).

## [v1.2.2] — Hardening da validação de prod

### Changed

- **Validação de prod não aceita mais atalho local/preview.** Novo anti-pattern #10 (`core/anti-patterns.md`): dev server local, preview deploy (`github-actions/preview-validation`) e `curl` validam a fase EXECUTE/REVIEW (mudança num ambiente efêmero / liveness) — **nunca** a fase DEPLOY. A fase DEPLOY só fecha com Playwright **navegado contra a URL de produção** (login real + render + console). Reforçado em `addons/e2e-validation/README.md`, `checklists/deploy-prod.md` (§6) e `core/workflow.md` (Fase 4).

## [v1.2.1] — Dispatch reliability fix

### Fixed

- **Dispatch do split mode nunca mais falha silenciosamente.** `dispatch_via_claude_cli` / `dispatch_via_claude_desktop` (`create-worktree.sh`) confiavam no exit code de `open <url>` — mas no macOS o `open` retorna sucesso (0) mesmo quando o handler do URL scheme não faz nada (app não registrado, sessão headless/SSH, prompt longo demais). O script anunciava "🚀 Opened" sem nenhum chat ter aberto, deixando o usuário sem o prompt. Agora o prompt é **sempre** salvo em arquivo + copiado pro clipboard primeiro (a garantia), o URL scheme é tentado só como best-effort, e a mensagem é honesta: _"se nenhum chat abriu, cola o prompt acima"_. Removido o guard `≤1800 chars` que pulava a tentativa de `open` pra qualquer prompt realista.

### Privacy

- Genericizados os nomes de schema de exemplo no addon `multi-tenant` (`auth_global`/`proj_management` → `shared_auth`/`shared_core`) — zero referência a qualquer projeto original.

## [v1.2.0] — Adaptive Mode

### Added

- **Modo monolithic** — orquestrador + execução no mesmo chat, aproveitando 1M context (Opus 4.6+/4.8). Worktree mantido, subagents só pra áreas disjuntas.
- **Profile `model:` block** — `context_window: 1m|200k` + `mode: auto|monolithic|split`
- **Heurística de decisão de modo** na fase PLAN (auto: 200k→split, 1m→monolithic pra pequeno/médio, split pra épico). Anuncia + aceita veto.
- **Addon `full-context`** — carrega repo filtrado no contexto quando 1m (filtros + limite ~500k tokens, cai pra incremental se grande)
- `init.sh` pergunta context window e salva no profile
- `create-worktree.sh` ramifica dispatch por modo (monolithic = cd no mesmo chat; split = URL scheme atual) + escreve modo no state.md

### Changed

- **Pitch rebalanceado** (README + workflow.md): paralelismo + isolation + memória institucional como benefícios principais; context bloat passa a ser 1 benefício (relevante só em 200k), não O motivo
- `core/multi-agent-strategy.md`: "agents" = subagents (monolithic) ou chats (split)

### Fixed

- `read_profile_key` (create-worktree.sh): grep sem match retornava exit 1 sob `set -e/pipefail`, matando o script. Agora retorna vazio — necessário pra backward compat (profile sem `model:`). Também strippa comentários inline YAML (`# ...`).

### Backward compatibility

- Profile antigo sem `model:` → assume 200k + split = **comportamento idêntico ao atual**. Quem usa Sonnet/Foundry/200k não vê diferença.

### Cut (YAGNI)

- Memory nativa (carregar todas memories) — apenas relaxada a parcimônia, sem feature
- `reasoning_effort` por tipo de sprint — 4.8 calibra sozinho

## [Unreleased]

### Added — Sprint completion report template

- **New file**: `templates/sprint-completion-report.md` — copy-paste-ready template the sprint chat fills in and pastes to the orchestrator chat at the end of execution
- Fixed structure with explicit fields: Status, Identificação, O que foi entregue, Validação, Stats, Decisões durante sprint, Bugs encontrados, Pendências orquestrador, **Próximo passo claro** (one of 5 enums)
- Includes a "variation curta" for trivial sprints
- **`templates/prompt-dispatch.md`** updated: sprint chat is now instructed to use this template at end of execution
- **`checklists/post-pr-review.md`** updated: orchestrator parses the report's `Próximo passo claro` to decide immediate action

Reasoning: previously the "final message from sprint chat" was a bullet list in `prompt-dispatch.md`. Each sprint chat would produce something slightly different. With a fixed template, the orchestrator can parse mechanically and decide action without re-reading the conversation.

### Added — Deploy duplication bug pattern

Real production case captured: deploy platform queued 2-4 deploys for a single PR merge due to overlapping triggers (webhook + semantic-release auto-commit + manual API call).

- **New file**: `addons/coolify-ssh/bug-patterns.md` documents the Coolify-specific case with 3 fix strategies (manual-only / webhook-only / path-filter)
- **`core/anti-patterns.md` #9**: cross-cutting version of the same pattern (applies to any platform with webhook + release tool + API: Vercel, Fly, Railway, Render, etc.)
- **`checklists/deploy-prod.md`** step 4 gained a `⚠️` callout linking to both, and a new check item: "Apenas 1 deploy foi enfileirado"
- **`addons/coolify-ssh/README.md`** gained a "Bug patterns conhecidos" section linking to the new file

### Why this matters

This is the first real "captured learning" since v1.1.0 — exactly the kind of contribution the [`checklists/capture-learnings.md`](checklists/capture-learnings.md) workflow exists to harvest. Pattern is reusable across stacks: any team running semantic-release + auto-deploy webhook + scripted deploy will hit this.

## [Unreleased] — v1.1.0 (visual dashboard)

### Added

- **`scripts/dashboard.sh`** — local kanban dashboard with 3 modes:
  - Static HTML (default): generates `$TMPDIR/sprint-orchestrator-dashboard.html` and opens in browser
  - `--serve`: local web server on `http://localhost:8765` with live updates via Server-Sent Events (state.md file watcher)
  - `--workspace`: multi-project mode reading `~/.config/sprint-orchestrator/workspace.yml`
- **`scripts/dashboard/template.html`** — vanilla HTML/CSS dark-theme kanban (4 columns: Planning/In Progress/Review/Done) with color-coding per phase
- **`scripts/dashboard/server.py`** — Python stdlib-only HTTP server with SSE for live updates (no pip installs needed)
- **`scripts/dashboard/README.md`** — usage docs for the dashboard

### Key property

Dashboard runs **100% locally** — bash + Python stdlib + browser. **Zero Claude token consumption.** Doesn't read or write `.sprint-orchestrator/state.md` except to parse it (read-only).

### Mentioned in

- SKILL.md: new bullet in "Workflows avançados" section
- All 3 READMEs: new "📊 Visual dashboard" subsection
- `scripts/dashboard/README.md` has full reference

## [Unreleased] — v1.0.3 (anonymized example profile)

### Security / Privacy

- **Removed real hostnames and URLs** from `examples/`. The original example file leaked a live admin panel URL of a production project — replaced with `https://coolify.example.com` placeholder.
- **Renamed** original example file → `examples/multi-tenant-saas-profile.yml`
- Project name in example: real name → `acme-saas`
- SSH alias in example: real alias → `production-vps`
- GitHub username in example: hardcoded user → `<your-github-username>` placeholder
- Removed link to the original private project repo from all 3 READMEs and FAQ
- Removed marketing-style attribution that pointed to a live private repo

### Added

- `CONTRIBUTING.md` now explicitly forbids real hostnames/usernames in example profiles
- PR template checklist updated to enforce the rule

### Rationale

Even meta-information (hostname of an admin panel, internal schema names) reduces "security through obscurity" — a legitimate defense layer for self-hosted infra. The skill demonstrates patterns; it doesn't need to point at any specific live production instance.

## [Unreleased] — v1.0.2 (Portuguese as primary)

### Changed

- **Portuguese is now the primary README** (project author's native language)
  - `README.md` → Portuguese (was English)
  - `README.en.md` → English (was `README.md`)
  - `README.es.md` → unchanged
- Cross-language switcher in all 3 READMEs updated: `[Português](README.md) · [English](README.en.md) · [Español](README.es.md)`
- `docs/faq.md` link updated to point to `README.en.md` for English readers

### Rationale

GitHub renders `README.md` by default. Putting Portuguese there reflects the project's origin (Brazilian dev community) without losing English/Spanish accessibility (one click away from the language switcher).

## [Unreleased] — v1.0.1 (installer)

### Added

- **`install.sh`** — one-liner installer at repo root. Commands: `install` (default), `update`, `uninstall`. Checks dependencies (`git`, `bash`, `gh`, `yq`, `python3`), warns about optional missing ones, supports `SPRINT_ORCHESTRATOR_DIR` env var override.
- One-liner now published in 3 README languages: `curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash`

### Changed

- Tutorial updated with 3 install methods (one-liner, review-first, direct clone)
- READMEs Quickstart section reordered: one-liner first, manual fallback second

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
- **Zero referências ao projeto original** nos arquivos de execução (`SKILL.md`, `core/`, `addons/`, `checklists/`, `templates/`, `scripts/`). Skill agora é totalmente agnóstica.
- `checklists/deploy-prod.md` não tem mais comandos hardcoded de SSH/Coolify/host alias — agora delega a addons específicos
- `checklists/pre-dispatch.md` reescrito com checks addon-aware (sem referenciar paths ou schemas específicos de nenhum projeto)

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
- `examples/multi-tenant-saas-profile.yml` (anonymized reference profile)

### Changed
- `SKILL.md` reescrito como entry point agnóstico (lê profile + ativa addons)
- `templates/plan.md` (genérico) substituído por subpasta `templates/plan/` com variantes por tipo

### Removed
- Refs hardcoded ao projeto original no `core/` (paths específicos, Coolify, Bun, schemas internos, etc.)

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
