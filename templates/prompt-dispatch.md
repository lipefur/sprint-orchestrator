# Template do prompt pra dispatch em chat novo

Use este template **interpolando placeholders `{{ ... }}`**, depois entregue pro user dentro de bloco \`\`\` triplo pra colar em Claude Code chat novo. (O `scripts/create-worktree.sh` já faz isso automaticamente via URL scheme, mas este template é o que vai dentro da URL.)

---

```
# Sprint {{N}} — {{PROJECT_NAME}}: {{TEMA}}

Você é o desenvolvedor executando Sprint {{N}}. Worktree em: {{WORKTREE_ABSOLUTE}}

## VERIFICAÇÃO INICIAL OBRIGATÓRIA

`​``bash
cd {{WORKTREE_ABSOLUTE}}
git status   # deve estar em sprint-{{N}}-{{TEMA_SLUG}}, limpo, em {{COMMIT_HASH}}
wc -l {{PLAN_PATH}}   # deve ser {{LINE_COUNT}} linhas
`​``

**Se o plano NÃO existir ou tiver linhas erradas, PARE e reporte ao orquestrador. NÃO crie plano novo.**

## Leia o plano PRIMEIRO

`{{PLAN_PATH}}` ({{LINE_COUNT}} linhas)

Tem TUDO detalhado: tipo de sprint, objetivos, fases, multi-agent strategy, fluxos E2E (se UI), DoD, anti-padrões.

## Tipo de sprint

{{ Lido do plano: feature / bugfix / refactor / migration / infra }}

Cada tipo tem rituais específicos. Consulte a seção "DoD" do plano.

## Padrão estabelecido (qualquer tipo de sprint)

- 1 PR único via `gh pr create`
- Commits incrementais, conventional commits, mensagens PT-BR
- NÃO mergeia em main — orquestrador faz
- Atualiza `.sprint-orchestrator/state.md` ao terminar com PR # e fase=REVIEW

## Padrões por addon ativo no projeto

(Consulta `addons/<nome>/README.md` da skill pra detalhes específicos quando relevante)

- **Addon `e2e-validation`**: roda Playwright nos "Fluxos E2E a validar" do plano ANTES de abrir PR. Se algum falha: NÃO abre PR, atualiza state.md com BLOCKED_E2E, reporta.
- **Addon `postgres` + plano com migrations**: garante idempotência (IF NOT EXISTS), GRANTs, backfill antes de SET NOT NULL.
- **Addon `multi-tenant`**: separa migrations global vs per-tenant, GRANTs cross-role.
- **Addon `monorepo`**: roda Docker build dos services afetados antes do PR.
- **Addon `nextjs`**: confere NEXT_PUBLIC_* via ARG no Dockerfile, Server Components com URL absoluta.

## Anti-padrões críticos (cross-cutting)

Ver `core/anti-patterns.md` da skill. Top 5 imediatos:

- ❌ Hardcoded `localhost:PORT` em código que vai pra container
- ❌ Inventar tabela/schema sem verificar com `psql -c '\d'`
- ❌ Workflow CI esquecer migration nova
- ❌ Sprint chat decidir trade-off técnico não batido pelo orquestrador — para e reporta
- ❌ Mergear sem smoke (+ E2E se aplicável) passar local

## Multi-agent strategy ({{ se aplica }})

{{N}} agents paralelos, zero overlap. Detalhes no plano.

## Entregar ao fim (mensagem final do sprint chat)

- N commits, +X/-Y, M arquivos
- (Se e2e-validation) Resultado dos fluxos E2E (PASS/FAIL com screenshots)
- PR #N criado
- Pendências orquestrador (env vars novas, migrations prod, contas externas)
- state.md atualizado
- Próximo passo claro ("orchestrator: review + merge + aplicar X em prod")

## Critérios de DoD

Listados no plano completo. Não pula nenhum. Especialmente:
- Smoke local passa
- (Se aplicável) Playwright E2E passa
- CI verde
- state.md atualizado

Bora. Lê o plano primeiro ({{LINE_COUNT}} linhas).
```

---

## Notas pra orchestrator gerar bem

### Placeholders obrigatórios

- `{{PROJECT_NAME}}` — lido de `.sprint-orchestrator.yml` `project_name`
- `{{N}}` — número do sprint
- `{{TEMA}}` — tema descritivo
- `{{TEMA_SLUG}}` — kebab-case do tema
- `{{WORKTREE_ABSOLUTE}}` — path absoluto `/Users/.../worktrees/sprint-N-tema`
- `{{COMMIT_HASH}}` — `git -C worktree rev-parse --short HEAD`
- `{{PLAN_PATH}}` — path relativo do plano
- `{{LINE_COUNT}}` — `wc -l < plan.md`

### Customizações por addon

- Se addon `e2e-validation` ativo: garantir que linha "roda Playwright ANTES de abrir PR" tá no prompt
- Se addon `postgres` ativo: garantir referência ao bug-patterns Postgres
- Se addon `multi-tenant` ativo: incluir nota sobre migrations global vs per-tenant

### Entrega final clara

Sprint chat precisa saber EXATAMENTE o que entregar como mensagem final pra orquestrador não ter que reler conversa toda. Estrutura padrão acelera handoff.
