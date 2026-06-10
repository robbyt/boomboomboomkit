"""
Story 4-4b Task 7 — separate CPU-only export script.

Mirrors Apple's universal pattern (verified across apple/ml-fastvit,
apple/corenet, apple/ml-vision-transformers-ane): always trace on CPU after
model.eval(); never touch MPS in the export process. Numerical-equivalence
guard between eager and traced modes (corenet pattern) catches silent trace
divergence BEFORE producing a poisoned .mlmodel (HALT (b) per AC #9).

Output: _bmad-output/ml-models/tempo_classifier.mlmodel (or .mlpackage if
coremltools 9.x writes that for `convert_to=mlprogram` — Task 7.5 verification).

Tensor names locked: "input" / "output" per Story 4-5 DD #16. Verified
post-convert; falls back to ct.utils.rename_feature on miss.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import numpy as np
import torch

from model import build_reference_model

REPO_ROOT = Path(__file__).resolve().parents[2]
ML_TRAINING_DIR = REPO_ROOT / "_bmad-output" / "ml-training"
ML_MODELS_DIR = REPO_ROOT / "_bmad-output" / "ml-models"


def main(argv=None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--checkpoint", type=str, default=str(ML_TRAINING_DIR / "model.pt"))
    p.add_argument(
        "--output",
        type=str,
        default=str(ML_MODELS_DIR / "giantsteps_v1.mlmodel"),
    )
    p.add_argument("--atol", type=float, default=1e-3)
    args = p.parse_args(argv if argv is not None else sys.argv[1:])

    # Step 1 — load checkpoint on CPU (NEVER MPS in export).
    print(f"Loading checkpoint on CPU: {args.checkpoint}")
    state = torch.load(args.checkpoint, map_location="cpu", weights_only=True)
    # Handle wrapped-checkpoint dicts saved by train.py periodic checkpoints
    # (which carry {"epoch", "model", "optimizer", "scheduler"}). The flat
    # final model.pt save is just state_dict; the periodic ones are wrapped.
    # Mirror the chunk-2 P8 unwrap pattern in convert.py.
    if isinstance(state, dict):
        for wrapper_key in ("model", "state_dict", "model_state_dict", "model_state"):
            inner = state.get(wrapper_key)
            if isinstance(inner, dict) and any(isinstance(v, torch.Tensor) for v in inner.values()):
                print(f"Unwrapped checkpoint via key {wrapper_key!r}")
                state = inner
                break
    model = build_reference_model()
    model.load_state_dict(state)
    n_params = sum(p.numel() for p in model.parameters())
    print(f"Model params: {n_params}")

    # Step 2 — eval mode.
    model.eval()

    # Step 3 — deterministic CPU example inputs. Use TWO examples (random +
    # featurized-style) so we exercise both branch-coverage paths a real
    # mel-spectrogram input would hit (post-ReLU dead zones, conv padding
    # boundaries) — random alone may miss them.
    gen = torch.Generator().manual_seed(0)
    example_random = torch.randn(1, 1, 128, 512, generator=gen)
    # "Featurized-style": tightly-bounded values matching the runtime z-scored
    # log-mel envelope distribution (per-band mean ≈ 0, stddev ≈ 1).
    example_featurized = torch.clamp(torch.randn(1, 1, 128, 512, generator=gen), -3.0, 3.0)
    examples = [("random", example_random), ("featurized", example_featurized)]

    # Step 4 — numerical equivalence: eager vs traced (against BOTH examples).
    print("Tracing on CPU...")
    traced_start = time.time()
    traced = torch.jit.trace(model, example_random)
    print(f"Trace built: {time.time() - traced_start:.3f}s")

    eager_vs_traced_max_abs = 0.0
    for label, ex in examples:
        with torch.no_grad():
            eager_out_ex = model(ex)
            traced_out_ex = traced(ex)
        diff = float(torch.abs(eager_out_ex - traced_out_ex).max().item())
        print(f"Eager-vs-traced max abs diff ({label}): {diff:.6e}")
        eager_vs_traced_max_abs = max(eager_vs_traced_max_abs, diff)
        if not torch.allclose(eager_out_ex, traced_out_ex, atol=args.atol):
            print(
                f"\n*** HALT (b): trace divergence on {label} input — max abs "
                f"diff {diff:.6e} > atol {args.atol} ***",
                file=sys.stderr,
            )
            return 2

    # Use the random example for downstream conversion + roundtrip (consistent
    # with the spec's deterministic-test-input contract).
    example = example_random
    with torch.no_grad():
        eager_out = model(example)

    # Step 5 — coremltools.convert
    try:
        import coremltools as ct
    except ImportError:
        print("ERROR: coremltools not installed", file=sys.stderr)
        return 2

    # compute_precision=FLOAT32: coremltools 9.x defaults mlprogram to FLOAT16,
    # which adds ~1e-3 numerical drift. For a 256-class softmax with O(0.1+)
    # logit margins, FP16 drift doesn't change argmax (verified empirically),
    # but the spec's HALT (b) atol=1e-3 is tighter than FP16 reliably hits.
    # FLOAT32 holds tolerance comfortably under 1e-3 and matches the PyTorch
    # eager numerics. Cost: 2× weight size (640 KB → 1.3 MB) — negligible.
    #
    # minimum_deployment_target=macOS15: matches BoomBoomBoomKit's Package.swift
    # `.macOS(.v15)` requirement — no point widening the .mlmodelc deployment
    # marker to macOS14 since library consumers are already on 15+. Spec
    # amendment 2026-05-09 (user-authorized): DD #9 originally specified macOS14
    # for "widest runtime compat", but the library's own minimum is macOS15.
    print("Converting via coremltools.convert(macOS15, CPU_ONLY, mlprogram, FP32)...")
    convert_start = time.time()
    ml_model = ct.convert(
        traced,
        inputs=[ct.TensorType(name="input", shape=(1, 1, 128, 512), dtype=np.float32)],
        outputs=[ct.TensorType(name="output", dtype=np.float32)],
        minimum_deployment_target=ct.target.macOS15,
        compute_units=ct.ComputeUnit.CPU_ONLY,
        convert_to="mlprogram",
        compute_precision=ct.precision.FLOAT32,
    )
    convert_seconds = time.time() - convert_start
    print(f"Convert: {convert_seconds:.1f}s")

    # Step 6 — save with crash-recoverable sibling-staging promotion. Mirrors
    # tools/coreml-convert/convert.py's chunk-2 P10 pattern: stage all
    # intermediate artifacts in a sibling .staging dir; only the final
    # os.rename touches the consumer's --output path. If anything fails
    # before the final rename, the prior good artifact at out_path is
    # preserved.
    import os
    import shutil

    out_path = Path(args.output)
    ML_MODELS_DIR.mkdir(parents=True, exist_ok=True)
    staging_dir = out_path.parent / f".export.{out_path.stem}.{os.getpid()}.staging"
    if staging_dir.exists():
        shutil.rmtree(staging_dir)
    staging_dir.mkdir(parents=True, exist_ok=False)

    try:
        staging_pkg = staging_dir / "model.mlpackage"
        ml_model.save(str(staging_pkg))
        if not staging_pkg.exists():
            print(
                f"\n*** HALT (b): coremltools.save did not produce {staging_pkg} ***",
                file=sys.stderr,
            )
            return 2

        if out_path.suffix == ".mlpackage":
            staged_final = staging_pkg
        else:
            # Story 4.1 .mlmodel-as-directory convention — rename within staging.
            staged_final = staging_dir / "model.mlmodel"
            os.rename(staging_pkg, staged_final)

        # Verify tensor names + roundtrip on the staged artifact BEFORE promotion
        # (so a failure here doesn't touch the consumer's prior good output).
        staged_loaded = ct.models.MLModel(str(staged_final))
        staged_spec = staged_loaded.get_spec()
        staged_in = [i.name for i in staged_spec.description.input]
        staged_out = [o.name for o in staged_spec.description.output]
        if staged_in != ["input"]:
            print(
                f"\n*** HALT (b): staged input tensor name {staged_in} != ['input'] ***",
                file=sys.stderr,
            )
            return 2
        if staged_out != ["output"]:
            # Defensive fallback: rename and re-save.
            print(f"Output name {staged_out} != ['output']; applying ct.utils.rename_feature...")
            ct.utils.rename_feature(
                staged_spec, staged_out[0], "output", rename_inputs=False, rename_outputs=True
            )
            staged_loaded = ct.models.MLModel(staged_spec, weights_dir=staged_loaded.weights_dir)
            staged_loaded.save(str(staged_final))
            staged_loaded = ct.models.MLModel(str(staged_final))
            staged_spec = staged_loaded.get_spec()
            staged_out = [o.name for o in staged_spec.description.output]
            if staged_out != ["output"]:
                print(
                    f"\n*** HALT (b): output rename failed; still {staged_out} ***", file=sys.stderr
                )
                return 2

        # Promote staged artifact → consumer's --output (crash-recoverable).
        # Rename existing → .old.<pid>; rename staged → final; rmtree old.
        # If the second rename fails, restore the old artifact.
        if out_path.exists():
            old_sibling = out_path.parent / f".{out_path.name}.old.{os.getpid()}"
            os.rename(out_path, old_sibling)
            try:
                os.rename(staged_final, out_path)
            except Exception:
                os.rename(old_sibling, out_path)
                raise
            shutil.rmtree(old_sibling, ignore_errors=True)
        else:
            os.rename(staged_final, out_path)
        final_paths = [out_path]
    finally:
        # Always clean up staging dir on success or failure.
        if staging_dir.exists():
            shutil.rmtree(staging_dir, ignore_errors=True)

    # Re-cast in/out_names (computed in Step 7 below) using the now-promoted
    # artifact. The next block re-loads MLModel(out_path) so this is safe.

    # Step 7 — load back via MLModel and verify tensor names + roundtrip.
    print(f"\nVerifying produced artifact at {out_path}")
    loaded = ct.models.MLModel(str(out_path))
    spec = loaded.get_spec()
    in_names = [i.name for i in spec.description.input]
    out_names = [o.name for o in spec.description.output]
    print(f"Input names:  {in_names}")
    print(f"Output names: {out_names}")
    if in_names != ["input"]:
        print(f"\n*** HALT (b): input tensor name {in_names} != ['input'] ***", file=sys.stderr)
        return 2
    if out_names != ["output"]:
        # Defensive fallback: rename and re-save.
        print(f"Output name {out_names} != ['output']; applying ct.utils.rename_feature...")
        ct.utils.rename_feature(spec, out_names[0], "output")
        loaded = ct.models.MLModel(spec, weights_dir=loaded.weights_dir)
        loaded.save(str(out_path))
        # Re-verify
        loaded = ct.models.MLModel(str(out_path))
        spec = loaded.get_spec()
        out_names = [o.name for o in spec.description.output]
        if out_names != ["output"]:
            print(f"\n*** HALT (b): output rename failed; still {out_names} ***", file=sys.stderr)
            return 2

    # Convert-roundtrip equivalence: PyTorch eager vs CoreML predict on same input.
    pred = loaded.predict({"input": example.numpy()})
    cml_out = np.asarray(pred["output"]).reshape(eager_out.shape)
    roundtrip_max = float(np.abs(eager_out.numpy() - cml_out).max())
    print(f"Convert-roundtrip max abs diff (PyTorch eager vs CoreML predict): {roundtrip_max:.6e}")
    if roundtrip_max > args.atol:
        print(
            f"\n*** HALT (b): convert-roundtrip {roundtrip_max:.6e} > atol {args.atol} ***",
            file=sys.stderr,
        )
        return 2

    file_bytes = sum(p.stat().st_size for p in final_paths if p.is_file())
    if not file_bytes:
        # Directory bundle (.mlpackage)
        for p in final_paths:
            if p.is_dir():
                for f in p.rglob("*"):
                    if f.is_file():
                        file_bytes += f.stat().st_size
    print(f"\nProduced: {out_path} ({file_bytes / 1024:.1f} KB)")
    print(f"PyTorch params: {n_params}")
    print(f"Eager-vs-traced max abs: {eager_vs_traced_max_abs:.6e}")
    print(f"Convert-roundtrip max abs: {roundtrip_max:.6e}")
    print("Tensor names: input='input', output='output'")

    # Emit a small convert-report next to the model
    report = {
        "checkpoint": args.checkpoint,
        "output": str(out_path),
        "params": n_params,
        "eager_vs_traced_max_abs": eager_vs_traced_max_abs,
        "convert_roundtrip_max_abs": roundtrip_max,
        "tensor_names": {"input": in_names, "output": out_names},
        "minimum_deployment_target": "macOS15",
        "compute_units": "CPU_ONLY",
        "convert_to": "mlprogram",
        "convert_seconds": convert_seconds,
        "produced_size_bytes": file_bytes,
    }
    report_path = out_path.with_suffix(out_path.suffix + ".convert_report.json")
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True))
    print(f"Wrote {report_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
