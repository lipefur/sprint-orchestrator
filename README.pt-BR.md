# sprint-orchestrator

> Skill portátil de orquestração multi-chat para Claude Code. Validada em 17+ sprints de produção.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-active-success.svg)](#status)
[![Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-orange.svg)](https://claude.com/claude-code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Discussions](https://img.shields.io/badge/💬-Discussions-blueviolet)](https://github.com/lipefur/sprint-orchestrator/discussions)

**🌍 Idiomas:** [English](README.md) · [Português](README.pt-BR.md) · [Español](README.es.md)
**📚 Docs:** [Tutorial](docs/tutorial-getting-started.md) · [FAQ](docs/faq.md) · [Recipes](docs/recipes/)

---

## O que é

Uma skill que ensina o Claude Code a orquestrar sprints de software entre **múltiplos chats**:

- Um **chat orquestrador** onde você faz brainstorming, planeja, revisa e mergeia
- Um ou mais **chats de sprint** instanciados por sprint, executando o plano em paralelo

Esse padrão evita o context bloat em chats longos e habilita paralelismo real via multi-agent dispatch.

## Por que existe

Chats longos do Claude esquecem contexto. Um único chat pra "construir feature X" acaba:

- Esquecendo decisões batidas no início
- Serializando trabalho que poderia rodar em paralelo
- Misturando brainstorming com implementação
- Perdendo lições dos sprints anteriores

A skill separa o chat **estratégico** (você + orquestrador) dos chats de **execução** (Claude focado em um sprint por vez), com estado persistente em `state.md` e anti-padrões aprendidos documentados por addon.

## Workflow em visão geral

```
┌─────────────────────────────────┐
│  CHAT ORQUESTRADOR (você fica)  │
│  • Brainstorming + plano        │
│  • Review + merge + deploy      │
└─────────────────────────────────┘
              ↓ dispatch via URL scheme
┌─────────────────────────────────┐
│  CHAT DE SPRINT (Claude novo)   │
│  • Lê plano commitado           │
│  • Multi-agent paralelo         │
│  • Abre PR (não mergeia)        │
└─────────────────────────────────┘
              ↓ PR pronto
       volta pro orquestrador
```

## Quickstart

### 1. Instale a skill globalmente

```bash
git clone https://github.com/lipefur/sprint-orchestrator.git ~/.claude/skills/sprint-orchestrator
```

### 2. Inicialize no seu projeto

```bash
cd path/para/seu/projeto
bash ~/.claude/skills/sprint-orchestrator/scripts/init.sh
```

O script vai:

- Inspecionar o repo (`package.json`, `docker-compose.yml`, `next.config.*`, `vercel.json`, `migrations/`, etc.)
- Detectar addons aplicáveis (`postgres`, `nextjs`, `monorepo`, etc.)
- Perguntar o que não conseguir inferir (deploy method, comando smoke)
- Escrever `.sprint-orchestrator.yml` na raiz do repo

### 3. Comece um sprint

No Claude Code, no chat orquestrador do seu projeto:

> "Plano sprint 1 — implementar OAuth login"

Claude faz brainstorming com você, escreve o plano, commita em main. Depois:

```bash
bash ~/.claude/skills/sprint-orchestrator/scripts/create-worktree.sh 1 oauth-login
```

Isso abre uma nova janela Claude Code via URL scheme `claude-cli://`, já rodando no worktree com o plano como prompt inicial.

### 4. Chat de sprint executa, abre PR, atualiza `.sprint-orchestrator/state.md`

### 5. (Opcional) Workflows avançados entram em ação:

- **Adversarial review** — 3º Claude revisa o PR adversarialmente
- **Preview validation** — GitHub Action faz deploy preview + roda Playwright
- **Capture learnings** — pós-deploy, propõe bug patterns pra adicionar à skill

## Suporte multi-IDE

O script de dispatch detecta seu ambiente automaticamente e adapta:

| Ambiente | Comportamento do dispatch |
|---|---|
| **Claude Code standalone** (Terminal/iTerm) | URL scheme `claude-cli://` abre nova janela com prompt |
| **Cursor** | Abre worktree no Cursor + copia prompt → aperte ⌘L pra nova chat |
| **VS Code** + Claude extension | Abre worktree no VS Code + copia prompt → comando "Claude: New Chat" |
| **Antigravity** (Google) | Copia prompt + instrução + working dir |
| **Windsurf** (Codeium) | Abre worktree no Windsurf + copia prompt → nova Cascade chat |
| **Outros** | Clipboard puro + arquivo temp com prompt |

Sobrescreva por projeto via `dispatch.method` no profile.

## Como difere de alternativas

| Abordagem | Trade-off |
|---|---|
| **Chat longo único** | Context bloat, sem paralelismo, sem memória entre sprints |
| **`superpowers:executing-plans`** | Bom pra executar plano conhecido numa sessão; não orquestra fluxo multi-sprint |
| **TODO list / Notion** | Sem anti-padrões aprendidos; sem automação de dispatch + review |
| **Esta skill** | Workflow multi-chat, addon-modular, estado persistente, validado em produção |

## Arquitetura

```
sprint-orchestrator/
├── core/             # sempre carregado — workflow, multi-agent, conventional commits, anti-patterns, adversarial-review
├── addons/           # carregado sob demanda via profile
│   ├── postgres/
│   ├── nextjs/
│   ├── multi-tenant/
│   ├── monorepo/
│   ├── coolify-ssh/
│   ├── github-actions/    # inclui subsystem preview-validation/
│   ├── e2e-validation/    # Playwright + Chrome DevTools + Chrome extension
│   ├── legalese/          # workarounds de content filter pra LICENSE/CoC
│   ├── hono/
│   ├── nginx/
│   └── docs-public/
├── templates/
│   ├── plan/         # por tipo de sprint: feature, bugfix, refactor, migration, infra
│   └── prompt-dispatch.md
├── checklists/       # pre-dispatch, post-pr-review, deploy-prod, capture-learnings
├── scripts/          # init.sh, create-worktree.sh (multi-IDE)
└── examples/         # perfis de referência
```

## Configuração

Projeto consumidor cria `.sprint-orchestrator.yml` (via `init.sh`):

```yaml
version: 1
project_name: meu-app
default_branch: main

paths:
  plans: docs/superpowers/plans
  worktrees: .claude/worktrees

addons: [postgres, nextjs, e2e-validation, github-actions]

dispatch:
  method: auto      # auto-detect IDE | claude-cli | cursor | vscode | antigravity | windsurf | clipboard-only

notifications:
  github_assignee: meu-username
  github_label: ready-for-review

# Workflows avançados (opt-in)
adversarial_review:
  enabled: true
  skip_types: [infra]
  reviewer_model: sonnet
  max_comments: 8

github-actions:
  preview_validation: true
  preview_platform: vercel  # vercel | fly | railway | coolify | generic
```

Schema completo no [CHANGELOG.md](CHANGELOG.md).

## Workflows avançados

### 🤖 Adversarial review

Quando chat de sprint abre PR, um **3º Claude isolado** é dispatchado como reviewer adversarial:

- Sem contexto da implementação
- Recebe só o diff do PR + plano original
- Tem prompt explícito de **encontrar problemas** (não aprovar)
- Posta comments via `gh pr review`
- Você vira arbitrador, não reviewer

Ver [`core/adversarial-review.md`](core/adversarial-review.md).

### 🚀 Preview deploy + auto-validation

Workflows GitHub Actions pra Vercel/Fly/Railway/Coolify:

1. PR abre → sobe deploy preview
2. Roda Playwright contra URL preview
3. Posta PR comment estruturado com PASS/FAIL + screenshots
4. Aplica label `auto-validated` ou `needs-fix`
5. Orquestrador acorda via GitHub notification (sem polling)

Ver [`addons/github-actions/preview-validation/`](addons/github-actions/preview-validation/).

### 🧠 Capture learnings

Após cada deploy, orquestrador proativamente triagia commits `fix:` e propõe novos bug patterns pra adicionar aos arquivos por addon. Skill evolui com o uso.

Ver [`checklists/capture-learnings.md`](checklists/capture-learnings.md).

## Padrões validados

Esta skill cresceu de uso real em produção. Bug patterns (GRANTs de Postgres, SSR fetch em Next.js, vazamento de middleware em Hono, etc.) estão documentados por addon. As fases do workflow (PLAN → DISPATCH → EXECUTE → REVIEW+DEPLOY) e anti-padrões são batalha-testados.

Ver [`examples/superdb-profile.yml`](examples/superdb-profile.yml) pra um perfil real completo.

## Status

**v1.0** do redesign (atual): fundação + 3 workflows avançados.

**Roadmap (v2.0):**

- Bug patterns split por addon (atualmente a maioria é placeholder)
- Profiles de exemplo adicionais (Next.js+Vercel, Django, monolito simples)
- Scripts de cleanup (`cleanup-merged.sh`, `list-sprints.sh`)
- Checklist de recovery pra sprint travado
- Template de kickoff pra projetos novos
- Implementação de scheduled task (pra projetos sem GitHub Actions)

## Contribuindo

PRs bem-vindos! Especialmente:

- **Addons novos** pra sua stack (Rails, Django, Spring, Go services, etc.)
- **Mais perfis de exemplo**
- **Bug patterns** das suas próprias lições de produção
- **Traduções** deste README

Ver [CONTRIBUTING.md](CONTRIBUTING.md).

## Licença

MIT — ver [LICENSE](LICENSE).

## Agradecimentos

Construído em cima do [Claude Code da Anthropic](https://claude.com/claude-code) e do ecossistema de skills [superpowers](https://github.com/anthropics/superpowers). Validação inicial no projeto SuperDB (BaaS multi-tenant brasileiro).
