# Comment format — contrato entre Action e Orquestrador

O GitHub Action posta **um único comment** com formato fixo, delimitado por HTML comments. O orquestrador parseia esse bloco pra decidir próxima ação.

## Formato canônico

```markdown
<!-- SPRINT-ORCHESTRATOR-AUTO-VALIDATION-START -->
## Auto-Validation Result

**Preview URL:** {{PREVIEW_URL}}
**Status:** {{STATUS_EMOJI}} {{STATUS}}
**Duration:** {{TOTAL_SECONDS}}s
**Run ID:** {{GITHUB_RUN_ID}}

### Playwright fluxos

| Fluxo | Status | Tempo |
|---|---|---|
{{ROWS}}

### Console errors (críticos)

```
{{CONSOLE_ERRORS or "Nenhum"}}
```

### Network errors (5xx)

```
{{NETWORK_5XX or "Nenhum"}}
```

### Screenshots

{{SCREENSHOT_LINKS or "N/A"}}

### Logs completos

[GitHub Action run]({{RUN_URL}})

<!-- SPRINT-ORCHESTRATOR-AUTO-VALIDATION-END -->
```

## Parser pro orquestrador

```bash
# Pegar o comment estruturado mais recente
COMMENT=$(gh pr view $PR_NUMBER --json comments -q '.comments[] | select(.body | contains("SPRINT-ORCHESTRATOR-AUTO-VALIDATION-START"))' | tail -1)

# Extrair status
STATUS=$(echo "$COMMENT" | grep "^\*\*Status:\*\*" | sed -E 's/.*Status:\*\* [^ ]+ //')
# STATUS = "PASS" ou "FAIL"

# Extrair preview URL
PREVIEW_URL=$(echo "$COMMENT" | grep "^\*\*Preview URL:\*\*" | sed -E 's/.*Preview URL:\*\* //')
```

## Labels associadas

O Action também aplica uma label:

- `auto-validated` se Status: PASS
- `needs-fix` se Status: FAIL
- `validation-error` se o próprio Action quebrou (preview deploy falhou, Playwright crashou)

Orquestrador pode filtrar PRs por label:

```bash
gh pr list --label "auto-validated" --state open
gh pr list --label "needs-fix" --state open
```

## Múltiplos runs

Se commits novos chegarem no PR, o Action roda de novo. Cada run **edita o comment existente** (não cria novo) pra não poluir o PR.

Implementação no workflow: usa `peter-evans/find-comment` ou similar pra encontrar o comment com marker `SPRINT-ORCHESTRATOR-AUTO-VALIDATION-START` e atualizar.

## Decisões do orquestrador baseadas no comment

```
STATUS = PASS
  ├─ Roda checklist post-pr-review normal
  ├─ Roda adversarial-review (se ativo)
  └─ Se tudo OK: merge

STATUS = FAIL
  ├─ Lê quais fluxos falharam
  ├─ Lê console/network errors
  ├─ Decide:
  │  ├─ Fix inline (bug óbvio, fix simples)
  │  └─ Re-dispatch sprint chat com contexto do erro

STATUS = validation-error
  ├─ Algo quebrou no próprio Action (preview deploy falhou, etc.)
  ├─ Investiga logs do Action
  ├─ Pode ser problema de infra (secret expirado, plataforma fora)
```

## Estabilidade do formato

Esse contrato é **versionado**. Mudanças breaking vão pro `CHANGELOG.md` da skill com `BREAKING CHANGE:`. Comentários antigos com marker antigo continuam parseáveis (sempre olhe `SPRINT-ORCHESTRATOR-AUTO-VALIDATION-START` — esse marker é estável).
