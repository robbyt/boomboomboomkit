"""KDD-B2 ablation arm B: maskedMelPretrain (masked-mel pretrain -> fine-tune).

Story 7.3 / AC1 / AC3 / AC4 / AC9 / AC10 / DD #13. Develop-only v1 scaffolding.

Masked-mel self-supervised pretraining of the TempoCNN conv encoder on label-free
train-side audio (tony.train strong + secondarySupervised + unsupervisedPool,
EXCLUDING val/LAO/sentinel/eval-leak per DD #12), then supervised fine-tune on the
IDENTICAL strong-only set + identical augmentation as arm A (DD #12 — only the
encoder init differs). Guardrail 3: `--weighting-profile` REQUIRED. Guardrail 1:
`promotable: false`.

Run: `make ablation-masked-mel`  (smoke: `--epochs 1 --pretrain-epochs 1 --subset 32`).
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time

ML_TRAINING_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ML_TRAINING_DIR)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import torch  # noqa: E402
from torch.utils.data import DataLoader  # noqa: E402

import ablation_common as common  # noqa: E402
import dataset as ds  # noqa: E402
import masked_mel  # noqa: E402
from ablation_features import WEIGHTING_PROFILES  # noqa: E402
from ablation_locator import (  # noqa: E402
    UnlabeledPretrainDataset,
    build_pretrain_audio_paths,
    build_random_split_records,
)
from ablation_train import finetune, run_random_split  # noqa: E402
from model import build_reference_model  # noqa: E402

VARIANT = "maskedMelPretrain"
VARIANT_DIR = common.ABLATION_DIR / VARIANT


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--epochs", type=int, default=60, help="shared fine-tune budget (DD #12)")
    p.add_argument("--pretrain-epochs", type=int, default=30, help="separate budget (DD #13)")
    p.add_argument("--batch-size", type=int, default=32)
    p.add_argument("--lr", type=float, default=1e-3)
    p.add_argument("--mask-ratio", type=float, default=masked_mel.DEFAULT_MASK_RATIO)
    p.add_argument("--mask-span", type=int, default=masked_mel.DEFAULT_SPAN)
    p.add_argument(
        "--weighting-profile", type=str, default=None, choices=[*WEIGHTING_PROFILES, None]
    )
    p.add_argument("--subset", type=int, default=None, help="first N tracks (CPU smoke)")
    p.add_argument("--num-workers", type=int, default=4, help="DataLoader workers (overlap decode)")
    p.add_argument("--octave-mass", type=float, default=0.15)
    p.add_argument("--label-smoothing", type=float, default=0.05)
    p.add_argument(
        "--random-split",
        action="store_true",
        help="DD #6 run B: pretrain, then fine-tune on the artist-blind random split + "
        "write run_b_random_split.json",
    )
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])
    if args.weighting_profile is None:
        raise ValueError(
            "Guardrail 3 (AC3): --weighting-profile {uniform|sub-band-emphasis} must be "
            "passed explicitly (the declared profile is encoded in model_metadata.json)."
        )
    common.set_seeds(args.seed)
    device = common.require_mps_or_subset(args.subset)
    print(f"[maskedMelPretrain] device={device} weighting={args.weighting_profile}")

    # --- Phase 1: masked-mel self-supervised pretraining (label-free) ---
    fixture = ds.load_fixture(ds.FIXTURE_PATH)
    pretrain_paths = build_pretrain_audio_paths()
    if args.random_split:
        # Run B: exclude the run-B random held-out from the pretrain corpus so the
        # masked-mel arm does NOT self-supervise on its own eval set (cycle-2:
        # otherwise ~80% of the random held-out, drawn from tony.train, leaks into
        # pretraining — asymmetric vs the supervised arm, which never pretrains).
        _, heldout_recs, _ = build_random_split_records()
        heldout = {r.audio_path.resolve() for r in heldout_recs}
        before = len(pretrain_paths)
        pretrain_paths = [p for p in pretrain_paths if p.resolve() not in heldout]
        print(
            f"[maskedMelPretrain] run-B: excluded {before - len(pretrain_paths)} held-out from pretrain"
        )
    if args.subset:
        pretrain_paths = pretrain_paths[: args.subset]
    print(f"[maskedMelPretrain] pretrain corpus: {len(pretrain_paths)} label-free tracks")
    # Loud-fail on an empty pretrain corpus — otherwise the encoder stays at random
    # init and the "masked-mel" arm silently degenerates into a second copy of
    # supervisedAugmented while metadata still claims pretrainEpochs (DD #12). (Lazy
    # decode now skips per-track failures; an all-failed corpus raises in the dataset.)
    if len(pretrain_paths) == 0:
        raise RuntimeError(
            "Empty masked-mel pretrain corpus (0 paths); refusing to ship a "
            "'maskedMelPretrain' model with a random-init encoder. Check the "
            "survey/manifests + TONY_AUDIO_ROOT."
        )
    pretrain_set = UnlabeledPretrainDataset(
        pretrain_paths, fixture, seed=args.seed, weighting_profile=args.weighting_profile
    )
    g_pre = torch.Generator()
    g_pre.manual_seed(args.seed)
    pretrain_loader = DataLoader(
        pretrain_set,
        batch_size=args.batch_size,
        shuffle=True,
        num_workers=args.num_workers,
        worker_init_fn=ds.worker_init_fn,
        generator=g_pre,
    )

    model = build_reference_model()
    start = time.time()
    masked_mel.pretrain_encoder(
        model,
        pretrain_loader,
        epochs=args.pretrain_epochs,
        device=device,
        seed=args.seed,
        mask_ratio=args.mask_ratio,
        span=args.mask_span,
    )

    if args.random_split:
        # DD #6 run B — fine-tune the pretrained encoder on the artist-blind random
        # split. The run-B random held-out was already excluded from the pretrain
        # corpus above (no self-supervised leakage onto its own eval set).
        run_random_split(
            model,
            variant=VARIANT,
            seed=args.seed,
            epochs=args.epochs,
            batch_size=args.batch_size,
            lr=args.lr,
            weighting_profile=args.weighting_profile,
            subset=args.subset,
            device=device,
            octave_mass=args.octave_mass,
            label_smoothing=args.label_smoothing,
            num_workers=args.num_workers,
        )
        return 0

    # --- Phase 2: supervised fine-tune (same set/aug as arm A; encoder warm-started) ---
    result = finetune(
        model,
        epochs=args.epochs,
        batch_size=args.batch_size,
        lr=args.lr,
        seed=args.seed,
        weighting_profile=args.weighting_profile,
        subset=args.subset,
        device=device,
        octave_mass=args.octave_mass,
        label_smoothing=args.label_smoothing,
        num_workers=args.num_workers,
    )
    wall = time.time() - start

    VARIANT_DIR.mkdir(parents=True, exist_ok=True)
    torch.save(model.state_dict(), VARIANT_DIR / "model.pt")
    metadata = common.build_metadata(
        variant=VARIANT,
        seed=args.seed,
        epoch_count=result.epoch_count,
        weighting_profile=args.weighting_profile,
        pretrain_epochs=args.pretrain_epochs,
        mask_ratio=args.mask_ratio,
    )
    common.write_metadata(VARIANT_DIR, metadata)
    (VARIANT_DIR / "training_log.json").write_text(
        json.dumps(
            {
                "variant": VARIANT,
                "val_acc1": result.val_acc1,
                "best_val_acc1": result.best_val_acc1,
                "pretrain_epochs": args.pretrain_epochs,
                "mask_ratio": args.mask_ratio,
                "wall_clock_seconds": wall,
                "per_epoch": result.per_epoch,
            },
            indent=2,
            sort_keys=True,
        )
    )
    print(
        f"[maskedMelPretrain] done | val_acc1 {result.val_acc1:.3f} | "
        f"best {result.best_val_acc1:.3f} | wall {wall:.1f}s | wrote {VARIANT_DIR}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
