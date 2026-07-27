---
title: 'PRD records the Epic 7 ML gate failure and the BYOW decision (GH-112)'
type: 'chore'
created: '2026-07-26'
status: 'done'
baseline_commit: '093f07a'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Epic 7's v2 model failed both FR-18 bundle gates across three retrains and the epic closed BYOW, but the PRD's Epic B section records none of it. FR-18, FR-24 and FR-25 still read as forward-looking conditionals, and the "Calibration failure" risk names FR-25 as its mitigation even though that metric never ran and its numeric floor was never committed. A reader must find the unplanned Epic 12 charter in `epics.md` to learn the shipped ML path fails its own gates. The `epics.md` coverage total presents Epic 7 as 14 FRs delivered, counting harnesses rather than outcomes, and the retro's H1 says "HELD OPEN" while its own status line and `sprint-status.yaml` say closed.

**Approach:** Append dated amendments in the PRD's established convention (parenthesized italic block, original wording retained above it) to FR-18, FR-24, FR-25 and the calibration risk, carrying the measured numbers and cross-referencing the Epic 12 charter. Qualify the `epics.md` coverage total. Correct the retro H1. Add a dated status update to `MODEL_CARD.md`, which stops at Story 4-6 and tells consumers the infrastructure is "ready to consume a higher-quality model when one is trained" without disclosing that the retrain was attempted three times and failed.

## Boundaries & Constraints

**Always:** Every number traceable to `epic-7-retro-2026-06-05.md` (close-out addendum) or `.../v2-runs/_archive/maskedMelPretrain-seed42-191tracks-rebalance/FR18-RESULT.md`. Amendments are appended, never substituted — the FR-29 (`prd.md:121`) and FR-34 (`:131`) precedent. State what was NOT measured as plainly as what was. `MODEL_CARD.md` ships to `main`: declarative house style, no em-dashes, no BMAD/story/AI-agent references.

**Ask First:** Any change to `sprint-status.yaml` (`epic-7: done` is the operator's recorded close, not drift). Any edit that restates an FR's original requirement rather than appending to it.

**Never:** No changes under `Sources/`, `Tests/`, `Demo/`, `scripts/`, or `Package.swift`. Do not amend the Epic 12 charter's step-1 octave-decode projection (superseded by the GH-141 measurement, but that is GH-166's scope). Do not re-run training or benchmarks — every number already exists.

</frozen-after-approval>

## Code Map

- `_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-05-25/prd.md` — FR-18 `:89`, FR-24 `:101`, FR-25 `:103`, calibration risk `:312`. Convention shown at `:20`, `:121`, `:131`, `:316`.
- `_bmad-output/planning-artifacts/epics.md` — coverage totals `:263`; Epic 7 FR list `:299`; Epic 12 charter `:1781+` (cross-reference target, not edited).
- `_bmad-output/implementation-artifacts/epic-7-retro-2026-06-05.md` — H1 `:1` vs status line `:7`; close-out addendum `:175+` is the source of record.
- `_bmad-output/ml-training/v2-runs/_archive/maskedMelPretrain-seed42-191tracks-rebalance/FR18-RESULT.md` — retrain ladder + per-band cannibalization table.
- `MODEL_CARD.md` — consumer-facing; status section `:5-26` stops at Story 4-6.

## Tasks & Acceptance

**Execution:**
- [x] `prd.md` FR-18 — amend with the authoritative 2026-06-09 run (`maskedMelPretrain` seed 42, featureSetVersion v2, tempo-band rebalanced, 1,534-track corpus): OA300 43/82 vs > 55/82 and GiantSteps 348/661 vs ≥ 537/661, both FAIL; the ladder OA300 50 → 48 → 43 and GiantSteps 296 → 330 → 348 showing structural rather than data-volume failure; gates (a) and (d) never evaluated because the decision DAG is monotone-downgrade-only; ML scored at 4% tolerance against DSP floors measured at 2% and still 189 tracks short; decision BYOW (`epic7CloseDecision="byow"`, gitTag `epic-7-close`). Cross-reference the Epic 12 charter.
- [x] `prd.md` FR-24 — amend: net-benefit never ran. No matched two-arm pair exists (the `supervisedAugmented` snapshot is stale, corpusHash `2294f44a` vs the authoritative `25e59a18`), so the gate was structurally un-runnable.
- [x] `prd.md` FR-25 — amend: neither the calibration metric nor its numeric floor was ever committed, and verification never ran. The FR's own precondition ("committed before Epic B is considered complete") went unmet and Epic B closed anyway.
- [x] `prd.md` calibration risk — amend: the named mitigation did not fire, so the risk is unretired rather than mitigated.
- [x] `epics.md:263` — qualify "Epic 7 = 14 FRs" as harnesses shipped, naming FR-16 (delivered, outcome unmet — the model still octave-doubles), FR-18 (evaluated, failed), FR-24 and FR-25 (never run).
- [x] `epic-7-retro-2026-06-05.md` — correct the H1 to match the file's own status line and `sprint-status.yaml`.
- [x] `MODEL_CARD.md` — add a dated status update disclosing the v2 outcome and that no model bundles; consumers wire their own via `BNNSTechnique(modelURL:)`.

**Acceptance Criteria:**
- Given a reader opens the PRD at FR-18 with no other artifact, when they finish the FR, then they know both gates were measured, both failed, by how much, and that the outcome was BYOW.
- Given a reader reaches the `epics.md` coverage total, when they read "Epic 7 = 14 FRs", then adjacent text prevents them concluding 14 outcomes were achieved.
- Given every original FR sentence present before the change, when the file is diffed, then none was deleted or reworded.
- Given `MODEL_CARD.md` after the change, when scanned, then the new text has no em-dashes, no BMAD/story/AI-agent references, and no claim that a bundled model exists.

## Design Notes

FR-29 (`prd.md:121`) and FR-34 (`:131`) both keep the original aspiration verbatim and append a bolded status correction stating the measurement, the gate it missed, and what the number does *not* establish. Follow that shape.

Precision trap: the FR-18 gate figures (GiantSteps 537/661, OA300 55/82) are DSP reference points measured at 2% tolerance, while the ML evaluation scored Acc1 at 4%. That comparison is generous to ML, not unfair to it, and saying so keeps the record honest rather than merely damning.

## Verification

**Commands:**
- `git diff --stat` — expected: only the five documentation files above.
- `grep -n -E 'BYOW|43/82|348/661' .../prd.md` — expected: matches inside the FR-18 amendment (zero matches before the change).
- `git diff -- .../prd.md | grep '^-' | grep -v '^---'` — expected: no removed lines; the change is additive.

**Manual checks:**
- Read each amended FR end-to-end: the original requirement still reads as originally written, the amendment is clearly demarcated as a later status correction.
- The Epic 12 cross-reference names the charter's location so a reader can follow it without searching.
