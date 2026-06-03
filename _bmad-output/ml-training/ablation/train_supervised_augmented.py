"""KDD-B2 ablation arm A: supervisedAugmented (random init -> supervised fine-tune).

Story 7.3 / AC1 / AC3 / AC4 / AC10. Develop-only v1 scaffolding.

Random-init supervised training on the Tony strong-only split (tony.train/val)
with octave-aware loss (FR-16) + the identical augmentation set as the masked-mel
arm (DD #5/#12). Guardrail 3: `--weighting-profile` is REQUIRED. Guardrail 1:
metadata carries `promotable: false` + the scaffolding note.

Run: `make ablation-supervised`  (smoke: `--epochs 1 --subset 32`).
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

import ablation_common as common  # noqa: E402
from ablation_features import WEIGHTING_PROFILES  # noqa: E402
from ablation_train import finetune  # noqa: E402
from model import build_reference_model  # noqa: E402

VARIANT = "supervisedAugmented"
VARIANT_DIR = common.ABLATION_DIR / VARIANT


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--epochs", type=int, default=60, help="shared fine-tune budget (DD #12)")
    p.add_argument("--batch-size", type=int, default=32)
    p.add_argument("--lr", type=float, default=1e-3)
    # Guardrail 3: declared profile. NOT `required=True` so we can raise the
    # AC3-specified ValueError (argparse would SystemExit instead).
    p.add_argument(
        "--weighting-profile", type=str, default=None, choices=[*WEIGHTING_PROFILES, None]
    )
    p.add_argument("--subset", type=int, default=None, help="first N train tracks (CPU smoke)")
    p.add_argument("--num-workers", type=int, default=4, help="DataLoader workers (overlap decode)")
    p.add_argument("--octave-mass", type=float, default=0.15)
    p.add_argument("--label-smoothing", type=float, default=0.05)
    p.add_argument(
        "--random-split",
        action="store_true",
        help="DD #6 run B: train on the artist-blind random split + write run_b_random_split.json",
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
    print(f"[supervisedAugmented] device={device} weighting={args.weighting_profile}")

    model = build_reference_model()

    if args.random_split:
        # DD #6 run B — random-init model on the artist-blind random split.
        from ablation_train import run_random_split

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

    start = time.time()
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

    import torch

    VARIANT_DIR.mkdir(parents=True, exist_ok=True)
    torch.save(model.state_dict(), VARIANT_DIR / "model.pt")
    metadata = common.build_metadata(
        variant=VARIANT,
        seed=args.seed,
        epoch_count=result.epoch_count,
        weighting_profile=args.weighting_profile,
    )
    common.write_metadata(VARIANT_DIR, metadata)
    (VARIANT_DIR / "training_log.json").write_text(
        json.dumps(
            {
                "variant": VARIANT,
                "val_acc1": result.val_acc1,
                "best_val_acc1": result.best_val_acc1,
                "wall_clock_seconds": wall,
                "per_epoch": result.per_epoch,
            },
            indent=2,
            sort_keys=True,
        )
    )
    print(
        f"[supervisedAugmented] done | val_acc1 {result.val_acc1:.3f} | "
        f"best {result.best_val_acc1:.3f} | wall {wall:.1f}s | wrote {VARIANT_DIR}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
