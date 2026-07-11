---
name: session-orchestration
description: Protocol for running work through parent/child agent sessions (e.g., the GitHub Copilot app's session tree, or any orchestrator dispatching cloud-agent runs). Use this whenever a session spawns or reports to another session, when starting work on a Task issue in a new session, when writing a completion/blocked/failed report, or when deciding what belongs in plan.md versus GitHub.

---

# Session Orchestration

Session trees and inter-session messages are powerful but **app-local**: a
cloud agent, a teammate, another machine, or you-next-week cannot see them.
GitHub is the only shared memory. Every rule below exists to keep the durable
record on GitHub while using sessions for speed.

## Mapping (the 1:1:1:1 rule)

| Plan object | Session object | Workspace object |
|---|---|---|
| Epic issue | Parent (orchestrator) session | — |
| Task issue | One child session | One worktree + branch `task/<n>-<slug>` (or accepted tool-prefixed variant) + one PR |

One Task issue per child session — never batch several issues into one
session (reports become unattributable) and never split one issue across
sessions without replanning first. Use a separate worktree per concurrent
child so parallel sessions cannot write to the same checkout.

## Child session protocol

**Start ritual** (do this before touching any file):
1. `gh issue view <n>` — read the full brief: Objective, Context & references,
   Acceptance criteria, Out of scope, File ownership, Verification, Routing.
2. Open every referenced agreement (`REQ-###`, ADR links). If a reference is
   missing or contradicts the issue, stop and apply the Ambiguity rule
   (`AGENTS.md` §6) — do not fill gaps with guesses.
3. Write `plan.md` in the worktree root: restate the acceptance criteria, the
   ownership paths, the verification commands, and your step plan. `plan.md`
   is a **session cache** — convenient, disposable, never authoritative, and
   never a substitute for updating the issue. Do not commit it
   (add to `.gitignore` if needed).
4. Claim the task on its comment ledger:
   `.github/skills/plan-management/scripts/claim-task.sh <n> --session <session-id>`
   — proceed only on exit 0; exit 3 means another session holds it (pick
   another frontier item). The session id is any stable, whitespace-free
   token, by convention tool + date or thread (e.g. `claude-code-20260712`,
   `copilot-app-<session>`, `codex-<thread>`). The claim comment is the
   durable "this task is taken" signal; follow it with one line naming the
   branch: `Starting in session <name/link>, branch task/<n>-<slug>` (or
   the accepted tool-prefixed variant, AGENTS.md §4).

**Work loop:** stay inside the ownership paths; commit early and often;
update `plan.md` freely; if scope drifts, stop and follow the Ambiguity rule
rather than quietly expanding.

**Verify** (before any completion claim): run every command in the issue's
Verification section; then confirm external state with commands, e.g.
`gh pr view <pr> --json state,statusCheckRollup`, `gh pr checks <pr>`,
`git status --short` (must be clean), and, when the task tracked Project
items, `gh project item-list`. Evidence = command + observed result.

**Record before report** — post this comment on the Task issue, then (and
only then) message the parent:

```markdown
## Outcome: <completed | blocked | failed | needs-replan>
**PR:** #<pr-number>
**Evidence:**
| Criterion | Evidence (command / link) | Result |
|---|---|---|
| AC1 ... | `pio test -e native` -> 12 passed | pass |
**Deviations:** <none, or what differs from the brief and why>
**Follow-ups:** <suggested downstream issue changes, or none>
**Scaffold friction:** <none | retro:candidate issue link>
```

The **Scaffold friction** line is optional: fill it when you filed or +1'd a
`retro:candidate` issue during the task (retro skill, §Candidate ledger).

The message to the parent is a pointer, not a payload: outcome word + issue
and PR links. If the parent session is gone, the record still stands — that
is the point.

## Parent session protocol

1. Dispatch only from the frontier (`plan-management` skill), after checking
   that concurrently dispatched tasks have disjoint File-ownership paths.
   Dispatch = claim first, then spawn: claim the issue with
   `claim-task.sh <n> --session <session-id>` and dispatch only what you
   hold, passing that session id to the child (the child's start-ritual
   claim is then an idempotent re-claim).
2. **Issue-first, dedicated-session — no exceptions for infra/ops.** Ad-hoc
   requests (e.g. a human asking "can you deploy this?"), and cloud/deploy/
   infra work in general (provisioning, secrets, deploy unblocking), get a
   Task issue created *before* any work begins, and run in a dedicated child
   session like any other task — never inline in the parent. No issue, no
   work: evidence recorded after the fact on a closed issue does not count.
3. When delegating, pass the issue number only — the issue is the brief. If
   you feel the need to add substantial instructions in the dispatch message,
   the brief is incomplete: fix the issue first.
4. Steer with short course-correction messages when session logs show drift;
   prefer steering over restarting.
5. On receiving a report: verify the record exists on the issue and spot-check
   the evidence with your own `gh` calls before updating labels/Project state
   or dispatching dependents. An unrecorded report is returned to the child
   with one instruction: record first.
6. Route `needs-replan` outcomes to the planner procedure
   (`plan-management` §Replanning) and post the rationale on the Epic.

## Escalation to humans

Escalate (label `needs:human`, stop the affected line of work) when: an
agreement in `docs/agreements/` turns out wrong; credentials/security issues
appear; the same task fails twice with different approaches; or two sessions
claim the same ownership paths. For that last case the claim ledger is the
deterministic resolver first: the ledger holder (earliest active claim —
check with `claim-task.sh <n> --status`) proceeds, the other session
releases; escalate only if the overlap itself was planned (a planning bug).
These are judgment or trust failures, not execution failures — humans own
those.
