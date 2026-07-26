# perf-baseline commit IDs and the 2026-07-25 history rewrite

Every `gitSHA` / `git_sha` value in this directory was written BEFORE the
2026-07-25 history rewrite, so none of them resolve in a current clone.
`git show <sha>` on any of them fails.

The record files themselves are not edited: a published measurement stays
exactly as it was measured. This file restores the link instead.

Old SHA -> new SHA, for the ones that can be recovered:

OLD        NEW        SUBJECT
1c8e274    7a6652a    Story 4-5 review pass v3: vDSP adoption, doc fixes, scope close-out
372032a    a535111    Story 4-6 review pass: split enableMLDiagnostics gate, parameterize di
61d6161    16d1dc1    Story 4-6 review pass: regenerate bnns-impact baselines at post-fix SH
8c37d64    9112315    housekeeping
8d932da    fcaddf4    Story 4-6: ML diagnostic instrumentation + canonical bnns-impact basel
9185698    8c4e28f    Story 4.2: report effective intensity and graceful ML degradation
9c48629    80d1a60    tony corpus: survey + DSP prepass + label derivation pipeline
9fd7c44    944f57c    Story 4-3 Task 1: pre-source-change baseline artifacts
aa786e3    161748e    Story 4-3b: subBandEnergies typed migration, tighten perf gate to 1.20
ae04011    a973fd6    land epic 7 (#28)
be26fa5    e7cf9a5    PR #2 follow-ups: 16 Copilot findings + perf-gate rebaseline
c1ba272    c629f60    Story 4-3: wire MLTechnique slot, migrate tuples to MLEvaluation struc

Not recoverable:

  03acccd
  0a5d13a
  1380089
  16e03e0
  2ba3cc3
  3a86a07
  4650bf0
  5d65780
  6e39893
  75da815
  840177e
  8cf77bd
  96eafc3
  a97bad2
  ba6ba52
  be38d80
  bf3acad
  e1e880b
  e58e60a
  f0c5b9e
  f794dc2

Those were commits that only ever existed on feature branches or pull-request
refs. The rewrite never saw them, so there is no mapping to recover. The same
cause is recorded in deferred-work.md under GH-167 row 8 for 11 SHA citations
in the Markdown artifacts.

Generated 2026-07-26 from 8-purge-commit-map-2026-07-25.txt.
