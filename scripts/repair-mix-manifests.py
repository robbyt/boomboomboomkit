#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# ///
"""
Repair the committed training manifests in place (develop-only, one-time).

The two manifests are produced by `non-rekordbox-survey.py`, which decodes the
whole pool and takes hours. When the continuous-mix exclusion landed, the
unsupervised manifest was rebuilt and the secondary one was not, so it kept 18 DJ
mixes -- as *supervised* rows, each carrying a single BPM label on an hour-long
multi-tempo recording.

This re-emits both through the shared emitter in `corpus_manifests`, so the
repaired artifacts are byte-identical to what a fresh survey run would now write.

**It refuses to stamp provenance unless the pre-repair rows reconcile exactly.**
The committed manifests came from a survey run whose bytes are gone. Stamping
today's survey SHA is only honest if today's survey still projects to those
committed rows; if it does not, the artifacts came from a different snapshot and
this stops rather than writing a false attestation.

Run: `make repair-mix-manifests`
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
ML_TRAINING_DIR = REPO_ROOT / "_bmad-output" / "ml-training"
sys.path.insert(0, str(ML_TRAINING_DIR))

import corpus_manifests as cm  # noqa: E402  (runtime sys.path insert above)

EXIT_MISSING = 2
EXIT_RECONCILE = 3


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Re-emit the committed training manifests.")
    ap.add_argument(
        "--check",
        action="store_true",
        help="report what would change; write nothing",
    )
    args = ap.parse_args(argv)

    paths = cm.default_paths(ML_TRAINING_DIR)
    if not paths["survey"].exists():
        print(
            f"ERROR: {paths['survey'].name} not found (gitignored, develop-only). "
            "Run `make non-rekordbox-survey` first.",
            file=sys.stderr,
        )
        return EXIT_MISSING

    survey_bytes = paths["survey"].read_bytes()
    survey = json.loads(survey_bytes.decode("utf-8"))
    survey_sha = cm.sha256_bytes(survey_bytes)

    try:
        durations, sidecar_sha = cm.load_durations(paths["durations"])
    except cm.ManifestError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return EXIT_MISSING

    stamped = json.loads(paths["durations"].read_text()).get("sourceSurveySha256")
    if stamped and stamped != survey_sha:
        print(
            f"ERROR: {paths['durations'].name} was built from a different survey "
            f"snapshot ({stamped[:12]}... vs {survey_sha[:12]}...). "
            "Re-run `make pool-durations`.",
            file=sys.stderr,
        )
        return EXIT_RECONCILE

    rows = survey["tracks"]
    try:
        secondary, sec_dropped = cm.emit_secondary(rows, durations, survey_sha, sidecar_sha)
        unsup, uns_dropped = cm.emit_unsupervised(rows, durations, survey_sha, sidecar_sha)
    except cm.ManifestError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return EXIT_RECONCILE

    # Reconciliation gate: re-emit WITHOUT the exclusion and require it to
    # reproduce the committed rows. That is what licenses the provenance stamp.
    pre_sec, _ = cm.emit_secondary(rows, durations, survey_sha, sidecar_sha, apply_exclusion=False)
    pre_uns, _ = cm.emit_unsupervised(
        rows, durations, survey_sha, sidecar_sha, apply_exclusion=False
    )

    failures = []
    for name, pre, post, committed, key in (
        ("secondary", pre_sec, secondary, paths["secondary"], "secondarySupervised"),
        ("unsupervised", pre_uns, unsup, paths["unsupervised"], "unsupervisedPool"),
    ):
        # A manifest is either not yet repaired (matches the pre-exclusion
        # emission) or already repaired (matches the post-exclusion one). Accept
        # either, so re-running is a no-op rather than a false alarm; anything
        # else means the committed artifact came from a different survey snapshot
        # and stamping this survey's SHA onto it would be a fiction.
        ok_pre, detail_pre = cm.projects_to(pre, committed, key)
        ok_post, detail_post = cm.projects_to(post, committed, key)
        if ok_pre:
            print(f"  reconcile {name:13s}: OK (pre-repair) — {detail_pre}")
        elif ok_post:
            print(f"  reconcile {name:13s}: OK (already repaired) — {detail_post}")
        else:
            print(f"  reconcile {name:13s}: MISMATCH — {detail_pre}")
            failures.append(name)

    if failures:
        print(
            "\nERROR: today's survey does not project to the committed manifest(s): "
            f"{failures}. They came from a different snapshot, so stamping this "
            "survey's SHA would be a false provenance claim. Stopping.",
            file=sys.stderr,
        )
        return EXIT_RECONCILE

    print(
        f"\n  secondarySupervised: tiered {secondary['derivation']['tieredRowCount']} "
        f"-> training-eligible {len(secondary['secondarySupervised'])} "
        f"({sec_dropped} continuous mixes excluded)"
    )
    print(
        f"  unsupervisedPool:    tiered {unsup['derivation']['tieredRowCount']} "
        f"-> training-eligible {len(unsup['unsupervisedPool'])} "
        f"({uns_dropped} continuous mixes excluded)"
    )

    if args.check:
        print("\n--check: nothing written.")
        return 0

    for payload, path in ((secondary, paths["secondary"]), (unsup, paths["unsupervised"])):
        path.write_text(cm.serialize(payload) + "\n", encoding="utf-8")
        print(f"  wrote {path.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
