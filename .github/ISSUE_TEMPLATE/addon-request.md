---
name: 🧩 New addon request
about: Request or propose an addon for a stack not yet covered
title: '[addon] '
labels: addon, enhancement
---

## Stack / technology

<!-- e.g. Django, Rails, Spring Boot, MongoDB, Heroku, GitLab CI -->

## Why this stack needs an addon

<!-- What's different about it that requires its own bug patterns / docs / detection?
     Bonus: what common bugs does this stack have that an addon could capture? -->

## Detection signals

<!-- How can `init.sh` auto-detect a project uses this stack? Specific files, deps, configs -->

- File `<filename>` exists with `<pattern>`
- Dependency `<name>` in package.json / requirements.txt / Gemfile
- Folder structure: ...

## Initial content I can contribute

- [ ] README.md describing when to activate + detection
- [ ] At least 2-3 bug-patterns from real production debugging
- [ ] Example profile in `examples/`
- [ ] Detection logic update for `scripts/init.sh`

## I will / I won't write this addon

- [ ] I will submit a PR with the initial addon
- [ ] I want someone else to write it (please consider this a request, not a contribution offer)

## Additional context

<!-- Links to docs, similar tools, etc. -->
