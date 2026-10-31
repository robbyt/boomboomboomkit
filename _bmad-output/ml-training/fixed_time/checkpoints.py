"""Per-epoch checkpoints so a fixed-time training run can resume (Story 15.5).

After every pretraining and fine-tuning epoch the run writes one checkpoint per
phase to `<out-dir>/checkpoints/`, replacing the previous one (temp name, then
rename), plus `pretrain-final.pt` after the last pretraining epoch:

  pretrain-latest.pt   pretrain-final.pt   finetune-latest.pt

A checkpoint holds everything the next epoch depends on: the model weights, the
phase's own state from the loop's `on_epoch_end` hook (pretraining: decoder,
optimizer, masking generator; fine-tuning: optimizer, LR schedule, sampler
generator, best and final validation Acc1, per-epoch log), the pretraining
loader's shuffle generator, the Python / numpy / torch (and MPS) RNG states, the
losses so far, and the crop-plan sha256 and recipe it was trained under.

Resuming restores the weights and the phase state before the loop starts, and
the RNG states at the start of the first resumed epoch, which is where the
uninterrupted run would have the same states (nothing draws from them between
one epoch's end and the next epoch's start). On CPU a resumed run therefore
matches an uninterrupted one exactly; MPS training is not claimed to be
bit-reproducible either way.
"""

from __future__ import annotations

import os
import random
from pathlib import Path
from typing import Any

import numpy as np
import torch

CHECKPOINT_SCHEMA = "fixed-time-checkpoint-v1"
CHECKPOINT_DIR = "checkpoints"
PRETRAIN_LATEST = "pretrain-latest"
PRETRAIN_FINAL = "pretrain-final"
FINETUNE_LATEST = "finetune-latest"
# Most advanced first: the resume point is the first of these that exists.
RESUME_ORDER = (FINETUNE_LATEST, PRETRAIN_FINAL, PRETRAIN_LATEST)


class CheckpointMismatch(RuntimeError):
    """A checkpoint was written under a different crop plan or recipe."""


def capture_rng() -> dict[str, Any]:
    state: dict[str, Any] = {
        "python": random.getstate(),
        "numpy": np.random.get_state(),
        "torch": torch.get_rng_state(),
    }
    if torch.backends.mps.is_available():
        state["mps"] = torch.mps.get_rng_state()
    return state


def restore_rng(state: dict[str, Any]) -> None:
    random.setstate(state["python"])
    np.random.set_state(state["numpy"])
    torch.set_rng_state(state["torch"])
    if "mps" in state and torch.backends.mps.is_available():
        torch.mps.set_rng_state(state["mps"])


def to_cpu(obj: Any) -> Any:
    """Detached CPU copies of every tensor in a nested state."""
    if isinstance(obj, torch.Tensor):
        return obj.detach().to("cpu", copy=True)
    if isinstance(obj, dict):
        return {k: to_cpu(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [to_cpu(v) for v in obj]
    if isinstance(obj, tuple):
        return tuple(to_cpu(v) for v in obj)
    return obj


class CheckpointStore:
    """The checkpoint files of one run directory, bound to its plan and recipe."""

    def __init__(self, out_dir: Path, *, plan_sha256: str, recipe: dict[str, Any]):
        self.dir = Path(out_dir) / CHECKPOINT_DIR
        self.plan_sha256 = plan_sha256
        self.recipe = dict(recipe)

    def path(self, name: str) -> Path:
        return self.dir / f"{name}.pt"

    def save(self, name: str, payload: dict[str, Any]) -> Path:
        self.dir.mkdir(parents=True, exist_ok=True)
        doc = {
            **to_cpu(payload),
            "schema": CHECKPOINT_SCHEMA,
            "cropPlanSha256": self.plan_sha256,
            "recipe": self.recipe,
        }
        final = self.path(name)
        tmp = final.with_name(f"{final.name}.tmp{os.getpid()}")
        torch.save(doc, tmp)
        os.replace(tmp, final)
        return final

    def load(self, name: str) -> dict[str, Any] | None:
        path = self.path(name)
        if not path.is_file():
            return None
        return torch.load(path, map_location="cpu", weights_only=False)

    def resume_point(self) -> tuple[str, dict[str, Any]] | None:
        """The most advanced checkpoint, or None. Raises CheckpointMismatch when any
        checkpoint present was written under another plan, recipe or schema."""
        found: dict[str, dict[str, Any]] = {}
        for name in RESUME_ORDER:
            doc = self.load(name)
            if doc is None:
                continue
            problems = []
            if doc.get("schema") != CHECKPOINT_SCHEMA:
                problems.append(f"schema {doc.get('schema')!r}")
            if doc.get("cropPlanSha256") != self.plan_sha256:
                problems.append(
                    f"crop-plan sha256 {doc.get('cropPlanSha256')}, this run's is "
                    f"{self.plan_sha256}"
                )
            if doc.get("recipe") != self.recipe:
                problems.append(f"recipe {doc.get('recipe')}, this run's is {self.recipe}")
            if problems:
                raise CheckpointMismatch(
                    f"checkpoint {self.path(name)} does not match this run: "
                    + "; ".join(problems)
                    + ". Pass --overwrite to start fresh."
                )
            found[name] = doc
        for name in RESUME_ORDER:
            if name in found:
                return name, found[name]
        return None


class Resumer:
    """Wires a CheckpointStore into the two training loops' hooks.

    `load()` reads the resume point (if any) and restores the model weights.
    `pretrain_hooks(...)` and `finetune_hooks(...)` return the keyword arguments
    for `masked_mel.pretrain_encoder` and `ablation_train.finetune`. The saved RNG
    states are restored once, at the start of the first epoch either loop runs.
    """

    def __init__(self, store: CheckpointStore | None, model, *, pretrain_epochs: int):
        self.store = store
        self.model = model
        self.pretrain_epochs = pretrain_epochs
        self.resumed_from: dict[str, Any] | None = None
        self.skip_pretrain = False
        self.pretrain_start = 0
        self.finetune_start = 0
        self.pretrain_state: dict[str, Any] | None = None
        self.finetune_state: dict[str, Any] | None = None
        self.loader_generator_state: torch.Tensor | None = None
        self.pretrain_losses: list[float] = []
        self.finetune_losses: list[float] = []
        self.pretrain_seconds_before = 0.0
        # Total pretraining time so far. Fine-tuning checkpoints write this, so
        # a run resumed from one still reports the whole pretraining time.
        self.pretrain_seconds = 0.0
        self.finetune_seconds_before = 0.0
        self._pending_rng: dict[str, Any] | None = None

    def load(self) -> dict[str, Any] | None:
        point = self.store.resume_point() if self.store is not None else None
        if point is None:
            return None
        name, doc = point
        self.model.load_state_dict(doc["model"])
        self._pending_rng = doc["rng"]
        self.pretrain_losses = list(doc.get("pretrainLosses", []))
        self.pretrain_seconds_before = float(doc.get("pretrainSeconds", 0.0))
        self.pretrain_seconds = self.pretrain_seconds_before
        if name == FINETUNE_LATEST:
            self.skip_pretrain = True
            self.finetune_start = int(doc["completedEpoch"]) + 1
            self.finetune_state = doc["phaseState"]
            self.finetune_losses = list(doc.get("finetuneLosses", []))
            self.finetune_seconds_before = float(doc.get("finetuneSeconds", 0.0))
        elif name == PRETRAIN_FINAL:
            self.skip_pretrain = True
        else:
            self.pretrain_start = int(doc["completedEpoch"]) + 1
            self.pretrain_state = doc["phaseState"]
            self.loader_generator_state = doc["loaderGenerator"]
        self.resumed_from = {
            "checkpoint": f"{CHECKPOINT_DIR}/{name}.pt",
            "phase": doc["phase"],
            "completedEpoch": int(doc["completedEpoch"]),
        }
        return self.resumed_from

    def _restore_pending_rng(self) -> None:
        if self._pending_rng is not None:
            restore_rng(self._pending_rng)
            self._pending_rng = None

    def pretrain_hooks(self, loader_generator: torch.Generator, on_epoch_start=None) -> dict:
        if self.loader_generator_state is not None:
            loader_generator.set_state(self.loader_generator_state)
        t_start = _now()

        def start(epoch: int) -> None:
            self._restore_pending_rng()
            if on_epoch_start is not None:
                on_epoch_start(epoch)

        def end(epoch: int, state: dict[str, Any]) -> None:
            self.pretrain_losses.append(float(state["loss"]))
            self.pretrain_seconds = self.pretrain_seconds_before + _now() - t_start
            if self.store is None:
                return
            payload = {
                "phase": "pretrain",
                "completedEpoch": epoch,
                "model": self.model.state_dict(),
                "phaseState": state,
                "loaderGenerator": loader_generator.get_state(),
                "rng": capture_rng(),
                "pretrainLosses": list(self.pretrain_losses),
                "pretrainSeconds": self.pretrain_seconds,
            }
            self.store.save(PRETRAIN_LATEST, payload)
            if epoch == self.pretrain_epochs - 1:
                self.store.save(PRETRAIN_FINAL, payload)

        return {
            "start_epoch": self.pretrain_start,
            "resume_state": self.pretrain_state,
            "on_epoch_start": start,
            "on_epoch_end": end,
        }

    def finetune_hooks(self, on_epoch_start=None) -> dict:
        t_start = _now()

        def start(epoch: int) -> None:
            self._restore_pending_rng()
            if on_epoch_start is not None:
                on_epoch_start(epoch)

        def end(epoch: int, state: dict[str, Any]) -> None:
            self.finetune_losses.append(float(state["trainLoss"]))
            if self.store is None:
                return
            self.store.save(
                FINETUNE_LATEST,
                {
                    "phase": "finetune",
                    "completedEpoch": epoch,
                    "model": self.model.state_dict(),
                    "phaseState": state,
                    "rng": capture_rng(),
                    "pretrainLosses": list(self.pretrain_losses),
                    "pretrainSeconds": self.pretrain_seconds,
                    "finetuneLosses": list(self.finetune_losses),
                    "finetuneSeconds": self.finetune_seconds_before + _now() - t_start,
                },
            )

        return {
            "start_epoch": self.finetune_start,
            "resume_state": self.finetune_state,
            "on_epoch_start": start,
            "on_epoch_end": end,
        }


def _now() -> float:
    import time

    return time.time()
