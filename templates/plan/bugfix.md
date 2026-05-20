# Sprint {{N}} — Bugfix: {{TEMA}}

> Tipo: **bugfix**
> Data: {{YYYY-MM-DD}}
> Worktree: `{{worktrees_path}}/sprint-{{N}}-{{TEMA_SLUG}}/`
> Branch: `sprint-{{N}}-{{TEMA_SLUG}}`
> Esforço: {{ baixo / médio }}
> Multi-agent: 1 agent (bug fixes raramente paralelizam bem)
> Lança quando: ASAP — bugs ativos têm prioridade

## Sintoma do bug

{{ Mensagem de erro exata + stack trace + onde aparece }}

```
{{ logs / stack trace }}
```

## Causa raiz

{{ 1-2 parágrafos explicando o "por quê" do bug }}

## Reprodução

```bash
{{ Passos pra reproduzir local }}
```

Expected (incorreto): {{ comportamento atual buggy }}
Expected (correto): {{ comportamento desejado }}

## Fix proposto

{{ 1 parágrafo — qual a mudança }}

### Arquivos modificados
```
{{ caminho/arquivo.ts:linha — o que muda }}
```

### Arquivos novos (se aplicável)
```
{{ caminho/teste-novo.ts — teste de regressão }}
```

## Fluxos E2E de regressão (se UI envolvida)

1. **Cenário do bug original**: {{ exatamente o que disparava o bug, agora deve passar }}
2. **Cenário relacionado**: {{ fluxo similar pra garantir que não quebra }}

## Teste de regressão obrigatório

```typescript
test('{{ bug não recorre }}', () => {
  // Reproduz o cenário do bug
  // Confirma o resultado correto
})
```

## DoD

- [ ] Fix implementado
- [ ] Teste de regressão escrito + passa
- [ ] (Se UI) Playwright fluxo passa
- [ ] Outros testes existentes não quebram
- [ ] PR aberto com link pro issue/relato original
- [ ] `state.md` atualizado

## Risco de regressão

| Área que pode quebrar | Probabilidade | Mitigação |
|---|---|---|
| {{ Feature X (próxima do fix) }} | {{ baixa / média }} | {{ rodar testes específicos / smoke }} |

## Hotfix vs Sprint normal

{{ Marcar se é hotfix urgente (deploy direto pós-merge) vs sprint normal (entra no próximo release) }}
