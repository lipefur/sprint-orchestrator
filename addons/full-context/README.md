# Addon: full-context

## Quando ativar

Projeto cabe em ~500k tokens E você usa `context_window: 1m`. Em vez de explorar arquivo-por-arquivo, o sprint chat carrega o repo inteiro filtrado no início do EXECUTE — "vê" a arquitetura toda de uma vez.

## Dependências

Requer `model.context_window: 1m` no profile. Sem efeito em 200k.

## Detecção automática

`init.sh` oferece ativar se o repo (filtrado) couber no limite.

## Como funciona

`load-context.sh` gera um dump do repo excluindo ruído:

- Exclui: `node_modules`, `.git`, `build`, `dist`, `.next`, `target`, `vendor`, lockfiles, binários, imagens, `_legacy`
- Limite de segurança: se o dump estimado passa de ~500k tokens (~2MB de texto), aborta e avisa pra usar exploração incremental

## Uso

```bash
bash <skill>/addons/full-context/load-context.sh > /tmp/repo-context.txt
# Sprint chat lê /tmp/repo-context.txt no início do EXECUTE
```

Override do limite via env:

```bash
FULL_CONTEXT_LIMIT_BYTES=3000000 bash <skill>/addons/full-context/load-context.sh
```

## Trade-off

Carregar tudo gasta contexto upfront mas economiza turnos de exploração. Vale pra repos pequenos/médios em 1m. Repos grandes: deixa incremental (o script aborta sozinho se passar do limite).
