You are working in:

/Users/rterhaar/Dropbox/research/swift/BoomBoomBoomKit

Your task is to preserve an existing rekordbox investigation, then use its findings to improve BoomBoomBoomKit.

## Goals and priorities

Primary goal: meet or exceed rekordbox’s BPM and beat-grid accuracy on DJ music.

Secondary goal: independently generate fresh waveform-analysis objects from audio. These objects should support waveform displays comparable to the information our RekordboxReader extracts, without requiring rekordbox, its database, or its analysis files.

This is a DJ-focused library. Prioritize:

- Electronic dance music, including house, techno, drum and bass, and syncopated/breakbeat material.
- Correct musical tempo level, including half/double-tempo decisions.
- Precise absolute beat-grid phase.
- Stable constant-tempo grids across long tracks.
- Reliable 4/4 bar starts.
- Correct alignment between generated waveforms, beats, and playback.

Accuracy takes priority over speed, but measure runtime and memory. Variable tempo and unusual meters are secondary.

Do not claim parity with rekordbox from implementation structure, output precision, synthetic tests, or agreement with rekordbox-generated labels alone. Parity requires a matched evaluation against independent annotations.

## 1. Preserve the research immediately

The artifacts currently exist under /private/tmp. Copy them into:

docs/rekordbox-analysis/

Do this before other work. The previous agent could read this repository but could not write here because its session’s writable workspace was elsewhere. Nothing has been copied into this repository yet.

Read CLAUDE.md and any applicable AGENTS.md first. Respect the repository’s develop/main publication rules: this research belongs in develop-side documentation, not the public release.

The inspected checkout was:

- Branch: rterhaar/12-7-eval-corpus-harness
- Tracked HEAD: 0f90ed8de52a9626cd47d3a263bed5af90a6c80e
- Untracked file: addendum-design.md

Inspect the current state before editing. Preserve the WIP branch and unrelated work. Do not reset, clean, rebase, or change the corpus protocol as a side effect.

Use this copy script, adjusting only the destination if the repository is located elsewhere:

from pathlib import Path
import hashlib
import json
import shutil

source = Path("/private/tmp")
destination = Path(
    "/Users/rterhaar/Dropbox/research/swift/BoomBoomBoomKit/"
    "docs/rekordbox-analysis"
)

files = {
    "rekordbox-dj-analysis-guidance.md": "FINDINGS.md",
    "rekordbox-bpm-analysis.hop": "artifacts/rekordbox-bpm-analysis.hop",
    "rekordbox-hopper-query.py": "scripts/rekordbox-hopper-query.py",
    "rekordbox-model-inspect.py": "scripts/rekordbox-model-inspect.py",
    "rekordbox-model-inspection.txt": "evidence/models/model-inspection.txt",
    "rekordbox-stft-graph.txt": "evidence/models/stft-graph.txt",
    "rekordbox-highprecision.asm": "evidence/native/rekordbox-highprecision.asm",
    "rekordbox-detect.asm": "evidence/native/rekordbox-detect.asm",
    "rb-analyze-focus.asm": "evidence/native/rb-analyze-focus.asm",
    "rb-observation-constructor.asm":
        "evidence/native/rb-observation-constructor.asm",
    "boomboom-timing-results.json": "evidence/timing/results.json",
    "boomboom-timing-swift.log": "evidence/timing/swift-test.log",
    "boomboom-timing-probe/ProbeTests/TimingProbeTests.swift":
        "evidence/timing/TimingProbeTests.swift",
    "boomboom-timing-probe/Package.swift":
        "evidence/timing/ProbePackage.swift",
}

for pattern in ("rb-beat-*.asm", "rb-focus-*.asm"):
    for path in sorted(source.glob(pattern)):
        files[path.name] = "evidence/native/" + path.name

hopper = source / "rekordbox-hopper-evidence"
if not hopper.is_dir():
    raise SystemExit(f"Missing required artifact directory: {hopper}")

for path in sorted(hopper.iterdir()):
    if path.is_file() and path.suffix in {".json", ".c"}:
        files[str(path.relative_to(source))] = "evidence/hopper/" + path.name

missing = [name for name in files if not (source / name).is_file()]
if missing:
    raise SystemExit("Missing artifacts:\n" + "\n".join(missing))

destination.mkdir(parents=True, exist_ok=True)

# Preserve the large local Hopper database without committing it to Git.
ignore = destination / ".gitignore"
ignore_line = "/artifacts/*.hop"
existing = ignore.read_text() if ignore.exists() else ""
if ignore_line not in existing.splitlines():
    ignore.write_text(
        existing
        + ("\n" if existing and not existing.endswith("\n") else "")
        + "# Local Hopper analysis databases; retain on disk.\n"
        + ignore_line
        + "\n"
    )

records = []
for source_name, destination_name in files.items():
    original = source / source_name
    copied = destination / destination_name
    copied.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(original, copied)

    digest = hashlib.sha256(copied.read_bytes()).hexdigest()
    original_digest = hashlib.sha256(original.read_bytes()).hexdigest()
    if digest != original_digest:
        raise SystemExit(f"Copy verification failed: {copied}")

    records.append({
        "path": destination_name,
        "source_path": str(original),
        "bytes": copied.stat().st_size,
        "sha256": digest,
    })

(destination / "manifest.json").write_text(
    json.dumps({"files": records}, indent=2) + "\n"
)
print(f"Copied and verified {len(records)} artifacts into {destination}")

The Hopper database is approximately 386 MB. Keep it locally, ignored by Git. Commit the reasonably sized reports, evidence, scripts, manifest, and handoff documentation according to repository conventions.

Do not copy the entire /private/tmp directory, Python environments, build caches, transport bootstrap files, or unrelated artifacts. Do not copy authentication tokens, the rekordbox executable, or proprietary model weights into the repository.

Create a README explaining the artifact layout. Fix or supplement the copied report’s /private/tmp links with relative links to the preserved artifacts. Retain original artifact bytes where practical; put interpretation in documentation.

Write a detailed AGENT_GUIDANCE.md incorporating these instructions and your implementation decisions. Add a link from docs/index.md.

Use local Git checkpoints for coherent changes, keeping research preservation, timing fixes, model experiments, and waveform generation reviewable separately. Do not publish or open PRs unless asked.

## 2. Understand what the investigation actually established

Read FINDINGS.md before implementation.

Inspected target:

/Applications/rekordbox 7/rekordbox.app/Contents/MacOS/rekordbox

Version: 7.2.19.0342, ARM64 slice of a universal Mach-O.

Executable SHA-256:

07dcecbaf304f777e435539c83c7dcc02e41de1eaf2e0a75e8a9852e4411a244

Verified findings:

- The high-precision path uses an existing legacy beat result.
- It calls learned beat/downbeat analysis.
- Neural outputs feed a bar-state Hidden Markov Model with Viterbi decoding.
- Results subsequently enter legacy v2 focus/grid refinement.
- Constant/dynamic-tempo mode affects that refinement.
- The final focus BPM accessor rounds to hundredths of a BPM. This establishes resolution, not accuracy.
- The two shipped beat models each have approximately 99,003 parameters:
  three bidirectional peephole-LSTM layers, 25 units per direction, followed by a three-class softmax.
- The model retains two output channels: ordinary beat and downbeat.
- Its frontend includes 1024/2048/4096-sample STFT paths with a 441-sample hop.
- The native decoder receives an explicit 100 fps parameter.

Useful native locations:

- Detect: 0x102327c80
- highPrecisionBeatAnalyze: 0x102327e50
- Learned analyze overload: 0x102307f8c
- downbeat_tracking: 0x102300d6c
- Observation likelihoods: 0x10231725c
- Legacy focus analysis: 0x10116c050
- Final focus BPM accessor: 0x1011820d4

Treat pseudocode as imperfect analysis output, not original source or an implementation specification. Hopper loses some ARM64 floating-point/SIMD details. In one dispatch condition, assembly preserves information that the pseudocode omits. Prefer instructions when exact conditions matter.

The precise legacy fitting objective, complete native resampling contract, model-selection details, and training data were not established. No matched runtime accuracy/speed benchmark against rekordbox was performed.

The architecture closely matches this published work:

https://archives.ismir.net/ismir2016/paper/000186.pdf

Public reference implementation:

https://github.com/CPJKU/madmom/blob/main/madmom/features/downbeats.py

Use published methods and independently implemented code/model choices. The shipped artifacts are research evidence; production BoomBoomBoomKit must analyze audio independently.

REA connection note: the completed Hopper database was saved successfully. REA’s macOS launcher rejected saved-database targets, so the investigation queried the installed REA Hopper adapter through Hopper’s supported Python console. The JSON records document that route and are not MCP Evidence envelopes. The copied query script contains paths to the previous environment; inspect and update them before reuse.

## 3. First implementation priority: absolute grid timing

A current-source Swift probe demonstrated a concrete discrepancy.

Across twelve synthetic fixtures:

- Sample rates: 44.1 and 48 kHz.
- Tempo: 120 BPM.
- Three offsets within an onset hop.
- Single impulses and short exponential-decay impulses.
- Twelve seconds of audio.

Both the public grid facade and a known-tempo frontend/tracker path produced playable gridOrigin anchors approximately 39.98–50.00 ms early.

The public path estimated approximately 120.00007 BPM and returned 24 beats per fixture. Supplying the exact tempo reproduced the phase discrepancy. It is therefore not explained by BPM estimation error.

Existing tests allow roughly 100 ms of constant phase offset. Other drift tests subtract constant offsets, so those tests do not establish tight absolute alignment.

Relevant sources at the inspected HEAD:

- BPMAnalyzer.swift around line 1181: unpadded, left-aligned STFT.
- BPMAnalyzer.swift around line 916: difference for frame i stored at envelope index i-1.
- BeatGridAnalyzer.swift around line 330: direct frame-to-time conversion.
- BeatGridAnalyzerTests.swift around line 846: permissive absolute-offset bound.

Required work:

1. Reproduce the measurement on the current branch.
2. Define the timing meaning of STFT frames, spectral differences, onset frames, and emitted beat timestamps.
3. Trace window centering, hop indexing, filtering, and window-start offsets.
4. Fix the convention or alignment method at the appropriate boundary.
5. Add permanent regression tests for absolute phase and the canonical gridOrigin.

Do not apply an unexplained universal +40 or +50 ms correction. The observed offset varies with waveform and sub-hop phase.

Expand tests to multiple BPMs, sample rates, hop phases, leading silence, and nonzero analysis-window offsets. Test both raw observations and the extrapolated playable grid.

Separate:

- Constant phase bias.
- Beat-to-beat jitter.
- Tempo/rate error.
- Long-track accumulated drift.
- Wrong metrical level.

Use synthetic signals with independent ground truth, then representative DJ kick and breakbeat excerpts. Synthetic impulse onset is an engineering reference, not a universal perceptual definition of musical beat placement.

Do not subtract codec priming twice. Establish a consistent decoded-PCM-relative timeline that agrees with playback.

## 4. Improve ML representation before another large retrain

BNNSTechnique currently resizes a varying-duration segment to 512 temporal frames. This changes seconds per frame with segment duration.

The underlying MLFeatureFrames retains fixed-hop frames; this resize is a model-input decision.

The recorded GiantSteps comparison was independently rescored from saved prediction files:

| Model | Strict hits / 661 | Octave-recoverable misses | Other misses |
|---|---:|---:|---:|
| Existing v2 model | 348 | 53 | 260 |
| Reference tempo-CNN | 545 | 100 | 16 |

The track-ID sets match. These are historical model predictions, not current inference, current combined-product accuracy, or a Rekordbox comparison.

This evidence makes representation/pulse detection a higher priority than additional octave heuristics.

Required experiments:

- Preserve a fixed seconds-per-frame relationship.
- Train on fixed-duration crops.
- Match training and inference preprocessing exactly.
- Evaluate multiple fixed-time crops at inference.
- Aggregate class probabilities or another explicitly defined sequence-level score.
- Compare against the legacy input contract and existing tempo-CNN baseline.
- Report results by DJ tempo band/style and error category.

A low-cost first ablation can retain the current architecture/input width while cropping a fixed number of source frames rather than stretching an arbitrary span. Evaluate whether its resulting duration provides enough context. Longer-context experiments may require a new input width or architecture; record that as a separate change.

Never alter runtime preprocessing for existing weights and assume accuracy will improve. Retrain or use weights trained for the new contract.

Version explicitly:

- Frontend and sample/frame rates.
- Window/padding convention.
- Feature definition and ordering.
- Normalization.
- Crop duration.
- Tensor shape.
- Output classes.
- Model identity.

Current BNNSTechnique’s supported feature version aliases the producer’s current constant. Merely bumping that constant does not independently establish what an old weights file was trained on.

Preserve the existing model path for comparison and rollback.

## 5. Add an independent beat/downbeat observation path

Prototype a compact framewise model plus structured 4/4 decoder.

Do not force temporal outputs into the current MLTechnique/MLEvaluation interface, which returns one scalar tempo evaluation.

Begin with a separate internal interface:

decoded audio span
→ timed beat/downbeat observations
→ structured decoder
→ candidate beat sequence
→ constant-tempo grid refinement

Observation data must include:

- Explicit frame timing and origin.
- Beat/downbeat channel semantics.
- Model identity.
- Frontend/input-contract identity.
- Valid coverage.

The decoder should compare plausible tempo/phase hypotheses and tolerate weak/missing evidence through breaks. Evaluate musical half/double-tempo alternatives before locking the final grid.

Keep the existing DSP path as a baseline/fallback. Evaluate the new path beside it before introducing fusion.

Avoid circular confidence:

- The existing grid is derived from the selected BPM.
- Its confidence is not independent confirmation of that BPM.
- SignalSource.beatGrid and its weight are currently placeholders, not an independent producer.
- Do not count the same learned evidence twice under different source names.

Keep inference optional and preserve the core library’s dependency and concurrency constraints. Do not bundle a model solely because it runs; benchmark it first.

## 6. Improve final constant-tempo grid fitting

The current optional comb refinement searches support over phase but returns only a refined tempo. Grid origin is selected from earlier detections.

Experiment with returning and evaluating a fitted tempo/phase pair.

For DJ material:

- Fit over a useful temporal span.
- Validate in separated stable regions.
- Preserve phase through breaks and weak passages.
- Compare low-frequency and broader spectral evidence on syncopated material.
- Use robust rejection of fills, missing kicks, and offbeat accents.
- Keep metrical-level choice separate from precise rate fitting.

Evaluate actual grid timestamps, not only a higher internal support score. A better score on the fitting objective does not guarantee a better musical grid.

Keep raw observations distinct from the final regular playable grid. Do not silently rewrite an existing public contract around raw beats.

## 7. Use the annotation work more effectively

Do not discard or redesign the current hand-annotation project.

The existing SOP already anchors a DAW grid at a stable downbeat and verifies at least 32 consecutive beats. Preserve supplementary information from that work where feasible:

- Original-audio timestamp of the reference downbeat.
- Verified BPM and declared metrical level.
- Bar position.
- Verified stable span.
- Distant alignment checks where available.
- Uncertainty or ambiguity.

The current DAW extractor primarily emits tempo. Investigate whether existing saved projects retain enough timing information to recover grid references; validate clip placement, warp coordinates, and offsets before trusting an automatic extraction.

Do not extrapolate beat labels across an entire track merely because one 32-beat span is verified.

Keep supplementary grid annotations separate from changes to frozen corpus membership or the signed protocol. Preserve blinding and training/evaluation separation.

## 8. Secondary goal: independently generated waveform objects

Implement waveform analysis from audio. It must work with rekordbox absent and must not read its database or ANLZ files.

The reader is a reference for useful information, not a dependency or required storage format.

Reference repository:

/Users/rterhaar/Dropbox/research/swift/rekordboxReader

Inspected reader HEAD:

041cda8da7c34d29a489438ce0822943db56b9fb

Inspect current code before relying on names:

- Sources/RekordboxReader/Analysis.swift
- Tests/RekordboxReaderTests/WaveformAndTimelineTests.swift

Observed reader capabilities:

- Monochrome height data.
- Detailed height plus RGB display data.
- Low/mid/high energy channels.
- Detailed waveform cadence of 150 columns/second.
- Overview reduction that preserves bucket maxima.
- Explicit timeline offsets.

Important distinction: PWV4 energy channels are not RGB and do not contain a height channel. Do not conflate frequency energy, display color, and waveform amplitude.

### Output contract

Add independent, typed, Sendable data objects describing:

- Source audio/analysis identity.
- Schema and algorithm version.
- Sample rate and channel policy.
- Covered frame range and actual duration.
- Explicit waveform-bin timing.
- Detail data.
- Overview data or a reduction/pyramid mechanism.

Provide compact bulk arrays suitable for drawing without allocating an object for every sample.

At minimum, expose:

- Amplitude envelope sufficient for a monochrome waveform.
- Peak-preserving overview.
- Low/mid/high spectral-energy information suitable for a three-band/color display.

Signed min/max and RMS are useful additions; define their semantics precisely if included.

Use a native floating-point analysis representation. Do not manufacture fake rekordbox chunk tags or prematurely quantize everything into its packed byte format.

Keep analysis data separate from rendering policy:

- Energy channels remain energy channels.
- Palette, gamma, display normalization, and contrast belong in documented presentation helpers or the host.
- Do not silently normalize each frequency band independently in a way that destroys their relative balance.
- Preserve an explicit full-scale/amplitude convention.
- Specify treatment of silence, clipping, and samples above nominal full scale.

The goal is comparable display capability, not byte-for-byte or pixel-identical rekordbox reproduction.

### Timing and resolution

Use 150 columns/second as the initial detail default for practical interoperability, configurable if useful.

Compute bin boundaries from sample positions using rational/integer-safe accounting. Do not accumulate rounded floating-point time steps or repeatedly round a hop size in a way that drifts.

Document whether each column represents an interval, its start, or its center. Store enough timing information to align it unambiguously with beats and playback.

Handle the final partial bin explicitly.

If spectral analysis uses a centered window or filter delay, account for that convention. Do not carry the demonstrated onset-timestamp discrepancy into waveform objects.

Support overview generation for a requested column count. Preserve narrow transients with peak/max aggregation. When reducing RMS or band powers, combine underlying energies with appropriate weights rather than averaging nonlinear display values.

### Decode and channel handling

Waveforms should cover the full requested track, independently of the BPM analyzer’s shorter analysis budget. Mark deliberately partial coverage explicitly.

Avoid reading a long stereo file into multiple full-size buffers. Prefer bounded-memory streaming, with shared decode infrastructure where practical.

Inspect the current decoder before promising a single shared pass: existing BPM options can limit decoded duration.

Do not derive stereo waveform amplitude solely from an averaged mono signal. Anti-phase channels can cancel. Define a channel-aware amplitude/energy policy and test it.

If the current DecodedAudio API contains mono samples only, document that limitation and add an appropriate URL/streaming path for channel-aware waveform generation. Do not silently pretend lost stereo information is recoverable.

Preserve cancellation and progress reporting. Avoid duplicate decode where the combined analysis path can share data, but do not make waveform generation depend on BPM succeeding.

### Waveform tests

Include meaningful tests for:

- Silence.
- Known-amplitude tones.
- Low-, mid-, and high-frequency tones.
- Frequency sweeps across band boundaries.
- Single-sample/narrow impulses.
- Unequal stereo channels and anti-phase stereo.
- Short files and final partial bins.
- Common sample rates.
- Correct duration and bin timestamps.
- Peak-preserving overview reduction.
- Correct energy aggregation.
- Finite outputs and bounded/defined normalization.
- Stable results across streaming block sizes.
- Cancellation and bounded memory.
- Alignment between waveform features, generated grid, and playback timeline.

Do not add a SwiftUI renderer or a dependency on RekordboxReader. A small adapter/example demonstrating how the host could map independent data into its rendering vocabulary is enough.

## 9. Evaluation required for the primary goal

Build a reproducible matched evaluation of:

- Existing BoomBoomBoomKit.
- Each proposed improvement.
- A named/versioned rekordbox analysis mode.
- Independent human/DAW references.

Use identical audio and comparable coverage.

Score separately:

1. Musical tempo level.
2. Strict tempo accuracy.
3. Fine BPM/rate error.
4. Absolute grid phase.
5. Beat precision/recall/F-measure.
6. Correct bar/downbeat phase.
7. Long-span drift.
8. Failures and abstentions.
9. Runtime and peak memory.

Report results by DJ style/tempo band and paired per-track differences. Distinguish average improvements from serious regressions. Use paired uncertainty estimates when claiming superiority.

Keep existing regression floors while establishing the new baseline. Do not weaken tests merely to make a change pass.

A 4% tempo classification hit is far too permissive to certify a long DJ grid. Add fine rate/phase measurements against verified references.

Rekordbox-generated grids are useful for measuring agreement and diagnosing differences. They are not independent truth. Adjudicate disagreements without automatically declaring either system correct.

Do not claim “meets or exceeds rekordbox” until the matched held-out evaluation supports the claim. State the corpus, modes, metrics, denominator, uncertainty, and limitations.

## 10. Working sequence and deliverables

Proceed in reviewable increments:

1. Preserve artifacts, hashes, documentation, and source provenance.
2. Reproduce the current absolute timing discrepancy and establish a baseline.
3. Implement and validate the timing correction/convention.
4. Add independent waveform data generation and tests.
5. Run fixed-time ML input experiments.
6. Prototype framewise observations and structured 4/4 decoding.
7. Evaluate joint tempo/phase refinement.
8. Integrate only changes supported by measured gains.
9. Run the matched rekordbox evaluation before making parity claims.

The waveform work can proceed independently of model training.

Deliver:

- Preserved research under docs/rekordbox-analysis.
- README, FINDINGS, AGENT_GUIDANCE, and hash manifest.
- Small, reviewable implementation changes.
- Permanent tests for demonstrated defects.
- Independent waveform-analysis objects and tests.
- Versioned model/frontend contracts for new experiments.
- Reproducible benchmark commands and reports.
- A clear account of improvements, regressions, and unresolved limitations.

Respect current source APIs, Swift strict concurrency, Accelerate/vDSP conventions, and existing project guidance. Keep unrelated WIP intact.

If data, weights, or annotations are insufficient to establish parity, complete the feasible implementation and measurement work, then identify the specific missing evidence. Do not substitute assumptions for a measured result.
