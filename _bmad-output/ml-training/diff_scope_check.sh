#!/usr/bin/env bash
# Story 4-4b Task 9.4 / AC #1 — diff-scope proof.
#
# Verifies that the post-Story-4-4b diff against the Task-1 baseline contains
# ZERO modifications to Sources/ or Tests/ EXCEPT for the produced
# Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/ artifact.
#
# HALT (f) per DD #12: any non-zero diff outside the allowed set fails.
#
# Checks BOTH committed (BASELINE..HEAD) AND staged + unstaged working-tree
# changes — staged-but-uncommitted unauthorized changes under Sources/ also
# trip the gate.
#
# Usage: bash _bmad-output/ml-training/diff_scope_check.sh <baseline-sha>
#   default baseline-sha = 73f8188 (Story 4-4b Task 1: pre-source baseline + Python env scaffolding)

set -euo pipefail

BASELINE_SHA="${1:-73f8188}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_PATH="${REPO_ROOT}/_bmad-output/implementation-artifacts/4-4b-diff-scope-proof.txt"
ALLOWED_PATH="Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc"

cd "${REPO_ROOT}"

{
  echo "============================================================"
  echo " Story 4-4b — diff-scope proof (AC #1, HALT (f) per DD #12)"
  echo "============================================================"
  echo ""
  echo "Baseline:    ${BASELINE_SHA}"
  echo "HEAD:        $(git rev-parse --short HEAD)"
  echo "Generated:   $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Allowed Sources/ path: ${ALLOWED_PATH}"
  echo ""
  echo "--- git diff --stat ${BASELINE_SHA}..HEAD -- Sources/ Tests/ ---"
  git diff --stat "${BASELINE_SHA}..HEAD" -- Sources/ Tests/ || true
  echo ""
  echo "--- git diff --stat ${BASELINE_SHA}..HEAD -- _bmad-output/ml-training/ ---"
  git diff --stat "${BASELINE_SHA}..HEAD" -- _bmad-output/ml-training/ || true
  echo ""
  echo "--- git diff --stat ${BASELINE_SHA}..HEAD -- _bmad-output/ml-models/ ---"
  git diff --stat "${BASELINE_SHA}..HEAD" -- _bmad-output/ml-models/ || true
  echo ""
  echo "--- git diff --stat ${BASELINE_SHA}..HEAD -- tools/coreml-convert/ ---"
  git diff --stat "${BASELINE_SHA}..HEAD" -- tools/coreml-convert/ || true
  echo ""
  echo "--- git diff --stat ${BASELINE_SHA}..HEAD -- _bmad-output/implementation-artifacts/4-4b-* ---"
  git diff --stat "${BASELINE_SHA}..HEAD" -- _bmad-output/implementation-artifacts/4-4b-* || true
  echo ""
  echo "--- git status (working tree) ---"
  git status --short
  echo ""
  echo "--- find _bmad-output/ml-training -type f (excluding .venv/__pycache__/checkpoints/swift_feature_extractor build outputs) ---"
  find _bmad-output/ml-training -type f \
    -not -path '*/.venv/*' \
    -not -path '*/__pycache__/*' \
    -not -path '*/checkpoints/*' \
    -not -path '*/swift_feature_extractor/.build/*' \
    -not -path '*/swift_feature_extractor/out/*' \
    | sort
  echo ""
  echo "--- find Sources/BoomBoomBoomKitML/Resources -type f ---"
  find Sources/BoomBoomBoomKitML/Resources -type f | sort
  echo ""
  echo "--- find tools/coreml-convert -type f (excluding caches) ---"
  find tools/coreml-convert -type f \
    -not -path '*/.venv/*' \
    -not -path '*/__pycache__/*' \
    -not -path '*/.pytest_cache/*' \
    | sort
  echo ""

  # AC #1 HALT (f) gate: diff in Sources/ MUST be limited to the allowed path.
  # Use git pathspec exclusion `:(exclude)` (anchored at directory boundary)
  # rather than prefix-based grep, so paths like
  # `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc_backup` cannot
  # slip through. Check committed (BASELINE..HEAD) AND staged AND unstaged.
  committed_changes=$(git diff --name-only "${BASELINE_SHA}..HEAD" -- \
    Sources/ Tests/ ":(exclude)${ALLOWED_PATH}/**" || true)
  staged_changes=$(git diff --cached --name-only -- \
    Sources/ Tests/ ":(exclude)${ALLOWED_PATH}/**" || true)
  unstaged_changes=$(git diff --name-only -- \
    Sources/ Tests/ ":(exclude)${ALLOWED_PATH}/**" || true)
  modified_sources=$(printf '%s\n%s\n%s\n' \
    "${committed_changes}" "${staged_changes}" "${unstaged_changes}" \
    | grep -v '^$' | sort -u || true)
  echo "--- HALT (f) GATE ---"
  if [ -z "${modified_sources}" ]; then
    echo "PASS: zero non-allowed changes under Sources/ or Tests/ (committed + staged + unstaged)"
  else
    echo "FAIL: unexpected modifications outside allowed path:"
    echo "${modified_sources}"
    echo ""
    echo "*** HALT (f): Story 4-4b cannot complete with these unauthorized Sources/Tests changes ***"
    exit 1
  fi
} | tee "${OUT_PATH}"

echo ""
echo "Wrote ${OUT_PATH}"
