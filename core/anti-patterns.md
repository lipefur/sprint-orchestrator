# Anti-padrões cross-cutting

Bugs e armadilhas que aparecem em **qualquer stack** que adote o workflow de sprints com orquestrador + chats de execução. Aprendidos na dor.

Para anti-padrões stack-specific, ver `addons/<nome>/bug-patterns.md`.

## 1. Hardcoded `localhost:PORT` em código que vai pra container

**Sintoma:** `Failed to load resource: net::ERR_CONNECTION_REFUSED @ http://localhost:PORT/...`

**Causa:** dev escreveu fallback `'http://localhost:PORT'` no código, ficou no bundle final ou no service deployed.

**Fix:**
- Trocar default por URL relativa (`/api/...`) que vai pro mesmo origin
- Ou passar URL completa via env var, NUNCA hardcoded

---

## 2. Porta de service errada em env vars

**Sintoma:** `ConnectionRefused: http://service:PORT`

**Causa:** env var setada com porta diferente da que o service expõe.

**Como detectar:** `grep -E "EXPOSE|PORT" services/X/Dockerfile` vs env do compose.

**Fix:** sincronizar EXPOSE com env var.

---

## 3. Import named errado de módulo Node

**Sintoma:** `SyntaxError: Export named 'X' not found in module 'node:Y'`

**Causa:** import `{ X } from 'node:Y'` mas o módulo exporta só default ou subset diferente.

**Fix:** verificar exports reais:

```typescript
// ERRADO
import { crypto } from 'node:crypto'

// CERTO
import { randomUUID, createHash } from 'node:crypto'
```

---

## 4. License/auth crash on boot em CI

**Sintoma:** `Missing required env: X` → service crasha em loop no CI smoke

**Causa:** sistema estrito por design. CI não tem keys reais.

**Fix:** env bypass específica pra teste, **bem documentada como apenas-test**:

```typescript
if (process.env.APP_TEST_BYPASS_LICENSE === 'true') {
  return mockClaims;  // só pra teste, NUNCA pra produção
}
```

CI workflow seta `<APP>_TEST_BYPASS_<X>=true` no `.env`.

---

## 5. Plano não commitado em main antes do worktree

**Sintoma:** Sprint chat reporta "plano não encontrado" e tenta criar plano novo do zero. Bagunça total.

**Causa:** Orchestrator escreveu plano em working dir do main mas não commitou. Worktree criado a partir do main não tem o plano.

**Fix:** **SEMPRE** commitar plano em main + push ANTES de criar worktree. O script `scripts/create-worktree.sh` valida isso e aborta se plano não tá commitado.

---

## 6. Esquecer de incluir migration nova no CI workflow

**Sintoma:** Migrations estão no PR mas CI ignora. Endpoints novos retornam 500.

**Causa:** Workflow lista migrations a aplicar explicitamente. Sprint adicionou nova mas não atualizou.

**Fix permanente longo-prazo:** trocar lista hardcoded por glob:

```yaml
for DIR in services/auth/migrations/sprint-*/; do
  for f in "$DIR"*.sql; do
    apply "$f"
  done
done
```

**Fix curto-prazo:** orchestrator no `pre-dispatch` check verifica e ADICIONA `sprint-N` ao workflow no MESMO commit que mergeia o sprint anterior.

---

## 7. Sprint chat decidindo trade-off técnico que orchestrator deveria bater

**Sintoma:** Sprint chat acha duas opções equivalentes, escolhe uma silenciosamente, plano fica desalinhado com decisões anteriores.

**Causa:** Plano não cobriu todos os trade-offs. Sprint chat preencheu sozinho.

**Fix preventivo:** plano lista **explicitamente** decisões abertas em seção "Decisões abertas (user decide)". Sprint chat **NÃO** pode resolver essas — para e reporta.

**Fix reativo:** se aconteceu, documenta decisão em handoff doc + atualiza plano via commit no main (sprint chat puxa).

---

## 8. Smoke local passa, smoke prod falha

**Sintoma:** Sprint chat reporta `bin/smoke-local.sh` verde. PR mergeado. Em prod, smoke E2E quebra.

**Causa:** Smoke local não cobre o que muda em prod (URL absoluta, container vs localhost, role diferente, etc.).

**Fix preventivo:** smoke local **DEVE** rodar contra config tipo-prod (container-based, role não-superuser, URLs absolutas). Documenta na própria `bin/smoke-local.sh` que ela aproxima prod.

**Fix reativo:** depois do bug em prod, ADICIONA o cenário ao smoke local. Próximo sprint não cai no mesmo.

---

## 9. Deploy duplicado por múltiplos triggers (webhook + auto-commit + API manual)

**Sintoma:** Plataforma de deploy enfileira 2-4 deploys em sequência após um único PR mergeado. Build/deploy roda múltiplas vezes desperdiçando compute e arriscando race conditions se migrations ou steps env-mutating rodam mais de uma vez.

**Causa:** Três triggers independentes podem disparar pro mesmo evento "publicar esse PR":

1. **Webhook do git host** (GitHub/GitLab → plataforma) dispara em todo push em main
2. **Ferramenta de release automática** (`semantic-release`, `release-please`, etc.) faz um **commit adicional** em main pra bumpar version + CHANGELOG → dispara o webhook de novo
3. **Chamada manual** de `POST /deploy` (ou equivalente CLI) do checklist de deploy adiciona um terceiro

Cada trigger constrói essencialmente o mesmo código, mas a plataforma processa cada um como deploy separado.

**Fix preventivo (escolha uma estratégia):**

- **Single source of truth — só manual**: desliga o webhook automático na plataforma. Deploys só via API/CLI explícita do orchestrator depois que migrations + env vars estão prontos.
- **Webhook only**: mantém webhook automático. Tira o `POST /deploy` do checklist. Configura `semantic-release` com `[skip ci]` no commit message ou roda **antes** do merge.
- **Path filter no webhook** (recomendado com semantic-release): plataforma ignora pushes que só tocam `package.json` + `CHANGELOG.md` (arquivos típicos do auto-commit). Manual deploy continua valendo. Requer plataforma com suporte a path filters.

**Fix reativo (já aconteceu):**

1. **Não cancela deploy rodando** — interromper pode deixar app inconsistente
2. Espera o deploy ativo terminar
3. Cancela os enfileirados na UI da plataforma
4. Valida estado final via health check + smoke E2E
5. Documenta a fonte do trigger usado em `state.md` pra próximo sprint do projeto saber qual estratégia adotar

**Para detalhes stack-specific** (Coolify, Vercel, Fly, Railway, etc.): ver `addons/<nome>/bug-patterns.md`. Coolify documentado em [`addons/coolify-ssh/bug-patterns.md`](../addons/coolify-ssh/bug-patterns.md).

---

## 10. Validação local/preview tratada como validação de prod

**Sintoma:** Fase DEPLOY dada como concluída/validada porque (a) um dev/preview server respondeu, (b) `curl` num endpoint deu 200, ou (c) o comment de preview-validation ficou verde. Mas a **URL de produção nunca foi navegada de verdade** — login real, render, console.

**Causa:** Duas confusões empilhadas:

1. **Fase.** Dev server local e o preview deploy (addon `github-actions/preview-validation`) validam a *mudança* num ambiente efêmero → fase **EXECUTE/REVIEW**, não prod. "Verificar via preview" cobre o local, não o DEPLOY.
2. **Profundidade.** `curl` (mesmo apelidado de "smoke") só prova **liveness** — que o endpoint responde. Não prova login real, render visual, nem console sem erro.

**Fix:** A fase **DEPLOY** só fecha com **Playwright navegado contra a URL de produção** — login real + render + console limpo — **pós-merge e pós-deploy**. Smoke local, preview deploy e `curl` cobrem EXECUTE/REVIEW e **nunca** substituem o smoke de prod. Irmão do #8 (lá o smoke local está mal-configurado; aqui ele está certo mas sendo usado na fase errada).

---

## Como adicionar caso novo

Após cada deploy debug, se descobriu padrão **cross-cutting** (aparece em mais de uma stack):

1. Identifica sintoma (mensagem de erro exata)
2. Causa raiz (1 frase)
3. Fix preventivo + reativo
4. Adiciona seção neste arquivo

Padrões stack-specific (Postgres, Next.js, Coolify, etc.) vão em `addons/<nome>/bug-patterns.md`.
