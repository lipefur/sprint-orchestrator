# Sprint {{N}} — {{TEMA}}

> Tipo: **feature**
> Data: {{YYYY-MM-DD}}
> Worktree: `{{worktrees_path}}/sprint-{{N}}-{{TEMA_SLUG}}/`
> Branch: `sprint-{{N}}-{{TEMA_SLUG}}`
> Esforço: {{ baixo / médio / alto }}
> Multi-agent: {{ 1 / 2 / 3 / 4 agents paralelos }}
> Lança quando: {{ contexto temporal }}

## Por que esse sprint existe

{{ 1-3 parágrafos — qual problema sendo resolvido, contexto histórico, urgência }}

## Objetivos

1. {{ Objetivo concreto 1 — testável }}
2. {{ Objetivo concreto 2 }}

## Não-objetivos (fora do escopo)

- ❌ {{ Coisa que parece estar no escopo mas não está }}

## Decisões batidas (NÃO refazer)

- {{ Decisão X = valor Y }} ({{ por quê / quando bateu }})

## Fases

### Fase 1 — {{ Nome curto }} ({{ esforço em horas/dias }})

{{ Descrição clara do que entrega + critério de aceitação }}

#### Arquivos novos
```
{{ caminho/arquivo.ts }}
```

#### Arquivos modificados
```
{{ caminho/existente.ts — o que muda }}
```

## Multi-agent strategy

{{ Recomendado: N agents paralelos, zero overlap. }}

### Agent A — {{ Foco }}
- {{ Arquivos owned }}
- {{ Entrega }}

### Agent B — {{ Foco }}
- {{ Arquivos owned }}
- {{ Entrega }}

## Fluxos E2E a validar (obrigatório se addon `e2e-validation` ativo)

1. **Golden path**: {{ Fluxo principal end-to-end }}
2. **Edge case 1**: {{ Cenário menos comum }}
3. **Edge case 2**: {{ Erro esperado, ex: senha errada → 401 amigável }}

Sprint chat executa via Playwright MCP antes de abrir PR.

## Migrations (se aplicável)

```sql
-- {{ caminho/migration.sql }}
{{ SQL com IF NOT EXISTS / DROP IF EXISTS pra idempotência }}
```

## Env vars novas (se aplicável)

```env
{{ NOME=valor_exemplo }}  # {{ propósito }}
```

## Testes esperados (target ≥ N novos)

- {{ Smoke E2E: golden path }}
- {{ Unit: lógica nova }}
- {{ Integration: contrato novo }}

## Critérios de DoD (Definition of Done)

- [ ] Todos objetivos implementados
- [ ] Smoke local passa
- [ ] (Se UI) Playwright dos fluxos E2E passa
- [ ] CI verde
- [ ] 1 PR único, mergeable em main
- [ ] PR description com TLDR + entregas + próximos passos
- [ ] `state.md` atualizado pra fase=REVIEW

## Anti-padrões específicos

- ❌ {{ Padrão específico do sprint }}

## Riscos + mitigações

| Risco | Probabilidade | Mitigação |
|---|---|---|
| {{ Risco X }} | {{ baixa / média / alta }} | {{ mitigação concreta }} |

## Decisões abertas (user decide ANTES de dispatch)

- [ ] {{ Pergunta 1 }} — opções: {{ A / B / C }}

## Pós-sprint

- {{ Próximo sprint dependente }}
- {{ Operacional pós-merge }}
