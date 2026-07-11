---
mode: agent
description: Onboard/tune this scaffold to the current project — inventory, gap interview, run-verified commands, fill every CUSTOMIZE, deliver one evidence PR.
---

Follow `.github/skills/project-onboarding/SKILL.md` end to end.

Optional context from me: ${input:notes}

1. **P0/P1:** run `scripts/tuning-status.sh`, then inventory the repository
   read-only. Show me the inventory table (area → stack → candidate
   commands → confidence).
2. **P2:** ask me, in one batch, only the questions the inventory could not
   answer (skill's question bank, ≤10). Wait for my answers.
3. **P3:** verify candidate commands by actually running them; keep an
   evidence log (command, prerequisites, result, workarounds). Show me the
   log before applying anything.
4. **P4:** on my approval, apply — fill/remove every CUSTOMIZE across the
   Sync Triangle, fix `applyTo` globs, delete inapplicable example
   instructions, update the layout map, bootstrap labels, seed provided docs
   into `docs/context/` with provenance. Never touch `AGENTS.md`; never
   write agreements.
5. **P5/P6:** prove (`tuning-status.sh` exits 0; gates run once) and open
   one PR titled `scaffold: onboard <project>` with the evidence log in the
   description, plus the retro-log row and any upstream candidates.
