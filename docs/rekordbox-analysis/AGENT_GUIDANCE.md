# AGENT_GUIDANCE — using this directory and planning the next epic

Audience: a future Claude Code / BMad / Codex agent planning or implementing
work driven by `FINDINGS.md`. This file is the handoff from the preservation
step (Phase 1) to everything downstream.

## Ground rules carried over from the handoff

1. **Treat `FINDINGS.md` as a current-HEAD report, not a specification.** Every
   call-site, offset, and line number in it is valid at
   `rterhaar/12-7-eval-corpus-harness` HEAD `0f90ed8de52a9626cd47d3a263bed5af90a6c80e`.
   Re-verify against the current branch before editing cited sources.
2. **Published methods, not shipped weights.** The architecture rekordbox uses
   closely matches [Böck et al. ISMIR 2016](https://archives.ismir.net/ismir2016/paper/000186.pdf)
   with a public reference at [madmom](https://github.com/CPJKU/madmom/blob/main/madmom/features/downbeats.py).
   Use that literature as the source of truth. The shipped TensorFlow models
   are research evidence; BoomBoomBoomKit must analyze audio independently.
3. **Hopper pseudocode is lossy.** For any float/SIMD-sensitive condition or
   constant, read the ARM64 instructions in `evidence/native/*.asm` directly;
   the `.c` sibling is a convenience, not the source of truth.
4. **Resolution is not accuracy.** `0x1011820d4` rounds to hundredths of a BPM;
   that establishes display precision only.
5. **No parity claims without a matched evaluation.** Agreement with rekordbox
   output is not independent truth. The matched-evaluation harness in Phase 9
   is the gate for any "meets or exceeds rekordbox" statement. Rekordbox's own
   beat-grid algorithm is not perfect: on syncopated DJ material its grid can
   lag a true kick transient by several ms, and its octave decisions miss on
   drum-and-bass / downtempo as often as our DSP path does. "Match or exceed
   rekordbox" is the Phase 9 scoring bar, specifically for kick-transient
   alignment on 4/4 EDM, correct musical tempo level, and stable constant-tempo
   grids. Phase 7's joint tempo/phase fit with sub-frame interpolation and the
   optional Story 15.3a oversampling knob are the two live levers for tightening
   phase accuracy; both report into Phase 9.
6. **Develop-only.** This directory stays on `develop`. Do not add it to
   `scripts/promote-to-main.py` or ship any part of it in the open-source
   release.
7. **Keep unrelated WIP intact.** The ML-annotation feature branch
   `rterhaar/12-7-eval-corpus-harness`, the untracked `addendum-design.md`,
   and the untracked `_bmad-output/ml-training/eval-corpus/` tree are not part
   of this work. Do not reset, clean, rebase, or touch Story 12-7's membership
   or signed corpus protocol as a side effect of anything below.

## Local-only artifacts

`artifacts/rekordbox-bpm-analysis.hop` is approximately 386 MB and gitignored
by `./.gitignore` (`/artifacts/*.hop`). Keep it on disk. If it is lost, the
Hopper queries can be re-run against a fresh database loaded from the
inspected rekordbox binary, but the saved `evidence/hopper/*.json` records
suffice to re-derive every claim in `FINDINGS.md` without the database.

## Epic 15 — multi-phased plan derived from `FINDINGS.md`

Epic 15 is chartered in `_bmad-output/planning-artifacts/epics.md` (added
2026-10-17). Epic 13 (DSP accuracy experiments) and Epic 14 (model retrain and
delivery) already hold those slots. The guidance in `FINDINGS.md` section
"Recommended order for a DJ library" and section 10 of the handoff describe
nine phases. The repository tracks them as BMad stories 15.1 through 15.9. Each
phase lands as a small, reviewable commit; nothing opens a PR without explicit
instruction.

## Coordination with Epic 12 and Epic 14 (standing rule)

**Epic 15 pins invariants, builds enablers, and runs harnesses; Epic 12 ranks
levers, picks variants, and gates retrains; Epic 14 bundles weights under Epic
12's gate.** Once Epic 15 pins a frame-time convention (Story 15.3), a waveform
channel policy (15.4), or an observation-path identity (15.6), Epic 12 retrains
inherit them. Epic 12 cannot change those invariants unilaterally; a change
requires an Epic 15 revision.

Ownership matrix:

| Lever / artifact | Builds | Decides to ship | Owns the gate |
|---|---|---|---|
| Phase 2 timing-baseline probe (15.2) | Epic 15 | — | — |
| Phase 3 frame-time convention + fix (15.3) | Epic 15 | Epic 15 (public API doc + regression test) | Epic 15 |
| Phase 4 waveform data types (15.4) | Epic 15 | Epic 15 (new namespace, additive) | Epic 15 |
| Phase 5 fixed-time ML input *harness* (15.5) | Epic 15 | — | — |
| Phase 5 input-representation *variant pick* | — | Epic 12 Story 12.5 | Epic 12 FR-58 |
| Phase 5 retrain under the picked variant | — | Epic 14 (gated on Epic 12 Gate 1) | Epic 14 |
| Phase 6 framewise observation path + 4/4 decoder (15.6) | Epic 15 (stub producer only) | Epic 15 (internal infra) | Epic 15 |
| Phase 6 trained observation weight bundle | — | Epic 14 | Epic 14 |
| Phase 6 fusion into `SignalSource.beatGrid` vote | — | Epic 12 corrected-ranking item 7(b) | Epic 12 |
| Phase 7 joint tempo+phase fit (15.7) | Epic 15 | Epic 15 (additive diagnostic) | Epic 15 |
| Phase 8 supplementary `.dawproject` annotations (15.8) | Epic 15 | Epic 15 (evaluation reference) | Epic 15 |
| Phase 8 Story 12-7 signed-corpus membership | — | Epic 12 Story 12-7 (unchanged) | Epic 12 |
| Phase 9 matched-evaluation harness (15.9) | Epic 15 | Epic 15 | Epic 15 |
| Any "meets or exceeds rekordbox" claim | — | 15.9 report body only | 15.9 report body only |

Escalation: Epic 15 reports evidence; Epic 12 holds the gate. If an Epic 12
ranking round accepts a variant that Epic 15 harness flags as regressive on a
sub-band, that disagreement is a Story 12.5 acceptance-criterion decision, not
an Epic 15 veto.

| Phase | Deliverable | Depends on |
|---|---|---|
| 1 | Preserve research (this directory) | — |
| 2 | Port the probe at `evidence/timing/TimingProbeTests.swift` into a reproducible target in-tree; confirm the 40–50 ms early-anchor measurement; publish a baseline tagged in `_bmad-output/perf-baselines/` | 1 |
| 3 | Define the frame-time convention; trace `BPMAnalyzer.swift:1181`, `:916`, `BeatGridAnalyzer.swift:330`; fix at the appropriate boundary (`presentationTime = ((f + 1) * hopSize + fftSize/2) / sampleRate`); add permanent regression tests across BPMs, sample rates, hop phases, leading silence, nonzero analysis-window offsets. **No universal +40/50 ms correction.** | 2 |
| 3a | Caller-configurable oversampling (`Options.beatGridOversamplingFactor` in {1, 2, 4}) for the STFT envelope; expands the Phase 3 regression bounds to assert tighter numbers at higher levels; measures the wall-clock impact. Opt-in, develop-only knob at first; folds into the public API once Phase 9 confirms the accuracy gain is reproducible. | 3 |
| 4 | Independent waveform-analysis objects: amplitude envelope + peak-preserving overview + low/mid/high energy with explicit per-bin timing (150 columns/second default, rational-safe), channel-aware stereo policy, bounded-memory streaming decode, cancellation + progress. **Do not depend on `RekordboxReader`.** Test matrix per handoff section 8 | 3 (reuses the fixed timing convention) |
| 5 | Fixed-time ML input experiments: fixed seconds/frame, fixed-duration crops, matched train/infer preprocessing, multi-crop at inference with explicit sequence-level aggregation; versioned frontend/window/padding/feature/normalization/crop/tensor/output-classes/model identity. Preserve the existing model path. | 2 (baseline) |
| 6 | Framewise beat/downbeat observation path, **not** on `MLTechnique`: decoded audio → timed observations (with explicit frame timing, origin, model+frontend identity, coverage) → structured 4/4 decoder → candidate beat sequence → constant-tempo refinement. Keep DSP as baseline. Avoid circular confidence; `SignalSource.beatGrid` stays a placeholder | 2 |
| 7 | Joint tempo/phase constant-tempo refinement returning a fitted pair; validated in separated stable regions; low-band vs broad spectral comparison on syncopated material; robust rejection of fills/missing kicks/offbeat accents | 6 |
| 8 | Reuse hand-annotation: preserve reference-downbeat timestamp, verified BPM, declared metrical level, bar position, stable span. Investigate what saved `.dawproject` files actually contain beyond tempo. **Do not extrapolate across a track from one 32-beat span.** **Do not touch the signed corpus protocol or Story 12-7 membership.** | 7 |
| 9 | Matched evaluation vs rekordbox (version-named mode), existing BoomBoomBoomKit, independent DAW references. Score separately: musical level, strict tempo, fine rate, absolute phase, F-measure, downbeat phase, long drift, failures/abstentions, runtime + peak memory. Paired per-track diffs, by DJ style/tempo band. **A 4% tempo hit is too permissive.** | 4, 7 |

## For the planning agent

The Epic 15 charter is at `_bmad-output/planning-artifacts/epics.md` and the
eight phase-planner story skeletons are at
`_bmad-output/implementation-artifacts/15-{2..9}-*.md`. The sprint-status
entry is logged at `_bmad-output/implementation-artifacts/sprint-status.yaml`.

The planning workflow is NOT the right place to make engineering decisions
about ML representation, grid timing, or waveform shape. It gathers them as
open questions to pressure-test in subsequent stories.

## For the implementing agent

- Make a `/bmad-code-review`-ready commit per sub-step, not per phase. Phase 3
  alone will land as several commits (trace, convention-fix, regression tests).
- Keep the probe target at `evidence/timing/` in sync with the in-tree test
  target in Phase 2 so a developer can reproduce the baseline measurement
  outside the production harness.
- Do not alter runtime preprocessing of existing weights and expect accuracy
  to improve. Retrain under the new contract or load weights trained for it.
- Keep the raw framewise observation stream distinct from any final playable
  grid. Both are useful; conflating them silently rewrites a public contract.
- `SignalSource.beatGrid` and `SignalWeights.beatGrid` are placeholders. Do
  not count learned evidence twice by giving the derived grid an independent
  vote.

## Open questions to carry forward

- Current rekordbox UI mode and whether users select constant vs dynamic tempo
  per track or globally.
- Which of `model7` / `model8` is actually invoked, and whether selection is
  user-configurable.
- Complete native resampling contract between the 44.1 kHz-trained frontend
  and the decoder's explicit 100 fps parameter.
- Model7/model8 training data provenance (not established; do not infer).
- Exact legacy focus-analysis fitting objective (large SIMD code; pseudocode
  is lossy).

Each of these is a diagnostic concern, not a blocker for Phases 2–8.
