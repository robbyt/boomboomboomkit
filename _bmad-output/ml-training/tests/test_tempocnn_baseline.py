"""Story 12.4: unit tests for the Gate 0 harness pure logic.

Synthetic rows only -- no network, no weights, no TensorFlow import (the harness
imports TF lazily inside run_model / _featurize only)."""

from __future__ import annotations

import hashlib
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from evaluate_fr18 import EXPECTED_GIANTSTEPS, acc1_correct  # noqa: E402
from tempocnn_baseline import (  # noqa: E402
    persist_failed_run,
    acc2_correct,
    acc_within,
    gate_inputs,
    gate_verdict,
    join_tempo2,
    score_rows,
    tempo2_floor_correct,
    verify_checksums,
)


class TestStrictScorer:
    """The @4% scorer must reproduce evaluate_fr18's verdicts exactly."""

    CASES = [
        (120.0, 120.0),
        (124.8, 120.0),  # exactly 4.0% high
        (124.81, 120.0),  # just over
        (115.2, 120.0),  # exactly 4.0% low
        (60.0, 120.0),  # octave error: strict counts it wrong
        (None, 120.0),  # abstain
        (float("nan"), 120.0),
        (float("inf"), 120.0),
        (-5.0, 120.0),
        (0.0, 120.0),
        (120.0, float("nan")),
        (120.0, 0.0),
    ]

    def test_matches_evaluate_fr18(self):
        for pred, truth in self.CASES:
            assert acc_within(pred, truth, 0.04) == acc1_correct(pred, truth), (pred, truth)

    def test_boundary_is_inclusive(self):
        assert acc_within(124.8, 120.0, 0.04)
        assert not acc_within(124.9, 120.0, 0.04)

    def test_2pct_is_tighter(self):
        assert acc_within(122.3, 120.0, 0.02)  # just inside 2%
        assert not acc_within(123.0, 120.0, 0.02)
        assert acc_within(123.0, 120.0, 0.04)


class TestScorerParityWithSwiftMirexHit:
    """Cross-check the @2% and tempo2-floor scorers against hand-computed synthetic
    rows mirroring GiantStepsBenchmarkTests.mirexHit semantics (primary-or-tempo2;
    an acc1 hit always implies an acc2/floor hit). Equivalence is established on
    these synthetic rows only -- the Swift metric itself is not executed here."""

    def test_primary_hit_implies_floor_hit(self):
        for pred, truth, tempo2 in [(127.0, 127.0, 139.0), (100.0, 101.0, None)]:
            if acc_within(pred, truth, 0.02):
                assert tempo2_floor_correct(pred, truth, tempo2, 0.02)

    def test_hand_computed_rows(self):
        # 127 exact; 139 exact via tempo2; 129.6 is 2.05% over 127 AND 6.8% under 139
        assert tempo2_floor_correct(127.0, 127.0, 139.0, 0.02) is True
        assert tempo2_floor_correct(139.0, 127.0, 139.0, 0.02) is True
        assert tempo2_floor_correct(129.6, 127.0, 139.0, 0.02) is False
        # tempo2 within tolerance: 140 vs tempo2 139 -> 0.72%
        assert tempo2_floor_correct(140.0, 127.0, 139.0, 0.02) is True
        # no tempo2 -> primary only
        assert tempo2_floor_correct(139.0, 127.0, None, 0.02) is False

    def test_acc1_implies_acc2(self):
        for pred, truth in [(120.0, 120.0), (124.8, 120.0), (61.0, 60.0)]:
            if acc_within(pred, truth, 0.04):
                assert acc2_correct(pred, truth, 0.04)

    def test_acc2_octave_factors(self):
        assert acc2_correct(60.0, 120.0, 0.04)  # half
        assert acc2_correct(240.0, 120.0, 0.04)  # double
        assert acc2_correct(40.0, 120.0, 0.04)  # third
        assert acc2_correct(360.0, 120.0, 0.04)  # triple
        assert not acc2_correct(80.0, 120.0, 0.04)  # 3:2 is NOT an Acc2 factor
        assert not acc2_correct(None, 120.0, 0.04)


class TestTempo2Floor:
    def test_primary_hit(self):
        assert tempo2_floor_correct(120.0, 120.0, None, 0.02)

    def test_tempo2_hit(self):
        assert tempo2_floor_correct(139.0, 127.0, 139.0, 0.02)

    def test_no_tempo2_no_fallback(self):
        assert not tempo2_floor_correct(139.0, 127.0, None, 0.02)

    def test_abstain_wrong(self):
        assert not tempo2_floor_correct(None, 127.0, 139.0, 0.02)

    def test_nonpositive_tempo2_ignored(self):
        assert not tempo2_floor_correct(139.0, 127.0, 0.0, 0.02)


class TestTempo2Join:
    RESOLVED = [{"trackId": "a.mp3", "audioPath": "/x/a.mp3", "groundTruthBPM": 127.0}]

    def test_joins(self):
        rows = join_tempo2(self.RESOLVED, [{"filename": "a.mp3", "bpm": 127.0, "tempo2": 139.0}])
        assert len(rows) == 1
        assert rows[0]["tempo2"] == 139.0

    def test_missing_join_refuses(self):
        with pytest.raises(SystemExit):
            join_tempo2(self.RESOLVED, [{"filename": "b.mp3", "tempo2": 1.0}])

    def test_duplicate_id_refuses(self):
        with pytest.raises(SystemExit):
            join_tempo2(
                self.RESOLVED,
                [{"filename": "a.mp3", "tempo2": 1.0}, {"filename": "a.mp3", "tempo2": 2.0}],
            )

    def test_non_numeric_tempo2_refuses(self):
        with pytest.raises(SystemExit):
            join_tempo2(self.RESOLVED, [{"filename": "a.mp3", "tempo2": "fast"}])

    def test_unkeyed_entries_skipped(self):
        rows = join_tempo2(
            self.RESOLVED, [{"tempo2": 5.0}, {"filename": "", "tempo2": 6.0}, {"filename": "a.mp3"}]
        )
        assert len(rows) == 1
        assert rows[0]["tempo2"] is None

    def test_boolean_tempo2_refuses(self):
        # bool is an int subclass; a corrupted ground truth with true/false must
        # trip the join-integrity refusal, not coerce to 1.0/0.0.
        with pytest.raises(SystemExit):
            join_tempo2(self.RESOLVED, [{"filename": "a.mp3", "tempo2": True}])


class TestDenominatorGuard:
    def _rows(self, n):
        return [{"modelBPM": 120.0, "groundTruthBPM": 120.0, "tempo2": None} for _ in range(n)]

    def test_refuses_short_denominator(self):
        with pytest.raises(SystemExit):
            score_rows(self._rows(EXPECTED_GIANTSTEPS - 1))

    def test_refuses_long_denominator(self):
        with pytest.raises(SystemExit):
            score_rows(self._rows(EXPECTED_GIANTSTEPS + 1))

    def test_scores_exact_denominator(self):
        summary = score_rows(self._rows(EXPECTED_GIANTSTEPS))
        assert summary["denominator"] == EXPECTED_GIANTSTEPS
        assert summary["protocolRows"]["strictAcc1At4pct"]["tracks"] == EXPECTED_GIANTSTEPS
        assert summary["protocolRows"]["acc2At4pct"]["tracks"] == EXPECTED_GIANTSTEPS
        assert summary["strictMissesOctaveRecoverable"] == 0


class TestFailureRateGuard:
    def _rows(self, failures):
        rows = [
            {"modelBPM": 120.0, "groundTruthBPM": 120.0, "tempo2": None}
            for _ in range(EXPECTED_GIANTSTEPS - failures)
        ]
        rows += [
            {"modelBPM": None, "failureReason": "OSError: boom", "groundTruthBPM": 120.0}
            for _ in range(failures)
        ]
        return rows

    def test_refuses_systematic_failure(self):
        # 5% of 661 = 33.05 -> 34 failures exceed the guard
        with pytest.raises(SystemExit):
            score_rows(self._rows(34))

    def test_refuses_total_failure(self):
        with pytest.raises(SystemExit):
            score_rows(self._rows(EXPECTED_GIANTSTEPS))

    def test_tolerates_sparse_failures(self):
        summary = score_rows(self._rows(33))  # exactly at the 5% bound
        assert summary["perTrackFailures"] == 33
        assert summary["protocolRows"]["strictAcc1At4pct"]["tracks"] == EXPECTED_GIANTSTEPS - 33


class TestGateRule:
    """Pre-registered rule: P = round(0.825 * 661) = 545; midpoint(348, 545) = 446.5.
    Gate fires iff reference <= midpoint."""

    def test_inputs(self):
        v = gate_verdict(447)
        assert v["publishedTracksOn661"] == 545
        assert v["midpointTracks"] == 446.5

    def test_fires_at_or_below_midpoint(self):
        assert gate_verdict(446)["gate0Fires"] is True
        assert gate_verdict(348)["gate0Fires"] is True
        assert gate_verdict(0)["gate0Fires"] is True

    def test_passes_above_midpoint(self):
        assert gate_verdict(447)["gate0Fires"] is False
        assert gate_verdict(545)["gate0Fires"] is False

    def test_verdict_strings(self):
        assert gate_verdict(446)["verdict"] == "measurement-not-modelling"
        assert gate_verdict(447)["verdict"] == "gap-attributable-to-our-model"

    def test_refuses_other_denominator(self):
        # 348 is pre-registered FOR the 661-row denominator
        with pytest.raises(SystemExit):
            gate_inputs(660)
        with pytest.raises(SystemExit):
            gate_verdict(400, n=662)


class TestChecksumRefusal:
    def _provenance(self, digest, blob=None, model_file="weights.h5"):
        entry = {"sha256": digest, "size_bytes": 3}
        if blob is not None:
            entry["git_blob_sha1"] = blob
        return {"model_file": model_file, "files": {"weights.h5": entry}}

    def test_mismatch_refuses(self, tmp_path):
        (tmp_path / "weights.h5").write_bytes(b"abc")
        with pytest.raises(SystemExit):
            verify_checksums(tmp_path, self._provenance("0" * 64))

    def test_missing_refuses(self, tmp_path):
        with pytest.raises(SystemExit):
            verify_checksums(tmp_path, self._provenance("0" * 64))

    def test_match_passes(self, tmp_path):
        (tmp_path / "weights.h5").write_bytes(b"abc")
        digest = hashlib.sha256(b"abc").hexdigest()
        assert verify_checksums(tmp_path, self._provenance(digest)) == tmp_path / "weights.h5"

    def test_missing_sha256_key_refuses_cleanly(self, tmp_path):
        (tmp_path / "weights.h5").write_bytes(b"abc")
        prov = {"model_file": "weights.h5", "files": {"weights.h5": {"size_bytes": 3}}}
        with pytest.raises(SystemExit, match="no sha256"):
            verify_checksums(tmp_path, prov)

    def test_blob_sha1_verified(self, tmp_path):
        data = b"abc"
        (tmp_path / "weights.h5").write_bytes(data)
        digest = hashlib.sha256(data).hexdigest()
        blob = hashlib.sha1(b"blob 3\x00" + data).hexdigest()
        assert (
            verify_checksums(tmp_path, self._provenance(digest, blob=blob))
            == tmp_path / "weights.h5"
        )
        with pytest.raises(SystemExit):
            verify_checksums(tmp_path, self._provenance(digest, blob="0" * 40))

    def test_empty_files_refuses(self, tmp_path):
        with pytest.raises(SystemExit):
            verify_checksums(tmp_path, {"model_file": "weights.h5", "files": {}})

    def test_missing_model_file_key_refuses(self, tmp_path):
        (tmp_path / "weights.h5").write_bytes(b"abc")
        digest = hashlib.sha256(b"abc").hexdigest()
        prov = self._provenance(digest)
        del prov["model_file"]
        with pytest.raises(SystemExit):
            verify_checksums(tmp_path, prov)


class TestFailedRunPersistence:
    def test_guard_trip_preserves_per_track_evidence(self, tmp_path):
        import json

        rows = [
            {"trackId": "a.mp3", "modelBPM": None, "failureReason": "decode error"},
            {"trackId": "b.mp3", "modelBPM": 128.0, "failureReason": None},
        ]
        out = tmp_path / "tempocnn-baseline" / "predictions.json"
        failed = persist_failed_run(out, "weights.h5", "gt.json", "0" * 64, rows)
        assert failed == out.parent / "predictions-failed.json"
        payload = json.loads(failed.read_text())
        assert payload["scored"] is False
        assert "summary" not in payload  # a failed run must not look scored
        assert payload["tracks"][0]["failureReason"] == "decode error"
