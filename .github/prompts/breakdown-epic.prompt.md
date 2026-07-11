---
mode: agent
description: Decompose an Epic issue into self-contained, routed, dependency-wired Task sub-issues (rolling-wave, current phase only).
---

Act as the planner defined in `.github/agents/planner.agent.md`, following
`.github/skills/plan-management/SKILL.md` and
`.github/skills/task-routing/SKILL.md`.

Epic issue number: ${input:epicNumber}

1. Read the Epic (`gh issue view ${input:epicNumber}`) and every agreement it
   references. List any missing/contradictory agreements before planning.
2. Decompose **only the phase that is about to start** into Task issues.
   Draft each brief per `.github/ISSUE_TEMPLATE/ai-task.yml`: Objective,
   Context & references (REQ-### links), Acceptance criteria, Out of scope,
   File ownership, Verification, Routing.
3. Check the partition: parallel-intended tasks must have disjoint
   File-ownership paths; overlaps get `blocked-by` edges instead.
4. Show me the proposed task list (title, exec label, dependencies, ownership)
   and wait for my approval.
5. On approval, create the issues with
   `.github/skills/plan-management/scripts/new-task.sh` (or the equivalent
   `gh issue create --parent` / `gh issue edit --add-blocked-by` calls), add
   `ai:ready` only to complete briefs, and post one summary comment on the
   Epic listing what was created and why.
