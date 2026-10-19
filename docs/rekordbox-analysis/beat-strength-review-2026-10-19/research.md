# Research and validation ledger

Investigation date: 2026-10-17. This package reads desktop library files independently. No proprietary code or SDK is loaded by the package, and no installed application was modified.

## Shipped artifacts and Hopper observations

| Artifact | Version | SHA-256 |
| --- | --- | --- |
| Bitwig `Contents/MacOS/BitwigStudio` | 6.1.4 | `36d861800da66d3c58865e0bf22de84d7f18420ce30888b8a2aa4fd8886aaac8` |
| Bitwig `Contents/Frameworks/libbitwig-jni.jnilib` | 6.1.4 | `bee0575d451f8a445e8140a5b3e31e44dc96a63d274bd88dfec4b2153549d0a6` |
| rekordbox `Contents/MacOS/libsqlcipher.0.dylib` | App 7.2.19.0342; embedded string 4.6.0 | `c17c3b934e81aa91481a738e340d0e84d564dafb71821c3297f0a01ec2306607` |

REA used the Hopper provider and the arm64 slice of each universal Mach-O. The original container hash is retained. Addresses below belong to the provider's thin-slice analysis; they are not file offsets. Evidence IDs refer to the investigation session, not committed source artifacts.

| Observation | Address / Evidence |
| --- | --- |
| Native launcher has no matching typed `rekordbox` strings within Hopper's searched inventory; the relevant code is in JNI | `ev_51651fe92605422f7b4322386e98cb01b92b2650658bc13437b2bc0d3527cc37` |
| JNI contains `RekordboxDbReader`, SQL helpers, and ANLZ methods | `ev_62d67e2e17dd54edfb0e9c1e902428b3cace0e9c2d8a388f0a9aea2535427ed2` |
| Reader opens with SQLite flag 1 (`READONLY`), applies a SQLCipher key, and sets a 1000 ms busy timeout | `0x353a4c`, `ev_d80c9b2f7beb642ead9e984d050301592db599961b2d7b8ce92a812d9b1ce95a` |
| Collection query joins track metadata, excludes local-deleted records, and filters its own supported FileType range | `0x2a5f10`, `ev_9c54d2bf823479b2b8b30cfff9cbb6af9130d6c9058c165a039f5573b4194afd` |
| Beat reader walks ANLZ chunks and recognizes `PQTZ` with endian conversion | `0x354070`, `ev_5849d8251b67b3aa61466241567c9b14a535dc682ff08f354ce52322d93eaa0a` |
| Whole-wave reader recognizes `PWV4` and reads six-byte entries | `0x354b58`, `ev_2bb9d9d8614ffc8e9dba8dee1a403b415a2d98f28a5ac31eaa3736bdcc7127a0` |
| Default analysis root appends `/share` to the database root | `0x353478`, `ev_9be6e9da350da4dbead522a46aafb575f8c2571f6b6aa87ba61620aef134ba30` |
| Installed SQLCipher library has a typed `4.6.0` string | `ev_4bc4bad6ce0c8c3aef0175c6edf2e70801844fded01686f1cb364701fdadd445` |

These are static observations, not proof of execution or exhaustive recovery. Hopper pseudocode contains inferred register types and artifacts; it was not copied as implementation source. Typed strings can be absent or split. Open REA sessions were closed after inspection. Bitwig's native reader also has logging helpers, reinforcing the choice to implement an independent parser rather than invoke its SDK.

Bitwig's own [integration announcement](https://www.bitwig.com/stories/bitwig-studio-is-now-integrated-with-alphathetas-rekordbox-474/) establishes the intended browsing capability; it does not specify the file format or promise an external SDK API.

## Independent format references

GitHub content was accessed using `gh api`; third-party installation/patch scripts were not executed.

- [Pyrekordbox models](https://github.com/dylanljones/pyrekordbox/blob/master/pyrekordbox/masterdb/models.py): table fields, lookup relationships, milliseconds, sample-rate units, metadata references.
- [Pyrekordbox configuration](https://github.com/dylanljones/pyrekordbox/blob/master/pyrekordbox/config.py): known settings paths, `masterDbDirectory`, moved database discovery. The installed rekordboxAgent `options.json` (2026-10-17) stores `"options": [["db-path", …], ["analysis-data-root-path", …], …]`; it has no `masterDbDirectory` key. Discovery reads those two keys as one record.
- [Pyrekordbox database access](https://github.com/dylanljones/pyrekordbox/blob/master/pyrekordbox/masterdb/database.py): published desktop passphrase and SQLCipher use. Its write APIs and logging behavior were not adopted.
- [Intelligent-playlist rules](https://github.com/dylanljones/pyrekordbox/blob/master/pyrekordbox/masterdb/smartlist.py): supported property/operator mapping. Evaluation uses a bounded typed subset, never XML-provided SQL.
- [ANLZ binary structures](https://github.com/dylanljones/pyrekordbox/blob/master/pyrekordbox/anlz/structs.py) and [Deep Symmetry's analysis](https://djl-analysis.deepsymmetry.org/rekordbox-export-analysis/anlz.html): chunk layouts, cues, waveforms, and phrase structure.
- [Beat-link waveform interpretation](https://github.com/Deep-Symmetry/beat-link/blob/main/src/main/java/org/deepsymmetry/beatlink/data/WaveformPreview.java): PWV4's six unsigned-byte channels. These values are not five-bit monochrome heights or a direct RGB rendering.
- [Rekordbox-tools cue conventions](https://github.com/Sluk3/rekordbox-tools/blob/master/rbtools/db.py) and [CueGen frame conversion](https://github.com/mganss/CueGen/blob/master/CueGen/Generator.cs): reserved Kind 4 memory loops, hot-slot mapping, and 150 frames/second fallback. These correct oversimplified memory/hot classifications in some older references.
- [Linux Bitwig integration research](https://github.com/willl03/bitwig-rekordbox-linux): corroborating independent SQLCipher/ANLZ approach. No shim was installed or copied into this package.

SQLCipher source is pinned to tag `v4.19.0`, commit `c4b275a47932888216bade83aff2bbc73df0ff85`. [Upstream compatibility documentation](https://github.com/sqlcipher/sqlcipher/blob/v4.19.0/README.md) describes same-major format compatibility. Actual installed-library reads verified the selected passphrase and default SQLCipher 4 profile. No compatibility migration is attempted.

## Runtime results

Validated with Swift 6.4 on arm64 macOS. The deployment target is macOS 15 since the Hilbert-readiness pass (for `Synchronization.Mutex`); earlier results used macOS 14. Intel compilation produced an x86_64 Mach-O executable; Intel runtime execution was not performed.

The optimized arm64 release executable also reads the local library successfully. Release validation uses `-debug-info-format none`: this restricted host rejects `dsymutil` during ordinary release dSYM generation, after compilation/linking. Source compilation and the resulting executable succeed without that debug-symbol packaging step.

- Local database: 32 active tracks, one playlist, 28 My Tags, zero metadata snapshot diagnostics.
- Independent ANLZ pass: all 96 local files parsed successfully (32 each DAT/EXT/2EX).
- Public package API pass: 773 beats, 160 waveforms, 191,260 waveform samples, zero cues. No private fixtures, titles, or paths were committed.
- Public API returned 226 informational unsupported-chunk diagnostics: PPTH/path, PVBR/seek data, PWV6/PWV7/PWVC, and two alternate PQT2 grids. These are skipped payloads, not malformed-file failures.
- The local library has no cue or phrase records and no intelligent playlists. Those features are validated by source interpretation and synthetic fixtures, not a local UI comparison.
- Synthetic 100,000-track snapshot: approximately 0.44–0.50 seconds in debug, including schema inspection and model materialization. No analysis files were loaded. This is a local measurement, not a general performance guarantee.
- The original 51-test suite was expanded with 16 public-API/CLI regression cases. There are now 67 Swift tests: 39 XCTest cases and 28 Swift Testing cases. The default Make target runs 65 and skips the two opt-ins. Twelve Python tooling tests cover structured reporting, opt-in isolation, and bounded cleanup scope.
- Encrypted WAL fixture demonstrates a writer commit is invisible inside an established read transaction and visible to a later read. Database/WAL byte hashes are unchanged by reads or rejected writes; the read-only handle does not checkpoint the WAL on close.
- A long-running SQLite query is interrupted by cancellation; wrong-key, absent-source, explicit-file grants, waveform cache invalidation, malformed-file repair, and system-SQLite coexistence tests pass.
- Symbol inspection confirms no unprefixed SQLite/SQLCipher definitions remain in the bundled codec object. System SQLite and the private codec can operate within the same test process.
- `Scripts/vendor-sqlcipher.py --check` now regenerates exactly matching amalgamation, header, and name-isolation bytes. The originally committed `sqlite3.inc` did not match: two `\u0000` escapes had become the text `^@`, one inside `jsonAppendRawNZ(pOut, "\\^@", 6)`, which reads six bytes from a three-byte literal. The amalgamation was regenerated from the pinned commit. `xoshiro_next`, the one external symbol outside the `sqlite3`/`sqlcipher` namespaces, is now renamed too; `nm -gU` on the codec object lists only `_rbr_*` symbols.

## Sandbox validation boundary

Bookmark resolution, stale/invalid grants, containment, denied/missing paths, bounded discovery, and scope cleanup are unit tested, including injected scope failures: a failed grant next to a working one, all grants failing for an otherwise readable file, overlapping denied and started scopes, stale-but-started bookmarks, and stop balancing on throws.

The signed probe now runs in a real App Sandbox process with the hardened runtime (`make test-sandbox`, 2026-10-17, macOS 27). Earlier attempts died before `main` (exit 133/134) because the tool had no embedded Info.plist; secinitd logged "Info.plist from code signature information has no value for kCFBundleIdentifierKey". With one embedded, all checks pass against an encrypted WAL library (production passphrase) whose writer stays open: no grant is denied, invalid-only grants are denied, a mixed invalid+valid list reads the library (`bookmarks=unresolvable,started`), a fresh process resolves the persisted bookmark again, and the change token is determinate. The probe uses an ad-hoc identity; the host's real signing identity, stale bookmarks, and offline volumes still need validation in the host.

## Completion and remaining coverage

Stages 0–4 are implemented for the supported desktop database and documented analysis formats. Unsupported chunks and intelligent rules remain explicit data/diagnostics rather than fabricated values. Remaining validation is the host app's own signing identity, Intel runtime testing, rekordbox 6 runtime testing, and real cue/phrase/intelligent-playlist comparisons using a suitable user-controlled library. New waveform/vocal/alternate-grid interpretation remains outside the currently supported decoder set.

The source library is never migrated, rekeyed, checkpointed, or edited. Shared-memory coordination is permitted as agreed. Tests write synthetic libraries only, except the explicitly enabled local read test.

## Makefile and regression validation

The Makefile adapts the local 2manyDJs Makefile's help, logs, structured-reporting, opt-in integration, formatting, and lint-baseline conventions to this Swift package. The default serial `swift test --xunit-output` produced no report with the installed toolchain. Separate `--parallel --disable-swift-testing` and `--parallel --disable-xctest` runs were verified to produce complete XCTest and Swift Testing XML reports. The reporter counts testcase elements: Swift Testing's suite `tests` attribute excludes skipped cases while its XML includes them.

Public-API tests now exercise cross-file cue precedence, empty extended lists, empty database-list authority, malformed-database fallback, corrupt sibling recovery, waveform-option cache behavior, snapshot invalidation, missing data, and symlink escape rejection. CLI tests use synthetic plaintext libraries and JSON decoding. They exposed deferred argument validation; missing option values and unknown arguments now fail before library discovery.

`make test-all` passes 66 Swift tests with the local-library test skipped, plus 12 tooling tests. `make test-integration` separately passes the real library read. Focused runs for both frameworks pass, while a filter matching no tests fails. Formatting and strict baseline lint pass with no new lint debt. The benchmark remains about 0.44 seconds in debug in this environment.

## Hilbert readiness pass (2026-10-17)

Changes for a sandboxed, live-browsing host: per-operation access contexts with non-fatal failed grants and `bookmarkStatus()`; real-home discovery with `options.json` analysis roots and diagnostics; separate database and file queues; `includeDatabaseCues`; `databaseCues(for:)`; `changeToken()`; `invalidateAnalysisCache()`; `Mutex`-based cancellation and cache; per-chunk ANLZ recovery; disabled legacy cues skipped; Span-based waveform decoders; public initializers; `audioTimeline(for:)`; and `TrackAnalysis.shifted(by:)`. The host guide is [integration.md](https://github.com/robbyt/swift-rekordboxReader/blob/main/docs/integration.md).

Measurements (debug build, arm64):

- Synthetic 100,000-track snapshot: 0.47 s.
- `analysis(for:)` with database cues: about 80 ms per call, almost all of it the SQLCipher key derivation for one fresh connection (each fresh connection that reads encrypted pages derives the key; 256,000 PBKDF2-HMAC-SHA512 iterations). Without database cues: about 19 µs plus file I/O. `databaseCues(for:)` pays the derivation once for many tracks. A retained connection was not added: it would have to hold security scopes across operations.
- Installed library (`make test-integration`): unchanged results (32 tracks, 773 beats, 160 waveforms, 226 informational unsupported-chunk diagnostics).
- Tests: 102 deterministic Swift tests pass with five opt-in skips; 13 tooling tests; 5 consumer-check tests compiled with default `MainActor` isolation and Approachable Concurrency.

### Decoder timeline (AVAudioFile)

`make test-decoder-timing` on the committed fixtures in `Fixtures/Timing` (`Scripts/timing-calibration.py`; LAME 3.100, afconvert, macOS 27; 12-second mono tracks). The offset is AVAudioFile click time minus source click time, fitted over every click (20–24 per file); drift and residuals were zero, and a seek never changed timing. Earlier 60-second stereo fixtures gave the same offsets.

| Format | Sample rates | Packet-table priming | LAME delay | AVAudioFile offset |
| --- | --- | --- | --- | --- |
| WAV, AIFF | 44.1 / 48 kHz | none | – | 0.00 ms |
| ALAC (M4A), FLAC | 44.1 / 48 kHz | 0 | – | 0.00 ms |
| MP3 CBR 320 and VBR V2, LAME tag | 44.1 / 48 kHz | 576 | 576 | 0.00 ms |
| MP3 CBR 320, no Xing/LAME tag (`lame -t`) | 44.1 kHz | none | – | +13.06 ms (576 samples) |
| MP3 CBR 320, no Xing/LAME tag (`lame -t`) | 48 kHz | none | – | +12.00 ms (576 samples) |
| AAC 256 kbps (M4A) | 44.1 / 48 kHz | 2112 | – | 0.00 ms |

AVAudioFile trims priming whenever the file declares it, and plays untagged MP3 576 samples late. These are host-side facts only.

### rekordbox timeline calibration (pending)

What rekordbox stores for the same files is not yet measured. To complete it: import and analyze `Fixtures/Timing` in rekordbox, copy the library into `Fixtures/Timing/rekordbox/` as its README describes, then run `make test-calibration`. It writes `calibration-report.md` with each file's offset (`playbackTime − rekordboxTime`), its offset relative to the WAV control, drift, residual, and matches. Record the table here. Then add `.calibrated` rows to `TimingRules` in `Sources/RekordboxReader/AudioTimeline.swift`, only for classes whose offset repeats across both sets and the held-out set, and bump `TimingRules.current.profile`. Until then, encoded formats report `confidence == .unknown` and no offset.
