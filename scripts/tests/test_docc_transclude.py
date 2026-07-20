"""W87 — behavioral coverage for `scripts/docc-transclude.py`.

One test (or one parametrized family) per row of the W87 spec I/O matrix. Every
test drives the real `main(argv)` with both `--docs-root` and `--output-dir`
pinned into pytest's `tmp_path`; the generator's repo-rooted defaults are never
exercised, so no run can touch
`Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Cases/`.

Failure tests assert three things, not just the raised exception: the exit code
is 1, a pre-seeded output dir is left byte-identical, and no `.cases-tmp-*` /
`.cases-bak-*` sibling survives in the output parent. An exception alone would
pass even if the generator had already clobbered `Cases/` on the way out.

Run: `make scripts-tests`.
"""

from __future__ import annotations

import errno
import os
import pathlib
import types
from typing import TYPE_CHECKING

import pytest

if TYPE_CHECKING:  # `conftest` resolves at runtime under pytest, but not to linters.
    from conftest import Workspace

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def expect_abort(docc: types.ModuleType, argv: list[str], workspace: Workspace) -> None:
    """Run `main(argv)`, asserting exit 1 with the output dir left untouched.

    Proves: the run exited 1; `workspace.output_dir` is in the SAME state
    afterwards as before (byte-identical contents, and the same
    absent/non-directory/symlink state, since `Workspace.snapshot` gives those
    shapes distinguishable values rather than an empty dict); and no
    `.cases-tmp-*` / `.cases-bak-*` sibling survives in the output parent.

    Does NOT prove: that the run failed for the intended REASON (assert a
    message fragment from `capsys` for that), nor anything about `--docs-root`
    or about paths outside `workspace.output_dir` and its parent.

    `before` is captured inside the helper so a caller cannot forget it. Callers
    that need the stderr text use `capsys` around this call.
    """
    before = workspace.snapshot()
    with pytest.raises(SystemExit) as excinfo:
        docc.main(argv)
    assert excinfo.value.code == 1
    assert workspace.snapshot() == before
    assert workspace.temp_residue() == []


def _under(path: object, root: pathlib.Path) -> bool:
    """True if `path` (str or PathLike) sits at or under `root`."""
    try:
        return pathlib.Path(os.fspath(path)).resolve().is_relative_to(root.resolve())
    except (TypeError, ValueError, OSError):
        return False


def patch_rename(
    docc: types.ModuleType,
    monkeypatch: pytest.MonkeyPatch,
    tmp_path: pathlib.Path,
    failing_calls: set[int],
) -> dict[str, int]:
    """Make the Nth in-`tmp_path` `os.rename` inside the generator raise.

    Deliberately narrow on three axes, because a blunt patch of the global `os`
    module would poison every `os.rename` in the pytest process (pytest's own
    tmp-dir bookkeeping included), share one counter across unrelated callers,
    and silently drop the `src_dir_fd` / `dst_dir_fd` keyword-only arguments:

    1. Scope: the module attribute `docc.os` is rebound to a proxy, so only the
       generator's own lookups are affected; the real `os` module is untouched.
    2. Selectivity: the counter advances and a failure fires ONLY when both
       operands sit under this test's `tmp_path`.
    3. Signature: the replacement takes and forwards the real
       `os.rename(src, dst, *, src_dir_fd=None, dst_dir_fd=None)`.

    Returns the shared call counter so a test can assert how far the generator
    actually got.
    """
    calls = {"n": 0}
    real_rename = os.rename

    def flaky_rename(src, dst, *, src_dir_fd=None, dst_dir_fd=None):
        if _under(src, tmp_path) and _under(dst, tmp_path):
            calls["n"] += 1
            if calls["n"] in failing_calls:
                raise OSError(errno.EIO, "induced rename failure", str(dst))
        return real_rename(src, dst, src_dir_fd=src_dir_fd, dst_dir_fd=dst_dir_fd)

    class _OSProxy:
        """Forwards every attribute to the real `os` except `rename`."""

        def __init__(self) -> None:
            self.rename = flaky_rename

        def __getattr__(self, name: str) -> object:
            return getattr(os, name)

    monkeypatch.setattr(docc, "os", _OSProxy())
    return calls


# ---------------------------------------------------------------------------
# Row: generate happy path
# ---------------------------------------------------------------------------


def test_generate_writes_one_page_per_eligible_source(docc, workspace):
    workspace.write_case("BPMSelectionPolicy", "dedup")
    workspace.write_case("BPMSelectionPolicy", "quorum")
    workspace.write_case("VotingPolicy", "simpleMajority")

    docc.main(workspace.argv())

    assert sorted(workspace.snapshot()) == [
        "BPMSelectionPolicy-dedup.md",
        "BPMSelectionPolicy-quorum.md",
        "VotingPolicy-simpleMajority.md",
    ]


def test_generated_page_is_h1_plus_byte_identical_body(docc, workspace):
    # The body carries a nested `---` and a trailing blank line: the strip must
    # end at the FIRST closing delimiter and reproduce everything after it
    # byte-for-byte, including the source's trailing newline.
    body = "Intro line.\n\n---\n\nAfter a horizontal rule.\n"
    workspace.write_case("VotingPolicy", "thresholdGated", body=body)

    docc.main(workspace.argv())

    page = (workspace.output_dir / "VotingPolicy-thresholdGated.md").read_bytes()
    assert page == b"# ``VotingPolicy/thresholdGated``\n\n" + body.encode("utf-8")


# ---------------------------------------------------------------------------
# Row: associated-value symbol
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("type_name", "stem", "symbol"),
    [
        ("EnsemblePolicy", "weightedVoting", "weightedVoting(_:)"),
        ("MLExecutionPolicy", "whenDSPConfidenceBelow", "whenDSPConfidenceBelow(_:)"),
        ("DownbeatResult", "detected", "detected(estimate:)"),
        ("AbstainReason", "sourceSpecific", "sourceSpecific(_:)"),
        ("DemotionReason", "sourceSpecific", "sourceSpecific(_:)"),
    ],
)
def test_assoc_value_case_h1_carries_the_signature(docc, workspace, type_name, stem, symbol):
    workspace.write_case(type_name, stem)

    docc.main(workspace.argv())

    page = (workspace.output_dir / f"{type_name}-{stem}.md").read_bytes()
    assert page.startswith(f"# ``{type_name}/{symbol}``\n\n".encode("utf-8"))


def test_value_only_case_h1_uses_the_bare_stem(docc, workspace):
    # Same stem, a type NOT in ASSOC_VALUE_SIGNATURES: no signature suffix.
    workspace.write_case("BPMSelectionPolicy", "weightedVoting")

    docc.main(workspace.argv())

    page = (workspace.output_dir / "BPMSelectionPolicy-weightedVoting.md").read_bytes()
    assert page.startswith(b"# ``BPMSelectionPolicy/weightedVoting``\n\n")


# ---------------------------------------------------------------------------
# Row: underscore exclusion
# ---------------------------------------------------------------------------


def test_underscore_dir_and_underscore_stem_are_skipped(docc, workspace):
    workspace.write_case("DSPTechnique", "acfSharpening")
    workspace.write_case("_Fixture", "_probe")  # underscore DIR
    workspace.write_case("DSPTechnique", "_probe")  # underscore STEM in a live dir

    docc.main(workspace.argv())

    assert sorted(workspace.snapshot()) == ["DSPTechnique-acfSharpening.md"]


# ---------------------------------------------------------------------------
# Row: stale-page sweep
# ---------------------------------------------------------------------------


def test_generate_sweeps_orphan_pages(docc, workspace):
    workspace.seed_output({"Gone-orphan.md": b"# ``Gone/orphan``\n\nstale\n"})
    workspace.write_case("DSPTechnique", "superFluxOnset")

    docc.main(workspace.argv())

    assert sorted(workspace.snapshot()) == ["DSPTechnique-superFluxOnset.md"]
    assert workspace.temp_residue() == []


# ---------------------------------------------------------------------------
# Row: fresh parent
# ---------------------------------------------------------------------------


def test_generate_creates_a_missing_output_parent(docc, workspace, tmp_path):
    workspace.output_dir = tmp_path / "no" / "such" / "parent" / "Cases"
    workspace.write_case("AnalysisIntensity", "level7")

    docc.main(workspace.argv())

    assert sorted(workspace.snapshot()) == ["AnalysisIntensity-level7.md"]
    assert workspace.temp_residue() == []


# ---------------------------------------------------------------------------
# Row: malformed source
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("label", "data", "message_fragment"),
    [
        ("no_opening", b"id: x\n---\nBody\n", "missing opening front-matter delimiter"),
        ("no_closing", b"---\nid: x\nBody\n", "missing closing front-matter delimiter"),
        ("cr_in_body", b"---\nid: x\n---\nBody\r\nmore\n", "contains a CR byte"),
        ("bad_utf8", b"---\nid: x\n---\nBody \xff\xfe\n", "not valid UTF-8"),
    ],
)
def test_malformed_source_aborts_leaving_output_untouched(
    docc, workspace, capsys, label, data, message_fragment
):
    workspace.seed_output()
    # The valid sibling's stem sorts BEFORE every `label` below, so the walk has
    # already transformed a good file when it reaches the malformed one — this is
    # a mid-corpus abort, not a first-file abort.
    workspace.write_case("DSPTechnique", "acfSharpening")
    assert "acfSharpening" < label
    workspace.write_raw("DSPTechnique", f"{label}.md", data)

    expect_abort(docc, workspace.argv(), workspace)

    assert message_fragment in capsys.readouterr().err


# ---------------------------------------------------------------------------
# Row: output-name collision
# ---------------------------------------------------------------------------


def test_output_name_collision_aborts(docc, workspace, capsys):
    # `A/B-c.md` and `A-B/c.md` both map to `A-B-c.md`.
    workspace.seed_output()
    workspace.write_case("A", "B-c")
    workspace.write_case("A-B", "c")

    expect_abort(docc, workspace.argv(), workspace)

    assert "collides with" in capsys.readouterr().err


# ---------------------------------------------------------------------------
# Row: path overlap
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("relation", ["equal", "inside", "contains"])
def test_path_overlap_is_rejected(docc, workspace, capsys, relation):
    workspace.write_case("VotingPolicy", "confidenceWeighted")
    if relation == "equal":
        output = workspace.docs_root
    elif relation == "inside":
        output = workspace.docs_root / "Cases"
    else:
        output = workspace.docs_root.parent  # contains docs_root

    # Keyed by path RELATIVE TO docs_root, not by basename: two same-named files
    # in different type dirs would otherwise collapse into one set member and a
    # write could slip through unnoticed.
    docs_before = {
        p.relative_to(workspace.docs_root).as_posix() for p in workspace.docs_root.rglob("*")
    }
    with pytest.raises(SystemExit) as excinfo:
        docc.main(["--docs-root", str(workspace.docs_root), "--output-dir", str(output)])

    assert excinfo.value.code == 1
    assert "overlaps docs-root" in capsys.readouterr().err
    # Nothing was written: the corpus is untouched and no temp dir was minted.
    docs_after = {
        p.relative_to(workspace.docs_root).as_posix() for p in workspace.docs_root.rglob("*")
    }
    assert docs_after == docs_before
    # Residue is checked in the parent the OVERLAPPING output path would live in
    # (which differs per relation), not in a fixed directory.
    assert sorted(p.name for p in output.parent.glob(".cases-*")) == []


# ---------------------------------------------------------------------------
# Row: missing docs-root
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("kind", ["absent", "regular_file", "broken_symlink"])
def test_missing_docs_root_is_rejected(docc, workspace, tmp_path, capsys, kind):
    workspace.seed_output()
    if kind == "absent":
        docs = tmp_path / "no-such-docs"
    elif kind == "regular_file":
        docs = tmp_path / "docs-as-file"
        docs.write_text("not a directory\n", encoding="utf-8")
    else:
        docs = tmp_path / "docs-dangling"
        docs.symlink_to(tmp_path / "target-that-does-not-exist")

    argv = ["--docs-root", str(docs), "--output-dir", str(workspace.output_dir)]
    expect_abort(docc, argv, workspace)

    assert "docs-root not found" in capsys.readouterr().err


# ---------------------------------------------------------------------------
# Row: no temp residue (success side; the failure side is asserted in
# `expect_abort`, which every failure test above routes through)
# ---------------------------------------------------------------------------


def test_no_temp_residue_after_a_successful_regenerate(docc, workspace):
    workspace.write_case("OctaveEquivalencePolicy", "exactMatchOnly")

    docc.main(workspace.argv())
    docc.main(workspace.argv())  # second pass exercises the move-aside/backup branch

    assert workspace.temp_residue() == []
    assert sorted(workspace.snapshot()) == ["OctaveEquivalencePolicy-exactMatchOnly.md"]


# ---------------------------------------------------------------------------
# Row: check round-trip (the PR #101 regression)
# ---------------------------------------------------------------------------


def test_check_passes_against_a_freshly_generated_dir(docc, workspace):
    workspace.write_case("EnsemblePolicy", "weightedVoting")
    workspace.write_case("EnsemblePolicy", "dspOnly")

    docc.main(workspace.argv())
    before = workspace.snapshot()

    docc.main(workspace.argv("--check"))  # no SystemExit == exit 0

    assert workspace.snapshot() == before  # --check writes nothing
    assert workspace.temp_residue() == []


# ---------------------------------------------------------------------------
# Row: check drift
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("drift", "message_fragment"),
    [
        ("missing", "page(s) missing"),
        ("extra", "stale/orphan page(s)"),
        ("byte", "drifted from its canonical source"),
    ],
)
def test_check_detects_drift(docc, workspace, capsys, drift, message_fragment):
    workspace.write_case("DSPTechnique", "adaptiveThreshold")
    workspace.write_case("DSPTechnique", "expandedCandidates")
    docc.main(workspace.argv())
    capsys.readouterr()  # discard the generate line

    target = workspace.output_dir / "DSPTechnique-adaptiveThreshold.md"
    if drift == "missing":
        target.unlink()
    elif drift == "extra":
        (workspace.output_dir / "DSPTechnique-orphan.md").write_bytes(b"# ``x``\n\ny\n")
    else:
        target.write_bytes(target.read_bytes().replace(b"Body", b"BODY"))

    expect_abort(docc, workspace.argv("--check"), workspace)

    assert message_fragment in capsys.readouterr().err


# ---------------------------------------------------------------------------
# Row: check empty / absent
# ---------------------------------------------------------------------------


def test_check_fails_on_an_empty_corpus(docc, workspace, capsys):
    workspace.seed_output()
    # docs_root exists but holds nothing eligible.
    workspace.write_case("_Fixture", "_probe")

    expect_abort(docc, workspace.argv("--check"), workspace)

    assert "no eligible source docs" in capsys.readouterr().err


def test_check_fails_when_the_output_dir_is_absent(docc, workspace, capsys):
    workspace.write_case("AbstainReason", "policyDisabled")
    assert not workspace.output_dir.exists()

    expect_abort(docc, workspace.argv("--check"), workspace)

    assert "dir missing at" in capsys.readouterr().err
    # Non-vacuous: `--check` must not have created the directory it complained
    # about. Asserting only the exit code would pass even if it had.
    assert not workspace.output_dir.exists()
    assert workspace.temp_residue() == []


def test_generate_on_an_empty_corpus_succeeds_and_writes_an_empty_dir(docc, workspace):
    # Documented asymmetry, encoded as-is (W87 spec Design Notes): `--check`
    # fails on an empty corpus but a plain generate succeeds with zero pages.
    # This is a characterization test, not an endorsement; changing it is an
    # "Ask First" against the generator, not a silent edit here.
    workspace.write_case("_Fixture", "_probe")

    docc.main(workspace.argv())

    assert workspace.output_dir.is_dir()
    assert workspace.snapshot() == {}
    assert workspace.temp_residue() == []


# ---------------------------------------------------------------------------
# Row: non-directory output-dir
#
# The defect this row exists for: before the guard, `atomic_swap` renamed the
# file or symlink sitting at `--output-dir` onto a `.cases-bak-*` name, made a
# fresh directory in its place, and then `shutil.rmtree(backup,
# ignore_errors=True)` no-opped because the backup was not a directory. The run
# printed "wrote N pages" and exited 0 while the original was displaced.
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("kind", ["regular_file", "symlink_to_dir", "broken_symlink"])
def test_non_directory_output_dir_is_rejected(docc, workspace, tmp_path, capsys, kind):
    workspace.write_case("SignalSource", "beatGrid")
    parent = tmp_path / "generated"
    parent.mkdir()
    output, expected_fragment = _plant_non_directory_output(kind, parent, tmp_path)

    argv = ["--docs-root", str(workspace.docs_root), "--output-dir", str(output)]
    with pytest.raises(SystemExit) as excinfo:
        docc.main(argv)

    assert excinfo.value.code == 1
    assert expected_fragment in capsys.readouterr().err
    # The existing path survives untouched, in place, with its original identity.
    if kind == "regular_file":
        assert output.is_file() and not output.is_symlink()
        assert output.read_bytes() == b"precious operator data\n"
    elif kind == "symlink_to_dir":
        assert output.is_symlink()
        assert output.resolve() == (tmp_path / "real-cases").resolve()
        assert (tmp_path / "real-cases" / "kept.md").read_bytes() == b"# kept\n"
    else:
        assert output.is_symlink() and not output.exists()
    # No rename happened, so nothing was minted or orphaned in the parent.
    assert sorted(p.name for p in parent.glob(".cases-*")) == []
    assert sorted(p.name for p in parent.iterdir()) == ["Cases"]


def _plant_non_directory_output(kind: str, parent: pathlib.Path, tmp_path: pathlib.Path):
    """Create the `kind` shape at `parent/Cases`; return (path, message fragment)."""
    output = parent / "Cases"
    if kind == "regular_file":
        output.write_bytes(b"precious operator data\n")
        return output, "exists and is not a directory"
    if kind == "symlink_to_dir":
        real_dir = tmp_path / "real-cases"
        real_dir.mkdir()
        (real_dir / "kept.md").write_bytes(b"# kept\n")
        output.symlink_to(real_dir)
        return output, "is a symlink"
    output.symlink_to(tmp_path / "target-that-does-not-exist")
    return output, "is a symlink"


@pytest.mark.parametrize("kind", ["regular_file", "symlink_to_dir", "broken_symlink"])
def test_check_rejects_a_non_directory_output_dir_with_the_same_message(
    docc, workspace, tmp_path, capsys, kind
):
    """`--check` and generate must agree on what a usable output dir is.

    They did not: the guard was called from `run_generate` only, so a
    symlink-to-directory at `--output-dir` passed `--check` with exit 0 while a
    generate hard-failed. And for a regular file `--check` reported the path as
    "missing", which is both false and a loop, since the `make docc-transclude`
    it recommends now refuses that same path.
    """
    workspace.write_case("SignalSource", "beatGrid")
    parent = tmp_path / "generated"
    parent.mkdir()
    output, expected_fragment = _plant_non_directory_output(kind, parent, tmp_path)

    argv = ["--docs-root", str(workspace.docs_root), "--output-dir", str(output)]
    with pytest.raises(SystemExit) as excinfo:
        docc.main([*argv, "--check"])

    assert excinfo.value.code == 1
    err = capsys.readouterr().err
    assert expected_fragment in err
    assert "dir missing at" not in err  # never reported as absent

    # Same shape under a generate: byte-identical message, so the modes agree.
    with pytest.raises(SystemExit) as excinfo:
        docc.main(argv)

    assert excinfo.value.code == 1
    assert capsys.readouterr().err == err
    assert sorted(p.name for p in parent.iterdir()) == ["Cases"]


def test_check_rejects_an_overlapping_docs_root_and_output_dir(docc, workspace, capsys):
    # `run_check` has its own `reject_path_overlap` call; the generate-side test
    # does not exercise it.
    workspace.write_case("VotingPolicy", "confidenceWeighted")
    output = workspace.docs_root / "Cases"

    with pytest.raises(SystemExit) as excinfo:
        docc.main(["--docs-root", str(workspace.docs_root), "--output-dir", str(output), "--check"])

    assert excinfo.value.code == 1
    assert "overlaps docs-root" in capsys.readouterr().err
    assert not output.exists()  # --check created nothing


def test_the_output_dir_guard_fires_before_the_corpus_is_collected(
    docc, workspace, tmp_path, capsys
):
    """Pin the call order inside `run_generate`.

    A non-directory `--output-dir` AND a malformed corpus are both fatal. The
    guard runs first, so the operator is told about the path they pointed at
    rather than about a source file, and no work is done on a corpus that was
    never going to be written anywhere valid.
    """
    workspace.write_raw("DSPTechnique", "broken.md", b"no front matter here\n")
    parent = tmp_path / "generated"
    parent.mkdir()
    output = parent / "Cases"
    output.write_bytes(b"precious operator data\n")

    argv = ["--docs-root", str(workspace.docs_root), "--output-dir", str(output)]
    with pytest.raises(SystemExit) as excinfo:
        docc.main(argv)

    assert excinfo.value.code == 1
    err = capsys.readouterr().err
    assert "exists and is not a directory" in err
    assert "missing opening front-matter delimiter" not in err
    assert output.read_bytes() == b"precious operator data\n"


# ---------------------------------------------------------------------------
# Row: rollback on mid-swap failure
# ---------------------------------------------------------------------------


def test_rollback_restores_the_original_when_the_swap_fails_mid_way(
    docc, workspace, monkeypatch, tmp_path, capsys
):
    """Exercise `atomic_swap`'s `finally` rollback, the least-reached branch.

    Every CLI-reachable failure aborts inside `collect_outputs`, which runs
    BEFORE any rename, so the untouched-output assertions elsewhere prove only
    that nothing moved. Here the second `os.rename` (temp dir -> output dir)
    raises, i.e. the failure lands AFTER the original was moved aside onto the
    `.cases-bak-*` name, which is the only state where rollback has work to do.
    """
    seeded = workspace.seed_output()
    workspace.write_case("SignalSource", "fileMetadata")

    # 1 = move the original aside, 2 = swap the temp dir into place, 3 = restore.
    calls = patch_rename(docc, monkeypatch, tmp_path, failing_calls={2})

    with pytest.raises(SystemExit) as excinfo:
        docc.main(workspace.argv())

    assert excinfo.value.code == 1
    assert calls["n"] >= 2  # the move-aside really did happen first
    assert "I/O failure" in capsys.readouterr().err
    assert workspace.snapshot() == seeded  # rolled back byte-identical
    assert workspace.temp_residue() == []


def test_a_failed_rollback_preserves_the_original_instead_of_deleting_it(
    docc, workspace, monkeypatch, tmp_path, capsys
):
    """The original must survive a restore that itself fails.

    Before the fix, `atomic_swap`'s `finally` swallowed the restore `OSError`
    and fell through to an unconditional `shutil.rmtree(backup)`, deleting the
    moved-aside original: the operator's only remaining copy. Now the backup is
    kept and the failure message names its path.
    """
    seeded = workspace.seed_output()
    workspace.write_case("SignalSource", "fileMetadata")

    # 2 = the swap into place, 3 = the rollback restore. Both fail, so the
    # original is stranded under its `.cases-bak-*` name.
    calls = patch_rename(docc, monkeypatch, tmp_path, failing_calls={2, 3})

    with pytest.raises(SystemExit) as excinfo:
        docc.main(workspace.argv())

    assert excinfo.value.code == 1
    assert calls["n"] >= 3  # the restore really was attempted
    err = capsys.readouterr().err
    assert "could not restore" in err
    assert "was NOT deleted" in err

    residue = workspace.temp_residue()
    assert [name for name in residue if name.startswith(".cases-tmp-")] == []
    backups = [name for name in residue if name.startswith(".cases-bak-")]
    assert len(backups) == 1, residue
    # The message names the surviving path, and that path holds the original.
    backup = workspace.output_dir.parent / backups[0]
    assert str(backup) in err
    assert {p.name: p.read_bytes() for p in backup.iterdir()} == seeded
    assert not workspace.output_dir.exists()


# ---------------------------------------------------------------------------
# Row: empty body
# ---------------------------------------------------------------------------


def test_empty_body_yields_the_h1_and_a_blank_line_only(docc, workspace):
    workspace.write_raw("VotingPolicy", "simpleMajority.md", b"---\nid: simpleMajority\n---\n")

    docc.main(workspace.argv())

    page = (workspace.output_dir / "VotingPolicy-simpleMajority.md").read_bytes()
    assert page == b"# ``VotingPolicy/simpleMajority``\n\n"


# ---------------------------------------------------------------------------
# Row: whole-file CRLF
# ---------------------------------------------------------------------------


def test_whole_file_crlf_is_rejected_as_a_missing_opening_delimiter(docc, workspace, capsys):
    # Characterization, not endorsement: because the opening line is `---\r`,
    # the failure is reported as a missing opening delimiter rather than as the
    # CR-byte violation the file actually is.
    workspace.seed_output()
    workspace.write_raw("DSPTechnique", "acfSharpening.md", b"---\r\nid: x\r\n---\r\nBody\r\n")

    expect_abort(docc, workspace.argv(), workspace)

    assert "missing opening front-matter delimiter" in capsys.readouterr().err


# ---------------------------------------------------------------------------
# Row: degenerate source bytes
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("label", "data"),
    [
        ("zero_byte", b""),
        ("utf8_bom", b"\xef\xbb\xbf---\nid: x\n---\nBody\n"),
    ],
)
def test_degenerate_source_bytes_are_rejected(docc, workspace, capsys, label, data):
    workspace.seed_output()
    workspace.write_raw("DSPTechnique", f"{label}.md", data)

    expect_abort(docc, workspace.argv(), workspace)

    assert "missing opening front-matter delimiter" in capsys.readouterr().err


# ---------------------------------------------------------------------------
# Row: unreadable source
# ---------------------------------------------------------------------------


def test_a_directory_named_like_a_source_file_is_rejected(docc, workspace, capsys):
    workspace.seed_output()
    workspace.write_case("DSPTechnique", "acfSharpening")
    (workspace.docs_root / "DSPTechnique" / "notAFile.md").mkdir()

    expect_abort(docc, workspace.argv(), workspace)

    # Assert the reason, not just the exit code: without this the test would
    # pass if the run had aborted for some unrelated cause.
    err = capsys.readouterr().err
    assert "notAFile.md: unreadable" in err


# ---------------------------------------------------------------------------
# Row: silent input drops
# ---------------------------------------------------------------------------


def test_loose_and_deeply_nested_sources_are_silently_ignored(docc, workspace):
    # Characterization of the depth-1 walk: only `<docs-root>/<Type>/<stem>.md`
    # is eligible. Both drops below are silent (no warning, no nonzero exit).
    workspace.write_case("DSPTechnique", "subBandNormalization")
    (workspace.docs_root / "loose.md").write_bytes(b"---\nid: loose\n---\nBody\n")
    nested = workspace.docs_root / "DSPTechnique" / "Nested"
    nested.mkdir()
    (nested / "deeper.md").write_bytes(b"---\nid: deeper\n---\nBody\n")

    docc.main(workspace.argv())

    assert sorted(workspace.snapshot()) == ["DSPTechnique-subBandNormalization.md"]


# ---------------------------------------------------------------------------
# Row: symlinked overlap
# ---------------------------------------------------------------------------


def test_a_docs_root_symlink_resolving_inside_the_output_dir_is_rejected(docc, tmp_path, capsys):
    # Lexically the two paths are unrelated; only because `reject_path_overlap`
    # resolves BOTH does the containment show up.
    output_dir = tmp_path / "out"
    real_docs = output_dir / "inner-docs"
    (real_docs / "DSPTechnique").mkdir(parents=True)
    (real_docs / "DSPTechnique" / "acfSharpening.md").write_bytes(b"---\nid: a\n---\nBody\n")
    docs_link = tmp_path / "docs-link"
    docs_link.symlink_to(real_docs)

    with pytest.raises(SystemExit) as excinfo:
        docc.main(["--docs-root", str(docs_link), "--output-dir", str(output_dir)])

    assert excinfo.value.code == 1
    assert "overlaps docs-root" in capsys.readouterr().err
    assert sorted(p.name for p in output_dir.iterdir()) == ["inner-docs"]
    assert sorted(p.name for p in tmp_path.glob(".cases-*")) == []


# ---------------------------------------------------------------------------
# Row: check ignores non-`.md`
# ---------------------------------------------------------------------------


def test_check_ignores_a_stray_non_md_file_that_a_generate_would_sweep(docc, workspace):
    # Second documented asymmetry, encoded as-is: `run_check` globs `*.md`, so a
    # stray `.txt` is invisible to it, while a generate rebuilds the directory
    # wholesale and drops the file. Changing either side is an "Ask First".
    workspace.write_case("DSPTechnique", "fineGridRefinement")
    docc.main(workspace.argv())
    stray = workspace.output_dir / "notes.txt"
    stray.write_bytes(b"stray\n")

    docc.main(workspace.argv("--check"))  # no SystemExit == exit 0

    assert stray.is_file()  # --check left it alone and did not complain

    docc.main(workspace.argv())  # a generate sweeps it

    assert not stray.exists()
    assert sorted(workspace.snapshot()) == ["DSPTechnique-fineGridRefinement.md"]


# ---------------------------------------------------------------------------
# Row: idempotency
# ---------------------------------------------------------------------------


def test_two_consecutive_generates_produce_identical_bytes(docc, workspace):
    workspace.write_case("EnsemblePolicy", "weightedVoting")
    workspace.write_case("AbstainReason", "sourceSpecific")
    workspace.write_case("BPMSelectionPolicy", "median", body="Median body.\n\n- a\n- b\n")

    docc.main(workspace.argv())
    first = workspace.snapshot()

    docc.main(workspace.argv())
    second = workspace.snapshot()

    assert first == second
    assert sorted(first) == [
        "AbstainReason-sourceSpecific.md",
        "BPMSelectionPolicy-median.md",
        "EnsemblePolicy-weightedVoting.md",
    ]
    assert workspace.temp_residue() == []


# ---------------------------------------------------------------------------
# Integration: the real per-case corpus
# ---------------------------------------------------------------------------


def expected_page_names_on_disk(docs_root: pathlib.Path) -> list[str]:
    """The `<Type>-<stem>.md` names, derived from disk, not from the generator.

    Computed independently of the generator's own walker and never hardcoded to
    49, so adding a case does not require touching this test. Asserting the NAME
    SET (not just the count) catches a mapping regression that happens to keep
    the cardinality intact.
    """
    return sorted(
        f"{type_dir.name}-{md_path.stem}.md"
        for type_dir in docs_root.iterdir()
        if type_dir.is_dir() and not type_dir.name.startswith("_")
        for md_path in type_dir.glob("*.md")
        if not md_path.name.startswith("_")
    )


def test_real_corpus_generates_then_checks_clean(docc, tmp_path, capsys):
    docs_root = docc.DEFAULT_DOCS_ROOT
    # A loud failure, not a skip: the corpus is committed and always present on
    # develop, so its absence means a broken checkout, not an excusable gap.
    assert docs_root.is_dir(), f"real corpus absent at {docs_root} (broken checkout?)"

    expected_names = expected_page_names_on_disk(docs_root)
    assert expected_names
    output_dir = tmp_path / "Cases"  # never the repo Cases/

    docc.main(["--docs-root", str(docs_root), "--output-dir", str(output_dir)])

    assert sorted(p.name for p in output_dir.glob("*.md")) == expected_names
    assert sorted(p.name for p in tmp_path.glob(".cases-*")) == []
    capsys.readouterr()

    # Round-trip: a just-generated dir must satisfy --check (PR #101 regression).
    docc.main(["--docs-root", str(docs_root), "--output-dir", str(output_dir), "--check"])

    assert f"{len(expected_names)} pages consistent" in capsys.readouterr().out
