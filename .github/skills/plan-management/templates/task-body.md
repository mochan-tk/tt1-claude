<!-- Canonical Task issue body. Mirrors .github/ISSUE_TEMPLATE/ai-task.yml.
     Used when creating Task issues via gh CLI / new-task.sh (issue forms
     apply only to the web UI). Keep the section headings exactly as below —
     agents and scripts parse them. Delete all comments before filing. -->

## Objective

<!-- One sentence: the observable outcome this task delivers. -->

## Context & references

<!-- Links the executing agent must read: REQ-### entries, ADRs, parent Epic,
     prior PRs/issues, relevant docs/context files. Assume the agent sees
     NOTHING beyond this issue and these links. -->

- Epic: #
- Requirements: REQ-
- Decisions:

## Acceptance criteria

<!-- Objectively checkable, each provable by a Verification command or an
     observable artifact. Reference REQ-### where applicable. -->

- [ ]
- [ ]

## Out of scope

<!-- Explicit non-goals for THIS task. The cheapest scope-creep guard. -->

-

## File ownership

<!-- Paths (globs allowed) this task may modify. The diff must stay inside
     them (AGENTS.md §5). Parallel tasks must not overlap. -->

-

## Verification

<!-- Commands to run, with expected results, executable on the routed
     surface (exec:cloud tasks get no hardware). -->

```bash

```

## Routing

<!-- See .github/skills/task-routing/SKILL.md. Mirror Surface as the exec:*
     label on the issue. -->

- Surface: exec:cloud | exec:app | exec:cli | exec:ide
- Suggested role: default | planner | orchestrator | reviewer
- Model/reasoning tier: high-reasoning | standard | fast | local
- Parallel-safe: yes | no — <why>

## Handoff notes

<!-- Optional: state another agent would need to take over or follow up. -->

-
