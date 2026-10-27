---
name: roomy
description: Free disk space safely with the roomy CLI when a task hits "no space left on device", a build fails for lack of disk, or the user asks to clean up developer or AI-agent artifacts (node_modules, venvs, model caches, agent caches). Scan first, plan, then clean only safe-tier items.
---

# Freeing disk space with Roomy

Roomy finds regenerable artifacts and removes only what a plan file lists. Use it instead of `rm -rf`.

## Steps

1. Check it is available: `roomy version` (install: `brew install tdermendjiev/roomy/roomy` on macOS; `.deb`/`.rpm` from https://getroomy.dev on Linux).
2. Scan: `roomy scan --json --quiet`. Read `bytesByTier.safe` and the top `items`. Tell the user what is reclaimable and from where (`category`, `label`, `displayPath`).
3. Plan safe items only: `roomy scan --plan /tmp/roomy-plan.json --quiet` (add `--min-idle-days 7` on a workstation; omit on a disposable agent host).
4. Preview: `roomy clean --plan /tmp/roomy-plan.json --dry-run --json`.
5. Execute: `roomy clean --plan /tmp/roomy-plan.json --yes --json --actor "claude-code"`.
6. Report bytes freed and where items went (Trash or quarantine). `roomy restore <path>` undoes.

## Rules

- Never pass `--allow-irreversible`. Items with `tier: warning` are session transcripts, archives and database volumes. Ask the user to handle those in the Roomy app or by hand.
- Use `--allow-caution` only after the user agrees, and show them the items first.
- Do not write your own paths into a plan unless they came from a `roomy scan --json` report in this session.
- Exit 5 = plan contains items above the allowed tier (rewrite the plan). Exit 3 = partial failure (report `failed`). Exit 4 = another run holds the lock (wait).
