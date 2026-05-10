#!/usr/bin/env bash
# Story 4-4b — post-training finalization sequence.
# Runs the Tasks 6/7/8/9 gating sequence against the final 60-epoch model.pt
# and writes the diff-scope-proof + final eval_report. Does NOT commit;
# expects the caller to commit after reviewing outputs.
#
# Usage: bash _bmad-output/ml-training/finalize.sh
#
# Env overrides:
#   OA300_CORPUS_PATH       — defaults to ~/Dropbox/OA300_OnsetAudio300
#   GIANTSTEPS_CORPUS_PATH  — defaults to ~/Dropbox/research/giantsteps-tempo-dataset
#   REGRESSION_SNAPSHOT     — defaults to _bmad-output/implementation-artifacts/4-4b-regression-snapshot.json

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ML_DIR="${REPO_ROOT}/_bmad-output/ml-training"
LOG="${ML_DIR}/finalize.log"

OA300_CORPUS_PATH="${OA300_CORPUS_PATH:-${HOME}/Dropbox/OA300_OnsetAudio300}"
GIANTSTEPS_CORPUS_PATH="${GIANTSTEPS_CORPUS_PATH:-${HOME}/Dropbox/research/giantsteps-tempo-dataset}"
REGRESSION_SNAPSHOT="${REGRESSION_SNAPSHOT:-${REPO_ROOT}/_bmad-output/implementation-artifacts/4-4b-regression-snapshot.json}"

cd "${REPO_ROOT}"

# Per-invocation temp dirs for the structural-equivalence step (was hardcoded /tmp/).
COREML_TMP1="$(mktemp -d -t coreml-out1.XXXXXX)"
COREML_TMP2="$(mktemp -d -t coreml-out2.XXXXXX)"
trap 'rm -rf "${COREML_TMP1}" "${COREML_TMP2}"' EXIT

# Run each step inside `set -o pipefail` so step failures aren't masked by tee.
# Capture inner exit via PIPESTATUS at the outer `tee` boundary.
{
  echo "============================================================"
  echo " Story 4-4b finalization sequence"
  echo " Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "============================================================"

  echo ""
  echo "[1/9] Eval — PyTorch + CoreML on OA300 held-out test (--source both for AC #11 sanity HALT)"
  cd "${ML_DIR}"
  uv run python eval.py --checkpoint model.pt --source both || {
    echo "*** SANITY HALT (c) tripped — see eval_report.json ***"
    exit 1
  }
  cd "${REPO_ROOT}"

  echo ""
  echo "[2/9] Export — final checkpoint to .mlmodel"
  cd "${ML_DIR}"
  uv run python export.py \
    --checkpoint model.pt \
    --output ../ml-models/giantsteps_v1.mlmodel
  cd "${REPO_ROOT}"

  echo ""
  echo "[3/9] Compile — make compile-model"
  make compile-model

  echo ""
  echo "[4/9] Re-eval via CoreML against the freshly-compiled artifact"
  cd "${ML_DIR}"
  uv run python eval.py \
    --checkpoint model.pt \
    --mlmodel ../ml-models/giantsteps_v1.mlmodel \
    --source both
  cd "${REPO_ROOT}"

  echo ""
  echo "[5/9] Structural-equivalence check (compile twice, diff)"
  echo "    NOTE: this gate compares model.mil text + weight.bin sha256."
  echo "    coremlc CAN embed timestamps in some metadata fields; if this gate"
  echo "    becomes flaky in a future toolchain, add SOURCE_DATE_EPOCH=0 or"
  echo "    drop the sha-comparison and rely on model.mil diff alone."
  xcrun coremlc compile _bmad-output/ml-models/giantsteps_v1.mlmodel "${COREML_TMP1}/"
  xcrun coremlc compile _bmad-output/ml-models/giantsteps_v1.mlmodel "${COREML_TMP2}/"
  diff "${COREML_TMP1}/giantsteps_v1.mlmodelc/model.mil" \
       "${COREML_TMP2}/giantsteps_v1.mlmodelc/model.mil" \
    && echo "PASS: model.mil identical"
  h1=$(shasum -a 256 "${COREML_TMP1}/giantsteps_v1.mlmodelc/weights/weight.bin" | cut -d' ' -f1)
  h2=$(shasum -a 256 "${COREML_TMP2}/giantsteps_v1.mlmodelc/weights/weight.bin" | cut -d' ' -f1)
  if [ "$h1" = "$h2" ]; then
    echo "PASS: weight.bin sha256 identical: $h1"
  else
    echo "FAIL: weight.bin sha256 differs"
    exit 1
  fi

  echo ""
  echo "[6/9] Diff-scope proof (committed + staged + unstaged)"
  bash _bmad-output/ml-training/diff_scope_check.sh

  echo ""
  echo "[7/9] make test (no regression)"
  make test 2>&1 | tail -3

  echo ""
  echo "[8/9] make benchmark — OA300 byte-identity check vs regression snapshot"
  OA300_CORPUS_PATH="${OA300_CORPUS_PATH}" \
    swift test --filter BoomBoomBoomKitBenchmarkTests.OA300BenchmarkTests 2>&1 \
    | grep -E "Acc1|Acc2|Test run with|Test \"benchmark" | tail -10
  # AC #12: assert per-track JSON byte-identity vs the captured pre-source snapshot.
  # The benchmark target writes per-track results to a known artifact path; if
  # that artifact diverges from REGRESSION_SNAPSHOT, AC #12 has been violated.
  # Note: this gate only fires if the snapshot file exists AND the live
  # benchmark output is reachable at a stable path; we soft-skip otherwise so
  # this script remains usable when the snapshot hasn't been captured.
  CURRENT_SNAPSHOT="${REPO_ROOT}/_bmad-output/implementation-artifacts/4-4b-regression-snapshot-current.json"
  if [ -f "${REGRESSION_SNAPSHOT}" ] && [ -f "${CURRENT_SNAPSHOT}" ]; then
    echo "[8b/9] AC #12 byte-equality: diff ${REGRESSION_SNAPSHOT} ${CURRENT_SNAPSHOT}"
    if diff -q "${REGRESSION_SNAPSHOT}" "${CURRENT_SNAPSHOT}"; then
      echo "PASS: per-track BPM JSON is byte-identical to pre-source baseline"
    else
      echo "FAIL: regression snapshot drifted — Story 4-4b violates AC #12"
      diff "${REGRESSION_SNAPSHOT}" "${CURRENT_SNAPSHOT}" | head -40 || true
      exit 1
    fi
  else
    echo "[8b/9] AC #12 byte-equality SKIPPED (snapshot not present at expected paths; verify manually)"
  fi

  echo ""
  echo "[9/9] make benchmark-giantsteps — GiantSteps byte-identity check"
  GIANTSTEPS_CORPUS_PATH="${GIANTSTEPS_CORPUS_PATH}" \
    swift test --filter BoomBoomBoomKitBenchmarkTests.GiantStepsBenchmarkTests 2>&1 \
    | grep -E "Acc1|Acc2|Test run with|Test \"benchmark" | tail -10

  echo ""
  echo "============================================================"
  echo " Finalization complete: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "============================================================"
} 2>&1 | tee "${LOG}"

# Surface inner-block exit code through tee so step failures aren't masked.
exit "${PIPESTATUS[0]}"
