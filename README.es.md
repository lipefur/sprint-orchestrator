# sprint-orchestrator

> **Orquesta sprints de software con Claude:** paralelismo, isolation vía git worktree, memoria institucional y (en modelos menores) cero context bloat. Adaptativo a 1M o 200k de context.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Latest](https://img.shields.io/github/v/release/lipefur/sprint-orchestrator?color=blue)](https://github.com/lipefur/sprint-orchestrator/releases)
[![Status](https://img.shields.io/badge/status-active-success.svg)](#estado)
[![Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-orange.svg)](https://claude.com/claude-code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Discussions](https://img.shields.io/badge/💬-Discussions-blueviolet)](https://github.com/lipefur/sprint-orchestrator/discussions)

**🌍 Idiomas:** [Português](README.md) · [English](README.en.md) · [Español](README.es.md)
**📚 Docs:** [Tutorial](docs/tutorial-getting-started.md) · [FAQ](docs/faq.md) · [Recipes](docs/recipes/)

---

## 🤔 El problema

Quieres construir algo grande con Claude. Abres un chat. Le explicas lo que quieres. Claude empieza a codear. Dos horas después:

- 😵 El chat está enorme. Claude olvidó las decisiones del principio.
- 🐌 Todo pasa una cosa a la vez, incluso cuando 4 cosas podrían correr en paralelo.
- 🔁 Explicas las mismas convenciones una y otra vez.
- 💔 ¿Bugs del sprint pasado? Olvidados. Claude cae en ellos otra vez.

**¿Te suena familiar?**

## ✨ La idea

Piensa en construir software como hacer una película:

| Rol | Quién |
|---|---|
| 🎬 **Director** (visión creativa, aprueba cortes) | **Tú** |
| 📋 **Productor** (planea, revisa, entrega) | **Chat orquestador** (se queda abierto para el proyecto entero) |
| 🎥 **Equipos de filmación** (cada uno graba una escena) | **Chats de sprint** (uno por feature, creado y descartado) |

Tú no filmas cada cuadro. Tú **diriges**, el productor **planea y revisa**, los equipos **ejecutan en paralelo**.

Eso es. Esa es la skill.

## 🎯 Antes / Después

| | **Sin esta skill** | **Con esta skill** |
|---|---|---|
| **Estructura del chat** | 1 chat gigante que olvida contexto | 1 orquestador + N chats de sprint enfocados |
| **Decisiones** | Tomadas al inicio, perdidas después | Capturadas en planes, commiteadas en git |
| **Paralelismo** | Una cosa a la vez | 1-4 agents por sprint, multi-sprint posible |
| **Memoria entre sprints** | Ninguna | `state.md` + `bug-patterns.md` por addon |
| **Control de calidad** | Lees cada PR manualmente | Claude adversarial revisa primero, tú arbitras |
| **Validación** | "Funciona en mi máquina" | GitHub Action hace preview deploy + Playwright automático |
| **Lecciones aprendidas** | Perdidas en el historial del chat | Capturadas como bug patterns después de cada deploy |

## 👥 Para quién es esta skill

- **Devs usando Claude Code todos los días** en proyectos reales (no solo demos)
- **Founders solo / indie hackers** construyendo productos multi-feature
- **Equipos pequeños** que quieren workflow estructurado con IA
- **Quienes tienen múltiples repos** queriendo proceso consistente entre ellos

**No es para:** scripts de un solo uso, prototipos descartables, "solo arregla este typo". Para eso, usa Claude directamente.

## 🚀 Instalación (1 comando)

```bash
curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash
```

El installer verifica dependencias, clona la skill a `~/.claude/skills/sprint-orchestrator/` y muestra próximos pasos.

<details>
<summary>Otros métodos de instalación (manual / revisar antes / ubicación custom)</summary>

**Revisar el installer antes:**

```bash
curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh -o /tmp/install.sh
less /tmp/install.sh        # inspecciona
bash /tmp/install.sh
```

**Clone directo (sin installer):**

```bash
git clone https://github.com/lipefur/sprint-orchestrator.git ~/.claude/skills/sprint-orchestrator
```

**Ubicación custom:**

```bash
SPRINT_ORCHESTRATOR_DIR=/custom/path bash install.sh
```

**Actualizar después:**

```bash
curl -fsSL https://raw.githubusercontent.com/lipefur/sprint-orchestrator/main/install.sh | bash -s -- update
```

</details>

## 📖 Quickstart (3 pasos)

### 1. Setup del proyecto (una vez)

```bash
cd path/a/tu/proyecto
bash ~/.claude/skills/sprint-orchestrator/scripts/init.sh
```

El script inspecciona tu repo, detecta tu stack (¿Postgres? ¿Next.js? ¿Monorepo?), pregunta algunas cosas y escribe `.sprint-orchestrator.yml`.

### 2. Planear un sprint

Abre Claude Code en tu proyecto. Di:

> "Vamos a planear sprint 1 — implementar login con OAuth"

Claude hace brainstorming contigo, escribe un plan detallado, commitea en `main`.

### 3. Dispatchar el sprint

```bash
bash ~/.claude/skills/sprint-orchestrator/scripts/create-worktree.sh 1 oauth-login
```

Una **nueva ventana de Claude Code abre**, ya corriendo en un worktree aislado con el plan cargado. Ejecuta autónomamente, abre PR, y vuelve a ti para revisar.

Es todo. Walkthrough completo: [docs/tutorial-getting-started.md](docs/tutorial-getting-started.md).

---

# Resumen técnico

Para quienes quieren entender la arquitectura antes de instalar.

## Cómo funciona por debajo

La skill está estructurada como **markdown modular** que Claude lee bajo demanda:

```
sprint-orchestrator/
├── SKILL.md             # entry point — Claude siempre lee
├── core/                # workflow + anti-patterns universales + estilo de commits
├── addons/              # stack-specific (carga solo si el profile activa)
├── templates/           # templates de plan por tipo, prompt dispatch, memory
├── checklists/          # pre-dispatch, post-pr-review, deploy-prod, capture-learnings
└── scripts/             # init.sh, create-worktree.sh (multi-IDE dispatch)
```

Cuando invocas la skill en Claude Code:

1. Claude lee `.sprint-orchestrator.yml` de tu proyecto
2. Carga `core/` (universal)
3. Carga solo los `addons/` que tu proyecto usa (ej. `postgres`, `nextjs`)
4. Consulta templates/checklists just-in-time por fase

Resultado: **~6-12k tokens de contexto** incluso con todos los addons activos.

## El workflow en 4 fases

```
┌─────────────────────────────────┐
│  CHAT ORQUESTADOR (te quedas)   │
│  1. PLAN — brainstorm + plan    │
│  2. DISPATCH — crea worktree    │
│              + abre chat nuevo  │
└─────────────────────────────────┘
              ↓
┌─────────────────────────────────┐
│  CHAT DE SPRINT (Claude nuevo)  │
│  3. EXECUTE — lee plan, codea,  │
│     testea, abre PR, update     │
└─────────────────────────────────┘
              ↓
┌─────────────────────────────────┐
│  VUELVE AL ORQUESTADOR          │
│  4. REVIEW + DEPLOY             │
│     (con checks automáticos)    │
└─────────────────────────────────┘
```

## Configuración (un archivo por proyecto)

`.sprint-orchestrator.yml` en la raíz del proyecto (generado por `init.sh`):

```yaml
version: 1
project_name: mi-app
default_branch: main

paths:
  plans: docs/superpowers/plans
  worktrees: .claude/worktrees

addons: [postgres, nextjs, e2e-validation, github-actions]

dispatch:
  method: auto      # auto-detect IDE (Cursor, VS Code, Claude Code, etc.)

notifications:
  github_assignee: mi-username       # auto-asignado en el PR
  github_label: ready-for-review

# Workflows avanzados (opt-in)
adversarial_review:
  enabled: true                       # 3er Claude revisa PRs adversarialmente
  reviewer_model: sonnet

github-actions:
  preview_validation: true            # preview deploy + Playwright auto en PR
  preview_platform: vercel            # vercel | fly | railway | coolify | generic
```

## Workflows avanzados

Tres workflows opt-in que elevan el flujo básico:

### 🤖 Adversarial review

Cuando el chat de sprint abre PR, un **3er Claude aislado** es dispatcheado como reviewer con prompt explícito: *"encuentra problemas que el implementer pasó por alto."* Postea comments vía `gh pr review`. Te conviertes en **árbitro**, no reviewer línea por línea.

→ [`core/adversarial-review.md`](core/adversarial-review.md)

### 🚀 Preview deploy + auto-validation

Templates de GitHub Action para Vercel/Fly/Railway/Coolify. Cuando PR abre: levanta preview deploy, corre Playwright contra URL preview, postea comment estructurado con PASS/FAIL + screenshots. Orquestador despierta vía GitHub notification — **sin polling**.

→ [`addons/github-actions/preview-validation/`](addons/github-actions/preview-validation/)

### 🧠 Capture learnings

Después de cada deploy, el orquestador triagia commits `fix:` del sprint y propone nuevos bug patterns para agregar a los addons. La skill **evoluciona con el uso** en lugar de quedarse estática.

→ [`checklists/capture-learnings.md`](checklists/capture-learnings.md)

### 📊 Visual dashboard

Kanban board local renderizado desde `state.md`. Tres modos:

```bash
bash <skill>/scripts/dashboard.sh              # HTML estático, abre en el navegador
bash <skill>/scripts/dashboard.sh --serve      # live server con auto-refresh (SSE)
bash <skill>/scripts/dashboard.sh --workspace  # multi-project desde ~/.config/sprint-orchestrator/workspace.yml
```

Corre 100% local, **cero tokens Claude consumidos**. Ve todo de un vistazo: sprints por fase, PRs abiertos con labels, merges recientes.

→ [`scripts/dashboard/`](scripts/dashboard/)

### 🎛️ Modos adaptativos (1M / 200k)

La skill detecta tu context window (preguntado en `init.sh`) y elige:

- **monolithic** (1M / Opus 4.6+/4.8) — orquestador + ejecución en el mismo chat. Menos handoff. Worktree mantenido; subagents solo para áreas disjuntas.
- **split** (200k / Sonnet / Foundry) — 2 chats separados. Comportamiento clásico.

`mode: auto` decide por context window + tamaño del sprint, anuncia la decisión y acepta veto. Override fijo vía `model.mode` en el profile. Profiles antiguos sin `model:` → split (backward compat). Detalles en `core/workflow.md`.

## Soporte multi-IDE

El script de dispatch **detecta tu entorno automáticamente** y se adapta:

| Entorno | Comportamiento |
|---|---|
| **Claude Code standalone** (Terminal/iTerm) | URL scheme `claude-cli://` abre nueva ventana con prompt pre-cargado |
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

## Estado

**v1.0.1** (actual): fundación + 3 workflows avanzados + installer one-liner.

**Roadmap (v2.0):**

- Bug patterns split por addon (la mayoría son placeholders hoy — gap más grande)
- Más profiles de ejemplo (Next.js+Vercel, Django, monolito simple)
- Scripts de cleanup (`cleanup-merged.sh`, `list-sprints.sh`)
- Checklist de recovery para sprint atascado
- Template de kickoff para proyectos nuevos
- Implementación de scheduled task (para proyectos sin GitHub Actions)

## Contribuyendo

Contribuciones más valiosas:

- 🧠 **Bug patterns** de tu debugging real en producción → ver [template de issue bug-pattern](.github/ISSUE_TEMPLATE/bug-pattern.md)
- 🧩 **Addons nuevos** para tu stack (Rails, Django, Spring, Go, etc.) → ver [CONTRIBUTING.md](CONTRIBUTING.md)
- 📋 **Profiles de ejemplo** en `examples/`
- 🌍 **Traducciones** de este README

## Licencia

MIT — ver [LICENSE](LICENSE). Haz fork libremente.

## Origen

Construida y validada en 17+ sprints de producción entre Mayo/2026 y el release público — en un proyecto BaaS multi-tenant en producción. Ver [`examples/multi-tenant-saas-profile.yml`](examples/multi-tenant-saas-profile.yml) para un profile real anonimizado.
