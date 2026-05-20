# Post-PR Review Checklist

Rode quando user volta dizendo "PR #{N} aberto" ou "sprint X completo".

## 0. Adversarial review (se ativo no profile)

**Antes** de revisar manualmente, dispatcha um Claude reviewer adversarial isolado:

- [ ] Lê plano original + PR diff + bug-patterns dos addons ativos
- [ ] Posta comments no PR via `gh pr review`
- [ ] Você triagia os comments (critical/high = fix; medium = decide; low = doc)

Ver `core/adversarial-review.md` pra prompt template e workflow detalhado.

Pula este passo se `profile.adversarial_review.enabled: false` OU se tipo do sprint está em `profile.adversarial_review.skip_types`.

## 1. Pega estado do PR

```bash
gh pr view {N} --json title,state,additions,deletions,changedFiles,statusCheckRollup,mergeable
```

Confirmar:
- [ ] State: OPEN
- [ ] Mergeable: MERGEABLE
- [ ] Stats razoáveis (não tem `+50000` ou nada absurdo)

## 2. CI status

Procurar nos checks (lista varia por projeto — consulte `addons/github-actions/` ou equivalente):
- [ ] Smoke E2E (se configurado) → **SUCCESS obrigatório**
- [ ] Lint → SUCCESS
- [ ] Build → SUCCESS
- [ ] Commitlint (se ativo) → SUCCESS
- [ ] Outros checks específicos do projeto

**Se algum check obrigatório falhar:**
- [ ] Veja logs com `gh run view <run-id> --log-failed | tail -50`
- [ ] **Fix inline NO orchestrator chat** (não delega de volta pro sprint chat)
- [ ] Pattern observado: 1-3 bugs latentes aparecem mesmo com smoke local OK
- [ ] Consulte `core/anti-patterns.md` (cross-cutting) + `addons/<X>/bug-patterns.md` (stack-specific) pra identificar rápido

## 3. Quality do commit

- [ ] Conventional commits no commit message (`feat:`, `fix:`, etc.)
- [ ] PR title segue `feat(sprint-N): tema curto` ou similar
- [ ] PR description tem TLDR + entregas + próximos passos
- [ ] Co-Authored-By no fim do commit

## 4. Spot-check segurança

- [ ] `git -C worktree log --all --pretty=oneline | xargs gitleaks ...` (se sprint mexeu em config/auth)
- [ ] Nenhum `.env` real commitado
- [ ] Nenhuma chave privada commitada (verificar paths `~/.ssh/`, `*.pem`, etc)
- [ ] Hardcode de senha ou token? → não

## 5. Memory atualizada

- [ ] Sprint chat criou `project_sprint_{N}_complete.md` em `~/.claude/projects/.../memory/`?
- [ ] Linha referenciando no `MEMORY.md` principal?
- [ ] Memory cobre: entregas, decisões, bugs, pendências

(Se não tiver, peça pro user atualizar ou faça você mesmo)

## 6. Merge

```bash
gh pr merge {N} --merge --delete-branch
```

- [ ] Merge OK
- [ ] Worktree limpa: `git worktree remove .claude/worktrees/sprint-{N}-{tema} --force`
- [ ] Branch local apagada
- [ ] `git checkout main && git pull --ff-only origin main`
- [ ] Confirma commit de merge em `git log --oneline main -3`

## 7. Limpa pendências do sprint chat

Veja seção "Pendências (orchestrator faz)" do memory completion.

Comuns:
- [ ] Setar env vars novas no Coolify/host
- [ ] Aplicar migrations em prod via SSH
- [ ] Configurar conta externa (Stripe, NF.io, etc) — comunica user
- [ ] Trigger deploy
- [ ] Smoke prod E2E

→ Roda `checklists/deploy-prod.md`

## 8. Atualiza memória final

Após validar deploy:
- [ ] Cria `project_sprint_{N}_deploy_{YYYY-MM-DD}.md` (template `memory-deploy.md`)
- [ ] Adiciona linha no `MEMORY.md` principal
- [ ] Documenta lições aprendidas em `references/common-bug-patterns.md` da skill (se houver bug novo)

---

## Padrão de quantos bugs surgem

Observado em 12+ sprints:

| Sprint complexidade | Bugs latentes que aparecem | Tempo orchestrator pra resolver |
|---|---|---|
| Simples (1-2 dias) | 0-1 | <30min |
| Médio (3-4 dias) | 1-3 | 1-2h |
| Alto (5+ dias) | 3-6 | 2-4h |

**Não é falha do sprint chat.** É natural — refletem buracos de cobertura do smoke local vs prod real. Resolve inline e adiciona caso a `references/common-bug-patterns.md` pra próximo sprint pegar antes.
