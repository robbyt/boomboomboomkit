"""Read the migrated JAMS `tempo` corpora back into the flat row shape the ML-training
pipeline consumes (Story 8.8b).

The on-disk ground-truth artifacts are JAMS 0.4 (`{ "entries": [ <JAMSFile> ] }`) after the
Story 8.8 migration; the existing readers want `{filename, bpm, subdir, title, genre}` dicts.
This helper bridges the two so the readers change only at the load call.
"""

from __future__ import annotations

import json
import math
from pathlib import Path
from typing import Any, TypeGuard


def is_json_number(x: object) -> TypeGuard[float]:
    """True iff `x` is a real (non-`bool`) finite JSON number. Mirrors Swift JSON decoding:
    `bool` is an `int` subclass in Python, and `json` parses `NaN`/`Infinity` into floats —
    both must be rejected for a valid JAMS tempo `value`. The project-wide tempo-number guard
    (also imported by `migrate-to-jams.py`); `scripts/dawproject-bpm.py` keeps its own copy as a
    different uv project that cannot import this module."""
    return not isinstance(x, bool) and isinstance(x, (int, float)) and math.isfinite(x)


def _entries(doc: Any, path: Path) -> list[dict[str, Any]]:
    if not isinstance(doc, dict) or "entries" not in doc:
        raise ValueError(f"{path} is not a JAMS corpus (expected a top-level 'entries' list)")
    entries = doc["entries"]
    if not isinstance(entries, list):
        raise ValueError(f"{path} 'entries' is not a list")
    return entries


def tempo_value(entry: dict[str, Any], path: Path) -> float:
    """The entry's canonical tempo BPM: the first `tempo` annotation's first observation value.

    Structurally defensive — a non-list `annotations`, non-dict annotation, non-list/empty
    `data`, non-dict observation, or a missing/`None`/bool/`NaN`/`Inf` `value` all fall through
    to the one path-sourced `ValueError` (never a leaked `TypeError`/`KeyError`). The FIRST
    `tempo` annotation is authoritative: if it is malformed, fail loudly rather than scanning
    past it (which would hide fixture corruption / duplicate-tempo ambiguity)."""
    annotations = entry.get("annotations")
    if isinstance(annotations, list):
        for ann in annotations:
            if isinstance(ann, dict) and ann.get("namespace") == "tempo":
                data = ann.get("data")
                if isinstance(data, list) and data and isinstance(data[0], dict):
                    value = data[0].get("value")
                    if is_json_number(value):
                        return float(value)
                break  # first tempo annotation is authoritative; don't scan past a bad one
    raise ValueError(f"{path}: a JAMS entry has no finite numeric tempo observation")


def load_oa300_rows(path: str | Path) -> list[dict[str, Any]]:
    """Flat `{filename, bpm, subdir, title, genre}` rows from a migrated oa300 JAMS corpus."""
    path = Path(path)
    doc = json.loads(path.read_text())
    rows: list[dict[str, Any]] = []
    for entry in _entries(doc, path):
        file_metadata = entry.get("file_metadata", {})
        identifiers = file_metadata.get("identifiers", {})
        sandbox = entry.get("sandbox", {})
        rows.append(
            {
                "filename": identifiers.get("basename"),
                "bpm": tempo_value(entry, path),
                "subdir": sandbox.get("subdir"),
                "title": file_metadata.get("title"),
                "genre": sandbox.get("genre"),
            }
        )
    return rows
