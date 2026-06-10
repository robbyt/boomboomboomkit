# Story 7.7 pressure-release valve (Epic 7 close-out)

The close-out decision is a **strict monotone DAG (DD #14)** — one direction, no
feedback edge:

1. **FR-24** (`fr24_net_benefit.py`) selects the promoted arm [model identity].
2. **KDD-B5** (Story 7.6 `evaluate_fr18.py`) gates the promoted arm → `bundle` / `byow`.
3. **FR-25 calibration** (`calibration_verification.py`) + **holdout-gap**
   (`holdout_gap.py`) may **only downgrade `bundle` → `byow`, NEVER upgrade**.
4. `epic7CloseDecision` (`epic7_freeze.py`) = the step-3 output.

The downgrade-only invariant is what removes the apparent circularity: FR-25
runs against the **v2 checkpoint's** predictions, which are **identical under
bundle vs byow** (both run the same `.mlOnly` BNNS path), so "final model" =
the v2 checkpoint fixed at step 1 — calibration consumes it, it does not choose it.

## FR-25 calibration failure / inconclusive

If FR-25 (AC3) reports `fail` or `inconclusive` (subset N<100 — `inconclusive`
is **not** a pass) even after Story 7.6 said `decision: "bundle"`:

- flip the close-out decision to `byow`;
- append an addendum to `_bmad-output/ml-training/fr-18-evaluation.md` citing the
  FR-25 override;
- bundling does **not** proceed; `epic7_freeze.py --decision byow`.

## Holdout-gap ≥ 8 pp

The gap is an **informational ~1.9σ tripwire at n=150 (DD #6)**, in
percentage-points, NOT a significance test and NOT comparable to 7.6's 537/661
counts. The threshold is **NEVER downgraded to force a pass.** If it fires:

- **default: accept the BYOW outcome and record the gap here** (close-out does
  not stall);
- restarting the FR-18 evaluator on a fresh checkpoint not tuned against the
  iterated corpus requires an **explicit operator sign-off with a named reason**
  (recorded here).

Because the holdout is a within-corpus stability check (the 150 tracks were
inside the same 661 corpus 7.6 tuned against), a large gap is *suggestive* of
iteration-leak, not proof; a small gap is necessary-but-not-sufficient evidence
against it.

## FR-24 net-benefit unproven (runner-up absent)

If the `supervisedAugmented` runner-up checkpoint was not trained, FR-24 is
`inconclusive` → net-benefit is **UNPROVEN**. The SSL variant is NOT
auto-bundled-as-net-benefit-proven (DD #5). Either train the runner-up to close
the gate, or record an **explicit operator acknowledgment** here that the SSL
variant ships on its own FR-18 gates without a proven net-benefit.

## Operator-owned remainder (gated on KDD-B4 signoff → 7.5 training → 7.6 eval)

1. `make ml-export-v2 EPIC7_V2_CHECKPOINT=<median-Acc1-seed v2 .pt>` →
   `make compile-model ML_MODEL_INPUT=_bmad-output/ml-models/giantsteps_v2.mlmodel`
   (load-AND-infer check, AC1).
2. Per-arm FR-24 producer runs (DD #15 — arm-namespaced dirs):
   - `ARM=maskedMelPretrain SEED=42 BNNS_MODEL_URL=<…seed_42> make fr18-produce` (×3 seeds)
   - `ARM=supervisedAugmented SEED=42 BNNS_MODEL_URL=<…seed_42> make fr18-produce` (×3 seeds)
   - `make fr24-net-benefit`
3. `make holdout-sample` (once) → `make holdout-gap`.
4. `make calibration-verify`.
5. `make epic7-freeze DECISION=<bundle|byow from the DAG>` + the decision-gated
   `main` squash-merge (re-bundle `Resources` + `Package.swift` + `MODEL_CARD.md`
   only if `bundle` survives the DAG; else `MODEL_CARD.md`-only BYOW doc).
6. `make post-bundle-watchlist`.
