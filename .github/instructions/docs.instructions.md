---
applyTo: "docs/**"
---

# Documentation Rules (`docs/`)

## Language and voice

- English only, for every file in this tree. Persistent artifacts must read
  identically to every model and every future session; mixed-language docs
  cause nuance drift.
- Write in the imperative for procedures and in plain declarative sentences
  for facts. State *why* a rule exists when it is not obvious.

## The two tiers are different

- `docs/context/` is an **intake area**: raw, possibly redundant, never
  authoritative. Every file starts with the provenance header defined in
  `.github/skills/context-collection/SKILL.md`. Do not "clean up" raw material
  into conclusions here — that is distillation and it happens elsewhere.
- `docs/agreements/` is **reviewed truth**: requirements (`REQ-###`), ADRs
  (`ADR-####`), glossary, non-goals. Files here change **only via pull request**
  with at least one human approval. Never edit them directly on a task branch
  as a side effect of implementation work; if implementation reveals an
  agreement is wrong, open a separate agreements PR and link the two.

## Traceability

- New or changed requirements get the next free `REQ-###` ID; never reuse IDs.
  Superseded requirements are marked `(superseded by REQ-###)`, not deleted.
- ADRs are numbered sequentially from `ADR-0001` and follow
  `docs/agreements/adr/ADR-0000-template.md`. An ADR that reverses a previous
  decision must reference the ADR it supersedes.
- When a decision is made anywhere else (issue thread, PR review, chat), it is
  not an agreement until it lands in `docs/agreements/` through a PR. Copy the
  conclusion, link the discussion.
