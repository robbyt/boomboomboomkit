"""
Story 4-4b Task 11.3 — Consumer-facing PyTorch → CoreML conversion CLI.

Matches the AC #13 surface defined in DD #13:

  uv run python convert.py --checkpoint <path.pt> --arch <reference|custom>
                           [--module path/to/model.py:ClassName]
                           [--input-shape "1,1,128,512"]
                           --output <path.mlpackage|.mlmodelc>
                           [--target macOS14|macOS15|iOS17|iOS18]
                           [--validate | --no-validate]

Always traces on CPU after `model.eval()` (Apple's universal pattern, DD #9).
Compute units always CPU_ONLY because BNNSGraph (Story 4-5's consumer) reads
MIL + weights directly and ignores the runtime hint.

Exit codes:
  0 — success, validated
  1 — convert succeeded but validation FAILED (HALT (g) per DD #12)
  2 — input error (missing checkpoint, bad architecture spec, etc.)
"""

from __future__ import annotations

import argparse
import errno
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import Optional

import numpy as np
import torch
import torch.nn as nn

# Local imports
from reference_arch import build_reference_model  # noqa: E402
from validate import (  # noqa: E402
    validate_roundtrip_equivalence,
    validate_tensor_names,
    validate_traced_eager_equivalence,
)

THIS_DIR = Path(__file__).resolve().parent


# ---------------------------------------------------------------------------
# Architecture loaders
# ---------------------------------------------------------------------------


def load_reference() -> nn.Module:
    return build_reference_model()


def load_custom(module_spec: str, kwargs: dict | None = None) -> nn.Module:
    """Load `path/to/model.py:ClassName` → instantiate `ClassName(**kwargs)`."""
    if ":" not in module_spec:
        raise ValueError(
            f"--module expects 'path/to/model.py:ClassName' format; got {module_spec!r}"
        )
    path_str, cls_name = module_spec.rsplit(":", 1)
    mod_path = Path(path_str).resolve()
    if not mod_path.exists():
        raise FileNotFoundError(f"Custom module file not found: {mod_path}")

    print(
        f"WARNING: --module executes arbitrary Python from {mod_path}; "
        f"only run with model.py files you trust.",
        file=sys.stderr,
    )
    spec = importlib.util.spec_from_file_location(mod_path.stem, mod_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load module spec for {mod_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    cls = getattr(module, cls_name, None)
    if cls is None:
        raise AttributeError(f"Class {cls_name!r} not found in {mod_path}")
    try:
        return cls(**(kwargs or {}))
    except TypeError as e:
        raise TypeError(
            f"{cls_name}(**{kwargs or {}}) failed: {e}. "
            f"Check the constructor signature of {cls_name} and pass "
            f"--module-args '{{\"key\": value}}' for any required kwargs."
        ) from e


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--checkpoint", required=True, type=str)
    p.add_argument(
        "--arch",
        type=str,
        default="reference",
        choices=["reference", "custom"],
    )
    p.add_argument(
        "--module",
        type=str,
        default=None,
        help="Path to a custom Module file in 'path/to/model.py:ClassName' form. Required when --arch=custom.",
    )
    p.add_argument(
        "--module-args",
        type=str,
        default=None,
        help="JSON object of constructor kwargs for the custom class. "
             'Example: --module-args \'{"n_mels": 128, "dropout": 0.1}\'. '
             "Ignored when --arch=reference.",
    )
    p.add_argument(
        "--input-shape",
        type=str,
        default="1,1,128,512",
        help="Comma-separated input shape. Default matches reference (1,1,128,512).",
    )
    p.add_argument(
        "--output",
        required=True,
        type=str,
        help="Destination path for the produced .mlpackage or .mlmodelc",
    )
    p.add_argument(
        "--target",
        type=str,
        default="macOS15",
        choices=["macOS14", "macOS15", "iOS17", "iOS18"],
        help="Minimum deployment target for the produced .mlmodel. "
             "Default macOS15 matches BoomBoomBoomKit's .macOS(.v15) package "
             "target and the bundled reference's metadata.json availability.",
    )
    val_group = p.add_mutually_exclusive_group()
    val_group.add_argument("--validate", dest="validate", action="store_true", default=True)
    val_group.add_argument(
        "--no-validate",
        dest="validate",
        action="store_false",
        help="Skip eager-vs-traced + tensor-name + roundtrip checks. NOT RECOMMENDED.",
    )
    p.add_argument("--atol", type=float, default=1e-3)
    return p.parse_args(argv)


_SUPPORTED_OUTPUT_EXTS = (".mlpackage", ".mlmodel", ".mlmodelc")


def promote_directory(candidate: Path, final: Path) -> None:
    """Crash-recoverable rename of `candidate` directory to `final`.

    NOT atomic for existing non-empty directory bundles on macOS — Python's
    `os.rename` does not replace non-empty directories. The pattern:
      1. If `final` exists, rename it to `.<name>.old.<pid>` (sibling).
      2. Rename `candidate` to `final`.
      3. rmtree the `.old` sibling.

    If step 2 fails after step 1 succeeded, restore the `.old` sibling back to
    `final` so the consumer's prior good artifact survives. There is a brief
    crash window between steps 1 and 2 during which only the `.old` sibling
    exists; restart can detect this manually and recover.

    Cross-filesystem: if `os.rename` raises `EXDEV`, fail loudly rather than
    silently degrading to copy. The sibling-staging design should make this
    unreachable — if you hit it, your `--output` is on a non-standard layout
    and the caller should be told.
    """
    try:
        if final.exists():
            old = final.parent / f".{final.name}.old.{os.getpid()}"
            os.rename(final, old)
            try:
                os.rename(candidate, final)
            except Exception:
                # Restore prior good artifact before re-raising.
                os.rename(old, final)
                raise
            shutil.rmtree(old, ignore_errors=True)
        else:
            os.rename(candidate, final)
    except OSError as e:
        if e.errno == errno.EXDEV:
            raise OSError(
                errno.EXDEV,
                f"Cross-filesystem rename refused (candidate={candidate}, "
                f"final={final}). Stage on the same filesystem as --output.",
            ) from e
        raise


def main(argv: Optional[list[str]] = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])

    # --- 0. Validate --output extension before any conversion or filesystem work ---
    out_suffix = Path(args.output).suffix
    if out_suffix not in _SUPPORTED_OUTPUT_EXTS:
        print(
            f"ERROR: unsupported output extension {out_suffix!r}. "
            f"Use one of {', '.join(_SUPPORTED_OUTPUT_EXTS)}.",
            file=sys.stderr,
        )
        return 2

    # P12: print --no-validate warning at the START so it's visible in CI logs
    # even if the run is killed/interrupted before the final post-write reminder.
    if not args.validate:
        print(
            "WARNING: --validate is disabled. The produced artifact will be "
            "written without numerical-equivalence or tensor-name checks. "
            "Do NOT ship a model produced with --no-validate to consumers.",
            file=sys.stderr,
        )

    # --- 1. Load checkpoint on CPU (Apple's universal pattern) ---
    ckpt = Path(args.checkpoint)
    if not ckpt.exists():
        print(f"ERROR: checkpoint not found: {ckpt}", file=sys.stderr)
        return 2

    if args.arch == "reference" and args.module:
        print(
            f"WARNING: --module {args.module!r} ignored because --arch=reference",
            file=sys.stderr,
        )

    # Parse --module-args JSON kwargs (used by --arch custom).
    module_kwargs: dict | None = None
    if args.module_args:
        try:
            module_kwargs = json.loads(args.module_args)
        except json.JSONDecodeError as e:
            print(f"ERROR parsing --module-args JSON: {e}", file=sys.stderr)
            return 2
        if not isinstance(module_kwargs, dict):
            print(
                f"ERROR: --module-args must be a JSON object, "
                f"got {type(module_kwargs).__name__}",
                file=sys.stderr,
            )
            return 2
        if not all(isinstance(k, str) for k in module_kwargs.keys()):
            print("ERROR: --module-args keys must all be strings", file=sys.stderr)
            return 2

    print(f"Loading model architecture: {args.arch}")
    if args.arch == "reference":
        model = load_reference()
    elif args.arch == "custom":
        if not args.module:
            print("ERROR: --module is required when --arch=custom", file=sys.stderr)
            return 2
        try:
            model = load_custom(args.module, module_kwargs)
        except Exception as e:
            print(f"ERROR loading custom architecture: {e}", file=sys.stderr)
            return 2
    else:
        print(f"ERROR: unsupported --arch {args.arch!r}", file=sys.stderr)
        return 2

    print(f"Loading checkpoint on CPU: {ckpt}")
    try:
        state = torch.load(str(ckpt), map_location="cpu", weights_only=True)
    except Exception as e:
        print(f"ERROR loading checkpoint (HALT (g)): {e}", file=sys.stderr)
        return 2
    # Common training-framework convention: torch.save({"state_dict": ..., "optimizer": ..., "epoch": ...})
    # or {"model": state_dict}. Unwrap to the flat state_dict so plain consumer
    # checkpoints load without bespoke pre-processing.
    if isinstance(state, dict):
        for wrapper_key in ("state_dict", "model_state_dict", "model", "model_state"):
            inner = state.get(wrapper_key)
            if isinstance(inner, dict) and any(isinstance(v, torch.Tensor) for v in inner.values()):
                print(f"Unwrapped checkpoint via key {wrapper_key!r}")
                state = inner
                break
    try:
        model.load_state_dict(state)
    except Exception as e:
        print(f"ERROR: state_dict shape mismatch (HALT (g)): {e}", file=sys.stderr)
        print(
            "Hint: ensure the architecture passed via --arch matches the "
            "checkpoint. Use --arch custom --module path:ClassName for "
            "non-reference architectures.",
            file=sys.stderr,
        )
        return 2
    n_params = sum(p.numel() for p in model.parameters())
    print(f"Model params: {n_params}")

    # --- 2. Eval mode + deterministic example input ---
    model.eval()
    try:
        shape = tuple(int(x) for x in args.input_shape.split(","))
    except ValueError as e:
        print(f"ERROR parsing --input-shape: {e}", file=sys.stderr)
        return 2
    if len(shape) != 4:
        print(
            f"ERROR: --input-shape must be 4D NCHW, got {len(shape)}D: {shape}",
            file=sys.stderr,
        )
        return 2
    if any(d <= 0 for d in shape):
        print(
            f"ERROR: --input-shape dims must be positive, got {shape}",
            file=sys.stderr,
        )
        return 2
    if any(d > 4096 for d in shape):
        print(
            f"ERROR: --input-shape dim > 4096 (suspect bug); got {shape}",
            file=sys.stderr,
        )
        return 2
    # Element-product cap: prevents "1,1,4096,4096" which passes per-dim but
    # allocates ~67M float32 elements (~256MB) for the example tensor alone.
    _ELEMENT_CAP = 16_000_000
    _total = 1
    for d in shape:
        _total *= d
    if _total > _ELEMENT_CAP:
        print(
            f"ERROR: --input-shape product {_total} exceeds {_ELEMENT_CAP:_} elements; "
            f"too large for a tempo classifier input.",
            file=sys.stderr,
        )
        return 2
    gen = torch.Generator().manual_seed(0)
    example = torch.randn(*shape, generator=gen)

    # --- 3. Trace on CPU ---
    print(f"Tracing on CPU with input shape {shape}...")
    try:
        traced = torch.jit.trace(model, example)
    except Exception as e:
        print(f"ERROR tracing model (HALT (g)): {e}", file=sys.stderr)
        return 2

    # --- 4. Validate eager vs traced (corenet pattern) ---
    eager_traced_ok = True
    eager_traced_max = 0.0
    if args.validate:
        eager_traced_ok, eager_traced_max = validate_traced_eager_equivalence(
            model, traced, example, atol=args.atol
        )
        print(
            f"Eager-vs-traced equivalence: {'OK' if eager_traced_ok else 'FAIL'} "
            f"(max abs diff {eager_traced_max:.6e}, atol {args.atol:.0e})"
        )
        if not eager_traced_ok:
            print(
                "*** HALT (g): eager-vs-traced divergence — refusing to "
                "produce a poisoned .mlmodel ***",
                file=sys.stderr,
            )
            return 1

    # --- 5. Convert via coremltools ---
    try:
        import coremltools as ct
    except ImportError:
        print("ERROR: coremltools not installed", file=sys.stderr)
        return 2

    target_map = {
        "macOS14": ct.target.macOS14,
        "macOS15": ct.target.macOS15,
        "iOS17": ct.target.iOS17,
        "iOS18": ct.target.iOS18,
    }
    convert_target = target_map[args.target]
    print(
        f"Converting (target={args.target}, compute_units=CPU_ONLY, convert_to=mlprogram)..."
    )
    convert_start = time.time()
    ml_model = ct.convert(
        traced,
        inputs=[ct.TensorType(name="input", shape=shape, dtype=np.float32)],
        outputs=[ct.TensorType(name="output", dtype=np.float32)],
        minimum_deployment_target=convert_target,
        compute_units=ct.ComputeUnit.CPU_ONLY,
        convert_to="mlprogram",
        # FP32 explicit: coremltools 9.x defaults mlprogram precision to FP16,
        # which adds ~1e-3 numerical drift and trips the default --atol roundtrip
        # check. FP32 keeps weights bit-identical to the PyTorch source.
        compute_precision=ct.precision.FLOAT32,
    )
    convert_seconds = time.time() - convert_start
    print(f"Convert: {convert_seconds:.1f}s")

    # Defensive: if input/output tensor names didn't propagate through ct.convert
    # (rare on the TorchScript-trace path, but possible across coremltools releases),
    # rename via ct.utils.rename_feature and rebuild MLModel with the patched spec
    # so downstream BNNSGraph consumers still find "input" / "output".
    spec = ml_model.get_spec()
    in_names = [i.name for i in spec.description.input]
    out_names = [o.name for o in spec.description.output]
    renamed = False
    if in_names and in_names != ["input"]:
        ct.utils.rename_feature(spec, in_names[0], "input", rename_inputs=True, rename_outputs=False)
        print(f"Rename fallback: input '{in_names[0]}' → 'input'", file=sys.stderr)
        renamed = True
    if out_names and out_names != ["output"]:
        ct.utils.rename_feature(spec, out_names[0], "output", rename_inputs=False, rename_outputs=True)
        print(f"Rename fallback: output '{out_names[0]}' → 'output'", file=sys.stderr)
        renamed = True
    if renamed:
        ml_model = ct.models.MLModel(spec, weights_dir=ml_model.weights_dir)

    # --- 6. Set up sibling staging directory (P10/P18: crash-recoverable writes) ---
    # All intermediate artifacts go into staging_dir, a sibling of out_path.
    # The consumer's --output is touched only by the final crash-recoverable
    # promote_directory() call. If anything fails before promotion, the prior
    # good artifact at out_path is preserved.
    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    staging_dir = out_path.parent / f".coreml-convert.{out_path.stem}.{os.getpid()}.staging"
    if staging_dir.exists():
        shutil.rmtree(staging_dir)
    staging_dir.mkdir(parents=True, exist_ok=False)

    try:
        staging_pkg = staging_dir / "model.mlpackage"
        ml_model.save(str(staging_pkg))

        # --- 7. Validate against the staged .mlpackage ---
        # coremltools loads .mlpackage natively but cannot directly load .mlmodelc.
        # Validating the staged .mlpackage anchors numerical-equivalence +
        # tensor-name contracts before we touch coremlc. The compiled .mlmodelc
        # gets a separate structural check below in step 8.
        tensor_ok = True
        roundtrip_ok = True
        roundtrip_max = 0.0
        in_names_actual: list[str] = []
        out_names_actual: list[str] = []
        if args.validate:
            loaded = ct.models.MLModel(str(staging_pkg))
            tensor_ok, in_names_actual, out_names_actual = validate_tensor_names(loaded)
            roundtrip_ok, roundtrip_max = validate_roundtrip_equivalence(
                model, loaded, example, atol=args.atol
            )
            print(
                f"Tensor names:    {'OK' if tensor_ok else 'FAIL'} "
                f"(input={in_names_actual}, output={out_names_actual})"
            )
            print(
                f"Roundtrip equiv: {'OK' if roundtrip_ok else 'FAIL'} "
                f"(max abs diff {roundtrip_max:.6e}, atol {args.atol:.0e})"
            )

        # --- 8. Dispatch within staging dir to produce staged_final ---
        structural_ok = True
        structural_missing: list[str] = []
        if out_path.suffix == ".mlpackage":
            staged_final = staging_pkg
        elif out_path.suffix == ".mlmodel":
            # Story 4.1 .mlmodel-as-directory convention — rename in-place.
            staged_final = staging_dir / "model.mlmodel"
            os.rename(staging_pkg, staged_final)
        elif out_path.suffix == ".mlmodelc":
            print(f"Compiling .mlpackage → .mlmodelc via xcrun coremlc...")
            try:
                subprocess.run(
                    ["xcrun", "coremlc", "compile", str(staging_pkg), str(staging_dir)],
                    check=True,
                    capture_output=True,
                )
            except FileNotFoundError:
                print(
                    "ERROR: xcrun not found. Install Xcode command-line tools "
                    "(`xcode-select --install`) and re-run.",
                    file=sys.stderr,
                )
                return 2
            except subprocess.CalledProcessError as e:
                print(
                    f"ERROR: xcrun coremlc compile failed: "
                    f"{e.stderr.decode(errors='replace')}",
                    file=sys.stderr,
                )
                return 1
            # xcrun coremlc compile produces <stem>.mlmodelc inside staging_dir
            staged_final = staging_dir / (staging_pkg.stem + ".mlmodelc")

            # Structural sanity check on the compiled .mlmodelc — catches coremlc
            # corruption (truncated weights, broken op-graph, missing metadata)
            # that the .mlpackage-based validation above cannot see.
            expected = [
                staged_final / "metadata.json",
                staged_final / "model.mil",
                staged_final / "coremldata.bin",
                staged_final / "weights" / "weight.bin",
            ]
            structural_missing = [
                str(p.relative_to(staged_final)) for p in expected
                if not p.exists() or p.stat().st_size == 0
            ]
            structural_ok = not structural_missing
            print(
                f"Structural check: {'OK' if structural_ok else 'FAIL'}"
                + (f" (missing/empty: {structural_missing})" if not structural_ok else "")
            )
        else:
            # _SUPPORTED_OUTPUT_EXTS gate above should make this unreachable.
            print(f"INTERNAL: unsupported extension {out_path.suffix}", file=sys.stderr)
            return 2

        # --- 9. Build report (used by both promotion and failure paths) ---
        # P12: when --no-validate, emit only {skipped, atol} — omit per-check
        # result keys entirely. `null` booleans for skipped checks are
        # schema-hostile; absence is unambiguous.
        validation_block: dict = {"skipped": not args.validate, "atol": args.atol}
        if args.validate:
            validation_block.update({
                "eager_vs_traced_max_abs": eager_traced_max,
                "eager_vs_traced_passed": eager_traced_ok,
                "tensor_names_passed": tensor_ok,
                "tensor_names_input": in_names_actual,
                "tensor_names_output": out_names_actual,
                "roundtrip_max_abs": roundtrip_max,
                "roundtrip_passed": roundtrip_ok,
                "structural_passed": structural_ok,
                "structural_missing": structural_missing,
            })

        # Validation passes if --no-validate (no checks to fail) OR if every
        # check that ran returned OK. Eager-vs-traced is checked earlier and
        # short-circuits with `return 1` on failure, so it's not in this list.
        validation_passed = (
            not args.validate
            or (tensor_ok and roundtrip_ok and structural_ok)
        )

        if validation_passed:
            # --- 10. Promote staged artifact to consumer's --output (P10/P18) ---
            try:
                promote_directory(staged_final, out_path)
            except OSError as e:
                # Promote failed; promote_directory has already restored the
                # consumer's prior artifact (if any) before re-raising. Surface
                # the error and exit non-zero. Do NOT write a report — the
                # staged artifact gets cleaned up in the finally block.
                print(
                    f"ERROR: promotion to {out_path} failed: {e}. "
                    f"Prior artifact at {out_path} (if any) was preserved.",
                    file=sys.stderr,
                )
                return 1
            final_path = out_path
        else:
            # Validation failed. Leave the failed artifact + report at a stable
            # ".failed" sibling location so the consumer can inspect; preserve
            # the consumer's prior good artifact at out_path. (P10/P18 contract:
            # existing artifact survives a forced conversion failure.)
            failed_dest = out_path.parent / f"{out_path.stem}.failed{out_path.suffix}"
            if failed_dest.exists():
                if failed_dest.is_dir():
                    shutil.rmtree(failed_dest)
                else:
                    failed_dest.unlink()
            os.rename(staged_final, failed_dest)
            final_path = failed_dest

        report = {
            "schema_version": 1,
            "checkpoint": str(ckpt),
            "arch": args.arch,
            "module": args.module,
            "input_shape": list(shape),
            "output": str(final_path),
            "promoted": validation_passed,
            "params": n_params,
            "minimum_deployment_target": args.target,
            "compute_units": "CPU_ONLY",
            "convert_to": "mlprogram",
            "convert_seconds": convert_seconds,
            "validation": validation_block,
        }
        if not args.validate:
            print(
                "WARNING: --no-validate skips numerical-equivalence and tensor-name "
                "guards; the produced .mlmodelc may be silently broken. Do NOT ship "
                "a model produced with --no-validate to consumers without re-running "
                "with validation.",
                file=sys.stderr,
            )

        report_path = Path(str(final_path) + ".convert_report.json")
        report_path.write_text(json.dumps(report, indent=2, sort_keys=True))

        if validation_passed:
            print(f"Wrote {final_path}")
            print(f"Wrote {report_path}")
            return 0
        else:
            print(f"Wrote {final_path} (validation FAILED — not promoted to {out_path})")
            print(f"Wrote {report_path}")
            print(
                "*** HALT (g): validation failed — see report above. The prior "
                f"artifact at {out_path} (if any) was preserved. ***",
                file=sys.stderr,
            )
            return 1
    finally:
        # Always clean up the staging dir, even on early-return / exception.
        # If promotion succeeded, staging_dir is now empty. If dispatch failed,
        # staging_dir contains partial work that should not be left behind.
        if staging_dir.exists():
            shutil.rmtree(staging_dir, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
