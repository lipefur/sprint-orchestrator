# Addon: coolify-ssh

## Quando ativar

Deploy via Coolify (self-hosted PaaS) com acesso SSH ao host pra aplicar migrations diretamente.

## Dependências

Nenhuma.

## Detecção automática

Não detecta automaticamente. Selecione o deploy method como `coolify-ssh` no `init.sh`.

## Overrides obrigatórios

```yaml
coolify-ssh:
  host_alias: <ssh-alias>           # alias em ~/.ssh/config (ex: my-vps)
  api_base: https://coolify.example.com
  # COOLIFY_TOKEN vem de env var, NUNCA no profile
```
