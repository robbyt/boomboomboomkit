"""
Build the tiny 1200-wide `.mlmodelc` fixture for the FixedTimeTechnique tests.

The fixture is a seeded, untrained four-layer network (conv, ReLU, global
average pool, linear) with the fixed-time tensor contract: input
`[1, 1, 128, 1200]` named `input`, 256 logits named `output`. It exists so the
tests can check the contract in both directions (FixedTimeTechnique accepts it
and rejects the 512-wide `CustomBundled.mlmodelc`; BNNSTechnique rejects it)
and run the whole-track path end to end. Its BPM output means nothing.

Output: `Tests/BoomBoomBoomKitTests/Fixtures/FixedTimeTiny.mlmodelc/`

Develop-only helper, not shipped to main. The compiled `.mlmodelc` IS
committed (the `CustomBundled.mlmodelc` / `RenamedTensors.mlmodelc` precedent).

Usage:
  cd _bmad-output/ml-training && uv run python scripts/build-fixed-time-fixture.py
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import coremltools as ct  # type: ignore[import-not-found]
import numpy as np
import torch
from torch import nn

REPO_ROOT = Path(__file__).resolve().parents[3]
FIXTURE_DIR = REPO_ROOT / "Tests/BoomBoomBoomKitTests/Fixtures/FixedTimeTiny.mlmodelc"
INPUT_SHAPE = (1, 1, 128, 1200)
SEED = 20261030


class TinyTempoModel(nn.Module):
    def __init__(self) -> None:
        super().__init__()
        self.conv = nn.Conv2d(1, 4, kernel_size=3, padding=1)
        self.relu = nn.ReLU()
        self.pool = nn.AdaptiveAvgPool2d(1)
        self.fc = nn.Linear(4, 256)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        x = self.pool(self.relu(self.conv(x)))
        return self.fc(x.flatten(1))


def main() -> int:
    torch.manual_seed(SEED)
    model = TinyTempoModel().eval()
    example = torch.randn(*INPUT_SHAPE, generator=torch.Generator().manual_seed(SEED))
    with torch.no_grad():
        traced = torch.jit.trace(model, example)
        eager = model(example).numpy()
    mlmodel = ct.convert(
        traced,
        inputs=[ct.TensorType(name="input", shape=INPUT_SHAPE, dtype=np.float32)],
        outputs=[ct.TensorType(name="output", dtype=np.float32)],
        minimum_deployment_target=ct.target.macOS15,
        compute_units=ct.ComputeUnit.CPU_ONLY,
        convert_to="mlprogram",
        compute_precision=ct.precision.FLOAT32,
    )
    diff = float(
        np.abs(eager - np.asarray(mlmodel.predict({"input": example.numpy()})["output"])).max()
    )
    if diff > 1e-4:
        print(f"ERROR: Core ML differs from eager by {diff:.3e}", file=sys.stderr)
        return 2

    with tempfile.TemporaryDirectory() as tmp:
        package = Path(tmp) / "FixedTimeTiny.mlpackage"
        mlmodel.save(str(package))
        subprocess.run(["xcrun", "coremlc", "compile", str(package), tmp], check=True)
        compiled = Path(tmp) / "FixedTimeTiny.mlmodelc"
        if FIXTURE_DIR.exists():
            shutil.rmtree(FIXTURE_DIR)
        shutil.copytree(compiled, FIXTURE_DIR)

    metadata = json.loads((FIXTURE_DIR / "metadata.json").read_text())
    shapes = [entry["shape"] for block in metadata for entry in block.get("inputSchema", [])]
    if shapes != ["[1, 1, 128, 1200]"]:
        print(f"ERROR: fixture input shapes {shapes}", file=sys.stderr)
        return 3
    print(f"OK: {FIXTURE_DIR} (eager vs Core ML {diff:.3e})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
