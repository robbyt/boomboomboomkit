"""KDD-B2 comparison report generator (AC5 / AC6). Operator-run after the full
60-epoch ablation runs (AC12 — the winner is the deliverable that gates 7.5).

Story 7.3. Develop-only v1 scaffolding.

Loads both variants' `model.pt` + `model_metadata.json`, runs inference on the
Tony val + leaveArtistOut splits, and emits `kdd-b2-comparison-v1.md` (+ sibling
JSON) with the five KDD-B2 axes:
  (a) Acc1 on tony.val (4% relative)
  (b) inference wall-clock per file (ms)
  (c) peak memory footprint (MB)
  (d) ECE_half_double + reliability-diagram bins + softmax-entropy histogram
      (JSON bins + a Markdown table; no matplotlib at v1 — PNG deferred to 7.7)
  (e) leave-artist-out Acc1 minus random-split Acc1 (the random-split run B is
      read from `{variant}/run_b_random_split.json` when present; else marked
      pending — DD #6 4-run protocol).
Winner = higher tony.val Acc1; tiebreak = lower ECE_half_double when within
+/-2 tracks (AC6, Hendrycks & Gimpel 2017). The qualifying-track count for ECE
is surfaced (Mary/John — a tiebreaker decided by a handful of tracks must be
visible).

Run: `make ablation-compare`.
"""

from __future__ import annotations

import json
import math
import os
import sys
import time

ML_TRAINING_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ML_TRAINING_DIR)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import ablation_common as common  # noqa: E402
import dataset as ds  # noqa: E402
from ablation_locator import LabeledTonyDataset, build_labeled_records  # noqa: E402
from model import build_reference_model  # noqa: E402
from octave_aware_loss import bin_to_bpm  # noqa: E402  (shared bin->BPM mapping)

VARIANTS = ("supervisedAugmented", "maskedMelPretrain")
OUT_MD = common.ABLATION_DIR / "kdd-b2-comparison-v1.md"
OUT_JSON = common.ABLATION_DIR / "kdd-b2-comparison-v1.json"


def _load_model(variant: str, device, weighting_profile: str):
    import torch

    variant_dir = common.ABLATION_DIR / variant
    ckpt = variant_dir / "model.pt"
    if not ckpt.exists():
        raise FileNotFoundError(f"{ckpt} not found — run `make ablation-{_target(variant)}` first.")
    # Validate the sibling metadata before trusting the checkpoint — otherwise a
    # stale/mismatched model.pt silently produces a wrong winner-bearing report
    # (the AC12 deliverable that gates Story 7.5). Codex 2026-06-02.
    md_path = variant_dir / "model_metadata.json"
    if not md_path.exists():
        raise FileNotFoundError(f"{md_path} not found — checkpoint provenance unverifiable.")
    md = json.loads(md_path.read_text())
    for key, want in (
        ("metadataSchema", "ablation-v1"),
        ("trainingVariant", variant),
        ("weightingProfile", weighting_profile),
        ("architecture", "TempoCNN"),
    ):
        if md.get(key) != want:
            raise ValueError(
                f"{md_path}: {key}={md.get(key)!r} != expected {want!r} — "
                f"the checkpoint does not match this comparison's config."
            )
    model = build_reference_model().to(device)
    model.load_state_dict(torch.load(ckpt, map_location=device))
    model.eval()
    return model


def _target(variant: str) -> str:
    return "supervised" if variant == "supervisedAugmented" else "masked-mel"


def _octave_correct(pred_bpm: float, true_bpm: float, tol: float = 0.04) -> bool:
    for f in (1.0, 2.0, 0.5):
        if abs(pred_bpm - f * true_bpm) / max(f * true_bpm, 1e-6) <= tol:
            return True
    return False


def _infer(model, records, device, weighting_profile: str, seed: int):
    """Return per-track (pred_bpm, true_bpm, softmax_max, entropy) + mean latency ms."""
    import torch

    fixture = ds.load_fixture(ds.FIXTURE_PATH)
    dset = LabeledTonyDataset(
        records, fixture, augment=False, seed=seed, weighting_profile=weighting_profile
    )
    out = []
    latencies = []
    with torch.no_grad():
        for i in range(len(dset)):
            x, y = dset[i]
            x = x.unsqueeze(0).to(device)
            t0 = time.perf_counter()
            logits = model(x)
            latencies.append((time.perf_counter() - t0) * 1000.0)
            # CPU before argmax/item — keep int64 off MPS (MPS int64 hazard).
            probs = torch.softmax(logits, dim=1)[0].detach().cpu()
            pred_bin = int(probs.argmax().item())
            smax = float(probs.max().item())
            ent = float(-(probs * (probs + 1e-12).log()).sum().item())
            out.append(
                {
                    "pred_bpm": bin_to_bpm(pred_bin),
                    "true_bpm": bin_to_bpm(int(y)),
                    "softmax_max": smax,
                    "entropy": ent,
                }
            )
    mean_ms = sum(latencies) / max(len(latencies), 1)
    return out, mean_ms


def _acc1(rows) -> tuple[int, int]:
    correct = sum(
        1 for r in rows if abs(r["pred_bpm"] - r["true_bpm"]) / max(r["true_bpm"], 1e-6) <= 0.04
    )
    return correct, len(rows)


def _ece_half_double(rows, n_bins: int = 10) -> tuple[float, int, list[dict]]:
    """ECE over octave-collapsed correctness. Returns (ece, qualifying_count, bins).

    v1 operationalization: "correct" = predicted BPM within 4% of T, 2T, or T/2;
    confidence = softmax max. qualifying_count = all evaluated tracks (surfaced so
    a tiebreaker decided by few tracks is visible)."""
    bins = [
        {"lo": i / n_bins, "hi": (i + 1) / n_bins, "n": 0, "conf": 0.0, "acc": 0.0}
        for i in range(n_bins)
    ]
    for r in rows:
        c = r["softmax_max"]
        idx = min(n_bins - 1, int(c * n_bins))
        bins[idx]["n"] += 1
        bins[idx]["conf"] += c
        bins[idx]["acc"] += 1.0 if _octave_correct(r["pred_bpm"], r["true_bpm"]) else 0.0
    n = len(rows)
    ece = 0.0
    for b in bins:
        if b["n"] == 0:
            continue
        avg_conf = b["conf"] / b["n"]
        avg_acc = b["acc"] / b["n"]
        ece += (b["n"] / max(n, 1)) * abs(avg_acc - avg_conf)
        b["conf"] = round(avg_conf, 4)
        b["acc"] = round(avg_acc, 4)
    return ece, n, bins


def _entropy_histogram(rows, n_bins: int = 10) -> list[int]:
    max_ent = math.log(256)  # uniform over 256 BPM bins = max entropy
    hist = [0] * n_bins
    for r in rows:
        frac = min(0.999, r["entropy"] / max(max_ent, 1e-9))
        hist[int(frac * n_bins)] += 1
    return hist


def _peak_memory_mb() -> float:
    import resource

    rss = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    # macOS reports bytes; Linux reports KB.
    return rss / (1024 * 1024) if sys.platform == "darwin" else rss / 1024


def main(argv: list[str] | None = None) -> int:
    import argparse

    p = argparse.ArgumentParser()
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--weighting-profile", type=str, default="uniform")
    args = p.parse_args(argv if argv is not None else sys.argv[1:])

    common.set_seeds(args.seed)
    # Inference-only report — use MPS if available, else CPU (do NOT require MPS;
    # the operator may re-analyze CPU-trained checkpoints on a non-Apple box).
    import torch

    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")

    val_records = build_labeled_records("val")
    lao_records = build_labeled_records("leaveArtistOut")

    results = {}
    for v in VARIANTS:
        model = _load_model(v, device, args.weighting_profile)
        val_rows, val_ms = _infer(model, val_records, device, args.weighting_profile, args.seed)
        lao_rows, _ = _infer(model, lao_records, device, args.weighting_profile, args.seed)
        val_c, val_n = _acc1(val_rows)
        lao_c, lao_n = _acc1(lao_rows)
        ece, ece_n, ece_bins = _ece_half_double(val_rows)
        # Run B (random split) read from an optional sidecar; else pending (DD #6).
        # A corrupt/truncated sidecar (e.g. a mid-write kill) degrades to pending
        # rather than crashing the whole report (which gates Story 7.5).
        rb = common.ABLATION_DIR / v / "run_b_random_split.json"
        random_acc1 = None
        if rb.exists():
            try:
                parsed = json.loads(rb.read_text())
                acc1 = parsed.get("acc1") if isinstance(parsed, dict) else None
                random_acc1 = float(acc1) if isinstance(acc1, (int, float)) else None
            except (json.JSONDecodeError, OSError, ValueError):
                print(
                    f"[warn] {rb} unreadable/corrupt — run-B treated as pending.", file=sys.stderr
                )
                random_acc1 = None
        results[v] = {
            "val_acc1_correct": val_c,
            "val_acc1_total": val_n,
            "inference_ms_per_file": round(val_ms, 3),
            "ece_half_double": round(ece, 4),
            "ece_qualifying_tracks": ece_n,
            "reliability_bins": ece_bins,
            "softmax_entropy_hist": _entropy_histogram(val_rows),
            "leave_artist_out_acc1_correct": lao_c,
            "leave_artist_out_acc1_total": lao_n,
            "random_split_acc1": random_acc1,
            "lao_minus_random_delta": (
                (lao_c / max(lao_n, 1)) - random_acc1 if random_acc1 is not None else None
            ),
        }

    # Winner: higher val Acc1; tiebreak ECE_half_double within +/-2 tracks (AC6).
    a, b = VARIANTS
    da = results[a]["val_acc1_correct"]
    db = results[b]["val_acc1_correct"]
    if abs(da - db) <= 2:
        winner = a if results[a]["ece_half_double"] <= results[b]["ece_half_double"] else b
        rationale = (
            f"Acc1 within +/-2 tracks ({da} vs {db}); tiebreak on ECE_half_double "
            f"({results[a]['ece_half_double']} vs {results[b]['ece_half_double']}; "
            f"qualifying tracks {results[a]['ece_qualifying_tracks']})."
        )
    else:
        winner = a if da > db else b
        rationale = f"Higher tony.val Acc1 ({da} vs {db}); gap exceeds +/-2 tracks (no tiebreak)."

    # Axis (c): a SINGLE process-wide peak RSS, not per-variant — both variants run
    # in one process and `resource.ru_maxrss` is a process high-water mark, so a
    # per-variant column would be contaminated/monotonic (Codex 2026-06-02). The
    # TempoCNN is ~1.3 MB regardless of arm; footprint is torch/librosa-runtime
    # dominated. A true per-variant figure would need a subprocess per arm (v1 skip).
    payload = {
        "winner": winner,
        "rationale": rationale,
        "process_peak_memory_mb": round(_peak_memory_mb(), 1),
        "results": results,
    }
    OUT_JSON.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    _write_md(payload)
    print(f"Wrote {OUT_MD} + {OUT_JSON}  | winner: {winner}")
    return 0


def _write_md(payload: dict) -> None:
    r = payload["results"]
    lines = [
        "# KDD-B2 ablation comparison (v1 scaffolding)",
        "",
        "> Guardrail 1: v1 features — these metrics do NOT transfer to v2 (Story 7.5).",
        "> The decision that DOES carry forward is the relative winner below.",
        "",
        f"**decision: {payload['winner']}**",
        "",
        f"_{payload['rationale']}_",
        "",
        "| axis | supervisedAugmented | maskedMelPretrain |",
        "|---|---|---|",
    ]
    a, b = "supervisedAugmented", "maskedMelPretrain"

    # The per-cell formatter receives the COLUMN's own result dict (rv) so each
    # column's denominator is its own variant's total — not variant A's for both.
    def row(label, key, fmt=lambda x, rv: x):
        return f"| {label} | {fmt(r[a].get(key), r[a])} | {fmt(r[b].get(key), r[b])} |"

    lines += [
        row("(a) tony.val Acc1", "val_acc1_correct", lambda x, rv: f"{x}/{rv['val_acc1_total']}"),
        row("(b) inference ms/file", "inference_ms_per_file"),
        row("(d) ECE_half_double", "ece_half_double"),
        row("    ECE qualifying tracks", "ece_qualifying_tracks"),
        row(
            "(e) leave-artist-out Acc1",
            "leave_artist_out_acc1_correct",
            lambda x, rv: f"{x}/{rv['leave_artist_out_acc1_total']}",
        ),
        row("    random-split Acc1", "random_split_acc1"),
        row("    LAO - random delta (FLOOR; see DD #6)", "lao_minus_random_delta"),
    ]
    lines += [
        "",
        f"(c) peak memory: **{payload.get('process_peak_memory_mb')} MB** process-wide RSS "
        "(both variants evaluated in one process; not per-variant — `ru_maxrss` is a "
        "process high-water mark. The TempoCNN is ~1.3 MB either way; footprint is "
        "torch/librosa-runtime dominated. A per-variant figure would need a subprocess "
        "per arm — out of scope for v1).",
        "",
        "Reliability-diagram bins + softmax-entropy histogram are in the sibling "
        "`kdd-b2-comparison-v1.json` (matplotlib is not a dependency; the `.png` is "
        "deferred to Story 7.7 / FR-25).",
        "",
        "If `random-split Acc1` shows `None`, run B (DD #6 random-split) has not been "
        "executed; the LAO delta is pending. The delta is a FLOOR on the artist-"
        "generalization gap (the random split reshuffles an already-artist-disjoint pool).",
    ]
    OUT_MD.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    sys.exit(main())
