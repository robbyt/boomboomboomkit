#!/usr/bin/env python3
"""Scaffold a new per-case documentation Markdown file from the shared template.

Invoked by `make new-case TYPE=<TypeName> CASE=<caseName>`. Copies
`Sources/BoomBoomBoomKit/Resources/_template.md`, substitutes the
`{{TYPE}}` / `{{CASE}}` placeholders, and writes
`Documentation/<TYPE>/<CASE>.md`. The template sits beside the copied
`Documentation/` tree (not inside it) so it stays out of `Bundle.module`.

Design (Story 11.3a DD-10):
  - Stdlib-only, run via `uv run` — deliberately NOT a shell target. A shell
    copy-and-substitute is fragile across BSD/GNU `sed`, needs escaping for `&`,
    `\\`, and delimiter characters, and can leave a partial file if substitution
    fails after the copy; this repo already extracted `demo-bump-build.py` for
    the same reason.
  - Validates that TYPE and CASE are Swift identifiers to block path escape
    (`/`, `..`, whitespace, shell metacharacters). It does NOT check TYPE/CASE
    against the Swift source roster — that is Story 11.4's fail-late validator.
  - Refuses to overwrite: the target is opened with exclusive-create mode, so an
    existing file is a hard error with a non-zero exit and no partial write.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# A Swift identifier: leading letter/underscore, then letters/digits/underscores.
# This is a lexical path-escape guard, not a Swift-source-roster check.
IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_ROOT = REPO_ROOT / "Sources/BoomBoomBoomKit/Resources/Documentation"
# The template lives BESIDE the copied Documentation/ tree (in Resources/), not
# inside it, so it does not ship in Bundle.module.
TEMPLATE = DOCS_ROOT.parent / "_template.md"


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="new-case",
        description="Scaffold a per-case documentation Markdown file from _template.md.",
    )
    parser.add_argument("type", help="The DocumentedCase type name (a Swift identifier).")
    parser.add_argument("case", help="The case identifier (a Swift identifier).")
    args = parser.parse_args()

    type_name = args.type
    case_name = args.case

    if not IDENTIFIER.match(type_name):
        fail(f"TYPE {type_name!r} is not a Swift identifier ([A-Za-z_][A-Za-z0-9_]*).")
    if not IDENTIFIER.match(case_name):
        fail(f"CASE {case_name!r} is not a Swift identifier ([A-Za-z_][A-Za-z0-9_]*).")

    if not TEMPLATE.is_file():
        fail(f"template not found at {TEMPLATE}")

    target = DOCS_ROOT / type_name / f"{case_name}.md"
    target.parent.mkdir(parents=True, exist_ok=True)

    body = TEMPLATE.read_text(encoding="utf-8")
    body = body.replace("{{TYPE}}", type_name).replace("{{CASE}}", case_name)

    try:
        # Exclusive-create: refuses to clobber an existing file, and writes
        # nothing on failure (no partial file).
        with open(target, "x", encoding="utf-8") as handle:
            handle.write(body)
    except FileExistsError:
        fail(f"refusing to overwrite existing file {target.relative_to(REPO_ROOT)}")

    print(f"created {target.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()
