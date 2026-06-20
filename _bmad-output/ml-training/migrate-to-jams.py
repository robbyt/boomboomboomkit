"""Story 8.8 — one-time migration of flat ground-truth artifacts to JAMS 0.4.

Develop-only (NOT shipped to main). Converts the flat per-track ground-truth JSON
artifacts to the JAMS `tempo`-namespace corpus shape the shared decoder
(`Sources/BoomBoomBoomKitTestSupport/JAMS/JAMSDecoder.swift`, Story 8.8a) reads.

Per-track mapping (oa300 / daw):
  - bpm/daw_bpm -> a single `tempo` observation {time:0, duration:0, value:bpm,
    confidence:1.0}
  - title      -> file_metadata.title + identifiers.track_id
  - filename   -> identifiers.basename
  - subdir     -> identifiers.local_path ("<subdir>/<basename>") + sandbox.subdir
  - genre (oa300) / rekordbox cross-check (daw) -> per-entry sandbox

Every emitted entry's file_metadata carries `duration` (0 when unknown) and
`jams_version` so each `entries[i]` is standalone `jams.load`-valid — the Python side
cannot lean on the Swift encoder's fallbacks (Codex round-1 P2).

Idempotent but validating: an already-JAMS input (top-level `entries`) is NOT rewritten,
but is still checked against the artifact-specific minimum shape and a failure exits
non-zero — never a blind skip (Codex round-1 P3).

The DnB regression-config artifact (`--artifact dnb`, Story 8.8c) is the
pressure-release-valve case: it is a nested config dict, not a flat per-track array, so
its per-track tempo truth routes to `tempo` observations while its non-tempo fields route
to `sandbox` — per-entry (`partition`, `source`, predicted-bpm, abs-error, `rationale`)
and corpus-level (`schema_version`, `regression_threshold`, `captured_with`).

Usage:
  uv run python migrate-to-jams.py --artifact oa300 \
      --input Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json \
      --report _bmad-output/implementation-artifacts/8-8-migration-report.md
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any, cast

JAMS_VERSION = "0.4.0"

DATA_SOURCE: dict[str, str] = {
    "oa300": "OA300 hand-labeled ground truth",
    "daw": "DAW manual placement",
    "dnb": "DnB triplet challenge set, manually verified",
}


def git_config(key: str, fallback: str) -> str:
    """Read a `git config` value, falling back if git is unavailable or the value is empty."""
    try:
        out = subprocess.run(["git", "config", key], capture_output=True, text=True, check=True)
    except (OSError, subprocess.CalledProcessError):
        return fallback
    value = out.stdout.strip()
    return value if value else fallback


def get_curator() -> dict[str, str]:
    """Curator identity from git config (AC 5); fall back to the operator name."""
    return {
        "name": git_config("user.name", "Robert Terhaar"),
        "email": git_config("user.email", "robbyt@gmail.com"),
    }


def jams_entry(
    *,
    title: str | None,
    basename: str,
    subdir: str | None,
    bpm: float,
    data_source: str,
    curator: dict[str, str],
    sandbox_extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Build one standalone-valid JAMS entry carrying a single `tempo` observation."""
    local_path = f"{subdir}/{basename}" if subdir else basename
    file_metadata: dict[str, Any] = {
        "duration": 0,
        "jams_version": JAMS_VERSION,
        "identifiers": {
            "basename": basename,
            "local_path": local_path,
            "track_id": title if title else basename,
        },
    }
    if title is not None:
        file_metadata["title"] = title

    sandbox: dict[str, Any] = {}
    if subdir is not None:
        sandbox["subdir"] = subdir
    if sandbox_extra:
        sandbox.update(sandbox_extra)

    entry: dict[str, Any] = {
        "file_metadata": file_metadata,
        "annotations": [
            {
                "namespace": "tempo",
                "data": [{"time": 0.0, "duration": 0.0, "value": bpm, "confidence": 1.0}],
                "annotation_metadata": {
                    "curator": curator,
                    "data_source": data_source,
                },
            }
        ],
    }
    if sandbox:
        entry["sandbox"] = sandbox
    return entry


def convert_oa300(rows: list[dict[str, Any]], curator: dict[str, str]) -> dict[str, Any]:
    entries = [
        jams_entry(
            title=row["title"],
            basename=row["filename"],
            subdir=row.get("subdir"),
            bpm=float(row["bpm"]),
            data_source=DATA_SOURCE["oa300"],
            curator=curator,
            sandbox_extra={"genre": row["genre"]},
        )
        for row in rows
    ]
    return {"entries": entries}


def convert_daw(rows: list[dict[str, Any]], curator: dict[str, str]) -> dict[str, Any]:
    entries = [
        jams_entry(
            title=None,
            basename=row["filename"],
            subdir=row.get("subdir"),
            bpm=float(row["daw_bpm"]),
            data_source=DATA_SOURCE["daw"],
            curator=curator,
            sandbox_extra={
                "rekordbox_bpm": float(row["rekordbox_bpm"]),
                "rekordbox_disagrees": bool(row["rekordbox_disagrees"]),
                "disagreement_type": row.get("disagreement_type"),
            },
        )
        for row in rows
    ]
    return {"entries": entries}


def convert_dnb(doc: dict[str, Any], curator: dict[str, str]) -> dict[str, Any]:
    """Convert the nested DnB regression config to a JAMS corpus (Story 8.8c).

    Per-track tempo truth (`ground_truth_bpm`) rides a `tempo` observation; the
    per-track regression fields (`source`, `current_predicted_bpm`, `current_abs_error`,
    `rationale`) plus a `partition` discriminator (`target` / `control`) ride the
    per-entry sandbox. The config/provenance that is NOT per-track —
    `schema_version`, `regression_threshold`, `captured_with` — rides the CORPUS-level
    sandbox on the `{entries, sandbox}` wrapper (the JAMS extension point). No source
    field is dropped.
    """

    def entry_for(row: dict[str, Any], partition: str) -> dict[str, Any]:
        sandbox_extra: dict[str, Any] = {
            "partition": partition,
            "source": row["source"],
            "current_predicted_bpm": float(row["current_predicted_bpm"]),
            "current_abs_error": float(row["current_abs_error"]),
        }
        if "rationale" in row:
            sandbox_extra["rationale"] = row["rationale"]
        return jams_entry(
            title=None,
            basename=row["track_id"],
            subdir=None,
            bpm=float(row["ground_truth_bpm"]),
            data_source=DATA_SOURCE["dnb"],
            curator=curator,
            sandbox_extra=sandbox_extra,
        )

    entries = [entry_for(row, "target") for row in doc["targets"]]
    entries += [entry_for(row, "control") for row in doc["dsp_correct_controls"]]
    return {
        "entries": entries,
        "sandbox": {
            "schema_version": doc["schema_version"],
            "regression_threshold": doc["regression_threshold"],
            "captured_with": doc["captured_with"],
        },
    }


CONVERTERS = {"oa300": convert_oa300, "daw": convert_daw, "dnb": convert_dnb}


def validate_jams(doc: dict[str, Any], artifact: str) -> None:
    """Validate an already-JAMS document against the artifact minimum shape.

    Raises SystemExit(1) on any failure so an idempotent re-run cannot mask a bad
    partial migration (Codex round-1 P3).
    """
    entries = doc.get("entries")
    if not isinstance(entries, list) or not entries:
        raise SystemExit(f"[{artifact}] already-JAMS but `entries` is missing or empty")
    for i, raw_entry in enumerate(entries):
        if not isinstance(raw_entry, dict):
            raise SystemExit(f"[{artifact}] entry {i} is not a JSON object")
        entry = cast("dict[str, Any]", raw_entry)
        annotations = entry.get("annotations", [])
        tempo = next((a for a in annotations if a.get("namespace") == "tempo"), None)
        if tempo is None:
            raise SystemExit(f"[{artifact}] entry {i} has no `tempo` annotation")
        first = (tempo.get("data") or [{}])[0]
        value = first.get("value")
        if not isinstance(value, (int, float)):
            raise SystemExit(f"[{artifact}] entry {i} tempo `value` is not numeric")
        if artifact == "oa300":
            genre = (entry.get("sandbox") or {}).get("genre")
            if not isinstance(genre, str) or not genre.strip():
                raise SystemExit(f"[{artifact}] entry {i} missing sandbox.genre")
        if artifact == "dnb":
            partition = (entry.get("sandbox") or {}).get("partition")
            if partition not in ("target", "control"):
                raise SystemExit(f"[{artifact}] entry {i} sandbox.partition is not target/control")
    if artifact == "dnb":
        corpus_sandbox = doc.get("sandbox") or {}
        if not isinstance(corpus_sandbox.get("schema_version"), int):
            raise SystemExit(f"[{artifact}] corpus sandbox missing schema_version")
        if not isinstance(corpus_sandbox.get("regression_threshold"), dict):
            raise SystemExit(f"[{artifact}] corpus sandbox missing regression_threshold")


def sandbox_fields(artifact: str) -> str:
    return {
        "oa300": "genre, subdir",
        "daw": "rekordbox_bpm, rekordbox_disagrees, disagreement_type, subdir",
        "dnb": "partition, source, current_predicted_bpm, current_abs_error, rationale "
        "(+ corpus-level schema_version, regression_threshold, captured_with)",
    }[artifact]


def upsert_report(report_path: Path, row: dict[str, str]) -> None:
    """Idempotently upsert a per-artifact row into the migration report table."""
    header = (
        "# Story 8-8 migration report\n\n"
        "One-time flat-JSON -> JAMS 0.4 migration (Stories 8.8b/8.8c). Develop-only.\n\n"
        "| artifact | input shape | output namespace | entries | curator | "
        "sandbox-routed fields |\n"
        "|---|---|---|---|---|---|\n"
    )
    cells = (
        f"| {row['artifact']} | {row['input_shape']} | {row['namespace']} | "
        f"{row['entries']} | {row['curator']} | {row['fields']} |\n"
    )
    existing = report_path.read_text() if report_path.exists() else header
    lines: list[str] = [
        line
        for line in existing.splitlines(keepends=True)
        if not line.startswith(f"| {row['artifact']} |")
    ]
    if not any(line.startswith("| artifact |") for line in lines):
        lines = [str(line) for line in header.splitlines(keepends=True)]
    lines.append(cells)
    report_path.write_text("".join(lines))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--artifact", required=True, choices=sorted(CONVERTERS))
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", type=Path, help="defaults to --input (in-place overwrite)")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    artifact: str = args.artifact
    input_path: Path = args.input
    output_path: Path = args.output if args.output else input_path

    doc = json.loads(input_path.read_text())

    if isinstance(doc, dict) and "entries" in doc:
        validate_jams(doc, artifact)
        entries = doc["entries"]
        print(f"[{artifact}] already JAMS ({len(entries)} entries) — validated, no rewrite")
        if args.report:
            upsert_report(
                args.report,
                {
                    "artifact": input_path.name,
                    "input_shape": "already-JAMS (valid)",
                    "namespace": "tempo",
                    "entries": str(len(entries)),
                    "curator": get_curator()["name"],
                    "fields": sandbox_fields(artifact),
                },
            )
        return 0

    # oa300/daw are flat arrays (one row -> one entry); dnb is a nested config dict
    # (targets[] + dsp_correct_controls[] -> entries, the rest -> corpus sandbox).
    if artifact == "dnb":
        if not isinstance(doc, dict):
            raise SystemExit(f"[dnb] expected a JSON object, got {type(doc).__name__}")
        input_shape = "nested config"
    else:
        if not isinstance(doc, list):
            raise SystemExit(f"[{artifact}] expected a flat JSON array, got {type(doc).__name__}")
        input_shape = "flat array"

    curator = get_curator()
    result = CONVERTERS[artifact](doc, curator)
    output_path.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n")
    entry_count = len(result["entries"])
    print(
        f"[{artifact}] migrated {entry_count} entries ({input_shape}) "
        f"-> JAMS tempo corpus at {output_path}"
    )

    if args.report:
        upsert_report(
            args.report,
            {
                "artifact": input_path.name,
                "input_shape": input_shape,
                "namespace": "tempo",
                "entries": str(entry_count),
                "curator": curator["name"],
                "fields": sandbox_fields(artifact),
            },
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
