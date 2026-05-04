# Story 3.6b: Metadata Parser Hardening + AC #4 Drift-Resistant Test

Status: review
**Depends on:** none (independent — can be picked up any time after Story 3-6 done)

## Story

As a library consumer relying on `MetadataPolicy.default` to read embedded BPM tags safely across the wild variety of real-world taggers,
I want the ID3v2 and MP4 parsers to validate every structural pre-condition before walking variable-length payloads (so malformed tags can never silently corrupt downstream evidence) and the AC #4 byte-equality regression test to share a single pre-corroboration pipeline with the service (so future service refactors cannot make the test pass for the wrong reason),
So that Story 3-6's "DSP-first honesty" contract holds against pathological inputs and the regression guard is anchored to the actual service code rather than a hand-replicated copy.

## Background

Story 3.6 (`done` as of 2026-05-02, SHA `03acccd`) shipped four byte-level container parsers for embedded BPM tags (`tmpo`, ID3v2 `TBPM`, Vorbis `BPM=`) plus a corroboration layer that boosts/penalizes DSP candidates. A two-pass code review (Codex gpt-5.5 + claude-opus-4-7) returned six patches, all applied. The patches landed correctly, but **the review process exposed three follow-up gaps that the code-review patches did not close** plus **one test-design concern** the patches partially addressed:

1. **Extended-header minimum-size validation is missing.** The code-review patch fixed the v2.3 extended-header skip arithmetic (`idx += 4 + extSize` instead of `idx += extSize`) so v2.3 ext-headers with the canonical sizes `6` and `10` walk correctly. But neither parser branch validates that `extSize` falls within the spec-permitted range. A malformed v2.3 header carrying `extSize = 2` or a v2.4 header carrying synchsafe-size `4` is currently silently accepted — the code skips a too-short range and lands somewhere mid-frame, where the all-zero-frame-ID padding rule (`Sources/BoomBoomBoomKit/FileMetadataReader.swift:271`) eventually breaks the walk and returns `[]`, but **the failure mode is "silent empty result instead of evidence" rather than "explicit reject."** This is functionally equivalent today (no tag → no boost → DSP unchanged), but it leaves the door open for a future hardening regression where the empty-result path becomes load-bearing.

2. **No CRC-flag test for v2.3 extended headers.** Per id3.org/id3v2.3.0 §3.2, the v2.3 extended-header size is `6` (canonical) OR `10` (when bit 7 of the first ext-flag byte signals a 4-byte CRC follows). The code-review patch's test suite covers `extSize=6` only. The `4 + extSize` arithmetic is correct for both cases (reads as `4 + 10 = 14` for the CRC variant), but **no test actually exercises the CRC path**. If a future refactor regresses the +4 to a literal `+10` (or to `+4 + min(extSize, 6)`), the existing tests would still pass.

3. **v2.3 footer-flag is not rejected.** ID3v2.3 reserves bit 4 of the tag-header flags byte; v2.4 defines bit 4 as the footer-present flag. The current parser at `Sources/BoomBoomBoomKit/FileMetadataReader.swift:181` rejects unsync (bit 7) and skips the extended header (bit 6) but does not check bit 4. A v2.3 file with bit 4 set is malformed per spec; a v2.4 file with bit 4 set has a 10-byte footer at the end of the tag body that the current parser would walk INTO as if it were a frame. Both should reject early. (In practice this is rare — most taggers don't write footers — but the parser hardening contract is "every spec-defined flag is handled or explicitly rejected.")

4. **AC #4 disabled-policy test depends on a hand-replicated pre-corroboration pipeline.** Story 3-6 code-review Patch #4 strengthened the AC #4 byte-equality test from "evidence is empty" to "evidence is empty AND `bpm`/`confidence`/per-candidate `bitPattern` match a baseline run." The baseline run is computed by `analyzePreMetadataPipeline` in `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift:163-205`, a private test helper that hand-replicates the service's pre-corroboration pipeline (PCMBufferReader → window loop → `BPMAnalyzer.estimateBPM` → `CandidateMergeStrategy.merge`). Both Codex and claude-opus-4-7 flagged this helper as **drift-prone**: any future service-side change (a new pre-merge step, a parameter reorder, etc.) would require dual edits, OR the test would fail-for-the-wrong-reason, OR the test would silently pass while the service does something different. The right fix is to expose the pre-corroboration pipeline as a single `static` helper on `AudioAnalysisService` and have the test invoke the same helper the service does — single source of truth, no drift possible. (Note: the secondary review further refined the helper signature; see §37 below.)

This story addresses all four. No DSP behavior changes; no merge-strategy changes; no public-API additions. The new internal helper `runPreCorroborationPipeline` and its return-type struct `PreCorroborationOutput` are both default-internal access (no `internal` keyword) and `Sendable`. Accuracy floors hold byte-for-byte.

### Secondary review pass (2026-05-02, post-authoring)

Before implementation, the story underwent a secondary review (Codex gpt-5.5 + a four-persona BMad roundtable: Amelia/dev, Winston/architect, Siri/Apple-platforms, Mary/analyst). The pass surfaced four additional gaps and refined three policy decisions. All findings are now folded into the ACs and Dev Notes below:

5. **Extended-header upper-bound check is missing.** AC #1/#2's minimum-size guards (`extSize >= 6`) catch under-sized headers but not over-sized ones (`extSize > body.count`). Today the over-sized case is caught downstream by `guard idx <= count` at `Sources/BoomBoomBoomKit/FileMetadataReader.swift:264` — same "silent empty result" failure mode as the under-sized case. The hardening contract requires explicit upstream rejection: `extSize >= 6 && extSize <= count - idx`.
6. **CRC-flag mismatch in the OTHER direction is uncovered.** AC #3 covers `extSize=10 + CRC flag set` (canonical CRC variant). It does not cover `extSize=10 + CRC flag CLEAR` (the spec-conformant size-only variant) or pin the lenient policy explicitly for both mismatch directions. The lenient policy (trust size, ignore flag) must be tested in both directions to prevent a future regression that special-cases one direction.
7. **TBPM frame flags are unhandled.** ID3v2.3 §3.3.1 defines per-frame flags including compression (bit 7 of frame-flags byte 2: `0x80`), encryption (bit 6: `0x40`), and grouping identity (bit 5: `0x20`). When set, these prepend additional fields BEFORE the frame text payload. The current parser at `Sources/BoomBoomBoomKit/FileMetadataReader.swift:290-296` ignores these flags entirely and decodes the raw payload as text, which produces silent garbage evidence for compressed/encrypted/grouped TBPM frames. This is a spec-correctness footgun the parser-hardening contract must close.
8. **Footer-flag policy decision was strict-reject; the secondary review recommends accept-and-continue.** Per ID3v2.4 §3.1 + §3.4, the v2.4 footer-present flag declares a 10-byte footer appended at end-of-tag-body. Crucially, the synchsafe `tagBodySize` field is footer-EXCLUSIVE per spec, so the existing `fh.read(upToCount: tagBodySize)` at `Sources/BoomBoomBoomKit/FileMetadataReader.swift:184` already reads the correct boundary. The footer sits outside the body the walker sees. Original AC #4 rejected v2.4-with-footer to avoid implementing footer-aware walking; the secondary review notes that "rejecting" actually rejects spec-compliant tags whose body is already correctly bounded by the existing read, with zero adversarial-surface gain. AC #4 is rewritten to: reject v2.3-with-bit-4-set (reserved/malformed per §3.1) AND accept v2.4-with-footer-flag-set (walking the body normally, since the footer is outside the slice).

Test-count target also corrected: actual current `@Test(` count is 287 (verified by `grep -rE '@Test\(' Tests/BoomBoomBoomKitTests/ | wc -l`); AC #1-#4 plus new AC #8 produce ≥ 12 new tests minimum. Story now targets monotonic increase rather than a fixed floor (see AC #7).

Helper signature decision (AC #5): the secondary review took the position that returning a struct `{result: BPMResult?, metadataInput: MetadataCorroborationInput}` better encodes the service's actual orchestration order (cancellation → metadata read → duration read → PCM read → window loop → merge → corroboration) as a structural invariant rather than a comment-level convention. The plain `BPMResult?` signature would force the service to keep building `metadataInput` adjacent to the call but disconnected from it. Story now prescribes the struct return.

## Acceptance Criteria

1. **Given** the v2.4 ID3 extended-header parse path (`Sources/BoomBoomBoomKit/FileMetadataReader.swift:247-264`)
   **When** a tag declares an extended-header synchsafe size that is either strictly less than 6 OR strictly greater than the remaining body length (`count - idx`)
   **Then** the parser returns `[]` (rejects the entire tag) instead of skipping a malformed range and continuing
   **And** unit tests in `FileMetadataReaderTests.swift` construct v2.4 files with:
     - `extSize ∈ {0, 4, 5}` (under-sized) — assert `tags.isEmpty`
     - `extSize` set to a value greater than the body length (e.g., `extSize = 32` with a 12-byte body of frame data) — assert `tags.isEmpty`
   **Spec ref:** id3.org/id3v2.4.0-structure §3.2 — "the extended header size [...] can thus never have a size of fewer than six bytes."

2. **Given** the v2.3 ID3 extended-header parse path
   **When** a tag declares an extended-header BE32 size that is not in the spec-permitted set `{6, 10}` OR a size that exceeds the remaining body length
   **Then** the parser returns `[]` (rejects the entire tag)
   **And** unit tests construct v2.3 files with:
     - `extSize ∈ {0, 4, 5, 7, 11, 100}` (size not in `{6, 10}`) — assert `tags.isEmpty` for each
     - `extSize = 10` but body too short to contain `4 + 10 = 14` extended-header bytes plus minimum frame — assert `tags.isEmpty`
   **Spec ref:** id3.org/id3v2.3.0 §3.2 — "the extended header size [...] is currently 6 or 10 bytes, excluding itself."

3. **Given** the v2.3 ID3 extended-header parse path
   **When** a tag declares `extSize = 10` with the CRC flag (bit 7 of the first ext-flag byte) set, followed by 4 bytes of CRC data, then a valid `TBPM` frame
   **Then** the parser correctly skips the full `4 + 10 = 14`-byte extended-header region and parses the `TBPM` frame
   **And** a unit test asserts `tags.count == 1` with the expected `parsedBPM`.
   **And** the parser implements a **lenient** mismatch policy in BOTH directions, pinned by tests:
     - `extSize = 6` with CRC flag SET (under-sized for declared CRC, but size is the load-bearing field) — parser walks 4 + 6 = 10 bytes and reads any TBPM frame that follows; test asserts `tags.count == 1` with expected `parsedBPM`.
     - `extSize = 10` with CRC flag CLEAR (over-sized vs declared no-CRC, but again size is load-bearing) — parser walks 4 + 10 = 14 bytes; test asserts `tags.count == 1` with expected `parsedBPM`.
   **Rationale (also documented in code comment):** the parser walks by the size field, not by the flag claim. The flag is informational metadata about CRC presence; trusting it would require a second size source disagreeing with the first. Many real-world v2.3 taggers can produce mismatch in either direction; rejecting on mismatch costs recall for zero parser-correctness gain. **This is a policy choice, not a spec-validity assertion** — a strict-conformance parser would reject both mismatches; we explicitly choose lenient.

4. **Given** the ID3 tag-header flags byte at `Sources/BoomBoomBoomKit/FileMetadataReader.swift:181` (and the matching AIFF embedded-tag path at `:228`)
   **When** bit 4 of `flags` is set
   **Then** behavior is version-specific:
     - **v2.3:** bit 4 is reserved per id3.org/id3v2.3.0 §3.1 ("These flags MUST be cleared"). Parser returns `[]` (rejects malformed tag).
     - **v2.4:** bit 4 is the footer-present flag per id3.org/id3v2.4.0-structure §3.1. The 10-byte footer per §3.4 sits AFTER the tag body; the synchsafe `tagBodySize` field is footer-EXCLUSIVE, so the existing `fh.read(upToCount: tagBodySize)` at `:184` and `parseEmbeddedID3Tag` at `:230` already read the correct body boundary. Parser walks the body normally — the footer is outside the slice the walker sees.
   **And** unit tests cover:
     - `v23FooterFlagRejected` — v2.3 MP3 with bit 4 set; assert `tags.isEmpty`.
     - `v23AIFFFooterFlagRejected` — v2.3 via AIFF embedded-tag path; assert `tags.isEmpty`.
     - `v24FooterFlagAcceptedAndWalked` — v2.4 MP3 with bit 4 set + valid TBPM frame in body; assert `tags.count == 1` with expected `parsedBPM`.
     - `v24AIFFFooterFlagAcceptedAndWalked` — v2.4 via AIFF embedded-tag path with bit 4 set + valid TBPM frame; assert `tags.count == 1` with expected `parsedBPM`.
   **Implementation note:** the secondary review concluded that strict v2.4 footer rejection rejects spec-compliant tags whose body the parser already bounds correctly, for zero adversarial-surface gain. See Background §8 above for the full rationale.

5. **Given** Story 3-6's `analyzePreMetadataPipeline` test helper at `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift:163-205`
   **When** this story lands
   **Then** the helper is removed and replaced with a call to a new `static` method on `AudioAnalysisService`:
     ```swift
     struct PreCorroborationOutput: Sendable {
       let result: BPMResult?
       let metadataInput: MetadataCorroborationInput
     }

     static func runPreCorroborationPipeline(
       url: URL, options: Options
     ) throws -> PreCorroborationOutput
     ```
   The helper encapsulates the full ordered pre-corroboration sequence: cancellation check → metadata read (`buildMetadataInput`) → duration read → PCM read → window loop with cancellation/progress → `CandidateMergeStrategy.merge`. It returns BOTH the merged DSP result and the metadata input that production `analyzeBPM(url:options:)` will hand to `MetadataCorroborator.apply`.
   **And** the production `analyzeBPM(url:options:)` body becomes (approximately):
     ```swift
     let pre = try AudioAnalysisService.runPreCorroborationPipeline(url: url, options: options)
     guard let merged = pre.result else { return nil }
     let (corroborated, evidence) = MetadataCorroborator.apply(to: merged, input: pre.metadataInput)
     // ...build AudioAnalysisResult from corroborated + evidence
     ```
   **And** the disabled-policy test in `MetadataCorroborationTests.swift` calls `try AudioAnalysisService.runPreCorroborationPipeline(url:options: optsDisabled).result` for the baseline. (The test discards `metadataInput` because the disabled-policy assertion is precisely that metadata I/O produces no evidence.)
   **And** the `internal` access modifier is omitted (default access in Swift, per Apple's Swift language guide); the helper's intent is conveyed via doc-comment, not redundant annotation.
   **And** both call sites compile and produce identical bitPattern output to the pre-story pipeline (no DSP change).
   **Rationale:** `BPMResult?`-only would keep `metadataInput` construction adjacent to but disconnected from the helper, leaving the orchestration-order invariant as a comment-level convention. The struct return encodes the invariant structurally — a future refactor that reorders cancellation/metadata/duration would have to break the helper signature, not silently diverge from a shadow copy.

6. **Given** the existing benchmark and accuracy-floor protections
   **When** this story's changes ship
   **Then**
   - OA300 with `metadataPolicy=.default`: Acc1 ≥ 58/82 AND Acc2 ≥ 74/82 (expected byte-for-byte match to Story 3-6 close-out — the OA300 corpus contains zero malformed extended headers and zero TBPM frames with compression/encryption/grouping flags, so the parser-reject-path additions do not change behavior on this corpus).
   - OA300 with `metadataPolicy=.disabled`: Acc1 = 57/82 AND Acc2 = 73/82 (expected byte-for-byte match to pre-Story-3-6, the AC #4-disabled-baseline contract Story 3-6 established, now anchored to the actual `runPreCorroborationPipeline` helper).
   - GiantSteps with `metadataPolicy=.default`: Acc1 ≥ 537/661 AND Acc2 ≥ 546/661.
   - `make oracle` shows no regression.
   - The 5 OA300 tagged tracks identified in Story 3-6's tagged-subset breakdown produce identical evidence (4 corroborated same-tempo, 1 uncorroborated).
   - **Tolerance note:** "byte-for-byte match" refers to `bitPattern` equality of `bpm`, `confidence`, and per-candidate fields against the Story 3-6 close-out baselines. If a future macOS release changes `AVAudioFile.fileFormat.duration` arithmetic by one sample (the duration-hint dependency at `AudioAnalysisService.swift:222-226`), the disabled-policy bitPattern test in `MetadataCorroborationTests.swift` MAY drift legitimately. In that case, regenerate the baseline rather than mask drift with a tolerance — the bitPattern equality is intentionally strict so that environmental drift is loud, not silent.

7. **Given** AC #6's accuracy floors are strict-equality contracts on the parser-accept path
   **When** the parser-reject and parser-accept-on-footer path additions land (AC #1-#4 + #8)
   **Then** the test suite grows monotonically:
   - Current `@Test(` count (verified at story authoring): **287** (`grep -rE '@Test\(' Tests/BoomBoomBoomKitTests/ | wc -l`). This counts grep-visible declarations; Swift Testing parameterized cases inflate the runner-discovered count. The story uses the grep-visible count as the baseline.
   - Expected new tests by AC: AC #1 (≥ 4 cases: 3 under-sized + 1 over-sized), AC #2 (≥ 7 cases: 6 size-not-in-{6,10} + 1 over-sized), AC #3 (≥ 3 cases: canonical CRC + 2 mismatch policies), AC #4 (4 cases: v2.3+v2.4 × MP3+AIFF), AC #8 (≥ 3 cases: compression + encryption + grouping flags). Minimum new tests: **≥ 12**; pragmatic target: ~16-20.
   - Final post-story `@Test(` count: monotonically ≥ baseline + 12. No existing test removed unless replaced by AC #5's helper-refactor (the `analyzePreMetadataPipeline` private helper, ~1 test loses its hand-replicated baseline and gains a single-source-of-truth call into the new helper).

8. **Given** the TBPM frame parse path at `Sources/BoomBoomBoomKit/FileMetadataReader.swift:290-296`
   **When** a `TBPM` frame's per-frame flags byte 2 (the second of the two frame-header flag bytes after the 4-byte size field) has any of: bit 7 (`0x80`, compression), bit 6 (`0x40`, encryption), or bit 5 (`0x20`, grouping identity) set
   **Then** the parser MUST NOT decode the frame payload as raw text. It either:
     - **(a)** rejects the entire `TBPM` frame (does not append to `found`), continuing the walk to find any subsequent well-formed `TBPM` (recommended — preserves any duplicate well-formed frame), OR
     - **(b)** appends a `FoundTag` with `parsedBPM = .nan` and `rejectionReason = "frame-flag-unsupported"` (more aggressive — produces evidence of the rejection in `metadataEvidence`).
   The implementation chooses option **(a)** — silent skip of the malformed frame, walk continues. Rationale: this aligns with how the existing all-zero-frame-ID padding rule and non-ASCII-frame-ID guard already behave (they break the walk silently rather than emitting evidence). A future story can promote rejection to evidence-emitting if telemetry shows it matters.
   **Spec ref:** id3.org/id3v2.3.0 §3.3.1 — frame format flags byte 2 defines compression, encryption, grouping. ID3v2.4 §4.1 has equivalent flags at the same bit positions but with synchsafe-encoded data length prefixes. This story handles BOTH versions identically (skip-the-frame).
   **And** unit tests cover:
     - `v23TBPMCompressionFlagSkipped` — v2.3 with frame-flags `[0x00, 0x80]`; assert `tags.isEmpty` (no other TBPM in the test fixture).
     - `v23TBPMEncryptionFlagSkipped` — v2.3 with frame-flags `[0x00, 0x40]`; assert `tags.isEmpty`.
     - `v23TBPMGroupingFlagSkipped` — v2.3 with frame-flags `[0x00, 0x20]`; assert `tags.isEmpty`.
     - (Optional but recommended) `v24TBPMCompressionFlagSkipped` — v2.4 equivalent for parity coverage.

## Tasks / Subtasks

- [x] Task 1: Validate ID3 extended-header sizes — minimum AND upper bound (AC: #1, #2)
  - [x] 1.1: At `Sources/BoomBoomBoomKit/FileMetadataReader.swift:247-264`, after reading `extSize`, add a version-specific size check that validates BOTH lower and upper bounds BEFORE mutating `idx`:
    - v2.4: `guard extSize >= 6, extSize <= count - idx else { return [] }` (synchsafe size includes the 4-byte size field; 6 = size + 1-byte flag-count + 1-byte flags; upper bound prevents walking past body end).
    - v2.3: `guard extSize == 6 || extSize == 10 else { return [] }` THEN `guard 4 + extSize <= count - idx else { return [] }` (BE32 size excludes the 4-byte size field; 6 = flags + padding-size; 10 = + 4-byte CRC; upper bound includes the 4-byte size field that v2.3 omits from `extSize`).
  - [x] 1.2: New `FileMetadataReaderTests.swift` cases under `ID3TBPMTests`:
    - `v23ExtendedHeaderSizeNotInPermittedSet(_ extSize: UInt32)` parameterized over `[0, 4, 5, 7, 11, 100]` — all assert `tags.isEmpty`.
    - `v24ExtendedHeaderSizeTooSmall(_ extSize: UInt32)` parameterized over `[0, 4, 5]` — all assert `tags.isEmpty`.
    - `v24ExtendedHeaderSizeBeyondBody` — constructs v2.4 file with `extSize = 32` and a 12-byte body of frame data; asserts `tags.isEmpty`.
    - `v23ExtendedHeaderSizeBeyondBody` — constructs v2.3 file with `extSize = 10` but tag body too short to contain `4 + 10 = 14` bytes; asserts `tags.isEmpty`.
  - [x] 1.3: Builder modification: extend `ID3TBPMTests.makeMP3` to accept `extendedHeaderSizeOverride: UInt32? = nil`. (`extendedHeaderPayloadOverride` was deemed unnecessary — the v2.3 oversized case is constructed inline because the builder cannot truncate `tagBodySize` cleanly.) Default behavior unchanged.
  - [x] 1.4: Verify that the existing `v23ExtendedHeader` and `v24ExtendedHeader` happy-path tests still pass after the size guard lands (sanity: 6 is permitted; 10 with CRC is permitted in v2.3). All 46 parser tests passed.

- [x] Task 2: Add v2.3 CRC-flag test coverage with both-direction lenient policy (AC: #3)
  - [x] 2.1: Extend `ID3TBPMTests.makeMP3` at `Tests/BoomBoomBoomKitTests/FileMetadataReaderTests.swift:212` to support `crcFlag: Bool = false`. When set, the v2.3 builder writes ext-flags as `[0x80, 0x00]` (bit 7 of the first ext-flag byte set). Pair with `extSize = 10` for the canonical case, OR allow caller to explicitly mismatch via `extendedHeaderSizeOverride`.
  - [x] 2.2: New test `v23CRCFlagSkipsCorrectly` — builds a v2.3 file with `extSize = 10` + `crcFlag = true` + 4 bytes of CRC data + valid TBPM frame; asserts `tags.count == 1` with expected `parsedBPM`. Regresses if the `4 + extSize` arithmetic is replaced by a literal `+10` or `+14`.
  - [x] 2.3: New test `v23CRCFlagSetButSizeSix` — builds with `extSize = 6` + `crcFlag = true` (mismatch direction A: under-sized for declared CRC); asserts `tags.count == 1` with expected `parsedBPM`. Pins lenient policy: size wins.
  - [x] 2.4: New test `v23CRCFlagClearButSizeTen` — builds with `extSize = 10` + `crcFlag = false` + 4 bytes of "would-be CRC" + valid TBPM frame (mismatch direction B: over-sized for declared no-CRC); asserts `tags.count == 1` with expected `parsedBPM`. Pins lenient policy: size wins, ignored flag.
  - [x] 2.5: Document the lenient policy decision in a comment near the v2.3 extended-header branch in `FileMetadataReader.swift`. Wording: `// v2.3 ext-header: trust extSize as the load-bearing field; CRC flag (bit 7 of first ext-flag byte) is not consulted. Mismatch in either direction (size 6 with flag set, size 10 with flag clear) is accepted because the walker walks by size, not by flag claim.`

- [x] Task 3: Version-specific bit-4 handling (AC: #4)
  - [x] 3.1: At `Sources/BoomBoomBoomKit/FileMetadataReader.swift:181` (and the matching AIFF embedded-tag path at `:228`), add a version-conditional bit-4 check AFTER the existing unsync (`0x80`) reject:
    ```swift
    if versionMajor == 3, flags & 0x10 != 0 { return [] }
    ```
    Do NOT add a v2.4 reject. The existing `fh.read(upToCount: tagBodySize)` (MP3) and `parseEmbeddedID3Tag` body slice (AIFF) already exclude the footer bytes per the spec's footer-exclusive `tagBodySize` semantics.
  - [x] 3.2: Update doc-comment on `parseID3v2Body` to note the version-specific bit-4 handling and that v2.4 footer-flag tags walk the body normally (footer is outside the slice).
  - [x] 3.3: New tests in `ID3TBPMTests` and `AIFFID3Tests`:
    - `v23FooterFlagRejected` — v2.3 MP3 with bit 4 set; asserts `tags.isEmpty`.
    - `v23AIFFFooterFlagRejected` — v2.3 AIFF embedded-tag path with bit 4 set; asserts `tags.isEmpty`.
    - `v24FooterFlagAcceptedAndWalked` — v2.4 MP3 with bit 4 set + valid TBPM frame in body; asserts `tags.count == 1` with expected `parsedBPM`.
    - `v24AIFFFooterFlagAcceptedAndWalked` — v2.4 AIFF equivalent.
  - [x] 3.4: Builder modification: extend `ID3TBPMTests.makeMP3` and `AIFFID3Tests.makeAIFF` to accept `footerFlag: Bool = false`. When set, OR `0x10` into the tag-header flags byte.

- [x] Task 4: Refactor disabled-policy test to share pre-corroboration pipeline (AC: #5)
  - [x] 4.1: Add an internal struct on `AudioAnalysisService`:
    ```swift
    struct PreCorroborationOutput: Sendable {
      let result: BPMResult?
      let metadataInput: MetadataCorroborationInput
    }
    ```
  - [x] 4.2: Extract the pre-corroboration sequence into `static func runPreCorroborationPipeline(url:options:) throws -> PreCorroborationOutput`. No `internal` keyword (default). Throw semantics identical; `onProgress` callback timing preserved per-window.
  - [x] 4.3: Replace the inline pre-corroboration block in `analyzeBPM(url:options:)` with:
    ```swift
    let pre = try Self.runPreCorroborationPipeline(url: url, options: options)
    guard let merged = pre.result else { return nil }
    let (corroborated, evidence) = MetadataCorroborator.apply(to: merged, input: pre.metadataInput)
    ```
  - [x] 4.4: Delete `analyzePreMetadataPipeline` from `MetadataCorroborationTests.swift`. Update the `disabledPolicy` test to call `try AudioAnalysisService.runPreCorroborationPipeline(url: url, options: optsDisabled).result`.
  - [x] 4.5: Verify the `disabledPolicy` test still passes byte-for-byte. Confirmed — bitPattern equality holds.
  - [x] 4.6: Add a doc-comment on `runPreCorroborationPipeline` documenting the dual-call-site contract.

- [x] Task 5: Reject TBPM frame compression/encryption/grouping flags (AC: #8)
  - [x] 5.1: In `parseID3v2Body`, BEFORE the `if frameIDBytes == [0x54, 0x42, 0x50, 0x4D]` check, read the 2-byte frame-flags field and skip the frame entirely if unsupported payload-affecting format flags are set. v2.3 skips bits 7/6/5 of byte 2; v2.4 skips bits 6/3/2 of byte 2:
    ```swift
    let frameFlags1 = body[body.startIndex + idx + 9]
    let unsupportedFormatFlags: UInt8 = versionMajor == 4 ? 0x4C : 0xE0
    if frameFlags1 & unsupportedFormatFlags != 0 {
      idx = payloadEnd
      continue
    }
    ```
    Applies to both v2.3 (§3.3.1) and v2.4 (§4.1), with version-specific bit positions.
  - [x] 5.2: Builder modification: extend `ID3TBPMTests.makeMP3` to accept `frameFlags: [UInt8] = [0x00, 0x00]`. Replaced the fixed `frame.append(contentsOf: [0x00, 0x00])` with `frame.append(contentsOf: frameFlags)`.
  - [x] 5.3: New tests in `ID3TBPMTests`:
    - `v23TBPMCompressionFlagSkipped` — frame-flags `[0x00, 0x80]`; asserts `tags.isEmpty`.
    - `v23TBPMEncryptionFlagSkipped` — frame-flags `[0x00, 0x40]`; asserts `tags.isEmpty`.
    - `v23TBPMGroupingFlagSkipped` — frame-flags `[0x00, 0x20]`; asserts `tags.isEmpty`.
    - `v24TBPMCompressionFlagSkipped` — v2.4 compression bit (`0x08`) coverage.
    - `v24TBPMEncryptionFlagSkipped` — v2.4 encryption bit (`0x04`) coverage.
    - `v24TBPMGroupingFlagSkipped` — v2.4 grouping bit (`0x40`) coverage.

- [x] Task 6: Validate (AC: #6, #7)
  - [x] 6.1: `make fmt` clean.
  - [x] 6.2: `make lint` — no new violations (only the pre-existing TODO warning in `LUFSAnalyzer.swift:94`).
  - [x] 6.3: `make test` — final test count: **304** (`grep -rE '@Test\(' Tests/BoomBoomBoomKitTests/ | wc -l`). Baseline 287 + 17 new declarations = 304. Exceeds AC #7 floor (≥ 299).
  - [x] 6.4: `make benchmark` — OA300 default-policy: **Acc1 = 58/82 (70.7%), Acc2 = 74/82 (90.2%)**. OA300 disabled-policy (durationHint=false control): **Acc1 = 57/82, Acc2 = 73/82** EXACTLY. Both byte-for-byte match Story 3-6 close-out.
  - [x] 6.5: `make benchmark-giantsteps` — GiantSteps default: **Acc1 = 537/661 (81.2%), Acc2 = 546/661 (82.6%)**. GiantSteps disabled (durationHint=false control): **Acc1 = 537/661, Acc2 = 546/661** EXACTLY.
  - [x] 6.6: `make oracle` — DAW oracle three-way comparison passed; no new regressions.
  - [ ] 6.7 (optional): `make perf-benchmark` — skipped per Dev Notes "do NOT add new perf-baseline JSON files unless Task 6.7 is run intentionally" guard. The parser-reject and helper-extract changes are pure code-structure with zero hot-path change.

### Review Findings

- [x] [Review][Patch] v2.4 TBPM frame-format flags are checked with the v2.3 bit mask [Sources/BoomBoomBoomKit/FileMetadataReader.swift:318]
- [x] [Review][Patch] v2.4 footer-present tests set the flag but do not include actual footer bytes [Tests/BoomBoomBoomKitTests/FileMetadataReaderTests.swift:497]
- [x] [Review][Patch] Story source pointer still names removed `extendedHeaderPayloadOverride` builder parameter [_bmad-output/implementation-artifacts/3-6b-metadata-parser-hardening.md:232]

## Dev Notes

### Architecture compliance

- **Public API boundary** (architecture.md:455-461): All Story 3-6b changes are internal. `runPreCorroborationPipeline` (AC #5) is `static` on `AudioAnalysisService` (default-internal access; explicit `internal` keyword omitted per Apple Swift idiom — `internal` is the default access level and adding it as a redundant annotation is inconsistent with the rest of the file). The new internal struct `PreCorroborationOutput` is `Sendable` and lives adjacent to the helper. No new public types, no internal-promotions, no `@testable`-import surface change.
- **Swift 6 strict concurrency**: The new helper takes `Options` (public, `Sendable`) and returns `PreCorroborationOutput { result: BPMResult?, metadataInput: MetadataCorroborationInput }` — both fields are `Sendable` (`BPMResult` is internal value-type-only; `MetadataCorroborationInput` is internal struct with `Sendable` fields per Story 3-6). No actor crossings; the helper is `nonisolated` (synchronous, value-typed). The `@Sendable () -> Bool` cancellation closure and `@Sendable (ProgressUpdate) -> Void` progress closure semantics are preserved exactly.
- **Field-style convention (ADR-11)**: This story does not touch `Options`. No new field additions.
- **Implicit-nil rule** (project-context.md): Not applicable (no new optional fields). The struct's `result: BPMResult?` is a passthrough of `CandidateMergeStrategy.merge`'s existing optional return.

### Source pointers (verified at SHA after Story 3-6 close-out)

- `Sources/BoomBoomBoomKit/FileMetadataReader.swift:181` — ID3 tag-header flags byte read; current rejection: `flags & 0x80 != 0` (unsync only). Bit 4 reject lands here.
- `Sources/BoomBoomBoomKit/FileMetadataReader.swift:228` — same flags byte in the AIFF embedded-tag path (`parseEmbeddedID3Tag`). Same patch applies.
- `Sources/BoomBoomBoomKit/FileMetadataReader.swift:247-264` — extended-header skip block. Minimum-size guards land at the top of this block, immediately after `extSize` is decoded.
- `Sources/BoomBoomBoomKit/FileMetadataReader.swift:271` — the all-zero-frame-ID padding break. This is the current "silent empty result" terminator that masks malformed extended-header sizes; AC #1/#2 make the rejection explicit upstream.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:209-282` (verified at story authoring) — the pre-corroboration pipeline block to extract. Begins with `if options.isCancelled() { throw CancellationError() }` at `:209`, includes `buildMetadataInput` at `:213-214`, duration read at `:222-226`, PCM read at `:228-230`, window loop at `:244-271`, ends with the `CandidateMergeStrategy.merge` call at `:275-282` before `MetadataCorroborator.apply`.
- `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift:163-205` — the `analyzePreMetadataPipeline` private helper to delete.
- `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift:463-483` (verified at story authoring) — the `disabledPolicy` test (`func disabledPolicy()` inside `MetadataCorroborationServiceTests`) to update.
- `Tests/BoomBoomBoomKitTests/FileMetadataReaderTests.swift:212` — `ID3TBPMTests.makeMP3` builder; extends with `crcFlag`, `extendedHeaderSizeOverride`, `footerFlag`, and `frameFlags` params (Tasks 1.3, 2.1, 3.4, 5.2).

### CRC-flag behavior decision — chosen lenient (both directions)

Per id3.org/id3v2.3.0 §3.2, the v2.3 extended-header BE32 size field "excludes itself" and equals 6 (no CRC) or 10 (with CRC). The CRC flag (bit 7 of the first ext-flag byte) **claims** the CRC is present. A well-formed file has both consistent (size = 10 ↔ flag set; size = 6 ↔ flag clear). A malformed file may have them disagree in either direction.

The chosen policy is **lenient: trust the size field, ignore the flag-claim mismatch**. Rationale:

1. The parser walks by size, not by flag-claim. The size field is the load-bearing information for boundary computation; the CRC flag is informational metadata about that boundary.
2. Real-world v2.3 taggers can produce mismatch in either direction. Rejecting on flag-mismatch costs real-world recall for zero parser-correctness gain (the size field already says where the next byte is).
3. The all-zero-frame-ID padding rule + non-ASCII-uppercase-digit frame-ID guard at `Sources/BoomBoomBoomKit/FileMetadataReader.swift:271-275` already terminate malformed walks safely.

**Important caveat:** "lenient" here is a **policy choice for a BPM-evidence extractor**, NOT a spec-validity assertion. A strict-conformance ID3v2.3 parser would reject both mismatch directions because the spec defines the size and flag together. Story 3-6b is explicit that it is choosing lenient because the parser's job is to harvest BPM evidence safely, not to act as a conformance gate.

The chosen policy is pinned by tests in BOTH directions (Tasks 2.3 and 2.4): `extSize=6 + flag set` AND `extSize=10 + flag clear` both parse successfully and emit the expected TBPM evidence.

### Footer-flag policy — reject v2.3 bit-4 (malformed), ACCEPT v2.4 footer (walk body normally)

ID3v2.4 §3.1 defines bit 4 of the tag-header flags byte as "Footer present"; §3.4 specifies the 10-byte footer (`3DI` + version + flags + size, mirroring the 10-byte header in reverse) appended at end-of-tag-body. **Crucially, the synchsafe `tagBodySize` field in the tag header is footer-EXCLUSIVE** — per spec, when a footer is present, the total tag size on disk is `10 (header) + tagBodySize + 10 (footer)`, but the size field encodes only `tagBodySize`. The footer sits OUTSIDE the body the walker needs to scan.

The original Story 3-6b authoring rejected v2.4-with-footer-flag-set as "supported version that uses an unsupported feature." The secondary review (2026-05-02) overturned this:

1. The existing `fh.read(upToCount: tagBodySize)` at `Sources/BoomBoomBoomKit/FileMetadataReader.swift:184` already reads the correct boundary — the footer bytes are not in the slice.
2. The AIFF embedded-tag path's `parseEmbeddedID3Tag` at `:230` slices `data[10..<10 + tagBodySize]`, also footer-exclusive.
3. Therefore "supporting" v2.4 footer is a **no-op for the walker** — bit 4 declares bytes outside the slice, not bytes the walker walks. Rejecting on bit 4 rejects spec-compliant tags whose body the parser already bounds correctly, for zero adversarial-surface gain.

Worst-case adversarial scenario: a malformed file with a misleading `tagBodySize` that incorrectly INCLUDES the footer bytes. In that case, the walker would scan the footer's first 4 bytes (`3DI` + version-major) as a frame ID. Validation: byte 1 (`3`) is `0x33`, byte 2 (`D`) is `0x44`, byte 3 (`I`) is `0x49`, byte 4 (version-major byte, e.g., `0x04`) — fails the existing all-uppercase-or-digit guard at `:272-275` (the `0x04` byte is not in `[0x30..0x39, 0x41..0x5A]`), so the walker breaks safely. The remaining adversarial risk is a deliberately crafted "valid-looking" frame inside footer bytes, which is identical to the risk for any malformed tag and not specific to footer presence.

Bit 4 in v2.3 is reserved per id3.org/id3v2.3.0 §3.1 ("These flags MUST be cleared"). A v2.3 tag with bit 4 set is malformed; v2.3 still rejects.

Net policy: **v2.3 rejects on bit 4 (malformed). v2.4 accepts on bit 4 (footer flag, walk body normally — footer is outside the slice).**

### TBPM frame-flag handling — silent skip on compression/encryption/grouping

ID3v2.3 §3.3.1 defines per-frame flags in two bytes following the 4-byte frame size. The frame-flags byte 2 (the second of the two flag bytes) defines:
- **bit 7 (`0x80`)** — Compression (frame data is zlib-compressed and prefixed with a 4-byte BE32 decompressed-size field).
- **bit 6 (`0x40`)** — Encryption (frame data is encrypted; an encryption method byte is prepended).
- **bit 5 (`0x20`)** — Grouping identity (a group identifier byte is prepended).

ID3v2.4 §4.1 has equivalent flags at the same bit positions (with synchsafe-encoded data length prefixes when relevant).

The current parser at `Sources/BoomBoomBoomKit/FileMetadataReader.swift:290-296` ignores frame flags entirely and decodes the raw payload as text. For a `TBPM` frame with any of these flags set, this produces silent garbage evidence — e.g., the first byte of compressed data may happen to look like a UTF-8 marker, and the decompressed-size prefix gets parsed as a Unicode scalar.

Story 3-6b's parser-hardening contract closes this footgun by **silently skipping** any TBPM frame whose frame-flags byte 2 has bits 7/6/5 set (`flags & 0xE0 != 0`). The walk continues past the frame to find any subsequent well-formed TBPM (in case the file has both a compressed copy and a plain copy — rare but legal). This aligns with how the existing all-zero-frame-ID padding guard and non-ASCII-frame-ID guard already behave: silent walk-termination rather than evidence-emission.

The alternative (emit a `FoundTag` with `parsedBPM = .nan` and `rejectionReason = "frame-flag-unsupported"`) is deferred to a future story if telemetry shows it matters. Justification: the corpus has never produced a compressed/encrypted/grouped TBPM frame; promoting this to evidence-emission adds noise to `metadataEvidence` for zero current value. **A future story can lift this to evidence-emission without breaking AC #8** because AC #8 specifies "MUST NOT decode the frame payload as raw text" — option (a) silent-skip is the chosen implementation but option (b) evidence-emit is also AC-compliant.

### Why the AC #5 helper refactor is the single highest-value patch in this story

The current `analyzePreMetadataPipeline` test helper at `MetadataCorroborationTests.swift:163-205` is ~40 lines of code that hand-replicate the production service. The two reviewers (Codex + claude-opus-4-7, plus the secondary-review BMad roundtable) independently flagged it as drift-prone. Concretely:

- If a future Story X adds a new pre-merge step (e.g., a metadata-aware silence check), the test helper would not see it. The test would either fail-for-the-wrong-reason ("disabled-policy run differs from baseline") or pass-for-the-wrong-reason ("disabled-policy run matches the OUTDATED baseline, masking a real regression").
- If a future refactor changes the order of arguments to `BPMAnalyzer.estimateBPM` or `CandidateMergeStrategy.merge`, the helper requires dual edits — and a reviewer will likely miss one.
- The helper depends on internal types (`BPMResult`, `BPMAnalyzer.Options`, `CandidateMergeStrategy`) being `@testable import`-accessible, which constrains future refactors that might tighten internal access.

The fix promotes the inline pre-corroboration block to a named `static` method that returns a `PreCorroborationOutput { result: BPMResult?, metadataInput: MetadataCorroborationInput }` struct, then swaps two call sites. The struct return is deliberately richer than `BPMResult?`-only because it encodes the service's full ordered orchestration (cancellation → metadata read → duration → PCM → window loop → merge) as a single typed unit. The disabled-policy test discards `metadataInput` (which is empty because the disabled policy short-circuits metadata I/O), but production uses both fields. This converts the AC #4-style byte-equality contract from "anchored to a hand-replicated copy of the service" to "anchored to the actual service code, with the orchestration order encoded as a struct invariant." That's the load-bearing improvement.

**Why the struct return rather than `BPMResult?` alone:** the alternative signature would force production `analyzeBPM(url:options:)` to keep building `metadataInput` adjacent to but disconnected from the helper call — the orchestration order (read metadata BEFORE the PCM read for cancellation efficiency) becomes a comment-level convention rather than a structural invariant. A future refactor that reorders the metadata read could silently diverge from the helper without breaking either signature. The struct return makes that future refactor structurally impossible without explicit signature changes. (Trade-off: slightly heavier internal model. Net win: orchestration invariant becomes type-encoded rather than convention-encoded.)

### Risk / out-of-scope guards

- **Do NOT** change DSP behavior. This is a pure parser-hardening + test-design story. Any Acc1/Acc2 delta on the accept-path (well-formed files) is a bug.
- **Do NOT** add new public types. `runPreCorroborationPipeline` is `static` (default-internal access; explicit `internal` keyword omitted), returns the new internal `PreCorroborationOutput` struct, and is called only by the production service and by the disabled-policy regression test.
- **Do NOT** widen the bitPattern equality check beyond `bpm`/`confidence`/per-candidate `bitPattern`. The Story 3-6 code-review patch explicitly scoped this; no story-level change to that scope is in scope here.
- **Do NOT** rename `MetadataCorroborator.apply`, `MetadataCorroborationInput`, or any of the four reader entry points (`readITunesTmpo`, `readID3TBPMFromMP3`, `readID3TBPMFromAIFF`, `readVorbisBPM`). They were stabilized in Story 3-6.
- **Do NOT** address the TVR fixture-test fragility concern noted in Story 3-6 review (Codex finding: AC #20 test asserts `parsedBPM == 129.0` which is stable but couples to a single corpus track). That's a separate observability question — if it becomes a real maintenance burden, a follow-up story can introduce a fixture-stability mode (e.g., env-gated relaxation). Not this story's scope.
- **Do NOT** add new perf-baseline JSON files unless Task 6.7 is run intentionally — the parser-hardening rejections do not change hot-path timing on real corpora.
- **Do NOT** promote v2.4 footer-flag handling to "support full footer parsing" (i.e., scanning the 10-byte footer at end-of-file as a redundancy check against the header). Story 3-6b accepts the flag and walks the body normally — the footer bytes are intentionally ignored. A future story can add footer-aware end-of-file scanning if it ever has a use case (currently none).
- **Do NOT** promote TBPM frame-flag rejection to evidence-emission. AC #8 prescribes silent-skip (option (a)). A future story can lift this to evidence-emit if telemetry shows compressed/encrypted/grouped TBPM frames are encountered in the wild.
- **Do NOT** add upper-bound checks beyond what AC #1/#2 prescribe. Specifically: do NOT also check that the EXTENDED HEADER fits within `count - idx - SOME-MINIMUM-FRAME-SIZE` to ensure at least one frame can follow. The all-zero-frame-ID padding rule and the `idx + 10 <= count` loop guard already handle the "ext header consumes entire body, no frames follow" case safely (returns `[]` because `found` stays empty). That graceful degradation is the correct behavior for "valid ext header, no frames" tags — they exist legally per spec.

### Apple-platform notes (from secondary review, Siri persona)

- The story's rationale for direct byte parsing (vs. AVFoundation metadata APIs) is correct but the wording should cite specific deprecated APIs. Synchronous loading of `AVAsset.commonMetadata`, `AVAsset.metadata`, and `AVMetadataItem.value/.stringValue/.numberValue` is deprecated starting iOS 16 / macOS 13 in favor of `try await asset.load(.metadata)`, `try await asset.load(.commonMetadata)`, and `try await asset.loadMetadata(for:)`. There is no blessed synchronous AVFoundation replacement for synchronous library callers on macOS 15+. Direct byte parsing is the defensible choice.
- AVFoundation distinguishes ID3 BPM (`AVMetadataIdentifier.id3MetadataBeatsPerMinute`) from iTunes/M4A BPM (`AVMetadataIdentifier.iTunesMetadataBeatsPerMin`). BPM is NOT a common metadata key. Story 3-6's split between `FileMetadataReader.readID3TBPMFromMP3` / `readID3TBPMFromAIFF` and `readITunesTmpo` is the correct factorization.
- `loadUnaligned` usage at `Sources/BoomBoomBoomKit/FileMetadataReader.swift:204, 260, 287` is correct for byte-source data; pointer alignment is not assumed.
- The main Apple-platform risk is not API availability — it is ensuring byte parsing never assumes pointer alignment, never walks beyond `Data.count`, and never lets a malformed size create an integer overflow or accidental huge allocation. AC #1/#2's explicit upper-bound check (`extSize <= count - idx`) closes this for the extended-header case; the story's existing payload-end check at `:292` (`payloadEnd <= count`) closes it for frame walking. AC #8's frame-flag silent-skip closes it for compressed-frame-payload misinterpretation.

### References

- [Source: _bmad-output/implementation-artifacts/3-6-bpm-metadata-corroboration-signal.md] — Story 3.6 close-out + the six code-review patches that motivated this follow-up. See "Review Findings → Code review" section for the patch list and the two-pass review that exposed these gaps.
- [Source: _bmad-output/planning-artifacts/architecture.md] — public/internal boundary (lines 455-481); ADR-11 Options-first convention (referenced for context, not directly applicable).
- [Source: _bmad-output/project-context.md] — Swift 6, value types, vDSP mandate, six-line file headers, `make fmt` before `make lint`, accuracy-floor enforcement pattern.
- [Source: Sources/BoomBoomBoomKit/FileMetadataReader.swift] — the parser file; rejection patches (Tasks 1, 3), CRC arithmetic verification (Task 2), and frame-flag silent-skip (Task 5) land here.
- [Source: Sources/BoomBoomBoomKit/AudioAnalysisService.swift] — the service file; helper extraction (Task 4) lands here.
- [Source: Tests/BoomBoomBoomKitTests/FileMetadataReaderTests.swift] — parser tests; Tasks 1, 2, 3, 5 add coverage here.
- [Source: Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift] — corroborator tests; Task 4 deletes the private `analyzePreMetadataPipeline` helper here and rewires the `disabledPolicy` test to call `AudioAnalysisService.runPreCorroborationPipeline`.
- ID3v2.3 informal standard §3.1 (tag-header flags), §3.2 (extended header), §3.3.1 (frame-format flags) — https://id3.org/id3v2.3.0
- ID3v2.4 informal standard §3.1 (tag-header flags), §3.2 (extended header), §3.4 (footer), §4.1 (frame-format flags) — https://id3.org/id3v2.4.0-structure
- [Source: _bmad-output/implementation-artifacts/3-3a-public-api-harmonization.md] — referenced as the format precedent for follow-up stories that close review-exposed gaps.
- Apple AVFoundation (referenced for "why direct byte parsing"): [Loading media data asynchronously](https://developer.apple.com/documentation/avfoundation/loading-media-data-asynchronously), [AVMetadataIdentifier](https://developer.apple.com/documentation/avfoundation/avmetadataidentifier).

## Dev Agent Record

### Agent Model Used

claude-opus-4-7 (Claude Code), 1M context window.

### Debug Log References

No HALTs encountered. Source builds clean on first pass; all parser tests + 27 corroboration tests + full 304-test suite pass. No regressions in any benchmark.

### Completion Notes List

- **Final test count:** 304 grep-visible `@Test(` declarations (baseline 287 + 17 new). AC #7 floor (≥ 299) exceeded. Swift Testing parameterized cases inflate the runner-discovered count further (the four parameterized declarations expand to 9 additional cases).
- **OA300 default-policy (Acc1, Acc2):** **58/82, 74/82** — byte-for-byte match to Story 3-6 close-out, AC #6 floors held.
- **OA300 disabled-policy (durationHint=false control, Acc1, Acc2):** **57/82, 73/82** EXACTLY — strict-equality contract held, now anchored to `runPreCorroborationPipeline` rather than the deleted hand-replicated helper.
- **GiantSteps default-policy (Acc1, Acc2):** **537/661, 546/661** — byte-for-byte match.
- **GiantSteps disabled-policy (Acc1, Acc2):** **537/661, 546/661** EXACTLY.
- **DAW oracle:** no new regressions on the 22 corpus failures (Story 3-6 close-out baseline preserved).
- **Story 3.6 tagged-subset breakdown test:** still passes — 5 OA300 tagged tracks produce identical evidence shape (4 corroborated same-tempo + 1 uncorroborated).
- **v2.3 CRC-flag mismatch policy:** confirmed **lenient in both directions** per the in-source comment at `FileMetadataReader.swift:265-271`. Pinned by tests `v23CRCFlagSetButSizeSix` (mismatch A: extSize=6 + flag set) and `v23CRCFlagClearButSizeTen` (mismatch B: extSize=10 + flag clear). Both produce the expected `parsedBPM = 128.0`.
- **Helper-refactor outcome:** `AudioAnalysisService.runPreCorroborationPipeline` returns `PreCorroborationOutput { result: BPMResult?, metadataInput: MetadataCorroborationInput }` per the secondary-review decision. Production `analyzeBPM(url:options:)` body shrunk from ~80 lines to 11 lines (1 helper call + 4 lines of corroborator + result wrap). The disabled-policy bitPattern test is now anchored to the SAME code path as production, eliminating the drift-prone `analyzePreMetadataPipeline` shadow copy.
- **Task 1.3 deviation:** `extendedHeaderPayloadOverride` was specified but turned out to be unnecessary — the v2.3 oversized case is built inline in `v23ExtendedHeaderSizeBeyondBody` because the builder cannot truncate `tagBodySize` cleanly without an additional override. The remaining helper params (`extendedHeaderSizeOverride`, `crcFlag`, `footerFlag`, `frameFlags`) are sufficient to construct every other AC #1-#4 + AC #8 case.
- **Task 6.7 (perf benchmark):** intentionally skipped per the "Risk / out-of-scope guards" doctrine in Dev Notes — no new perf-baseline JSON file generated.
- **Lint:** only the pre-existing TODO warning in `LUFSAnalyzer.swift:94` (unchanged from baseline). No new violations.
- **Format:** `make fmt` clean (formatter touched none of the changed files in a meaningful way).

### File List

- `Sources/BoomBoomBoomKit/FileMetadataReader.swift` — modified (Tasks 1.1, 2.5, 3.1, 3.2, 5.1)
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — modified (Task 4: extracted `runPreCorroborationPipeline`, added `PreCorroborationOutput` struct, simplified `analyzeBPM(url:options:)` body)
- `Tests/BoomBoomBoomKitTests/FileMetadataReaderTests.swift` — modified (extended `ID3TBPMTests.makeMP3` and `AIFFID3Tests.makeAIFF` builders; added 17 new `@Test(` declarations spanning AC #1-#4 + AC #8)
- `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` — modified (deleted private `analyzePreMetadataPipeline` helper; rewired `disabledPolicy` test to call `AudioAnalysisService.runPreCorroborationPipeline`)

## Change Log

- 2026-05-02 (Story 3-6b creation): Authored as a follow-up to Story 3.6's two-pass code review (Codex gpt-5.5 + claude-opus-4-7, 2026-05-02). The review applied six patches to Story 3.6 itself but exposed three parser-hardening gaps (extended-header minimum-size validation, v2.3 CRC-flag test coverage, footer-flag rejection) and one test-design concern (disabled-policy bitPattern test depends on a drift-prone hand-replicated pipeline helper). This story closes all four. Status: `backlog`. Sprint-status entry added.
- 2026-05-02 (Story 3-6b implementation): All six tasks completed in a single pass, no HALTs. Parser hardening: v2.3/v2.4 ext-header size validation (AC #1, #2), v2.3 CRC-flag both-direction lenient policy (AC #3), v2.3-bit-4-reject + v2.4-bit-4-accept (AC #4 — MP3 + AIFF), TBPM frame compression/encryption/grouping silent-skip (AC #8). Helper refactor: `AudioAnalysisService.runPreCorroborationPipeline` extracted as single source of truth for the pre-corroboration ordering invariant, `analyzePreMetadataPipeline` test helper deleted, `disabledPolicy` test anchored to production helper (AC #5). Validation: 304 tests pass (baseline 287 + 17 new declarations); OA300 default 58/74 + disabled 57/73 EXACTLY (AC #6); GiantSteps default 537/546 + disabled 537/546 EXACTLY; DAW oracle no regressions; `make fmt` and `make lint` clean. Task 1.3 minor deviation: `extendedHeaderPayloadOverride` parameter not added (turned out unnecessary — v2.3 oversized case built inline); other helper-builder params sufficient. Status: `review`.
- 2026-05-02 (Story 3-6b secondary review pass, post-authoring): Underwent a second review using Codex gpt-5.5 (orchestrator-level plan review) plus a four-persona BMad roundtable (Amelia/dev, Winston/architect, Siri/Apple-platforms, Mary/analyst — each spawned as independent gpt-5.5 sessions). Five forced-choice clarifications resolved by the user: (1) absorb external-review extras into 3-6b rather than defer to 3-6c; (2) helper signature returns `PreCorroborationOutput` struct, not `BPMResult?` alone, to encode service orchestration order as structural invariant; (3) v2.4 footer-flag policy changed from REJECT to ACCEPT-AND-WALK-BODY-NORMALLY, since synchsafe `tagBodySize` is footer-exclusive per spec and the existing read already excludes the footer (consulted Codex gpt-5.5 for trade-off recommendation); (4) test-count target relaxed from fixed floor (≥ 295) to monotonic increase ≥ baseline + 12 (verified baseline = 287); (5) explicit `internal` keyword dropped from helper signature in favor of default access (consulted axiom-swift skill — `internal` redundancy is mainstream Swift idiom, not a Claude hallucination). Story rewritten: AC #1 strengthened with upper-bound check; AC #2 same; AC #3 expanded to pin lenient policy in BOTH mismatch directions; AC #4 split into v2.3-reject vs v2.4-accept; AC #5 returns struct; AC #7 uses monotonic-increase target; new AC #8 added for TBPM frame-flag silent-skip (compression/encryption/grouping per v2.3 §3.3.1 / v2.4 §4.1); new Task 5 for AC #8. Dev Notes rewritten: CRC-flag policy section pins both-direction lenient; footer-flag section completely rewritten to v2.3-reject/v2.4-accept; new TBPM frame-flag handling section; new Apple-platform notes citing specific AVFoundation deprecated APIs. Risk/out-of-scope guards expanded with three new doctrines.
