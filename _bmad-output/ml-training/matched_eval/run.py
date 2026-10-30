"""CLI for the Story 15.9 evaluation (`make matched-eval`).

  prepare   resolve and verify the corpora; write manifest.json and
            runner-input.json to the run directory
  swift     run the Swift runner on runner-input.json -> runner-output.json
  report    join manifest, runner output and the 15.5 scores; write rows.json to
            the run directory and the tracked aggregate (JSON and Markdown)
  all       prepare, swift, report

The run directory is `<run-root>/<git sha>[-dirty]` and is gitignored. The
tracked aggregate is `<artifact-dir>/15-9-matched-eval-<git sha>[-dirty].{json,md}`.
"Dirty" means tracked files differ from HEAD; untracked files are counted
separately in the aggregate's digests.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any

from matched_eval import corpora as cp
from matched_eval import report as rp

ML_TRAINING_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = ML_TRAINING_DIR.parent.parent
DEFAULT_RUN_ROOT = ML_TRAINING_DIR / "matched-eval-runs"
DEFAULT_ARTIFACT_DIR = REPO_ROOT / "_bmad-output" / "implementation-artifacts"
BUNDLE_GATE_INPUT_RELPATH = Path(
    "eval-corpus/bundle-gate/predictions/bundle-gate-input-seed-42.json"
)
EXIT_REFUSED = 3


def git_state() -> dict[str, Any]:
    def run(*args: str) -> str:
        return subprocess.check_output(["git", *args], cwd=str(REPO_ROOT), text=True).strip()

    try:
        sha = run("rev-parse", "HEAD")
        tracked = run("status", "--porcelain", "--untracked-files=no")
        untracked = run("status", "--porcelain")
    except (OSError, subprocess.CalledProcessError):
        return {"sha": "unknown", "dirty": True, "untrackedPaths": None}
    untracked_count = sum(1 for line in untracked.splitlines() if line.startswith("??"))
    return {"sha": sha, "dirty": bool(tracked), "untrackedPaths": untracked_count}


def run_dir_for(run_root: Path, git: dict[str, Any]) -> Path:
    return run_root / (git["sha"] + ("-dirty" if git["dirty"] else ""))


def write_json(path: Path, doc: Any) -> str:
    data = rp.canonical_json(doc)
    tmp = path.with_name(f".{path.name}.tmp{os.getpid()}")
    tmp.write_bytes(data)
    tmp.replace(path)
    return rp.sha256_bytes(data)


def prepare(args: argparse.Namespace, run_dir: Path) -> None:
    corpora = tuple(args.corpus) if args.corpus else cp.CORPORA
    manifest = cp.build_manifest(
        corpora,
        oa300_root=Path(args.oa300_root) if args.oa300_root else None,
        giantsteps_root=Path(args.giantsteps_root) if args.giantsteps_root else None,
        bundle_gate_input=(
            Path(args.legacy_root) / BUNDLE_GATE_INPUT_RELPATH if args.legacy_root else None
        ),
    )
    run_dir.mkdir(parents=True, exist_ok=True)
    write_json(run_dir / "manifest.json", manifest)
    write_json(run_dir / "runner-input.json", cp.runner_input(manifest))
    counts = {c: len(d["rows"]) for c, d in manifest["corpora"].items()}
    print(f"[prepare] {counts} -> {run_dir}")


def swift(args: argparse.Namespace, run_dir: Path) -> int:
    runner = Path(args.runner)
    if not runner.is_file():
        print(f"ERROR: Swift runner not found at {runner}", file=sys.stderr)
        return 2
    cmd = [
        str(runner),
        "--input",
        str(run_dir / "runner-input.json"),
        "--output",
        str(run_dir / "runner-output.json"),
    ]
    return subprocess.call(cmd)


def report(args: argparse.Namespace, run_dir: Path, git: dict[str, Any]) -> None:
    manifest_bytes = (run_dir / "manifest.json").read_bytes()
    manifest = json.loads(manifest_bytes)
    runner_bytes = (run_dir / "runner-output.json").read_bytes()
    runner_doc = json.loads(runner_bytes)
    manifest_sha = rp.sha256_bytes(manifest_bytes)
    fixed_time_dir = Path(args.fixed_time_run_dir) if args.fixed_time_run_dir else None
    rows, fixed_time_digests = rp.build_rows(
        manifest, manifest_sha, runner_doc, fixed_time_dir, git
    )
    rows_sha = write_json(run_dir / "rows.json", {"schema": rp.ROWS_SCHEMA, "rows": rows})
    digests = {
        "corpusManifestSha256": manifest_sha,
        "runnerOutputSha256": rp.sha256_bytes(runner_bytes),
        "perTrackRowsSha256": rows_sha,
        "fixedTimeScoresSha256": fixed_time_digests,
        "untrackedPathsAtRun": git.get("untrackedPaths"),
    }
    agg = rp.aggregate(rows, manifest, digests, git, runner_doc)
    md = rp.render_markdown(agg)
    agg_bytes = rp.canonical_json(agg)
    for text in (agg_bytes.decode("utf-8"), md):
        rp.assert_no_track_identifiers(text, manifest)

    stem = f"15-9-matched-eval-{run_dir.name}"
    artifact_dir = Path(args.artifact_dir)
    artifact_dir.mkdir(parents=True, exist_ok=True)
    (run_dir / f"{stem}.json").write_bytes(agg_bytes)
    (artifact_dir / f"{stem}.json").write_bytes(agg_bytes)
    (artifact_dir / f"{stem}.md").write_text(md)
    print(f"[report] {len(rows)} rows -> {run_dir / 'rows.json'}")
    print(f"[report] aggregate -> {artifact_dir / (stem + '.json')} and .md")


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Story 15.9 evaluation harness.")
    p.add_argument("command", choices=("prepare", "swift", "report", "all"))
    p.add_argument("--run-root", default=str(DEFAULT_RUN_ROOT))
    p.add_argument("--run-dir", help="use this run directory instead of <run-root>/<git sha>")
    p.add_argument("--artifact-dir", default=str(DEFAULT_ARTIFACT_DIR))
    p.add_argument("--legacy-root", help="ml-training directory holding eval-corpus/ (read-only)")
    p.add_argument("--fixed-time-run-dir", help="Story 15.5 run directory with scores-*.json")
    p.add_argument("--runner", help="path to the built matched-eval-run binary")
    p.add_argument("--corpus", action="append", choices=cp.CORPORA)
    p.add_argument("--oa300-root", default=os.environ.get("OA300_CORPUS_PATH", ""))
    p.add_argument("--giantsteps-root", default=os.environ.get("GIANTSTEPS_CORPUS_PATH", ""))
    args = p.parse_args(argv if argv is not None else sys.argv[1:])

    git = git_state()
    run_dir = Path(args.run_dir) if args.run_dir else run_dir_for(Path(args.run_root), git)
    try:
        if args.command in ("prepare", "all"):
            prepare(args, run_dir)
        if args.command in ("swift", "all"):
            code = swift(args, run_dir)
            if code != 0:
                print(f"ERROR: the Swift runner exited {code}", file=sys.stderr)
                return code
        if args.command in ("report", "all"):
            report(args, run_dir, git)
    except (cp.CorpusRefusal, rp.ReportRefusal) as e:
        print(f"ERROR: refused. {e}", file=sys.stderr)
        return EXIT_REFUSED
    return 0


if __name__ == "__main__":
    sys.exit(main())
