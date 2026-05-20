# Addon: docs-public

## Quando ativar

Projeto publica documentação pública (developer docs, marketing site, knowledge base). Conteúdo pode acidentalmente vazar info sensível (SQL DML interno, comandos ops, tokens).

## Dependências

Nenhuma.

## Detecção automática

- Diretórios `docs/`, `docs/landing/`, `docs/public/`, `website/`, `marketing/` com >5 arquivos `.html`/`.md`/`.mdx`
