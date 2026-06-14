<!-- Story 8.5a — downbeat detection (fixed-meter downbeat-phase estimation). Quick follow-up to 8.5.
     Closes the "no story populates DownbeatResult" gap; unblocks the DJ consumer's bar/half-bar snap.
     Designed 2026-06-13 via Codex (thread 019ec2a4) + grounded against the onset/sub-band plumbing.
     Depends on Story 8.5 (BeatGridAnchor + BeatGridAnchorSource.downbeat + gridOrigin). BC is NOT a goal (nothing shipped to main). -->

# Story 8.5a: Downbeat detection — fixed-meter downbeat-phase estimation

Status: ready-for-dev

## Story

As a **library consumer** (concretely: a Rekordbox-style DJ app doing bar/half-bar quantized launch),
I want **`DownbeatResult.detected` populated with a first-downbeat anchor + the assumed meter when the rhythmic evidence is strong enough, and an honest `.noneDetected` abstain otherwise**,
so that **I can extrapolate bar lines (`anchorTime + barIndex × beatsPerBar / (tempo/60)`) and snap launches to the top of the bar — without the library ever fabricating a downbeat it isn't sure of.**

## ⚠️ Context (read FIRST)

This is a **quick follow-up to Story 8.5** that fills the gap flagged in 8.5 DD #13: `DownbeatResult` (the public tri-state from Story 8.3) is `.notAttempted` everywhere and **no story populates it**, which blocks the DJ consumer's bar/half-bar (1/1, 1/2) snap. This story adds a conservative, pure-DSP downbeat-*phase* estimator on top of the beats the 8.5 grid already produces.

- **Hard dependency on Story 8.5.** This story consumes `BeatGrid.gridOrigin: BeatGridAnchor?` and sets `BeatGridAnchorSource.downbeat` (both introduced in 8.5). Sequence: 8.5 → 8.5a. It does NOT touch the BPM pipeline or the C2 octave logic.
- **Scope is deliberately narrow (Codex thread `019ec2a4`).** Assume **4/4** (carry `beatsPerBar` as `.assumed`, do NOT pretend to detect meter); estimate a **single downbeat phase** (which beat-in-bar is beat 1); produce a **first-downbeat anchor** + the downbeat beats; **abstain** (`.noneDetected`) when evidence is weak. A wrong downbeat on a live deck is worse than no downbeat — the success condition is "produce a downbeat when the rhythmic evidence is strong; otherwise abstain", NOT "always produce one".
- **Clean-room / aubio fence (KDD-C1, project rule).** No aubio source transcribed or named in code/public PRs. Cite academic literature for the metrical-accent heuristic (DD #7).
- **Constant-tempo only** (inherited from the fixed-period tracker; 8.4 doc). Variable meter / non-4/4 detection / per-beat `Battito` are explicitly out of scope (DD #8).

## Acceptance Criteria

**AC1 — `MeterEstimate` + enriched `DownbeatResult.detected` payload (public types).**
Add `public struct MeterEstimate: Sendable, Hashable, Codable { public let beatsPerBar: Int; public let source: MeterSource }` and `public enum MeterSource: Sendable, Hashable, Codable { case assumed; case detected }`. **Enrich** `DownbeatResult.detected(beats: [BeatTimestamp])` → `case detected(estimate: DownbeatEstimate)` where:
```swift
public struct DownbeatEstimate: Sendable, Hashable, Codable {
  public let beats: [BeatTimestamp]   // the downbeat beats (bar starts), in order
  public let meter: MeterEstimate     // { beatsPerBar: 4, source: .assumed } in 8.5a
  public let confidence: Float        // [0,1], clamped finite (NaN-free → Hashable)
  public let phaseIndex: Int          // which beat-in-bar (0..<beatsPerBar) is the downbeat
}
```
The associated value stays **labeled** (`estimate:`) to keep the `Codable` wire-shape stable (`{"detected":{"estimate":{…}}}` not `_0`) — same rationale as the existing `beats:` label (Story 8.3 DD #9 / SE-0295). `DownbeatResult` remains NOT `CaseIterable` (associated value), `Hashable` sound (all floats clamped finite). `BeatGridTypesTests` updates to the new payload (BC not a goal). `DownbeatResult.description` switch stays exhaustive (no `default:`).

**AC2 — opt-in downbeat detection; default path unchanged.**
Add `Options.detectDownbeats: Bool = false`. When `false` (default), `BeatGrid.downbeats == .notAttempted` exactly as today — the BPM/beat-grid output is byte-identical to 8.5 (`.bitPattern`-locked). When `true`, the grid path runs the downbeat estimator and sets `downbeats` to `.detected(estimate:)` or `.noneDetected`. The combined `analyze(...)` and both `analyzeBeatGrid` overloads honor it.

**AC3 — downbeat-phase estimator (fixed 4/4, percussive-accent heuristic).**
A new internal estimator (`DownbeatAnalyzer` or a method on `BeatGridAnalyzer`) runs over the detected beats + the per-frame sub-band onset envelopes (`OnsetEnvelopes.subBands = [kick, snareLow, snareCrack, hiHat]`, `BPMAnalyzer.swift:557-559`) when `detectDownbeats == true`:
1. For each detected beat (window-relative frame `f`), sample a window of `±20%` of the beat period around `f` and take the per-band peak from kick (low), snareCrack, and full-band envelopes; normalize each band across the analysis window.
2. Per-beat downbeat-likelihood `score = 1.0·lowBand + 0.25·fullBand − 0.25·snareCrack`, clamped `≥ 0` (low-frequency/kick emphasis marks bar starts; subtract snare-crack to suppress backbeat phases — DD #7).
3. Assign each beat a **bar-phase index by quantized POSITION, NOT array index**: `phase = Int(((beatTime − firstBeatTime) / beatPeriod).rounded()) % beatsPerBar`, where `beatPeriod = 60.0 / estimatedTempo`. Folding by raw array index (`i % beatsPerBar`) is unsound — the Davies & Plumbley DP backtrace admits inter-beat intervals in `[period/2, 2·period]`, so it can drop or double a beat mid-window (the exact hazard 8.5 DD #4 names), and one dropped/doubled beat shifts every later array-index phase by ±1, scrambling all bins. Position-quantization is robust to a single missing/extra beat. **Grid-integrity abstain:** if the beat array is non-uniform — consecutive inter-beat intervals deviate from `beatPeriod` by more than ~25% for more than a small fraction of beats (the DP lost the grid) — return `.noneDetected` rather than estimate a phase from an unreliable grid.
4. Aggregate each of the `beatsPerBar` phase bins with a **median (or trimmed mean), NOT a raw sum** (a single transient must not dominate — Codex). Winner = max-aggregate phase bin; the first downbeat = the **earliest detected beat whose bar-phase == the winner phase**; the downbeat beats = all detected beats whose bar-phase == the winner phase, within coverage.

**AC4 — honest confidence + abstain path.**
`confidence = 0.7·margin + 0.3·separation`, where `margin = clamp01((winner − runnerUp) / max(winner, ε))` and `separation = clamp01((winner − meanPhaseScore) / max(winner, ε))`, with `ε = 1e-6` (Float). (The confidence term is named `separation` — distinct from gate (d)'s multi-bar *support* below; they are different quantities.) The estimator retains **both** the per-phase aggregate (for `winner`/`runnerUp`/`meanPhaseScore`/`margin`/`separation`) **and** the winner phase's per-bar score vector (for gate (d)). Return `.detected(estimate:)` **only if all** hold: (a) `≥ 3` complete bars of beats exist (`beats.count ≥ 3·beatsPerBar`); (b) `winner > 0` **and** `winner ≥ 1.25 · runnerUp` (the `winner > 0` guard keeps the margin gate self-sound — an all-zero histogram must not pass on `0 ≥ 1.25·0`); (c) `confidence ≥ 0.4`; and (d) **multi-bar support** — the winner phase's per-bar score exceeds the per-beat mean in `≥ ceil(bars/2)` bars (a real recurring accent, not a single-bar spike). Otherwise return `.noneDetected`. (Conservative by design — a missed downbeat just disables bar-snap; a wrong one causes audibly wrong launches.)

**AC5 — `gridOrigin.source == .downbeat` on success; preserved on abstain.**
When the estimator returns `.detected`, the grid's `gridOrigin` (from 8.5) is set to the **first downbeat** with `source == .downbeat` (the reserved 8.5 case). When it returns `.noneDetected` (or `detectDownbeats == false`), `gridOrigin` keeps the 8.5 phase-consistency anchor (`source == .medianConsistentBeat` / `.strongestBeat` / `.firstBeat`) unchanged. This is what lets the DJ consumer phase the bar grid off `gridOrigin` only when `source == .downbeat`.

**AC6 — sub-band onset envelopes forced when downbeats requested (no BPM perturbation).**
Sub-band onset envelopes are currently computed only when `techniqueSet.contains(.subBandVoting)` (`BPMAnalyzer.swift:264,270`). When `detectDownbeats == true`, the grid path **forces `computeSubBands: true`** so the estimator has its input, independent of the active technique set. This is additive — the sub-band envelopes feed only the downbeat estimator (and sub-band voting iff that technique is independently on); the **BPM selection result is unchanged** (`.bitPattern`-locked, AC2).

**AC7 — performance.**
With `detectDownbeats == false`: zero added cost (byte-identical, AC2). With `detectDownbeats == true`: the added cost is one sub-band onset pass (if not already computed for `.subBandVoting`) + an O(beats) folding pass — reported, not gated to a fixed ceiling (mirrors 8.5 AC10). The estimator allocates no per-beat heap in a loop where a vDSP primitive serves (CLAUDE.md).

**AC8 — tests.**
`DownbeatAnalyzerTests` (deterministic, runtime-generated fixtures): (a) a synthetic 4/4 click with a **kick emphasized on beat 1** every bar → `.detected` with `phaseIndex` matching the planted downbeat and `gridOrigin.source == .downbeat`; (b) a **flat four-on-the-floor** click (equal kick every beat) → `.noneDetected` (abstain — no phase separation); (c) **fewer than 3 bars** → `.noneDetected`; (d) `detectDownbeats == false` → `.notAttempted` + BPM byte-identical (`.bitPattern`); (e) `DownbeatResult`/`DownbeatEstimate`/`MeterEstimate` `Codable` round-trip + the labeled `estimate:` wire-shape + NaN-free `Hashable`; (f) **backbeat-heavy** click (snareCrack on phases 1&3, equal kick everywhere) → the `−0.25·snareCrack` penalty must NOT promote a snare phase as downbeat (abstain or pick the true kick phase, never a backbeat phase) — exercises the backbeat mitigation; (g) **bass-drop** fixture (one bar with a huge low-band transient on a non-downbeat phase) → the median aggregation rejects it where a raw sum would be fooled — exercises the AC3.4 median mitigation; (h) **anacrusis** (a strong accent on the pre-bar-1 pickup beat) → the multi-bar support gate (AC4d) holds against the single-beat pickup; (i) **one planted missing beat** mid-window → the position-quantized folding (AC3.3) still resolves the correct phase OR honestly abstains via the grid-integrity guard, NOT a scrambled phase. Assertions use **independent ground truth** (the planted downbeat phase), never the estimator's own output.

**FRs covered:** FR-28 (downbeat tri-state — first story to *populate* it).
**KDDs implemented:** C2 (beat/downbeat provenance — `BeatTimestamp` strength; extends to the downbeat anchor).

## Tasks / Subtasks

- [ ] **Task 1 — public types (AC1).** `MeterEstimate` + `MeterSource` (new file); `DownbeatEstimate` (new file or co-located); enrich `DownbeatResult.detected(beats:)` → `.detected(estimate: DownbeatEstimate)`; update `description`, `Codable`, and `BeatGridTypesTests`. Clamp `DownbeatEstimate.confidence` finite.
- [ ] **Task 2 — `Options.detectDownbeats` + sub-band forcing (AC2, AC6).** Add the flag (default `false`); thread into the grid path; force `computeSubBands: true` when set; assert BPM byte-identity when set (sub-bands computed-but-unused-by-BPM unless `.subBandVoting` is independently on).
- [ ] **Task 3 — downbeat-phase estimator (AC3, AC4, AC5).** New internal estimator over beats + `subBands`; per-beat low/full/snareCrack sampling (±20% period window, per-band normalize); folded median aggregation; margin+support confidence; the 4-part abstain gate; on success set `DownbeatResult.detected(estimate:)` + repoint `gridOrigin` to the first downbeat with `source == .downbeat`; on abstain preserve the 8.5 anchor.
- [ ] **Task 4 — wire into the service paths (AC2).** `analyzeBeatGrid(url:/decoded:)` and combined `analyze(...)` honor `detectDownbeats`; `Options.isCancelled` checkpoint before the estimator (it is cheap, but stay consistent with 8.5 DD #4).
- [ ] **Task 5 — DocC + README.** Document the heuristic + the abstain semantics + the 4/4-assumed `MeterEstimate`; README "## Beat grid" gains a downbeat paragraph (bar extrapolation formula + "abstains when unsure"). Update `docs/beatgrid-design-notes.md` §5 to mark the downbeat story as scheduled/landed.
- [ ] **Task 6 — tests (AC8).** `DownbeatAnalyzerTests` per AC8.
- [ ] **Task 7 — gates + PR.** `make fmt`/`make lint` (LUFSAnalyzer:135 baseline)/`make test` green; 5-recipe `bpm-diagnostic-trace` audit zero matches (no trace field — DD #6 carries over). 1Password-signed commit `rterhaar/8-5a` off `rterhaar/8-5` (stacked) or `rterhaar/epic-8`; PR into `rterhaar/epic-8`.

## Dev Notes

### Design Decisions (DDs)

**DD #1 — fixed-meter downbeat-PHASE estimation, not general downbeat tracking (Codex).** The honest framing: estimate which beat-in-bar is beat 1 for **percussive, constant-tempo, 4/4** material. Do not claim general downbeat detection. The MVP is a metrical-accent heuristic with an abstain path, not an ML/DBN/particle-filter system (those are explicitly what we are NOT doing — DD #7).

**DD #2 — `beatsPerBar` is `.assumed`, never pretend-detected (Codex).** Carry `MeterEstimate { beatsPerBar: 4, source: .assumed }`. Do NOT hardcode `4` internally without surfacing that it is assumed — a consumer must know the meter wasn't measured. Non-4/4 detection is a later story; `MeterSource.detected` is reserved for it.

**DD #3 — enrich `DownbeatResult.detected` now (Codex; BC not a goal).** The current `.detected(beats:)` is too thin for a consumer deciding whether to trust bar-snap — it carries no meter, confidence, or phase. Change to `.detected(estimate: DownbeatEstimate)` while pre-1.0. Keep the associated value **labeled** for a stable `Codable` wire-shape (Story 8.3 DD #9). A future per-beat `Battito` payload is additive (`DownbeatEstimate` gains an optional `beatPositions: [BeatPosition]?` later — no breaking change). This is consistent with how 8.5 reshapes `BeatGrid` (nothing shipped to `main`).

**DD #4 — opt-in, default-off, BPM byte-identical (AC2/AC6).** `Options.detectDownbeats = false` keeps `downbeats == .notAttempted` and the BPM result `.bitPattern`-identical. Forcing `computeSubBands: true` when downbeats are requested is additive: sub-band envelopes feed the downbeat estimator only; they alter BPM selection **only** via `.subBandVoting`, which is independent and unchanged. Lock BPM byte-identity in a test (AC8d).

**DD #5 — runs in the window-relative frame space the beats were tracked in.** The detected beats' window-relative frames `f` (the same `f` 8.4 used to compute `presentationTime = (windowStartSample + f·hopSize)/sampleRate` and `strength = onsetEnvelope[f]/envMax`) index directly into `subBands[band][f]`. Run the estimator alongside `estimateBeatGrid` (or pass the beats' frame indices) so no track↔window offset reconciliation is needed. The default `.analysisWindow` coverage (≈30 s) already yields many bars (30 s @ 120 BPM = 60 beats = 15 bars ≥ the 3-bar floor), so downbeat detection works on the cheap default coverage.

**DD #6 — NO trace field; KDD-T0 does not trigger (carries over from 8.3/8.4/8.5).** Downbeat output rides `BeatGrid.downbeats`, a parallel result, not a `UnifiedSignalPool` participant. No `BeatGridTraceEntry`/trace field; 5-recipe audit zero matches; W74 stays armed.

**DD #7 — academic grounding (aubio fence held).** The metrical-accent heuristic (low-frequency/bass + percussive accent marks bar starts) is grounded in academic literature, cited in DocC, NOT aubio: Goto's bass/drum-pattern beat-tracking; Klapuri, Eronen & Astola, "Analysis of the meter of acoustic musical signals" (hierarchical meter from accent features); Durand, Bello, David & Richard (downbeat tracking from rhythm + bass content — cited as the ML direction we deliberately do NOT take); Böck, Krebs & Widmer ("Joint Beat and Downbeat Tracking with Recurrent Neural Networks", ISMIR 2016 — RNN downbeat likelihood + dynamic Bayesian network temporal model; likewise the learned direction we are NOT taking); Davies, Plumbley & Ellis ground the beat-phase/tempo side, not the downbeat classifier. Frame it as "fixed-meter downbeat-phase estimation for percussive constant-tempo music." Imports stay `Foundation` + `Accelerate`; `Package.swift` unchanged.

**DD #8 — explicit deferrals.** Out of scope (later stories, if ever): non-4/4 meter detection; per-beat `Battito` (1–4) labels; harmonic-change / section / phrase-level downbeats; full-track downbeat correction; ML/DBN downbeat models; variable-tempo bar tracking.

### Failure modes + mitigations (from Codex; bake into the estimator + tests)

| Failure mode | Mitigation (in AC3/AC4) |
|---|---|
| Four-on-the-floor (kick every beat → flat low-band phase) | margin gate + abstain (AC8b is exactly this case → `.noneDetected`) |
| Backbeat-heavy (snare/clap on 2 & 4 dominates) | `− 0.25·snareCrack` term penalizes snare-heavy phases |
| Breakbeat/DnB (kick avoids beat 1 / implies half-time) | abstain on low margin; constant-tempo + half-time is the BPM stage's octave concern |
| Pickups / anacrusis (first phrase accent ≠ bar 1) | multi-bar support requirement (AC4d) |
| Bass drop / fill (one bar-local event) | median/trimmed aggregation (AC3.3), not raw sum |

### Architecture / source-tree touch points

| File | Change | Notes |
|---|---|---|
| `Sources/BoomBoomBoomKit/DownbeatResult.swift` | UPDATE | `.detected(beats:)` → `.detected(estimate: DownbeatEstimate)`; `description`/`Codable`; keep NOT-`CaseIterable` |
| `Sources/BoomBoomBoomKit/DownbeatEstimate.swift` | NEW | `DownbeatEstimate` + `MeterEstimate` + `MeterSource` (or co-locate) |
| `Sources/BoomBoomBoomKit/DownbeatAnalyzer.swift` | NEW (internal) | the phase estimator (or a method on `BeatGridAnalyzer`) |
| `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift` | UPDATE | run the estimator over beats + `subBands`; repoint `gridOrigin` to the downbeat (source `.downbeat`) on success |
| `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` | UPDATE | force `computeSubBands: true` when `detectDownbeats`; thread sub-bands to the grid/downbeat path; BPM result unchanged |
| `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` | UPDATE | `Options.detectDownbeats`; honor it in `analyzeBeatGrid` + `analyze` |
| `README.md` + `docs/beatgrid-design-notes.md` | UPDATE | downbeat paragraph + bar-extrapolation formula; mark §5 scheduled/landed |
| `Tests/BoomBoomBoomKitTests/BeatGridTypesTests.swift` | UPDATE | new `DownbeatResult` payload + `DownbeatEstimate`/`MeterEstimate` Codable/Hashable |
| `Tests/BoomBoomBoomKitTests/DownbeatAnalyzerTests.swift` | NEW | AC8 |
| `_bmad-output/implementation-artifacts/sprint-status.yaml` + `epics.md` + `deferred-work.md` | UPDATE | register 8-5a; close the "no story populates DownbeatResult" flag |

### Pressure-release valve

If the estimator + the type enrichment can't both land in one context window: ship AC1 (the enriched `DownbeatResult` + `MeterEstimate`/`DownbeatEstimate` types) and the opt-in flag wired to **always `.noneDetected`** as a placeholder (types land, populated detection deferred), OR ship the estimator against the existing `.detected(beats:)` and defer the payload enrichment. Document in `8-5a-pressure-release.md`. Prefer landing the conservative estimator — the types without a populator repeat the 8.3 gap.

### Testing standards

Swift Testing; `@testable import` for the internal estimator; deterministic runtime-generated fixtures (planted-downbeat 4/4 click, flat four-on-the-floor, <3-bar). Assert against **independent ground truth** (planted phase), never the estimator's own output. Byte-identity via `.bitPattern` (AC8d). No committed audio binaries.

### References

- [Source: Sources/BoomBoomBoomKit/DownbeatResult.swift] (the tri-state being enriched; NOT-`CaseIterable` doctrine + DD #9 labeled-payload rationale)
- [Source: Sources/BoomBoomBoomKit/BPMAnalyzer.swift:557-559] (`OnsetEnvelopes.subBands = [kick, snareLow, snareCrack, hiHat]`) and [:264,270] (sub-bands gated behind `.subBandVoting` — AC6 forces them) and [:140] (`kickBandRange = 0..<20` ≈ 30–200 Hz)
- [Source: Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:197-217] (beats + window-relative frame `f` mapping — `gridOrigin` is introduced by Story 8.5, not present in this file today)
- [Source: 8-5 spec] `_bmad-output/implementation-artifacts/8-5-long-file-sync-stability-and-bpm-beat-grid-consistency.md` (DD #11 `BeatGridAnchor`/`BeatGridAnchorSource.downbeat`; DD #13 the downbeat design constraints this story implements)
- [Source: docs/beatgrid-design-notes.md §5] (consumer ask: single first-downbeat anchor + `beatsPerBar`, additive Battito, `gridOrigin.source == .downbeat`)
- [Source: epics.md:89,236] (FR-28 downbeat tri-state) and [architecture.md:498-509] (KDD-C2 tri-state + provenance)
- Codex thread `019ec2a4` (2026-06-13) — the estimator design, abstain thresholds, `MeterEstimate`/`DownbeatEstimate` shape, academic references, failure modes.

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List

## Change Log

| Date | Change |
|---|---|
| 2026-06-13 | Story created → ready-for-dev. Quick follow-up to 8.5 (depends on it). Populates `DownbeatResult` (FR-28) via a conservative pure-DSP downbeat-phase estimator: fixed 4/4 (`MeterEstimate.assumed`), low-band/percussive accent folded mod `beatsPerBar`, median aggregation, margin+separation confidence with a 4-part abstain gate, `gridOrigin.source == .downbeat` on success. Enriches `DownbeatResult.detected(beats:)` → `.detected(estimate: DownbeatEstimate)`. Opt-in (`Options.detectDownbeats = false`), BPM byte-identical. Designed via Codex `019ec2a4`; grounded against the sub-band onset plumbing (`BPMAnalyzer.swift:557-559`); aubio fence held (academic refs only). Deferred: non-4/4, Battito, harmonic/section downbeats, ML. |
| 2026-06-13 | Adversarial verification pass (3 auditors: code-feasibility, algorithm-soundness, aubio-fence+consistency) — 0 blockers, 5 should-fix + 6 nits, all applied. Substantive fix: **fold beat phase by quantized POSITION, not array index** (AC3.3) — array-index folding reintroduced the drop/double-beat hazard 8.5 DD#4 deliberately avoids; added a grid-integrity abstain + a missing-beat test (AC8i). Reconciled gate (d) to keep the winner's per-bar vector + pinned it to `≥ ceil(bars/2)` (AC4). Renamed the confidence term `support`→`separation` (gate (d) keeps "support"); pinned `ε = 1e-6`; added `winner > 0` to gate (b). Corrected the citation `Böck/Krebs/Schedl`→`Böck/Krebs/Widmer` (ISMIR 2016, DD#7). Added AC8 tests for backbeat/bass-drop/anacrusis (the previously test-less Codex failure modes). Tightened the BeatGridAnalyzer line cite. Fixed two stale "unscheduled" refs + a `8.5a`/split-label collision in the 8-5 spec. |
