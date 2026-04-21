# Story 2.4: OA300 Genre Labeling (Shrunken Scope)

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a library author,
I want every OA300 ground-truth entry to carry a non-optional `genre` label (sourced from the subdir for the 74 DnB/breaks-subdir tracks and from explicit per-track tags for the 8 "Bad BPM" tracks, using the GiantSteps taxonomy plus an OA300-only `footwork` extension),
so that Story 2.5 (Genre-Stratified Accuracy Reporting) can bucket OA300 results per-genre without any further schema work, and cross-corpus genre reports (OA300 + GiantSteps) share a vocabulary.

## Scope Notes

- **No corpus expansion.** The original story called for ≥20 new genre-diverse tracks. That scope was cut — GiantSteps (661 electronic-genre-labeled tracks) already provides cross-genre diversity; OA300 remains the DnB tuning corpus.
- **No manual listening.** All 82 existing tracks are tagged via a deterministic subdir heuristic (72 tracks) plus 8 explicit per-track tags the user has already supplied for the `Bad BPM` bucket.
- **Backwards-compat is not a goal.** `OA300Track.genre: String?` (already present in `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:18`) is flipped to non-optional `String`. Every row must carry a genre or decoding fails loudly.

## Acceptance Criteria

1. **Given** the ground-truth fixture at `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json` (82 entries, schema `{filename, bpm, subdir?, title}`, no `genre` field today),
   **When** this story lands,
   **Then** every entry (all 82) has a non-empty `genre: String` field appended at the end of each JSON object (field order: `filename`, `bpm`, `subdir`, `title`, `genre`).
   **And** no entry is added, removed, or renamed.
   **And** the file remains valid JSON: 2-space indent, UTF-8, `ensure_ascii=false` equivalent (matches the existing output format used by `convert-rekordbox-export.py:201-202`).

2. **Given** the GiantSteps genre taxonomy used on all 661 GiantSteps tracks (`Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:37`),
   **When** the OA300 taxonomy is defined,
   **Then** it uses the **23 GiantSteps labels** as-is for any genre that exists there, plus **OA300-specific extensions** for rhythmic identities with no direct GiantSteps equivalent. Story 2-4 seeds two extensions: `footwork` and `half-time-dnb`. **Initial allowed set**: 23 GiantSteps labels + 2 OA300 extensions = 25 labels total.
   **And** the taxonomy is intentionally **extensible** — future stories may add labels by appending to `ALLOWED_GENRES`, tagging the affected rows in `oa300-ground-truth.json`, and logging the addition in that story's Change Log. No Swift code change is required (the `OA300Track.genre` field is a plain `String`; there is no compile-time or decode-time allowlist check).
   **And** no entry in `oa300-ground-truth.json` has a `genre` value outside the current `ALLOWED_GENRES` list.
   **And** the list is recorded once as a constant at the top of `Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py` (`ALLOWED_GENRES`), accompanied by an extensibility comment that describes the workflow for adding labels (do not phrase as "enforced, do not edit"). This is the only non-generated artifact where the taxonomy lives.

3. **Given** the 82 existing entries,
   **When** the genre assignment runs,
   **Then** the mapping follows this deterministic rule set. **Per-track user tags win over subdir heuristic** — resolve per-track overrides first, then apply subdir defaults only to rows with no override:

   **Subdir heuristic defaults (applied after per-track overrides; 72 tracks covered):**
   | subdir | count | genre |
   |---|---|---|
   | `T Tunes` | 56 | `drum-and-bass` |
   | `null` (corpus root) | 11 | `drum-and-bass` |
   | `R Tunes` | 3 | `breaks` |
   | `R Tunes/Liam Howlett - Prodigy Presents The Dirtchamber Sessions Vol.1 - FLAC` | 2 | `breaks` |

   **Bad BPM per-track overrides (8 tracks, user-specified):**
   | filename | genre |
   |---|---|
   | `03 TVR.m4a` | `tech-house` |
   | `College Hill - Undercurrents Vol 3 - 08 Self Immolation.mp3` | `breaks` |
   | `Echtoo - Chakra - Seminal Sounds.wav` | `breaks` |
   | `Echtoo - Chakra.wav` | `breaks` |
   | `Echtoo - The Mummy - Seminal Sounds.wav` | `footwork` |
   | `Fixate - EXITMINILP008 - Fixate - 'Conundrum' - 01 Conundrum.mp3` | `breaks` |
   | `Icicle - Condense.wav` | `techno` |
   | `Nautical Divine - Makara.mp3` | `techno` |

   **Half-time DnB per-track overrides (1 track, user-specified — subdir heuristic would have assigned `drum-and-bass`):**
   | filename | genre |
   |---|---|
   | `1. The Faraday_Bunker (D-Struct Remix).wav` (corpus root) | `half-time-dnb` |

   **Additional per-track overrides (1 track, user-specified — tempo-context override where subdir heuristic misclassifies):**
   | filename | genre | reasoning |
   |---|---|---|
   | `Proxima_Trapped_Original Mix.mp3` (subdir `T Tunes`, 140 BPM) | `breaks` | Too slow for DnB (160–180 BPM); 140 BPM with bass/breaks feel. Subdir heuristic would misclassify as `drum-and-bass`. |

   **And** the final distribution is exactly: `drum-and-bass: 67`, `breaks: 10`, `techno: 2`, `tech-house: 1`, `footwork: 1`, `half-time-dnb: 1` (sums to 82).
   **And** every per-track override entry (Bad BPM, half-time-DnB, and tempo-context) matches its user-supplied tag verbatim — no override row inherits the subdir default.

4. **Given** the shared `OA300Track` struct at `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:13-19`,
   **When** this story lands,
   **Then** the `genre: String?` field is flipped to `genre: String` (non-optional).
   **And** the existing in-file comment `"genre is optional to accommodate Story 2-4's genre backfill without a second struct"` is replaced with a comment that reflects the new non-optional contract **and documents the taxonomy as extensible** (canonical list lives in `ALLOWED_GENRES` in the Python regenerator; Swift does not validate against the list so new labels require zero library change). A malformed row that omits `genre` is a loud-fail (Decodable throws); no silent skip.
   **And** the four consumer suites (`OA300BenchmarkTests.swift`, `DAWOracleBenchmarkTests.swift`, `AblationFullMatrixTests.swift`, `PerformanceBenchmarkTests.swift`) all continue to compile and pass without source edits — they never read `genre` today, and Swift's JSON decoder treats a now-required field as still-decoding-fine so long as the fixture supplies it (AC #1 guarantees this).

5. **Given** `Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py`,
   **When** this story lands,
   **Then** the script no longer hardcodes its output path to `script_dir/oa300-ground-truth.json` (current line 199-200 — a pre-existing bug: the script writes to `BoomBoomBoomKitTests/Fixtures/` while the actual ground-truth file lives in `BoomBoomBoomKitBenchmarkTests/Fixtures/`, so today's naive re-run silently writes an orphan file at the wrong location).
   **And** the script's new default output is **stdout**: `json.dump(deduped, sys.stdout, indent=2, ensure_ascii=False)` + trailing newline.
   **And** the script accepts an optional `--output PATH` / `-o PATH` argument (use `argparse`) that, when provided, writes to that path instead of stdout. No default path.
   **And** the script's docstring is updated: (a) remove the line `"writes oa300-ground-truth.json to the same directory as this script"`; (b) add a usage example showing `uv run convert-rekordbox-export.py <corpus> -o Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json`; (c) add a warning block (3-4 lines) that naively re-running the script **will destroy the `genre` column** because it regenerates from Rekordbox TSV which has no genre field. Either extend the script to merge genre tags from a side-file, or edit the ground-truth JSON by hand after this story lands. `ALLOWED_GENRES` is the canonical list.
   **And** `ALLOWED_GENRES` from AC #2 is present as a module-level constant at the top of the script (between the docstring and the first function). Commented as an **extensible canonical list** with the workflow for adding labels (append to the constant, tag rows in the JSON fixture, log in the proposing story's Change Log). The comment must NOT use "enforced / do not edit" language — the taxonomy is meant to grow.
   **And** the script parses as valid Python 3 (`python3 -c "import ast; ast.parse(open('Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py').read())"` exits 0).

6. **Given** the invariant that `genre` is non-optional on `OA300Track`,
   **When** any benchmark suite tries to decode `oa300-ground-truth.json`,
   **Then** the decode succeeds on a well-formed file and throws loudly (with the standard `DecodingError.keyNotFound` for `genre`) on a row missing `genre`.
   **And** the benchmark suite's `init() throws` surfaces the error — there is no silent-skip path.
   **And** a unit test in a new `Tests/BoomBoomBoomKitTestSupport/` test target (or added to an existing test file if one exists; verify) exercises both paths: a one-row valid JSON decodes; a one-row JSON missing `genre` throws. This prevents a future careless edit from silently re-introducing optional semantics.

7. **Given** the full `make benchmark`, `make oracle`, `make ablation`, `make perf-benchmark`, and `make benchmark-giantsteps` targets,
   **When** this story lands,
   **Then** all five continue to succeed with `OA300_CORPUS_PATH` + `GIANTSTEPS_CORPUS_PATH` env vars set.
   **And** `make benchmark` produces Acc1/Acc2 on OA300 that do not regress from the pre-story baseline (Acc1 = 57/82 per reference in `.claude/skills/running-benchmarks/SKILL.md`). This is a **smoke check**, not a gate — the genre backfill touches zero library code and zero Swift analyzer paths, so any numeric change would indicate a test-setup regression, not a detection regression.

8. **Given** the Completion Notes section,
   **When** the story is moved to `review`,
   **Then** it includes:
   - The final genre histogram across all 82 entries (should match AC #3 exactly: `drum-and-bass: 67, breaks: 10, techno: 2, tech-house: 1, footwork: 1, half-time-dnb: 1`).
   - Confirmation that `OA300Track.genre` is non-optional and the comment is updated (including extensibility note).
   - Confirmation that `convert-rekordbox-export.py` defaults to stdout + accepts `--output`, and that `ALLOWED_GENRES` is present with extensibility guidance.
   - The `make benchmark` Acc1/Acc2 counts (expected unchanged from baseline).
   - A one-line note confirming `daw-oracle.json` was not regenerated (this story does not touch `.dawproject` or the oracle).

## Tasks / Subtasks

**Execution order:** 0 → 1 → 2 → 3 → 4 → 5. Tasks 1 and 3 can parallelize after Task 0 lands.

- [x] **Task 0: Lock taxonomy constant** (AC: #2)
  - [x] 0.1 Confirm the 24-label set: 23 GiantSteps genres (extracted via `python3 -c "import json; print(sorted(set(e['genre'] for e in json.load(open('$GIANTSTEPS_CORPUS_PATH/giantsteps-tempo-ground-truth.json')))))"`) plus `footwork`. Record in this story's Completion Notes if any GiantSteps label has drifted since story creation (count was 23 at 2026-04-18).
  - [x] 0.2 Add an `ALLOWED_GENRES` Python-list-literal constant at the top of `Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py` (between the docstring and the first `import`) containing all 24 labels alphabetically sorted. Include the pointer comment per AC #2.

- [x] **Task 1: Flip `genre` non-optional on `OA300Track`** (AC: #4, #6)
  - [x] 1.1 In `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:18`, change `public let genre: String?` → `public let genre: String`.
  - [x] 1.2 Rewrite the doc-comment block above the struct (lines 3-12) so the sentence about genre's optionality reflects the non-optional contract (per AC #4 example text).
  - [x] 1.3 `swift build` — expect clean. If any downstream consumer reads `genre` as optional (`track.genre == nil`, `track.genre?.something`), it is a new failure surface — fix at call site (there are no such reads today; grep `rg '\.genre' Sources Tests` to verify).
  - [x] 1.4 Leave the four benchmark suites unmodified — they never touch `genre`.

- [x] **Task 2: Backfill `genre` on all 82 ground-truth entries** (AC: #1, #3)
  - [x] 2.1 Open `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json`. Apply the deterministic mapping from AC #3 — per-track overrides first (10 rows: 8 Bad BPM + 1 half-time-dnb + 1 tempo-context), subdir heuristic for the remaining 72 rows.
  - [x] 2.2 Preferred workflow: write a throw-away Python snippet (do not commit) that loads the JSON, walks each entry, applies the mapping (lookup table for per-track overrides, subdir-switch for the rest), appends `genre` at the end of each object, re-writes with `json.dump(data, f, indent=2, ensure_ascii=False)`.
  - [x] 2.3 Verify the final file: 82 entries; every entry has a `genre` from `ALLOWED_GENRES`; distribution matches AC #3 exactly (`drum-and-bass: 67, breaks: 10, techno: 2, tech-house: 1, footwork: 1, half-time-dnb: 1`); JSON parses cleanly.

- [x] **Task 3: Rewrite `convert-rekordbox-export.py` CLI** (AC: #5)
  - [x] 3.1 Add `import argparse` near the existing imports.
  - [x] 3.2 Replace the `sys.argv`-based positional arg parser (current `main()` lines 112-136) with an `argparse.ArgumentParser`. Args: positional `corpus_dir`, optional `-o/--output PATH`.
  - [x] 3.3 Replace the hardcoded output block (current lines 199-204) with:
    ```python
    if args.output:
        with open(args.output, "w") as f:
            json.dump(deduped, f, indent=2, ensure_ascii=False)
            f.write("\n")
        print(f"Wrote {len(deduped)} entries to {args.output}", file=sys.stderr)
    else:
        json.dump(deduped, sys.stdout, indent=2, ensure_ascii=False)
        sys.stdout.write("\n")
    ```
    Informational prints move to `file=sys.stderr` so stdout carries only JSON when `--output` is omitted.
  - [x] 3.4 Update the docstring (lines 2-13) per AC #5 text.
  - [x] 3.5 Run a syntax check: `python3 -c "import ast; ast.parse(open('Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py').read())"`. Run a dry invocation: `uv run Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py --help` — confirm argparse usage prints.
  - [x] 3.6 Do NOT run the script against the real corpus in this story — it would overwrite the genre-backfilled file from Task 2. That is the failure mode the AC #5 docstring warning exists to prevent.

- [x] **Task 4: Add genre-decoding unit test** (AC: #6)
  - [x] 4.1 Find the existing test file for `OA300Track` decoding (grep `rg 'OA300Track' Tests --glob '*.swift'`). If one exists, append the two new tests there; if not, create `Tests/BoomBoomBoomKitTests/CorpusTracksDecodingTests.swift` (the non-benchmark unit test target, not `BoomBoomBoomKitBenchmarkTests`).
  - [x] 4.2 Add Swift Testing cases:
    - `@Test("OA300Track decodes with genre field")` — feeds a single-row JSON with `{"filename": "x.wav", "bpm": 120.0, "subdir": null, "title": "x", "genre": "techno"}` through `JSONDecoder`; asserts decode succeeds and `genre == "techno"`.
    - `@Test("OA300Track throws when genre is missing")` — feeds a single-row JSON without the `genre` key; asserts `JSONDecoder().decode([OA300Track].self, from:)` throws `DecodingError.keyNotFound` matching `genre`.
  - [x] 4.3 `make test` — the new tests are in the unit-test target (no `OA300_CORPUS_PATH` needed); all unit tests green.

- [x] **Task 5: Validation + Completion Notes** (AC: #7, #8)
  - [x] 5.1 Run `make benchmark` (requires `OA300_CORPUS_PATH`). Confirm: 82 tracks analyzed, Acc1/Acc2 counts unchanged from the reference (`running-benchmarks` SKILL.md: Acc1 = 57/82, Acc2 = 73/82). Record actual counts in Completion Notes.
  - [x] 5.2 Run `make oracle`. Confirm pass (loads `oa300-ground-truth.json` via `OA300Track`; genre field present). **Pre-existing failure confirmed unrelated to this story** — see Debug Log References; deferred.
  - [x] 5.3 Run `make benchmark-giantsteps`. Confirm pass (unrelated to OA300 changes but validates no accidental cross-impact on shared `CorpusTracks.swift` edits).
  - [x] 5.4 Run `make ablation` **OR** skip with a note in Completion Notes that it was deferred (~9 min runtime; not strictly required for this story — it also loads `OA300Track`, so if Task 1.3's `swift build` was clean, `make ablation` is highly likely to pass). Deferred.
  - [x] 5.5 Record the genre histogram across the 82 final entries — should match AC #3 exactly.
  - [x] 5.6 Flip Status: `ready-for-dev` → `review`. Update `_bmad-output/implementation-artifacts/sprint-status.yaml` key `2-4-oa300-corpus-expansion-with-genre-diversity` from `ready-for-dev` → `review`.

## Dev Notes

### What changed vs the original Story 2.4

The original story scoped a corpus *expansion* (≥20 new genre-diverse tracks + backfill). During validation, two things surfaced:

1. **The file referenced wrong paths** — `Tests/BoomBoomBoomKitTests/Fixtures/` instead of `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/`. The test target was reorganized after the epic was drafted.
2. **`OA300Track` is a single shared public struct** at `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:13-19`, not a private per-suite decoder. The `genre: String?` field was pre-wired for Story 2.4 but with the wrong nullability.
3. **GiantSteps already provides 661 genre-labeled electronic tracks** — cross-genre diversity was already delivered by Story 2.1. OA300 expansion adds marginal value at meaningful sourcing cost.

Given user constraints ("no manual labeling", "electronic-only", "backwards-compat is not a goal"), the expansion scope was cut. What remains is the *labeling* half of the original story, done deterministically from subdir+filename without any listening. The 24-label taxonomy uses GiantSteps' vocabulary verbatim plus one user-sanctioned extension (`footwork` for `Echtoo - The Mummy`, which has no direct GiantSteps equivalent).

### Why extensions to the GiantSteps taxonomy

GiantSteps' 23 labels do not cover every rhythmic identity in OA300. Story 2-4 seeds two extensions:

- **`footwork`** — sanctioned by user for `Echtoo - The Mummy`. Footwork-at-160-BPM is distinct enough from `breaks` and `drum-and-bass` that forcing it into either would lose a real category signal for Story 2.5's genre-stratified report.
- **`half-time-dnb`** — sanctioned by user for tracks that sit at 170 BPM in Rekordbox ground truth but perceptually feel like 85 BPM because the snare pattern lands on beat 3 only (instead of 2 & 4) or is driven by kicks rather than snares. This is perceptually distinct from regular DnB and relevant both for genre-stratified accuracy reporting (Story 2.5) and for BPM-detection honesty — if the detector reports 85 we want to credit the "perceptual half-time" interpretation, not penalize it. Current tag: `1. The Faraday_Bunker (D-Struct Remix).wav` (kick-driven, no main snares).

Both extensions fall under tiny-bucket handling in Story 2.5's cross-corpus report logic (`epics.md:436-438`: `<5 tracks = flagged as insufficient sample`), so their Acc1/Acc2 will be flagged rather than presented as percentages.

### Taxonomy extensibility

The taxonomy is a **living list**, not a frozen vocabulary. Adding a new genre in a future story requires three coordinated edits, none of which touches library (`Sources/BoomBoomBoomKit/`) code:

1. Append the new label to `ALLOWED_GENRES` in `Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py` (canonical source).
2. Retag the affected rows in `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json` (per-track overrides like the Bad BPM and half-time-dnb sections in this story's AC #3).
3. Log the addition in the proposing story's Change Log, referencing this story's AC #2 extensibility clause.

Swift's `OA300Track.genre: String` intentionally does **not** validate against `ALLOWED_GENRES` — adding a label causes zero compile errors and zero decode errors. The only hard contract is that the field is present.

### File-path reality (post-fix)

- Ground truth: `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json` (82 entries, loaded by all four benchmark suites via `Bundle.module.url(forResource:withExtension:)`).
- Python regenerator: `Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py` (lives in the non-benchmark unit test target's Fixtures — different directory from the file it regenerates). This cross-target layout was pre-existing and is why the script's hardcoded-output-path bug went unnoticed.
- Shared decoder struct: `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:13-19` (`public struct OA300Track: Decodable, Sendable`).
- Consumer suites (all in `Tests/BoomBoomBoomKitBenchmarkTests/`): `OA300BenchmarkTests.swift`, `DAWOracleBenchmarkTests.swift`, `AblationFullMatrixTests.swift` (note: file name, suite name is `AblationMatrixTests`), `PerformanceBenchmarkTests.swift`.

### Why the Python script fix is scoped inside this story

The script's broken output path (writes to `BoomBoomBoomKitTests/Fixtures/` where no file lives, while the real file is at `BoomBoomBoomKitBenchmarkTests/Fixtures/`) is a pre-existing bug unrelated to genre backfill. It is fixed here anyway because: (a) this story touches the script (`ALLOWED_GENRES` constant, docstring warning) so an additional small refactor is low-risk; (b) leaving a broken regenerator in tree is cruft; (c) the new stdout-or-`--output` design is the correct long-term shape regardless of the genre concern. A separate story would be ceremony without benefit.

### Forward-compat for Story 2.5

Story 2.5 (Genre-Stratified Accuracy Reporting, `epics.md:426-441`) will read `track.genre` directly after this story lands. No `OA300Track` edit required — Task 1 delivers the non-optional field. Story 2.5's reporter must be prepared for:
- Tiny buckets (`techno: 2`, `tech-house: 1`, `footwork: 1`) — already handled by the epic's "insufficient sample" note (AC in `epics.md:436-438` says `<5 tracks = flagged, not reported as percentage`).
- Labels that exist in OA300 but not GiantSteps (`footwork`) and labels that exist in GiantSteps but not OA300 (almost all of them — OA300 uses only 5 of the 24 labels). Cross-corpus unified reports must take the label union.

### GiantSteps taxonomy reference (as of 2026-04-18)

The 23 labels extracted from `$GIANTSTEPS_CORPUS_PATH/giantsteps-tempo-ground-truth.json`:

`breaks, chill-out, deep-house, dj-tools, drum-and-bass, dubstep, electro-house, electronica, funk-r-and-b, glitch-hop, hard-dance, hardcore-hard-techno, hip-hop, house, indie-dance-nu-disco, minimal, pop-rock, progressive-house, psy-trance, reggae-dub, tech-house, techno, trance`

Plus the OA300-only extensions seeded in Story 2-4: `footwork`, `half-time-dnb`. Initial allowed set: 25 labels (extensible — see Taxonomy Extensibility note above).

### Project Structure Notes

- Files touched: one JSON file, one Swift struct, one Python script, one new unit-test file (if needed), this story file, sprint-status.yaml. No Makefile edits.
- No ADR impact. ADR-9 (GiantSteps as separate test suite) and ADR-10 (dual tolerance) are unaffected.
- No PRD impact beyond the direct FR tie: FR33 ("Genre-stratified accuracy reporting is available once the corpus has sufficient genre diversity") — the *labeling* half of the FR33 precondition is delivered by this story; the *diversity* half is already delivered by GiantSteps per Story 2.1.
- No perf-baseline regression expected. `PerformanceBenchmarkTests` decodes `oa300-ground-truth.json` via the shared `OA300Track` struct; the genre field is a new required decode field but the JSON supplies it, so the decode path is unchanged in speed and correctness. No `_bmad-output/perf-baselines/*.json` record will shift on this story's commit.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.4] (original scope — this story replaces it)
- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.5] (downstream consumer; dictates AC #2 taxonomy + AC #4 non-optional contract)
- [Source: _bmad-output/planning-artifacts/prd.md#FR33] (genre-stratified accuracy reporting)
- [Source: Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:13-19] (shared `OA300Track` struct — flipped by Task 1)
- [Source: Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:30-38] (`GiantStepsTrack` — non-optional genre already, the model this story aligns OA300 to)
- [Source: Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json] (82-entry target file — edited by Task 2)
- [Source: Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py:199-202] (broken output path + format; rewritten by Task 3)
- [Source: Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift:42-49] (ground-truth resource loader — pattern shared by all four benchmark suites)
- [Source: .claude/skills/running-benchmarks/SKILL.md] (Acc1 = 57/82 baseline; targets list; corpus env-var conventions)
- [Source: $GIANTSTEPS_CORPUS_PATH/giantsteps-tempo-ground-truth.json] (GiantSteps taxonomy — the 23 labels OA300 aligns to)

### Previous-story intelligence

Story 2.3 (`2-3-performance-benchmark-infrastructure.md`) added `PerformanceBenchmarkTests` which loads `oa300-ground-truth.json` via the shared `OA300Track` struct. Because `genre` was already `String?` on that struct, Story 2.3 could land without touching the fixture. After this story, the field is `String` (non-optional) — Story 2.3's decoder path now requires the field. The fixture edit in Task 2 is the only thing standing between a working state and a decode failure; Task 2 must land in the same commit as Task 1, not separately.

Story 2.1 (`2-1-giantsteps-tempo-dataset-integration.md`) established `GiantStepsTrack` with non-optional `genre: String`. This is the precedent for the Story 2.4 design: one taxonomy, one contract, loud-fail on omission. OA300 inherits that shape.

Story 2.6 (`2-6-perf-baselines-file-per-run-redesign.md`, also ready-for-dev) is orthogonal to this one. They can ship in either order. Story 2.6 touches `PerformanceBenchmarkTests.swift`, the Makefile, and `running-benchmarks` SKILL.md — zero file overlap with this story.

### Git intelligence (recent commits)

Epic 2 commit pattern on `rterhaar/epic-2`:
- `6e39893` Story 2-3: Performance benchmark infrastructure with delta-vs-last-baseline reporting
- `a97bad2` Story 2-2: Dual-tolerance accuracy reporting and MIREX-compliant Acc2 unification
- `eefdb1f` Story 2-1: GiantSteps dual-tempo integration and MIREX-compliant Acc2

Commit message for this story should match: `Story 2-4: OA300 genre labeling (GiantSteps-aligned)`. Single commit.

### Out of scope

- Corpus expansion (≥20 new tracks) — cut by Q6 scope shrink. OA300 stays 82 tracks.
- `convert-rekordbox-export.py` extension to read/merge a genre side-file. The current story adds `ALLOWED_GENRES` as a constant and a warning block; wiring the script to preserve genre on re-run is a follow-up if the script ever needs to be re-run (which, per Task 3.6, it should not after this story lands).
- Story 2.5 implementation. The forward-compat contract is delivered here (`genre: String` non-optional, 24-label taxonomy, histogram reported); the *reporting* logic is entirely Story 2.5's scope.
- Re-running `make oracle-generate` or touching `daw-oracle.json` — unrelated to genre.
- Any change to ablation matrix, intensity mapping, or DSP technique code paths.

## Dev Agent Record

### Agent Model Used

claude-opus-4-7 (story context engine)

### Debug Log References

- In-dev scope amendment: user requested `half-time-dnb` be added to the taxonomy mid-implementation. Two tracks tagged: `Proxima_Trapped_Original Mix.mp3` and `1. The Faraday_Bunker (D-Struct Remix).wav`. Taxonomy also reframed from "locked 24-label set" to "extensible 25-label seed" per user direction that the system must not be too rigid.
- Pre-existing oracle failure confirmed: `make oracle` fails on HEAD (pre-story) with `DecodingError.keyNotFound: daw_bpm` at `DAWOracleBenchmarkTests.swift:232`. Root cause is a conflict between `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase` and `DAWOracleTrack`'s explicit `CodingKeys` with snake_case raw values — the strategy strips the snake_case form before CodingKey lookup, so the `dawBpm = "daw_bpm"` mapping never matches. Verified by stashing story changes and re-running `make oracle`: same failure. Not caused by this story. Deferred — a separate follow-up should remove either `CodingKeys` (let `.convertFromSnakeCase` do the work) or the decoder strategy (let CodingKeys handle it). AC #7's "`make oracle` continues to succeed" is interpreted as "does not regress", which this story satisfies.

### Completion Notes List

- **Taxonomy amendment (mid-dev):** Seeded taxonomy is now 25 labels (23 GiantSteps + `footwork` + `half-time-dnb`) and is explicitly extensible — future stories may append via `ALLOWED_GENRES` + retag + Change Log, no Swift change required. Captured in AC #2 rewrite and Change Log.
- **Final genre histogram across 82 entries:** `drum-and-bass: 67, breaks: 10, techno: 2, tech-house: 1, footwork: 1, half-time-dnb: 1` — matches AC #3 exactly. Verified via Python `Counter` on `oa300-ground-truth.json`.
- **`OA300Track.genre` non-optional:** Flipped `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:18` from `String?` to `String`. Doc comment rewritten to describe the non-optional contract and note the taxonomy is extensible (canonical list lives in `ALLOWED_GENRES`; Swift does not validate against it).
- **GiantSteps taxonomy drift check:** 23 labels confirmed unchanged from 2026-04-18 reference. `python3 -c "import json; print(sorted(set(e['genre'] for e in json.load(open('$GIANTSTEPS_CORPUS_PATH/giantsteps-tempo-ground-truth.json')))))"` returns the same 23 labels.
- **`convert-rekordbox-export.py` rewrite:** stdout-by-default + `-o/--output PATH` via argparse; docstring updated with usage example and a destroy-the-genre-column warning block; `ALLOWED_GENRES` present with extensibility guidance (no "enforced / do not edit" framing). Informational logs moved to stderr. Syntax + `--help` verified.
- **Genre-decoding unit test:** New file `Tests/BoomBoomBoomKitTests/CorpusTracksDecodingTests.swift` with 2 Swift Testing cases (happy path + loud-fail on missing `genre`). Both pass.
- **`make benchmark` Acc1/Acc2:** Acc1 = 57/82 (69.5%), Acc2 = 73/82 (89.0%) at intensity 7, `maxConfidence` merge. Matches the pre-story baseline from `running-benchmarks` SKILL.md — no accuracy regression.
- **`make benchmark-giantsteps`:** Overall Acc1 = 81.1%, Acc2 = 82.5% across 661 tracks — passes, confirms no cross-impact from the shared `CorpusTracks.swift` edit.
- **`make oracle`:** Pre-existing failure (unrelated to this story) — documented in Debug Log References above. Not caused by Story 2-4; should be addressed in a follow-up.
- **`make ablation`:** Deferred per Task 5.4. Same `OA300Track` decode path as the other benchmark suites, all of which passed.
- **Full unit test suite:** `make test` runs 145/145 green.
- **`make fmt` + `make lint`:** Clean. Only lint warning is a pre-existing TODO in `LUFSAnalyzer.swift:94` — intentional per CLAUDE.md rule.
- **`daw-oracle.json`:** Not regenerated (this story does not touch `.dawproject` or the oracle).
- **Code review applied (2026-04-18):** Two decision-needed findings resolved — (a) custom `init(from:)` on `OA300Track` throws `DecodingError.dataCorrupted` on empty/whitespace `genre`; (b) new unit test loads the real fixture and asserts every row's genre is in a Swift-side mirror of `ALLOWED_GENRES`. One docstring wording patch applied. Gemini refinements: #3 and #5 subsumed by the decision-needed resolutions; #2 (`sort_keys=True`) rejected as AC #1 conflict; #1 and #4 deferred. Unit suite 149/149 green; OA300 Acc1=69.5% / Acc2=89.0% unchanged post-hardening.

### File List

- `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift` (modified — `OA300Track.genre` flipped to non-optional `String`; custom `init(from:)` added to throw `DecodingError.dataCorrupted` on blank/whitespace genre; doc comment rewritten to describe the tightened contract and extensible taxonomy)
- `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json` (modified — `genre` field appended to all 82 entries; histogram `drum-and-bass: 67, breaks: 10, techno: 2, tech-house: 1, footwork: 1, half-time-dnb: 1`)
- `Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py` (modified — `ALLOWED_GENRES` constant with 25 labels + extensibility comment; `argparse`-based CLI with stdout default + `-o/--output` flag; rewritten docstring with usage example and destroy-the-genre-column warning block; informational logs → stderr; review-patch: "above"→"below" one-word wording fix)
- `Tests/BoomBoomBoomKitTests/CorpusTracksDecodingTests.swift` (created — Swift Testing cases for the `OA300Track` genre contract: happy path + four loud-fail shapes (`keyNotFound`, `valueNotFound`, `dataCorrupted` ×2) + `fixtureGenresAreWithinAllowedTaxonomy` drift-guard against a Swift-side mirror of `ALLOWED_GENRES`)
- `_bmad-output/implementation-artifacts/2-4-oa300-corpus-expansion-with-genre-diversity.md` (modified — in-dev amendment for `half-time-dnb` + extensibility reframe; all tasks checked; Dev Agent Record filled; Status flipped to `review`)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified — `2-4-oa300-corpus-expansion-with-genre-diversity` status `ready-for-dev` → `review`)

## Change Log

- 2026-04-17 — **Story created** (original scope: corpus expansion + genre backfill).
- 2026-04-18 — **Story rewritten** (via `/bmad-create-story 2-4` validate+update pass). Scope shrunk from "expansion + labeling" to "labeling only" (Q6). Corpus expansion (≥20 new tracks) cut because GiantSteps already provides cross-genre electronic diversity. Taxonomy aligned to GiantSteps' 23 labels with one user-sanctioned extension (`footwork`, Q5+Q4 follow-up). Genre flipped to non-optional (Q2, "backwards-compat is not a goal"). Subdir heuristic replaces manual listening (Q1). `convert-rekordbox-export.py` hardcoded-output-path bug fixed (Q3). All path references corrected from `BoomBoomBoomKitTests/Fixtures/` to `BoomBoomBoomKitBenchmarkTests/Fixtures/` where the actual ground-truth lives. `OA300Track` confirmed as shared public struct in `CorpusTracks.swift`, not a per-suite private. Status: `ready-for-dev`.
- 2026-04-18 — **In-dev amendment**: added `half-time-dnb` as a second OA300 extension (24 → 25 initial labels). User-supplied per-track tags for two tracks previously defaulting to `drum-and-bass`: `Proxima_Trapped_Original Mix.mp3` (T Tunes) and `1. The Faraday_Bunker (D-Struct Remix).wav` (corpus root). AC #2 reframed from a locked 24-label set to an **extensible** taxonomy (future stories may append labels via a 3-step workflow: update `ALLOWED_GENRES`, tag rows, log in Change Log). Struct doc comment and Python constant comment reworded to remove "enforced / do not edit" framing.
- 2026-04-18 — **User revision (review-stage)**: `Proxima_Trapped_Original Mix.mp3` reverted from `half-time-dnb` back to `drum-and-bass` (user re-auditioned and judged not half-time). `half-time-dnb` tag now applies to a single track (`1. The Faraday_Bunker (D-Struct Remix).wav`). The `half-time-dnb` label remains in `ALLOWED_GENRES` (taxonomy extension is sticky; single-track bucket is fine since Story 2.5's `<5 tracks = insufficient sample` rule handles it). Updated AC #3 subdir counts, half-time-dnb table, final histogram, AC #8 expected histogram, Task 2 subtasks, Completion Notes, and File List.
- 2026-04-18 — **Second user revision (review-stage)**: `Proxima_Trapped_Original Mix.mp3` retagged `drum-and-bass` → `breaks` (user noted the track is 140 BPM, too slow for DnB; bass/breaks feel fits better). Added a third per-track override category to AC #3 — "Additional per-track overrides (tempo-context)" — distinct from the Bad BPM and half-time-DnB override tables to keep the semantic reason for the override explicit. Subdir heuristic T Tunes count now 56 (was 57). Final histogram: `drum-and-bass: 67, breaks: 10, techno: 2, tech-house: 1, footwork: 1, half-time-dnb: 1`.
- 2026-04-18 — **Code review applied (review → done)**: resolved both decision-needed findings. (1) Added a Swift-side mirror of `ALLOWED_GENRES` + `fixtureGenresAreWithinAllowedTaxonomy` unit test that loads the real fixture and asserts every row's genre is in the mirror — taxonomy drift workflow is now 4 steps (Python + JSON + Swift mirror + Change Log). (2) Added custom `OA300Track.init(from:)` that throws `DecodingError.dataCorrupted` on empty/whitespace `genre`; added tests for `""`, `"   \n\t "`, and `null`. Doc-comment updated to describe the tightened contract. Applied one docstring wording patch (`above`→`below`). Rejected Gemini refinement #2 (`sort_keys=True`) as AC #1 conflict. Deferred Gemini #1 (`--merge-from` flag) and #4 (`Genre` wrapper struct) to follow-up. Status: `review` → `done`.

### Review Findings

_Code review run 2026-04-18. Layers: Blind Hunter, Edge Case Hunter, Acceptance Auditor. Fixture integrity verified: 82 entries, histogram matches AC #3, key order `[filename, bpm, subdir, title, genre]` stable, zero off-taxonomy or empty genres._

- [x] [Review][Decision] `ALLOWED_GENRES` is declared but never consulted at runtime — **Resolved 2026-04-18**: added `fixtureGenresAreWithinAllowedTaxonomy` unit test in `Tests/BoomBoomBoomKitTests/CorpusTracksDecodingTests.swift` that loads the real `oa300-ground-truth.json` via `#filePath`-relative URL and asserts every row's `genre` is in a private Swift-side mirror of `ALLOWED_GENRES` (25 labels). Drift workflow is now 4 steps: Python `ALLOWED_GENRES` + JSON fixture + Swift mirror + Change Log. Also asserts `tracks.count == 82`.
- [x] [Review][Decision] Only a missing `genre` key triggers loud-fail — **Resolved 2026-04-18**: replaced synthesized `Decodable` conformance on `OA300Track` with a custom `init(from decoder:)` that throws `DecodingError.dataCorrupted` when `genre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty`. Added three unit tests: empty string `""`, whitespace-only `"   \n\t "`, and JSON `null`. Doc-comment on `CorpusTracks.swift:3-19` rewritten to describe the tightened contract (missing→`keyNotFound`, null→`valueNotFound`, blank→`dataCorrupted`). OA300 benchmark re-run post-change: Acc1=69.5% (57/82), Acc2=89.0% (73/82) — matches baseline; no regression from stricter decoder. Unit suite: 149/149 green.
- [x] [Review][Patch] Docstring wording inconsistency: "`ALLOWED_GENRES` above" in warning block but constant is below the docstring [`Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py:31`] — **Fixed 2026-04-18**: one-word change, `above` → `below`. Python `ast.parse` sanity check exits 0.
- [x] [Review][Triage] Gemini refinement #2 (`sort_keys=True` on `json.dump`) — **Rejected 2026-04-18**: would alphabetize keys to `bpm, filename, genre, subdir, title` and directly violate AC #1's mandated order `filename, bpm, subdir, title, genre`. Not applied.
- [x] [Review][Triage] Gemini refinement #3 (live fixture taxonomy validation) and #5 (guard against empty strings) — **Already satisfied** by the D1/D2 resolutions above.
- [x] [Review][Defer] Gemini refinement #1 (`--merge-from <json>` flag on converter) — logged to `deferred-work.md`; spec explicitly out-of-scope.
- [x] [Review][Defer] Gemini refinement #4 (`Genre` wrapper struct) — logged to `deferred-work.md`; revisit once a second consumer (Story 2-5 reporter) makes the ergonomic benefit concrete.
- [x] [Review][Defer] Test runs `JSONDecoder().decode()` twice in `throwsWhenGenreMissing` — deferred, cosmetic. The `#expect(throws: DecodingError.self)` block plus a second `do/catch` for associated-value extraction is belt-and-suspenders; could consolidate once Swift Testing adds typed associated-value matching. [`Tests/BoomBoomBoomKitTests/CorpusTracksDecodingTests.swift:56-69`]
- [x] [Review][Defer] `convert-rekordbox-export.py` CLI has no hardening for `args.output` — no parent-dir validation, `-o -` creates a literal file named `-`, trailing-slash path yields bare `IsADirectoryError` traceback. Deferred, pre-existing style; script not meant to be re-run per Task 3.6. [`convert-rekordbox-export.py:278-281`]
- [x] [Review][Defer] No `encoding="utf-8"` on `open(args.output, "w")` or on `sys.stdout.write` — under `LANG=C`/`LC_ALL=POSIX` the script can raise `UnicodeEncodeError` mid-output because the fixture contains non-ASCII (`Xiûa`, smart apostrophes). Deferred, environmental; macOS default locale is UTF-8 and script is not expected to re-run. [`convert-rekordbox-export.py:278, 283-284`]
- [x] [Review][Defer] Duplicate `.wav` / `.mp3` pairs in the fixture count twice in per-genre accuracy — e.g., `5. Darkgray Heart_Beating Heart Of The Summer Sun (robbyt Remix)` has both `.wav` (line 66) and `.mp3` (line 617) entries. Pre-existing corpus data-quality issue, not introduced by this story, but now doubled in Story 2-5's per-genre buckets. [`Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json`]
- [x] [Review][Defer] Completion Notes claims "145/145 unit tests green" and GiantSteps `Acc1=81.1%, Acc2=82.5%` are unverifiable from the diff — trust-but-verify via `make test` and `make benchmark-giantsteps`. Deferred, verification-only. [`_bmad-output/implementation-artifacts/2-4-oa300-corpus-expansion-with-genre-diversity.md:282-284`]
