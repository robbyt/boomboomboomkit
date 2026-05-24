# Sprint Change Proposal — Story 5-6 Review-Findings Reconciliation

Date: 2026-05-23
Author: Dev agent (via `/bmad-correct-course` after `/code-review` + party-mode triage + Codex meta-review)
Scope: Story 5-6 (`5-6-end-user-ui-redesign`, status: `review`)
Trigger: `/code-review` surfaced 15 verified defects; workflow terminated at JSON output without applying findings to the story spec or planning fixes.

Revision history:
- v1 (2026-05-23) — initial draft from party-mode triage (Mary + John + Amelia + Paige).
- v2 (2026-05-23) — applied 5 Codex meta-review revisions: §4.1 F09 test update + stale-inspector doc, §4.2 surgical pbxproj plan, §4.4 / §4.6 deferred-work.md integration, F04/F07 reclassified as explicit accepted-AC-violation deferrals, §5 sequencing (Paige first, F09 last).
- v3 (2026-05-23) — applied 7 finalization revisions from Codex thread `019e5619-aa1b-7cc3-84e7-6579dd614712` + Apple-docs MCP API validation:
  - Apple-docs: corrected F07 Color initializer spelling (`Color(NSColor.windowBackgroundColor)` → `Color(nsColor: .windowBackgroundColor)`) — the original spelling would silently resolve to the asset-catalog overload.
  - Apple-docs: F07 must use TWO different dynamic colors for a visible gradient (`.windowBackgroundColor` → `.underPageBackgroundColor`); same color twice = flat fill.
  - Apple-docs: F14 hint text "Drop" → "Drag here" per macOS HIG / AppKit VoiceOver vocabulary.
  - Apple-docs: confirmed R2's SceneStorage claim is wrong-by-omission; Paige adds an honest R2 correction to Phase 1 spec edits.
  - Codex: F10 (DEAD_CODE_STRIPPING) lands in Phase 2, not 5-6b — preserving then reverting is churn.
  - Codex: W28 closure stays inline in its Story-5-3 origin section (matches W14/W16/W17/W30 pattern).
  - Codex: Phase 1 Review Findings table uses `planned-fix` status; Phase 5 flips to `fixed`.

---

## Section 1 — Issue Summary

`/code-review` was run against `_bmad-output/implementation-artifacts/5-6-end-user-ui-redesign.md` after the dev agent flipped status to `review`. The xhigh-effort 5-angle + Codex blind-hunter workflow produced 15 verified findings (13 CONFIRMED + 1 PLAUSIBLE + 1 from sweep), then printed a JSON array and exited. No findings were written into the story spec; no fix plan was generated.

Party-mode round (2026-05-23, Mary + John + Amelia + Paige) diagnosed the gap and produced a triage. Codex meta-review (2026-05-23, thread `019e5619-aa1b-7cc3-84e7-6579dd614712`) validated triage soundness and identified 5 concrete revisions to apply before execution — all incorporated below.

- **Root cause** (Mary): The `/code-review` slash command is a stateless analyzer — Phases 1-3 (hunt → verify → rank). It has no Phase 4 (reconcile findings to story artifact). It also doesn't take a story path as input, so it cannot know where to write back.
- **JTBD framing** (John): `/code-review` did its job (find bugs). The user's expectation (close out the story) is a different job that belongs to `bmad-correct-course` or `bmad-code-review` (the story-aware BMAD variant). Do NOT retrofit the generic plugin to chain into BMAD.
- **Concrete plan** (Amelia): Bucket the 15 findings into MUST-FIX-now, MUST-DEFER-to-5-7, SHOULD-FIX-in-follow-up-story.
- **Audit structure** (Paige + Codex correction): Add a `### Review Findings` table to Story 5-6's Dev Agent Record AND record every deferred F-ID in the project's canonical deferral ledger at `_bmad-output/implementation-artifacts/deferred-work.md` (precedent: Story 5-2 W## entries; current ledger high-water W32).

The 15 findings, ranked by severity:

| F-ID | Severity | File:Line | Summary |
|---|---|---|---|
| F01 | blocker | `project.pbxproj:412` | PRODUCT_BUNDLE_IDENTIFIER renamed `com.robbyt.BoomBoomBoomKitDemo`→`com.robbyt.BoomBoomBoom`; INFOPLIST_KEY_CFBundleDisplayName=`BoomBoomBoom`. Contradicts Story 5-7 KDD #4 + Story 5-6 R2. |
| F02 | major | `ContentView.swift:332` | AC #3 metadata stack missing `row.intensity` + "Result captured at" caption. |
| F03 | major | `ContentView.swift:327` | `Font.system(size: 96)` does NOT scale with Dynamic Type; KDD #4 / AC #2 contract false. |
| F04 | major | `EmptyStateView.swift:23` | AC #12 violated: `.frame(maxHeight: .infinity)` competes with parent `Spacer()` — fills only upper half. |
| F05 | blocker | `project.pbxproj` + `AppIcon.icon/` | Scope creep: AppIcon (2 MB), bundle ID, display name landed despite OUT-OF-SCOPE → Story 5-7. |
| F06 | major | `ContentView.swift:177` | Picker renders `Text(strategy.rawValue)` (camelCase); `humanize(_:)` already exists. Closes pre-existing W28. |
| F07 | major | `StrategyBackground.swift:66` | AC #6/#7 violated: `Color(white:)` static; `.none` neutral case breaks in Dark Mode. |
| F08 | blocker | `project.pbxproj:246` | MACOSX_DEPLOYMENT_TARGET 15.0→15.6 silently; Package.swift still `.v15`. |
| F09 | minor | `ContentView.swift:41` | `triggerReanalyze()` flips `backgroundStrategy` to nil mid-run — gradient flashes neutral. |
| F10 | minor | `project.pbxproj:245` | `DEAD_CODE_STRIPPING=YES` on test target risks Swift Testing reflection. |
| F11 | minor | `ContentView.swift:55` | `.dropDestination` doesn't `.ignoresSafeArea()` but gradient does; visual/hit-test mismatch. |
| F12 | minor | `ContentView.swift:87` | Toolbar Button no `.accessibilityValue` for toggle state. |
| F13 | minor | `EmptyStateView.swift:21` | `.foregroundStyle(.tertiary)` but KDD #5 specs `.secondary`. |
| F14 | minor | `EmptyStateView.swift:12` | No `.accessibilityElement(.combine)` + no `.accessibilityHint`. |
| F15 | nit | `TraceView.swift:325` | "Drop an audio file to analyze" vs new "Drop a track" — copy mismatch. |

---

## Section 2 — Impact Analysis

**Epic Impact:** Epic 5 (Developer Experience). Story 5-6 cannot advance past `review` until findings reach terminal states. Story 5-7 inherits explicit carry-over from 5-6.

**Story Impact (post-revision):**

- **Story 5-6** — stays `review`; gains a `### Review Findings` sub-section in Dev Agent Record. F02/F03/F06/F09/F10/F15 fixed in-place (F10 promoted to Bucket 1 per Codex v3 review). F04/F07/F11/F12/F13/F14 deferred to new story `5-6b-a11y-polish` AS EXPLICIT ACCEPTED-AC-VIOLATION DEFERRALS (F04→AC #12, F07→AC #6/#7, F13→KDD #5) — close-out gate explicitly accepts these violations with cross-link to 5-6b. F01/F05/F08 deferred to Story 5-7. Every deferral mirrored as a W## entry in `deferred-work.md`. Paige also corrects R2 wording (SceneStorage default-flip cohort impact) per Apple-docs MCP API 7 finding.
- **Story 5-7** (currently `ready-for-dev`) — gains a `## Carry-over from Story 5-6` appendix referencing F01, F05, F08. Existing 5-7 KDD #4/#5 already forbid bundle-ID + display-name rename — the appendix MUST state that 5-6's pbxproj rename was reverted and that 5-7 must NOT reintroduce. F08 gets new KDD #9 + AC #12 explicitly capturing the Package.swift `.v15` ↔ demo MACOSX_DEPLOYMENT_TARGET lockstep decision.
- **New Story 5-6b** (`5-6b-a11y-polish`) — to be created. Scope: F04, F07, F11, F12, F13, F14 (F10 promoted to Bucket 1 in 5-6, removed from 5-6b scope). Est. ~25 LOC across 2 Swift files (was ~30 LOC pre-F10-promotion). Each finding cross-links back to its accepted-violation entry in Story 5-6's Review Findings table.
- **`deferred-work.md`** (project canonical ledger per Story 5-2 precedent) — gains new section `## Deferred from: code review of 5-6-end-user-ui-redesign (2026-05-23)` with entries W33-W42 (one per F-ID, regardless of bucket; closed-state entries inline-annotated per existing pattern). W28 closure annotation lands inline in its original Story-5-3 section (matches W14/W16/W17/W30 pattern, NOT moved to the new 5-6 section). The story-spec `### Review Findings` table is the per-story snapshot; the ledger is the project-wide search target. Both must stay in sync.

**Artifact Conflicts:**

- `_bmad-output/implementation-artifacts/sprint-status.yaml` — needs new entry for `5-6b-a11y-polish: backlog`; 5-6 stays `review`.
- `_bmad-output/planning-artifacts/epics.md` — Epic 5 list grows by one story (5-6b inserted between 5-6 and 5-7).
- `_bmad-output/implementation-artifacts/5-7-app-store-submission-readiness.md` — Carry-over appendix added; KDD #9 + AC #12 added.
- `_bmad-output/implementation-artifacts/deferred-work.md` — new W33-W42 entries; also closes pre-existing W28 (Picker camelCase) since F06 fixes it.
- No PRD, architecture, or UX-spec changes (Story 5-6 was demo-app only; no library API impact).

**Technical Impact:**

- **Bucket-2 surgical revert** (per §4.2 below — NOT a `git checkout HEAD -- pbxproj` blanket): unstages specifically the bundle-ID rename, display-name change, LSApplicationCategoryType, AppIcon.icon catalog rename, INCLUDE_ALL_APPICON_ASSETS=YES, and restores all six configs to `MACOSX_DEPLOYMENT_TARGET = 15.0`. Preserves DEVELOPMENT_TEAM blank, CODE_SIGN_IDENTITY/PROVISIONING_PROFILE_SPECIFIER removal (Story 5-6's original surgical revert), `LastUpgradeCheck 2630→2650` (cosmetic Xcode auto-injection), `STRING_CATALOG_GENERATE_SYMBOLS=YES` (cosmetic Xcode auto-injection), `DEAD_CODE_STRIPPING=YES` (F10 — 5-6b will revert this).
- **Bucket-1 fix commits** (~7 net LOC across ContentView.swift, TraceView.swift, AnalysisViewModel.swift + 1 test update): addresses 5 in-scope AC violations.
- **F09 test update** required (Codex finding): `Demo/.../BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift:867-883` (`lastRunSnapshotResetOnAnalyzePrologue`) explicitly asserts `lastRunSnapshot == nil` synchronously after `analyze()` starts. F09 removes that prologue-clear behavior; the test must be inverted or deleted.
- **No library changes** — `Sources/**` and `Tests/**` remain zero-diff (the test update is under `Demo/` not `Tests/`).
- **Pre-commit gauntlet** (`make demo-fmt demo-lint demo-build demo-test pre-commit`) re-runs after Bucket-1.

---

## Section 3 — Recommended Approach

**Path: Direct Adjustment + One New Story**

Combines John's path-1 (use existing BMAD triage tooling, don't retrofit `/code-review`) with Amelia's 3-bucket execution plan, Paige's audit-structure schema, and Codex's 5 revisions.

**Rationale:**

- 5 of 15 findings are explicit AC violations or release-blockers fixable inside Story 5-6's stated scope — Direct Adjustment is the cheapest path.
- 3 findings (bundle ID, AppIcon, deployment target) are scope creep that already has a home — Story 5-7's existing KDDs forbid the changes; Story 5-6 must un-do them.
- 7 findings are real defects (3 are AC violations, 4 are polish) deferred to `5-6b-a11y-polish`. Three of those (F04, F07, F13) are explicit accepted AC violations — Story 5-6 close-out gate acknowledges this transparently rather than re-labeling as polish.

**Effort Estimate (revised after Codex):**

- §4.2 Bucket-2 surgical revert: 30 min (more careful than initial estimate — line-by-line pbxproj edit rather than checkout-and-reapply)
- §4.1 Bucket-1 fixes + F09 test update: 75 min (~7 LOC + test invert + visual verification)
- §4.4 Story 5-6 spec update (Review Findings table + Change Log): 20 min
- §4.4 deferred-work.md update (W33-W42 + W28 close): 30 min
- §4.5 Story 5-7 spec update (Carry-over appendix + KDD #9 + AC #12): 20 min
- §4.6 New Story 5-6b spec creation: 30 min (via `bmad-create-story`)
- §4.6 sprint-status.yaml + epics.md edits: 10 min
- **Total: ~3.5 hours** (was 2.5h before Codex revisions added surgical-revert + deferred-work + test-update overhead)

**Risk Assessment:**

- **Low-medium** — Bucket-2 surgical revert needs careful pbxproj line discipline (NOT a blanket checkout). Bucket-1 fixes are localized but F09 carries a test-semantics change.
- **F09 judgment** (validated by Codex): Removing the `lastRunSnapshot = nil` prologue does NOT break diagnostic export — Export Trace button is hidden during `viewModel.isAnalyzing` at `ContentView.swift:208`, so stale export is unreachable through normal UI. The inspector content (`ContentView.swift:100-108`) WILL show the prior snapshot during in-progress analyze — acceptable, must be documented in the F09 fix commit message. The ContentView-side `@State displayStrategy` alternative is NOT safer (duplicates derivable state, risks drift from `options.mergeStrategy`). Proceed with removing the prologue.
- **F09 test update**: `lastRunSnapshotResetOnAnalyzePrologue` (line 867) becomes `lastRunSnapshotPreservedAcrossReanalyze` with inverted assertion. The test's existing `try await Task.sleep` drain pattern stays.

**Timeline Impact:** Story 5-6 close-out delayed by ~3.5 hours. Story 5-7 timeline unchanged (carry-over appendix is a doc edit, not new code).

---

## Section 4 — Detailed Change Proposals

### 4.1 Bucket 1 — Direct fixes in Story 5-6 scope (5 findings, ~7 LOC + 1 test)

**Change 1 — F02: ~~Restore AC #3 metadata~~ → AC #3 amended per user direction (2026-05-23)** — STATUS: wontfix.

User reviewed the proposed fix during Phase 3 execution and chose to DROP intensity + "Result captured at" caption from the metadata stack entirely. AC #3 amended in Story 5-6 spec; KDD #4 metadata-fields list updated to match. Implementation as-shipped (fileName, Confidence, Elapsed) matches the amended AC. F02 row in §Review Findings updated to `wontfix (AC amended 2026-05-23)`.

The original finding was correct against the original AC — the over-spec'd AC was the actual issue. The snapshot-divergence cue Story 5-3 / 5-4 W2 introduced remains on `viewModel.lastRunSnapshot` for the Diagnostics inspector audience; it's just no longer surfaced in the hero metadata stack as developer-mode telemetry.

**Change 2 — F03: Dynamic-Type-respecting hero typography**

```
File: Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift
Section: ContentView struct + resultView(_:) hero Text around line 327
AC: #2 / KDD #4

ADD to ContentView struct:
  @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 96

OLD (resultView):
  Text(row.bpm)
    .font(.system(size: 96, weight: .bold).monospacedDigit().leading(.tight))
    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    .minimumScaleFactor(0.6)
    .lineLimit(1)

NEW:
  Text(row.bpm)
    .font(.system(size: heroSize, weight: .bold).monospacedDigit().leading(.tight))
    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    .minimumScaleFactor(0.6)
    .lineLimit(1)

Rationale: @ScaledMetric scales the point value with Dynamic Type relative to
.largeTitle; pairs with the existing .dynamicTypeSize(...AX3) ceiling so AX4/AX5
cap at the AX3 scale rather than push the digits off-canvas. KDD #4's "honors
AX1–AX3" promise becomes true. Default body-size renders identically to the
current fixed 96pt; only AX-size users see scaling.
```

**Change 3 — F06: Humanize Picker labels (also closes pre-existing W28)**

```
File: Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift
Section: controlsSection Picker around line 177
AC: Story brief ("consumer tool, not developer evaluation harness")
Closes: W28 in deferred-work.md (Story 5-3 deferral)

OLD:
  ForEach(CandidateMergeStrategy.allCases, id: \.self) { strategy in
    Text(strategy.rawValue).tag(strategy)
  }

NEW:
  ForEach(CandidateMergeStrategy.allCases, id: \.self) { strategy in
    Text(AnalysisViewModel.humanize(strategy)).tag(strategy)
  }

Rationale: humanize() already exists and is used for the result caption; using it
for the picker eliminates camelCase ("maxConfidence", "windowVoting") from the
end-user UI. W28 in deferred-work.md anticipated this exact fix ("Re-open trigger:
demo evolves into a more polished release shape"); Story 5-6 IS the trigger.
```

**Change 4 — F09: Preserve backgroundStrategy across reanalyze (last among code fixes per §5 sequencing)**

```
Files:
  - Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift (analyze body)
  - Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift:867-883
AC: Story 5-6 AC #5

OLD (in AnalysisViewModel.analyze() prologue, ~line 157):
  lastRunSnapshot = nil
  // ... synchronous prologue continues, Task launched ...
  // ... eventually inside Task body:
  lastRunSnapshot = LastRunDiagnosticSnapshot(...)

NEW:
  // F09 (2026-05-23): do NOT clear lastRunSnapshot at run start. Holding
  // the prior snapshot lets ContentView.backgroundStrategy (which reads
  // `lastRunSnapshot == nil ? nil : options.mergeStrategy`) keep the prior
  // strategy gradient until the new result arrives, satisfying AC #5's
  // single-crossfade contract (strategy→new-strategy, not strategy→neutral→new).
  //
  // SIDE EFFECT (acceptable): the inspector content (ContentView.swift:100-108)
  // will show the prior snapshot's TraceView during in-progress analyze instead
  // of the empty-state placeholder. Export Trace button is gated by
  // !viewModel.isAnalyzing (ContentView.swift:208) so stale-export remains
  // unreachable via normal UI. Documented in AC #5 trade-off block.
  // ... synchronous prologue continues without the nil-clear ...
  // ... eventually inside Task body:
  lastRunSnapshot = LastRunDiagnosticSnapshot(...)

TEST UPDATE (REQUIRED — Codex finding):
  Demo/.../BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift:867-883

OLD test:
  @Test("lastRunSnapshotResetOnAnalyzePrologue: new analyze clears prior snapshot")
  @MainActor
  func lastRunSnapshotResetOnAnalyzePrologue() async throws {
    let viewModel = try await Self.analyzeFixture()
    #expect(viewModel.lastRunSnapshot != nil)
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    viewModel.analyze(url: url)
    #expect(viewModel.lastRunSnapshot == nil, "prologue should clear snapshot synchronously")
    // Drain the in-flight task so the test doesn't leak a Task.
    let deadline = ContinuousClock.now.advanced(by: .seconds(30))
    while viewModel.isAnalyzing && ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(50))
    }
  }

NEW test:
  // F09 (2026-05-23): snapshot is preserved across re-analyze so the
  // strategy-keyed background gradient can crossfade strategy→new-strategy
  // in a single transition (Story 5-6 AC #5). Stale snapshot during
  // analyze is acceptable because Export Trace button is hidden by
  // !viewModel.isAnalyzing during the run.
  @Test("lastRunSnapshotPreservedAcrossReanalyze: prior snapshot survives prologue")
  @MainActor
  func lastRunSnapshotPreservedAcrossReanalyze() async throws {
    let viewModel = try await Self.analyzeFixture()
    let priorSnapshot = try #require(viewModel.lastRunSnapshot)
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    viewModel.analyze(url: url)
    // Synchronous prologue must NOT clear — prior snapshot still readable.
    #expect(viewModel.lastRunSnapshot != nil, "prologue should preserve prior snapshot")
    #expect(viewModel.lastRunSnapshot?.runOptions == priorSnapshot.runOptions)
    // Drain so the test doesn't leak a Task.
    let deadline = ContinuousClock.now.advanced(by: .seconds(30))
    while viewModel.isAnalyzing && ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(50))
    }
    // After completion, snapshot should be the NEW one.
    #expect(viewModel.lastRunSnapshot != nil)
  }

Rationale: backgroundStrategy collapsing to nil mid-run forces the gradient to
neutral for the duration of analyze, then to the new strategy — two crossfades
with a long neutral hold. Removing the prologue clear gives the AC #5-mandated
single crossfade. The pre-existing test asserted the now-inverted contract;
inverting it preserves the test's intent (verify prologue semantics) while
matching the new desired behavior.
```

**Change 5 — F15: Consistent empty-state copy**

```
File: Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/TraceView.swift
Section: TraceInspectorEmptyView body around line 325
AC: Copy consistency (implicit — Story 5-6 introduces "Drop a track")

OLD:
  Text("Drop an audio file to analyze.")

NEW:
  Text("Drop a track to analyze.")

Rationale: EmptyStateView (new in 5-6) says "Drop a track". Inspector empty state
must use the same noun for the same action. One-line copy fix.
```

### 4.2 Bucket 2 — Surgical pbxproj revert (3 findings)

**Codex finding:** `git checkout HEAD -- project.pbxproj` is too blunt — would also erase `LastUpgradeCheck`, `DEAD_CODE_STRIPPING`, `STRING_CATALOG_GENERATE_SYMBOLS`, and the deployment-target alignment. Line-by-line surgical edit required.

**Action — explicit pbxproj edits (apply via Edit tool, NOT git checkout):**

| Line range | Operation | Target value |
|---|---|---|
| `:412` Debug + `:434` Release | Revert | `PRODUCT_BUNDLE_IDENTIFIER = com.robbyt.BoomBoomBoomKitDemo;` |
| `:404` Debug + `:425` Release | DELETE | `INFOPLIST_KEY_CFBundleDisplayName = BoomBoomBoom;` line |
| `:405` Debug + `:426` Release | DELETE | `INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.music";` line |
| `:388` Debug + `:413` Release | Revert | `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;` |
| `:390` Debug + `:415` Release | DELETE | `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;` line |
| `:248` test Debug + `:310` proj Release + `:374` proj Debug + `:410` Debug + `:447` test Release + `:469` Release | Revert all 6 | `MACOSX_DEPLOYMENT_TARGET = 15.0;` |

**File removal:**
```bash
git rm --cached -rf Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AppIcon.icon/
rm -rf Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AppIcon.icon/
```

**ALSO REVERT — F10 fix (Codex v3 promotion):**

| Lines | Operation | Notes |
|---|---|---|
| 6 instances of `DEAD_CODE_STRIPPING = YES;` across pbxproj diff (app target Debug/Release, test target Debug/Release, project Debug/Release per Codex v3 count correction) | DELETE all 6 lines | F10 fix — DEAD_CODE_STRIPPING=YES on test target risks Swift Testing reflection-based `@Test` discovery; Apple guidance is NO on test bundles. Codex v3: preserving then reverting in 5-6b is pointless churn. Removed in Phase 2; F10 closes in Story 5-6, NOT 5-6b. |

**PRESERVE (do NOT revert — these are either authorized Story 5-6 edits or harmless Xcode auto-injections):**

- `DEVELOPMENT_TEAM = "";` on both app-target configs — Story 5-6's original surgical revert per Debug Log #1.
- `CODE_SIGN_IDENTITY` + `PROVISIONING_PROFILE_SPECIFIER` removed lines — Story 5-6's original surgical revert.
- `LastUpgradeCheck = 2650;` (Xcode auto-injection; cosmetic) — keep.
- `STRING_CATALOG_GENERATE_SYMBOLS = YES;` on Release configs (Xcode auto-injection; harmless without `.xcstrings` files) — keep.

**Verification after surgical revert:**

```bash
make demo-fmt && make demo-lint    # both must exit 0
make demo-build                    # BUILD SUCCEEDED
make demo-test                     # TEST SUCCEEDED — record exact invocation count
git diff HEAD -- Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj
  # Should show ONLY: DEVELOPMENT_TEAM blanks, CODE_SIGN_IDENTITY/PROVISIONING_PROFILE_SPECIFIER removals,
  # LastUpgradeCheck bump, STRING_CATALOG_GENERATE_SYMBOLS adds (Release configs).
  # Should NOT show: bundle-ID rename, display-name, LSApplicationCategoryType, AppIcon catalog rename,
  # INCLUDE_ALL_APPICON_ASSETS, deployment-target bumps, DEAD_CODE_STRIPPING adds.
```

**Invocation count discipline (Codex v3 framing):** record the exact `make demo-test` invocation count after Phase 2. Story 5-6 spec quoted "78 invocations" and treated 79-→-78 as ±1 historical variance; with F10 (DEAD_CODE_STRIPPING) now removed in Phase 2, any further count drop after Phase 4's F09 test rename is investigation-worthy, NOT historical-variance. Phase 4 swaps `lastRunSnapshotResetOnAnalyzePrologue` for `lastRunSnapshotPreservedAcrossReanalyze` — net change is 0 invocations (one test renamed in place). Expected post-Phase-4 count: same as post-Phase-2 count. Material drop = investigate.

All six configs are currently at 15.6; the surgical revert restores all six to 15.0 in one pass (no mid-state bounce through the 15.0/15.6 mismatch).

### 4.3 Bucket 3 — New Story `5-6b-a11y-polish` (6 findings, F10 promoted to Bucket 1)

**To be created via `bmad-create-story`** AFTER Story 5-6 spec updates land (per §5 sequencing). Scope:

- **F04** (AC #12 violation accepted) — drop `.frame(maxHeight: .infinity)` from EmptyStateView; parent `Spacer()` owns vertical centering. Currently EmptyStateView fills upper half only.
- **F07** (AC #6/#7 violation accepted) — `Color(white:)` → `Color(nsColor: .windowBackgroundColor)` and `Color(nsColor: .underPageBackgroundColor)` (two DIFFERENT dynamic colors) for the `.none` case in StrategyBackground. Apple-docs MCP correction (v3): the original v2 proposal's `Color(NSColor.windowBackgroundColor)` is the WRONG initializer spelling — would silently resolve to `Color(_ name: String, bundle:)` (asset-catalog overload), looking up a color named "windowBackgroundColor" and falling back to a placeholder. Use the labeled `nsColor:` initializer. Also: using the same color for both LinearGradient anchors produces a flat fill — must pair `.windowBackgroundColor` with `.underPageBackgroundColor` (or `.controlBackgroundColor`) for any visible gradient. Dark Mode contrast floor restored via dynamic-color semantic anchors.
- **F11** — extend drop-target hit-region: either move `.ignoresSafeArea()` to the outer ZStack OR adjust the gradient to stop at the safe area. Decide based on visual verification.
- **F12** — `.accessibilityValue(Text(inspectorPresented ? "Shown" : "Hidden"))` on Diagnostics toolbar Button. Apple-docs MCP (v3): current Apple-indexed doc surfaces only the `Text` overload — prefer wrapping the literal for forward-compat, even though the `String` overload exists in the SDK and compiles today.
- **F13** (KDD #5 violation accepted) — `.foregroundStyle(.tertiary)` → `.foregroundStyle(.secondary)` in EmptyStateView caption.
- **F14** — `.accessibilityElement(children: .combine)` + `.accessibilityHint("Drag an audio file here to analyze")` on EmptyStateView outer VStack. Apple-docs MCP (v3): "Drag" verb (not "Drop") matches macOS HIG + AppKit drop-target VoiceOver vocabulary (Finder, Mail attachments, etc.).

Estimated: ~25 LOC, 2 Swift files. Status at creation: `backlog`. (F10 promoted to Bucket 1 in Story 5-6 per Codex v3; was previously in this list at ~30 LOC + 1 pbxproj edit.)

Each finding in the new story's Acceptance Criteria explicitly cross-links to the corresponding accepted-violation entry in Story 5-6's Review Findings table.

### 4.4 Story 5-6 spec update — add Review Findings table + deferred-work.md ledger entries

**Append to `_bmad-output/implementation-artifacts/5-6-end-user-ui-redesign.md`** a new sub-section under `### Dev Agent Record`, peer to Completion Notes and Change Log:

```markdown
### Review Findings

`/code-review` xhigh-effort 5-angle + Codex blind-hunter pass, 2026-05-23, against
this story's spec + the actual SwiftUI/pbxproj implementation. Triage + bucket
routing captured per `_bmad-output/planning-artifacts/sprint-change-proposal-2026-05-23.md`.
Project-wide deferral ledger entries at `_bmad-output/implementation-artifacts/deferred-work.md`
W33-W42 mirror the deferred rows below.

| F-ID | Severity | AC | File:Line | Status | Resolution |
|------|----------|----|-----------|--------|------------|
| F01 | blocker | — | `project.pbxproj:412` | deferred | → Story 5-7 §Carry-over (KDD #4); W33 in deferred-work.md |
| F02 | major | AC #3 | `ContentView.swift:332` | planned-fix → fixed (Phase 3) | commit `<sha>` |
| F03 | major | AC #2 / KDD #4 | `ContentView.swift:327` | planned-fix → fixed (Phase 3) | commit `<sha>` |
| F04 | major | AC #12 | `EmptyStateView.swift:23` | deferred (accepted AC violation) | → Story 5-6b; W34 in deferred-work.md |
| F05 | blocker | — | `project.pbxproj` + `AppIcon.icon/` | deferred | → Story 5-7 §Carry-over (AC #1); W35 in deferred-work.md |
| F06 | major | Story brief | `ContentView.swift:177` | planned-fix → fixed (Phase 3) | commit `<sha>` (also closes W28 — annotation lands inline in Story-5-3 ledger section) |
| F07 | major | AC #6/#7 | `StrategyBackground.swift:66` | deferred (accepted AC violation) | → Story 5-6b; W36 in deferred-work.md |
| F08 | blocker | — | `project.pbxproj:246` | deferred | → Story 5-7 §Carry-over (new KDD #9 + AC #12); W37 in deferred-work.md |
| F09 | minor | AC #5 | `ContentView.swift:41` + `AnalysisViewModel.swift:157` | planned-fix → fixed (Phase 4) | commit `<sha>` (includes test rename in `AnalysisViewModelSmokeTest.swift:867`) |
| F10 | minor | — | `project.pbxproj:245` | planned-fix → fixed (Phase 2) | commit `<sha>` (DEAD_CODE_STRIPPING removed on all 6 added configs; promoted from 5-6b per Codex v3); W38 in deferred-work.md as CLOSED |
| F11 | minor | — | `ContentView.swift:55` | deferred | → Story 5-6b; W39 in deferred-work.md |
| F12 | minor | — | `ContentView.swift:87` | deferred | → Story 5-6b; W40 in deferred-work.md |
| F13 | minor | KDD #5 | `EmptyStateView.swift:21` | deferred (accepted AC violation) | → Story 5-6b; W41 in deferred-work.md |
| F14 | minor | — | `EmptyStateView.swift:12` | deferred | → Story 5-6b; W42 in deferred-work.md |
| F15 | nit | — | `TraceView.swift:325` | planned-fix → fixed (Phase 3) | commit `<sha>` |

Status legend: `open` / `planned-fix` / `fixed` / `deferred` / `deferred (accepted AC violation)` / `accept-as-known-issue`.
`planned-fix` is the Phase 1 (Paige) interim state for items Amelia will fix in Phases 2-4;
Phase 5 (Paige SHA-fill) flips them to `fixed` after the commits land.
Story 5-6 advances `review` → `done` once every row is at a terminal state (`fixed`,
`deferred`, `deferred (accepted AC violation)`, or `accept-as-known-issue`).
F04, F07, F13 are explicitly accepted AC violations — close-out gate acknowledges Story 5-6
ships with known AC violations on AC #6/#7/#12 and KDD #5; resolution lands in Story 5-6b.
```

**Append to `_bmad-output/implementation-artifacts/deferred-work.md`** at the top (after the preamble, before "Deferred from: code review of 5-3-parameter-controls"):

```markdown
## Deferred from: code review of 5-6-end-user-ui-redesign (2026-05-23)

- **W33 — F01: PRODUCT_BUNDLE_IDENTIFIER + INFOPLIST_KEY_CFBundleDisplayName rename to BoomBoomBoom** — `Demo/.../project.pbxproj:412` + `:404`. Story 5-7 KDD #4 + #5 forbid this rename; reverted in this PR (§4.2). Story 5-7 must NOT reintroduce. Re-open trigger: a future story explicitly authorizes the rename via a KDD update in Story 5-7 or a successor App Store-renaming story.
- **W34 — F04: EmptyStateView fills only upper half — AC #12 accepted violation** — `Demo/.../EmptyStateView.swift:23`. `.frame(maxWidth: .infinity, maxHeight: .infinity)` competes with parent `Spacer()` for vertical extent; SwiftUI splits 50/50. AC #12 promised "fills the main pane". Deferred to Story 5-6b. Fix: drop `maxHeight: .infinity`, let parent Spacer own vertical centering. Est. 1 LOC.
- **W35 — F05: AppIcon.icon directory + 2 MB clock-man.png + icon.json + ASSETCATALOG_COMPILER_APPICON_NAME rename** — `Demo/.../AppIcon.icon/` + `Demo/.../project.pbxproj:388`. Story 5-7 AC #1 owns app icon. Reverted in this PR; Story 5-7 must generate fresh stub or supply final art. Re-open trigger: Story 5-7 execution.
- **W36 — F07: StrategyBackground neutral gradient uses static Color(white:) — AC #6/#7 accepted violation** — `Demo/.../StrategyBackground.swift:66`. Non-dynamic colors break in Dark Mode; every other case uses semantic anchors. AC #6 demands 4.5:1 metadata contrast in both Light and Dark mode; AC #7 demands solid-fill in increased-contrast. Both contracts violated for `.none` case. Deferred to Story 5-6b. Fix (Apple-docs MCP corrected, v3): use TWO different dynamic anchors — `Color(nsColor: .windowBackgroundColor)` paired with `Color(nsColor: .underPageBackgroundColor)`. The `nsColor:` argument label is REQUIRED; bare `Color(NSColor.windowBackgroundColor)` resolves to the asset-catalog `Color(_ name:)` overload and silently fails. Same color for both anchors = flat fill, not a gradient.
- **W37 — F08: MACOSX_DEPLOYMENT_TARGET 15.0→15.6 silent bump while Package.swift still .v15** — `Demo/.../project.pbxproj` six configs + `Package.swift:6`. Reverted to 15.0 in this PR (§4.2). Story 5-7 must capture the lockstep decision: any future bump requires Package.swift + all six pbxproj configs together. Re-open trigger: Story 5-7 execution.
- **W38 — F10: DEAD_CODE_STRIPPING=YES on test target risks Swift Testing reflection — CLOSED 2026-05-23 (Story 5-6 Phase 2 surgical revert).** `Demo/.../project.pbxproj` — 6 instances removed across app target Debug/Release, test target Debug/Release, project Debug/Release. Apple guidance is DEAD_CODE_STRIPPING=NO on test bundles because `@Test` discovery is reflection-based. Codex v3 review promoted F10 from 5-6b to Story 5-6 (preserving then reverting was pointless churn). Re-open trigger: any test-count drop on a future Xcode point release.
- **W39 — F11: Drop target safe-area mismatch — gradient extends behind title bar, dropDestination doesn't** — `Demo/.../ContentView.swift:55`. `.contentShape(Rectangle()) + .dropDestination` on outer ZStack lack `.ignoresSafeArea()`; child StrategyBackground has it. Drops on the visible-gradient strip behind the title bar silently fail. Deferred to Story 5-6b. Fix: move `.ignoresSafeArea()` to ZStack OR stop gradient at safe area.
- **W40 — F12: Toolbar Diagnostics Button has no .accessibilityValue for toggle state** — `Demo/.../ContentView.swift:87`. VoiceOver always announces "Diagnostics, button" regardless of inspector visibility. Deferred to Story 5-6b. Fix: `.accessibilityValue(inspectorPresented ? "Shown" : "Hidden")`.
- **W41 — F13: EmptyStateView caption uses .tertiary instead of spec'd .secondary — KDD #5 accepted violation** — `Demo/.../EmptyStateView.swift:21`. Lower contrast than spec; may drop below WCAG AA 4.5:1 on the F07-buggy neutral background. Deferred to Story 5-6b. Fix: `.tertiary` → `.secondary`. Est. 1 LOC.
- **W42 — F14: EmptyStateView missing .accessibilityElement(.combine) + .accessibilityHint** — `Demo/.../EmptyStateView.swift:12`. VoiceOver announces headline + caption as two separate elements with no drop-affordance explanation. Deferred to Story 5-6b. Fix (Apple-docs MCP, v3): `.accessibilityElement(children: .combine)` + `.accessibilityHint("Drag an audio file here to analyze")` on outer VStack. "Drag" verb (not "Drop") matches macOS HIG + AppKit drop-target VoiceOver vocabulary (Finder, Mail attachments).
```

**W28 placement (Codex v3 correction):** W28 closure annotation stays INLINE in its original Story-5-3 review ledger section (matches W14/W16/W17/W30 pattern). DO NOT move W28 to the new 5-6 section. The pattern: locate the existing line `- **W28 — Picker labels show camelCase rawValues (...)** — ...` in the "Deferred from: code review of 5-3-parameter-controls" section, append `— CLOSED 2026-05-23 (Story 5-6 F06)` to the title, and prepend the closure annotation to the entry body. The new 5-6 section gets a one-line cross-reference: `- See also: W28 closed inline in Story-5-3 section (Picker camelCase rawValues fix).`

### 4.5 Story 5-7 spec update — Carry-over appendix + new KDD #9 + new AC #12

Append to `_bmad-output/implementation-artifacts/5-7-app-store-submission-readiness.md`:

```markdown
## Carry-over from Story 5-6 (2026-05-23)

Per `_bmad-output/planning-artifacts/sprint-change-proposal-2026-05-23.md`. Story 5-6's
pre-staged pbxproj changes were reverted as scope creep; Story 5-7 owns the canonical
implementation of each item below.

- **F01 (bundle ID + display name rename)** — Story 5-6 staged
  `PRODUCT_BUNDLE_IDENTIFIER = com.robbyt.BoomBoomBoom` + `INFOPLIST_KEY_CFBundleDisplayName = BoomBoomBoom`.
  REVERTED in Story 5-6's surgical revert. Story 5-7's existing KDD #4 and KDD #5
  explicitly forbid this rename ("Bundle ID stays `com.robbyt.BoomBoomBoomKitDemo`",
  "App name stays `BoomBoomBoomKitDemo`"). Story 5-7 must NOT reintroduce.
- **F05 (AppIcon.icon bundle landing)** — Story 5-6 staged a 2 MB `clock-man.png`
  placeholder + `icon.json` under `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AppIcon.icon/`
  with the pbxproj catalog rename. REVERTED. Story 5-7 AC #1 owns the icon set;
  KDD #1 authorizes stub artwork. Story 5-7 dev agent may reuse the reverted
  `clock-man.png` artifact OR generate fresh stub artwork.
- **F08 (deployment-target alignment)** — Story 5-6 staged `MACOSX_DEPLOYMENT_TARGET = 15.6`
  on all six pbxproj configs while `Package.swift` remained `.macOS(.v15)` (= 15.0).
  REVERTED to 15.0 across all six configs. See new KDD #9 + AC #12 below.
```

Add new KDD #9 to Story 5-7 (insert after current KDD #8):

```markdown
9. **Deployment-target alignment with library `Package.swift` is a lockstep decision.**
   Demo's `MACOSX_DEPLOYMENT_TARGET` (6 pbxproj configs: app Debug/Release, test Debug/Release,
   project Debug/Release) and library's `Package.swift platforms` MUST move in lockstep.
   Current state (post-Story-5-6 revert): all six demo configs + Package.swift at macOS 15.0.
   Story 5-7 has no behavioral need to bump (no Liquid Glass APIs, no 15.6-only system
   frameworks consumed). Decision: STAY at 15.0 unless a Story 5-7 deliverable explicitly
   requires a 15.x API. If a future bump is needed: edit `Package.swift` `.macOS(.v15)`
   → `.macOS(.v15_6)` AND all six demo pbxproj `MACOSX_DEPLOYMENT_TARGET` lines in
   lockstep. Splitting (demo at 15.6, library at 15.0) silently breaks library consumers
   on macOS 15.0–15.5.
```

Add new AC #12 to Story 5-7:

```markdown
12. **Deployment-target stays at macOS 15.0** unless a Story 5-7 deliverable requires
    a newer API. Verified: `MACOSX_DEPLOYMENT_TARGET = 15.0` on all six demo pbxproj
    configs; `Package.swift` declares `.macOS(.v15)`. Dev agent runs:

    ```bash
    grep 'MACOSX_DEPLOYMENT_TARGET' Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj | sort -u
    grep '\.macOS' Package.swift
    ```

    Both must report 15.0 / `.v15`. If either differs, KDD #9 lockstep applies.
```

### 4.6 sprint-status.yaml + epics.md + deferred-work.md preamble

**Update `_bmad-output/implementation-artifacts/sprint-status.yaml`:**

```yaml
5-6-end-user-ui-redesign: review        # unchanged — stays in review until all F-IDs terminal
5-6b-a11y-polish: backlog                # NEW
5-7-app-store-submission-readiness: ready-for-dev   # unchanged
```

**Update `_bmad-output/planning-artifacts/epics.md` Epic 5 section** — insert Story 5.6b stub between 5.6 and 5.7 (around line 1352):

```markdown
### Story 5.6b: Accessibility + Layout Polish Follow-up

Captures the 7 SHOULD-FIX / accepted-AC-violation defects deferred from Story 5-6
review pass (2026-05-23). Scope: F04 (AC #12), F07 (AC #6/#7), F10, F11, F12, F13
(KDD #5), F14. See `_bmad-output/implementation-artifacts/5-6-end-user-ui-redesign.md`
§Review Findings and `_bmad-output/implementation-artifacts/deferred-work.md` W34/W36/W38-W42.
Estimated: ~30 LOC across 2 Swift files + 1 pbxproj edit.
```

**`deferred-work.md` already updated** in §4.4 — also remove the now-obsolete standalone W28 line from its current Story-5-3 review section (it moves to the W28-CLOSED entry in the new 5-6 section).

---

## Section 5 — Implementation Handoff

**Change Scope Classification:** **Moderate**

- More than a single-AC fix (touches 4 story specs, sprint-status, epics, deferred-work ledger, requires new story creation).
- Less than a fundamental replan (PRD and architecture untouched; epic structure preserved).
- Backlog reorganization needed (insert 5-6b between 5-6 and 5-7).

**Sequencing (revised per Codex v2 + v3):**

```
Phase 1 — Spec updates (Paige; ~1.5 hours; no code dependencies):
  1a. Append §4.4 Review Findings table to 5-6 story spec — `fixed` rows shown as
      `planned-fix → fixed (Phase N)`; Paige flips to `fixed` + populates SHAs in Phase 5
  1b. Append §4.4 W33-W42 to deferred-work.md (NEW section); W38 lands as CLOSED;
      W28 closure annotation inline in existing Story-5-3 section (NOT moved);
      cross-reference note in new 5-6 section per v3 placement correction
  1c. Append §4.5 Carry-over + KDD #9 + AC #12 to 5-7 story spec
  1d. Correct Story 5-6 R2 wording per Apple-docs MCP API 7 finding:
      replace "users who toggled at any point retain their preference" framing
      with honest "silent-majority cohort (relied on implicit true) sees inspector
      hidden post-update; discovery affordance via Diagnostics toolbar button +
      ⌘⇧D + system View → Show Inspector menu is the migration path — no code
      migration added because the affordance is explicit and visible"
  1e. Update §4.6 sprint-status.yaml (5-6b: backlog)
  1f. Update §4.6 epics.md (insert 5.6b stub)
  1g. Create new Story 5-6b spec via `bmad-create-story` — 6 findings (F10 removed
      from scope per v3 promotion to Bucket 1)

Phase 2 — Bucket-2 surgical revert + F10 fix (Amelia; ~45 min):
  2a. Edit pbxproj lines per §4.2 table — surgical, NOT git checkout
  2b. ALSO remove 6 DEAD_CODE_STRIPPING=YES lines per v3 F10 promotion
  2c. `git rm --cached -rf AppIcon.icon/` + `rm -rf AppIcon.icon/`
  2d. `make demo-fmt demo-lint demo-build demo-test pre-commit` — all green
  2e. Record exact `make demo-test` invocation count for Phase 4 comparison
  2f. Commit: `Story 5-6: revert pbxproj scope creep — defer bundle/icon/deployment-target to Story 5-7; remove DEAD_CODE_STRIPPING on test target (F10)`

Phase 3 — Bucket-1 fixes EXCEPT F09 (Amelia; ~30 min):
  3a. Apply F02 (ContentView.swift:332 metadata restoration)
  3b. Apply F03 (ContentView.swift:327 @ScaledMetric hero)
  3c. Apply F06 (ContentView.swift:177 humanize Picker)
  3d. Apply F15 (TraceView.swift:325 copy)
  3e. `make demo-fmt demo-lint demo-build demo-test pre-commit`
  3f. Commit: `Story 5-6: address review findings F02, F03, F06, F15`

Phase 4 — F09 (Amelia; ~45 min — LAST because it changes view-model semantics + test):
  4a. Edit AnalysisViewModel.swift — remove `lastRunSnapshot = nil` prologue
  4b. Rewrite AnalysisViewModelSmokeTest.swift:867-883 per §4.1 Change 4
  4c. `make demo-fmt demo-lint demo-build demo-test pre-commit`
  4d. Verify `make demo-test` invocation count matches Phase 2 recorded count
      (test renamed in place; expected delta 0). Any material drop = investigate.
  4e. Commit: `Story 5-6: address review finding F09 (preserve snapshot across reanalyze)`

Phase 5 — Spec close-out (Paige + User; ~45 min):
  5a. Paige updates §4.4 Review Findings table — flip `planned-fix → fixed (Phase N)`
      rows to `fixed` with actual commit SHAs from Phases 2-4
  5b. User runs Story 5-6 AC #17 visual verification per the Pending User Action items
  5c. User commits final spec updates on 1Password GPG signer
  5d. sprint-status.yaml flips 5-6 review → done IF all 5 visual-verification items pass
```

**Handoff Recipients & Responsibilities:**

| Recipient | Phase | Responsibility |
|-----------|-------|----------------|
| **Paige (Tech Writer)** | 1, 5 | Execute Phase 1 entirely (spec updates with `planned-fix → fixed (Phase N)` interim status; W28 inline closure in Story-5-3 ledger section per v3 placement; R2 wording correction per Apple-docs MCP API 7). After Phase 4, return for 5a (flip `planned-fix` rows to `fixed`; populate actual SHAs). Create new Story 5-6b via `bmad-create-story` — 6 findings (F10 removed from scope per v3 promotion). |
| **Amelia (Developer)** | 2, 3, 4 | Execute Phases 2-4 in order. Phase 2: surgical pbxproj edits per §4.2 table INCLUDING F10's DEAD_CODE_STRIPPING removal (6 lines per Codex v3). Phase 3: 4 Bucket-1 fixes (F02, F03, F06, F15). Phase 4: F09 + test rename (LAST). Re-run gating gauntlet after each phase; record exact `make demo-test` invocation count in Phase 2 and verify Phase 4 matches. |
| **John (PM, advisory)** | 1f | One-sentence sign-off on new Story 5-6b acceptance criteria before Paige finalizes. No full PRD pass. |
| **User** | 5b, 5c | Execute Story 5-6 AC #17 visual verification (a-g) at 1280×800 and 2560×1600. Final commits on 1Password GPG signer per Story 5-1+ precedent. |

**Success Criteria:**

1. `make demo-fmt demo-lint demo-build demo-test pre-commit` all green after each of Phases 2, 3, 4.
2. Story 5-6 §Review Findings table populated; all 15 rows at terminal state (`fixed` / `deferred` / `deferred (accepted AC violation)`).
3. Story 5-7 §Carry-over appendix + KDD #9 + AC #12 landed.
4. `deferred-work.md` contains new entries W33-W42 + W28 close-out under "Deferred from: code review of 5-6-end-user-ui-redesign (2026-05-23)".
5. Story 5-6b spec exists at `_bmad-output/implementation-artifacts/5-6b-a11y-polish.md` (status `backlog`).
6. `sprint-status.yaml` reflects 5-6b: backlog.
7. `git diff --stat Sources/` empty; `git diff --stat Tests/` empty (per Story 5-6 AC #16 — note the test change is under `Demo/.../BoomBoomBoomKitDemoTests/`, not the library's `Tests/`).
8. Library accuracy baselines unchanged (OA300 Acc1=58/82, GiantSteps Acc1=537/661 from Story 5-5 close-out).

**Workflow process improvement (recorded for future sprints, NOT in this PR):**

- Mary's diagnosis (validated by Codex): `/code-review` lacks a Phase 4 reconciler. John's guidance (validated by Codex): do NOT retrofit; use `bmad-correct-course` (this skill, now invoked) for triage, or `bmad-code-review` (BMAD-native, story-aware) next time. Codex specifically rejected building `bmad-apply-review-findings` as premature.
- Action: when reviewing a story spec, prefer `bmad-code-review` over generic `/code-review`. If `/code-review` is used, immediately follow with `/bmad-correct-course` to bridge findings → story artifact + deferral ledger. This proposal documents the bridge pattern.

---

## Approval

Awaiting user `yes` / `no` / `revise` to advance to Step 5 routing.
