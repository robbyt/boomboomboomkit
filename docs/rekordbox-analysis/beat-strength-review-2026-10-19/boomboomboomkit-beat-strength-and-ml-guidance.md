# BoomBoomBoomKit: beat evidence, phase tracking, and learned parameter selection

Development-agent handoff, 2026-10-19. This responds to `beat-strength-question.md`, including the follow-up request to learn thresholds and other analysis parameters from external evaluation. The objective is a DJ library that meets or exceeds Rekordbox on independently evaluated tempo, beat phase, grid stability, and 4/4 bar starts. These are implementation recommendations, not a claim that parity has been achieved.

## Read this first

Fix the decoder's handling of missing evidence before optimizing its thresholds. Then expose a bounded, versioned configuration and fit its parameters against labeled DJ tracks. After establishing a strong globally tuned baseline, test whether a small model that adapts selected parameters to each passage improves held-out results. Continue developing the beat/downbeat observation model and a structured decoder alongside this work.

Yes: thresholds can be learned. So can search widths, transition penalties, refinement weights, and confidence calibration. A practical first step is offline algorithm configuration: an optimizer repeatedly runs the Swift pipeline, compares results with annotations, and selects settings. This need not put another neural network into the shipping Swift library. A later contextual model can predict settings from the audio itself.

The immediate bug is structural: the current decoder treats any positive activation as both a beat observation and permission to move its clock. Optimizing a number cannot make those two meanings equivalent. Preserve explicit distinctions between a predicted grid position, an observed beat, and a trusted phase correction.

## Reviewed state and scope

Reviewed BBBK commit: `a2d213c54d9a5a4ab68bf96bbaf8101bc7b8573a`, branch `rterhaar/15-7-joint-tempo-phase-fit`. Recheck your current diff before implementing; another agent may have advanced these files.

Relevant sources under `Sources/BoomBoomBoomKit/FeatureSubstrate/Framewise/`:

- `FramewiseObservations.swift`: timing and probability contract.
- `DSPStubObservationProducer.swift`: onset salience divided by its span maximum; downbeat support is half beat support.
- `BarStateDecoder.swift`: seed search, on/off windows, emission, and greedy re-anchoring.
- `MetricalLevelSelector.swift`: quarter/half/double comparison and required quarter-level baseline.
- `JointTempoPhaseFit.swift`: refinement, trimming, support cutoff, and abstention.
- Tests: `Tests/BoomBoomBoomKitTests/FramewiseObservationsTests.swift`.

This handoff does not authorize replacing your branch or discarding concurrent changes. Use ordinary local snapshots within your writable BBBK workspace before each implementation stage. No BBBK source files were modified by this investigation.

## Evidence and reproduction

Raw disassembly, model graphs, evidence bundles, and probe artifacts are kept locally and ignored by Git. Only the Markdown reports are intended for version control. Artifact links and copy commands below require those local files; a fresh checkout contains the reports without the supporting artifact directories.

**Development-agent constraint:** do not commit the Logic disassembly work. `combined-evidence.json` contains full proprietary pseudocode/assembly, and `function-index.json` is its address index; both must remain local-only wherever copied. Keeping only `hopper/`, `native/`, and `model/` out of Git is insufficient. Preserve the Markdown output summaries. If your repository keeps evidence-manifest rows, retain filenames, sizes, hashes, and local lookup pointers only, without embedding raw code or exporting the evidence payload. Ignore rules do not untrack an already staged/tracked file: inspect the destination index before committing, and remove any raw artifacts from that index while retaining local files. No commit or push of raw Logic artifacts is authorized.

The supporting directory is [beat-strength-evidence-2026-10-19](beat-strength-evidence-2026-10-19/). Its manifest records source paths, sizes, and SHA-256 hashes. The additional [Logic Pro report](logic-pro-analysis-2026-10-19/README.md) preserves new REA/Hopper evidence and shipped-model metadata. The beat-strength directory preserves:

- Four focused Hopper queries, each as JSON and pseudocode: threshold trimming, observation likelihoods, state-space construction, and bar Viterbi decoding.
- Native ARM64 assembly for the threshold helper and the learned-analysis call site.
- The query script and a standalone Swift probe containing unchanged copies of the four reviewed decoder/selector/fitter/observation sources.
- Probe output and build log. The probe's `FeatureSubstrate.DecodedAudio` placeholder only satisfies an unused protocol type; it does not emulate or test the PCM frontend.

The new Hopper records explicitly identify their route as the installed REA adapter called through Hopper's Python console. They are static evidence, not MCP Evidence envelopes or recordings of application audio analysis. Decompiled variable names and types are imperfect; use the accompanying assembly when interpreting constants and calls.

Earlier artifacts already reside in BBBK at `docs/rekordbox-analysis/`, including `FINDINGS.md`, `AGENT_GUIDANCE.md`, the saved Hopper database, model inspection, and native assembly. The reader repository's [research.md](research.md) preserves the Bitwig findings.

To copy this supplement into a writable BBBK checkout, run this from the development agent's environment. It creates a new directory and refuses to replace an existing destination:

```bash
python3 - <<'PY'
from pathlib import Path
import hashlib, json, shutil
src = Path('/Users/rterhaar/Dropbox/research/swift/rekordboxReader/docs')
dst = Path('/Users/rterhaar/Dropbox/research/swift/BoomBoomBoomKit/docs/rekordbox-analysis/beat-strength-review-2026-10-19')
assert not dst.exists(), f'Review existing destination first: {dst}'
# Install destination ignore rules BEFORE copying local-only artifacts.
repo = Path('/Users/rterhaar/Dropbox/research/swift/BoomBoomBoomKit')
ignore = repo / '.gitignore'
rules = '''
# Imported analysis evidence stays local; Markdown summaries may be tracked.
combined-evidence.json
function-index.json
**/beat-strength-evidence-*/
**/logic-pro-analysis-*/*
!**/logic-pro-analysis-*/README.md
'''
current = ignore.read_text() if ignore.exists() else ''
if rules.strip() not in current:
    ignore.write_text(current.rstrip() + '\n' + rules)
dst.mkdir(parents=True)
guide = 'boomboomboomkit-beat-strength-and-ml-guidance.md'
shutil.copy2(src / guide, dst / guide)
evidence = 'beat-strength-evidence-2026-10-19'
shutil.copytree(src / evidence, dst / evidence)
logic = 'logic-pro-analysis-2026-10-19'
shutil.copytree(src / logic, dst / logic)
for folder in [evidence, logic]:
    manifest = json.loads((dst / folder / 'manifest.json').read_text())
    for item in manifest['files']:
        path = dst / folder / item['path']
        assert path.stat().st_size == item['bytes'], path
        assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256'], path
shutil.copy2(src / 'research.md', dst / 'research.md')
print(dst)
PY
```

Reproduce the source-level failure from this reader checkout; the standalone probe does not need the BBBK package or its datasets:

```bash
CLANG_MODULE_CACHE_PATH=/private/tmp/beat-strength-clang \
SWIFTPM_MODULECACHE_OVERRIDE=/private/tmp/beat-strength-module \
swift run \
  --package-path docs/beat-strength-evidence-2026-10-19/probe \
  --scratch-path /private/tmp/beat-strength-build \
  --cache-path /private/tmp/beat-strength-cache \
  --disable-sandbox Probe
```

All cases below use 100 fps, 120 BPM, a 50-frame period, and zero frame origin. Clicks occur at frames 10, 60, 110, 260, and 310.

| Observation input | Observed decoder output | Interpretation |
| --- | --- | --- |
| Constant 0.01, 400 frames | `0,38,76,114,152,190,228,266,304,342`; contrast 0 | Flat support repeatedly advances the clock early. |
| Constant 0.5, 1200 frames | `0,38,76,...,1140`; contrast 0 | The problem also occurs at a high constant floor. |
| Clicks over floor 0.01 | `10,60,110,148,186,224,262,310,348`; indices `0...8` | Phantom observations and wrong index progression appear through the gap. |
| Same clicks over floor 0 | `10,60,110,260,310`; indices `0,1,2,5,6` | Exact zeros preserve the intended missing positions. |

The selector chose quarter level and the final fitter abstained in all four cases. These observations demonstrate a decoder defect; they do not demonstrate that the current public analyzer accepts a false final grid. Add longer fixtures with enough genuine beats to exercise the fitter's acceptance path.

## Answers to the four questions

### 1. What does Rekordbox's threshold actually do?

At the inspected learned-analysis call site, ARM64 instructions at `0x102308510` through `0x102308540` construct float bits `0x3d4ccccd`, approximately 0.05, and pass the value into `madmom::downbeat_tracking`. The call also supplies observation lambda 16 and a 100 fps cadence. See the retained `native/rb-beat-1.asm`.

The threshold helper at `0x102302f00` compares activations against its scalar argument, finds qualifying indices, and slices the original activation array between the first and last qualifying frames. It does not divide the threshold by the maximum activation or erase each weak frame inside that span. Its no-qualifying-data path needs to be interpreted using its native return representation; do not assume it literally returns the same empty Python array as a reference implementation.

**The observed 0.05 is an absolute activity-span threshold, not a per-predicted-beat acceptance floor.** Interior weak frames remain available to the sequence decoder. Span selection, state decoding, and local peak correction are separate operations.

The public pinned [madmom threshold helper](https://github.com/CPJKU/madmom/blob/27f032e8947204902c675e5e341a3faf5dc86dae/madmom/features/beats.py#L844-L877) provides a useful independently inspectable reference for span trimming. It does not establish Apple's or Rekordbox's training procedure or the origin of proprietary weights.

### 2. How is phase carried through weak passages?

The inspected Rekordbox path uses a structured bar/tempo state sequence and Viterbi decoding. A weak frame is evaluated in the context of permitted transitions and neighboring evidence. Final peak correction operates within decoded beat regions. It is not the current BBBK rule of finding any positive maximum in a wide window and independently resetting the next prediction to that point.

With lambda 16, the nominal beat-region fraction is about 1/16 of a period, roughly 31 ms at 120 BPM before frame quantization. This is not a directly interchangeable setting for BBBK's acquisition window.

This supports using a persistent phase/tempo model and constrained correction. It does **not** prove that Rekordbox freezes phase throughout every breakdown, suppresses every weak beat, or has a particular minimum-strength rule in its legacy focus pass. The exact legacy optimization objective and its weak-beat policy remain unestablished.

A nonbeat HMM state generally represents frames between beats. It is not, by itself, a special instruction to omit an entire musical grid position. A DJ grid should continue across a breakdown even when no transient supports a particular position; keep inferred grid events distinct from acoustic observations.

### 3. What should the stub do now?

Use locally measured evidence above background, and preserve the tracking clock when that evidence is absent. Do not make a fraction of the single largest onset in the whole span the complete fix.

Recommended starting design, to be validated rather than treated as a proven detector:

1. Estimate local background and variation over several beat periods. Median and median absolute deviation are reasonable initial robust statistics. Define window alignment, edge behavior, and exclusion of the candidate's immediate peak neighborhood.
2. Measure local peak prominence above that background, plus neighborhood contrast and temporal consistency. Retain raw amplitude separately.
3. Require meaningful prominence to emit an observed beat. For a constant stream, prominence must be zero. Use a documented numerical guard when the background variation is zero; do not allow division by a tiny MAD alone to turn negligible perturbations into certainty.
4. Apply a separate, stricter rule before correcting phase. A plausible onset is not necessarily the musical beat to which the grid should move.
5. Reject unsupported observations while advancing the predicted grid by one period and incrementing `gridIndex`. Do not reset the clock to a floor argmax.

An entire-window 95th percentile is affected by peak sparsity and frame cadence: it may describe background when beats occupy few frames. A local maximum is still vulnerable to one outlier. Accepted-beat history can help but cannot be the only reference: it has a cold-start problem and can lock out a new quieter section. Evaluate local robust statistics as the initial baseline, with these alternatives as controlled ablations.

The current stub emits normalized onset salience, not calibrated probability. Treat its scores accordingly. A calibrated learned producer may need a different decision rule; version that rule with the producer.

#### Keep the selector baseline without inventing observations

For a sufficiently covered positive constant stream, return a valid **no-evidence candidate** with zero contrast and no observed beats, or explicitly mark its positions as prediction-only. It can participate as the quarter-level comparison baseline while the fitter abstains. Do not claim its arbitrary bookkeeping phase is an acquired musical phase.

Preserve the currently intentional all-zero/silence result and coverage/admissible-seed rejection behavior unless you make an explicit, tested API change. The quarter-level requirement must not be bypassed merely because a half/double candidate fits a shorter clip.

This requires handling an empty observation list: avoid `supportSum / 0`, give evidence/support status an explicit meaning, and make fitting reject it cleanly. An alternative is an explicit candidate status such as `noEvidence`, with an optional phase. The public API need not expose these internal choices.

For flat maxima, prefer the frame nearest the prediction, followed by a deterministic secondary tie rule. This prevents a directional tie bias but does not replace the missing-evidence decision. Apply the evidence rule in seed acquisition as well as subsequent tracking; otherwise a quiet leading floor still chooses a false initial phase.

### 4. How wide should the window be, and when can it move phase?

A wide acquisition window can be useful. A wide window does not authorize an equally large phase correction at every position. Separate acquisition, steady tracking, coasting, and deliberate reacquisition.

For ordinary tracking, combine local evidence with a phase residual and a correction bound. A positive on-minus-off margin alone fails on noise; a mandatory `on > off` rule for every observation also rejects legitimate beats in syncopated material. Use on/off contrast as one feature and a metrical-level score, rather than the universal definition of a beat.

Keep signed contrast contributions from all admissible predicted positions, including rejected observations. Keep the denominator based on scored positions. Do not inflate a candidate by averaging only its accepted strongest beats. Anchor the off-window on the committed prediction/correction decision, not on a discarded peak, and document the ordering so the algorithm is not circular.

The existing decoder can move by nearly 0.25 period while the fitter trims beyond 0.15 period. Those settings have different purposes but currently permit incompatible behavior. A large residual should trigger an explicit reacquisition hypothesis or be rejected as a correction; do not rely on trimming to reconstruct grid indices after greedy tracking loses them.

Preserve fractional periods and subframe time conversion. Independently snapping each position to an integer period introduces drift; model a floating-point clock, and update its rate only through an explicit estimator. Preserve the existing five-minute slightly-wrong-seed-tempo regression: simply freezing a wrong initial period is not sufficient.

## Probability semantics before introducing an HMM

BBBK currently documents inclusive beat probability `B`: downbeats also count as beats. The reference three-class observation model uses mutually exclusive ordinary-beat and downbeat classes. These contracts are different.

If BBBK keeps inclusive `B` and downbeat probability `D`, a compatible categorical decomposition is:

```text
nonbeat      = 1 - B
ordinaryBeat = B - D
downbeat     = D
require 0 <= D <= B <= 1
```

Do not copy a reference `1 - B - D` expression onto inclusive BBBK channels. Alternatively change the producer contract to exclusive classes and migrate every consumer and fixture together. Document whether `D` is marginal or conditional; the equation above assumes marginal downbeat probability.

The inspected native observation model uses log likelihoods with ordinary beat, downbeat, and remaining nonbeat mass distributed over nonbeat states. The pinned [madmom observation model](https://github.com/CPJKU/madmom/blob/27f032e8947204902c675e5e341a3faf5dc86dae/madmom/features/beats_hmm.py) and [downbeat decoder](https://github.com/CPJKU/madmom/blob/27f032e8947204902c675e5e341a3faf5dc86dae/madmom/features/downbeats.py) explain this reference structure. State-space details and class semantics must be ported together.

The current `D = 0.5 * B` stub contains no independent bar-start information. Good beat tracking on that stub is not evidence of good downbeat detection. Let bar phase be uncertain rather than assigning confidence to an arbitrary tied phase.

## Learning thresholds and other parameters from external analysis

### Distinguish three experiments

| Experiment | What is learned | What ships in Swift |
| --- | --- | --- |
| Global algorithm configuration | One parameter set that performs well across training/validation tracks | A versioned configuration; no additional inference model required |
| Contextual parameter selection | A mapping from audio/passage features to a few bounded settings or profiles | A small predictor plus validation, bounds, and fallback configuration |
| Observation learning | Framewise beat/downbeat evidence from audio | The trained observation model and its exact frontend/timing contract |

These can be combined. A learned observation model still needs decoding, confidence, and refinement settings. There is no evidence from this reverse engineering that Rekordbox learns its threshold values dynamically. The adaptive parameter approach here is a proposal for BBBK.

For offline global tuning, start with random search as a control, then a Bayesian/TPE or random-forest-based optimizer. [SMAC's official guide](https://automl.github.io/SMAC3/latest/3_getting_started/) describes algorithm configuration against a target function and evaluation instances. [Optuna's multi-objective tutorial](https://optuna.readthedocs.io/en/stable/tutorial/20_recipes/002_multi_objective.html) demonstrates selecting configurations across competing objectives. Pin the selected tool version in the experiment environment; do not add it as a shipping Swift dependency.

### Expose meaningful parameters, with units and legal combinations

Build one internal `Codable & Sendable` configuration rather than scattering experiment constants across files. Reject nonfinite values, invalid ranges, and incompatible combinations at the harness boundary. Record defaults and configuration schema version. Initially tune roughly 8–15 influential dimensions, then expand only if validation and sensitivity analysis justify it; this is an experimental scope recommendation, not a magic statistical bound.

Candidate groups:

| Group | Example tunables | Coupling to respect |
| --- | --- | --- |
| Local evidence | Background window in periods, prominence multiplier, minimum effective scale, neighborhood shape | Frontend cadence, peak width, normalization |
| Acquisition | Search span, minimum evidence duration, hypothesis count | Available coverage and tempo ambiguity |
| Tracking | Search half-width in periods, phase gain, maximum ordinary correction, rate gain | Clock stability, seed-tempo error, fractional periods |
| Reacquisition | Required evidence consistency, competing-hypothesis margin | Gaps, intentional tempo changes, index continuity |
| Structured decoding | Tempo-change penalty, beat-region width, observation temperature | Model calibration and state discretization |
| Refinement | Robust residual scale, reliability weighting, support/coverage requirements | Observation acceptance, metrical level, abstention |

Some quantities are architectural choices, not useful free parameters. Class semantics, frame timestamps, coverage boundaries, monotonic indices, finite arithmetic, and the rule that absent evidence cannot itself correct phase are invariants. An optimizer must not “improve” a score by changing them. Keep evaluator tolerances and test annotations outside the tunable configuration.

Do not expose a hundred independent knobs merely because you can. Large spaces cost more evaluations, contain redundant parameterizations, and are easier to overfit with a small annotated corpus. Introduce conditional parameter groups only when that algorithm path is active. Compare a larger search against a small baseline at equal compute budget.

### Build a deterministic external evaluator around the Swift implementation

The tuning controller can be Python; the target must execute the production Swift analysis code. Avoid maintaining a separate Python reimplementation whose winner behaves differently after porting.

Proposed harness flow, not an existing command contract:

```text
configuration JSON + track/annotation manifest + fixed evaluation seed
    -> Swift analysis executable
    -> per-track result JSON with predictions and diagnostics
    -> independently specified scoring
    -> optimizer trial metrics, constraint outcomes, and provenance
```

Compile the analysis executable once per code revision, rather than invoking a package rebuild for every trial. Cache decoded PCM and features only when their complete dependency identity matches. Changing normalization, STFT timing, hop size, sample rate, or the observation model invalidates affected caches. Observation caches must record model/frontend identifiers, frame origin, cadence, coverage, and source-audio identity.

For each trial save the configuration, source commit plus dirty-diff identity, dataset split/hash, annotation version, model hash, frontend identity, seeds, per-track errors, runtime, memory, and abstention reasons. Detect failed processes and malformed/nonfinite results; an abstention or crash must not disappear from the denominator.

Prefer a few useful objectives and constraints over dozens of separately optimized scores. They should expose DJ failures rather than reducing every decision to raw BPM accuracy.

Suggested metric set:

- Exact intended tempo level, with half/double errors reported separately from unrelated errors.
- Fine tempo error at the intended level and accumulated phase drift over the track.
- Signed absolute phase error on the decoded-PCM timeline, plus median and tail absolute error. Do not align each result to truth before measuring this.
- Beat continuity, beat-index slips across breaks, and bar/downbeat phase accuracy.
- False confident grids, abstentions, and accuracy versus coverage. A configuration that abstains on every hard track must not win.
- Performance on quiet sections, long breakdowns, and worst-performing track groups.
- Wall time and peak memory on a fixed machine and analysis mode.

Set quantitative acceptance margins before examining the locked test set. Use track-level paired comparisons and uncertainty estimates, rather than treating thousands of neighboring frames as independent examples. A standard broad beat-matching score can be supplementary, but cannot establish tight DJ phase accuracy by itself. Tempo-only datasets cannot supervise the full beat/downbeat objective.

An initial search objective can minimize independently measured phase/grid failure while enforcing minimum coverage and maximum runtime constraints. Select among finalists using the full metric table; do not hide octave or bar-start regressions in a weighted average. Make any weights explicit and fixed before final evaluation.

### Use external analysis without confusing a teacher with truth

Useful external signals include hand-annotated beat/downbeat times, independently checked tempo and phase, synthetic signals with exact timing, and outputs from other analyzers. An expensive offline ensemble or analysis pass can provide training targets for a cheaper runtime model.

Rekordbox and Logic outputs can be comparison baselines or weak teacher labels. Keep their provenance, exact analysis settings, file versions, and human verification status. Agreement with either application is not independent evidence that a prediction is musically correct. Where they disagree, prioritize annotation and adjudication rather than majority voting by assumption.

Do not use a reference analyzer at shipping inference time if the goal is independent analysis. Do not give the contextual predictor annotation-derived error features that will not exist for a new user track. Separate an offline oracle experiment from a deployable prediction experiment in every report.

### Hold out entire related track groups

Split by original recording and related versions; keep edits, remasters, stems, excerpts, and augmented copies in the same group. Also inspect artist/release overlap. Randomly splitting frames or clips from the same recording leaks its rhythm, production, and timing.

With only a few hand-annotated tracks, use grouped cross-validation within development data, keep a genuinely untouched test group, and prefer simpler configurations. If selecting the contextual model as well as its parameters, nest that selection within development folds. The final test set is not another tuning dashboard.

Record ambiguous musical tempo levels and annotation uncertainty. Training a model against contradictory “ground truth” can reward arbitrary octave preferences. Include musically diverse DJ material: straight four-on-the-floor, breakbeat, halftime, syncopation, sparse intros, quiet breakdowns, large drops, clipping, sustained pads, and tracks with actual tempo changes.

### Contextual adaptation after global tuning

First test a small number of globally validated profiles. Predict which profile to use from observable features such as local onset distribution, robust background scale, dynamic range, periodicity strength, spectral balance, agreement of tempo hypotheses, and recent phase residual consistency. A small classifier or regressor may suffice; do not assume a large network is needed.

A profile selector is often easier to diagnose than unconstrained regression of a large parameter vector. Several different parameter vectors can yield the same output, making “the best vector for this track” an unstable supervised label. If generating oracle profile labels offline, do it within the training partition and retain near-ties/uncertainty. Compare contextual selection with the best fixed profile, not just untuned defaults.

For passage adaptation, define whether offline future context is permitted. Smooth parameter changes, use hysteresis or a minimum dwell where appropriate, and bound how they affect phase/tempo. A threshold change alone must not create a phase jump. Start with a few outputs—evidence sensitivity, phase correction trust, and perhaps a validated profile—rather than allowing every constant to change every frame.

Train and validate confidence as well as accuracy. An out-of-distribution or low-confidence passage should fall back to the validated configuration or retain multiple hypotheses. Do not turn model uncertainty into a confident grid reset.

A sensible progression is: global configuration -> profile selection -> bounded passage adaptation -> consider joint training only if the measured benefit warrants it. A nondifferentiable peak picker/HMM can be tuned with black-box optimization; a differentiable surrogate is not required for the first experiments. End-to-end learning is a separate research task with additional stability and deployment obligations.

### Audit the fitter before celebrating a better decoder

The reviewed fitter has `minSupportScore = 0.1`, minimum 8 kept beats, minimum kept fraction 0.5, trim radius 0.15 period, and maximum relative tempo deviation 0.05. The support cutoff is especially relevant: accepting quiet beats in the decoder may still end in abstention because the fitter averages globally normalized stub amplitude.

Separate amplitude, calibrated event probability, observation reliability, and fit residual. Do not feed a locally standardized prominence directly into a field documented as probability. Either preserve raw support and add explicit reliability, or migrate the contract and identifiers. Evaluate fit rejection reasons in the tuning report so the optimizer cannot compensate for one gate by making another excessively permissive.

## Regression and evaluation work for the development agent

Implement the structural correction and tests first, then add configuration and optimization. Use the current project Makefile/test conventions. Add targets for the new tools only after their CLI exists; do not document fictional working commands.

| Fixture | Required checks |
| --- | --- |
| Existing exact-silence gap | Preserve observed times and missing `gridIndex` positions. |
| Same gap over a positive constant floor | No floor observations or cumulative early corrections; returning clicks retain their intended times and indices. |
| Positive constants at several magnitudes | Zero contrast baseline where coverage permits, no acquired observed phase, fitter abstains, no division by zero. |
| Quiet periodic beats plus one large transient | The isolated maximum does not globally suppress the quiet beat train; inspect final fit acceptance as well as decoder output. |
| Abrupt loud-to-quiet and quiet-to-loud sections | Local reference adapts without losing grid index or causing a phase jump. |
| Seeded noise, with and without beats | No systematic directional walk; measure false corrections and final false-confident fits across multiple fixed seeds. |
| Strong syncopated/offbeat events | Preserve actual beat evidence; do not force `on > off` to become a universal emission rule. |
| Long break followed by returning beats | Preserve index continuity and diagnose tempo uncertainty; distinguish ordinary correction from explicit reacquisition. |
| Fractional periods and existing five-minute wrong-tempo seed | No integer-period drift; stable convergence/refinement and no missing/duplicated indices. |
| Coverage boundaries and short clips | Preserve admissible seed rules, full-window scoring, and quarter-baseline requirements. |
| Independent beat and downbeat patterns | Validate class semantics and downbeat phase; do not use only `D = 0.5 * B`. |
| Absolute timing fixtures through the real frontend | Check frame origin, resampling, and phase on the PCM timeline; the observation-only probe cannot verify these. |

Assert the intermediate observations, candidate status, score denominator, correction decisions, selector outcome, fitter acceptance/rejection, and final musical grid. Distinguish prediction-only positions from observed beats in diagnostics. Include enough real beats around synthetic gaps to satisfy the fitter's minimum sample count.

Do not reapply the earlier investigation's approximately 40–50 ms timing offset as a universal correction. The current producer already incorporates a newer timestamp convention; remaining latency must be measured on the current frontend at each supported sample rate. Preserve provenance when comparing old and new results.

For a claim of meeting or exceeding Rekordbox, run matched audio and clearly recorded analysis modes against an untouched independently annotated DJ test set. Report tempo level, fine rate, phase, drift, bar phase, failures, coverage, and resource cost separately. Static binary similarities and a better development-set score cannot establish that claim.

## Bitwig's contribution and its boundary

Bitwig's inspected `RekordboxDbReader::getBeatGridFromANLZ` at `0x354070` reads stored beat-grid data from ANLZ `PQTZ` chunks, including endian conversion. The preserved REA record is `ev_5849d8251b67b3aa61466241567c9b14a535dc682ff08f354ce52322d93eaa0a`; see [research.md](research.md).

This is evidence about consuming existing analysis, useful for time conversion and data interoperability. It does not establish a Bitwig audio beat-detection algorithm or justify a threshold in BBBK. Treat imported grids as one output representation, not an implementation of the independent detector.

The secondary waveform goal remains compatible with this plan: compute new waveform objects from decoded audio, with explicit timeline/cadence, coverage, amplitude/band semantics, and schema identity. Beat inference and waveform production should share a verified PCM timeline while remaining separate outputs. Tuning a detector should not redefine waveform sample positions.

## Expected implementation handoff

### Incorporate the new Logic Pro evidence

REA/Hopper inspection of Logic Pro 12.4 found a native strategy that produces neural predictions, analyzes loop/constant/variable-tempo candidates, scores candidates, and selects a result subject to mode and hint handling. The shipped model has separate framewise beat, ordinary-beat, and downbeat sigmoid heads, plus tempo and beats-per-bar softmax heads. The native variable-tempo route uses a joint time-signature/beat HMM. See [the detailed Logic report and Evidence IDs](logic-pro-analysis-2026-10-19/README.md).

The common candidate scoring function calls measures of peak agreement, downbeat contrast, interval plausibility, smoothness, local consistency, stability, and unnecessary variability. Exact weights and their training provenance are unknown. This suggests a useful experiment for BBBK: learn a small ranker over coherent grid candidates, and compare it with a globally tuned fixed score, before attempting unrestricted prediction of many thresholds.

Keep a constant-tempo DJ-grid candidate alongside a variable-tempo candidate and half/double alternatives. Test whether the selector can retain the stable explanation when transients wander, yet select the variable explanation for a true tempo change. These are new experiment recommendations; the static findings do not establish Logic's runtime accuracy or prove that it learns detector thresholds dynamically.

If adding auxiliary tempo/meter heads to the BBBK observation model, verify benefit through independent ablations. The Logic graph's three sigmoid heads are not a categorical softmax and do not guarantee inclusive probability consistency. Keep the BBBK probability contract explicit. Do not use imported proprietary weights in the independent library.

### Stage deliverables

Deliver a focused decoder correction with regressions, an explicit evidence/reliability contract, and a documented migration for no-evidence candidates. Follow with a deterministic evaluation CLI and versioned configuration. Then deliver a reproducible global tuning experiment and, only if it earns its complexity, contextual adaptation.

For each stage provide the failure it fixes, exact source changes, tests run, per-track evaluation results, abstention changes, and remaining limitations. Preserve the untuned baseline and all search settings. The shipping library should analyze new tracks independently of Rekordbox or Logic; external analysis is development evidence and optional teaching data.
