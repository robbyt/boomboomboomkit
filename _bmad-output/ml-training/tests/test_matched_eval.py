"""Story 15.9: evaluation harness pure logic.

Synthetic inputs only: no corpus audio, no Swift runner, no network. Track ids
here are invented."""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path
from typing import Any

import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from matched_eval import corpora as cp  # noqa: E402
from matched_eval import metrics as mt  # noqa: E402
from matched_eval import report as rp  # noqa: E402
from matched_eval import stats as st  # noqa: E402

GIT = {"sha": "0" * 40, "dirty": False, "untrackedPaths": 0}


# ---------------------------------------------------------------------------
# Synthetic builders
# ---------------------------------------------------------------------------


def swift_record(
    tempo: float | None, *, status: str = "ok", reason: str | None = None, grid: Any = None
) -> dict[str, Any]:
    return {
        "status": status,
        "reason": reason,
        "tempoBPM": tempo,
        "grid": grid,
        "runtimeSeconds": 0.1,
        "peakMemoryAboveBaselineBytes": 1024,
        "variantIdentity": "synthetic",
        "buildConfiguration": "test",
    }


def manifest_and_runner(
    corpus: str,
    tracks: list[dict[str, Any]],
) -> tuple[dict[str, Any], dict[str, Any]]:
    """`tracks`: dicts with id, ref, style, systems (Swift records by system id),
    and optionally commercial and annotation."""
    rows = []
    runner_tracks = []
    for t in tracks:
        sha = hashlib.sha256(t["id"].encode()).hexdigest()
        rows.append(
            {
                "trackId": t["id"],
                "audioPath": f"/synthetic/audio/{t['id']}",
                "audioSha256": sha,
                "referenceBPM": t["ref"],
                "style": t.get("style", "untagged"),
                "commercialBPM": t.get("commercial"),
                "annotation": t.get("annotation"),
                "corpus": corpus,
            }
        )
        systems = {s: swift_record(t["ref"]) for s in rp.SWIFT_SYSTEMS}
        systems.update(t.get("systems", {}))
        runner_tracks.append(
            {"trackId": t["id"], "corpus": corpus, "audioSha256": sha, "systems": systems}
        )
    sources: dict[str, Any] = {
        "reference": {"name": "synthetic-reference.json", "sha256": "ab" * 32}
    }
    manifest = {
        "schema": cp.MANIFEST_SCHEMA,
        "corpora": {
            corpus: {"rows": rows, "sources": sources, "referenceKind": cp.REFERENCE_KIND[corpus]}
        },
    }
    runner = {
        "schema": "15.9-runner-output.v1",
        "buildConfiguration": "test",
        "memorySampling": "test",
        "tracks": runner_tracks,
    }
    return manifest, runner


def build(corpus: str, tracks: list[dict[str, Any]]):
    manifest, runner = manifest_and_runner(corpus, tracks)
    rows, digests = rp.build_rows(manifest, "cd" * 32, runner, None, GIT)
    return manifest, runner, rows


def annotation_120(start: float = 10.0, bars: int = 8) -> dict[str, Any]:
    """A 15.8-shaped annotation: a verified 120 BPM span of `bars` bars from `start`."""
    bar_s = 4 * 60.0 / 120.0
    lines = [[start + i * bar_s, float(1 + i)] for i in (0, bars)]
    return {
        "referenceDownbeatSeconds": start,
        "spanStartSeconds": start,
        "spanEndSeconds": start + bars * bar_s,
        "verifiedBPM": 120.0,
        "declaredLevel": "quarter",
        "barPosition": 1,
        "barLines": lines,
    }


def row_for(rows, system: str, track: str) -> dict[str, Any]:
    return next(r for r in rows if r["system"] == system and r["trackId"] == track)


# ---------------------------------------------------------------------------
# I/O matrix: tempo families
# ---------------------------------------------------------------------------


def test_exact_tempo():
    fam = mt.evaluate(swift_record(128.0), 128.0, None, runtime_comparable=True)
    assert fam["tempo_level"]["class"] == "same"
    assert all(fam["strict_tempo"][mt.strict_key(t)] for t in mt.STRICT_TOLERANCES)
    assert fam["fine_error"]["error_bpm"] == 0.0
    assert fam["fine_error"]["error_ppt"] == 0.0


def test_tolerance_edge():
    fam = mt.evaluate(swift_record(128.04), 128.0, None, runtime_comparable=True)
    assert fam["strict_tempo"]["0.10"] is True
    assert fam["strict_tempo"]["0.05"] is True
    assert fam["strict_tempo"]["0.02"] is False
    assert fam["fine_error"]["error_bpm"] == pytest.approx(0.04)
    assert fam["fine_error"]["error_ppt"] == pytest.approx(0.3125)


def test_octave_half():
    fam = mt.evaluate(swift_record(64.2), 128.0, None, runtime_comparable=True)
    assert fam["tempo_level"]["class"] == "half"
    assert not any(fam["strict_tempo"][mt.strict_key(t)] for t in mt.STRICT_TOLERANCES)


@pytest.mark.parametrize(
    "system,expected",
    [(256.0, "double"), (85.4, "two-thirds"), (192.0, "three-halves"), (100.0, "other")],
)
def test_level_classes(system, expected):
    assert mt.tempo_level_class(system, 128.0) == expected


# ---------------------------------------------------------------------------
# I/O matrix: grid families, abstention, analyzer coverage
# ---------------------------------------------------------------------------


def test_no_hand_annotation_reports_no_reference_and_leaves_pairings():
    tracks = [{"id": f"t{i}", "ref": 120.0} for i in range(12)]
    _, _, rows = build("oa300", tracks)
    for r in rows:
        for f in mt.GRID_FAMILIES:
            assert r["families"][f]["status"] == mt.NO_REFERENCE
    values = rp.metric_values(rows, "oa300")
    for metric in ("phase_error_s", "f_measure", "downbeat_correct", "drift_s"):
        assert not any(m == metric for (_s, m) in values)


def test_grid_families_on_a_synthetic_annotation():
    ann = annotation_120(start=10.0, bars=8)
    exact = {"tempoBPM": 120.0, "anchorSeconds": 0.5, "downbeat": {"status": "not-attempted"}}
    fam = mt.grid_families(exact, ann)
    assert fam["grid_phase"]["phase_error_s"] == pytest.approx(0.0, abs=1e-9)
    assert fam["beat_prf"]["f_measure"] == pytest.approx(1.0)
    assert fam["drift"]["drift_s"] == pytest.approx(0.0, abs=1e-9)
    assert fam["downbeat_phase"]["status"] == mt.NO_DATA

    late = {"tempoBPM": 120.0, "anchorSeconds": 0.53, "downbeat": {"anchorSeconds": 12.03}}
    fam = mt.grid_families(late, ann)
    assert fam["grid_phase"]["phase_error_s"] == pytest.approx(0.03)
    assert fam["downbeat_phase"]["downbeat_correct"] is True

    off = {"tempoBPM": 120.0, "anchorSeconds": 0.75, "downbeat": {}}
    assert mt.grid_families(off, ann)["beat_prf"]["f_measure"] == pytest.approx(0.0)

    fast = {"tempoBPM": 120.12, "anchorSeconds": 10.0, "downbeat": {}}
    drift = mt.grid_families(fast, ann)["drift"]
    # 32 beats at 120.12 BPM end 0.016 s before 16 s.
    assert drift["drift_s"] == pytest.approx(32 * 60 / 120.12 - 16.0)

    half = {"tempoBPM": 60.0, "anchorSeconds": 10.0, "downbeat": {}}
    assert mt.grid_families(half, ann)["drift"]["status"] == mt.LEVEL_MISMATCH


def test_reference_beats_follow_the_bar_lines():
    ann = annotation_120(start=2.0, bars=2)
    beats = mt.reference_beats(ann)
    assert beats.size == 9
    assert np.allclose(np.diff(beats), 0.5)


def test_joint_fit_abstention_is_counted_but_not_paired():
    tracks = [
        {
            "id": "t0",
            "ref": 120.0,
            "systems": {
                "variant-joint-fit": swift_record(
                    None, status="abstained", reason="joint-fit-returned-nil"
                )
            },
        },
        *({"id": f"t{i}", "ref": 120.0} for i in range(1, 12)),
    ]
    _, _, rows = build("oa300", tracks)
    jf = row_for(rows, "variant-joint-fit", "t0")
    assert jf["status"] == "abstained"
    assert jf["reason"] == "joint-fit-returned-nil"
    assert jf["families"]["failure"]["failed_or_abstained"] is True
    assert jf["families"]["tempo_level"]["status"] == "abstained"

    strata = rp._strata(rows, "oa300")
    pairs = rp.pairing_summaries(rows, "oa300", strata, None)
    level = next(
        p
        for p in pairs
        if p["a"] == "boomboomboomkit-optimal"
        and p["b"] == "variant-joint-fit"
        and p["metric"] == "level_same"
    )
    assert level["strata"]["overall"]["n"] == 11
    failure = next(
        p
        for p in pairs
        if p["a"] == "boomboomboomkit-optimal"
        and p["b"] == "variant-joint-fit"
        and p["metric"] == "failed_or_abstained"
    )
    assert failure["strata"]["overall"]["n"] == 12
    assert failure["strata"]["overall"]["n_negative"] == 1


@pytest.mark.parametrize("corpus", ["eval-12-7", "giantsteps"])
def test_commercial_analyzer_outside_oa300_is_not_run(corpus):
    _, _, rows = build(corpus, [{"id": "t0", "ref": 128.0, "commercial": 128.0}])
    row = row_for(rows, rp.COMMERCIAL, "t0")
    assert row["status"] == mt.NOT_RUN
    for name, f in row["families"].items():
        expected = mt.NO_REFERENCE if name in mt.GRID_FAMILIES else mt.NOT_RUN
        assert f["status"] == expected


def test_commercial_analyzer_on_oa300_has_tempo_only():
    _, _, rows = build("oa300", [{"id": "t0", "ref": 128.0, "commercial": 64.0}])
    row = row_for(rows, rp.COMMERCIAL, "t0")
    assert row["families"]["tempo_level"]["class"] == "half"
    assert row["families"]["runtime_memory"]["status"] == mt.NOT_APPLICABLE
    assert row["details"]["analyzerVersion"] == "unrecorded"
    ann_rows = build(
        "oa300", [{"id": "t0", "ref": 120.0, "commercial": 120.0, "annotation": annotation_120()}]
    )[2]
    assert row_for(ann_rows, rp.COMMERCIAL, "t0")["families"]["beat_prf"]["status"] == mt.NO_DATA


# ---------------------------------------------------------------------------
# Strata, statistics, labels
# ---------------------------------------------------------------------------


def test_underpowered_stratum_has_n_and_no_direction():
    # 6 tracks in 110-129 with a large consistent error, 10 in 150-179.
    tracks = [
        {
            "id": f"u{i}",
            "ref": 120.0,
            "style": "techno",
            "systems": {"boomboomboomkit-optimal": swift_record(121.0 + 0.1 * i)},
        }
        for i in range(6)
    ] + [
        {
            "id": f"v{i}",
            "ref": 170.0,
            "style": "drum-and-bass",
            "systems": {"boomboomboomkit-optimal": swift_record(171.0 + 0.1 * i)},
        }
        for i in range(10)
    ]
    manifest, runner, rows = build("oa300", tracks)
    agg = rp.aggregate(rows, manifest, {}, GIT, runner)
    c = agg["corpora"]["oa300"]
    assert c["strataN"]["band:110-129"] == 6
    pair = next(
        p
        for p in c["pairings"]
        if p["a"] == "boomboomboomkit-optimal" and p["b"] == "oracle" and p["metric"] == "error_bpm"
    )
    small = pair["strata"]["band:110-129"]
    assert small["n"] == 6 and small["underpowered"] is True
    assert small["interval_excludes_zero"] is True
    assert small["direction"] is None
    big = pair["strata"]["band:150-179"]
    assert big["underpowered"] is False
    assert big["direction"] is not None
    md = rp.render_markdown(agg)
    assert "| 110-129 | 6 | yes |" in md


def test_bootstrap_is_deterministic_and_uses_the_committed_parameters():
    rng = np.random.default_rng(1)
    d = rng.normal(0.3, 1.0, 40)
    a = st.paired_summary(list(d), "k")
    b = st.paired_summary(list(d), "k")
    assert a == b
    assert st.BOOTSTRAP_RESAMPLES == 10_000
    lo, hi = a["interval95"]
    assert lo <= a["median"] <= hi
    assert a["interval_excludes_zero"] == (lo > 0 or hi < 0)
    assert 0.0 <= a["wilcoxon_p"] <= 1.0


def test_all_zero_differences():
    s = st.paired_summary([0.0] * 12, "z")
    assert s["interval95"] == [0.0, 0.0]
    assert s["wilcoxon_p"] == 1.0
    assert s["interval_excludes_zero"] is False


@pytest.mark.parametrize(
    "bpm,band",
    [(60.0, "60-89"), (89.99, "60-89"), (90.0, "90-109"), (174.0, "150-179"), (210.0, "180-210")],
)
def test_tempo_bands(bpm, band):
    assert st.tempo_band(bpm) == band
    assert st.tempo_band(55.0) == st.OUTSIDE_BANDS


def test_pairing_labels():
    labels = {(a, b): rp.pairing_label(a, b) for a, b in rp.pairings()}
    assert len(labels) == 15
    assert all(b != rp.SYSTEMS[0] for _a, b in labels)
    assert labels[("boomboomboomkit-optimal", "commercial-analyzer")] == rp.SYSTEM_VS_SYSTEM
    assert labels[("commercial-analyzer", "oracle")] == rp.SYSTEM_VS_REFERENCE
    for (a, b), label in labels.items():
        assert (label == rp.SYSTEM_VS_REFERENCE) == (b == rp.ORACLE)
        assert a != rp.ORACLE


def test_giantsteps_pairings_are_tagged_crowdsourced():
    tracks = [{"id": f"g{i}", "ref": 128.0, "style": "techno"} for i in range(3)]
    manifest, runner, rows = build("giantsteps", tracks)
    agg = rp.aggregate(rows, manifest, {}, GIT, runner)
    pairs = agg["corpora"]["giantsteps"]["pairings"]
    assert pairs
    assert all(p["referenceTag"] == cp.CROWDSOURCED_TAG for p in pairs)


def test_direction_sentence_carries_pairing_n_interval_and_p():
    s = st.paired_summary([0.5 + 0.01 * i for i in range(20)], "d")
    text = rp.direction_sentence("oa300", "a-sys", "oracle", "system-vs-reference", "m", s, None)
    assert text is not None
    for part in ("`a-sys` vs `oracle`", "system-vs-reference", "n = 20", "95 % interval", "p ="):
        assert part in text


# ---------------------------------------------------------------------------
# Wording guard and tracked aggregate
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "text",
    [
        "boomboomboomkit-optimal matches commercial-analyzer on strict tempo",
        "the library meets the commercial-analyzer",
        "it Exceeds commercial-analyzer",
        "approaches the commercial-analyzer",
        "reaches parity with commercial-analyzer",
    ],
)
def test_wording_guard_rejects_comparison_words(text):
    with pytest.raises(rp.WordingViolation):
        rp.check_wording(text)


def test_wording_guard_allows_harness_names():
    rp.check_wording("Produced by `make matched-eval` into matched-eval-runs/.")


def test_generated_markdown_passes_the_guard_and_names_every_pairing():
    tracks = [
        {
            "id": f"t{i}",
            "ref": 170.0,
            "style": "drum-and-bass",
            "commercial": 170.0,
            "systems": {"boomboomboomkit-optimal": swift_record(85.0 if i % 3 else 170.2)},
        }
        for i in range(12)
    ]
    manifest, runner, rows = build("oa300", tracks)
    agg = rp.aggregate(rows, manifest, {"corpusManifestSha256": "cd" * 32}, GIT, runner)
    md = rp.render_markdown(agg)
    rp.check_wording(md)
    for p in agg["corpora"]["oa300"]["pairings"]:
        s = p["strata"]["overall"]
        assert {"n", "interval95", "wilcoxon_p", "interval_excludes_zero"} <= set(s)
        assert p["label"] in (rp.SYSTEM_VS_SYSTEM, rp.SYSTEM_VS_REFERENCE)
        assert f"#### `{p['a']}` vs `{p['b']}` ({p['label']}" in md


def test_render_markdown_refuses_forbidden_words(monkeypatch):
    tracks = [{"id": f"t{i}", "ref": 120.0} for i in range(3)]
    manifest, runner, rows = build("oa300", tracks)
    agg = rp.aggregate(rows, manifest, {}, GIT, runner)
    agg["systems"]["commercial-analyzer"] = "matches the library"
    with pytest.raises(rp.WordingViolation):
        rp.render_markdown(agg)


def test_tracked_aggregate_carries_no_track_identifiers():
    tracks = [{"id": f"e9-secret{i:04d}", "ref": 120.0 + i, "style": "untagged"} for i in range(12)]
    manifest, runner, rows = build("eval-12-7", tracks)
    agg = rp.aggregate(rows, manifest, {"corpusManifestSha256": "cd" * 32}, GIT, runner)
    text = rp.canonical_json(agg).decode() + rp.render_markdown(agg)
    rp.assert_no_track_identifiers(text, manifest)
    assert "e9-secret" not in text
    assert "/synthetic/audio" not in text
    with pytest.raises(rp.ReportRefusal):
        rp.assert_no_track_identifiers(text + "e9-secret0003", manifest)


def test_rows_carry_provenance():
    _, _, rows = build("oa300", [{"id": "t0", "ref": 120.0, "commercial": 120.0}])
    for r in rows:
        prov = r["provenance"]
        for key in (
            "gitSha",
            "dirty",
            "buildConfiguration",
            "system",
            "variantIdentity",
            "corpusManifestSha256",
            "audioSha256",
            "referenceSource",
            "referenceSha256",
        ):
            assert key in prov
        assert prov["system"] == r["system"]


def test_runner_output_must_cover_the_manifest():
    manifest, runner = manifest_and_runner("oa300", [{"id": "t0", "ref": 120.0}])
    runner["tracks"] = []
    with pytest.raises(rp.ReportRefusal):
        rp.build_rows(manifest, "x", runner, None, GIT)


# ---------------------------------------------------------------------------
# Corpora
# ---------------------------------------------------------------------------


def _jams_entry(path: str, bpm: float, genre: str | None = None) -> dict[str, Any]:
    entry: dict[str, Any] = {
        "file_metadata": {"identifiers": {"local_path": path, "basename": Path(path).name}},
        "annotations": [{"namespace": "tempo", "data": [{"time": 0.0, "value": bpm}]}],
        "sandbox": {},
    }
    if genre:
        entry["sandbox"]["genre"] = genre
    return entry


def test_duplicate_recording_keeps_the_wav(tmp_path):
    paths = ["5. Some Title.mp3", "5. Some Title.wav", "Sub/Other.aiff"]
    root = tmp_path / "oa300"
    (root / "Sub").mkdir(parents=True)
    for p in paths:
        (root / p).write_bytes(p.encode())
    (root / cp.ORACLE_FILENAME).write_text(
        json.dumps({"entries": [_jams_entry(p, 170.0) for p in paths]})
    )
    labels = tmp_path / "labels.json"
    labels.write_text(
        json.dumps({"entries": [_jams_entry(p, 85.0, "drum-and-bass") for p in paths]})
    )
    doc = cp.load_oa300(root, labels)
    ids = [r["trackId"] for r in doc["rows"]]
    assert ids == ["5. Some Title.wav", "Sub/Other.aiff"]
    assert doc["sources"]["duplicateRecordingsDropped"] == 1
    assert doc["rows"][0]["commercialBPM"] == 85.0
    assert doc["rows"][0]["annotation"] is None
    assert doc["sources"]["annotations"] is None


def test_duplicate_without_a_wav_refuses():
    with pytest.raises(cp.CorpusRefusal):
        cp.dedupe_recordings(["a.mp3", "a.m4a"])


def test_annotation_version_is_checked(tmp_path):
    entry = _jams_entry("x.wav", 120.0)
    entry["sandbox"] = {"annotation_version": "15.8.v1"}
    path = tmp_path / cp.ANNOTATIONS_FILENAME
    path.write_text(json.dumps({"entries": [entry]}))
    with pytest.raises(cp.CorpusRefusal):
        cp.load_annotations(path)
    assert cp.load_annotations(tmp_path / "absent.json") == ({}, None)


def test_changed_12_7_audio_refuses_naming_the_track(tmp_path):
    audio = tmp_path / "a.wav"
    audio.write_bytes(b"original")
    good = hashlib.sha256(b"original").hexdigest()
    audio.write_bytes(b"changed")
    gate = tmp_path / "bundle-gate-input-seed-42.json"
    gate.write_text(
        json.dumps(
            {
                "tracks": [
                    {
                        "trackId": "e9-row0001",
                        "category": "locked-12.7-member",
                        "audioPath": str(audio),
                        "audioSha256": good,
                        "groundTruthBPM": 128.0,
                    }
                ]
            }
        )
    )
    with pytest.raises(cp.CorpusRefusal, match="e9-row0001"):
        cp.load_eval_12_7(gate)
