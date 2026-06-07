"""Phase 1.5 real-track runtime parity (Epic 7 close-out, Story 7.5 full-run).

Verifies that ``feature_substrate_v2``'s z-score + resample-to-512 matches the
Swift runtime on a REAL multi-minute track (large F), not just the short
(F<=496) sine/click fixtures ml-parity stage 5 uses. The Swift ``dump-real-track``
CLI ran the FULL AudioAnalysisService path and dumped, from the selected analysis
window's trace:
  - ``log_mel.f32``      — MLFeatureFrames.logMelData (frame-major [F*M])
  - ``model_input.f32``  — BNNSTechnique.modelInputTensor output (mel-major [M*512])
  - ``manifest.json``    — melBands / frames / window seconds / energy offset

Feeding Python the EXACT Swift log-mel isolates the z-score+resample step (no
AVFoundation-vs-librosa decode confound, no mel-impl confound). Compares against
a training-fidelity abs bound over active bands (log-mel std>=1e-3) — exact
bit-parity is not portable because the runtime's resample control comes from the
block-vectorized vDSP_vramp (see TRAIN_FIDELITY_ABS_TOL).

Run: ``uv run python verify_real_track_parity.py \
    --dump swift_feature_extractor/out/real_track``
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np

import feature_substrate_v2 as fsv2

# Training-fidelity bound on the model-input tensor. Exact bit-parity with the
# Swift runtime is NOT portably reproducible: the runtime's resample control comes
# from `vDSP_vramp`, a block-vectorized primitive whose float32 output is neither
# strict scalar accumulation nor pure i*step (this dump's control.f32 proved it).
# i*step (f32) is the closest portable match (~9.6e-4 residual here, vs ~3.3e-2 for
# the prior accumulation bug). That residual is a tiny, ~unbiased sub-sample jitter
# — far below the augmentation perturbations the model trains under — so a model
# trained on i*step features infers correctly through the vDSP runtime.
TRAIN_FIDELITY_ABS_TOL = 2.0e-3  # comfortably above the irreducible vDSP_vramp residual
ACTIVE_STD_FLOOR = 1e-3  # mirror test_feature_parity.py stage-5 active-band mask


def _read_f32(path: Path) -> np.ndarray:
    return np.frombuffer(path.read_bytes(), dtype=np.float32)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--dump", type=Path, default=Path("swift_feature_extractor/out/real_track"))
    args = p.parse_args(argv if argv is not None else sys.argv[1:])

    manifest = json.loads((args.dump / "manifest.json").read_text())
    melr = manifest["melBands"]
    frames = manifest["frames"]
    layout = manifest["tensorLayout"]
    if layout != "frameMajorLogMel":
        raise SystemExit(f"unexpected tensorLayout {layout!r} (expected frameMajorLogMel)")

    log_mel_flat = _read_f32(args.dump / "log_mel.f32")
    swift_model_input = _read_f32(args.dump / "model_input.f32")
    if log_mel_flat.size != melr * frames:
        raise SystemExit(f"log_mel size {log_mel_flat.size} != {melr}*{frames}")
    if swift_model_input.size != melr * fsv2.TARGET_WIDTH:
        raise SystemExit(f"model_input size {swift_model_input.size} != {melr}*{fsv2.TARGET_WIDTH}")

    # frame-major [F*M] -> [F, M] -> transpose -> mel-major [M, F]
    mel_major = np.ascontiguousarray(log_mel_flat.reshape(frames, melr).T, dtype=np.float32)
    py = fsv2.model_input_tensor_from_log_mel(mel_major)  # [M, 512]
    swift = swift_model_input.reshape(melr, fsv2.TARGET_WIDTH)

    # Active-band mask: bands whose log-mel actually varies (degenerate bands are
    # zeroed identically on both sides; z-score amplifies near-zero-std noise).
    band_std = mel_major.std(axis=1)
    active = band_std >= ACTIVE_STD_FLOOR
    n_active = int(active.sum())

    abs_diff = np.abs(py - swift)
    max_abs_active = float(abs_diff[active].max()) if n_active else 0.0
    max_abs_all = float(abs_diff.max())
    active_ok = max_abs_active <= TRAIN_FIDELITY_ABS_TOL

    print(f"track window: {manifest['analysisWindowSeconds']}s  F={frames}  melBands={melr}")
    print(f"active bands: {n_active}/{melr}")
    print(f"max abs diff (active): {max_abs_active:.3e}   (all bands): {max_abs_all:.3e}")
    print(f"training-fidelity bound: abs<={TRAIN_FIDELITY_ABS_TOL:.0e}")
    if active_ok:
        print("PARITY PASS — feature_substrate_v2 matches the runtime within training fidelity.")
        return 0
    print(f"PARITY FAIL — max active-band abs diff {max_abs_active:.3e} exceeds bound.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
