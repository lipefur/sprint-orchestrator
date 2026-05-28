# Multi-Agent Strategy

Quando dispatchar 1, 2, 3 ou 4 agents paralelos dentro do sprint chat.

## "Agent" depende do modo

- **Modo split**: cada "agent" pode ser um chat separado OU um subagent dentro do sprint chat.
- **Modo monolithic**: "agents" são **subagents** (Task tool) dispatchados pelo mesmo chat. Execução é inline por default; dispatcha subagent só quando há áreas disjuntas que ganham com paralelismo real.

A matriz de decisão abaixo (quando usar N agents) vale igual nos dois modos — muda só o mecanismo (chat vs subagent).

## Matriz de decisão

| Complexidade | Agents | Risco overlap |
|---|---|---|
| Trivial (typo/doc curta) | 0 — fix inline no orchestrator | n/a |
| Pequeno (1 feature simples, 2-6h) | 1 | nenhum |
| Médio (backend OU frontend, 1-2 dias) | 2 paralelos | baixo |
| Alto (backend + frontend + docs, 2-4 dias) | 3 | médio |
| Muito alto (4+ áreas independentes) | 4 | alto |

⚠️ **Mais de 4 agents = sprint mal escopado.** Quebra em 2 sprints menores.

## Princípio: zero overlap de arquivos

Cada agent **owns** um conjunto de arquivos. Outros agents **não podem editar** esses arquivos. Conflito = re-orquestrar.

### Padrões de divisão válidos

**Por subsistema:**
```
Agent A — Backend (services/*)
Agent B — Frontend (apps/*)
Agent C — Docs (docs/*, README)
Agent D — Infra (.github/, docker-compose, scripts)
```

**Por capability técnica:**
```
Agent A — Migrations + DB schema
Agent B — License/auth system
Agent C — Tests + CI
```

**Por fluxo do user:**
```
Agent A — Signup + onboarding
Agent B — Dashboard projetos
Agent C — Admin views
```

## Contratos de sincronização

Quando agents consomem output uns dos outros, **defina contrato no plano** (não negocia em runtime):

### API contract
```
Agent A entrega: POST /api/v1/X → 201, body: {jwt: string, expires_at: string}
Agent B consome: fetch /api/v1/X → renderiza form com response
```

### Type/schema
```
Agent A define em types.ts: export interface Y { ... }
Agent B/C importam: import type { Y } from './types.ts'
```

### Order
```
Agent A → migrations (primeiro)
Agent B/C → código que usa as tabelas (depois)
```

Use `sequence` quando aplicável: sprint chat dispatch A, espera, dispatch B+C.

## Quando NÃO dividir em multi-agent

- Sprint mexe em **arquivo único** (refactor de um service)
- Dependência forte entre arquivos (A bloqueia B bloqueia C)
- Coordenação custaria mais que paralelismo (sprint <4h)
- Domínio que o sprint chat ainda está descobrindo — linear primeiro

## Anti-padrões observados

| Anti-padrão | Fix |
|---|---|
| Multi-agent sem contratos claros | Plano lista contratos explícitos (endpoints, types, ordem) |
| Multi-agent quando 1 funcionaria | Se sprint <2 dias, usa 1 agent |
| Mesmos arquivos owned por múltiplos agents | Cada arquivo tem 1 owner explícito no plano |
| Agent C esperando A+B sem timeout | Sprint chat dispatch em fases sequenciais se há dependência |

## Mensageria entre agents

90% dos casos não precisa. Contratos no plano + arquivos disjuntos resolvem. Quando precisa:

- **Comentários inline no PR draft** (raro)
- **Arquivo `.sprint-status.md`** compartilhado (não-commitado)
- **Convenção:** Agent B só começa depois que Agent A push commit X

## Modelo recomendado

| Agents | Modelo | `think hard`? |
|---|---|---|
| 1 | Sonnet médio | só se arquitetura crítica |
| 2-3 | Sonnet médio | sim, se trade-offs sendo decididos |
| 4 | Sonnet médio | sim — overhead de orquestração |

Opus raramente vale o custo. Sonnet 4.6+ dá conta de 95% dos sprints.
