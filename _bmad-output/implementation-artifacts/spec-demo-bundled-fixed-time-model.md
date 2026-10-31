---
title: 'Demo: ship the fixed-time model built in'
type: 'feature'
created: '2026-10-30'
status: 'in-review'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: '41b8746849803c3ce850e1525cf5acb029b48bac'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The demo ships with no model, so anyone trying it must find and add a `.mlmodelc` before ML does anything. The owner wants the demo, including the App Store archive, to ship with the Story 15.5 fixed-time model built in.

**Approach:** Commit the seed-42 fixed-time model into the demo target's resources, and have `ModelCatalog` list it as a `Bundled` entry on every launch, ready to use without picking a file.

## Boundaries & Constraints

**Always:**
- The bundled model is the exported seed-42 model, byte for byte (`weights/weight.bin` sha256 `cc2c1c8a3e21411a8406f1f3e7c64059f4c8c59446b52628de4f2b6763caa327`), renamed to `fixed-time-tempo-v1.mlmodelc` so the picker shows `fixed-time-tempo-v1`.
- The built `.app` carries the whole bundle at `Contents/Resources/fixed-time-tempo-v1.mlmodelc/`, with its folder structure intact (`weights/`, `analytics/`).
- The bundled entry is never written to bookmark storage. It is found in the app bundle on each launch.
- User-added models keep working exactly as today: add, restore, select and the labeled errors.
- **Launch behavior (owner decision, 2026-10-30): load it, leave it off.** On every launch the bundled model loads and is marked `Selected: yes`, and `Use loaded model` starts off (`mlEnabled = false`). Results under `Default` stay unchanged until the user turns it on. A user who picks another model in the session replaces it, as today.

**Never:**
- No library (`Sources/`) changes.
- No change to the library's shipped surface or to `main`. `Demo/` stays develop-only.
- No new UI controls (no remove button, no model-management screen).
- Don't persist a user-added model selection across launches (W81 stays deferred).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Fresh install | No bookmarks | Picker lists `fixed-time-tempo-v1`, `Source: Bundled`; `Use this model` loads it as Kind Fixed-time | N/A |
| Bundled plus user models | Bookmarks restore 2 models | Bundled row first, then the user rows; selection marks stay URL-keyed | N/A |
| Resource missing | Bundle lookup returns nil (e.g. a test host) | No bundled row; catalog behaves as today | No diagnostic; absence is silent |
| User adds the bundled file from disk | Same bytes, different URL | Added as a separate `User-added` row | N/A |
| Bundled load fails at launch | Technique init throws | No model attached, selection cleared, `Use loaded model` off; the bundled row stays listed | `Reason: bundled-model-load-failed` added to the restore diagnostics, shown on first picker open |
| Bundled chosen later in picker | User clicks `Use this model` | Same as a user model: loads, `mlEnabled` true | Existing failure contract |

</frozen-after-approval>

## Code Map

- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ModelCatalog.swift` -- `ModelSource.bundled` already exists, unused (DD2 comment). `registerEntry(standardizedURL:)` and `mirror(_:source:accessURL:)` are the add path. The bundled URL is its own `accessURL` (an app-bundle read needs no security scope). Update the `ModelSource` doc comment.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift:907` -- `loadModel(at:)`. It calls `startAccessingSecurityScopedResource` defensively, which returns false for a bundle URL; confirm it doesn't treat false as failure. `mlEnabled` is set true on load (`:991`).
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BoomBoomBoomBPMApp.swift:10` -- the app-level `ModelCatalog()`.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ModelPickerView.swift` -- row shows `Source:` from `catalog.source(for:)`. Needs no change unless ordering does.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM.xcodeproj/project.pbxproj` -- the app folder is a `PBXFileSystemSynchronizedRootGroup`. A `.mlmodelc` dropped into it may be copied as one package or flattened file by file. Verify in the built `.app`, and fall back to an explicit folder copy if it flattens.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/ModelCatalogTests.swift` -- existing catalog tests assume an empty catalog with no bookmarks. They must not start seeing the bundled row.
- `Demo/BoomBoomBoomBPM/README.md` -- the demo readme.
- Source model: `/Users/rterhaar/tmp/bbbk-training/fixed-time-runs/seed_42/fixed_time_seed_42.mlmodelc`. Its metadata has no paths or names; the export record is in the sibling `fixed_time_seed_42.export.json`.

## Tasks & Acceptance

**Execution:**
- [x] `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/Models/fixed-time-tempo-v1.mlmodelc/` -- copy the source bundle in unchanged -- ships the model.
- [x] `ModelCatalog.swift` -- add an init parameter for the bundled model URL, defaulting to the `Bundle.main` lookup. Register and mirror it as `.bundled` before `restore()`, and skip it silently when the lookup is nil -- lets tests inject or omit it.
- [x] `BoomBoomBoomBPMApp.swift`/`ContentView.swift`/`AnalysisViewModel.swift` -- at launch, load the bundled entry through `catalog.useModel` + `loadModel(at:)`, then set `mlEnabled = false` without triggering a re-analyze or persisting anything. On failure, add the labeled diagnostic -- the owner's launch decision. Unit-test this launch step through a seam (no GUI).
- [x] `ModelCatalogTests.swift` -- existing tests pass nil explicitly. New tests cover: a bundled row's source, ordering and selection; no bookmark is stored for it; a nil URL gives no row; `useModel` hands the bundle URL to the loader.
- [x] `Demo/BoomBoomBoomBPM/README.md` -- a short section on the built-in model: what it is (Story 15.5 fixed-time, seed 42), the weights sha256, how it was exported (`make fixed-time-export`), and how to replace it.

**Acceptance Criteria:**
- Given a fresh build, when the `.app` is inspected, then `Contents/Resources/fixed-time-tempo-v1.mlmodelc/weights/weight.bin` exists and matches the pinned sha256.
- Given the built app, when the picker opens, then the bundled row shows `Source: Bundled`, and choosing it gives `Kind: Fixed-time` with the ML rows in Diagnostics.
- Given `make demo-test`, then every existing demo test passes unchanged in meaning.

## Implementation Notes

- Status note: the status stays `in-review` until the owner's GUI smoke test in the running app (CLAUDE.md demo-UI rule). After review, `make demo-build` (bundle tree and weight sha256 checked in the built app), `make demo-test`, `make demo-lint` and `make demo-fmt` all pass.

- The synchronized root group copies `Models/fixed-time-tempo-v1.mlmodelc` as one package (flattened to `Contents/Resources/`, folder tree intact); no pbxproj edit was needed.
- The launch step runs from `ContentView`'s `.task`, once per `AnalysisViewModel`. A window reopened in the same session gets a fresh view model, so it loads the bundled model again and the shared catalog's `Selected:` mark moves back to it, matching the technique that window actually has attached.
- A bundled resource that is present but fails to register (unhashable) is skipped silently, like a nil lookup; the matrix names no diagnostic for it.

## Spec Change Log

## Review Triage Log

| # | Layer | Finding | Verdict | Evidence | Route |
|---|---|---|---|---|---|
| 1 | blind, edge, gap | A second window (Cmd-N) reruns the launch step, which moves the shared `Selected:` mark or clears another window's mark on failure | medium | `WindowGroup` gives each window its own view model but one app-level `ModelCatalog`. The mark is app-wide while models are per window, so the same mismatch already happens when a user picks a model in a second window. The launch step makes it happen without user action. | defer |
| 2 | edge | A second window's failed launch load appends a duplicate `bundled-model-load-failed` | low | Real, but it needs both a failing bundled load and two windows, and the fix adds a guard | reject |
| 3 | blind | Opening the picker clears the launch failure's real cause (`mlModelError`), leaving only the generic reason | low | The `onAppear` clearing predates this change and applies to every model. The cause is shown in the main window until the picker opens. A launch failure of the tested bundled model is unlikely. | reject |
| 4 | blind | Every launch compiles the model twice on the main thread (window model attempt, then fixed-time) and hashes it | low | The two attempts come from #218's `constructTechnique` fallback. Loading at launch is the owner's decision. The cost is well under a second, and avoiding it needs a new kind parameter. | reject |
| 5 | blind, edge | A bundled resource that is present but unreadable disappears with no diagnostic | low | `registerEntry` only throws when hashing fails. An unreadable file inside the signed app bundle is unlikely, and the fix adds a branch. A damaged-but-readable model registers and then fails at load with the labeled reason. | reject |
| 6 | edge | The README says a load failure shows the reason, but a registration failure shows nothing | false | The README sentence covers load failures, which do add the reason (`loadBundledModelAtLaunch`). Registration failure is row 5. | reject |
| 7 | gap, blind | No test runs the real launch path: the default `Bundle.main` URL plus the default loader | medium | Pre-verified. Every test injects a URL or a loader, so a miswired default would pass `make demo-test`. | patch |
| 8 | blind | `launchStepRunsOnce` is named "never replaces a later pick" but never picks another model | low | Confirmed. The test only toggles `mlEnabled`. | patch |
| 9 | blind | `BundledModelLaunchTests` leaves its temp `.mlmodelc` folders behind | low | Confirmed: `cleanUp` removes only the `UserDefaults` suites | patch |
| 10 | blind | The Makefile help for `fixed-time-export` says "Weights stay outside git", but the demo now commits a copy | low | Confirmed at `Makefile:1184` | patch |
| 11 | blind | CLAUDE.md says compiled models live under `_bmad-output/ml-models/` and doesn't mention the demo's built-in copy | low | That line is about the library. A note about the demo copy would go in an agent-context file. | defer |
| 12 | blind | The README gives no accuracy or trust information for a model that now ships | low | Confirmed. The training report has the GiantSteps numbers and calls the run a smoke test of the training setup. A two-line addition fixes it. | patch |
| 13 | blind | The README's provenance claims (seed, 1e-3 export check) aren't backed by any committed record | false | The 1e-3 check is enforced by the committed `export.py` (`fixed-time-export` refuses otherwise). The pinned weight hash ties the committed bytes to that export. Training runs stay outside git by design. | reject |
| 14 | blind | The spec file is untracked, so the code's references to it point at nothing | false | The spec is committed with the change in step 5 | reject |
| 15 | blind | `restoreDiagnostics` / `clearRestoreDiagnostics` now hold a launch failure too, so the names are stale | low | The doc comment says so. No named harm beyond the name, and a rename touches the picker. | reject |
| 16 | blind | The pinned-hash test checks only `weight.bin`, and the hash is written in two places | low | The weights are the bytes that matter. Hashing the whole tree adds complexity, and the README pairing is documented in its replace steps. | reject |
| 17 | blind | The `.capabilityMissing` branch can't run and has no test | low | It's defensive code, commented as unreachable, and it detaches correctly. No harm named. | reject |
| 18 | blind | The comment's reason why `onChange` doesn't fire is wrong | false | `onChange` compares values between view updates, and the true-then-false pair is set synchronously, so no update sees `true`. The comment is accurate (the toggle being hidden until a model loads is a second, independent reason). | reject |

## Verification

**Commands:**
- `make demo-build` -- expected: BUILD SUCCEEDED; then `find` the built `.app` for the bundle tree and `shasum -a 256` its `weight.bin`.
- `make demo-test` -- expected: TEST SUCCEEDED.
- `make demo-lint` and `make demo-fmt` (no diff) -- expected: clean.

**Manual checks:**
- Owner GUI smoke (gates `done`): a fresh launch shows the bundled row as `Selected: yes`, `Use loaded model` is off, and `Default` BPMs are unchanged. Turning it on with `ML augmented` shows the ML rows and 1-4 shaded crops.
