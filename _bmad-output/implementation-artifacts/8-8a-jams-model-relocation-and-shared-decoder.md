---
baseline_commit: 3c7c796c12597a5396850f500512ddc87a6608e6
---

# Story 8.8a: Relocate + extend the shared JAMS model (decoder, tempo-encode guard, corpus loaders)

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **library maintainer consolidating on JAMS as the single canonical ground-truth annotation format**,
I want Story 8.7's JAMS model relocated into a shared, public home and extended with a strict `tempo`-encode path, a typed multi-artifact `sandbox`, and corpus-loader adapters on `OA300Track`/`DAWOracleTrack`,
so that Stories 8.8b (OA300 + DAW migration) and 8.8c (DnB regression-config migration) can flip the on-disk artifacts and call sites against one shared decoder — without each re-deriving JAMS plumbing.

## Context (shared across 8.8a/b/c)

Story 8.8 was split 3 ways (operator decision, 2026-06-20) after a Codex review flagged the combined unit as too large (~13 Swift + 5 Python consumer rewrites + a decoder relocation). **8.8a is the prerequisite infrastructure slice**; 8.8b and 8.8c are independent migrations that both depend on it.

The epic AC (`epics.md` §"Story 8.8", 2026-05-26) predates 8.7's JAMS work and understates the blast radius. Two operator rulings govern all three slices:

- *"Nothing is shipping, this is all new code… backwards compat is not a goal."* (2026-06-20)
- **DD-1:** Reverse 8.7 DD-7 (which kept the JAMS decoder benchmark-target-internal so MIR format never reached consumers). Relocate the JAMS model into `Sources/BoomBoomBoomKitTestSupport` and make the types `public`, giving all three test targets + the shipping corpus decoders one shared decoder. Justified solely by the pre-1.0/unshipped/no-BC ruling. [[feedback_no_bc_goal_prerelease]]
- **DD-2:** 8.8b/8.8c overwrite the flat artifacts **in place** (single canonical format, no sibling-`.jams.json` hedge). 8.8a itself migrates no artifact.

## Acceptance Criteria

1. **JAMS model relocated + public.** `Tests/BoomBoomBoomKitBenchmarkTests/Helpers/JAMSDecoder.swift` moves to `Sources/BoomBoomBoomKitTestSupport/JAMS/JAMSDecoder.swift`; all types/inits/accessors are `public`. The header comment records DD-1 (8.7 DD-7 reversed; now the shared corpus-annotation decoder). The 8.7 consumers (`BeatGridBenchmarkTests`, `JAMSDecoderTests`) import it from `BoomBoomBoomKitTestSupport` and their `beat` round-trip + conformance tests stay green.

2. **`tempo`-encode strictness guard added** (the deferral flagged in `JAMSDecoder.swift:132-138` as "the Story 8.8 follow-up"). Encoding a `tempo`-namespace observation requires a non-nil numeric `value` and `confidence ∈ [0, 1]`; a violation throws a new typed `JAMSEncodingError` (e.g. `.tempoValueMissing` / `.tempoConfidenceOutOfRange`) rather than emitting a schema-invalid entry. The `beat` emit path is unchanged.

3. **Typed multi-artifact `sandbox`.** `JAMSSandbox` keeps its existing `constantTempo` (the 8.7 beat corpus reads it — `JAMSDecoder.swift:265` — do not drop it) and gains typed optional fields covering all three artifacts: `genre`, `subdir` (oa300); `rekordboxBpm`, `rekordboxDisagrees`, `disagreementType` (daw); `partition`, `source`, `currentPredictedBpm`, `currentAbsError`, `rationale` (dnb). All `Optional`, all typed — **no `[String: Any]`** (project typed-payload convention). A corpus-level sandbox type carrying `schema_version` / `regression_threshold` / `captured_with` is threaded onto `JAMSCorpus` (`{entries, sandbox}`).

4. **Artifact-level validators.** Because the union makes cross-artifact-invalid payloads representable, the model exposes loud-failing accessors (e.g. `JAMSFile.oa300Genre() throws`, `JAMSFile.tempoBPM() throws`, `JAMSFile.dnbPartition() throws`) that throw on a missing required field rather than handing callers raw optionals. These are the seam 8.8b/8.8c consume.

5. **Corpus-loader adapters on the shipping decoders.** `OA300Track` and `DAWOracleTrack` (`CorpusTracks.swift`) gain `init(jamsFile: JAMSFile) throws` (bpm/dawBpm from the `tempo` observation; filename from `identifiers.basename`; subdir/genre/disagreement from `sandbox`) **and** public adapters `OA300Track.loadCorpus(from: Data) throws -> [OA300Track]` / `DAWOracleTrack.loadCorpus(from:)` (decode `JAMSCorpus`, map `entries`). The **non-empty-`genre` loud-fail contract** is preserved end-to-end: a JAMS entry whose `sandbox.genre` is absent/blank/whitespace throws `keyNotFound` / `dataCorrupted` exactly as the flat decoder did.

6. **No migration, no call-site flips.** 8.8a changes **zero** on-disk fixtures and **zero** existing consumer load sites (those are 8.8b/8.8c). `make build` + `make test` stay green; the existing flat fixtures still decode through the unchanged flat path until 8.8b/8.8c land. (This keeps 8.8a independently shippable.)

7. **Unit test proves the adapter seam.** A new test in `BoomBoomBoomKitTests` (or the relocated `JAMSDecoderTests`) hand-builds a synthetic `tempo` JAMS entry, decodes it through `OA300Track.init(jamsFile:)`, and asserts: bpm/genre/subdir/filename round-trip; the genre loud-fail (absent/blank/whitespace) throws; the `tempo`-encode guard rejects a nil/out-of-range `confidence`.

## Tasks / Subtasks

- [x] **Task 1 — Relocate the model (AC: 1).** `git mv` `JAMSDecoder.swift` → `Sources/BoomBoomBoomKitTestSupport/JAMS/`; make types `public`; update the header for DD-1; fix the two 8.7 import sites; confirm 8.7 `beat` tests green.
- [x] **Task 2 — Tempo-encode guard (AC: 2).** Add `JAMSEncodingError`; guard `tempo` in `JAMSObservation.encode`/`JAMSAnnotation.encode`; remove the "Story 8.8 follow-up" comment; add an encode-rejection test.
- [x] **Task 3 — Sandbox union + corpus sandbox (AC: 3).** Extend `JAMSSandbox` (keep `constantTempo`); add the corpus-level sandbox type; thread onto `JAMSCorpus`.
- [x] **Task 4 — Validators + adapters (AC: 4, 5).** Add the throwing artifact accessors; add `init(jamsFile:)` + `loadCorpus(from:)` to `OA300Track`/`DAWOracleTrack`, preserving the genre loud-fail.
- [x] **Task 5 — Seam test + gauntlet (AC: 6, 7).** Add the synthetic-entry adapter test; `make fmt`/`make lint`/`make build`/`make test` green; confirm no fixture or existing-call-site changes (`git diff` touches only `Sources/BoomBoomBoomKitTestSupport/`, `CorpusTracks.swift`, the relocated decoder, and the new test).

## Dev Notes

- **Per-track JAMS `tempo` shape** (used by 8.8b/8.8c): one observation `{time:0, duration:0, value:<bpm>, confidence:1.0}`. `JAMSValue.int` is a `beat`-phase accessor — irrelevant for tempo; read `value.number` for BPM. `file_metadata` must carry `duration` + `jams_version` for `jams.load` validity (the encoder already enforces this — `JAMSDecoder.swift:228`).
- **`genre` has no JAMS `file_metadata` slot** → `sandbox.genre` (typed). The non-empty contract (`CorpusTracksDecodingTests`, loud-fail on blank/whitespace) moves with it.
- **Decoder home:** all three test targets already depend on `BoomBoomBoomKitTestSupport`, so one public decoder there serves every consumer and lets 8.8c collapse its local mirror structs onto it.
- **Shipping note:** `BoomBoomBoomKitTestSupport` ships to main, so the relocated decoder ships — acceptable per the operator ruling; it adds no dependency (pure `Foundation` `Codable`).
- Commit: `Story 8-8a: <deliverable>`. [[feedback_commit_messages_focus_on_deliverables]] [[feedback_no_business_jargon_in_commits]]

### References

- 8.7 decoder + `tempo`/DD-7 forward refs: [Source: Tests/BoomBoomBoomKitBenchmarkTests/Helpers/JAMSDecoder.swift:34-265]
- Shipping corpus decoders + genre contract: [Source: Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:20-90], [Source: Tests/BoomBoomBoomKitTests/CorpusTracksDecodingTests.swift]
- Epic AC: [Source: _bmad-output/planning-artifacts/epics.md#Story 8.8 (lines 1172-1202)]
- Release discipline: [Source: CLAUDE.md §"Release Process"]
- Codex review (folded fixes P2/P4): thread 019ee3a2

## Dev Agent Record

### Agent Model Used

claude-opus-4-8 (spec authored + implemented)

### Debug Log References

### Completion Notes List

- **Task 1 (relocate):** `git mv` `JAMSDecoder.swift` → `Sources/BoomBoomBoomKitTestSupport/JAMS/`; all types/inits/accessors made `public`; header rewritten to record DD-1 (8.7 DD-7 reversed). `BeatGridBenchmarkTests` already imported `BoomBoomBoomKitTestSupport` (no change). `JAMSDecoderTests` gained the import + stale-DD-7 header fix. The empty `Tests/.../Helpers/` dir is harmless (SPM/git ignore empty dirs).
- **Task 2 (tempo guard):** added `JAMSEncodingError { tempoValueMissing, tempoConfidenceOutOfRange(Double?) }`; the guard lives in `JAMSAnnotation.encode` (the observation has no namespace knowledge) and fires only for `.tempo` — validates non-nil finite `value` + `confidence ∈ [0,1]` BEFORE the observation encoder writes a schema-invalid null. `beat` emit unchanged. "Story 8.8 follow-up" deferral comment removed.
- **Task 3 (sandbox):** `JAMSSandbox` kept `constantTempo` and gained 10 typed optional fields (genre/subdir/rekordbox*/partition/source/current*/rationale) — no `[String: Any]`. New `JAMSCorpusSandbox` (`schema_version`/`regression_threshold`/`captured_with`, with typed `JAMSRegressionThreshold` + `JAMSCapturedWith` sub-objects) threaded onto `JAMSCorpus` as an optional `sandbox`. `JAMSCorpus` round-trip identity preserved (synthesized encode omits nil sandbox via `encodeIfPresent`).
- **Task 4 (validators + adapters):** `JAMSFile.tempoBPM() throws` + `dnbPartition() throws` (+ `tempoAnnotation`); `JAMSValidationError { missingTempoObservation, missingDnBPartition }`. `OA300Track`/`DAWOracleTrack` gained `init(jamsFile:) throws` + `static loadCorpus(from:) throws` as same-file extensions (access the `private` CodingKeys). Genre loud-fail reproduced exactly: absent `sandbox.genre` → `DecodingError.keyNotFound("genre")`, blank/whitespace → `DecodingError.dataCorrupted` with `codingPath.last == "genre"`. The flat `init(from:)` paths are UNTOUCHED (AC 6 — no call-site flips; 8.8a is non-breaking and independently shippable).
- **Task 5 (gauntlet):** new `Tests/BoomBoomBoomKitTests/JAMSCorpusAdapterTests.swift` (9 tests) proves adapter decode, `loadCorpus`, genre loud-fail (do/catch parity with `CorpusTracksDecodingTests`), missing-tempo loud-fail, DAW adapter, and the tempo-encode guard (nil value + out-of-range confidence). Gauntlet: `make fmt` clean; `swift build` clean; `make test` 698 pass (+9 vs 8-7's 689); `swift test --filter BoomBoomBoomKitBenchmarkTests.JAMSDecoderTests` 7/7 pass (relocation + corpus-sandbox addition did not break the 8.7 round-trip identity); `make lint` 1 violation = canonical `LUFSAnalyzer` TODO baseline, py-lint clean (zero Python touched). `git diff` scope: relocated decoder + `CorpusTracks.swift` + `JAMSDecoderTests.swift` (import/header) + new adapter test — no fixture or existing-call-site changes (AC 6 ✓).

### File List

- `Sources/BoomBoomBoomKitTestSupport/JAMS/JAMSDecoder.swift` (relocated from `Tests/BoomBoomBoomKitBenchmarkTests/Helpers/`, made public + extended)
- `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift` (added `init(jamsFile:)` + `loadCorpus` adapters)
- `Tests/BoomBoomBoomKitBenchmarkTests/JAMSDecoderTests.swift` (import + stale-header fix)
- `Tests/BoomBoomBoomKitTests/JAMSCorpusAdapterTests.swift` (NEW — 9 seam tests)

## Change Log

- 2026-06-20 — Story 8.8a implemented: relocated the JAMS model to public `BoomBoomBoomKitTestSupport` (DD-1), added the `tempo`-encode guard + `JAMSEncodingError`, the typed sandbox union + corpus-level sandbox, artifact validators, and the `OA300Track`/`DAWOracleTrack` JAMS adapters. Flat decode paths untouched (non-breaking). 698 unit tests pass; 7/7 relocated 8.7 JAMS tests pass; lint/py-lint baseline-clean. Status → review.
