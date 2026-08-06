# Epic 12 Context: Measurement integrity and the DSP tempo prior

<!-- Generated from planning artifacts. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Give consumers a way to constrain the tempo search range at the input — so a drum-and-bass integrator stops getting 140 for a 70 BPM track without training or supplying a model — and, alongside that, build the three measurement assets the project has never had: a published TempoCNN-family baseline reproduced and scored on our own evaluation path, a band-balanced 258-track corpus whose labels were never corroborated by the detector under test, and a bundle gate stated in tracks rather than percentages. The framing matters: the ML programme has a stopping rule that can terminate it, but nothing in this epic dies with it. A diagnosis, a corpus, a working tempo prior, and a gate definition all survive. This is the epic that turns "we know whether a bundleable model is reachable and which lever to fund" into an outcome rather than a consolation prize.

## Stories

- Story 12.1: Consumer-specifiable tempo search range
- Story 12.2: Style-classifier decision — scope it, defer it, or reject it
- Story 12.3: Annotation-version tagging and the octave-error metric
- Story 12.4: Reproduce the TempoCNN reference baseline (Gate 0)
- Story 12.5: Pipeline differential and cause ranking
- Story 12.6: Metrical-level convention and the ground-truth rule
- Story 12.7: Build the 258-track band-balanced corpus
- Story 12.8: Declare the bin schema a public contract
- Story 12.9: Define the bundle gate

## Requirements & Constraints

**Byte-identity of the default DSP path is a hard contract, not a best-effort.** Every lever in this epic is additive and opt-in; the default-options pipeline must produce bit-identical `bpm`, `confidence`, and `candidates`. A paired opt-out byte-equality test ships with any story that touches the pipeline. This is stronger than the project's usual "where feasible" phrasing.

**Every accuracy-affecting change ships a per-track impact report** with per-band and per-genre breakdown, following the existing impact-report make-target precedent. Any substrate change bumps the single feature-set-version constant (never hardcoded at a call site), and the Swift↔Python FNV checksum parity tripwire holds.

**The four unconditional corpus floors hold throughout:** OA300 Acc1 ≥ 57/82 and Acc2 ≥ 73/82; GiantSteps Acc1 ≥ 537/661 and Acc2 ≥ 546/661.

**Invalid configuration is normalized, never thrown.** Out-of-range, inverted, or non-finite tempo bounds are silently clamped and documented on the property, following the existing clamping-parameter precedent.

**Ground truth may never be corroborated by our own detector.** Label selection, corroboration, and corpus membership must be decidable without reading any DSP output; the audit that enforces this fails closed. Using aggregate DSP statistics to *size* an annotation budget is permitted; using them to exclude or effectively exclude tracks is not.

**Accuracy figures carry their ground-truth annotation version.** Untagged historical figures are marked untagged, never assumed to match current labels. `Acc2 − Acc1` is reported as a first-class metric alongside Acc1, not as a derived footnote — it is the standard octave-error proxy and this epic is about octave errors.

**Corpus constants are fixed and single-sourced:** 6 bands, 43 tracks per band, 258 evaluation tracks, α = 0.05, minimum gate lift 12 net tracks at 10% discordance, DSP-handled-band threshold 30 of 43. The training corpus is a separate artifact sized for volume with band-aware sampling and explicitly *not* balanced to 43. Both share one metrical-level convention and one partition.

**Margins are stated in tracks, never percentages.** Per-band results are a deterministic tripwire — `gains ≥ losses`, exact `b:c` split reported — and never a significance or noninferiority claim. Seed agreement is a robustness guardrail only.

**Non-negotiables carried in from project policy:** OA300 is private and never published or referenced outward; weights never enter the repository; zero third-party dependencies; Swift 6 strict concurrency with all new public types `Sendable`; bulk numeric work through vDSP. Every literature claim traces to primary text, not to a summary — a summarizer fabricated a sigma value, a decode method, and accuracy figures during discovery.

## Technical Decisions

**There is no architecture record for this epic.** The architecture document predates it, covers only earlier epics, and returns nothing on Epic 12 subject matter. Do not infer architecture decisions that were never made. Two items carry public-API surface with no ADR behind them: moving the tempo bounds onto the options struct, and declaring the bin schema a public contract. Only the general constraints still bind — brownfield framing, no new SPM product targets (work lands in the existing five targets or not at all), and the existing cross-cutting enforcement mechanisms.

**Configuration goes on the options struct, never as a call parameter.** New tunables are non-optional defaulted fields on the analysis options type, per the project's options-first configuration rule.

**The tempo bounds are two pairs with different semantics and different blast radii**, and are exposed and documented separately: a candidate *scan* range that sizes the search grid, and a *perceptual* octave-normalization window consumed by range normalization. The perceptual pair carries an at-least-one-octave invariant, because the normalization routine's two sequential loops will otherwise return a value below the stated minimum.

**A consumer-specifiable range is a hard filter by construction**, while the style-conditioned prior it was originally bundled with mandates reweighting and never hard-filtering. ~~Story 12.2 must state explicitly whether the two coexist or one supersedes the other.~~ **RESOLVED 2026-08-05 by Story 12.2** (`_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md`): they do **not** coexist. The caller-declared range **supersedes** the style-conditioned prior's delivery mechanism, because the style classifier is **rejected**: with no classifier there is no inferred style left to condition on. The hard-filter objection survives and is answered by opt-in defaults rather than dismissed: both bounds pairs default to the pre-story values, so the library's default path never acquires the failure mode. The style classifier itself was an unscoped second model this epic does not build, and Story 12.2 closed that as a written reject rather than leaving it open.

**Python placement follows the existing release split.** Baseline-reproduction and corpus tooling are develop-only and live under the ML-training tree. The consumer convert-CLI directory is the only Python that ships publicly and its scope does not extend to research harnesses.

**The 256-bin schema is declared in three places** — the shipping convert-tool reference architecture, the develop-only dataset module, and the runtime's hard-coded expected bin count — and they move together. Bins that can never decode to a usable tempo against the runtime's abstain range are recorded as a known dead range. Story 12.8 *declares only*: no bin count changes, no decode behaviour changes. Any future schema change requires a named story; pre-1.0, breaking changes are permitted and preferred over compatibility shims.

**Decision and analysis stories leave code untouched.** Stories 12.2, 12.4, and 12.5 require byte-identical `Sources/` and `Tests/`; 12.3 requires byte-identical `Sources/` with changes confined to benchmark and test-support surfaces; 12.8 permits doc-comment-only edits.

**One old requirement is struck and must not be treated as live scope:** the proposal to re-label affected OA300 tracks in place. OA300 stays intact as a tagged historical artifact so its historical figures remain interpretable; the single convention is declared for the *new* corpus only.

**The superseded Epic 12 charter is retained in the epics file as historical record.** Where it disagrees with the story breakdown, the story breakdown governs; where its lever ranking disagrees with Story 12.5's ranking, 12.5 governs once it exists. Charter item 7(a) — wiring the idle octave-equivalence policy and DSP octave resolution as a signal-pool arbiter — is explicitly post-MVP and is covered by no story here.

## Cross-Story Dependencies

Every dependency points backward; no story requires a later one.

- **12.1 inherits a precondition from the transferred DSP octave levers:** no DSP-path change is pre-committed before the octave-ambiguity threshold sweep runs. The sweep runs as 12.1's first task, or the rule is retired in writing with a stated reason — silently dropping it is not permitted.
- **12.3 must land before 12.6.** Declaring a single metrical-level convention makes every old-label figure incomparable; annotation-version tagging is what makes that transition survivable rather than silently confusing. The new convention gets its own version tag.
- **12.6 gates 12.7.** The convention and the tag-to-ground-truth rule are written before any labelling starts, so the rule cannot change mid-verification and invalidate completed work. 12.6 cannot close on agent work alone — it carries the operator's explicit signoff.
- **12.7 gates 12.9.** The bundle gate is defined on the 258-track corpus and cannot be stated without it. 12.7 also wires the fail-closed training signoff for the new corpus, or records explicitly that no training story may run until it is wired.
- **12.4 gates 12.5**, and carries the epic's pressure-release valve: if the reference baseline also scores near our own low figure on our evaluation path, Gate 0 fires, the finding is that the problem is measurement rather than modelling, and stories 12.5 onward are re-planned rather than executed.
- **12.5 produces the cause ranking that supersedes the charter's** as the driver of downstream work. A ranked cause outside this epic's scope becomes documented input to the follow-on delivery epic and is not acted on here.
- **The follow-on model-retrain-and-delivery epic depends on this epic in full** and is scoped only if the gates pass.
- **12.9's harness must be exercised against a negative control** — the earlier retrain that failed its promotion gates — and demonstrably reject it. A gate that has never rejected anything is not known to work.
