"""Tests for `scripts/dawproject-annotations.py` (Story 15.8).

Every `.dawproject` here is synthetic: a zip holding only a hand-built
`project.xml`, written into pytest's `tmp_path` together with a synthetic OA300
ground-truth JAMS file. Logic rows call the extractor in-process; the
repository-walk test runs it as a subprocess so the protected-path assertion
covers a real invocation.
"""

from __future__ import annotations

import importlib.util
import json
import math
import os
import subprocess
import sys
import zipfile
from pathlib import Path
from xml.sax.saxutils import quoteattr

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts" / "dawproject-annotations.py"


def _load():
    """Load the hyphenated CLI as a module (the conftest.py convention).

    Registered in `sys.modules` before execution because `dataclasses` resolves
    string annotations through the defining module's entry there. Bytecode
    writing is off for the load, so no `.pyc` lands in `scripts/__pycache__`,
    and the flag the extractor sets at import is restored afterwards so the
    rest of the pytest process is unaffected.
    """
    saved = sys.dont_write_bytecode
    sys.dont_write_bytecode = True
    try:
        spec = importlib.util.spec_from_file_location("dawproject_annotations", SCRIPT)
        assert spec and spec.loader
        mod = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = mod
        spec.loader.exec_module(mod)
    finally:
        sys.dont_write_bytecode = saved
    return mod


annotations = _load()

# --- synthetic inputs ---------------------------------------------------------

DURATION = 120.0
END = (256.0, DURATION)  # end-of-file warp: never an anchor


def clip(name: str, warps, *, comment: str = "", duration: float | str = DURATION) -> dict:
    return {"file": f"audio/{name}", "warps": warps, "comment": comment, "duration": duration}


def project_xml(
    clips: list[dict],
    *,
    ts=(4, 4),
    ts_automation: bool = False,
    application: bool = True,
    warps_units: tuple[str, str] = ("beats", "seconds"),
) -> str:
    tracks, lanes = [], []
    for i, c in enumerate(clips):
        tid = f"t{i}"
        tracks.append(
            f'<Track contentType="audio" id="{tid}" name="track {i}" comment={quoteattr(c["comment"])}/>'
        )
        warp_xml = "".join(f'<Warp time="{t}" contentTime="{ct}"/>' for t, ct in c["warps"])
        lanes.append(
            f'<Lanes track="{tid}" id="l{i}"><Clips id="c{i}">'
            f'<Clip time="0.0" duration="300.0" playStart="0.0" name="clip {i}"><Clips id="ic{i}">'
            f'<Clip time="0.0" duration="300.0" contentTimeUnit="beats" playStart="0.0">'
            f'<Warps contentTimeUnit="{warps_units[1]}" timeUnit="{warps_units[0]}" id="w{i}">'
            f'<Audio algorithm="repitch" channels="2" sampleRate="44100" duration="{c["duration"]}" id="a{i}">'
            f"<File path={quoteattr(c['file'])}/></Audio>{warp_xml}</Warps>"
            f"</Clip></Clips></Clip></Clips></Lanes>"
        )
    automation = '<TimeSignatureAutomation id="tsa"/>' if ts_automation else ""
    app = '<Application name="Bitwig Studio" version="6.0.11"/>' if application else ""
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<Project version="1.0">{app}'
        '<Transport><Tempo unit="bpm" value="128.0" id="tempo"/>'
        f'<TimeSignature denominator="{ts[1]}" numerator="{ts[0]}" id="ts"/></Transport>'
        f"<Structure>{''.join(tracks)}</Structure>"
        f'<Arrangement id="arr"><Lanes timeUnit="beats" id="root">{"".join(lanes)}</Lanes>{automation}</Arrangement>'
        "</Project>"
    )


def write_dawproject(path: Path, xml: str) -> Path:
    with zipfile.ZipFile(path, "w") as zf:
        zf.writestr("project.xml", xml)
    return path


def write_ground_truth(
    path: Path, basenames: list[str], subdirs: dict[str, str] | None = None
) -> Path:
    entries = []
    for name in basenames:
        sandbox = {}
        if subdirs and name in subdirs:
            sandbox["subdir"] = subdirs[name]
        entries.append(
            {
                "file_metadata": {
                    "duration": 0,
                    "jams_version": "0.4.0",
                    "identifiers": {"basename": name, "local_path": name, "track_id": name},
                },
                "annotations": [
                    {
                        "namespace": "tempo",
                        "data": [{"time": 0.0, "duration": 0.0, "value": 128.0, "confidence": 1.0}],
                    }
                ],
                "sandbox": sandbox,
            }
        )
    path.write_text(json.dumps({"entries": entries}))
    return path


class Run:
    def __init__(self, code: int, stderr: str, out: Path):
        self.code = code
        self.stderr = stderr
        self.out = out

    @property
    def skips(self) -> list[str]:
        return [line for line in self.stderr.splitlines() if line.startswith("skip ")]

    @property
    def doc(self) -> dict:
        return json.loads(self.out.read_text())

    @property
    def entries(self) -> list[dict]:
        return self.doc["entries"]


@pytest.fixture
def run(tmp_path, capsys):
    """Build inputs in tmp_path and call the extractor in-process."""

    def _run(
        clips: list[dict],
        *,
        gt: list[str] | None = None,
        subdirs: dict[str, str] | None = None,
        extra: tuple[str, ...] = (),
        **xml_kwargs,
    ) -> Run:
        dawproject = write_dawproject(
            tmp_path / "corpus.dawproject", project_xml(clips, **xml_kwargs)
        )
        names = gt if gt is not None else [os.path.basename(c["file"]) for c in clips]
        match = write_ground_truth(tmp_path / "gt.json", names, subdirs)
        out = tmp_path / "daw-oracle-annotations.json"
        argv = ["--dawproject", str(dawproject), "--match", str(match), "--out", str(out), *extra]
        code = annotations.main(argv)
        return Run(code, capsys.readouterr().err, out)

    return _run


ANNOTATED = [(0.0, 0.0), (16.0, 7.5), (80.0, 37.5), END]


def _sandbox(entry: dict) -> dict:
    return entry["sandbox"]


def _annotation(entry: dict, namespace: str) -> dict:
    (ann,) = [a for a in entry["annotations"] if a["namespace"] == namespace]
    return ann


def _assert_inside_span(entry: dict) -> None:
    """Every number finite; every observation time inside the verified span (AC4)."""
    sb = _sandbox(entry)
    start, end = sb["verified_span_start_sec"], sb["verified_span_end_sec"]
    assert start < end
    assert start <= sb["reference_downbeat_time_sec"] <= end

    def walk(node):
        if isinstance(node, dict):
            for v in node.values():
                walk(v)
        elif isinstance(node, list):
            for v in node:
                walk(v)
        elif isinstance(node, float):
            assert math.isfinite(node)

    walk(entry)
    for ann in entry["annotations"]:
        for obs in ann["data"]:
            assert start <= obs["time"] <= end
            assert obs["time"] + obs["duration"] <= end + 1e-9
    for check in sb["distant_alignment_checks"]:
        assert start < check["time_sec"] < end


# --- I/O matrix: records ------------------------------------------------------


def test_annotated_clip(run):
    r = run([clip("x.wav", ANNOTATED, comment="level=half; unc=low; checked at bar 21")])
    assert r.code == 0
    assert r.skips == []
    (entry,) = r.entries
    assert entry["file_metadata"]["identifiers"] == {
        "basename": "x.wav",
        "local_path": "x.wav",
        "track_id": "x.wav",
    }
    assert entry["file_metadata"]["jams_version"] == "0.4.0"
    assert entry["file_metadata"]["duration"] == DURATION
    sb = _sandbox(entry)
    assert sb == {
        "reference_downbeat_time_sec": 7.5,
        "verified_bpm": 128.0,
        "declared_metrical_level": "half",
        "bar_position": 5,
        "verified_span_start_sec": 7.5,
        "verified_span_end_sec": 37.5,
        "distant_alignment_checks": [],
        "uncertainty": {"level": "low", "note": "checked at bar 21"},
        "annotation_version": "15.8.v1",
        "source": "bitwig-warp-bar-line-pair",
        "dawproject_application": {"name": "Bitwig Studio", "version": "6.0.11"},
    }
    tempo = _annotation(entry, "tempo")["data"]
    assert tempo == [{"time": 7.5, "duration": 30.0, "value": 128.0, "confidence": 1.0}]
    beats = _annotation(entry, "beat_position")["data"]
    assert [b["time"] for b in beats] == [7.5, 37.5]
    assert [b["value"] for b in beats] == [
        {"position": 1, "measure": 5, "num_beats": 4, "beat_units": 4},
        {"position": 1, "measure": 21, "num_beats": 4, "beat_units": 4},
    ]
    _assert_inside_span(entry)


def test_interior_check(run):
    warps = [(0.0, 0.0), (16.0, 7.5), (80.0, 37.49), (144.0, 67.5), END]
    r = run([clip("x.wav", warps)])
    (entry,) = r.entries
    sb = _sandbox(entry)
    assert (sb["verified_span_start_sec"], sb["verified_span_end_sec"]) == (7.5, 67.5)
    assert sb["verified_bpm"] == 128.0
    (check,) = sb["distant_alignment_checks"]
    assert check["bar_position"] == 21
    assert check["time_sec"] == 37.49
    assert check["residual_ms"] == pytest.approx(-10.0, abs=1e-6)
    assert len(_annotation(entry, "beat_position")["data"]) == 3
    _assert_inside_span(entry)


def test_bar_two_lower_bound(run):
    r = run([clip("x.wav", [(0.0, 0.0), (4.0, 1.875), (36.0, 16.875), END])])
    (entry,) = r.entries
    assert _sandbox(entry)["bar_position"] == 2
    measures = [b["value"]["measure"] for b in _annotation(entry, "beat_position")["data"]]
    assert measures == [2, 10]
    _assert_inside_span(entry)


def test_bar_two_just_below_the_integer_is_accepted(run):
    r = run([clip("x.wav", [(0.0, 0.0), (3.99994, 1.875), (36.0, 16.875), END])])
    (entry,) = r.entries
    assert _sandbox(entry)["bar_position"] == 2


def test_bar_two_outside_the_tolerance_is_rejected(run):
    r = run([clip("x.wav", [(0.0, 0.0), (3.9, 1.875), (36.0, 16.875), END])])
    assert r.entries == []
    assert r.skips == ["skip x.wav: no-declared-downbeat-anchor"]


def test_non_beat_warp_timeline_has_no_anchor(run):
    r = run([clip("x.wav", ANNOTATED)], warps_units=("seconds", "seconds"))
    assert r.code == 0
    assert r.entries == []
    assert r.skips == ["skip x.wav: no-declared-downbeat-anchor"]


def test_rounded_bar_gap_is_accepted(run):
    r = run([clip("x.wav", [(0.0, 0.0), (16.01, 7.5), (48.0, 22.5), END])])
    (entry,) = r.entries
    assert _sandbox(entry)["bar_position"] == 5
    measures = [b["value"]["measure"] for b in _annotation(entry, "beat_position")["data"]]
    assert measures == [5, 13]
    _assert_inside_span(entry)


def test_default_comment_values(run):
    (entry,) = run([clip("x.wav", ANNOTATED)]).entries
    sb = _sandbox(entry)
    assert sb["declared_metrical_level"] == "unspecified"
    assert sb["uncertainty"] == {
        "level": "medium",
        "note": "derived from bar-line warp pair; no operator comment",
    }


def test_comment_keys_are_case_insensitive(run):
    (entry,) = run([clip("x.wav", ANNOTATED, comment=" LEVEL = double ;Unc=high")]).entries
    sb = _sandbox(entry)
    assert sb["declared_metrical_level"] == "double"
    assert sb["uncertainty"]["level"] == "high"


def test_unsorted_warps_are_sorted(run):
    r = run([clip("x.wav", [(0.0, 0.0), (80.0, 37.5), (16.0, 7.5), END])])
    (entry,) = r.entries
    assert _sandbox(entry)["verified_span_start_sec"] == 7.5


def test_identifiers_follow_the_oracle_shape(run):
    r = run([clip("x.wav", ANNOTATED)], subdirs={"x.wav": "Bad BPM"})
    (entry,) = r.entries
    assert entry["file_metadata"]["identifiers"] == {
        "basename": "x.wav",
        "local_path": "Bad BPM/x.wav",
        "track_id": "x.wav",
    }


# --- I/O matrix: omitted clips ------------------------------------------------


@pytest.mark.parametrize(
    "warps,reason",
    [
        ([(0.0, 0.0), (928.00006, 327.53)], "no-declared-downbeat-anchor"),
        ([(0.0, 0.0), (0.986, 0.46), (928.00006, 327.53)], "no-declared-downbeat-anchor"),
        ([(0.0, 0.0), (16.0, 7.5), END], "no-declared-downbeat-anchor"),
        ([(0.0, 0.5), (32.0, 15.5), END], "no-declared-downbeat-anchor"),
        ([(0.0, 0.0), (16.0, 7.5), (40.0, 18.75), END], "verified-span-shorter-than-8-bars"),
        ([(16.0, 7.5), (33.3, 15.6), (80.0, 37.5), END], "unverified-warp-inside-span"),
        ([(0.0, 0.0), (16.0, 7.5), (80.0, 7.5), END], "warps-not-monotonic"),
        ([(0.0, 0.0), (16.0, "nan"), (80.0, 37.5), END], "warps-not-monotonic"),
    ],
    ids=[
        "origin-and-end-only",
        "three-point-legacy",
        "single-anchor",
        "origin-warp-with-offset",
        "pair-too-close",
        "nudge-inside-span",
        "equal-content-time",
        "non-finite",
    ],
)
def test_omitted_clip(run, warps, reason):
    r = run([clip("x.wav", warps, duration=327.53 if warps[-1][0] == 928.00006 else DURATION)])
    assert r.code == 0
    assert r.entries == []
    assert r.skips == [f"skip x.wav: {reason}"]


def test_non_finite_duration_is_rejected(run):
    r = run([clip("x.wav", ANNOTATED, duration="inf")])
    assert r.skips == ["skip x.wav: warps-not-monotonic"]


@pytest.mark.parametrize("comment", ["level=triplet", "unc=certain", "level=half; level=double"])
def test_bad_comment_token(run, comment):
    r = run([clip("x.wav", ANNOTATED, comment=comment)])
    assert r.code == 0
    assert r.entries == []
    assert r.skips == ["skip x.wav: invalid-comment-token"]


@pytest.mark.parametrize(
    "kwargs", [{"ts": (3, 4)}, {"ts_automation": True}], ids=["three-four", "automation"]
)
def test_not_four_four_skips_every_clip(run, kwargs):
    r = run([clip("x.wav", ANNOTATED), clip("y.wav", ANNOTATED)], **kwargs)
    assert r.code == 0
    assert r.entries == []
    assert r.skips == ["skip x.wav: time-signature-not-4-4", "skip y.wav: time-signature-not-4-4"]


def test_unmatched_ground_truth(run):
    r = run([clip("x.wav", ANNOTATED), clip("other.wav", ANNOTATED)], gt=["x.wav"])
    assert [e["file_metadata"]["identifiers"]["basename"] for e in r.entries] == ["x.wav"]
    assert r.skips == ["skip other.wav: unmatched-ground-truth"]


def test_duplicate_match_keeps_first_in_document_order(run):
    r = run(
        [clip("x.mp3", ANNOTATED, comment="first"), clip("x.wav", ANNOTATED, comment="second")],
        gt=["x.mp3"],
    )
    (entry,) = r.entries
    assert entry["sandbox"]["uncertainty"]["note"] == "first"
    assert r.skips == ["skip x.wav: duplicate-ground-truth-match"]


def test_duplicate_match_is_reserved_by_a_skipped_clip(run):
    r = run([clip("x.mp3", [(0.0, 0.0), END]), clip("x.wav", ANNOTATED)], gt=["x.mp3"])
    assert r.entries == []
    assert r.skips == [
        "skip x.mp3: no-declared-downbeat-anchor",
        "skip x.wav: duplicate-ground-truth-match",
    ]


def test_entries_sorted_by_ground_truth_filename(run):
    r = run([clip("b.wav", ANNOTATED), clip("a.wav", ANNOTATED)])
    assert [e["file_metadata"]["identifiers"]["basename"] for e in r.entries] == ["a.wav", "b.wav"]


def test_zero_records_writes_empty_document(run):
    r = run([clip("x.wav", [(0.0, 0.0), END])])
    assert r.code == 0
    assert r.out.read_bytes() == b'{\n  "entries": []\n}\n'


# --- determinism and --check --------------------------------------------------


def test_rerun_is_byte_identical_and_check_passes(run):
    clips = [
        clip(
            "x.wav", [(0.0, 0.0), (16.0, 7.5), (80.0, 37.49), (144.0, 67.5), END], comment="unc=low"
        )
    ]
    first = run(clips)
    first_bytes = first.out.read_bytes()
    second = run(clips)
    assert second.out.read_bytes() == first_bytes
    checked = run(clips, extra=("--check",))
    assert checked.code == 0
    assert checked.out.read_bytes() == first_bytes


def test_check_missing_output(run):
    r = run([clip("x.wav", ANNOTATED)], extra=("--check",))
    assert r.code == 1
    assert not r.out.exists()
    assert r.stderr.splitlines()[-1].endswith("is missing")


def test_check_entry_count_mismatch(run, tmp_path):
    seeded = b'{\n  "entries": []\n}\n'
    (tmp_path / "daw-oracle-annotations.json").write_bytes(seeded)
    checked = run([clip("x.wav", ANNOTATED)], extra=("--check",))
    assert checked.code == 1
    assert checked.stderr.splitlines()[-1].endswith("differs at entry x.wav")
    assert checked.out.read_bytes() == seeded


def test_check_non_document_output(run, tmp_path):
    seeded = b'"seeded"\n'
    (tmp_path / "daw-oracle-annotations.json").write_bytes(seeded)
    checked = run([clip("x.wav", ANNOTATED)], extra=("--check",))
    assert checked.code == 1
    assert checked.stderr.splitlines()[-1].endswith("is not an annotations document")
    assert checked.out.read_bytes() == seeded


def test_check_changed_output(run):
    r = run([clip("x.wav", ANNOTATED)])
    doc = r.doc
    doc["entries"][0]["sandbox"]["verified_bpm"] = 127.0
    stale = (json.dumps(doc, sort_keys=True, indent=2) + "\n").encode()
    r.out.write_bytes(stale)
    checked = run([clip("x.wav", ANNOTATED)], extra=("--check",))
    assert checked.code == 1
    assert checked.stderr.splitlines()[-1].endswith("differs at entry x.wav")
    assert checked.out.read_bytes() == stale


# --- exit 2 -------------------------------------------------------------------


def _seed_output(tmp_path: Path) -> tuple[Path, bytes]:
    out = tmp_path / "daw-oracle-annotations.json"
    seeded = b'{"entries": ["seeded"]}\n'
    out.write_bytes(seeded)
    return out, seeded


def _call(capsys, dawproject: Path, match: Path, out: Path) -> tuple[int, str]:
    code = annotations.main(
        ["--dawproject", str(dawproject), "--match", str(match), "--out", str(out)]
    )
    return code, capsys.readouterr().err


@pytest.mark.parametrize(
    "case",
    [
        "missing",
        "not-zip",
        "no-project-xml",
        "parse-error",
        "missing-attribute",
        "missing-application",
    ],
)
def test_unreadable_dawproject(tmp_path, capsys, case):
    out, seeded = _seed_output(tmp_path)
    match = write_ground_truth(tmp_path / "gt.json", ["x.wav"])
    dawproject = tmp_path / "corpus.dawproject"
    if case == "not-zip":
        dawproject.write_text("not a zip")
    elif case == "no-project-xml":
        with zipfile.ZipFile(dawproject, "w") as zf:
            zf.writestr("metadata.xml", "<MetaData/>")
    elif case == "parse-error":
        write_dawproject(dawproject, "<Project><Unclosed></Project>")
    elif case == "missing-attribute":
        xml = project_xml([clip("x.wav", ANNOTATED)]).replace('contentTime="7.5"', "")
        write_dawproject(dawproject, xml)
    elif case == "missing-application":
        write_dawproject(dawproject, project_xml([clip("x.wav", ANNOTATED)], application=False))
    code, err = _call(capsys, dawproject, match, out)
    assert code == 2
    assert len(err.splitlines()) == 1
    assert err.startswith("error: ")
    assert out.read_bytes() == seeded


@pytest.mark.parametrize(
    "payload",
    [
        None,
        "{not json",
        '{"no_entries": []}',
        '{"entries": [{"annotations": []}]}',
        '{"entries": [{"file_metadata": {}, "annotations": '
        '[{"namespace": "tempo", "data": [{"value": 128.0}]}]}]}',
    ],
)
def test_invalid_match_file(tmp_path, capsys, payload):
    out, seeded = _seed_output(tmp_path)
    dawproject = write_dawproject(
        tmp_path / "corpus.dawproject", project_xml([clip("x.wav", ANNOTATED)])
    )
    match = tmp_path / "gt.json"
    if payload is not None:
        match.write_text(payload)
    code, err = _call(capsys, dawproject, match, out)
    assert code == 2
    assert len(err.splitlines()) == 1
    assert out.read_bytes() == seeded


def test_output_directory_missing(tmp_path, capsys):
    dawproject = write_dawproject(
        tmp_path / "corpus.dawproject", project_xml([clip("x.wav", ANNOTATED)])
    )
    match = write_ground_truth(tmp_path / "gt.json", ["x.wav"])
    code, err = _call(capsys, dawproject, match, tmp_path / "absent" / "out.json")
    assert code == 2
    assert err.startswith("error: ")


@pytest.mark.skipif(
    hasattr(os, "geteuid") and os.geteuid() == 0, reason="root ignores directory permissions"
)
def test_unwritable_output_leaves_nothing_behind(tmp_path, capsys):
    dawproject = write_dawproject(
        tmp_path / "corpus.dawproject", project_xml([clip("x.wav", ANNOTATED)])
    )
    match = write_ground_truth(tmp_path / "gt.json", ["x.wav"])
    locked = tmp_path / "locked"
    locked.mkdir()
    seeded = b"seeded\n"
    (locked / "out.json").write_bytes(seeded)
    locked.chmod(0o555)
    try:
        code, err = _call(capsys, dawproject, match, locked / "out.json")
        assert code == 2
        assert len(err.splitlines()) == 1
        assert sorted(p.name for p in locked.iterdir()) == ["out.json"]
        assert (locked / "out.json").read_bytes() == seeded
    finally:
        locked.chmod(0o755)


# --- AC5: no write outside the tmp corpus path -------------------------------


PROTECTED = [
    REPO_ROOT / "_bmad-output" / "ml-training" / "eval-corpus",
    REPO_ROOT / "_bmad-output" / "ml-training" / "tony-corpus" / "tony-truth-labels.json",
    REPO_ROOT / "scripts",
]


def _stat(path: Path) -> tuple[int, int]:
    st = os.stat(path)
    return (st.st_size, st.st_mtime_ns)


def _snapshot() -> dict[str, tuple[int, int]]:
    """`{path: (size, mtime_ns)}` for every file under the protected roots, `__pycache__` included.

    Size and modification time rather than a content hash: `eval-corpus/` holds
    gigabytes of audio, and any write the extractor made would move the mtime.
    """
    snap: dict[str, tuple[int, int]] = {}
    for root in PROTECTED:
        if root.is_file():
            snap[root.relative_to(REPO_ROOT).as_posix()] = _stat(root)
        elif root.is_dir():
            for path in root.rglob("*"):
                if path.is_file():
                    snap[path.relative_to(REPO_ROOT).as_posix()] = _stat(path)
    return snap


def test_subprocess_run_touches_no_protected_path(tmp_path):
    corpus = tmp_path / "oa300"
    corpus.mkdir()
    dawproject = write_dawproject(
        tmp_path / "corpus.dawproject",
        project_xml([clip("x.wav", ANNOTATED), clip("y.wav", [(0.0, 0.0), END])]),
    )
    match = write_ground_truth(tmp_path / "gt.json", ["x.wav", "y.wav"])
    out = corpus / "daw-oracle-annotations.json"

    before = _snapshot()
    assert any(key.startswith("scripts/") for key in before)
    env = {**os.environ, "PYTHONDONTWRITEBYTECODE": "1"}
    proc = subprocess.run(
        [
            sys.executable,
            str(SCRIPT),
            "--dawproject",
            str(dawproject),
            "--match",
            str(match),
            "--out",
            str(out),
        ],
        capture_output=True,
        text=True,
        env=env,
        cwd=tmp_path,
        check=False,
    )
    after = _snapshot()

    assert proc.returncode == 0, proc.stderr
    assert proc.stderr.splitlines() == ["skip y.wav: no-declared-downbeat-anchor"]
    assert len(json.loads(out.read_text())["entries"]) == 1
    assert sorted(p.name for p in corpus.iterdir()) == ["daw-oracle-annotations.json"]
    assert after == before


def test_run_writes_no_bytecode_without_the_environment_flag(tmp_path):
    """The script itself turns bytecode off before loading `dawproject-bpm.py`.

    Run from a copy so a `__pycache__` directory, if one appeared, would be
    unambiguous; PYTHONDONTWRITEBYTECODE and PYTHONPYCACHEPREFIX are removed from
    the environment, since either would make the assertion pass vacuously.
    """
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    for name in ("dawproject-annotations.py", "dawproject-bpm.py"):
        (bin_dir / name).write_bytes((REPO_ROOT / "scripts" / name).read_bytes())
    dawproject = write_dawproject(
        tmp_path / "corpus.dawproject", project_xml([clip("x.wav", ANNOTATED)])
    )
    match = write_ground_truth(tmp_path / "gt.json", ["x.wav"])
    env = {
        k: v
        for k, v in os.environ.items()
        if k not in ("PYTHONDONTWRITEBYTECODE", "PYTHONPYCACHEPREFIX")
    }
    proc = subprocess.run(
        [
            sys.executable,
            str(bin_dir / "dawproject-annotations.py"),
            "--dawproject",
            str(dawproject),
            "--match",
            str(match),
            "--out",
            str(tmp_path / "out.json"),
        ],
        capture_output=True,
        text=True,
        env=env,
        cwd=tmp_path,
        check=False,
    )
    assert proc.returncode == 0, proc.stderr
    assert sorted(p.name for p in bin_dir.iterdir()) == [
        "dawproject-annotations.py",
        "dawproject-bpm.py",
    ]
