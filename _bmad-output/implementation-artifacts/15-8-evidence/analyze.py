# /// script
# requires-python = ">=3.10"
# ///
"""Per-clip warp inventory of a DAWproject project.xml (Story 15.8 evidence).

Usage:
  uv run analyze.py <project.xml> <out.csv>

`project.xml` is the file inside the .dawproject zip (unzip it first). One CSV row
per `Warps` element: the warp list, per-segment BPMs, how far any middle warp sits
from the line through the last segment, the outer and inner `Clip` attributes, and
how many warps sit near an integer beat or a bar line. `corpus-clips.csv` and
`other-clips.csv` next to this script were produced by it from the corpus
`.dawproject` and `other-bpms.dawproject`. Stdlib only.
"""

import collections
import csv
import sys
import xml.etree.ElementTree as ET


def ancestors(parent: dict, el: ET.Element):
    while el in parent:
        el = parent[el]
        yield el


def attr(el: ET.Element | None, key: str) -> str | None:
    return el.get(key) if el is not None else None


def segment_bpm(a: tuple[float, float], b: tuple[float, float]) -> float:
    if b[1] == a[1]:
        return float("nan")
    return (b[0] - a[0]) / (b[1] - a[1]) * 60


def near_bar(t: float) -> bool:
    return abs(t / 4 - round(t / 4)) * 4 <= 0.02


def near_int(t: float) -> bool:
    return abs(t - round(t)) <= 0.02


def analyze(path: str) -> tuple[float, list[dict]]:
    root = ET.parse(path).getroot()
    tempo_el = root.find(".//Transport/Tempo")
    tempo = float(attr(tempo_el, "value") or "nan")
    tracks = {t.get("id"): t.get("name") for t in root.iter("Track")}
    parent = {child: p for p in root.iter() for child in p}
    rows = []
    for w in root.iter("Warps"):
        anc = list(ancestors(parent, w))
        clips = [e for e in anc if e.tag == "Clip"]  # inner first
        inner = clips[0] if clips else None
        outer = clips[1] if len(clips) > 1 else None
        lanes = next((e for e in anc if e.tag == "Lanes" and e.get("track")), None)
        in_arrangement = any(e.tag == "Arrangement" for e in anc)
        pts = [
            (float(x.get("time", "nan")), float(x.get("contentTime", "nan")))
            for x in w.findall("Warp")
        ]
        file_el = w.find("Audio/File")
        audio = w.find("Audio")
        b0, s0 = pts[0]
        bl, sl = pts[-1]
        bpm_first_to_last = (bl - b0) / (sl - s0) * 60
        bp, sp = pts[-2]
        bpm_last = (bl - bp) / (sl - sp) * 60
        segs = [segment_bpm(pts[i], pts[i + 1]) for i in range(len(pts) - 1)]
        nonorigin = pts[1:]
        mid = pts[1:-1]
        duration = attr(audio, "duration")
        rows.append(
            {
                "track": tracks.get(lanes.get("track")) if lanes is not None else None,
                "in_arrangement": in_arrangement,
                "file": attr(file_el, "path") or "",
                "audio_duration_s": duration,
                "sample_rate": attr(audio, "sampleRate"),
                "algorithm": attr(audio, "algorithm"),
                "n_warps": len(pts),
                "warps": ";".join(f"({t:.6f},{c:.6f})" for t, c in pts),
                "bpm_last_segment": round(bpm_last, 4),
                "bpm_first_to_last": round(bpm_first_to_last, 4),
                "bpm_diff": round(bpm_last - bpm_first_to_last, 4),
                "segment_bpms": ";".join(f"{x:.4f}" for x in segs),
                "mid_pred_beats_at_project_tempo": ";".join(
                    f"{c * tempo / 60:.4f}" for _, c in mid
                ),
                "mid_pred_beats_at_last_segment_bpm": ";".join(
                    f"{c * bpm_last / 60:.4f}" for _, c in mid
                ),
                "mid_beat_offset_vs_last_seg": ";".join(
                    f"{t - c * bpm_last / 60:.4f}" for t, c in mid
                ),
                "mid_time_offset_s_vs_last_seg": ";".join(
                    f"{(c - t * 60 / bpm_last) * 1000:.2f}ms" for t, c in mid
                ),
                "last_vs_audio_dur_s": round(sl - float(duration), 6)
                if duration is not None
                else None,
                "outer_time": attr(outer, "time"),
                "outer_duration": attr(outer, "duration"),
                "outer_playStart": attr(outer, "playStart"),
                "outer_loopStart": attr(outer, "loopStart"),
                "outer_loopEnd": attr(outer, "loopEnd"),
                "outer_name": attr(outer, "name"),
                "outer_enable": attr(outer, "enable"),
                "inner_time": attr(inner, "time"),
                "inner_duration": attr(inner, "duration"),
                "inner_playStart": attr(inner, "playStart"),
                "inner_loopStart": attr(inner, "loopStart"),
                "inner_loopEnd": attr(inner, "loopEnd"),
                "nonorigin_near_int_beat": sum(1 for t, _ in nonorigin if near_int(t)),
                "nonorigin_near_bar": sum(1 for t, _ in nonorigin if near_bar(t)),
                "mid_near_int_beat": sum(1 for t, _ in mid if near_int(t)),
                "mid_near_bar": sum(1 for t, _ in mid if near_bar(t)),
                "first_seg_beats": round(pts[1][0] - pts[0][0], 4),
                "last_seg_beats": round(bl - bp, 4),
                "last_seg_start_s": round(sp, 6),
                "last_seg_end_s": round(sl, 6),
            }
        )
    return tempo, rows


def main() -> None:
    path, out = sys.argv[1], sys.argv[2]
    tempo, rows = analyze(path)
    with open(out, "w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    print("tempo", tempo, "warps", len(rows))
    print("n_warps dist", collections.Counter(r["n_warps"] for r in rows))
    print("in_arrangement", collections.Counter(r["in_arrangement"] for r in rows))


if __name__ == "__main__":
    main()
