# AGENTS.md — Operating Constitution for All AI Agents

This is the constitution for every AI agent working in this repository, on
every surface: GitHub Copilot cloud (coding) agent, GitHub Copilot app
sessions, Copilot CLI, IDE chat agents, and third-party agents. It defines
behavior only; repository practicalities (layout, commands, PR mechanics)
live in `.github/copilot-instructions.md` and must not be duplicated or
contradicted here.

If any instruction conflicts with this file, stop and escalate per §6.

## Principles

### §1 Persistence rule
GitHub is the single source of truth; sessions are ephemeral. Chat threads,
session trees, and inter-session messages are transport, not storage.
Anything that must outlive the session — results, decisions, blockers, plan
changes, lessons — is written to an issue, a pull request, or a committed
file. Assume every other agent, and every future session, can see only
GitHub, never your conversation.

### §2 Record-before-report
Finish (or abort) by writing the structured outcome on the durable record
first — a comment on the Task issue and the PR description — and only then
send the session message to your parent session or the human. A report that
exists only as a session message does not count as reported. The comment
format is defined in `.github/skills/session-orchestration/SKILL.md`.

### §3 Verify-before-done
Never claim a state you have not verified in this session against ground
truth: `git status`, `gh issue view`, `gh pr view`, `gh pr checks`, project
queries. Your memory of what you did is not evidence. Procedure and evidence
format: `.github/skills/verification/SKILL.md`.

### §4 Unit of work
1 Task issue = 1 session = 1 worktree/branch = 1 pull request.
Branch name: `task/<issue-number>-<short-slug>`; a managed surface's
tool-generated prefix (e.g. `<user>-task-<n>-<slug>`) is an accepted
equivalent needing no deviation note. The PR body links the issue with
`Closes #<n>`. Never batch several issues into one session or PR; never
split one issue across sessions without replanning first.

### §5 Single-writer rule
Modify only paths inside the **File ownership** section of your Task issue.
Parallel tasks must own disjoint path sets; where overlap is unavoidable,
the plan serializes them with a `blocked-by` dependency. If your task turns
out to need paths you do not own, stop and escalate per §6 with the label
`needs:replan`.

### §6 Ambiguity rule
Escalate, don't guess. When requirements are ambiguous or contradictory,
when acceptance criteria cannot be met as written, or when you are blocked:
write the situation and the options you see as an issue comment, apply
`needs:human` (judgment/trust matters) or `needs:replan` (plan/scope
matters), and stop that line of work. A wrong guess silently merged costs
far more than a paused task.

### §7 Rolling-wave planning
Epics stay coarse; Task issues are decomposed just-in-time when their phase
starts, and revised whenever reality diverges. Every plan change carries a
rationale comment on the Epic. Procedures:
`.github/skills/plan-management/SKILL.md`.

### §8 English-only rule
All durable artifacts — issues, PRs, commit messages, code comments, and
every Markdown file — are written in English so model behavior stays
consistent across tools and sessions. Conversations with humans may use the
human's language.

### §9 Start ritual
At session start read, in order: (1) this file, (2)
`.github/copilot-instructions.md`, (3) your Task issue in full, (4) every
agreement it references under `docs/agreements/`, (5) the skills named by
your role or task. Then restate the goal, acceptance criteria, and ownership
paths in one short paragraph before changing anything. If you cannot restate
them, escalate per §6.

## Where things live

| Concern | Location |
|---|---|
| Raw collected material (phase 1) | `docs/context/` |
| Reviewed requirements, ADRs, glossary, non-goals (phase 2) | `docs/agreements/` |
| Repository practicalities (layout, commands, PR mechanics) | `.github/copilot-instructions.md` |
| Path-scoped rules | `.github/instructions/*.instructions.md` |
| Procedures (planning, routing, orchestration, verification, retro, context) | `.github/skills/*/SKILL.md` |
| Role definitions | `.github/agents/*.agent.md` |
| Reusable slash-command prompts | `.github/prompts/*.prompt.md` |
| Work-order / Epic formats | `.github/ISSUE_TEMPLATE/` |

## Amendments

This file is versioned like code and changes only via PR — normally a
`retro:` PR produced by `.github/skills/retro/SKILL.md`, subject to its
Budget rule (always-on files stay lean; adding a line usually means removing
one). Anything procedural belongs in a skill, not here.
