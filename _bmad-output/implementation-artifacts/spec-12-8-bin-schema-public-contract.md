---
title: 'Story 12.8: declare the bin schema a public contract'
type: 'feature'
created: '2026-10-25'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
baseline_commit: 'eae87cc125585119a83c199c613c0c1154048acc'
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-12-context.md'
---

<frozen-after-approval reason="human-owned intent, do not modify unless human renegotiates">

## Intent

**Problem:** A BYOW model must match the runtime's 256-bin tempo output, but the three declarations are not identified together as a public contract. The consumer documentation also incorrectly suggests that widening the perceptual window makes decode-dead bins usable.

**Approach:** Make the README's existing `BNNSTechnique` model-contract section authoritative, name the three declaration sites and their joint-change rule, document the public mismatch error and breaking-change policy, and describe the fixed decode abstain and its 115 dead bins with a link to issue #147. Add brief pointers at the declaration sites without changing bin counts, decode behavior, training, or model weights. Create a feature branch from `develop` and a PR targeting `develop`.

</frozen-after-approval>

## Implementation Notes

- Branch `rterhaar/story-12-8-bin-schema` starts from `eae87cc125585119a83c199c613c0c1154048acc` (`develop`).
- The README's BYOW contract is authoritative; the two Python declarations and the BNNS runtime constants now point to it. The `MLTechniqueError` doc comment also names the consumer-visible failure.
- Corrected the existing README claim about perceptual-window reachability: BNNS decode abstains outside 60-200 BPM before ensemble folding. The 115 dead bins and issue #147 are documented without altering runtime or training behavior.
- `make lint` and `git diff --check` passed. The lint run reported one pre-existing, non-serious nesting warning in `PerformanceBenchmarkTests.swift`.

## Review Triage Log

- `medium`, patched: the runtime's `bpmBinOffset` was missing from the joint-change rule; changing the bin minimum while updating only the count would decode incorrect BPM values.
- `medium`, patched: count validation alone accepts a shifted or reordered 256-bin model; README now distinguishes this from schema compatibility.
- `low`, patched: the README's `try?` example hid the newly documented construction error; the example now propagates it with `try`.
- `low`, patched: the README table required shape `(1, 256)` although `validateContract` accepts any positive-rank output tensor totaling 256 elements; the table now states the actual validation rule.
