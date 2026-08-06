---
title: 'Story 12.3: Annotation-version tagging and the octave-error metric'
type: 'feature' # feature | bugfix | refactor | chore
created: '2026-08-06'
status: 'ready-for-dev' # draft | ready-for-dev | in-progress | in-review | done | blocked
review_loop_iteration: 0
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
algorithm change, so a figure measured against one annotation set and compared against
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
  `.untagged`. Declared version if the file carries one, otherwise a content digest. See
  Design Notes: `.untagged` is reserved for figures whose source is no longer available.
- `.untagged` is a first-class value, never `nil` and never absent. Reading a historical
  record that predates tagging must yield it explicitly.
- `Acc2 - Acc1` is emitted as its own named field and its own printed column, computable
  **per band and per genre**, not only in aggregate.
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

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Declared version present | OA300 fixture, which carries JAMS metadata per entry | Resolves to the declared version; every downstream figure carries it | No error expected |
| No declared version | GiantSteps ground truth, a flat array with no version field anywhere | Resolves to a **content-digest** tag over the truth file, which is still distinguishing. NOT `.untagged` -- the file is present, so its identity is knowable | No error expected |
| Two annotation sets, same corpus | The same corpus re-annotated, so byte content differs | The two resolve to different tags and are therefore comparable-as-different | No error expected |
| Historical artifact read | A committed perf-baseline record at the previous `schemaVersion`, written before this story | Reads successfully and surfaces `.untagged`; the cross-run delta line still works | Rejecting it would silently kill the delta; reject only on unknown-and-unsupported |
| Current artifact read | A record at the bumped `schemaVersion` | Reads its recorded version verbatim | Malformed version string is a decode failure, not a silent `untagged` |
| Octave proxy, aggregate | acc1 = 58, acc2 = 74, total = 82 | `octaveErrorProxy == 16`, emitted as a named field and a column | No error expected |
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
  single choke point where every benchmark acquires ground truth. Version resolution lands
  here so the ~20 emit sites inherit it.
- `Sources/BoomBoomBoomKitTestSupport/GenreAccuracyReporter.swift` -- `GenreBucket:19-56`
  (closed 4-field struct, `precondition(acc1Correct <= acc2Correct):48`), `format:99`,
  header `:113-115`, `renderRow:148-165`, `minSampleSize:5`. The per-band surface FR-61's
  success metric needs. Adding a column touches struct, header, row renderer, and goldens.
- `Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift` -- `mirexHit:327`
  (the `tempo2` fallback, doc-commented today with the 361/71 finding), headline emit
  `:54-61`, genre pass `:209-245`.
- `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift` -- headline emit
  `:70-76`, genre pass `:712-742`.
- `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift` -- `schemaVersion`
  written `:720`, **reader rejects != 2 at `:211`**, `AccuracySnapshot:696-704`,
  `BaselineRecord.accuracy:743`, GiantSteps hit helper `:684-692`. The only persisted
  accuracy artifact with a version field and a back-compat reader, so it is where the
  `untagged` path is genuinely exercised.
- `Tests/BoomBoomBoomKitBenchmarkTests/TempoRangeImpactTests.swift` -- `InputProvenance:616`
  (basename + SHA-256, landed 2026-08-06). The existing precedent to generalize, and the
  only artifact today that records anything about which truth file it read.
- `Tests/BoomBoomBoomKitTests/GenreAccuracyReporterTests.swift` -- golden strings that move
  when the column is added.
- `_bmad-output/implementation-artifacts/deferred-work.md` -- the 2026-08-06 entry
  recommending octave-strict scoring alongside floor-compatible on GiantSteps. This story
  makes the strict number available; whether it becomes enforced is noted there, not here.

**Duplication this story removes.** The `tempo2`-fallback MIREX hit is reimplemented four
times, identically: `GiantStepsBenchmarkTests.swift:346-357`,
`OctaveThresholdSweepTests.swift:296-306`, `PerformanceBenchmarkTests.swift:684-692`,
`TempoRangeImpactTests.swift:905-930`. No shared helper computes Acc1 and Acc2 together;
every suite reimplements the same pairing by hand.

## Tasks & Acceptance

**Execution:**

- [ ] `Sources/BoomBoomBoomKitTestSupport/AnnotationVersion.swift` -- NEW. An open
  identifier (`Sendable`, `Hashable`, `Codable`, `CustomStringConvertible`) wrapping a
  string, with `.untagged` as a named static. Open because Story 12.6 must mint one; a
  closed enum would have to be reopened by that story. Provides the two-rule resolution:
  a declared version when the source carries one, else a content digest over the source
  bytes, reusing the `InputProvenance` digest approach already in the repository. Do not
  enumerate corpus-specific statics beyond what a resolution rule needs; a per-corpus
  static list is the closed-enum failure mode wearing different clothes.
- [ ] `Sources/BoomBoomBoomKitTestSupport/AccuracyTally.swift` -- NEW. `acc1`, `acc2`,
  `total`, `annotationVersion`, and `octaveErrorProxy` as a computed `acc2 - acc1`.
  Construction rejects `acc1 > acc2`. Carries the shared MIREX hit that returns the
  octave-strict and floor-compatible verdicts as distinct values, so the four duplicate
  implementations collapse to one and FR-61's proxy is meaningful on GiantSteps rather than
  pre-absorbed by the `tempo2` acceptance.
- [ ] `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift` -- resolve an
  `AnnotationVersion` at load for each corpus and expose it on the loaded result. OA300 and
  the DAW oracle read their declared JAMS metadata; GiantSteps declares nothing, so it takes
  the content-digest branch and still gets a distinguishing tag. Existing call sites keep
  compiling.
- [ ] `Sources/BoomBoomBoomKitTestSupport/GenreAccuracyReporter.swift` -- add the
  `Acc2-Acc1` column and surface the annotation version in the header, so the per-band
  reading FR-61's success metric depends on is available without hand subtraction.
- [ ] `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift` -- bump the
  persisted schema and record the annotation version per corpus. **The reader must accept
  the previous schema and surface `untagged` for it**; rejecting it kills the cross-run
  delta line against every committed baseline.
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

## Review Triage Log

## Design Notes

**The story's own AC contradicts itself, and the contradiction is resolvable from the
text.** `epics.md:2127-2129` reads "`Sources/` is byte-identical; changes are confined to
the benchmark and **test-support** surface." But `BoomBoomBoomKitTestSupport` **is** a
target under `Sources/`, so the two clauses cannot both hold literally. Three pieces of
text resolve it toward the shipping-library reading:

1. The same sentence names the test-support surface as permitted, so it cannot be the thing
   held byte-identical.
2. NFR-11 states the hard contract as "DSP-only output remains byte-identical", which is
   the two shipping library targets, not the fixture target.
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
digest over the truth file distinguishes any two annotation sets deterministically, needs no
cooperation from the upstream dataset, and is already the precedent this repository set
today in `InputProvenance`. It also degrades correctly: OA300 declares JAMS metadata, so it
gets a declared tag, and the digest is the fallback rather than the rule.

That leaves `.untagged` meaning exactly what FR-60 wants it to mean and nothing else: a
**historical figure whose source is no longer determinable**, such as a persisted baseline
written before this story. It is not a synonym for "this corpus is undocumented". Keeping
those two cases distinct is the difference between a tag that carries information and one
that merely records our ignorance.

**Why version resolution belongs at the loader.** There are roughly twenty sites that emit
an Acc1/Acc2 figure and eleven JSON schemas that persist one. Attaching the version at each
emit site is twenty chances to forget. `CorpusTracks.loadCorpus` is the single choke point
every one of them already passes through, so resolving there makes the tag free downstream
and makes a missing tag a loader bug rather than a per-site oversight.

**Why the strict-versus-floor split is FR-61's problem and not scope creep.** On GiantSteps
the committed metric scores a hit against `bpm` **or** `tempo2`, and 361 of 661 rows carry a
second annotation within tolerance of an octave relation, of which 71 are realized on a
default-configuration baseline. `Acc2 - Acc1` on that metric is therefore partly
pre-absorbed: the metric has already forgiven some of the octave error the proxy exists to
measure. Emitting the proxy against the floor metric alone would be a misleading number, so
the shared helper returns both verdicts.

**Scope boundary, stated so the reviewer can attack it.** FR-60 says "every reported
accuracy figure". This story builds the vocabulary and adopts it at the surfaces where
figures are **persisted or gated**, which is where the story's own "so that" clause bites:
a number is compared across corpora and dates only if it was written down. Exploratory
stdout-only sweeps inherit the vocabulary through the loader but are not converted here.

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
