"""Tests for `scripts/promote-to-main.py` (GH-167 row 8).

The load-bearing one is `test_allowlist_matches_claude_md`. Moving the
ships-to-main list into a script created a second copy alongside CLAUDE.md's
table, and two lists with nothing coupling them is the same defect one layer
up from the denylist this script replaced. That test makes the documentation a
tested artifact rather than prose that happens to be accurate today.

Every test writes only into `tmp_path`; nothing here touches the repo tree.
"""

from __future__ import annotations

import importlib.util
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts" / "promote-to-main.py"


def _load():
    """Load the hyphenated CLI as a module (the conftest.py convention)."""
    spec = importlib.util.spec_from_file_location("promote_to_main", SCRIPT)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


promote = _load()


def _claude_md_ships_to_main() -> set[str]:
    """Parse the 'Ships to main' table out of CLAUDE.md.

    The table sits under a '### Ships to `main`' heading and ends at the next
    heading. Only the first column is read, stripped of backticks.
    """
    text = (REPO_ROOT / "CLAUDE.md").read_text()
    start = text.index("### Ships to `main`")
    end = text.index("###", start + 10)
    rows = set()
    for line in text[start:end].splitlines():
        if not line.startswith("|"):
            continue
        first = line.split("|")[1].strip()
        if not first or first.startswith("-") or first == "Path":
            continue
        rows.add(first.strip("`"))
    return rows


def test_allowlist_matches_claude_md():
    """The script's allowlist and CLAUDE.md's table must be the same set.

    Bites in BOTH directions: an entry added to one and not the other names
    the divergence here rather than surfacing on release day.
    """
    assert set(promote.SHIPS_TO_MAIN) == _claude_md_ships_to_main()


def test_partition_is_total():
    """Every path lands in exactly one of kept/stripped — never both, never neither."""
    paths = [
        "Sources/BoomBoomBoomKit/BPMAnalyzer.swift",
        "Tests/BoomBoomBoomKitTests/X.swift",
        "Package.swift",
        "CLAUDE.md",
        "_bmad-output/implementation-artifacts/spec.md",
        "docs/gemini-audit.md",
        "Demo/App/Main.swift",
        ".gemini/config",
        "TODO.md",
        "scripts/promote-to-main.py",
    ]
    kept = [p for p in paths if promote.is_allowed(p)]
    stripped = [p for p in paths if not promote.is_allowed(p)]
    assert len(kept) + len(stripped) == len(paths)
    assert not (set(kept) & set(stripped))


@pytest.mark.parametrize(
    "path",
    [
        "CLAUDE.md",
        "_bmad-output/project-context.md",
        "_bmad/config.toml",
        ".claude/settings.json",
        ".agents/skill.md",
        ".gemini/config",
        "docs/chatgpt-audit.md",
        "docs/glm-audit.md",
        "Demo/BoomBoomBoomBPM/App.swift",
        "TODO.md",
        "hilbert-request.md",
        "scripts/promote-to-main.py",
        ".github/workflows/ci.yml",
        "codex-review.diff",
    ],
)
def test_develop_only_paths_are_stripped(path):
    """The six paths the old denylist never named must strip without being enumerated."""
    assert not promote.is_allowed(path)


@pytest.mark.parametrize(
    "path",
    [
        "Package.swift",
        "LICENSE",
        "Makefile",
        "README.md",
        "MODEL_CARD.md",
        ".gitignore",
        ".swiftlint.yml",
        "Sources/BoomBoomBoomKit/BPMAnalyzer.swift",
        "Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift",
        "tools/coreml-convert/convert.py",
    ],
)
def test_shipping_paths_are_kept(path):
    assert promote.is_allowed(path)


def test_unlisted_new_directory_fails_closed():
    """The property that makes this an allowlist: a path nobody anticipated strips."""
    assert not promote.is_allowed(".somenewllm/config.toml")
    assert not promote.is_allowed("internal-notes/2027-planning.md")


def test_prefix_collision_does_not_leak():
    """`Sources/` must not clear a sibling that merely starts with the same text."""
    assert promote.is_allowed("Sources/x.swift")
    assert not promote.is_allowed("SourcesInternal/x.swift")
    assert promote.is_allowed("tools/coreml-convert/convert.py")
    assert not promote.is_allowed("tools/internal-thing/x.py")


def test_gitignore_is_preserved_from_main():
    """develop's .gitignore names the workflow; main keeps its own public one."""
    assert ".gitignore" in promote.PRESERVE_FROM_MAIN


def _git(cwd: Path, *args: str) -> str:
    return subprocess.run(
        ["git", *args], cwd=cwd, capture_output=True, text=True, check=True
    ).stdout


def test_end_to_end_strip_in_a_temp_repo(tmp_path: Path):
    """Drive the real CLI against a throwaway repo; assert the index is partitioned."""
    repo = tmp_path / "repo"
    repo.mkdir()
    _git(repo, "init", "-q", "-b", "main")
    _git(repo, "config", "user.email", "t@t")
    _git(repo, "config", "user.name", "t")
    for rel in ("Package.swift", "LICENSE", "CLAUDE.md", "TODO.md"):
        (repo / rel).write_text("x\n")
    (repo / "Sources").mkdir()
    (repo / "Sources" / "a.swift").write_text("x\n")
    (repo / "_bmad-output").mkdir()
    (repo / "_bmad-output" / "spec.md").write_text("x\n")
    _git(repo, "add", "-A")

    proc = subprocess.run(
        ["python3", str(SCRIPT), "--execute", "--allow-any-branch"],
        cwd=repo,
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0, proc.stderr

    staged = set(_git(repo, "ls-files", "--cached").split())
    assert staged == {"Package.swift", "LICENSE", "Sources/a.swift"}
    assert "CLAUDE.md" not in staged
    assert "TODO.md" not in staged
    assert "_bmad-output/spec.md" not in staged
    # Stripped files stay on disk — only the index changed.
    assert (repo / "CLAUDE.md").exists()


def test_refuses_when_nothing_staged(tmp_path: Path):
    repo = tmp_path / "empty"
    repo.mkdir()
    _git(repo, "init", "-q", "-b", "main")
    proc = subprocess.run(
        ["python3", str(SCRIPT), "--allow-any-branch"],
        cwd=repo,
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 2
    assert "nothing staged" in proc.stderr


def test_refuses_off_main(tmp_path: Path):
    repo = tmp_path / "offmain"
    repo.mkdir()
    _git(repo, "init", "-q", "-b", "feature")
    (repo / "LICENSE").write_text("x\n")
    _git(repo, "add", "-A")
    proc = subprocess.run(["python3", str(SCRIPT)], cwd=repo, capture_output=True, text=True)
    assert proc.returncode == 2
    assert "expected to be on 'main'" in proc.stderr


def test_dry_run_leaves_the_index_untouched(tmp_path: Path):
    repo = tmp_path / "dry"
    repo.mkdir()
    _git(repo, "init", "-q", "-b", "main")
    (repo / "LICENSE").write_text("x\n")
    (repo / "TODO.md").write_text("x\n")
    _git(repo, "add", "-A")
    before = _git(repo, "ls-files", "--cached")
    proc = subprocess.run(
        ["python3", str(SCRIPT), "--allow-any-branch"],
        cwd=repo,
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0
    assert "DRY RUN" in proc.stdout
    assert _git(repo, "ls-files", "--cached") == before


def test_from_ref_is_read_only_and_needs_no_squash(tmp_path: Path):
    """The drift check must run from any branch with nothing staged.

    CLAUDE.md tells the operator to run `make release-preview` periodically
    rather than only at release time. That promise is only true if the preview
    works off a ref instead of a staged squash.
    """
    repo = tmp_path / "ref"
    repo.mkdir()
    _git(repo, "init", "-q", "-b", "develop")
    _git(repo, "config", "user.email", "t@t")
    _git(repo, "config", "user.name", "t")
    (repo / "LICENSE").write_text("x\n")
    (repo / "CLAUDE.md").write_text("x\n")
    _git(repo, "add", "-A")
    _git(repo, "commit", "-q", "-m", "init")

    proc = subprocess.run(
        ["python3", str(SCRIPT), "--from-ref", "develop"],
        cwd=repo,
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0, proc.stderr
    assert "WOULD SHIP" in proc.stdout
    assert "DRIFT CHECK" in proc.stdout
    # Ran on a branch that is not main, with an empty index.
    assert not _git(repo, "diff", "--cached", "--name-only").strip()


def test_from_ref_refuses_execute(tmp_path: Path):
    """--from-ref cannot stage; combining it with --execute is a usage error."""
    repo = tmp_path / "refx"
    repo.mkdir()
    _git(repo, "init", "-q", "-b", "main")
    _git(repo, "config", "user.email", "t@t")
    _git(repo, "config", "user.name", "t")
    (repo / "LICENSE").write_text("x\n")
    _git(repo, "add", "-A")
    _git(repo, "commit", "-q", "-m", "init")
    proc = subprocess.run(
        ["python3", str(SCRIPT), "--from-ref", "main", "--execute"],
        cwd=repo,
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 2
    assert "read-only" in proc.stderr
