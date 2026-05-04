---
name: bpm-diagnostic-trace
description: Use when adding, modifying, or auditing fields on `BPMDiagnosticTrace` — covers the typed-evidence pattern adopted in Story 3-3b, the anti-patterns it replaced, audit grep recipes for the four banned shapes, and the per-field implementation checklist. Triggers on "trace field", "BPMDiagnosticTrace", "diagnostic detail", "trace key", "%.1f trace", or any work touching `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift`.
---

# BPMDiagnosticTrace Field Pattern

## Overview

`BPMDiagnosticTrace` is BoomBoomBoomKit's public diagnostic record — populated when `analyzeBPM(...)` is called with `enableTrace: true`. It captures intermediate state from each step of the 10-step BPM pipeline so library consumers can debug edge cases.

The trace's file header says **"Evolving API — fields may change across versions"** (`Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:6`). This is a deliberate license to keep the schema honest, not a license to add fields casually. **Every new field is a public API surface — typed and bounded — that consumers will read.**

Story 3-3b (close-out 2026-05) standardized the shape of every detail field on the trace. This skill encodes that pattern so the next field added behaves like its peers, and so any drift can be caught in audit.

## When to use

Invoke this skill when:

- Adding a new field to `BPMDiagnosticTrace` (any field, but especially "detail" fields that capture per-step intermediate state).
- Modifying an existing field's type or semantics.
- Auditing the codebase for trace anti-patterns before a release.
- Reviewing a PR that touches `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` or any `trace?.X = ...` write site in `Sources/BoomBoomBoomKit/BPMAnalyzer.swift`.
- A consumer reports "two of my trace entries collapsed into one" or "my trace key disappeared" — a classic dictionary-collision symptom.

If your work doesn't touch the trace, skip this skill.

## The required pattern (post-Story-3-3b)

A trace detail field carrying **per-candidate, per-band, or per-event data** uses a typed array of `Sendable` evidence structs:

```swift
public struct BPMDiagnosticTrace: Sendable {
  // …other fields…

  /// Per-candidate normalized click correlation score.
  /// Populated only when `enableTrace: true` AND `.clickTrackCorrelation`
  /// is in the technique set. Nil when the technique was skipped.
  public var clickCorrelationDetail: [ClickCorrelationEntry]?
}

public struct ClickCorrelationEntry: Sendable, CustomStringConvertible {
  public let candidateIndex: Int
  public let bpm: Double
  public let normalizedClickScore: Float

  public init(candidateIndex: Int, bpm: Double, normalizedClickScore: Float) {
    self.candidateIndex = candidateIndex
    self.bpm = bpm
    self.normalizedClickScore = normalizedClickScore
  }

  public var description: String {
    "ClickCorrelationEntry(idx: \(candidateIndex), bpm: \(bpm), ncc: \(normalizedClickScore))"
  }
}
```

A trace detail field carrying **a single decision or summary record** uses a typed evidence struct (no array wrapper):

```swift
public var subBandVoteDetail: SubBandVoteEvidence?

public struct SubBandVoteEvidence: Sendable, CustomStringConvertible {
  public let preVoteBPM: Double
  public let postVoteBPM: Double
  public let changed: Bool
  // …public init + description as above…
}
```

A trace detail field carrying **a heterogeneous record with sub-collections** uses a typed evidence struct that contains its own typed sub-structs (no CSV serialization):

```swift
public var durationHintDetail: DurationHintEvidence?

public struct DurationHintEvidence: Sendable, CustomStringConvertible {
  public let fileDurationSeconds: Double
  public let barCandidates: [BarCandidate]
  public let boostedCandidates: [Double]
  // …
}

public struct BarCandidate: Sendable, CustomStringConvertible {
  public let bars: Int
  public let bpm: Double
  // …
}
```

### Five rules that make a field conformant

1. **Stored in `BPMDiagnosticTrace.swift`.** All evidence types colocate with the trace struct that owns them. Do **not** split into per-type files.
2. **`public struct`, conforms to `Sendable, CustomStringConvertible`.** Public memberwise `init`. `description` returns one line containing the meaningful field values (used in LLDB and `print()`).
3. **Native value types only.** `Int`, `Double`, `Float`, `Bool`, `String` for scalars; `[T]` for collections of `Sendable` types. **Never `[String: …]` for trace data.**
4. **Optional only when "absence of data" is meaningful.** Trace not requested ⇒ field is nil. Field requested but technique skipped ⇒ field is nil. Field requested AND technique ran ⇒ field is non-nil even when the inner array is empty (the empty array is itself information: "ran but produced nothing").
5. **Doc comment names the precondition.** Always document: "Populated only when `enableTrace: true` AND _<technique gate>_. Nil when _<reason>_." This contract is what lets consumers distinguish "feature off" from "feature on but no signal."

## The four banned anti-patterns

These shapes are forbidden on `BPMDiagnosticTrace`. All four shipped at some point during Stories 1-2 / 3-1 / 3-3 / 3-4 and were eliminated by Story 3-3b. **Re-introducing any of them is a regression.**

### 1. Dictionary keyed by stringified BPM — `[String: Float]?`

```swift
// FORBIDDEN
public var clickCorrelationDetail: [String: Float]?
// At write site:
detail[String(format: "%.1f", cand.bpm)] = clampedNCC
```

**Why it's forbidden.** Two candidates whose BPMs round to the same one-decimal label collapse silently into one entry. Example: `61.04` and `60.95` both round to `"61.0"`. The second write overwrites the first; the consumer sees one entry and has no way to detect the loss.

**Correct shape.** `[<TypedEntry>]?` where the entry struct carries the candidate's full-precision `bpm: Double` AND a `candidateIndex: Int` for stable ordering.

### 2. Dictionary with stringified-number values — `[String: String]?` (fixed keys)

```swift
// FORBIDDEN
public var subBandVoteDetail: [String: String]?
// At write site:
trace?.subBandVoteDetail = [
  "preVoteBPM": String(format: "%.1f", preVoteBPM),
  "postVoteBPM": String(format: "%.1f", winner.bpm),
  "changed": changed ? "true" : "false",
]
```

**Why it's forbidden.** No collision risk (the keys are fixed strings), but every consumer string-parses values that were already typed. `%.1f` discards two decimal places of precision. Booleans become `"true"`/`"false"` strings that don't compare safely. The dictionary's "any key permitted" surface area lies about the schema — there are exactly three keys, always.

**Correct shape.** `<TypedEvidence>?` struct with native-typed stored properties.

### 3. CSV-serialized arrays inside dictionary values

```swift
// FORBIDDEN (Story 3-4's original shape; banned by Story 3-3b)
detail["barCandidates"] =
  barCandidates.map { "\($0.bars)=\(String(format: "%.1f", $0.bpm))" }
  .joined(separator: ",")
```

**Why it's forbidden.** The consumer parses a string ("64=64.0,96=96.0,128=128.0") that was synthesized from `[(bars: Int, bpm: Double)]`. Both ends string-marshal a typed value across a string boundary in the same process. Empty-CSV vs nil-CSV becomes a parsing concern (`detail?["barCandidates"] == ""` vs `detail?["barCandidates"] == nil`) rather than a typed `Optional<[BarCandidate]>`.

**Correct shape.** `[BarCandidate]` directly inside the typed evidence struct. Empty array means "ran but produced nothing"; nil at the outer evidence-optional means "did not run."

### 4. Stringly-typed enums-as-string-values

```swift
// FORBIDDEN
trace?.harmonicRatioDetail = [
  "ratio": ev.ratio,        // ev.ratio is already "2:1" / "3:2" / "3:1"
  "fastBPM": String(format: "%.1f", ev.fastBPM),
  "slowBPM": String(format: "%.1f", ev.slowBPM),
  "winner": String(format: "%.1f", ev.winnerBPM),
]
```

**Why it's forbidden.** Same as #2, plus: `ev` is already a typed `HarmonicRatioEvidence`. The dictionary form throws away the type that was right there, then asks the consumer to reconstruct it from strings.

**Correct shape.** Promote the existing typed evidence to public; assign it directly: `trace?.harmonicRatioDetail = ev`.

## Audit recipes (grep)

Run these at any time. **Each must return zero matches** in `Sources/BoomBoomBoomKit/`.

### Recipe A — banned trace field types

```bash
grep -nE 'public var [a-zA-Z]+Detail: \[String: (Float|String|Int|Double|Bool)\]' \
  Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift
```

Any match is a banned shape per anti-patterns #1, #2.

### Recipe B — `%.1f` stringified BPM keys

```bash
grep -nE 'String\(format: ?"%\.1f", ?[a-zA-Z]+\.bpm\)' Sources/BoomBoomBoomKit/
```

`%.1f` formatting of BPM values is suspicious anywhere it's used as a dictionary key or written to a trace field. Inspect each match. (Some `%.1f` in log strings or test fixtures is fine; trace writes are not.)

### Recipe C — CSV serialization in trace writes

```bash
grep -nE 'trace\?\.[a-zA-Z]+Detail.*joined\(separator:' Sources/BoomBoomBoomKit/
```

Any match is anti-pattern #3.

### Recipe D — test consumer leftovers

After a trace migration, no test should still index a detail field by string key:

```bash
grep -rnE 'Detail\?\[\"' Tests/BoomBoomBoomKitTests/
grep -rnE 'Detail\[\"' Tests/BoomBoomBoomKitTests/
```

Both must be empty after a migration. If either matches, the migration left a string-key reader that compiles only because Swift dict-subscript on a typed struct is now a syntax error — meaning the test never ran. Catch it before CI does.

### Recipe E — non-`Sendable` evidence types

```bash
grep -nE 'public struct [A-Z][a-zA-Z]*Evidence' Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift \
  | grep -v ': Sendable'
```

Any match is missing `Sendable` conformance — a Swift 6 strict-concurrency violation waiting to surface in a consumer's `Task` boundary.

## Adding a new trace field — checklist

Before you write code, run **Recipe A** to confirm the file is currently clean.

For a new field on `BPMDiagnosticTrace`:

1. **Decide the cardinality.** Per-candidate / per-band / per-event ⇒ array of typed entries. Single decision ⇒ typed evidence struct (no array). Heterogeneous record ⇒ typed evidence struct that contains its own typed sub-structs.
2. **Define the type(s) in `BPMDiagnosticTrace.swift`.** `public struct <Name>Entry` (or `<Name>Evidence`): `Sendable, CustomStringConvertible`. All stored properties `public let`. Public memberwise `init`. `description` returns one line.
3. **Add a `// MARK: - Step N: <name>` header** above the field declaration. Match the step-numbered organization that already exists.
4. **Declare the field as `public var <name>Detail: <TypedShape>?`.** Always optional. Initial value `nil` (implicit; do not write `= nil`).
5. **Doc comment names the precondition** with the "Populated only when X AND Y. Nil when Z." formula. Always specify what differentiates "did not run" from "ran but produced nothing."
6. **At the producer write site (typically in `BPMAnalyzer.swift`)**: gate on `let writeTrace = trace != nil` (or `options.enableTrace` if outside the trace-bound scope), accumulate locally into typed values, assign once at the end of the producer function. **Never accumulate into a `[String: …]` and convert at the end.**
7. **Run the audit recipes.** A through E must all return zero matches.
8. **Write a test in `Tests/BoomBoomBoomKitTests/BPMDiagnosticTraceTests.swift`** (or the suite that already covers the producer) that exercises the new field with `enableTrace: true` and asserts the typed properties exist and carry the expected values. Use exact equality on `Double`/`Int`/`Bool`. For `Float`, use `abs(a - b) < tolerance`.
9. **Update this skill** if the new field reveals a new shape that should become canonical. (For example: a future "per-window decision log" might motivate a fourth shape — array of typed structs with non-monotonic indices. Document it here so the next developer can match the precedent.)
10. **Update `_bmad-output/project-context.md`** if the trace's public surface area expands in a way that affects an architectural rule. Adding one more typed evidence struct to a trace whose pattern is already documented does not require a context-md update.

## Modifying an existing trace field

Modifying = renaming, adding a stored property, deprecating, or removing.

- **Renaming a field:** treat as a public API breaking change. Same commit must update all consumers in `Tests/`. Run `grep -rn '<oldFieldName>' Sources/ Tests/` and confirm zero matches before commit.
- **Adding a stored property to an existing evidence struct:** the public memberwise `init` must be regenerated (Swift does NOT auto-generate a public init when the struct is public; the explicit `public init` you wrote is the source of truth). Update every construction site.
- **Removing a field:** delete declaration + all writes + all tests in the same commit. Add a Change Log entry to the story file and a note in `BPMDiagnosticTrace.swift`'s file header.
- **Always rerun audit recipes A–E** after the change.
- **Always rerun `make benchmark`, `make benchmark-giantsteps`, `make oracle`** after the change. Trace changes never alter DSP — any accuracy delta is a bug.

## Why this pattern, briefly

Story 3-3 added `clickCorrelationDetail: [String: Float]?` keyed by `String(format: "%.1f", bpm)` because the dict shape mirrored other trace fields' "easy to inspect in `print()`" affordance. Code-review (Codex Edge-Case-Hunter) flagged that two candidates differing by less than 0.1 BPM collapse silently. The same `%.1f` pattern was already in place for `harmonicRatioDetail` (Story 3-1), `subBandVoteDetail` (Story 1-2), and Story 3-4 then added a fourth — `durationHintDetail` — with the same shape PLUS CSV-serialized sub-arrays.

Story 3-3b migrated all four to typed evidence structs in one cross-cutting commit. The `CustomStringConvertible` conformance (AC #7 of that story) preserves the "easy to print" affordance the dicts had. The typed `[Entry]` shape preserves candidate identity through `candidateIndex`. The `Sendable` conformance keeps the trace usable across `Task` boundaries.

The lesson generalized: **a trace field's value type must carry the same precision and structure as the data the producer computed — no string round-trip.** This skill exists so the next contributor doesn't have to relearn that.

## References

- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` — canonical home of all trace types.
- `_bmad-output/implementation-artifacts/3-3b-trace-key-namespacing.md` — the story that established this pattern.
- `_bmad-output/implementation-artifacts/3-3-click-track-cross-correlation.md:210` — origin of the deferred finding that became Story 3-3b.
- `_bmad-output/project-context.md` (sections "Access control boundaries", "Critical Don't-Miss Rules → API contract violations") — public-promotion rule and `Sendable` requirement that this pattern enforces.
- `running-benchmarks` skill — invoke after any trace-touching change to verify accuracy floors hold byte-for-byte.
