# Beat Grid — Consumer Design Notes (2manyDJs / "Hilbert")

_Date: 2026-06-13. Source: the Hilbert DJ-app agent's answers to the five Story 8.5 API-shape questions. Companion to [`api-feedback.md`](api-feedback.md) (the MediaDiff/MetaMan feedback). These are **binding design constraints** for the upcoming beat-grid features — Story 8.5 (anchor + tempo, `TempoAgreement`, coverage, combined `analyze`) and the deferred downbeat story. Keep them in mind while building; deviations should be deliberate, not accidental._

Two consumers shape the beat-grid API. **MediaDiff/MetaMan** (a metadata viewer) is instrumentation-only — it calls `analyzeBPM` and never touches the grid. **Hilbert** (a Rekordbox-style social DJ app) is the *real* grid consumer: it drives auto-sync and quantized launch off the grid, so the design below is what a live DJ feature actually needs. (`tempoAgreement` is therefore a **feature**, not a test-only signal — see §1.)

---

## 0. Hilbert's consumer model (this shapes everything below)

> **Re-tensing note (2026-06-13, second Hilbert-agent pass).** The API/grid-shape half of this doc is sound and spec-faithful. This consumer-model section originally **over-stated Hilbert's readiness** — it presented several capabilities as already-solved that are in fact **unbuilt Hilbert-side prerequisites**. They are corrected to future tense below and the prerequisites enumerated. None of this changes the library API; it changes what the *consumer* must build before the grid features work end-to-end. The Hilbert-internal facts below (file/line citations) are the consumer agent's, taken as authoritative for its own codebase.

- **Analysis is *intended* to run at index time and be cached per-track** — computed once during indexing, never recomputed at load/play. **Prerequisite (not yet built):** `IndexedFile` today caches only scalar `bpmDetections` (`Float` + `Date`) + `userBPM`, and `BPMDetectorProtocol.detectBPM` truncates everything but `result.bpm` to a `Float`. A grid-bearing cache needs (a) a `Codable` grid-projection field on `IndexedFile`, (b) an additive SwiftData migration (an optional field migrates cleanly under the V3 auto-migration-only constraint — but call it out), and (c) a detector-protocol change to surface the grid (adopt `analyze(...)`). The whole anchor+tempo contract has **no consumer-side home yet**.
- **Cache a minimal owned *projection*, NOT the whole `BeatGrid`.** `BeatGrid` is `Codable`, but it carries `beats: [BeatTimestamp]` — the exact bloat §2 rejects. Hilbert should cache a small owned struct (anchor time, `estimatedTempo`, `tempoAgreement` + factor, the two confidences; later the downbeat anchor + `beatsPerBar`) and own a `cacheFormatVersion: Int` today (this also neutralizes most of the §8 Codable-churn risk with zero library change).
- **Hilbert works entirely in seconds** (`TimeInterval`); launch is an immediate `player.play()`. This part is accurate and is the right currency (§6).
- 🔴 **BLOCKER — the `deck.rate` actuator has no arbiter (Hilbert-side, currently unscheduled).** The original "rate-matching already exists (VariSpeed + a drift PI controller)" treated three control loops with incompatible assumptions as one solved mechanism. Per the Hilbert agent: there is exactly one `VariSpeed` per deck and one blind last-writer-wins write path (`RateNode.setRate`); auto-sync wants an absolute ratio (`masterBPM/trackBPM`, e.g. 0.74), the shipped drift PI is built around a resting rate of 1.0 (clamped `[0.985,1.015]`), and every routine transport event (play/stop/seek/track-change/staleness) hard-writes `setRate(1.0)`. The dominant failure isn't concurrent fighting — it's that the **next routine transport event yanks a beatmatched deck back to unity** (audible tempo+pitch jump). Until Hilbert lands a rate arbiter that composes `effectiveRate = autoSyncBaseRate × driftCorrectionFactor` (drift controller emits a multiplicative ~1.0 correction and resets to the auto-sync base, **not** 1.0), grid auto-sync is **non-functional alongside the shipped SharePlay `resetRate` sync**. This is a Hilbert prerequisite, not a library gap — recorded so the binding-constraints picture stays honest. **This is the one item to escalate.**
- **Quantized-launch trigger is a separate Hilbert-side prerequisite.** Bar-line launch needs a firing primitive the playback path lacks: its only timing signal is a ~100 ms poll and `play()/play(from:)` are immediate, so firing on a poll wake-up is late by up to ~43% of a 1/8 note at 128 BPM — far past the ≤30 ms target. Hilbert needs either a fine-grained countdown that tightens its sleep as the bar line nears (driven by `precisePosition`) or true `AVAudioTime` `play(at:)` scheduling. The downbeat anchor (§5) unblocks the bar-grid *math* only; the on-beat *launch* needs this trigger.
- **Large-delta auto-sync needs keylock (Hilbert-side).** `VariSpeed` pitch-shifts; fine for the ±1.5% drift nudge and small-delta (≲3%) matching, but a large-delta match (128↔174 ≈ −5.3 semitones) audibly detunes. A pitch-preserving node (`TimePitch`/keylock) is a Hilbert audio-graph prerequisite the grid doesn't address.
- **Implications the library honors:** Double-seconds currency (§6); cache-bloat is unwelcome (§2); the `Codable` shape is a contract once cached (§8).

---

## 1. `TempoAgreement` — total enum, carries the octave factor

- **Total enum, `.notCompared` replaces `nil`.** Hilbert prefers a total enum over `Bool?` (removes the nil-as-"not compared" overload).
- **`.octaveEquivalent(factor: Int)` with `factor ∈ {-2, +2}` — carry the factor.** This is *our authoritative classification*, not something the consumer re-derives. Reason: if Hilbert re-derived the octave relationship itself, it and the library could disagree at the boundary and reconcile grid phase against a *different* octave than the one the library decided. For sync, Hilbert takes **rate** from the corroborated `bpm.bpm` and **phase** from the grid; when the two are an octave apart it uses our factor to know how to reinterpret the grid's beat spacing (decimate every-other-beat for a 2× grid, subdivide for a ½× grid).
  - **Document the direction precisely:** `+2` = "grid tempo is ~2× the BPM-stage tempo"; `-2` = "grid is ~½×". I.e. `estimatedTempo ≈ bpm.bpm × (factor > 0 ? Double(factor) : 1.0 / Double(-factor))`.
  - An `Int` factor is `Hashable`/`Codable`-clean — it does **not** reintroduce the `Double`-payload problem that made us reject a `ratio: Double` (a `Double` would add a NaN clamp-site to `BeatGrid`'s NaN-free→`Hashable`/`Codable` doctrine). The exact fractional ratio, if ever needed, is still computable from the two raw tempos.
- **2× only for now.** Ship `0.5×`/`2.0×` octave detection only; treat genuine `4×`/`0.25×` as `.disagree`. True halftime DnB is already a 2× relationship (~174↔87); real 4× is fringe, and widening the band grows the false-positive surface. Hilbert would rather a real 4×-off track land in `.disagree` and prompt the user than auto-sync to quarter tempo. (Revisit only if real library data demands it.)
- **Use a RELATIVE tolerance, not absolute BPM.** Hilbert's range is 30–300 BPM; an absolute ±2 BPM is 6.7% at 30 BPM but 0.67% at 300 BPM — inconsistent. Use a relative band (**~2%**, matching the library's own `isNearMatch` at `BPMSelectionPolicy.swift:397-400`, `abs(a-b)/min ≤ 0.02`) for **both** the direct `.agree` comparison and the post-scaling `.octaveEquivalent` comparison. (Hilbert suggested ~2.5%; 2% keeps it consistent with the existing internal convention — either is acceptable, but it must be relative and uniform.)

> **Correctness invariant (do not get this wrong):** the agreement must be computed against a tempo the grid was **not** octave-snapped to. In Story 8.4, `estimatedTempo` is snapped to the single-pass `tempoBPM` (`BeatGridAnalyzer.swift:242`). If `analyze(...)` feeds that same single-pass tempo into the DP and then compares against it, agreement is a **construction artifact** (the library's own DD #2 warning). It is only a real cross-check if `estimatedTempo` is snapped to the single-pass octave and then compared against the **full multi-window** `bpm.bpm`. Hilbert is relying on this distinction for the flag to mean anything.

---

## 2. Coverage — `.analysisWindow` default is right; no `.fullTrack` consumer yet

- **Hilbert has no mid-track detected-beat consumer.** Its waveform/timeline UI is greenfield (the waveform generator is a literal `// TODO` stub; the scrubber is a normalized 0–1 fader with no beat overlay). For sync + quantize it extrapolates mid-track positions from `gridOrigin + estimatedTempo`, so it never needs detected beats past the analysis window.
- **Cache-bloat is a second reason.** Storing thousands of detected beats per track across the whole library is bloat Hilbert doesn't want — anchor+tempo (plus, later, a downbeat anchor) is a handful of values.
- **Therefore:** `.analysisWindow` default is correct; **do not invest in the O(track) `.fullTrack` path's accuracy now.** The "detected beats vs idealized grid" overlay is a real future want, but it's gated behind Hilbert's unstarted waveform work — they'll ask for `.fullTrack` accuracy when they build it, not before. Keep `.fullTrack` minimal/opt-in.

---

## 3. Confidence — compose from documented per-field signals; don't build a scalar

- **Hilbert composes the gate from parts** (its codebase philosophy: no opaque magic signals). **Lead with the degraded-path guard** — `analyze(...)` can return a nil grid, a nil `gridOrigin`, or `estimatedTempo == 0` (`BeatGrid` documents "gate validity with `estimatedTempo > 0`"). Filling the gate in naively either force-unwraps (crash) or admits a degraded grid, after which `deck.rate = masterBPM / trackBPM` divides by an unvalidated tempo and pushes `Inf`/`NaN` through the blind rate writer:
  ```swift
  guard let grid = beatGrid, let anchor = grid.gridOrigin, grid.estimatedTempo > 0
  else { return false }
  autoSyncAllowed = grid.tempoAgreement != .disagree
                 && grid.confidence   >= gridFloor    // provisionally ~0.5
                 && anchor.confidence  >= anchorFloor   // provisionally ~0.5
  ```
  The **rate layer must also reject non-finite / non-positive rates** before writing them (the way the seek path already guards `position.isFinite`) — a divide-by-unvalidated-tempo must not reach the blind actuator. Floors are **provisional** — Hilbert has no empirical floors yet (confidence is currently only logged, never thresholded) and will tune against its real library.
- **Our obligation (this is what they actually need from us):** document precisely **what each confidence measures**, and keep those semantics **stable across library version bumps** so a floor of `0.5` keeps meaning. Current semantics:
  - `BeatGrid.confidence = 0.5 · meanOnsetStrength + 0.5 · acfStrengthAtPeriod` (`BeatGridAnalyzer.swift:251`) — half mean per-beat onset salience, half normalized autocorrelation magnitude at the tracked period.
  - `gridOrigin.confidence` = the chosen anchor beat's per-beat confidence: a period-deviation Gaussian `exp(-(log(interval/period))²)` for interior beats, or the onset strength for the first beat (`BeatGridAnalyzer.swift:204-210`).
- **Do NOT build a derived "grid trustworthiness" scalar.** Keep the parts; document them; Hilbert composes and tunes.

---

## 4. `gridOrigin` anchor — the Rekordbox extrapolation model is the contract

- **Anchor + tempo is Hilbert's grid model**, not the raw `beats[]` array. It does beat math (continuous sync + sub-beat quantize) and will not trust the full detected-beat list — the DP can drop a beat on a missed onset or double one on a busy onset, and sub-beat interpolation between adjacent detected beats then produces wrong midpoints while continuous sync accumulates error across gaps.
- **Extrapolation:** `gridOrigin.presentationTime + (60.0 / estimatedTempo) · n` for the n-th beat. Drift-free by construction on constant-tempo material (the only kind the fixed-period tracker supports).
- `BeatGridAnchor { beatIndex, presentationTime, confidence, strength, source }`, selected by **phase consistency** (not max-strength, which can be a snare fill / off-beat transient; not first-beat, which can be weak because the analysis window starts at an energy transition). `source` records which rule chose it.
- **Extrapolation generalizes to `n ∈ ℤ` and sub-beats.** The forward whole-beat form above is the special case `n ≥ 0`. Backward extrapolation (into the intro, before the anchor) is `n < 0`; an M-way sub-beat snap (1/8-note quantize is `M = 2` per beat) is `gridOrigin.presentationTime + (60.0 / estimatedTempo) · (n + k/M)` for sub-index `k ∈ [0, M)`. All drift-free by construction on constant-tempo material.
- **`gridOrigin.beatIndex` is a back-pointer into *this grid's* `beats[]`, not a stable cross-analysis identifier.** It is `0 ..< beats.count`-valid for the grid that produced it (the library guarantees `beats[gridOrigin.beatIndex]` is safe — an out-of-range anchor is dropped to `nil` at construction), but it is coverage/window-relative: re-analyzing the same track, or analyzing a different one, yields an unrelated index. **Extrapolate from `presentationTime`, never from `beatIndex`.** The index is "which detected beat did we anchor on" introspection only.
- **Library-side ask (satisfied here): `estimatedTempo` and `gridOrigin.presentationTime` are DETECTOR-relative.** If a consumer substitutes its own tempo (a manual DJ "this track is really 140" override — Hilbert's `getBPM()` precedence is `userBPM > detector`), the cached grid is now inconsistent with playback: (a) launch extrapolation runs at the detected tempo while playback runs at the override rate; (b) `tempoAgreement` was computed against the detected tempo and no longer describes reality; (c) nothing rescales the static cache. **Contract for an overriding consumer:** keep `gridOrigin.presentationTime` (the phase is still valid) but recompute the period from the override tempo (`60.0 / userBPM`), and treat `tempoAgreement` as **stale** — recompute it against the override or demote it to `.notCompared`. (Which tempo is authoritative for *rate* is the consumer's call. The library's position: `bpm.bpm` / `estimatedTempo` are *detector* outputs; an override is the consumer overriding the detector, not the library being wrong. **Recommended library follow-up:** a DocC note on `BeatGrid.estimatedTempo` / `gridOrigin` stating this provenance explicitly — small, ships to `main`.)

---

## 5. Downbeats — a single first-downbeat anchor + meter (LANDED in Story 8.5a)

Downbeat detection (`DownbeatResult.detected`) was **not in Story 8.5**; it **landed in Story 8.5a** (`8-5a-downbeat-detection.md`), the first story to populate `DownbeatResult`. It unblocks Hilbert's bar/half-bar (1/1, 1/2) snap. It is **opt-in** via `Options.detectDownbeats` (default off → `.notAttempted`, BPM/grid byte-identical to 8.5); when on, a conservative fixed-4/4 downbeat-phase estimator returns `.detected(estimate:)` or an honest `.noneDetected` abstain. Story 8.5a implements exactly these constraints (designed so there is no second migration):

- **A single first-downbeat anchor is the minimal unblocker.** Because Hilbert extrapolates a constant-tempo grid, the bar grid is fully specified by one downbeat anchor + tempo + meter:
  ```
  barLine(barIndex) = anchorTime + barIndex × beatsPerBar / (estimatedTempo / 60.0)
  ```
  This composes with the reserved `BeatGridAnchor.source == .downbeat`: when downbeats run, `gridOrigin` becomes the first downbeat.
- **Include the meter (`beatsPerBar`, default 4).** "Top of the bar" = `beatsPerBar` beats; hard-coding 4/4 silently breaks 3/4 or 6/8. Cheap insurance even though Hilbert's material is ~99% 4/4.
- **Be precise about breaking vs additive (correction).** Story 8.5a *does* reshape `DownbeatResult.detected(beats:)` → `.detected(estimate: DownbeatEstimate{...})` — that **is a breaking `Codable` change** (fine pre-1.0, but do not mislabel it "additive / no breaking change"). The design intent is to take the breaking reshape **now**, with 8.5a, so that *afterward* a future per-beat `Battito` (1–4) payload can be added **truly additively**. (Rekordbox stores Battito because it survives manual grid edits and odd bars; Hilbert will want it eventually, just not to ship bar-snap.)
- **Bar/half-bar snap must gate on meter provenance.** 8.5a ships `MeterEstimate { beatsPerBar: 4, source: .assumed }` — it never sets `.detected` (4/4 is assumed, not measured). Bar-snap on an `.assumed` 4/4 silently misaligns on 3/4 · 6/8 material. The consumer should gate hard bar-snap on `gridOrigin.source == .downbeat && meter.source == .detected`; with `.assumed`, bar-snap is best-effort and should be surfaced as such. The library will **not** pretend an assumed meter was detected — surfacing that distinction is the whole point of the `source` field.

---

## 6. Timestamps & alignment — Double seconds, decoded-PCM-relative

- **Keep `presentationTime` as `Double` seconds. Do NOT add a sample-frame API for Hilbert.** Its entire stack is `TimeInterval`, and Double-seconds at 44.1 kHz already carries far more precision than its playback path can consume. When Hilbert eventually adds `AVAudioTime` scheduling for sample-accurate launch, it will convert seconds→frames itself using the file's sample rate. A frame-index API would be precision it can't use and would round-trip anyway.
- **Decoded-PCM-relative alignment is what Hilbert relies on.** Its claim (to validate on their side, not ours): AudioKit's `AudioPlayer.currentTime` reads the same `AVAudioFile` render position, which is also decoded-PCM-relative, so our beat times land on the same clock as their playhead with **no offset to reconcile** for lossless input. This is exactly the contract in the Story 8.5 alignment AC — `presentationTime` is relative to the decoded-PCM origin (`t = 0` = file start, energy-scan drop included).
- **Lossy caveat applies.** Hilbert's library is mostly MP3/M4A; the lossy decode-offset ambiguity (encoder delay) is an audible-flam risk for sample-accurate launch. The Story 8.5 README must distinguish lossless (sample-exact) from lossy (decode-relative, encoder-delay caveat) and quantify the worst-case lossy bound; the empirical priming verification + provenance query are Story 8.7.

---

## 7. Cancellation & progress

- **Wire `Options.isCancelled` through the combined `analyze(...)` — required.** Hilbert calls analysis from an actor during **batch indexing over a whole library**; a 5-min combined BPM+grid pass per file adds up. Cancelling an index run (or a re-index) must abort the current file's in-flight pass, mirroring what `analyzeBPM` already exposes (`Options.isCancelled` exists at `AudioAnalysisService.swift:283`). Today Hilbert's cancellation is coarse (a `Task.checkCancellation()` *before* the call), so an in-flight pass can't be interrupted — `isCancelled` through `analyze(...)` fixes that.
- **`onProgress` is optional / low-priority.** Hilbert would only use it for a per-file indeterminate→determinate indexing indicator; its batch-level file-count progress covers most of the UX.

---

## 8. `Codable` shape stability — a cross-version cache constraint (forward design note)

`BeatGrid` is cached per-track across Hilbert's entire library at index time, so the **`Codable` representation is a contract once a consumer caches it.** Pre-1.0 we break the type freely (and are doing so in Story 8.5 — `Bool?` → `TempoAgreement`, new `gridOrigin`/`coverage`), but be aware:

- A breaking `Codable` shape change invalidates a caching consumer's entire library cache, forcing a full re-index. That is a real cost for a raw-`BeatGrid`-caching consumer — but **this is NOT a backwards-compatibility concern and must not be framed as one** (BC is a non-goal; we break the shape freely). The remedy below is about *detecting* drift the consumer can act on, not about *avoiding* the break.
- **RESOLVED (2026-06-14, Codex + 3-agent adversarial triangulation → operator decision "add it, done right"; landing in Story 8.5a, the last unversioned shape).** Two complementary, orthogonal version fields:
  - (a) The **consumer owns a `cacheFormatVersion: Int`** on its own cached *projection* (§0). It versions *Hilbert's projection shape* and is the consumer's primary lever — with zero library change.
  - (b) The **library adds `schemaVersion: Int` to `BeatGrid`** (`currentSchemaVersion = 1`, encoded always, faithful `decodeIfPresent ?? 1`, **never throws** on an unknown future version, `Int` so the NaN-free→`Hashable` doctrine is untouched). Honest framing: a **semantic-drift / forensic stamp**, NOT cache protection and NOT BC. Two caveats stated plainly so nobody oversells it:
    - It is **inert in-library** — nothing in `Sources/` reads it. The `MLFeatureFrames.featureSetVersion` precedent this note originally cited is *load-bearing* (`BNNSTechnique` abstains on it at runtime, `BNNSTechnique.swift:366`); `BeatGrid.schemaVersion` is a value a *consumer* may gate on, read by no library code. The closer in-repo precedent is the stored `BaselineRecord.schemaVersion: Int` (warn-and-skip, not throw).
    - A breaking *shape* change already throws at decode, so `schemaVersion` buys nothing there. Its **only** job is the orthogonal narrow class the throw misses: a future change that keeps every key decodable but redefines *meaning* (the `confidence` formula, `estimatedTempo`/`presentationTime` provenance, the `tempoAgreement` factor sign — the §3 stability contracts). It also cannot retroactively tag pre-8.5a caches (absent→1); it versions forward only. And a top-level stamp is a *hand-maintained assertion* over the nested graph (the 8.5a break itself is inside `DownbeatResult`), only as reliable as bump discipline.
    - Ships in 8.5a **with** the read-side consumer contract (compare `schemaVersion` to `currentSchemaVersion` / your cache's version; re-index on mismatch; the library does not migrate) and a named bump-trigger list — a write-only version would be theater. Full rationale: Story 8.5a DD #9.

---

## 9. Continuous deck-to-deck phase-lock (distinct from launch)

The doc originally named only **quantized launch**; **continuous phase-lock** (holding two decks beat-aligned over time, not just at the launch instant) is a separate feature with a distinct dependency.

- **Library-side ask (open): characterize the extrapolation validity window.** The anchor+tempo grid is drift-free *on perfectly constant-tempo material*. A continuous phase-lock loop needs to know the **worst-case phase error on slightly non-constant material** (e.g. a track that breathes ±0.1 BPM) at, say, **3 min and 5 min** from the anchor, so it knows when a re-anchor is required. This is not yet characterized; it is a candidate measurement for the **Story 8.7 acceptance corpus** (it already times 5-min tracks and measures last-beat drift — the near-constant-tempo phase-error curve is an additive metric there). Until measured, document the contract as "drift-free on constant tempo; re-anchor cadence for non-constant material is consumer-tuned, library characterization pending 8.7."
- **End-to-end quantized-launch precision budget (consumer-side, but library feeds it).** A launch's audible error is the sum of: anchor hop-quantization (~10 ms, the onset-envelope hop), immediate-`play()` jitter (Hilbert-side, the §0 trigger prerequisite), and the lossy encoder-delay offset (~48 ms for AAC, §6). The consumer should assemble this budget and define a target audible tolerance rather than assuming immediate-play hits the grid.

## Confirmed correct — do NOT "fix" these

The second Hilbert-agent pass explicitly validated the following as spec-consistent. They are **not** contradictions; a future editor (or auditing agent) should leave them alone:

- `.analysisWindow` coverage default (matches Story 8.5 AC1) — §2.
- Relative ~2% agreement tolerance (matches the library's `BPMSelectionPolicy.isNearMatch`) — §1.
- `.octaveEquivalent(factor:)` direction `factor ∈ {-2, +2}` (2× only; 4× → `.disagree`) — §1.
- `gridOrigin` / `TempoAgreement` being net-new-but-scheduled (8.5 / 8.5a) — §1, §4.
- Seconds-currency, decoded-PCM-relative model; declining a sample-frame API is correct — §6.
- Reserving the non-emitted `BeatGridAnchorSource.downbeat` case now so 8.5a repoints `gridOrigin` with zero `Codable` break — §5.
- The lossy ~48 ms encoder-delay bound (2112/44100 ≈ 47.9 ms) is accurately quantified — §6.

## Library-side action items distilled (for the maintainer)

Everything above that is genuinely **library** work (vs Hilbert-side prerequisites):

1. **DocC provenance note** on `BeatGrid.estimatedTempo` / `gridOrigin` — they are detector-relative; a consumer override keeps phase, recomputes period, and stales `tempoAgreement` (§4). Small; ships to `main`.
2. **RESOLVED → Story 8.5a (AC9/DD #9):** add `BeatGrid.schemaVersion: Int` as a faithful-decode semantic-drift/forensic stamp (NOT BC, NOT cache protection; inert in-library; bare `Int`, never-throws, with the read-side consumer contract + bump triggers) — §8. *(Note: NOT modeled on `featureSetVersion`, which is load-bearing at runtime; the precedent is the stored `BaselineRecord.schemaVersion: Int`.)*
3. **Characterize the non-constant-tempo phase-error curve** at 3/5 min as an additive Story 8.7 acceptance-corpus metric — §9.
4. **`beatIndex`-is-a-back-pointer** wording — already a DocC-worthy clarification on `BeatGridAnchor.beatIndex` (§4).

The single thing to **escalate** is Hilbert-side, not library: the `deck.rate` arbiter (§0 BLOCKER). Until it lands, grid auto-sync conflicts with the shipped SharePlay sync — that is the consumer's gating prerequisite, and no library change unblocks it.

## Cross-references

- Story 8.5 spec: `_bmad-output/implementation-artifacts/8-5-long-file-sync-stability-and-bpm-beat-grid-consistency.md`
- Consumer roster + intent: memory `project_beatgrid_consumers`
- MediaDiff/MetaMan feedback (combined `analyze`, async, cancellation): [`api-feedback.md`](api-feedback.md)
- Design-fork reasoning: Codex thread `019ec2a4` (internal — do not share the thread itself; this doc is the portable contract)

## Summary of binding constraints

1. `TempoAgreement` total enum; `.octaveEquivalent(factor: Int ∈ {-2,+2})` carrying the factor (authoritative; document direction); `.notCompared` for `nil`.
2. 2× only (4× → `.disagree`); **relative ~2%** tolerance, uniform across direct + octave comparison.
3. Agreement compared against the **full multi-window `bpm.bpm`**, never the snapped single-pass tempo.
4. `.analysisWindow` default; no `.fullTrack` consumer yet — keep it minimal.
5. Document `confidence` semantics + keep them stable; don't build a trustworthiness scalar.
6. `gridOrigin` anchor + tempo extrapolation is the grid model; phase-consistency selected.
7. Future downbeat story: single first-downbeat anchor (`source == .downbeat`) + `beatsPerBar`; extensible to Battito.
8. `Double` seconds (no frame API); decoded-PCM-relative; lossy caveat.
9. `isCancelled` wired into `analyze(...)` (required); `onProgress` optional.
10. `BeatGrid` `Codable` shape is a cache contract — add library `schemaVersion` (fold into 8.5a) + consumer `cacheFormatVersion`.

**Second-pass deltas (2026-06-13, Hilbert-agent re-review).** The API/grid-shape decisions (§1–§8 above) were validated as sound — see "Confirmed correct." Changes were re-tensing §0 (the consumer model over-claimed readiness; the `deck.rate` arbiter, grid-bearing cache, and quantized-launch trigger are unbuilt Hilbert prerequisites, the rate arbiter being a 🔴 blocker), hardening the §3 gate example (lead with the `guard let grid … estimatedTempo > 0`), generalizing §4 extrapolation (`n ∈ ℤ`, sub-beat `k/M`) + the `beatIndex`-back-pointer + detector-relative-provenance notes, correcting §5's "additive" mislabel (8.5a's `detected(beats:)→detected(estimate:)` IS breaking) + the meter-provenance bar-snap gate, sharpening §8 (`schemaVersion`), and adding §9 (continuous phase-lock + validity-window characterization). Library action items distilled in their own section above.
