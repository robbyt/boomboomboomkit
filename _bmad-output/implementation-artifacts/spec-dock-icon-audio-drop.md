---
title: 'Dock-icon audio drop ingress'
type: 'bugfix'
created: '2026-05-25'
status: 'done'
context: ['{project-root}/CLAUDE.md']
baseline_commit: '13e9628'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Dragging an audio file onto the BoomBoomBoom dock icon does nothing — the icon does not accept the drop. The runtime routing for LaunchServices document-open events already exists (`ContentView.onOpenURL` → `AnalysisViewModel.handleOpenURL` → `analyze(url:autoStarted:true)`), but the app declares no `CFBundleDocumentTypes` in `Info.plist`, so LaunchServices never tells the dock that this app handles audio. As a result, the explicit code path for dock drops in `AnalysisViewModel.swift:393-410` is dead.

**Approach:** Add a `CFBundleDocumentTypes` array to `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/Info.plist` that declares Viewer/Alternate-rank support for exactly the six file UTIs corresponding to `AnalysisViewModel.supportedExtensions` (`wav, aiff, mp3, flac, m4a, caf`). No Swift code changes — the existing `.onOpenURL` plumbing handles everything once LaunchServices accepts the drop.

## Boundaries & Constraints

**Always:**
- Declare UTIs one-by-one (six entries) — never via parent `public.audio`. The existing comment at `AnalysisViewModel.swift:13-17` documents why broadening with `UTType.conforms(to:)` silently widens the supported set beyond what `PCMBufferReader` decodes; the same anti-pattern applies to UTI declarations.
- `LSHandlerRank = Alternate` (not `Owner`) — users have primary audio apps; we accept drops but do not claim default-handler status for any of these formats.
- `CFBundleTypeRole = Viewer` (not `Editor`) — the app reads-only.
- All UTIs declared must be system-declared on macOS 15+ (no `UTImportedTypeDeclarations` block).
- Info.plist edits only; no pbxproj edits (the existing config already has `GENERATE_INFOPLIST_FILE = NO; INFOPLIST_FILE = BoomBoomBoomBPM/Info.plist` for both Debug and Release of the app target).
- No marketing-version or build-number changes (those were just bumped in commit `13e9628 Demo: pin to v0.0.1 build 4`).

**Ask First:**
- If macOS LaunchServices cache (`lsregister`) refuses to recognize the new UTIs after `make demo-build` and a clean install, before assuming the plist is wrong, check whether the build is being installed at a path other than `~/Library/Developer/Xcode/DerivedData/.../BoomBoomBoom.app` — a stale LSRegister entry pointing at an older `.app` bundle can mask the new declarations.

**Never:**
- Do NOT change `BoomBoomBoomBPMApp.swift` to add `NSApplicationDelegateAdaptor` — SwiftUI's `.onOpenURL` already handles the AppKit dock-drop event for `WindowGroup` apps; adding an explicit AppDelegate would create two competing handlers.
- Do NOT change `AnalysisViewModel.handleOpenURL` — it already exists, validates payload via the shared `validateDropPayload`, and routes to `analyze(url:autoStarted:true)`.
- Do NOT register `public.audio` as a fallback. It would silently accept `.m4b` audiobooks, `.mp4` containers, and other formats `PCMBufferReader` cannot decode, breaking the existing extension allow-list contract.
- Do NOT add `CFBundleURLTypes` (URL scheme handling) — out of scope; this is a file-drop fix only.
- Do NOT introduce sandbox entitlement changes — the existing `com.apple.security.files.user-selected.read-write` entitlement is sufficient. LaunchServices-delivered file URLs receive a kernel-vended sandbox extension; per `AnalysisViewModel.swift:159-170` (Story 5-7 C1 carry-over), the `start/stopAccessingSecurityScopedResource` plumbing handles this defensively.
- Do NOT extend the dock-drop accept-set to `.aif` or `.aifc` — `AnalysisViewModel.supportedExtensions` lists only `"aiff"` today, and widening the dock declaration without updating the allow-list would create a mismatch where LaunchServices accepts the drop and `validateDropPayload` rejects it. If `.aif` / `.aifc` support is wanted, it's a separate fix touching `supportedExtensions` first.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Drop one supported file on dock (cold launch) | App not running; user drags `track.mp3` to dock | App launches, window appears, analysis starts automatically with `autoStarted: true` | N/A |
| Drop one supported file on dock (warm) | App running and idle; user drags `track.flac` to dock | `.onOpenURL` fires → `handleOpenURL` validates → `analyze(url:autoStarted:true)` starts | N/A |
| Drop one supported file on dock during in-flight analysis | App running and analyzing; user drops `track2.wav` | New `analyze()` call cancels the prior in-flight task (existing behavior at `AnalysisViewModel.swift:177-180`); new analysis proceeds | N/A |
| Drop multiple files on dock | User selects 3 files and drags to dock | Spec deliberately does NOT guarantee multi-file dock-drop semantics. Observed behavior on macOS 15: each URL fires `.onOpenURL` separately; in-flight cancellation means the last-arriving URL's analysis survives. Window-drop's atomic `.multipleFiles` rejection is NOT replicated here. | Documented as intentional divergence; if multi-file parity is later required, the right fix is `NSApplicationDelegateAdaptor` + `application(_:open:)` for atomic batch handling — out of scope for this spec |
| Drop unsupported type on dock | User drags `book.m4b` to dock | macOS dock should refuse the drop (we don't declare `com.apple.m4a-audio-book` UTI); if a permissive parent UTI somehow delivers it, `validateDropPayload` rejects with `.dropUnsupportedType` banner | Existing banner via `error = .dropUnsupportedType(extension: "m4b")` |
| Drop while another supported file is selected via window | App running with prior result; user drops new file on dock | Prior result clears via existing `clearPriorResult()` path; new analysis starts | N/A |

</frozen-after-approval>

## Code Map

- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/Info.plist` — target of the change; add `CFBundleDocumentTypes` array with six UTI entries
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift:18-20` — authoritative list of supported extensions; the UTI declarations MUST mirror this set exactly
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift:393-410` — `handleOpenURL` already wired; no edit needed but verify it remains the LaunchServices entry point
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift:88-93` — `.onOpenURL` modifier already wired; no edit needed
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BoomBoomBoomBPM.entitlements` — verify only; no edit needed

## Tasks & Acceptance

**Execution:**
- [x] `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/Info.plist` — Insert a `CFBundleDocumentTypes` array with six dict entries, one per supported UTI. Each entry has `CFBundleTypeName` (human-readable, e.g. `"MP3 Audio"`), `CFBundleTypeRole = Viewer`, `LSHandlerRank = Alternate`, `LSItemContentTypes` (single-element array with the specific UTI string). UTIs: `public.mp3` (mp3), `com.microsoft.waveform-audio` (wav), `public.aiff-audio` (aiff), `org.xiph.flac` (flac), `com.apple.m4a-audio` (m4a), `com.apple.coreaudio-format` (caf).

**Acceptance Criteria:**
- Given the app is installed and registered with LaunchServices, when the user drags a supported audio file onto the dock icon, then the dock icon highlights as a valid drop target.
- Given the app is not running, when the user drops a supported audio file on the dock, then the app launches and analysis begins automatically (verified by status banner reaching `analyzing` then `result`).
- Given the app is running and idle, when the user drops a supported audio file on the dock, then analysis begins without manual interaction (no need to click into the window).
- Given the app is running and currently analyzing a file, when the user drops a different supported file on the dock, then the prior analysis is cancelled and the new one starts (matches the existing window-drop behavior at `AnalysisViewModel.swift:177-180`).
- Given the user attempts to drop an unsupported file type (e.g. `.m4b`, `.ogg`) on the dock, then the dock visually rejects the drop (macOS does not highlight) — no error banner should appear because the file never reaches the app.
- Given the app has been built and opened once (so LaunchServices indexes the bundle), then the **built** `BoomBoomBoom.app/Contents/Info.plist` (NOT the source `Info.plist`) contains a `CFBundleDocumentTypes` array with exactly six dict entries whose `LSItemContentTypes` cover all six target UTIs. The source plist edit is necessary but not sufficient — the built artifact is what LaunchServices reads.

## Design Notes

**UTI choice for `.m4a`: `com.apple.m4a-audio`, NOT `public.mpeg-4-audio`.** `public.mpeg-4-audio` (Apple's `UTType.mpeg4Audio` named property) is broader — `.m4b` (audiobook), `.mp4` audio-only, and protected-content variants all conform to it. Declaring it in `LSItemContentTypes` would over-widen the dock-drop accept-set beyond what `PCMBufferReader` decodes, recreating exactly the anti-pattern that `AnalysisViewModel.swift:13-17` warns against for `UTType.conforms(to:)`. `com.apple.m4a-audio` is the narrower Apple-private UTI that macOS assigns specifically to `.m4a` music files — verified on the macOS 15 install via `lsregister -dump | grep m4a`.

**UTI catalog gap for FLAC and CAF.** Apple's `UniformTypeIdentifiers` named-property catalog (`UTType.mp3`, `UTType.aiff`, `UTType.wav`, `UTType.mpeg4Audio`, etc.) does NOT expose named properties for FLAC or CAF, even though both are first-class macOS-recognized formats. The named catalog is a curated subset of LaunchServices' registered UTIs — verified via `lsregister -dump | grep -iE "(flac|coreaudio-format)"` which returns both `org.xiph.flac` (FLAC) and `com.apple.coreaudio-format` (CAF) as system-registered. So the LSItemContentTypes strings work even though there's no Swift-side `UTType.flac` constant.

**Why `.onOpenURL` is sufficient — no `NSApplicationDelegateAdaptor` needed.** Per Apple's `View.onOpenURL(perform:)` documentation (macOS 11.0+), the modifier "Registers a handler to invoke in response to a URL that your app receives" — including LaunchServices document-open events on macOS. The existing wiring at `ContentView.swift:91-93` is the canonical SwiftUI pattern for a non-document-based app accepting dock-drop file URLs. Adding an AppDelegate adapter would create two competing handlers and risk routing bugs. The current absence of dock-drop is purely a missing `CFBundleDocumentTypes` declaration — LaunchServices has no way to know we accept audio without it.

**Multi-file dock drops — deliberately not guaranteed.** The spec does NOT promise specific multi-file dock-drop semantics. Observed behavior on macOS 15: `.onOpenURL` fires once per URL, and `AnalysisViewModel.analyze()`'s in-flight cancellation at lines 177-180 means the last-arriving URL's analysis is the one that survives. This DIVERGES from window-drop's atomic `.multipleFiles` rejection — and that's accepted, not matched. If multi-file parity later becomes a product requirement, the right fix is to introduce `NSApplicationDelegateAdaptor` with `application(_:open:)` for atomic batch handling; trying to race-detect URL batches inside `.onOpenURL` would be brittle. Out of scope here.

**Extension-vs-UTI mismatch is intentional.** LaunchServices uses UTIs to decide whether the dock accepts a drop; `AnalysisViewModel.validateDropPayload` uses filename extension to validate at the app boundary. These can diverge — e.g., an extensionless file with audio content might pass the dock but fail extension validation; a file renamed `track.mp3.m4a` would pass both gates but `PCMBufferReader` may fail to decode. The app's existing failure surface (`error = .fileReadFailed`) handles the latter cleanly. Documented behavior, not a defect.

## Verification

**Commands:**
- `make demo-fmt` — expected: clean (no Info.plist files are touched by swift-format, but run for hygiene)
- `make demo-lint` — expected: exit 0
- `make demo-build` — expected: BUILD SUCCEEDED; produces `.app` bundle under DerivedData
- `plutil -p Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/Info.plist | grep -A 60 CFBundleDocumentTypes` — expected: six dict entries with the six UTIs
- After `make demo-build`, locate the built `.app` bundle and run `plutil -p <path>/BoomBoomBoom.app/Contents/Info.plist | grep -A 60 CFBundleDocumentTypes` — expected: identical six dict entries (proves Xcode propagated the plist edit to the bundle, not just the source)
- After opening the built `.app` once: `/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump | grep -A 80 -B 10 com.robbyt.BoomBoomBoomBPM` — expected: bundle entry shows the six UTI claims under its bindings. This catches plist-not-packaged or stale-registration failures that the static plutil check would miss.
- For each of the six extensions, on a real sample file: `mdls -name kMDItemContentType -name kMDItemContentTypeTree sample.<ext>` — expected: the content-type tree includes the corresponding declared UTI (e.g., `sample.m4a` resolves to or conforms to `com.apple.m4a-audio`).
- Boundary check: `mdls -name kMDItemContentType -name kMDItemContentTypeTree sample.m4b` — expected: content type is `com.apple.m4a-audio-book` or similar audiobook UTI, NOT `com.apple.m4a-audio`. Proves the `.m4a` vs `.m4b` declaration boundary holds.

**Manual checks (CLI cannot exercise dock-drop directly):**
- After `make demo-build`, open the built `.app` via Finder once (double-click in DerivedData/.../Products/Debug) so LaunchServices indexes the bundle.
- Cheaper proxy first: `open -a BoomBoomBoom path/to/sample.mp3` for each of the six extensions. Expected: app launches/raises, analysis starts. This exercises the same `.onOpenURL` plumbing as dock-drop without the drag UI; faster to iterate on.
- Finder "Open With" → BoomBoomBoom for one file of each of the six extensions. Expected: same behavior. Confirms LaunchServices presents us in the Open With menu (Alternate rank).
- Dock-drop check (the actual ACs): quit the app, then drag a `.mp3` from Finder onto the dock icon. Expected: dock highlights, app launches, analysis starts. Repeat for `.wav`, `.flac`, `.m4a`, `.caf`, `.aiff` (use OA300 corpus tracks).
- Negative dock check: drag a `.m4b` and a `.ogg` to the dock. Expected: dock does NOT highlight; drop is silently rejected.
- Edge: drop an iCloud-evicted (not-yet-downloaded) audio file on the dock. Expected: clean failure path — either `.fileReadFailed` banner or system-level download prompt; no crash.
- Edge: drop a Finder alias and a symlink pointing to a supported audio file. Expected: behavior depends on whether the URL delivered is the alias/symlink itself or its resolved target; document what actually happens, treat as observation rather than pass/fail.
- If dock declines to highlight despite all the static checks above passing, suspect stale LSRegister cache: `lsregister -kill -r -domain local -domain system -domain user` and re-test.

## Suggested Review Order

- Entry point — declares the app as an Alternate Viewer for six audio UTIs; everything else is six near-identical repetitions of this dict shape.
  [`Info.plist:7`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/Info.plist#L7)

- The narrow `com.apple.m4a-audio` choice — *not* `public.mpeg-4-audio` — keeps `.m4b` audiobooks out of the dock-accept set per the existing `AnalysisViewModel.swift:13-17` warning.
  [`Info.plist:64`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/Info.plist#L64)

- FLAC and CAF UTIs are system-registered on macOS 15 even though they have no named-property in `UTType` — verified empirically.
  [`Info.plist:52`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/Info.plist#L52)

- The pre-existing `.onOpenURL` wiring this manifest unlocks — already validates, dispatches, and analyzes; no Swift changes required here.
  [`ContentView.swift:91`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift#L91)
