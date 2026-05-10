"""
Story 4-4b model.py — re-exports the canonical reference architecture from
`tools/coreml-convert/reference_arch.py` per DD #13 / codex Med #6.

Single source of truth lives at `tools/coreml-convert/reference_arch.py`
(the directory that ships to main). Training imports from there at runtime
via the local repo path. Drift between training and convert is caught at
the dev's daily smoke-run because both depend on the same module.

Public API (re-exports):
  - `TempoCNN` — the nn.Module class
  - `build_reference_model()` — factory function
  - `verify_param_budget(model)` — assert 150k ≤ params ≤ 350k
  - `BPM_BIN_COUNT`, `BPM_BIN_MIN`, `BPM_BIN_MAX` — bin schema constants
  - `bin_to_bpm`, `bpm_to_bin` — bin index ↔ BPM mapping helpers
"""

from __future__ import annotations

import sys
from pathlib import Path

# Import from tools/coreml-convert/reference_arch.py — canonical source.
_REPO_ROOT = Path(__file__).resolve().parents[2]
_REFERENCE_ARCH_DIR = _REPO_ROOT / "tools" / "coreml-convert"
if str(_REFERENCE_ARCH_DIR) not in sys.path:
    sys.path.insert(0, str(_REFERENCE_ARCH_DIR))

from reference_arch import (  # noqa: E402
    BPM_BIN_COUNT,
    BPM_BIN_MAX,
    BPM_BIN_MIN,
    TempoCNN,
    bin_to_bpm,
    bpm_to_bin,
    build_reference_model,
    verify_param_budget,
)

__all__ = [
    "BPM_BIN_COUNT",
    "BPM_BIN_MAX",
    "BPM_BIN_MIN",
    "TempoCNN",
    "bin_to_bpm",
    "bpm_to_bin",
    "build_reference_model",
    "verify_param_budget",
]


def write_model_artifacts(out_dir: Path) -> None:
    """Write model_summary.txt + model_metadata.json (Tasks 4.3-4.4)."""
    import json

    import torch
    import torchinfo

    model = build_reference_model()
    n_params = verify_param_budget(model)

    # model_summary.txt via torchinfo
    summary = torchinfo.summary(
        model,
        input_size=(1, 1, 128, 512),
        col_names=("input_size", "output_size", "num_params", "kernel_size"),
        depth=3,
        verbose=0,
    )
    (out_dir / "model_summary.txt").write_text(str(summary))

    # model_metadata.json — bin centers + arch summary (Story 4-5 lookup)
    bin_centers = [float(BPM_BIN_MIN + i) for i in range(BPM_BIN_COUNT)]
    metadata = {
        "schema_version": 1,
        "story": "4-4b",
        "architecture": "TempoCNN (S&M-style shallow CNN, 3 conv blocks, scaled down)",
        "source_module": "tools/coreml-convert/reference_arch.py",
        "n_params": n_params,
        "input_shape_nchw": [1, 1, 128, 512],
        "input_dtype": "float32",
        "output_shape": [1, BPM_BIN_COUNT],
        "output_semantic": "logits over BPM bins (apply softmax for probabilities)",
        "bpm_bin_min": BPM_BIN_MIN,
        "bpm_bin_max": BPM_BIN_MAX,
        "bpm_bin_count": BPM_BIN_COUNT,
        "bin_centers_bpm": bin_centers,
        "bin_to_bpm_formula": "bpm = float(argmax + bpm_bin_min)",
        "feature_set_version": "v1",
        "tensor_names": {"input": "input", "output": "output"},
    }
    (out_dir / "model_metadata.json").write_text(
        json.dumps(metadata, indent=2, sort_keys=True)
    )


if __name__ == "__main__":
    out = Path(__file__).resolve().parent
    write_model_artifacts(out)
    print(f"Wrote model_summary.txt and model_metadata.json to {out}")
