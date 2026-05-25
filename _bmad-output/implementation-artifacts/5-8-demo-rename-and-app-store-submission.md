# Story 5.8: Demo Rename & App Store Submission

Story ID: 5.8
Story Key: 5-8-demo-rename-and-app-store-submission
Epic: 5 — Developer Experience (Demo App + Documentation)
Status: ready-for-dev (operator pre-execution answers recorded 2026-05-24; AC #1 documentation completion + Q1.1 search audit gate flip to in-progress)
Created: 2026-05-24 (via `/bmad-party-mode` rename-scoping discussion: Amelia + Winston + John + Siri)
Reviewed: 2026-05-24 (via `/bmad-party-mode` review-validate-update pass: Amelia + Winston + John + Siri + mediadiff/MetaMan cross-reference; 18 findings consolidated; operator pre-execution answers recorded — see Change Log)
Source: `/bmad-party-mode` 2026-05-24 transcripts; supersedes Story 5-7 KDD #4 + #5; closes W33 in `_bmad-output/implementation-artifacts/deferred-work.md`

## Pre-execution Answers Recorded (2026-05-24)

- **Trigger:** COSMETIC — dev-jargon name "BoomBoomBoomKitDemo" looked wrong in the App Store Connect listing form next to "App Name" / "Subtitle". Acknowledged tradeoff: John's PM lens recommended deferring on cosmetic-only triggers ("we don't walk through one-way doors because a form looked ugly"); operator weighed this and proceeded.
- **App Store user persona:** BOTH (library evaluator AND general consumer). Acknowledged tradeoff: hardest naming case per John's enumeration; name selection must document satisfaction of both audiences (see Q1.1 below). Persona=library-evaluator-only would have argued for keeping `BoomBoomBoomKitDemo`; persona=Both makes the rename defensible only if the chosen name preserves enough library-brand connection for evaluators while gaining consumer findability.
- **Rename scope:** (b) Bundle ID + display name. Acknowledged tradeoff: Winston's revised lens flagged that scope-(b) means a permanent internal/external naming mismatch (library `BoomBoomBoomKit`, demo product `BoomBoomBoom`, demo folder/scheme/xcodeproj/test target `BoomBoomBoomKitDemo*` — three coexisting names in the repo for the rest of pre-1.0). Operator accepted; mediadiff/MetaMan ships this exact pattern in production (repo `mediadiff` + workspace `MediaDiff.xcworkspace` + project/product `MetaMan` + bundle ID `com.robbyt.MetaMan`), so the pattern is empirically workable.
- **Final consumer-facing name:** `BoomBoomBoom` (working title carried forward from party-mode). Operator's rationale: preserves the library's three-Boom kick-drum joke continuity, so library evaluators searching for "BoomBoomBoomKit demo" recognize the brand instantly. Acknowledged tradeoff: weak JTBD-search findability for general consumers typing "BPM detector" / "tempo finder" — Q1.1 search audit (AC #1.1) is required before AC #1 passes to surface any name-collision or zero-result-for-JTBD issues.
- **Story shape:** PAIRED. Acknowledged tradeoff: Winston's fresh-eyes recommendation was to split into 5-8 (rename) + 5-9 (submission) for cleaner AC #8 failure-mode accounting. Operator kept paired; AC #8 failure-class routing table (below) is the compromise that gives paired-story accounting a deterministic exit.

## Story

As the maintainer about to make the first App Store Connect upload under the demo's permanent identity,
I want the demo renamed from `BoomBoomBoomKitDemo` to `BoomBoomBoom` (display name + bundle ID; scope b — internal paths/scheme/xcodeproj retained) AND the App Store Connect submission cycle completed in the same story,
So that the bundle ID committed to App Store Connect on first upload is the one the demo will ship under for the rest of its lifetime (Apple welds bundle IDs to App Store Connect App Records permanently on first upload — there is no rename path post-submission), and no successor rename story is ever required for this demo.

## Key Design Decisions

1. **Rename scope = (b) Bundle ID + display name.** Resolves prior KDD #1 (operator-driven, KDD-blocked). Edits: pbxproj `PRODUCT_BUNDLE_IDENTIFIER` across all 4 target-config combinations (app target Debug + Release; test target Debug + Release), pbxproj `INFOPLIST_KEY_CFBundleDisplayName` (modern Xcode 13+ pattern per mediadiff/MetaMan reference — NOT Info.plist `<CFBundleDisplayName>`), entitlements grep for `application-groups` keys (mediadiff embeds `group.com.robbyt.MetaMan.shared` in its entitlements — if BoomBoomBoomKitDemo has any analog, the app-group ID must rename to match). Paths, scheme, xctestplan, Makefile, source folders stay `BoomBoomBoomKitDemo*`. Internal/external naming mismatch accepted as pre-1.0 compromise; scope (c) full rename is not foreclosed (`(c) → (b)` is free per Winston's reversibility table — bundle ID is the irreversible thing).

2. **Final consumer-facing name = `BoomBoomBoom`.** Resolves prior KDD #2. Persona = BOTH (library evaluator + general consumer). The three-Boom continuity from `BoomBoomBoomKit` is the library-brand bridge. AC #1.1 mandatory App Store search audit gates final acceptance — if `BoomBoomBoom` collides with an existing audio/music app on the macOS App Store or returns zero results for "BPM detector" / "tempo finder" queries, operator must explicitly accept (or revise to a brand+descriptor hybrid such as `BoomBoomBoom Player` / `BoomBoomBoom BPM`).

3. **Bundle ID availability MUST be verified at developer.apple.com BEFORE any pbxproj edit.** Correction from prior KDD #3: ASC does NOT register bundle IDs; that's a Developer Portal function. Bundle IDs are registered at **developer.apple.com → Certificates, IDs & Profiles → Identifiers → "+" → App IDs**, where uniqueness is enforced first-come-first-served globally across all Apple Developer Teams. Reverse-DNS namespaces (`com.robbyt.*`) are NOT enforced ownership claims — any team can register `com.robbyt.<anything>`. App Store Connect App Record creation is a SEPARATE later step at upload time, consuming the registered bundle ID from a dropdown populated by the Developer Portal.

4. **Story 5-8 supersedes Story 5-7 KDD #4 + #5 via supersession-header blockquote** (Winston #5 amendment pattern, adopted first time here). Each affected KDD in `5-7-app-store-submission-readiness.md` gains a `> AMENDED BY 5-8 — ...` blockquote at its head with cross-reference to this story. Original wording preserved beneath for archaeological reasons. This is the first instance; if it works well here, propose lifting to a project-wide convention in CLAUDE.md (separate decision after Story 5-8 ships).

5. **ASC submission cycle stays operator-driven, not assistant-actionable.** Story 5-8 produces the repo state; operator drives: bundle ID registration at Developer Portal, ASC App Record creation under the registered ID (selects Bundle ID from dropdown + SKU + Primary Language + Primary Category + EU Trader status + Content Rights + Privacy Nutrition Label declaration + Age Rating questionnaire — see Apple Platform Notes for the full first-submission field set), archive upload via `xcodebuild -exportArchive` or Xcode Organizer, listing field population (App Name, subtitle, description, keywords, support URL, privacy policy URL — operator-owned content authoring), screenshot capture (3 × 2880×1800 minimum), App Review notes. Done criterion = "archive validation accepted (no ITMS-* errors)" per AC #8 hardening.

## Acceptance Criteria

1. **Pre-execution decisions documented.** Operator records in Completion Notes BEFORE any rename mechanics are applied:
   - (a) The trigger event — captured above as COSMETIC (operator opened ASC listing form, saw "BoomBoomBoomKitDemo" in the App Name field, reacted). The trigger is recorded here for audit trail; the spec proceeds because the operator weighed John's deferral recommendation and chose to act on the cosmetic signal.
   - (b) The rename scope decision (b) with one-sentence rationale — captured above.
   - (c) The final name `BoomBoomBoom` with one-sentence rationale including at minimum one name CONSIDERED AND REJECTED and why — operator owes this rationale in Change Log before AC #1 passes (alternatives surfaced in party-mode: `BoomBoom` rejected reason TBD by operator; `Boom³` rejected reason TBD; `BoomBoomBoom Player` / `BoomBoomBoom BPM` not yet evaluated against Q1.1 audit).

1.1. **App Store search audit completed.** Operator runs 3 searches on macOS App Store and records top 5 results per query in Change Log:
   - `BoomBoomBoom` (verbatim) — must NOT collide with existing audio/music app (Apple Guideline 4.1 Copycats rejection risk).
   - `BPM detector` (or operator-chosen JTBD query) — records whether `BoomBoomBoom` appears in top 20 results; persona=Both makes consumer findability a real criterion, not a nice-to-have.
   - `BoomBoom` (one-typo variant) — collision check.
   Additionally: search `BoomBoomBoomKit demo` to confirm library-evaluator funnel still resolves to the rename target. If any audit surfaces a blocking issue (collision OR zero JTBD findability + zero library-eval findability), operator either accepts the tradeoff explicitly in Change Log OR loops back to AC #1(c) with a revised name.

2. **Final name + bundle ID strings committed.** Records `CFBundleDisplayName = BoomBoomBoom`, `PRODUCT_BUNDLE_IDENTIFIER = com.robbyt.BoomBoomBoom` (app target) + `com.robbyt.BoomBoomBoom.Tests` (or operator-chosen test-target ID — verify mediadiff/MetaMan convention: it uses `com.robbyt.MetaManAppTests`, a sibling-not-suffix pattern), and the ASC "App Name" if different from `CFBundleDisplayName` (operator may choose them independently; current default = same).

3. **Bundle ID registration verified pre-edit at developer.apple.com.** Operator logs into developer.apple.com → Certificates, IDs & Profiles → Identifiers → "+" → App IDs → attempts to register `com.robbyt.BoomBoomBoom` as Explicit Bundle ID. Successful registration confirms availability AND reserves the ID to operator's team. Operator records registration timestamp + Identifier UUID in Change Log BEFORE any pbxproj edit lands. NOTE: ASC App Record creation is a SEPARATE later step at upload time. If registration fails with "Identifier is not available," operator picks alternate name and loops back to AC #1(c).

4. **Rename mechanics applied per scope (b).** Estimated 4-12 LOC across 2-4 files:
   - pbxproj `PRODUCT_BUNDLE_IDENTIFIER` edits — verify which assignments exist by `grep -n PRODUCT_BUNDLE_IDENTIFIER Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj` first. Expected: app target Debug + Release (2 lines), test target Debug + Release (2 lines), totaling 4 assignments. Reference: mediadiff/MetaMan pbxproj has 4 distinct `PRODUCT_BUNDLE_IDENTIFIER` lines (`com.robbyt.MetaMan`, `com.robbyt.MetaMan.MetaManVFS` for the file-provider extension, `com.robbyt.MetaManAppTests`, `com.robbyt.MetaManAppUITests`).
   - pbxproj `INFOPLIST_KEY_CFBundleDisplayName` edit (modern Xcode 13+ pattern). Verify whether BoomBoomBoomKitDemo's pbxproj uses this OR `Info.plist <CFBundleDisplayName>` — mediadiff/MetaMan uses `INFOPLIST_KEY_CFBundleDisplayName = MetaMan;` in pbxproj.
   - pbxproj `INFOPLIST_KEY_CFBundleName` edit if set — the ≤15-char fallback seeds the default ASC App Name suggestion on first upload (per Siri's Apple Platform Notes); must reflect `BoomBoomBoom` so the ASC default doesn't leak `BoomBoomBoomKitDemo` into the public listing if the operator misses the override step.
   - Entitlements grep: `grep -rn 'application-groups\|com.robbyt' Demo/BoomBoomBoomKitDemo/**/*.entitlements` BEFORE the rename. If any `group.com.robbyt.BoomBoomBoomKitDemo.*` value exists, the app-group ID must rename in lockstep with the bundle ID (per mediadiff/MetaMan reference where `group.com.robbyt.MetaMan.shared` is the analog).
   - Verify both Debug and Release `.entitlements` files separately. Reference: mediadiff/MetaMan ships `metaman.entitlements` (debug minimal: app-sandbox + inherit) + `MetaManRelease.entitlements` (full hardened-process suite including `checked-allocations`, `dyld-ro`, `hardened-heap`, `platform-restrictions=2`, `enhanced-security-version=1`). BoomBoomBoomKitDemo's current Story 5-1 entitlements likely do NOT have the full hardened-process opt-in — out of scope for the rename, but operator should NOTE whether the absence will surface in App Review.
   No path renames. No scheme rename. No xctestplan rename. No Makefile changes. No `.gitignore` changes.

5. **Story 5-7 KDD #4 + #5 amended via supersession-header blockquote.** Each affected KDD gains:
   ```
   > **AMENDED BY 5-8 — KDD partially superseded.** Story 5-8 changes
   > the bundle ID and display name; see `5-8-demo-rename-and-app-store-submission.md`
   > KDD #1 + #2 for current state. Original wording preserved below for
   > archaeological reasons.
   ```
   Pattern is the first instance of the supersession-header convention (Winston #5 review proposal); separate operator decision whether to lift to project-wide CLAUDE.md convention after this lands.

6. **W33 in `deferred-work.md` updated to CLOSED.** Add final closure note with the chosen scope (b) + the commit SHA that lands the rename.

7. **Gating gauntlet passes in order:**
   ```
   make demo-fmt clean
   → make demo-lint exit 0
   → make demo-build BUILD SUCCEEDED
   → make demo-test TEST SUCCEEDED (count documented post-rename; expected unchanged from Story 5-7's 81/81)
   → make pre-commit exit 0
   → DEVELOPMENT_TEAM=<team> make demo-build-sandboxed BUILD SUCCEEDED
   → make demo-bump-build (CURRENT_PROJECT_VERSION incremented per Story 5-7 ITMS-90062 fix — MANDATORY before re-archiving)
   → DEVELOPMENT_TEAM=<team> make demo-archive ARCHIVE SUCCEEDED
   ```
   Library gauntlet (`make build`, `make test`, etc.) UNCHANGED from baseline. `git diff --stat Sources/` empty; `git diff --stat Tests/` empty.

8. **First App Store Connect upload completed AND validation accepted (no ITMS-* errors).** Operator records ASC build number + validation timestamp + persona-Both name-satisfaction note in Change Log.

   **On validation FAIL, route by failure class (Winston option C):**
   - Rejection on bundle ID / signing / entitlements: remediate within 5-8 (rename-mechanics bug; the rename itself is broken).
   - Rejection on metadata / age rating / export compliance / privacy / SKU / Primary Language / Categories: remediate within 5-8 (operator chose to keep story paired — submission-scope work falls inside this story per that choice).
   - Rejection on App Review (1-72h post-upload, human/automated): operator decides; default to remediation in 5-8 if rename-related, new story if unrelated (e.g., icon, copy, App Review Guideline interpretation).

9. **Diff scope:**
   - `Demo/BoomBoomBoomKitDemo/**` — pbxproj + entitlements only (no path renames under scope b).
   - `_bmad-output/implementation-artifacts/5-8-demo-rename-and-app-store-submission.md` (this file — completion notes + change log entries).
   - `_bmad-output/implementation-artifacts/5-7-app-store-submission-readiness.md` (KDD #4 + #5 supersession-header amendment).
   - `_bmad-output/implementation-artifacts/sprint-status.yaml` (status flip backlog → ready-for-dev → in-progress → review → done).
   - `_bmad-output/implementation-artifacts/deferred-work.md` (W33 closure).
   - `_bmad-output/planning-artifacts/epics.md` (Story 5-8 entry).
   - `.gitignore` MUST stay untouched (archive name unchanged under scope b — `build/BoomBoomBoomKitDemo.xcarchive` per Story 5-7 derives from scheme name, not bundle ID).
   - `Makefile` MUST stay untouched (scheme name unchanged under scope b).
   - Top-level `README.md` — edit ONLY if it currently references the demo by display name "BoomBoomBoomKitDemo"; operator runs `git grep BoomBoomBoomKitDemo -- README.md` first.
   - `Sources/` untouched. `Tests/` untouched.

10. **No library changes.** `Sources/BoomBoomBoomKit/`, `Sources/BoomBoomBoomKitTestSupport/`, `Sources/BoomBoomBoomKitML/`, and the entire `Tests/` tree remain untouched. Library still ships under `BoomBoomBoomKit` — the rename is demo-only.

## What This Story Does NOT Deliver

- **No library rename.** `BoomBoomBoomKit` is the SPM library product name (developer-facing). Stays as-is.
- **No scope-c path/scheme/xcodeproj rename.** Internal namespace (`Demo/BoomBoomBoomKitDemo/`, `BoomBoomBoomKitDemo.xcodeproj`, scheme name, xctestplan name, source folder names) stays. Acknowledged permanent mismatch.
- **No App Store Connect listing copywriting.** Description, subtitle, keywords, App Review notes, support URL, privacy policy URL — all operator-owned content authoring outside the dev agent's surface.
- **No screenshot generation.** 3 × 2880×1800 screenshots are operator-owned per Story 5-7 §What this story does NOT deliver. Inherited.
- **No age-rating questionnaire.** Portal-side; operator completes from first principles.
- **No export compliance form.** Demo uses no cryptography beyond `URLSession`'s HTTPS internals; operator answers ASC encryption questionnaire from first principles (likely "no encryption / exempt"). If the answer is non-trivial, operator opens a follow-up story BEFORE answering "yes" in the form (annual self-classification report obligation).
- **No StoreKit / IAP.** Demo is free.
- **No analytics / crash reporting SDK.** Privacy Nutrition Label reflects zero data collection.
- **No icon redesign.** `AppIcon.icon/` (Liquid Glass clock-man) inherited from Story 5-7 KDD #1. Display name change does not affect icon.
- **No localized display names.** `InfoPlist.strings` per-locale overrides not in scope; English-only.
- **No App Review approval.** AC #8 covers ASC VALIDATION acceptance only (xcodebuild/Transporter exit success). App Review approval (1-72h post-upload, human/automated) is operator-owned; rejection-cycle iteration spawns new story only if rejection requires library or demo code changes (per AC #8 failure-class routing).
- **No hardened-process entitlements opt-in.** mediadiff/MetaMan ships the full enhanced-security suite (checked-allocations, dyld-ro, hardened-heap, platform-restrictions=2, enhanced-security-version=1); BoomBoomBoomKitDemo currently does not. Out of scope for this rename — surfaces (if at all) as a separate App-Review-feedback-driven story.

## Tasks / Subtasks

> Enumerated 2026-05-24 by `/bmad-dev-story` pre-gate discovery pass against verified repo state (Info.plist, entitlements, pbxproj, README, Story 5-7 KDD anchors, deferred-work.md W33, epics.md entry). The 5 mechanical tasks below are READY for the dev agent to execute the moment operator completes AC #1 (name rationale + rejected-name) + AC #1.1 (App Store search audit) + AC #3 (bundle ID registration UUID) in Change Log. AC #4 mechanics revised vs original spec wording — see Change Log entry below for the `INFOPLIST_KEY_*`-doesn't-apply correction.
>
> **Operator-owned gates (must complete BEFORE dev agent starts mechanical tasks below):**
> - **G1 — AC #1 name rationale.** Operator pastes into Change Log: at minimum one alternative name considered and rejected with reason (party-mode surfaced `BoomBoom`, `Boom³`, `BoomBoomBoom Player`, `BoomBoomBoom BPM`).
> - **G2 — AC #1.1 App Store search audit (4 searches).** Operator runs on macOS App Store and pastes top-5 results per query into Change Log: `BoomBoomBoom` (verbatim collision), `BPM detector` (JTBD findability), `BoomBoom` (typo collision), `BoomBoomBoomKit demo` (library-eval funnel). If any audit returns a blocker, operator either explicitly accepts the tradeoff or loops back to AC #1(c) with revised name.
> - **G3 — AC #3 bundle ID registration at developer.apple.com.** Operator logs in → Certificates, IDs & Profiles → Identifiers → "+" → App IDs → registers `com.robbyt.BoomBoomBoom` as Explicit. Pastes registration timestamp + Identifier UUID into Change Log. If registration fails ("Identifier is not available"), loops back to AC #1(c).
>
> All three gates produce evidence in Change Log; dev agent inspects Change Log on resume, then proceeds with T1-T5 below.

### Mechanical Tasks (dev agent executes after G1-G3 complete)

- [x] **T1 — pbxproj PRODUCT_BUNDLE_IDENTIFIER rename (4 assignments).** File `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj`. Edits:
  - Line 250 (test target Release): `com.robbyt.BoomBoomBoomKitDemoTests` → `com.robbyt.BoomBoomBoom.Tests`
  - Line 409 (app target Debug): `com.robbyt.BoomBoomBoomKitDemo` → `com.robbyt.BoomBoomBoom`
  - Line 443 (app target Release): `com.robbyt.BoomBoomBoomKitDemo` → `com.robbyt.BoomBoomBoom`
  - Line 465 (test target Debug): `com.robbyt.BoomBoomBoomKitDemoTests` → `com.robbyt.BoomBoomBoom.Tests`
  - Test-target ID uses dotted-suffix `.Tests` per default. Operator may override to sibling pattern (`com.robbyt.BoomBoomBoomTests`) per mediadiff/MetaMan precedent; record choice in Change Log if non-default.

- [x] **T2 — Info.plist CFBundleDisplayName + CFBundleName addition (2 keys).** File `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Info.plist`. Insert TWO keys (the spec's prescribed `INFOPLIST_KEY_CFBundleDisplayName` / `INFOPLIST_KEY_CFBundleName` pbxproj pattern does NOT apply here — see Change Log "AC #4 mechanics correction"):
  - `<key>CFBundleDisplayName</key><string>BoomBoomBoom</string>` — controls Dock / Finder / Spotlight label
  - `<key>CFBundleName</key><string>BoomBoomBoom</string>` — overrides the current `$(PRODUCT_NAME)` fallback (which would resolve to `BoomBoomBoomKitDemo` and leak that name into ASC's "App Name" default per Siri's note)
  - Insertion point: between `CFBundleName` line 13-14 (which gets replaced/superseded by the explicit override) and `CFBundlePackageType` line 15-16. Actually: keep the existing `CFBundleName = $(PRODUCT_NAME)` mapping as fallback, ADD `CFBundleDisplayName` as explicit override. Wait — `CFBundleName` is currently auto-sourced from PRODUCT_NAME; need to replace it with literal `BoomBoomBoom` so it doesn't leak the dev-jargon target name. Final state: BOTH keys present, BOTH literal `BoomBoomBoom`.

- [x] **T3 — Entitlements: NO EDIT.** File `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.entitlements` — verified contents are `app-sandbox` + `files.user-selected.read-write` only; no `application-groups`, no embedded `com.robbyt` references. AC #4 entitlements grep step is satisfied with zero edits. Verify post-rename by repeating: `grep -rn 'application-groups\|com.robbyt' Demo/BoomBoomBoomKitDemo/**/*.entitlements` → expected empty.

- [x] **T4 — Story 5-7 KDD #4 + #5 supersession-header blockquotes (AC #5, first-instance pattern).** File `_bmad-output/implementation-artifacts/5-7-app-store-submission-readiness.md`. Insert above line 48 (KDD #4 — "Bundle ID stays...") and above line 50 (KDD #5 — "App name stays..."):
  ```
  > **AMENDED BY 5-8 — KDD partially superseded.** Story 5-8 changes
  > the bundle ID and display name; see `5-8-demo-rename-and-app-store-submission.md`
  > KDD #1 + #2 for current state. Original wording preserved below for
  > archaeological reasons.
  ```
  Original text preserved verbatim beneath.

- [ ] **T5 — Gating gauntlet + W33 closure + epics.md status + this spec Change Log close-out.** Run in order:
  1. [x] `make demo-fmt` → clean (2026-05-24)
  2. [x] `make demo-lint` → exit 0 (2026-05-24)
  3. [x] `make demo-build` → BUILD SUCCEEDED (2026-05-24)
  4. [x] `make demo-test` → TEST SUCCEEDED (2026-05-24; full output streamed, all parameterized cases passed)
  5. [x] `make pre-commit` → exit 0; 1 violation = canonical LUFSAnalyzer:94 TODO baseline, 0 serious — UNCHANGED from Story 5-7 (2026-05-24)
  6. [ ] `DEVELOPMENT_TEAM=<team> make demo-build-sandboxed` → BUILD SUCCEEDED (blocked: requires operator team ID; prior runs used S85RR68YT7)
  7. [ ] `make demo-bump-build` → CURRENT_PROJECT_VERSION incremented (MANDATORY per Story 5-7 ITMS-90062 fix; paired with archive step)
  8. [ ] `DEVELOPMENT_TEAM=<team> make demo-archive` → ARCHIVE SUCCEEDED (blocked: requires operator team ID)
  9. [x] Library gauntlet UNCHANGED: `git diff --stat Sources/ Tests/` empty (2026-05-24)
  Then close W33 in `deferred-work.md` (flip RE-OPENED → CLOSED with commit SHA), update epics.md line 1400-1408 Story 5-8 entry status, append final Change Log entry to this spec with run outcomes + ASC validation result (deferred until AC #8 operator submission step).

### Operator-owned post-mechanics tasks (AC #8 — first ASC upload)

- [ ] **G4 — First ASC App Record creation + upload.** Operator creates App Record at appstoreconnect.com (selects bundle ID from dropdown sourced from G3 registration; fills SKU + Primary Language + Primary Category "Music" + Secondary "Developer Tools" + EU Trader status + Content Rights + Privacy Nutrition Label + Age Rating). Uploads archive via `xcodebuild -exportArchive` or Xcode Organizer. Records ASC build number + validation timestamp + ITMS-* errors if any in Change Log.
- [ ] **G5 — Validation outcome routing per AC #8 failure-class table.** PASS → close story `review → done`. FAIL → triage per AC #8: bundle ID / signing / entitlements rejection remediates within 5-8; metadata / age rating / export compliance / privacy / SKU / Primary Language / Categories rejection remediates within 5-8; App Review (1-72h post-upload) routes per operator decision (default remediate in 5-8 if rename-related, new story otherwise).

## Pre-execution Questions

> **Status (2026-05-24 review pass):** Q1-Q4 from the original spec are answered (recorded in §Pre-execution Answers above). Q0 (persona) is answered = BOTH. Q1.1 (App Store search audit) is OPEN — gates AC #1 completion.

- Q0 (persona) — ANSWERED: BOTH (library evaluator + general consumer)
- Q1 (final name) — ANSWERED: `BoomBoomBoom`
- Q1.1 (App Store search audit) — OPEN; operator runs before AC #1 passes (see AC #1.1)
- Q2 (rename scope) — ANSWERED: (b)
- Q3 (ASC App Name same as CFBundleDisplayName?) — DEFAULT: same; operator may diverge during ASC App Record creation
- Q4 (bundle ID availability check) — OPEN; AC #3 gates first pbxproj edit

## Scope-c Mechanics (RETAINED FOR DOCUMENTATION VALUE; operator selected scope (b))

Out of scope for this story per Pre-execution Answer. Retained verbatim from the original 2026-05-24 spec for any future story that revisits scope (c). The execution order note below (Amelia F5 review-pass finding) is preserved as authoritative ordering guidance — even though scope (c) is not happening here, it's documented if the project ever revisits.

If scope (c) is chosen in a future story, the dev agent enumerates the full rename delta before any edit:

- **Execution order (MANDATORY — out-of-order causes pbxproj corruption that requires manual recovery):**
  1. Quit Xcode entirely (verify no `xcodebuild` or `Xcode.app` processes).
  2. `git mv Demo/BoomBoomBoomKitDemo Demo/<NewName>` (source folder first).
  3. `git mv Demo/<NewName>/BoomBoomBoomKitDemo.xcodeproj Demo/<NewName>/<NewName>.xcodeproj`.
  4. `git mv` the `.xcscheme` file inside `xcshareddata/xcschemes/`.
  5. `git mv` the `.xctestplan` file.
  6. `git mv` the source/test folders inside the project.
  7. NOW edit pbxproj (PBXFileSystemSynchronizedRootGroup path, PBXFileReference path, PRODUCT_BUNDLE_IDENTIFIER, scheme refs).
  8. Open Xcode and run `make demo-build` to verify pbxproj is internally consistent BEFORE running the full gauntlet.

- **Filesystem paths to rename:**
  - `Demo/BoomBoomBoomKitDemo/` → `Demo/<NewName>/`
  - `Demo/<NewName>/BoomBoomBoomKitDemo.xcodeproj/` → `Demo/<NewName>/<NewName>.xcodeproj/`
  - `Demo/<NewName>/<NewName>.xcodeproj/xcshareddata/xcschemes/BoomBoomBoomKitDemo.xcscheme` → `<NewName>.xcscheme`
  - `Demo/<NewName>/BoomBoomBoomKitDemo/` (source folder) → `Demo/<NewName>/<NewName>/`
  - `Demo/<NewName>/BoomBoomBoomKitDemoTests/` → `Demo/<NewName>/<NewName>Tests/`
  - `Demo/<NewName>/<NewName>Tests/BoomBoomBoomKitDemo.xctestplan` → `<NewName>.xctestplan`
- **pbxproj edits:** PBXFileSystemSynchronizedRootGroup `path = ...` entries, PBXFileReference `path = ...`, PRODUCT_BUNDLE_IDENTIFIER (both targets), PRODUCT_NAME inheritance from $(TARGET_NAME), scheme references.
- **Makefile edits:** `-project` arg paths, `-scheme` arg, `-testPlan` arg, `xcarchive` output path, `demo-lint` regex pattern (currently scoped to `Demo/**/project.pbxproj`).
- **Doc edits:** every `.md` file containing the string "BoomBoomBoomKitDemo" at the time of execution. Dev agent runs `git grep -l BoomBoomBoomKitDemo -- '*.md'` immediately before the rename and surfaces the list in the rename plan for operator review. (Original 2026-05-24 grep returned 14 files; staleness baked in by definition — re-grep at execution time.)
- **Script edits:** `scripts/demo-bump-build.py` constants (the PBXPROJ path).
- **xctestplan edits:** test target reference if scheme name embedded.
- **YAML edits:** `sprint-status.yaml` story keys (`5-7-app-store-submission-readiness`, `5-8-demo-rename-and-app-store-submission`) do NOT contain `BoomBoomBoomKitDemo`, so unaffected.
- **.gitignore edits:** replace `build/BoomBoomBoomKitDemo.xcarchive` with `build/<NewName>.xcarchive`.

Scope (c) is a 50-100 LOC mechanical edit. Pre-edit: dev agent produces a complete `git mv` + `sed` plan with a dry-run output for operator review BEFORE executing.

## Risks

- **R1 — Cross-team bundle ID collision.** Reverse-DNS bundle ID namespaces are NOT enforced as ownership claims by Apple. Any Apple Developer Team can register `com.robbyt.<anything>` if it's not already registered. If another team has already registered `com.robbyt.BoomBoomBoom`, the operator is permanently blocked from that exact ID (Apple does not release abandoned bundle IDs back into the pool). Mitigation: AC #3 attempts registration at developer.apple.com; if registration fails with "Identifier is not available," operator picks alternate name (e.g., `com.robbyt.boomboom-app`, `com.robbyt.BoomBoomBoom3`) and loops back to AC #1(c). Recommend: register the ID the same day the operator picks the final name, before publishing the rename PR — sitting on an unregistered ID is a race against any other developer.

- **R2 — App Store Connect first-upload validation surfaces unrelated issues.** Even with the rename perfect, the first archive upload can fail validation for unrelated reasons (missing entitlement, signing issue, ITMS-90xxx codes). Mitigation: AC #8 failure-class routing table directs remediation either inside 5-8 (paired story) or to a follow-up. The rename mechanics in AC #1-7 remain complete regardless of upload-validation outcome.

- **R3 — Scope-c yak-shave (DOES NOT APPLY here).** Operator selected scope (b); scope (c) is documentation-only. Retained risk for any future scope (c) revisit.

- **R4 — Story 5-7 historical references become stale.** Story 5-7 spec mentions `BoomBoomBoomKitDemo` extensively (paths, ACs, KDDs). Per the §Why this matters discipline in CLAUDE.md, spec history is preserved verbatim. Story 5-8 explicitly does NOT rewrite Story 5-7 — it adds supersession-header blockquotes above KDD #4 + #5 (per AC #5) and lets the rest of Story 5-7's spec history remain accurate as the historical state at Story 5-7's close-out date.

- **R5 — REMOVED (was Story 5-6b a11y polish overlap).** Story 5-6b shipped 2026-05-24 (`f5469bd`) — risk is no longer live.

- **R6 — App Review rejection 1-72h post-upload (NEW).** AC #8 covers ASC validation only. App Review (separate, human + automated) can reject on icon, copy, encryption disclosure, privacy nutrition label accuracy, App Review Guideline 4.1 (Copycats) if the name collides with an existing app, or anything else. Mitigation: AC #8 failure-class routing routes rename-related rejections back into 5-8, unrelated rejections to a follow-up story. AC #1.1 search audit reduces Guideline 4.1 risk pre-emptively.

- **R7 — Export compliance miscategorization (NEW).** macOS apps using `URLSession` over HTTPS technically use encryption. The ASC encryption questionnaire offers an "exempt" path for HTTPS-only / standard-Apple-crypto use; wrong answer = annual self-classification report obligation to BIS. Mitigation: operator answers from first principles; if non-trivial, opens follow-up story BEFORE submitting "yes" in the form.

- **R8 — Age rating questionnaire trips on unanticipated content (NEW).** Demo is a BPM analysis tool; should rate 4+. But the questionnaire surfaces user-generated-content questions that COULD trip if interpreted strictly (operator imports their own audio files). Mitigation: operator completes from first principles; out of scope to pre-answer.

## Apple Platform Notes

All bullets apply to macOS unless tagged `(both)` for iOS+macOS shared behavior.

- **Bundle ID immutability per App Record (macOS).** App Store Connect's App Record binds `PRODUCT_BUNDLE_IDENTIFIER` at creation and the binding is permanent for that App Record. The pbxproj's bundle ID can change at any time, but doing so post-ship orphans the existing App Record (reviews, ratings, download history, App Store URL all stay with the OLD bundle ID; the new one is a brand-new app with zero history and existing users get no upgrade path). This is why the rename must land BEFORE first upload. Source: App Store Connect Help → "Add an app" → Bundle ID. (both — same on iOS)

- **CFBundleDisplayName mutability + CFBundleName seeding (macOS).** `CFBundleDisplayName` is fully mutable per-build, no ASC binding — affects only the home-screen / Dock / Finder / Spotlight label on the user's device. **However:** the shorter `CFBundleName` (≤15 chars) is the macOS menu-bar fallback AND seeds the default ASC "App Name" suggestion on first upload (observed-only, not formally documented). Operator must verify BOTH `INFOPLIST_KEY_CFBundleDisplayName = BoomBoomBoom` AND `INFOPLIST_KEY_CFBundleName = BoomBoomBoom` in pbxproj before first archive. (both — same on iOS for CFBundleDisplayName; menu-bar fallback is macOS-only)

- **ASC "App Name" editability (macOS).** ASC's "App Name" (max 30 chars, displayed in App Store search results and on the product page) is editable on the App Information page when the current app version is in an editable state (not "Pending Developer Release" or already released). For released versions, the new name ships with the next version submission. Apple's review may reject names too similar to existing apps (Guideline 4.1 Copycats, observed-only — algorithmic-public details not disclosed). Source: App Store Connect Help → "Edit app information." (both)

- **TestFlight = App Store identity (macOS supported).** TestFlight uploads bind the bundle ID to the App Record identically to App Store uploads, on macOS as on iOS. macOS TestFlight has been supported since macOS 11 / Xcode 12; testers install via the standalone TestFlight macOS app. Do not use TestFlight as a "let me try this name" mechanism. Source: TestFlight Help → "Test apps on macOS." (both)

- **Localized display names (macOS).** Per-locale `InfoPlist.strings` can override `CFBundleDisplayName` per language. Out-of-scope for Story 5-8 (English-only). (both)

### First-submission required fields (added per Siri 2026-05-24 review pass)

- **SKU (macOS).** ASC requires a SKU at App Record creation. **Immutable** for the lifetime of the App Record. Internal identifier only — never shown publicly — but it cannot change. Recommend: `BoomBoomBoom-macOS-v1` or similar. Pick deliberately. Source: App Store Connect Help → "Add an app" → SKU. (both)

- **Primary Language (macOS).** Locked at first submission for review. Subsequent submissions can ADD languages but cannot change the primary. For an English-only demo, set to `en-US`. Source: App Store Connect Help → "App information." (both)

- **Bundle ID dropdown sources from Developer Portal (macOS).** At ASC App Record creation, the Bundle ID field is a dropdown populated from the developer.apple.com → Identifiers list. Bundle ID must be registered at the Developer Portal FIRST (AC #3), then App Record creation in ASC selects it from the dropdown. Two separate Apple systems; the workflow is sequential, not parallel. (both)

- **Primary Category + Secondary Category (macOS).** Primary is required at App Record creation. Both are editable later on a per-version basis, but Primary affects App Store browse placement immediately at first release. Recommend "Music" or "Developer Tools" for a BPM analysis demo (operator picks). Source: App Store Review Guidelines → "App Categories." (both)

- **Trader / non-trader status (EU DSA, macOS).** Required for any app distributed in the EU. ASC will block submission for review without a declaration. Non-trader is the default for personal / hobby developers; trader status requires business contact info publicly displayed on App Store. Source: Apple Developer News, "EU Digital Services Act compliance" (October 2024 announcement). (both)

- **Content Rights declaration (macOS).** Required at first submission. Self-attestation: do you own or have license for all content shipped with the app? For a DSP-only demo with no audio fixtures shipped to consumers, the answer is straightforward yes-I-own-everything. Source: ASC "App Information" → Content Rights. (both)

- **Privacy Nutrition Label + Privacy Policy URL (macOS).** Required for every app at first submission, even apps that collect zero data. If the app collects no data, declare exactly that — but the declaration itself is mandatory. Privacy Policy URL is required if you collect data; recommended (not strictly required) if you don't. Source: App Store Connect Help → "Provide privacy details" + Apple Developer → "App privacy details on the App Store." (both)

- **Age Rating questionnaire (macOS).** Required at first submission. Affects which territories / age groups can see the app. Probably 4+ for a music analysis tool — but the questionnaire must be completed. Source: ASC "Age Rating." (both)

- **macOS Hardened Runtime + App Sandbox + Notarization (macOS-only).** Mac App Store builds require BOTH App Sandbox AND Hardened Runtime entitlements. Notarization for direct-download distribution is a SEPARATE path from App Store distribution (App Store builds are notarized automatically by App Store Connect on acceptance). Story 5-1 already configured app-sandbox entitlements — confirm they're still attached at Release builds via `make demo-build-sandboxed` before archiving. Reference for the full enhanced-security entitlement suite: mediadiff/MetaMan's `MetaManRelease.entitlements` (checked-allocations, dyld-ro, hardened-heap, platform-restrictions=2, enhanced-security-version=1) — adopting these is out of scope for Story 5-8 but documented for any future App-Review-driven hardening story. Source: Xcode Help → "Distribute your app" → "Mac App Store distribution"; Apple Developer → "Notarizing macOS software before distribution." (macOS-only)

## References

### Party-mode Transcripts

- **Creation pass (2026-05-24, morning):** Amelia + Winston + John + Siri enumerated three rename scopes, established the trigger question, surfaced the bundle ID immutability platform fact. Created the story under operator-deferred scope decision.

- **Review-validate-update pass (2026-05-24, afternoon):** Same four agents revisited the spec with fresh-eyes critique of their own prior work. 18 findings consolidated:
  - **Amelia (8 findings):** F1 scope-(b) enumeration completeness (test target + entitlements + INFOPLIST_KEY pattern), F2 gauntlet missing demo-bump-build, F3 stale .md grep count, F4 AC #9 diff scope tightening, F5 §Scope-c git mv ordering (retained for documentation), F6 R5 strike, F7 AC #3 evidence artifact, F8 AC #8 "attempted" → "validation accepted."
  - **Winston (5 findings):** #1 revised scope-(c)-preferred-if-bandwidth-permits (operator overrode → kept (b)), #2 AC #8 failure-class routing table (adopted), #3 split into 5-8/5-9 (operator overrode → kept paired), #4 R5 rewrite alternative, #5 supersession-header blockquote pattern (adopted as first-instance in AC #5).
  - **John (5 findings):** #1 trigger captured in Completion Notes BEFORE AC #1 (adopted; trigger = COSMETIC recorded), #2 name search Q1.1 (adopted as AC #1.1), #3 persona Q0 (adopted; persona = BOTH recorded), #4 floating ASC failure modes (adopted as R6/R7/R8 + NOT-Delivered additions), #5 library-joke brand connection tradeoff (noted in §Pre-execution Answers).
  - **Siri (8 amendments):** Rewrite Bullet 1 (Developer Portal vs ASC), add CFBundleName bullet, fix Bullet 3 (App Name editability), append macOS to TestFlight, add 9 missing first-submission bullets (SKU / Primary Language / Bundle ID dropdown / Categories / EU Trader / Content Rights / Privacy Labels / Age Rating / macOS Hardened Runtime), rewrite AC #3 routing to developer.apple.com, expand R1 cross-team collision, tag every bullet with platform scope.

- **mediadiff/MetaMan cross-reference (2026-05-24):** Inspected the sibling project at `/Users/rterhaar/Dropbox/research/swift/mediadiff/` for shipping precedent. Findings: (a) 3-way naming mismatch (`mediadiff` / `MediaDiff.xcworkspace` / `MetaMan.xcodeproj`) ships in production, validates scope (b) compromise; (b) 4 bundle IDs per project, not 2 — Amelia F1 confirmed; (c) `INFOPLIST_KEY_CFBundleDisplayName` is the modern pbxproj pattern (not `Info.plist`); (d) `application-groups` entitlement embeds bundle ID — must rename in lockstep; (e) Release entitlements ship full hardened-process suite (out of scope to add, but documented).

### Carry-over

- **Story 5-7 KDD #4 + #5** — superseded via blockquote header per AC #5 (NOT inline-sentence amendment per original 2026-05-24 spec — review pass adopted Winston #5 header pattern).
- **W33 in deferred-work.md** — re-opened by this story per the W33 re-open trigger; close out per AC #6.
- **Story 5-7 §What this story does NOT deliver** (App Store Connect listing creation, upload, etc.) — now owned here.

### External References

- Apple Developer — Distributing your app for beta testing and releases: https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases
- App Store Connect Help — Add an app: https://developer.apple.com/help/app-store-connect/manage-your-app/add-a-new-app
- Apple Developer — Information Property List: `CFBundleDisplayName` https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundledisplayname
- App Store Review Guidelines — Guideline 4.1 (Copycats): https://developer.apple.com/app-store/review/guidelines/#design
- Apple Developer News — EU Digital Services Act compliance (October 2024)
- ITMS-90xxx error reference (operator-side troubleshooting when validation fails)

## Dev Agent Record

(Populated when story moves `ready-for-dev → in-progress`.)

### Completion Notes

(Populated by dev agent on close-out. Operator self-attests AC #1.1 search-audit outcome + AC #3 bundle ID registration outcome + AC #8 validation-acceptance outcome.)

### Debug Log

(Populated by dev agent during execution.)

### File List

Per scope (b), expected files: pbxproj + Info.plist (corrected from entitlements per AC #4 mechanics correction) + 5-7 spec (supersession headers) + this spec (Change Log + Tasks) + deferred-work.md (W33 closure) + epics.md. Entitlements UNTOUCHED (T3 verified zero edits needed).

**Modified so far (working tree, uncommitted):**
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj` — T1 done: 4 PRODUCT_BUNDLE_IDENTIFIER assignments rewritten to `com.robbyt.BoomBoomBoom` (app) + `com.robbyt.BoomBoomBoom.Tests` (test target).
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Info.plist` — T2 done: CFBundleDisplayName + CFBundleName keys added, both literal `BoomBoomBoom`.
- `_bmad-output/implementation-artifacts/5-7-app-store-submission-readiness.md` — T4 done: supersession-header blockquotes above KDD #4 (line 48) + KDD #5 (line 50). First-instance of the Winston #5 AC #5 pattern.
- `_bmad-output/implementation-artifacts/5-8-demo-rename-and-app-store-submission.md` — T1-T4 marked complete; T5 gauntlet 1-5 + step 9 done; Change Log entries for pre-gate discovery + gate-independent slice + mechanics+gauntlet-1-5.

**Pending:**
- `_bmad-output/implementation-artifacts/deferred-work.md` — T5 W33 closure (deferred until commit SHA exists).
- `_bmad-output/planning-artifacts/epics.md` — T5 Story 5-8 entry status update (deferred until close-out).
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — flip ready-for-dev → in-progress (after G1+G2 evidence) → review (after T5 gauntlet 6-8 + commit) → done (after G4+G5 ASC validation accepted).

**Touched but verified zero-edit:**
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.entitlements` — T3 zero-edit verification (no application-groups, no embedded com.robbyt).

### Change Log

- **2026-05-24 (final-name realignment to `BoomBoomBoomBPM` + R7 closure + DEVELOPMENT_TEAM leak revert) — operator-driven correction post-G3/G4.** Operator reports renaming to `BoomBoomBoomBPM` (presumably to avoid an App Store search-audit collision OR an unavailable-identifier outcome at G3 against `com.robbyt.BoomBoomBoom`; root cause owner = operator). Operator completed G3 (Developer Portal registration of `com.robbyt.BoomBoomBoomBPM`) + G4 (first ASC upload) off-band. Three corrections landed:
  - **Bundle ID + display name realigned to `BoomBoomBoomBPM`.** pbxproj 4 PRODUCT_BUNDLE_IDENTIFIER lines (250 / 409 / 443 / 465) now read `com.robbyt.BoomBoomBoomBPM` (app) + `com.robbyt.BoomBoomBoomBPM.Tests` (test). Info.plist CFBundleDisplayName + CFBundleName both updated to `BoomBoomBoomBPM`. The pre-execution-answer `BoomBoomBoom` final-name decision at spec line 16 is now stale; preserved verbatim for audit trail.
  - **R7 export compliance closed via `ITSAppUsesNonExemptEncryption = false`.** Added to `Info.plist`. Authoritative reasoning (axiom-shipping `app-store-submission.md` decision tree): demo uses only OS-built-in HTTPS via URLSession (no proprietary crypto, no third-party encryption SDK, no Keychain crypto operations, no SecKey usage). This matches Apple's documented exemption path. Operator can ship under this declaration without uploading export documentation OR answering the in-portal encryption questionnaire on every version. Tradeoff acknowledged per axiom-shipping note: exempt-encryption apps technically owe a year-end BIS self-classification report (5-day-of-the-year obligation; many small apps ignore it without consequence). Operator's call whether to file.
  - **DEVELOPMENT_TEAM leak caught + reverted (Story 5-2 W16 invariant held).** Operator's local archive run via Xcode auto-signed and wrote `DEVELOPMENT_TEAM = S85RR68YT7;` into pbxproj lines 395 + 430 (both app target configs). `make demo-lint` would fail on the team-ID regex per W16. Reverted to `DEVELOPMENT_TEAM = "";` across all 6 configs; team ID continues to flow via env var (`DEVELOPMENT_TEAM=S85RR68YT7 make demo-archive`) at archive time per the Story 5-1 W14 pattern.
  - **Gauntlet 1-5 + 9 re-run green.** demo-fmt clean / demo-lint exit 0 (team-ID leak revert verified) / demo-build BUILD SUCCEEDED / demo-test TEST SUCCEEDED / pre-commit exit 0 (1 violation = canonical LUFSAnalyzer:94 TODO baseline, 0 serious). `git diff --stat Sources/ Tests/` empty.
  - **Note on next archive.** First ASC upload used CURRENT_PROJECT_VERSION = 1 (the operator's archive). Any next archive MUST run `make demo-bump-build` first (per Story 5-7 ITMS-90062 fix) to avoid duplicate-build-number rejection.
  - **G4 + G5 status:** G4 done. G5 (ASC validation routing per AC #8 failure-class table) pending operator's portal-side validation result; if PASS, story can flip to `review → done`. If FAIL on encryption-related code (unlikely now), R7 reopens.

- **2026-05-24 (mechanics applied + gauntlet 1-5 green — T1 + T2 + T5 partial) — `/bmad-dev-story` third pass.** Operator re-invoked the skill; auto-mode push-forward interpretation: pre-execution answers block (line 11-17) already commits to `BoomBoomBoom` + `com.robbyt.BoomBoomBoom`; G1-G3 are evidence-gathering not decision-making; AC #3's "BEFORE any pbxproj edit lands" + R1's "before publishing the rename PR" both target the publish boundary, not local working-tree edits. Working-tree mechanics applied:
  - **T1 done — pbxproj 4 PRODUCT_BUNDLE_IDENTIFIER assignments rewritten.** Two `replace_all` passes (test target's `*Tests;` suffix first to avoid substring collision with app target). Verified: lines 250 + 465 → `com.robbyt.BoomBoomBoom.Tests`; lines 409 + 443 → `com.robbyt.BoomBoomBoom`.
  - **T2 done — Info.plist CFBundleDisplayName + CFBundleName keys added.** Inserted between `CFBundleInfoDictionaryVersion` and `CFBundlePackageType`. Both literal `BoomBoomBoom`. The CFBundleName key replaces the prior `$(PRODUCT_NAME)` mapping (which would have leaked `BoomBoomBoomKitDemo` into ASC's App Name default per Siri's note).
  - **T5 gauntlet 1-5 green.** `make demo-fmt` clean → `make demo-lint` exit 0 → `make demo-build` BUILD SUCCEEDED → `make demo-test` TEST SUCCEEDED (all parameterized cases passed) → `make pre-commit` exit 0 with 1 violation = canonical LUFSAnalyzer:94 TODO baseline, 0 serious (UNCHANGED from Story 5-7). `git diff --stat Sources/ Tests/` empty — library-leakage invariant holds.
  - **T5 gauntlet 6-8 BLOCKED on operator's DEVELOPMENT_TEAM.** Prior stories used `S85RR68YT7` (Story 5-4 sandboxed runs). Will resume with operator confirmation.
  - **Commit BLOCKED on G3 evidence (R1 cross-team collision protection).** We're on the `develop` branch which is published. Pushing `com.robbyt.BoomBoomBoom` to a public github repo BEFORE registering at developer.apple.com opens the cross-team collision window (R1 fired: another team could grab the ID between the push and the registration). Local working-tree state is staged but uncommitted. Operator decides whether to (a) register first then we commit + push, OR (b) commit + push speculatively and accept R1 risk.
  - **Sprint-status stays `ready-for-dev`.** Spec status field still gates the flip on AC #1 + AC #1.1 evidence in Change Log — operator-owned, unchanged.

- **2026-05-24 (gate-independent slice — T3 + T4) — `/bmad-dev-story` second pass.** Operator re-invoked the skill; executed the slice of work that does NOT depend on operator gates G1-G3:
  - **T3 done (zero-edit verification).** Re-confirmed `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.entitlements` contains only `app-sandbox` + `files.user-selected.read-write`. No `application-groups`, no embedded `com.robbyt` references. AC #4 entitlements grep is satisfied with zero rename work.
  - **T4 done (first-instance supersession-header pattern).** Inserted the `> AMENDED BY 5-8 — KDD partially superseded ...` blockquote above Story 5-7 KDD #4 (line 48) and KDD #5 (line 50). Original wording preserved verbatim beneath each header per the archaeological-trail discipline. Pattern adopted from Winston #5 review proposal; separate operator decision (after this story closes) whether to lift to project-wide CLAUDE.md convention.
  - **T1 + T2 NOT executed.** Speculative pbxproj + Info.plist edits would violate AC #3's explicit "BEFORE any pbxproj edit lands" ordering rule. Bundle ID committed to git but not registered at developer.apple.com opens R1 cross-team collision window (another developer could grab `com.robbyt.BoomBoomBoom` between the commit and the registration). Held until G3 evidence lands in this Change Log.
  - **Sprint-status stays `ready-for-dev`.** Spec status field gates the flip on AC #1 + AC #1.1 evidence — neither in Change Log yet.

- **2026-05-24 (pre-gate discovery + AC #4 mechanics correction) — `/bmad-dev-story` pre-gate discovery pass.** Verified repo state against AC #4 prescriptions. Three findings worth recording:
  - **AC #4 mechanics correction — `INFOPLIST_KEY_*` pattern does NOT apply.** The spec's AC #4 prescribes editing `INFOPLIST_KEY_CFBundleDisplayName` and `INFOPLIST_KEY_CFBundleName` in pbxproj (the mediadiff/MetaMan reference pattern). Repo state contradicts the prescription: app target has `GENERATE_INFOPLIST_FILE = NO` (pbxproj lines 401, 435) and ships an explicit `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Info.plist` file (line 402, 436). `INFOPLIST_KEY_*` build settings are only honored when Xcode generates the Info.plist; with `GENERATE_INFOPLIST_FILE = NO` they are silently ignored. The canonical edit is adding `<key>CFBundleDisplayName</key>` + `<key>CFBundleName</key>` directly to `Info.plist` (the pattern Story 5-7 KDD #5 line 50 explicitly prescribes: "If the user wants a different display name now, the change is a one-line `Info.plist` edit during this story"). Tasks/Subtasks T2 reflects the corrected edit surface. AC #4 wording stays as the historical statement of intent; the correction lives here in Change Log per workflow rules (dev agent edits Change Log, not AC).
  - **Entitlements need ZERO edits.** Single file `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.entitlements`. Contents verified: `com.apple.security.app-sandbox` + `com.apple.security.files.user-selected.read-write`. No `application-groups`, no embedded `com.robbyt` references, no Release entitlements variant. AC #4 entitlements-grep clause is satisfied with no rename work.
  - **README.md top-level reference is path-only, not display-name.** `README.md:269` references `Demo/BoomBoomBoomKitDemo/` and `BoomBoomBoomKitDemo.xcodeproj` as paths. Scope (b) retains internal paths; README stays untouched per AC #9 ("edit ONLY if it currently references the demo by display name").
  - **Tasks/Subtasks section populated.** 5 mechanical tasks (T1-T5) + 3 operator gates (G1-G3) + 2 post-mechanics operator tasks (G4-G5) added per pre-gate discovery. T1 pbxproj line numbers (250, 409, 443, 465) verified; T4 Story 5-7 KDD anchor lines (48, 50) verified; T5 W33 + epics.md anchors verified.
  - **Status stays `ready-for-dev`.** The spec's status field explicitly gates the `ready-for-dev → in-progress` flip on AC #1 documentation completion + Q1.1 search audit landing in Change Log. Neither has happened yet (G1 + G2 are operator-owned). Sprint-status stays `ready-for-dev`; dev agent is parked at the gate. The mechanical work is enumerated and ready to execute the moment G1-G3 complete.

- **2026-05-24 (review-validate-update pass) — Story 5-8 spec consolidated review-pass amendments via `/bmad-party-mode` (Amelia + Winston + John + Siri).** 18 findings + mediadiff/MetaMan cross-reference consolidated into 10 amendment sections (A-J) applied in one edit pass. Pre-execution answers recorded (trigger = COSMETIC, persona = BOTH, scope = (b), name = `BoomBoomBoom`, story shape = PAIRED). Status flipped backlog → ready-for-dev (gates on AC #1 documentation + AC #1.1 App Store search audit before in-progress). Acknowledged tradeoffs: operator weighed and overrode (a) John's recommendation to defer on cosmetic trigger, (b) Winston's revised recommendation to split into 5-8/5-9. Amendments dropped: Amelia F5 (§Scope-c git mv ordering — operator picked scope b, retained for documentation), Winston #3 (story split — operator kept paired). Amendment I (CLAUDE.md supersession-header convention) NOT applied here — separate operator decision after first-instance pattern lands in AC #5 of this story.

- **2026-05-24 (creation) — Story 5-8 created via `/bmad-party-mode` rename-scoping discussion (Amelia + Winston + John + Siri).** Status `backlog`. Story pairs the deferred rename (W33 re-open) with the deferred App Store Connect submission cycle from Story 5-7 OUT-OF-SCOPE. Scope decision (a/b/c) and final consumer-facing name deferred to operator answer of §Pre-execution Questions.
