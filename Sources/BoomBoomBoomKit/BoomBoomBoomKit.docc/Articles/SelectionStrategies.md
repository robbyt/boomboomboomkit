# Selection Strategies

Choose how BoomBoomBoomKit combines per-window BPM candidates into one answer,
how ties are broken when window-voting is in play, and how octave equivalence is
(not yet) treated.

## Overview

Progressive analysis runs the DSP pipeline over several time windows and each
window emits its own candidate list with confidence scores. Three configuration
knobs shape the final BPM:

- ``BPMSelectionPolicy`` — the cross-window merge strategy (8 cases).
- ``VotingPolicy`` — the resolution policy that elects the winning cluster,
  consulted *only* when the merge strategy is ``BPMSelectionPolicy/windowVoting``
  (3 cases). It can change the winner outright, not merely break ties.
- ``OctaveEquivalencePolicy`` — how half/double tempos relate (3 cases, currently
  reserved — see the honesty note below).

Per-case reference pages carry the full prose for every case; this article
surveys and compares them. It never restates a case's detailed treatment — read
the symbol page (for example ``BPMSelectionPolicy/maxConfidence``) for that.

## BPMSelectionPolicy

``BPMSelectionPolicy`` (a `String`, `CaseIterable` enum) defaults to
``BPMSelectionPolicy/maxConfidence``. Five of the eight cluster raw candidates
within a 2% tempo tolerance and then differ in how they *score* each cluster; two
(``BPMSelectionPolicy/maxConfidence`` and ``BPMSelectionPolicy/union``) do not
cluster at all; and ``BPMSelectionPolicy/windowVoting`` clusters each window's
*final, post-disambiguation* BPM rather than raw candidates. A cluster's score
draws on every candidate that landed in it — one window can contribute more than
one candidate — so the aggregates below are over candidate scores, not one score
per window.

| Strategy | Clusters (2%)? | Optimizes for | Failure mode |
|---|---|---|---|
| ``BPMSelectionPolicy/maxConfidence`` | No | Single most-confident window, unchanged | A confidently-wrong window (e.g. an octave-doubled DnB candidate) wins outright |
| ``BPMSelectionPolicy/dedup`` | Yes | Highest candidate score within each cluster | Collapses near-duplicates but still trusts one candidate's score |
| ``BPMSelectionPolicy/quorum`` | Yes | Cluster with the most distinct contributing windows | A genuinely correct minority tempo loses to a popular-but-wrong one |
| ``BPMSelectionPolicy/average`` | Yes | Cluster ranked by the mean of its candidate scores | A single weak candidate drags a good cluster's mean down |
| ``BPMSelectionPolicy/median`` | Yes | Cluster ranked by the median candidate score (outlier-resistant) | Ignores a lone but correct high-confidence outlier |
| ``BPMSelectionPolicy/weightedAverage`` | Yes | Cluster ranked by the confidence-weighted mean of its candidate scores | An overconfident bad candidate skews the weighting |
| ``BPMSelectionPolicy/union`` | No | Flat pool sorted by raw score | No consensus signal at all; raw score is the only arbiter |
| ``BPMSelectionPolicy/windowVoting`` | Post-disambiguation | Agreement across each window's *final* BPM | Falls back to `maxConfidence` when no two windows agree |

`maxConfidence` is the safe baseline — every other policy should earn its place
by beating it on your own corpus. The consensus-oriented strategies (`quorum`,
`windowVoting`) shine when several windows quietly agree on the true tempo and a
lone outlier would otherwise win.

## VotingPolicy

``BPMSelectionPolicy/windowVoting`` votes on each window's post-disambiguation
BPM (not its raw candidates), requires at least two windows to agree, and falls
back to ``BPMSelectionPolicy/maxConfidence`` when there is no consensus. How the
winning group is chosen is delegated to ``VotingPolicy`` (default
``VotingPolicy/simpleMajority``). `VotingPolicy` is consulted *only* when
`mergeStrategy == .windowVoting` — it is inert for every other selection policy.

| Voting policy | Winner rule | Uses `votingThreshold`? |
|---|---|---|
| ``VotingPolicy/simpleMajority`` | The cluster backed by the most windows (≥2) | No |
| ``VotingPolicy/confidenceWeighted`` | The cluster with the highest summed confidence | No |
| ``VotingPolicy/thresholdGated`` | Like `simpleMajority`, but the winner's top confidence must meet `Options.votingThreshold` | Yes |

At a `votingThreshold` of `0.0`, ``VotingPolicy/thresholdGated`` is identical to
``VotingPolicy/simpleMajority`` — the gate admits everything.

## OctaveEquivalencePolicy

``OctaveEquivalencePolicy`` (default ``OctaveEquivalencePolicy/octaveAwareWithPenalty``)
enumerates three intended treatments of half/double tempo relationships:

- ``OctaveEquivalencePolicy/collapseToFundamental``
- ``OctaveEquivalencePolicy/octaveAwareWithPenalty`` (the default)
- ``OctaveEquivalencePolicy/exactMatchOnly``

> Important: This policy is currently **reserved and inert.** The selection entry
> point accepts an `equivalence:` parameter but discards it (`_ = equivalence` in
> `BPMSelectionPolicy.select`). Cross-signal octave *corroboration* is governed by
> ``MetadataPolicy`` (and the DSP pipeline runs its own separate octave
> disambiguation) — but choosing a non-default ``OctaveEquivalencePolicy`` value
> does **not** yet change any result. The case set is a forward-declared surface,
> not a live control.

## Related guides

- <doc:EnsemblePresets> — combining the DSP result with an ML voice.
