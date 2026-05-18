"""
Story 4-4b Task 3.1 — package Swift CLI outputs into feature_pipeline_v1.npz.

The Swift CLI (`swift_feature_extractor/`) writes raw float32 binaries +
manifest.json. This script reads them and bundles into the canonical
`fixtures/feature_pipeline_v1.npz` consumed by training and the parity harness.
"""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

import numpy as np

ML_TRAINING_DIR = Path(__file__).resolve().parent
SWIFT_OUT_DIR = ML_TRAINING_DIR / "swift_feature_extractor" / "out"
FIXTURE_PATH = ML_TRAINING_DIR / "fixtures" / "feature_pipeline_v1.npz"


def main() -> int:
    manifest_path = SWIFT_OUT_DIR / "manifest.json"
    if not manifest_path.exists():
        print(f"ERROR: manifest not found at {manifest_path}", file=sys.stderr)
        print("Run: cd swift_feature_extractor && swift run dump-fixture", file=sys.stderr)
        return 1

    manifest = json.loads(manifest_path.read_text())

    fb_shape = tuple(manifest["filterbank_shape"])  # (128, 1024)
    fb_path = SWIFT_OUT_DIR / manifest["filterbank_path"]
    win_path = SWIFT_OUT_DIR / manifest["stft_window_path"]

    fb = np.fromfile(fb_path, dtype=np.float32).reshape(fb_shape)
    win = np.fromfile(win_path, dtype=np.float32)
    assert win.shape[0] == manifest["stft_window_length"], "STFT window size mismatch"

    # Verify Swift's self-hash on the same byte stream (filterbank || window).
    expected_sha = manifest["sha256"]
    h = hashlib.sha256()
    with open(fb_path, "rb") as f:
        h.update(f.read())
    with open(win_path, "rb") as f:
        h.update(f.read())
    actual_sha = h.hexdigest()
    if actual_sha != expected_sha:
        print(f"ERROR: SHA-256 mismatch", file=sys.stderr)
        print(f"  expected: {expected_sha}", file=sys.stderr)
        print(f"  actual:   {actual_sha}", file=sys.stderr)
        return 1

    FIXTURE_PATH.parent.mkdir(parents=True, exist_ok=True)
    # Delete any prior fixture before writing — np.savez overwrites in place
    # but leaves no record of stale shapes if a prior run used different
    # n_mels / n_fft. Explicit unlink + rewrite makes the operation
    # observable in file-mtime / size and matches the "single canonical
    # fixture per feature_set_version" contract.
    if FIXTURE_PATH.exists():
        print(f"Removing stale fixture at {FIXTURE_PATH}")
        FIXTURE_PATH.unlink()
    np.savez(
        FIXTURE_PATH,
        mel_filterbank=fb,
        stft_window=win,
        hop_size=np.int32(manifest["hop_size"]),
        sample_rate=np.int32(manifest["sample_rate"]),
        f_min=np.float32(manifest["f_min"]),
        f_max=np.float32(manifest["f_max"]),
        n_fft=np.int32(manifest["n_fft"]),
        n_mels=np.int32(manifest["n_mels"]),
        feature_set_version=np.array(manifest["feature_set_version"]),
        sha256=np.array(actual_sha),
    )

    # Verify round-trip loads correctly.
    fixture = np.load(FIXTURE_PATH)
    assert fixture["mel_filterbank"].shape == fb_shape
    assert fixture["stft_window"].shape == win.shape
    print(f"Wrote {FIXTURE_PATH}")
    print(f"  mel_filterbank: {fb_shape}, dtype={fb.dtype}")
    print(f"  stft_window:    {win.shape}, dtype={win.dtype}")
    print(f"  hop_size={manifest['hop_size']}, sample_rate={manifest['sample_rate']}")
    print(f"  f_min={manifest['f_min']}, f_max={manifest['f_max']}")
    print(f"  feature_set_version={manifest['feature_set_version']}")
    print(f"  sha256={actual_sha}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
