---
title: 'Story 12.6: Metrical-level convention and the ground-truth rule'
type: 'feature'
created: '2026-08-08'
status: 'blocked'
review_loop_iteration: 0
followup_review_recommended: true
final_revision: '8a8f751' # re-signed 2026-08-08
baseline_revision: '4b66b75' # branch rterhaar/12-6-metrical-level-convention, stacked on Story 12.3 (re-signed 2026-08-08)
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-12-context.md'
warnings: ['oversized']
---

<intent-contract>

## Intent

**Problem:** The 258-track band-balanced corpus (FR-59) cannot be built until exactly one
metrical-level convention is declared (FR-59b) and the tag-to-ground-truth rule is written
down with it (FR-59f), because the pool's band distribution is a property of the convention
(78% sub-100 by tag, 65% at 160-175 by DSP, identical files), and a rule that changes
mid-verification invalidates hand-verification work already done. The operator will
hand-verify all 258 tracks; the rule must be fixed before the first label.

**Approach:** One declaration artifact that (1) declares a single metrical level for the
new corpus with the two-population evidence and its mandatory caveat, (2) transcribes the
settled FR-59f option-1 rule into an operational verification protocol (blinding,
ordering, keep/reject/replace, budget), (3) defines the 80-85 / 160-175 sentinel subset,
(4) performs the FR-62 legacy-corpus convention audit, and (5) mints the corpus's
`declared:` annotation-version tag under Story 12.3's scheme. The artifact ends in an
explicit operator-signoff block; the story cannot close on agent work alone.

## Boundaries & Constraints

**Always:**
- Exactly ONE metrical level is declared, recorded with the corpus, and justified from the
  two independent populations (pool third-party tags: 71% half-tempo; Tony Rekordbox
  as-entered: 889 below 100 vs 36 octave-corrected). The caveat travels with every citation
  of the octave-corrected column: its octave came from a cluster vote our detector
  participated in, so only the as-entered column is FR-59a.1-clean (epics.md Story 12.6 AC).
- The ground-truth rule is FR-59f option 1 (human verification, SETTLED 2026-07-29,
  operator) and the protocol embeds the four safe-ordering conditions verbatim in
  substance: candidate set fixed before any DSP quantity is consulted; entire committed
  batch annotated; annotator blinded to tag, DSP estimate, confidence, and ratio class;
  membership chosen after annotation by a precommitted rule reading no DSP output. If the
  batch will not be completed, the queue is randomized (prd.md FR-59f (c)).
- 100-120 is verified first, for the workload reason (Q9: 197 of 262 pool labels in the
  1.5x class), not scarcity; the (b) one-keeper-in-four budget scenario is cited as a
  hypothesis-derived scenario, never as a measured rejection rate.
- The 80-85 / 160-175 octave-ambiguity pairs are retained as a tagged sentinel subset,
  not collapsed.
- No OA300 track is re-labelled in place (FR-62a struck, superseded by FR-59b); OA300
  stays a tagged historical artifact.
- The FR-62 audit records, per legacy corpus (OA300, GiantSteps, Tony truth labels /
  training manifests), which convention its labels follow, with evidence anchors.
- The new convention's annotation-version tag uses Story 12.3's namespace and validation
  rules (`declared:<value>`, no reserved-prefix collision, no whitespace/control chars);
  the exact tag string is recorded in the declaration.
- The declaration is drafted as a RECOMMENDATION with the full evidence for and against
  each level; the operator signs off before it becomes the rule. The signoff block states
  what signing means and what remains open until signed.
- Amend-not-erase throughout; dated 2026-08-08; PRD/epics citations lead with stable
  identifiers (FR/section), line numbers as dated hints. No emojis, no em-dashes.

**Block If:**
- The evidence, once assembled, genuinely underdetermines the recommendation between the
  two levels such that stating one would be arbitrary. (Presenting a recommendation the
  operator may overturn is expected; fabricating decisive evidence is not.)
- The operator-signoff AC: this story NEVER reaches `done` in this run. After review, the
  run HALTs with status `blocked`, blocking condition `operator signoff required on the
  ground-truth rule (FR-59f / epics.md Story 12.6 final AC)`.

**Never:**
- No changes under `Sources/` or `Tests/` (this is a declaration/audit story; Story 12.3
  already landed the tagging machinery). `git diff --stat 4b66b75 -- Sources/ Tests/`
  stays empty.
- No corpus building, no track draw, no labelling: that is Story 12.7.
- No re-litigating settled operator decisions (FR-59f option 1; six bands kept; N=43;
  258 total) — transcribe and operationalize them.
- No DSP-derived quantity used to include or exclude any track in the sentinel-subset
  definition or the draw rule.

</intent-contract>

## Code Map

- `_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-07-26/prd.md` -- FR-59b (:185), FR-59f + settled option 1 + (a)/(b)/(c) amendments (:196-222), FR-62/62a (:230-231), feasibility resolution + 71%/889-36 populations (:235-260)
- `_bmad-output/planning-artifacts/epics.md` -- Story 12.6 ACs (:2202-2240)
- `_bmad-output/ml-training/three-source-band-census-2026-08-01.md` -- two-population banding evidence (889/36, per-band counts)
- `_bmad-output/ml-training/q9-ratio-cluster-2026-08-01.md` -- Q9 ratio composition (197-of-262 1.5x class in 100-120)
- `Sources/BoomBoomBoomKitTestSupport/AnnotationVersion.swift` -- Story 12.3 tag scheme the declared tag must validate against (read-only reference)
- `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json` + `12-dnb-sentinels-expanded.json` -- legacy-corpus label sources for the FR-62 audit (read-only)
- `_bmad-output/ml-training/tony-corpus/tony-truth-labels.json` -- Tony legacy labels for the FR-62 audit (read-only; gitignored corpus data referenced by counts only)
- `_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md` -- AS-BUILT: the declaration artifact (six sections; recommends full-tempo; tag `declared:metrical-full-tempo-v1-2026-08-08`; unchecked operator-signoff block)
- As-built count anchors: oa300-ground-truth.json measured 2026-08-08 as 82 entries / 41 in [160,175) / 18 below 100 (13 within [80,85]); tony-truth-labels.json measured as 1,509 of 1,534 labelled, bands 36/26/253/372/786/36 (matches census octave-corrected column)

## Tasks & Acceptance

**Execution:**
- [x] `_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md` -- write the declaration artifact with sections: (1) Convention declaration (recommended level, evidence from both populations with the FR-59a.1 caveat, what adopting the other level would change); (2) Ground-truth rule (FR-59f option 1 operationalized: verification workflow, blinding mechanics, per-band order starting 100-120, keep/reject criteria, replacement-from-band rule, budget with the (b) scenario labelled as hypothesis); (3) Sentinel subset definition (which 80-85 / 160-175 pairs, how tagged, DSP-free membership rule); (4) FR-62 legacy audit table (OA300, GiantSteps, Tony labels: convention each follows, evidence); (5) Annotation-version tag (exact `declared:` string, validated against Story 12.3's rules); (6) Operator signoff block (unchecked) -- rationale: the single artifact FR-59b/59f require to exist "recorded with the corpus" before any labelling
- [x] `_bmad-output/implementation-artifacts/sprint-status.yaml` -- leave `12-6-*` at `in-progress`-equivalent state the workflow sets; do NOT set done -- rationale: final AC requires operator signoff
- [x] Validate the chosen tag string against `AnnotationVersion.declared(_:)` semantics by inspection (trimmed, no control chars, no reserved prefix, not "untagged") -- rationale: Story 12.3's validator is the gate the tag must later pass at corpus load

**Acceptance Criteria:**
- Given the declaration artifact, when read, then exactly one metrical level is recommended with both populations cited and the octave-corrected caveat attached at every citation of that column
- Given the ground-truth rule section, when compared against prd.md FR-59f, then option 1 and all four safe-ordering conditions appear in substance, 100-120 is ordered first for the workload reason, and no DSP quantity gates draw membership
- Given the sentinel-subset section, when the rule lands, then the 80-85 / 160-175 pairs are retained as a tagged subset with a DSP-free membership rule
- Given the FR-62 audit table, when read, then each legacy corpus row states its convention with an evidence anchor, and no OA300 relabelling is proposed
- Given the tag section, when checked against Story 12.3's `AnnotationVersion` rules, then the `declared:` string is valid and non-colliding
- Given the full artifact, when the run ends, then an unchecked operator-signoff block exists and the run status is `blocked` on operator signoff, not `done`
- Given the branch, when diffed against 4b66b75, then `Sources/` and `Tests/` are byte-identical

## Spec Change Log

## Review Triage Log

### 2026-08-08 -- Review pass (Blind Hunter + Edge Case Hunter)
- intent_gap: 0
- bad_spec: 0
- patch: 15: (high 1, medium 6, low 8)
- defer: 0
- reject: 0
- addressed_findings:
  - `[high]` `[patch]` The pool-construction phrase "where the tag level is known" could launder DSP ratio-class output into draw-pool banding, the exact FR-59a.1 leak. Replaced with an unambiguous face-value-tag rule: no ratio class, DSP estimate, or dsp/tag quantity is consulted at pool-construction time; level resolution only via human verification; cross-band entry only through the band's committed random replacement draw.
  - `[medium]` `[patch]` Replacement surplus guarantee was proven on the census's legacy/mixed banding, not the declared convention; now stated as not yet re-established under full-tempo, with an explicit band-exhaustion escalation rule (HALT the band, operator decides).
  - `[medium]` `[patch]` The per-band budget "roughly 50-60" was unsourced; deleted. Only the sourced ~170-review hypothesis-derived scenario for 100-120 remains; other bands unestimated until the first completed batch measures a keeper rate, with a named re-plan checkpoint owned by the operator.
  - `[medium]` `[patch]` The signoff scope bound less than the protocol's legality rests on; now binds the entire section-2 protocol including the four safe-ordering conditions, the 100-120-first order, batch mechanics, and the tie-break, with a dated-amendment re-signoff rule for mid-verification changes.
  - `[medium]` `[patch]` The faster-level tie-break was buried in recommendation prose and undefined for non-2:1 ratios; now a named signable rule, scoped to 2:1 pairs, with a verbatim-record ratio-ambiguous flag otherwise and the half-tempo inversion stated.
  - `[medium]` `[patch]` One citation of the octave-corrected 786 column lacked the FR-59a.1 caveat and used the column as evidence for which level is right; caveat attached and the column demoted to convention-description evidence.
  - `[medium]` `[patch]` Sentinel-subset rule was one-directional, used two names, left "same recording" and the empty outcome undefined, and silently widened "80-85" to [80, 87.5); all four pinned (reverse clause included, `octave-sentinel` unified, fingerprint join defined, size-0 a recorded result, widening declared as a deviation).
  - `[low]` `[patch]` Band edges pinned half-open [lo, hi) at all six boundaries; surplus-keeper and duplicate tiebreaks defined by committed draw order; annotated span pinned to full track; blinding band-level-prior residual recorded as a limitation; the 18-vs-14 fixture/census delta stated as unreconciled and flagged for Story 12.7's fingerprint join; FR-62 GiantSteps row basis corrected to 661 scored rows; tag naming unified to `metrical-<level>-v1-<signoff-date>` minted at signing; the draft tag string executed through `AnnotationVersion.declared(_:)` via a throwaway test (passed, then deleted); the 12.3 stacked-branch not-yet-PR-reviewed dependency recorded as a signoff risk.

## Verification

**Commands:**
- `git diff --stat 4b66b75 -- Sources/ Tests/` -- expected: empty
- `make test` -- expected: unchanged (1031 tests, 170 suites, 4 known issues) since no code changes

**Manual checks:**
- Every number quoted in the artifact traces to prd.md, epics.md, or a named `_bmad-output/ml-training/` artifact; no new measurements are invented
- The signoff block names the operator decision points: the convention itself, the keep/reject criteria, and the budget

## Auto Run Result

Status: blocked (2026-08-08) -- blocking condition: operator signoff required on the ground-truth rule (FR-59f / epics.md Story 12.6 final AC). All agent-completable work is done and reviewed; the story closes only when the operator signs the declaration artifact.

**Summary:** The Story 12.6 declaration artifact `12-6-metrical-level-convention.md` is written: (1) recommended convention full-tempo (perceptual), argued from the FR-59a.1-clean populations plus detector-comparability and band-design, with the octave-corrected caveat at every citation; (2) FR-59f option-1 hand-verification protocol operationalized (face-value-tag pool banding, four safe-ordering conditions, blinding with recorded residual, 100-120 first, batch mechanics, keep/reject, replacement and exhaustion rules, sourced-only budget, re-plan checkpoint); (3) `octave-sentinel` subset with a two-directional DSP-free membership rule; (4) FR-62 legacy audit (OA300 full-tempo, GiantSteps full-tempo on 661 scored rows, Tony full-tempo after a detector-influenced octave vote, counts only); (5) tag rule `metrical-<level>-v1-<signoff-date>`, draft string executed through Story 12.3's validator; (6) signoff block binding the convention, the entire protocol, and the budget, with the stacked-12.3 dependency risk recorded.

**Files:** `12-6-metrical-level-convention.md` (new), this spec, `epic-12-context.md` (regenerated). `Sources/` and `Tests/` byte-identical to 4b66b75.

**Review:** 15 patches applied (1 high, 6 medium, 8 low), 0 deferred, 0 rejected; no intent gaps, no spec repairs. The high finding was a pool-construction phrasing that could have leaked DSP output into draw membership.

**Verification:** `git diff --stat 4b66b75 -- Sources/ Tests/` empty; `make test` 1031/170/4 green; every quoted number traced to prd.md, epics.md, the three-source census, the Q9 artifact, or the committed OA300 fixture (82/18/13/41 re-verified); tag validator executed, not inspected.

**Residual risks:** the operator may overturn the recommended level (the half-tempo amendment path and tag fallback are pre-written); per-band pool sizes under the declared convention are unmeasured until Story 12.7 re-bands the pool; the 18-vs-14 row-basis delta is unreconciled and assigned to 12.7's fingerprint join.

**Operator actions needed (morning):** (1) unlock 1Password; (2) re-sign or accept the four commits on the stacked branches (DONE 2026-08-08: re-signed as 0fb914b/4b66b75/8a8f751/b19e2a6); (3) push both branches and open PRs (12.3 -> rterhaar/epic-12, then 12.6 -> 12.3's branch or rebase after 12.3 lands); (4) read `12-6-metrical-level-convention.md` and sign or overturn the convention in its section 6 block.
