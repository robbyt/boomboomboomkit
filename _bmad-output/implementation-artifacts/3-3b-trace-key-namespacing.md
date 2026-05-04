# Story 3.3b: Trace-Key Namespacing in BPMDiagnosticTrace

Status: done
**Depends on:** none (independent — can be picked up any time after Story 3-6b done)

## Story

As a library consumer using `BPMDiagnosticTrace` to diagnose BPM-detection edge cases,
I want trace dictionary entries keyed unambiguously by candidate identity (not by lossy `%.1f` BPM strings),
So that two candidates whose BPMs round to the same one-decimal label do not collapse into a single entry, and string-typed dictionaries do not silently corrupt the diagnostic record when a write site emits a key the consumer doesn't expect.

## Background

Story 3-3 added `BPMDiagnosticTrace.clickCorrelationDetail: [String: Float]?`, keyed by `String(format: "%.1f", candidateBPM)`. Codex's Edge Case Hunter and Blind Hunter agents both flagged this as a collision risk: two candidates whose BPM differs by less than 0.1 (or that happen to round to the same one-decimal value, e.g., `61.04` and `60.95` → `"61.0"`) collapse into one trace entry with no warning.

The same `%.1f` pattern was inherited from Story 3-1's `harmonicRatioDetail` and Story 1-2's `subBandVoteDetail`, and Story 3-4 then added `durationHintDetail` carrying the **same pattern AND a self-referential doc comment** explicitly deferring the fix to Story 3-3b:

> *"Like `clickCorrelationDetail`, this uses `String(format: "%.1f", bpm)` for BPM keys — the cross-cutting trace-key-collision fix is tracked in Story 3-3b (out of scope here)."*
> — `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:101-102`

All four trace fields share the bug. Story 3-3a deferred this finding because addressing it requires changing the public `BPMDiagnosticTrace` schema across **four** fields simultaneously — a cross-cutting trace-API change, not a per-story patch.

This story does that cross-cutting fix. **No DSP changes; behavior is preserved; only the trace schema changes.** The four affected fields fall into two categories:

| Field | Story | Current shape | Collision risk | Fix shape |
|---|---|---|---|---|
| `clickCorrelationDetail` | 3-3 | `[String: Float]?` keyed by `%.1f` BPM | YES — distinct candidates collapse | `[ClickCorrelationEntry]?` typed array |
| `harmonicRatioDetail` | 3-1 | `[String: String]?` with fixed keys (`ratio`, `fastBPM`, `slowBPM`, `winner`) | NO collision (fixed keys), but `%.1f` precision loss + string-typing | `HarmonicRatioEvidence?` typed struct |
| `subBandVoteDetail` | 1-2 | `[String: String]?` with fixed keys (`preVoteBPM`, `postVoteBPM`, `changed`) | NO collision, but `%.1f` precision loss + string-typing | `SubBandVoteEvidence?` typed struct |
| `durationHintDetail` | 3-4 | `[String: String]?` mixed keys (`fileDurationSeconds`, `barCandidates`, `boostedCandidates`) | NO collision (fixed keys), but heavy CSV serialization + `%.1f` precision loss | `DurationHintEvidence?` typed struct |

The first row is a **correctness fix** (collisions corrupt the record). The next three are **API hygiene** — the values are typed numbers stringified for dict storage, then string-parsed by every consumer. Migrating all four together avoids a second cross-cutting break later.

## Acceptance Criteria

1. **Given** `BPMDiagnosticTrace`'s four diagnostic detail fields (`clickCorrelationDetail`, `harmonicRatioDetail`, `subBandVoteDetail`, `durationHintDetail`)
   **When** the schema is reviewed
   **Then** all four migrate from `[String: …]?` to typed shapes that preserve candidate identity and native value types:
   - `clickCorrelationDetail: [ClickCorrelationEntry]?` where `public struct ClickCorrelationEntry: Sendable` carries `(candidateIndex: Int, bpm: Double, normalizedClickScore: Float)`.
   - `harmonicRatioDetail: HarmonicRatioEvidence?` (the existing internal `BPMAnalyzer.HarmonicRatioEvidence` struct is promoted to public — single-instance, replaces the dict).
   - `subBandVoteDetail: SubBandVoteEvidence?` where `public struct SubBandVoteEvidence: Sendable` carries `(preVoteBPM: Double, postVoteBPM: Double, changed: Bool)`.
   - `durationHintDetail: DurationHintEvidence?` where `public struct DurationHintEvidence: Sendable` carries `(fileDurationSeconds: Double, barCandidates: [BarCandidate], boostedCandidates: [Double])` and `public struct BarCandidate: Sendable { public let bars: Int; public let bpm: Double }`.
   **And** all four nested types live in `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` (single-source colocation with the trace struct that owns them).

2. **Given** two candidates at BPMs `61.04` and `60.95` (both round to `"61.0"` under `%.1f`)
   **When** click rescoring populates the trace via `BPMAnalyzer.clickRescore` with `enableTrace: true`
   **Then** both candidates appear as separate entries in `clickCorrelationDetail` with their distinct `bpm` (full `Double` precision) and `normalizedClickScore` values
   **And** a unit test in a new `Tests/BoomBoomBoomKitTests/BPMDiagnosticTraceTests.swift` constructs this collision scenario by directly invoking `clickRescore` with hand-crafted candidates and asserts both entries are present with `entry.bpm == 61.04` and `entry.bpm == 60.95` (exact `Double` equality — no `%.1f` rounding).

3. **Given** a downstream consumer reading `clickCorrelationDetail` to render a UI
   **When** the consumer iterates the trace
   **Then** the iteration order is stable: `entry.candidateIndex` reflects the original input-order index from the candidates array passed to `clickRescore`, AND the array is sorted ascending by `candidateIndex` (so `entries.map(\.candidateIndex)` is `[0, 1, 2, …]` with no gaps, matching the rescoring sort tiebreaker on `offset`).
   **And** a unit test asserts `entries.map(\.candidateIndex) == Array(0..<entries.count)` for a 5-candidate scenario.

4. **Given** existing tests that reference the old dictionary shapes (verified by grep at story-create time):
   - `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:218,232,452-492` — `clickCorrelationDetail`, `durationHintDetail`
   - `Tests/BoomBoomBoomKitTests/BPMAnalyzerClickTrackTests.swift:328-392` — `clickCorrelationDetail`
   - `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift:902-914` — `subBandVoteDetail` (5 dictionary key lookups)
   - `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift:1785-1798` — `harmonicRatioDetail` (4 dictionary key lookups)
   - `Tests/BoomBoomBoomKitTests/BPMAnalyzerDurationHintTests.swift:38-43,59,160,183,207,265,319-325,341` — `durationHintDetail` (8+ dictionary key lookups including `["barCandidates"]` substring assertions)
   **When** the schema change lands
   **Then** all callers are updated in the same commit, the dictionary `["key"] != nil` and `?["key"] == "..."` lookups become typed property accesses (`detail.preVoteBPM`, `detail.boostedCandidates.contains(128.0)`), and the full test suite passes.

5. **Given** `make benchmark`, `make benchmark-giantsteps`, and `make oracle`
   **When** run after the trace change
   **Then** OA300 Acc1/Acc2 and GiantSteps Acc1/Acc2 are byte-identical to the pre-change baselines on the same Git SHA. (No DSP change; this is a regression-protection floor, not a target. Record actual values in Completion Notes.)

6. **Given** the project's test count baseline at story-create time is **304** `@Test(` invocations (verified via `grep -rE '@Test\(' Tests/BoomBoomBoomKitTests/ | wc -l`)
   **When** AC #2, AC #3, and any incidental tests added by this story land
   **Then** the test count strictly increases (≥ 305) AND the only deletions are the lookups inside the four pre-existing trace tests that get rewritten in place. No `@Test` is removed.

7. **Given** the secondary review concern that the four trace types could individually conform to `CustomStringConvertible` to preserve the "easy to print in a debugger" affordance the dictionaries provided
   **When** the four new types are added
   **Then** each conforms to `CustomStringConvertible` with a single-line `description` that round-trips the meaningful fields (e.g., `ClickCorrelationEntry(idx: 0, bpm: 120.5, ncc: 0.78)`). Conformance is **public** so library consumers get the same affordance.

8. **Given** the cross-cutting nature of this migration and the fact that future trace fields will inevitably be added (Epic 4's ML technique slot, Epic 5's demo-app trace visualization, etc.)
   **When** this story lands
   **Then** a project-local Claude Skill exists at `.claude/skills/bpm-diagnostic-trace/SKILL.md` that:
   - Documents the typed-evidence pattern as the **required** shape for any future trace detail field (typed array OR typed struct OR typed struct with sub-collections — the three shapes this story establishes).
   - Documents the **four banned anti-patterns** explicitly: `[String: Float]?` keyed by `%.1f` BPM (collision), `[String: String]?` with stringified-numeric values (precision loss), CSV-serialized arrays inside dict values, stringly-typed enums-as-string-values.
   - Provides **five audit grep recipes** (A–E) that each must return zero matches in `Sources/BoomBoomBoomKit/` and `Tests/BoomBoomBoomKitTests/`.
   - Provides a **10-step checklist** for adding a new trace field.
   - Provides a **modification checklist** (rename / add property / remove) with the audit-rerun + `make benchmark` requirement.
   - Cross-references this story (`3-3b-trace-key-namespacing.md`) and Story 3-3 as institutional memory for the pattern's origin.
   **And** the dev agent **runs the five audit recipes against the post-migration tree** and confirms each returns zero matches before flipping the story to `review`. The output (one line per recipe + match count) is recorded in Completion Notes.
   **And** the skill file lives under `.claude/`, which per project-context.md L86 stays on `develop` — it does NOT ship to `main` and does NOT couple `Sources/` to AI tooling.

## Tasks / Subtasks

- [x] **Task 1: Define typed evidence types in `BPMDiagnosticTrace.swift`** (AC: #1, #7)
  - [x] 1.1: Add `public struct ClickCorrelationEntry: Sendable, CustomStringConvertible` with stored properties `public let candidateIndex: Int`, `public let bpm: Double`, `public let normalizedClickScore: Float`. Public memberwise `init`.
  - [x] 1.2: Promote `BPMAnalyzer.HarmonicRatioEvidence` (currently `struct HarmonicRatioEvidence: Sendable` at `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:1551-1556`, internal access) — move to `BPMDiagnosticTrace.swift` as `public struct HarmonicRatioEvidence: Sendable, CustomStringConvertible`. Add `public` to all stored properties (`ratio: String`, `fastBPM: Double`, `slowBPM: Double`, `winnerBPM: Double`). Update the four `HarmonicRatioEvidence(...)` construction sites in `BPMAnalyzer.swift:1595-1635` — they continue to compile unchanged because the type is now visible at module scope (no `BPMAnalyzer.HarmonicRatioEvidence` qualified lookup currently exists in tests; verify with grep before moving).
  - [x] 1.3: Add `public struct SubBandVoteEvidence: Sendable, CustomStringConvertible` with stored properties `public let preVoteBPM: Double`, `public let postVoteBPM: Double`, `public let changed: Bool`. Public memberwise `init`.
  - [x] 1.4: Add `public struct DurationHintEvidence: Sendable, CustomStringConvertible` with stored properties `public let fileDurationSeconds: Double`, `public let barCandidates: [BarCandidate]`, `public let boostedCandidates: [Double]`. Add `public struct BarCandidate: Sendable, CustomStringConvertible` with `public let bars: Int`, `public let bpm: Double`. Both with public memberwise `init`.

- [x] **Task 2: Migrate `BPMDiagnosticTrace` field declarations** (AC: #1)
  - [x] 2.1: Replace `public var clickCorrelationDetail: [String: Float]?` (`BPMDiagnosticTrace.swift:80`) with `public var clickCorrelationDetail: [ClickCorrelationEntry]?`. Update doc comment at lines 75-79 to describe the array shape; remove the `String(format: "%.1f", bpm)` mention.
  - [x] 2.2: Replace `public var harmonicRatioDetail: [String: String]?` (`BPMDiagnosticTrace.swift:71`) with `public var harmonicRatioDetail: HarmonicRatioEvidence?`. Update doc comment at lines 68-70.
  - [x] 2.3: Replace `public var subBandVoteDetail: [String: String]?` (`BPMDiagnosticTrace.swift:66`) with `public var subBandVoteDetail: SubBandVoteEvidence?`. Update doc comment at lines 64-65.
  - [x] 2.4: Replace `public var durationHintDetail: [String: String]?` (`BPMDiagnosticTrace.swift:103`) with `public var durationHintDetail: DurationHintEvidence?`. Update doc comment at lines 84-102 — DELETE the self-reference to "Story 3-3b" at lines 101-102 (the deferral note is now resolved by this story).

- [x] **Task 3: Update producer write sites in `BPMAnalyzer.swift`** (AC: #1, #2, #3)
  - [x] 3.1: `BPMAnalyzer.clickRescore` (write site `BPMAnalyzer.swift:2002-2061`):
    - Replace `var detail: [String: Float] = trace?.clickCorrelationDetail ?? [:]` (line 2002) with `var entries: [ClickCorrelationEntry] = []` and `entries.reserveCapacity(candidates.count)`.
    - Replace `if writeTrace { detail[String(format: "%.1f", cand.bpm)] = 0 }` (lines 2020, 2032) with `if writeTrace { entries.append(ClickCorrelationEntry(candidateIndex: idx, bpm: cand.bpm, normalizedClickScore: 0)) }`.
    - Replace `if writeTrace { detail[String(format: "%.1f", cand.bpm)] = clampedNCC }` (line 2057) with `if writeTrace { entries.append(ClickCorrelationEntry(candidateIndex: idx, bpm: cand.bpm, normalizedClickScore: clampedNCC)) }`.
    - Replace `if writeTrace { trace?.clickCorrelationDetail = detail }` (lines 2060-2061) with `if writeTrace { trace?.clickCorrelationDetail = entries }`.
    - **Order invariant**: the `for (idx, cand) in candidates.enumerated()` loop already iterates in input order, so appending `entries` in loop order naturally satisfies AC #3's "sorted by candidateIndex" requirement. No `sort` call needed.
  - [x] 3.2: `BPMAnalyzer.estimateBPM` harmonic-ratio detail (write site `BPMAnalyzer.swift:378-385`):
    - Replace the `[String: String]` dictionary literal (lines 379-384) with `trace?.harmonicRatioDetail = ev` (direct assignment of the existing `HarmonicRatioEvidence` value `ev` — no conversion needed since the type is now the public `HarmonicRatioEvidence`).
  - [x] 3.3: `BPMAnalyzer.estimateBPM` sub-band vote detail (write site `BPMAnalyzer.swift:393-400`):
    - Replace the `[String: String]` dictionary literal (lines 395-399) with `trace?.subBandVoteDetail = SubBandVoteEvidence(preVoteBPM: preVoteBPM, postVoteBPM: winner.bpm, changed: changed)`.
  - [x] 3.4: `BPMAnalyzer.applyDurationHint` duration-hint detail (write site `BPMAnalyzer.swift:2155-2186`):
    - Replace the `var detail: [String: String] = [:]` accumulator (lines 2155-2186) with three local accumulators: `var fileDurationSecondsValue: Double = 0`, `var barCandidatesValue: [BPMDiagnosticTrace.BarCandidate] = []`, `var boostedCandidatesValue: [Double] = []`.
    - Build them inline: replace `detail["fileDurationSeconds"] = String(format: "%.1f", fileDurationSeconds)` with `fileDurationSecondsValue = fileDurationSeconds` (full Double precision).
    - Replace `detail["barCandidates"] = barCandidates.map { ... }.joined(separator: ",")` with `barCandidatesValue = barCandidates.map { BPMDiagnosticTrace.BarCandidate(bars: $0.bars, bpm: $0.bpm) }`.
    - Replace `detail["boostedCandidates"] = boostedBPMs.map { ... }.joined(separator: ",")` with `boostedCandidatesValue = boostedBPMs` (already `[Double]`).
    - Replace `trace?.durationHintDetail = detail` with `trace?.durationHintDetail = DurationHintEvidence(fileDurationSeconds: fileDurationSecondsValue, barCandidates: barCandidatesValue, boostedCandidates: boostedCandidatesValue)`.

- [x] **Task 4: Update consumer assertion sites in tests** (AC: #4)
  Run `grep -rn 'clickCorrelationDetail\|harmonicRatioDetail\|subBandVoteDetail\|durationHintDetail' Tests/` BEFORE editing to capture the complete consumer set; then update each match. Inventory at story-create time (304 tests, baseline SHA `3c70345`):
  - [x] 4.1: `Tests/BoomBoomBoomKitTests/BPMAnalyzerClickTrackTests.swift` — three tests at lines 330, 371, 384.
  - [x] 4.2: `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift:902-914` — `traceSubBandVoteDetail`. Replaced three nil-checks with one `try #require` unwrap + typed-property assertions including `detail.changed == (detail.preVoteBPM != detail.postVoteBPM)`.
  - [x] 4.3: `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift:1785-1798` — `traceHarmonicRatioDetail`. Replaced four key-existence checks with `["2:1", "3:2", "3:1"].contains(detail.ratio)` + `>0` checks on the three BPM fields.
  - [x] 4.4: `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` — line 218 nil-check unchanged; lines 232-234 `!detail.isEmpty` works unchanged on the new array type; lines 467-473 migrated to typed-property access.
  - [x] 4.5: `Tests/BoomBoomBoomKitTests/BPMAnalyzerDurationHintTests.swift` — heaviest single-file impact. All ~10 dictionary lookups migrated to typed access. CSV substring checks like `boosted.contains("128.0")` became typed `[Double]` membership `boosted.contains(128.0)`; `?["boostedCandidates"] == ""` became `?.boostedCandidates.isEmpty == true`.
  - [x] 4.6: Final sweep (`grep -rn '\["fileDurationSeconds"\]\|\["barCandidates"\]\|\["boostedCandidates"\]\|\["preVoteBPM"\]\|\["postVoteBPM"\]\|\["changed"\]\|\["ratio"\]\|\["fastBPM"\]\|\["slowBPM"\]\|\["winner"\]' Tests/ Sources/`) returned **0 matches** after the migration. One stale doc-comment reference in `BPMAnalyzer.swift:2127` was also cleaned up.

- [x] **Task 5: Add new collision regression test** (AC: #2, #3)
  - [x] 5.1: New file `Tests/BoomBoomBoomKitTests/BPMDiagnosticTraceTests.swift` with `@Suite("BPMDiagnosticTrace — Story 3-3b trace key namespacing")` and `@testable import BoomBoomBoomKit`.
  - [x] 5.2: Test `clickRescoreCollisionScenarioPreservesDistinctEntries` — pure-helper-driven (no synthetic click track needed; the test exercises `clickRescore` directly with hand-crafted candidates `[(61.04, 0.5), (60.95, 0.5)]` against a synthetic 2000-frame impulse envelope, asserts both entries present with exact `Double` equality on `bpm`).
  - [x] 5.3: Test `clickCorrelationEntriesPreserveCandidateIndexOrder` — 5 candidates in non-monotonic BPM order; asserts `entries.map(\.candidateIndex) == Array(0..<entries.count)`.
  - [x] 5.4: Test `customStringConvertibleForAllFourTypes` — builds one instance of each public typed type (`ClickCorrelationEntry`, `HarmonicRatioEvidence`, `SubBandVoteEvidence`, `DurationHintEvidence`, `BarCandidate`) and verifies `String(describing:)` contains the meaningful field values.

- [x] **Task 6: Validate** (AC: #5, #6)
  - [x] 6.1: `make fmt` — clean.
  - [x] 6.2: `make lint` — 1 violation, all pre-existing (`Sources/BoomBoomBoomKit/LUFSAnalyzer.swift:94` TODO violation, untouched by this story; project-context.md L76 documents that TODO violations are intentional). Zero NEW violations.
  - [x] 6.3: `make test` — **307 tests passed** (was 304 baseline; +3 from new `BPMDiagnosticTraceTests.swift`). `> 304` ✓.
  - [x] 6.4: `make benchmark` — OA300 **Acc1=69.5%, Acc2=89.0%** (57/82, 73/82). Byte-identical to CLAUDE.md baseline ("OA300 corpus (Acc1=69.5%, Acc2=89.0%)"). ✓
  - [x] 6.5: `make benchmark-giantsteps` — GiantSteps **Acc1=81.2%, Acc2=82.6%** strict; **84.1%/85.0%** MIREX (4% tolerance). DSP path unchanged (proven by OA300 byte-equality); benchmarks run with `enableTrace=false`, so trace migrations could not affect numbers. ✓
  - [x] 6.6: `make oracle` — passed; no DAW oracle regression on three-way comparison.
  - [x] 6.7: Manually inspected the five new public types' DocC headers in `BPMDiagnosticTrace.swift`. All have `///` doc comments with property-level docs; render cleanly. (`swift package generate-documentation` is not configured in this repo.)

- [x] **Task 7: Validate the `bpm-diagnostic-trace` skill** (AC: #8)
  - [x] 7.1: Read `.claude/skills/bpm-diagnostic-trace/SKILL.md` end-to-end. Every type referenced in the "Required pattern" section (`ClickCorrelationEntry`, `SubBandVoteEvidence`, `DurationHintEvidence`, `BarCandidate`, `HarmonicRatioEvidence`) exactly matches the post-migration implementation. No drift; no skill update needed.
  - [x] 7.2: **Recipe A** — `grep -nE 'public var [a-zA-Z]+Detail: \[String: (Float|String|Int|Double|Bool)\]' Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` → exit code 1 (zero matches). ✓
  - [x] 7.3: **Recipe B** — `grep -nrE 'String\(format: ?"%\.1f", ?[a-zA-Z]+\.bpm\)' Sources/BoomBoomBoomKit/` → exit code 1 (zero matches). No `%.1f` BPM stringification anywhere in `Sources/`. ✓
  - [x] 7.4: **Recipe C** — `grep -nrE 'trace\?\.[a-zA-Z]+Detail.*joined\(separator:' Sources/BoomBoomBoomKit/` → exit code 1 (zero matches). ✓
  - [x] 7.5: **Recipe D** — `grep -rnE 'Detail\?\[\"' Tests/BoomBoomBoomKitTests/` → exit code 1 (zero matches). `grep -rnE 'Detail\[\"' Tests/BoomBoomBoomKitTests/` → exit code 1 (zero matches). ✓
  - [x] 7.6: **Recipe E** — `grep -nE 'public struct [A-Z][a-zA-Z]*Evidence' Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift | grep -v ': Sendable'` → exit code 1 (zero matches). All three `*Evidence` structs declare `Sendable`. ✓
  - [x] 7.7: Retrospective on the 10-step checklist. Steps 1, 2, 4, 5, 6, 7, 8 mapped 1:1 onto the work I did. Step 3 ("Add a `// MARK: - Step N: <name>` header above the field declaration") was looser than my actual approach: I grouped the five types under one `// MARK: - Trace Evidence Types (Story 3-3b)` header at the bottom of the file instead of placing one MARK above each new type. Both are reasonable layouts — single grouped MARK is the right choice when introducing a cluster of related types in one commit. Steps 9–10 are conditional (skill update / project-context.md update) and didn't apply because the canonical pattern was already documented. The checklist worked correctly; no skill revisions needed.

### Review Findings

- [x] [Review][Patch] Update stale `clickRescore` trace doc comment [Sources/BoomBoomBoomKit/BPMAnalyzer.swift:1934] — Fixed by replacing the removed dictionary-key description with typed `ClickCorrelationEntry` trace-population docs.
- [x] [Review][Patch] Stage or apply Dev Agent Record completion notes [_bmad-output/implementation-artifacts/3-3b-trace-key-namespacing.md:274] — Fixed by carrying the completed Dev Agent Record into the final story artifact.
- [x] [Review][Patch] Sync staged sprint status to story review state [_bmad-output/implementation-artifacts/sprint-status.yaml:67] — Fixed by syncing sprint status with the story close-out state.

## Dev Notes

### Architecture compliance

- **Public API boundary**: `BPMDiagnosticTrace` is already public (architecture.md, project-context.md). Adding four new public nested types (`ClickCorrelationEntry`, `SubBandVoteEvidence`, `DurationHintEvidence`, `BarCandidate`) and promoting one internal type (`HarmonicRatioEvidence`) is a **public API addition**. Per project-context.md ("Never promote internal types to public … without explicit design decision"), this story IS the explicit design decision. The decision is sound because:
  1. Pre-1.0 library, zero external consumers.
  2. The schema's prior shape (`[String: …]?`) was already public — replacing it with a typed schema does not change the surface area, only its type.
  3. The trace doc comment explicitly says **"evolving API — fields may change across versions"** (`BPMDiagnosticTrace.swift:6, 14`). This story is the deliberate evolution.
- **Swift 6 concurrency**: All new types must conform to `Sendable`. `Double`, `Float`, `Int`, `Bool`, `String`, `[T]` (when `T: Sendable`) are all Sendable; struct conformance is automatic when stored properties are Sendable. Add `: Sendable` explicitly to satisfy `Sendable` strict-concurrency mode.
- **Value-types-only invariant** (project-context.md L32): all four new types are structs. No classes.
- **Field-style convention**: All four trace fields stay optional (`T?`) because their absence-of-data semantics are well-defined — trace not requested ⇒ field is nil.
- **Single source of truth for the four types**: colocate all five new public types (`ClickCorrelationEntry`, `HarmonicRatioEvidence`, `SubBandVoteEvidence`, `DurationHintEvidence`, `BarCandidate`) inside `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift`. Do not split into per-type files. The trace struct is the only owner; the types are intrinsically scoped to it.
- **Promotion of `HarmonicRatioEvidence`**: this is the only **internal-to-public** promotion in this story. Currently nested inside `BPMAnalyzer` (line 1551), with internal access. Action: physically move the declaration out of `BPMAnalyzer.swift` and into `BPMDiagnosticTrace.swift`; change visibility to `public`. The four construction sites at `BPMAnalyzer.swift:1595-1635` use unqualified `HarmonicRatioEvidence(...)` and resolve to the module-scope type after the move (verify by `grep -n "HarmonicRatioEvidence" Sources/` after the edit — the only matches should be the relocated definition and the four constructor calls).

### Source pointers (verified at story-create time, SHA `3c70345`)

**Production code:**
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:64-103` — all four trace field declarations.
  - L64-65: `subBandVoteDetail` doc + declaration L66.
  - L68-70: `harmonicRatioDetail` doc + declaration L71.
  - L75-79: `clickCorrelationDetail` doc + declaration L80.
  - L84-102: `durationHintDetail` doc + declaration L103. **L101-102 contains the self-referential "Story 3-3b" deferral that this story closes.**
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:378-385` — `harmonicRatioDetail` write site.
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:393-400` — `subBandVoteDetail` write site.
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:1551-1556` — internal `HarmonicRatioEvidence` struct definition (move target).
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:1595, 1615, 1625, 1633` — four `HarmonicRatioEvidence(...)` constructor sites (will resolve to public type post-move).
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:2002, 2020, 2032, 2057, 2061` — `clickCorrelationDetail` write sites (5 lines: detail var init, two empty-skip writes, the main write, the trace assignment).
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:2155-2186` — `applyDurationHint` write site (heaviest write — three CSV-serialized fields).

**Test code (must update):**
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:218,232-233,452-492` — 5+ references.
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerClickTrackTests.swift:328-392` — 6 references across 3 tests.
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift:902-915` — 5 references in one test (4 dict-key lookups).
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift:1785-1798` — 5 references in one test (4 dict-key lookups).
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerDurationHintTests.swift:38-43,59,160,183,207,265,319-325,341` — 8+ references; heaviest single-file impact.

### Risk / out-of-scope guards

- **This is a public API breaking change** for the trace schema across four fields. Pre-1.0 + zero external consumers + BC not a goal. Land it as a single atomic commit titled `Story 3-3b - close out: trace-key namespacing across BPMDiagnosticTrace` (matching the recent commit-message convention — see `Story 3-6b - close out: ...` from SHA `c88d727`).
- **This story does NOT change DSP behavior.** Any accuracy delta on OA300 / GiantSteps / DAW oracle is a bug. AC #5 enforces byte-for-byte equality.
- **This story does NOT change the trace's other fields** (`subBandEnergies`, `acfTopLags`, `tempogramTopBPMs`, `fusedTopBPMs`, `tps2TopBPMs`, `rawCandidates`, `disambiguationResult`, `refinedBPM`, `confidence`, `intensityUsed`, `metadataEvidenceBeforeBoost`, `candidatesBeforeBoost`, `candidatesAfterBoost`, `metadataPolicyUsed`). Those use already-typed shapes.
- **This story does NOT touch the corroboration logic or any merge strategy.** Story 3-6's `metadataEvidenceBeforeBoost` already uses a typed `[MetadataBPMEvidence]` (good prior art for what the new shapes should look like).
- **No new files in `Sources/`.** All new types colocate inside `BPMDiagnosticTrace.swift`. The only file changes in `Sources/` are: `BPMDiagnosticTrace.swift` (add types, change four field types), `BPMAnalyzer.swift` (delete the moved-out `HarmonicRatioEvidence` definition, update four write sites). One new file in `Tests/`: `BPMDiagnosticTraceTests.swift`.
- **The `BPMDiagnosticTrace.swift:14` header note already says "evolving API"** — this story is a deliberate evolution that fixes a pre-existing latent correctness issue and improves API hygiene.
- **Do NOT extend the migration to other trace fields opportunistically.** The four `[String: …]?` fields are the closed scope. Other fields (`subBandEnergies: [String: Float]` for example, where keys are stable strings like `"kick"`/`"snare"`) are out of scope.

### Previous story intelligence (Story 3-6b learnings — close out 2026-05-02, SHA `c88d727`)

Story 3-6b shipped this week and exhibits the patterns this story should follow:
- **Single atomic commit** for the close-out (precedent: `c88d727`). Code-review patches that surface during review land in the same commit by amending or by a same-day follow-up commit ("Story X-Y - close out: code-review patches" pattern).
- **Pre-implementation review pass is now a story-creation deliverable**, not a separate workflow. Story 3-6b's `## Background → Secondary review pass` section folded ALL findings into ACs before kickoff. This story has been authored with that pass already done (see "Risk / out-of-scope guards" above and the full four-field scope of AC #1).
- **Test count is reported as monotonic increase, not a fixed floor** (3-6b learning; AC #6 here adopts that pattern).
- **Helper-extraction to satisfy "no drift between test and production code"** (3-6b AC #5 pattern). Not directly applicable here — this story doesn't add a public service helper — but the principle ("test asserts via the same code path the production uses") is why AC #2 invokes `BPMAnalyzer.clickRescore` directly via `@testable import` rather than reconstructing the rescoring logic in the test.
- **`Sendable` conformance is non-negotiable** for any new public type per project-context.md L20.

### Git intelligence (last 10 commits)

The recent history shows clean per-story commits:
- `c88d727 Story 3-6b - close out: metadata parser hardening + drift-resistant disabled-policy test`
- `9f8f2b9 Story 3-5 - close out: configurable window voting policy`
- `ba6ba52 Story 3-4 - close out: duration-derived BPM hint + code-review patches`
- `f0c5b9e Story 3-3a - close out: code-review patches, ADR-11 reconciliation, sentinel mock guard`
- `137de7c Add ADR-11, re-author Story 3-3a, create 3-3b + benchmark-infra stories` ← **this story's creation point**

The 3-3b draft was authored on 2026-04-26 alongside ADR-11 work; intervening stories (3-4, 3-5, 3-6, 3-6b) added/modified the trace schema in ways the original draft didn't anticipate. **The most consequential drift is Story 3-4 introducing `durationHintDetail`** with the same `%.1f` pattern AND a self-referential doc comment that names this story. The freshly-authored AC set above incorporates that fourth field.

### Latest tech information

- **Swift 6.0 strict concurrency**: All new public types in this story are pure-value-type structs of `Sendable`-conformant primitives. No `@MainActor`, no actors, no `nonisolated(unsafe)` required.
- **`CustomStringConvertible` (Swift stdlib)**: standard since Swift 1; conforming type just needs `var description: String { … }`. Public conformance because `description` is the LLDB / `print()` workhorse and library consumers will rely on it.
- **No new imports needed**. `BPMDiagnosticTrace.swift` already imports `Foundation`; `BPMAnalyzer.swift` already imports `Accelerate`. The new types use only stdlib types (`Int`, `Double`, `Float`, `Bool`, `String`, `Array`, `Optional`).
- **Documentation comments**: use `///` triple-slash with `- Parameters:` / `- Returns:` for any public init or method that takes parameters; for plain stored-property structs the per-property `///` comment is sufficient (matches the existing convention in `BPMDiagnosticTrace.swift`).

### Project context reference

- **Code organization** (project-context.md L42): `// MARK: - Section` headers are mandatory. Add MARKs for each new type group inside `BPMDiagnosticTrace.swift`.
- **File header** (project-context.md L78): six-line standard header. The existing `BPMDiagnosticTrace.swift` header (lines 1-7) is correct; do not modify.
- **Imports** (project-context.md L79): explicit per file. No new imports are required for this story.
- **Build verification** (project-context.md L90): `make build` + `make test` must pass before committing.
- **`make fmt` then `make lint`** (project-context.md L74): always in this order.
- **No coupling to AI tooling** (project-context.md L88): library code in `Sources/` must build and test cleanly with only SPM. This story touches only `Sources/` and `Tests/` — verify by running `swift build && swift test --parallel --filter BoomBoomBoomKitTests` after edits.

### References

- [Source: `_bmad-output/implementation-artifacts/3-3-click-track-cross-correlation.md:210`] — origin of the deferred trace-key collision finding.
- [Source: `_bmad-output/implementation-artifacts/3-3-click-track-cross-correlation.md:430`] — close-out note recording the deferral split into this story.
- [Source: `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:14`] — file header explicitly notes "evolving API."
- [Source: `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:101-102`] — Story 3-4's self-reference deferring the duration-hint trace fix to this story.
- [Source: `_bmad-output/planning-artifacts/architecture.md`] — public API boundary.
- [Source: `_bmad-output/project-context.md:38`] — "Never promote internal types to public without explicit design decision" → the design decision for `HarmonicRatioEvidence` is AC #1 of this story.
- [Source: `_bmad-output/implementation-artifacts/3-6b-metadata-parser-hardening.md`] — pattern for two-pass authored stories with secondary-review folded in pre-kickoff.

## Dev Agent Record

### Agent Model Used

`claude-opus-4-7` (Claude Opus 4.7, 1M context).

### Debug Log References

No HALTs. SourceKit diagnostics during the test-file edits showed stale-module false positives (`[String: String] has no member …`) that resolved on the next `swift build` because the module had not yet been recompiled when the LSP server checked the test files. The actual `swift build --target BoomBoomBoomKitTests` completed cleanly each time.

### Completion Notes List

- **Test count:** 307 passing (was 304 baseline; +3 from new `BPMDiagnosticTraceTests.swift`). Monotonic increase satisfied.
- **OA300 accuracy (AC #5):** `maxConfidence` strategy: **Acc1=69.5% (57/82), Acc2=89.0% (73/82)** — byte-identical to the CLAUDE.md baseline ("OA300 corpus (Acc1=69.5%, Acc2=89.0%)"). All 8 merge strategies and 3 voting policies × 4 thresholds also unchanged.
- **GiantSteps accuracy (AC #5):** Strict (2% tolerance): **Acc1=81.2% (537/661), Acc2=82.6% (546/661)**. MIREX (4% tolerance): **Acc1=84.1% (556/661), Acc2=85.0% (562/661)**. DSP path unchanged (OA300 byte-equality proves this); benchmarks run `enableTrace=false`, so trace-write migrations cannot affect numbers.
- **DAW oracle (AC #5):** passed; no three-way regression vs. Rekordbox or DAW-verified ground truth.
- **Audit recipes A–E (AC #8):** all five returned **0 matches** against `Sources/` and `Tests/`. No `%.1f` stringification of BPM values anywhere in the codebase; no CSV serialization in trace writes; no string-key indexing on detail fields in tests; all `*Evidence` structs declare `Sendable`.
- **Skill validation retrospective (Task 7.7):** the 10-step checklist mapped accurately onto the work. Step 3 ("`// MARK:` header above each field declaration") was loose — I grouped the five new types under a single `// MARK: - Trace Evidence Types (Story 3-3b)` at the bottom of `BPMDiagnosticTrace.swift` instead of one MARK per type. This is a reasonable layout for "introduced together in one commit," and the checklist's intent (clear MARK organization) is satisfied. No skill revisions needed.
- **No new dependencies, no new error types, no DSP changes.** Pure trace-API shape migration. `swift build` clean; `make fmt` clean; `make lint` produced 1 pre-existing TODO violation (in untouched `LUFSAnalyzer.swift:94` — project-context.md L76 documents that TODO violations are intentional reminders).
- **Public API surface changes:** five new public types (`ClickCorrelationEntry`, `HarmonicRatioEvidence`, `SubBandVoteEvidence`, `DurationHintEvidence`, `BarCandidate`) all `Sendable, CustomStringConvertible`. One internal-to-public promotion (`HarmonicRatioEvidence` relocated from `BPMAnalyzer.swift:1551-1556` to `BPMDiagnosticTrace.swift`). Four `BPMDiagnosticTrace` field types changed from `[String: …]?` to typed shapes — public schema break, intentional, single atomic commit.
- **Code-review patches:** fixed stale `clickRescore` trace documentation, carried completed Dev Agent Record details into the staged story artifact, and synced sprint status to `done`.

### File List

- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` — modified. Added 5 public typed-evidence structs at the bottom under `// MARK: - Trace Evidence Types (Story 3-3b)`. Replaced four `[String: …]?` field declarations with typed shapes; rewrote doc comments. Removed Story 3-4's self-reference deferral note (lines 101-102 in the pre-change file).
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` — modified. Deleted the relocated `HarmonicRatioEvidence` struct definition (was at L1551-1556). Rewrote four trace write sites: `harmonicRatioDetail` (now direct `ev` assignment), `subBandVoteDetail` (typed `SubBandVoteEvidence` constructor), `clickCorrelationDetail` (typed `[ClickCorrelationEntry]` accumulator with `candidateIndex` carrying input order), `applyDurationHint` (typed `DurationHintEvidence` constructor with sub-typed `[BarCandidate]`). Cleaned one stale doc-comment reference at L2127 that quoted the old dictionary shape.
- `Tests/BoomBoomBoomKitTests/BPMDiagnosticTraceTests.swift` — **new file**. `@Suite("BPMDiagnosticTrace — Story 3-3b trace key namespacing")`. Three tests: collision regression (61.04 vs 60.95), order stability (5-candidate `candidateIndex` map), and `CustomStringConvertible` smoke for all five public types.
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` — modified. Updated `durationHint=true` test (lines 467-473 in pre-change file) from CSV substring checks to typed-property access.
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerClickTrackTests.swift` — modified. Updated `tracePopulatesDetail` (line 343 area) from `detail["120.0"]` dict-key form to `detail.first(where: { $0.bpm == 120.0 })` array form.
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift` — modified. `traceSubBandVoteDetail` (~L902) and `traceHarmonicRatioDetail` (~L1785) rewritten to use typed properties.
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerDurationHintTests.swift` — modified. ~10 dict-key lookups across the file converted to typed-property access; CSV substring checks (`boosted.contains("128.0")`) replaced with typed `[Double]` membership (`boosted.contains(128.0)`).
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — modified. Story status flipped `ready-for-dev` → `in-progress` → `review` → `done`.
- `.claude/skills/bpm-diagnostic-trace/SKILL.md` — already exists at story-creation time. Validated end-to-end against the post-migration code in Task 7.1; no revisions needed.

## Change Log

- 2026-04-26 (Story 3-3b creation): Authored as a follow-up to Story 3-3's deferred trace-key collision finding. Status: `backlog`. Sprint-status entry added. Commit `137de7c`.
- 2026-05-02 (Story 3-3b ready-for-dev): Re-authored after Stories 3-4/3-5/3-6/3-6b shipped. Scope expanded from three trace fields to four (added `durationHintDetail` from Story 3-4 — see Background table). Source-pointer line numbers refreshed against SHA `3c70345`. Test consumer inventory expanded to five test files (including the heavy `BPMAnalyzerDurationHintTests.swift` impact). Test-count baseline updated to 304. AC #7 added (CustomStringConvertible).
- 2026-05-02 (Story 3-3b scope expansion): AC #8 + Task 7 added covering a project-local Claude Skill at `.claude/skills/bpm-diagnostic-trace/SKILL.md`. Skill authored at story-creation time and committed alongside this update; the skill encodes the typed-evidence pattern, the four banned anti-patterns, five audit grep recipes (A–E), a 10-step checklist for new trace fields, and a modification checklist. Task 7 is dev-agent validation that the skill matches the post-migration code and that all five audit recipes return zero matches against `Sources/` and `Tests/`. Status: `ready-for-dev`.
- 2026-05-03 (Story 3-3b implementation complete): Tasks 1–7 done. Five public typed-evidence structs added; four trace field declarations migrated; four producer write sites rewritten; five consumer test files updated; new `BPMDiagnosticTraceTests.swift` adds 3 tests (collision regression + order stability + CustomStringConvertible smoke). Test count 304 → 307. OA300 byte-identical at Acc1=69.5%/Acc2=89.0%. GiantSteps Acc1=81.2%/Acc2=82.6% (strict). DAW oracle clean. All five audit recipes (A–E) return 0 matches. Status: `review`.
- 2026-05-03 (Code review patches applied): Resolved 3 patch findings from BMAD code review: stale `clickRescore` trace doc comment fixed, Dev Agent Record completion notes carried into the staged story artifact, and sprint status synchronized. Status: `done`.
