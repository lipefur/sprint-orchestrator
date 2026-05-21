# Coolify bug patterns

Real production bugs observed when using Coolify as deploy platform via SSH + API. Each entry: symptom → root cause → preventive fix → reactive fix.

---

## 1. Duplicate deploys queued (webhook + semantic-release + manual API)

### Symptom

Coolify queues 2-4 deploys in quick succession after a single PR merge. Build/deploy cycle runs multiple times, wasting compute and risking race conditions if migrations or env-mutating steps run more than once.

```
Coolify queue:
  - Deploy #142 (triggered by webhook — merge commit)
  - Deploy #143 (triggered by webhook — semantic-release commit)
  - Deploy #144 (triggered by API call — orchestrator's POST /deploy)
```

### Root cause

Three independent triggers can fire for the same logical "ship this PR" event:

1. **GitHub webhook** fires on every push to `main`. Configured by default when you connect a GitHub repo to a Coolify application.
2. **`semantic-release`** (if configured) pushes a new commit to `main` after the merge to bump the version and write CHANGELOG. **This is also a push** → fires the webhook again.
3. **Manual API call** to `POST /api/v1/deploy?uuid=<app>` from the orchestrator's deploy workflow ([`checklists/deploy-prod.md`](../../checklists/deploy-prod.md) step 4) adds a third deploy on top.

Each trigger sees a different commit but ends up building the same code (or very nearly the same — semantic-release only changes `package.json` + `CHANGELOG.md`).

### Preventive fix (pick one strategy)

**Strategy A — Single source of truth: manual deploys only**

Disable the GitHub webhook in Coolify (Application Settings → "Auto deploy on git push" → OFF). Deploy only via explicit API call when the orchestrator is ready (after migrations applied, env vars set, etc.).

Pros: full control over deploy ordering. Cons: orchestrator must remember to deploy (the skill's deploy-prod checklist enforces this anyway).

**Strategy B — Webhook only, no manual call**

Keep the webhook. Remove the `POST /deploy` step from your deploy-prod checklist. Configure `semantic-release` to either:

- Run **before** merge (so the release commit is part of the PR), avoiding the second push
- Use `[skip ci]` in the commit message (`semantic-release` config: `releaseRules` with `[skip ci]`) so the webhook ignores it

Pros: simple. Cons: deploy starts before migrations applied unless your CI pipeline handles ordering.

**Strategy C — Path filter on webhook (recommended for projects with semantic-release)**

In Coolify's webhook configuration, add a path filter so the webhook only fires for changes outside `package.json` and `CHANGELOG.md`. Semantic-release commits only touch those, so they get ignored. Manual API deploy continues to work for orchestrator-driven deploys.

```yaml
# Coolify webhook config (conceptual — actual UI varies by Coolify version)
trigger_on_push:
  branches: [main]
  ignore_paths:
    - package.json
    - CHANGELOG.md
    - .release-please-manifest.json
```

Pros: deploys are intentional, semantic-release commits skipped. Cons: requires Coolify version that supports path filters.

### Reactive fix (when it already happened)

If duplicate deploys are already queued:

1. **Don't cancel mid-deploy** if one is currently running — interrupting can leave the app in inconsistent state
2. Wait for the running deploy to finish
3. Cancel queued deploys: Coolify UI → Application → Deployments → ⨯ on each queued
4. Verify final state via health check + smoke E2E

Document the trigger source in `state.md` so the orchestrator learns to skip the manual deploy step next time for this project.

---

## Pattern catalog

Add new Coolify-specific patterns above this line as you encounter them. Generic deploy patterns (e.g., "deploy duplication" across any platform) belong in [`core/anti-patterns.md`](../../core/anti-patterns.md).
