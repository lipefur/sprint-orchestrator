# Sprint {{N}} — Migration: {{TEMA}}

> Tipo: **migration**
> Data: {{YYYY-MM-DD}}
> Worktree: `{{worktrees_path}}/sprint-{{N}}-{{TEMA_SLUG}}/`
> Branch: `sprint-{{N}}-{{TEMA_SLUG}}`
> Esforço: {{ baixo / médio }}
> Multi-agent: geralmente 1 agent (migrations têm ordem rígida)

## Motivação

{{ Por que essa migration — nova tabela, índice de performance, normalização, denormalização, etc. }}

## Schema antes / depois

### Antes
```sql
{{ DDL atual }}
```

### Depois
```sql
{{ DDL alvo }}
```

## Migration SQL

```sql
-- {{ Path: services/X/migrations/sprint-{{N}}/01_descritivo.sql }}

-- IDEMPOTENTE: roda 2x sem erro
{{ ALTER / CREATE / DROP com IF EXISTS / IF NOT EXISTS }}

-- GRANT pro role de service (não esqueça)
GRANT SELECT, INSERT, UPDATE, DELETE ON {{schema.tabela}} TO {{role_name}};
```

## Backfill (se aplicável)

Pra colunas NOT NULL adicionadas a tabelas com dados existentes:

```sql
-- Backfill antes de SET NOT NULL
UPDATE {{tabela}} SET {{coluna}} = {{valor_default}} WHERE {{coluna}} IS NULL;
ALTER TABLE {{tabela}} ALTER COLUMN {{coluna}} SET NOT NULL;
```

## INSERTs no código que precisam atualizar

⚠️ **Crítico** — coluna nova NOT NULL quebra INSERTs existentes.

```bash
grep -rE "INSERT INTO {{tabela}}" services/*/src/
```

Pra cada match, atualizar INSERT incluindo a coluna nova OU definir DEFAULT na migration.

## Reversão (rollback plan)

Se a migration der problema em prod:

```sql
-- Rollback SQL
{{ ALTER TABLE ... DROP COLUMN }}
{{ DROP TABLE IF EXISTS ... }}
```

⚠️ Migrations forward-only são mais seguras (não destrutivas) — preferir adicionar e abandonar sobre dropar.

## Aplicação em prod

```bash
{{ Comandos do addon de deploy ativo, ex: ssh + docker exec psql }}
```

## DoD

- [ ] Migration SQL idempotente
- [ ] Aplica local sem erro
- [ ] GRANTs incluídos
- [ ] INSERTs no código atualizados (se NOT NULL)
- [ ] Testes que tocam a tabela continuam passando
- [ ] CI smoke aplica a migration (workflow lista o sprint-N)
- [ ] PR aberto com migration + código + atualização do CI workflow
- [ ] `state.md` atualizado
- [ ] Plano de aplicação em prod documentado

## Anti-padrões específicos

- ❌ Migration não-idempotente (sem IF EXISTS)
- ❌ Esquecer GRANT pro role do service
- ❌ NOT NULL sem backfill + sem DEFAULT
- ❌ Esquecer de adicionar sprint-N ao workflow de CI

## Sem UI / sem Playwright

Migrations puras não precisam de Playwright. Mas se o endpoint que consome a tabela é exposto via UI, sprint subsequente DEVE rodar E2E.
