# Recipes

Real configurations for specific stack combinations. Each recipe is a self-contained guide.

## How to use a recipe

1. Pick the recipe that matches your stack
2. Copy the `.sprint-orchestrator.yml` snippet to your project
3. Follow any setup instructions specific to that stack
4. Run `bash <skill>/scripts/init.sh --force` to merge the profile

## Available recipes

(Empty for now — contributions welcome!)

## How to contribute a recipe

Recipes should answer: **"How do I configure sprint-orchestrator for stack X + Y + Z?"**

Format:

```markdown
# <Stack combination>

> Example: Next.js + Vercel + Supabase

## Profile

\`\`\`yaml
version: 1
project_name: ...
addons: [...]
# ... full profile
\`\`\`

## Specific setup

- What detection signals trigger this stack
- Any manual setup steps
- Common gotchas for this combination

## Sprint examples

What kinds of sprints fit naturally with this stack.

## Bug patterns specific to this combination

If applicable.
```

Submit via PR with file `docs/recipes/<stack>-<deploy>.md`.

## Wanted recipes

If you can write one of these, please do:

- [ ] Next.js + Vercel + Supabase
- [ ] Next.js + Railway + Postgres
- [ ] Remix + Fly.io + Postgres
- [ ] SvelteKit + Cloudflare Pages + D1
- [ ] Astro + Netlify + (any DB)
- [ ] Django + Render + Postgres
- [ ] Rails + Heroku + Postgres
- [ ] Spring Boot + AWS (ECS) + RDS
- [ ] Go + Fly.io + Postgres
- [ ] Elixir/Phoenix + Fly.io + Postgres
- [ ] FastAPI + Railway + Postgres
- [ ] Hono + Cloudflare Workers + D1

Open a [recipe request discussion](https://github.com/lipefur/sprint-orchestrator/discussions/categories/ideas) if your stack isn't listed.
