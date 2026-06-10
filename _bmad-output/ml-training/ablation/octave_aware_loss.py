"""Octave-aware training loss (FR-16) for the KDD-B2 ablation harness.

Story 7.3 / DD #2. Develop-only v1 scaffolding.

Replaces one-hot cross-entropy with a SOFT-TARGET cross-entropy that places
primary mass on the true BPM bin `T` and documented partial-credit mass on the
octave family `{2T, T/2}` (the OA300/Tony Acc2 convention — NOT the GiantSteps
`{3, 1/3}` triplet extension).

Design decisions baked in (Codex/Winston 2026-06-02 review):
  - Octave partners are computed in BPM space and DROPPED when their BPM falls
    outside [30, 285] BEFORE binning. This avoids the clamp defect where, e.g.,
    a 170 BPM DnB track's `2T = 340` would clamp to bin 255 (285 BPM) and smear
    octave credit onto a spurious in-range bin.
  - Duplicate octave bins are merged before mass assignment.
  - Label smoothing is applied ONCE (not double-counted with the octave mass),
    and the target vector is renormalized to sum to 1.0.
  - The bin<->BPM mapping is a LOCAL 3-line clamp (the real `bpm_to_bin` lives in
    `tools/coreml-convert/reference_arch.py:47`; `dataset.py` has no such
    function). Replicated here to keep this develop-only loss module
    self-contained.

References (per AC2):
  - Schreiber & Müller 2018, "A Single-Step Approach to Musical Tempo Estimation
    Using a Convolutional Neural Network" (tempo-octave error taxonomy).
  - Hendrycks & Gimpel 2017, "A Baseline for Detecting Misclassified and
    Out-of-Distribution Examples in Neural Networks" (calibration tie-in;
    ECE_half_double is the KDD-B2 tiebreaker, AC6).
"""

from __future__ import annotations

import torch
import torch.nn.functional as F

# Bin schema (mirrors dataset.BPM_BIN_* / reference_arch — 256 integer bins 30..285).
BPM_BIN_MIN = 30
BPM_BIN_MAX = 285
BPM_BIN_COUNT = BPM_BIN_MAX - BPM_BIN_MIN + 1  # 256

# Octave family for partial credit (OA300/Tony Acc2 convention).
OCTAVE_FACTORS = (2.0, 0.5)


def bpm_to_bin(bpm: float) -> int:
    """Local 3-line clamp (DD #2). Maps a BPM to its integer bin index [0, 255]."""
    idx = int(round(bpm)) - BPM_BIN_MIN
    return max(0, min(BPM_BIN_COUNT - 1, idx))


def bin_to_bpm(bin_idx: int) -> int:
    """Inverse of `bpm_to_bin` for an in-range integer bin."""
    return int(bin_idx) + BPM_BIN_MIN


def octave_partner_bins(true_bin: int) -> list[int]:
    """Return the in-range, deduped octave-partner bins for `true_bin`.

    Partners (`2T`, `T/2`) are computed in BPM space; any partner whose BPM falls
    outside [BPM_BIN_MIN, BPM_BIN_MAX] is DROPPED before binning (DD #2 — avoids
    the clamp-to-boundary smear). The true bin itself is excluded from the result
    (a partner that collides with `T` carries no separate octave mass).
    """
    t_bpm = bin_to_bpm(true_bin)
    partners: set[int] = set()
    for factor in OCTAVE_FACTORS:
        o_bpm = t_bpm * factor
        if BPM_BIN_MIN <= round(o_bpm) <= BPM_BIN_MAX:
            partners.add(bpm_to_bin(o_bpm))
    partners.discard(int(true_bin))
    return sorted(partners)


def build_octave_soft_targets(
    true_bins: torch.Tensor,
    *,
    octave_mass: float = 0.15,
    label_smoothing: float = 0.05,
    n_bins: int = BPM_BIN_COUNT,
) -> torch.Tensor:
    """Build (N, n_bins) soft targets that sum to 1.0 per row.

    Mass layout per sample:
      - primary `1 - octave_mass` on bin `T` (or `1.0` if no valid octave partner);
      - `octave_mass` split evenly across the in-range octave partners;
      - then label smoothing applied ONCE as a convex combination with the
        uniform distribution (preserves sum == 1.0).

    `octave_mass` is the documented partial-credit weight; it is HELD IDENTICAL
    across both ablation arms (DD #12).
    """
    if not 0.0 <= octave_mass < 1.0:
        raise ValueError(f"octave_mass must be in [0, 1); got {octave_mass}")
    if not 0.0 <= label_smoothing < 1.0:
        raise ValueError(f"label_smoothing must be in [0, 1); got {label_smoothing}")

    device = true_bins.device
    n = true_bins.shape[0]
    targets = torch.zeros(n, n_bins, device=device, dtype=torch.float32)
    for i in range(n):
        t_bin = int(true_bins[i].item())
        partner_bins = octave_partner_bins(t_bin)
        if partner_bins:
            per = octave_mass / len(partner_bins)
            for b in partner_bins:
                targets[i, b] += per
            targets[i, t_bin] += 1.0 - octave_mass
        else:
            # No valid octave partner (track near a band edge) -> all mass on T,
            # so the octave penalty does not silently land on a clamped bin.
            targets[i, t_bin] += 1.0

    if label_smoothing > 0.0:
        targets = targets * (1.0 - label_smoothing) + label_smoothing / n_bins

    return targets


def octave_aware_loss(
    logits: torch.Tensor,
    true_bins: torch.Tensor,
    *,
    octave_mass: float = 0.15,
    label_smoothing: float = 0.05,
) -> torch.Tensor:
    """Soft-target CE over the BPM bins (FR-16).

    `logits`: (N, BPM_BIN_COUNT) raw model outputs. `true_bins`: (N,) long bin idx.
    Predicting an octave (`2T`/`T/2`) still incurs a strictly-positive penalty —
    smaller than a far-off bin, never free ("does not collapse to 0", AC2).
    """
    n_bins = logits.shape[1]
    # Build the soft targets on CPU: the per-element `.item()` Python loop hits a
    # known MPS int64 bug (reads garbage from a Long tensor on the mps device),
    # so move bin labels to CPU first, then move the float targets to the logits
    # device for the multiply.
    targets = build_octave_soft_targets(
        true_bins.detach().to("cpu"),
        octave_mass=octave_mass,
        label_smoothing=label_smoothing,
        n_bins=n_bins,
    ).to(logits.device)
    log_probs = F.log_softmax(logits, dim=1)
    return -(targets * log_probs).sum(dim=1).mean()
