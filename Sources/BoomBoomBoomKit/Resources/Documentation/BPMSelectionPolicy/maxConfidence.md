---
id: maxConfidence
title: Highest-Confidence Window
---
**What it does.** Selects the single analysis window that reported the highest confidence and returns its BPM unchanged. When progressive analysis runs the pipeline over several time windows (30s, 60s, 90s), each window produces its own candidate list and a confidence score; _maxConfidence_ ignores the others entirely and forwards the winner. This is the library's current default merge strategy — it does no clustering, averaging, or voting, so the result is always a value that some individual window actually produced.

**When to pick it.** Reach for it when you trust that one clean window is more reliable than a blend of several noisy ones, or when you want the cheapest, most predictable merge with no cross-window interaction. It is the safe baseline for well-recorded material where at least one window locks onto a stable tempo, and it is the strategy to keep until you have benchmarked alternatives against your own corpus — every other policy should earn its place by beating this one on the OA300 or GiantSteps accuracy numbers.

**Tradeoff.** Because it trusts a single self-reported confidence score, it fails on tracks where the wrong tempo looks confident. On drum-and-bass material an octave-doubled candidate frequently self-reports higher confidence than the true fundamental, so the loudest, most periodic-looking window wins and the final BPM lands at half or double the real tempo. It also discards genuinely corroborating evidence: three windows that quietly agree on the correct tempo lose to one over-confident outlier, because agreement across windows never enters the decision. Where cross-window consensus matters, _quorum_ or _windowVoting_ will out-perform it.
