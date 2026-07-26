---
title: 'GH-167 item 5 — Fixture provenance + first real-audio CI floor (#154, #161, #160, #159)'
type: 'bugfix'
created: '2026-07-24'
status: 'done'
review_loop_iteration: 0
baseline_commit: 'b8255a1'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** CI asserts nothing about accuracy. `.github/workflows/ci.yml` runs `swift build`, `make test`, a format check, and SwiftLint; every accuracy floor (OA300 Acc1 ≥ 57, GiantSteps ≥ 537, beat-grid F, consistency rate) lives in the env-gated benchmark target CI never builds, so an Acc1 collapse from 58/82 to 40/82 merges green (#154). Octave correctness has no automated coverage anywhere: the one bundled-fixture tempo check (`BeatGridAnalyzerTests.recoversClickTrackTempo`) is octave-tolerant and its comment delegates octave correctness to those same unrun benchmarks (#161). Separately, the shipped fixtures carry no provenance manifest (#159) and the documented OGG/corruption contracts are untested (#160).

**Approach:** Add an octave-strict accuracy floor over bundled fixtures that runs in the ordinary `make test` lane with no corpus, using ground truth established independently of this library. Record the four tempos it currently gets wrong as `withKnownIssue` ratchets rather than loosening the assertion. Ship a provenance manifest, and close the untested negative paths.

## Boundaries & Constraints

**Always:**
- Ground truth comes from construction, the author, or human verification recorded in `FIXTURES.md` — **never** a value this library produced. Pinning analyzer output builds a change-detector that enshrines current errors.
- Known failures use `withKnownIssue` with default `isIntermittent: false`, so the suite fails when a defect is *fixed* and the wrapper must be removed.
- Unconditional invariants (finite BPM, within the 60–200 `rangeNormalize` output range, confidence finite and in [0, 1]) sit **outside** every wrapper, so a `NaN` or absurd value can never be absorbed as "known".
- The floor sets `metadataPolicy = .disabled` so it measures DSP, not file tags.
- Exactly one expectation inside each `withKnownIssue` closure — the default matcher accepts any issue.
- Every new guard is bite-proven by mutation, reverted from a scratchpad copy, never `git checkout`.

**Ask First:**
- Any change to an existing accuracy floor value or corpus gate.
- Adding a fixture beyond the OGG case, or exceeding the current fixture size footprint.
- Promoting anything new to public API.

**Never:**
- Behavioural `Sources/` changes. Documentation-only exception: correcting the false OGG-unsupported claim in `PCMBufferReader.swift` and `MetadataPolicy.swift` (amended 2026-07-25 — the original wording said "narrowing the claim" in one file, before measurement showed the claim was wrong rather than imprecise, and present in four places).
- Pinning the four wrong values (182 / 192 / 140 / 115.6) as expectations.
- Restoring octave tolerance to make an assertion pass.
- Claiming #159's licensing half or a non-fatal-truncation portion of #160 is closed when it isn't.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Fixture matches truth | Click track or correct-resolving MP3 | Within 2% of truth; suite green | N/A |
| Known octave failure | `Meta_Man` (92), `La_Noche` (96), `Submerged_Lament` (70) | Assertion fails, absorbed by `withKnownIssue`; run stays green | Diagnostic names the harmonic relation |
| Known failure gets fixed | Any wrapped case starts passing | `knownIssueNotRecorded` → **run fails**, nonzero exit | Message directs removal of the wrapper |
| Degenerate result | BPM `NaN`/∞/out of 60–200, or confidence outside [0,1] | Fails **outside** the wrapper — never absorbed | Unconditional invariant |
| OGG input | Valid Vorbis fixture | **Decodes successfully** — non-empty, finite, normalized samples at 44.1 kHz | N/A. Amended 2026-07-25 after measurement disproved the original "throws" premise; operator confirmed OGG support is wanted |
| Truncated MP3/FLAC | First N bytes of an existing fixture | Observed behaviour, measured then pinned | If non-fatal, assert that and leave the gap open |
| CAF input | `test-bwf.caf` | Non-empty normalized mono samples | N/A |

</frozen-after-approval>

## Code Map

- `Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift` -- new; the floor + ratchet. Already drafted, carries three defects to fix.
- `Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/FIXTURES.md` -- new; provenance + ground-truth table + authoring rules.
- `Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/robbyt_x-ray-{30s,120s}.mp3` -- new; owner-authored, `-map_metadata -1`.
- `Tests/BoomBoomBoomKitTests/PCMBufferReaderTests.swift` -- `PCMBufferReaderErrorTests` at :220 is the extension point; `fileDurationThrowsOnZeroSampleRate` is the byte-level precedent.
- `Tests/BoomBoomBoomKitTests/BeatGridAnalyzerTests.swift` -- `matchesWithinOctave` (:40) + `recoversClickTrackTempo` (:48); also used by other tests in the file.
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` -- `analyzeBPMWithMP3` (:18) carries the 40–220 band.
- `Sources/BoomBoomBoomKit/PCMBufferReader.swift` -- `PCMBufferReaderError` (:13); OGG claim at :17 (doc comment only).
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` -- `rangeNormalize` (:2107) bounds output to `perceptualMin/MaxBPM` 60/200. Read-only reference.

## Tasks & Acceptance

**Execution:**
- [x] `AccuracyFloorTests.swift` -- collapse the duplicate `Issue.record` + `#expect` into one `#expect(within, Comment(rawValue:))` -- 4 failures currently emit 8 known issues, and two issues per wrapper widen the default matcher
- [x] `AccuracyFloorTests.swift` -- set `options.metadataPolicy = .disabled` -- the floor claims to measure DSP but the default path enables `TBPM` corroboration
- [x] `AccuracyFloorTests.swift` -- add unconditional finite / 60–200 / confidence-bounds invariants outside the wrapper -- closes the hole where a `NaN` from a known-failing fixture is absorbed as "known"
- [x] `AccuracyFloorTests.swift` -- re-measure and record per-fixture error and headroom after the metadata change -- pre-change numbers describe a different analysis path
- [x] `AccuracyFloorTests.swift` -- add the missing `bpm-120-downbeat` case + a `cases.count == 12` denominator guard (Codex review) -- the manifest claimed a fixture the floor never ran, and an emptied `arguments` array would report green
- [x] `BeatGridAnalyzerTests.swift` -- make `recoversClickTrackTempo` octave-strict and add a median-adjacent-beat-interval check -- a scalar tempo can read 120 while beats sit at 60; guard ≥2 beats and positive/finite intervals
- [x] `PCMBufferReaderTests.swift` -- add OGG, truncated MP3/FLAC, and CAF cases -- three documented contracts with no test
- [x] `AudioFixtures/` -- add a small ffmpeg-generated Vorbis fixture -- pins the *measured* OGG behaviour
- [x] `AudioAnalysisServiceTests.swift` -- retire the 40–220 band, keep the decode smoke test -- superseded by the floor; cannot be tightened in place since its fixture is a known failure
- [x] `FIXTURES.md` -- finalize: provenance, verification methods, C2PA-is-not-a-licence, authoring rules
- [x] `PCMBufferReader.swift` + `MetadataPolicy.swift` + `CLAUDE.md` + `project-context.md` -- correct the OGG claim (4 sites) -- comment/doc text only
- [x] `deferred-work.md` -- item-5 section with re-open triggers

**Acceptance Criteria:**
- Given no corpus environment variables, when `make test` runs, then the accuracy floor executes and the run passes with exactly 4 known issues from this suite.
- Given a known-failing fixture whose defect is repaired, when the suite runs, then the process exits nonzero via `knownIssueNotRecorded`.
- Given any fixture returning a non-finite or out-of-range BPM, when the suite runs, then it fails outside the wrapper regardless of known-failure status.
- Given a clean `swift package clean` build, when the suite runs, then every new resource resolves through `AudioFixtures.url`.
- Given `make benchmark` on the local corpus, when compared to `b8255a1`, then denominators and floor values are unchanged.

## Spec Change Log

**2026-07-25 — Codex diff review (thread `019f97ec`).** Two merge-blockers and four nits, all valid, all applied.
- *Blocker:* `bpm-120-downbeat` appeared in FIXTURES.md's ground-truth table but not in the floor's case list, so a fixture the manifest claimed was covered never ran — the same measure-nothing shape item 4 existed to close. **Amended:** case added (passes, 0.00%) plus a `cases.count == 12` denominator guard, which also closes the empty-`arguments` silent-pass. **Avoided known-bad state:** a manifest that documents coverage the code does not provide.
- *Blocker:* the manifest asserted "No file here is commercial or third-party copyrighted material" while separately listing nine files as unconfirmed provenance. **Amended:** restructured into four separated categories (C2PA-attested / human knowledge / redistribution authority / unknown); blanket claim removed; **Open items** records the unestablished redistribution basis. **KEEP:** the rule that ground truth is never a value this library produced — it survived review and is the spec's load-bearing idea.
- *Nits applied:* `.disabled` described as "ENFORCES" no-tag when it only keeps tags out of the measurement; "all metadata stripped" false (`TSSE`/`Lavf` remains); a cited headroom table did not exist (now measured for all 12); no `truth.isFinite && truth > 0` guard.

**2026-07-25 — Codex plan review, same thread.** Eight changes to the remaining-work plan. Material ones: compare median-derived tempo to ground truth rather than to `estimatedTempo` (otherwise it adds no ground-truth coverage); HALT rather than silently add a fifth known issue; truncation is two cases (MP3 *and* FLAC) asserting safety properties if non-fatal; `Refs` not `Fixes` for partially-open issues; 925 is a pre-change baseline, not a target. Sharpest catch: the proposed SHA-256 assertion would have tripped before the rejection assertion during its own bite proof, validating the wrong guard.

**2026-07-25 — operator directive: simplicity over defensive layering.** The SHA-256 assertions proposed for the OGG and truncation fixtures were **dropped**. They added a maintained constant, a regeneration burden, and a bite-proof bypass, to guard against a fixture being swapped for garbage — where the only consequence is that the test proves "garbage is rejected" instead of "valid Ogg decodes". That is a provenance concern; `FIXTURES.md` records the digest and the `ffprobe` validation instead. Removing them also dissolved the bite-proof-interference problem entirely.

**2026-07-25 — measurement invalidated the OGG premise (HALT + operator decision).** The plan assumed OGG is undecodable and the test would assert rejection. Measured: `PCMBufferReader` decodes Vorbis-in-Ogg cleanly on macOS 26 (44,160 samples @ 44.1 kHz). The "OGG is NOT supported / no Core Audio codec" claim was false in **four** places, two of which ship to `main`. **Amended** after operator decision: correct all four sites to state what was verified, rename the fixture `unsupported-vorbis.ogg` → `vorbis-decodable.ogg`, and assert the actual decode. This is the honest closure of #160's format-support half — the documented contract was untested *and wrong*. Scope note: verified on macOS 26 only; the correction does not claim macOS 15.

## Design Notes

**Why a ratchet rather than a loosened assertion.** Four bundled fixtures are wrong today: three clean 2× octave doublings (all on slow tracks — 92, 96, 70) and one 2/3× triplet. The honest options were to loosen the tolerance until they pass, pin the wrong values, or record them. The first two destroy the floor's purpose. `withKnownIssue` keeps the assertion at full strength, keeps CI green, and — because it fails when the issue stops occurring — converts the debt into a signal that fires exactly when #141's octave work lands.

**These are repair ratchets, not regression ratchets.** A known failure can drift from 182 to 199 untripped. The unconditional invariants cap the blast radius; nothing pins the erroneous values, because doing so would enshrine them.

**Evidence for #141/#166.** On `Submerged_Lament` the correct answer was already in the candidate list and lost on score (70 at 0.97 vs 140 at 1.01) — a *selection* failure, not a generation failure, and in the **DSP** path rather than ML. `robbyt_x-ray` resolves correctly at 30 s (174.27, conf 0.92) but collapses to 115.64 (conf 0.66) at 120 s on identical audio, implicating content between 0:30 and 2:00.

**Tolerance.** 2% matches the project's Acc1 convention and cannot admit a harmonic error: 2× = 100%, ½× = 50%, ⅔× = 33⅓%, 3⁄2× = 50%.

## Verification

**Commands:**
- `swift package clean && make test` -- expected: passes with no corpus env; floor executes; 4 known issues from this suite; record total tests/suites against 924/160
- `make fmt && make lint` -- expected: clean, 6 pre-existing violations, 0 serious
- `make benchmark` -- expected: denominators and floor values unchanged vs `b8255a1`
- `swift test --filter AccuracyFloorTests` (repeat ×3 under `--parallel`) -- expected: deterministic; record peak runtime

**Bite proofs** (mutate, observe failure, revert from scratchpad copy, re-verify SHA-256):
- Change a passing fixture's truth -- expected: floor fails
- Set a known failure's truth to the DSP value -- expected: nonzero exit via `knownIssueNotRecorded`
- Force a non-finite/out-of-range BPM -- expected: fails **outside** the wrapper
- Feed `recoversClickTrackTempo` a 2× expected tempo -- expected: fails
- Perturb beat spacing leaving `estimatedTempo` correct -- expected: median-interval check fails
- Point the OGG test at a non-audio file -- expected: the decode assertion fails
- Use the untruncated file for the FLAC case -- expected: the expected-throw assertion fails

**Manual checks:**
- `git status --short` clean of stray artifacts after every mutation/revert cycle.
- CI runs macOS 26 only while the package supports macOS 15; state in the PR that negative codec assertions are verified on the CI platform only.

## Suggested Review Order

**The floor's design contract**

- Start here: why ground truth may never come from this library.
  [`AccuracyFloorTests.swift:28`](../../Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift#L28)

- The 12 cases; four carry a `knownFailure` reason string.
  [`AccuracyFloorTests.swift:88`](../../Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift#L88)

- Invariants deliberately OUTSIDE the wrapper — the NaN-concealment fix.
  [`AccuracyFloorTests.swift:170`](../../Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift#L170)

- One expectation per wrapper; the default matcher accepts any issue.
  [`AccuracyFloorTests.swift:205`](../../Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift#L205)

- Cardinality guard: an emptied `arguments` array would otherwise run zero cases.
  [`AccuracyFloorTests.swift:138`](../../Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift#L138)

**Octave coverage on the beat-grid path**

- Was octave-tolerant, deferring to benchmarks CI never runs; now strict.
  [`BeatGridAnalyzerTests.swift:64`](../../Tests/BoomBoomBoomKitTests/BeatGridAnalyzerTests.swift#L64)

- Median beat spacing vs truth — a scalar can read 120 while beats sit at 60.
  [`BeatGridAnalyzerTests.swift:101`](../../Tests/BoomBoomBoomKitTests/BeatGridAnalyzerTests.swift#L101)

**The corrected OGG claim (measurement disproved the documentation)**

- The claim that shipped to `main`, now stating what was verified.
  [`PCMBufferReader.swift:17`](../../Sources/BoomBoomBoomKit/PCMBufferReader.swift#L17)

- The test that pins the real behaviour.
  [`PCMBufferReaderTests.swift:290`](../../Tests/BoomBoomBoomKitTests/PCMBufferReaderTests.swift#L290)

- Second shipping site, scoped to tag-reading rather than decode support.
  [`MetadataPolicy.swift:16`](../../Sources/BoomBoomBoomKit/MetadataPolicy.swift#L16)

**Corruption behaviour, measured rather than assumed**

- The one genuinely fatal case; asserts the specific enum case and URL.
  [`PCMBufferReaderTests.swift:303`](../../Tests/BoomBoomBoomKitTests/PCMBufferReaderTests.swift#L303)

- Non-fatal: safety properties, non-empty checked first to avoid vacuous pass.
  [`PCMBufferReaderTests.swift:330`](../../Tests/BoomBoomBoomKitTests/PCMBufferReaderTests.swift#L330)

**Provenance and what stays open**

- Four separated categories; C2PA attests provenance, not licence.
  [`FIXTURES.md:7`](../../Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/FIXTURES.md#L7)

- Open items: the unestablished redistribution basis.
  [`FIXTURES.md:106`](../../Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/FIXTURES.md#L106)

**Peripherals**

- Superseded 40–220 plausibility band retired.
  [`AudioAnalysisServiceTests.swift:18`](../../Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift#L18)

- Seven ledger entries with re-open triggers.
  [`deferred-work.md`](./deferred-work.md)
