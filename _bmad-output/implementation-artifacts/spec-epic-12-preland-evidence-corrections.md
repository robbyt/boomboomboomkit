---
title: 'Epic 12: correct pre-landing evidence and signoff status'
type: 'chore'
created: '2026-10-25'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Epic 12's recorded 12.4 baseline claims per-track equality with a published result when only the aggregate count can be compared. The 12.6 protocol and current 12.7 summaries still describe operator signoff as pending even though both decisions were signed.

**Approach:** Correct those statements at their current reading points, preserving the recorded numbers, signed decisions, historical sections, and the corpus/training gates. Keep the change on a child PR targeting `rterhaar/epic-12`.

</frozen-after-approval>

## Implementation Notes

- Corrected the 12.4 baseline report to claim only aggregate equality with the published figure; the published run has no per-track predictions to compare.
- Updated the current-reading introductions in the signed 12.6 protocol, the 12.7 corpus account, and the Epic 12 context. Kept the protocol signoff distinct from the still-pending corpus/training signoff.
- Audited the remaining Epic 12 deferred items against the current branch: private corpus state is ignored and untracked, 172 members are unsigned, and `train.py` remains blocked. The corpus-harness debt activates on later remint, annotation, re-pass, or signoff work. The opt-in ML range interaction needs a separate behavior decision. Stories 12.8 and 12.9 remain backlog, and PR #189's running changelog needs a refresh at epic close-out.
- Review exposed a rounding error in the same 12.4 claim: `545 / 661 * 100 = 82.4508...`, which rounds to 82.5% at one decimal. Corrected the verdict, results table, and comparison paragraph without changing either track count or the gate.
- Rephrased the 12.4 comparison as an aggregate sanity check and the section-5 tag record in 12.6 as the signed outcome. No runtime code, corpus member, benchmark report JSON, or training gate changed.

## Review Triage Log

- `medium` — The 12.4 report stated 82.4% for 545/661 in two places; arithmetic gives 82.5% at one decimal. Patched the report and its false rounding explanation.
- `medium` — The 12.4 report called matching aggregate counts a strong alignment cross-check despite lacking published per-track predictions. Patched to an aggregate sanity check and referred to the separate row/annotation alignment record.
- `medium` — Section 5 of the signed 12.6 protocol still called the minted tag a draft to be re-dated. Patched the current status while retaining the historical validation run.
