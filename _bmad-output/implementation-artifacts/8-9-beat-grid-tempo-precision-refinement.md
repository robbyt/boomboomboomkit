---
baseline_commit: 53313c062ba91d3dd0843a4c8961efa0cb67a946
---

# Story 8-9: Beat-Grid Tempo-Precision Refinement

Status: done

## Story

As a developer integrating BoomBoomBoomKit beat grids into a tempo-sync consumer (e.g. a DJ
auto-sync feature),
I want the extrapolated beat grid to stay aligned with the audio across a full track,
so that the grid I lock onto does not slowly slide off the beat even when the detected tempo is
"correct" to within a fraction of a BPM.

## Context

Story 8-7 measured beat-grid accuracy against the Rekordbox-derived JAMS oracle (1264 tracks, 910
constant-tempo, ±70 ms, octave-normalized): beat-position F-measure **0.372**, downbeat correctness
**0.144** at a 4.3% fire rate, FR-29 last-beat drift **P95 1652 ms** (median ~176 ms). The epic's
published targets (0.75 / 0.65 / 30 ms) were never measured — placeholders. Floors were locked at
measured−margin (0.33 / 0.10 / 2.0 s) as regression nets, and `8-7-pressure-release.md` recommended
refining the tracker. The operator chose to do that refinement here, as a NEW story — NOT a reopen
of the `done` Story 8-4 (the tracker works; the *precision ambition* was unmeasured).

**The defect in one line, from a real master ("Arbitrary Arbitrage", 160 BPM):** the BPM stage
reports 160.00 and the grid reports 160.15 — they "agree" as tempo scalars, but the grid extrapolates
at `0.094%` too fast, accumulating ~112 ms of phase drift over a 120 s span (~1/3 of a beat). The
grid starts on the beat at the anchor and walks off it by the end. "Tempo correct" and "grid placed
without drift" are different bars; this story closes the second one.

## Acceptance Criteria

1. **Robust ordinal-aware tempo+phase refit (primary).** A new post-DP step in
   `BeatGridAnalyzer.estimateBeatGrid` fits the detected beat times to a constant-tempo line
   `t_i ≈ phase + m_i · period`, where ordinals are assigned from the period
   (`m_i = round((t_i − anchor) / period)`), NOT the array index — so a single dropped/doubled DP
   beat does not corrupt the slope. The refined `estimatedTempo = 60 / slope` and `gridOrigin`
   (`= phase`) replace the current `let estimatedTempo = tempoBPM` at `BeatGridAnalyzer.swift:344`.
2. **Confidence-weighted, MAD-trimmed fit.** The fit is weighted by `BeatTimestamp.confidence` and
   `.strength`, then refined once: drop residuals beyond ~2.5·MAD (or a fixed fraction of the
   period) and refit. Plain unweighted LS and Theil-Sen are both rejected (LS is outlier-fragile;
   Theil-Sen only if implementation cost is trivial).
3. **Fail-closed guard.** The refit is accepted only if its residual RMS decreases AND its predicted
   long-span drift improves vs. the pre-refit grid; otherwise the original DP-derived
   `estimatedTempo` / `gridOrigin` are kept unchanged. The refit can never ship a worse grid.
4. **Tempo sanity band.** The refined tempo is constrained to a tight relative band around the
   upstream BPM-stage tempo unless an explicit octave/half-time path handles a doubling — the refit
   corrects fractions of a BPM, it must not silently jump octaves.
4a. **Composition with the shipped `BeatGridTempoLock`.** The user-opt-in tempo lock
   (`Options.beatGridTempoLock`, shipped 2026-06-20 — `.off` / `.bpmStage` / `.bpm(Double)`) and
   this automatic refit are complementary and must compose, not collide. Per the Codex design
   review (thread 019ee7ed): **the lock applies AFTER the refit.** The refit improves both tempo
   AND phase from onset evidence; the lock then replaces only the final tempo *scalar* with the
   authoritative (octave-normalized) BPM when the user has opted in. The refit's phase/anchor gains
   still matter under lock, so the lock does NOT make this story redundant. Concretely:
   `applyTempoLock` (`AudioAnalysisService.swift`) runs on the already-refined grid; the refit must
   not assume an unlocked tempo. The drift-P95 acceptance gate (AC #6) is measured with the lock
   `.off` (the refit's own merit), with a locked pass reported separately.
5. **Secondary lever (reported, not gated): parabolic tempogram-peak interpolation.** Sub-bin
   interpolation of the tempogram peak upstream of the DP tracker, measured independently so its
   contribution is separable from AC #1. Ships only if it is net-positive on the corpus.
6. **Acceptance metric = absolute per-track phase-drift P95 (ms)** on oracle-validated
   constant-tempo tracks. F-measure is demoted to a reported diagnostic. The median:P95 spread ratio
   is diagnostic-only (NOT a gate — a ratio can improve because the median worsens). The per-track
   phase-drift P95 **gate** is the retained Story-8-7 regression net (`driftP95GateSeconds = 2.0 s`,
   `BeatGridBenchmarkTests.swift:461-464`) — NOT a newly-introduced assertion. What this story **adds**
   to the acceptance suite is the stratified drift **reporting** (median / P90 / P95 / P99 + the ratio,
   stratified by octave-correct / octave-wrong / variable-tempo / low-confidence / short-vs-long) plus
   the 50 ms aspirational share (reported, not gated).
7. **Oracle audit (precondition for the gate).** Fit the Rekordbox oracle beats THEMSELVES to
   `phase + k · period` and report the oracle's own residual RMS/P95; exclude or separate tracks
   whose oracle is piecewise / hand-warped / coarsely quantized. Comparing our constant-tempo line
   to a piecewise oracle is mis-specified — the drift gate applies only to oracle-validated
   constant-tempo tracks.
8. **Failure-mode decomposition (precondition, parallel).** Over the existing per-track 8-7 output,
   produce: a per-track F histogram; F before/after octave-normalization; drift-vs-track-length
   correlation; the per-track offset distribution; and an isolation of the ~50 worst tracks with
   shared-trait tabulation. This names which bucket (tempo-drift / anchor-phase / octave-half-time)
   the refit actually reaches BEFORE any "we fixed drift" claim is made.
9. **Byte-identity / no-regression.** The `analyzeBPM(url:)` path and default `Options` are
   untouched — the refit runs only inside the `Options.computeBeatGrid == true` gate
   (`BPMAnalyzer.swift:221`), which the default path never reaches. OA300 BPM floors hold
   (`make benchmark`): Acc1 ≥ 57/82, Acc2 ≥ 73/82 (current 58/82, 74/82). Existing beat-grid floors
   hold or rise: drift P95 ≤ 2.0 s, F ≥ 0.33, downbeat ≥ 0.10.
10. **Out-of-scope carve-outs.** Octave/half-time correctness is tracked as its OWN metric (not
    folded into drift). Downbeat detection (0.144 @ 4.3% fire) is EXPLICITLY OUT OF SCOPE — it is a
    separate, much weaker subsystem and must not be conflated with beat-position drift.
11. **Operator decisions recorded (blocking the final gate number).** Both decisions are now
    RESOLVED (2026-06-22):
    - (a) **Drift-P95 threshold — two-tier.** Aspirational musical target = **50 ms** drift-P95,
      carried as a *reported* metric alongside the AC #6 P50/P90/P95/P99 stratification (NOT a merge
      gate). The *committed* regression floor asserted by `make benchmark-beatgrid` is set
      **measured-after-refit − margin** (the 8-7 precedent), finalized in Task 6 once the refit
      produces real numbers — never gate the merge on an unmeasured ambition (8-7's placeholder-target
      mistake). Ratchet the committed floor toward 50 ms over subsequent measurements. Justification:
      onset-asynchrony literature puts perceptually "tight" beat alignment under ~20-30 ms (jazz-trio
      study: listeners preferred asynchronies < 19 ms; natural drummer spread 2-26 ms), so a P95 ≤ 50 ms
      keeps even the worst 5% of tracks inside the beatmatchable zone. The Rekordbox oracle quantizes
      beat positions (`Inizio`) to 1 ms — 50× finer than 50 ms — so oracle numeric precision is NOT the
      binding constraint; correct constant-tempo track selection (AC #7) is. (Codex tie-break was
      attempted but the backend was down at decision time; the literature + oracle inspection were
      decisive without it.)
    - (b) **Downbeat carve-out confirmed.** The metadata-viewer consumer is instrumentation-only;
      nothing gates on downbeat correctness, so downbeat (0.144 @ 4.3% fire) stays OUT of 8-9 scope
      per AC #10.

## Tasks / Subtasks

1. **[x] Decomposition + oracle audit spike** (AC #7, #8) — `decompose_beatgrid.py` re-aggregates the
   8-7 per-track output, fits each oracle to a line, emits the bucket breakdown + oracle residual
   report (`8-9-decomposition.md`). Ran over the full 1264-track artifacts. THE LOAD-BEARING RESULT.
2. **[reverted] Robust ordinal-aware refit** (AC #1–#4) — implemented (period-ordinal two-pass,
   confidence·strength-weighted, MAD-trimmed, fail-closed, anchor snap), then **REVERTED**: the
   authoritative full-corpus `benchmark-beatgrid` showed it **regressed** the F-measure 0.3718→0.3254
   (below the 0.33 floor) while drift was unmoved. Negative result — see Completion Notes.
3. **[x] Per-track drift-P95 acceptance assertion** (AC #6) — stratified median/P90/P95/P99 + med:P95
   ratio (octave-correct/-wrong/variable/low-confidence/short/long) + the 50 ms aspirational report,
   keeping the 2.0 s regression net, in `BeatGridBenchmarkTests.swift`. KEPT (reports on the Story-8.4
   grid; independent of the reverted refit).
4. **[dropped] Secondary lever** (AC #5) — parabolic tempogram-peak interpolation NOT pursued. The
   decomposition shows no fractional-tempo headroom (failures are out-of-scope wrong-pulse F=0 misses),
   and the tempo-refit negative result removes the rationale. Codex (thread 019eedd7) concurs it should
   only be a separately-scoped future experiment, not part of 8-9.
5. **[x] Regression gauntlet** (AC #9) — post-revert: `make test` 706 green; `make benchmark` OA300
   byte-identical (58/82, 74/82); `make benchmark-beatgrid` F restored to the 0.3718 baseline (≥ 0.33),
   drift gate passes (1652 ms ≤ 2000 ms).
6. **[x] Decisions recorded; gate unchanged** (AC #11) — the two AC #11 decisions are recorded. With
   the refit reverted there is no measured improvement to retighten the committed `driftP95GateSeconds`
   to — it stays the 2.0 s regression net (already passing); the 50 ms aspirational target stays a
   reported number. Story 8-7's floors are unchanged (no re-measure needed — the grid is byte-identical
   to 8-7).

### Review Findings

_Adversarial code-review 2026-06-22 (Blind Hunter via Codex + Edge Case Hunter + Acceptance Auditor over the staged change set vs baseline `53313c0`). Negative-result story: `Sources/` byte-identical, so all findings land in the develop-only test/spike code. No HIGH-severity issues._

- [x] [Review][Decision→Patch] AC #6 "new per-track P95 assertion" reads as new but is the retained 8-7 net — `BeatGridBenchmarkTests.swift:461-464` asserts `p95 <= driftP95GateSeconds (2.0 s)`, which is the pre-existing Story-8-7 gate; what this diff actually *added* is the stratified REPORTING + 50 ms aspirational share. **Resolved (operator): patched the AC #6 wording** to state the P95 gate is the retained 8-7 net and the stratified reporting + 50 ms share are what this story adds.
- [x] [Review][Patch] Guard the two `np.corrcoef` calls against zero-variance NaN [decompose_beatgrid.py:209-210] — identical F / clipped-P95 / duration vectors yield `nan` + RuntimeWarning, silently printed as the correlation the report's conclusions rest on; the spec retains this spike for future re-runs, so a degenerate subset can hit it. **Fixed:** added the `corr_or_nan` helper and routed both call sites through it.
- [x] [Review][Patch] "Worst 50" table renders only 25 rows under a "Worst 50" header [decompose_beatgrid.py:220,231] — `worst[:25]` under the `## Worst 50 tracks` heading; the aggregate `n_warped`/`n_variable` are correctly computed over `worst[:50]`, so only the table is a silent 25-row sample. **Fixed:** heading now reads "aggregate over 50, lowest-F 25 listed", mirrored in `8-9-decomposition.md`.
- [x] [Review][Defer] Downbeat gate smoke-skip keyed on `limit > 0`, not on actual partial coverage [BeatGridBenchmarkTests.swift:367] — deferred, extends the surface of already-tracked **8-7-D1** (the F-measure floor uses the same convention; the robust coverage-signal fix in 8-7-D1 applies identically). An oversized `BEAT_GRID_LIMIT` would skip the gate despite full coverage.
- [x] [Review][Defer] Full-run zero-fired-constant downbeat slice false-fails instead of skipping [BeatGridBenchmarkTests.swift:370] — deferred, near-unreachable on the real corpus (~42 constant tracks fire); `meanConstant` defaults to 0 < floor only if NO constant track fires a downbeat on a full run. Pre-existing default, not introduced by this diff.
- [x] [Review][Defer] Even-`n` "median" picks the upper-middle element [BeatGridBenchmarkTests.swift:389,416,449] — deferred, REPORTED-only diagnostics (the gate uses P95); strata are large (hundreds) so the one-element offset is cosmetic. The IBI median at :389 feeds `octaveClass` but the 4% band absorbs a one-element shift.
- [x] [Review][Defer→Patch] Python degenerate-input hardening in the decomposition spike [decompose_beatgrid.py] — **3 of 4 folded into PR #50** after Copilot re-flagged them: empty-`p95s` guard, empty-join fail-fast (`return 1`), and `acc_row.get("basename") or track_id` fallback. The 4th (no file-not-found/JSON-decode handling on `open()`) stays deferred as `8-9-D4` — a traceback is acceptable feedback for a develop-only one-shot spike.

_Dismissed as noise (4): `bool(ct)` string-"false" misclassification — `rekordbox-beats.py:349,381` writes a real JSON bool, so unreachable on the actual oracle; missing-`constant_tempo`-defaults-to-True — oracle always writes the field; no file-not-found handling on the spike's `open()` — a traceback is acceptable operator feedback for a develop-only CLI; "0 ms residual" framing — `%.1f` rounding shorthand, defensible given the 1 ms oracle quantization (sub-0.05 ms true residuals)._

## Dev Agent Record

### Completion Notes

**Outcome: NEGATIVE RESULT — the tempo refit does not work on this corpus and was reverted.**

The headline deliverable (the DP-beat tempo+phase refit) was fully implemented and unit-tested, then
the authoritative full-corpus `make benchmark-beatgrid` run **regressed** the beat F-measure
**0.3718 → 0.3254** (below the committed 0.33 floor) while FR-29 drift was unmoved (median 176→172 ms,
P95 1652 ms unchanged). Per the project rule "when a story's headline deliverable doesn't work, prefer
deletion over a deprecation cycle" (Story 4-6 precedent), and confirmed by a Codex tie-break (thread
019eedd7), the refit was **reverted** — `BeatGridAnalyzer.swift` is byte-identical to its pre-8-9
`HEAD` (`estimatedTempo = tempoBPM`).

**Root cause (the load-bearing finding).** The grid already reported `estimatedTempo = tempoBPM` — the
upstream BPM-stage tempogram+fine-grid estimate. Story 8.4 had *deliberately removed* an earlier
DP-beat re-measurement because it was noisier than `tempoBPM`. The refit re-introduced exactly that
noise: it fits the (noisy) DP beats and moves the tempo off the clean `tempoBPM`. Because the
F-measure scores a FULL-TRACK extrapolation, even a sub-0.1% wrong-direction tempo move accumulates
over hundreds of beats and pushes late beats outside the ±70 ms match window → recall drops → F
regresses. There was no fractional-tempo headroom to capture in the first place: the decomposition
(below) shows the corpus failures are gross wrong-pulse/octave F=0 misses, not fractional drift, and
the drift gate **already passed without the refit** (P95 1652 ms < 2000 ms).

**Shipped (the genuinely-useful parts, kept):**
- **Decomposition + oracle line-fit audit** (`decompose_beatgrid.py` → `8-9-decomposition.md`): the
  oracle is a clean constant-tempo line — **910/910 constant-flagged oracles fit a line at 0 ms
  residual**, `corr(octave-F, oracle-residual) = −0.006`, **0 of the 50 worst tracks** have a warped
  oracle. So the 8-7 drift is genuine grid error (the gate is well-specified), but the corpus is
  dominated by **F=0 wrong-pulse misses** — a separate onset/tempo-detection weakness, out of 8-9
  scope. This is what proves the refit had nothing to gain and names where the real problem lives.
- **Stratified drift-P95 reporting + 50 ms aspirational target** in `BeatGridBenchmarkTests.swift`:
  median/P90/P95/P99 + med:P95 ratio across octave-correct/-wrong/variable/low-confidence/short/long,
  plus the share within the 50 ms musical target (REPORTED, not gated). Reports on the Story-8.4 grid;
  independent of the reverted refit. Also added the missing SMOKE-MODE skip to the in-suite downbeat
  gate so `BEAT_GRID_LIMIT` subset runs don't false-fail (mirrors the F-measure floor's existing guard).
- **AC #11 decisions recorded** (50 ms aspirational + measured−margin committed floor; downbeat
  instrumentation-only) — retained in this spec for the next person who attempts beat-grid precision.

**Verification (post-revert):** `make fmt`/`make lint` clean (1 pre-existing `LUFSAnalyzer.swift:135`
TODO baseline); `make test` **706/706**; `make benchmark` OA300 **58/82, 74/82** (byte-identical);
`make benchmark-beatgrid` full corpus — F restored to **0.3718 ≥ 0.33**, FR-29 P95 **1652 ms ≤ 2000 ms**,
downbeat 0.1444/42 — every floor passes.

### Pending user action (operator-owned)

1. **Separate-LLM `/bmad-code-review`** on the kept change set (benchmark reporting + decomposition
   spike), then the 1Password-signed commit / PR onto `rterhaar/epic-8`.
2. **Epic 8 close-out:** Story 8-7's floors are unchanged (the grid is byte-identical to 8-7, so no
   re-measure is needed) — 8-7 can flip to `done` and the epic retrospective can run. The beat-grid
   precision question is closed as a negative result; any future attempt (e.g. phase-only, or fixing
   the upstream wrong-pulse detection) is a NEW, separately-scoped story per Codex's recommendation.

### File List

- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift` — (reverted to `HEAD`; net unchanged) the refit was implemented here then removed
- `Tests/BoomBoomBoomKitBenchmarkTests/BeatGridBenchmarkTests.swift` — (modified, KEPT) stratified drift report + 50 ms aspirational + downbeat smoke guard
- `_bmad-output/ml-training/decompose_beatgrid.py` — (new, develop-only) decomposition + oracle line-fit audit spike
- `_bmad-output/implementation-artifacts/8-9-decomposition.md` — (new, develop-only) decomposition report (full 1264-track run)

## Dev Notes

- **Insertion point.** `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift` — `estimateBeatGrid(...)`
  begins at line 115; the beats array is built at ~236–326; `let estimatedTempo = tempoBPM` is at
  **line 344**; `selectGridOrigin(beats:estimatedTempo:)` (which the refit must feed) is at line 355
  / defined at 422. The refit slots between the beats construction and `selectGridOrigin`. Tuning
  constants live at ~59–69.
- **Byte-identity mechanism.** `estimateBeatGrid` runs only under `Options.computeBeatGrid`
  (`BPMAnalyzer.swift:221`, default `false`); the production `analyzeBPM` path never reaches it, so
  the BPM result is byte-identical by construction. Lock with the OA300 floors.
- **The value types are not the tracker.** `BeatGrid.swift` / `BeatGridAnchor.swift` /
  `BeatTimestamp.swift` are value types — the DP tracker + grid construction live in
  `BeatGridAnalyzer.swift`. `BeatGrid.init` rebuilds `gridOrigin` from `beats[beatIndex]` and drops
  out-of-range anchors (`BeatGrid.swift:104-110, 213-222`), so the refit must produce an anchor that
  indexes a real beat. `BeatTimestamp.confidence`/`.strength` are `Float` in `[0,1]`, clamped finite.
- **Why the refit works on this corpus.** 8-7's per-track median offset ~0 means the DP beats are
  unbiased on average — a global line fit cuts variance (drift), exactly the failure mode. It is
  octave-inert: on a half-time-tracked track it fits a clean line through the wrong pulse (a no-op,
  never a regression), which is why octave correctness is a separate axis (AC #10).
- **Acceptance harness.** `BeatGridBenchmarkTests.swift` holds `@Suite("Beat-Grid Acceptance
  Benchmark")` (line 107) and `@Suite("Beat-Grid F-measure Floor")` (line 418); floor constants:
  `downbeatCorrectnessFloor = 0.10` (:397), `driftP95GateSeconds = 2.0` (:404), `fMeasureFloor =
  0.33` (:426); the FR-29 drift sub-test is at ~366–386. Run via `make benchmark-beatgrid` (release;
  Swift emits estimated beats JAMS → `_bmad-output/ml-training/eval-beatgrid.py` mir_eval → Swift
  asserts the floor). Oracle from `make oracle-generate-beats` (`scripts/rekordbox-beats.py`,
  develop-only).
- **The demo visualization is the manual debugging surface.** The `rterhaar/demo-beat-grid` branch
  overlays the extrapolated grid + raw beats + downbeats + anchor over the waveform; scrolling to a
  track's end shows the drift directly (the "Arbitrary Arbitrage" 160.15-vs-160.00 case is a ready
  regression fixture). It also now exposes the analysis time cap (`Options.maxSeconds`) and a
  "Lock grid to detected BPM" toggle (`.bpmStage`) so the lock-vs-refit behavior can be eyeballed
  on the same track.
- **The shipped tempo lock (prior art for this story).** `BeatGridTempoLock.swift` +
  `Options.beatGridTempoLock` + `applyTempoLock`/`octaveNormalizedLockTempo` in
  `AudioAnalysisService.swift` (lock honored only on the combined `analyze()` path; pre-lock
  `tempoAgreement` preserved as the diagnostic; target octave-normalized via the existing
  `classifyTempoAgreement` 2% band; default `.off` keeps `analyzeBPM`/OA300 byte-identical at
  58/82, 74/82). The refit lands at the same site and must run *before* `applyTempoLock` (AC #4a).
  `BeatGrid.with(estimatedTempo:)` is the value-forwarder both paths use to swap the tempo scalar
  without a field-enumerating re-init.

## References

- `_bmad-output/implementation-artifacts/8-7-beat-grid-acceptance-corpus-and-mir-eval-f-measure-floor.md`
  (format exemplar + baseline)
- `_bmad-output/implementation-artifacts/8-7-pressure-release.md` (the reopen recommendation)
- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift`, `Sources/BoomBoomBoomKit/BPMAnalyzer.swift`
- `Sources/BoomBoomBoomKit/BeatGridTempoLock.swift`,
  `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` (`applyTempoLock` / `octaveNormalizedLockTempo`),
  `Sources/BoomBoomBoomKit/BeatGrid.swift` (`with(estimatedTempo:)`) — the shipped tempo lock
- `Tests/BoomBoomBoomKitBenchmarkTests/BeatGridBenchmarkTests.swift`
- `scripts/rekordbox-beats.py`, `_bmad-output/ml-training/eval-beatgrid.py`, `make benchmark-beatgrid`

## Change Log

- 2026-06-20 — Spec created. Consensus from a design roundtable (PM/Architect/Dev/Analyst) plus a
  Codex tie-break: robust ordinal-aware refit over plain LS; drift-P95 as the gate (F demoted, ratio
  diagnostic-only); oracle line-fit audit as a precondition; octave separate; downbeat out of scope.
- 2026-06-20 — Updated with the shipped `BeatGridTempoLock` (user-opt-in constant-BPM lock). Codex
  design review (thread 019ee7ed): the lock composes with this refit and applies AFTER it (AC #4a);
  octave-normalize the locked target, preserve the pre-lock agreement diagnostic, combined-path
  only. The refit's drift-P95 gate is measured lock-off; a locked pass is reported separately.
- 2026-06-22 — AC #11 operator decisions resolved. Drift-P95: 50 ms aspirational (reported) +
  measured-minus-margin committed floor (set in Task 6); justified by onset-asynchrony psychoacoustics
  (tight < ~20-30 ms) and the Rekordbox oracle's 1 ms beat-position quantization (precision not the
  binding constraint). Downbeat carve-out confirmed instrumentation-only. Story unblocked for dev.
- 2026-06-22 — Refit implemented + unit-tested (two-pass ordinal-aware, weighted, MAD-trimmed,
  fail-closed, anchor snap; downbeat isolated; 10 tests; stratified reporting; decomposition spike).
- 2026-06-22 — **Refit REVERTED — negative result.** The authoritative full-corpus `benchmark-beatgrid`
  showed the refit regressed the F-measure 0.3718→0.3254 (below the 0.33 floor) while drift was unmoved
  (P95 1652 ms unchanged; the drift gate already passed without it). Root cause: the grid already
  reported the clean BPM-stage `tempoBPM` (Story 8.4 deliberately removed a noisier DP-beat
  re-measurement), and the refit re-introduced that noise — the full-track-extrapolated F-measure
  punishes the accumulated wrong-direction tempo error. Decomposition confirmed no fractional-tempo
  headroom (failures are out-of-scope wrong-pulse F=0 misses on a clean oracle). Per the project's
  delete-don't-deprecate rule + a Codex tie-break (thread 019eedd7), reverted `BeatGridAnalyzer.swift`
  to byte-identical `HEAD`; deleted the refit tests. KEPT the decomposition spike + stratified
  reporting + recorded decisions as the 8-9 deliverable. Post-revert gauntlet: fmt/lint clean, 706 unit
  tests, OA300 byte-identical 58/82·74/82, full benchmark-beatgrid F restored to 0.3718 ≥ 0.33, drift
  gate passes. Story 8-7 floors unchanged (grid byte-identical to 8-7).
