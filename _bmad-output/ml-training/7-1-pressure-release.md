# Story 7.1 — Pressure-Release Log

Develop-only record of the two DD-defined valves and how they resolved during
7.1 implementation. Created so a reviewer does not have to reconstruct these
borderline calls.

## Valve (a) — split-contamination / re-tiering → 7.1a/7.1b split?

**Condition (DD #8):** "if split-contamination > 5% leakage requires re-tiering,
split into Story 7.1a (diagnostics+policy) / 7.1b (split rebuild+audit)."

**Measured:** Tony↔external-eval leakage = **54 / 1,078 trainable = 5.01%**
(54 normalized-title collisions with OA300; 0 with GiantSteps — GiantSteps is
numeric-ID-named, so Tony's human-named DnB cannot collide).

**Decision: NO 7.1a/7.1b split.** The valve's trigger is leakage that *requires
re-tiering*. The 54 collisions are handled by **exclusion before train/val
assignment** (AC5) — they are removed from the trainable split, not re-banded.
The tier policy and the 333/745/241/25 histogram are unchanged; no
`truth_confidence` bound moved. Re-tiering is not required, so the valve does not
fire even though the raw leakage figure sits at the 5% line. The exclusion set +
rationale are recorded in `corpus_splits.json -> tony.excludedCrossCorpus`.

Note the conservative bias (AC5): a normalized-title hit is excluded even for
generic titles, so 54 is an upper bound on true same-recording leaks (excluding a
false-positive from TRAINING is harmless; admitting a true leak inflates the
FR-18 promotion gate). The `Charly (Neekeetone Jungle Rework)` title-collision is
excluded to be safe and is a rework, not the OA300 recording.

## Valve (b) — DnB subgenre asymmetry → drop below 2-per-subgenre

**Condition (DD #8):** "if 8 DnB tracks across {neurofunk, jungle, jump-up,
liquid} are not nameable by ear from Strong+Solid, drop to >= 1-per-subgenre and
document the asymmetry; NEVER substitute non-DnB tracks."

**Measured:** the corpus has no `subgenre` field. On-disk keyword probe over
playlist names + titles + albums: `neurofunk`=0, `jump-up`=0, `liquid`=0
machine-readable hits; only `jungle` (10) and `amen` (103) have any footprint.

**Decision: valve FIRED (provisional tags + operator gate).** A dev agent cannot
classify by ear. The 8 expanded sentinels were selected as representative DnB
Strong/Solid tracks (150-180 BPM) and assigned **provisional** subgenres
(`subgenre_provisional: true`) from the weak available signals (playlist vibe +
tempo band + jungle/amen keyword). The heuristic happened to fill all four
subgenre slots 2-each, but those assignments are NOT by-ear-confident. Final
classification into {neurofunk, jungle, jump-up, liquid} is an **operator gate**
before Story 7.6 consumes the sentinels. No non-DnB substitution occurred. Full
detail in `expanded-sentinels-curation.md`.
