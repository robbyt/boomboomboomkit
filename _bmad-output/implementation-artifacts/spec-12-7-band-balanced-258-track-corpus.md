---
title: 'Story 12.7: Build the 258-track band-balanced corpus (construction harness)'
type: 'feature'
created: '2026-08-08'
status: 'blocked' # on operator hand-verification + the fallback addendum for the four short bands
review_loop_iteration: 0
baseline_revision: '31d772e' # rterhaar/epic-12 tip (#196 squash-merge)
final_revision: '202d60a' # implementation commit; this reference recorded in a follow-up commit
followup_review_recommended: true
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-12-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md'
warnings: ['oversized']
---

<intent-contract>

## Intent

**Problem:** The bundle gate (12.9) needs a 43x6-band, 258-track evaluation corpus whose
labels were never selected or corroborated by the detector under test (FR-59/59a), but no
construction tooling exists: candidate pools, seeded membership draw sequences, blinded
annotation worklists, keep/reject bookkeeping, the fail-closed audit, and the manifest
emitter all have to be built before the operator's hand-verification (signed protocol,
12-6-metrical-level-convention.md section 2) can begin. The corpus itself cannot complete
in this run — verification is operator DAW work — so the deliverable is the harness plus
the committed candidate/draw commitment, and the run ends `blocked` on operator
hand-verification.

**Approach:** One develop-only Python tool implementing the signed section-2 protocol
literally: face-value-tag pool construction with FR-59a.2 training-set exclusion, per-band
seeded-PRNG membership draw sequences cryptographically committed (counts + seeds + pool
SHA-256 in git; row-level data gitignored per the OA300/pool privacy rules), blinded batch
staging (opaque row IDs, copied audio), annotation ingest with the precommitted DSP-free
keep/reject and first-43-cumulative membership rule, a fail-closed audit (FR-59a.1
assertion, FR-59a.2 residual overlap on the `check_cross_corpus_residual` precedent,
duplicates, sentinel-rule inputs), a JAMS manifest emitter carrying
`declared:metrical-full-tempo-v1-2026-08-08` + `octave-sentinel` tags + the 175+
degeneracy note, and the KDD-B4-pattern fail-closed signoff gate wired into `train.py`.

## Boundaries & Constraints

**Always:**
- The signed protocol in `12-6-metrical-level-convention.md` section 2 is the source of
  truth; where this spec and it differ, the protocol wins and the difference is a defect.
- Pool banding reads ONLY face-value tag BPM: OA300 fixture value, Tony `average_bpm`
  (as-entered), pool `fileMetadataBPM`. No DSP estimate, confidence, ratio class, or
  dsp/tag quantity is read at pool-construction, draw, or membership time. Tag-less rows
  are excluded with per-band counts recorded.
- All six band edges half-open [lo, hi) at 100/120/140/160/175 everywhere (pools,
  keep/reject, sentinel windows).
- FR-59a.2 exclusion at candidate construction: rows matching the training corpus — the
  two committed non-Rekordbox manifests (by `audioHash`), `corpus_splits.json`
  `tony.train` + `tony.val` (by track identity), and any candidate sharing an artist
  string with a training-set row where artist is known (Tony rows; pool rows have no
  artist field — record that limitation) — are excluded before commitment, counts
  recorded per band per reason.
- Membership draw sequence: one global per-band permutation from a recorded seeded PRNG
  (`random.Random(seed)`, seed + algorithm recorded), fixed at commitment. Membership =
  first 43 keepers in this sequence, cumulative across batches; same sequence governs
  surplus and duplicate tie-breaks. Batch = consecutive span, default 40.
- Blinded worklists carry opaque row ID + staged-copy audio path ONLY. Tags, DSP fields,
  and survey fields never appear in the annotator-facing output.
- Committed (git) artifacts pass a q9-style recursive privacy allowlist: counts, seeds,
  band names, SHA-256 commitments only — no absolute roots, no row-level paths, no audio
  hashes except the named commitment digests. Row-level candidate/draw/worklist files are
  gitignored.
- Keep/reject criteria exactly as signed (stable lock, in-band at declared level,
  not irresolvable, intact/non-duplicate); verified-out-of-band rows are rejected, never
  reassigned; rejects retain their verified tempo as data.
- OA300 is private: never published or referenced outward; committed artifacts follow the
  counts-only rule.
- `Sources/` and `Tests/` (Swift) stay byte-identical; all new code is develop-only
  Python + Makefile + artifacts.
- New scripts: `uv run`, ruff-clean, added to the Makefile `py-lint` ty enumeration;
  pytest under `scripts/tests/` (ruff-only there).

**Block If:**
- A band's post-exclusion candidate pool holds fewer than 43 rows at commitment time —
  record the counts in the commitment artifact and HALT (exhaustion escalation is the
  operator's, per the signed fallback rule; do not auto-extend from Tony/OA300).
- Any input the harness needs is missing or schema-mismatched (`non-rekordbox-survey.json`
  absent, `tony-survey.json` schema drift, manifests unreadable) — HALT rather than
  degrade.
- The signed protocol would have to be amended to proceed.

**Never:**
- No operator verification simulated, no annotation values invented, no track labelled by
  this run. The 258/43-per-band ACs are NOT satisfiable here; the run ends `blocked` on
  operator hand-verification with the harness complete.
- No relabelling of OA300 in place (FR-62a struck). No modification of the existing
  training manifests or `corpus_splits.json` in this story (the FR-59d training-corpus
  rebuild is post-verification work; this story wires the gate that blocks training
  until then).
- No `--match` / legacy-label join in any annotator-facing path.
- No new `DSPTechnique`/public Swift API of any kind.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| commit-pools happy path | three source inputs readable | gitignored `eval-corpus/candidate-pools.json` (row-level) + committed `12-7-candidate-commitment.{json,md}` (per-band counts, exclusion counts by reason, seeds, SHA-256 of the row-level file); idempotent re-run verifies, refuses to overwrite with different content | second run with drifted inputs exits nonzero naming the digest mismatch |
| tag-less row | pool row `fileMetadataBPM: null` | excluded from banded pools; counted in per-band exclusion counts | not an error |
| band under 43 candidates | post-exclusion pool < 43 | commitment still written; tool exits nonzero listing the short bands | HALT condition surfaced to operator |
| stage-batch | committed pools + band + batch index | next consecutive span of the draw sequence; audio copied to staging dir named by opaque row ID; worklist CSV with row ID only | refuses if pools uncommitted or batch out of sequence |
| ingest annotation | worklist + operator-filled tempo/flags per row ID | keep/reject applied (DSP-free), cumulative membership recomputed, verified surplus recorded; out-of-band verify → reject with tempo retained | malformed/missing row → exit nonzero, nothing partially applied |
| tempo-unstable / irresolvable flag | annotator flag set | row rejected with reason recorded | not an error |
| audit | any state | fail-closed: FR-59a.1 assertion (no DSP field consulted in membership inputs — asserts the membership derivation reads only verified tempi + draw sequence), residual overlap vs OA300/GiantSteps (`find_cross_corpus_matches` precedent), duplicate check, oa300 18-vs-14 row-basis reconciliation report | any assertion failure → nonzero exit |
| emit-manifest before 258 complete | membership < 43 in any band | refuses; prints per-band progress | expected during verification |
| emit-manifest complete | all bands at 43 | JAMS corpus with `declared:metrical-full-tempo-v1-2026-08-08`, per-track `sentinel: octave-sentinel` where the two-directional [80,87.5)/[160,175) rule holds against FR-59a.1-clean legacy labels, 175+ degeneracy note in corpus metadata; signoff marker `REVIEWER_SIGNOFF: pending` in the committed corpus artifact | privacy gate must pass before write |
| train.py gate | corpus signoff `pending` or marker absent | any substrate-v2 training run aborts before work (KDD-B4 `_SIGNOFF_RE` pattern) | fail closed |

</intent-contract>

## Code Map

- `_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md` -- SIGNED protocol (section 2: pools, two orders, batches, keep/reject, replacement, exhaustion, budget; section 3: sentinel rule; section 5: tag) — binding, read-only
- `scripts/non-rekordbox-survey.py` / gitignored `_bmad-output/ml-training/non-rekordbox-survey.json` -- pool source, 4,766 rows; per-row `audioHash`, `path` (relative), `fileMetadataBPM` (face-value, often null), `tier`; NO artist field
- `_bmad-output/ml-training/tony-corpus/tony-survey.json` (tracked) -- Tony source, 1,721 rows; `track_id`, `artist`, `average_bpm` (as-entered), `local_path`, `basename`; no hash
- `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json` -- OA300 source (82 rows, Rekordbox BPM = face value); read-only
- `_bmad-output/ml-training/non-rekordbox-secondary-supervised-manifest.json` + `non-rekordbox-unsupervised-pretrain-manifest.json` (committed) -- FR-59a.2 exclusion sets by `audioHash` (2,154 + 2,162 rows)
- `_bmad-output/ml-training/corpus_splits.json` (committed) -- `tony.train`/`tony.val` identities for FR-59a.2 exclusion
- `scripts/audit-corpus-splits.py` + `_bmad-output/ml-training/corpus_common.py` -- `compute_fingerprint` (52-dim, cached `tony-corpus/fingerprint-cache.npz`), `find_cross_corpus_matches` / `check_cross_corpus_residual` precedent, `is_continuous_mix`
- `_bmad-output/ml-training/q9_ratio_cluster.py` -- `privacy_gate(doc)` recursive-allowlist precedent (copy the mechanism + exit-code-3 convention for the new committed artifacts)
- `_bmad-output/ml-training/train.py` -- `check_substrate_preconditions()` (~line 454) `_SIGNOFF_RE` KDD-B4 gate to extend with the 258-corpus marker
- `_bmad-output/ml-training/three-source-band-census-2026-08-01.md` -- expected pre-exclusion band counts (sanity anchors: pool 1988/262/52/42/102/104; Tony as-entered 889/8/137/310/0/0; OA300 14/1/7/16/44/0)
- `scripts/build-eval-corpus.py` -- NEW: the harness (subcommands `commit-pools`, `stage-batch`, `ingest`, `status`, `audit`, `emit-manifest`)
- `scripts/tests/test_build_eval_corpus.py` -- NEW: pure-logic pytest suite
- `_bmad-output/implementation-artifacts/12-7-candidate-commitment.{json,md}` -- NEW committed commitment record (privacy-gated)
- `Makefile` -- NEW targets `eval-corpus-pools`, `eval-corpus-batch`, `eval-corpus-ingest`, `eval-corpus-audit`, `eval-corpus-manifest`; ty enumeration + `help` entries
- `.gitignore` -- entries for the gitignored `_bmad-output/ml-training/eval-corpus/` working dir

## Tasks & Acceptance

**Execution:**
- [x] `scripts/build-eval-corpus.py` -- implement the six subcommands per the I/O matrix; state lives under gitignored `_bmad-output/ml-training/eval-corpus/` (candidate-pools.json, draw-sequences.json, batches/, annotations/, membership.json); all randomness from recorded per-band seeds; stdlib + `corpus_common` only (no torch/librosa on the hot path; fingerprint use goes through the existing cache) -- rationale: single tool = single audit surface
- [x] `scripts/tests/test_build_eval_corpus.py` -- pytest over the pure logic: half-open banding at all five edges, tag-less exclusion, FR-59a.2 exclusion accounting, draw determinism (same seed → same permutation), first-43-cumulative membership incl. surplus + duplicate tie-break by sequence position, keep/reject incl. out-of-band rejection retaining tempo, sentinel two-directional rule at [80,87.5)/[160,175) boundaries (80 in, 87.5 out, 160 in, 175 out), privacy gate rejects a path/hash smuggled into a committed doc, commitment digest mismatch detection -- rationale: the protocol's correctness lives in these rules
- [x] `_bmad-output/implementation-artifacts/12-7-candidate-commitment.md` + `.json` -- generate via `commit-pools` against the real inputs; counts + seeds + digests only -- rationale: the protocol's "list committed before verification begins", satisfied without publishing the private inventory
- [x] `_bmad-output/implementation-artifacts/12-7-eval-corpus.md` -- NEW corpus artifact: records the signed-protocol pointer, the 175+ degeneracy note, the per-band progress table (initially 0/43), the oa300 18-vs-14 reconciliation outcome from `audit`, and exactly one `REVIEWER_SIGNOFF: pending` marker -- rationale: the KDD-B4-pattern gate needs a marker document; degeneracy AC needs a recorded home
- [x] `_bmad-output/ml-training/train.py` -- extend `check_substrate_preconditions()` to also require `12-7-eval-corpus.md` present with exactly one `REVIEWER_SIGNOFF:` marker reading `signed` before ANY substrate-v2 training run (unconditional — per the epic decision "wired before any training story runs"; no training is scheduled before the corpus completes, so this blocks nothing current); keep the existing corpus-diagnostics gate untouched -- rationale: final AC (fail-closed equivalent wired)
- [x] `Makefile` -- add the five targets (uv-run, no emojis, `## help` lines), add `scripts/build-eval-corpus.py` to the py-lint ty enumeration -- rationale: repo convention; ruff covers scripts/ automatically, ty does not
- [x] `.gitignore` -- add `_bmad-output/ml-training/eval-corpus/` -- rationale: row-level data is private inventory (q9 rule)

**Acceptance Criteria:**
- Given the three source inputs, when `make eval-corpus-pools` runs, then the commitment artifact records per-band candidate counts, per-reason exclusion counts (tag-less, FR-59a.2 by manifest-hash / tony-split / artist), seeds, and the pool-file SHA-256, and the artifact passes the privacy gate
- Given committed pools, when `stage-batch` then `ingest` run on synthetic annotations in tests, then membership equals the first 43 keepers in draw-sequence order regardless of annotation work order or batch boundaries
- Given the audit subcommand, when any membership input carries a DSP-derived field or a residual cross-corpus overlap exists, then it exits nonzero (fails closed), and a clean state exits zero with the reconciliation report
- Given a complete corpus (test fixture), when `emit-manifest` runs, then the JAMS output carries the section-5 tag, sentinel tags per the two-directional rule, and the 175+ degeneracy note; given an incomplete corpus, it refuses
- Given `train.py`, when the 258-corpus signoff marker is absent or `pending`, then a substrate-v2 training run aborts before any training work
- Given the branch, when diffed against the epic-12 tip, then `Sources/` and Swift `Tests/` are byte-identical and `make test` + `make py-lint` + `make scripts-tests` pass
- Given the run ends, then the spec status is `blocked` with condition `operator hand-verification` — the 43x6 corpus ACs remain open by design

## Spec Change Log

## Review Triage Log

### 2026-08-08 -- Review pass (Blind Hunter + Edge Case Hunter)
- intent_gap: 0
- bad_spec: 0
- patch: 21: (high 3, medium 5, low 13)
- defer: 0
- reject: 4
- addressed_findings:
  - `[high]` `[patch]` Commitment silently re-mintable when the gitignored pools file was absent -- now verify-or-restore: deterministic regeneration from the recorded seed, byte-hash compared against the committed digests, HarnessError on drift; digests never rewritten (live-tested via delete + restore)
  - `[high]` `[patch]` Privacy gate's len<60 exemption let 60+-char absolute paths bypass -- path roots (`Users/`, `Volumes/`, `~`, `$HOME`) now forbidden at any length; length exemption retained only for bare slashes in prose
  - `[high]` `[patch]` Annotation CSV had no header validation (missing flag column silently read False) -- exact 7-column header set asserted before any row parses
  - `[medium]` `[patch]` `draw_file_sha256` never re-verified -- both digests verified at all four consuming subcommands; missing files/keys raise HarnessError
  - `[medium]` `[patch]` Sentinel legacy-label join used normalized title, deviating from the signed protocol's fingerprint/exact-filename rule -- replaced with audioHash exact match + exact-basename fallback; normalized title retained only in the residual audit where it is the documented precedent
  - `[medium]` `[patch]` FR-59a.1 audit was a fail-open denylist -- converted to key allowlists over candidate/annotation/membership records; unexpected keys fail the audit
  - `[medium]` `[patch]` Re-ingest silently overwrote a batch's annotations -- now refuses without `--force`; with it, the replaced file's sha256 is recorded
  - `[medium]` `[patch]` Batch-record gaps shifted the staging start silently -- contiguity enforced, gap is an error
  - 13 low patches: non-finite bpm parse error; oa300 bpm-key guard; atomic md write; `--size` validation + interrupted-copy repair; schema-access guards; conflicting `--seed` error; non-numeric stored bpm guard; mid-string audio-extension regex; bidirectional duplicate registration; train.py gate message names the fallback-addendum stall; short-bands framing strengthened in both committed artifacts with per-band shortfall numbers; record-then-stage ordering; verify/restore output prints both digests
  - Rejected: band-visible row IDs (the signed protocol's stated per-track-only blinding residual), surplus-duplicate membership loss (unreachable given sequence ordering), Makefile exit-code aggregation note, train.py read_text traceback shape (fails closed regardless)

## Auto Run Result

Status: `blocked` on operator hand-verification (by design -- the spec's Never
section and the 12.6 precedent: the 43x6 corpus ACs are operator DAW work).

**Implemented:** the full Story 12.7 construction harness for the signed
FR-59f protocol, plus the real candidate commitment. Files:

- `scripts/build-eval-corpus.py` -- six subcommands (`commit-pools`,
  `stage-batch`, `ingest`, `status`, `audit`, `emit-manifest`); seeded per-band
  draw sequences, opaque row IDs, blinded worklists, DSP-free keep/reject with
  first-43-cumulative membership, fail-closed audit, JAMS emitter with the
  section-5 tag + `octave-sentinel` rule, verify-or-restore cryptographic
  commitment, q9-style privacy gate
- `scripts/tests/test_build_eval_corpus.py` -- 55 pure-logic tests
- `_bmad-output/implementation-artifacts/12-7-candidate-commitment.{json,md}` --
  committed pool commitment (counts, seeds, digests; privacy-gated)
- `_bmad-output/implementation-artifacts/12-7-eval-corpus.md` -- corpus artifact
  with 175+ degeneracy note, 0/43 progress table, reconciliation outcome, and
  exactly one `REVIEWER_SIGNOFF: pending` marker
- `_bmad-output/ml-training/train.py` -- unconditional gate (d): substrate-v2
  training aborts until the 258-corpus signoff reads `signed`
- `Makefile` (five `eval-corpus-*` targets + ty enumeration), `.gitignore`
  (`_bmad-output/ml-training/eval-corpus/`)

**Material finding for the operator (escalation per the signed exhaustion
rule):** at the committed pools, four bands cannot reach 43 candidates --
100-120 has 3 (short 40), 120-140 has 28 (short 15), 160-175 has 41 (short 2),
175-plus has 9 (short 34). Dominant cause: the FR-59a.2 manifest-hash exclusion
removes nearly the whole tag-carrying non-Rekordbox pool (the two training
manifests cover it). The signed fallback (dated addendum enumerating Tony
as-entered rows, then OA300 rows, before any DSP statistic is consulted) is the
operator's next action; the harness performs no auto-extension.

**Audit outcome:** clean (FR-59a.1 allowlist, residual overlap, duplicates).
The 12.6-flagged oa300 18-vs-14 discrepancy resolved as a value-source
difference, not a band-edge effect; the fixture face-value counts stand for the
sentinel definition.

**Review:** 21 patches applied (3 high, 5 medium, 13 low), 0 deferred,
4 rejected -- see Review Triage Log. Follow-up review recommended: true
(volume + three high-severity commitment/privacy/ingest fixes).

**Verification:** `make py-lint` clean; `make scripts-tests` 170 passed (55 new);
`make test` 1038 tests / 170 suites passed; `make eval-corpus-pools` verifies the
existing commitment (exit 4 solely from the recorded short-bands HALT);
`make eval-corpus-audit` clean; `git diff --stat 31d772e -- Sources/ Tests/`
empty (Swift byte-identical).

**Residual risks:** artist-based FR-59a.2 exclusion enforceable only for Tony
rows (pool has no artist field; recorded limitation, compensated by the audit
fingerprint pass); keeper rates unmeasured until the first completed batch (the
signed re-plan checkpoint).

## Design Notes

- **Commitment without publication:** the signed protocol requires the candidate list be
  committed before verification, but the pool inventory is private (q9 lesson). The
  mechanism: full row-level pools + draw sequences in one gitignored JSON; a committed
  artifact carries its SHA-256 + counts + seeds. Any later tampering with the row-level
  file breaks the digest; re-running `commit-pools` verifies instead of overwriting.
- **Primary pools = union of all three sources** banded by face value (AC1 "drawn
  across"), with FR-59a.2 exclusions applied. The signed exhaustion fallback (Tony
  as-entered, then OA300) applies to rows NOT in the primary pools only if a band was
  sourced pool-only; since the union already includes Tony/OA300 face-value rows, the
  fallback's practical role is the operator-escalation path — implement exhaustion as
  HALT + escalate exactly as signed, no auto-extension.
- **Artist exclusion asymmetry is recorded, not solved:** pool rows carry no artist
  string; artist-based FR-59a.2 exclusion is only enforceable for Tony rows. The
  commitment artifact states this; the audit's fingerprint pass (existing cache,
  report-only precedent) is the compensating check.
- **Opaque row IDs:** `e<band-index>-<zero-padded sequence position>-<4-hex salt>` derived
  from the seeded PRNG at commitment — stable, meaningless to the annotator, join key for
  ingest.
- **`status` subcommand** prints the per-band progress + keeper-rate estimate after each
  completed batch (the signed re-plan checkpoint input: ceil(43/rate)).

## Verification

**Commands:**
- `make py-lint` -- expected: ruff + ty clean including the new script
- `make scripts-tests` -- expected: new pytest suite passes
- `make test` -- expected: 1038 tests / 170 suites unchanged (no Swift edits)
- `make eval-corpus-pools` -- expected: commitment artifacts written; per-band counts within sanity range of the census anchors minus exclusions; nonzero exit iff a band < 43
- `git diff --stat <epic-12-tip> -- Sources/ Tests/` -- expected: empty
