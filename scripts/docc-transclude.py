#!/usr/bin/env python3
"""One-way DocC transclude generator for the per-case documentation corpus.

Invoked by `make docc-transclude`. Mirrors each canonical per-case doc
`Sources/BoomBoomBoomKit/Resources/Documentation/<Type>/<stem>.md` into a DocC
symbol-extension page `BoomBoomBoomKit.docc/Cases/<Type>-<stem>.md`. The
canonical docs are the single source of truth (NFR-5): this generator READS
them and never writes back. The `Cases/` tree is a gitignored build artifact —
regenerate it, never hand-edit it.

Each generated page: strips the ENTIRE leading YAML front-matter block (all keys;
boundary is the closing `---` delimiter, not a fixed line count), prepends a
symbol-extension h1 ``# ``<Type>/<symbol>```` , then reproduces the source body
byte-for-byte. `<symbol>` is the filename stem for value-only cases, or the
signature-suffixed identifier for the five associated-value cases (see
ASSOC_VALUE_SIGNATURES — a bare stem fails DocC symbol binding). No `@Metadata`
block is emitted: an h1 that is a `` ``Type/case`` `` symbol link already makes
the page a symbol extension.

Design (Story 11.5):
  - Stdlib-only, run via `uv run` — deliberately NOT a shell target (mirrors
    `scripts/new-case.py`). Develop-only: lives in `scripts/`, never ships to main.
  - Byte discipline: read/write bytes, NOT Python universal-newline mode. The
    canonical corpus is LF-only (11.4-validated); a CR/CRLF byte in an input body
    is treated as malformed (fail nonzero) rather than silently normalized.
  - Atomic + self-cleaning: the full output set is built and validated in memory
    first, written into a sibling temp dir, then swapped into place wholesale, so
    a renamed/removed case leaves no stale page and any malformed input aborts
    with `Cases/` left untouched (never a partial update).
  - Coverage is roster-derived: the output count equals the number of eligible
    source files (49 today), asserted rather than hardcoded.
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DOCS_ROOT = REPO_ROOT / "Sources/BoomBoomBoomKit/Resources/Documentation"
DEFAULT_OUTPUT_DIR = REPO_ROOT / "Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Cases"

# The five associated-value cases whose DocC symbol path needs the signature
# suffix (a bare stem fails symbol binding). Value-only cases use the bare stem.
# Source-verified against the enum declarations; carry this map exactly.
ASSOC_VALUE_SIGNATURES: dict[tuple[str, str], str] = {
    ("EnsemblePolicy", "weightedVoting"): "weightedVoting(_:)",
    ("MLExecutionPolicy", "whenDSPConfidenceBelow"): "whenDSPConfidenceBelow(_:)",
    ("DownbeatResult", "detected"): "detected(estimate:)",
    ("AbstainReason", "sourceSpecific"): "sourceSpecific(_:)",
    ("DemotionReason", "sourceSpecific"): "sourceSpecific(_:)",
}

DELIM = b"---"
NL = b"\n"


class MalformedInput(Exception):
    """A source file could not be transformed; the run must abort untouched."""


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def symbol_path(type_name: str, stem: str) -> str:
    """Return the DocC symbol path segment `<Type>/<symbol>` for a case file."""
    symbol = ASSOC_VALUE_SIGNATURES.get((type_name, stem), stem)
    return f"{type_name}/{symbol}"


def strip_front_matter(data: bytes, rel: str) -> bytes:
    """Return the body after the leading YAML front-matter block, byte-exact.

    Splitting on and re-joining with ``b"\\n"`` is byte-lossless, so the returned
    body is identical to the source bytes following the closing ``---`` line
    (including the source's single trailing newline). Rejects missing delimiters,
    invalid UTF-8, and any CR byte in the body.
    """
    try:
        data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise MalformedInput(f"{rel}: not valid UTF-8 ({exc})") from exc

    lines = data.split(NL)
    if not lines or lines[0] != DELIM:
        raise MalformedInput(f"{rel}: missing opening front-matter delimiter '---'")

    close_index: int | None = None
    for index in range(1, len(lines)):
        if lines[index] == DELIM:
            close_index = index
            break
    if close_index is None:
        raise MalformedInput(f"{rel}: missing closing front-matter delimiter '---'")

    body = NL.join(lines[close_index + 1 :])
    if b"\r" in body:
        raise MalformedInput(f"{rel}: body contains a CR byte (corpus is LF-only)")
    return body


def build_page(type_name: str, stem: str, body: bytes) -> bytes:
    """Compose the symbol-extension page: h1 + blank line + verbatim body."""
    heading = f"# ``{symbol_path(type_name, stem)}``".encode("utf-8")
    return heading + NL + NL + body


def eligible_sources(docs_root: Path) -> list[tuple[str, str, Path]]:
    """Return sorted `(type_name, stem, path)` for every eligible case file.

    Skips `_`-prefixed directories and `_`-prefixed filename stems. Deterministic
    (sorted) traversal so output is reproducible.
    """
    if not docs_root.is_dir():
        fail(f"docs-root not found at {docs_root}")

    results: list[tuple[str, str, Path]] = []
    for type_dir in sorted(p for p in docs_root.iterdir() if p.is_dir()):
        if type_dir.name.startswith("_"):
            continue
        for md_path in sorted(type_dir.glob("*.md")):
            if md_path.name.startswith("_"):
                continue
            results.append((type_dir.name, md_path.stem, md_path))
    return results


def collect_outputs(docs_root: Path) -> dict[str, bytes]:
    """Build the full `{output_filename: page_bytes}` map, validating everything.

    Raises MalformedInput on any malformed source or duplicate output filename —
    before any file is written.
    """
    outputs: dict[str, bytes] = {}
    origin: dict[str, str] = {}
    for type_name, stem, path in eligible_sources(docs_root):
        rel = str(path.relative_to(docs_root.parent))
        try:
            data = path.read_bytes()
        except OSError as exc:
            raise MalformedInput(f"{rel}: unreadable ({exc})") from exc

        body = strip_front_matter(data, rel)
        page = build_page(type_name, stem, body)

        name = f"{type_name}-{stem}.md"
        if name in outputs:
            raise MalformedInput(f"{rel}: output '{name}' collides with {origin[name]}")
        outputs[name] = page
        origin[name] = rel
    return outputs


def _is_within(child: Path, parent: Path) -> bool:
    """True if `child` is `parent` or nested under it. Python 3.8-safe."""
    try:
        child.relative_to(parent)
        return True
    except ValueError:
        return False


def reject_path_overlap(docs_root: Path, output_dir: Path) -> None:
    """Refuse an output-dir that equals, contains, or sits inside docs-root."""
    docs_res = docs_root.resolve()
    out_res = output_dir.resolve()
    if out_res == docs_res or _is_within(out_res, docs_res) or _is_within(docs_res, out_res):
        fail(f"output-dir {out_res} overlaps docs-root {docs_res}; refusing to run")


def atomic_swap(output_dir: Path, outputs: dict[str, bytes]) -> None:
    """Write outputs to a sibling temp dir, then swap it into place wholesale.

    Fully self-cleaning: on any failure the sibling temp dir is removed and, if
    the existing `Cases/` was already moved aside, it is restored — so a crash
    mid-swap never leaves a partial `Cases/` or an orphan `.cases-tmp-*` /
    `.cases-bak-*` dir behind (those prefixes are also gitignored as a hard-kill
    backstop).
    """
    parent = output_dir.parent
    parent.mkdir(parents=True, exist_ok=True)

    tmp_dir = Path(tempfile.mkdtemp(dir=parent, prefix=".cases-tmp-"))
    backup: Path | None = None
    swapped = False
    try:
        for name, data in outputs.items():
            (tmp_dir / name).write_bytes(data)
        if output_dir.exists():
            backup = Path(tempfile.mkdtemp(dir=parent, prefix=".cases-bak-"))
            backup.rmdir()  # free the name so os.rename can move Cases/ onto it
            os.rename(output_dir, backup)
        os.rename(tmp_dir, output_dir)
        swapped = True
    finally:
        if not swapped:
            # Roll back a moved-aside original, then drop the temp set.
            if backup is not None and backup.exists() and not output_dir.exists():
                try:
                    os.rename(backup, output_dir)
                except OSError:
                    pass
            shutil.rmtree(tmp_dir, ignore_errors=True)
        if backup is not None:
            shutil.rmtree(backup, ignore_errors=True)


def run_generate(docs_root: Path, output_dir: Path) -> int:
    reject_path_overlap(docs_root, output_dir)
    outputs = collect_outputs(docs_root)
    atomic_swap(output_dir, outputs)
    return len(outputs)


def run_check(docs_root: Path, output_dir: Path) -> int:
    """Verify-only: assert the pages already on disk under `output_dir` are
    exactly what a fresh generation would produce.

    Rebuilds the expected `{name: page_bytes}` set in memory (no writes), then
    compares it against the actual files under `output_dir`: the filename SETS
    must match exactly (no missing, no stale/extra pages) and every on-disk
    page's bytes must equal the freshly-generated bytes. Any malformed source,
    empty corpus, or on-disk drift exits nonzero. `make docc-validate` feeds
    this a freshly-generated temp dir (so it byte-verifies the real write/swap
    path independent of the gitignored repo `Cases/`); a direct call with the
    default `--output-dir` instead audits the repo `Cases/` (which must have
    been generated first).
    """
    reject_path_overlap(docs_root, output_dir)
    outputs = collect_outputs(docs_root)  # validates + builds the expected page set
    if not outputs:
        fail(f"no eligible source docs under {docs_root} (wrong --docs-root?)")
    if not output_dir.is_dir():
        fail(f"generated Cases/ dir missing at {output_dir}; run `make docc-transclude`")

    on_disk = {p.name for p in output_dir.glob("*.md")}
    expected = set(outputs)
    missing = sorted(expected - on_disk)
    extra = sorted(on_disk - expected)
    if missing:
        fail(f"Cases/ is stale: {len(missing)} page(s) missing (e.g. {missing[:3]}); regenerate")
    if extra:
        fail(f"Cases/ has {len(extra)} stale/orphan page(s) (e.g. {extra[:3]}); regenerate")
    for name, page in outputs.items():
        if (output_dir / name).read_bytes() != page:
            fail(f"Cases/{name} drifted from its canonical source; regenerate (do not hand-edit)")
    return len(outputs)


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="docc-transclude",
        description="Generate DocC symbol-extension pages from per-case docs.",
    )
    parser.add_argument(
        "--docs-root",
        type=Path,
        default=DEFAULT_DOCS_ROOT,
        help="Canonical per-case documentation root (read-only).",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="Generated Cases/ output directory (regenerated wholesale).",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Verify-only: assert the pages under --output-dir match a fresh generation, write nothing.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> None:
    args = parse_args(argv)
    docs_root: Path = args.docs_root
    output_dir: Path = args.output_dir

    try:
        if args.check:
            count = run_check(docs_root, output_dir)
            print(f"docc-transclude --check: {count} pages consistent with {output_dir}")
        else:
            count = run_generate(docs_root, output_dir)
            print(f"docc-transclude: wrote {count} pages to {output_dir}")
    except MalformedInput as exc:
        fail(str(exc))
    except OSError as exc:
        fail(f"I/O failure: {exc}")


if __name__ == "__main__":
    main()
