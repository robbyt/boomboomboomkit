---
id: noneDetected
title: No Downbeats Detected
---
**What it does.** Reports that downbeat detection ran and found nothing: a negative result, distinct from never having run. It is the abstain the conservative downbeat estimator returns when the rhythmic evidence is too weak to lock a bar phase: too few bars, no clear winner over the runner-up, low confidence, or insufficient multi-bar support. The estimator deliberately prefers this "ran, nothing usable" over guessing, because a wrong downbeat on a live deck is worse than none.

**When to pick it.** Handle rather than choose it: it appears when detection was enabled but the track's rhythm did not meet the estimator's four-part acceptance gate. Treat it as a negative that can be trusted, because the library looked and declined to assert a downbeat, and fall back to a beat grid without a bar origin rather than inventing one.

**Tradeoff.** Because the gate is conservative, _noneDetected_ is returned on some tracks that do have a stable downbeat the estimator could not confidently recover, a false negative that costs a bar grid where one was possible. It is the deliberate trade: the estimator accepts missing downbeats to avoid asserting wrong ones. One provenance caveat for persisted results: a _noneDetected_ decoded from a stale or tampered cache may be a structurally-invalid _detected_ that was normalized down, so on cached data it means nothing usable was found, not strictly that a fresh analysis ran. A consumer that reads _noneDetected_ as "this track has no meter" is also misled, since it only means detection abstained, not that the music lacks a bar structure.
