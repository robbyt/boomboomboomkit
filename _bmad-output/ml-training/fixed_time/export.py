"""Export the fixed-time model to a compiled Core ML model the demo app can load.

Reads `model.pt` (a plain state_dict of the reference architecture) from the run
directory, converts it on CPU to an ML program with input `[1, 1, 128, 1200]`
named `input` and output `output` (FP32, macOS 15), compiles it with
`xcrun coremlc`, and writes `fixed_time_seed_<seed>.mlmodelc` next to
`model.pt`. Weights stay in the run directory, outside git.

Before writing anything it checks the conversion on a real crop: the
top-ranked crop of a bundled audio fixture (or `--audio`), built with the same
`fixed_time.features` code that scoring uses. If PyTorch eager and Core ML
outputs differ by more than `--atol` (1e-3), or either holds a NaN or inf, it
refuses and leaves any earlier export in place.

The model is never named or exported as `giantsteps_v2_*`.

Run from `_bmad-output/ml-training/`:
  uv run python -m fixed_time.export --run-dir <run dir>
"""

from __future__ import annotations

import argparse
import json
import math
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np

import fixed_time  # noqa: F401  (sys.path setup for the sibling training modules)
from fixed_time import features as ft

ML_TRAINING_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = ML_TRAINING_DIR.parent.parent
DEFAULT_RUN_DIR = ML_TRAINING_DIR / "fixed-time-runs" / "seed_42"
DEFAULT_AUDIO = (
    REPO_ROOT / "Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/robbyt_x-ray-120s.mp3"
)
INPUT_SHAPE = (1, 1, ft.N_MELS, ft.CROP_FRAMES)


class ExportRefusal(RuntimeError):
    """The export would produce a model that differs from the checkpoint."""


def check_finite_outputs(outputs: dict[str, np.ndarray]) -> None:
    """Refuse if any compared output holds a NaN or inf."""
    for label, values in outputs.items():
        if not np.isfinite(values).all():
            raise ExportRefusal(f"{label} output contains non-finite values")


def check_parity(label: str, diff: float, atol: float) -> None:
    """Refuse unless `diff` is finite and within `atol`. A NaN diff compares
    false against any limit, so it is rejected explicitly."""
    if not math.isfinite(diff):
        raise ExportRefusal(f"{label} max abs difference from eager is not finite ({diff})")
    if diff > atol:
        raise ExportRefusal(f"{label} output differs from eager by {diff:.3e} > {atol}")


def load_state(checkpoint: Path):
    import torch

    state = torch.load(checkpoint, map_location="cpu", weights_only=True)
    if isinstance(state, dict):
        for key in ("model", "state_dict", "model_state_dict", "model_state"):
            inner = state.get(key)
            if isinstance(inner, dict) and any(isinstance(v, torch.Tensor) for v in inner.values()):
                return inner
    return state


def real_crop(audio_path: Path) -> tuple[np.ndarray, dict]:
    """The top-ranked crop of `audio_path` as a [1, 1, 128, 1200] float32 tensor."""
    import dataset as ds
    from fixed_time.score import decode_audio

    fixture = ds.load_fixture(ds.FIXTURE_PATH)
    ft.check_fixture(fixture)
    audio = decode_audio(audio_path)
    _, starts, scores = ft.candidate_scores(audio)
    kept = ft.rank_crops(starts, scores)
    if not kept:
        raise ExportRefusal(f"{audio_path} has no rhythmic crop to check the conversion on")
    crop = ft.crop_tensor_at(audio, kept[0], fixture)
    info = {
        "audio": str(audio_path),
        "startFrame": int(kept[0]),
        "startSeconds": ft.start_seconds(kept[0]),
    }
    return crop.reshape(INPUT_SHAPE).astype(np.float32), info


def export(run_dir: Path, seed: int, audio_path: Path, atol: float) -> Path:
    if not (math.isfinite(atol) and atol >= 0):
        raise ExportRefusal(f"atol must be finite and >= 0, got {atol}")

    import coremltools as ct
    import torch

    from model import build_reference_model

    checkpoint = run_dir / "model.pt"
    if not checkpoint.is_file():
        raise ExportRefusal(f"no checkpoint at {checkpoint}")
    out_path = run_dir / f"fixed_time_seed_{seed}.mlmodelc"
    if out_path.name.startswith("giantsteps_v2"):
        raise ExportRefusal("the fixed-time model must not be named giantsteps_v2_*")

    model = build_reference_model()
    model.load_state_dict(load_state(checkpoint))
    model.eval()

    crop, crop_info = real_crop(audio_path)
    example = torch.from_numpy(crop)
    with torch.no_grad():
        eager = model(example).numpy()
        traced = torch.jit.trace(model, example)
        traced_out = traced(example).numpy()
    check_finite_outputs({"eager": eager, "traced": traced_out})
    trace_diff = float(np.abs(eager - traced_out).max())
    print(f"eager vs traced max abs difference: {trace_diff:.3e}")
    check_parity("trace", trace_diff, atol)

    mlmodel = ct.convert(
        traced,
        inputs=[ct.TensorType(name="input", shape=INPUT_SHAPE, dtype=np.float32)],
        outputs=[ct.TensorType(name="output", dtype=np.float32)],
        minimum_deployment_target=ct.target.macOS15,
        compute_units=ct.ComputeUnit.CPU_ONLY,
        convert_to="mlprogram",
        compute_precision=ct.precision.FLOAT32,
    )
    spec = mlmodel.get_spec()
    in_names = [i.name for i in spec.description.input]
    out_names = [o.name for o in spec.description.output]
    if in_names != ["input"] or out_names != ["output"]:
        raise ExportRefusal(f"tensor names {in_names} -> {out_names}, expected input -> output")

    coreml_out = np.asarray(mlmodel.predict({"input": crop})["output"]).reshape(eager.shape)
    check_finite_outputs({"Core ML": coreml_out})
    diff = float(np.abs(eager - coreml_out).max())
    print(
        f"eager vs Core ML max abs difference on the crop at {crop_info['startSeconds']:.2f} s "
        f"of {audio_path.name}: {diff:.3e} (limit {atol:g})"
    )
    check_parity("Core ML", diff, atol)

    with tempfile.TemporaryDirectory(dir=run_dir, prefix=".fixed-time-export.") as tmp:
        package = Path(tmp) / f"fixed_time_seed_{seed}.mlpackage"
        mlmodel.save(str(package))
        subprocess.run(["xcrun", "coremlc", "compile", str(package), tmp], check=True)
        compiled = Path(tmp) / f"fixed_time_seed_{seed}.mlmodelc"
        if not compiled.is_dir():
            raise ExportRefusal(f"coremlc did not write {compiled}")
        old = run_dir / f".{out_path.name}.old.{os.getpid()}"
        if out_path.exists():
            os.rename(out_path, old)
        try:
            os.rename(compiled, out_path)
        except OSError:
            if old.exists():
                os.rename(old, out_path)
            raise
        shutil.rmtree(old, ignore_errors=True)

    report = {
        "checkpoint": str(checkpoint),
        "output": str(out_path),
        "inputShape": list(INPUT_SHAPE),
        "inputContract": ft.INPUT_CONTRACT,
        "checkCrop": crop_info,
        "eagerVsTracedMaxAbs": trace_diff,
        "eagerVsCoreMLMaxAbs": diff,
        "atol": atol,
        "minimumDeploymentTarget": "macOS15",
        "computePrecision": "FLOAT32",
    }
    report_path = run_dir / f"fixed_time_seed_{seed}.export.json"
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print(f"wrote {out_path}")
    print(f"wrote {report_path}")
    return out_path


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Export the fixed-time model to .mlmodelc.")
    p.add_argument("--run-dir", type=Path, default=DEFAULT_RUN_DIR)
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--audio", type=Path, default=DEFAULT_AUDIO, help="audio for the crop check")
    p.add_argument("--atol", type=float, default=1e-3)
    args = p.parse_args(argv if argv is not None else sys.argv[1:])
    try:
        export(args.run_dir.resolve(), args.seed, args.audio.resolve(), args.atol)
    except ExportRefusal as e:
        print(f"ERROR: export refused. {e}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
