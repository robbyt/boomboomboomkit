#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""demo-bump-build.py — Increment CURRENT_PROJECT_VERSION in BoomBoomBoomKitDemo's pbxproj.

Replaces the shell-pipeline-based ``demo-bump-build`` Makefile recipe. The shell
form went through three rounds of churn in 48 hours (Story 5-7 PR #9 squash +
two 2026-05-24 code-review passes) on the same dozen lines of sed/grep before
being extracted to Python per operator directive 2026-05-24. Closes the
fragility cycle that was producing recurring review flags around BSD-vs-GNU
sed portability, regex anchoring, shell quoting, and arithmetic edge cases.

Develop-only — not shipped to main per CLAUDE.md §Release Process. Standard
library only (no third-party deps). Invoked from the Makefile as
``uv run scripts/demo-bump-build.py``.

Invariants enforced:
  * Every ``CURRENT_PROJECT_VERSION = ...;`` assignment must parse as an integer.
    Mixing integer with non-integer values (e.g., ``1.0``) is a hard error —
    no partial-bump state can occur.
  * All assignments converge to ``max(values) + 1`` in a single rewrite.
  * Quoted-form values (``= "1";``) are handled identically to unquoted form
    and rewritten to the normalized unquoted form (matches Xcode's modern
    preferred output).
  * Post-rewrite verification: applied-rewrite count MUST equal input-line
    count, else the script refuses to write and exits non-zero.

Exit codes:
    0  bumped successfully
    1  parse/validation error (non-integer mix, zero matches, count mismatch,
       UnicodeDecodeError reading the pbxproj)
    2  invocation error (pbxproj not found, permission/TOCTOU/write OSError)
"""

from __future__ import annotations

import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
PBXPROJ = (
    REPO_ROOT
    / "Demo"
    / "BoomBoomBoomKitDemo"
    / "BoomBoomBoomKitDemo.xcodeproj"
    / "project.pbxproj"
)

# Line-anchored, whitespace-tolerant, quoted-or-unquoted integer matcher.
# Group 1 captures leading indentation so rewrites preserve it.
# Group 2 captures the integer value (sans quotes).
LINE_RE = re.compile(
    r'^(\s*)CURRENT_PROJECT_VERSION\s*=\s*"?(\d+)"?\s*;\s*$',
    re.MULTILINE,
)

# Loose matcher used purely for counting total assignments (including
# non-integer-form ones we'd refuse to bump). Required so the "found N total
# but only M integer-form" error message can name the divergence.
ANY_LINE_RE = re.compile(
    r"^\s*CURRENT_PROJECT_VERSION\s*=.*$",
    re.MULTILINE,
)


def main() -> int:
    if not PBXPROJ.exists():
        print(f"ERROR: pbxproj not found at {PBXPROJ}", file=sys.stderr)
        return 2

    try:
        text = PBXPROJ.read_text(encoding="utf-8")
    except UnicodeDecodeError as exc:
        print(f"ERROR: pbxproj is not valid UTF-8: {exc}", file=sys.stderr)
        return 1
    except OSError as exc:
        print(f"ERROR: cannot read {PBXPROJ}: {exc}", file=sys.stderr)
        return 2

    total = len(ANY_LINE_RE.findall(text))
    if total == 0:
        print(
            f"ERROR: no CURRENT_PROJECT_VERSION assignments found in {PBXPROJ.name}",
            file=sys.stderr,
        )
        return 1

    matches = LINE_RE.findall(text)
    integer_count = len(matches)

    if total != integer_count:
        print(
            f"ERROR: found {total} CURRENT_PROJECT_VERSION assignments but only "
            f"{integer_count} are integer-form. Non-integer values (e.g., 1.0) "
            f"are not supported — fix the pbxproj before bumping",
            file=sys.stderr,
        )
        return 1

    values = [int(value) for _indent, value in matches]
    max_val = max(values)
    next_val = max_val + 1

    def replace(match: re.Match[str]) -> str:
        indent = match.group(1)
        return f"{indent}CURRENT_PROJECT_VERSION = {next_val};"

    new_text = LINE_RE.sub(replace, text)

    applied = sum(
        1 for _indent, value in LINE_RE.findall(new_text) if int(value) == next_val
    )
    if applied != total:
        print(
            f"ERROR: bump would rewrite {applied} of {total} CURRENT_PROJECT_VERSION "
            f"lines — pbxproj would be inconsistent, NOT writing changes",
            file=sys.stderr,
        )
        return 1

    # Atomic write via per-invocation tempfile + os.replace. Same-filesystem
    # (dir=PBXPROJ.parent) is required so os.replace is atomic; delete=False
    # because we hand the path to os.replace. Per-invocation NamedTemporaryFile
    # prevents concurrent-invocation races on a shared fixed path (PR #11
    # Copilot finding #1). shutil.copymode preserves the original pbxproj mode
    # (0644) — NamedTemporaryFile defaults to 0600, which would narrow access
    # on os.replace. try/finally cleans up the temp on any exception path.
    # Acknowledged limitation: the full read-modify-write race (two invocations
    # both reading N, both writing N+1) is not serialized; single-operator
    # workflow doesn't exercise it.
    tmp_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=PBXPROJ.parent,
            prefix=".pbxproj.",
            suffix=".tmp",
            delete=False,
        ) as tmp:
            tmp_path = Path(tmp.name)
            tmp.write(new_text)
        shutil.copymode(PBXPROJ, tmp_path)
        os.replace(tmp_path, PBXPROJ)
        tmp_path = None  # ownership transferred; nothing to clean up
    except OSError as exc:
        print(f"ERROR: cannot write {PBXPROJ}: {exc}", file=sys.stderr)
        return 2
    finally:
        if tmp_path is not None:
            try:
                tmp_path.unlink(missing_ok=True)
            except OSError:
                pass  # best-effort cleanup; do not override the script's exit
    print(
        f"Bumped CURRENT_PROJECT_VERSION (max across {total} configs was {max_val}) "
        f"-> {next_val}, applied to all {applied} configs"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
