"""Train the fixed-time variant with the legacy recipe (Story 15.5, develop-only).

The recipe is the legacy maskedMelPretrain seed-42 run in every value except the
input: 30 masked-mel pretraining epochs then 60 fine-tuning epochs, tempo-band
rebalance, uniform weighting, and the loss, optimizer and masking settings
`train.py` passes to `run_v2`. Both phases see [1, 128, 1200] fixed-time crops
from `fixed_time.features`, and the pretraining decoder reconstructs 1200 frames.

Which crop each song uses in each epoch comes only from the crop plan
(`crop-plan.json`, written by `fixed_time.plan` / `make fixed-time-plan`). The
run refuses when the plan is missing or its ranking rule, recipe values or
song-list hashes differ from the run's. Songs the plan skipped (no kept crop)
are left out before the datasets and the rebalancing sampler are built.

Before training, the run reads the archived legacy `model_metadata.json` and
refuses unless the current split hash and the recorded recipe values equal the
legacy ones. The corpus hash is not required to match (owner decision
2026-10-29): the legacy pretraining manifests still held continuous DJ mixes
that commit 1a697a5 removed. The variant trains on the current manifests and
records both corpus hashes and the row counts that differ.

Writes `fixed-time-runs/seed_42/{model.pt,metadata.json,training_log.json}`.
Nothing is named or loadable as `v2` or `giantsteps_v2_seed_*`.

  uv run python -m fixed_time.train_fixed_time --preflight   # shape check + timed subset
  uv run python -m fixed_time.plan                           # crop plan, before the full run
  uv run python -m fixed_time.train_fixed_time               # full run (MPS)
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import fixed_time  # noqa: F401  (sys.path setup for the sibling training modules)
from fixed_time import features as ft

ML_TRAINING_DIR = Path(__file__).resolve().parent.parent
RUNS_DIR = ML_TRAINING_DIR / "fixed-time-runs"
DEFAULT_OUT_DIR = RUNS_DIR / "seed_42"
LEGACY_METADATA = (
    ML_TRAINING_DIR
    / "v2-runs"
    / "_archive"
    / "maskedMelPretrain-seed42-191tracks-rebalance"
    / "model_metadata.json"
)
# The hashes of the legacy run this variant is compared against. The archived
# metadata must carry the split hash and the current split must reproduce it; the
# corpus hash is recorded against the current one, not required to match.
LEGACY_SPLIT_VERSION_HASH = "b89f8d7c6272165e1b20f7b17844b5b30e32789c0811e150abfdf0ee13b4b742"
LEGACY_CORPUS_VERSION_HASH = "25e59a18c658573f4c5bf762c227eddb44b1c78e6b76473f21a7cf4408b928f8"
# Manifest rows behind the legacy corpus hash: the manifests as of 1a697a5~1,
# before continuous DJ mixes were removed (verified: those files reproduce
# LEGACY_CORPUS_VERSION_HASH exactly).
LEGACY_MANIFEST_COMMIT = "1a697a5~1"
LEGACY_MANIFEST_ROWS = {"secondarySupervised": 2172, "unsupervisedPool": 2407}

RUN_KIND = "infrastructure-smoke"
METADATA_SCHEMA = "fixed-time-train-v1"

# The legacy recipe. Values the legacy metadata records are cross-checked against
# it; the rest are the values `train.py` passes to `ablation.train_v2.run_v2`
# (TrainArgs defaults plus the Makefile `ml-train-v2` flags), which its metadata
# hashes do not cover.
RECIPE: dict[str, Any] = {
    "trainingVariant": "maskedMelPretrain",
    "seed": 42,
    "pretrainEpochs": 30,
    "epochCount": 60,
    "tempoBandRebalanced": True,
    "weightingProfile": "uniform",
    "maskRatio": 0.15,
    "maskSpan": 5,
    "batchSize": 32,
    "learningRate": 1e-3,
    "octaveMass": 0.15,
    "labelSmoothing": 0.1,
}
# Recipe keys the legacy metadata records, checked for equality.
LEGACY_RECORDED_KEYS = (
    "trainingVariant",
    "seed",
    "pretrainEpochs",
    "epochCount",
    "tempoBandRebalanced",
    "weightingProfile",
    "maskRatio",
)


class RecipeDriftError(RuntimeError):
    """The variant's split or recipe differs from the legacy run's."""


def check_recipe(legacy: dict[str, Any], *, split_hash: str) -> None:
    """Refuse unless the split hash and the recorded recipe values equal the
    legacy run's. Raises `RecipeDriftError` naming every difference. The corpus
    hash is recorded by `corpus_drift`, never refused on."""
    problems: list[str] = []
    if legacy.get("splitVersionHash") != LEGACY_SPLIT_VERSION_HASH:
        problems.append(
            f"archived legacy splitVersionHash {legacy.get('splitVersionHash')} is not the "
            f"pinned {LEGACY_SPLIT_VERSION_HASH}"
        )
    if split_hash != LEGACY_SPLIT_VERSION_HASH:
        problems.append(
            f"split hash {split_hash} differs from the legacy split hash "
            f"{LEGACY_SPLIT_VERSION_HASH}"
        )
    for key in LEGACY_RECORDED_KEYS:
        if legacy.get(key) != RECIPE[key]:
            problems.append(f"legacy {key}={legacy.get(key)!r}, this recipe has {RECIPE[key]!r}")
    if problems:
        raise RecipeDriftError("recipe drift: " + "; ".join(problems))


def corpus_drift(
    legacy: dict[str, Any], *, corpus_hash: str, manifest_rows: dict[str, int]
) -> dict[str, Any]:
    """Record (never refuse on) how the current corpus differs from the legacy one."""
    return {
        "legacyCorpusVersionHash": legacy.get("corpusVersionHash"),
        "currentCorpusVersionHash": corpus_hash,
        "matches": corpus_hash == legacy.get("corpusVersionHash"),
        "legacyManifestRows": dict(LEGACY_MANIFEST_ROWS),
        "legacyManifestSource": f"git {LEGACY_MANIFEST_COMMIT}",
        "currentManifestRows": dict(manifest_rows),
        "differingRows": {
            k: {"legacy": LEGACY_MANIFEST_ROWS[k], "current": manifest_rows.get(k)}
            for k in LEGACY_MANIFEST_ROWS
            if manifest_rows.get(k) != LEGACY_MANIFEST_ROWS[k]
        },
        "reason": (
            "owner decision 2026-10-29: the legacy pretraining manifests still held "
            "continuous DJ mixes that commit 1a697a5 removed; the variant trains on the "
            "current manifests"
        ),
    }


def current_manifest_rows() -> dict[str, int]:
    import ablation_common as common

    return {
        "secondarySupervised": len(
            json.loads(common.SECONDARY_MANIFEST.read_text())["secondarySupervised"]
        ),
        "unsupervisedPool": len(
            json.loads(common.UNSUPERVISED_MANIFEST.read_text())["unsupervisedPool"]
        ),
    }


def current_hashes() -> tuple[str, str]:
    """(split hash, corpus hash) of the corpus training would read now."""
    import ablation_common as common
    import train_v2_artifacts as tv2

    splits = json.loads(common.CORPUS_SPLITS.read_text())
    return tv2.compute_split_version_hash(splits), common.compute_corpus_version_hash()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def run_guard(legacy_path: Path) -> dict[str, Any]:
    """Run the recipe guard. Returns the hashes; raises `RecipeDriftError`."""
    if not legacy_path.exists():
        raise RecipeDriftError(f"legacy metadata not found: {legacy_path}")
    import masked_mel

    if (RECIPE["maskRatio"], RECIPE["maskSpan"]) != (
        masked_mel.DEFAULT_MASK_RATIO,
        masked_mel.DEFAULT_SPAN,
    ):
        raise RecipeDriftError(
            f"recipe mask ratio/span {RECIPE['maskRatio']}/{RECIPE['maskSpan']} differ from "
            f"masked_mel defaults {masked_mel.DEFAULT_MASK_RATIO}/{masked_mel.DEFAULT_SPAN}"
        )
    legacy = json.loads(legacy_path.read_text())
    split_hash, corpus_hash = current_hashes()
    check_recipe(legacy, split_hash=split_hash)
    return {
        "legacyMetadataPath": str(legacy_path.relative_to(ML_TRAINING_DIR))
        if legacy_path.is_relative_to(ML_TRAINING_DIR)
        else str(legacy_path),
        "legacyMetadataSha256": sha256_file(legacy_path),
        "splitVersionHash": split_hash,
        "corpusVersionHash": corpus_hash,
        "corpusDrift": corpus_drift(
            legacy, corpus_hash=corpus_hash, manifest_rows=current_manifest_rows()
        ),
    }


# ---------------------------------------------------------------------------
# Shape check
# ---------------------------------------------------------------------------


def shape_check() -> dict[str, Any]:
    """The reference model and the masked-mel decoder at [N, 1, 128, 1200]."""
    import torch

    import masked_mel
    from model import build_reference_model

    model = build_reference_model()
    model.eval()
    n = 2
    x = torch.randn(n, *ft.TENSOR_SHAPE[1:])
    with torch.no_grad():
        logits = model(x)
        latent = masked_mel.run_encoder(model, x)
        decoder = masked_mel.MelReconstructionDecoder(
            n_mels=ft.N_MELS, target_frames=ft.CROP_FRAMES
        )
        recon = decoder(latent)
    expected_logits = (n, 256)
    expected_recon = (n, 1, ft.N_MELS, ft.CROP_FRAMES)
    if tuple(logits.shape) != expected_logits:
        raise RuntimeError(f"model output {tuple(logits.shape)}, expected {expected_logits}")
    if tuple(recon.shape) != expected_recon:
        raise RuntimeError(f"decoder output {tuple(recon.shape)}, expected {expected_recon}")
    return {
        "input": [n, *ft.TENSOR_SHAPE[1:]],
        "logits": list(logits.shape),
        "encoderLatent": list(latent.shape),
        "decoderOutput": list(recon.shape),
    }


# ---------------------------------------------------------------------------
# Training
# ---------------------------------------------------------------------------


def _device(subset: int | None):
    import ablation_common as common

    return common.require_mps_or_subset(subset)


def kept_entries(crop_plan: dict[str, Any], name: str) -> list[dict[str, Any]]:
    """The plan's entries for list `name` that were not skipped, in plan order. The
    one skip filter training and the report's exposure count share."""
    return [e for e in crop_plan["songs"][name] if not e["skipped"]]


def planned_inputs(crop_plan: dict[str, Any]) -> dict[str, Any]:
    """Kept songs, in plan order, with their planned crops. Skipped songs are dropped
    here, before any dataset or sampler exists."""
    from ablation_locator import build_labeled_records

    def kept(name: str) -> list[dict[str, Any]]:
        return kept_entries(crop_plan, name)

    def records(name: str) -> list:
        # Labels come from the current label join, never from the plan; the plan
        # only says which songs are kept and in what order.
        by_key = {str(r.audio_path): r for r in build_labeled_records(name)}
        return [by_key[e["key"]] for e in kept(name)]

    return {
        "pretrainPaths": [Path(e["path"]) for e in kept("pretrain")],
        "pretrainSchedules": {e["key"]: e["schedule"] for e in kept("pretrain")},
        "trainRecords": records("train"),
        "trainSchedules": {e["key"]: e["schedule"] for e in kept("train")},
        "valRecords": records("val"),
        "validationCrops": {e["key"]: e["validationCrop"] for e in kept("val")},
    }


def train(
    *,
    crop_plan: dict[str, Any],
    out_dir: Path,
    subset: int | None,
    pretrain_epochs: int,
    epochs: int,
    num_workers: int,
    write_artifacts: bool,
    checkpoints=None,
) -> dict[str, Any]:
    """Masked-mel pretraining then fine-tuning on the planned fixed-time crops.

    Returns timing and result figures. Writes `model.pt.partial` only when
    `write_artifacts` (the full run); the preflight subset run writes no weights.
    With `checkpoints` (a `fixed_time.checkpoints.CheckpointStore`) it saves a
    checkpoint after every epoch and first resumes from the latest one, if any.
    """
    import torch
    from torch.utils.data import DataLoader

    import ablation_common as common
    import dataset as ds
    import masked_mel
    from ablation_train import finetune
    from fixed_time.checkpoints import Resumer
    from fixed_time.datasets import FixedTimeLabeledDataset, FixedTimePretrainDataset
    from model import build_reference_model

    seed = RECIPE["seed"]
    common.set_seeds(seed)
    device = _device(subset)
    fixture = ds.load_fixture(ds.FIXTURE_PATH)
    ft.check_fixture(fixture)
    model = build_reference_model()
    inputs = planned_inputs(crop_plan)
    resumer = Resumer(checkpoints, model, pretrain_epochs=pretrain_epochs)
    resumed_from = resumer.load()
    if resumed_from is not None:
        print(
            f"[fixed-time] resuming from {resumed_from['checkpoint']} "
            f"(phase {resumed_from['phase']}, epoch {resumed_from['completedEpoch']} done)"
        )

    pretrain_paths = inputs["pretrainPaths"]
    if not pretrain_paths:
        raise RuntimeError("empty masked-mel pretraining pool; refusing a random-init encoder")
    print(
        f"[fixed-time] device={device} kept songs: pretrain={len(pretrain_paths)} "
        f"train={len(inputs['trainRecords'])} val={len(inputs['valRecords'])}; "
        f"skipped {crop_plan['skippedSongs']}"
    )

    pretrain_set = FixedTimePretrainDataset(
        pretrain_paths, fixture, schedules=inputs["pretrainSchedules"]
    )
    g_pre = torch.Generator()
    g_pre.manual_seed(seed)
    pretrain_loader = DataLoader(
        pretrain_set,
        batch_size=RECIPE["batchSize"],
        shuffle=True,
        num_workers=num_workers,
        worker_init_fn=ds.worker_init_fn,
        generator=g_pre,
    )
    t0 = time.time()
    if not resumer.skip_pretrain:
        masked_mel.pretrain_encoder(
            model,
            pretrain_loader,
            epochs=pretrain_epochs,
            device=device,
            seed=seed,
            mask_ratio=RECIPE["maskRatio"],
            span=RECIPE["maskSpan"],
            target_frames=ft.CROP_FRAMES,
            **resumer.pretrain_hooks(g_pre, on_epoch_start=pretrain_set.set_epoch),
        )
    pretrain_seconds = resumer.pretrain_seconds_before + (
        0.0 if resumer.skip_pretrain else time.time() - t0
    )
    # Fine-tuning checkpoints carry this total, so a resume from one reports it.
    resumer.pretrain_seconds = pretrain_seconds

    # finetune builds the train and val sets itself; keep them so the epoch
    # callback reaches the train set before each epoch's iterator starts.
    built: list[FixedTimeLabeledDataset] = []

    def dataset_factory(*args, **kwargs):
        d = FixedTimeLabeledDataset(
            *args,
            schedules=inputs["trainSchedules"],
            validation_crops=inputs["validationCrops"],
            **kwargs,
        )
        built.append(d)
        return d

    def on_finetune_epoch(epoch: int) -> None:
        for d in built:
            d.set_epoch(epoch)

    t1 = time.time()
    result = finetune(
        model,
        epochs=epochs,
        batch_size=RECIPE["batchSize"],
        lr=RECIPE["learningRate"],
        seed=seed,
        weighting_profile=RECIPE["weightingProfile"],
        subset=subset,
        device=device,
        octave_mass=RECIPE["octaveMass"],
        label_smoothing=RECIPE["labelSmoothing"],
        num_workers=num_workers,
        train_records=inputs["trainRecords"],
        val_records=inputs["valRecords"],
        feature_path="fixed-time",
        rebalance=RECIPE["tempoBandRebalanced"],
        dataset_factory=dataset_factory,
        **resumer.finetune_hooks(on_epoch_start=on_finetune_epoch),
    )
    finetune_seconds = resumer.finetune_seconds_before + time.time() - t1

    figures: dict[str, Any] = {
        "device": str(device),
        "pretrainTracks": len(pretrain_paths),
        "trainTracks": len(inputs["trainRecords"]),
        "valTracks": len(inputs["valRecords"]),
        "keptSongs": crop_plan["keptSongs"],
        "skippedSongs": crop_plan["skippedSongs"],
        "pretrainSeconds": pretrain_seconds,
        "finetuneSeconds": finetune_seconds,
        "finalValAcc1": result.val_acc1,
        "bestValAcc1": result.best_val_acc1,
        "perEpoch": result.per_epoch,
        "pretrainLosses": list(resumer.pretrain_losses),
        "finetuneTrainLosses": list(resumer.finetune_losses),
        "resumedFrom": resumed_from,
    }
    if write_artifacts:
        # Weights stay under a temp name until write_run_artifacts promotes them
        # together with the metadata.
        out_dir.mkdir(parents=True, exist_ok=True)
        torch.save(model.state_dict(), out_dir / "model.pt.partial")
    return figures


def read_plan(out_dir: Path) -> tuple[dict[str, Any], str]:
    """Load the crop plan and refuse unless it matches the run. Raises PlanError."""
    from fixed_time import plan as cp

    crop_plan, sha = cp.load_plan(out_dir)
    cp.validate_plan(crop_plan, cp.song_lists(None), cp.schedule_recipe())
    return crop_plan, sha


def pcm_source() -> dict[str, Any]:
    """Which PCM training read: the legacy loader's 120 s cache, or a full decode."""
    import ablation_locator as loc

    if loc._PCM_CACHE_DIR:
        return {
            "kind": "pcm-cache",
            "cacheDir": loc._PCM_CACHE_DIR,
            "detail": (
                "BBB_PCM_CACHE_DIR set: every decode is capped at 120 s (librosa soxr_hq, "
                "44.1 kHz mono) and later epochs read the float16 cache entry; a track whose "
                "entry could not be written is re-decoded float32 with the same cap. "
                "Legacy training read the same cache."
            ),
        }
    return {
        "kind": "full-decode",
        "cacheDir": None,
        "detail": "BBB_PCM_CACHE_DIR unset: every epoch decodes the whole file float32 "
        "(librosa soxr_hq, 44.1 kHz mono), then keeps the first 120 s",
    }


TRAINING_CROP_POLICY = (
    "every crop comes from the crop plan. Fine-tuning: each epoch a song uses the kept crop "
    "the plan assigns it for that epoch; a PCM segment starting at that crop (shifted left "
    "when it would overrun the audio) is augmented on PCM (stretch, gain, pink noise, pitch "
    "shift, with the legacy per-song seeding) and the 1200-frame crop is taken where the "
    "ranked audio landed; a song too short for the segment trains with stretch off. "
    "Pretraining: the planned kept crop for the epoch, unaugmented. Validation: the "
    "top-ranked crop."
)
PRETRAINING_CROP_POLICY = (
    "each epoch every kept pretraining song contributes one of its at most 4 rhythm-ranked "
    "1200-frame (12 s) crops from its first 120 s, per the crop plan; legacy pretraining saw "
    "one fixed view per song, its whole 30/60/90 s window resized to 512 columns"
)


def write_run_artifacts(
    out_dir: Path,
    guard: dict[str, Any],
    figures: dict[str, Any],
    plan_info: dict[str, Any],
) -> None:
    import ablation_common as common
    from fixed_time.datasets import FEATURE_CACHE_VERSION

    weights = out_dir / "model.pt.partial"
    metadata = {
        "metadataSchema": METADATA_SCHEMA,
        "runKind": RUN_KIND,
        "architecture": "TempoCNN",
        "modelIdentity": f"fixed-time-crop{ft.CROP_FRAMES}-maskedMelPretrain-seed{RECIPE['seed']}",
        "inputContract": ft.input_contract(),
        "trainingSecondsPerFrame": ft.SECONDS_PER_FRAME,
        "trainingCrop": TRAINING_CROP_POLICY,
        "pretrainingCropPolicy": PRETRAINING_CROP_POLICY,
        "cropPlan": plan_info,
        "reproducibility": (
            "the data schedule is fixed by the crop plan; floating-point training on MPS is "
            "not claimed to be bit-reproducible"
        ),
        "pcmSource": pcm_source(),
        "valAcc1Note": (
            "finalValAcc1 and bestValAcc1 are measured on each validation song's top-ranked "
            "12 s crop and are not comparable with the legacy validation figure"
        ),
        "featureCacheVersion": FEATURE_CACHE_VERSION,
        "recipe": RECIPE,
        "recipeGuard": guard,
        "corpusDrift": guard.get("corpusDrift"),
        "weightsFile": "model.pt",
        "weightsSha256": sha256_file(weights),
        "pretrainTracks": figures["pretrainTracks"],
        "trainTracks": figures["trainTracks"],
        "valTracks": figures["valTracks"],
        "songsWithoutKeptCrop": figures["skippedSongs"],
        "finalValAcc1": figures["finalValAcc1"],
        "bestValAcc1": figures["bestValAcc1"],
        "wallClockSeconds": figures["pretrainSeconds"] + figures["finetuneSeconds"],
        "device": figures["device"],
        "resumed": figures.get("resumedFrom") is not None,
        "resumedFrom": figures.get("resumedFrom"),
        "checkpointDir": "checkpoints",
        "harnessGitSha": common.harness_git_sha(),
        "promotable": False,
        "note": (
            "Develop-only Story 15.5 variant. Not a v2 model and not loadable under the v2 "
            "feature-set version; never export it as giantsteps_v2_seed_*."
        ),
    }
    (out_dir / "metadata.json.partial").write_text(
        json.dumps(metadata, indent=2, sort_keys=True) + "\n"
    )
    (out_dir / "training_log.json.partial").write_text(
        json.dumps(
            {
                "perEpoch": figures["perEpoch"],
                "pretrainLosses": figures.get("pretrainLosses", []),
                "finetuneTrainLosses": figures.get("finetuneTrainLosses", []),
                "pretrainSeconds": figures["pretrainSeconds"],
                "finetuneSeconds": figures["finetuneSeconds"],
            },
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )
    # Promote together, weights last: a model.pt on disk always has its metadata.
    for name in ("metadata.json", "training_log.json", "model.pt"):
        (out_dir / f"{name}.partial").replace(out_dir / name)


def plan_summary(crop_plan: dict[str, Any], sha256: str | None) -> dict[str, Any]:
    from fixed_time.plan import PLAN_FILE

    return {
        "file": PLAN_FILE,
        "sha256": sha256,
        "songLists": crop_plan["songLists"],
        "keptSongs": crop_plan["keptSongs"],
        "skippedSongs": crop_plan["skippedSongs"],
        "rankingRule": crop_plan["rankingRule"],
    }


def preflight(out_dir: Path, subset: int, num_workers: int, legacy_path: Path) -> int:
    from fixed_time import plan as cp

    print(f"[preflight] shape check at [N, {', '.join(map(str, ft.TENSOR_SHAPE[1:]))}]")
    shapes = shape_check()
    print(f"[preflight] ok: {shapes}")

    try:
        guard: dict[str, Any] = {"status": "pass", **run_guard(legacy_path)}
        print("[preflight] recipe guard: pass")
    except RecipeDriftError as e:
        guard = {"status": "refuse", "reason": str(e)}
        print(f"[preflight] recipe guard: THE FULL RUN WOULD REFUSE: {e}")

    # The subset gets its own in-memory crop plan (never written): the full run's
    # plan comes from `make fixed-time-plan`.
    print(f"[preflight] planning crops for {subset} songs per list")
    t0 = time.time()
    subset_plan = cp.make_plan(subset, num_workers)
    plan_seconds = time.time() - t0
    planned_songs = sum(len(v) for v in subset_plan["songs"].values())

    print(f"[preflight] timing one pretraining epoch and one fine-tuning epoch on {subset} songs")
    figures = train(
        crop_plan=subset_plan,
        out_dir=out_dir,
        subset=subset,
        pretrain_epochs=1,
        epochs=1,
        num_workers=num_workers,
        write_artifacts=False,
    )
    full = {name: len(songs) for name, songs in cp.song_lists(None).items()}
    # First-epoch timings include cold decodes; later epochs read the caches when
    # they are configured, so this projection is an upper estimate for those runs.
    per_pretrain_track = figures["pretrainSeconds"] / max(figures["pretrainTracks"], 1)
    per_finetune_track = figures["finetuneSeconds"] / max(
        figures["trainTracks"] + figures["valTracks"], 1
    )
    per_planned_song = plan_seconds / max(planned_songs, 1)
    projected = (
        per_planned_song * sum(full.values())
        + per_pretrain_track * full["pretrain"] * RECIPE["pretrainEpochs"]
        + per_finetune_track * (full["train"] + full["val"]) * RECIPE["epochCount"]
    )
    report = {
        "runKind": RUN_KIND,
        "shapeCheck": shapes,
        "recipeGuard": guard,
        "corpusDrift": guard.get("corpusDrift"),
        "subsetTracks": subset,
        "subsetPlan": {
            "keptSongs": subset_plan["keptSongs"],
            "skippedSongs": subset_plan["skippedSongs"],
        },
        "device": figures["device"],
        "planSecondsOnSubset": plan_seconds,
        "pretrainEpochSecondsOnSubset": figures["pretrainSeconds"],
        "finetuneEpochSecondsOnSubset": figures["finetuneSeconds"],
        "fullSongLists": full,
        "projectedFullRunHours": projected / 3600.0,
        "projectionNote": (
            "per-song subset times scaled to planning every song once plus 30 pretraining and "
            "60 fine-tuning epochs; cold decodes make it an upper estimate when the PCM and "
            "feature caches are set"
        ),
    }
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "preflight.json").write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print(
        f"[preflight] projected full run: {projected / 3600.0:.1f} h "
        f"({full['pretrain']} pretraining songs x {RECIPE['pretrainEpochs']} epochs, "
        f"{full['train']}+{full['val']} labelled songs x {RECIPE['epochCount']} epochs) "
        f"-> {out_dir / 'preflight.json'}"
    )
    return 0


# What the trainer writes to a run directory. `--overwrite` moves these, and only
# these, aside; the crop plan and anything else in the directory stay put.
RUN_FILES = ("model.pt", "metadata.json", "training_log.json", "checkpoints")


def archive_previous_run(out_dir: Path) -> Path | None:
    """Move the previous run's files into `out_dir/_archive/<UTC timestamp>/`.

    Moving instead of deleting keeps the completed run until its replacement
    finishes, and leaves the run directory with no model.pt, so an interrupted
    replacement run resumes from its own checkpoints on a plain rerun. Returns
    the archive folder, or None when there was nothing to move."""
    present = [n for n in RUN_FILES if (out_dir / n).exists()]
    if not present:
        return None
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    archive = out_dir / "_archive" / stamp
    archive.mkdir(parents=True, exist_ok=False)
    for name in present:
        shutil.move(str(out_dir / name), str(archive / name))
    print(f"[fixed-time] moved the previous run's {', '.join(present)} to {archive}")
    return archive


def full_run(out_dir: Path, num_workers: int, legacy_path: Path, overwrite: bool) -> int:
    from fixed_time.plan import PlanError

    try:
        guard = run_guard(legacy_path)
    except RecipeDriftError as e:
        print(f"ERROR: training refused. {e}", file=sys.stderr)
        return 3
    try:
        crop_plan, plan_sha = read_plan(out_dir)
    except PlanError as e:
        print(f"ERROR: training refused. {e}", file=sys.stderr)
        return 3
    from fixed_time.checkpoints import CheckpointMismatch, CheckpointStore

    existing = [n for n in ("model.pt", "metadata.json") if (out_dir / n).exists()]
    if existing and not overwrite:
        print(
            f"ERROR: {existing} exist in {out_dir}; pass --overwrite to archive them "
            "and start a new run.",
            file=sys.stderr,
        )
        return 2
    if overwrite:
        archive_previous_run(out_dir)
    store = CheckpointStore(out_dir, plan_sha256=plan_sha, recipe=RECIPE)
    if not overwrite:
        try:
            store.resume_point()  # refuse a mismatched checkpoint before any work
        except CheckpointMismatch as e:
            print(f"ERROR: training refused. {e}", file=sys.stderr)
            return 3
    figures = train(
        crop_plan=crop_plan,
        out_dir=out_dir,
        subset=None,
        pretrain_epochs=RECIPE["pretrainEpochs"],
        epochs=RECIPE["epochCount"],
        num_workers=num_workers,
        write_artifacts=True,
        checkpoints=store,
    )
    write_run_artifacts(out_dir, guard, figures, plan_summary(crop_plan, plan_sha))
    print(f"[fixed-time] done -> {out_dir}")
    return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Train the fixed-time variant with the legacy recipe (Story 15.5)."
    )
    p.add_argument("--preflight", action="store_true", help="shape check + timed one-epoch subset")
    p.add_argument("--preflight-subset", type=int, default=32)
    p.add_argument("--num-workers", type=int, default=4)
    p.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    p.add_argument("--legacy-metadata", type=Path, default=LEGACY_METADATA)
    p.add_argument(
        "--overwrite",
        action="store_true",
        help="move the previous run to <out-dir>/_archive/<UTC time>/ and start fresh",
    )
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])
    if args.preflight:
        return preflight(
            args.out_dir, args.preflight_subset, args.num_workers, args.legacy_metadata
        )
    return full_run(args.out_dir, args.num_workers, args.legacy_metadata, args.overwrite)


if __name__ == "__main__":
    sys.exit(main())
