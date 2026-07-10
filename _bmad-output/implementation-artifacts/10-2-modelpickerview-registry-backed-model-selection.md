---
title: 'Story 10.2: ModelPickerView — registry-backed model selection'
type: 'feature'
created: '2026-07-09'
status: 'done'
review_loop_iteration: 0
followup_review_recommended: false
final_revision: 'pending-operator-signed-commit'
epic: 10
story: 10.2
baseline: '6bf83f4'
baseline_revision: '6bf83f4'
warnings: []
---

# Story 10.2: ModelPickerView — registry-backed model selection

## Story

**As a** demo user evaluating BoomBoomBoomKit's ML augmentation,
**I want** to pick an ML model from a list (previously-added, restored across launches) or add a new one via file picker,
**So that** I can compare model behavior across runs without rebuilding the app.

This is a **demo-only** story (`Demo/BoomBoomBoomBPM/`, develop-only). `Sources/` and `Tests/` MUST stay byte-identical. It consumes Story 10.1 (`BookmarkPersistence`, done) and the library `ModelRegistry` (Epic 8). It folds Epic 9 retrospective action AI-3 (relocate the grandfathered "Load Model…" button) restoring FR-43.

## Acceptance Criteria

**AC1 — populated list.**
**Given** the catalog holds ≥1 registry entry (a user-added model restored via `BookmarkPersistence.resolveAll()` and/or added this session),
**When** the picker sheet opens,
**Then** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ModelPickerView.swift` renders a SwiftUI `List` over the demo catalog (backed by the library `ModelRegistry.entries` — the real API; **not** `allEntries()`, DD1). Rows are identified by `entry.url.standardizedFileURL` (**not** by the filename-derived identifier, which is not unique — DD7), each showing the display name, a labeled source string (`Source: User-added`, DD2), and a labeled integrity string (`Integrity: recorded` + short sha256 prefix — trust-on-first-use, honest, DD4). Bare booleans/numerics are FR-44 violations.

**AC2 — empty state (fresh install).**
**Given** a fresh launch with no persisted user-added models and no bundled/known-public catalog (none ships today, DD3),
**When** the picker sheet opens,
**Then** the view renders the explanatory panel "No models available — add one to begin", and the "Use this model" button is disabled with a labeled rationale (`Reason: no-models-available`).

**AC3 — add from disk (transactional, deduped).**
**Given** the picker sheet is open,
**When** the user taps "Add model from disk…",
**Then** an `NSOpenPanel` constrained toward **`.mlmodelc` bundles** (`.mlmodel` is NOT the target — the library `register()` hashes only directory bundles and `BNNSTechnique` requires `.mlmodelc`; DD6) presents; a wrong selection is caught by the register-first validation (DD8), not silently accepted. On selection the catalog dedups by `url.standardizedFileURL` (W79) — a URL already in the catalog is rejected with a labeled `Reason: model-already-added`, no duplicate row. Otherwise, **inside one `withSecurityScopedAccess` bracket**, the catalog calls `ModelRegistry.register(url:metadata:)` **first** (validate — the digest read must succeed) and only on success calls `BookmarkPersistence.store(url:)` and appends the `.userAdded` row (DD8 transactional order — a `register` throw leaves NO orphaned bookmark; surfaces `Reason: model-register-failed`).

**AC4 — use this model.**
**Given** a registry entry is highlighted,
**When** the user taps "Use this model",
**Then** the demo calls `AnalysisViewModel.loadModel(at: entry.url)` (which constructs `BNNSTechnique(modelURL:)` **inside a `withSecurityScopedAccess` bracket** — DD9 — and sets the existing `mlTechnique`/`mlModelName`/`mlEnabled`/`mlModelError` quartet). On success the sheet dismisses, the chosen entry is marked with a labeled `Selected: yes` indicator (keyed by URL, DD7), and the demo re-analyzes the current file **if one is loaded**; on failure `mlModelError` stays visible and the sheet does not dismiss.

**AC5 — persistence across launches (10.1 ↔ 10.2 integration, resilient restore).**
**Given** a model was added via the picker in a prior session,
**When** the app relaunches,
**Then** the catalog `restore()`s through `BookmarkPersistence.resolveAll()`: it dedups the resolved tuples by `standardizedFileURL` (W79 — `resolveAll()` can return duplicate URLs) and registers each **under security scope, catching per-entry `register` throws** so one moved/unhashable file cannot abort restore or the launch — a failed entry is skipped with a labeled `Reason: restored-model-unavailable` diagnostic (DD8). Every still-valid model appears in the picker as `.userAdded` **without** re-picking the file.

**AC6 — relocate "Load Model…" (AI-3 / FR-43).**
**Given** the demo grandfathers a "Load Model…" button into the primary view (`ContentView.swift:381`, Story 9.3 decision D1),
**When** Story 10.2 lands,
**Then** that action-row button is removed and the add-model affordance lives **only** inside the picker sheet; the primary view exposes a single "Models…" entry point that opens the sheet — restoring the FR-43 "primary stays primary" surface.

**AC7 — library byte-identity.** `git diff Sources/ Tests/` is empty.

## Tasks / Subtasks

- [x] `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ModelCatalog.swift` (NEW) — `@MainActor @Observable` demo catalog. Owns one library `ModelRegistry`, an **injectable** `BookmarkPersistence` (default `BookmarkPersistence(defaults: .standard)`; injected fake-seam catalog for tests, mirroring 10.1's `Codec` seam), a `[URL: ModelSource]` provenance map **keyed by `standardizedFileURL`** (DD7 — identifiers are not unique), and `selectedURL: URL?`. Add nested `enum ModelSource { case bundled, knownPublic, userAdded }` with a labeled `display` (`"User-added"` etc.) — `.bundled`/`.knownPublic` are documented seams for a future bundled model (DD2), not dead code. `restore()` (called from `init`): `resolveAll()` → **dedup tuples by `standardizedFileURL`** → for each unique URL, `withSecurityScopedAccess { register(...) }` inside a **per-entry `do/catch`** that skips + emits `Reason: restored-model-unavailable` on throw (DD8). `addFromDisk(url:) -> Result<Void, AddError>`: dedup by `standardizedFileURL` (labeled `model-already-added`) → `withSecurityScopedAccess { register(...) first; on success store(url:) }` (transactional; `register` throw → `model-register-failed`, NO stored bookmark — DD8). Register identity: `ModelMetadata(identifier: url.deletingPathExtension().lastPathComponent, capabilities: [.tempoEstimation])`. Expose `entries`, `isEmpty`, `source(for url:)`, `integrityLabel(for entry:)`, `select(url:) -> URL?`, `isSelected(_ entry:)`.
- [x] `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ModelPickerView.swift` (NEW) — SwiftUI sheet: `List` over `catalog.entries` (row: name / `Source:` / `Integrity:` / `Selected:`), an "Add model from disk…" button presenting the `NSOpenPanel` (restrict to `.mlmodelc` via `UTType(filenameExtension: "mlmodelc")` if non-nil else fall back to the existing message-only panel; `canChooseFiles = true`, `canChooseDirectories = true` since `.mlmodelc` is a bundle — DD6; the register-first validation in DD8 is the real guard against a wrong selection), a "Use this model" button (disabled + `Reason: no-models-available` when empty), and the empty-state panel. FR-44 labeled strings throughout; surface `AddError`/restore diagnostics as labeled `Reason:` text.
- [x] `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift` — remove `Button("Load Model…")` from the bottom action row (:381) **and its BYOW action-row comments**; add a "Models…" button that opens the picker via `.sheet(isPresented:)`; on "Use this model" success, `triggerReanalyze()`. Confirm `pickAndLoadMLModel()` has **no remaining primary-view caller** afterward (FR-43 restored — DD10).
- [x] `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift` — add `loadModel(at url: URL) -> Bool` extracting the `BNNSTechnique(modelURL:)` construct + `attachMLTechnique` + macOS-15 gate from `pickAndLoadMLModel()`, **wrapping the construct in the caller-supplied URL's `withSecurityScopedAccess` bracket** (restored bookmark URLs arrive scope-unstarted — DD9). `pickAndLoadMLModel()` (its NSOpenPanel path) delegates to `loadModel(at:)`; keep it only if still reachable, else it becomes internal. No behavior change to the success quartet (`mlTechnique`/`mlModelName`/`mlEnabled`/`mlModelError`).
- [x] `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/ModelCatalogTests.swift` (NEW) — CI tests over the fake `BookmarkPersistence` seam + suite-isolated `UserDefaults` (`removePersistentDomain`, per 10.1), `@MainActor`-annotated: restore-on-init populates entries; `restore()` dedups duplicate resolved URLs to one row (W79); `restore()` skips an entry whose `register` throws and keeps the others + a labeled diagnostic; `addFromDisk` dedups a re-added URL (one entry, labeled reject); `addFromDisk` register-failure leaves NO persisted bookmark (transactional rollback, DD8); **two same-named `.mlmodelc` in different directories yield two distinct URL-keyed rows and `select` resolves the correct URL** (DD7 collision guard); empty catalog reports `isEmpty`; `select(url:)` returns the resolved URL and sets `selectedURL`; source tag is `.userAdded`. (The `register`/`store` failure injection rides the fake `BookmarkPersistence.Codec` seam + a temp-dir fixture bundle.)

## Dev Notes

### What this story is (and is NOT)
It is the demo model-picker sheet + a demo-side catalog wrapping the library `ModelRegistry` and the 10.1 `BookmarkPersistence`. It is NOT a change to the library registry, NOT a bundled-model addition, and NOT ML BYOW infrastructure (that already ships — `pickAndLoadMLModel`/`attachMLTechnique`/`BNNSTechnique`). It reorganizes the existing single-model BYOW load into a persistent, multi-entry picker.

### Recorded design decisions (flag at PR, mirroring the 9.x / 10.1 D1 precedent)
- **DD1 — real API is `ModelRegistry.entries`, not `allEntries()`.** The epic AC cites `allEntries()`; the library exposes `public var entries: [ModelRegistryEntry]`, `lookup(identifier:)`, and `register(url:expectedDigest:metadata:) throws`. Cite the real surface.
- **DD2 — no library source-category; the demo owns provenance.** `ModelRegistryEntry` has no Bundled/Known-public/User-added field, and no bundled model ships (CLAUDE.md: Story 4-6 Branch C removed it; consumers BYOW) nor a known-public catalog exists. The demo introduces `ModelSource`; today every entry is `.userAdded`; the other two cases are seams for a future bundled model, not dead code.
- **DD3 — fresh-launch reconciliation.** Epic AC1 ("launches with no user-added models" → populated List) contradicts "no bundled models ship". Reconciled: a truly fresh install → the AC2 empty state; AC1's row-rendering applies once ≥1 entry exists (restored user-added or added this session).
- **DD4 — integrity label reflects trust-on-first-use.** `register(expectedDigest: nil)` records current bytes (TOFU); it does not verify against a pin. "Integrity: verified" would overclaim, so the label is `Integrity: recorded` + short `digestHexString` prefix — labeled (FR-44) and honest.
- **DD5 — MainActor + `Sendable` composition (type-safe, but registration is synchronous disk I/O).** The catalog is `@MainActor @Observable` (demo default isolation, CLAUDE.md). `ModelRegistry` is a `Sendable final class`; `BookmarkPersistence` is `nonisolated @unchecked Sendable`. No cross-actor data-race hazard — the catalog calls both from the main actor. **Caveat:** `ModelRegistry.register` recomputes SHA-256 from disk under its own mutex; calling it on the main actor during `restore()`/`addFromDisk` briefly blocks the UI on the bundle size. Accepted for the demo (models are small, MB-scale); keep `withSecurityScopedAccess` bodies **synchronous** (no `await` inside the bracket — scope is process-wide but the bracket must not span suspension). If a large-bundle stall appears, offload the digest to a background task and hop back to `@MainActor` to mutate observable state (documented option, not required now).
- **DD6 — `.mlmodelc` bundles only.** The library `register()`/`computeDigest` throws `unsupportedFormat` for a non-directory input (`ModelRegistry.swift` `guard isDirectory`), and `BNNSTechnique` requires a compiled `.mlmodelc`. The epic AC's "`.mlmodel` files" allowance is wrong — constrain the panel to `.mlmodelc` (`UTType.mlmodelc`).
- **DD7 — URL-keyed identity, not filename identifier.** `ModelMetadata.identifier` is derived from the filename and is **not unique** (two `model.mlmodelc` in different folders collide); the library `register` appends without identifier dedup and `lookup(identifier:)` returns the first match. So the catalog keys provenance, selection, and the `Selected: yes` mark on `entry.url.standardizedFileURL`, never on the identifier. Test-locked by the same-name/different-dir case.
- **DD8 — transactional add + resilient restore.** `resolveAll()`/`register`/`store` all do I/O that can fail. `addFromDisk` registers **first** (validate), persists the bookmark second, and appends the observable row **only after BOTH commit** — so a `register` throw orphans no bookmark and adds no row (`registerFailed`), and a `store` throw (rarer — bookmark creation after a successful hash) adds no row and no bookmark and is cleanly retryable (`persistFailed`). The mirror appends the single registered entry (not a wholesale `registry.entries` copy) so an unshown entry left in the ephemeral registry by a store-failure can't resurface as a duplicate on retry. `restore()` catches per-entry `register` throws, skips the bad entry with a labeled diagnostic, and never aborts launch. No persistence removal API is needed. *(The store-failure handling + `persistFailed` case were added in the 2026-07-09 code-review pass — see Change Log.)*
- **DD9 — restored-URL load needs the security-scope bracket.** `resolveAll()` returns URLs with scope **not** started; `BNNSTechnique.init` reads/compiles from disk. `loadModel(at:)` (and each `register`) must run inside `BookmarkPersistence.withSecurityScopedAccess(to:perform:)`. Freshly-picked URLs keep their transient `NSOpenPanel` scope.
- **DD10 — relocation completeness (FR-43 / AI-3).** Removing the button is not enough — remove its action-row comments too and confirm `pickAndLoadMLModel()` has no remaining primary-view caller, so the add-model affordance truly lives only in the sheet.

### Security-scope discipline (inherited from 10.1)
`resolveAll()` returns resolved URLs but security-scope access is **not** implicit. Wrap each `register` (which does file I/O to compute the digest) and each analysis run in `BookmarkPersistence.withSecurityScopedAccess(to:perform:)`. The existing `pickAndLoadMLModel` already brackets `start/stopAccessingSecurityScopedResource`; the restored-URL path must too.

### Testability honesty
The picker **view** and the terminal `BNNSTechnique(modelURL:)` load (macOS 15 + a real compiled model) are operator/GUI-tested, as in 10.1 AC6. `ModelCatalog`'s logic — restore, dedup, empty-state, select-returns-URL, source/identity derivation — IS CI-testable via the injected fake `BookmarkPersistence` seam. Keep the BNNS construction in the view/VM layer so the catalog stays decode-free and CI-green.

### Boundaries (autonomous-run guardrails — HALT if any trigger)
- **Block if** the `ModelRegistry` / `ModelRegistryEntry` / `BNNSTechnique` API differs from what DD1/DD5 cite when the code is opened.
- **Block if** `.mlmodel`/`.mlmodelc` selection needs an entitlement or `UTType` the demo lacks and that can't be added demo-locally.
- **Block if** relocating "Load Model…" breaks an existing demo smoke-test contract that can't be updated within `Demo/`.

### Project Structure Notes
New files land beside the existing demo sources under `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/`; the test under `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/`. Both must be added to the Xcode project's `BoomBoomBoomBPM` target / `BoomBoomBoomBPM.xctestplan` (they are auto-membership only if the folder is a synchronized group — verify in the pbxproj).

### References
- Library: `Sources/BoomBoomBoomKit/ModelRegistry.swift` (`entries`, `register`, `lookup`), `ModelRegistryEntry.swift` (`ModelRegistryEntry`, `ModelDigest.hexString`, `ModelMetadata`, `ModelCapability.tempoEstimation`).
- 10.1: `Demo/.../BookmarkPersistence.swift` (`store(url:) throws -> UUID`, `resolveAll() -> [(id,url)]`, `withSecurityScopedAccess`, `init(defaults:codec:onDiagnostic:)`, `Codec` seam).
- Demo BYOW: `AnalysisViewModel.swift` (`pickAndLoadMLModel`, `attachMLTechnique(_:named:)`, `mlModelName`/`mlEnabled`), `ContentView.swift:381` (Load Model… button).
- Deferred: `deferred-work.md` W79 (dedup is the picker's job).
- Conventions: CLAUDE.md "Demo app conventions" (MainActor default isolation; UserDefaults hydrate via `object(forKey:)`), FR-43 (primary stays primary), FR-44 (labeled confidence-like strings; `confidence-label-audit.sh` in `make demo-lint`).

## Dev Agent Record

### Completion Notes List
- All 7 ACs satisfied; demo gauntlet green (`demo-fmt` clean, `demo-build` BUILD SUCCEEDED, `demo-test` TEST SUCCEEDED incl. 9 new `ModelCatalogTests`, `demo-lint` confidence-label PASS + no team leak). `git diff Sources/ Tests/` empty (AC7 — library byte-identical).
- All party-mode/Codex findings landed in code: register-first transactional add (DD8, `ModelCatalog.swift` register at store−1), URL-keyed identity + selection (DD7), `withSecurityScopedAccess` around every register and the `loadModel(at:)` BNNS construct (DD9), resilient `restore()` with per-entry catch + `standardizedFileURL` dedup (DD8), `.mlmodelc`-targeted panel with register-first as the real guard (DD6), `Load Model…` relocated to the `Models…` sheet (DD10/AC6).
- Deviations (all sanctioned by the spec): `pickAndLoadMLModel()` retained but now delegates to `loadModel(at:)` and has no remaining primary-view caller (Task 4 "keep only if reachable"); `AddError` is `Equatable` but `Result<Void, AddError>` isn't (Void), so tests use `isSuccess`/`failure` helpers; `AnalysisViewModel` holds its own `BookmarkPersistence(defaults: .standard)` for the load bracket (Task 4 "give it its own").

### File List
- NEW `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ModelCatalog.swift`
- NEW `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ModelPickerView.swift`
- NEW `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/ModelCatalogTests.swift`
- MOD `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift` (added `loadModel(at:)` + injectable `bookmarkPersistence`; `pickAndLoadMLModel()` delegates)
- MOD `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift` (relocated Load Model → `Models…` sheet)

### Change Log
- 2026-07-09 — Story 10.2 dev complete on `rterhaar/epic-10` (baseline `6bf83f4`). Demo-only; library byte-identical.
- 2026-07-09 — Code-review pass (Codex Blind Hunter + Edge Case Hunter + Acceptance Auditor). 6 patches applied (2 medium, 4 low): transactional store-failure handling (split register/mirror + `AddError.persistFailed`, DD8 refined), `clearSelection()` on failed load (FR-44 honesty), indexed restore-diagnostic id, stale-error/diagnostic clears, labeled `mlModelError`. 2 new regression tests (11 ModelCatalog tests total). 1 defer (W80 symlink dedup), 2 reject (macOS-14 moot on 15.6 floor; DD5-accepted sync hash). Gauntlet re-run green; `git diff Sources/ Tests/` empty.
- 2026-07-09 — Codex diff-review (thread `019f49dd`, 2 rounds) confirmed all core invariants hold. P7 applied: `ContentView.swift` `mlModelError` render labeled `Reason: \(mlError)` to match the picker's already-labeled version (the primary-view render was pre-existing but my picker patch had left the two surfaces inconsistent). Declined (Codex agreed): the empty-state headline is explanatory prose, not an FR-44 confidence-like value, and the labeled `Reason: no-models-available` already sits beneath it. `demo-fmt` clean, `demo-lint` confidence-label PASS; library still byte-identical.

### Review Findings

### Code Review (3-layer, 2026-07-09)
Baseline `6bf83f4`. Three parallel layers: **Blind Hunter (Codex, thread `019f49c8`)** + **Edge Case Hunter** + **Acceptance Auditor**. The Auditor verified all AC1–AC7 and DD1–DD10 SATISFIED against the code with no vacuous tests. Triage: **6 patch (medium 2, low 4) + 1 defer + 2 reject**; no intent_gap, no bad_spec, no high-severity production bug.

Patches applied (all demo-only, `Sources/`/`Tests/` byte-identical):
- **[medium] P1 — transactional store-failure.** `addFromDisk` mirrored the observable row before `store` ran, so a `store` throw after a successful `register` left a ghost row + blocked retry + no persisted bookmark. Fix: split `registerAndMirror` into `registerEntry` (validate) + `mirror` (append single entry), mirror only after BOTH register and store commit; added an honest `AddError.persistFailed` (`Reason: model-persist-failed`) distinct from `registerFailed`. Locked by new test `addFromDiskStoreFailureNoGhostRow`. Refines DD8 (see Spec Change Log).
- **[medium] P2 — stale `Selected: yes` after a failed load.** A failed `loadModel` clears the prior technique but left `selectedURL` pointing at the old model, so a row lied `Selected: yes` while nothing was attached (FR-44). Fix: `ModelCatalog.clearSelection()` called on the load-failure branch. Locked by new test `clearSelectionClearsMark`.
- **[low] P3 — `ForEach(restoreDiagnostics, id: \.self)`** collided on duplicate reason strings (2 skipped models → duplicate SwiftUI IDs). Fix: indexed id.
- **[low] P4 — stale `mlModelError`** greeted a fresh picker reopen. Fix: clear on `onAppear`.
- **[low] P5 — stale `addDiagnostic`** survived an `NSOpenPanel` cancel. Fix: clear before `runModal`.
- **[low] P6 — `mlModelError`** rendered as a bare interpolation off the FR-44 pattern. Fix: `Reason:`-labeled.

Deferred: **W80** — lexical (`standardizedFileURL`) dedup misses a symlink/target duplicate (low, uncommon flow). Also marked **W79 RESOLVED** (this story delivered the dedup W79 deferred here).

Rejected: (1) "macOS-14 user builds an unusable catalog" — the demo's deployment floor is macOS 15.6, so the `#available(macOS 15)` guards are defensive-only and the case can't occur; (2) "restore() hashes synchronously on the main actor at launch" — already an accepted, documented tradeoff (DD5).

### Review Triage Log

#### 2026-07-09 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 6 (high 0, medium 2, low 4)
- defer: 1
- reject: 2
- addressed_findings:
  - `[medium]` `[patch]` P1 transactional store-failure — split register/mirror, mirror-after-commit, added `AddError.persistFailed`; regression test added.
  - `[medium]` `[patch]` P2 stale `Selected: yes` on failed load — `clearSelection()` on the failure branch; regression test added.
  - `[low]` `[patch]` P3 `restoreDiagnostics` `ForEach` id collision — indexed id.
  - `[low]` `[patch]` P4 stale `mlModelError` on picker reopen — cleared in `onAppear`.
  - `[low]` `[patch]` P5 stale `addDiagnostic` on panel cancel — cleared before `runModal`.
  - `[low]` `[patch]` P6 `mlModelError` bare interpolation — `Reason:`-labeled.

### Spec Review (party-mode, pre-dev, 2026-07-09)
Two independent adversarial lenses ran against the draft — a code-grounded spec auditor and a Codex plan-review (thread `019f49b8`). Both confirmed the API citations and DD1/DD4 are correct, and converged on the same substantive defects, all folded into the ACs/Tasks/DDs above:
- `.mlmodel` allowance contradicted `register()`/`BNNSTechnique` (both require `.mlmodelc`) → DD6.
- Filename-derived identifiers are not unique; `register` doesn't dedup them and `lookup` returns first-match → URL-keyed identity, DD7.
- `store`-then-`register` orphaned a bookmark on `register` failure → register-first transactional order, DD8.
- `restore()` didn't dedup `resolveAll()` duplicates (W79) nor catch per-entry `register` throws → resilient restore, DD8.
- The `loadModel(at:)` extraction dropped the security-scope bracket restored URLs need → DD9.
- MainActor `register` runs synchronous SHA-256 → DD5 caveat (accepted for demo, no `await` in the bracket).
- Relocation must remove comments + leave no primary caller of `pickAndLoadMLModel()` → DD10.
Confirmed: the demo pbxproj uses `PBXFileSystemSynchronizedRootGroup`, so new files auto-join the app/test targets; `make demo-test` runs the test target in CI.

## Auto Run Result

Status: **done** (demo-only; library byte-identical). Baseline `6bf83f4`.

**Implemented change.** The demo gains a registry-backed model picker: a new `@MainActor @Observable ModelCatalog` wraps the library `ModelRegistry` + the Story-10.1 `BookmarkPersistence` into one observable source of truth (URL-keyed identity, transactional add, resilient security-scoped restore), a new `ModelPickerView` sheet lists models with FR-44-labeled Source/Integrity/Selected/Reason strings + an "Add model from disk…" affordance, and the grandfathered primary-view "Load Model…" button is relocated into the sheet (AI-3 / FR-43), reached via a new "Models…" button. Persisted user-added models restore across launches (10.1 ↔ 10.2 integration).

**Files changed.**
- NEW `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ModelCatalog.swift` — demo catalog (restore/add/select, transactional, URL-keyed).
- NEW `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ModelPickerView.swift` — the picker sheet.
- NEW `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/ModelCatalogTests.swift` — 11 CI tests.
- MOD `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift` — `loadModel(at:)` (scope-bracketed BNNS load) + injectable `bookmarkPersistence`; `pickAndLoadMLModel()` delegates.
- MOD `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift` — "Load Model…" → "Models…" sheet.
- Docs: `deferred-work.md` (W79 resolved, W80 added).

**Review findings breakdown.** Party-mode spec review (code-grounded auditor + Codex) hardened the spec pre-dev (7 findings → DDs). Code review (Codex Blind Hunter + Edge Case Hunter + Acceptance Auditor): all AC1–AC7 + DD1–DD10 SATISFIED, no vacuous tests; **6 patches applied** (2 medium: transactional store-failure, stale `Selected:` label; 4 low: id collision, stale error/diagnostic clears, labeled error), **1 deferred** (W80 symlink dedup), **2 rejected** (macOS-14 moot on the 15.6 floor; DD5-accepted sync hash). No intent_gap, no bad_spec, no high-severity bug.

**Verification.** `make demo-fmt` clean; `make demo-build` BUILD SUCCEEDED; `make demo-test` TEST SUCCEEDED (11 ModelCatalog tests + existing demo tests green); `make demo-lint` confidence-label PASS + no team leak; `git diff Sources/ Tests/` empty (library byte-identical, AC7).

**Residual risks.** (1) W80 symlink-vs-target duplicate (low, deferred). (2) The BNNS-load terminal path + the picker view are operator/GUI-tested (macOS 15 + a real `.mlmodelc`), as in 10.1 AC6 — CI covers `ModelCatalog` logic only. (3) `followup_review_recommended: false` — the P1 patch reworked the transactional add/restore core (new `persistFailed` case), but it is test-locked (`addFromDiskStoreFailureNoGhostRow`) and Acceptance-Auditor-confirmed; the patch delta is the only thing an extra pass would re-scan.

**Pending (operator).** 1Password-signed commit + PR onto `rterhaar/epic-10` (dev-auto did not auto-commit — this repo's commits are operator-owned and 1Password-signed per CLAUDE.md discipline). Suggested subject: `Story 10-2: ModelPickerView — registry-backed model selection`. Also run the demo GUI smoke (open picker, add a model, use it, relaunch to confirm restore) — the operator-owned surface 10.1 AC6 established.
