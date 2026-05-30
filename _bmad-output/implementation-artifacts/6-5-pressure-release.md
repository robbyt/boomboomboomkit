# Story 6.5 — Pressure-Release Split Record

**Date:** 2026-05-30
**Decision:** Split Story 6.5 into **6.5a** (byte-inert type taxonomy) + **6.5b** (semantic Stage-3 flip).
**Authorized by:** operator sign-off after the validation → party-mode → Codex review cascade.

## Why the split (the epic valve fired)

The epic (epics.md:582) pre-authorized a 6.5a/6.5b split "if the rename + types exceed a single dev-agent context window," and mandated this record. The trigger fired — but on a **different fault line** than the epic anticipated, because Story 6.5's true scope was a UNION the epic's ACs didn't reflect:

- The epic assumed Story 6.4 already performed the byte→semantic flip (epics.md:572-574). **False** — 6.4b's operator-signed B-cascade deferred the entire semantic Stage-3 flip into 6.5. So 6.5 = Half A (byte-inert types) ∪ Half B (semantic flip).
- The epic's pre-cascade valve split *within Half A* (rename+SignalWeights vs the other 3 types). That boundary strands the merge-flip and assumes no semantic work — wrong axis.

The 9-reviewer cascade (3 validation lenses + Winston/Amelia/Mary/John/Siri + Codex; 5 needs-rework / 4 ship-with-fixes) converged on the **byte-inert ÷ semantic** fault line:

- **Delivery risk (party-mode John + Winston + Mary):** the monolith has no rollback story — a Half-B accuracy regression discovered post-merge forces reverting the *whole* monolith including the safe Half A; it muddies the zero-delta bisect boundary the 6.1–6.4b prep sequence was built to preserve.
- **Atomicity (architecture.md:343 / KDD-A6):** the byte→semantic test swap MUST be atomic with the merge-flip (no red interval). It therefore lives entirely inside Half B and can never straddle a 6.5a/6.5b boundary.
- **Context-window (party-mode Amelia):** the full union (78-ref rename + 4 types + EnsemblePolicy break + 41-site/two-phase semantic flip + apply-removal + 15-test migration + the atomic swap + MergeSemanticEqualityTests authoring + 6 riders) does not fit one dev-agent window with the care Half B's winner-promotion math demands.

## The split boundary

- **6.5a — `6-5a-byte-inert-type-taxonomy` (ready-for-dev).** Rename `CandidateMergeStrategy → BPMSelectionPolicy` (78 refs / 12 files); add `SignalWeights` / `OctaveEquivalencePolicy` / `MLExecutionPolicy` / `ComputeBudget`; `EnsemblePolicy` 5-case facade. All byte-inert (default-path output byte-identical to `011f927`); the 4 `.stage1Floor/.stage2Floor` byte-floor tests stay GREEN (the inertness oracle). New policy types ship as configurable-but-inert config. Spec: `6-5a-byte-inert-type-taxonomy.md`.
- **6.5b — `6-5b-semantic-stage3-flip` (backlog, gated on 6.5a landing).** Pool-authoritative **two-phase** `BPMSelectionPolicy.select` (Phase 1 = retained 8-strategy cross-window aggregation; Phase 2 = cross-signal fusion); `apply` removal with the **multiplicative** boost/penalty/reselection relocated verbatim into Phase 2, scaled by `SignalWeights.fileMetadata`; the atomic byte→semantic swap; the `WeightedSignal.score` read-seam + `SignalParticipation.score` accessor; FR-1/FR-6/FR-7; riders W48/W51/W56/W61/6-3-D1/6-3-D2; the merge-frozen-rule supersession. To be authored via `/bmad-create-story 6-5b`.

## Ratified design corrections (from the cascade)

Two cascade findings are load-bearing for 6.5b and are recorded here so they survive into its spec:

1. **The `select(from:pool:weights:equivalence:)` 3-arg signature is non-implementable** — it drops the `strategy` / `candidateCount` / `votingPolicy` / `votingThreshold` state the 8 cross-window strategies require. Codex ratified a TWO-PHASE selector with a widened signature (instance method on `BPMSelectionPolicy`, or static with `strategy:` + the carried params).
2. **Multiplicative ≠ additive (the root semantic hazard).** Re-expressing `apply`'s ×1.25 multiplicative boost-and-reselect as additive `effectiveVote = confidence × weight` is not algebraically equivalent; the winner-promotion (128@0.5×1.25 = 0.625 > 140@0.5) is not guaranteed to survive. Fix: keep the multiplicative transform verbatim inside Phase 2; `SignalWeights.fileMetadata` SCALES the boost strength (`boost = 1.0 + fileMetadata × (corroborationBoost − 1.0)`), it does not replace the transform. `fileMetadata = 0` ⇒ metadata inert (the disabled-path identity); `= 1.0` ⇒ the promotion is exactly preserved.

Half-A corrections (counts 78/12/41, NaN-Hashable conformances, the `CaseIterable` ripple, inert-config framing, the root-ceiling-incoherence flag) are applied in the 6.5a spec.
