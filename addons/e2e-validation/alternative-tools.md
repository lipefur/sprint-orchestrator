# E2E — Ferramentas alternativas ao Playwright

Use Playwright MCP por default (ver `playwright-patterns.md`). Estas alternativas servem casos específicos.

---

## Chrome DevTools MCP — debug interativo

**Quando usar:** bug visual, performance, network falhando, console errors, acessibilidade.

**Tools típicas:**

- `mcp__chrome-devtools__navigate_page` — abre URL
- `mcp__chrome-devtools__take_snapshot` — DOM completo
- `mcp__chrome-devtools__take_screenshot` — screenshot
- `mcp__chrome-devtools__list_console_messages` — logs
- `mcp__chrome-devtools__list_network_requests` — requests
- `mcp__chrome-devtools__lighthouse_audit` — performance/a11y/SEO

**Padrão (bug visual):** `navigate` → `take_screenshot` → `take_snapshot` → `list_console_messages` → identifica causa.

**Padrão (performance):** `performance_start_trace` → executa ação → `performance_stop_trace` → `performance_analyze_insight`.

**Padrão (a11y pré-merge):** `lighthouse_audit` nas páginas afetadas. Score Accessibility ≥ 90, Performance ≥ 80.

---

## Claude in Chrome (extensão) — fluxos com sessão real do user

**Quando usar:** login 2FA com SMS real, fluxo que requer cookies/storage do user, SSO com conta real, paywall com cartão real.

**Tools típicas:**

- `mcp__Claude_in_Chrome__navigate`
- `mcp__Claude_in_Chrome__find` — selector finder DOM-aware
- `mcp__Claude_in_Chrome__computer` — clicks, type, scroll
- `mcp__Claude_in_Chrome__get_page_text`
- `mcp__Claude_in_Chrome__form_input`

**Quando NÃO usar:** automação CI (extension é interativa), testes de cada sprint (overhead alto). Use Playwright como default.

**Atenção:** sessões/cookies são reais. Confirme com user antes de ações irreversíveis (deletar conta, cancelar plano).
