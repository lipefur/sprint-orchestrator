# Deploy Production Checklist

Rode **depois** de mergear PR em main. Cada seção tem instruções genéricas + addons específicos consultados sob demanda.

## 1. Pre-deploy

### Backups (se aplicável)

- [ ] Backup DB antes de migrations destrutivas (mecanismo depende do addon de DB ativo)
- [ ] Backup volume antes de remover service (depende do platform de deploy)

### Configs externas

- [ ] Conta criada e ativa em serviços novos (pagamento, email, etc.) — confirmar com user
- [ ] Keys/tokens gerados e disponíveis pra setar como env vars
- [ ] DNS records configurados (wildcard subdomain cobre muito)

## 2. Migrations em produção

Aplicação depende do addon de deploy ativo:

- **Addon `coolify-ssh`**: ver `addons/coolify-ssh/migrations-prod.md`
- **Addon `vercel`**: migrations via build step ou ferramenta CLI da DB
- **Addon `fly`**: `fly ssh console -C "your-migrate-command"` ou release_command no `fly.toml`
- **Addon `railway`**: release command via dashboard ou CLI
- **`manual`**: você define o processo no runbook do projeto

### Padrões cross-addon

- [ ] Cada migration roda com error-stop (`ON_ERROR_STOP=1` em Postgres, equivalentes em outras DBs)
- [ ] Warnings tipo "already exists, skipping" são OK (migration idempotente)
- [ ] Errors fatais param o deploy — investiga antes de prosseguir
- [ ] Se addon `multi-tenant` ativo: separar migrations globais vs per-tenant (ver `addons/multi-tenant/`)

## 3. Env vars novas

- [ ] Pra cada env nova listada em "Pendências orquestrador" do memory completion
- [ ] Multi-line vars (PEM keys, certs): cuidado com escaping
- [ ] Verificar valor aceito (não vazio, não truncado)
- [ ] Mecanismo depende do addon de deploy ativo

## 4. Trigger deploy

Depende do addon de deploy. Padrão: `git push origin main` deve disparar automaticamente em Vercel/Railway/Fly/Render. Coolify pode requerer API call manual ou ter auto-deploy configurado.

- [ ] Aguarda deploy completar (timeout sensato: 5-15min)
- [ ] Logs do deploy não têm errors

## 5. Container/runtime warm-up

```bash
until [ "$(curl -sS -o /dev/null -w '%{http_code}' https://<dominio>/health)" = "200" ]; do
  sleep 5
done
```

- [ ] Health endpoint responde 200
- [ ] Sem containers/processes em restart loop

## 6. Smoke E2E em prod

Quando addon `e2e-validation` ativo, roda Playwright contra URL prod (não localhost):

- [ ] Golden path passa
- [ ] Edge cases passam
- [ ] Endpoints pré-existentes continuam OK (regressão)
- [ ] Endpoints novos retornam status esperado

Sem `e2e-validation` ativo: smoke manual via `curl` dos endpoints críticos.

## 7. Validação adicional via UI (se aplicável)

Se sprint mexeu em UI, rodar Chrome DevTools MCP ou Playwright contra URL prod:

- [ ] Página carrega sem console errors
- [ ] Componentes visíveis e estilizados
- [ ] Brand consistente

## 8. Atualiza memory

- [ ] Cria `project_sprint_{N}_deploy_{YYYY-MM-DD}.md` (template `templates/memory-deploy.md`)
- [ ] Atualiza state.md (fase=DONE)
- [ ] Linha no MEMORY.md principal do projeto

## 9. Comunicação ao user

- [ ] Estado final: o que entrou no ar + pendências que requerem ação do user
- [ ] Próximos passos sugeridos (próximo sprint? hotfix? config externa que falta?)
- [ ] Sem alarmismo se está tudo OK — confirma sucesso

## 10. Capture learnings

Roda `checklists/capture-learnings.md` — orquestrador proativamente triagia bugs do sprint e propõe adição às bug-patterns da skill. Sem isso, conhecimento se perde e próximos sprints redescobrem o mesmo bug.

---

## Quando algo dá errado

### Container/process em restart loop

Cheque logs imediatamente. Padrões comuns:

- `Missing required env: X` → setar env var
- `permission denied for table` → faltou GRANT em migration (ver `addons/postgres/`)
- `Cannot find module 'X'` → workspace dep mal configurado (ver `addons/monorepo/`)
- `relation X does not exist` → migration não aplicada ou tabela inventada

### Smoke prod falha após deploy verde

- Container healthy mas endpoint quebrado → bug funcional. Fix inline no orchestrator.
- Container restart → boot fail. Veja logs.
- DNS/SSL — raro, verificar proxy/loadbalancer.

### Rollback

Maioria das plataformas mantém versão anterior. Mas se migrations já rodaram, schema mudou:

- Migrations forward-only são mais seguras (não-destrutivas)
- Adicionar > dropar
- Backwards-compatible > breaking changes

Se rollback é necessário e migration foi destrutiva: ver backup do passo 1.
