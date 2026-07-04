---
name: beat-grid
description: Use when authoring, reviewing, or consuming BoomBoomBoomKit's beat-grid / downbeat surface (Epic 8) — the BeatGrid*/Downbeat* public types, the analyzeBeatGrid / analyze entry points, the step-11 fan-out, tempo lock/refine, manual anchors, and the beat-grid accuracy floor. Extracted from project-context.md per its >120-rule growth tripwire.
---

# Beat-grid & downbeat conventions

Critical rules for the Epic 8 beat-grid subsystem. `project-context.md` carries a
single pointer to this file; the conventions live here. Rules, not history —
imperative voice; trailing `(reference: Story X-Y)` where origin matters.

## Public surface (add to the access-control roster mentally when reasoning)

**Public value types** (`Sources/BoomBoomBoomKit/`): `BeatGrid`, `BeatGridAnchor`,
`BeatGridAnchorSource`, `BeatGridAnchorRepositionMode`, `BeatGridTempoLock`,
`BeatGridCoverage`, `BeatTimestamp`, `DownbeatResult`, `DownbeatEstimate`,
`MeterEstimate`, `MeterSource`, `DownbeatStrategy`, `TempoAgreement`,
`CombinedAnalysisResult`, plus the two typed-evidence structs below and the public
`LUFSReport`. **Internal analyzers** (do NOT promote without a named story):
`BeatGridAnalyzer`, `DownbeatAnalyzer`, `StructuralDropAnalyzer`,
`BeatGridGridIntegrity`, `BarPhase`. CLAUDE.md "Key Types" is the current
source-of-truth roster; keep it and this file in sync.

## Entry points

- `AudioAnalysisService` exposes three siblings beside `analyzeBPM`:
  `analyzeBeatGrid(url:options:) -> BeatGrid?` (standalone grid;
  `tempoAgreement == .notCompared`), `analyzeLUFS(...) -> LUFSReport?`, and the
  combined `analyze(url:options:) -> CombinedAnalysisResult?`. There is NO
  `BeatGridService` / `LUFSService` sibling struct — the entry points live on
  `AudioAnalysisService`.
- **`analyze` shares ONE decode** across BPM + beat-grid (+ LUFS); its
  `BeatGrid.tempoAgreement` is resolved against the multi-window BPM tempo.
  `analyzeBeatGrid` alone cannot compare (there is no BPM run), so its
  `tempoAgreement` is `.notCompared`. Do not re-decode per subsystem.

## Options fields (all default to a byte-identical no-op)

The five beat-grid fields on `AudioAnalysisService.Options` are non-optional with a
default: `beatGridCoverage` (`.analysisWindow`), `detectDownbeats` (`false`),
`downbeatStrategy` (`.metricalAccent`), `beatGridTempoLock` (`.off`),
`refineBeatGridTempo` (`false`). At their defaults the beat-grid path is inert and
DSP/BPM output is byte-identical. `refineBeatGridTempo` STAYS off by default — the
flip is documented future work with a concrete gate (Epic 8 retro AI-1); do not flip it.

## Pipeline placement

- Beat-grid extraction is **step 11**, an OPTIONAL PARALLEL fan-out in `BPMAnalyzer`
  (gated by `BPMAnalyzer.Options.computeBeatGrid`, default `false` → branch not
  entered → byte-identical default output). Confidence is **step 12**. Step 11 runs
  AFTER the post-disambiguation steps (10/10b/10c) and **does NOT reorder or feed the
  tempo spine** (steps 1-9 + 10/10b/10c still never reorder). It is a parallel
  OUTPUT, not a stage in the tempo pipeline.
- Pipeline step numbers are stable identifiers (same rule as the DSP spine): once
  `11`/`12` ship in a trace key or artifact filename they do not move.

## Consumer contracts (the correctness traps)

- **Beat grid is a PARALLEL fan-out, NOT a pool signal.** It does not feed BPM winner
  selection and does not participate in the unified signal pool. `SignalSource.beatGrid`
  / `SignalWeights.beatGrid` are **producer-less** — no `WeightedSignal` is emitted with
  `source: .beatGrid`; `UnifiedSignalPool` / `BPMSelectionPolicy` never consume it.
  Beat-grid coherence as an octave lever is armed-but-unbuilt future work
  (deferred-work W53/W74). Do NOT route the grid into pool selection without an
  explicit story.
- **Extrapolate from the anchor; do not trust raw beats.** The canonical playable grid
  is always `gridOrigin.presentationTime + (60/estimatedTempo)*n`, NEVER the spacing of
  `BeatGrid.beats` (the DP tracker can drop/double a beat). This is load-bearing after a
  tempo lock (`BeatGridTempoLock` / `Options.beatGridTempoLock`) or auto-refine
  (`Options.refineBeatGridTempo`): both override `estimatedTempo` and re-anchor
  `gridOrigin` while leaving `beats` at their originally-tracked spacing, so `beats` and
  `estimatedTempo` intentionally describe different tempos.
- **Timestamps are decoded-PCM-relative and already playback-aligned** (AVFoundation
  removes codec priming on decode). Apply device-latency or manual nudges via
  `BeatGrid.offset(by:)`, never by subtracting priming yourself.
- **Beat-grid config is NOT a DSPTechnique / BPMSelectionPolicy / EnsemblePolicy case.**
  `DownbeatStrategy`, `BeatGridTempoLock`, and `BeatGridAnchorRepositionMode` are
  Options/call-time configuration for phase, tempo-lock, and manual anchor placement
  only — never tempo, tempo octave, or BPM winner selection. `DSPTechnique.allCases.count`
  stays 8; do not expand the 256-combo ablation matrix. Promoting one into those families
  requires an explicit story (mirrors the "Metadata is NOT a DSPTechnique" rule).

## Value-type invariants

- **NaN-free by construction.** `BeatGrid`, `BeatGridAnchor`, and `BeatTimestamp` clamp
  every float field finite at every init path (memberwise AND Codable decode, which routes
  through the clamping memberwise init) — that is what makes their compiler-synthesized
  `Hashable`/`Equatable` sound (these types are Codable-cached). Octave/lock factors are
  carried as `Int` (`TempoAgreement.octaveEquivalent(factor:)`, `BeatGrid.tempoLockOctaveFactor`,
  values in {-2,1,2}) precisely because an `Int` cannot be NaN. A type with a `Double`
  payload that can be NaN stays `Equatable`-only (`BeatGridTempoLock.bpm(Double)`, mirroring
  `MLExecutionPolicy` / `EnsembleDecision`). Preserve this doctrine when adding fields.
- **Typed evidence** (same rule as the DSP trace — never `[String: Any]`): Epic 8 added
  `BeatGridTempoRefinementEvidence` (on `BPMDiagnosticTrace.beatGridTempoRefinement`) and
  `DownbeatStrategyEvidence` (on `.downbeatStrategy`), both `Sendable, CustomStringConvertible`.
  Any new beat-grid trace field runs the `bpm-diagnostic-trace` skill's five audit recipes
  (zero matches against `Sources/`/`Tests/`).

## Accuracy posture (accept-as-shipped)

Beat-grid accuracy was **measured and missed** the epic targets (0.75/0.65/30 ms): F-measure
~0.37, downbeat ~0.14 at ~4% fire, FR-29 drift P95 ~1.65 s versus the Rekordbox JAMS oracle.
Epic 8 CLOSED accept-as-shipped (2026-07-01) and pivoted to manual hand-correction levers
(BPM lock 8.9, downbeat-strategy select 8.11, manual anchor reposition 8.12) rather than
auto-precision. The committed floors (0.33 F / 0.10 downbeat / 2.0 s drift) are **regression
nets at measured−margin, not goals**. Compare an EXTRAPOLATED grid against the oracle, not raw
beats. Full record: `_bmad-output/implementation-artifacts/8-7-pressure-release.md` +
`epic-8-retro-2026-07-01.md`.

## Benchmarks

- **`make benchmark-beatgrid`** (Story 8.7 DD-12) is a three-step orchestration: (1)
  `BeatGridBenchmarkTests` emits estimated beats to `8-7-estimated-beats.jams.json` and asserts
  coverage/drift/downbeat; (2) the develop-only Python sidecar `_bmad-output/ml-training/eval-beatgrid.py`
  computes `mir_eval.beat.f_measure` (±70 ms, octave-tolerant over {1/2,1,2}×) into
  `8-7-beat-grid-accuracy.json`; (3) `BeatGridFloorTests` (`BEAT_GRID_ACCURACY_JSON` env) asserts
  `mean_f_measure_octave_constant >= 0.33`. `BEAT_GRID_LIMIT=N` reports a subset but does not gate.
  Run `make oracle-generate-beats` first (builds the Rekordbox JAMS beat oracle). Develop-only —
  fails loudly on a main-only checkout.
- Wall-clock impact gates run under `swift test -c release` (timing-honest): `beat-grid-impact-report`,
  `tempo-refine-impact-report`, `combined-analyze-impact-report`, `shared-decode-impact-report`.
  Accuracy gates (`consistency-rate-oa300` ≥90% sync-usable, `accuracy-forensics` reporting-only) are
  config-agnostic.
