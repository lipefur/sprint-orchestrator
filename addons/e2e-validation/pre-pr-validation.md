# Pre-PR Validation Checklist

Roda DENTRO da fase EXECUTE, antes do sprint chat abrir PR. Quando addon `e2e-validation` ativo, **substitui parte do checklist genérico de smoke** por validação E2E real.

## Pré-requisito

- Plano tem campo "Fluxos E2E a validar" com ≥1 fluxo declarado
- MCP `playwright` (ou alternativa) disponível
- App está rodando local na URL configurada (ex: `http://localhost:3000`)

## Checklist obrigatório

- [ ] **Aplicação está rodando local**
  - `curl -sf $BASE_URL || echo "App não está no ar"` retorna sucesso
  - Banco de dados/migrations aplicados

- [ ] **Playwright MCP disponível**
  - `ls .claude/mcp/playwright` existe OU MCP tools `mcp__playwright__*` respondem

- [ ] **Golden path passa**
  - Executa script Playwright completo do golden path
  - Result: PASS
  - Screenshots/snapshots anexados se relevante

- [ ] **Edge cases passam (≥1 obrigatório, ≥3 recomendado)**
  - Cada edge case do plano executado
  - Result: PASS pra todos
  - Console sem erros (`mcp__playwright__browser_console_messages` retorna lista vazia ou só warnings benignos)

- [ ] **Network sem 5xx**
  - `mcp__playwright__browser_network_requests` filtrado por `status >= 500` deve ser vazio
  - 4xx em endpoints de erro intencional (login com senha errada → 401) são OK

- [ ] **Performance sanity check (opcional, mas recomendado)**
  - Lighthouse audit nas páginas principais
  - Performance ≥ 70, Accessibility ≥ 90

- [ ] **Bug latente check**
  - Console messages: zero erros JS críticos
  - Screenshot final de cada fluxo bate visualmente com expectativa

## Se algum item falha

1. **NÃO** abrir PR. Sprint chat para.
2. Atualiza `.sprint-orchestrator/state.md` com fase=BLOCKED_E2E + descrição do erro
3. Tenta fix inline (sprint chat pode resolver)
4. Re-roda checklist
5. Se 3 tentativas falham: reportar ao orquestrador (state.md já tá com info), aguardar

## Quando PR é aberto

State.md é atualizado pra fase=REVIEW com link do PR + screenshots dos fluxos passando.

## No review (orchestrator)

Orchestrator roda novamente:
- Os mesmos fluxos contra URL local OU staging
- Confirma resultado bate com o que sprint chat reportou

Se diverge: investiga (talvez ambiente local do sprint chat estava diferente).

## Pós-deploy (orchestrator)

Roda contra URL prod. Falha aqui = rollback ou hotfix inline.
