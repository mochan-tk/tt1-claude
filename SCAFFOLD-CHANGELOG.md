# Scaffold Changelog & Lineage

This repository instance was created from the **agentic-dev-scaffold**
template. This file tracks which template version the instance adopted and
how to move between versions. The project's own changelog, if any, lives
elsewhere — this file is about the scaffolding only.

**Scaffold version adopted by this instance:** v0.5.0
*(update this line when upgrading; the onboarding PR should confirm it)*

## Upgrading an instance

1. Diff this instance against the template tag you are moving to
   (e.g., `git remote add scaffold <template-url> && git fetch scaffold --tags
   && git diff scaffold/v0.2.0..scaffold/v0.3.0 -- . ':!docs/context' ':!docs/agreements'`).
2. Cherry-pick or apply the changes, **keeping project tunings** (the Sync
   Triangle content, `applyTo` globs, layout map) — upgrades change
   procedures and templates, not your project truth.
3. Re-run `scripts/tuning-status.sh` and the CI gates.
4. Land as one PR titled `scaffold: upgrade to vX.Y.Z`; append a
   `docs/agreements/retro-log.md` row (class `scaffold-upgrade`).

## Upstreaming (instance → template)

When a retro fix is project-agnostic, open a matching PR on the template
repository and mark the retro-log Fix cell `[upstreamed]` — see
`.github/skills/retro/SKILL.md`, Upstreaming. That is how future projects
inherit what this one learned.

## Versions

### v0.5.0 — 2026-07-04

Self-tuning loop (Epic #19): scaffold friction observed during development
now accumulates in a countable ledger, a monthly deterministic job surfaces
what is overdue, and the loop is proven end-to-end on a real deviation.

- Candidate ledger (#20): `retro:candidate` label added to
  `scripts/setup-labels.sh`; the retro skill gains a Candidate ledger
  section (search before filing → file or +1 → promote at the 2nd
  occurrence; occurrence count = 1 filing + N occurrence comments); the
  session-orchestration outcome format and the PR template gain a
  "Scaffold friction" prompt so first occurrences get recorded.
- Hygiene automation (#21): `scripts/retro-hygiene.sh` prints a
  deterministic Markdown report — open candidates with occurrence counts,
  ages in days and PROMOTION OVERDUE flags, plus `AGENTS.md` /
  `.github/copilot-instructions.md` line counts against the ~150-line
  Budget-rule target — and `--create-issue` files it as the idempotent
  monthly "Retro hygiene review <YYYY-MM>" issue labeled `needs:human`.
  `.github/workflows/retro-hygiene.yml` runs it on the 1st of every month
  (plus `workflow_dispatch`).
- Live retro demo (#22): the branch-name deviation (app-generated branch
  names instead of `task/<n>-<slug>`, declared on six merged PRs) is
  promoted into a real `retro:` fix — AGENTS.md §4 clause,
  session-orchestration mapping update, retro-log row — closing its
  candidate issue so future PRs no longer need the deviation note.

### v0.4.0 — 2026-07-04

- `scripts/setup-project.sh`: scripted bootstrap for an optional GitHub
  Projects v2 roadmap board. `init` creates (or reuses) a "<repo> roadmap"
  project, adds `Start date` / `Target date` DATE fields if missing, and
  links the project to the repository — idempotent re-runs. `dates` puts an
  issue on the board (reusing the item when already present) and sets both
  date fields, validating YYYY-MM-DD format and rejecting a target earlier
  than the start. The Roadmap *view* itself remains a one-time manual UI
  step (view creation is not exposed by the GitHub API). Plan-management
  skill gains a "Roadmap scheduling" subsection; README documents the
  optional bootstrap step. (#16)

### v0.3.0 — 2026-07-04

- CI: new `scaffold-self-check` job in `ci.yml` — pinned shellcheck
  (v0.11.0) over all tracked shell scripts, pinned actionlint (1.7.12)
  over workflow files, plus two new deterministic consistency checks:
  `scripts/check-template-sync.sh` (issue forms <-> canonical body
  templates) and `scripts/check-md-links.sh` (Markdown path references
  resolve). (#11)
- Repository hygiene files: `.gitignore` (session `plan.md`, OS/editor
  cruft), `.github/CODEOWNERS` (human review gate on `docs/agreements/`
  and `.github/workflows/`), `.github/dependabot.yml` (weekly GitHub
  Actions version updates). (#10)
- `scripts/setup-ruleset.sh`: scripted bootstrap for the README step-5
  branch ruleset (required PR, >= 1 approval, required status checks);
  safe by default — created with enforcement disabled until a human
  reviews and enables it. (#10)
- `new-task.sh` wires parent, labels, and `--blocked-by` dependencies in
  one `gh issue create` call, so a failed edit step can no longer leak an
  unwired task into the frontier; plan-management cookbook updated to
  match. (#9)
- Fixed bash-3.2 empty-array crashes (`set -u` + empty `"${arr[@]}"` on
  macOS /bin/bash) in `scripts/setup-labels.sh` and `frontier.sh` using
  the `${arr[@]+"${arr[@]}"}` guard idiom; same guard applied in
  `new-task.sh`. (#7, #9)

### v0.2.1 — 2026-07-03

- Added `CLAUDE.md` shim (`@AGENTS.md` + `@.github/copilot-instructions.md`
  imports) so Claude Code loads the same always-on context as the Copilot
  surfaces, regardless of native AGENTS.md support status.

### v0.2.0 — 2026-07-03

- Added `project-onboarding` skill and `/onboard-project` prompt: tuning is
  now a procedure an agent executes (inventory → gap interview →
  run-verified commands → fill CUSTOMIZE → evidence PR).
- Added `scripts/tuning-status.sh`; CI surfaces untuned state as warnings.
- Added the second improvement loop: retro Upstreaming section + this
  lineage file; template versions are tags on the template repository.
- README: getting-started rewritten around onboarding; lineage section.

### v0.1.0 — 2026-07-03

- Initial 40-file scaffold: AGENTS.md constitution (§1–§9); seven skills
  (context-collection, context-distillation, plan-management + frontier/
  new-task scripts + canonical bodies, task-routing, session-orchestration,
  verification, retro); three roles; five prompts; issue forms + PR
  template; CI + copilot-setup-steps placeholders; docs tree; label
  bootstrap.
