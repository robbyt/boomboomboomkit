#!/usr/bin/env python3
"""Stage a `develop` -> `main` promotion using an allowlist that fails closed.

The previous protocol was a denylist: "remove every path in the
Stays-on-develop list". Anything not enumerated shipped by default, so every
new develop-only directory was a silent leak waiting for release day. At the
time this script was written `develop` had 21 top-level entries and the list
named 6 — `.gemini/`, `Demo/`, `docs/`, `TODO.md`, `hilbert-request.md` and
`.github/` would all have shipped.

This inverts the default. ``SHIPS_TO_MAIN`` is the complete set of paths
allowed on `main`; the index is partitioned against it and everything else is
unstaged, whether or not anyone remembered to list it. Adding a develop-only
directory tomorrow requires no edit here.

Usage
-----
    git checkout main
    git merge --squash develop
    uv run scripts/promote-to-main.py            # dry run, stages nothing
    uv run scripts/promote-to-main.py --execute  # unstage the strip set
    git commit                                   # a human writes the message

Develop-only. Consumers never run this, and it strips itself.
"""

from __future__ import annotations

import argparse
import subprocess
import sys

# ---------------------------------------------------------------------------
# The allowlist. This is the executable source of truth; CLAUDE.md's
# "Ships to main" table documents it and `scripts/tests/test_promote_to_main.py`
# asserts the two agree, so they cannot drift.
#
# Trailing "/" means "this directory and everything under it".
# ---------------------------------------------------------------------------
SHIPS_TO_MAIN: tuple[str, ...] = (
    ".gitignore",
    ".swiftlint.yml",
    "LICENSE",
    "MODEL_CARD.md",
    "Makefile",
    "Package.swift",
    "README.md",
    "Sources/",
    "Tests/",
    "tools/coreml-convert/",
)

# `main` keeps its OWN version of these rather than taking develop's.
#
# develop's .gitignore is 132 lines, most of them patterns for paths that do
# not exist on `main` at all — ml-training checkpoints, per-seed model
# exports, party-mode scratch, BMAD output subtrees. Carrying them to `main`
# would be dead config a consumer cannot act on. `main` has its own 48-line
# file covering what a main-only checkout actually produces: SPM build output,
# Xcode/DerivedData, the tools/coreml-convert virtualenv, and OS/editor junk.
#
# Note this is a FUNCTIONAL split, not a secrecy one: in-code provenance
# comments (story references, design-decision numbers) ship deliberately and
# are useful to anyone reading the source. Only whole develop-only FILES are
# withheld, which is what the allowlist above governs.
PRESERVE_FROM_MAIN: frozenset[str] = frozenset({".gitignore"})


def run(*args: str) -> str:
    """Run a git command, returning stdout. Raises on non-zero exit."""
    proc = subprocess.run(["git", *args], capture_output=True, text=True, check=False)
    if proc.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} failed: {proc.stderr.strip()}")
    return proc.stdout


def run_bytes(*args: str) -> bytes:
    """Run a git command, returning raw stdout bytes (blobs may be binary)."""
    proc = subprocess.run(["git", *args], capture_output=True, check=False)
    if proc.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} failed")
    return proc.stdout


def staged_paths() -> list[str]:
    """Every staged path, NUL-separated.

    `git ls-files` without -z QUOTES any path containing non-ASCII bytes, so
    a shipping fixture such as
    `Sources/.../AudioFixtures/Meta_Man_<greek>.mp3` arrives wrapped in double
    quotes and fails a naive prefix match — it would be stripped from the
    release. -z emits raw bytes with no quoting. Found by running the real
    promotion; every ASCII-only fixture test passed straight over it.
    """
    raw = run_bytes("ls-files", "--cached", "-z")
    # A CONFLICTED index lists the same path once per merge stage, so a naive
    # list double-counts. `git merge --squash develop` now always conflicts on
    # .gitignore (main carries its own public copy, develop a develop-specific
    # one), making this the normal case rather than an edge case. Dedupe while
    # preserving order.
    seen: dict[str, None] = {}
    for chunk in raw.split(b"\x00"):
        if chunk:
            seen.setdefault(chunk.decode("utf-8", "surrogateescape"), None)
    return list(seen)


def unmerged_paths() -> list[str]:
    """Paths left conflicted by the squash merge."""
    raw = run_bytes("ls-files", "--unmerged", "-z")
    seen: dict[str, None] = {}
    for entry in raw.split(b"\x00"):
        if not entry:
            continue
        # Format: "<mode> <sha> <stage>\t<path>"
        _, _, path = entry.partition(b"\t")
        if path:
            seen.setdefault(path.decode("utf-8", "surrogateescape"), None)
    return list(seen)


def is_allowed(path: str) -> bool:
    """True when `path` is cleared to appear on `main`."""
    for entry in SHIPS_TO_MAIN:
        if entry.endswith("/"):
            if path.startswith(entry):
                return True
        elif path == entry:
            return True
    return False


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Stage a develop -> main promotion against an allowlist."
    )
    parser.add_argument(
        "--execute",
        action="store_true",
        help="actually unstage the strip set (default is a dry run)",
    )
    parser.add_argument(
        "--from-ref",
        metavar="REF",
        help=(
            "partition REF's tree instead of the index — a drift check that "
            "runs from any branch on any day, with no squash staged. "
            "Implies a dry run."
        ),
    )
    parser.add_argument(
        "--allow-any-branch",
        action="store_true",
        help="skip the 'must be on main' guard (testing only)",
    )
    args = parser.parse_args()

    try:
        run("rev-parse", "--git-dir")
    except RuntimeError:
        print("error: not inside a git repository", file=sys.stderr)
        return 2

    # --from-ref inspects a ref rather than the index, so neither the branch
    # guard nor a staged squash applies. This is what makes the preview a
    # standing drift check rather than a release-day-only step.
    if args.from_ref:
        if args.execute:
            print("error: --from-ref is read-only; drop --execute", file=sys.stderr)
            return 2
        raw = run_bytes("ls-tree", "-r", "--name-only", "-z", args.from_ref)
        staged = [c.decode("utf-8", "surrogateescape") for c in raw.split(b"\x00") if c]
        if not staged:
            print(f"error: '{args.from_ref}' resolved to an empty tree", file=sys.stderr)
            return 2
        keep = sorted(p for p in staged if is_allowed(p))
        strip = sorted(p for p in staged if not is_allowed(p))
        assert len(keep) + len(strip) == len(staged), "partition is not total"

        def roots_of(paths: list[str]) -> list[str]:
            return sorted({p.split("/")[0] + ("/" if "/" in p else "") for p in paths})

        print(f"WOULD SHIP from {args.from_ref} ({len(keep)} files)")
        for r in roots_of(keep):
            print(f"  {r}")
        print(f"\nWOULD BE STRIPPED ({len(strip)} files)")
        for r in roots_of(strip):
            print(f"  {r}")
        print("\nDRIFT CHECK — read-only, nothing staged.")
        return 0

    if not args.allow_any_branch:
        # `rev-parse --abbrev-ref HEAD` fails on an unborn branch (a repo with
        # no commits yet). `symbolic-ref` reports the branch name regardless,
        # so the guard refuses cleanly instead of dying with a traceback.
        try:
            branch = run("symbolic-ref", "--short", "HEAD").strip()
        except RuntimeError:
            branch = "(detached HEAD)"
        if branch != "main":
            print(
                f"error: expected to be on 'main', found '{branch}'.\n"
                "       Run `git checkout main && git merge --squash develop` first.",
                file=sys.stderr,
            )
            return 2

    staged = staged_paths()
    if not staged:
        print("error: nothing staged — did `git merge --squash develop` run?", file=sys.stderr)
        return 2

    conflicted = unmerged_paths()
    unresolved = [p for p in conflicted if p not in PRESERVE_FROM_MAIN]

    keep = sorted(p for p in staged if is_allowed(p))
    strip = sorted(p for p in staged if not is_allowed(p))

    # Every staged path lands in exactly one set. Asserted rather than assumed:
    # a partition bug would silently ship whatever it failed to classify.
    assert len(keep) + len(strip) == len(staged), "partition is not total"

    def roots(paths: list[str]) -> list[str]:
        return sorted({p.split("/")[0] + ("/" if "/" in p else "") for p in paths})

    print(f"STAGED FOR main ({len(keep)} files)")
    for r in roots(keep):
        print(f"  {r}")

    missing = [
        e
        for e in SHIPS_TO_MAIN
        if not any(is_allowed(p) and (p == e or p.startswith(e)) for p in keep)
    ]
    if missing:
        print("\nALLOWLISTED BUT ABSENT FROM THE TREE")
        for m in missing:
            print(f"  {m}")

    print(f"\nSTRIPPED — not on the allowlist ({len(strip)} files)")
    for r in roots(strip):
        print(f"  {r}")

    if conflicted:
        print(f"\nCONFLICTED BY THE SQUASH ({len(conflicted)})")
        for c in conflicted:
            note = (
                "resolved to main's copy" if c in PRESERVE_FROM_MAIN else "NEEDS MANUAL RESOLUTION"
            )
            print(f"  {c}: {note}")

    if not args.execute:
        print(f"\nDRY RUN — {len(strip)} files would be unstaged, {len(keep)} kept.")
        print("Re-run with --execute to stage the promotion.")
        return 0

    if unresolved:
        print(
            "error: unresolved merge conflicts outside the preserve set:\n  "
            + "\n  ".join(unresolved)
            + "\nResolve them, `git add` the results, then re-run.",
            file=sys.stderr,
        )
        return 2

    if strip:
        # Batch through xargs-style chunking: a full develop tree can exceed
        # the argv limit.
        for i in range(0, len(strip), 500):
            run("rm", "--cached", "-q", "--", *strip[i : i + 500])

    for path in sorted(PRESERVE_FROM_MAIN):
        try:
            run("checkout", "HEAD", "--", path)
            print(f"preserved main's own {path}")
        except RuntimeError:
            print(f"note: {path} not present on main; develop's version stands")

    print(f"\nStaged. {len(strip)} files unstaged, {len(keep)} remain.")
    print("Review with `git status`, then commit with a public-facing message.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
