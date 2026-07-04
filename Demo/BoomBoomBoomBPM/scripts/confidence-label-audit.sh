#!/usr/bin/env bash
#
# FR-44 confidence-label audit + FR-43 no-diagnostic-leak tripwire (Story 9.3).
#
# Fails `make demo-lint` if any confidence-like value is rendered as a bare
# numeric (no label), or if the Story-9.2 signal-pool diagnostic table leaks
# into the primary view. Develop-only: Demo/ ships via `make demo-archive`,
# never to main.
#
# Scope + limits (Story 9.3 DD3): this is a FORWARD GUARD for the common
# bare-interpolation anti-pattern, not a completeness proof of FR-44. Known
# regex blind spots (accepted — the pressure-release valve covers brittleness):
# a label-less `Text(String(format:...))`/`monoFloat(...)` (the value is in the
# argument, not the string), an inner-string-literal interpolation, a raw
# Swift string `#"...\#(...)..."#`, a bare interpolation with an ALPHABETIC unit
# suffix (`"\(x) dB"` — the trailing-suffix match stops at the first letter to
# avoid flagging trailing labels), and a THEORETICAL false-positive on a label
# that FOLLOWS a leading interpolation (`"\(a) confidence: \(b)"`) — none occur
# in the current demo. These are covered by the render inventory + review. (A
# NON-alphabetic unit suffix such as `%` IS now caught — Codex PR #88 review.)
set -euo pipefail

SRC="Demo/BoomBoomBoomBPM/BoomBoomBoomBPM"
CONTENT_VIEW="$SRC/ContentView.swift"

# A double-quoted Swift string that is a BARE interpolation — starts with `\(`,
# no leading label — of a confidence-like value, optionally followed by a
# non-alphabetic unit suffix (`%`, whitespace, digits, symbols) before the
# closing quote. Wrapper-agnostic (no `Text(` anchor), so it catches
# `Text("\(x.confidence)")`, `Text("\(x.confidence)%")`, AND the demo's own
# `secondaryMetadataRow("\(x.confidence)")` primary-view pattern. A labeled
# render (`"BPM confidence: \(x)"`) starts with a letter, not `\(`, so it is not
# matched. The trailing suffix stops at the first LETTER so an alphabetic unit
# (`"\(x) dB"`) stays a documented blind spot — a trailing letter could be a
# legitimate label, and broadening there is the brittleness DD3's pressure-
# release valve exists for.
PATTERN='"\\\([^"]*([Cc]onfidence|[Ww]eight|[Ss]oftmax|reliability|[Ss]core|[Ee]ffectiveVote|[Vv]ote)[^"]*\)[^"[:alpha:]]*"'

# The gate must FAIL, never silently pass, if it cannot see what it audits
# (Codex review: a missing path makes `grep` error, which a naked `if grep`
# would swallow as "no violations"). Check existence up front.
if [ ! -d "$SRC" ]; then
  echo "confidence-label-audit: CANNOT RUN — source dir missing: $SRC" >&2
  exit 3
fi
if [ ! -f "$CONTENT_VIEW" ]; then
  echo "confidence-label-audit: CANNOT RUN — ContentView missing: $CONTENT_VIEW" >&2
  exit 3
fi

# Non-vacuous self-test: the pattern MUST fire on the known-bad forms, or the
# gate has silently broken (a bad regex edit, a grep-dialect or escaping slip).
for bad in \
  'Text("\(row.confidence)")' \
  'secondaryMetadataRow("\(row.confidence)")' \
  'Text("\(row.confidence)%")' \
  'secondaryMetadataRow("\(row.confidence)%")'; do
  if ! printf '%s\n' "$bad" | grep -qE "$PATTERN"; then
    echo "confidence-label-audit: SELF-TEST FAILED — pattern no longer catches: $bad" >&2
    exit 2
  fi
done

# Negative self-test: the sanctioned leading-label form MUST NOT trip the gate,
# or a regex edit has introduced a false positive on a correctly-labeled render.
for ok in 'Text("BPM confidence: \(row.confidence)")'; do
  if printf '%s\n' "$ok" | grep -qE "$PATTERN"; then
    echo "confidence-label-audit: SELF-TEST FAILED — pattern false-positives on a labeled render: $ok" >&2
    exit 2
  fi
done

# FR-44 audit. Capture grep's status explicitly so we distinguish 0 (matches =
# violation), 1 (clean = pass), and >=2 (grep error = fail loudly). `--include`
# precedes the search root for portability (BSD/GNU).
set +e
fr44="$(grep -rnE --include='*.swift' "$PATTERN" "$SRC")"
fr44_status=$?
set -e
if [ "$fr44_status" -eq 0 ]; then
  printf '%s\n' "$fr44" >&2
  echo "confidence-label-audit: FR-44 violation — a confidence-like value is rendered without a label." >&2
  echo "  Add a label, e.g. \"BPM confidence: \\(x)\" instead of a bare \"\\(x)\"." >&2
  exit 1
elif [ "$fr44_status" -ge 2 ]; then
  echo "confidence-label-audit: CANNOT RUN — grep errored (status $fr44_status) during the FR-44 scan." >&2
  exit 3
fi

# FR-43 tripwire: the signal-pool diagnostic table (Story 9.2) must live only in
# the sidebar (TraceView), never in the primary view. Match an INSTANTIATION
# (`SignalPoolDiagnosticTable(`), not a bare-name mention, so a comment
# referencing the type does not trip the gate (Codex review).
set +e
fr43="$(grep -nE 'SignalPoolDiagnosticTable[[:space:]]*\(' "$CONTENT_VIEW")"
fr43_status=$?
set -e
if [ "$fr43_status" -eq 0 ]; then
  printf '%s\n' "$fr43" >&2
  echo "confidence-label-audit: FR-43 violation — the signal-pool diagnostic table leaked into the primary view (ContentView.swift)." >&2
  exit 1
elif [ "$fr43_status" -ge 2 ]; then
  echo "confidence-label-audit: CANNOT RUN — grep errored (status $fr43_status) during the FR-43 scan." >&2
  exit 3
fi

echo "confidence-label-audit: PASS"
