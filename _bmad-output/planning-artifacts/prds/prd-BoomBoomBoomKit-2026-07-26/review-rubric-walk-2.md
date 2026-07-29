# PRD Verification Re-Review — Epic 12

Second pass, 2026-07-29. Scope: verify the fixes applied after `review-rubric-walk.md`
returned PASS WITH FINDINGS, and hunt for defects the fixes introduced.

Not a re-walk of the rubric. Every arithmetic claim below was recomputed from source
(`non-rekordbox-survey.json`, `accuracy-forensics-*.json`, `AccuracyFloorTests.swift`,
`octave_aware_loss.py`) or by exact two-sided McNemar computed here.

---

## Verdict

**FIXES PARTIAL.**

Four of the six verifications hold cleanly. Two do not. The statistical work is
exemplary — I recomputed the entire α=0.025 correction and the entire new feasibility
table exactly, and every value is right. The evidence corrections (octave dominance,
the triplet fixture, the one-hot contradiction) are right to the digit.

What went wrong is the thing the brief anticipated: **layering.** The corpus
correction changed the headline number from 162 tracks to 258 and then updated only
three of the seven places that depend on it. The result is that §5.3 now contradicts
itself twice within twenty lines, one retracted claim is reasserted verbatim three
lines after its own retraction, and FR-59c's central arithmetic claim — which FR-71,
FR-68 and Q11 all rest on — became **false** as a direct consequence of the resize.

Separately, the AST correction was applied to the top of the addendum section and not
to the bottom, leaving the retracted conclusion standing under the heading
"**Conclusion carried into the PRD**."

---

## Per-item verification

### 1. Corpus label rule (was CRITICAL) — **PARTIAL FAIL**

**The selection basis is genuinely fixed, and the new numbers are exactly right.**

Recomputed from `_bmad-output/ml-training/non-rekordbox-survey.json`, banding on
`fileMetadataBPM` only, `dspBPM` ignored entirely:

| Band | PRD claims | I compute | ✓ |
|---|---|---|---|
| <100 | 1,996 | 1,996 | ✓ |
| 100-120 | 262 | 262 | ✓ |
| 120-140 | 52 | 52 | ✓ |
| **140-160** | **43** | **43** | ✓ |
| 160-175 | 102 | 102 | ✓ |
| 175+ | 113 | 113 | ✓ |
| total tagged | 2,568 | 2,568 | ✓ |

Scarcest band is 140-160 at 43 ✓. 6 × 43 = 258 ✓. The DSP-agreement figure the PRD
retracts (28 in 100-120) also reproduces exactly, as does 217 for 100-120 under DSP
banding — so the retraction is correctly grounded.

Recomputed McNemar at α = 0.025 (exact two-sided, `b ~ Bin(d, 0.5)`):

| discordance | d = round(rate × 258) | PRD min net lift | I compute | ✓ |
|---|---|---|---|---|
| 5% | 13 | 9 | 9 (11:2, p=0.0225) | ✓ |
| 10% | 26 | 14 | 14 (20:6, p=0.0094) | ✓ |
| 20% | 52 | 18 | 18 (35:17, p=0.0175) | ✓ |

Percentages check: 9/258 = 3.49% → "3.5%" ✓; 14/258 = 5.43% → "5.4%" ✓;
18/258 = 6.98% → "7.0%" ✓.

**Everything the correction newly asserts is correct. What it failed to do is
propagate.** Five defects, three of them serious:

- **CRITICAL — the retracted claim is reasserted three lines after its retraction.**
  Line 172 says "on the compliant basis, 100-120 is not the binding constraint and
  there is no one-track margin." Line 185 says "The scarcest band is 140-160 at 43,
  not 100-120 at 28." Then line 193 says "Two findings remain unchanged and still
  hold," and finding 1 reads: "**100-120 is the binding constraint and has
  effectively no margin** … 262 tagged tracks but only 28 where tag and DSP agree …
  **do not treat 28-for-27 as satisfied.**" That is the DSP-agreement-derived
  conclusion the correction exists to withdraw, restated as a surviving finding, with
  the same 28 and the same 27. A reader reaches the correction, then reaches its
  negation, and the negation is the one flagged in bold as still holding. (Also: "Two
  findings remain unchanged" introduces **three** numbered items.)

- **CRITICAL — at n = 43 the margin is zero, not "no margin problem."** 140-160 has
  exactly 43 available. Setting uniform n = 43 consumes the band completely. One label
  rejected on review drops n for all six bands — the identical failure mode the
  correction claims to have dissolved, relocated from 100-120 to 140-160 and made
  worse (0 slack rather than 1). The PRD asserts the opposite ("there is no one-track
  margin") and never states a review margin for the new binding band. FR-59f's own
  logic — that labels are unvalidated and some will be rejected — makes a zero-margin
  n indefensible.

- **HIGH — the 43/258 figure is derived from the wrong population.** FR-59 sources the
  evaluation corpus "across OA300, Tony's Rekordbox collection, and the Story 7.2
  non-Rekordbox pool." The feasibility table counts the **pool alone**. Adding the
  §5.3 band table's other columns: 140-160 has 15 (OA300) + 372 (Tony) + 43 (pool) =
  430 available, not 43. Under FR-59a.2 (no artist in both eval and any training set)
  Tony is excluded, giving 15 + 43 = 58 — so n = 58 and a 348-track corpus, still not
  258. Neither 162 nor 258 follows from the stated sourcing. The error is not
  conservative in a safe direction: it under-sizes the corpus and therefore weakens
  the gate the corpus exists to power.

- **HIGH — the cited source artifact still asserts the retracted rule.** The PRD
  points at `_bmad-output/ml-training/non-rekordbox-band-feasibility-2026-07-29.md`
  for "full analysis." That file is unamended: its Headline still reads "Every band
  clears 27 tracks on the highest-confidence subset," its feasibility table is still
  the DSP-agreement table, and its conclusion 3 still reads "**100-120 should be
  treated as the binding constraint** on uniform n … At 28 available for a 27 target
  there is none." The PRD's finding 1 is a verbatim carry-over from it. The stale
  claim therefore survives in **both** documents, and the PRD's own citation
  contradicts the PRD.

- **MEDIUM — circularity in the label-quality argument.** Finding 1 uses DSP-agreement
  *rates* as evidence that 100-120's labels are poorly corroborated, while FR-59a.1
  forbids DSP agreement as a selection signal. If DSP agreement is admissible as a
  diagnostic of label quality, the original selection rule was defensible and the
  correction over-reaches; if it is inadmissible, finding 1's argument has no support.
  The PRD needs to pick one. As written it uses the forbidden signal to argue about
  the very band it stopped using it to select.

**Does FR-59f adequately govern label validation? — partially.**

What it gets right: it names the problem precisely (a tag is one unverified
assertion), it enumerates three mutually exclusive options, it requires the choice be
recorded with the corpus, and it declares a hard block ("until this is settled the
corpus cannot be built"). That is more governance than any other F3 requirement has.

Four gaps:

- No owner, no date, no decision criterion. It is the third FR in F3 (with FR-59b and
  now Q11) that blocks work and specifies no way to become unblocked. F3 remains a
  chain of mutual blockers with no entry point.
- Option 1's tractability claim is unsupported. "258 tracks is tractable by hand" cites
  the DAW-oracle workflow as precedent — that workflow produced **23** verified
  annotations out of OA300's 82. An 11× scale-up is asserted, not estimated, and the
  annotator is unnamed. The prior review's "who does the manual annotation" finding is
  unclosed.
- Option 3 ("tag-only, declared as such … the gate's conclusions hedged accordingly")
  has no operational content. "Hedged" is not a procedure. Taking option 3 would make
  FR-68's pass/fail uninterpretable, which is a larger consequence than the sentence
  admits — it should either be dropped or given a stated confidence discount.
- It does not address label *convention*, only label *validity*. A correct tag at the
  wrong metrical level passes all three options and still poisons the corpus. FR-59b
  covers that, but FR-59f does not cross-reference it, so a reader could satisfy FR-59f
  completely and still have a two-convention corpus.

### 2. F1 classifier (was CRITICAL) — **PASS, with unpropagated residue**

FR-54a is honest. It states the classifier is "an unscoped second model, and this PRD
does not build it," enumerates the four things nothing specifies (training corpus,
taxonomy, accuracy gate, size/latency budget), names the tension with the operator's
small-model constraint, and concludes "**that justification no longer holds as
written**." It does not paper over anything. It scopes its own consequence correctly
("Blocks F1's MVP claim, not F1 itself") rather than overclaiming.

Residue the fix did not touch:

- **§8.1's rationale is unchanged**: "none needs a retrain, all are cheap relative to
  training." That is the sentence FR-54a refutes, and it is still the PRD's only
  effort statement, in the section a reader consults to decide whether to fund the MVP.
  FR-54a corrects the claim 190 lines earlier than the place the claim is made.
- **§13 still has no router-error risk row.**
- **Q5 remains struck as RESOLVED** while FR-54a proposes reopening it ("or revisit Q5
  in favour of the caller-declared option"). §14's live list does not include it.

### 3. Alpha inconsistency (was CRITICAL) — **PASS**

FR-69's new note is exactly right. Verified by exact two-sided McNemar:

| d | min t at α=0.05 | min t at α=0.025 | PRD note | ✓ |
|---|---|---|---|---|
| 25 | 11 (18:7, p=0.0433) | **13** (19:6, p=0.0146) | "13 not 11" | ✓ |
| 66 | 18 (42:24, p=0.0356) | **20** (43:23, p=0.0187) | "20 not 18" | ✓ |
| 132 | 24 (78:54, p=0.0449) | **28** (80:52, p=0.0184) | "28 not 24" | ✓ |

The two unchanged rows are also correctly unchanged: d=8 → 8 and d=16 → 10 at both α.
The framing ("Read the table as a floor, then apply FR-69a") is the right fix — it
keeps the α=0.05 table as the single-corpus reference and names FR-69a as operative,
rather than silently rewriting the table. FR-69a's own "~8 on OA300 and ~20 on
GiantSteps" re-verifies.

**Not fixed (carried from the prior review's same finding):** FR-59c still states its
per-band floor at α=0.05 — "cannot reach `p <= 0.05`" and "a band needs at least 6
discordant tracks." Under FR-69a's operative 0.025 the floor is **7**: 6:0 gives
p = 0.03125 (fails), 7:0 gives p = 0.015625 (passes). The prior review named this
explicitly and it was left.

### 4. FR-68 / Q10 / Q11 (was CRITICAL) — **PASS, with two gaps**

Q10 captures "which corpora" well: it names all three candidate answers and both
internal contradictions by section (§5.3 excludes GiantSteps, §5.6 keeps it, §9 still
says "primary corpus"). Q11 captures the no-regression gap correctly and states the
right remedy — a predeclared per-band noninferiority margin in tracks — and gives the
right reason ("'no significant regression' is not evidence of no regression"). Both
are tagged **Blocks F6**. FR-68's inline flags mirror them. This is a proper fix.

Gaps:

- **Q10 does not capture that the arms overlap by construction.** FR-59 draws the
  balanced corpus *from* OA300 and Tony, so "the new corpus with the legacy ones as
  external validation" is not external validation — the same track can score in two
  arms, and FR-69a's partial-conjunction rule is being applied to arms that share
  material. The prior review raised this; Q10 enumerates the options without it, so
  whoever answers Q10 can pick option 3 without knowing it is unsound.
- **Q11 duplicates FR-69c item 4** ("predeclare each band's noninferiority margin and
  treat one-track bands as unmeasurable") without cross-referencing or superseding it.
  Two live homes for one open item.
- §9's Primary metric ("on the primary corpus") is still uncorrected. Q10 documents
  the contradiction rather than resolving it, which is legitimate, but §9 continues to
  assert a metric definition the PRD knows is wrong.

### 5. `ensemblePolicy` default (was HIGH) — **PASS**

FR-72b is a clean fix. It states the current default (`.dspOnly`), names why it
matters in one sentence a maintainer can act on ("A model can therefore clear every
gate in F6 and change nothing any user sees"), enumerates all three positions with
their costs, and picks one on a stated ground ("The third is the only one consistent
with FR-73"). It also implicitly disambiguates the §10 byte-identity NFR by describing
it as "the byte-identity contract that `.dspOnly` currently guarantees" — i.e. policy-
scoped, not default-scoped.

Two loose ends: §10's NFR and §9's counter-metric still read as unqualified "DSP-only
path byte-identical" at their own point of use, and FR-72b ends "should be confirmed
rather than assumed" — a fifth undecided item that §14 does not list (see New Defect 4).

### 6. Octave dominance / FR-55 triplet / one-hot / AST — **3 PASS, 1 FAIL**

**Octave dominance — PASS, exact.** Verified against
`_bmad-output/implementation-artifacts/accuracy-forensics-{oa300,giantsteps}.json`:

- OA300: `exact` 58 → 82 − 58 = 24 misses. Octave = `double` 11 + `half` 5 = **16**.
  Triplet = `twoThird` 2 + `threeHalf` 0 = **2**. `other` = **6**. 16+2+6 = 24 ✓.
- GiantSteps: `exact` 537 → 661 − 537 = 124 misses. Octave = 5 + 2 = **7**.
  Triplet = 10 + 9 = **19**. `other` = **98**. 7+19+98 = 124 ✓.

The Glossary entry matches every figure and both totals. The retraction ("Calling it
'the dominant measured failure' without qualification was wrong") is accurate and no
unqualified restatement survives — I grepped both documents for "dominant"; the four
other hits are all about DnB corpus composition, not error type.

**FR-55 triplet — PASS.** `Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift` has
exactly four `knownFailure` entries: three `octave-doubled` (lines 112, 115, 118) and
one at line 126, `robbyt_x-ray-120s`, `trueBPM: 174`, labelled
`"triplet-related: reports ~115.6, two-thirds of 174 (3:2)"`. The PRD's correction
names the right fixture, the right line, and the right ratio (the file's own header
records 33.54% error → 115.64 → ratio 1.5047 ✓). It also draws the right consequence
("a lever that fixes one need not touch the other") and links it to Q9.

*Not addressed:* the prior review's second half of this finding — `epics.md:1819`
records `Submerged_Lament` as a **selection** failure, not a generation failure, and
FR-55 still does not distinguish the two classes or say which of the four F1 is
expected to move.

**One-hot contradiction — PASS.** Verified `_bmad-output/ml-training/ablation/
octave_aware_loss.py:77-78`: `octave_mass: float = 0.15`, `label_smoothing: float =
0.05`. The correction paragraph in §4.3 is accurate, names both passages, and draws
the operative consequence (FR-63's ablation must *construct* a one-hot baseline). No
"identical to ours" text survives anywhere in either document. FR-63 and AS-6 remain
consistent with it.

**AST evidence block — FAIL. The retracted claims survive, including under the
heading that hands them to the PRD.**

The addendum's CORRECTION block (lines 30-48) is correct and well-argued, and
`prd.md:289` correctly reflects it ("Not rejected on 'head shape' or on mean
collapse"). But addendum lines 50-54 — the original text — were left in place beneath
it and say the opposite:

- Line 50, "**Reading.**": "tracks far from it collapse toward ~125-135. This is
  regression to the conditional mean… **The 71 BPM case is decisive** — the prediction
  is 133.5… **this value corresponds to nothing.**" Line 42 retracts precisely this:
  "**The example called decisive was wrong.** `71 → 133.5` was described as
  corresponding to nothing; 133.5 is within **6.0%** of the octave (142)." (Verified:
  |133.5−142|/142 = 5.99% ✓; and `89 → 129.2` vs 1.5×89 = 133.5 is 3.2% ✓.)
- Line 52: "None of these rescues a scalar head."
- Line 54: "**Conclusion carried into the PRD:** the failure is the head, not the
  backbone." Line 40 retracts this in as many words: "'The failure is the scalar head,
  not the AST backbone' **is unsupported.**"

So the addendum contains a labelled conclusion, described as the one carried into the
PRD, that the PRD explicitly does not carry and that the addendum itself refutes
fourteen lines above. This is the exact "stale version of the old claim survives"
failure the brief asked about, and it is in the load-bearing sentence.

The subsample figures themselves are internally sound — I recomputed the ten-row table:
mean |error| = 202.1/10 = 20.21 ("MAE 20.2" ✓) and 4 rows inside 4% ("4 of 10" ✓) — so
the correction's diagnosis (the subsample was real but unrepresentative) holds. The
fix needed is deletion of lines 50-54, not recomputation.

---

## New defects introduced by the fixes

**ND-1 (CRITICAL). The 162 → 258 change was applied to three places and skipped four,
inside the same section.**

Carrying **258 / n=43**: FR-59f (line 153), FR-68's Q10 flag (222), Q10 (372).
Still carrying **162 / n=27**:

| Line | Text | Status |
|---|---|---|
| 143 | FR-59: "roughly 27, for about 162 tracks total" | stale — this is the requirement itself |
| 145 | FR-59: "At 162 tracks and 10% discordance… net lift of 10 tracks (6.2%)" | stale |
| 150 | FR-59c: "At 27 tracks per band…" | stale **and now false — see ND-2** |
| 160 | FR-59d: "Truncating training data to ~162 tracks…" | stale |
| 260 | FR-71: "at ~27 tracks per band" | stale |

FR-59 — the requirement that defines the corpus — states 162 twelve lines above a
block stating 258. A story author implementing FR-59 will build the wrong corpus.

**ND-2 (CRITICAL). FR-59c's arithmetic became false at n = 43, and FR-71, FR-68 and
Q11 all depend on it.**

FR-59c states: "At 27 tracks per band, exact McNemar cannot reach `p <= 0.05` at 10%
or 20% band discordance." True at 27 (10% → d=3, p=0.25; 20% → d=5, 5:0 p=0.0625).

**False at 43.** 20% of 43 = 8.6 → d = 9. A 9:0 split gives exact two-sided
p = 2 × 2⁻⁹ = **0.0039** — significant at both 0.05 and 0.025. Even d = 8 gives
p = 0.0078. So at the corpus the PRD now specifies, a per-band significance claim
**is** reachable at 20% band discordance.

This is not cosmetic. FR-59c is the stated justification for FR-71 being "descriptive,
not inferential," it is cited by name in FR-71, and it is the premise Q11 and FR-69c.4
use to argue that no-regression needs a noninferiority margin instead of a
significance test. The resize strengthened the corpus and nobody re-derived what that
buys. The correct restatement at n=43 and α=0.025: unreachable at 10% discordance
(d=4, 4:0 → p=0.125), reachable at 20% (d=9, needs 9:0). That is a materially
different requirement.

**ND-3 (HIGH). The feasibility table's margin column is computed against the abandoned
target.** The table header reads "vs 27" and the column shows +1,969 / +235 / +25 /
+16 / +75 / +86 — margins against n=27, three lines above the sentence adopting n=43.
At n=43 the true margins are +1,953 / +219 / **+9** / **0** / +59 / +70. The two bands
that actually constrain the build (120-140 at +9, 140-160 at 0) are invisible in the
table as presented, and the +16 in bold for 140-160 reads as comfortable when it is
the number that was consumed to set n.

**ND-4 (MEDIUM). §14's live-item count went from wrong-by-9 to wrong-by-4, and the
fixes are what added the new ones.** The preamble now says "**Four items remain
live**" (Q8, Q9, Q10, Q11) — an improvement. But the fix round introduced at least
three more undecided items and filed none of them in §14:

- **FR-59f** — "Until this is settled the corpus cannot be built." A hard blocker on
  F3, stated as a requirement, absent from §14.
- **FR-54a** — "Either scope the classifier as its own feature… or revisit Q5." An
  open branch that would reopen a struck question.
- **FR-72b** — "should be confirmed rather than assumed."

Plus the pre-existing FR-69c items 1-5, FR-72a items 1-3, and Q1's own trailing "Two
caveats… not yet resolved," none of which moved. The prior review's fix instruction
was to promote open items *into* §14; the fixes instead added three more open items
*outside* it.

**ND-5 (MEDIUM). FR-59f is mis-numbered and mis-referenced.** It is placed between
FR-59c and FR-59d, so the sequence reads 59, 59a, 59b, 59c, **59f**, 59d, 59e — the
suffix ordering the prior review praised for hygiene is now broken. And the feasibility
block at line 193 says "**FR-59f** below governs" while FR-59f is 41 lines **above**
it. Either move FR-59f after FR-59e, or renumber it 59c-bis; fix the direction word.

**ND-6 (LOW). Stale count in §5.3.** "That single fact generated four of the seven §14
questions" — there are now eleven. And §14 lists its live items out of order (Q8, Q10,
Q11, Q9).

---

## Prior findings the fix round did not touch

Not re-argued, listed so they are not assumed closed by this pass:

- §4.4 "**UNTESTED inference.** … FR-59 tests this" vs AS-5 "**LARGELY CONFIRMED**",
  with FR-59 containing no confirm-or-refute step. Unchanged, and it now also
  contradicts FR-59b's "makes AS-5 a property of the *old* corpora."
- §13 row "FR-59 and FR-62 test and record the convention" — FR-62 is subsumed.
- §13 row "sourcing is open (Q3)" — Q3 is resolved and struck.
- §13 has no row for classifier router error, corpus-build schedule, ensemble-default
  flip, or demo-archive size.
- §11 "the stratified split (FR-59) is for octave testing, not training" — FR-59's
  superseded shape.
- §9 Primary and Secondary metrics unanchored (Q10 now documents the Primary problem).
- §14 Q4 → FR-62a for costs that were deleted with the struck text.
- FR-59a.2 (no artist in both eval and training) vs FR-59 sourcing from Tony's
  Rekordbox collection — and this now also breaks the 43/258 derivation, see item 1.
- No stopping gate on F3; no per-lever retrain budget.
- "Balancing strengthens the aggregate gate" still attributes to balance an effect of
  `n` (and the effect is now larger, since n went 162 → 258, which makes the
  misattribution more visible rather than less).
- Band boundaries still undefined and absent from the Glossary — which matters more
  now, because the new 43 depends on `140 <= bpm < 160` being the intended rule.
- "by tag it is 78% sub-100, by DSP 65% at 160-175, describing identical files" — the
  denominators are still 2,568 and 4,753. On the tagged 2,568 alone the DSP figure is
  1,855/2,568 = 72%, not 65%. The "identical files" claim remains false as written, in
  both the PRD and the source artifact.

---

## Minimum set to close before a Story 12.x touches F3 or F6

1. Delete or rewrite feasibility finding 1; fix "Two findings" → three.
2. Propagate 258 / n=43 into FR-59, FR-59d, FR-71; recompute FR-59c at n=43 and state
   the 20%-discordance case honestly.
3. State the review margin: n < 43 (or re-derive n over the actual three-source
   population, which is the real fix).
4. Amend `non-rekordbox-band-feasibility-2026-07-29.md` or stop citing it.
5. Delete addendum lines 50-54.
6. Restate FR-59c's discordance floor at α=0.025 (7, not 6).
7. File FR-59f, FR-54a and FR-72b's open branches in §14.

Items 1, 2, 4 and 5 are text deletions or number substitutions. Item 3 is a real
decision. Nothing here requires restructuring.

---

## Count

| Severity | New | Verifications failed |
|---|---|---|
| critical | 2 (ND-1, ND-2) | item 1 (partial), item 6 AST |
| high | 1 (ND-3) | — |
| medium | 2 (ND-4, ND-5) | — |
| low | 1 (ND-6) | — |

Plus 4 unpropagated residues inside otherwise-passing fixes (items 1, 2, 3, 4) and
~13 prior findings untouched.
