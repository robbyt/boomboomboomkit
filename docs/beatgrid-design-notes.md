# Beat Grid — Consumer Design Notes (2manyDJs / "Hilbert")

_Date: 2026-06-13. Source: the Hilbert DJ-app agent's answers to the five Story 8.5 API-shape questions. Companion to [`api-feedback.md`](api-feedback.md) (the MediaDiff/MetaMan feedback). These are **binding design constraints** for the upcoming beat-grid features — Story 8.5 (anchor + tempo, `TempoAgreement`, coverage, combined `analyze`) and the deferred downbeat story. Keep them in mind while building; deviations should be deliberate, not accidental._

Two consumers shape the beat-grid API. **MediaDiff/MetaMan** (a metadata viewer) is instrumentation-only — it calls `analyzeBPM` and never touches the grid. **Hilbert** (a Rekordbox-style social DJ app) is the *real* grid consumer: it drives auto-sync and quantized launch off the grid, so the design below is what a live DJ feature actually needs. (`tempoAgreement` is therefore a **feature**, not a test-only signal — see §1.)

---

## 0. Hilbert's consumer model (this shapes everything below)

- **Analysis runs at index time and is cached per-track.** Beat grids are computed once during library indexing and stored on the track record — never recomputed at load or play time. Indexing is a hard prerequisite for all track ops.
- **`BeatGrid` being `Codable` is load-bearing** — it *is* the cache representation. (See §8: Codable-shape stability is a real cross-version constraint once a consumer caches.)
- **Hilbert works entirely in seconds** (`TimeInterval`). There is no sample-frame / `AVAudioTime` scheduling in its playback path today; launch is an immediate `player.play()`. Rate-matching already exists (AudioKit `VariSpeed` + a drift PI controller).
- **Implications we must honor:** Double-seconds is the timestamp currency (§6); cache-bloat is unwelcome (anchor+tempo over thousands of detected beats — §2); the `Codable` shape is a contract once cached (§8).

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

- **Hilbert composes the gate from parts** (its codebase philosophy: no opaque magic signals). Roughly:
  ```
  autoSyncAllowed = tempoAgreement != .disagree
                 && beatGrid.confidence   >= gridFloor      // provisionally ~0.5
                 && gridOrigin.confidence >= anchorFloor     // provisionally ~0.5
  ```
  Floors are **provisional** — Hilbert has no empirical floors yet (confidence is currently only logged, never thresholded) and will tune against its real library.
- **Our obligation (this is what they actually need from us):** document precisely **what each confidence measures**, and keep those semantics **stable across library version bumps** so a floor of `0.5` keeps meaning. Current semantics:
  - `BeatGrid.confidence = 0.5 · meanOnsetStrength + 0.5 · acfStrengthAtPeriod` (`BeatGridAnalyzer.swift:251`) — half mean per-beat onset salience, half normalized autocorrelation magnitude at the tracked period.
  - `gridOrigin.confidence` = the chosen anchor beat's per-beat confidence: a period-deviation Gaussian `exp(-(log(interval/period))²)` for interior beats, or the onset strength for the first beat (`BeatGridAnalyzer.swift:204-210`).
- **Do NOT build a derived "grid trustworthiness" scalar.** Keep the parts; document them; Hilbert composes and tunes.

---

## 4. `gridOrigin` anchor — the Rekordbox extrapolation model is the contract

- **Anchor + tempo is Hilbert's grid model**, not the raw `beats[]` array. It does beat math (continuous sync + sub-beat quantize) and will not trust the full detected-beat list — the DP can drop a beat on a missed onset or double one on a busy onset, and sub-beat interpolation between adjacent detected beats then produces wrong midpoints while continuous sync accumulates error across gaps.
- **Extrapolation:** `gridOrigin.presentationTime + (60.0 / estimatedTempo) · n` for the n-th beat. Drift-free by construction on constant-tempo material (the only kind the fixed-period tracker supports).
- `BeatGridAnchor { beatIndex, presentationTime, confidence, strength, source }`, selected by **phase consistency** (not max-strength, which can be a snare fill / off-beat transient; not first-beat, which can be weak because the analysis window starts at an energy transition). `source` records which rule chose it.

---

## 5. Downbeats — design the FUTURE story for a single first-downbeat anchor + meter

Downbeat detection (`DownbeatResult.detected`) is **not in Story 8.5**; it is **scheduled as Story 8.5a** (`8-5a-downbeat-detection.md`), the first story to populate `DownbeatResult`. It unblocks Hilbert's bar/half-bar (1/1, 1/2) snap. Story 8.5a implements exactly these constraints (designed so there is no second migration):

- **A single first-downbeat anchor is the minimal unblocker.** Because Hilbert extrapolates a constant-tempo grid, the bar grid is fully specified by one downbeat anchor + tempo + meter:
  ```
  barLine(barIndex) = anchorTime + barIndex × beatsPerBar / (estimatedTempo / 60.0)
  ```
  This composes with the reserved `BeatGridAnchor.source == .downbeat`: when downbeats run, `gridOrigin` becomes the first downbeat.
- **Include the meter (`beatsPerBar`, default 4).** "Top of the bar" = `beatsPerBar` beats; hard-coding 4/4 silently breaks 3/4 or 6/8. Cheap insurance even though Hilbert's material is ~99% 4/4.
- **Keep `DownbeatResult.detected` additively extensible to a future per-beat `Battito` (1–4) payload.** Hilbert does not need Battito for v1, but a single anchor now + an extensible shape avoids a breaking change later. (Rekordbox stores Battito because it survives manual grid edits and odd bars; Hilbert will want it eventually, just not to ship bar-snap.)

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

- A breaking `Codable` shape change **invalidates a caching consumer's entire library cache**, forcing a full re-index (expensive for them, and silent unless we signal it).
- **Design intent for the 1.0 window:** before 1.0, consider a `schemaVersion` / migration seam (or at minimum an explicit "this `Codable` change is breaking for cached consumers" signal in release notes) so a future shape bump doesn't silently corrupt cached grids or force an unannounced re-index. This is **not** a Story 8.5 deliverable — it's a constraint to weigh whenever `BeatGrid`'s stored shape changes.

---

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
10. `BeatGrid` `Codable` shape is a cache contract — weigh a version/migration seam before 1.0.
