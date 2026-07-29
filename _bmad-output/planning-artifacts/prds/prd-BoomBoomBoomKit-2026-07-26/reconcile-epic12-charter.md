# Input reconciliation — Epic 12 charter vs. the Epic 12 PRD

**Input:** Epic 12 charter, `_bmad-output/planning-artifacts/epics.md:1796-1872` (rewritten 2026-07-26 under `spec-gh-166-epic12-lever-sequencing.md`), plus the Epic 13 charter at `epics.md:1874-1888`.

**Targets:** `prd.md` (365 lines) and `addendum.md` (79 lines) in `prds/prd-BoomBoomBoomKit-2026-07-26/`.

**Method:** every charter paragraph checked for a PRD counterpart; every PRD claim that restates a charter claim checked for divergence. Greps run against `prd.md` + `addendum.md` for the charter's named artifacts and types. Zero-hit terms are recorded as hard drops, not as paraphrases I failed to spot.

Grep results (occurrences in `prd.md` + `addendum.md` combined):

| charter term | hits |
|---|---|
| `forensic` / `accuracy-forensics` | 0 |
| `selection-bound` | 0 |
| `Submerged` | 0 |
| `beat-grid` / `beatGrid` / `W53` | 0 |
| `SignalPool` | 0 |
| `OctaveEquivalencePolicy` | 0 |
| `resolveOctaveAmbiguity` | 0 |
| `CoreMLTechnique` | 0 |
| `dspOnly` / `ensemblePolicy` | 0 |
| `KDD-B4` / `signoff` | 0 |
| `posterior-derived` | 0 |

---

## 1. Dropped without acknowledgement

### 1.1 The forensic miss-composition — the charter's own "load-bearing evidence" — is gone, and one of its numbers contradicts the PRD

Charter `:1813`, under the heading **"What is still true, and is now the load-bearing evidence"**:

> "The forensic harness stands: OA300's 24 misses are 16 octave + 2 triplet + 6 other, with 21/24 selection-bound and 17/24 carrying truth at candidate rank 1; **GiantSteps' 124 misses are mostly non-harmonic (98 other, 19 triplet, 7 octave)**."

Zero of these figures appear in the PRD. Two consequences:

**(a) A dropped fact that *supports* the PRD.** "21/24 selection-bound, 17/24 with truth at candidate rank 1" is the single strongest argument for F1 — it says the right answer is already generated and merely not chosen, so a reweighting prior has something to reweight. The PRD argues F1 purely from the SMC 2015 citation (`prd.md:77`) and never uses the project's own measurement.

**(b) A dropped fact that *undercuts* the PRD, which is why the drop matters.** `prd.md:46` asserts in the glossary: "**Octave error** | Predicting 2× or ½ the true tempo. **The dominant measured failure.**" On GiantSteps that is false by the charter's own forensics — 7 of 124 misses are octave, 98 are non-harmonic "other". Octave dominance is an OA300 property (16/24), not a project-wide one. The charter itself drew the conclusion the PRD needs and dropped: "**octave decode pays off mostly on OA300**" (`:1872`).

This propagates directly into the F1 evidence base. `prd.md:22` and `:77` justify F1 on Hörschläger et al. SMC 2015 lifting GiantSteps overall 45.5% → 75.0%, "on the same corpus we evaluate against". Our DSP already scores **537/661 = 81.2%** on GiantSteps (the FR-18 bar the PRD cites at `:198`) — *above* the post-prior number in the cited result — and only 7 of our 124 GiantSteps misses are the error class a genre prior addresses. AS-7 (`:364`) covers transfer generically ("the SMC 2015 style-prior result transfers to our corpus and pipeline"), but the specific, already-measured, in-repo counter-evidence is not on the page. A reader of the PRD alone cannot see that F1's headline citation is a result our DSP already exceeds.

### 1.2 The Epic 12 beat-grid / SignalPool octave arbiter (charter ranking item 7) vanished entirely

Charter `:1844`, ranking item 7, "**Octave arbiter from outside the posterior — UNTESTED, and the surviving half of the original item 1**", two forms:

> "(a) wire the idle `OctaveEquivalencePolicy` + DSP `resolveOctaveAmbiguity` as an arbiter through the SignalPool (chartered in 2026-06, never built — GH-141 measured only the decode half); (b) a multi-task beat + tempo head supervised by the Epic 8 Rekordbox beat oracle"

The PRD keeps only the *correction* to form (b) — `prd.md:87-89` reproduces the Sun et al. ISMIR 2021 −4.1pp GiantSteps figure and the "no magic bullet" line. It never states the lever those corrections were attached to. Form (a) — an explicitly never-built, already-chartered lever with two idle types sitting in `Sources/` — is absent from the feature list, from §7 Non-Goals, and from §8.2 Out of Scope. It is not deferred; it is unmentioned.

This is the largest single drop, and it is compounded by §3 below: Epic 13 still claims it.

### 1.3 The charter's general working hypothesis was narrowed to one instance without saying so

Charter `:1811`:

> "**Working hypothesis for the PRD: an octave lever should source its disambiguation from outside the signal that generated the candidate** — a perceptual tempo prior, **beat-grid coherence, file metadata**, or a learned classifier trained to the task."

The PRD implements exactly one of the four (perceptual/style prior, as F1) and one more by accident (the classifier, via Q5's resolution at `:350`). Beat-grid coherence and file metadata are never mentioned in the PRD — `metadata` appears twice and both are `model_metadata.json` (`:189`, `:65`). File metadata is notable because `MetadataCorroborator` already exists, already runs as Phase 2a of selection, and already carries `HarmonicRatio` octave machinery — an outside-evidence octave arbiter that is built and shipping. The charter named it; the PRD does not.

### 1.4 The `#172` fixture evidence lost its specifics, including the fact that one of four is not an octave error

Charter `:1817`:

> "`Meta_Man` 92 → 182.00 (2×), `Meta_Man_La_Noche_Digital_` 96 → 191.76 (2×), `Submerged_Lament` 70 → 140.12 (2×), `robbyt_x-ray-120s` **174 → 115.64 (2/3× triplet)**."

`prd.md:108` (FR-55) reduces this to "the four `AccuracyFloorTests` known-failure fixtures, all of which are DSP-path octave errors with no model involved". **That is wrong on the charter's own data**: the fourth is a 2/3× triplet, not an octave error. A style prior with a DnB 130-180 range would not obviously recover a 174 → 115.64 triplet the way it recovers a 70 → 140 doubling. FR-55's target set is 3 fixtures, not 4, and the PRD asserts 4.

Also dropped: charter `:1819`, "**At least one is a selection failure, not a generation failure.** `Submerged_Lament` had 70 in its own candidate list, scoring 0.97 against 140 at 1.01." A 0.04 score gap between the right and wrong answer is the concrete demonstration that a reweighting prior is sufficient — the exact mechanism FR-54 specifies ("reweights (never hard-filters)"). It survives in the PRD only as the anonymised marketing line at `:30` ("a DSP path that calls a 70 BPM track 140").

### 1.5 The forensic harness itself is not referenced anywhere

Charter `:1872` records `make accuracy-forensics` as landed infrastructure and instructs: "**Use `accuracy-forensics-*.json` as the step-1 / step-2 diagnostic substrate before any retrain.**" It supplies precisely "octave vs triplet vs other error-type histograms, a candidate-recall oracle …, a recall split (selection- vs generation-bound), and a DSP-confidence reliability curve".

FR-55 ("Measure per-band and per-genre"), FR-61 (`Acc2 − Acc1` first-class), FR-71 (per-band lift), and §9's per-band counter-metrics all require exactly this harness. The PRD specifies the outputs and never names the tool that already produces them, so a downstream story will re-derive or re-build it. Zero hits for `forensic` in either target file.

### 1.6 The entire "Enablers" section (charter `:1848-1855`) is absent

Five of six items are dropped silently:

| charter enabler | PRD status |
|---|---|
| **Raw-audio access on the evaluation path** — `MLTechnique.evaluate(trace:)` + `MLFeatureFrames` is the only input path, frozen at 4-5 DD #18; "a backbone wanting its own front end … cannot be tested without a pre-1.0 signature change" | `prd.md:322` restates the freeze as a *constraint* but never as the *blocker* the charter identified. Arguably moot for bigger backbones (§7 excludes them) but not for the addendum's still-open hybrid head (`addendum.md:34`) |
| **C5 tunable abstain thresholds — ALREADY LANDED, do not re-scope** | absent; the anti-rescope warning is lost |
| **C3 — model-bound feature version** | absent. PRD has the parity tripwire (`:305`) but not the binding that stops a model and its substrate drifting apart |
| **C6 — convert-tool featurize contract** | absent. FR-67 (`:194`) touches `tools/coreml-convert/` for the *bin schema* only |
| **D3 — live BNNS/CoreML technique tests** | absent |
| **Full-posterior diagnostic dumps** — "the FR-18 dumps carry only decoded BPM + `softmaxMax`. GH-141 had to build a bespoke harness to measure one rule; any future posterior-derived experiment will need the same thing again" | absent, and this one bites: FR-63's "smearing-versus-one-hot ablation and a sigma sweep" and FR-64's octave-partner-mass evaluation are posterior-derived experiments that cannot be read off the current dumps |

### 1.7 Four of the charter's six "Open scoping questions for the PRD" are unanswered

Charter `:1870` posed six. §14 answers two.

| charter question | PRD |
|---|---|
| "what is the PRD's stopping rule — how many net-negative levers before the epic's premise … is itself re-examined?" | **Answered** — §6, two failures |
| "Does the octave work split into a DSP-selection track (#172, overlapping Epic 13) and an ML track, and who owns the overlap?" | **Answered** — Q6 |
| "does the representation redesign stand alone as a substrate epic between 8 and 12?" | **Unanswered.** §7 defers representation redesign; the sub-epic question is not addressed |
| "**new corpus signoff on par with KDD-B4** against the new representation?" | **Unanswered and operationally blocking.** F3 builds an entirely new corpus (FR-59–FR-59e) and never mentions a signoff. `train.py`'s KDD-B4 gate *fails closed* — per the Makefile, `ml-train-v2` "Requires the KDD-B4 signoff signed (train.py's gate fails closed otherwise)". A new corpus therefore cannot be trained against until a signoff exists. Zero hits for `KDD-B4` or `signoff` in the PRD |
| "does GiantSteps' own **sub-120 annotation set** need an octave-cleanliness audit (the ruler vs the lens)?" | **Partially.** The PRD covers annotation *version* (FR-60, TISMIR 2020 swing at `:93`) and GiantSteps independence (FR-69c.1), but never the sub-120 octave-cleanliness audit the charter asked for — which is odd given F3's whole thesis is that 100-120 is the scarce, least-corroborated band |
| "Should the training-target repair (item 1) and bin-range alignment (item 2) land as **ONE retrain**, since both are cheap and both need a retrain to evaluate?" | **Unanswered.** F4 and F5 are separate features; §6 gates F4 but never gates F5 at all. The charter's own instruction at `:1839` — "Fold into whichever change next bumps `featureSetVersion`" — is also dropped |

### 1.8 Miscellaneous provenance dropped

- The OA300 arm of the FR-18 bundle gate: charter `:1802` "OA300 43/82 **vs >55**". `prd.md:198` states only the GiantSteps arm (≥537/661).
- The runtime citations behind FR-66/FR-67: `BNNSTechnique.swift:884` (decode `30 + argmax`), `:889` (the `60.0...200.0` abstain), `:190` (`expectedBinCount = 256`), and the charter's note that #147's `:857` citation is stale. FR-66/67 keep the substance, lose every line reference — which is the class of error the project's own "factual-claims grep before story spec" rule exists to prevent.
- Genre/tempo mixture-of-experts, charter ranking item 9, "**EXPLICITLY LAST RESORT**": not in §7 Non-Goals. Its cost is acknowledged obliquely at `:350` (Q5's classifier "accepts a router-error failure surface plus a second model in the deployment path — the exact cost the 2026-06-09 roundtable cited when ranking genre-MoE last"), but MoE itself is never ranked or excluded.
- Charter `:1802`: "FR-16's octave-aware *loss* was delivered and the model still doubles — so **loss-only is insufficient**." The PRD makes training-target repair (F4) the lever behind Gate 1 without carrying this caution.

---

## 2. Direct contradictions

### 2.1 The PRD reverses a recorded operator decision on compute, without saying it is doing so

Charter `:1821-1823`, its own section, attributed and dated:

> "### Compute-constraint change (operator, 2026-07-21)
> CPU-only inference is **no longer a requirement**. Larger models are acceptable if accuracy improves, and Apple's bring-your-own-model APIs are in scope."

`prd.md:260`, §7 Non-Goals:

> "**Bigger models.** Capacity is not the constraint (§4.3). AST-as-classifier, EfficientAT fine-tunes and Core AI are out of scope."

Three separate divergences here:

1. **Operator decision vs. PRD ruling.** The charter's relaxation is an operator input; the PRD's exclusion is an evidence-based product call. The PRD may well be right, but it converts an operator constraint-relaxation into an out-of-scope line without recording that it is overriding one. §0 claims only to supersede "the charter's lever *ordering*" (`:14`).
2. **AST-as-classifier: charter says accept, PRD says exclude.** Charter `:1830`: "**AST-as-classifier: ACCEPTED AS A HARNESS EXPERIMENT, gated on the CoreML backend story.**" PRD: out of scope. A flat reversal of an explicit verdict, not a reordering.
3. **The charter's own demotion is weaker than the PRD's exclusion.** Charter item 6 (`:1843`) says "**DEMOTED on evidence 2026-07-27** … treat this lever as **low-priority until item 2's reference-gap diagnosis says otherwise**." Demoted-and-conditional, with an explicit re-open trigger. The PRD hard-excludes it — which then collides with FR-58 (`:118`): "That ranking, not the charter's, drives everything after F2." If F2's ranking surfaces capacity as a suspect, §7 has already forbidden acting on it. AS-2 (`:359`) names the risk but the Non-Goals text does not carry the conditional.

### 2.2 The PRD closes a question the charter deliberately left open

Charter `:1811`, its final sentence:

> "That is enough to stop re-trying those variants — both carry **explicit re-open triggers** in `deferred-work.md` (`:901`, GH-141 blocks) and neither is 'try it again more carefully' — but it is **not** proof that no posterior-derived rule can work on a better-calibrated model. **The ledger deliberately left that open (`:1210`); the charter does not close it.**"

`prd.md:264`, §7 Non-Goals:

> "**Re-litigating the two measured failures.** Closed."

The charter says *the variants* are closed and *the class* is open, with re-open triggers logged in a ledger. The PRD says "Closed" full stop. Since F4/F5 aim at producing a better-calibrated model, and the charter's caveat is scoped precisely to "a better-calibrated model", the PRD's Non-Goal forecloses the one condition under which the charter said the question should be revisited. Zero hits for `posterior-derived` in the PRD.

### 2.3 The ensemble-policy default — the charter's explicit sequencing consequence — is absent, and the PRD's gate depends on it

Charter `:1819`, consequence (a):

> "an ML lever cannot close this class **without also changing the ensemble policy** — these are measured under the default `.dspOnly`, where `MLTechnique.evaluate` is never invoked, so a better model changes nothing here until `.mlOnly` / `.highestConfidence` / `.weightedVoting` is on the default path, **which is its own decision**."

The PRD's entire F6 is built on ensemble lift (FR-68, `:200`; glossary `:49`; §9 primary metric `:282`; AS-4 `:361`), and simultaneously requires at `:303` and `:291` that "DSP-only output remains byte-identical" / "DSP-only path byte-identical". Those are compatible only if `Options.ensemblePolicy` remains `.dspOnly` by default — in which case the demo-app user of §2.1 ("wants correct BPM on drum-and-bass without knowing what a model is") never receives the ensemble lift the gate certifies. The default-flip decision the charter flagged as "its own decision" is nowhere in the PRD. Zero hits for `dspOnly` or `ensemblePolicy`.

### 2.4 The PRD builds a corpus for a band whose only candidate lever it has deferred

Charter `:1842`, ranking item 5 (input-representation redesign): "This is **the only lever that plausibly touches the `100-120` band, which no octave rule can reach.**" Backed by E0 at `:1813`: 100-120 is `Acc1 == Acc2 == 1/35` — "neither half nor double lands, so no octave rule of any kind helps there."

The PRD carries E0's numbers (`:60`) but not the conclusion drawn from them. It then:

- defers representation redesign to §7 Non-Goals (`:266`);
- makes 100-120 the **binding constraint** of the entire F3 corpus build (`:177`: "100-120 is the binding constraint and has effectively no margin … One rejected label drops the band below target and forces uniform n down for every other band with it");
- and reduces the charter's algorithmic finding to a *sourcing* problem in the risk table (`:335`: "The 100-120 band is unreachable | Acknowledged — OA300 has one track there; sourcing is open (Q3)").

That reframe is a contradiction of substance. The charter says 100-120 is unreachable because *no octave rule reaches it and only representation redesign plausibly does*; the PRD says it is hard because *we lack tracks*. On the charter's evidence, adding 27 tracks in 100-120 to the evaluation corpus buys a better measurement of a failure no in-scope lever can fix.

### 2.5 F2 has no charter antecedent — and the charter's cross-reference to it is broken

`prd.md:12` and §0 frame the PRD as operationalizing the charter. F2 (reference-gap diagnosis, FR-56/57/58) is **not** in the charter's corrected ranking (`:1838-1846`, items 1-9) and is not in the SUPERSEDED list either. The only trace is charter `:1843`: "treat this lever as low-priority until **item 2's reference-gap diagnosis** says otherwise" — but charter item 2 is *bin-range alignment* (`:1839`), not a reference-gap diagnosis. The charter's cross-reference points at the wrong item, i.e. the charter has a dangling pointer to a lever it never chartered.

F2 is a good addition and the PRD's strongest structural contribution. But §0's framing ("Turns the Epic 12 charter into scoped, gated requirements") understates it, and the charter's broken pointer should be fixed rather than inherited silently.

### 2.6 Two PRD-internal inconsistencies produced by the reconciliation

- **"Primary corpus" vs. "no single primary."** §9 (`:282`): "Ensemble Acc1 lift over DSP-alone on **the primary corpus**." Q1 (`:346`), settled by the operator: "**no single primary.** Lift must appear on two of the three." §9 was not updated when Q1 resolved.
- **FR-59's new corpus vs. FR-68's three corpora.** FR-59 builds a fourth, band-balanced, ~162-track corpus and says it "**blocks the bundle gate**" (`:139`). FR-68's gate is defined over "the three evaluation corpora" (OA300 / GiantSteps / Tony, per Q1). Whether the new corpus replaces one, joins them as a fourth, or *is* the gate is never stated. FR-69a's partial-conjunction rule is written for exactly three p-values.

---

## 3. Is the Epic 13 duplication accurately described?

**No. It is mis-described in one direction and materially under-described in two others, and there is a live conflict the PRD does not record at all.**

The PRD's claim, stated twice:

- `:110`: "This lever is DSP-side and overlaps Epic 13. **Ownership settled 2026-07-28: Epic 12 owns it** (§14 Q6). The overlapping Epic 13 claim is a recorded duplication to settle when that charter is next opened, and no longer gates this work."
- `:351` (Q6): "Both charters claim the DSP octave levers … **Epic 13's overlapping claim on the DSP octave levers is now a recorded duplication.**"

Epic 13's actual scope (`epics.md:1880-1887`), verbatim:

1. `:1881` — "**Phase 0.5 — offline ceiling sweep** (no shipped DSP): from the forensic JSON, compute the octave-resolver ceiling (sweep the hand-tuned `0.3`/`0.5` `resolveOctaveAmbiguity` thresholds + sub-band vote weights on an OA300 dev slice, report OA300 holdout + GiantSteps once) vs the candidate-recall ceiling. **Whichever is higher picks Phase 1.**"
2. `:1882` — "**Beat-grid-support candidate rescoring** (W53/W74 …) … **Overlaps Epic 12's beat-grid-arbiter idea — coordinate.**"
3-6. `:1883-1886` — sliding/aggregated tempogram; `subBandEmphasis`; multi-region anchor; normalized ACF. None of these touch F1.

### 3.1 Epic 13 never claims F1

Nothing in Epic 13's six-item scope is a tempo search range, a consumer-specifiable range, or a style-conditioned prior. `#172` appears **only** in Epic 12's charter (`:1819`, `:1840`), where Epic 12 unilaterally asserts the overlap ("Coordinate with Epic 13 so the two epics do not both claim it"). Q6's premise — "Both charters claim the DSP octave levers" — is not supported by Epic 13's text for F1. The operator's ruling is fine; the stated conflict it resolves is, for F1, one charter's assumption about another charter rather than a textual collision.

### 3.2 Epic 13 claims two things Epic 12's PRD dropped, so the PRD cedes them by omission rather than "recording a duplication"

- **`resolveOctaveAmbiguity` threshold sweep** (Epic 13 item 1) vs. Epic 12 charter ranking item 7(a), "wire the idle `OctaveEquivalencePolicy` + DSP `resolveOctaveAmbiguity` as an arbiter through the SignalPool" (`:1844`). Both charters name the same function. The PRD dropped item 7(a) entirely (§1.2 above), so this lever is now claimed only by Epic 13 — but the PRD tells the reader Epic 12 *won* the DSP-octave-lever ownership dispute. The two statements together produce an orphan: a lever Epic 12 no longer specifies, that Epic 13 still holds, under a PRD sentence implying Epic 12 took it.
- **Beat-grid-support candidate rescoring** (Epic 13 item 2) vs. Epic 12 charter item 7(b) + the reciprocal "Overlaps the Epic 13 beat-grid-support rescoring idea (W53/W74) — coordinate so both epics do not build it" (`:1844`). This is the one duplication both charters flag *bilaterally and by name*. The PRD does not mention beat-grid at all (0 grep hits). So the single explicitly mutual duplication in the two charters is the one the PRD's "known duplication" note does not cover.

### 3.3 Epic 13 claims something stronger than duplication: a sequencing gate over the DSP path

Epic 13's scope header, `:1880`: "**Provisional scope (sequenced — Phase 0.5 ceiling sweep CHOOSES the first move; do NOT pre-commit)**."

Epic 12's PRD pre-commits F1 as an MVP first move on the DSP path (`:272`, `:274`: "F1 carries the highest published evidence in the epic"). If Epic 13's charter still stands as written, Epic 12 has pre-committed a DSP-path first move that Epic 13 says must be *chosen* by a sweep nobody has run. Q6's resolution assigns *ownership of a lever*; it does not dispose of Epic 13's *sequencing rule* over DSP-path changes. Calling this "a recorded duplication to settle when that charter is next opened" understates it: it is a live procedural conflict, and Epic 13 is the charter that says "do NOT pre-commit."

### 3.4 The PRD invalidates Epic 13's acceptance gate without saying so

Epic 13's discipline, `:1888`:

> "**≥2-track OA300 margin (1 track ≈ 1.2pp, below the ~5pp binomial SE)**; no GiantSteps regression for a default-path change …"

`prd.md:203-221` (FR-69) demolishes exactly that rationale:

> "~~Existing discipline is ≥2 OA300 tracks (1 track ≈ 1.2pp against a ~5pp standard error).~~ The ~5pp figure is `sqrt(p(1-p)/n)` for a *single* proportion at n=82 … **A 2-track net lift can never be significant.** … **'≥2 tracks' survives only as a product-value floor** … **and must never again be described as justified against noise.**"

The struck sentence is Epic 13's gate, near-verbatim, including the parenthetical. The PRD is right on the statistics and wrong to leave the consequence unstated: F1 is a DSP default-path change that the PRD claims for Epic 12, and it is now unclear which gate governs it — FR-69's McNemar table (8 net OA300 tracks at 10% discordance) or Epic 13's shipped ≥2-track discipline. The PRD's own §7 exclusion of "re-litigating" does not reach this, and FR-55 (`:108`) specifies F1's measurement without naming any acceptance threshold.

### 3.5 One asymmetry worth noting

`prd.md:14` claims the PRD "supersedes the charter". It can supersede Epic 12's charter. It cannot supersede Epic 13's, which is a separate live document that still contains items 1 and 2 unamended. Until `epics.md:1874-1888` is edited, the Q6 resolution exists only inside this PRD, and any reader starting from `epics.md` sees Epic 13 holding `resolveOctaveAmbiguity` and beat-grid rescoring with no note that Epic 12 took anything.

---

## 4. Recommended fixes, ranked

1. **Restore the forensic miss-composition** (`epics.md:1813`) into §4 and correct the glossary's "the dominant measured failure" to name the corpus asymmetry (OA300 16/24 octave vs. GiantSteps 7/124). Then reconcile F1's SMC 2015 evidence against our DSP's 81.2% GiantSteps Acc1 — the cited result's post-prior score is 75.0%.
2. **Fix FR-55**: one of the four fixtures is a 2/3× triplet, not an octave error. Restore the four fixture values and the `Submerged_Lament` 0.97-vs-1.01 selection-failure datum.
3. **Decide, in writing, what happens to charter ranking item 7(a)** — the `OctaveEquivalencePolicy`/`resolveOctaveAmbiguity`/SignalPool arbiter. Own it, defer it, or cede it to Epic 13 explicitly. Right now it is orphaned under a PRD sentence implying Epic 12 took it.
4. **Rewrite §5.1's Epic 13 note and Q6** to say what is actually true: Epic 13 does not claim F1; Epic 13 *does* claim the `resolveOctaveAmbiguity` sweep and beat-grid rescoring; Epic 13's "Phase 0.5 chooses the first move" sequencing rule conflicts with F1-as-MVP; and FR-69 invalidates Epic 13's ≥2-track gate rationale. State which gate governs F1.
5. **Address the `.dspOnly` default.** FR-68's ensemble lift and NFR "DSP-only byte-identical" cannot both hold for a shipping user without an explicit ensemble-policy default decision.
6. **Answer the four unanswered charter scoping questions**, KDD-B4-equivalent corpus signoff first — `train.py`'s gate fails closed, so F3's corpus cannot be trained against without it.
7. **Reconcile the compute Non-Goal with the operator's 2026-07-21 relaxation** and the charter's *conditional* demotion of item 6. Either record that the PRD overrides the operator decision, or restate the exclusion as conditional on F2's ranking, matching FR-58.
8. **Restore the enablers list**, at minimum full-posterior diagnostic dumps (FR-63/FR-64 need them) and the `accuracy-forensics` harness (FR-55/FR-61/FR-71 need it).
9. **Fix the two PRD-internal inconsistencies**: §9's "primary corpus" vs. Q1's "no single primary"; FR-59's fourth corpus vs. FR-68's three.
