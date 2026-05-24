# Story 5.8: Demo Rename & App Store Submission

Story ID: 5.8
Story Key: 5-8-demo-rename-and-app-store-submission
Epic: 5 — Developer Experience (Demo App + Documentation)
Status: backlog
Created: 2026-05-24 (via `/bmad-party-mode` rename-scoping discussion: Amelia + Winston + John + Siri)
Source: `/bmad-party-mode` 2026-05-24 transcript; supersedes Story 5-7 KDD #4 + #5; closes W33 in `_bmad-output/implementation-artifacts/deferred-work.md`

## Story

As the maintainer about to make the first App Store Connect upload under the demo's permanent identity,
I want the demo renamed from `BoomBoomBoomKitDemo` to its final consumer-facing identity AND the App Store Connect submission cycle completed in the same story,
So that the bundle ID committed to App Store Connect on first upload is the one the demo will ship under for the rest of its lifetime (Apple welds bundle IDs to App Store Connect App Records permanently on first upload — there is no rename path post-submission), and no successor rename story is ever required for this demo.

**Scope clarification (read first).** Story 5-8 pairs two pieces of work that the 2026-05-24 party-mode discussion identified as inseparable: (a) renaming the demo from `BoomBoomBoomKitDemo` to its final consumer-facing identity, and (b) running the App Store Connect submission cycle that was OUT-OF-SCOPE in Story 5-7. The pairing exists because the bundle ID is immutable post-first-upload (Siri's authoritative Apple-platform-doc citation 2026-05-24), so the rename MUST land before the first archive is uploaded — otherwise the demo is permanently welded to the wrong identity.

Story 5-8 does NOT pre-commit to a rename scope. The party-mode discussion surfaced three viable scopes and the operator will decide during Story 5-8 execution which to pursue.

## Key Design Decisions

1. **Rename scope decision is operator-driven (KDD-blocked).** Story 5-8 cannot start until the operator picks one of three scopes:

   - **Scope (a) — Display-name-only.** Add `CFBundleDisplayName = BoomBoomBoom` (or chosen name) to `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Info.plist`. Bundle ID stays `com.robbyt.BoomBoomBoomKitDemo`. Paths, scheme, xctestplan, Makefile, all source folders stay `BoomBoomBoomKitDemo`. ~1 LOC. Lowest cost. Forecloses scopes (b) and (c) cheaply later (renaming the bundle ID post-submission requires a new App Store Connect listing — catastrophic for a shipped app).

   - **Scope (b) — Bundle ID + display name.** Add `CFBundleDisplayName = BoomBoomBoom`; rewrite `PRODUCT_BUNDLE_IDENTIFIER = com.robbyt.BoomBoomBoom` + `com.robbyt.BoomBoomBoomTests` in pbxproj (4 lines: 2 Debug + 2 Release × app + tests). Paths, scheme, xctestplan, Makefile, source folders stay `BoomBoomBoomKitDemo`. ~5-6 LOC. Winston's recommendation: changes the externally-visible/permanent identity (bundle ID + display name) while leaving the internal-only `BoomBoomBoomKit*` namespace consistent for repo consumers.

   - **Scope (c) — Full rename.** Rename paths, .xcodeproj, scheme, xctestplan, bundle IDs, display name, Makefile targets, xcarchive name, 502 doc references across 23 files. ~50-100 LOC of mechanical edits. Siri's recommendation if the operator wants the entire repo to reflect the final consumer-facing name — but Winston and Amelia both flagged the scope-creep cost.

   **Decision criterion:** if the bundle ID needs to read `com.robbyt.BoomBoomBoom` post-submission, scope (b) or (c) is required (bundle ID is permanent). If the bundle ID's "Demo" suffix is acceptable forever (it's never user-visible), scope (a) is sufficient.

2. **Final consumer-facing name is operator-driven (KDD-blocked).** "BoomBoomBoom" was the operator's working title in the 2026-05-24 discussion. Before Story 5-8 starts, the operator must confirm:

   - Is `BoomBoomBoom` the final name, or a placeholder? John's question 2026-05-24: "Why 'BoomBoomBoom' specifically and not 'BoomBoom'? Three 'Boom's is the library's joke. The demo doesn't have to carry the joke."
   - App Store Connect "App Name" field (max 30 chars, shown in search results) and `CFBundleDisplayName` (home-screen / Dock / Finder label) are INDEPENDENT per Siri's 2026-05-24 citation. The operator can ship under different names if desired — though same-name is conventional.

3. **Bundle ID availability MUST be verified before any pbxproj edit (scope b or c).** Bundle IDs are first-come-first-served per Apple Developer Team. Even though `com.robbyt.*` is the operator's reverse-DNS namespace, App Store Connect can refuse a specific ID if it was registered by a prior team or reserved. Verification step: log in to App Store Connect → Identifiers → check that `com.robbyt.<final-name>` is available before committing the pbxproj rename. If unavailable, pick an alternative and re-decide.

4. **Story 5-8 supersedes Story 5-7 KDD #4 + #5.** Story 5-7 KDD #4 ("Bundle ID stays `com.robbyt.BoomBoomBoomKitDemo`") and KDD #5 ("App name stays `BoomBoomBoomKitDemo`") were scope-discipline decisions for Story 5-7 — explicitly NOT permanent architectural commitments per the party-mode analysis. Story 5-8 amends both with the operator's chosen scope. The amendment lands as an additional sentence at the end of each KDD in `5-7-app-store-submission-readiness.md` rather than a rewrite — preserves the audit trail of why the prior decision existed.

5. **The App Store Connect submission cycle owned by this story is operator-driven, not assistant-actionable.** Story 5-8 produces the repo state that the operator then uses to drive: App Store Connect App Record creation under the final bundle ID, archive upload via `xcodebuild -exportArchive` or Xcode Organizer, App Store Connect listing field population (App Name, subtitle, description, keywords, support URL, privacy policy URL, age rating, export compliance), screenshot capture (3 × 2880×1800 minimum), App Review notes. The story's `done` criterion is "archive successfully accepted by App Store Connect validation" — but the assistant has no visibility into App Store Connect, so the operator self-attests by pasting the validation-success screenshot or transaction-ID into the Completion Notes.

## Acceptance Criteria

1. **Rename scope decision recorded.** A new KDD #1 (or amendment to Story 5-7 KDD #4/#5) captures which of scope (a) / (b) / (c) the operator chose, and the rationale. Decision recorded in `5-8-...md` AND cross-referenced from `5-7-...md`.

2. **Final name + bundle ID strings committed.** A new KDD #2 (or amendment) records the final `CFBundleDisplayName` value, the final `PRODUCT_BUNDLE_IDENTIFIER` value (if changed from `com.robbyt.BoomBoomBoomKitDemo`), and the final App Store Connect "App Name" (if different from `CFBundleDisplayName`).

3. **Bundle ID availability verified pre-edit.** If scope (b) or (c): operator logs into App Store Connect, confirms `com.robbyt.<final-name>` is registerable, records the verification timestamp + screenshot/note in Completion Notes BEFORE any pbxproj edit lands.

4. **Rename mechanics applied per chosen scope.**
   - Scope (a): exactly 1 line added to `Info.plist`. No other file changes.
   - Scope (b): exactly the pbxproj `PRODUCT_BUNDLE_IDENTIFIER` lines + the Info.plist line. No path or scheme renames.
   - Scope (c): full enumeration in §Scope-c Mechanics below (Story 5-8 dev agent generates a complete file-by-file delta plan before any edit).

5. **Story 5-7 KDD #4 + #5 amended in place.** Both KDDs gain a 2026-05-24 amendment sentence cross-referencing Story 5-8's chosen scope. Original wording preserved.

6. **W33 in `deferred-work.md` updated to CLOSED.** Add the final closure note with the chosen scope + the commit SHA that landed the rename.

7. **Gating gauntlet passes per Story 5-7's bar.** `make demo-fmt` clean, `make demo-lint` exit 0, `make demo-build` BUILD SUCCEEDED, `make demo-test` TEST SUCCEEDED (count documented post-rename), `make pre-commit` exit 0, `DEVELOPMENT_TEAM=<team> make demo-build-sandboxed` BUILD SUCCEEDED, `DEVELOPMENT_TEAM=<team> make demo-archive` ARCHIVE SUCCEEDED. Library gauntlet (`make build`, `make test`, etc.) UNCHANGED from baseline. `git diff --stat Sources/` empty; `git diff --stat Tests/` empty.

8. **First App Store Connect upload attempted.** Operator runs `xcodebuild -exportArchive` (or uploads via Xcode Organizer) against the archive produced under the final bundle ID. App Store Connect validation outcome recorded in Completion Notes (PASS or FAIL with reason).

9. **Diff scope.** Same as Story 5-7 AC #11 baseline (post-2026-05-24 broadening): `Demo/**` (including renamed paths if scope (c)), `.gitignore` (if archive name changed), `Makefile` (if scheme name changed), top-level `README.md` (if any external-facing name reference exists), `_bmad-output/implementation-artifacts/{5-8-..., 5-7-... (KDD amendments), sprint-status.yaml, deferred-work.md (W33 closure)}`, `_bmad-output/planning-artifacts/epics.md` (Story 5-8 entry). `git diff --stat Sources/` empty; `git diff --stat Tests/` empty.

10. **No library changes.** `Sources/BoomBoomBoomKit/`, `Sources/BoomBoomBoomKitTestSupport/`, `Sources/BoomBoomBoomKitML/`, and the entire `Tests/` tree remain untouched. Library still ships under `BoomBoomBoomKit` — the rename is demo-only.

## What This Story Does NOT Deliver

- **No library rename.** `BoomBoomBoomKit` is the SPM library product name (developer-facing). Stays as-is.
- **No App Store Connect listing copywriting.** Description, subtitle, keywords, App Review notes, support URL, privacy policy URL — all operator-owned content authoring outside the dev agent's surface.
- **No screenshot generation.** 3 × 2880×1800 screenshots are operator-owned per Story 5-7 §What this story does NOT deliver. Story 5-8 inherits the same exclusion.
- **No age-rating questionnaire.** Portal-side.
- **No export compliance.** Demo uses no cryptography; one-click "no crypto" answer.
- **No StoreKit / IAP.** Demo is free; no monetization.
- **No analytics / crash reporting SDK.** Privacy manifest reflects zero data collection.
- **No icon redesign.** `AppIcon.icon/` (Liquid Glass clock-man) inherited from Story 5-7 KDD #1. Display name change does not affect icon.
- **No localized display names.** `InfoPlist.strings` per-locale overrides not in scope; English-only.

## Tasks / Subtasks

> NOTE: Tasks are not enumerated until the rename scope decision is recorded (AC #1). Story 5-8 stays at `backlog` status until the operator answers the four scope-determining questions in the §Pre-execution Questions section below. Once answered, the dev agent generates the appropriate task list per the chosen scope.

## Pre-execution Questions (operator answers before flipping to `ready-for-dev`)

1. **Final consumer-facing name?** (e.g., `BoomBoomBoom`, `BoomBoom`, `Boom³`, other) — affects every other decision.
2. **Rename scope?** (a) display-name-only, (b) bundle ID + display name, (c) full path/project/scheme rename.
3. **App Store Connect "App Name" field?** Same as `CFBundleDisplayName` or different?
4. **Bundle ID availability check completed?** (Yes / not yet — gates scope (b) and (c).)

## Scope-c Mechanics (only if operator selects scope (c))

If scope (c) is chosen, the dev agent enumerates the full rename delta before any edit:

- **Filesystem paths to rename:**
  - `Demo/BoomBoomBoomKitDemo/` → `Demo/<NewName>/`
  - `Demo/<NewName>/BoomBoomBoomKitDemo.xcodeproj/` → `Demo/<NewName>/<NewName>.xcodeproj/`
  - `Demo/<NewName>/<NewName>.xcodeproj/xcshareddata/xcschemes/BoomBoomBoomKitDemo.xcscheme` → `<NewName>.xcscheme`
  - `Demo/<NewName>/BoomBoomBoomKitDemo/` (source folder) → `Demo/<NewName>/<NewName>/`
  - `Demo/<NewName>/BoomBoomBoomKitDemoTests/` → `Demo/<NewName>/<NewName>Tests/`
  - `Demo/<NewName>/<NewName>Tests/BoomBoomBoomKitDemo.xctestplan` → `<NewName>.xctestplan`
- **pbxproj edits:** PBXFileSystemSynchronizedRootGroup `path = ...` entries, PBXFileReference `path = ...`, PRODUCT_BUNDLE_IDENTIFIER (both targets), PRODUCT_NAME inheritance from $(TARGET_NAME), scheme references.
- **Makefile edits:** `-project` arg paths, `-scheme` arg, `-testPlan` arg, `xcarchive` output path, `demo-lint` regex pattern (currently scoped to `Demo/**/project.pbxproj`).
- **Doc edits:** 14 `.md` files reference `BoomBoomBoomKitDemo` (per 2026-05-24 grep); most are spec docs that need string-replace + audit for context-sensitive references.
- **Script edits:** `scripts/demo-bump-build.py` constants (the PBXPROJ path).
- **xctestplan edits:** test target reference if scheme name embedded.
- **YAML edits:** `sprint-status.yaml` story keys (`5-7-app-store-submission-readiness`, `5-8-demo-rename-and-app-store-submission`) do NOT contain `BoomBoomBoomKitDemo`, so unaffected.

Scope (c) is a 50-100 LOC mechanical edit. Pre-edit: dev agent produces a complete `git mv` + `sed` plan with a dry-run output for operator review BEFORE executing.

## Risks

- **R1 — Bundle ID unavailability.** If `com.robbyt.<final-name>` is registered by another Apple Developer Team, scopes (b) and (c) become unbuildable as-planned. Mitigation: operator AC #3 availability check pre-edit. If unavailable: operator picks alternate name and re-decides (loops back to AC #1).

- **R2 — App Store Connect first-upload validation surfaces unrelated issues.** Even with the rename perfect, the first archive upload can fail validation for unrelated reasons (missing entitlement, signing issue, ITMS-90xxx codes). Mitigation: AC #8 records the failure for follow-up; the rename mechanics in AC #1-7 are still complete.

- **R3 — Scope-c yak-shave.** Winston's warning: "the kind of yak-shave that produces three weeks of merge conflicts and a follow-up story to fix the docs you missed." Mitigation: only do scope (c) if there's a concrete reason it's worth the cost; scope (b) gets the user-visible benefit at 1/10th the surface.

- **R4 — Story 5-7 historical references become stale.** Story 5-7 spec mentions `BoomBoomBoomKitDemo` extensively (paths, ACs, KDDs). Per the §Why this matters discipline in CLAUDE.md, spec history is preserved verbatim. Story 5-8 explicitly does NOT rewrite Story 5-7 — it amends KDD #4 + #5 in place (additive sentences) and lets the rest of Story 5-7's spec history remain accurate as the historical state at Story 5-7's close-out date.

- **R5 — Story 5-6b a11y polish still pending.** 5-6b is independently in `backlog`. Decision: does 5-6b land before 5-8, after 5-8, or as part of 5-8? Default recommendation per the party-mode discussion: 5-6b ships independently (small a11y polish, < 20 LOC), 5-8 follows. But if scope (c) rename is chosen, 5-6b's diff scope overlaps and they should sequence in series, not parallel.

## Apple Platform Notes

- **Bundle ID immutability.** Per Apple's documentation, `PRODUCT_BUNDLE_IDENTIFIER` cannot be changed after the first build is uploaded to App Store Connect under that App Record. Renaming the bundle ID post-submission creates a NEW App Record with zero reviews, zero ratings, zero download history — catastrophic for any shipped app. This is the single decision the operator must get right BEFORE first upload.

- **CFBundleDisplayName mutability.** Display name is fully mutable across builds without consequence. Only affects the home-screen / Dock / Finder / Spotlight label on the user's device. No App Store Connect identity binding.

- **App Store Connect "App Name" vs `CFBundleDisplayName`.** Independent fields. App Store Connect's "App Name" (max 30 chars) appears in App Store search results and on the product page. `CFBundleDisplayName` appears on the installed app. They can differ. App Store Connect's "App Name" is editable but only via a new app version submission (not independently).

- **TestFlight = App Store identity.** TestFlight uploads bind the bundle ID to the App Record identically to App Store uploads. There is no "TestFlight-only" sandbox where the bundle ID is provisional. Do not use TestFlight as a "let me try this name" mechanism.

- **Localized display names.** Per-locale `InfoPlist.strings` can override `CFBundleDisplayName` per language. Out-of-scope for Story 5-8 (English-only).

## References

### Party-mode Transcript (2026-05-24)

The four-agent discussion that surfaced this story's existence:

- **Amelia** — Enumerated the three rename scopes with file-count and test-impact precision. Recommended scope (a) on cost grounds.
- **Winston** — Reframed KDD #4/#5 as scope-discipline decisions (not architectural commitments). Argued for scope (b) as the right cut-point: change what's permanent and externally visible, leave the internal namespace coherent. Flagged scope (c) as yak-shave.
- **John** — Interrogated the trigger ("what changed in 24 hours?"). Asked whether the operator had looked at the App Store Connect listing form and seen the developer-jargon name. Recommended scope (a) pending answers to three trigger questions.
- **Siri** — Authoritative Apple-platform-doc citation: bundle IDs are permanently welded to App Store Connect App Records on first upload. Recommended scope (c) on platform-fact grounds (the only one-way door is the bundle ID; pre-submission is the only free moment to set it; full rename is the only scope that guarantees no internal-name leak post-ship).

The 3-of-4 lighter-scope recommendation vs Siri's heavier-scope recommendation reflects the genuine asymmetry: code-mechanics agents see internal consistency; platform-doc agent sees external immutability. Story 5-8 captures both perspectives so the dev agent + operator can decide with eyes open.

### Carry-over

- **Story 5-7 KDD #4 + #5** — superseded; amend in place per AC #5.
- **W33 in deferred-work.md** — re-opened by this story per the W33 re-open trigger; close out per AC #6.
- **Story 5-7 §What this story does NOT deliver** (App Store Connect listing creation, upload, etc.) — now owned here.

### External References

- Apple Developer — Distributing your app for beta testing and releases: https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases
- App Store Connect Help — Add an app: https://developer.apple.com/help/app-store-connect/manage-your-app/add-a-new-app
- Apple Developer — Information Property List: `CFBundleDisplayName` https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundledisplayname
- ITMS-90xxx error reference (operator-side troubleshooting when validation fails)

## Dev Agent Record

(Populated when story moves `backlog → ready-for-dev → in-progress`.)

### Completion Notes

(Populated by dev agent on close-out. Operator self-attests AC #8 outcome.)

### Debug Log

(Populated by dev agent during execution.)

### File List

(Populated by dev agent — per chosen scope, the actual file-by-file delta.)

### Change Log

- 2026-05-24 — Story 5-8 created via `/bmad-party-mode` rename-scoping discussion (Amelia + Winston + John + Siri). Status `backlog`. Story pairs the deferred rename (W33 re-open) with the deferred App Store Connect submission cycle from Story 5-7 OUT-OF-SCOPE. Scope decision (a/b/c) and final consumer-facing name deferred to operator answer of §Pre-execution Questions.
