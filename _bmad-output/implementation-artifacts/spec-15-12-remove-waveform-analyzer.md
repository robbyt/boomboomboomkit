---
title: 'Story 15.12: remove the Story 15.4 waveform analyzer'
type: 'refactor'
created: '2026-10-28'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: 'dabddb498cecdac820a14ff0f6c9c6921d44c816'
context:
  - '{project-root}/_bmad-output/implementation-artifacts/15-11-waveform-band-levels.md (the replacement; its operator decision 2 sets 15.12)'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Story 15.4 left a second, unused waveform API in BBBK: `WaveformAnalyzer` and its option, result, error and record types. It landed on `develop` in #198, was never released to `main` or tagged, and no app that depends on BBBK uses it. Story 15.11's `BandWaveformReader` measures the waveform the downstream DJ app actually draws. Two waveform APIs make the library harder to read and keep alive code nobody calls.

**Decision (owner, 2026-10-28):** remove now. The 15.11 condition was "after the downstream app runs on the 15.11 reader, once a fresh check confirms nothing uses it". The fresh check found no consumer of any 15.4 symbol, and the app never used the analyzer, so removal cannot affect its migration; waiting for that migration is not required.

**Approach:** Delete the 15.4 analyzer, its records, its tests, its benchmark, its Makefile target and its perf baselines. Fix the few references that point at it. Leave every 15.11 `BandWaveform*` file and `FeatureSubstrate.DecodedAudio` unchanged.

## Boundaries & Constraints

**Always:** `make test`, `make lint`, `make docc-validate` and the release rehearsal stay green. Every `BandWaveform*` file, `WaveformBandFilter.swift`, their tests and their outputs are byte-for-byte unchanged, except the one comment in `WaveformBandFilter.swift` that names `WaveformAnalyzer`. History stays as it is: story specs, change logs, and `epics.md` keep their mentions of 15.4. No em dashes. No third-party or app names in `Sources/`, `Tests/`, commits or PR text.

**Never:** Change the behavior of any remaining API. Delete or rewrite the 15.4 story spec (only mark it superseded). Edit any other repository.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Symbols gone | `grep -rn -E "WaveformAnalyzer\|WaveformOptions\|WaveformAnalysisResult\|WaveformDetailEnvelope\|WaveformPeakOverview\|WaveformEnergyChannels\|WaveformRecordDecoding" Sources Tests Makefile README.md CLAUDE.md` | no output | N/A |
| Namespace gone | `public enum Waveform` in `Sources/` | absent; the demo app's own `Waveform` and the two test-local `enum Waveform` still compile | N/A |
| DocC link | `BeatGridAnalysisSpan.swift:37` | reworded without the removed symbol; `make docc-validate` passes | N/A |
| Test count | `make test` | baseline minus exactly the tests in `WaveformAnalyzerTests` and `WaveformRecordCodingTests` (53 `@Test` functions; count the run's reported cases before deleting), nothing else | N/A |

</frozen-after-approval>

## Code Map

All removal targets are under `Sources/BoomBoomBoomKit/FeatureSubstrate/Waveform/` unless noted.
- Delete: `Waveform.swift` (empty `public enum Waveform`), `WaveformAnalyzer.swift` (`WaveformAnalyzer`, `WaveformAnalysisResult`, `WaveformAnalyzerError`, private `BinLayout`, `PassProgress`, `BiquadCoefficients`), `WaveformOptions.swift`, `WaveformDetailEnvelope.swift`, `WaveformPeakOverview.swift`, `WaveformEnergyChannels.swift`, `WaveformRecordDecoding.swift` (used only by the files above).
- Keep: `BandWaveform.swift`, `BandWaveform+Serialization.swift`, `BandWaveformReader.swift`, `BandWaveformError.swift`, `WaveformBandFilter.swift` (none uses a 15.4 symbol; its header comment at `:7-9` names `WaveformAnalyzer` and is reworded).
- `Sources/BoomBoomBoomKit/BeatGridAnalysisSpan.swift:37` -- DocC link to ``WaveformDetailEnvelope/coveredSampleRange``; reword so the sentence stands without it.
- Tests: delete `Tests/BoomBoomBoomKitTests/WaveformAnalyzerTests.swift`, `WaveformRecordCodingTests.swift`, `Tests/BoomBoomBoomKitBenchmarkTests/WaveformAnalyzerPerfTests.swift` (no other test uses their helpers). Leave the test-local `enum Waveform` in `BeatGridTimingBaselineTests.swift:67` and `BeatGridFrameTimeConventionTests.swift:100`.
- `Makefile:352-358` -- the `waveform-perf-baseline` target and its help line.
- `_bmad-output/perf-baselines/waveform/` -- `README.md` plus 4 JSON baselines for the removed benchmark.
- `CLAUDE.md:238` -- the `BandWaveformReader` entry's closing clause that compares it with `WaveformAnalyzer`.
- `_bmad-output/implementation-artifacts/deferred-work.md` -- `:1265-1268` (roster lacks the 15.4 Waveform types and the 15.6/15.7 Framewise types): its Waveform half becomes moot, the Framewise half stays open; `:1546-1548` (DocC curation list) drops `WaveformAnalyzer`.
- `_bmad-output/implementation-artifacts/epic-15-context.md` -- live guidance for later Epic 15 stories: `:23` says 15.4 landed its first phase, `:50` says 15.9 reads 15.4 output when present, `:51` says 15.12 waits for the downstream app's migration. All three now contradict this story.
- `_bmad-output/implementation-artifacts/15-4-independent-waveform-data.md` -- status `review (Phase 1 of 3 landed)`; phases 15.4a and 15.4b never started.
- Untouched: `README.md`, `project-context.md`, the DocC catalog, `docs/`, `Package.swift`, `Demo/` (its own `Waveform` enum shadowed BBBK's; removing BBBK's ends the clash), every other repository.
- External consumers checked 2026-10-28 (none use a 15.4 symbol): the DJ app (pins `develop` `a8d5166`), its docs315 copy (`main` `468a7b3`), TheRealFatShady (`develop` `35c6bed`), mediadiff `MediaDiffCore` and `MetaMan` (`main`).

## Tasks & Acceptance

**Execution:**
- [x] Record the baseline `make test` count before the first edit.
- [x] Delete the seven source files and three test files listed in the Code Map.
- [x] `BeatGridAnalysisSpan.swift:37`, `WaveformBandFilter.swift:7-9`, `CLAUDE.md:238` -- reword without the removed names.
- [x] `Makefile` -- remove `waveform-perf-baseline`; delete `_bmad-output/perf-baselines/waveform/`.
- [x] `deferred-work.md` -- append to `:1265-1268` a note that the Waveform types were removed in 15.12, leaving only the Framewise half open; drop `WaveformAnalyzer` from `:1546-1548`.
- [x] `15-4-independent-waveform-data.md` -- status `superseded`, with one line: removed in Story 15.12, replaced by Story 15.11's `BandWaveformReader`; 15.4a and 15.4b withdrawn.
- [x] `epic-15-context.md` -- `:23`: 15.4's first phase was removed in 15.12 (replaced by 15.11); `:50`: drop 15.4 from the outputs 15.9 reads; `:51`: 15.12 removed the analyzer on 2026-10-28 after a check found no consumer, without waiting for the downstream app's migration.
- [x] `sprint-status.yaml` -- `15-12-remove-waveform-analyzer` follows this spec's status.

**Acceptance Criteria:**
- Given the matrix rows, when each check runs, then it gives the stated result.
- Given `uv run scripts/promote-to-main.py --from-ref dabddb4` and `--from-ref HEAD` after commit, then the "WOULD SHIP" count drops by exactly 10, and `git diff --name-status dabddb4 HEAD -- Sources Tests` lists exactly the 7 source and 3 test deletions plus modifications to `BeatGridAnalysisSpan.swift` and `WaveformBandFilter.swift`. `make release-rehearse RELEASE_REHEARSE_REF=HEAD` passes.
- Given `git diff --stat` against the baseline, then no `BandWaveform*` file, `WaveformBandFilter.swift` beyond its comment, or test of them appears.

## Verification

**Commands:**
- `make test` -- green; count equals baseline minus the two deleted suites' tests.
- `make fmt && make lint` -- no changes; only the pre-existing `PerformanceBenchmarkTests.swift:139` warning.
- `make docc-validate` -- pass.
- `swift build --target BoomBoomBoomKitBenchmarkTests` (or `swift build --build-tests`) -- the benchmark target still compiles.
- After commit: `make release-rehearse RELEASE_REHEARSE_REF=HEAD` -- passes.

## Review Triage Log

| # | Source | Finding | Verdict | Evidence | Route |
|---|--------|---------|---------|----------|-------|
| 1 | blind, edge, gap | `epic-15-context.md:39` "Waveform surface (15.4)" still reads as live design | low | The bullet describes the removed envelope, overview and stereo decode in present tense with no removal note; a later Epic 15 build loads this file instead of the epics file. | patch |
| 2 | blind, edge | The `epic-15-context.md` rewrite goes past the three named lines | false | The rewrite is the step-01 recompile the workflow requires when `epics.md` is newer than the cached file; only lines 23, 50 and 51 are this story's edits. | reject |
| 3 | blind, edge | The recompile dropped the per-pair label rule (`system-vs-system` vs `system-vs-reference`) | medium | `epics.md:2529` carries the rule; the recompiled Requirements bullet keeps only "never the reference", and a 15.9 build reads this file, not `epics.md`. | patch |
| 4 | blind, edge | The recompile dropped named anchors (`FittedTempoPhase`, W95/W98/W99, annotation path, `make matched-eval`) | low | Real loss, but the compile instructions target 800 to 1500 tokens and every name is still in `epics.md` and the story files; restoring them is new content, not a correction. | reject |
| 5 | blind | Header "Edit freely" contradicts regeneration | false | The header is the literal text the compile template prescribes (`compile-epic-context.md:20`). | reject |
| 6 | blind, edge, gap | Spec says `in-review`, sprint row says `in-progress` | false | Transient within the workflow: step 05 moves the sprint row with the spec. | reject |
| 7 | blind | Spec records no baseline count or verification results | low | Fix edits this build's spec; the counts (1303 to 1250, WOULD SHIP 309 to 299) are in the presentation. | reject |
| 8 | blind | The consumer check method is not recorded | low | Fix edits this build's spec. | reject |
| 9 | blind | `15-11-waveform-band-levels.md:16,37` still state the wait-for-migration condition | false | Intent: story specs keep their history; line 37 is inside that spec's frozen block; this spec records the waiver. | reject |
| 10 | blind | The 15.4 story body still says "deferred" and cites the removed make target | false | Intent: history stays; only the status line changes. | reject |
| 11 | blind | Deleting `perf-baselines/waveform/` leaves the 15.4 and 15.11 citations pointing at nothing | low | Real; a one-clause correction to the 15.4 superseded line naming `dabddb4` as where the files remain fixes it. | patch |
| 12 | blind | `epics.md` Phase 4 not marked amended | false | Intent: `epics.md` keeps its 15.4 mentions. | reject |
| 13 | blind | Demo build not verified | false | Nothing in `Demo/` names a removed symbol (gap layer searched it); a shadowed library name going away cannot break code that never named it. Demo build run anyway in verification. | reject |
| 14 | blind | Symbol grep omits `project-context.md`, DocC, `docs/`, `Demo/` | false | The gap layer searched all of them and found nothing; fix would edit this spec. | reject |
| 15 | blind | The frozen tag contains an em dash | false | Template text, and fix edits this spec. | reject |
| 16 | blind | No `update_history` line in `sprint-status.yaml` | false | Story status moves do not get history lines (15.11's move to done added none). | reject |
