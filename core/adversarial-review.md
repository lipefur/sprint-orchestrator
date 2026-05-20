# Adversarial Review — segundo par de olhos

Quando o sprint chat termina e abre PR, **antes** do orquestrador revisar manualmente, dispatcha um **terceiro Claude isolado** como reviewer adversarial. Esse Claude:

- **Não tem o contexto** da implementação (zero memória do sprint chat)
- Recebe **só o PR diff + plano original** como input
- Tem prompt explícito de **encontrar problemas** (não de aprovar)
- Posta comments no PR via `gh pr review`
- Orquestrador (humano + Claude) decide aceitar/rejeitar cada comment

**Resultado:** humano vira **arbitrador**, não reviewer linha-por-linha. Você só intervém quando os dois Claudes (implementer + adversarial reviewer) discordam.

## Quando ativar

Por default: **todo sprint** de tipo `feature`, `bugfix`, `refactor` que toca código de produto. Tipos `infra` e `migration` podem pular se for trivial.

Configure no profile:

```yaml
adversarial_review:
  enabled: true                 # default true
  skip_types: []                # ex: [infra] pra pular sprints de infra
  reviewer_model: sonnet        # opus pra sprints críticos, sonnet default
  max_comments: 8               # limite pra não poluir PR
```

## Prompt template pro reviewer Claude

Salva como arquivo temp e passa pro Claude via dispatch (ou via `gh pr review --body-file`):

```markdown
Você é um **adversarial code reviewer**. Sua missão é encontrar problemas que o implementer perdeu.

## Contexto

- **Plano original**: {{PLAN_PATH}} (lê o arquivo)
- **PR diff**: {{PR_URL}} (usa `gh pr diff {{PR_NUMBER}}`)
- **Tipo de sprint**: {{TYPE}} (feature/bugfix/refactor/migration/infra)
- **Addons ativos**: {{ADDONS}}

## Sua mentalidade

Você é **adversarial**, não cooperativo. O implementer **já achou que tá bom**. Você precisa achar o que ele perdeu.

Foco em:

1. **Bugs sutis** — race conditions, edge cases não cobertos, lógica invertida
2. **Anti-padrões** específicos dos addons ativos (consulta `addons/<X>/bug-patterns.md`)
3. **DoD não cumprido** — algum critério do plano não foi atendido?
4. **Over/underbuild** — implementou mais ou menos do que o plano pedia?
5. **Testes fracos** — testes que mockam demais, ou não testam o que importa
6. **Segurança** — credenciais expostas, queries sem sanitização, auth bypass acidental
7. **Performance** — N+1 queries, fetch desnecessário, loops O(n²)

**NÃO se preocupe com:**

- Estilo/formatação (lint pega isso)
- Naming subjetivo (só se for genuinamente confuso)
- "Could be cleaner" sem problema concreto

## Output format

Pra cada problema encontrado:

```
[severity: critical|high|medium|low] file.ts:linha
Problema: <descrição em 1 frase>
Por quê é problema: <1-2 frases>
Sugestão: <fix concreto, código se aplicável>
```

Limite: máximo {{MAX_COMMENTS}} comments. Prioriza critical > high > medium > low.

Se **nenhum problema crítico/high** encontrado, retorna:

```
✅ Adversarial review passed. {{N}} medium/low observations below for consideration.
```

## Submission

Posta via:

```bash
gh pr review {{PR_NUMBER}} --request-changes --body-file /tmp/adversarial-review.md
```

(Use `--comment` em vez de `--request-changes` se só tem medium/low.)
```

## Workflow integrado

### 1. Sprint chat termina, abre PR

(Já existente — Fase EXECUTE termina com PR aberto e state.md atualizado pra fase=REVIEW.)

### 2. Orquestrador detecta PR aberto

(Via scheduled task OU via preview-validation comment OU manual.)

### 3. Orquestrador dispatcha adversarial reviewer

Antes de revisar manualmente:

```bash
# Pseudo-código do que orchestrator executa
PR_NUMBER=$(gh pr list --head sprint-N-tema --json number -q '.[0].number')
PLAN_PATH=$(.sprint-orchestrator/state.md grep "Plano:")
ADDONS=$(yq '.addons' .sprint-orchestrator.yml)

# Dispatch Claude reviewer isolado (subagent ou nova sessão)
# Passa o prompt acima interpolado
# Reviewer roda gh pr diff, lê plano, lê bug-patterns dos addons
# Posta gh pr review com comments
```

### 4. Orquestrador lê os comments do reviewer

```bash
gh pr view $PR_NUMBER --json reviews
```

### 5. Triagem dos comments

Pra cada comment do adversarial reviewer:

- **critical/high**: fix obrigatório antes de mergear. Orchestrator fixa inline OU manda sprint chat fixar.
- **medium**: decide caso a caso. Fix se trivial.
- **low**: documentar como tech debt se não for fixar.
- **falso positivo**: rejeita explicitamente com reply no comment ("Não aplica porque X").

### 6. Re-roda reviewer (opcional)

Após fixes, pode rodar reviewer de novo. Se passa: merge.

## Padrão N-Claude consensus (avançado)

Pra sprints críticos (deploy em prod sensível, mudança de schema, mexer em billing), dispatch **3 reviewers paralelos** com mesma prompt mas modelos/seeds diferentes:

- Reviewer A: Sonnet
- Reviewer B: Sonnet (seed diferente)
- Reviewer C: Opus

**Comment só vira "actionable" se 2/3 reviewers apontaram**. Reduz noise, mantém sinal.

## Por que funciona

Implementer Claude tem **viés de aprovação** — escreveu o código, naturalmente acha que tá bom. Adversarial Claude tem **viés oposto explícito** — busca problemas. Os dois vieses se cancelam, sobra sinal de qualidade.

Diferente de "Claude revisa o próprio código" (que tem viés acumulado). É mais próximo de **pair review humano**, mas escalável e barato.

## Custo

- 1 dispatch extra por PR
- ~10-20k tokens (lê diff + plan + bug-patterns)
- Custo: ~$0.03-0.10 por sprint em Sonnet
- ROI: cada bug crítico evitado vale 30min-2h de debug em prod

## Limites

- Reviewer pode ser **muito paranóico** — gera noise. Ajusta `max_comments` no profile pra forçar priorização.
- Reviewer não substitui **testes E2E reais** (Playwright). Complementa.
- Sprints **infra-only** ou **doc-only** dispensam — overhead > benefício.
