# Addon: multi-tenant

## Quando ativar

Aplicação multi-tenant com isolamento por schema (Postgres `search_path`) ou por database. Provision functions criam estrutura por tenant.

## Dependências

Requer `postgres`.

## Detecção automática

- Pattern `auth_global`, `proj_management`, ou similar em migrations
- Função SQL `provision_*` em migrations
- Schemas com pattern `proj_*`, `org_*`, `tenant_*`

## Overrides

```yaml
multi-tenant:
  global_schemas: [auth_global, proj_management]   # schemas globais
  tenant_schema_pattern: "proj_*"                  # pattern dos schemas per-tenant
  tenant_role_pattern: "proj_{slug}_owner"         # pattern do role do tenant
```
