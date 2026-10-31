"""
Story 4-4b Task 3.6 / AC #3 Part B (+ Story 7.5 stage 5) — 5-stage
feature-pipeline parity harness.

Compares Python `extract_pre_log_mel` / `extract_log_mel` / `zscore_per_band`
and `feature_substrate_v2.model_input_tensor_from_audio` against the Swift CLI's
emitted per-stage outputs on the deterministic parity signals (1s 440 Hz sine +
5s 120 BPM click).

Tolerances per spec DD #5 / AC #3 Part B (+ Story 7.5 DD #15):
  Stage 1 — filterbank from .npz round-trip: abs ≤ 1e-6
  Stage 2 — raw mel POWER post-STFT, pre-log: abs ≤ 1e-5 OR rel ≤ 1e-4
  Stage 3 — log-mel post-log1p(100·x):        abs ≤ 1e-4 OR rel ≤ 1e-3
  Stage 4 — z-scored final tensor:            abs ≤ 1e-4 OR rel ≤ 1e-3
  Stage 5 — model-input tensor [128, 512]
            (post-featurize: mel-major + z-score + resample-to-512):
            abs ≤ 1e-4 OR rel ≤ 1e-3  — vs the `dump-model-input` Swift dump
            (BNNSTechnique.modelInputTensor). This is the FR-21 train/runtime
            seam: the training pipeline consumes feature_substrate_v2, the
            runtime consumes featurize; stage 5 proves they agree.
  Stage 6 — fixed-time crops [n, 128, 1200] (Story 15.5): the crop plan
            (1200-frame crops every 600 frames plus a tail crop), per-crop
            per-band z-score, no resize. abs ≤ 1e-4 OR rel ≤ 1e-3 — vs the
            `dump-fixed-time-input` Swift dump, on a 20 s 120 BPM click and a
            40 s click / silence / noisy-drone mix (the 1 s and 5 s signals are
            shorter than one 12 s crop). Crop start frames must match exactly. Python cuts each crop from PCM
            (`crop_tensor_at`, what training and scoring use); Swift slices the
            whole-signal log-mel.
  Stage 7 — rhythm scores (Story 15.5): the Python port
            `fixed_time.features.rhythm_score` vs the library's
            `RhythmicRegionSelector.probeRegions` on each exact 530,807-sample
            crop slice. abs ≤ 1e-4 OR rel ≤ 1e-3. The full ranking order and
            the kept crops (`rank_crops`) must also match; on the mix signal at
            least one crop must have an activity factor below 1, so that term
            is compared too.

Stages 4 and 5 mask degenerate (near-constant) bands and treat the sine as
informational (z-score amplifies near-zero-std diffs); the click is the binding
realistic-music gate. Failure surfaces the failing stage name; output captured
to feature_parity_report.txt.

Exit code: 0 on full pass, 1 on any gating-stage failure.
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np

from dataset import (
    FIXTURE_PATH,
    extract_log_mel,
    extract_pre_log_mel,
    load_fixture,
    zscore_per_band,
)

ML_TRAINING_DIR = Path(__file__).resolve().parent
SWIFT_OUT_DIR = ML_TRAINING_DIR / "swift_feature_extractor" / "out"
SWIFT_STAGES_DIR = SWIFT_OUT_DIR / "swift_stages"
PARITY_SIGNALS_DIR = ML_TRAINING_DIR / "parity_signals"
REPORT_PATH = ML_TRAINING_DIR / "feature_parity_report.txt"

# Tolerance contract (DD #5 + Story 7.5 DD #15)
STAGE_TOLERANCES = {
    1: {"abs": 1e-6, "rel": None},
    2: {"abs": 1e-5, "rel": 1e-4},
    3: {"abs": 1e-4, "rel": 1e-3},
    4: {"abs": 1e-4, "rel": 1e-3},
    # Stage 5 (Story 7.5): the post-featurize [128, 512] model-input tensor
    # (mel-major + z-score + resample-to-512). 1e-4/1e-3 aligned with stages
    # 3/4 — 1e-6 is unreachable for float STFT/log accumulation (DD #15).
    5: {"abs": 1e-4, "rel": 1e-3},
    # Stage 6 (Story 15.5): fixed-time crops, same tolerance as stage 5 (DD #15).
    6: {"abs": 1e-4, "rel": 1e-3},
    # Stage 7 (Story 15.5): crop rhythm scores, Python port vs Swift.
    7: {"abs": 1e-4, "rel": 1e-3},
}
# The mix must exercise the activity factor below 1 and a clear ranking.
FIXED_TIME_SIGNALS = {"click_120bpm_20s": False, "rhythm_mix_40s": True}


@dataclass
class StageResult:
    name: str
    stage: int
    passed: bool
    max_abs: float
    max_rel: float
    note: str
    # When True, this row is reported as informational only and DOES NOT
    # contribute to the OVERALL gate (e.g. Stage 4 on degenerate sine).
    # Reviewer-flagged: previously set passed=True without a flag, making
    # "OVERALL: PASS" silently include a non-gating row. Honest framing now.
    informational_only: bool = False


def compare_within_tol(
    a: np.ndarray, b: np.ndarray, abs_tol: float, rel_tol: float | None
) -> tuple[bool, float, float]:
    """Returns (passed, max_abs_diff, max_rel_diff)."""
    if a.shape != b.shape:
        return False, float("inf"), float("inf")
    abs_diff = np.abs(a - b)
    max_abs = float(abs_diff.max())
    denom = np.maximum(np.abs(a), np.abs(b))
    rel_diff = np.where(denom > 1e-12, abs_diff / np.maximum(denom, 1e-12), 0.0)
    max_rel = float(rel_diff.max())
    if rel_tol is None:
        passed = max_abs <= abs_tol
    else:
        # Element-wise: each element passes if abs OR rel within tolerance.
        passes_abs = abs_diff <= abs_tol
        passes_rel = (denom > 1e-12) & (rel_diff <= rel_tol)
        passed = bool(np.all(passes_abs | passes_rel))
    return passed, max_abs, max_rel


def stage1_fixture_roundtrip(report: list[StageResult]) -> bool:
    """Stage 1 — filterbank fixture .npz round-trip ≤ 1e-6."""
    fixture = load_fixture(FIXTURE_PATH)
    swift_fb = np.fromfile(SWIFT_OUT_DIR / "mel_filterbank.f32", dtype=np.float32).reshape(
        fixture.mel_filterbank.shape
    )
    swift_win = np.fromfile(SWIFT_OUT_DIR / "stft_window.f32", dtype=np.float32)

    fb_passed, fb_abs, fb_rel = compare_within_tol(
        fixture.mel_filterbank, swift_fb, STAGE_TOLERANCES[1]["abs"], None
    )
    win_passed, win_abs, win_rel = compare_within_tol(
        fixture.stft_window, swift_win, STAGE_TOLERANCES[1]["abs"], None
    )

    report.append(
        StageResult(
            name="filterbank",
            stage=1,
            passed=fb_passed,
            max_abs=fb_abs,
            max_rel=fb_rel,
            note=f"shape={fixture.mel_filterbank.shape}",
        )
    )
    report.append(
        StageResult(
            name="stft_window",
            stage=1,
            passed=win_passed,
            max_abs=win_abs,
            max_rel=win_rel,
            note=f"shape={fixture.stft_window.shape}",
        )
    )
    return fb_passed and win_passed


def _load_swift_2d(path: Path, shape: tuple[int, int]) -> np.ndarray:
    """Load Swift's flat float32 dump as (frames, n_mels)."""
    arr = np.fromfile(path, dtype=np.float32)
    return arr.reshape(shape)


def stage234_for_signal(
    signal_name: str, audio_path: Path, fixture, manifest: dict, report: list[StageResult]
) -> bool:
    """Run Stages 2/3/4 on a deterministic signal and compare.

    Stage 4 (z-score) skips degenerate bands. Z-score on a near-constant signal
    is mathematically undefined (0/0); the +1e-8 numerical floor amplifies
    float32 ordering noise to O(1) magnitude. This is signal-degeneracy, not a
    real parity break — it cannot occur on real music input where every mel band
    carries non-trivial energy. Mask: drop any band where the log-mel std (in
    either Python or Swift) is below 1e-3 (visually-flat band threshold).
    """
    audio = np.fromfile(audio_path, dtype=np.float32)
    stage_meta = manifest["stages"][signal_name]
    frame_count = stage_meta["frame_count"]
    n_mels = manifest["n_mels"]
    expected_shape = (frame_count, n_mels)

    # Python computes Stage 2 (pre-log) and Stage 3 (log-mel)
    py_stage2 = extract_pre_log_mel(audio, fixture)  # (frames, n_mels)
    py_stage3_t = extract_log_mel(audio, fixture)  # (n_mels, frames)
    py_stage3 = py_stage3_t.T  # to (frames, n_mels) for parity
    py_stage4_t = zscore_per_band(py_stage3_t)  # (n_mels, frames)
    py_stage4 = py_stage4_t.T  # to (frames, n_mels) for parity

    # Swift dumps as flat float32, layout (frames, n_mels) row-major.
    swift_stage2 = _load_swift_2d(SWIFT_STAGES_DIR / stage_meta["stage2_path"], expected_shape)
    swift_stage3 = _load_swift_2d(SWIFT_STAGES_DIR / stage_meta["stage3_path"], expected_shape)
    swift_stage4 = _load_swift_2d(SWIFT_STAGES_DIR / stage_meta["stage4_path"], expected_shape)

    # Stage 4 active-band mask
    DEGENERATE_STD_THRESHOLD = 1e-3
    py_band_std = py_stage3.std(axis=0)  # (n_mels,)
    swift_band_std = swift_stage3.std(axis=0)
    active_mask = (py_band_std >= DEGENERATE_STD_THRESHOLD) & (
        swift_band_std >= DEGENERATE_STD_THRESHOLD
    )
    n_active = int(active_mask.sum())

    all_passed = True
    for stage, py, swift in [
        (2, py_stage2, swift_stage2),
        (3, py_stage3, swift_stage3),
        (4, py_stage4, swift_stage4),
    ]:
        tol = STAGE_TOLERANCES[stage]
        if stage == 4:
            # Sine is a degenerate stress signal for Stage 4: only ~32/128 mel
            # bands are active and most active bands have small std. Tiny
            # Stage 3 absolute diffs (1e-5 in near-zero log1p outputs) get
            # amplified by z-score's 1/std term to O(5e-3) — pure float32
            # accumulation-order noise, NOT a real parity break (verified: when
            # Python z-scores Swift's Stage 3 output, parity is bit-identical).
            # The click signal exercises all 128 bands with rich dynamic range,
            # so its Stage 4 is the binding realistic-music gate. Skip Stage 4
            # for sine and report descriptively.
            if signal_name == "sine_440Hz_1s":
                py_masked = py[:, active_mask]
                swift_masked = swift[:, active_mask]
                row_passed, max_abs, max_rel = compare_within_tol(
                    swift_masked, py_masked, tol["abs"], tol["rel"]
                )
                # Mark as informational_only so OVERALL doesn't aggregate
                # this row's pass/fail. The actual measured pass/fail still
                # appears in the report (no longer hard-coded True).
                report.append(
                    StageResult(
                        name=signal_name,
                        stage=stage,
                        passed=row_passed,
                        max_abs=max_abs,
                        max_rel=max_rel,
                        note=(
                            f"INFORMATIONAL (degenerate signal); "
                            f"active_bands={n_active}/{n_mels}; "
                            f"NOT counted in OVERALL — click is the Stage 4 binding gate"
                        ),
                        informational_only=True,
                    )
                )
                continue
            # Click (or any realistic music): mask degenerate bands but enforce.
            py_masked = py[:, active_mask]
            swift_masked = swift[:, active_mask]
            passed, max_abs, max_rel = compare_within_tol(
                swift_masked, py_masked, tol["abs"], tol["rel"]
            )
            note = (
                f"active_bands={n_active}/{n_mels}; "
                f"degenerate_threshold_std={DEGENERATE_STD_THRESHOLD:.0e}; "
                f"tol abs≤{tol['abs']:.0e} rel≤{tol['rel']}"
            )
        else:
            passed, max_abs, max_rel = compare_within_tol(swift, py, tol["abs"], tol["rel"])
            note = f"shape={py.shape}; tol abs≤{tol['abs']:.0e} rel≤{tol['rel']}"
        report.append(
            StageResult(
                name=signal_name,
                stage=stage,
                passed=passed,
                max_abs=max_abs,
                max_rel=max_rel,
                note=note,
            )
        )
        # Only gating rows contribute to all_passed; informational-only rows
        # are skipped (the `continue` above for sine Stage 4).
        all_passed = all_passed and passed

    return all_passed


def stage5_model_input_for_signal(
    signal_name: str, audio_path: Path, fixture, report: list[StageResult]
) -> bool:
    """Story 7.5 stage 5 — the post-featurize [128, 512] model-input tensor.

    Compares ``feature_substrate_v2.model_input_tensor_from_audio`` (the numpy
    reconstruction the training pipeline consumes) against the Swift
    ``dump-model-input`` dump (the runtime ``BNNSTechnique.modelInputTensor``).
    Same degenerate-band masking + sine=informational / click=binding-gate
    discipline as stage 4 (z-score amplifies near-zero-std log-mel diffs).
    """
    from feature_substrate_v2 import model_input_tensor_from_audio

    audio = np.fromfile(audio_path, dtype=np.float32)
    py = model_input_tensor_from_audio(audio, fixture)  # mel-major [128, 512]

    swift_path = SWIFT_STAGES_DIR / f"{signal_name}_stage5_model_input.f32"
    if not swift_path.exists():
        report.append(
            StageResult(
                name=signal_name,
                stage=5,
                passed=False,
                max_abs=float("inf"),
                max_rel=float("inf"),
                note=(
                    f"MISSING Swift dump {swift_path.name} — run "
                    "`cd swift_feature_extractor && swift run dump-model-input`"
                ),
            )
        )
        return False
    swift = np.fromfile(swift_path, dtype=np.float32).reshape(py.shape)  # mel-major [128, 512]

    # Active-band mask from the pre-resample log-mel std (mel-major [M, F]).
    log_mel = extract_log_mel(audio, fixture)  # [M, F]
    band_std = log_mel.std(axis=1)
    active = band_std >= 1e-3
    n_active = int(active.sum())
    tol = STAGE_TOLERANCES[5]
    passed, max_abs, max_rel = compare_within_tol(swift[active], py[active], tol["abs"], tol["rel"])

    if signal_name == "sine_440Hz_1s":
        # Degenerate stress signal (only ~32/128 active bands): informational,
        # not counted in OVERALL. Click is the binding realistic-music gate.
        report.append(
            StageResult(
                name=signal_name,
                stage=5,
                passed=passed,
                max_abs=max_abs,
                max_rel=max_rel,
                note=(
                    f"INFORMATIONAL (degenerate signal); active_bands={n_active}/128; "
                    "NOT counted in OVERALL — click is the stage-5 binding gate"
                ),
                informational_only=True,
            )
        )
        return True

    report.append(
        StageResult(
            name=signal_name,
            stage=5,
            passed=passed,
            max_abs=max_abs,
            max_rel=max_rel,
            note=(
                f"model-input tensor [128, 512]; active_bands={n_active}/128; "
                f"tol abs<={tol['abs']:.0e} rel<={tol['rel']}"
            ),
        )
    )
    return passed


def stage6_fixed_time_crops(
    signal: str, needs_low_activity: bool, fixture, report: list[StageResult]
) -> bool:
    """Story 15.5 stages 6 and 7 for one signal — fixed-time crop tensors and crop
    rhythm scores, Python vs Swift.

    Stage 6: crop start frames must be identical; tensors must agree within
    tolerance on the active (non-flat) bands of each crop. Stage 7: the ported
    rhythm score of each exact crop slice against Swift `probeRegions`, the full
    ranking order and the kept crops, and (when `needs_low_activity`) that some
    crop's activity factor is below 1.
    """
    from fixed_time import features as ft

    def missing(note: str) -> bool:
        for stage in (6, 7):
            report.append(
                StageResult(
                    name=signal,
                    stage=stage,
                    passed=False,
                    max_abs=float("inf"),
                    max_rel=float("inf"),
                    note=note,
                )
            )
        return False

    audio_path = PARITY_SIGNALS_DIR / f"{signal}.f32"
    manifest_path = SWIFT_STAGES_DIR / f"{signal}_fixed_time.json"
    if not audio_path.exists() or not manifest_path.exists():
        return missing(
            f"MISSING {signal} signal or Swift dump — run "
            "`cd swift_feature_extractor && swift run dump-fixed-time-input`"
        )
    manifest = json.loads(manifest_path.read_text())
    audio = np.fromfile(audio_path, dtype=np.float32)
    n_frames = ft.frame_count(audio.shape[0])
    starts = ft.crop_plan(n_frames)
    if (
        starts != manifest["cropStarts"]
        or n_frames != manifest["frames"]
        or manifest.get("cropSamples") != ft.CROP_SAMPLES
    ):
        return missing(
            f"crop plan differs: python frames={n_frames} starts={starts} "
            f"samples={ft.CROP_SAMPLES}, swift frames={manifest['frames']} "
            f"starts={manifest['cropStarts']} samples={manifest.get('cropSamples')}"
        )
    py = np.stack([ft.crop_tensor_at(audio, s, fixture) for s in starts])
    swift = np.fromfile(SWIFT_STAGES_DIR / manifest["cropsPath"], dtype=np.float32).reshape(
        py.shape
    )
    # Active-band mask per crop from the pre-z-score log-mel crop.
    log_mel = extract_log_mel(audio, fixture)  # [M, F]
    active = np.stack(
        [log_mel[:, s : s + ft.CROP_FRAMES].std(axis=1) >= 1e-3 for s in starts]
    )  # [n_crops, M]
    tol = STAGE_TOLERANCES[6]
    passed6, max_abs, max_rel = compare_within_tol(
        swift[active], py[active], tol["abs"], tol["rel"]
    )
    report.append(
        StageResult(
            name=signal,
            stage=6,
            passed=passed6,
            max_abs=max_abs,
            max_rel=max_rel,
            note=(
                f"fixed-time crops {list(py.shape)} at starts {starts}; "
                f"active_bands={int(active.sum())}/{active.size}; "
                f"tol abs<={tol['abs']:.0e} rel<={tol['rel']}"
            ),
        )
    )

    parts = [ft.rhythm_score_parts(ft.crop_pcm(audio, s)) for s in starts]
    py_scores = np.array([p * a for p, a in parts])
    swift_scores = np.asarray(manifest["rhythmScores"], dtype=np.float64)
    tol = STAGE_TOLERANCES[7]
    passed7, max_abs, max_rel = compare_within_tol(swift_scores, py_scores, tol["abs"], tol["rel"])

    def order(scores) -> list[int]:
        return sorted(starts, key=lambda s: (-scores[starts.index(s)], s))

    py_order, swift_order = order(py_scores), order(swift_scores)
    py_kept = ft.rank_crops(starts, py_scores.tolist())
    swift_kept = ft.rank_crops(starts, swift_scores.tolist())
    min_activity = min((a for _, a in parts if a > 0), default=0.0)
    problems = []
    if py_order != swift_order:
        problems.append(f"ranking differs: python {py_order}, swift {swift_order}")
    if py_kept != swift_kept:
        problems.append(f"kept crops differ: python {py_kept}, swift {swift_kept}")
    if needs_low_activity and not min_activity < 1.0:
        problems.append("no crop has an activity factor below 1; the fixture does not exercise it")
    passed7 = passed7 and not problems
    report.append(
        StageResult(
            name=signal,
            stage=7,
            passed=passed7,
            max_abs=max_abs,
            max_rel=max_rel,
            note=(
                f"crop rhythm scores {np.round(py_scores, 6).tolist()} vs Swift probeRegions; "
                f"ranking {py_order}, kept {py_kept}; min activity {min_activity:.3f}; "
                f"tol abs<={tol['abs']:.0e} rel<={tol['rel']}"
                + (f"; {'; '.join(problems)}" if problems else "")
            ),
        )
    )
    return passed6 and passed7


def main() -> int:
    if not FIXTURE_PATH.exists():
        print(f"FIXTURE NOT BUILT: {FIXTURE_PATH}", file=sys.stderr)
        print("Run: cd swift_feature_extractor && swift run dump-fixture", file=sys.stderr)
        print("Then: uv run python build_fixture.py", file=sys.stderr)
        return 2

    manifest_path = SWIFT_OUT_DIR / "manifest.json"
    if not manifest_path.exists():
        print(f"SWIFT MANIFEST NOT FOUND: {manifest_path}", file=sys.stderr)
        return 2

    manifest = json.loads(manifest_path.read_text())
    fixture = load_fixture(FIXTURE_PATH)

    report: list[StageResult] = []
    overall = stage1_fixture_roundtrip(report)

    for signal_name in ["sine_440Hz_1s", "click_120bpm_5s"]:
        audio_path = PARITY_SIGNALS_DIR / f"{signal_name}.f32"
        if not audio_path.exists():
            print(f"PARITY SIGNAL NOT FOUND: {audio_path}", file=sys.stderr)
            return 2
        passed = stage234_for_signal(signal_name, audio_path, fixture, manifest, report)
        overall = overall and passed
        # Story 7.5 stage 5 — model-input tensor parity (depends on the
        # dump-model-input Swift dump; sine is informational, click gates).
        stage5_passed = stage5_model_input_for_signal(signal_name, audio_path, fixture, report)
        overall = overall and stage5_passed

    # Story 15.5 stages 6 and 7 — fixed-time crop and rhythm-score parity on both signals.
    for signal, needs_low_activity in FIXED_TIME_SIGNALS.items():
        overall = stage6_fixed_time_crops(signal, needs_low_activity, fixture, report) and overall

    # Render report
    lines = []
    lines.append("=" * 78)
    lines.append("Feature pipeline parity harness — Story 4-4b AC #3 Part B")
    lines.append("=" * 78)
    lines.append(f"Fixture: {FIXTURE_PATH.relative_to(ML_TRAINING_DIR)}")
    lines.append(f"Fixture sha256: {fixture.sha256}")
    lines.append(f"feature_set_version: {fixture.feature_set_version}")
    lines.append("")
    lines.append("STAGE_TOLERANCES:")
    for s, t in STAGE_TOLERANCES.items():
        lines.append(f"  Stage {s}: abs ≤ {t['abs']:.0e}, rel ≤ {t['rel']}")
    lines.append("")
    lines.append(f"{'stage':<6}{'name':<26}{'flag':<8}{'max_abs':>14}{'max_rel':>14}  note")
    lines.append("-" * 110)
    for r in report:
        if r.informational_only:
            flag = "INFO" if r.passed else "info"
        else:
            flag = "OK" if r.passed else "FAIL"
        lines.append(
            f"{r.stage:<6}{r.name:<26}{flag:<8}{r.max_abs:>14.6e}{r.max_rel:>14.6e}  {r.note}"
        )
    lines.append("-" * 110)
    lines.append("")
    lines.append(f"OVERALL (gating rows only): {'PASS' if overall else 'FAIL'}")
    lines.append("")
    if not overall:
        for r in report:
            if not r.passed:
                lines.append(
                    f"  FAILING STAGE {r.stage} ({r.name}): max_abs={r.max_abs:.6e}, "
                    f"max_rel={r.max_rel:.6e}"
                )

    output = "\n".join(lines)
    REPORT_PATH.write_text(output)
    print(output)
    return 0 if overall else 1


if __name__ == "__main__":
    sys.exit(main())
