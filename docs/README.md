# docs/

Long-form documentation, tutorials, and recipes.

## Index

- 📖 [**Getting Started Tutorial**](tutorial-getting-started.md) — 15-minute walkthrough from zero to first sprint
- ❓ [**FAQ**](faq.md) — common questions
- 🍳 [**Recipes**](recipes/) — stack-specific configurations
- 🔄 [**Migrations**](migrations/) — guides when profile schema breaks compat (none yet)

## When to add docs here vs in core/addons/

| Goes here (`docs/`) | Goes in skill (`core/`, `addons/`, `checklists/`) |
|---|---|
| Tutorial, walkthrough | Documentation Claude reads to execute |
| FAQ, conceptual explanation | Operational reference |
| Stack-specific recipe | Stack-specific addon |
| Migration guide between versions | Schema documentation in CHANGELOG |
| Marketing / pitch / blog post | n/a — keep marketing out of the skill |

Rule of thumb: if **Claude needs to read it to execute a sprint**, it goes in the skill structure (`core/`, `addons/`, etc.). If **a human reads it to understand or onboard**, it goes here.

## Contributing docs

PRs welcome. See [CONTRIBUTING.md](../CONTRIBUTING.md).
