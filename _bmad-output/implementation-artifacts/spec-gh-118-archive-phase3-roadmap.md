---
title: 'GH-118: archive phase3-roadmap.md and repair the links the move breaks'
type: 'chore'
created: '2026-07-28'
status: 'done'
review_loop_iteration: 0
baseline_commit: '2f4d696'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `_bmad-output/planning-artifacts/phase3-roadmap.md` sits beside the live `epics.md` and `architecture.md` with no date marker and no banner, but it was written 2026-03-29: its baselines predate Epics 3-11, most of its proposals shipped long ago (harmonic ratio, click track, duration hint, ML package split), and its "Octave classifier" sketch contradicts the Epic 12 charter's lever ranking. Its three exact contemporaries were archived during Epic 6 prep (`c0a4b17`); it was left behind.

**Approach:** Move it into `planning-artifacts/archive/` under a date-suffixed name, matching how `architecture.md`, `epics.md`, and `prd.md` were archived in that commit. Repair only the two live navigational links the move breaks; leave the dated historical citations pointing at the old path untouched.

## Boundaries & Constraints

**Always:** Follow the `c0a4b17` precedent — date-suffixed filename, content byte-unmodified, `git mv` so history follows. Split inbound references by function: *navigational* (exists so a reader follows it now — must resolve) vs *historical* (records what a document read at the path it had when written — must not be rewritten).

**Ask First:** Whether to also repair the pre-existing dead `prd.md` link one line above the link this change must fix, in both `docs/` files. Outside GH-118's stated scope, but it is the only other dead link in either file, and leaving it ships an index where one line was deliberately repaired and its neighbour knowingly left broken.

**Never:** Edit the roadmap's content. Add a supersession banner — the archived trio got none; `archive/` plus the dated filename is the established signal. Rewrite the stale descriptions in the `docs/` lists ("5 epics, 22 stories", "45 FRs, 20 NFRs") — content drift, not link rot, and a separate sweep. Touch the historical citations below. Archive `implementation-readiness-report-2026-03-31.md` — also a root-dwelling contemporary, but GH-118 does not name it.

</frozen-after-approval>

## Code Map

**Move:** `_bmad-output/planning-artifacts/phase3-roadmap.md` (frontmatter `source: party-mode discussion (2026-03-29)` supplies the suffix) → `_bmad-output/planning-artifacts/archive/`, which already holds `architecture-2026-03-31.md`, `epics-2026-03-31.md`, `prd-2026-03-31.md`.

**Navigational — repair:**
- `docs/index.md:36` -- "Planning Artifacts" list
- `docs/project-overview.md:57` -- "Existing Project Documentation" list
- `docs/index.md:33`, `docs/project-overview.md:54` -- dead `prd.md` link (Ask First); the live PRD on `develop` is `_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-05-25/prd.md`

**Historical — leave verbatim (6 sites):**
- `archive/architecture-2026-03-31.md:7`, `archive/prd-2026-03-31.md:9`, `archive/epics-2026-03-31.md:8` -- `inputDocuments` frontmatter
- `implementation-artifacts/1-1-internal-buffer-reuse-in-bpm-pipeline.md:271`, `implementation-artifacts/3-2-fine-grid-precision-fix.md:242` -- `[Source: ...]` in `done` specs
- `planning-artifacts/implementation-readiness-report-2026-03-31.md:164` -- dated status table

## Tasks & Acceptance

**Execution:**
- [x] `_bmad-output/planning-artifacts/phase3-roadmap.md` -- `git mv` to `archive/phase3-roadmap-2026-03-29.md` -- matches the three files archived in `c0a4b17`
- [x] `docs/index.md:36` -- repoint to the archive path, mark the entry archived -- the link dies otherwise
- [x] `docs/project-overview.md:57` -- same repoint and marker
- [x] `docs/index.md:33`, `docs/project-overview.md:54` -- repoint dead `prd.md` to `prds/prd-BoomBoomBoomKit-2026-05-25/prd.md` -- Ask First resolved 2026-07-28: operator approved including it, so both files end with zero dead links. Descriptions corrected to the new target's own counts (51 FRs / 10 NFRs, per its status line); leaving `45 FRs, 20 NFRs` beside a repointed link would have introduced a fresh falsehood rather than preserved an old one

**Acceptance Criteria:**
- Given the branch head, when every relative link target in the two `docs/` files is resolved against the filesystem, then all resolve (all but `prd.md` if Ask First is declined).
- Given `git log --follow` on the archived path, when run **after the rename is committed** (`git log` cannot see a staged-only rename), then pre-move commits are reachable. Pre-move history at the old path is `802383c`, so the post-commit count is 2.
- Given `git show --stat HEAD`, when inspecting the move, then git records a rename, not add+delete.
- Given a repo-wide grep for the old path **excluding this spec file** (which necessarily quotes the old path 4 times), when run after the change, then exactly the 6 historical citations above remain and no others.
- Given `scripts/promote-to-main.py`, when checked, then every touched path is develop-only, so `make release-preview` is unaffected.

## Spec Change Log

## Design Notes

The one non-obvious call is which of the 8 inbound references to repair, and it splits by function rather than by file type. A navigational reference that dangles makes the index lie about what the project has. A historical citation records what a document read on the day it was written; repointing it to a path that did not exist then buys a link nobody follows at the cost of falsifying the record. The archived trio's own frontmatter still cites `planning-artifacts/prd.md`, dead since `c0a4b17` — that is the precedent, and it is the right one.

## Verification

**Commands:**
- `grep -ho '(\.\./[^)]*)' docs/index.md docs/project-overview.md | tr -d '()' | sort -u | while read -r p; do t="${p#../}"; [ -e "$t" ] && echo "OK $t" || echo "MISSING $t"; done` -- expected: no `MISSING`
- `git log --follow --oneline -- _bmad-output/planning-artifacts/archive/phase3-roadmap-2026-03-29.md` -- expected: more than one commit
- `grep -rn "planning-artifacts/phase3-roadmap.md" --include="*.md" --include="*.yaml" . | grep -v '^./.git/'` -- expected: exactly 6 hits, all historical
- `git show --stat HEAD` -- expected: rename recorded

No build, test, or lint run applies: no Swift, Python, or manifest file is touched.

## Suggested Review Order

**The archival**

- The move itself; content byte-identical, git records a rename, date suffix from its own frontmatter.
  [`phase3-roadmap-2026-03-29.md:1`](../planning-artifacts/archive/phase3-roadmap-2026-03-29.md#L1)

**Links the move forced**

- Repointed and marked archived so the index stops presenting a 2026-03-29 plan as live.
  [`index.md:36`](../../docs/index.md#L36)

- Same repoint in the second index.
  [`project-overview.md:57`](../../docs/project-overview.md#L57)

**Scope extension (approved at checkpoint)**

- Pre-existing dead link; description corrected to the new target's own counts, not left stale.
  [`index.md:33`](../../docs/index.md#L33)

- Same repair in the second index.
  [`project-overview.md:54`](../../docs/project-overview.md#L54)

**Peripheral**

- Records the "5 epics, 22 stories" drift this change deliberately did not sweep.
  [`deferred-work.md:1228`](deferred-work.md#L1228)
