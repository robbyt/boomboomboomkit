"""Shared harness utilities for the KDD-B2 ablation: metadata schema (DD #8),
corpusVersionHash, determinism reuse, and the eval Acc1 metric.

Story 7.3. Develop-only v1 scaffolding.
"""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

import corpus_common as cc

ML_TRAINING_DIR = cc.ML_TRAINING_DIR
ABLATION_DIR = ML_TRAINING_DIR / "ablation"
CORPUS_SPLITS = ML_TRAINING_DIR / "corpus_splits.json"
SECONDARY_MANIFEST = ML_TRAINING_DIR / "non-rekordbox-secondary-supervised-manifest.json"
UNSUPERVISED_MANIFEST = ML_TRAINING_DIR / "non-rekordbox-unsupervised-pretrain-manifest.json"

METADATA_SCHEMA = "ablation-v1"
SCAFFOLDING_NOTE = "v1 features — FR-18 metrics do not transfer to v2"
FEATURE_SET_VERSION = "v1"
TRAINING_VARIANTS = ("supervisedAugmented", "maskedMelPretrain")
# Kept in sync with ablation_features.WEIGHTING_PROFILES (duplicated to keep this
# module import-light for the metadata-schema test).
WEIGHTING_PROFILES = ("uniform", "sub-band-emphasis")


def set_seeds(seed: int) -> None:
    """Reuse the existing determinism block from `train.py` (AC1/FR-20)."""
    sys.path.insert(0, str(ML_TRAINING_DIR))
    from train import set_seeds as _set_seeds

    _set_seeds(seed)


def harness_git_sha() -> str:
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"], cwd=str(ML_TRAINING_DIR), text=True
        ).strip()
    except Exception:  # noqa: BLE001
        return "unknown"


def compute_corpus_version_hash() -> str:
    """Stable SHA-256 over the CONCRETE corpus state (DD #8): the actual Tony
    split id-lists, the labels SHA, and BOTH expansion-manifest CONTENT hashes
    (not free-text derivation prose). The DD #6 run-B random-split artifact hash is
    recorded SEPARATELY in `{variant}/run_b_random_split.json` (`splitSha`) when run
    B fires — the deterministic main runs are fully pinned by this hash."""
    splits = json.loads(CORPUS_SPLITS.read_text())
    tony = splits["tony"]
    payload: dict[str, Any] = {
        "trainIds": sorted(str(x) for x in tony["train"]),
        "valIds": sorted(str(x) for x in tony["val"]),
        "leaveArtistOutIds": sorted(str(x) for x in tony["leaveArtistOut"]["heldOutTrackIds"]),
        "labelsSha256": tony.get("_provenance", {}).get("labelsSha256", "unknown"),
        "secondaryManifestSha256": (
            cc.file_sha256(SECONDARY_MANIFEST) if SECONDARY_MANIFEST.exists() else "absent"
        ),
        "unsupervisedManifestSha256": (
            cc.file_sha256(UNSUPERVISED_MANIFEST) if UNSUPERVISED_MANIFEST.exists() else "absent"
        ),
    }
    canonical = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode()).hexdigest()


def build_metadata(
    *,
    variant: str,
    seed: int,
    epoch_count: int,
    weighting_profile: str,
    pretrain_epochs: int | None = None,
    mask_ratio: float | None = None,
    extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """The ablation per-variant model_metadata.json schema (DD #8).

    Distinct discriminator `metadataSchema: "ablation-v1"` so a blind json.load
    never confuses it with model.py's schema_version 1. Guardrail-1: promotable
    false + the verbatim scaffoldingNote."""
    if variant not in TRAINING_VARIANTS:
        raise ValueError(f"variant must be one of {TRAINING_VARIANTS}; got {variant!r}")
    if weighting_profile not in WEIGHTING_PROFILES:
        raise ValueError(
            f"weighting_profile must be one of {WEIGHTING_PROFILES}; got {weighting_profile!r}"
        )
    md: dict[str, Any] = {
        "metadataSchema": METADATA_SCHEMA,
        "architecture": "TempoCNN",
        "seed": seed,
        "epochCount": epoch_count,
        "corpusVersionHash": compute_corpus_version_hash(),
        "harnessGitSha": harness_git_sha(),
        "featureSetVersion": FEATURE_SET_VERSION,
        "weightingProfile": weighting_profile,
        "trainingVariant": variant,
        "promotable": False,
        "scaffoldingNote": SCAFFOLDING_NOTE,
    }
    if variant == "maskedMelPretrain":
        md["pretrainEpochs"] = pretrain_epochs
        md["maskRatio"] = mask_ratio
    if extra:
        md.update(extra)
    return md


def write_metadata(variant_dir: Path, metadata: dict[str, Any]) -> Path:
    variant_dir.mkdir(parents=True, exist_ok=True)
    out = variant_dir / "model_metadata.json"
    out.write_text(json.dumps(metadata, indent=2, sort_keys=True) + "\n")
    return out


def require_mps_or_subset(subset: int | None) -> "object":
    """Mirror train.py's HALT (a): full runs require MPS; --subset allows CPU smoke."""
    import torch

    if not torch.backends.mps.is_available() and not subset:
        raise RuntimeError(
            "Full ablation runs require MPS (Apple Silicon). "
            "torch.backends.mps.is_available() is False. Use --subset for CPU smoke."
        )
    return torch.device("mps" if torch.backends.mps.is_available() else "cpu")


def acc1_4pct(pred_bins, true_bins) -> float:
    """Acc1 = within 4% relative BPM (reuses train.acc_4pct semantics)."""

    sys.path.insert(0, str(ML_TRAINING_DIR))
    from train import acc_4pct, bin_to_bpm_tensor

    pred_bpm = bin_to_bpm_tensor(pred_bins)
    true_bpm = bin_to_bpm_tensor(true_bins)
    correct = acc_4pct(pred_bpm, true_bpm).sum().item()
    total = true_bins.shape[0]
    return correct / max(total, 1)
