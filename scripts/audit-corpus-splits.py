#!/usr/bin/env python3
"""
Story 7.1 Task 4 — corpus-split contamination audit (develop-only).

This script IS the regression harness for AC4/AC5/AC6/AC7 and the executable
gate for AC8. Its scope/contract is FIXED in this header so Stories 7.5/7.6 can
reason about exactly what "zero contamination" covered:

  GATING checks (any failure => non-zero exit):
    1. schema guard            — corpus_splits.json MUST be schema_version 2 with
                                 the `tony` namespace; a flat v1 train/val/test
                                 shape fails loud (DD #2).
    2. split disjointness      — tony.train / tony.val / tony.leaveArtistOut.heldOut
                                 are pairwise disjoint by track_id (AC4).
    3. artist disjointness     — leaveArtistOut.heldOutArtists and trainArtists are
                                 disjoint on the canonical artist key (AC6);
                                 empty-artist tracks excluded from the assertion (DD #4).
    4. cross-corpus residual   — NO tony.train/val track normalized-title-matches an
                                 OA300/GiantSteps eval track (AC5 — exclusion must
                                 have already removed them).
    5. sentinel holdout        — the 8 expanded sentinel track_ids are absent from
                                 tony.train/val (AC7).
    6. near-dup fingerprint     — DEFENSIVE, REPORT-ONLY (never gates the exit
       (DD #3)                   code, per DD #3 "never the sole auto-exclusion
                                 signal"). Standardizes the 52-d MFCC+chroma
                                 timbral signature per-dimension across the cohort,
                                 then cosine; surfaces the highest-similarity
                                 boundary-crossing pairs as REVIEW FLAGS for a
                                 human. Method = librosa MFCC+chroma timbral
                                 (Chromaprint/fpcalc unavailable in-env;
                                 pre-authorized fallback). BLIND SPOT: coarse
                                 statistical signature — see
                                 corpus_common.compute_fingerprint. Cached to
                                 tony-corpus/fingerprint-cache.npz (method-versioned).
                                 The GATE against same-recording near-dups is the
                                 metadata layer: build_tony_splits groups by
                                 canonical artist AND normalized title, so no
                                 same-artist/same-title pair can cross a boundary.

  --check-gate                 — KDD-B4 (AC8): exit non-zero while the reviewer
                                 signoff in corpus-diagnostics-v1.md is `pending`.
  --check-sentinels-against F  — JAMS schema-validate F + confirm zero contamination
                                 vs tony.train/val (AC7).
  --no-fingerprint             — omit the defensive fingerprint pass. Prints a LOUD
                                 notice (this is NOT a silent narrowing of "zero
                                 contamination" — the metadata gates still run).

Run: `make audit-corpus-splits`  (or `uv run python scripts/audit-corpus-splits.py`).
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
ML_TRAINING_DIR = REPO_ROOT / "_bmad-output" / "ml-training"
sys.path.insert(0, str(ML_TRAINING_DIR))

import corpus_common as cc  # noqa: E402  (runtime sys.path insert above)

SPLITS_PATH = ML_TRAINING_DIR / "corpus_splits.json"
DIAGNOSTICS_MD = ML_TRAINING_DIR / "corpus-diagnostics-v1.md"

# Cosine (over per-dimension-standardized timbral vectors) above which a
# boundary-crossing pair is surfaced as a REVIEW FLAG. Report-only — the
# fingerprint never gates the exit code (DD #3).
NEAR_DUP_REVIEW = 0.97
NEAR_DUP_REPORT_TOP = 20


class AuditResult:
    def __init__(self) -> None:
        self.failures: list[str] = []
        self.warnings: list[str] = []
        self.info: list[str] = []

    def fail(self, msg: str) -> None:
        self.failures.append(msg)

    def warn(self, msg: str) -> None:
        self.warnings.append(msg)

    def note(self, msg: str) -> None:
        self.info.append(msg)

    def report(self) -> int:
        for m in self.info:
            print(f"  [ok]   {m}")
        for m in self.warnings:
            print(f"  [warn] {m}")
        for m in self.failures:
            print(f"  [FAIL] {m}")
        if self.failures:
            print(f"\nAUDIT FAILED — {len(self.failures)} contamination/gate issue(s).")
            return 1
        print(f"\nAUDIT PASSED — 0 failures, {len(self.warnings)} review flag(s).")
        return 0


# ---------------------------------------------------------------------------
# Structural gates
# ---------------------------------------------------------------------------


def load_splits(res: AuditResult) -> dict | None:
    if not SPLITS_PATH.exists():
        res.fail(f"corpus_splits.json not found at {SPLITS_PATH} — run `make ml-splits`.")
        return None
    data = json.loads(SPLITS_PATH.read_text())
    # Gate 1: schema guard.
    if data.get("schema_version") != 2 or "tony" not in data:
        res.fail(
            "schema guard: corpus_splits.json is not schema_version 2 with a `tony` "
            "namespace (a stale flat v1 train/val/test shape must fail loud, DD #2)."
        )
        return None
    res.note("schema guard: schema_version 2 + tony namespace present.")
    return data


def check_disjointness(tony: dict, res: AuditResult) -> None:
    train = set(tony.get("train", []))
    val = set(tony.get("val", []))
    held = set(tony.get("leaveArtistOut", {}).get("heldOutTrackIds", []))
    # Non-empty train AND val (an over-aggressive manual-dup-exclusions.json could
    # otherwise empty val with no failure; Story 7.5's validation loader needs it).
    if not train:
        res.fail("tony.train is empty.")
    if not val:
        res.fail(
            "tony.val is empty — Story 7.5 validation cannot run. Over-exclusion in "
            "manual-dup-exclusions.json or a too-small trainable set is the likely cause."
        )
    for a, b, na, nb in [
        (train, val, "train", "val"),
        (train, held, "train", "leaveArtistOut"),
        (val, held, "val", "leaveArtistOut"),
    ]:
        overlap = a & b
        if overlap:
            res.fail(
                f"disjointness: {len(overlap)} track_ids in BOTH {na} and {nb}: "
                f"{sorted(overlap)[:5]}"
            )
    if not res.failures:
        res.note(
            f"disjointness: train({len(train)}) / val({len(val)}) / "
            f"heldOut({len(held)}) pairwise disjoint."
        )


def check_artist_disjointness(tony: dict, res: AuditResult) -> None:
    lao = tony.get("leaveArtistOut", {})
    train_artists = set(lao.get("trainArtists", []))
    held_artists = set(lao.get("heldOutArtists", []))
    overlap = train_artists & held_artists
    if overlap:
        res.fail(
            f"artist disjointness (AC6): {len(overlap)} canonical artist keys in BOTH "
            f"trainArtists and heldOutArtists: {sorted(overlap)[:5]}"
        )
    else:
        res.note(
            f"artist disjointness: {len(held_artists)} held-out artists disjoint from "
            f"{len(train_artists)} train artists on the canonical key."
        )
    # Held-out sizing (AC6: >= 10% of cleaned trainable).
    held_n = len(lao.get("heldOutTrackIds", []))
    min_req = lao.get("minRequired", 0)
    if held_n < min_req:
        res.fail(f"leave-artist-out sizing: held-out {held_n} < required {min_req} (>= 10%).")
    else:
        res.note(f"leave-artist-out sizing: {held_n} held-out tracks >= {min_req} (10% floor).")


def _tony_by_id(tracks: list[dict]) -> dict[str, dict]:
    return {str(t.get("track_id")): t for t in tracks}


def check_cross_corpus_residual(tony: dict, tracks: list[dict], res: AuditResult) -> None:
    by_id = _tony_by_id(tracks)
    train_val = list(tony.get("train", [])) + list(tony.get("val", []))
    records = [by_id[i] for i in train_val if i in by_id]
    ext = cc.build_external_index(giantsteps_gt_path=cc.resolve_giantsteps_gt_path())
    residual = cc.find_cross_corpus_matches(records, ext)
    if residual:
        res.fail(
            f"cross-corpus residual (AC5): {len(residual)} tony.train/val tracks still "
            f"match an external-eval title (exclusion failed): "
            f"{[m.tony_name for m in residual][:5]}"
        )
    else:
        res.note(
            f"cross-corpus residual: 0 tony.train/val tracks match OA300/GiantSteps "
            f"(checked {ext.corpora_checked})."
        )
    # Surface over-exclusion: conservative title-matching could remove a large
    # slice via generic external titles. Warn (don't fail) past 5% so the operator
    # can eyeball whether generics are doing the excluding.
    xc = tony.get("excludedCrossCorpus", {})
    before = tony.get("trainable_before_exclusion", 0)
    if before and xc.get("count", 0) / before > 0.05:
        res.warn(
            f"cross-corpus exclusion removed {xc['count']}/{before} "
            f"({xc['count'] / before:.1%}) of trainable — review excludedCrossCorpus.matches "
            f"for generic-title false positives (conservative over-exclusion is by design)."
        )
    if "giantsteps" not in ext.corpora_checked:
        # Fail-closed: AC5 requires coverage of BOTH OA300 and GiantSteps. Missing
        # GS env means the gate cannot certify Tony<->GiantSteps, so it must NOT
        # pass silently. (GS is numeric-ID-named so title-overlap risk is
        # structurally low, but the gate's job is to certify, not assume.)
        res.fail(
            "cross-corpus residual (AC5): GiantSteps GT not resolved "
            "(GIANTSTEPS_CORPUS_PATH unset) — coverage cannot be certified. Set "
            "GIANTSTEPS_CORPUS_PATH (the `make audit-corpus-splits` target passes it) "
            "and re-run."
        )


def check_sentinel_holdout(tony: dict, res: AuditResult) -> None:
    sent = set(tony.get("sentinelHoldout", {}).get("expandedSentinelIds", []))
    if not sent:
        res.warn(
            "sentinel holdout: no expanded sentinels recorded in the split "
            "(run `make curate-sentinels` then `make ml-splits`)."
        )
        return
    train_val = set(tony.get("train", [])) | set(tony.get("val", []))
    leak = sent & train_val
    if leak:
        res.fail(
            f"sentinel holdout (AC7): {len(leak)} expanded sentinels appear in "
            f"tony.train/val: {sorted(leak)}"
        )
    else:
        res.note(f"sentinel holdout: all {len(sent)} expanded sentinels held out of train/val.")


# ---------------------------------------------------------------------------
# Near-dup fingerprint pass (DD #3)
# ---------------------------------------------------------------------------


def fingerprint_pass(tony: dict, tracks: list[dict], res: AuditResult) -> None:
    import numpy as np

    by_id = _tony_by_id(tracks)
    label: dict[str, str] = {}
    for i in tony.get("train", []):
        label[i] = "train"
    for i in tony.get("val", []):
        label[i] = "val"
    for i in tony.get("leaveArtistOut", {}).get("heldOutTrackIds", []):
        label[i] = "leaveArtistOut"

    ids = [i for i in label if i in by_id and by_id[i].get("local_path")]
    # Load cache (method-versioned: a method change invalidates stale vectors).
    cache: dict[str, "np.ndarray"] = {}
    if cc.FINGERPRINT_CACHE.exists():
        z = np.load(cc.FINGERPRINT_CACHE, allow_pickle=True)
        cached_method = str(z["__method__"]) if "__method__" in z.files else "unknown"
        if cached_method == cc.FINGERPRINT_METHOD:
            for k in z.files:
                if k == "__method__":
                    continue
                v = z[k]
                # Drop any non-finite cached vector (a corrupt entry would yield
                # NaN cosine and silently SUPPRESS review flags); it is recomputed.
                if np.all(np.isfinite(v)):
                    cache[k] = v
        else:
            res.note(
                f"fingerprint cache method {cached_method!r} != {cc.FINGERPRINT_METHOD!r} "
                f"— rebuilding cache."
            )

    vecs: dict[str, "np.ndarray"] = {}
    resolved = 0
    unresolved: list[str] = []
    new_cache_entries = 0
    for tid in ids:
        path = by_id[tid]["local_path"]
        if not os.path.exists(path):
            unresolved.append(tid)
            continue
        ckey = cc.content_hash(path)
        if ckey in cache:
            vecs[tid] = cache[ckey]
            resolved += 1
            continue
        fp = cc.compute_fingerprint(path)
        if fp is None:
            unresolved.append(tid)
            continue
        cache[ckey] = fp
        vecs[tid] = fp
        resolved += 1
        new_cache_entries += 1

    if new_cache_entries:
        # ty over-strictly assumes `**cache` could supply savez_compressed's
        # `allow_pickle: bool` kwarg; cache keys are content-hash hexdigests, never
        # "allow_pickle", so this is a false positive.
        np.savez_compressed(
            cc.FINGERPRINT_CACHE,
            __method__=cc.FINGERPRINT_METHOD,
            **cache,  # ty: ignore[invalid-argument-type]
        )

    res.note(
        f"fingerprint pass: {resolved}/{len(ids)} split tracks fingerprinted "
        f"({len(unresolved)} undecodable), method={cc.FINGERPRINT_METHOD} (REPORT-ONLY)."
    )
    if unresolved:
        res.warn(
            f"fingerprint pass: {len(unresolved)} tracks could not be fingerprinted "
            f"(reported, not silently dropped): {unresolved[:5]}"
        )

    tid_list = list(vecs.keys())
    if len(tid_list) < 2:
        return
    # Standardize per-dimension across the cohort, then unit-norm, then cosine.
    M = np.stack([vecs[t] for t in tid_list]).astype(np.float64)  # (N, 52) raw
    mu = M.mean(axis=0)
    sd = M.std(axis=0)
    sd[sd < 1e-9] = 1.0
    Z = (M - mu) / sd
    norms = np.linalg.norm(Z, axis=1, keepdims=True)
    norms[norms < 1e-12] = 1.0
    Zn = Z / norms
    sims = Zn @ Zn.T

    n = len(tid_list)
    flagged: list[tuple[float, str]] = []
    for a in range(n):
        for b in range(a + 1, n):
            la, lb = label[tid_list[a]], label[tid_list[b]]
            if la == lb:
                continue  # same split — not a boundary crossing
            s = float(sims[a, b])
            if s >= NEAR_DUP_REVIEW:
                ida, idb = tid_list[a], tid_list[b]
                na = by_id[ida].get("name", "")[:28]
                nb = by_id[idb].get("name", "")[:28]
                # Include track_ids so the operator can copy a confirmed dup's id
                # straight into manual-dup-exclusions.json (KDD-B4 signoff loop).
                flagged.append((s, f"{s:.3f} {la}[{ida}]:{na!r} <-> {lb}[{idb}]:{nb!r}"))
    flagged.sort(reverse=True)
    if flagged:
        top = [m for _, m in flagged[:NEAR_DUP_REPORT_TOP]]
        res.warn(
            f"near-dup fingerprint: {len(flagged)} boundary-crossing pair(s) with "
            f"standardized cosine >= {NEAR_DUP_REVIEW} — REVIEW FLAGS only (NOT gated; "
            f"coarse-signature blind spot, DD #3). Same-artist/same-title near-dups are "
            f"already blocked by the metadata split grouping. Top: {top}"
        )
    else:
        res.note(
            f"near-dup fingerprint: 0 boundary-crossing pairs >= {NEAR_DUP_REVIEW} "
            f"(review threshold). Metadata grouping is the same-recording gate."
        )


# ---------------------------------------------------------------------------
# AC7 — JAMS sentinel schema validation
# ---------------------------------------------------------------------------


def check_sentinels_against(jams_path: Path, tony: dict, res: AuditResult) -> None:
    if not jams_path.exists():
        res.fail(f"--check-sentinels-against: {jams_path} not found.")
        return
    try:
        data = json.loads(jams_path.read_text())
    except json.JSONDecodeError as exc:
        res.fail(f"sentinel JAMS: invalid JSON: {exc}")
        return
    entries = data.get("entries")
    if not isinstance(entries, list) or not entries:
        res.fail("sentinel JAMS: no `entries` list.")
        return
    bad = 0
    for e in entries:
        anns = e.get("annotations")
        if not (isinstance(e.get("file_metadata"), dict) and isinstance(anns, list) and anns):
            bad += 1
            continue
        ann = anns[0]
        if ann.get("namespace") != "tempo":
            bad += 1
            continue
        d = ann.get("data")
        if not (isinstance(d, list) and d and "value" in d[0] and "confidence" in d[0]):
            bad += 1
    if bad:
        res.fail(
            f"sentinel JAMS schema: {bad}/{len(entries)} entries malformed "
            f"(need file_metadata + tempo annotation with data[].value+confidence)."
        )
    else:
        res.note(
            f"sentinel JAMS schema: all {len(entries)} entries valid "
            f"(namespace=tempo, value+confidence present)."
        )
    # Holdout: expanded sentinel IDs must not be in train/val.
    expanded = {str(x) for x in data.get("expandedTrackIds", [])}
    train_val = set(tony.get("train", [])) | set(tony.get("val", []))
    leak = expanded & train_val
    if leak:
        res.fail(
            f"sentinel holdout (AC7): {len(leak)} expanded sentinels in tony.train/val: "
            f"{sorted(leak)}"
        )
    else:
        res.note(f"sentinel holdout: {len(expanded)} expanded sentinels confined out of train/val.")


# ---------------------------------------------------------------------------
# AC8 — KDD-B4 reviewer-signoff gate
# ---------------------------------------------------------------------------


def check_gate(res: AuditResult) -> None:
    if not DIAGNOSTICS_MD.exists():
        res.fail(
            f"--check-gate: {DIAGNOSTICS_MD.name} not found — diagnostics not produced "
            f"(run `make corpus-diagnostics`)."
        )
        return
    text = DIAGNOSTICS_MD.read_text()
    # Parse the SINGLE canonical marker (anchored, not a naive substring scan that
    # an instructional sentence containing "REVIEWER_SIGNOFF: signed" could trip).
    markers = re.findall(r"REVIEWER_SIGNOFF:\s*(signed|pending)", text)
    if len(markers) != 1:
        res.fail(
            f"--check-gate: expected exactly ONE REVIEWER_SIGNOFF marker in "
            f"{DIAGNOSTICS_MD.name}, found {len(markers)} — refusing to interpret an "
            f"ambiguous gate state."
        )
        return
    state = markers[0]
    if state == "signed":
        res.note("KDD-B4 gate: REVIEWER_SIGNOFF: signed — corpus reviewed, training unblocked.")
    else:
        res.fail(
            "KDD-B4 gate (AC8): REVIEWER_SIGNOFF: pending. 7.1 'done' = evidence "
            "assembled + review pending, NOT corpus-safe-to-train. The operator must "
            "transcribe the checklist and flip the marker to `signed`. This blocks "
            "Story 7.5 train.py, not 7.1 close."
        )


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Story 7.1 corpus-split contamination audit.")
    ap.add_argument(
        "--check-gate",
        action="store_true",
        help="Exit non-zero while the KDD-B4 reviewer signoff is pending (AC8).",
    )
    ap.add_argument(
        "--check-sentinels-against",
        metavar="FILE",
        default=None,
        help="JAMS schema-validate FILE + confirm sentinel holdout (AC7).",
    )
    ap.add_argument(
        "--no-fingerprint",
        action="store_true",
        help="Omit the defensive near-dup fingerprint pass (prints a loud notice).",
    )
    args = ap.parse_args(argv)

    res = AuditResult()
    print("Story 7.1 corpus-split contamination audit")
    print("=" * 52)

    # --check-gate is a standalone gate (no split needed beyond the md).
    if args.check_gate:
        check_gate(res)
        return res.report()

    data = load_splits(res)
    if data is None:
        return res.report()
    tony = data["tony"]
    tracks, _ = cc.load_tony_corpus()

    check_disjointness(tony, res)
    check_artist_disjointness(tony, res)
    check_cross_corpus_residual(tony, tracks, res)
    check_sentinel_holdout(tony, res)

    if args.check_sentinels_against:
        check_sentinels_against(Path(args.check_sentinels_against), tony, res)

    if args.no_fingerprint:
        res.warn(
            "FINGERPRINT PASS SKIPPED (--no-fingerprint): defensive near-dup coverage "
            "NOT run this invocation. Metadata gates still enforced. Re-run without the "
            "flag for full DD #3 coverage."
        )
    else:
        fingerprint_pass(tony, tracks, res)

    return res.report()


if __name__ == "__main__":
    sys.exit(main())
