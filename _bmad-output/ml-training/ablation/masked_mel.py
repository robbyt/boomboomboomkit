"""Masked-mel self-supervised pretraining (DD #13) for the maskedMelPretrain arm.

Story 7.3. Develop-only v1 scaffolding.

Pinned recipe (Codex/Winston/Amelia 2026-06-02 — the #1 cross-reviewer gap):
  - Encoder = TempoCNN.block1 -> pool1(1,5) -> block2 -> pool2(1,4) -> block3
    (everything BEFORE the GAP); latent shape (N, 96, 128, T/20).
  - Masking = input-space contiguous TIME-FRAME spans (NOT mel-band masking),
    ~15% of frames, span ~5 frames, mask value 0 (post-z-score mean ~ 0),
    deterministic from the run seed.
  - Decoder = lightweight interpolate-to-(128,T) + 1x1 conv (96 -> 1), DISCARDED
    after pretraining (only block1/2/3 weights transfer).
  - Loss = MSE on MASKED positions only.
  - Transfer = the pretrained TempoCNN's conv blocks warm-start the fine-tune
    model (same instance), then fine-tune ALL layers (head fc1/fc2 random). No
    freezing (freezing would be a different comparison).

References: He et al. 2022 (masked autoencoders); Park et al. 2019 (SpecAugment
time-masking precedent).
"""

from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F

DEFAULT_MASK_RATIO = 0.15
DEFAULT_SPAN = 5


def run_encoder(model: nn.Module, x: torch.Tensor) -> torch.Tensor:
    """Run the TempoCNN conv stack up to (but not including) the GAP."""
    x = model.block1(x)
    x = model.pool1(x)
    x = model.block2(x)
    x = model.pool2(x)
    x = model.block3(x)
    return x  # (N, 96, n_mels, T/20)


class MelReconstructionDecoder(nn.Module):
    """Lightweight decoder that undoes the 20x time pooling. Discarded post-pretrain."""

    def __init__(self, in_ch: int = 96, n_mels: int = 128, target_frames: int = 512):
        super().__init__()
        self.proj = nn.Conv2d(in_ch, 1, kernel_size=1)
        self._target = (n_mels, target_frames)

    def forward(self, latent: torch.Tensor) -> torch.Tensor:
        x = F.interpolate(latent, size=self._target, mode="nearest")  # (N, 96, 128, T)
        return self.proj(x)  # (N, 1, 128, T)


def make_time_mask(
    n_frames: int, mask_ratio: float, span: int, generator: torch.Generator
) -> torch.Tensor:
    """Boolean (n_frames,) — True = masked. Contiguous spans, ~mask_ratio coverage,
    deterministic from `generator`."""
    n_mask = int(round(mask_ratio * n_frames))
    mask = torch.zeros(n_frames, dtype=torch.bool)
    if n_mask <= 0 or n_frames <= 0:
        return mask
    guard = 0
    while int(mask.sum().item()) < n_mask and guard < n_frames * 4:
        start = int(torch.randint(0, max(1, n_frames - span + 1), (1,), generator=generator).item())
        mask[start : min(n_frames, start + span)] = True
        guard += 1
    return mask


def apply_time_mask(batch: torch.Tensor, mask_ratio: float, span: int, generator: torch.Generator):
    """Zero masked time-frames in a (N, 1, n_mels, T) batch.

    Returns `(masked_batch, mask_bool)` where `mask_bool` is (N, T) True=masked.
    Each sample gets its own deterministic span layout.
    """
    n, _c, _m, t = batch.shape
    masked = batch.clone()
    mask_bool = torch.zeros(n, t, dtype=torch.bool, device=batch.device)
    for i in range(n):
        m = make_time_mask(t, mask_ratio, span, generator).to(batch.device)
        masked[i, :, :, m] = 0.0
        mask_bool[i] = m
    return masked, mask_bool


def masked_reconstruction_loss(
    recon: torch.Tensor, target: torch.Tensor, mask_bool: torch.Tensor
) -> torch.Tensor:
    """MSE on masked positions only. `recon`/`target`: (N,1,n_mels,T); `mask_bool`: (N,T)."""
    # Broadcast (N,T) -> (N,1,n_mels,T) over mel + channel.
    m = mask_bool[:, None, None, :].expand_as(target)
    if m.sum() == 0:
        return (recon * 0.0).sum()  # no masked positions (degenerate) -> zero grad
    diff = (recon - target) ** 2
    return diff[m].mean()


def pretrain_encoder(
    model: nn.Module,
    loader,
    *,
    epochs: int,
    device: torch.device,
    seed: int,
    mask_ratio: float = DEFAULT_MASK_RATIO,
    span: int = DEFAULT_SPAN,
) -> None:
    """Masked-mel pretrain the conv encoder IN PLACE on `model` (block1/2/3 get
    grads; the head fc1/fc2 are untouched). The decoder is local + discarded."""
    import dataset as ds

    if not 0.0 <= mask_ratio <= 1.0:
        raise ValueError(f"mask_ratio must be in [0, 1]; got {mask_ratio}")
    if span < 1:
        raise ValueError(f"mask span must be >= 1; got {span}")
    if span >= ds.TARGET_FRAMES:
        # A span >= the frame count masks 100% of frames in one placement,
        # silently voiding mask_ratio (the encoder would see all-zero input).
        raise ValueError(
            f"mask span must be < TARGET_FRAMES ({ds.TARGET_FRAMES}); got {span} — "
            f"a span >= the frame count masks every frame and voids mask_ratio."
        )

    model.to(device)  # encoder weights must be on the same device as the batch
    # Decoder reconstruction shape is the LIVE feature shape (dataset.N_MELS /
    # TARGET_FRAMES), NOT a hardcoded 512 — so a future TARGET_FRAMES/N_MELS change
    # cannot silently shape-crash or mis-target the masked-MSE.
    decoder = MelReconstructionDecoder(n_mels=ds.N_MELS, target_frames=ds.TARGET_FRAMES).to(device)
    enc_params = (
        list(model.block1.parameters())
        + list(model.block2.parameters())
        + list(model.block3.parameters())
    )
    optimizer = torch.optim.Adam(enc_params + list(decoder.parameters()), lr=1e-3)
    gen = torch.Generator(device="cpu")
    gen.manual_seed(seed)
    model.train()
    decoder.train()
    for epoch in range(epochs):
        total, n = 0.0, 0
        for x in loader:
            x = x.to(device, non_blocking=True)
            x_masked, mask_bool = apply_time_mask(x, mask_ratio, span, gen)
            latent = run_encoder(model, x_masked)
            recon = decoder(latent)
            loss = masked_reconstruction_loss(recon, x, mask_bool)
            optimizer.zero_grad(set_to_none=True)
            loss.backward()
            optimizer.step()
            total += float(loss.item()) * x.shape[0]
            n += x.shape[0]
        print(f"[pretrain] epoch {epoch:03d} | masked-MSE {total / max(n, 1):.5f}")
