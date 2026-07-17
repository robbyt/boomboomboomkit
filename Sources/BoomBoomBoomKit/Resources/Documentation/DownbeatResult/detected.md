---
id: detected
title: Downbeats Detected
payload: DownbeatEstimate
---
**What it does.** Reports that downbeat detection ran and produced a _DownbeatEstimate_ — the downbeat beats, the assumed meter, an overall confidence, and the locked bar-phase index, all NaN-free by construction. It is the positive, successful state of the tri-state result, carried as the case payload. The estimate is guaranteed structurally usable when it comes from the analyzer, which validates every invariant before constructing a _detected_ value.

**When to pick it.** You handle it when a _BeatGrid_ carries a real downbeat estimate — the case where you can draw a bar grid, align a loop to the one, or anchor a Rekordbox-style origin, because the phase index tells you which beat starts each bar. It is the only state that lets downstream sync logic place bar lines rather than just beats.

**Tradeoff.** The estimate assumes a meter — the estimator always assumes common time (four-four) and does not measure the meter — so on genuinely odd-meter or shifting-meter material a _detected_ result can lock a confident bar phase against the wrong meter, placing bar lines that drift out of alignment as the track progresses. And a _detected_ value decoded from a stale or tampered cache whose estimate is structurally invalid is normalized down to _noneDetected_ rather than handed over broken — so a consumer relying on persisted results should expect an occasional silent downgrade rather than a corrupt success.
