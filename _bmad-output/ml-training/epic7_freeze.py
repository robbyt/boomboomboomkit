"""FR-20 reproducibility freeze (Story 7.7 AC7 / Task 5).

Develop-only. Freezes ``training_log.json`` + ``model_metadata.json`` at Epic-7
close and stamps two NET-NEW epic-global fields (DD #8):
  - ``epic7CloseDecision``: reuses 7.6's EXACT KDD-B5 literals ``"bundle"`` /
    ``"byow"`` (NOT the epic prose's ``"bundled"/"byowOnly"``), so a
    freeze<->decision audit join matches identical strings (John).
  - ``gitTag``: ``"epic-7-close"``.

This is a SEPARATE module — NOT an extension of
``train_v2_artifacts.build_seed_metadata``, which is per-seed and ``raise``s on
``seed not in SEEDS`` (the wrong home for an epic-global fact — Amelia). It
stamps the frozen metadata and, when present, the per-seed metadata files (each
bundled checkpoint records the close decision for audit join).

Dev smoke writes ``"byow"``; the authoritative value is operator-set after the
FR-25 + holdout-gap outcome via the DD #14 downgrade-only decision DAG.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
GIT_TAG = "epic-7-close"
VALID_DECISIONS = ("bundle", "byow")


def freeze_metadata(meta: dict[str, Any], decision: str, git_tag: str = GIT_TAG) -> dict[str, Any]:
    """Return ``meta`` with the two net-new epic-global fields stamped (DD #8).

    Pure; validates the decision literal against 7.6's KDD-B5 enum.
    """
    if decision not in VALID_DECISIONS:
        raise ValueError(f"epic7CloseDecision must be one of {VALID_DECISIONS} (got {decision!r})")
    out = dict(meta)
    out["epic7CloseDecision"] = decision
    out["gitTag"] = git_tag
    return out


def _stamp_file(path: Path, decision: str) -> bool:
    if not path.exists():
        return False
    meta = json.loads(path.read_text())
    path.write_text(json.dumps(freeze_metadata(meta, decision), indent=2, allow_nan=False))
    return True


def main() -> int:
    ap = argparse.ArgumentParser(description="FR-20 Epic-7 reproducibility freeze (Story 7.7)")
    ap.add_argument("--decision", choices=VALID_DECISIONS, default="byow", help="KDD-B5 outcome")
    ap.add_argument("--metadata", type=Path, default=HERE / "model_metadata.json")
    ap.add_argument("--training-log", type=Path, default=HERE / "training_log.json")
    ap.add_argument(
        "--seed-metadata-glob",
        default="model_metadata_seed_*.json",
        help="per-seed metadata files to also stamp (audit join)",
    )
    ns = ap.parse_args()

    stamped = []
    if _stamp_file(ns.metadata, ns.decision):
        stamped.append(ns.metadata.name)
    # FR-20 freezes BOTH training_log.json + model_metadata.json (AC7) — stamp the
    # close decision/tag into the training log too so the reproducibility record
    # is self-describing (code-review: the docstring/AC name it, so touch it).
    if _stamp_file(ns.training_log, ns.decision):
        stamped.append(ns.training_log.name)
    for p in sorted(HERE.glob(ns.seed_metadata_glob)):
        if _stamp_file(p, ns.decision):
            stamped.append(p.name)

    if not stamped:
        raise FileNotFoundError(
            f"no files to freeze (looked for {ns.metadata}, {ns.training_log} + {ns.seed_metadata_glob})"
        )
    print(f"epic7-freeze: decision={ns.decision} gitTag={GIT_TAG} -> stamped {stamped}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
