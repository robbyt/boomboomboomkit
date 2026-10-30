"""Corpus manifests and references for the Story 15.9 evaluation.

Three corpora, each with its own independent reference:

  oa300       The DAW-verified BPMs of `$OA300_CORPUS_PATH/daw-oracle.json`, joined
              to the audio on `identifiers.local_path`. One recording is listed
              twice (the same title as `.mp3` and `.wav`); it counts once, as the
              `.wav`. The commercial analyzer's BPM for each track is read from the
              committed OA300 label file, joined on the same path, together with
              the style tag (`sandbox.genre`). Hand annotations
              (`daw-oracle-annotations.json`, Story 15.8 schema `15.8.v2`) are
              attached when present.
  eval-12-7   The 172 `locked-12.7-member` rows of the bundle-gate seed-42 input
              (verified tempo), read-only. Every audio file is hashed and the run
              refuses, naming the track, if one differs from its recorded sha256.
              Style tag `untagged`.
  giantsteps  The 661 rows of `giantsteps-tempo-ground-truth.json`. Its labels are
              crowdsourced, so every pairing on this corpus is tagged
              `crowdsourced-reference`. Style tag from the label file's `genre`.

Track ids are the ones the Story 15.5 scores files use: the OA300 relative path,
the 12.7 row id, the GiantSteps filename.
"""

from __future__ import annotations

import hashlib
import json
from collections import defaultdict
from pathlib import Path
from typing import Any

import matched_eval  # noqa: F401  (sys.path setup)

ML_TRAINING_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = ML_TRAINING_DIR.parent.parent
OA300_LABELS = (
    REPO_ROOT / "Tests" / "BoomBoomBoomKitBenchmarkTests" / "Fixtures" / ("oa300-ground-truth.json")
)
ORACLE_FILENAME = "daw-oracle.json"
ANNOTATIONS_FILENAME = "daw-oracle-annotations.json"
GIANTSTEPS_LABELS_FILENAME = "giantsteps-tempo-ground-truth.json"

CORPORA = ("oa300", "eval-12-7", "giantsteps")
EXPECTED_COUNTS = {"oa300": 22, "eval-12-7": 172, "giantsteps": 661}
REFERENCE_KIND = {
    "oa300": "daw-verified",
    "eval-12-7": "verified-12.7",
    "giantsteps": "crowdsourced-reference",
}
CROWDSOURCED_TAG = "crowdsourced-reference"
UNTAGGED = "untagged"
ANNOTATION_VERSION = "15.8.v2"
MANIFEST_SCHEMA = "15.9-manifest.v1"
KEPT_DUPLICATE_SUFFIX = ".wav"


class CorpusRefusal(RuntimeError):
    """The corpus inputs are not what the evaluation requires; nothing runs."""


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def _entries(path: Path) -> list[dict[str, Any]]:
    doc = json.loads(path.read_text())
    entries = doc.get("entries") if isinstance(doc, dict) else None
    if not isinstance(entries, list):
        raise CorpusRefusal(f"{path.name}: expected an object with an `entries` list")
    return entries


def jams_tempo(entry: dict[str, Any]) -> float:
    """The first `tempo` observation of a JAMS entry."""
    for ann in entry.get("annotations", []):
        if ann.get("namespace") == "tempo" and ann.get("data"):
            return float(ann["data"][0]["value"])
    raise CorpusRefusal(f"entry {local_path(entry)!r} has no tempo observation")


def local_path(entry: dict[str, Any]) -> str:
    path = entry.get("file_metadata", {}).get("identifiers", {}).get("local_path")
    if not isinstance(path, str) or not path:
        raise CorpusRefusal("entry without identifiers.local_path")
    return path


# ---------------------------------------------------------------------------
# OA300
# ---------------------------------------------------------------------------


def dedupe_recordings(paths: list[str]) -> tuple[list[str], list[str]]:
    """Collapse one recording listed under several audio formats to its `.wav`.

    Paths that differ only in extension are one recording. A group of more than
    one keeps its single `.wav`; a group with no `.wav`, or with two, refuses.
    Returns (kept in input order, dropped)."""
    groups: dict[str, list[str]] = defaultdict(list)
    for p in paths:
        groups[str(Path(p).with_suffix(""))].append(p)
    dropped: list[str] = []
    for stem, members in groups.items():
        if len(members) < 2:
            continue
        wavs = [m for m in members if Path(m).suffix.lower() == KEPT_DUPLICATE_SUFFIX]
        if len(wavs) != 1:
            raise CorpusRefusal(
                f"recording {stem!r} is listed {len(members)} times with {len(wavs)} .wav files"
            )
        dropped.extend(m for m in members if m != wavs[0])
    dropped_set = set(dropped)
    return [p for p in paths if p not in dropped_set], dropped


def load_annotations(path: Path) -> tuple[dict[str, dict[str, Any]], dict[str, Any] | None]:
    """Story 15.8 hand annotations keyed by local path, plus a source record.
    An absent file yields no annotations and no source."""
    if not path.is_file():
        return {}, None
    out: dict[str, dict[str, Any]] = {}
    for entry in _entries(path):
        sandbox = entry.get("sandbox", {})
        version = sandbox.get("annotation_version")
        if version != ANNOTATION_VERSION:
            raise CorpusRefusal(
                f"{path.name}: annotation_version {version!r}, expected {ANNOTATION_VERSION}"
            )
        key = local_path(entry)
        if key in out:
            raise CorpusRefusal(f"{path.name}: two annotations for one track")
        out[key] = normalize_annotation(entry)
    return out, {"name": path.name, "sha256": sha256_file(path), "entries": len(out)}


def normalize_annotation(entry: dict[str, Any]) -> dict[str, Any]:
    """The fields the grid families read, from one `15.8.v2` entry."""
    sandbox = entry["sandbox"]
    bar_lines: list[list[float]] = []
    for ann in entry.get("annotations", []):
        if ann.get("namespace") != "beat_position":
            continue
        for item in ann.get("data", []):
            bar_lines.append([float(item["time"]), float(item["value"]["measure"])])
    bar_lines.sort()
    return {
        "referenceDownbeatSeconds": float(sandbox["reference_downbeat_time_sec"]),
        "spanStartSeconds": float(sandbox["verified_span_start_sec"]),
        "spanEndSeconds": float(sandbox["verified_span_end_sec"]),
        "verifiedBPM": float(sandbox["verified_bpm"]),
        "declaredLevel": sandbox.get("declared_metrical_level"),
        "barPosition": int(sandbox["bar_position"]),
        "barLines": bar_lines,
    }


def load_oa300(oa300_root: Path, labels_path: Path = OA300_LABELS) -> dict[str, Any]:
    """OA300 rows: DAW-verified reference, commercial-analyzer BPM, style tag."""
    oracle_path = oa300_root / ORACLE_FILENAME
    if not oracle_path.is_file():
        raise CorpusRefusal(f"oa300: {ORACLE_FILENAME} not found under the OA300 root")
    oracle = {local_path(e): jams_tempo(e) for e in _entries(oracle_path)}
    kept, dropped = dedupe_recordings(list(oracle))
    labels: dict[str, tuple[float, str | None]] = {}
    for e in _entries(labels_path):
        labels[local_path(e)] = (jams_tempo(e), e.get("sandbox", {}).get("genre"))
    annotations, annotation_source = load_annotations(oa300_root / ANNOTATIONS_FILENAME)

    rows: list[dict[str, Any]] = []
    problems: list[str] = []
    for path in kept:
        audio = oa300_root / path
        if not audio.is_file():
            problems.append(f"{path} (audio missing)")
            continue
        if path not in labels:
            problems.append(f"{path} (not in the OA300 label file)")
            continue
        commercial_bpm, genre = labels[path]
        if not genre:
            problems.append(f"{path} (no style tag)")
            continue
        rows.append(
            {
                "trackId": path,
                "audioPath": str(audio),
                "audioSha256": sha256_file(audio),
                "referenceBPM": oracle[path],
                "style": genre,
                "commercialBPM": commercial_bpm,
                "annotation": annotations.get(path),
            }
        )
    if problems:
        raise CorpusRefusal("oa300: " + ", ".join(problems))
    sources: dict[str, Any] = {
        "reference": {"name": ORACLE_FILENAME, "sha256": sha256_file(oracle_path)},
        "commercialAnalyzer": {"name": labels_path.name, "sha256": sha256_file(labels_path)},
        "duplicateRecordingsDropped": len(dropped),
        "annotations": annotation_source,
        "annotatedTracks": sum(1 for r in rows if r["annotation"] is not None),
    }
    return {"rows": rows, "sources": sources}


# ---------------------------------------------------------------------------
# 12.7 corpus (read-only)
# ---------------------------------------------------------------------------


def load_eval_12_7(bundle_gate_input: Path) -> dict[str, Any]:
    """The 172 locked members, every audio hash verified against the input."""
    from fixed_time.score import ScoreRefusal, load_eval_12_7_rows, verify_audio_hashes

    if not bundle_gate_input.is_file():
        raise CorpusRefusal("eval-12-7: bundle-gate seed-42 input not found")
    base = load_eval_12_7_rows(bundle_gate_input)
    try:
        verify_audio_hashes(base)
    except ScoreRefusal as e:
        raise CorpusRefusal(str(e)) from e
    rows = [
        {
            "trackId": r["trackId"],
            "audioPath": r["audioPath"],
            "audioSha256": r["audioSha256"],
            "referenceBPM": r["groundTruthBPM"],
            "style": UNTAGGED,
            "commercialBPM": None,
            "annotation": None,
        }
        for r in base
    ]
    return {
        "rows": rows,
        "sources": {
            "reference": {"name": bundle_gate_input.name, "sha256": sha256_file(bundle_gate_input)}
        },
    }


# ---------------------------------------------------------------------------
# GiantSteps
# ---------------------------------------------------------------------------


def load_giantsteps(giantsteps_root: Path) -> dict[str, Any]:
    from build_fr18_input import resolve_giantsteps

    labels_path = giantsteps_root / GIANTSTEPS_LABELS_FILENAME
    if not labels_path.is_file():
        raise CorpusRefusal(f"giantsteps: {GIANTSTEPS_LABELS_FILENAME} not found")
    genre = {str(t.get("filename")): t.get("genre") for t in json.loads(labels_path.read_text())}
    rows = []
    for r in resolve_giantsteps(str(giantsteps_root)):
        audio = Path(r["audioPath"])
        rows.append(
            {
                "trackId": r["trackId"],
                "audioPath": str(audio),
                "audioSha256": sha256_file(audio),
                "referenceBPM": float(r["groundTruthBPM"]),
                "style": genre.get(r["trackId"]) or UNTAGGED,
                "commercialBPM": None,
                "annotation": None,
            }
        )
    return {
        "rows": rows,
        "sources": {
            "reference": {"name": labels_path.name, "sha256": sha256_file(labels_path)},
            "referenceTag": CROWDSOURCED_TAG,
        },
    }


# ---------------------------------------------------------------------------
# Manifest
# ---------------------------------------------------------------------------


def check_rows(corpus: str, rows: list[dict[str, Any]]) -> None:
    ids = [r["trackId"] for r in rows]
    if len(set(ids)) != len(ids):
        raise CorpusRefusal(f"{corpus}: duplicate track ids")
    if len(rows) != EXPECTED_COUNTS[corpus]:
        raise CorpusRefusal(f"{corpus}: {len(rows)} tracks, expected {EXPECTED_COUNTS[corpus]}")


def build_manifest(
    corpora: tuple[str, ...],
    *,
    oa300_root: Path | None,
    giantsteps_root: Path | None,
    bundle_gate_input: Path | None,
) -> dict[str, Any]:
    """Resolve and verify every requested corpus before anything runs."""
    out: dict[str, Any] = {}
    for corpus in corpora:
        if corpus == "oa300":
            if oa300_root is None:
                raise CorpusRefusal("OA300_CORPUS_PATH is not set")
            doc = load_oa300(oa300_root)
        elif corpus == "eval-12-7":
            if bundle_gate_input is None:
                raise CorpusRefusal("the legacy root holding eval-corpus/ is not set")
            doc = load_eval_12_7(bundle_gate_input)
        elif corpus == "giantsteps":
            if giantsteps_root is None:
                raise CorpusRefusal("GIANTSTEPS_CORPUS_PATH is not set")
            doc = load_giantsteps(giantsteps_root)
        else:
            raise CorpusRefusal(f"unknown corpus {corpus}")
        check_rows(corpus, doc["rows"])
        doc["referenceKind"] = REFERENCE_KIND[corpus]
        for row in doc["rows"]:
            row["corpus"] = corpus
        out[corpus] = doc
    return {"schema": MANIFEST_SCHEMA, "corpora": out}


def runner_input(manifest: dict[str, Any]) -> dict[str, Any]:
    """The Swift runner's input: track id, corpus, audio path, sha256."""
    tracks = [
        {
            "trackId": r["trackId"],
            "corpus": corpus,
            "audioPath": r["audioPath"],
            "audioSha256": r["audioSha256"],
        }
        for corpus, doc in manifest["corpora"].items()
        for r in doc["rows"]
    ]
    return {"schema": "15.9-runner-input.v1", "tracks": tracks}
