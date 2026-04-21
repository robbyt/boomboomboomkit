# Story 3.6: BPM Metadata Corroboration Signal

Status: ready-for-dev

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
   **And** the returned `bpm`, `confidence`, and `candidates` fields are byte-identical to the pre-Story-3.6 pipeline output on the same input (regression guard — OA300 and GiantSteps with `.disabled` must produce pre-story baseline numbers exactly).

5. **Given** an M4A file containing a valid `moov/udta/meta/ilst/tmpo` atom (e.g., the OA300 fixture `03 TVR.m4a` under the `Bad BPM/` subfolder),
   **When** `FileMetadataReader.readTags(from:policy:)` is invoked with `.default`,
   **Then** the `tmpo` int16 is parsed by walking the MP4 atom tree directly (NOT via `AVAsset.commonMetadata` or `AVMetadataItem`).
   **And** the returned evidence contains an entry with `source == .iTunesTmpo` and `parsedBPM` equal to the atom's 16-bit big-endian integer value as `Double`.
   **And** a `tmpo` value of `0` is treated as absent (no evidence emitted — this is the iTunes sentinel for "no BPM data").
   **And** `parsedBPM` outside `valueRange` (30.0...300.0) is rejected with `rejectionReason == "out-of-range"` (evidence still emitted, `corroboratedWith == nil`).

6. **Given** an MP3 or AIFF file with an ID3v2 `TBPM` text frame,
   **When** `FileMetadataReader` reads the file,
   **Then** the ID3v2 header (`ID3` magic, version, flags, size) is parsed directly and the `TBPM` text frame is located by walking the tag body.
   **And** the frame's text encoding byte is honored (ISO-8859-1 = 0x00, UTF-16 = 0x01, UTF-16BE = 0x02, UTF-8 = 0x03).
   **And** two or more `TBPM` frames with conflicting parsed values in the same file are treated as an intra-file conflict and rejected per AC-10.
   **And** synchsafe integer size fields (ID3v2.4) are decoded correctly (each byte contributes 7 bits).

7. **Given** a FLAC file with a Vorbis comment block containing a `BPM=` entry (case-insensitive key match),
   **When** `FileMetadataReader` reads the file,
   **Then** the Vorbis comment block is parsed directly from the FLAC metadata-block sequence (block type 4, little-endian lengths).
   **And** the returned evidence contains an entry with `source == .vorbisBPM`.
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
    **Then** ALL tags from that file are rejected for decision purposes (no boost applied, no penalty).
    **And** each rejected tag is recorded in `metadataEvidence` with `rejectionReason == "intra-file-conflict"` and `boostApplied == 1.0`.
    **And** the trace captures the disagreeing raw values and parsed values.

11. **Given** a tag (single source OR unanimous consensus) with parsed BPM `T`,
    **When** a DSP candidate `C` exists in the merge pool satisfying `abs(C - T) / T <= 0.03`,
    **Then** the tag is considered "corroborated at same-tempo".
    **And** the evidence entry has `corroboratedWith == C`, `ratioMatched == nil`.

12. **Given** a tag with parsed BPM `T` that does NOT match any DSP candidate at same-tempo,
    **When** the existing `resolveOctaveAmbiguity` path (2:1 within 1.92-2.08 ratio) OR the Story 3.1 harmonic-ratio path (3:2, 3:1) would resolve `T` and some DSP candidate `C` to the same underlying tempo,
    **Then** the tag is considered "corroborated at ratio".
    **And** `ratioMatched` is populated with the matched `HarmonicRatio` enum value, `corroboratedWith == C`.
    **And** until Story 3.1 ships, the 3:2 and 3:1 corroboration paths are stubbed to return `nil` so metadata behavior does not depend on unshipped code. A `MetadataPolicy.allowTripletCorroboration: Bool = false` flag gates the Story 3.1 path.

13. **Given** a corroborated tag (single-source or unanimous, same-tempo or ratio-matched),
    **When** `CandidateMergeStrategy.merge` runs across windows,
    **Then** the corroborated candidate's confidence is multiplied by `1.25` and clamped to `0.95` (never reaches `1.0` by construction).
    **And** `boostApplied` in the evidence records the effective multiplier (the clamped ratio, not the raw 1.25).
    **And** the boost is applied inside `CandidateMergeStrategy.merge` (cross-window), NOT solely inside `BPMAnalyzer.resolveOctaveAmbiguity` (step 10 per-window).

14. **Given** a unanimous-consensus tag set that does NOT corroborate any DSP candidate (neither same-tempo nor any enabled ratio),
    **When** `analyzeBPM` returns,
    **Then** the DSP-chosen BPM is returned unchanged (the tag value does NOT override DSP).
    **And** the winning candidate's confidence is multiplied by `0.85` (skepticism penalty applied in `CandidateMergeStrategy.merge`).
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
    **Then** `DSPTechnique.allCases.count == 6` (unchanged).
    **And** `TechniqueSet.allDSPCombinations().count == 64` (2^6 — regression guard).
    **And** no new case is added to `DSPTechnique` for metadata.

18. **Given** `enableTrace: true` and a file producing metadata evidence,
    **When** `analyzeBPM` returns,
    **Then** `BPMDiagnosticTrace` includes new fields: `metadataEvidenceBeforeBoost: [MetadataBPMEvidence]`, `candidatesBeforeBoost: [(bpm: Double, score: Float)]`, `candidatesAfterBoost: [(bpm: Double, score: Float)]`, `metadataPolicyUsed: MetadataPolicy`.
    **And** the trace distinguishes five rejection states: `"intra-file-conflict"`, `"dsp-disagreement"`, `"uncorroborated-single-tag"`, `"sentinel-zero"`, `"out-of-range"`, `"non-numeric"` (the first three govern decision; the last three govern parsing).

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
    - `make ablation` — full 2^6=64 technique matrix completes without crashes. Count assertion guards against accidental matrix growth.
    - `make perf-benchmark` — wall-clock mean/median/p95 do not regress by more than 10% (metadata read adds ~1-5 ms per file; aggregate drift should be well under this threshold).
    - Update inline `///` doc comments on every modified public API (`AudioAnalysisResult`, `AudioAnalysisService.Options`, new types).
    - Update CLAUDE.md "Key Types" section to reflect `MetadataPolicy`, `MetadataSource`, `MetadataBPMEvidence`, `HarmonicRatio`, and the new `AudioAnalysisResult.metadataEvidence` field.

## Tasks / Subtasks

**Execution order: 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8. Task 0 is pre-story baseline capture. Tasks 1-2 are public-API types. Task 3 is the reader. Tasks 4-5 wire it through the service and merge strategy. Task 6 is trace. Task 7 is tests. Task 8 is validation and benchmark breakdown.**

- [ ] **Task 0: Capture pre-story baselines** (AC: #19, #21)
  - [ ] 0.1 Run `make benchmark` on HEAD before any Story 3.6 changes. Record the exact Acc1/Acc2 integer counts (e.g., `Acc1=208/300, Acc2=267/300`) in Completion Notes under "Pre-story OA300 baseline".
  - [ ] 0.2 Run `make benchmark-giantsteps` on HEAD. Record Acc1/Acc2 integer counts in Completion Notes under "Pre-story GiantSteps baseline".
  - [ ] 0.3 Run `make perf-benchmark` on HEAD. Record mean/median/p95 wall-clock in Completion Notes under "Pre-story perf baseline".
  - [ ] 0.4 Document the exact git SHA these baselines were captured against. The regression gates in Task 8 compare integer counts against these numbers.

- [ ] **Task 1: Create public types** (AC: #1, #3, #12)
  - [ ] 1.1 Create `Sources/BoomBoomBoomKit/MetadataPolicy.swift` with the standard six-line header.
  - [ ] 1.2 Declare `public enum MetadataSource: String, CaseIterable, Sendable, Hashable` with cases `.iTunesTmpo`, `.id3TBPM`, `.vorbisBPM`. Raw values match case names.
  - [ ] 1.3 Declare `public enum HarmonicRatio: Sendable, Hashable` with cases `.one`, `.double`, `.half`, `.threeHalf`, `.twoThird`. Document that `.threeHalf` / `.twoThird` depend on Story 3.1; metadata uses them only when `MetadataPolicy.allowTripletCorroboration == true`.
  - [ ] 1.4 Declare `public struct MetadataPolicy: Sendable, Hashable` with fields: `enabledSources: Set<MetadataSource>`, `consensusTolerance: Double` (default `0.5` BPM absolute), `corroborationTolerance: Double` (default `0.03` relative), `corroborationBoost: Double` (default `1.25`), `maxBoostedConfidence: Double` (default `0.95`), `skepticismPenalty: Double` (default `0.85`), `allowOctaveCorroboration: Bool` (default `true`), `allowTripletCorroboration: Bool` (default `false`), `valueRange: ClosedRange<Double>` (default `30.0...300.0`), `parsing: ParsingOptions`.
  - [ ] 1.5 Declare nested `public struct ParsingOptions: Sendable, Hashable` with fields (all default `true`): `stripWhitespaceAndBOM`, `acceptLocaleDecimalComma`, `acceptRangeMidpoint`, `treatZeroAsAbsent`, `rejectNonNumeric`.
  - [ ] 1.6 Declare presets: `public static let `default`: MetadataPolicy` (all three sources enabled, defaults as above), `public static let disabled: MetadataPolicy` (empty `enabledSources`, all booleans `false`, otherwise same defaults — disabled is an explicit no-op, NOT nil).
  - [ ] 1.7 Declare `public struct MetadataBPMEvidence: Sendable` in the same file with fields per AC #3. Add `///` doc comments on every field.

- [ ] **Task 2: Wire the policy into AudioAnalysisService.Options and AudioAnalysisResult** (AC: #2, #3, #4, #16)
  - [ ] 2.1 Add `public var metadataPolicy: MetadataPolicy = .default` to `AudioAnalysisService.Options`. Preserve the empty `public init() {}` pattern — users mutate `opts.metadataPolicy = .disabled` to opt out.
  - [ ] 2.2 Add `public let metadataEvidence: [MetadataBPMEvidence]` to `AudioAnalysisResult`. Initialize to `[]` in the default no-metadata path so existing call sites compile cleanly.
  - [ ] 2.3 Update the `AudioAnalysisResult` initializer invocation inside `AudioAnalysisService.analyzeBPM` to pass `metadataEvidence: evidence` (empty array when policy is `.disabled`).
  - [ ] 2.4 Add inline `///` doc on `Options.metadataPolicy` explaining default-on behavior and the `.disabled` opt-out. Add inline `///` doc on `AudioAnalysisResult.metadataEvidence` explaining emptiness conditions.

- [ ] **Task 3: Implement FileMetadataReader with direct container parsing** (AC: #5, #6, #7, #8)
  - [ ] 3.1 Create `Sources/BoomBoomBoomKit/FileMetadataReader.swift`, standard header. Declare `internal enum FileMetadataReader` (caseless namespace, same pattern as `MelFilterbank`).
  - [ ] 3.2 Declare an internal `FoundTag: Sendable` struct with `source: MetadataSource`, `rawString: String`, `parsedBPM: Double`, `rejectionReason: String?`.
  - [ ] 3.3 Implement `static func readTags(from url: URL, policy: MetadataPolicy) -> [FoundTag]` — dispatches on the file's extension (`.mp4`/`.m4a` → tmpo; `.mp3`/`.aiff` → ID3 TBPM; `.flac` → Vorbis). Returns `[]` for unsupported extensions (`.wav`, `.caf`). Never throws — metadata absence is not an error.
  - [ ] 3.4 Implement `private static func readITunesTmpo(from url: URL) -> FoundTag?` — opens the file with `FileHandle(forReadingFrom: url)`, walks the MP4 atom tree `moov` → `udta` → `meta` → `ilst`, finds child atom `tmpo`, reads its 16-bit big-endian `Int` value. MP4 atoms are `[4-byte big-endian size][4-byte fourCC type][payload]`. Handle 64-bit extended sizes (size == 1) by reading the next 8 bytes. Return nil if any atom missing. Parse the `ilst` item's type/data sub-atoms: the integer value sits in a `data` atom with 16 bytes of header followed by the int16.
  - [ ] 3.5 Implement `private static func readID3TBPM(from url: URL) -> [FoundTag]` — reads the first 10 bytes to check for `"ID3"` magic + version + flags + synchsafe size. Reads the tag body, walks frames: each frame is `[4-byte ASCII ID][4-byte size — synchsafe in ID3v2.4, regular in v2.3][2-byte flags][payload]`. For each `TBPM` frame: read encoding byte (first byte of payload), decode remaining bytes accordingly, strip terminators. Return ALL `TBPM` frames found (multiple frames are allowed and must be reported for intra-file-conflict detection per AC #10).
  - [ ] 3.6 Implement `private static func readVorbisBPM(from url: URL) -> FoundTag?` — opens the FLAC file, validates `"fLaC"` magic. Walks the metadata block sequence: each block is `[1-byte header (type + last-flag)][3-byte big-endian length][payload]`. Block type 4 is Vorbis comment. Parse the Vorbis comment payload: `[4-byte little-endian vendor length][vendor string][4-byte little-endian comment count]` then `[4-byte LE length][UTF-8 "KEY=VALUE" string]` repeated. Key match is case-insensitive for `"BPM"`.
  - [ ] 3.7 Implement `static func parseRawBPM(_ raw: String, policy: MetadataPolicy) -> (parsed: Double, rejectionReason: String?)` — applies parsing hygiene per AC #8: BOM/whitespace strip, locale comma, range midpoint, non-numeric reject. Returns `(Double.nan, reason)` for rejections so callers emit evidence with `rejectionReason` set.
  - [ ] 3.8 After per-source parsing, filter by `policy.valueRange` and policy-enabled parsing flags. Convert each `FoundTag` with `rejectionReason == nil` into a valid candidate; retain rejections for trace emission.

- [ ] **Task 4: Wire reader into AudioAnalysisService and build evidence** (AC: #2, #4, #9, #10, #16)
  - [ ] 4.1 In `AudioAnalysisService.analyzeBPM(url:options:)`, after the early cancellation check but before the PCM read, add: `let foundTags: [FoundTag] = options.metadataPolicy.enabledSources.isEmpty ? [] : FileMetadataReader.readTags(from: url, policy: options.metadataPolicy)`. The empty-check short-circuits the `.disabled` case to zero I/O per AC #4.
  - [ ] 4.2 Compute consensus: if exactly one valid (non-rejected) found tag → single-tag case. If ≥2 and all agree within `policy.consensusTolerance` (±0.5 BPM absolute) → unanimous consensus with `consensusBPM = mean`. If ≥2 and at least one pair disagrees → intra-file conflict (all tags rejected for decision, `rejectionReason == "intra-file-conflict"` on each).
  - [ ] 4.3 Build initial `[MetadataBPMEvidence]` entries from `foundTags`: each entry carries `source`, `rawValue`, `parsedBPM`, and (initially) `corroboratedWith = nil`, `ratioMatched = nil`, `boostApplied = 1.0`, `rejectionReason` reflecting parse-time state. The later merge step updates `corroboratedWith`/`ratioMatched`/`boostApplied`/`rejectionReason` based on DSP outcomes.
  - [ ] 4.4 Thread the `MetadataCorroborationInput` struct (private, contains `consensusBPM: Double?`, `participatingTags: [MetadataBPMEvidence]`, `conflictDetected: Bool`, and a reference to the policy) from the service into `CandidateMergeStrategy.merge` via a new parameter. The public `merge` overload keeps backward-compatible signature (default nil input → current behavior); the service passes the real input.

- [ ] **Task 5: Apply boost/penalty in CandidateMergeStrategy.merge** (AC: #11, #12, #13, #14, #15)
  - [ ] 5.1 Add a new private helper `static func applyMetadataCorroboration(to result: BPMResult, input: MetadataCorroborationInput, policy: MetadataPolicy) -> (BPMResult, [MetadataBPMEvidence])` in `CandidateMergeStrategy.swift`. This runs AFTER the normal merge produces a `BPMResult`, operating on its final `candidates` array and `bpm`/`confidence`.
  - [ ] 5.2 Corroboration check per AC #11, #12:
    - For each participating tag (including the single-tag case — treat the single tag as a degenerate "consensus" of one), test if the winning candidate `C` satisfies `abs(C - T) / T <= policy.corroborationTolerance` (default 0.03).
    - If not, test octave match via `policy.allowOctaveCorroboration`: candidate is double or half of `T` within the 1.92-2.08 ratio window used by `resolveOctaveAmbiguity`.
    - If not, test triplet match via `policy.allowTripletCorroboration` and Story 3.1's `HarmonicRatio` path. Until Story 3.1 ships, this branch returns `false` (stubbed).
    - On corroboration: apply `confidence = min(policy.maxBoostedConfidence, confidence * policy.corroborationBoost)`. Update evidence with `corroboratedWith`, `ratioMatched`, `boostApplied = result.confidence / prevConfidence`.
  - [ ] 5.3 Unanimous-disagrees penalty per AC #14: if `input.consensusBPM != nil` (unanimous consensus) AND no candidate in the merge pool corroborates at any allowed ratio, multiply the winning candidate's confidence by `policy.skepticismPenalty` (default 0.85). Mark every participating evidence entry with `rejectionReason == "dsp-disagreement"`, `boostApplied = 0.85`.
  - [ ] 5.4 Single-uncorroborated per AC #15: if only one tag and it does not corroborate, leave confidence unchanged. Evidence entry gets `rejectionReason == "uncorroborated-single-tag"`, `boostApplied = 1.0`.
  - [ ] 5.5 Intra-file conflict per AC #10 / `input.conflictDetected == true`: skip all corroboration. Every evidence entry already has `rejectionReason == "intra-file-conflict"`.
  - [ ] 5.6 The merge strategy boost hook is called from `CandidateMergeStrategy.merge` after the existing strategy switch returns its result, before `merge` itself returns. Pass the updated `[MetadataBPMEvidence]` out via an additional return tuple field OR (cleaner) stash it on the `BPMResult` trace if `enableTrace: true` and let the service extract both.

- [ ] **Task 6: Extend BPMDiagnosticTrace** (AC: #18)
  - [ ] 6.1 Add public fields to `BPMDiagnosticTrace`: `public var metadataEvidenceBeforeBoost: [MetadataBPMEvidence] = []`, `public var candidatesBeforeBoost: [(bpm: Double, score: Float)] = []`, `public var candidatesAfterBoost: [(bpm: Double, score: Float)] = []`, `public var metadataPolicyUsed: MetadataPolicy = .default`. All have `///` doc comments.
  - [ ] 6.2 Populate the trace fields in `CandidateMergeStrategy.applyMetadataCorroboration` when `enableTrace` was true (threaded via the input struct).
  - [ ] 6.3 Ensure the trace's existing `confidence` field reflects the post-boost/post-penalty confidence (not the pre-boost value) — consistent with the existing "`confidence` is the final returned value" semantic.

- [ ] **Task 7: Tests** (AC: #5, #6, #7, #8, #9, #10, #11, #12, #13, #14, #15, #16, #17, #20)
  - [ ] 7.1 Create `Tests/BoomBoomBoomKitTests/FileMetadataReaderTests.swift`. Use Swift Testing. Cover parser correctness per format, hygiene rules, and rejection paths (sentinel-zero, out-of-range, non-numeric, intra-file-conflict).
    - Fixture M4A with `tmpo = 128` → `parsedBPM == 128.0`, `source == .iTunesTmpo`.
    - Fixture M4A with `tmpo = 0` → no evidence emitted (or evidence with `rejectionReason == "sentinel-zero"` depending on policy — align with AC #8).
    - Fixture MP3 with `TBPM = "128"` → `parsedBPM == 128.0`, `source == .id3TBPM`.
    - Fixture MP3 with `TBPM = "128,5"` → `parsedBPM == 128.5` (locale comma).
    - Fixture MP3 with `TBPM = "120-125"` → `parsedBPM == 122.5` (range midpoint).
    - Fixture MP3 with `TBPM = "fast"` → rejected with `rejectionReason == "non-numeric"`.
    - Fixture MP3 with `TBPM = "500"` → rejected with `rejectionReason == "out-of-range"`.
    - Fixture MP3 with two `TBPM` frames `128` and `130` → intra-file-conflict (both rejected).
    - Fixture FLAC with `BPM=175` in Vorbis comment → `parsedBPM == 175.0`, `source == .vorbisBPM`.
    - Fixture WAV with no tags → empty result.
  - [ ] 7.2 Fixture generation: prefer checking in small pre-tagged binary fixtures under `Tests/BoomBoomBoomKitTests/Fixtures/metadata/` (one per format, ~5-20 KB each). Generate with `ffmpeg`/`mp4box`/`metaflac` at fixture-creation time, commit the binaries. Document the generation commands in `Tests/BoomBoomBoomKitTests/Fixtures/metadata/README.md`. Avoid at-test-time generation — it's fragile and slows tests.
  - [ ] 7.3 Create `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift`. Integration tests against `AudioAnalysisService.analyzeBPM` using the new fixtures plus synthetic click tracks from `TestSignalGenerators`. Cover:
    - **testDefaultEnablesMetadata**: default `Options` → metadata read, evidence populated on tagged fixture.
    - **testDisabledPolicyNoIO**: `metadataPolicy = .disabled` → evidence empty. Assert byte-identical `bpm`/`confidence`/`candidates` against a snapshot of the pre-story output on the same fixture (regression guard per AC #4).
    - **testSameTempoCorroborationBoostsConfidence**: synthetic 128 BPM click + tag=128 + DSP detects 128 → confidence boosted (≤ 0.95), `corroboratedWith == 128.0`, `ratioMatched == nil`, `boostApplied > 1.0`.
    - **testOctaveCorroboration**: synthetic 128 BPM click + tag=64 + DSP detects 128 → corroborated via `.half` ratio, confidence boosted.
    - **testUnanimousConsensus**: fixture with tmpo=128 AND TBPM=128 + DSP detects 128 → unanimous consensus, both evidence entries corroborated.
    - **testIntraFileConflict**: fixture with tmpo=128 AND TBPM=140 + DSP detects 128 → both tags rejected with `"intra-file-conflict"`, no boost applied to DSP candidate.
    - **testUnanimousDisagreesWithDSPApplyPenalty**: fixture with tmpo=128 AND TBPM=128 + DSP detects 140 (no ratio match) → DSP value 140 returned, confidence × 0.85, evidence entries marked `"dsp-disagreement"`.
    - **testSingleUncorroboratedTagIgnored**: fixture with only tmpo=200 + DSP detects 128 (no ratio match) → confidence unchanged, evidence marked `"uncorroborated-single-tag"`.
    - **testFastestIntensityStillReadsMetadata**: `intensity = .fastest` on tagged fixture → evidence populated.
    - **testTVRFixtureHasTmpoAtom** (AC #20): explicit reference test against the OA300 `03 TVR.m4a` fixture under the `Bad BPM/` subfolder. Env-gate behind `OA300_CORPUS_PATH` (same pattern as `OA300BenchmarkTests`). Document the ground-truth `tmpo` atom value in a code comment.
  - [ ] 7.4 Add a regression-guard test that asserts `DSPTechnique.allCases.count == 6` and `TechniqueSet.allDSPCombinations().count == 64` (AC #17). Put it in `AblationSmokeTests.swift` or a new `ArchitectureInvariantsTests.swift`.

- [ ] **Task 8: Validation and benchmark breakdown** (AC: #19, #21)
  - [ ] 8.1 `make fmt` + `make lint` — clean. Resolve any new warnings in the new files.
  - [ ] 8.2 `make build` — compiles cleanly on `swift build -c debug` and `swift build -c release`.
  - [ ] 8.3 `make test` — all existing + new tests pass in parallel.
  - [ ] 8.4 `make benchmark` — OA300 Acc1/Acc2 integer counts ≥ Task 0 baselines. Also add a "Tagged-subset breakdown" section to `OA300BenchmarkTests.benchmarkAcc1*` output: count the `result.metadataEvidence.count > 0` tracks and bucket them into (corroborated-same-tempo, corroborated-octave, intra-file-conflict, dsp-disagreement, uncorroborated). This is a reporting addition, not a gate.
  - [ ] 8.5 `make benchmark-giantsteps` — Acc1/Acc2 ≥ Task 0 baselines.
  - [ ] 8.6 `make ablation` — matrix completes, count is 64 (guarded by Task 7.4).
  - [ ] 8.7 `make perf-benchmark` — mean/median/p95 drift from Task 0 baseline ≤ 10%. Record the new timing in Completion Notes as the post-story perf baseline.
  - [ ] 8.8 Update CLAUDE.md "Key Types" section: add entries for `MetadataPolicy`, `MetadataSource`, `MetadataBPMEvidence`, `HarmonicRatio`, and mention the new `AudioAnalysisResult.metadataEvidence` field.
  - [ ] 8.9 Run `make oracle` (three-way DAW comparison) — capture the `03 TVR.m4a` behavior explicitly. Document in Completion Notes whether metadata corroborated the DAW oracle or DSP.

## Dev Notes

### Why NOT a DSPTechnique case

`DSPTechnique` is a closed enum of sample-domain signal-processing transformations — each case corresponds to a gated code path inside `BPMAnalyzer.estimateBPM` that operates on `[Float]` samples. Metadata reading is a pre-analysis input-source concern, orthogonal to the DSP pipeline. Adding `.metadataHint` would (a) double the ablation matrix to 2^7=128 for a non-DSP signal, (b) corrupt the semantic meaning of `DSPTechnique.allCases`, and (c) still require a sideband config struct to carry per-source rules because enum cases can't carry rich associated values while remaining `CaseIterable + Hashable`. The decision: keep `DSPTechnique` pure; expose metadata as `AudioAnalysisService.Options.metadataPolicy` with a rich struct. This mirrors Story 3.4 (duration-derived BPM hint), which is likewise NOT a `DSPTechnique` case.

### Why the boost lives in CandidateMergeStrategy.merge, not BPMAnalyzer step 10

Metadata is read once per file. `BPMAnalyzer.estimateBPM` runs once per analysis window (intensity 6+ runs 3 windows: 30s/60s/90s). If the boost applied inside step 10 it would either have to be threaded through every window call or re-read per window — both redundant. `CandidateMergeStrategy.merge` is the natural place: it runs once per file, after all window candidates are collected, before the final BPM is chosen. This is also where the user-directed "quorum decider" semantics live (the existing `.quorum`, `.windowVoting`, etc. strategies). Applying the boost here composes cleanly with every merge strategy.

### Why direct container parsing, not AVFoundation

`AVAsset.commonMetadata` and `AVMetadataItem.metadataItems(from:filteredByIdentifier:)` are the modern Swift-concurrent APIs but carry two concrete problems for this library: (1) FLAC Vorbis-comment surfacing on macOS is historically inconsistent — the user reports it works on some files and silently returns nothing on others, and the failure mode is unobservable; (2) `AVAsset` metadata loading is async, forcing either an async `analyzeBPM` entry point (breaks the sync contract) or a `semaphore.wait()` inside the sync path (anti-pattern under Swift 6 strict concurrency). Direct parsing is ~150 LOC across three formats (MP4 tmpo ~40 LOC, ID3 TBPM ~60 LOC, FLAC Vorbis ~50 LOC), has zero AVFoundation deprecation exposure, stays fully synchronous, and gives deterministic FLAC behavior. Trade-off: we own the parser code; the formats are stable and the parsers are small.

### Container-format parsing pitfalls

**MP4 `tmpo` atom:**
- Atom header is `[4-byte big-endian size][4-byte fourCC type]`. If size == 1, the next 8 bytes are the real 64-bit big-endian size (handle this).
- The `tmpo` atom is inside `moov/udta/meta/ilst/tmpo`. The `meta` atom has a 4-byte version/flags field before its children — skip it.
- `tmpo` under `ilst` is actually a container holding a `data` sub-atom. The `data` atom payload is `[4-byte type][4-byte locale][payload]`. For `tmpo`, the payload is a 2-byte big-endian int16.
- Always check atom size ≥ 8 (header minimum) to avoid infinite loops on malformed files.

**ID3v2 TBPM frame:**
- Header is `"ID3"` + `[1 version][1 revision][1 flags][4-byte synchsafe size]`. Synchsafe: each byte contributes 7 bits, high bit always 0. Decode: `size = (b0<<21) | (b1<<14) | (b2<<7) | b3`.
- In ID3v2.3, frame sizes are regular 32-bit big-endian integers. In ID3v2.4, they're synchsafe. Check the header version byte.
- `TBPM` payload: first byte is the text encoding. `0x00 = ISO-8859-1`, `0x01 = UTF-16 with BOM`, `0x02 = UTF-16BE without BOM`, `0x03 = UTF-8`. Decode remaining bytes accordingly.
- Text frames may have trailing null terminators (`\0` for single-byte encodings, `\0\0` for UTF-16). Strip them.
- Multiple `TBPM` frames are spec-violations but common in real files. Return ALL of them so AC #10 can detect conflict.

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

Triplet-ratio corroboration (tag=120, DSP=180, ratio 2:3) requires the `HarmonicRatio` resolution path from Story 3.1. Until 3.1 ships, the triplet corroboration check is a stub that always returns `nil`. `MetadataPolicy.allowTripletCorroboration` defaults to `false` so this dependency is explicit and the stub behavior is the documented default. When 3.1 lands, a follow-up micro-story flips the default to `true` and re-runs benchmarks.

Octave corroboration (2:1, 1:2) uses the existing `resolveOctaveAmbiguity` ratio window (1.92-2.08) and ships active in this story. `MetadataPolicy.allowOctaveCorroboration` defaults to `true`.

### Tagged-subset benchmark breakdown (AC #19)

`OA300BenchmarkTests` should grow a reporting block that partitions the corpus by metadata outcome:
```
=== Tagged-subset breakdown ===
  Tracks with metadata read:       N / 300
    Corroborated (same-tempo):     A
    Corroborated (octave ratio):   B
    Corroborated (triplet ratio):  C  (stub — always 0 until Story 3.1)
    Intra-file conflict:           D
    DSP disagreement (unanimous):  E
    Uncorroborated (single tag):   F
```
This is not a gate — it's observability. The gate is `Acc1/Acc2 >= pre-story baseline`. The breakdown lets us see whether metadata is helping (corroborated bins growing, DSP-disagreement bin small) or hurting (DSP-disagreement bin large, indicating widespread tag-DSP mismatch that might signal a bug or a tag-quality problem in the corpus).

### Regression-guard strategy

The strongest regression guard is AC #4's byte-identical requirement: with `metadataPolicy = .disabled`, the pipeline output must match the pre-Story-3.6 output on any input exactly. If Task 8.4 shows any drift on OA300 or GiantSteps with `.disabled`, it means Story 3.6 changed DSP behavior via an unintended side effect (e.g., a change to merge-strategy sort order, a float precision issue). That's a blocker — fix before proceeding.

The softer guard is `metadataPolicy = .default` on OA300 maintains Acc1/Acc2 ≥ baseline. The expectation is neutral-to-positive movement: the tagged subset gets a small boost from correct tags, while wrong tags get filtered out by the corroboration rule. A regression here is a sign the tolerance or boost magnitude is mis-tuned — first action is to compare the tagged-subset breakdown to isolate which tracks shifted.

### Out-of-scope for this story

- **Caller-supplied external BPM hints.** The public API takes `url: URL`, so external callers cannot pass pre-computed BPM values as hints. If a future story adds a byte-stream `analyzeBPM(samples:sampleRate:)` entry point, that would be the natural place to accept `externalHints: [BPMHint]`. Do not build the `BPMHint` primitive now.
- **Per-source tier weights.** The design explicitly rejects per-source weights (`Rekordbox = 0.8`, `iTunes = 0.5`, etc.) because there is no way to detect the writing tool from the tag itself. All enabled sources are peer; agreement across sources is the trust signal.
- **Writing metadata back.** Read-only. This library does not modify audio files.
- **OGG container support.** Not a supported input format. Vorbis-inside-FLAC is; Vorbis-inside-OGG is not.
- **New merge strategies.** Existing 8 `CandidateMergeStrategy` cases are untouched. The boost hook runs after whichever strategy was selected.

### Project Structure Notes

- All new source files go under `Sources/BoomBoomBoomKit/` (the library target). No changes to `BoomBoomBoomKitTestSupport` or `Package.swift` target layout.
- `FileMetadataReader` is `internal`. `MetadataPolicy`, `MetadataSource`, `HarmonicRatio`, and `MetadataBPMEvidence` are `public` (they appear on `Options` / `AudioAnalysisResult`).
- Test fixtures go under `Tests/BoomBoomBoomKitTests/Fixtures/metadata/` — committed binary files with a `README.md` documenting generation commands.
- The `03 TVR.m4a` reference test is env-gated behind `OA300_CORPUS_PATH` (same pattern as other corpus tests).
- Branch/distribution: this work stays on `develop` alongside the library source. When squash-merging to `main`, the standard "AI tooling exclusion" applies — `_bmad/`, `_bmad-output/`, `.claude/` are stripped. Library-only files (`Sources/`, `Tests/`, `Package.swift`, etc.) ship to `main` as usual. No AI-tooling coupling in the new source.

### References

- **Epic 3 parent**: [epics.md#epic-3-dsp-accuracy-improvement](../planning-artifacts/epics.md) — Story 3.6 added after 3.5.
- **Dependency (future)**: Story 3.1 "Harmonic Ratio Detection" — provides `HarmonicRatio` for triplet corroboration. Stubbed in this story.
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

_TBD — populated by dev-story workflow._

### Debug Log References

_TBD._

### Completion Notes List

_TBD — Task 0 baselines go here first, then incremental notes per task._

### File List

_TBD — populated as tasks complete. Expected:_

- Sources/BoomBoomBoomKit/MetadataPolicy.swift (new)
- Sources/BoomBoomBoomKit/FileMetadataReader.swift (new)
- Sources/BoomBoomBoomKit/AudioAnalysisService.swift (modified)
- Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift (modified)
- Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift (modified)
- Sources/BoomBoomBoomKit/AudioAnalysisResult.swift or AudioAnalysisService.swift (AudioAnalysisResult struct modified)
- Tests/BoomBoomBoomKitTests/FileMetadataReaderTests.swift (new)
- Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift (new)
- Tests/BoomBoomBoomKitTests/ArchitectureInvariantsTests.swift (new, or added to existing)
- Tests/BoomBoomBoomKitTests/Fixtures/metadata/ (new binary fixtures + README)
- Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift (modified — tagged-subset breakdown)
- CLAUDE.md (modified — Key Types section)
