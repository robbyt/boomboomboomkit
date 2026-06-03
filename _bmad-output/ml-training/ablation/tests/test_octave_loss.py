"""FR-16 octave-aware loss assertions (Story 7.3 / DD #2).

Covers the out-of-range octave-partner fix, target normalization, the
strictly-positive-but-discounted octave penalty, and determinism.
"""

from __future__ import annotations

import os
import sys

import pytest
import torch

_ABLATION = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_ML = os.path.dirname(_ABLATION)
sys.path.insert(0, _ML)
sys.path.insert(0, _ABLATION)

import octave_aware_loss as oal  # noqa: E402


def test_soft_targets_sum_to_one():
    bins = torch.tensor([0, 55, 140, 255, 90])
    t = oal.build_octave_soft_targets(bins)
    sums = t.sum(dim=1)
    assert torch.allclose(sums, torch.ones_like(sums), atol=1e-5)


def test_octave_partner_out_of_range_dropped_high():
    # 170 BPM -> bin 140. 2T = 340 BPM is OUT of [30, 285] -> dropped. T/2 = 85 -> bin 55.
    assert oal.bin_to_bpm(140) == 170
    assert oal.octave_partner_bins(140) == [55]


def test_octave_partner_out_of_range_dropped_low():
    # 32 BPM -> bin 2. T/2 = 16 BPM is OUT of range -> dropped. 2T = 64 -> bin 34.
    assert oal.octave_partner_bins(2) == [34]


def test_octave_partners_both_in_range():
    # 60 BPM -> bin 30. 2T = 120 -> bin 90; T/2 = 30 -> bin 0. Both in range.
    assert oal.octave_partner_bins(30) == [0, 90]


def test_no_octave_mass_on_clamped_boundary_bin():
    # The 285-BPM top bin (255): 2T=570 dropped, T/2=142.5->round 142->bin 112. No mass
    # on a clamped boundary; the only partner is the real in-range half.
    t = oal.build_octave_soft_targets(torch.tensor([255]), octave_mass=0.15, label_smoothing=0.0)
    partner = oal.octave_partner_bins(255)
    assert partner == [112]
    # bin 255 keeps primary; bin 112 (T/2) gets octave mass; bin 254 (a clamp neighbor) does not.
    assert t[0, 255] > t[0, 112] > 0.0
    assert t[0, 254] == 0.0


def test_octave_penalty_less_than_far_off():
    # A model confident on the OCTAVE (2T) should incur LESS loss than one confident
    # on a far-off bin, but MORE than predicting the true bin (penalty does not collapse to 0).
    true_bin = 30  # 60 BPM; partners bins 0 (30) and 90 (120)
    y = torch.tensor([true_bin])
    n = oal.BPM_BIN_COUNT
    logits_true = torch.full((1, n), -10.0)
    logits_true[0, true_bin] = 10.0
    logits_octave = torch.full((1, n), -10.0)
    logits_octave[0, 90] = 10.0  # confident on 2T
    logits_far = torch.full((1, n), -10.0)
    logits_far[0, 200] = 10.0  # confident on a far bin (230 BPM)

    loss_true = oal.octave_aware_loss(logits_true, y).item()
    loss_octave = oal.octave_aware_loss(logits_octave, y).item()
    loss_far = oal.octave_aware_loss(logits_far, y).item()

    assert loss_true < loss_octave < loss_far
    assert loss_octave > 0.0  # octave prediction is still penalized


def test_deterministic_identical_inputs():
    y = torch.tensor([10, 140, 90])
    logits = torch.randn(3, oal.BPM_BIN_COUNT, generator=torch.Generator().manual_seed(7))
    a = oal.octave_aware_loss(logits, y).item()
    b = oal.octave_aware_loss(logits, y).item()
    assert a == b


@pytest.mark.parametrize("bad", [-0.1, 1.0, 1.5])
def test_invalid_octave_mass_rejected(bad):
    with pytest.raises(ValueError):
        oal.build_octave_soft_targets(torch.tensor([10]), octave_mass=bad)
