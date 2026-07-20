# Story 11.1: DocumentedCase protocol, Bundle.module accessor, Mutex<T> cache

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->
<!-- dev-auto baseline_revision: 07dfddfb95d2e7a5663adea164efbf5582032189 (HEAD at implementation start) -->
<!-- dev-auto review_loop_iteration: 1 (one bad_spec loopback; iteration-2 review was patch-only) -->
<!-- dev-auto followup_review_recommended: false -->
<!-- dev-auto final_revision: 07dfddfb95d2e7a5663adea164efbf5582032189 (UNCHANGED — no commit made; the operator owns the 1Password-signed commit per project convention, which overrides the skill's auto-commit step) -->

## Key Design Decisions (review BEFORE dev begins)

1. **`BoomBoomBoomKitDocs` is a caseless-enum namespace, NOT a class.** `ModelRegistry` is the *sole* sanctioned reference type in the core target (project-context.md language rule — "the only class in the core target; do not add others without a named story"). The docs accessor is stateless-façade + a static cache, which fits the caseless-enum namespace precedent (`MelFilterbank`, `FileMetadataReader`, `MetadataCorroborator`). Declare `public enum BoomBoomBoomKitDocs {}` with a `static let cache` and static `attributedString(for:id:)`. A static stored `Mutex` property on a caseless enum is legal and `Sendable`.

2. **`Mutex` from `Synchronization` is already proven in the core target — do NOT reach for the `OSAllocatedUnfairLock` pressure-valve unless a real compile error surfaces.** Precedents: `ModelRegistry.swift:61` (`private let state = Mutex(State())`) and `AudioAnalysisService.swift:2014` (`private let storage = Mutex<...>(nil)`). The `ModelRegistry` `state.withLock { }` idiom is the exact template. The epic's pressure-release valve (fall back to `OSAllocatedUnfairLock`, write `11-1-pressure-release.md`) is a genuine escape hatch, but the in-repo evidence says it will not be needed. If it IS needed, HALT and surface — do not silently swap primitives.

3. **11.1 does NOT conform the 9 production enums to `DocumentedCase`.** It declares the protocol + the `RawRepresentable where RawValue == String` default extension + the accessor/cache + the resource-bundle wiring, and proves them with a **Tests/-only fixture conformer**. Production-type conformance lands *with its authored docs* in Stories 11.2 (`AnalysisIntensity`) / 11.3a / 11.3b. Rationale: conforming a production enum now would make its `.docs` return the fallback string until 11.3, and half-documented public surface invites confusion. This keeps 11.1 a clean foundation. (Declared here so review is not surprised by the absence of production conformances.)

4. **Use `.copy("Resources/Documentation")` — this OVERRIDES the epic's KDD-E6 `.process` on evidence (Codex + SwiftPM docs, 2026-07-15).** SwiftPM `.process` copies unprocessed files (`.md`) to the resource bundle's **top-level** directory — it FLATTENS `Documentation/<Type>/`, which breaks the accessor's `subdirectory: "Documentation/<kind>"` resolution AND collides the two `sourceSpecific.md` basenames (`AbstainReason/` vs `DemotionReason/` — SwiftPM may even hard-error on conflicting destinations). `.copy` on a directory retains structure verbatim (proven by `AudioFixtures` at `AudioFixtures.swift:15-37`, and by SwiftPM's BundlingResources docs). Add `resources: [.copy("Resources/Documentation")]` to the core target block at `Package.swift:13-16` (currently NO `resources:` arg — Story 4-6 removed the ML target's; core never had one). Adding `resources:` is also what makes `Bundle.module` a real symbol in core (today comment-only at `MLTechnique.swift:159`). **KDD-E6 is superseded for this story** — see the supersession note in Dev Notes; carry the `.copy` decision forward to Stories 11.3/11.5.

5. **RESOLVED (was "forward risk"): the `.process` flatten + `sourceSpecific.md` collision is fixed at 11.1 by KDD-4's `.copy`, not deferred.** Codex ruled this a known incompatibility with the lookup contract, not an 11.3-only concern — the accessor's resolution strategy is chosen NOW, so the bundle layout that makes it work must land NOW. The 11.1 build/test MUST assert the nested `Documentation/<subdir>/` structure actually exists in `Bundle.module` (via the sentinel-resource happy-path test in AC #7) — do not trust `.gitkeep` alone to prove SwiftPM recognized the resource.

6. **The accessor is non-optional, non-throwing — the fallback path is the contract (FR-49).** `attributedString(for:id:)` returns a clear informative `AttributedString` on any miss (resource absent, unreadable, or `AttributedString(markdown:)` parse failure) — e.g. `"Documentation unavailable for <kind>.<id>."` Never empty, never `nil`, never `throws`. This is load-bearing: every `.docs` call site downstream relies on it.

7. **File I/O happens OUTSIDE the lock; the cache is double-checked (KDD-E5).** Read → check cache under lock → if miss, release, do file I/O + markdown parse, re-acquire, re-check (another thread may have inserted), insert, return. Do NOT hold the `Mutex` across `Bundle.module.url(...)` / `Data(contentsOf:)` / `AttributedString(markdown:)`.

8. **`AttributedString` markdown parsing is a net-new API in this codebase** (scout: zero prior use in `Sources/`/`Demo/`). **~~Prefer `AttributedString(contentsOf: url, options:, baseURL: nil) throws`~~ SUPERSEDED (PR #97 Codex review, 2026-07-16): use `String(contentsOf:encoding:)` + `AttributedString(markdown:options:)`.** The one-call `contentsOf` form was preferred while no pre-processing was needed, but YAML front-matter stripping (KDD-E7, see AC #4) must intercept the raw text before parsing, so the read-then-parse two-step is now required. Options: `.init(interpretedSyntax: .inlineOnlyPreservingWhitespace)` — this inline-only mode is *why* the authoring rules (no tables/code blocks/heading hierarchy, Stories 11.3a/b) exist: it is the render path's hard constraint, not a style preference. All markdown inits `throws` (default `failurePolicy: .throwError`), so `try?` → fallback is the abstain path (KDD-6). macOS 15 floor means no `@available` gating is needed in core (scout confirmed core uses none). `Bundle` resolution is case-sensitive — `id` must equal the filename stem exactly (aligns with KDD-E7).

## Story

As a library consumer using Xcode autocomplete,
I want every public mode case to be *able* to expose a `docs: AttributedString` property backed by a thread-safe, offline documentation accessor,
so that later stories can attach authored guidance that I read inline — without string lookups, network calls, or runtime crashes.

## Acceptance Criteria

1. **Protocol declared.** `Sources/BoomBoomBoomKit/DocumentedCase.swift` declares `public protocol DocumentedCase: Sendable` with `static var documentedKind: String { get }`, `var documentationID: String { get }`, and `var docs: AttributedString { get }` (KDD-E2). **`Hashable` is DROPPED (Review pass 1, 3-reviewer consensus, 2026-07-15).** The docs mechanism never uses `Self: Hashable` (the cache keys on an internal `(kind, id)` `CacheKey`, not on the conformer), and the bound overturns `MLExecutionPolicy`'s checked-in `Sendable, Equatable` (deliberately non-`Hashable` — NaN-bearing `Double` payload) — a named future conformer (AC #2). Supersedes the epic AC at `epics.md` line ~1540 (`Sendable, Hashable`); KDD-E2 governs only the `var docs` shape, not the superprotocol bound, so nothing in KDD-E2 is contradicted. Pre-1.0, over-constrained epic ACs are corrected freely.

2. **Free ID derivation for String-raw conformers — via TWO separate extensions (Codex 2026-07-15).** (a) An UNCONSTRAINED extension on `DocumentedCase` provides the default `docs` → `BoomBoomBoomKitDocs.attributedString(for: Self.documentedKind, id: documentationID)`. (b) A CONSTRAINED extension `where Self: RawRepresentable, Self.RawValue == String` provides `documentationID { rawValue }` (KDD-E3). **These must be separate:** if `docs` accidentally lives only on the constrained extension, associated-value conformers that hand-write `documentationID` silently lose `docs`. String-raw conformers get `documentationID` free; associated-value conformers (`EnsemblePolicy`, `MLExecutionPolicy`, `DownbeatResult`, `AbstainReason`, `DemotionReason` — enums whose cases carry payloads block raw-value synthesis) override `documentationID` manually. NOTE: the epic's "7 of 9 free" figure is NOT verified here — the exact free-vs-manual split is resolved per-type when conformances are authored in 11.2/11.3 (factual-claims-grep discipline); 11.1 only ships the mechanism.

3. **Thread-safe accessor with `Mutex` + I/O outside lock.** `Sources/BoomBoomBoomKit/BoomBoomBoomKitDocs.swift` declares `public enum BoomBoomBoomKitDocs` with `public static func attributedString(for kind: String, id: String) -> AttributedString` — **explicitly `public`** (not implicit): Story 11.6's demo popover and Story 11.4's validator both call it directly by string `(kind, id)`, so it is advertised namespace API, not a `.docs`-only internal (Codex 2026-07-15). Backed by `Mutex<[CacheKey: AttributedString]>` from `import Synchronization`. File I/O + markdown parsing occur OUTSIDE the lock; the cache is re-checked under lock before insertion (KDD-E5 double-checked locking). `CacheKey` is a `Hashable` value type over `(kind, id)`. Nothing (no dictionary reference, no mutable state) escapes either `withLock` closure.

4. **Informative non-optional fallback (FR-49).** When a doc resource is missing, unreadable, or fails markdown parsing, `attributedString(for:id:)` returns a clear informative `AttributedString` (e.g. `"Documentation unavailable for <kind>.<id>."`) — never empty, never optional, never throwing. Resolution uses `Bundle.module.url(forResource: id, withExtension: "md", subdirectory: "Documentation/\(kind)")` (filename match is case-PRESERVING but filesystem-dependent — case-insensitive on default APFS, per Review pass 2; pass the exact enum-identifier casing, aligns with KDD-E7), then `AttributedString(contentsOf: url, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace), baseURL: nil)` — a single read+parse call; markdown inits `throws` (default `failurePolicy: .throwError`), caught via `try?` → fallback.
   - **Blank-parse is a MISS (Review pass 1 + strengthened Review pass 2, 3-reviewer unanimous).** A parse that SUCCEEDS but is blank — zero-length OR all-whitespace (inline-only mode PRESERVES whitespace, so an all-whitespace file parses to a non-empty-but-blank string) — is treated as a miss → fallback. The never-empty guarantee must hold on the parse-success path, not only the throw path. Guard with `parsed.characters.contains(where: { !$0.isWhitespace })` (whitespace-aware — the pass-1 `!parsed.characters.isEmpty` under-caught the all-whitespace case).
   - **Malformed-input guard (Review pass 1, low-severity hardening).** Because the accessor is a public string API, an EMPTY `kind`/`id`, or one containing a path separator (`/`) or a `..` segment, resolves straight to the fallback WITHOUT interpolating the untrusted separator into `subdirectory:` — a catalog-isolation / cache-alias guard. Real callers pass controlled enum-identifier tokens, so this never fires in normal use.
   - **YAML front-matter is stripped before parsing (PR #97 review, Codex P2, 2026-07-16).** Every authored 11.3 doc file carries a `---`-delimited `id:`/`title:`/`payload:` block (KDD-E7). That metadata is tooling/validator input, NOT user-visible prose, and `AttributedString` has no front-matter concept — inline-only mode would render it as literal text ahead of the body. So resolution reads the raw text first (`String(contentsOf:encoding:)`, no longer the one-call `AttributedString(contentsOf:)`) and strips a leading `---`…`---` block via a `strippingFrontMatter(_:)` helper before `AttributedString(markdown:options:)`. An unterminated / absent front-matter block leaves the text untouched (authoring error caught by Story 11.4's validator; the accessor stays total). This is 11.1's mechanism responsibility (the accessor owns the parse path) — folded here rather than leaking into 11.3's authoring scope.

5. **SPM resource bundle wired with `.copy`.** `Package.swift` adds `resources: [.copy("Resources/Documentation")]` to the `BoomBoomBoomKit` target (overrides KDD-E6 `.process` — see KDD-4). Ship: `Sources/BoomBoomBoomKit/Resources/Documentation/.gitkeep` (dir reservation), a `_`-prefixed sentinel resource `Sources/BoomBoomBoomKit/Resources/Documentation/_Fixture/_probe.md` carrying minimal known markdown (proves the happy path), a `_`-prefixed all-whitespace sentinel `Sources/BoomBoomBoomKit/Resources/Documentation/_Fixture/_blank.md` (proves the blank-parse guard, AC #7 (f); Review pass 2), AND a `_`-prefixed front-matter sentinel `Sources/BoomBoomBoomKit/Resources/Documentation/_Fixture/_frontmatter.md` (a `---` block + body — proves front-matter stripping, AC #7 (g); PR #97 Codex review), so the resolution tests prove the bundle+subdir chain end-to-end. `swift build` succeeds; the nested `Documentation/_Fixture/` structure is present in `Bundle.module` (asserted by the AC #7 happy-path test). (The `_`-prefix keeps the sentinel out of Story 11.4's validator, which skips `_`-stem files; 11.3 may retire the sentinel once real case files exist and repoint the happy-path test at one.)

6. **Protocol-family cap holds (KDD-E1).** No sibling protocols (`DefaultProvidable`, `PerformanceAnnotated`, `DeprecatedIn`) ship — one protocol only, pre-1.0.

7. **Tests prove shape + happy-path + fallback + cache race-safety.** `Tests/BoomBoomBoomKitTests/DocumentedCaseTests.swift` (Swift Testing) proves: (a) a Tests-only fixture enum conforming `DocumentedCase` via the String-raw extension derives `documentationID == rawValue`; (b) **happy path (Codex-mandated):** `attributedString(for: "_Fixture", id: "_probe")` resolves the sentinel resource (AC #5) and returns its authored content — this is the ONLY test that proves the resource declaration + `Bundle.module` generation + preserved subdir + filename lookup + markdown parse actually work (fallback-only tests pass even when every real lookup is broken); (c) fallback: `attributedString(for: "NoSuchKind", id: "nope")` is non-empty and contains both `"NoSuchKind"` and `"nope"`, and produces a non-empty `AttributedString` (not just an empty string); (d) **cache race-safety:** a concurrent same-key `withTaskGroup` stress test over the sentinel key returns consistent values under contention (the naive "call twice, compare" does NOT prove caching — two fallback strings compare equal even with no cache). Production-enum conformance + a real-case happy-path remain deferred to 11.2/11.3.
   - (e) **Associated-value conformer inherits `docs` (Review pass 1, 3-reviewer consensus — locks the split-extension invariant).** A second Tests-only fixture — an associated-value enum with a HAND-WRITTEN `documentationID` (mirroring how `MLExecutionPolicy`/`AbstainReason` will conform in 11.3, since payload-carrying cases block raw-value synthesis) — has a resolvable `.docs`. This is the ONLY test guarding the reason the two extensions are separate (AC #2): a refactor that traps `docs` on the constrained `RawRepresentable` extension would silently strip `docs` from every associated-value conformer and MUST fail this test. Assert its `.docs` returns the fallback naming its `(documentedKind, documentationID)` (no resource ships for it) and is non-empty.
   - **Plain `import BoomBoomBoomKit`, NOT `@testable` (Review pass 1, low).** Every symbol the suite exercises is public, so a plain `import` enforces the consumer-visible surface — an accidental loss of `public` on the accessor or a default breaks the test (a `@testable` import would mask it).
   - **Honest concurrency-test scope (Review pass 1, low).** The `withTaskGroup` test is a concurrent-access SAFETY smoke test (no crash, no torn read, consistent values under contention). It does NOT claim to prove single-insertion / negative-cache behavior — that would require an injectable-loader or cache-reset test seam, which is out of scope here (the `Mutex` + double-checked-locking correctness is sound by inspection; a lost double-check only causes a benign redundant parse). The test comment must not overclaim.
   - (f) **Blank-parse guard test (Review pass 2, 3-reviewer unanimous).** `attributedString(for: "_Fixture", id: "_blank")` (the all-whitespace sentinel, AC #5) returns the fallback (contains `"Documentation unavailable"` and `"_blank"`), NOT the blank content — proving the whitespace-aware guard actually fires. Without a whitespace-only resource in the bundle this path is untestable, which is why the `_blank.md` sentinel ships.
   - (g) **Front-matter stripping test (PR #97 Codex review).** `attributedString(for: "_Fixture", id: "_frontmatter")` returns the prose body (contains `"Body"` / `"visible prose"`) and NOT the metadata (`id:`, `payload:`, the sentinel title token, or the `---` delimiters) — proving the accessor strips the KDD-E7 front-matter block before rendering. This closes the gap where every real 11.3 `.docs` would otherwise display implementation metadata ahead of the prose.

## Tasks / Subtasks

- [x] Task 1: Declare `DocumentedCase` protocol (AC: #1, #2, #6)
  - [x] Create `Sources/BoomBoomBoomKit/DocumentedCase.swift` (six-line header, `// MARK:` sections, `///` docs on all public symbols)
  - [x] `public protocol DocumentedCase: Sendable` (NO `Hashable` — dropped in Review pass 1; see AC #1) with `static var documentedKind: String`, `var documentationID: String`, `var docs: AttributedString`
  - [x] UNCONSTRAINED extension: default `docs` → `BoomBoomBoomKitDocs.attributedString(for: Self.documentedKind, id: documentationID)`
  - [x] CONSTRAINED extension `where Self: RawRepresentable, Self.RawValue == String`: `documentationID { rawValue }`
  - [x] Verify the two extensions are SEPARATE — `docs` must NOT be trapped on the constrained one, or associated-value conformers lose it (Codex)
  - [x] Confirm NO sibling protocols added (KDD-E1)
- [x] Task 2: Implement `BoomBoomBoomKitDocs` accessor + cache (AC: #3, #4)
  - [x] Create `Sources/BoomBoomBoomKit/BoomBoomBoomKitDocs.swift`: `public enum BoomBoomBoomKitDocs`, `import Synchronization`
  - [x] `private static let cache = Mutex<[CacheKey: AttributedString]>([:])`; `private struct CacheKey: Hashable { let kind: String; let id: String }`
  - [x] `public static func attributedString(for kind: String, id: String) -> AttributedString`: `if let cached = cache.withLock({ $0[key] }) { return cached }`; **malformed-input guard first** (Review pass 1) — if `kind`/`id` is empty or contains `/` or a `..` segment, skip resolution and use the fallback; else resolve via `Bundle.module.url(forResource: id, withExtension: "md", subdirectory: "Documentation/\(kind)")`, then `try? AttributedString(contentsOf: url, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace), baseURL: nil)` (one read+parse call — do NOT hand-roll `Data(contentsOf:)`); **treat a successful-but-empty parse (`parsed.characters.isEmpty`) as a MISS → fallback** (Review pass 1 — never-empty must hold on the success path, AC #4); then `cache.withLock { if let c = $0[key] { return c }; $0[key] = candidate; return candidate }` (double-checked). Nothing escapes either closure.
  - [x] Fallback `AttributedString("Documentation unavailable for \(kind).\(id).")` on any missing/unreadable/parse-failure path. **CACHE the fallback** (negative caching is safe — the resource bundle is fixed for the process lifetime; 11.3 ships a rebuild → new process → fresh static cache). State this in a doc comment.
  - [x] Follow the `ModelRegistry` `state.withLock { }` idiom (`ModelRegistry.swift:53-75`); do NOT hold the lock across I/O
- [x] Task 3: Wire SPM resources (AC: #5)
  - [x] `Package.swift`: add `resources: [.copy("Resources/Documentation")]` to the `BoomBoomBoomKit` target block (currently `Package.swift:13-16`, no `resources:` arg) — `.copy` NOT `.process` (KDD-4 overrides KDD-E6)
  - [x] Create `Sources/BoomBoomBoomKit/Resources/Documentation/.gitkeep`
  - [x] Create the sentinel `Sources/BoomBoomBoomKit/Resources/Documentation/_Fixture/_probe.md` with minimal known markdown (e.g. `**Probe.** Sentinel resource proving bundle resolution.`)
  - [x] `swift build` succeeds; confirm `Bundle.module` resolves in the core target AND the nested `Documentation/_Fixture/` structure survived `.copy` (the AC #7 happy-path test is the assertion)
- [x] Task 4: Tests (AC: #7)
  - [x] `Tests/BoomBoomBoomKitTests/DocumentedCaseTests.swift` (Swift Testing `@Suite`/`@Test`/`#expect`/`#require`); use plain `import BoomBoomBoomKit` (NOT `@testable` — every exercised symbol is public; Review pass 1)
  - [x] Fixture-conformer test: `enum FixtureCase: String, DocumentedCase { static let documentedKind = "FixtureCase"; case alpha; case beta }` → assert `FixtureCase.alpha.documentationID == "alpha"`
  - [x] **Associated-value conformer test (Review pass 1, load-bearing):** a second fixture — an associated-value enum with a hand-written `documentationID` (e.g. `enum PayloadCase: DocumentedCase { static let documentedKind = "PayloadCase"; case tuned(Double); var documentationID: String { "tuned" } }`) — assert its `.docs` resolves (returns the fallback naming `PayloadCase.tuned`, non-empty). Guards the split-extension invariant: a refactor trapping `docs` on the constrained extension MUST fail this.
  - [x] **Happy-path test (Codex-mandated, load-bearing):** `attributedString(for: "_Fixture", id: "_probe")` returns the sentinel's authored content (assert it contains the probe body, NOT the fallback string) — proves the `.copy` bundle+subdir+parse chain
  - [x] Fallback test: `attributedString(for: "NoSuchKind", id: "nope")` → non-empty `AttributedString`, `String(...)` contains `"NoSuchKind"` and `"nope"`
  - [x] Concurrent-access safety smoke test: `withTaskGroup` firing N concurrent `attributedString(for: "_Fixture", id: "_probe")` calls → all return equal, consistent values, no crash/torn read (replaces the weak "call twice, compare"). Comment must NOT overclaim single-insertion/negative-cache proof (Review pass 1 — that needs a test seam, out of scope; `Mutex` + double-checked-locking are sound by inspection)
- [x] Task 5: Gating checklist
  - [x] `make fmt` then `make lint` (order matters — formatter can introduce lint violations); zero new `// TODO:` in `Sources/`
  - [x] `make build` + `make test` green; record exact integer test counts in Completion Notes
  - [x] Confirm `Sources/`/`Tests/` changes are additive; run OA300/GiantSteps floors unaffected (this story is docs-infra, no DSP touch — note the byte-inertness of the analysis pipeline honestly)

## Dev Notes

### Apple-docs cross-check (Siri, 2026-07-15 — Xcode semantic index)
Verified against the Apple Developer Documentation before dev:
- **`Mutex`** (`Synchronization`): `@frozen struct Mutex<Value> where Value: ~Copyable`, conforms `Sendable`. Init `init(_ initialValue: consuming sending Value)`; `withLock` is `borrowing func withLock<Result, E>(_ body: (inout sending Value) throws(E) -> sending Result)`. Apple's own doc example is our exact use case: `let cache = Mutex<[Key: Resource]>([:])` + `cache.withLock { $0[key] = resource }`. A `static let cache = Mutex<[CacheKey: AttributedString]>([:])` is verbatim-correct.
- **Markdown parse**: `AttributedString.MarkdownParsingOptions.InterpretedSyntax.inlineOnlyPreservingWhitespace` confirmed (parses all markdown, interprets inline-span attributes only, preserves whitespace). Prefer `init(contentsOf:options:baseURL:) throws` (read+parse in one call) over the `Data`+`init(markdown:)` two-step. All markdown inits `throws`, default `failurePolicy: .throwError`.
- **`Bundle`**: `url(forResource:withExtension:subdirectory:)` signature confirmed; resolution is **case-sensitive** and does NOT recurse below the named subdirectory. On macOS the resource root is `Contents/Resources/`, so a `subdirectory: "Documentation/<kind>"` resolves to `Contents/Resources/Documentation/<kind>/` **iff the bundle preserves that structure** — see the OPEN item below.
- **RESOLVED (Codex 2026-07-15):** SwiftPM `.process` FLATTENS `Documentation/<Type>/` (copies unprocessed `.md` to the bundle top level) — it breaks `subdirectory:`-based resolution and collides `AbstainReason/sourceSpecific.md` vs `DemotionReason/sourceSpecific.md`. `.copy` preserves structure verbatim (`AudioFixtures.swift:15-37` + SwiftPM BundlingResources docs). The plan uses `.copy`, overriding epic KDD-E6 — see KDD-4 and the supersession note below.

### KDD-E6 supersession (2026-07-15)
> **AMENDED — KDD-E6 `.process` superseded by `.copy` for Story 11.1+ (Codex + SwiftPM BundlingResources docs).** `.process` copies unprocessed `.md` files to the bundle top level, flattening `Documentation/<Type>/` and colliding same-basename files (`sourceSpecific.md` ×2); it is incompatible with the `subdirectory:`-keyed accessor. `.copy` retains the directory structure verbatim. The load-bearing invariant (per-case docs resolvable by `(kind, id)` from `Bundle.module`) is preserved; only the SPM rule changes. Carry `.copy` forward to Stories 11.3 (authoring) and 11.5 (DocC transclude reads the same tree). Original KDD-E6 wording preserved in `epics.md` for audit; pre-1.0, breaking the epic KDD freely is sanctioned.

### Codex plan review (2026-07-15)
External review (Codex MCP) of this spec pre-implementation. Verdict: approve the `Mutex` / caseless-enum / fallback / deferred-conformance design; changes requested (all folded above): (1) BLOCKER `.process`→`.copy` [KDD-4/5, AC #5]; (2) add a sentinel happy-path resolution test [AC #7b, Task 3/4]; (3) concurrent cache-race test replacing "call twice, compare" [AC #7d]; (4) cache the fallback explicitly [Task 2]; (5) `attributedString(for:id:)` explicitly `public` [AC #3]; (6) separate the unconstrained `docs` default from the constrained `documentationID` [AC #2, Task 1]; (7) don't assert the epic's "7 of 9 free" count — resolve per-type at 11.3 [AC #2]. Codex explicitly AGREED: the double-checked `Mutex` locking is sound (redundant parse is benign), a `static let` `~Copyable Mutex` on a caseless enum has no Swift-6 concurrency gotcha (no `nonisolated(unsafe)` needed), and deferring production-enum conformance is reasonable.

### Architecture patterns and constraints
- **Caseless-enum namespace, not a class** (KDD-1 above). Core target's sole class is `ModelRegistry`; adding a second requires a named story — this story does not authorize one. `BoomBoomBoomKitDocs` is `public enum` with only static members.
- **All new public types conform to `Sendable`** (project-context.md tech-stack rule). `DocumentedCase: Sendable, Hashable`; `AttributedString` is already `Sendable`; the `Mutex` cache is `Sendable`.
- **Public API discipline (pre-1.0):** this internal→public addition IS the story's declared deliverable (AC #1/#3) — that satisfies "every internal→public promotion is declared in the story spec's AC." Public protocol signatures use named `Sendable` types only (no tuples): `documentedKind: String`, `documentationID: String`, `docs: AttributedString` all comply.
- **Six-line file header + `// MARK: -` sections + `///` doc comments on every public symbol** (code-organization rule). Cite KDD-E1/E2/E3/E5/E6 in doc comments where they explain a non-obvious choice.

### Source-tree components to touch (verified against current tree)
- NEW `Sources/BoomBoomBoomKit/DocumentedCase.swift`
- NEW `Sources/BoomBoomBoomKit/BoomBoomBoomKitDocs.swift`
- NEW `Sources/BoomBoomBoomKit/Resources/Documentation/.gitkeep`
- NEW `Sources/BoomBoomBoomKit/Resources/Documentation/_Fixture/_probe.md` (sentinel resource for the happy-path test)
- UPDATE `Package.swift:13-16` (core target block — add `resources: [.copy("Resources/Documentation")]`)
- NEW `Tests/BoomBoomBoomKitTests/DocumentedCaseTests.swift`

### Concrete in-repo precedents (read these before writing code)
- **Mutex cache idiom:** `Sources/BoomBoomBoomKit/ModelRegistry.swift:13` (`import Synchronization`), `:53-75` (`public final class ... Sendable { private struct State {...}; private let state = Mutex(State()); ... state.withLock { $0.entries } }`). Mirror the `withLock` access shape; adapt from `final class` to `enum` static member.
- **Second core-target `Mutex`:** `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:11` + `:2014`.
- **`Bundle.module` resolution + subdirectory + NFC/NFD fallback:** `Sources/BoomBoomBoomKitTestSupport/AudioFixtures.swift:15-37` (uses `.copy` + `subdirectory:` — the exact pattern this story adopts; ours is also `.copy` per KDD-4).
- **String-raw enum shape (conformance template for later stories):** `Sources/BoomBoomBoomKit/BPMSelectionPolicy.swift:11-50` (`public enum ... : String, CaseIterable, Sendable, Hashable` with `///` per-case docs), and the minimal `SignalSource.swift:8-13`.
- **Associated-value enum that CANNOT be `RawRepresentable`** (why 2 of 9 types override `documentationID`): `Sources/BoomBoomBoomKit/EnsemblePolicy.swift:133-145` (hand-rolled `stableKey` because `.weightedVoting(SignalWeights)` blocks raw-value synthesis). This is the pattern the manual `documentationID` override will follow in 11.3a.

### Testing standards
- **Swift Testing only** (`@Suite`, `@Test`, `#expect`, `#require`) — never XCTest. New test utilities that consuming packages would need go in `BoomBoomBoomKitTestSupport`, but this fixture conformer is test-internal, so it stays in the test target.
- **Happy-path proven via a `_`-prefixed sentinel, NOT a real case file** — 11.1 ships `Documentation/_Fixture/_probe.md` (AC #5) so the resolution chain is actually tested (Codex: fallback-only tests pass even when every real lookup is broken). Do NOT fabricate a real-CASE fixture (e.g. `BPMSelectionPolicy/maxConfidence.md`) — that would present fallback-free prose before 11.3 authors it and could trip 11.4's validator. The `_`-prefix keeps the sentinel out of 11.4's per-file validator (which skips `_`-stem files). Production-case happy-path stays 11.3/11.4's job.
- **`make test` runs only `BoomBoomBoomKitTests`** — corpus benchmarks are a separate env-gated target and are irrelevant here.

### Project Structure Notes
- Resource directory path `Sources/BoomBoomBoomKit/Resources/Documentation/` aligns with the epic spec; `.copy` (KDD-4) preserves the `Documentation/<Type>/` structure the accessor resolves against via `subdirectory: "Documentation/<kind>"`. The sentinel happy-path test (AC #7) verifies this at build/test time (probe `Bundle.module.resourceURL` if resolution behaves unexpectedly). No conflict with existing structure — the core target has no `Resources/` today.
- Main-bound epic: this is library source (`Sources/`, `Tests/`, `Package.swift`) — it ships to `main`. Unlike Epic 10 (demo-only), there is NO byte-identity net; new public API is expected and declared. Keep everything additive and dependency-free (Synchronization is an Apple framework — allowed).

### References
- [Source: _bmad-output/planning-artifacts/epics.md#Story 11.1: DocumentedCase protocol, Bundle.module accessor, Mutex<T> cache]
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 11: Per-case selection-strategy docs] (KDD-E1…E8)
- [Source: _bmad-output/project-context.md#Language-Specific Rules] (sole-class rule, Sendable, caseless-enum namespaces)
- [Source: _bmad-output/project-context.md#Public API Discipline (pre-1.0)] (named-Sendable-types, internal→public-in-AC)
- [Source: Sources/BoomBoomBoomKit/ModelRegistry.swift:53-75] (Mutex idiom)
- [Source: Sources/BoomBoomBoomKitTestSupport/AudioFixtures.swift:15-37] (Bundle.module + subdirectory)
- [Source: Package.swift:13-16] (core target block, no resources arg)

### Previous Story Intelligence (Epic 11 story 1 — no prior story in this epic)
No in-epic predecessor. Load-bearing cross-epic prior art instead:
- **Epic 6 (Story 6.5a)** landed `ComputeBudget` + `MLExecutionPolicy` as *declared-but-not-yet-Options-wired* public forward surface — the same "ship the seam ahead of its consumer" shape this story uses (protocol + accessor exist before any production conformer). Precedent that forward-declared public API without a live consumer is accepted here.
- **Epic 9** landed `ModelRegistry` — the one sanctioned class + the `Mutex` idiom this story reuses. Do not add a second class.
- **Epic 8** landed `DownbeatResult` (enum) — one of the 9 future conformers; no action here.
- **Epic 10 retro (2026-07-12):** demo-UI stories carry an extra GUI-smoke discipline. 11.1 is pure library infra (no UI), so that discipline does not apply — but Story 11.6 (later) does. Not this story.

### Pending user action (operator-owned closeout — surface at `review`)
Per project-context.md workflow rules, the auto-mode dev agent cannot complete these; list them in Completion Notes when the story reaches `review`:
- `/bmad-code-review` on a separate-LLM cadence (project convention).
- Final commit on the 1Password GPG signer. Suggested subject: `Story 11-1: DocumentedCase protocol + Bundle.module docs accessor + Mutex cache`. End the body with the `Claude-Session:` trailer.
- Branch: land the PR into `rterhaar/epic-11` (umbrella), not `develop` directly (Epic 6/7 workflow, operator-confirmed 2026-07-15).

## Spec Change Log

### 2026-07-15 — Review pass 1 amendment (bad_spec loopback, review_loop_iteration 1)
- **Triggering findings (3-reviewer consensus — Blind Hunter, Edge Case Hunter, Codex):**
  1. `DocumentedCase: Sendable, Hashable` bound overturns `MLExecutionPolicy`'s checked-in `Sendable, Equatable` (deliberately non-`Hashable`) — a named future conformer — and is unused by the docs mechanism (cache keys on an internal `(kind,id)`, never on `Self`).
  2. Never-empty (FR-49) violated on the parse-SUCCESS path: an empty/whitespace-only or block-only `.md` parses without throwing to an empty `AttributedString`, cached and returned — the code only fell back on `throw`.
  3. The split-extension invariant (associated-value conformers inherit `docs` from the UNCONSTRAINED extension) had no test — a refactor trapping `docs` on the constrained extension would pass the suite while stripping `docs` from all named future conformers.
- **Amended (outside any intent-contract — this story has none):** AC #1 + Task 1 (drop `Hashable` → `Sendable`); AC #4 + Task 2 (empty-parse-is-a-miss guard + empty/path-separator input guard); AC #7 + Task 4 (associated-value conformer `docs` test; plain `import`; honest concurrency-test wording). Folded low-severity patches: `@testable`→plain `import`; malformed-input guard; comment de-overclaiming.
- **Known-bad state avoided:** shipping a foundational protocol whose `Hashable` bound blocks the very conformers the story schedules for 11.3, plus a "total function" that returns empty on a real (author-error) input path.
- **KEEP (must survive re-derivation):** the caseless-enum `BoomBoomBoomKitDocs` namespace; `Mutex` + double-checked locking with I/O outside the lock; the `.copy("Resources/Documentation")` SPM wiring (Codex verified the bundle layout is correct); the `_Fixture/_probe.md` sentinel + load-bearing happy-path test; cached-fallback (negative caching) rationale; the six-line header / `// MARK:` / `///`-on-public-symbols house style; deferred production-enum conformance.
- **Epic reconciliation:** `epics.md` line ~1540 (`Sendable, Hashable`) carries a supersession note mirroring the KDD-E6 precedent. KDD-E2 (the `var docs` shape) is untouched — it never governed the superprotocol bound.

## Review Triage Log

### 2026-07-15 — Review pass (iteration 1)
- intent_gap: 0
- bad_spec: 3 (high 1, medium 2)
- patch: 3 (low 3)
- defer: 0
- reject: 8 (medium 3, low 5)
- addressed_findings:
  - `[high]` `[bad_spec]` Drop `Hashable` from `DocumentedCase` — bound unused by the mechanism and overturns `MLExecutionPolicy`'s checked-in non-`Hashable` contract (named future conformer). AC #1 + Task 1 amended; epics.md line ~1540 superseded.
  - `[medium]` `[bad_spec]` Never-empty (FR-49) hole on the parse-success path — treat `parsed.characters.isEmpty` as a miss → fallback. AC #4 + Task 2 amended.
  - `[medium]` `[bad_spec]` Split-extension invariant untested — add an associated-value fixture conformer asserting inherited `.docs`. AC #7 + Task 4 amended.
  - `[low]` `[patch]` `@testable import` → plain `import BoomBoomBoomKit` (exercised surface is all public). Task 4.
  - `[low]` `[patch]` Malformed-input guard (empty/`/`/`..` `kind`/`id` → fallback, no untrusted interpolation into `subdirectory:`). AC #4 + Task 2.
  - `[low]` `[patch]` De-overclaim the concurrency-test comment + the "can never be served" doc note (transient-failure caveat). AC #7 + Task 4.
- rejected (rationale, not silent): unbounded negative-cache growth (bounded for the closed enum-driven keyspace; eviction is unwarranted pre-1.0 complexity — the malformed-input guard partially mitigates the hostile-key angle); synchronous I/O in a property getter (deliberate synchronous `.docs` design; tiny cached bundled reads); test-isolation / cache-reset seam (unreachable — the bundle is immutable, so a given key always resolves identically); redundant `.gitkeep` (0-byte; retains forward dir-reservation value for when 11.3 retires the sentinel); sentinel ships to `main` (necessary + `_`-prefixed + retired in 11.3; Codex verified the layout is correct and load-bearing); unlocalized fallback string (error-path diagnostic, zero-dep library, out of scope); NFC/NFD filename normalization (docs IDs are ASCII enum identifiers — no ambiguity for the closed set); transient-read-failure cache poisoning (near-unreachable for immutable local bundled resources; only the doc-comment overclaim was worth softening, folded as a patch).

### 2026-07-15 — Review pass (iteration 2, post-re-derive)
- intent_gap: 0
- bad_spec: 0
- patch: 4 (medium 1, low 3)
- defer: 0
- reject: 3 (low 3)
- addressed_findings:
  - `[medium]` `[patch]` **Whitespace-only `.md` bypassed the blank guard (3-reviewer unanimous — Blind Hunter + Edge Case Hunter + Codex).** `!parsed.characters.isEmpty` catches only zero-length parses; inline-only mode preserves whitespace, so an all-whitespace file returned a visually-blank string, contradicting the guard's own comment + FR-49. Fixed: guard now `parsed.characters.contains(where: { !$0.isWhitespace })`; shipped a whitespace-only `_Fixture/_blank.md` sentinel + a test asserting it returns the fallback. (No spec loopback — the spec intent already said whitespace-only is a miss; the code under-implemented it.)
  - `[low]` `[patch]` Doc-accuracy: the `kind`/`id` "case-sensitive" claim is false on default APFS (case-insensitive). Softened the accessor doc to "case-preserving; resolution filesystem-dependent (case-insensitive on default APFS)".
  - `[low]` `[patch]` Doc-accuracy: the dropped-`Hashable` rationale said `Hashable` "would exclude NaN-bearing conformers" (imprecise — NaN types satisfy `Hashable`, just with broken semantics). Reworded to the correct reasons: unnecessary (cache keys on the internal tuple) + would exclude `MLExecutionPolicy`'s checked-in non-`Hashable` design.
  - `[low]` `[patch]` Doc-accuracy: the "inline-only mode strips block content" comment overstated it (preserving-whitespace retains block markup as literal text). Reworded.
- rejected (rationale, not silent): unbounded negative-cache growth (re-raised; Codex confirms bounded/safe for the immutable-bundle closed-set usage; eviction remains unwarranted pre-1.0); `.gitkeep` in the shipped bundle (re-raised; 0-byte, forward dir-reservation value; Codex: "not a defect"); test-only sentinel(s) ship to `main` (re-raised; necessary + `_`-prefixed + retired in 11.3; Codex verified load-bearing and correct).
- Both hunters + Codex explicitly confirmed: NO correctness defect, NO wrong fix, NO bad_spec this pass — the whitespace hole is the only new item and is a completeness patch.

### 2026-07-16 — PR #97 review (Codex connector, on the pushed branch)
- intent_gap: 0
- bad_spec: 0
- patch: 1 (medium 1)
- defer: 0
- reject: 0
- addressed_findings:
  - `[medium]` `[patch]` **Strip YAML front-matter before parsing (Codex P2, PR #97 discussion r3592462151).** KDD-E7 mandates a `---`-delimited `id:`/`title:`/`payload:` block in every authored 11.3 doc file; the accessor parsed the whole file, so once 11.3 lands, every real `.docs` would render implementation metadata as literal text ahead of the prose. **Verdict: 11.1 scope, not 11.3** — front-matter handling is the accessor's parse-path responsibility (11.3a/b are prose-authoring stories); the schema is already fixed in KDD-E7, so it's knowable now; and deferring guarantees a latent "every doc shows metadata" bug the moment 11.3a lands. Fixed: `resolve` now reads raw text (`String(contentsOf:encoding:)`, replacing the one-call `AttributedString(contentsOf:)`) and strips a leading `---`…`---` block via `strippingFrontMatter(_:)` before `AttributedString(markdown:)`. Unterminated/absent front-matter leaves text untouched (11.4 validator's job; accessor stays total). Shipped `_Fixture/_frontmatter.md` sentinel + test (g) asserting the body renders and the metadata does not. 853 tests / 140 suites green.

## Dev Agent Record

### Agent Model Used

claude-opus-4-8[1m] (bmad-dev-auto workflow, implementation subagent)

### Debug Log References

- Stale-SourceKit index lag flagged `Cannot find 'BoomBoomBoomKitDocs' in scope` in `DocumentedCase.swift` immediately after each sibling-file creation (both passes). Not a real error — same-module symbol; `make build` + `make test` resolve it cleanly.

### Completion Notes List

- **Implemented in two passes.** Pass 1 shipped green (850 tests); a 3-reviewer adversarial pass (Blind Hunter + Edge Case Hunter + Codex) found a `bad_spec` root cause (the epic AC's `Hashable` bound) + two more bad_spec + three low patches. Spec amended (see Spec Change Log + Review Triage Log), code re-derived. Pass 2 is the shipped state.
- **The 6 Review-pass-1 corrections, all in the re-derived code:** (1) `public protocol DocumentedCase: Sendable` — no `Hashable`; (2) blank-parse treated as a miss → fallback (strengthened in iteration 2 to whitespace-aware `parsed.characters.contains(where: { !$0.isWhitespace })`); (3) `isSafeIdentifier` guard (empty / `/` / `..`) before any `subdirectory:` interpolation; (4) tests use plain `import BoomBoomBoomKit`, not `@testable`; (5) associated-value fixture `PayloadCase.tuned(Double)` asserts inherited `.docs` (locks the split-extension invariant); (6) comments de-overclaimed (concurrency test = safety smoke; cache note does not claim a transient miss "can never be served").
- `Mutex` from `Synchronization` compiled cleanly both passes — no `OSAllocatedUnfairLock` pressure-valve needed (no `11-1-pressure-release.md`).
- `.copy("Resources/Documentation")` (overrides epic KDD-E6 per KDD-4). Codex independently verified the bundle layout — `Documentation/_Fixture/_probe.md` resolves through `Bundle.module` + `subdirectory:`; the load-bearing happy-path test asserts the probe body renders (not the fallback), proving the `.copy` chain end-to-end.
- Production-enum conformance deferred to 11.2/11.3 per KDD-3 — only the mechanism + sentinel-backed proof ship here.
- **Iteration-2 review (post-re-derive) — patch-only, no loopback.** A 3-reviewer pass (Blind Hunter + Edge Case Hunter + Codex) unanimously confirmed the re-derived code has NO correctness defect and the pass-1 fixes are correct, and found one completeness gap: the empty-parse guard `!parsed.characters.isEmpty` under-caught an ALL-WHITESPACE file (inline-only mode preserves whitespace → non-empty-but-blank). Patched: guard is now `parsed.characters.contains(where: { !$0.isWhitespace })`, plus a shipped all-whitespace `_blank.md` sentinel + a test asserting it falls back. Three low doc-accuracy patches folded (case-sensitivity claim softened for APFS; `Hashable` rationale corrected; inline-only "strips" wording fixed). Re-raised rejects (cache growth, `.gitkeep`, sentinel-to-main) held with rationale.
- **Gating (final, all green):** `make fmt` clean; `make lint` `Found 5 violations, 0 serious in 176 files` — all 5 pre-existing `Demo/`-only (zero in the new source/test files, grep-confirmed); `make build` "Build complete!"; `make test` = **853 tests / 140 suites passed** (the `Story 11.1 DocumentedCase` suite contributes 7 tests: shape, happy-path, fallback, associated-value-inherits-docs, blank-parse-guard, front-matter-strip, concurrent-safety). Orchestrator-verified. [Count corrected 2026-07-18 close-out review — the enumeration was written pre-PR-#97 and omitted the front-matter-strip test (g); the suite ships 7 @Test methods.]
- Purely additive; no DSP touched — OA300/GiantSteps accuracy floors byte-unaffected.

**Operator-owned closeout (auto-mode cannot do these — surfaced at review):**
- `/bmad-code-review` on a separate-LLM cadence (project convention).
- Final commit on the 1Password GPG signer. Suggested subject: `Story 11-1: DocumentedCase protocol + Bundle.module docs accessor + Mutex cache`. End the body with the `Claude-Session:` trailer.
- Land the PR into `rterhaar/epic-11` (umbrella), not `develop` directly.

### File List

- NEW `Sources/BoomBoomBoomKit/DocumentedCase.swift`
- NEW `Sources/BoomBoomBoomKit/BoomBoomBoomKitDocs.swift`
- NEW `Sources/BoomBoomBoomKit/Resources/Documentation/.gitkeep`
- NEW `Sources/BoomBoomBoomKit/Resources/Documentation/_Fixture/_probe.md` (happy-path sentinel)
- NEW `Sources/BoomBoomBoomKit/Resources/Documentation/_Fixture/_blank.md` (all-whitespace sentinel — proves the blank-parse guard, Review pass 2)
- NEW `Sources/BoomBoomBoomKit/Resources/Documentation/_Fixture/_frontmatter.md` (front-matter sentinel — proves front-matter stripping, PR #97 Codex review)
- NEW `Tests/BoomBoomBoomKitTests/DocumentedCaseTests.swift`
- UPDATE `Package.swift` (added `resources: [.copy("Resources/Documentation")]` to the `BoomBoomBoomKit` target block)
- UPDATE `_bmad-output/planning-artifacts/epics.md` (develop-only; reconciled the Story 11.1 AC + KDD-E2 note — `Hashable` dropped from the protocol bound, mirroring the KDD-E6 supersession precedent)

## Auto Run Result

Status: **done**

### Summary of implemented change
Story 11.1 lands the Epic 11 documentation foundation: a `public protocol DocumentedCase: Sendable` (with a `docs: AttributedString` default resolving `Documentation/<kind>/<id>.md` from `Bundle.module`), a thread-safe `public enum BoomBoomBoomKitDocs` accessor backed by a `Synchronization.Mutex` cache with I/O outside the lock and double-checked insertion, and the SPM `.copy("Resources/Documentation")` wiring. The accessor is a total function (non-optional, non-throwing, informative non-empty fallback on any miss — missing / unreadable / parse-failure / blank-parse / malformed-input). No production enum is conformed yet (deferred to 11.2/11.3); the mechanism is proven by a Tests-only fixture conformer + `_`-prefixed sentinel resources.

### Files changed
- `Sources/BoomBoomBoomKit/DocumentedCase.swift` (new) — the protocol + unconstrained `docs` default + constrained `documentationID { rawValue }`.
- `Sources/BoomBoomBoomKit/BoomBoomBoomKitDocs.swift` (new) — the `Mutex`-cached, I/O-outside-lock accessor with blank-parse + malformed-input guards.
- `Sources/BoomBoomBoomKit/Resources/Documentation/{.gitkeep, _Fixture/_probe.md, _Fixture/_blank.md}` (new) — dir reservation + happy-path sentinel + whitespace sentinel.
- `Tests/BoomBoomBoomKitTests/DocumentedCaseTests.swift` (new) — 7 tests (shape, happy-path, fallback, associated-value-inherits-docs, blank-parse-guard, front-matter-strip, concurrent-safety).
- `Package.swift` (update) — `.copy` resources on the core target.
- `_bmad-output/planning-artifacts/epics.md` (update, develop-only) — reconciled the `Hashable`-drop.

### Review findings breakdown
- **Iteration 1 (bad_spec loopback):** 3 bad_spec (drop `Hashable` [high]; blank-parse never-empty hole [med]; split-extension invariant untested [med]) + 3 low patches; 8 rejected. Spec amended, code re-derived.
- **Iteration 2 (patch-only):** 1 medium patch (whitespace-only blank-parse guard — 3-reviewer unanimous, test-locked) + 3 low doc-accuracy patches; 3 rejected (re-raised, held with rationale). No bad_spec, no intent_gap — reviewers confirmed no correctness defect and no wrong fix.
- Three independent reviewers used across both passes: Blind Hunter + Edge Case Hunter (bmad review skills) + Codex (operator-requested each pass).

### Follow-up review recommendation
**false.** The final pass applied only patches; the single behavior change (whitespace-aware blank guard) is tiny, localized, test-locked, and was specified verbatim by three converging reviewers. No API/security/data breadth. An independent follow-up review is not warranted.

### Verification performed
- `make fmt` clean; `make lint` 5 pre-existing `Demo/`-only violations (0 in new files, grep-confirmed); `make build` "Build complete!"; `make test` **853 tests / 140 suites passed**. Gates re-run and confirmed by the orchestrator after every material change (pass 1, re-derive, iteration-2 patches).
- Codex empirically verified the built bundle contains `Documentation/_Fixture/_probe.md` at the exact nested path (the `.copy` layout is correct).

### Residual risks
- **Operator-owned closeout remains** (auto-mode cannot do these): separate-LLM `/bmad-code-review`; the final 1Password-signed commit (suggested subject `Story 11-1: DocumentedCase protocol + Bundle.module docs accessor + Mutex cache`, `Claude-Session:` trailer); landing the PR into `rterhaar/epic-11`. No commit was made this run (project convention overrides the skill's auto-commit step), so `final_revision` == `baseline_revision`.
- Accepted-with-rationale (not defects): the negative cache is unbounded (bounded in practice for the closed enum keyspace); the `_`-prefixed sentinel resources + `.gitkeep` ship in the public bundle until 11.3 authors real case files and retires them.
- `main`-bound change: everything except `epics.md` ships to `main`. Additive, zero-dependency (`Synchronization` is Apple). No byte-identity net applies (unlike Epic 10) — new public API is the declared deliverable.

## Code Review Findings — close-out (2026-07-18)

Separate-LLM `/bmad-code-review` over the shipped 11-1 surface (`07dfddf..9a9fa73`), 4 adversarial layers: Blind Hunter + Edge Case Hunter + Acceptance Auditor + Codex blind-hunter (`019f73e3`, gpt-5.6-sol/medium). **Verdict: clean.** All four independently confirmed the `Mutex` double-checked-locking is correct (I/O + parse outside the lock, only `Sendable` `AttributedString` values escape, no reentrancy/deadlock); the Acceptance Auditor verified all 7 ACs satisfied. No blocking, high, or medium finding requires a code change. Triage: 0 decision-needed, 0 shippable-code patches, 3 defer, 4 dismiss, 1 develop-only doc-note patch (applied).

- [x] **[Review][Defer] Unbounded negative cache** [`BoomBoomBoomKitDocs.swift:45`] — deferred as **W88**. Pre-existing/by-design; already noted in Residual Risks. Bounded in-library (49-key surface); footgun only via direct `attributedString(for:id:)` with high-cardinality strings.
- [x] **[Review][Defer] Transient read-failure permanently negative-cached (first-writer-wins)** [`BoomBoomBoomKitDocs.swift:82-88,113`] — deferred as **W89**. Codex finding; already acknowledged verbatim in the cache `- Note:` (lines 42-44). Graceful, bounded (one doc → fallback until restart under rare fd pressure).
- [x] **[Review][Defer] `_Fixture` sentinels ship in the public bundle** [`Package.swift` `.copy`] — deferred as **W90**. Already noted in Residual Risks; by-design tension (the bundle-resolution test resolves `_probe` through `Bundle.module`, so the sentinel must ship). Harmless `_`-prefixed pollution.
- [x] **[Review][Patch] Completion-Notes stale test count (6 → 7)** — applied. The enumeration (lines ~228/259) predated PR #97's front-matter-strip test (g); corrected to 7 with the front-matter test named.
- Dismissed (4, handled-in-source / convention-safe): unterminated-front-matter metadata leak + leading-`---` body-discard (both documented in `strippingFrontMatter`'s doc-comment, caught at dev-time by 11.4's shipped validator; authored docs all carry front matter per KDD-E7); `isSafeIdentifier`'s `..` substring over-reject (hypothetical stems only); bare-CR-only line endings (archaic; authored docs are LF/CRLF, CRLF verified safe).

**Status → `done`.** The 11-1 code is already committed (`3c6996b` + `9a9fa73`, signed); the only pending operator action is the 1Password-signed commit of this close-out's develop-only artifact updates (this findings section + `sprint-status.yaml` flip + deferred-work W88–W90).
