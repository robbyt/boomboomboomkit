"""Test fixture for --arch custom --module round-trip.

A minimal, distinct-from-reference nn.Module exercising the convert tool's
custom-architecture path. NOT a real tempo classifier — just a smoke fixture.
"""
from __future__ import annotations

import torch
import torch.nn as nn


class CustomTempoCNN(nn.Module):
    """Trivial 2-layer conv net — distinct from reference TempoCNN."""

    def __init__(self) -> None:
        super().__init__()
        self.conv1 = nn.Conv2d(1, 8, kernel_size=(3, 3), padding=1)
        self.relu = nn.ReLU()
        self.gap = nn.AdaptiveAvgPool2d((1, 1))
        self.fc = nn.Linear(8, 256)  # 256 BPM bins, matches BPM_BIN_COUNT

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        x = self.relu(self.conv1(x))
        x = self.gap(x).flatten(1)
        return self.fc(x)
