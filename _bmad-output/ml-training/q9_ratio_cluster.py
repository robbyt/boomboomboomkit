"""
Q9 (Epic 12 PRD, section 14) — ratio-cluster aggregate generator (develop-only).

Reads the gitignored `non-rekordbox-survey.json` and emits
`q9-ratio-cluster-v1.json`, the tracked evidence artifact behind
`q9-ratio-cluster-2026-08-01.md`.

Why an aggregate rather than the survey itself: the survey carries track
filenames and an absolute audio root for a private collection, so it cannot be
committed. The artifact's original acceptance criterion promised
repository-only reproducibility, which was never achievable. This delivers
something weaker and states it plainly:

  - repository-only readers get AUDITABILITY. They can read this generator,
    confirm the prose agrees with the committed aggregate, and check the
    reconciliation identities. They CANNOT recompute a count from source
    observations, detect an altered or omitted survey row, or validate either
    BPM signal.
  - the operator gets REPRODUCTION, via `--check` against the private survey.

`survey_sha256` lets the operator prove later which private snapshot a number
came from. It proves nothing to anyone without the survey.

Every number is a count over two fallible signals. Neither the file tag nor our
own detector is ground truth, and FR-59a.1 forbids treating the detector as
such. Nothing here labels a track.

Run: `make q9-ratio-cluster`   (or `uv run python q9_ratio_cluster.py`)
Verify: `uv run python q9_ratio_cluster.py --check`
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import statistics
import sys
from typing import Any

GENERATOR_VERSION = "q9-ratio-cluster/1.0.0"
SCHEMA_VERSION = 1

HERE = os.path.dirname(os.path.abspath(__file__))
SURVEY = os.path.join(HERE, "non-rekordbox-survey.json")
OUTPUT = os.path.join(HERE, "q9-ratio-cluster-v1.json")

EXPECTED_SURVEY_SCHEMA = 1

# Exit codes: 0 ok, 1 drift, 2 missing input, 3 invariant/privacy failure.
EXIT_DRIFT = 1
EXIT_MISSING_INPUT = 2
EXIT_INVARIANT = 3

BIN_WIDTH_OCTAVES = 0.05
# The prose publishes only bins at or above this count. Sparse bins are
# aggregated rather than enumerated: emitting them would disclose more than the
# artifact does (release rule, operator decision 2026-08-01).
MIN_PUBLISHED_BIN = 10

# Half-open [lo, hi). Asserted mutually exclusive below.
CLASS_WINDOWS = {
    "1x": (0.97, 1.03),
    "1.33x": (1.30, 1.36),
    "1.5x": (1.48, 1.52),
    "2x": (1.94, 2.06),
}
CLASS_ORDER = ["1x", "1.33x", "1.5x", "2x", "other"]

BANDS = [
    ("<100", 0.0, 100.0),
    ("100-120", 100.0, 120.0),
    ("120-140", 120.0, 140.0),
    ("140-160", 140.0, 160.0),
    ("160-175", 160.0, 175.0),
    ("175+", 175.0, float("inf")),
]
BAND_ORDER = [b[0] for b in BANDS]

# Sensitivity windows for the 1.5x count. No window is privileged; the spread
# across them is itself a reported result.
SENSITIVITY_WINDOWS = [(1.40, 1.60), (1.45, 1.55), (1.48, 1.52), (1.49, 1.51)]

# The trough between the 1.33x and 1.5x modes. NOT [1.30, 1.45): that interval
# is 86/91 the 1.33x peak itself, and calling it a shoulder smeared a real mode
# across a wide window (review finding, 2026-08-01).
GAP_WINDOW = (1.36, 1.45)

DETECTOR_WINDOW = (165.0, 180.0)
MIRROR_WINDOW = (108.0, 125.0)

# `AccuracyFloorTests` fixture. Its metadata is stripped, so it carries no tag
# and no ratio: analogous to the 1.33x class, not a member of it.
FIXTURE_TRUE_BPM = 174.0
FIXTURE_REPORTED_BPM = 115.6


class InvariantError(Exception):
    """A reconciliation, exclusivity, or privacy invariant did not hold."""


def _finite_positive(value: object) -> bool:
    """Accept only a finite, strictly positive real. Rejects bool explicitly:
    `isinstance(True, int)` is True in Python and would silently pass as 1.0."""
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return False
    return math.isfinite(value) and value > 0


def _bin_index(ratio: float) -> int:
    """Constant-width log2 bin. `floor(x/w + 0.5)` and not `round`, which is
    ties-to-even and would put an exact bin boundary in a neighbour."""
    return math.floor(math.log2(ratio) / BIN_WIDTH_OCTAVES + 0.5)


def _classify(ratio: float) -> str:
    for name in CLASS_ORDER[:-1]:
        lo, hi = CLASS_WINDOWS[name]
        if lo <= ratio < hi:
            return name
    return "other"


def _band(bpm: float) -> str:
    for name, lo, hi in BANDS:
        if lo <= bpm < hi:
            return name
    raise InvariantError(f"BPM {bpm} fell outside every band")


def _pct(sorted_values: list[float], fraction: float) -> float:
    """Index-based percentile, floor, no interpolation. p05 = v[n//20],
    p95 = v[19n//20]. Documented so a second implementation matches."""
    idx = min(int(len(sorted_values) * fraction), len(sorted_values) - 1)
    return sorted_values[idx]


def _density_per_octave(count: int, lo: float, hi: float) -> float:
    return count / (math.log2(hi) - math.log2(lo))


def _assert_windows_exclusive() -> None:
    names = CLASS_ORDER[:-1]
    for i, a in enumerate(names):
        alo, ahi = CLASS_WINDOWS[a]
        if not alo < ahi:
            raise InvariantError(f"class {a} window is empty or inverted")
        for b in names[i + 1 :]:
            blo, bhi = CLASS_WINDOWS[b]
            if alo < bhi and blo < ahi:
                raise InvariantError(f"class windows {a} and {b} overlap")


def load_survey(path: str) -> dict:
    if not os.path.exists(path):
        sys.stderr.write(
            f"Error: survey not found at {path}.\n"
            "It is gitignored and develop-only. Regenerate with "
            "`make non-rekordbox-survey` (requires the operator's Rekordbox "
            "XML and audio collection).\n"
        )
        raise SystemExit(EXIT_MISSING_INPUT)
    with open(path, "rb") as handle:
        raw = handle.read()
    data = json.loads(raw.decode("utf-8"))
    if data.get("schema_version") != EXPECTED_SURVEY_SCHEMA:
        raise InvariantError(
            f"survey schema_version is {data.get('schema_version')!r}, "
            f"expected {EXPECTED_SURVEY_SCHEMA}"
        )
    if not isinstance(data.get("tracks"), list):
        raise InvariantError("survey has no `tracks` list")
    data["_sha256"] = hashlib.sha256(raw).hexdigest()
    return data


def build(data: dict) -> dict:
    _assert_windows_exclusive()
    tracks = data["tracks"]

    paired: list[tuple[float, dict]] = []
    dsp_only = tag_only = neither = 0
    for track in tracks:
        tag_ok = _finite_positive(track.get("fileMetadataBPM"))
        dsp_ok = _finite_positive(track.get("dspBPM"))
        if tag_ok and dsp_ok:
            paired.append((track["dspBPM"] / track["fileMetadataBPM"], track))
        elif dsp_ok:
            dsp_only += 1
        elif tag_ok:
            tag_only += 1
        else:
            neither += 1

    if len(paired) + dsp_only + tag_only + neither != len(tracks):
        raise InvariantError("reconciliation does not sum to the track total")

    # --- histogram, published bins only -------------------------------------
    raw_bins: dict[int, int] = {}
    for ratio, _ in paired:
        raw_bins[_bin_index(ratio)] = raw_bins.get(_bin_index(ratio), 0) + 1
    published = sorted(b for b, n in raw_bins.items() if n >= MIN_PUBLISHED_BIN)
    suppressed = [b for b, n in raw_bins.items() if n < MIN_PUBLISHED_BIN]
    histogram = {
        "bin_width_octaves": BIN_WIDTH_OCTAVES,
        "rounding_rule": (
            "index = floor(log2(ratio) divided by bin_width_octaves, plus 0.5). "
            "Deliberately not Python round(), which is ties-to-even."
        ),
        "min_published_count": MIN_PUBLISHED_BIN,
        "bins": [
            {
                "log2_center": round(b * BIN_WIDTH_OCTAVES, 2),
                "ratio_center": round(2 ** (b * BIN_WIDTH_OCTAVES), 3),
                "count": raw_bins[b],
            }
            for b in published
        ],
        "suppressed_bin_count": len(suppressed),
        "suppressed_track_total": sum(raw_bins[b] for b in suppressed),
    }

    # --- window sensitivity + the trough ------------------------------------
    sensitivity: list[dict[str, object]] = []
    counts: list[int] = []
    for lo, hi in SENSITIVITY_WINDOWS:
        n = sum(1 for r, _ in paired if lo <= r < hi)
        counts.append(n)
        sensitivity.append(
            {
                "window": [lo, hi],
                "count": n,
                "density_per_octave": round(_density_per_octave(n, lo, hi)),
            }
        )
    spread_pct = round((max(counts) - min(counts)) / max(counts) * 100, 1)

    gap_lo, gap_hi = GAP_WINDOW
    gap_n = sum(1 for r, _ in paired if gap_lo <= r < gap_hi)
    rejected_lo, rejected_hi = 1.30, 1.45
    rejected_n = sum(1 for r, _ in paired if rejected_lo <= r < rejected_hi)
    c133_lo, c133_hi = CLASS_WINDOWS["1.33x"]
    c133_n = sum(1 for r, _ in paired if c133_lo <= r < c133_hi)

    # --- per-class profiles --------------------------------------------------
    grouped: dict[str, list[dict]] = {name: [] for name in CLASS_ORDER}
    for ratio, track in paired:
        grouped[_classify(ratio)].append(track)
    if sum(len(v) for v in grouped.values()) != len(paired):
        raise InvariantError("class assignment is not exhaustive")

    classes = {}
    for name in CLASS_ORDER:
        rows = grouped[name]
        if not rows:
            continue
        confs = [r["dspConfidence"] for r in rows if _finite_positive(r.get("dspConfidence"))]
        entry = {
            "count": len(rows),
            "tag_bpm_median": round(statistics.median(r["fileMetadataBPM"] for r in rows), 1),
            "dsp_bpm_median": round(statistics.median(r["dspBPM"] for r in rows), 1),
        }
        if name in CLASS_WINDOWS:
            entry["window"] = list(CLASS_WINDOWS[name])
        if confs:
            entry["dsp_confidence_median"] = round(statistics.median(confs), 3)
        classes[name] = entry

    # --- band decomposition --------------------------------------------------
    bands: dict[str, dict[str, int]] = {name: {c: 0 for c in CLASS_ORDER} for name in BAND_ORDER}
    for ratio, track in paired:
        bands[_band(track["fileMetadataBPM"])][_classify(ratio)] += 1
    band_out = {}
    grand = 0
    for name in BAND_ORDER:
        row = bands[name]
        total = sum(row.values())
        grand += total
        band_out[name] = dict(row, total=total)
    if grand != len(paired):
        raise InvariantError("band cells do not reconcile to the paired total")

    # --- the largest directory ----------------------------------------------
    # "Largest" = the immediate parent directory basename holding the most rows
    # carrying a DSP estimate; ties broken by name. Grouping by first path
    # component instead yields a different population, so this is pinned.
    dir_counts: dict[str, int] = {}
    for track in tracks:
        if not _finite_positive(track.get("dspBPM")):
            continue
        key = os.path.basename(os.path.dirname(track["path"]))
        dir_counts[key] = dir_counts.get(key, 0) + 1
    largest = sorted(dir_counts.items(), key=lambda kv: (-kv[1], kv[0]))[0][0]

    dir_rows = [
        t
        for t in tracks
        if _finite_positive(t.get("dspBPM"))
        and os.path.basename(os.path.dirname(t["path"])) == largest
    ]
    dlo, dhi = DETECTOR_WINDOW
    in_window = [t for t in dir_rows if dlo <= t["dspBPM"] < dhi]
    mlo, mhi = MIRROR_WINDOW
    mirror_rows = [t for t in dir_rows if mlo <= t["dspBPM"] < mhi]

    tag_split: dict[str, int] = {"<100": 0, "100-120": 0, "120-160": 0, "160-180": 0}
    tagged_in_window = [t for t in in_window if _finite_positive(t.get("fileMetadataBPM"))]
    for track in tagged_in_window:
        bpm = track["fileMetadataBPM"]
        if bpm < 100:
            tag_split["<100"] += 1
        elif bpm < 120:
            tag_split["100-120"] += 1
        elif bpm < 160:
            tag_split["120-160"] += 1
        else:
            tag_split["160-180"] += 1
    n_split = len(tagged_in_window)

    # Directory concentration of the 1.5x class. The name is never emitted.
    c15 = grouped["1.5x"]
    c15_dirs: dict[str, int] = {}
    for track in c15:
        key = os.path.basename(os.path.dirname(track["path"]))
        c15_dirs[key] = c15_dirs.get(key, 0) + 1
    top_dir_share = max(c15_dirs.values())

    largest_directory = {
        "note": (
            "Directory name is deliberately not emitted. Definition: immediate "
            "parent basename with the most DSP-bearing rows, ties by name."
        ),
        "rows_with_dsp": len(dir_rows),
        "detector_window": list(DETECTOR_WINDOW),
        "rows_in_detector_window": len(in_window),
        "base_rate_percent": round(len(in_window) / len(dir_rows) * 100, 1),
        "mirror_window": list(MIRROR_WINDOW),
        "rows_in_mirror_window": len(mirror_rows),
        "tagged_rows_in_detector_window": n_split,
        "tag_split": tag_split,
        "tag_split_percent": {k: round(v / n_split * 100, 1) for k, v in tag_split.items()},
    }

    # --- 1.5x cluster detail -------------------------------------------------
    band_1_5x = [
        t for r, t in paired if _classify(r) == "1.5x" and 100 <= t["fileMetadataBPM"] < 120
    ]
    spread = sorted(t["dspBPM"] for t in band_1_5x)
    quantized = sum(1 for t in c15 if round(t["fileMetadataBPM"]) in (113, 115, 116, 117))
    band_100_120 = band_out["100-120"]
    cluster_detail = {
        "count": len(c15),
        "top_directory_share": top_dir_share,
        "top_directory_percent": round(top_dir_share / len(c15) * 100, 0),
        "tag_quantized_to_four_integers": quantized,
        "tag_integers": [113, 115, 116, 117],
        "in_100_120_band": len(band_1_5x),
        "share_of_100_120_band": round(len(band_1_5x) / band_100_120["total"] * 100, 1),
        "dsp_bpm_spread": {
            "min": round(spread[0], 1),
            "p05": round(_pct(spread, 0.05), 1),
            "median": round(statistics.median(spread), 1),
            "p95": round(_pct(spread, 0.95), 1),
            "max": round(spread[-1], 1),
        },
    }

    # --- circular-evidence reconciliation ------------------------------------
    # `tier` is a deterministic function of `agreementAfterOctaveNormalization`,
    # which is why both are excluded as evidence in the artifact. Emitted so a
    # reader can confirm the collinearity rather than take it on trust.
    tier_agreement: dict[str, int] = {}
    for _, track in paired:
        key = f"{track.get('tier')}|{bool(track.get('agreementAfterOctaveNormalization'))}"
        tier_agreement[key] = tier_agreement.get(key, 0) + 1
    if len(tier_agreement) != 2:
        raise InvariantError(
            "tier/agreement cross-tab is no longer 2 cells; the collinearity "
            "claim in the artifact must be re-derived"
        )

    # --- 140-160 non-1x count ------------------------------------------------
    band_140_160 = band_out["140-160"]
    non_1x_140_160 = band_140_160["total"] - band_140_160["1x"]

    # --- budgeting scenario --------------------------------------------------
    clean_100_120 = band_100_120["total"] - band_100_120["1.5x"]
    keeper_rate = clean_100_120 / band_100_120["total"]
    reviews_for_43 = math.ceil(43 / keeper_rate)

    result = {
        "schema_version": SCHEMA_VERSION,
        "generator_version": GENERATOR_VERSION,
        "survey_sha256": data["_sha256"],
        "epistemic_status": (
            "Counts over two fallible signals. Neither the file tag nor the "
            "detector is ground truth; FR-59a.1 forbids treating the detector "
            "as such. No track is labelled here."
        ),
        "reconciliation": {
            "tracks_total": len(tracks),
            "paired": len(paired),
            "dsp_only": dsp_only,
            "tag_only": tag_only,
            "neither": neither,
        },
        "histogram": histogram,
        "window_sensitivity": {
            "windows": sensitivity,
            "spread_percent": spread_pct,
            "note": "No window is privileged. The spread is itself a result.",
        },
        "modes": {
            "gap_between_1_33x_and_1_5x": {
                "window": list(GAP_WINDOW),
                "count": gap_n,
                "density_per_octave": round(_density_per_octave(gap_n, gap_lo, gap_hi)),
            },
            "rejected_shoulder_1_30_1_45": {
                "window": [rejected_lo, rejected_hi],
                "count": rejected_n,
                "of_which_1_33x_core": c133_n,
                "note": (
                    "Retained to show why this interval is not a shoulder: it is "
                    "mostly the 1.33x mode itself."
                ),
            },
            "core_1_5x_density_per_octave": round(
                _density_per_octave(classes["1.5x"]["count"], *CLASS_WINDOWS["1.5x"]),
                1,
            ),
        },
        "classes": classes,
        "bands": band_out,
        "band_140_160_non_1x": non_1x_140_160,
        "band_100_120_after_removing_1_5x": clean_100_120,
        "budget_scenario": {
            "keeper_rate": round(keeper_rate, 4),
            "target_per_band": 43,
            "expected_reviews_for_target": reviews_for_43,
            "note": (
                "Presumes the tagging-convention hypothesis and a naive random "
                "draw. A budgeting scenario, not a measured rejection rate."
            ),
        },
        "largest_directory": largest_directory,
        "cluster_1_5x": cluster_detail,
        "tier_agreement_crosstab": tier_agreement,
        "fixture_reference": {
            "note": (
                "AccuracyFloorTests fixture. Metadata stripped, so it carries no "
                "tag and no ratio: analogous to the 1.33x class, not a member."
            ),
            "true_bpm": FIXTURE_TRUE_BPM,
            "reported_bpm": FIXTURE_REPORTED_BPM,
            "reported_over_true": round(FIXTURE_REPORTED_BPM / FIXTURE_TRUE_BPM, 4),
        },
        "derived": {
            "two_thirds_of_2x_class_dsp_median": round(classes["2x"]["dsp_bpm_median"] * 2 / 3, 1),
        },
    }
    result["claims"] = _claim_manifest()
    _validate_claims(result)
    return result


def _claim_manifest() -> dict[str, str]:
    """Stable claim id -> JSON pointer. Every empirical figure the prose
    publishes must resolve here. Catches newly added figures; it cannot prove a
    figure is attached to the right claim, and no cheap check can."""
    return {
        "q9.paired": "/reconciliation/paired",
        "q9.tracks_total": "/reconciliation/tracks_total",
        "q9.dsp_only": "/reconciliation/dsp_only",
        "q9.neither": "/reconciliation/neither",
        "q9.histogram": "/histogram/bins",
        "q9.window_spread": "/window_sensitivity/spread_percent",
        "q9.gap": "/modes/gap_between_1_33x_and_1_5x/count",
        "q9.gap_density": "/modes/gap_between_1_33x_and_1_5x/density_per_octave",
        "q9.rejected_shoulder": "/modes/rejected_shoulder_1_30_1_45/count",
        "q9.rejected_shoulder_core": ("/modes/rejected_shoulder_1_30_1_45/of_which_1_33x_core"),
        "q9.core_density": "/modes/core_1_5x_density_per_octave",
        "q9.class_1x": "/classes/1x",
        "q9.class_1_33x": "/classes/1.33x",
        "q9.class_1_5x": "/classes/1.5x",
        "q9.class_2x": "/classes/2x",
        "q9.class_other": "/classes/other",
        "q9.bands": "/bands",
        "q9.band_100_120_clean": "/band_100_120_after_removing_1_5x",
        "q9.band_140_160_non_1x": "/band_140_160_non_1x",
        "q9.base_rate": "/largest_directory/base_rate_percent",
        "q9.mirror_rows": "/largest_directory/rows_in_mirror_window",
        "q9.tag_split": "/largest_directory/tag_split_percent",
        "q9.tagged_in_window": "/largest_directory/tagged_rows_in_detector_window",
        "q9.cluster_concentration": "/cluster_1_5x/top_directory_percent",
        "q9.cluster_quantized": "/cluster_1_5x/tag_quantized_to_four_integers",
        "q9.cluster_band_share": "/cluster_1_5x/share_of_100_120_band",
        "q9.cluster_spread": "/cluster_1_5x/dsp_bpm_spread",
        "q9.tier_collinearity": "/tier_agreement_crosstab",
        "q9.budget_reviews": "/budget_scenario/expected_reviews_for_target",
        "q9.fixture_ratio": "/fixture_reference/reported_over_true",
        "q9.two_thirds": "/derived/two_thirds_of_2x_class_dsp_median",
    }


def _resolve_pointer(doc: object, pointer: str) -> object:
    # `Any` deliberately: narrowing `object` to `dict` yields an unparameterised
    # mapping whose key type is `Never`, so ty rejects the string subscript.
    node: Any = doc
    for part in pointer.lstrip("/").split("/"):
        part = part.replace("~1", "/").replace("~0", "~")
        if not isinstance(node, dict) or part not in node:
            raise InvariantError(f"claim pointer {pointer} does not resolve")
        node = node[part]
    return node


def _validate_claims(doc: dict) -> None:
    for claim_id, pointer in doc["claims"].items():
        if not claim_id.startswith("q9."):
            raise InvariantError(f"claim id {claim_id} is not namespaced")
        _resolve_pointer(doc, pointer)


# --- privacy gate ------------------------------------------------------------
# An allowlist, not a grep. A grep for ".mp3" misses .wav, .m4a, bare titles,
# and any future schema addition. Threat model: no filenames and no filesystem
# location. This is NOT directory anonymity -- the prose describes the
# population and git history already carries the directory name.
_FORBIDDEN_SUBSTRINGS = ("/", "\\", "~", "$HOME", "Users/", "Volumes/")
# Named exemptions. Kept explicit and tiny: each one is a hole in the gate.
# `/claims/*` values are JSON pointers, which are slash-shaped by definition.
_PATH_EXEMPT = ("/generator_version",)
_AUDIO_EXTENSIONS = (".mp3", ".wav", ".m4a", ".flac", ".aiff", ".aif", ".ogg", ".caf")
_HEX = set("0123456789abcdef")


def _looks_like_hash(text: str) -> bool:
    stripped = text.strip().lower()
    return len(stripped) >= 32 and all(ch in _HEX for ch in stripped)


def privacy_gate(doc: dict) -> None:
    """Recursive allowlist. `survey_sha256` is the sole permitted hash."""

    def walk(node: object, path: str) -> None:
        if isinstance(node, dict):
            for key, value in node.items():
                if not isinstance(key, str):
                    raise InvariantError(f"non-string key at {path}")
                walk(value, f"{path}/{key}")
        elif isinstance(node, list):
            for i, value in enumerate(node):
                walk(value, f"{path}/{i}")
        elif isinstance(node, str):
            if path == "/survey_sha256":
                if len(node) != 64 or not all(ch in _HEX for ch in node):
                    raise InvariantError("survey_sha256 is not 64 lowercase hex")
                return
            if path in _PATH_EXEMPT or path.startswith("/claims/"):
                return
            lowered = node.lower()
            if any(lowered.endswith(ext) or f"{ext} " in lowered for ext in _AUDIO_EXTENSIONS):
                raise InvariantError(f"audio extension leaked at {path}")
            if _looks_like_hash(node):
                raise InvariantError(f"unexpected hash-shaped string at {path}")
            # Prose notes are allowed to contain slashes; short label-like
            # strings are not, since those are where a path would hide.
            if len(node) < 60 and any(bad in node for bad in _FORBIDDEN_SUBSTRINGS):
                raise InvariantError(f"path-like label at {path}: {node!r}")

    walk(doc, "")


# --- prose drift guard -------------------------------------------------------
# Catches a figure added to the artifact with nothing behind it. It proves
# COVERAGE, not correctness: it cannot tell whether a number is attached to the
# right claim, and no cheap check can, short of generating the prose from this
# JSON. The exemption list below needs maintenance and that is the honest cost.
ARTIFACT = os.path.join(HERE, "q9-ratio-cluster-2026-08-01.md")

# Structural numbers that are not empirical claims: dates, section and FR
# numbers, window bounds, band edges, ratio labels, tag integers, targets.
_PROSE_EXEMPT = {
    # dates and identifiers
    "2026",
    "8",
    "1",
    "12",
    "9",
    "59",
    "55",
    "14",
    "187",
    # window bounds and band edges
    "0.97",
    "1.03",
    "1.30",
    "1.36",
    "1.45",
    "1.40",
    "1.48",
    "1.5",
    "1.52",
    "1.49",
    "1.51",
    "1.55",
    "1.60",
    "1.94",
    "2.06",
    "1.33",
    "0.05",
    "100",
    "120",
    "140",
    "160",
    "175",
    "180",
    "108",
    "125",
    "165",
    # tag integers, target, small structural counts
    "113",
    "115",
    "116",
    "117",
    "43",
    "2",
    "3",
    "4",
    "5",
    "6",
    "0.5",
    "0.0924",
    "115.3",
    "115.6",
    "174",
    "120.0",
}
# Not preceded by a letter, so "p05" and "v2" are not read as figures.
_NUMBER_RE = r"(?<![A-Za-z0-9.])[0-9][0-9,]*(?:\.[0-9]+)?"


def _collect_values(node: object, out: set[str]) -> None:
    if isinstance(node, dict):
        for key, value in node.items():
            if key != "claims":
                _collect_values(value, out)
    elif isinstance(node, list):
        for value in node:
            _collect_values(value, out)
    elif isinstance(node, bool):
        return
    elif isinstance(node, (int, float)):
        # The prose renders the same value several ways (170 / 170.0 / 1,784).
        # Emit every plausible rendering so the audit compares meaning, not
        # formatting -- otherwise it fires on trailing zeros and thousands
        # separators and nobody keeps running it.
        value = float(node)
        out.add(f"{node:g}")
        for places in (0, 1, 2, 3):
            out.add(f"{value:.{places}f}")
        if value.is_integer():
            out.add(f"{int(value):,}")
        out.add(f"{value * 100:g}")


def audit_prose(doc: dict, artifact: str) -> list[str]:
    import re

    if not os.path.exists(artifact):
        raise InvariantError(f"artifact not found at {artifact}")
    backed: set[str] = set()
    _collect_values(doc, backed)
    backed = {v.replace(",", "") for v in backed} | backed

    uncovered: list[str] = []
    with open(artifact, encoding="utf-8") as handle:
        for lineno, line in enumerate(handle, 1):
            if line.startswith(("    ", "\t")) or line.lstrip().startswith("`"):
                continue
            # Dates, file:line references, inline code spans and section marks
            # are structure, not claims. Strip before scanning rather than
            # exempting each literal they happen to contain.
            line = re.sub(r"\d{4}-\d{2}-\d{2}", " ", line)
            line = re.sub(r"[\w.-]+\.(?:md|py|json|swift):\d+", " ", line)
            line = re.sub(r"`[^`]*`", " ", line)
            line = re.sub(r"(?:sha|SHA)-?\d+", " ", line)
            for raw in re.findall(_NUMBER_RE, line):
                bare = raw.replace(",", "")
                if bare in _PROSE_EXEMPT or raw in _PROSE_EXEMPT:
                    continue
                if bare in backed or raw in backed:
                    continue
                uncovered.append(f"{os.path.basename(artifact)}:{lineno}: {raw}")
    return uncovered


def render(doc: dict) -> str:
    return json.dumps(doc, indent=2, sort_keys=True, ensure_ascii=True) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=(__doc__ or "").split("\n")[1])
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify the committed aggregate matches the survey; write nothing",
    )
    parser.add_argument(
        "--audit-prose",
        action="store_true",
        help="report figures in the artifact with no backing value in the aggregate",
    )
    parser.add_argument("--survey", default=SURVEY)
    parser.add_argument("--output", default=OUTPUT)
    parser.add_argument("--artifact", default=ARTIFACT)
    args = parser.parse_args(argv)

    try:
        doc = build(load_survey(args.survey))
        privacy_gate(doc)
    except InvariantError as exc:
        sys.stderr.write(f"Invariant failure: {exc}\n")
        return EXIT_INVARIANT

    rendered = render(doc)

    if args.audit_prose:
        try:
            uncovered = audit_prose(doc, args.artifact)
        except InvariantError as exc:
            sys.stderr.write(f"{exc}\n")
            return EXIT_INVARIANT
        if uncovered:
            sys.stderr.write("Figures with no backing value in the aggregate:\n")
            for row in uncovered:
                sys.stderr.write(f"  {row}\n")
            return EXIT_DRIFT
        print("OK: every prose figure resolves to a value in the aggregate.")
        return 0

    if args.check:
        if not os.path.exists(args.output):
            sys.stderr.write(f"Error: {args.output} does not exist.\n")
            return EXIT_MISSING_INPUT
        with open(args.output, encoding="utf-8") as handle:
            committed = handle.read()
        if committed != rendered:
            sys.stderr.write("Drift: the committed aggregate does not match the survey.\n")
            import difflib

            for line in list(
                difflib.unified_diff(
                    committed.splitlines(),
                    rendered.splitlines(),
                    "committed",
                    "regenerated",
                    lineterm="",
                )
            )[:40]:
                sys.stderr.write(line + "\n")
            return EXIT_DRIFT
        print(f"OK: {os.path.basename(args.output)} matches the survey.")
        return 0

    tmp = args.output + ".tmp"
    with open(tmp, "w", encoding="utf-8") as handle:
        handle.write(rendered)
    os.replace(tmp, args.output)
    print(f"Wrote {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
