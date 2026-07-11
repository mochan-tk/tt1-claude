---
name: verification
description: Prove that work meets its Task issue — layered verification gates, the pre-PR checklist, the acceptance-criteria evidence table, and CI-failure triage. Use this before marking any PR ready for review, when writing the Verification section of a task brief, when a CI check fails, or when reviewing whether someone else's evidence actually proves their claim.
---

# Verification

Agent-produced work is verified in layers, cheapest and most deterministic
first. Each layer exists because the one after it is more expensive: a linter
catches in seconds what a human notices in minutes. The corollary that shapes
this whole repository: **automated checks are the ceiling on agent autonomy** —
work that only a human can verify can never be safely delegated, so investing
in layer 1 is investing in delegation itself.

## The layers

1. **Deterministic** — formatters, linters, type checks, unit/integration
   tests, build. Runs locally and in CI. Binary outcomes only.
2. **Security** — secret scanning, dependency review, code scanning. Never
   ship "temporary" suppressions without a linked issue.
3. **AI review** — Copilot code review and/or the `reviewer` agent, guided by
   `.github/instructions/code-review.instructions.md`. Catches claim/evidence
   gaps and silent deviations before a human spends attention.
4. **Human review** — judgment: is this the *right* change? Protected by
   branch ruleset (required PR + required checks + human approval on
   agent-authored PRs).

Never compensate for a lower layer at a higher one ("reviewer will catch it")
and never weaken a lower layer to pass ("delete the flaky test"). A failing
gate is information; removing the gate destroys the information.

## Pre-PR checklist (implementer)

1. Run every command in the Task issue's **Verification** section; capture
   real output.
2. `git status --short` clean; diff confined to the issue's File-ownership
   paths.
3. New logic has tests at the appropriate level (firmware logic: `native`
   env — see `firmware.instructions.md`).
4. Fill the PR template's evidence table — every acceptance criterion gets a
   row:

```markdown
| Criterion | Evidence (command / link) | Result |
|---|---|---|
| REQ-012: pairing completes < 5 s | `npm test -- pairing.spec` -> 8 passed | pass |
| Docs updated | docs/agreements/requirements.md diff in this PR | pass |
| HIL verified on device | n/a in this task -> follow-up #<n> (exec:ide) | deferred |
```

`deferred` is legal only when a follow-up issue exists and is linked;
"pass (untested)" is not a result.

## CI failure triage

When a check fails, classify before touching anything:

- **Environment** (missing tool, network, flake): fix the environment —
  usually `.github/workflows/copilot-setup-steps.yml` or CI config — and note
  it as a retro candidate.
- **Defect** (the code is wrong): fix the code.
- **Specification mismatch** (the test encodes a requirement the task was
  told to change, or the requirement itself is wrong): **stop patching.**
  Apply `needs:replan`, record the mismatch on the issue, and let the plan —
  or the agreement — be corrected first. Making a wrong test pass is the most
  damaging "fix" an agent can make.

## Writing good Verification sections (planner)

- Commands must run in the task's routed environment (`exec:cloud` tasks get
  no hardware — split HIL criteria into an `exec:ide` follow-up).
- Prefer commands over prose: "run X, expect Y" beats "make sure it works".
- Include the negative case when it matters ("`grep -R <secret-pattern>`
  returns nothing").
