# Content Filter Workarounds

Lição do Sprint 12: o **content filter da Anthropic** pode bloquear respostas LLM que tentam gerar textos longos com legalese, mesmo legítimos (licenses, códigos de conduta).

Sintoma:
```
API Error: 400 {"type":"error","error":{"type":"invalid_request_error",
"message":"Output blocked by content filtering policy"}}
```

**NÃO é problema do prompt** — o filter tem falso positivo em padrões de texto longo de tom legal/regulatório.

## Solução: baixar da fonte canônica via curl

Em vez de pedir LLM pra gerar texto canônico, baixe da fonte oficial:

### Licenças OSS

```bash
# AGPL-3.0
curl -fsSL https://www.gnu.org/licenses/agpl-3.0.txt -o LICENSE

# GPL-3.0
curl -fsSL https://www.gnu.org/licenses/gpl-3.0.txt -o LICENSE

# MIT (curto, LLM consegue gerar)
echo "MIT License

Copyright (c) $(date +%Y) {nome}

[texto MIT padrão]" > LICENSE

# Apache 2.0
curl -fsSL https://www.apache.org/licenses/LICENSE-2.0.txt -o LICENSE

# BSL 1.1
curl -fsSL https://mariadb.com/bsl11/ -o LICENSE
# ou
curl -fsSL https://github.com/maxmind/MaxMind-DB-Spec/raw/main/LICENSE -o LICENSE.template

# AGPL-3.0 com fallback (caso gnu.org caia)
curl -fsSL https://raw.githubusercontent.com/wiki/zenorocha/agpl/agpl-3.0.txt -o LICENSE
```

### Code of Conduct

```bash
# Contributor Covenant 2.1
curl -fsSL https://www.contributor-covenant.org/version/2/1/code_of_conduct/code_of_conduct.md -o CODE_OF_CONDUCT.md

# Contributor Covenant 2.0
curl -fsSL https://www.contributor-covenant.org/version/2/0/code_of_conduct/code_of_conduct.md -o CODE_OF_CONDUCT.md
```

### Termos legais customizados

Pra LICENSE-COMMERCIAL.md, PRIVACY-POLICY.md, TERMS-OF-SERVICE.md que **não são canônicos** (são específicos do projeto), você pode:

1. **Escrever conteúdo curto e original** (LLM consegue) — funciona pra ~3-5KB de texto
2. **Usar template + placeholders** que o user preenche
3. **Pedir advogado** se for legal vinculante (mas isso é estratégia, não skill)

## O que pode dar trigger (evitar gerar inline)

| Tipo de texto | Tamanho típico | Pode dar trigger? |
|---|---|---|
| LICENSE AGPL/GPL full text | 30-35KB | 🔴 quase sempre |
| MIT/ISC LICENSE | 1KB | 🟢 nunca |
| Contributor Covenant 2.1 | 5KB | 🟡 às vezes |
| Privacy Policy boilerplate | 10-30KB | 🔴 às vezes |
| Terms of Service boilerplate | 10-30KB | 🔴 às vezes |
| CONTRIBUTING.md (original PT-BR/EN) | 2-5KB | 🟢 nunca |
| SECURITY.md (original) | 1-2KB | 🟢 nunca |

**Regra:** se vai escrever texto >5KB com tom legal/regulatório, **busca fonte canônica primeiro** antes de gerar.

## Como integrar no workflow do sprint chat

No prompt de dispatch, adicione anti-padrão:

```
❌ Gerar inline textos legais longos (LICENSE full text, etc) — 
   content filter Anthropic bloqueia; baixar via curl da fonte oficial
   (gnu.org, contributor-covenant.org, opensource.org)
```

E reference este arquivo:

```
Ver references/content-filter-workarounds.md pra fontes oficiais
```

## Recuperação se filter dispara

1. Identifica o arquivo que gerou trigger (provavelmente LICENSE ou Code of Conduct)
2. **Não tenta de novo** — vai bloquear de novo
3. **Orchestrator (você) baixa via curl** no shell direto
4. Cria os outros arquivos curtos inline (CONTRIBUTING, SECURITY, CODEOWNERS)
5. Commit + continua o sprint

## Caso real observado

Sprint que criava arquivos OSS bloqueado várias vezes tentando gerar AGPL-3.0 full text. Orchestrator resolveu inline:

```bash
curl -fsSL https://www.gnu.org/licenses/agpl-3.0.txt -o LICENSE       # 34KB
curl -fsSL https://www.contributor-covenant.org/.../code_of_conduct.md \
  -o CODE_OF_CONDUCT.md                                                # 5KB

# Resto dos arquivos curtos: criados direto com Write tool (curtos, originais)
Write CONTRIBUTING.md   # 2KB
Write SECURITY.md       # 1KB
Write CODEOWNERS        # <1KB
```

Total: ~10min vs 1h tentando reabrir agent várias vezes.
