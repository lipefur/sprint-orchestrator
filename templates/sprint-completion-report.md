# Template: Sprint Completion Report

Use este template **no FIM do sprint chat**, depois de abrir o PR. Preenche, copia o bloco abaixo, cola no chat orquestrador.

Formato fixo pra orquestrador escanear rápido e decidir próximo passo sem reler conversa toda.

---

## Como usar

1. Sprint chat termina implementação + abre PR
2. Copia o bloco entre as `===` abaixo
3. Substitui os placeholders `{{ ... }}` com dados reais
4. Cola no chat orquestrador
5. Orquestrador parseia, decide próximo passo (review / fix / merge / deploy)

---

## Template (copie daqui pra baixo)

```
========================================================================
✅ SPRINT {{N}} CONCLUÍDO — {{TEMA}}
========================================================================

## Status geral
{{ ✅ DONE / ⚠️ DONE_WITH_CONCERNS / ❌ BLOCKED / 🛑 NEEDS_DECISION }}

## Identificação

- **Sprint**: #{{N}} — {{TEMA}}
- **Tipo**: {{ feature / bugfix / refactor / migration / infra }}
- **Branch**: `{{sprint-N-tema-slug}}`
- **Worktree**: `{{caminho/absoluto/do/worktree}}`
- **Commit base**: `{{HASH_INICIAL}}`
- **PR**: #{{NUMERO}} — {{URL_DO_PR}}
- **Tempo gasto**: {{ Xh / X dias }}

## O que foi entregue

### Arquivos novos
- `{{caminho/arquivo-novo.ts}}` — {{1 linha do que faz}}
- ...

### Arquivos modificados
- `{{caminho/existente.ts}}` — {{o que mudou}}
- ...

### Migrations (se aplicável)
- `{{caminho/migration.sql}}` — {{descrição curta}}

### Testes
- {{N}} testes novos / {{M}} modificados
- Cobertura: {{ mantida / aumentada de X% pra Y% }}

## Validação

- [{{X}}] Smoke local (`{{comando}}`) — {{ ✅ PASS / ❌ FAIL }}
- [{{X}}] Playwright E2E ({{ ✅ se addon e2e-validation ativo / N/A senão }})
  - Golden path: {{ ✅ PASS / ❌ FAIL }}
  - Edge case 1 ({{descrição}}): {{ ✅ PASS / ❌ FAIL }}
  - Edge case 2 ({{descrição}}): {{ ✅ PASS / ❌ FAIL }}
- [{{X}}] CI no PR — {{ ✅ verde / ⏳ rodando / ❌ falhou (motivo) }}
- [{{X}}] Adversarial review (se ativo) — {{ ✅ aprovado / ⚠️ N comments pendentes / ❌ bloqueado }}

## Stats

- {{N}} commits
- +{{X}} / -{{Y}} linhas em {{M}} arquivos
- Multi-agent: {{ 1 agent / N agents paralelos — A: X, B: Y }}

## Decisões tomadas durante o sprint

{{ Trade-offs ou escolhas que apareceram e que o orquestrador precisa saber. Lista vazia se nada apareceu. }}

- {{Decisão X}} → {{escolhi Y porque Z}}
- ...

## Bugs encontrados e fixados durante o sprint

{{ Útil pra capture-learnings rodar depois. Lista vazia se nada apareceu. }}

- {{Commit hash}} — {{bug X / fix Y}} — {{stack: postgres? nextjs? cross-cutting?}}
- ...

## Pendências (orquestrador faz)

⚠️ **Itens que dependem de ação humana ou do orquestrador antes do merge/deploy:**

- [ ] {{Setar env var `NOME` em prod (valor exemplo: `...`)}}
- [ ] {{Aplicar migration via `{comando}` em prod}}
- [ ] {{Configurar conta externa (Stripe/email/etc) — instrução: `...`}}
- [ ] {{Outro item}}

(Lista vazia se nada pendente)

## Próximo passo claro pro orquestrador

→ **{{ um dos abaixo }}**:

- `review_and_merge` — PR pronto, sem pendências externas. Revisa e mergeia.
- `review_then_block_for_setup` — PR pronto mas tem pendências (✏ acima). Configura primeiro, depois mergeia.
- `fix_needed` — algo falhou (CI, Playwright, adv-review). Detalhes na seção Validação. Pode fixar inline ou re-dispatchar sprint chat.
- `decision_needed` — apareceu trade-off durante execução que não tava no plano. Detalhes na seção Decisões. Bate decisão antes de prosseguir.
- `blocked_external` — algo fora do meu controle bloqueou (API externa fora, infra falhando, etc). Não consegui terminar.

## Notas opcionais

{{ Qualquer contexto adicional que orquestrador deveria saber. Apague se não tiver nada. }}

========================================================================
```

---

## Como o orquestrador deve responder

Quando você (sprint chat) cola esse relatório no chat orquestrador, ele vai:

1. **Parsear o `Status geral` + `Próximo passo claro`** — decide ação imediata
2. **Confirmar Validação** — re-roda checks rápidos via `gh pr view`, `gh run list`
3. **Triagiar Pendências** — executa o que pode (env vars, migrations) e marca o que precisa decisão humana
4. **Consultar `checklists/post-pr-review.md`** — passo a passo formal
5. **Rodar `checklists/capture-learnings.md`** se tiver bugs na lista

Se algo ficou ambíguo no relatório, orquestrador pode te perguntar de volta — mas o ideal é o relatório ser self-contained o suficiente pra ele agir sem precisar reler a conversa do sprint.

## Anti-padrões a evitar no relatório

- ❌ Marcar tudo como ✅ sem ter rodado os checks (relatar falso PASS gera bugs em prod)
- ❌ Pendências vagas tipo "alguém precisa configurar Stripe" — específica qual env var, qual valor
- ❌ Omitir bugs encontrados durante o sprint — eles têm valor histórico (viram bug patterns)
- ❌ Próximo passo "depende" — sempre escolha um dos status concretos
- ❌ Não incluir o link do PR — orquestrador precisa pra rodar `gh pr view`

## Variação curta (sprints simples)

Pra sprints muito pequenos (bugfix trivial, doc fix), uma versão enxuta serve:

```
========================================================================
✅ SPRINT {{N}} CONCLUÍDO — {{TEMA}}
========================================================================

PR: #{{N}} {{URL}}
Tipo: {{tipo}}
Branch: `{{branch}}`

Resumo: {{1 frase do que foi feito}}

Validação:
- Smoke local: ✅ PASS
- CI: ✅ verde
- {{Outros checks específicos}}

Pendências: nenhuma (ou lista curta)

Próximo passo: review_and_merge
========================================================================
```

Use só pra sprints pequenos. Quando há trade-offs, multi-agent, bugs encontrados, ou pendências reais — usa o formato completo acima.
