"""Score the fixed-time variant on GiantSteps and the 12.7 corpus (Story 15.5).

For every track: decode the whole file at 44.1 kHz (no 120 s cap, no PCM
cache), score every candidate 1200-frame crop with the ported rhythm score,
keep at most 4 per the ranking rule, run the model on each kept crop in Python
on `model.pt`, and average their softmax with `mean_of_softmax_ranked`. The
decode is `30 + argmax`, reported raw like the legacy rows, with
`inRuntimeRange` flagging 60...200. A track with no candidate crop abstains
`shorter-than-crop`; one whose candidates all score 0 abstains
`no-rhythmic-crop`.

Corpora:
  - GiantSteps (661 tracks), resolved by `build_fr18_input.resolve_giantsteps`.
  - The 12.7 signed corpus, read-only: the 172 `locked-12.7-member` rows of the
    12.9 bundle-gate seed-42 input. Every file is hashed first; if any differs
    from its recorded `audioSha256`, the run refuses before scoring anything.

Writes `scores-<corpus>.json` (per-track rows, including each kept crop's start
frame, start seconds and rhythm score) and `crops-<corpus>.npz` (per track:
every candidate's start frame and rhythm score, the kept start frames in rank
order, and every kept crop's class probabilities) next to the model.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import time
from pathlib import Path
from typing import Any

import numpy as np

import fixed_time  # noqa: F401  (sys.path setup for the sibling training modules)
from fixed_time import features as ft

ML_TRAINING_DIR = Path(__file__).resolve().parent.parent
DEFAULT_RUN_DIR = ML_TRAINING_DIR / "fixed-time-runs" / "seed_42"
BUNDLE_GATE_INPUT_RELPATH = Path(
    "eval-corpus/bundle-gate/predictions/bundle-gate-input-seed-42.json"
)
LOCKED_CATEGORY = "locked-12.7-member"
EXPECTED_COUNTS = {"giantsteps": 661, "eval-12-7": 172}
CORPORA = tuple(EXPECTED_COUNTS)
AGGREGATOR_NAME = "mean_of_softmax_ranked"
AGGREGATOR_SYMBOL = "fixed_time.score:mean_of_softmax_ranked"
BATCH_CROPS = 64


class ScoreRefusal(RuntimeError):
    """Inputs do not match what the run requires; nothing is scored."""


def mean_of_softmax_ranked(crop_probabilities: np.ndarray) -> np.ndarray:
    """The aggregator: the mean of the kept crops' class-probability vectors.

    `crop_probabilities` is [n_kept, 256] of softmax outputs for the crops the
    rhythm ranking kept (at most 4, in rank order); returns [256]. Every kept
    crop weighs the same.
    """
    if crop_probabilities.ndim != 2 or crop_probabilities.shape[0] == 0:
        raise ValueError(f"need [n_crops > 0, classes], got {crop_probabilities.shape}")
    return crop_probabilities.astype(np.float64).mean(axis=0)


def resolve_aggregator(symbol: str):
    """Resolve a recorded `module:function` aggregator symbol to the function."""
    import importlib

    module_name, _, attr = symbol.partition(":")
    return getattr(importlib.import_module(module_name), attr)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def code_git_sha() -> str:
    """`git rev-parse HEAD`, with `-dirty` when the working tree has changes."""
    import subprocess

    try:
        sha = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=str(ML_TRAINING_DIR), text=True
        ).strip()
        dirty = subprocess.check_output(
            ["git", "status", "--porcelain"], cwd=str(ML_TRAINING_DIR), text=True
        ).strip()
    except (OSError, subprocess.CalledProcessError):
        return "unknown"
    return f"{sha}-dirty" if dirty else sha


# ---------------------------------------------------------------------------
# Corpus resolution
# ---------------------------------------------------------------------------


def load_eval_12_7_rows(bundle_gate_input: Path) -> list[dict[str, Any]]:
    """The 172 locked 12.7 members from the bundle-gate input (read-only)."""
    doc = json.loads(bundle_gate_input.read_text())
    rows = [r for r in doc["tracks"] if r.get("category") == LOCKED_CATEGORY]
    return [
        {
            "trackId": str(r["trackId"]),
            "audioPath": r["audioPath"],
            "groundTruthBPM": float(r["groundTruthBPM"]),
            "audioSha256": r["audioSha256"],
            "corpus": "eval-12-7",
        }
        for r in rows
    ]


def verify_audio_hashes(rows: list[dict[str, Any]]) -> None:
    """Refuse if any file is missing or its sha256 differs from `audioSha256`."""
    bad: list[str] = []
    for r in rows:
        path = Path(r["audioPath"])
        if not path.is_file():
            bad.append(f"{r['trackId']} (missing: {path})")
            continue
        actual = sha256_file(path)
        if actual != r["audioSha256"]:
            bad.append(f"{r['trackId']} (sha256 {actual} != recorded {r['audioSha256']})")
    if bad:
        raise ScoreRefusal("12.7 audio differs from the bundle-gate input: " + ", ".join(bad))


def check_rows(corpus: str, rows: list[dict[str, Any]]) -> None:
    ids = [r["trackId"] for r in rows]
    if len(rows) != EXPECTED_COUNTS[corpus]:
        raise ScoreRefusal(f"{corpus}: {len(rows)} tracks, expected {EXPECTED_COUNTS[corpus]}")
    if len(set(ids)) != len(ids):
        dupes = sorted({i for i in ids if ids.count(i) > 1})
        raise ScoreRefusal(f"{corpus}: duplicate track ids {dupes}")


def resolve_corpus(corpus: str, *, giantsteps_root: str, bundle_gate_input: Path):
    """Rows for `corpus` plus the sha256 of the label/membership source."""
    if corpus == "giantsteps":
        from build_fr18_input import resolve_giantsteps

        if not giantsteps_root:
            raise ScoreRefusal("GIANTSTEPS_CORPUS_PATH is not set")
        rows = resolve_giantsteps(giantsteps_root)
        for r in rows:
            r["audioSha256"] = sha256_file(Path(r["audioPath"]))
        source = Path(giantsteps_root) / "giantsteps-tempo-ground-truth.json"
    else:
        if not bundle_gate_input.is_file():
            raise ScoreRefusal(f"bundle-gate input not found: {bundle_gate_input}")
        rows = load_eval_12_7_rows(bundle_gate_input)
        source = bundle_gate_input
    check_rows(corpus, rows)
    if corpus == "eval-12-7":
        verify_audio_hashes(rows)
    return rows, {"path": str(source), "sha256": sha256_file(source)}


# ---------------------------------------------------------------------------
# Inference
# ---------------------------------------------------------------------------


def load_model(weights: Path, device):
    import torch

    from model import build_reference_model

    model = build_reference_model()
    model.load_state_dict(torch.load(weights, map_location="cpu", weights_only=True))
    model.to(device)
    model.eval()
    return model


def crop_probabilities(model, crops: np.ndarray, device) -> np.ndarray:
    """[n, 128, 1200] z-scored crops -> [n, 256] softmax probabilities."""
    import torch

    out = []
    with torch.no_grad():
        for i in range(0, crops.shape[0], BATCH_CROPS):
            x = torch.from_numpy(np.ascontiguousarray(crops[i : i + BATCH_CROPS])).unsqueeze(1)
            logits = model(x.to(device)).detach().cpu().double()
            out.append(torch.softmax(logits, dim=1).numpy())
    return np.concatenate(out, axis=0)


def decode_audio(path: Path) -> np.ndarray:
    """Whole file, 44.1 kHz mono, the training loader's resampler; no length cap."""
    import librosa

    audio, _ = librosa.load(str(path), sr=ft.SAMPLE_RATE, mono=True, res_type="soxr_hq")
    return np.ascontiguousarray(audio, dtype=np.float32)


def score_track(
    model, row: dict[str, Any], fixture, device, aggregator=mean_of_softmax_ranked
) -> tuple[dict, dict[str, np.ndarray]]:
    """One track -> (row, arrays): arrays hold every candidate's start and rhythm
    score, the kept starts in rank order, and the kept crops' probabilities."""
    audio = decode_audio(Path(row["audioPath"]))
    n_frames, starts, scores = ft.candidate_scores(audio)
    kept = ft.rank_crops(starts, scores)
    by_start = dict(zip(starts, scores))
    base = {
        "trackId": row["trackId"],
        "corpus": row["corpus"],
        "groundTruthBPM": row["groundTruthBPM"],
        "audioSha256": row["audioSha256"],
        "samples": int(audio.shape[0]),
        "frames": n_frames,
        "candidateCrops": len(starts),
        "tailCrop": bool(starts) and starts[-1] % ft.CROP_HOP_FRAMES != 0,
        "keptCrops": [
            {"startFrame": s, "startSeconds": ft.start_seconds(s), "rhythmScore": by_start[s]}
            for s in kept
        ],
    }
    arrays = {
        "starts": np.asarray(starts, dtype=np.int64),
        "scores": np.asarray(scores, dtype=np.float64),
        "kept": np.asarray(kept, dtype=np.int64),
        "probs": np.empty((0, 256), dtype=np.float32),
    }
    if not kept:
        return (
            {
                **base,
                "variantBPM": None,
                "inRuntimeRange": None,
                "abstained": ft.ABSTAIN_SHORT if not starts else ft.ABSTAIN_NO_RHYTHM,
                "meanProbabilityMax": None,
            },
            arrays,
        )
    crops = np.stack([ft.crop_tensor_at(audio, s, fixture) for s in kept])
    probs = crop_probabilities(model, crops, device)
    aggregated = aggregator(probs)
    bpm, in_range = ft.decode_bpm(aggregated)
    arrays["probs"] = probs.astype(np.float32)
    return (
        {
            **base,
            "variantBPM": bpm,
            "inRuntimeRange": in_range,
            "abstained": None,
            "meanProbabilityMax": float(aggregated.max()),
        },
        arrays,
    )


def write_atomic(path: Path, write) -> None:
    """Write via a temp file in the same directory, then rename into place."""
    tmp = path.with_name(f"{path.stem}.tmp{os.getpid()}{path.suffix}")
    write(tmp)
    tmp.replace(path)


def score_corpus(
    corpus: str,
    rows: list[dict[str, Any]],
    model,
    fixture,
    device,
    out_dir: Path,
    meta: dict,
    aggregator,
) -> Path:
    out_rows: list[dict[str, Any]] = []
    arrays: dict[str, np.ndarray] = {}
    t0 = time.time()
    for i, row in enumerate(rows):
        scored, track_arrays = score_track(model, row, fixture, device, aggregator)
        out_rows.append(scored)
        for name, arr in track_arrays.items():
            arrays[f"{name}_{i:04d}"] = arr
        if (i + 1) % 50 == 0 or i + 1 == len(rows):
            print(f"[score:{corpus}] {i + 1}/{len(rows)} ({time.time() - t0:.0f}s)")
    arrays["track_ids"] = np.asarray([r["trackId"] for r in out_rows])
    npz_path = out_dir / f"crops-{corpus}.npz"
    write_atomic(npz_path, lambda p: np.savez_compressed(p, **arrays))
    doc = {
        **meta,
        "corpus": corpus,
        "trackCount": len(out_rows),
        "cropProbabilitiesFile": npz_path.name,
        "cropProbabilitiesSha256": sha256_file(npz_path),
        "cropArrays": (
            "per track index i: starts_i (every candidate start frame), scores_i (its rhythm "
            "score), kept_i (kept start frames in rank order), probs_i ([n_kept, 256] softmax "
            "of the kept crops, in rank order); track_ids maps i to trackId"
        ),
        "inferenceSeconds": time.time() - t0,
        "rows": out_rows,
    }
    out_path = out_dir / f"scores-{corpus}.json"
    write_atomic(out_path, lambda p: p.write_text(json.dumps(doc, indent=2, sort_keys=True) + "\n"))
    print(f"[score:{corpus}] wrote {out_path}")
    return out_path


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Score the fixed-time variant (Story 15.5).")
    p.add_argument("--run-dir", type=Path, default=DEFAULT_RUN_DIR)
    p.add_argument("--corpus", choices=(*CORPORA, "all"), default="all")
    p.add_argument(
        "--legacy-root",
        type=Path,
        default=ML_TRAINING_DIR,
        help="ml-training directory holding the gitignored eval-corpus/ state (read-only)",
    )
    p.add_argument("--device", default="cpu", help="torch device for inference (cpu or mps)")
    args = p.parse_args(argv if argv is not None else sys.argv[1:])

    import torch

    import dataset as ds

    weights = args.run_dir / "model.pt"
    if not weights.is_file():
        print(
            f"ERROR: no variant weights at {weights}; run fixed-time-train first.", file=sys.stderr
        )
        return 2
    bundle_gate_input = args.legacy_root / BUNDLE_GATE_INPUT_RELPATH
    corpora = CORPORA if args.corpus == "all" else (args.corpus,)
    giantsteps_root = os.environ.get("GIANTSTEPS_CORPUS_PATH", "")

    # Resolve and verify every corpus before scoring any of them.
    resolved = {}
    try:
        for corpus in corpora:
            resolved[corpus] = resolve_corpus(
                corpus, giantsteps_root=giantsteps_root, bundle_gate_input=bundle_gate_input
            )
    except ScoreRefusal as e:
        print(f"ERROR: scoring refused. {e}", file=sys.stderr)
        return 3

    fixture = ds.load_fixture(ds.FIXTURE_PATH)
    ft.check_fixture(fixture)
    device = torch.device(args.device)
    model = load_model(weights, device)
    # The aggregator actually applied is the one the recorded symbol resolves to,
    # so the manifest cannot name a function other than the one that ran.
    aggregator = resolve_aggregator(AGGREGATOR_SYMBOL)
    if aggregator.__name__ != AGGREGATOR_NAME:
        raise RuntimeError(f"aggregator symbol {AGGREGATOR_SYMBOL} does not name {AGGREGATOR_NAME}")
    meta = {
        "story": "15.5",
        "modelFile": str(weights),
        "weightsSha256": sha256_file(weights),
        "inputContract": ft.INPUT_CONTRACT,
        "inferenceSecondsPerFrame": ft.SECONDS_PER_FRAME,
        "aggregator": AGGREGATOR_NAME,
        "aggregatorSymbol": AGGREGATOR_SYMBOL,
        "decode": (
            "bpm = 30 + argmax of the aggregated probabilities, reported raw; inRuntimeRange "
            "flags 60...200; no confidence gate"
        ),
        "rankingRule": ft.ranking_rule(),
        "coverage": (
            "whole file (no 120 s cap): every candidate crop rhythm-scored, at most 4 kept"
        ),
        "device": str(device),
        "featureFixtureSha256": fixture.sha256,
        "codeGitSha": code_git_sha(),
    }
    # The label and membership sources as scored, so the report can refuse if
    # either changes between scoring and reporting.
    scored_inputs: dict[str, str] = {}
    gs_truth = Path(giantsteps_root) / "giantsteps-tempo-ground-truth.json"
    if giantsteps_root and gs_truth.is_file():
        scored_inputs["giantstepsGroundTruth"] = sha256_file(gs_truth)
    if bundle_gate_input.is_file():
        scored_inputs["bundleGateInput"] = sha256_file(bundle_gate_input)
    meta["scoredInputs"] = scored_inputs
    for corpus in corpora:
        rows, source = resolved[corpus]
        score_corpus(
            corpus,
            rows,
            model,
            fixture,
            device,
            args.run_dir,
            {**meta, "labelSource": source},
            aggregator,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
