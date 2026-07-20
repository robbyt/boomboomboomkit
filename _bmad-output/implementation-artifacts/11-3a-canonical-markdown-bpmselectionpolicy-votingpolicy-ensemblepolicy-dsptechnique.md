# Story 11.3a: Author canonical Markdown for BPMSelectionPolicy + VotingPolicy + EnsemblePolicy + DSPTechnique (24 files)

Status: done

<!-- bmad-dev-auto metadata -->
<!-- baseline_revision: create-story v1 (2026-07-16) -->
<!-- review_loop_iteration: 0 -->
<!-- finalized: 2026-07-16 — Codex review (thread 019f6d38) + xcode semantic-docs cross-check (AttributedString inline-only confirmed) + party-mode ratification folded in (see Finalization Log at end) -->

> **Finalized 2026-07-16** via Codex review + an Apple-docs cross-check + party-mode. Codex's review was on-point and fully ratified (no dismissals). Headline changes vs the create-story draft: (FIN-1) **11.3a now ships its own story-local STRUCTURAL VALIDATOR** over its 24 files (front-matter/three-bold-lead/word-count/size/banned-markup/exact-case-filename) — without it, malformed docs ship green because `.docs` is a total function and Story 11.4's cross-type validator is a later, dependent story; (FIN-2) **`make new-case` is backed by a stdlib `scripts/new-case.py`** (uv-run, develop-only) with lexical Swift-identifier validation of `TYPE`/`CASE` to block path-escape — NOT source-roster validation (fail-late per Paige #5) — chosen over fragile BSD/GNU shell per the repo's Makefile-fragility history; (FIN-3) the scaffolder smoke uses a `_`-prefixed throwaway so it can't break the 24-count; (FIN-6) **DD-4/DD-6 corrected** — inline-only markdown RETAINS block markup as literal unattributed text (confirmed against Apple docs), it does not reject it, and the accessor has no `_`-skip (only the shell count excludes `_`). See Finalization Log.

## Story

As a **library author shipping per-case prose for the ensemble-and-selection types**,
I want **every case of `BPMSelectionPolicy` (8), `VotingPolicy` (3), `EnsemblePolicy` (5), and `DSPTechnique` (8) to have a 200-400 word Markdown file with consistent structure, and those four enums to conform to `DocumentedCase`**,
so that **the ensemble-decision API surface — the most consumer-visible documented family — ships first with authored prose, and Xcode autocomplete + the demo's strategy popovers surface uniform high-signal guidance for these 24 cases.**

This story is **additive and main-bound**: it adds 24 resource files, three tooling files, and a one-line-per-enum `DocumentedCase` conformance. `Sources/` behavior is byte-identical except for the four enums gaining a protocol conformance (no stored state, no case changes). No test in `Tests/` changes runtime behavior; new tests only assert docs resolve. The corpus floors are untouched (no DSP path changes).

## Key Design Decisions

> The DD block is the surface the pre-implementation Codex review + xcode-mcp cross-check + party-mode finalize walk first.

**DD-1 — Conformance is protocol-only; no case or storage changes.** The four enums gain `DocumentedCase` in their conformance list plus `static let documentedKind = "<TypeName>"`. `BPMSelectionPolicy`, `VotingPolicy`, `DSPTechnique` are `String`-raw, so `documentationID` comes free from the constrained extension (`= rawValue`); the filename stem is therefore the exact case identifier (`maxConfidence.md`, `acfSharpening.md`). No behavior changes — the conformance only adds a computed `docs` accessor.

**DD-2 — `EnsemblePolicy` hand-writes `documentationID` via its existing `stableKey`.** `EnsemblePolicy` carries an associated value (`.weightedVoting(SignalWeights)`), so it is not `RawRepresentable` and cannot inherit the free `documentationID`. It already ships a `public var stableKey: String` returning `"default" / "dspOnly" / "mlOnly" / "highestConfidence" / "weightedVoting"` (payload-ignoring). Add `public var documentationID: String { stableKey }` — a single source, already payload-agnostic, so `weightedVoting.md` (NOT `weightedVoting_SignalWeights.md`) resolves for every `SignalWeights` value. The unconstrained `docs` default is inherited unchanged. `documentedKind = "EnsemblePolicy"`.

**DD-3 — Front-matter schema per KDD-E7.** Every file opens with a `---`-delimited YAML block carrying `id:` (EXACTLY the Swift case identifier — `maxConfidence`, not `max-confidence`), `title:` (a human-readable phrase), and — only for cases with an associated value — `payload:` naming the associated type. In 11.3a the only payload-bearing case is `EnsemblePolicy.weightedVoting` → `payload: SignalWeights`. The accessor (`BoomBoomBoomKitDocs.strippingFrontMatter`) strips this block before `AttributedString(markdown:)`, so it never renders; it is validator/tooling input (Story 11.4). The block MUST be terminated (a second `---`) or the accessor renders the whole file.

**DD-4 — Body: exactly three bold-lead paragraphs, failure-mode mandatory (KDD-E8 + Paige #3 Option A). [CORRECTED]** After the front-matter, the body is exactly three paragraphs, each led by `**What it does.**`, `**When to pick it.**`, `**Tradeoff.**`, in that order, nothing before/after/between. Total prose 200-400 words; file ≤ 10 KB. The **Tradeoff paragraph MUST contain at least one concrete failure-mode sentence** — a named scenario where the case produces a wrong or degraded result (e.g. "fails on DnB tracks where octave-doubled candidates self-report higher confidence than the fundamental"). Inline markup is limited to `**bold**` and `_italic_`; NO code fences, tables, images, headings, or DocC `` ``symbol`` `` links. **Correction (Codex + Apple-docs cross-check):** `.inlineOnlyPreservingWhitespace` does NOT reject banned block markup — per Apple's `interpretedSyntax` docs ("the parser still parses it and includes its text in the final result. However, the relevant text won't have attributes") a heading/table/fence is retained as literal, unattributed text, so it renders ugly but still resolves non-fallback. The ban is therefore enforced by the STRUCTURAL VALIDATOR (DD-9, this story) and later Story 11.4 — never by the parser.

**DD-5 — Prose is grounded in the in-source doc-comments, not invented.** Each enum's existing `///` doc-comments + the CLAUDE.md Key-Types roster are the authoritative semantic source. Authors paraphrase real behavior (e.g. BPMSelectionPolicy's 2%-cluster math, DSPTechnique's measured OA300 impact deltas, EnsemblePolicy's `.dspOnly` byte-identity contract). Do NOT introduce claims absent from source. The failure-mode sentences must describe genuine, technically-correct failure conditions (octave doubling, outlier windows, tag-bias toward DSP, limiter-flattened transients), not fabricated ones.

**DD-6 — Scaffolder ships beside the prose (Paige #5, fail-late). [CORRECTED → see DD-10 for the implementation.]** Add `Sources/BoomBoomBoomKit/Resources/Documentation/_template.md` (three-bold-lead skeleton with `{{TYPE}}`/`{{CASE}}` placeholders + a front-matter stub) and a `make new-case TYPE=… CASE=…` target that materializes `Documentation/<TYPE>/<CASE>.md` from the template, substituting placeholders and refusing to overwrite an existing file. The scaffolder does NOT validate `TYPE`/`CASE` against the Swift case roster (that is Story 11.4's fail-late job) — but it MUST lexically validate that each is a Swift identifier (`^[A-Za-z_][A-Za-z0-9_]*$`) to block path-escape (`/`, `..`, whitespace, shell metacharacters). `_template.md` is `_`-prefixed so the 49-file shell count (`grep -v '/_'`) ignores it. **Correction (Codex):** the accessor itself has NO `_`-skip — it is a direct `Bundle.module` lookup, and the `_Fixture/` sentinel tests deliberately resolve `_`-prefixed resources; only the shell COUNT excludes `_`. `_template` is simply never referenced as a case `documentationID`, so it is never resolved regardless.

**DD-10 — `new-case` is a stdlib Python script, not shell (repo-fragility precedent). [FINALIZED]** Implement the scaffolder as `scripts/new-case.py` (stdlib-only, invoked `uv run scripts/new-case.py <TYPE> <CASE>`); `make new-case` shells to it. Rationale: Codex flagged the BSD/GNU `sed -i` split, `&`/`\`/delimiter escaping in substitution, `cp -n` silent-skip vs error, `mktemp` portability, and partial-file-on-failure — the exact fragility class the repo already extracted `demo-bump-build.py` to escape. The Python form: (a) lexically validates `TYPE`/`CASE` are Swift identifiers (rejects path-escape) BUT does not check the Swift source roster; (b) reads `Resources/Documentation/_template.md`, substitutes `{{TYPE}}`/`{{CASE}}`; (c) creates the parent dir and opens the target with exclusive-create mode (`'x'`) so an existing file is a hard error with a non-zero exit and no clobber — atomic, no partial write. `scripts/` is develop-only, so `make new-case` fails loudly on a main-only checkout (the ml-* convention; consumers don't scaffold this library's own docs). Uses `uv run` per project convention.

**DD-11 — Story-local structural validator (closes the "ships green" gap). [FINALIZED]** Because `BoomBoomBoomKitDocs.attributedString` is a TOTAL function (a missing/malformed file silently returns a fallback, and inline-only retains banned markup as literal text — DD-4), a green build + a non-fallback assertion do NOT prove the 24 files satisfy the authoring contract. Story 11.4 builds the authoritative cross-type drift+rule validator, but it is a LATER story that depends on 11.3a+11.3b already existing — it cannot gate 11.3a retroactively. Therefore 11.3a ships a focused structural test (`DocumentedCaseAuthoredDocsTests` or similar) over ITS OWN 24 files enforcing DD-9's algorithm. This is complementary to (not a duplicate of) 11.4: 11.4 generalizes across every `DocumentedCase` type + adds the exhaustive-`allCases` drift switch; 11.3a's guard is scoped to the four types authored here so malformed prose can't land mid-epic. AC 5's original "non-fallback proves stripped correctly" claim is RETRACTED (an unterminated front-matter block resolves non-fallback yet renders the metadata) — the strip is proven instead by asserting the rendered body contains none of the front-matter key tokens.

**DD-7 — `Resources/README.md` documents the format restriction.** Add `Sources/BoomBoomBoomKit/Resources/README.md` stating the no-tables/no-code/no-images/no-DocC-links rule and pointing to `BoomBoomBoomKit.docc/Articles/SelectionStrategies.md` (authored in Story 11.5) as the place for richer treatments. It is excluded from the 49-count by the `grep -v '/_'`… wait — README.md is NOT `_`-prefixed; the count command is scoped to `Resources/Documentation/` and `README.md` lives at `Resources/README.md` (one level up), so it is outside the counted tree. Keep it at `Resources/README.md`, not under `Documentation/`.

**DD-8 — Pressure-release valve (KDD-E8).** If a case genuinely needs a table/code sample to be clear, the per-case `.md` stays plain-prose and the richer treatment goes in the Story 11.5 DocC article; record any such deviation in `_bmad-output/implementation-artifacts/11-3a-pressure-release.md`. Expectation: none of the 24 cases needs this — all are explainable in prose.

**DD-9 — Structural-validator algorithm (pins the fuzzy contract terms Codex flagged). [FINALIZED]** The DD-11 test applies this exact, deterministic algorithm to each of the 24 files (and is the reference 11.4 will generalize):
- **Front-matter:** file byte-0 is a line whose trimmed content is `---`; a second `---` line closes it; the block parses as `key: value` lines containing at least `id` and `title`; `id` equals the filename stem (exact, case-sensitive) AND equals a real `documentationID` of the parent-directory type; `payload` (if present) is a Swift-type-identifier token. An unterminated block is a FAILURE (not silently tolerated as the accessor does).
- **Body extraction:** everything after the closing `---`. Split into paragraphs = maximal runs of non-blank lines separated by ≥1 blank line. Require exactly 3 paragraphs.
- **Bold leads:** paragraph 1 starts with `**What it does.**`, 2 with `**When to pick it.**`, 3 with `**Tradeoff.**` (exact literal prefixes, in order).
- **Word count:** whitespace-split token count over the concatenated three-paragraph body text (bold-lead words included, `**`/`_` markers not counted as separate tokens). Require `200 ≤ n ≤ 400`.
- **Size:** on-disk file ≤ 10240 bytes.
- **Banned markup (line scan over the body):** reject a line matching `^\s{0,3}#` (ATX heading), a line containing a ``` code fence, a line with ≥2 unescaped `|` (table), `![` (image), `<doc:` or a `` `` ``-delimited DocC symbol link. (Inline `` `code` `` single backticks are also disallowed to stay conservative.)
- **Failure-mode proxy (Tradeoff paragraph):** must contain ≥1 token from a failure lexicon (`fail`, `fails`, `failing`, `mis`, `wrong`, `degrad`, `break`, `breaks`, `regress`, `confus`, `collaps`, `spurious`, `false`, `drift`, `overcount`, `undercount`). This is an ADVISORY-STRICT proxy — the test asserts it, but the substantive "is this a real, correct failure mode?" judgment is the reviewer's (recorded, not automated).
- **Filename exact-case lock:** enumerate the real on-disk `*.md` files under `Resources/Documentation/<Type>/`; assert the set of stems equals the type's `documentationID` set with case-sensitive string equality (catches a `MaxConfidence.md` typo that APFS case-insensitivity would otherwise mask).
- **Strip proof:** the rendered `AttributedString` body contains none of the literal tokens `id:`, `title:`, `payload:`, or `---` (proves the front-matter was stripped, replacing the retracted AC-5 claim).

## Acceptance Criteria

1. **24 files exist, one per case.** `Sources/BoomBoomBoomKit/Resources/Documentation/<Type>/<case>.md` exists for every case across exactly 24 files: `BPMSelectionPolicy/` (8: maxConfidence, dedup, quorum, average, median, weightedAverage, union, windowVoting), `VotingPolicy/` (3: simpleMajority, confidenceWeighted, thresholdGated), `EnsemblePolicy/` (5: default, dspOnly, mlOnly, highestConfidence, weightedVoting), `DSPTechnique/` (8: acfSharpening, adaptiveThreshold, subBandNormalization, expandedCandidates, fineGridRefinement, subBandVoting, clickTrackCorrelation, superFluxOnset). Filenames match the Swift case identifier 1:1 (`weightedVoting.md`, not `weightedVoting_SignalWeights.md`). (DD-1, DD-2, DD-3)

2. **Three-bold-lead body, failure-mode mandatory.** Every file's body is exactly three paragraphs led by `**What it does.**`, `**When to pick it.**`, `**Tradeoff.**` in that order; total prose 200-400 words; file ≤ 10 KB; the Tradeoff paragraph contains ≥1 concrete failure-mode sentence; inline markup limited to `**bold**`/`_italic_` (no code/tables/images/headings/DocC links). (DD-4, DD-5)

3. **Front-matter well-formed.** Each file opens with a terminated `---` YAML block containing `id:` == the case identifier == the filename stem, a human-readable `title:`, and `payload: SignalWeights` for `EnsemblePolicy/weightedVoting.md` only. The stripped body still parses non-empty through `AttributedString(markdown:, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))`. (DD-3)

4. **Four enums conform to `DocumentedCase`.** `BPMSelectionPolicy`, `VotingPolicy`, `DSPTechnique` add `DocumentedCase` to their conformance list + `static let documentedKind = "<TypeName>"` (documentationID free from rawValue). `EnsemblePolicy` adds `DocumentedCase` + `documentedKind` + `public var documentationID: String { stableKey }`. Unit-test-locked: for each type, `allCases.map(\.documentationID)` (or `allPolicies.map(\.documentationID)` for EnsemblePolicy) equals the exact expected stem list, and every case's `.docs` returns a non-fallback (authored) `AttributedString`. (DD-1, DD-2)

5. **`.docs` returns authored prose, not fallback, for all 24 cases.** A test asserts `case.docs` for every case across the four types is non-empty AND does not equal the `"Documentation unavailable for <kind>.<id>."` fallback — this proves the resource RESOLVED. (It does NOT by itself prove correct stripping/structure — that is AC 9. The original "proves stripped correctly" claim is retracted: an unterminated front-matter block also resolves non-fallback.) (DD-1, DD-2, DD-3, DD-11)

6. **Scaffolder + template ship.** `Sources/BoomBoomBoomKit/Resources/Documentation/_template.md` exists (front-matter stub + three bold leads + `{{TYPE}}`/`{{CASE}}` placeholders). `make new-case TYPE=<T> CASE=<c>` (backed by `scripts/new-case.py`, DD-10) creates `Documentation/<T>/<c>.md` from the template with substitutions, and refuses (non-zero exit, no clobber, no partial write) when the target exists. It does NOT validate TYPE/CASE against the Swift case roster, but DOES reject a TYPE/CASE that is not a Swift identifier (`^[A-Za-z_][A-Za-z0-9_]*$`) with a non-zero exit (path-escape guard). The scaffolder smoke uses a `_`-prefixed throwaway (`TYPE=_ScaffoldSmoke CASE=probe`) and removes it, so a stray run cannot perturb the 24-file count. (DD-6, DD-10)

7. **Format-restriction README.** `Sources/BoomBoomBoomKit/Resources/README.md` documents the inline-only restriction and points to the Story 11.5 DocC article for tables/code. (DD-7)

8. **Gates green.** `make build`, `make test` (the `BoomBoomBoomKitTests` unit suites — the benchmark target is env-gated and out of scope for this doc-only story), `make fmt` clean, `make lint` 0-serious, `make demo-build` succeed. After this story, `find Sources/BoomBoomBoomKit/Resources/Documentation -type f -name "*.md" | grep -v '/_' | wc -l` returns 24 (the full 49 arrives with 11.3b); the `_template.md`, `_Fixture/` sentinels, and `AnalysisIntensity/.gitkeep` are all excluded by `grep -v '/_'` (or by not being `*.md`). (all DDs)

9. **Story-local structural validator passes over all 24 files.** A test suite applies the DD-9 algorithm to every authored file: front-matter terminated + `id`/`title` present + `id` == stem == a real case; exactly three ordered bold-lead paragraphs; 200-400 body words; ≤10 KB; no banned block markup; Tradeoff failure-mode lexicon proxy; filename exact-case lock (on-disk stems == the type's `documentationID` set, case-sensitive); and the rendered body contains none of `id:`/`title:`/`payload:`/`---` (strip proof). A failure names both the offending file and the violated rule. (DD-9, DD-11)

## Tasks / Subtasks

- [x] **Task 1 — Conform the four enums to `DocumentedCase`.** (AC 4)
  - [x] `BPMSelectionPolicy.swift`: add `DocumentedCase` to the conformance list; add `public static let documentedKind = "BPMSelectionPolicy"`.
  - [x] `VotingPolicy.swift`: add `DocumentedCase`; `public static let documentedKind = "VotingPolicy"`.
  - [x] `DSPTechnique.swift`: add `DocumentedCase` to the `enum DSPTechnique` line ONLY (NOT `TechniqueSet`); `public static let documentedKind = "DSPTechnique"`.
  - [x] `EnsemblePolicy.swift`: add `DocumentedCase`; `public static let documentedKind = "EnsemblePolicy"`; `public var documentationID: String { stableKey }`.
  - [x] All witnesses are explicitly `public` (matches the `AnalysisIntensity.documentedKind` precedent). `make build` compiles.
- [x] **Task 2 — Author the 8 `BPMSelectionPolicy` doc files.** (AC 1, 2, 3, 5) Source: the `///` comments in `BPMSelectionPolicy.swift` (2%-cluster math, per-strategy scoring) + CLAUDE.md roster. Failure-mode examples: maxConfidence → octave-doubled candidate self-reports higher confidence; median → resistant to outliers but needs ≥3 windows to matter; windowVoting → falls back to maxConfidence with no consensus.
- [x] **Task 3 — Author the 3 `VotingPolicy` doc files.** (AC 1, 2, 3, 5) Source: `VotingPolicy.swift` comments. thresholdGated payload note: threshold lives on `Options.votingThreshold`, not a case payload.
- [x] **Task 4 — Author the 5 `EnsemblePolicy` doc files.** (AC 1, 2, 3, 5) `weightedVoting.md` carries `payload: SignalWeights`. Cover the `.dspOnly` byte-identity + default-Options nuance (Options still defaults to `.dspOnly`, not `.default`).
- [x] **Task 5 — Author the 8 `DSPTechnique` doc files.** (AC 1, 2, 3, 5, 9) Source: the measured OA300 impact deltas in `DSPTechnique.swift` comments. superFluxOnset → cite the Branch-B inert-ship outcome (regresses Acc1 by 4 tracks on top of `.optimal`). **`clickTrackCorrelation`: its own case comment says "Impact: TBD" — ground the prose in the `TechniqueSet.clickAugmented` doc-comment instead (ties `.optimal` Acc1 55/82, +1 Acc2 68/82 vs 67/82), which is the authoritative measured artifact.** (Codex FIN-7)
- [x] **Task 6 — Scaffolder + template + README.** (AC 6, 7) `_template.md` (front-matter stub + three bold leads + `{{TYPE}}`/`{{CASE}}`); `scripts/new-case.py` (stdlib, Swift-identifier lexical validation, exclusive-create no-clobber, placeholder substitution — DD-10); `make new-case` target shelling to `uv run scripts/new-case.py`; `Resources/README.md`. Add `scripts/new-case.py` to the `py-lint` ruff/ty scope in the Makefile if the lint target enumerates files.
- [x] **Task 7 — Tests.** (AC 4, 5, 9) Add a `@Suite` (e.g. `DocumentedCaseAuthoredDocsTests`) with: (a) parameterized `@Test`s over each type's cases asserting `.docs` is non-empty and ≠ fallback; (b) `documentationID` stem-list equality per type; (c) the DD-9 STRUCTURAL VALIDATOR over the 24 on-disk files (front-matter, three-bold-lead, word count, size, banned markup, failure-mode proxy, filename exact-case lock, strip proof). Confirm the existing 11.1 accessor tests still pass. Tests read the files from `Bundle.module` and/or the source tree — resolve the on-disk path via `#filePath`-relative navigation or `Bundle.module.urls(forResourcesWithExtension:subdirectory:)`.
- [x] **Task 8 — Gates.** `make fmt`, `make build`, `make test`, `make lint` (incl. `py-lint` for the new script), `make demo-build`. Confirm `find … | grep -v '/_' | wc -l == 24`.

## Dev Notes

### Authoritative doc contract (KDD-E7 + KDD-E8 + Paige)

File shape (verbatim template intent):
```
---
id: <exactCaseIdentifier>
title: <Human Readable Phrase>
payload: <AssociatedType>   # ONLY for cases with an associated value
---
**What it does.** <paragraph>

**When to pick it.** <paragraph>

**Tradeoff.** <paragraph including >=1 concrete failure-mode sentence>
```
- Prose 200-400 words (front-matter excluded from the count); file ≤ 10 KB.
- Inline `**bold**` / `_italic_` only. No fenced code, tables, images, headings, DocC symbol links.
- `id` == filename stem == Swift case identifier, exactly.
- Front-matter block MUST be terminated with a second `---`.

### Conformance mechanics (from `DocumentedCase.swift` + `BoomBoomBoomKitDocs.swift`)

- `DocumentedCase: Sendable` requires `static var documentedKind: String`, `var documentationID: String`, `var docs: AttributedString`.
- String-raw enums: `documentationID` supplied by the constrained extension (`where Self: RawRepresentable, RawValue == String`). Just declare conformance + `documentedKind`.
- Associated-value enums (`EnsemblePolicy`): hand-write `documentationID`; inherit `docs` from the unconstrained extension. Use the existing `stableKey`.
- The accessor resolves `Bundle.module/Documentation/<documentedKind>/<documentationID>.md`, strips front-matter, parses inline-only, and returns an informative fallback string on any miss. `.docs` non-fallback ⇒ the resource resolved.
- The resource tree already ships via `Package.swift` `.copy("Resources/Documentation")` (Story 11.1). New `<Type>/` subdirectories are picked up automatically by `.copy` (preserves subdir structure). No `Package.swift` edit needed. VERIFY this during dev (a missing copy manifests as universal fallback).

### Exact case rosters (order = source declaration order)

- **BPMSelectionPolicy** (String-raw): maxConfidence, dedup, quorum, average, median, weightedAverage, union, windowVoting.
- **VotingPolicy** (String-raw): simpleMajority, confidenceWeighted, thresholdGated.
- **EnsemblePolicy** (assoc-value; `allPolicies` order): default, dspOnly, mlOnly, highestConfidence, weightedVoting(SignalWeights).
- **DSPTechnique** (String-raw): acfSharpening, adaptiveThreshold, subBandNormalization, expandedCandidates, fineGridRefinement, subBandVoting, clickTrackCorrelation, superFluxOnset.

### Continuity from Story 11.2 (done)

11.2 conformed `AnalysisIntensity` (String-raw) to `DocumentedCase` with `documentedKind = "AnalysisIntensity"` and reserved `Documentation/AnalysisIntensity/.gitkeep` (prose in 11.3b). The same free-documentationID pattern applies to the three String-raw enums here. 11.2's docs smoke test (`.docs` non-empty per case) is the precedent for AC 5's test shape.

### Out of scope

- Prose for the 11.3b types (AnalysisIntensity, OctaveEquivalencePolicy, MLExecutionPolicy, DownbeatResult, AbstainReason, DemotionReason).
- Story 11.4's `DocumentationValidatorTests` (drift + rule validator) — AC 5's tests here are conformance smoke tests, not the full validator.
- The DocC catalog / `SelectionStrategies.md` article (Story 11.5).

## File List

_Final (dev-story close 2026-07-16):_
- NEW `Resources/Documentation/BPMSelectionPolicy/{maxConfidence,dedup,quorum,average,median,weightedAverage,union,windowVoting}.md` (8)
- NEW `Resources/Documentation/VotingPolicy/{simpleMajority,confidenceWeighted,thresholdGated}.md` (3)
- NEW `Resources/Documentation/EnsemblePolicy/{default,dspOnly,mlOnly,highestConfidence,weightedVoting}.md` (5)
- NEW `Resources/Documentation/DSPTechnique/{acfSharpening,adaptiveThreshold,subBandNormalization,expandedCandidates,fineGridRefinement,subBandVoting,clickTrackCorrelation,superFluxOnset}.md` (8)
- NEW `Resources/Documentation/_template.md`, `Resources/README.md`
- EDIT `BPMSelectionPolicy.swift`, `VotingPolicy.swift`, `DSPTechnique.swift`, `EnsemblePolicy.swift` (conformance)
- EDIT `Makefile` (`new-case` target + `new-case.py` added to `py-lint` ty scope)
- NEW `scripts/new-case.py` (stdlib scaffolder, DD-10)
- EDIT `Package.swift` (exclude `Resources/README.md` so the non-bundled contributor readme does not trip an SPM unhandled-file warning)
- NEW `Tests/BoomBoomBoomKitTests/DocumentedCaseAuthoredDocsTests.swift` (conformance + `.docs` + DD-9 structural validator, 13 tests)

## Dev Agent Record

### Completion Notes (2026-07-16)

- **All 8 tasks complete; all 9 ACs satisfied.** 24 authored files + 4 conformances + scaffolder + README + tests.
- **Contract-compliance fix during dev:** the first-draft prose used inline-code backticks for identifiers, which the authoring rule bans (`**bold**` / `_italic_` inline only). Converted all inline `` `x` `` → `_x_` across the 24 files + `_template.md` (README keeps backticks — it is a GitHub readme, not validated/bundled). The DD-9 validator now bans backticks, so files and validator agree.
- **Package.swift:** added `exclude: ["Resources/README.md"]` — `Resources/README.md` sits outside the `.copy("Resources/Documentation")` tree, so without the exclude SPM warns about an unhandled file. The file stays on disk (read by 11.4 from the source tree), just not bundled.
- **Gates (macOS):** `make build` clean · `make test` **868 tests / 141 suites** green (was 855/140; +13 from `DocumentedCaseAuthoredDocsTests`) · `make fmt` no churn · `make lint` **5 violations, 0 serious** (all pre-existing Demo; `py-lint` ruff+ty clean incl. `new-case.py`) · `make demo-build` BUILD SUCCEEDED · 24-file count confirmed · scaffolder smoke (create / no-clobber / path-escape-reject) verified.
- **Word counts** 233-270 (target 200-400); **file sizes** ~1.5-1.8 KB (ceiling 10 KB).
- **Out of scope, confirmed deferred:** the 11.3b types; Story 11.4's cross-type validator (this suite is story-local); the Story 11.5 DocC article. No `11-3a-pressure-release.md` needed — every case was explainable in plain prose.
- **Note carried to 11-3b:** the epic-context sweep found `DownbeatResult.detected` is `detected(estimate: DownbeatEstimate)` in source, not the epic's `detected([BeatTimestamp])` — author the `payload:` against the real type and reconcile the epic text.

## Code Review (2026-07-16)

Three-layer adversarial review: a **Codex blind-hunter** (codex:consult, thread 019f6d51), an **Acceptance Auditor**, and an **Edge-Case Hunter**. Outcome: **clean-after-patches → done**. The auditor confirmed no false-completion (the `.docs`-resolve tests genuinely iterate all 24 cases; the validator genuinely runs all 24 files) and all quantitative DSP/ensemble prose matched source. Patches applied:

- **Content (2 real defects):** `simpleMajority.md` claimed an even 2-2 split falls back to `maxConfidence` — wrong; `pickLargestCluster` elects the higher-confidence cluster, fallback only when no cluster has ≥2 windows. Fixed. `confidenceWeighted.md` asserted an illusory singleton-loss failure (a winning singleton is also `maxConfidence`'s pick, so no wrong outcome) + muddled "2-versus-1 against three" phrasing. Rewrote both to a genuine failure mode.
- **Validator teeth (3 Codex blocking + should-fix — the story's whole point):** hardened `DocumentedCaseAuthoredDocsTests` to close false-negatives: failure lexicon now WORD-BOUNDARY matched (was substring — "close" contained "lose", "premise" contained "mis"); per-case `payload:` presence/absence enforced (exactly `EnsemblePolicy.weightedVoting` → `SignalWeights`, all others none); banned-markup scan extended to indented code, `~~~` fences, setext rules, blockquotes, ordered/unordered lists, and `](` links; colonless / duplicate front-matter keys rejected; CRLF tolerated (matches the accessor); strict filename set (catches `_oops.md` / `junk.MD` / case typos); each bold lead must appear exactly once and each paragraph carry ≥20 words; strip-proof now checks all four tokens (`---`/`id:`/`title:`/`payload:`) per AC 9.
- **Accepted-deferred (to Story 11.4):** the `payload` regex bracket-balance nit and content-blind heading/pipe false-positive potential on hypothetical future prose (no current-corpus impact); 11.4 owns the authoritative cross-type validator.
- **Re-gated:** `make build` clean · `make test` **868/141** · `make fmt` no churn · `make lint` 5/0-serious · `make demo-build` SUCCEEDED.

Pending operator: 1Password-signed commit + push to `rterhaar/11-3` (append to PR #97 changelog).

## Change Log

- 2026-07-16 — create-story draft (bmad-dev-auto, hybrid full-pipeline run for 11-3).
- 2026-07-16 — Finalized (Codex review + xcode semantic-docs cross-check + party-mode); status → ready-for-dev. See Finalization Log.
- 2026-07-16 — Implemented (dev-story): 24 docs + 4 conformances + scaffolder + validator. Code-review clean-after-patches (2 content fixes + validator hardening) → done.

## Finalization Log (2026-07-16)

Pipeline: create-story draft → **Codex adversarial spec review** (thread 019f6d38) → **xcode DocumentationSearch cross-check** (Apple `AttributedString` markdown parsing) → **party-mode ratification**. Codex's review was high-signal and fully ratified — nothing dismissed. Ratified changes:

- **FIN-1 (Codex blocking) — story-local structural validator added.** `.docs` is total (missing/malformed → silent fallback) and inline-only retains banned markup as literal text, so a green build proves nothing about authoring quality; Story 11.4's cross-type validator is a later dependent story. 11.3a now ships DD-11's structural test over its own 24 files. New AC 9; DD-9 pins the exact algorithm.
- **FIN-2 (Codex blocking) — AC 5's "proves stripped correctly" retracted.** An unterminated front-matter block resolves non-fallback. Strip is now proven by asserting the rendered body contains no front-matter tokens (DD-9 strip proof, AC 9).
- **FIN-3 (Codex blocking) — `new-case` path-escape closed.** Lexical Swift-identifier validation of `TYPE`/`CASE` (still NOT source-roster validation — fail-late per Paige #5). AC 6, DD-6, DD-10.
- **FIN-4 (Codex should-fix) — scaffolder de-fragilized.** Implemented as stdlib `scripts/new-case.py` via `uv run` (repo precedent: `demo-bump-build.py`), not BSD/GNU shell. Exclusive-create no-clobber, atomic. DD-10.
- **FIN-5 (Codex should-fix) — AC 6 vs AC 8 file-count conflict resolved.** Scaffolder smoke uses a `_`-prefixed throwaway + cleanup. AC 6.
- **FIN-6 (Codex should-fix + xcode cross-check) — DD-4/DD-6 corrected.** Apple docs confirm inline-only markdown includes excluded-syntax text unattributed (does not reject it); the accessor has no `_`-skip (only the shell count excludes `_`).
- **FIN-7 (Codex should-fix) — `clickTrackCorrelation` prose grounded in `TechniqueSet.clickAugmented`** (its own comment is "Impact: TBD"). Task 5.
- **FIN-8 (Codex should-fix) — all `DocumentedCase` witnesses explicitly `public`.** Task 1.
- **FIN-9 (Codex should-fix) — AC 8 `make test` scope corrected** to the `BoomBoomBoomKitTests` unit suites (benchmark target is env-gated, out of scope); count command clarified.
- **Confirmed sound (Codex):** the conformance design — three String-raw enums get free `documentationID`; `EnsemblePolicy.documentationID { stableKey }` is correct and non-conflicting; `SignalWeights` is `Sendable`; all four rosters/counts match source; the 24-file count command holds.
- **xcode semantic-docs cross-check:** `AttributedString.MarkdownParsingOptions.InterpretedSyntax.inlineOnlyPreservingWhitespace` — Apple: "the parser still parses it and includes its text in the final result. However, the relevant text won't have attributes." Confirms FIN-6.
