# BoomBoomBoomKitDemo

End-user macOS demo app for [BoomBoomBoomKit](../../README.md). Drop an audio file, see the detected BPM, optionally inspect the diagnostic trace pipeline. Distributed as a free download via the Mac App Store.

## Bundle identity

| Field | Value |
|-------|-------|
| Bundle ID | `com.robbyt.BoomBoomBoomKitDemo` |
| Display name | `BoomBoomBoomKitDemo` |
| Development team | configured per-operator via `DEVELOPMENT_TEAM=<id>` env var (see Archive workflow) |
| Minimum macOS | 15.6 (App Store demo binary only — library distributes independently via SPM at `.macOS(.v15)`; see [Story 5-7 KDD #9](../../_bmad-output/implementation-artifacts/5-7-app-store-submission-readiness.md) for the platform-decoupling rationale) |

## App Store category

- **Primary:** Music
- **Secondary:** Developer Tools

**Rationale:** the consumer audience this demo serves is musicians, DJs, and producers — Music's discovery surfaces (browse, search ranking) outperform Developer Tools for that audience. Developer Tools is preserved as secondary to reflect the library's heritage and to surface the demo for the audience that found the SPM library first. Category selection is set at App Store Connect listing creation, not in the bundle; this README records the decision for in-repo traceability.

## Versioning

- **`CFBundleShortVersionString` (marketing version):** semantic `MAJOR.MINOR.PATCH`, starts at `0.1` (pre-1.0 per library framing in `CLAUDE.md`). Visible to users in the App Store listing.
- **`CFBundleVersion` (build number):** monotonically increasing integer per upload to App Store Connect. Starts at `1`. Manual bump (no date-derived scheme); operator increments per archive.

Both values are set via `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` build settings in `BoomBoomBoomKitDemo.xcodeproj`; `Info.plist` references them via `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)` placeholders.

To bump:

```bash
# Edit Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj
#   MARKETING_VERSION = 0.2;          (raise for user-visible release)
#   CURRENT_PROJECT_VERSION = 2;      (raise for every archive upload)
```

## Archive workflow

`make demo-archive` produces a signed `.xcarchive` at `build/BoomBoomBoomKitDemo.xcarchive`. `DEVELOPMENT_TEAM` env var is required (fails fast if unset, matching the `make demo-build-sandboxed` pattern from Story 5-1 W14).

```bash
DEVELOPMENT_TEAM=ABC1234DEF make demo-archive
```

The archive is NOT auto-uploaded. To submit:

1. Open the archive in Xcode Organizer: `open build/BoomBoomBoomKitDemo.xcarchive`
2. Use **Distribute App** → **App Store Connect** → **Upload**, OR
3. Export with `xcodebuild -exportArchive -archivePath build/BoomBoomBoomKitDemo.xcarchive -exportPath build/export -exportOptionsPlist ExportOptions.plist`, then upload the resulting `.pkg` / `.app` via Transporter.

Apple's `-allowProvisioningUpdates` flag (on by default in `make demo-archive`) auto-downloads/refreshes the App Store distribution provisioning profile from Apple's servers if your Apple Developer account is configured. The first archive on a fresh machine may prompt for Xcode sign-in.

## App Store Connect portal checklist

These are portal-side items the operator handles via App Store Connect — none of them are in-repo artifacts. Story 5-7 ships the in-repo prerequisites; this checklist surfaces the portal work that follows.

| Item | Status | Notes |
|------|--------|-------|
| App record created in App Store Connect | operator | Use bundle ID `com.robbyt.BoomBoomBoomKitDemo` |
| Screenshots (3 × 2880×1800 minimum) | operator | Run the app at 2880×1800 window size; capture via macOS Screenshot (`Cmd-Shift-4` / `Cmd-Shift-5`). Suggested subjects: empty-state drop zone, mid-analysis ProgressView, post-result hero + Diagnostics inspector |
| App description (≤4000 chars) | operator | Highlight: zero-config BPM detection, supports WAV/AIFF/MP3/FLAC/M4A, sandbox-respecting, no tracking |
| Subtitle (≤170 chars) | operator | Suggested: "Detect BPM from any audio file. Free, private, fast." |
| Keywords (≤100 chars CSV) | operator | Suggested: `bpm,tempo,music,dj,analysis,audio,beat,producer,detection` |
| Support URL | operator | Maintained externally |
| Privacy policy URL | operator | Recommended even though the app collects nothing — App Store Connect requests it; a one-paragraph "this app collects no data" page suffices |
| Age rating questionnaire | operator | This demo: 4+ rating (no objectionable content, no UGC) |
| Export compliance | operator | One-click "no cryptography" answer (demo uses no crypto) |
| App Review notes | operator | Free-text — recommend explaining: "Drag-and-drop audio file → BPM calculation runs entirely on-device via library; no network access; no tracking; no IAP" |

## Privacy manifest

`PrivacyInfo.xcprivacy` declares:

- `NSPrivacyTracking = false`
- Empty `NSPrivacyTrackingDomains`
- Empty `NSPrivacyCollectedDataTypes` (this app collects nothing)
- `NSPrivacyAccessedAPICategoryUserDefaults` reason `CA92.1` (for `@SceneStorage`-backed inspector preference)

Required by Apple since May 2024 for any App Store submission. Auto-included in the bundle by Xcode 26+'s `PBXFileSystemSynchronizedRootGroup` (no project edits needed).

## Build configurations

| Make target | Purpose |
|-------------|---------|
| `make demo-build` | Debug, unsigned, no entitlements. Fast iteration. |
| `make demo-build-sandboxed DEVELOPMENT_TEAM=<id>` | Debug, signed, entitlements active. Repro sandbox-related bugs. |
| `make demo-test` | Unit tests for `AnalysisViewModel` (~78 invocations). |
| `make demo-archive DEVELOPMENT_TEAM=<id>` | **Release**, signed, distribution provisioning. Produces `.xcarchive` for App Store upload. |
| `make demo-fmt` / `make demo-lint` | Format + lint Demo/-only sources. |

## Out of scope (handled elsewhere)

- **Library distribution** — `BoomBoomBoomKit` ships independently via Swift Package Manager. The demo's macOS 15.6 minimum does NOT bind library consumers; `Package.swift` remains at `.macOS(.v15)`.
- **End-user UI redesign** — Story 5-6 owns the hero typography, strategy-keyed background, collapsible Diagnostics inspector.
- **Diagnostic trace inspector** — Story 5-4 owns the trace export JSON pipeline.
- **In-app purchases / subscriptions** — not in scope; the app is free.
- **Analytics / crash reporting / telemetry** — not in scope; the privacy manifest reflects zero collection.
