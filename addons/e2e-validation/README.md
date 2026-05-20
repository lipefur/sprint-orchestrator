# Addon: e2e-validation

Validação E2E **obrigatória** pra qualquer sprint que mexe em UI. Combina 3 ferramentas, cada uma pra um caso de uso específico.

## Quando ativar

- Projeto tem UI (frontend, dashboard, app)
- Addon `nextjs` (ou similar) ativo no profile
- Explicitamente declarado em `profile.addons: [..., e2e-validation]`

## Dependências

- Pelo menos uma ferramenta MCP de browser disponível no Claude Code:
  - `playwright` MCP (mais comum, padrão)
  - `chrome-devtools` MCP (debug interativo)
  - `Claude in Chrome` extension (fluxos com login real)

## 3 ferramentas, 3 casos

| Ferramenta | Quando usar | Modo |
|---|---|---|
| **Playwright MCP** | Default: script E2E automatizado validando golden path + edge cases. Roda pré-PR e pós-deploy. | Headless, fast, repetível |
| **Chrome DevTools MCP** | Bug visual aparece, precisa investigar console/network/DOM/Lighthouse. | Interativo, debug |
| **Claude in Chrome** | Fluxo requer sessão real do user (login pago, cookies pessoais). | Browser real do user |

Ver detalhes em `playwright-patterns.md` (default) e `alternative-tools.md` (Chrome DevTools + Chrome extension).

## Integração com workflow

**Fase EXECUTE (sprint chat):**
- Sprint chat, ANTES de abrir PR, roda Playwright nos fluxos declarados no campo "Fluxos E2E a validar" do plano
- Se algum fluxo falha: NÃO abre PR, para e atualiza `state.md` com erro

**Fase REVIEW (orchestrator):**
- Roda Playwright de novo (URL local ou staging)
- Se falha: fix inline no orchestrator (não delega)

**Fase DEPLOY (orchestrator):**
- Roda Playwright contra URL de produção
- Se falha: decide rollback ou hotfix inline

Ver `pre-pr-validation.md` pra checklist obrigatório.

## Campo novo no plano

Quando addon ativo, `templates/plan/<tipo>.md` que envolvem UI (feature, bugfix com UI) DEVEM ter:

```markdown
## Fluxos E2E a validar (obrigatório)

1. **Golden path**: <descrição>
2. **Edge case 1**: <descrição>
3. **Edge case 2**: <descrição>
```

`pre-dispatch.md` verifica que esse campo existe e tem ≥1 fluxo.
