---
name: sprint-orchestrator
description: Use when the user wants to plan, dispatch, review or deploy software sprints in a multi-chat orchestration pattern. Skill provides a portable workflow with auto-discovery of project profile, modular addons (postgres, multi-tenant, nextjs, coolify-ssh, e2e-validation, etc), URL-scheme dispatch to new Claude Code sessions, and validated checklists from 17+ production sprints. Reads `.sprint-orchestrator.yml` from the consuming project.
---

# Sprint Orchestrator

Padrão portátil de orquestração de sprints de software validado em 17+ sprints reais. Separa estratégia (orquestrador) de execução (sprint chats) em chats diferentes pra evitar context bloat e maximizar paralelismo.

## Quando usar

- Usuário diz "próximo sprint", "novo sprint", "vamos pro sprint N — tema X"
- Usuário pede pra "orquestrar X em outro chat"
- Trabalho > 2 horas estimado, com escopo definível
- Há decisões batidas que podem ser cristalizadas em plano

## Quando NÃO usar

- Bug fix trivial (<30min) — fix direto, sem worktree
- Pergunta de discussão estratégica sem ação técnica — só responder
- Refactor cosmético — vai direto
- User ainda não bateu decisões críticas — faz brainstorming primeiro (use `superpowers:brainstorming`)

## Como esta skill é estruturada

```
sprint-orchestrator/
├── core/             # SEMPRE carregar (independente do projeto)
├── addons/           # carregar SOB DEMANDA (via profile.addons[])
├── templates/        # templates de plano, prompt, memory
├── checklists/       # pre-dispatch, post-pr-review, deploy-prod
├── scripts/          # init.sh, create-worktree.sh
└── examples/         # profiles de referência
```

## Setup (primeiro uso por projeto)

Se `.sprint-orchestrator.yml` não existe na raiz do repo: instrua o user a rodar `bash <skill>/scripts/init.sh`. Detalhes de instalação no `README.md`.

## Workflow nas 4 fases

Ver detalhes em `core/workflow.md`. Resumo:

1. **PLAN** — orchestrator brainstorma com user, escreve plano usando `templates/plan/<tipo>.md`, commita em main + push.
2. **DISPATCH** — orchestrator roda `scripts/create-worktree.sh N <tema>` que cria worktree + state.md + scheduled task + abre Claude Code novo via URL scheme.
3. **EXECUTE** — sprint chat (Claude novo) lê plano, executa, valida E2E (quando aplicável), abre PR, atualiza state.md.
4. **REVIEW+DEPLOY** — scheduled task detecta PR aberto, abre sessão nova do orchestrator que faz review + merge + deploy + state.md update.

## Ambientes suportados (multi-IDE)

A skill funciona em qualquer ambiente onde Claude esteja disponível. O dispatch da Fase 2 (abrir novo sprint chat) auto-detecta o IDE/terminal atual e adapta:

| Ambiente | Como o dispatch funciona |
|---|---|
| **Claude Code standalone** (Terminal/iTerm) | URL scheme `claude-cli://` abre nova janela com prompt já rodando |
| **Cursor** | Abre worktree em nova janela Cursor + copia prompt → você dá ⌘L (nova chat) + cola |
| **VS Code** + Claude extension | Abre worktree em VS Code + copia prompt → comando "Claude: New Chat" + cola |
| **Antigravity** (Google) | Copia prompt + instrução pra abrir nova aba com working dir setado |
| **Windsurf** (Codeium) | Abre worktree em Windsurf + copia prompt → nova Cascade chat + cola |
| **Outros** | Clipboard puro + arquivo temporário com prompt + instruções genéricas |

Pra forçar um método específico, define `dispatch.method` no profile. Default `auto` detecta sozinho via env vars (`TERM_PROGRAM`, `CURSOR_TRACE_ID`, `VSCODE_PID`, etc.) e process tree.

## Como ler esta skill (pra Claude)

Quando o user invocar esta skill:

1. **Leia `.sprint-orchestrator.yml` do projeto consumidor.**
   - Se não existe: ofereça rodar `scripts/init.sh` antes de continuar.
2. **Sempre carregue todo `core/`** (workflow, multi-agent-strategy, conventional-commits, anti-patterns, adversarial-review).
3. **Para cada `addon` listado em `profile.addons[]`:** leia `addons/<nome>/README.md` agora; leia outros arquivos do addon **just-in-time** quando a fase relevante chegar.
4. **Use templates do `templates/plan/<tipo>.md`** quando user pedir plano novo (default: `feature.md`).
5. **Use `templates/prompt-dispatch.md`** quando for hora de dispatch.
6. **Consulte `checklists/`** ao iniciar cada fase (pre-dispatch, post-pr-review, deploy-prod, capture-learnings).

## Workflows avançados (opcionais)

- **Adversarial review** (`core/adversarial-review.md`) — 3º Claude isolado revisa PR adversarialmente, posta comments. Você vira arbitrador, não reviewer. Ativa via `profile.adversarial_review.enabled: true`.
- **Preview deploy + auto-validation** (`addons/github-actions/preview-validation/`) — quando PR abre, GitHub Action faz preview deploy + Playwright contra URL preview + posta PR comment estruturado. Mata o polling do "PR aberto?". Ativa via `profile.github-actions.preview_validation: true`.
- **Capture learnings** (`checklists/capture-learnings.md`) — após cada deploy, orquestrador triagia bugs fixados durante sprint e propõe adição às `addons/<X>/bug-patterns.md`. Loop de auto-melhoria da skill.
- **Visual dashboard** (`scripts/dashboard/`) — kanban board local renderizado a partir do `state.md`. Modos: estático / live server (`--serve`) / multi-project workspace (`--workspace`). Roda 100% local, zero tokens Claude. Invoque com `bash <skill>/scripts/dashboard.sh`.

## Profile schema (resumo)

Arquivo `.sprint-orchestrator.yml` na raiz do projeto consumidor. Schema versionado (atual: v1). Ver `CHANGELOG.md` pra mudanças de versão.

```yaml
version: 1
project_name: string            # obrigatório
default_branch: main

paths:
  plans: docs/superpowers/plans
  worktrees: .claude/worktrees
  memory: ~/.claude/projects/<hash>/memory

smoke:
  local: bin/smoke-local.sh     # opcional
  ci_workflow: smoke-e2e.yml    # opcional

git:
  worktree_prefix: sprint
  pr_title_prefix: "feat(sprint-N):"
  conventional_commits: true
  semantic_release: false

dispatch:
  method: auto                  # auto (detect IDE) | claude-cli | claude-desktop |
                                # cursor | vscode | antigravity | windsurf | clipboard-only

addons: [postgres, nextjs, e2e-validation, github-actions]

notifications:                   # opt-in
  github_assignee: null
  github_label: ready-for-review
  macos: false
  webhook: null
  email: null

# Workflows avançados (opt-in)
adversarial_review:
  enabled: true                  # 3º Claude reviewer adversarial pré-merge
  skip_types: [infra]            # tipos de sprint que pulam
  reviewer_model: sonnet         # ou opus pra sprints críticos
  max_comments: 8

github-actions:
  preview_validation: true       # GitHub Action faz preview deploy + Playwright
  preview_platform: vercel       # vercel | fly | railway | coolify | generic

# Overrides por addon (todos opcionais)
postgres:
  service_role: platform_admin
```

Defaults sensatos pra tudo exceto `version` e `project_name`. Ver `examples/` pra perfis de referência completos.

## Anti-padrões críticos

Ver `core/anti-patterns.md` pra lista cross-cutting + `addons/<nome>/bug-patterns.md` pra stack-specific.

## OSS

Esta skill é open-source MIT licensed. Veja `README.md` pra instalação em projeto novo, ou `examples/` pra perfis de referência.
