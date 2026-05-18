"""pytest suite for the convert tool.

Hybrid pattern:
- Subprocess test (using sys.executable, NOT `uv run`) for the canonical
  consumer-facing flow — exercises argparse, real exit codes, cross-process
  state isolation.
- In-process tests using convert_main(argv) for everything else — faster,
  hermetic, integrates cleanly with pytest's capsys for stderr assertions.

Run via: `cd tools/coreml-convert && uv run pytest tests/`

The conftest.py at tools/coreml-convert/conftest.py prepends that directory
onto sys.path at collection time, so this module imports siblings cleanly.
"""

from __future__ import annotations

import importlib.util
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
import pytest
import torch

THIS_DIR = Path(__file__).resolve().parent
PARENT_DIR = THIS_DIR.parent

# Sibling imports work because conftest.py prepends PARENT_DIR onto sys.path.
from reference_arch import build_reference_model, TempoCNN  # noqa: E402
from convert import main as convert_main  # noqa: E402


def _make_checkpoint(tmp_path: Path, name: str, seed: int = 0) -> Path:
    torch.manual_seed(seed)
    model = build_reference_model()
    ckpt = tmp_path / f"{name}.pt"
    torch.save(model.state_dict(), ckpt)
    return ckpt


@pytest.fixture
def synthetic_checkpoint(tmp_path: Path) -> Path:
    return _make_checkpoint(tmp_path, "synthetic", seed=0)


def _run_convert(argv: list[str]) -> int:
    """Invoke convert.main in-process. Returns exit code."""
    return convert_main(argv)


def test_reference_round_trip(synthetic_checkpoint: Path, tmp_path: Path) -> None:
    """SUBPROCESS smoke test: argparse + real exit code + cross-process state.

    Plus AC #9 numerical equivalence (P13) checked via the loaded CoreML model.
    Uses sys.executable so the test never depends on `uv` being on PATH (P14).
    """
    convert_py = PARENT_DIR / "convert.py"
    output = tmp_path / "test_round_trip.mlpackage"
    proc = subprocess.run(
        [
            sys.executable, str(convert_py),
            "--checkpoint", str(synthetic_checkpoint),
            "--arch", "reference",
            "--output", str(output),
            "--validate",
        ],
        cwd=str(PARENT_DIR),
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0, (
        f"convert failed:\nstderr:\n{proc.stderr}\nstdout:\n{proc.stdout}"
    )
    assert output.exists()

    import coremltools as ct
    loaded = ct.models.MLModel(str(output))
    spec = loaded.get_spec()
    assert [i.name for i in spec.description.input] == ["input"]
    assert [o.name for o in spec.description.output] == ["output"]

    np.random.seed(0)
    x = np.random.randn(1, 1, 128, 512).astype(np.float32)
    pred = loaded.predict({"input": x})
    out = np.asarray(pred["output"]).reshape(-1)
    assert out.shape == (256,)
    assert np.all(np.isfinite(out))

    # P13: numerical equivalence eager-vs-CoreML at the test layer.
    eager_model = build_reference_model().eval()
    eager_model.load_state_dict(
        torch.load(str(synthetic_checkpoint), weights_only=True)
    )
    with torch.no_grad():
        eager_out = eager_model(torch.from_numpy(x)).cpu().numpy().reshape(-1)
    assert np.allclose(eager_out, out, atol=1e-3), (
        f"Eager vs CoreML max abs diff: {np.max(np.abs(eager_out - out)):.3e}"
    )


def test_alternate_checkpoint_round_trip(tmp_path: Path) -> None:
    """P15 / HALT (g): a second, structurally-identical-but-distinct checkpoint round-trips."""
    ckpt = _make_checkpoint(tmp_path, "alternate", seed=12345)
    output = tmp_path / "alternate.mlpackage"
    rc = _run_convert([
        "--checkpoint", str(ckpt),
        "--arch", "reference",
        "--output", str(output),
        "--validate",
    ])
    assert rc == 0
    assert output.exists()


def test_module_path_round_trip(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture,
) -> None:
    """P16: --arch custom --module path:Class round-trips a consumer-defined nn.Module.

    Uses monkeypatch.syspath_prepend so the import doesn't leak into sys.path
    across tests (P14 hardening). Loads the fixture via spec_from_file_location,
    which deliberately does NOT register the module in sys.modules — the fixed
    `__name__` arg is only an attribute, not a sys.modules key, so no collision
    risk even if two tests use the same name. (Verified by CPython importlib
    semantics: see https://docs.python.org/3/library/importlib.html.)
    """
    fixture_dir = THIS_DIR / "fixtures"
    fixture_path = fixture_dir / "custom_arch.py"
    assert fixture_path.exists(), f"Test fixture missing: {fixture_path}"

    monkeypatch.syspath_prepend(str(fixture_dir))
    spec = importlib.util.spec_from_file_location(
        "custom_arch_test_fixture", fixture_path
    )
    custom_mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(custom_mod)
    CustomTempoCNN = custom_mod.CustomTempoCNN

    torch.manual_seed(0)
    model = CustomTempoCNN()
    ckpt = tmp_path / "custom.pt"
    torch.save(model.state_dict(), ckpt)
    output = tmp_path / "custom.mlpackage"

    rc = _run_convert([
        "--checkpoint", str(ckpt),
        "--arch", "custom",
        "--module", f"{fixture_path}:CustomTempoCNN",
        "--input-shape", "1,1,64,256",
        "--output", str(output),
        "--validate",
    ])
    assert rc == 0
    assert output.exists()

    captured = capsys.readouterr()
    assert "WARNING:" in captured.err and "arbitrary Python" in captured.err


def test_corrupted_checkpoint_halts(tmp_path: Path) -> None:
    """HALT (g) wired: corrupted checkpoint refused without producing output."""
    bad = tmp_path / "bad.pt"
    torch.save({}, bad)
    output = tmp_path / "should-not-exist.mlpackage"
    rc = _run_convert([
        "--checkpoint", str(bad),
        "--arch", "reference",
        "--output", str(output),
        "--validate",
    ])
    assert rc != 0
    assert not output.exists()


def test_no_validate_emits_warning(
    synthetic_checkpoint: Path,
    tmp_path: Path,
    capsys: pytest.CaptureFixture,
) -> None:
    """--no-validate prints stderr warning AND omits per-check result keys (P12).

    Per Codex review: per-check booleans MUST be ABSENT from the report (not
    null) so the JSON shape is `{skipped: true, atol: 0.001}` only.
    """
    output = tmp_path / "no_validate.mlpackage"
    rc = _run_convert([
        "--checkpoint", str(synthetic_checkpoint),
        "--arch", "reference",
        "--output", str(output),
        "--no-validate",
    ])
    assert rc == 0
    captured = capsys.readouterr()
    assert "WARNING:" in captured.err and "no-validate" in captured.err.lower()

    report = json.loads(Path(str(output) + ".convert_report.json").read_text())
    validation = report["validation"]
    assert validation["skipped"] is True
    assert "atol" in validation
    # P12: per-check result keys absent entirely (not null) when skipped.
    assert "roundtrip_passed" not in validation
    assert "tensor_names_passed" not in validation
    assert "structural_passed" not in validation
    assert "eager_vs_traced_passed" not in validation


def test_promotion_failure_restores_existing_artifact(
    synthetic_checkpoint: Path,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """P10/P18 recovery branch: monkeypatch os.rename so the second rename
    (`staging → final`) fails AFTER the first rename (`final → .old.<pid>`)
    succeeded. Asserts:
      - the original artifact at out_path is restored byte-identically
      - no .<name>.old.<pid> sibling remains
      - no .coreml-convert.*.staging directory remains
    Codex flagged this as the missing proof for the crash-recoverable design.
    """
    output = tmp_path / "preexisting.mlpackage"
    output.mkdir()
    (output / "marker").write_text("original-good-artifact")
    original_marker_bytes = (output / "marker").read_bytes()

    import convert as convert_mod

    real_rename = os.rename

    def flaky_rename(src, dst):
        # Intercept the exact "promotion" rename: candidate → out_path.
        # Other renames (staging-internal, sentinel-to-.old, .old-restoration)
        # all proceed normally.
        if str(dst) == str(output) and ".staging" in str(src):
            raise OSError("simulated promotion failure")
        return real_rename(src, dst)

    monkeypatch.setattr(convert_mod.os, "rename", flaky_rename)

    rc = _run_convert([
        "--checkpoint", str(synthetic_checkpoint),
        "--arch", "reference",
        "--output", str(output),
        "--validate",
    ])
    assert rc != 0

    # Original artifact restored byte-identically.
    assert output.exists() and output.is_dir()
    assert (output / "marker").read_bytes() == original_marker_bytes

    # No leftover .old.<pid> siblings or staging dirs in the output's parent.
    siblings = list(output.parent.iterdir())
    leftover = [
        s.name for s in siblings
        if (
            s.name.startswith(f".{output.name}.old.")
            or s.name.startswith(".coreml-convert.")
        )
    ]
    assert not leftover, f"Leftover sibling artifacts after failed promotion: {leftover}"


def test_existing_mlpackage_survives_validation_failure(
    synthetic_checkpoint: Path,
    tmp_path: Path,
) -> None:
    """P10/P18: existing .mlpackage is preserved when validation fails.

    Forces validation failure via --atol 1e-30 (any non-zero numerical drift
    trips the roundtrip check). The failed artifact lands at the .failed
    sibling; the original at out_path is left untouched.
    """
    output = tmp_path / "preexisting.mlpackage"
    output.mkdir()
    (output / "marker").write_text("survivor")

    rc = _run_convert([
        "--checkpoint", str(synthetic_checkpoint),
        "--arch", "reference",
        "--output", str(output),
        "--validate",
        "--atol", "1e-30",
    ])
    assert rc == 1, "Validation should have failed at atol=1e-30"
    assert (output / "marker").exists()
    assert (output / "marker").read_text() == "survivor"

    # The failed artifact should be at output_stem.failed.mlpackage
    failed = output.parent / "preexisting.failed.mlpackage"
    assert failed.exists(), f"Expected failed sibling at {failed}"
    failed_report = output.parent / "preexisting.failed.mlpackage.convert_report.json"
    assert failed_report.exists()
    report = json.loads(failed_report.read_text())
    assert report["promoted"] is False
    assert report["validation"]["roundtrip_passed"] is False


def test_no_orphan_staging_dir_after_failure(tmp_path: Path) -> None:
    """P10/P18: no .coreml-convert.*.staging dirs remain after a failed conversion."""
    bad = tmp_path / "bad.pt"
    torch.save({}, bad)
    output = tmp_path / "should-not-exist.mlpackage"
    rc = _run_convert([
        "--checkpoint", str(bad),
        "--arch", "reference",
        "--output", str(output),
        "--validate",
    ])
    assert rc != 0
    leftover = [
        s.name for s in tmp_path.iterdir()
        if s.name.startswith(".coreml-convert.")
    ]
    assert not leftover, f"Orphan staging dirs: {leftover}"


# --- P11 input-shape boundary tests ---


def test_input_shape_too_few_dims(synthetic_checkpoint: Path, tmp_path: Path) -> None:
    rc = _run_convert([
        "--checkpoint", str(synthetic_checkpoint), "--arch", "reference",
        "--input-shape", "1,1,128",
        "--output", str(tmp_path / "x.mlpackage"),
    ])
    assert rc == 2


def test_input_shape_zero_dim(synthetic_checkpoint: Path, tmp_path: Path) -> None:
    rc = _run_convert([
        "--checkpoint", str(synthetic_checkpoint), "--arch", "reference",
        "--input-shape", "1,1,128,0",
        "--output", str(tmp_path / "x.mlpackage"),
    ])
    assert rc == 2


def test_input_shape_per_dim_cap(synthetic_checkpoint: Path, tmp_path: Path) -> None:
    rc = _run_convert([
        "--checkpoint", str(synthetic_checkpoint), "--arch", "reference",
        "--input-shape", "1,1,128,99999999",
        "--output", str(tmp_path / "x.mlpackage"),
    ])
    assert rc == 2


def test_input_shape_element_cap(synthetic_checkpoint: Path, tmp_path: Path) -> None:
    """P11 element-product cap: 4096*4096 passes per-dim but exceeds 16M elements."""
    rc = _run_convert([
        "--checkpoint", str(synthetic_checkpoint), "--arch", "reference",
        "--input-shape", "1,1,4096,4096",
        "--output", str(tmp_path / "x.mlpackage"),
    ])
    assert rc == 2


# --- P9 / P24 --module / --module-args tests ---


def test_module_args_invalid_json(
    synthetic_checkpoint: Path,
    tmp_path: Path,
    capsys: pytest.CaptureFixture,
) -> None:
    rc = _run_convert([
        "--checkpoint", str(synthetic_checkpoint), "--arch", "custom",
        "--module", str(THIS_DIR / "fixtures" / "custom_arch.py:CustomTempoCNN"),
        "--module-args", "not json",
        "--output", str(tmp_path / "x.mlpackage"),
    ])
    assert rc == 2
    assert "ERROR parsing --module-args JSON" in capsys.readouterr().err


def test_module_args_array_rejected(
    synthetic_checkpoint: Path,
    tmp_path: Path,
    capsys: pytest.CaptureFixture,
) -> None:
    rc = _run_convert([
        "--checkpoint", str(synthetic_checkpoint), "--arch", "custom",
        "--module", str(THIS_DIR / "fixtures" / "custom_arch.py:CustomTempoCNN"),
        "--module-args", "[1,2,3]",
        "--output", str(tmp_path / "x.mlpackage"),
    ])
    assert rc == 2
    assert "must be a JSON object" in capsys.readouterr().err


def test_module_with_arch_reference_warns(
    synthetic_checkpoint: Path,
    tmp_path: Path,
    capsys: pytest.CaptureFixture,
) -> None:
    """P24: --module ignored when --arch=reference; warning to stderr."""
    rc = _run_convert([
        "--checkpoint", str(synthetic_checkpoint), "--arch", "reference",
        "--module", "fake/path.py:FakeClass",
        "--output", str(tmp_path / "x.mlpackage"),
    ])
    assert rc == 0
    err = capsys.readouterr().err
    assert "ignored because --arch=reference" in err


# --- F12 (PR #2 follow-up) bin-count validation tests ---


def test_custom_without_expected_bin_count_prints_info(
    tmp_path: Path,
    capsys: pytest.CaptureFixture,
) -> None:
    """F12: --arch custom without --expected-bin-count emits a stdout INFO
    diagnostic but does NOT fail. The custom fixture happens to output 256
    bins (matches BPM_BIN_COUNT), but the contract is permissive in this
    branch — the test asserts the BYOM workflow is not blocked.
    """
    fixture_path = THIS_DIR / "fixtures" / "custom_arch.py"
    torch.manual_seed(0)
    spec = importlib.util.spec_from_file_location("custom_arch_fixture", fixture_path)
    custom_mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(custom_mod)
    model = custom_mod.CustomTempoCNN()
    ckpt = tmp_path / "custom_noflag.pt"
    torch.save(model.state_dict(), ckpt)
    output = tmp_path / "custom_noflag.mlpackage"

    rc = _run_convert([
        "--checkpoint", str(ckpt),
        "--arch", "custom",
        "--module", f"{fixture_path}:CustomTempoCNN",
        "--input-shape", "1,1,64,256",
        "--output", str(output),
        "--validate",
    ])
    assert rc == 0
    captured = capsys.readouterr()
    # Stdout, not stderr — stderr would imply warning/error to BYOM users.
    assert "INFO" in captured.out and "per-sample elements" in captured.out
    assert "Pass --expected-bin-count" in captured.out


def test_custom_with_matching_expected_bin_count_passes(tmp_path: Path) -> None:
    """F12: --arch custom + correct --expected-bin-count succeeds."""
    fixture_path = THIS_DIR / "fixtures" / "custom_arch.py"
    torch.manual_seed(0)
    spec = importlib.util.spec_from_file_location("custom_arch_fixture", fixture_path)
    custom_mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(custom_mod)
    model = custom_mod.CustomTempoCNN()
    ckpt = tmp_path / "custom_match.pt"
    torch.save(model.state_dict(), ckpt)
    output = tmp_path / "custom_match.mlpackage"

    rc = _run_convert([
        "--checkpoint", str(ckpt),
        "--arch", "custom",
        "--module", f"{fixture_path}:CustomTempoCNN",
        "--input-shape", "1,1,64,256",
        "--expected-bin-count", "256",  # matches fixture
        "--output", str(output),
        "--validate",
    ])
    assert rc == 0
    assert output.exists()


def test_custom_with_wrong_expected_bin_count_halts(
    tmp_path: Path,
    capsys: pytest.CaptureFixture,
) -> None:
    """F12: --arch custom + WRONG --expected-bin-count hard-fails with HALT (g)."""
    fixture_path = THIS_DIR / "fixtures" / "custom_arch.py"
    torch.manual_seed(0)
    spec = importlib.util.spec_from_file_location("custom_arch_fixture", fixture_path)
    custom_mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(custom_mod)
    model = custom_mod.CustomTempoCNN()
    ckpt = tmp_path / "custom_mismatch.pt"
    torch.save(model.state_dict(), ckpt)
    output = tmp_path / "custom_mismatch.mlpackage"

    rc = _run_convert([
        "--checkpoint", str(ckpt),
        "--arch", "custom",
        "--module", f"{fixture_path}:CustomTempoCNN",
        "--input-shape", "1,1,64,256",
        "--expected-bin-count", "128",  # fixture produces 256
        "--output", str(output),
        "--validate",
    ])
    assert rc == 1
    err = capsys.readouterr().err
    assert "HALT" in err and "256 bins per sample" in err
    assert not output.exists()


def test_reference_arch_bin_count_enforced_via_monkeypatch(
    synthetic_checkpoint: Path,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture,
) -> None:
    """F12: reference path enforces BPM_BIN_COUNT. The reference always
    produces 256 outputs; force the gate to fire by monkeypatching the
    BPM_BIN_COUNT constant inside convert.py to 128. The model still emits
    256 outputs but the gate compares against the patched value.
    """
    import convert as convert_mod

    monkeypatch.setattr(convert_mod, "BPM_BIN_COUNT", 128)

    output = tmp_path / "ref_bin_mismatch.mlpackage"
    rc = _run_convert([
        "--checkpoint", str(synthetic_checkpoint),
        "--arch", "reference",
        "--output", str(output),
    ])
    assert rc == 1
    err = capsys.readouterr().err
    assert "HALT" in err
    assert "256 bins per sample" in err and "expected 128" in err
    assert not output.exists()
