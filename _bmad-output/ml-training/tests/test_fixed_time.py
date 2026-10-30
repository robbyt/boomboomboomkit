"""Story 15.5: fixed-time harness pure logic.

Synthetic inputs only: no corpus, no trained weights, no network."""

from __future__ import annotations

import hashlib
import json
import random
import sys
from pathlib import Path

import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from fixed_time import features as ft  # noqa: E402
from fixed_time import plan as cp  # noqa: E402
from fixed_time import report as rp  # noqa: E402
from fixed_time import score as sc  # noqa: E402
from fixed_time import train_fixed_time as tr  # noqa: E402


def click_track(seconds: float, bpm: float = 120.0, sr: int = 44_100) -> np.ndarray:
    """The TestSignalGenerators click: a 64-sample decaying impulse each beat."""
    n = int(sr * seconds)
    out = np.zeros(n, dtype=np.float32)
    step = int(sr * 60.0 / bpm)
    decay = np.exp(-np.arange(64) / 10.0).astype(np.float32)
    for b in range(0, n, step):
        end = min(b + 64, n)
        out[b:end] = decay[: end - b]
    return out


def swift_rhythm_score(samples: np.ndarray, sample_rate: int = 44_100) -> float:
    """Literal loop transliteration of RhythmicRegionSelector.score (Float32)."""
    f32 = np.float32
    bin_size = max(1, int(sample_rate / 100))
    bin_count = samples.shape[0] // bin_size
    if bin_count < 100:
        return 0.0
    step = max(1, bin_size // 64)
    energy = np.zeros(bin_count, dtype=f32)
    for b in range(bin_count):
        vals = np.abs(samples[b * bin_size : (b + 1) * bin_size : step]).astype(f32)
        energy[b] = f32(vals.sum(dtype=f32) / f32(vals.shape[0]))
    onset = np.zeros(bin_count, dtype=f32)
    onset[1:] = np.maximum(f32(0), energy[1:] - energy[:-1])
    total_energy = float(energy[1:].sum(dtype=np.float64))
    total_onset = float(onset.sum(dtype=np.float64))
    if total_energy <= 0 or total_onset <= 0:
        return 0.0
    c = onset.astype(np.float64) - total_onset / bin_count
    norm = float((c * c).sum())
    best = 0.0
    for lag in range(30, 101):
        best = max(best, float((c[lag:] * c[:-lag]).sum()) / norm)
    return max(0.0, best) * min(1.0, total_onset / total_energy * 8)


class TestContract:
    def test_crop_constants(self):
        assert ft.CROP_SAMPLES == 530_807
        assert ft.frame_count(ft.CROP_SAMPLES) == 1200
        assert ft.frame_count(ft.CROP_SAMPLES - 1) == 1199
        assert ft.SECONDS_PER_FRAME == pytest.approx(0.01)
        assert ft.TENSOR_SHAPE == (1, 1, 128, 1200)
        assert ft.CROP_HOP_FRAMES == 600

    def test_augment_segment_survives_the_fastest_stretch(self):
        assert int(ft.AUG_SEGMENT_SAMPLES / ft.MAX_STRETCH_RATE) >= ft.CROP_SAMPLES

    def test_contract_name_is_not_v2(self):
        assert "v2" not in ft.INPUT_CONTRACT


class TestCropPlan:
    def test_120s_clip_gives_18_regular_plus_one_tail(self):
        assert ft.frame_count(120 * 44_100) == 11_996
        starts = ft.crop_plan(11_996)
        assert len(starts) == 19
        assert starts[:18] == list(range(0, 18 * 600, 600))
        assert starts[-1] == 11_996 - 1200

    @pytest.mark.parametrize("k", [0, 1, 5, 17])
    def test_exact_fit_has_no_tail(self, k):
        n = 1200 + 600 * k
        starts = ft.crop_plan(n)
        assert starts == list(range(0, 600 * k + 1, 600))
        assert starts[-1] + 1200 == n

    def test_one_frame_over_adds_tail(self):
        assert ft.crop_plan(1201) == [0, 1]

    def test_short_clip_has_no_crop(self):
        assert ft.crop_plan(1199) == []
        assert ft.crop_plan(0) == []

    def test_every_crop_in_range_and_last_frame_covered(self):
        for n in range(1200, 5000, 37):
            starts = ft.crop_plan(n)
            assert all(0 <= s and s + 1200 <= n for s in starts)
            assert starts[-1] + 1200 == n

    def test_start_seconds(self):
        assert ft.start_seconds(600) == pytest.approx(6.0)


class TestRhythmScore:
    def test_pulse_scores_high(self):
        x = click_track(13.0)[: ft.CROP_SAMPLES]
        assert ft.rhythm_score(x) > 0.5

    def test_silence_scores_zero(self):
        assert ft.rhythm_score(np.zeros(ft.CROP_SAMPLES, np.float32)) == 0.0

    def test_drone_scores_zero(self):
        # 100 Hz: one period per 441-sample bin, tiled so every bin is identical.
        period = np.sin(2 * np.pi * np.arange(441) / 441).astype(np.float32)
        x = np.tile(period, ft.CROP_SAMPLES // 441 + 1)[: ft.CROP_SAMPLES]
        assert ft.rhythm_score(x) == 0.0

    def test_too_short_scores_zero(self):
        assert ft.rhythm_score(click_track(0.99)) == 0.0

    @pytest.mark.parametrize("seed", [0, 1, 2])
    def test_vectorized_port_matches_loop_transliteration(self, seed):
        rng = np.random.default_rng(seed)
        x = (click_track(13.0)[: ft.CROP_SAMPLES] * rng.uniform(0.2, 1.0)) + rng.standard_normal(
            ft.CROP_SAMPLES
        ).astype(np.float32) * 0.05
        x = x.astype(np.float32)
        assert ft.rhythm_score(x) == pytest.approx(swift_rhythm_score(x), rel=1e-4, abs=1e-5)


class TestRanking:
    def test_weak_crops_matrix_row(self):
        starts = [0, 1200, 2400, 3600]
        assert ft.rank_crops(starts, [0.5, 0.8, 0.39, 0.1]) == [1200, 0]

    def test_overlapping_neighbours_matrix_row(self):
        assert ft.rank_crops([0, 600, 1200], [0.9, 0.85, 0.8]) == [0, 1200]

    def test_overlap_is_any_shared_frame(self):
        # 1199 frames apart share one frame; 1200 apart share none.
        assert ft.rank_crops([0, 1199], [0.9, 0.8]) == [0]
        assert ft.rank_crops([0, 1200], [0.9, 0.8]) == [0, 1200]

    def test_kept_crops_never_overlap(self):
        rng = random.Random(7)
        for _ in range(200):
            starts = ft.crop_plan(rng.randint(1200, 12_000))
            kept = ft.rank_crops(starts, [rng.random() for _ in starts])
            assert all(abs(a - b) >= 1200 for i, a in enumerate(kept) for b in kept[i + 1 :])

    def test_at_most_four_in_rank_order(self):
        starts = list(range(0, 1200 * 6, 1200))
        assert ft.rank_crops(starts, [0.6, 0.9, 0.7, 0.95, 0.8, 0.85]) == [
            3600,
            1200,
            6000,
            4800,
        ]

    def test_ties_go_to_the_earlier_start(self):
        assert ft.rank_crops([0, 1200, 2400], [0.5, 0.9, 0.9]) == [1200, 2400, 0]

    def test_best_zero_keeps_nothing(self):
        assert ft.rank_crops([0, 1200], [0.0, 0.0]) == []
        assert ft.rank_crops([], []) == []

    def test_exactly_half_is_kept(self):
        assert ft.rank_crops([0, 1200], [0.8, 0.4]) == [0, 1200]

    def test_rule_text_names_the_overlap_rule(self):
        rule = ft.ranking_rule()
        assert rule["keptCropsOverlap"] is False and "shares a frame" in rule["rule"]


class TestCropTensors:
    @pytest.fixture(scope="class")
    def fixture(self):
        import dataset as ds

        return ds.load_fixture(ds.FIXTURE_PATH)

    def test_short_audio_has_no_crop(self, fixture):
        n_frames, starts, crops = ft.crops_from_audio(np.zeros(ft.CROP_SAMPLES - 1), fixture)
        assert n_frames == 1199 and starts == [] and crops.shape == (0, 128, 1200)

    def test_crop_from_pcm_equals_crop_of_whole_log_mel(self, fixture):
        rng = np.random.default_rng(0)
        audio = rng.standard_normal(ft.CROP_SAMPLES + 441 * 700).astype(np.float32)
        n_frames, starts, crops = ft.crops_from_audio(audio, fixture)
        assert n_frames == 1900 and starts == [0, 600, 700]
        np.testing.assert_allclose(ft.crop_tensor_at(audio, 700, fixture), crops[2], atol=1e-5)

    def test_crop_is_zscored_per_band(self, fixture):
        rng = np.random.default_rng(1)
        crop = ft.crop_tensor_from_pcm(
            rng.standard_normal(ft.CROP_SAMPLES).astype(np.float32), fixture
        )
        assert crop.shape == (128, 1200)
        np.testing.assert_allclose(crop.mean(axis=1), 0.0, atol=1e-4)
        np.testing.assert_allclose(crop.std(axis=1), 1.0, atol=1e-3)


class TestDecodeAudio:
    def test_48k_file_is_resampled_to_44k1(self, tmp_path):
        from scipy.io import wavfile

        path = tmp_path / "tone48k.wav"
        t = np.arange(48_000 * 2) / 48_000.0
        wavfile.write(path, 48_000, (0.1 * np.sin(2 * np.pi * 440.0 * t)).astype(np.float32))
        audio = sc.decode_audio(path)
        assert audio.dtype == np.float32
        assert abs(audio.shape[0] - 2 * 44_100) <= 1


class TestAggregatorAndDecode:
    def test_mean_of_softmax_ranked(self):
        probs = np.zeros((2, 256))
        probs[0, 90] = 1.0
        probs[1, 90] = 0.4
        probs[1, 100] = 0.6
        agg = sc.mean_of_softmax_ranked(probs)
        assert agg[90] == pytest.approx(0.7) and agg[100] == pytest.approx(0.3)

    def test_aggregator_symbol_resolves_to_one_function(self):
        assert sc.resolve_aggregator(sc.AGGREGATOR_SYMBOL) is sc.mean_of_softmax_ranked
        assert sc.AGGREGATOR_NAME == "mean_of_softmax_ranked"

    def test_aggregator_refuses_empty(self):
        with pytest.raises(ValueError):
            sc.mean_of_softmax_ranked(np.zeros((0, 256)))

    @pytest.mark.parametrize(
        ("argmax", "in_range"),
        [(30, True), (170, True), (29, False), (25, False), (171, False), (0, False), (255, False)],
    )
    def test_decode_reports_raw_and_flags_range(self, argmax, in_range):
        probs = np.zeros(256)
        probs[argmax] = 1.0
        bpm, ok = ft.decode_bpm(probs)
        assert bpm == 30.0 + argmax
        assert ok is in_range


class TestBandsAndCategories:
    @pytest.mark.parametrize(
        ("truth", "band"),
        [(99.9, "<100"), (100.0, "100-140"), (140.0, "100-140"), (140.1, ">140"), (174.0, ">140")],
    )
    def test_bands(self, truth, band):
        assert rp.tempo_band(truth) == band

    @pytest.mark.parametrize(
        ("pred", "truth", "category"),
        [
            (120.0, 120.0, "within-4pct"),
            (124.8, 120.0, "within-4pct"),
            (60.0, 120.0, "octave-halving"),
            (87.0, 174.0, "octave-halving"),
            (240.0, 120.0, "octave-doubling"),
            (80.0, 120.0, "non-octave-over-4pct"),  # 2:3 triplet error
            (125.0, 120.0, "non-octave-over-4pct"),
            (None, 120.0, "abstained"),
            (float("nan"), 120.0, "abstained"),
        ],
    )
    def test_categories(self, pred, truth, category):
        assert rp.error_category(pred, truth) == category

    def test_every_miss_has_a_miss_category(self):
        for pred in np.linspace(40.0, 300.0, 400):
            if not rp.arm_result(float(pred), 128.0)["acc1"]:
                assert rp.error_category(float(pred), 128.0) != "within-4pct"


def _rows(n: int, *, hits: int, prefix: str = "t", truth: float = 120.0):
    return [(f"{prefix}{i:04d}", truth if i < hits else 50.0, truth) for i in range(n)]


class TestJoinAndAnchors:
    def _patch_counts(self, monkeypatch, n=10):
        monkeypatch.setitem(rp.EXPECTED_COUNTS, "giantsteps", n)
        monkeypatch.setitem(rp.EXPECTED_ACC1, ("giantsteps", "legacy"), 6)
        monkeypatch.setitem(rp.EXPECTED_ACC1, ("giantsteps", "tempoCnn"), 8)

    def test_exact_join_passes(self, monkeypatch):
        self._patch_counts(monkeypatch)
        joined = rp.join_arms(
            "giantsteps",
            {
                "variant": _rows(10, hits=7),
                "legacy": _rows(10, hits=6),
                "tempoCnn": _rows(10, hits=8),
            },
        )
        counts = rp.check_expected_acc1("giantsteps", joined)
        assert counts == {"variant": 7, "legacy": 6, "tempoCnn": 8}
        s = rp.summarize("giantsteps", joined)
        assert s["deltaAcc1"] == {"variantMinusLegacy": 1, "variantMinusTempoCnn": -1}
        assert s["paired"]["legacy"] == {
            "bothHit": 6,
            "variantOnly": 1,
            "legacyOnly": 0,
            "bothMiss": 3,
        }

    def test_expected_acc1_drift_refuses(self, monkeypatch):
        self._patch_counts(monkeypatch)
        joined = rp.join_arms(
            "giantsteps",
            {
                "variant": _rows(10, hits=7),
                "legacy": _rows(10, hits=5),
                "tempoCnn": _rows(10, hits=8),
            },
        )
        with pytest.raises(rp.ReportRefusal, match="legacy strict Acc1 recomputes to 5"):
            rp.check_expected_acc1("giantsteps", joined)

    def test_missing_id_refuses_and_lists_it(self, monkeypatch):
        self._patch_counts(monkeypatch)
        with pytest.raises(rp.ReportRefusal, match="missing ids \\['t0009'\\]"):
            rp.join_arms(
                "giantsteps",
                {
                    "variant": _rows(10, hits=7),
                    "legacy": _rows(9, hits=6),
                    "tempoCnn": _rows(10, hits=8),
                },
            )

    def test_duplicate_id_refuses_and_lists_it(self, monkeypatch):
        self._patch_counts(monkeypatch)
        legacy = _rows(10, hits=6)
        legacy[9] = legacy[0]
        with pytest.raises(rp.ReportRefusal, match="duplicate ids \\['t0000'\\]"):
            rp.join_arms(
                "giantsteps",
                {"variant": _rows(10, hits=7), "legacy": legacy, "tempoCnn": _rows(10, hits=8)},
            )

    def test_label_drift_refuses(self, monkeypatch):
        self._patch_counts(monkeypatch)
        legacy = _rows(10, hits=6)
        legacy[3] = ("t0003", 120.0, 121.0)
        with pytest.raises(rp.ReportRefusal, match="labels differ across arms for \\['t0003'\\]"):
            rp.join_arms(
                "giantsteps",
                {"variant": _rows(10, hits=7), "legacy": legacy, "tempoCnn": _rows(10, hits=8)},
            )

    def test_exposure_counts_hash_membership_per_source(self):
        pools = {
            "tony.train": {"h2"},
            "secondarySupervised": {"h3", "zz"},
            "unsupervisedPool": {"h2"},
        }
        pools["unattributed"] = {"h4"}
        e = rp.exposure({"a": "h1", "b": "h2", "c": "h3", "d": "h4"}, pools)
        assert e["tracks"] == 4
        assert e["inPretrainingPool"] == 3
        assert e["trackIds"] == ["b", "c", "d"]
        assert e["labelledTrainingOverlap"] == 1
        assert e["labelFreeBySource"] == {"secondarySupervised": 1, "unsupervisedPool": 1}
        assert e["unattributed"] == 1
        assert "byte-identical" in e["matchRule"]

    def test_pool_attribution_per_source_and_per_arm(self, tmp_path, monkeypatch):
        import ablation_locator as loc
        from ablation_locator import LabeledRecord

        root = tmp_path / "tony"
        root.mkdir()
        files = {}
        for name in ("train.mp3", "both.mp3", "sec.mp3", "uns.mp3", "stray.mp3"):
            (root / name).write_bytes(name.encode())
            files[name] = hashlib.sha256(name.encode()).hexdigest()
        sec = tmp_path / "sec.json"
        uns = tmp_path / "uns.json"
        sec.write_text(
            json.dumps(
                {
                    "secondarySupervised": [
                        {"relPath": "sec.mp3", "audioHash": files["sec.mp3"]},
                        # A tony.train file a manifest also lists counts as tony.train.
                        {"relPath": "both.mp3", "audioHash": files["both.mp3"]},
                    ]
                }
            )
        )
        uns.write_text(
            json.dumps(
                {"unsupervisedPool": [{"relPath": "uns.mp3", "audioHash": files["uns.mp3"]}]}
            )
        )
        monkeypatch.setattr(loc, "SECONDARY_MANIFEST", sec)
        monkeypatch.setattr(loc, "UNSUPERVISED_MANIFEST", uns)
        monkeypatch.setattr(loc, "tony_audio_root", lambda: root)
        train = [
            LabeledRecord("t1", root / "train.mp3", 120.0),
            LabeledRecord("t2", root / "both.mp3", 128.0),
        ]
        monkeypatch.setattr(loc, "build_labeled_records", lambda w: train if w == "train" else [])
        monkeypatch.setattr(
            loc,
            "build_pretrain_audio_paths",
            lambda: [
                root / n for n in ("train.mp3", "both.mp3", "sec.mp3", "uns.mp3", "stray.mp3")
            ],
        )
        legacy_manifests = {
            "secondarySupervised": {
                "rows": [{"relPath": "sec.mp3", "audioHash": files["sec.mp3"]}]
            },
            "unsupervisedPool": {
                "rows": [
                    {"relPath": "uns.mp3", "audioHash": files["uns.mp3"]},
                    {"relPath": "Mixes/mix.mp3", "audioHash": "mixhash"},
                ]
            },
        }
        cache: dict = {}
        pools = rp.pretraining_pool_hashes(cache, legacy_manifests)
        variant = pools["variant"]
        assert variant["tony.train"] == {files["train.mp3"], files["both.mp3"]}
        assert variant["secondarySupervised"] == {files["sec.mp3"]}
        assert variant["unsupervisedPool"] == {files["uns.mp3"]}
        assert variant["unattributed"] == {files["stray.mp3"]}
        assert pools["legacy"]["unsupervisedPool"] == {files["uns.mp3"], "mixhash"}
        assert pools["legacy"]["tony.train"] == variant["tony.train"]
        assert len(cache) == 3  # train, both and stray were hashed; manifest rows were not

        hashes = {"a": files["both.mp3"], "b": files["sec.mp3"], "c": "mixhash", "d": "none"}
        v = rp.exposure(hashes, pools["variant"])
        g = rp.exposure(hashes, pools["legacy"])
        assert (v["labelledTrainingOverlap"], v["inPretrainingPool"]) == (1, 2)
        assert v["labelFreeBySource"] == {"secondarySupervised": 1, "unsupervisedPool": 0}
        assert g["labelFreeBySource"] == {"secondarySupervised": 1, "unsupervisedPool": 1}
        assert g["inPretrainingPool"] == 3

    @pytest.mark.parametrize(
        ("b", "c", "p"),
        [(0, 0, 1.0), (5, 5, 1.0), (10, 0, 2 / 1024), (0, 10, 2 / 1024), (9, 1, 22 / 1024)],
    )
    def test_mcnemar_exact_p(self, b, c, p):
        assert rp.mcnemar_exact_p(b, c) == pytest.approx(p)

    def test_summary_carries_mcnemar_per_pairing(self, monkeypatch):
        self._patch_counts(monkeypatch)
        joined = rp.join_arms(
            "giantsteps",
            {
                "variant": _rows(10, hits=7),
                "legacy": _rows(10, hits=6),
                "tempoCnn": _rows(10, hits=8),
            },
        )
        s = rp.summarize("giantsteps", joined)
        assert s["mcnemarExactP"]["legacy"] == pytest.approx(1.0)  # 1 vs 0 discordant
        assert set(s["mcnemarExactP"]) == {"legacy", "tempoCnn"}


class TestAudioHashRefusal:
    def test_changed_audio_refuses_naming_the_track(self, tmp_path):
        good = tmp_path / "good.wav"
        good.write_bytes(b"abc")
        bad = tmp_path / "bad.wav"
        bad.write_bytes(b"changed")
        rows = [
            {
                "trackId": "row-good",
                "audioPath": str(good),
                "audioSha256": hashlib.sha256(b"abc").hexdigest(),
            },
            {
                "trackId": "row-bad",
                "audioPath": str(bad),
                "audioSha256": hashlib.sha256(b"orig").hexdigest(),
            },
        ]
        with pytest.raises(sc.ScoreRefusal, match="row-bad") as info:
            sc.verify_audio_hashes(rows)
        assert "row-good" not in str(info.value)

    def test_missing_audio_refuses(self, tmp_path):
        rows = [{"trackId": "row-x", "audioPath": str(tmp_path / "nope.wav"), "audioSha256": "0"}]
        with pytest.raises(sc.ScoreRefusal, match="row-x"):
            sc.verify_audio_hashes(rows)

    def test_locked_rows_only(self, tmp_path):
        doc = {
            "tracks": [
                {
                    "trackId": "a",
                    "category": "locked-12.7-member",
                    "audioPath": "x",
                    "audioSha256": "1",
                    "groundTruthBPM": 120,
                },
                {
                    "trackId": "b",
                    "category": "blinded-e-extra",
                    "audioPath": "y",
                    "audioSha256": "2",
                    "groundTruthBPM": 120,
                },
            ]
        }
        path = tmp_path / "input.json"
        path.write_text(json.dumps(doc))
        rows = sc.load_eval_12_7_rows(path)
        assert [r["trackId"] for r in rows] == ["a"]


def _variant_oa300(*rows):
    """Score-doc rows: (trackId, title, truth)."""
    return [{"trackId": t, "title": title, "groundTruthBPM": truth} for t, title, truth in rows]


def _legacy_oa300(*rows):
    """Legacy dump rows: (title, prediction, truth)."""
    return [{"title": title, "bpm": bpm, "truth": truth} for title, bpm, truth in rows]


class TestOa300Pairing:
    def test_unique_key_pairs(self):
        out = rp.pair_legacy_oa300(
            _legacy_oa300(("A", 120.0, 120.0), ("B", 157.0, 157.85), ("B", 140.0, 157.84)),
            _variant_oa300(
                ("x/a.mp3", "A", 120.0), ("b1.mp3", "B", 157.85), ("b2.mp3", "B", 157.84)
            ),
        )
        assert sorted(out) == [
            ("b1.mp3", 157.0, 157.85),
            ("b2.mp3", 140.0, 157.84),
            ("x/a.mp3", 120.0, 120.0),
        ]

    def test_shared_key_same_prediction_pairs_both(self):
        out = rp.pair_legacy_oa300(
            _legacy_oa300(("S", 169.0, 170.0), ("S", 169.0, 170.0)),
            _variant_oa300(("s1.mp3", "S", 170.0), ("s2.mp3", "S", 170.0)),
        )
        assert sorted(out) == [("s1.mp3", 169.0, 170.0), ("s2.mp3", 169.0, 170.0)]

    def test_shared_key_different_predictions_refuses_naming_the_key(self):
        with pytest.raises(rp.ReportRefusal, match="'S', 170.0.*different BPMs"):
            rp.pair_legacy_oa300(
                _legacy_oa300(("S", 169.0, 170.0), ("S", 140.0, 170.0)),
                _variant_oa300(("s1.mp3", "S", 170.0), ("s2.mp3", "S", 170.0)),
            )

    def test_key_count_mismatch_refuses_naming_the_key(self):
        with pytest.raises(rp.ReportRefusal, match="'S', 170.0.*2 variant rows, 1 legacy rows"):
            rp.pair_legacy_oa300(
                _legacy_oa300(("S", 169.0, 170.0)),
                _variant_oa300(("s1.mp3", "S", 170.0), ("s2.mp3", "S", 170.0)),
            )

    def test_unused_legacy_row_refuses_naming_it(self):
        with pytest.raises(rp.ReportRefusal, match="'Z', 99.0.*\\(1 legacy row unused\\)"):
            rp.pair_legacy_oa300(
                _legacy_oa300(("A", 120.0, 120.0), ("Z", 99.0, 99.0)),
                _variant_oa300(("a.mp3", "A", 120.0)),
            )

    def test_surplus_legacy_rows_are_counted_when_the_variant_has_some(self):
        with pytest.raises(rp.ReportRefusal, match="'S', 170.0.*\\(2 legacy rows unused\\)"):
            rp.pair_legacy_oa300(
                _legacy_oa300(*[("S", 169.0, 170.0)] * 3),
                _variant_oa300(("s1.mp3", "S", 170.0)),
            )

    def test_label_differs_from_legacy_refuses(self):
        # A changed label makes two unmatched keys, both named.
        with pytest.raises(rp.ReportRefusal) as info:
            rp.pair_legacy_oa300(
                _legacy_oa300(("A", 120.0, 120.0)), _variant_oa300(("a.mp3", "A", 121.0))
            )
        assert "('A', 120.0)" in str(info.value) and "('A', 121.0)" in str(info.value)

    def test_expected_count_drift_refuses_naming_43(self):
        variant = [(f"v{i:02d}.mp3", 120.0, 120.0) for i in range(82)]
        legacy = [(tid, 120.0 if i < 42 else 50.0, 120.0) for i, (tid, _, _) in enumerate(variant)]
        joined = rp.join_arms("oa300", {"variant": variant, "legacy": legacy})
        with pytest.raises(
            rp.ReportRefusal, match="oa300/legacy strict Acc1 recomputes to 42, expected 43"
        ):
            rp.check_expected_acc1("oa300", joined)

    def test_expected_count_matches(self):
        variant = [(f"v{i:02d}.mp3", 120.0, 120.0) for i in range(82)]
        legacy = [(tid, 120.0 if i < 43 else 50.0, 120.0) for i, (tid, _, _) in enumerate(variant)]
        joined = rp.join_arms("oa300", {"variant": variant, "legacy": legacy})
        assert rp.check_expected_acc1("oa300", joined) == {"variant": 82, "legacy": 43}
        assert rp.summarize("oa300", joined)["tempoCnn"] == rp.NOT_RUN

    def test_load_legacy_reads_only_oa300_rows(self, tmp_path):
        path = tmp_path / "predictions.json"
        path.write_text(
            json.dumps(
                [
                    {"corpus": "oa300", "trackId": "A", "fr18ModelBPM": 120, "groundTruthBPM": 120},
                    {
                        "corpus": "giantsteps",
                        "trackId": "g",
                        "fr18ModelBPM": 1,
                        "groundTruthBPM": 2,
                    },
                ]
            )
        )
        assert rp.load_legacy_oa300(path) == [{"title": "A", "bpm": 120.0, "truth": 120.0}]

    def test_manifest_requires_oa300_scoring_time_hash(self):
        with pytest.raises(
            rp.ReportRefusal, match="scores-oa300.json does not record oa300GroundTruth"
        ):
            rp.build_manifest(
                _training_md(),
                {"giantsteps": _score_doc(), "oa300": _score_doc()},
                TestBuildManifest.INPUTS,
            )

    def test_manifest_refuses_oa300_labels_changed_since_scoring(self):
        scored = {"oa300GroundTruth": "o" * 64}
        inputs = {
            **TestBuildManifest.INPUTS,
            "oa300GroundTruth": {"path": "oa.json", "sha256": "n" * 64},
        }
        with pytest.raises(rp.ReportRefusal, match="oa300GroundTruth sha256 at report time"):
            rp.build_manifest(
                _training_md(),
                {"giantsteps": _score_doc(), "oa300": _score_doc(scoredInputs=scored)},
                inputs,
            )

    def test_manifest_checks_only_each_corpus_own_label_source(self):
        # A GiantSteps scores file is not invalidated by an OA300 label change,
        # even when it carries a stale oa300GroundTruth entry.
        inputs = {
            **TestBuildManifest.INPUTS,
            "oa300GroundTruth": {"path": "oa.json", "sha256": "n" * 64},
        }
        gs = _score_doc(
            scoredInputs={"giantstepsGroundTruth": "g" * 64, "oa300GroundTruth": "o" * 64}
        )
        oa = _score_doc(scoredInputs={"oa300GroundTruth": "n" * 64})
        m = rp.build_manifest(_training_md(), {"giantsteps": gs, "oa300": oa}, inputs)
        assert m["inputs"] == inputs


class TestScoreRecordsOwnLabelSource:
    def test_each_scores_file_records_only_its_corpus_label_source(self, tmp_path, monkeypatch):
        import types

        import dataset as ds

        (tmp_path / "model.pt").write_bytes(b"")
        captured: dict[str, dict] = {}
        monkeypatch.setattr(
            sc,
            "resolve_corpus",
            lambda corpus, **_kw: ([], {"path": f"{corpus}.json", "sha256": f"s-{corpus}"}),
        )
        monkeypatch.setattr(sc, "load_model", lambda *_a: None)
        monkeypatch.setattr(ds, "load_fixture", lambda _p: types.SimpleNamespace(sha256="f"))
        monkeypatch.setattr(ft, "check_fixture", lambda _f: None)
        monkeypatch.setattr(
            sc,
            "score_corpus",
            lambda corpus, _rows, _m, _f, _d, _out, meta, _agg: captured.setdefault(corpus, meta),
        )
        assert sc.main(["--run-dir", str(tmp_path)]) == 0
        assert {c: m["scoredInputs"] for c, m in captured.items()} == {
            "giantsteps": {"giantstepsGroundTruth": "s-giantsteps"},
            "eval-12-7": {"bundleGateInput": "s-eval-12-7"},
            "oa300": {"oa300GroundTruth": "s-oa300"},
        }


def _write_json(path: Path, doc) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc))
    return path


def _report_run(tmp_path, monkeypatch, *, second_shared_legacy_bpm: float):
    """A minimal run directory and legacy root that `rp.main` reads end to end.

    GiantSteps and 12.7 hold 2 tracks each; OA300 holds 3, two of which share
    the (title, label) key ("Song S", 170.0). Exposure inputs are stubbed.
    Returns (argv, run_dir)."""
    import ablation_locator as loc
    import corpus_common as cc
    import dataset as ds

    run = tmp_path / "run"
    legacy_root = tmp_path / "legacy"
    side = tmp_path / "side"
    run.mkdir()
    for name in ("secondary.json", "unsupervised.json", "splits.json", "labels.json"):
        _write_json(side / name, {})
    _write_json(side / "pool-durations.json", {})
    monkeypatch.setattr(loc, "SECONDARY_MANIFEST", side / "secondary.json")
    monkeypatch.setattr(loc, "UNSUPERVISED_MANIFEST", side / "unsupervised.json")
    monkeypatch.setattr(loc, "CORPUS_SPLITS", side / "splits.json")
    monkeypatch.setattr(loc, "ML_TRAINING_DIR", side)
    monkeypatch.setattr(cc, "TONY_TRUTH_LABELS", side / "labels.json")
    fixture = side / "fixture.npz"
    fixture.write_bytes(b"fixture")
    monkeypatch.setattr(ds, "FIXTURE_PATH", fixture)
    monkeypatch.setattr(rp, "load_legacy_manifests", lambda: {})
    monkeypatch.setattr(
        rp,
        "pretraining_pool_hashes",
        lambda _cache, _manifests: {
            arm: {src: set() for src in rp.POOL_SOURCES} for arm in ("variant", "legacy")
        },
    )
    for corpus, n in (("giantsteps", 2), ("eval-12-7", 2), ("oa300", 3)):
        monkeypatch.setitem(rp.EXPECTED_COUNTS, corpus, n)
    monkeypatch.setattr(
        rp,
        "EXPECTED_ACC1",
        {
            ("giantsteps", "legacy"): 2,
            ("eval-12-7", "legacy"): 2,
            ("oa300", "legacy"): 3,
            ("giantsteps", "tempoCnn"): 2,
        },
    )

    gs_truth = _write_json(side / "giantsteps-tempo-ground-truth.json", [])
    bundle_input = _write_json(legacy_root / rp.BUNDLE_GATE_INPUT_RELPATH, {"tracks": []})
    oa300_truth_sha = sc.sha256_file(sc.oa300_ground_truth_path())
    plan = _write_json(run / "crop-plan.json", {"plan": 1})
    (run / "model.pt").write_bytes(b"weights")
    _write_json(
        run / "metadata.json",
        _training_md(
            cropPlan={"sha256": sc.sha256_file(plan), "keptSongs": {}, "skippedSongs": {}}
        ),
    )

    gs = [("g1.mp3", 120.0), ("g2.mp3", 128.0)]
    e127 = [("e1", 100.0), ("e2", 140.0)]
    oa = [
        ("house/a.mp3", "Song A", 120.0),
        ("b.mp3", "Song S", 170.0),
        ("dnb/c.mp3", "Song S", 170.0),
    ]

    def variant_row(tid, truth, **extra):
        return {
            "trackId": tid,
            "variantBPM": truth,
            "groundTruthBPM": truth,
            "audioSha256": "h-" + tid,
            "abstained": None,
            "inRuntimeRange": True,
            **extra,
        }

    docs = {
        "giantsteps": (
            [variant_row(t, b) for t, b in gs],
            {"giantstepsGroundTruth": sc.sha256_file(gs_truth)},
            str(gs_truth),
        ),
        "eval-12-7": (
            [variant_row(t, b) for t, b in e127],
            {"bundleGateInput": sc.sha256_file(bundle_input)},
            str(bundle_input),
        ),
        "oa300": (
            [variant_row(t, b, title=title) for t, title, b in oa],
            {"oa300GroundTruth": oa300_truth_sha},
            "Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json",
        ),
    }
    for corpus, (rows, scored, label_path) in docs.items():
        (run / f"crops-{corpus}.npz").write_bytes(b"npz-" + corpus.encode())
        _write_json(
            run / f"scores-{corpus}.json",
            _score_doc(
                rows=rows,
                scoredInputs=scored,
                labelSource={"path": label_path, "sha256": next(iter(scored.values()))},
                featureFixtureSha256="f",
                aggregator=sc.AGGREGATOR_NAME,
                cropProbabilitiesFile=f"crops-{corpus}.npz",
            ),
        )

    legacy_dump = [
        {"corpus": "giantsteps", "trackId": t, "fr18ModelBPM": b, "groundTruthBPM": b}
        for t, b in gs
    ] + [
        {"corpus": "oa300", "trackId": "Song A", "fr18ModelBPM": 120.0, "groundTruthBPM": 120.0},
        {"corpus": "oa300", "trackId": "Song S", "fr18ModelBPM": 169.0, "groundTruthBPM": 170.0},
        {
            "corpus": "oa300",
            "trackId": "Song S",
            "fr18ModelBPM": second_shared_legacy_bpm,
            "groundTruthBPM": 170.0,
        },
    ]
    _write_json(legacy_root / rp.LEGACY_GIANTSTEPS_RELPATH, legacy_dump)
    _write_json(
        legacy_root / rp.LEGACY_12_7_RELPATH,
        [
            {"trackId": t, "category": rp.LOCKED_CATEGORY, "modelBPM": b, "groundTruthBPM": b}
            for t, b in e127
        ],
    )
    tempocnn = _write_json(
        tmp_path / "tempocnn.json",
        {"tracks": [{"trackId": t, "modelBPM": b, "groundTruthBPM": b} for t, b in gs]},
    )
    argv = [
        "--run-dir",
        str(run),
        "--legacy-root",
        str(legacy_root),
        "--tempocnn",
        str(tempocnn),
    ]
    return argv, run


def _snapshot(directory: Path) -> dict[str, bytes]:
    return {p.name: p.read_bytes() for p in sorted(directory.iterdir())}


class TestReportMainOa300:
    def test_shared_key_with_different_legacy_predictions_writes_nothing(
        self, tmp_path, monkeypatch, capsys
    ):
        argv, run = _report_run(tmp_path, monkeypatch, second_shared_legacy_bpm=140.0)
        before = _snapshot(run)
        assert rp.main(argv) == 3
        err = capsys.readouterr().err
        assert "('Song S', 170.0)" in err and "different BPMs" in err
        assert _snapshot(run) == before

    def test_consistent_run_records_the_oa300_inputs(self, tmp_path, monkeypatch):
        argv, run = _report_run(tmp_path, monkeypatch, second_shared_legacy_bpm=169.0)
        assert rp.main(argv) == 0
        manifest = json.loads((run / "manifest.json").read_text())
        assert {
            "variantScoresOa300",
            "variantCropProbabilitiesOa300",
            "legacyOa300Predictions",
            "oa300GroundTruth",
        } <= set(manifest["inputs"])
        report = json.loads((run / "fixed-time-report.json").read_text())
        assert report["expectedAcc1"]["oa300/legacy"] == {"recorded": 3, "recomputed": 3}
        assert report["summaries"]["oa300"]["tempoCnn"] == rp.NOT_RUN
        assert sorted(r["trackId"] for r in report["tracks"]["oa300"]) == [
            "b.mp3",
            "dnb/c.mp3",
            "house/a.mp3",
        ]


class TestOa300Resolution:
    GT = [
        {"filename": "a.mp3", "bpm": 120.0, "subdir": "house", "title": "Song A"},
        {"filename": "b.mp3", "bpm": 170.0, "subdir": None, "title": "Song S"},
        {"filename": "c.mp3", "bpm": 170.0, "subdir": "dnb", "title": "Song S"},
    ]

    def _corpus(self, tmp_path, monkeypatch, *, skip=()):
        import build_fr18_input
        import jams_corpus

        root = tmp_path / "oa300"
        for t in self.GT:
            rel = Path(t["subdir"], t["filename"]) if t["subdir"] else Path(t["filename"])
            if str(rel) in skip:
                continue
            (root / rel).parent.mkdir(parents=True, exist_ok=True)
            (root / rel).write_bytes(rel.name.encode())
        rows = lambda _path: [dict(t) for t in self.GT]  # noqa: E731
        monkeypatch.setattr(jams_corpus, "load_oa300_rows", rows)
        monkeypatch.setattr(build_fr18_input, "load_oa300_rows", rows)
        monkeypatch.setitem(sc.EXPECTED_COUNTS, "oa300", len(self.GT))
        return root

    def test_rows_carry_relative_path_ids_title_and_hash(self, tmp_path, monkeypatch):
        root = self._corpus(tmp_path, monkeypatch)
        rows, source = sc.resolve_corpus(
            "oa300", giantsteps_root="", bundle_gate_input=tmp_path / "x", oa300_root=str(root)
        )
        assert [(r["trackId"], r["title"]) for r in rows] == [
            ("house/a.mp3", "Song A"),
            ("b.mp3", "Song S"),
            ("dnb/c.mp3", "Song S"),
        ]
        assert rows[0]["audioSha256"] == hashlib.sha256(b"a.mp3").hexdigest()
        assert all(r["corpus"] == "oa300" for r in rows)
        assert (
            source["path"] == "Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json"
        )
        assert len(source["sha256"]) == 64

    def test_missing_audio_refuses_naming_the_file(self, tmp_path, monkeypatch):
        root = self._corpus(tmp_path, monkeypatch, skip=("dnb/c.mp3",))
        with pytest.raises(sc.ScoreRefusal, match="dnb/c.mp3") as info:
            sc.resolve_oa300_rows(str(root))
        assert "house/a.mp3" not in str(info.value)

    def test_missing_audio_exits_nonzero(self, tmp_path, monkeypatch, capsys):
        root = self._corpus(tmp_path, monkeypatch, skip=("b.mp3",))
        run = tmp_path / "run"
        run.mkdir()
        (run / "model.pt").write_bytes(b"")
        monkeypatch.setenv("OA300_CORPUS_PATH", str(root))
        assert sc.main(["--run-dir", str(run), "--corpus", "oa300"]) == 3
        assert "b.mp3" in capsys.readouterr().err
        assert sorted(p.name for p in run.iterdir()) == ["model.pt"]

    def test_unset_corpus_path_refuses(self):
        with pytest.raises(sc.ScoreRefusal, match="OA300_CORPUS_PATH"):
            sc.resolve_oa300_rows("")


class TestRecipeGuard:
    LEGACY = {
        "splitVersionHash": tr.LEGACY_SPLIT_VERSION_HASH,
        "corpusVersionHash": tr.LEGACY_CORPUS_VERSION_HASH,
        "trainingVariant": "maskedMelPretrain",
        "seed": 42,
        "pretrainEpochs": 30,
        "epochCount": 60,
        "tempoBandRebalanced": True,
        "weightingProfile": "uniform",
        "maskRatio": 0.15,
    }

    def test_matching_split_and_recipe_pass(self):
        tr.check_recipe(self.LEGACY, split_hash=tr.LEGACY_SPLIT_VERSION_HASH)

    def test_corpus_hash_drift_is_recorded_not_refused(self):
        current = "7bc1" + "0" * 60
        tr.check_recipe(self.LEGACY, split_hash=tr.LEGACY_SPLIT_VERSION_HASH)  # no raise
        drift = tr.corpus_drift(
            self.LEGACY,
            corpus_hash=current,
            manifest_rows={"secondarySupervised": 2154, "unsupervisedPool": 2162},
        )
        assert drift["matches"] is False
        assert drift["legacyCorpusVersionHash"] == tr.LEGACY_CORPUS_VERSION_HASH
        assert drift["currentCorpusVersionHash"] == current
        assert drift["differingRows"] == {
            "secondarySupervised": {"legacy": 2172, "current": 2154},
            "unsupervisedPool": {"legacy": 2407, "current": 2162},
        }

    def test_matching_corpus_records_no_differing_rows(self):
        drift = tr.corpus_drift(
            self.LEGACY,
            corpus_hash=tr.LEGACY_CORPUS_VERSION_HASH,
            manifest_rows=dict(tr.LEGACY_MANIFEST_ROWS),
        )
        assert drift["matches"] is True and drift["differingRows"] == {}

    def test_split_hash_drift_refuses(self):
        with pytest.raises(tr.RecipeDriftError, match="split hash deadbeef"):
            tr.check_recipe(self.LEGACY, split_hash="deadbeef")

    def test_recorded_recipe_drift_refuses(self):
        legacy = {**self.LEGACY, "tempoBandRebalanced": False}
        with pytest.raises(tr.RecipeDriftError, match="tempoBandRebalanced"):
            tr.check_recipe(legacy, split_hash=tr.LEGACY_SPLIT_VERSION_HASH)

    def test_recipe_pins_the_values_train_py_passes(self):
        from train import TrainArgs

        legacy = TrainArgs()
        assert tr.RECIPE["octaveMass"] == legacy.octave_mass == 0.15
        assert tr.RECIPE["labelSmoothing"] == legacy.label_smoothing == 0.1
        assert tr.RECIPE["learningRate"] == legacy.lr
        assert tr.RECIPE["batchSize"] == legacy.batch_size
        assert tr.RECIPE["pretrainEpochs"] == legacy.pretrain_epochs
        assert tr.RECIPE["epochCount"] == legacy.epochs
        import masked_mel

        assert tr.RECIPE["maskRatio"] == masked_mel.DEFAULT_MASK_RATIO
        assert tr.RECIPE["maskSpan"] == masked_mel.DEFAULT_SPAN


# ---------------------------------------------------------------------------
# Review additions: training crop, datasets, score_track, manifest, markdown
# ---------------------------------------------------------------------------


@pytest.fixture(scope="module")
def feature_fixture():
    import dataset as ds

    return ds.load_fixture(ds.FIXTURE_PATH)


class TestTrainingCrop:
    def _capture(self, monkeypatch):
        """Wrap augment_pcm to record the segment it gets and the rate it draws."""
        real = ft.augment_pcm
        seen: dict = {}

        def wrapped(audio, bpm, rng, sr, allow_stretch):
            probe = random.Random()
            probe.setstate(rng.getstate())
            seen["rate"] = probe.uniform(0.96, 1.04) if allow_stretch else 1.0
            seen["allow_stretch"] = allow_stretch
            seen["segment_len"] = audio.shape[0]
            return real(audio, bpm, rng, sr=sr, allow_stretch=allow_stretch)

        monkeypatch.setattr(ft, "augment_pcm", wrapped)
        monkeypatch.setattr(ft, "label_preserving_pitch_shift", lambda a, rng, sr: a)
        return seen

    def _audio(self, seconds):
        return (
            np.random.default_rng(5).standard_normal(int(44_100 * seconds)).astype(np.float32) * 0.1
        )

    def test_segment_starts_at_the_crop(self):
        assert ft.augmentation_segment(44_100 * 60, 600) == (600 * 441, 0, True)

    def test_segment_shifts_left_near_the_end(self):
        n = 44_100 * 30
        start = ft.crop_plan(ft.frame_count(n))[-1]  # the tail crop
        seg_start, d, ok = ft.augmentation_segment(n, start)
        assert ok and seg_start + ft.AUG_SEGMENT_SAMPLES == n
        assert d == start * 441 - seg_start > 0

    def test_short_song_gets_bare_crop_without_stretch(self):
        assert ft.augmentation_segment(ft.CROP_SAMPLES + 10, 0) == (0, 0, False)

    def test_crop_shape_and_label_follow_the_drawn_rate(self, monkeypatch, feature_fixture):
        seen = self._capture(monkeypatch)
        crop, label = ft.training_crop(
            self._audio(40), 600, 128.0, feature_fixture, random.Random(11)
        )
        assert crop.shape == (128, 1200)
        assert seen["allow_stretch"] is True and seen["segment_len"] == ft.AUG_SEGMENT_SAMPLES
        assert label == ft.bin_for(128.0 * seen["rate"])

    def test_crop_covers_the_ranked_audio_after_a_shift(self, monkeypatch, feature_fixture):
        """With the identity augmentation, the crop is exactly the planned crop."""
        monkeypatch.setattr(ft, "augment_pcm", lambda a, bpm, rng, sr, allow_stretch: (a, bpm))
        monkeypatch.setattr(ft, "label_preserving_pitch_shift", lambda a, rng, sr: a)
        audio = self._audio(30)
        start = ft.crop_plan(ft.frame_count(audio.shape[0]))[-1]
        crop, _ = ft.training_crop(audio, start, 120.0, feature_fixture, random.Random(1))
        np.testing.assert_allclose(crop, ft.crop_tensor_at(audio, start, feature_fixture))

    def test_stretched_crop_starts_at_d_over_r(self, monkeypatch, feature_fixture):
        """A 2 % stretch: the crop is cut at round(d / r) of the stretched segment."""
        rate = 1.02
        cut: dict = {}

        def stretch(a, bpm, rng, sr, allow_stretch):
            return np.ascontiguousarray(a[::1][: int(a.shape[0] / rate)]), bpm * rate

        real_cut = ft.crop_tensor_from_pcm

        def record(pcm, fixture):
            cut["first"] = float(pcm[0])
            return real_cut(pcm, fixture)

        monkeypatch.setattr(ft, "augment_pcm", stretch)
        monkeypatch.setattr(ft, "label_preserving_pitch_shift", lambda a, rng, sr: a)
        monkeypatch.setattr(ft, "crop_tensor_from_pcm", record)
        audio = np.arange(44_100 * 30, dtype=np.float32)
        start = 600
        seg_start, d, _ = ft.augmentation_segment(audio.shape[0], start)
        _, label = ft.training_crop(audio, start, 120.0, feature_fixture, random.Random(1))
        assert cut["first"] == audio[seg_start + int(round(d / rate))]
        assert label == ft.bin_for(120.0 * rate)

    def test_short_song_trains_with_stretch_off(self, monkeypatch, feature_fixture):
        seen = self._capture(monkeypatch)
        audio = self._audio((ft.CROP_SAMPLES + 5_000) / 44_100)
        assert audio.shape[0] < ft.AUG_SEGMENT_SAMPLES
        crop, label = ft.training_crop(audio, 0, 128.0, feature_fixture, random.Random(3))
        assert crop.shape == (128, 1200)
        assert seen["allow_stretch"] is False and seen["segment_len"] == ft.CROP_SAMPLES
        assert label == ft.bin_for(128.0)

    def test_label_unscaled_above_stretch_ceiling(self, monkeypatch, feature_fixture):
        seen = self._capture(monkeypatch)
        bpm = ft.BPM_BIN_MAX / 1.04 + 1.0
        crop, label = ft.training_crop(self._audio(40), 0, bpm, feature_fixture, random.Random(12))
        assert crop.shape == (128, 1200)
        assert seen["allow_stretch"] is False
        assert label == ft.bin_for(bpm)


# ---------------------------------------------------------------------------
# Crop plan
# ---------------------------------------------------------------------------

RECIPE_SMALL = {"seed": 42, "pretrainEpochs": 3, "epochCount": 4}


def _ranking(kept, skipped=None):
    return {
        "fileSize": 1000,
        "fileMtimeNs": 7,
        "frames": 11_996,
        "candidateCrops": 19,
        "bestRhythmScore": kept[0][1] if kept else 0.0,
        "kept": [
            {"startFrame": s, "startSeconds": ft.start_seconds(s), "rhythmScore": r}
            for s, r in kept
        ],
        "skipped": skipped,
    }


def _lists():
    return {
        "pretrain": [{"key": "/a.mp3", "path": "/a.mp3"}, {"key": "/z.mp3", "path": "/z.mp3"}],
        "train": [{"key": "/b.mp3", "path": "/b.mp3", "trackId": "b"}],
        "val": [{"key": "/c.mp3", "path": "/c.mp3", "trackId": "c"}],
    }


def _same(_path):
    return {"fileSize": 1000, "fileMtimeNs": 7}


def _rankings():
    return {
        "/a.mp3": _ranking([(600, 0.9), (0, 0.6)]),
        "/z.mp3": _ranking([], skipped=ft.ABSTAIN_NO_RHYTHM),
        "/b.mp3": _ranking([(1200, 0.8), (600, 0.7), (0, 0.5)]),
        "/c.mp3": _ranking([(1800, 0.7), (0, 0.4)]),
    }


class TestPlan:
    def test_rank_audio_records_kept_crops_with_timestamps(self):
        audio = np.concatenate([np.zeros(44_100 * 13, np.float32), click_track(20.0)])
        r = cp.rank_audio(audio)
        assert r["skipped"] is None and 1 <= len(r["kept"]) <= 4
        first = r["kept"][0]
        assert first["startSeconds"] == pytest.approx(first["startFrame"] / 100.0)
        assert first["startFrame"] >= 600  # the silent opening is never the best crop
        assert first["rhythmScore"] == pytest.approx(r["bestRhythmScore"])

    def test_rank_audio_uses_only_the_first_120s(self):
        r = cp.rank_audio(np.zeros(44_100 * 200, np.float32))
        assert r["frames"] == 11_996 and r["candidateCrops"] == 19

    def test_rank_audio_skips_silence_and_short_songs(self):
        assert cp.rank_audio(np.zeros(44_100 * 30, np.float32))["skipped"] == ft.ABSTAIN_NO_RHYTHM
        assert cp.rank_audio(np.zeros(44_100 * 5, np.float32))["skipped"] == ft.ABSTAIN_SHORT

    def test_build_plan_schedules_and_skips(self):
        plan = cp.build_plan(_lists(), _rankings(), RECIPE_SMALL)
        a, z = plan["songs"]["pretrain"]
        assert len(a["schedule"]) == 3 and set(a["schedule"]) <= {600, 0}
        assert "schedule" not in z and z["skipped"] == ft.ABSTAIN_NO_RHYTHM
        (b,) = plan["songs"]["train"]
        assert len(b["schedule"]) == 4 and set(b["schedule"]) <= {1200, 600, 0}
        assert plan["songs"]["val"][0]["validationCrop"] == 1800
        assert plan["keptSongs"] == {"pretrain": 1, "train": 1, "val": 1}
        assert plan["skippedSongs"]["pretrain"] == {ft.ABSTAIN_NO_RHYTHM: 1}

    def test_schedule_is_a_pure_function_of_seed_epoch_and_song(self):
        one = cp.build_plan(_lists(), _rankings(), RECIPE_SMALL)
        two = cp.build_plan(_lists(), _rankings(), RECIPE_SMALL)
        assert one == two
        kept = [0, 600, 1200, 1800]
        draws = [
            cp.draw_crop(kept, seed=42, phase="finetune", epoch=e, key="/b") for e in range(40)
        ]
        assert len(set(draws)) > 1  # the crop changes by epoch
        assert draws == [
            cp.draw_crop(kept, seed=42, phase="finetune", epoch=e, key="/b") for e in range(40)
        ]

    def test_validate_accepts_its_own_plan(self):
        plan = cp.build_plan(_lists(), _rankings(), RECIPE_SMALL)
        cp.validate_plan(json.loads(json.dumps(plan)), _lists(), RECIPE_SMALL, identity=_same)

    def test_validate_refuses_changed_audio(self):
        plan = cp.build_plan(_lists(), _rankings(), RECIPE_SMALL)

        def touched(path):
            return None if path == "/c.mp3" else {"fileSize": 1000, "fileMtimeNs": 8}

        with pytest.raises(cp.PlanError, match="audio files changed") as info:
            cp.validate_plan(plan, _lists(), RECIPE_SMALL, identity=touched)
        assert "val: 1 audio files" in str(info.value)

    def test_validate_refuses_missing_validation_crop(self):
        plan = cp.build_plan(_lists(), _rankings(), RECIPE_SMALL)
        del plan["songs"]["val"][0]["validationCrop"]
        with pytest.raises(cp.PlanError, match="val: 1 kept songs lack a validation crop"):
            cp.validate_plan(plan, _lists(), RECIPE_SMALL, identity=_same)

    def test_validate_refuses_validation_crop_not_kept(self):
        plan = cp.build_plan(_lists(), _rankings(), RECIPE_SMALL)
        plan["songs"]["val"][0]["validationCrop"] = 300
        with pytest.raises(cp.PlanError, match="not one of their kept crops"):
            cp.validate_plan(plan, _lists(), RECIPE_SMALL, identity=_same)

    def test_validate_refuses_scheduled_crop_not_kept(self):
        plan = cp.build_plan(_lists(), _rankings(), RECIPE_SMALL)
        plan["songs"]["train"][0]["schedule"][2] = 300
        with pytest.raises(cp.PlanError, match="train: 1 songs use a crop"):
            cp.validate_plan(plan, _lists(), RECIPE_SMALL, identity=_same)

    def test_validate_refuses_short_schedule(self):
        plan = cp.build_plan(_lists(), _rankings(), RECIPE_SMALL)
        plan["songs"]["pretrain"][0]["schedule"].pop()
        with pytest.raises(cp.PlanError, match="pretrain: 1 kept songs lack a 3-epoch schedule"):
            cp.validate_plan(plan, _lists(), RECIPE_SMALL, identity=_same)

    def test_validate_refuses_songs_that_do_not_hash_to_the_summary(self):
        plan = cp.build_plan(_lists(), _rankings(), RECIPE_SMALL)
        plan["songs"]["pretrain"].reverse()
        with pytest.raises(cp.PlanError, match="do not hash to its own song list"):
            cp.validate_plan(plan, _lists(), RECIPE_SMALL, identity=_same)

    def test_corrupt_plan_is_a_plan_error(self, tmp_path):
        (tmp_path / cp.PLAN_FILE).write_text('{"planSchema": ')
        with pytest.raises(cp.PlanError, match="not valid JSON"):
            cp.load_plan(tmp_path)

    def test_full_run_refuses_corrupt_plan_with_exit_3(self, tmp_path, monkeypatch):
        monkeypatch.setattr(tr, "run_guard", lambda _p: {"corpusDrift": None})
        (tmp_path / cp.PLAN_FILE).write_text("not json")
        assert tr.full_run(tmp_path, 0, tmp_path / "legacy.json", False) == 3
        assert [p.name for p in tmp_path.iterdir()] == [cp.PLAN_FILE]

    def test_rank_path_records_file_identity(self, tmp_path, monkeypatch):
        import ablation_locator

        song = tmp_path / "s.wav"
        song.write_bytes(b"abc")
        monkeypatch.setattr(ablation_locator, "_load_pcm", lambda _p: click_track(20.0))
        r = cp._rank_path(str(song))
        assert r["fileSize"] == 3 and r["fileMtimeNs"] == song.stat().st_mtime_ns

    def test_validate_refuses_changed_song_list(self):
        plan = cp.build_plan(_lists(), _rankings(), RECIPE_SMALL)
        lists = _lists()
        lists["train"].append({"key": "/d.mp3", "path": "/d.mp3", "trackId": "d"})
        with pytest.raises(cp.PlanError, match="train song list differs"):
            cp.validate_plan(plan, lists, RECIPE_SMALL, identity=_same)

    def test_validate_refuses_changed_rule_or_recipe(self):
        plan = cp.build_plan(_lists(), _rankings(), RECIPE_SMALL)
        stale = {**plan, "rankingRule": {**plan["rankingRule"], "maxKeptCrops": 5}}
        with pytest.raises(cp.PlanError, match="ranking rule"):
            cp.validate_plan(stale, _lists(), RECIPE_SMALL, identity=_same)
        with pytest.raises(cp.PlanError, match="recipe"):
            cp.validate_plan(plan, _lists(), {**RECIPE_SMALL, "epochCount": 60}, identity=_same)

    def test_missing_plan_refuses(self, tmp_path):
        with pytest.raises(cp.PlanError, match="no crop plan"):
            cp.load_plan(tmp_path)

    def test_full_run_refuses_without_plan_and_writes_nothing(self, tmp_path, monkeypatch):
        monkeypatch.setattr(tr, "run_guard", lambda _p: {"corpusDrift": None})
        assert tr.full_run(tmp_path, 0, tmp_path / "legacy.json", False) == 3
        assert list(tmp_path.iterdir()) == []

    def test_planned_inputs_drop_skipped_songs_before_datasets(self, monkeypatch):
        from ablation_locator import LabeledRecord
        import ablation_locator

        labels = {
            "train": [LabeledRecord("b", Path("/b.mp3"), 128.0)],
            "val": [LabeledRecord("c", Path("/c.mp3"), 140.0)],
        }
        monkeypatch.setattr(ablation_locator, "build_labeled_records", lambda w: labels[w])
        plan = cp.build_plan(_lists(), _rankings(), RECIPE_SMALL)
        inputs = tr.planned_inputs(plan)
        assert inputs["pretrainPaths"] == [Path("/a.mp3")]
        assert set(inputs["pretrainSchedules"]) == {"/a.mp3"}
        assert [r.track_id for r in inputs["trainRecords"]] == ["b"]
        assert inputs["validationCrops"] == {"/c.mp3": 1800}


class TestDatasetsFollowThePlan:
    def test_labeled_set_uses_the_epochs_crop_for_every_appearance(
        self, monkeypatch, feature_fixture
    ):
        from ablation_locator import LabeledRecord
        import fixed_time.datasets as fds

        seen = []
        monkeypatch.setattr(fds, "load_training_pcm", lambda _p: np.zeros(10, np.float32))

        def fake_crop(audio, start, bpm, fixture, rng):
            seen.append(start)
            return np.zeros((128, 1200), np.float32), ft.bin_for(bpm)

        monkeypatch.setattr(ft, "training_crop", fake_crop)
        d = fds.FixedTimeLabeledDataset(
            [LabeledRecord("b", Path("/b.mp3"), 128.0)],
            feature_fixture,
            augment=True,
            seed=42,
            weighting_profile="uniform",
            schedules={"/b.mp3": [0, 600, 1200]},
        )
        for epoch in range(3):
            d.set_epoch(epoch)
            d[0]
            d[0]
        assert seen == [0, 0, 600, 600, 1200, 1200]

    def test_pretrain_set_crops_by_epoch_and_caches_by_crop(
        self, monkeypatch, tmp_path, feature_fixture
    ):
        import fixed_time.datasets as fds

        monkeypatch.setenv("BBB_FEATURE_CACHE_DIR", str(tmp_path))
        audio = click_track(25.0)
        monkeypatch.setattr(fds, "load_training_pcm", lambda _p: audio)
        d = fds.FixedTimePretrainDataset(
            [Path("/a.mp3")], feature_fixture, schedules={"/a.mp3": [0, 600]}
        )
        x0 = d[0]
        d.set_epoch(1)
        x1 = d[0]
        assert tuple(x0.shape) == (1, 128, 1200)
        np.testing.assert_allclose(x1[0].numpy(), ft.crop_tensor_at(audio, 600, feature_fixture))
        assert fds.feature_cache_path(Path("/a.mp3"), 0, "decode-f32") != fds.feature_cache_path(
            Path("/a.mp3"), 600, "decode-f32"
        )
        assert len(list(tmp_path.glob("ft-*.npy"))) == 2

    def test_cache_key_names_the_pcm_source(self, monkeypatch, tmp_path):
        import ablation_locator as loc
        import fixed_time.datasets as fds

        monkeypatch.setenv("BBB_FEATURE_CACHE_DIR", str(tmp_path / "feat"))
        song = tmp_path / "song.mp3"
        song.write_bytes(b"x")
        a = fds.feature_cache_path(song, 0, "decode-f32")
        assert a != fds.feature_cache_path(song, 0, "pcm-cache-f16")
        monkeypatch.setattr(loc, "_PCM_CACHE_DIR", None)
        assert fds.pcm_source_for(song) == "decode-f32"
        monkeypatch.setattr(loc, "_PCM_CACHE_DIR", str(tmp_path / "pcm"))
        assert fds.pcm_source_for(song) == "decode-f32"  # no cache entry yet
        entry = loc._pcm_cache_path(song)
        entry.parent.mkdir(parents=True)
        entry.write_bytes(b"")
        assert fds.pcm_source_for(song) == "pcm-cache-f16"

    def test_cached_validation_crop_is_not_decoded(self, monkeypatch, tmp_path, feature_fixture):
        from ablation_locator import LabeledRecord
        import fixed_time.datasets as fds

        monkeypatch.setenv("BBB_FEATURE_CACHE_DIR", str(tmp_path))
        audio = click_track(25.0)
        decodes = []

        def load(path):
            decodes.append(path)
            return audio

        monkeypatch.setattr(fds, "load_training_pcm", load)
        d = fds.FixedTimeLabeledDataset(
            [LabeledRecord("c", Path("/c.mp3"), 140.0)],
            feature_fixture,
            augment=False,
            seed=42,
            weighting_profile="uniform",
            strict=True,
            validation_crops={"/c.mp3": 600},
        )
        first, _ = d[0]
        for epoch in (1, 2):
            d.set_epoch(epoch)
            again, label = d[0]
            np.testing.assert_array_equal(again.numpy(), first.numpy())
        assert len(decodes) == 1 and label == ft.bin_for(140.0)

    def test_record_without_planned_crop_refuses(self, feature_fixture):
        from ablation_locator import LabeledRecord
        from fixed_time.datasets import FixedTimeLabeledDataset

        with pytest.raises(ValueError, match="no planned crop"):
            FixedTimeLabeledDataset(
                [LabeledRecord("b", Path("/b.mp3"), 128.0)],
                feature_fixture,
                augment=False,
                seed=42,
                weighting_profile="uniform",
                validation_crops={},
            )


class TestLabeledDatasetDecodeFailures:
    """Ports of ablation/tests/test_lazy_dataset.py strict / skip-and-shift cases."""

    def _records(self):
        from ablation_locator import LabeledRecord

        return [
            LabeledRecord(track_id="bad", audio_path=Path("/nope/bad.mp3"), bpm=120.0),
            LabeledRecord(track_id="good", audio_path=Path("/nope/good.mp3"), bpm=140.0),
        ]

    def _dataset(self, feature_fixture, *, strict):
        from fixed_time.datasets import FixedTimeLabeledDataset

        return FixedTimeLabeledDataset(
            self._records(),
            feature_fixture,
            augment=False,
            seed=42,
            weighting_profile="uniform",
            strict=strict,
            validation_crops={"/nope/bad.mp3": 0, "/nope/good.mp3": 0},
        )

    def test_strict_raises_on_failed_decode(self, monkeypatch, feature_fixture):
        import fixed_time.datasets as fds

        monkeypatch.setattr(fds, "load_training_pcm", lambda _p: None)
        with pytest.raises(RuntimeError, match="strict eval"):
            self._dataset(feature_fixture, strict=True)[0]

    def test_nonstrict_skips_to_next_record_and_strict_does_not(self, monkeypatch, feature_fixture):
        import fixed_time.datasets as fds

        monkeypatch.setattr(
            fds,
            "deterministic_crop",
            lambda path, start, fixture: (
                None if "bad" in str(path) else np.zeros((128, 1200), np.float32)
            ),
        )
        x, label = self._dataset(feature_fixture, strict=False)[0]
        assert tuple(x.shape) == (1, 128, 1200)
        assert label == ft.bin_for(140.0)  # shifted onto the "good" record
        with pytest.raises(RuntimeError, match="strict eval"):
            self._dataset(feature_fixture, strict=True)[0]

    def test_all_failing_raises_runtimeerror(self, monkeypatch, feature_fixture):
        import fixed_time.datasets as fds

        monkeypatch.setattr(fds, "load_training_pcm", lambda _p: None)
        with pytest.raises(RuntimeError, match="All labeled tracks failed"):
            self._dataset(feature_fixture, strict=False)[0]


class _StubModel:
    """Returns fixed logits, one row per crop, regardless of the input."""

    def __init__(self, logits: np.ndarray):
        self.logits = logits

    def __call__(self, x):
        import torch

        return torch.from_numpy(self.logits[: x.shape[0]].astype(np.float32))


class TestScoreTrack:
    def _row(self):
        return {
            "trackId": "t1",
            "corpus": "giantsteps",
            "groundTruthBPM": 120.0,
            "audioSha256": "x",
            "audioPath": "/unused.wav",
        }

    def _score(self, monkeypatch, feature_fixture, audio, logits):
        import torch

        monkeypatch.setattr(sc, "decode_audio", lambda _p: audio)
        return sc.score_track(_StubModel(logits), self._row(), feature_fixture, torch.device("cpu"))

    def test_rhythmic_clip_keeps_ranked_crops(self, monkeypatch, feature_fixture):
        logits = np.zeros((4, 256))
        logits[0, 90] = 3.0  # 120 BPM
        logits[1:, 100] = 2.0  # 130 BPM
        audio = click_track(30.0)
        row, arrays = self._score(monkeypatch, feature_fixture, audio, logits)
        n_kept = len(row["keptCrops"])
        assert row["candidateCrops"] == len(arrays["starts"]) == len(arrays["scores"])
        assert 1 <= n_kept <= 4 and arrays["probs"].shape == (n_kept, 256)
        assert list(arrays["kept"]) == [k["startFrame"] for k in row["keptCrops"]]
        assert all(k["startSeconds"] == k["startFrame"] / 100.0 for k in row["keptCrops"])
        expected = np.exp(logits[:n_kept]) / np.exp(logits[:n_kept]).sum(axis=1, keepdims=True)
        assert row["variantBPM"] == 30.0 + int(np.argmax(expected.mean(axis=0)))
        assert row["inRuntimeRange"] is True and row["abstained"] is None

    def test_title_is_copied_when_present(self, monkeypatch, feature_fixture):
        import torch

        monkeypatch.setattr(sc, "decode_audio", lambda _p: click_track(10.0))
        row, _ = sc.score_track(
            _StubModel(np.zeros((1, 256))),
            {**self._row(), "corpus": "oa300", "title": "Song A"},
            feature_fixture,
            torch.device("cpu"),
        )
        assert row["title"] == "Song A"
        plain, _ = self._score(monkeypatch, feature_fixture, click_track(10.0), np.zeros((1, 256)))
        assert "title" not in plain

    def test_short_clip_abstains(self, monkeypatch, feature_fixture):
        row, arrays = self._score(
            monkeypatch, feature_fixture, click_track(10.0), np.zeros((1, 256))
        )
        assert row["candidateCrops"] == 0 and arrays["probs"].shape == (0, 256)
        assert row["variantBPM"] is None and row["abstained"] == ft.ABSTAIN_SHORT

    def test_silence_abstains_no_rhythmic_crop(self, monkeypatch, feature_fixture):
        row, _ = self._score(
            monkeypatch, feature_fixture, np.zeros(44_100 * 30, np.float32), np.zeros((1, 256))
        )
        assert row["candidateCrops"] == 4 and row["keptCrops"] == []
        assert row["variantBPM"] is None and row["abstained"] == ft.ABSTAIN_NO_RHYTHM

    def test_out_of_range_argmax_is_reported_raw(self, monkeypatch, feature_fixture):
        logits = np.zeros((4, 256))
        logits[:, 25] = 5.0  # 55 BPM, outside 60...200
        row, _ = self._score(monkeypatch, feature_fixture, click_track(30.0), logits)
        assert row["variantBPM"] == 55.0 and row["inRuntimeRange"] is False
        assert row["abstained"] is None
        assert rp.arm_result(row["variantBPM"], 120.0)["acc1"] is False


def _training_md(**overrides):
    md = {
        "trainingSecondsPerFrame": ft.SECONDS_PER_FRAME,
        "weightsSha256": "w" * 64,
        "modelIdentity": "fixed-time-crop1200-maskedMelPretrain-seed42",
        "recipe": dict(tr.RECIPE),
        "pcmSource": {"kind": "pcm-cache"},
        "cropPlan": {"sha256": "p" * 64, "keptSongs": {}, "skippedSongs": {}},
        "songsWithoutKeptCrop": {"pretrain": {"no-rhythmic-crop": 3}},
        "corpusDrift": tr.corpus_drift(
            {"corpusVersionHash": tr.LEGACY_CORPUS_VERSION_HASH},
            corpus_hash="7bc1" + "0" * 60,
            manifest_rows={"secondarySupervised": 2154, "unsupervisedPool": 2162},
        ),
    }
    md.update(overrides)
    return md


def _score_doc(**overrides):
    doc = {
        "inferenceSecondsPerFrame": ft.SECONDS_PER_FRAME,
        "weightsSha256": "w" * 64,
        "aggregatorSymbol": sc.AGGREGATOR_SYMBOL,
        "rankingRule": ft.ranking_rule(),
        "scoredInputs": {"giantstepsGroundTruth": "g" * 64, "bundleGateInput": "b" * 64},
        "cropProbabilitiesFile": "crops.npz",
        "codeGitSha": "abc",
    }
    doc.update(overrides)
    return doc


class TestBuildManifest:
    INPUTS = {
        "variantWeights": {"path": "model.pt", "sha256": "w" * 64},
        "cropPlan": {"path": "crop-plan.json", "sha256": "p" * 64},
        "giantstepsGroundTruth": {"path": "gt.json", "sha256": "g" * 64},
        "bundleGateInput": {"path": "bg.json", "sha256": "b" * 64},
    }

    def test_complete_manifest(self):
        m = rp.build_manifest(
            _training_md(),
            {"giantsteps": _score_doc(), "eval-12-7": _score_doc()},
            self.INPUTS,
            code_git_sha="deadbeef",
        )
        assert m["run_kind"] == "infrastructure-smoke"
        assert m["frontendSampleRateHz"] == 44_100
        assert "window" in m["stft"] and "padding" in m["stft"]
        assert m["stft"]["hopSamples"] == 441
        assert {"bands", "fMinHz", "fMaxHz", "order"} <= set(m["mel"])
        assert "population std" in m["normalization"]
        assert m["crop"]["frames"] == 1200
        assert m["crop"]["seconds"] == pytest.approx(12.0364, 1e-4)
        assert m["crop"]["hopFrames"] == 600 and "tail crop" in m["crop"]["tailCropRule"]
        assert m["tensorShape"] == [1, 1, 128, 1200]
        assert m["rhythmRanking"]["maxKeptCrops"] == 4
        assert "RhythmicRegionSelector" in m["rhythmRanking"]["scoreSource"]
        assert m["cropPlan"]["sha256"] == "p" * 64
        assert m["classSchema"]["bins"] == 256
        assert (m["classSchema"]["bpmMin"], m["classSchema"]["bpmMax"]) == (30, 285)
        assert m["modelIdentity"] and m["weightsSha256"] == "w" * 64
        assert m["trainingSecondsPerFrame"] == m["inferenceSecondsPerFrame"] == 0.01
        assert m["aggregator"]["name"] == "mean_of_softmax_ranked"
        assert m["inputs"] == self.INPUTS
        assert m["codeGitSha"]["report"] == "deadbeef"
        assert m["corpusDrift"]["matches"] is False
        assert any("1a697a5" in note for note in m["armDifferences"])
        assert any("crop choice" in note for note in m["armDifferences"])
        assert any("one fixed view per song" in note for note in m["armDifferences"])

    @pytest.mark.parametrize(
        "bad",
        [
            {"weightsSha256": "x" * 64},
            {"inferenceSecondsPerFrame": 0.02},
            {"aggregatorSymbol": "somewhere:median_of_argmax"},
            {"rankingRule": {**ft.ranking_rule(), "maxKeptCrops": 8}},
        ],
    )
    def test_refuses_mismatch(self, bad):
        with pytest.raises(rp.ReportRefusal):
            rp.build_manifest(
                _training_md(),
                {"giantsteps": _score_doc(), "eval-12-7": _score_doc(**bad)},
                self.INPUTS,
            )

    def test_refuses_labels_changed_since_scoring(self):
        inputs = {**self.INPUTS, "bundleGateInput": {"path": "bg.json", "sha256": "c" * 64}}
        with pytest.raises(rp.ReportRefusal, match="bundleGateInput sha256 at report time"):
            rp.build_manifest(
                _training_md(), {"giantsteps": _score_doc(), "eval-12-7": _score_doc()}, inputs
            )

    def test_refuses_scores_without_scoring_time_hashes(self):
        with pytest.raises(rp.ReportRefusal, match="does not record bundleGateInput"):
            rp.build_manifest(
                _training_md(),
                {"giantsteps": _score_doc(), "eval-12-7": _score_doc(scoredInputs={})},
                self.INPUTS,
            )

    def test_refuses_a_crop_plan_training_did_not_use(self):
        inputs = {**self.INPUTS, "cropPlan": {"path": "crop-plan.json", "sha256": "q" * 64}}
        with pytest.raises(rp.ReportRefusal, match="crop-plan.json"):
            rp.build_manifest(
                _training_md(), {"giantsteps": _score_doc(), "eval-12-7": _score_doc()}, inputs
            )


class TestReportRendering:
    def test_markdown_renders_without_rekordbox(self, monkeypatch):
        monkeypatch.setitem(rp.EXPECTED_COUNTS, "giantsteps", 4)
        monkeypatch.setitem(rp.EXPECTED_COUNTS, "eval-12-7", 4)
        monkeypatch.setitem(rp.EXPECTED_COUNTS, "oa300", 4)
        tracks = {
            "giantsteps": rp.join_arms(
                "giantsteps",
                {
                    "variant": _rows(4, hits=2),
                    "legacy": _rows(4, hits=1),
                    "tempoCnn": _rows(4, hits=3),
                },
            ),
            "eval-12-7": rp.join_arms(
                "eval-12-7", {"variant": _rows(4, hits=1), "legacy": _rows(4, hits=2)}
            ),
            "oa300": rp.join_arms(
                "oa300", {"variant": _rows(4, hits=3), "legacy": _rows(4, hits=1)}
            ),
        }
        pools = {src: set() for src in rp.POOL_SOURCES}
        report = {
            "runKind": rp.RUN_KIND,
            "variant": {
                "modelIdentity": "m",
                "weightsSha256": "w",
                "inputContract": ft.INPUT_CONTRACT,
                "aggregator": "mean_of_softmax_ranked",
            },
            "armDifferences": rp.arm_differences(_training_md()),
            "exposure": {
                c: {arm: rp.exposure({"t0000": "h"}, pools) for arm in ("variant", "legacy")}
                for c in rp.CORPORA
            },
            "summaries": {
                c: rp.summarize(
                    c,
                    tracks[c],
                    {
                        "t0003": {"abstained": ft.ABSTAIN_NO_RHYTHM, "inRuntimeRange": None},
                        "t0002": {"abstained": None, "inRuntimeRange": False},
                    },
                )
                for c in rp.CORPORA
            },
            "tracks": tracks,
        }
        md = rp.render_markdown(report)
        assert "## giantsteps (4 tracks)" in md and "## eval-12-7 (4 tracks)" in md
        oa300 = md.split("## oa300 (4 tracks)", 1)[1].split("## Inputs", 1)[0]
        assert "| fixed-time variant | 3/4 (75.0 %) |" in oa300
        assert "| legacy (512-column) | 1/4 (25.0 %) |" in oa300
        assert "| tempo-CNN | not-run | not-run |" in oa300
        assert "- variantMinusLegacy: +2 tracks" in oa300 and "McNemar p = " in oa300
        assert "Tracks where the variant and legacy disagree on Acc1 (2)" in oa300
        assert "| <100 |" in oa300 and "| octave-halving |" in oa300
        assert sum(f"| oa300 | {rp.ARM_LABEL[a]} |" in md for a in ("variant", "legacy")) == 2
        assert "AVFoundation" in md and "float16" in md and "byte-identical" in md
        assert "label-free pool" not in md and "same pool" not in md
        assert "crop choice" in md and "no-rhythmic-crop 1" in md
        assert "exact two-sided McNemar p = " in md
        assert "labelled-training overlap" in md and "same draws in every epoch" in md
        assert "outside 60 to 200 (reported raw, as legacy rows are): 1" in md
        assert "rekordbox" not in md.lower()

    def test_refused_report_writes_nothing(self, tmp_path):
        assert rp.main(["--run-dir", str(tmp_path)]) == 3
        assert list(tmp_path.iterdir()) == []


# ---------------------------------------------------------------------------
# The per-epoch callback, through the reused loops
# ---------------------------------------------------------------------------
# Module-level so DataLoader worker processes (spawn) can unpickle them.


class EpochStampedSet:
    """Items are constant tensors equal to (dataset epoch + 1), so a batch tells
    which epoch the worker's copy of the dataset was at."""

    def __init__(self, records=None, fixture=None, *, labelled=True, frames=1200, **_kwargs):
        self._n = 4
        self._labelled = labelled
        self._frames = frames
        self._epoch = 0

    def set_epoch(self, epoch: int) -> None:
        self._epoch = int(epoch)

    def __len__(self) -> int:
        return self._n

    def __getitem__(self, i):
        import torch

        x = torch.full((1, 128, self._frames), float(self._epoch + 1))
        return (x, 90) if self._labelled else x


class _Stamp:
    """Records max(x) - 1 for every batch seen while in training mode."""

    def __init__(self):
        self.seen: list[int] = []

    def __call__(self, x, training: bool):
        if training:
            self.seen.append(int(round(float(x.max()))) - 1)


def _tiny_model(stamp: _Stamp):
    import torch
    import torch.nn as nn

    class Rec(nn.Module):
        def forward(self, x):
            stamp(x, self.training)
            return x

    class Tiny(nn.Module):
        def __init__(self):
            super().__init__()
            self.block1 = Rec()
            self.pool1 = nn.Identity()
            self.block2 = nn.Identity()
            self.pool2 = nn.Identity()
            self.block3 = nn.Conv2d(1, 96, 1)
            self.fc = nn.Linear(1, 256)

        def forward(self, x):
            x = self.block1(x)
            return self.fc(x.mean(dim=(1, 2, 3)).unsqueeze(1))

    torch.manual_seed(0)
    return Tiny()


class TestEpochCallbackThroughLoops:
    def test_finetune_batches_see_epochs_in_order(self):
        import torch
        from ablation_train import finetune

        stamp = _Stamp()
        built: list = []

        def factory(*args, **kwargs):
            d = EpochStampedSet(*args, **kwargs)
            built.append(d)
            return d

        def on_epoch(epoch):
            for d in built:
                d.set_epoch(epoch)

        records = [object()] * 4
        finetune(
            _tiny_model(stamp),
            epochs=3,
            batch_size=2,
            lr=1e-3,
            seed=42,
            weighting_profile="uniform",
            subset=None,
            device=torch.device("cpu"),
            num_workers=1,
            train_records=records,
            val_records=records,
            feature_path="fixed-time",
            dataset_factory=factory,
            on_epoch_start=on_epoch,
        )
        assert stamp.seen == [0, 0, 1, 1, 2, 2]

    def test_pretrain_batches_see_epochs_in_order(self):
        import torch

        import masked_mel
        from torch.utils.data import DataLoader

        stamp = _Stamp()
        data = EpochStampedSet(labelled=False)
        loader = DataLoader(data, batch_size=2, shuffle=False, num_workers=1)
        masked_mel.pretrain_encoder(
            _tiny_model(stamp),
            loader,
            epochs=3,
            device=torch.device("cpu"),
            seed=42,
            target_frames=1200,
            on_epoch_start=data.set_epoch,
        )
        assert stamp.seen == [0, 0, 1, 1, 2, 2]

    def test_train_wires_set_epoch_to_both_datasets(self, monkeypatch, feature_fixture):
        import ablation_locator
        import ablation_train
        import masked_mel
        from ablation_locator import LabeledRecord

        labels = {
            "train": [LabeledRecord("b", Path("/b.mp3"), 128.0)],
            "val": [LabeledRecord("c", Path("/c.mp3"), 140.0)],
        }
        monkeypatch.setattr(ablation_locator, "build_labeled_records", lambda w: labels[w])
        recipe = {"seed": 42, "pretrainEpochs": 30, "epochCount": 60}
        plan = cp.build_plan(_lists(), _rankings(), recipe)
        seen: dict = {}

        def fake_pretrain(model, loader, **kw):
            seen["target_frames"] = kw["target_frames"]
            kw["on_epoch_start"](7)
            seen["pretrain_epoch"] = loader.dataset._epoch

        def fake_finetune(model, **kw):
            train_set = kw["dataset_factory"](
                kw["train_records"],
                feature_fixture,
                augment=True,
                seed=42,
                weighting_profile="uniform",
                feature_path="fixed-time",
            )
            val_set = kw["dataset_factory"](
                kw["val_records"],
                feature_fixture,
                augment=False,
                seed=42,
                weighting_profile="uniform",
                strict=True,
                feature_path="fixed-time",
            )
            kw["on_epoch_start"](5)
            seen["finetune_epochs"] = (train_set._epoch, val_set._epoch)
            seen["train_crop"] = train_set.crop_start(0)
            seen["val_crop"] = val_set.crop_start(0)
            return ablation_train.FinetuneResult(0.0, 0.0, 0, [])

        monkeypatch.setattr(masked_mel, "pretrain_encoder", fake_pretrain)
        monkeypatch.setattr(ablation_train, "finetune", fake_finetune)
        tr.train(
            crop_plan=plan,
            out_dir=Path("/nonexistent"),
            subset=1,
            pretrain_epochs=1,
            epochs=1,
            num_workers=0,
            write_artifacts=False,
        )
        assert seen["target_frames"] == 1200 and seen["pretrain_epoch"] == 7
        assert seen["finetune_epochs"] == (5, 5)
        assert seen["train_crop"] == plan["songs"]["train"][0]["schedule"][5]
        assert seen["val_crop"] == 1800


# ---------------------------------------------------------------------------
# Checkpoint and resume
# ---------------------------------------------------------------------------


class IndexedSet:
    """Distinct items per index, so shuffle and sampler order change the result."""

    def __init__(self, records=None, fixture=None, *, labelled=True, frames=40, **_kwargs):
        self._labelled = labelled
        self._frames = frames
        self._n = 8

    def set_epoch(self, epoch: int) -> None:
        pass

    def __len__(self) -> int:
        return self._n

    def __getitem__(self, i):
        import torch

        g = torch.Generator().manual_seed(1000 + i)
        x = torch.randn((1, 128, self._frames), generator=g)
        return (x, 60 + 10 * i) if self._labelled else x


class _Rec:
    def __init__(self, bpm):
        self.bpm = bpm


def _resume_model():
    """Tiny model with dropout in both phases, so the torch RNG matters."""
    import torch.nn as nn

    class Tiny(nn.Module):
        def __init__(self):
            super().__init__()
            self.block1 = nn.Conv2d(1, 4, 1)
            self.pool1 = nn.Identity()
            self.block2 = nn.Dropout(0.2)
            self.pool2 = nn.Identity()
            self.block3 = nn.Conv2d(4, 96, 1)
            self.head = nn.Sequential(nn.Linear(4, 16), nn.Dropout(0.3), nn.Linear(16, 256))

        def forward(self, x):
            return self.head(self.block1(x).mean(dim=(2, 3)))

    return Tiny()


def _fresh(seed: int = 0):
    import torch

    torch.manual_seed(seed)
    random.seed(seed)
    np.random.seed(seed)
    return _resume_model()


class _Crash(RuntimeError):
    pass


def _crash_at(epoch_to_crash: int):
    def cb(epoch):
        if epoch == epoch_to_crash:
            raise _Crash(f"simulated crash at epoch {epoch}")

    return cb


def _weights(model):
    return {k: v.detach().clone() for k, v in model.state_dict().items()}


def _assert_same_weights(a, b):
    import torch

    assert a.keys() == b.keys()
    for k in a:
        assert torch.equal(a[k], b[k]), k


class TestCheckpointResume:
    RECIPE = {"seed": 42, "epochs": 3}

    def _store(self, path, sha="p" * 64):
        from fixed_time.checkpoints import CheckpointStore

        return CheckpointStore(path, plan_sha256=sha, recipe=self.RECIPE)

    def _pretrain(self, model, store, on_epoch_start=None):
        import torch
        from torch.utils.data import DataLoader

        import masked_mel
        from fixed_time.checkpoints import Resumer

        resumer = Resumer(store, model, pretrain_epochs=3)
        resumer.load()
        g = torch.Generator()
        g.manual_seed(42)
        loader = DataLoader(
            IndexedSet(labelled=False), batch_size=2, shuffle=True, num_workers=0, generator=g
        )
        masked_mel.pretrain_encoder(
            model,
            loader,
            epochs=3,
            device=torch.device("cpu"),
            seed=42,
            target_frames=40,
            **resumer.pretrain_hooks(g, on_epoch_start=on_epoch_start),
        )
        return resumer

    def test_pretraining_resume_matches_an_uninterrupted_run(self, tmp_path):
        straight_model = _fresh()
        straight = self._pretrain(straight_model, self._store(tmp_path / "a"))

        store = self._store(tmp_path / "b")
        with pytest.raises(_Crash):
            self._pretrain(_fresh(), store, on_epoch_start=_crash_at(2))
        assert store.load("pretrain-latest")["completedEpoch"] == 1
        assert store.load("pretrain-final") is None

        resumed_model = _fresh(seed=999)  # other weights and RNG: the checkpoint must win
        resumed = self._pretrain(resumed_model, store)
        assert resumed.resumed_from == {
            "checkpoint": "checkpoints/pretrain-latest.pt",
            "phase": "pretrain",
            "completedEpoch": 1,
        }
        assert resumed.pretrain_losses == straight.pretrain_losses
        assert len(resumed.pretrain_losses) == 3
        _assert_same_weights(_weights(resumed_model), _weights(straight_model))
        assert store.load("pretrain-final")["completedEpoch"] == 2

    def _finetune(self, model, store, on_epoch_start=None):
        import torch

        from ablation_train import finetune
        from fixed_time.checkpoints import Resumer

        resumer = Resumer(store, model, pretrain_epochs=3)
        resumer.load()
        records = [_Rec(bpm) for bpm in (90, 128, 128, 140, 150, 165, 170, 174)]
        result = finetune(
            model,
            epochs=3,
            batch_size=2,
            lr=1e-3,
            seed=42,
            weighting_profile="uniform",
            subset=None,
            device=torch.device("cpu"),
            octave_mass=0.15,
            label_smoothing=0.1,
            num_workers=0,
            train_records=records,
            val_records=records,
            feature_path="fixed-time",
            rebalance=True,
            dataset_factory=IndexedSet,
            **resumer.finetune_hooks(on_epoch_start=on_epoch_start),
        )
        return resumer, result

    def test_finetuning_resume_matches_an_uninterrupted_run(self, tmp_path):
        straight_model = _fresh()
        straight, straight_result = self._finetune(straight_model, self._store(tmp_path / "a"))

        store = self._store(tmp_path / "b")
        with pytest.raises(_Crash):
            self._finetune(_fresh(), store, on_epoch_start=_crash_at(2))
        assert store.load("finetune-latest")["completedEpoch"] == 1

        resumed_model = _fresh(seed=999)
        resumed, resumed_result = self._finetune(resumed_model, store)
        assert resumed.resumed_from["checkpoint"] == "checkpoints/finetune-latest.pt"
        assert resumed.finetune_losses == straight.finetune_losses
        assert len(resumed.finetune_losses) == 3
        assert resumed_result.per_epoch == straight_result.per_epoch
        assert resumed_result.best_val_acc1 == straight_result.best_val_acc1
        _assert_same_weights(_weights(resumed_model), _weights(straight_model))

    def test_resume_prefers_the_most_advanced_checkpoint(self, tmp_path):
        store = self._store(tmp_path)
        model = _resume_model()
        for name, phase, epoch in (
            ("pretrain-latest", "pretrain", 2),
            ("pretrain-final", "pretrain", 2),
        ):
            store.save(
                name,
                {"phase": phase, "completedEpoch": epoch, "model": model.state_dict(), "rng": {}},
            )
        assert store.resume_point()[0] == "pretrain-final"

    def test_plan_sha_mismatch_refuses(self, tmp_path):
        from fixed_time.checkpoints import CheckpointMismatch

        self._store(tmp_path, sha="a" * 64).save("pretrain-latest", {"phase": "pretrain"})
        with pytest.raises(CheckpointMismatch, match="crop-plan sha256"):
            self._store(tmp_path, sha="b" * 64).resume_point()

    def test_recipe_mismatch_refuses(self, tmp_path):
        from fixed_time.checkpoints import CheckpointMismatch, CheckpointStore

        self._store(tmp_path).save("finetune-latest", {"phase": "finetune"})
        other = CheckpointStore(tmp_path, plan_sha256="p" * 64, recipe={"seed": 43, "epochs": 3})
        with pytest.raises(CheckpointMismatch, match="recipe"):
            other.resume_point()

    def test_full_run_refuses_a_checkpoint_from_another_plan(self, tmp_path, monkeypatch):
        from fixed_time.checkpoints import CheckpointStore

        CheckpointStore(tmp_path, plan_sha256="a" * 64, recipe=tr.RECIPE).save(
            "pretrain-latest", {"phase": "pretrain"}
        )
        monkeypatch.setattr(tr, "run_guard", lambda _p: {"corpusDrift": None})
        monkeypatch.setattr(tr, "read_plan", lambda _d: ({}, "b" * 64))
        monkeypatch.setattr(tr, "train", lambda **_kw: pytest.fail("must not train"))
        assert tr.full_run(tmp_path, 0, tmp_path / "legacy.json", False) == 3
        assert (tmp_path / "checkpoints" / "pretrain-latest.pt").is_file()

    def test_overwrite_clears_checkpoints_and_starts_fresh(self, tmp_path, monkeypatch):
        from fixed_time.checkpoints import CheckpointStore

        CheckpointStore(tmp_path, plan_sha256="a" * 64, recipe=tr.RECIPE).save(
            "pretrain-latest", {"phase": "pretrain"}
        )
        seen = {}
        monkeypatch.setattr(tr, "run_guard", lambda _p: {"corpusDrift": None})
        monkeypatch.setattr(tr, "read_plan", lambda _d: ({}, "b" * 64))

        def fake_train(**kw):
            seen["store"] = kw["checkpoints"]
            seen["left"] = list((tmp_path / "checkpoints").glob("*.pt"))
            return {}

        monkeypatch.setattr(tr, "train", fake_train)
        monkeypatch.setattr(tr, "write_run_artifacts", lambda *a, **k: None)
        monkeypatch.setattr(tr, "plan_summary", lambda *a, **k: {})
        assert tr.full_run(tmp_path, 0, tmp_path / "legacy.json", True) == 0
        assert seen["left"] == [] and seen["store"].plan_sha256 == "b" * 64

    def test_checkpoint_write_is_atomic(self, tmp_path):
        store = self._store(tmp_path)
        store.save("pretrain-latest", {"phase": "pretrain", "completedEpoch": 0})
        store.save("pretrain-latest", {"phase": "pretrain", "completedEpoch": 1})
        names = sorted(p.name for p in (tmp_path / "checkpoints").iterdir())
        assert names == ["pretrain-latest.pt"]
        assert store.load("pretrain-latest")["completedEpoch"] == 1
