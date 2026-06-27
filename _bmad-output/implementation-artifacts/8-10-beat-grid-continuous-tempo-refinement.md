---
baseline_commit: ac490347b7098a664e30530298becbd135a96015
---

# Story 8.10: Continuous beat-grid tempo refinement (sub-0.1-BPM) + drift-rate acceptance harness

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **DJ-sync / beat-grid consumer** (the Rekordbox-style `gridOrigin` + `estimatedTempo` extrapolator),
I want **the grid's tempo refined to sub-0.1-BPM precision from the audio's own onset evidence, seeded by the BPM detection result**,
so that **the extrapolated grid does not drift off the beat by the end of a multi-minute track** (today's dominant beat-grid accuracy loss).

## Context & why this story exists

Story 8-7 measured the beat grid against the Rekordbox JAMS oracle: beat-position F-measure **0.37** (aspirational target 0.75) and FR-29 P95 last-beat drift **1652 ms** (target 30 ms). Per `8-7-pressure-release.md` §2 the dominant failure is **tempo precision, not phase placement**: per-track median offset is ~0, but the within-track spread is 50–100 ms because the grid's `estimatedTempo` differs from the reference BPM by a few **tenths** of a BPM, and that rate error accumulates as a lever arm (`beat[n] = anchor + n·(60/tempo)`) across the track.

The grid emits `estimatedTempo = tempoBPM` **verbatim** from the BPM stage (`BeatGridAnalyzer.swift:344`). The BPM stage is tuned to pick the right tempo/octave within ~2–4% (OA300 Acc1 70.7%) — plenty to *name* the track, far too coarse to *extrapolate* a grid over hundreds of beats. This story tightens that one number to sub-0.1-BPM by fitting against the audio's own onset evidence.

This story is **pillar 1 of 3** in the beat-grid accuracy follow-up (the work `8-7-pressure-release.md` recommended; 8-7 is now `done`). The split (operator decision 2026-06-23): **8-10** = continuous tempo refinement (this story, the measurable 80% drift win); **8-11** = drop-anchored downbeat / measure-top inference (the 8/16/24/32-bar idea; builds on the Story 8-5a `DownbeatAnalyzer`); **8-12** = manual anchor reposition. Scope decided via party-mode + two Codex consults (thread `019ef269`).

## Key Design Decisions (DD)

1. **Refine the rate, keep the shape.** The public contract stays one anchor (`gridOrigin`) + one tempo (`estimatedTempo`), extrapolated. No new public grid shape. The refined value is reported **as `BeatGrid.estimatedTempo` only** — the Rekordbox one-number model (Codex: do NOT keep the coarse BPM as the grid tempo while secretly extrapolating a refined period). **The public `BPMResult.bpm` (`bpm.bpm`) is UNTOUCHED** — the grid is a step-11 fan-out that does not feed BPM winner selection (`BPMAnalyzer.swift:219`). So on the BPM-only path a consumer may legitimately see `bpm.bpm` and `bpm.beatGrid.estimatedTempo` differ by tenths of a BPM (and `tempoAgreement == .notCompared`); that is intended — document it as a consumer note so it is not filed as a bug. The coarse pre-refinement tempo survives only as a diagnostic (DD #6).

2. **Fit against continuous interpolated onset evidence, NOT integer DP beat intervals.** This is the load-bearing decision and the trap that sank the two prior attempts. Story 8.4 re-measured tempo from integer-frame inter-beat-interval medians (each diff carries ~one onset frame ≈ 2% of the period of quantization) → ~0.2 BPM noise → reverted. Story 8.9's DP-beat tempo+phase refit regressed F 0.3718→0.3254 → reverted (`BeatGridAnalyzer.swift` is byte-identical to that revert). The refit must operate at **sub-frame** resolution, **jointly optimizing BOTH period AND phase as free search dimensions**: maximize the **interpolated** onset-envelope comb *support* `score(period, phase) = Σ wₖ · onsetInterp(anchorTime + k·period)` (higher support = better) over the usable span, seeded at `tempoBPM`. The DP beats AND their phase are *initialization only* and a circularity hazard (phase-locked to the seed period); they are never the fitted observation, and the refit must **NOT hold phase fixed at a DP anchor** — doing so re-inherits the seed phase bias that sank 8.9.

3. **Bounded adaptive period window — and the window IS the octave safety.** Search a window around the seed `tempoBPM` (period domain), clamped so it (a) cannot reach a half/double-tempo octave and (b) stays within the envelope length `n` frames (a too-long period → zero comb taps → degenerate). Because the window cannot reach `2·seed` / `seed/2`, **no separate octave-band rejection is needed** — assert the window bound, do NOT ship a dead `2·seed`-band check that can never fire under a few-percent window (Grumbal: one guard would make the other theater). Any octave comparison that is needed reuses the existing 2% comparator (`octaveEquivalenceFactor` / `classifyTempoAgreement`), not a hand-coded second `< / <=`. Width is adaptive: narrow for a high-confidence BPM, wider for weak — wide enough to correct a real 0.3–0.8 BPM error. Octave selection stays the BPM stage's job (the DP tracks AT `tempoBPM`, not an octave of it).

4. **Reject-guard scored by the IDENTICAL fit objective → monotonic.** (This is the blocker the room flagged; "residual" was loose error-language that inverted DD #2's *support*.) Score the seed period and the refined period by the **same DD #2 support objective** — same weights `wₖ`, same in-bounds tap set / usable span, each period evaluated at *its own* argmax phase — computed against the track's *own* onset evidence (NOT any oracle; the oracle is the benchmark, not a runtime input). **Accept the refined tempo iff `support_refined > support_seed`** (strict; no epsilon margin that admits noise, no epsilon-equality that ships noise as a "win"). A guard whose metric disagrees with the fit objective, or that scores the two periods at different phases, re-opens the exact back door that regressed 8.9.

   **Finite-positive precheck (mandatory, before the comparison AND before any assignment):** the refined value must be `isFinite && > 0`. A non-finite/≤0 period (comb argmax at a window edge → `60/period` = `0`/`±Inf`/`NaN`) would otherwise launder to the `0.0` "no estimate" sentinel at `BeatGrid.init` (`BeatGrid.swift:199`), silently turning a good seed grid into "no tempo," and reaches the pre-construction consumers `selectGridOrigin` / `DownbeatAnalyzer.estimate` raw. `refineTempo` must therefore RETURN only the seed or a bounded-positive-finite value — the construction clamp is a backstop, not the guard.

   **On reject / abstain, return the seed's *original binding* `tempoBPM`** — NOT a recomputed `60·onsetRate/period`, which round-trips through quantization and perturbs the low bits (the 8.4 trap; it applies to the rejected value exactly as to the fitted one). Worst case is then literally byte-identical to HEAD.

   **Minimum-span abstain:** below a floor number of comb periods / beats (the lever-arm baseline a sub-0.1-BPM fit needs — a 2–3-tap fit is unstable), the refit returns the seed unconditionally. This is also why the refit frequently abstains on the short default `.analysisWindow` (~30 s) coverage and delivers its precision on `.fullTrack` spans (see AC #9 / Dev Notes).

5. **Opt-in `refineBeatGridTempo: Bool = false`, byte-identical default.** Add a `Bool` named **`refineBeatGridTempo`** to `AudioAnalysisService.Options` (mirrors the shipped `detectDownbeats` / `beatGridTempoLock` pattern; NOT a new enum, and NOT named `refineTempo` — that collides with Task 1's private method). Default OFF → default-options output byte-identical to the pre-story pipeline (paired `Double.bitPattern` opt-out test asserting the FULL `BeatGrid` graph + `bpm`/`confidence`/`candidates`, per the byte-equality-opt-out discipline). The refinement runs INSIDE `BeatGridAnalyzer.estimateBeatGrid` where `onsetEnvelope` / `acf` / `frames` are in scope (it CANNOT live in `applyTempoLock`, which only sees the finished grid scalar). **Threading trap:** the combined-path grid is built in `AudioAnalysisService.beatGrid(decoded:)`, which constructs its own `BPMAnalyzer.Options` at **two** sites (`:1479` and `:1492`) — the flag must be threaded into BOTH, or `analyze()` / `analyzeBeatGrid()` silently never refine while `analyzeBPM` does, and the default-OFF opt-out test (OFF everywhere) will not catch the hole. **Lock precedence (stated once, here — do not restate elsewhere):** on the combined `analyze()` path a `beatGridTempoLock` other than `.off` OVERRIDES the auto-refined tempo; in particular `.bpmStage` replaces it with the *coarse* stage BPM and DISCARDS the sub-0.1 precision (intended — document so a vanished refinement is not filed as a bug), while a `.bpm(NaN/≤0/>octave)` lock is a documented no-op so the refined tempo stands. Completion Notes decide whether to flip the default after measuring the lift (a separate decision gated on AC #9, not part of this story's `done`).

6. **Diagnostic state designed before the technique (splittable if time-boxed).** Surface the pre-refinement (coarse) tempo, the refined tempo, both support scores, and `accepted: Bool` on `BPMDiagnosticTrace` (gated by `enableTrace`), as a typed `Sendable, CustomStringConvertible` evidence struct following the established `SubBandVoteEvidence` before/after/changed-bool convention (NOT a `[String:…]` dict — the four banned trace shapes; all five `bpm-diagnostic-trace` audit recipes must return zero matches). This makes "did the reject-guard fire, and by how much" debuggable from a single corpus run. **Note:** the guard's behaviour is ALSO observable via AC #9's impact JSON (`changedTempo` / `improvedTempoError` / `worsenedTempoError`) and AC #8's unit tests — so this trace struct is the *nice* surface, not the only one. It is the first thing to split into a fast-follow if the story runs long; do not let it block the proof-of-lift.

7. **Acceptance metric = drift-rate / tempo error against the OA300 DAW-verified oracle, via the EXISTING harness** (operator decision). The DAW oracle (`daw-oracle.json`, Bitwig-verified BPMs, diagnostic TRUTH) gives manually-verified per-track BPM — and drift is purely a function of tempo error, so a verified BPM is sufficient truth to score grid precision without hand-marked beat positions. **Reuse `DAWOracleBenchmarkTests`'s oracle loader** (`oracleByFilename`) — add the ON-vs-OFF tempo-error comparison as a NEW test case in that suite, NOT a from-scratch env-gated harness (Dana: the loader, by-filename lookup, and parallel per-track analysis already exist). The committed regression floor is a **post-measurement output**: implement → run → record the measured lift in Completion Notes → THEN commit a floor at (measured lift − small margin). It is not a precondition number that can be written before the code runs. The Rekordbox JAMS F-measure (`make benchmark-beatgrid`) is a SECONDARY compatibility/regression signal (must not regress below the existing 0.33 floor). The aspirational 0.75 / 30 ms is explicitly NOT a gate (a single-tempo grid against a corpus including drifting vinyl is red-on-arrival against 0.75 — see Out of scope).

## Acceptance Criteria

1. A continuous, sub-frame tempo-refinement step is added to `BeatGridAnalyzer.estimateBeatGrid` that, seeded at the single-window DSP `tempoBPM`, jointly searches a bounded adaptive period window AND phase, and returns the (period, phase) maximizing interpolated onset-comb support over the usable span. It reuses the existing in-scope signals (`onsetEnvelope`, `acf`, `frames`, `onsetRate`) — **no new onset/FFT feature-extraction pass** (a scoped ADR-3 scratch buffer for the interpolation/accumulation is allowed; "no new pipeline allocation" was over-claimed) (DD #2, AC-ref `BeatGridAnalyzer.swift:115`/`:344`).

2. The refinement NEVER uses integer DP inter-beat intervals or their median as the fitted tempo observation (DD #2 — the reverted 8.4 approach). A code-level assertion or test pins that the fitted value comes from the continuous onset-comb objective.

3. A reject-guard makes the change monotonic, scored by the **identical DD #2 support objective** (same weights, same in-bounds tap set, each period at its own argmax phase, against the track's own onset evidence — never an oracle): the refined tempo is accepted iff `support_refined > support_seed` (strict). Before the comparison and before any assignment the refined value is prechecked `isFinite && > 0` (else it would launder to the `0.0` sentinel at `BeatGrid.swift:199`). Below a minimum comb-period/beat-span floor the refit abstains. On reject/abstain, `estimatedTempo` is the seed's ORIGINAL `tempoBPM` binding — not a recomputed `60·onsetRate/period` — so the rejected path is bit-pattern-identical to HEAD (DD #4).

4. The search window is bounded so it (a) cannot reach a half/double-tempo octave and (b) stays within the envelope length `n`; that bound IS the octave safety (no separate `2·seed`-band check — it could never fire under a few-percent window). Any octave comparison reuses the existing 2% comparator (`octaveEquivalenceFactor` / `classifyTempoAgreement`), not a hand-coded second comparator (DD #3).

5. The refinement is opt-in via `Options.refineBeatGridTempo: Bool` defaulting OFF, threaded into BOTH `BPMAnalyzer.Options` constructions in `AudioAnalysisService.beatGrid(decoded:)` (`:1479`, `:1492`); with it OFF, `analyze` / `analyzeBeatGrid` / `analyzeBPM` output (`bpm`, `confidence`, `candidates`, and the full `BeatGrid` graph) is **byte-identical** (`Double.bitPattern`) to the pre-story pipeline, proven by a paired opt-out test using a shared `static` helper (DD #5).

6. When refinement is ON, the refined value is reported as `BeatGrid.estimatedTempo` (`bpm.bpm` is unchanged), and the refined tempo is set BEFORE `selectGridOrigin` so the `gridOrigin` anchor is phase-consistent with the refined period. `BeatGridTempoLock` precedence is tested as a matrix — `{refit ON} × {.off, .bpmStage, .bpm(valid), .bpm(NaN/≤0/>octave)}` — asserting which tempo scalar survives (a non-`.off` lock OVERRIDES the refined tempo; the `.bpm(NaN/≤0/>octave)` no-op cell leaves the refined tempo standing) AND that standalone `analyzeBeatGrid` ignores the lock (DD #1, #5).

7. A typed evidence struct on `BPMDiagnosticTrace` (gated by `enableTrace`) surfaces `{ coarseTempo, refinedTempo, residualSeed, residualRefined, accepted: Bool }` (or equivalent), `Sendable, CustomStringConvertible`; all five `bpm-diagnostic-trace` audit recipes return zero matches against `Sources/` and `Tests/` (DD #6).

8. Unit tests (no corpus): a synthetic constant-tempo click at a fractional BPM (e.g. 127.3) fitted from a **deliberately coarse seed** (disable `.fineGridRefinement` so the seed quantizes >0.1 BPM off — otherwise the already-sub-BPM `.optimal` seed makes "strictly closer" unsatisfiable and AC #8 collides with AC #3) yields `estimatedTempo` within ±0.05 BPM of truth AND strictly closer than the seed; the reject-guard returns the seed (bit-pattern-identical) on aperiodic AND flat-constant envelopes; the minimum-span abstain returns the seed on a too-short window; octave safety holds on a half-time-seeded fixture.

9. A new test case **in the existing `DAWOracleBenchmarkTests` suite** (reusing its `oracleByFilename` loader — not a new harness) scores the DAW-verified oracle (tempo error + predicted last-beat drift over track length) with refinement ON vs OFF, emits a per-track impact JSON to `_bmad-output/implementation-artifacts/8-10-tempo-refine-impact.json` (schema includes `changedTempo`, `improvedTempoError`, `worsenedTempoError`, `total`). The committed regression floor is recorded AFTER the first measured run (Completion Notes), then asserted at (measured lift − margin) — it is a post-measurement output, not a precondition, and never the aspirational target. Because sub-0.1-BPM precision needs a long baseline, this measures on `.fullTrack` coverage. The Rekordbox `make benchmark-beatgrid` F-measure is a secondary regression check and must not regress below the existing 0.33 floor (DD #7).

10. The four corpus accuracy floors (OA300 Acc1 ≥ 57/82, Acc2 ≥ 73/82; GiantSteps Acc1 ≥ 537/661, Acc2 ≥ 546/661) hold unchanged — refinement touches only the beat-grid tempo, never BPM winner selection (`BeatGrid` is a step-11 fan-out that does not feed BPM selection, `BPMAnalyzer.swift:219`).

## Out of scope (explicit)

- **Drop-anchored downbeat / measure-top inference** (the 8/16/24/32-bar idea) → **Story 8-11**.
- **Manual anchor reposition** ("click a new start position") → **Story 8-12**. (The manual *BPM* lock half already ships as `BeatGridTempoLock.bpm(Double)` + `BeatGrid.with(estimatedTempo:)`.)
- **Variable-tempo / multi-segment grids.** The DP tracker is fixed-period; a single global refined period CANNOT fit genuinely-drifting vinyl/jungle. This is the residual error floor after refinement and needs a multi-anchor architecture — a separate future epic, not reusable from a single-tempo output. On such material the grid stays constant-tempo; consider a future "constant-tempo unreliable" flag (not this story).
- **ML tempo** (resolves to ~1 BPM, two orders too coarse) and **rebuilding the DP phase tracker** (median offset ~0 — the beats are placed fine; the tracker is not the failure).
- **Chasing F=0.75 against the auto-analyzed Rekordbox oracle** as a hard gate (DD #7).

## Tasks / Subtasks

- [x] **Task 1 — Continuous onset-comb tempo refinement** (AC: 1, 2, 3, 4)
  - [x] Add a private `refineTempo(seedBPM:onsetEnvelope:acf:frames:onsetRate:) -> Double` to `BeatGridAnalyzer` that jointly searches a bounded adaptive (period, phase) window around the seed, scoring interpolated onset-comb SUPPORT (maximize); returns the refined BPM or the seed. All interpolation taps clamped to `[0, n)` (guard `idx+1 < n`) — no buffer over-read (the `windowMax`/`acf`-lag guard precedents at `:272`/`:497`).
  - [x] Implement sub-frame onset interpolation (linear or parabolic) for the comb evaluation; use vDSP for bulk accumulation where the access pattern allows (control-flow loop over comb taps wrapping vDSP is fine). Guard the parabolic-vertex denominator against zero (flat objective).
  - [x] Reject-guard scored by the SAME support objective at each period's own argmax phase over the same in-bounds tap set; accept iff `support_refined > support_seed` (strict). Precheck `refined.isFinite && > 0` before compare/assign. Below the minimum-span floor, return the seed. On reject/abstain, `return seedBPM` (the original binding, NOT a recomputed value).
  - [x] Bound the period window against BOTH a half/double octave AND the envelope length `n` — the window bound is the octave safety; reuse `octaveEquivalenceFactor`/`classifyTempoAgreement` for any octave test. No standalone `2·seed`-band check.
  - [x] Wire the result into `estimateBeatGrid` at the `estimatedTempo = tempoBPM` site (`:344`) behind the new flag — set the refined tempo BEFORE the `selectGridOrigin(estimatedTempo:)` call (`:355`) so the anchor is phase-consistent with the refined period.
- [x] **Task 2 — Options surface + threading** (AC: 5, 6)
  - [x] Add `refineBeatGridTempo: Bool = false` to `AudioAnalysisService.Options` (ADR-11) and `BPMAnalyzer.Options` (mirror `detectDownbeats`); thread to `BeatGridAnalyzer.estimateBeatGrid`.
  - [x] Thread the flag into BOTH `BPMAnalyzer.Options` constructions in `AudioAnalysisService.beatGrid(decoded:)` (`:1479`, `:1492`) — miss one and the combined paths silently never refine.
  - [x] Document `BeatGridTempoLock` precedence on the `refineBeatGridTempo` doc-comment: `applyTempoLock` (combined path, `:1621`, called `:1573`/`:1600`) overrides the refined tempo with `.bpmStage`/`.bpm`; `.bpmStage` discards the sub-0.1 precision.
- [x] **Task 3 — Diagnostic evidence** (AC: 7)
  - [x] Add the typed evidence struct + a `BPMDiagnosticTrace` field (gated by `enableTrace`); conform `Sendable, CustomStringConvertible`.
  - [x] Run the five `bpm-diagnostic-trace` audit recipes; confirm zero matches.
- [x] **Task 4 — Unit tests** (AC: 8)
  - [x] Fractional-BPM synthetic click (127.3) from a deliberately coarse seed (`.fineGridRefinement` disabled): refined within ±0.05 BPM and strictly closer than seed.
  - [x] Reject-guard returns the seed (bit-pattern-identical) on aperiodic AND flat-constant envelopes; minimum-span abstain returns the seed on a too-short window.
  - [x] Octave-safety on a half-time-seeded fixture.
  - [x] Refit ON × `BeatGridTempoLock` matrix (`.off`/`.bpmStage`/`.bpm(valid)`/`.bpm(NaN/≤0/>octave)`); standalone `analyzeBeatGrid` ignores the lock.
  - [x] Byte-identity opt-out test (AC #5): default-OFF full-`BeatGrid`-graph + `bpm`/`confidence`/`candidates` bit-pattern-equal to pre-story (shared static helper, not hand-replicated logic).
- [x] **Task 5 — Drift-rate acceptance (existing oracle harness)** (AC: 9)
  - [x] Add a test case to `DAWOracleBenchmarkTests` (reuse `oracleByFilename`): |refined − verified| vs |coarse − verified|, predicted last-beat drift over track length, ON vs OFF, `.fullTrack` coverage.
  - [x] Per-track impact JSON + a `make` target (mirror `make beat-grid-impact-report`). Record the measured lift in Completion Notes, THEN commit a floor at (measured − margin).
  - [x] Secondary: `make benchmark-beatgrid` F-measure not below 0.33.
- [x] **Task 6 — Corpus regression + gating** (AC: 10)
  - [x] `make fmt`, `make lint`, `make test`, `make benchmark`, `make benchmark-giantsteps`; record exact integer counts in Completion Notes.

## Dev Notes

### Architecture & source tree

- **`Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift`** (UPDATE) — internal enum, fixed-period Davies & Plumbley / Ellis DP (`tightness=100`, `alpha=0.8`). `estimateBeatGrid(...)` (`:115`) produces `frames` (DP beat indices) and `beats`, then sets `estimatedTempo = tempoBPM` (`:344`). The refinement inserts between the DP backtrace and that assignment (set the refined tempo BEFORE `selectGridOrigin` at `:355`). **REWRITE the DocC rationale at `:328`–`:344`, do NOT "extend" it:** that paragraph currently asserts `tempoBPM` is "the right value to report," which 8-10 negates — the integer-median re-quantization of 8.4 stays the wrong move, but the new continuous *comb* refit is the distinguishing mechanism that makes a re-measurement correct this time. Pre-insertion degenerate guards (`:129`/`:137`/`:149`) run upstream, so the refit inherits them.
- **`Sources/BoomBoomBoomKit/BPMAnalyzer.swift`** (UPDATE) — `estimateBeatGrid` (`:611`) and the step-11 fan-out (`:549`) call `BeatGridAnalyzer.estimateBeatGrid(... tempoBPM: bpm ...)`. Thread the new flag through `BPMAnalyzer.Options`. The grid is a step-11 fan-out that does NOT feed BPM winner selection (`:219`) — so AC #10 holds by construction.
- **`Sources/BoomBoomBoomKit/AudioAnalysisService.swift`** (UPDATE) — add `refineBeatGridTempo: Bool` (ADR-11; near `beatGridTempoLock` at `:350`) AND thread it into BOTH `BPMAnalyzer.Options` builds inside `beatGrid(decoded:)` (`:1479`, `:1492`). `applyTempoLock` (`func` at `:1621`, doc-comment from `:1614`; called at `:1573`/`:1600`) keeps overriding the auto tempo with `.bpmStage`/`.bpm` — refinement feeds the auto path, lock is the explicit override.
- **`Sources/BoomBoomBoomKit/BeatGrid.swift`** — the refit sets the refined tempo as a local at the `:344` site (feeding the single `init` at `:388`), so `with(estimatedTempo:)` is NOT the analyzer-side mechanism; `with(estimatedTempo:)` (`:260`) is the *lock-path* forwarder in `applyTempoLock`. The clamping `init` (`:199`) is the construction-time backstop — but the refit must return finite-positive (AC #3), not rely on the clamp.

### Constraints (from project-context.md)

- Swift 6 strict concurrency; all new public types `Sendable`. Value types only (structs/enums, static methods). Analyzers NEVER throw (return the seed/grid). vDSP for all bulk numeric ops — no manual `for` over sample buffers (control-flow loops wrapping vDSP are fine). `vDSP_Length(...)` on all counts.
- **Byte-equality opt-out is the regression backbone** for any `Options`-gated accuracy feature (AC #5). Expose a shared `static` helper for any logic the opt-out test mirrors; do not hand-replicate.
- **Per-track impact report is mandatory** for accuracy-affecting techniques (AC #9). If `changedTempo == 0` at default, say so honestly in Completion Notes.
- Diagnostic/evidence payloads use named typed `Sendable` value types, never `[String:…]` (AC #7; `bpm-diagnostic-trace` skill, recipes A–E).
- Pre-1.0: no BC promised — prefer the clean surface. Pipeline step numbers are stable identifiers (this is still step 11; do not renumber).

### Diagnostic state (designed before the technique — project rule)

The technique's failure modes (reject-guard fired? octave-snapped? refined the wrong direction?) are NOT observable via the existing trace surface. AC #7's evidence struct answers, from a single corpus run: the coarse seed, the refined value, both residuals, and whether the refinement was accepted. Without it, debugging a drift regression means re-instrumenting by hand (the Story 4-6 `MLDiagnosticSnapshot` precedent).

### Acceptance harness notes

- **DAW oracle** (`daw-oracle.json`, corpus-local, JAMS-migrated by Story 8-8b; `DAWOracleBenchmarkTests`) = Bitwig-verified BPMs = diagnostic TRUTH (primary here). Three-way harness already loads it. Drift-rate = `f(tempoError)`, so verified BPM alone scores precision; no hand-marked beats needed.
- **Rekordbox JAMS** (`make benchmark-beatgrid`, `rekordbox-beats.jams.json`) = auto-analyzed peer = SECONDARY compatibility (the 8-7 F-measure floor 0.33 must not regress).

### Previous Story Intelligence (PSI)

- **Story 8-9** (`f8f2600`, beat-grid tempo-precision refinement) — NEGATIVE result: a DP-beat tempo+phase refit regressed F 0.3718→0.3254 with no reject-guard and was reverted; `BeatGridAnalyzer.swift` is byte-identical to HEAD. **This story's DD #2/#4 are the direct corrective** (continuous onset-comb fit, not DP beats; mandatory reject-guard). Kept from 8-9: `decompose_beatgrid.py` + stratified drift reporting confirming failures are tempo-precision, not phase.
- **Story 8-9 / 53313c0** shipped `BeatGridTempoLock` (`.off`/`.bpmStage`/`.bpm(Double)`) fully wired via `Options.beatGridTempoLock` + `applyTempoLock` — the manual BPM-lock primitive 8-12 builds on; this story feeds the auto path beneath it.
- **Story 8-7** — measurement harness + floors (0.33 F / 2.0 s drift); its pressure-release doc is this story's mandate. Floors are regression nets, not quality claims.
- Test/gating pattern: env-gated benchmark + per-track impact JSON + `make` target (mirror `make beat-grid-impact-report`); byte-identity opt-out via `Double.bitPattern`.

### References

- [Source: `_bmad-output/implementation-artifacts/8-7-pressure-release.md` §2 — dominant failure = tempo precision]
- [Source: `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:115,328-344` — `estimateBeatGrid`, `estimatedTempo = tempoBPM`, 8.4-removal rationale]
- [Source: `Sources/BoomBoomBoomKit/BeatGrid.swift:84,260` — `estimatedTempo` sentinel + `with(estimatedTempo:)`]
- [Source: `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:350,1479,1492,1573,1600,1621` — `beatGridTempoLock`, the two `beatGrid(decoded:)` Options builds, `applyTempoLock` (`func` at `:1621`)]
- [Source: `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:219,549,611` — step-11 fan-out, no BPM-selection feedback; `tempoBPM` is the single-window DSP tempo (NOT the cross-window quorum)]
- [Source: `Tests/BoomBoomBoomKitBenchmarkTests/DAWOracleBenchmarkTests.swift` — DAW-verified oracle TRUTH; reuse its `oracleByFilename` loader (AC #9)]
- [Source: party-mode + Codex thread `019ef269` — fit continuous onset-comb, not integer DP beats; report refined as the grid's one tempo (`bpm.bpm` untouched); drift-rate primary]

## Spec Review (party-mode adversarial pass, 2026-06-25)

Reviewed by the Code-Review-Crew (5 independent lenses, each verifying cited line numbers against `Sources/`). Findings folded in:

- **AC #3 (blocker) — reject-guard objective pinned.** "Residual" (lower-better) inverted DD #2's *support* (higher-better) and was not tied to the fit objective; a dev could score seed/refined at different phases and re-open the 8.9 regression. Now: identical support objective, each period at its own argmax phase, same in-bounds tap set, strict `>`, finite-positive precheck, original-binding seed return.
- **AC #8 ↔ AC #3 collision fixed.** Default `.optimal` seed is already sub-BPM, so "strictly closer than seed" was unsatisfiable; the fixture now forces a coarse seed (`.fineGridRefinement` off).
- **DD #3 / AC #4 reconciled.** A few-percent window can never reach `2·seed`/`seed/2`, so the octave-band check was dead code; the window bound (clamped against octave AND envelope length `n`) is now the octave safety.
- **DD #2 — phase is a free search dimension** (not fixed at a DP anchor, which re-inherits seed bias).
- **Sentinel-laundering + min-span abstain** pinned (Boundary/Vex): refit returns finite-positive or the seed; abstains below the lever-arm baseline.
- **Threading trap** (Grumbal): flag threaded into BOTH `beatGrid(decoded:)` Options builds (`:1479`/`:1492`), else combined paths silently never refine.
- **Reuse over rebuild** (Yui/Dana): flag named `refineBeatGridTempo: Bool`; AC #9 reuses `DAWOracleBenchmarkTests` rather than a new harness; floor is a post-measurement output; AC #1 softened to "no new feature-extraction pass"; AC #7 marked splittable.
- **Wording/cites**: rewrite (not extend) the `:328-344` rationale; `applyTempoLock` `func` at `:1621`; dropped the inaccurate "BPM detection quorum" framing (`tempoBPM` is single-window); consumer note that `bpm.bpm` ≠ `beatGrid.estimatedTempo`.

## Dev Agent Record

### Agent Model Used

claude-opus-4-8 (Claude Code, bmad-dev-story), 2026-06-25.

### Debug Log References

- `make test` → 716 tests pass (the 10 new `BeatGridTempoRefinementTests` included).
- `make fmt` clean; `make lint` → 1 violation, 0 serious (the canonical `LUFSAnalyzer.swift:135` TODO baseline — unchanged).
- `make benchmark` (OA300) → Acc1 58/82 (70.7%), Acc2 74/82 (90.2%) — IDENTICAL to the pre-story baseline; floors 57/82 + 73/82 held.
- `make benchmark-giantsteps` → Acc1 537/661 (81.2%), Acc2 546/661 (82.6%) — IDENTICAL; floors 537/661 + 546/661 held.
- `make tempo-refine-impact-report` → `_bmad-output/implementation-artifacts/8-10-tempo-refine-impact.json`.

### Completion Notes List

**What shipped.** A continuous, sub-frame onset-comb tempo refinement in `BeatGridAnalyzer.refineTempo(...)` (Story 8.10, DD #2/#4), opt-in via `Options.refineBeatGridTempo: Bool = false`, threaded through `BPMAnalyzer.Options` into BOTH `beatGrid(decoded:)` Options builds (`:1479`/`:1492`). The refit folds every onset frame onto a sub-frame phase axis (`combSupport`), scoring mean onset energy at the best beat phase; it scans a bounded adaptive period window (acf-periodicity-weighted half-width 1.5–4 %, clamped against the envelope length and well under an octave), parabolic-refines the peak, and is accepted iff `support_refined > support_seed` (strict). The refined value is reported as `BeatGrid.estimatedTempo` only; `bpm.bpm` is untouched.

**Monotonic reject-guard (the regression-prevention core).** Seed and refined periods are scored by the IDENTICAL support objective, each at its own argmax phase. Three abstain paths all return the seed's ORIGINAL `tempoBPM` binding (bit-pattern-identical to HEAD): (1) min-span (< 8 beats), (2) periodicity/contrast < 1.5 (aperiodic noise / flat-constant — no beat phase to sharpen), (3) finite-positive precheck on the refined BPM before any compare/assign. Unit tests pin each path bit-identically. The contrast abstain is the design addition beyond the spec's DD list: it is what makes the *aperiodic* path (not just flat-constant) return the seed deterministically — framed as an abstain gate (the min-span sibling), NOT an epsilon on the accept comparison (which stays strict `>`).

**Measured drift-rate lift (AC #9, DAW-verified oracle, `.fullTrack`, 300 s cap).** total=23 tracks on disk, scored=14 (9 excluded as >octave grid/oracle mismatches — a pre-existing octave-tracking issue, not this story's concern). **changedTempo=2, improvedTempoError=2, worsenedTempoError=0**; mean predicted last-beat drift 0.676 s → 0.662 s. The two tracks that fired (both 160-BPM tracked at half-time ~80) went coarse 79.97 → refined 79.999/80.000 BPM, collapsing predicted drift from ~0.10 s to ~0.004 s (a ~25× per-track reduction). Honest read: the refit is conservative — it fires only where the audio's own onset comb supports a strictly-better period, which on this small verified subset is 2/14; but where it fires it is a large, zero-regression win, and the reject-guard held the other 12 at the seed.

**Committed regression floor (AC #9).** The robust, corpus-size-independent floor is the reject-guard's own contract, asserted in `tempoRefinementImpact`: `improvedTempoError >= worsenedTempoError` AND `meanDriftOn <= meanDriftOff`. A hard `improved >= 2` count was deliberately NOT committed — the DAW-verified subset is too small (14 scored) for a count floor to be stable across corpus/algorithm drift; the monotonic property is the meaningful net-never-worse guarantee.

**Default stays OFF.** The AC #9 measurement is the input to the default-flip decision (a separate decision, not part of this story's `done`): with a 2/14 fire rate on the verified subset, the default stays `false`. Consumers opt in via `Options.refineBeatGridTempo = true` (and should use `.window`/`.fullTrack` coverage for the long lever arm a sub-0.1-BPM fit needs).

**Secondary F-measure (AC #9).** `make benchmark-beatgrid` (Rekordbox JAMS, develop-only Tony corpus) runs the DEFAULT path (refit OFF) → byte-identical to pre-story → F cannot regress below the 0.33 floor by construction. Not re-run here (requires the operator's Tony-corpus `oracle-generate-beats` setup); inert-by-construction.

**Pending user action (operator-owned closeout).** (1) `/bmad-code-review` on a separate-LLM cadence (project convention). (2) Final commit gated on the 1Password SSH signer. (3) Optional: decide whether to flip `refineBeatGridTempo` default after a larger-corpus measurement (out of scope here).

### File List

- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift` (M) — `refineTempo` + `combSupport` + tuning constants + `TempoRefitResult`; refit wired at the `estimatedTempo` site behind the flag (set before `selectGridOrigin`); rewrote the `:328–344` DocC rationale; two new params on `estimateBeatGrid` (`refineBeatGridTempo`, `refinementSink`).
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` (M) — `refineBeatGridTempo: Bool = false` on `Options`; threaded into both `BeatGridAnalyzer.estimateBeatGrid` call sites (step-11 fan-out with trace sink; full-track seam).
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` (M) — `refineBeatGridTempo: Bool = false` on public `Options` (with `BeatGridTempoLock` precedence doc); threaded into BOTH `BPMAnalyzer.Options` builds in `beatGrid(decoded:)`.
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` (M) — `BeatGridTempoRefinementEvidence` typed evidence struct + `beatGridTempoRefinement` trace field (Step 11 section).
- `Tests/BoomBoomBoomKitTests/BeatGridTempoRefinementTests.swift` (A) — 10 deterministic + combined-path tests (AC #2/#3/#4/#5/#6/#7/#8).
- `Tests/BoomBoomBoomKitBenchmarkTests/DAWOracleBenchmarkTests.swift` (M) — `tempoRefinementImpact` AC #9 harness (reuses `oracleByFilename`) + impact-report schema.
- `Makefile` (M) — `tempo-refine-impact-report` target.

### Change Log

- 2026-06-25 — Story 8.10 implemented; all 10 ACs satisfied; status → review.
- 2026-06-26 — `/bmad-code-review` (separate-LLM: Codex Blind Hunter + Edge Case Hunter + Acceptance Auditor); status → done. 1 decision + 1 patch + 4 defer + 4 dismissed. Decision (`beats` spacing vs refined `estimatedTempo`) resolved Option 1 (document the invariant; Codex thread `019f0216`) — `BeatGrid` doc-comments now name lock/refine as a divergence source and pin `gridOrigin` + `estimatedTempo` as the canonical playable grid. Patch (AC #5 BPM-field byte-identity) test-locked: `refinementDoesNotPerturbBPMFields` proves `bpm`/`confidence`/`candidates` bit-identical across baseline/OFF/ON `estimateBPM` runs + a deterministic refit-executed check. Both patches doc/test-only (refit logic + Options defaults untouched). Gauntlet: `make fmt` clean, `make test` 717 pass (716 + new), `make lint` 1 violation 0 serious (LUFSAnalyzer TODO baseline). 4 defers logged as 8-10-D1..D4. PENDING (operator): 1Password-signed commit/PR onto rterhaar/epic-8.

## Review Findings

Code review 2026-06-25 (separate-LLM cadence): Blind Hunter (Codex MCP), Edge Case Hunter, Acceptance Auditor. Raw: ~13 findings across 3 layers → after dedup/triage: 1 decision-needed, 1 patch, 4 defer, 4 dismissed. Auditor verified all 10 ACs + 7 DDs as SATISFIED, including the two regression-prone cores (DD #4 reject-guard objective/phase/strict-`>`/original-binding-return, DD #5 two-site threading).

- [x] [Review][Patch] (resolved from Decision) Document the `beats`-vs-`estimatedTempo` invariant [Sources/BoomBoomBoomKit/BeatGrid.swift] — When refit accepts (e.g. seed 127.0 → refined 127.3), the returned `beats`/`beatFrames` stay DP-spaced for the seed period while `estimatedTempo` reports the refined value. `gridOrigin` IS re-derived at the refined tempo (`BeatGridAnalyzer.swift:382`), so the Rekordbox extrapolation anchor (`anchor + n·60/estimatedTempo`) is self-consistent — but a consumer iterating raw `beats` sees spacing that disagrees with the stated tempo. **Resolved (operator + Codex thread `019f0216`, 2026-06-26): Option 1 — document, do NOT re-derive.** `beats` are raw detector observations; `gridOrigin + estimatedTempo` is the authoritative playable model. Re-deriving would break consistency with the shipped manual-lock path (`BeatGrid.with(estimatedTempo:)`, Story 8-9), which already keeps raw beats while overriding the tempo by design. Patch: strong doc-comment on `beats` (raw detections, not guaranteed evenly spaced after lock/refine — extrapolate from `gridOrigin + estimatedTempo`) and on `estimatedTempo`/`gridOrigin` (the canonical extrapolation model). A future `modeledBeat(at:)` accessor, if wanted, is a separate surface — not an overload of `beats`. [source: blind + Codex]

- [x] [Review][Patch] AC #5 opt-out test under-covers the byte-identity promise [Tests/BoomBoomBoomKitTests/BeatGridTempoRefinementTests.swift] — `defaultOffIsByteIdenticalAndOnIsNotInert` asserts only the `BeatGrid` graph (analyzer-level) bit-equal with the flag OFF; AC #5 requires `bpm`, `confidence`, AND `candidates` `Double.bitPattern`-equality too. Holds by construction (the flag is read only inside the grid fan-out), but the AC's explicit test-lock for those three fields is not met. Fix: add the three service-level `bitPattern` assertions. [source: auditor]

- [x] [Review][Defer] combSupport bin count varies with period across the accept comparison [Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:726] — `bins = max(8, round(period·2))` differs between the seed and refined periods, so `support_refined > support_seed` compares two differently-binned objectives; max-over-more-bins inflates support for longer (slower) periods on sparsely-populated bins → a slow-tempo tilt. Sized down: at ~127 BPM the `.fullTrack` span gives ~100 frames/bin (variance bias negligible); material only on near-min-span fits (~4 frames/bin), which the min-span (8-beat) + contrast (1.5) guards already make abstain-prone, and monotonicity is preserved. Follow-up: use a period-independent bin count for the seed/refined comparison. — deferred, precision follow-up. [source: edge+blind]

- [x] [Review][Defer] Refinement trace evidence uncaptured on `.window`/`.fullTrack` coverage [Sources/BoomBoomBoomKit/BPMAnalyzer.swift:696] — The full-track seam `estimateBeatGrid(decoded:tempoBPM:coverage:options:)` threads `refineBeatGridTempo` but passes the default no-op `refinementSink` and has no `trace` surface, so `BPMDiagnosticTrace.beatGridTempoRefinement` is never populated on the long-coverage path where refinement most often fires. Diagnostic-only — AC #9's impact JSON reads `grid.estimatedTempo` directly and is unaffected; DD #6 marks the trace splittable. The seam structurally has no trace plumbing. — deferred, diagnostic-only gap. [source: edge]

- [x] [Review][Defer] AC #9 monotonic floor can false-alarm on support/oracle divergence [Tests/BoomBoomBoomKitBenchmarkTests/DAWOracleBenchmarkTests.swift:659] — `#expect(improved >= worsened)` / `meanDriftOn <= meanDriftOff` assume support-better ⇒ oracle-closer; the reject-guard only guarantees support improvement against the audio's own onset evidence, so a groove/swing/mistuned-label track could move tempo away from the DAW oracle and trip the floor as a false regression. Operator-chosen floor (Completion Notes); empirically improved=2/worsened=0 on the 14-track subset. — deferred, acknowledged floor choice. [source: edge]

- [x] [Review][Defer] Refine window asymmetric on minimal spans [Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:656] — When `spanFrames/seedPeriod ≈ refineMinBeats`, `maxPeriodBySpan ≈ seedPeriod` truncates `pHi` to ≈ seedPeriod while `pLo` keeps the full `(1−halfWidth)` reach, so the search can only speed the tempo up, not slow it down — a faster-tempo coverage bias in the marginal regime. Monotonicity is preserved (accept still requires `support_refined > support_seed`), so it under-corrects rather than mis-accepts. — deferred, marginal-regime coverage limitation. [source: edge]

**PR #51 review follow-up (post-push, Codex bot P2 + my consult thread `019f09e0`):** the Codex review bot found a real `.bpmStage` lock-precedence bug that the weak 8-10-D5 test hid — `.bpmStage` routed through the gated `octaveNormalizedLockTempo`, so an accepted refit (up to the 4% window) or a single- vs multi-window split that pushes the grid >2% from the stage tempo was classified `.disagree` → the lock silently no-oped, leaving the refined grid standing instead of restoring the coarse stage BPM (violating DD #5 and the function's own doc). Confirmed real + reachable (refine-on AND refine-off) by code-read + Codex consult. Fixed: new authoritative `AudioAnalysisService.stageLockTempo` (within-octave applies, >octave / non-finite guarded); `.bpm(value)` stays gated; docs updated in `AudioAnalysisService.swift` + `BeatGridTempoLock.swift`. Tests: exhaustive `stageLockTempo` unit + octave boundaries, `applyTempoLockBpmStageOverridesDivergentGrid` integration (124→120 override vs `.bpm(120)` gated no-op), and `lockMatrixPrecedence` strengthened to exact equality. Resolves 8-10-D5; adds 8-10-D6 (`.bpm` within-octave gating, operator decision). The two Copilot comments were on the bundled `bmad 6.9.0` tooling commit (develop-only, out of scope). Default path untouched → corpus floors + byte-identity unaffected.

**Codex diff-review follow-up (staged-diff pass, thread `019f07a0`):** no Critical/High; numerical hazards, reject-guard monotonicity, window bounds, and flag threading all confirmed clean. Two test-robustness findings: (P3, applied) the env-gated `tempoRefinementImpact` gate used a soft `#expect(available.count >= 20)` and defaulted `meanDrift`/`scored` to 0, so an empty/all-octave-mismatch corpus would pass the monotonic assertions vacuously — hardened to `try #require(available.count >= 20)` + `try #require(scored > 0)` (NOT a `changedTempo` floor, which would contradict the deliberate no-count-floor decision). (8-10-D5, deferred) the `.bpmStage` cell of `lockMatrixPrecedence` is weakly distinguishing on a clean click — logged to `deferred-work.md`.

**Dismissed (4):** (1) reject-guard monotonic over a phase-free support scalar rather than the emitted grid (blind B2/B3) — the implementation faithfully matches the ratified DD #4 objective ("each period at its own argmax phase"), `gridOrigin` is re-derived at the refined tempo, and AC #9 empirically shows improved=2/worsened=0; design ratified + validated. (2) impact benchmark passes trivially if inert (blind B4) — non-inertness is covered by `defaultOffIsByteIdenticalAndOnIsNotInert`. (3) `refineMinContrast = 1.5` abstain gate beyond DD #4's enumerated list (auditor A2) — disclosed in Completion Notes, monotonic-safe (an abstain, not an accept-epsilon), benign. (4) spec references nonexistent `octaveEquivalenceFactor` (auditor A3) — spec wording nit; the code correctly reuses `classifyTempoAgreement`, and the refit needs no octave comparison (window-bound safety).
