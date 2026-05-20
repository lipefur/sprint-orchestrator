# Sprint {{N}} — Refactor: {{TEMA}}

> Tipo: **refactor**
> Data: {{YYYY-MM-DD}}
> Worktree: `{{worktrees_path}}/sprint-{{N}}-{{TEMA_SLUG}}/`
> Branch: `sprint-{{N}}-{{TEMA_SLUG}}`
> Esforço: {{ médio / alto }}
> Multi-agent: 1 agent linear (refactor cross-cutting raramente paralelizável)

## Motivação

{{ Por que refactor — débito acumulado, performance, manutenibilidade, prep pra feature futura }}

## Garantia: ZERO mudança de comportamento

Refactor não muda nada que o user observa. Todos os testes existentes passam SEM modificação.

Se algum teste precisa mudar pra passar com o refactor, **não é mais refactor — é mudança de feature**. Reescreve plano.

## Antes / Depois

### Antes
```
{{ estrutura/código atual — descrição ou snippet }}
```

### Depois
```
{{ estrutura/código novo — descrição ou snippet }}
```

## Estratégia

{{ Como manter zero behavior change durante refactor }}

- Mover código sem mudar lógica
- Renomear sem mudar contrato externo
- Extrair funções/classes mantendo interface pública igual
- Se precisa mudar contrato: marca como "PHASE 2" e faz em sprint separado

## Arquivos afetados

```
{{ Lista — incluindo movimentações }}
{{ origin/file.ts → new/path/file.ts }}
```

## Testes de regressão obrigatórios

Todos os testes existentes nos arquivos afetados (e seus consumers) PRECISAM passar sem modificação:

```bash
{{ comando que roda os testes relevantes }}
# Expected: tudo passa, mesma cobertura/tempo
```

## DoD

- [ ] Refactor implementado
- [ ] Testes existentes passam SEM modificação (exceto imports/paths)
- [ ] Smoke local passa
- [ ] (Se UI) Playwright dos fluxos críticos passa idêntico ao antes
- [ ] CI verde
- [ ] PR aberto explicando refactor + linking PRs anteriores que motivaram
- [ ] `state.md` atualizado

## Anti-padrões específicos de refactor

- ❌ Misturar refactor com mudança de feature no mesmo PR
- ❌ "Aproveitar pra arrumar bug X" durante refactor — abre sprint separado
- ❌ Renomear coisas públicas (APIs, exports) sem deprecation strategy
- ❌ "Otimizar performance" durante refactor — vira sprint de perf

## Risco

Refactor tem risco baixo se behavior change = 0, mas atinge MUITOS arquivos. Mitigações:
- Pequenos commits incrementais (não 1 commit gigante)
- Sprint chat valida testes a cada commit
- Se algum teste quebra: rollback do último commit, investiga
