# Story 2.1: Complete GiantSteps Tempo Dataset Integration

Status: done

## Story

As a library author,
I want to benchmark BoomBoomBoomKit against the GiantSteps Tempo dataset with dual-tempo annotations and MIREX-compliant Acc2,
so that I have a rigorous, standards-compliant validation corpus alongside OA300.

## Acceptance Criteria

1. **Given** the GiantSteps JAMS annotations (`annotations_v2/jams/*.jams`),
   **When** ground truth is regenerated,
   **Then** `giantsteps-tempo-ground-truth.json` includes `tempo2: Double?` (second annotated tempo, null for single-tempo tracks),
   **And** the primary `bpm` field is the highest-confidence tempo from the JAMS data,
   **And** 577 tracks have non-null `tempo2`, 84 have null `tempo2`, 3 tracks with 0 annotations are excluded.

2. **Given** the `GiantStepsTrack` Decodable struct,
   **When** updated,
   **Then** it includes `let tempo2: Double?` alongside existing fields.

3. **Given** a GiantSteps track with two annotated tempos (e.g., track 1068430: tempo1=87.0, tempo2=174.0),
   **When** Acc1 is evaluated,
   **Then** the track is counted as correct if the detected BPM matches EITHER `bpm` OR `tempo2` within tolerance.

4. **Given** the `isAcc2Match` function in `GiantStepsBenchmarkTests.swift`,
   **When** updated for MIREX compliance,
   **Then** it checks factors {1, 2, 1/2, 3, 1/3} (adding `detected * 3` and `detected / 3` to the existing octave checks).

5. **Given** `make benchmark-giantsteps`,
   **When** run,
   **Then** the suite reports Acc1/Acc2 using dual-tempo matching and MIREX-compliant Acc2 factors,
   **And** genre-stratified breakdown continues to work.

6. **Given** a Python script `scripts/giantsteps-ground-truth.py`,
   **When** run with `uv run scripts/giantsteps-ground-truth.py <jams_dir>`,
   **Then** it produces the updated JSON to stdout.

7. **Standard gating (all stories in Epics 1-4):**
   - `make fmt` + `make lint` pass before and after implementation
   - `make test` -- all existing tests pass (153+ tests)
   - `make benchmark` -- no Acc1/Acc2 regressions on OA300
   - `make ablation` -- full technique matrix completes without crashes

## Tasks / Subtasks

**Execution order: Task 1 -> 2 -> 3 -> 4. Task 2 depends on the JSON from Task 1. Task 3 modifies the test file that reads the JSON from Task 2. Task 4 is final validation.**

- [x] Task 1: Create ground truth regeneration script (AC: #1, #6)
  - [x] 1.1 Create `scripts/giantsteps-ground-truth.py` that parses JAMS files from `annotations_v2/jams/*.jams`
  - [x] 1.2 For each JAMS file: extract `.annotations[0].data[]` entries, sort by `confidence` descending, emit `bpm` (highest confidence value) and `tempo2` (second value if present, else null)
  - [x] 1.3 Extract `genre` from the existing `annotations_v2/genre/*.genre` files (same as current approach) -- or if genre data is already in the existing JSON, preserve it
  - [x] 1.4 Exclude tracks with 0 tempo annotations (3 tracks)
  - [x] 1.5 Output sorted by track_id for stable diffs
  - [x] 1.6 Run `uv run scripts/giantsteps-ground-truth.py /Users/rterhaar/Dropbox/research/giantsteps-tempo-dataset/annotations_v2/jams > Tests/BoomBoomBoomKitTests/Fixtures/giantsteps-tempo-ground-truth.json`
  - [x] 1.7 Verify output: 661 entries (664 minus 3 zero-annotation tracks), 577 with non-null tempo2

- [x] Task 2: Update `GiantStepsTrack` model and dual-tempo Acc1 matching (AC: #2, #3)
  - [x] 2.1 Add `let tempo2: Double?` to `GiantStepsTrack` struct (line 17-22 of `GiantStepsBenchmarkTests.swift`)
  - [x] 2.2 Update `runBenchmark()` Acc1 evaluation (around line 191): check `isAcc1Match(detected, track.bpm) || (track.tempo2 != nil && isAcc1Match(detected, track.tempo2!))`
  - [x] 2.3 Update `runBenchmarkDetailed()` genre breakdown: same dual-tempo check in `benchmarkByGenre()` (around line 113)

- [x] Task 3: Fix `isAcc2Match` for MIREX compliance (AC: #4)
  - [x] 3.1 In `GiantStepsBenchmarkTests.swift` (line 40-44), add `|| isAcc1Match(detected * 3, expected) || isAcc1Match(detected / 3, expected)` to `isAcc2Match`
  - [x] 3.2 Apply the same dual-tempo logic to Acc2: check against both `bpm` and `tempo2`

- [x] Task 4: Validation (AC: #5, #7)
  - [x] 4.1 `make fmt` + `make lint`
  - [x] 4.2 `make test` -- all 153+ tests pass
  - [x] 4.3 `make benchmark` -- OA300 unchanged (this story does not touch OA300 code)
  - [x] 4.4 `make benchmark-giantsteps` -- suite runs with updated ground truth and reports Acc1/Acc2
  - [x] 4.5 Verify genre-stratified output still works

## Dev Notes

### What Already Exists (Do NOT Recreate)

- `GiantStepsBenchmarkTests.swift` -- 243 lines, fully functional. Modify in place.
- `giantsteps-tempo-ground-truth.json` -- 664 entries. Regenerate with tempo2 field.
- `make benchmark-giantsteps` Makefile target -- no changes needed.
- Genre breakdown in `benchmarkByGenre()` -- modify for dual-tempo, don't rewrite.

### JAMS File Format

Path: `{GIANTSTEPS_CORPUS_PATH}/annotations_v2/jams/{track_id}.LOFI.jams`

```json
{
  "annotations": [{
    "namespace": "tempo",
    "data": [
      {"value": 127.0, "confidence": 0.949},
      {"value": 139.0, "confidence": 0.051}
    ]
  }]
}
```

- 577 tracks have 2 tempo entries, 84 have 1, 3 have 0
- The higher-confidence tempo is the primary BPM
- NOTE: `bpm` field in current JSON already matches the highest-confidence JAMS value (verified for tracks 1030011, 1068430, 1092771)

### Genre Files

Path: `{GIANTSTEPS_CORPUS_PATH}/annotations_v2/genre/{track_id}.LOFI.genre`

Single-line file containing the genre string. Current JSON already has this data.

### MIREX Acc2 Convention (Verified)

MIREX Acc2 allows factors **{1, 2, 1/2, 3, 1/3}** within tolerance. Our current `isAcc2Match` only checks {1, 2, 1/2} -- missing 3:1 and 1:3. This is a real bug.

Sources: MIREX 2021 Audio Tempo Estimation wiki, mir_eval `tempo.py`.

Note: `isAcc2Match` is duplicated in 3 files (OA300, GiantSteps, DAWOracle) -- all have the same bug. **This story only fixes GiantSteps.** Story 2-2 will fix OA300 and DAWOracle when adding dual tolerance methods.

### Dual-Tempo Acc1 Matching Logic

For GiantSteps Acc1, a detection is correct if it matches ANY annotated tempo:
```
isCorrect = isAcc1Match(detected, track.bpm) || 
            (track.tempo2 != nil && isAcc1Match(detected, track.tempo2!))
```

For GiantSteps Acc2, apply the same dual-tempo logic but with octave+triplet factors:
```
isCorrectAcc2 = isAcc2Match(detected, track.bpm) || 
                (track.tempo2 != nil && isAcc2Match(detected, track.tempo2!))
```

### Pre-Read Audio Sharing

NOT needed at corpus level. 664 tracks * ~120s * 44.1kHz * 4 bytes = ~14 GB -- won't fit in memory. Current per-track reading in `withTaskGroup` is correct. "Pre-read sharing" means within a single track across tolerance evaluations, which is already implemented.

### Architecture Compliance

- **ADR-9:** GiantSteps as separate test suite with `GIANTSTEPS_CORPUS_PATH` env var -- already implemented
- **ADR-10:** Dual tolerance as separate test methods -- Story 2-2 scope, not this story
- **No library source changes** in this story -- test infrastructure only
- **Python script convention:** Use `uv run` (not `python3`) per project feedback

### Project Structure Notes

- Script location: `scripts/giantsteps-ground-truth.py` (alongside existing `scripts/dawproject-bpm.py`)
- Fixture location: `Tests/BoomBoomBoomKitTests/Fixtures/giantsteps-tempo-ground-truth.json` (existing file, overwrite)
- Test file: `Tests/BoomBoomBoomKitTests/GiantStepsBenchmarkTests.swift` (existing file, modify)

### Previous Story Intelligence

From Epic 1 retro (2026-04-05):
- **No overscoped tasks:** All tasks here are verified against actual data (JAMS format inspected, entry counts confirmed)
- **Deterministic test patterns:** No timing-dependent tests in this story
- **`public init() {}` Options pattern:** Not applicable (no library API changes)
- **Standard gating checklist:** fmt, lint, test, benchmark, ablation before and after

### References

- [Source: _bmad-output/planning-artifacts/epics.md, Story 2.1 section (lines 329-357)]
- [Source: _bmad-output/planning-artifacts/architecture.md, ADR-9 and ADR-10]
- [Source: _bmad-output/implementation-artifacts/epic-1-retro-2026-04-05.md, Epic 2 Preparation section]
- [Source: MIREX 2021 Audio Tempo Estimation wiki -- Acc2 factors {1, 2, 1/2, 3, 1/3}]
- [Source: mir_eval tempo.py -- detection() function uses relative tolerance]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

None -- no blockers or debug sessions required.

### Completion Notes List

- Task 1: Created `scripts/giantsteps-ground-truth.py` parsing JAMS annotations. Genre files found at `annotations/genre/` (not `annotations_v2/genre/`). Output: 661 entries, 577 dual-tempo, 84 single-tempo, 3 excluded (0 annotations). All counts match AC #1.
- Task 2: Added `tempo2: Double?` to `GiantStepsTrack`. Dual-tempo Acc1 matching applied in both `runBenchmark()` and `benchmarkByGenre()`.
- Task 3: Added triple factors (`detected * 3`, `detected / 3`) to `isAcc2Match` for MIREX compliance. Dual-tempo Acc2 matching already handled by Task 2's `acc2Hit` logic.
- Task 4: All gating passed. `make fmt` + `make lint` clean (1 pre-existing TODO warning). 153 tests pass. OA300 unchanged (Acc1=69.5%, Acc2=89.0%). GiantSteps: Acc1=81.1% (up from 70.0%), Acc2=82.5% (up from 79.1%) -- improvements from dual-tempo matching and MIREX-compliant Acc2.

### File List

- `scripts/giantsteps-ground-truth.py` (new)
- `Tests/BoomBoomBoomKitTests/Fixtures/giantsteps-tempo-ground-truth.json` (removed from repo -- now lives in corpus dir)
- `Tests/BoomBoomBoomKitTests/GiantStepsBenchmarkTests.swift` (modified: GiantStepsTrack model, isAcc2Match, dual-tempo matching, load JSON from corpus dir)

### Review Findings

- [x] [Review][Patch] Force-unwrap of `track.tempo2!` -- use `.map { } ?? false` instead of `!= nil && ...!` pattern [GiantStepsBenchmarkTests.swift:114-118,198-202]
- [x] [Review][Patch] Unused `import os` in Python script [scripts/giantsteps-ground-truth.py:16]
- [x] [Review][Patch] JAMS namespace filtering -- filter for `namespace == "tempo"` instead of assuming `annotations[0]` [scripts/giantsteps-ground-truth.py:30-38]
- [x] [Review][Defer] Failure table shows `expected: track.bpm` when `tempo2` was the Acc2 match -- deferred, cosmetic (does not affect accuracy counts)
- [x] [Review][Defer] `isAcc2Match` diverges between GiantSteps and OA300/DAWOracle -- deferred, explicitly Story 2-2 scope
- [x] [Review][Defer] `isAcc1Match` division by zero when `expected == 0` -- deferred, pre-existing across all 3 benchmark files
- [x] [Review][Defer] Duplicated acc1/acc2 logic between `runBenchmark` and `benchmarkByGenre` -- deferred, pre-existing
