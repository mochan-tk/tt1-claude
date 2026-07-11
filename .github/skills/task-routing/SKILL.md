---
name: task-routing
description: Decide where and with what each Task issue should run — execution surface (exec:cloud / exec:app / exec:cli / exec:ide label), suggested agent role, and suggested model/reasoning effort. Use this while decomposing an Epic, when filling the Routing block of ai-task issues, when a task changes nature mid-flight and needs re-routing, and whenever someone asks which tool (cloud agent, Copilot app, CLI, IDE) should handle a piece of work.
---

# Task Routing

Every Task issue carries exactly one `exec:*` label plus a filled Routing
block. Routing is decided at planning time so that dispatch is mechanical:
orchestrators and humans read the label and act, instead of re-debating tool
choice per task.

## Routing inputs

Score the task on five axes before choosing:

1. **Ambiguity** — is the brief fully specified, or will it need human
   judgment calls mid-task?
2. **Local dependency** — does it need physical hardware (flash, serial, HIL),
   local credentials, or a specific machine?
3. **Parallelism value** — is it one of many independent tasks worth running
   concurrently?
4. **Sensitivity** — does it expose data that must not leave the machine?
5. **Reasoning depth** — mechanical transformation, or design-grade thinking?

## Surface matrix

| Label | Surface | Strengths | Choose when |
|---|---|---|---|
| `exec:cloud` | Copilot cloud agent (assign issue to Copilot) | Fully async, parallel at scale, ephemeral clean env, delivers a draft PR, iterates on CI failures | Brief is self-contained and unambiguous; no local/hardware needs; ideal for tests, refactors, docs, well-specified features |
| `exec:app` | Copilot app session (parent/child tree, worktrees) | Steerable in real time, session tree for orchestration, per-session model/agent choice, local checkout | Orchestration itself; tasks needing occasional steering; parallel local work isolated by worktrees; when model choice matters per task |
| `exec:cli` | Copilot CLI | Scriptable, composable with `gh`, runs in CI/automation | Batch/repetitive repo operations, plan-graph manipulation at scale, scheduled or pipeline-triggered agent work |
| `exec:ide` | VS Code + Copilot Chat (agent mode) | Human-in-the-loop, full local toolchain, hardware access (e.g., PlatformIO upload/monitor) | Ambiguous or exploratory work; design spikes; anything touching physical devices |

## Hard rules

- **Hardware rule.** Building firmware and running `native`-env tests can go
  anywhere; flashing, serial monitoring, and hardware-in-the-loop verification
  route to `exec:ide` (or an `exec:app` session on the machine physically
  connected to the device). Never let a cloud task carry a hardware-verified
  acceptance criterion.
- **Sensitivity rule.** Tasks handling data that must stay local route to
  `exec:app`/`exec:ide` with a local model suggested in the Routing block.
- **Ambiguity rule.** If you cannot write objectively checkable acceptance
  criteria, the task is not `exec:cloud` yet — either sharpen the brief or
  route to an interactive surface.

## Model / reasoning suggestion

The Routing block's model suggestion is advisory (pickers and availability
change), but the effort tier is meaningful:

| Tier | Use for | Examples of intent |
|---|---|---|
| `high-reasoning` | Planning, architecture, replanning, review, tricky debugging | frontier-class model, extended/high reasoning effort |
| `standard` | Ordinary implementation with good briefs | default model settings |
| `fast` | Mechanical edits, renames, formatting, boilerplate | smaller/faster model |
| `local` | Sensitive data, offline work | on-device model |

## Role suggestion

Suggest a role when a specialized definition exists in `.github/agents/`
(e.g., `planner`, `orchestrator`, `reviewer`) or in the client's agent picker
(e.g., security- or docs-focused agents). Leave as `default` otherwise; do not
invent role names that no surface provides.

## Re-routing

A task changes surface when its nature changes: an `exec:cloud` task that
turns ambiguous comes back as `exec:ide`/`exec:app`; an exploratory task whose
outcome is now a crisp spec goes out again as `exec:cloud`. Re-routing is a
plan change: swap the `exec:*` label, adjust the Routing block, note one line
of rationale on the issue.
