# Beat strength: how should the 4/4 decoder decide "no beat here"?

Request for guidance from the rekordbox analysis effort (`docs/rekordbox-analysis/FINDINGS.md`, `AGENT_GUIDANCE.md`). Written 2026-10-19 during review of PRs 198 to 200 (Epic 15, Stories 15.6 and 15.7).

## Where this sits

Story 15.6 added an internal framewise observation path: a producer emits per-frame beat and downbeat probabilities in `[0, 1]`, and `BarStateDecoder` (`Sources/BoomBoomBoomKit/FeatureSubstrate/Framewise/BarStateDecoder.swift`) walks the stream at a candidate tempo. The only producer today is `DSPStubObservationProducer`: the existing onset envelope divided by its maximum. No trained observation model exists yet; the full bar-state HMM is deferred to Phase 9.

The decoder is a windowed peak-pick. At each predicted position it takes the maximum over an on-window of plus or minus a quarter period, emits that frame as a beat, and re-anchors the next prediction on it. Positions without a beat advance by one period and leave a gap in `gridIndex`. `MetricalLevelSelector` ranks quarter, half and double tempo by mean on-beat minus off-beat contrast, and `JointTempoPhaseFit` (Story 15.7) fits tempo and phase through the emitted beats with outlier trimming.

## The problem

The decoder's beat test is `onWindow.value > 0`. A frame is "no beat" only when the on-window maximum is exactly zero. That holds for digital silence through the stub (the onset envelope is zero there, and the gap test passes), and for nothing else.

Any producer with a positive floor breaks it: a sigmoid or softmax head never emits an exact zero, and real audio through the stub has a noise floor in the onset envelope. With a flat floor the on-window argmax is the window's first frame (ties keep the earliest), so every gap position re-anchors about a quarter period earlier. Simulation at 100 fps, period 50 frames, clicks at 10, 60, 110, 260, 310 and two missing: predictions 160, 198, 236, 274 all pick floor frames, the returning click at 260 is missed, four phantom beats are emitted, and the click at 310 lands one grid position late. Two consecutive weak positions derail the grid until the shift wraps a full period.

## The fix under review, and the objection to it

Proposed: a relative support floor. A frame counts as a beat only when its probability is at least 10 percent of the largest beat probability over the usable span; the seed search uses the same rule; a rejected pick anchors the off-window on the prediction instead of on itself. Decoding stays alive on a constant input (the threshold scales with it), so the metrical-level comparison still receives a zero-contrast candidate at a wrong level.

Objection: the reference is one frame. A single large transient (a crash, a clipped sample, a pop) raises the bar for the whole span, so beats in a quiet intro or breakdown whose onset strength is under that line become "no beat". That produces the gaps and lost grid the fix is meant to prevent. Click fixtures cannot show it; real tracks in the Phase 9 evaluation would.

Alternatives considered so far, none chosen:

- a high percentile (for example the 95th) of the beat probabilities over the span, tracking the background rather than the peak;
- a local maximum over several periods around each prediction, following dynamics;
- a running reference from already accepted beats, such as a fraction of their median support;
- an explicit no-beat decision, which is what a bar-state decoder with a nonbeat state does.

`AGENT_GUIDANCE.md` item 4 already says to treat silence and weak passages as missing evidence, not reasons to force a new phase. The current rule violates that; the proposed fix satisfies it only for passages quieter than a tenth of the loudest onset.

## Questions

1. FINDINGS.md records that rekordbox's bar-state decoder includes "thresholding and peak correction" (`evidence/hopper/downbeat-tracking.json`, entry `0x102300d6c`; `evidence/native/rb-beat-0.asm`), and that the nonbeat probability is the remaining mass after beat and downbeat. What does the preserved pseudocode show about that threshold: an absolute value on the beat probability, a value relative to the sequence, or a decision made by the state space (nonbeat states) rather than by a threshold at all?
2. Does rekordbox treat a weak passage as missing evidence and carry the tempo and phase through it, or does it allow the grid to re-anchor there? Anything in the legacy focus analysis about minimum beat strength would help.
3. For our stub-era peak-pick, which reference for a "no beat" decision would you recommend until a trained observation head and the HMM arrive: a relative floor to the span maximum, a percentile, a local maximum, a running reference from accepted beats, or something else? The constraint is that a constant input must still decode with zero contrast, because the metrical-level selector needs a seed-level candidate to compare against.
4. Is a quarter-period on-window the right search width for re-anchoring once a reference exists, or should re-anchoring itself be gated (for example only when the accepted beat is also stronger than its off-window)?

Relevant code: `BarStateDecoder.decode` (windows, seed, emission), `MetricalLevelSelector.select` (requires a quarter-level candidate), `JointTempoPhaseFit.fit` (trimming at 0.15 period, abstention rules), `DSPStubObservationProducer` (normalization). Tests: `Tests/BoomBoomBoomKitTests/FramewiseObservationsTests.swift`.
