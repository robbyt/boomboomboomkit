---
title: 'Story 12.3: Annotation-version tagging and the octave-error metric'
type: 'feature' # feature | bugfix | refactor | chore
created: '2026-08-06'
status: 'ready-for-dev' # draft | ready-for-dev | in-progress | in-review | done | blocked
review_loop_iteration: 1
followup_review_recommended: false
baseline_revision: 'e48475a' # branch rterhaar/12-3-annotation-version-tagging, clean tree
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

Line numbers are as of `e48475a`, 2026-08-06; the named symbol governs if they drift.

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

- [ ] `Sources/BoomBoomBoomKitTestSupport/AnnotationVersion.swift` -- NEW. An open
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
- [ ] `Sources/BoomBoomBoomKitTestSupport/AccuracyTally.swift` -- NEW. `acc1`, `acc2`,
  `total`, `annotationVersion`, and `octaveErrorProxy` as a computed `acc2 - acc1` (a
  track count; percentage-point rendering `100 * (acc2 - acc1) / total` lives beside it).
  Construction rejects `acc1 > acc2`. Carries the shared MIREX hit that returns the
  octave-strict and floor-compatible verdicts as distinct values, so the five hand-rolled
  pairings collapse to one and FR-61's proxy is meaningful on GiantSteps rather than
  pre-absorbed by the `tempo2` acceptance.
- [ ] `Sources/BoomBoomBoomKitTestSupport/JAMS/JAMSDecoder.swift` -- add an optional
  `version` property to `JAMSAnnotationMetadata` (absent today), so a declared version is
  representable at all. The synthetic declared-version unit fixture exercises it.
- [ ] `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift` -- new `loadVersionedCorpus`
  API per corpus returning the tracks plus the resolved `AnnotationVersion`, with the
  existing array-returning `loadCorpus` retained as a wrapper so its ~13 test-file call
  sites provably keep compiling. Add the GiantSteps loader (none exists today) and migrate
  the four raw `JSONDecoder().decode([GiantStepsTrack].self, ...)` sites to it. **All
  three corpora take the digest branch today** (corrected 2026-08-07: no corpus declares
  `annotation_metadata.version`; the migrator never writes it); the declared branch is
  exercised by the unit fixture and becomes live if a future migration populates the
  field.
- [ ] `Sources/BoomBoomBoomKitTestSupport/GenreAccuracyReporter.swift` -- add the
  `Acc2-Acc1` column (count, with percentage points) and surface the annotation version in
  the header, so the per-genre reading FR-61's success metric depends on is available
  without hand subtraction.
- [ ] `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift` -- bump the
  persisted schema and record the annotation version per corpus. **The reader must accept
  the previous schema and surface `untagged` for it**; rejecting it kills the cross-run
  delta line against every committed baseline. Mechanics: a **custom decoder** that
  defaults the version field to `.untagged` when `schemaVersion == 2`, decodes it for the
  bumped schema, and rejects unsupported versions -- a synthesized `Decodable` on a
  non-optional field would fail before `schemaVersion` can be inspected.
- [ ] `Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift` and
  `.../OA300BenchmarkTests.swift` -- adopt the shared tally and print the version and the
  proxy in the headline output. Hit counts must not change.
- [ ] `Tests/BoomBoomBoomKitTests/` -- NEW unit suite covering the I/O matrix: the untagged
  resolution path, the previous-schema read, the rejected `acc1 > acc2` construction, the
  degenerate zero proxy, and the strict-versus-floor split on a `tempo2` row.
- [ ] `Tests/BoomBoomBoomKitTests/GenreAccuracyReporterTests.swift` -- update goldens for
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
