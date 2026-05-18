#!/usr/bin/env bash
#
# profile-trace-build-cost.sh
#
# Story 4-3b Task 1.2: capture an xctrace Time Profiler trace of the
# mock-injected analyzeBPM hot path, plus a hardware/toolchain metadata
# block for the markdown profile artifact.
#
# Usage:
#   ./profile-trace-build-cost.sh
#
# Output:
#   _bmad-output/perf-baselines/4-3b-trace-build-cost-<timestamp>.trace
#   _bmad-output/perf-baselines/4-3b-profile-metadata.txt
#
# AC #1 reproducibility: paste 4-3b-profile-metadata.txt into
# _bmad-output/implementation-artifacts/4-3b-trace-profile.md "Reproducibility"
# section.
#
# If xctrace --launch fails (TCC, codesign), open Instruments GUI and use
# File > Record Trace from Template > Time Profiler against the .xctest
# bundle host directly, OR `xctrace record --attach <pid>` against a
# long-loop variant of the test. Document which path was used in the
# markdown.
#

set -euo pipefail

PROJ_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR="$PROJ_ROOT/_bmad-output/perf-baselines"
mkdir -p "$OUT_DIR"

TIMESTAMP="$(date +%Y%m%dT%H%M%SZ)"
TRACE_OUT="$OUT_DIR/4-3b-trace-build-cost-${TIMESTAMP}.trace"
META_OUT="$OUT_DIR/4-3b-profile-metadata.txt"

echo "[1/4] Building release test bundle (so xctrace profiles optimized code)..."
cd "$PROJ_ROOT"
# -enable-testing is required because BoomBoomBoomKitTests uses @testable
# imports. Without it, the release build fails with ModuleNotTestable.
swift build -c release --build-tests -Xswiftc -enable-testing

echo "[2/4] Locating xctest bundle host and helper..."
# SPM emits the .xctest bundle under the platform-specific build dir
# (.build/arm64-apple-macosx/release/), not .build/release/.
XCTEST_BUNDLE=$(find .build -path '*/release/*.xctest' -type d -print -quit 2>/dev/null)
if [[ -z "$XCTEST_BUNDLE" ]]; then
  echo "ERROR: no .xctest bundle found under .build/*/release/" >&2
  exit 1
fi
echo "       bundle: $XCTEST_BUNDLE"

# swiftpm-testing-helper loads the .xctest bundle via dlopen and runs Swift
# Testing tests against it. Launching this directly (instead of `swift test`)
# means xctrace's target-pid="SINGLE" sampling captures BoomBoomBoomKit
# symbols, not the swift parent that just spawns the helper.
HELPER="$(xcrun --find swiftpm-testing-helper 2>/dev/null \
  || echo /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/libexec/swift/pm/swiftpm-testing-helper)"
if [[ ! -x "$HELPER" ]]; then
  echo "ERROR: swiftpm-testing-helper not found at $HELPER" >&2
  exit 1
fi
echo "       helper: $HELPER"

# Testing.framework lives in Xcode's SharedFrameworks; the .xctest bundle
# was linked against it via @rpath, but the helper doesn't set the rpath.
# Inject DYLD_FRAMEWORK_PATH so dyld resolves @rpath/Testing.framework.
TESTING_FRAMEWORK_DIR="/Applications/Xcode.app/Contents/SharedFrameworks"
if [[ ! -d "$TESTING_FRAMEWORK_DIR/Testing.framework" ]]; then
  # Fallback search if Xcode is at a non-default path. Use `find -print -quit`
  # instead of `find | grep | head -1`: under `set -o pipefail`, a head-closed
  # pipe can hit EPIPE on subsequent `find` writes and abort the script when
  # there are multiple matches (multi-Xcode-install machines). Hard-fail with
  # a diagnostic if no match exists rather than silently using `dirname ""`
  # which would resolve to `.` and point DYLD_FRAMEWORK_PATH at the cwd.
  FOUND_TESTING_FRAMEWORK="$(find /Applications -maxdepth 6 -path '*SharedFrameworks*' -name 'Testing.framework' -type d -print -quit 2>/dev/null)"
  if [[ -z "$FOUND_TESTING_FRAMEWORK" ]]; then
    echo "ERROR: could not locate Testing.framework under */SharedFrameworks/ in /Applications. Install Xcode or set TESTING_FRAMEWORK_DIR explicitly." >&2
    exit 1
  fi
  TESTING_FRAMEWORK_DIR="$(dirname "$FOUND_TESTING_FRAMEWORK")"
fi
echo "       Testing.framework dir: $TESTING_FRAMEWORK_DIR"

echo "[3/4] Capturing reproducibility metadata to $META_OUT..."
{
  echo "## Reproducibility"
  echo "- macOS: $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
  echo "- Xcode: $(xcodebuild -version | head -1)"
  echo "- xctrace: $(xctrace version 2>&1 | head -1 || true)"
  echo "- Hardware: $(sysctl -n hw.model) ($(sysctl -n machdep.cpu.brand_string))"
  echo "- AC power: required (run only when plugged in)"
  echo "- Run count: 1 (Time Profiler single-capture; AC #4 perf-benchmark uses N=5)"
  echo "- Profile target: BoomBoomBoomKitTests.MLTechniquePerfTests/profileLongLoop (env-gated long-loop variant; PROFILE_LOOPS_ITERS=${PROFILE_LOOPS_ITERS:-200})"
  echo "- Intensity: .fastest (matches existing fixture; Story 4.3 measured 22% structural ratio constant across .fastest/.default)"
  echo "- Mock: MockMLTechnique(returning: nil) — abstain path"
  echo "- Build config: release with --build-tests"
  echo "- Commit: $(git rev-parse --short HEAD)"
} > "$META_OUT"
cat "$META_OUT"

echo "[4/4] Running xctrace Time Profiler against env-gated long-loop test..."
echo "      Output: $TRACE_OUT"
# Launch swiftpm-testing-helper directly so xctrace's target-pid="SINGLE"
# sampling captures BoomBoomBoomKit symbols. The MLTechniquePerfTests
# .profileLongLoop test is env-gated on PROFILE_LOOPS=1 — never runs under
# `make test`. PROFILE_LOOPS_ITERS controls iteration count (default 200).
ITERS="${PROFILE_LOOPS_ITERS:-200}"
echo "      PROFILE_LOOPS_ITERS=$ITERS (override via env)"
if ! xctrace record \
  --template 'Time Profiler' \
  --output "$TRACE_OUT" \
  --target-stdout - \
  --env "PROFILE_LOOPS=1" \
  --env "PROFILE_LOOPS_ITERS=$ITERS" \
  --env "DYLD_FRAMEWORK_PATH=$TESTING_FRAMEWORK_DIR" \
  --launch -- "$HELPER" \
  --test-bundle-path "$XCTEST_BUNDLE" \
  --testing-library swift-testing \
  --filter "MLTechniquePerfTests/profileLongLoop" 2>&1; then
  echo ""
  echo "WARNING: xctrace --launch failed. Fallback paths:" >&2
  echo "  1) Open Instruments.app, choose Time Profiler, then run:" >&2
  echo "       DYLD_FRAMEWORK_PATH=$TESTING_FRAMEWORK_DIR \\" >&2
  echo "       PROFILE_LOOPS=1 PROFILE_LOOPS_ITERS=$ITERS \\" >&2
  echo "       $HELPER \\" >&2
  echo "         --test-bundle-path $XCTEST_BUNDLE \\" >&2
  echo "         --testing-library swift-testing \\" >&2
  echo "         --filter MLTechniquePerfTests/profileLongLoop" >&2
  echo "     and attach Instruments to the helper PID." >&2
  echo "  2) Document the fallback path used in 4-3b-trace-profile.md." >&2
  exit 1
fi

echo ""
echo "Trace saved to: $TRACE_OUT"
echo "Open with: open '$TRACE_OUT'"
echo ""
echo "Extract top functions table:"
echo "  xctrace export --input '$TRACE_OUT' --xpath '/trace-toc/run/data/table[@schema=\"time-profile\"]'"
