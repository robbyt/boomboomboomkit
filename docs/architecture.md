# BoomBoomBoomKit — Architecture

This file is a pointer. It was originally scaffolded by the `bmad-create-architecture`
skill at project initialization, before the canonical architecture document moved
to `_bmad-output/planning-artifacts/architecture.md`. Rather than maintain two
architecture docs (and accept the drift that produced the staleness here), we
redirect readers to the canonical source of each kind of architectural fact.

## Where the canonical lives

| Looking for… | Read |
|---|---|
| Current type surface (public + internal types, fields, conformances) | `CLAUDE.md` § "Architecture" → "Key Types" |
| Pipeline step list + stable step-number identifiers | `_bmad-output/project-context.md` § "Pipeline step numbers are stable identifiers" |
| Active KDDs (Key Design Decisions) + ADRs | `_bmad-output/planning-artifacts/architecture.md` (develop-only) |
| Current epic plan + roadmap | `_bmad-output/planning-artifacts/epics.md` (develop-only) |
| Accuracy floors + current measurements | `CLAUDE.md` § "Design Constraints" |
| Release process + file-disposition table | `CLAUDE.md` § "Release Process — what ships to `main` vs stays on `develop`" |
| Public consumer overview | `README.md` |

`_bmad-output/` is develop-only; consumers cloning `main` will not see it. See
`CLAUDE.md` for the release-process file disposition.

## Why this file is a stub, not a rewrite

Pre-1.0; no backwards-compatibility promised; library has zero external consumers
today. The single-source-of-truth canonical lives where the work happens —
`_bmad-output/planning-artifacts/architecture.md` is updated story-by-story via
KDD amendment commits. Re-running `bmad-create-architecture` would target that
canonical (per the skill's configured output path), not this file. Maintaining a
hand-written copy here would be drift-by-construction.
