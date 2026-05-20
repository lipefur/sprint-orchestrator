---
name: 🧠 Bug pattern contribution
about: Share a real bug pattern from your production debugging
title: '[bug-pattern] '
labels: bug-pattern, enhancement
---

## Which addon does this belong to?

<!-- e.g. addons/postgres, addons/nextjs, core (if cross-cutting) -->

## Symptom

<!-- Exact error message, stack trace, or visible behavior -->

```
<!-- logs here -->
```

## Cause (root)

<!-- 1-2 sentences explaining WHY it happens, not just WHAT -->

## When it appears

<!-- Context: always when X, only when Y, on Postgres version Z, etc. -->

## Preventive fix

<!-- Code or process change that avoids the bug -->

```typescript
// example
```

## Reactive fix (if already happened)

<!-- Code to fix it after the fact -->

```typescript
// example
```

## Real case (optional but valuable)

<!-- Project / sprint / commit where this was actually hit -->

## How to validate this is reusable

- [ ] This bug would appear in other projects using the same stack (not specific to my codebase)
- [ ] The fix is generic (not specific to my business logic)
- [ ] I've actually debugged this in production (not theoretical)
