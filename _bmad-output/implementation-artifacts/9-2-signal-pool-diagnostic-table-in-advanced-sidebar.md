---
baseline_commit: 5dcae9fe6edfe1a3014740b55a8561c941fb5a13
---

# Story 9.2: Signal-pool diagnostic table in advanced sidebar

Status: done

## Story

As a developer auditing why the ensemble picked a particular BPM,
I want the advanced sidebar to render a sortable `SwiftUI.Table` of every contributing signal — source, BPM, confidence, weight, contribution, cluster — with the winning cluster visually emphasized and rejected candidates grouped separately,
so that I can audit the ensemble's decision post-analysis without re-running with `enableTrace: true` and cross-referencing trace dumps by hand.

## Context & why this story exists

Second story of Epic 9 (demo shell + ensemble picker — FR-41, KDD-D5). Epic 9 depends only on Epic 6, which closed 2026-05-30; both AC7 gates (Story 6.1 shipped `BPMDiagnosticTrace.signalParticipationTrace`; Story 6.5 shipped the `EnsemblePolicy` facade) are closed on develop.

**Landing note:** Story 9.1 was accidentally squash-landed to develop as `5dcae9f "Land epic 9 (#87)"` (operator mistook it for epic-8), and the operator chose to leave it landed rather than roll develop back. This story therefore branches off the post-9.1 develop on a fresh `rterhaar/epic-9`, and epic-9 will land a **second** squash (9.2 + 9.3). 9.1's demo-side machinery — `EnsemblePresetPicker`, the `selectedEnsemblePreset` single-writer of `Options.ensemblePolicy`, the always-on `opts.enableTrace = true` — is already on develop and this story builds directly on it.

This is a **demo-only story**: `git diff --stat Sources/ Tests/` must be empty at close-out. Every type the table reads (`BPMDiagnosticTrace.signalParticipationTrace`, `SignalParticipationTraceEntry`, `SignalParticipation`, `WeightedSignal`, `SignalSource`, `EnsembleWeightResolution`) is already public library surface (Story 6.1 / 6.5b) — consumed, never modified. **No library change, no live/incremental updates** (FR-41 explicitly defers per-window emission to a future epic).

## Key Design Decisions (DD)

1. **DD1 — New `SignalPoolDiagnosticTable.swift` owns the `Table` + row model + a PURE derivation; `TraceView` embeds it as a bounded-height section.** AC1 mandates a new file exposing `SignalPoolDiagnosticTable` (a `View` wrapping `Table(of: SignalPoolDiagnosticRow.self, sortOrder: $sortOrder)`). The advanced sidebar's content today is `TraceView` (`TraceView.swift:20-37`, a `ScrollView` → `VStack` of `GroupBox` sections). So the new view is embedded as a new `GroupBox` section inside `TraceView.body`. The new file also declares `struct SignalPoolDiagnosticRow: Identifiable` and a **pure `static func rows(from entries: [SignalParticipationTraceEntry], selectedBPM: Double, winner: EnsembleWeightResolution.Winner?) -> [SignalPoolDiagnosticRow]`** — this is where all flatten/derive logic lives, so it is unit-testable without a real run (the `BeatGridLogicTests` pure-static-helper precedent, `BeatGridLogicTests.swift`). The `View` is a thin renderer over the derived rows. **The derivation namespace MUST be explicitly `nonisolated`** (declare the row model + the static on a `nonisolated enum SignalPoolDiagnostics { … }` or mark the type `nonisolated`): the demo target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (`project.pbxproj:414`), so an unmarked static inherits `@MainActor` and forces the pure unit tests to be `@MainActor` — the demo already uses `nonisolated enum Waveform` for exactly this (`Waveform.swift:14`). Follow that precedent.

2. **DD2 — AC5's whole-tree `grep -r EnsembleDecision Demo/` is over-broad and would regress forensics; scope the removal to the on-screen summary VIEW.** FR-41's actual requirement is "Replaces the current `EnsembleDecision` **summary view** inside the sidebar." That summary view is the `if let decision = trace.ensembleDecision { … }` `LabeledContent` block inside `TraceView.mlSection` (`TraceView.swift:252-266`). But a literal `grep -r EnsembleDecision Demo/` ALSO hits (a) the `EnsembleDecisionJSON` projection in `TraceExport.swift:310,392,534,542`, (b) the golden fixture key `"ensembleDecision"` at `5-4-trace-export-golden.json:28`, and (c) NaN-sanitization tests at `AnalysisViewModelSmokeTest.swift:875,940,1085-1106,1341,1487`. Deleting those regresses forensic JSON export of the ML decision AND breaks `traceProjectionRoundTripsJSON` / `nanInSanitizedFieldsNullifies` / the golden fixture. **Resolution:** remove only the on-screen `ensembleDecision` rendering in `TraceView.swift`; the JSON export projection, its golden coverage, and the NaN tests STAY untouched (export ≠ "summary view", and they are golden-locked / `Sources`-adjacent forensic surface). Verification narrows from the whole-tree grep to `grep -n "ensembleDecision" Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/TraceView.swift` returning **zero**. Recorded as an explicit interpretation — flag at PR review like 9.1's D1. (This is also why the demo's `ensembleDecision` block was vestigial anyway — see DD8.)

3. **DD3 — `SignalPoolDiagnosticRow` flattens `SignalParticipationTraceEntry` + its embedded `WeightedSignal`; the six columns' provenance is pinned.** The columns do NOT all map to stored fields:
   - **Source** ← `entry.source.rawValue` (`dsp` / `ml` / `fileMetadata`; `beatGrid` has no producer — DD forward seam, never appears in a live trace).
   - **Weight** ← `entry.weight` (`Double`).
   - **Contribution** ← `entry.contribution` (`Double`; the entry's own `description` documents it as `signalConfidence × weight`).
   - **Confidence** ← `entry.participation.confidence` (`0.0` for `.absent` / `.abstained`; the signal's `confidence` for `.present` / `.demoted`).
   - **BPM** ← the `WeightedSignal.bpm` embedded in `.present` / `.demoted`; **there is no BPM for `.absent` / `.abstained`** → render `—` and sort it to the bottom.
   - **Cluster** ← **DERIVED** (DD4); no such field exists on any trace type.
   The row also carries `participationKind` (present / demoted(reason) / abstained(reason) / absent) so the demo can show *why* a non-voting source is present-but-silent (e.g. ML `.abstained("ml-eval-deferred")` on a no-model run, metadata `.absent` when tags are off). **Sort keys, not display values, are what `TableColumn(value:)` binds (Codex):** an optional `bpm: Double?` is a poor `TableColumn(value:)` comparator key. The row therefore stores **non-optional, finite-safe sort keys** — `bpmSortKey`, `confidenceSortKey`, `weightSortKey`, `contributionSortKey` (all `Double`) — each mapping missing/`.nan`/`±Inf` to a deterministic sentinel (DD9); the `TableColumn`s bind their `value:` comparator to THESE keys while their cell closures render the finite-guarded display string (`—` for missing/non-finite).

4. **DD4 — "Cluster" and the winning row are DERIVED; the rule is pinned so the dev agent does not invent one.** `selectedBPM = trace.ensembleWeightResolution?.selectedBPM ?? snapshot.result.bpm`. For each row with a BPM, it belongs to the **winning cluster** iff `abs(bpm - selectedBPM) <= clusterToleranceBPM` where `clusterToleranceBPM = 0.5` (absolute; octave-folding is deliberately OUT of scope — this is a demo audit table, not a library octave resolver). Derived per-row fields:
   - `clusterRank: Int` — `0` = winning cluster, `1` = other `.present`/`.demoted` candidate (has a BPM, off-cluster), `2` = non-voter (`.absent`/`.abstained`, no BPM). Drives default grouping + the Cluster column sort.
   - `clusterLabel: String` — `"Winner"` (rank 0) / `"Rejected"` (rank 1) / `"—"` (rank 2).
   - `isWinner: Bool` — the SINGLE decisive row carrying the badge. **Selection is source-restricted with no cross-source fallback (revised after code review — the original "fall back to the full cluster" mis-badged a DSP row when ML won):** (a) map `winner` to the authoritative source — `.dsp`→`.dsp`, `.tie`→`.dsp` (the combiner's DSP-wins tiebreak), `.ml`→`.ml`, and **`nil`→`.dsp`** (no weighted resolution, e.g. `.dspOnly`; file metadata only re-weights the pool, it is never the selected candidate, so a confidence-1.0 tag must NOT steal the badge); (b) candidates = winning-cluster rows (`clusterRank == 0`) **with that exact source**; (c) among candidates pick greatest `contribution`, then smallest `abs(bpm − selectedBPM)`, then smallest original entry index — a total order, so at most one `isWinner`; (d) if NO candidate survives, NO badge (all `false`). **The critical case:** `signalParticipationTrace` is built inside `select()` BEFORE ML inference, so the pool's `.ml` entry is ALWAYS `.abstained` (no BPM, never rank 0). An `.ml` winner therefore yields NO badge — the row it won on isn't in this pre-ML trace — and the verdict is carried by the `ensembleWeightResolution` summary line (DD8) instead of mis-badging DSP. Because multiple merged `.dsp` rows can exist (`BPMSelectionPolicy.participationEntries` emits one per merged candidate), the contribution/delta/index tiebreak is what makes the DSP badge single.
   `isWinningCluster` (for the tint) = `clusterRank == 0`.

5. **DD5 — AC3 (free sort) and AC4 (grouped/emphasized) reconciled via per-row emphasis + a default sort, NOT hard `Table` `Section`s.** The winner emphasis is row state (`isWinningCluster` → background tint; `isWinner` → leading `checkmark.circle.fill` badge), so it travels under ANY sort order and never disappears. AC4's "rejected candidates ... grouped below the winner" is the **default** `@State private var sortOrder = [KeyPathComparator(\SignalPoolDiagnosticRow.clusterRank), KeyPathComparator(\.contributionSortKey, order: .reverse)]`. A column-header tap re-sorts by that column (AC3) and dissolves the grouping — expected for a sortable table; the user can re-tap the **Cluster** column to regroup winner-vs-rejected. `Table` `Section`s are rejected because they fight arbitrary column sort. **Two SwiftUI `Table` gotchas that MUST be honored (Codex), or AC3/AC4 silently fail:**
   - **(a) `Table` does NOT auto-sort its rows from the `sortOrder` binding.** The binding only records header taps; the developer must feed the sorted collection: `Table(of:sortOrder:$sortOrder) { … rows … }` where the rows iterate `SignalPoolDiagnostics.rows(from:…).sorted(using: sortOrder)` (recompute on each render, or keep a `@State` array and `.onChange(of: sortOrder)` re-sort it). If the code iterates the unsorted array, header clicks appear to do nothing.
   - **(b) Row-level `.background(...)` is NOT a real mechanism on a plain `Table`** — a `TableRow` is not an ordinary `View`, and `.listRowBackground` is a `List` tool. The winning-cluster tint is applied **per-cell**: each of the six `TableColumn` cell closures wraps its content with `.background(row.isWinningCluster ? Color.accentColor.opacity(0.12) : .clear)` (full-cell), and the leading `Source` cell also carries the `checkmark.circle.fill` badge for `row.isWinner`. Accept that the tint is per-cell (may read as banded, not a seamless full-row block) — acceptable for a diagnostic table; do not bridge to AppKit for a seamless row (out of scope).

6. **DD6 — The `Table` needs a BOUNDED height inside `TraceView`'s `ScrollView`.** `TraceView.body` is `ScrollView { VStack { … } }` (`TraceView.swift:20-37`); a `SwiftUI.Table` brings its own vertical scroll and, nested unbounded in an outer `ScrollView`, collapses to near-zero height. The section gives the table `.frame(minHeight: 160, idealHeight: 240, maxHeight: 340)` (an explicit ideal, per Codex — the `beatGridSection` `.frame(maxHeight: 340)` pattern plus a floor/ideal for the nested case). Expect nested vertical scrolling; keep the sidebar as the placement (moving the `Table` outside would force a TraceView layout rewrite — rejected). **Column-width caution (Codex):** the inspector is only 240/320/480 pt wide (`ContentView.swift:126` `.inspectorColumnWidth`), so six columns are tight — give numeric columns explicit `width:`/`min` and let `Source`/`Cluster` truncate; verify legibility in the operator GUI smoke. App deploys macOS 15.6, so `Table(of:sortOrder:)`, `TableColumn`, `KeyPathComparator`, and `.inspector` are all available without `#available` (KDD-D5 cites macOS 13+; architecture.md:1224 confirms no guards needed).

7. **DD7 — Empty-state (AC2) is reached via an EMPTY `signalParticipationTrace`, not a live `enableTrace=false` toggle.** The demo hard-codes `opts.enableTrace = true` on every run (`AnalysisViewModel.swift:404`), and `TraceView` renders only when `lastRunSnapshot != nil` (`ContentView.swift:126-146` 3-way branch), so post-run the trace is ALWAYS populated. `SignalPoolDiagnosticTable` shows the empty-state message **"Enable diagnostic trace in advanced settings"** (AC2 verbatim) when its `entries` input is empty. The AC2 "`enableTrace = false`" path is therefore exercised by a **pure-view unit test passing `[]`**, not by a real run (no `enableTrace` toggle is added — out of scope; the message is defensive + future-proofs a later advanced-settings toggle).

8. **DD8 — Surface `ensembleWeightResolution` as the section's summary line, because the shipped presets emit IT, not `ensembleDecision`.** The `ensembleDecision` block being removed (DD2) was effectively dead on-screen: `.default`/`.dspOnly`/`.weightedVoting` (the only presets 9.1 ships) emit `ensembleWeightResolution`; `ensembleDecision` is populated ONLY for `.mlOnly`/`.highestConfidence`, which no preset maps to (`AudioAnalysisService.combineEnsemble`; verified in 9.1's Debug Log). So the new section renders `trace.ensembleWeightResolution` (winner, `dspEffectiveVote`, `mlEffectiveVote`, `selectedBPM`) as a one-line summary above the Table when non-nil, giving the demo an honest "who won and why" it never actually showed before. Under `.dspOnly` the resolution is `nil` → omit the summary; the Table still renders the pool (DSP `.present` rows + ML `.abstained("ml-eval-deferred")` + metadata `.absent`/`.present`).

9. **DD9 — NaN-safe display AND sort, with the sort keys as the bound comparator properties.** Trace `Double`s are unsanitized value-carriers that can hold `NaN`/`±Inf` (CLAUDE.md; `EnsembleWeightResolution`/`WeightedSignal` are deliberately non-`Hashable` for this reason). Cells format via a finite-guarded helper (mirror `TraceView.monoFloat` at `TraceView.swift:321-324`, but return `—` for non-finite). **The `TableColumn(value:)` comparator MUST bind to the finite-safe stored sort keys (`bpmSortKey`/`confidenceSortKey`/`weightSortKey`/`contributionSortKey` — DD3), never the raw `Double?`/`Double` display values** — sorting on `NaN` does not crash but yields an unstable/useless order (NaN comparisons are not well-ordered). Each sort key maps missing/`.nan`/`±Inf` to a deterministic sentinel (`-Double.greatestFiniteMagnitude`, so missing/non-finite sort to the bottom on descending default). Display strings stay `—`; only the hidden sort keys are sentinel-mapped.

10. **DD10 — FR-44 (no bare numeric) is satisfied by the column headers.** Every numeric cell sits under a labeled column (`Source` / `BPM` / `Confidence` / `Weight` / `Contribution` / `Cluster`) and the summary line labels each value (`Winner:`, `DSP vote:`, `ML vote:`, `Selected BPM:`). No bare number ships. FR-44's cross-cutting CI enforcement is Story 9.3's job; this table complies by construction.

## Acceptance Criteria

1. **New file + table shape (KDD-D5).** Given a new file `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/SignalPoolDiagnosticTable.swift`, when the demo target builds via `make demo-build`, then `SignalPoolDiagnosticTable` is a SwiftUI `View` containing a `Table(of: SignalPoolDiagnosticRow.self, sortOrder: $sortOrder)` with exactly six `TableColumn`s labeled verbatim `Source`, `BPM`, `Confidence`, `Weight`, `Contribution`, `Cluster`.

2. **Data source + empty state.** Given the table reads from `BPMDiagnosticTrace.signalParticipationTrace` (Story 6.1), when an analysis completes (demo forces `enableTrace = true`), then the table renders one `SignalPoolDiagnosticRow` per `SignalParticipationTraceEntry` (5–15 rows typical per KDD-D5); when the entries array is empty (AC2's `enableTrace = false` condition), the table shows "Enable diagnostic trace in advanced settings" rather than crashing (DD7 — exercised by a pure-view test with `[]`).

3. **Sort interaction.** Given sort via the `Table`'s built-in column-header tap, when the user clicks any column header, rows re-sort by that column ascending; a second click reverses; the table is read-only (no row editing). The displayed rows are explicitly `.sorted(using: sortOrder)` — the `sortOrder` binding records the tap but does NOT auto-sort the data (DD5a). Column comparators bind to the finite-safe sort keys so non-finite / missing values sort deterministically (DD9).

4. **Visual emphasis (FR-41).** When the table renders, rows in the winning cluster carry an accent background tint (HIG-compliant, `Color.accentColor.opacity`), the single winning row carries a leading `checkmark.circle.fill` SF Symbol badge, and rejected candidates appear grouped below the winner under the default sort (DD4/DD5). Cluster membership and the winner are derived per DD4 (`selectedBPM` ± 0.5 BPM; winner from `ensembleWeightResolution.winner`, or the top-contribution winning-cluster `.present` row when the resolution is nil).

5. **Replaces the on-screen `EnsembleDecision` summary view (FR-41, scoped per DD2).** When the sidebar source compiles, the on-screen `ensembleDecision` rendering is removed from `TraceView.swift` — verified by `grep -n "ensembleDecision" Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/TraceView.swift` returning zero. The `EnsembleDecisionJSON` export projection in `TraceExport.swift`, the golden fixture, and the NaN-sanitization tests are deliberately preserved (export ≠ summary view; golden-locked). The new signal-pool section + the `ensembleWeightResolution` summary line (DD8) are the sidebar's ensemble-audit surface.

6. **Sidebar-closed discipline (FR-43).** Given the table lives inside the existing `.inspector(isPresented:)` sidebar from Story 5-6b (`⌘⇧D`), when the sidebar is closed, the primary BPM-result flow is unaffected (the table renders only inside the inspector content, gated by the same `inspectorPresented` `@SceneStorage` — `ContentView.swift:14,126-146`).

7. **Dependency gate.** Story 6.1 (`signalParticipationTrace`) AND Story 6.5 (`EnsemblePolicy` facade) are closed on develop — satisfied (Epic 6 closed 2026-05-30; both types verified public on the current tree).

8. **Demo-only diff scope.** `git diff --stat Sources/ Tests/` is empty; `make build` + `make test` pass unchanged; the golden trace-export fixture (`5-4-trace-export-golden.json`) and its test are untouched and pass (DD2).

## Out of scope (explicit)

- **Live / per-window incremental updates** — FR-41 defers incremental `BPMDiagnosticTrace` emission to a future epic; the table is final-state, post-analysis only.
- **Any library change** (`Sources/`, `Tests/`) — every read type is already public; no new trace field, no new `enableTrace` toggle in the demo UI.
- **Removing / altering the `EnsembleDecisionJSON` JSON export, the golden fixture, or the NaN-sanitization tests** (DD2 — export is preserved).
- **Octave-aware cluster grouping** — cluster membership is a simple ±0.5 BPM proximity to `selectedBPM` (DD4); octave folding is a library concern, not a demo table.
- **Row editing, selection-driven side effects, CSV/JSON export of the table** — read-only, sortable only (KDD-D5).
- **FR-44 canonical label vocabulary / CI gate** (Story 9.3 + Epic 11 KDD-E8); this story only complies with "no bare numeric" via column headers (DD10).
- **`beatGrid` signal rows** — `SignalSource.beatGrid` has no pool producer (deferred-work W53); it will never appear in a live `signalParticipationTrace`.
- **Localization; new accessibility conventions beyond the demo's existing 5-6b bar** — new controls carry labels at the existing standard (that is T3's a11y subtask, not a new NFR).

## Tasks / Subtasks

- [x] **T1 — `SignalPoolDiagnosticTable.swift` (new file): row model + pure derivation + Table view** (AC1, AC2, AC3, AC4)
  - [x] `struct SignalPoolDiagnosticRow: Identifiable` — `id`, `source: String`, display fields + **finite-safe stored sort keys** `bpmSortKey`/`confidenceSortKey`/`weightSortKey`/`contributionSortKey: Double` (DD3/DD9), plus `clusterRank: Int`, `clusterLabel: String`, `isWinningCluster: Bool`, `isWinner: Bool`, `participationKind: String` (DD3/DD4). Keep the BPM display as `Double?`/string but sort on `bpmSortKey` (a `Double?` is a poor `TableColumn(value:)` key — Codex).
  - [x] Pure `static func rows(from entries: [SignalParticipationTraceEntry], selectedBPM: Double, winner: EnsembleWeightResolution.Winner?) -> [SignalPoolDiagnosticRow]` on a **`nonisolated`** namespace (DD1 — the demo is MainActor-default-isolated; `nonisolated enum Waveform` precedent); the sole flatten/derive + winner-selection site (DD4 order-sensitive rule).
  - [x] `struct SignalPoolDiagnosticTable: View` — `Table(of: SignalPoolDiagnosticRow.self, sortOrder: $sortOrder)` over rows that are **explicitly `.sorted(using: sortOrder)`** (DD5a — `Table` does not auto-sort), with the six verbatim `TableColumn`s whose `value:` comparators bind the sort keys (AC1); `@State sortOrder` defaulting to `[clusterRank, contributionSortKey desc]` (DD5); **per-cell** winning-cluster tint + `checkmark.circle.fill` badge on the `Source` cell (DD5b — no row `.background`); finite-guarded cells with `—` fallback (DD9); empty-state message when `entries.isEmpty` (DD7).
  - [x] Optional `ensembleWeightResolution` summary line above the Table when non-nil (DD8), each value labeled (DD10).
  - [x] New file auto-joins the app target (pbxproj `PBXFileSystemSynchronizedRootGroup` — no pbxproj edit; verify via `make demo-build`).
- [x] **T2 — `TraceView` integration + `ensembleDecision` on-screen removal** (AC5, AC6)
  - [x] Add a `signalPoolSection` `GroupBox` to `TraceView.body` (`TraceView.swift:20-37`) that embeds `SignalPoolDiagnosticTable(entries: snapshot.trace.signalParticipationTrace, resolution: snapshot.trace.ensembleWeightResolution, selectedBPM: <DD4 selectedBPM>)` with the `.frame(minHeight: 160, maxHeight: 340)` bound (DD6). Place it where the ensemble audit belongs (near the former ML section).
  - [x] Remove the on-screen `ensembleDecision` `LabeledContent` block from `mlSection` (`TraceView.swift:252-266`); keep the ML-diagnostic rows (softmax/checksum, `:272-317`) and `mlFeatures`. Verify `grep -n "ensembleDecision" TraceView.swift` == 0 (AC5/DD2).
  - [x] Do NOT touch `TraceExport.swift`, the golden fixture, or the NaN tests (DD2).
- [x] **T3 — Tests (`BoomBoomBoomBPMTests`, Swift Testing)** (AC1, AC2, AC3, AC4)
  - [x] New `SignalPoolDiagnosticTableTests.swift` — PURE derivation tests (no `@MainActor`/fixtures, `BeatGridLogicTests` style): synthetic `[SignalParticipationTraceEntry]` → assert row count, column provenance (DD3), cluster membership at the ±0.5 boundary (in/out), `isWinner` selection with and without a resolution (DD4), non-voter (`.absent`/`.abstained`) rows get `bpm == nil` + `clusterRank == 2`.
  - [x] Empty-state (pure half): `rows(from: [], …)` is empty is unit-tested (`emptyInput`). The VIEW-render of the "Enable diagnostic trace in advanced settings" message is correct by construction (`entries.isEmpty` branch) but is operator GUI-smoke — the demo has no SwiftUI view-inspection harness (AC2/DD7).
  - [x] NaN safety: a `WeightedSignal(bpm: .nan, …)` derives a finite-safe sort key and displays `—`; sort is deterministic (DD9).
  - [x] Real-run integration (the established pattern — `analyze(url:)` on `bpm-120-click.wav` + poll `isAnalyzing` with the 30 s ceiling, per `AnalysisViewModelSmokeTest`/`EnsemblePresetPickerTests.runAnalysis`): assert `lastRunSnapshot.trace.signalParticipationTrace` is non-empty and `rows(from:)` yields ≥1 winning-cluster row for a default-preset run. Record the added real-run count in Completion Notes.
  - [x] `ensembleWeightResolution` summary presence: non-nil under a `.default`/weighted preset run, nil under `.dspOnly` (mirrors `EnsemblePresetPickerTests` precedence assertions).
  - [x] Winner total-order coverage (code-review follow-up): `.tie`→DSP, nil→DSP-over-metadata, `.ml`-abstained→no-badge, and equal-contribution→smaller-delta tiebreak each asserted.
  - [x] Accessibility: the winner badge carries `.accessibilityLabel("winning signal")`; `Table` cells inherit default VoiceOver exposure at the existing 5-6b bar (no dedicated a11y unit test — view-layer, operator GUI-smoke).
- [x] **T4 — Gauntlet + close-out** (AC5, AC8)
  - [x] `make demo-fmt`, `make demo-lint`, `make demo-build`, `make demo-test`, `make pre-commit` — record counts in Completion Notes.
  - [x] `make build` + `make test` (library untouched); `git diff --stat Sources/ Tests/` empty (AC8).
  - [x] Golden trace-export test passes with `5-4-trace-export-golden.json` untouched (DD2); `grep -n "ensembleDecision" TraceView.swift` == 0 (AC5).
  - [x] Diff hygiene: the untracked `_bmad-output/implementation-artifacts/14-1-daw-warp-anchors.generated.json` and `_bmad-output/party-mode/` must NOT enter this story's commits — stage paths explicitly, never `git add -A`.
  - [x] Story file Dev Agent Record + File List; sprint-status `backlog → ready-for-dev → in-progress → review`.

## Dev Notes

### Architecture & source tree (touch points, verified 2026-07-03 against the post-`5dcae9f` develop tree)

- **NEW** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/SignalPoolDiagnosticTable.swift` — `SignalPoolDiagnosticRow` + pure `rows(from:selectedBPM:winner:)` + `SignalPoolDiagnosticTable` view (DD1).
- **UPDATE** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/TraceView.swift` (365 lines) — add `signalPoolSection` to `body` (`:20-37`); remove the `ensembleDecision` block from `mlSection` (`:252-266`); reuse `monoFloat` (`:321-324`) or a finite-guarded sibling (DD6/DD9).
- **NEW** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/SignalPoolDiagnosticTableTests.swift` (DD1 pure tests + real-run integration).
- **NO CHANGE**: `TraceExport.swift` (`EnsembleDecisionJSON` export preserved — DD2); `5-4-trace-export-golden.json`; `AnalysisViewModel.swift` (already forces `enableTrace = true` at `:404`, captures the snapshot at `:517-525`); `ContentView.swift` (inspector wiring at `:126-146` unchanged); anything under `Sources/` or `Tests/`.

### Library surface consumed (read-only; verified public declarations)

- `BPMDiagnosticTrace.signalParticipationTrace: [SignalParticipationTraceEntry]` — `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:265` (default `[]`; populated whenever a trace is built — `BPMSelectionPolicy.select` `participationEntries(...)`; NOT gated on ensemble policy, so present on `.dspOnly` too).
- `BPMDiagnosticTrace.ensembleWeightResolution: EnsembleWeightResolution?` — `:174-182` (non-nil for `.default`/`.weightedVoting`; nil for `.dspOnly`/`.mlOnly`/`.highestConfidence`).
- `SignalParticipationTraceEntry` — `SignalPool/SignalParticipationTraceEntry.swift:12-51`: `source: SignalSource`, `participation: SignalParticipation`, `weight: Double`, `contribution: Double`. `Sendable, CustomStringConvertible`, NOT `Codable`.
- `SignalParticipation` — `SignalPool/SignalParticipation.swift:9-40`: `.absent`, `.abstained(AbstainReason)`, `.demoted(WeightedSignal, reason:)`, `.present(WeightedSignal)`; computed `.confidence: Double` and `.score: Float?`.
- `WeightedSignal` — `SignalPool/WeightedSignal.swift:8-33`: `bpm`, `confidence: Double`, `source`, `score: Float?`.
- `SignalSource` — `SignalPool/SignalSource.swift:8-13`: `dsp/ml/fileMetadata/beatGrid` (`String, CaseIterable`).
- `AbstainReason` / `DemotionReason` — `.sourceSpecific(String)` + `AbstainReason.mlEvalDeferred = "ml-eval-deferred"`, `.noCandidates`.
- `EnsembleWeightResolution` — `EnsembleWeightResolution.swift:27-71`: `policyKey`, `weights: SignalWeights`, `dspEffectiveVote`, `mlEffectiveVote: Double?`, `winner: Winner` (`.dsp/.ml/.tie`), `selectedBPM`. NOT `Codable`/`Hashable`.
- The internal `UnifiedSignalPool` / `BPMSelectionPolicy.participationEntries` are NOT reachable from the demo — read the finished entries off the trace only.

### Reuse-first inventory

- Snapshot access: `snapshot.trace.signalParticipationTrace` / `.ensembleWeightResolution` — the snapshot is already captured (`AnalysisViewModel.swift:517-525`, `LastRunDiagnosticSnapshot.trace`). No new capture plumbing.
- Finite-guarded float formatting: `TraceView.monoFloat(_:digits:)` (`:321-324`) — extend with a `—` non-finite fallback rather than inventing a formatter (DD9).
- Pure-logic test template: `BeatGridLogicTests.swift` (static helpers, no `@MainActor`, no fixtures) — the model for the `rows(from:)` unit tests.
- Real-run test template: `EnsemblePresetPickerTests.runAnalysis(_:)` / `AnalysisViewModelSmokeTest.analyzeFixture()` (poll `isAnalyzing`, 30 s ceiling, `AudioFixtures.url(for: "bpm-120-click", extension: "wav")`).
- Per-row layout precedent: `TraceView.candidateRow` (`:100-109`) — but this story uses a real `SwiftUI.Table`, not hand-built `HStack` rows (the demo's first `Table`; AC1 mandates it).

### Constraints (project-context.md / CLAUDE.md)

- Demo stays on develop; ships via `make demo-archive` only. Nothing lands on main.
- Swift Testing (`@Suite`/`@Test`/`#expect`/`#require`); 2-space indent; `make demo-fmt` before `demo-lint`.
- No emojis anywhere; commit message `Story 9-2: <deliverable>` with no review-process references; `Claude-Session:` trailer; operator signs.
- Trace `Double`s are unsanitized value-carriers (may be NaN) — finite-guard on display AND on sort keys (DD9). See the `bpm-diagnostic-trace` skill for the typed-evidence field rules.

### Previous Story Intelligence (PSI)

- **Story 9.1 (this epic, just landed `5dcae9f`)**: the demo builds with **MainActor default isolation** — demo enums / computed props / view models are implicitly `@MainActor`; pure-value tests still need `@MainActor` unless the tested API is genuinely non-isolated (9.1 Debug Log red #1). The pure `rows(from:)` static should be non-isolated if possible; if the compiler forces isolation, annotate the tests. **Weighted presets emit `EnsembleWeightResolution`, NOT `EnsembleDecision`** (9.1 Debug Log red #3) — the entire basis for DD2/DD8; do not assert `ensembleDecision` for demo presets.
- **Epic 8 retro / factual-claims grep**: every path/line cited here was re-verified on 2026-07-03 against the post-`5dcae9f` tree.
- **9.1 commit hygiene**: the untracked `14-1-daw-warp-anchors.generated.json` (its `.gitignore` fence lives only on epic-14) and `_bmad-output/party-mode/` must be kept out — explicit-path staging only.

### Testing standards

- `make demo-test` drives the app scheme + `BoomBoomBoomBPM.xctestplan`; new test files under `BoomBoomBoomBPMTests/` auto-join (synchronized folders) — verify discovery by name in the run log.
- Record exact demo-test invocation counts before/after in Completion Notes (post-9.1 baseline: 124).
- Prefer pure `rows(from:)` unit tests for the derivation logic (fast, deterministic); one real-run integration test proves the live trace actually populates.

### References

- epics.md `### Story 9.2` (lines 1278-1316) — ACs, six-column contract, KDD-D5 sizing, dependency gate.
- prd.md FR-41 (`:165`), FR-43 (`:169`), FR-44 (`:171`); architecture.md KDD-D5 (`:555`), sidebar/table description (`:318`), macOS-15-no-guards note (`:1224`), `SignalPoolDiagnosticTable.swift # NEW` (`:1099`).
- Story 9.1 spec (`9-1-…-persistence.md`) — the demo precedent (Table-less sidebar, `enableTrace` always-on, `EnsembleWeightResolution` vs `EnsembleDecision`).
- deferred-work W53 (`beatGrid` producer absent — DD3/out-of-scope).
- API validation (to run in the review phase, as in 9.1): `Table(of:sortOrder:)`, `TableColumn(value:)` with `KeyPathComparator`, `.inspector(isPresented:)` — all macOS 13/14+, app deploys 15.6, no `#available` needed (architecture.md:1224).

## Dev Agent Record

### Agent Model Used

Claude Opus 4.8 (claude-opus-4-8), 2026-07-03 session, bmad-dev-story single-shot implementation.

### Debug Log References

- Compile red #1 (`make demo-build`): `KeyPathComparator(\SignalPoolDiagnosticRow.contributionSortKey, order: .reverse)` in a stored `@State` default is non-`Sendable` under Swift 6 strict concurrency (`KeyPath` does not conform to `Sendable`). Fix: initialize `sortOrder` empty and apply the default cluster-first grouping in `sortedRows` when `sortOrder.isEmpty`, replacing it on the user's first header tap (DD5a preserved). No KeyPathComparator is stored in a default.
- Compile red #2 (`make demo-test`): the pure test helpers `entry`/`present` were `static` but called bare from Swift Testing instance `@Test` methods (`Static member … cannot be used on instance`). Fix: made them instance methods. The cascade "cannot infer key path type" errors were downstream of the unresolved `rows` type and cleared with them.
- Compile red #3 (`make demo-test`): `SignalPoolDiagnosticRow`'s stored properties were `@MainActor`-isolated (demo default isolation), so the off-actor pure tests could not read `.clusterRank`/`.isWinner`/etc., and the `TableColumn(value:)` keypaths could not form. Fix: marked the whole `SignalPoolDiagnosticRow` struct `nonisolated` (DD1 required the row model off the actor, not just the derivation enum). This also unblocked the `TableColumn` value keypaths.

### Completion Notes List

- All 4 tasks + 20 subtasks complete; all 8 ACs satisfied. Demo-only: `git diff --stat Sources/ Tests/` empty; library `make build` clean + `make test` 842 tests / 138 suites (byte-identical to the pre-9.2 baseline).
- `SignalPoolDiagnosticTable.swift` (NEW): `nonisolated struct SignalPoolDiagnosticRow` (display fields + finite-safe `*SortKey` fields) + `nonisolated enum SignalPoolDiagnostics.rows(from:selectedBPM:winner:)` (the sole flatten/derive + total-order winner selection) + `SignalPoolDiagnosticTable` view (six verbatim `TableColumn`s over `.sorted(using: sortOrder)`, per-cell accent tint, `checkmark.circle.fill` winner badge, `ensembleWeightResolution` summary line, empty-state message). Auto-joined the app target (synchronized folders, no pbxproj edit).
- `TraceView.swift` (MODIFIED): new `signalPoolSection` GroupBox between `metadataSection` and `mlSection`; the on-screen `ensembleDecision` block removed from `mlSection` (and dropped from `hasAnyML`). AC5 verified: `grep -c ensembleDecision Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/TraceView.swift` == 0; the `EnsembleDecisionJSON` export in `TraceExport.swift` (5 refs) + golden fixture + NaN tests preserved untouched (DD2).
- `SignalPoolDiagnosticTableTests.swift` (NEW): 14 tests — provenance, ±0.5 cluster boundary (inclusive), non-voter rank/dash/zero-confidence, winner by source / `.tie`→DSP / nil→DSP-over-metadata / `.ml`-abstained→no-badge / multiple-DSP-single-badge / delta-tiebreak / empty-cluster-no-badge, NaN BPM → `—` + sentinel sort key, empty input, and 2 real-run integration (`.default` populates pool + weighted resolution + winning-cluster row; `.dspOnly` populates pool with nil resolution). All 14 green (12 initial + 2 code-review winner-rule tests).
- Gauntlet: `make demo-fmt` clean; `make demo-build` BUILD SUCCEEDED; `make demo-test` **136 test cases, 0 failures** (+12 from the 124 post-9.1 baseline); `make demo-lint` exit 0; `make build` 0.15 s; `make test` 842/138; `make pre-commit` 1 violation 0 serious (the canonical `LUFSAnalyzer.swift` TODO baseline). Diff scope demo-only.

### Pending user action (operator-owned)

- Manual GUI smoke (the UI-behavior half of AC3/AC4 that pure tests cannot cover): open the sidebar (`⌘⇧D`), analyze a track; confirm the six-column table renders in the 240–480 pt inspector without unreadable truncation, the winning cluster is accent-tinted with a single `checkmark.circle.fill` badge, column-header taps re-sort (and reverse on a second tap), and the `Signal pool` section stays absent from the primary flow when the sidebar is closed.
- 1Password-signed commit + `gh pr create` onto `rterhaar/epic-9` after code review.

### File List

- NEW `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/SignalPoolDiagnosticTable.swift` — row model + nonisolated pure derivation (cluster + total-order winner) + sortable six-column `Table` view (per-cell tint, badge, resolution summary, empty-state).
- MODIFIED `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/TraceView.swift` — `signalPoolSection` added; on-screen `ensembleDecision` summary block removed from `mlSection`.
- NEW `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/SignalPoolDiagnosticTableTests.swift` — 12 tests (pure derivation + 2 real-run).
- MODIFIED `_bmad-output/implementation-artifacts/sprint-status.yaml` — status flips (9-2 ready-for-dev → in-progress → review).
- MODIFIED `_bmad-output/implementation-artifacts/9-2-signal-pool-diagnostic-table-in-advanced-sidebar.md` — this file (frontmatter baseline_commit, checkboxes, Dev Agent Record, Change Log, status).

## Review Findings (code review 2026-07-03 — 3-layer: Codex Blind Hunter, Edge Case Hunter, Acceptance Auditor)

~13 findings → 2 code patches + 1 test-coverage patch + 2 honesty corrections + 1 recorded decision + accepted/dismissed with evidence. All three layers independently converged on the winner-badge bug (P1).

### Recorded decision (operator sign-off at PR)

- **D1 (auditor AC1) — `Table(sortedRows, sortOrder:)` used, not the literal `Table(of: SignalPoolDiagnosticRow.self, sortOrder:)` the AC/DD1 spelled.** The data-driven initializer is the CORRECT form for DD5a — the `Table(of:sortOrder:)` builder takes no data collection, so it cannot feed an explicit `.sorted(using:)`. The six verbatim-labeled columns + the `sortOrder` binding contract are fully met. Recorded rather than silently deviating — flag at PR if the literal `Table(of:)` form was intended.

### Patches (applied, all green)

- **P1 (Codex HIGH + Edge #1 MEDIUM) — winner-source badge fix.** `signalParticipationTrace` is built inside `select()` BEFORE ML inference, so a live `.ml` pool row is ALWAYS `.abstained` (no BPM). The original "fall back to the full winning cluster when source-match is empty" mis-badged a DSP row while the summary read `Winner: ml`, and let a confidence-1.0 metadata tag steal the badge under `.dspOnly`. Now: restrict to the authoritative source (`.dsp`/`.tie`/`nil`→DSP, `.ml`→ML) with NO cross-source fallback; an `.ml` winner yields no badge (the verdict is carried by the `ensembleWeightResolution` summary line). DD4 revised.
- **P2 (Codex MEDIUM) — default grouping sort is now a total order.** Added the `id` (trace-index) tiebreak so equal-contribution rows sort deterministically (Swift `sorted` is not stable).
- **P3 (Codex LOW + auditor test-gap) — winner total-order coverage.** Added `mlWinnerAbstainedNoBadge`, `winnerNilRestrictsToDsp` (metadata out-contributes DSP but DSP keeps the badge), and `winnerDeltaTiebreak` (equal contribution → smaller BPM delta). Signal-pool suite 12 → 14 tests.
- **P4 (auditor) — honesty corrections.** Two T3 subtasks over-claimed dedicated tests: the empty-state VIEW-render and the accessibility check are operator GUI-smoke (the demo has no SwiftUI view-inspection harness), not unit tests. Reworded; what ships is the pure `rows([])` empty test + the badge's `.accessibilityLabel("winning signal")`.

### Accepted / dismissed (with evidence)

- **Edge #3 (multiple DSP candidates all labeled "Rejected")** — matches AC4's "rejected candidates" design; the harmonic relationship is already surfaced in the Disambiguation section. Accept as-designed.
- **Edge #4 (empty-state copy misdiagnoses a trace-on-but-empty pool)** — the string is AC2-mandated verbatim; the demo forces `enableTrace = true`, so the empty branch is defensive / future-toggle. Kept verbatim per AC2.
- **Codex LOW (badged row may not be first in its cluster under the default sort)** — cosmetic; the badge travels with the row regardless of position. Accept.
- **Edge/auditor Info confirmations** — `SignalParticipationTraceEntry`'s source precondition is unreachable from the demo (read-only consumer); removing the on-screen `ensembleDecision` block is NOT a regression (no demo preset maps to `.mlOnly`/`.highestConfidence`, the only cases that emit it); FR-44 satisfied (every number labeled); NaN / zero `selectedBPM` handled without crash. No action.
- **Manual-smoke items** (Table-in-ScrollView scroll nesting; first-tap ascending sort inverting the default grouping; six-column truncation in the 240–480 pt inspector) — already listed in Pending user action.

## Change Log

- 2026-07-03: Story spec created (bmad-create-story). Grounded by a 3-agent parallel forensic pass (epic/PRD/architecture planning; demo app current structure; library signal-pool trace surface); every cited path/type/line re-verified against the post-`5dcae9f` develop tree. Branches off the post-9.1 develop (9.1 accidentally landed as `5dcae9f`; operator chose to leave it landed — see Context).
- 2026-07-03: Pre-implementation Codex review (thread `019f2645-84d9-71c3-bf57-5dcc4198cfaa`). CONFIRMED DD2 (AC5's literal whole-tree grep is unsatisfiable without breaking the golden fixture `5-4-trace-export-golden.json:28` + the `EnsembleDecisionJSON` export + NaN tests; FR-41 scopes removal to the on-screen view — reinterpretation is correct), DD6 (bounded Table-in-ScrollView is the right placement), the ±0.5 BPM cluster heuristic, and the sort-vs-Sections reconciliation. Folded 3 HIGH + 3 MEDIUM fixes: DD4 winner rule tightened to a total order (`.tie`→DSP, contribution→BPM-delta→index, guaranteed single badge, handles multiple merged `.dsp` rows); DD5a — `Table` does NOT auto-sort, rows must be explicitly `.sorted(using: sortOrder)`; DD5b — winning-cluster tint is per-CELL, not a nonexistent row `.background`; DD3/DD9 — `TableColumn(value:)` binds finite-safe stored sort keys, not raw `Double?`/`NaN`; DD1 — the pure derivation namespace must be explicitly `nonisolated` (`nonisolated enum Waveform` precedent, demo is MainActor-default-isolated); DD6 — added `idealHeight: 240` + six-column width/truncation caution for the 240–480 pt inspector.
- 2026-07-03: Implementation complete (bmad-dev-story, single-shot; status ready-for-dev → in-progress → review). 2 NEW + 1 MODIFIED Swift file in Demo/; +12 test invocations (demo-test 136 total, 0 failures); library untouched (`git diff Sources/ Tests/` empty; 842 library tests green). Three implementation reds hit and resolved — a non-Sendable `KeyPathComparator` in a `@State` default (empty-init + manual default grouping), `static` test helpers called from instance `@Test`s, and the MainActor-isolated row model blocking off-actor tests + `TableColumn` keypaths (`nonisolated struct`) — details in Debug Log References. DD2 verified live: `ensembleDecision` gone from `TraceView.swift` (grep 0), `EnsembleDecisionJSON` export + golden fixture preserved.
- 2026-07-03: Code review complete (3-layer: Codex Blind Hunter thread `019f2699-1a74-7633-9f11-2088f43550f7`, Edge Case Hunter, Acceptance Auditor). All three converged on the winner-badge bug (P1): the pre-ML trace's `.ml` row is always abstained, so an `.ml` winner mis-badged a DSP row via the old full-cluster fallback. Triage: 2 code patches (P1 source-restricted badge / no cross-source fallback; P2 total-order default sort) + 1 test patch (P3, +2 winner-rule tests, suite 12→14) + 2 honesty corrections (P4, over-claimed empty-state-view + a11y subtasks → GUI-smoke) + 1 recorded decision (D1, `Table(sortedRows,…)` vs literal `Table(of:…)`) + accepted/dismissed with evidence. Post-patch: 14 signal-pool tests green, demo-test 0 failures, `Sources/ Tests/` diff empty, AC5 grep 0. Status review → done.
