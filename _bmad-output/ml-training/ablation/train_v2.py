"""Substrate-bound v2 training runner — Story 7.5 full-run wiring (Epic 7 close-out).

Develop-only. This is the SHARED recipe module the authoritative ``train.py``
delegates to (after its KDD-B4 ``check_substrate_preconditions`` gate). It trains
the KDD-B2 winner ``maskedMelPretrain`` — and the FR-24 runner-up
``supervisedAugmented`` — on the Tony Strong+Solid split using the v2 substrate
feature path (``feature_substrate_v2`` via ``feature_path="v2"``), so the model
trains on the exact tensor ``BNNSTechnique`` infers on (FR-21 train/runtime
parity).

Two entry points:
  - ``run_v2(...)`` — the recipe. ``promotable=True`` writes the authoritative
    per-seed metadata (``train_v2_artifacts.build_seed_metadata``); the caller
    (``train.py``) owns the ``giantsteps_v2_seed_*`` naming + the KDD-B4 gate.
  - ``main()`` — the SMOKE CLI. Runs WITHOUT the KDD-B4 gate (pre-signoff dev
    verification), writes NON-promotable artifacts to ``ablation/v2-smoke/<variant>/``
    (``promotable:false`` + ``smoke:true``, NEVER a ``giantsteps_v2_seed_*`` name)
    so a smoke run can never be mistaken for an authoritative checkpoint.

Run smoke: ``python ablation/train_v2.py --variant maskedMelPretrain \
    --epochs 1 --pretrain-epochs 1 --subset 8 --weighting-profile uniform``
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

ML_TRAINING_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ML_TRAINING_DIR)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import torch  # noqa: E402
from torch.utils.data import DataLoader  # noqa: E402

import ablation_common as common  # noqa: E402
import dataset as ds  # noqa: E402
import masked_mel  # noqa: E402
import train_v2_artifacts as tv2  # noqa: E402
from ablation_locator import (  # noqa: E402
    UnlabeledPretrainDataset,
    build_pretrain_audio_paths,
)
from ablation_train import finetune  # noqa: E402
from model import build_reference_model  # noqa: E402

VARIANTS = ("maskedMelPretrain", "supervisedAugmented")
SMOKE_ROOT = common.ABLATION_DIR / "v2-smoke"
CORPUS_SPLITS = common.CORPUS_SPLITS


def run_v2(
    *,
    variant: str,
    seed: int,
    epochs: int,
    pretrain_epochs: int,
    batch_size: int,
    lr: float,
    weighting_profile: str,
    subset: int | None,
    num_workers: int,
    octave_mass: float,
    label_smoothing: float,
    mask_ratio: float,
    mask_span: int,
    device,
    out_dir: Path,
    promotable: bool,
    smoke: bool,
) -> dict:
    """Train one v2 arm and write ``model.pt`` + ``model_metadata.json`` +
    ``training_log.json`` to ``out_dir``. Returns the metadata dict."""
    if variant not in VARIANTS:
        raise ValueError(f"variant must be one of {VARIANTS}; got {variant!r}")
    if weighting_profile != "uniform":
        # Guardrail 3 / DD #6: the v2 substrate has no sub-band-emphasis path.
        raise ValueError("v2 substrate run requires --weighting-profile uniform")

    fixture = ds.load_fixture(ds.FIXTURE_PATH)
    model = build_reference_model()
    start = time.time()

    pretrain_used = 0
    if variant == "maskedMelPretrain":
        pretrain_paths = build_pretrain_audio_paths()
        if subset:
            pretrain_paths = pretrain_paths[:subset]
        if len(pretrain_paths) == 0:
            raise RuntimeError(
                "Empty masked-mel pretrain corpus (0 paths); refusing to ship a "
                "'maskedMelPretrain' model with a random-init encoder. Check the "
                "survey/manifests + TONY_AUDIO_ROOT."
            )
        print(f"[train_v2:{variant}] pretrain corpus: {len(pretrain_paths)} label-free tracks")
        pretrain_set = UnlabeledPretrainDataset(
            pretrain_paths,
            fixture,
            seed=seed,
            weighting_profile=weighting_profile,
            feature_path="v2",
        )
        g_pre = torch.Generator()
        g_pre.manual_seed(seed)
        pretrain_loader = DataLoader(
            pretrain_set,
            batch_size=batch_size,
            shuffle=True,
            num_workers=num_workers,
            worker_init_fn=ds.worker_init_fn,
            generator=g_pre,
        )
        masked_mel.pretrain_encoder(
            model,
            pretrain_loader,
            epochs=pretrain_epochs,
            device=device,
            seed=seed,
            mask_ratio=mask_ratio,
            span=mask_span,
        )
        pretrain_used = pretrain_epochs

    # Supervised fine-tune (identical loop both arms; encoder init is the only
    # headline difference — random for supervisedAugmented, masked-mel-pretrained
    # for maskedMelPretrain) on the v2 substrate feature path.
    result = finetune(
        model,
        epochs=epochs,
        batch_size=batch_size,
        lr=lr,
        seed=seed,
        weighting_profile=weighting_profile,
        subset=subset,
        device=device,
        octave_mass=octave_mass,
        label_smoothing=label_smoothing,
        num_workers=num_workers,
        feature_path="v2",
    )
    wall = time.time() - start

    out_dir.mkdir(parents=True, exist_ok=True)
    torch.save(model.state_dict(), out_dir / "model.pt")

    if promotable:
        splits = json.loads(CORPUS_SPLITS.read_text())
        metadata = tv2.build_seed_metadata(
            seed=seed,
            epoch_count=result.epoch_count,
            weighting_profile=weighting_profile,
            corpus_version_hash=common.compute_corpus_version_hash(),
            split_version_hash=tv2.compute_split_version_hash(splits),
            harness_git_sha=common.harness_git_sha(),
            variant=variant,
        )
    else:
        # Smoke / non-authoritative: NEVER promotable, explicitly flagged so it
        # can't be confused with an authoritative giantsteps_v2_seed_* checkpoint.
        metadata = {
            "metadataSchema": "train-v2-smoke",
            "architecture": "TempoCNN",
            "trainingVariant": variant,
            "weightingProfile": weighting_profile,
            "featureSetVersion": tv2.FEATURE_SET_VERSION,
            "modelGeneration": tv2.MODEL_GENERATION,
            "seed": seed,
            "epochCount": result.epoch_count,
            "promotable": False,
            "smoke": True,
            "harnessGitSha": common.harness_git_sha(),
            "_note": "v2 substrate SMOKE run (Phase 1 verification) — not an authoritative checkpoint.",
        }
    if variant == "maskedMelPretrain":
        metadata["pretrainEpochs"] = pretrain_used
        metadata["maskRatio"] = mask_ratio
    (out_dir / "model_metadata.json").write_text(
        json.dumps(metadata, indent=2, sort_keys=True) + "\n"
    )
    (out_dir / "training_log.json").write_text(
        json.dumps(
            {
                "variant": variant,
                "featureSetVersion": tv2.FEATURE_SET_VERSION,
                "smoke": smoke,
                "val_acc1": result.val_acc1,
                "best_val_acc1": result.best_val_acc1,
                "pretrain_epochs": pretrain_used,
                "wall_clock_seconds": wall,
                "per_epoch": result.per_epoch,
                "mpsReproducibilityNote": (
                    "PyTorch MPS is not bit-reproducible across macOS minor versions; "
                    "seed pins shuffle order + init, not bitwise outputs."
                ),
            },
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )
    print(
        f"[train_v2:{variant}] done | val_acc1 {result.val_acc1:.3f} | "
        f"best {result.best_val_acc1:.3f} | wall {wall:.1f}s | promotable={promotable} | wrote {out_dir}"
    )
    return metadata


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="v2 substrate training SMOKE runner (no KDD-B4 gate).")
    p.add_argument("--variant", choices=VARIANTS, default="maskedMelPretrain")
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--epochs", type=int, default=1)
    p.add_argument("--pretrain-epochs", type=int, default=1)
    p.add_argument("--batch-size", type=int, default=32)
    p.add_argument("--lr", type=float, default=1e-3)
    p.add_argument("--weighting-profile", type=str, default="uniform")
    p.add_argument("--subset", type=int, default=8, help="first N tracks (CPU/MPS smoke)")
    p.add_argument("--num-workers", type=int, default=0)
    p.add_argument("--octave-mass", type=float, default=0.15)
    p.add_argument("--label-smoothing", type=float, default=0.05)
    p.add_argument("--mask-ratio", type=float, default=masked_mel.DEFAULT_MASK_RATIO)
    p.add_argument("--mask-span", type=int, default=masked_mel.DEFAULT_SPAN)
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    """SMOKE CLI: runs WITHOUT the KDD-B4 gate, writes non-promotable artifacts to
    ablation/v2-smoke/<variant>/. The authoritative gated path is train.py."""
    args = parse_args(argv if argv is not None else sys.argv[1:])
    common.set_seeds(args.seed)
    device = common.require_mps_or_subset(args.subset)
    out_dir = SMOKE_ROOT / args.variant
    print(f"[train_v2 SMOKE] variant={args.variant} device={device} out={out_dir}")
    run_v2(
        variant=args.variant,
        seed=args.seed,
        epochs=args.epochs,
        pretrain_epochs=args.pretrain_epochs,
        batch_size=args.batch_size,
        lr=args.lr,
        weighting_profile=args.weighting_profile,
        subset=args.subset,
        num_workers=args.num_workers,
        octave_mass=args.octave_mass,
        label_smoothing=args.label_smoothing,
        mask_ratio=args.mask_ratio,
        mask_span=args.mask_span,
        device=device,
        out_dir=out_dir,
        promotable=False,
        smoke=True,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
