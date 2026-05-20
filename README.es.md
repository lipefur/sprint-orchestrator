# sprint-orchestrator

> Skill portátil de orquestación multi-chat para Claude Code. Validada en 17+ sprints de producción.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-active-success.svg)](#estado)
[![Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-orange.svg)](https://claude.com/claude-code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Discussions](https://img.shields.io/badge/💬-Discussions-blueviolet)](https://github.com/lipefur/sprint-orchestrator/discussions)

**🌍 Idiomas:** [English](README.md) · [Português](README.pt-BR.md) · [Español](README.es.md)
**📚 Docs:** [Tutorial](docs/tutorial-getting-started.md) · [FAQ](docs/faq.md) · [Recipes](docs/recipes/)

---

## Qué es

Una skill que enseña a Claude Code a orquestar sprints de software entre **múltiples chats**:

- Un **chat orquestador** donde haces brainstorming, planeas, revisas y mergeas
- Uno o más **chats de sprint** instanciados por sprint, ejecutando el plan en paralelo

Este patrón evita el context bloat en chats largos y habilita paralelismo real vía multi-agent dispatch.

## Por qué existe

Los chats largos de Claude olvidan contexto. Un chat único para "construir feature X" termina:

- Olvidando decisiones tomadas al inicio
- Serializando trabajo que podría correr en paralelo
- Mezclando brainstorming con implementación
- Perdiendo lecciones de sprints anteriores

La skill separa el chat **estratégico** (tú + orquestador) de los chats de **ejecución** (Claude enfocado en un sprint a la vez), con estado persistente en `state.md` y anti-patterns aprendidos documentados por addon.

## Workflow general

```
┌─────────────────────────────────┐
│  CHAT ORQUESTADOR (te quedas)   │
│  • Brainstorming + plan         │
│  • Review + merge + deploy      │
└─────────────────────────────────┘
              ↓ dispatch vía URL scheme
┌─────────────────────────────────┐
│  CHAT DE SPRINT (Claude nuevo)  │
│  • Lee plan commiteado          │
│  • Multi-agent paralelo         │
│  • Abre PR (no mergea)          │
└─────────────────────────────────┘
              ↓ PR listo
       vuelve al orquestador
```

## Quickstart

### 1. Instala la skill globalmente

```bash
git clone https://github.com/lipefur/sprint-orchestrator.git ~/.claude/skills/sprint-orchestrator
```

### 2. Inicializa en tu proyecto

```bash
cd path/a/tu/proyecto
bash ~/.claude/skills/sprint-orchestrator/scripts/init.sh
```

El script va a:

- Inspeccionar tu repo (`package.json`, `docker-compose.yml`, `next.config.*`, `vercel.json`, `migrations/`, etc.)
- Detectar addons aplicables (`postgres`, `nextjs`, `monorepo`, etc.)
- Preguntar lo que no pudo inferir (deploy method, comando smoke)
- Escribir `.sprint-orchestrator.yml` en la raíz del repo

### 3. Empieza un sprint

En Claude Code, en el chat orquestador de tu proyecto:

> "Plan sprint 1 — implementar login con OAuth"

Claude hace brainstorming contigo, escribe el plan, commitea en main. Después:

```bash
bash ~/.claude/skills/sprint-orchestrator/scripts/create-worktree.sh 1 oauth-login
```

Esto abre una nueva ventana Claude Code vía URL scheme `claude-cli://`, ya corriendo en el worktree con el plan como prompt inicial.

### 4. Chat de sprint ejecuta, abre PR, actualiza `.sprint-orchestrator/state.md`

### 5. (Opcional) Workflows avanzados se activan:

- **Adversarial review** — 3er Claude revisa el PR adversarialmente
- **Preview validation** — GitHub Action hace deploy preview + corre Playwright
- **Capture learnings** — post-deploy, propone bug patterns para agregar a la skill

## Soporte multi-IDE

El script de dispatch detecta tu entorno automáticamente y se adapta:

| Entorno | Comportamiento del dispatch |
|---|---|
| **Claude Code standalone** (Terminal/iTerm) | URL scheme `claude-cli://` abre nueva ventana con prompt |
| **Cursor** | Abre worktree en Cursor + copia prompt → presiona ⌘L para nueva chat |
| **VS Code** + Claude extension | Abre worktree en VS Code + copia prompt → comando "Claude: New Chat" |
| **Antigravity** (Google) | Copia prompt + instrucción + working dir |
| **Windsurf** (Codeium) | Abre worktree en Windsurf + copia prompt → nueva Cascade chat |
| **Otros** | Clipboard puro + archivo temp con prompt |

Sobrescribe por proyecto vía `dispatch.method` en el profile.

## Cómo difiere de alternativas

| Enfoque | Trade-off |
|---|---|
| **Chat largo único** | Context bloat, sin paralelismo, sin memoria entre sprints |
| **`superpowers:executing-plans`** | Bueno para ejecutar plan conocido en una sesión; no orquesta flujo multi-sprint |
| **TODO list / Notion** | Sin anti-patterns aprendidos; sin automatización de dispatch + review |
| **Esta skill** | Workflow multi-chat, addon-modular, estado persistente, validado en producción |

## Arquitectura

```
sprint-orchestrator/
├── core/             # siempre cargado — workflow, multi-agent, conventional commits, anti-patterns, adversarial-review
├── addons/           # cargados bajo demanda vía profile
│   ├── postgres/
│   ├── nextjs/
│   ├── multi-tenant/
│   ├── monorepo/
│   ├── coolify-ssh/
│   ├── github-actions/    # incluye subsystem preview-validation/
│   ├── e2e-validation/    # Playwright + Chrome DevTools + Chrome extension
│   ├── legalese/          # workarounds de content filter para LICENSE/CoC
│   ├── hono/
│   ├── nginx/
│   └── docs-public/
├── templates/
│   ├── plan/         # por tipo de sprint: feature, bugfix, refactor, migration, infra
│   └── prompt-dispatch.md
├── checklists/       # pre-dispatch, post-pr-review, deploy-prod, capture-learnings
├── scripts/          # init.sh, create-worktree.sh (multi-IDE)
└── examples/         # profiles de referencia
```

## Configuración

Proyecto consumidor crea `.sprint-orchestrator.yml` (vía `init.sh`):

```yaml
version: 1
project_name: mi-app
default_branch: main

paths:
  plans: docs/superpowers/plans
  worktrees: .claude/worktrees

addons: [postgres, nextjs, e2e-validation, github-actions]

dispatch:
  method: auto      # auto-detect IDE | claude-cli | cursor | vscode | antigravity | windsurf | clipboard-only

notifications:
  github_assignee: mi-username
  github_label: ready-for-review

# Workflows avanzados (opt-in)
adversarial_review:
  enabled: true
  skip_types: [infra]
  reviewer_model: sonnet
  max_comments: 8

github-actions:
  preview_validation: true
  preview_platform: vercel  # vercel | fly | railway | coolify | generic
```

Schema completo en [CHANGELOG.md](CHANGELOG.md).

## Workflows avanzados

### 🤖 Adversarial review

Cuando el chat de sprint abre un PR, un **3er Claude aislado** es dispatcheado como reviewer adversarial:

- Sin contexto de la implementación
- Recibe solo el diff del PR + plan original
- Tiene prompt explícito para **encontrar problemas** (no aprobar)
- Postea comentarios vía `gh pr review`
- Tú te conviertes en árbitro, no reviewer

Ver [`core/adversarial-review.md`](core/adversarial-review.md).

### 🚀 Preview deploy + auto-validation

Workflows GitHub Actions para Vercel/Fly/Railway/Coolify:

1. PR abre → levanta deploy preview
2. Corre Playwright contra URL preview
3. Postea comment estructurado en PR con PASS/FAIL + screenshots
4. Aplica label `auto-validated` o `needs-fix`
5. Orquestador despierta vía GitHub notification (sin polling)

Ver [`addons/github-actions/preview-validation/`](addons/github-actions/preview-validation/).

### 🧠 Capture learnings

Después de cada deploy, el orquestador proactivamente triagia commits `fix:` y propone nuevos bug patterns para agregar a los archivos por addon. La skill evoluciona con el uso.

Ver [`checklists/capture-learnings.md`](checklists/capture-learnings.md).

## Patrones validados

Esta skill creció de uso real en producción. Bug patterns (GRANTs de Postgres, SSR fetch en Next.js, leak de middleware en Hono, etc.) están documentados por addon. Las fases del workflow (PLAN → DISPATCH → EXECUTE → REVIEW+DEPLOY) y anti-patterns están battle-tested.

Ver [`examples/superdb-profile.yml`](examples/superdb-profile.yml) para un profile real completo.

## Estado

**v1.0** del redesign (actual): fundación + 3 workflows avanzados.

**Roadmap (v2.0):**

- Bug patterns split por addon (actualmente la mayoría son placeholders)
- Profiles de ejemplo adicionales (Next.js+Vercel, Django, monolito simple)
- Scripts de cleanup (`cleanup-merged.sh`, `list-sprints.sh`)
- Checklist de recovery para sprint atascado
- Template de kickoff para proyectos nuevos
- Implementación de scheduled task (para proyectos sin GitHub Actions)

## Contribuyendo

¡PRs bienvenidos! Especialmente:

- **Addons nuevos** para tu stack (Rails, Django, Spring, Go services, etc.)
- **Más profiles de ejemplo**
- **Bug patterns** de tus propias lecciones de producción
- **Traducciones** de este README

Ver [CONTRIBUTING.md](CONTRIBUTING.md).

## Licencia

MIT — ver [LICENSE](LICENSE).

## Agradecimientos

Construido sobre [Claude Code de Anthropic](https://claude.com/claude-code) y el ecosistema de skills [superpowers](https://github.com/anthropics/superpowers). Validación inicial en el proyecto SuperDB (BaaS multi-tenant brasileño).
