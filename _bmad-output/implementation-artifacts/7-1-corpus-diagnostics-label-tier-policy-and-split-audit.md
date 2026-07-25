---
baseline_commit: 07a235375a0eba32bcdb789c8742debd34db13f0
---

# Story 7.1: Corpus diagnostics + label-tier policy + split-contamination audit

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Spec validation history

- **2026-05-31 — party-mode (Mary/analyst, Winston/architect, Amelia/dev, John/PM) + Codex adversarial review.** All five reviewers inspected the live corpus on disk, surfacing data-substrate gaps the planning docs hid. 30+ findings triaged; the correctness-critical set is folded in below. Headline: **Codex found an undetected Tony→OA300 train/eval leak** (~46 of 49 normalized-title overlaps are very likely the same recording — Tony is TRAIN, OA300 is the FR-18 promotion gate, and `dataset.py::_verify_no_leak` only covers OA300↔GiantSteps, never Tony) → new AC5 (cross-corpus overlap audit + exclusion). Other accepted findings: AC7 DnB subgenre has no machine-readable field → curator-assigned by ear (DD #8); leave-artist-out needs a canonical artist key, not raw Rekordbox strings, with 43 empty-artist tracks handled (DD #4); `labelSourceBias` is 4×4 not 5×5 (signal 3 structurally absent) (DD #6); `corpus_splits.json` must namespace `tony.*`/`externalEval.*` + bump `schema_version` (DD #2); near-dup needs real fingerprinting, not chroma-cosine, all-pairs (DD #3); KDD-B4 signoff shipped as `--check-gate` code + checklist (DD #7); exact half-open tier bounds, single-source-truth policy, labeler/corpus version+hash pinning with a drift-**block** threshold, and loud-fail on decode/resolution failures (DD #1, AC9). **Operator decision (kept):** n=12 sentinel curation stays in 7.1 (Codex recommended splitting it out; PM kept it per the epic).
- Tier histogram reconciles **exactly** to the PRD snapshot (Strong 333 / Solid 745 / Marginal 241 / Reject 25) on the current develop-local corpus — confirmed by three independent reviewers. Counts are a snapshot, not a contract (FR-14 says "currently"); the corpus file is gitignored/develop-local, so AC9 pins its hash.

## Story

As a library maintainer,
I want the 1,344-track hand-labeled corpus diagnosed (label-source bias, octave ambiguity, confidence calibration of the disagreement signals, cluster stability, representative manual-review findings) and tiered (Strong / Solid / Marginal / Reject), with `corpus_splits.json` audited for related-recording leakage across train/val/test boundaries **and across the Tony↔external-eval boundary**, and a leave-artist-out slice committed,
so that the Epic 7 training run begins only on evidence-reviewed data behind a documented label-tier policy and split-contamination guards — satisfying KDD-B4's "produced + reviewed BEFORE training begins" gate.

This is the **Python prefix** of Epic 7 (Codex PHASED verdict): pre-substrate-safe, no Swift dependency, may run in parallel with the (now-complete) Epic 6. It produces the reusable corpus-prep / diagnostics / audit plumbing that the substrate-bound training run (Story 7.5) and the FR-18 promotion-gate evaluation (Story 7.6) consume. Per Guardrail 1, anything model-weight-shaped is out of scope — this story produces *evidence and policy*, not a model.

## Acceptance Criteria

**AC1 (FR-12) — Corpus diagnostics artifact.**
**Given** `_bmad-output/ml-training/corpus-diagnostics-v1.json` and `_bmad-output/ml-training/corpus-diagnostics-v1.md` are produced by a diagnostics generator run against the 1,344 hand-labeled tracks in `_bmad-output/ml-training/tony-corpus/tony-truth-labels.json`,
**When** the generator runs,
**Then** the JSON carries:
- `labelSourceBias` — a **4×4** agreement matrix over the labeler's exactly-emitted disagreement signals `{rekordbox_average, grid_bpm, dsp, playlist}` (DD #6); signal 3 (`grid_spacing` / inter-Inizio) is reported as a documented **structural absence** (coverage 0, no key emitted) — NOT a sparse signal;
- `octaveAmbiguityRate` — fraction of resolvable tracks where Rekordbox `AverageBpm` vs DSP winner form a 2:1 ratio within the labeler's 0.04 tolerance;
- `labelOctaveErrorAudit` (E1) — a half/double **label-error** estimate distinct from signal disagreement: sample Strong+Solid tracks where `bpm_truth ≈ 2× Rekordbox AverageBpm` AND only the half-time-boosted cluster carried the winner, flag as candidate confidently-wrong labels (this catches the dangerous high-margin/wrong-octave class that `octaveAmbiguityRate` and `truth_confidence` both miss);
- `confidenceCalibrationByTier` — per-tier mean `truth_confidence` + ECE; **this ECE measures label-confidence calibration, NOT model calibration — it produces no transferable FR-18 metric (Guardrail 2)**;
- `clusterStability` — k-means stability across ≥ 5 seeds via `scipy.cluster.vq.kmeans2` (the no-HALT path; `scikit-learn` is not a dependency);
- `representativeManualReviewFindings` — ≥ 10 named tracks, each with a non-empty `note`, **≥ 2 of which are drawn from the Marginal band** so the Marginal cohort provably appears in the diagnostics (KDD-B4 item (ii));

and the Markdown sibling is falsifiably structured: it contains **one `##` section header per top-level JSON key** (so "reviewer-readable" is grep-checkable, not a stub).

**AC2 (FR-14) — Label-tier policy with exact bounds.**
**Given** `_bmad-output/ml-training/label-tier-policy-v1.md` is authored,
**When** the policy is reviewed,
**Then** it codifies the tiers with **exact half-open intervals** on `truth_confidence`: Strong `[0.80, ∞)`, Solid `[0.65, 0.80)`, Marginal `[0.55, 0.65)`, Reject `[0.0, 0.55)` **plus** all `bpm_truth == null` abstentions (M2 — boundary records exist at exactly 0.65 and 0.80; they land in the higher tier); declares Strong + Solid the initial supervised set (1,078 target per FR-14) and Marginal + Reject excluded; states an explicit **single-source-truth trainability policy** (the labeler flags `single_source_truth` but still assigns `bpm_truth` — the policy MUST decide whether Strong/Solid single-source tracks are trainable, and document the count) (M3); and quotes **KDD-B3's 5 reopen triggers verbatim** (see Dev Notes; pin the citation to the header text, not a line number).

**AC3 (FR-15) — Forbidden-input enumeration.**
**Given** the audio-only model constraint (FR-15),
**When** the tier policy is reviewed,
**Then** it explicitly enumerates the forbidden model inputs — playlist names, file-path components, Rekordbox-specific signals, DSP candidate scores, artist embedding, ID3 BPM — and confirms each is excluded from any future feature-pipeline contract (these signals may inform *labeling* but never become *model features*). Note for the author: the corpus's only genre-adjacent signal is `signals.playlist.names`, which is itself an FR-15-forbidden curator artifact — it may seed by-ear curation (AC7) but must never enter a feature contract.

**AC4 (FR-22 within-Tony) — Namespaced split + near-dup audit.**
**Given** `_bmad-output/ml-training/corpus_splits.json` is regenerated with the Tony split nested under explicit namespaces (`tony: {train, val, leaveArtistOut}`, `externalEval: {giantsteps, oa300}`) and `schema_version` bumped (DD #2 — the existing flat `train/val/test` keys mean GiantSteps/OA300 and MUST NOT be overloaded), and `scripts/audit-corpus-splits.py` runs against it,
**When** the audit runs,
**Then** zero alternate-encode pairs, edit pairs, or near-duplicate fingerprints (DD #3 fingerprint method) cross the `tony.train` / `tony.val` / `tony.leaveArtistOut` boundaries; the audit exits non-zero on any contamination; a stale-shape consumer (flat `train/val/test` read as Tony) fails loud against the bumped `schema_version`.

**AC5 (FR-22 cross-corpus — the leakage blocker, B1) — Tony↔external overlap audit + exclusion.**
**Given** Tony is the *training* corpus and OA300 + GiantSteps are *external held-out eval* corpora feeding FR-18 gates (OA300 Acc1 > 55/82; GiantSteps Acc1 ≥ 537/661),
**When** the audit runs,
**Then** it detects related-recording overlaps between the Tony trainable set and BOTH OA300 and GiantSteps (normalized-title + artist + duration metadata match as the precise first pass — empirically catches the ~46 known same-recording overlaps; DD #3 fingerprint as the defensive second pass), **EXCLUDES every matched Tony track from the trainable set before train/val assignment** (detect *and remove*, not merely assert), records the excluded set + rationale in the audit output, and exits non-zero if any Tony training/validation track still matches an external-eval track; the 4 named DnB triplets (Charly / Faraday_Bunker / Yin Yang / HEFT_Anagram) are confirmed removed (the `Charly (Neekeetone Jungle Rework)` title-collision in Tony is excluded to be safe and documented as a rework, not the OA300 recording). `dataset.py::_verify_no_leak` covered only OA300↔GiantSteps; this AC is the missing Tony coverage.

**AC6 (FR-22 leave-artist-out) — Canonical-key disjoint artist slice.**
**Given** the leave-artist-out evaluation slice is part of the split contract,
**When** `corpus_splits.json` is audited,
**Then** `tony.leaveArtistOut: {trainArtists: [...], heldOutArtists: [...]}` is present and the two sets are disjoint **on a canonical artist key** (DD #4 — NOT the raw Rekordbox `artist` string: split collaborations on `&`/`,`/`feat`/`and` to a primary artist, name-parse the **43 empty-artist trainable tracks**, best-effort typo/alias merge with documented residue); empty-artist tracks are excluded from BOTH the held-out slice AND the disjointness assertion with their count documented; the held-out tracks (counted from named artists only) are sized ≥ 10% of the trainable set (≥ ~108), for Story 7.6's FR-23 octave-policy-consistency report; the audit verifies disjointness on the canonical key.

**AC7 (FR-18 gate (a) — n=12 expanded sentinels, kept in 7.1).**
**Given** Mary #3's n=12 DnB-sentinel-expansion requirement (FR-18 gate (a)),
**When** Story 7.1 closes,
**Then** 8 additional DnB tracks are curated as expanded sentinels per `_bmad-output/ml-training/expanded-sentinels-curation.md`: subgenre is **curator-assigned by ear** (DD #8 — no `subgenre` field exists in the corpus; the only programmatic stratification input is source-confidence quintile + tempo band), targeting 2 tracks per subgenre {neurofunk, jungle, jump-up, liquid} from Strong + Solid, favoring **representative** over adversarial-hard tracks; the 12-track **identifier manifest** (4 original + 8 expanded — NOT an audio-hash list; re-express the 4 originals from the canonical schema-v3 `Tests/.../4-dnb-triplet-targets.json`, not the diverged `_bmad-output/implementation-artifacts/` copy) is committed to `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/12-dnb-sentinels-expanded.json` in **JAMS format** (DD #5); `scripts/audit-corpus-splits.py --check-sentinels-against 12-dnb-sentinels-expanded.json` schema-validates the JAMS skeleton AND returns zero contamination against Tony train+val. The DD #8 valve (drop to ≥ 1-per-subgenre) is **expected to fire** given subgenre thinness — document the asymmetry, never substitute non-DnB tracks.

**AC8 (KDD-B4 gate — executable, C5) — Review gate shipped as code.**
**Given** the KDD-B4 "produced + reviewed before training begins" gate,
**When** the artifacts are produced,
**Then** `corpus-diagnostics-v1.md` carries a **structured reviewer-signoff checklist** (not a bare line) the operator fills by transcribing what they verified — tier histogram value, count of findings reviewed, count of octave-conflict tracks spot-checked against audio with track IDs — initialized to a `REVIEWER SIGNOFF: pending` state; AND `scripts/audit-corpus-splits.py --check-gate` exits non-zero while the signoff is `pending` and zero once signed (one executable source of truth Story 7.5's `train.py` precondition calls — 7.1 does NOT implement the `train.py` precondition itself); AND the story explicitly states **7.1 "done" = evidence assembled + review pending, NOT corpus-safe-to-train** — that flips only when the operator signs.

**AC9 (M1 + M4) — Provenance pinning + loud failure.**
**Given** the corpus is develop-local/gitignored and silently filtered,
**When** the diagnostics + split are produced,
**Then** `corpus-diagnostics-v1.json` pins the **labeler script version/hash + the input corpus file hash** (so a regenerated label file is detectable); a **drift-block threshold** is documented (tier-count drift beyond the threshold, or any tier crossing a documented bound, BLOCKS training pending review — not merely "documented"); and decode / path-resolution failures are surfaced **loudly** (the labeler silently filters `resolve_status == "ok"` and the builder skips missing audio with counters only — the diagnostics MUST report the resolved-vs-total count and list unresolved tracks, never silently shrink the corpus).

**AC10 — Reconciliation-shows-work + branch/scope discipline.**
**Given** tiers are computed from `truth_confidence` (DD #1),
**When** the histogram is produced,
**Then** the **computed** histogram is emitted into `corpus-diagnostics-v1.json` (showing `333/745/241/25` derives from banding `truth_confidence`, not from transcribing the PRD) and reconciled against the PRD snapshot with any drift documented as a snapshot delta (NOT coerced — FR-14 says "currently"); AND all Story 7.1 artifacts are develop-only EXCEPT `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/12-dnb-sentinels-expanded.json` (ships to `main`, sibling of `4-dnb-triplet-targets.json`); zero `Sources/` changes; `make build` + `make test` mechanically unchanged (no Swift behavior touched — OA300/GiantSteps accuracy gates need not run; assert `git diff --stat Sources/` empty).

## Tasks / Subtasks

- [x] **Task 1 — Corpus diagnostics generator** (AC: #1, #9)
  - [x] Author `_bmad-output/ml-training/corpus_diagnostics.py` reading `tony-corpus/tony-truth-labels.json` (+ `tony-dsp-prepass.json`, `tony-survey.json`).
  - [x] `labelSourceBias`: 4×4 agreement matrix over the exact emitted keys `{rekordbox_average, grid_bpm, dsp, playlist}`; emit signal-3 structural-absence note (coverage 0). _(relation-axis — playlist carries no bpm)_
  - [x] `octaveAmbiguityRate` (2:1 within 0.04) + `labelOctaveErrorAudit` (half/double label-error sample, E1). _(E1 sharpened: 665 convention-doubled vs 13 genuine DSP-unconfirmed high-risk)_
  - [x] `confidenceCalibrationByTier` (per-tier mean confidence + label-ECE, document binning + the Guardrail-2 "label not model" note).
  - [x] `clusterStability` via `scipy.cluster.vq.kmeans2`, ≥ 5 seeds; document k + feature vector. _(co-assignment consistency 0.9575)_
  - [x] `representativeManualReviewFindings`: ≥ 10 named tracks, non-empty `note` each, ≥ 2 from the Marginal band; pin the JSON shape so length + note-presence are assertable. _(10 findings, 2 Marginal)_
  - [x] Emit `corpus-diagnostics-v1.json` + `corpus-diagnostics-v1.md` (one `##` per JSON key); pin labeler+corpus hashes (AC9); report resolved-vs-total + unresolved list (M1). _(15/15 keys have ##; 1344/1344 resolved)_
  - [x] `make corpus-diagnostics` target (develop-only, `uv run`).

- [x] **Task 2 — Label-tier policy + computation** (AC: #2, #3, #10)
  - [x] Tier banding with exact half-open intervals (M2); emit computed histogram into the diagnostics JSON; reconcile vs PRD 333/745/241/25, document drift, set the AC9 drift-block threshold. _(computed 333/745/241/25, drift 0)_
  - [x] Single-source-truth trainability decision + count (M3). _(0 single-source in trainable; INCLUDE/moot)_
  - [x] Author `label-tier-policy-v1.md`: bands, supervised set, exclusions, KDD-B3 5 triggers verbatim (header-pinned citation), FR-15 forbidden-input enumeration.

- [x] **Task 3 — Namespaced split rebuild + leave-artist-out** (AC: #4, #6)
  - [x] Extend `dataset.py` to build the Tony split nested under `tony: {train, val, leaveArtistOut}` + preserve `externalEval: {giantsteps, oa300}`; bump `schema_version`; fail loud on stale flat shape (DD #2). _(schema_version 2; flat v1 KeyErrors loud)_
  - [x] Canonical artist key (DD #4): split collabs, name-parse the 43 empty-artist tracks, document residue; build `leaveArtistOut` disjoint on the canonical key, ≥ 10% from named artists, empty-artist disposition documented. _(106 held-out / 36 artists ≥ 102; 35 empties excluded from held-out)_

- [x] **Task 4 — Audit script** (AC: #4, #5, #7, #8)
  - [x] Author `scripts/audit-corpus-splits.py` (NEW): within-Tony near-dup (DD #3 fingerprint, all-pairs, report-only); **Tony↔OA300 + Tony↔GiantSteps overlap audit + exclusion** (AC5 — metadata first pass; exclusion happens in `build_tony_splits`, audit re-verifies zero residual + non-zero exit); sentinel-holdout + JAMS schema-validate (`--check-sentinels-against`); `--check-gate` (AC8); canonical-key disjointness check (AC6).
  - [x] Port `dataset.py::_verify_no_leak` normalizer — factor into a shared module both import, OR copy with an explicit "kept in sync" note in both (DD #10). _(corpus_common.normalize_track_key + sync note in both)_
  - [x] `make audit-corpus-splits` target (develop-only, `uv run`).

- [x] **Task 5 — Expanded DnB sentinels** (AC: #7)
  - [x] By-ear subgenre curation of 8 tracks (DD #8); author `expanded-sentinels-curation.md` (per-track rationale + curator-assigned subgenre + the likely-fired asymmetry valve). _(provisional subgenre — dev agent cannot listen; operator by-ear gate documented; valve FIRED)_
  - [x] Hand-author `Tests/.../Fixtures/12-dnb-sentinels-expanded.json` (JAMS skeleton per DD #5; re-express the 4 originals from canonical schema-v3 targets); run the holdout + schema-validate audit. _(generated deterministically by curate_sentinels.py; 12 entries valid)_

- [x] **Task 6 — KDD-B4 gate wiring** (AC: #8)
  - [x] Author the structured signoff checklist in `corpus-diagnostics-v1.md` (pending state); implement `--check-gate` exit-code contract; document the Story-7.5 `train.py` precondition contract + the "7.1-done ≠ corpus-safe" statement.

- [x] **Task 7 — Verification gauntlet + close** (AC: #10)
  - [x] `uv run` each entry point end-to-end; confirm artifacts at the exact AC paths; confirm `--check-gate` non-zero while pending.
  - [x] `git status`: changes only under `_bmad-output/`, `scripts/`, `Makefile`, and the single `Tests/.../Fixtures/12-dnb-sentinels-expanded.json`; zero `Sources/` diff.
  - [x] `make build` + `make test` green (483 tests / 105 suites) — the new fixture bundles via `Package.swift:43 .copy("Fixtures")`, inert at runtime (no Swift decoder until 8.7).
  - [x] Populate Dev Agent Record; flip story → review.

## Dev Notes

### Context — where this sits in Epic 7

Epic 7 retrains a TempoCNN-style model on Tony's hand-labeled corpus; FR-18 is reshaped from an *existence gate* to a *promotion gate* (clear all 5 → bundle on `main`; any fail → BYOW-only). Story 7.1 is the corpus-evidence foundation every later story consumes: 7.2 expands audio on 7.1's tiering; 7.3 runs the KDD-B2 ablation over 7.1's splits; 7.4 wires the Marginal tier as a failure-categorization lens; 7.5 (gates on Epic 6's 6.2 substrate + 6.5b runtime) trains v2 and its `train.py` precondition enforces 7.1's KDD-B4 gate; 7.6 (gates on 6.5b) runs FR-18 + FR-23 consuming 7.1's leave-artist-out slice + 12-sentinel set.

**Guardrails (Codex, non-negotiable):** (1) v1 work is scaffolding/diagnostics — corpus prep + diagnostics + audit plumbing are reusable, model weights/calibration disposable; (2) `featureSetVersion` bumps invalidate FR-18 metrics, so 7.1 produces *no* transferable accuracy claims (the AC1 label-ECE is explicitly NOT a model metric); (3) one declared `WeightingProfile` per trained model (a 7.3/7.5 concern).

### Verified on-disk reality (factual-claims grep + 5-reviewer corpus inspection)

| Epic/spec assumption | On-disk reality | Action |
|---|---|---|
| 1,344-track corpus tiered S/S/M/R | `tony-truth-labels.json` = 1,344 records with `truth_confidence` floats + `qa_flags`; **no tier field**. Banding reproduces **exactly** 333/745/241/25 today. | Compute tiers (DD #1); pin corpus hash (AC9). |
| `corpus_splits.json` present + audited | Exists but is GiantSteps fold01-val / folds 02-10-train / OA300-test (595/66/82), flat `train/val/test` keys; no `leaveArtistOut`; no artist grouping. | Namespace + rebuild (DD #2). |
| `_verify_no_leak` guards the corpus | Covers only **OA300↔GiantSteps** — Tony is uncovered, and ~46 Tony↔OA300 same-recording overlaps exist (Codex). | New cross-corpus audit + exclusion (AC5). |
| 5 disagreement signals | `signals` dict has **4 keys** `{rekordbox_average, grid_bpm, dsp, playlist}`; `grid_spacing` never emitted. | 4×4 matrix (DD #6). |
| DnB subgenre stratification | **No `subgenre` field**; `genre` empty on 88%; neurofunk/jump-up/liquid = 0 hits. | Curator-assigned by ear (DD #8). |
| leave-artist-out on raw `artist` | Raw Rekordbox strings: 43 empty-artist trainable tracks, collab/alias/typo variants self-certify a false green. | Canonical key (DD #4). |
| `corpus-diagnostics-v1.*`, `label-tier-policy-v1.md`, `expanded-sentinels-curation.md`, `12-dnb-sentinels-expanded.json`, `scripts/audit-corpus-splits.py` | Do NOT exist. JAMS greenfield (no Python `jams` dep; Swift `JAMSDecoder` not until 8.7). | Author (Tasks 1-6). |
| Audio fingerprinting | Does NOT exist — only filename/title overlap. | New (DD #3). |

### Design Decisions

**DD #1 — Tiers COMPUTED from `truth_confidence`; exact bounds; single-source policy; pinned + drift-blocked.** The labeler (`scripts/tony-tunes-labels.py`, `MIN_TRUTH_CONFIDENCE = 0.55`) emits `truth_confidence` (head-to-head `winner_weight/(winner_weight+runner_up_weight)`, rounded to 3 decimals) + QA flags, not tiers. 7.1 bands it with **exact half-open intervals** (M2; boundary records at exactly 0.65/0.80 go to the higher tier). `truth_confidence` is winner-margin, NOT calibrated correctness — two biased signals agreeing yields high confidence, so the policy must state a **single-source-truth** decision (M3) and the diagnostics must add a label-octave-error audit (E1) since margin won't catch confidently-wrong octave labels. Counts are a snapshot ("currently" per FR-14); reconcile + show work (AC10), do not coerce. Pin the labeler script hash + corpus file hash (AC9 — the corpus is develop-local/gitignored, so the 333/745/241/25 figures are *current-local-state*); large drift BLOCKS training, not just documents.

**DD #2 — `corpus_splits.json` namespaced + version-bumped.** The existing flat `train/val/test` keys mean GiantSteps folds + OA300 (`split_strategy` literally says "GiantSteps fold01 = val"). Overloading `train` to also mean Tony invites accidental GiantSteps training / double-counting. Nest `tony: {train, val, leaveArtistOut}` and `externalEval: {giantsteps, oa300}`; bump `schema_version` so a 7.5/7.6 consumer fails loud on the old flat shape. Tony = training; GiantSteps + OA300 + sentinels = external held-out eval (FR-18 gates b/c).

**DD #3 — Leak/near-dup detection: metadata-precise first pass + fingerprint second pass; all-pairs.** Primary leak signal is normalized-title + artist + duration match — Codex's 49-overlap detection used normalized title alone with high precision, so this is the load-bearing pass for AC5's ~46 known overlaps. Secondary defensive layer is audio fingerprinting (chroma-cosine is too weak — it misses tempo-stretched / pitch-shifted / remaster variants, exactly the DnB half-time family). Prefer **Chromaprint/AcoustID landmark fingerprinting** (`pyacoustid` + the `fpcalc` binary — **pre-authorized** addition to `pyproject.toml`); if `fpcalc` is not installable in-env, fall back to a documented librosa peak-landmark fingerprint (**pre-authorized**, no HALT). **Drop the within-artist restriction** — all-pairs cosine over ~1,078 pooled vectors is microseconds; extraction is the only cost and it's identical either way; cache fingerprints to `.npz` keyed by content hash. The audit's coverage/scope is FIXED in the script header (it's a regression gate other stories invoke, not a runtime perf escape hatch); document the chosen method's blind spot.

**DD #4 — Leave-artist-out uses a canonical artist key.** Raw Rekordbox `artist` self-certifies a false green: 43 of 1,078 trainable tracks have an empty `artist` (artist embedded in `name`), and collaboration strings (`tim reaper` solo vs `dwarde & tim reaper`), aliases, and typos (`Origin Unknown`/`Unknwon`) split one human across train and held-out while the disjointness check — comparing the same raw strings — passes anyway. Define a canonical key: split on `&`/`,`/`feat`/`and`, take the primary artist; name-parse the 43 empties; best-effort typo/alias merge with documented residue. **Exclude empty-artist tracks from both the held-out slice and the disjointness assertion** (count them); size the held-out ≥ 10% from named artists only. The audit checks disjointness on the canonical key, not the raw string.

**DD #5 — JAMS fixture hand-authored, schema-validated, ships to main.** JAMS (Humphrey et al. ISMIR 2014) is greenfield in-repo; the Swift `JAMSDecoder.swift` lands in Story 8.7. 7.1 hand-authors `12-dnb-sentinels-expanded.json` following the JAMS schema and the **develop-only audit script schema-validates it** (namespace == "tempo", `data[].value` + `confidence` present) so a malformed payload fails on develop before merging — the only guard until 8.7's decoder. Per-entry skeleton: `file_metadata` (title/artist/duration/identifiers.track_id) + `annotations[]` (namespace "tempo", `data:[{time, duration, value, confidence}]`, `annotation_metadata.curator`, `sandbox:{subgenre, confidence_quintile, held_out}`). **Confirmed:** `Package.swift:43` declares the benchmark target `resources: [.copy("Fixtures")]` — the file bundles wholesale, no `Package.swift` edit, inert at runtime (no decoder pre-8.7). This is the only main-bound artifact; it must reference no develop-only path. Re-express the 4 originals from the canonical schema-v3 `Tests/.../4-dnb-triplet-targets.json` (NOT the diverged schema-v1 `_bmad-output/implementation-artifacts/` copy that `dataset.py:48` points at).

**DD #6 — "Disagreement signals" = the 4 emitted keys; matrix is 4×4.** `tony-truth-labels.json` records carry a `signals` dict with exactly `{rekordbox_average, grid_bpm, dsp, playlist}` on all 1,344 records. Signal 3 (inter-`Inizio` grid spacing) is **declared-but-unwired** — the survey doesn't emit full grid arrays (`tony-tunes-labels.py:284-288`) — so there is no `grid_spacing` key to count; report it as a structural absence (coverage 0), not a sparse signal. The downstream Story 7.4 `failureCategory` vector (`tonyLabel/dspBPM/rekordboxBPM/idTagBPM/gridBPM/duration`) is a *different, later* construction — 7.1 does NOT materialize idTag/duration signals the labeler doesn't emit.

**DD #7 — KDD-B4 gate shipped as executable code + diligence checklist.** A bare `REVIEWER SIGNOFF: pending → signed` line is a presence gate a `sed` one-liner satisfies with zero review. The gate's epistemic value is the operator *actually examining* the evidence. So (a) the signoff is a structured checklist the operator fills by transcribing what they verified (histogram value, N findings reviewed, M octave-conflicts spot-checked with track IDs), and (b) `scripts/audit-corpus-splits.py --check-gate` exits non-zero while pending — one executable source of truth that Story 7.5's `train.py` precondition calls, instead of prose duplicated across two stories. State plainly: **7.1 "done" = evidence assembled + review pending, NOT corpus-safe-to-train** — that flips when the operator signs (operator-owned; blocks 7.5, not 7.1 close).

**DD #8 — DnB subgenre is curator-assigned by ear (no field exists) + pressure-release valves.** The corpus has no `subgenre` field; `genre` is empty on 1,520/1,721 rows and granular only to `'Drum & Bass'`; neurofunk/jump-up/liquid return zero machine-readable hits (only jungle has any path/playlist footprint). So AC7's "2-per-subgenre" rule is **manual by-ear classification**, recorded per-track in `expanded-sentinels-curation.md` + the JAMS `sandbox.subgenre`; the only programmatic stratification input is confidence-quintile + tempo-band. The author must first confirm 8 DnB tracks across the subgenres are even nameable from Strong+Solid by ear; the DD #8 valve (drop to ≥ 1-per-subgenre, document asymmetry) is **expected to fire**. Valves carried verbatim from the epic: (a) if split-contamination > 5% leakage requires re-tiering, split into Story 7.1a (diagnostics+policy) / 7.1b (split rebuild+audit), document in `7-1-pressure-release.md`; (b) NEVER substitute easy non-DnB tracks for missing sentinel slots.

**DD #9 — develop-only vs main + zero accuracy impact.** Every artifact is develop-only (`_bmad-output/ml-training/`, `scripts/`, `Makefile`) EXCEPT the main-bound JAMS fixture (per the CLAUDE.md Tests/ rule; matches `4-dnb-triplet-targets.json` precedent). Zero `Sources/` changes → DSP/ML runtime unchanged → OA300/GiantSteps accuracy gates need not re-run (assert `git diff --stat Sources/` empty). No emojis in echo statements; `uv run` not `python3`.

**DD #10 — Reuse: extend `dataset.py` for splits, new `scripts/audit-corpus-splits.py` for audit.** Split-building logic extends `dataset.py` (one writer for `corpus_splits.json` — do not fork a second writer racing on the same file). The audit is a new script under `scripts/`. The `_verify_no_leak` normalizer is needed in both: factor it into a shared importable module, OR copy it with an explicit "kept in sync with `dataset.py`" note in both files (the two develop-only dirs have no package boundary, so a documented copy is acceptable). `dataset.py:48`'s `DNB_TARGETS_PATH` points at the stale schema-v1 `_bmad-output/implementation-artifacts/4-dnb-triplet-targets.json`; the audit reads the canonical schema-v3 `Tests/.../Fixtures/` copy.

### KDD-B3's 5 reopen triggers — VERBATIM (copy into label-tier-policy-v1.md)

Source: `architecture.md`, section header **"Reopen triggers (Codex's 5 named signals)"** (cite the header text, not a line number — the line offsets drift):

1. Strong/Solid validation accuracy plateaus below target while train accuracy is materially higher
2. Leave-artist-out or GiantSteps underperforms despite good in-domain validation
3. Error analysis shows many failures are near marginal-style ambiguity (half/double confusions, 87/174, 130/65/260, breakbeat/DnB edge cases)
4. Masked-mel pretraining helps materially, implying unlabeled/ambiguous audio structure is useful
5. Marginal tracks receive stable, high-confidence predictions across seeds/checkpoints/augmentations and do not degrade sentinels

### KDD-B4 gate — the contract 7.1 satisfies

Source: `architecture.md`, section header **"KDD-B4 — Diagnostic suite (structural requirements only)"**. Artifact = JSON + human-readable Markdown at `_bmad-output/ml-training/corpus-diagnostics-v1.{json,md}`; **Gate position = produced + reviewed before training begins (per FR-12)**. Mary #2's marginal-tier triple (failure-categorization lens / disagreement-geometry input / post-bundle watchlist) is mostly Story 7.4; 7.1 satisfies item (ii) by surfacing disagreement geometry AND ensuring the Marginal cohort provably appears in the diagnostics (AC1: per-tier table + ≥ 2 of 10 findings from the Marginal band).

### Project Structure Notes

- New Python under `_bmad-output/ml-training/` + `scripts/` — develop-only per CLAUDE.md decision tree (item 3). New `Makefile` targets (`corpus-diagnostics`, `audit-corpus-splits`) follow the `ml-*`/`tony-*` pattern (`uv run`, develop-only, fail loud on main-only checkout, no emojis).
- `_bmad-output/ml-training/pyproject.toml` declares `librosa>=0.10`, `numpy`, `scipy>=1.11`, `torch`, `coremltools`. `scikit-learn` NOT declared — use `scipy.cluster.vq.kmeans2` (pre-authorized, no HALT). `pyacoustid` (Chromaprint) is **pre-authorized** for DD #3 with a pre-authorized librosa-landmark fallback. `jams` NOT needed (hand-authored).
- Branch/PR (for the later dev-story run, not this spec): Epic 6 used a parent `rterhaar/epic-6` with per-story PRs. Mirror with `rterhaar/epic-7` off `develop`; story branch `rterhaar/7-1` → PR base `rterhaar/epic-7`.

### Testing standards

- Python-prefix: "tests" are the generator/audit scripts running clean end-to-end + the audit script's own non-zero-exit assertions. The audit script IS the regression harness for AC4/AC5/AC6/AC7 and the gate for AC8 — its scope/contract is fixed in the script header so 7.5/7.6 can reason about what "zero contamination" covered.
- No Swift `@Test` work (the JAMS fixture has no Swift consumer until 8.7). `make build` + `make test` stay green; per DD #9 accuracy benchmarks need not run.

### References

- Story 7.1 epic text: `_bmad-output/planning-artifacts/epics.md#L589-L627`; Epic 7 preamble + guardrails: `epics.md#L278-L302`; story-phasing: `epics.md#L585-L588`.
- FR-12/14/15/17/22/18/23: `_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-05-25/prd.md` (L77/L81/L83/L87/L97/L89/L99). (Active PRD is in the `prds/...` subdir — `planning-artifacts/prd.md` does NOT exist.)
- KDD-B2/B3/B4/B5 + FR-18 expanded gates: `architecture.md` (cite by section header — "KDD-B3 — Marginal-tier reintroduction" / "KDD-B4 — Diagnostic suite" — not line numbers).
- Labeler signals + thresholds: `scripts/tony-tunes-labels.py` (signals L10-15; weights/thresholds L49-98, L263-294; `truth_confidence` L415/451; `single_source_truth` L437; resolve filter L596). Survey raw artist: `scripts/tony-tunes-survey.py:70`.
- Corpus data (develop-local/gitignored): `_bmad-output/ml-training/tony-corpus/{tony-survey.json, tony-dsp-prepass.json, tony-truth-labels.json}`; prior snapshot `tony-corpus/snapshots/2026-05-12-447tracks/`.
- Split + leak logic to extend: `_bmad-output/ml-training/dataset.py` (`_verify_no_leak` L250-310; `_normalize_track_key` L227; writer L303; `DNB_TARGETS_PATH` stale-copy L48; `train/val/test` flat keys L144/L303).
- Sentinel contract: `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json` (canonical schema v3); consumers `SuperFluxImpactTests.swift`, `BNNSImpactTests.swift:1016`. Bundling: `Package.swift:43 .copy("Fixtures")`.
- Raw corpus: `/Users/rterhaar/Dropbox/tony-tunes/` (Rekordbox XML `05092026.xml`, ~6,400 audio, `missing-tracks.txt` 373 unresolved).
- JAMS spec: jams.readthedocs.io (`tempo` namespace).

## Dev Agent Record

### Agent Model Used

claude-opus-4-8 (Opus 4.8, 1M context) via bmad-dev-story.

### Debug Log References

- **Substrate verification (pre-code):** every load-bearing factual claim was
  re-confirmed against the live develop-local corpus before writing code. Tier
  banding reproduces EXACTLY 333/745/241/25; trainable Strong+Solid = 1,078;
  empty-artist-among-trainable = 43; signal-key set is the 4-tuple
  `{rekordbox_average, grid_bpm, dsp, playlist}` on all 1,344 records;
  `single_source_truth` is a qa_flag (not a track field) and 0 of its 10 holders
  reach the trainable tier; `bpm_truth == null` == the 25 Reject set.
- **E1 over-report fixed:** the first cut flagged all 665 "truth = 2× Rekordbox"
  tracks as label-error candidates — but for DnB that is the EXPECTED half-time
  DJ-tagging convention (DSP independently confirms the full tempo). Sharpened
  E1's high-risk subset to doubling that DSP did NOT confirm (`dsp.relation !=
  'same'`) → 13 genuine confidently-wrong-octave candidates, the reviewer
  spot-check list.
- **Fingerprint degeneracy fixed (the key correctness catch):** the first
  fingerprint (pooled chroma + onset-autocorrelation mean, unit-norm) was
  DEGENERATE on dense electronic audio — it scored cosine 1.000 between unrelated
  tracks and flagged 168,796 boundary-crossing "near-dups". Hard-gating on it
  would make the audit always-fail. Replaced with a 52-d MFCC-mean+std+chroma-mean
  timbral signature, standardized per-dimension across the cohort before cosine,
  and made the fingerprint pass REPORT-ONLY (review flags, never gating) per
  DD #3's "never the sole auto-exclusion signal". The same-recording GATE is the
  metadata layer (canonical-artist + normalized-title grouping in
  `build_tony_splits`), which is reliable.
- **fpcalc/pyacoustid unavailable in-env** → used the pre-authorized librosa
  fallback (no HALT, DD #3). librosa 0.11.0; all 1,078 trainable audio paths
  resolve; fingerprint cache is method-versioned (`tony-corpus/fingerprint-cache.npz`).

### Completion Notes List

- **AC1** — `corpus_diagnostics.py` emits `corpus-diagnostics-v1.{json,md}`:
  4×4 `labelSourceBias` on the relation axis (playlist carries no bpm — the only
  axis spanning all four signals) + signal-3 structural-absence note;
  `octaveAmbiguityRate`; `labelOctaveErrorAudit` (E1, doubled 665 / high-risk 13);
  `confidenceCalibrationByTier` (label-ECE 0.4533, Guardrail-2 labelled);
  `clusterStability` (kmeans2, 5 seeds, co-assignment consistency 0.9575);
  `representativeManualReviewFindings` (10 findings, 2 Marginal). MD has one `##`
  per top-level JSON key (15/15, grep-verified).
- **AC2/AC3** — `label-tier-policy-v1.md`: exact half-open bounds (boundary→higher,
  M2); Strong+Solid = 1,078 supervised, Marginal+Reject excluded; single-source
  policy (count 0 in trainable, INCLUDE/moot, M3); KDD-B3 5 triggers verbatim
  (header-pinned); FR-15 forbidden-input enumeration.
- **AC4** — `corpus_splits.json` schema_version **2**, namespaced
  `tony.{train,val,leaveArtistOut}` + `externalEval.{giantsteps,oa300}`; flat v1
  shape is gone (stale consumer KeyErrors loud). Audit: schema guard +
  train/val/heldOut disjointness + near-dup (metadata grouping gates,
  fingerprint reports).
- **AC5** — Tony↔OA300 + Tony↔GiantSteps overlap detected AND excluded in
  `build_tony_splits` before train/val assignment (54 OA300 collisions, 0
  GiantSteps — numeric-ID-named); excluded set + rationale recorded; audit
  re-verifies 0 residual (non-zero exit on any). Named DnB triplet residue empty.
- **AC6** — `leaveArtistOut` disjoint on the canonical artist key (collab-split +
  43-empty-artist parse + alias merge w/ documented residue); 108 held-out / 27
  artists ≥ 10% floor (102, `ceil`-computed so the floor is truly ≥10%); 35
  empty-artist tracks excluded from held-out + disjointness assertion, counted.
  Split grouping = connected components over (shared artist ∪ shared title, the
  title edge SCOPED to empty-artist endpoints) so every copy of a recording lands
  on one side without fusing unrelated same-title artists.
- **AC7** — `12-dnb-sentinels-expanded.json` (JAMS, ships to main): 4 originals
  re-expressed from canonical schema-v3 `4-dnb-triplet-targets.json` + 8 expanded
  Tony Strong/Solid; subgenre PROVISIONAL (dev agent cannot listen — operator
  by-ear gate documented; DD #8 valve FIRED). 8 expanded held out of tony.train/val.
  `--check-sentinels-against` schema-validates + confirms holdout.
- **AC8** — KDD-B4 gate: structured signoff checklist + `REVIEWER_SIGNOFF: pending`
  marker in the diagnostics MD; `audit --check-gate` exits non-zero while pending,
  0 once `signed`; train.py precondition contract documented. **7.1 "done" =
  evidence assembled + review pending, NOT corpus-safe-to-train.**
- **AC9** — labels + labeler SHA-256 pinned; drift-block threshold (27 abs)
  documented, `blocksTraining` computed; resolved-vs-total reported (1344/1344),
  unresolved list emitted (M1 loud-fail).
- **AC10** — computed histogram emitted + reconciled vs PRD (delta 0, not coerced);
  develop-only except the main-bound JAMS fixture; `git diff --stat Sources/`
  empty; `make build` + `make test` green (483/105).
- **Pressure-release:** `7-1-pressure-release.md` records the 5.0% cross-corpus
  leakage (handled by exclusion, no re-tiering → no 7.1a/7.1b split) and the
  DD #8 subgenre valve firing.

### File List

New (develop-only):
- `_bmad-output/ml-training/corpus_common.py`
- `_bmad-output/ml-training/corpus_diagnostics.py`
- `_bmad-output/ml-training/curate_sentinels.py`
- `_bmad-output/ml-training/corpus-diagnostics-v1.json`
- `_bmad-output/ml-training/corpus-diagnostics-v1.md`
- `_bmad-output/ml-training/label-tier-policy-v1.md`
- `_bmad-output/ml-training/expanded-sentinels-curation.md`
- `_bmad-output/ml-training/7-1-pressure-release.md`
- `_bmad-output/ml-training/manual-dup-exclusions.json` (operator-input template for the KDD-B4 dup-exclusion loop; empty list = no drops)
- `scripts/audit-corpus-splits.py`
- (`_bmad-output/ml-training/tony-corpus/fingerprint-cache.npz` — regenerable cache, gitignored, NOT committed)

New (ships to main):
- `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/12-dnb-sentinels-expanded.json`

Modified (develop-only):
- `_bmad-output/ml-training/dataset.py` (Tony namespaced split + leave-artist-out + cross-corpus/sentinel exclusion + namespaced writer; legacy `build_splits`/`_verify_no_leak` intact)
- `_bmad-output/ml-training/corpus_splits.json` (regenerated, schema_version 2 namespaced)
- `Makefile` (`corpus-diagnostics`, `curate-sentinels`, `audit-corpus-splits` targets; `ml-splits` threads corpus paths)
- `.gitignore` (ignore the regenerable fingerprint cache)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (7-1 → in-progress→review)
- `_bmad-output/implementation-artifacts/7-1-...md` (this story file: baseline_commit, tasks, Dev Agent Record)

### Review Follow-ups (AI)

`bmad-code-review` ran a 4-layer quorum (Blind Hunter + Edge Case Hunter +
Acceptance Auditor + Codex blind-hunter). All 10 ACs were confirmed SATISFIED;
the quorum-agreed correctness/robustness fixes were applied:

- [x] **[high] Title-link over-merge (Edge Case Hunter, verified):** connected
  components fused unrelated same-title artists — a 59-track megacomponent merged
  Ternion Sound + sinistarr + subject_xero via generic titles "simulacra"/"portland",
  distorting the split. Scoped the title edge to fire only when ≥1 endpoint is
  empty-artist (the genuine artist-in-name dedup case). Multi-artist components 3→0.
- [x] **[high] Held-out floor rounded below 10% (Codex, verified):** `int(round(0.10*N))`
  gave 9.96%; switched to `math.ceil`.
- [x] **[high] GiantSteps coverage pass-when-unavailable (Codex):** the cross-corpus
  audit now FAILS (was warn) when `GIANTSTEPS_CORPUS_PATH` is unset — fail-closed for a leak gate.
- [x] **[high] `--check-gate` naive substring (Edge Case Hunter):** parse the single
  anchored `REVIEWER_SIGNOFF` marker via regex; ambiguous/missing marker → fail.
- [x] **[med] track_id integrity (Edge + Codex):** `load_tony_corpus` loud-fails on
  missing/duplicate track_ids + non-finite truth_confidence; `_recording_components` asserts uniqueness.
- [x] **[med] Sentinel file present-but-broken (Edge):** `load_expanded_sentinel_ids`
  raises (was silent `set()` → no-op holdout).
- [x] **[med] Degenerate-corpus crashes (Blind + Codex):** guarded empty/`N<k` paths in
  `confidence_calibration_by_tier` + `cluster_stability` (clean shapes, no numpy blowups).
- [x] **[med] `labelSourceBias` degenerate axes (Auditor):** emit `degenerateAxisPairs`
  disclosing that rekordbox_average/grid_bpm are identical alias columns; "double" relation comment corrected.
- [x] **[low] Robustness:** sentinel `take()` local-count stratification; external-GT
  list-shape guard; cross-corpus reports all hit corpora; empty `tony.val` floor `max(1,…)`;
  fingerprint cache drops non-finite cached vectors; over-exclusion >5% warning; quintile thin-pool guard.
- [x] **[doc] Stale counts + Charly mechanism (Auditor):** AC6 counts refreshed;
  clarified Tony's Charly is Marginal-tier-excluded (not cross-corpus), leak-safe.
- [x] **[follow-up] Near-dup checklist item made actionable:** the new review
  checklist item said confirmed dups should be "excluded", but no within-Tony dup
  exclusion path existed. Added `manual-dup-exclusions.json` (optional operator
  input, same exclusion pattern as cross-corpus/sentinels) + track_ids in the
  audit's near-dup flag output, so the operator can confirm a flagged pair by ear,
  drop the duplicate's id, and re-run `make ml-splits`.
- Deferred (not 7.1 defects): split incremental-instability under corpus growth
  (design note for 7.5/7.6, deferred-work 7-1-D1); the report-only fingerprint's
  residual 21 inconsistent-naming near-dup flags are surfaced for the operator's
  KDD-B4 signoff (new checklist item + the manual-dup-exclusions.json action path).

### Change Log

- 2026-05-31 — Story 7.1 implemented: corpus diagnostics (FR-12), label-tier policy
  (FR-14/15), namespaced split + leave-artist-out (FR-22), Tony↔external leak
  exclusion (AC5/B1), 12-track JAMS DnB sentinels (FR-18 gate a), KDD-B4 review
  gate as executable code (AC8). Zero `Sources/` changes; `make build`/`make test`
  green (483/105). Status → review.
- 2026-05-31 — Code-review quorum fixes applied (title-link over-merge, ceil floor,
  GiantSteps fail-closed, anchored signoff gate, corpus-integrity loud-fails, degenerate
  guards; see Review Follow-ups). Audit re-verified green; split now 812/96/108.
