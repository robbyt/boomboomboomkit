"""Story 12.4 (Gate 0): score the published reference tempo CNN on our 661 GiantSteps rows.

Develop-only. Runs the Schreiber and Mueller ISMIR 2018 single-step tempo CNN
("A Single-Step Approach to Musical Tempo Estimation Using a Convolutional Neural
Network", ISMIR 2018) end to end -- the model's OWN featurization and decode as
published (2018 paper Sections 3.1 and 3.4), NOT our substrate -- and scores it on
literally the same 661 GiantSteps rows, annotation source, and FR-18-strict protocol
that produced our v2 model's 348/661.

Row resolution is REUSED from ``build_fr18_input.resolve_giantsteps`` so the rows are
identical by construction. The strict Acc1 scorer is REUSED from
``evaluate_fr18.acc1_correct`` (4% relative tolerance, abstain counts wrong) for the
same reason. Context rows (strict @2%, tempo2-floor @2%, octave-tolerant @4%, Acc2 @4%)
are computed here and always labelled with their protocol.

Weights live OUTSIDE git in ``TEMPOCNN_WEIGHTS_DIR``; identity is pinned by
``tempocnn-baseline-provenance.json`` (SHA-256 AND git blob SHA-1) and this harness
refuses to run on any mismatch. TensorFlow is imported lazily so the scorer / gate /
checksum logic stays importable (and unit-testable) without the ``tempocnn-baseline``
dependency group.

Published pipeline implemented here, per primary text:
- 2018 paper Section 3.1: mono, resample to 11025 Hz, half-overlapping windows of
  1024 samples (hop 512), 40-band mel magnitude spectrum covering 20-5000 Hz,
  network input 256 frames (about 11.9 s).
- 2018 paper Section 3.3: each 256-frame sub-spectrogram rescaled to [0, 1]
  independently (PER-WINDOW max-normalization -- the paper's training-time semantics;
  recorded as an implementation decision in the story report).
- 2018 paper Section 3.4: sliding window with half-overlap (hop 128 frames),
  activations averaged class-wise, tempo class with greatest activation wins.
  Trailing frames short of a full 256-frame window are DROPPED (up to 127 frames,
  about 5.9 s), matching the reference implementation's sliding-window behavior;
  recorded as an implementation decision in the story report.
- 2018 paper Section 3.2: 256 tempo classes covering integer BPM 30 to 285,
  so decoded BPM = argmax index + 30.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

from build_fr18_input import resolve_giantsteps
from corpus_manifests import sha256_file  # streamed digest, shared with the manifest tooling
from evaluate_fr18 import EXPECTED_GIANTSTEPS, acc1_correct, octave_match

HERE = Path(__file__).resolve().parent
PROVENANCE_PATH = HERE / "tempocnn-baseline-provenance.json"

# Gate 0 inputs (pre-registered; see 12-4-tempocnn-baseline-report.md).
OUR_MODEL_TRACKS = 348  # v2 maskedMelPretrain seed_42, FR-18 strict Acc1 on 661
PUBLISHED_ACC1 = 0.825  # Schreiber & Mueller 2019 (arXiv:1903.10839) Table 4a,
# 'Literature' row for GiantSteps (their [3] = the 2018 CNN), revised annotations,
# 661 tracks, Acc1 with 4% tolerance (2019 paper Section 2.5).

STRICT_TOL = 0.04  # matches evaluate_fr18.ACC1_TOL (FR-18 protocol)
CONTEXT_TOL = 0.02  # DSP-benchmark tolerance, context rows only

# A systematic environment fault (broken TF install, unreadable corpus mount) would
# otherwise score 0/661 and emit gate0Fires: true -- the exact wrong verdict. Above
# this per-track failure fraction the run refuses to score at all.
MAX_FAILURE_FRACTION = 0.05


# ---------------------------------------------------------------------------
# Pure logic (importable without TensorFlow)
# ---------------------------------------------------------------------------


def git_blob_sha1(path: Path) -> str:
    """git's blob object id: sha1(b"blob <len>\\0" + bytes)."""
    data = path.read_bytes()
    h = hashlib.sha1(b"blob %d\x00" % len(data))
    h.update(data)
    return h.hexdigest()


def verify_checksums(weights_dir: Path, provenance: dict) -> Path:
    """Verify every file in the provenance record (SHA-256 and, when recorded, git
    blob SHA-1); refuse on mismatch or absence. Returns the model file's path (the
    entry named by the provenance's ``model_file`` key)."""
    files = provenance.get("files") or {}
    if not files:
        raise SystemExit("ERROR: provenance record lists no files; refusing to run.")
    model_file = provenance.get("model_file")
    if not model_file or model_file not in files:
        raise SystemExit(
            "ERROR: provenance record has no model_file key naming which entry to load;"
            " refusing to run."
        )
    for name, meta in files.items():
        path = weights_dir / name
        if not path.is_file():
            raise SystemExit(f"ERROR: weights file missing: {path}")
        expected_sha = meta.get("sha256")
        if not expected_sha:
            raise SystemExit(f"ERROR: provenance entry for {name} has no sha256; refusing to run.")
        digest = sha256_file(path)
        if digest != expected_sha:
            raise SystemExit(
                f"ERROR: SHA-256 mismatch for {path}\n"
                f"  expected {expected_sha}\n"
                f"  actual   {digest}\n"
                "Refusing to run: the weights are not the recorded artifact."
            )
        expected_blob = meta.get("git_blob_sha1")
        if expected_blob:
            blob = git_blob_sha1(path)
            if blob != expected_blob:
                raise SystemExit(
                    f"ERROR: git blob SHA-1 mismatch for {path}\n"
                    f"  expected {expected_blob}\n"
                    f"  actual   {blob}\n"
                    "Refusing to run: the weights are not the recorded artifact."
                )
    return weights_dir / model_file


def acc_within(pred: float | None, truth: float, tol: float) -> bool:
    """Relative-tolerance accuracy; None / non-finite / non-positive pred is wrong."""
    if pred is None or not math.isfinite(pred) or pred <= 0:
        return False
    if not math.isfinite(truth) or truth <= 0:
        return False
    return abs(pred - truth) / truth <= tol


def tempo2_floor_correct(
    pred: float | None, truth: float, tempo2: float | None, tol: float
) -> bool:
    """Correct if within tol of the primary truth OR of tempo2 (when present).

    Python re-implementation of the Swift benchmark's mirexHit semantics
    (GiantStepsBenchmarkTests); equivalence is unit-tested on synthetic rows only."""
    if acc_within(pred, truth, tol):
        return True
    if tempo2 is not None and tempo2 > 0:
        return acc_within(pred, float(tempo2), tol)
    return False


def acc2_correct(pred: float | None, truth: float, tol: float) -> bool:
    """Acc2 per the papers: correct allowing octave errors by factors 2 and 3
    (2018 paper Section 4: "allowing octave errors 2 and 3 ... a 4% tolerance")."""
    if pred is None or not math.isfinite(pred) or pred <= 0:
        return False
    if not math.isfinite(truth) or truth <= 0:
        return False
    for factor in (1.0, 2.0, 0.5, 3.0, 1.0 / 3.0):
        if abs(pred * factor - truth) / truth <= tol:
            return True
    return False


def persist_failed_run(
    output: Path, model_variant: str, gt_basename: str, gt_sha256: str, rows: list[dict]
) -> Path:
    """Write the per-track evidence of a run the failure guard refused to score.

    Deliberately carries ``scored: False`` and NO summary/gate block, so a failed
    run can never be mistaken for a scored artifact."""
    failed_path = output.parent / "predictions-failed.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    failed_path.write_text(
        json.dumps(
            {
                "story": "12.4",
                "generatedAt": datetime.now(timezone.utc).isoformat(),
                "modelVariant": model_variant,
                "groundTruthFile": {"basename": gt_basename, "sha256": gt_sha256},
                "scored": False,
                "tracks": rows,
            },
            indent=2,
        )
    )
    return failed_path


def gate_inputs(n: int = EXPECTED_GIANTSTEPS) -> dict:
    """Pre-registered midpoint(348, P) rule, computed in tracks.

    OUR_MODEL_TRACKS = 348 is pre-registered FOR the 661-row denominator; any other
    n would silently compare different populations, so it is refused."""
    if n != EXPECTED_GIANTSTEPS:
        raise SystemExit(
            f"ERROR: gate rule is pre-registered for n={EXPECTED_GIANTSTEPS}, got n={n}."
        )
    p_tracks = round(PUBLISHED_ACC1 * n)
    midpoint = (OUR_MODEL_TRACKS + p_tracks) / 2.0
    return {
        "ourModelTracks": OUR_MODEL_TRACKS,
        "publishedAcc1": PUBLISHED_ACC1,
        "publishedTracksOn661": p_tracks,
        "midpointTracks": midpoint,
        "rule": "Gate 0 fires iff referenceStrictAcc1Tracks <= midpoint; passes iff above.",
    }


def gate_verdict(reference_tracks: int, n: int = EXPECTED_GIANTSTEPS) -> dict:
    inputs = gate_inputs(n)
    fires = reference_tracks <= inputs["midpointTracks"]
    return {
        **inputs,
        "referenceStrictAcc1Tracks": reference_tracks,
        "gate0Fires": fires,
        "verdict": "measurement-not-modelling" if fires else "gap-attributable-to-our-model",
    }


def score_rows(rows: list[dict]) -> dict:
    """Score per-track prediction rows (modelBPM, groundTruthBPM, tempo2).

    Refuses a denominator other than EXPECTED_GIANTSTEPS, and refuses to score when
    per-track failures exceed MAX_FAILURE_FRACTION (a mostly-failed run must not be
    read as a near-zero accuracy and fire the gate)."""
    n = len(rows)
    if n != EXPECTED_GIANTSTEPS:
        raise SystemExit(
            f"ERROR: denominator is {n}, expected {EXPECTED_GIANTSTEPS}. "
            "Refusing to score a different population."
        )
    failures = [r for r in rows if r.get("modelBPM") is None]
    if len(failures) > MAX_FAILURE_FRACTION * n:
        reasons = sorted({str(r.get("failureReason", "unknown")) for r in failures})
        raise SystemExit(
            f"ERROR: {len(failures)}/{n} per-track failures exceed the "
            f"{MAX_FAILURE_FRACTION:.0%} guard -- this is a systematic fault, not a "
            f"model score. Failure modes: {reasons[:5]}"
        )
    strict4 = sum(1 for r in rows if acc1_correct(r.get("modelBPM"), r["groundTruthBPM"]))
    strict2 = sum(
        1 for r in rows if acc_within(r.get("modelBPM"), r["groundTruthBPM"], CONTEXT_TOL)
    )
    floor2 = sum(
        1
        for r in rows
        if tempo2_floor_correct(
            r.get("modelBPM"), r["groundTruthBPM"], r.get("tempo2"), CONTEXT_TOL
        )
    )
    octave4 = sum(1 for r in rows if octave_match(r.get("modelBPM"), r["groundTruthBPM"]))
    acc2 = sum(1 for r in rows if acc2_correct(r.get("modelBPM"), r["groundTruthBPM"], STRICT_TOL))
    return {
        "denominator": n,
        "perTrackFailures": len(failures),
        "protocolRows": {
            "strictAcc1At4pct": {
                "tracks": strict4,
                "protocol": "FR-18 strict Acc1, 4% relative tolerance, no tempo2 fallback,"
                " abstain/decode-failure wrong. GATE ROW (the protocol behind 348/661).",
            },
            "strictAcc1At2pct": {
                "tracks": strict2,
                "protocol": "Strict Acc1, 2% relative tolerance, no tempo2 fallback."
                " Context row only.",
            },
            "tempo2FloorAcc1At2pct": {
                "tracks": floor2,
                "protocol": "Acc1 at 2% tolerance with tempo2 fallback (the DSP benchmark's"
                " 537/661 = 81.2% instrument; Python re-implementation of the Swift"
                " mirexHit metric, equivalence tested on synthetic rows). Context row only.",
            },
            "octaveTolerantAcc1At4pct": {
                "tracks": octave4,
                "protocol": "Acc1 at 4% accepting pred, 2*pred, or pred/2"
                " (evaluate_fr18.octave_match). Context row only.",
            },
            "acc2At4pct": {
                "tracks": acc2,
                "protocol": "Acc2 per the papers: 4% tolerance allowing octave errors by"
                " factors 2 and 3 (2018 paper Section 4). Context row only.",
            },
        },
        "strictMissesOctaveRecoverable": octave4 - strict4,
        "gate": gate_verdict(strict4, n),
    }


def join_tempo2(resolved: list[dict], gt_entries: list[dict]) -> tuple[list[dict], int]:
    """Attach tempo2 to every resolved row. Hard-exits on: duplicate ground-truth ids,
    non-numeric tempo2 values, or any resolved row that fails to join."""
    tempo2_by_id: dict[str, float | None] = {}
    for t in gt_entries:
        key = t.get("filename") or t.get("trackId") or t.get("id")
        if key is None or str(key).strip() == "":
            continue  # un-keyed ground-truth entry cannot join anything
        key = str(key)
        if key in tempo2_by_id:
            raise SystemExit(f"ERROR: duplicate ground-truth id {key!r}; join is ambiguous.")
        tempo2 = t.get("tempo2")
        if tempo2 is not None and (
            isinstance(tempo2, bool) or not isinstance(tempo2, (int, float))
        ):
            raise SystemExit(f"ERROR: non-numeric tempo2 {tempo2!r} for ground-truth id {key!r}.")
        tempo2_by_id[key] = float(tempo2) if tempo2 is not None else None
    rows: list[dict] = []
    for r in resolved:
        tid = r["trackId"]
        if tid not in tempo2_by_id:
            raise SystemExit(f"ERROR: resolved row {tid!r} has no ground-truth join entry.")
        rows.append(
            {
                "trackId": tid,
                "audioPath": r["audioPath"],
                "groundTruthBPM": r["groundTruthBPM"],
                "tempo2": tempo2_by_id[tid],
            }
        )
    # Every resolved row either joined or hard-exited above, so a partial join is
    # unrepresentable; the emitted matchedTempo2Rows is simply len(rows).
    return rows


# ---------------------------------------------------------------------------
# Model run (TensorFlow imported lazily)
# ---------------------------------------------------------------------------


def _featurize(audio_path: str):
    """Published input pipeline (2018 paper Sections 3.1/3.3/3.4). Per-window
    [0, 1] max-normalization; tail frames short of a full window dropped (see module
    docstring). Degenerate audio (non-finite spectrogram or peak <= 0) raises."""
    import librosa
    import numpy as np

    y, _sr = librosa.load(audio_path, sr=11025, mono=True)
    mel = librosa.feature.melspectrogram(
        y=y, sr=11025, n_fft=1024, hop_length=512, power=1, n_mels=40, fmin=20, fmax=5000
    )
    if not np.isfinite(mel).all():
        raise ValueError("degenerate audio: non-finite mel spectrogram")
    if mel.max() <= 0:
        raise ValueError("degenerate audio: spectrogram peak <= 0 (silent or empty input)")
    frames, hop = 256, 128
    if mel.shape[1] < frames:
        padded = np.zeros((mel.shape[0], frames), dtype=mel.dtype)
        padded[:, : mel.shape[1]] = mel
        mel = padded
    windows = []
    for offset in range(0, mel.shape[1] - frames + 1, hop):
        window = mel[:, offset : offset + frames]
        peak = window.max()
        if peak > 0:
            window = window / peak  # per-window rescale to [0, 1] (Section 3.3)
        windows.append(window)
    return np.stack(windows)[:, :, :, None]  # (windows, 40, 256, 1)


def run_model(rows: list[dict], weights_path: Path) -> None:
    """Predict in place: sets modelBPM (or None + failureReason) on each row."""
    import numpy as np
    from tensorflow.keras.models import load_model

    model = load_model(weights_path, compile=False)
    for i, row in enumerate(rows, start=1):
        try:
            batch = _featurize(row["audioPath"])
            prediction = model.predict(batch, verbose=0)
            averaged = prediction.mean(axis=0)
            if not np.isfinite(averaged).all():
                raise ValueError("non-finite model output")
            index = int(averaged.argmax())
            row["modelBPM"] = float(index + 30)  # classes cover BPM 30..285 (Section 3.2)
        except Exception as exc:  # per-track failure counts as wrong, no global abort;
            # a >5% failure rate is refused by score_rows' guard.
            row["modelBPM"] = None
            row["failureReason"] = f"{type(exc).__name__}: {exc}"
        if i % 50 == 0 or i == len(rows):
            print(f"  scored {i}/{len(rows)}", flush=True)


def main() -> int:
    parser = argparse.ArgumentParser(description="Story 12.4 Gate 0 reference baseline")
    parser.add_argument(
        "--weights-dir",
        type=str,
        default=os.environ.get("TEMPOCNN_WEIGHTS_DIR", ""),
        help="Directory holding the reference weights (outside git).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=HERE / "tempocnn-baseline" / "predictions.json",
    )
    ns = parser.parse_args()

    if not ns.weights_dir.strip():
        print("ERROR: TEMPOCNN_WEIGHTS_DIR is not set (or pass --weights-dir).", file=sys.stderr)
        return 1
    weights_dir = Path(ns.weights_dir)

    provenance = json.loads(PROVENANCE_PATH.read_text())
    weights_path = verify_checksums(weights_dir, provenance)
    print(
        f"checksum OK: {weights_path.name}"
        f" sha256={provenance['files'][weights_path.name]['sha256']}"
        f" blob_sha1={provenance['files'][weights_path.name].get('git_blob_sha1', 'n/a')}"
    )

    corpus_path = os.environ.get("GIANTSTEPS_CORPUS_PATH", "")
    if not corpus_path:
        print("ERROR: GIANTSTEPS_CORPUS_PATH is not set.", file=sys.stderr)
        return 1
    resolved = resolve_giantsteps(corpus_path)
    if len(resolved) != EXPECTED_GIANTSTEPS:
        print(
            f"ERROR: resolved {len(resolved)} GiantSteps rows, expected {EXPECTED_GIANTSTEPS}."
            " Refusing to run on a different population.",
            file=sys.stderr,
        )
        return 1

    gt_path = Path(corpus_path) / "giantsteps-tempo-ground-truth.json"
    gt_sha256 = sha256_file(gt_path)
    rows = join_tempo2(resolved, json.loads(gt_path.read_text()))

    print(f"running reference model on {len(rows)} rows ...")
    run_model(rows, weights_path)

    for r in rows:  # machine-specific absolute paths are noise in a tracked artifact
        r["audioPath"] = os.path.basename(r["audioPath"])
    try:
        summary = score_rows(rows)
    except SystemExit:
        # The >5% failure guard tripped. Preserve the completed run's per-track
        # evidence (predictions + failureReason) so the fault can be diagnosed
        # without a re-run. Deliberately NO summary/gate block: a failed run must
        # never be mistakable for a scored artifact.
        failed_path = persist_failed_run(
            ns.output, provenance["model_file"], gt_path.name, gt_sha256, rows
        )
        print(f"wrote {failed_path} (per-track evidence preserved)", file=sys.stderr)
        raise
    out = {
        "story": "12.4",
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "modelVariant": provenance["model_file"],
        "weightsSHA256": provenance["files"][weights_path.name]["sha256"],
        "groundTruthFile": {"basename": gt_path.name, "sha256": gt_sha256},
        "matchedTempo2Rows": len(rows),
        "summary": summary,
        "tracks": rows,
    }
    ns.output.parent.mkdir(parents=True, exist_ok=True)
    ns.output.write_text(json.dumps(out, indent=2))
    print(json.dumps(summary, indent=2))
    print(f"wrote {ns.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
