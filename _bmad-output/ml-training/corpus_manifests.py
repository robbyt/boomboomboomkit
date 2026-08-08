"""
Shared emission of the two committed training manifests (develop-only).

One emitter, used by `scripts/non-rekordbox-survey.py` (which produces the
artifacts from scratch) and `scripts/repair-mix-manifests.py` (which repairs
committed ones without the hours-long survey re-run). A second, divergent
generator is how the secondary manifest came to carry 18 DJ mixes while the
unsupervised one was clean.

**Derivation order matters and is not negotiable:**

  1. write the survey
  2. build `pool-durations.json`, stamping `sourceSurveySha256`
  3. emit both manifests from the survey plus that *matching* sidecar

Emitting manifests before the sidecar exists means they cannot record which
duration data produced them, and duration is half the mix predicate.

**Exclusion happens here, at emission — never at tier assignment.** The survey's
`decide_tier()` is deliberately path-blind, and feeding a directory name or a
duration into it would corrupt the tier counts, the sensitivity report and the
provenance audit. A row keeps its honest `secondarySupervised` tier and is simply
not training-eligible. Report both numbers or the gap reads as drift.
"""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path

import corpus_common as cc

# Bump when the predicate, threshold or exemption set changes, so a manifest
# records which policy produced it.
MIX_POLICY_VERSION = "continuous-mix/1"

SURVEY_NAME = "non-rekordbox-survey.json"
DURATIONS_NAME = "pool-durations.json"
SECONDARY_NAME = "non-rekordbox-secondary-supervised-manifest.json"
UNSUPERVISED_NAME = "non-rekordbox-unsupervised-pretrain-manifest.json"


class ManifestError(Exception):
    """An emission or reconciliation invariant did not hold."""


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    # Streamed in 1 MiB chunks: this helper is shared with the Story 12.4 baseline
    # harness, whose weights file is ~12 MB; a read_bytes slurp scales with file size.
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def serialize(payload: dict) -> str:
    """The exact on-disk form. Hash what is written, never a re-serialization."""
    return json.dumps(payload, indent=2, sort_keys=True, allow_nan=False)


# --- durations ---------------------------------------------------------------


def build_duration_rows(survey: dict, audio_root: Path) -> tuple[list[dict], int, int]:
    """Container-header durations for every survey row. No decode."""
    from mutagen import File as MutagenFile

    rows: list[dict] = []
    missing = unreadable = 0
    for track in survey["tracks"]:
        rel = track.get("path")
        if not rel:
            continue
        full = Path(audio_root) / rel
        if not full.exists():
            missing += 1
            continue
        try:
            info = getattr(MutagenFile(str(full)), "info", None)
            seconds = getattr(info, "length", None)
        except Exception:  # noqa: BLE001 - any decoder complaint means unusable
            seconds = None
        if not isinstance(seconds, (int, float)) or seconds <= 0:
            unreadable += 1
            continue
        rows.append({"relPath": rel, "seconds": round(float(seconds), 2)})
    rows.sort(key=lambda r: r["relPath"])
    return rows, unreadable, missing


def durations_payload(rows: list[dict], unreadable: int, missing: int, survey_sha: str) -> dict:
    return {
        "schema_version": 2,
        "note": (
            "Container-header durations for the non-Rekordbox pool, joined to the "
            "survey on `path`. Used only to identify continuous DJ mixes; never a "
            "training feature."
        ),
        "sourceSurveySha256": survey_sha,
        "mixPolicyVersion": MIX_POLICY_VERSION,
        "count": len(rows),
        "unreadable": unreadable,
        "missing": missing,
        "rows": rows,
    }


def load_durations(path: Path) -> tuple[dict[str, float], str]:
    """Return (relPath -> seconds, sidecar sha). Raises if absent or malformed."""
    path = Path(path)
    if not path.exists():
        raise ManifestError(
            f"{path.name} not found. Duration is half the mix predicate, so emitting "
            f"without it would silently treat every unknown duration as 'not a mix'. "
            f"Run `make pool-durations`."
        )
    raw = path.read_bytes()
    data = json.loads(raw.decode("utf-8"))
    rows = data.get("rows")
    if not isinstance(rows, list):
        raise ManifestError(f"{path.name} has no `rows` list.")
    out: dict[str, float] = {}
    for row in rows:
        rel, secs = row.get("relPath"), row.get("seconds")
        if not isinstance(rel, str) or not isinstance(secs, (int, float)):
            raise ManifestError(f"{path.name}: malformed row {row!r}")
        out[rel] = float(secs)
    return out, sha256_bytes(raw)


# --- emission ----------------------------------------------------------------


def _partition(
    rows: list[dict], tier: str, durations: dict[str, float], apply_exclusion: bool = True
):
    """Split a tier's rows into training-eligible and excluded-as-mix.

    Duration completeness is required for *candidates only*. The rows with no
    duration entry are the container-unreadable ones, which are `reject` tier and
    therefore never candidates; if that ever stops being true this raises rather
    than defaulting them to 'not a mix'.
    """
    keep, dropped = [], []
    for r in rows:
        if r["tier"] != tier:
            continue
        rel = r["path"]
        if not apply_exclusion:
            # Reconciliation only: reproduce the pre-policy rows so a repair can
            # prove today's survey still projects to the committed artifact.
            keep.append(r)
            continue
        if rel not in durations:
            raise ManifestError(
                f"{tier} candidate has no duration entry: {rel!r}. Regenerate the "
                f"sidecar (`make pool-durations`); an unknown duration must never "
                f"be read as 'not a mix'."
            )
        (dropped if cc.is_continuous_mix(rel, durations[rel]) else keep).append(r)
    return keep, dropped


def _provenance(survey_sha: str, sidecar_sha: str, excluded: int, tiered: int) -> dict:
    return {
        "sourceSurveySha256": survey_sha,
        "durationsSha256": sidecar_sha,
        "mixPolicyVersion": MIX_POLICY_VERSION,
        "tieredRowCount": tiered,
        "excludedContinuousMixes": excluded,
    }


def emit_secondary(
    rows, durations, survey_sha, sidecar_sha, apply_exclusion: bool = True
) -> tuple[dict, int]:
    keep, dropped = _partition(rows, "secondarySupervised", durations, apply_exclusion)
    payload = {
        "schema_version": 2,
        "audioHash_derivation": "corpus_common.file_sha256 (raw audio bytes) — pinned join key",
        "note": (
            "Story 7.3 supervised-augmented loader: use relPath ONLY to fetch bytes "
            "(never as a feature); read bpm_truth as the label. Continuous DJ mixes "
            "are excluded at emission; the survey tier is left honest, so "
            "`tieredRowCount` exceeding the row count is expected, not drift."
        ),
        "derivation": _provenance(survey_sha, sidecar_sha, len(dropped), len(keep) + len(dropped)),
        "secondarySupervised": [
            {
                "audioHash": r["audioHash"],
                "relPath": r["path"],
                "bpm_truth": r["bpm_truth"],
                "labelConfidence": r["labelConfidence"],
            }
            for r in keep
        ],
    }
    return payload, len(dropped)


def emit_unsupervised(
    rows, durations, survey_sha, sidecar_sha, apply_exclusion: bool = True
) -> tuple[dict, int]:
    keep, dropped = _partition(rows, "unsupervisedPool", durations, apply_exclusion)
    for r in keep:
        if not r.get("audioHash") or not r.get("path"):
            raise ManifestError(f"unsupervisedPool row missing audioHash/path: {r!r}")
    payload = {
        "schema_version": 2,
        "audioHash_derivation": "corpus_common.file_sha256 (raw audio bytes) — pinned join key",
        "note": (
            "Story 7.3 masked-mel pretraining corpus (label-free). Use relPath ONLY "
            "to fetch bytes (never as a feature); NO labels. Continuous DJ mixes are "
            "excluded at emission; the survey tier is left honest, so "
            "`tieredRowCount` exceeding the row count is expected, not drift."
        ),
        "derivation": _provenance(survey_sha, sidecar_sha, len(dropped), len(keep) + len(dropped)),
        "unsupervisedPool": [{"audioHash": r["audioHash"], "relPath": r["path"]} for r in keep],
    }
    return payload, len(dropped)


# --- reconciliation ----------------------------------------------------------


def projects_to(payload: dict, committed_path: Path, key: str) -> tuple[bool, str]:
    """Does a freshly-emitted manifest reproduce the committed one's rows exactly?

    This is the precondition for stamping provenance onto a repaired artifact. The
    committed manifests were produced by a survey run whose bytes are gone; without
    this check, stamping today's survey SHA would be a retroactive fiction rather
    than an attestation. Compares rows only -- the added `derivation` block and the
    schema bump are the repair's own contribution.
    """
    committed = json.loads(Path(committed_path).read_text())
    old = committed.get(key)
    if not isinstance(old, list):
        return False, f"committed {Path(committed_path).name} has no `{key}` list"
    new = payload[key]
    if len(old) != len(new):
        return False, f"row count {len(old)} -> {len(new)} before exclusions were applied"
    for i, (a, b) in enumerate(zip(old, new)):
        if a != b:
            return False, f"row {i} differs: {a!r} != {b!r}"
    return True, f"{len(old)} rows reproduce exactly, in order"


def default_paths(ml_training_dir: Path | None = None) -> dict[str, Path]:
    base = Path(ml_training_dir or os.path.dirname(os.path.abspath(__file__)))
    return {
        "survey": base / SURVEY_NAME,
        "durations": base / DURATIONS_NAME,
        "secondary": base / SECONDARY_NAME,
        "unsupervised": base / UNSUPERVISED_NAME,
    }
