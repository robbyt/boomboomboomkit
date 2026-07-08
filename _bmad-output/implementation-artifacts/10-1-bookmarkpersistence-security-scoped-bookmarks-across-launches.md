---
baseline_commit: b4d7211dd031ec81f927eacbd0ba97a0f2148b55
---

# Story 10.1: BookmarkPersistence — security-scoped bookmarks across launches

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **demo developer ensuring user-added models survive app restarts**,
I want **a `BookmarkPersistence` helper that stores security-scoped bookmark `Data` in `UserDefaults` and resolves it on launch**,
so that **user-added model URLs from the file picker keep resolving after the demo relaunches, without re-prompting the user**.

> **Renumber note (2026-07-07 party-mode):** this was Story 10.2 in the original epic draft. It swaps to **10.1** because Story 10.2 (`ModelPickerView`) *consumes* `BookmarkPersistence.store(...)` — the dependency now runs top-to-bottom. Nothing about the story's scope changed; only its number and the two cross-references in `epics.md`. See `epics.md` › `partyModeAmendmentsApplied` (2026-07-07).

## Acceptance Criteria

**AC1 — All three entitlement keys present (the third is the one developers forget).**
**Given** the demo's sandbox entitlements file,
**When** the operator inspects `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BoomBoomBoomBPM.entitlements`,
**Then** all of these keys are present and `true`: `com.apple.security.app-sandbox` (NFR-9), a user-selected file-access key (`com.apple.security.files.user-selected.read-write` is already present and is a superset of the epic's `read-only` — see **DD1**; keep it, do NOT downgrade), **AND** the currently-missing `com.apple.security.files.bookmarks.app-scope`. The third key is load-bearing for app-scoped bookmarks and is absent today; this story adds it.

**AC2 — Store a security-scoped bookmark keyed by a stable demo-owned UUID.**
**Given** the user picks a model file via the Story 10.2 file picker,
**When** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BookmarkPersistence.swift` creates a bookmark from the picked `URL` with `.withSecurityScope` (app-scoped → `relativeTo: nil`; and since a model is a read-only input, combine with `.securityScopeAllowOnlyReadAccess` for least privilege — see **DD1**/**Apple-docs verification**),
**Then** the resulting `Data` is persisted in the injected `UserDefaults`, keyed by a **demo-minted, stable `UUID`** (the registry is ephemeral — see **DD2**), mirroring the injected-`UserDefaults` precedent from Story 5-6 (KDD-D3, inlined in `AnalysisViewModel`); **no Keychain, no file-system sidecar, no JSON wrappers** — the stored value is plist-native `[String: Data]`.

**AC3 — Resolve-all on launch, refresh stale, drop-on-failure without prompting.**
**Given** the demo relaunches and `BookmarkPersistence.resolveAll()` runs during startup,
**When** any stored bookmark resolves with `bookmarkDataIsStale == true`,
**Then** that entry is refreshed (re-create the bookmark from the resolved URL, re-persist under the same UUID); if resolution *throws*, the entry is dropped from the persisted map with a labeled diagnostic (`Reason: bookmark-resolution-failed`) and the user is **NOT** prompted mid-launch. `resolveAll()` returns only the entries that resolved.

**AC4 — Security-scoped access is bracketed (the file-I/O footgun).**
**Given** a resolved model URL is about to be read (by Story 10.2 / the analysis path),
**When** the caller reads bytes from that URL,
**Then** access is bracketed by `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()` (stop iff start returned `true`, balanced via `defer`). `BookmarkPersistence` provides a `withSecurityScopedAccess(_:perform:)` convenience so callers cannot leak or double-release the scope (see **DD3**). `resolveAll()` returns resolved URLs with the scope **not yet started**; the bracket is the caller's per-use responsibility.

**AC5 — Persistence/stale/drop logic is CI-testable via an injected bookmark seam.**
**Given** the demo unit-test target runs under `swift test` / `make demo-test` (unsigned, non-sandboxed — `.withSecurityScope` bookmark creation is unreliable there),
**When** `BookmarkPersistenceTests` exercises store → resolveAll → stale-refresh → drop-on-throw,
**Then** the bookmark encode/decode is behind an injectable seam (default = real `URL.bookmarkData` / `URL(resolvingBookmarkData:)`; tests inject a fake that can force `isStale` and `throw`), and every test uses an isolated `UserDefaults(suiteName:)` with `removePersistentDomain(forName:)` cleanup — the Story 5-6 test pattern — so cases run in parallel without contaminating `.standard`.

**AC6 — Entitlement is load-bearing (operator-run negative path, honestly scoped).**
**Given** `com.apple.security.files.bookmarks.app-scope` is temporarily removed,
**When** the demo is built with `make demo-build-sandboxed` (**NOT** `demo-build`, which bypasses signing so entitlements never attach — Story 5-1 DD #6) and relaunched,
**Then** bookmark resolution fails on the second launch, confirming the entitlement is load-bearing. This is an **operator-run manual verification** documented in the story implementation artifact — it is explicitly **not** a `swift test` assertion (a non-sandboxed CI process cannot reproduce it). Document the run (or its deferral) in the completion notes.

## Tasks / Subtasks

- [x] **Task 1 — Add the missing entitlement (AC1).**
  - [x] In `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BoomBoomBoomBPM.entitlements`, add `<key>com.apple.security.files.bookmarks.app-scope</key><true/>`.
  - [x] Keep the existing `com.apple.security.files.user-selected.read-write` (DD1 — superset of the epic's `read-only`; the audio-file open path already relies on it). Do NOT downgrade.
  - [x] Confirm `com.apple.security.app-sandbox` stays `true`.

- [x] **Task 2 — `BookmarkPersistence` type + injectable bookmark seam (AC2, AC5).**
  - [x] Create `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BookmarkPersistence.swift`.
  - [x] Declare it `nonisolated` and `Sendable`-clean (the demo target defaults to `@MainActor` isolation — mark pure helpers `nonisolated` so off-actor tests can drive them; precedent: `nonisolated enum SignalPoolDiagnostics`). It is a helper over `UserDefaults`, not a view model.
  - [x] Inject `UserDefaults` (mirror `AnalysisViewModel.Configuration.defaults`) so tests supply an isolated suite.
  - [x] Inject the bookmark codec seam: a small protocol or closure pair `makeBookmark(URL) throws -> Data` / `resolveBookmark(Data) throws -> (url: URL, isStale: Bool)`, defaulting to the real `.withSecurityScope` calls. Tests inject a fake.
  - [x] Persist a single plist-native `[String: Data]` map under ONE stable key (UserDefaults has no prefix-scan, so a single enumerable dictionary is cleaner than per-UUID keys + a separate index). Key the dictionary by `UUID().uuidString`. `store(url:) -> UUID` mints the UUID, encodes the bookmark, writes the map.

- [x] **Task 3 — `resolveAll()` with stale-refresh + drop-on-failure (AC3).**
  - [x] `resolveAll() -> [(id: UUID, url: URL)]`: read the map, resolve each bookmark, refresh+re-persist when `isStale`, drop+diagnostic when resolve throws, never prompt. Return only resolved entries.
  - [x] Emit the labeled diagnostic `Reason: bookmark-resolution-failed` (FR-44 discipline — labeled, not a bare value) on the drop path. Persist the pruned map back.

- [x] **Task 4 — Security-scoped access bracket helper (AC4).**
  - [x] Add `withSecurityScopedAccess<T>(to url: URL, perform: () throws -> T) rethrows -> T`: call `startAccessingSecurityScopedResource()`, `defer { if started { url.stopAccessingSecurityScopedResource() } }`, run the body. Stop iff start returned `true`.
  - [x] Document that `resolveAll()` hands back URLs with the scope NOT started; Story 10.2 / the analysis call site wraps its read in this helper.

- [x] **Task 5 — Tests (AC5) — red first.**
  - [x] Create `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/BookmarkPersistenceTests.swift`, mirroring `MergeStrategyPersistenceTests` isolation (`UserDefaults(suiteName:)` + `removePersistentDomain(forName:)`, parallel-safe).
  - [x] Cover: store→resolveAll round-trip (fake seam); `isStale` forces refresh + re-persist (assert the stored Data changed); resolve-throw drops the entry + prunes the map + leaves siblings intact; empty/absent map resolves to `[]`; the access-bracket helper balances start/stop (assert stop only when start returned true, via a fake URL access counter or a documented note if not fakeable).
  - [x] These are pure-logic tests over injected seams — no real security scope, so they run green in unsigned CI.

- [x] **Task 6 — Gauntlet + operator-run negative path (AC6).**
  - [x] `make demo-fmt`, `make demo-build` (BUILD SUCCEEDED), `make demo-test` (TEST SUCCEEDED), `make demo-lint` (`confidence-label-audit: PASS` — the `Reason:` diagnostic is labeled, no bare numerics).
  - [x] `git diff --stat Sources/ Tests/` empty (demo-only; library byte-identical by construction).
  - [x] Record the AC6 operator verification (`make demo-build-sandboxed` with the entitlement removed → 2nd-launch resolution fails) in Completion Notes, or mark it operator-deferred with the exact command.

## Dev Notes

### What this story is (and is NOT)
- **IS:** a self-contained, demo-only `UserDefaults` persistence helper for security-scoped bookmarks + the entitlement that makes it work. Zero library (`Sources/`) change. Zero `Tests/` (library) change.
- **IS NOT:** the model picker UI (that is Story 10.2, which calls `store(url:)` here) and IS NOT any change to the `ModelRegistry` library type.

### Critical: the registry is ephemeral — the demo owns the persistent map (DD2)
`ModelRegistry` (Epic 8, `Sources/BoomBoomBoomKit/ModelRegistry.swift`) is an in-memory, `Mutex`-guarded catalog that is **re-registered every launch** — its own docs say "persist the `ModelDigest` hex in `UserDefaults`, re-registering on launch." `ModelRegistryEntry` is keyed by a consumer-chosen `identifier: String` and carries `url: URL`, `digest`, etc.; there is **no built-in UUID and no `save`/`load`**. So the persistent identity of a user-added model is a **demo-side construct**: `BookmarkPersistence` mints the stable `UUID`, owns the `{uuidString: bookmarkData}` map, and on launch Story 10.2 will resolve each bookmark → `URL` → `ModelRegistry.register(url:)`. That is exactly FR-38 ("demo owns persistence for user-added models only"). [Source: Sources/BoomBoomBoomKit/ModelRegistry.swift#L20-L51, ModelRegistryEntry.swift#L188-L236]

### The precedent to mirror — Story 5-6, inlined in AnalysisViewModel (KDD-D3)
There is **no standalone `MergeStrategyPersistence` type**; the "precedent" is the pattern inlined in `AnalysisViewModel.swift`: a `Configuration` struct that injects `defaults: UserDefaults` (so tests pass an isolated suite), stable `static let …Key` strings, and — the Epic 9 hardening — a `object(forKey:)`-based self-heal (absent → fallback; present-but-unusable → `removeObject` + fallback). `MergeStrategyPersistenceTests` uses `UserDefaults(suiteName:)` + `removePersistentDomain(forName:)` for parallel isolation. Mirror the **injection + isolation + self-heal** discipline; the storage shape differs (bookmark `Data` map, not a single `String` rawValue). [Source: Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift#L20-L120, Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/MergeStrategyPersistenceTests.swift]

### Security-scoped bookmark lifecycle (the footgun — DD3)
Long-standing macOS sandbox API (not a new-OS surface):
- **Create:** `url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)`.
- **Resolve:** `URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)`.
- **Access:** the resolved URL is NOT usable for file I/O until `startAccessingSecurityScopedResource()` (returns `Bool`); balance every successful start with exactly one `stopAccessingSecurityScopedResource()` (via `defer`). This is why AC4 exists — hide it behind `withSecurityScopedAccess(_:perform:)`.
- **Entitlement:** app-scoped bookmarks require `com.apple.security.files.bookmarks.app-scope` (the missing key). [Source: architecture.md#KDD-D3, planning-artifacts/architecture.md#L82, #L553]

### Demo conventions this story inherits (CLAUDE.md "Demo app conventions")
- Demo target builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` → mark pure helpers `nonisolated`.
- Persist stable values (bookmark `Data` keyed by a stable `UUID` string) — never a derived/volatile payload.
- FR-44 confidence-label discipline is enforced by `make demo-lint` (`confidence-label-audit.sh`); the `Reason: bookmark-resolution-failed` string is a labeled diagnostic, compliant. No `SignalPoolDiagnosticTable(` leak concern here (FR-43 tripwire is scoped to `ContentView.swift`).

### Apple-docs verification (Xcode semantic docs MCP, 2026-07 — cross-checked at spec time)
Every API below was confirmed against Apple Developer Documentation via the `mcp__xcode__DocumentationSearch` tool; the dev agent can treat these signatures as authoritative:
- **Create:** `func bookmarkData(options: URL.BookmarkCreationOptions, includingResourceValuesForKeys: Set<URLResourceKey>?, relativeTo: URL?) throws -> Data`. `.withSecurityScope` → read/write on resolve; **combine with `.securityScopeAllowOnlyReadAccess`** for read-only (correct here — models are read-only inputs; least privilege). App-scoped bookmark = `relativeTo: nil`. `.withSecurityScope` cannot be combined with `.minimalBookmark`/`.suitableForBookmarkFile`.
- **Resolve:** `init(resolvingBookmarkData: Data, options: URL.BookmarkResolutionOptions, relativeTo: URL?, bookmarkDataIsStale: inout Bool) throws`, with `.withSecurityScope` in options. Apple's guidance: if `bookmarkDataIsStale == true`, recreate the bookmark and update the stored copy (exactly AC3).
- **Access is NOT implicit:** for an explicit security-scoped bookmark, resolving does **not** auto-start access — `withoutImplicitStartAccessing` is documented as "not applicable to security-scoped bookmarks." So AC4's explicit `startAccessingSecurityScopedResource()` bracket is mandatory, not optional. Balance every `true` return with exactly one `stop…`, or the app leaks kernel resources and eventually loses sandbox-extension ability until relaunch.
- **Entitlement:** app-scoped bookmarks require `com.apple.security.files.bookmarks.app-scope`; the sibling `…bookmarks.document-scope` is for *document*-scoped bookmarks (a different flow we are NOT using). AC1 asks for the app-scope key, matching NFR-9.
[Source: developer.apple.com — "Accessing files from the macOS App Sandbox" (Security), `URL.bookmarkData(...)`, `URL(resolvingBookmarkData:...)`, `startAccessingSecurityScopedResource()`, `BookmarkCreationOptions.securityScopeAllowOnlyReadAccess`.]

### Sandbox testability honesty (DD4)
`make demo-build` bypasses code signing (Story 5-1 DD #6), so entitlements do not attach and a non-sandboxed process's `.withSecurityScope` behavior is unreliable — which is precisely why AC5 puts the encode/decode behind an injectable seam (CI tests the map/stale/drop logic with a fake) and AC6 pushes the real entitlement-is-load-bearing proof to an operator-run `make demo-build-sandboxed` step. Do not fake a passing security-scope test in CI; test the logic you can, and mark the sandbox proof operator-run.

### Project Structure Notes
- NEW: `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BookmarkPersistence.swift` (matches architecture.md#L1101 planned path).
- UPDATE: `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BoomBoomBoomBPM.entitlements` (add one key).
- NEW: `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/BookmarkPersistenceTests.swift`.
- All under `Demo/` → **develop-only**, ships via `make demo-archive`, never to `main` (CLAUDE.md release protocol).

### References
- [Source: _bmad-output/planning-artifacts/epics.md#Story-10.1] (renumbered) — the 5 ACs + pressure-release valve.
- [Source: _bmad-output/planning-artifacts/architecture.md#KDD-D3] — UserDefaults bookmark persistence, Story 5-6 precedent, native `Data` support.
- [Source: _bmad-output/planning-artifacts/architecture.md#L82] — "Keep bookmark creation in the demo (FR-38), never in the library."
- [Source: _bmad-output/planning-artifacts/architecture.md#NFR-9] — App Store compliance via `bookmarks.app-scope`.
- [Source: Sources/BoomBoomBoomKit/ModelRegistry.swift, ModelRegistryEntry.swift] — ephemeral registry, `register(url:...)`, `identifier`-keyed, no UUID/save.
- [Source: Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift] — injected-`UserDefaults` + `object(forKey:)` self-heal precedent.
- [Source: Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/MergeStrategyPersistenceTests.swift] — suite-isolated parallel test pattern.
- [Source: CLAUDE.md#Demo-app-conventions] — MainActor default-isolation, stable-value persistence, `make demo-*` gates.

### Recorded design decisions (flag at PR, mirroring the 9.x D1 precedent)
- **DD1 — entitlement + read-only bookmark:** keep the existing app-level `user-selected.read-write` (superset of the epic AC's `read-only`; the audio-file open path uses it); ADD the missing `bookmarks.app-scope`. Do not downgrade a working entitlement. Separately, tighten the *bookmark* itself to read-only via `.securityScopeAllowOnlyReadAccess` (a model is a read-only input) — this honors the epic's read-only intent at the bookmark level without touching the app entitlement. Verified against Apple docs (see above).
- **DD2 — identity:** the persistent UUID↔bookmark map is demo-owned; `ModelRegistry` is ephemeral/re-registered each launch, so keying is a `BookmarkPersistence` concern, not a registry field.
- **DD3 — access bracket:** ship `withSecurityScopedAccess(_:perform:)` so start/stop is impossible to unbalance; `resolveAll()` returns un-started URLs.
- **DD4 — testability split:** encode/decode behind an injectable seam → CI tests the persistence logic; the entitlement-load-bearing proof (AC6) is operator-run under `demo-build-sandboxed`.
- **DD5 — storage shape:** single plist-native `[String: Data]` under one key (enumerable, atomic) over per-UUID keys + index. No JSON wrappers.

**Pressure-release valve:** If `URL.bookmarkData(options: .withSecurityScope, …)` proves unstable for `.mlmodelc` *directory* bundles specifically, fall back to storing the parent-directory bookmark and reconstructing the bundle path on resolve; do not abandon security scope. Document any deviation in `_bmad-output/implementation-artifacts/10-1-pressure-release.md`.

## Dev Agent Record

### Agent Model Used

claude-opus-4-8[1m] (Claude Code, /bmad-dev-story) — 2026-07-08.

### Debug Log References

- `make demo-build` — initial `struct` version failed the `Sendable` check on the `UserDefaults` stored property (thread-safe but not SDK-`Sendable`; a `nonisolated` type can't lean on main-actor isolation like `AnalysisViewModel.Configuration`). During code-review hardening this became a lock-guarded `final class`; a first `Mutex<UserDefaults>` attempt then hit `sending 'defaults' risks causing data races` (vending a non-`Sendable` value across the mutex region), resolved by using `Mutex(())` as a pure critical section with `defaults` staying a plain `let` touched only inside `withLock`. Final: `** BUILD SUCCEEDED **`.
- `make demo-test` — `** TEST SUCCEEDED **`; all 7 `BookmarkPersistenceTests` green (round-trip, stale-refresh, drop-on-throw, empty map, access bracket, non-UUID self-heal, 50-way concurrent-store no-lost-updates).
- `make demo-lint` — `confidence-label-audit: PASS` (the `Reason: bookmark-resolution-failed` diagnostic is a labeled string, FR-44 compliant; no `SignalPoolDiagnosticTable(` leak).
- `make demo-fmt` — clean.

### Completion Notes List

- **AC1** — added `com.apple.security.files.bookmarks.app-scope` to `BoomBoomBoomBPM.entitlements`; kept `app-sandbox` + the existing `user-selected.read-write` superset (DD1 — not downgraded).
- **AC2/AC5** — `BookmarkPersistence` is a `nonisolated final class` (`@unchecked Sendable`) over an injected `UserDefaults`, with an injectable `Codec` seam (`makeBookmark` / `resolveBookmark`, default `.live` = real `.withSecurityScope`). The create path uses `[.withSecurityScope, .securityScopeAllowOnlyReadAccess]` (least-privilege read-only, DD1) with app-scoped `relativeTo: nil`. `store(url:) throws -> UUID` mints a stable UUID and persists a single plist-native `[String: Data]` under `bookmarksKey` (`store` is `throws` because bookmark creation can fail — the spec's `-> UUID` shape plus the honest error surface). The compound map read-modify-write in `store`/`resolveAll` runs inside a **process-global `static Mutex(())`** critical section (see code-review note).
- **AC3** — `resolveAll()` refreshes stale bookmarks in place (re-encode under active scope, re-persist same UUID), drops resolve-failures with the labeled `Reason: bookmark-resolution-failed` diagnostic (no mid-launch prompt), prunes the map, and returns only resolved entries. Empty/absent map → `[]` (no precondition). A non-UUID poisoned key also self-heals. The per-entry decision is a pure `classify(key:data:) -> EntryOutcome` (`.keep`/`.refresh`/`.drop`) state machine; the loop just applies outcomes, and drop diagnostics are emitted after the lock releases (no injected-closure reentrancy deadlock).
- **AC4** — `withSecurityScopedAccess(to:perform:)` brackets `start`/`stop`, stopping iff `start` returned `true` (via `defer`). `resolveAll()` hands back URLs with the scope NOT started; the read bracket is the caller's per-use responsibility (Story 10.2 / analysis path).
- **AC6 — OPERATOR-DEFERRED (not a CI assertion, by design — DD4).** The entitlement-is-load-bearing proof cannot run in an unsigned, non-sandboxed `swift test` process. To verify manually: temporarily remove the `com.apple.security.files.bookmarks.app-scope` key from `BoomBoomBoomBPM.entitlements`, then `DEVELOPMENT_TEAM=<team-id> make demo-build-sandboxed` (NOT `make demo-build`, which bypasses signing so entitlements never attach — Story 5-1 DD #6), launch, add a model, relaunch → bookmark resolution should FAIL on the second launch. Restore the key afterward.
- **Code review (Codex diff-review, 2026-07-08 — pre-review hardening).** Round 1 flagged one merge-blocker: the original `struct` + `@unchecked Sendable` design did an unsynchronized compound read-modify-write of the map, so concurrent `store`/`resolveAll` could silently drop a good bookmark — the `Sendable` contract lied. Resolution (matches the library's `Mutex`-guarded `ModelRegistry` precedent): converted to a `final class` and guarded the map mutation with a `Mutex`; `@unchecked Sendable` is now justified by the lock rather than hand-waved. Round 2/3 tightened it: the lock is **`static`** (the shared resource is the process-global `bookmarksKey`, not the instance, closing a cross-instance race), diagnostics moved outside the lock, and the nested per-entry conditional was refactored into the `classify` FSM. Added a `concurrentStoresDoNotLoseEntries` regression test (50-way `DispatchQueue.concurrentPerform`, asserts zero lost updates). Codex round 3: both findings closed, "ready for review." The remaining nit (a deliberately reentrant fake codec could deadlock under the lock) is documented, not blocking — the live codec is pure.
- **`@unchecked Sendable` (recorded for the reviewer):** the one deviation from the spec's literal "`Sendable`-clean" wording. It is now the correct, precedented form (`UserDefaults` is thread-safe but not SDK-`Sendable`; a `nonisolated` type can't lean on main-actor isolation like `AnalysisViewModel.Configuration` does), justified by the `Mutex` — same as `ModelRegistry` / `BNNSTechnique`.
- Library byte-identity: `git diff --stat Sources/ Tests/` empty — zero library change by construction (demo-only, ships via `make demo-archive`, never `main`).

### File List

- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BookmarkPersistence.swift` (NEW)
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BoomBoomBoomBPM.entitlements` (UPDATE — added `bookmarks.app-scope`)
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/BookmarkPersistenceTests.swift` (NEW)

### Change Log

- 2026-07-08 — Story 10.1 implemented: security-scoped bookmark persistence for user-added model files (demo-only). New `BookmarkPersistence` helper (injected UserDefaults + bookmark Codec seam; store/resolveAll/stale-refresh/drop; access bracket), the `bookmarks.app-scope` entitlement, and CI-testable unit tests. AC6 operator-deferred. Demo gauntlet green; `Sources/`/`Tests/` byte-identical.
- 2026-07-08 — Code-review hardening (Codex diff-review): converted `BookmarkPersistence` struct → `final class` guarded by a process-global `static Mutex` (fixes an unsynchronized-map-mutation lost-update race that the `@unchecked Sendable` contract had masked); refactored the per-entry resolve logic into a `classify` outcome FSM; moved drop diagnostics outside the lock; added a 50-way concurrent-store regression test. 7 tests green.
- 2026-07-08 — `/bmad-code-review` (3-layer: Codex Blind Hunter, Edge Case Hunter, Acceptance Auditor; all six ACs SATISFIED). Two patches applied, one defer: (1) `resolveAll()` no longer holds the static `Mutex` across the injectable codec's file I/O — refactored to snapshot-classify-merge with a compare-and-swap merge (`map[key] == snapshot[key]`), closing the re-entrancy-deadlock trap while preserving concurrent-`store` UUIDs and concurrent-refresh writes; validated by `axiom:concurrency` + Codex (Codex caught a stale-drop hole in the first presence-only guard → CAS). (2) Poison-husk prune folded into the merge write-back. Duplicate-URL dedup deferred to Story 10.2 (W79). New regression test `concurrentResolveDuringStoresLosesNothing`; 8 tests green. Demo gauntlet re-run green (demo-fmt/build/test/lint); `git diff Sources/ Tests/` still empty.

### Review Findings

Code review 2026-07-08 (`/bmad-code-review`, baseline b4d7211) — 3 parallel layers: Blind Hunter (Codex adversarial), Edge Case Hunter, Acceptance Auditor. Acceptance Auditor: all six ACs SATISFIED, DD1–DD5 met, zero library change confirmed. Triage: 2 decision-needed, 1 patch, 0 defer, 8 dismissed as noise/by-design.

- [x] [Review][Patch] Narrow the static lock so codec I/O runs outside it — APPLIED. `resolveAll()` refactored to snapshot-classify-merge: snapshot the map under the lock, run all `classify()` codec resolve/refresh I/O OUTSIDE the lock, then re-acquire and merge each outcome via **compare-and-swap** (`map[key] == snapshot[key]`) on both the refresh and drop branches, writing back only on change. Closes the re-entrancy-deadlock trap; a concurrent `store()`'s new UUID and a concurrent resolver's fresh refresh are both preserved. Validated by `axiom:concurrency` (canonical "refactor to avoid nested locking" pattern) and Codex (which caught the original presence-only guard's stale-drop hole → CAS fix). Added regression test `concurrentResolveDuringStoresLosesNothing`. [Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BookmarkPersistence.swift:175]
- [x] [Review][Patch] `resolveAll()` poisoned-husk self-heal — APPLIED (folded into the merge). The merge write-back writes the re-read filtered `bookmarkMap()`, so non-`Data` junk is pruned on any refresh/drop write. Residual: a value that is not a dictionary at all (zero valid entries) is still healed by the next `store()`, not by `resolveAll` alone — accepted as low (store() self-heals; no per-launch write churn). [Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BookmarkPersistence.swift:271]
- [x] [Review][Defer] Duplicate-URL stores create duplicate entries [Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BookmarkPersistence.swift:141] — deferred to Story 10.2. `store(url:)` mints a fresh `UUID()` unconditionally, so the same file added twice yields two entries / two registrations. AC2 requires only "mint a UUID" — dedup is the picker's add-model UX concern; the persistence layer stays intentionally URL-agnostic.
