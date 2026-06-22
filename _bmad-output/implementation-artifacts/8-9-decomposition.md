# Story 8-9 — beat-grid decomposition + oracle line-fit audit

Tracks joined (oracle ∩ accuracy): **1264** (constant-flagged **910**).

## Oracle line-fit audit (AC #7)

Each oracle's beats fit to a single constant-tempo line; the residual P95 is the irreducible drift floor a constant-tempo grid faces against that oracle.

- Oracle-validated constant-tempo (P95 ≤ 70 ms): **910 / 910** (100.0%).

- Warped / piecewise / coarse (P95 > 70 ms): **0** — these inflate measured drift and are mis-specified for the constant-tempo drift gate.

- Oracle residual P95 over constant-flagged (ms): median 0.0, P90 0.0, P95 0.0, max 0.0.


  Oracle residual-P95 histogram (ms):

  - [0, 10): 910
  - [10, 25): 0
  - [25, 50): 0
  - [50, 70): 0
  - [70, 100): 0
  - [100, 250): 0
  - [250, 1000): 0
  - [1000, 1e+09): 0

## F-measure decomposition (AC #8)

- Mean octave F: all **0.372**, oracle-validated-constant **0.372** (the subset the drift gate actually applies to).

- Octave normalization lift (F_octave − F_raw): mean **0.110**, median **0.090** — the half/double-time density mismatch the octave-tolerant score recovers (NOT a phase/drift problem the refit reaches).


  Octave-F histogram (all tracks):

  - [0, 0.1): 60
  - [0.1, 0.2): 30
  - [0.2, 0.3): 227
  - [0.3, 0.4): 480
  - [0.4, 0.5): 287
  - [0.5, 0.7): 141
  - [0.7, 0.9): 26
  - [0.9, 1.0001): 13

- corr(octave-F, oracle-residual-P95) = **-0.006** (negative ⇒ low F is driven by a warped oracle, not a fixable grid error).

- corr(oracle-residual-P95, duration) = **+0.137** (positive ⇒ longer tracks drift more in the oracle itself).

## Worst 50 tracks by octave-F (shared-trait isolation, AC #8) — aggregate over 50, lowest-F 25 listed

- of the 50 worst: **0** have a warped oracle (P95 > 70 ms), **15** are flagged variable-tempo — i.e. 15 of 50 worst are oracle/material issues, not grid drift.


  | basename | octave-F | const | n_ref | oracle-P95 ms |
  |---|---|---|---|---|
  | Chrissy - PHYSICAL RELEASE - 06 Bust-Fre | 0.000 | Y | 621 | 0 |
  | Special Request - Physically Sick 3 - 21 | 0.000 | Y | 908 | 0 |
  | Sun People - Into The New EP - 02 Overto | 0.000 | Y | 394 | 0 |
  | GutterFunk - Addison Groove- TeknoJuke - | 0.000 | N | 523 | 0 |
  | Hyroglifics - BS6 - 03 Turbo Island.mp3 | 0.000 | N | 330 | 1 |
  | Hyroglifics & Sinistarr - BS6 - 01 BS6.m | 0.000 | Y | 300 | 0 |
  | Itoa - EXIT078 - Itoa - 'Ever Orbit' EP  | 0.000 | Y | 360 | 0 |
  | Om Unit - Prawn Cocktail (Salva Remix).m | 0.000 | Y | 711 | 0 |
  | Chimpo - Chimpo Presents Contrast - 02 T | 0.000 | Y | 449 | 0 |
  | Basic Rhythm - XT - Woozy - 02 Woozy.mp3 | 0.000 | Y | 342 | 0 |
  | Thys - More Than Three Dumb Edits - 02 H | 0.000 | Y | 420 | 0 |
  | Ternion Sound - Digital Artifice - 07 Po | 0.000 | Y | 520 | 0 |
  | Ternion Sound - Digital Artifice - 13 In | 0.000 | Y | 516 | 0 |
  | Ternion Sound - Digital Artifice - 18 Ch | 0.000 | Y | 642 | 0 |
  | Deft - -SKIN- E.P - 03 HUMBLE.mp3 | 0.000 | Y | 385 | 0 |
  | CESCO - Up The Place EP - 04 Swing King  | 0.000 | Y | 628 | 0 |
  | Hyroglifics - I'll Wait, I Guess - 04 Si | 0.000 | Y | 290 | 0 |
  | Commodo - Deft 1s - 02 Forester.mp3 | 0.000 | N | 237 | 0 |
  | Coido - -20​-​20 Volume 3- L​.​P - 02 We | 0.000 | N | 544 | 0 |
  | Detboi - Welcome to the Darkness (Origin | 0.000 | N | 431 | 0 |
  | DJ Scam - Saatchi (Original Mix).mp3 | 0.000 | Y | 358 | 0 |
  | ADMM49D1 - Origin Unknown - Voyage to th | 0.000 | N | 428 | 0 |
  | Cheetah - SSBB012 Cheetah - The Big Cat  | 0.000 | Y | 323 | 0 |
  | Nikki Nair, DJ ADHD - Where U Find This  | 0.000 | Y | 537 | 0 |
  | Randomer - Smokin - 03 Rye.mp3 | 0.000 | Y | 642 | 0 |

