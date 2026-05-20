# Sprint {{N}} — Infra: {{TEMA}}

> Tipo: **infra**
> Data: {{YYYY-MM-DD}}
> Worktree: `{{worktrees_path}}/sprint-{{N}}-{{TEMA_SLUG}}/`
> Branch: `sprint-{{N}}-{{TEMA_SLUG}}`
> Esforço: {{ baixo / médio / alto }}
> Multi-agent: {{ geralmente 1 agent, mas pode ter 2 se CI + Dockerfile separáveis }}

## Motivação

{{ Por que essa mudança de infra — novo workflow CI, otimização Docker, deploy automation, etc. }}

## Escopo: ZERO mudança em código de produto

Infra muda apenas:
- `.github/workflows/*.yml`
- `Dockerfile*`, `docker-compose.yml`
- `bin/*.sh`, `scripts/*.sh`
- `package.json` `scripts`
- Configs de deploy (Coolify env vars via API, Vercel project settings, etc.)

Se precisa mudar código de produto pra suportar nova infra, **abre sprint separado** tipo `feature` ou `refactor`.

## Mudanças

### Workflows CI (se aplica)
```yaml
{{ caminho/workflow.yml — diff descrito }}
```

### Dockerfile (se aplica)
```dockerfile
{{ Mudanças }}
```

### Scripts (se aplica)
```bash
{{ Mudanças }}
```

## Testes da infra

Como validar que a infra nova funciona:

- [ ] CI roda local (act/nektos/docker-based) ou em PR draft
- [ ] Docker build passa: `docker compose build`
- [ ] Smoke roda contra a infra nova: `bin/smoke-local.sh`
- [ ] (Se mexe em workflow) trigger manual do workflow valida

## Rollback plan

Se infra nova quebra:

```bash
{{ revert specific commit / restaurar configs antigas }}
```

## DoD

- [ ] Infra implementada
- [ ] Build/CI passam
- [ ] Smoke local continua passando
- [ ] Documentação atualizada (README/CHANGELOG/runbooks)
- [ ] PR aberto explicando mudança + benefício esperado
- [ ] `state.md` atualizado

## Sem Playwright

Sprints `infra` puro raramente envolvem Playwright (não muda UI). Mas se a mudança afeta deploy ou roteamento, rodar smoke E2E em staging ANTES de mergear pra main.

## Anti-padrões específicos

- ❌ Misturar mudança de infra com mudança de feature (aumenta risco)
- ❌ Atualizar dependências major sem testes adequados
- ❌ Reescrever Dockerfile e mudar logging/config no mesmo PR
- ❌ Desabilitar checks de CI "temporariamente" sem issue rastreando
