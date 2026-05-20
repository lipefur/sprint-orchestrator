# Contributing to sprint-orchestrator

Thanks for your interest in contributing! This is a young project and PRs are welcome.

## What I'm most excited to receive

### 🎯 New addons for stacks I don't use

The skill ships with addons for Postgres, Next.js, Monorepo, Coolify, etc. But there are many stacks missing:

- **Backend**: Django, Rails, Spring Boot, Go services, Elixir/Phoenix, Laravel
- **Frontend**: Remix, SvelteKit, Astro, Solid
- **Database**: MySQL, MongoDB, SQLite, DynamoDB, Supabase
- **Deploy**: AWS, GCP, Heroku, DigitalOcean App Platform
- **CI**: GitLab CI, CircleCI, Buildkite

To add an addon, copy [`addons/postgres/README.md`](addons/postgres/README.md) as a template, fill in your stack's specifics, and submit a PR.

### 🐛 Bug patterns from your production lessons

The most valuable content in this skill is the bug patterns documented per addon — real bugs that real production code hit, with the fix and the prevention.

If you've debugged a tricky bug that fits one of the existing addons (`addons/<X>/bug-patterns.md`), please submit it. Format:

```markdown
## <Title>

**Symptom:** <error message or visible behavior>

**Cause:** <1-2 sentences explaining "why">

**Fix:** <code or process>

**Real case:** <project/sprint where it happened, optional>
```

See [`addons/postgres/`](addons/postgres/) for examples once filled in.

### 🌍 Translations

The README is currently in English, Portuguese (BR) and Spanish. Other languages welcome — submit `README.<lang-code>.md` matching the existing structure.

### 📋 Example profiles

`examples/` only has the SuperDB profile right now. More profiles welcome (Next.js+Vercel, Django+Render, Spring Boot+AWS, etc.) — they help others understand how to configure.

## How to contribute

1. **Open an issue first** if it's a big change (new addon with substantial content, refactor of core/).
2. **Fork + branch**:
   ```bash
   git clone https://github.com/<your-username>/sprint-orchestrator.git
   git checkout -b feat/<short-description>
   ```
3. **Make your changes** following the project conventions:
   - Markdown style: clear headings, code blocks with language tags
   - Bash: `set -euo pipefail`, error messages with `❌` / success with `✅`
   - YAML: 2-space indent, comments on complex keys
4. **Commit using conventional commits**:
   ```
   feat(addons/django): add Django addon
   fix(scripts/init.sh): handle pnpm-workspace.yaml correctly
   docs(README): add Spanish translation
   ```
5. **Push + open PR** with description explaining:
   - What changed
   - Why
   - How you tested (especially for scripts)
6. **Be patient** — solo maintainer, response in days not hours.

## Style guide

### Markdown

- Headers: `##` for sections, `###` for subsections, no `H4` if possible
- Code blocks always have language tag (`bash`, `typescript`, `yaml`, etc.)
- Tables for comparisons or matrices (not for narrative)
- Diagrams: ASCII art OK for simple flows, otherwise Mermaid

### Bash scripts

- `#!/usr/bin/env bash` shebang
- `set -euo pipefail` at top
- Functions for repeated logic
- Errors to stderr (`>&2`) with clear messages
- Exit codes: `0` success, `1` user error, `2` system error

### YAML profiles

- Required fields commented as such
- Optional fields with sensible defaults shown
- Per-addon overrides as nested key matching addon name

## Project structure

```
sprint-orchestrator/
├── SKILL.md           ← entry point (don't grow this past ~150 lines)
├── core/              ← always loaded by Claude (keep tight)
├── addons/<name>/     ← loaded on-demand
│   ├── README.md      ← when to activate + detection + overrides
│   ├── bug-patterns.md ← real bugs with fixes
│   └── <other docs>   ← stack-specific guides
├── templates/         ← interpolated when used
├── checklists/        ← consulted per phase
├── scripts/           ← never loaded into context (just executed)
└── examples/          ← reference profiles
```

## What I won't merge

- **AI-generated content with no validation** — bug patterns must come from real production debugging, not "what could go wrong with X"
- **Speculative features** — features without a concrete use case
- **Major rewrites without prior discussion** — open an issue first
- **Breaking changes to profile schema** without `CHANGELOG.md` migration notes

## License

By contributing, you agree your contributions will be licensed under MIT (same as the project).

## Questions?

Open an issue with the `question` label. I'll respond when I can.
