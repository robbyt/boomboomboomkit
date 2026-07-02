---
baseline_commit: 9b3c6e3230e5eb54324d0eebf1db9e0827236afa
---

# Story 8.3: `BeatGrid` + `BeatTimestamp` + tri-state `DownbeatResult` public types

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a library consumer,
I want typed beat-grid result containers (`BeatGrid`, `BeatTimestamp` with `confidence` + `strength`, tri-state `DownbeatResult`) landed as public types **before** the beat-tracking algorithm itself,
so that Story 8.4's `BeatGridAnalyzer` has a stable result shape to populate, and Epic 10's demo `BeatGridTimelineView` (FR-39) can begin design work against the public type.

This is a **types-only** story. No beat-tracking algorithm, no pipeline step-11 insertion, no `analyzeBeatGrid(...)` service method — all of that is Story 8.4. The deliverable here is three pure value types plus their tests, plus the DocC/README documentation obligation Mary's seam rule assigns to Epic 8 stories.

## Context & critical corrections (read before writing code)

The mandatory pre-spec grep against the live codebase found **three factual errors in the epics-md ACs** for this story. The corrections below are authoritative; the epics ACs are superseded where they conflict.

1. **AC5's `BPMDiagnosticTrace.beatGridPlaceholder` seam DOES NOT EXIST.** This correction has two parts — separate them so neither over-claims (Mary's pressure-test):
   - **1a (verified fact):** Grep of `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` returns zero matches for `beatGridPlaceholder` / `BeatGridTraceEntry` / `beatGrid`. This is the same "Story 6.2 seam was never built" pattern Stories 8.1 and 8.2 each hit and documented. There is no internal Epic-6 beat-grid trace field to promote.
   - **1b (design choice, argued affirmatively — NOT merely inferred from 1a):** 8.3 exposes the beat grid as a **public value type**, not a `BPMDiagnosticTrace` field, and that choice *fully* serves every downstream consumer: the Epic-10 FR-39 `BeatGridTimelineView` consumes a public `BeatGrid` value (verified field-sufficient — see AC8/DD #6), and the Story 8.4 algorithm populates and returns that same value type. Per **KDD-T0**, a trace field is added ONLY when the type *affects winner selection, weight resolution, or gate firing* AND the boundary is ambiguous. Beat grid is a **parallel output** (Story 8.4 inserts it as pipeline step 11, *post-disambiguation*); it does not feed BPM winner selection. **KDD-T0 therefore does not trigger for the types-only landing in 8.3.**
   - **Re-evaluation hook (not "never"):** `SignalSource.beatGrid` already exists producerless (W53). When Story 8.4+ wires a beat-grid *producer* into the unified pool, `estimatedTempo`/`confidence` become weight-resolution inputs and **KDD-T0 MUST be re-run** — `signalParticipationTrace` already reserves the `.beatGrid` case for that field. 8.3 asserts "no trace field *in 8.3*," not "no trace field ever." This forward-seam decision is recorded as deferred-work **W74** (see DD #6).
   - The seam-mitigation obligation for 8.3 reduces (exactly as Story 8.1 reduced it) to: DocC `///` on the three new public types + a README "Beat grid" section + the 5-recipe `bpm-diagnostic-trace` audit returning zero matches (trivially true, since no trace field is added). See DD #6.

2. **AC4's `Double.bitEqual(to:)` is the WRONG API.** The actual helper is `NumericTestHelpers.bitEqual(_ lhs:_ rhs:)` — a **static, two-argument** function (overloaded for `Double` and `Float`) in `Sources/BoomBoomBoomKitTestSupport/NumericTestHelpers.swift:16,22`. There is no instance method `Double.bitEqual(to:)`. Use `NumericTestHelpers.bitEqual(a, b)`.

3. **`Hashable` + `Codable` are sound here ONLY because every float field is clamped finite at construction.** The shipped `LUFSReport` (Story 8.1) *dropped* `Hashable` and is *not* `Codable` — it carries unsanitized `Double` time-series payloads and chose value-carrier semantics. 8.3 is different: **KDD-C2 (architecture, authoritative) explicitly declares all three types `Hashable`**, and the Codable round-trip AC requires `Codable`. The only blocker to `Hashable`/synthesized `Equatable` is `Double.nan` (non-reflexive). Clamping **every** float field to finite at construction removes that blocker. So 8.3 keeps `Hashable` + `Codable` per KDD-C2, but the clamping AC must cover **all** float fields, not just `BeatTimestamp.confidence`/`strength` (the epics AC under-specified this — `presentationTime` and `BeatGrid.estimatedTempo`/`confidence` MUST clamp too). See DD #2 and DD #3. This divergence from `LUFSReport` is intentional and must be documented in the type doc comments so a reviewer does not flag it as inconsistency.

## Acceptance Criteria

**AC1 — Three public value types, exact shapes (KDD-C2).**
Given new files `Sources/BoomBoomBoomKit/BeatGrid.swift`, `Sources/BoomBoomBoomKit/BeatTimestamp.swift`, `Sources/BoomBoomBoomKit/DownbeatResult.swift`,
When the test suite runs,
Then all three types are `public`, `Sendable`, `Hashable`, `Codable`, `CustomStringConvertible`; and:
- `BeatGrid` carries **exactly five** stored fields: `beats: [BeatTimestamp]`, `downbeats: DownbeatResult`, `estimatedTempo: Double`, `confidence: Float`, `tempoAgreedWithBPMStage: Bool?`.
- `BeatTimestamp` carries **exactly three** stored fields: `presentationTime: Double`, `confidence: Float`, `strength: Float`.
- `DownbeatResult` carries **exactly three** cases: `.notAttempted`, `.noneDetected`, `.detected(beats: [BeatTimestamp])`. **The associated value is labeled `beats:`** — a deliberate refinement of KDD-C2's shorthand `.detected([BeatTimestamp])` (see DD #9): the label hardens the public Codable JSON contract to the stable, self-documenting `{"detected":{"beats":[…]}}` instead of the positional `{"detected":{"_0":[…]}}` synthesized for an unlabeled payload (SE-0295). Pre-1.0, so the call-site change costs nothing.

**AC2 — `BeatTimestamp.init` clamps all three fields finite (KDD-C2 Amelia provenance rule).**
Given `BeatTimestamp.init(presentationTime:confidence:strength:)`,
When `confidence` or `strength` (both **`Float`** — use `Float.nan` / `Float.infinity` literals, NOT `Double.nan`, which will not compile into a `Float` parameter) is passed `Float.nan`, `Float.infinity`, or a value outside `[0.0, 1.0]`,
Then the init silently clamps to `[0.0, 1.0]` (NaN → 0.0) — never throws, never propagates NaN;
And when `presentationTime` (**`Double`** — `Double.nan` / `±Double.infinity` are the correct literals here) is passed `Double.nan`/`±Double.infinity` or a negative value, the init clamps it to `0.0` (non-finite → 0.0; finite negative → 0.0 — playback time is `≥ 0` by definition). This guarantees `BeatTimestamp` carries no non-finite float, which is the precondition for sound `Hashable`/`Equatable`.
Per-field literal types (compile-trap guard): `presentationTime: Double` → `Double.nan`; `confidence: Float`, `strength: Float` → `Float.nan`. The clamp helpers are precision-matched: `clampUnit(_ x: Float) -> Float` and `clampNonNegative(_ x: Double) -> Double` (DD #2, named once, reused across both types).

**AC3 — `BeatGrid.init` clamps its float fields finite.**
Given `BeatGrid.init(beats:downbeats:estimatedTempo:confidence:tempoAgreedWithBPMStage:)`,
When `estimatedTempo` (**`Double`**) is non-finite (`Double.nan`/`±Double.infinity`) **OR non-positive (`≤ 0`)**, the init clamps it to `0.0` — the documented canonical "no valid tempo estimate" sentinel (also the empty-grid sentinel, AC7). A negative BPM is physically impossible and is treated as the same equivalence class as absence (operator decision 2026-06-13: clamp non-positive → 0, consistent with `presentationTime ≥ 0` and the `SignalWeights`/`ComputeBudget` isFinite-first/non-negative init precedent); **positive finite `estimatedTempo` passes through UNCLAMPED** — beat-grid tempo is an independent estimate, not bound to the BPM stage's 60–200 range, and plausibility/range validation is Story 8.4's algorithm concern, not this value type's. See DD #8.
And when `confidence` (**`Float`** — `Float.nan`/`Float.infinity` literals) is non-finite or outside `[0.0, 1.0]`, the init clamps to `[0.0, 1.0]` (NaN → 0.0).

**AC4 — synthesized `Hashable`/`Equatable` is correct because clamping removed NaN.**
Given all float fields are finite post-init,
When `Hashable`/`Equatable` conformance is exercised,
Then the conformances are **compiler-synthesized** (NOT hand-written `bitPattern` comparisons à la `MLExecutionPolicy`) — and this is correct *precisely because* clamping guarantees no NaN can reach the synthesized `==`/`hash(into:)`. A unit test constructs two `BeatTimestamp`/`BeatGrid` values from NaN inputs and asserts `a == a` (reflexivity) and `a == b` for equal clamped inputs, with matching `hashValue`.

**AC5 — `DownbeatResult` is NOT `CaseIterable`; coverage enforced by exhaustive switch.**
Given `DownbeatResult` has an associated-value case (`.detected(beats: [BeatTimestamp])`),
When the pattern-coverage invariant test runs,
Then `DownbeatResult` does **not** conform to `CaseIterable` — this is **forced, not chosen**: `CaseIterable` synthesis is suppressed by the compiler the moment any case carries a payload (Siri, SE-0295), and `.detected`'s payload is unbounded so `.allCases` would be meaningless anyway (the `MLExecutionPolicy` precedent is corroborating, not the primary reason). Coverage is enforced by a dedicated test containing an **exhaustive `switch`** over all three cases with **no `default:` clause** (a future added case — e.g. a Story 8.4 `.ambiguous` — forces a compile error in that test; a `default:` would silently swallow it). The same no-`default:` discipline applies to `DownbeatResult.description` (Task 2).

**AC6 — `Codable` round-trip is bit-exact, clamp-invariant-preserving.**
Given `Codable` round-trip tests for `BeatGrid`, `BeatTimestamp`, and `DownbeatResult`,
When every `DownbeatResult` case (including `.detected(beats:)` with **0, 1, and 200** beats) and representative `BeatGrid`/`BeatTimestamp` values round-trip through `JSONEncoder` → `JSONDecoder`,
Then the decoded value equals the encoded value under `NumericTestHelpers.bitEqual(_:_:)` applied field-by-field (Double and Float overloads). **"Bit-exact" mechanism note (Siri):** this holds not because JSON stores binary (JSON is decimal text) but because Foundation emits each finite `Double`/`Float` as its *shortest round-trippable decimal description*, which `JSONDecoder` parses back to the bit-identical value. The test pins this on a 4-value worst-case `Double` corpus — `0.1`, `Double.pi`, `Double.leastNormalMagnitude`, `Double.greatestFiniteMagnitude` — to verify on-toolchain (the Swift-6/macOS-15 `swift-foundation` JSON-coder rewrite preserves this by design, but a 4-value test converts "documented intent" into "verified here").
And the JSON wire-shape is asserted per case: `.detected(beats:)` → `{"detected":{"beats":[…]}}` (labeled payload, DD #9); the no-payload cases → `{"notAttempted":{}}` / `{"noneDetected":{}}` (SE-0295 case-name-key → empty object, **not** a bare string `"notAttempted"`).
And a **hostile-JSON test** decodes a hand-authored payload carrying **finite but semantically out-of-range** values — `confidence: 5.0`, `strength: -2.0`, `presentationTime: -1.0`, `estimatedTempo: -120.0` — and asserts the decoded instance satisfies the clamp invariant: `confidence`/`strength` ∈ `[0,1]`, `presentationTime == 0.0`, **`estimatedTempo == 0.0`** (negative → no-estimate sentinel per AC3). This proves `init(from:)` routes through the clamping path rather than assigning decoded scalars directly (DD #3). Scope note: non-finite (`NaN`/`±Infinity`) values are **out of scope for the hostile-JSON test** — standard JSON has no NaN/Infinity literal and Foundation's default `nonConformingFloatEncodingStrategy`/`...DecodingStrategy` is `.throw`, so `JSONDecoder` rejects them before `init(from:)` runs; the non-finite clamp path is exercised by the in-memory AC2/AC3 tests, not via JSON.
And a **round-trip-of-round-trip** test (Siri): `decode → encode → decode` again on the hostile payload, asserting the second decode equals the first (catches an encode-side key the decoder ignores, which a single round-trip would mask).

**AC7 — empty/`.notAttempted` "no beat-grid run" sentinel is documented and distinguishable.**
Given the public ergonomics test,
When a consumer constructs `BeatGrid(beats: [], downbeats: .notAttempted, estimatedTempo: 0, confidence: 0, tempoAgreedWithBPMStage: nil)`,
Then this exact shape is the documented canonical "no beat-grid run" sentinel (DocC on `BeatGrid` states it verbatim), and it is distinguishable in code from `.noneDetected` (which means "downbeat detection *ran* and found none"). A test asserts the two are `!=` and that `.notAttempted != .noneDetected`.

**AC8 — seam-mitigation reduces to documentation (no trace field; KDD-T0 does not trigger).**
Given Mary's Epic-6 → Epic-8 seam-mitigation rule and the verified absence of any internal beat-grid trace seam (see Context correction #1),
When this story lands,
Then (a) the three new public types each carry DocC `///` doc comments (type-level + every public member); (b) the README gains a "Beat grid" section that introduces the result shape and forward-points to Story 8.4's `analyzeBeatGrid`; (c) the 5-recipe `bpm-diagnostic-trace` skill audit returns **zero** matches against `Sources/` and `Tests/`; (d) the PR description states explicitly that 8.3 introduces **no** `BPMDiagnosticTrace` field in 8.3, records the KDD-T0 non-trigger rationale (beat grid does not affect BPM winner selection), AND records the **W74 re-evaluation hook** (KDD-T0 MUST be re-run when 8.4+ wires a beat-grid producer into the unified pool via `SignalSource.beatGrid`); (e) **FR-39 type-sufficiency is confirmed** — `BeatGrid`'s public fields cover everything `BeatGridTimelineView` (FR-39) renders: tempo (`estimatedTempo`), beat count (`beats.count`), downbeat status (`downbeats`), grid confidence (`confidence`), and per-beat timeline position (`BeatTimestamp.presentationTime`, with `strength` available for beat-emphasis rendering). No field is missing; no type change is deferred to Epic 10 (Mary's stakeholder-drop check, verified against `epics.md:103,330`).

**AC9 — no behavioral / accuracy / perf impact; existing analyzer stub untouched.**
Given 8.3 is types-only,
When `make build`, `make test`, `make fmt`, `make lint` run,
Then all pass; `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift` (the Story 8.2 placeholder) is **not modified** (Story 8.4 owns wiring the `BeatGrid` type into it); no `BPMAnalyzer`/`AudioAnalysisService`/`LUFSAnalyzer` source changes; and the four corpus floors are **not run as a gate** (no DSP touched — but the dev agent confirms zero diff under `Sources/BoomBoomBoomKit/*.swift` except the three new files + README, so the floors cannot move by construction).

**FRs covered:** FR-27 (beat-grid extraction — **result-shape portion only**; the `analyzeBeatGrid(url:options:)` method + pipeline step-11 insertion that the FR-27 verb "returns…" describes is Story 8.4, which also cites FR-27 partial at `epics.md:1039`), FR-28 (downbeat tri-state — **fully** covered; the `.notAttempted`/`.noneDetected`/`.detected` distinction IS the type, `epics.md:89`).
**KDDs implemented:** C2 (`BeatGrid` result type shape), C6 (no engine protocol — concrete result types only, engine abstraction deferred to second impl).
**Pressure-release valve:** None. Pure type definitions; if any AC resists, the story is mis-scoped, not the types.

## Tasks / Subtasks

- [x] **Task 1 — `BeatTimestamp.swift`** (AC: 1, 2, 4, 6)
  - [x] Define `public struct BeatTimestamp: Sendable, Hashable, Codable, CustomStringConvertible` with the three `public let` fields.
  - [x] **Explicit `public init(presentationTime:confidence:strength:)`** over all stored properties — NOT "memberwise": Swift's synthesized memberwise init is `internal`, so a public struct needs an explicit one (Amelia/Codex). This is *the clamping init*: `confidence`/`strength` (`Float`) → `[0,1]` (NaN→0); `presentationTime` (`Double`) → non-finite→0.0 and finite-negative→0.0. Factor into the two precision-matched shared helpers `clampUnit(_:Float)->Float` / `clampNonNegative(_:Double)->Double` (DD #2) — do not improvise inline clamp forms.
  - [x] Custom `init(from decoder:)` that decodes raw scalars **into locals, then constructs `self` via the clamping init** (`self.init(presentationTime:…, confidence:…, strength:…)`). It **MUST NOT** assign decoded values directly to stored properties (`self.confidence = try container.decode(...)`) — that bypasses the clamp and lets a hostile out-of-range value survive, defeating the entire design (Amelia trap A, Siri Claim 1 caveat). Let `encode(to:)` be **synthesized**; do **not** hand-roll it. Do **not** declare an explicit `enum CodingKeys` (the synthesized one, keyed by stored-property names, is shared by the synthesized `encode` and referenced by the custom decoder — declaring an explicit/renamed one risks the encode/decode key desync Siri flagged in Claim 2; only introduce one if you make BOTH halves explicit together).
  - [x] `description` returns one line, e.g. `"BeatTimestamp(t: \(presentationTime)s, conf: \(confidence), str: \(strength))"`.
  - [x] Type-level + per-member DocC `///`. Document the clamp contract and the "divergence from LUFSReport: clamped → Hashable is sound" rationale.

- [x] **Task 2 — `DownbeatResult.swift`** (AC: 1, 5, 6)
  - [x] Define `public enum DownbeatResult: Sendable, Hashable, Codable, CustomStringConvertible` with exactly `.notAttempted` / `.noneDetected` / **`.detected(beats: [BeatTimestamp])`** (labeled payload, DD #9 — yields the stable `{"detected":{"beats":[…]}}` JSON instead of positional `{"detected":{"_0":[…]}}`). Synthesized `Codable` (the `.detected` payload delegates element decode to `BeatTimestamp`'s clamping `init(from:)`, so the clamp invariant propagates through the enum). Verify all three JSON case-shapes, including the no-payload shape `{"notAttempted":{}}` (SE-0295 case-name-key → empty object, not a bare string).
  - [x] Do **not** add `CaseIterable` — it is **un-synthesizable** for an enum with a payload case (compiler-suppressed; Siri/SE-0295), not merely a style choice. Add a doc comment stating that, so no one "helpfully" tries to hand-roll `allCases`.
  - [x] `description` via an **exhaustive `switch` with no `default:`** (so a future `.ambiguous` is a compile error here, not a silent fallthrough): `"notAttempted"` / `"noneDetected"` / `"detected(\(beats.count) beats)"`.
  - [x] DocC `///` distinguishing `.notAttempted` (grid never ran) from `.noneDetected` (ran, found none).

- [x] **Task 3 — `BeatGrid.swift`** (AC: 1, 3, 4, 6, 7)
  - [x] Define `public struct BeatGrid: Sendable, Hashable, Codable, CustomStringConvertible` with the five `public let` fields.
  - [x] **Explicit `public init(beats:downbeats:estimatedTempo:confidence:tempoAgreedWithBPMStage:)`** (not "memberwise") clamping `estimatedTempo` (`Double`; **non-finite OR non-positive → 0.0**, DD #8) and `confidence` (`Float`; `[0,1]`, NaN→0 via `clampUnit`). `beats`/`downbeats` carry already-clamped `BeatTimestamp`s by construction; `tempoAgreedWithBPMStage: Bool?` needs no clamping.
  - [x] Custom `init(from decoder:)` decoding into locals then **delegating to the clamping init** (never direct property assignment — same trap-A rule as Task 1); synthesized `encode(to:)`; no explicit `CodingKeys`.
  - [x] `description` one line summarizing counts + tempo + agreement, rendering the `Bool?` explicitly for all three states (e.g. `tempoAgreed: true|false|unknown` — never force-unwrap; the `nil` case must print, Amelia trap F).
  - [x] DocC `///` — type-level doc states the canonical "no beat-grid run" sentinel verbatim (AC7), notes `estimatedTempo == 0.0` is the "no valid estimate" sentinel (negative and non-finite both normalize here; read `estimatedTempo > 0` to gate validity), and documents the `tempoAgreedWithBPMStage` nil-vs-Bool semantics (KDD-C3: nil when no BPM analysis ran in the same call).

- [x] **Task 4 — Tests** `Tests/BoomBoomBoomKitTests/BeatGridTypesTests.swift` (AC: 1–7)
  - [x] Shape/sentinel assertions (construct each type; the compiler enforces field count, so assert the documented sentinel and case set rather than reflecting on stored-field count — `Mirror` is not a public contract, Codex).
  - [x] Clamp tests, **split per field-family** (Amelia trap C — a single `@Test(arguments:)` cannot take a heterogeneous `[Double.nan, Float.nan]` collection; the element type won't unify): one parameterized `@Test` over the `Double` fields (`presentationTime`, `estimatedTempo`) fed `Double.nan`/`±Double.infinity`/out-of-range; a separate one over the `Float` fields (`confidence`, `strength`) fed `Float.nan`/`Float.infinity`/out-of-range. Assert finite, in-range outputs with exact equality (e.g. `#expect(ts.confidence == 0.0)` after `Float.nan`).
  - [x] **Negative-finite `estimatedTempo` test** (DD #8): `BeatGrid(estimatedTempo: -120.0, …)` → `estimatedTempo == 0.0`; and a positive edge tempo (e.g. `250.0`) passes through UNCLAMPED (`== 250.0`) to lock "positive finite is not range-clamped."
  - [x] Reflexivity test: value built from `Float.nan`/`Double.nan` inputs satisfies `a == a` and stable `hashValue`; equal clamped inputs hash-equal (covers `BeatTimestamp`, `BeatGrid`, and `.detected(beats:)` recursively).
  - [x] Exhaustive-switch coverage test over `DownbeatResult` (the AC5 compile-tripwire, no `default:`).
  - [x] Codable round-trip (parameterized over `.detected(beats:)` with 0/1/200 beats + representative grids) asserting field-wise `NumericTestHelpers.bitEqual`, PLUS a 4-value worst-case `Double` bit-exact corpus (`0.1`, `Double.pi`, `Double.leastNormalMagnitude`, `Double.greatestFiniteMagnitude`).
  - [x] **JSON wire-shape assertions** per `DownbeatResult` case: `.detected(beats:)` → contains key path `detected.beats`; `.notAttempted`/`.noneDetected` → `{"notAttempted":{}}`/`{"noneDetected":{}}` (assert the empty-object shape, not a bare string).
  - [x] Hostile-decode test: finite out-of-range `confidence: 5.0`/`strength: -2.0`, negative `presentationTime: -1.0`, negative `estimatedTempo: -120.0` in JSON → all clamped on decode (`estimatedTempo == 0.0`). Proves `init(from:)` re-clamps. (No non-finite JSON case — `.throw` default rejects it pre-`init`; see AC6 scope note.)
  - [x] **decode→encode→decode** test (Siri): second decode of the hostile payload equals the first — catches an encode-side key the decoder silently ignores.
  - [x] Sentinel-distinguishability test: `.notAttempted != .noneDetected`; empty-grid sentinel `!=` a `.noneDetected`-carrying grid.

- [x] **Task 5 — Documentation + seam-mitigation** (AC: 8)
  - [x] README "Beat grid" section (place it after "## Shared decode" / near the existing "## LUFS measurement" block) describing the result shape and forward-pointing to Story 8.4's `analyzeBeatGrid`. Mark it clearly as the result type that 8.4 will populate.
  - [x] Run the 5 `bpm-diagnostic-trace` audit recipes; confirm zero matches.
  - [x] PR description: enumerate the new public surface (three types + members), and state "no `BPMDiagnosticTrace` field added in 8.3 — KDD-T0 does not trigger (beat grid does not affect BPM winner selection); **W74 re-evaluation hook recorded** — KDD-T0 must be re-run when 8.4+ wires a beat-grid producer into the unified pool (`SignalSource.beatGrid`)."

- [x] **Task 6 — Gates** (AC: 9)
  - [x] `make build`, `make test`, `make fmt`, `make lint` green. Record the new test/suite counts (delta from 8-2's 560 tests / 123 suites).
  - [x] Confirm `git diff --stat` under `Sources/BoomBoomBoomKit/` shows only the three new files (BeatGridAnalyzer.swift untouched); confirm no `Tests/` deletions.

### Review Findings

Code review 2026-06-13 (3 layers: Blind Hunter via Codex, Edge Case Hunter, Acceptance Auditor). Zero code defects; all 9 ACs + 9 DDs verified PASS by the Acceptance Auditor and Codex independently confirmed the NaN-free invariant survives every Codable path. Two minor test-effectiveness gaps surfaced by the Edge Case Hunter — both test-only (the implementation is correct); both resolved 2026-06-13 (Codex-reviewed test plan, +3 tests):

- [x] [Review][Patch] Signed-zero (`-0.0`) clamp boundary untested [Tests/BoomBoomBoomKitTests/BeatGridTypesTests.swift] — `doubleFieldsClamp`/`floatFieldsClamp` assert `== 0.0`, but `-0.0 == 0.0` is `true`, so a clamp regression that returned the `-0.0` input (e.g. swapped `max` arg order) would pass undetected. **Fixed:** added `clampCanonicalizesNegativeZero` — feeds `-0.0` to every clamped float field and asserts canonical `+0.0` via `NumericTestHelpers.bitEqual` (bit-pattern, distinguishes signed zero).
- [x] [Review][Patch] Missing-required-key decode throw untested [Tests/BoomBoomBoomKitTests/BeatGridTypesTests.swift] — the hostile-decode tests always supply every required key, so the non-optional `decode(_:forKey:)` throw path (e.g. a payload omitting `estimatedTempo`) is uncovered. A regression to `decodeIfPresent(...) ?? 0` would silently swallow malformed input with no failing test. **Fixed:** added `beatTimestampMissingRequiredKeyThrowsKeyNotFound` + `beatGridMissingRequiredKeyThrowsKeyNotFound` — each captures the error via `try #require(throws: DecodingError.self)` and pattern-matches `.keyNotFound`, asserting the specific missing key name (`confidence` / `estimatedTempo`).

## Dev Notes

### Design Decisions

**DD #1 — Types-only scope; `BeatGridAnalyzer.swift` is off-limits.** The Story 8.2 placeholder at `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift` is a caseless `enum` namespace exposing `onsetFeatures(for:weighting:)` — it makes the KDD-C4 cross-consumer invariant assertable today and does **not** reference any `BeatGrid` type. Story 8.4 owns connecting `BeatGrid` to it (and inserting step 11). 8.3 must not touch it. `FeatureSubstrateTests.swift:50-69` exercises the stub; do not perturb that test.

**DD #2 — Full-finite clamping is the `Hashable`/`Codable` soundness precondition (and the doctrine that reconciles the LUFSReport divergence).** KDD-C2 declares all three types `Hashable`; the AC mandates `Codable` round-trip. Synthesized `Hashable`/`Equatable` is unsound only in the presence of `Double.nan`/`Float.nan` (`NaN != NaN` breaks reflexivity — the exact reason `MLExecutionPolicy`/`EnsembleDecision`/`SignalParticipation` drop `Hashable`). Clamping **every** float field finite at construction (including the decode path — see DD #3) removes the NaN, so synthesized conformances become sound and we keep `Hashable` per KDD-C2.

  **The doctrine (corrected after reading `LUFSReport.swift:21-26`):** clamping is the *precondition* for sound `Hashable`, but it is NOT the reason to *add* it — those are two separate decisions. `LUFSReport` **also clamps** every non-finite field to its `-100.0` sentinel, yet still **drops `Hashable`** — and verified-on-source, NOT for a reflexivity reason: it omits `Hashable` because it "[is] never a `Set`/`Dictionary` key, and the multi-thousand-element series fields make hashing pointless." So the rule future value-type authors follow is: **(1) any public value type with float fields MUST clamp them finite at every init path; (2) THEN, separately — add `Hashable` for small, keyable value types (8.3's three types: a handful of scalars + a beat array), and omit it for large series-carrying carriers that are never keys (`LUFSReport`).** Both clamp; they diverge only on step (2). This makes the 8.3-vs-`LUFSReport` difference one rule with two outcomes, not an inconsistency a reviewer should flag. Document this reasoning in the type doc comments.

  The epics AC only named `confidence`/`strength` clamping on `BeatTimestamp`; this story extends clamping to `presentationTime` and `BeatGrid.estimatedTempo`/`confidence` because **those floats are equally capable of being NaN** and would silently make `Hashable` unsound. Do NOT hand-write `bitPattern`-based `==` (the `MLExecutionPolicy` pattern) — that pattern exists to *tolerate* NaN; here we *eliminate* it, so synthesized conformance is both correct and simpler. Clamp helpers are precision-matched (`clampUnit(_:Float)->Float`, `clampNonNegative(_:Double)->Double`) and declared once.

**DD #3 — Custom `init(from:)` routes through the clamping init; encode is synthesized.** To keep the clamp invariant true for *every* instance regardless of provenance (including a decoded hostile JSON), `BeatTimestamp` and `BeatGrid` provide a custom `init(from decoder:)` that decodes raw scalars **into locals** and constructs `self` via the explicit clamping init. **It MUST delegate, never assign** — `self.init(presentationTime:…)`, not `self.confidence = try container.decode(...)`; a direct assignment bypasses the clamp and is the single most likely dev mistake (Amelia trap A). `encode(to:)` stays **synthesized**, and **no explicit `enum CodingKeys` is declared**: the compiler synthesizes one (keyed by stored-property names) that both the synthesized `encode` emits and the custom decoder references, so the two halves cannot desync. Per Siri's Claim-2 footgun, introducing an explicit/renamed `CodingKeys`, or decoding ad-hoc keys not present in the synthesized set, risks an encode/decode key mismatch that the compiler will NOT catch — so don't, unless making both halves explicit together. For valid (already-clamped, finite) values this round-trips bit-for-bit under `NumericTestHelpers.bitEqual` (mechanism: Foundation's shortest-round-trippable decimal `description`, not binary JSON), satisfying AC6, and survives the decode→encode→decode double round-trip. `DownbeatResult` uses fully-synthesized `Codable`; its `.detected(beats:)` payload decodes each element through `BeatTimestamp`'s clamping decoder, so the invariant propagates through the enum.

**DD #4 — `DownbeatResult` mirrors `SignalParticipation`'s Codable-enum precedent.** `SignalParticipation` (`Sources/BoomBoomBoomKit/SignalPool/SignalParticipation.swift`) is the in-repo precedent for a `public enum … Sendable, Codable` with associated values and synthesized `Codable`. `DownbeatResult` follows it. It adds `Hashable` (sound because `BeatTimestamp` is NaN-free) and `CustomStringConvertible`. It deliberately omits `CaseIterable` per the `MLExecutionPolicy` precedent (assoc-value case → no meaningful `.allCases`).

**DD #5 — File placement: core root, not a subfolder.** `architecture.md:1025-1026` places `BeatTimestamp.swift` and `DownbeatResult.swift` at `Sources/BoomBoomBoomKit/` root (siblings of `BPMDiagnosticTrace.swift`), not under `SignalPool/` or `FeatureSubstrate/`. `BeatGrid.swift` joins them at root. The `BoomBoomBoomKit` target is path-based (`Package.swift:13-15`, `path: "Sources/BoomBoomBoomKit"`, no explicit `sources:` list), so new files are auto-included — **no `Package.swift` edit**.

**DD #6 — KDD-T0 does not trigger *in 8.3*; seam-mitigation = docs only; re-evaluation deferred as W74.** Verified: no `beatGridPlaceholder` or beat-grid field exists on `BPMDiagnosticTrace`. KDD-T0 (`architecture.md:311,703-744`) gates trace fields on "affects winner selection / weight resolution / gate firing." Beat grid is a parallel step-11 output that does not feed BPM disambiguation, so no trace field is warranted for the types-only landing. The seam-mitigation rule (Mary; `epics.md:312`) still applies in its documentation form — DocC + README — exactly as Story 8.1 discharged it when its cited seam was also absent (`epics.md:890`). The 5-recipe audit trivially passes (no field added). **The stance is "no field in 8.3," not "no field ever"** (Winston/Mary): `SignalSource.beatGrid` exists producerless (W53), and when Story 8.4+ wires a beat-grid producer into the unified pool, `estimatedTempo`/`confidence` become weight-resolution inputs — at which point KDD-T0 DOES trigger and a `signalParticipationTrace`/`.beatGrid` field is warranted. That re-evaluation is recorded as **deferred-work W74** so the 8.4 dev inherits a tracked obligation rather than reading "no trace field" as settled law. 8.3 is types-only, so it does not *build* the trace surface — it only *names the forward decision*.

**DD #7 — `SignalSource.beatGrid` stays producerless.** `Sources/BoomBoomBoomKit/SignalPool/SignalSource.swift:12` already has `case beatGrid` (deferred-work W53 — "no producer until Epic 8"). 8.3 does **not** wire a beat-grid producer into the unified pool; that is Story 8.4+ (if at all). Out of scope here — do not add pool participation logic. (The same W53 seam is what arms the W74 KDD-T0 re-evaluation in DD #6.)

**DD #8 — `estimatedTempo` clamps non-finite AND non-positive to `0.0` (operator decision, 2026-06-13).** The party-mode review surfaced a genuine fork: allow a negative finite tempo through (Amelia: types-only, plausibility is 8.4's job) vs clamp it (Winston: a negative BPM is garbage, and garbage and absence are the same equivalence class). The operator chose **clamp non-positive → 0.0**, the existing AC7 "no valid estimate" sentinel. Rationale: (1) `0.0` is already overloaded as the no-run/no-estimate sentinel (AC7), so collapsing negatives into it is intentional, not lossy — a `-120` BPM carries no recoverable information; (2) it mirrors `presentationTime ≥ 0` and the codebase's `SignalWeights`/`ComputeBudget` isFinite-first/non-negative init precedent; (3) it protects the FR-39 `BeatGridTimelineView` consumer from scaling a timeline by a negative tempo. **Positive finite values are NOT range-clamped** — 60–200 plausibility remains Story 8.4's algorithm concern; the type only refuses the physically-impossible. Consumers gate validity with `estimatedTempo > 0`. This is the one place 8.3 deliberately tightens beyond KDD-C2's silent under-specification.

**DD #9 — `.detected` associated value is labeled `beats:` (KDD-C2 refinement, operator-approved 2026-06-13).** KDD-C2 writes the case as `.detected([BeatTimestamp])` — Swift type-shorthand, not a JSON-contract decision. 8.3 ships it as **`.detected(beats: [BeatTimestamp])`**. Per SE-0295, an unlabeled associated value synthesizes the positional JSON key `_0` (`{"detected":{"_0":[…]}}`), which silently shifts if a future payload member is ever added; a label pins the public Codable wire-shape to the stable, self-documenting `{"detected":{"beats":[…]}}` (Siri: required hardening; Amelia: cheaper than asserting `_0` in tests). Pre-1.0, so the call-site change (`.detected(beats: …)`) costs nothing and there is no BC concern. This is a documented refinement of KDD-C2's canonical shape, not a departure from its intent (still exactly three cases, still `[BeatTimestamp]` payload).

### Architecture compliance

- **KDD-C2** (`architecture.md:496-522`) — the canonical shape is reproduced in AC1 with **two operator-approved refinements** that tighten (not contradict) it: the `.detected` payload is labeled `beats:` (DD #9, JSON-contract hardening) and `estimatedTempo` clamps non-positive→0 (DD #8). Both stay within KDD-C2's intent (three cases, `[BeatTimestamp]` payload, five `BeatGrid` fields). The `strength` field provenance note (Amelia #2: `onsetEnvelope[frame]/onsetEnvelopeMax`, vDSP `vDSP_maxv`, NaN-free at construction) is **Story 8.4's** producer concern; 8.3 only guarantees the *type* refuses NaN.
- **KDD-C3** (`architecture.md:524-526`) — `tempoAgreedWithBPMStage: Bool?`: nil when no BPM analysis ran in the same call; `true`/`false` when both computed. Document on the field; the *population* is 8.4/8.5.
- **KDD-C6** (`architecture.md:545-547`) — no public engine protocol in v1.0. 8.3 ships concrete result types only; correct by construction (no protocol introduced).
- **Swift 6 strict concurrency** — all three types are pure value types with `Sendable` (trivially satisfied: only `Sendable` stored members).
- **Naming/style** — match the file-header comment block of existing core files (see `MLExecutionPolicy.swift:1-8`, `SignalSource.swift:1-6`). Run `make fmt` (swift-format) before commit.

### Testing standards

- Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`, `#require`) — NOT XCTest. Parameterized tests via `@Test(arguments:)`.
- Float comparisons: use `NumericTestHelpers.bitEqual(_:_:)` for the Codable round-trip (bit-exact); use exact equality for clamp-target assertions (e.g. `#expect(ts.confidence == 0.0)` after NaN input — the clamp produces a literal `0.0`).
- Test file: `Tests/BoomBoomBoomKitTests/BeatGridTypesTests.swift` (the `BoomBoomBoomKitTests` target; `make test` filters to it).
- `BoomBoomBoomKitTestSupport` is already a test dependency (`Package.swift:36`) — import it for `NumericTestHelpers`.

### Previous-story intelligence (Story 8-2, `done` @ `9b3c6e3`/`b91e588`)

- 8-2 created the `BeatGridAnalyzer` stub specifically so 8.3+8.4 have a landing seam; it is exercised by `FeatureSubstrateTests`. Leave both alone.
- 8-2's review cycle repeatedly caught **under-clamped numeric inits trapping/propagating on non-finite inputs** (the `cappedSampleCount` Int64 overflow MAJOR; the `DecodedAudio.init` ≥8kHz-but-otherwise-unbounded admission). The lesson directly informs DD #2/#3: clamp at the boundary, test the hostile input, never assume the producer is well-behaved.
- 8-2 confirmed the project's NaN discipline is enforced at review: a public type carrying an unsanitized `Double` will be flagged. 8.3's answer is to **sanitize at init** so `Hashable` is defensible — document that reasoning inline so the reviewer sees it.
- Branch/PR convention (Epic 8): per-story branch `rterhaar/8-3` off `rterhaar/epic-8`; PR into `rterhaar/epic-8`; 1Password-signed commits are automatic via git config (do not raise signing alarms — see memory). Operator owns the final commit/PR; the dev agent's `/bmad-code-review` flips review→done.

### Project Structure Notes

- New files (all ship to `main`): `Sources/BoomBoomBoomKit/BeatGrid.swift`, `BeatTimestamp.swift`, `DownbeatResult.swift`; `Tests/BoomBoomBoomKitTests/BeatGridTypesTests.swift`; README edit.
- No `Package.swift` change (path-based target). No `BoomBoomBoomKitML` / TestSupport / Demo changes.
- No develop-only artifacts; this is pure public-library surface.

### References

- `_bmad-output/planning-artifacts/epics.md:967-1001` — Story 8.3 ACs (superseded where Context corrections apply).
- `_bmad-output/planning-artifacts/architecture.md:496-547` — KDD-C2 / C3 / C6 (authoritative type shape).
- `_bmad-output/planning-artifacts/architecture.md:311,703-744` — KDD-T0 trigger (why no trace field).
- `_bmad-output/planning-artifacts/epics.md:312` — Mary's Epic-6→Epic-8 seam-mitigation rule.
- `Sources/BoomBoomBoomKitTestSupport/NumericTestHelpers.swift:13-25` — `NumericTestHelpers.bitEqual` (the correct helper; AC4 fix).
- `Sources/BoomBoomBoomKit/MLExecutionPolicy.swift:23-54` — assoc-value enum, no `CaseIterable`, NaN-handling rationale (precedent for DownbeatResult + the "don't hand-write bitPattern ==" decision).
- `Sources/BoomBoomBoomKit/SignalPool/SignalParticipation.swift:9-13` — `public enum … Sendable, Codable` with associated values (DownbeatResult precedent).
- `Sources/BoomBoomBoomKit/LUFSReport.swift:21-34` — the `LUFSReport` value-carrier choice 8.3 deliberately diverges from (clamps-but-keeps-Hashable vs clamps-but-drops-Hashable).
- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift` — the 8.2 stub 8.3 must NOT modify.
- `.claude/skills/bpm-diagnostic-trace/SKILL.md` — the 5 audit recipes (AC8).
- `_bmad-output/implementation-artifacts/8-2-shared-decode-wiring-three-analyzers-one-decodedaudio.md` — prior-story learnings (clamp-at-boundary discipline).

## Dev Agent Record

### Agent Model Used

claude-opus-4-8[1m] (Opus 4.8, 1M context) — bmad-dev-story workflow.

### Debug Log References

- `swift build` clean on first attempt (no API surface errors; custom `init(from:)` + synthesized `encode`/`CodingKeys` pattern compiled as designed).
- One transient test-compile failure: the `makeBeats` helper's inline `Float(... ? ... : ...)` ternaries tripped the Swift type-checker's "unable to type-check in reasonable time" heuristic. Fixed by hoisting `time`/`confidence`/`strength` into explicitly-typed locals (no behavior change).

### Completion Notes List

Story 8.3 is **types-only** — three pure public value types plus tests and docs. No DSP, no service method, no pipeline step, no trace field.

**What shipped (new public surface):**
- `BeatTimestamp` (struct): `presentationTime: Double`, `confidence: Float`, `strength: Float`. Clamping init + clamping `init(from:)`. `Sendable, Hashable, Codable, CustomStringConvertible`.
- `DownbeatResult` (enum): `.notAttempted` / `.noneDetected` / `.detected(beats: [BeatTimestamp])` (labeled payload, DD #9). Synthesized `Codable`; exhaustive-switch `description` (no `default:`); NOT `CaseIterable` (compiler-suppressed by payload case). `Sendable, Hashable, Codable, CustomStringConvertible`.
- `BeatGrid` (struct): `beats`, `downbeats`, `estimatedTempo: Double`, `confidence: Float`, `tempoAgreedWithBPMStage: Bool?`. Clamping init + clamping `init(from:)` (delegates to clamping init, `decodeIfPresent` for the optional Bool to match the synthesized `encodeIfPresent`). `Sendable, Hashable, Codable, CustomStringConvertible`.
- Internal `BeatGridClamp` namespace (caseless enum) holds the two precision-matched helpers `clampUnit(_:Float)->Float` / `clampNonNegative(_:Double)->Double`, declared once and reused across both types (DD #2).

**AC coverage:**
- AC1 — three types, exact shapes; `.detected(beats:)` labeled payload. ✅
- AC2/AC3 — all float fields clamp finite at construction (`presentationTime`/`estimatedTempo` non-finite OR non-positive → 0.0; `confidence`/`strength` → `[0,1]`, NaN→0). DD #8: `estimatedTempo` negative→0 sentinel, positive finite passes UNCLAMPED (verified with 250.0). ✅
- AC4 — `Hashable`/`Equatable` compiler-synthesized (no hand-written `bitPattern`); reflexivity + hash-stability test from NaN inputs passes precisely because clamping removed NaN. ✅
- AC5 — `DownbeatResult` not `CaseIterable`; coverage enforced by exhaustive `switch` with no `default:` in both the test and `description`. ✅
- AC6 — Codable round-trip bit-exact via `NumericTestHelpers.bitEqual` (field-by-field); 4-value worst-case `Double` corpus (`0.1`, `Double.pi`, `leastNormalMagnitude`, `greatestFiniteMagnitude`); per-case JSON wire-shape asserts (`{"detected":{"beats":[…]}}`, `{"notAttempted":{}}`, no `_0` leak); hostile finite-out-of-range decode re-clamps; decode→encode→decode double round-trip. ✅
- AC7 — "no beat-grid run" sentinel documented verbatim in DocC; distinguishability test (`.notAttempted != .noneDetected`, empty-grid != none-detected grid). ✅
- AC8 — DocC on all three types + every member; README "Beat grid" section + Public API table rows; 5-recipe `bpm-diagnostic-trace` audit returns ZERO matches (no trace field added — KDD-T0 does not trigger; beat grid is a parallel step-11 output, not BPM-winner-affecting). ✅
- AC9 — types-only; `BeatGridAnalyzer.swift` untouched; no `BPMAnalyzer`/`AudioAnalysisService`/`LUFSAnalyzer` changes; corpus floors not run as a gate (no DSP touched — `git status` confirms only the three new source files + README differ, so floors cannot move by construction). ✅

**Gates:** `make build` clean; `make test` green — **575 tests / 124 suites** (delta from 8-2's 560/123: +15 tests, +1 suite). `make fmt` applied (formatter idempotent on the new files). `make lint` — 1 violation, 0 serious: the pre-existing `LUFSAnalyzer.swift:135` TODO baseline (the documented "acceptable single violation"); my files added zero violations.

**KDD-T0 non-trigger + W74 re-evaluation hook (for the PR description):** 8.3 introduces **no** `BPMDiagnosticTrace` field. KDD-T0 gates trace fields on "affects winner selection / weight resolution / gate firing"; beat grid is a parallel post-disambiguation output that does not feed BPM winner selection, so no field is warranted for the types-only landing. The stance is "no field *in 8.3*," not "no field ever": `SignalSource.beatGrid` exists producerless (W53), and when Story 8.4+ wires a beat-grid *producer* into the unified pool, `estimatedTempo`/`confidence` become weight-resolution inputs — at which point **KDD-T0 MUST be re-run** and a `signalParticipationTrace`/`.beatGrid` field is warranted. Recorded as deferred-work **W74**.

**Pending user action:**
- `/bmad-code-review` on a separate-LLM cadence (project convention — different LLM than the dev session). A clean review flips this story review→done.
- 1Password-signed commit on branch `rterhaar/8-3` (off `rterhaar/epic-8`) + PR into `rterhaar/epic-8`. Operator owns the final commit/PR.

### File List

- `Sources/BoomBoomBoomKit/BeatTimestamp.swift` (new) — `BeatTimestamp` struct + internal `BeatGridClamp` clamp namespace.
- `Sources/BoomBoomBoomKit/DownbeatResult.swift` (new) — tri-state `DownbeatResult` enum.
- `Sources/BoomBoomBoomKit/BeatGrid.swift` (new) — `BeatGrid` struct.
- `Tests/BoomBoomBoomKitTests/BeatGridTypesTests.swift` (new) — full AC1–AC7 test suite (15 test functions, parameterized clamp/round-trip/corpus cases).
- `README.md` (modified) — added "## Beat grid" section + three Public API table rows.
- `_bmad-output/implementation-artifacts/8-3-...md` (modified) — frontmatter `baseline_commit`, task checkboxes, Dev Agent Record, Change Log, Status (develop-only artifact, not shipped to main).
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified) — status ready-for-dev → in-progress → review (develop-only).

## Change Log

- 2026-06-13 — Implemented `BeatTimestamp`, `DownbeatResult`, `BeatGrid` public value types + `BeatGridTypesTests` (15 tests). All 9 ACs satisfied; types-only, no DSP/service/trace changes. `make build`/`make test` green (575 tests / 124 suites, +15/+1 from 8-2); `make fmt`/`make lint` clean (only the pre-existing LUFSAnalyzer TODO baseline). 5-recipe trace audit zero matches. Status → review.
- 2026-06-13 — Code review (Blind Hunter via Codex + Edge Case Hunter + Acceptance Auditor): zero code defects, all 9 ACs + 9 DDs PASS. Two test-effectiveness gaps fixed (+3 tests, Codex-reviewed plan): `clampCanonicalizesNegativeZero` (signed-zero `-0.0` → canonical `+0.0` via `bitEqual`) and `beatTimestampMissingRequiredKeyThrowsKeyNotFound`/`beatGridMissingRequiredKeyThrowsKeyNotFound` (omitted required key throws `.keyNotFound`, asserts key name). `make test` green — **578 tests / 124 suites** (+3 from review baseline); `make fmt` idempotent; `make lint` clean (pre-existing LUFSAnalyzer TODO baseline only). Status → done.
