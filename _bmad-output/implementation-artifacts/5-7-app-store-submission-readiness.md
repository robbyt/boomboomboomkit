# Story 5.7: App Store Submission Readiness Scaffold

Story ID: 5.7
Story Key: 5-7-app-store-submission-readiness
Epic: 5 — Developer Experience (Demo App + Documentation)
Status: ready-for-dev

## Story

As the maintainer preparing the BoomBoomBoomKitDemo app for free macOS App Store distribution,
I want the in-repo prerequisites for a signed, App-Review-acceptable archive build to be in place — app icon, privacy manifest, signing-aware archive workflow, and a recorded category decision —
So that the App Store Connect submission flow has zero in-tree blockers and the actual upload becomes a packaging-and-portal task rather than a project-restructure task.

**Scope clarification (read first).** Story 5-7 lands the file-system / build-system prerequisites that have to live in the repo before any archive can be signed and uploaded to App Store Connect. It does NOT include any of the App Store Connect portal work (creating the listing, uploading screenshots, filling out App Review notes, age-rating questionnaire, export compliance attestation) — the user has stated explicitly that they handle distribution. The story's deliverable is "the repo can produce a signed archive that passes App Store validation rules".

Three deliverables ship:

1. **App icon set.** Full macOS icon ladder (16, 32, 64, 128, 256, 512, 1024 @1x and @2x where applicable, plus the 1024×1024 marketing icon) committed under `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Assets.xcassets/AppIcon.appiconset/` (or the modern `.icon` bundle format if the project uses it — verified to be `.icon` per the local `AppIcon.icon` directory). Placeholder artwork is acceptable if the user has not supplied final art; the dev agent uses a stub gradient → rasterized icon set so the archive build doesn't fail validation. Final art replacement is one-line.

2. **Privacy manifest (`PrivacyInfo.xcprivacy`).** Required since May 2024 for any app uploaded to App Store Connect. The demo declares: zero tracking (`NSPrivacyTracking: false`, `NSPrivacyTrackingDomains: []`), zero collected data types (`NSPrivacyCollectedDataTypes: []`), and the file-timestamp / UserDefaults API access reasons that apply (likely `C617.1` for UserDefaults via `@SceneStorage` and possibly none others — verified during implementation).

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

1. **Stub icon artwork is acceptable and intentional pre-final-art.** The dev agent generates a minimal placeholder (e.g., a gradient with the letters "BBB" or a music-note glyph) using ImageMagick / `sips` / Acorn / whatever is available, and rasterizes it to the full ladder. The placeholder is committed as the working icon set. Final art replaces it via a one-line follow-up (`mv newicon.icon Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Assets.xcassets/AppIcon.icon` or equivalent). The reason this is fine: App Store validation requires the icon set to EXIST and be COMPLETE (all required sizes); it does not require the artwork to be polished. Polish is a follow-up the user can do without re-running this story.

2. **`PrivacyInfo.xcprivacy` is committed as an XML plist, not a JSON file.** Apple's documented format is the `.xcprivacy` extension with property-list XML payload. Xcode 26 auto-detects the file at Demo/.../BoomBoomBoomKit/PrivacyInfo.xcprivacy and includes it in the bundle. No Xcode project edits required if the file sits at the expected path (the `PBXFileSystemSynchronizedRootGroup` Story 5-1 used auto-includes new files in the target).

3. **`make demo-archive` accepts `DEVELOPMENT_TEAM` via environment but does NOT default it.** Matches the Story 5-1 W14 pattern for `make demo-build-sandboxed`. Failing fast on an unset team prevents an unsigned archive from being silently produced. The error message points the user at the documented invocation: `DEVELOPMENT_TEAM=ABC1234DEF make demo-archive`.

4. **Bundle ID stays `com.robbyt.BoomBoomBoomKitDemo`.** Per Story 5-1 DD, the bundle ID was chosen to be App-Store-acceptable from day one. No change in Story 5-7. The user can override at archive time with `xcodebuild PRODUCT_BUNDLE_IDENTIFIER=<other>` if they want a different listing identifier, but the in-repo default stays.

5. **App name stays "BoomBoomBoomKitDemo".** Renaming to something more consumer-friendly (party-mode Siri's "BeatScope" suggestion) is a marketing decision the user owns and can be done at App Store Connect listing time without changing the bundle ID. Story 5-7 records the in-repo display name (`CFBundleDisplayName`) as "BoomBoomBoomKitDemo" for consistency with prior stories. If the user wants a different display name now, the change is a one-line `Info.plist` edit during this story.

6. **Marketing version + build number scheme: semantic-major.minor.patch + monotonic build counter.** Marketing version starts at `0.1` (pre-1.0 per CLAUDE.md library framing), build number starts at `1` and increments per archive. Story 5-7 sets the initial values in `Info.plist` and documents the bump policy in `Demo/BoomBoomBoomKitDemo/README.md`. Build number bumps are manual (not date-derived) — the user controls the bump cadence.

7. **Category recommendation:** Music (primary). Reason: the consumer audience the user named is musicians / DJs / producers. Discovery surfaces (browse, search ranking) for "Music" outperform "Developer Tools" for this audience. Secondary category: Developer Tools (the library's heritage). Final call belongs to the user; the recommendation is recorded in the README.

8. **No automated archive validation step.** `xcodebuild -archive` succeeding does not guarantee App Store validation will pass. Manual `xcodebuild -exportArchive -exportOptionsPlist <opts>` + the validation pass via Xcode Organizer is the user's workflow. Story 5-7 produces the artifact; the user runs validation manually before submitting.

9. **Demo deployment-target documented as 15.6; library `Package.swift` independently at .macOS(.v15).** (Added 2026-05-23 per Story 5-6 carry-over F08, revised same day per user authorization.) Current state: demo `MACOSX_DEPLOYMENT_TARGET = 15.6` on all 6 pbxproj configs (app Debug/Release, test Debug/Release, project Debug/Release); `Package.swift` declares `.macOS(.v15)` (= 15.0). The two are intentionally DECOUPLED, not in lockstep. Rationale: the demo binary is distributed via App Store as a separate end-user product (Story 5-7's whole framing); library SPM consumers integrate `BoomBoomBoomKit` directly through Package.swift and are unaffected by the demo's deployment target. The 15.6 floor only affects end-user installs of the App Store demo binary. Codex's earlier "splitting silently breaks library consumers on 15.0-15.5" framing applies only if the demo binary IS the library's distribution channel — which it isn't; SPM is the distribution channel for the library. Re-coupling rule: if a future change bundles the library inside the demo's App Store binary as the SOLE distribution channel (instead of alongside SPM), `Package.swift` and demo pbxproj MUST move in lockstep — but that's a different distribution model than what ships today.

## Acceptance Criteria

1. **App icon set exists and is complete** at `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Assets.xcassets/AppIcon.icon/` (or `AppIcon.appiconset/`, matching whatever asset-catalog format the project currently uses — verified by the dev agent). Includes all macOS-required sizes (16×16, 32×32, 64×64, 128×128, 256×256, 512×512, 1024×1024 at @1x AND @2x where applicable, plus the 1024×1024 marketing icon). Stub artwork is acceptable.

2. **`PrivacyInfo.xcprivacy` exists** at `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/PrivacyInfo.xcprivacy`. Property-list XML payload declares: `NSPrivacyTracking: false`, `NSPrivacyTrackingDomains: []`, `NSPrivacyCollectedDataTypes: []`, and any `NSPrivacyAccessedAPITypes` entries that apply (likely `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` or `C617.1` for `@SceneStorage` — dev agent verifies).

3. **`make demo-archive` target exists** in the Makefile. Invocation: `DEVELOPMENT_TEAM=<team-id> make demo-archive`. Produces a `.xcarchive` at `build/BoomBoomBoomKitDemo.xcarchive` (or equivalent gitignored path). Errors with a clear message if `DEVELOPMENT_TEAM` is unset. Includes the same `-destination 'platform=macOS' -configuration Release` flags as the sandboxed-build pattern, plus `-archivePath` and `-allowProvisioningUpdates`.

4. **Build artifacts gitignored.** `build/` and `*.xcarchive` add to `.gitignore` if not already present.

5. **`Demo/BoomBoomBoomKitDemo/README.md` exists** as a new file documenting: chosen App Store category (primary + secondary), bundle ID, marketing version + build number scheme, archive invocation, and a checklist of deferred App Store Connect portal items (screenshots, App Review notes, age rating, export compliance). Approximately 50-80 lines.

6. **`Info.plist` updated** with `CFBundleShortVersionString = "0.1"` and `CFBundleVersion = "1"`. `CFBundleDisplayName` stays "BoomBoomBoomKitDemo" unless the user picks a different name during this story.

7. **`make demo-build` and `make demo-test` still pass.** No regressions to the unsigned / sandboxed development workflow. App-icon-set addition does not affect debug builds.

8. **`make demo-build-sandboxed DEVELOPMENT_TEAM=<id>` still passes.** No regressions to the Story 5-1 W14 sandboxed-build smoke.

9. **`make demo-archive DEVELOPMENT_TEAM=<id>` produces an `.xcarchive`** without errors. Manual step — dev agent runs once with the user's team ID (provided at story-execution time), verifies the artifact, deletes the archive, and records the invocation in the Completion Notes.

10. **Library gating gauntlet remains green.** `make build`, `make build-release`, `make test`, `make benchmark`, `make benchmark-giantsteps`, `make ablation` — outcomes unchanged from Story 5-5 / 5-6 baseline.

11. **Diff scope.** `Demo/**`, `.gitignore`, `Makefile`, and the new Demo README. `git diff --stat Sources/` empty; `git diff --stat Tests/` empty.

12. **Demo deployment-target stays at macOS 15.6; library Package.swift stays at `.macOS(.v15)`.** (Added 2026-05-23 per Story 5-6 carry-over F08, revised same day per user authorization; binds KDD #9 decoupling.) Verified state at Story 5-7 start: demo `MACOSX_DEPLOYMENT_TARGET = 15.6` on all 6 demo pbxproj configs; `Package.swift` declares `.macOS(.v15)`. Dev agent runs:

    ```bash
    grep 'MACOSX_DEPLOYMENT_TARGET' Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj | sort -u
    grep '\.macOS' Package.swift
    ```

    Demo lines must report 15.6 uniformly; Package.swift must report `.v15`. The decoupling is intentional per KDD #9. If a future story re-couples them, update KDD #9 with the new lockstep rule before changing either side.

## Tasks / Subtasks

- [ ] **Task 1 — App icon set** (AC #1).
  - [ ] 1.1 Identify the asset-catalog format in use. Local `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AppIcon.icon` directory exists per `ls` — that's the modern Xcode 16+ `.icon` bundle format. If it's empty or incomplete, populate it.
  - [ ] 1.2 Generate a stub icon at 1024×1024 (placeholder gradient + "BBB" text or music-note glyph). Tools: `sips` (built-in), ImageMagick, or any image editor.
  - [ ] 1.3 Rasterize the icon to all required macOS sizes. For the `.icon` bundle format, Xcode auto-generates ladder sizes from the 1024×1024 source — verify by opening the project once and checking the asset catalog renders correctly.
  - [ ] 1.4 Commit the icon bundle. Avoid committing the source PSD / unrasterized artwork — only the rasterized `.icon` contents that ship in the bundle.

- [ ] **Task 2 — Privacy manifest** (AC #2).
  - [ ] 2.1 Create `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/PrivacyInfo.xcprivacy` with the property-list XML payload. Template:
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
  - [ ] 2.2 Verify Xcode auto-includes the file in the bundle. Build and check `build/Release/BoomBoomBoomKitDemo.app/Contents/Resources/PrivacyInfo.xcprivacy` exists.
  - [ ] 2.3 Confirm no other API access categories apply. The demo uses: `FileManager.default` (for read-only user-selected file access — not a privacy-manifest category), `URL.fileURLWithPath` (no category), `AVFoundation` via the library (no app-level category — `BoomBoomBoomKit` handles it), `@SceneStorage` (UserDefaults under the hood — captured above). No timestamp APIs (`stat`, `creationDate`), no disk-space APIs, no system-boot-time APIs. The `CA92.1` reason for UserDefaults is "C617.1" or "CA92.1" depending on the exact API surface — `@SceneStorage` uses `UserDefaults.standard` for window-scene persistence, falling under "C617.1: app functionality" or "CA92.1: app functionality with limited specificity". Dev agent picks the most accurate reason code; Apple does not reject for over-declaration as long as the declared reason maps to an actual use.

- [ ] **Task 3 — `make demo-archive` target** (AC #3, AC #4).
  - [ ] 3.1 Add the target to `Makefile`. Pattern:
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
  - [ ] 3.2 Add `build/` and `*.xcarchive` to `.gitignore` if not present (Story 5-1 may already have added them — verify).

- [ ] **Task 4 — `Demo/BoomBoomBoomKitDemo/README.md`** (AC #5).
  - [ ] 4.1 Create the file. Sections: Overview (one paragraph linking to the parent README), Bundle Identity (bundle ID + team), App Store Category (primary + secondary + rationale), Versioning (marketing + build number policy), Archive Workflow (`DEVELOPMENT_TEAM=... make demo-archive` + manual `xcodebuild -exportArchive` step), App Store Connect Portal Checklist (deferred items: screenshots, App Review notes, age rating, export compliance — each with the answer or expected workflow).
  - [ ] 4.2 Cross-link from the top-level `README.md`'s Demo App paragraph (added in Story 5-5) — one inline link to `Demo/BoomBoomBoomKitDemo/README.md`.

- [ ] **Task 5 — `Info.plist` versioning** (AC #6).
  - [ ] 5.1 Verify current `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Info.plist` values for `CFBundleShortVersionString` and `CFBundleVersion`.
  - [ ] 5.2 Set `CFBundleShortVersionString = "0.1"` and `CFBundleVersion = "1"` if not already present.
  - [ ] 5.3 Leave `CFBundleDisplayName` as "BoomBoomBoomKitDemo" unless the user picks a different name during story execution.

- [ ] **Task 6 — Gating gauntlet** (AC #7 through #11).
  - [ ] 6.1 `make demo-fmt` clean.
  - [ ] 6.2 `make demo-lint` exit 0.
  - [ ] 6.3 `make demo-build` BUILD SUCCEEDED.
  - [ ] 6.4 `make demo-test` 79 invocations passing.
  - [ ] 6.5 `DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM) make demo-build-sandboxed` BUILD SUCCEEDED.
  - [ ] 6.6 `DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM) make demo-archive` produces a `.xcarchive`. Verify with `ls -la build/BoomBoomBoomKitDemo.xcarchive`. Delete the archive after verification (gitignored).
  - [ ] 6.7 `make build`, `make build-release`, `make test`, `make benchmark`, `make benchmark-giantsteps`, `make ablation` — outcomes unchanged.
  - [ ] 6.8 Diff-scope verification: `git diff --stat Sources/` empty; `git diff --stat Tests/` empty.

- [ ] **Task 7 — Story-spec close-out + sprint-status flip**.
  - [ ] 7.1 Populate Dev Agent Record.
  - [ ] 7.2 Update sprint-status.yaml: `5-7-app-store-submission-readiness: review`.
  - [ ] 7.3 Commit. Suggested message: `Story 5-7: App Store submission readiness — icon, privacy manifest, archive target`.

## Apple Platform Notes

- **Privacy manifest** is required for App Store submission since May 1, 2024 (Apple announcement: https://developer.apple.com/news/?id=3d8a9yyh). The required API access reasons are documented at https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api. `NSPrivacyAccessedAPICategoryUserDefaults` reason codes are `CA92.1`, `C617.1`, or `1C8F.1` depending on the use case — for app-functionality persistence (which is what `@SceneStorage` does), `CA92.1` is the typical match.

- **Asset catalog `.icon` bundle format** is the modern Xcode 16+ format. It supersedes the legacy `AppIcon.appiconset` directory of individually-sized PNGs. Xcode auto-generates the ladder from a single 1024×1024 source. Reference: https://developer.apple.com/design/human-interface-guidelines/app-icons.

- **`xcodebuild archive`** + `-allowProvisioningUpdates` automatically downloads / refreshes the App Store distribution provisioning profile from Apple's servers if a valid Apple Developer account is configured. The user's first `make demo-archive` invocation may prompt for sign-in via Xcode if the profile cache is cold.

- **App Store category metadata** is set at App Store Connect listing creation, not in the app bundle. The in-repo record (Demo README) is for human-readable traceability — Apple validates category selection at the portal, not via plist or manifest.

- **Marketing version semantics** (`CFBundleShortVersionString`) is what App Store displays to users (e.g., "0.1"). Build number (`CFBundleVersion`) is what App Store Connect uses to disambiguate uploads (must be monotonically increasing per `CFBundleShortVersionString`). Apple ref: https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundleshortversionstring.

## Risks

- **R1 — Stub icon artwork may look unprofessional pre-final-art.** Mitigation: a placeholder gradient is acceptable for App Store validation. Final artwork replacement is a one-step `.icon` bundle swap and does not require re-running Story 5-7.

- **R2 — Privacy manifest reason code mismatch.** If the dev agent picks `CA92.1` but the actual `@SceneStorage` use case better matches `C617.1`, App Store Review may flag the manifest. Apple's documented over-declaration tolerance: declaring an extra reason code does NOT cause rejection (Apple's stated position). Mitigation: declare both `CA92.1` AND `C617.1` if uncertain. Apple ref: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api/describing_use_of_user_defaults_apis.

- **R3 — `make demo-archive` requires a valid signing identity, which CI/fresh-clone environments do not have.** This target is develop-only and operator-driven. It does NOT run as part of `make pre-commit` or any aggregate gate. The `DEVELOPMENT_TEAM`-unset error is fail-fast for fresh-clone safety.

- **R4 — App Store Connect listing requires fields not produced by this story** (screenshots at 2880×1800, App Review notes, age-rating questionnaire answers, export compliance attestation). These are portal-side blockers the user handles. The Demo README's checklist surfaces them for the user's reference but does not gate the in-repo work.

- **R5 — The `AppIcon.icon` directory may currently be a placeholder that fails Xcode build validation.** Local `ls` shows the directory exists; the dev agent verifies it contains the required `Contents.json` + source PNG(s) and produces a valid build artifact in `build/Release/BoomBoomBoomKitDemo.app/Contents/Resources/AppIcon.icns`.

- **R6 — Bundle ID conflict on first archive upload.** If the user has not registered `com.robbyt.BoomBoomBoomKitDemo` in App Store Connect, the first archive upload via Xcode Organizer prompts for registration. This is a one-time portal-side step the user owns — no in-repo blocker.

## References

### Previous Story Intelligence (PSI)

1. **Story 5-1 (Demo app project scaffold, 2026-05-18)** — established the demo project structure, bundle ID `com.robbyt.BoomBoomBoomKitDemo`, App Sandbox + Hardened Runtime entitlements, and the `make demo-build-sandboxed DEVELOPMENT_TEAM=...` pattern (W14 close-out). Story 5-7 mirrors W14's env-var-error-on-unset pattern for `make demo-archive`. The `PBXFileSystemSynchronizedRootGroup` project structure means new files at `Demo/.../BoomBoomBoomKit/` (e.g., `PrivacyInfo.xcprivacy`) are auto-included in the target without Xcode project edits.

2. **Story 5-6 (End-user UI redesign, 2026-05-22 — running in parallel)** — Story 5-7 is independent of 5-6 (UI redesign vs. submission readiness). The two stories can land in either order, though Story 5-6 should ideally land FIRST so the App Store screenshots showcase the redesigned UI rather than the developer-eval layout. If 5-7 lands first, the icon and manifest are in place for the eventual archive but the screenshots remain a manual step on top of the post-5-6 visual state. The user's stated intent suggests 5-6 then 5-7 — Story 5-7 PSI documents the dependency direction.

3. **Story 5-5 (Public API documentation and README, 2026-05-21)** — the top-level `README.md` Demo App paragraph (added per Story 5-5 follow-through) is the cross-link target for Story 5-7's Demo README. The Demo README at `Demo/BoomBoomBoomKitDemo/README.md` is new; the top-level README's Demo paragraph picks up an inline link to it during Story 5-7.

4. **Party-mode discussion (2026-05-22)** — Siri laid out the "NOW" submission-gating list verbatim. Story 5-7 implements those items: app icon, privacy manifest, signing identity, App Store category. Items Siri flagged as "later" (screenshots, age rating, export compliance, App Review notes) are explicitly out-of-scope.

## Diff-scope Expectations

**Files touched (post-Task-7):**

- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Assets.xcassets/AppIcon.icon/` (or `.appiconset/`) — populated with icon assets. File count varies by format.
- **NEW:** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/PrivacyInfo.xcprivacy` — ~20 lines XML.
- **NEW:** `Demo/BoomBoomBoomKitDemo/README.md` — ~50-80 lines.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Info.plist` — version + build number entries.
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

### Implementation Plan

(filled by dev agent)

### Completion Notes

(filled by dev agent)

### Debug Log

(filled by dev agent)

### File List

(filled by dev agent)

### Change Log

(filled by dev agent)

## Carry-over from Story 5-6 (2026-05-23)

Per `_bmad-output/planning-artifacts/sprint-change-proposal-2026-05-23.md` (v3). Story 5-6's pre-staged pbxproj changes were reverted as scope creep; Story 5-7 owns the canonical implementation of each item below.

- **F01 (bundle ID + display name rename)** — Story 5-6 staged `PRODUCT_BUNDLE_IDENTIFIER = com.robbyt.BoomBoomBoom` + `INFOPLIST_KEY_CFBundleDisplayName = BoomBoomBoom`. REVERTED in Story 5-6's surgical revert (Phase 2). Story 5-7's existing **KDD #4** and **KDD #5** explicitly forbid this rename ("Bundle ID stays `com.robbyt.BoomBoomBoomKitDemo`", "App name stays `BoomBoomBoomKitDemo`"). Story 5-7 must NOT reintroduce. Ledger: `_bmad-output/implementation-artifacts/deferred-work.md` **W33**.
- **F05 (AppIcon.icon bundle landing)** — Story 5-6 staged a 2 MB `clock-man.png` placeholder + `icon.json` under `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AppIcon.icon/` with the pbxproj catalog rename. REVERTED. Story 5-7 **AC #1** owns the icon set; **KDD #1** authorizes stub artwork. Story 5-7 dev agent may reuse the reverted `clock-man.png` artifact OR generate fresh stub artwork. Ledger: **W35**.
- **F08 (deployment-target alignment)** — Story 5-6 staged `MACOSX_DEPLOYMENT_TARGET = 15.6` on all six pbxproj configs. User authorized 2026-05-23: keep at 15.6 (overrides Codex's revert-to-15.0 recommendation). Demo binary distributed separately from library SPM; Package.swift stays at `.macOS(.v15)`. Demo's 15.6 floor only affects end-user installs of the App Store demo binary, not library SPM consumers. See **KDD #9** (demo/library platform decoupling, revised) + **AC #12** (verify demo=15.6 / Package.swift=.v15, revised). Ledger: **W37** updated to accept-as-known-issue with user authorization.
