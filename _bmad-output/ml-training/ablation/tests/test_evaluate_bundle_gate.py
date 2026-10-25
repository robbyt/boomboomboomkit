"""Fixture checks for the Story 12.9 paired gate and refusal conditions."""

from __future__ import annotations

import copy
import json
from pathlib import Path

import pytest

import evaluate_bundle_gate as gate


def write_json(path: Path, doc: dict | list) -> bytes:
    raw = (json.dumps(doc, sort_keys=True) + "\n").encode()
    path.write_bytes(raw)
    return raw


def run_fixture(tmp_path: Path, monkeypatch):
    run_dir = tmp_path / "seed_42"
    run_dir.mkdir()
    gate_row = {
        "trackId": "e1-aaaa",
        "audioPath": "/private/audio.wav",
        "audioSha256": "a" * 64,
        "groundTruthBPM": 130.0,
        "sourceBand": "120-140",
        "verifiedBand": "120-140",
        "category": "locked-12.7-member",
    }
    sentinel = {**gate_row, "trackId": "sentinel:original", "category": "sentinel-four"}
    sentinel["sourceBand"] = "sentinel"
    expected_sentinel = copy.deepcopy(sentinel)
    monkeypatch.setattr(gate, "four_sentinel_rows", lambda: [expected_sentinel])
    cohort = {"cohortSha256": "fixture", "tracks": [gate_row]}
    input_doc = {"cohortSha256": "fixture", "seed": 42, "tracks": [gate_row, sentinel]}
    input_path = tmp_path / "bundle-gate-input-seed-42.json"
    input_bytes = write_json(input_path, input_doc)
    predictions = [
        {k: r[k] for k in ("trackId", "groundTruthBPM", "sourceBand", "verifiedBand", "category")}
        for r in input_doc["tracks"]
    ]
    prediction_bytes = write_json(run_dir / "predictions.json", predictions)
    checkpoint = tmp_path / "model.mlmodel"
    checkpoint.write_bytes(b"model")
    manifest = {
        "harnessVersion": 1,
        "cohortSha256": "fixture",
        "inputSha256": gate.digest_bytes(input_bytes),
        "predictionsSha256": gate.digest_bytes(prediction_bytes),
        "ensemblePolicy": "default",
        "checkpointPath": str(checkpoint),
        "checkpointSha256": gate.checkpoint_digest(checkpoint),
        "expectedTrackCount": 2,
        "actualTrackCount": 2,
        "unresolvedTracks": [],
        "seed": 42,
        "modelIdentifier": "fixture",
        "gitSha": "fixture",
    }
    write_json(run_dir / "manifest.json", manifest)
    return run_dir, cohort, input_doc, predictions, manifest


def save_run(run_dir: Path, input_doc: dict, predictions: list, manifest: dict):
    input_bytes = write_json(run_dir.parent / "bundle-gate-input-seed-42.json", input_doc)
    prediction_bytes = write_json(run_dir / "predictions.json", predictions)
    manifest["inputSha256"] = gate.digest_bytes(input_bytes)
    manifest["predictionsSha256"] = gate.digest_bytes(prediction_bytes)
    write_json(run_dir / "manifest.json", manifest)


def row(track_id: str, dsp: float | None, ensemble: float | None, band: str = "120-140") -> dict:
    return {
        "trackId": track_id,
        "category": "locked-12.7-member",
        "groundTruthBPM": 130.0,
        "verifiedBand": band,
        "dspBPM": dsp,
        "ensembleBPM": ensemble,
        "modelBPM": None,
        "softmaxMax": None,
        "mlAbstained": True,
        "dspCandidatesTop3": [],
    }


def synthetic_cohort(rows: list[dict]) -> dict:
    return {
        "tracks": [{"trackId": r["trackId"], "category": r["category"]} for r in rows],
        "verifiedBands": {b: sum(r["verifiedBand"] == b for r in rows) for b in gate.BANDS},
        "count": len(rows),
        "cohortSha256": "fixture",
    }


def test_exact_mcnemar_boundaries_and_net_tracks():
    assert gate.exact_mcnemar_p(0, 0) == 1
    assert gate.exact_mcnemar_p(5, 0) == 0.0625
    assert gate.exact_mcnemar_p(6, 0) == 0.03125
    assert gate.exact_mcnemar_p(13, 3) <= 0.05
    assert gate.required_net_lift(0) is None
    assert gate.required_net_lift(5) is None
    assert gate.required_net_lift(6) == 6
    assert gate.required_net_lift(16) == 10
    rows = [row(f"gain-{i}", None, 130) for i in range(6)] + [row("loss", 130, None)]
    table = gate.paired_table(rows)
    assert (table["bGains"], table["cLosses"], table["dDiscordant"]) == (6, 1, 7)
    assert table["netTracks"] == 5


def test_unequal_and_sparse_bands():
    rows = [row(f"full-{i}", 130, 130) for i in range(48)] + [
        row(f"slow-{i}", None, None, "sub-100") for i in range(4)
    ]
    scored = gate.score_seed(synthetic_cohort(rows), rows)
    assert scored["bands"]["120-140"]["dspHandledThreshold"] == 34
    assert scored["bands"]["120-140"]["dspHandled"] is True
    assert scored["bands"]["sub-100"]["state"] == "unmeasurable"
    assert scored["calibration"]["state"] == "inconclusive"
    assert scored["mlAbstains"] == 52


def test_band_regression_and_substantive_negative_control(monkeypatch):
    rows = [row(f"x-{i}", 130, None) for i in range(43)]
    cohort = synthetic_cohort(rows)
    monkeypatch.setattr(gate, "signoff_reasons", lambda _cohort: ["signoff absent"])
    report = gate.evaluate(cohort, {42: rows})
    assert report["decision"] == "refused"
    assert any("paired" in x for x in report["substantiveFailures"])
    assert any("band 120-140 regression" in x for x in report["substantiveFailures"])
    assert "signoff absent" in report["approvalRefusals"]


def test_refusal_before_closure_even_if_pair_passes(monkeypatch):
    rows = [row(f"gain-{i}", None, 130) for i in range(6)]
    cohort = synthetic_cohort(rows)
    monkeypatch.setattr(gate, "signoff_reasons", lambda _cohort: ["partition open"])
    report = gate.evaluate(cohort, {42: rows})
    assert report["seeds"][42]["paired"]["state"] == "pass"
    assert report["decision"] == "refused"
    assert "partition open" in report["approvalRefusals"]


def test_12_7_signoff_alone_cannot_approve_expanded_cohort(monkeypatch):
    monkeypatch.setattr(gate, "member_signoff_reasons", lambda: [])
    cohort = {"verifiedBands": {band: 43 for band in gate.BANDS}}
    reasons = gate.signoff_reasons(cohort)
    assert reasons == ["expanded gate cohort training-partition closure is not certified"]


def test_abstain_does_not_fabricate_ensemble_gain():
    rows = [row("abstain", 130, 130)]
    scored = gate.score_seed(synthetic_cohort(rows), rows)
    assert scored["paired"]["bGains"] == 0
    assert scored["paired"]["netTracks"] == 0
    assert scored["calibration"]["state"] == "inconclusive"


def test_metadata_and_missing_prediction_refuse():
    rows = [row("one", 130, 130)]
    cohort = synthetic_cohort(rows)
    assert gate.score_seed(cohort, rows)["paired"]["n"] == 1
    altered = copy.deepcopy(rows)
    altered[0]["trackId"] = "other"
    try:
        gate.score_seed(cohort, altered)
    except ValueError as exc:
        assert "omit" in str(exc)
    else:
        raise AssertionError("missing frozen row was accepted")


def test_legacy_duplicate_titles_keep_distinct_input_ids(tmp_path, monkeypatch):
    audio = tmp_path / "a.wav"
    audio.write_bytes(b"audio")
    source = {
        "trackId": "same title",
        "audioPath": str(audio),
        "groundTruthBPM": 130.0,
    }
    monkeypatch.setattr(gate, "four_sentinel_rows", lambda: [])
    monkeypatch.setattr(gate, "resolve_oa300", lambda _root: [source, source])
    monkeypatch.setattr(gate, "resolve_giantsteps", lambda _root: [])
    prepared = gate.prepare({"tracks": [], "cohortSha256": "fixture"}, seed=42, include_legacy=True)
    assert len(prepared["tracks"]) == 2
    assert len({r["trackId"] for r in prepared["tracks"]}) == 2


@pytest.mark.parametrize("change", ["id", "label", "audio-hash"])
def test_read_run_rejects_substituted_original_sentinel(tmp_path, monkeypatch, change):
    run_dir, cohort, input_doc, predictions, manifest = run_fixture(tmp_path, monkeypatch)
    assert gate._read_run(run_dir, cohort)[0] == 42
    sentinel = input_doc["tracks"][1]
    if change == "id":
        sentinel["trackId"] = "sentinel:replacement"
        predictions[1]["trackId"] = sentinel["trackId"]
    elif change == "label":
        sentinel["groundTruthBPM"] = 131.0
        predictions[1]["groundTruthBPM"] = 131.0
    else:
        sentinel["audioSha256"] = "b" * 64
    save_run(run_dir, input_doc, predictions, manifest)
    with pytest.raises(ValueError, match="four original sentinel"):
        gate._read_run(run_dir, cohort)


def test_read_run_rejects_prediction_tampering_and_policy_mismatch(tmp_path, monkeypatch):
    run_dir, cohort, _input, predictions, manifest = run_fixture(tmp_path, monkeypatch)
    predictions[0]["groundTruthBPM"] = 140.0
    write_json(run_dir / "predictions.json", predictions)
    with pytest.raises(ValueError, match="incomplete, stale"):
        gate._read_run(run_dir, cohort)
    predictions[0]["groundTruthBPM"] = 130.0
    manifest["ensemblePolicy"] = "mlOnly"
    save_run(run_dir, _input, predictions, manifest)
    with pytest.raises(ValueError, match="nondefault"):
        gate._read_run(run_dir, cohort)


def test_seed_robustness_requires_distinct_checkpoint_hashes():
    reports = {seed: {"paired": {"netTracks": 6}} for seed in gate.SEEDS}
    repeated = {seed: {"checkpointSha256": "a" * 64} for seed in gate.SEEDS}
    assert gate.seed_robustness_state(reports, repeated) == "fail"
    distinct = {
        seed: {"checkpointSha256": f"{index:064x}"}
        for index, seed in enumerate(gate.SEEDS, start=1)
    }
    assert gate.seed_robustness_state(reports, distinct) == "pass"


def test_checkpoint_digest_covers_separate_weight_files(tmp_path):
    bundle = tmp_path / "model.mlmodelc"
    (bundle / "weights").mkdir(parents=True)
    (bundle / "coremldata.bin").write_bytes(b"graph")
    weights = bundle / "weights/weight.bin"
    weights.write_bytes(b"weights-v1")
    first = gate.checkpoint_digest(bundle)
    weights.write_bytes(b"weights-v2")
    assert gate.checkpoint_digest(bundle) != first


def test_negative_control_uses_only_known_seed_42_failure():
    passed = {
        "paired": {"state": "pass"},
        "calibration": {"state": "pass"},
        "fourSentinels": {"state": "pass"},
        "bands": {},
    }
    failed = copy.deepcopy(passed)
    failed["paired"]["state"] = "fail"
    report = {
        "runProvenance": {
            42: {"checkpointSha256": gate.FAILED_SEED42_CHECKPOINT_SHA256},
            43: {"checkpointSha256": "b" * 64},
        },
        "seeds": {42: passed, 43: failed},
        "substantiveFailures": ["seed 43 paired=fail"],
    }
    assert gate.negative_control_rejected(report) is False
    report["seeds"][42] = failed
    report["runProvenance"][42]["checkpointSha256"] = "c" * 64
    assert gate.negative_control_rejected(report) is False
    report["runProvenance"][42]["checkpointSha256"] = gate.FAILED_SEED42_CHECKPOINT_SHA256
    assert gate.negative_control_rejected(report) is True


@pytest.mark.parametrize("change", ["id", "label"])
def test_load_cohort_rejects_rehashed_locked_substitution(tmp_path, monkeypatch, change):
    gen = tmp_path / "eval-corpus/generations/fixture"
    gen.mkdir(parents=True)
    commitment = tmp_path / "commitment.json"
    commitment.write_text("{}")
    monkeypatch.setattr(gate, "HERE", tmp_path)
    monkeypatch.setattr(gate, "COMMITMENT", commitment)
    ids = [f"e1-{index:04x}" for index in range(172)]
    membership = {"120-140": {"members": ids}}
    signed = {
        "entries": [
            {
                "file_metadata": {"identifiers": {"row_id": rid}},
                "annotations": [{"data": [{"value": 130.0}]}],
            }
            for rid in ids
        ]
    }
    source_files = {
        "membershipSha256": gen / "membership.json",
        "signedJamsSha256": gen / "258-corpus.jams.json",
        "annotationLedgerSha256": gen / "annotation-ledger.jsonl",
    }
    write_json(source_files["membershipSha256"], membership)
    write_json(source_files["signedJamsSha256"], signed)
    source_files["annotationLedgerSha256"].write_text("")
    rows = [
        {
            "trackId": rid,
            "category": "locked-12.7-member",
            "groundTruthBPM": 130.0,
            "sourceBand": "120-140",
            "verifiedBand": "120-140",
        }
        for rid in ids
    ]
    if change == "id":
        rows[0]["trackId"] = "e1-replacement"
    else:
        rows[0]["groundTruthBPM"] = 131.0
    source = {
        "generation": "fixture",
        "commitmentSha256": gate.digest_bytes(commitment.read_bytes()),
        **{field: gate.digest_bytes(path.read_bytes()) for field, path in source_files.items()},
    }
    doc = {"tracks": rows, "count": 172, "source": source}
    doc["cohortSha256"] = gate.digest_bytes(
        json.dumps(doc, sort_keys=True, separators=(",", ":")).encode()
    )
    cohort_path = tmp_path / "cohort.json"
    write_json(cohort_path, doc)
    with pytest.raises(ValueError, match="frozen locked"):
        gate.load_cohort(cohort_path)
