# `docs/agreements/` — Reviewed Truth (Phase 2)

The distilled, human-approved knowledge every agent designs against.
Produced from `docs/context/` by
`.github/skills/context-distillation/SKILL.md`; change control by
`.github/instructions/docs.instructions.md` (**PR + human approval only** —
merge is what makes something an agreement).

| File | Holds |
|---|---|
| `requirements.md` | Verifiable requirements, one `REQ-###` each |
| `non-goals.md` | Explicit "we will not" list |
| `glossary.md` | Project vocabulary |
| `adr/ADR-####-<slug>.md` | One architectural decision per record |
| `retro-log.md` | Ledger of system improvements (`retro:` PRs) |

Task issues cite these by ID (`REQ-###`, `ADR-####`); acceptance criteria
trace back here. If work reveals an agreement is wrong: stop, open a separate
agreements PR, link the two (do not edit agreements as a side effect of an
implementation branch).
