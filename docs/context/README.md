# `docs/context/` — Raw Intake Area (Phase 1)

Landing zone for **raw** project information: meeting notes, existing specs,
domain research, exports from external tools, interview answers. Rules and
procedure: `.github/skills/context-collection/SKILL.md`; scoped rules:
`.github/instructions/docs.instructions.md`.

Ground rules (summary — the skill is authoritative):

- One topic per directory: `docs/context/<topic>/`, each with an `INDEX.md`
  (one line per file: what it is, why it matters; conflicts and open
  questions listed at the top).
- Every file starts with the provenance header (source / retrieved / method /
  collector / sensitivity / status). `status: raw` until a distillation pass
  marks it `distilled`.
- Nothing here is authoritative. Agents may read it for background but must
  design against `docs/agreements/` only.
- Completeness beats tidiness; never "clean up" raw material into
  conclusions here — that is distillation
  (`.github/skills/context-distillation/SKILL.md`).
