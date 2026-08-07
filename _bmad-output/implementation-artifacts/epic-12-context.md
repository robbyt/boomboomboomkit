# Epic 12 Context: Measurement integrity and the DSP tempo prior

<!-- Generated from planning artifacts. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Epic 12 gives consumers a way to constrain tempo detection at the input, so a caller analyzing drum-and-bass stops getting 140 for a 70 BPM track without anyone training a model, and it gives the project the three measurement instruments it has never had: a published reference baseline reproduced and scored on our own evaluation path, a band-balanced 258-track evaluation corpus whose labels were never corroborated by the detector under test, and a bundle gate defined in tracks rather than percentages. Three retrains and two cheap octave fixes have already failed, so the epic is deliberately built so that every deliverable survives the stopping rule firing: a diagnosis, a corpus, a working prior and a gate definition all stand even if the model programme is terminated. The success condition is knowing whether a bundleable model is reachable and which lever to fund, as an outcome rather than a consolation.

## Stories

- Story 12.1: Consumer-specifiable tempo search range
- Story 12.2: Style-classifier decision (scope, defer, or reject)
- Story 12.3: Annotation-version tagging and the octave-error metric
- Story 12.4: Reproduce the TempoCNN reference baseline (Gate 0)
- Story 12.5: Pipeline differential and cause ranking
- Story 12.6: Metrical-level convention and the ground-truth rule
- Story 12.7: Build the 258-track band-balanced corpus
- Story 12.8: Declare the bin schema a public contract
- Story 12.9: Define the bundle gate

## Requirements & Constraints

**The tempo prior.** The four previously-private tempo bounds are consumer-specifiable through the analysis options as two separate pairs with different semantics and blast radius: the candidate scan range, and the octave-normalization window. Both ship opt-in, defaulting to the pre-story bounds, so the default path never acquires the failure mode as a feature. Invalid input is normalized silently rather than thrown.

**No style classifier, and no style-conditioned prior of any kind.** Story 12.2 decided reject on a product-policy premise: automatic style inference is outside this library's mission, and callers own their own domain constraints. The caller-declared bounds shipped in Story 12.1 are the named alternative octave mechanism; they supersede the rejected prior's delivery mechanism rather than coexisting with it. The published drum-and-bass prior from the literature has since been run here as a hard scan-range bound at 130-180 over three corpora and is negative (drum-and-bass accuracy falls on every conformant slice, and non-drum-and-bass cost is large). That bounds the hard-filter reading only: whether the published work applied its prior as a search constraint or as a candidate reweighting is unverified in this repository, so the soft-reweighting form remains untested and the published result is not refuted. Do not write the transfer assumption up as settled in either direction. The per-genre counter-metric survives, retargeted to guard the opted-in bounds path, since a consumer-set narrow range can help one genre by hurting the rest.

**Measurement integrity.** Every accuracy figure carries the annotation version of the ground truth it was scored against; historical figures with unknown provenance are marked untagged, never assumed current. `Acc2 - Acc1` is reported as a first-class octave-error metric alongside Acc1, never as a derived footnote.

**The reference baseline is a gate, not a benchmark.** Annotation versions must be aligned before scoring, or the gate measures the ruler and reports it as the model, which is the exact question it exists to answer. If the reference also scores near our own model's figure on our evaluation path, the gate fires: the problem is measurement, the remaining stories are re-planned rather than executed, and the finding is the deliverable. Every literature figure cited must trace to primary text; a summarizer previously fabricated figures and a decode method.

**Corpus.** 258 tracks, 43 in each of six bands, drawn across the private evaluation corpus, the Rekordbox collection and the non-Rekordbox pool. Two conditions are non-optional: no label may be selected or corroborated using our own detector (the audit for this fails closed), and no track, remix or artist may appear in both the evaluation corpus and any training set. One metrical-level convention is declared for the corpus and every track labelled to it, with the old octave-ambiguity pairs retained as a tagged sentinel subset. Ground truth comes from operator hand-verification, which is a budget risk at this scale and requires explicit operator signoff. Legacy corpora are audited for which convention they were trained toward and are never re-labelled in place. The training corpus is a separate artifact sized for volume with band-aware sampling, explicitly not balanced, sharing the convention and the partition.

**The bundle gate.** Ensemble lift over DSP alone, on the balanced corpus alone, with the legacy corpora reported as context but not gating. The margin is stated in tracks, never percentages. Per-band lift is always reported and is a deterministic tripwire, never a significance or noninferiority claim. Triplet sentinels and a confidence-calibration floor both gate, and the calibration metric that was never run previously is committed and run here. A gate that has never rejected anything is not known to work, so the harness is exercised against a known-failing model and must reject it.

**Binding NFRs.** DSP-only output stays byte-identical, test-locked, and this is hard rather than best-effort. Any accuracy-affecting change ships a per-track impact report with per-band and per-genre breakdown. Any substrate change bumps the feature-set version and re-runs the Swift-to-Python parity tripwire. Swift 6 strict concurrency with all new public types `Sendable`; zero third-party dependencies; bulk numeric work through vDSP. The four unconditional corpus accuracy floors hold. The private corpus is never published or referenced outward.

## Technical Decisions

- New tuning surface goes on the analysis `Options` struct as non-optional defaulted fields, never as analysis-function parameters. Out-of-range or non-finite values are silently clamped and normalized following the existing threshold-field precedent, with the normalization documented on the property.
- The two bounds pairs are exposed and documented separately. The perceptual pair carries an at-least-one-octave-wide invariant, because its normalization runs two sequential loops with no re-check and a narrower window returns values below the stated minimum.
- Of the four pinned known-failure fixtures, three are octave doublings that a range can resolve and the fourth is a 3:2 triplet relation that is not expected to resolve. The fixture file's existing triplet label is correct and must be left alone.
- Most stories in this epic are decision, measurement or declaration deliverables whose acceptance includes `Sources/` and `Tests/` being byte-identical. The bin-schema story permits doc-comment edits only.
- The reference-baseline harness is develop-only Python under the ML-training tree. The consumer convert CLI is the only Python that ships to the public branch and its scope is that CLI.
- The bin schema is declared in three places, one of which ships publicly, and a mismatch surfaces as a consumer-visible error. Story 12.8 declares only: it names all three sites, records that they move together, records the decode-dead bin range, and changes no bin count and no decode behaviour. Range alignment itself needs a retrain and belongs to the follow-on epic.
- Architecture coverage for this epic is absent; the existing architecture document predates it. The SPM target layout is pinned and this epic adds no new targets.
- Epic 12 owns the DSP octave levers taken from the later DSP-experiments charter. The signal-pool octave arbiter is explicitly post-MVP and no story covers it. Pre-1.0 rules apply: breaking changes are permitted and preferred over compatibility shims.
- The cause ranking produced in Story 12.5 supersedes the charter's lever ranking as the driver of all later work; the charter ranking is annotated rather than deleted. A ranked cause outside this epic's scope becomes documented input to the follow-on epic and is not acted on here.

## Cross-Story Dependencies

Every dependency points backward; no story requires a later one. Story 12.5 consumes Story 12.4's scored baseline and cannot start before it. Story 12.3's annotation-version tagging must be in place before Story 12.6 declares a convention that makes every old-label figure incomparable. Story 12.7 consumes Story 12.6's convention and ground-truth rule, and Story 12.9's gate cannot be defined without Story 12.7's corpus. Stories 12.1, 12.2 and 12.8 are independent of the rest.

Story 12.4 carries an epic-level stopping condition that can halt everything after it. Stories 12.4, 12.7 and 12.9 each exceed a single development session and should be split when their specs are written; 12.7 additionally carries operator hand-verification that no agent can complete, and 12.6 cannot close without explicit operator signoff on the ground-truth rule.

The follow-on model-retrain-and-delivery epic depends on Epic 12 in full: its lever choice comes from the cause ranking, its gate cannot run without this corpus, and its delivery work cannot start until a model worth shipping exists. Nothing in Epic 12 depends on it.
