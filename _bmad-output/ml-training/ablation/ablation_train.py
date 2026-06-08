"""Shared supervised fine-tune loop for the KDD-B2 ablation arms.

Story 7.3. Develop-only v1 scaffolding.

Both arms (supervisedAugmented, maskedMelPretrain) call `finetune(...)` on the
IDENTICAL strong-only labeled set with the IDENTICAL augmentation, head,
optimizer, LR schedule, batch size, epoch budget, and paired seeds (DD #12
confound-lock). The ONLY headline difference is the encoder init (`model` is
random for supervisedAugmented; masked-mel-pretrained for maskedMelPretrain).
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass, field
from typing import Any

import torch
import torch.nn as nn
from torch.utils.data import DataLoader, WeightedRandomSampler

import ablation_common as common
import dataset as ds
from ablation_locator import (
    LabeledTonyDataset,
    build_labeled_records,
    build_random_split_records,
)
from octave_aware_loss import octave_aware_loss

sys.path.insert(0, str(common.ML_TRAINING_DIR))


@dataclass
class FinetuneResult:
    val_acc1: float
    best_val_acc1: float
    epoch_count: int
    per_epoch: list[dict[str, Any]] = field(default_factory=list)


def _subset(records: list, subset: int | None) -> list:
    return records[:subset] if subset else records


# GiantSteps tempo-band priors (the bundle gate's distribution, n=661) — the
# target the rebalanced sampler matches so the model stops over-predicting the
# DnB tempos the Tony corpus is glutted with (Epic 7 data-augmentation: Tony is
# 51% 160-175 BPM, GiantSteps only 23%; GiantSteps is 47% 120-140, Tony ~15%).
_GS_BAND_PRIORS = {
    "<100": 0.0908,
    "100-120": 0.0530,
    "120-140": 0.4675,
    "140-160": 0.1331,
    "160-175": 0.2315,
    "175+": 0.0242,
}
# Clamp the per-track weight so the few under-represented tracks aren't oversampled
# to the point of memorization (Codex: rebalancing cannot invent examples).
_REBALANCE_CLAMP = (0.33, 3.0)


def _tempo_band(bpm: float) -> str:
    if bpm < 100:
        return "<100"
    if bpm < 120:
        return "100-120"
    if bpm < 140:
        return "120-140"
    if bpm < 160:
        return "140-160"
    if bpm < 175:
        return "160-175"
    return "175+"


def _rebalance_weights(records) -> list[float]:
    """Per-track WeightedRandomSampler weights = clamp(GS_frac / corpus_frac): the
    effective training distribution approaches the GiantSteps gate's tempo bands
    (down-weight the DnB glut, up-weight house/techno)."""
    from collections import Counter

    bands = [_tempo_band(float(r.bpm)) for r in records]
    counts = Counter(bands)
    n = max(len(records), 1)
    lo, hi = _REBALANCE_CLAMP
    weights: list[float] = []
    for b in bands:
        src_frac = counts[b] / n
        tgt_frac = _GS_BAND_PRIORS.get(b, src_frac)
        w = (tgt_frac / src_frac) if src_frac > 0 else 1.0
        weights.append(min(hi, max(lo, w)))
    print(f"[finetune] rebalance band counts (raw): {dict(counts)}")
    return weights


def finetune(
    model: nn.Module,
    *,
    epochs: int,
    batch_size: int,
    lr: float,
    seed: int,
    weighting_profile: str,
    subset: int | None,
    device: torch.device,
    octave_mass: float = 0.15,
    label_smoothing: float = 0.05,
    num_workers: int = 4,
    train_records=None,
    val_records=None,
    feature_path: str = "v1",
    rebalance: bool = False,
) -> FinetuneResult:
    """Supervised fine-tune on Tony strong-only (tony.train/tony.val). Returns the
    final + best val Acc1 (4% relative) and a per-epoch log."""
    fixture = ds.load_fixture(ds.FIXTURE_PATH)
    if train_records is None:
        train_records = build_labeled_records("train")
    if val_records is None:
        val_records = build_labeled_records("val")
    train_records = _subset(train_records, subset)
    # In smoke (--subset set) cap val too so preloading the full 92-track val set
    # does not blow the < 2 min smoke budget (AC1). Full runs pass subset=None and
    # keep the full val set as the fixed eval.
    val_records = _subset(val_records, subset)

    train_set = LabeledTonyDataset(
        train_records,
        fixture,
        augment=True,
        seed=seed,
        weighting_profile=weighting_profile,
        feature_path=feature_path,
    )
    # strict=True: val_acc1 drives best-checkpoint selection, so a decode failure must
    # loud-fail rather than silently substitute another track (Copilot PR #26). train_set
    # stays resilient (default strict=False) — one bad track shouldn't kill a 60-epoch run.
    val_set = LabeledTonyDataset(
        val_records,
        fixture,
        augment=False,
        seed=seed,
        weighting_profile=weighting_profile,
        strict=True,
        feature_path=feature_path,
    )
    # Loud-fail if there are no records at all (a silently-untrained model would
    # otherwise write a confident `val_acc1: 0.0`). Per-track decode failures are lazy:
    # train_set skip-and-shifts (resilient, prints a WARN); val_set is strict (loud-fail,
    # no substitution — keeps val_acc1 honest). There is no eager decode-drop count here.
    if len(train_set) == 0 or len(val_set) == 0:
        raise RuntimeError(
            f"Empty dataset (train_records={len(train_set)}, val_records={len(val_set)}); "
            f"refusing to write a silently-untrained model. Check the Tony split + TONY_AUDIO_ROOT."
        )
    # Explicit seed-derived generator so the fine-tune shuffle order is a pure
    # function of `seed`, INDEPENDENT of any global-RNG consumed by a prior phase
    # (e.g. masked-mel pretraining). Without this the two arms' fine-tune batch
    # order diverges purely because arm B pretrained first — a confound DD #12
    # forbids ("attributable to encoder INIT only"). val_loader is shuffle=False.
    g = torch.Generator()
    g.manual_seed(seed)
    if rebalance:
        # Tempo-band rebalancing toward the GiantSteps gate (Epic 7). Mutually
        # exclusive with shuffle — the weighted sampler IS the shuffle. Seeded by
        # the same generator so the draw order stays a pure function of `seed`.
        weights = _rebalance_weights(train_records)
        sampler = WeightedRandomSampler(
            weights, num_samples=len(train_records), replacement=True, generator=g
        )
        train_loader = DataLoader(
            train_set,
            batch_size=batch_size,
            sampler=sampler,
            num_workers=num_workers,
            worker_init_fn=ds.worker_init_fn,
        )
    else:
        train_loader = DataLoader(
            train_set,
            batch_size=batch_size,
            shuffle=True,
            num_workers=num_workers,
            worker_init_fn=ds.worker_init_fn,
            generator=g,
        )
    val_loader = DataLoader(
        val_set,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        worker_init_fn=ds.worker_init_fn,
    )

    model = model.to(device)
    optimizer = torch.optim.Adam(model.parameters(), lr=lr)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=max(epochs, 1))

    best_val = 0.0
    final_val = 0.0
    per_epoch: list[dict[str, Any]] = []
    for epoch in range(epochs):
        model.train()
        for x, y in train_loader:
            x = x.to(device, non_blocking=True)
            # Keep the int64 label tensor on CPU — PyTorch MPS corrupts int64
            # storage on the host<->device round-trip (a Long index read back from
            # mps returns garbage). octave_aware_loss builds the soft targets from
            # CPU `y` and moves only the float targets to the logits device.
            optimizer.zero_grad(set_to_none=True)
            logits = model(x)
            loss = octave_aware_loss(
                logits, y, octave_mass=octave_mass, label_smoothing=label_smoothing
            )
            loss.backward()
            optimizer.step()
        scheduler.step()
        final_val = _evaluate(model, val_loader, device)
        best_val = max(best_val, final_val)
        per_epoch.append({"epoch": epoch, "val_acc1": final_val})
        print(f"[finetune] epoch {epoch:03d} | val_acc1 {final_val:.3f}")

    return FinetuneResult(
        val_acc1=final_val, best_val_acc1=best_val, epoch_count=epochs, per_epoch=per_epoch
    )


@torch.no_grad()
def _evaluate(model: nn.Module, loader: DataLoader, device: torch.device) -> float:
    model.eval()
    preds = []
    trues = []
    for x, y in loader:
        x = x.to(device, non_blocking=True)
        logits = model(x)
        # Move the FLOAT logits to CPU, THEN argmax — keep int64 off MPS (same
        # MPS int64 hazard as the loss path).
        preds.append(logits.detach().cpu().argmax(dim=1))
        trues.append(y)
    if not preds:
        return 0.0
    return common.acc1_4pct(torch.cat(preds), torch.cat(trues))


def run_random_split(
    model: nn.Module,
    *,
    variant: str,
    seed: int,
    epochs: int,
    batch_size: int,
    lr: float,
    weighting_profile: str,
    subset: int | None,
    device: torch.device,
    octave_mass: float = 0.15,
    label_smoothing: float = 0.05,
    num_workers: int = 4,
):
    """DD #6 run B — train `model` (with its arm's init already applied) on the
    artist-BLIND random split and write `{variant}/run_b_random_split.json` with the
    held-out Acc1 + the split SHA (the DD #8 random-split artifact hash). Feeds the
    leave-artist-out-minus-random delta in `compare_kdd_b2`."""
    train_recs, heldout_recs, split_sha = build_random_split_records()
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
        train_records=train_recs,
        val_records=heldout_recs,
    )
    out_dir = common.ABLATION_DIR / variant
    out_dir.mkdir(parents=True, exist_ok=True)
    sidecar = out_dir / "run_b_random_split.json"
    sidecar.write_text(
        json.dumps(
            {
                "acc1": result.val_acc1,
                "splitSha": split_sha,
                "trainingSeed": seed,
                "variant": variant,
                "note": "DD #6 run B (artist-blind random split). The LAO-minus-random "
                "delta is a FLOOR — the pool is already artist-curated.",
            },
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )
    print(f"[run-B random-split] {variant} | held-out Acc1 {result.val_acc1:.3f} | wrote {sidecar}")
    return sidecar, result.val_acc1
