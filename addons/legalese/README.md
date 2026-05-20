# Addon: legalese

## Quando ativar

Sprint vai gerar arquivos com texto legal/regulatório longo (LICENSE full text, Privacy Policy, Terms of Service, Code of Conduct extenso). Esses gatilham o content filter da Anthropic.

## Como `init.sh` detecta

Não detecta automaticamente. Ative manualmente no profile quando souber que o sprint envolve criação de arquivos OSS canônicos.

## Conteúdo

- `content-filter.md` — fontes oficiais (`curl`) pra baixar AGPL, GPL, MIT, Contributor Covenant, etc., evitando que o LLM seja bloqueado tentando gerar texto canônico inline.

## Quando NÃO ativar

Projetos que não publicam código aberto ou docs legais longas — addon dispensável.
