"""Cohort selection fixtures; the real freeze is exercised by the operator."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import sys
import zipfile
from pathlib import Path
from types import SimpleNamespace

import pytest

from test_build_eval_corpus import _gen, _mint, bec, ws as corpus_ws  # noqa: F401

SOURCE = Path(__file__).resolve().parents[1] / "build-bundle-gate-cohort.py"
spec = importlib.util.spec_from_file_location("bundle_gate_cohort", SOURCE)
assert spec is not None and spec.loader is not None
cohort = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = cohort
spec.loader.exec_module(cohort)
UNSOUND_FLAGS = ("audio_defect", "tempo_unstable", "irresolvable", "duplicate_of")


def fixture(tmp_path: Path):
    members = ["e1-aaaa"]
    good = tmp_path / "good.wav"
    member = tmp_path / "member.wav"
    good.write_bytes(b"good")
    member.write_bytes(b"member")
    files = {"e1-aaaa": member, "e2-bbbb": good}
    hashes = {}
    entries = {}
    for rid, path in files.items():
        hashes[rid] = hashlib.sha256(path.read_bytes()).hexdigest()
        entries[rid] = {"rowId": rid, "source": "pool", "contentSha256": hashes[rid]}
    annotations = {
        "e1-aaaa": {"verified_bpm": 130.0},
        "e2-bbbb": {"verified_bpm": 131.0},
    }
    module = SimpleNamespace(
        BAND_NAMES=("120-140",),
        band_of=lambda bpm: "120-140" if 120 <= bpm < 140 else None,
        load_annotations=lambda _state, _band: annotations,
        _resolve_audio=lambda entry, _root: files[entry["rowId"]],
        sha256_file=lambda path: hashlib.sha256(path.read_bytes()).hexdigest(),
    )
    state = SimpleNamespace(
        by_row_id=entries,
        pools={"pool_audio_root": str(tmp_path)},
        sequence_row_ids=lambda _band: list(entries),
    )
    archive = tmp_path / "source.dawproject"
    with zipfile.ZipFile(archive, "w") as zf:
        zf.writestr("audio/e2-bbbb.wav", good.read_bytes())
    state.daw_archive = archive
    state.daw_references = {"e2-bbbb": {"audio/e2-bbbb.wav"}}
    membership = {"120-140": {"members": members}}
    signed = {
        "entries": [
            {
                "file_metadata": {"identifiers": {"row_id": "e1-aaaa"}},
                "annotations": [{"data": [{"value": 130.0}]}],
            }
        ]
    }
    track = SimpleNamespace(problem=None, bpm=131.0)
    tracks = {"e2-bbbb": track}
    return module, state, membership, signed, tracks, annotations, files


def freeze(module, state, membership, signed, tracks):
    with zipfile.ZipFile(state.daw_archive) as archive:
        return cohort.make_cohort(
            module, state, membership, signed, tracks, archive, state.daw_references
        )


def test_signed_label_and_blinded_extra(tmp_path: Path):
    module, state, membership, signed, tracks, _ann, _files = fixture(tmp_path)
    tracks["e1-aaaa"] = SimpleNamespace(problem="stale clip", bpm=None)
    tracks["x1-cccc"] = SimpleNamespace(problem=None, bpm=90.0)
    result = freeze(module, state, membership, signed, tracks)
    assert [r["category"] for r in result["tracks"]] == [
        "locked-12.7-member",
        "blinded-e-extra",
    ]
    assert [r["groundTruthBPM"] for r in result["tracks"]] == [130, 131]
    assert not any(r["trackId"].startswith("x1-") for r in result["tracks"])
    assert result["exclusions"] == {}


@pytest.mark.parametrize("flag", UNSOUND_FLAGS)
def test_unsound_and_duplicate_extra_excluded(tmp_path: Path, flag: str):
    module, state, membership, signed, tracks, annotations, _files = fixture(tmp_path)
    annotations["e2-bbbb"][flag] = "e1-aaaa" if flag == "duplicate_of" else True
    result = freeze(module, state, membership, signed, tracks)
    assert len(result["tracks"]) == 1
    assert sum(result["exclusions"].values()) == 1


def test_missing_or_stale_audio_refuses(tmp_path: Path):
    module, state, membership, signed, tracks, _ann, files = fixture(tmp_path)
    files["e2-bbbb"].write_bytes(b"changed")
    with pytest.raises(ValueError, match="hash missing or changed"):
        freeze(module, state, membership, signed, tracks)
    files["e2-bbbb"].unlink()
    with pytest.raises(ValueError, match="source audio missing"):
        freeze(module, state, membership, signed, tracks)


def test_daw_stale_clip_or_label_refuses(tmp_path: Path):
    module, state, membership, signed, tracks, annotations, _files = fixture(tmp_path)
    tracks["e2-bbbb"].bpm = 132.0
    with pytest.raises(ValueError, match="DAW and annotation disagree"):
        freeze(module, state, membership, signed, tracks)
    tracks["e2-bbbb"].bpm = 131.0
    annotations["e2-bbbb"].pop("verified_bpm")
    with pytest.raises(ValueError, match="verified tempo"):
        freeze(module, state, membership, signed, tracks)


def test_daw_audio_must_match_committed_source(tmp_path: Path):
    module, state, membership, signed, tracks, _ann, _files = fixture(tmp_path)
    with zipfile.ZipFile(state.daw_archive, "w") as zf:
        zf.writestr("audio/e2-bbbb.wav", b"different")
    with pytest.raises(ValueError, match="DAW audio differs"):
        freeze(module, state, membership, signed, tracks)
    state.daw_references["e2-bbbb"] = {"audio/e2-bbbb-other.wav"}
    with pytest.raises(ValueError, match="DAW audio reference differs"):
        freeze(module, state, membership, signed, tracks)


@pytest.mark.parametrize("altered", ["pool", "draw"])
@pytest.mark.usefixtures("corpus_ws")
def test_committed_pool_and_draw_drift_refuses_before_selection(altered: str):
    assert _mint() == 0
    path = bec.pools_path(_gen()) if altered == "pool" else bec.draws_path(_gen())
    doc = json.loads(path.read_text())
    doc["tampered"] = True
    path.write_text(json.dumps(doc))
    with pytest.raises(bec.HarnessError, match=f"digest mismatch for {path.name}"):
        cohort.validated_state(bec)
