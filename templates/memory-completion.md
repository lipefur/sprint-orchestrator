# Template: `project_sprint_{N}_complete.md`

Use no FIM do sprint chat (Fase EXECUTE). Salvar em `{profile.paths.memory}/project_sprint_{N}_complete.md`.

E adicionar linha referenciando no MEMORY.md principal.

---

```markdown
# {{PROJECT_NAME}} Sprint {{N}} — {{TEMA}} completo {{YYYY-MM-DD}}

> Data: {{YYYY-MM-DD}}
> Status: PR #{{PR_NUMBER}} aberto / mergeado
> Branch: `sprint-{{N}}-{{TEMA_SLUG}}` (deletada após merge)
> Worktree: `{{profile.paths.worktrees}}/sprint-{{N}}-{{TEMA_SLUG}}` (limpa após merge)

## O que foi entregue

### Backend (se aplicável)
- {{Bullets de arquivos + funções}}
- {{N testes novos}}

### Frontend (se aplicável)
- {{...}}

### Migrations (se aplicável)
- `{{caminho/migration.sql}}`

### Outros
- {{Docs, configs, CI, infra}}

## Stats

- {{N commits, +X/-Y linhas, M arquivos}}
- {{Testes novos: N}}
- {{Cobertura mantida/aumentada}}

## Validação E2E (se addon `e2e-validation` ativo)

- [ ] Golden path: PASS
- [ ] Edge cases: PASS
- Screenshots/snapshots: {{path se relevante}}

## Decisões batidas durante o sprint

- {{Decisão técnica X = Y porque Z}}

(Diferente das decisões batidas no PLANO — aqui é o que apareceu durante execução)

## Bugs encontrados e fixados durante sprint

{{Se houver — bom pra próximas sprints aprenderem. Vão pra `addons/<X>/bug-patterns.md` da skill se forem stack-specific.}}

## Pendências (orchestrator faz)

- [ ] {{Setar env var X em prod}}
- [ ] {{Aplicar migration sprint-{{N}} em prod}}
- [ ] {{Configurar conta externa Y}}
- [ ] {{Smoke prod pós-deploy}}

## Próximos passos sugeridos

- {{Sprint dependente}}
- {{Hotfix futuro se descobriu débito}}
- {{Refactor oportuno em outro sprint}}

## Lições aprendidas

{{Coisas que vão pra `core/anti-patterns.md` (se cross-cutting) ou `addons/<X>/bug-patterns.md` (se stack-specific)}}
```

---

## Como adicionar entrada no MEMORY.md principal

```markdown
- [{{PROJECT_NAME}} Sprint {{N}} — {{tema}} {{YYYY-MM-DD}}](project_sprint_{{N}}_complete.md) — {{1 linha: PR #N mergeado, o que entregou, pendências críticas}}
```

Mantenha a linha curta (≤ 1 parágrafo). Detalhes ficam no arquivo separado.
