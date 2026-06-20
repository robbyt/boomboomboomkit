"""Read the migrated JAMS `tempo` corpora back into the flat row shape the ML-training
pipeline consumes (Story 8.8b).

The on-disk ground-truth artifacts are JAMS 0.4 (`{ "entries": [ <JAMSFile> ] }`) after the
Story 8.8 migration; the existing readers want `{filename, bpm, subdir, title, genre}` dicts.
This helper bridges the two so the readers change only at the load call.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def _entries(doc: Any, path: Path) -> list[dict[str, Any]]:
    if not isinstance(doc, dict) or "entries" not in doc:
        raise ValueError(f"{path} is not a JAMS corpus (expected a top-level 'entries' list)")
    entries = doc["entries"]
    if not isinstance(entries, list):
        raise ValueError(f"{path} 'entries' is not a list")
    return entries


def _tempo_value(entry: dict[str, Any], path: Path) -> float:
    for ann in entry.get("annotations", []):
        if ann.get("namespace") == "tempo":
            data = ann.get("data") or []
            if data and isinstance(data[0].get("value"), (int, float)):
                return float(data[0]["value"])
    raise ValueError(f"{path}: a JAMS entry has no numeric tempo observation")


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
                "bpm": _tempo_value(entry, path),
                "subdir": sandbox.get("subdir"),
                "title": file_metadata.get("title"),
                "genre": sandbox.get("genre"),
            }
        )
    return rows
