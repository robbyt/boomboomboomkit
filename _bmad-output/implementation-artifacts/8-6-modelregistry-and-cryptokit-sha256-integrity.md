# Story 8.6: ModelRegistry + ModelRegistryEntry + ModelRegistryError + CryptoKit SHA-256 integrity

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **library consumer**,
I want **a public `ModelRegistry` that lists bundled (if any) + user-added + known-public-reference models with CryptoKit SHA-256 integrity validation at registration time**,
so that **ML model misuse (corruption, wrong-version weights, silent disk swap) surfaces as a typed `ModelRegistryError.integrityCheckFailed(expected:actual:)` rather than as silently-wrong BPM output.**

## Acceptance Criteria

1. **Three new public Sendable types.** New files `Sources/BoomBoomBoomKit/ModelRegistry.swift`, `ModelRegistryEntry.swift`, `ModelRegistryError.swift` exist; all three are `public` and `Sendable`. `ModelRegistry` exposes `register(url:expectedDigest:metadata:) throws -> ModelRegistryEntry`, `entries: [ModelRegistryEntry]`, and `lookup(identifier:) -> ModelRegistryEntry?`. `ModelRegistryEntry` carries identity (`identifier: String`), integrity (`digest: SHA256.Digest`), capability (`capabilities: Set<ModelCapability>`), and attribution (`license: String?`, `sourceURL: URL?`). `ModelRegistryError` is an enum with at minimum `.integrityCheckFailed(expected: SHA256.Digest, actual: SHA256.Digest)`, `.modelResourceMissing(URL)`, and `.unsupportedFormat(reason: String)`. [Source: epics.md#Story-8.6 AC1; architecture.md#FR-32]

2. **KDD-C5 digest algorithm, zero new deps.** SHA-256 is computed via `SHA256.hash(data:)` (or the byte-identical incremental `SHA256()` + `update(data:)` form — see DD-5) over `.mlmodelc` directory contents **sorted by relative path with concatenated bytes** (KDD-C5 algorithm verbatim). Zero new external dependencies enter `Package.swift`. Computation is hardware-accelerated on Apple Silicon (CryptoKit default). [Source: epics.md#Story-8.6 AC2; architecture.md#L165-167 "SHA-256 over `.mlmodelc` directory contents (sorted-by-relative-path, concatenated bytes)"]

3. **CryptoKit confined to the ModelRegistry trio.** `import CryptoKit` appears in the core target (`Sources/BoomBoomBoomKit/`) **only** in `ModelRegistry.swift`, `ModelRegistryEntry.swift`, and `ModelRegistryError.swift` — nowhere else. (The epic's literal "and only to `ModelRegistry.swift`" is impossible because `SHA256.Digest` is in the public API of all three types — see **DD-3**. The verifiable, honest constraint is "no CryptoKit creep into unrelated core files.") Gate: `grep -rn "import CryptoKit" Sources/BoomBoomBoomKit/` returns only the three ModelRegistry files. [Source: epics.md#Story-8.6 AC2; architecture.md#L192]

4. **Cache-on-first-load.** Per KDD-C5, when `register(url:expectedDigest:metadata:)` is called twice with the same URL, the second call short-circuits the SHA-256 computation and returns the cached result — verified by a test-only digest-computation counter (`@testable`-visible internal). Cache is in-memory only (no cross-launch persistence — that is the consumer's responsibility, per NFR / FR-32). [Source: epics.md#Story-8.6 AC3; architecture.md#L167 "Computed once per registration; cached"]

5. **Integrity mismatch throws, registry unchanged.** When a fixture model at `Tests/BoomBoomBoomKitTests/Fixtures/Models/tampered.mlmodelc/` is registered with a wrong `expectedDigest`, `register` throws `ModelRegistryError.integrityCheckFailed(expected:actual:)` with both digests populated; the registry's `entries` array remains unchanged (the throw happens before any append); no silent acceptance. [Source: epics.md#Story-8.6 AC4]

6. **`modelIdentifier` cross-link + README section.** A DocC cross-link is added between the producing-model identity field and `ModelRegistryEntry.identifier`, and a README "Model registry" section is added. (The epic's premise — "Story 6.2 left an internal `BPMDiagnosticTrace.modelIdentifier` unannotated" — is **factually wrong**: no such field exists. The actual equivalent, `MLEvaluation.modelIdentifier`, is **already `public`** at `MLTechnique.swift:59`. So this AC reduces to DocC cross-linking the already-public field and adding the README section — see **DD-1**. No internal field is promoted because none exists.) [Source: epics.md#Story-8.6 AC5; Sources/BoomBoomBoomKit/MLTechnique.swift:53-59]

7. **In-memory-only API surface (no persistence methods).** There is no `save(to:)` / `load(from:)` method on `ModelRegistry`. Demos and consumers handle persistence via their own bookmark + `UserDefaults` plumbing (Epic 10's responsibility). [Source: epics.md#Story-8.6 AC6; architecture.md#FR-32 "In-memory only at library level"]

8. **Test suite coverage.** New test suite `Tests/BoomBoomBoomKitTests/ModelRegistryTests.swift` covers: happy-path registration (digest match), failure-path (digest mismatch → typed error, entries unchanged), cache reuse (second `register` short-circuits — counter asserted), and `Sendable` conformance (concurrent `register` from multiple `Task`s does not corrupt the entry array). [Source: epics.md#Story-8.6 AC7]

9. **No regression / BPM byte-identity.** The full unit suite stays green and the default `analyzeBPM` path is byte-identical — `ModelRegistry` is a brand-new, opt-in type wired to nothing in the analysis pipeline (it is a consumer-facing catalog, not a pipeline stage). `make fmt` idempotent; `make lint` clean (only the pre-existing `LUFSAnalyzer.swift:135` baseline violation). [Source: project regression discipline; CLAUDE.md "Design Constraints"]

## Tasks / Subtasks

- [ ] **Task 1 — `ModelCapability` + `ModelRegistryEntry` value types** (AC: 1, 6)
  - [ ] Create `Sources/BoomBoomBoomKit/ModelRegistryEntry.swift`. Add `import CryptoKit`.
  - [ ] Define `public enum ModelCapability: String, Sendable, Hashable, CaseIterable, Codable` — co-located here per **DD-2** (the AC names only 3 new files; `ModelCapability` is `ModelRegistryEntry`'s natural owner and keeps root files < 5). Seed a small closed-ish set of cases that describe what a model can do, e.g. `.tempoEstimation` (the only capability the library consumes today). Document it as additively-extensible pre-1.0 (new cases land with their consuming story — do NOT over-enumerate speculative cases now).
  - [ ] Define `public struct ModelRegistryEntry: Sendable, Hashable` with stored `identifier: String`, `digest: SHA256.Digest`, `capabilities: Set<ModelCapability>`, `license: String?`, `sourceURL: URL?`, and the resolved/standardized `url: URL` the digest was computed over. (`SHA256.Digest`, `URL`, `String`, `Set<ModelCapability>` are all `Hashable` + `Sendable`, so the synthesized conformances are sound.)
  - [ ] Add a `public var digestHexString: String` convenience (`digest.map { String(format: "%02x", $0) }.joined()`) for display — Epic 10 renders `Integrity: verified` from this; consumers should not have to reach into the `Digest` byte sequence.
  - [ ] **Do NOT conform to `Codable`** (per **DD-7**): `SHA256.Digest` is not `Codable`, and FR-32 makes the registry in-memory-only, so there is no wire-format requirement. Add a one-line DocC note explaining the deliberate non-`Codable` (this is an intentional deviation from the other Epic-8 public types — call it out so a reviewer doesn't flag it as an omission).
  - [ ] DocC: cross-link `ModelRegistryEntry/identifier` to `MLEvaluation/modelIdentifier` (`The forensic tag a producing model stamps on its ``MLEvaluation`` (``MLEvaluation/modelIdentifier``) should match this registry identifier so trace logs can be joined to a registered model.`).
- [ ] **Task 2 — `ModelRegistryError`** (AC: 1, 5)
  - [ ] Create `Sources/BoomBoomBoomKit/ModelRegistryError.swift`. Add `import CryptoKit`. Mirror the house style of the sibling `MLTechniqueError` (`MLTechnique.swift:151`): `public enum ModelRegistryError: Error, Sendable` with rich DocC per case.
  - [ ] Cases: `.integrityCheckFailed(expected: SHA256.Digest, actual: SHA256.Digest)`, `.modelResourceMissing(URL)`, `.unsupportedFormat(reason: String)`. (`.modelResourceMissing(URL)` deliberately mirrors the sibling `MLTechniqueError.modelResourceMissing(URL)` name — different enum, no conflict; do not conflate them.)
  - [ ] Optionally conform `CustomStringConvertible` for readable diagnostics (render the two digests as hex in `.integrityCheckFailed`). Do not force `Equatable`/`Hashable` — tests pattern-match via `if case`.
- [ ] **Task 3 — `ModelRegistry` (Sendable class + Mutex) + digest algorithm** (AC: 1, 2, 3, 4, 7)
  - [ ] Create `Sources/BoomBoomBoomKit/ModelRegistry.swift`. Add `import CryptoKit` and `import Synchronization`.
  - [ ] Implement as `public final class ModelRegistry: Sendable` (NOT an `actor` — see **DD-3**: `entries`/`lookup`/`register` are synchronous in the AC, which an actor cannot provide). Back all mutable state with a single `Mutex<State>` following the project precedent (`AudioAnalysisService.swift:1617`, `BNNSTechnique.swift:140`). `State { var entries: [ModelRegistryEntry]; var digestCache: [URL: SHA256.Digest]; var digestComputationCount: Int }`. Provide `public init()`.
  - [ ] `public var entries: [ModelRegistryEntry]` — reads a snapshot under the lock.
  - [ ] `public func lookup(identifier: String) -> ModelRegistryEntry?` — first match under the lock.
  - [ ] `public func register(url: URL, expectedDigest: SHA256.Digest? = nil, metadata: ModelMetadata) throws -> ModelRegistryEntry` — see Task 4 for `ModelMetadata`. Flow (all under the lock, or compute-then-lock — see DD-6 re: holding the lock across I/O): standardize the URL key; if `digestCache[key]` exists, reuse it (short-circuit, do NOT bump the counter); else verify the resource exists (`.modelResourceMissing` if not) and is a directory bundle (`.unsupportedFormat` otherwise), compute the digest (bump `digestComputationCount`), cache it. Then: if `expectedDigest != nil` and `expected != actual` → `throw .integrityCheckFailed(expected:actual:)` **before** appending (entries unchanged). Else build the `ModelRegistryEntry` (using `expectedDigest ?? computed`), append, return it.
  - [ ] Implement the KDD-C5 digest helper as `static func computeDigest(forModelAt url: URL) throws -> SHA256.Digest` (internal, `@testable`-visible — lets the mismatch + happy-path tests be deterministic). Algorithm: recursively enumerate **regular files** under `url`, compute each file's path **relative to `url`**, sort ascending by that relative path (stable, locale-independent byte/`<` ordering), then feed file bytes in that order into an incremental `var hasher = SHA256()` via `hasher.update(data:)` per file, returning `hasher.finalize()`. (Incremental update over the sorted files is byte-identical to hashing the concatenation but never materializes the ~1.2 MB+ `weight.bin` blobs into one buffer — see **DD-5**.) Throw `.modelResourceMissing` / `.unsupportedFormat` on enumeration failure.
  - [ ] Expose an internal `var digestComputationCount: Int { get }` (reads under the lock) for the cache test.
- [ ] **Task 4 — `ModelMetadata` register-input struct** (AC: 1)
  - [ ] Define `public struct ModelMetadata: Sendable, Hashable` carrying the register-time inputs that are NOT derived from the file: required `identifier: String`, and defaulted `capabilities: Set<ModelCapability> = []`, `license: String? = nil`, `sourceURL: URL? = nil`. Place it in `ModelRegistryEntry.swift` (it is the entry's pre-image). This honors the Options-struct pattern (required `identifier` as the only non-defaulted field; the rest optional/defaulted in one struct) and gives `register(url:expectedDigest:metadata:)` its exact 3-parameter shape. [memory: feedback_options_struct_pattern]
- [ ] **Task 5 — `modelIdentifier` cross-link + README "Model registry" section** (AC: 6)
  - [ ] Add the reciprocal DocC cross-link on `MLEvaluation/modelIdentifier` (`MLTechnique.swift:53-59`) pointing to `ModelRegistryEntry/identifier`. No code/behaviour change — DocC only. (Do NOT invent a `BPMDiagnosticTrace.modelIdentifier` field; it does not exist and is not needed — **DD-1**.)
  - [ ] Add a "## Model registry" section to `README.md` (ships to `main`): what `ModelRegistry` is, the `register` → integrity-check → `lookup` flow, the TOFU vs pinned-digest distinction (**DD-4**), and the in-memory-only contract. **No story numbers, no BMAD/KDD/internal jargon, no aubio** — public-facing prose only. [memory: feedback_no_business_jargon_in_commits, feedback_no_aubio_in_public]
- [ ] **Task 6 — Fixtures + test suite** (AC: 5, 8)
  - [ ] Reuse the existing committed fixture `Tests/BoomBoomBoomKitTests/Fixtures/CustomBundled.mlmodelc/` (multi-file, nested `weights/` + `analytics/` subdirs — exercises the recursive sorted-relative-path enumeration) for the **happy path**.
  - [ ] Create the net-new mismatch fixture `Tests/BoomBoomBoomKitTests/Fixtures/Models/tampered.mlmodelc/` — a minimal synthetic directory bundle (a couple of tiny deterministic files, e.g. a stub `metadata.json` + `coremldata.bin`; it need not be a loadable CoreML model — the registry only hashes bytes). Register it with a deliberately-wrong `expectedDigest` (e.g. `SHA256.hash(data: Data())`, the empty-input digest) → `.integrityCheckFailed`.
  - [ ] Add `Tests/BoomBoomBoomKitTests/ModelRegistryTests.swift` (`import Testing`, `@testable import BoomBoomBoomKit`, `import CryptoKit`). Suites/tests:
    - happy path: compute `CustomBundled` digest via the internal helper, `register` with that `expectedDigest` → returned entry's `digest == expected`, `entries.count == 1`, `lookup(identifier:)` round-trips.
    - TOFU path: `register` with `expectedDigest: nil` → entry's `digest` equals the freshly-computed digest, registered.
    - mismatch: register `tampered.mlmodelc` with wrong digest → throws `.integrityCheckFailed`, both digests populated, `entries` still empty.
    - cache reuse: two `register` calls (or `computeDigest` is funneled through `register`) on the same URL → `digestComputationCount == 1`.
    - missing resource: `register` a non-existent URL → `.modelResourceMissing`.
    - Sendable / concurrency: fan out N `Task`s each registering a distinct identifier (same or distinct fixture URL) via a `TaskGroup`; assert final `entries.count == N` with no lost updates and no crash (Mutex correctness).
  - [ ] Confirm the new fixture directory is under `Tests/` (ships to `main`); it is not develop-only.
- [ ] **Task 7 — Gates** (AC: 3, 9)
  - [ ] `make fmt` (idempotent), `make lint` (only the `LUFSAnalyzer.swift:135` baseline), `make test` (full suite green incl. the new ModelRegistry suite).
  - [ ] Run the AC3 confinement gate: `grep -rn "import CryptoKit" Sources/BoomBoomBoomKit/` → only the three ModelRegistry files.
  - [ ] Confirm `git diff Package.swift` is empty (zero new dependencies).

## Dev Notes

### Why this story is low-risk and self-contained

`ModelRegistry` is a **standalone consumer-facing catalog**. It is NOT wired into the BPM/LUFS/beat-grid pipeline, the ensemble, `Options`, or `AudioAnalysisService`. Nothing in the analysis path reads it. That is why AC9 (BPM byte-identity) holds by construction — there is no pipeline edit. The whole story is: three new public types + one new test suite + a DocC cross-link + a README section. Treat any temptation to "wire it into model selection" as out of scope (that is Epic 10's `ModelPickerView`, which *reads* the registry).

### Decisions / factual corrections to the epic ACs (READ BEFORE CODING)

These came out of a pre-spec grep of the actual codebase. The epic ACs carry three claims that do not match the code; each is resolved here.

- **DD-1 — There is no internal `BPMDiagnosticTrace.modelIdentifier` to "promote."** Epic AC5 says "Story 6.2 left an internal `BPMDiagnosticTrace.modelIdentifier: String?` field (or equivalent) unannotated → promote it to public." Reality (grep): the only `modelIdentifier` in the core target is `MLEvaluation.modelIdentifier: String?`, which is **already `public`** (`Sources/BoomBoomBoomKit/MLTechnique.swift:59`). The other is `BNNSTechnique.modelIdentifier` (internal, in the *ML* target — out of core, out of scope). So AC6 here reduces to a **DocC cross-link** between the already-public `MLEvaluation.modelIdentifier` and the new `ModelRegistryEntry.identifier`, plus the README section. Nothing is "promoted." Do not fabricate a trace field. [memory: feedback_factual_claims_grep_pre_story, feedback_direct_about_failure]
- **DD-2 — `ModelCapability` is a NEW type the AC forgets to name.** The AC's file list names exactly three new files but `ModelRegistryEntry.capabilities: Set<ModelCapability>` requires a `ModelCapability` type that does not exist. Co-locate it (and `ModelMetadata`) in `ModelRegistryEntry.swift` to honor the explicit 3-file enumeration and keep root `.swift` files under the "subdir when ≥ 5 cohesive files" threshold (architecture.md#L149). A dedicated `ModelCapability.swift` would also be defensible (still < 5) — co-location is the recommendation, not a hard rule.
- **DD-3 — `import CryptoKit` cannot be confined to a single file; `ModelRegistry` must be a class, not an actor.**
  - *CryptoKit confinement:* `SHA256.Digest` is named in the public API of all three types (`ModelRegistryEntry.digest`, `ModelRegistryError.integrityCheckFailed`, `ModelRegistry.register`), so all three files must `import CryptoKit`. The epic's "only `ModelRegistry.swift`" is literally impossible without changing the named public API (which AC1 fixes as `SHA256.Digest`). Honest reframe (AC3): CryptoKit enters core **only via the ModelRegistry trio** — verifiable with the grep gate. A core-owned `ModelDigest` wrapper would confine the import but would violate the AC1 `digest: SHA256.Digest` contract — rejected.
  - *Class vs actor:* AC1 gives `entries` and `lookup(...)` synchronous signatures and `register(...)` a synchronous (throwing, non-async) return. An `actor` forces `await` on all of these. Therefore `ModelRegistry` is a `public final class: Sendable` with a `Synchronization.Mutex<State>` guarding all mutation. AC8's "concurrent register does not corrupt the entry array" is satisfied by the Mutex, not by actor isolation. Precedent: `AudioAnalysisService.swift:1617` (`Mutex<FeatureSubstrate.DecodedAudio?>`), `BNNSTechnique.swift:140`.
- **DD-4 — `expectedDigest` is optional (TOFU vs pinned).** Make it `expectedDigest: SHA256.Digest? = nil`. `nil` = trust-on-first-use: compute, record, register (the "user-added model" path — the consumer has no pre-known digest). Non-`nil` = verify-or-throw (the "known-public-reference model" path — the consumer ships the expected digest and wants a swap detected). Document plainly that TOFU is **pin-now-detect-later**, not verified provenance. This shape supports both the happy-path test (pass the matching digest) and the mismatch test (pass a wrong one).
- **DD-5 — Digest algorithm: incremental hash over sorted files (byte-identical to "concatenated bytes").** KDD-C5 verbatim is "SHA-256 over `.mlmodelc` directory contents sorted-by-relative-path, concatenated bytes." Implement with `var hasher = SHA256(); for file in sortedFiles { hasher.update(data: Data(contentsOf: file)) }; hasher.finalize()`. Feeding the sorted file bytes incrementally produces the **same** digest as hashing one concatenated `Data`, without materializing the 1.26 MB `weights/weight.bin` (and future larger blobs) into a single buffer. *Boundary note for the reviewer:* KDD-C5 concatenates file *contents* only — it does NOT interleave the relative-path bytes into the hash. That means two different directory layouts whose files concatenate to the same byte stream would collide. This is a theoretical cross-layout collision, **not** a tamper-detection gap (any byte change to a registered model still changes the digest). Implement verbatim; if a reviewer wants path-mixing hardening, that is a follow-up, not this story.
- **DD-6 — digest-computation counter + lock discipline.** The cache test needs proof the second `register(sameURL)` does not recompute. Keep an internal `digestComputationCount` bumped exactly once per actual SHA computation. Cache key = standardized URL (`url.standardizedFileURL`). Note: computing the digest does file I/O; holding the `Mutex` across I/O is acceptable here (registration is not a hot path and keeps cache/append atomic), but if you prefer not to hold the lock across I/O, use the double-checked pattern (lock → check cache miss → unlock → compute → lock → re-check/insert/append) and ensure the counter still reflects real computations. Either is fine; document which you chose.
- **DD-7 — `ModelRegistryEntry` is `Sendable, Hashable` but intentionally NOT `Codable`.** `SHA256.Digest` has no `Codable` conformance, and FR-32 makes the registry in-memory-only, so there is no serialization requirement. The other Epic-8 public types (`BeatGrid`, `LUFSReport`, `TempoAgreement`) are `Codable`; this one is the deliberate exception. Add a DocC note saying so, and provide `digestHexString` for display. Do not hand-roll a `Digest` `Codable` for a consumer that does not exist (pre-1.0; no BC concern — add it later if a consumer surfaces). [memory: feedback_no_bc_goal_prerelease]
- **DD-8 — No persistence methods (AC7 / FR-32).** No `save(to:)` / `load(from:)`. Persistence is the consumer's job (Epic 10 security-scoped bookmark + `UserDefaults`, mirroring the Story 5-6 `MergeStrategyPersistence` precedent named in epics.md#L330).

### Source-tree placement

All three new source files live at `Sources/BoomBoomBoomKit/` **root** (the core target), siblings of `LUFSReport.swift`, `BeatGrid.swift`, `TempoAgreement.swift`, `MLTechnique.swift`. This matches architecture.md#L146 ("`ModelRegistry` (Epic 8) … land[s] in existing `BoomBoomBoomKit` core target") and #L149 ("LUFS / BeatGrid / ModelRegistry … files (1-3 each) stay at root. Codified threshold: subdir when ≥ 5 cohesive files"). With `ModelCapability` + `ModelMetadata` co-located, this story adds 3 files — under the threshold, so no `ModelRegistry/` subdir. This all ships to `main` (it is `Sources/` + `Tests/` + README — the public library). [Source: CLAUDE.md "Ships to `main`"]

### Existing patterns to mirror (read these first)

- **`Sources/BoomBoomBoomKit/MLTechnique.swift`** — `MLEvaluation` (public `Sendable` value type with rich DocC), `MLTechniqueError` (`public enum … : Error, Sendable`, per-case DocC). This is the closest house-style template for `ModelRegistryEntry` + `ModelRegistryError`. `MLEvaluation.modelIdentifier:53-59` is the cross-link target.
- **`Sources/BoomBoomBoomKit/LUFSReport.swift`** — recent public-type precedent (promoted-to-public, root file, DocC doc-comment density).
- **`Sources/BoomBoomBoomKit/AudioAnalysisService.swift:11,1617`** — `import Synchronization` + `Mutex<…>` usage (the `DecodedCapture` pattern from Story 8.5). Copy this locking idiom for `ModelRegistry`.
- **`Sources/BoomBoomBoomKitML/BNNSTechnique.swift:140,269`** — `Mutex` for a cache counter (the `(confidence, margin)` cache) + `FileManager.default.fileExists(atPath:)` resource-existence check. The fileExists check is the model for the `.modelResourceMissing` guard.
- **`Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift`** — how existing tests consume the `.mlmodelc` fixtures (`CustomBundled.mlmodelc`, `RenamedTensors.mlmodelc`) and resolve their URLs. Reuse that URL-resolution approach for the registry tests.

### Testing standards

- Swift Testing (`import Testing`, `@Suite`/`@Test`/`#expect`/`#require`) — NOT XCTest. `@testable import BoomBoomBoomKit` to reach the internal `computeDigest` + `digestComputationCount`.
- Concurrency test: prefer `await withTaskGroup` over raw `Task` + sleep; assert on the post-join `entries.count`. No `sleep()` (project testing-auditor discipline).
- The two `.mlmodelc` fixtures and the new `Models/tampered.mlmodelc/` are committed test resources under `Tests/` (ship to `main`) — confirm `Package.swift` test-target resource handling already globs `Fixtures/` (it does for the existing `.mlmodelc` fixtures; the new `Models/` subdir rides the same rule — verify no explicit per-file `.copy` is required).

### Project Structure Notes

- **Ships to `main`:** `Sources/BoomBoomBoomKit/{ModelRegistry,ModelRegistryEntry,ModelRegistryError}.swift`, `Tests/BoomBoomBoomKitTests/ModelRegistryTests.swift`, `Tests/BoomBoomBoomKitTests/Fixtures/Models/tampered.mlmodelc/`, `README.md`. All public-library surface. [CLAUDE.md decision tree #1]
- **Stays on develop:** this story file + `sprint-status.yaml`.
- **README discipline:** the "Model registry" section is public-facing — no story numbers, no BMAD/KDD references, no aubio, no internal jargon. [memory: feedback_no_aubio_in_public, feedback_no_business_jargon_in_commits]
- **Zero new SPM products / dependencies** (architecture.md#L146, NFR-2). CryptoKit + Synchronization are Apple system frameworks, not SPM deps — `Package.swift` is untouched.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story-8.6 (lines 1092-1130)] — the seven ACs, FR-32/33, KDD-C5.
- [Source: _bmad-output/planning-artifacts/architecture.md#L93-94] — FR-32 (model registry public type, in-memory) + FR-33 (CryptoKit `SHA256.hash(data:)` integrity at registration, cached).
- [Source: _bmad-output/planning-artifacts/architecture.md#L124] — NFR-2 zero external deps (CryptoKit, Synchronization explicitly allowed).
- [Source: _bmad-output/planning-artifacts/architecture.md#L146,149] — core-target placement + root-file ≤ threshold rule.
- [Source: _bmad-output/planning-artifacts/architecture.md#L165-167,192] — KDD-C5 algorithm verbatim + `import CryptoKit` NEW in `ModelRegistry.swift`.
- [Source: _bmad-output/planning-artifacts/architecture.md#L310] — KDD-C5 (CryptoKit SHA-256 integrity), KDD-C6 (no engine abstraction in v1.0).
- [Source: Sources/BoomBoomBoomKit/MLTechnique.swift:53-59,151] — `MLEvaluation.modelIdentifier` (already public, cross-link target) + `MLTechniqueError` house style.
- [Source: Sources/BoomBoomBoomKit/AudioAnalysisService.swift:11,1617] — `Mutex` precedent.
- [Source: Tests/BoomBoomBoomKitTests/Fixtures/CustomBundled.mlmodelc/] — existing multi-file `.mlmodelc` fixture (happy-path source).
- [Source: CLAUDE.md] — main-vs-develop ship rules; design constraints.

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List

### Change Log
