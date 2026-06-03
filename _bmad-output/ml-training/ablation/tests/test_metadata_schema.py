"""AC4 — Guardrail-1/3 metadata schema assertions (Story 7.3).

Run: `make ablation-tests` (or
`uv run --project _bmad-output/ml-training pytest _bmad-output/ml-training/ablation/tests/`).
"""

from __future__ import annotations

import os
import sys

import pytest

_ABLATION = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_ML = os.path.dirname(_ABLATION)
sys.path.insert(0, _ML)
sys.path.insert(0, _ABLATION)

import ablation_common as common  # noqa: E402

REQUIRED_FIELDS = {
    "metadataSchema",
    "architecture",
    "seed",
    "epochCount",
    "corpusVersionHash",
    "harnessGitSha",
    "featureSetVersion",
    "weightingProfile",
    "trainingVariant",
    "promotable",
    "scaffoldingNote",
}


def _md(variant="supervisedAugmented", **kw):
    return common.build_metadata(
        variant=variant, seed=42, epoch_count=60, weighting_profile="uniform", **kw
    )


def test_guardrail1_promotable_false_and_exact_scaffolding_note():
    md = _md()
    assert md["promotable"] is False
    assert md["scaffoldingNote"] == "v1 features — FR-18 metrics do not transfer to v2"


def test_required_fields_present():
    md = _md()
    assert REQUIRED_FIELDS.issubset(md.keys())


def test_feature_set_version_is_v1():
    assert _md()["featureSetVersion"] == "v1"


def test_metadata_schema_discriminator():
    # Distinct from model.py's schema_version:1 so a blind json.load can't confuse them.
    assert _md()["metadataSchema"] == "ablation-v1"


def test_architecture_is_tempocnn():
    assert _md()["architecture"] == "TempoCNN"


@pytest.mark.parametrize("wp", ["uniform", "sub-band-emphasis"])
def test_weighting_profile_accepted(wp):
    assert (
        common.build_metadata(
            variant="supervisedAugmented", seed=1, epoch_count=1, weighting_profile=wp
        )["weightingProfile"]
        == wp
    )


@pytest.mark.parametrize("variant", ["supervisedAugmented", "maskedMelPretrain"])
def test_training_variant_accepted(variant):
    md = common.build_metadata(
        variant=variant,
        seed=1,
        epoch_count=1,
        weighting_profile="uniform",
        pretrain_epochs=30,
        mask_ratio=0.15,
    )
    assert md["trainingVariant"] == variant


def test_invalid_variant_rejected():
    with pytest.raises(ValueError):
        common.build_metadata(variant="bogus", seed=1, epoch_count=1, weighting_profile="uniform")


def test_invalid_weighting_profile_rejected():
    # AC4 — the metadata schema must reject an out-of-set weightingProfile (the
    # CLI choices guard is not the schema layer the AC names).
    with pytest.raises(ValueError):
        common.build_metadata(
            variant="supervisedAugmented", seed=1, epoch_count=1, weighting_profile="garbage"
        )


def test_masked_mel_records_pretrain_fields():
    md = _md(variant="maskedMelPretrain", pretrain_epochs=30, mask_ratio=0.15)
    assert md["pretrainEpochs"] == 30
    assert md["maskRatio"] == 0.15


def test_corpus_version_hash_is_stable_hex():
    # Deterministic 64-char sha256 hex over the concrete corpus state (DD #8).
    if not common.CORPUS_SPLITS.exists():
        pytest.skip("corpus_splits.json absent (develop-local)")
    h1 = common.compute_corpus_version_hash()
    h2 = common.compute_corpus_version_hash()
    assert h1 == h2
    assert len(h1) == 64 and all(c in "0123456789abcdef" for c in h1)
