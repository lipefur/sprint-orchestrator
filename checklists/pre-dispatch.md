# Pre-Dispatch Checklist

Rode **antes** de criar o worktree do sprint chat. Falhar aqui custa MUITO menos que descobrir no meio do sprint.

## Plano em ordem

- [ ] Plano escrito em `docs/superpowers/plans/{YYYY-MM-DD}-{projeto}-sprint-{N}-{tema}.md`
- [ ] Plano tem mínimo: **Objetivo, Decisões batidas, Fases, DoD, Anti-padrões**
- [ ] Decisões abertas listadas explicitamente e **resolvidas com user antes** de criar plano final
- [ ] Multi-agent strategy decidida (ver `references/multi-agent-strategy.md`)
- [ ] Estimativa de esforço documentada (baixo/médio/alto + horas/dias)
- [ ] Migrations idempotentes (`IF NOT EXISTS` / `DROP IF EXISTS`)
- [ ] Env vars novas listadas com defaults sensatos

## Plano commitado (CRÍTICO)

- [ ] `git add docs/superpowers/plans/{filename}.md`
- [ ] `git commit -m "docs: plano Sprint {N} — {tema}"`
- [ ] `git push origin main`

⚠️ **Sem isso, o sprint chat NÃO encontra o plano** (Sprint 10 quebrou exatamente assim).

## Estado git limpo

- [ ] `git status` mostra working tree clean em main
- [ ] `git worktree list` não tem worktrees abandonados de sprints anteriores
- [ ] Branches deletadas: `git branch -a | grep -i sprint` deve ter só `main` + sprint atual

## Criar worktree

- [ ] `git worktree add .claude/worktrees/sprint-{N}-{tema-slug} -b sprint-{N}-{tema-slug}`
- [ ] `cd .claude/worktrees/sprint-{N}-{tema-slug}`
- [ ] `git pull --ff-only origin main` (pega o commit do plano)
- [ ] Confirma plano acessível: `ls docs/superpowers/plans/{filename}.md`
- [ ] Confirma line count: `wc -l docs/superpowers/plans/{filename}.md`

## Pré-flight specifications

- [ ] Sprint mexe em license/secret/security? → adicionar lembrete pra gerar keys offline antes
- [ ] Sprint mexe em migrations? → confirmar idempotência + ordem dependencies entre schemas
- [ ] Addon `postgres` ativo + migration adiciona coluna NOT NULL? → instruir sprint chat a grep TODOS os INSERTs nessa tabela e incluir a coluna nova em cada um. NUNCA aceitar pattern "gera valor + INSERT sem ele + UPDATE depois"
- [ ] Addon `postgres` ativo + cria função SQL ou migration que cria tabela? → instruir a (a) cruzar colunas da DDL com TODOS os arquivos do código que consomem a tabela; (b) dar GRANT pro role do service principal
- [ ] Addon `multi-tenant` ativo + cria migration global? → instruir a adicionar `sprint-N` ao loop do CI workflow no MESMO PR
- [ ] Addon `nextjs` ativo + Server Component faz fetch? → instruir a usar URL absoluta (`next/headers`) + forwardar cookies
- [ ] Addon `nextjs` ativo + sprint adiciona `NEXT_PUBLIC_*` env? → lembrar de adicionar `ARG` no Dockerfile
- [ ] Addon `docs-public` ativo? → instruir sprint chat a separar docs públicos vs internos + grep de segurança antes do PR (SQL DML em tabelas internas, comandos ops, tokens, credenciais)
- [ ] Addon `monorepo` ativo + sprint adiciona workspace dep? → lembrar de atualizar Dockerfiles dos services Docker
- [ ] Addon `legalese` ativo OU sprint cria LICENSE/Code of Conduct? → usar `curl` da fonte oficial (ver `addons/legalese/content-filter.md`)

## Prompt formatado pra entrega

Use `templates/prompt-dispatch.md` interpolando:

- [ ] `{{PATH_ABSOLUTO_WORKTREE}}` — começa com `/Users/...`
- [ ] `{{COMMIT_HASH}}` — `git -C worktree rev-parse --short HEAD`
- [ ] `{{LINE_COUNT}}` — `wc -l < plano.md`
- [ ] `{{PLAN_FILENAME}}` — só o filename, não path completo
- [ ] `{{TEMA_SLUG}}` — kebab-case
- [ ] Modelo recomendado (Sonnet médio, com/sem `think hard`)
- [ ] Multi-agent breakdown se aplicável

## Dependências externas

- [ ] User vai precisar de conta externa (Stripe, NF.io, GitHub Org, etc)? → comunicado ANTES do dispatch
- [ ] Algo que orchestrator precisa fazer antes do sprint começar (gerar par RSA, criar repo privado)?
- [ ] DNS/Coolify precisa config antecipada?

## Confirmações antes de entregar prompt

- [ ] Re-leu o prompt completo procurando placeholders não-interpolados (`{{...}}`)
- [ ] Não tem texto "TODO" ou "FIXME" no prompt
- [ ] Verificação inicial obrigatória está NO TOPO do prompt
- [ ] Anti-padrões críticos incluídos (mesmo os crônicos genéricos)
- [ ] Mensagem final esperada do sprint chat está documentada

---

## Se algum item falhar

**NÃO entregue o prompt pro user.** Resolve primeiro. Tempo de orchestrator pra resolver agora < tempo de sprint chat descobrir + voltar + você arrumar + sprint chat re-orchestrar.
