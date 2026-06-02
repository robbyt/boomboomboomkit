<!-- baseline_commit: 80a55aa (Story 7-1 merge, PR #24) -->
<!-- branch: rterhaar/7-2 off rterhaar/epic-7 (mirror the Epic-6 parent-branch + per-story-PR workflow) -->
<!-- epic_source: _bmad-output/planning-artifacts/epics.md#L629-L663 (Story 7.2) -->

# Story 7.2: Non-Rekordbox audio expansion + provenance-clean tiering

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Spec validation history

- **2026-06-01 — spec created** via bmad-create-story (ultracode). A 6-agent context-engine workflow + mandatory factual-claims grep surfaced **three reality-deltas baked in as DDs**: (1) the epic's named input dir `_bmad-output/ml-training/tony-corpus/non-rekordbox/` **does NOT exist** — the ~4,700 set is DERIVED (DD #1); (2) the four FR-17 sentinels are **title-keyed, not audio-hash-keyed**, and no audio-hash field exists project-wide — AC7 uses a content hash, NOT title-match (DD #3/#4); (3) **no Python tag-BPM parser and no `mutagen`** exist (DD #2). All four sentinel files were located on disk; **Charly (`.aiff`) appears in BOTH OA300 and the non-Rekordbox pool, byte-identical (sha256 `b4ede99…`)** — so sentinel exclusion is load-bearing.
- **2026-06-01 — Codex adversarial review (round 1)** caught a **metadata-corroboration circularity**: under default `Options().metadataPolicy = .default`, `AudioAnalysisService.analyzeBPM` returns the **post-corroboration** BPM (and the `0.03` window matches the library's corroboration default), so a naïve DSP-vs-tag gate is self-fulfilling. Fixed: metadata-BLIND DSP (new dev-only `tony-dsp-prepass --no-metadata` → public `MetadataPolicy.disabled`, verified at `MetadataPolicy.swift:186` to suppress both tag I/O and corroboration) + INDEPENDENT `mutagen` tags. Also integrated round 1: basename subtraction with ambiguous-basename quarantine (the conservative equivalent of resolved-path subtraction — the foreign-host XML paths preclude exact resolution, so basename is the only join); `file_sha256` audioHash (overclaim dropped); path-free downstream manifest; typed `decide_tier` guard; yield/threshold honesty.
- **2026-06-01 — axiom:ask (axiom-concurrency) + Codex round 2 + party-mode review (Mary/Winston/Amelia/John)**, all claims re-verified in code. axiom + Codex-2 confirmed `.disabled` is correct/complete and the Swift 6 `--no-metadata` pattern is hazard-free. The party converged on **two blockers now fixed**: (A) the **Python-walk → Swift-CLI adapter seam** — the unmodified `tony-dsp-prepass` requires a non-optional `track_id`/`name`/`artist` and hard-filters `resolve_status == "ok"` at TWO sites (`main.swift:176` + `:294`), so the survey must SYNTHESIZE the survey shape with `audioHash` as the stable join `track_id`, partition `cloud_only`/`ambiguous_membership` UPSTREAM of the CLI, and assert count-in == count-out (new DD #9; AC1/AC3); (B) the **7.2→7.3 manifest was unloadable** (`audioHash`-keyed, path-free → no bytes to train on) — the manifest now carries `relPath` for file fetch (FR-15 forbids path as a model FEATURE, not as a file LOCATOR), AC9 reframed. Also integrated: AC5 names the **net-new ratio-family agreement predicate** (canonicalization primitives reused, comparison authored; band-edge-safe); `decide_tier` Optional params + "selected DSP result confidence ≤ 0.40" wording; the **octave-risk caveat** (agreement proves DSP↔tag *consistency*, not octave *correctness* — 7.3's FR-16 loss is the backstop); the **underpowered-arm yield tripwire** (a near-empty supervised tier is a JOB risk to the ablation, named in the report); sentinel-source **fail-loud** precondition; `mutagen` py.typed note; AC6 grep tightened to `decide_tier` call sites.

## Story

**As a** library maintainer,
**I want** the ~4,700 unlabeled audio files outside Rekordbox `<COLLECTION>` surveyed, fingerprinted, and tiered as a semi-supervised pool with strict provenance filters (DSP + generic file-metadata agreement within 2-3% after octave normalization → secondary supervised tier; path/playlist/Rekordbox-derived signals forbidden as expansion-tier evidence),
**So that** Epic 7's KDD-B2 ablation can fairly compare supervised-only-with-augmentation vs masked-mel pretraining over a clean expansion pool, with a source-distribution report (genre/tempo/source/tier counts before-and-after) produced for review per FR-13.

## Acceptance Criteria

> Numbering preserves the six epic ACs (epics.md L635-L659) and adds the prerequisites the epic glossed: the set **derivation**, the **metadata-blind DSP + independent tag** producer (the agreement gate is otherwise circular), the **audioHash** AC7 depends on, and the **adapter contract** to the existing Swift CLI. Each AC tags its epic source.

**AC1 — Derive the non-Rekordbox set by basename subtraction (with ambiguous-basename quarantine), upfront 3-way partition (fills the epic gap).**
**Given** there is no `tony-corpus/non-rekordbox/` directory (verified absent) and audio lives under `TONY_AUDIO_ROOT = /Users/rterhaar/Dropbox/tony-tunes/` (~6,407 audio files) alongside `05092026.xml` (`<COLLECTION Entries="1721">`), and the XML `Location` attrs encode a foreign hostname so **basename is the only available join** (paths cannot be resolved exactly),
**When** `scripts/non-rekordbox-survey.py` runs,
**Then** it (a) builds the on-disk basename index (`build_basename_index`) and parses the XML `<COLLECTION>` into a **basename set** (`parse_collection_basenames`); (b) computes the expansion candidates = on-disk audio (recursive; `{.mp3,.wav,.aif,.aiff,.flac,.m4a,.caf}`) whose basename is **NOT** in the collection set; (c) partitions every candidate into exactly one bucket BEFORE any DSP call — `analyzable` (a non-empty readable single-basename file → fed to DSP), `cloud_only` (0-byte Dropbox/iCloud placeholder → reported, NOT analyzed), or `ambiguous_membership` (basename appears in >1 on-disk location per the index's multi-entry buckets → reported, excluded from BOTH tiers so a shared basename can never over-exclude a real file — the conservative equivalent of resolved-path subtraction given the foreign-host paths). It asserts **count-in == count-out** (every walked candidate lands in exactly one bucket) and reports the computed `analyzable` count reconciled against the "~4,700" estimate as a snapshot (**not coerced**; note the `~6,407 − 1,721 ≈ 4,686` figure is an UPPER bound on the subtrahend — basename resolution is lossy, so the true expansion set is typically larger). No physical `non-rekordbox/` directory is created (DD #1).

**AC2 — Survey output schema (epic AC1, L637-639).**
**Given** the `analyzable` set,
**When** the survey completes,
**Then** `_bmad-output/ml-training/non-rekordbox-survey.json` has per-file fields: `path` (relative to `TONY_AUDIO_ROOT`), `audioHash` (DD #3), `dspBPM`, `dspConfidence` (metadata-blind, AC3), `fileMetadataBPM` (ID3v2.3/v2.4 TBPM, MP4 tmpo, FLAC Vorbis BPM= only; `null` when absent/unparseable), `agreementAfterOctaveNormalization` (Bool), `agreementDeltaPct` (Float; the min ratio-family delta), `tier` (`secondarySupervised` / `unsupervisedPool` / `reject`), plus `bpm_truth` + `labelSource` + `labelConfidence` (written only on `secondarySupervised` rows). The `cloud_only` + `ambiguous_membership` buckets are emitted in a sibling `skipped` section (count-in == count-out). No dict is keyed by a rounded-BPM string (project-context.md banned-shape lesson).

**AC3 — Synthesized adapter to the Swift CLI: metadata-BLIND DSP + INDEPENDENT tag parser (architecture; breaks the circularity AND the integration seam).**
**Given** the unmodified `tony-dsp-prepass` decodes a fixed Rekordbox-survey shape with non-optional `track_id`/`name`/`artist` and hard-filters `resolve_status == "ok"` at `main.swift:176` and `:294`, and that `analyzeBPM` under default `metadataPolicy` returns a tag-corroborated BPM,
**When** per-file `dspBPM`/`dspConfidence`/`fileMetadataBPM` are produced,
**Then**: (a) the survey **computes `audioHash = file_sha256` first**, then synthesizes a SurveyTrack-shaped JSON per `analyzable` file — `track_id = audioHash` (the stable+unique JOIN key for the read-back), `name = ""`, `artist = ""`, `local_path = <abs path>`, `resolve_status = "ok"` (only `analyzable` files get `"ok"`, so the CLI's dual filter drops nothing AC1 meant to keep) — and invokes `tony-dsp-prepass --no-metadata`, joining `DSPTrackResult.track_id == audioHash` on read-back; (b) `--no-metadata` sets `options.metadataPolicy = .disabled` (public preset; the existing tony-corpus default prepass is untouched) → BPM-tag-blind DSP (`durationHint` stays on — it is audio/container-derived, independent of TBPM/tmpo/Vorbis, so it does not reopen the circularity; "BPM-tag-blind" is the precise claim); (c) `fileMetadataBPM` is read by an **independent** parser, Python `mutagen` (added via `uv add mutagen`), parsing raw ID3v2.3/v2.4 TBPM, MP4 tmpo, FLAC Vorbis `BPM=`. The two signals are provenance-independent → the AC5 gate is meaningful, not tautological. (Documented alternative: all-Swift two-pass harvesting `result.metadataEvidence.parsedBPM`; `mutagen` preferred for independence + 1× DSP — its parser-drift vs the library's `FileMetadataReader` is an accepted, bounded, dev-only diagnostic cost, DD #2.) All Swift edits confined to the dev-only `swift_feature_extractor/` package.

**AC4 — `audioHash` is a content hash, never path-derived; doubles as join + manifest key (supports AC2/AC3/AC7/AC9).**
**Given** FR-13/FR-15 forbid path/Rekordbox-derived signals as provenance,
**When** `audioHash` is computed,
**Then** it is `corpus_common.file_sha256(local_path)` — SHA-256 over the raw audio-file bytes (reuse the existing helper; deterministic; content-derived, NOT path-derived) — explicitly **NOT** `content_hash()` (sha1 of `path|size|mtime`, path-derived, FR-13-forbidden). The same `audioHash` is the CLI read-back join key (AC3) and the manifest identity key (AC9). Documented limitation: a raw-byte hash catches **exact-file** duplicates (verified sufficient for the byte-identical Charly leak) but is **not** robust to re-encodes — re-encoded sentinel copies are handled by the report-only near-copy aid (AC7), never by claiming byte-hash robustness it lacks.

**AC5 — Octave-normalized agreement via a typed function with a NAMED ratio-family predicate (epic AC3, L645-647).**
**Given** the 2-3% agreement tolerance for secondary-supervised promotion,
**When** a file is tiered,
**Then** the decision is a **pure typed function** `decide_tier(dsp_bpm: float | None, dsp_confidence: float | None, file_metadata_bpm: float | None, audio_hash: str) -> TierResult` that structurally receives ONLY those values (no `path`/playlist/XML-id in scope — the provenance guard is the type, AC6). Agreement is the **ratio-family predicate** (net-new code; the canonicalization primitives are reused, the comparison is authored): `agreement = any( |file_metadata_bpm - k*dsp_bpm| / max(file_metadata_bpm, k*dsp_bpm) <= 0.03 for k in (0.5, 1.0, 2.0) )` — i.e. the tag agrees with the DSP BPM or its half or double. This is band-edge-safe (it does NOT rely on `_canonicalize(a) == _canonicalize(b)`, which can differ for true octave pairs near 60/200); reuse `corpus_diagnostics._canonical_ratio` / `tony-tunes-labels._near_pct` for the ratio/tolerance idiom. Passing → `secondarySupervised` (`bpm_truth` = the metadata-blind DSP BPM canonicalized to [60,200] via `_canonicalize`; `labelSource = "dsp_metadata_agreement"`; `labelConfidence = min(dspConfidence, 0.64)`, strictly below the Solid floor 0.65). Failing → `unsupervisedPool` (label-free). No parseable file metadata AND the **selected DSP result** confidence ≤ 0.40 (the function receives the selected `dsp_confidence`, not a candidate list) → `reject`.

**AC6 — Provenance-filter contract: typed guard + call-site audit (epic AC2, L641-643).**
**Given** the provenance-filter contract (FR-13),
**When** the survey runs,
**Then** path components, parent directory names, and Rekordbox-derived attributes (XML track IDs, playlist membership) are NEVER consulted as **tiering** evidence — enforced structurally by the AC5 typed `decide_tier` signature, and documented in `_bmad-output/ml-training/non-rekordbox-provenance-audit.md`, which enumerates the forbidden columns, states the load-bearing distinction (using the Rekordbox XML to **define pool membership** is set-partitioning, NOT per-file tiering evidence — DD #1), and records a grep-verification that covers BOTH the tiering module body AND every `decide_tier` **call-site argument expression** (`rg -i "playlist|path|rekordbox|artist|id3"` plus a check that the four args are sourced only from `{dspBPM, dspConfidence, fileMetadataBPM, audioHash}` columns) returning zero hits.

**AC7 — Sentinel exclusion by audioHash, fail-loud on missing sources (epic AC5, L653-655 / FR-17).**
**Given** the four DnB sentinels (Charly, Faraday_Bunker, Yin Yang, HEFT_Anagram 6) — all four located on disk; Charly in the pool itself, byte-identical to the OA300 copy,
**When** the survey runs,
**Then** it precomputes each sentinel's `audioHash` (`file_sha256`) from its on-disk path and force-sets `tier = reject` + warns on any row whose `audioHash` matches — regardless of metadata agreement; exclusion is by **audio content hash** (FR-13-clean), NOT title/filename match (which would violate FR-13). The precompute **fails loud** if any sentinel source path (under OA300 + `TONY_AUDIO_ROOT`) is unreadable — a silently-empty sentinel set is unacceptable (mirrors AC10 fail-loud discipline). For re-encoded near-copies the byte hash cannot catch, emit a **report-only** title/duration near-copy aid for manual review (a review aid, NOT a tiering input). The 8 expanded sentinels (numeric Rekordbox IDs) are structurally outside the pool; cross-check the 12-set report-only.

**AC8 — Source-distribution report: yield, octave-risk, and ablation-risk honesty (epic AC4, L649-651).**
**Given** the tiered survey,
**When** `_bmad-output/ml-training/non-rekordbox-source-distribution.md` is produced,
**Then** it presents before-and-after tables of (a) **genre proxy** (file-path hint → coarse buckets — *report-only, NEVER a tiering input*; its sole review purpose: let the reviewer judge whether the expansion **broadens** the domain or **reinforces** the DnB-heavy labeled corpus — a composition-balance judgment, not a per-file decision), (b) tempo histogram (60-200 BPM, 5-BPM bins), (c) source/format distribution (MP3/FLAC/M4A/WAV[/AIFF]), (d) tier counts; it reports the `secondarySupervised` **yield honestly** with a **threshold-sensitivity** table (tier counts at `0.03` vs `0.04`, and at the `0.40` reject floor) — and, if the supervised tier is small, names it explicitly as a **RISK to the KDD-B2 ablation** (a near-empty supervised-augmented arm makes the comparison foregone rather than fair — a JOB outcome, not just a number; do NOT loosen `0.03`/`0.40` to manufacture a larger tier); it carries the **octave-risk caveat** (a `secondarySupervised` label proves DSP↔tag *consistency*, not octave *correctness* — Tony's half-tempo pattern (FR-12) means DSP and tag can agree on the wrong fundamental; 7.3's octave-aware loss (FR-16) is the backstop). The report is **reference-linked from `corpus-diagnostics-v1.md`** (net-new link). KDD-B4 JSON+paired-Markdown convention.

**AC9 — Loadable, FR-15-clean downstream manifest for Story 7.3 (epic AC6, L657-659).**
**Given** Story 7.3's supervised-augmented loader must read audio bytes (so it needs a file locator) while its FR-15 grep gate (epics.md L699) forbids forbidden signals in loader CODE,
**When** the survey completes,
**Then** it emits `_bmad-output/ml-training/non-rekordbox-secondary-supervised-manifest.json` for the `tier == secondarySupervised` rows, carrying `audioHash` (identity/dedup key) + `relPath` (relative to `TONY_AUDIO_ROOT` — needed to FETCH BYTES; FR-15 forbids path as a model **feature**, not as a file **locator**) + `bpm_truth` + `labelConfidence`, and EXCLUDING the actual forbidden feature signals (playlist, genre-proxy, Rekordbox track-id, DSP candidate scores). The manifest header pins the `audioHash` derivation (`file_sha256`) so a future 7.3 edit cannot silently change the join key. The script header documents the 7.3-side obligation: 7.3's loader uses `relPath` ONLY to read bytes (never as a feature — its own L699 grep covers its loader code), reads `bpm_truth` as the label, and treats this manifest AS "the `tier == secondarySupervised` subset" (epics.md L657-659); the `unsupervisedPool` subset is reserved for the masked-mel variant. (When Story 7.3 is authored, its loader-input AC must point at this manifest — flagged for the 7.3 spec.)

**AC10 — Lint / ty / Make / uv wiring.**
**Given** the project's Python tooling discipline,
**When** the script lands,
**Then**: `mutagen` is added to `_bmad-output/ml-training/pyproject.toml` via `uv add`; `scripts/non-rekordbox-survey.py` is ruff-clean and ty-clean **with `../../scripts/non-rekordbox-survey.py` appended to the `py-lint` ty allowlist** (`Makefile`) — note `mutagen` may ship no `py.typed`, so a scoped `# ty: ignore[unresolved-import]` (or a minimal stub) on the import is acceptable and is NOT a script bug; the script runs via `uv run --project _bmad-output/ml-training python scripts/non-rekordbox-survey.py` (imports `corpus_common` + `mutagen`); a new develop-only `non-rekordbox-survey` Make target exists (modeled on `tony-survey`/`audit-corpus-splits`: fail-loud, **no emojis**).

**AC11 — Develop-only + zero accuracy impact.**
**Given** every 7.2 artifact is develop-only (DD #7),
**When** the story closes,
**Then** `git diff --stat Sources/` and `git diff --stat Tests/` are **empty** (the `--no-metadata` edit touches only the dev-only `swift_feature_extractor/` package — reachable via the existing public `MetadataPolicy.disabled`, no `Sources/` edit required); `make build` + `make test` stay green; OA300/GiantSteps benchmarks need not run; `uv run` not `python3`; no emojis.

**FRs covered:** FR-13, FR-15 (forbidden-input enforcement), FR-17 (sentinel exclusion).
**KDDs implemented:** B4 (source-distribution report folded into corpus diagnostics).

## Tasks / Subtasks

- [x] **Task 1 — Set derivation + 3-way partition + reconciliation** (AC: #1)
  - [x] Parse `<COLLECTION>` from `$(TONY_XML)` into a basename set; build `build_basename_index($(TONY_AUDIO_ROOT))`; subtract by basename (foreign-host paths preclude exact resolution).
  - [x] Expansion candidates = on-disk audio minus resolved paths; partition each into `analyzable` / `cloud_only` (0-byte) / `ambiguous_membership` (read the index's multi-entry buckets directly — NOT `resolve_one`'s first-match scalar).
  - [x] Assert count-in == count-out; report `analyzable` count + reconcile vs "~4,700" (snapshot; `4,686` is an upper bound on the subtrahend); emit the `skipped` buckets.

- [x] **Task 2 — Swift CLI `--no-metadata` flag (4 edits, one dev-only file)** (AC: #3, #11)
  - [x] In `swift_feature_extractor/Sources/tony-dsp-prepass/main.swift`: add `var noMetadata: Bool` to `CLI` (`:28`); add `case "--no-metadata"` (valueless) to `parse` (`:45-68`); thread it into `analyze(track:intensity:noMetadata:)` (`:175`); set `options.metadataPolicy = .disabled` (`:184`) when true. Default behavior (existing tony-corpus prepass) unchanged.
  - [x] `swift build -c release` green; confirm a tagged file's `bpm` no longer shifts toward its tag.

- [x] **Task 3 — Synthesized adapter + independent tags + audioHash + typed tiering** (AC: #2, #3, #4, #5, #6, #7)
  - [x] Compute `audioHash = corpus_common.file_sha256(path)` per `analyzable` file FIRST; synthesize the SurveyTrack JSON (`track_id = audioHash`, `name=""`, `artist=""`, `local_path`, `resolve_status="ok"`); invoke `tony-dsp-prepass --no-metadata`; join `DSPTrackResult.track_id == audioHash`.
  - [x] Parse `fileMetadataBPM` via `mutagen` (ID3 TBPM / MP4 tmpo / FLAC Vorbis `BPM=`).
  - [x] Implement pure typed `decide_tier(dsp_bpm, dsp_confidence, file_metadata_bpm, audio_hash)` with the ratio-family `k∈{0.5,1,2}` 0.03 predicate; three-way rule; `bpm_truth`/`labelSource`/`labelConfidence=min(dspConfidence,0.64)`.
  - [x] Precompute the 4 sentinel `file_sha256`es (fail loud if any source path unreadable); force `reject` + warn on match; emit the report-only near-copy aid + 12-set cross-check.

- [x] **Task 4 — Artifacts: survey JSON, loadable manifest, two MD reports** (AC: #2, #6, #8, #9)
  - [x] Emit `non-rekordbox-survey.json` (full, with `path` + `skipped` buckets) + the loadable `non-rekordbox-secondary-supervised-manifest.json` (`audioHash` + `relPath` + `bpm_truth` + `labelConfidence`; derivation pinned in header).
  - [x] `non-rekordbox-provenance-audit.md`: forbidden-column enumeration + membership-vs-tiering distinction + typed-guard + call-site grep result.
  - [x] `non-rekordbox-source-distribution.md`: tables (a)-(d) + yield + threshold-sensitivity + ablation-risk + octave-risk caveat (mirror `corpus_diagnostics.render_markdown` PATTERN — it is hardwired to the 7.1 shape, not a callable); append a reference link into `corpus-diagnostics-v1.md`.

- [x] **Task 5 — Make target + lint/ty/uv wiring** (AC: #10)
  - [x] `uv add mutagen`; add the `non-rekordbox-survey` Make target (develop-only, fail-loud, no emojis); append the script to the `py-lint` ty allowlist (scoped `# ty: ignore` on the mutagen import if needed).

- [x] **Task 6 — Verification gauntlet + close** (AC: #9, #11)
  - [x] `make non-rekordbox-survey` end-to-end; all artifacts at the AC paths; count-in == count-out holds; `make py-lint` (ruff + ty) green; sentinel exclusion fires on Charly; manifest has no forbidden column.
  - [x] `git diff --stat Sources/` + `Tests/` empty; `make build` + `make test` green; populate Dev Agent Record; flip story → review.

## Dev Notes

### Context — where this sits in Epic 7

Epic 7 retrains a TempoCNN-style model on Tony's corpus; FR-18 is a *promotion gate*. Story 7.2 is the **clean semi-supervised expansion pool** feeding Story 7.3's KDD-B2 ablation: `secondarySupervised` (labeled → supervised-augmented variant) and `unsupervisedPool` (label-free → masked-mel variant). The pool flows 7.2 → 7.3 → 7.5 → 7.7 (FR-24 net-benefit). 7.2 produces SEPARATE artifacts; it does **not** modify `corpus_splits.json`, so it does not reshuffle the Story-7.1 Tony split. **Guardrails (Codex):** v1 = scaffolding (7.2 produces no transferable accuracy claim); `featureSetVersion`/`WeightingProfile` are 7.3/7.5 concerns. The guardrail 7.2 carries: FR-15 forbidden inputs may inform tiering/labeling but must NEVER become model features — enforced by the typed `decide_tier` + the FR-15-clean manifest (AC9).

### Verified on-disk reality (factual-claims grep — re-verified through party-mode @ 80a55aa)

| Epic/spec assumption | On-disk reality | Action |
|---|---|---|
| Input dir `tony-corpus/non-rekordbox/` holds ~4,700 files | **Does NOT exist.** Audio at `TONY_AUDIO_ROOT=/Users/rterhaar/Dropbox/tony-tunes/` (6,407 audio: mp3 5642, wav 657, aiff 43, flac 34, m4a 17, aif 14) + `05092026.xml` (`<COLLECTION Entries="1721">`). XML `Location` = foreign host → basename is the only join. | DERIVE by basename subtraction + ambiguous-basename quarantine + 3-way partition (DD #1/#9). |
| DSP `bpm` is metadata-independent | **FALSE.** `analyzeBPM` default `metadataPolicy=.default` returns post-corroboration BPM (`AudioAnalysisService.swift:347`); CLI sets only `options.intensity` (`main.swift:184`). `0.03` window = library corroboration default. | Metadata-blind via `--no-metadata`→`.disabled` (`MetadataPolicy.swift:186`); independent `mutagen` (DD #2). |
| Swift CLI accepts an arbitrary file list | **FALSE.** `SurveyTrack` requires non-optional `track_id`/`name`/`artist` (`main.swift:101-104`); hard-filters `resolve_status=="ok"` at `:176` + `:294`. | Synthesize SurveyTrack JSON; `track_id=audioHash` join key; `"ok"` only for `analyzable` (DD #9). |
| Sentinels referenced by "audio hash" | Title-keyed (`track_id`=title); zero audio-hash fields project-wide. `content_hash()` path-derived (forbidden); `file_sha256` exists. | `audioHash=file_sha256` (DD #3); exclude by it + near-copy aid (DD #4). |
| Sentinel files reachable | All 4 located: OA300 `1./4./9.*.wav` + `T Tunes/…Charly….aiff`. **Charly ALSO in `tony-tunes/Drum and Bass/` — byte-identical (`b4ede99…`).** | Precompute 4 hashes; fail loud if source unreadable (AC7). |
| Python reads ID3/MP4/Vorbis BPM | **No** Python tag parser; **no `mutagen`** (`mutagen==1.47.0` resolves on PyPI). | `uv add mutagen`; parse independently (DD #2). |
| `resolve_one` gives the full duplicate set | **FALSE.** Returns first-match scalar (`survey.py:204`); `cloud_only`/`ambiguous` are statuses. | Read `build_basename_index` multi-entry buckets for quarantine (DD #1). |
| `corpus-diagnostics-v1.md` exists to link into | Exists; `REVIEWER_SIGNOFF: pending`. Zero `non-rekordbox` refs. | Append a reference link (AC8). |

### Design Decisions

**DD #1 — DERIVE the set by basename subtraction WITH ambiguous-basename quarantine + upfront 3-way partition; Rekordbox XML defines MEMBERSHIP, not tiering evidence.** The named input dir is absent. The XML `Location` attrs encode a foreign hostname (`/Users/echtoo-mbp/…`), so the XML records **cannot be resolved to exact local paths** — basename is the only available join (the same join the existing `tony-tunes-survey.py` uses). So: parse `<COLLECTION>` into a basename set; expansion = on-disk audio whose basename is NOT in that set. The risk of bare-basename subtraction (one collection `A.mp3` excluding every unrelated on-disk `A.mp3`) is handled NOT by path resolution (impossible here) but by **quarantine**: any basename with >1 on-disk copy is moved to `ambiguous_membership` (reported, excluded from BOTH tiers) rather than blindly subtracted. This is the conservative equivalent of resolved-path subtraction — it never over-excludes a real file, at the cost of quarantining genuinely-ambiguous basenames (86 files, reported). Partition every candidate into `analyzable`/`cloud_only`/`ambiguous_membership` and assert count-in == count-out. Do NOT physically create a `non-rekordbox/` dir. **Provenance distinction:** using the XML to decide *which files are non-Rekordbox* (membership) is partitioning, NOT a per-file **tiering** signal — FR-13/FR-15 forbid Rekordbox-derived signals as tiering evidence, never as the boundary scoping the universe (audited per AC6).

**DD #2 — Metadata-BLIND DSP + INDEPENDENT tag parser (the circularity fix).** `analyzeBPM` under default `metadataPolicy=.default` returns the post-corroboration BPM, so a "DSP vs tag" gate against it is self-fulfilling (and `0.03` matches the corroboration default). Fix: `dspBPM`/`dspConfidence` from `tony-dsp-prepass --no-metadata` (`options.metadataPolicy = .disabled` — verified at `MetadataPolicy.swift:186`/`AudioAnalysisService.swift:941` to suppress BOTH tag I/O and corroboration; `durationHint` is audio-derived and stays on, so the precise claim is **BPM-tag-blind**); `fileMetadataBPM` from an **independent** parser (`mutagen`). Independence is the architectural property that makes the gate sound; the accepted, bounded cost is **parser drift** (`mutagen` vs the library's `FileMetadataReader` may differ at the margins — sentinel-zero, malformed frames, multi-value tags). This is a dev-only diagnostic tool feeding an ablation that cares about signal *independence* far more than byte-matching the library parser, so the trade is made eyes-open. **Documented alternative:** all-Swift two-pass harvesting `result.metadataEvidence.parsedBPM` from a second `.default` pass — reuses the library parsers but doubles DSP cost and re-introduces the footgun of *ignoring* the corroborated `.bpm`. Either way the Swift edit is dev-only.

**DD #3 — `audioHash = file_sha256` (raw bytes); the "re-encode-robust" overclaim is dropped.** `content_hash()` is sha1 of `path|size|mtime` — path-derived, FR-13-forbidden. Use `file_sha256` (raw-byte SHA-256): deterministic, content-derived, catches exact-file duplicates (verified for the byte-identical Charly leak), NOT re-encode-robust (documented; near-copies → DD #4 report-only aid). `audioHash` does triple duty: survey identity, the CLI read-back join key (DD #9), and the manifest key (AC9).

**DD #4 — Sentinel exclusion by `audioHash`, resolving the FR-13 "audio hash" vs forbidden-path tension.** Fixtures are title-keyed; no audio hash exists. Title/filename match would violate FR-13. Resolution: precompute the 4 sentinels' `file_sha256` from their located paths (fail loud if a source is unreadable — AC7) and force `reject` on `audioHash` match (FR-13-clean). Charly genuinely sits in the pool, so this fires. Re-encoded near-copies → a report-only title/duration aid (a manual-review aid, NOT a tiering input).

**DD #5 — Typed `decide_tier` guard; the agreement predicate is NET-NEW (ratio-family, band-edge-safe).** The tier decision is a pure function whose signature physically excludes `path`/playlist/XML-id (the type is the guard; the AC6 grep — now covering call-site arg expressions — is secondary). The reuse map covers the *canonicalization primitives* (`_canonicalize`, `_canonical_ratio`, `_near_pct`), but the **agreement comparison is authored**: `any(|m - k*d|/max(m,k*d) <= 0.03 for k in (0.5,1,2))`. This ratio-family check is deliberately NOT `_canonicalize(a)==_canonicalize(b)` — canon-equality can differ for true octave pairs near the 60/200 band edges. `render_markdown` (`corpus_diagnostics.py:622`) is hardwired to the 7.1 diag shape → a PATTERN to mirror, not a callable. The new tier vocabulary (`secondarySupervised/unsupervisedPool/reject`) is **orthogonal** to Strong/Solid/Marginal/Reject (label-confidence) — do not overload `tier_for`.

**DD #6 — `bpm_truth` = metadata-blind DSP; consistency ≠ correctness (octave-risk caveat).** Store `bpm_truth` = the octave-normalized **metadata-blind DSP** BPM (audio-derived → FR-15-clean; the tag only corroborates via the gate), `labelSource = "dsp_metadata_agreement"`, `labelConfidence = min(dspConfidence, 0.64)` (below the Solid 0.65 floor). This is only sound BECAUSE DD #2 makes the DSP blind. **Caveat (carry into AC8):** the agreement gate proves DSP↔tag *consistency*, NOT octave *correctness* — when DSP picks the wrong fundamental (Tony's half-tempo pattern, FR-12) and the tag happens to agree, `bpm_truth` enshrines the DSP octave error. 7.3's octave-aware loss (FR-16) is the trainer-side backstop; the source-distribution report must state this so a reviewer does not read "agreement = correct."

**DD #7 — develop-only + zero accuracy impact.** All artifacts develop-only (`scripts/`, `_bmad-output/ml-training/`, `Makefile`, `mutagen`, the dev-only `swift_feature_extractor/` `--no-metadata` edit — reachable via public `MetadataPolicy.disabled`, so no `Sources/` edit). Zero `Sources/` + `Tests/` changes → runtime byte-unchanged → accuracy gates need not re-run. No emojis; `uv run` not `python3`.

**DD #8 — Pressure-release (epic: None) + yield/threshold/ablation integrity.** DnB tracks frequently lack clean ID3 TBPM, so `secondarySupervised` may be small. Report the yield + a threshold-sensitivity table honestly; **never** loosen `≤0.03` or the `0.40` reject floor to manufacture a larger tier (poisons the "clean pool" premise). Additionally — a near-empty supervised tier is a **JOB outcome, not just a number**: it leaves 7.3's supervised-augmented arm underpowered and the KDD-B2 comparison foregone rather than fair, so the source-distribution report must name a small supervised tier as an explicit **RISK to the ablation** (not silently pass a yield count). 7.2 does not touch `corpus_splits.json` (7-1-D1 instability N/A).

**DD #9 — The synthesized Python-walk → Swift-CLI adapter contract (the integration seam).** The non-Rekordbox files have no XML record, but `tony-dsp-prepass` decodes a fixed survey shape with non-optional `track_id`/`name`/`artist` and hard-filters `resolve_status == "ok"` at `main.swift:176` + `:294`. The survey therefore SYNTHESIZES a SurveyTrack JSON per `analyzable` file: `track_id = audioHash` (the stable+unique join key — `DSPTrackResult.track_id == audioHash` on read-back; a path-derived synthetic id would be a provenance smell), `name=""`/`artist=""` (empty strings satisfy the non-optional decode), `local_path`, `resolve_status="ok"`. **Only `analyzable` files get `"ok"`** — `cloud_only`/`ambiguous_membership` are partitioned OUT in Python (AC1) so the CLI's `"ok"`-filter cannot silently defeat AC1's no-silent-drop promise. The count-in == count-out reconciliation (Task 1/6) closes the seam: every walked candidate ends in exactly one of {DSP-result row, `cloud_only`, `ambiguous_membership`}.

### Project Structure Notes

- New Python at `scripts/non-rekordbox-survey.py` — develop-only, kebab-case, sibling of `tony-tunes-survey.py`. Runs via `uv run --project _bmad-output/ml-training python scripts/non-rekordbox-survey.py` (imports `corpus_common` + `mutagen`). NEVER `Sources/`/`Tests/`/`tools/`/`main`.
- Swift edit confined to `swift_feature_extractor/Sources/tony-dsp-prepass/main.swift` (add `--no-metadata`, 4 sites: `CLI` struct, `parse`, `analyze` signature, `.disabled` set) — dev-only package.
- New `Makefile` target `non-rekordbox-survey` (develop-only, fail-loud, no emojis). ty allowlist edit to `py-lint` mandatory; ruff auto-covers `scripts/`. `mutagen` added via `uv add` to `_bmad-output/ml-training/pyproject.toml`.
- Branch/PR: `rterhaar/7-2` off `rterhaar/epic-7`; PR base `rterhaar/epic-7` (never touch `develop`).

### Testing standards

- Python-prefix: the survey + provenance-audit run clean end-to-end; the count-in==count-out reconciliation holds (AC1/DD #9); the typed-tiering grep (AC6) is zero-hit at module body AND call sites; sentinel exclusion fires on Charly (AC7); the manifest has no forbidden column and resolves `relPath` to a readable file (AC9).
- Swift: `swift build -c release` the dev-only `swift_feature_extractor` green (the `--no-metadata` flag compiles + yields BPM-tag-blind DSP). NO shipping-library `@Test` work; `make build`+`make test` green; accuracy benchmarks need not run.

### References

- Story 7.2 epic: `epics.md#L629-L663`; Epic 7 preamble + guardrails: `#L585-L588` + `#L292-L296`; corpus framing `#L284`. Downstream: 7.3 `#L665-L703` (FR-15 `rg` gate L699; loader-input AC L657-659; entrypoints L673); 7.7 FR-24 `#L853-L855`.
- FRs: active PRD `prds/prd-BoomBoomBoomKit-2026-05-25/prd.md` — **FR-13** (L79, "audio-derived DSP + generic file-metadata agreement"), **FR-15** (L83), **FR-17** (L87), FR-12 (L77), FR-14 (L81), FR-16 (L85, octave-aware loss — the AC8 octave-risk backstop), FR-22 (L97), FR-24 (L101).
- Circularity / `.disabled` evidence: `AudioAnalysisService.swift` (post-corroboration return ~L347; `metadataPolicy=.default` L270; gate on `enabledSources.isEmpty` ~L941); `MetadataPolicy.swift:186` (`disabled` public); `SignalPool/MetadataCorroborator.swift` (no-op when no tags participate).
- Swift CLI: `swift_feature_extractor/Sources/tony-dsp-prepass/main.swift` (`CLI` L28; `parse` L45-68; `SurveyTrack` L101-114 [non-optional `track_id`/`name`/`artist`]; `analyze` L175-185 [`var options` L184]; `"ok"` filters L176 + L294).
- Reuse — `corpus_common.py` (`file_sha256` L168 [audioHash], `content_hash` L400 [forbidden], `tier_for` L77 [Solid floor 0.65, do not overload]); `scripts/tony-tunes-survey.py` (`build_basename_index` L161, `resolve_one` L178/L204 [first-match scalar — use index buckets for quarantine]); `scripts/tony-tunes-labels.py` (`_canonicalize` L471, `_near_pct` L465); `corpus_diagnostics.py` (`_canonical_ratio` L127, `render_markdown` L622 [pattern, not callable]).
- Sentinels: `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/{4-dnb-triplet-targets.json (track_id=title), 12-dnb-sentinels-expanded.json (JAMS)}`. On-disk: OA300 `1./4./9.*.wav` + `T Tunes/…Charly….aiff`; Charly also `tony-tunes/Drum and Bass/…Charly….aiff` (byte-identical).
- Upstream (link/cross-check, do NOT modify except the AC8 link): `_bmad-output/ml-training/{corpus-diagnostics-v1.md, corpus_splits.json (schema_version 2), label-tier-policy-v1.md}`.
- Raw corpus (develop-local/gitignored): `/Users/rterhaar/Dropbox/tony-tunes/` (`05092026.xml`, ~6,407 audio). Makefile: `TONY_XML`, `TONY_AUDIO_ROOT`, `tony-survey`/`tony-dsp-prepass`/`audit-corpus-splits`/`py-lint`.
- Conventions: CLAUDE.md (develop-vs-main; `scripts/` + `_bmad-output/ml-training/` develop-only); project-context.md (banned shapes L182-183; `uv run` L134); MEMORY.md (no emojis; `uv run`; factual-claims grep).

## Dev Agent Record

### Agent Model Used

claude-opus-4-8 (Opus 4.8) via bmad-dev-story (ultracode). Pre-dev spec hardened by axiom:ask (axiom-concurrency) + Codex round 2 + party-mode (Mary/Winston/Amelia/John); all findings integrated before implementation.

### Debug Log References

- **Swift `--no-metadata` verification:** confirmed in-code that `MetadataPolicy.disabled` (`enabledSources: []`) short-circuits `buildMetadataInput` to zero tag I/O + empty corroboration input (`AudioAnalysisService.swift:941`), so `result.bpm` under the new flag is pure DSP. The CLI emits `metadata.no_metadata` and the survey hard-asserts it (`run_dsp_prepass`), failing loud if the prepass ever ran corroborated (DD #2 guard).
- **`decide_tier` unit verification** (direct calls): agreement→secondarySupervised (bpm_truth canonicalized, labelConfidence capped 0.64); octave pair `(dsp 87, tag 174)`→secondarySupervised (ratio-family `k∈{0.5,1,2}` works); `(no meta, dsp 0.3≤0.40)`→reject; `(dsp 0.5>0.40, no meta)`→unsupervisedPool; sentinel hash-match→reject override fires.
- **Full run** (`make non-rekordbox-survey`, 2026-06-01): derivation reconciled count-in==count-out (no SystemExit); DSP `--no-metadata` over 5,060 files in 87.6s (4,765 ok / 295 undecodable→null dspBPM, gracefully tiered); tiers secondarySupervised=2,173 / unsupervisedPool=2,417 / reject=470; manifest=2,173 rows.

### Completion Notes List

- **All 11 ACs satisfied; all 6 tasks complete.** Develop-only: zero `Sources/` + zero `Tests/` diff (`git diff --stat` both empty — the Swift edit is the dev-only `swift_feature_extractor/` CLI, reachable via the public `MetadataPolicy.disabled`); `make build` + `make test` green (**483 tests / 105 suites**, unchanged baseline); `make py-lint` green (ruff + ty, the new script in the ty allowlist).
- **Reality-correction vs spec Dev Notes (DD #4 / table):** Charly is in Tony's Rekordbox `<COLLECTION>` (`charly` basename ∈ collection set, verified), so it is correctly excluded UPSTREAM as in-collection and never reaches the expansion pool — the spec's "Charly genuinely sits in the non-Rekordbox pool" overstated it. The audioHash force-reject (AC7/DD #4) is proven to fire on hash-match and remains armed as defense-in-depth; it simply did not need to here. All 4 sentinels were located + hashed (charly resolved to 2 copies across OA300 + tony-tunes); fail-loud precondition exercised (did not trip).
- **Mary CB3 validated:** analyzable=**5,060**, not "~4,700" — resolution is lossy (only 1,632 of 1,721 collection records resolve to on-disk basenames; 1,261 in-collection singletons removed; 86 ambiguous_membership quarantined; 0 cloud_only), so the expansion set is LARGER than the `6,407−1,721≈4,686` upper bound, exactly as AC1's "snapshot, not coerced" framing anticipated.
- **John/DD #8 yield risk did NOT materialize:** secondarySupervised=2,173 (Tony's DJ library is well-TBPM-tagged); the source-distribution report's `<50` ablation-risk clause therefore did not fire. Threshold sensitivity: 0.03→2,173 vs 0.04→2,181 (+8), confirming 0.03 is not artificially restrictive. Octave-risk caveat (DD #6) present in the report; tempo histogram peaks at 170-174 (2,721) — the DnB signature; genre proxy shows the expansion REINFORCES the DnB-heavy domain (4,923/5,060).
- **Manifest is FR-15-clean + loadable (AC9):** exactly `{audioHash, relPath, bpm_truth, labelConfidence}` — zero forbidden columns (no path/playlist/genre/track_id/dsp-candidate); relPath resolves for byte fetch; `file_sha256` derivation pinned in the header. All 2,173 secondary rows carry `bpm_truth`+`labelSource`+`labelConfidence`≤0.64 (0 violations).
- **Artifact policy:** `non-rekordbox-survey.json` (2.3 MB, absolute paths) is gitignored as a regenerable intermediate (mirrors 7.1's fingerprint-cache); the portable hash-keyed manifest (518 KB, the 7.3 contract) + the two reviewable `.md` reports are committed; the `corpus-diagnostics-v1.md` reference link was appended (AC8).
- **Pending operator:** final commit on the 1Password GPG signer (suggested: `Story 7-2: non-Rekordbox audio expansion + provenance-clean tiering`); open PR base `rterhaar/epic-7`. The `--no-metadata` Swift edit is develop-only (`swift_feature_extractor/`) — main-bound diff is empty.

### File List

New (develop-only):
- `scripts/non-rekordbox-survey.py` — the survey/tiering CLI (derivation, synthesized adapter, mutagen tags, typed `decide_tier`, sentinel exclusion, artifact emit).
- `_bmad-output/ml-training/non-rekordbox-secondary-supervised-manifest.json` — the FR-15-clean, hash-keyed Story 7.3 contract (committed).
- `_bmad-output/ml-training/non-rekordbox-source-distribution.md` — reviewable source-distribution report (committed).
- `_bmad-output/ml-training/non-rekordbox-provenance-audit.md` — reviewable provenance audit (committed).
- `_bmad-output/ml-training/non-rekordbox-survey.json` — full per-file survey (gitignored; regenerable via `make non-rekordbox-survey`).

Modified (develop-only):
- `_bmad-output/ml-training/swift_feature_extractor/Sources/tony-dsp-prepass/main.swift` — `--no-metadata` flag (`CLI` field + parse case + `analyze`/`runBatch` threading + `options.metadataPolicy = .disabled` + `metadata.no_metadata` provenance).
- `Makefile` — `non-rekordbox-survey` target + `../../scripts/non-rekordbox-survey.py` appended to the `py-lint` ty allowlist.
- `_bmad-output/ml-training/pyproject.toml` + `uv.lock` — added `mutagen` (`uv add`).
- `_bmad-output/ml-training/corpus-diagnostics-v1.md` — appended the source-distribution reference link (AC8).
- `.gitignore` — ignore the regenerable `non-rekordbox-survey.json`.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — 7-2 ready-for-dev → in-progress → review.

Zero changes under `Sources/` or `Tests/` (verified).

### Change Log

- 2026-06-01 — Implemented Story 7.2 (non-Rekordbox audio expansion + provenance-clean tiering) per the 11-AC / 6-task spec. Status ready-for-dev → review.
- 2026-06-01 — Code-review patch round (bmad-code-review, 4 adversarial layers + extra blind-hunter). 14 fixes applied, 3 dismissed. Re-verified green; artifacts regenerated. Status review → done.

## Senior Developer Review (AI)

**Reviewed:** 2026-06-01 — bmad-code-review on the uncommitted Story 7.2 diff (baseline `80a55aa`). **Outcome: Approve (post-patch).**

Four parallel adversarial layers (Blind Hunter A, **a second Blind Hunter** per operator request, Edge Case Hunter, Acceptance Auditor) reviewed the new `scripts/non-rekordbox-survey.py` (745 lines) + the `--no-metadata` `main.swift` edit + the Makefile. ~25 raw findings triaged → **14 patched, 3 dismissed**. The Swift `--no-metadata` edit was independently confirmed correct + concurrency-safe by every layer. Post-patch: `make py-lint` (ruff + ty) green, `make build` + `make test` (483/105) green, `git diff Sources/`+`Tests/` empty, artifacts regenerated.

**Headline fixes (Med→real):**
- **Duplicate-`audioHash` join collision** (Blind A+B+Edge): 15 hashes / 294 identical-byte files (the undecodable ones) shared a join key → would corrupt the 7.3 manifest. Now deduped first-path-wins before DSP; manifest re-verified **2,172 rows / 2,172 distinct hashes / 0 duplicate keys**. (Side effect: DSP errors 295→13, reject 470→187.)
- **AC7 near-copy aid + 12-set cross-check were NOT implemented** (Acceptance Auditor — the one material claim-vs-code gap): both now implemented report-only (`build_sentinel_review`), with the 12-set title match tightened to specific titles (≥10 chars) so generic titles ("Dream"/"BOO") don't drown the aid (48→2 matches).
- **AC8 0.40-floor sensitivity datapoint** (Auditor): added as a sensitivity-table row (174 floor-rejects) alongside 0.03/0.04.

**Robustness fixes:** `file_sha256` TOCTOU wrap (skip+report unreadable); 0-byte sentinel skip + fail-loud-if-only-0-byte (a 0-byte placeholder would hash empty bytes and silently defeat FR-17); Vorbis `vals[0]` index guard (`_first`); `decide_tier` finite guards (NaN/Inf can't escape the reject floor); DSP read-back reconciliation (warn on missing join); `json allow_nan=False`; clean `SystemExit` on subprocess failure / missing output; `.get` read-back; stale sentinel `agreementDeltaPct` cleared on force-reject so it can't inflate the `at_04` recount; skipped-bucket paths all relativized.

**Dismissed (real but spec-correct / acknowledged):**
- "Reject-floor bypassed when metadata present → low-confidence secondary labels" (Blind B High): **spec-correct** — AC5 defines secondary = agreement; DD #6's `labelConfidence = min(dspConf, 0.64)` deliberately carries the low confidence forward (verified min 0.37, **no 0.0** in the data) so 7.3 can weight it. Not a bug; the spec design intentionally keeps tag-corroborated low-DSP-confidence agreements as weak labels.
- Half-tempo `bpm_truth` enshrinement (Blind A/B): acknowledged in the DD #6 octave-risk caveat (FR-16 is the backstop).
- `dsp_conf <= 0.40` inclusive reject: matches the spec's "≤ 0.40 → reject" wording.

### Review Follow-ups (AI)

- [x] [Med] Dedup analyzable by `audioHash` (first-path-wins) — the manifest join key must be 1:1.
- [x] [Med] Implement AC7 report-only title near-copy aid (flag re-encodes the byte hash misses).
- [x] [Med] Implement AC7 12-set title cross-check (specific-title-only to avoid noise).
- [x] [Med] Add AC8 0.40-reject-floor sensitivity datapoint to the report.
- [x] [Med] Guard Vorbis `vals[0]` indexing; broaden the tag-read try so a malformed tag can't crash the survey.
- [x] [Med] Wrap `file_sha256` (TOCTOU/unreadable → skip+report, count-reconciled).
- [x] [Med] Skip 0-byte sentinel files in precompute; fail loud if a needle resolves only to 0-byte placeholders.
- [x] [Med] Clear force-rejected sentinel `agreementDeltaPct`; exclude reject rows from the `at_04` sensitivity recount.
- [x] [Med] DSP read-back reconciliation — warn on any submitted hash absent from the CLI output.
- [x] [Low] `decide_tier` finite guards (NaN/Inf BPM/confidence treated as absent).
- [x] [Low] `json.dumps(..., allow_nan=False)` on both JSON artifacts.
- [x] [Low] Read-back uses `.get("track_id")`; clean `SystemExit` on subprocess failure / missing output.
- [x] [Low] Relativize all skipped-bucket paths (cloud_only / ambiguous / duplicate / unreadable).
- [x] [Low] Emit `duplicate_audio_hash` + `unreadable` skipped buckets in the survey + report.

**Codex diff-review round (post-commit `e1d74ee`, 3 should-fixes applied; verdict: correct, no blocking, appropriately scoped):**

- [x] [Should-fix] DSP read-back gap now **fails loud** (was warn-only) — a submitted track absent from the CLI output is an adapter-contract violation (one result row per submitted track), not normal data quality (DD #9).
- [x] [Should-fix] Sentinel hashing now tracks per-needle successful hashes and **fails loud if zero hashed** (previously a needle whose every matched file was unreadable would silently contribute no hash); log reports the successful count, not the matched count.
- [x] [Should-fix] Corrected terminology across spec + code + comments: the derivation is **basename subtraction with ambiguous-basename quarantine**, NOT "resolved-path subtraction" — the XML `Location` foreign-host paths make exact resolution impossible, so basename is the only join; the quarantine (not path resolution) is what prevents over-exclusion.
- Codex "cut for simplicity" callouts (12-set title cross-check, generated provenance-audit report) NOT cut — both are spec-mandated (AC7 defense-in-depth / AC6 audit artifact); cutting would re-open the Acceptance Auditor's gap. Surfaced to the operator as an optional spec-trim.
