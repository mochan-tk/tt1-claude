# Copilot Repository Instructions

Trust these instructions. Search the codebase only when something here is
missing or demonstrably wrong — and when that happens, propose a fix to this
file as part of your PR (see the retro skill).

`AGENTS.md` at the repository root defines the operating protocol
(persistence rule, record-before-report, verify-before-done, unit of work,
single-writer rule, Ambiguity rule). It applies to you in full. This file adds the operational
details Copilot needs to work efficiently in this repository.

## Repository layout

<!-- CUSTOMIZE: Keep this map accurate; it saves agents expensive exploration.
     Example:
     - `firmware/`  — PlatformIO project. Envs defined in `firmware/platformio.ini`.
     - `server/`    — API server. Entry point `server/src/index.ts`.
     - `app/`       — client app.
     - `docs/context/`    — raw collected material (read for background).
     - `docs/agreements/` — reviewed decisions (read before designing anything).
-->
- `docs/context/` — raw collected material.
- `docs/agreements/` — reviewed requirements, ADRs, glossary, non-goals.
- `.github/skills/` — procedures. `.github/instructions/` — path-scoped rules.
- `.github/agents/` — role definitions (orchestrator, planner, reviewer).

## Environment setup and validated commands

If `CUSTOMIZE` markers remain in this file (check with
`scripts/tuning-status.sh`), this repository has **not been onboarded** —
run `.github/skills/project-onboarding/SKILL.md` before trusting or
extending the commands below.

Run steps in this order. Do not improvise alternative commands when these work.

<!-- CUSTOMIZE: Replace with commands verified to work in a clean environment,
     including known failures and workarounds. Keep this in sync with
     `.github/workflows/copilot-setup-steps.yml` so your interactive and cloud
     environments match. Example:

     1. `npm ci`               — install server/app dependencies (~2 min).
     2. `pip install platformio` — required before any firmware command.
     3. `npm test`             — full unit test suite; must pass before any PR.
     4. `pio test -e native -d firmware` — firmware logic tests on the host.
        Note: `pio test` without `-e native` tries to reach real hardware and
        will fail in cloud environments — never use it there.
-->

## Working a Task issue

The Task issue body is your work order. It follows
`.github/ISSUE_TEMPLATE/ai-task.yml` and contains: Objective, Context &
references, Acceptance criteria, Out of scope, File ownership, Verification,
and Routing. Read all of it before writing code.

1. Comment on the issue that you are starting (one line is enough).
2. Work on branch `task/<issue-number>-<short-slug>`. Touch only paths listed
   under **File ownership**.
3. Keep the PR description synchronized with reality: map each acceptance
   criterion to evidence using the table in the PR template.
4. Run every command in the issue's **Verification** section before marking the
   PR ready. If a command fails, fix the cause or report the blocker — never
   delete or weaken the check.
5. If the task turns out to be materially different from its description,
   follow the Ambiguity rule in `AGENTS.md` (comment, label `needs:human` or
   `needs:replan`, stop).
6. Finish with the record-before-report comment on the issue: status, evidence,
   deviations, follow-ups (format in
   `.github/skills/session-orchestration/SKILL.md`).

## Pull request conventions

- Title: imperative mood, mirrors the Task issue title.
- Body: fill `.github/PULL_REQUEST_TEMPLATE.md` completely, including
  `Closes #<n>` and the evidence table.
- Keep PRs reviewable: one Task issue per PR; if the diff exceeds roughly 400
  changed lines outside generated code, propose splitting via `needs:replan`
  instead of pushing on.

## Things that will get your PR rejected

- Diff touches paths outside the issue's File ownership section.
- Acceptance criteria without evidence, or verification commands not run.
- Secrets, tokens, or credentials in code or config.
- Modified CI workflows, rulesets, or checks without an explicit mandate.
- Non-English persistent artifacts (code comments, docs, commit messages).
