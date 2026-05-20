# Capture Learnings — pós-deploy

Rode **depois** do sprint mergeado e deployed em prod (final da fase REVIEW+DEPLOY). Objetivo: capturar sistematicamente o que aprendeu nesse sprint e propor adição às bug-patterns da skill.

Sem esse passo, conhecimento se perde. Próximos sprints redescobrem o mesmo bug.

## Auto-detecção: bugs encontrados durante o sprint

Olhe os commits do sprint pra identificar candidatos a bug pattern:

```bash
git log --oneline main --grep="^fix" --since="<DATA_DISPATCH>" | head -10
```

Pra cada commit `fix:`, pergunte:

- [ ] Foi um bug que **outro projeto teria também** com esse stack?
- [ ] A causa raiz é **stack-specific** (ex: peculiaridade do Next.js/Postgres/Hono)?
- [ ] O fix é **reusable** (não específico do nosso código)?

Se 3/3 SIM → **candidato a bug pattern**.

## Triagem dos candidatos

Pra cada candidato:

### 1. Identifique o addon dono

```
Bug em Server Component fetch     → addons/nextjs/bug-patterns.md
Bug de GRANT faltando             → addons/postgres/bug-patterns.md
Bug de middleware Hono vazando    → addons/hono/bug-patterns.md
Bug genérico (qualquer stack)     → core/anti-patterns.md
```

### 2. Estruture o pattern (template)

```markdown
## {{N}}. {{Título curto descritivo}}

**Sintoma:** {{Mensagem de erro exata ou comportamento visível}}

```
{{logs/stack trace/output}}
```

**Causa:** {{1-2 frases explicando "por quê" do bug, não só "o quê"}}

**Quando aparece:** {{contexto — sempre que X, ou só em condição Y}}

**Fix preventivo:**

```{{lang}}
// {{código que evita o bug}}
```

**Fix reativo (se já aconteceu):**

```{{lang}}
// {{código que corrige}}
```

**Caso real observado:** {{Sprint N, commit hash, PR #}} (opcional — útil pra rastrear)
```

### 3. Verifique se já não existe

```bash
grep -i "{{palavra-chave do sintoma}}" addons/{{addon}}/bug-patterns.md
```

Se já tem pattern parecido: **atualiza com novo caso**, não cria duplicado.

### 4. Adiciona ao arquivo

```bash
# Edita addons/{{addon}}/bug-patterns.md, adiciona seção nova
# Commit + push pra main
git add addons/{{addon}}/bug-patterns.md
git commit -m "docs(addons/{{addon}}): add bug pattern from sprint {{N}}"
```

(Esse commit vai pro **repo da SKILL**, não do projeto consumidor. Se a skill é versionada em git separado, faz lá.)

## Learnings cross-cutting

Algumas lições não são "bug pattern" — são meta-aprendizados sobre o workflow:

- "Esse tipo de sprint sempre demora 2x o estimado" → ajusta esforço esperado
- "Multi-agent não funcionou aqui" → revisa critérios de quando usar multi-agent
- "Esse addon precisava de mais detecção" → atualiza init.sh

Captura em `MEMORY.md` do projeto OU em issue na skill upstream.

## Workflow assistido pelo orchestrator

Ao fim de cada deploy bem-sucedido, orchestrator deve **proativamente** perguntar:

> "Sprint {{N}} mergeado e deployed. Olhei os commits e vi {{N}} commits de fix durante o sprint. Vou triar pra ver se algum vira bug pattern reusável:
>
> 1. [bug X] — Stack: Postgres. Caso: NOT NULL + INSERT desatualizado. Já tem pattern parecido em postgres/bug-patterns.md, **atualizo com novo caso**?
> 2. [bug Y] — Stack: Hono. Caso: middleware vaza pra sub-routes. **Pattern novo — adiciono?**
> 3. [bug Z] — Específico do nosso código. **Pulo.**
>
> Aprovar 1, 2, ambos, ou nenhum?"

Você responde, ele aplica.

## Sem comunidade ainda

Hoje, esses bug patterns vão pra **sua própria skill** (versionada no seu git). Não há upstream comunitário.

Quando publicar OSS e tiver tração: workflow vira **abrir PR upstream** com pattern novo, comunidade revisa, mergeia → todo mundo se beneficia.

## Por que vale o esforço

**Sem capture sistemático:**
- Bug X em Sprint 5
- Bug X de novo em Sprint 12 (ninguém lembrou)
- Bug X de novo em Sprint 19 (já é folklore mas não tá escrito)

**Com capture sistemático:**
- Bug X em Sprint 5 → vira pattern em `addons/postgres/bug-patterns.md`
- Sprint 12: orchestrator lê o pattern no pre-dispatch, alerta sprint chat
- Sprint 12: bug não aparece. 30min economizados.
- Multiplica por 10 sprints, 5 projetos = horas de debug evitadas

**Investimento por sprint**: 5-10 minutos.
**Payoff**: composto ao longo do tempo.
