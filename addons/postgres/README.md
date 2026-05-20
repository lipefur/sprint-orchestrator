# Addon: postgres

## Quando ativar

Projeto usa PostgreSQL como banco principal. Migrations em SQL puro ou via ORM (Prisma, Drizzle).

## Dependências

Nenhuma.

## Detecção automática

- `prisma/schema.prisma` com `provider = "postgresql"`
- Diretório `migrations/` com arquivos `.sql`
- Service `postgres` em `docker-compose.yml`
- Dependência `pg`, `postgres`, `@prisma/client` em `package.json`

## Overrides

```yaml
postgres:
  superuser_role: postgres        # default
  service_role: <role-name>       # role usado pelo service principal
```
