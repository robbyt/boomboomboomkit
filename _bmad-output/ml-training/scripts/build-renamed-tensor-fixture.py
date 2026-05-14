"""
Build a renamed-output-tensor `.mlmodelc` fixture for Story 4-5 HALT (i) gate.

The fixture is a copy of the bundled `giantsteps_v1` model with the output
tensor renamed from `output` to `var_42`. Used by
`BNNSTechniqueTests.initThrowsOnMismatchedTensorNames` to prove
`BNNSTechnique.init(modelURL:)` throws `MLTechniqueError.invalidTensorContract`
when the contract-required name is absent.

Output: `Tests/BoomBoomBoomKitTests/Fixtures/RenamedTensors.mlmodelc/`

This is a develop-only helper — not shipped to main. The compiled `.mlmodelc`
IS committed (per the existing `CustomBundled.mlmodelc/` precedent).

Usage:
  cd _bmad-output/ml-training && uv run python scripts/build-renamed-tensor-fixture.py
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

import coremltools as ct  # type: ignore[import-not-found]


REPO_ROOT = Path(__file__).resolve().parents[3]
SOURCE_MLPACKAGE = REPO_ROOT / "_bmad-output/ml-models/giantsteps_v1.mlmodel"
FIXTURE_DIR = REPO_ROOT / "Tests/BoomBoomBoomKitTests/Fixtures/RenamedTensors.mlmodelc"
NEW_OUTPUT_NAME = "var_42"


def rename_output_in_mil(spec) -> None:
    """Rename the model output tensor across the proto spec.

    `ct.utils.rename_feature` doesn't reliably propagate into MIL SSA
    bindings, so we walk the spec and rename every site that mentions the
    original tensor name. Three rename targets must all be updated:
      1. `description.output[i].name` — the externally-visible signature
      2. `mlProgram.functions[*].block_specializations[*].outputs[]` — the
         block's terminal output binding
      3. The MIL op `outputs[]` lists — every op that defines the named
         tensor (typically the last op before the terminal output)
    Missing #3 produces `coremlc: error: Unable to parse ML Program:
    Failed to find type of <new_name>`.
    """
    if not spec.description.output:
        raise RuntimeError("source model has no declared output")

    original_name = spec.description.output[0].name
    print(f"renaming output '{original_name}' -> '{NEW_OUTPUT_NAME}'", file=sys.stderr)

    # (1) Description envelope.
    spec.description.output[0].name = NEW_OUTPUT_NAME

    # (2) + (3) Walk the MIL program. For each function and block, rename:
    #   - the block's outputs[] strings
    #   - every op's `outputs[*].name` field whose name matches `original_name`
    if spec.HasField("mlProgram"):
        for func_name in spec.mlProgram.functions:
            func = spec.mlProgram.functions[func_name]
            for block_spec in func.block_specializations.values():
                # Block-level outputs[] (the externally-exported names).
                for i, out_name in enumerate(block_spec.outputs):
                    if out_name == original_name:
                        block_spec.outputs[i] = NEW_OUTPUT_NAME
                # Each op produces zero or more named outputs; rename any
                # match. NamedValueType protobuf with `name` field.
                for op in block_spec.operations:
                    for op_output in op.outputs:
                        if op_output.name == original_name:
                            op_output.name = NEW_OUTPUT_NAME


def main() -> int:
    if not SOURCE_MLPACKAGE.exists():
        print(
            f"ERROR: source mlpackage not found at {SOURCE_MLPACKAGE}\n"
            "       Run `make ml-export` first, or point to an existing .mlpackage.",
            file=sys.stderr,
        )
        return 1

    print(f"loading source: {SOURCE_MLPACKAGE}", file=sys.stderr)
    model = ct.models.MLModel(str(SOURCE_MLPACKAGE))
    spec = model.get_spec()

    rename_output_in_mil(spec)

    # Write to a temporary mlpackage so we can recompile. ML programs are
    # spec + weights; `save_spec` requires the source weights dir so it can
    # bundle them into the new mlpackage.
    with_renamed = REPO_ROOT / "_bmad-output/ml-models/_renamed_var42.mlpackage"
    if with_renamed.exists():
        shutil.rmtree(with_renamed)
    print(f"saving intermediate mlpackage: {with_renamed}", file=sys.stderr)
    source_weights_dir = SOURCE_MLPACKAGE / "Data/com.apple.CoreML/weights"
    ct.utils.save_spec(
        spec, str(with_renamed), weights_dir=str(source_weights_dir)
    )

    # Compile via xcrun coremlc into the fixture dir's parent so the produced
    # `.mlmodelc` lands at the fixture path.
    fixture_parent = FIXTURE_DIR.parent
    fixture_parent.mkdir(parents=True, exist_ok=True)

    # Remove stale fixture if present so the compile produces a clean tree.
    if FIXTURE_DIR.exists():
        shutil.rmtree(FIXTURE_DIR)

    print(f"compiling: xcrun coremlc compile -> {fixture_parent}", file=sys.stderr)
    compiled_basename = with_renamed.stem + ".mlmodelc"  # _renamed_var42.mlmodelc
    subprocess.run(
        ["xcrun", "coremlc", "compile", str(with_renamed), str(fixture_parent)],
        check=True,
    )

    # The coremlc step writes <basename>.mlmodelc; rename to the canonical
    # fixture name so the test can refer to it via a stable URL.
    raw_output = fixture_parent / compiled_basename
    if not raw_output.exists():
        print(
            f"ERROR: expected coremlc output at {raw_output} but it doesn't exist",
            file=sys.stderr,
        )
        return 2
    raw_output.rename(FIXTURE_DIR)

    # Sanity-check the produced fixture's metadata.json reflects the renamed
    # output. If the rename didn't propagate, fail loud rather than ship a
    # silently-valid fixture.
    metadata_path = FIXTURE_DIR / "metadata.json"
    with metadata_path.open() as f:
        metadata = json.load(f)
    output_names = {
        entry["name"]
        for block in metadata
        for entry in block.get("outputSchema", [])
    }
    if NEW_OUTPUT_NAME not in output_names:
        print(
            f"ERROR: renamed fixture's metadata.json does not contain "
            f"output name '{NEW_OUTPUT_NAME}'; got {output_names}",
            file=sys.stderr,
        )
        return 3

    # Clean up the intermediate .mlpackage — it's not needed once the
    # .mlmodelc is committed.
    shutil.rmtree(with_renamed)

    print(f"OK: renamed-output fixture written to {FIXTURE_DIR}", file=sys.stderr)
    print(f"    output tensor name: {NEW_OUTPUT_NAME}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
