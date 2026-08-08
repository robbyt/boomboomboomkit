---
title: 'Story 12.3: Annotation-version tagging and the octave-error metric'
type: 'feature' # feature | bugfix | refactor | chore
created: '2026-08-06'
status: 'done' # draft | ready-for-dev | in-progress | in-review | done | blocked
review_loop_iteration: 1
followup_review_recommended: true
final_revision: '0fb914b' # re-signed 2026-08-08
baseline_revision: '89e2092' # branch rterhaar/12-3-annotation-version-tagging-impl, clean tree (implementation run 2026-08-08; spec authored at e48475a)
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-12-context.md'
warnings: ['multiple-goals', 'oversized']
---

<intent-contract>

## Intent

**Problem:** Every accuracy figure this project reports is anonymous about the ruler that
produced it. Re-annotating GiantSteps moved a published system's Acc1 by ~6 points with no
algorithm change (Schreiber, Urbano & Müller, TISMIR 2020: Acc1 58.9 -> 64.8 -- the Story
12.3 AC names it in its "documented annotation swing" Given, `epics.md:2119`, and the PRD
carries the PUBLISHED capacity bullet, `prd.md:117`, both as of 2026-08-07), so a figure measured against one annotation set and compared against
another is a silent error, and Story 12.6 is about to declare a metrical-level convention
that makes every pre-convention figure incomparable. Separately, `Acc2 - Acc1` is the
standard octave-error proxy and this epic is about octave errors, yet no reporting surface
emits it: every consumer subtracts it by hand, if at all.

**Approach:** Put both obligations in one shared vocabulary in the test-support target, and
resolve the annotation version **at the corpus loader** so every one of the ~20 existing
emit sites inherits it rather than each remembering. Adopt it at the surfaces where figures
are persisted or gated, which is where cross-date comparison actually happens. A record
that predates tagging reads as `untagged`, never as current.

## Boundaries & Constraints

**Always:**
- The annotation-version identifier is an **open** type, not a closed enum. Story 12.6 must
  mint a tag for a project-declared convention on a project-built corpus, so the namespace
  spans both third-party annotation releases and internal declarations.
- **A present ground-truth file always resolves to a distinguishing tag**, never to
  `.untagged`. Declared version if the file carries one, otherwise a content digest over
  **canonicalized annotation content**, not raw file bytes (see Design Notes). See
  Design Notes: `.untagged` is reserved for figures whose source is no longer available.
- Tags are **namespaced**: `declared:<value>`, `sha256:<64 lowercase hex>`, and the
  sentinel `untagged`. Resolution rejects a declared value that is empty, whitespace-only,
  equal to `untagged`, or that collides with a reserved prefix -- otherwise a truth file
  declaring the literal string `"untagged"` or `"sha256:..."` forges the sentinel or a
  digest tag.
- `.untagged` is a first-class value, never `nil` and never absent. Reading a historical
  record that predates tagging must yield it explicitly.
- `Acc2 - Acc1` is emitted as its own named field and its own printed column, computable
  **per genre** (via `GenreAccuracyReporter`), not only in aggregate. ~~per band and~~
  (struck 2026-08-07: FR-61 and the Story 12.3 AC contain no band language, and no
  per-band reporting surface exists for corpus accuracy; "per band" was this spec's own
  unsupported addition.) The proxy is a track **count**; printed output shows both the
  count and percentage points, defined `100 * (acc2 - acc1) / total`, rendered to one
  decimal place, and `0.0` when `total == 0`.
- Corpus floors do not move: OA300 Acc1 >= 57/82, Acc2 >= 73/82 (measured 58/74);
  GiantSteps Acc1 >= 537/661, Acc2 >= 546/661, which sits **exactly** on its floor, so any
  GiantSteps drop is a blocker rather than a trend.
- Swift Testing only (`@Suite`/`@Test`/`#expect`), never XCTest. Swift 6 strict concurrency:
  new public types are `Sendable`. No third-party dependencies.

**Block If:**
- Any corpus floor moves. This story changes reporting, not detection; a moved floor means
  the refactor changed behaviour and must not be papered over.
- Adopting the shared MIREX helper changes any suite's hit count. The helper must be a pure
  extraction of existing logic.

**Never:**
- No changes to `Sources/BoomBoomBoomKit/` or `Sources/BoomBoomBoomKitML/`. **See Design
  Notes for why the AC's literal "`Sources/` is byte-identical" cannot be read literally.**
- Do not migrate or rewrite committed historical artifacts to backfill a version. The AC's
  obligation is at the point of surfacing, not a migration.
- Do not change what the committed GiantSteps floor scores against. Reporting the strict
  metric alongside it is in scope; changing the gate is Story 12.6's question.
- Do not invent a *declared* version for a corpus that declares none. The digest branch
  records what the file actually was; asserting it is "GiantSteps v2" would be a claim the
  repository cannot substantiate.
- Do not widen `.untagged` into "this corpus is undocumented". It means the source is no
  longer determinable, which is a strictly smaller set.
- **Never resolve to `file_metadata.jams_version`.** That is the JAMS *format* version
  (`"0.4.0"` on every entry of every JAMS artifact this project emits); it would be
  identical across any re-annotation, which is exactly the false-identity failure the
  digest branch exists to prevent. It is the only version-shaped field in the OA300
  fixture, so an implementer WILL reach for it without this line.
- Do not digest raw file bytes for the version tag. A converter re-serialization (key
  order, whitespace) must not mint a new annotation version for annotation-identical
  content. Raw bytes remain correct for `InputProvenance`, which answers a different
  question ("which file did this run read").

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Declared version present | A truth file whose `annotation_metadata` carries a non-null `version` -- a **synthetic unit-test fixture**; none of the three corpora declares one today (verified 2026-08-07: `version` is null on every OA300 fixture entry and every DAW-oracle entry, and GiantSteps has no version field at all) | Resolves to `declared:<value>`; every downstream figure carries it | Mixed or conflicting declared versions across a file's annotations fail loudly; empty/whitespace/reserved-colliding values are rejected, not silently digested |
| No declared version | All three real corpora today: OA300, the DAW oracle, GiantSteps | Resolves to a `sha256:` **content-digest** tag over canonicalized annotation rows, which is still distinguishing. NOT `.untagged` -- the file is present, so its identity is knowable | No error expected |
| Two annotation sets, same corpus | The same corpus re-annotated, so byte content differs | The two resolve to different tags and are therefore comparable-as-different | No error expected |
| Historical artifact read | A committed perf-baseline record at the previous `schemaVersion`, written before this story | Reads successfully and surfaces `.untagged`; the cross-run delta line still works | Rejecting it would silently kill the delta; reject only on unknown-and-unsupported |
| Current artifact read | A record at the bumped `schemaVersion` | Reads its recorded version verbatim | Malformed version string is a decode failure, not a silent `untagged` |
| Octave proxy, aggregate | acc1 = 58, acc2 = 74, total = 82 | `octaveErrorProxy == 16` (a track count), emitted as a named field and a column; printed with `19.5 pp` alongside | No error expected |
| Octave proxy, empty bucket | total == 0 | Count 0, percentage points printed `0.0`, no division-by-zero | No error expected |
| Octave proxy, degenerate | acc1 == acc2 | Proxy is 0 and still emitted, not suppressed as uninteresting | No error expected |
| Invariant violation | A tally constructed with acc1 > acc2 | Unrepresentable: rejected at construction | Acc2 is a superset of Acc1 by definition; a violation is a caller bug |
| GiantSteps dual scoring | A track whose detection matches `tempo2` but not `bpm` | Floor-compatible hit, octave-strict miss; both reported | No error expected |

</intent-contract>

## Code Map

**As built (2026-08-08, implementation run at baseline `89e2092`):**

- `Sources/BoomBoomBoomKitTestSupport/AnnotationVersion.swift` -- NEW.
  `AnnotationVersion:24` (open tag; `.untagged` static, validating `init(parsing:)` +
  Codable), `declared(_:):63`, `AnnotationRow` + `contentDigest(corpus:rows:):107`
  (length-prefixed UTF-8, big-endian IEEE-754 bit patterns, 0x00/0x01 nil markers,
  domain prefix `BoomBoomBoomKit.annotation.v1/<corpus>`), two-rule `resolve:150`,
  `AccuracyRecordSchema:218` (schema 2 -> `.untagged`, 3 required, else rejected --
  extracted here so the perf-baseline back-compat rule is unit-testable).
- `Sources/BoomBoomBoomKitTestSupport/AccuracyTally.swift` -- NEW. `AccuracyTally:15`
  (throwing init rejects `acc1 > acc2`; `octaveErrorProxy` count + `%.1f` pp,
  `0.0` at `total == 0`), `MIREXTempoVerdict:71` (carries the relocated 71-track
  strict-vs-floor doc comment), `mirexTempoVerdict:92` (the shared pairing all five
  hand-rolled sites migrated to).
- `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift` -- `VersionedCorpus:81`,
  `resolveJAMSAnnotationVersion:98` (row ID `identifiers.local_path`, loud fail when
  absent; never reads `jams_version`), OA300 `loadVersionedCorpus:181` (+ `loadCorpus`
  wrapper `:174`), `extension GiantStepsTrack:189` (NEW `loadCorpus` +
  `loadVersionedCorpus:200`, row ID `track_id`), DAW `loadVersionedCorpus` below it.
- `Sources/BoomBoomBoomKitTestSupport/JAMS/JAMSDecoder.swift` --
  `JAMSAnnotationMetadata.version:243` (optional, defaulted init param, key `version`).
- `Sources/BoomBoomBoomKitTestSupport/GenreAccuracyReporter.swift` --
  `GenreBucket.octaveErrorProxy:37`/`:41`, `format` gains
  `annotationVersion: AnnotationVersion = .untagged` `:117`, header line
  `Annotation version: <tag>` `:140`, `Acc2-Acc1` column cell `:179`
  (`%3d %5.1fpp`; `insufficient` cell widened to 27 to span it).
- `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift` --
  `AccuracySnapshot.annotationVersion:132` (optional, normalized non-nil at decode),
  custom `BaselineRecord.init(from:):153` (schemaVersion-first decode,
  `AccuracyRecordSchema.supported` gate), `readHistory` guard `:267`, writer
  `schemaVersion: AccuracyRecordSchema.current:783`, per-corpus versions recorded
  `:460` (oa300) / `:767` (giantsteps).
- `Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift` /
  `OA300BenchmarkTests.swift` -- loaders flipped to `loadVersionedCorpus`, headline
  prints `Annotation version:` + `Acc2-Acc1 (octave-error proxy):` via `AccuracyTally`,
  genre passes thread `annotationVersion` into the reporter; `mirexHit` delegates to
  `mirexTempoVerdict` (floor pair).
- Migrated raw-decode/hand-rolled sites: `AccuracyForensicsTests.swift:77`,
  `AblationFullMatrixTests.swift:503` (both -> `GiantStepsTrack.loadCorpus`),
  `OctaveThresholdSweepTests.swift` sweep hit, `TempoRangeImpactTests.swift` strict
  pairing (12.1 impact path) + SMC floor/strict block -- all via `mirexTempoVerdict`.
- `Tests/BoomBoomBoomKitTests/AnnotationVersionTests.swift` -- NEW unit suites
  `AnnotationVersion` (declared/reserved/conflict, digest determinism + order/corpus/nil
  discrimination, validating Codable, schema rule, synthetic declared-version JAMS
  fixture, GiantSteps re-serialization invariance) and `AccuracyTally` (proxy
  aggregate/empty/degenerate, rejected construction, strict-vs-floor split).
- `Tests/BoomBoomBoomKitTests/GenreAccuracyReporterTests.swift` -- new column/header
  tests (goldens are contains-based; existing ones unchanged and passing).

Spec-time line numbers below are as of `e48475a`, 2026-08-06; the named symbol governs
if they drift.

- `Sources/BoomBoomBoomKitTestSupport/AccuracyMatchers.swift` -- `isAcc1Match:7`,
  `isAcc2Match:18`, `classifyTempoError:45`. The primitives. Untouched; the new tally
  composes them.
- `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift` -- `OA300Track:17` +
  `loadCorpus:124`, `GiantStepsTrack:40`, `DAWOracleTrack:57` + `loadCorpus:165`. The
  intended choke point where every benchmark acquires ground truth. **Not yet true for
  GiantSteps** (corrected 2026-08-07): four suites decode `[GiantStepsTrack]` raw via
  `JSONDecoder` -- `GiantStepsBenchmarkTests.swift:50`, `AccuracyForensicsTests.swift:77`,
  `PerformanceBenchmarkTests.swift:635`, `AblationFullMatrixTests.swift:503` -- so this
  story adds a GiantSteps loader and migrates those sites; only then does the loader
  inherit-everywhere argument hold.
- `Sources/BoomBoomBoomKitTestSupport/JAMS/JAMSDecoder.swift` -- `JAMSAnnotationMetadata`
  has **no `version` property today** (verified 2026-08-07), so the declared branch
  requires adding the optional field to the JAMS model. TestSupport, in scope.
- `Sources/BoomBoomBoomKitTestSupport/GenreAccuracyReporter.swift` -- `GenreBucket:19-56`
  (closed 4-field struct, `precondition(acc1Correct <= acc2Correct):48`), `format:99`,
  header `:113-115`, `renderRow:148-165`, `minSampleSize:5`. The per-genre surface FR-61's
  success metric needs. Adding a column touches struct, header, row renderer, and goldens.
- `Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift` -- `mirexHit:346`
  (the `tempo2` fallback, doc-commented today with the 361/71 finding), headline emit
  `:54-61`, genre pass `:209-245`.
- `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift` -- headline emit
  `:70-76`, genre pass `:712-742`.
- `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift` -- `schemaVersion`
  written `:720`, **reader rejects != 2 at `:211`**, `AccuracySnapshot:696-704`,
  `BaselineRecord.accuracy:743`, GiantSteps hit helper `:684-692`. The only persisted
  accuracy artifact with a version field and a back-compat reader, so it is where the
  `untagged` path is genuinely exercised.
- `Tests/BoomBoomBoomKitBenchmarkTests/TempoRangeImpactTests.swift` -- `InputProvenance:621`
  (basename + SHA-256 of raw bytes, landed 2026-08-06). The provenance precedent; it stays
  raw-bytes, and the version tag digests canonicalized content instead (see Design Notes).
- `Tests/BoomBoomBoomKitTests/GenreAccuracyReporterTests.swift` -- golden strings that move
  when the column is added.
- `_bmad-output/implementation-artifacts/deferred-work.md` -- the 2026-08-06 entry
  recommending octave-strict scoring alongside floor-compatible on GiantSteps. This story
  makes the strict number available; whether it becomes enforced is noted there, not here.

**Duplication this story removes** (recounted 2026-08-07). Four hand-rolled sites
implement the floor-compatible primary-or-`tempo2` MIREX pairing --
`GiantStepsBenchmarkTests.swift:346-357`, `OctaveThresholdSweepTests.swift:296-306`,
`PerformanceBenchmarkTests.swift:684-692`, `TempoRangeImpactTests.swift:912-930` -- and a
fifth hand-rolls the primary-only Acc1/Acc2 pairing with no `tempo2`
(`TempoRangeImpactTests.swift:370-386`, the 12.1 impact path). They share the same
verdict contract, not identical code (a typed helper, inline expressions, and an array
variant). No shared helper computes Acc1 and Acc2 together; the shared tally is what all
five migrate to.

## Tasks & Acceptance

**Execution:**

- [x] `Sources/BoomBoomBoomKitTestSupport/AnnotationVersion.swift` -- NEW. An open
  identifier (`Sendable`, `Hashable`, `Codable`, `CustomStringConvertible`) wrapping a
  string, with `.untagged` as a named static. Open because Story 12.6 must mint one; a
  closed enum would have to be reopened by that story. Provides the two-rule resolution:
  a declared version when the source carries one (all version-declaring annotations in the
  file must agree; mixed or conflicting values fail loudly; none means digest), else a
  content digest over **canonicalized annotation rows**, not raw bytes. Canonical form:
  domain prefix `BoomBoomBoomKit.annotation.v1/<corpus>`, rows
  `(stableRowID, primaryTempo, alternateTempo?, genre?)` sorted by row ID, encoded with
  length-prefixed UTF-8 strings, IEEE-754 bit patterns for tempos, and an explicit nil
  marker -- no delimiter ambiguity, no float-format drift. `stableRowID` is
  `file_metadata.identifiers.local_path` for the JAMS corpora (verified 2026-08-07:
  `local_path` is 82/82 unique on OA300 while `track_id` is only 80/82) and the GiantSteps
  track id for GiantSteps. Rendered `sha256:<64 lowercase hex>`. Do not
  enumerate corpus-specific statics beyond what a resolution rule needs; a per-corpus
  static list is the closed-enum failure mode wearing different clothes.
- [x] `Sources/BoomBoomBoomKitTestSupport/AccuracyTally.swift` -- NEW. `acc1`, `acc2`,
  `total`, `annotationVersion`, and `octaveErrorProxy` as a computed `acc2 - acc1` (a
  track count; percentage-point rendering `100 * (acc2 - acc1) / total` lives beside it).
  Construction rejects `acc1 > acc2`. Carries the shared MIREX hit that returns the
  octave-strict and floor-compatible verdicts as distinct values, so the five hand-rolled
  pairings collapse to one and FR-61's proxy is meaningful on GiantSteps rather than
  pre-absorbed by the `tempo2` acceptance.
- [x] `Sources/BoomBoomBoomKitTestSupport/JAMS/JAMSDecoder.swift` -- add an optional
  `version` property to `JAMSAnnotationMetadata` (absent today), so a declared version is
  representable at all. The synthetic declared-version unit fixture exercises it.
- [x] `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift` -- new `loadVersionedCorpus`
  API per corpus returning the tracks plus the resolved `AnnotationVersion`, with the
  existing array-returning `loadCorpus` retained as a wrapper so its ~13 test-file call
  sites provably keep compiling. Add the GiantSteps loader (none exists today) and migrate
  the four raw `JSONDecoder().decode([GiantStepsTrack].self, ...)` sites to it. **All
  three corpora take the digest branch today** (corrected 2026-08-07: no corpus declares
  `annotation_metadata.version`; the migrator never writes it); the declared branch is
  exercised by the unit fixture and becomes live if a future migration populates the
  field.
- [x] `Sources/BoomBoomBoomKitTestSupport/GenreAccuracyReporter.swift` -- add the
  `Acc2-Acc1` column (count, with percentage points) and surface the annotation version in
  the header, so the per-genre reading FR-61's success metric depends on is available
  without hand subtraction.
- [x] `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift` -- bump the
  persisted schema and record the annotation version per corpus. **The reader must accept
  the previous schema and surface `untagged` for it**; rejecting it kills the cross-run
  delta line against every committed baseline. Mechanics: a **custom decoder** that
  defaults the version field to `.untagged` when `schemaVersion == 2`, decodes it for the
  bumped schema, and rejects unsupported versions -- a synthesized `Decodable` on a
  non-optional field would fail before `schemaVersion` can be inspected.
- [x] `Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift` and
  `.../OA300BenchmarkTests.swift` -- adopt the shared tally and print the version and the
  proxy in the headline output. Hit counts must not change.
- [x] `Tests/BoomBoomBoomKitTests/` -- NEW unit suite covering the I/O matrix: the untagged
  resolution path, the previous-schema read, the rejected `acc1 > acc2` construction, the
  degenerate zero proxy, and the strict-versus-floor split on a `tempo2` row.
- [x] `Tests/BoomBoomBoomKitTests/GenreAccuracyReporterTests.swift` -- update goldens for
  the new column.

**Acceptance Criteria:**

- Given a benchmark that scores against a corpus whose annotation version is resolvable,
  when it reports an accuracy figure, then that figure carries the version rather than
  leaving it to the reader (FR-60).
- Given a persisted baseline record written before this story, when it is read, then it is
  surfaced as `untagged` and the cross-run delta still works, rather than being rejected or
  silently assumed to match current labels.
- Given GiantSteps has a documented annotation swing and its ground truth declares no
  version, when the same corpus is scored against two different annotation sets, then the
  two figures carry different tags and are therefore distinguishable from each other.
- Given any adopted accuracy report, when it is emitted, then `Acc2 - Acc1` appears as a
  named field and a printed column alongside Acc1, not as something the reader derives.
- Given Story 12.6 will mint a tag for a newly declared convention, when it does, then it
  needs no change to the identifier type, because the namespace is open.
- Given this story is measurement infrastructure, when it lands, then
  `git diff --stat e48475a -- Sources/BoomBoomBoomKit/ Sources/BoomBoomBoomKitML/` is
  empty, and both corpus floors are unchanged.

## Spec Change Log

- **2026-08-07 (review_loop_iteration 1):** Corrections from the PR #192 fact-check
  review, all verified against the tree before adoption. (1) All three corpora take the
  digest branch today; the declared branch moves to a synthetic unit fixture; new Never
  bullets on `jams_version` and the `"untagged"` literal; tag namespaces
  `declared:`/`sha256:`/`untagged`. (2) "Per band" struck from the FR-61 Always bullet
  and both prose sites. (3) Digest input pinned to canonicalized annotation rows with a
  fully specified encoding; row ID is `local_path` (82/82 unique vs `track_id` 80/82).
  (4) Anchors corrected (`mirexHit:346`, `InputProvenance:621`, NFR-11 at `epics.md:223`);
  duplication inventory recounted to four floor-compatible sites plus one primary-only.
  (5) Intent citation corrected to `prd.md:117` / `epics.md:2119`. Plus: `JAMSDecoder`
  version-property task, `loadVersionedCorpus` + GiantSteps-loader migration (the
  choke-point claim was false as written), custom-decoder mechanics for the schema bump,
  proxy pinned as count + percentage points, CryptoKit TestSupport authorization, and the
  FR-60 narrowing converted into an explicit operator checkpoint.

## Review Triage Log

**2026-08-07 -- PR #192 review (5 inline findings + summary), fact-checked individually:**

1. *OA300 declared-version premise false* -- **ACCEPTED** (reviewer's option 2). Verified:
   `annotation_metadata.version` null on all OA300 and DAW-oracle entries;
   `migrate-to-jams.py` never writes it. I/O matrix, `CorpusTracks` task, and Design Notes
   rewritten; `jams_version` and `"untagged"`-literal Never bullets added.
2. *"Per band" uncovered and misattributed* -- **ACCEPTED**. Verified zero band concept in
   `GenreAccuracyReporter` and no band language in FR-61 or the story AC. Struck.
3. *Digest input unpinned* -- **ACCEPTED**, canonicalized-content direction taken, with
   the encoding, row schema, and namespace fully specified rather than left to the
   implementer.
4. *Code Map anchors* -- **ACCEPTED IN PART**. `mirexHit:346`, `InputProvenance:621`,
   NFR-11 file attribution, and the fifth pairing at `:370-386` all verified and adopted.
   **REJECTED:** the claim that `:905-930` "is the arm-runner" and the pairing lives at
   `:572-597`/`:694-717`. Verified the floor-compatible primary-or-alt pairing IS at
   `:912-930` (`isAcc1Match`/`isAcc2Match` against `truthBPM` and `altTruthBPM`); the
   proposed ranges are the `AlternateTruthCensus` struct and stored-column doc comments.
   Anchor tightened to `:912-930`, relocation declined.
5. *Uncited ~6-point claim* -- **ACCEPTED**; cited as Schreiber, Urbano & Müller,
   TISMIR 2020, `prd.md:117` + `epics.md:2119` (an intermediate fix citing `prd.md:93`
   was itself wrong -- `:93` is the "On capacity" heading -- and was corrected same-day).

Secondary fact-check (Codex, 2 rounds, same-day) confirmed the five dispositions
including the item-4 rejection, and surfaced the additional corrections recorded in the
change-log entry above; every claim was re-verified against the tree before adoption
(one of its counts was itself corrected: OA300 nested `track_id` is 80/82 unique, and an
earlier "1 unique" figure came from querying a nonexistent top-level key).

## Design Notes

**The story's own AC contradicts itself, and the contradiction is resolvable from the
text.** `epics.md:2127-2129` reads "`Sources/` is byte-identical; changes are confined to
the benchmark and **test-support** surface." But `BoomBoomBoomKitTestSupport` **is** a
target under `Sources/`, so the two clauses cannot both hold literally. Three pieces of
text resolve it toward the shipping-library reading:

1. The same sentence names the test-support surface as permitted, so it cannot be the thing
   held byte-identical.
2. NFR-11 (labelled at `epics.md:223`; the PRD carries the sentence unlabelled in §10,
   `prd.md:396` as of 2026-08-07) states the hard contract as "DSP-only output remains
   byte-identical", which is the two shipping library targets, not the fixture target.
3. The sibling stories state the stricter form deliberately: 12.4 and 12.5 say "`Sources/`
   **and `Tests/`** are byte-identical" (`epics.md:2166`, `:2198`). The author distinguishes
   the scopes on purpose, and 12.3 got the weaker one plus an explicit permission.

So the gate is `Sources/BoomBoomBoomKit/` and `Sources/BoomBoomBoomKitML/`. Recorded here
rather than silently assumed, because it widens the story's blast radius. **Note the
consequence:** `BoomBoomBoomKitTestSupport` ships to `main`, so the new types are public API
on the release branch. That is consistent with precedent, since `AccuracyMatchers` and
`GenreAccuracyReporter` already live there as public API.

**Why a content digest, and what `.untagged` is actually for.** The epic AC requires that
GiantSteps annotation versions be "distinguishable from each other by tag". GiantSteps
ground truth is a flat array with no version field anywhere, so a naive reading resolves it
to `.untagged` -- and then a future re-annotation also resolves to `.untagged`, and the two
are **not** distinguishable, which fails the AC the reading was meant to satisfy. A content
digest over the truth content distinguishes any two annotation sets deterministically and
needs no cooperation from the upstream dataset. ~~It also degrades correctly: OA300
declares JAMS metadata, so it gets a declared tag, and the digest is the fallback rather
than the rule.~~ (Corrected 2026-08-07: OA300's `annotation_metadata` carries only
`{curator, data_source}` -- `version` is null on all 82 entries, and on all DAW-oracle
entries; both files are emitted by `migrate-to-jams.py`, which never writes a version. So
today the digest is the rule for **all three corpora** and the declared branch is
exercised by a synthetic unit fixture until a future migration populates the field. The
only version-shaped field in the fixture is `file_metadata.jams_version`, the JAMS format
version, which must never be used -- see the Never list.)

**Why the digest input is canonicalized content, not raw bytes.** The truth files are
*generated conversion artifacts*: a converter rerun that reorders keys or changes
whitespace would change a raw-byte digest and mint a new "annotation version" for
annotation-identical content -- the false-distinction dual of the false-identity failure
above, and it would silently fragment exactly the cross-date comparison this story exists
for. The digest therefore covers the canonical rows defined in the AnnotationVersion task
and changes only when an annotation actually changes. `InputProvenance` stays raw-bytes:
provenance ("which file did this run read") and annotation identity are different
questions with different correct answers.

**CryptoKit in TestSupport.** The digest uses CryptoKit's SHA-256. Project context
records CryptoKit as imported only by `ModelRegistry` in the core target; this story
extends that authorization to `BoomBoomBoomKitTestSupport` (a system framework, so NFR-2's
no-third-party rule is untouched; `Tests/` already imports it in
`TempoRangeImpactTests.swift`). The project-context sentence takes its dated amendment
when this lands.

That leaves `.untagged` meaning exactly what FR-60 wants it to mean and nothing else: a
**historical figure whose source is no longer determinable**, such as a persisted baseline
written before this story. It is not a synonym for "this corpus is undocumented". Keeping
those two cases distinct is the difference between a tag that carries information and one
that merely records our ignorance.

**Why version resolution belongs at the loader.** There are roughly twenty sites that emit
an Acc1/Acc2 figure and eleven JSON schemas that persist one. Attaching the version at each
emit site is twenty chances to forget. `CorpusTracks` is the intended single choke point --
**but not yet the actual one** (corrected 2026-08-07): GiantSteps has no loader there and
four suites decode it raw (sites named in the Code Map). This story adds the GiantSteps
loader and migrates those four sites; only after that does "resolving at the loader makes
the tag free downstream" hold, which is why the migration is an execution task rather than
an assumption. The `loadVersionedCorpus`-plus-wrapper shape keeps the ~13 existing
`loadCorpus` call sites compiling by construction rather than by promise.

**Why the strict-versus-floor split is FR-61's problem and not scope creep.** On GiantSteps
the committed metric scores a hit against `bpm` **or** `tempo2`, and 361 of 661 rows carry a
second annotation within tolerance of an octave relation, of which 71 are realized on a
default-configuration baseline. `Acc2 - Acc1` on that metric is therefore partly
pre-absorbed: the metric has already forgiven some of the octave error the proxy exists to
measure. Emitting the proxy against the floor metric alone would be a misleading number, so
the shared helper returns both verdicts.

**Scope boundary -- an explicit deviation from FR-60's letter, flagged for the operator.**
FR-60 says "every reported accuracy figure". This story builds the vocabulary and adopts
it at the surfaces where figures are **persisted or gated**, which is where the story's
own "so that" clause bites: a number is compared across corpora and dates only if it was
written down. Exploratory stdout-only sweeps inherit the vocabulary through the loader but
are not converted here. That is a **narrowing of the FR as written**, not just a note:
a version available from the loader is not the same as a version carried on every emitted
figure. OPERATOR CHECKPOINT (2026-08-07, raised on PR #192): accept the persisted-or-gated
boundary (recording the FR-60 amendment in the triage log when accepted), or widen this
story to convert the remaining stdout-only emit sites. The spec proceeds on the narrowed
reading until answered.

### Implementation Notes (2026-08-08)

Judgment calls made during the implementation run, none contradicting the contract:

- **`AccuracyTally` rejects invalid counts with a throwing init**, not a
  `precondition`: "rejected at construction" must be unit-testable under Swift
  Testing, and a precondition crash is not. `TallyError.invalidCounts` also covers
  negatives and `acc2 > total`.
- **The schema back-compat rule lives in TestSupport** (`AccuracyRecordSchema`)
  rather than inline in the private `BaselineRecord` decoder, so the
  previous-schema-read row of the I/O matrix is covered by the non-env-gated unit
  suite; the benchmark decoder calls it. The custom `BaselineRecord.init(from:)`
  sits in an extension to preserve the synthesized memberwise init.
- **Digest encoding pinned as**: 8-byte big-endian UTF-8 byte-count length
  prefixes, 8-byte big-endian IEEE-754 bit patterns, `0x00`/`0x01` optional
  markers, rows sorted by `stableRowID` in UTF-8 byte order (equivalent to Unicode-scalar order for well-formed strings; stated as bytes to match the code and the golden vector literally). Documented on
  `contentDigest`.
- **`loadCorpus` is a true wrapper** (`loadVersionedCorpus(...).tracks`), which
  adds a loud-fail on a JAMS entry missing `identifiers.local_path` to the ~13
  existing call sites. Verified before adopting: `local_path` is present and
  unique on all 82 OA300 rows, all 23 DAW-oracle rows, and every synthetic unit
  fixture, so no existing path changes behavior.
- **All five hand-rolled MIREX pairings migrated** to `mirexTempoVerdict` (the
  tally task's "five collapse to one"), including `OctaveThresholdSweepTests` and
  both `TempoRangeImpactTests` sites, as pure expression-equivalent swaps.
- **Reporter column format**: proxy cell `%3d %5.1fpp`; the `insufficient` cell
  widened from 14 to 27 chars to span the new column; `Annotation version: <tag>`
  is line 2 of every report, defaulting to `untagged` when a caller passes none
  (the existing reporter tests' non-version call sites stay valid).
- One edge accepted: a schema-3 baseline record with a MISSING version field
  fails loudly via `AccuracyRecordSchema.missingAnnotationVersion` (spec-aligned);
  a schema-3 record with a MALFORMED string fails in `AnnotationVersion`'s
  validating decoder before the schema rule runs -- both are decode failures,
  never silent `untagged`.
- Measured on this run: GiantSteps digest tag
  `sha256:7c4dafc499c97cb40d837806ef5675211065d628a0689e411de260fe8d65a686`;
  floor-metric proxy at default config is 9 tracks (1.4 pp) on 537/546/661.

### 2026-08-08 -- Review pass (Blind Hunter + Edge Case Hunter, post-implementation)
- intent_gap: 0
- bad_spec: 0
- patch: 12: (high 0, medium 3, low 9)
- defer: 0
- reject: 6
- addressed_findings:
  - `[medium]` `[patch]` Two raw GiantSteps `JSONDecoder` sites remained (OctaveThresholdSweepTests, TempoRangeImpactTests SMC arm) beyond the four the spec enumerated; migrated to the versioned loader. The spec's count of four was a survey undercount, not a scope decision.
  - `[medium]` `[patch]` Digest determinism guards: stableRowID uniqueness enforced (typed error on duplicates), empty row IDs rejected in both the JAMS resolver and the GiantSteps loader, rows sorted by UTF-8 byte order instead of String `<` (canonical-equivalence sorting could flap the tag), empty row set refuses to mint a tag on both the digest and declared branches.
  - `[medium]` `[patch]` A schema-2 accuracy record carrying an `annotationVersion` field is now a loud decode failure instead of being silently trusted; schema 2 predates tagging, so a present field is forged or foreign.
  - `[low]` `[patch]` Declared-version collection restricted to tempo-namespace annotations; a beat-annotation version can no longer tag a tempo corpus.
  - `[low]` `[patch]` `contentDigest` throws on non-finite tempos and canonicalizes -0.0 to 0.0 before taking the IEEE-754 bit pattern.
  - `[low]` `[patch]` `declared(_:)` trims whitespace before validation, rejects control characters and interior newlines (report-line injection), and applies the reserved-prefix check case-insensitively ("SHA256:", "Untagged" variants rejected).
  - `[low]` `[patch]` Unsupported perf-baseline schema now surfaces as "unsupported schemaVersion N" instead of "malformed baseline file"; the unreachable post-decode guard removed.
  - `[low]` `[patch]` `MIREXTempoVerdict.miss` added; the hand-built all-false sentinel in the SMC harness uses it.
  - `[low]` `[patch]` New unit tests covering every guard above, including a three-ordering digest-determinism test with a non-ASCII row ID.
  - Rejected (spec-conformant design or unreachable): digest row tuple excludes beat annotations and GiantSteps filename (the canonical row is pinned by this spec); partial declared-version resolution follows the spec's agreeing-set rule; tally/reporter proxy render differ deliberately (prose line vs table cell); reporter column overflow needs a >999-track bucket; throwing tally on acc1>acc2 is structurally unreachable at call sites; `loadCorpus` wrapper's loud-fail on missing local_path is the spec's own choke-point contract.

### 2026-08-08 -- PR #195 review pass (7 inline findings, fact-checked individually)
- intent_gap: 0
- bad_spec: 0
- patch: 7: (high 0, medium 2, low 5)
- defer: 0
- reject: 0
- addressed_findings:
  - `[medium]` `[patch]` No golden-vector test pinned the canonical digest byte stream; every digest test was self-referential, so a canonicalization change would silently re-mint every `sha256:` tag. Added a test pinning the exact 64-hex tag for a fixed two-row input, commented that changing the byte stream requires a `.v2` domain-prefix bump.
  - `[medium]` `[patch]` The GiantSteps headline labelled a floor-based Acc2-Acc1 as "the octave-error proxy" while the floor metric is near-blind to octave behaviour. `runBenchmark` now also tallies primary-only strict verdicts and every GiantSteps headline prints both, labelled floor-compatible and primary-strict (at the committed floors: floor 9 / 1.4 pp, strict 60 / 9.1 pp).
  - `[low]` `[patch]` `try?` in the perf-benchmark GiantSteps pass swallowed the versioned loader's typed failures and blamed the env var; the skip line now prints the actual error.
  - `[low]` `[patch]` The DAW-oracle digest row omitted `rekordbox_bpm`, so a regenerated oracle with corrected cross-check values minted an identical tag; `rekordboxBpm` now feeds `alternateTempo`. Latent: no committed artifact records a DAW tag (verified by grep).
  - `[low]` `[patch]` `init?(parsing:)` normalized padded `declared:` payloads instead of failing; the parsing path now rejects non-canonical payloads while `declared(_:)` construction keeps trimming. Tests added.
  - `[low]` `[patch]` Decode-time schema-2 normalization left `schemaVersion: 2` on a record now carrying the field, so a re-encode round-trip would poison the file for this same decoder; normalization now bumps the decoded record to schema 3. Round-trip test added.
  - `[low]` `[patch]` The two harnesses that discarded the resolved tag now print it in their output headers, and the four copy-pasted tally print blocks collapsed into a shared `AccuracyTally` headline helper (which also gave the strict-proxy line a single home).

### 2026-08-08 -- PR #195 Copilot review pass (5 comments, fact-checked individually)
- intent_gap: 0
- bad_spec: 0
- patch: 5: (high 0, medium 0, low 5)
- defer: 0
- reject: 0
- addressed_findings:
  - `[low]` `[patch]` `contentDigest` is public but did not reject an empty `stableRowID` (only the loaders guarded it); the validation loop now throws `missingStableRowID` on an empty ID. Test added.
  - `[low]` `[patch]` `declared(_:)` rejected only `CharacterSet.controlCharacters`, so U+2028/U+2029 (category Zl/Zp, in `.newlines` but not control characters) passed interior to a payload and could split a printed header line; the validation now rejects `.newlines` members too. Test added.
  - `[low]` `[patch]` `resolve` compared raw declared strings before `declared(_:)`'s trimming, so `"v2"` and `" v2 "` falsely conflicted although each alone canonicalizes to `declared:v2`; every declaration is now canonicalized and validated first, and the agreement check runs on canonical tags (the conflict error still lists payload values). Test added.
  - `[low]` `[patch]` A schema-2 baseline record with an explicit `"annotationVersion": null` decoded as absent (`decodeIfPresent` collapses null and absent) and bypassed the carrying-the-field-fails-loudly rule; the snapshot decoder now captures `container.contains(.annotationVersion)` and the schema rule takes the presence bit. JSON-level test added.
  - `[low]` `[patch, premise rejected]` The implementation note said rows sort in "Unicode-scalar order" while the code sorts UTF-8 bytes. Copilot's claim that the two orders can differ is FALSE (UTF-8 byte order preserves scalar order for all well-formed strings by design; the divergence exists for UTF-16 code units); accepted as wording precision only -- the note now says UTF-8 byte order and records the equivalence.

None of the five changes the digest byte stream: the golden-vector test is unchanged and green, and both corpus tags are unaffected (the new guards reject inputs no real corpus produces; the resolve fix changes behavior only for whitespace-variant declarations, which no corpus carries).

## Verification

**Commands:**
- `make test` -- expected: 993 or more tests, 168 or more suites, still 4 known issues, all
  passing. The count rises by the new unit suite.
- `make benchmark` -- expected: OA300 Acc1 58/82, Acc2 74/82, unchanged, now printing the
  annotation version and the `Acc2-Acc1` column.
- `make benchmark-giantsteps` -- expected: Acc1 537/661, Acc2 546/661, unchanged. This sits
  exactly on its floor; any drop is a blocker.
- `make perf-benchmark` -- expected: writes a record at the bumped schema, and the delta
  line against the previous committed baseline still renders, proving the untagged
  back-compat path.
- `git diff --stat e48475a -- Sources/BoomBoomBoomKit/ Sources/BoomBoomBoomKitML/` --
  expected: empty.
- `make pre-commit` -- expected: green.

**Manual checks:**
- One committed perf-baseline JSON at the previous schema still reads and reports
  `untagged`, confirmed by the delta line rendering rather than by inspecting the file.

## Auto Run Result

Status: done (2026-08-08, bmad-dev-auto run; spec authored 2026-08-06 at e48475a, implemented at baseline 89e2092)

**Summary:** Annotation-version tagging (FR-60) and the Acc2-Acc1 octave-error proxy (FR-61) landed in the test-support and benchmark surface. `AnnotationVersion` (namespaced `declared:` / `sha256:` / `untagged` tag space, two-rule resolution, CryptoKit content digest over canonicalized rows), `AccuracyTally` + `MIREXTempoVerdict` (shared strict/floor pairing collapsing five hand-rolled variants), versioned corpus loaders (`loadVersionedCorpus` with `loadCorpus` compat wrappers), all six raw GiantSteps decode sites migrated, perf-baseline schema bumped to 3 with schema-2 records reading as `untagged`.

**Files:** Sources/BoomBoomBoomKitTestSupport/{AnnotationVersion,AccuracyTally}.swift (new), {CorpusTracks,GenreAccuracyReporter,JAMS/JAMSDecoder}.swift (modified); Tests/BoomBoomBoomKitTests/AnnotationVersionTests.swift (new), GenreAccuracyReporterTests.swift; Tests/BoomBoomBoomKitBenchmarkTests/{GiantSteps,OA300,Performance,AccuracyForensics,AblationFullMatrix,OctaveThresholdSweep,TempoRangeImpact}Tests.swift.

**Review:** 12 patches applied (3 medium, 9 low), 0 deferred, 6 rejected; no intent gaps, no spec repairs.

**Verification:** `make test` 1031/170 suites, 4 known issues, green. `make benchmark`: OA300 Acc1 58/82, Acc2 74/82, proxy 16 (19.5 pp), version `sha256:6dd9349a...`. `make benchmark-giantsteps`: Acc1 537/661, Acc2 546/661 (exact floors), proxy 9 (1.4 pp), version `sha256:7c4dafc4...65a686`. `make perf-benchmark`: schema-3 record written, delta line rendered against the schema-2 baseline at 8bcec39 (untagged back-compat path proven). `git diff --stat 89e2092 -- Sources/BoomBoomBoomKit/ Sources/BoomBoomBoomKitML/` empty. `make ml-training-tests` 37 passed. `make pre-commit`: all gates green except two `scripts/tests/test_promote_to_main.py` cases that fail only because the 1Password commit signer is locked (any `git commit` in a scratch repo fails; reproduced independently of this change; they will pass once the signer is unlocked).

**Residual risks:** none identified beyond the rejected-findings rationale above; the two signer-dependent test failures are environmental.
