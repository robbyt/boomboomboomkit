"""
Story 4-4b Task 11.4 — validation harness for the consumer convert tool.

Three validators per DD #11 / DD #13:
  - eager-vs-traced equivalence (corenet pattern, AC #9 step 4)
  - tensor-name verification (input == "input", output == "output")
  - convert-roundtrip equivalence (PyTorch eager vs CoreML predict)
"""

from __future__ import annotations

import numpy as np
import torch


def validate_traced_eager_equivalence(
    eager_model: torch.nn.Module,
    traced_model: torch.jit.ScriptModule,
    example: torch.Tensor,
    atol: float = 1e-3,
) -> tuple[bool, float]:
    """Returns (passed, max_abs_diff)."""
    eager_model.eval()
    traced_model.eval()
    with torch.no_grad():
        a = eager_model(example)
        b = traced_model(example)
    max_abs = float(torch.abs(a - b).max().item())
    return max_abs <= atol, max_abs


def validate_tensor_names(mlmodel) -> tuple[bool, list[str], list[str]]:
    """Returns (passed, input_names, output_names)."""
    spec = mlmodel.get_spec()
    in_names = [i.name for i in spec.description.input]
    out_names = [o.name for o in spec.description.output]
    return (in_names == ["input"] and out_names == ["output"]), in_names, out_names


def validate_roundtrip_equivalence(
    pytorch_model: torch.nn.Module,
    mlmodel,
    example: torch.Tensor,
    atol: float = 1e-3,
) -> tuple[bool, float]:
    """Returns (passed, max_abs_diff).

    Shape contract is strict: BNNSTechnique consumes the raw CoreML output
    shape, so the converter must not silently reshape. A `(1, 256)` PyTorch
    output and a `(256,)` CoreML output have matching element counts but are
    NOT the same artifact at the BNNS layer. Raise ValueError on mismatch
    instead of reshaping (the caller treats this as HALT (g)).
    """
    pytorch_model.eval()
    with torch.no_grad():
        eager_out = pytorch_model(example).numpy()
    pred = mlmodel.predict({"input": example.numpy()})
    out_key = "output" if "output" in pred else next(iter(pred.keys()))
    cml_out = np.asarray(pred[out_key])
    if cml_out.shape != eager_out.shape:
        raise ValueError(
            f"CoreML output shape {cml_out.shape} does not match "
            f"PyTorch eager shape {eager_out.shape}. The converter must not "
            f"silently reshape — BNNSTechnique consumes the raw output shape."
        )
    max_abs = float(np.abs(eager_out - cml_out).max())
    return max_abs <= atol, max_abs
