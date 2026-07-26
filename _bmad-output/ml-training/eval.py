"""
Story 4-4b Task 6 — eval the trained model on OA300 held-out test.

Two run modes (controlled by --source):
  --source pytorch  : load model.pt + reconstruct PyTorch model, run inference
                      on CPU. Faster for smoke; primary mode while iterating.
  --source coreml   : load _bmad-output/ml-models/tempo_classifier.mlmodel and
                      run via coremltools.MLModel.predict. AC #11 binding mode
                      ("eval.py runs inference directly through the produced
                      .mlmodel — not through a Python re-implementation of
                      BNNSTechnique").
  --source both     : run both, assert outputs agree within 1e-3 (DD #11
                      convert-roundtrip sanity HALT).

Three named accuracy metrics per AC #11 / DD #11:
  acc_4pct  := |pred - truth| / truth ≤ 0.04   (S&M 2018 Acc1, MIREX-comparable)
  acc_2pct  := |pred - truth| / truth ≤ 0.02   (this repo's Acc1, ablation comparable)
  strict_0_5 := |pred - truth| ≤ 0.5 BPM       (named-DnB strictness)

Sanity HALTs (must hold — story-gating per DD #11):
  - OA300 acc_4pct ≥ 5% (≥ 5/82 tracks)
  - 100% non-NaN/non-Inf softmax outputs
  - convert-roundtrip equivalence (when --source both): max abs diff ≤ 1e-3

Advisory HALT (named-DnB strict_0_5 ≥ 2/4) and promotion warning
(OA300 acc_4pct ≥ 25%) are reported but do NOT trip the script's exit code —
they require Project Lead acknowledgement at story handoff.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
import torch

from dataset import (
    BPM_BIN_MIN,
    FIXTURE_PATH,
    SAMPLE_RATE,
    TARGET_FRAMES,
    build_splits,
    extract_log_mel,
    load_fixture,
    sample_window,
    zscore_per_band,
)
from model import build_reference_model

ML_TRAINING_DIR = Path(__file__).resolve().parent
EVAL_REPORT_PATH = ML_TRAINING_DIR / "eval_report.json"
ML_MODELS_DIR = ML_TRAINING_DIR.parent / "ml-models"
DEFAULT_MLMODEL_PATH = ML_MODELS_DIR / "giantsteps_v1.mlmodel"

# --- DnB triplet target ground-truth (dawproject-verified) per DD #1 ---
DNB_TRACKS = [
    ("Charly (Neekeetone Jungle Rework)", 160.0, "Charly"),
    ("1. The Faraday_Bunker (D-Struct Remix)", 170.0, "Faraday_Bunker"),
    ("4. Yin Yang Audio_Within Cells Interlinked (Acid Lab Remix)", 170.0, "Yin Yang"),
    ("9. HEFT_Anagram 6 (Owl Remix)", 170.0, "HEFT_Anagram"),
]


# ---------------------------------------------------------------------------
# Inference: PyTorch path
# ---------------------------------------------------------------------------


def featurize_for_inference(audio: np.ndarray, fixture) -> np.ndarray:
    """Same pipeline as train-time eval (no augmentation, centered window)."""
    log_mel = extract_log_mel(audio, fixture)  # (n_mels, T)
    log_mel = sample_window(log_mel, TARGET_FRAMES, training=False)
    z = zscore_per_band(log_mel)
    return z[np.newaxis, np.newaxis, :, :].astype(np.float32)  # (1, 1, n_mels, T)


# ---------------------------------------------------------------------------
# GH-141 octave-folded decode (mirror of
# `BNNSTechnique.octaveFoldCandidate` in Sources/BoomBoomBoomKitML/).
#
# The Swift runtime and this offline scorer MUST agree, or a measured
# improvement here would not be the improvement consumers get. Keep the two
# in lockstep: same downward-only direction, same straddling-bin sum, same
# >= comparison, same 60 BPM floor, same in-range precondition.
#
# NOT mirrored, deliberately: the Swift side's construction-time threshold
# validation/clamping (this is a scorer; --octave-fold-threshold is operator
# input) and its up-front non-finite-logit rejection.
#
# KNOWN BOUNDARY DIVERGENCE: Swift sums the two straddling bins in `Float`;
# NumPy widens to binary64 here. The two therefore round differently in the
# last bits, so a threshold set exactly at a computed ratio can fall on
# opposite sides in the two implementations. Immaterial for sweeping (ratios
# are compared against coarse thresholds) but it means this is not a
# bit-exact mirror, and a track sitting exactly on a threshold may be scored
# differently offline than at runtime.
# ---------------------------------------------------------------------------

OCTAVE_FOLD_DISABLED = None


def decode_bpm(probs: np.ndarray, fold_threshold: float | None = OCTAVE_FOLD_DISABLED) -> float:
    """Decode a BPM from a 256-bin posterior.

    With ``fold_threshold`` None this is the bare argmax the model was
    trained against, byte-for-byte the pre-GH-141 behaviour. With a float
    it folds to the fundamental when the posterior mass at half the argmax
    tempo reaches ``fold_threshold`` times the argmax bin's own mass.

    Folding is downward only: the E0 diagnostic measured 38 doubling
    errors below 100 BPM and zero halving errors in any band.
    """
    # np.argmax raises on an empty array; Swift returns a clean abstain for
    # empty logits, so refuse explicitly rather than surfacing a numpy error
    # from the middle of a corpus scoring run.
    if probs.size == 0:
        raise ValueError("decode_bpm: empty posterior (Swift decodes this as abstain)")
    pred_bin = int(np.argmax(probs))
    bpm = float(pred_bin + BPM_BIN_MIN)
    if fold_threshold is None:
        return bpm
    # Fold only on the in-range path, matching Swift: an out-of-range
    # argmax keeps reporting raw.
    if not (60.0 <= bpm <= 200.0):
        return bpm
    max_mass = float(probs[pred_bin])
    if not np.isfinite(max_mass) or max_mass <= 0.0:
        return bpm
    folded = bpm / 2.0
    if folded < 60.0:
        return bpm
    half_index = (pred_bin - BPM_BIN_MIN) / 2.0
    lower, upper = int(np.floor(half_index)), int(np.ceil(half_index))
    half_mass = 0.0
    if 0 <= lower < len(probs):
        half_mass += float(probs[lower])
    if upper != lower and 0 <= upper < len(probs):
        half_mass += float(probs[upper])
    if half_mass <= 0.0:
        return bpm
    ratio = half_mass / max_mass
    if np.isfinite(ratio) and ratio >= fold_threshold:
        return folded
    return bpm


def predict_pytorch(
    model: torch.nn.Module,
    x: np.ndarray,
    device: torch.device,
    fold_threshold: float | None = OCTAVE_FOLD_DISABLED,
) -> tuple[float, np.ndarray, np.ndarray]:
    """Returns (predicted_bpm, softmax_probs, raw_logits)."""
    model.eval()
    with torch.no_grad():
        t = torch.from_numpy(x).to(device)
        logits_t = model(t)
        probs = torch.softmax(logits_t, dim=1).cpu().numpy()[0]
        logits = logits_t.cpu().numpy()[0]
    return decode_bpm(probs, fold_threshold), probs, logits


def predict_coreml(
    mlmodel, x: np.ndarray, fold_threshold: float | None = OCTAVE_FOLD_DISABLED
) -> tuple[float, np.ndarray, np.ndarray]:
    """Returns (predicted_bpm, softmax_probs, raw_logits)."""
    out = mlmodel.predict({"input": x})
    if "output" not in out:
        # Hard-fail: silent fallback to next(iter(...)) would mask an export.py
        # rename bug that AC #9's tensor-name contract is supposed to catch.
        raise RuntimeError(
            f"CoreML model output missing 'output' key; got {list(out.keys())}. "
            "Check export.py tensor-name contract (AC #9 / DD #16)."
        )
    raw_arr = np.asarray(out["output"]).reshape(-1)
    # Apply softmax to convert logits → probs (CoreML model returns logits per AC #9)
    exp = np.exp(raw_arr - raw_arr.max())
    probs = exp / exp.sum()
    return decode_bpm(probs, fold_threshold), probs, raw_arr


# ---------------------------------------------------------------------------
# Metric helpers
# ---------------------------------------------------------------------------


def _acc_4pct(pred: float, truth: float) -> bool:
    return truth > 0 and abs(pred - truth) / truth <= 0.04


def _acc_2pct(pred: float, truth: float) -> bool:
    return truth > 0 and abs(pred - truth) / truth <= 0.02


def _strict_0_5(pred: float, truth: float) -> bool:
    return abs(pred - truth) <= 0.5


def _is_finite_softmax(probs: np.ndarray) -> bool:
    return bool(np.all(np.isfinite(probs)) and abs(probs.sum() - 1.0) < 1e-3)


# ---------------------------------------------------------------------------
# Main eval driver
# ---------------------------------------------------------------------------


@dataclass
class EvalResult:
    track_id: str
    ground_truth_bpm: float
    predicted_bpm: float
    abs_error_bpm: float
    rel_error_pct: float
    acc_4pct: bool
    acc_2pct: bool
    strict_0_5: bool
    finite_softmax: bool


def evaluate_corpus(
    records,
    fixture,
    *,
    pt_model: torch.nn.Module | None = None,
    pt_device: torch.device | None = None,
    cml_model=None,
    roundtrip_atol: float = 1e-3,
    show_progress: bool = True,
    fold_threshold: float | None = OCTAVE_FOLD_DISABLED,
) -> tuple[list[EvalResult], dict[str, float]]:
    """Run inference on every record. Returns per-track + roundtrip-stats."""
    import librosa
    from tqdm import tqdm

    iterator = tqdm(records, desc="eval", disable=not show_progress)
    results: list[EvalResult] = []
    # Codex C9: per-track BPM-class diff (max_roundtrip_diff_bpm) is too coarse.
    # A logit drift that doesn't change argmax can still violate the convert
    # numerical-equivalence contract. Track BOTH:
    #   - max_roundtrip_diff_bpm   = abs(pt_pred_bpm - cml_pred_bpm) max
    #   - max_roundtrip_diff_logit = abs(pt_logits - cml_logits) elementwise max
    # The logit-drift gate is the binding AC #9 contract; the BPM-class diff is
    # informational (highlights when drift crosses a bin boundary).
    max_roundtrip_diff_bpm = 0.0
    max_roundtrip_diff_logit = 0.0
    for r in iterator:
        try:
            audio, _ = librosa.load(
                str(r.audio_path), sr=SAMPLE_RATE, mono=True, res_type="soxr_hq"
            )
            audio = audio.astype(np.float32)
        except Exception as e:
            print(f"WARN: failed to load {r.audio_path}: {e}", file=sys.stderr)
            continue

        x = featurize_for_inference(audio, fixture)

        pt_pred = None
        cml_pred = None
        pt_logits = None
        cml_logits = None
        finite = True

        if pt_model is not None:
            pt_pred, pt_probs, pt_logits = predict_pytorch(pt_model, x, pt_device, fold_threshold)
            finite = finite and _is_finite_softmax(pt_probs)
        if cml_model is not None:
            cml_pred, cml_probs, cml_logits = predict_coreml(cml_model, x, fold_threshold)
            finite = finite and _is_finite_softmax(cml_probs)
        if pt_pred is not None and cml_pred is not None:
            bpm_diff = abs(pt_pred - cml_pred)
            if bpm_diff > max_roundtrip_diff_bpm:
                max_roundtrip_diff_bpm = bpm_diff
            if pt_logits is not None and cml_logits is not None:
                logit_diff = float(np.abs(pt_logits - cml_logits).max())
                if logit_diff > max_roundtrip_diff_logit:
                    max_roundtrip_diff_logit = logit_diff

        # Choose the predicted_bpm: CoreML if available else PyTorch.
        chosen = cml_pred if cml_pred is not None else pt_pred
        if chosen is None:
            continue

        bpm = r.bpm
        results.append(
            EvalResult(
                track_id=r.track_id,
                ground_truth_bpm=bpm,
                predicted_bpm=chosen,
                abs_error_bpm=abs(chosen - bpm),
                rel_error_pct=(abs(chosen - bpm) / max(bpm, 1e-6)) * 100.0,
                acc_4pct=_acc_4pct(chosen, bpm),
                acc_2pct=_acc_2pct(chosen, bpm),
                strict_0_5=_strict_0_5(chosen, bpm),
                finite_softmax=finite,
            )
        )

    stats = {
        "max_roundtrip_diff_bpm": max_roundtrip_diff_bpm,
        "max_roundtrip_diff_logit": max_roundtrip_diff_logit,
    }
    return results, stats


def summarize(results: list[EvalResult]) -> dict[str, Any]:
    n = len(results)
    if n == 0:
        return {"acc_4pct_count": 0, "acc_4pct_percent": 0.0, "n": 0}
    acc4 = sum(1 for r in results if r.acc_4pct)
    acc2 = sum(1 for r in results if r.acc_2pct)
    strict = sum(1 for r in results if r.strict_0_5)
    finite = sum(1 for r in results if r.finite_softmax)
    return {
        "n": n,
        "acc_4pct_count": acc4,
        "acc_4pct_percent": 100.0 * acc4 / n,
        "acc_2pct_count": acc2,
        "acc_2pct_percent": 100.0 * acc2 / n,
        "strict_0_5_count": strict,
        "strict_0_5_percent": 100.0 * strict / n,
        "finite_softmax_count": finite,
        "finite_softmax_percent": 100.0 * finite / n,
    }


def named_dnb_subset(results: list[EvalResult]) -> list[dict[str, Any]]:
    """Pull the 4 DnB triplet rows by substring match on track_id + override the
    ground_truth_bpm to the dawproject-verified DD #1 baseline (since OA300 GT
    has Yin Yang/HEFT_Anagram at 85, which is octave-down)."""
    out = []
    for full_id, gt_bpm, needle in DNB_TRACKS:
        matched = next((r for r in results if needle in r.track_id), None)
        if matched is None:
            out.append(
                {
                    "track_id": full_id,
                    "needle": needle,
                    "ground_truth_bpm": gt_bpm,
                    "missing_in_eval": True,
                }
            )
            continue
        out.append(
            {
                "track_id": matched.track_id,
                "ground_truth_bpm": gt_bpm,
                "predicted_bpm": matched.predicted_bpm,
                "abs_error_bpm": abs(matched.predicted_bpm - gt_bpm),
                "rel_error_pct": (abs(matched.predicted_bpm - gt_bpm) / gt_bpm) * 100.0,
                "acc_4pct": _acc_4pct(matched.predicted_bpm, gt_bpm),
                "acc_2pct": _acc_2pct(matched.predicted_bpm, gt_bpm),
                "strict_0_5": _strict_0_5(matched.predicted_bpm, gt_bpm),
            }
        )
    return out


def main(argv=None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--checkpoint", type=str, default=str(ML_TRAINING_DIR / "model.pt"))
    p.add_argument("--mlmodel", type=str, default=str(DEFAULT_MLMODEL_PATH))
    p.add_argument(
        "--source",
        type=str,
        choices=["pytorch", "coreml", "both"],
        default="both",
        help="Inference source. Default 'both' so the canonical gating run "
        "exercises AC #11's CoreML binding mode AND captures the "
        "convert-roundtrip sanity HALT. Use 'pytorch' for fast smoke "
        "iteration during dev (sanity HALT for roundtrip will be omitted "
        "from the report when CoreML is not exercised).",
    )
    p.add_argument("--test-corpus", type=str, default="oa300", choices=["oa300"])
    p.add_argument(
        "--octave-fold-threshold",
        type=float,
        default=None,
        help=(
            "Enable the GH-141 octave-folded decode at this posterior mass ratio. "
            "Omit for the bare argmax the model was trained against, which is the "
            "runtime default. Measured NET-NEGATIVE at every threshold on the "
            "reference model; see 141-octave-fold-impact.json before using it."
        ),
    )
    args = p.parse_args(argv if argv is not None else sys.argv[1:])

    fixture = load_fixture(FIXTURE_PATH)
    splits = build_splits(verify=True)
    test_records = splits["test"]
    print(f"Test set: {len(test_records)} OA300 tracks")

    pt_model = None
    pt_device = None
    cml_model = None

    if args.source in ("pytorch", "both"):
        pt_device = torch.device("cpu")  # CPU for deterministic eval
        pt_model = build_reference_model().to(pt_device)
        state = torch.load(args.checkpoint, map_location=pt_device, weights_only=True)
        # Mirror chunk-2 P8 unwrap: train.py periodic checkpoints are wrapped
        # {"epoch", "model", "optimizer", "scheduler"}; final model.pt is flat.
        if isinstance(state, dict):
            for wrapper_key in ("model", "state_dict", "model_state_dict", "model_state"):
                inner = state.get(wrapper_key)
                if isinstance(inner, dict) and any(
                    isinstance(v, torch.Tensor) for v in inner.values()
                ):
                    print(f"Unwrapped checkpoint via key {wrapper_key!r}")
                    state = inner
                    break
        pt_model.load_state_dict(state)
        print(f"Loaded PyTorch checkpoint: {args.checkpoint}")

    if args.source in ("coreml", "both"):
        try:
            import coremltools as ct
        except ImportError:
            print("ERROR: coremltools not installed", file=sys.stderr)
            return 2
        if not Path(args.mlmodel).exists():
            print(f"ERROR: .mlmodel not found at {args.mlmodel}", file=sys.stderr)
            print("Run `make ml-export` first.", file=sys.stderr)
            return 2
        cml_model = ct.models.MLModel(args.mlmodel)
        print(f"Loaded CoreML model: {args.mlmodel}")

    start = time.time()
    results, stats = evaluate_corpus(
        test_records,
        fixture,
        pt_model=pt_model,
        pt_device=pt_device,
        cml_model=cml_model,
        fold_threshold=args.octave_fold_threshold,
    )
    eval_seconds = time.time() - start

    # Summaries
    overall = summarize(results)
    dnb_results = named_dnb_subset(results)
    dnb_strict_count = sum(1 for r in dnb_results if r.get("strict_0_5") is True)

    # Sanity HALTs. Per chunk-1 P12 review: when --source != 'both', the
    # convert-roundtrip HALT key is OMITTED entirely (mirrors chunk-2
    # convert.py P12 omit-keys-when-skipped) so the report is honest about
    # which gates actually ran. The sanity_halts.values() check still works
    # because the key is absent, not False.
    sanity_halts: dict[str, bool] = {
        "oa300_acc_4pct_>=_5pct": overall["acc_4pct_percent"] >= 5.0,
        # Chunk-1 P-low: 100% exact, not >=99.99 — single non-finite track must
        # trip the HALT.
        "non_nan_outputs_100pct": (
            overall["finite_softmax_count"] == overall["n"] and overall["n"] > 0
        ),
    }
    if args.source == "both":
        sanity_halts["convert_roundtrip_logit_within_1e3"] = (
            stats["max_roundtrip_diff_logit"] <= 1e-3
        )
    advisory_halts = {
        "named_dnb_strict_0_5_>=_2_of_4": dnb_strict_count >= 2,
        "_advisory_only": ("below threshold blocks Story 4-5 signoff, not Story 4-4b production"),
    }
    promotion_warnings = {
        "oa300_acc_4pct_>=_25pct": overall["acc_4pct_percent"] >= 25.0,
        "_signoff_required_if_false": ("Project Lead must acknowledge in Completion Notes"),
    }
    soft_targets = {
        "giantsteps_val_acc_4pct_>=_55pct": None,  # not evaluated here
        "oa300_acc_4pct_>=_40pct": overall["acc_4pct_percent"] >= 40.0,
        "named_dnb_strict_0_5_>=_3_of_4": dnb_strict_count >= 3,
    }

    metadata = {
        "captured_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "checkpoint": args.checkpoint,
        "mlmodel": args.mlmodel if args.source in ("coreml", "both") else None,
        "inference_source": args.source,
        "feature_set_version": "v1",
        "eval_wall_clock_seconds": eval_seconds,
    }
    if args.source == "both":
        metadata["max_roundtrip_diff_bpm"] = stats["max_roundtrip_diff_bpm"]
        metadata["max_roundtrip_diff_logit"] = stats["max_roundtrip_diff_logit"]

    payload = {
        "metadata": metadata,
        "test_corpus": args.test_corpus,
        "test_size": overall["n"],
        "metrics": {
            "acc_4pct_count": overall["acc_4pct_count"],
            "acc_4pct_percent": overall["acc_4pct_percent"],
            "acc_2pct_count": overall["acc_2pct_count"],
            "acc_2pct_percent": overall["acc_2pct_percent"],
            "strict_0_5_count": overall["strict_0_5_count"],
            "strict_0_5_percent": overall["strict_0_5_percent"],
            "finite_softmax_count": overall["finite_softmax_count"],
            "finite_softmax_percent": overall["finite_softmax_percent"],
        },
        "sanity_halts": sanity_halts,
        "advisory_halts": advisory_halts,
        "promotion_warnings": promotion_warnings,
        "soft_targets": soft_targets,
        "named_dnb_results": dnb_results,
        "per_track_predictions": [
            {
                "track_id": r.track_id,
                "ground_truth_bpm": r.ground_truth_bpm,
                "predicted_bpm": r.predicted_bpm,
                "abs_error_bpm": r.abs_error_bpm,
                "rel_error_pct": r.rel_error_pct,
                "acc_4pct": r.acc_4pct,
                "acc_2pct": r.acc_2pct,
                "strict_0_5": r.strict_0_5,
            }
            for r in results
        ],
    }

    EVAL_REPORT_PATH.write_text(json.dumps(payload, indent=2, sort_keys=True))

    # Console summary
    print()
    print(f"=== OA300 held-out test ({overall['n']} tracks) ===")
    print(
        f"acc_4pct: {overall['acc_4pct_count']}/{overall['n']} ({overall['acc_4pct_percent']:.1f}%)"
    )
    print(
        f"acc_2pct: {overall['acc_2pct_count']}/{overall['n']} ({overall['acc_2pct_percent']:.1f}%)"
    )
    print(
        f"strict_0_5: {overall['strict_0_5_count']}/{overall['n']} "
        f"({overall['strict_0_5_percent']:.1f}%)"
    )
    print(
        f"finite_softmax: {overall['finite_softmax_count']}/{overall['n']} "
        f"({overall['finite_softmax_percent']:.1f}%)"
    )
    print(f"\nNamed DnB ({dnb_strict_count}/4 strict_0_5):")
    for r in dnb_results:
        if r.get("missing_in_eval"):
            print(f"  ! {r['needle']}: NOT IN EVAL SET")
            continue
        print(
            f"  {r['ground_truth_bpm']:>6.1f} → {r['predicted_bpm']:>6.1f}  "
            f"(abs {r['abs_error_bpm']:>5.1f}, "
            f"rel {r['rel_error_pct']:>5.1f}%)  "
            f"strict_0_5={r['strict_0_5']}  {r['track_id']}"
        )

    print()
    print("Sanity HALTs (must hold):")
    for k, v in sanity_halts.items():
        print(f"  {'OK ' if v else 'FAIL'} {k}: {v}")
    print("\nAdvisory HALT (Story 4-5 signoff gate):")
    print(
        f"  {'OK ' if advisory_halts['named_dnb_strict_0_5_>=_2_of_4'] else 'FAIL'} "
        f"named_dnb_strict_0_5_>=_2_of_4: "
        f"{advisory_halts['named_dnb_strict_0_5_>=_2_of_4']}"
    )
    print("\nPromotion warning:")
    print(
        f"  {'OK ' if promotion_warnings['oa300_acc_4pct_>=_25pct'] else 'WARN'} "
        f"oa300_acc_4pct_>=_25pct: "
        f"{promotion_warnings['oa300_acc_4pct_>=_25pct']}"
    )
    print(f"\nWrote {EVAL_REPORT_PATH}")
    print(f"Eval wall-clock: {eval_seconds:.1f}s")

    if not all(sanity_halts.values()):
        print("\n*** SANITY HALT TRIPPED — story does not advance per DD #11 ***")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
