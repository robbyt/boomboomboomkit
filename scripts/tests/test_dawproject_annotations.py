"""Tests for `scripts/dawproject-annotations.py` (Story 15.8).

Every `.dawproject` here is synthetic: a zip holding only a hand-built
`project.xml`, written into pytest's `tmp_path` together with a synthetic OA300
ground-truth JAMS file. The real-export replay rebuilds one clip from the
Bitwig 6.1.4 export inspected for W102 with its exact offset, warp and duration
values. Logic rows call the extractor in-process; the
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
import xml.etree.ElementTree as ET
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

# 128 BPM: one beat is 0.46875 s, so arrangement bar N at zero offset is 1.875 * (N - 1) s.
SEC_PER_BEAT = 60.0 / 128.0
DURATION = 120.0
END = (256.0, DURATION)  # end-of-file warp at bar line 65, exactly the end of the audio
ANNOTATED = [(0.0, 0.0), END]  # the tempo warp alone, as every corpus clip has it
DECLARED = "bar=5-21"

# The real Bitwig 6.1.4 export (W102): track e3-22fffe3b2c53, 140 BPM, drop on bar 49.
REAL_WARPS = [(0.0, 0.0), (789.6455583572388, 338.419525)]
REAL_DURATION = 338.419525
REAL_OFFSET = 62.3652  # 0 + 0 - (-62.3652) - 0


def clip(
    name: str,
    warps,
    *,
    comment: str = "",
    duration: float | str = DURATION,
    outer_time: float | str | None = 0.0,
    outer_play_start: float | str | None = 0.0,
    inner_time: float | str | None = 0.0,
    inner_play_start: float | str | None = 0.0,
    track: str | None = None,
) -> dict:
    """One clip. A `None` offset attribute is left out of the XML.

    Clips given the same `track` share one track and one lane, in the order given,
    and the first one's comment is the track Comment; by default each clip gets its own.
    """
    return {
        "track": track,
        "file": f"audio/{name}",
        "warps": warps,
        "comment": comment,
        "duration": duration,
        "outer": {"time": outer_time, "playStart": outer_play_start},
        "inner": {"time": inner_time, "playStart": inner_play_start},
    }


def real_clip(comment: str, **kwargs) -> dict:
    kwargs.setdefault("outer_play_start", -REAL_OFFSET)
    return clip(
        "e3-22fffe3b2c53.mp3", REAL_WARPS, comment=comment, duration=REAL_DURATION, **kwargs
    )


def _attrs(values: dict) -> str:
    return "".join(f' {k}="{v}"' for k, v in values.items() if v is not None)


def _clip_xml(i: int, c: dict, warps_units: tuple[str, str]) -> str:
    """The outer clip, its inner clip and the warps, as Bitwig nests them."""
    warp_xml = "".join(f'<Warp time="{t}" contentTime="{ct}"/>' for t, ct in c["warps"])
    return (
        f'<Clip{_attrs(c["outer"])} duration="900.0" name="clip {i}"><Clips id="ic{i}">'
        f'<Clip{_attrs(c["inner"])} duration="900.0" contentTimeUnit="beats">'
        f'<Warps contentTimeUnit="{warps_units[1]}" timeUnit="{warps_units[0]}" id="w{i}">'
        f'<Audio algorithm="repitch" channels="2" sampleRate="44100" duration="{c["duration"]}" id="a{i}">'
        f"<File path={quoteattr(c['file'])}/></Audio>{warp_xml}</Warps>"
        f"</Clip></Clips></Clip>"
    )


def project_xml(
    clips: list[dict],
    *,
    ts=(4, 4),
    ts_automation: bool = False,
    application: bool = True,
    warps_units: tuple[str, str] = ("beats", "seconds"),
) -> str:
    groups: dict[str, list[tuple[int, dict]]] = {}
    for i, c in enumerate(clips):
        groups.setdefault(c["track"] or f"t{i}", []).append((i, c))
    tracks, lanes = [], []
    for n, (tid, members) in enumerate(groups.items()):
        comment = members[0][1]["comment"]
        tracks.append(
            f'<Track contentType="audio" id="{tid}" name="track {n}" comment={quoteattr(comment)}/>'
        )
        clip_xml = "".join(_clip_xml(i, c, warps_units) for i, c in members)
        lanes.append(f'<Lanes track="{tid}" id="l{n}"><Clips id="c{n}">{clip_xml}</Clips></Lanes>')
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
        match: bool = True,
        extra: tuple[str, ...] = (),
        **xml_kwargs,
    ) -> Run:
        dawproject = write_dawproject(
            tmp_path / "corpus.dawproject", project_xml(clips, **xml_kwargs)
        )
        out = tmp_path / "daw-oracle-annotations.json"
        argv = ["--dawproject", str(dawproject), "--out", str(out), *extra]
        if match:
            names = gt if gt is not None else [os.path.basename(c["file"]) for c in clips]
            gt_path = write_ground_truth(tmp_path / "gt.json", names, subdirs)
            argv += ["--match", str(gt_path)]
        code = annotations.main(argv)
        return Run(code, capsys.readouterr().err, out)

    return _run


def _sandbox(entry: dict) -> dict:
    return entry["sandbox"]


def _annotation(entry: dict, namespace: str) -> dict:
    (ann,) = [a for a in entry["annotations"] if a["namespace"] == namespace]
    return ann


def _measures(entry: dict) -> list[int]:
    return [b["value"]["measure"] for b in _annotation(entry, "beat_position")["data"]]


def _real_seconds(bar: int, offset: float = REAL_OFFSET) -> float:
    """Content seconds of arrangement bar `bar` on the real clip's single warp segment."""
    content_beat = 4 * (bar - 1) - offset
    return content_beat / REAL_WARPS[1][0] * REAL_WARPS[1][1]


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
    r = run([clip("x.wav", ANNOTATED, comment="level=half; unc=low; bar=5-21; checked at 21")])
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
        "uncertainty": {"level": "low", "note": "checked at 21"},
        "annotation_version": "15.8.v2",
        "source": "bitwig-clip-offset-bar-comment",
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


def test_real_export_replay(run):
    r = run([real_clip("level=quarter; unc=low; bar=49; bass drops on 49")])
    assert r.skips == []
    (entry,) = r.entries
    sb = _sandbox(entry)
    assert sb["reference_downbeat_time_sec"] == pytest.approx(55.558, abs=1e-3)
    assert sb["verified_span_start_sec"] == sb["reference_downbeat_time_sec"]
    assert sb["verified_bpm"] == pytest.approx(140.0, abs=1e-6)
    assert sb["bar_position"] == 49
    assert sb["declared_metrical_level"] == "quarter"
    assert sb["uncertainty"] == {"level": "low", "note": "bass drops on 49"}
    # Defaulted end: the last arrangement bar line whose content beat is still on the warp
    # map, floor((last warp beat + offset) / 4) + 1, which here also lands before the
    # end-of-file second.
    last_beat = REAL_WARPS[-1][0]
    end_bar = math.floor((last_beat + REAL_OFFSET) / 4) + 1
    assert 4 * (end_bar - 1) - REAL_OFFSET < last_beat
    assert _real_seconds(end_bar) < REAL_DURATION
    assert sb["verified_span_end_sec"] == pytest.approx(_real_seconds(end_bar), abs=1e-6)
    assert _measures(entry) == [49, end_bar]
    assert sb["distant_alignment_checks"] == []
    _assert_inside_span(entry)


def test_outer_time_and_outer_play_start_agree(run):
    comment = "level=quarter; unc=low; bar=49; bass drops on 49"
    slid = run([real_clip(comment)]).entries
    moved = run([real_clip(comment, outer_time=REAL_OFFSET, outer_play_start=0.0)]).entries
    assert [_sandbox(e) for e in moved] == [_sandbox(e) for e in slid]


def test_missing_offset_attributes_count_as_zero(run):
    explicit = run([clip("x.wav", ANNOTATED, comment=DECLARED)]).entries
    omitted = run(
        [
            clip(
                "x.wav",
                ANNOTATED,
                comment=DECLARED,
                outer_time=None,
                outer_play_start=None,
                inner_time=None,
                inner_play_start=None,
            )
        ]
    ).entries
    assert omitted == explicit


@pytest.mark.parametrize(
    "kwargs",
    [{"inner_time": -0.1341}, {"inner_play_start": 0.1341}],
    ids=["inner-time", "inner-play-start"],
)
def test_inner_clip_offset_shifts_the_mapping(run, kwargs):
    # offset = -0.1341, so bar 5 (arrangement beat 16) is content beat 16.1341.
    (entry,) = run([clip("x.wav", ANNOTATED, comment=DECLARED, **kwargs)]).entries
    sb = _sandbox(entry)
    assert sb["verified_span_start_sec"] == pytest.approx(16.1341 * SEC_PER_BEAT, abs=1e-6)
    assert sb["verified_span_end_sec"] == pytest.approx(80.1341 * SEC_PER_BEAT, abs=1e-6)
    assert sb["verified_bpm"] == 128.0
    assert sb["bar_position"] == 5
    _assert_inside_span(entry)


def test_explicit_span_end(run):
    (entry,) = run([real_clip("bar=49-113")]).entries
    sb = _sandbox(entry)
    assert sb["verified_span_start_sec"] == pytest.approx(_real_seconds(49), abs=1e-6)
    assert sb["verified_span_end_sec"] == pytest.approx(_real_seconds(113), abs=1e-6)
    assert _measures(entry) == [49, 113]
    _assert_inside_span(entry)


def test_zero_offset_bar_two(run):
    (entry,) = run([clip("x.wav", ANNOTATED, comment="bar=2")]).entries
    sb = _sandbox(entry)
    assert sb["bar_position"] == 2
    assert sb["verified_span_start_sec"] == 1.875
    # Bar 65 sits on the end-of-file second, so the defaulted end is bar 64.
    assert sb["verified_span_end_sec"] == 63 * 4 * SEC_PER_BEAT
    assert _measures(entry) == [2, 64]
    _assert_inside_span(entry)


def test_bar_line_warp_inside_span_is_a_check(run):
    r = run([clip("x.wav", [(0.0, 0.0), (80.0, 37.5), END], comment="bar=5-41")])
    (entry,) = r.entries
    sb = _sandbox(entry)
    (check,) = sb["distant_alignment_checks"]
    assert check["bar_position"] == 21
    assert check["time_sec"] == 37.5
    assert check["residual_ms"] == pytest.approx(0.0, abs=1e-6)
    assert _measures(entry) == [5, 21, 41]
    _assert_inside_span(entry)


def test_bar_line_warp_off_the_line_reports_a_residual(run):
    # The warp sits 10 ms early. The start and end bar seconds come from the same warp map,
    # so the moved point pulls them too and the residual is smaller than 10 ms, not zero.
    warps = [(0.0, 0.0), (80.0, 37.49), END]
    (entry,) = run([clip("x.wav", warps, comment="bar=5-41")]).entries
    start = 16.0 / 80.0 * 37.49
    end = 37.49 + (160.0 - 80.0) / (256.0 - 80.0) * (DURATION - 37.49)
    bpm = 144.0 / (end - start) * 60.0
    expected_ms = (37.49 - (start + 64.0 * 60.0 / bpm)) * 1000.0
    (check,) = _sandbox(entry)["distant_alignment_checks"]
    assert check["bar_position"] == 21
    assert check["residual_ms"] == pytest.approx(expected_ms, abs=1e-5)
    assert check["residual_ms"] < -5.0
    _assert_inside_span(entry)


def test_warp_within_tolerance_of_the_start_bar_is_that_bar_line(run):
    warps = [(0.0, 0.0), (16.01, 16.01 * SEC_PER_BEAT), END]
    (entry,) = run([clip("x.wav", warps, comment=DECLARED)]).entries
    assert _sandbox(entry)["distant_alignment_checks"] == []
    assert _measures(entry) == [5, 21]


def test_origin_nudge_before_the_span_is_accepted(run):
    # The corpus shape: a collinear second warp under one beat, left over from placing beat 1.
    warps = [(0.0, 0.0), (0.986, 0.986 * SEC_PER_BEAT), END]
    (entry,) = run([clip("x.wav", warps, comment="bar=5")]).entries
    sb = _sandbox(entry)
    assert sb["distant_alignment_checks"] == []
    assert sb["verified_span_start_sec"] == pytest.approx(7.5, abs=1e-6)
    assert sb["verified_bpm"] == pytest.approx(128.0, abs=1e-6)
    _assert_inside_span(entry)


def test_default_comment_values(run):
    (entry,) = run([clip("x.wav", ANNOTATED, comment="bar=5")]).entries
    sb = _sandbox(entry)
    assert sb["declared_metrical_level"] == "unspecified"
    assert sb["uncertainty"] == {
        "level": "medium",
        "note": "derived from clip offset and bar comment; no free text",
    }


def test_comment_keys_are_case_insensitive(run):
    comment = " LEVEL = double ;Unc=high; BAR = 5 - 21"
    (entry,) = run([clip("x.wav", ANNOTATED, comment=comment)]).entries
    sb = _sandbox(entry)
    assert sb["declared_metrical_level"] == "double"
    assert sb["uncertainty"]["level"] == "high"
    assert _measures(entry) == [5, 21]


def test_unsorted_warps_are_sorted(run):
    r = run([clip("x.wav", [(80.0, 37.5), (0.0, 0.0), END], comment="bar=5-41")])
    (entry,) = r.entries
    assert _sandbox(entry)["verified_span_start_sec"] == 7.5
    assert len(_sandbox(entry)["distant_alignment_checks"]) == 1


def test_two_clips_on_one_track_skip_together(run):
    r = run(
        [
            clip("x.wav", ANNOTATED, comment=DECLARED, track="shared"),
            clip("y.wav", ANNOTATED, track="shared"),
            clip("z.wav", ANNOTATED, comment=DECLARED),
        ]
    )
    assert r.code == 0
    assert [e["file_metadata"]["identifiers"]["basename"] for e in r.entries] == ["z.wav"]
    assert r.skips == [
        "skip x.wav: multiple-clips-on-track",
        "skip y.wav: multiple-clips-on-track",
    ]


def test_nested_track_lanes_visit_each_clip_once(tmp_path):
    # A group lane holding a child lane. The Clip wrapped around the child lane is not
    # one of the child clip's own enclosing clips, so its offset must not be counted.
    inner = _clip_xml(0, clip("x.wav", ANNOTATED, inner_time=-0.1341), ("beats", "seconds"))
    xml = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Project version="1.0"><Application name="Bitwig Studio" version="6.0.11"/>'
        '<Transport><TimeSignature denominator="4" numerator="4" id="ts"/></Transport>'
        "<Structure>"
        '<Track contentType="tracks" id="group" name="group" comment="bar=9; group comment"/>'
        '<Track contentType="audio" id="child" name="child" comment="bar=5; child comment"/>'
        "</Structure>"
        '<Arrangement id="arr"><Lanes timeUnit="beats" id="root">'
        '<Lanes track="group" id="lg"><Clips id="gc"><Clip time="99.0" playStart="0.0">'
        f'<Lanes track="child" id="lc"><Clips id="cc">{inner}</Clips></Lanes>'
        "</Clip></Clips></Lanes>"
        "</Lanes></Arrangement></Project>"
    )
    (only,) = annotations.collect_clips(ET.fromstring(xml))
    assert only.track_id == "child"
    assert only.comment == "bar=5; child comment"
    assert only.clip_offsets_raw == (("0.0", "0.0"), ("-0.1341", "0.0"))

    dawproject = write_dawproject(tmp_path / "nested.dawproject", xml)
    out = tmp_path / "nested.json"
    assert annotations.main(["--dawproject", str(dawproject), "--out", str(out)]) == 0
    (entry,) = json.loads(out.read_text())["entries"]
    assert _sandbox(entry)["uncertainty"]["note"] == "child comment"
    assert _sandbox(entry)["verified_span_start_sec"] == pytest.approx(
        16.1341 * SEC_PER_BEAT, abs=1e-6
    )


def test_identifiers_follow_the_oracle_shape(run):
    r = run([clip("x.wav", ANNOTATED, comment=DECLARED)], subdirs={"x.wav": "Bad BPM"})
    (entry,) = r.entries
    assert entry["file_metadata"]["identifiers"] == {
        "basename": "x.wav",
        "local_path": "Bad BPM/x.wav",
        "track_id": "x.wav",
    }


# --- I/O matrix: omitted clips ------------------------------------------------


@pytest.mark.parametrize("comment", ["", "level=half; unc=low; verified by ear"])
def test_no_bar_token_is_not_annotated(run, comment):
    r = run([clip("x.wav", ANNOTATED, comment=comment)])
    assert r.code == 0
    assert r.entries == []
    assert r.skips == ["skip x.wav: no-declared-downbeat-bar"]


@pytest.mark.parametrize(
    "comment",
    [
        "level=triplet; bar=5",
        "unc=certain; bar=5",
        "level=half; level=double; bar=5",
        "bar=0",
        "bar=x",
        "bar=10-10",
        "bar=10-9",
        "bar=5; bar=6",
        "bar=",
        "bar=5-",
        "bar=1234567",
        pytest.param("bar=" + "9" * 5000, id="bar-5000-digits"),
        pytest.param("bar=5-" + "9" * 5000, id="span-end-5000-digits"),
    ],
)
def test_bad_comment_token(run, comment):
    r = run([clip("x.wav", ANNOTATED, comment=comment)])
    assert r.code == 0
    assert r.entries == []
    assert r.skips == ["skip x.wav: invalid-comment-token"]


@pytest.mark.parametrize(
    "factory,reason",
    [
        (lambda: clip("x.wav", ANNOTATED, comment="bar=1"), "declared-bar-outside-audio"),
        (lambda: clip("x.wav", ANNOTATED, comment="bar=65"), "declared-bar-outside-audio"),
        (lambda: clip("x.wav", ANNOTATED, comment="bar=200"), "declared-bar-outside-audio"),
        (lambda: clip("x.wav", ANNOTATED, comment="bar=5-65"), "declared-bar-outside-audio"),
        (lambda: real_clip("bar=16"), "declared-bar-outside-audio"),
        (lambda: real_clip("bar=49-56"), "verified-span-shorter-than-8-bars"),
        (lambda: clip("x.wav", ANNOTATED, comment="bar=60"), "verified-span-shorter-than-8-bars"),
        (
            lambda: clip("x.wav", [(0.0, 0.0), (33.3, 15.6), END], comment="bar=5"),
            "unverified-warp-inside-span",
        ),
        (
            lambda: clip(
                "x.wav",
                [(0.0, 0.0), (80.0, 37.5), (80.01, 80.01 * SEC_PER_BEAT), END],
                comment="bar=5-41",
            ),
            "unverified-warp-inside-span",
        ),
        (
            lambda: clip("x.wav", [(0.0, 0.0), (16.0, 7.5), (80.0, 7.5), END], comment="bar=5"),
            "warps-not-monotonic",
        ),
        (
            lambda: clip("x.wav", [(0.0, 0.0), (16.0, "nan"), END], comment="bar=5"),
            "warps-not-monotonic",
        ),
        (
            lambda: clip("x.wav", ANNOTATED, comment="bar=5", outer_play_start="nan"),
            "clip-offset-not-finite",
        ),
        (
            lambda: clip("x.wav", ANNOTATED, comment="bar=5", inner_time="x"),
            "clip-offset-not-finite",
        ),
    ],
    ids=[
        "bar-one-at-audio-start",
        "bar-on-end-of-file",
        "bar-past-the-end",
        "span-end-on-end-of-file",
        "real-bar-before-audio",
        "explicit-span-too-short",
        "defaulted-span-too-short",
        "nudge-inside-span",
        "two-warps-on-one-bar-line",
        "equal-content-time",
        "non-finite-warp",
        "non-finite-offset",
        "unparseable-offset",
    ],
)
def test_omitted_clip(run, factory, reason):
    c = factory()
    r = run([c])
    assert r.code == 0
    assert r.entries == []
    assert r.skips == [f"skip {os.path.basename(c['file'])}: {reason}"]


def test_non_finite_duration_is_rejected(run):
    r = run([clip("x.wav", ANNOTATED, comment=DECLARED, duration="inf")])
    assert r.skips == ["skip x.wav: warps-not-monotonic"]


def test_non_beat_warp_timeline_is_rejected(run):
    r = run([clip("x.wav", ANNOTATED, comment=DECLARED)], warps_units=("seconds", "seconds"))
    assert r.code == 0
    assert r.entries == []
    assert r.skips == ["skip x.wav: warps-not-beats-seconds"]


@pytest.mark.parametrize(
    "kwargs", [{"ts": (3, 4)}, {"ts_automation": True}], ids=["three-four", "automation"]
)
def test_not_four_four_skips_every_clip(run, kwargs):
    clips = [clip("x.wav", ANNOTATED, comment=DECLARED), clip("y.wav", ANNOTATED, comment=DECLARED)]
    r = run(clips, **kwargs)
    assert r.code == 0
    assert r.entries == []
    assert r.skips == ["skip x.wav: time-signature-not-4-4", "skip y.wav: time-signature-not-4-4"]


def test_unmatched_ground_truth(run):
    clips = [
        clip("x.wav", ANNOTATED, comment=DECLARED),
        clip("other.wav", ANNOTATED, comment=DECLARED),
    ]
    r = run(clips, gt=["x.wav"])
    assert [e["file_metadata"]["identifiers"]["basename"] for e in r.entries] == ["x.wav"]
    assert r.skips == ["skip other.wav: unmatched-ground-truth"]


def test_duplicate_match_keeps_first_in_document_order(run):
    r = run(
        [
            clip("x.mp3", ANNOTATED, comment=f"{DECLARED}; first"),
            clip("x.wav", ANNOTATED, comment=f"{DECLARED}; second"),
        ],
        gt=["x.mp3"],
    )
    (entry,) = r.entries
    assert entry["sandbox"]["uncertainty"]["note"] == "first"
    assert r.skips == ["skip x.wav: duplicate-basename"]


def test_duplicate_match_is_reserved_by_a_skipped_clip(run):
    r = run([clip("x.mp3", ANNOTATED), clip("x.wav", ANNOTATED, comment=DECLARED)], gt=["x.mp3"])
    assert r.entries == []
    assert r.skips == [
        "skip x.mp3: no-declared-downbeat-bar",
        "skip x.wav: duplicate-basename",
    ]


def test_without_match_identifiers_are_the_audio_basename(run):
    r = run(
        [
            clip("x.wav", ANNOTATED, comment=f"{DECLARED}; first"),
            clip("x.wav", ANNOTATED, comment=f"{DECLARED}; second"),
            clip("not-in-any-ground-truth.wav", ANNOTATED, comment=DECLARED),
        ],
        match=False,
    )
    assert r.code == 0
    assert [e["file_metadata"]["identifiers"] for e in r.entries] == [
        {
            "basename": "not-in-any-ground-truth.wav",
            "local_path": "not-in-any-ground-truth.wav",
            "track_id": "not-in-any-ground-truth.wav",
        },
        {"basename": "x.wav", "local_path": "x.wav", "track_id": "x.wav"},
    ]
    assert r.entries[1]["sandbox"]["uncertainty"]["note"] == "first"
    assert r.skips == ["skip x.wav: duplicate-basename"]
    assert "unmatched-ground-truth" not in r.stderr


def test_entries_sorted_by_ground_truth_filename(run):
    r = run(
        [clip("b.wav", ANNOTATED, comment=DECLARED), clip("a.wav", ANNOTATED, comment=DECLARED)]
    )
    assert [e["file_metadata"]["identifiers"]["basename"] for e in r.entries] == ["a.wav", "b.wav"]


def test_zero_records_writes_empty_document(run):
    r = run([clip("x.wav", ANNOTATED)])
    assert r.code == 0
    assert r.out.read_bytes() == b'{\n  "entries": []\n}\n'


# --- determinism and --check --------------------------------------------------


def test_rerun_is_byte_identical_and_check_passes(run):
    clips = [clip("x.wav", [(0.0, 0.0), (80.0, 37.49), END], comment="unc=low; bar=5-41")]
    first = run(clips)
    first_bytes = first.out.read_bytes()
    assert len(first.entries) == 1
    second = run(clips)
    assert second.out.read_bytes() == first_bytes
    checked = run(clips, extra=("--check",))
    assert checked.code == 0
    assert checked.out.read_bytes() == first_bytes


def test_check_missing_output(run):
    r = run([clip("x.wav", ANNOTATED, comment=DECLARED)], extra=("--check",))
    assert r.code == 1
    assert not r.out.exists()
    assert r.stderr.splitlines()[-1].endswith("is missing")


def test_check_entry_count_mismatch(run, tmp_path):
    seeded = b'{\n  "entries": []\n}\n'
    (tmp_path / "daw-oracle-annotations.json").write_bytes(seeded)
    checked = run([clip("x.wav", ANNOTATED, comment=DECLARED)], extra=("--check",))
    assert checked.code == 1
    assert checked.stderr.splitlines()[-1].endswith("differs at entry x.wav")
    assert checked.out.read_bytes() == seeded


def test_check_non_document_output(run, tmp_path):
    seeded = b'"seeded"\n'
    (tmp_path / "daw-oracle-annotations.json").write_bytes(seeded)
    checked = run([clip("x.wav", ANNOTATED, comment=DECLARED)], extra=("--check",))
    assert checked.code == 1
    assert checked.stderr.splitlines()[-1].endswith("is not an annotations document")
    assert checked.out.read_bytes() == seeded


def test_check_changed_output(run):
    r = run([clip("x.wav", ANNOTATED, comment=DECLARED)])
    doc = r.doc
    doc["entries"][0]["sandbox"]["verified_bpm"] = 127.0
    stale = (json.dumps(doc, sort_keys=True, indent=2) + "\n").encode()
    r.out.write_bytes(stale)
    checked = run([clip("x.wav", ANNOTATED, comment=DECLARED)], extra=("--check",))
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
        xml = project_xml([clip("x.wav", ANNOTATED, comment=DECLARED)]).replace(
            'contentTime="120.0"', ""
        )
        write_dawproject(dawproject, xml)
    elif case == "missing-application":
        write_dawproject(
            dawproject, project_xml([clip("x.wav", ANNOTATED, comment=DECLARED)], application=False)
        )
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
        tmp_path / "corpus.dawproject", project_xml([clip("x.wav", ANNOTATED, comment=DECLARED)])
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
        tmp_path / "corpus.dawproject", project_xml([clip("x.wav", ANNOTATED, comment=DECLARED)])
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
        tmp_path / "corpus.dawproject", project_xml([clip("x.wav", ANNOTATED, comment=DECLARED)])
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
        project_xml([clip("x.wav", ANNOTATED, comment=DECLARED), clip("y.wav", ANNOTATED)]),
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
    assert proc.stderr.splitlines() == ["skip y.wav: no-declared-downbeat-bar"]
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
        tmp_path / "corpus.dawproject", project_xml([clip("x.wav", ANNOTATED, comment=DECLARED)])
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
