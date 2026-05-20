# Template: `project_sprint_{N}_deploy_{YYYY-MM-DD}.md`

Use **depois** que orchestrator fez merge + deploy + validação em prod. Complementa `project_sprint_{N}_complete.md` com o que aconteceu no deploy real.

Salvar em `{profile.paths.memory}/project_sprint_{N}_deploy_{YYYY-MM-DD}.md`.

---

```markdown
# {{PROJECT_NAME}} Sprint {{N}} deploy completo em prod {{YYYY-MM-DD}}

> Data: {{YYYY-MM-DD}}
> Status: {{O que entrou em prod}}

## O que entrou no ar

- **{{URL/serviço}}**: {{descrição curta}}
- {{Outras entregas visíveis pro user final}}

## Pipeline executado

### 1. Pré-deploy
- {{Backup feito? onde}}
- {{Config externa criada}}
- {{Keys geradas}}

### 2. PR mergeado
- **Commit merge**: `{{HASH}}`
- {{N arquivos, +X/-Y}}
- {{N testes novos}}

### 3. Env vars setadas
- `{{VAR_1}}` = {{tipo de conteúdo}}
- `{{VAR_2}}` = ...

### 4. Migrations em prod
- `{{caminho/migration.sql}}` — {{aplicado idempotente, sem regressão}}

### 5. Bugs descobertos pós-merge (e fixes inline)

| Bug | Causa | Fix |
|---|---|---|
| {{descrição}} | {{causa raiz}} | commit `{{HASH}}` |

(Padrão observado: 1-3 bugs surgem no deploy mesmo com smoke verde)

### 6. Validação prod

| Endpoint/fluxo | Status | Notes |
|---|---|---|
| {{URL X}} | ✅ 200 | {{}} |
| {{Fluxo E2E Y}} | ✅ PASS | {{}} |

Boot logs do service principal:
```
{{Linha relevante 1}}
{{Linha relevante 2}}
```

## Lições aprendidas

1. **{{Lição 1}}** — {{descrição + onde adicionar nas bug-patterns da skill}}
2. **{{Lição 2}}**

## Pendências pós-deploy (não-bloqueantes)

- [ ] {{Coisa que pode ficar pro próximo sprint}}
- [ ] {{Operacional/comunicação pendente}}

## Estado main pós-Sprint {{N}}

```
{{git log --oneline -5}}
```
```
