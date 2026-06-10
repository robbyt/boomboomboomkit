"""Build the FR-18 runtime-producer input manifest (Story 7.6, Task 7).

Develop-only, stdlib-only. ALL corpus / sentinel / Tony-audio resolution lives
here (Python-side) so the main-bound Swift ``FR18EvaluationHarnessTests`` stays
corpus-agnostic and grep-clean (Story 7.6 AC2 / AC11 / DD #2). Emits a single
``fr18-eval-input.json`` listing every audio file to evaluate, tagged by corpus:
``oa300`` / ``giantsteps`` / ``sentinel`` / ``tony_val`` / ``tony_lao`` /
``marginal``. The same track list is reused for each seed (only ``BNNS_MODEL_URL``
changes per seed); ``--seed`` stamps the manifest for the producer's seed dir.

Env: ``OA300_CORPUS_PATH``, ``GIANTSTEPS_CORPUS_PATH``, ``TONY_AUDIO_ROOT``.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
FIXTURES = REPO / "Tests" / "BoomBoomBoomKitBenchmarkTests" / "Fixtures"


def _exists(path: str) -> bool:
    return bool(path) and os.path.isfile(path)


def _tony_audio_path(local_path: str) -> str:
    """Resolve a Tony track's audio. Prefer the absolute ``local_path`` from
    ``tony-truth-labels.json``; if it doesn't exist on this host and
    ``TONY_AUDIO_ROOT`` is set, rebase the basename under that root (lets an
    operator relocate the corpus via the advertised env var). Returns "" if
    nothing resolves."""
    if _exists(local_path):
        return local_path
    root = os.environ.get("TONY_AUDIO_ROOT", "")
    if root and local_path:
        cand = os.path.join(root, os.path.basename(local_path))
        if _exists(cand):
            return cand
    return ""


def resolve_oa300(corpus_path: str) -> list[dict]:
    if not corpus_path:
        return []
    gt = json.loads((FIXTURES / "oa300-ground-truth.json").read_text())
    out: list[dict] = []
    for t in gt:
        sub = t.get("subdir")
        audio = (
            os.path.join(corpus_path, sub, t["filename"])
            if sub
            else os.path.join(corpus_path, t["filename"])
        )
        if _exists(audio):
            out.append(
                {
                    "trackId": t.get("title") or t["filename"],
                    "audioPath": audio,
                    "groundTruthBPM": float(t["bpm"]),
                    "corpus": "oa300",
                }
            )
    return out


def resolve_giantsteps(corpus_path: str) -> list[dict]:
    if not corpus_path:
        return []
    gt_path = Path(corpus_path) / "giantsteps-tempo-ground-truth.json"
    if not gt_path.exists():
        return []
    gt = json.loads(gt_path.read_text())
    out: list[dict] = []
    for t in gt:
        fn = t.get("filename") or t.get("trackId") or t.get("id")
        if fn is None:
            continue
        # GiantSteps audio commonly lives under <corpus>/audio/<file>.{wav,mp3,…}.
        bpm = float(t.get("bpm") or t.get("tempo") or 0.0)
        if bpm <= 0:
            continue  # skip un-scorable ground truth (would inflate the denominator)
        for sub in ("audio", "", "wav"):
            cand = (
                os.path.join(corpus_path, sub, str(fn))
                if sub
                else os.path.join(corpus_path, str(fn))
            )
            if _exists(cand):
                out.append(
                    {
                        "trackId": str(fn),
                        "audioPath": cand,
                        "groundTruthBPM": bpm,
                        "corpus": "giantsteps",
                    }
                )
                break
    return out


def _tony_index() -> dict[str, dict]:
    labels = json.loads((HERE / "tony-corpus" / "tony-truth-labels.json").read_text())
    if isinstance(labels, list):
        rows = labels
    elif isinstance(labels, dict) and isinstance(labels.get("tracks"), list):
        rows = labels["tracks"]
    else:
        rows = next((v for v in labels.values() if isinstance(v, list)), [])
    return {str(r["track_id"]): r for r in rows}


def _match_tony_by_name(title: str, tony_idx: dict[str, dict]) -> dict | None:
    """Fallback: find a Tony row whose `name` is a (non-trivial) substring of the
    sentinel title. Resolves originals whose track_id is a long title that does
    not key into OA300 or a numeric Tony id (e.g. the "Charly" sentinel)."""
    title_l = title.lower()
    for row in tony_idx.values():
        name = str(row.get("name", "")).strip()
        if len(name) >= 8 and name.lower() in title_l:
            return row
    return None


def resolve_sentinels(oa300_corpus: str, tony_idx: dict[str, dict]) -> list[dict]:
    sent = json.loads((FIXTURES / "12-dnb-sentinels-expanded.json").read_text())
    oa300 = {t["trackId"]: t for t in resolve_oa300(oa300_corpus)}
    out: list[dict] = []
    for entry in sent.get("entries", []):
        tid = entry["file_metadata"]["identifiers"]["track_id"]
        bpm = float(entry["annotations"][0]["data"][0]["value"])
        # 4 originals live in OA300 (by title); 8 expanded are Tony track IDs;
        # any residual original resolves via a Tony name-substring fallback.
        audio: str | None = None
        if tid in oa300:
            audio = oa300[tid]["audioPath"]
        elif tid in tony_idx and _tony_audio_path(tony_idx[tid].get("local_path", "")):
            audio = _tony_audio_path(tony_idx[tid].get("local_path", ""))
        else:
            match = _match_tony_by_name(entry["file_metadata"].get("title", ""), tony_idx)
            if match is not None and _tony_audio_path(match.get("local_path", "")):
                audio = _tony_audio_path(match.get("local_path", ""))
        if audio is not None:
            out.append(
                {"trackId": tid, "audioPath": audio, "groundTruthBPM": bpm, "corpus": "sentinel"}
            )
    return out


def resolve_tony(track_ids: list[str], corpus_tag: str, tony_idx: dict[str, dict]) -> list[dict]:
    out: list[dict] = []
    for tid in track_ids:
        row = tony_idx.get(str(tid))
        if row is None:
            continue
        path = _tony_audio_path(row.get("local_path", ""))
        bpm = row.get("bpm_truth")
        if path and bpm is not None:
            out.append(
                {
                    "trackId": str(tid),
                    "audioPath": path,
                    "groundTruthBPM": float(bpm),
                    "corpus": corpus_tag,
                }
            )
    return out


def build_tracks() -> list[dict]:
    oa300_corpus = os.environ.get("OA300_CORPUS_PATH", "")
    gs_corpus = os.environ.get("GIANTSTEPS_CORPUS_PATH", "")
    tony_idx = _tony_index()
    splits = json.loads((HERE / "corpus_splits.json").read_text())
    tony = splits.get("tony", {})
    lao_ids = tony.get("leaveArtistOut", {}).get("heldOutTrackIds", [])
    val_ids = tony.get("val", [])
    watchlist = json.loads((HERE / "marginal-watchlist.json").read_text())
    # Explicit "watchlist" key — the first list-valued key is `_consumedBy`,
    # not the records (code-review BLOCKER).
    if isinstance(watchlist, list):
        wl_rows = watchlist
    elif isinstance(watchlist, dict) and isinstance(watchlist.get("watchlist"), list):
        wl_rows = watchlist["watchlist"]
    else:
        wl_rows = []
    marginal_ids = [str(r["track_id"]) for r in wl_rows]

    tracks: list[dict] = []
    tracks += resolve_oa300(oa300_corpus)
    tracks += resolve_giantsteps(gs_corpus)
    tracks += resolve_sentinels(oa300_corpus, tony_idx)
    tracks += resolve_tony(val_ids, "tony_val", tony_idx)
    tracks += resolve_tony(lao_ids, "tony_lao", tony_idx)
    tracks += resolve_tony(marginal_ids, "marginal", tony_idx)
    return tracks


def main() -> int:
    parser = argparse.ArgumentParser(description="Build FR-18 eval input manifest (Story 7.6)")
    parser.add_argument("--seed", type=int, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--subset", type=int, default=0, help="cap per-corpus track count (smoke)")
    ns = parser.parse_args()

    tracks = build_tracks()
    if ns.subset > 0:
        capped: list[dict] = []
        per: dict[str, int] = {}
        for t in tracks:
            c = t["corpus"]
            if per.get(c, 0) < ns.subset:
                capped.append(t)
                per[c] = per.get(c, 0) + 1
        tracks = capped

    counts: dict[str, int] = {}
    for t in tracks:
        counts[t["corpus"]] = counts.get(t["corpus"], 0) + 1
    ns.output.write_text(json.dumps({"seed": ns.seed, "tracks": tracks}, indent=2))
    print(f"FR-18 input: {len(tracks)} tracks {counts} -> {ns.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
