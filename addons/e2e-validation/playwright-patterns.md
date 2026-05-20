# Playwright MCP — Padrões de uso

## Setup mínimo

A skill assume que MCP `playwright` está disponível. Tools típicas:

- `mcp__playwright__browser_navigate` — abre URL
- `mcp__playwright__browser_click` — clique em selector
- `mcp__playwright__browser_fill_form` — preenche campos
- `mcp__playwright__browser_take_screenshot` — screenshot
- `mcp__playwright__browser_snapshot` — DOM snapshot (mais leve que screenshot)
- `mcp__playwright__browser_wait_for` — espera condição (texto aparece, URL muda)
- `mcp__playwright__browser_console_messages` — lê console (erros JS)

## Pattern 1: Golden path

Cada sprint declara o "caminho feliz" — fluxo principal end-to-end. Script Playwright valida:

```typescript
// Pseudocódigo do que sprint chat executa via MCP

await browser_navigate(`${BASE_URL}/login`)
await browser_fill_form({ email: 'test@example.com', password: '...' })
await browser_click('button[type="submit"]')
await browser_wait_for({ text: 'Dashboard' })   // confirma redirect
await browser_navigate(`${BASE_URL}/projects/new`)
await browser_fill_form({ name: 'Test Project' })
await browser_click('button:has-text("Criar")')
await browser_wait_for({ text: 'Test Project' })  // confirma criação
```

Sprint chat ROUTE_SCRIPT — pode estar inline no plano ou em arquivo `e2e/sprint-N.spec.ts`.

## Pattern 2: Edge cases

Pra cada feature, 1-3 edge cases. Exemplos:

```typescript
// Login com senha errada → mensagem clara, sem 500
await browser_fill_form({ password: 'wrong' })
await browser_click('button[type="submit"]')
await browser_wait_for({ text: 'Senha incorreta' })   // não pode ter "500" ou "Internal Server Error"

// Console limpa (sem JS errors)
const msgs = await browser_console_messages()
const errors = msgs.filter(m => m.type === 'error')
if (errors.length > 0) throw new Error(`Console errors: ${JSON.stringify(errors)}`)
```

## Pattern 3: Smoke prod pós-deploy

Após merge + deploy, orquestrador roda Playwright contra URL prod:

```typescript
const BASE_URL = 'https://app.example.com'   // URL prod do profile
// Repete golden path + 1-2 edge cases críticos
```

Falha = decisão rollback ou hotfix inline.

## Quando NÃO usar Playwright

- Login que requer 2FA com SMS real → use `Claude in Chrome` extension
- Fluxo que requer arquivo específico do disco do user → use extension
- Bug específico de console/network → use Chrome DevTools MCP

## Timeout sensato

- Cada `wait_for`: 10s default, 30s pra ações lentas (build, deploy preview)
- Cada `browser_navigate`: 15s
- Total por fluxo: <2min — se passa disso, fluxo está mal escrito ou app está lento

## Flaky tests

Se um teste falha intermitentemente:

1. Roda 3x; se 2/3 passam, é flaky
2. Remove do bloqueante; abre issue separada pra fix
3. NÃO bloqueia sprint por teste flaky
4. Documenta no `state.md` ("teste X removido temporariamente — issue #Y")

## Output esperado

Cada fluxo executado retorna:
- ✅ PASS (todos asserts ok)
- ❌ FAIL (assert específico, screenshot anexado, erros console anexados)
- ⏱️ TIMEOUT (qual passo, screenshot anexado)
