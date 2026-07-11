---
name: project-onboarding
description: Tune this generic scaffold to a concrete target project — inventory the repo, interview only the gaps, verify every command by actually running it, fill or remove every CUSTOMIZE block, and deliver one evidence-backed onboarding PR. Use this whenever the scaffold lands in a new or existing project, whenever `scripts/tuning-status.sh` reports markers, whenever commands in copilot-instructions are unverified or drift from CI, and whenever a user says "tune/onboard/set up this scaffold for project X".
---

# Project Onboarding

This scaffold ships generic on purpose: project truth is injected once, here,
by procedure — not sprinkled ad hoc. Onboarding succeeds when an agent that
knows nothing about the project can work from `.github/copilot-instructions.md`
alone and every stated command demonstrably runs.

Two invariants govern everything below:

- **The Sync Triangle.** `.github/copilot-instructions.md` (validated
  commands), `.github/workflows/ci.yml` (gates), and
  `.github/workflows/copilot-setup-steps.yml` (cloud-agent env) must state
  the *same* toolchain and commands. Any edit to one is an edit to all three.
- **Evidence or it does not land.** A command enters the Triangle only after
  it has been executed in a clean environment during this onboarding, with
  its output (or failure + workaround) captured for the PR.

## Procedure

### P0 — Status

Run `scripts/tuning-status.sh`. Exit 0 → already tuned; run in re-tune mode
(see Re-tuning) only if something changed. Otherwise the report is your
worklist.

### P1 — Inventory (read-only)

Detect before you ask. Scan for: manifests and lockfiles (`package.json`,
`pyproject.toml`/`requirements*.txt`, `go.mod`, `Cargo.toml`, `pom.xml`,
`platformio.ini`, `Dockerfile`, `Makefile`, `Taskfile*`), existing CI under
`.github/workflows/`, test directories and runners, formatters/linters
configs, monorepo workspaces, and hardware markers (board envs in
`platformio.ini`). Produce an inventory table: area → stack → candidate
build/lint/test commands → confidence.

### P2 — Interview (gaps only)

Ask the human only what P1 could not answer, in one batch. Question bank
(pick applicable, keep ≤10):

1. Which areas are in active development vs frozen?
2. Exact commands you trust for build / lint / test per area, if any?
3. Firmware: target envs, and which machine physically hosts devices
   (routes `exec:ide` work)?
4. Runtime versions to pin (Node/Python/etc.)?
5. Paths that agents must never touch (extend rulesets / File-ownership
   defaults)?
6. Secrets/credentials policy; anything that must stay local
   (`local` model tier)?
7. Org-level issue types / Project board to attach? (Projects v2 boards are
   always user/org-owned; `scripts/setup-project.sh init` links the board to
   the repo so it shows in the repo's Projects tab — an org/user board URL
   is expected, not a misconfiguration.)
8. Larger runners needed for the cloud agent?
9. Existing docs to seed `docs/context/` with (do NOT distill them here)?
10. Anything the last CI lied about (flaky/slow gates)?

### P3 — Verify by running

In a clean checkout, execute candidate commands in dependency order. Record
for each: exact command, environment prerequisites, runtime, result. Failures
are content: capture the error and the working workaround — these notes go
into copilot-instructions so no agent rediscovers them. Never promote an
unrun command.

### P4 — Apply

- Fill every `CUSTOMIZE` block in the Triangle files with P3-verified
  content; delete the placeholder steps/warnings they replace.
- Area instructions: fix `applyTo` globs; delete inapplicable examples
  (e.g., `firmware.instructions.md` when there is no firmware); add one
  `.instructions.md` per detected area that has real rules (one concern per
  file).
- Repository layout map in copilot-instructions: make it match reality.
- Run `scripts/setup-labels.sh` if labels are missing.
- Seed provided documents into `docs/context/<topic>/` with provenance
  headers (`context-collection` skill). Do **not** write agreements —
  distillation is a separate, human-gated phase.
- Do **not** touch `AGENTS.md` (Budget rule; behavior is project-independent).

### P5 — Prove

`scripts/tuning-status.sh` exits 0; the new CI gates run green once end to
end (or documented-red with a linked issue); `copilot-setup-steps.yml`
executes via its own workflow_dispatch. Definition of tuned = all three.

### P6 — Record

One PR titled `scaffold: onboard <project>`: the Triangle diffs, the
inventory table, the interview answers, and the P3 evidence log in the
description. Append a `docs/agreements/retro-log.md` row (failure class:
`onboarding`). List any project-agnostic improvements you noticed as
upstream candidates (see the retro skill, Upstreaming).

## Re-tuning

Re-run P1→P6 (scoped to the delta) when: a new manifest/lockfile type
appears; CI and copilot-instructions disagree; `copilot-setup-steps` fails
for the cloud agent; or a retro identifies stale commands. Drift between the
Triangle files is itself a retro trigger.

## Must NOT

- Invent agreements, requirements, or ADRs.
- Weaken or delete existing gates to make onboarding "pass".
- Leave a command in the Triangle that was not executed in P3.
- Introduce non-English durable artifacts.
