"""Shared pytest setup for the `scripts/` test suite (W87).

Two jobs:

1. Load `scripts/docc-transclude.py` as an importable module. The filename is
   hyphenated (it is a `uv run` CLI, not a package), so a plain `import` cannot
   reach it; `importlib.util.spec_from_file_location` is the documented escape
   hatch. Session-scoped because the module is stateless and the load is pure.
2. Hand every test a `workspace` rooted in pytest's `tmp_path`. NOTHING in this
   suite may write into the repo tree, and specifically never into
   `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Cases/` — so `workspace.argv()`
   always passes BOTH `--docs-root` and `--output-dir` explicitly, and no test
   is allowed to fall through to the generator's repo-rooted defaults.

Run: `make scripts-tests` (or
`uv run --project _bmad-output/ml-training pytest scripts/tests/`).
"""

from __future__ import annotations

import importlib.util
import os
import pathlib
import types

import pytest

_SCRIPTS = pathlib.Path(__file__).resolve().parent.parent
_SRC = _SCRIPTS / "docc-transclude.py"


def _load_generator() -> types.ModuleType:
    spec = importlib.util.spec_from_file_location("docc_transclude", _SRC)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load a module spec from {_SRC}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@pytest.fixture(scope="session")
def docc() -> types.ModuleType:
    """The `scripts/docc-transclude.py` module under test."""
    return _load_generator()


class Workspace:
    """A synthetic corpus + output dir, both under one pytest `tmp_path`.

    `docs_root` and `output_dir` are deliberately siblings under `root` so they
    never overlap (the generator refuses an overlapping pair), and `output_dir`
    sits one level down inside `generated/` so `output_dir.parent` is a real,
    inspectable directory for the temp-residue assertions.
    """

    # Reserved `snapshot()` key for the "output_dir is not a plain directory"
    # states. `/` cannot appear in a relative POSIX path component, so it can
    # never collide with a real entry key.
    STATE_KEY = "<output-dir/state>"
    SYMLINK_MARKER = b"symlink -> "

    def __init__(self, root: pathlib.Path) -> None:
        self.root = root
        self.docs_root = root / "docs"
        self.output_dir = root / "generated" / "Cases"
        self.docs_root.mkdir(parents=True, exist_ok=True)

    def argv(self, *extra: str) -> list[str]:
        """Full argv with both paths pinned into `tmp_path`."""
        return [
            "--docs-root",
            str(self.docs_root),
            "--output-dir",
            str(self.output_dir),
            *extra,
        ]

    def write_case(self, type_name: str, stem: str, body: str = "Body text.\n") -> pathlib.Path:
        """Write a well-formed `<Type>/<stem>.md` with a two-key front matter."""
        front = f"---\nid: {stem}\ntitle: {stem.title()}\n---\n"
        return self.write_raw(type_name, f"{stem}.md", (front + body).encode("utf-8"))

    def write_raw(self, type_name: str, filename: str, data: bytes) -> pathlib.Path:
        """Write arbitrary bytes to `<Type>/<filename>` (for malformed inputs)."""
        type_dir = self.docs_root / type_name
        type_dir.mkdir(parents=True, exist_ok=True)
        path = type_dir / filename
        path.write_bytes(data)
        return path

    def seed_output(self, pages: dict[str, bytes] | None = None) -> dict[str, bytes]:
        """Pre-populate `output_dir` with known pages and return that snapshot.

        Used by every failure test: the on-disk bytes here must survive an
        aborted run untouched, which is the assertion that proves the run failed
        for the right reason rather than after a partial write.
        """
        if pages is None:
            pages = {"Seeded-page.md": b"# ``Seeded/page``\n\nseeded body\n"}
        self.output_dir.mkdir(parents=True, exist_ok=True)
        for name, data in pages.items():
            (self.output_dir / name).write_bytes(data)
        return dict(pages)

    def snapshot(self) -> dict[str, bytes]:
        """`{relative_path: bytes}` for every entry anywhere under `output_dir`.

        Recursive and keyed by POSIX path relative to `output_dir`, so residue
        left in a nested subdirectory cannot escape the byte-identity assertions
        (a top-level, name-keyed listing would miss it and would also collide on
        same-named files in different subdirectories).

        Symlinks are recorded by their LINK TARGET under the
        `SYMLINK_MARKER` prefix, never by reading through them: a symlink left
        inside `output_dir` is exactly the residue class the generator's
        non-directory guard exists for, and skipping symlinks would make it
        invisible to every byte-identity assertion here.

        The degenerate shapes are explicit values, not an empty dict. An empty
        `{}` means "the directory exists and holds nothing", and returning it for
        an absent or non-directory `output_dir` would make a before/after
        comparison vacuously true for any test that never called
        `seed_output()`; those shapes get their own distinguishable marker so a
        transition between them fails the comparison.
        """
        if self.output_dir.is_symlink():
            return {self.STATE_KEY: self.SYMLINK_MARKER + os.readlink(self.output_dir).encode()}
        if not self.output_dir.exists():
            return {self.STATE_KEY: b"absent"}
        if not self.output_dir.is_dir():
            return {self.STATE_KEY: b"exists, not a directory"}

        snap: dict[str, bytes] = {}
        for path in sorted(self.output_dir.rglob("*")):
            key = path.relative_to(self.output_dir).as_posix()
            if path.is_symlink():
                snap[key] = self.SYMLINK_MARKER + os.readlink(path).encode()
            elif path.is_file():
                snap[key] = path.read_bytes()
        return snap

    def temp_residue(self) -> list[str]:
        """Any `.cases-tmp-*` / `.cases-bak-*` sibling left in the output parent."""
        parent = self.output_dir.parent
        if not parent.is_dir():
            return []
        return sorted(p.name for p in parent.glob(".cases-*"))


@pytest.fixture
def workspace(tmp_path: pathlib.Path) -> Workspace:
    return Workspace(tmp_path)
