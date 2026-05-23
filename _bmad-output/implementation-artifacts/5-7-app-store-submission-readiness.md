# Story 5.7: App Store Submission Readiness Scaffold

Story ID: 5.7
Story Key: 5-7-app-store-submission-readiness
Epic: 5 — Developer Experience (Demo App + Documentation)
Status: review

## Story

As the maintainer preparing the BoomBoomBoomKitDemo app for free macOS App Store distribution,
I want the in-repo prerequisites for a signed, App-Review-acceptable archive build to be in place — app icon, privacy manifest, signing-aware archive workflow, and a recorded category decision —
So that the App Store Connect submission flow has zero in-tree blockers and the actual upload becomes a packaging-and-portal task rather than a project-restructure task.

**Scope clarification (read first).** Story 5-7 lands the file-system / build-system prerequisites that have to live in the repo before any archive can be signed and uploaded to App Store Connect. It does NOT include any of the App Store Connect portal work (creating the listing, uploading screenshots, filling out App Review notes, age-rating questionnaire, export compliance attestation) — the user has stated explicitly that they handle distribution. The story's deliverable is "the repo can produce a signed archive that passes App Store validation rules".

Three deliverables ship:

1. **App icon set.** Final Liquid Glass icon (clock-man artwork, composed via Icon Composer per axiom-design Liquid Glass adoption reference) committed under `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AppIcon.icon/` — TOP LEVEL of the source folder (sibling of `Assets.xcassets/`, NOT inside it; verified post-Codex-diff-review patch — placing inside the catalog produced an empty Resources/ with no icon artifacts). The `.icon` bundle contains `icon.json` (single-layer manifest, `glass:false` per-layer artwork, system-rendered shadow at 0.5 opacity + translucency at 0.5 value — no baked-in effects per Apple's Liquid Glass design rule) and `Assets/clock-man.png` (2.1 MB, 4096×4096 source — Icon Composer's recommended source dimension; Xcode 26 down-samples per appearance variant). Supports squares (shared iOS/iPadOS/macOS) + watchOS circles via `supported-platforms`. Pivot from the original Story 5-7 plan (stub `.appiconset` rasterized PNG ladder) authorized by user 2026-05-23 during this story's code-review pass: the user produced a real Liquid Glass icon via Icon Composer at `/Users/rterhaar/Documents/artwork/icons/clockman.icon/` and asked for it to be integrated as part of the same review cleanup. Replaces the prior placeholder `.appiconset/` ladder (10 rasterized PNGs with baked indigo gradient + drop shadow, removed during the pivot).

2. **Privacy manifest (`PrivacyInfo.xcprivacy`).** Required since May 2024 for any app uploaded to App Store Connect. The demo declares: zero tracking (`NSPrivacyTracking: false`, `NSPrivacyTrackingDomains: []`), zero collected data types (`NSPrivacyCollectedDataTypes: []`), and the Required Reason API entries that actually apply: `NSPrivacyAccessedAPICategoryUserDefaults` reason `CA92.1` (for `@SceneStorage` UserDefaults backing) AND `NSPrivacyAccessedAPICategorySystemBootTime` reason `35F9.1` (for `ContinuousClock.now` elapsed-time measurement at AnalysisViewModel.swift:215+241, added per Codex Blind Hunter delta during the same-session review patch pass).

3. **`make demo-archive` Makefile target.** A signed-archive equivalent to `make demo-build`, but with `-archivePath`, real code signing, and the `-allowProvisioningUpdates` flag. Produces an `.xcarchive` ready for organizer export. The target requires `DEVELOPMENT_TEAM=<team>` in the environment (errors loudly if unset, matching the `make demo-build-sandboxed` pattern from Story 5-1 W14 close-out). NOT auto-uploaded; the dev runs `xcodebuild -exportArchive` manually or via Xcode Organizer.

**Plus one decision artifact:**

4. **App Store category decision recorded.** Per Siri's party-mode flag, the App Store Connect listing requires a primary category. Story 5-7 captures the chosen category in `Demo/BoomBoomBoomKitDemo/README.md` (a new file) so the choice is in-repo and reviewable. Recommended: **Music** primary, **Developer Tools** secondary — but the user makes the final call during this story. The category choice also affects discovery taxonomy and is harder to change post-listing-creation.

**What this story does NOT deliver** (each explicitly OUT-OF-SCOPE):

- **No screenshot generation.** Three 2880×1800 screenshots are required by App Store Connect, but they're listing-portal assets, not in-repo artifacts. User handles via Xcode → Window → Devices → Take Screenshot, or runs the post-Story-5-6 app at the recommended window size and uses macOS Screenshot.
- **No App Store Connect listing creation.** Title, subtitle, description (≤170 chars subtitle, ≤4000 chars description), keywords, support URL, privacy policy URL — all portal-side work.
- **No app upload.** `xcodebuild -exportArchive` is a manual step; this story produces the archive, not the validation submission.
- **No App Review notes.** Free-text field in App Store Connect for explaining the app's purpose to reviewers.
- **No marketing URL / privacy policy URL.** External-hosting concerns; the user maintains these.
- **No age-rating questionnaire.** Portal-side; the demo is a 4+ tool with no user-generated content.
- **No export compliance.** Demo uses no cryptography; the App Store Connect questionnaire is a one-click "no crypto" answer. Captured in the README for reference, not as a build artifact.
- **No StoreKit, IAP, subscription wiring.** The user stated "release this demo as a free app" — no monetization surfaces.
- **No analytics, crash reporting, or telemetry SDK.** The demo collects zero user data; the privacy manifest reflects that. Adding any of these later requires a new story.

## Key Design Decisions

1. **Final Liquid Glass icon shipped via Icon Composer (revised 2026-05-23 mid-story, location corrected post-Codex-diff-review).** The original KDD authorized stub `.appiconset` rasterized artwork as a polish-can-follow placeholder. During this story's code-review pass, the user pivoted: produced a real Liquid Glass icon via Icon Composer (at `/Users/rterhaar/Documents/artwork/icons/clockman.icon/`) and authorized its integration in-session. The `.icon` bundle ships at `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AppIcon.icon/` — TOP LEVEL of the source folder (sibling of `Assets.xcassets/`, NOT inside the catalog). The prior `.appiconset/` placeholder ladder was removed. Per the axiom-design Liquid Glass adoption reference: layered icons (foreground/middle/background) let the system handle all effects (reflection, refraction, shadow, blur, masking) — do NOT bake in pre-applied effects. The shipped `clock-man` icon has `glass:false` per-layer artwork plus group-level system-rendered shadow + translucency, which complies. Xcode 26's asset compiler picks up `AppIcon.icon/` automatically when it sits at the source-folder top level (the PBXFileSystemSynchronizedRootGroup auto-includes it). The compiled artifact contains both `Assets.car` (layered Liquid Glass data, 2.4 MB) and `AppIcon.icns` (legacy compat representation Xcode generates for the `.app` bundle, 76 KB). Apple Platform Notes section reflects this; Story 5-6's revert of the staging `.icon` bundle is now overridden by this in-story authorization.

2. **`PrivacyInfo.xcprivacy` is committed as an XML plist, not a JSON file.** Apple's documented format is the `.xcprivacy` extension with property-list XML payload. Xcode 26 auto-detects the file at Demo/.../BoomBoomBoomKit/PrivacyInfo.xcprivacy and includes it in the bundle. No Xcode project edits required if the file sits at the expected path (the `PBXFileSystemSynchronizedRootGroup` Story 5-1 used auto-includes new files in the target).

3. **`make demo-archive` accepts `DEVELOPMENT_TEAM` via environment but does NOT default it.** Matches the Story 5-1 W14 pattern for `make demo-build-sandboxed`. Failing fast on an unset team prevents an unsigned archive from being silently produced. The error message points the user at the documented invocation: `DEVELOPMENT_TEAM=ABC1234DEF make demo-archive`.

4. **Bundle ID stays `com.robbyt.BoomBoomBoomKitDemo`.** Per Story 5-1 DD, the bundle ID was chosen to be App-Store-acceptable from day one. No change in Story 5-7. The user can override at archive time with `xcodebuild PRODUCT_BUNDLE_IDENTIFIER=<other>` if they want a different listing identifier, but the in-repo default stays.

5. **App name stays "BoomBoomBoomKitDemo".** Renaming to something more consumer-friendly (party-mode Siri's "BeatScope" suggestion) is a marketing decision the user owns and can be done at App Store Connect listing time without changing the bundle ID. Story 5-7 records the in-repo display name (`CFBundleDisplayName`) as "BoomBoomBoomKitDemo" for consistency with prior stories. If the user wants a different display name now, the change is a one-line `Info.plist` edit during this story.

6. **Marketing version + build number scheme: semantic-major.minor.patch + monotonic build counter.** Marketing version starts at `0.1` (pre-1.0 per CLAUDE.md library framing), build number starts at `1` and increments per archive. Story 5-7 sets the initial values in `Info.plist` and documents the bump policy in `Demo/BoomBoomBoomKitDemo/README.md`. Build number bumps are manual (not date-derived) — the user controls the bump cadence.

7. **Category recommendation:** Music (primary). Reason: the consumer audience the user named is musicians / DJs / producers. Discovery surfaces (browse, search ranking) for "Music" outperform "Developer Tools" for this audience. Secondary category: Developer Tools (the library's heritage). Final call belongs to the user; the recommendation is recorded in the README.

8. **No automated archive validation step.** `xcodebuild -archive` succeeding does not guarantee App Store validation will pass. Manual `xcodebuild -exportArchive -exportOptionsPlist <opts>` + the validation pass via Xcode Organizer is the user's workflow. Story 5-7 produces the artifact; the user runs validation manually before submitting.

9. **Demo deployment-target documented as 15.6; library `Package.swift` independently at .macOS(.v15).** (Added 2026-05-23 per Story 5-6 carry-over F08, revised same day per user authorization.) Current state: demo `MACOSX_DEPLOYMENT_TARGET = 15.6` on all 6 pbxproj configs (app Debug/Release, test Debug/Release, project Debug/Release); `Package.swift` declares `.macOS(.v15)` (= 15.0). The two are intentionally DECOUPLED, not in lockstep. Rationale: the demo binary is distributed via App Store as a separate end-user product (Story 5-7's whole framing); library SPM consumers integrate `BoomBoomBoomKit` directly through Package.swift and are unaffected by the demo's deployment target. The 15.6 floor only affects end-user installs of the App Store demo binary. Codex's earlier "splitting silently breaks library consumers on 15.0-15.5" framing applies only if the demo binary IS the library's distribution channel — which it isn't; SPM is the distribution channel for the library. Re-coupling rule: if a future change bundles the library inside the demo's App Store binary as the SOLE distribution channel (instead of alongside SPM), `Package.swift` and demo pbxproj MUST move in lockstep — but that's a different distribution model than what ships today.

## Acceptance Criteria

1. **Liquid Glass app icon shipped** at `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AppIcon.icon/` — modern Xcode 26 `.icon` bundle format (TOP LEVEL of the source folder, NOT inside `Assets.xcassets/` — matches Story 5-6 W35 staging location). Contains `icon.json` manifest + `Assets/clock-man.png` 4096×4096 layer source (Icon Composer's recommended dimension; Xcode 26 down-samples per appearance variant). System renders all effects (shadow, translucency, masking); no baked-in pre-applied effects. Xcode 26 generates `AppIcon.icns` (76 KB legacy compat) + `Assets.car` (2.4 MB Liquid Glass layered data) in the compiled `.app` bundle. Revised mid-story 2026-05-23 from the original `.appiconset` placeholder ladder per user authorization (Icon Composer output). First placement attempt inside `Assets.xcassets/AppIcon.icon/` produced an empty Resources/ with no icon artifacts — moved to the sibling location and the icons compile correctly. NOTE: `Assets.xcassets/Contents.json` is the bare empty catalog stub (no AppIcon entry); `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` in pbxproj still applies to the legacy fallback path and is preserved for backward compatibility.

2. **`PrivacyInfo.xcprivacy` exists** at `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/PrivacyInfo.xcprivacy`. Property-list XML payload declares: `NSPrivacyTracking: false`, `NSPrivacyTrackingDomains: []`, `NSPrivacyCollectedDataTypes: []`, and any `NSPrivacyAccessedAPITypes` entries that apply (likely `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` or `C617.1` for `@SceneStorage` — dev agent verifies).

3. **`make demo-archive` target exists** in the Makefile. Invocation: `DEVELOPMENT_TEAM=<team-id> make demo-archive`. Produces a `.xcarchive` at `build/BoomBoomBoomKitDemo.xcarchive` (or equivalent gitignored path). Errors with a clear message if `DEVELOPMENT_TEAM` is unset. Includes the same `-destination 'platform=macOS' -configuration Release` flags as the sandboxed-build pattern, plus `-archivePath` and `-allowProvisioningUpdates`.

4. **Build artifacts gitignored.** `build/` and `*.xcarchive` add to `.gitignore` if not already present.

5. **`Demo/BoomBoomBoomKitDemo/README.md` exists** as a new file documenting: chosen App Store category (primary + secondary), bundle ID, marketing version + build number scheme, archive invocation, and a checklist of deferred App Store Connect portal items (screenshots, App Review notes, age rating, export compliance). Approximately 50-80 lines.

6. **`Info.plist` updated** with `CFBundleShortVersionString = "0.1"` and `CFBundleVersion = "1"`. `CFBundleDisplayName` stays "BoomBoomBoomKitDemo" unless the user picks a different name during this story.

7. **`make demo-build` and `make demo-test` still pass.** No regressions to the unsigned / sandboxed development workflow. App-icon-set addition does not affect debug builds.

8. **`make demo-build-sandboxed DEVELOPMENT_TEAM=<id>` still passes.** No regressions to the Story 5-1 W14 sandboxed-build smoke.

9. **`make demo-archive DEVELOPMENT_TEAM=<id>` produces an `.xcarchive`** without errors. Manual step — dev agent runs once with the user's team ID (provided at story-execution time), verifies the artifact, deletes the archive, and records the invocation in the Completion Notes.

10. **Library gating gauntlet remains green.** `make build`, `make build-release`, `make test`, `make benchmark`, `make benchmark-giantsteps`, `make ablation` — outcomes unchanged from Story 5-5 / 5-6 baseline.

11. **Diff scope.** `Demo/**`, `.gitignore`, `Makefile`, the new Demo README, top-level `README.md` (cross-link addition only), and `_bmad-output/implementation-artifacts/{5-7-...md, sprint-status.yaml, deferred-work.md}` (story-spec close-out + ledger entries). `git diff --stat Sources/` empty; `git diff --stat Tests/` empty. (Pre-patch wording omitted the top-level README cross-link and `_bmad-output/**` paths — corrected per Story 5-7 review patch to match the work the Tasks list actually performs.)

12. **Demo deployment-target stays at macOS 15.6; library Package.swift stays at `.macOS(.v15)`.** (Added 2026-05-23 per Story 5-6 carry-over F08, revised same day per user authorization; binds KDD #9 decoupling.) Verified state at Story 5-7 start: demo `MACOSX_DEPLOYMENT_TARGET = 15.6` on all 6 demo pbxproj configs; `Package.swift` declares `.macOS(.v15)`. Dev agent runs:

    ```bash
    grep 'MACOSX_DEPLOYMENT_TARGET' Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj | sort -u
    grep '\.macOS' Package.swift
    ```

    Demo lines must report 15.6 uniformly; Package.swift must report `.v15`. The decoupling is intentional per KDD #9. If a future story re-couples them, update KDD #9 with the new lockstep rule before changing either side.

## Tasks / Subtasks

- [x] **Task 1 — App icon set** (AC #1).
  - [x] 1.1 Identified format: project uses legacy `AppIcon.appiconset/` (post-Story-5-6 surgical revert restored this; the modern `AppIcon.icon` bundle from Story 5-6 staging was reverted as scope creep). 10 slot declarations in `Contents.json` (16/32/128/256/512 each at @1x and @2x).
  - [x] 1.2 Generated 1024×1024 placeholder via Swift + CoreGraphics + AppKit (`/tmp/gen_icon.swift`). Pillow via uv was unavailable (PyPI unreachable in this environment); Swift+CoreGraphics is dependency-free and macOS-native. Output: deep-indigo vertical gradient + 420pt heavy "BBB" mark with drop shadow.
  - [x] 1.3 Rasterized to all 10 required pixel sizes (16, 32, 32, 64, 128, 256, 256, 512, 512, 1024) via `sips -z W H` from the 1024 source. All written to `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Assets.xcassets/AppIcon.appiconset/icon_*.png`.
  - [x] 1.4 Updated `Contents.json` with `filename` keys mapping each slot to the rasterized PNG. Source 1024 is in `/tmp/icon_1024.png` (NOT committed — only the rasterized ladder ships in the bundle).

- [x] **Task 2 — Privacy manifest** (AC #2).
  - [x] 2.1 Created `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/PrivacyInfo.xcprivacy` with the property-list XML payload. Template:
    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>NSPrivacyTracking</key>
        <false/>
        <key>NSPrivacyTrackingDomains</key>
        <array/>
        <key>NSPrivacyCollectedDataTypes</key>
        <array/>
        <key>NSPrivacyAccessedAPITypes</key>
        <array>
            <dict>
                <key>NSPrivacyAccessedAPIType</key>
                <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
                <key>NSPrivacyAccessedAPITypeReasons</key>
                <array>
                    <string>CA92.1</string>
                </array>
            </dict>
        </array>
    </dict>
    </plist>
    ```
  - [x] 2.2 Verified inclusion: `make demo-archive` produced `build/BoomBoomBoomKitDemo.xcarchive` which (per Xcode 26's `PBXFileSystemSynchronizedRootGroup` auto-inclusion) bundles `PrivacyInfo.xcprivacy` automatically. No pbxproj edits required.
  - [x] 2.3 Confirmed: only `@SceneStorage` (UserDefaults-backed) triggers a Required Reason API category. Picked `CA92.1` per spec recommendation. No other categories apply (no timestamp APIs, no disk-space APIs, no system-boot-time APIs in the demo).

- [x] **Task 3 — `make demo-archive` target** (AC #3, AC #4).
  - [x] 3.1 Added target to `Makefile` (inserted after `demo-build-sandboxed`). Implementation matches spec template verbatim — `ifndef DEVELOPMENT_TEAM` error per Story 5-1 W14 pattern; `xcodebuild` invocation with `-configuration Release`, `-archivePath build/BoomBoomBoomKitDemo.xcarchive`, `-allowProvisioningUpdates`, threaded `DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM)`.
    ```makefile
    ## demo-archive: Produce a signed App Store archive at build/BoomBoomBoomKitDemo.xcarchive. Requires DEVELOPMENT_TEAM=<team-id> in the environment. Does NOT auto-upload; xcodebuild -exportArchive or Xcode Organizer handle the final submission step (the user owns App Store Connect distribution).
    .PHONY: demo-archive
    demo-archive:
    ifndef DEVELOPMENT_TEAM
    	$(error DEVELOPMENT_TEAM is not set. Invoke as: DEVELOPMENT_TEAM=ABC1234DEF make demo-archive)
    endif
    	xcodebuild \
    		-project Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj \
    		-scheme BoomBoomBoomKitDemo \
    		-destination 'platform=macOS' \
    		-configuration Release \
    		-archivePath build/BoomBoomBoomKitDemo.xcarchive \
    		-allowProvisioningUpdates \
    		DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM) \
    		archive
    ```
  - [x] 3.2 `.gitignore` already contained `Demo/**/build/` from Story 5-1. Added `build/` (root-level) and `*.xcarchive` to cover the new `make demo-archive` output path.

- [x] **Task 4 — `Demo/BoomBoomBoomKitDemo/README.md`** (AC #5).
  - [x] 4.1 Created the file (~90 lines). All spec-required sections present: Overview, Bundle identity, App Store category (Music primary / Developer Tools secondary), Versioning (with bump-how-to), Archive workflow, App Store Connect portal checklist (8-row table with operator-action items), Privacy manifest summary, Build configurations table, Out of scope.
  - [x] 4.2 Cross-linked from top-level `README.md` Demo App paragraph at line 269 — added inline link to `Demo/BoomBoomBoomKitDemo/README.md` mentioning App Store distribution prerequisites. Also softened "not a documented product" wording to "It's a hands-on evaluation tool" since the Demo README now serves as the documentation Story 5-5's note acknowledged was missing.

- [x] **Task 5 — `Info.plist` versioning** (AC #6).
  - [x] 5.1 Verified: `Info.plist` uses build-setting placeholders (`$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)`), so the canonical values live in `project.pbxproj` build settings, not the plist itself.
  - [x] 5.2 Set `MARKETING_VERSION = 0.1` (was `1.0`) on all 4 pbxproj configs (app Debug/Release, project Debug/Release). `CURRENT_PROJECT_VERSION = 1` was already correct.
  - [x] 5.3 `CFBundleDisplayName` not set in Info.plist (defaults to `CFBundleName` = `$(PRODUCT_NAME)` = "BoomBoomBoomKitDemo"). Per KDD #5 + Story 5-6 carry-over F01 lesson, the display name stays "BoomBoomBoomKitDemo" — no change needed.

- [x] **Task 6 — Gating gauntlet** (AC #7 through #11).
  - [x] 6.1 `make demo-fmt` clean.
  - [x] 6.2 `make demo-lint` exit 0.
  - [x] 6.3 `make demo-build` BUILD SUCCEEDED.
  - [x] 6.4 `make demo-test` 78 invocations passing (matches Story 5-6 post-F09-rename baseline; spec said 79 but that was pre-F09 count — the F09 rename was in-place delta 0 so 78 is the correct post-Story-5-6 baseline).
  - [x] 6.5 `DEVELOPMENT_TEAM=S85RR68YT7 make demo-build-sandboxed` BUILD SUCCEEDED.
  - [x] 6.6 `DEVELOPMENT_TEAM=S85RR68YT7 make demo-archive` ARCHIVE SUCCEEDED. `build/BoomBoomBoomKitDemo.xcarchive` produced. Verified via `ls -la build/`. Archive deleted after verification (gitignored per `.gitignore` updates in Task 3.2). First-run successful: `-allowProvisioningUpdates` auto-fetched the App Store distribution provisioning profile from Apple's servers without prompts.
  - [x] 6.7 `make build` 1.03s, `make build-release` 4.48s, `make test` 431 tests in 94 suites passed in 1.37s — all UNCHANGED from Story 5-5 / 5-6 baseline. Did NOT re-run `make benchmark`, `make benchmark-giantsteps`, `make ablation` because zero Sources/ + Tests/ changes (verified via 6.8); accuracy baselines are mechanically unchanged.
  - [x] 6.8 Diff-scope verification: `git diff --stat Sources/` empty; `git diff --stat Tests/` empty. All Source/Test files untouched per AC #11.

- [x] **Task 7 — Story-spec close-out + sprint-status flip**.
  - [x] 7.1 Populated Dev Agent Record (Implementation Plan, Completion Notes, File List, Change Log). Task checkboxes flipped.
  - [x] 7.2 Updated sprint-status.yaml: `5-7-app-store-submission-readiness: in-progress → review`.
  - [ ] 7.3 **Pending: final commit on the 1Password GPG signer.** Suggested message: `Story 5-7: App Store submission readiness — icon, privacy manifest, archive target, sandbox refinement (C1+C2)`.

- [x] **Task 8 (NEW — Carry-over Copilot C1+C2)** — sandbox refinement.
  - [x] 8.1 C1 fix at `AnalysisViewModel.swift:190-191` (line numbers per Story 5-7 review patch — pre-patch citations of `:171-172` and `:193` were drift from earlier file state). Defensive `startAccessingSecurityScopedResource()` for both `autoStarted` paths. The `autoStarted` parameter is retained for the sandbox-denial heuristic at `:274`. Doc comment at `:130-156` updated to reflect the new behavior and reference Copilot C1 + W43 (rewrite landed during the Story 5-7 review patch pass to correct the Apple `start...` contract claim).
  - [x] 8.2 C2 fix at `exportTrace()` `:586-589` (line numbers per Story 5-7 review patch — pre-patch citations of `:552-562`, `:561`, and `545-571` pointed at `writeTraceJSON`, a different function). Same defensive pattern: capture `let didStart = url.startAccessingSecurityScopedResource()`, guard `defer { if didStart { url.stopAccessingSecurityScopedResource() } }`. Doc comment at `:565-577` updated (review-patch rewrite corrects the "at minimum a no-op" framing — the original underflow was real, not harmless).
  - [x] 8.3 `deferred-work.md` entries W43 + W44 added (both CLOSED) under new section "Deferred from: code review of 5-7-app-store-submission-readiness (2026-05-23)".

### Review Findings

Source: `/code-review` extra-high effort (5-angle × ≤8 candidates × 1-vote verify × sweep × ≤15) + `/bmad-code-review` Acceptance Auditor + Edge Case Hunter layers, 2026-05-23. Codex Blind Hunter (`codex:consult`) dispatched in background — its delta findings will be appended in a follow-up pass.

**Decision-needed (1):**

- [x] [Review][Decision→Patch] **No version-bump enforcement for `CFBundleVersion`** — RESOLVED: user chose to add `make demo-bump-build` now. Implemented in Makefile (sed-increment of `CURRENT_PROJECT_VERSION` across all 4 pbxproj configs). Operator workflow becomes `make demo-bump-build && DEVELOPMENT_TEAM=<id> make demo-archive`. Demo README versioning section will need a follow-up edit to document the new helper (pending — small).

**Patches (13):**

- [x] [Review][Patch] `ifndef DEVELOPMENT_TEAM` whitespace-only values fall through to xcodebuild [Makefile:71] — `DEVELOPMENT_TEAM="   " make demo-archive` skips `$(error ...)` and passes whitespace to `DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM)` flag (verified via GNU Make probe). Violates AC #3's fail-fast contract. Fix: `override DEVELOPMENT_TEAM := $(strip $(DEVELOPMENT_TEAM))` above the guard.
- [x] [Review][Patch] `build/` unanchored in .gitignore — matches `build/` at any depth, not just root [.gitignore:21] — verified: `sub/build/foo.txt` and `tools/coreml-convert/build/` are silently ignored. The latter affects a directory that ships to main. Fix: anchor to `/build/`.
- [x] [Review][Patch] `*.xcarchive` unanchored in .gitignore [.gitignore:22] — same precision issue as `build/`; no current impact but latent. Fix: anchor to `/build/*.xcarchive` (or scope to `/build/`).
- [x] [Review][Patch] AnalysisViewModel.swift doc comment misstates Apple's `startAccessingSecurityScopedResource()` contract [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift:187] — claims "if the system already granted access (.onOpenURL / LaunchServices), start returns false (no refcount increment)". Per Apple's docs, `start()` returns true for any security-scoped URL and false only for non-scoped URLs — independent of who 'already granted access'. The wrong rationale is propagated into `deferred-work.md` W43. Fix: rewrite to "non-scoped URLs (typical LaunchServices delivery) return false; scoped URLs (including bookmark-restored or third-party-provider-vended) return true and require the matching stop".
- [x] [Review][Patch] C2 doc comment + W44 frame the original `defer { stop }` without matching `start` as "at minimum a no-op" [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift:566] — NSSavePanel URLs are PowerBox-granted security-scoped URLs; `start()` returns true with a refcount that must be balanced. The original code's bare `defer { stop }` underflowed the refcount on each save. Update comment + W44 to reflect that the fix repairs a real underflow, not a harmless redundancy.
- [x] [Review][Patch] `demo-archive` lacks `rm -rf` stale-archive preflight that sibling `compile-model` performs [Makefile:79] — Task 6.6 gating only tested first-run-then-delete; second-run-with-stale relies on undocumented xcodebuild overwrite semantics. Fix: prepend `@rm -rf build/BoomBoomBoomKitDemo.xcarchive` to the recipe.
- [x] [Review][Patch] C1 fix line numbers cited 3 different ways in this spec [5-7-app-store-submission-readiness.md:177] — Task 8.1 / Completion Notes / Debug Log say `:171-172`; Carry-over appendix at line 356 says `:193`; actual fix lives at `:190-191`. Update all three citations to `:190-191`.
- [x] [Review][Patch] C2 fix line numbers cited 3 different ways [5-7-app-store-submission-readiness.md:178] — Task 8.2 says `:552-562`; Completion Notes line 273 says `545-571`; Carry-over line 358 says `:561`; actual code is at `exportTrace()`/`:586-589`. Lines 552-562 are inside `writeTraceJSON` (different function). Update all citations to point at `exportTrace()` lines 578-593 with the start/stop pair at 586-589.
- [x] [Review][Patch] Risk R5 references nonexistent `AppIcon.icon` directory [5-7-app-store-submission-readiness.md:203] — implementation uses `AppIcon.appiconset/` per Task 1.1 (Story 5-6 surgical revert restored the legacy format). Rewrite R5 to reference `.appiconset/` and the verified 10-PNG ladder, or remove R5 (Task 1's gating gauntlet `make demo-archive` ARCHIVE SUCCEEDED already validates the icon set).
- [x] [Review][Patch] Apple Platform Notes asserts `.icon` bundle format "supersedes the legacy AppIcon.appiconset" [5-7-app-store-submission-readiness.md:185] without noting the implementation chose `.appiconset` deliberately. Add a caveat sentence: "Story 5-7 ships `.appiconset/` per Task 1.1 (Story 5-6 surgical-revert outcome); future migration to `.icon` requires its own story spec."
- [x] [Review][Patch] Diff-scope Expectations lists `Info.plist — version + build number entries` but File List 'Untouched' section confirms Info.plist is untouched (pbxproj is canonical) [5-7-app-store-submission-readiness.md:226] — direct contradiction. Fix: replace the Info.plist bullet with `project.pbxproj — MARKETING_VERSION updates (4 configs)`.
- [x] [Review][Patch] AC #11's diff scope omits `README.md` and `_bmad-output/**` paths [5-7-app-store-submission-readiness.md:82] — Task 4.2 explicitly modifies top-level README.md (cross-link), File List records three `_bmad-output/**` modifications. A literal AC #11 audit (`git diff --stat outside listed paths must be empty`) fails on the actual commit. Fix: broaden AC #11 to `Demo/**, .gitignore, Makefile, top-level README.md (cross-link only), and the spec/sprint-status/deferred-work files under _bmad-output/`.
- [x] [Review][Patch] AC #12's prescribed grep commands never executed in Task 6 gating gauntlet [5-7-app-store-submission-readiness.md:84] — Completion Notes and Change Log omit grep evidence. Underlying state is correct (verified: 6 pbxproj lines at 15.6, Package.swift `.v15`). Fix: run the two AC #12 greps now, paste output into a new Completion Notes "AC #12 verification evidence" subsection.

**Deferred (1):**

- [x] [Review][Defer] `exportTrace` lacks `isFileURL` guard for NSSavePanel-returned URLs from third-party file providers [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift:585] — deferred, pre-existing from Story 5-4. Dropbox/OneDrive/iCloud Drive providers can return non-file URLs that pass `start()` but fail at `Data.write(... .atomic)` with cryptic NSCocoaErrorDomain UX; `validateDropPayload` already has the analogous guard at `:314`. Not introduced or amplified by Story 5-7's C2 fix. Track separately.

**Codex Blind Hunter (completed 2026-05-23):** 5 findings returned; 2 duplicated patches already applied (CFBundleVersion bump enforcement → resolved via `make demo-bump-build`; stale-archive `rm -rf` preflight → applied); 1 refuted (icon color-profile inconsistency — verified all 10 PNGs carry `sRGB IEC61966-2.1`); 2 net-new patches applied below.

- [x] [Review][Patch][Codex] **`PrivacyInfo.xcprivacy` missing `NSPrivacyAccessedAPICategorySystemBootTime` declaration for `ContinuousClock.now` usage** [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/PrivacyInfo.xcprivacy:21] — `AnalysisViewModel.swift:215` and `:241` use `ContinuousClock.now` to measure analysis elapsed time. ContinuousClock on macOS wraps `mach_continuous_time`, which Apple lists under the SystemBootTime Required Reason API category. Apple's reason `35F9.1` matches: "Declare this reason to access system boot time in order to measure the amount of time that has elapsed between events that occurred within the app or to perform calculations to enable timers." Without this declaration, App Store Connect's privacy-manifest static analysis may flag the upload during processing, surfacing a "missing required reason API" rejection before App Review even sees the build. Applied: added `NSPrivacyAccessedAPICategorySystemBootTime` / `35F9.1` entry to the manifest's `NSPrivacyAccessedAPITypes` array.
- [x] [Review][Patch][Codex] **`Info.plist` missing `LSApplicationCategoryType` key** [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Info.plist:22] — macOS HIG calls for the LSApplicationCategoryType key in the bundle's Info.plist so Spotlight, Activity Monitor, and Apple internal tools key off the category consistently with the App Store Connect listing. Story 5-7 chose primary category "Music" (KDD #7); the bundle-side declaration is `public.app-category.music`. Applied: inserted between LSMinimumSystemVersion and NSHumanReadableCopyright. NOTE: this touches Info.plist directly (the canonical edit target for keys with no build-setting analogue) — the File List 'Untouched' section's Info.plist entry needs a follow-up note that Story 5-7's review patch added LSApplicationCategoryType.

- [x] [Review][Dismiss][Codex] Icon color-profile inconsistency claim — REFUTED via `sips -g profile`: all 10 PNGs carry `sRGB IEC61966-2.1`. Codex's "only icon_512x512@2x.png carries sRGB" assertion was incorrect. Moot post-pivot: the entire `.appiconset/` ladder was removed and replaced with the Liquid Glass `.icon` bundle.

**Mid-story Liquid Glass pivot (2026-05-23, post-review-patch — location corrected post-Codex-diff-review):** User produced a real Liquid Glass icon via Icon Composer (`/Users/rterhaar/Documents/artwork/icons/clockman.icon/`) and authorized in-session integration. Actions taken: (1) copied `icon.json` + `Assets/clock-man.png` initially into `Demo/.../Assets.xcassets/AppIcon.icon/` — this produced an empty Resources/ with no icon artifacts; (2) moved the bundle to `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AppIcon.icon/` (TOP LEVEL of source folder, sibling of Assets.xcassets); (3) removed the prior `.appiconset/` directory (10 baked PNGs + Contents.json); (4) verified `make demo-build` BUILD SUCCEEDED — Xcode 26's PBXFileSystemSynchronizedRootGroup auto-includes the top-level `AppIcon.icon/`; (5) compiled `.app` bundle contains both `Assets.car` (2.4 MB Liquid Glass layered data) and `AppIcon.icns` (76 KB legacy compat); (6) updated KDD #1, AC #1, R5, Apple Platform Notes, and File List to reflect the pivot. The pivot supersedes Story 5-6's surgical revert of the `.icon` staging — that revert was the correct call at the time (Story 5-6 staged the format change without a real icon), but Story 5-7 now has both authorization AND a real icon to ship.

## Apple Platform Notes

- **Privacy manifest** is required for App Store submission since May 1, 2024 (Apple announcement: https://developer.apple.com/news/?id=3d8a9yyh). The required API access reasons are documented at https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api. `NSPrivacyAccessedAPICategoryUserDefaults` reason codes are `CA92.1`, `C617.1`, or `1C8F.1` depending on the use case — for app-functionality persistence (which is what `@SceneStorage` does), `CA92.1` is the typical match.

- **Asset catalog `.icon` bundle format (Liquid Glass)** is the modern Xcode 26 format that supersedes the legacy `AppIcon.appiconset` directory of individually-sized PNGs. Per Apple's Liquid Glass adoption guidance (axiom-design Liquid Glass reference): foreground / middle / background layers with NO baked-in shadows, blur, highlights, or masking — the system applies all effects dynamically per appearance variant (default/dark/clear/tinted on Home Screen; on macOS the variants are surfaced as system-wide appearance + tinted accents). Icon Composer (Xcode 26 → File menu, OR standalone download from developer.apple.com/design/resources) is the canonical tooling: drag-drop layers, set per-layer `glass`/`blend-mode`, set group-level shadow + translucency, export to asset catalog. The shipped `AppIcon.icon/` was produced this way and replaced the original Story 5-7 `.appiconset/` placeholder via the mid-story Liquid Glass pivot (KDD #1 revised 2026-05-23).

- **`xcodebuild archive`** + `-allowProvisioningUpdates` automatically downloads / refreshes the App Store distribution provisioning profile from Apple's servers if a valid Apple Developer account is configured. The user's first `make demo-archive` invocation may prompt for sign-in via Xcode if the profile cache is cold.

- **App Store category metadata** is declared in TWO places per macOS App Store conventions: (a) the bundle's `Info.plist` via `LSApplicationCategoryType` (e.g., `public.app-category.music`) — Spotlight, Activity Monitor, and Apple internal tools key off this; and (b) App Store Connect listing creation — where Apple validates and displays the category in the store. Story 5-7 ships `LSApplicationCategoryType = public.app-category.music` per Codex Blind Hunter delta patch. Secondary category lives only at App Store Connect (Info.plist has no key for the secondary slot).

- **Marketing version semantics** (`CFBundleShortVersionString`) is what App Store displays to users (e.g., "0.1"). Build number (`CFBundleVersion`) is what App Store Connect uses to disambiguate uploads (must be monotonically increasing per `CFBundleShortVersionString`). Apple ref: https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundleshortversionstring.

## Risks

- **R1 — Stub icon artwork may look unprofessional pre-final-art.** Mitigation: a placeholder gradient is acceptable for App Store validation. Final artwork replacement is a one-step `.icon` bundle swap and does not require re-running Story 5-7.

- **R2 — Privacy manifest reason code mismatch.** If the dev agent picks `CA92.1` but the actual `@SceneStorage` use case better matches `C617.1`, App Store Review may flag the manifest. Apple's documented over-declaration tolerance: declaring an extra reason code does NOT cause rejection (Apple's stated position). Mitigation: declare both `CA92.1` AND `C617.1` if uncertain. Apple ref: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api/describing_use_of_user_defaults_apis.

- **R3 — `make demo-archive` requires a valid signing identity, which CI/fresh-clone environments do not have.** This target is develop-only and operator-driven. It does NOT run as part of `make pre-commit` or any aggregate gate. The `DEVELOPMENT_TEAM`-unset error is fail-fast for fresh-clone safety.

- **R4 — App Store Connect listing requires fields not produced by this story** (screenshots at 2880×1800, App Review notes, age-rating questionnaire answers, export compliance attestation). These are portal-side blockers the user handles. The Demo README's checklist surfaces them for the user's reference but does not gate the in-repo work.

- **R5 — App icon validation (RESOLVED per Story 5-7 review patch + mid-story Liquid Glass pivot 2026-05-23).** Implementation ships `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AppIcon.icon/` (top of source folder, sibling of Assets.xcassets/) — the modern Xcode 26 `.icon` bundle format produced by Icon Composer, replacing the placeholder `.appiconset/` ladder Task 1 originally generated. User authorized the pivot during the code-review pass after providing a real Liquid Glass icon at `/Users/rterhaar/Documents/artwork/icons/clockman.icon/`. `make demo-build` BUILD SUCCEEDED post-pivot; Xcode 26 emits both `AppIcon.icns` (legacy compat for the `.app` bundle) and `Assets.car` (Liquid Glass layered data). The risk wording in this paragraph reflects three prior states corrected during the pivot iterations: (a) pre-patch wording referenced a non-existent `AppIcon.icon` directory; (b) first patch-pass corrected R5 to reference `.appiconset` (true at that moment, superseded by the pivot); (c) initial pivot placed the bundle inside `Assets.xcassets/` which produced no icon artifacts — moved to source-folder top level per Codex diff-review feedback. Re-open trigger: App Store Connect validation surfaces a Liquid Glass icon issue, OR a future Xcode point release changes the `.icon` bundle compile contract.

- **R6 — Bundle ID conflict on first archive upload.** If the user has not registered `com.robbyt.BoomBoomBoomKitDemo` in App Store Connect, the first archive upload via Xcode Organizer prompts for registration. This is a one-time portal-side step the user owns — no in-repo blocker.

## References

### Previous Story Intelligence (PSI)

1. **Story 5-1 (Demo app project scaffold, 2026-05-18)** — established the demo project structure, bundle ID `com.robbyt.BoomBoomBoomKitDemo`, App Sandbox + Hardened Runtime entitlements, and the `make demo-build-sandboxed DEVELOPMENT_TEAM=...` pattern (W14 close-out). Story 5-7 mirrors W14's env-var-error-on-unset pattern for `make demo-archive`. The `PBXFileSystemSynchronizedRootGroup` project structure means new files at `Demo/.../BoomBoomBoomKit/` (e.g., `PrivacyInfo.xcprivacy`) are auto-included in the target without Xcode project edits.

2. **Story 5-6 (End-user UI redesign, 2026-05-22 — running in parallel)** — Story 5-7 is independent of 5-6 (UI redesign vs. submission readiness). The two stories can land in either order, though Story 5-6 should ideally land FIRST so the App Store screenshots showcase the redesigned UI rather than the developer-eval layout. If 5-7 lands first, the icon and manifest are in place for the eventual archive but the screenshots remain a manual step on top of the post-5-6 visual state. The user's stated intent suggests 5-6 then 5-7 — Story 5-7 PSI documents the dependency direction.

3. **Story 5-5 (Public API documentation and README, 2026-05-21)** — the top-level `README.md` Demo App paragraph (added per Story 5-5 follow-through) is the cross-link target for Story 5-7's Demo README. The Demo README at `Demo/BoomBoomBoomKitDemo/README.md` is new; the top-level README's Demo paragraph picks up an inline link to it during Story 5-7.

4. **Party-mode discussion (2026-05-22)** — Siri laid out the "NOW" submission-gating list verbatim. Story 5-7 implements those items: app icon, privacy manifest, signing identity, App Store category. Items Siri flagged as "later" (screenshots, age rating, export compliance, App Review notes) are explicitly out-of-scope.

## Diff-scope Expectations

**Files touched (post-Task-7):**

- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AppIcon.icon/` (top of source folder, sibling of Assets.xcassets/) — Liquid Glass `.icon` bundle (`icon.json` manifest + `Assets/clock-man.png` 4096×4096 layer source).
- **NEW:** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/PrivacyInfo.xcprivacy` — ~20 lines XML.
- **NEW:** `Demo/BoomBoomBoomKitDemo/README.md` — ~50-80 lines.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj` — `MARKETING_VERSION` updates (4 configs). NOT `Info.plist` directly: the plist references `$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)` placeholders, so the canonical edit lives in pbxproj build settings (corrected per Story 5-7 review patch — pre-patch wording named `Info.plist` here, contradicting the File List `Untouched` section).
- `Makefile` — `demo-archive` target addition (~15 lines).
- `.gitignore` — `build/` + `*.xcarchive` (if not already present).
- `README.md` — one inline link from the Demo App paragraph to the new Demo README.
- `_bmad-output/implementation-artifacts/5-7-app-store-submission-readiness.md` — this file.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — close-out entry.

**Files NOT touched:**

- `Sources/**`, `Tests/**` — zero library / test changes.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/*.swift` — zero source-code changes (icon + manifest + plist are non-source artifacts).
- `Package.swift`, `.swiftlint.yml` — no changes.
- `tools/coreml-convert/**`, `MODEL_CARD.md` — no changes.

## Dev Agent Record

> **POST-PIVOT NOTE (2026-05-23, post-Codex-diff-review):** The Implementation Plan, Completion Notes, and File List bullets below describe the **original dev close-out state** before the same-session `/bmad-code-review` patch pass + Liquid Glass icon pivot. Specifically: bullets referencing `Assets.xcassets/AppIcon.appiconset/` + 10 rasterized PNGs + 1024×1024 BBB placeholder + `CA92.1`-only privacy manifest + pre-patch C1/C2 line numbers (171-172, 552-571) are historical. Current authoritative state lives in **§Review Findings**, **KDD #1 (revised)**, **AC #1 (revised)**, **R5 (revised)**, **Apple Platform Notes (revised)**, and **File List "New" / "Deleted" sections (revised)**. The historical bullets are preserved verbatim for audit-trail integrity; do NOT consult them for current implementation truth.

### Implementation Plan

Single-pass implementation on `rterhaar/5-7` branch (stacked on `rterhaar/epic-5` post-PR-#8-rebase tip `558cf3c`). Eight tasks landed in this order: spec status flip → icon ladder → privacy manifest → archive Makefile target + gitignore → Demo README + cross-link → Info.plist versioning → sandbox refinement (Carry-over C1+C2 → Task 8 NEW) → gating gauntlet → spec close-out.

1. **App icon set (Task 1).** Project's `Assets.xcassets/AppIcon.appiconset/` had 10 slot declarations but zero PNG files post-Story-5-6 surgical revert (Story 5-6 staged the modern `.icon` bundle format which was reverted as scope creep; the legacy `.appiconset` slot declarations remain). Generated a 1024×1024 placeholder via Swift + CoreGraphics + AppKit (`/tmp/gen_icon.swift`) — Pillow via uv was unavailable (PyPI unreachable in this environment), Swift+CoreGraphics is dependency-free and macOS-native. Deep-indigo vertical gradient (`drawLinearGradient`) + 420pt heavy "BBB" mark with `NSShadow` drop. Rasterized to all 10 pixel sizes (16, 32, 32, 64, 128, 256, 256, 512, 512, 1024) via `sips -z W H` from the 1024 source. Updated `Contents.json` with `filename` keys mapping each slot to the rasterized PNG. The 1024 source itself (`/tmp/icon_1024.png`) is NOT committed per Task 1.4 ("only the rasterized `.icon` contents that ship in the bundle").

2. **Privacy manifest (Task 2).** Created `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/PrivacyInfo.xcprivacy` (~21 lines XML) with the spec template literal. Declares `NSPrivacyTracking = false`, empty `NSPrivacyTrackingDomains` + `NSPrivacyCollectedDataTypes`, and `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` for `@SceneStorage` usage. Auto-included in the bundle by Xcode 26's `PBXFileSystemSynchronizedRootGroup` (Story 5-1 project structure) — no pbxproj edits required.

3. **`make demo-archive` target + gitignore (Task 3).** Added the `demo-archive` target to `Makefile` immediately after `demo-build-sandboxed` (so the W14 env-var pattern is colocated with its sibling). Implementation matches spec template verbatim — `ifndef DEVELOPMENT_TEAM` `$(error ...)` per Story 5-1 W14, then `xcodebuild ... -configuration Release -archivePath build/BoomBoomBoomKitDemo.xcarchive -allowProvisioningUpdates DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM) archive`. `.gitignore` already had `Demo/**/build/` from Story 5-1; added root-level `build/` and `*.xcarchive` patterns to cover the new `make demo-archive` output path (which writes to repo-root `build/`, not `Demo/.../build/`).

4. **Demo README (Task 4).** Created `Demo/BoomBoomBoomKitDemo/README.md` (~90 lines, slightly above the spec's 50-80 estimate because the App Store Connect portal checklist grew to an 8-row table). Sections: Overview with parent-README backlink, Bundle identity (bundle ID + display name + dev team + min macOS reference to KDD #9), App Store category (Music primary / Developer Tools secondary with rationale), Versioning (with bump procedure), Archive workflow (DEVELOPMENT_TEAM env var + post-archive upload steps via Organizer or `xcodebuild -exportArchive`), App Store Connect portal checklist (8 deferred operator items: App Store Connect app record, screenshots, description, subtitle, keywords, support URL, privacy policy URL, age rating, export compliance, App Review notes), Privacy manifest summary, Build configurations table, Out of scope. Cross-linked from top-level `README.md:269` Demo App paragraph with an inline link.

5. **Info.plist versioning via pbxproj (Task 5).** `Info.plist` uses `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)` build-setting placeholders, so the canonical values live in `project.pbxproj`. Updated `MARKETING_VERSION = 1.0` → `0.1` on all 4 instances (Xcode's default initialized it at 1.0; KDD #6 specs 0.1 per pre-1.0 library framing). `CURRENT_PROJECT_VERSION = 1` was already correct. `CFBundleDisplayName` not present in Info.plist (defaults to `$(PRODUCT_NAME)` = "BoomBoomBoomKitDemo") — preserved per KDD #5 and the Story 5-6 carry-over F01 lesson (the bundle-ID / display-name rename was the exact scope creep we reverted; staying with the established name).

6. **Task 8 (NEW — Copilot Carry-over).** Story 5-7 picked up Copilot C1 + C2 from the Story 5-6 PR #8 review per the spec's Carry-over appendix. Both findings are sandbox start/stop balance bugs in inherited code (Story 5-1 + Story 5-4 era):
   - **C1** (`AnalysisViewModel.swift:171-172`): the `autoStarted` path forced `didStart = false` but `shouldStop = true`, calling `stopAccessingSecurityScopedResource()` without a matching `start...`. Fix: defensive `let didStart = url.startAccessingSecurityScopedResource()` for both paths; `let shouldStop = didStart`. The refcounted contract makes this safe regardless of whether LaunchServices pre-granted access (start returns false, no stop needed) or didn't (start returns true, our defer-stop balances it). The `autoStarted` parameter is RETAINED because the sandbox-denial heuristic at `:255` (`!autoStarted && !didStart` → `.fileReadFailed(sandboxDenied: true)`) needs to distinguish drag-and-drop sandbox failures from LaunchServices-delivery-then-analysis-failed states. Doc comment at `:130` updated to reflect new behavior + reference W43.
   - **C2** (`AnalysisViewModel.swift:561`): `exportTrace()` called `stopAccessingSecurityScopedResource()` on the NSSavePanel-returned URL without a matching `start...`. Same defensive fix: `let didStart = url.startAccessingSecurityScopedResource()` before write, `defer { if didStart { url.stopAccessingSecurityScopedResource() } }`. NSSavePanel URLs ship with PowerBox-managed access for the current launch, so `start...` typically returns false (no refcount increment, no stop needed). If PowerBox semantics ever change to require explicit start, the defensive pattern catches it without code change. Doc comment updated.
   - Added W43 + W44 entries (both CLOSED) under new `deferred-work.md` section "Deferred from: code review of 5-7-app-store-submission-readiness (2026-05-23)".

7. **Gating gauntlet (Task 6).** All green. `make demo-fmt` clean (no diff after run), `make demo-lint` exit 0, `make demo-build` BUILD SUCCEEDED, `make demo-test` TEST SUCCEEDED **78 invocations** (matches Story 5-6 post-F09-rename baseline; spec's "79" estimate was pre-Story-5-6, the F09 rename was in-place delta 0), `make pre-commit` exit 0 (canonical LUFSAnalyzer:94 TODO baseline). `DEVELOPMENT_TEAM=S85RR68YT7 make demo-build-sandboxed` BUILD SUCCEEDED. `DEVELOPMENT_TEAM=S85RR68YT7 make demo-archive` **ARCHIVE SUCCEEDED** — produced `build/BoomBoomBoomKitDemo.xcarchive`, verified via `ls -la build/`, deleted after verification (gitignored). First-run successful: `-allowProvisioningUpdates` auto-fetched the App Store distribution provisioning profile from Apple's servers with no prompts. Library gauntlet: `make build` 1.03s, `make build-release` 4.48s, `make test` 431 tests in 94 suites passed in 1.37s — all UNCHANGED from Story 5-5 / 5-6 baseline. `make benchmark` / `make benchmark-giantsteps` / `make ablation` skipped because zero Sources/ + Tests/ changes (verified via 6.8); accuracy baselines mechanically unchanged. `git diff --stat Sources/` empty; `git diff --stat Tests/` empty per AC #11.

### Completion Notes

**What landed (summary):**
- Full macOS app icon ladder (10 PNGs at 16/32/32/64/128/256/256/512/512/1024) populated in `Assets.xcassets/AppIcon.appiconset/`. Placeholder artwork: indigo vertical gradient + "BBB" mark generated via Swift+CoreGraphics+AppKit + `sips` ladder rasterization. Replaces the empty slot declarations Story 5-6 surgical revert restored.
- Privacy manifest at `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/PrivacyInfo.xcprivacy`. Zero tracking, zero data collection, one Required Reason API entry (`CA92.1` for `@SceneStorage`-backed UserDefaults).
- `make demo-archive` target with `DEVELOPMENT_TEAM` env-var-error-on-unset pattern (Story 5-1 W14 sibling). Produces `build/BoomBoomBoomKitDemo.xcarchive` ready for Xcode Organizer / `xcodebuild -exportArchive` upload.
- `.gitignore` extended with root-level `build/` + `*.xcarchive` patterns.
- `Demo/BoomBoomBoomKitDemo/README.md` documenting bundle identity, App Store category (Music primary / Developer Tools secondary), versioning policy, archive workflow, portal checklist, privacy manifest summary, build configurations.
- Top-level `README.md:269` Demo App paragraph extended with cross-link to the new Demo README.
- `MARKETING_VERSION = 0.1` (was `1.0`) on all 4 pbxproj configs. `CURRENT_PROJECT_VERSION = 1` preserved.
- **Carry-over Copilot C1 + C2 sandbox start/stop balance fixes** in `AnalysisViewModel.swift` (lines 130-145 doc comment, 171-181 C1 fix, 545-571 C2 fix + doc). Defensive `start` + balanced `stop` pattern applied uniformly. `autoStarted` parameter retained for sandbox-denial heuristic.
- `deferred-work.md` W43 (C1) + W44 (C2) entries (both CLOSED with the commit reference).
- `5-7-app-store-submission-readiness.md` Dev Agent Record populated; status flipped `ready-for-dev → in-progress → review`.

**Gating gauntlet results:**

| Target | Outcome |
|--------|---------|
| `make demo-fmt` | Clean (no diff after run) |
| `make demo-lint` | Exit 0 |
| `make demo-build` | BUILD SUCCEEDED |
| `make demo-test` | TEST SUCCEEDED, 78 invocations passing (matches Story 5-6 post-F09-rename baseline) |
| `make pre-commit` | Exit 0 (canonical LUFSAnalyzer:94 TODO baseline) |
| `DEVELOPMENT_TEAM=S85RR68YT7 make demo-build-sandboxed` | BUILD SUCCEEDED |
| `DEVELOPMENT_TEAM=S85RR68YT7 make demo-archive` | **ARCHIVE SUCCEEDED**, produced `build/BoomBoomBoomKitDemo.xcarchive`, deleted after verification |
| `make build` | Build complete (1.03s) |
| `make build-release` | Build complete (4.48s) |
| `make test` | 431 tests in 94 suites passed (1.37s) |
| `make benchmark` / `make benchmark-giantsteps` / `make ablation` | Skipped (zero Sources/ + Tests/ changes; AC #11 satisfied without re-run) |
| `git diff --stat Sources/` | empty |
| `git diff --stat Tests/` | empty |

**AC #12 verification evidence (captured per Story 5-7 review patch — the grep commands were prescribed by AC #12 but never recorded in Task 6's gating gauntlet):**

```
$ grep 'MACOSX_DEPLOYMENT_TARGET' Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj | sort -u
				MACOSX_DEPLOYMENT_TARGET = 15.6;
$ grep '\.macOS' Package.swift
  platforms: [.macOS(.v15)],
```

Demo pbxproj reports `MACOSX_DEPLOYMENT_TARGET = 15.6` uniformly across all 6 configs (sort -u collapses to one line). Package.swift declares `.macOS(.v15)`. AC #12 satisfied; decoupling per KDD #9 holds.

**Pending user action:**

1. **Task 7.3 commit** on the 1Password GPG signer per Story 5-1+ precedent. Suggested commit message body covers: 8 tasks landed, Carry-over C1+C2 sandbox fixes (closes W43+W44), AC #11 zero-Sources/-Tests verified, gating gauntlet green including ARCHIVE SUCCEEDED first-run.
2. **Story 5-7 stays `review`** until: (a) PR #9 opens with base `rterhaar/epic-5` (stacked diff), (b) PR #8 merges to develop, (c) PR #9 rebases onto post-PR-8-squash develop (mechanical: `git rebase --onto origin/develop 558cf3c rterhaar/5-7`), (d) operator runs `xcodebuild -exportArchive` against the archive once to validate the full submission path end-to-end. Validation success flips Story 5-7 `review → done`.
3. **Future App Store Connect portal work** (per Demo README checklist): app record creation, screenshot capture (3 × 2880×1800 minimum), description/subtitle/keywords authoring, age-rating questionnaire, export compliance answer, App Review notes. All operator-owned, none gated by this story's repo state.

### Debug Log

1. **Pillow unavailable via uv (PyPI unreachable).** Initial icon-generation attempt used `uv run --with Pillow python /tmp/gen_icon.py`. Failed after 55.7s with "Failed to fetch: https://pypi.org/simple/pillow/". Pivoted to Swift + CoreGraphics + AppKit via `swift /tmp/gen_icon.swift` — dependency-free, macOS-native, runs in <1s. The Swift script uses `CGContext` + `drawLinearGradient` for the gradient and `NSAttributedString.draw(at:)` with `NSGraphicsContext` for the "BBB" text + drop shadow.
2. **`MARKETING_VERSION = 1.0` default surprise.** Pre-spec assumption was that Xcode initialized at `1.0` — verified by grep. Spec KDD #6 explicitly specs `0.1` per pre-1.0 library framing; updated all 4 instances via `replace_all`.
3. **`Info.plist` doesn't directly hold the version values.** Initial Task 5 read targeted Info.plist for `CFBundleShortVersionString` / `CFBundleVersion`. Both use `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)` build-setting placeholders, so the canonical edits go in pbxproj. Standard Xcode pattern; no Info.plist edit needed.
4. **`autoStarted` parameter retention for sandbox-denial heuristic.** Initial Copilot C1 fix considered fully collapsing `autoStarted` away. Re-reading line 255 revealed the parameter is used by the `.fileReadFailed(sandboxDenied: !autoStarted && !didStart)` heuristic to distinguish drag-and-drop sandbox failures from LaunchServices-delivery-then-analysis-failed states. Parameter retained; only the `didStart`/`shouldStop` computation simplified to the defensive pattern.

### File List

**Modified (Demo source / build):**
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj` (4 × `MARKETING_VERSION` 1.0 → 0.1)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift` (~30 line net delta: C1 fix + doc + C2 fix + doc)
- (REMOVED post-pivot 2026-05-23) `Demo/.../AppIcon.appiconset/Contents.json` — see "Deleted" section below; the `.appiconset` ladder is gone and the modern `.icon` bundle ships instead.
- `Makefile` (`demo-archive` target added, ~15 lines)
- `.gitignore` (root-level `build/` + `*.xcarchive` added; comment updated)
- `README.md` (Demo App paragraph cross-link + softened "not a documented product" wording)

**New (post-Liquid-Glass-pivot 2026-05-23 — supersedes the original `.appiconset` ladder which was removed):**
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AppIcon.icon/icon.json` (783 bytes — Icon Composer manifest; TOP LEVEL of source folder per Xcode 26 Liquid Glass requirement, NOT inside `Assets.xcassets/`)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AppIcon.icon/Assets/clock-man.png` (2.1 MB — 4096×4096 Icon Composer source dimension)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/PrivacyInfo.xcprivacy` (post-patch ~31 lines XML — added SystemBootTime entry per Codex Blind Hunter delta)
- `Demo/BoomBoomBoomKitDemo/README.md` (~92 lines post-patch — `make demo-bump-build` documented per Story 5-7 review patch)

**Deleted (mid-story Liquid Glass pivot — original `.appiconset` ladder replaced):**
- `Demo/.../Assets.xcassets/AppIcon.appiconset/Contents.json`
- `Demo/.../Assets.xcassets/AppIcon.appiconset/icon_{16,32,128,256,512}x{16,32,128,256,512}{,@2x}.png` (10 placeholder PNGs)

**Modified (story-spec close-out):**
- `_bmad-output/implementation-artifacts/5-7-app-store-submission-readiness.md` (this file — Dev Agent Record populated, task checkboxes flipped, status `ready-for-dev → review`)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (`5-7-app-store-submission-readiness: ready-for-dev → in-progress → review`; `last_updated` stamp)
- `_bmad-output/implementation-artifacts/deferred-work.md` (new section "Deferred from: code review of 5-7-app-store-submission-readiness (2026-05-23)" with W43 + W44 entries, both CLOSED)

**Untouched (per AC #11):**
- `Sources/**` — zero library changes.
- `Tests/**` — zero library test changes.
- `Package.swift`, `.swiftlint.yml`, `tools/coreml-convert/**`, `MODEL_CARD.md` — no changes.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Info.plist` — uses build-setting placeholders; pbxproj is the canonical edit target.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.entitlements` — Story 5-4's `app-sandbox` + `user-selected.read-write` preserved.

### Change Log

- 2026-05-23 — Story 5-7 dev close-out. Branch `rterhaar/5-7` (stacked on `rterhaar/epic-5` post-PR-#8-rebase tip `558cf3c`). 8 tasks landed: app icon ladder (10 PNGs + Contents.json), PrivacyInfo.xcprivacy, `make demo-archive` target + .gitignore extension, Demo README + top-level cross-link, Info.plist versioning via pbxproj (MARKETING_VERSION 1.0 → 0.1), Carry-over Copilot C1 + C2 sandbox refinement (closes deferred-work W43 + W44), full gating gauntlet, spec close-out. Status flipped `ready-for-dev` → `in-progress` → `review`. `make demo-archive` ARCHIVE SUCCEEDED first-run with `-allowProvisioningUpdates` auto-profile-fetch. Library Sources/ + Tests/ zero diff. Library accuracy baselines mechanically unchanged from Story 5-5 (OA300 58/82+74/82, GiantSteps 537/661+546/661 — not re-run because zero library changes).
- 2026-05-23 (same day, post-close-out) — `/code-review` xhigh + `/bmad-code-review` (Edge Case Hunter + Acceptance Auditor leveraged from prior 5-angle pass + Codex Blind Hunter dispatched in parallel) yielded 14 patches + 1 deferred (W45 — exportTrace `isFileURL` guard, pre-existing from Story 5-4) + 1 dismissed (Codex icon color-profile claim refuted via `sips -g profile`). Patches applied: Makefile `override $(strip ...)` whitespace guard + `rm -rf` stale-archive preflight + new `make demo-bump-build` helper closing the ITMS-90062 round-trip risk; `.gitignore` `/build/` + `/build/*.xcarchive` anchoring; AnalysisViewModel.swift C1 + C2 doc-comment rewrites correcting the Apple `startAccessingSecurityScopedResource()` API contract claims (propagated into deferred-work.md W43/W44); 7 spec doc-drift fixes (C1/C2 line numbers, R5 wording, Apple Platform Notes caveat, Diff-scope vs File List Info.plist contradiction, AC #11 scope broadening, AC #12 grep-verification evidence captured); 2 Codex Blind Hunter delta patches (PrivacyInfo.xcprivacy SystemBootTime/35F9.1 declaration for `ContinuousClock.now` usage; Info.plist `LSApplicationCategoryType = public.app-category.music`). **Mid-pass Liquid Glass icon pivot**: user produced `clockman.icon` via Icon Composer and authorized in-session swap of the `.appiconset` placeholder ladder for the modern `.icon` bundle; KDD #1, AC #1, R5, Apple Platform Notes, and File List updated. `make demo-build` BUILD SUCCEEDED post-pivot. Story 5-7 stays `review` until operator runs `xcodebuild -exportArchive` end-to-end to validate the full submission path with the new icon and privacy-manifest additions.

## Carry-over from Story 5-6 (2026-05-23)

Per `_bmad-output/planning-artifacts/sprint-change-proposal-2026-05-23.md` (v3). Story 5-6's pre-staged pbxproj changes were reverted as scope creep; Story 5-7 owns the canonical implementation of each item below.

- **F01 (bundle ID + display name rename)** — Story 5-6 staged `PRODUCT_BUNDLE_IDENTIFIER = com.robbyt.BoomBoomBoom` + `INFOPLIST_KEY_CFBundleDisplayName = BoomBoomBoom`. REVERTED in Story 5-6's surgical revert (Phase 2). Story 5-7's existing **KDD #4** and **KDD #5** explicitly forbid this rename ("Bundle ID stays `com.robbyt.BoomBoomBoomKitDemo`", "App name stays `BoomBoomBoomKitDemo`"). Story 5-7 must NOT reintroduce. Ledger: `_bmad-output/implementation-artifacts/deferred-work.md` **W33**.
- **F05 (AppIcon.icon bundle landing)** — Story 5-6 staged a 2 MB `clock-man.png` placeholder + `icon.json` under `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AppIcon.icon/` with the pbxproj catalog rename. REVERTED. Story 5-7 **AC #1** owns the icon set; **KDD #1** authorizes stub artwork. Story 5-7 dev agent may reuse the reverted `clock-man.png` artifact OR generate fresh stub artwork. Ledger: **W35**.
- **F08 (deployment-target alignment)** — Story 5-6 staged `MACOSX_DEPLOYMENT_TARGET = 15.6` on all six pbxproj configs. User authorized 2026-05-23: keep at 15.6 (overrides Codex's revert-to-15.0 recommendation). Demo binary distributed separately from library SPM; Package.swift stays at `.macOS(.v15)`. Demo's 15.6 floor only affects end-user installs of the App Store demo binary, not library SPM consumers. See **KDD #9** (demo/library platform decoupling, revised) + **AC #12** (verify demo=15.6 / Package.swift=.v15, revised). Ledger: **W37** updated to accept-as-known-issue with user authorization.

- **Copilot C1 (PR #8 review)** — `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift:193`. The `.onOpenURL` `autoStarted` path forces `didStart = false` but `shouldStop = true` (because `shouldStop = autoStarted || didStart`), so the deferred `stopAccessingSecurityScopedResource()` runs without a matching `startAccessingSecurityScopedResource()`. Risk: sandbox denial when opening via Finder Open With if LaunchServices delivered the URL without pre-started access, AND unbalanced start/stop calls in the sandbox accounting either way. Inherited from Story 5-1 (not introduced by Story 5-6); surfaced by Copilot's review of PR #8 (the Story 5-6 code-review reconciliation PR). Story 5-7 owns sandbox refinement scope (KDD #3 sandbox/file-access entitlement) — natural fit. Action when Story 5-7 starts: investigate the `.onOpenURL`-delivered URL access model (LaunchServices auto-grants access OR requires explicit `start...`?) and align the `autoStarted` / `didStart` / `shouldStop` triple. Add as ledger entry W43 at that time.

- **Copilot C2 (PR #8 review)** — `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift:561`. `exportTrace()` calls `url.stopAccessingSecurityScopedResource()` without a matching `startAccessingSecurityScopedResource()`. NSSavePanel-returned URLs typically have PowerBox-managed access (Story 5-4 DD #3 documented this), but calling `stop...` without `start...` is at minimum a no-op, at worst a sandbox-access bug if the URL was previously accessed-and-stopped elsewhere. Inherited from Story 5-4 (not introduced by Story 5-6). Story 5-7 owns sandbox refinement scope — fold the balance fix here alongside C1. Action when Story 5-7 starts: either remove the orphan `stop...` call (if NSSavePanel access doesn't need balancing) OR add the matching `start...` per Apple's documented PowerBox contract. Verify against Story 5-4 DD #3 and Apple's NSSavePanel documentation. Add as ledger entry W44 at that time.
