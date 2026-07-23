---
id: mlOnly
title: ML-Wins Resolution
---
**What it does.** When the ML technique returns a usable evaluation, this policy adopts the model's BPM (octave-folded into 60 through 200, so an estimate of 240 becomes 120; a non-finite value abstains back to DSP) and the model's confidence (clamped to 0 through 1; a non-finite confidence abstains back to DSP), while preserving the DSP candidate list. When the model abstains, by returning nil or by emitting a non-finite sentinel, the DSP winner carries through unchanged and the trace records the abstain kind. The model's verdict is authoritative when present: ML overrides DSP on the final BPM whenever it produces a usable answer.

**When to pick it.** Choose it when you have a model you trust more than the DSP pipeline for the reported tempo, for instance a well-validated genre-specific classifier, and you want its verdict to be authoritative while still keeping DSP as the abstain fallback. It is a direct way to A/B a model's standalone accuracy inside the pipeline, since the ML value wins outright whenever available rather than being blended or out-voted.

**Tradeoff.** The final BPM may not appear in the returned candidate list, which only ever contains DSP candidates. That is an invariant most other policies preserve, and downstream consumers relying on _the winner is always among the candidates_ will break on it. Letting ML win unconditionally also means a confidently wrong model overrides a correct DSP reading with no arbitration: unlike _highestConfidence_ or the weighted policies, there is no comparison of the two voices, so any systematic model bias passes straight through to the result whenever the model declines to abstain.
