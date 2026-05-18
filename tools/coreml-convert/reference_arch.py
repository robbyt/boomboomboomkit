"""
S&M-style shallow tempo CNN — canonical reference architecture (DD #6, DD #13).

This module is the **single source of truth** for the reference TempoCNN class
(codex Med #6 — flipped from `_bmad-output/ml-training/model.py` so the
architecture definition lives in the directory that ships to main).
`_bmad-output/ml-training/model.py` imports from here at runtime.

Layer summary per DD #6 (Schreiber & Müller 2018, scaled DOWN to 3 conv blocks
for the GiantSteps-class corpus size):

  Input              (N, 1, 128, 512) NCHW float32
  ConvBlock1   parallel (1,32),(1,64),(1,96) along time, 16ch each → concat 48ch
  MaxPool      (1, 5) along time
  ConvBlock2   parallel (1,16),(1,32),(1,48) along time, 24ch each → concat 72ch
  MaxPool      (1, 4) along time
  ConvBlock3   parallel (1,8),(1,16),(1,24) along time, 32ch each → concat 96ch
  GlobalAvgPool over (mel, time)
  Dense        256 units, ReLU, Dropout 0.3
  Dense        BPM_BIN_COUNT units (256), softmax during training (CE loss
               applies log_softmax internally; eager output is logits)

Block 2's `out_per_branch=24` (yielding 72ch concat, not 96) is a deliberate
deviation from spec DD #6's stated (32, 32, 32) — needed to land param count
in the [150k, 350k] budget. See the inline comment in `TempoCNN.__init__`.

Total parameters: ~150-350k expected (DD #6 budget; verified by
`verify_param_budget()` below — current implementation reports 315,096 params).
"""

from __future__ import annotations

import torch
import torch.nn as nn

# BPM bin schema per DD #7 — 256 integer bins from 30 to 285 BPM inclusive.
BPM_BIN_MIN = 30
BPM_BIN_MAX = 285
BPM_BIN_COUNT = BPM_BIN_MAX - BPM_BIN_MIN + 1  # 256


def bin_to_bpm(bin_idx: int) -> float:
    """Map argmax bin index to BPM (DD #7)."""
    return float(bin_idx + BPM_BIN_MIN)


def bpm_to_bin(bpm: float) -> int:
    """Map a BPM value to the nearest integer bin index, clamped to [0, 255]."""
    idx = int(round(bpm)) - BPM_BIN_MIN
    return max(0, min(BPM_BIN_COUNT - 1, idx))


class MultiKernelConvBlock(nn.Module):
    """Parallel time-axis conv branches concatenated along channels.

    Each branch is a (1, k_i) Conv2d on time axis with `out_per_branch`
    channels. Outputs are concatenated → total channels =
    out_per_branch * len(kernels).

    Padding is "same" along time (k_i // 2) so all branches preserve spatial
    dim and can be concatenated.
    """

    def __init__(
        self,
        in_channels: int,
        out_per_branch: int,
        kernels_time: tuple[int, ...],
    ):
        super().__init__()
        self.branches = nn.ModuleList(
            [
                nn.Conv2d(
                    in_channels,
                    out_per_branch,
                    kernel_size=(1, k),
                    padding=(0, k // 2),
                )
                for k in kernels_time
            ]
        )
        self.relu = nn.ReLU(inplace=True)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        outs = []
        for conv in self.branches:
            o = conv(x)
            # Pad-2k convs may differ by 1 sample at right edge for even k;
            # crop to the input width to keep concat shapes consistent.
            if o.shape[-1] > x.shape[-1]:
                o = o[..., : x.shape[-1]]
            outs.append(self.relu(o))
        return torch.cat(outs, dim=1)


class TempoCNN(nn.Module):
    """Shallow multi-filter tempo classifier per DD #6."""

    def __init__(
        self,
        n_mels: int = 128,
        n_classes: int = BPM_BIN_COUNT,
        dropout: float = 0.3,
    ):
        super().__init__()
        self.n_mels = n_mels
        self.n_classes = n_classes

        self.block1 = MultiKernelConvBlock(
            in_channels=1, out_per_branch=16, kernels_time=(32, 64, 96)
        )
        self.pool1 = nn.MaxPool2d(kernel_size=(1, 5))

        # Block 2 out_per_branch reduced from 32 to 24 to fit AC #5 param
        # budget [150k, 350k]. Spec DD #6 says (32, 32, 32) but block 3's
        # kernel sizes also accumulate into the spec's ~150-300k target;
        # the dev was authorized to "finalize exact channel counts at Task 4".
        self.block2 = MultiKernelConvBlock(
            in_channels=48, out_per_branch=24, kernels_time=(16, 32, 48)
        )
        self.pool2 = nn.MaxPool2d(kernel_size=(1, 4))

        self.block3 = MultiKernelConvBlock(
            in_channels=72, out_per_branch=32, kernels_time=(8, 16, 24)
        )

        # Global average pool collapses (n_mels, time) → scalar per channel.
        self.gap = nn.AdaptiveAvgPool2d((1, 1))

        # Dense head
        self.fc1 = nn.Linear(96, 256)
        self.fc1_relu = nn.ReLU(inplace=True)
        self.dropout = nn.Dropout(dropout)
        self.fc2 = nn.Linear(256, n_classes)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # x: (N, 1, n_mels, T)
        x = self.block1(x)  # (N, 48, n_mels, T)
        x = self.pool1(x)  # (N, 48, n_mels, T/5)
        x = self.block2(x)  # (N, 72, n_mels, T/5) — 24ch × 3 branches per __init__
        x = self.pool2(x)  # (N, 72, n_mels, T/20)
        x = self.block3(x)  # (N, 96, n_mels, T/20)
        x = self.gap(x)  # (N, 96, 1, 1)
        x = x.flatten(1)  # (N, 96)
        x = self.fc1_relu(self.fc1(x))  # (N, 256)
        x = self.dropout(x)
        x = self.fc2(x)  # (N, n_classes) — logits
        return x


def build_reference_model() -> nn.Module:
    """Public factory for the canonical reference architecture (DD #13)."""
    return TempoCNN()


def verify_param_budget(model: nn.Module, lo: int = 150_000, hi: int = 350_000) -> int:
    """Verify total parameters fall in [lo, hi]; return the count.

    Raises ValueError on out-of-budget — bare `assert` would be silenced
    under `python -O` and lose the regression guard.
    """
    total = sum(p.numel() for p in model.parameters())
    if not (lo <= total <= hi):
        raise ValueError(
            f"TempoCNN param count {total} outside DD #6 budget [{lo}, {hi}]"
        )
    return total


if __name__ == "__main__":
    model = build_reference_model()
    n = verify_param_budget(model)
    print(f"TempoCNN params: {n}")
    print(model)
