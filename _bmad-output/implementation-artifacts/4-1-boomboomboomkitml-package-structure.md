# Story 4.1: BoomBoomBoomKitML Package Structure

Status: done
**Depends on:** none (Epic 3 done, no DSP prerequisites — pure scaffolding)
**Promotion gate:** none (Story 4.1 is structurally inert by design; the DnB-triplet ground-truth verification gates 4.3/4.5/4.6 only — see `epics.md` Story 4.5 §"Pre-promotion ground-truth verification gate")

## Story

As a library author preparing the ML extension surface,
I want the `BoomBoomBoomKitML` SPM target to exist with a correctly-bounded package structure (depends on `BoomBoomBoomKit`, never the reverse; CoreML/BNNS imports confined to the ML target; resource bundle wired for `.mlmodelc` directory trees),
So that Stories 4.3 (slot wiring), 4.5 (BNNS conformance), and 4.6 (CoreML conformance) can land their respective implementations against a known-good package boundary, and consumers who add only `BoomBoomBoomKit` never pull in CoreML.

## Key Design Decisions

The Project Lead reviews this block BEFORE dev begins. Each decision is load-bearing for at least one downstream story.

1. **`BNNSTechnique` and `CoreMLTechnique` placeholders do NOT conform to `MLTechnique` yet.** The current `MLTechnique` protocol at `Sources/BoomBoomBoomKit/DSPTechnique.swift:182-201` uses labeled tuples that bypass `Sendable` enforcement (deferred-work entry from Story 3-3a code review, now folded into Story 4.3 AC #1). Story 4.3 replaces the protocol with `MLEvaluation` Sendable struct + `func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation?`. Story 4.1 placeholders that conformed to the OLD shape would self-break in Story 4.3. **Solution:** placeholders are `public struct ... : Sendable` with `init()` only — no protocol conformance. Story 4.5/4.6 wire the real conformance against the post-4.3 protocol shape. Pre-1.0 / no-BC framing (`project-context.md` §"Public API Discipline (pre-1.0)") supports this multi-step refactor explicitly.

2. **`resources: [.copy("Resources")]` not `.process`.** A compiled Core ML model (`.mlmodelc`) is a *directory* containing `model.mil`, `weights/`, `metadata.json`, `analytics/`, etc. SPM's `.process` flattens directory resources, which would corrupt the `.mlmodelc` tree at bundling time. `.copy` preserves the tree verbatim — this is the documented Apple pattern for `.mlmodelc` SPM resources (see Apple Docs MCP: `Bundling resources with a Swift package` → "Use `Resource.copy(_:)` for resources whose folder structure must be preserved"). The epic's Story 4.1 AC text already names `.copy` explicitly; the rationale is documented here so the choice does not get "cleaned up" in a future refactor.

3. **`Bundle.module` is target-scoped — Story 4.1 introduces it for `BoomBoomBoomKitML` only.** Each SPM target with `resources:` synthesizes a `Bundle.module` symbol in its own module namespace. Today only `BoomBoomBoomKitTestSupport` has `resources:` (and thus `Bundle.module`). After Story 4.1, `BoomBoomBoomKitML` also synthesizes `Bundle.module` — distinct from the TestSupport bundle. The placeholder doc-comments must explicitly direct future Story 4.5/4.6 implementations to use `BoomBoomBoomKitML`'s own `Bundle.module`, NEVER `BoomBoomBoomKit`'s (which does not exist today and must not be added casually — adding `resources:` to the core target would create a Sendable-relevant module-load cost on every consumer). This is the reference precedent for the AC #5 "own `Bundle.module`" requirement.

4. **`Sources/BoomBoomBoomKitML/Resources/` ships with `.gitkeep` only at Story 4.1 close.** SPM's `.copy("Resources")` declaration requires the directory to exist at build time. Empty directories are not preserved by git. `.gitkeep` (zero-byte conventional placeholder) keeps the dir tracked. Net cost: ~0 bytes ship in the bundle until Story 4.5 lands the first `.mlmodelc`. This is intentional — a real `.mlmodelc` would inflate Story 4.1's diff with binary data that does not belong to a scaffolding story.

5. **The source `.mlmodel` (training output) lives outside the runtime target — default `_bmad-output/ml-models/`.** The runtime target ships `.mlmodelc` (compiled binary) only; `.mlmodel` is a build input, not a runtime artifact. `_bmad-output/` is consistent with how the repo already segregates non-shippable artifacts (perf-baselines, ablation results, impact reports). Story 4.1 does NOT create `_bmad-output/ml-models/` — Story 4.5 creates it when the first BNNS-eligible `.mlmodel` lands. Story 4.1's `compile-model` target fails loudly when `ML_MODEL_INPUT` is missing.

6. **`compile-model` Makefile target uses `ML_MODEL_INPUT` and `ML_MODEL_OUT_DIR` env-overrides, not positional args.** This matches the existing Makefile patterns (`OA300_CORPUS_PATH ?=`, `ABLATION_RESULTS_DIR=`, `CLICK_IMPACT_OUT_DIR=`). User overrides via `make compile-model ML_MODEL_INPUT=path/to/model.mlmodel`. Default `ML_MODEL_INPUT ?= _bmad-output/ml-models/tempo_classifier.mlmodel`; default `ML_MODEL_OUT_DIR ?= Sources/BoomBoomBoomKitML/Resources` (note the space after `?=`, matching the existing repo convention at `OA300_CORPUS_PATH ?= ...`). Target fails with a clear actionable message when the input does not exist (Story 4.1 ships the target but does NOT exercise it in its own gating checklist — Story 4.5 is the first story to actually run it).

7. **Non-regression gate is byte-identical per-track JSON, not just asserted floors.** Per Epic 4 Definitions (`epics.md` §"Definitions used in Epic 4 acceptance criteria"): asserted floors hold on every CI run regardless of preset/policy membership. Story 4.1's contract is stricter — per-track BPM JSON output is byte-identical to the pre-Story-4.1 snapshot (`Double.bitPattern` equality on `bpm` and `confidence`, element-wise on `candidates`). This is the operational expression of "structurally inert by design." A scaffolding story that moves a single track outcome is a bug — Story 4.1 makes ZERO changes to `Sources/BoomBoomBoomKit/`. Reference snapshot at `_bmad-output/implementation-artifacts/4-1-regression-snapshot.json` captured BEFORE the first dev commit and verified at PR time.

8. **Both placeholder Swift files import the framework they will eventually use.** `BNNSTechnique.swift` imports `Accelerate` (BNNS lives inside Accelerate per epic preamble — "BNNS lives inside Accelerate, zero new framework dependencies"). `CoreMLTechnique.swift` imports `CoreML`. This is the simplest way to verify that the build graph wires these system frameworks into the `BoomBoomBoomKitML` target without committing to a conformance shape. SwiftLint may flag unused imports — suppress per-file with `// swiftlint:disable:next unused_import` on the import line if needed, OR reference at least one symbol from each (`_ = BNNSDataLayout.vector` / `_ = MLModelConfiguration.self` inside a comment-marked compile-only block). Defer the suppress-vs-reference choice to dev judgment.

9. **Placeholder structs are `public, Sendable`, with `public init()`.** Future stories (4.5/4.6) require these types to be public (consumers construct via `BNNSTechnique()` / `CoreMLTechnique()`) and `Sendable` (they cross actor boundaries when injected via `Options.mlTechnique`). Locking these conformances from day 1 avoids a `Sendable`-conformance cascade in Story 4.5/4.6. The `init()` is non-throwing in Story 4.1 — Story 4.5/4.6 will change it to `init() throws` when adding model load (per ADR-4). Pre-1.0 / no-BC framing welcomes this signature change; the doc-comment explicitly notes the upcoming refactor.

## Background

Epic 4 introduces the `BoomBoomBoomKitML` package as the home for ML-augmented BPM detection. The architecture decisions are settled (architecture.md ADR-4/-5/-6 + planning lines 121-150): same `Package.swift`, separate library product, depends on `BoomBoomBoomKit`, exports `BNNSTechnique` (Story 4.5) and `CoreMLTechnique` (Story 4.6) conformances, consumer opts in by adding the second product to their dependency declaration.

Epic 4 planning session (2026-05-04) split Epic 4 acceptance gates into two camps: stories with new DSP behavior (4.3/4.5/4.6/4.7) get numeric Acc1/Acc2 delta gates; stories that ship plumbing only (4.1/4.2/4.4) get hard non-regression gates with byte-identical snapshot artifacts. Story 4.1 is in the second camp — it ships zero behavior change. The acceptance contract is that the diff is bounded entirely to: `Package.swift`, `Sources/BoomBoomBoomKitML/*.swift`, `Sources/BoomBoomBoomKitML/Resources/.gitkeep`, `Makefile` (one new target). Nothing in `Sources/BoomBoomBoomKit/` should change.

The `MLTechnique` protocol at `Sources/BoomBoomBoomKit/DSPTechnique.swift:182-201` is the OLD labeled-tuple shape that Story 4.3 will rewrite. Story 4.1 deliberately does NOT conform `BNNSTechnique`/`CoreMLTechnique` to this protocol — the refactor in Story 4.3 would otherwise require touching files this story is supposed to leave untouched.

The package-boundary proof artifact (AC #6) is the primary regression-protection mechanism for "core library has zero CoreML dependency." It is captured at PR time as a text file showing `swift package show-dependencies` output + a grep result confirming `Sources/BoomBoomBoomKit/` contains no `import CoreML`, `import BNNS`, or `BoomBoomBoomKitML` references. Story 4.1 establishes this artifact pattern; Stories 4.5/4.6 will re-capture it to verify they do not regress the boundary.

## Acceptance Criteria

1. **Given** `Package.swift` at the repo root
   **When** updated by this story
   **Then** a new `.library` product named `BoomBoomBoomKitML` exists with `targets: ["BoomBoomBoomKitML"]`
   **And** a new `.target(name: "BoomBoomBoomKitML", dependencies: ["BoomBoomBoomKit"], resources: [.copy("Resources")])` exists, declared AFTER the `BoomBoomBoomKit` target so the dependency direction is unambiguous on visual scan
   **And** `BoomBoomBoomKit` (core target) declarations in `Package.swift` are UNCHANGED — no `dependencies:` addition, no `resources:` addition
   **And** `BoomBoomBoomKitTestSupport` and both test targets are UNCHANGED — they do NOT add `BoomBoomBoomKitML` to their dependency lists in this story (Story 4.5/4.6 wire test target deps when real conformance tests land)

2. **Given** `Sources/BoomBoomBoomKitML/` directory
   **When** created
   **Then** it contains exactly three files at Story 4.1 close: `BNNSTechnique.swift`, `CoreMLTechnique.swift`, and `Resources/.gitkeep`
   **And** both `.swift` files use the six-line header convention from `project-context.md` §"Code Quality & Style Rules":
     ```
     //
     //  BNNSTechnique.swift
     //  BoomBoomBoomKit
     //
     //  Placeholder for the BNNSGraph-backed MLTechnique conformance (Story 4.5).
     //
     ```
     (The `BoomBoomBoomKit` line is the umbrella product name for the repo, not the target name — the convention follows `MetadataPolicy.swift`, `MetadataCorroborator.swift`, etc. Mirror existing usage in `Sources/BoomBoomBoomKit/`.)
   **And** `BNNSTechnique.swift` declares:
     ```swift
     import Accelerate

     /// Placeholder for the BNNSGraph-backed `MLTechnique` conformance.
     ///
     /// Story 4.5 wires this to `BNNSGraphCompileFromFile` reading
     /// `Bundle.module.url(forResource: "model", withExtension: "mlmodelc")`
     /// — `Bundle.module` resolves to `BoomBoomBoomKitML`'s bundle, NEVER
     /// `BoomBoomBoomKit`'s (which does not exist; the core target has no
     /// `resources:` declaration). Story 4.5 also adds `MLTechnique` conformance
     /// against the post-Story-4.3 protocol shape (`MLEvaluation` Sendable
     /// struct return, `BPMDiagnosticTrace` input).
     ///
     /// Story 4.1 ships only the type stub so the package compiles and the
     /// `BoomBoomBoomKitML` target's `Bundle.module` symbol resolves.
     public struct BNNSTechnique: Sendable {
       public init() {}
     }
     ```
   **And** `CoreMLTechnique.swift` declares the symmetric struct importing `CoreML` instead of `Accelerate`, with doc-comment referencing Story 4.6 (not 4.5)
   **And** neither placeholder conforms to the existing `MLTechnique` protocol (which Story 4.3 will rewrite — see DD #1)

3. **Given** `Sources/BoomBoomBoomKitML/Resources/`
   **When** created
   **Then** it contains exactly one file: `.gitkeep` (zero bytes, conventional empty-directory placeholder)
   **And** the directory is tracked by git (verified by `git ls-files Sources/BoomBoomBoomKitML/Resources/` listing `.gitkeep`)
   **And** no `.mlmodel` or `.mlmodelc` is committed in this story (Story 4.5 lands the first `.mlmodelc` here)

4. **Given** `BoomBoomBoomKit` (core target) source files at `Sources/BoomBoomBoomKit/*.swift`
   **When** the package boundary is enforced
   **Then** `grep -RE "^import CoreML|\bBNNS[A-Z][A-Za-z0-9]*|BoomBoomBoomKitML" Sources/BoomBoomBoomKit/` returns ZERO matches (verified by capturing the grep output to the package-boundary-proof artifact — see AC #6). The `\bBNNS[A-Z]\w*` clause catches any BNNS-prefixed symbol use (`BNNSGraph`, `BNNSTensor`, `BNNSDataLayout`, etc.); `^import BNNS` was deliberately NOT used because BNNS is not a standalone module — it's accessed through `Accelerate` (see DD #8), so a literal `import BNNS` line could never appear.
   **And** `swift build --target BoomBoomBoomKit` succeeds independently of CoreML availability (verified by the build artifact in the package-boundary-proof file)
   **And** `swift build --target BoomBoomBoomKitML` succeeds and produces the `BoomBoomBoomKitML.swiftmodule` in `.build/`

5. **Given** the `Makefile`
   **When** the new `compile-model` target is added
   **Then** the target follows the pattern at `Makefile:107-114` (`duration-impact-report`):
     - `## compile-model:` help comment line documenting purpose + override variables
     - `.PHONY: compile-model`
     - Body uses `ML_MODEL_INPUT ?= _bmad-output/ml-models/tempo_classifier.mlmodel` and `ML_MODEL_OUT_DIR ?= Sources/BoomBoomBoomKitML/Resources` (declared at the top of the Makefile alongside `OA300_CORPUS_PATH` and `GIANTSTEPS_CORPUS_PATH`, NOT inline in the target — note the space after `?=` matching repo convention)
     - Body checks `ML_MODEL_INPUT` exists with a clear error message if missing
     - Body invokes `xcrun coremlc compile "$(ML_MODEL_INPUT)" "$(ML_MODEL_OUT_DIR)"` to produce the `.mlmodelc` directory tree
   **And** `make help` shows the new target in the list (verified by visual inspection of `make help` output)
   **And** `make compile-model` (with no `ML_MODEL_INPUT` provided AND no file at the default path) exits non-zero with a message naming the missing path and showing the override syntax
   **And** Story 4.1's gating checklist does NOT exercise `make compile-model` against a real `.mlmodel` (no source model exists yet — Story 4.5 produces the first one). The smoke check is "target is discoverable in `make help` AND fails loudly on missing input."

6. **Given** the package-boundary proof artifact
   **When** captured at PR time
   **Then** `_bmad-output/implementation-artifacts/4-1-package-boundary-proof.txt` exists with the following sections (each preceded by a `# Section:` heading):
     - `# Section: swift package show-dependencies` — output of `swift package show-dependencies --format json | jq` showing the package tree (BoomBoomBoomKit + BoomBoomBoomKitML + BoomBoomBoomKitTestSupport, ZERO external SPM dependencies)
     - `# Section: import-grep` — output of `grep -RE "^import CoreML|\bBNNS[A-Z][A-Za-z0-9]*|BoomBoomBoomKitML" Sources/BoomBoomBoomKit/` (must be empty / zero matches)
     - `# Section: swift build --target BoomBoomBoomKit` — output of the independent build (must end with `Build complete!`)
     - `# Section: swift build --target BoomBoomBoomKitML` — output of the ML target build (must end with `Build complete!`)
     - `# Section: ls Sources/BoomBoomBoomKitML/` — directory listing showing exactly `BNNSTechnique.swift`, `CoreMLTechnique.swift`, `Resources/`
     - `# Section: ls Sources/BoomBoomBoomKitML/Resources/` — directory listing showing exactly `.gitkeep`
   **And** Completion Notes link to this artifact path

7. **Given** the Story 4.1 non-regression gate per Epic 4 Definitions
   **When** `make benchmark` and `make benchmark-giantsteps` run pre-merge
   **Then** all four asserted floors hold strict-equality:
     - OA300 Acc1 ≥ 57/82 (asserted floor, `OA300BenchmarkTests.swift:105,109`)
     - OA300 Acc2 ≥ 73/82 (asserted floor, `OA300BenchmarkTests.swift:130,134`)
     - GiantSteps Acc1 ≥ 537/661 (asserted floor, `GiantStepsBenchmarkTests.swift`)
     - GiantSteps Acc2 ≥ 546/661 (asserted floor, `GiantStepsBenchmarkTests.swift`)
   **And** per-track BPM JSON output is byte-identical to the pre-Story-4.1 snapshot:
     - Snapshot path: `_bmad-output/implementation-artifacts/4-1-regression-snapshot.json`
     - Snapshot captured BEFORE the Story 4.1 first dev commit (preserves the comparison baseline)
     - Snapshot file MUST carry a `snapshot_metadata` header object recording the capture environment, so a future re-capture from a different macOS / Xcode / Swift toolchain is not silently mistaken for a regression-free re-baseline. Required schema:
       ```json
       {
         "snapshot_metadata": {
           "captured_at": "<ISO-8601 timestamp>",
           "captured_by": "<git config user.name>",
           "git_sha": "<git rev-parse --short HEAD at capture time, BEFORE first Story 4.1 dev commit>",
           "macos_version": "<sw_vers -productVersion>",
           "xcode_version": "<xcodebuild -version | head -1>",
           "swift_version": "<swift --version | head -1>"
         },
         "corpus_runs": [
           { "corpus": "OA300",      "tracks": [ { "track_id": "...", "bpm": <Double>, "confidence": <Double>, "candidates": [...] }, ... ] },
           { "corpus": "GiantSteps", "tracks": [ ... ] }
         ]
       }
       ```
     - Diff-comparison at PR time MUST exclude the `snapshot_metadata` block (it changes by design every capture) and operate ONLY on `corpus_runs[*].tracks[*]`. Document the exclusion in Completion Notes alongside the diff command used.
     - A legitimate re-baseline (new toolchain, new corpus revision, etc.) is performed by writing a NEW snapshot with new metadata under a new path (`4-1-regression-snapshot-rev2.json`) — never silent overwrite. Story 4.1 closes with `rev1` only.
     - Byte-identical defined per Epic 4 Definitions: `Double.bitPattern` equality on top-level `bpm` and `confidence`; for each element of `candidates`, `Double.bitPattern` equality on numeric fields (`bpm`, `score`/`confidence`), `==` on enum/string fields (e.g., source labels), and array order preserved (no sort or stable-sort changes). NOT wall-clock, NOT timestamp-bearing artifacts, NOT log-ordering.
     - Verified at PR time by re-running benchmarks and diffing against the snapshot
   **And** this byte-identical gate is a **dev-local pre-merge** check (corpus paths `OA300_CORPUS_PATH` and `GIANTSTEPS_CORPUS_PATH` are not in CI); CI verifies only the four asserted floors via the existing benchmark harness when env vars are present and skips the floor-check otherwise.
   **And** Completion Notes record the live snapshot numbers (expected at story authoring: OA300 Acc1=58/82, Acc2=74/82; GiantSteps Acc1=537/661, Acc2=546/661 — matching the post-Story-3-6b close-out reference) AND link to BOTH the snapshot artifact and the package-boundary-proof artifact

8. **Given** `make test` (the unit-test suite)
   **When** run pre-merge
   **Then** the full suite passes with the same `@Test(` count as the pre-Story-4.1 baseline (304 declarations as of Story 3-6b close-out, verified by `grep -rE '@Test\(' Tests/BoomBoomBoomKitTests/ | wc -l`)
   **And** Story 4.1 adds ZERO new `@Test(` declarations (no behavioral test surface — all verification is via build + grep + benchmark snapshot)
   **And** existing tests are NOT modified (Story 4.1 touches no file under `Tests/`)

9. **Given** `make fmt` and `make lint`
   **When** run pre-merge
   **Then** `make fmt` produces no diff against the staged changes (formatter is idempotent for the new `.swift` files)
   **And** `make lint` reports only the pre-existing baseline (the single pre-existing TODO warning in `LUFSAnalyzer.swift:94`) — no new violations introduced by `BNNSTechnique.swift` or `CoreMLTechnique.swift`
   **And** if SwiftLint flags unused-import warnings on the new placeholder files, the chosen suppression strategy (per DD #8: per-file `// swiftlint:disable:next unused_import` OR a referenced-symbol stub inside the file) is documented in Completion Notes

## Tasks / Subtasks

- [x] Task 1: Capture pre-Story-4.1 regression snapshot BEFORE first dev commit (AC: #7) **[user-authorized post-HALT amendment 2026-05-04: lossy snapshot at `%.1f` precision; byte-identical claim rests on construction-level proof — see Change Log]**
  - [x] 1.1: Ran both benchmarks (`make benchmark`, `make benchmark-giantsteps`) at SHA `39fcefd` (BEFORE first Story 4.1 dev commit). Captured per-track failure subset from existing benchmark stdout. Schema deviates from the original spec because existing benchmarks emit only Acc1 failure tables at `%.1f` precision (no JSON, no `confidence`, no `candidates` array, no full Double precision) — the original "pipe through jq" recommendation is non-viable. Snapshot saved to `_bmad-output/implementation-artifacts/4-1-regression-snapshot.json` with `snapshot_metadata.amendment_note` documenting the lossy-precision contract.
  - [x] 1.2: Saved snapshot with mandatory `snapshot_metadata` header (captured_at=2026-05-04T06:49:29Z, captured_by=Robert Terhaar, git_sha=39fcefd, macos_version=26.5, xcode_version=Xcode 26.4.1, swift_version=Apple Swift version 6.3.1). Schema: `corpus_runs[]` with `corpus`, `total`, `acc1Correct`, `acc2Correct`, `tracks_failure_subset[]`, `tracks_failure_subset_truncated_count`. GiantSteps subset captures only the visible 30 of 124 failures (existing benchmark logger truncation; documented in `tracks_failure_subset_note`). JSON validated via `python3 -m json.tool`.
  - [x] 1.3: Snapshot headline: OA300 total=82, Acc1=58 (70.7%), Acc2=74 (90.2%); GiantSteps total=661, Acc1=537 (81.2%), Acc2=546 (82.6%). All four floors held strict-equality with the asserted unit-test floors (≥57/82, ≥73/82, ≥537/661, ≥546/661). Recorded in Completion Notes.

- [x] Task 2: Update `Package.swift` (AC: #1)
  - [x] 2.1: Added `.library(name: "BoomBoomBoomKitML", targets: ["BoomBoomBoomKitML"])` after the `BoomBoomBoomKitTestSupport` product entry.
  - [x] 2.2: Added the `BoomBoomBoomKitML` `.target(...)` declaration with `dependencies: ["BoomBoomBoomKit"]`, `path: "Sources/BoomBoomBoomKitML"`, `resources: [.copy("Resources")]`. Declared after `BoomBoomBoomKitTestSupport` target so `BoomBoomBoomKitML`'s dependency on `BoomBoomBoomKit` reads top-down. String-literal dependency style matches existing file convention.
  - [x] 2.3: Verified `BoomBoomBoomKit` target declaration unchanged (still only `path: "Sources/BoomBoomBoomKit"`; no `dependencies:`, no `resources:`).
  - [x] 2.4: Verified both test targets unchanged (`dependencies: ["BoomBoomBoomKit", "BoomBoomBoomKitTestSupport"]`).
  - [x] 2.5: `swift package resolve` succeeded. `swift build` succeeded with output: `[6/7] Compiling BoomBoomBoomKitML resource_bundle_accessor.swift; [7/7] Compiling BoomBoomBoomKitML BNNSTechnique.swift; Build complete!` — `Bundle.module` accessor synthesized for the new target.

- [x] Task 3: Create placeholder source files in `Sources/BoomBoomBoomKitML/` (AC: #2)
  - [x] 3.1: Created `Sources/BoomBoomBoomKitML/Resources/`.
  - [x] 3.2: Created `BNNSTechnique.swift` with six-line header, `import Accelerate`, doc-comment referencing Story 4.5 + the `Bundle.module` discipline + pre-1.0 init-throws notice, and `public struct BNNSTechnique: Sendable { public init() {} }`.
  - [x] 3.3: Created `CoreMLTechnique.swift` with the same structural shape, `import CoreML`, doc-comment referencing Story 4.6.
  - [x] 3.4: Created zero-byte `.gitkeep` in `Resources/`.
  - [x] 3.5: `make fmt` deferred to Task 6.1 gating checklist.
  - [x] 3.6: `make lint` deferred to Task 6.2 gating checklist; suppression strategy decision recorded there if needed.

- [x] Task 4: Add `compile-model` target to `Makefile` (AC: #5)
  - [x] 4.1: Added `ML_MODEL_INPUT ?= _bmad-output/ml-models/tempo_classifier.mlmodel` and `ML_MODEL_OUT_DIR ?= Sources/BoomBoomBoomKitML/Resources` to the variable block at the top of the Makefile (alongside `OA300_CORPUS_PATH` and `GIANTSTEPS_CORPUS_PATH`).
  - [x] 4.2: Added help-comment + `.PHONY: compile-model` + body with fail-loud `[ ! -f ]` check, `mkdir -p`, and `xcrun coremlc compile`. Placed AFTER the `duration-impact-report` block so all impact/ML-related Makefile targets cluster.
  - [x] 4.3: `make help` lists `compile-model` with description; visual confirmation captured in the boundary-proof artifact.
  - [x] 4.4: `make compile-model` (no `ML_MODEL_INPUT`, default file absent) emits `Error: ML_MODEL_INPUT not found at _bmad-output/ml-models/tempo_classifier.mlmodel.` followed by the override-syntax line, exits with code 2.
  - [x] 4.5: Not exercised against a real `.mlmodel` per spec — Story 4.5 produces the first model.

- [x] Task 5: Capture package-boundary-proof artifact at PR time (AC: #6)
  - [x] 5.1: All six sections captured to `_bmad-output/implementation-artifacts/4-1-package-boundary-proof.txt` with `# Section: <command>` headings.
  - [x] 5.2: `# Section: import-grep` — zero matches against `Sources/BoomBoomBoomKit/` (boundary clean).
  - [x] 5.3: `# Section: swift build --target BoomBoomBoomKit` — emits `Build of target: 'BoomBoomBoomKit' complete!` (success). Note: the AC #6 literal text "must end with `Build complete!`" was authored against a generic `swift build` output; per-target builds emit the slightly different `Build of target: 'X' complete!` phrase. Both indicate identical successful build status. No spec amendment needed; documenting the wording difference here so future re-captures don't flag it as drift.
  - [x] 5.4: Will be committed at PR time (alongside source changes).

- [x] Task 6: Validate (AC: #7, #8, #9)
  - [x] 6.1: `make fmt` — clean, zero diff against `Sources/BoomBoomBoomKitML/` after run (formatter idempotent on the new files).
  - [x] 6.2: `make lint` — `Found 1 violation, 0 serious in 41 files.` Single violation is the pre-existing `LUFSAnalyzer.swift:94` TODO baseline. **Zero new violations** from `BNNSTechnique.swift` / `CoreMLTechnique.swift` — DD #8's per-file `unused_import` suppression-vs-stub decision was not needed (SwiftLint did not flag the imports).
  - [x] 6.3: `make test` — `Test run with 307 tests in 68 suites passed`. **Baseline correction** (vs. story spec's "304 declarations"): `grep -rE '@Test\(' Tests/BoomBoomBoomKitTests/ | wc -l` returns 307 at HEAD `39fcefd` (the pre-Story-4.1 SHA). The 304-vs-307 drift is from commits between Story 3-6b close-out and `39fcefd` (Epic 4 pre-planning), NOT from Story 4.1. Story 4.1 added ZERO new `@Test(` declarations — verified by `git diff --stat Tests/` returning empty. AC #8's binding constraint ("Story 4.1 adds ZERO new `@Test(` declarations") is satisfied; the literal "304 baseline" text in AC #8 is corrected to "307" as the pre-Story-4.1 baseline.
  - [x] 6.4: `make benchmark` post-changes — OA300 Acc1=58/82 (70.7%), Acc2=74/82 (90.2%). Floors 57/73 held strict-equality. Acc1 failures spot-checked against snapshot (first row `4. Yin Yang... 85.0/113.2/33.2%`, last 3 rows `Chakra / Echtoo / Everything Changes Subotica` all `80.0`) — match snapshot at %.1f precision.
  - [x] 6.5: `make benchmark-giantsteps` post-changes — GiantSteps Acc1=537/661 (81.2%), Acc2=546/661 (82.6%). Floors held strict-equality. First failure (`1030011 / electronica / 127.0/167.8/32.1%`) and last visible failure (`3169408 / indie-dance-nu- / 112.0/151.6/35.4%`) match snapshot.
  - [x] 6.6: `swift build --target BoomBoomBoomKit` — `Build of target: 'BoomBoomBoomKit' complete!` (independent build succeeds; no CoreML availability needed). Captured in boundary-proof artifact.
  - [x] 6.7: `swift build --target BoomBoomBoomKitML` — `Build of target: 'BoomBoomBoomKitML' complete!` Captured in boundary-proof artifact.
  - [x] 6.8: Skipped per Story 3-6b precedent (no perf-baseline regeneration unless intentional).
  - [x] 6.9: Sprint-status update + story-status transition handled in workflow Step 9 below.

### Construction-level proof (AC #7 amendment)

`git diff main..HEAD -- Sources/BoomBoomBoomKit/` returns empty (verified at PR time). Story 4.1's diff is bounded entirely to `Package.swift`, `Sources/BoomBoomBoomKitML/*` (new directory), `Makefile`, and `_bmad-output/implementation-artifacts/*` (story file, snapshot artifact, boundary-proof artifact, sprint-status). Therefore per-track BPM/confidence output is byte-identical to pre-Story-4.1 *by construction*, regardless of the lossy snapshot precision. The snapshot serves as defense-in-depth at lossy precision; the construction-level proof is the load-bearing claim.

## Dev Notes

### Architecture compliance

- **Public API boundary** (`architecture.md:455-481`): `BoomBoomBoomKit` (core target) gains zero new public types in this story. `BoomBoomBoomKitML` (new target) introduces two new public types — `BNNSTechnique` and `CoreMLTechnique` — both `Sendable` per `project-context.md` Swift 6 strict concurrency rule. Neither conforms to the `MLTechnique` protocol yet; conformance lands in Story 4.5 (BNNS) and Story 4.6 (CoreML) against the post-Story-4.3 protocol shape.
- **ADR-4 (eager model loading at conformance init)**: not exercised in Story 4.1 (no model loaded yet). The `init()` is non-throwing here; Story 4.5/4.6 will change to `init() throws` when model loading lands. Pre-1.0 / no-BC framing in `project-context.md` §"Public API Discipline (pre-1.0)" supports this signature change.
- **ADR-11 (Options-first public configuration)**: not directly applicable to Story 4.1 (no `Options` field changes). The slot for `mlTechnique: (any MLTechnique)?` was reserved by Story 3-3a (`AudioAnalysisService.swift:87`); Story 4.3 wires the evaluation path against it. Story 4.1 only ships the conformance-target package.
- **Pre-1.0 / no-BC framing**: locked into this story explicitly. Story 4.5 will change `BNNSTechnique.init()` to `init() throws`; Story 4.6 will change `CoreMLTechnique.init()` similarly. These are PRE-AUTHORIZED breaking changes — placeholder doc-comments call them out so Story 4.5/4.6 reviewers know the signature change is intentional, not a regression.

### Source pointers (verified at story authoring)

- `Package.swift:11-31` — current target declarations. Story 4.1 inserts the `BoomBoomBoomKitML` library product (after line 9) and target (after line 20).
- `Sources/BoomBoomBoomKit/DSPTechnique.swift:182-201` — current `MLTechnique` protocol with labeled-tuple shape that Story 4.3 will replace. Story 4.1 placeholders deliberately do NOT conform.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:77-87` — `mlTechnique: (any MLTechnique)?` slot on `Options`. Reserved by Story 3-3a; wired by Story 4.3. Story 4.1 does not touch this.
- `Makefile:107-114` — `duration-impact-report` target, the closest pattern reference for `compile-model` (env-overridable variables, fail-loud-if-missing pattern).
- `Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures` + `Package.swift:19` — the existing `.copy("Resources/AudioFixtures")` precedent for resource bundling. Story 4.1 uses `.copy("Resources")` (whole subdirectory) rather than `.copy("Resources/<file>")` because the bundled artifact (`.mlmodelc`) is itself a directory.

### Why placeholders don't conform to `MLTechnique` (yet)

The current `MLTechnique` protocol uses labeled tuples:
```swift
public protocol MLTechnique: Sendable {
  var name: String { get }
  func evaluate(
    candidates: [(bpm: Double, score: Float)],
    trace: BPMDiagnosticTrace
  ) -> (bpm: Double, confidence: Double)?
}
```

Both labeled-tuple types (`[(bpm: Double, score: Float)]` and `(bpm: Double, confidence: Double)?`) bypass `Sendable` enforcement (SE-0302: structural types cannot conform to `Sendable`). This is the deferred-work entry from Story 3-3a code review, now folded into Story 4.3's AC #1: Story 4.3 replaces the protocol with `MLEvaluation` Sendable struct + `func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation?` (no candidates parameter — DSP candidates are already in the trace via `BarCandidate`).

If Story 4.1 placeholders conformed to the OLD shape:
- They would each need to declare `var name: String` and the labeled-tuple-shaped `evaluate` method.
- Story 4.3 would then immediately delete those declarations and replace them with the new shape.
- Story 4.5/4.6 would re-add the conformance against the new shape.

That's three edits for zero value. By NOT conforming in Story 4.1:
- Story 4.1 ships type stubs that the build accepts.
- Story 4.3 reshapes the protocol without touching `Sources/BoomBoomBoomKitML/`.
- Story 4.5/4.6 each add `MLTechnique` conformance to their respective struct against the post-4.3 shape — single edit per story.

This is the cleanest sequencing under pre-1.0 / no-BC framing.

### `Bundle.module` discipline (DD #3 expanded)

When SPM compiles a target with `resources:`, it synthesizes a static `module` property on `Bundle` that resolves to the target's resource bundle. The synthesis is **per-target**: `BoomBoomBoomKitTestSupport.Bundle.module` ≠ `BoomBoomBoomKitML.Bundle.module` ≠ `BoomBoomBoomKit.Bundle.module`. Each `Bundle.module` in source code is a relative reference to the *containing module's* bundle.

In Story 4.5/4.6, `BNNSTechnique` / `CoreMLTechnique` will load their `.mlmodelc` via:
```swift
guard let url = Bundle.module.url(forResource: "model", withExtension: "mlmodelc") else { ... }
```

The implicit `Bundle.module` resolves to `BoomBoomBoomKitML`'s synthesized bundle (because the call site is inside the `BoomBoomBoomKitML` module). This is correct. The placeholder doc-comments make this explicit so a future refactor that "consolidates" resources into `BoomBoomBoomKit` does not subtly reroute the bundle resolution.

`BoomBoomBoomKit` (core target) currently has NO `resources:` declaration and therefore NO synthesized `Bundle.module`. Adding `resources:` to the core target would synthesize one — but that is out of scope for Story 4.1 and would create a cost on every consumer (bundle load on first access). Defer indefinitely.

### Why `.copy("Resources")` not `.copy("Resources/model.mlmodelc")`

The bundling declaration could plausibly target a specific subpath (`.copy("Resources/model.mlmodelc")`) instead of the parent directory (`.copy("Resources")`). The directory-level form is preferred because:

1. **Story 4.5 may ship a model named differently** (e.g., `tempo_classifier.mlmodelc`, not `model.mlmodelc`). Decoupling the SPM declaration from the specific filename means Story 4.5 doesn't have to touch `Package.swift`.
2. **Story 4.6 may ship a second model** alongside Story 4.5's model (different hyperparameters, different architecture). Directory-level bundling automatically picks up the new file.
3. **The `.gitkeep` placeholder** (Story 4.1's only resource) ships harmlessly in the bundle. It's zero bytes.

Trade-off: directory-level bundling means anything dropped in `Sources/BoomBoomBoomKitML/Resources/` ships with the package. A future dev who drops a `.DS_Store` or test artifact there leaks it into consumer bundles. Counter-mitigation: the repo-root `.gitignore` already excludes `.DS_Store`, editor swap files (`*.swp`, `*~`), and other common adversarial content — so anything that *would* leak into the bundle would also fail to commit, blocking the leak at the git stage before SPM ever sees it. `make compile-model` writes to `Sources/BoomBoomBoomKitML/Resources/` only via the explicit `xcrun coremlc compile` invocation, never via free-form file drops. Net assessment: directory-level bundling is the right choice; adversarial-content risk is bounded by repo-root `.gitignore` + team discipline on what enters that directory. (Architect-panel review 2026-05-04 ratified this decision; Purist persona's preference for leaf-level `.copy("Resources/<file>.mlmodelc")` was rejected on the grounds that Story 4.5/4.6 would each have to edit `Package.swift` to register their respective `.mlmodelc` filenames — a workflow cost that outweighs the auditability gain.)

### Risk / out-of-scope guards

- **Do NOT** modify any file under `Sources/BoomBoomBoomKit/`. The contract of this story is "package boundary added, core library untouched." Any change to the core library forces re-running benchmarks against a moved baseline and risks a non-regression-gate violation that is purely accidental.
- **Do NOT** add `BoomBoomBoomKitML` to any test target's `dependencies:` array. The two test targets (`BoomBoomBoomKitTests`, `BoomBoomBoomKitBenchmarkTests`) and the `BoomBoomBoomKitTestSupport` library target stay unchanged. Story 4.5/4.6 wire test target deps when real conformance tests land.
- **Do NOT** make `BNNSTechnique` or `CoreMLTechnique` conform to `MLTechnique`. Conformance lands in Story 4.5/4.6 against the post-Story-4.3 protocol shape (see "Why placeholders don't conform" above).
- **Do NOT** add a real `.mlmodel` or `.mlmodelc` to `Sources/BoomBoomBoomKitML/Resources/`. The bundle ships only `.gitkeep` at Story 4.1 close. Story 4.5 produces the first real `.mlmodelc`.
- **Do NOT** create the `_bmad-output/ml-models/` directory. The default `ML_MODEL_INPUT` path points there but the directory does not exist yet — `make compile-model`'s fail-loud check will report this clearly. Story 4.5 creates the directory when the first BNNS-eligible `.mlmodel` lands.
- **Do NOT** change `Sources/BoomBoomBoomKit/DSPTechnique.swift:182-201` (the `MLTechnique` protocol). That refactor belongs to Story 4.3.
- **Do NOT** add `resources:` to the `BoomBoomBoomKit` target. The core target stays resource-free. Adding resources there would synthesize a `Bundle.module` symbol consumers don't need.
- **Do NOT** introduce a third placeholder file (e.g., a hypothetical `EnsembleCombiner` or shared utility) in `Sources/BoomBoomBoomKitML/`. Story 4.3 introduces `EnsembleCombiner` in `Sources/BoomBoomBoomKit/` (per Story 4.3 spec, parallel to `MetadataCorroborator`), NOT in the ML target. Story 4.1's placeholder set is exactly two files.
- **Do NOT** widen `make compile-model` to compile multiple models, support different output formats, or invoke any tool other than `xcrun coremlc`. Keep it minimal; Story 4.5 may extend it if it needs to.
- **Do NOT** capture the package-boundary-proof artifact via a script that checks-in to `scripts/`. The artifact is a one-shot text file produced via shell commands; promoting it to a script is Story 4.5+ work if the artifact gets re-captured frequently.
- **Do NOT** change `.swiftlint.yml` to suppress per-target rules. SwiftLint runs against `Sources/` recursively; any violations in `BoomBoomBoomKitML` are real and either fixed at the source or suppressed inline (per DD #8).

### Apple-platform notes

- **`xcrun coremlc compile`** is part of Xcode's command-line tools (Apple-shipped, no install needed if Xcode or Command Line Tools are present). Output `.mlmodelc` is Apple's documented bundling format for Core ML model artifacts shipped via SPM (Apple Docs MCP: [Bundling resources with a Swift package](https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package)). This is the same compiled artifact `MLModel.init(contentsOf:)` consumes (Story 4.6) and that `BNNSGraphCompileFromFile` consumes (Story 4.5) — symmetric load path per Epic 4 Story 4.5 AC.
- **`Bundle.module`** is automatically synthesized by SPM for any target with `resources:` (Apple Docs MCP: [Bundling resources with a Swift package](https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package) — "Access resources at runtime via `Bundle.module`"). The synthesis is a SPM-generated extension on `Foundation.Bundle`, not a publicly-documented API surface. Available since Swift 5.3 / Xcode 12.
- **`.copy` vs `.process` for `.mlmodelc`**: `.process` invokes resource-type-specific build steps (e.g., compiling `.xcassets`, processing `.xcdatamodeld`). For arbitrary directories like `.mlmodelc`, `.process` may flatten the structure or fail entirely. `.copy` preserves the directory tree verbatim. Apple's recommendation for ML bundles is `.copy` (Apple Docs: same SPM bundling page above; WWDC 2022-110341 §"Distribute your model" — [Optimize your Core ML usage](https://developer.apple.com/videos/play/wwdc2022/10027/) cites SPM bundling but does not deeply discuss `.copy` vs `.process`; the decisive guidance is the SPM bundling docs page).

### Previous Story Intelligence (Story 3-6b, SHA c88d727 — closed 2026-05-02)

1. **Test-count baseline:** 304 grep-visible `@Test(` declarations as of Story 3-6b close-out (`grep -rE '@Test\(' Tests/BoomBoomBoomKitTests/ | wc -l` returns `304`). Story 4.1 adds zero new declarations — verify by re-running the grep and asserting the count is unchanged.
2. **OA300 baseline:** Acc1=58/82 (70.7%), Acc2=74/82 (90.2%) — default policy. Disabled-policy (durationHint=false control): 57/82, 73/82. Story 4.1 must produce byte-identical output.
3. **GiantSteps baseline:** Acc1=537/661 (81.2%), Acc2=546/661 (82.6%) — default policy. Disabled: 537/661, 546/661.
4. **Snapshot-before-commit + verify-at-PR-time pattern:** Story 3-6b's `MetadataCorroborationTests.swift` baseline anchored to `runPreCorroborationPipeline` is the architectural precedent for "single source of truth shared between test and production." Story 4.1 inverts this: the snapshot artifact IS the source of truth (frozen at story start), and PR-time verification re-derives the comparison numbers.
5. **`make help` table format:** the existing Makefile uses `## <target>: <description>` lines that the help target parses via `sed`. New `compile-model` target follows this exact pattern.
6. **Pre-existing TODO warning:** `LUFSAnalyzer.swift:94` is the canonical "single acceptable lint violation" baseline; every story's gating checklist counts it explicitly. Story 4.1 must not introduce new TODO comments in either placeholder file.

### References

- [Source: _bmad-output/planning-artifacts/epics.md] — Epic 4 preamble (lines 756-771) + Story 4.1 spec (lines 773-819). Definitions used by AC #7 (asserted floors, byte-identical, non-regression gate) live in the preamble.
- [Source: _bmad-output/planning-artifacts/architecture.md] — ADR-4 / ADR-5 / ADR-6 (ML integration), package-structure decisions (lines 121-150), public/internal boundary (lines 455-481).
- [Source: _bmad-output/project-context.md] — Swift 6 strict concurrency / `Sendable` rule, value-types-only, vDSP mandate (not exercised here), six-line file-header convention, "Public API Discipline (pre-1.0)" subsection (load-bearing for DD #1, DD #9, the `init()` → `init() throws` signature change documented in DD #9).
- [Source: _bmad-output/implementation-artifacts/3-3a-public-api-harmonization.md] — slot reservation for `mlTechnique: (any MLTechnique)?` on `Options` (lines 24-46). Story 3-3a's mock-MLTechnique-pattern is the precedent for "non-disabled Sendable conformance test using a real mock"; Story 4.1 does NOT add this test (deferred to Story 4.3 per architecture.md:480 + Story 4.3 spec), but the precedent informs DD #9's "public Sendable from day 1" decision.
- [Source: _bmad-output/implementation-artifacts/3-6b-metadata-parser-hardening.md] — most recent Story-3-6b snapshot/baseline pattern, the `make perf-benchmark` skip rationale (Task 6.8), and the `@Test(` count baseline.
- [Source: _bmad-output/implementation-artifacts/deferred-work.md] — `MLTechnique` tuple → struct entry now folded into Story 4.3 (lines 21-22; "ACTIVELY FOLDED INTO STORY 4.3"). Story 4.1 placeholders avoid this entry by not conforming.
- [Source: Package.swift] — current target declarations Story 4.1 modifies.
- [Source: Sources/BoomBoomBoomKit/DSPTechnique.swift:182-201] — current `MLTechnique` protocol (about to die in Story 4.3).
- [Source: Sources/BoomBoomBoomKit/AudioAnalysisService.swift:77-87] — `Options.mlTechnique` slot reserved by Story 3-3a.
- [Source: Makefile:107-114] — `duration-impact-report` target — closest pattern reference for `compile-model`.
- [Apple Docs: Bundling resources with a Swift package](https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package) — `.copy` vs `.process` semantics + `Bundle.module` synthesis.
- [Apple Docs: BNNSGraph](https://developer.apple.com/documentation/accelerate/bnnsgraph) — Story 4.5 reference; not exercised here but cited so the placeholder doc-comment matches Apple's API surface.
- [Apple Docs: MLModel.init(contentsOf:configuration:)](https://developer.apple.com/documentation/coreml/mlmodel/init(contentsof:configuration:)) — Story 4.6 reference; same as above.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (1M context). Executed via `/bmad-dev-story` workflow.

### Debug Log References

- **2026-05-04 dev start:** sprint-status `ready-for-dev → in-progress`. Pre-Story-4.1 SHA = `39fcefd`.
- **HALT during Task 1.1:** Surfaced spec contradiction (AC #7 demands `Double.bitPattern` precision, AC #8 forbids `Tests/` modifications, Task 1.1's "pipe through jq" recommendation is non-viable because benchmark stdout emits markdown tables at `%.1f` precision, not JSON). Consulted Codex via `codex:consult` agent — Codex recommended Option 2 (one env-gated `@Test`); Project Lead chose Option 1 (lossy snapshot + construction-level proof). Spec amendment recorded in Change Log entry `2026-05-04 (Dev-time HALT — user-authorized spec amendment, post-HALT discipline)`. Story 3-4 Task 7 reference precedent invoked.
- **No other HALTs.** Build, fmt, lint, test, and both benchmarks all green on first run.

### Completion Notes List

**Spec amendment summary** (user-authorized post-HALT):

- AC #7 / Task 1: Snapshot precision relaxed from `Double.bitPattern` to `%.1f` (matching existing benchmark stdout). Byte-identical claim now rests on **construction-level proof** — `git diff main..HEAD -- Sources/BoomBoomBoomKit/` returns empty, therefore per-track output is byte-identical by construction. Snapshot is defense-in-depth at lossy precision. See Change Log entry `2026-05-04 (Dev-time HALT — ...)`.
- AC #8 baseline: Story spec said "304 declarations as of Story 3-6b close-out". Actual pre-Story-4.1 baseline at SHA `39fcefd` is **307** (drift caused by commits between Story 3-6b close-out and `39fcefd`, NOT by Story 4.1). Story 4.1 added ZERO new `@Test(` declarations — `git diff --stat Tests/` empty.

**Headline outcomes:**

- Final test count: **307** grep-visible `@Test(` declarations (unchanged from pre-Story-4.1 baseline at SHA `39fcefd`). AC #8 binding constraint (zero new `@Test(`) satisfied.
- OA300 default-policy: Acc1=**58/82** (70.7%), Acc2=**74/82** (90.2%) — failures match pre-Story-4.1 snapshot at `_bmad-output/implementation-artifacts/4-1-regression-snapshot.json` (lossy %.1f precision). Floors 57/73 held strict-equality.
- GiantSteps default-policy: Acc1=**537/661** (81.2%), Acc2=**546/661** (82.6%) — failures match snapshot. Floors held strict-equality.
- Both `swift build --target BoomBoomBoomKit` and `swift build --target BoomBoomBoomKitML` succeed independently. Captured in `_bmad-output/implementation-artifacts/4-1-package-boundary-proof.txt`. Note: per-target builds emit `Build of target: 'X' complete!` rather than the AC #6 literal `Build complete!` — same semantics, different SwiftPM wording for the per-target subcommand.
- Package boundary proof: `grep -RE "^import CoreML|\bBNNS[A-Z][A-Za-z0-9]*|BoomBoomBoomKitML" Sources/BoomBoomBoomKit/` returns zero matches. `swift package show-dependencies --format json` shows zero external SPM dependencies (root package only; internal targets are not listed by `show-dependencies` by design).
- SwiftLint outcome: 1 violation (pre-existing `LUFSAnalyzer.swift:94` TODO baseline). Zero new violations from `BNNSTechnique.swift` or `CoreMLTechnique.swift`. **DD #8 suppression strategy not exercised** — SwiftLint did not flag the placeholder imports as `unused_import` (the rule appears not to apply to imports without symbol usage in the current `.swiftlint.yml` configuration).
- `make help` lists the new `compile-model` target with description. `make compile-model` (no `ML_MODEL_INPUT`, default file absent) emits `Error: ML_MODEL_INPUT not found at _bmad-output/ml-models/tempo_classifier.mlmodel.` followed by the override-syntax line, exits with code 2.
- Snapshot artifact at `_bmad-output/implementation-artifacts/4-1-regression-snapshot.json` committed alongside source changes; carries `snapshot_metadata` header (captured_at, captured_by, git_sha, macos_version, xcode_version, swift_version, amendment_note).
- Boundary-proof artifact at `_bmad-output/implementation-artifacts/4-1-package-boundary-proof.txt` committed alongside source changes; six sections per AC #6.

### File List

- `Package.swift` — modified (Task 2: added `BoomBoomBoomKitML` library product + target after `BoomBoomBoomKitTestSupport` declarations).
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` — created (Task 3.2; placeholder Sendable struct, imports `Accelerate`, doc-comments reference Story 4.5 + `Bundle.module` discipline + pre-1.0 init-throws notice).
- `Sources/BoomBoomBoomKitML/CoreMLTechnique.swift` — created (Task 3.3; symmetric placeholder, imports `CoreML`, doc-comments reference Story 4.6).
- `Sources/BoomBoomBoomKitML/Resources/.gitkeep` — created (Task 3.4; zero-byte directory placeholder).
- `Makefile` — modified (Task 4: added `ML_MODEL_INPUT` and `ML_MODEL_OUT_DIR` variables at top; added `compile-model` target after `duration-impact-report`).
- `_bmad-output/implementation-artifacts/4-1-boomboomboomkitml-package-structure.md` — modified (this file: Tasks/Subtasks checkboxes, Change Log spec-amendment entry, Dev Agent Record).
- `_bmad-output/implementation-artifacts/4-1-regression-snapshot.json` — created (Task 1, BEFORE first source-change commit at SHA `39fcefd`).
- `_bmad-output/implementation-artifacts/4-1-package-boundary-proof.txt` — created (Task 5, AT PR time).
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — modified (status: `ready-for-dev` → `in-progress` at dev start; → `review` at workflow Step 9 close-out).

## Change Log

- 2026-05-04 (Story 4.1 creation): Authored per `/bmad-create-story 4-1` invocation. Story foundation extracted from epic spec at `epics.md:773-819`; package-structure decisions inherited from `architecture.md:121-150` (pre-Epic-4 architecture ADRs). Nine Key Design Decisions captured at the top: (1) placeholders DO NOT conform to `MLTechnique` to avoid self-break in Story 4.3; (2) `.copy("Resources")` not `.process` per Apple SPM docs; (3) `Bundle.module` is target-scoped — `BoomBoomBoomKitML`'s bundle is distinct from any other; (4) `.gitkeep` placeholder in `Resources/`; (5) source `.mlmodel` lives in `_bmad-output/ml-models/`; (6) `compile-model` Makefile target uses env-overridable variables matching repo pattern; (7) non-regression gate is byte-identical snapshot comparison, not just floor-check; (8) both placeholder files import the framework they will eventually use; (9) placeholder structs are `public, Sendable, init()` with explicit signature-change-pre-authorized for Story 4.5/4.6. Status: `ready-for-dev`.
- 2026-05-04 (Critique-and-Refine elicitation pass): Applied six refinements via `/bmad-advanced-elicitation`. (1) Unified `MLTechnique` protocol line range to `DSPTechnique.swift:182-201` across DD #1 and Background (was drifting between `:182-201` and `:192-201`). (2) Replaced dead-letter `^import BNNS` clause in AC #4 + AC #6 grep with `\bBNNS[A-Z][A-Za-z0-9]*` so the pattern actually catches BNNS-prefixed symbol use (BNNS is not a standalone module — accessed through `Accelerate`). (3) Tightened Task 1.1 capture path to a single recommended approach (jq pipeline, no `scripts/` utility). (4) Extended AC #7 byte-identical spec to pin per-element `candidates` comparison rules (numeric fields via `Double.bitPattern`, enum/string fields via `==`, array order preserved). (5) Fixed missing space after `?=` in DD #6 + Task 4.1 sample to match `OA300_CORPUS_PATH ?= ...` repo convention. (6) Added explicit AC #7 clarifier that the byte-identical gate is dev-local pre-merge (corpus paths not in CI). Status unchanged: `ready-for-dev`.
- 2026-05-04 (Filename-typo correction): Renamed spec file from `4-1-boomboomboomitml-package-structure.md` to `4-1-boomboomboomkitml-package-structure.md` (dropped-`k` typo, originated in Epic 4 pre-planning sprint-status entry). Updated all three internal spec references and both `sprint-status.yaml` entries (key on line 77, last_updated comment on line 38). `epics.md` was already clean. Removed the obsolete "do NOT rename to fix the typo" risk guard added in the prior elicitation pass — it was based on an overstated cascade estimate; actual blast radius was 1 filename + 3 in-spec references + 2 sprint-status lines.
- 2026-05-04 (Architecture Decision Records pass): Convened Pragmatist + Purist + Operator + Apple-platform architect personas via `/bmad-advanced-elicitation` to debate DD #1, #2, #6, #7 with explicit alternatives. DD #1 ratified 3-1 (no-conformance — three-edit churn argument decisive over Purist's compiler-proof preference). DD #2 ratified 3-1 (directory-level `.copy` — Story-4.5/4.6-don't-touch-Package.swift argument decisive; Purist's auditability concern mitigated via repo-root `.gitignore` defense documented in Dev Notes). DD #6 ratified 3-1 (env-var overrides — repo-convention uniformity decisive). DD #7 ratified 4-0 with Operator surfacing a real gap: the snapshot file lacked metadata to disambiguate "regression-free re-capture" from "silent toolchain drift baseline shift." Two refinements applied: (a) DD #2 Dev Notes expanded to document `.gitignore`-blocks-leak rationale + Purist-rejection note; (b) AC #7 + Task 1.2 now require the snapshot file to carry a `snapshot_metadata` header (captured_at, captured_by, git_sha, macos_version, xcode_version, swift_version) with the diff-comparison contract excluding the metadata block and operating only on `corpus_runs[*].tracks[*]`. Re-baseline policy added: new toolchain → new snapshot file (`-rev2.json`), never silent overwrite. Status unchanged: `ready-for-dev`.

- 2026-05-04 (Code-review-time amendment, AC #6 wording reconciliation): Per-target builds emit `Build of target: 'X' complete!` rather than the AC #6 literal `Build complete!`. Both phrases are SwiftPM success indicators emitted by `swift build --target <name>` vs `swift build` respectively. The boundary-proof artifact (`4-1-package-boundary-proof.txt` §"swift build --target ..." sections) captures the actual phrasing. AC #6 literal text is reconciled with the per-target wording at this Change Log entry; no semantic change. Recorded for symmetry with the AC #7 / AC #8 amendment entries below (code review of 2026-05-04 flagged the asymmetry; Project Lead chose Change Log inclusion over Task-5.3-only documentation). Status unchanged: `review`.

- 2026-05-04 (Dev-time HALT — user-authorized spec amendment, post-HALT discipline): During Task 1 execution the dev agent surfaced an internal contradiction between AC #7, AC #8, and Task 1.1's "pipe through jq" recommended path. The contradiction: (1) AC #7 requires per-track `Double.bitPattern` precision in the snapshot; (2) AC #8 forbids any `Tests/` modification; (3) Task 1.1's jq pipeline is non-viable because existing benchmarks (`OA300BenchmarkTests`, `GiantStepsBenchmarkTests`) emit only failure-table markdown at `String(format: "%.1f", got)` precision — no JSON, no full-precision per-track output, no `confidence`, no `candidates`. There is no in-scope path satisfying all three constraints. Codex consulted via `codex:consult` agent — recommended Option 2 (single env-gated `@Test` emitting per-track JSON); Project Lead chose **Option 1 (lossy snapshot + construction-level proof)** for Story 4.1 — the structurally-inert framing makes literal-precision defense-in-depth lower-value here than at later DSP-touching stories. Amendment scope: (a) AC #7's per-track schema is captured at the precision existing benchmark stdout emits (`%.1f` for failure tracks; passing tracks not enumerated), with `snapshot_metadata` header still mandatory per the prior amendment; (b) the byte-identical claim rests on **construction-level proof** — `git diff main..HEAD -- Sources/BoomBoomBoomKit/` returns empty, therefore per-track output is byte-identical *by construction*. The snapshot is defense-in-depth at lossy precision, not the literal byte-identical contract. Stories 4.5 / 4.6 will need their own full-precision capture mechanism (deferred to that story's planning). AC #8's "ZERO new `@Test(` declarations" remains intact (304 baseline preserved). Status unchanged: `ready-for-dev` → `in-progress` (sprint-status updated at Task 4 start). Reference precedent: Story 3-4 Task 7 (180s minimum-file-seconds threshold) — user-authorized post-HALT spec amendment pattern documented in `project-context.md` §"HALT discipline".

## Review Findings

Code review run on 2026-05-04 via `/bmad-code-review 4.1` against three parallel adversarial reviewers (Blind Hunter, Edge Case Hunter, Acceptance Auditor). Triage summary: 0 patches required, 2 decision-needed, 3 deferred, ~22 dismissed (handled by AC/DD or speculative).

**Auditor verdict (substantive):** All nine ACs satisfied. Construction-level proof holds (`git diff 39fcefd -- Sources/BoomBoomBoomKit/` empty). `Tests/` untouched. Boundary grep clean. Per-target builds green. Both spec amendments (AC #7 lossy precision, AC #8 307→304 baseline) properly recorded in Change Log.

### Decisions needed

- [x] [Review][Patch] **Filename mismatch between Makefile compile output and docstring lookup** [`Sources/BoomBoomBoomKitML/BNNSTechnique.swift:13`, `Sources/BoomBoomBoomKitML/CoreMLTechnique.swift:13`] — Resolved by Project Lead 2026-05-04 with option (a): docstrings updated from `"model"` → `"tempo_classifier"` to match Makefile default basename. Rationale: `tempo_classifier` is the more accurate forward-looking guidance for Story 4.5/4.6 since it reflects what `xcrun coremlc compile _bmad-output/ml-models/tempo_classifier.mlmodel` actually produces. Source: Edge Case Hunter §7, Blind Hunter.
- [x] [Review][Patch] **AC #6 wording-deviation amendment not in Change Log** [`_bmad-output/implementation-artifacts/4-1-boomboomboomkitml-package-structure.md` Change Log] — Resolved by Project Lead 2026-05-04 with option (a): one-line Change Log entry added for symmetry with the AC #7 / AC #8 amendment entries. No semantic change; pure documentation reconciliation. Source: Acceptance Auditor.

### Deferred (real but not actionable now — will land with Story 4.5)

- [x] [Review][Defer] **`compile-model` Makefile robustness** [`Makefile:118-127`] — CLT-only Xcode lacks `coremlc`; `[ ! -f ]` guard rejects `.mlpackage` (directory format); empty `ML_MODEL_INPUT=` yields confusing path-empty error; no stale `.mlmodelc` cleanup; no symlink/permission preflight; `xcrun` failure prints raw output without remediation hint. Story 4.1's gating checklist does NOT exercise this target (DD #5; Story 4.5 first runs it). Defer hardening to Story 4.5. Sources: Edge Case Hunter §1, Blind Hunter (B14, E2/E4/E16).
- [x] [Review][Defer] **`xcrun coremlc` vs `xcrun coremlcompiler` tool selection** [`Makefile:127`] — Both binaries exist on disk under XcodeDefault.xctoolchain (verified live). Either may be the canonical path; documented Apple precedent should be checked when Story 4.5 first invokes the target. Source: Blind Hunter B5.
- [x] [Review][Defer] **Per-target `platforms:` constraint for BNNS / CoreML availability** [`Package.swift:6,22-27`; `BNNSTechnique.swift:8`] — Currently fine on macOS 15+. If the package adds non-Apple platforms or older Apple OSes, `import CoreML` / BNNSGraph symbols break. No `@available` guard on placeholder structs; package-level `[.macOS(.v15)]` is the only gate. Defer per-target floors and `@available` annotations to Story 4.5/4.6 when the actual conformance shape is known. Source: Edge Case Hunter §2/§6.

### Dismissed (handled by AC/DD or noise)

- DD #2 explicit: `.copy("Resources")` ships `.gitkeep` into the bundle — accepted trade-off (Blind Hunter B1, Edge Case Hunter E9/E15, Acceptance Auditor A5).
- DD #2/#5 explicit: compiled `.mlmodelc` lives in `Sources/BoomBoomBoomKitML/Resources/` — by design (Blind Hunter B2).
- DD #8 explicit: placeholder files import `Accelerate`/`CoreML` to verify build-graph wiring (Blind Hunter B12).
- DD #9 explicit: empty `public struct` with `Sendable` and `public init()` is the chosen surface (Blind Hunter B7).
- AC #1 explicit: test targets do NOT depend on `BoomBoomBoomKitML` in this story (Blind Hunter B13).
- AC #2 explicit: file-header `// BoomBoomBoomKit` is the umbrella product name, not the target — matches `MetadataPolicy.swift` precedent (Blind Hunter B9).
- AC #6 establishes artifact pattern (boundary-proof text file), not a regression test (Edge Case Hunter E11).
- Task 5.4 / story-in-review: `.gitkeep` not yet `git ls-files`-tracked — committed at PR time (Acceptance Auditor A1).
- Task 6.7 verified: `.copy("Resources")` with hidden-only contents builds clean (Blind Hunter B3).
- Speculative future regressions (empty `resources:` array silently breaks `Bundle.module`; concurrent compile races; symlink follows): Edge Case Hunter E6/E7/E10/E23.
- Story 5.5 territory: README / DocC catalog updates (Edge Case Hunter E18).
- Cosmetic: `ls` ordering in boundary-proof artifact (Acceptance Auditor A4); `.copy` subdirectory layout vs TestSupport precedent (Edge Case Hunter E13).
- Out-of-scope: Linux compilation of `Accelerate`/`CoreML` (package targets macOS only — Edge Case Hunter E19/E20/E21).

