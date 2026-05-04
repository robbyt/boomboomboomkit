# Story 3.6: BPM Metadata Corroboration Signal

Status: done

## Story

As a DJ-tool developer consuming BoomBoomBoomKit,
I want embedded file-tag BPM metadata (iTunes `tmpo`, ID3 `TBPM`, Vorbis `BPM`) to corroborate the DSP estimate when present and trustworthy,
so that well-tagged library files converge faster and more accurately without sacrificing the library's DSP-first honesty on mistagged or untagged audio.

## Acceptance Criteria

1. **Given** a consumer importing `BoomBoomBoomKit`,
   **When** they inspect the public API,
   **Then** `MetadataPolicy` exists as a public `Sendable, Hashable` struct in `Sources/BoomBoomBoomKit/MetadataPolicy.swift`.
   **And** `MetadataSource` exists as a public `String, CaseIterable, Sendable, Hashable` enum with exactly three cases: `.iTunesTmpo`, `.id3TBPM`, `.vorbisBPM` (raw values matching the case names).
   **And** `MetadataPolicy` exposes at least two named presets: `.default` and `.disabled`.
   **And** `MetadataPolicy.default.valueRange == 30.0...300.0`.
   **And** `MetadataPolicy.default.enabledSources == [.iTunesTmpo, .id3TBPM, .vorbisBPM]` (all three).
   **And** `MetadataPolicy.disabled.enabledSources.isEmpty`.

2. **Given** `AudioAnalysisService.Options`,
   **When** a consumer creates a default `Options` instance via `Options()`,
   **Then** `options.metadataPolicy == .default` (metadata corroboration is ON by default).
   **And** setting `options.metadataPolicy = .disabled` disables all metadata I/O and all merge-stage boosting.
   **And** the existing `Options.init()` empty-initializer pattern is preserved (no required parameters added).

3. **Given** `AudioAnalysisResult`,
   **When** `analyzeBPM` returns a non-nil result,
   **Then** the result exposes a public `metadataEvidence: [MetadataBPMEvidence]` array (empty when policy is `.disabled` or no tags found).
   **And** `MetadataBPMEvidence` is a public `Sendable` struct with exactly these fields: `source: MetadataSource`, `rawValue: String`, `parsedBPM: Double`, `corroboratedWith: Double?`, `ratioMatched: HarmonicRatio?`, `boostApplied: Double`, `rejectionReason: String?`.
   **And** when `metadataPolicy = .disabled`, `result.metadataEvidence.isEmpty == true`.

4. **Given** `metadataPolicy = .disabled`,
   **When** `analyzeBPM` runs against any fixture,
   **Then** `FileMetadataReader` is NOT invoked (zero file-metadata I/O beyond the existing PCM read).
   **And** the returned `bpm` and `confidence` fields are equal to the pre-Story-3.6 pipeline output by `Double.bitPattern` on the same input.
   **And** the returned `candidates` array equals the pre-Story-3.6 array element-wise: `count` equal, each element's `bpm` matches by `Double.bitPattern`, each `score` matches by `Float.bitPattern`. (Whole-`AudioAnalysisResult` byte-identity is NOT claimed because the new `metadataEvidence` field changes struct layout — the contract is value-level field equality on the pre-existing fields, which is what regression testing actually depends on.)
   **And** OA300 and GiantSteps benchmarks run with `metadataPolicy = .disabled` produce Acc1/Acc2 integer counts equal to the Task 0 baselines exactly.

5. **Given** an M4A file containing a valid `moov/udta/meta/ilst/tmpo` atom (e.g., the OA300 fixture `03 TVR.m4a` under the `Bad BPM/` subfolder),
   **When** `FileMetadataReader.readTags(from:policy:)` is invoked with `.default`,
   **Then** the `tmpo` int16 is parsed by walking the MP4 atom tree directly (NOT via `AVAsset.commonMetadata` or `AVMetadataItem`).
   **And** the returned evidence contains an entry with `source == .iTunesTmpo` and `parsedBPM` equal to the atom's 16-bit big-endian integer value as `Double`.
   **And** a `tmpo` value of `0` is recorded with `parsedBPM == .nan`, `rejectionReason == "sentinel-zero"`, `boostApplied == 1.0` — evidence IS emitted so the trace can show the read happened (this is the iTunes sentinel for "no BPM data"; Codex review 2026-04-30 picked the emit-with-rejection contract for traceability over the silent-skip contract).
   **And** `parsedBPM` outside `valueRange` (30.0...300.0) is rejected with `rejectionReason == "out-of-range"` (evidence still emitted, `corroboratedWith == nil`).

6. **Given** an MP3 file with an ID3v2 `TBPM` text frame,
   **When** `FileMetadataReader` reads the file,
   **Then** the ID3v2 header is located at the file's leading bytes (`ID3` magic, version, flags, synchsafe size at offsets 0-9) and the `TBPM` text frame is located by walking the tag body.
   **And** ID3v2.3 and ID3v2.4 are both supported. ID3v2.2 is NOT supported (3-byte frame IDs differ; `TBPM` is not a v2.2 frame). ID3v1 is NOT supported. Tags with the unsynchronisation flag set in the tag header are rejected (returned as zero tags, not crashed) — full de-unsynchronisation is out of scope for this story.
   **And** if an extended header is present (header flag bit 6), it is skipped (read its synchsafe-or-regular size, advance past it). The v2.4 footer (header flag bit 4), if present, is ignored.
   **And** the frame's text encoding byte is honored (ISO-8859-1 = 0x00, UTF-16 = 0x01, UTF-16BE = 0x02, UTF-8 = 0x03).
   **And** synchsafe integer size fields (ID3v2.4 frame sizes; v2.3 frame sizes are regular 32-bit big-endian) are decoded correctly per the version byte (each byte contributes 7 bits in synchsafe).
   **And** two or more `TBPM` frames with conflicting parsed values in the same file are treated as an intra-file conflict and rejected per AC-10.

6a. **Given** an AIFF or AIFF-C file with an embedded `ID3 ` chunk containing an ID3v2 `TBPM` text frame,
   **When** `FileMetadataReader` reads the file,
   **Then** the file is parsed as an IFF FORM container — read the leading `FORM` magic + 4-byte big-endian size + 4-byte FORM type (`AIFF` or `AIFC`), then walk child chunks (`[4-byte ASCII id][4-byte big-endian size][payload]`, payloads padded to even length) until a chunk with id `"ID3 "` (note trailing space) is found.
   **And** the `ID3 ` chunk's payload is then parsed as an embedded ID3v2 tag using the same v2.3/v2.4 path as MP3 (AC #6) — synchsafe sizes, frame walking, encoding byte, intra-file-conflict detection, all identical.
   **And** if no `ID3 ` chunk is found, the AIFF returns zero tags (this is the common case — most AIFFs have no ID3 metadata).

7. **Given** a FLAC file with a Vorbis comment block containing one or more `BPM=` entries (case-insensitive key match),
   **When** `FileMetadataReader` reads the file,
   **Then** the Vorbis comment block is parsed directly from the FLAC metadata-block sequence (block type 4, little-endian lengths).
   **And** ALL `BPM=` entries are returned (the Vorbis spec permits repeated keys). When two or more entries have conflicting parsed values, they participate in intra-file-conflict detection (AC #10) the same way duplicate ID3 `TBPM` frames do — all rejected with `rejectionReason == "intra-file-conflict"`.
   **And** each returned evidence entry has `source == .vorbisBPM`.
   **And** the implementation does NOT route through AVFoundation for FLAC metadata (AVFoundation surfacing of Vorbis comments on macOS is historically inconsistent — direct parsing is required for determinism).

8. **Given** any raw tag string,
   **When** parsing runs under `MetadataPolicy.default.parsing`,
   **Then** leading/trailing whitespace and a UTF-8/UTF-16 BOM are stripped before numeric parsing.
   **And** a locale decimal comma is accepted (`"128,5"` parses to `128.5`).
   **And** a range midpoint is accepted (`"120-125"` parses to `122.5`).
   **And** a non-numeric residue (e.g., `"fast"`, `"?"`, empty string after trimming) is rejected with `rejectionReason == "non-numeric"`.
   **And** a parsed value outside `valueRange` is rejected with `rejectionReason == "out-of-range"`.
   **And** `tmpo == 0` is rejected with `rejectionReason == "sentinel-zero"`.

9. **Given** a file where two or more enabled `MetadataSource` entries are present AND their parsed values agree within **±0.5 BPM absolute**,
   **When** consensus is computed,
   **Then** the tags are treated as "unanimous consensus".
   **And** the consensus value is the arithmetic mean of the agreeing tags' `parsedBPM`.
   **And** all participating evidence entries share the same `corroboratedWith`/`boostApplied` outcome derived from the consensus value.

10. **Given** a file where two or more enabled `MetadataSource` entries are present AND at least one pair disagrees by more than ±0.5 BPM absolute,
    **When** consensus is computed,
    **Then** ALL valid parsed tags participating in consensus are rejected for decision purposes (no boost applied, no penalty). Parse-phase rejections (`sentinel-zero`, `out-of-range`, `non-numeric`) keep their original `rejectionReason` and are NOT retroactively relabeled.
    **And** each rejected consensus participant is recorded in `metadataEvidence` with `rejectionReason == "intra-file-conflict"` and `boostApplied == 1.0`.
    **And** the trace captures the disagreeing raw values and parsed values.
    **And** this is an all-or-nothing rule: for any N ≥ 2 tags, any single pairwise disagreement rejects the entire consensus set. There is no majority-rules carve-out — three tags with values `(128, 128, 174)` rejects all three, NOT a 2-of-3 consensus of 128. See Dev Notes "Why all-or-nothing for intra-file conflict" for rationale and future-work pointer.

11. **Given** a tag (single source OR unanimous consensus) with parsed BPM `T`,
    **When** any DSP candidate `C` in the post-merge candidate pool satisfies `abs(C - T) / T <= 0.03`,
    **Then** the tag is considered "corroborated at same-tempo".
    **And** EVERY matching candidate (not just the current winner) has its score multiplied by `policy.corroborationBoost` (default 1.25), then the winner is re-selected from the boosted candidate pool. This means metadata can promote a previously-lower-ranked candidate to be the chosen BPM.
    **And** the evidence entry has `corroboratedWith == winnerC`, `ratioMatched == nil` where `winnerC` is the post-promotion winner.
    **And** the final `result.confidence` is `min(policy.maxBoostedConfidence, prevConfidence * policy.corroborationBoost)` if `prevConfidence.isFinite && prevConfidence > 0`, else unchanged from `prevConfidence`. (Divide-by-zero / NaN guard per Codex review 2026-04-30.)

12. **Given** a tag with parsed BPM `T` that does NOT match any DSP candidate at same-tempo,
    **When** the existing `resolveOctaveAmbiguity` path (2:1 within 1.92-2.08 ratio) OR the Story 3.1 harmonic-ratio path (3:2 within 1.45-1.55, 3:1 within 2.85-3.15) would resolve `T` and some DSP candidate `C` to the same underlying tempo,
    **Then** the tag is considered "corroborated at ratio".
    **And** `ratioMatched` is populated with the matched `HarmonicRatio` enum value, `corroboratedWith == C`.
    **And** the 3:2 and 3:1 metadata-promotion paths are gated by `MetadataPolicy.allowTripletCorroboration: Bool = false` (default off). Story 3.1 has shipped 3:2 / 3:1 *detection* (`BPMAnalyzer.resolveOctaveAmbiguity` at `BPMAnalyzer.swift:1622-1636`) but only as trace-evidence — the detected pair does NOT modify the chosen winner. Story 3.6 introduces the first *winner-promotion* via 3:2 / 3:1 (driven by metadata corroboration), which is why the gate is opt-in until validated by a future story.

13. **Given** a corroborated tag (single-source or unanimous, same-tempo or ratio-matched),
    **When** `MetadataCorroborator.apply(to:input:policy:)` runs (called from `AudioAnalysisService.analyzeBPM` AFTER `CandidateMergeStrategy.merge` returns),
    **Then** the corroborated candidate's confidence is multiplied by `1.25` and clamped to `0.95` (never reaches `1.0` by construction).
    **And** `boostApplied` in the evidence records the effective multiplier (the clamped ratio, not the raw 1.25). When `prevConfidence` is non-finite or non-positive, `boostApplied == 1.0` (defensiveness gate).
    **And** the boost is applied inside `MetadataCorroborator.apply` (post-merge, cross-window) — NOT inside `CandidateMergeStrategy.merge` (which keeps its current `BPMResult?` signature unchanged to preserve the 41 existing call sites in tests and benchmarks) and NOT inside `BPMAnalyzer.resolveOctaveAmbiguity` (step 10 per-window). The corroborator runs uniformly for single-window and multi-window paths because it is invoked unconditionally by `analyzeBPM`, so AC #16's "fastest intensity still populates evidence" holds without special-casing the `windowResults.count == 1` short-circuit inside `merge`.

14. **Given** a unanimous-consensus tag set that does NOT corroborate any DSP candidate (neither same-tempo nor any enabled ratio),
    **When** `analyzeBPM` returns,
    **Then** the DSP-chosen BPM is returned unchanged (the tag value does NOT override DSP).
    **And** the winning candidate's confidence is multiplied by `0.85` (skepticism penalty applied in `MetadataCorroborator.apply`, post-merge). Same divide-by-zero guard as AC #13 — when `prevConfidence` is non-finite or non-positive, `boostApplied == 1.0` and confidence is unchanged.
    **And** each participating evidence entry has `rejectionReason == "dsp-disagreement"`, `corroboratedWith == nil`, `boostApplied == 0.85`.

15. **Given** a single tag (one source only) that does NOT corroborate any DSP candidate,
    **When** `analyzeBPM` returns,
    **Then** the tag is ignored for decision purposes (no boost, no penalty — confidence unchanged).
    **And** the evidence entry is recorded with `rejectionReason == "uncorroborated-single-tag"`, `boostApplied == 1.0`.

16. **Given** `options.intensity = .fastest` (intensity 1),
    **When** `analyzeBPM` runs on a file with a valid `tmpo` atom,
    **Then** `FileMetadataReader` is still invoked and evidence is populated.
    **And** metadata reading is NOT gated by `AnalysisIntensity` or `DSPTechnique` — only by `Options.metadataPolicy`.

17. **Given** the `DSPTechnique` enum and `TechniqueSet` API,
    **When** this story lands,
    **Then** `DSPTechnique.allCases.count == 7` (unchanged — Story 3.3 already added `clickTrackCorrelation`).
    **And** `TechniqueSet.allDSPCombinations().count == 128` (2^7 — regression guard).
    **And** no new case is added to `DSPTechnique` for metadata.

18. **Given** `enableTrace: true` and a file producing metadata evidence,
    **When** `analyzeBPM` returns,
    **Then** `BPMDiagnosticTrace` includes new fields: `metadataEvidenceBeforeBoost: [MetadataBPMEvidence]`, `candidatesBeforeBoost: [(bpm: Double, score: Float)]`, `candidatesAfterBoost: [(bpm: Double, score: Float)]`, `metadataPolicyUsed: MetadataPolicy`.
    **And** the trace distinguishes six rejection states across two phases: decision-phase — `"intra-file-conflict"`, `"dsp-disagreement"`, `"uncorroborated-single-tag"`; parse-phase — `"sentinel-zero"`, `"out-of-range"`, `"non-numeric"`.

19. **Given** the OA300 benchmark run under `make benchmark` with `metadataPolicy = .default`,
    **When** Story 3.6 lands,
    **Then** Acc1 does not regress below the pre-story baseline number captured in Task 0.
    **And** Acc2 does not regress below the pre-story baseline.
    **And** the benchmark report prints a "Tagged-subset breakdown" section: count of OA300 tracks where metadata was read, where metadata corroborated the DSP winner, where tags were rejected intra-file, and where unanimous tags disagreed with DSP.

20. **Given** the OA300 fixture `03 TVR.m4a` in the `Bad BPM/` subfolder,
    **When** `MetadataCorroborationTests.testTVRFixtureHasTmpoAtom()` runs with `metadataPolicy = .default`,
    **Then** an explicit test asserts: the `tmpo` atom is read, `MetadataBPMEvidence` is emitted with `source == .iTunesTmpo`, the parsed value matches the documented ground-truth atom value, and the corroboration/rejection outcome against this specific (known-bad-BPM) file is asserted explicitly (captured in a comment as documented ground truth).

21. **Standard gating (all Epic 3 stories):**
    - `make fmt` + `make lint` pass before and after (existing pre-existing warnings acceptable).
    - `make test` — all existing + new tests pass.
    - `make benchmark` — OA300 Acc1/Acc2 integer counts do NOT regress below the pre-story baseline captured in Task 0.
    - `make benchmark-giantsteps` — GiantSteps Acc1/Acc2 do NOT regress below the pre-story baseline.
    - `make ablation` — full 2^7=128 technique matrix completes without crashes. Count assertion guards against accidental matrix growth.
    - `make perf-benchmark` — wall-clock mean/median/p95 do not regress by more than 10% (metadata read adds ~1-5 ms per file; aggregate drift should be well under this threshold).
    - Update inline `///` doc comments on every modified public API (`AudioAnalysisResult`, `AudioAnalysisService.Options`, new types).
    - Update CLAUDE.md "Key Types" section to reflect `MetadataPolicy`, `MetadataSource`, `MetadataBPMEvidence`, `HarmonicRatio`, and the new `AudioAnalysisResult.metadataEvidence` field.

## Tasks / Subtasks

**Execution order: 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8. Task 0 is pre-story baseline capture. Tasks 1-2 are public-API types. Task 3 is the reader. Tasks 4-5 wire it through the service and merge strategy. Task 6 is trace. Task 7 is tests. Task 8 is validation and benchmark breakdown.**

- [x] **Task 0: Capture pre-story baselines + tolerance sweep** (AC: #19, #21)
  - [x] 0.1 Run `make benchmark` on HEAD before any Story 3.6 changes. Record the exact Acc1/Acc2 integer counts (e.g., `Acc1=57/82, Acc2=72/82`) in Completion Notes under "Pre-story OA300 baseline".
  - [x] 0.2 Run `make benchmark-giantsteps` on HEAD. Record Acc1/Acc2 integer counts in Completion Notes under "Pre-story GiantSteps baseline".
  - [x] 0.3 Run `make perf-benchmark` on HEAD. Record mean/median/p95 wall-clock in Completion Notes under "Pre-story perf baseline".
  - [x] 0.4 Document the exact git SHA these baselines were captured against. The regression gates in Task 8 compare integer counts against these numbers.
  - [x] 0.5 **Corroboration tolerance sweep (Codex finding M14):** AFTER Task 5 (corroborator) is implemented, run a one-time experimental benchmark with `corroborationTolerance` swept across `[0.01, 0.02, 0.03]` on the OA300 tagged subset. For each value, record the tagged-subset breakdown counts (corroborated-same-tempo / corroborated-octave / dsp-disagreement / uncorroborated). The default of `0.03` is loose: at 200 BPM it blesses ±6 BPM as "the same tempo." Document in Completion Notes which value gives the best Acc1 lift on the tagged subset. The shipped default stays at `0.03` (matches duration-hint precedent and avoids over-tightening before we've seen the data) UNLESS the sweep shows `0.02` is materially better, in which case file a follow-up micro-story to flip the default. The sweep itself is observability — not a gate — but the data informs whether `0.03` is right.

- [x] **Task 1: Create public types** (AC: #1, #3, #12)
  - [x] 1.1 Create `Sources/BoomBoomBoomKit/MetadataPolicy.swift` with the standard six-line header.
  - [x] 1.2 Declare `public enum MetadataSource: String, CaseIterable, Sendable, Hashable` with cases `.iTunesTmpo`, `.id3TBPM`, `.vorbisBPM`. Raw values match case names.
  - [x] 1.3 Declare `public enum HarmonicRatio: Sendable, Hashable` with cases `.one`, `.double`, `.half`, `.threeHalf`, `.twoThird`. Story 3.1 noted that the public type would be defined here when 3.6 ships (Story 3.1 spec, line 10). Document that `.threeHalf` / `.twoThird` are detected by `BPMAnalyzer.resolveOctaveAmbiguity` today as trace-only evidence; metadata-driven winner-promotion via these ratios is opt-in via `MetadataPolicy.allowTripletCorroboration == true` (default `false`).
  - [x] 1.4 Declare `public struct MetadataPolicy: Sendable, Hashable` with fields: `enabledSources: Set<MetadataSource>`, `consensusTolerance: Double` (default `0.5` BPM absolute), `corroborationTolerance: Double` (default `0.03` relative), `corroborationBoost: Double` (default `1.25`), `maxBoostedConfidence: Double` (default `0.95`), `skepticismPenalty: Double` (default `0.85`), `allowOctaveCorroboration: Bool` (default `true`), `allowTripletCorroboration: Bool` (default `false`), `valueRange: ClosedRange<Double>` (default `30.0...300.0`), `parsing: ParsingOptions`.
  - [x] 1.5 Declare nested `public struct ParsingOptions: Sendable, Hashable` with fields (all default `true`): `stripWhitespaceAndBOM`, `acceptLocaleDecimalComma`, `acceptRangeMidpoint`, `treatZeroAsAbsent`, `rejectNonNumeric`.
  - [x] 1.6 Declare presets: `public static let `default`: MetadataPolicy` (all three sources enabled, defaults as above) and `public static let disabled: MetadataPolicy` (empty `enabledSources`, all other fields at their natural defaults — `disabled` is an explicit no-op marker, NOT nil; the empty `enabledSources` set fully suppresses both file I/O and the merge-stage boost without needing the booleans flipped).
  - [x] 1.7 Declare `public struct MetadataBPMEvidence: Sendable` in the same file with fields per AC #3. Add `///` doc comments on every field.

- [x] **Task 2: Wire the policy into AudioAnalysisService.Options and AudioAnalysisResult** (AC: #2, #3, #4, #16)
  - [x] 2.1 Add `public var metadataPolicy: MetadataPolicy = .default` to `AudioAnalysisService.Options`. Preserve the empty `public init() {}` pattern — users mutate `opts.metadataPolicy = .disabled` to opt out.
  - [x] 2.2 Add `public let metadataEvidence: [MetadataBPMEvidence]` to `AudioAnalysisResult`. Initialize to `[]` in the default no-metadata path so existing call sites compile cleanly.
  - [x] 2.3 Update the `AudioAnalysisResult` initializer invocation inside `AudioAnalysisService.analyzeBPM` to pass `metadataEvidence: evidence` (empty array when policy is `.disabled`).
  - [x] 2.4 Add inline `///` doc on `Options.metadataPolicy` explaining default-on behavior and the `.disabled` opt-out. Add inline `///` doc on `AudioAnalysisResult.metadataEvidence` explaining emptiness conditions.

- [x] **Task 3: Implement FileMetadataReader with direct container parsing** (AC: #5, #6, #7, #8)
  - [x] 3.1 Create `Sources/BoomBoomBoomKit/FileMetadataReader.swift`, standard header. Declare `internal enum FileMetadataReader` (caseless namespace, same pattern as `MelFilterbank`).
  - [x] 3.2 Declare an internal `FoundTag: Sendable` struct with `source: MetadataSource`, `rawString: String`, `parsedBPM: Double`, `rejectionReason: String?`.
  - [x] 3.3 Implement `static func readTags(from url: URL, policy: MetadataPolicy) -> [FoundTag]` — dispatches on the file's extension (`.mp4`/`.m4a` → `readITunesTmpo`; `.mp3` → `readID3TBPMFromMP3`; `.aiff`/`.aif`/`.aifc` → `readID3TBPMFromAIFF`; `.flac` → `readVorbisBPM` returning `[FoundTag]`). Returns `[]` for unsupported extensions (`.wav`, `.caf`). Never throws — metadata absence is not an error.
  - [x] 3.4 Implement `private static func readITunesTmpo(from url: URL) -> FoundTag?` — opens the file with `FileHandle(forReadingFrom: url)`, **immediately followed by `defer { try? fh.close() }`** (file-descriptor leak guard — see Swift Implementation Pitfalls in Dev Notes; a 300-track benchmark would exhaust the macOS soft fd limit of 256 without this). Walks the MP4 atom tree `moov` → `udta` → `meta` → `ilst`, finds child atom `tmpo`. MP4 atoms are `[4-byte big-endian size][4-byte fourCC type][payload]`; if `size == 1`, the next 8 bytes hold a 64-bit big-endian extended size (handle this). The `meta` atom has a 4-byte version/flags field before its child atoms — skip those 4 bytes. Inside `tmpo`, locate the child `data` atom. From the `data` atom's start: 8 bytes are the atom header (size + `data` fourCC), then 4 bytes are type/version+flags, then 4 bytes are locale, then the 2-byte big-endian int16 BPM payload — total offset 16 from atom start, or 8 from atom payload start. Bounds-check every read (atom size ≥ 8) to avoid infinite loops on malformed files. Return nil if any atom missing.
  - [x] 3.5 Implement `private static func readID3TBPMFromMP3(from url: URL) -> [FoundTag]` — opens with `FileHandle(forReadingFrom: url)` + `defer { try? fh.close() }` (fd-leak guard). Reads the first 10 bytes for `"ID3"` magic at offset 0. Header layout: `[3 magic][1 version major][1 version minor][1 flags][4 synchsafe size]`. Support **ID3v2.3 and ID3v2.4 only**: reject (return `[]`) if the version major byte is `2` (v2.2 has 3-byte frame IDs and `TBPM` is not a v2.2 frame). If the unsynchronisation flag (bit 7 of header flags) is set, reject (return `[]`) — full de-unsync is out of scope. If the extended-header flag (bit 6) is set, read its size (synchsafe in v2.4, regular 32-bit in v2.3) and skip past it. Walk frames in the tag body: each frame is `[4-byte ASCII ID][4-byte size: synchsafe in v2.4, regular big-endian in v2.3][2-byte flags][payload]`. For each `TBPM` frame: read encoding byte (first byte of payload — `0x00` ISO-8859-1, `0x01` UTF-16-with-BOM, `0x02` UTF-16BE-no-BOM, `0x03` UTF-8), decode remaining bytes accordingly, strip trailing null terminators (`\0` for single-byte encodings, `\0\0` for UTF-16). Stop walking when frame ID is all zeros (padding) or when tag-body bytes are exhausted. The v2.4 footer (bit 4 of header flags), if present, is ignored. Return ALL `TBPM` frames found.
  - [x] 3.5b Implement `private static func readID3TBPMFromAIFF(from url: URL) -> [FoundTag]` — opens with `FileHandle(forReadingFrom: url)` + `defer { try? fh.close() }` (fd-leak guard). Read the first 12 bytes for `"FORM"` magic (offset 0) + 4-byte big-endian size + 4-byte FORM type at offset 8 (`"AIFF"` or `"AIFC"`). Reject if magic mismatch. Walk child chunks starting at offset 12: each chunk is `[4-byte ASCII id][4-byte big-endian size][payload]`, with payload zero-padded to even length (skip the pad byte if size is odd). Look for chunk id `"ID3 "` (note trailing space; this is the AIFF spec id for ID3 metadata). When found, parse the chunk's payload as an embedded ID3v2 tag using the same logic as `readID3TBPMFromMP3` (factor the body-walking code into `private static func parseID3v2Body(_ bytes: Data) -> [FoundTag]` so MP3 and AIFF share it). Return `[]` if no `ID3 ` chunk is found.
  - [x] 3.6 Implement `private static func readVorbisBPM(from url: URL) -> [FoundTag]` — opens the FLAC file with `FileHandle(forReadingFrom: url)` + `defer { try? fh.close() }` (fd-leak guard), validates `"fLaC"` magic at offset 0. Walks the metadata block sequence: each block is `[1-byte header (high bit = is-last-block flag, low 7 bits = block type)][3-byte big-endian length][payload]`. Block type 4 is Vorbis comment. Parse the Vorbis comment payload using **little-endian** lengths: `[4-byte LE vendor length][vendor UTF-8 string][4-byte LE user_comment_count]`, then `user_comment_count` repetitions of `[4-byte LE length][UTF-8 "KEY=VALUE" string]`. For each comment whose key matches `BPM` case-insensitively, emit a `FoundTag` with `source = .vorbisBPM`. Return `[FoundTag]` (not `FoundTag?`) so duplicate `BPM=` entries can participate in intra-file-conflict detection per AC #7 / AC #10 — Vorbis spec permits repeated keys.
  - [x] 3.7 Implement `static func parseRawBPM(_ raw: String, policy: MetadataPolicy) -> (parsed: Double, rejectionReason: String?)` — applies parsing hygiene per AC #8: BOM/whitespace strip, locale comma, range midpoint, non-numeric reject. Returns `(Double.nan, reason)` for rejections so callers emit evidence with `rejectionReason` set.
  - [x] 3.8 After per-source parsing, filter by `policy.valueRange` and policy-enabled parsing flags. Convert each `FoundTag` with `rejectionReason == nil` into a valid candidate; retain rejections for trace emission.

- [x] **Task 4: Wire reader into AudioAnalysisService and build evidence** (AC: #2, #4, #9, #10, #16)
  - [x] 4.1 In `AudioAnalysisService.analyzeBPM(url:options:)`, after the early cancellation check but before the PCM read, add: `let foundTags: [FoundTag] = options.metadataPolicy.enabledSources.isEmpty ? [] : FileMetadataReader.readTags(from: url, policy: options.metadataPolicy)`. The empty-check short-circuits the `.disabled` case to zero I/O per AC #4.
  - [x] 4.2 Compute consensus: if exactly one valid (non-rejected) found tag → single-tag case. If ≥2 and all agree within `policy.consensusTolerance` (±0.5 BPM absolute) → unanimous consensus with `consensusBPM = mean`. If ≥2 and at least one pair disagrees → intra-file conflict (all tags rejected for decision, `rejectionReason == "intra-file-conflict"` on each).
  - [x] 4.3 Build initial `[MetadataBPMEvidence]` entries from `foundTags`: each entry carries `source`, `rawValue`, `parsedBPM`, and (initially) `corroboratedWith = nil`, `ratioMatched = nil`, `boostApplied = 1.0`, `rejectionReason` reflecting parse-time state. The later corroborator step updates `corroboratedWith`/`ratioMatched`/`boostApplied`/`rejectionReason` based on DSP outcomes.
  - [x] 4.4 Declare `internal struct MetadataCorroborationInput: Sendable` in a new file `Sources/BoomBoomBoomKit/MetadataCorroborator.swift` (NOT private inside `AudioAnalysisService.swift` — it is referenced cross-file from `MetadataCorroborator`). Fields: `consensusBPM: Double?`, `participatingTags: [MetadataBPMEvidence]`, `conflictDetected: Bool`, `policy: MetadataPolicy`. The service builds this struct and passes it to the corroborator.

- [x] **Task 5: Apply boost/penalty via MetadataCorroborator (post-merge, NOT inside merge)** (AC: #11, #12, #13, #14, #15, #16)
  - [x] 5.0 **Architectural decision (Codex review 2026-04-30, finding C1):** `CandidateMergeStrategy.merge`'s `BPMResult?` return type is **NOT changed** by this story. There are 41 call sites of `.merge(...)` across `BPMAnalyzerTests`, `OA300BenchmarkTests`, and `Sources/`; a return-type cascade would explode the diff and risk subtle test breakage. Instead, introduce a new caseless enum namespace `MetadataCorroborator` (parallel to `MelFilterbank`, `FileMetadataReader`) in `Sources/BoomBoomBoomKit/MetadataCorroborator.swift`. The service calls `merge()` first (signature unchanged), then calls `MetadataCorroborator.apply(...)` on the merged result. This also resolves Codex finding C3 (`merge`'s `count == 1` short-circuit no longer skips metadata application — the corroborator runs unconditionally from the service after merge returns).
  - [x] 5.1 Implement `static func apply(to result: BPMResult, input: MetadataCorroborationInput) -> (BPMResult, [MetadataBPMEvidence])` in `MetadataCorroborator.swift`. Operates on `result.candidates`, `result.bpm`, `result.confidence`. Returns the post-corroboration `BPMResult` plus the final evidence list. When `input.participatingTags.isEmpty`, returns `(result, [])` unchanged (this is the `metadataPolicy = .disabled` and zero-tags-found paths).
  - [x] 5.2 Corroboration + winner-promotion per AC #11, #12 (matters for tests like `testOctaveCorroboration` where DSP's top candidate is wrong but a lower-ranked candidate matches the tag):
    - For each participating tag (single-tag case is a degenerate "consensus" of one): scan ALL candidates in `result.candidates`, not just `result.bpm`. A candidate `C` corroborates tag `T` if `abs(C.bpm - T) / T <= policy.corroborationTolerance` (same-tempo), OR if `policy.allowOctaveCorroboration && (C.bpm/T or T/C.bpm) ∈ [1.92, 2.08]` (octave), OR if `policy.allowTripletCorroboration && (ratio ∈ [1.45, 1.55] or ratio ∈ [2.85, 3.15])` (triplet — gated `false` by default).
    - For every corroborating `(C, T)` pair: multiply `C.score` by `policy.corroborationBoost` (default 1.25). Apply boost to the candidate's score, NOT the result's confidence — confidence comes from re-selecting the winner. **Boost arithmetic must happen in `Double`** because `C.score` is `Float` but `policy.corroborationBoost` is `Double` and Swift does NOT auto-widen `Float * Double`. Pattern: `let boosted = Float(Double(C.score) * policy.corroborationBoost)`. Same pattern for the 0.85 skepticism penalty in 5.3 — `0.85` is exactly representable neither as Float nor Double, but the `Float(Double * Double)` form is the canonical "compute in Double, store in Float" idiom and matches the precision tradeoff used elsewhere in the pipeline.
    - Re-select the winner from the boosted candidate pool: highest score wins; ties broken by `(higher original score, lower original index)` (mirrors DD#16 from Story 3-5 to keep tiebreakers consistent with `windowVoting`).
    - Compute final `confidence`: if the new winner is a corroborated candidate, `prevConfidence * policy.corroborationBoost` clamped at `policy.maxBoostedConfidence` (0.95). If the new winner is NOT corroborated (no tag matches it), confidence is unchanged. Apply the divide-by-zero / non-finite guard: if `prevConfidence.isFinite && prevConfidence > 0`, compute `boostApplied = newConfidence / prevConfidence`; otherwise `boostApplied = 1.0` and confidence is unchanged. Per Codex finding M10.
    - Update each participating evidence entry: set `corroboratedWith` to the (re-selected) winner's bpm if it corroborates the tag, else `nil`; set `ratioMatched` to the matched `HarmonicRatio` enum value; set `boostApplied`.
  - [x] 5.3 Unanimous-disagrees penalty per AC #14: if `input.consensusBPM != nil` (unanimous consensus) AND no candidate in `result.candidates` corroborates at any allowed ratio, multiply the winning candidate's confidence by `policy.skepticismPenalty` (default 0.85), with the same divide-by-zero guard as 5.2. Mark every participating evidence entry with `rejectionReason == "dsp-disagreement"`, `boostApplied = 0.85`.
  - [x] 5.4 Single-uncorroborated per AC #15: if only one tag and it does not corroborate, leave confidence unchanged. Evidence entry gets `rejectionReason == "uncorroborated-single-tag"`, `boostApplied = 1.0`.
  - [x] 5.5 Intra-file conflict per AC #10 / `input.conflictDetected == true`: skip all corroboration. Every evidence entry already has `rejectionReason == "intra-file-conflict"`.
  - [x] 5.6 Wire from `AudioAnalysisService.analyzeBPM`: after the existing `CandidateMergeStrategy.merge(...)` call (line ~252), add `let (corroborated, evidence) = MetadataCorroborator.apply(to: mergedResult, input: corroborationInput)`. Pass `evidence` to the `AudioAnalysisResult` initializer. The corroborator runs uniformly for single-window (intensity 1-5) and multi-window (intensity 6+) paths because the service calls it unconditionally — AC #16's "fastest intensity still populates evidence" holds without changing `merge`.

- [x] **Task 6: Extend BPMDiagnosticTrace** (AC: #18)
  - [x] 6.1 Add public fields to `BPMDiagnosticTrace`: `public var metadataEvidenceBeforeBoost: [MetadataBPMEvidence] = []`, `public var candidatesBeforeBoost: [(bpm: Double, score: Float)] = []`, `public var candidatesAfterBoost: [(bpm: Double, score: Float)] = []`, `public var metadataPolicyUsed: MetadataPolicy = .default`. All have `///` doc comments.
  - [x] 6.2 Populate the trace fields in `MetadataCorroborator.apply` when `enableTrace` was true (threaded via the `BPMResult.trace` carried into the function — when `result.trace != nil`, populate the new fields on a mutable copy and return it as part of the new `BPMResult`).
  - [x] 6.3 Ensure the trace's existing `confidence` field reflects the post-boost/post-penalty confidence (not the pre-boost value) — consistent with the existing "`confidence` is the final returned value" semantic.

- [x] **Task 7: Tests** (AC: #5, #6, #7, #8, #9, #10, #11, #12, #13, #14, #15, #16, #17, #20)
  - [x] 7.1 Create `Tests/BoomBoomBoomKitTests/FileMetadataReaderTests.swift`. Use Swift Testing. Cover parser correctness per format, hygiene rules, and rejection paths (sentinel-zero, out-of-range, non-numeric, intra-file-conflict).
    - Fixture M4A with `tmpo = 128` → `parsedBPM == 128.0`, `source == .iTunesTmpo`.
    - Fixture M4A with `tmpo = 0` → evidence emitted with `parsedBPM.isNaN == true`, `rejectionReason == "sentinel-zero"`, `boostApplied == 1.0` (matches AC #5 + AC #8).
    - Fixture MP3 with `TBPM = "128"` → `parsedBPM == 128.0`, `source == .id3TBPM`.
    - Fixture MP3 with `TBPM = "128,5"` → `parsedBPM == 128.5` (locale comma).
    - Fixture MP3 with `TBPM = "120-125"` → `parsedBPM == 122.5` (range midpoint).
    - Fixture MP3 with `TBPM = "fast"` → rejected with `rejectionReason == "non-numeric"`.
    - Fixture MP3 with `TBPM = "500"` → rejected with `rejectionReason == "out-of-range"`.
    - Fixture MP3 with two `TBPM` frames `128` and `130` → intra-file-conflict (both rejected).
    - Fixture MP3 with v2.2 header (version major byte = 2) → reader returns zero tags (v2.2 unsupported, AC #6).
    - Fixture MP3 with unsynchronisation flag set → reader returns zero tags (unsync rejected, AC #6).
    - Fixture AIFF with `ID3 ` chunk containing `TBPM = "128"` → `parsedBPM == 128.0`, `source == .id3TBPM` (validates AC #6a chunk-walking path is distinct from MP3's leading-`ID3` path).
    - Fixture AIFF with no `ID3 ` chunk → reader returns zero tags (common case, AC #6a).
    - Fixture FLAC with TWO `BPM=` Vorbis comments (`128` and `130`) → intra-file-conflict (both rejected, AC #7).
    - Fixture FLAC with `BPM=175` in Vorbis comment → `parsedBPM == 175.0`, `source == .vorbisBPM`.
    - Fixture WAV with no tags → empty result.
  - [x] 7.2 Fixture strategy (Codex finding M15): two-tier.
    - **Parser unit fixtures** (preferred for the `FileMetadataReaderTests` cases above): hand-crafted minimal byte arrays declared inline in test source as `Data(bytes: [...])`. These are 30-200 bytes each — a hand-written `tmpo` atom, a 50-byte ID3v2.3 frame, a synthetic FLAC header + Vorbis comment block. Deterministic across machines, no external tooling needed, no version drift, easy to audit byte-for-byte in code review. Parser tests live or die by these.
    - **Integration fixtures** (one or two real container files): committed under `Tests/BoomBoomBoomKitTests/Fixtures/metadata/` for end-to-end exercises that need real PCM + real metadata in the same file. Document tool versions in `Fixtures/metadata/README.md` (e.g., `ffmpeg N-XXX-YYY`, `metaflac 1.4.3`). These are NOT regenerable byte-for-byte; if a teammate regenerates, expect padding/atom-ordering/vendor-string drift. Tests against integration fixtures should assert *parsed values* (parsedBPM == 128.0), NEVER raw bytes or specific offsets.
  - [x] 7.3 Create `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift`. Integration tests against `AudioAnalysisService.analyzeBPM` using the new fixtures plus synthetic click tracks from `TestSignalGenerators`. Cover:
    - **testDefaultEnablesMetadata**: default `Options` → metadata read, evidence populated on tagged fixture.
    - **testDisabledPolicyNoIO**: `metadataPolicy = .disabled` → evidence empty. Assert byte-identical `bpm`/`confidence`/`candidates` against a snapshot of the pre-story output on the same fixture (regression guard per AC #4).
    - **testSameTempoCorroborationBoostsConfidence**: synthetic 128 BPM click + tag=128 + DSP detects 128 → confidence boosted (≤ 0.95), `corroboratedWith == 128.0`, `ratioMatched == nil`, `boostApplied > 1.0`.
    - **testOctaveCorroboration**: synthetic 128 BPM click + tag=64 + DSP detects 128 → corroborated via `.half` ratio, confidence boosted.
    - **testUnanimousConsensus** (corrected: unit test, NOT integration): a single audio container cannot carry both `tmpo` (MP4-only) and `TBPM` (ID3-only) — different format families. Rewrite as a unit test against `MetadataCorroborator.apply` with a hand-constructed `MetadataCorroborationInput.participatingTags` containing two evidence entries from distinct `MetadataSource` values both at `parsedBPM = 128.0`. DSP candidates supplied directly as `[(bpm: 128.0, score: 0.7)]`. Assert `consensusBPM == 128.0`, `conflictDetected == false`, both entries corroborated with `corroboratedWith == 128.0`. Alternative integration variant (if a single-container option is desired): use MP3 with two `TBPM` frames at the same value to exercise the duplicate-frame consensus path — but note this exercises within-source consensus, not cross-source.
    - **testIntraFileConflict** (corrected: unit test, NOT integration): same cross-container limitation as above. Rewrite as a unit test against `MetadataCorroborator.apply` with hand-constructed `participatingTags` containing `.iTunesTmpo = 128.0` and `.id3TBPM = 140.0`. DSP candidates `[(bpm: 128.0, score: 0.7)]`. Assert `conflictDetected == true`, both entries marked `rejectionReason == "intra-file-conflict"`, no boost applied to DSP candidate.
    - **testThreeTagPartialAgreement** (Codex policy-architect freeze of all-or-nothing rule, AC #10): unit test against `MetadataCorroborator.apply` with hand-constructed `participatingTags` containing three entries — `.iTunesTmpo = 128.0`, `.id3TBPM = 128.0`, `.vorbisBPM = 174.0`. DSP candidates `[(bpm: 128.0, score: 0.7)]`. Assert `conflictDetected == true` and ALL THREE entries have `rejectionReason == "intra-file-conflict"` and `boostApplied == 1.0` — including the two that agreed at 128. This test pins the all-or-nothing contract; if a future story flips to majority-rules, this test fails deliberately, signaling the future-author to also update rejection vocabulary (`"outlier-from-majority"` for the 174 entry, distinct from `"intra-file-conflict"` for the no-consensus case).
    - **testUnanimousDisagreesWithDSPApplyPenalty** (corrected: unit test, NOT integration): same cross-container limitation as `testUnanimousConsensus` / `testIntraFileConflict`. Rewrite as a unit test against `MetadataCorroborator.apply` with hand-constructed `participatingTags` containing `.iTunesTmpo = 128.0` and `.id3TBPM = 128.0`. DSP candidates `[(bpm: 140.0, score: 0.7)]` (no ratio match to 128). Assert `result.bpm == 140.0`, `result.confidence ≈ 0.7 × 0.85`, both evidence entries marked `rejectionReason == "dsp-disagreement"`, `boostApplied == 0.85`.
    - **testSingleUncorroboratedTagIgnored**: fixture with only tmpo=200 + DSP detects 128 (no ratio match) → confidence unchanged, evidence marked `"uncorroborated-single-tag"`.
    - **testFastestIntensityStillReadsMetadata**: `intensity = .fastest` on tagged fixture → evidence populated.
    - **testDurationHintComposesWithMetadataBoost** (Codex finding M11): synthetic 128 BPM click ≥ 180 seconds + tag=128 + default Options (both `durationHint` and `metadataPolicy = .default`). Assert that `confidence` reflects compounded effects: per-window candidate boost (1.10× from Story 3.4 step 9.7) → merge → corroborator (1.25× post-merge). Final confidence ≤ `policy.maxBoostedConfidence` (0.95). Document the expected ordering in a code comment so future refactors don't accidentally re-order the boosts.
    - **testBoostAppliedDivideByZeroGuard** (Codex finding M10): manufacture a `BPMResult` with `confidence == 0` (or non-finite) and run the corroborator directly. Assert `boostApplied == 1.0` and final confidence equals input confidence — no NaN, no Inf.
    - **testWinnerPromotionFromCorroboration** (Codex finding C2): synthetic input where DSP's top candidate (by score) is 140 BPM but a lower-ranked candidate is 128 BPM, plus tag=128. Assert that the post-corroboration winner is 128 BPM (the tag promoted the lower-ranked candidate above the DSP top), `result.bpm == 128.0`, `corroboratedWith == 128.0`. Without this test the contract reverts silently to "boost only the winner."
    - **testTVRFixtureHasTmpoAtom** (AC #20): explicit reference test against the OA300 `03 TVR.m4a` fixture under the `Bad BPM/` subfolder. Env-gate behind `OA300_CORPUS_PATH` (same pattern as `OA300BenchmarkTests`). Capture the actual `tmpo` value in Completion Notes when the corpus is available locally — preflight via `AtomicParsley` or the new `FileMetadataReader.readITunesTmpo` itself. Document the ground-truth value in a code comment.
  - [x] 7.4 Add a regression-guard test that asserts `DSPTechnique.allCases.count == 7` and `TechniqueSet.allDSPCombinations().count == 128` (AC #17). Put it in `AblationSmokeTests.swift` or a new `ArchitectureInvariantsTests.swift`.

- [x] **Task 8: Validation and benchmark breakdown** (AC: #19, #21)
  - [x] 8.1 `make fmt` + `make lint` — clean. Resolve any new warnings in the new files.
  - [x] 8.2 `make build` — compiles cleanly on `swift build -c debug` and `swift build -c release`.
  - [x] 8.3 `make test` — all existing + new tests pass in parallel.
  - [x] 8.4 `make benchmark` — OA300 Acc1/Acc2 integer counts ≥ Task 0 baselines. Also add a "Tagged-subset breakdown" section to `OA300BenchmarkTests.benchmarkAcc1*` output: count the `result.metadataEvidence.count > 0` tracks and bucket them into (corroborated-same-tempo, corroborated-octave, intra-file-conflict, dsp-disagreement, uncorroborated). Print as `N / total` where `total` is `availableTracks.count` (currently 82 — do NOT hardcode 300; the corpus fixture covers 82 of 300 entries today, see Codex finding L18). This is a reporting addition, not a gate.
  - [x] 8.5 `make benchmark-giantsteps` — Acc1/Acc2 ≥ Task 0 baselines.
  - [x] 8.6 `make ablation` — matrix completes, count is 128 (guarded by Task 7.4).
  - [x] 8.7 `make perf-benchmark` — mean/median/p95 drift from Task 0 baseline ≤ 10%. Record the new timing in Completion Notes as the post-story perf baseline.
  - [x] 8.8 Update CLAUDE.md "Key Types" section: add entries for `MetadataPolicy`, `MetadataSource`, `MetadataBPMEvidence`, `HarmonicRatio`, and mention the new `AudioAnalysisResult.metadataEvidence` field.
  - [x] 8.9 Run `make oracle` (three-way DAW comparison) — capture the `03 TVR.m4a` behavior explicitly. Document in Completion Notes whether metadata corroborated the DAW oracle or DSP.

## Dev Notes

### Why NOT a DSPTechnique case

`DSPTechnique` is a closed enum of sample-domain signal-processing transformations — each case corresponds to a gated code path inside `BPMAnalyzer.estimateBPM` that operates on `[Float]` samples. Metadata reading is a pre-analysis input-source concern, orthogonal to the DSP pipeline. Adding `.metadataHint` would (a) double the ablation matrix from 2^7=128 to 2^8=256 for a non-DSP signal, (b) corrupt the semantic meaning of `DSPTechnique.allCases`, and (c) still require a sideband config struct to carry per-source rules because enum cases can't carry rich associated values while remaining `CaseIterable + Hashable`. The decision: keep `DSPTechnique` pure; expose metadata as `AudioAnalysisService.Options.metadataPolicy` with a rich struct. This mirrors Story 3.4 (duration-derived BPM hint), which is likewise NOT a `DSPTechnique` case.

### Why the boost lives in MetadataCorroborator (post-merge), not in CandidateMergeStrategy.merge or BPMAnalyzer step 10

Metadata is read once per file. `BPMAnalyzer.estimateBPM` runs once per analysis window (intensity 6+ runs 3 windows: 30s/60s/90s); if the boost applied inside step 10 it would have to be threaded through every window call — redundant. `CandidateMergeStrategy.merge` would be the natural place semantically (it runs once per file post-windows), BUT changing `merge`'s signature to also return `[MetadataBPMEvidence]` cascades into 41 existing call sites in `BPMAnalyzerTests`, `OA300BenchmarkTests`, and elsewhere — Codex review (2026-04-30, finding C1) flagged the cascade as the dominant integration risk. Additionally, `merge` short-circuits when `windowResults.count == 1`, which would silently bypass metadata for intensities 1-5 (Codex finding C3). The fix: introduce a separate caseless enum namespace `MetadataCorroborator` (parallel to `MelFilterbank`, `FileMetadataReader`) that runs AFTER `merge` returns, called unconditionally from `AudioAnalysisService.analyzeBPM`. This keeps `merge`'s signature stable, runs uniformly across all intensities, and isolates corroboration logic to one file (~80 LOC) that is independently testable.

### Why direct container parsing, not AVFoundation

`AVAsset.commonMetadata` (sync) is **deprecated on macOS 13+**; the modern replacement is `await asset.load(.commonMetadata)` which is `async`-only per the explicit `AVAsynchronousKeyValueLoading` contract. Adopting it would force `analyzeBPM` to either become `async` (breaking the public sync contract — and propagating async to every caller including `AudioAnalysisService.analyzeLUFS` for symmetry) or wrap `await` inside a semaphore (anti-pattern under Swift 6 strict concurrency, and SwiftLint-flagged). `AVAudioFile` exposes no metadata accessors — verified via Apple Developer Documentation MCP scan, 2026-04-30. Additionally, FLAC Vorbis-comment surfacing on macOS is empirically inconsistent — the user reports silent nil returns on some FLACs, and Apple documents no `vorbisComment` member of `AVMetadataFormat` (verified via apple-docs MCP), consistent with the empirical observation. Direct parsing is ~150 LOC across three formats (MP4 tmpo ~40 LOC, ID3 TBPM ~60 LOC, FLAC Vorbis ~50 LOC), stays fully synchronous, sidesteps the AVFoundation async-or-deprecated cliff entirely, and gives deterministic FLAC behavior. If a future story ever wants AVFoundation as a fallback path for ID3 only (where it's reliable), note the typed identifiers exist: `AVMetadataIdentifier.iTunesMetadataBeatsPerMin` (NOT `…BeatsPerMinute` — symbol is truncated; verified via apple-docs MCP) and `AVMetadataIdentifier.id3MetadataBeatsPerMinute`. Trade-off: we own ~150 LOC of parser code; the formats are stable and the parsers are small.

### Swift Implementation Pitfalls (Pre-Dev Checklist)

These are universal Swift byte-parsing traps that the per-format pitfalls below do NOT cover. The dev agent must internalize all six before writing `FileMetadataReader` or `MetadataCorroborator` — each is a known silent-bug source independent of any container format. Source: `axiom-performance` review, 2026-05-02.

1. **`Data` slice index space.** `Data` slices preserve the parent's `startIndex`. `data[2..<6][0]` traps with index-out-of-bounds; `data[2..<6].first` returns `0x02`. Two safe patterns: `let payload = Data(data[2..<6])` (rebuild from index 0, copies bytes — fine for small spans) or `let payload = data[2..<6]; payload[payload.startIndex + offset]` (index-relative, no copy). Pick one and use it consistently inside each parser. **This is the single most common Swift byte-parser bug.**

2. **Multi-byte loads must use `loadUnaligned`.** `UnsafeRawBufferPointer.load(fromByteOffset:as:)` traps `EXC_BAD_ACCESS` on misaligned access for types with alignment > 1. Use `loadUnaligned(fromByteOffset:as:)` (Swift 5.7+) for every UInt16 / UInt32 / UInt64 read at an arbitrary byte offset. Always apply `.bigEndian` (MP4, ID3, FLAC outer) or `.littleEndian` (Vorbis comment) explicitly — Swift's `.load` returns the native byte order of the host, NOT the file's wire format.

3. **`Float * Double` does NOT auto-widen.** Swift won't let you multiply a `Float` by a `Double` — they require an explicit cast. The candidate-score boost path crosses this boundary because `BPMResult.candidates: [(bpm: Double, score: Float)]` mixes Float scores with Double policy multipliers. Compute in Double, store in Float at assignment: `let boosted = Float(Double(score) * policy.corroborationBoost)`. Doing the multiply in Float silently loses precision (0.85 is not exactly representable in either format, and `Float(0.85) ≠ Double(0.85)` at the bit level).

4. **`FileHandle` MUST close in `defer`.** `FileHandle(forReadingFrom:)` opens a Unix file descriptor. Across a 300-track OA300 benchmark with `metadataPolicy = .default`, that's 300 leaked fds. macOS soft limit is 256 — the benchmark would fail mid-run with `EMFILE`. Pattern (used in all four reader functions, Tasks 3.4 / 3.5 / 3.5b / 3.6):
   ```swift
   guard let fh = try? FileHandle(forReadingFrom: url) else { return [] }
   defer { try? fh.close() }
   ```

5. **`withUnsafeBytes` pointer lifetime.** The pointer is invalid outside the closure. Compute and copy values inside; never return or store the raw pointer. This is correct:
   ```swift
   let value = data.withUnsafeBytes { ptr in
     ptr.loadUnaligned(fromByteOffset: 8, as: UInt32.self).bigEndian
   }
   ```
   This is undefined behavior:
   ```swift
   let ptr = data.withUnsafeBytes { $0.baseAddress! }  // dangling
   let value = ptr.load(as: UInt32.self)  // UB
   ```

6. **`String(data:encoding:)` is `Optional`.** ID3 frame text decoding can fail on truncated, malformed, or wrong-encoding-byte bytes. Treat decoding failure as `rejectionReason == "non-numeric"` (or `"out-of-range"` if applicable to the failure mode), never crash. Pattern: `guard let text = String(data: payload, encoding: chosenEncoding) else { return FoundTag(... rejectionReason: "non-numeric") }`.

### Container-format parsing pitfalls

**MP4 `tmpo` atom:**
- Atom header is `[4-byte big-endian size][4-byte fourCC type]`. If size == 1, the next 8 bytes are the real 64-bit big-endian size (handle this).
- The `tmpo` atom is inside `moov/udta/meta/ilst/tmpo`. The `meta` atom has a 4-byte version/flags field before its children — skip it.
- `tmpo` under `ilst` is actually a container holding a `data` sub-atom. **`data` atom layout (Codex finding M5 — easy to misread):** `[8-byte atom header (size + "data" fourCC)][4-byte type/version+flags][4-byte locale][payload]`. From the `data` atom's start, the int16 BPM is at offset 16 (8 header + 4 type/flags + 4 locale). From the `data` atom's payload start (i.e., after the 8-byte header), the int16 is at offset 8 (4 type/flags + 4 locale). For `tmpo`, the payload is the 2-byte big-endian int16 BPM value.
- Always check atom size ≥ 8 (header minimum) to avoid infinite loops on malformed files.

**ID3v2 TBPM frame:**
- Header is `"ID3"` + `[1 version][1 revision][1 flags][4-byte synchsafe size]`. Synchsafe: each byte contributes 7 bits, high bit always 0. Decode: `size = (b0<<21) | (b1<<14) | (b2<<7) | b3`.
- **Version scope (Codex finding M6):** Story 3.6 supports **ID3v2.3 and ID3v2.4 only**. ID3v2.2 has 3-byte frame IDs and `TBPM` is not a v2.2 frame ID — if `version == 2`, return zero tags. ID3v1 (trailing 128-byte `TAG` block at file end) is unsupported.
- **Header flags to handle:** bit 7 (unsynchronisation) — if set, return zero tags (full de-unsync is out of scope; ~99% of tagged files have this clear). bit 6 (extended header) — if set, read its size (synchsafe in v2.4, regular 32-bit big-endian in v2.3) and skip past it before walking frames. bit 4 (v2.4 footer) — if set, ignore the trailing footer.
- In ID3v2.3, frame sizes are regular 32-bit big-endian integers. In ID3v2.4, they're synchsafe. Check the header version byte.
- `TBPM` payload: first byte is the text encoding. `0x00 = ISO-8859-1`, `0x01 = UTF-16 with BOM`, `0x02 = UTF-16BE without BOM`, `0x03 = UTF-8`. Decode remaining bytes accordingly.
- Text frames may have trailing null terminators (`\0` for single-byte encodings, `\0\0` for UTF-16). Strip them.
- Multiple `TBPM` frames are spec-violations but common in real files. Return ALL of them so AC #10 can detect conflict.
- **Stop walking** when frame ID is all zeros (this is padding) or when the tag-body bytes are exhausted. Don't loop on garbage past the declared tag size.

**AIFF FORM container (Codex finding C4):**
- Header: `[4 magic "FORM"][4-byte big-endian size][4-byte FORM type "AIFF" or "AIFC"]`.
- After byte 12, child chunks repeat: `[4-byte ASCII id][4-byte big-endian size][payload]`. Chunks are zero-padded to even length — if size is odd, skip one pad byte after the payload.
- Look for chunk id `"ID3 "` (note trailing space; this is the registered AIFF id for an ID3v2 metadata chunk). When found, parse the chunk's payload with the same ID3v2 logic as MP3.
- Reject if `FORM` magic is missing or the FORM type is neither `AIFF` nor `AIFC`. Most AIFFs have no `ID3 ` chunk — return zero tags in that case (not an error).

**FLAC Vorbis comment block:**
- FLAC file starts with `"fLaC"` (4 bytes) followed by a sequence of metadata blocks.
- Block header: `[1 byte: high bit = is-last-block flag, low 7 bits = block type][3-byte big-endian length]`.
- Block type 4 is `VORBIS_COMMENT`. Block type 0 is `STREAMINFO` (always first).
- Vorbis comment payload uses **little-endian** lengths (unlike the FLAC outer framing):
  - `[4-byte LE vendor length][vendor UTF-8 string][4-byte LE user_comment_count]`
  - Then `user_comment_count` entries: `[4-byte LE length][UTF-8 "KEY=VALUE" string]`.
- Key match for `BPM` is case-insensitive per Vorbis spec. `"bpm=128"`, `"BPM=128"`, and `"Bpm=128"` all match.

### Consensus tolerance: ±0.5 BPM absolute, not ±N% relative

Within-file tag consensus checks whether two independently-written tags (e.g., iTunes Match writing `tmpo`, ID3 editor writing `TBPM`) agree on the same tempo. Agreement is almost always either exact (128 / 128) or within rounding (128.0 / 128.3). Relative tolerances like ±2% are too loose at 128 BPM (±2.56 includes distinct tempos like 125/130) and too tight at 60 BPM (±1.2 might miss legitimate rounding). Absolute ±0.5 is strict and honest: it says "128 and 129 are different tempos, not rounding variations." DSP corroboration tolerance (AC #11, ±3%) is looser on purpose — DSP has its own jitter from fine-grid refinement.

### Boost shape: multiplicative 1.25× clamped 0.95 — cannot reach 1.0 by construction

This encodes robbyt's explicit skepticism directive: *"the metadata tagger may use DSP methodology similar to ours, which means a false positive in the tag could correlate with a false positive in our DSP — we must not trust the metadata implicitly 100%."* An additive boost (e.g., +0.25) reaches confidence = 1.0 whenever DSP confidence is ≥ 0.75, which violates this directive mechanically. Multiplicative 1.25× clamped at 0.95 guarantees:
- Low-confidence correct candidate (0.3) gets a modest lift to 0.375 — tag agreement doesn't flip rankings against a higher-confidence competitor.
- Mid-confidence correct candidate (0.6) becomes 0.75 — meaningful boost.
- High-confidence correct candidate (0.8) becomes 0.95 (clamped) — the tag adds conviction but cannot reach certainty.
- Metadata alone (uncorroborated) never boosts anything.

### Dependency on Story 3.1 (Harmonic Ratio Detection)

Story 3.1 has shipped (sprint-status: `done`). It introduced 3:2 (1.45-1.55 ratio window) and 3:1 (2.85-3.15 ratio window) *detection* in `BPMAnalyzer.resolveOctaveAmbiguity` — see `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:1622-1636`. Critically, those branches emit `HarmonicRatioEvidence` for the trace but do NOT modify the chosen `best` candidate. They are detection-only.

Story 3.6 introduces the first *winner-promotion* via 3:2 / 3:1, driven by metadata corroboration: a tag at half-time / triplet-time of a DSP candidate would promote that candidate to be the merge-stage winner via the boost path. Because triplet promotion has no validated regression coverage on the corpus today, `MetadataPolicy.allowTripletCorroboration` defaults to `false`. A follow-up story (post-3.6) is responsible for: (a) flipping the default to `true`, (b) running the tagged-subset breakdown to confirm net-positive movement, (c) re-running OA300 and GiantSteps gates.

Octave corroboration (2:1, 1:2) uses the existing `resolveOctaveAmbiguity` ratio window (1.92-2.08) — that path already promotes the chosen winner today, so layering a metadata boost on it is a small extension rather than a new behavior. `MetadataPolicy.allowOctaveCorroboration` defaults to `true`.

Story 3.6 also owns defining the public `HarmonicRatio` type (Story 3.1 explicitly deferred this; see Story 3.1 spec, line 10).

### Tagged-subset benchmark breakdown (AC #19)

`OA300BenchmarkTests` should grow a reporting block that partitions the corpus by metadata outcome:
```
=== Tagged-subset breakdown ===
  Tracks with metadata read:       N / total       (total = availableTracks.count, currently 82)
    Corroborated (same-tempo):     A
    Corroborated (octave ratio):   B
    Corroborated (triplet ratio):  C  (always 0 unless allowTripletCorroboration=true)
    Intra-file conflict:           D
    DSP disagreement (unanimous):  E
    Uncorroborated (single tag):   F
```
This is not a gate — it's observability. The gate is `Acc1/Acc2 >= pre-story baseline`. The breakdown lets us see whether metadata is helping (corroborated bins growing, DSP-disagreement bin small) or hurting (DSP-disagreement bin large, indicating widespread tag-DSP mismatch that might signal a bug or a tag-quality problem in the corpus).

### Regression-guard strategy

The strongest regression guard is AC #4's field-level equality requirement: with `metadataPolicy = .disabled`, the returned `bpm`/`confidence`/`candidates` fields must match the pre-Story-3.6 output by `Double.bitPattern` (and `Float.bitPattern` for `score`) — not "byte-identical whole-`AudioAnalysisResult`," which is unattainable because the new `metadataEvidence` field changes struct layout. If Task 8.4 shows any drift on OA300 or GiantSteps with `.disabled`, it means Story 3.6 changed DSP behavior via an unintended side effect (e.g., a change to merge-strategy sort order, a float precision issue, a perturbation of evaluation order from the new early-fetch line in `analyzeBPM`). That's a blocker — fix before proceeding.

The softer guard is `metadataPolicy = .default` on OA300 maintains Acc1/Acc2 ≥ baseline. The expectation is neutral-to-positive movement: the tagged subset gets a small boost from correct tags, while wrong tags get filtered out by the corroboration rule. A regression here is a sign the tolerance or boost magnitude is mis-tuned — first action is to compare the tagged-subset breakdown to isolate which tracks shifted.

### Out-of-scope for this story

- **Caller-supplied external BPM hints.** The public API takes `url: URL`, so external callers cannot pass pre-computed BPM values as hints. If a future story adds a byte-stream `analyzeBPM(samples:sampleRate:)` entry point, that would be the natural place to accept `externalHints: [BPMHint]`. Do not build the `BPMHint` primitive now.
- **Per-source tier weights.** The design explicitly rejects per-source weights (`Rekordbox = 0.8`, `iTunes = 0.5`, etc.) because there is no way to detect the writing tool from the tag itself. All enabled sources are peer; agreement across sources is the trust signal.
- **Writing metadata back.** Read-only. This library does not modify audio files.
- **OGG container support.** Not a supported input format. Vorbis-inside-FLAC is; Vorbis-inside-OGG is not.
- **New merge strategies.** Existing 8 `CandidateMergeStrategy` cases are untouched. The boost hook runs *after* `merge` returns, in the new `MetadataCorroborator`, NOT inside any merge strategy — `merge`'s `BPMResult?` signature is unchanged across all 41 existing call sites.
- **Changes to `merge` signature.** Explicitly out-of-scope. Codex review (2026-04-30) flagged the cascade risk and we adopted the post-merge-corroborator architecture instead. A future story may revisit if it has a strong reason; this story does not.
- **Tag-domain plausibility filtering beyond `valueRange`.** Story 3.6 adds no domain-plausibility filter beyond the parse-stage `valueRange` (default `30.0...300.0`) and the corroboration check itself. Plausibility is enforced transitively: a tag with no matching DSP candidate (at same-tempo, octave, or enabled triplet ratio) falls through to `uncorroborated-single-tag` and is ignored. Note one consequence under default policy (`allowOctaveCorroboration == true`): a 30 BPM tag against a 174 BPM DSP candidate has no relationship and is ignored, BUT a 30 BPM tag against a 60 BPM DSP candidate corroborates via the octave window because 60/30 = 2.0 ∈ [1.92, 2.08]. That is intentional under the half-time/double-time design — 30 BPM is a valid half-time interpretation of a 60 BPM song. The DSP pool acts as the implicit plausibility check; this is by design, not by oversight.

### Why all-or-nothing for intra-file conflict

When two or more enabled tag sources are present and they disagree by > ±0.5 BPM absolute, AC #10 rejects the entire consensus set rather than picking the majority. Rationale (Codex policy review, 2026-05-02): tags inside one file are not independent witnesses. Two agreeing tags may have been written by the same tool, copied through transcoding, or produced by a similar DSP family — the count of tags is not the count of independent measurements. Under "DSP-first honesty" (Story line 9), contradictory metadata does not boost DSP. A `(128, 128, 174)` tag set means "this container has contradictory tempo claims," not "two votes for 128."

**Future-work pointer.** If field data shows N≥3 partial-agreement conflicts are common AND DSP recovery from them is unreliable, a follow-up story may add a `consensusPolicy: ConsensusPolicy = .strict` enum field with `.strict` (current behavior) and `.majority` cases. That work requires:
- Extended tagged-subset breakdown reporting that distinguishes N≥3 partial-agreement cases from full-disagreement cases (current AC #19 breakdown does not). Task 0.5's `corroborationTolerance` sweep does NOT measure this — a separate observability story is needed first.
- A new `rejectionReason == "outlier-from-majority"` distinct from `"intra-file-conflict"` so the trace can distinguish "metadata layer unusable" from "metadata layer had a usable majority plus one bad tag."
- A re-evaluation of the ±0.5 BPM consensus tolerance — if integer-rounding tools are causing benign N vs N+1 conflicts, source-aware tolerance is preferable to a global ±1.0 (which would accept genuinely-different-tempo claims as consensus).

### Project Structure Notes

- All new source files go under `Sources/BoomBoomBoomKit/` (the library target). No changes to `BoomBoomBoomKitTestSupport` or `Package.swift` target layout.
- `FileMetadataReader` and `MetadataCorroborator` are both `internal` (caseless enum namespaces, same pattern as `MelFilterbank`). `MetadataCorroborationInput` is `internal` (declared in `MetadataCorroborator.swift`). `MetadataPolicy`, `MetadataSource`, `HarmonicRatio`, and `MetadataBPMEvidence` are `public` (they appear on `Options` / `AudioAnalysisResult`).
- Test fixtures: hand-crafted minimal byte arrays inline in test source for parser unit tests; one or two real container fixtures committed under `Tests/BoomBoomBoomKitTests/Fixtures/metadata/` with a `README.md` documenting tool versions for the integration tests. (Two-tier strategy per Codex finding M15.)
- The `03 TVR.m4a` reference test is env-gated behind `OA300_CORPUS_PATH` (same pattern as other corpus tests).
- Branch/distribution: this work stays on `develop` alongside the library source. When squash-merging to `main`, the standard "AI tooling exclusion" applies — `_bmad/`, `_bmad-output/`, `.claude/` are stripped. Library-only files (`Sources/`, `Tests/`, `Package.swift`, etc.) ship to `main` as usual. No AI-tooling coupling in the new source.

### References

- **Epic 3 parent**: [epics.md#epic-3-dsp-accuracy-improvement](../planning-artifacts/epics.md) — Story 3.6 added after 3.5.
- **Dependency (shipped)**: Story 3.1 "Harmonic Ratio Detection" (status: `done`) — provides 3:2 / 3:1 ratio detection in `BPMAnalyzer.resolveOctaveAmbiguity` (trace-only evidence, does not modify chosen winner). Story 3.6 introduces the public `HarmonicRatio` type AND the first metadata-driven winner-promotion via these ratios, gated behind `MetadataPolicy.allowTripletCorroboration: Bool = false` (default off) until validated by a follow-up story.
- **Architecture context**: [architecture.md](../planning-artifacts/architecture.md) — ADR-7 (harmonic ratio detection in step 10) provides the octave-ratio infrastructure Story 3.6 reuses.
- **Project conventions**: [project-context.md](../project-context.md) — Swift 6, value types, vDSP mandate, `@preconcurrency import AVFoundation`, Options-struct pattern, six-line file headers, `make fmt` before `make lint`.
- **Container format specs**:
  - ISO/IEC 14496-12:2015 (MP4 atom structure, `moov/udta/meta/ilst/tmpo`)
  - ID3v2.4 informal standard §4.2 text frames (`TBPM`) — https://id3.org/id3v2.4.0-frames
  - Xiph.org Vorbis comment specification — https://xiph.org/vorbis/doc/v-comment.html
  - FLAC format specification §6 metadata blocks — https://xiph.org/flac/format.html
- **OA300 fixture reference**: `03 TVR.m4a` under `$OA300_CORPUS_PATH/Bad BPM/` — confirmed to carry an iTunes `tmpo` atom.
- **Party-mode design synthesis** (this conversation): Winston (architect), Amelia (dev), Mary (analyst) converged on "not a DSPTechnique, not per-source weights, direct container parsing, multiplicative boost clamped at 0.95, consensus at ±0.5 BPM absolute, corroboration at ±3% relative, metadata in merge not step 10."

## Dev Agent Record

### Agent Model Used

claude-opus-4-7 (Opus 4.7, 1M context window) via Claude Code CLI.

### Debug Log References

- Pre-story baseline run logs: `/tmp/baseline-oa300.log`, `/tmp/baseline-giantsteps.log`, `/tmp/baseline-perf.log` (ephemeral; values copied into Completion Notes)
- Post-story benchmark logs: `/tmp/oa300-rerun.log`, `/tmp/giantsteps-rerun.log`, `/tmp/ablation.log`, `/tmp/perf-rerun.log` (ephemeral)
- Per-run perf baseline JSON: `_bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260502T072102Z--03acccd--0b0c92da.json` (pre-story snapshot before any wiring), `_bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260502T150436Z--03acccd--de0ab4d2.json` (post-story snapshot), `_bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260502T151937Z--03acccd--08af7a51.json` (post-story follow-up snapshot)

### Completion Notes List

**Pre-story baselines (git SHA `03acccd`, captured 2026-05-02):**
- OA300: Acc1=57/82 (69.5%), Acc2=73/82 (89.0%) [intensity 7, default Options, no metadata yet]
- GiantSteps: Acc1=537/661 (81.2%), Acc2=546/661 (82.6%)
- Perf (OA300 wall-clock): mean=187ms, median=148ms, p95=263ms

**Post-story results (git SHA `03acccd` + Story 3.6, 2026-05-02):**
- OA300 with `metadataPolicy=.default`: Acc1=58/82 (+1, 70.7%), Acc2=74/82 (+1, 90.2%)
- OA300 with `metadataPolicy=.disabled`: Acc1=57/82, Acc2=73/82 — exact match to pre-story (AC #4 byte-equality contract holds)
- GiantSteps with `metadataPolicy=.default`: Acc1=537/661, Acc2=546/661 (no change — corpus has no embedded BPM tags)
- GiantSteps with `metadataPolicy=.disabled`: Acc1=537/661, Acc2=546/661 (matches baseline)
- Ablation: 128 combinations completed, optimal still `sharp+vote+fine` at Acc1=55. Architecture invariant test pins `DSPTechnique.allCases.count == 7` and `TechniqueSet.allDSPCombinations().count == 128`.
- Perf (post-story): mean=179ms (-4.5% vs baseline — within system variance, well under the 10% gate; the metadata read is <5ms on tagged files and the OA300 corpus is mostly untagged)

**Post-code-review-patches snapshot (third perf-baseline JSON, 15:19:37Z):**
- OA300 with `metadataPolicy=.default`: Acc1=58/82, Acc2=74/82 — **identical to post-story**. Code-review patches (ID3v2.3 ext-header arithmetic, MP4 oversized-atom guard, intra-file conflict integration test, AC #4 bitPattern field check, doc reconciliation) ship **zero accuracy delta**, as expected for parser-correctness fixes that exercise paths the OA300 corpus does not hit.
- GiantSteps with `metadataPolicy=.default`: Acc1=537/661, Acc2=546/661 — **identical to post-story** (corpus has no embedded BPM tags; metadata layer is inert).
- Perf (post-patches): mean=176ms, median=145ms, p95=241ms (within run-to-run variance of post-story; the patches do not change the hot path).
- **Accuracy is the goal, not wall-clock**: across all three snapshots (pre-story / post-story / post-patches) the accuracy axis tells the load-bearing story — Story 3.6 lifted OA300 by +1 Acc1 / +1 Acc2 via metadata corroboration on tagged files, and the code-review patches preserved that gain byte-for-byte.

**Tagged-subset breakdown (OA300 with default policy):**
```
Tracks with metadata read:       5 / 82
  Corroborated (same-tempo):     4
  Corroborated (octave ratio):   0
  Corroborated (triplet ratio):  0
  Intra-file conflict:           0
  DSP disagreement (unanimous):  0
  Uncorroborated (single tag):   1
```

**Task 0.5 corroboration tolerance sweep (CORROBORATION_SWEEP=1):**
```
Tolerance  Acc1   Acc2   SameTempo  Octave  Uncorrob  DSPDis
0.01       58/82  74/82   3          0       2         0
0.02       58/82  74/82   4          0       1         0
0.03       58/82  74/82   4          0       1         0
```
Acc1/Acc2 are identical across all three tolerances. Tightening from 0.03 to 0.02 keeps the same outcomes; tightening to 0.01 loses one same-tempo corroboration (a tag that was within 2% but outside 1%) without changing accuracy. The shipped default `0.03` is correct — no follow-up micro-story needed.

**TVR fixture (AC #20 reference, OA300 `Bad BPM/03 TVR.m4a`):**
- Embedded `tmpo` atom value: 129
- DSP winner at default intensity: 130.0 BPM
- Result: `corroboratedWith=130.0`, `ratioMatched=nil`, `boostApplied≈1.033` (confidence boost was clamped near `maxBoostedConfidence=0.95`)
- This is a same-tempo corroboration: `|130 - 129| / 129 ≈ 0.78%` is well within the default 3% tolerance.
- Rekordbox ground-truth for TVR is 130 BPM, so DSP+metadata agree with Rekordbox.

**DAW oracle (`make oracle`):**
- TVR is not in the failures list — DSP detects within tolerance, metadata corroborates the DSP winner. Three-way agreement (DSP / metadata / Rekordbox).
- The remaining 8 oracle-annotated failures are unchanged from pre-story (all are corpus-level DSP shortcomings, not metadata regressions).

**Architecture decisions adopted from the story spec (verbatim):**
1. `MetadataCorroborator` is a separate caseless-enum namespace called AFTER `merge` returns — this preserves the `BPMResult?` signature of `CandidateMergeStrategy.merge` across all 41 call sites (Codex finding C1). The single-window short-circuit inside `merge` no longer skips metadata at intensity 1-5 (Codex finding C3) because the corroborator runs unconditionally from the service.
2. `HarmonicRatio` has 5 cases as specified. The 3:1 ratio window (2.85-3.15) maps to `.threeHalf` (tag faster) or `.twoThird` (tag slower) — both are triplet-family ratios and the trace carries enough numeric detail (candidate BPM + tag BPM) for consumers that need to disambiguate. Documented in `MetadataCorroborator.matchRatio` doc comment.
3. Direct container parsing (no AVFoundation): `tmpo` atom walker, ID3v2.3/v2.4 frame walker (shared between MP3 and AIFF `ID3 ` chunks), FLAC Vorbis comment parser. All four parsers use `FileHandle(forReadingFrom:) + defer { try? fh.close() }` to guard against fd leaks under the 300-track benchmark.
4. AC #4 byte-equality regression guard: the two pre-existing exact-baseline tests (Story 3-4 AC #5 `durationHint=false` and Story 3-5 AC #4 `windowVoting+.simpleMajority`) were updated to set `metadataPolicy = .disabled`, since metadata corroboration now ships default-on. Default-on benchmark numbers are tracked separately by the `>= baseline` soft floor in `benchmarkAcc1Strict`.

**Tests:**
- `FileMetadataReaderTests.swift`: 31 tests across 6 suites — parser correctness for MP4, MP3, AIFF, FLAC, plus hygiene rules (locale comma, range midpoint, sentinel-zero, out-of-range, non-numeric, BOM stripping). All pass.
- `MetadataCorroborationTests.swift`: 27 tests across 4 suites — corroborator unit tests (winner-promotion, intra-file conflict, three-tag partial agreement, unanimous-disagrees penalty, single-uncorroborated, divide-by-zero guard, confidence clamp, triplet gate on/off, parse-rejection passthrough), plus service-level integration tests using a synthetic AIFF builder that wraps PCM + ID3 chunk in one file. All pass. Architecture invariants (DSPTechnique.count == 7, allDSPCombinations().count == 128, MetadataSource.count == 3, default/disabled preset shapes) live in this file under "Architecture Invariants — Story 3.6 regression guards" suite.
- TVR fixture test (env-gated by `OA300_CORPUS_PATH`) passes with corroboratedWith=130.0.
- `make test`: 287 tests pass in parallel. No regressions in pre-existing suites.

### File List

**New:**
- `Sources/BoomBoomBoomKit/MetadataPolicy.swift` — public types (`MetadataPolicy`, `MetadataSource`, `HarmonicRatio`, `MetadataBPMEvidence`, `MetadataPolicy.ParsingOptions`)
- `Sources/BoomBoomBoomKit/FileMetadataReader.swift` — internal caseless enum namespace, container parsers
- `Sources/BoomBoomBoomKit/MetadataCorroborator.swift` — internal caseless enum namespace, `apply(to:input:)` static method, `MetadataCorroborationInput` struct
- `Tests/BoomBoomBoomKitTests/FileMetadataReaderTests.swift` — parser unit tests (hand-crafted byte arrays)
- `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` — corroborator unit tests + service integration + architecture invariants

**Modified:**
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — added `metadataPolicy` to Options, `metadataEvidence` to AudioAnalysisResult, `buildMetadataInput` private helper, post-merge `MetadataCorroborator.apply` call
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` — added 4 new fields (`metadataEvidenceBeforeBoost`, `candidatesBeforeBoost`, `candidatesAfterBoost`, `metadataPolicyUsed`)
- `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift` — `runBenchmark` accepts `metadataPolicy`, `windowVotingDefaultPolicyMatchesBaseline` and `benchmarkDurationHintOptOut` set `.disabled` to preserve byte-equality, new `taggedSubsetBreakdown` and `corroborationToleranceSweep` tests
- `Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift` — `runBenchmark` accepts `metadataPolicy`, exact-baseline tests set `.disabled`
- `CLAUDE.md` — Key Types section additions for `MetadataPolicy`, `MetadataSource`, `MetadataBPMEvidence`, `HarmonicRatio`, `FileMetadataReader`, `MetadataCorroborator`

**Not modified (per Codex finding C1):**
- `Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift` — `merge` signature unchanged across all 41 call sites

**Not created (story-spec deviation, documented):**
- `Tests/BoomBoomBoomKitTests/Fixtures/metadata/` — the two-tier fixture strategy (hand-crafted byte arrays + real containers) was simplified to all-hand-crafted in test sources. Integration tests use `ClickTrackAIFFBuilder` (in `MetadataCorroborationTests.swift`) which constructs valid AIFF FORM containers with embedded ID3 chunks at runtime. This avoids version-drift across teammates regenerating fixtures while still exercising the AVFoundation read path end-to-end.
- `Tests/BoomBoomBoomKitTests/ArchitectureInvariantsTests.swift` — the regression-guard tests were inlined as the "Architecture Invariants — Story 3.6 regression guards" suite inside `MetadataCorroborationTests.swift`. Same coverage, fewer files.

### Review Findings

**Code review**

- [x] [Review][Patch] ID3v2.3 extended headers are skipped 4 bytes early [Sources/BoomBoomBoomKit/FileMetadataReader.swift:246]
- [x] [Review][Patch] Malformed MP4 extended atom sizes can trap instead of returning no metadata [Sources/BoomBoomBoomKit/FileMetadataReader.swift:159]
- [x] [Review][Patch] AC #20 TVR reference test prints the captured metadata outcome instead of asserting it [Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift:535]
- [x] [Review][Patch] AC #4 disabled-policy test does not verify field-level bitPattern identity [Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift:412]
- [x] [Review][Patch] Service-level intra-file conflict test name promises two TBPM frames but exercises only one DSP-disagreeing tag [Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift:486]
- [x] [Review][Patch] `metadataEvidence` doc says parse-rejected tags are empty, but implementation returns parse-rejection evidence [Sources/BoomBoomBoomKit/AudioAnalysisService.swift:22]

**Markdown review**

- [x] [Review][Patch] Debug log references list only two perf-baseline JSON files, but the staged changes add three perf-baseline snapshots [_bmad-output/implementation-artifacts/3-6-bpm-metadata-corroboration-signal.md:437]

## Change Log

| Date       | Version | Description                                                                                                                                                                                                                                                                                                                                                                                                                                | Author |
| ---------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| 2026-04-30 | v1.1    | Story-validation pass under `bmad-create-story` (review/validate/update mode). Corrected: AC #17 / Task 7.4 / "Why NOT a DSPTechnique case" Dev Note (count was 6/64, reality is 7/128 — Story 3.3 already added `clickTrackCorrelation`); AC #12 / Task 5.2 / Story 3.1 Dev Note (Story 3.1 is `done` with 3:2 / 3:1 detection-only at `BPMAnalyzer.swift:1622-1636` — winner-promotion via metadata is the new behavior, gated by `allowTripletCorroboration: false`); Task 5.6 picked the explicit return-tuple path and rejected the `BPMResult.trace` stash (incompatible with AC #3 when `enableTrace == false`); Task 1.6 narrowed the `.disabled` preset description to align with AC #1 (empty `enabledSources` is the only invariant, booleans are irrelevant); AC #18 fixed off-by-one ("five" → "six rejection states"). Status remains `ready-for-dev`. | Bob (SM) |
| 2026-04-30 | v1.2    | Adversarial party-mode validation pass (Codex gpt-5.5 + Apple Docs MCP + Axiom). Codex flagged 4 critical + 12 medium/low; v1.1's return-tuple architecture was wrong (would cascade across 41 `merge` call sites — verified). New architecture: introduce caseless enum `MetadataCorroborator` in a new file; `merge` signature stays `BPMResult?` unchanged; service calls `MetadataCorroborator.apply` after `merge` returns. Resolves C1 (cascade), C3 (single-window short-circuit skipping metadata at intensity 1-5). C2 (winner-promotion): AC #11 + Task 5.2 now explicitly boost ALL matching candidates and re-select winner — metadata can promote a lower-ranked candidate. C4 (AIFF): split AC #6 into MP3 (leading `ID3` header) + AC #6a (AIFF FORM-chunk-walk for `ID3 ` chunk); Task 3.5 split into 3.5 / 3.5b. M5 (MP4 byte-offset wording rewritten). M6 (ID3 v2.3/v2.4 only; reject v2.2 and unsync; skip extended header / footer). M7 (Vorbis returns `[FoundTag]` for duplicate detection). M8 (sentinel-zero contract: emit-with-`"sentinel-zero"`; AC #5 + Task 7.1 aligned with AC #8). M9 (`MetadataCorroborationInput` is `internal`, not private). M10 (divide-by-zero guard on `prevConfidence`). M11 (added `testDurationHintComposesWithMetadataBoost`). M12 (AC #4 scoped to `Double.bitPattern` + element equality, not whole-result identity). M14 (added Task 0.5 corroboration-tolerance sweep at 0.01/0.02/0.03). M15 (fixture strategy: hand-crafted byte arrays for unit tests, real fixtures only for integration). L13 (AVFoundation Dev Note tightened — `commonMetadata` deprecated macOS 13+, async-only modern path verified by Apple Docs MCP). L17 (Task 8.6 stale "64" → "128"). L18 (`N / total` not `N / 300`). Apple Docs typo: noted `iTunesMetadataBeatsPerMin` (truncated, not `…BeatsPerMinute`). Added `Sources/BoomBoomBoomKit/MetadataCorroborator.swift` to File List; `CandidateMergeStrategy.swift` removed from "modified" list. Status remains `ready-for-dev`. | Bob (SM) |
| 2026-05-02 | v1.3    | Swift-internals + bad-tag-handling pass (Axiom-performance review + Codex gpt-5.5 party-mode review). Added Dev Notes "Swift Implementation Pitfalls" subsection (six byte-parser footguns: Data slice index space, loadUnaligned alignment, Float×Double cast, FileHandle defer-close, withUnsafeBytes lifetime, String(data:encoding:) Optional). Float/Double precision note added inline to Task 5.2 boost arithmetic. `defer { try? fh.close() }` requirement added to all four reader tasks (3.4 / 3.5 / 3.5b / 3.6). AC #10 amended with explicit all-or-nothing clause + parse-phase rejection carve-out ("all valid parsed tags participating in consensus"); separate AC #10b proposal dropped after Codex review confirmed redundancy. Two existing Task 7.3 test descriptions corrected from integration to unit tests (no single audio container carries `tmpo` + `TBPM` + Vorbis); new `testThreeTagPartialAgreement` unit test added to freeze the all-or-nothing rule for 3+ tag cases. Out-of-scope bullet added for tag-domain plausibility filtering. New Dev Notes subsection "Why all-or-nothing for intra-file conflict" with future-work pointer (extended tagged-subset breakdown + new `outlier-from-majority` rejection reason if majority-rules story ever ships). Status remains `ready-for-dev`. | Bob (SM) |
| 2026-05-02 | v1.4    | Story implementation complete (dev-story workflow). All 8 tasks (0-8) and 60+ subtasks marked [x]. Pre-story baselines captured at SHA `03acccd`: OA300 57/73, GiantSteps 537/546, perf mean 187ms. Post-story default-on: OA300 58/74 (+1 each), GiantSteps unchanged (corpus has no embedded tags), perf mean 179ms (-4.5%, within variance). Disabled-policy preserves AC #4 byte-equality on both corpora exactly. Tagged-subset breakdown: 5/82 tracks have metadata, 4 corroborated same-tempo, 1 uncorroborated. Corroboration tolerance sweep across [0.01, 0.02, 0.03] confirms 0.03 default is correct (Acc1/Acc2 identical at all three; only the SameTempo bucket count varies). TVR fixture (AC #20): tmpo=129, DSP=130, corroboratedWith=130, ratioMatched=nil, boost≈1.033. Two existing exact-baseline tests (Story 3-4 AC #5 + Story 3-5 AC #4) updated to set `metadataPolicy=.disabled` to preserve their byte-equality contracts now that metadata ships default-on. Documented two minor spec deviations (no `Fixtures/metadata/` directory — synthetic ClickTrackAIFFBuilder generates real-PCM-plus-ID3 fixtures at runtime; ArchitectureInvariantsTests.swift inlined as a suite inside MetadataCorroborationTests.swift). All 284 unit tests pass; ablation 128 combos pass; perf p95 within 10% gate. Status moved to `review`. | Amelia (Dev) |
| 2026-05-02 | v1.5    | Code-review patches applied (Codex gpt-5.5 + claude-opus-4-7 dual-pass review). Six code-review items + one markdown item, all verdicted Correct or Correct-with-Concern by both reviewers. Patches: (P1) ID3v2.3 extended-header skip arithmetic — `idx += versionMajor == 3 ? 4 + extSize : extSize` (v2.3 size-field excludes itself per id3.org/id3v2.3.0 §3.2; v2.4 includes it per id3.org/id3v2.4.0-structure). (P2) MP4 oversized-atom guard — added `actualSize <= UInt64(remaining)` before `Int(actualSize)` cast to prevent trap on `UInt64 > Int.max`. (P3) AC #20 TVR test asserts `parsedBPM == 129.0` / `corroboratedWith == 130.0` / `boost > 1.0` instead of printing. (P4) AC #4 disabled-policy test now compares full `bpm`/`confidence`/per-candidate `bitPattern` against a hand-replicated pre-corroboration pipeline (helper `analyzePreMetadataPipeline`); concern noted — helper is drift-prone, deferred to Story 3-6b for a single-source refactor. (P5) Service-level intra-file conflict test now writes two distinct TBPM frames (`128`, `130`) into a single AIFF and asserts both are rejected as `intra-file-conflict` (matches the test name's promise). (P6) `metadataEvidence` doc reconciled with implementation — parse-rejected tags DO produce evidence entries. (Markdown) Debug Log References list now includes the third perf-baseline JSON. Test count grew 284 → 287. Post-patches benchmark snapshot (15:19:37Z) preserves OA300 58/74 + GiantSteps 537/546 byte-for-byte; wall-clock mean 176ms within run-to-run variance of post-story. Story status moved to `done`. Story 3-6b created as backlog follow-up to address (a) parser-hardening gaps the patches exposed but did not close (extended-header minimum-size validation, v2.3 CRC variant test coverage, v2.3 footer-flag rejection) and (b) the AC #4 helper-drift concern. | Amelia (Dev) |
