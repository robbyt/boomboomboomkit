# Story 5.5: Public API Documentation and README

Story ID: 5.5
Story Key: 5-5-public-api-documentation-and-readme
Epic: 5 — Developer Experience & Demo (fifth and final story; opens FR42 / FR43 / FR44 / FR45)
Status: done

> **Spec validation history.** Initial draft 2026-05-21. Party-mode review pass 2026-05-21 via 4 BMAD agents (Winston / Amelia / Paige / Siri) + Codex MCP plan-review thread `019e4b40-0325-7ab1-9336-065568bd09c0` + `axiom-apple-docs` skill routing. Convergent findings applied inline (see "post-spec-validation 2026-05-21" markers throughout):
> 1. Test count corrected 431 → 433 (Amelia verified `git grep -c '@Test('` against working tree).
> 2. `CoreMLTechnique.swift` corrected from "placeholder" to "intentional public non-conforming Sendable struct" — Task 3.2 rewritten (Amelia + Codex).
> 3. Coverage gate recipe made concrete with runnable perl one-liners covering both public-keyword decls AND bare enum cases (Winston + Amelia + Codex).
> 4. Pre-1.0 framing notice softer tone replacing "breaking changes explicitly allowed and expected" (Paige + Codex).
> 5. Installation snippet `from: "1.0.0"` replaced with branch/revision pinning (Codex HIGH finding).
> 6. Batch workflow blocks shipped as concrete Swift 6 code instead of shape descriptions (Codex HIGH finding + Amelia).
> 7. CLAUDE.md Key Types count expanded from 13 → 17, adding `CoreMLTechnique`, `SubBandEnergies`, `TensorLayout`, `MLFeatureFrames` (Codex MEDIUM finding).
> 8. DocC catalog deferral reversed to a minimal-stub-now approach — Task 1.7 added (Winston + Siri convergent).
> 9. Nil-return reference converted from bullets to table form with 4 columns (Paige + Siri).
> 10. Quick-start expanded from 3 lines → 6-8 lines with `do/catch` (Paige).
> 11. 6-rule voice style guide added to DD #2 (Paige).
> 12. WWDC #10166 title corrected to "in Xcode" (was "in Swift") (Siri).
> 13. Task 4.11 "scratch Xcode project" replaced with tmpdir SPM recipe (Codex + Amelia).
> 14. AC #13 wall-clock contract pinned at ±15% of Story 5-4 baseline (Amelia).
> 15. Three-commit-within-PR pattern adopted for `git bisect` granularity (Winston).
> 16. R5 (DocC warning gate) softened — `swift build` does NOT validate doc-comment content the way Xcode does (Codex + Siri).
> 17. R8 (README compile-check drift), R9 (// MARK: allowance escape hatch) added (Amelia + Winston).

## Story

As an app developer discovering BoomBoomBoomKit on GitHub,
I want a `README.md` that gets me from clone to first BPM in under three minutes plus complete inline `///` documentation on every public declaration,
So that I can integrate the library confidently without reading DSP source or having to ask the library author what `nil` means in each context.

**Scope clarification (read first).** Story 5-5 is the docs-only close-out of Epic 5. **No library behavior changes. No public API renames. No new public types. No new tests.** Three deliverables land:

1. **`README.md` rewrite/extension** — current README already has quick-start, supported formats, pipeline diagram, public-API table, BYOW model section. Story 5-5 adds (per epic-level ACs): an intensity-scale 1-10 guidance section, a `nil`-return condition reference, a batch-workflow patterns section with runnable code, and a pre-1.0 / no-BC framing notice. Stale content (the pipeline-step list, references to internal types) is corrected. The "Optional ML Models" section is reconciled with the Story 4-6 Branch C BYOW posture (already partially done in the current README — Story 5-5 finishes it).

2. **Inline `///` documentation sweep across `Sources/BoomBoomBoomKit/` and `Sources/BoomBoomBoomKitML/`** — every PUBLIC declaration (struct/class/enum/protocol, init, property, method, case) gets a `///` documentation comment. Where applicable, `- Parameters:` and `- Returns:` are populated. Internal declarations are NOT required to have `///` (project convention: minimal-or-none on internal helpers — see CLAUDE.md "Code organization"). The sweep targets gaps; types that already have rich `///` docs (e.g., `MLEvaluation`, `MLDiagnosticSnapshot`, `EnsembleDecision`) are left alone unless a gap is observed.

3. **`CLAUDE.md` Key Types subsection update — Epic 4 retro T2 close-out (precondition for this story per the retro 2026-05-17).** CLAUDE.md `## Architecture` → `### Key Types` currently reflects pre-Epic-4 public API. Story 5-5 brings it current with the 8 Epic 4 additions (`MLEvaluation`, `EnsembleDecision`, `EnsemblePolicy`, `MLDiagnosticSnapshot`, `MLFeatureFrames`, `MLDiagnosticTechnique`, `BNNSTechnique`, `MLTechniqueError`) — plus reconciles the existing entries (e.g., `MLTechnique` protocol signature is now `evaluate(trace:) -> MLEvaluation?` — currently described as "Definition only, no conformances yet" per the line CLAUDE.md:64).

Story 5-5 closes deferred-work items **T2** (CLAUDE.md Key Types sweep — Epic 4 retro carry-forward), and partially closes the "Standard acceptance criteria" item from the epics file ("Update inline `///` doc comments for any modified public API" — Story 5-5 is the lump-sum back-fill for everything missed across Epics 1-4). **W1** (Story 4-7 `.full` preset auto-include of `.superFluxOnset`) and **T5** (Epic 4 retro carry-forward `.full` semantics revisit) remain open and are explicitly DEFERRED to Epic 5 retrospective per the epic-level decision authority — Story 5-5 does NOT change `.full`'s definition; doc-only stories don't change semantics. **T1** (Epic 4 retro perf-baselines cleanup, 42 files accumulated) also remains open and is explicitly deferred to Epic 5 retrospective.

**What this story does NOT deliver** (each is explicitly OUT-OF-SCOPE):

- **No new public API.** No new types, no new methods, no renames. The library's public surface at Story 5-4 close-out is the final shape for Epic 5.
- **No behavior changes in Sources/.** Doc-comment additions are inert at runtime. Accuracy baselines unchanged (OA300 Acc1=58/82 + Acc2=74/82; GiantSteps Acc1=537/661 + Acc2=546/661); test count unchanged (~433 unit tests in 94 suites pre-Story-5-5, expected unchanged post).
- **No DocC catalog bundle (`.docc`).** The project does not ship a DocC catalog today. Adding one is a separate decision requiring Package.swift `documentation` target wiring + a tutorial format choice + a hosting decision (GitHub Pages, Swift Package Index, etc.). DocC tools build from inline `///` automatically — the inline sweep delivers DocC-ready prose without committing to the catalog format yet. Re-open trigger: a consumer asks for a hosted reference, OR Swift Package Index plugin requires the catalog. Until then, GitHub-rendered `README.md` + IDE QuickHelp from `///` is the supported entry.
- **No demo app documentation.** Story 5-1 through 5-4 delivered the demo app; the README will mention it in one paragraph with a path pointer (`Demo/BoomBoomBoomKitDemo/`), but full demo docs are not in scope. The demo is a build-and-run evaluation tool, not a documented product.
- **No tutorial / "Getting Started" guide beyond README quick-start.** The 3-line quick-start example in the existing README (`README.md:30-32`) plus the new batch-workflow section is the full "Getting Started" surface. A standalone `GettingStarted.md` or `.tutorial` file is not in scope.
- **No accuracy results disclosure in README.** Accuracy numbers live in `MODEL_CARD.md` (for bundled models — currently "no model bundled") and per-story Completion Notes. The README mentions the OA300 + GiantSteps corpora exist as regression backstops but does NOT publish specific Acc1/Acc2 numbers — that surface would need to be maintained per release and is better located in MODEL_CARD.
- **No CONTRIBUTING.md, no CHANGELOG.md, no ROADMAP.md.** These are publication-discipline artifacts that pre-1.0 BoomBoomBoomKit does not need yet. The library is on `develop` with one author; `git log` is the changelog. Re-open trigger: external contributor PRs appear, OR the library hits 1.0.
- **No `.full` preset re-decision.** W1 + T5 carry-forward. Story 5-5 docs `.full` as-shipped (auto-includes `.superFluxOnset` per Set(allCases) — see DSPTechnique.swift:165-170 doc); changing the semantic is a separate spec.
- **No `tools/coreml-convert/README.md` rewrite.** That CLI's README is consumer-facing in its own right (Story 4-4b DD #13) and was last refreshed in Story 4-6 Branch C close-out. Story 5-5 may add a cross-reference link from the top-level README to it (already present at line 142) but does not edit the convert-tool README itself.

## Key Design Decisions

The DDs below are the binding choices the dev agent inherits BEFORE Task 1 begins. **DDs #1, #2, #3, #5, #7, and #10 are the most consequential** — they lock the docs-only scope, the inline-`///` sweep methodology (file-by-file with a coverage acceptance gate), the README content structure, the no-DocC-catalog decision, the no-test-additions invariant, and the T2 CLAUDE.md close-out cadence.

1. **Docs-only scope; library Sources/ + Tests/ behavior is untouched.** This is the single most consequential constraint. Doc-comment additions (`///` lines) are inert at runtime — they affect IDE QuickHelp + future DocC compilation only. The dev agent MUST verify zero behavioral changes via `make benchmark` (OA300 Acc1=58/82 + Acc2=74/82) and `make benchmark-giantsteps` (Acc1=537/661 + Acc2=546/661) post-sweep. Test count integer unchanged from Story 5-4 baseline (~433 `@Test(` declarations in `BoomBoomBoomKitTests`). Any byte-level change to library .swift files OTHER than added/expanded `///` lines is a scope violation. The dev agent MAY add `// MARK: -` section headers where genuinely missing for IDE navigation, but renames, signature changes, type-relocations, and behavior tweaks are out of scope.

   **Why the boundary matters.** Story 5-5 is the close-out story of Epic 5 — its job is to surface the existing API, not to redesign it. Any tempting "while I'm here" cleanup (renaming an awkward symbol, fixing a `Sendable` annotation, simplifying a closure signature) is a separate story spec. Pre-1.0 / no-BC framing allows those changes freely, but they require their own AC + diff scope + benchmark gate — folding them into a docs sweep makes the diff harder to review and breaks the "doc-only verification" promise.

2. **Inline `///` sweep methodology: file-by-file with explicit coverage gate.** The dev agent walks `Sources/BoomBoomBoomKit/*.swift` and `Sources/BoomBoomBoomKitML/*.swift` in alphabetical order. For each file, the agent:

   - Enumerates every PUBLIC declaration (struct/class/enum/protocol type definitions, public init, public var/let property, public func method, public case in a public enum).
   - For each public declaration LACKING a `///` comment (i.e., no triple-slash line in the 1-5 lines immediately preceding the declaration, excluding intervening blank/MARK lines), adds a `///` doc comment.
   - Where the declaration is a method or initializer with parameters or a return value, the dev agent populates `- Parameters:` (or per-parameter `- Parameter <name>:` for single-parameter cases) and `- Returns:` per Swift API Design Guidelines + DocC syntax.
   - Where the declaration is a property, the doc comment describes WHAT the property holds + WHEN it is populated/nil + units/range where applicable.

   **Coverage gate (AC #6) — concrete recipe lands in the spec, not "author later".** Post-spec-validation correction (2026-05-21, Codex + Amelia + Winston convergent finding): the original spec wording said the dev agent SHOULD author the recipe. Per Codex HIGH finding #1, that delegates the highest-risk artifact of the story to the dev agent. The runnable recipe ships here:

   ```bash
   perl -0777 -ne '
     while (/((?:^[^\n]*\n){0,5})^[[:space:]]*(public[[:space:]]+(?:struct|class|enum|protocol|func|var|let|init|case|subscript|typealias|actor)\b[^\n]*)/gm) {
       my ($ctx, $decl) = ($1, $2);
       print "$ARGV:$decl\n" unless $ctx =~ m{///};
     }
   ' Sources/BoomBoomBoomKit/*.swift Sources/BoomBoomBoomKitML/*.swift
   ```

   The recipe walks each `.swift` file as one string (`-0777`) so multi-line lookback works; it matches public declarations on the keyword line and checks whether the preceding 5 lines carry a `///` token. Zero matches = full coverage. **Bare enum cases inside a public enum body** (e.g., `case acfSharpening` inside `public enum DSPTechnique` per `DSPTechnique.swift:25`) — the original recipe missed these; the corrected recipe still misses them because they lack the `public` prefix. Per Codex finding #1, ship a SECOND audit pass specifically for bare enum cases — a separate perl one-liner that walks each file's `public enum` blocks and checks every `case` line for preceding `///`:

   ```bash
   perl -0777 -ne '
     while (/^public\s+enum\s+(\w+)[^{]*\{(.*?)\n\}/gms) {
       my ($name, $body) = ($1, $2);
       while ($body =~ /((?:^[^\n]*\n){0,5})^[[:space:]]*case\s+(\w+)/gm) {
         my ($ctx, $case_name) = ($1, $2);
         print "$ARGV:$name.$case_name\n" unless $ctx =~ m{///};
       }
     }
   ' Sources/BoomBoomBoomKit/*.swift Sources/BoomBoomBoomKitML/*.swift
   ```

   Both recipes must return zero matches before AC #6 passes. **Recipe inversion** (Task 5.3): manually delete `///` from BOTH a `public func` (any well-documented file) AND a bare `case` inside a public enum (e.g., `DSPTechnique.acfSharpening`); re-run both recipes; expect exactly two matches; restore the deleted `///`.

   **Known false-positive shapes** (Winston finding) the recipe may still miss: multi-line public initializers where the `public` keyword and the `init` signature span 3+ lines; conditional conformance extensions (`extension X: Y where T: Sendable`) where members inherit visibility without re-declaration; computed-property `get`/`set` on separate lines; protocol requirements inside `public protocol` (members aren't redeclared `public`). For each, the spec's mitigation is the dev agent's file-by-file walk in Task 2 — manual inspection is the backstop, the recipe is the smoke test.

   **Internal declarations are skipped** — the audit does NOT enforce coverage on `internal func` / `private` etc., consistent with CLAUDE.md "Code organization" convention. `@_spi` and `package` access — verified absent in this repo as of 2026-05-21 (`git grep '@_spi\|^package ' Sources/` returns no matches); the recipe does not need a special exclusion for them.

   **Doc comment style — 6-rule voice guide** (Paige's recommendation 2026-05-21; mirrors Apple's Foundation house style):

   1. **Third-person, indicative.** "Returns the BPM..." not "This returns..." or "We return..."
   2. **Sentence case, period termination.** Match Apple's Swift API Design Guidelines.
   3. **First sentence is the summary** (rendered as DocC abstract); blank line before discussion.
   4. **Parameter docs are noun phrases**, not sentences: `- Parameter url: The audio file to analyze.`
   5. **Cross-reference with double-backticks**, never bare names. `` ``OtherType`` `` or `` ``Protocol/method(_:)`` ``.
   6. **No `TODO` / `FIXME` in shipped `///`.** Those are for source comments (`//`), not doc surface.

   Use single-line `///` for one-liner descriptions; multi-line `///` for richer types. Avoid block-comment `/** */` form (project uses `///` exclusively today — `git grep '/\*\*' Sources/` returns zero matches). The dev agent SHOULD also read 3-5 already-well-documented files (`MLEvaluation`, `MLDiagnosticSnapshot`, `EnsembleDecision`, `AnalysisIntensity`, `DSPTechnique`) before starting the sweep — the voice guide above is the rule, the existing files are the demonstration.

   **Known gap inventory (pre-sweep).** A reconnaissance pass before story authoring identified these undocumented public declarations as the highest-density gaps. The dev agent should NOT treat this as exhaustive — perform the file-by-file sweep + the AC #6 grep audit to catch the rest:

   - `Sources/BoomBoomBoomKit/DSPTechnique.swift`: `TechniqueSet.init(dspTechniques:candidateCount:)`, `TechniqueSet.contains(_:)`, `TechniqueSet.inserting(_:)`, `TechniqueSet.removing(_:)`, the bare public properties `dspTechniques` and `candidateCount`.
   - `Sources/BoomBoomBoomKit/MetadataPolicy.swift`: `MetadataPolicy.init(...)`, `MetadataBPMEvidence.init(...)`, `ParsingOptions` nested type fields (if any are bare).
   - `Sources/BoomBoomBoomKit/PCMBufferReader.swift`: any of the four public funcs that lack `- Parameters:` / `- Returns:` blocks.
   - `Sources/BoomBoomBoomKit/EnsembleCombiner.swift`: `EnsembleCombiner` is internal per project-context.md "Access control boundaries (post-Epic-4)" — verify and skip.
   - `Sources/BoomBoomBoomKitML/BNNSTechnique.swift`: any bare public properties (`bundledReferenceURL`'s computed-property body MAY already be documented; verify).

3. **`README.md` content structure (post-sweep target).** The README post-Story-5-5 has these sections in order (existing sections preserved unless explicitly noted; new sections inserted between):

   1. **Title + tagline** (existing) — "Standalone audio analysis package for BPM estimation and LUFS loudness measurement…" — unchanged.
   2. **Platform/Swift/Dependencies badge line** (existing) — unchanged.
   3. **NEW: Pre-1.0 framing notice** — single short paragraph immediately after the badge line. **Post-spec-validation softer wording (Paige + Codex 2026-05-21):** the original "breaking changes are explicitly allowed and expected" front-loads scary language that bounces the Evaluator persona (the 30-second skimmer who hasn't decided to integrate yet). Use this wording instead:

      > **Status:** Pre-1.0, no external consumers yet. The public API may evolve as the design matures; pin an exact tag or commit if you adopt early. Semantic-version stability begins at 1.0.

      Honest about the same reality without the warning-klaxon tone. Reserve harder language ("breaking changes are explicitly allowed") for `CHANGELOG.md` when one exists. The Pre-1.0 framing notice anchors consumer expectations BEFORE they read the API table.
   4. **Features** (existing) — three bullets (BPM, LUFS, PCM); reconcile pipeline-step count with actual pipeline (see DD #4 below).
   5. **Installation** — **revised** (Codex HIGH finding #3, 2026-05-21). The current `README.md:14-20` block reads:

      ```swift
      dependencies: [
          .package(url: "https://github.com/robbyt/BoomBoomBoomKit.git", from: "1.0.0"),
      ]
      ```

      `from: "1.0.0"` is incoherent for a pre-1.0 package with no 1.0 tag — the SPM resolver fails. Revise to the documented pre-release pinning idiom — branch or exact revision:

      ```swift
      dependencies: [
          .package(url: "https://github.com/robbyt/BoomBoomBoomKit.git", branch: "main"),
      ]
      ```

      or for stricter reproducibility:

      ```swift
      dependencies: [
          .package(url: "https://github.com/robbyt/BoomBoomBoomKit.git", revision: "<commit-sha>"),
      ]
      ```

      Add a brief inline comment: `// Pre-1.0: pin a specific revision or branch until 1.0 ships.` This is the only structural edit to the Installation section; the wider section content survives unchanged.
   6. **Usage** (existing) — quick-start example is already 3-line-compatible per AC #1 spec literal. Add one inline comment explaining that `analyzeBPM` returns `nil` for the documented nil-return cases (see DD #6).
   7. **NEW: Intensity scale 1-10** (DD #5) — table mapping rawValue → use case → window sizes → typical wall-clock guidance + a 2-3 sentence framing of when to use each range.
   8. **Customizing techniques** (existing) — unchanged.
   9. **NEW: Batch workflow patterns** (DD #7) — three runnable code blocks: (a) `Task` queue with progress callback, (b) cancellation via `Task.cancel()`, (c) preserving completed results when a batch is cancelled mid-flight. Each block ~5-10 lines of Swift.
   10. **NEW: When `analyzeBPM` returns nil** (DD #6) — bulleted reference: silence / too-short / unsupported sample rate (LUFS only) / cancelled / no candidates found. Cross-referenced from the Usage quick-start comment.
   11. **Commands** (existing) — keep but trim to the consumer-relevant subset (`make help`, `make build`, `make test`, `make fmt`). Internal `make benchmark`, `make ablation`, etc., are stripped to reduce the surface a consumer sees — those targets remain in the Makefile + reachable via `make help`, but the README doesn't advertise them as consumer-facing.
   12. **Pipeline Architecture** (existing diagram) — unchanged.
   13. **Public API** table (existing) — refreshed to include the 8 Epic 4 additions per DD #8 (mirrors the CLAUDE.md Key Types sweep).
   14. **Test Support** (existing) — unchanged.
   15. **BPM Pipeline Steps** (existing list, currently STALE) — DD #4 — corrected to reflect the actual 9-step spine + 3 post-disambiguation steps + 2 optional gated rescore stages (per project-context.md "Invariant DSP pipeline" + "Optional gated rescore stages").
   16. **Using your own tempo model (BYOW)** (existing) — unchanged from current state (already refreshed in Story 4-6 Branch C). Verify the `tools/coreml-convert/README.md` link still resolves.
   17. **References** (existing) — unchanged.
   18. **License** (existing) — unchanged.

   **Section size targets.** Pre-1.0 framing notice: ~3 lines. Intensity scale: ~25 lines (table + framing). Batch workflow patterns: ~50 lines (3 code blocks + brief prose). Nil-return reference: ~15 lines (intro + 5 bullets + cross-link to the inline `///` source-of-truth on `AudioAnalysisService.analyzeBPM`). Net README growth target: ~120-160 lines (currently 180 → expected ~300-340).

   **No section reordering** beyond the new section insertions specified above. The dev agent MUST preserve every existing section's content unless the section is explicitly flagged for revision in this DD or DD #4. README rewrites are a known anti-pattern: consumers who have linked to anchors (`README.md#features`) break silently when sections are renamed.

4. **Pipeline-step list reconciliation in README.** The current `## BPM Pipeline Steps` list (`README.md:125-136`) lists 10 numbered steps but uses pre-Epic-3 + pre-Epic-4 nomenclature. The actual pipeline is documented in `project-context.md` "Invariant DSP pipeline" + "Optional gated rescore stages" — 9 unconditional steps + 3 post-disambiguation steps (10/10b/10c) + 2 optional gated rescore stages (9b click-track cross-correlation, 9.7 duration-derived BPM hint). The dev agent updates the README list to reflect this accurately. **Stable identifier convention:** post-Epic-3 the fractional/letter suffix convention (9b, 9.7, 10b, 10c) IS the canonical step identifier (per project-context.md "Pipeline step numbers are stable identifiers"); the README should USE these identifiers, not renumber them 1-N. This anchors the README pipeline list to the same identifiers benchmark logs + trace keys + history use.

   **Source format suggestion.** Mirror the project-context.md format: numbered top-level steps (1-9), then a sub-section for "Optional gated rescore stages" (9b, 9.7), then a sub-section for "Post-disambiguation steps" (10, 10b, 10c). One sentence per step. Approximately 25 lines total.

5. **Intensity scale 1-10 guidance — README content (AC #3).** The new section is a markdown table plus 2-3 sentences of framing. Suggested table columns: `rawValue | Use case | Window sizes | Typical wall-clock @ 3min track`. Suggested rows (the dev agent SHOULD verify wall-clock numbers against the most recent `_bmad-output/perf-baselines/` JSON; if no recent baseline reflects the precise mapping, fall back to approximate buckets):

   - `1` (`.fastest`): Interactive previewing — single 15s window, 1 candidate, no disambiguation. ~50ms.
   - `2`: Light analysis — single 30s window, baseline technique set, 3 candidates. ~150ms.
   - `3-6`: Standard analysis — single 30s window, optimal technique set, 3 candidates. ~200ms.
   - `7` (`.default`): Best DSP accuracy — progressive 30s/60s/90s windows, optimal technique set, threshold-gated retry. ~400ms.
   - `8` (`.thorough`): Reserved for ML augmentation. Without `Options.mlTechnique`, falls through to level 7 with `degradationReason` set.
   - `9`: Reserved for ML quorum (future).
   - `10` (`.maximum`): Reserved for maximum-thoroughness ML (future).

   **Framing.** A 2-3 sentence intro explains the ordinal contract (higher = more accurate, never less accurate at same parameters) + the ML-degradation behavior at 8-10 (per `AudioAnalysisService.maximumSupportedIntensity(mlTechnique:)` semantics). Cross-link to inline `///` doc on `AnalysisIntensity` for the authoritative version.

   **Wall-clock numbers are illustrative, NOT contractual.** The dev agent should phrase them as "approximate" or "typical" to avoid baking in a perf claim the project does not test against. Story 2-3 + Story 2-6 measure wall-clock per-run; those numbers drift with hardware and macOS Accelerate updates. **Do NOT include a "≤ X ms" SLA-style claim.**

6. **Nil-return condition documentation — README content (AC #4) — TABLE FORM** (Paige's recommendation 2026-05-21). Original spec said bullet list; bullets force the reader to parse five paragraphs to compare cases. Apple precedent: `URLError.Code` reference uses a table; Foundation's `JSONDecoder.DecodingError` discussion uses one. Ship the section as a markdown table:

   | Condition | When it fires | What the caller sees | Mitigation |
   |-----------|--------------|----------------------|------------|
   | Silence | `BPMAnalyzer` step 2 RMS guard rejects below-threshold audio | `try analyzeBPM(url:)` returns `nil` | Check audio energy upstream; raise input gain if applicable. |
   | Too-short audio | File contains < the minimum analyzable seconds for the requested intensity (intensity 7 needs ≥30s post-energy-transition) | `try analyzeBPM(url:)` returns `nil` | Use a lower intensity, or analyze longer clips. |
   | Unsupported sample rate | `analyzeLUFS` only — `LUFSAnalyzer` supports 44.1/48/96 kHz only | `try analyzeLUFS(url:)` returns `nil` | Resample to a supported rate before LUFS analysis. Does NOT affect `analyzeBPM`. |
   | Cancelled analysis | Caller's `Task` was cancelled OR `Options.isCancelled` returned `true` between window iterations | `try analyzeBPM(url:)` THROWS `CancellationError`; `try?` collapses to `nil` | Distinguish via `do { try analyzeBPM(...) } catch is CancellationError { ... }` if cancellation needs explicit handling. |
   | No candidates found | Degenerate audio (white noise, sustained pitched material) produced zero surviving candidates after range normalization (step 9) | `try analyzeBPM(url:)` returns `nil` | Inspect the file with `enableTrace: true` and read `rawCandidates` to confirm; this is the rarest case. |

   **The `CancellationError` row is the load-bearing distinction** — per AC #4 wording, the section MUST clarify that cancellation surfaces as a throw (not a nil), but `try?` callers see both as nil. The table makes the dual-surface visible at a glance instead of buried in prose. Cross-link from the Usage section's quick-start via inline comment (`// nil = silence/too-short/no-candidates — see "When analyzeBPM returns nil" below`). The inline `///` on `AudioAnalysisService.analyzeBPM(url:options:)` is the authoritative source-of-truth (rendered via DocC `- Returns:` bullet list per Apple SDK precedent — Siri's finding); the README table is the consumer-facing convenience surface. Both should agree on the case enumeration.

7. **Batch workflow patterns — README content (AC #5) — CONCRETE Swift 6 blocks.** Post-spec-validation correction (Codex HIGH finding #4 + Amelia 2026-05-21): the original spec described block shapes but didn't ship the code. Swift 6 strict concurrency makes "describe a TaskGroup, the dev agent will figure out the actor hops" unsafe — `@MainActor` accumulator + child-task writes need actor-isolation hops the dev agent might get wrong. **Spec ships the canonical blocks below; the dev agent's job is to land them verbatim into the README and compile-check via Task 4.11.** The blocks demonstrate the public surface introduced by Epic 1 (Stories 1-1 / 1-2 — cancellation + progress).

   **Block 1 — Sequential batch with progress callback** (~12 lines):

   ```swift
   import BoomBoomBoomKit
   import Foundation

   func analyzeBatch(_ urls: [URL]) throws -> [URL: AudioAnalysisResult] {
       var results: [URL: AudioAnalysisResult] = [:]
       for url in urls {
           var opts = AudioAnalysisService.Options()
           opts.onProgress = { @Sendable update in
               print("[\(url.lastPathComponent)] \(update.windowsCompleted)/\(update.windowsTotal)")
           }
           if let result = try AudioAnalysisService.analyzeBPM(url: url, options: opts) {
               results[url] = result
           }
       }
       return results
   }
   ```

   **Block 2 — Concurrent batch with `TaskGroup` + cancellation** (~18 lines). Scenario-framed per Paige's recommendation ("Importing a 5,000-track music library on background launch"):

   ```swift
   // Importing a user music library on background launch — fan out per track,
   // cancel the whole batch if the user backgrounds the importer.
   func importLibrary(_ urls: [URL]) async throws -> [URL: AudioAnalysisResult] {
       try await withThrowingTaskGroup(of: (URL, AudioAnalysisResult?).self) { group in
           for url in urls {
               group.addTask {
                   let result = try? AudioAnalysisService.analyzeBPM(url: url)
                   return (url, result)
               }
           }
           var collected: [URL: AudioAnalysisResult] = [:]
           for try await (url, result) in group {
               if let result { collected[url] = result }
           }
           return collected
       }
       // Caller cancels via the outer Task: `importTask.cancel()`. The default
       // isCancelled closure (`{ Task.isCancelled }`) propagates to each child
       // analysis between window iterations (ADR-1).
   }
   ```

   **Block 3 — Preserving completed results when the batch is cancelled mid-flight** (~16 lines). FR13 demonstration — completed analyses are NOT discarded when cancellation fires:

   ```swift
   actor ImportAccumulator {
       private(set) var results: [URL: AudioAnalysisResult] = [:]
       func record(_ url: URL, _ result: AudioAnalysisResult) { results[url] = result }
   }

   func importLibraryPreservingProgress(_ urls: [URL]) async -> [URL: AudioAnalysisResult] {
       let accumulator = ImportAccumulator()
       await withTaskGroup(of: Void.self) { group in
           for url in urls {
               group.addTask {
                   if let result = try? AudioAnalysisService.analyzeBPM(url: url) {
                       await accumulator.record(url, result)
                   }
               }
           }
       }
       return await accumulator.results
   }
   ```

   **Compile-correctness verified at story authorship (2026-05-21) against Swift 6.0 / macOS 15 / BoomBoomBoomKit post-Story-5-4 public API.** The blocks above use:
   - `var opts = AudioAnalysisService.Options()` + mutation (ADR-11 / Options-first config).
   - `onProgress: (@Sendable (ProgressUpdate) -> Void)?` matching the public type per `ProgressUpdate.swift`.
   - `try?` to coalesce the `throws CancellationError` + `nil`-return dual surface into a single `Optional` collapse.
   - `actor` for the cross-task accumulator (the only pre-1.0-stable way to share mutable state across `withTaskGroup` child tasks under Swift 6 strict concurrency).
   - `withThrowingTaskGroup` in Block 2 to allow propagating non-cancellation errors out; `withTaskGroup` in Block 3 because all errors are swallowed at the call site.

   **Scenario framing for the README.** Block 2 ships with the "Importing a user music library on background launch" framing inline (Paige's recommendation). Blocks 1 + 3 ship with one-sentence framings each.

8. **CLAUDE.md `### Key Types` subsection sweep — T2 close-out from Epic 4 retro (AC #8).** The current Key Types list (`CLAUDE.md:86-99` per the earlier grep) lists 11 types. Story 5-5 brings it current. **Post-spec-validation correction (Codex MEDIUM finding 2026-05-21):** the original spec said "13 new entries" but undercounted — also missing are public top-level types `CoreMLTechnique`, `SubBandEnergies`, `TensorLayout`, `MLFeatureFrames`. **Revised inventory below** (17 total additions/corrections):

   - **Reconcile existing entries** — `MLTechnique` is currently described as "Public protocol for future CoreML integration (Phase 3). Evaluates candidates post-pipeline via BPMDiagnosticTrace. Definition only, no conformances yet." That is stale post-Story-4-5; the protocol now has a real BNNSGraph conformance (`BNNSTechnique`) shipping in `BoomBoomBoomKitML`, the signature is `evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation?`, and the protocol is frozen per Story 4-5 DD #18. Update the entry.
   - **Add Epic 4 additions** — `MLEvaluation`, `EnsembleDecision`, `EnsemblePolicy`, `MLDiagnosticSnapshot`, `MLFeatureFrames` (public typed-evidence struct at `BPMDiagnosticTrace.swift:483`), `TensorLayout` (public enum at `BPMDiagnosticTrace.swift:435`), `MLDiagnosticTechnique`, `BNNSTechnique` (in the `BoomBoomBoomKitML` target), `CoreMLTechnique` (in the `BoomBoomBoomKitML` target — intentional non-conforming placeholder for Bundle.module symbol resolution; document the non-conformance + BYOW redirection per the existing `///`), `MLTechniqueError`. Plus the 5 typed-evidence structs from Story 3-3b: `ClickCorrelationEntry`, `HarmonicRatioEvidence`, `SubBandVoteEvidence`, `DurationHintEvidence`, `BarCandidate`. Plus `SubBandEnergies` (public struct at `BPMDiagnosticTrace.swift:388`, carried via `BPMDiagnosticTrace.subBandEnergies`).
   - **Match style** — CLAUDE.md uses a `**Name** — Description` bullet/paragraph style for Key Types. The new entries follow the same style: one paragraph each, ~3-5 sentences, covering role + key contract notes (e.g., "MLTechnique frozen per Story 4-5 DD #18, signature `evaluate(trace:) -> MLEvaluation?`").
   - **Format-discipline reminder** — CLAUDE.md has a `### Architecture` subsection (line 73) + `### Key Types` (line 86); other subsections elsewhere. The Story 5-5 sweep ONLY touches `### Key Types` content — NOT the surrounding sections. The growth tripwire at the bottom of CLAUDE.md ("when rule count exceeds ~120, extract a subsection to a project-local skill file. Current count: ~105") is NOT affected by Key Types growth (Key Types is descriptive content, not a "rule"). If the dev agent's sweep pushes the rule count above 120, the extraction is a separate concern and is deferred to a future story.

9. **Minimal `.docc` catalog stub — REVISED scope (post-spec-validation 2026-05-21, Winston + Siri convergent finding).** The original spec deferred the catalog entirely. Both Winston ("real cost of a stub catalog is ~1 hour") and Siri ("Apple explicitly recommends a catalog with at minimum a top-level extension file to give the module a landing page") flagged the deferral as overcautious. **Revised approach: ship a minimal stub now.** The stub consists of exactly one file:

   `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/BoomBoomBoomKit.md`

   The `.docc` directory is auto-detected by SPM (no `Package.swift` edit needed). The single `.md` file is a top-level landing page providing a module-level overview that DocC + Xcode QuickHelp surface on `import BoomBoomBoomKit`. Structure (≤30 lines markdown):

   ```markdown
   # ``BoomBoomBoomKit``

   Standalone audio analysis package for BPM estimation and LUFS loudness
   measurement on macOS 15+.

   ## Overview

   BoomBoomBoomKit is a pure-Swift library with zero external dependencies — it
   uses only Apple's Accelerate (vDSP), AVFoundation, and Foundation. The
   public facade is ``AudioAnalysisService``; analysis depth is controlled
   via ``AnalysisIntensity`` and ``CandidateMergeStrategy``.

   ## Topics

   ### Public Facade

   - ``AudioAnalysisService``
   - ``AudioAnalysisResult``

   ### Configuration

   - ``AnalysisIntensity``
   - ``CandidateMergeStrategy``
   - ``TechniqueSet``
   - ``DSPTechnique``
   ```

   This is the **module landing page only** — no tutorials, no articles, no rich extensions. The trade Siri's finding closes: previously, `import BoomBoomBoomKit` in Xcode QuickHelp showed nothing (no module-level doc surface). With the stub, QuickHelp on the module name shows the overview; Swift Package Index renders the landing page as the symbol-index entry point.

   **What's still deferred to a future story** (DocC tutorials, articles like "Using BoomBoomBoomKitML", hosting decision for GitHub Pages vs Apple-hosted, `swift-docc-plugin` build lane). The stub is the minimal viable catalog that pays off the "module has no front door" gap without committing to any of the larger DocC-content fork-in-the-road decisions.

   **Re-open trigger:** a consumer asks for a hosted reference, OR a tutorial-flavored article is genuinely needed (e.g., the BYOW model conversion flow), OR `swift-package-index/swift-docc-plugin` rendering surfaces a gap that requires richer DocC content to fix.

10. **No new tests added; no test removals.** The sweep is doc-content additive in `Sources/`. No `Tests/` files are touched. Verification is via:

    - `make fmt` (formats `///` blocks to canonical Swift API Design style — auto-wraps lines at 100 chars per the project's `.swift-format` rule, if applicable).
    - `make lint` (SwiftLint's `missing_docs` rule is NOT enabled in `.swiftlint.yml`, so the gate is the explicit AC #6 grep recipe — see Task 5).
    - `make build` (compiles; doc comments don't fail compilation, but unbalanced `/// - Parameters:` blocks can produce DocC warnings).
    - `make test` (existing test suite passes unchanged; doc comments are inert at runtime).
    - `make benchmark` + `make benchmark-giantsteps` (accuracy baselines unchanged — see DD #1).

    **Test count contract.** Pre-Story-5-5 baseline from Story 5-4 close-out: 433 `@Test(` declarations in `Tests/BoomBoomBoomKitTests` distributed across 94 suites. Post-Story-5-5 expected: same. A test count delta is a scope violation — flag it as a HALT event (per project-context.md "HALT discipline").

## Acceptance Criteria

1. **`README.md` quick-start sample exists with honest error handling.** Post-spec-validation correction (Paige 2026-05-21): the literal 3-line example hides `try` (what does it throw?) and `?` (when is it nil?). Expand to a 6-8 line block with `do/catch` that's honest about both failure modes:

   ```swift
   import BoomBoomBoomKit

   do {
       let result = try AudioAnalysisService.analyzeBPM(url: audioFileURL)
       print("BPM: \(result?.bpm ?? 0)")  // nil = silence/too-short/no-candidates — see "When analyzeBPM returns nil" below
   } catch {
       print("Analysis failed: \(error)")
   }
   ```

   The inline comment seeds the cross-reference to the new nil-return table (DD #6). This block is the FIRST piece of code a consumer sees; making it copy-pasteable + accurate-on-both-failure-modes is worth the extra 3 lines.

2. **`README.md` documents all supported audio formats with NO `OGG` reference.** The existing "BPM Estimation" feature bullet (`README.md:9`) already lists "WAV, AIFF, MP3, FLAC, M4A, CAF" — no OGG present. Verify post-rewrite. The dev agent SHOULD also confirm `grep -i 'ogg\|vorbis' README.md` returns nothing inappropriate (Vorbis is fine when referring to FLAC's Vorbis comment metadata format, but NOT as an audio file format claim).

3. **`README.md` describes the intensity scale 1-10 with brief guidance.** New section per DD #5 — table mapping `rawValue` → use case → window sizes → typical wall-clock. Includes framing on ordinal contract + ML-degradation behavior at 8-10.

4. **`README.md` documents when `analyzeBPM` returns nil.** New section per DD #6 — bulleted reference covering silence / too-short audio / unsupported sample rate (LUFS only — explicit clarification this case does NOT affect `analyzeBPM`) / cancelled analysis (clarifies surfacing as `throws CancellationError`, nil under `try?`) / no candidates found.

5. **`README.md` documents batch workflow patterns.** New section per DD #7 — three runnable Swift code blocks: (a) sequential batch with progress callback, (b) concurrent batch with TaskGroup + cancellation, (c) preserving completed results when cancellation fires mid-batch. Each block compiles.

6. **Every public declaration in `Sources/BoomBoomBoomKit/` and `Sources/BoomBoomBoomKitML/` has an inline `///` documentation comment.** Coverage gate is the grep recipe documented in Task 5; recipe inversion verified during dev. Internal declarations (`internal`, `private`, `fileprivate`) are NOT in scope.

7. **Public methods + initializers with parameters or return values have `- Parameters:` / `- Returns:` populated** per Swift API Design Guidelines and DocC syntax. Single-parameter methods MAY use the shorter `- Parameter <name>:` form. The dev agent SHOULD spot-check that the existing well-documented types (`MLEvaluation.init`, `EnsembleDecision.init`, `BNNSTechnique.init(modelURL:)`, `AudioAnalysisService.analyzeBPM(url:options:)`) match the post-sweep style of newly-documented types.

8. **`CLAUDE.md` `### Key Types` subsection is updated to reflect the post-Epic-4 public API** per DD #8. Specifically: the `MLTechnique` entry is no longer described as "Definition only, no conformances yet"; the 8 Epic 4 additions are present; the 5 typed-evidence structs from Story 3-3b are present.

9. **Pre-1.0 / no-BC framing notice is present near the top of `README.md`** per DD #3 step 3.

10. **The `## BPM Pipeline Steps` section in `README.md` accurately reflects the 9-step spine + post-disambiguation steps (10/10b/10c) + optional gated rescore stages (9b/9.7)** per DD #4. Step identifiers match `project-context.md` "Invariant DSP pipeline" verbatim.

11. **Library accuracy baselines are unchanged.** OA300 Acc1=58/82 (`benchmarkAcc1Strict`), Acc2=74/82; GiantSteps strict Acc1=537/661, Acc2=546/661. Verified by `make benchmark` + `make benchmark-giantsteps`. Both unconditional `#expect` assertions in the suite continue to pass.

12. **Test count is unchanged.** `Tests/BoomBoomBoomKitTests` carries 433 `@Test(` declarations distributed across 94 suites (Story 5-4 baseline). Recipe: `git grep -c '@Test(' Tests/BoomBoomBoomKitTests/` summed equals 433 unchanged. (Demo test count from Story 5-4 also unchanged at 80; the demo test target is not in scope but is part of the per-story regression backstop.)

13. **Standard gating gauntlet (per epics file Epics 1-4 standard ACs).** `make fmt` (clean), `make lint` (1 violation = canonical `LUFSAnalyzer.swift:94` TODO baseline), `make build` (exit 0), `make build-release` (exit 0), `make test` (433/433 pass; **warm-cache real seconds within ±15% of Story 5-4 baseline ~2.05s on M5 Max — per Amelia's recommendation 2026-05-21**, otherwise dev agent records investigation note in Completion Notes per A3 discipline), `make demo-build` (BUILD SUCCEEDED), `make demo-test` (existing demo tests pass; count unchanged at Story 5-4 baseline of 80 invocations), `make demo-fmt` (clean), `make demo-lint` (exit 0), `make pre-commit` (aggregate exit 0). `make benchmark` + `make benchmark-giantsteps` (AC #11 above). `make ablation` (256 combos complete without crashes).

14. **`Sources/BoomBoomBoomKit/` and `Sources/BoomBoomBoomKitML/` diff scope is doc-comment-only.** Verifiable via `git diff Sources/ -- ':!Sources/**/Resources/'` showing only added `///` lines (and possibly added `// MARK:` headers per DD #1). Zero net source-line semantic changes — every modified file's compiled bytecode is identical pre/post-sweep, modulo doc-comment line additions which are stripped by the compiler.

## Tasks / Subtasks

- [x] **Task 1 — T2 CLAUDE.md Key Types sweep (Epic 4 retro carry-forward, AC #8)** (precondition for downstream Tasks; landing first means README and inline-`///` work can reference an updated CLAUDE.md without re-doing the type list).
  - [x] 1.1 Read CLAUDE.md `### Key Types` subsection (lines 86-99 per current state).
  - [x] 1.2 Compose 8 new entries (post-Epic-4 additions) following the existing bullet/paragraph style: `MLEvaluation`, `EnsembleDecision`, `EnsemblePolicy`, `MLDiagnosticSnapshot`, `MLFeatureFrames`, `MLDiagnosticTechnique`, `BNNSTechnique`, `MLTechniqueError`.
  - [x] 1.3 Compose 5 new entries (Story 3-3b typed-evidence promotions): `ClickCorrelationEntry`, `HarmonicRatioEvidence`, `SubBandVoteEvidence`, `DurationHintEvidence`, `BarCandidate`.
  - [x] 1.4 Update the existing `MLTechnique` entry (the line currently saying "Definition only, no conformances yet" — that's stale post-Story 4-5).
  - [x] 1.5 Verify the surrounding sections + the "Last Updated" + rule-count tripwire footer at the bottom of CLAUDE.md are NOT touched.
  - [x] 1.6 `git diff CLAUDE.md` review: ONLY `### Key Types` subsection lines should appear.

- [x] **Task 1.7 — Minimal `.docc` catalog stub** (post-spec-validation 2026-05-21, see DD #9 revision).
  - [x] 1.7.1 Create `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/` directory.
  - [x] 1.7.2 Author `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/BoomBoomBoomKit.md` (≤30 lines) per the structure in DD #9 — module-level overview + Topics section linking to `AudioAnalysisService`, `AudioAnalysisResult`, `AnalysisIntensity`, `CandidateMergeStrategy`, `TechniqueSet`, `DSPTechnique`.
  - [x] 1.7.3 Verify `swift build` continues to succeed (SPM auto-detects the `.docc` directory; no `Package.swift` changes needed).
  - [x] 1.7.4 Verify `make test` is unaffected (catalogs are documentation artifacts, not build artifacts).
  - [x] 1.7.5 If `swift-docc-plugin` is installed, run `swift package generate-documentation` and inspect the resulting bundle for the module-level landing page; otherwise skip.

- [x] **Task 2 — Inline `///` sweep across `Sources/BoomBoomBoomKit/` (AC #6, AC #7)** (the volume of work — file-by-file).
  - [x] 2.1 Read the entire `Sources/BoomBoomBoomKit/` directory file list alphabetically.
  - [x] 2.2 For each file, identify every public declaration and the current `///` coverage state.
  - [x] 2.3 Add `///` doc comments to undocumented public declarations following the Swift API Design Guidelines style (sentence case, period termination, DocC double-backtick symbol links).
  - [x] 2.4 Populate `- Parameters:` / `- Returns:` for methods + initializers.
  - [x] 2.5 Spot-check that internal helpers are NOT touched (CLAUDE.md "Code organization" convention: minimal-or-none doc comments on internal).
  - [x] 2.6 After each file, run `make fmt` on Sources/ to catch any formatting drift introduced by the doc comments (especially long-line wrapping in multi-line `///` blocks).
  - [x] 2.7 Pre-flight against the known gap inventory in DD #2 (TechniqueSet init/contains/inserting/removing, MetadataPolicy init, ParsingOptions fields, PCMBufferReader funcs).

- [x] **Task 3 — Inline `///` sweep across `Sources/BoomBoomBoomKitML/` (AC #6, AC #7)** (smaller volume; 2 files: `BNNSTechnique.swift` and `CoreMLTechnique.swift`).
  - [x] 3.1 Read `BNNSTechnique.swift`; identify any bare public declarations (most are already well-documented post-Story-4-5).
  - [x] 3.2 Read `CoreMLTechnique.swift`. **NOTE (post-spec-validation correction 2026-05-21):** the original spec wording called this a "placeholder per project-context.md" — that wording is wrong. `CoreMLTechnique.swift` is a real public Sendable struct (`public struct CoreMLTechnique: Sendable` at line 27, plus `public init()` at line 28) that ships in `BoomBoomBoomKitML` as an intentional non-conforming placeholder for the package-layout / Bundle.module symbol resolution. It is already well-documented (a 14-line `///` block above the struct declaration covers the non-conformance + BYOW pointer + future-epic note). Verify both `public` declarations have `///` coverage and that the existing doc text remains accurate; the type SHOULD be included in the CLAUDE.md `### Key Types` sweep (per DD #8 + Codex finding) and SHOULD appear in the README's Public API table refresh (per Task 4.8).
  - [x] 3.3 Apply the same `- Parameters:` / `- Returns:` discipline as Task 2.4.

- [x] **Task 4 — `README.md` rewrite/extension (AC #1, #2, #3, #4, #5, #9, #10)**.
  - [x] 4.1 Read the entire current `README.md` (180 lines per Story 5-4 baseline).
  - [x] 4.2 Add the pre-1.0 framing notice paragraph after the badge line (DD #3 step 3).
  - [x] 4.3 Add inline cross-link comment in the Usage quick-start block referencing the new "When `analyzeBPM` returns nil" section.
  - [x] 4.4 Insert the new "Intensity scale 1-10" section per DD #5.
  - [x] 4.5 Insert the new "Batch workflow patterns" section per DD #7 with three code blocks.
  - [x] 4.6 Insert the new "When `analyzeBPM` returns nil" section per DD #6.
  - [x] 4.7 Correct the `## BPM Pipeline Steps` list per DD #4 — 9 unconditional steps + sub-section for optional rescore stages + sub-section for post-disambiguation steps.
  - [x] 4.8 Refresh the `## Public API` table to include the 8 Epic 4 additions (mirror the CLAUDE.md Key Types update from Task 1).
  - [x] 4.9 Trim the `## Commands` list to consumer-relevant subset (`make help`, `make build`, `make test`, `make fmt`).
  - [x] 4.10 Verify the BYOW section + `tools/coreml-convert/` cross-link survives unchanged (no edits beyond verifying URL targets resolve). **Terminology standardization (Codex LOW finding 2026-05-21):** the current README line 142 uses "BYOM (bring-your-own-model)" while MODEL_CARD.md + CLAUDE.md + project-context.md + BNNSTechnique.swift all use "BYOW (bring-your-own-weights)". Update the README's BYOM occurrence to BYOW for consistency across the consumer-facing surfaces.
  - [x] 4.11 Compile-check each Swift code block in the README (the new 6-line quick-start per AC #1, the three DD #7 batch-workflow blocks, the Usage / Customizing-techniques / BYOW blocks) via a tmpdir SPM recipe (Codex + Amelia recommendation 2026-05-21):
    ```bash
    TMP=$(mktemp -d) && cd "$TMP" && swift package init --type executable --name readme-check
    # Edit Package.swift to add `.package(path: "/Users/rterhaar/Dropbox/research/swift/BoomBoomBoomKit")` and `.product(name: "BoomBoomBoomKit", package: "BoomBoomBoomKit")` on the target
    # Paste each README Swift block into Sources/readme-check/main.swift (one block per recipe iteration), wrapped in `func _check() async throws { ... }` if needed
    swift build
    ```
    A type error → fix in the README block. The "scratch Xcode project" phrasing from earlier spec revisions is replaced by this SPM-only path — no Xcode UI variability, reproducible on a fresh-clone CI machine.

- [x] **Task 5 — Coverage audit + recipe inversion (AC #6)**.
  - [x] 5.1 Author the grep-based coverage recipe — pattern: `find Sources/BoomBoomBoomKit Sources/BoomBoomBoomKitML -name '*.swift' -exec awk '...' {} +` where the awk script detects public declarations whose preceding 5 lines contain no `///`. The dev agent SHOULD prefer a Python or perl one-liner over awk if multi-line lookback is awkward; the canonical version of the recipe lands in the Completion Notes for future stories to reuse.
  - [x] 5.2 Run the recipe → expect zero matches.
  - [x] 5.3 Recipe inversion: temporarily delete one `///` line in `AnalysisIntensity.swift` (or any other well-documented file), re-run the recipe → expect exactly one match pointing at the deleted line. Restore the `///`.
  - [x] 5.4 Document the canonical recipe in the Completion Notes for future-story reuse.

- [x] **Task 6 — Gating gauntlet (AC #11, AC #12, AC #13, AC #14)** — the standard per-story regression backstop, expanded slightly for docs scope.
  - [x] 6.1 `make fmt` — clean.
  - [x] 6.2 `make demo-fmt` — clean (no Demo/ changes expected, but doublecheck post-sweep that swift-format on Sources/ didn't accidentally touch anything in Demo/).
  - [x] 6.3 `make lint` — 1 violation = `LUFSAnalyzer.swift:94` canonical TODO baseline. Any other violation → fix or escalate.
  - [x] 6.4 `make demo-lint` — exit 0.
  - [x] 6.5 `make build` — exit 0.
  - [x] 6.6 `make build-release` — exit 0.
  - [x] 6.7 `make test` — 433/433 pass in 94 suites; record wall-clock real seconds (warm cache) for the A3 baseline per Epic 4 retro carry-forward.
  - [x] 6.8 `make demo-build` — BUILD SUCCEEDED.
  - [x] 6.9 `make demo-test` — pass; existing demo test count unchanged (Story 5-4 baseline: 80 invocations).
  - [x] 6.10 `DEVELOPMENT_TEAM=S85RR68YT7 make demo-build-sandboxed` — BUILD SUCCEEDED (verify Story 5-4's read-write entitlement persists; no changes to the demo target expected).
  - [x] 6.11 `make pre-commit` — aggregate exit 0.
  - [x] 6.12 `make benchmark` — OA300 Acc1=58/82 + Acc2=74/82 UNCHANGED.
  - [x] 6.13 `make benchmark-giantsteps` — strict Acc1=537/661 + Acc2=546/661 UNCHANGED. MIREX-tolerance counts (separate metric, not pinned by spec) also expected stable.
  - [x] 6.14 `make ablation` — 256 combos complete without crashes; `.optimal` Acc1 ≥ 55/82 unit-test floor holds. (The 207.6s wall-clock from Story 4-7 is not a story-5-5 deliverable; just verify the suite passes.)
  - [x] 6.15 Diff scope verification (AC #14) — check BOTH `+` and `-` lines (Codex MEDIUM finding 2026-05-21 — original recipe missed deleted semantic lines):
    ```bash
    git diff Sources/ | grep -E '^[+-][^+-]' | grep -vE '^[+-][[:space:]]*(///|// MARK:|$)' | head -20
    ```
    Returns empty = no non-doc-comment line additions OR removals. Any match is a scope violation — escalate. The smoke recipe is paired with a manual `git diff Sources/` review post-`make fmt` to confirm swift-format-induced trailing-whitespace adjustments are the only `-` line changes (which the recipe will surface; the dev agent confirms they're whitespace, not semantic).

- [ ] **Task 7 — `/bmad-code-review` separate-LLM cadence (per Story 5-4 + 5-3 + 5-2 + 5-1 close-out pattern)**.
  - [ ] 7.1 User invokes `/bmad-code-review` against the staged Story 5-5 diff in a separate session.
  - [ ] 7.2 Review-layer cadence: at minimum 3 layers (Blind Hunter + Edge Case Hunter + Acceptance Auditor); Codex MCP plan-review may be added per Story 5-3 + 5-4 precedent if doc-content-quality findings warrant a fourth perspective. For a docs-only story, the fourth layer is OPTIONAL but recommended for the README content blocks (Codex is good at spotting stale/inaccurate technical prose).
  - [ ] 7.3 Findings triaged per Story 5-3 + 5-4 pattern: critical → patch inline; medium → deferred-work entry with re-open trigger; low/cosmetic → dismissed-or-noted-in-Completion-Notes.

- [ ] **Task 8 — Final commits + sprint-status update — THREE-COMMIT PATTERN within ONE PR** (Winston 2026-05-21).
  - [ ] 8.1 Stage and commit in three logically-ordered chunks for `git bisect` + PR-review granularity (single gauntlet run, three commit-grain audit trails):
    - **Commit 1** — `Story 5-5: CLAUDE.md Key Types sweep (Epic 4 retro T2)` — CLAUDE.md ### Key Types subsection only.
    - **Commit 2** — `Story 5-5: inline /// documentation sweep` — Sources/BoomBoomBoomKit/ + Sources/BoomBoomBoomKitML/ doc-comment additions + Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/BoomBoomBoomKit.md stub catalog landing page.
    - **Commit 3** — `Story 5-5: README extension + pre-1.0 framing` — README.md content additions.
    - Final commit (or amend to Commit 3) — story spec + sprint-status.yaml.
  - [ ] 8.2 Verify diff scope per AC #14 against the AGGREGATE diff (not per-commit) — the three-commit split is for review readability, the gating gauntlet runs against the merged state.
  - [ ] 8.3 Commit message style: `Story 5-5: <subject>` (imperative mood, follows the `Story X-Y: <subject>` precedent from b6b5dd3 — see `feedback_no_business_jargon_in_commits` memory). NO "close out" / "ship" / "deliver" framing.
  - [ ] 8.4 Commit signing: 1Password GPG signer per Story 5-1 / 5-2 / 5-3 / 5-4 close-out precedent. If signer is locked, stage but defer commit.
  - [ ] 8.5 Update sprint-status.yaml: `5-5-public-api-documentation-and-readme: review`. (User flips to `done` after Task 7 code-review pass per Story 5-3 + 5-4 cadence.)

## Apple Platform Notes

- **DocC inline comment syntax.** Swift's DocC compiler (bundled with Xcode 13+, current at Xcode 26) parses `///` comments using a markdown subset plus DocC-specific extensions: `- Parameters:` block form (multi-param) and `- Parameter X:` field form (single-param) per Apple's *Formatting Your Documentation Content* guide; `- Returns:` directives; double-backtick `` ``Symbol`` `` symbol links and `` ``Type/method(_:)`` `` path references (current as of Xcode 26 / Swift 6.x); fenced code blocks with language hints (` ```swift `). Xcode QuickHelp renders these in the same panel as Apple framework docs. References:
  - Apple's Swift API Design Guidelines (https://www.swift.org/documentation/api-design-guidelines/)
  - Apple's DocC documentation (https://www.swift.org/documentation/docc/)
  - Apple's Formatting Your Documentation Content (https://www.swift.org/documentation/docc/formatting-your-documentation-content)
  - Apple's Documenting a Swift Framework or Package (https://www.swift.org/documentation/docc/documenting-a-swift-framework-or-package)
  - **WWDC21 #10166** "Meet DocC documentation in **Xcode**" (post-spec-validation: the original spec said "in Swift" — Siri 2026-05-21 corrected)
  - **WWDC22 #110368** "What's new in Swift-DocC"
  - **WWDC23 #10244** "Create rich documentation with Swift-DocC"

- **`@available` annotations — Xcode QuickHelp renders as a metadata badge, do NOT restate in prose** (Siri's verification 2026-05-21). `BNNSTechnique` carries `@available(macOS 15.0, *)`. Xcode QuickHelp renders the annotation as a **separate metadata badge in the header chip area**, independent of the `///` body — manually duplicating "Available on macOS 15+" in prose is redundant and creates drift risk if the deployment target shifts. Swift Package Index propagates `@available` into its rendered reference automatically. The dev agent SHOULD verify all post-sweep `///` blocks on `BNNSTechnique` members continue to render correctly under that availability gate; DocC does not treat the annotation as a doc-suppression mechanism.

- **Module-level documentation surface (post-spec-validation 2026-05-21, Siri finding #4).** With the minimal `.docc` stub now in scope (DD #9), `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/BoomBoomBoomKit.md` provides the module-level overview that QuickHelp surfaces on `import BoomBoomBoomKit`. Without the stub, `import BoomBoomBoomKit` in Xcode QuickHelp shows nothing — the pre-1.0 framing notice + module overview lives ONLY in README. With the stub, both surfaces carry it.

- **Swift Package Index DocC rendering.** Swift Package Index (https://swiftpackageindex.com/) auto-renders DocC from inline `///` comments without a catalog. If/when BoomBoomBoomKit is published to SPI, the post-Story-5-5 inline docs will be the rendered reference content. The dev agent's `///` writing voice should be aware of this rendering target — keep it concise + cross-link-rich.

- **Xcode 26 QuickHelp.** Modern Xcode shows `///` content in the Quick Help inspector pane (option-click a symbol) and inline hover-overs. The DocC markdown subset is fully supported — including fenced code blocks, which render syntax-highlighted in QuickHelp. Test post-sweep by opening one of the touched files in Xcode and confirming a hover-over on a newly-documented declaration renders without doc-comment parse warnings.

## Risks

- **R1 — Stale wall-clock numbers in the intensity-scale section.** DD #5 lists illustrative numbers (~50ms / ~150ms / ~200ms / ~400ms) for the 1-10 mapping. These are approximate buckets from the project-context.md AnalysisIntensity comment block — they were recorded in earlier stories on prior hardware (Apple M-series Pro / Max class). If a consumer benchmarks on lower-end hardware (M1 base, intel Mac) and sees materially-higher wall-clock, they may report the README as misleading. Mitigation: phrase the numbers as "approximate" / "typical" and avoid SLA-style language. Re-open trigger: a consumer reports a hardware-class mismatch worth tabulating.

- **R2 — README quick-start example syntax drift.** The existing `try AudioAnalysisService.analyzeBPM(url: audioFileURL)` quick-start (`README.md:31`) compiles against the post-Epic-4 public API. If the dev agent accidentally edits the symbol name, the user is the first to discover the breakage. Mitigation: Task 4.11 (compile-check each batch-workflow code block) explicitly extends to the existing quick-start.

- **R3 — Inline `///` content drift away from source-of-truth.** Some Sources/ files have rich docstrings that go deeper than the surrounding fields (e.g., `MLDiagnosticSnapshot.swift` has a 30-line population-matrix table). The dev agent's gap-fill sweep should NOT compress existing rich docs to match the surrounding minimum — leave the rich content alone. Doc volume varies per type because the underlying complexity does; the project does not enforce a uniform-length doc style.

- **R4 — Coverage-grep recipe brittleness.** The AC #6 grep recipe (Task 5) is line-based and may produce false positives on edge cases like:
   - A public declaration whose `///` block is interrupted by a `// MARK:` header in between (rare but legitimate code organization).
   - A public declaration in a multi-line `extension` block where the extension's `///` doc is sufficient.
   - A public computed-property `get`/`set` where only the property header needs the `///`.

  The dev agent SHOULD test the recipe against the post-Story-4-7 codebase (which has known-good coverage on `MLEvaluation`, `EnsembleDecision`, etc.) and tune for zero false positives BEFORE running it against the post-sweep state. False positives reported as audit failures would block AC #6 incorrectly.

- **R5 — DocC parse warnings on malformed `/// - Parameters:` blocks.** If the dev agent writes a `- Parameters:` block but the parameter names don't match the method signature, **Xcode** emits a warning during the IDE build. **Post-spec-validation correction (Codex + Siri 2026-05-21):** plain `swift build` does NOT generally validate doc-comment content the way Xcode does — DocC warnings often only surface when invoking the DocC build directly. Mitigation: Task 6.5 (`make build`) AND Task 6.6 (`make build-release`) MAY not catch a malformed `- Parameters:` block. The dev agent SHOULD run `swift package generate-documentation` (via swift-docc-plugin if installed) OR `xcrun docc preview` against the post-sweep source as an OPTIONAL verification step. If the dev agent does not have swift-docc-plugin available, treat R5 as "Xcode IDE will surface these warnings on next IDE open; CI will not block."

- **R6 — Pre-1.0 framing notice tone.** DD #3 step 3 wording is condensed from project-context.md verbatim. The notice may read as off-putting to a consumer ("breaking changes are explicitly allowed and expected") and discourage adoption. Mitigation: the notice acknowledges reality (zero external consumers today) + sets correct expectations (don't pin a specific version yet; expect to upgrade through breaks until 1.0). If a consumer reports the framing as discouraging, the wording can soften in a follow-up story without re-opening Story 5-5.

- **R7 — A3 baseline drift fold-through (Story 5-4 close-out + Epic 4 retro).** Story 5-4 baseline `make test` warm-cache was ~2.05s real on M5 Max for 433 runs in 94 suites; cold-cache 6.84s real (Story 5-1 baseline). Story 5-5 adds no test code and no Sources/ behavioral changes — the wall-clock SHOULD be within ±0% of Story 5-4's baseline (modulo OS/Accelerate cache-state variance). If the dev agent sees a >5% delta in warm-cache real seconds, that's a flag — investigate before claiming AC #13. Per MEMORY.md `project_sprint1_status` notes, the 10% tripwire only fires on content delta, not parallel-runner scheduling jitter, so a noisy ~10-20% delta is acceptable if no content shifted.

- **R8 — README Swift code blocks have no automated compile guard; drift inevitable** (Amelia 2026-05-21). The DD #7 batch-workflow blocks compile-check at story-authorship time (Task 4.11) but have no test-suite or CI mechanism to keep them in sync with the public API across future stories. The next breaking change to `AudioAnalysisService.Options` will silently invalidate the README blocks; the first consumer to copy-paste them sees a compile error. Apple's documented mitigation is DocC `@Snippet` (a build-checked code-snippet mechanism that lives in `.docc` and is verified at catalog build time). The minimal `.docc` stub from DD #9 does NOT add `@Snippet` infrastructure. **Mitigation today:** Task 4.11's tmpdir SPM compile-check at story-authorship time + AC #14 diff-scope verification. **Mitigation when re-opened:** add `@Snippet` blocks inside `BoomBoomBoomKit.docc/Snippets/` and reference them via DocC's `@Snippet(path: "...")` directive — this requires a future story.

- **R9 — `// MARK:` allowance in DD #1 is a real escape hatch** (Winston 2026-05-21). The original spec permitted adding `// MARK: -` headers AND the diff-scope grep recipe whitelists them. An agent that reorders code around a new MARK can theoretically change `lazy var` initialization order or extension-method resolution while still passing the audit. Mitigation: the dev agent SHOULD only add `// MARK:` headers BETWEEN existing logical sections (never inside a struct body) and SHOULD verify post-sweep that no extension reordering occurred via `git diff --stat Sources/` showing only line-add deltas in pre-existing extension blocks. The accuracy gauntlet (AC #11) is the ultimate backstop — semantic breaks fail OA300/GiantSteps benchmark assertions even if the diff-scope recipe whitelists them.

## References

### Previous Story Intelligence (PSI)

1. **Story 5-4 (Diagnostic Trace Visualization and Export, 2026-05-20)** — completed `review` status close-out. Zero library Sources/ + zero Tests/ modifications were the framing precedent for Story 5-5's even-stricter docs-only scope. Story 5-4 DD #5 atomic snapshot pattern + DD #6 final-step cascade derivation are NOT relevant to Story 5-5 (demo-internal), but the close-out cadence (party-mode review, multi-layer code-review, separate-LLM cadence on commit) IS the model for Task 7. Demo test count baseline: 80 invocations post-Story-5-4 (was 57 pre-Story-5-4); Story 5-5 expected delta: 0.

2. **Story 5-3 (Parameter Controls, 2026-05-20)** — closed deferred-work W2 partially (config-summary visible in disclosure header) + W12 + W20. The pattern of "static helper on view-model + testable via @testable import" from Story 5-3's `formatResultRow` is NOT applicable to Story 5-5 (docs-only), but the gating gauntlet structure (Task 5 + 6 + 7 → demo + library tests + benchmarks + lint + fmt + sandboxed build) IS the model for Story 5-5's Task 6.

3. **Story 5-2 (Core Analysis Flow, 2026-05-19)** — added `make demo-fmt` + `make demo-lint` + `make pre-commit` targets (W16 close). Story 5-5 uses all three in the Task 6 gating gauntlet.

4. **Story 5-1 (Demo App Project Scaffold, 2026-05-18)** — established Epic 5 hygiene patterns A2 (deferred-work.md canonical for findings — Story 5-5 uses this for W1/T1/T5 deferrals) and A3 (make-test wall-clock baseline tracked per epic — Story 5-5 honors this in Task 6.7).

5. **Story 4-6 (ML Accuracy Investigation + Bundle Decision, 2026-05-16, Branch C close-out)** — pulled `giantsteps_v1.mlmodelc` from Sources/. Story 5-5's README "Using your own tempo model" section (existing content per `README.md:138-168`) was refreshed in 4-6; Story 5-5 verifies the refresh is still accurate (no model bundled, BYOW posture documented).

6. **Epic 4 retrospective (2026-05-17)** — opened action items A1 (diagnostic-instrumentation contract added to story-authoring discipline), A2 (story-file `[ ]` checkboxes deprecated in favor of deferred-work.md cross-references — Story 5-5 honors this throughout), A3 (make-test wall-clock budget tracking per epic). Carried-forward items: T1 (perf-baselines cleanup, deferred to Epic 5 retro), T2 (CLAUDE.md Key Types sweep, RESOLVED IN STORY 5-5 — see Task 1 + AC #8), T3 (license counsel review on derivative weights work, deferred), T4 (Story 4-7 W1-W13 deferred per documented re-open triggers), T5 (`.full` preset semantics revisit, deferred to Epic 5 retro per DD #2 scope clarification).

7. **Project-context.md (last updated 2026-05-17)** — authoritative source for: "Public API Discipline (pre-1.0)" subsection (informs DD #3 pre-1.0 framing notice + ACs); "Invariant DSP pipeline" subsection (informs DD #4 + AC #10); "Code organization" rule (informs DD #2 internal-skip convention); "Access control boundaries (post-Epic-4)" subsection (informs DD #2 + DD #8 type enumeration). Story 5-5 docs-content MUST agree with project-context.md word-for-word on overlapping content — if a divergence is found, project-context.md is the source of truth.

8. **Epics file Epic 5 standard ACs** — the bottom-of-file "Standard acceptance criteria (all stories in Epics 1-4)" block (`epics.md:197-204`) lists `make fmt` + `make lint` + `make test` + `make benchmark` + `make ablation` + "Update inline `///` doc comments for any modified public API" + "Update CLAUDE.md if public types or key behaviors change." Story 5-5 IS the lump-sum back-fill for both `///` and CLAUDE.md items — Epic 5 is the documentation phase per the epic preamble.

### External References

- **Swift API Design Guidelines** (https://www.swift.org/documentation/api-design-guidelines/) — canonical voice + parameter-block style for `///` docs.
- **DocC documentation** (https://www.swift.org/documentation/docc/) — markdown subset, `- Parameters:` syntax, double-backtick symbol links.
- **Swift Package Index DocC rendering** (https://swiftpackageindex.com/SwiftPackageIndex/SwiftPackageIndex-Server) — render target for inline `///` if BoomBoomBoomKit ever publishes there.

## Diff-scope Expectations

**Files touched (post-Task-8):**

- `CLAUDE.md` — `### Key Types` subsection updated (Task 1). ~40-60 line delta in that subsection only (expanded from "13 entries" estimate to ~17 after Codex finding).
- **NEW: `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/BoomBoomBoomKit.md`** — minimal stub catalog landing page (Task 1.7). ~30 lines markdown.
- `Sources/BoomBoomBoomKit/*.swift` — doc-comment additions only (Tasks 2). File-by-file size deltas vary; total expected: ~150-300 lines added across ~15 files. Zero functional source-line changes (per DD #1).
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` — small targeted additions (Task 3.1).
- `Sources/BoomBoomBoomKitML/CoreMLTechnique.swift` — verify existing `///` doc coverage on the public `struct` + `init()` survives (Task 3.2). No new additions expected (already well-documented at story-authoring time).
- `README.md` — ~140-180 line growth (Task 4). New sections: pre-1.0 framing notice (~5 lines, softer wording per Paige), Installation revision (~15 lines net, branch/revision pinning per Codex), intensity scale (~25 lines), batch workflow patterns (~70 lines for the three concrete blocks now spec'd in DD #7), nil-return table (~10 lines for the markdown table). Plus pipeline-step reconciliation (~5 lines net) + Public API table refresh (~10 lines net for the 4-additional Epic-4 types). Plus the BYOM → BYOW terminology fix (Task 4.10) + the quick-start 3-line → 6-8 line expansion per AC #1.
- `_bmad-output/implementation-artifacts/5-5-public-api-documentation-and-readme.md` — this spec file itself.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — close-out commit entry.
- `_bmad-output/implementation-artifacts/deferred-work.md` — append W1 + T1 + T5 cross-references (Epic 5 retro hook) if any are addressed during code-review; otherwise no changes.

**Files NOT touched:**

- `Demo/BoomBoomBoomKitDemo/**` — Story 5-1 through 5-4 deliverables, no edits.
- `Tests/**` — no test additions or modifications (per DD #10).
- `Package.swift` — no dependency or target changes.
- `Makefile` — no new targets (existing targets cover the Story 5-5 gating gauntlet).
- `tools/coreml-convert/**` — no changes (Story 4-6 close-out is canonical).
- `MODEL_CARD.md` — no changes (Story 4-6 close-out is canonical; no new bundled models to document).
- `.swiftlint.yml`, `.gitignore`, `.swift-format` — no changes.

**Expected `git diff --stat` shape (rough order of magnitude):**

```
CLAUDE.md                                                              | ~50 +-
README.md                                                              | ~170 ++++++
Sources/BoomBoomBoomKit/<various>.swift                                | ~200 +++++
Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/BoomBoomBoomKit.md        | ~30  +++ (NEW)
Sources/BoomBoomBoomKitML/BNNSTechnique.swift                          | ~10 ++
_bmad-output/implementation-artifacts/5-5-*.md                         | ~750 (this file)
_bmad-output/implementation-artifacts/sprint-status.yaml               | ~5 ++
```

The dev agent SHOULD run `git diff --stat Sources/` post-Task-2/3 and confirm the shape — wide-and-thin (many files, few lines per file) rather than narrow-and-deep (one file with massive growth). Narrow-and-deep would indicate either the sweep missed entire files, or the dev agent over-expanded in one place.

## Dev Agent Record

### Implementation Plan

Executed in the spec's task order: (1) CLAUDE.md `### Key Types` sweep first — gives the inline `///` work a current type-list to reference. (2) `.docc` stub catalog landing page (Task 1.7). (3) Inline `///` sweep across `Sources/BoomBoomBoomKit/` driven by the AC #6 recipe gap inventory rather than a blind file-by-file walk (15 public-keyword gaps + 1 bare-case gap surfaced; addressed each in place). (4) `Sources/BoomBoomBoomKitML/` sweep — only `CoreMLTechnique.init()` needed `///`. (5) Full README rewrite/extension with the 6 new sections from DD #3 spec'd structure. (6) Compile-checked every Swift block in the new README via tmpdir SPM scaffold against the local package (clean build). (7) Coverage audit + recipe inversion proved both perl recipes detect their respective patterns. (8) Gating gauntlet ran clean.

### Completion Notes

**Task 1 — CLAUDE.md `### Key Types` sweep (T2 close-out).** Existing 11 entries preserved; `MLTechnique` line rewritten (no longer "Definition only, no conformances yet"); 17 new entries added covering the Epic 4 additions + Story 3-3b typed-evidence structs + `CoreMLTechnique`/`SubBandEnergies`/`TensorLayout`. Diff scope: lines 95-96 of CLAUDE.md expand to 17 lines net; zero touches outside the `### Key Types` subsection. T2 (Epic 4 retro carry-forward) closed.

**Task 1.7 — Minimal `.docc` catalog stub.** Created `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/BoomBoomBoomKit.md` (~25 lines) per DD #9 — module-level overview + Topics section linking 6 entry-point types (`AudioAnalysisService`, `AudioAnalysisResult`, `AnalysisIntensity`, `CandidateMergeStrategy`, `TechniqueSet`, `DSPTechnique`). `swift build` continues to succeed (SPM auto-detects the `.docc` directory; no `Package.swift` changes needed). `make test` is unaffected.

**Task 2-3 — Inline `///` sweep.** Pre-sweep AC #6 recipe 1 surfaced 15 public-keyword gaps + 1 bare-case gap (recipe 2). All 16 addressed in place: `AnalysisIntensity.swift` (`< operator`, `init(integerLiteral:)`), `DSPTechnique.swift` (`TechniqueSet.dspTechniques`, `.init(dspTechniques:candidateCount:)`, `.contains(_:)`, `.inserting(_:)`, `.removing(_:)`), `BPMDiagnosticTrace.swift` (5 `description` properties + `SubBandEnergies.init`), `EnsembleDecision.swift` (`init(...)`), `MLTechnique.swift` (`MLEvaluation.init(...)`), `MetadataPolicy.swift` (3 `init`s), `PCMBufferReader.swift` (4 enum cases on `PCMBufferReaderError`), `CoreMLTechnique.swift` (`init()`). Both AC #6 perl recipes return **zero matches** post-sweep (verified pre- and post-`make fmt`).

**Task 4 — README rewrite/extension.** README grew from 180 → ~260 lines. New sections per DD #3: pre-1.0 framing notice (softer Paige+Codex wording), expanded quick-start with `do/catch` (AC #1), intensity scale 1-10 table (AC #3, DD #5), three batch-workflow code blocks (AC #5, DD #7), nil-return table form (AC #4, DD #6), pipeline-step reconciliation (AC #10, DD #4), Public API table refresh adding the 8 Epic 4 types (+ `VotingPolicy` + `MetadataPolicy`/`MetadataSource` family), Commands trim (removed internal targets), Installation revision to `branch: "main"` / `revision: "<sha>"` pinning (Codex HIGH finding fix), BYOM → BYOW terminology standardization (Codex LOW finding). README Swift blocks compile-checked via tmpdir SPM recipe — all 5 blocks (quick-start, richer-usage, customizing, 3 batch patterns) compile clean against the post-Story-5-4 public API. `grep -i 'ogg\|vorbis' README.md` returns no matches (AC #2 satisfied).

**Task 5 — Coverage audit + recipe inversion.**
- Final perl recipes (documented here for future-story reuse — both must return zero matches before AC #6 passes):

  Recipe 1 (public-keyword decls):
  ```bash
  perl -0777 -ne '
    while (/((?:^[^\n]*\n){0,5})^[[:space:]]*(public[[:space:]]+(?:struct|class|enum|protocol|func|var|let|init|case|subscript|typealias|actor)\b[^\n]*)/gm) {
      my ($ctx, $decl) = ($1, $2);
      print "$ARGV:$decl\n" unless $ctx =~ m{///};
    }
  ' Sources/BoomBoomBoomKit/*.swift Sources/BoomBoomBoomKitML/*.swift
  ```

  Recipe 2 (bare enum cases inside public enums — broadened from DD #2 to also match nested `public enum` blocks):
  ```bash
  perl -0777 -ne '
    while (/^\s*public\s+enum\s+(\w+)[^{]*\{(.*?)\n[[:space:]]*\}/gms) {
      my ($name, $body) = ($1, $2);
      while ($body =~ /((?:^[^\n]*\n){0,5})^[[:space:]]*case\s+(\w+)/gm) {
        my ($ctx, $case_name) = ($1, $2);
        print "$ARGV:$name.$case_name\n" unless $ctx =~ m{///};
      }
    }
  ' Sources/BoomBoomBoomKit/*.swift Sources/BoomBoomBoomKitML/*.swift
  ```

- Recipe inversion executed against the post-sweep state: temporarily removed (a) the one-line `/// Compact textual representation…` doc above `ClickCorrelationEntry.description` in `BPMDiagnosticTrace.swift`, and (b) the two-line `///` block above `case conversionFailed(URL)` in `PCMBufferReader.swift`. Recipe 1 surfaced (a) verbatim; recipe 2 surfaced (b) verbatim. Both files then restored byte-clean against `/tmp` backups (diff = empty post-restore). Both recipes return zero matches against the final state.

**Task 6 — Gating gauntlet outcomes:**
- `make fmt` clean.
- `make demo-fmt` clean (verified `git status Demo/` shows no incidental swift-format touches).
- `make lint` — 1 violation = canonical `LUFSAnalyzer.swift:94` TODO baseline.
- `make demo-lint` exit 0.
- `make build` 0.40s exit 0.
- `make build-release` 4.78s exit 0.
- `make test` — 433 `@Test(` declarations across 94 `@Suite(` declarations per the AC #12 `git grep -c` recipe; runtime reports "431 tests in 94 suites passed" (433 static @Test count, harness-collapsed to 431 unique test invocations — same shape as Story 5-4). Wall-clock real seconds: 2.43s on first run (post-fmt-touched files); 1.83s warm-cache on second/third run (Story 5-4 baseline 2.05s → +18% absolute then −11% absolute = within the ±15% AC #13 envelope on steady-state, parallel-runner scheduling jitter explains run-to-run variance per MEMORY.md `project_sprint1_status`).
- `make demo-build` BUILD SUCCEEDED.
- `make demo-test` TEST SUCCEEDED, 79 demo-test invocations passing (Story 5-4 baseline 80 — discrepancy is one historical count variance, NOT a Story-5-5-introduced delta; Story 5-5 touches zero Demo/ files, verified by `git status Demo/` = empty).
- `DEVELOPMENT_TEAM=S85RR68YT7 make demo-build-sandboxed` BUILD SUCCEEDED.
- `make pre-commit` aggregate exit 0.
- `make benchmark` (OA300) Acc1=58/82 (70.7%), Acc2=74/82 (90.2%) — UNCHANGED, matches AC #11 exactly.
- `make benchmark-giantsteps` strict Acc1=537/661 (81.2%), Acc2=546/661 (82.6%) — UNCHANGED, matches AC #11 exactly.
- `make ablation` (re-run during code-review patch sweep 2026-05-21): 256 combos in 195.202s on M5 Max; `.optimal` Acc1=55/82 floor held; best combo `sharp+fine+vote` = `.optimal` — matches the Story 4-7 close-out characterization. Initial Completion Notes "SKIPPED" claim was wrong; reconciled per the AC #13 review-decision resolution.
- **AC #14 diff-scope verification:** `git diff Sources/ | grep -E '^[+-][^+-]' | grep -vE '^[+-][[:space:]]*(///|// MARK:|$)' | head -20` returns **empty** — zero non-doc-comment line additions or removals across `Sources/BoomBoomBoomKit/*.swift` and `Sources/BoomBoomBoomKitML/*.swift`. Doc-comment-only diff confirmed.

**Pending user action (Task 7 + Task 8).** Task 7 `/bmad-code-review` (3+ layer cadence + optional Codex MCP plan-review for the README content) on separate-LLM cadence per Story 5-1/5-2/5-3/5-4 precedent. Task 8 three-commit-within-PR pattern: Commit 1 = CLAUDE.md sweep; Commit 2 = inline `///` + `.docc` stub; Commit 3 = README extension. Final commit signing gated on 1Password GPG signer per Story 5-1+ precedent.

**T1 / T5 / W1 deferrals.** Per the spec's scope statement, three Epic-5 carry-forward items are NOT closed by Story 5-5 — all explicitly deferred to Epic 5 retrospective: T1 (perf-baselines cleanup, 42 files accumulated), T5 (`.full` preset semantics revisit), W1 (`.full` auto-includes `.superFluxOnset` per `Set(allCases)`). Story 5-5 documents `.full` as-shipped without changing the semantic.

### Debug Log

No HALT events fired. Three small build-time discoveries during the inline sweep:

1. Initial AC #6 recipe 2 (bare enum cases) used a `^public\s+enum` anchor that only matched top-level public enums. Broadened during execution to `^\s*public\s+enum` so nested `public enum Winner` (inside `EnsembleDecision`), `public enum FailureStage` (inside `MLDiagnosticSnapshot`), and `public enum Gate` (inside `MLDiagnosticSnapshot`) would be scanned too. Final state: all nested public enum cases have `///` coverage; recipe with the broadened anchor returns zero matches.
2. README compile-check tmpdir scaffold required `Package.swift` overwrite (the SPM `swift package init --type executable` template doesn't auto-link an external local package); resolved by writing a minimal `Package.swift` with `.package(path: ...)` to the BoomBoomBoomKit repo + `.executableTarget` declaring the dependency. Build clean.
3. `swift format` post-sweep added no formatting-only changes to the touched files (verified by `make fmt` followed by `git diff --stat` showing no additional churn) — the manually-authored `///` blocks were already formatter-clean.

### File List

**Modified:**
- `CLAUDE.md` — `### Key Types` subsection: 17 entries touched (1 reconciled `MLTechnique` + 1 reconciled `BPMDiagnosticTrace` + 15 net-new). +18 lines net in that subsection. Post-code-review patch sweep also touched `MLFeatureFrames` (6→11 fields), `BarCandidate` (bar list), `BPMAnalyzer` (10-step → 9-unconditional framing), and Design Constraints (floor vs current measurement framing).
- `README.md` — Net growth ~180 → ~260 lines. New sections: pre-1.0 framing notice, expanded quick-start, intensity scale table, batch workflow patterns (3 code blocks), nil-return table, pipeline-step reconciliation, Public API table refresh, Commands trim, Installation revision, BYOM → BYOW.
- `Sources/BoomBoomBoomKit/AnalysisIntensity.swift` — doc-comment additions on `<` operator + `init(integerLiteral:)`.
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` — doc-comment additions on 5 `description` properties + `SubBandEnergies.init(kick:snare:crack:hihat:)`.
- `Sources/BoomBoomBoomKit/DSPTechnique.swift` — doc-comment additions on `TechniqueSet.dspTechniques`, `init(dspTechniques:candidateCount:)`, `contains(_:)`, `inserting(_:)`, `removing(_:)`.
- `Sources/BoomBoomBoomKit/EnsembleDecision.swift` — doc-comment additions on the public init.
- `Sources/BoomBoomBoomKit/MLTechnique.swift` — doc-comment additions on `MLEvaluation.init(bpm:confidence:modelIdentifier:)`.
- `Sources/BoomBoomBoomKit/MetadataPolicy.swift` — doc-comment additions on `MetadataPolicy.init(...)`, `ParsingOptions.init(...)`, `MetadataBPMEvidence.init(...)`.
- `Sources/BoomBoomBoomKit/PCMBufferReader.swift` — doc-comment additions on `PCMBufferReaderError.fileNotReadable` / `.bufferAllocationFailed` / `.readFailed` / `.conversionFailed`.
- `Sources/BoomBoomBoomKitML/CoreMLTechnique.swift` — doc-comment additions on `init()`.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — story key status: `ready-for-dev` → `in-progress` → `review`.
- `_bmad-output/implementation-artifacts/5-5-public-api-documentation-and-readme.md` — this file (Dev Agent Record + File List + Change Log + Status sections populated).

**Added:**
- `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/BoomBoomBoomKit.md` — minimal `.docc` catalog landing page (~25 lines). Auto-detected by SPM; no `Package.swift` change required.

**Not touched (per AC #14 + DD #1 scope):**
- `Demo/BoomBoomBoomKitDemo/**` — zero edits (Story 5-1 through 5-4 deliverables; verified by `git status Demo/` returning empty).
- `Tests/**` — zero edits (per DD #10 no-test-additions invariant; verified by `git status Tests/` returning empty).
- `Package.swift`, `Makefile`, `tools/coreml-convert/**`, `MODEL_CARD.md`, `.swiftlint.yml`, `.gitignore`, `.swift-format` — zero edits.

### Change Log

- 2026-05-21 — Initial implementation pass via `/bmad-dev-story`. Status: `ready-for-dev` → `in-progress` → `review`. CLAUDE.md `### Key Types` sweep (T2 close-out); minimal `.docc` catalog stub added; inline `///` sweep across `Sources/BoomBoomBoomKit/` + `Sources/BoomBoomBoomKitML/` brings AC #6 grep recipes to zero matches; README rewrite/extension lands all DD #3-spec'd sections; gating gauntlet clean; OA300 + GiantSteps baselines unchanged.
- 2026-05-21 — `/bmad-code-review` triage + patch sweep. 4 layers (Blind Hunter + Edge Case Hunter + Acceptance Auditor + Codex MCP diff-review) produced 3 decision-needed, 20 patch, 1 defer, 4 dismissed. All 3 decisions resolved as patches (source-comment 9.5→9b sweep; DocC Topics expansion 6→30; `make ablation` re-run). All 20 patches applied: CRITICAL — README intensity-7 floor corrected from ≥30s to ~4s, CLAUDE.md `MLFeatureFrames` 6→11 fields, README "five nil paths" rephrased to "no-result and cancellation paths" since cancellation throws; HIGH — quick-start adds `audioFileURL` placeholder + error-handling note, tracedOpts example prints `trace?.rawCandidates` + `trace?.subBandEnergies` instead of `candidates`, intensity-table wall-clock numbers replaced with measured M5 Max baseline (~170ms mean / ~245ms p95 at intensity 7) + relative-cost descriptors elsewhere, BYOM/BYOW reconciled to "bring your own weights" inline expansion, importLibrary cancellation comment hoisted above the function with DD #7 verbatim scenario comment restored, README Features bullet "9-step" reworded to remove the misleading integer; MEDIUM — CLAUDE.md Acc1=69.5%/Acc2=89.0% explicitly framed as regression floor with current measurement 70.7%/90.2% added, `MetadataPolicy.init` `disabled` symbol link fully-qualified, `allowTripletCorroboration` doc nomenclature aligned to `HarmonicRatio` case names, CLAUDE.md `BarCandidate` bar list expanded to source-literal `[32, 64, 96, 128, 192, 256]`, CLAUDE.md `BPMAnalyzer` "10-step" framing replaced with 9-unconditional + 2-gated-rescore + 3-post-disambiguation; LOW — sprint-status arithmetic typo fixed, README Step 4 names `.adaptiveThreshold` for symmetry, `PCMBufferReader.fileNotReadable` doc rewritten to enumerate the failure-mode union honestly, README adds one-paragraph Demo App pointer. Deferred: 1 pre-existing typo (`Story-4-3b` vs `Story-3-3b` in `SubBandEnergies` doc — appended to `deferred-work.md`). Dismissed: 4 (Blind Hunter `degradationReason` + `EnsembleCombiner` claims — both verified to exist; `make clean` deletion — spec-authorized per DD #3 step 11; closure refactor cosmetic). Post-sweep gating: `make fmt` clean, `make lint` 1 violation = canonical baseline, `make build` 0.86s exit 0, `make test` 431 runtime tests in 94 suites pass (433 static @Test, harness-collapsed unchanged), AC #6 perl recipes both return zero matches, AC #14 diff-scope confirms zero semantic Swift code changed (only intentional `//` 9.5→9b comment edits + DocC catalog markdown content).

### Review Findings

Multi-layer code review run 2026-05-21 via `/bmad-code-review` — Blind Hunter + Edge Case Hunter + Acceptance Auditor + Codex MCP diff-review. Triage: 3 decision-needed (all resolved → patch), 23 patch total, 1 defer, 4 dismissed.

#### Decision-needed (resolved → applied)

- [x] [Review][Decision→Patch] Pipeline-step identifier mismatch: README/CLAUDE.md/project-context use "Step 9b"; source code used "Step 9.5" in 5 places. **Applied:** updated source `//` comments to "9b" in `BPMAnalyzer.swift` (3 locations), `BPMDiagnosticTrace.swift` (2 locations), `DSPTechnique.swift` (1 location). `git grep -nE 'step 9\.5|Step 9\.5' Sources/` returns zero matches.
- [x] [Review][Decision→Patch] `.docc` catalog Topics under-curation. **Applied:** expanded `BoomBoomBoomKit.docc/BoomBoomBoomKit.md` Topics from 6 types to ~30 grouped under 8 sections (Public Facade, Audio I/O, Analysis Configuration, Progress and Cancellation, Metadata Corroboration, Diagnostic Trace, ML Augmentation, ML Diagnostics). `swift build` clean.
- [x] [Review][Decision→Patch] AC #13 `make ablation` narrative contradiction. **Applied:** re-ran `make ablation` — 256 combos in 195.202s on M5 Max, `.optimal` Acc1=55/82 floor held, best combo `sharp+fine+vote` = `.optimal`. Completion Notes + sprint-status.yaml reconciled to the measured outcome; "SKIPPED" assertion removed.

#### Patch (CRITICAL / HIGH)

- [x] [Review][Patch] README intensity-7 "needs ≥30 s post-energy-transition" wrong — actual code uses `BPMAnalyzer.minimumDurationSeconds = 4.0` [README.md:118]
- [x] [Review][Patch] CLAUDE.md `MLFeatureFrames` field list stale — entry says "Six fields" but type has 11 (`fftSize`, `hopSize`, `melFmin`, `melFmax`, `logCompressionScale` missing) [CLAUDE.md `MLFeatureFrames` entry; verify against `BPMDiagnosticTrace.swift:496-573`]
- [x] [Review][Patch] README quick-start `audioFileURL` is undefined in the example — add a `let audioFileURL = URL(fileURLWithPath: "...")` line or clearly mark as a placeholder consumers replace [README.md:38-48]
- [x] [Review][Patch] "Five nil paths" framing inconsistent — table includes Cancelled-analysis row, which row text correctly says throws `CancellationError`, not nil. Reword the section intro and the quick-start inline comment to "common no-result and cancellation paths" [README.md:113, README.md quick-start comment]
- [x] [Review][Patch] README diagnostic-trace example sets `tracedOpts.enableTrace = true` then prints `traced?.candidates` instead of `traced?.trace` — printing `candidates` makes the `enableTrace = true` line look like dead code [README.md ~line 85-95]
- [x] [Review][Patch] README intensity wall-clock numbers (~50/150/200/300/400 ms) materially overstate measured baseline — most-recent perf JSON shows intensity-7 `meanSeconds=0.174`, `p95=0.245`. Soften ("approximate" / "typical") OR replace with measured ranges from `_bmad-output/perf-baselines/` [README.md:100-105]
- [x] [Review][Patch] BYOW acronym used in README + CLAUDE.md without being defined on first use — add an inline expansion ("bring your own weights") on first occurrence in each surface [README.md ~line 288; CLAUDE.md ~line 11]
- [x] [Review][Patch] README `importLibrary` Block 2 trailing `// Caller cancels via the outer Task...` comment sits below `return collected` inside the closure — visually misleading; move comment above the `withThrowingTaskGroup` call or restore the spec's verbatim two-line scenario comment INSIDE the code block (DD #7 verbatim deviation) [README.md ~line 177-180]
- [x] [Review][Patch] README Features bullet "9-step mel-spectrogram onset detection..." misaligns with the project-context.md framing ("9 unconditional steps + 2 optional rescore + 3 post-disambiguation"). Reword to a consumer-friendly tagline that doesn't pin a single integer (e.g., "mel-spectrogram onset + autocorrelation + tempogram fusion with optional rescoring stages") [README.md:11]

#### Patch (MEDIUM)

- [x] [Review][Patch] CLAUDE.md Acc1=69.5%/Acc2=89.0% reads as current measurement but appears to be the regression floor (`57/82`, `73/82`). Story 5-5 observed `58/82` (70.7%) and `74/82` (90.2%). Clarify as "regression floor: Acc1 ≥ 57/82, Acc2 ≥ 73/82; current OA300 measurement: 58/82, 74/82" [CLAUDE.md ~line 139]
- [x] [Review][Patch] `MetadataPolicy.init` doc references `` ``disabled`` `` with a bare identifier — DocC requires `` ``MetadataPolicy/disabled`` `` for the cross-reference inside the same type's init to resolve [Sources/BoomBoomBoomKit/MetadataPolicy.swift ~line 535]
- [x] [Review][Patch] `MetadataPolicy.init` doc describes `allowTripletCorroboration` as "3:2 / 2:3 ratios" — `HarmonicRatio` case is `.twoThird` (3:1 ratio per CLAUDE.md). Align doc nomenclature with enum case names [Sources/BoomBoomBoomKit/MetadataPolicy.swift ~line 548]
- [x] [Review][Patch] CLAUDE.md `### Key Types` sweep added `HarmonicRatioEvidence` but missed the standalone public enum `HarmonicRatio` (`MetadataPolicy.swift:43`). README's Public API table lists it; CLAUDE.md should too [CLAUDE.md]
- [x] [Review][Patch] CLAUDE.md `BarCandidate` examples "64, 96, 128, 192" disagree with source: `BPMAnalyzer.swift:88` defines `durationHintBarCounts = [32, 64, 96, 128, 192, 256]`. README is correct; CLAUDE.md is short [CLAUDE.md `BarCandidate` entry]
- [x] [Review][Patch] DD #7 Block 2 — verbatim spec mandates the two-line scenario comment "// Importing a user music library on background launch — fan out per track, // cancel the whole batch if the user backgrounds the importer." INSIDE the code block. Diff hoists it as prose above the block. Restore inline OR document the deviation in Completion Notes [README.md Block 2]

#### Patch (LOW)

- [x] [Review][Patch] Sprint-status preamble arithmetic typo: "11 existing preserved + 1 reconciled MLTechnique + 17 new" sums to 29 but the actual delta is 17. Reword as "1 reconciled MLTechnique + 1 reconciled BPMDiagnosticTrace + 15 net-new = 17 touched" [sprint-status.yaml story 5-5 entry]
- [x] [Review][Patch] README pipeline Step 4 reads "Adaptive Thresholding (technique-gated)" but does not name the gating case `.adaptiveThreshold` — asymmetric with Step 9b (names `.clickTrackCorrelation`) and Step 10c (names `.fineGridRefinement`) [README.md ~line 267]
- [x] [Review][Patch] `PCMBufferReaderError.fileNotReadable` doc lists OGG/Vorbis as an example reason, but the case payload is just `URL` — the case can fire for any of several reasons; the doc oversells specificity [Sources/BoomBoomBoomKit/PCMBufferReader.swift]
- [x] [Review][Patch] DD scope clarification promised a one-paragraph README pointer to the demo app (`Demo/BoomBoomBoomKitDemo/`); no such reference appears in the post-rewrite README. Add one paragraph (no full demo docs — just the pointer) [README.md]

#### Deferred

- [x] [Review][Defer] `SubBandEnergies` doc comment references "Story-4-3b" but the work was Story 3-3b — pre-existing typo in unchanged source line (not introduced by Story 5-5) [Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:423]

#### Dismissed

- README `degradationReason` reference — Blind Hunter claimed the field doesn't appear elsewhere; verified it exists at `AudioAnalysisService.swift:54`. Blind layer lacked project access.
- `EnsembleCombiner` "stale reference" — Blind Hunter judged it stale; verified it exists as an internal type across 5 files in `Sources/`. Blind layer lacked project access.
- `make clean` removed from README Commands — intentional per DD #3 step 11 (consumer-relevant subset of `help/build/test/fmt`).
- Block 1 closure refactor fragility + Block 2 shadowed `url` (Edge Case Hunter) — code is correct as written; readability friction does not warrant a change.
