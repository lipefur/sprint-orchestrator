# Workflow — 4 fases do Sprint

Padrão validado em 17+ sprints. Organiza o trabalho de sprint em fases claras com isolation via git worktree, paralelismo via multi-agent, e memória institucional (anti-patterns + bug-patterns que acumulam). Em modelos com context window menor (200k), também evita context bloat dividindo estratégia e execução em chats separados — mas esse é um dos benefícios, não o único.

## Modelo mental

```
┌────────────────────────────────────────────┐
│  ORCHESTRATOR CHAT (o user fica aqui)      │
│  • Brainstorming estratégico               │
│  • Decisões batidas com user               │
│  • Planos detalhados                       │
│  • Review de PR + merge + deploy           │
│  • State + Memory persistente              │
└────────────────────────────────────────────┘
                  ↓ dispatch (URL scheme + worktree)
┌────────────────────────────────────────────┐
│  SPRINT CHAT (Claude novo, escopo limitado)│
│  • Lê plano commitado                      │
│  • Multi-agent paralelo (1-4 agents)       │
│  • Implementa, roda smoke + E2E local      │
│  • Abre PR (NÃO mergeia)                   │
│  • Atualiza state.md + memory              │
└────────────────────────────────────────────┘
                  ↓ PR pronto
            volta pro orchestrator
```

## Modos adaptativos (monolithic / split / auto)

A skill funciona em dois modos, escolhidos pela heurística abaixo conforme o context window disponível e o tamanho do sprint.

### Heurística de decisão (roda na fase PLAN)

```
profile.model ausente            → split  (assume 200k, comportamento legado)
profile.model.mode == monolithic → monolithic  (override fixo)
profile.model.mode == split      → split        (override fixo)
profile.model.mode == auto:
    context_window == 200k        → split   (monolithic não cabe)
    context_window == 1m:
        sprint épico              → split   (multi-área, esforço alto, paralelismo pesado)
        sprint pequeno/médio      → monolithic
```

`sprint épico` = esforço alto + 2+ áreas independentes. Pequeno/médio = o resto.

Após decidir em modo `auto`, **anuncie e aceite veto**:

> "Sprint médio + você tem 1M → vou de monolithic. OK ou prefere split?"

Registre o modo escolhido no `state.md` do sprint.

### O que muda por modo

| Fase | Split | Monolithic |
|---|---|---|
| PLAN | brainstorm + plano + commit em main | igual |
| DISPATCH | `create-worktree.sh` cria worktree + abre chat novo (URL scheme) | `create-worktree.sh` cria worktree; o mesmo chat faz `cd` e continua |
| EXECUTE | sprint chat separado executa | mesmo chat executa; subagents só se áreas disjuntas |
| REVIEW | volta pro orchestrator chat | mesmo chat revisa (adversarial via subagent) |

**Invariantes nos dois modos:** worktree isolado, `state.md` atualizado por fase, completion report no fim, checklists aplicam igual.

### Memory em 1m

Com `context_window: 1m`, o orquestrador pode carregar memories de sprints anteriores inteiras quando precisar — sem a seletividade que 200k exigia. Memory continua `.md` por sprint.

## Fases

### Fase 1 — PLAN (orchestrator)

1. Brainstorming com user até decisões batidas
2. Cria plano em `{profile.paths.plans}/YYYY-MM-DD-{projeto}-sprint-N-{tema}.md` usando `templates/plan/{tipo}.md`
3. Commit plano em main + push
   - **Crítico**: sem isso, sprint chat não acha plano

### Fase 2 — DISPATCH (orchestrator)

4. Roda `scripts/create-worktree.sh N {tema}` que:
   - Cria worktree em `{profile.paths.worktrees}/sprint-N-{tema}/`
   - Atualiza `.sprint-orchestrator/state.md` com entrada nova (fase=DISPATCH)
   - Gera prompt do `templates/prompt-dispatch.md` interpolado
   - Tenta abrir Claude Code via URL scheme `claude-cli://?q=...&folder=...`
   - Fallback: copia prompt pro clipboard + abre terminal novo
   - Agenda scheduled task de auto-detect de PR (a cada 30min, até 6h timeout)

### Fase 3 — EXECUTE (sprint chat — outro Claude lê esta skill também)

5. Sprint chat:
   - Verifica path do plano + line count (PARA se não bate)
   - Lê plano completo
   - Multi-agent paralelo se aplicável
   - Roda smoke local (`{profile.smoke.local}`)
   - **Quando addon `e2e-validation` ativo**: roda Playwright MCP nos fluxos declarados ANTES de abrir PR
   - Abre 1 PR único, conventional commits
   - Atualiza `.sprint-orchestrator/state.md` com PR # e fase=REVIEW
   - Se `notifications.github_assignee` definido, assigna user no PR + adiciona label `ready-for-review`

### Fase 4 — REVIEW + DEPLOY (orchestrator)

6. Scheduled task detecta PR aberto → abre sessão nova do orquestrador com contexto carregado
7. Orquestrador:
   - Lê `.sprint-orchestrator/state.md`
   - Roda checklist `checklists/post-pr-review.md` (versão Fase 2 será addon-aware)
   - Fixes inline se CI falhar (não delega de volta)
   - Roda Playwright **navegado** pós-merge contra URL prod (quando `e2e-validation` ativo) — preview/local/`curl` cobrem EXECUTE/REVIEW, não isto (anti-pattern #10)
   - Merge quando verde
   - Roda checklist `checklists/deploy-prod.md`
   - Atualiza state.md com fase=DONE + memory deploy

## State file — `.sprint-orchestrator/state.md`

Source of truth do estado dos sprints. Source-controlled no repo do projeto consumidor.

Formato:

```markdown
# Sprint state — {project_name}

> Atualizado: 2026-05-19 14:32 (sprint chat)

## Sprint 14 — multi-tenancy migrations
- **Fase**: EXECUTE (sprint chat ativo)
- **Worktree**: .claude/worktrees/sprint-14-multi-tenancy/
- **Branch**: sprint-14-multi-tenancy
- **Tipo**: migration
- **Despachado em**: 2026-05-19 11:00
- **Commit base**: a3f8c91
- **Multi-agent**: 2 agents paralelos (A: SQL functions, B: TS consumers)
- **PR**: aguardando
- **Scheduled task**: task-abc123 (check a cada 30min, timeout 2026-05-19 17:00)
- **Próximo passo**: sprint chat termina → abre PR → orquestrador detecta

## Sprint 13 — billing webhooks (mergeado)
- **Status**: ✅ Deploy completo em 2026-05-18
- **PR**: #15 mergeado em 2026-05-17
- **Validação prod**: https://app.exemplo.com — Playwright navegado: login + render + console OK
- **Memory**: project_sprint_13_deploy_2026-05-18.md
```

**Quem escreve:**
- Orquestrador: cria entrada na fase DISPATCH, atualiza nas fases REVIEW e DONE.
- Sprint chat: atualiza ao terminar (PR aberto, fase=REVIEW).
- Scheduled task: marca PR detectado quando muda fase.

**Resiliência**: orquestrador pode re-derivar estado do `gh pr list` + `git worktree list` se `state.md` está stale (>2h sem update). State é cache, não fonte primária.

## Scheduled task pattern (auto-detect de PR)

Quando `create-worktree.sh` dispara, registra task usando MCP `scheduled-tasks` (quando disponível) ou via `cron`/`launchd` fallback:

```
Task ID: sprint-N-tema-check
Interval: 30min
Command: `cd <profile.paths.worktrees>/sprint-N-tema && gh pr list --head sprint-N-tema --json number,state,url`
On found: dispara nova sessão do orchestrator via `claude-cli://?q=<review-prompt>&folder=<worktree>`
On 6h timeout: notifica user (canal configurado em profile.notifications) + auto-desliga
```

Cleanup é responsabilidade da Fase 2 (`scripts/cleanup-merged.sh`).

## Anti-padrões críticos (cross-cutting)

- ❌ **NÃO** criar worktree antes de commitar plano em main — sprint chat não acha plano
- ❌ **NÃO** delegar fix de CI bug pra sprint chat — resolve inline no orchestrator
- ❌ **NÃO** mergear sem smoke + E2E (quando aplicável) passarem local
- ❌ **NÃO** abrir PR se Playwright pré-PR falhou (quando addon `e2e-validation` ativo)
- ❌ **NÃO** mexer no histórico git público sem rotacionar secrets antes
- ❌ **NÃO** assumir schema/tabela existe sem verificar — sempre `psql -c '\d'` antes (quando addon `postgres`)

Para anti-padrões stack-specific, ver `addons/<nome>/bug-patterns.md` (a partir da Fase 2 do refactor).

## Convenções estabelecidas

- **Worktrees**: `{profile.paths.worktrees}/sprint-{N}-{tema-slug}/`
- **Branches**: `{profile.git.worktree_prefix}-{N}-{tema-slug}` (default: `sprint-N-tema`)
- **Planos**: `{profile.paths.plans}/{YYYY-MM-DD}-{project_name}-sprint-{N}-{tema}.md`
- **Memory completion**: `project_sprint_{N}_complete.md` (em `{profile.paths.memory}/`)
- **Memory deploy**: `project_sprint_{N}_deploy_{YYYY-MM-DD}.md`
- **Commits**: Conventional (`feat`, `fix`, `chore`, `docs`, etc.) + Co-Authored-By
- **PR title**: `{profile.git.pr_title_prefix} tema curto`
- **PR body**: TLDR + lista entregas + DoD + próximos passos
