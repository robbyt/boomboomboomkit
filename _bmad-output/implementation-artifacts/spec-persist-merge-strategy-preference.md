---
title: 'Persist merge-strategy preference (quorum default)'
type: 'feature'
created: '2026-05-25'
status: 'done'
context: ['{project-root}/CLAUDE.md']
baseline_commit: '840dd60'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Every BoomBoomBoom launch resets the merge-strategy dropdown to the library's `.maxConfidence` default. Users who prefer a different strategy (e.g., `.quorum`) have to re-pick it after every app start. There is no persistence of the user's choice; `AnalysisViewModel.swift:122` initializes `options` with the library default and the Picker just edits that runtime value.

**Approach:** Persist the user's merge-strategy selection in `UserDefaults` (the canonical macOS "basic prefs file" — a plist at `~/Library/Containers/com.robbyt.BoomBoomBoomBPM/Data/Library/Preferences/com.robbyt.BoomBoomBoomBPM.plist`). On launch, `AnalysisViewModel.init(configuration:)` reads the saved `rawValue` through an injectable `Configuration` dependency, parses to `CandidateMergeStrategy`, and seeds `options.mergeStrategy` before `ContentView.body` first renders — so the Picker shows the persisted value without a transient flash. When no saved value exists (first launch, missing key) the fallback is `.quorum`. When the stored rawValue is unrecognized (e.g., a library case was removed), self-heal: delete the bad key and hydrate `.quorum`. Every Picker change writes the new selection through a small `persistPreferredMergeStrategy()` helper invoked from `ContentView`'s existing `.onChange(of: viewModel.options.mergeStrategy)`. Production uses `UserDefaults.standard`; tests inject an isolated `UserDefaults(suiteName:)` to avoid contaminating each other or the operator's app prefs.

## Boundaries & Constraints

**Always:**
- Demo-side change only. The library default `.maxConfidence` in `Sources/BoomBoomBoomKit/AudioAnalysisService.Options` stays untouched — this affects only how `AnalysisViewModel` *seeds* its `options.mergeStrategy`. Library consumers integrating via SPM continue to receive `.maxConfidence` unless they opt in. Document the divergence in a comment inside `AnalysisViewModel`, NOT in the library — the library must not know about demo policy.
- Storage layer is `UserDefaults`, accessed through an injectable `AnalysisViewModel.Configuration` value type whose `.live` static carries `UserDefaults.standard` + fallback `.quorum`. The init signature is `init(configuration: Configuration = .live)` — production callers pass nothing; tests pass an isolated `UserDefaults(suiteName:)`-backed Configuration. Stored via `@ObservationIgnored private let configuration: Configuration`.
- UserDefaults key: `"preferredMergeStrategy"` (single shared constant `AnalysisViewModel.preferredMergeStrategyKey`). Match the privacy-manifest declaration already present at `PrivacyInfo.xcprivacy:18` (`NSPrivacyAccessedAPICategoryUserDefaults` reason `CA92.1`).
- Store the strategy as its `String` rawValue (`CandidateMergeStrategy` is `String, CaseIterable, Sendable, Hashable` at `Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift:19`). Never store the case index — rawValue is the rename-stable identity.
- Unrecognized stored rawValue (case removed in a future library version, or user manually edited the plist): **self-heal** — delete the bad key from UserDefaults and hydrate `.quorum`. Pre-1.0 framing per `CLAUDE.md`: no need to preserve invalid local state on the chance a case is re-added.
- Picker binding (`$viewModel.options.mergeStrategy`) stays unchanged. The persistence layer is invisible to the Picker; hydration happens in VM `init()` before SwiftUI calls `body` for the first time.

**Ask First:**
- If `CandidateMergeStrategy`'s case set changes in the library (e.g., a case is renamed or removed), the rawValue stored on disk for the removed case becomes a "ghost" — the spec's fallback to `.quorum` handles it silently, but the user's preference is lost. If preference-loss-on-library-rename is a concern, add a one-time migration. Not in scope for this spec.

**Never:**
- Do NOT introduce `@AppStorage` for this preference. The Picker is bound to `$viewModel.options.mergeStrategy` (an `@Observable` property), not to `@AppStorage`. Adding `@AppStorage` in `ContentView` would create a second source of truth and require `.task`-based hydration that races with `@Observable` initialization. Hydrating in `AnalysisViewModel.init()` is race-free.
- Do NOT change the library default `.maxConfidence` in `Sources/BoomBoomBoomKit/`. This is a demo-side seeding change; library consumers are unaffected.
- Do NOT update `PrivacyInfo.xcprivacy` — the existing `CA92.1` UserDefaults declaration already covers this use.
- Do NOT add CloudKit / NSUbiquitousKeyValueStore sync. Local-device persistence only — out of scope.
- Do NOT persist any other `options` field (intensity, ML technique, ensemble policy, etc.). Single-field scope; other prefs are a separate fix if requested.
- Do NOT block the `init()` on any I/O beyond the synchronous UserDefaults read.
- Do NOT introduce a settings/preferences pane. The Picker IS the user-facing surface; persistence is invisible from the UI.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| First launch (no saved pref) | UserDefaults key absent | Picker shows `quorum`; `viewModel.options.mergeStrategy == .quorum` | N/A — `quorum` is the fallback default |
| Returning launch with saved pref | UserDefaults key = `"weightedAverage"` | Picker shows `weighted average`; `viewModel.options.mergeStrategy == .weightedAverage` | N/A |
| User changes Picker | Picker selection: `.median` | `options.mergeStrategy` mutates → existing `.onChange` triggers `triggerReanalyze()` AND `persistPreferredMergeStrategy()` writes `"median"` to UserDefaults | N/A |
| Unrecognized stored rawValue | UserDefaults key = `"deprecatedStrategy"` (e.g., removed in a library version bump) | `CandidateMergeStrategy(rawValue:)` returns nil; **delete the bad key** and hydrate `.quorum`. On next launch the key is absent (first-launch path). | Silent self-heal, no banner |
| Corrupt UserDefaults (non-string for key) | UserDefaults returns nil for `.string(forKey:)` | Same as "no saved pref" — fall back to `.quorum`. Optional: also remove the non-string value for consistency with the self-heal contract above. | Silent fallback |
| Two Picker changes in rapid succession | User clicks `.median` then immediately `.dedup` | Both `.onChange` invocations fire in order; the second write wins on disk (`"dedup"`); existing in-flight-cancel semantics at `AnalysisViewModel.swift:177-180` mean only the second `triggerReanalyze()` survives. No debounce introduced. | N/A |
| Multiple windows of the app (future) | One window picks `.dedup`, another picks `.quorum` | Both windows write through; last write wins. Acceptable — single-user app, no conflict resolution | N/A |

</frozen-after-approval>

## Code Map

- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift:12` — `init()` becomes `init(configuration: Configuration = .live)`; body hydrates `options.mergeStrategy` from `configuration.defaults`
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift:122` — `var options: AudioAnalysisService.Options = .init()` remains, but `init(configuration:)` overrides `options.mergeStrategy` after Swift's default-property-initializer pass
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift` — add nested `struct Configuration` (with `defaults: UserDefaults`, `fallbackStrategy: CandidateMergeStrategy`, static `.live`), `static let preferredMergeStrategyKey = "preferredMergeStrategy"`, `@ObservationIgnored private let configuration: Configuration`, and `func persistPreferredMergeStrategy()` near the existing static `humanize(_:)` at line 436 (other static helpers cluster there). Include an inline comment near `init(configuration:)` explaining the demo-vs-library default divergence.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift:222` — extend the existing `.onChange(of: viewModel.options.mergeStrategy)` to call `viewModel.persistPreferredMergeStrategy()` before `triggerReanalyze()`
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/AnalysisViewModelSmokeTest.swift` — verify the existing smoke test still passes against an isolated UserDefaults suite; pass a test-Configuration explicitly so the test does not depend on `.standard` state
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/` — new file `MergeStrategyPersistenceTests.swift` exercising the four invariants below in isolation, using `UserDefaults(suiteName:)` with a unique per-test suite name + `removePersistentDomain(forName:)` cleanup in a `deinit` or `defer`
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/PrivacyInfo.xcprivacy:18` — verify only; `CA92.1` already covers this use, no edit needed

## Tasks & Acceptance

**Execution:**
- [ ] `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift` — Add nested `struct Configuration { let defaults: UserDefaults; let fallbackStrategy: CandidateMergeStrategy; static let live = Configuration(defaults: .standard, fallbackStrategy: .quorum) }`. Add `static let preferredMergeStrategyKey = "preferredMergeStrategy"` and `@ObservationIgnored private let configuration: Configuration`. Change `init()` to `init(configuration: Configuration = .live)`: store the config, then read `configuration.defaults.string(forKey: Self.preferredMergeStrategyKey)`; if the raw value decodes via `CandidateMergeStrategy(rawValue:)`, set `options.mergeStrategy` to it; if the raw value is present but does NOT decode, call `configuration.defaults.removeObject(forKey: Self.preferredMergeStrategyKey)` to self-heal AND set `options.mergeStrategy = configuration.fallbackStrategy`; if the raw value is absent, just set `options.mergeStrategy = configuration.fallbackStrategy`. Add `func persistPreferredMergeStrategy()` that writes `options.mergeStrategy.rawValue` to `configuration.defaults` under the same key. Add a doc comment on `init(configuration:)` explicitly noting "the demo seeds `.quorum` while the library default at `AudioAnalysisService.Options` remains `.maxConfidence` — this divergence is intentional, demo policy must not leak into the library".
- [ ] `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift` — Modify the existing `.onChange(of: viewModel.options.mergeStrategy)` closure (line 222) to call `viewModel.persistPreferredMergeStrategy()` immediately before the existing `triggerReanalyze()` call.
- [ ] `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/AnalysisViewModelSmokeTest.swift` — Update `wrapping()` to instantiate `AnalysisViewModel(configuration: .init(defaults: UserDefaults(suiteName: "...test.smoke")!, fallbackStrategy: .quorum))` so the test does not consult `.standard`. Clean up via `removePersistentDomain(forName:)` after the test. Verify BPM detection still passes for the 120 BPM click fixture.
- [ ] `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/MergeStrategyPersistenceTests.swift` — NEW FILE. Swift Testing `@Suite("Merge strategy persistence")` covering four invariants: (1) absent key hydrates `.quorum`, (2) valid raw value `"weightedAverage"` hydrates `.weightedAverage`, (3) `persistPreferredMergeStrategy()` after mutating `options.mergeStrategy = .dedup` writes `"dedup"` to the configured defaults, (4) unrecognized raw value `"bogusStrategy"` hydrates `.quorum` AND removes the bad key from the configured defaults. Each test uses a unique `UserDefaults(suiteName:)` and `removePersistentDomain(forName:)` cleanup.

**Acceptance Criteria:**
- Given the app has never run before (UserDefaults key absent), when the user launches it, then the merge-strategy Picker displays `quorum`. Because the Picker stays bound to `$viewModel.options.mergeStrategy`, this is achieved by VM hydration completing before `ContentView.body` first renders — no `.task`-based bridge, no transient flash.
- Given the user selects `weighted average` from the Picker, when they quit and relaunch the app, then the Picker displays `weighted average` on launch.
- Given the user selects any of the eight `CandidateMergeStrategy` cases, when they quit and relaunch, then the same case is selected on the next launch (verified for each of the eight cases).
- Given UserDefaults contains an unrecognized rawValue (e.g., `"removedCaseName"`), when the user launches the app, then the Picker falls back to `quorum`, no error banner appears, AND the bad key is removed from UserDefaults on hydrate (self-heal). On the *next* launch after that, the key is absent and the first-launch path runs.
- Given the user changes the Picker, when the `.onChange` fires, then BOTH the persistence write AND the existing `triggerReanalyze()` execute — the in-flight re-analysis behavior at `AnalysisViewModel.swift:177-180` is preserved.
- Given two strategy changes occur back-to-back (e.g., user clicks `.median` then immediately `.dedup`), then the last-selected strategy (`dedup`) is the value persisted on disk, the existing in-flight-cancel semantics supersede the first re-analyze with the second, and no debounce layer is introduced.
- Given the existing `AnalysisViewModelSmokeTest.wrapping()` test, when run after this change, then it continues to pass against an isolated UserDefaults suite — the new default (`.quorum` from the test Configuration) must not regress the `bpm-120-click.wav` detection result.
- Given the new `MergeStrategyPersistenceTests` suite, when run, then all four invariants pass independently with no cross-test state leakage (each test uses its own `UserDefaults(suiteName:)`).

## Verification

**Commands:**
- `make demo-fmt` — expected: clean (Swift sources reformatted in place; minimal churn)
- `make demo-lint` — expected: exit 0
- `make demo-build` — expected: BUILD SUCCEEDED
- `make demo-test` — expected: all tests pass; the smoke test still detects the 120 BPM click track
- After build + launch + Picker change + quit: `defaults read com.robbyt.BoomBoomBoomBPM preferredMergeStrategy` — expected: the rawValue of the user's last selection (e.g., `quorum`, `weightedAverage`)
- Reset state for testing first-launch: `defaults delete com.robbyt.BoomBoomBoomBPM preferredMergeStrategy && open <built-app>` — expected: Picker shows `quorum`
- Unrecognized raw-value test: `defaults write com.robbyt.BoomBoomBoomBPM preferredMergeStrategy bogusValue && open <built-app>` — expected: Picker shows `quorum`; after launch, the self-heal path has removed the bad key, so `defaults read com.robbyt.BoomBoomBoomBPM preferredMergeStrategy` reports that the key does not exist.

**Manual checks:**
- Launch fresh-state app → Picker reads `quorum`. Pick `weighted average`. Quit. Relaunch → Picker reads `weighted average`. Pick `dedup`. Quit. Relaunch → Picker reads `dedup`.
- For each of the eight cases, verify roundtrip (set → quit → relaunch → assert).
- Verify Picker change still triggers re-analyze (existing behavior preserved): change strategy mid-result, observe new analysis starts immediately.

## Suggested Review Order

**Persistence layer**

- Entry point — injectable Configuration struct + `.live` default (`.standard` + `.quorum` fallback). Read this first to grasp the dependency-injection seam.
  [`AnalysisViewModel.swift:19`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift#L19)

- `init(configuration:)` hydration — three branches: valid raw, unrecognized (self-heal: remove key + fall back), absent (just fall back). The self-heal arm is the most interesting; that's the pre-1.0 stance on rawValue drift.
  [`AnalysisViewModel.swift:50`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift#L50)

- `persistPreferredMergeStrategy()` — symmetric write path; one-line implementation, called only from ContentView's `.onChange`.
  [`AnalysisViewModel.swift:74`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift#L74)

**UI wiring**

- The single line that turns persistence on: extends the existing onChange to write through before re-analyzing. Picker binding stays unchanged; persistence is invisible to the view.
  [`ContentView.swift:223`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift#L223)

**Tests**

- Four-invariant suite using `UserDefaults(suiteName:)` + `removePersistentDomain` cleanup. Each test independent, parallel-safe, no `.standard` contact.
  [`MergeStrategyPersistenceTests.swift:13`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/MergeStrategyPersistenceTests.swift#L13)

- Smoke-test isolation helpers — `makeIsolatedViewModel` factory + per-suite cleanup. Existing test sites that didn't depend on `mergeStrategy` were left untouched (behaviorally invariant).
  [`AnalysisViewModelSmokeTest.swift:586`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/AnalysisViewModelSmokeTest.swift#L586)
