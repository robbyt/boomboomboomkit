# Tempo conflict resolution

How BoomBoomBoomKit reconciles **competing tempo hypotheses** into one reported BPM and
one beat-grid tempo. "Conflict" here means any disagreement between tempo signals — two
plausible candidates, an octave/half-double ambiguity, two analysis windows that disagree,
a file tag that contradicts the audio, an ML model vs the DSP, or a beat grid whose tempo
diverges from the BPM stage. This is the order in which those conflicts are resolved, and
the rule that decides each one.

> Scope: this documents the *resolution* logic — the points where the pipeline chooses
> between competing values. The signal-*production* DSP (onset detection, autocorrelation,
> tempogram) is upstream of this and covered in `CLAUDE.md` / the source. Pipeline step
> numbers (`BPMAnalyzer`) are stable identifiers.

## The pipeline, as a sequence of resolutions

```
candidates ─▶ rescore ─▶ octave/harmonic disambiguation ─▶ sub-band vote
            ─▶ cross-window merge ─▶ metadata corroboration ─▶ ensemble (DSP/ML)
            ─▶ [beat grid] tempo-agreement + lock precedence
```

Each stage takes a set of competing values and narrows it. `bpm` (the public
`AudioAnalysisResult.bpm`) is finalized at the ensemble stage; the **beat grid carries its
own `estimatedTempo`** that is resolved separately (and may legitimately differ — see §8).

---

## 1. Candidate set — the things that can conflict

The DSP produces a ranked list of `(bpm, score)` **candidates** (periodicity peaks fused
from autocorrelation + the Fourier tempogram, range-normalized to 60–200 BPM). This list
is the raw material every later stage arbitrates over. It is exposed verbatim on
`AudioAnalysisResult.candidates` **pre-disambiguation** — i.e. `candidates[0]` is the
top-*scored* candidate, which is **not necessarily the final `bpm`** once the stages below
run. (Forensic tooling must recover the selected candidate by matching `result.bpm`, not by
reading `candidates[0]` — see `AccuracyForensics`.)

A conflict the candidate generator cannot resolve is one it never surfaces: if the true
tempo is absent from the candidates, no downstream stage can recover it ("generation-bound"
failure). The forensic harness (`make accuracy-forensics`) measures this directly as the
recall split.

## 2. Per-candidate rescoring (damping / boosting, no winner change yet)

Two optional, technique-gated steps adjust candidate *scores* before any winner is chosen:

- **Click-track cross-correlation** (step 9b, `.clickTrackCorrelation`): a rhythmic-alignment
  check that **only damps** (multiplier ≤ 1) — `score ← score · (α + (1−α)·clickScore)`,
  `α = 0.3` floor. It tempers candidates that fail a beat-alignment test without ever
  boosting; it cannot invent a winner, only weaken implausible ones.
- **Duration-derived BPM hint** (step 9.7): boosts candidates matching a bar-count-derived
  BPM (a track that is an exact 32/64/96/128/192/256 bars at 4 beats/bar) by ~10%. A weak
  corroborative prior; never damps unmatched candidates.

## 3. Octave / harmonic disambiguation — the core conflict

This is the dominant tempo conflict (`resolveOctaveAmbiguity`): the audio is genuinely
periodic at both `T` and `2T` (or `T` and `1.5T`), and the right answer is a musical choice.

- **2:1 octave** (candidate ratio in `1.92…2.08`): resolved by **sub-band voting** plus a
  fused-energy fallback.
  - *Sub-band vote*: compare the autocorrelation strength of the fast vs slow period across
    four frequency bands (kick / snare-body / snare-crack / hi-hat) with fixed weights
    `[0.5, 1.0, 1.5, 2.0]`; the period more bands prefer (by weight) wins. (These weights
    are a known hand-tuned, genre-biased heuristic — see "Known limitations".)
  - *Fallback heuristic*: if sub-bands are unavailable, prefer the faster period only when
    its fused periodicity energy ≥ `0.3 ×` the slower's **and** its score ≥ `0.5 ×` the
    slower's (`octaveEnergyThreshold = 0.3`, `octaveScoreThreshold = 0.5`).
- **3:2 and 3:1 (triplet/half-bar)** ratios are *detected* and recorded as
  `HarmonicRatioEvidence` (trace-only) — they inform diagnostics but do not auto-promote a
  winner in the DSP path.

Octave selection is intentionally the **BPM stage's** job, not the beat grid's — the grid
tracks at whatever octave the BPM stage chose.

## 4. Sub-band confirmation (steps 10 / 10b) and fine-grid (10c)

After disambiguation, sub-band voting can re-confirm the chosen pulse (`SubBandVoteEvidence`
records pre/post), a sub-band peak-confirmation pass runs, and **fine-grid refinement** (10c)
nudges the winner to sub-0.1-BPM precision around the chosen period. These refine the
*chosen* tempo; they do not re-open the octave choice.

## 5. Cross-window merge — windows that disagree (`BPMSelectionPolicy.select`, Phase 1)

Progressive analysis runs multiple windows; each produces its own disambiguated result.
The **merge strategy** reconciles them. Default is `maxConfidence` (the most-confident
window wins). The closed set of 8 strategies (`BPMSelectionPolicy`):

| Strategy | Conflict rule |
|---|---|
| `maxConfidence` (default) | highest-confidence window wins |
| `dedup` | collapse near-duplicate candidates, then max |
| `quorum` | require agreement among ≥ N windows |
| `average` / `median` / `weightedAverage` | central tendency across windows |
| `union` | pool all candidates, then select |
| `windowVoting` | vote on each window's **post-disambiguation** BPM (via `VotingPolicy`: `simpleMajority` / `confidenceWeighted` / `thresholdGated`); falls back to `maxConfidence` on no consensus |

Key invariant (ablation finding): merging *raw* candidates loses per-window octave
disambiguation, so consensus strategies vote on the **disambiguated** per-window result, not
the raw candidate pool.

## 6. Metadata corroboration — file tags vs the audio (Phase 2a, `MetadataCorroborator.apply`)

Embedded BPM tags (`iTunes tmpo` / `ID3 TBPM` / `Vorbis BPM`) are **corroboration, not
authority** — the audio leads, the tag confirms:

- A candidate whose BPM matches a participating tag (same-tempo, or octave if
  `allowOctaveCorroboration`) is **boosted** `× 1.25`, clamped at `0.95` (a tag adds
  conviction but can never reach certainty). The winner is then re-selected from the boosted
  pool, so a tag *can* promote a corroborated candidate over an uncorroborated higher-scored
  one.
- If the unanimous tag *disagrees* with the DSP winner, a **skepticism penalty** `× 0.85` is
  applied to the DSP confidence (the disagreement is surfaced, not silently trusted).
- Intra-file tag conflicts (two tags > `0.5` BPM apart) reject both tags.
- Tags are never consulted as a primary source; `MetadataPolicy.disabled` makes this stage
  byte-inert.

## 7. Ensemble — DSP vs ML (Phase 2b, `combineEnsemble`, `EnsemblePolicy`)

When an `MLTechnique` is wired up, its `MLEvaluation` competes with the DSP winner. The
`EnsemblePolicy` decides:

| Policy | Conflict rule |
|---|---|
| `.dspOnly` (**default**) | ML never invoked; DSP wins (byte-identical to no-ML) |
| `.mlOnly` | ML wins when it returns non-nil; DSP fallback otherwise |
| `.highestConfidence` | higher self-reported confidence wins; DSP breaks ties |
| `.weightedVoting(SignalWeights)` / `.default` | per-source weighted resolution over the unified signal pool — `effectiveVote = confidence × weight[source]`; DSP wins ties; emits `EnsembleWeightResolution` |

This stage finalizes `AudioAnalysisResult.bpm`. The DSP winner reaching here has already
survived stages 1–6.

## 8. Beat grid — a separate tempo, and lock precedence

The beat grid (`BeatGrid.estimatedTempo`) is a **parallel step-11 fan-out** that does **not**
feed BPM winner selection. It is seeded by the single-window DSP tempo and may legitimately
differ from `bpm.bpm` by tenths of a BPM (or be auto-refined). Two conflict surfaces:

- **Grid vs BPM stage agreement** (`classifyTempoAgreement`, 2% relative band): reports
  `.agree` / `.octaveEquivalent(±2)` / `.disagree` so a sync consumer can decide whether the
  grid is trustworthy. This is *diagnostic*, computed before any lock.
- **`BeatGridTempoLock` precedence** (combined `analyze` path, `applyTempoLock`) — when the
  consumer asks to lock the grid tempo to an authoritative value:

  | Lock | Rule |
  |---|---|
  | `.off` (default) | grid keeps its tracked/refined tempo |
  | `.bpmStage` | **authoritative**: replace the grid tempo with the BPM-stage tempo, octave-normalized to the grid, applying **even on a within-octave disagreement**; no-op only on a true > octave divergence or non-finite/≤0 stage tempo (`stageLockTempo`) |
  | `.bpm(value)` | **gated** caller input: octave-normalized to the grid, but a value disagreeing by more than 2% within an octave — or non-finite/≤0/> octave — leaves the grid unlocked (`octaveNormalizedLockTempo`) |

  The authority difference is deliberate: `.bpmStage` is the pipeline's own output (trusted),
  while `.bpm(value)` is arbitrary external input (treated skeptically). Standalone
  `analyzeBeatGrid` has no BPM stage and ignores the lock entirely.

- **Auto tempo refinement** (`refineBeatGridTempo`, opt-in): refines `estimatedTempo` to
  sub-0.1-BPM by fitting the audio's onset-comb, behind a monotonic reject-guard (never
  worse than the seed). A non-`.off` lock overrides it; `.bpmStage` specifically discards the
  refined precision in favor of the coarse stage BPM.

## Resolution order, summarized

1. Generate candidates (a conflict absent here is unrecoverable downstream).
2. Rescore (damp implausible, boost duration-corroborated) — no winner change.
3. **Octave/harmonic disambiguation** — sub-band vote + energy/score heuristic.
4. Sub-band confirmation + fine-grid precision on the chosen pulse.
5. **Cross-window merge** (`BPMSelectionPolicy`) — windows that disagree.
6. **Metadata corroboration** — tags boost/penalize, can re-promote, never authoritative.
7. **Ensemble** (`EnsemblePolicy`) — DSP vs ML; finalizes `bpm`.
8. **Beat grid** — independent `estimatedTempo`; agreement diagnostic + lock precedence
   (`.bpmStage` authoritative, `.bpm` gated).

## Known limitations (where the resolution is weakest)

- **Octave disambiguation is hand-tuned.** The sub-band vote weights `[0.5, 1.0, 1.5, 2.0]`
  and the `0.3 / 0.5` energy/score thresholds are fixed and genre-biased. Forensic data shows
  octave/selection is the dominant OA300 failure (most misses have the correct tempo present
  in the top candidates but lose to disambiguation) — the planned work (Epic 12 octave-aware
  decode, Epic 13 ceiling sweep / beat-grid-support rescoring) targets exactly this stage.
- **Triplet (3:2 / 2:3) ratios** are detected but not auto-resolved in the DSP path.
- **`.bpm(value)` lock gating** rejects a within-octave > 2% manual lock (deferred decision
  `8-10-D6`).
- **Confidence is not empirically calibrated** for the DSP path (reliability curves now exist
  via the forensic harness; calibration is future work).

## Where to look in the code

- `BPMAnalyzer.swift` — candidates, rescoring (9b/9.7), `resolveOctaveAmbiguity`, sub-band
  voting, fine-grid (10/10b/10c).
- `BPMSelectionPolicy` / `VotingPolicy` — cross-window merge.
- `MetadataCorroborator` / `MetadataPolicy` — tag corroboration.
- `AudioAnalysisService.combineEnsemble` / `EnsemblePolicy` — DSP/ML resolution.
- `AudioAnalysisService.classifyTempoAgreement` / `applyTempoLock` / `stageLockTempo` /
  `octaveNormalizedLockTempo` — grid agreement + lock precedence.
- `BeatGridAnalyzer.refineTempo` — opt-in grid tempo refinement.
