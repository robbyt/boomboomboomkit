"""Plan the fixed-time training crops once, before training (Story 15.5, develop-only).

Ranks every masked-mel pretraining, `tony.train` and `tony.val` song over its
first 120 s with the ported rhythm score, and writes `crop-plan.json` to the run
directory. For every song the plan records the kept crops (start frame, start
seconds, rhythm score) or the reason it was skipped, and it fixes the whole
schedule: the kept crop each song uses in each of the 30 pretraining and 60
fine-tuning epochs (drawn once from the seed), and each validation song's crop
(its top-ranked one). Training reads only this file and never runs the rhythm
score.

  uv run python -m fixed_time.plan --out-dir fixed-time-runs/seed_42
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import random
import sys
import time
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path
from typing import Any

import fixed_time  # noqa: F401  (sys.path setup for the sibling training modules)
from fixed_time import features as ft

ML_TRAINING_DIR = Path(__file__).resolve().parent.parent
DEFAULT_OUT_DIR = ML_TRAINING_DIR / "fixed-time-runs" / "seed_42"
PLAN_FILE = "crop-plan.json"
PLAN_SCHEMA = "fixed-time-crop-plan-v2"
LISTS = ("pretrain", "train", "val")

SKIP_DECODE = "decode-failed"


class PlanError(RuntimeError):
    """The crop plan is missing or does not match the run; training refuses."""


def schedule_recipe() -> dict[str, int]:
    """The recipe values the schedule depends on."""
    from fixed_time.train_fixed_time import RECIPE

    return {
        "seed": int(RECIPE["seed"]),
        "pretrainEpochs": int(RECIPE["pretrainEpochs"]),
        "epochCount": int(RECIPE["epochCount"]),
    }


def list_hash(keys: list[str]) -> str:
    """sha256 of a song list, in order (order fixes the augmentation seeding)."""
    return hashlib.sha256(json.dumps(keys, separators=(",", ":")).encode()).hexdigest()


def song_lists(subset: int | None = None) -> dict[str, list[dict[str, Any]]]:
    """The three song lists training reads, as {list: [{key, path, trackId?, bpm?}]}.

    `key` is the song's path as the training loader lists it."""
    from ablation_locator import build_labeled_records, build_pretrain_audio_paths

    def cut(xs: list) -> list:
        return xs[:subset] if subset else xs

    out: dict[str, list[dict[str, Any]]] = {
        "pretrain": [{"key": str(p), "path": str(p)} for p in cut(build_pretrain_audio_paths())]
    }
    for which in ("train", "val"):
        out[which] = [
            {"key": str(r.audio_path), "path": str(r.audio_path), "trackId": r.track_id}
            for r in cut(build_labeled_records(which))
        ]
    return out


def song_list_hashes(lists: dict[str, list[dict[str, Any]]]) -> dict[str, dict[str, Any]]:
    return {
        name: {"count": len(songs), "sha256": list_hash([s["key"] for s in songs])}
        for name, songs in lists.items()
    }


# ---------------------------------------------------------------------------
# Ranking
# ---------------------------------------------------------------------------


def rank_audio(audio) -> dict[str, Any]:
    """First 120 s of 44.1 kHz PCM -> the ranking record for one song."""
    audio = audio[: ft.TRAINING_MAX_SAMPLES]
    n_frames, starts, scores = ft.candidate_scores(audio)
    by_start = dict(zip(starts, scores))
    kept = ft.rank_crops(starts, scores)
    skipped = None
    if not starts:
        skipped = ft.ABSTAIN_SHORT
    elif not kept:
        skipped = ft.ABSTAIN_NO_RHYTHM
    return {
        "frames": n_frames,
        "candidateCrops": len(starts),
        "bestRhythmScore": max(scores) if scores else None,
        "kept": [
            {
                "startFrame": s,
                "startSeconds": ft.start_seconds(s),
                "rhythmScore": by_start[s],
            }
            for s in kept
        ],
        "skipped": skipped,
    }


def file_identity(path: str) -> dict[str, int] | None:
    """The audio file's size and modification time, or None when it is missing."""
    try:
        st = os.stat(path)
    except OSError:
        return None
    return {"fileSize": st.st_size, "fileMtimeNs": st.st_mtime_ns}


def _rank_path(path: str) -> dict[str, Any]:
    """Worker: decode one file the way training does and rank its crops. The file's
    size and mtime are read before the decode, so they describe the bytes ranked."""
    from ablation_locator import _load_pcm

    identity = file_identity(path) or {"fileSize": None, "fileMtimeNs": None}
    audio = _load_pcm(Path(path))
    if audio is None:
        return {
            **identity,
            "frames": 0,
            "candidateCrops": 0,
            "bestRhythmScore": None,
            "kept": [],
            "skipped": SKIP_DECODE,
        }
    return {**identity, **rank_audio(audio)}


def rank_paths(paths: list[str], num_workers: int) -> dict[str, dict[str, Any]]:
    """Rank each unique path once, across processes when num_workers > 1."""
    unique = list(dict.fromkeys(paths))
    t0 = time.time()
    results: dict[str, dict[str, Any]] = {}
    if num_workers <= 1:
        for i, p in enumerate(unique):
            results[p] = _rank_path(p)
            if (i + 1) % 250 == 0:
                print(f"[plan] ranked {i + 1}/{len(unique)} ({time.time() - t0:.0f}s)")
    else:
        with ProcessPoolExecutor(max_workers=num_workers) as pool:
            for i, (p, r) in enumerate(zip(unique, pool.map(_rank_path, unique, chunksize=8))):
                results[p] = r
                if (i + 1) % 250 == 0:
                    print(f"[plan] ranked {i + 1}/{len(unique)} ({time.time() - t0:.0f}s)")
    print(f"[plan] ranked {len(unique)} songs in {time.time() - t0:.0f}s")
    return results


# ---------------------------------------------------------------------------
# Schedule
# ---------------------------------------------------------------------------


def draw_crop(kept: list[int], *, seed: int, phase: str, epoch: int, key: str) -> int:
    """The kept crop a song uses in one epoch, drawn from (seed, phase, epoch, song).

    String seeds hash with sha512, so the draw is independent of list order and
    of PYTHONHASHSEED."""
    if not kept:
        raise ValueError(f"song {key} has no kept crop to draw")
    return random.Random(f"fixed-time-plan|{seed}|{phase}|{epoch}|{key}").choice(kept)


def build_plan(
    lists: dict[str, list[dict[str, Any]]],
    rankings: dict[str, dict[str, Any]],
    recipe: dict[str, int],
) -> dict[str, Any]:
    """Assemble the plan from song lists and their rankings (pure)."""
    seed = recipe["seed"]
    songs: dict[str, list[dict[str, Any]]] = {}
    skipped: dict[str, dict[str, int]] = {}
    for name in LISTS:
        entries = []
        counts: dict[str, int] = {}
        for s in lists[name]:
            r = rankings[s["path"]]
            kept = [k["startFrame"] for k in r["kept"]]
            entry: dict[str, Any] = {**s, **r}
            if r["skipped"]:
                counts[r["skipped"]] = counts.get(r["skipped"], 0) + 1
            elif name == "pretrain":
                entry["schedule"] = [
                    draw_crop(kept, seed=seed, phase="pretrain", epoch=e, key=s["key"])
                    for e in range(recipe["pretrainEpochs"])
                ]
            elif name == "train":
                entry["schedule"] = [
                    draw_crop(kept, seed=seed, phase="finetune", epoch=e, key=s["key"])
                    for e in range(recipe["epochCount"])
                ]
            else:
                entry["validationCrop"] = kept[0]
            entries.append(entry)
        songs[name] = entries
        skipped[name] = counts
    return {
        "planSchema": PLAN_SCHEMA,
        "inputContract": ft.INPUT_CONTRACT,
        "rankingRule": ft.ranking_rule(),
        "recipe": dict(recipe),
        "songLists": song_list_hashes(lists),
        "keptSongs": {n: sum(1 for e in songs[n] if not e["skipped"]) for n in LISTS},
        "skippedSongs": skipped,
        "scheduleRule": (
            "pretraining and fine-tuning: each epoch every kept song uses one of its kept "
            "crops, drawn once by random.Random('fixed-time-plan|seed|phase|epoch|path')."
            "choice(kept); validation: the top-ranked crop"
        ),
        "songs": songs,
    }


# ---------------------------------------------------------------------------
# Reading the plan
# ---------------------------------------------------------------------------


def validate_plan(
    plan: dict[str, Any],
    lists: dict[str, list[dict[str, Any]]],
    recipe: dict[str, int],
    identity=file_identity,
) -> None:
    """Refuse a plan that does not match the run. Checks the schema, input contract,
    ranking rule, recipe values and song-list hashes against the run; that each
    song list in `songs` hashes to the plan's own summary; that every song's audio
    file still has the size and mtime the plan recorded (`identity(path)`); that
    each kept pretraining and train song has a full schedule drawn only from its
    kept crops; and that each kept validation song has a validation crop among its
    kept crops. Raises PlanError naming every problem."""
    problems: list[str] = []
    if plan.get("planSchema") != PLAN_SCHEMA:
        problems.append(f"plan schema {plan.get('planSchema')!r}, expected {PLAN_SCHEMA!r}")
    if plan.get("inputContract") != ft.INPUT_CONTRACT:
        problems.append(
            f"plan input contract {plan.get('inputContract')!r}, expected {ft.INPUT_CONTRACT!r}"
        )
    if plan.get("rankingRule") != ft.ranking_rule():
        problems.append("plan ranking rule differs from fixed_time.features.ranking_rule()")
    if plan.get("recipe") != recipe:
        problems.append(f"plan recipe {plan.get('recipe')} differs from the run's {recipe}")
    expected = song_list_hashes(lists)
    summary = plan.get("songLists") or {}
    for name in LISTS:
        if summary.get(name) != expected[name]:
            problems.append(
                f"{name} song list differs: plan {summary.get(name)}, run {expected[name]}"
            )
    if problems:
        raise PlanError("crop plan does not match the run: " + "; ".join(problems))

    songs = plan.get("songs") or {}
    epochs = {"pretrain": recipe["pretrainEpochs"], "train": recipe["epochCount"]}
    for name in LISTS:
        entries = songs.get(name) or []
        recorded = song_list_hashes({name: entries})[name]
        if recorded != summary[name]:
            problems.append(f"{name}: the songs in the plan do not hash to its own song list")
        changed, unscheduled, off_plan = [], [], []
        for e in entries:
            now = identity(e["path"])
            if now is None or now != {
                "fileSize": e.get("fileSize"),
                "fileMtimeNs": e.get("fileMtimeNs"),
            }:
                changed.append(e["key"])
            if e.get("skipped"):
                continue
            kept = {k["startFrame"] for k in e.get("kept", [])}
            if name == "val":
                if e.get("validationCrop") is None:
                    unscheduled.append(e["key"])
                elif e["validationCrop"] not in kept:
                    off_plan.append(e["key"])
            else:
                schedule = e.get("schedule") or []
                if len(schedule) != epochs[name]:
                    unscheduled.append(e["key"])
                elif any(start not in kept for start in schedule):
                    off_plan.append(e["key"])
        if changed:
            problems.append(
                f"{name}: {len(changed)} audio files changed or vanished since planning "
                f"(size or mtime differs), e.g. {changed[:3]}"
            )
        if unscheduled:
            what = "a validation crop" if name == "val" else f"a {epochs.get(name)}-epoch schedule"
            problems.append(
                f"{name}: {len(unscheduled)} kept songs lack {what}, e.g. {unscheduled[:3]}"
            )
        if off_plan:
            problems.append(
                f"{name}: {len(off_plan)} songs use a crop that is not one of their kept crops, "
                f"e.g. {off_plan[:3]}"
            )
    if problems:
        raise PlanError("crop plan does not match the run: " + "; ".join(problems))


def load_plan(out_dir: Path) -> tuple[dict[str, Any], str]:
    """(plan, sha256 of the plan file); PlanError when absent or not valid JSON."""
    path = out_dir / PLAN_FILE
    if not path.is_file():
        raise PlanError(f"no crop plan at {path}; run `make fixed-time-plan` first")
    data = path.read_bytes()
    try:
        plan = json.loads(data)
    except (json.JSONDecodeError, UnicodeDecodeError) as e:
        raise PlanError(f"crop plan at {path} is not valid JSON: {e}") from e
    if not isinstance(plan, dict):
        raise PlanError(f"crop plan at {path} is not a JSON object")
    return plan, hashlib.sha256(data).hexdigest()


def write_json_atomic(path: Path, doc: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f"{path.name}.tmp{os.getpid()}")
    tmp.write_text(json.dumps(doc, indent=1, sort_keys=True) + "\n")
    tmp.replace(path)


def make_plan(subset: int | None, num_workers: int) -> dict[str, Any]:
    lists = song_lists(subset)
    paths = [s["path"] for name in LISTS for s in lists[name]]
    rankings = rank_paths(paths, num_workers)
    return build_plan(lists, rankings, schedule_recipe())


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Plan the fixed-time training crops (Story 15.5).")
    p.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    p.add_argument("--num-workers", type=int, default=4)
    args = p.parse_args(argv if argv is not None else sys.argv[1:])
    plan = make_plan(None, args.num_workers)
    path = args.out_dir / PLAN_FILE
    write_json_atomic(path, plan)
    print(
        f"[plan] kept songs {plan['keptSongs']}, skipped {plan['skippedSongs']} -> {path} "
        f"(sha256 {hashlib.sha256(path.read_bytes()).hexdigest()})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
