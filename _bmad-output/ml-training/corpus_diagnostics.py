"""
Story 7.1 Task 1 + Task 6 — corpus diagnostics generator (develop-only).

Reads `tony-corpus/tony-truth-labels.json` and emits:
  - `corpus-diagnostics-v1.json` — the FR-12 diagnostics artifact,
  - `corpus-diagnostics-v1.md`  — reviewer-readable sibling with one `##`
    section per top-level JSON key + the KDD-B4 reviewer-signoff checklist.

Guardrail 2 (Codex, non-negotiable): every confidence/ECE figure here is a
LABEL-confidence diagnostic over the disagreement signals, NOT a model metric.
It produces NO transferable FR-18 accuracy claim.

Run: `make corpus-diagnostics`  (or `uv run python corpus_diagnostics.py`).
Regenerating REsets the reviewer signoff to `pending` — new evidence requires
new review (AC8 / AC9 drift philosophy).
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys

import numpy as np
from scipy.cluster.vq import kmeans2, whiten

import corpus_common as cc
import marginal_failure_categorize as mfc

OUT_JSON = cc.ML_TRAINING_DIR / "corpus-diagnostics-v1.json"
OUT_MD = cc.ML_TRAINING_DIR / "corpus-diagnostics-v1.md"

# Story 7.4 use-(b) — proximity sub-metric coverage gate (DD #5). The
# fingerprint cache was built over SPLIT tracks (Marginal is split-excluded by
# FR-14), so live Marginal coverage is ~16/241 — below this floor the per-
# category mean nearest-Strong distance is `null`+status, never a misleading
# upward-biased number. Numeric proximity appears only after `--fingerprint-fill`.
MARGINAL_PROXIMITY_COVERAGE_FLOOR = 0.80
MARGINAL_PROXIMITY_MIN_PER_CATEGORY = 10

SIGNALS = ("rekordbox_average", "grid_bpm", "dsp", "playlist")
BPM_SIGNALS = ("rekordbox_average", "grid_bpm", "dsp")  # playlist carries no bpm
# `relation` values worth comparing (playlist "missing" / None excluded as
# "signal did not speak"). The current labeler emits same/half/far/near; "double"
# is kept DEFENSIVELY (a future labeler could emit it) but is not produced today,
# so the labelOctaveErrorAudit `halvedCount` stratum is structurally 0 on this
# corpus — that's expected, not a miscount.
MEANINGFUL_RELATIONS = {"same", "half", "double", "near", "far"}

# AC9 — drift-block threshold. Tier-count drift beyond this (vs the pinned
# PRD snapshot) OR any tier crossing a documented bound BLOCKS training pending
# review. 2% of 1344 ~= 27 tracks; chosen so normal label-file regeneration
# noise passes but a structural relabel trips the block.
DRIFT_BLOCK_ABS = 27


# ---------------------------------------------------------------------------
# Individual diagnostics
# ---------------------------------------------------------------------------


def _git_sha() -> str:
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=cc.REPO_ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        sha = out.stdout.strip()
        dirty = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=cc.REPO_ROOT,
            capture_output=True,
            text=True,
        ).stdout.strip()
        return f"{sha}{'-dirty' if dirty else ''}"
    except Exception:
        return "unknown"


def label_source_bias(tracks: list[dict]) -> dict:
    """4×4 agreement matrix over the 4 EMITTED signals, on the `relation` field
    (the only axis comparable across all four — playlist carries no bpm). Cell
    [i][j] = fraction of tracks where BOTH signals spoke meaningfully and their
    relation-to-truth labels match, plus the co-presence count n. Signal 3
    (`grid_spacing` / inter-Inizio) is a documented STRUCTURAL ABSENCE.
    """
    matrix: dict[str, dict[str, dict]] = {}
    for i in SIGNALS:
        matrix[i] = {}
        for j in SIGNALS:
            n = 0
            agree = 0
            for t in tracks:
                ri = t["signals"].get(i, {}).get("relation")
                rj = t["signals"].get(j, {}).get("relation")
                if ri in MEANINGFUL_RELATIONS and rj in MEANINGFUL_RELATIONS:
                    n += 1
                    if ri == rj:
                        agree += 1
            matrix[i][j] = {"agreement": round(agree / n, 4) if n else None, "n": n}
    # Disclose degenerate (100%-identical) off-diagonal axis pairs so a reader
    # does not mistake the 4x4 for four INDEPENDENT signals (on this corpus
    # rekordbox_average and grid_bpm carry an identical relation on every record).
    degenerate_pairs = [
        [i, j]
        for idx_i, i in enumerate(SIGNALS)
        for j in SIGNALS[idx_i + 1 :]
        if matrix[i][j]["n"] and matrix[i][j]["agreement"] == 1.0
    ]
    return {
        "axis": "relation-to-assigned-truth (same/half/double/near/far)",
        "signals": list(SIGNALS),
        "matrix": matrix,
        "degenerateAxisPairs": degenerate_pairs,
        "degenerateAxisNote": "Signal pairs with agreement 1.0 carry an IDENTICAL "
        "relation on every co-present record — they are not independent axes. On this "
        "corpus rekordbox_average and grid_bpm are such an alias pair; the matrix is "
        "4x4 by emitted key (DD #6) but effectively rank-deficient on the relation axis.",
        "playlistNote": "playlist is relation-only (no bpm); 'missing' on tracks "
        "with no matching playlist prior is treated as 'did not speak'.",
        "signal3StructuralAbsence": {
            "name": "grid_spacing (inter-Inizio grid spacing)",
            "coverage": 0,
            "note": "DECLARED-but-UNWIRED: the survey never emits full grid arrays "
            "(tony-tunes-survey.py), so no `grid_spacing` key exists on any record. "
            "Reported as a structural absence, NOT a sparse signal. The matrix is "
            "4×4 over the emitted signals, not 5×5 (DD #6).",
        },
    }


def octave_ambiguity_rate(tracks: list[dict]) -> dict:
    """Fraction of resolvable tracks where Rekordbox AverageBpm vs DSP winner
    form a 2:1 ratio within the labeler's 0.04 tolerance.
    """
    resolvable = [t for t in tracks if t.get("bpm_truth") is not None]
    n = 0
    for t in resolvable:
        r = t["signals"].get("rekordbox_average", {}).get("bpm")
        d = t["signals"].get("dsp", {}).get("bpm")
        if r is None or d is None:
            continue
        ratio = cc.canonical_ratio(r, d)
        if abs(ratio - 2.0) <= 0.04 * 2.0:
            n += 1
    denom = len(resolvable)
    return {
        "rate": round(n / denom, 4) if denom else None,
        "ambiguousCount": n,
        "resolvableCount": denom,
        "definition": "Rekordbox AverageBpm vs DSP winner form a 2:1 ratio within "
        "0.04 relative tolerance (same metric the labeler uses).",
    }


def label_octave_error_audit(tracks: list[dict]) -> dict:
    """E1 — half/double LABEL-error estimate, distinct from signal disagreement.

    Two strata among Strong+Solid where the assigned truth is DOUBLE the human
    Rekordbox tag (rekordbox_average.relation == 'half' => truth = 2× rekordbox):

      - `doubledCount`: ALL such tracks. For DnB this is mostly the EXPECTED
        half-time DJ-tagging convention (Tony grids to 85 for mixing; the track
        is genuinely 170) and is NOT by itself a label error.
      - `highRisk`: the dangerous subset where the doubling was carried ONLY by
        the boosted half->full cluster and DSP did NOT independently land on the
        full tempo (dsp relation != 'same'). This is the confidently-wrong octave
        class that margin-based truth_confidence cannot catch — the full-tempo
        label rests on grid/boost alone, with no independent onset-analysis
        confirmation.
    """
    doubled: list[dict] = []
    high_risk: list[dict] = []
    halved: list[dict] = []
    for t in tracks:
        if cc.tier_for(t.get("truth_confidence"), t.get("bpm_truth")) not in cc.TRAINABLE_TIERS:
            continue
        rk = t["signals"].get("rekordbox_average", {})
        rel = rk.get("relation")
        truth = t.get("bpm_truth")
        rbpm = rk.get("bpm")
        dsp_rel = t["signals"].get("dsp", {}).get("relation")
        if rel == "half":
            sources = (t.get("truth_cluster") or {}).get("sources", [])
            row = {
                "track_id": str(t.get("track_id")),
                "name": t.get("name"),
                "bpm_truth": truth,
                "rekordbox_bpm": rbpm,
                "dspRelation": dsp_rel,
                "winnerClusterSources": sources,
                "winnerSourceCount": len(sources),
            }
            doubled.append(row)
            # DSP did not independently confirm the full tempo => no onset-based
            # corroboration of the doubling.
            if dsp_rel != "same":
                high_risk.append(row)
        elif rel == "double":
            halved.append(
                {
                    "track_id": str(t.get("track_id")),
                    "name": t.get("name"),
                    "bpm_truth": truth,
                    "rekordbox_bpm": rbpm,
                    "dspRelation": dsp_rel,
                }
            )
    return {
        "definition": "Strong+Solid tracks where assigned truth is an octave off the "
        "human Rekordbox tag (rekordbox relation 'half' => truth=2×rekordbox).",
        "doubledCount": len(doubled),
        "doubledNote": "Mostly the EXPECTED DnB half-time tagging convention (DJ grids to "
        "the half for mixing); NOT a label error on its own. Reported for transparency.",
        "highRiskCount": len(high_risk),
        "highRiskDefinition": "doubled AND DSP did not independently confirm the full "
        "tempo (dsp relation != 'same') — the confidently-wrong octave class: the "
        "full-tempo label rests on grid/boost with no independent onset corroboration.",
        "halvedCount": len(halved),
        "highRiskSample": high_risk[:25],
        "halvedSample": halved[:15],
        "guardrailNote": "LABEL-quality audit, not a model metric (Guardrail 2). Feeds "
        "KDD-B3 reopen-trigger 3 (half/double confusions); high-risk track IDs are the "
        "spot-check list for the reviewer signoff (AC8).",
    }


def _proxy_correct(t: dict) -> bool:
    """Proxy 'label is correct' indicator for label-ECE: >= 2 of the 3 BPM-bearing
    signals agree with the assigned truth at SAME octave (relation == 'same').
    This is a LABEL-AGREEMENT proxy, NOT ground-truth correctness (no oracle exists).
    """
    same = sum(1 for s in BPM_SIGNALS if t["signals"].get(s, {}).get("relation") == "same")
    return same >= 2


def confidence_calibration_by_tier(tracks: list[dict]) -> dict:
    """Per-tier mean truth_confidence + a binned label-ECE against the
    signal-agreement proxy. NOT model calibration (Guardrail 2): produces no
    transferable FR-18 metric.
    """
    resolvable = [t for t in tracks if t.get("bpm_truth") is not None]
    if not resolvable:
        return {
            "perTier": {},
            "labelECE": None,
            "eceBins": [],
            "note": "no resolvable tracks (all bpm_truth null) — ECE undefined.",
        }
    per_tier: dict[str, dict] = {}
    for tier in cc.TRAINABLE_TIERS + ("Marginal",):
        group = [
            t for t in resolvable if cc.tier_for(t["truth_confidence"], t["bpm_truth"]) == tier
        ]
        if not group:
            per_tier[tier] = {"n": 0}
            continue
        confs = np.array([t["truth_confidence"] for t in group])
        proxy = np.array([1.0 if _proxy_correct(t) else 0.0 for t in group])
        per_tier[tier] = {
            "n": len(group),
            "meanConfidence": round(float(confs.mean()), 4),
            "proxyAgreementAccuracy": round(float(proxy.mean()), 4),
        }
    # Overall binned ECE (10 equal-width bins over confidence in the observed range).
    confs = np.array([t["truth_confidence"] for t in resolvable])
    proxy = np.array([1.0 if _proxy_correct(t) else 0.0 for t in resolvable])
    bins = np.linspace(confs.min(), confs.max() + 1e-9, 11)
    idx = np.clip(np.digitize(confs, bins) - 1, 0, 9)
    ece = 0.0
    bin_rows = []
    for b in range(10):
        mask = idx == b
        cnt = int(mask.sum())
        if cnt == 0:
            continue
        conf_mean = float(confs[mask].mean())
        acc_mean = float(proxy[mask].mean())
        ece += (cnt / len(confs)) * abs(conf_mean - acc_mean)
        bin_rows.append(
            {
                "bin": b,
                "n": cnt,
                "meanConfidence": round(conf_mean, 4),
                "proxyAccuracy": round(acc_mean, 4),
            }
        )
    return {
        "perTier": per_tier,
        "labelECE": round(float(ece), 4),
        "eceBins": bin_rows,
        "binning": "10 equal-width bins over the observed truth_confidence range; "
        "ECE = sum_b (n_b/N) |meanConfidence_b - proxyAccuracy_b|.",
        "proxyDefinition": ">=2 of 3 BPM-bearing signals (rekordbox/grid/dsp) agree "
        "with the assigned truth at same octave (relation=='same').",
        "GUARDRAIL_2": "This ECE measures LABEL-confidence calibration against a "
        "signal-agreement proxy, NOT model calibration. It produces NO transferable "
        "FR-18 metric. A featureSetVersion bump does not affect it because no model "
        "is involved.",
    }


def cluster_stability(tracks: list[dict], k: int = 4, seeds: int = 5) -> dict:
    """k-means stability across >= `seeds` seeds via scipy.cluster.vq.kmeans2
    (scikit-learn is NOT a dependency). Feature vector encodes the per-track
    disagreement geometry. Stability = sklearn-free co-assignment consistency:
    over a fixed sample of track pairs, the fraction of seed-pairs that agree on
    whether the two tracks share a cluster (permutation-invariant — no label
    alignment needed).
    """
    resolvable = [t for t in tracks if t.get("bpm_truth") is not None]
    feats = []
    for t in resolvable:
        truth = t["bpm_truth"]

        def logr(sig: str) -> float:
            b = t["signals"].get(sig, {}).get("bpm")
            if not b or b <= 0 or truth <= 0:
                return 0.0
            return float(np.log2(b / truth))

        feats.append(
            [
                float(t["truth_confidence"]),
                logr("rekordbox_average"),
                logr("grid_bpm"),
                logr("dsp"),
            ]
        )
    X = np.asarray(feats, dtype=np.float64)
    N = X.shape[0]
    if N < max(k, 2):
        return {
            "k": k,
            "seeds": seeds,
            "coAssignmentConsistency": None,
            "note": f"too few resolvable tracks ({N}) for k={k} k-means — skipped.",
        }
    Xw = whiten(X)

    labelings = []
    distortions = []
    for s in range(seeds):
        centroids, labels = kmeans2(Xw, k, seed=1000 + s, minit="++", missing="warn")
        labelings.append(labels)
        # distortion = mean distance to assigned centroid
        d = float(np.mean([np.linalg.norm(Xw[i] - centroids[labels[i]]) for i in range(N)]))
        distortions.append(d)

    # Co-assignment consistency over a deterministic pair sample.
    rng = np.random.default_rng(20260531)
    n_pairs = min(5000, N * (N - 1) // 2)
    a = rng.integers(0, N, size=n_pairs)
    b = rng.integers(0, N, size=n_pairs)
    valid = a != b
    a, b = a[valid], b[valid]
    # Sampled with replacement (a few duplicate pairs are statistically harmless
    # at N in the hundreds+); guard the degenerate empty-sample case.
    if a.size == 0:
        return {
            "k": k,
            "seeds": seeds,
            "coAssignmentConsistency": None,
            "note": "pair sample empty (degenerate N) — stability undefined.",
        }
    same_per_seed = np.stack([(L[a] == L[b]) for L in labelings])  # (seeds, pairs)
    # For each pair: agreement across all seed-pairs = how often two seeds concur.
    frac_same = same_per_seed.mean(axis=0)  # (pairs,)
    # consistency: 1 when all seeds agree (all-same or all-diff), 0.5 when split.
    consistency = float(np.mean(np.maximum(frac_same, 1.0 - frac_same)))
    return {
        "k": k,
        "seeds": seeds,
        "featureVector": [
            "truth_confidence",
            "log2(rekordbox/truth)",
            "log2(grid/truth)",
            "log2(dsp/truth)",
        ],
        "method": "scipy.cluster.vq.kmeans2 (++init, whiten-standardized features)",
        "coAssignmentConsistency": round(consistency, 4),
        "consistencyDefinition": "Over a fixed 5000-pair sample, mean of "
        "max(frac_same_cluster, 1-frac_same_cluster) across seeds — 1.0 = perfectly "
        "stable, 0.5 = seed-dependent. Permutation-invariant (no label alignment).",
        "distortionMean": round(float(np.mean(distortions)), 4),
        "distortionStd": round(float(np.std(distortions)), 4),
    }


def representative_findings(tracks: list[dict]) -> list[dict]:
    """>= 10 named tracks with non-empty data-derived notes; >= 2 from the
    Marginal band (KDD-B4 item (ii) — the Marginal cohort provably appears).
    """
    by_tier = {tier: [] for tier in cc.TIERS}
    for t in tracks:
        by_tier[cc.tier_for(t["truth_confidence"], t["bpm_truth"])].append(t)

    def rel(t, s):
        return t["signals"].get(s, {}).get("relation")

    def find(group, pred):
        return next((t for t in group if pred(t)), None)

    findings: list[dict] = []

    def add(t, note):
        if t is None:
            return
        findings.append(
            {
                "track_id": str(t.get("track_id")),
                "name": t.get("name"),
                "artist": t.get("artist") or "(empty)",
                "tier": cc.tier_for(t["truth_confidence"], t["bpm_truth"]),
                "truth_confidence": t["truth_confidence"],
                "bpm_truth": t.get("bpm_truth"),
                "qa_flags": t.get("qa_flags", []),
                "note": note,
            }
        )

    # 2 Strong exemplars where all 3 BPM signals agree at same octave.
    clean = [t for t in by_tier["Strong"] if all(rel(t, s) == "same" for s in BPM_SIGNALS)]
    for t in clean[:2]:
        add(
            t,
            "Strong-tier clean exemplar: all three BPM signals (rekordbox/grid/dsp) "
            "agree with the assigned truth at the same octave.",
        )
    # 2 Solid where rekordbox/grid say half but dsp pulled truth to full tempo.
    split = [
        t
        for t in by_tier["Solid"]
        if rel(t, "rekordbox_average") == "half" and rel(t, "dsp") == "same"
    ]
    for t in split[:2]:
        add(
            t,
            "Solid-tier octave split: Rekordbox+grid tag the half-time; DSP carried "
            "the full-tempo winner. Watch for wrong-octave risk (E1).",
        )
    # >= 2 MARGINAL findings (required).
    marg_amb = [t for t in by_tier["Marginal"] if "ambiguous_cluster" in t.get("qa_flags", [])]
    for t in marg_amb[:2]:
        add(
            t,
            "Marginal-tier ambiguous cluster: winner barely beat the runner-up; "
            "tempo geometry is genuinely contested. Failure-categorization candidate (Story 7.4).",
        )
    if sum(1 for f in findings if f["tier"] == "Marginal") < 2:
        for t in by_tier["Marginal"][:2]:
            if not any(f["track_id"] == str(t.get("track_id")) for f in findings):
                add(
                    t,
                    "Marginal-tier representative: truth_confidence in [0.55,0.65); "
                    "excluded from the initial supervised set, retained as a watchlist (KDD-B3).",
                )
    # 2 label-octave-error candidates: high-risk subset (doubled AND DSP did
    # not independently confirm the full tempo).
    high_risk = [
        t
        for t in (by_tier["Strong"] + by_tier["Solid"])
        if rel(t, "rekordbox_average") == "half" and rel(t, "dsp") != "same"
    ]
    for t in high_risk[:2]:
        add(
            t,
            "Label-octave-error HIGH-RISK candidate (E1): assigned truth is 2× the "
            "human Rekordbox tag AND DSP did not independently land on the full tempo. "
            "If the DJ tag was right, this is a confidently-wrong octave label.",
        )
    # 1 single_source_truth, 1 high-confidence Strong with a 'far' dsp.
    ss = find(tracks, lambda t: "single_source_truth" in t.get("qa_flags", []))
    add(
        ss,
        "single_source_truth flag: winner cluster rests on < 2 distinct non-playlist "
        "sources; lands in Marginal/Reject (no single-source track reaches the trainable tier).",
    )
    fardsp = find(by_tier["Strong"], lambda t: rel(t, "dsp") == "far")
    add(
        fardsp,
        "Strong-tier with DSP 'far': Rekordbox+grid consensus carried a confident "
        "label despite the DSP estimate being off — DSP-disagreement exemplar.",
    )

    # Guarantee >= 10 by topping up from Solid with generic notes.
    i = 0
    while len(findings) < 10 and i < len(by_tier["Solid"]):
        t = by_tier["Solid"][i]
        i += 1
        if any(f["track_id"] == str(t.get("track_id")) for f in findings):
            continue
        add(
            t,
            "Solid-tier representative: multi-signal agreement placed truth_confidence "
            "in [0.65,0.80); part of the initial supervised set.",
        )
    return findings


def single_source_truth_policy(tracks: list[dict]) -> dict:
    """M3 — the labeler flags single_source_truth but still assigns bpm_truth.
    Decide + document trainability. On this corpus the answer is structural:
    NO single-source track reaches Strong/Solid (the flag co-occurs with low
    confidence), so the trainable set is fully multi-source.
    """
    trainable = [t for t in tracks if cc.is_trainable(t)]
    ss_trainable = [t for t in trainable if "single_source_truth" in t.get("qa_flags", [])]
    ss_total = sum(1 for t in tracks if "single_source_truth" in t.get("qa_flags", []))
    return {
        "singleSourceTotal": ss_total,
        "singleSourceInTrainable": len(ss_trainable),
        "decision": "INCLUDE — moot on this corpus: 0 single-source tracks reach the "
        "Strong/Solid trainable tier (the single_source_truth flag co-occurs with "
        "low_confidence and tiers into Marginal/Reject). The trainable set of "
        f"{len(trainable)} is fully multi-source. If a future relabel pushes a "
        "single-source track into Strong/Solid, this decision MUST be revisited.",
    }


# ---------------------------------------------------------------------------
# Story 7.4 use-(b) — Marginal-tier disagreement geometry (DD #3 / DD #5)
# ---------------------------------------------------------------------------


def _load_cached_fingerprints(
    subset: list[dict], *, fill: bool = False
) -> tuple[dict[str, "np.ndarray"], int]:
    """Return ({track_id -> raw vector}, new_entries) for `subset`, reading the
    method-versioned cache. Cache-ONLY in the default path (no audio decode —
    DD #5); `fill=True` is the operator path that computes missing vectors via
    librosa and writes them back (needs Tony audio).
    """
    cache: dict[str, "np.ndarray"] = {}
    if cc.FINGERPRINT_CACHE.exists():
        z = np.load(cc.FINGERPRINT_CACHE, allow_pickle=True)
        method = str(z["__method__"]) if "__method__" in z.files else "unknown"
        if method == cc.FINGERPRINT_METHOD:
            for k in z.files:
                if k == "__method__":
                    continue
                v = z[k]
                if np.all(np.isfinite(v)):
                    cache[k] = v

    vecs: dict[str, "np.ndarray"] = {}
    new_entries = 0
    for t in subset:
        path = t.get("local_path")
        if not path or not os.path.exists(path):
            continue
        ckey = cc.content_hash(path)
        if ckey in cache:
            vecs[str(t.get("track_id"))] = cache[ckey]
        elif fill:
            fp = cc.compute_fingerprint(path)
            if fp is None:
                continue
            cache[ckey] = fp
            vecs[str(t.get("track_id"))] = fp
            new_entries += 1

    if fill and new_entries:
        np.savez_compressed(
            cc.FINGERPRINT_CACHE,
            __method__=cc.FINGERPRINT_METHOD,
            **cache,
        )
    return vecs, new_entries


def marginal_tier_disagreement_geometry(tracks: list[dict], *, fill: bool = False) -> dict:
    """Use-(b) `marginalTierDisagreementGeometry` block (AC3).

    Sub-metrics (a)-(c) are computed from on-disk JSON at 100% coverage; (d) is
    coverage-gated (DD #5) — `null`+status below the floor (the expected
    dev-agent state with the split-built cache).
    """
    records = mfc.categorization_records(tracks)
    marg_by_id = {str(t.get("track_id")): t for t in mfc.select_marginal(tracks)}

    # Octave geometry shares the categorizer's single-source predicate (DD #3) —
    # the finite-coercing `_centroid` path, not a raw `.get("centroid")` re-impl.
    def _is_octave(t: dict) -> bool:
        return mfc.is_octave_ratio(mfc.cluster_ratio(t))

    # Group marginal track_ids by category (declared order).
    by_cat: dict[str, list[str]] = {c: [] for c in mfc.CATEGORIES}
    for r in records:
        by_cat[r["failureCategory"]].append(r["track_id"])

    # --- Proximity (d) — coverage-gated nearest-Strong distance (DD #5). ---
    strong = [
        t for t in tracks if cc.tier_for(t.get("truth_confidence"), t.get("bpm_truth")) == "Strong"
    ]
    marg_vecs, marg_new = _load_cached_fingerprints(list(marg_by_id.values()), fill=fill)
    strong_vecs, strong_new = _load_cached_fingerprints(strong, fill=fill)
    marg_total = len(marg_by_id)
    strong_total = len(strong)
    marg_cov_frac = len(marg_vecs) / marg_total if marg_total else 0.0
    coverage_ok = marg_cov_frac >= MARGINAL_PROXIMITY_COVERAGE_FLOOR and bool(strong_vecs)

    per_category: dict[str, dict] = {}
    for cat in mfc.CATEGORIES:
        ids = by_cat[cat]
        n = len(ids)
        dsp_confs = []
        for i in ids:
            conf = marg_by_id[i].get("signals", {}).get("dsp", {}).get("confidence")
            if cc._is_finite(conf):
                dsp_confs.append(conf)
        octave_n = sum(1 for i in ids if _is_octave(marg_by_id[i]))

        # (d) coverage-gated proximity for THIS category.
        covered_ids = [i for i in ids if i in marg_vecs]
        if coverage_ok and len(covered_ids) >= MARGINAL_PROXIMITY_MIN_PER_CATEGORY:
            cat_marg_vecs = {i: marg_vecs[i] for i in covered_ids}
            nearest = mfc.nearest_strong_distances(cat_marg_vecs, strong_vecs)
            dists = [d for _, d in nearest.values()]
            mean_dist = round(float(np.mean(dists)), 6) if dists else None
            prox_status = "computed"
        else:
            mean_dist = None
            prox_status = "insufficientCoverage"

        per_category[cat] = {
            "count": n,
            "meanDspConfidence": round(float(np.mean(dsp_confs)), 6) if dsp_confs else None,
            "halfDoubleRate": round(octave_n / n, 6) if n else None,
            "coveredForProximity": len(covered_ids),
            "meanNearestStrongDistance": mean_dist,
            "proximityStatus": prox_status,
        }

    return {
        "marginalTierCount": marg_total,
        "categorizationModule": "marginal_failure_categorize.py",
        "perCategory": per_category,
        "halfDoubleRateDefinition": "fraction of the category's tracks whose "
        "runner_up_cluster centroid is a 2x/0.5x (octave) ratio of the truth_cluster "
        "centroid (canonical_ratio within OCTAVE_RATIO_TOL).",
        "proximity": {
            "metric": "cosine distance to the nearest Strong-tier neighbor in the "
            f"{cc.FINGERPRINT_METHOD} fingerprint space (per-dimension standardized "
            "across the union, exhaustive argmin, ties -> lowest Strong track_id).",
            "marginalCoverage": f"{len(marg_vecs)}/{marg_total}",
            "strongCoverage": f"{len(strong_vecs)}/{strong_total}",
            "coverageFloor": MARGINAL_PROXIMITY_COVERAGE_FLOOR,
            "minPerCategory": MARGINAL_PROXIMITY_MIN_PER_CATEGORY,
            "coverageMet": coverage_ok,
            "note": "DD #5 — the fingerprint cache was built over SPLIT tracks; Marginal "
            "is split-excluded (FR-14), so coverage is far below the floor on a dev-agent "
            "run and per-category meanNearestStrongDistance is null with "
            "proximityStatus 'insufficientCoverage'. This is EXPECTED and gates nothing. "
            "Numeric proximity appears only after the corpus_diagnostics.py --fingerprint-fill "
            "flag (needs Tony audio + librosa) raises coverage above the floor.",
            "fillRan": fill,
            "fillNewVectors": marg_new + strong_new,
        },
    }


# ---------------------------------------------------------------------------
# Assembly
# ---------------------------------------------------------------------------


def build_diagnostics(*, fingerprint_fill: bool = False) -> dict:
    tracks, prov = cc.load_tony_corpus()

    # AC9 / M1 — resolved-vs-total audio (NEVER silently shrink the corpus).
    total = len(tracks)
    unresolved = [
        {
            "track_id": str(t.get("track_id")),
            "name": t.get("name"),
            "local_path": t.get("local_path"),
        }
        for t in tracks
        if not (t.get("local_path") and os.path.exists(t["local_path"]))
    ]
    resolved = total - len(unresolved)

    hist = cc.tier_histogram(tracks)
    snapshot = cc.PRD_TIER_SNAPSHOT
    delta = {tier: hist[tier] - snapshot.get(tier, 0) for tier in cc.TIERS}
    max_abs_drift = max(abs(v) for v in delta.values())
    drift_blocks = max_abs_drift > DRIFT_BLOCK_ABS

    diagnostics = {
        "schemaVersion": 1,
        "generator": "corpus_diagnostics.py",
        "gitSha": _git_sha(),
        "provenance": {
            "labelsPath": prov.labels_path,
            "labelsSha256": prov.labels_sha256,
            "labelerScriptPath": prov.labeler_script_path,
            "labelerScriptSha256": prov.labeler_script_sha256,
            "trackCount": prov.track_count,
            "note": "The corpus is develop-local/gitignored; these hashes pin the "
            "EXACT label file + labeler that produced the figures below. A regenerated "
            "label file changes labelsSha256 and invalidates this artifact (AC9).",
        },
        "resolvedVsTotal": {
            "total": total,
            "resolvedAudio": resolved,
            "unresolvedCount": len(unresolved),
            "unresolved": unresolved,
            "note": "M1 loud-fail: audio resolution is reported, never silently "
            "filtered. The labeler's resolve_status filter and the builder's "
            "skip-missing-audio counters must not shrink the corpus unannounced.",
        },
        "tierHistogram": {
            "computed": hist,
            "prdSnapshot": snapshot,
            "snapshotDelta": delta,
            "note": "Computed by banding truth_confidence with exact half-open "
            "intervals (NOT transcribed from the PRD). FR-14 says 'currently' — drift "
            "is reported as a snapshot delta, not coerced (AC10).",
        },
        "driftBlockThreshold": {
            "maxAbsTierDrift": max_abs_drift,
            "thresholdAbs": DRIFT_BLOCK_ABS,
            "blocksTraining": drift_blocks,
            "note": "AC9 — tier-count drift beyond threshold (or any tier crossing a "
            "documented bound) BLOCKS training pending review. `blocksTraining: true` "
            "means Story 7.5 train.py MUST halt until re-reviewed.",
        },
        "labelSourceBias": label_source_bias(tracks),
        "octaveAmbiguityRate": octave_ambiguity_rate(tracks),
        "labelOctaveErrorAudit": label_octave_error_audit(tracks),
        "confidenceCalibrationByTier": confidence_calibration_by_tier(tracks),
        "clusterStability": cluster_stability(tracks),
        "representativeManualReviewFindings": representative_findings(tracks),
        "singleSourceTruthPolicy": single_source_truth_policy(tracks),
        "marginalTierDisagreementGeometry": marginal_tier_disagreement_geometry(
            tracks, fill=fingerprint_fill
        ),
        "reviewerSignoff": {
            "state": "pending",
            "note": "KDD-B4 gate (AC8). `scripts/audit-corpus-splits.py --check-gate` "
            "exits non-zero while this is 'pending'. The operator transcribes what they "
            "verified into the checklist in corpus-diagnostics-v1.md, then flips the "
            "REVIEWER_SIGNOFF marker to 'signed'. 7.1 'done' = evidence assembled + "
            "review pending, NOT corpus-safe-to-train.",
            "checklistItems": [
                "tierHistogram.computed transcribed and matches expectation",
                "count of representativeManualReviewFindings reviewed (>= 10, >= 2 Marginal)",
                "count of labelOctaveErrorAudit candidates spot-checked against audio (with track IDs)",
                "audit-corpus-splits.py near-dup REVIEW FLAGS resolved (each genuinely-"
                "differently-named same-recording pair excluded or confirmed distinct, with IDs)",
                "driftBlockThreshold.blocksTraining is false",
            ],
        },
    }
    return diagnostics


# ---------------------------------------------------------------------------
# Markdown rendering — one `##` per top-level JSON key (AC1 grep invariant).
# ---------------------------------------------------------------------------


def render_markdown(diag: dict) -> str:
    lines: list[str] = []
    lines.append("# Corpus Diagnostics v1 (Story 7.1, FR-12)")
    lines.append("")
    lines.append(
        "> Develop-only diagnostic artifact. Every confidence/ECE figure here is a "
        "LABEL-confidence diagnostic over the disagreement signals, NOT a model metric "
        "(Guardrail 2). Produces NO transferable FR-18 accuracy claim."
    )
    lines.append("")
    lines.append(
        "Machine-readable companion: `corpus-diagnostics-v1.json`. This Markdown has "
        "exactly one `##` section per top-level JSON key (grep-checkable reviewer "
        "structure)."
    )
    lines.append("")

    # KDD-B4 signoff checklist rendered prominently (AC8).
    so = diag["reviewerSignoff"]
    lines.append("## REVIEWER SIGNOFF (KDD-B4 gate)")
    lines.append("")
    lines.append(f"`REVIEWER_SIGNOFF: {so['state']}`")
    lines.append("")
    lines.append(
        "The operator fills this by TRANSCRIBING what they actually verified, then "
        "changes the marker above to `signed`. `audit-corpus-splits.py --check-gate` "
        "exits non-zero until then. **7.1 'done' = evidence assembled + review pending, "
        "NOT corpus-safe-to-train** — that flips only when this is signed (it gates "
        "Story 7.5 train.py, not 7.1 close)."
    )
    lines.append("")
    for item in so["checklistItems"]:
        lines.append(f"- [ ] {item}  →  _verified value:_ `__________`")
    lines.append("")

    def render(obj, depth=0):
        pad = "  " * depth
        out = []
        if isinstance(obj, dict):
            for k, v in obj.items():
                if isinstance(v, (dict, list)):
                    out.append(f"{pad}- **{k}**:")
                    out.extend(render(v, depth + 1))
                else:
                    out.append(f"{pad}- **{k}**: `{v}`")
        elif isinstance(obj, list):
            for el in obj[:30]:
                if isinstance(el, (dict, list)):
                    out.append(f"{pad}-")
                    out.extend(render(el, depth + 1))
                else:
                    out.append(f"{pad}- `{el}`")
            if len(obj) > 30:
                out.append(f"{pad}- _... {len(obj) - 30} more (see JSON)_")
        return out

    skip = {"reviewerSignoff"}  # already rendered above, but still needs a ## header
    for key, val in diag.items():
        lines.append(f"## {key}")
        lines.append("")
        if key in skip:
            lines.append(f"See REVIEWER SIGNOFF section above. State: `{val['state']}`.")
            lines.append("")
            continue
        if isinstance(val, (dict, list)):
            lines.extend(render(val))
        else:
            lines.append(f"`{val}`")
        lines.append("")
    return "\n".join(lines) + "\n"


def _existing_signoff_state() -> str | None:
    """Return the REVIEWER_SIGNOFF state in the on-disk .md (signed/pending), or
    None if the file is absent or carries no marker. Anchored regex (same form the
    audit uses).

    Fail-CLOSED on ambiguity (code-review 7-4): any marker count != 1 maps to
    "signed" so `main()` refuses to overwrite without --force — a 2+-marker file
    (including two `pending`) is an ambiguous state the guard must not silently
    clobber. Only a single unambiguous marker returns its own value.
    """
    if not OUT_MD.exists():
        return None
    markers = re.findall(r"REVIEWER_SIGNOFF:\s*(signed|pending)", OUT_MD.read_text())
    if not markers:
        return None
    if len(markers) != 1:
        return "signed"
    return markers[0]


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Story 7.1/7.4 corpus diagnostics generator.")
    ap.add_argument(
        "--fingerprint-fill",
        action="store_true",
        help="OPERATOR-ONLY (DD #5): compute missing librosa fingerprints from Tony "
        "audio to raise the use-(b) proximity coverage above the floor. Needs the "
        "audio on disk; the default dev-agent run reads cache-only and emits null.",
    )
    ap.add_argument(
        "--force",
        action="store_true",
        help="Regenerate even when the on-disk diagnostics are REVIEWER_SIGNOFF: signed "
        "(DD #4 — regeneration reverts the signoff to pending).",
    )
    args = ap.parse_args(argv)

    # DD #4 — loud-fail before clobbering a SIGNED diagnostics file. Regenerating
    # reverts REVIEWER_SIGNOFF to pending; a silent overwrite would let a reviewer
    # vouch for a snapshot that no longer exists. Mirrors the audit's loud-fail.
    if _existing_signoff_state() == "signed" and not args.force:
        print(
            "REFUSING to overwrite a SIGNED diagnostics file: "
            f"{OUT_MD.name} carries REVIEWER_SIGNOFF: signed. Regenerating would revert "
            "it to pending and silently invalidate the KDD-B4 gate that Story 7.5 "
            "train.py reads. Re-run with --force if you intend to re-open review.",
            file=sys.stderr,
        )
        return 2

    diag = build_diagnostics(fingerprint_fill=args.fingerprint_fill)
    OUT_JSON.write_text(json.dumps(diag, indent=2, sort_keys=False) + "\n")
    OUT_MD.write_text(render_markdown(diag))

    hist = diag["tierHistogram"]["computed"]
    print(f"Wrote {OUT_JSON.name} + {OUT_MD.name}")
    print(f"  tiers: {hist}")
    print(
        f"  resolved audio: {diag['resolvedVsTotal']['resolvedAudio']}/{diag['resolvedVsTotal']['total']}"
    )
    print(f"  labelECE (label, not model): {diag['confidenceCalibrationByTier']['labelECE']}")
    print(
        f"  cluster co-assignment consistency: {diag['clusterStability']['coAssignmentConsistency']}"
    )
    print(
        f"  E1 doubled-label candidates (Strong+Solid): {diag['labelOctaveErrorAudit']['doubledCount']}"
    )
    geo = diag["marginalTierDisagreementGeometry"]
    print(
        f"  marginal geometry: {geo['marginalTierCount']} tracks, "
        f"proximity coverage {geo['proximity']['marginalCoverage']} "
        f"(floor {geo['proximity']['coverageFloor']}, met={geo['proximity']['coverageMet']})"
    )
    print(
        f"  reviewer signoff: {diag['reviewerSignoff']['state']} "
        f"(run audit --check-gate to enforce)"
    )
    if diag["driftBlockThreshold"]["blocksTraining"]:
        print(
            "  WARNING: tier drift exceeds the block threshold — training BLOCKED pending review."
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
