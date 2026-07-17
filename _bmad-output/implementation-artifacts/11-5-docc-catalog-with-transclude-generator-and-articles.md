---
title: 'Story 11.5: DocC catalog with transclude generator and articles'
type: 'feature'
created: '2026-07-17'
status: 'done'
baseline_revision: ca06957a2582d0163f15a61ba8862529a7bbb919
review_loop_iteration: 0
followup_review_recommended: true
context:
  - '{project-root}/CLAUDE.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-11-context.md'
warnings: [oversized]
---

<intent-contract>

## Intent

**Problem:** Epic 11's 49 canonical per-case `.md` docs surface only inline via `.docs`. DocC has no navigable reference site for them, and there is no narrative article surveying the selection-strategy and ensemble-preset families (which per-case docs are forbidden from doing — KDD-E8 bans tables/matrices in runtime docs).

**Approach:** Extend the existing `BoomBoomBoomKit.docc/` catalog with two hand-authored comparison articles + a curated landing page, plus a develop-only one-way generator (`make docc-transclude` → `scripts/docc-transclude.py`) that mirrors each canonical `.md` into a DocC symbol-extension page under a gitignored `Cases/` build artifact. No prose is duplicated by hand (NFR-5): the per-case source-of-truth stays in `Resources/Documentation/`.

## Boundaries & Constraints

**Always:**
- The transclude generator is **one-way**: `Resources/Documentation/<Type>/<case>.md` → `BoomBoomBoomKit.docc/Cases/<Type>-<stem>.md`. It reads, never writes, the canonical docs.
- Generator output naming is uniform `Cases/<Type>-<stem>.md` for ALL 49 files (NOT flat `<stem>.md` — two `sourceSpecific.md` files, `AbstainReason/` + `DemotionReason/`, collide under flat naming). DocC binds the page by the in-file symbol-link h1, so the filename only needs to be unique + deterministic.
- Each generated page: (a) strips the ENTIRE YAML front-matter block (all keys — `id`/`title`/optional `payload`; boundary = the closing `---`, not a fixed line count), (b) prepends a symbol-extension h1 `` # ``<Type>/<symbol>`` `` where `<symbol>` is the filename stem for value-only cases OR the signature-suffixed identifier for the five associated-value cases (see the ASSOC-VALUE SIGNATURE MAP in Design Notes — a bare stem fails DocC binding), (c) preserves the three-bold-lead body verbatim, byte-for-byte, with the source's single trailing newline. NEVER inject DocC symbol links into the body. Do NOT emit a `@Metadata { @PageKind(symbolExtension) }` block — `symbolExtension` is not a valid `@PageKind` argument (would warn/fail AC6); the h1 symbol link alone makes the page a symbol extension. (This reconciles the epic's Paige-#4 `@PageKind(symbolExtension)` prescription, which is not a real DocC directive.)
- Generator SKIPS `_`-prefixed filename stems AND `_`-prefixed directories (the `_Fixture/` sentinels, any `_template.md`, a future `_Foo/`) and never touches `Resources/README.md`. Deterministic (sorted) traversal. **Body is preserved byte-for-byte** (read/write bytes, NOT Python universal-newline mode). The canonical corpus is LF-only (11.4-validated), so byte-verbatim yields LF output; a CR or CRLF byte in an input body is treated as malformed input (fail nonzero) rather than silently normalized — byte-verbatim and forced-LF cannot both hold for CRLF, so reject it.
- Generator is **atomic + self-cleaning**: build the full output set into a temp dir, validate it (every eligible source has front-matter delimiters + valid UTF-8; no two inputs map to the same output path; `--output-dir` does NOT equal, contain, or sit inside `--docs-root` — reject any overlap so an ancestor output can't clobber source dirs), THEN replace `Cases/` wholesale so a renamed/removed case leaves no stale page. Swap mechanics (non-empty-dir-safe, portable): write into a sibling temp dir, rename the existing `Cases/` to a backup, rename temp → `Cases/`, delete the backup on success; on swap failure roll back from the backup. On ANY malformed input (missing opening/closing `---`, invalid UTF-8/CR/CRLF, duplicate output path, path overlap, unreadable file) it exits nonzero and leaves the existing `Cases/` untouched — never a partial update.
- Coverage is **roster-derived, not a magic number**: assert output count == number of eligible source files (every eligible `<Type>/<stem>.md` → exactly one page). 49 is today's value; the gate must not hardcode 49 as the only signal (a legitimate future case addition should not fail as an unexplained magic-number mismatch).
- `scripts/docc-transclude.py` is **stdlib-only**, `#!/usr/bin/env python3`, `from __future__ import annotations`, argparse, `REPO_ROOT = Path(__file__).resolve().parent.parent` — mirror `scripts/new-case.py`. Develop-only (lives in `scripts/`); NEVER shipped to main.
- The `make docc-transclude` target is a single `uv run scripts/docc-transclude.py` line (mirror `make new-case`); it ships in the Makefile and fails loudly on a main-only checkout (script absent) — the intentional `ml-*`/`new-case` convention.
- The two Articles + the landing page are under `Sources/` → they SHIP TO MAIN. Articles MAY use tables, code blocks, and DocC symbol links (KDD-E8 permits this in catalog articles).
- Every symbol/case named in the Articles must match LIVE SOURCE. Honesty flags are mandatory (see Design Notes): `EnsemblePolicy.default` case ≠ the `Options.ensemblePolicy` default (`.dspOnly`); `OctaveEquivalencePolicy` is configurable-but-inert (`_ = equivalence` in `select`); `MLExecutionPolicy` is not yet `Options`-wired; `SignalWeights.beatGrid`/`SignalSource.beatGrid` are inert (no producer); `SignalWeights.fileMetadata` only feeds Phase-2a corroboration, not the ensemble `effectiveVote`.

**Block If:**
- Satisfying AC6 would require adding `apple/swift-docc-plugin` (or any package dependency) to `Package.swift` — that violates NFR-2. If `xcodebuild docbuild` cannot produce a clean archive without a package dependency, HALT `blocked` (`docc build needs a forbidden dependency`). (Expected NOT to trigger — the implicit `BoomBoomBoomKit` scheme + Xcode-bundled DocC compiler is confirmed available.)

**Never:**
- Never add `swift-docc-plugin` or any external SPM dependency (NFR-2 hard constraint). Do NOT use `swift package generate-documentation`.
- Never hand-author or hand-edit any file under `Cases/` — it is a regenerated build artifact.
- Never commit `Cases/` (gitignored). Never place a `.md` README note inside the catalog root (DocC renders a stray `.md` as an uncurated article → AC6 warning) — use `BoomBoomBoomKit.docc/README.txt` (DocC treats `.txt` as an inert resource).
- Never let the added `docc-validate` drift step hard-fail on a main-only checkout — guard it on `scripts/docc-transclude.py` presence and skip with a note when absent.
- Do NOT duplicate per-case prose into the Articles (NFR-5). Articles survey and compare; they do not restate a case's three paragraphs.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Standard value case | `BPMSelectionPolicy/maxConfidence.md` (`id`/`title`) | `Cases/BPMSelectionPolicy-maxConfidence.md`: h1 `` # ``BPMSelectionPolicy/maxConfidence`` `` + blank line + verbatim 3-bold-lead body (no `@Metadata` block) | No error |
| Associated-value case | `EnsemblePolicy/weightedVoting.md` (has `payload: SignalWeights`) | `Cases/EnsemblePolicy-weightedVoting.md`: h1 `` # ``EnsemblePolicy/weightedVoting(_:)`` `` (signature suffix from the map, NOT bare `weightedVoting`); ALL front-matter keys stripped incl. `payload` | No error |
| Labeled assoc-value | `DownbeatResult/detected.md` | h1 `` # ``DownbeatResult/detected(estimate:)`` `` (labeled arg) | No error |
| Colliding stem | `AbstainReason/sourceSpecific.md` + `DemotionReason/sourceSpecific.md` | Two distinct files `Cases/AbstainReason-sourceSpecific.md` + `Cases/DemotionReason-sourceSpecific.md`; h1s `` ``AbstainReason/sourceSpecific(_:)`` `` / `` ``DemotionReason/sourceSpecific(_:)`` `` | No collision (Type-prefixed) |
| Skipped inputs | `_Fixture/*`, a future `_template.md`, `Resources/README.md`, a future `_`-prefixed dir | Not emitted; not counted | Silently skipped |
| Malformed input | A `<Type>/<stem>.md` missing opening/closing `---`, invalid UTF-8, or two inputs mapping to one output path | Generator exits nonzero; existing `Cases/` left untouched (temp-build-then-swap) | Fail-closed, no partial update |
| Drift / coverage (`--check`) | On-disk `Cases/` vs a fresh in-memory generation | Filename SETS match (no missing/orphan) AND every on-disk page's bytes == fresh; nonzero on stale/hand-edited/deleted page or empty corpus | Missing/extra/byte-mismatch/empty → fail nonzero |
| Main-only checkout | `scripts/docc-transclude.py` absent | `make docc-transclude` fails loudly; `make docc-validate` drift step self-skips with a printed note; swift-test portion still runs | Graceful skip in docc-validate; hard fail in docc-transclude (intentional) |

</intent-contract>

## Code Map

- `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/BoomBoomBoomKit.md` -- EXISTING landing page (git-tracked). Add a `## Topics` article group curating the two new guides.
- `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Articles/SelectionStrategies.md` -- NEW. Surveys `BPMSelectionPolicy` (8) + `VotingPolicy` (3) + `OctaveEquivalencePolicy` (3). Ships to main.
- `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Articles/EnsemblePresets.md` -- NEW. Surveys `EnsemblePolicy` (5) + `SignalWeights` + `MLExecutionPolicy` (3) + `SignalSource` (4). Ships to main.
- `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/README.txt` -- NEW. Author-facing note: `Cases/*.md` is generated, edit `Resources/Documentation/` instead. `.txt` so DocC treats it as inert (mirror `Resources/README.md` "Adding a case" guidance).
- `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Cases/` -- generated build artifact (gitignored). Populated by the generator.
- `scripts/docc-transclude.py` -- NEW, stdlib-only, develop-only. The generator. Mirrors `scripts/new-case.py` conventions.
- `Makefile` -- add `docc-transclude` target (single `uv run` line, `## ` help); add `docc-build` target (`docc-transclude` prereq → `xcodebuild docbuild` into `build/docc/`, the AC6 gate as a make target); extend `docc-validate` with a presence-guarded drift step; add `../../scripts/docc-transclude.py` to the `py-lint` ty file list (ruff already covers via the `../../scripts/` glob).
- `.gitignore` -- add `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Cases/` (anchored full path) in a new build-artifact section near the SPM/Xcode block.
- `Sources/BoomBoomBoomKit/Resources/README.md` -- EXISTING; its "richer treatments live in `Articles/SelectionStrategies.md`" pointer now resolves to a real file — verify/keep accurate.

## Tasks & Acceptance

**Execution:**
- [x] `scripts/docc-transclude.py` -- Implement the stdlib-only generator: walk `Resources/Documentation/<Type>/*.md` (sorted; skip `_`-prefixed stems AND `_`-prefixed dirs), strip front-matter to the closing `---`, emit `Cases/<Type>-<stem>.md` with the signature-aware symbol-extension h1 (ASSOC-VALUE SIGNATURE MAP for the 5 assoc-value cases; bare stem otherwise) + verbatim byte-preserved body (LF, no `@Metadata` block). Atomic temp-build-then-swap; fail nonzero on malformed input / duplicate output path / `--output-dir` nested in `--docs-root`, leaving `Cases/` untouched. CLI: `--docs-root` (default `Sources/BoomBoomBoomKit/Resources/Documentation`), `--output-dir` (default `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Cases`), `--check` (verify-only mode for docc-validate: assert the ON-DISK `Cases/` matches a fresh generation — filename set identical, each on-disk page's bytes equal the freshly-built page — so it detects a stale/missing/hand-edited/orphan page; fails nonzero on empty corpus; no writes); print count. Deterministic output.
- [x] `Makefile` -- add `## docc-transclude:` target = `uv run scripts/docc-transclude.py` (help notes "Develop-only; fails on a main-only checkout"); extend `docc-validate` with a `[ -f scripts/docc-transclude.py ]`-guarded step invoking `docc-transclude --check` (roster-derived coverage + per-file body byte-equality + determinism), skipping with a printed note otherwise, and update the `docc-validate` help line so it no longer claims "no develop-only tooling"; append `../../scripts/docc-transclude.py` to the `py-lint` ty list.
- [x] `.gitignore` -- ignore `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Cases/`.
- [x] `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Articles/SelectionStrategies.md` -- author the survey article (tables + symbol links allowed) from the verified case data; include the `OctaveEquivalencePolicy`-is-inert honesty note.
- [x] `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Articles/EnsemblePresets.md` -- author the ensemble/weighting article; include all four honesty flags (default case ≠ Options default; MLExecutionPolicy not wired; beatGrid inert; fileMetadata dual role).
- [x] `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/BoomBoomBoomKit.md` -- add a `## Topics` group (e.g. `### Guides`) linking `<doc:SelectionStrategies>` + `<doc:EnsemblePresets>`.
- [x] `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/README.txt` -- author the "Cases/ is generated" note.

**Acceptance Criteria:**
- Given a clean tree, when `make docc-transclude` runs, then `Cases/` contains one `<Type>-<stem>.md` page per eligible source file (49 today), each with the stripped front-matter + signature-aware symbol-extension h1 + byte-verbatim body (no `@Metadata` block), the five assoc-value pages carry their signature-suffixed h1s, and running it twice yields byte-identical output.
- Given `Cases/` is a build artifact, when `git status` runs after generation, then no `Cases/` file is staged/tracked (gitignored), and `BoomBoomBoomKit.docc/README.txt` documents the regenerate-don't-edit rule.
- Given the Articles ship to main, when they are read, then every enum/case/symbol named matches live source (assoc-value case links use the `(_:)`/`(estimate:)` signature form) and the four ensemble honesty flags + the octave-inert flag are present; no per-case three-paragraph prose is copied verbatim (NFR-5).
- Given `make docc-validate` runs on develop, then it runs the swift-test suites AND (script present) invokes `docc-transclude --check`, which asserts the on-disk `Cases/` file set + per-file bytes match a fresh generation (so a stale, missing, or hand-edited page fails CI); on a main-only checkout the drift step self-skips with a note and the swift-test portion still passes.
- Given `xcodebuild docbuild -scheme BoomBoomBoomKit -destination 'platform=macOS'` runs after transclusion, then the build succeeds (exit 0, `BUILD DOCUMENTATION SUCCEEDED`), the `.doccarchive` contains both article identifiers (`selectionstrategies`, `ensemblepresets`) and the per-case symbol pages (incl. the collision-safe `AbstainReason`/`DemotionReason` `sourceSpecific` pair), and ZERO DocC diagnostics originate from `Articles/` or `Cases/`. (VERIFIED — Xcode 26.6: archive built, both articles + all case pages bound, no `.docc/Articles|Cases` diagnostics.) NOTE: a repo-wide `--warnings-as-errors`-clean docbuild is NOT achievable today and is explicitly OUT of 11.5 scope — pre-existing malformed symbol links in unrelated Swift `///` doc comments (e.g. `MLFeatureFrames`, `BeatGrid`, renamed `with(...)`/`combineEnsemble`/`merge`, and structurally-unresolvable cross-target `` ``BNNSTechnique`` `` refs per DD #14) fail that flag; tracked as deferred work. DocC ingested `Cases/` cleanly, so the pressure-release valve was NOT triggered.
- Given `make py-lint` runs, then `scripts/docc-transclude.py` passes ruff + ty with zero findings.

## Spec Change Log

### 2026-07-17 — `--check` semantics clarified (review finding, high)
- **Triggering finding:** 3-reviewer consensus that `docc-transclude --check` was a no-op — it re-derived the expected pages in memory and compared them to themselves (the coverage count and round-trip guard were both tautological), never reading the on-disk `Cases/`. So `make docc-validate`'s advertised drift gate could not detect a stale, hand-edited, or deleted `Cases/` (it even passed against a nonexistent `--output-dir`).
- **Amended:** the Tasks `--check` line, the `docc-validate` AC, and the I/O matrix drift row now specify on-disk comparison — the `Cases/` filename set and each page's bytes must match a fresh generation — plus an empty-corpus floor. The original wording ("each output body byte-identical to source body") described exactly the tautological check and was the root cause. Fixed as a localized patch to `run_check` (not a full code-revert loopback: the generator's naming, signature map, atomic swap, byte/LF discipline, the two articles, and the verified-green docbuild were all correct and re-deriving them would have risked regressing verified-good work).
- **Known-bad avoided:** a validation gate that silently passes on a stale or hand-edited `Cases/`.
- **KEEP:** uniform `<Type>-<stem>.md` naming; the 5-entry assoc-value signature map; atomic temp-build-then-swap; byte-verbatim/LF discipline; the source-verified honesty flags in both articles.

## Review Triage Log

### 2026-07-17 — Review pass (Blind Hunter + Edge Case Hunter + Codex, Opus 4.8)
- intent_gap: 0
- bad_spec: 0
- patch: 9: (high 1, medium 2, low 6)
- defer: 0
- reject: 4
- addressed_findings:
  - `[high]` `[patch]` `--check` was a no-op (in-memory self-comparison; never read on-disk `Cases/`) — rewrote `run_check` to compare the on-disk file set + per-file bytes against a fresh generation; proven to now fail on hand-edit, delete, and empty corpus, stay deterministic, leave no orphans. Removed the tautological round-trip guard + dead coverage assertion; clarified spec `--check` wording.
  - `[medium]` `[patch]` `SelectionStrategies.md` prose contradicted its own table on `windowVoting` clustering — corrected to "five cluster raw candidates, two do not, `windowVoting` clusters post-disambiguation BPMs".
  - `[medium]` `[patch]` `atomic_swap` could orphan `.cases-tmp-*`/`.cases-bak-*` dirs mid-swap and let an `OSError` escape as a raw traceback — wrapped the swap in try/finally rollback+cleanup, added an `OSError`→clean-`fail()` handler, and a `.gitignore` backstop for the temp/backup prefixes.
  - `[low]` `[patch]` average/median/weightedAverage described as aggregating "window scores" — corrected to "candidate scores" (`BPMCluster.scores` is per-candidate).
  - `[low]` `[patch]` `VotingPolicy` called a "tie-break rule" — reframed as the resolution policy that elects the winning cluster (can change the winner outright).
  - `[low]` `[patch]` "octave behavior governed entirely by `MetadataPolicy`" too broad — narrowed to cross-signal corroboration + noted the DSP's separate octave disambiguation.
  - `[low]` `[patch]` `reject_path_overlap` used `Path.is_relative_to` (3.9+) — replaced with a 3.8-safe `relative_to`/except-`ValueError` helper.
  - `[low]` `[patch]` `--check` passed on a 0-file corpus — added an empty-corpus floor (fail nonzero, "wrong --docs-root?").
  - `[low]` `[patch]` orphan swap dirs sit inside the tracked `.docc/` — added `.gitignore` backstop for `.cases-tmp-*`/`.cases-bak-*`.
- rejected (no change, verified): `EnsemblePolicy/default` reserved-word link (VERIFIED bound in the archive as `default.json`); `---`-inside-front-matter early truncation (documented by-design — first closing delimiter wins; corpus is 11.4-validated); CRLF-front-matter message wording (file still correctly rejected nonzero; corpus is LF); `docc-build` main-only failure message (matches the existing `new-case`/`ml-*` fail-loud convention).

## Design Notes

**ASSOC-VALUE SIGNATURE MAP (source-verified — the generator MUST carry this exactly).** Value-only cases use `<Type>/<stem>` as the symbol path; these five associated-value cases need the signature suffix (a bare stem fails DocC symbol binding):
```
("EnsemblePolicy",   "weightedVoting")        -> weightedVoting(_:)
("MLExecutionPolicy","whenDSPConfidenceBelow")-> whenDSPConfidenceBelow(_:)
("DownbeatResult",   "detected")              -> detected(estimate:)   # LABELED arg
("AbstainReason",    "sourceSpecific")        -> sourceSpecific(_:)
("DemotionReason",   "sourceSpecific")        -> sourceSpecific(_:)
```
The Articles must use the same signature form for these case links (e.g. `` ``EnsemblePolicy/weightedVoting(_:)`` ``).

**No `@PageKind(symbolExtension)` (reconciles epic Paige #4).** The epic prescribes `@Metadata { @PageKind(symbolExtension) }`, but `@PageKind`'s only valid arguments are `article`/`sampleCode` — `symbolExtension` is not a real directive and would fail the `--warnings-as-errors` docbuild. Omit the `@Metadata` block entirely: a file whose h1 is a `` ``Type/case`` `` symbol link IS a symbol extension with no directive needed. Pressure-release valve (epic): if DocC still cannot ingest `Cases/` cleanly, ship `Articles/` only and defer the per-case pages — the inline `.docs` accessor (Story 11.1) is the load-bearing surface — logging the deviation in `11-5-pressure-release.md`.

**AC6 build path (NFR-2-safe) — VERIFIED.** `xcodebuild docbuild -scheme BoomBoomBoomKit -destination 'platform=macOS' -derivedDataPath <tmp>`; the `.doccarchive` lands at `<tmp>/Build/Products/Debug/BoomBoomBoomKit.doccarchive`. The `BoomBoomBoomKit` scheme is SPM-auto-generated. Do NOT add `swift package generate-documentation` (needs the forbidden plugin). AC6 is an operator/local gate (full Xcode, macOS-only), NOT a consumer-runnable `make` target. Result (Xcode 26.6): `BUILD DOCUMENTATION SUCCEEDED`; archive contains `selectionstrategies` + `ensemblepresets` article nodes + all per-case symbol pages (maxConfidence, `weightedVoting(_:)`, `detected(estimate:)`, both `sourceSpecific` pages each bind to exactly one node); grep of the log for `.docc/(Articles|Cases)/` diagnostics returns NONE.

**`--warnings-as-errors` deferred (out of 11.5 scope).** Adding `OTHER_DOCC_FLAGS="--warnings-as-errors"` FAILS the docbuild, but ENTIRELY on pre-existing doc-comment symbol-link debt in unrelated Swift source (`MLFeatureFrames`/`TensorLayout` `` ``CaseIterable`` ``/`nchw`/`BPMAnalyzer`, `BeatGrid` renamed `with(...)`, private `combineEnsemble`/old `merge` sigs, and cross-target `` ``BNNSTechnique`` `` which cannot resolve from core per DD #14). None cite `Articles/` or `Cases/`. A warnings-clean docbuild requires a codebase-wide doc-comment audit (and possibly restructuring the BNNSTechnique cross-target refs) — a separate cleanup story. Tracked in `deferred-work.md`.

**Pinned transclude example** (`maxConfidence.md` → `Cases/BPMSelectionPolicy-maxConfidence.md`), body elided:
```
# ``BPMSelectionPolicy/maxConfidence``

**What it does.** …(verbatim body, unchanged)…
```

**Verified article facts (author against these, not CLAUDE.md prose):** `BPMSelectionPolicy` 8 cases (default `maxConfidence`); `VotingPolicy` 3 (default `simpleMajority`, consulted only when `mergeStrategy == .windowVoting`); `OctaveEquivalencePolicy` 3 (default `octaveAwareWithPenalty`, RESERVED/inert — `_ = equivalence`); `EnsemblePolicy` 5 (`` `default` ``/`dspOnly`/`mlOnly`/`highestConfidence`/`weightedVoting(SignalWeights)`; `invokesMLInference` false only for `.dspOnly`; `Options.ensemblePolicy` default is `.dspOnly`, NOT the `default` case); `SignalWeights{dsp,ml,fileMetadata,beatGrid}` all default 1.0, only `dsp`/`ml` feed `effectiveVote = confidence × weight`, `fileMetadata` scales Phase-2a corroboration, `beatGrid` inert; `MLExecutionPolicy` 3 (default `.whenDSPConfidenceBelow(0.85)`, forward-declared/not `Options`-wired); `SignalSource` 4 (`.beatGrid` has no producer). Associated-value case links use `(_:)` (e.g. `` ``EnsemblePolicy/weightedVoting(_:)`` ``).

## Verification

**Commands:**
- `make docc-transclude` -- expected: one page per eligible source (49 today) into `Cases/`; deterministic + byte-identical on re-run.
- `make docc-validate` -- expected: swift-test suites green + `--check` drift step (roster coverage + per-file body byte-equality + determinism) passes; main-only checkout self-skips the drift step.
- `make py-lint` -- expected: ruff + ty clean for `scripts/docc-transclude.py`.
- `make fmt` / `make lint` -- expected: no Swift churn; 0-serious (pre-existing Demo findings excluded).
- `make docc-build` (or `xcodebuild docbuild -scheme BoomBoomBoomKit -destination 'platform=macOS' -derivedDataPath <tmp>`) -- expected: `BUILD DOCUMENTATION SUCCEEDED`; archive at `build/docc/Build/Products/Debug/BoomBoomBoomKit.doccarchive` contains `selectionstrategies` + `ensemblepresets` + per-case pages; `grep '.docc/(Articles|Cases)/' <log>` returns none (operator/local gate, needs full Xcode; VERIFIED Xcode 26.6 via `make docc-build`). `--warnings-as-errors` fails only on pre-existing unrelated doc-comment debt — out of scope, deferred (W86).

**In-session build/test:** run library builds + targeted tests through the **xcode MCP** (`BuildProject`, `RunSomeTests`) per operator directive, not `swift build`/`swift test` via Bash.

**Manual checks:**
- `git status --short` after `make docc-transclude` shows no `Cases/` entry (gitignored).
- The two Articles read as surveys, cross-link real symbols, and carry every honesty flag; no verbatim per-case paragraph copied.

## Auto Run Result

Status: done

**Summary.** Extended the `BoomBoomBoomKit.docc/` catalog with a parallel DocC surface for the Epic-11 per-case docs: two hand-authored survey articles, a curated landing page, and a develop-only one-way generator that mirrors the 49 canonical per-case docs into DocC symbol-extension pages (a gitignored `Cases/` build artifact), plus make targets to build and drift-check the catalog. No per-case prose is duplicated by hand (NFR-5); no package dependency added (NFR-2).

**Files changed.**
- `scripts/docc-transclude.py` (NEW, develop-only) — stdlib-only one-way generator: strips YAML front-matter, prepends a signature-aware symbol-extension h1, byte-verbatim body, atomic self-cleaning temp-swap, `--check` on-disk drift mode.
- `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Articles/SelectionStrategies.md` (NEW) — survey of `BPMSelectionPolicy`/`VotingPolicy`/`OctaveEquivalencePolicy` with comparison tables + the octave-inert honesty note.
- `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Articles/EnsemblePresets.md` (NEW) — survey of `EnsemblePolicy`/`SignalWeights`/`MLExecutionPolicy`/`SignalSource` with all four honesty flags.
- `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/README.txt` (NEW) — author-facing "Cases/ is generated" note (`.txt` = DocC-inert).
- `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/BoomBoomBoomKit.md` — added a `### Guides` topics group linking both articles.
- `Makefile` — added `docc-transclude` + `docc-build` targets; extended `docc-validate` with the guarded on-disk drift check; added the new script to the `py-lint` ty list.
- `.gitignore` — ignore the generated `Cases/` + the swap temp/backup prefixes.
- `_bmad-output/implementation-artifacts/deferred-work.md` — W86 (repo-wide DocC `--warnings-as-errors` debt, out of scope).

**Review findings.** 9 patches applied (1 high: the `--check` no-op → real on-disk drift gate; 2 medium: article/table contradiction, swap robustness; 6 low), 4 rejected with cause, 0 deferred, 0 intent-gaps. See the Review Triage Log.

**Verification.** `make docc-transclude` → 49 pages, deterministic (stable sha1 across regenerations); `make docc-validate` → 22 tests / 13 suites green + `--check` on-disk drift gate PROVEN (fails on hand-edit, delete, and empty corpus; passes clean); `make py-lint` → ruff + ty clean incl. the new script; `make lint` → 0 serious (5 pre-existing Demo); `make docc-build` (`xcodebuild docbuild`, Xcode 26.6) → `BUILD DOCUMENTATION SUCCEEDED`, archive contains both article nodes + all per-case symbol pages (incl. the collision-safe `sourceSpecific` pair and `EnsemblePolicy/default`), zero diagnostics from `Articles/` or `Cases/`. No `Sources/` Swift changed; `Cases/`/`build/` gitignored (never committed).

**Residual risks.** (1) A repo-wide `--warnings-as-errors` docbuild is NOT clean — pre-existing doc-comment symbol-link debt in unrelated Swift source (incl. structurally-unresolvable cross-target `BNNSTechnique` refs, DD #14); out of scope, tracked as W86. (2) FR-50-style drift for a *new* documented type still relies on the operator adding its type-dir + article link (the generator auto-covers any new `<Type>/<case>.md`, but a brand-new type won't appear in the landing page's Guides group without a hand edit). (3) `docc-build`/`docc-validate --check` need full Xcode / the develop-only generator respectively; both fail-loud or self-skip on a main-only checkout by design.

**Pending (operator-owned closeout):** independent `/bmad-code-review` (followup recommended — the review made a high-severity fix to the drift gate) + push `rterhaar/11-5` and open the PR into `rterhaar/epic-11`; update the epic-11 → develop running changelog (PR #97); flip sprint-status `11-5` when landed.
