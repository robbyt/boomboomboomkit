#!/usr/bin/env python3
"""
analyze-time-profile.py

Parse `xctrace export --xpath '/trace-toc/run/data/table[@schema="time-profile"]'`
output and emit:
  - Top N "leaf" functions (top frame in each backtrace, weighted by sample weight).
  - Top N "ancestor" functions (any frame, useful for inclusive cost).
  - Allocation site placeholder (separate Allocations template needed for true sizes).

Usage:
  uv run _bmad-output/scripts/analyze-time-profile.py /tmp/4-3b-time-profile.xml

Notes:
  xctrace XML uses `<deduplicated_symbol>` and id/ref pointers. We resolve refs
  by building a symbol table on first pass, then walking each row's backtrace
  on second pass. Samples are weighted by the `<weight>` field (microseconds
  in `weight` element fmt; we use the integer ns value).
"""
from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from collections import Counter

if len(sys.argv) < 2:
    sys.stderr.write("Usage: analyze-time-profile.py <time-profile.xml>\n")
    sys.exit(2)

XML_PATH = sys.argv[1]

# Build a flat element-by-id table by streaming. xctrace's id/ref scheme
# means earlier rows define and later rows reference; iterparse handles this
# naturally because all references appear after their definitions.
print(f"Parsing {XML_PATH}…", file=sys.stderr)

tree = ET.parse(XML_PATH)
root = tree.getroot()

# Collect every element with an id attribute into a lookup.
id_table: dict[str, ET.Element] = {}
for el in root.iter():
    eid = el.get("id")
    if eid is not None:
        id_table[eid] = el


def resolve(el: ET.Element) -> ET.Element:
    """Follow `ref="N"` to the canonical element, recursively."""
    ref = el.get("ref")
    if ref is None:
        return el
    target = id_table.get(ref)
    if target is None:
        return el
    return resolve(target)


def frame_name(frame_el: ET.Element) -> str | None:
    """Get a human-readable function name for a <frame> element, resolving refs."""
    canon = resolve(frame_el)
    name = canon.get("name")
    if name:
        return name
    return None


leaf_counter: Counter[str] = Counter()  # samples × weight, leaf frame only
ancestor_counter: Counter[str] = Counter()  # inclusive: every frame in stack

total_weight_ns = 0
sample_count = 0

for row in root.iter("row"):
    # weight is in nanoseconds (the integer text), formatted as "N.NN ms"
    w_el = row.find("weight")
    if w_el is None:
        continue
    w_canon = resolve(w_el)
    try:
        weight_ns = int(w_canon.text or "0")
    except (TypeError, ValueError):
        continue

    bt_el = row.find("tagged-backtrace")
    if bt_el is None:
        continue
    bt_canon = resolve(bt_el)
    backtrace = bt_canon.find("backtrace")
    if backtrace is None:
        backtrace = bt_canon  # in case it IS the backtrace already

    # Find frames in document order; the FIRST frame is the deepest (leaf).
    frames = list(backtrace.iter("frame"))
    if not frames:
        continue

    leaf = frame_name(frames[0])
    if leaf:
        leaf_counter[leaf] += weight_ns

    seen_in_stack: set[str] = set()
    for f in frames:
        nm = frame_name(f)
        if nm and nm not in seen_in_stack:
            ancestor_counter[nm] += weight_ns
            seen_in_stack.add(nm)

    total_weight_ns += weight_ns
    sample_count += 1


def fmt_pct(weight: int) -> str:
    if total_weight_ns == 0:
        return "  0.0%"
    return f"{(weight / total_weight_ns) * 100:5.1f}%"


def fmt_ms(weight: int) -> str:
    return f"{weight / 1_000_000:7.1f} ms"


print(f"\nTotal samples: {sample_count}")
print(f"Total weight:  {total_weight_ns / 1_000_000_000:.3f} s")
print()

print("=== Top 30 leaf functions (top of stack, exclusive cost) ===")
for name, w in leaf_counter.most_common(30):
    print(f"  {fmt_pct(w)}  {fmt_ms(w)}  {name}")

print()
print("=== Top 30 ancestor functions (anywhere in stack, inclusive cost) ===")
for name, w in ancestor_counter.most_common(30):
    print(f"  {fmt_pct(w)}  {fmt_ms(w)}  {name}")

print()
print("=== Top 30 BoomBoomBoomKit-prefixed functions (leaf) ===")
bbk = [
    (n, w) for n, w in leaf_counter.most_common(500)
    if "BPMAnalyzer" in n or "BoomBoomBoomKit" in n
    or "BPMDiagnostic" in n or "AudioAnalysisService" in n
    or "MelFilterbank" in n or "OnsetEnvelope" in n
    or "Tempogram" in n or "Autocorrelation" in n
]
for name, w in bbk[:30]:
    print(f"  {fmt_pct(w)}  {fmt_ms(w)}  {name}")

print()
print("=== Top 30 BoomBoomBoomKit-prefixed functions (ancestor / inclusive) ===")
bbk2 = [
    (n, w) for n, w in ancestor_counter.most_common(500)
    if "BPMAnalyzer" in n or "BoomBoomBoomKit" in n
    or "BPMDiagnostic" in n or "AudioAnalysisService" in n
    or "MelFilterbank" in n or "OnsetEnvelope" in n
    or "Tempogram" in n or "Autocorrelation" in n
]
for name, w in bbk2[:30]:
    print(f"  {fmt_pct(w)}  {fmt_ms(w)}  {name}")
