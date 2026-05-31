# PRD Quality Review — ML Retraining, Multi-Signal Ensemble, and Selection-Strategy Documentation

## Overall verdict

This PRD is strong on developer-outcome discipline, scope honesty about deferred type-taxonomy, and substantive cross-cutting risk linkage — Epic A's signal-pool rewrite, Epic B's bundling gates, and Epic E's `DocumentedCase` proposal each carry their thesis through to acceptance criteria. The principal risks are: (1) several FRs name testable thresholds but defer the actual numbers to "the test/eval plan" without locking the gate before the epic can close (FR-29, FR-34, FR-25), (2) Epic D's UX FRs lean adjective-heavy in a few spots where bounds are achievable, and (3) the open-items density — ~25 KDDs and 5 cross-cutting KDDs — is high for green-light-to-build but consistent with the explicit "architect picks" frame. Mechanical hygiene around FR numbering gaps (48 moved, 51 dropped) is documented in-line and survives reviewer scrutiny.

## Decision-readiness — strong

Trade-offs are surfaced honestly. Every KDD names the alternatives, not just the chosen path: KDD-A1 lists three voting-policy shapes with party-mode vote distribution; KDD-C1 lists three beat-tracking algorithms with the GPL-licensing constraint that knocks one out at the edge; KDD-E2 cites Apple's `CaseDisplayRepresentable` as inspiration but explicitly says it is NOT direct precedent (per-instance vs static-map shape differs). FR-15's reasoning paragraph ("on a 1,344-track / ~250-artist corpus, artist embedding memorizes rather than generalizes; ID3 BPM as model input would double-count an existing peer voter") is exactly the kind of named-tradeoff-with-loss decision-readiness the rubric asks for.

FR-18 spells out the bundle-vs-BYOW branching gate in plain terms (the four gates a-d), and the decision log shows operator endorsement. The pre-1.0 BC framing is stated repeatedly (NFR-4, the closing cross-cutting risk) rather than buried.

A decision-maker reading the Open Questions section sees ~25 KDDs with their resolution location (architecture doc, training plan, doc-authoring guide) — that is decision routing, not decision dodging.

### Findings
- **low** Epic A KDD #6 (post-merge boundary collapse) appears in Open Questions but not in Epic A's "KDDs deferred" list — the inline FR-7 prose hints at the collapse, but the architectural decision itself is split across two sections. *Fix:* Add KDD-A6 to Epic A's "KDDs deferred to architecture doc" list to match the Open Questions entry.

## Substance over theater — strong

No persona theater (this is a developer-audience library PRD; persona elaboration would be overhead — see Shape fit). No vision theater — the Vision statement names three specific outputs (BPM/LUFS/beat-grid), the architectural spine (unified weighted voting), and a hard constraint (zero external dependencies). It is not interchangeable with a generic audio-library PRD.

No innovation theater — the only novelty claims (unified-peer-signal voting replacing today's post-merge corroboration) are grounded against pre-existing invariants in the decision log: NFR-4 explicitly names what is being broken (`MetadataCorroborator.apply` post-merge boundary, frozen 41-call-site merge signature, removal of `EnsembleCombiner`). Cross-cutting risks #1 and #2 ("No hidden labelers," "Tony-domain overfit") are non-trivial; they each fund a named mitigation FR.

NFRs avoid boilerplate. NFR-2 is a named-constraint with a hard rule ("only Apple system frameworks"). NFR-6 cites concrete percentages (15% wall-clock budget) and refers to the measurement command (`make perf-benchmark`). NFR-7 quotes regression floors as absolute counts (55/82, 537/661) tied to specific corpora.

### Findings
None at adequate-or-better thresholds; this dimension is genuinely well-funded.

## Strategic coherence — strong

The PRD has a stated thesis: replace today's privileged-DSP-pipeline-with-bolted-on-ML-arbitration with a unified weighted voting system where DSP, ML, and metadata are peers. That thesis explains every epic: A builds the voting system, B retrains the previously-failing model that motivates B's existence (the forensic anchor `softmax_max_p95=0.294` is named in FR-25), C adds new public signal types (LUFS, beat-grid) that flow into the voter, D exposes the result through preset UX without leaking architecture churn, and E documents the resulting public mode enums.

Feature ordering follows the thesis: the Epic Dependency Graph shows A unlocks B/C/E, and FR-42's graceful-degradation clause for late Epic E delivery is a thesis-aware sequencing decision, not a backlog ordering.

Success metrics validate the thesis: FR-10 / NFR-7 (accuracy floors), FR-11 / NFR-6 (perf budgets), FR-18 (bundling gates anchored to the previously-failed model). Counter-metric named in cross-cutting risk #2 ("Tony-domain overfit") — Tony-corpus eval is gated against OA300 / GiantSteps as independent generalization corpora. That is the right counter-metric for this thesis.

The MVP scope kind is platform/capability, not problem-solving; the scope logic (5 epics, each tied to a peer signal or surface) matches.

### Findings
None.

## Done-ness clarity — adequate

Most FRs name a testable consequence. FR-10 (accuracy floors with specific counts + measurement commands), FR-11 (15% wall-clock + named make target), FR-18 (4 enumerated gates), FR-32 (named registry field categories a–d), and the NFRs (zero deps, macOS 15+, Swift 6 Sendable) are unambiguous.

Where this dimension weakens is the "specific threshold lives in the test/eval plan" pattern that recurs in Epic C and Epic B:

- **FR-25 confidence calibration:** names the metric family (ECE, softmax distribution shape) and the anchor (the prior model's 0.294 p95) but does NOT pin the new floor. "A documented floor" is the consequence — the actual number is deferred.
- **FR-29 long-file sync stability:** "Specific drift tolerance lives in the test plan / acceptance corpus." An engineer cannot run a test against this FR until that document exists.
- **FR-34 beat-grid acceptance corpus:** "Specific accuracy thresholds (F-measure floor, beat-position tolerance) live in the training/eval plan and are committed there before Epic C is considered complete." This is partially redeemed by the explicit "committed before Epic C is considered complete" hard gate — but the gate is at epic close, not at story creation, which leaves story-spec writers without a number.
- **FR-2 / FR-6:** "Signal influence scales with the signal's self-reported confidence and a per-source reliability factor" / "normalizes contribution per source family, not per individual signal row." These are directional, not testable — no consumer-visible bound on what "swamping" means.

Epic D's UX FRs land closer to adjective territory in places: FR-43 ("dominant interaction," "clean end-user experience"), FR-44 ("the label tells the user what kind of confidence it represents" — testable via inspection, but no inventory of confidence types to enumerate against), FR-40 ("without dominating the BPM-centric flow").

Epic E is mostly tight. FR-50 is a binary outcome (CI gate exists or not). FR-49 ("never empty, never crash") is testable. FR-47 is the soft spot — "concise prose covering what the option does AND why" — the test-plan referenced for style-guide adherence (KDD-E7) does not yet exist.

### Findings
- **high** Deferred thresholds without a pin-by-close-of-epic gate (FR-25, FR-29) — *Fix:* mirror FR-34's "committed before Epic C is considered complete" hard-gate language onto FR-25 and FR-29 so the test/eval plan is required before the epic can be closed, not after stories begin.
- **medium** FR-44 confidence-semantics audit needs an inventory (§ Epic D) — five confidence-like values are named in the FR (BPM confidence, beat-grid confidence, signal weight, source reliability, ML softmax max) but the FR does not say what label-text is acceptable for each. *Fix:* either enumerate the canonical labels in the FR, or punt to "labels defined in the Epic E doc-authoring style guide" — currently it is implied but not specified.
- **medium** FR-2 source-weight outcome is directional, not measurable (§ Epic A) — "scales with confidence and reliability" cannot be falsified. *Fix:* state the consumer-visible contract — e.g., "given two signals of equal source family, the higher-confidence one wins; given two signals of equal confidence in different families, the per-source-reliability ranking determines winner."
- **low** FR-43 / FR-40 / FR-44 adjective drift (§ Epic D) — "dominant," "clean," "without dominating" are tone, not bounds. Probably tolerable for a demo-app FR set, but worth flagging that an end-user-experience FR set deserves at least one wireframe or layout sketch reference. *Fix:* either acknowledge this is intentional (the demo is exploratory) or punt to a UX doc explicitly.

## Scope honesty — strong

Non-goals are surfaced where they would do work. FR-39 ("Waveform rendering is explicitly out of scope for v1"). FR-19 (export tooling out of scope). FR-22 (artist memorization detected but not prevented via feature engineering). The Aubio license note in Epic C is non-goal-by-license, explicitly named. FR-51-dropped and FR-48-moved are both annotated in-place with reasoning, not silently re-numbered.

Pre-1.0 BC framing is stated in three places (NFR-4, Cross-Cutting Risk #9, the decision log). No hidden migration plan; the operator BC clarification is documented as the reason byte-equality contracts were stripped.

Open-items density: ~25 named KDDs + 9 cross-cutting risks + the deferred-threshold pattern noted above. For a green-light-to-build PRD this would be high; for a launch-grade refactor with explicit "architect picks during implementation" framing in five places, it is honest. The KDDs all have a named resolution location (architecture doc, training plan, doc-authoring guide), so they are routed, not orphaned.

The decision log captures multiple party-mode rounds, Codex consults, and operator overrides — that audit trail is itself scope-honest about how the PRD reached its current shape.

### Findings
- **low** No top-level "Non-Goals" section consolidating the scattered non-goals (§ throughout) — FR-39, FR-19, the Aubio license constraints, the deferred FR-51, and the DocC parallel-surface decision (KDD-E10) are each non-goals but live distributed. *Fix:* optional — for a 5-epic PRD this scatter is tolerable, but a Non-Goals consolidation section would help downstream UX/architecture authors see the boundary without grepping the whole doc.

## Downstream usability — adequate

This PRD will feed UX → architecture → story creation, so downstream usability matters. The Epic Dependency Graph + KDD resolution-location pointers give architecture authors a clean entry point. Cross-references resolve: FR-11a points to KDD-E4, FR-7 points to FR-31, FR-22 points to FR-15. The Open Questions section uses stable IDs (KDD-A1 through KDD-E8) so the architecture doc can cite them.

Glossary is implicit, not formal — the domain nouns (`CandidateMergeStrategy`, `EnsemblePolicy`, `MLTechnique`, `MetadataCorroborator`, `AnalysisIntensity`, `BPMDiagnosticTrace`, `DocumentedCase`) appear consistently with their CLAUDE.md / project-context.md spelling and case, but no explicit Glossary section. For this audience (developers who will read CLAUDE.md alongside the PRD) that is probably fine; for an external reader it would not be.

FR IDs are documented with gaps: FR-48 moved to NFRs (annotated in §Epic E), FR-51 dropped (annotated). FR-11a uses suffix-numbering rather than re-numbering FR-12+ — that is a defensible pre-1.0 choice but creates a non-contiguous ID space.

The PRD does not define personas, user journeys, or success-metric IDs. This is correct for the shape (see Shape fit) but means downstream usability is strictly via FR/NFR/KDD cross-reference, not via a UJ/persona/SM lattice.

### Findings
- **low** No formal Glossary section (§ throughout) — domain nouns are used consistently but not defined in-PRD. *Fix:* optional — link to CLAUDE.md's Architecture section as the source-of-truth glossary in the PRD's frontmatter, or accept that downstream readers must hold both docs.
- **low** FR-11a suffix-numbering breaks contiguous ID space (§ Epic A) — FR-12 starts Epic B, so FR-11a is the only non-integer FR. *Fix:* tolerable as documented; could renumber to FR-12 with cascade, but the cost outweighs the benefit pre-1.0.

## Shape fit — strong

This is a developer-audience library PRD with a secondary end-user-via-demo audience. UJs and personas would be overhead — the operator explicitly chose "outcome-only FRs" per John's discipline, and the document carries that discipline through all five epics. The demo's end-user concerns surface as FRs (FR-36 named presets, FR-39 timeline-not-waveform, FR-43 two-tier discipline) rather than as a separate persona/journey lattice, which is the right fit for a library-with-reference-app PRD.

Brownfield references are accurate against CLAUDE.md / project-context.md spot-checks:
- The Story 4-6 Branch C model pull is correctly cited (FR-25 anchor; cross-cutting risk #3).
- `MetadataCorroborator.apply` post-merge boundary is correctly cited as the invariant being broken (NFR-4, decision log).
- `BNNSTechnique(modelURL:) throws` is the correct BYOW path (FR-19).
- Story 5-6b's `.inspector(isPresented:)` is correctly cited as the canonical advanced-sidebar (FR-43).
- The `featureSetVersion` drift seam (FR-21) is correctly tied to the `MLFeatureFrames` invariant.

Constraint traceability is non-trivial here (zero external dependencies, Swift 6 strict concurrency, macOS 15+) — each lands in NFRs with project-context-aligned phrasing.

The chain-top framing (feeds UX → architecture → stories) is appropriate given the 5-epic scope; the deferred-KDD pattern is the mechanism by which the chain proceeds.

### Findings
None.

## Mechanical notes

- **Glossary drift:** Domain nouns spelled consistently with CLAUDE.md (`CandidateMergeStrategy`, `EnsemblePolicy`, `BNNSTechnique`, `MLFeatureFrames`, `BPMDiagnosticTrace`, `featureSetVersion`). No `mlmodelc` vs `mlmodel` confusion in either direction.
- **ID continuity:** FR IDs run 1 → 52 with two documented gaps (FR-48 moved to NFR-5; FR-51 dropped). FR-11a is suffix-numbered. KDDs use the `KDD-{epic}{n}` scheme (KDD-A1 through KDD-E8) consistently between epic sections and the Open Questions consolidation. NFR-1 through NFR-10 are contiguous.
- **Cross-references:** All inline references resolve: FR-7 → FR-31, FR-11 → FR-11a → FR-4, FR-22 → FR-15, FR-18 → FR-25, FR-25 → FR-18, FR-42 → FR-46/FR-52, NFR-7 → FR-10, NFR-9 → FR-38. KDD-A6 is in Open Questions but not in Epic A's "KDDs deferred" list — see Decision-readiness finding.
- **Assumptions Index roundtrip:** No `[ASSUMPTION: …]` callouts in the PRD. For a PRD with this much explicit deferral via KDDs that may be intentional — assumptions that would otherwise be inline have been promoted to named KDDs. No orphaned index entries.
- **Persona linkage:** N/A — no personas, no UJs (correct for shape, see Shape fit).
- **Required sections:** Title + frontmatter ✓, Vision ✓, Features (5 epics, 51 outcome FRs minus the documented FR-48 move + FR-51 drop) ✓, Epic Dependency Graph ✓, NFRs (NFR-1 through NFR-10) ✓, Open Questions (~25 KDDs) ✓, Cross-Cutting Risks (9 named) ✓. No Glossary, no UJs, no Personas, no SM/Metrics section — all appropriate omissions for this shape.
