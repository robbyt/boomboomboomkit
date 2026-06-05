"""Sample the sealed stratified GiantSteps holdout (Story 7.7 AC6 / Task 1).

Develop-only. Samples ``n=150`` tracks from the GiantSteps corpus with a fixed
seed + stratification by tempo band and (when available) GS style label
(5 tempo bins x the 3 most-common style labels plus an "other" catch-all, so up
to 5x4=20 populated strata; tempo-only 5 bins when no style field exists — DD #7,
never fabricate labels). The n=150 quota is distributed evenly across whatever
strata are populated (no track is dropped to force exactly 15 buckets).

Two artifacts, distinct leak surfaces (DD #10):
  - ``giantsteps-holdout-v2.json`` — local JAMS truth file (``tempo`` namespace,
    per-track BPM). ``.gitignore``'d, NEVER committed (operator-local).
  - ``giantsteps-holdout-v2-manifest.md`` — committed: selection script ref +
    GS corpus version + seed + the SHA256 digest of the sorted
    ``{trackId, sha256(audio)}`` hash-manifest (NO BPM committed).

The seal is temporal + structural (sampled at 7.7-close, fixed-seed,
SHA256-committed; ``holdout_gap.py`` only ever SUBTRACTS these hashes from
Story-7.6 dumps that predate this file) — NOT a filename grep. Re-running with
the same seed re-samples the identical 150 hashes (the reproducibility guard).

Env: ``GIANTSTEPS_CORPUS_PATH``. Fails closed (named error) when unset/missing.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import random
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent
ML_TRAINING = REPO / "_bmad-output" / "ml-training"
sys.path.insert(0, str(ML_TRAINING))

import corpus_common as cc  # noqa: E402  (sys.path insert above)

HOLDOUT_N = 150
TEMPO_BINS = 5
STYLE_LABELS = 3
DEFAULT_SEED = 7700
# Candidate keys a GS ground-truth row might carry a style/genre label under.
# NOTE: musical `key` (e.g. "A minor") is deliberately EXCLUDED — GiantSteps is
# the Tempo+Key dataset and ships a harmonic-key annotation, which is NOT a
# style/genre label; including it would wrongly engage style stratification on
# the key axis instead of the DD #7 tempo-only fallback (code-review).
STYLE_KEYS = ("style", "genre", "subgenre")


class HoldoutSampleError(RuntimeError):
    """Raised when the GS corpus is absent or too small to sample n=150."""


# ---------------------------------------------------------------------------
# Pure stratification (corpus-free, unit-tested)
# ---------------------------------------------------------------------------


def detect_style_key(tracks: list[dict]) -> str | None:
    """Return the first STYLE_KEYS field present + non-empty on a majority of
    tracks, else None (-> tempo-only fallback, DD #7). Never fabricates."""
    for key in STYLE_KEYS:
        present = sum(1 for t in tracks if t.get(key) not in (None, ""))
        if present >= 0.5 * len(tracks) and present > 0:
            return key
    return None


def _quantile_edges(values: list[float], bins: int) -> list[float]:
    """Interior edges for ``bins`` equal-frequency buckets over sorted values."""
    s = sorted(values)
    return [s[min(len(s) - 1, (i * len(s)) // bins)] for i in range(1, bins)]


def tempo_bin(bpm: float, edges: list[float]) -> int:
    """Bucket ``bpm`` into [0, len(edges)] via the interior edges (bisect-right)."""
    lo = 0
    for e in edges:
        if bpm < e:
            return lo
        lo += 1
    return lo


def _top_style_buckets(tracks: list[dict], style_key: str, k: int) -> dict[str, str]:
    """Map each track's raw style value to one of the ``k`` most-common labels,
    or "other" — a stable, deterministic bucketing for stratification."""
    counts: dict[str, int] = {}
    for t in tracks:
        v = str(t.get(style_key, "")).strip().lower()
        if v:
            counts[v] = counts.get(v, 0) + 1
    top = [lbl for lbl, _ in sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))[:k]]
    return {lbl: lbl for lbl in top}


def select_holdout(
    tracks: list[dict], seed: int = DEFAULT_SEED, n: int = HOLDOUT_N
) -> tuple[list[dict], dict]:
    """Deterministically select ``n`` tracks, stratified. Returns
    ``(selected, basis)`` where ``basis`` records the stratification used
    (15-strata style+tempo, or tempo-only fallback). Pure: no audio/IO."""
    if len(tracks) < n:
        raise HoldoutSampleError(f"GS corpus has {len(tracks)} scorable tracks < n={n}")
    # Sort by trackId first so the RNG draws from a stable order (reproducibility).
    tracks = sorted(tracks, key=lambda t: str(t["trackId"]))
    bpms = [float(t["bpm"]) for t in tracks]
    tempo_edges = _quantile_edges(bpms, TEMPO_BINS)
    style_key = detect_style_key(tracks)
    basis: dict[str, object] = {}

    if style_key is not None:
        allowed = set(_top_style_buckets(tracks, style_key, STYLE_LABELS))

        def stratum_of(t: dict) -> tuple[int, str]:
            raw = str(t.get(style_key, "")).strip().lower()
            sb = raw if raw in allowed else "other"  # "other" is a real stratum
            return (tempo_bin(float(t["bpm"]), tempo_edges), sb)

        basis = {"mode": "style+tempo", "styleKey": style_key}
    else:

        def stratum_of(t: dict) -> tuple[int, str]:  # type: ignore[misc]
            return (tempo_bin(float(t["bpm"]), tempo_edges), "")

        basis = {"mode": "tempo-only", "styleKey": None}

    by_stratum: dict[tuple, list[dict]] = {}
    for t in tracks:
        by_stratum.setdefault(stratum_of(t), []).append(t)
    strata = sorted(by_stratum, key=lambda k: (k[0], str(k[1])))
    basis["strata"] = len(strata)

    # Distribute n across populated strata so quotas sum EXACTLY to n (remainder
    # to the first strata) — no global sort+trim that would lexically drop
    # strata-selected picks (code-review). take<=quota keeps the running total
    # <= n; thin strata are made up by a deterministic top-up from the remainder.
    rng = random.Random(seed)
    base, extra = divmod(n, len(strata))
    selected: list[dict] = []
    for i, key in enumerate(strata):
        quota = base + (1 if i < extra else 0)
        pool = sorted(by_stratum[key], key=lambda t: str(t["trackId"]))
        selected.extend(rng.sample(pool, min(quota, len(pool))))
    if len(selected) < n:
        chosen = {str(t["trackId"]) for t in selected}
        remainder = sorted(
            (t for t in tracks if str(t["trackId"]) not in chosen),
            key=lambda t: str(t["trackId"]),
        )
        rng.shuffle(remainder)
        selected.extend(remainder[: n - len(selected)])
    selected = sorted(selected, key=lambda t: str(t["trackId"]))
    assert len(selected) == n
    return selected, basis


def hash_manifest(entries: list[dict]) -> list[dict]:
    """Sorted ``[{trackId, sha256}]`` — the committed-digest basis (no BPM)."""
    return sorted(
        ({"trackId": str(e["trackId"]), "sha256": e["sha256"]} for e in entries),
        key=lambda e: e["trackId"],
    )


def manifest_digest(entries: list[dict]) -> str:
    """SHA256 over the canonical-JSON sorted hash-manifest (DD #10)."""
    canonical = json.dumps(hash_manifest(entries), sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode()).hexdigest()


# ---------------------------------------------------------------------------
# Corpus IO (operator-run; fails closed at dev time)
# ---------------------------------------------------------------------------


def _load_gs_ground_truth(corpus_path: str) -> list[dict]:
    if not corpus_path:
        raise HoldoutSampleError("GIANTSTEPS_CORPUS_PATH is unset (operator-owned run)")
    gt_path = Path(corpus_path) / "giantsteps-tempo-ground-truth.json"
    if not gt_path.exists():
        raise HoldoutSampleError(f"GS ground truth not found at {gt_path}")
    rows = json.loads(gt_path.read_text())
    out: list[dict] = []
    for r in rows:
        fn = r.get("filename") or r.get("trackId") or r.get("id")
        bpm = float(r.get("bpm") or r.get("tempo") or 0.0)
        if fn is None or bpm <= 0:
            continue
        row = {"trackId": str(fn), "bpm": bpm}
        for k in STYLE_KEYS:
            if r.get(k) not in (None, ""):
                row[k] = r[k]
        out.append(row)
    return out


def _resolve_audio(corpus_path: str, track_id: str) -> str | None:
    for sub in ("audio", "", "wav"):
        cand = (
            os.path.join(corpus_path, sub, track_id) if sub else os.path.join(corpus_path, track_id)
        )
        if os.path.isfile(cand):
            return cand
    return None


def main() -> int:
    ap = argparse.ArgumentParser(description="Sample the sealed GiantSteps holdout (Story 7.7)")
    ap.add_argument("--seed", type=int, default=DEFAULT_SEED)
    ap.add_argument("--n", type=int, default=HOLDOUT_N)
    ap.add_argument("--jams-out", type=Path, default=ML_TRAINING / "giantsteps-holdout-v2.json")
    ap.add_argument(
        "--manifest-out", type=Path, default=ML_TRAINING / "giantsteps-holdout-v2-manifest.md"
    )
    ns = ap.parse_args()

    corpus_path = os.environ.get("GIANTSTEPS_CORPUS_PATH", "")
    tracks = _load_gs_ground_truth(corpus_path)
    selected, basis = select_holdout(tracks, seed=ns.seed, n=ns.n)

    entries: list[dict] = []
    for t in selected:
        audio = _resolve_audio(corpus_path, str(t["trackId"]))
        if audio is None:
            raise HoldoutSampleError(f"audio missing for holdout track {t['trackId']}")
        entries.append(
            {
                "trackId": str(t["trackId"]),
                "bpm": float(t["bpm"]),
                "sha256": cc.file_sha256(Path(audio)),
            }
        )

    # (a) local JAMS truth file (gitignored).
    jams = {
        "fixture_schema": "jams-tempo-giantsteps-holdout-v2",
        "jams_namespace": "tempo",
        "description": "Sealed n=150 GiantSteps holdout (Story 7.7). LOCAL ONLY — gitignored.",
        "stratification": basis,
        "seed": ns.seed,
        "annotations": [
            {
                "file_metadata": {"identifiers": {"track_id": e["trackId"]}},
                "namespace": "tempo",
                "data": [{"time": 0.0, "duration": None, "value": e["bpm"], "confidence": 1.0}],
            }
            for e in entries
        ],
    }
    ns.jams_out.write_text(json.dumps(jams, indent=2, allow_nan=False))

    # (b) committed manifest (hash digest only, no BPM).
    digest = manifest_digest(entries)
    corpus_version = os.path.basename(os.path.normpath(corpus_path))
    md = (
        "# GiantSteps holdout v2 — reproducibility manifest (Story 7.7 AC6 / DD #10)\n\n"
        f"- selection_script: `scripts/sample-giantsteps-holdout.py`\n"
        f"- gs_corpus_version: `{corpus_version}`\n"
        f"- seed: `{ns.seed}`\n"
        f"- n: `{len(entries)}`\n"
        f"- stratification: `{basis}`\n"
        f"- hash_manifest_sha256: `{digest}`\n\n"
        "The hash-list itself (`giantsteps-holdout-v2.json`) is `.gitignore`'d. "
        "Re-running with the same seed re-samples the identical 150 hashes "
        "(reproducibility guard); `holdout_gap.py` only subtracts these from "
        "Story-7.6 dumps that predate this file (the temporal/structural seal).\n"
    )
    ns.manifest_out.write_text(md)
    print(f"holdout: {len(entries)} tracks, basis={basis['mode']}, digest={digest[:12]}…")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
