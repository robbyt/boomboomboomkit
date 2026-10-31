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
from matched_eval import run as rn  # noqa: E402
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
        "buildConfiguration": rp.EXPECTED_RUNNER_BUILD,
        "gitSha": GIT["sha"],
        "dirty": GIT["dirty"],
        "limit": None,
        "memorySampling": "test",
        "tracks": runner_tracks,
    }
    return manifest, runner


def build(corpus: str, tracks: list[dict[str, Any]], fixed_time_dir: Path | None = None):
    manifest, runner = manifest_and_runner(corpus, tracks)
    rows, _digests = rp.build_rows(manifest, "cd" * 32, runner, fixed_time_dir, GIT)
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
    pairs, _count = rp.pairing_summaries(rows, "oa300", strata, None)
    level = next(
        p
        for p in pairs
        if p["a"] == "boomboomboomkit-optimal"
        and p["b"] == "variant-joint-fit"
        and p["metric"] == "level_same"
    )
    # An abstention counts as incorrect in accuracy, so all 12 tracks pair.
    assert level["strata"]["overall"]["n"] == 12
    assert level["strata"]["overall"]["n_positive"] == 1
    assert level["accuracyCountsAbstentionAsIncorrect"] is True
    abs_err = next(
        p
        for p in pairs
        if p["a"] == "boomboomboomkit-optimal"
        and p["b"] == "variant-joint-fit"
        and p["metric"] == "abs_error_bpm"
    )
    assert abs_err["strata"]["overall"]["n"] == 11
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
    assert "| 110-129 | 6 | `boomboomboomkit-optimal` | 6 | yes |" in md


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
    assert 0.0 <= a["p_value"] <= 1.0
    assert a["statistic"] == "median"


def test_all_zero_differences():
    s = st.paired_summary([0.0] * 12, "z")
    assert s["interval95"] == [0.0, 0.0]
    assert s["p_value"] == 1.0
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
    s["q_value"] = 0.01
    text = rp.direction_sentence("oa300", "a-sys", "oracle", "system-vs-reference", "m", s, None)
    assert text is not None
    for part in (
        "`a-sys` vs `oracle`",
        "system-vs-reference",
        "n = 20",
        "95 % interval",
        "p =",
        "q =",
    ):
        assert part in text
    s["q_value"] = 0.2
    assert rp.direction_sentence("oa300", "a", "oracle", "x", "m", s, None) is None


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
        assert {"n", "interval95", "p_value", "q_value", "interval_excludes_zero"} <= set(s)
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


# ---------------------------------------------------------------------------
# Review pass 1 additions
# ---------------------------------------------------------------------------


def _scores_dir(tmp_path: Path, corpus: str, rows: list[dict[str, Any]]) -> Path:
    d = tmp_path / "fixed-time"
    d.mkdir(exist_ok=True)
    (d / f"scores-{corpus}.json").write_text(
        json.dumps(
            {
                "weightsSha256": "ee" * 32,
                "inputContract": "synthetic",
                "aggregator": "synthetic",
                "codeGitSha": "x",
                "rows": rows,
            }
        )
    )
    return d


def _sha(track: str) -> str:
    return hashlib.sha256(track.encode()).hexdigest()


def test_fixed_time_join_ok_abstained_and_missing_track(tmp_path):
    d = _scores_dir(
        tmp_path,
        "oa300",
        [
            {"trackId": "t0", "audioSha256": _sha("t0"), "variantBPM": 128.0, "abstained": None},
            {"trackId": "t1", "audioSha256": _sha("t1"), "variantBPM": None, "abstained": "x"},
        ],
    )
    tracks = [{"id": f"t{i}", "ref": 128.0} for i in range(3)]
    _, _, rows = build("oa300", tracks, d)
    assert row_for(rows, rp.FIXED_TIME, "t0")["status"] == mt.OK
    assert row_for(rows, rp.FIXED_TIME, "t0")["families"]["strict_tempo"]["0.02"] is True
    assert row_for(rows, rp.FIXED_TIME, "t1")["status"] == mt.ABSTAINED
    assert row_for(rows, rp.FIXED_TIME, "t2")["status"] == mt.NOT_RUN
    rt = row_for(rows, rp.FIXED_TIME, "t0")["families"]["runtime_memory"]["status"]
    assert rt == mt.NOT_COMPARABLE


def test_fixed_time_hash_mismatch_refuses(tmp_path):
    d = _scores_dir(
        tmp_path,
        "oa300",
        [{"trackId": "t0", "audioSha256": "00" * 32, "variantBPM": 128.0, "abstained": None}],
    )
    with pytest.raises(rp.ReportRefusal, match="15.5"):
        build("oa300", [{"id": "t0", "ref": 128.0}], d)


def test_fixed_time_missing_scores_file_refuses_but_not_for_synthetic(tmp_path):
    d = tmp_path / "empty-run"
    d.mkdir()
    with pytest.raises(rp.ReportRefusal, match="scores-oa300"):
        build("oa300", [{"id": "t0", "ref": 128.0}], d)
    _, _, rows = build(cp.SYNTHETIC, [{"id": "c0", "ref": 120.0}], d)
    assert row_for(rows, rp.FIXED_TIME, "c0")["status"] == mt.NOT_RUN


def test_yes_no_statistics_use_mean_and_mcnemar():
    diffs = [1.0] * 9 + [-1.0] * 1 + [0.0] * 10
    s = st.paired_summary(diffs, "yn", yes_no=True)
    assert s["statistic"] == "mean"
    assert s["estimate"] == pytest.approx(0.4)
    from fixed_time.report import mcnemar_exact_p

    assert s["p_value"] == pytest.approx(mcnemar_exact_p(9, 1))
    lo, hi = s["interval95"]
    assert lo <= 0.4 <= hi


def test_benjamini_hochberg():
    q = st.benjamini_hochberg([0.01, 0.04, 0.03, 0.5])
    # Sorted p 0.01, 0.03, 0.04, 0.5 -> raw 0.04, 0.06, 0.0533, 0.5 -> running minimum.
    assert q == pytest.approx([0.04, 0.04 * 4 / 3, 0.04 * 4 / 3, 0.5])
    assert st.benjamini_hochberg([]) == []


def test_corpus_test_count_and_q_values_in_aggregate():
    tracks = [{"id": f"t{i}", "ref": 120.0} for i in range(12)]
    manifest, runner, rows = build("oa300", tracks)
    agg = rp.aggregate(rows, manifest, {}, GIT, runner)
    c = agg["corpora"]["oa300"]
    n_tests = sum(len(p["strata"]) for p in c["pairings"])
    assert c["testCount"] == n_tests > 0
    assert all("q_value" in s for p in c["pairings"] for s in p["strata"].values())
    assert f"tests run: {n_tests}" in rp.render_markdown(agg)


def test_abstention_counts_as_incorrect_in_accuracy_rates():
    tracks = [
        {
            "id": f"t{i}",
            "ref": 120.0,
            "systems": {
                "variant-joint-fit": swift_record(None, status="abstained", reason="nil")
                if i < 3
                else swift_record(120.0)
            },
        }
        for i in range(10)
    ]
    manifest, runner, rows = build("oa300", tracks)
    agg = rp.aggregate(rows, manifest, {}, GIT, runner)
    jf = agg["corpora"]["oa300"]["systems"]["variant-joint-fit"]["overall"]
    assert jf["metrics"]["level_same"]["n"] == 10
    assert jf["metrics"]["level_same"]["mean"] == pytest.approx(0.7)
    assert jf["coverage"] == pytest.approx(0.7)
    assert jf["metrics"]["abs_error_bpm"]["n"] == 7


def test_level_mismatch_skips_downbeat_and_drift():
    ann = annotation_120()
    half = {"tempoBPM": 60.0, "anchorSeconds": 10.0, "downbeat": {"anchorSeconds": 10.0}}
    fam = mt.grid_families(half, ann)
    assert fam["downbeat_phase"]["status"] == mt.LEVEL_MISMATCH
    assert fam["drift"]["status"] == mt.LEVEL_MISMATCH
    assert fam["grid_phase"]["status"] == mt.OK


def test_drift_is_phase_error_at_last_bar_minus_first():
    ann = annotation_120(start=10.0, bars=8)
    grid = {"tempoBPM": 120.12, "anchorSeconds": 10.03, "downbeat": {}}
    drift = mt.grid_families(grid, ann)["drift"]
    first = mt.nearest_beat_error(120.12, 10.03, 10.0)
    last = mt.nearest_beat_error(120.12, 10.03, 26.0)
    assert drift["drift_s"] == pytest.approx(last - first)
    assert first == pytest.approx(0.03)


@pytest.mark.parametrize("tempo", [float("nan"), float("inf"), 0.0, -120.0, None])
def test_non_finite_or_non_positive_tempo_is_a_failure(tempo):
    _, _, rows = build(
        "oa300",
        [{"id": "t0", "ref": 120.0, "systems": {"variant-joint-fit": swift_record(tempo)}}],
    )
    row = row_for(rows, "variant-joint-fit", "t0")
    assert row["status"] == mt.FAILED
    assert row["reason"] == mt.INVALID_TEMPO
    assert row["families"]["failure"]["failed_or_abstained"] is True
    assert mt._metric_tempo_level(row["families"]) == 0.0


@pytest.mark.parametrize("tempo", [0.0, -1.0, float("nan")])
def test_invalid_grid_tempo_is_a_grid_failure(tempo):
    fam = mt.grid_families({"tempoBPM": tempo, "anchorSeconds": 1.0}, annotation_120())
    assert all(fam[f]["status"] == mt.FAILED for f in mt.GRID_FAMILIES)


def test_synthetic_click_reference_shape(tmp_path):
    doc = cp.build_synthetic_clicks(tmp_path / "clicks")
    rows = doc["rows"]
    assert len(rows) == cp.EXPECTED_COUNTS[cp.SYNTHETIC] == 12
    assert {r["style"] for r in rows} == {"single-impulse", "64-sample-exp-decay"}
    first = next(r for r in rows if r["trackId"] == "click-44100-offset0-single-impulse.wav")
    assert first["audioSha256"] == cp.sha256_file(Path(first["audioPath"]))
    ann = first["annotation"]
    assert len(ann["beatTimes"]) == 23
    assert ann["beatTimes"][0] == pytest.approx(0.5)
    assert [m for _t, m in ann["barLines"]] == [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
    assert ann["spanStartSeconds"] == pytest.approx(0.5)
    assert ann["spanEndSeconds"] == pytest.approx(10.5)
    assert mt.reference_beats(ann).size == 21
    exact = {"tempoBPM": 120.0, "anchorSeconds": 0.5, "downbeat": {}}
    fam = mt.grid_families(exact, ann)
    assert fam["beat_prf"]["f_measure"] == pytest.approx(1.0)
    assert fam["grid_phase"]["phase_error_s"] == pytest.approx(0.0, abs=1e-12)

    late = next(r for r in rows if r["trackId"] == "click-48000-offset479-64-sample-exp-decay.wav")
    assert late["annotation"]["beatTimes"][0] == pytest.approx((24_000 + 479) / 48_000)

    from scipy.io import wavfile

    sr, data = wavfile.read(first["audioPath"])
    assert sr == 44_100 and data.dtype == np.float32 and data.size == 529_200
    assert data[22_050] == 1.0 and data[22_051] == 0.0


def test_runner_grid_record_keys_feed_the_grid_families():
    """A runner record in the exact shape matched-eval-run writes."""
    grid = {
        "tempoBPM": 120.0,
        "anchorSeconds": 10.5,
        "anchorSource": "medianConsistentBeat",
        "beatCount": 56,
        "analysisSpanStartSeconds": 0.0,
        "analysisSpanEndSeconds": 30.0,
        "downbeat": {"status": "not-attempted"},
    }
    record = {
        "status": "ok",
        "reason": None,
        "tempoBPM": 120.0,
        "grid": grid,
        "runtimeSeconds": 0.2,
        "peakMemoryAboveBaselineBytes": 4096,
        "runtimeComparable": True,
        "variantIdentity": "x",
        "buildConfiguration": rp.EXPECTED_RUNNER_BUILD,
    }
    _, _, rows = build(
        "oa300",
        [
            {
                "id": "t0",
                "ref": 120.0,
                "annotation": annotation_120(),
                "systems": {"boomboomboomkit-optimal": record},
            }
        ],
    )
    fam = row_for(rows, "boomboomboomkit-optimal", "t0")["families"]
    assert fam["grid_phase"]["status"] == mt.OK
    assert fam["grid_phase"]["region"] == "inside-analysed-span"
    assert fam["beat_prf"]["f_measure"] == pytest.approx(1.0)
    assert fam["downbeat_phase"]["status"] == mt.NO_DATA
    assert fam["drift"]["drift_s"] == pytest.approx(0.0, abs=1e-9)
    assert fam["runtime_memory"]["peak_memory_bytes"] == 4096

    not_comparable = {**record, "runtimeComparable": False, "runtimeSeconds": None}
    _, _, rows = build(
        "oa300",
        [{"id": "t0", "ref": 120.0, "systems": {"boomboomboomkit-optimal": not_comparable}}],
    )
    rt = row_for(rows, "boomboomboomkit-optimal", "t0")["families"]["runtime_memory"]
    assert rt["status"] == mt.NOT_COMPARABLE


def test_wording_scan_covers_the_tracked_json():
    tracks = [{"id": f"t{i}", "ref": 120.0} for i in range(3)]
    manifest, runner, rows = build("oa300", tracks)
    agg = rp.aggregate(rows, manifest, {}, GIT, runner)
    rp.check_wording(rp.canonical_json(agg).decode())
    for word in ("better", "worse", "ahead", "level with", "equivalent", "comparable", "beats"):
        agg["systems"]["oracle"] = f"the reference is {word} here"
        with pytest.raises(rp.WordingViolation):
            rp.check_wording(rp.canonical_json(agg).decode())
    rp.check_wording('{"status": "not-comparable"}')


def test_runner_provenance_must_match_the_report():
    _manifest, runner = manifest_and_runner("oa300", [{"id": "t0", "ref": 120.0}])
    rp.check_runner_provenance(runner, GIT)
    with pytest.raises(rp.ReportRefusal):
        rp.check_runner_provenance({**runner, "gitSha": "1" * 40}, GIT)
    with pytest.raises(rp.ReportRefusal):
        rp.check_runner_provenance({**runner, "dirty": True}, GIT)
    with pytest.raises(rp.ReportRefusal):
        rp.check_runner_provenance({**runner, "buildConfiguration": "debug"}, GIT)


def test_annotation_on_a_dropped_duplicate_refuses(tmp_path):
    paths = ["5. T.mp3", "5. T.wav"]
    root = tmp_path / "oa300"
    root.mkdir()
    for p in paths:
        (root / p).write_bytes(p.encode())
    (root / cp.ORACLE_FILENAME).write_text(
        json.dumps({"entries": [_jams_entry(p, 170.0) for p in paths]})
    )
    labels = tmp_path / "labels.json"
    labels.write_text(json.dumps({"entries": [_jams_entry(p, 170.0, "dnb") for p in paths]}))
    ann = _jams_entry("5. T.mp3", 170.0)
    ann["sandbox"] = {
        "annotation_version": cp.ANNOTATION_VERSION,
        "reference_downbeat_time_sec": 1.0,
        "verified_span_start_sec": 1.0,
        "verified_span_end_sec": 20.0,
        "verified_bpm": 170.0,
        "bar_position": 1,
    }
    (root / cp.ANNOTATIONS_FILENAME).write_text(json.dumps({"entries": [ann]}))
    with pytest.raises(cp.CorpusRefusal, match="duplicate"):
        cp.load_oa300(root, labels)


# ---------------------------------------------------------------------------
# run.py
# ---------------------------------------------------------------------------


def _write_run(run_dir: Path, tracks: list[dict[str, Any]], runner_extra: dict | None = None):
    manifest, runner = manifest_and_runner("oa300", tracks)
    runner.update(runner_extra or {})
    run_dir.mkdir(parents=True, exist_ok=True)
    (run_dir / "manifest.json").write_text(json.dumps(manifest))
    (run_dir / "runner-output.json").write_text(json.dumps(runner))
    return manifest


def _fake_swift_toolchain(monkeypatch, bin_dir: Path, build_code: int = 0) -> list:
    """Record every subprocess the swift step starts; `swift build --show-bin-path`
    answers `bin_dir`, the build answers `build_code`, the runner answers 0."""
    calls: list = []

    def call(cmd, **kw):
        calls.append((list(cmd), kw.get("cwd")))
        return build_code if cmd[:2] == ["swift", "build"] else 0

    def check_output(cmd, **kw):
        calls.append((list(cmd), kw.get("cwd")))
        return f"{bin_dir}\n"

    monkeypatch.setattr(rn.subprocess, "call", call)
    monkeypatch.setattr(rn.subprocess, "check_output", check_output)
    monkeypatch.setattr(rn, "git_state", lambda: GIT)
    return calls


def test_run_swift_refuses_without_runner_input(tmp_path, monkeypatch):
    calls = _fake_swift_toolchain(monkeypatch, tmp_path)
    assert rn.main(["swift", "--run-dir", str(tmp_path)]) == rn.EXIT_REFUSED
    assert calls == []


def test_run_swift_builds_the_runner_before_running_it(tmp_path, monkeypatch):
    # The runner records the SHA of the checkout at run time; that names the code it
    # was built from only if the driver builds it from this checkout first.
    run_dir = tmp_path / "run"
    run_dir.mkdir()
    (run_dir / "runner-input.json").write_text("{}")
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    (bin_dir / "matched-eval-run").write_text("")
    calls = _fake_swift_toolchain(monkeypatch, bin_dir)
    assert rn.main(["swift", "--run-dir", str(run_dir)]) == 0
    flags = ["swift", "build", "-c", "release", "-Xswiftc", "-enable-testing"]
    package = str(rn.ML_TRAINING_DIR / "swift_feature_extractor")
    build = calls.index((flags + ["--product", "matched-eval-run"], package))
    bin_path = calls.index((flags + ["--show-bin-path"], package))
    runs = [i for i, (cmd, _) in enumerate(calls) if cmd[0] == str(bin_dir / "matched-eval-run")]
    assert len(runs) == 1 and build < bin_path < runs[0]


def test_run_swift_refuses_a_failed_build(tmp_path, monkeypatch):
    (tmp_path / "runner-input.json").write_text("{}")
    calls = _fake_swift_toolchain(monkeypatch, tmp_path, build_code=1)
    assert rn.main(["swift", "--run-dir", str(tmp_path)]) == rn.EXIT_REFUSED
    assert [cmd[:2] for cmd, _ in calls] == [["swift", "build"]]


def test_run_swift_takes_no_prebuilt_runner(tmp_path, monkeypatch):
    # A binary built at an older commit would be labeled with the current HEAD.
    (tmp_path / "runner-input.json").write_text("{}")
    stale = tmp_path / "matched-eval-run"
    stale.write_text("")
    calls = _fake_swift_toolchain(monkeypatch, tmp_path / "bin")
    with pytest.raises(SystemExit) as exc:
        rn.main(["swift", "--run-dir", str(tmp_path), "--runner", str(stale)])
    assert exc.value.code == 2
    assert calls == []


def test_run_report_refuses_without_run_files(tmp_path, monkeypatch):
    monkeypatch.setattr(rn, "git_state", lambda: GIT)
    assert rn.main(["report", "--run-dir", str(tmp_path / "empty")]) == rn.EXIT_REFUSED


def test_run_report_refuses_on_runner_from_other_code(tmp_path, monkeypatch):
    monkeypatch.setattr(rn, "git_state", lambda: GIT)
    run_dir = tmp_path / "run"
    _write_run(run_dir, [{"id": "t0", "ref": 120.0}], {"gitSha": "1" * 40})
    args = ["report", "--run-dir", str(run_dir), "--artifact-dir", str(tmp_path / "art")]
    assert rn.main(args) == rn.EXIT_REFUSED


def test_run_report_turns_a_wording_violation_into_a_refusal(tmp_path, monkeypatch):
    monkeypatch.setattr(rn, "git_state", lambda: GIT)
    monkeypatch.setitem(rp.SYSTEM_DESCRIPTIONS, "oracle", "a better reference")
    run_dir = tmp_path / "run"
    _write_run(run_dir, [{"id": "t0", "ref": 120.0}])
    args = ["report", "--run-dir", str(run_dir), "--artifact-dir", str(tmp_path / "art")]
    assert rn.main(args) == rn.EXIT_REFUSED
    assert not (tmp_path / "art").exists()


def test_run_report_accepts_a_declared_limit(tmp_path, monkeypatch):
    monkeypatch.setattr(rn, "git_state", lambda: GIT)
    run_dir = tmp_path / "run"
    manifest = _write_run(run_dir, [{"id": f"t{i}", "ref": 120.0} for i in range(3)])
    runner = json.loads((run_dir / "runner-output.json").read_text())
    runner["tracks"] = runner["tracks"][:2]
    runner["limit"] = 2
    (run_dir / "runner-output.json").write_text(json.dumps(runner))
    art = tmp_path / "art"
    assert rn.main(["report", "--run-dir", str(run_dir), "--artifact-dir", str(art)]) == 0
    out = art / f"15-9-matched-eval-{GIT['sha']}-limit2.json"
    agg = json.loads(out.read_text())
    assert agg["limit"] == 2 and agg["corpora"]["oa300"]["n"] == 2
    assert (art / f"15-9-matched-eval-{GIT['sha']}-limit2.md").is_file()
    # Without the declaration the short runner output refuses.
    runner["limit"] = None
    (run_dir / "runner-output.json").write_text(json.dumps(runner))
    assert rn.main(["report", "--run-dir", str(run_dir), "--artifact-dir", str(art)]) == 3
    assert manifest["corpora"]["oa300"]["rows"]
