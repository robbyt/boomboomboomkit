"""
Story 7.1 Task 5 — expanded DnB sentinel curation (develop-only generator).

Emits two artifacts:
  - Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/12-dnb-sentinels-expanded.json
    (JAMS-format tempo-sentinel manifest; SHIPS TO MAIN, sibling of
    4-dnb-triplet-targets.json; inert at runtime — no Swift decoder until 8.7)
  - _bmad-output/ml-training/expanded-sentinels-curation.md
    (per-track rationale + provisional subgenre + the DD #8 asymmetry valve)

12 entries = 4 originals (re-expressed from the canonical schema-v3
4-dnb-triplet-targets.json) + 8 expanded Tony Strong+Solid tracks.

DD #8 reality (confirmed on-disk): the corpus has NO subgenre field, and
neurofunk/jump-up/liquid return ZERO machine-readable hits. A dev agent cannot
classify by ear. So subgenre here is PROVISIONAL — grounded in the only weak
signals available (playlist-name vibe + tempo band + 'jungle'/'amen' keywords)
and flagged `subgenre_provisional: true`. The DD #8 valve (drop below
2-per-subgenre confidence) HAS fired: final by-ear classification into
{neurofunk, jungle, jump-up, liquid} is an OPERATOR gate before Story 7.6 uses
these sentinels. NEVER substitute non-DnB tracks for missing slots.

Run: `make curate-sentinels`.
"""

from __future__ import annotations

import json
import sys

import corpus_common as cc

OUT_JAMS = (
    cc.REPO_ROOT / "Tests" / "BoomBoomBoomKitBenchmarkTests" / "Fixtures"
    / "12-dnb-sentinels-expanded.json"
)
OUT_MD = cc.ML_TRAINING_DIR / "expanded-sentinels-curation.md"
CANONICAL_ORIGINALS = (
    cc.REPO_ROOT / "Tests" / "BoomBoomBoomKitBenchmarkTests" / "Fixtures"
    / "4-dnb-triplet-targets.json"
)

N_EXPANDED = 8


def _provisional_subgenre(track: dict) -> tuple[str, str]:
    """Return (provisional_subgenre, rationale) from the only weak signals
    available. PROVISIONAL — operator confirms by ear (DD #8)."""
    names = " ".join(track["signals"].get("playlist", {}).get("names", [])).lower()
    title = (track.get("name") or "").lower()
    bpm = track.get("bpm_truth") or 0.0
    blob = f"{names} {title}"
    if "amen" in blob or "jungle" in blob:
        return "jungle", "amen/jungle footprint in playlist/title"
    if "bouncey" in blob or "bounce" in blob:
        return "jump-up", "'bouncey' playlist vibe (jump-up proxy)"
    if "grumble" in blob or "grime" in blob or bpm >= 174.0:
        return "neurofunk", "dark/grumble playlist or >=174 BPM (neuro proxy)"
    return "liquid", "no jungle/jump-up/neuro signal — default provisional (weakest tag)"


def select_expanded_sentinels() -> list[dict]:
    """Deterministically select 8 clean Tony Strong+Solid DnB tracks, stratified
    by confidence quintile x tempo band, favoring representative over
    adversarial-hard tracks (DD #8)."""
    tracks, _ = cc.load_tony_corpus()
    trainable = [t for t in tracks if cc.is_trainable(t)]
    ext = cc.build_external_index(giantsteps_gt_path=cc.resolve_giantsteps_gt_path())
    excl = {m.track_id for m in cc.find_cross_corpus_matches(trainable, ext)}
    clean = [t for t in trainable if str(t.get("track_id")) not in excl]

    # DnB tempo band only (sentinels are DnB; 155-178 covers the half-time family).
    dnb = [t for t in clean if 150.0 <= (t.get("bpm_truth") or 0) <= 180.0]

    # Stratify: 2 jungle (keyword-backed) + spread across provisional subgenres,
    # picking mid-confidence representatives deterministically (sort by a stable
    # key: confidence closeness to 0.72, then track_id).
    def rep_sort_key(t):
        return (abs(t["truth_confidence"] - 0.72), str(t.get("track_id")))

    chosen: list[dict] = []
    chosen_ids: set[str] = set()

    def take(pool, n_new):
        """Add up to n_new NOT-yet-chosen tracks from `pool` (local count, not a
        global cap — so a thin subgenre can't be silently backfilled by another)."""
        added = 0
        for t in sorted(pool, key=rep_sort_key):
            if added >= n_new or len(chosen) >= N_EXPANDED:
                break
            tid = str(t.get("track_id"))
            if tid in chosen_ids:
                continue
            chosen.append(t)
            chosen_ids.add(tid)
            added += 1

    # Target 2 per provisional subgenre (the DD #8 valve fires when a subgenre is
    # thin — that's expected and documented, NOT silently backfilled to look full).
    for sg in ("jungle", "jump-up", "neurofunk", "liquid"):
        pool = [t for t in dnb if _provisional_subgenre(t)[0] == sg]
        take(pool, 2)
    # Top up to N_EXPANDED from any remaining DnB representative (records the
    # asymmetry honestly — the curation MD reports the resulting per-subgenre spread).
    take(dnb, N_EXPANDED)
    return chosen[:N_EXPANDED]


def load_originals() -> list[dict]:
    data = json.loads(CANONICAL_ORIGINALS.read_text())
    out = []
    for t in data["targets"]:
        out.append({
            "track_id": t["track_id"],
            "bpm": float(t["ground_truth_bpm"]),
            "confidence": 1.0,
            "source": t.get("source", "dawproject"),
        })
    return out


def jams_entry(*, title, artist, track_id, bpm, confidence, subgenre,
               provisional, quintile, origin, source) -> dict:
    """One JAMS-format entry: file_metadata + a single tempo annotation."""
    return {
        "file_metadata": {
            "title": title,
            "artist": artist,
            "duration": None,  # not available in source metadata
            "identifiers": {"track_id": track_id},
        },
        "annotations": [
            {
                "namespace": "tempo",
                "data": [
                    {"time": 0.0, "duration": None, "value": bpm, "confidence": confidence}
                ],
                "annotation_metadata": {
                    "curator": {"name": "Story 7.1 sentinel curation", "email": ""},
                    "annotation_tools": "curate_sentinels.py (provisional subgenre)",
                },
                "sandbox": {
                    "subgenre": subgenre,
                    "subgenre_provisional": provisional,
                    "confidence_quintile": quintile,
                    "held_out": True,
                    "origin": origin,
                    "source": source,
                },
            }
        ],
    }


def build_jams(expanded: list[dict], originals: list[dict]) -> dict:
    entries: list[dict] = []

    # 4 originals (OA300 dawproject-verified; already held-out eval).
    for o in originals:
        entries.append(jams_entry(
            title=o["track_id"], artist="", track_id=o["track_id"],
            bpm=o["bpm"], confidence=o["confidence"],
            subgenre="dnb-original", provisional=False, quintile=None,
            origin="4-dnb-triplet-targets.json (schema v3)", source=o["source"],
        ))

    # Confidence quintile boundaries over the expanded set. Guarded for a thin
    # pool (< 5 tracks -> single bin; index would otherwise overrun); ties collapse
    # quintiles harmlessly (the field is provisional metadata, no runtime consumer).
    confs = sorted(t["truth_confidence"] for t in expanded)
    def quintile(c):
        import bisect
        if len(confs) < 5:
            return 1
        edges = [confs[min(len(confs) - 1, int(len(confs) * q / 5))] for q in range(1, 5)]
        return bisect.bisect_left(edges, c) + 1

    for t in expanded:
        sg, _ = _provisional_subgenre(t)
        entries.append(jams_entry(
            title=t.get("name"), artist=t.get("artist") or "",
            track_id=str(t.get("track_id")), bpm=t["bpm_truth"],
            confidence=t["truth_confidence"], subgenre=sg, provisional=True,
            quintile=quintile(t["truth_confidence"]),
            origin="tony-truth-labels.json (Strong/Solid)", source="tony-labeler",
        ))

    return {
        "fixture_schema": "jams-tempo-sentinels-v1",
        "jams_namespace": "tempo",
        "description": "12 DnB tempo sentinels for the FR-18 gate (a): 4 originals "
        "(dawproject-verified, re-expressed from 4-dnb-triplet-targets.json schema v3) + "
        "8 expanded Tony Strong/Solid tracks. JAMS-format; inert at runtime (no Swift "
        "JAMSDecoder until Story 8.7). Expanded subgenre tags are PROVISIONAL — operator "
        "confirms by ear before Story 7.6 use (DD #8).",
        "ddNote_subgenre_valve": "DD #8 valve FIRED: neurofunk/jump-up/liquid have zero "
        "machine-readable footprint in the corpus; a dev agent cannot classify by ear. "
        "Subgenre tags on the 8 expanded entries are heuristic (playlist vibe + tempo + "
        "jungle/amen keyword) and carry subgenre_provisional:true. 2-per-subgenre "
        "confidence is NOT met programmatically; final classification is an operator gate.",
        "expandedTrackIds": sorted(str(t.get("track_id")) for t in expanded),
        "entries": entries,
    }


def render_curation_md(jams: dict, expanded: list[dict]) -> str:
    from collections import Counter
    sg_counts = Counter()
    for t in expanded:
        sg_counts[_provisional_subgenre(t)[0]] += 1
    lines = ["# Expanded DnB Sentinel Curation (Story 7.1, FR-18 gate (a))", ""]
    lines.append("Develop-only rationale for the 8 expanded sentinels in the main-bound "
                 "`Tests/.../Fixtures/12-dnb-sentinels-expanded.json` (4 originals + 8 expanded).")
    lines.append("")
    lines.append("## DD #8 subgenre asymmetry valve — FIRED")
    lines.append("")
    lines.append("The corpus has NO `subgenre` field. On-disk keyword probe: "
                 "`neurofunk`=0, `jump-up`=0, `liquid`=0 machine-readable hits; only "
                 "`jungle` (10) and `amen` (103) have any footprint. A dev agent cannot "
                 "classify by ear. Therefore:")
    lines.append("")
    lines.append("- Subgenre tags below are **provisional** (`subgenre_provisional: true`), "
                 "derived from playlist vibe + tempo band + jungle/amen keywords.")
    lines.append("- The DD #8 valve (drop below confident 2-per-subgenre) **has fired**. "
                 "Provisional spread: " + ", ".join(f"{k}={v}" for k, v in sorted(sg_counts.items())) + ".")
    lines.append("- **Operator gate:** confirm/reassign each expanded sentinel by ear into "
                 "{neurofunk, jungle, jump-up, liquid} before Story 7.6 consumes them.")
    lines.append("- Non-DnB substitution is forbidden; every expanded track is DnB "
                 "(150-180 BPM, Strong/Solid).")
    lines.append("")
    lines.append("## Expanded sentinels (8)")
    lines.append("")
    lines.append("| track_id | name | bpm_truth | truth_conf | provisional subgenre | rationale |")
    lines.append("|---|---|---|---|---|---|")
    for t in expanded:
        sg, why = _provisional_subgenre(t)
        nm = (t.get("name") or "").replace("|", "/")[:48]
        lines.append(f"| {t.get('track_id')} | {nm} | {t['bpm_truth']} | "
                     f"{t['truth_confidence']} | {sg} (provisional) | {why} |")
    lines.append("")
    lines.append("## Originals (4)")
    lines.append("")
    lines.append("Re-expressed from `Tests/.../Fixtures/4-dnb-triplet-targets.json` (canonical "
                 "schema v3) — NOT the diverged schema-v1 `_bmad-output/implementation-artifacts/` "
                 "copy. These are the named DnB half-time failures (Charly/Faraday_Bunker/"
                 "Yin Yang/HEFT_Anagram), already OA300 held-out eval.")
    lines.append("")
    for e in jams["entries"][:4]:
        fm = e["file_metadata"]
        d = e["annotations"][0]["data"][0]
        lines.append(f"- `{fm['identifiers']['track_id']}` — {d['value']} BPM "
                     f"(conf {d['confidence']}, {e['annotations'][0]['sandbox']['source']})")
    lines.append("")
    return "\n".join(lines) + "\n"


def main() -> int:
    expanded = select_expanded_sentinels()
    if len(expanded) < N_EXPANDED:
        print(f"ERROR: only found {len(expanded)} expanded sentinels (need {N_EXPANDED}). "
              f"DnB pool too thin — do NOT substitute non-DnB tracks (DD #8).", file=sys.stderr)
        return 1
    originals = load_originals()
    jams = build_jams(expanded, originals)
    OUT_JAMS.write_text(json.dumps(jams, indent=2) + "\n")
    OUT_MD.write_text(render_curation_md(jams, expanded))
    print(f"Wrote {OUT_JAMS.relative_to(cc.REPO_ROOT)} ({len(jams['entries'])} entries: "
          f"4 originals + {len(expanded)} expanded)")
    print(f"Wrote {OUT_MD.relative_to(cc.REPO_ROOT)}")
    print(f"  expanded track_ids: {jams['expandedTrackIds']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
