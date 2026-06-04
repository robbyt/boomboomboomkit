"""
Story 4-4b Task 5 — training loop on M5 Max + MPS.

Adam + cosine LR; CE loss with label smoothing 0.1; on-PCM data augmentation
per DD #10 (time-shift, tempo-stretch ±4% with corrected `bpm * rate` label,
gain ±6 dB, pink noise SNR 30-50 dB).

Reproducibility per AC #7 — seeds + `torch.use_deterministic_algorithms(True,
warn_only=True)` + PYTORCH_ENABLE_MPS_FALLBACK=1. PyTorch MPS does not
guarantee bit-reproducibility across macOS minor versions; the held-out OA300
sanity HALT (DD #11) is the regression-protection contract.

Runtime budget per AC #8:
  Smoke: `--epochs 1 --subset 32` must complete < 2 min
  Full:  60 epochs ≤ 6 h wall-clock HALT ceiling (stretch < 2 h)

PCM caching: tracks' decoded audio is loaded once into RAM (~few GB on the
GiantSteps train set) and re-used across epochs — DD #10 augmentation is
applied to the cached PCM, NOT to cached features (cached log-mel breaks
augmentation semantically).
"""

from __future__ import annotations

import argparse
import json
import os
import random
import re
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import DataLoader, Dataset
from tqdm import tqdm

# Local imports
from dataset import (
    BPM_BIN_COUNT,
    BPM_BIN_MAX,
    BPM_BIN_MIN,
    FIXTURE_PATH,
    SAMPLE_RATE,
    TARGET_FRAMES,
    TrackRecord,
    augment_pcm,
    build_splits,
    extract_log_mel,
    load_fixture,
    sample_window,
    worker_init_fn,
    zscore_per_band,
)
from model import build_reference_model, verify_param_budget

ML_TRAINING_DIR = Path(__file__).resolve().parent
CHECKPOINTS_DIR = ML_TRAINING_DIR / "checkpoints"
TRAINING_LOG_PATH = ML_TRAINING_DIR / "training_log.json"
MODEL_PATH = ML_TRAINING_DIR / "model.pt"


# ---------------------------------------------------------------------------
# In-memory cached dataset (PCM-cached for throughput)
# ---------------------------------------------------------------------------


class CachedTempoDataset(Dataset):
    """Like TempoDataset but caches decoded PCM in RAM after first read.

    Uses librosa.load on first __getitem__ for each record; later epochs hit
    the cache. Augmentation runs on the cached PCM each epoch (DD #10).
    """

    def __init__(
        self,
        records: list[TrackRecord],
        fixture,
        augment: bool,
        seed: int = 42,
        preload: bool = True,
    ):
        self.records = records
        self.fixture = fixture
        self.augment = augment
        self._base_seed = seed
        self._pcm_cache: dict[int, np.ndarray] = {}
        self._failed: set[int] = set()
        # Epoch counter — bumped via `set_epoch(...)` between epochs in the
        # train loop. Mixed into _make_rng so augmentation varies per epoch
        # at fixed seed (without leaking PID).
        self._epoch: int = 0
        if preload:
            self._preload_all()

    def set_epoch(self, epoch: int) -> None:
        """Called by the train loop between epochs to advance augmentation RNG."""
        self._epoch = int(epoch)

    def imports_for_dataset(self) -> None:
        """Re-emit BPM_BIN_MAX/MIN constants so test/dev tooling can reach them."""
        # No-op kept for documentation: BPM_BIN_MAX / BPM_BIN_MIN are imported
        # at module top from `dataset`, accessible to consumers.
        pass

    def _preload_all(self) -> None:
        import librosa

        for i, r in enumerate(tqdm(self.records, desc="Preload PCM", leave=False)):
            try:
                audio, _ = librosa.load(
                    str(r.audio_path), sr=SAMPLE_RATE, mono=True, res_type="soxr_hq"
                )
                self._pcm_cache[i] = audio.astype(np.float32)
            except Exception as e:
                # Was: substitute 5s of zeros and KEEP the original BPM label —
                # silently injects label noise. Now: track the failure and
                # exclude the index from __len__ via _failed set.
                print(f"WARN: failed to load {r.audio_path}: {e}", file=sys.stderr)
                self._failed.add(i)

    def __len__(self) -> int:
        return len(self.records) - len(self._failed)

    def _idx_to_record(self, idx: int) -> int:
        """Map a 0..len-1 index past failed records (skip-and-shift)."""
        if not self._failed:
            return idx
        # Walk forward past any failed indices.
        for i in range(len(self.records)):
            if i in self._failed:
                continue
            if idx == 0:
                return i
            idx -= 1
        raise IndexError(f"idx {idx} out of bounds in CachedTempoDataset")

    def _make_rng(self, idx: int, epoch: int = 0) -> random.Random:
        # Per-call seed is `(base_seed, idx, epoch)` — explicitly does NOT mix
        # `os.getpid()` (was a determinism hole: pid varies across shell
        # sessions, breaking same-seed reproducibility). The epoch counter
        # gives augmentation variation across epochs while staying
        # reproducible at fixed seed + idx + epoch.
        return random.Random((self._base_seed * 1_000_003 + idx) * 1_000_003 + epoch)

    def __getitem__(self, idx: int) -> tuple[torch.Tensor, int]:
        real_idx = self._idx_to_record(idx)
        record = self.records[real_idx]
        rng = self._make_rng(real_idx, self._epoch)

        if real_idx in self._pcm_cache:
            audio = self._pcm_cache[real_idx].copy()
        else:
            import librosa

            try:
                audio, _ = librosa.load(
                    str(record.audio_path), sr=SAMPLE_RATE, mono=True, res_type="soxr_hq"
                )
            except Exception as e:
                # Lazy-path failure: drop from len + skip. Mirror preload-path.
                print(f"WARN: failed to load {record.audio_path}: {e}", file=sys.stderr)
                self._failed.add(real_idx)
                # Recurse to next valid item; bounded by len(records).
                if len(self) == 0:
                    raise RuntimeError("All records failed to load") from e
                return self.__getitem__(idx % max(len(self), 1))
            audio = audio.astype(np.float32)
            self._pcm_cache[real_idx] = audio.copy()

        bpm = record.bpm
        if self.augment:
            stretch_safe_ceiling = BPM_BIN_MAX / 1.04
            audio, bpm = augment_pcm(
                audio,
                bpm,
                rng,
                sr=SAMPLE_RATE,
                allow_stretch=(bpm <= stretch_safe_ceiling),
            )

        log_mel_t = extract_log_mel(audio, self.fixture)  # (n_mels, T)
        log_mel_t = sample_window(log_mel_t, TARGET_FRAMES, rng=rng, training=self.augment)
        z = zscore_per_band(log_mel_t)

        bin_idx = max(0, min(BPM_BIN_COUNT - 1, int(round(bpm)) - BPM_BIN_MIN))
        return torch.from_numpy(z).unsqueeze(0), bin_idx


# ---------------------------------------------------------------------------
# Determinism / env
# ---------------------------------------------------------------------------


def set_seeds(seed: int) -> None:
    """Per AC #7 determinism block.

    `PYTHONHASHSEED` env var must be set BEFORE the Python interpreter starts
    to actually pin hash randomization (per Python docs). Setting it inside
    a running process is a no-op for hash randomization. Therefore this
    function:
      1. Records what the user wants in os.environ (informational only).
      2. WARNS to stderr if the env var wasn't pre-set OR doesn't match.
    Callers wanting true hash determinism must invoke train.py via a wrapper
    that sets the env, e.g.:
        PYTHONHASHSEED=42 uv run python train.py --seed 42
    """
    expected = str(seed)
    pre_set = os.environ.get("PYTHONHASHSEED")
    if pre_set != expected:
        print(
            f"WARNING (AC #7 determinism): PYTHONHASHSEED was '{pre_set}' at "
            f"interpreter start; setting it now ('{expected}') is a no-op for "
            f"hash randomization (Python docs). Re-run with "
            f"`PYTHONHASHSEED={expected} uv run python ...` for fully "
            f"deterministic dict iteration order. Numerical seeds (random / "
            f"numpy / torch) are unaffected.",
            file=sys.stderr,
        )
    os.environ["PYTHONHASHSEED"] = expected  # informational
    os.environ["PYTORCH_ENABLE_MPS_FALLBACK"] = "1"
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    # warn_only=True per spec — some MPS ops have no deterministic impl.
    torch.use_deterministic_algorithms(True, warn_only=True)


# ---------------------------------------------------------------------------
# Train / val loops
# ---------------------------------------------------------------------------


def acc_4pct(predicted_bpm: torch.Tensor, true_bpm: torch.Tensor) -> torch.Tensor:
    """|pred - truth| / truth ≤ 0.04 — literature-comparable Acc1 (S&M 2018)."""
    return torch.abs(predicted_bpm - true_bpm) / torch.clamp(true_bpm, min=1e-6) <= 0.04


def bin_to_bpm_tensor(bin_idx: torch.Tensor) -> torch.Tensor:
    """Convert bin tensor to BPM (float)."""
    return bin_idx.float() + float(BPM_BIN_MIN)


def train_one_epoch(
    model: nn.Module,
    loader: DataLoader,
    optimizer: torch.optim.Optimizer,
    device: torch.device,
    label_smoothing: float = 0.1,
) -> tuple[float, float]:
    model.train()
    total_loss = 0.0
    total_correct_4pct = 0
    total_n = 0
    for x, y in loader:
        x = x.to(device, non_blocking=True)
        y = y.to(device, non_blocking=True)
        optimizer.zero_grad(set_to_none=True)
        logits = model(x)
        loss = F.cross_entropy(logits, y, label_smoothing=label_smoothing)
        loss.backward()
        optimizer.step()
        with torch.no_grad():
            pred_bin = logits.argmax(dim=1)
            pred_bpm = bin_to_bpm_tensor(pred_bin)
            true_bpm = bin_to_bpm_tensor(y)
            correct = acc_4pct(pred_bpm, true_bpm).sum().item()
            total_correct_4pct += correct
            total_n += x.shape[0]
        total_loss += loss.item() * x.shape[0]
    return total_loss / max(total_n, 1), total_correct_4pct / max(total_n, 1)


@torch.no_grad()
def eval_one_epoch(
    model: nn.Module,
    loader: DataLoader,
    device: torch.device,
    label_smoothing: float = 0.1,
) -> tuple[float, float]:
    model.eval()
    total_loss = 0.0
    total_correct_4pct = 0
    total_n = 0
    for x, y in loader:
        x = x.to(device, non_blocking=True)
        y = y.to(device, non_blocking=True)
        logits = model(x)
        loss = F.cross_entropy(logits, y, label_smoothing=label_smoothing)
        pred_bin = logits.argmax(dim=1)
        pred_bpm = bin_to_bpm_tensor(pred_bin)
        true_bpm = bin_to_bpm_tensor(y)
        correct = acc_4pct(pred_bpm, true_bpm).sum().item()
        total_correct_4pct += correct
        total_n += x.shape[0]
        total_loss += loss.item() * x.shape[0]
    return total_loss / max(total_n, 1), total_correct_4pct / max(total_n, 1)


# ---------------------------------------------------------------------------
# Metadata header (AC #7)
# ---------------------------------------------------------------------------


def env_metadata(seed: int) -> dict[str, Any]:
    import platform
    import subprocess

    def _safe_run(cmd: list[str]) -> str:
        try:
            return subprocess.check_output(cmd, text=True).strip()
        except Exception:
            return "unknown"

    import coremltools as ct
    import torchaudio

    git_sha = _safe_run(["git", "rev-parse", "--short", "HEAD"])
    macos_version = platform.mac_ver()[0]
    xcode_version = _safe_run(["xcodebuild", "-version"]).split("\n")[0]

    return {
        "git_sha": git_sha,
        "macos_version": macos_version,
        "xcode_version": xcode_version,
        "python_version": platform.python_version(),
        "torch_version": torch.__version__,
        "torchaudio_version": torchaudio.__version__,
        "coremltools_version": ct.__version__,
        "training_seed": seed,
        "feature_set_version": "v2",
        "training_start_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "mps_available": bool(torch.backends.mps.is_available()),
        "mps_built": bool(torch.backends.mps.is_built()),
        "deterministic_note": (
            "PyTorch MPS does NOT guarantee bit-reproducibility across macOS "
            "minor versions or between repeated runs of the same seed (PyTorch "
            "issue #97236 documents incomplete MPS determinism). The seed pin "
            "makes runs deterministic-at-the-Python-level but resulting weights "
            "may differ slightly across hardware/driver versions. The held-out "
            "test floor (DD #11 ≥5%% acc_4pct sanity HALT) is the regression-"
            "protection contract."
        ),
        "mps_fallback_observed": False,  # set true below if any epoch ≥ 5× median
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


@dataclass
class TrainArgs:
    seed: int = 42
    epochs: int = 60
    batch_size: int = 32
    lr: float = 1e-3
    label_smoothing: float = 0.1
    augment: bool = True
    subset: int | None = None
    num_workers: int = 0
    resume: str | None = None
    checkpoint_every: int = 5
    weighting_profile: str = "uniform"
    allow_legacy_giantsteps: bool = False


def parse_args(argv: list[str]) -> TrainArgs:
    p = argparse.ArgumentParser()
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--epochs", type=int, default=60)
    p.add_argument("--batch-size", type=int, default=32)
    p.add_argument("--lr", type=float, default=1e-3)
    p.add_argument("--label-smoothing", type=float, default=0.1)
    p.add_argument("--no-augment", action="store_true")
    p.add_argument(
        "--subset",
        type=int,
        default=None,
        help="Use only first N train tracks (smoke run). Validation always full.",
    )
    p.add_argument("--num-workers", type=int, default=0)
    p.add_argument("--resume", type=str, default=None)
    p.add_argument("--checkpoint-every", type=int, default=5)
    # Guardrail 3 (AC6 / DD #6): exactly one declared WeightingProfile per run.
    # The substrate OnsetFeaturesBuilder implements ONLY `.uniform` and THROWS
    # on `.subBandEmphasis`, so `uniform` is the only selectable value for the
    # v2 run. REQUIRED (no default) so a run can never start undeclared.
    p.add_argument(
        "--weighting-profile",
        type=str,
        required=True,
        choices=["uniform"],
        help="Declared WeightingProfile (Guardrail 3). Only 'uniform' is selectable: "
        "the substrate OnsetFeaturesBuilder throws on .subBandEmphasis (DD #6).",
    )
    p.add_argument(
        "--allow-legacy-giantsteps",
        action="store_true",
        help="Run the historical GiantSteps build_splits pipeline. NEVER use for the "
        "Story 7.5 v2 run — the substrate-v2 Tony loop must be wired first (S1 guard).",
    )
    a = p.parse_args(argv)
    return TrainArgs(
        seed=a.seed,
        epochs=a.epochs,
        batch_size=a.batch_size,
        lr=a.lr,
        label_smoothing=a.label_smoothing,
        augment=not a.no_augment,
        subset=a.subset,
        num_workers=a.num_workers,
        resume=a.resume,
        checkpoint_every=a.checkpoint_every,
        weighting_profile=a.weighting_profile,
        allow_legacy_giantsteps=a.allow_legacy_giantsteps,
    )


ML_TRAINING_DIR = Path(__file__).resolve().parent
REPO_ROOT = ML_TRAINING_DIR.parent.parent
DIAGNOSTICS_MD = ML_TRAINING_DIR / "corpus-diagnostics-v1.md"
_SIGNOFF_RE = re.compile(r"REVIEWER_SIGNOFF:\s*(signed|pending)")


class SubstratePreconditionError(RuntimeError):
    """Story 7.5 AC10 — train.py refuses to start unless (a) the Story 6.2
    FeatureSubstrate types, (b) the Story 6.5b ``BPMSelectionPolicy.select(``
    runtime flip, AND (c) the KDD-B4 corpus signoff are ALL present in the
    checkout. The substrate-bound v2 run must train against the same feature
    contract + runtime path Story 7.6 evaluates (FR-21 + Codex PHASED gate)."""


def check_substrate_preconditions() -> None:
    """AC10 / DD #11 / DD #16 — the named-error gate. Reaching this gate and
    aborting on (c) IS the dev-agent's verified outcome (the KDD-B4 signoff is
    operator-owned); the operator's full run proceeds only once it is signed."""
    sources = REPO_ROOT / "Sources" / "BoomBoomBoomKit"

    # (a) Story 6.2 substrate types present in the checkout.
    onset = sources / "FeatureSubstrate" / "OnsetFeatures.swift"
    builder = sources / "FeatureSubstrate" / "OnsetFeaturesBuilder.swift"
    if not onset.exists() or not builder.exists():
        raise SubstratePreconditionError(
            "AC10(a): FeatureSubstrate.OnsetFeatures / OnsetFeaturesBuilder absent from "
            f"{sources / 'FeatureSubstrate'} — the Story 6.2 substrate must be present."
        )

    # (b) Story 6.5b KDD-A6 Stage-3 flip: `func select(` (the signature spans
    # lines, so match `func select(` NOT `select(from:` — Story 7.5 DD #16/Codex).
    policy = sources / "BPMSelectionPolicy.swift"
    policy_text = policy.read_text(encoding="utf-8") if policy.exists() else ""
    # Require BOTH the declaration token AND the pool input type — a bare
    # `func select(` substring could live in a comment (review S2: a fail-closed
    # gate must not fail-open on a comment). `select(from: UnifiedSignalPool` is
    # the actual 6.5b signature.
    if "func select(" not in policy_text or "UnifiedSignalPool" not in policy_text:
        raise SubstratePreconditionError(
            "AC10(b): BPMSelectionPolicy.select(from: UnifiedSignalPool) (Story 6.5b "
            "KDD-A6 Stage-3 pool-authoritative flip) not found in Sources/ — the "
            "runtime path Story 7.6 evaluates against is absent."
        )

    # (c) KDD-B4 corpus signoff — same contract as
    # `scripts/audit-corpus-splits.py --check-gate`: exactly one
    # REVIEWER_SIGNOFF marker, and it must be `signed`.
    if not DIAGNOSTICS_MD.exists():
        raise SubstratePreconditionError(
            f"AC10(c): {DIAGNOSTICS_MD.name} not found — corpus diagnostics not produced "
            "(run `make corpus-diagnostics`). KDD-B4 gate cannot pass."
        )
    markers = _SIGNOFF_RE.findall(DIAGNOSTICS_MD.read_text(encoding="utf-8"))
    if len(markers) != 1:
        raise SubstratePreconditionError(
            f"AC10(c): expected exactly ONE REVIEWER_SIGNOFF marker in {DIAGNOSTICS_MD.name}, "
            f"found {len(markers)} — fails CLOSED (matches audit-corpus-splits.py --check-gate)."
        )
    if markers[0] != "signed":
        raise SubstratePreconditionError(
            "AC10(c): KDD-B4 corpus signoff is `pending`. Training is BLOCKED until the "
            f"operator transcribes what they verified in {DIAGNOSTICS_MD.name} and flips "
            "REVIEWER_SIGNOFF -> signed (the same gate `audit-corpus-splits.py --check-gate` "
            "enforces). Story 7.1 'done' = evidence assembled, NOT corpus-safe-to-train."
        )


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])

    # AC10 / DD #16: the substrate + flip + KDD-B4 signoff gate fires FIRST,
    # before any MPS/fixture/corpus work. In the dev environment the signoff is
    # `pending`, so this aborts with the named error — that abort IS the
    # dev-verified outcome (the operator owns the signoff + the full run).
    check_substrate_preconditions()

    set_seeds(args.seed)

    # AC #8 / DD #1: training MUST run on MPS to fit the 6h wall-clock budget.
    # If MPS isn't available the user is on the wrong machine; CPU-only would
    # take ~30h+ and silently overrun. HALT (a)-class: refuse to start.
    if not torch.backends.mps.is_available() and not args.subset:
        raise RuntimeError(
            "AC #8: full training requires MPS (Apple Silicon). "
            "torch.backends.mps.is_available() returned False. "
            "Use --subset for CPU-only smoke runs only."
        )
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"Device: {device}")

    fixture = load_fixture(FIXTURE_PATH)
    print(f"Loaded fixture v{fixture.feature_set_version} sha={fixture.sha256[:12]}")

    # Story 7.5 Task 4 / DD #2 — HARD STOP (review BLOCKER/landmine S1): the
    # substrate-bound v2 full run MUST train on the Tony Strong+Solid split
    # (corpus_splits.json tony.{train,val} via corpus_common.load_tony_corpus +
    # ablation_common), consuming feature_substrate_v2 model-input tensors + the
    # maskedMelPretrain recipe (ablation/masked_mel.py + train_masked_mel_pretrain.py).
    # That loop rewire is the operator's gated full-run step. Rather than leave
    # the legacy GiantSteps build_splits() reachable behind a prose comment (which
    # would silently train a MISMATCHED model the day an operator flips the
    # KDD-B4 signoff without doing the swap — the three-way review flagged this as
    # the load-bearing landmine), we FAIL CLOSED: the legacy loop is disabled.
    # Pass --allow-legacy-giantsteps ONLY for the historical GiantSteps pipeline,
    # never for the Story 7.5 v2 run.
    if not getattr(args, "allow_legacy_giantsteps", False):
        raise NotImplementedError(
            "Story 7.5: the substrate-v2 training loop (Tony split + "
            "feature_substrate_v2 + maskedMelPretrain) is the operator's gated "
            "full-run step and is NOT yet wired into train.py. The legacy "
            "GiantSteps build_splits() loop below is INTENTIONALLY DISABLED so a "
            "signed-off run cannot silently train a model on the wrong corpus + a "
            "non-runtime-faithful (crop/loop + 1e-8-floor z-score) feature path. "
            "Wire the v2 loader before the signed run; or pass "
            "--allow-legacy-giantsteps to run the historical GiantSteps pipeline."
        )
    splits = build_splits(verify=True)
    train_records = splits["train"]
    val_records = splits["val"]
    if args.subset is not None:
        train_records = train_records[: args.subset]
        print(f"SMOKE: using {args.subset} train tracks (val full {len(val_records)})")

    print(f"Train: {len(train_records)}, Val: {len(val_records)}")

    # Preload ONLY when workers=0 (single-process — cache is in main process).
    # With workers>0 each worker has its own memory; preloading in main is wasted
    # — workers fall back to OS page cache on disk reads. Empirically faster.
    preload = args.num_workers == 0
    train_set = CachedTempoDataset(
        train_records, fixture, augment=args.augment, seed=args.seed, preload=preload
    )
    val_set = CachedTempoDataset(
        val_records, fixture, augment=False, seed=args.seed, preload=preload
    )

    # Reverted persistent_workers=True after empirical deadlock at num_workers=8
    # on macOS: workers each accumulated 50+ min CPU but main consumed nothing
    # (queue/prefetch deadlock pattern documented for spawn + persistent on
    # macOS). Spawn-startup cost per epoch (~5s × N workers) is the cost we
    # pay; net is still substantially faster than num_workers=0.
    train_loader = DataLoader(
        train_set,
        batch_size=args.batch_size,
        shuffle=True,
        num_workers=args.num_workers,
        worker_init_fn=worker_init_fn,
        drop_last=False,
    )
    val_loader = DataLoader(
        val_set,
        batch_size=args.batch_size,
        shuffle=False,
        num_workers=args.num_workers,
        worker_init_fn=worker_init_fn,
        drop_last=False,
    )

    model = build_reference_model().to(device)
    n_params = verify_param_budget(model)
    print(f"Model params: {n_params}")

    optimizer = torch.optim.Adam(model.parameters(), lr=args.lr)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=args.epochs)

    start_epoch = 0
    if args.resume:
        # weights_only=False is intentional: the checkpoint contains
        # optimizer/scheduler state with non-tensor pickled fields. The
        # checkpoints are produced by THIS script under controlled conditions
        # — not consumer-supplied — so unpickling is safe here.
        ckpt = torch.load(args.resume, map_location=device, weights_only=False)
        model.load_state_dict(ckpt["model"])
        optimizer.load_state_dict(ckpt["optimizer"])
        scheduler.load_state_dict(ckpt["scheduler"])
        # Restore RNG state so resumed augmentation matches non-interrupted
        # runs at the same seed (AC #7 reproducibility envelope).
        if "rng_state" in ckpt:
            rng = ckpt["rng_state"]
            if "python" in rng:
                random.setstate(rng["python"])
            if "numpy" in rng:
                np.random.set_state(rng["numpy"])
            if "torch" in rng:
                torch.set_rng_state(rng["torch"])
        else:
            print(
                "WARN: --resume checkpoint has no rng_state; augmentation "
                "from this point will diverge from a non-interrupted run.",
                file=sys.stderr,
            )
        start_epoch = ckpt["epoch"] + 1
        print(f"Resumed from {args.resume} (epoch {start_epoch})")

    CHECKPOINTS_DIR.mkdir(exist_ok=True)

    log_metadata = env_metadata(args.seed)
    log_per_epoch: list[dict[str, Any]] = []
    epoch_walls: list[float] = []
    overall_start = time.time()

    # AC #8 wall-clock HALT (a) ceilings — actually enforced now (was
    # documented but never tripped in code). Smoke run uses --subset; full run
    # otherwise. If wall-clock exceeds the ceiling, raise so the run exits
    # non-zero before silently burning hours.
    SMOKE_CEILING_S = 2 * 60  # 2 min smoke ceiling
    FULL_CEILING_S = 6 * 60 * 60  # 6h full-run ceiling
    is_smoke = args.subset is not None
    ceiling_s = SMOKE_CEILING_S if is_smoke else FULL_CEILING_S
    print(f"AC #8 wall-clock ceiling: {ceiling_s}s ({'smoke' if is_smoke else 'full'} run)")

    for epoch in range(start_epoch, args.epochs):
        epoch_start = time.time()
        # Bump augmentation epoch counter so successive epochs see different
        # augmentations (deterministic at fixed seed + idx + epoch).
        if hasattr(train_set, "set_epoch"):
            train_set.set_epoch(epoch)
        train_loss, train_acc4 = train_one_epoch(
            model, train_loader, optimizer, device, label_smoothing=args.label_smoothing
        )
        val_loss, val_acc4 = eval_one_epoch(
            model, val_loader, device, label_smoothing=args.label_smoothing
        )
        scheduler.step()
        epoch_wall = time.time() - epoch_start
        epoch_walls.append(epoch_wall)
        rec = {
            "epoch": epoch,
            "wall_clock_seconds": epoch_wall,
            "lr": optimizer.param_groups[0]["lr"],
            "train_loss": train_loss,
            "train_acc_4pct": train_acc4,
            "val_loss": val_loss,
            "val_acc_4pct": val_acc4,
        }
        log_per_epoch.append(rec)
        median_wall = float(np.median(epoch_walls))
        if epoch_wall >= 5.0 * median_wall and len(epoch_walls) >= 3:
            log_metadata["mps_fallback_observed"] = True
            print(
                f"!! WARN: epoch {epoch} wall {epoch_wall:.1f}s >= 5x median {median_wall:.1f}s — MPS fallback suspected"
            )
        print(
            f"epoch {epoch:03d} | "
            f"wall {epoch_wall:6.1f}s | "
            f"train loss {train_loss:.4f} acc_4pct {train_acc4:.3f} | "
            f"val loss {val_loss:.4f} acc_4pct {val_acc4:.3f}"
        )

        # AC #8 HALT (a): enforce the wall-clock ceiling each epoch.
        elapsed = time.time() - overall_start
        if elapsed >= ceiling_s:
            print(
                f"\n*** HALT (a): wall-clock {elapsed:.1f}s exceeded ceiling "
                f"{ceiling_s}s ({'smoke <2min' if is_smoke else 'full <6h'}) ***",
                file=sys.stderr,
            )
            # Save what we have before raising so the partial run is recoverable.
            torch.save(model.state_dict(), MODEL_PATH.with_suffix(".pt.partial"))
            raise RuntimeError(f"AC #8 HALT (a): wall-clock {elapsed:.1f}s ≥ {ceiling_s}s")

        # Checkpoint every N — wrapped dict carrying RNG state for clean resume.
        if (epoch + 1) % args.checkpoint_every == 0 or epoch == args.epochs - 1:
            ckpt_path = CHECKPOINTS_DIR / f"epoch_{epoch:03d}.pt"
            torch.save(
                {
                    "epoch": epoch,
                    "model": model.state_dict(),
                    "optimizer": optimizer.state_dict(),
                    "scheduler": scheduler.state_dict(),
                    "args": vars(args),
                    "rng_state": {
                        "python": random.getstate(),
                        "numpy": np.random.get_state(),
                        "torch": torch.get_rng_state(),
                    },
                },
                ckpt_path,
            )

    # Save final model state_dict ONLY (export.py + eval.py reload this; the
    # wrapped intermediate checkpoints are for resume).
    torch.save(model.state_dict(), MODEL_PATH)

    log_metadata["training_end_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    log_metadata["total_wall_clock_seconds"] = time.time() - overall_start
    log_metadata["epochs_completed"] = len(log_per_epoch)
    log_metadata["median_epoch_wall_clock_seconds"] = (
        float(np.median(epoch_walls)) if epoch_walls else 0.0
    )

    out = {"metadata": log_metadata, "per_epoch": log_per_epoch}
    TRAINING_LOG_PATH.write_text(json.dumps(out, indent=2, sort_keys=True))
    print(f"\nWrote {TRAINING_LOG_PATH}")
    print(f"Wrote {MODEL_PATH}")
    print(f"Total wall-clock: {log_metadata['total_wall_clock_seconds']:.1f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
