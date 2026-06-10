# Masked-mel pretraining recipe (DD #13) — v1 scaffolding

Story 7.3. Develop-only. Implemented in `masked_mel.py` + `train_masked_mel_pretrain.py`.

The `maskedMelPretrain` arm underwrites half the KDD-B2 comparison, so the
self-supervised recipe is pinned (not invented ad hoc). Two devs running this
spec build the same SSL method.

## Encoder split

The transferable encoder is the TempoCNN conv stack BEFORE the global average
pool:

```
block1 -> pool1(1,5) -> block2 -> pool2(1,4) -> block3   ->  latent (N, 96, 128, T/20)
```

The conv stack downsamples time by 20x (5 x 4) and never touches the mel axis, so
the latent keeps all 128 mel bands. `run_encoder()` runs exactly these layers.

## Masking

- Input-space, contiguous **time-frame spans** on the z-scored log-mel (NOT
  mel-band masking — that would change frequency-weighting semantics).
- ~`15%` of frames (`--mask-ratio`, default `0.15`), span ~`5` frames
  (`--mask-span`).
- Mask value `0` (post-z-score per-band mean ~ 0).
- Deterministic from the run seed (a seeded `torch.Generator`).

## Decoder (discarded after pretraining)

A lightweight head that undoes the 20x time pooling: `F.interpolate` the latent
back to `(128, T)` then a `1x1` conv `96 -> 1`. It is trained alongside the
encoder during pretraining and then **discarded** — only `block1/2/3` weights
transfer.

## Loss

MSE on the **masked positions only** (`masked_reconstruction_loss`), not
full-frame reconstruction.

## Transfer

The SAME `TempoCNN` instance is used for both phases: pretraining trains its
`block1/2/3` (+ the throwaway decoder) on reconstruction; fine-tuning then trains
the whole model (encoder warm-started, head `fc1/fc2` random) on classification
with the octave-aware loss. **All layers fine-tune** (no freezing — freezing would
be a different comparison).

## Budgets

- Fine-tune budget = `--epochs` (the SHARED budget, identical to `supervisedAugmented`, DD #12).
- Pretrain budget = `--pretrain-epochs` (default `30`, SEPARATE; NOT counted
  against the fine-tune budget). Recorded in `model_metadata.json` as
  `pretrainEpochs` + `maskRatio`.

## Pretraining corpus (DD #12 hygiene)

Label-free train-side audio = `tony.train` strong audio + `secondarySupervised`
audio + `unsupervisedPool` audio, **excluding** `tony.val` / `tony.leaveArtistOut`
/ sentinel / eval-leak audio (so the artist-generalization measurement is not
contaminated). Residual risk: the `unsupervisedPool`'s artist provenance is not
reliably known, so a non-Rekordbox track could in principle be a held-out artist —
bounded, dev-only diagnostic cost (DD #12).

## References

- He et al. 2022, *Masked Autoencoders Are Scalable Vision Learners* (MAE).
- Park et al. 2019, *SpecAugment* (time-masking precedent for spectrograms).
