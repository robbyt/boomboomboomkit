---
baseline_commit: eca19a32a541eab2b26c4258651909a76215ab8b
---

# Story 9.1: EnsemblePresetPicker in primary view with persistence

Status: done

## Story

As a developer evaluating BoomBoomBoomKit,
I want the demo's primary view to offer four named ensemble presets (`Default`, `DSP only`, `ML augmented`, `Trust file tags`) mapped to the `EnsemblePolicy` facade from Story 6.5,
so that I can drop an audio file, pick a named preset, and see the unified-signal-pool ensemble pick a BPM without ever touching raw per-source weights or policy enums.

## Context & why this story exists

First story of Epic 9 (demo shell + ensemble picker — FR-36, KDD-D1). Epic 9 depends only on Epic 6, which closed 2026-05-30; the epics.md gate ("Story 6.5 closed on develop before this story's first PR") is satisfied. Epic 8 landed on develop as `eca19a3`, so the demo already carries the beat-grid overlay and the Epic 7 BYOW ML controls — this story must integrate with both, and one integration point (the BYOW `.mlOnly` override) is a genuine design decision, resolved in DD3 below.

This is a **demo-only story**: `git diff --stat Sources/ Tests/` must be empty at close-out. The library's `EnsemblePolicy` surface is consumed, never modified.

## Key Design Decisions (DD)

1. **DD1 — Demo-side `EnsemblePreset` enum is the persisted identity, not `EnsemblePolicy`.** `EnsemblePolicy` is not `RawRepresentable`/`Codable` (the `.weightedVoting(SignalWeights)` case carries an associated value), and its `stableKey` returns the bare string `"weightedVoting"` for BOTH weight-bearing presets (`Sources/BoomBoomBoomKit/EnsemblePolicy.swift:137-143`) — it cannot distinguish `ML augmented` from `Trust file tags`. The AC's "persistence is encoded by case identifier (not raw `SignalWeights` floats)" therefore means a **new demo-side enum**: `EnsemblePreset: String, CaseIterable, Sendable` with cases `.default = "default"`, `.dspOnly = "dspOnly"`, `.mlAugmented = "mlAugmented"`, `.trustFileTags = "trustFileTags"`, declared in the new `EnsemblePresetPicker.swift`, plus a computed `var policy: EnsemblePolicy` carrying the KDD-D1 literals verbatim.

2. **DD2 — Persistence extends the existing `AnalysisViewModel.Configuration` mechanism; no new persistence type, no `@AppStorage`.** The Story 5-6 precedent (PR #16) is NOT a standalone `MergeStrategyPersistence` type — that name exists only as the test file. The mechanism lives inside `AnalysisViewModel`: injectable `Configuration { defaults, fallbackStrategy }` (`AnalysisViewModel.swift:20-28`), static key (`:30`), three-branch hydrate in `init` (absent → fallback; valid → hydrate; unrecognized → **self-heal**: remove key + fallback) (`:51-69`), and a `persist...()` method called from ContentView's `.onChange` (`:75-80`). This story adds `preferredEnsemblePresetKey = "preferredEnsemblePreset"`, a `fallbackPreset: EnsemblePreset` Configuration field **with a default value of `.default`** (the struct's memberwise init has 7 existing construction sites — 5 in `MergeStrategyPersistenceTests` at `:27/:51/:76/:91/:115`, the smoke-test helper at `:615`, and `.live` at `:24`; a defaulted parameter keeps them all compiling), the same three-branch hydrate, and `persistPreferredEnsemblePreset()`. The Configuration doc comment already promises "future prefs knobs land in the same place" — this is that seam being used as designed. `@AppStorage` stays banned per the PR #16 spec ("second source of truth racing `@Observable` init").

3. **DD3 — The preset picker becomes the single writer of `Options.ensemblePolicy`; the BYOW `.mlOnly` hard override is removed.** Today `analyze()` writes `opts.ensemblePolicy = .mlOnly` whenever `mlEnabled && mlTechnique != nil` (`AnalysisViewModel.swift:364-368`). Left in place, that silently clobbers the preset and violates AC3 ("Options.ensemblePolicy byte-equals the picker's resolved EnsemblePolicy") whenever the toggle is on. Resolution: `analyze()` always sets `opts.ensemblePolicy = selectedEnsemblePreset.policy`; the ML block shrinks to `opts.mlTechnique = technique` + `opts.enableMLDiagnostics = true` (attach the model; let the preset's policy govern how it participates). The toggle relabels from `ML (.mlOnly)` to `Use loaded model`. **Toggle-off semantics, explicit:** ML participation requires BOTH a loaded model AND the toggle on (`mlEnabled && mlTechnique != nil` — unchanged gate); with the toggle off (or no model), `opts.mlTechnique` stays `nil` and ML is absent from the run, while the preset remains selected, persisted, and still governs `ensemblePolicy`. Consequences accepted: the forced-`.mlOnly` demo path is gone — an attached model participates per the active preset (weighted under `ML augmented`, short-circuited under `DSP only` — the `.dspOnly` operation-inert contract is test-locked in the library). Zero existing demo tests cover the old override (verified: no `mlEnabled`/`mlTechnique` references in `BoomBoomBoomBPMTests/`), so nothing breaks; this story adds the first coverage. **Testability seam:** `mlTechnique` is `private` (`AnalysisViewModel.swift:237`) and the only loader runs `NSOpenPanel` → `BNNSTechnique(modelURL:)` (`:696-728`) — untestable as-is. `pickAndLoadMLModel()` splits into panel presentation + an internal `attachMLTechnique(_ technique: any MLTechnique, named: String)` that is the **behavior-preserving extraction of the existing success block**: it sets the full quartet `mlTechnique` / `mlModelName` / `mlEnabled = true` / `mlModelError = nil` (the toggle's visibility is gated on `mlModelName != nil`, so a technique-only seam would strand the GUI path). The panel keeps the availability guard, `NSOpenPanel`, security scoping, `BNNSTechnique` construction, and the catch block. Tests drive the seam with a stub `MLTechnique` conformer (the protocol is public library surface; a two-line stub struct suffices) and flip `mlEnabled = false` themselves for the toggle-off variant. Alternatives rejected: (a) toggle-wins precedence — violates AC3 silently; (b) removing the toggle — loses the ability to detach a loaded model without relaunching.

4. **DD4 — First-launch fallback preset is `Default` (`EnsemblePolicy.default`), diverging deliberately from the library default (`.dspOnly`).** The demo's job (epics.md Epic 9 charter) is *proving the ensemble*; defaulting to the DSP-only short-circuit would demo nothing. Precedent: the demo already seeds `mergeStrategy = .quorum` against the library's `.maxConfidence`, with a doc comment fencing the divergence from leaking into the library (`AnalysisViewModel.swift:39-51` region). Mirror that comment for the preset. `AudioAnalysisService.Options.ensemblePolicy` stays `.dspOnly` (`AudioAnalysisService.swift:255`) — untouched. Golden-fixture impact: none expected — both `ensemblePolicy: "dspOnly"` occurrences in the smoke tests are hand-constructed literals in synthetic `TraceExport` values (`AnalysisViewModelSmokeTest.swift:1002`, `:1255`), not runtime captures; T6 verifies the golden test still passes untouched.

5. **DD5 — Selection state is `AnalysisViewModel.selectedEnsemblePreset`, and preset changes never touch `options.mergeStrategy`.** The picker binds to a new `var selectedEnsemblePreset: EnsemblePreset` on the view model — a **stored, observed property (NOT `@ObservationIgnored`**; the adjacent `configuration` property IS ignored, and copy-pasting that annotation would silently kill picker updates) — hydrated in `init` before first render, same no-flash rationale as the merge-strategy hydrate. ContentView wires `.onChange(of: viewModel.selectedEnsemblePreset)` → `persistPreferredEnsemblePreset()` + `triggerReanalyze()` — exactly one re-analyze per user selection. The pre-written warning at `ContentView.swift:283-286` (merge-strategy `.onChange` fires on programmatic writes; "a future preset feature could trigger unintended re-analyzes") is honored by construction: the preset path never writes `options.mergeStrategy`, so the merge-strategy `.onChange` cannot cascade.

6. **DD6 — Picker renders as four visible rows with subtitle captions; `.radioGroup` is the recommended style, not a contract.** The AC pins "four selectable rows" each showing a subtitle line beneath the name — a `.menu` picker (the merge-strategy precedent) cannot satisfy that. Recommended: `Picker(selection:)` + `.pickerStyle(.radioGroup)` with a two-line `VStack(alignment: .leading)` label per row (`Text(name)` + `Text(subtitle).font(.caption).foregroundStyle(.secondary)`). Apple's own guidance validates the style choice (radio groups for two-to-five options; macOS 10.15+). If radio-group label rendering proves unacceptable on macOS 15 (task T1 verifies visually), fall back to a hand-rolled selectable-row list that MUST preserve this contract: one bound selection driving `selectedEnsemblePreset`, four rows with stable per-case selection identity, a visible selected indicator, keyboard focusability/actuation, and a combined name+subtitle accessibility label per row. Either way, an automatable test asserts all four display names and all four subtitle strings exist verbatim; only final layout polish is manual-smoke territory. Subtitle strings are a **contract** (Sally #2, epics.md): the four lines ship verbatim, hard-coded, with the verbatim seam comment `// REPLACED BY Story 10.5: subtitle becomes a "?" popover wired to Epic 11 docs via BoomBoomBoomKitDocs.attributedString(for:id:)`.

7. **DD7 — `ML augmented` without an active model degrades honestly and visibly.** With `Options.mlTechnique == nil`, the library records ML as `SignalParticipation.absent` and DSP wins — the preset changes only the inert weights, i.e. effectively nothing. Accepted (Epic 10 wires the model registry), surfaced via caption rows in the existing `mlModelError` style. Condition source: `mlTechnique` is `private`, but `mlModelName: String?` is already the public observable ContentView uses to gate the toggle (`ContentView.swift:315`) — the caption keys off `selectedEnsemblePreset == .mlAugmented` combined with (a) `mlModelName == nil` → `No model loaded — ML signal is absent until you load one.`, or (b) `mlModelName != nil && !mlEnabled` → `Model loaded but "Use loaded model" is off — ML signal is absent.` The rows are informational; the preset stays selectable and persists (the choice is meaningful once a model is attached and enabled).

8. **DD8 — The `beatGrid: 1.0` weight in the KDD-D1 literals is a forward seam, not behavior.** `SignalSource.beatGrid` has no pool producer (deferred-work W53; Epic 8 shipped the beat grid as a sibling output, not a pool participant). The spec promises no beat-grid ensemble participation; the literal ships as written so the preset table matches KDD-D1 byte-for-byte.

## Acceptance Criteria

1. **New file builds.** Given a new file `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/EnsemblePresetPicker.swift`, when the demo target builds via `make demo-build`, then `EnsemblePresetPicker` is a SwiftUI `View` rendering exactly four selectable rows labeled verbatim `Default` / `DSP only` / `ML augmented` / `Trust file tags`, with no fifth raw-weights option in the primary view.

2. **KDD-D1 mapping locked by test.** When each preset is selected, the resolved `EnsemblePolicy` matches: `Default → .default`, `DSP only → .dspOnly`, `ML augmented → .weightedVoting(SignalWeights(dsp: 1.0, ml: 1.5, fileMetadata: 1.0, beatGrid: 1.0))`, `Trust file tags → .weightedVoting(SignalWeights(dsp: 1.0, ml: 1.0, fileMetadata: 2.0, beatGrid: 1.0))` — verified by `EnsemblePresetPickerTests.presetMappingMatchesKDDD1`. (Equality is well-defined: `EnsemblePolicy` is `Hashable`; `SignalWeights`' finite-normalizing init makes these literals deterministic. `.default` and `.weightedVoting(.default)` are behaviorally equivalent but NOT `==` — the mapping must use the exact cases above.)

3. **Preset drives the run.** When the user picks a preset and drops a file, the resulting `AudioAnalysisService.Options.ensemblePolicy` value equals the picker's resolved `EnsemblePolicy` (value-equality via `==`; the epics.md "byte-equals" phrasing means exactly this — `EnsemblePolicy` is `Hashable`) — **unconditionally**, including when a BYOW model is loaded and enabled (DD3). Verified via the per-run capture: `lastRunSnapshot.runOptions.ensemblePolicy == selectedEnsemblePreset.policy` (RunOptionsSnapshot stores the full `EnsemblePolicy`, `TraceExport.swift:30` — full-policy equality distinguishes the two `.weightedVoting` presets where `stableKey` cannot).

4. **Persistence round-trip by case identifier.** When the user selects `ML augmented`, quits, and relaunches, `ML augmented` is restored as the active preset. Persistence stores `EnsemblePreset.rawValue` under `preferredEnsemblePreset` (DD1/DD2) — never raw `SignalWeights` floats. Three hydrate branches are each test-covered: absent key → fallback (`.default`); valid stored value → hydrated; unrecognized stored value → self-heal (key removed + fallback), matching the merge-strategy precedent exactly.

5. **Primary-view anchoring (FR-43).** When the advanced sidebar (`.inspector(isPresented:)`) is closed, the preset picker remains visible and functional in the primary view — it is not gated behind `⌘⇧D`.

6. **Subtitles verbatim with the Story 10.5 seam.** Each preset row shows a single inline-authored subtitle beneath the name: `Default — balanced ensemble`, `DSP only — disables ML, fastest`, `ML augmented — adds the trained classifier`, `Trust file tags — prefer ID3/MP4/Vorbis tempo tags`. The text is hard-coded in `EnsemblePresetPicker.swift` and marked with the verbatim comment `// REPLACED BY Story 10.5: subtitle becomes a "?" popover wired to Epic 11 docs via BoomBoomBoomKitDocs.attributedString(for:id:)`. No docs bundle, no `Bundle.module`, no docs accessor.

7. **Dependency gate.** Story 6.5 is closed on develop (satisfied — Epic 6 closed 2026-05-30; verified in sprint-status.yaml).

8. **BYOW reconciliation (DD3).** With a model loaded and `Use loaded model` on, `analyze()` no longer forces `.mlOnly`: the effective policy is the preset's. A new test locks the precedence (preset wins; `opts.mlTechnique` set; `enableMLDiagnostics` set). The toggle label no longer claims `.mlOnly`.

9. **Demo-only diff scope.** `git diff --stat Sources/ Tests/` is empty; `make build` + `make test` pass unchanged; the golden trace-export fixture is untouched and its test passes (DD4).

## Out of scope (explicit)

- Signal-pool diagnostic table (Story 9.2) and the `EnsembleDecision` summary-view replacement it owns.
- Primary-flow audit / confidence-label CI gate (Story 9.3).
- "?" popovers, docs bundle, `BoomBoomBoomKitDocs` accessor (Story 10.5; the subtitle is the seam).
- Model registry / model picker / bookmark persistence (Epic 10; the existing `Load Model…` button stays as-is).
- Raw per-source weight controls anywhere (sidebar raw-weights UI is Epic 9/10 sidebar territory, and a fifth picker row is explicitly forbidden by AC1).
- Any library change (`Sources/`, `Tests/`), including the stale Story-4.4-era `Options.ensemblePolicy` doc comment (`AudioAnalysisService.swift:233-254`) — noted for a future library hygiene pass, not this story.
- Localization, and any NEW accessibility conventions beyond the demo's existing 5-6b quality bar (no NFRs exist in PRD/architecture for the demo). New controls still carry labels at the existing standard — that is T1's accessibility subtask, not a new NFR.

## Tasks / Subtasks

- [x] **T1 — `EnsemblePresetPicker.swift` (new file)** (AC1, AC2, AC6)
  - [x] `EnsemblePreset: String, CaseIterable, Sendable` enum — 4 cases with rawValues per DD1, display names, subtitle strings, and `var policy: EnsemblePolicy` with the KDD-D1 literals.
  - [x] `EnsemblePresetPicker: View` — binds `selection: Binding<EnsemblePreset>`, renders 4 rows (name + caption subtitle) per DD6; verify radio-group label rendering visually, fall back per DD6 if broken.
  - [x] Verbatim `// REPLACED BY Story 10.5:` seam comment on the subtitle definitions (AC6).
  - [x] Accessibility: each row exposes name + subtitle to VoiceOver (existing 5-6b label patterns; no new conventions).
  - [x] New file lands under the app target automatically (pbxproj uses `PBXFileSystemSynchronizedRootGroup`, objectVersion 77 — no pbxproj edit; verify target membership via `make demo-build`).
- [x] **T2 — `AnalysisViewModel` persistence + state** (AC3, AC4)
  - [x] `static let preferredEnsemblePresetKey = "preferredEnsemblePreset"`.
  - [x] `Configuration.fallbackPreset: EnsemblePreset = .default` (defaulted — keeps the 6 existing memberwise-init sites compiling; update `.live`).
  - [x] `var selectedEnsemblePreset: EnsemblePreset` hydrated in `init` via the three-branch pattern (absent/valid/unrecognized-self-heal), mirroring `:51-69`.
  - [x] `persistPreferredEnsemblePreset()` mirroring `:75-80`.
  - [x] Demo-vs-library divergence doc comment per DD4 (mirror the `.quorum` fence comment).
- [x] **T3 — `analyze()` rewiring + testability seam** (AC3, AC8)
  - [x] `opts.ensemblePolicy = selectedEnsemblePreset.policy` in the options prologue (after the `var opts = options` snapshot at `:348`, alongside the existing demo overrides).
  - [x] Remove `opts.ensemblePolicy = .mlOnly` from the BYOW block (`:364-368`); keep `opts.mlTechnique = technique` + `opts.enableMLDiagnostics = true` gated on `mlEnabled` exactly as today; update the block's Epic 7 comment to describe preset-governed participation and explicit toggle-off absence (DD3).
  - [x] Split `pickAndLoadMLModel()`: panel presentation calls a new internal `attachMLTechnique(_ technique: any MLTechnique, named: String)` (DD3 seam) — behavior-preserving for the GUI path.
  - [x] Sweep ALL stale `.mlOnly` prose: the BYOW state comments at `AnalysisViewModel.swift:213` and `:224`, and the ContentView BYOW comment at `:303` — no false documentation left behind.
- [x] **T4 — ContentView integration** (AC1, AC5, AC8)
  - [x] `EnsemblePresetPicker(selection: $viewModel.selectedEnsemblePreset)` in its **own `GroupBox("Ensemble")` directly ABOVE the `GroupBox("Parameters")`** in `controlsSection` (primary view; functional with the inspector closed). The ensemble choice is the demo's headline consumer control, not a ninth parameter knob — grouping semantics, not art direction; Story 9.3's layout audit inherits this structure.
  - [x] `.onChange(of: viewModel.selectedEnsemblePreset)` → `viewModel.persistPreferredEnsemblePreset()` + `triggerReanalyze()` (DD5).
  - [x] Relabel the ML toggle `ML (.mlOnly)` → `Use loaded model` (DD3).
  - [x] DD7 caption rows keyed off `mlModelName`/`mlEnabled` (both already public observables): no-model and loaded-but-disabled variants.
  - [x] Extend `copyConfigToPasteboard` (`AnalysisViewModel.swift:644` region) with the active preset line — the copied config would otherwise omit the new primary parameter and mislead.
- [x] **T5 — Tests (`BoomBoomBoomBPMTests`, Swift Testing)** (AC2, AC3, AC4, AC8)
  - [x] New `EnsemblePresetPickerTests.swift`: `presetMappingMatchesKDDD1` (all four exact `EnsemblePolicy` values, incl. the NOT-`.weightedVoting(.default)` distinction for `Default`).
  - [x] Verbatim-content assertion: all four display names + all four subtitle strings (DD6's automatable check).
  - [x] Persistence: round-trip, absent-key fallback (asserts `.default` restored — DD4), self-heal-on-unrecognized (isolated `UserDefaults(suiteName:)` + `removePersistentDomain`; `try #require` the suite — never force-unwrap, per PR #16 Copilot finding 2).
  - [x] Dual-preference isolation: persisting the preset neither overwrites nor self-heals `preferredMergeStrategy`, and vice versa (both live in the same injected suite).
  - [x] Per-run propagation: run a real analysis per the established pattern — `analyze(url:)` on `bpm-120-click.wav` + poll `isAnalyzing` with the 30 s ceiling (`AnalysisViewModelSmokeTest.swift:12-38` is the template); assert **full-policy equality** `lastRunSnapshot.runOptions.ensemblePolicy == selectedEnsemblePreset.policy` for BOTH `.weightedVoting` presets (stableKey cannot distinguish them — it is asserted only in the trace-export JSON test). Runtime budget: these plus the precedence variants add ~4 real DSP runs (~10 s) to `make demo-test` — record the new invocation count in Completion Notes.
  - [x] No-cascade: setting `selectedEnsemblePreset` does not mutate `options.mergeStrategy` (locks DD5's one-re-analyze promise at the state level).
  - [x] DD3 precedence: attach a stub `MLTechnique` conformer via the T3 seam, set `mlEnabled = true`, run; effective policy == preset policy (not `.mlOnly`), `opts.mlTechnique` non-nil. Toggle-off variant: technique attached, `mlEnabled = false` → `mlTechnique` absent from the run.
- [x] **T6 — Gauntlet + close-out** (AC9)
  - [x] `make demo-fmt`, `make demo-lint`, `make demo-build`, `make demo-test`, `make pre-commit` — record counts in Completion Notes.
  - [x] `make build` + `make test` (library untouched); `git diff --stat Sources/ Tests/` empty.
  - [x] Golden trace-export test passes with fixture untouched (DD4 verification); grep the demo test target for stale runtime `.dspOnly` expectations now that first-launch runs resolve `.default` (hand-built literals stay).
  - [x] Diff hygiene: the untracked `_bmad-output/implementation-artifacts/14-1-daw-warp-anchors.generated.json` (its `.gitignore` fence lives only on the epic-14 branch) must NOT enter this story's commits — stage paths explicitly, never `git add -A`.
  - [x] Story file Dev Agent Record + File List; sprint-status stays `in-progress` → flip per review flow.

## Dev Notes

### Architecture & source tree (touch points, verified 2026-07-02 against the post-`eca19a3` develop tree)

- **NEW** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/EnsemblePresetPicker.swift` — view + `EnsemblePreset` enum (DD1/DD6).
- **UPDATE** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift` (904 lines) — `Configuration` (`:20-28`), key (`:30`), `init` hydrate (`:51-69`), persist (`:75-80`), BYOW state comments (`:213`, `:224`), `analyze()` prologue (`:348`) + BYOW block (`:364-368`), `copyConfigToPasteboard` (`:644` region), `pickAndLoadMLModel` seam split (`:696-721`).
- **UPDATE** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift` (506 lines) — `controlsSection` (`:227-370`); merge-strategy `.onChange` warning comment at `:283-286`; ML toggle block (`:307-336`).
- **NEW** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/EnsemblePresetPickerTests.swift`; **UPDATE** `AnalysisViewModelSmokeTest.swift` only if the shared VM-construction helper (`:611-620`) needs the defaulted Configuration field surfaced.
- **NO CHANGE**: `TraceExport.swift` (already exports `runOptions.ensemblePolicy.stableKey` at `:250`); golden fixture; anything under `Sources/` or `Tests/`.

### Library surface consumed (read-only; verified declarations)

- `EnsemblePolicy: Sendable, Hashable`, 5 cases, `stableKey`, `allPolicies` — `Sources/BoomBoomBoomKit/EnsemblePolicy.swift:66-152`. Case-count invariant (5, ordered) is test-locked in `MetadataCorroborationTests.ensemblePolicyCases` — do not duplicate; reuse the order if asserting on `allPolicies`.
- `SignalWeights(dsp:ml:fileMetadata:beatGrid:)`, all params defaulted `1.0`, finite-normalizing (`SignalPool/SignalWeights.swift:41-51`).
- `Options.ensemblePolicy: EnsemblePolicy = .dspOnly` (`AudioAnalysisService.swift:255`). Its doc comment (`:233-254`) is stale Story-4.4 text — do NOT cite it; the `EnsemblePolicy` case doc comments are current.
- With `mlTechnique == nil`: ML records as `SignalParticipation.absent` under every policy; `.weightedVoting(fileMetadata: 2.0)` still scales Phase-2a metadata corroboration (boost ×1.5-equivalent, penalty →0.7, confidence ceiling 0.95 stands) — i.e. `Trust file tags` has real effect without ML; `ML augmented` without a model differs from `Default` only in inert weights.

### Reuse-first inventory

- Three-branch hydrate + self-heal + injectable-suite testing: copy the shapes from `AnalysisViewModel.swift:51-80` and `MergeStrategyPersistenceTests.swift` (126 lines) — do not invent a parallel mechanism.
- Caption-row styling for the DD7 notice: the `mlModelError` red-caption / `Model:` secondary-caption rows (`ContentView.swift:323-336`).
- Re-analyze debounce entry point: `triggerReanalyze()` (`ContentView.swift:200-203`).
- Humanized-label precedent (W28) exists for enum rawValues, but preset display names are hard-coded verbatim per AC — `humanize` is not involved.

### Constraints (project-context.md / CLAUDE.md)

- Demo stays on develop; ships via `make demo-archive` only. Nothing from this story lands on main.
- Swift Testing (`@Suite`/`@Test`/`#expect`/`#require`) in the demo test target; 2-space indent; `make demo-fmt` before `demo-lint`.
- No `@AppStorage`; no new persistence types; UserDefaults via injectable Configuration only (DD2).
- No emojis anywhere; commit message `Story 9-1: <deliverable>` with no review-process references.
- Options-first discipline applies to the library only — untouched here.

### Previous Story Intelligence (PSI)

- **PR #16 (merge-strategy persistence)**: three review findings to not repeat — (1) self-heal IS a UserDefaults write (don't claim write-free behavior in comments); (2) never force-unwrap `UserDefaults(suiteName:)` in tests (`try #require`); (3) after any spec-review policy flip, grep Verification sections for stale expectations of the old policy (project-context.md:159).
- **Story 5-6 / 5-6b**: inspector column width must stay applied INSIDE the inspector closure; `InspectorCommands()` single wire preserved; `.onChange` fires on programmatic writes (the `:283-286` warning was written for this story).
- **Epic 8 retro**: factual-claims grep caught drift in 6 of 8 stories — every path/line cited here was re-verified on 2026-07-02 against the current tree.
- **Epic 7 BYOW**: the `Load Model…`/toggle path shipped test-free; DD3's rewiring adds its first coverage rather than breaking any.

### Testing standards

- `make demo-test` drives the app scheme + `BoomBoomBoomBPM.xctestplan`; new test files under `BoomBoomBoomBPMTests/` auto-join the target (synchronized folders) — verify discovery by name in the run log.
- Isolated `UserDefaults(suiteName: "com.robbyt.BoomBoomBoomBPMTests.<testName>")` + `removePersistentDomain` in setup/teardown, per `MergeStrategyPersistenceTests` precedent.
- Record exact test counts before/after in Completion Notes (demo-test invocation count precedent from Story 5-6: 78).

### References

- epics.md `### Story 9.1` (lines 1238-1276) — ACs, subtitle contract, KDD-D1 mapping.
- architecture.md KDD-D1 (`:551`), KDD-D3 (`:553`, bookmark-scoped — Epic 10, cited here only as the UserDefaults-family precedent), KDD-A5 (`:432` preset-to-policy table).
- prd.md FR-36 + preset naming rationale (`:175`).
- `_bmad-output/implementation-artifacts/spec-persist-merge-strategy-preference.md` — the persistence precedent spec.
- deferred-work: W53 (beatGrid producer absent — DD8), W28 (humanized labels).
- API availability validated against Apple docs 2026-07-02: `.pickerStyle(.radioGroup)` is macOS 10.15+ and Apple's guidance recommends radio groups for **two to five options** (four fits) with sentence-style labels without ending punctuation (all four preset names comply) — this validates DD6's recommendation; `.inspector(isPresented:content:)` is macOS 14.0+ (app deploys 15.6); `UserDefaults.removePersistentDomain(forName:)` throws if passed the argument/registration domain identifiers — tests must use custom suite names only (they do).

## Dev Agent Record

### Agent Model Used

Claude Fable 5 (claude-fable-5), 2026-07-02 session, auto-mode single-shot implementation.

### Debug Log References

- Compile red #1: `EnsemblePreset.policy`/`displayName`/`subtitle` are implicitly `@MainActor` (the demo app target builds with MainActor default isolation) — the two pure-value tests needed the same `@MainActor` annotation every other test in the target carries.
- Compile red #2: a fourth `generateConfigSnippet` call site at `AnalysisViewModelSmokeTest.swift:587` (pasteboard round-trip test) — it constructs the `.live` configuration, so the preset had to be pinned explicitly (`.dspOnly`) to keep the test invariant to operator prefs.
- Test red #3: `attachedModelDoesNotForceMLOnly` asserted `trace.ensembleDecision != nil`, but the KDD-A5 weighted policies emit `EnsembleWeightResolution`, NOT `EnsembleDecision` (that record belongs to `.mlOnly`/`.highestConfidence` — `AudioAnalysisService.combineEnsemble:816-825`). Reworked both precedence tests to assert on `ensembleWeightResolution.mlEffectiveVote` (non-nil = ML voice participated; nil = absent).

### Completion Notes List

- All 6 tasks + 31 subtasks complete; all 9 ACs satisfied.
- `EnsemblePreset` enum + `EnsemblePresetPicker` view (radioGroup, four rows with caption subtitles, verbatim Story 10.5 seam comment) in the new `EnsemblePresetPicker.swift`; auto-joined the app target via synchronized folders (no pbxproj edit, verified by `make demo-build`).
- Persistence: `preferredEnsemblePreset` key + `Configuration.fallbackPreset` (defaulted `var` — all 7 pre-existing construction sites compile unmodified) + three-branch hydrate + `persistPreferredEnsemblePreset()`, exact mirror of the merge-strategy mechanism.
- DD3 landed: `analyze()` sets `opts.ensemblePolicy = selectedEnsemblePreset.policy` unconditionally; the BYOW `.mlOnly` override is gone; `attachMLTechnique(_:named:)` extracted as the behavior-preserving success-quartet seam; toggle relabeled `Use loaded model`; stale `.mlOnly` prose swept from both files (repo-wide grep clean).
- `ensembleSection` GroupBox above Parameters (party-mode amendment); DD7 caption rows (no-model + loaded-but-disabled) keyed off public observables.
- Copy Config snippet grew to 5 lines with the preset's copy-pasteable policy literal; shape test updated 4→5, new 4-preset formatting test.
- Gauntlet (post-review-patch): `make demo-fmt` clean; `make demo-lint` exit 0; `make demo-build` BUILD SUCCEEDED; `make demo-test` TEST SUCCEEDED — **124 test-case invocations, 0 failures** (+23 from this story: 19 in `EnsemblePresetPickerTests`, 4 preset-snippet invocations in the smoke suite; the pre-review count claim of "+20/16" was off by one — corrected per review finding, and the review patches added 4 drift-lock invocations); `make pre-commit` exit 0 (1 lint violation = the canonical `LUFSAnalyzer.swift:94` TODO baseline); `make build` 0.16 s; `make test` **842 tests / 138 suites passed**; `git diff --stat Sources/ Tests/` **empty** (AC9); golden trace-export fixture untouched and its test green (DD4 confirmed — both `dspOnly` literals are hand-built); stale runtime-`.dspOnly` grep clean.
- The 14-1 generated warp-anchors file was kept out of the staged set (T6 diff hygiene).

### Pending user action (operator-owned)

- Manual GUI smoke: preset selection persists across quit/relaunch (`defaults read com.robbyt.BoomBoomBoomBPM preferredEnsemblePreset`); four rows render with subtitles at 1280×800 and 2560×1600; no-model caption appears/disappears with `ML augmented`.
- Final commit on the 1Password signer.

### File List

- NEW `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/EnsemblePresetPicker.swift` — `EnsemblePreset` enum (rawValue persistence identity, KDD-D1 `policy` mapping, `policyLiteral`, verbatim subtitles + Story 10.5 seam comment) + `EnsemblePresetPicker` radio-group view.
- MODIFIED `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift` — `Configuration.fallbackPreset`, `preferredEnsemblePresetKey`, preset hydrate in `init`, `persistPreferredEnsemblePreset()`, `selectedEnsemblePreset` observed property, `analyze()` preset-derived policy + `.mlOnly` override removal, `attachMLTechnique(_:named:)` seam, `generateConfigSnippet` 5-line shape, BYOW comment sweep.
- MODIFIED `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift` — `ensembleSection` GroupBox above Parameters with picker `.onChange` (persist + re-analyze) + DD7 caption rows; ML toggle relabel `Use loaded model`; BYOW comment sweep.
- NEW `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/EnsemblePresetPickerTests.swift` — 16 test invocations: KDD-D1 mapping, verbatim row content, 3-branch persistence + round-trip, dual-preference isolation, no-cascade, per-run full-policy propagation (both weightedVoting presets, real fixture runs), DD3 precedence + toggle-off (stub `MLTechnique`).
- MODIFIED `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/AnalysisViewModelSmokeTest.swift` — 4 `generateConfigSnippet` call sites take `ensemblePreset:`; shape test 4→5 lines; new 4-preset policy-literal formatting test; pasteboard test pins the preset explicitly.
- MODIFIED `_bmad-output/implementation-artifacts/sprint-status.yaml` — status flips (epic-9 in-progress; 9-1 backlog → ready-for-dev → in-progress → review).
- MODIFIED `_bmad-output/implementation-artifacts/9-1-ensemblepresetpicker-in-primary-view-with-persistence.md` — this file (frontmatter, checkboxes, record, status).

## Review Findings (code review 2026-07-02 — 3-layer: Codex Blind Hunter, Edge Case Hunter, Acceptance Auditor)

21 raw findings (9 blind + 5 edge + 7 auditor) → 6 patches applied, 1 recorded decision, 4 deferred, 10 dismissed with evidence.

### Recorded decision (operator sign-off at PR)

- **D1 (auditor #2) — Subtitle renders the post-em-dash fragment, not the full AC contract string.** The AC lists rows as `Default — balanced ensemble`; the implementation renders `Default` as the title and `balanced ensemble` as the caption beneath (rendering the full string under the title would duplicate the name). The contract TEXT is locked verbatim by `verbatimNamesAndSubtitles` (names and subtitles asserted independently, plus the reconstructed contract strings). Recorded here as an explicit interpretation rather than a silent one — flag at PR review if the literal duplicated-name rendering was intended.

### Patches (applied in this round, all green at 124/124)

- **P1 (auditor #1)** — Story 10.5 seam comment collapsed to a single line so the verbatim grep finds it (`line_length` is lint-disabled).
- **P2 (auditor #3)** — `attachedModelDoesNotForceMLOnly` now asserts `runOptions.enableMLDiagnostics == true`; `toggleOffKeepsMLAbsent` asserts the negative.
- **P3 (edge #5)** — new `policyLiteralMirrorsPolicy` drift-lock test (×4): the hand-mirrored `policyLiteral` string is derived-asserted from the resolved `policy` weights, so a weight edit without the literal edit fails the suite.
- **P4 (edge #3)** — third honesty caption: `DSP only` with a loaded+enabled model now shows `DSP only ignores the loaded model — ML signal is absent.` (mirrors DD7's rule for the inverse trap).
- **P5 (blind #5)** — `hydrateAbsentKey` pre-cleans its UserDefaults suite before construction (a crashed prior run could poison the absent-key premise).
- **P6 (auditor #6)** — verbatim test asserts display names and subtitles independently (degenerate mis-split can no longer pass), plus the Completion Notes test-count correction (auditor #5).

### Deferred (recorded, not this story)

- **W (edge #1)** — a non-string value stored under either preference key takes the absent branch and never self-heals; pattern-level (identical exposure in the merge-strategy hydrate) — fix both keys together or not at all.
- **W (edge #4)** — Copy Config snippet for ML-invoking presets omits an `opts.mlTechnique` attach hint; revisit when Epic 10 rebuilds model UX.
- **W (blind #9)** — `.radioGroup` complex-label accessibility/hit-target behavior: already covered by the operator-owned GUI smoke in Pending user action.
- **W (auditor #4)** — `opts.mlTechnique != nil` is proven behaviorally (`mlEffectiveVote != nil`), not asserted directly (`RunOptionsSnapshot` carries no technique field); comment records the inference.

### Dismissed (with evidence)

- **Blind #1 (HIGH, mid-run preset change)** — false premise: the preset read happens in `analyze()`'s synchronous `@MainActor` prologue (same turn as the user action); no async boundary precedes it.
- **Blind #2 (HIGH, overlapping analyses)** — false premise: the prologue cancels every prior in-flight task and gates stale writes by UUID (Story 5-2/5-3 machinery; same claim was refuted in the Story 5-3 review).
- **Blind #3 (programmatic writes trigger `.onChange`)** — parity with the accepted merge-strategy pattern; hydration runs in `init` before any view exists.
- **Blind #4 (actor-unconstrained seam)** — false premise: `AnalysisViewModel` is `@MainActor` (`AnalysisViewModel.swift:9`).
- **Blind #6 (poll misses `isAnalyzing`)** — false premise: `isAnalyzing = true` is set synchronously in the prologue before `analyze()` returns.
- **Blind #7 (vacuous negative ML assertion)** — mitigated by the paired positive test on the same fixture/preset; comment added (P2 round).
- **Blind #8 (snippet scope)** — `SignalWeights` lives in the same module every other snippet line already requires.
- **Edge #2 (downgrade erases newer preset)** — self-heal-on-unrecognized is the deliberate, documented pre-1.0 policy (merge-strategy precedent).
- **Auditor AC6 wrap + count** — resolved by P1/P6.
- **Auditor #7 (commit hygiene)** — enforced at staging: explicit paths only; `14-1-daw-warp-anchors.generated.json` and `_bmad-output/party-mode/` stay out of this story's commit.

## Change Log

- 2026-07-02: Story spec created (bmad-create-story). Grounded by a 4-agent parallel forensic pass (demo app current state, library ensemble surface, prior-story intelligence, architecture/PRD) with every cited path/type/line re-verified against the post-`eca19a3` develop tree.
- 2026-07-02: Pre-implementation Codex review round 1 (thread `019f2530-04e9-7d23-aaf4-0078e13a509f`) — 4 MUST-FIX + 5 SHOULD-FIX + 3 CONSIDER applied: per-run propagation asserts full `EnsemblePolicy ==` (stableKey collapses the weightedVoting presets); DD7 caption re-keyed to the public `mlModelName`/`mlEnabled` observables (`mlTechnique` is private) with a loaded-but-disabled variant; DD3 gains explicit toggle-off semantics + an internal `attachMLTechnique` testability seam (the NSOpenPanel-only loader was untestable); stale `.mlOnly` comment sweep added to T3; DD6 fallback contract pinned (selection binding, stable identity, visible indicator, keyboard, a11y label) + verbatim-content test; dual-preference isolation and no-cascade tests added to T5; Copy Config gains the preset line; first-launch-fallback assertion + stale-`.dspOnly` grep added; AC3 "byte-equals" clarified to value-equality via `==`. API availability validated (radioGroup macOS 10.15+/2-5-option guidance; inspector macOS 14+; removePersistentDomain constraints).
- 2026-07-02: Code review complete (3-layer: Codex Blind Hunter thread `019f2550-64a6-7bb3-bdf6-807b5cd2d635`, Edge Case Hunter, Acceptance Auditor). 21 raw → 6 patches (seam-comment single-line, enableMLDiagnostics assertions, policyLiteral drift-lock ×4, DSP-only-ignores-model caption, absent-key pre-clean, independent name/subtitle assertions) + 1 recorded decision (subtitle-fragment rendering, D1) + 4 defers + 10 dismissals with evidence. Post-patch: demo-test 124/124, pre-commit clean. Status review → done.
- 2026-07-02: Implementation complete (bmad-dev-story, auto-mode single-shot; status ready-for-dev → in-progress → review). 2 NEW + 3 MODIFIED Swift files in Demo/; +20 test invocations (demo-test 120 total, 0 failures); library untouched (`git diff Sources/ Tests/` empty; 842 library tests green). Three implementation reds hit and resolved — MainActor default isolation on the enum, a fourth snippet call site, and the weighted-policy trace record being `EnsembleWeightResolution` (not `EnsembleDecision`) — details in Debug Log References.
- 2026-07-02: Party-mode review round (Mary, Paige, John, Sally, Winston, Amelia, Gloria) — 5 amendments: picker moved to its own `GroupBox("Ensemble")` above Parameters (Sally — headline control, not a ninth knob; Winston — GroupBoxes accrete, cheap insurance); `attachMLTechnique` seam pinned as the behavior-preserving extraction of the full success quartet incl. `mlEnabled = true` (Amelia — a technique-only seam strands the toggle's `mlModelName` gate); `selectedEnsemblePreset` explicitly NOT `@ObservationIgnored` (copy-paste trap from the adjacent `configuration`); Configuration call-site count corrected 6 → 7 (Mary); real-run test pattern citation (`AnalysisViewModelSmokeTest.swift:12-38`) + ~10 s demo-test runtime budget noted; epic-14's unfenced generated warp-anchors file barred from this story's commits (Gloria).
