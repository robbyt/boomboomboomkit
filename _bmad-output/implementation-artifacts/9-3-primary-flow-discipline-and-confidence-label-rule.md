---
baseline_commit: 8856dcdc3e94efcad224d1fa190e7d5a78201125
---

# Story 9.3: Primary-flow discipline + confidence-label rule

Status: done

## Story

As a consumer evaluating the demo,
I want the demo to keep "drop file → get answer" as the dominant interaction and never display a bare numeric value for any confidence-like quantity,
so that the primary flow stays uncluttered for end-user evaluation while developer affordances stay one keystroke away in the sidebar, and so that no number ever appears without a label telling me what kind of confidence it represents.

## Context & why this story exists

Third and final story of Epic 9 (FR-43, FR-44; no KDD — a cross-cutting rule Epic 10 inherits). It ships the **confidence-label CI gate** and the FR-43 **no-dev-diagnostic-leak** discipline as an enforceable, inheritable rule rather than a one-off cleanup. Branches off the post-9.2 `rterhaar/epic-9` (commit `8856dcd`); epic-9 lands as a second squash (9.2 + 9.3).

**This is a demo-only story**: `git diff --stat Sources/ Tests/` must be empty at close-out. It ships one new shell script + one `Makefile` wiring line + a one-line label refinement.

**Grounding fact that shapes the whole story (verified 2026-07-03):** the demo is ALREADY FR-44-clean — the proposed audit regex returns **0 matches** on the current `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/`. Every confidence-like value is already labeled: `LabeledContent("Confidence"/"Softmax max"/"Winner score")` (TraceView), `"DSP vote: \(…)"` / column headers (SignalPoolDiagnosticTable, Story 9.2), `"Confidence: \(row.confidence)"` (ContentView primary result — a preformatted `String`, `AnalysisViewModel.swift:138/839`). So this story is a **forward gate + a label-specificity refinement**, not a bare-numeric cleanup.

## Key Design Decisions (DD)

1. **DD1 — The `Parameters` GroupBox (including the pre-existing BYOW `Load Model…` button) STAYS in the primary view; AC1's enforceable clause is the no-dev-diagnostic-leak list (recorded decision).** AC1 says the empty-launch primary view shows "only the drop zone, the `EnsemblePresetPicker`, and a placeholder result region." Taken literally, the existing `GroupBox("Parameters")` (`ContentView.swift:273` — intensity, maxSeconds, lock-to-BPM, merge strategy, the BYOW `Button("Load Model…")` at `:355`, action buttons) also renders in the primary view. **Interpretation:** AC1's forbidden clause reads "no diagnostic-table preview, no raw-weights controls, no model-picker affordance leak **from the (Epic 10) sidebar surface**." The intensity/merge-strategy controls are visible end-user evaluation knobs (shipped since Story 5-x), not "hidden parameters." **The BYOW `Load Model…` button (Codex flag): it IS a model-loading affordance in the primary view — but it is the Epic-7 bring-your-own-weights control, NOT the "(Epic 10) sidebar surface" model-picker (`ModelPickerView`, Story 10.1) that AC1's parenthetical names.** AC1 forbids the *future Epic 10 registry picker* from leaking into primary; the pre-existing Epic-7 BYOW load button is grandfathered. Recorded explicitly (not glossed) — flag at PR: if the operator wants the BYOW load control moved to the inspector too, that is a small follow-up, but it is a deliberate deviation call, not a silent one. Relocating the whole `Parameters` box is out of scope (Epic 10 layout territory).

2. **DD2 — `confidence-label-audit.sh` is a NON-VACUOUS forward gate, wired into `make demo-lint` by APPENDING to the existing `DEVELOPMENT_TEAM` guard (not replacing it).** The script (`Demo/BoomBoomBoomBPM/scripts/confidence-label-audit.sh`, ships to develop — Demo/) fails the build (`exit 1`) on any real match. It carries a **self-test**: it first asserts the regex FIRES on a known-bad snippet (both a `Text("\(row.confidence)")` and a `secondaryMetadataRow("\(row.confidence)")` form) and aborts (`exit 2`) if it no longer does — so the gate can never silently become vacuous. **Shell correctness (Codex):** under `set -euo pipefail`, a naked `grep` that finds nothing exits `1` and would wrongly fail the build — the real scan MUST use the `if grep -rnE "$PATTERN" …; then …; exit 1; fi` shape (grep's no-match `1` becomes the passing branch), never a bare `grep` as the last command. `exit 2` (gate broken) and `exit 1` (violation found) both fail `make demo-lint` while preserving diagnosis. The `demo-lint` recipe gains a second step invoking the script after the pbxproj `DEVELOPMENT_TEAM` grep; both must pass.

3. **DD3 — The audit matches a bare-interpolation STRING LITERAL of a confidence-like value, wrapper-agnostic (revised after Codex: the original `Text\(`-anchored regex missed the demo's own `secondaryMetadataRow(...)` wrapper).** The primary confidence render funnels through `secondaryMetadataRow(_:)` → `Text(value)` (`ContentView.swift:548`), so anchoring on `Text\(` would be blind to the exact call site being guarded. Pattern (drop the `Text\(` prefix — match the string anywhere): `"\\\([^"]*([Cc]onfidence|[Ww]eight|[Ss]oftmax|reliability|[Ss]core|[Ee]ffectiveVote|[Vv]ote)[^"]*\)"` — a double-quoted string that STARTS with `\(`, contains a confidence-like token, and closes `)"` (a PURE interpolation, no label). This catches `Text("\(x.confidence)")` AND `secondaryMetadataRow("\(x.confidence)")` AND any other wrapper, while NOT flagging `"BPM confidence: \(x)"` (starts with `B`), `"\(x.confidence) more"` (does not close `)"`), `LabeledContent("Confidence"){…}`, `Text(row.bpm)`, or `Text(row.confidenceDisplay)` (no string literal). Verified: **0 matches** on the current demo. **Documented limitation (Codex):** the regex is a FORWARD GUARD for the common bare-interpolation anti-pattern, NOT a completeness proof of FR-44 — it does not catch a label-less `Text(String(format: "%.2f", x.confidence))` or an unlabeled `monoFloat(x.confidence,…)` (the confidence lives in the argument, not the string). Those are covered by the verified render inventory (all current `String(format:)`/`monoFloat` confidence renders sit inside a `LabeledContent`) + review, not grep; a grep that tried to parse `String(format:)` label-adjacency would be the brittle case the pressure-release valve exists for.

4. **DD4 — Pressure-release valve NOT triggered; document the non-deviation, do not downgrade.** The AC's valve ("if the regex set proves too brittle, downgrade to a SwiftLint custom rule + document in `9-3-pressure-release.md`") is conditional on brittleness. The regex is clean and low-false-positive on the real demo, so the primary regex gate ships as-is with NO SwiftLint downgrade. Per the AC's intent to record the outcome, the spec's Completion Notes state the valve was not needed; no separate `9-3-pressure-release.md` is created (the AC scopes that file to the deviation case, which did not occur).

5. **DD5 — Label specificity: `ContentView.swift:532` `"Confidence:"` → `"BPM confidence:"` + the Epic-11 seam.** FR-44 wants the label to say WHICH confidence; the AC example is `BPM confidence: 0.78`. The primary result's `secondaryMetadataRow("Confidence: \(row.confidence)")` is already labeled + formatted (`row.confidence` is `"78%"`), but the label is generic. Relabel to `"BPM confidence: \(row.confidence)"` and mark it `// TODO(Epic 11): align with KDD-E8 style guide` (placeholder-vocabulary seam per the AC). **Beat-grid confidence** (`BeatGridView.swift:391` `LabeledContent("Confidence")` inside `GroupBox("Beat grid")`) is contextually labeled and is explicitly Epic-10-owned per the AC ("future beat-grid confidence inherited by Epic 10") — left as-is, noted as Epic-10-deferred, NOT relabeled here.

6. **DD6 — FR-43 no-leak is a regression TRIPWIRE (not complete enforcement) via a grep in the same audit script; presentation-only + state-retention are satisfied by construction.** The script asserts `SignalPoolDiagnosticTable` is referenced ONLY in the sidebar (`TraceView.swift`), never in `ContentView.swift` — a concrete guard against the Story-9.2 table leaking into the primary flow. **Acknowledged scope (Codex):** this is a targeted tripwire; it would NOT catch other hypothetical FR-43 leaks (a directly-embedded `TraceView`, ad-hoc `signalParticipationTrace`/`ensembleWeightResolution` summaries, or a future differently-named diagnostic view in `ContentView`). It pins the one diagnostic surface that exists today; broader enforcement is review + the cross-cutting rule Epic 10 inherits (AC7). AC2 (⌘⇧D carries dev affordances) and AC3 (closing the sidebar is presentation-only, retains file/preset/BPM/label) are already structurally true — the inspector is a pure `.inspector(isPresented:)` toggle (`ContentView.swift:126-146`) that mutates no analysis state; no code change needed, verified by inspection.

## Acceptance Criteria

1. **Primary launch state (FR-43).** On launch with no file dropped, the primary view shows the drop zone (`EmptyStateView`), the `EnsemblePresetPicker` (`ensembleSection`), and a placeholder result region — and NO diagnostic-table preview, raw-weights control, or model-picker affordance. Verified by DD6's grep gate (`SignalPoolDiagnosticTable` absent from `ContentView.swift`) + inspection; the `Parameters` GroupBox remains per DD1.

2. **Sidebar carries dev affordances (⌘⇧D).** The `.inspector(isPresented:)` toggle (Story 5-6b) carries the diagnostic table (Story 9.2) and future dev-tool extension points; unchanged from 9.2.

3. **Closing the sidebar is presentation-only.** Closing the inspector retains the current file, preset, BPM result, and confidence label — satisfied by construction (the toggle mutates no analysis state; `lastRunSnapshot`/`selectedEnsemblePreset`/result are independent of `inspectorPresented`).

4. **Confidence-label discipline (FR-44).** Every confidence-like quantity the demo displays carries an explicit label identifying its kind — no bare-numeric (`Text("\(value)")`) confidence call sites. The primary BPM confidence is relabeled `BPM confidence:` (DD5).

5. **CI grep gate.** `Demo/BoomBoomBoomBPM/scripts/confidence-label-audit.sh` runs as part of `make demo-lint`, self-tests that its regex fires on a known-bad snippet, and produces zero real matches on the demo; a bare-numeric confidence render fails the build.

6. **Epic-11 vocabulary seam.** Placeholder labels chosen here are marked `// TODO(Epic 11): align with KDD-E8 style guide`; exact label strings are deferred to Epic 11.

7. **Cross-cutting inheritance.** Epic 10 stories inherit the FR-44 audit + the ⌘⇧D sidebar convention from this story (they cite 9.3 rather than re-deriving) — documentation seam, not code.

8. **Demo-only diff scope.** `git diff --stat Sources/ Tests/` is empty; `make build` + `make test` pass unchanged; `make demo-build`/`demo-test` green.

## Out of scope (explicit)

- **Relocating the `Parameters` GroupBox** (intensity/merge-strategy/BYOW) to the sidebar (DD1 — recorded decision; Epic 10 layout territory if ever wanted).
- **Beat-grid confidence label specificity** (`BeatGridView.swift:391`) — Epic-10-owned per the AC; left contextually labeled.
- **Exact FR-44 label-string vocabulary** — Epic 11 / KDD-E8 (DD5 ships placeholders with the TODO seam).
- **Any library change** (`Sources/`, `Tests/`); the model picker (Epic 10); raw per-source weight controls (Epic 10 sidebar).
- **A SwiftLint custom rule for the audit** — the regex gate is clean, so the pressure-release downgrade is NOT taken (DD4).

## Tasks / Subtasks

- [x] **T1 — `confidence-label-audit.sh` (new) + `make demo-lint` wiring** (AC4, AC5, DD2/DD3/DD6)
  - [x] `Demo/BoomBoomBoomBPM/scripts/confidence-label-audit.sh` — `set -euo pipefail`; the DD3 bare-interpolation-confidence regex; a self-test that the regex FIRES on `Text("\(row.confidence)")` (abort `exit 2` if not — non-vacuous); the real audit over `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/` (`exit 1` on match with a fix hint); the DD6 FR-43 grep (`SignalPoolDiagnosticTable` must be absent from `ContentView.swift`); a `PASS` line. Executable (`chmod +x`).
  - [x] `Makefile` `demo-lint`: append a second step invoking the script after the existing `DEVELOPMENT_TEAM` pbxproj guard (both must pass; keep the guard intact).
- [x] **T2 — Confidence-label specificity** (AC4, AC6, DD5)
  - [x] `ContentView.swift:532`: `"Confidence: \(row.confidence)"` → `"BPM confidence: \(row.confidence)"` + `// TODO(Epic 11): align with KDD-E8 style guide`.
- [x] **T3 — Gauntlet + close-out** (AC5, AC8)
  - [x] `make demo-fmt`, `make demo-lint` (now runs the audit — confirm PASS + self-test fires), `make demo-build`, `make demo-test` — record in Completion Notes.
  - [x] `make build` + `make test` (library untouched); `git diff --stat Sources/ Tests/` empty (AC8).
  - [x] Manually corrupt one render to a bare `Text("\(row.confidence)")` and confirm `make demo-lint` FAILS (proves the gate is live), then revert.
  - [x] Diff hygiene: the untracked `14-1-daw-warp-anchors.generated.json` and `_bmad-output/party-mode/` must NOT enter this story's commits — stage paths explicitly.
  - [x] Story file Dev Agent Record + File List; sprint-status `backlog → ready-for-dev → in-progress → review`.

## Dev Notes

### Architecture & source tree (touch points, verified 2026-07-03 against the post-`8856dcd` tree)

- **NEW** `Demo/BoomBoomBoomBPM/scripts/confidence-label-audit.sh` — the FR-44 + FR-43 audit (develop-only; Demo/ ships via `make demo-archive`, never to main).
- **UPDATE** `Makefile` — `demo-lint` gains the audit invocation (after the `DEVELOPMENT_TEAM` guard).
- **UPDATE** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift` — one label string (`:532`) + the Epic-11 TODO.
- **NO CHANGE**: any Swift beyond the one label; `TraceView.swift`/`SignalPoolDiagnosticTable.swift` (already labeled — 9.2); `BeatGridView.swift` (Epic-10-deferred); `Sources/`/`Tests/`.

### Confidence-render inventory (verified — all already labeled)

- `ContentView.swift:532` `"Confidence: \(row.confidence)"` — labeled + formatted (`row.confidence` = `"78%"`, `AnalysisViewModel.swift:839`); relabeled for specificity (DD5).
- `TraceView.swift` — `LabeledContent("Confidence")` (:57), `LabeledContent("Winner score")` (:144), `LabeledContent("Softmax max"/"Softmax 2nd")` (:295/:300), inline `"score: %.3f"` (:106). All labeled.
- `SignalPoolDiagnosticTable.swift` (9.2) — `Confidence`/`Weight` column headers, `"DSP vote:"/"ML vote:"` summary. All labeled.
- `BeatGridView.swift:391` `LabeledContent("Confidence")` inside `GroupBox("Beat grid")` — contextually labeled; Epic-10-deferred.

### Reuse-first / constraints

- The audit is a shell gate (the "test" for this discipline story) — no SwiftUI view-inspection harness exists in the demo, so FR-43/44 are enforced by grep gates + the one label edit, not new Swift unit tests. Keep the gate NON-VACUOUS (the self-test).
- Demo stays on develop; ships via `make demo-archive`. No emojis; commit `Story 9-3: <deliverable>` + `Claude-Session:` trailer; operator signs.
- `make demo-lint` must keep the `DEVELOPMENT_TEAM` pbxproj guard working (append, do not replace).

### Previous Story Intelligence (PSI)

- **Story 9.2 (just done, `8856dcd`)**: the signal-pool table is the ONLY diagnostic surface added to the sidebar; the DD6 FR-43 grep pins it to `TraceView.swift`. The demo builds with MainActor default isolation (irrelevant here — no new Swift types).
- **9.1/9.2 recorded-decision precedent**: an AC whose literal wording over-reaches (here AC1's "only") is handled with a documented recorded decision (D1/DD1), not a silent deviation — flag at PR.
- **Commit hygiene**: keep `14-1-daw-warp-anchors.generated.json` + `_bmad-output/party-mode/` out (explicit-path staging).

### References

- epics.md `### Story 9.3` (lines 1318-1360) — ACs, the CI grep gate, the pressure-release valve, Epic-10 inheritance.
- prd.md FR-43 (`:169`), FR-44 (`:171`); architecture.md sidebar/`⌘⇧D` (`:318`).
- Makefile `demo-lint` (the `DEVELOPMENT_TEAM` guard this story extends).

## Dev Agent Record

### Agent Model Used

Claude Opus 4.8 (claude-opus-4-8), 2026-07-03 session, bmad-dev-story single-shot.

### Debug Log References

- Corrupt-test `rm -f` was rejected by the sandbox ("Un-recognized argument -f"); re-ran with plain `rm`. No impact on the deliverable — the probe file was transient and never staged.
- No compile/test reds: the only Swift change is a one-line label string; the audit is a shell gate exercised directly (self-test fires; planted bare render → exit 1; clean → PASS).

### Completion Notes List

- All 3 tasks complete; all 8 ACs satisfied. Demo-only: `git diff --stat Sources/ Tests/` empty; library `make build` clean + `make test` 842/138 (byte-identical baseline).
- `confidence-label-audit.sh` (NEW, executable): wrapper-agnostic bare-interpolation regex (catches `Text("\(x.confidence)")` AND `secondaryMetadataRow("\(x.confidence)")`), non-vacuous self-test on both forms (exit 2 if the regex stops firing), existence guards + explicit grep-status handling distinguishing violation (exit 1) / clean (pass) / grep-error (exit 3) so a missing path fails loudly instead of silently passing (code-review P1), `--include` before the path (P2), + the FR-43 instantiation tripwire (`SignalPoolDiagnosticTable(` absent from `ContentView.swift`, P3). PASS on the current demo (0 real matches).
- `Makefile` `demo-lint`: audit appended after the `DEVELOPMENT_TEAM` pbxproj guard (both must pass; guard intact); comment updated.
- `ContentView.swift:532`: `"Confidence:"` → `"BPM confidence:"` (FR-44 specificity) + `// TODO(Epic 11): align with KDD-E8 style guide` seam.
- Verified live (T3 corrupt-test): a planted `Text("\(row.confidence)")` made `demo-lint` FAIL exit 1; removing it restored PASS. Pressure-release valve NOT triggered (regex clean + low-false-positive) — no SwiftLint downgrade, no `9-3-pressure-release.md` (DD4).
- Gauntlet: `make demo-fmt` clean; `make demo-lint` PASS (audit self-test fires); `make demo-build` BUILD SUCCEEDED; `make demo-test` 0 failures; `make build`/`make test` 842/138. Diff scope demo-only.

### Pending user action (operator-owned)

- Recorded decision DD1 (BYOW `Load Model…` grandfathered in the primary view vs AC1's "(Epic 10) sidebar surface" model-picker wording) — sign off at PR, or request the BYOW control moved to the inspector as a small follow-up.
- 1Password-signed commit + `gh pr create` for the epic-9 branch (9-2 + 9-3).

### File List

- NEW `Demo/BoomBoomBoomBPM/scripts/confidence-label-audit.sh` — FR-44 confidence-label + FR-43 no-diagnostic-leak audit (self-testing shell gate).
- MODIFIED `Makefile` — `demo-lint` runs the audit after the `DEVELOPMENT_TEAM` guard.
- MODIFIED `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift` — primary confidence label `Confidence:` → `BPM confidence:` + Epic-11 TODO seam.
- MODIFIED `_bmad-output/implementation-artifacts/sprint-status.yaml` — status flips (9-3 ready-for-dev → in-progress → review).
- MODIFIED `_bmad-output/implementation-artifacts/9-3-primary-flow-discipline-and-confidence-label-rule.md` — this file.

## Review Findings (code review 2026-07-03 — Codex Blind Hunter, focused shell-gate pass)

Given the tiny surface (one shell gate + a Makefile line + a one-line label) and the pre-implementation Codex design review, the post-implementation review was a single focused adversarial pass on the audit script (the only non-trivial artifact). 8 findings → 3 patches applied + 2 documented limitations accepted.

### Patches (applied, all verified)

- **P1 (Codex HIGH ×2) — the gate no longer swallows `grep` errors as a pass.** The `if grep; then exit 1; fi` shape treated grep's error exit (≥2 — bad/missing path, unreadable dir) identically to no-match (1), so the audit would print `PASS` when it could not actually see the files (self-disabling). Fixed: existence guards on `$SRC` and `ContentView.swift` (exit 3 if missing), and explicit status capture (`set +e; …; status=$?; set -e`) distinguishing 0 (violation → exit 1), 1 (clean → pass), ≥2 (grep error → exit 3, fail loudly). Verified: running from a dir without the source tree now exits 3, not 0.
- **P2 (Codex MED) — `--include='*.swift'` moved BEFORE the search root** (portability across BSD/GNU grep; also avoids the error-swallow of P1).
- **P3 (Codex MED/LOW) — the FR-43 tripwire matches an INSTANTIATION** (`SignalPoolDiagnosticTable[[:space:]]*\(`), not a bare-name mention, so a comment referencing the type in `ContentView.swift` no longer trips the gate (the same class of false-positive that bit the 9.2 `ensembleDecision` grep).

### Accepted / documented limitations (in the script header + DD3)

- Regex false-negatives — a label-less `Text(String(format:...))`/`monoFloat(...)` (value in the argument, not the string), an inner-string-literal interpolation, and raw Swift strings (`#"...\#(...)..."#`) — are forward-guard blind spots covered by the render inventory + review, NOT grep (broadening to parse them is the brittle case the pressure-release valve exists for).
- A THEORETICAL false-positive on a label that FOLLOWS a leading interpolation (`"\(a) confidence: \(b)"`) — does not occur in the current demo (the shipped `"BPM confidence: \(x)"` starts with a letter and is correctly not matched). Documented; not worth the regex brittleness to pre-empt.

## Change Log

- 2026-07-03: Story spec created (bmad-create-story). Grounded by a direct audit of the demo's confidence renders (all already labeled; the FR-44 regex returns 0 matches today → forward gate) + the `demo-lint`/Makefile structure + the FR-43 primary-vs-sidebar composition. Every cited path/line re-verified against the post-`8856dcd` tree.
- 2026-07-03: Pre-implementation Codex review (thread `019f2968-f5a2-78b3-978b-30a599ef3d19`). Confirmed the self-test design (DD2), the `exit 2`/`exit 1` semantics, and that the regex does not false-positive on the labeled cases. Folded 3 fixes: **DD1** — named the pre-existing BYOW `Button("Load Model…")` (`ContentView.swift:355`) explicitly, grandfathered against AC1's "(Epic 10) sidebar surface" model-picker wording rather than glossing it (flag at PR); **DD3** — dropped the `Text\(` anchor so the regex is wrapper-agnostic and actually catches the demo's own `secondaryMetadataRow("\(…)")` primary-view pattern, and documented it as a forward guard (not an FR-44 completeness proof — `String(format:)`/`monoFloat` label-less renders are covered by inventory + review); **DD2** — pinned the `if grep …; then exit 1; fi` shape (a naked `grep` under `set -e` exits 1 on no-match and would wrongly fail). DD6 reframed as a targeted regression tripwire, not complete FR-43 enforcement.
- 2026-07-03: Implementation complete (bmad-dev-story; status ready-for-dev → in-progress → review). 1 NEW shell gate + 2 MODIFIED (Makefile, ContentView label). Audit PASS on the current demo; T3 corrupt-test proved it fails on a planted bare render (exit 1) and the self-test fires (exit 2 path reachable). Pressure-release valve not triggered. Library untouched (842/138); demo-build/test green.
- 2026-07-03: Code review complete (Codex Blind Hunter, focused shell-gate pass, thread `019f2977-5f69-71c1-b690-f1ae2291456e`). 8 findings → 3 patches (P1 HIGH×2 grep-error-swallow → existence guards + explicit 0/1/≥2 status handling, verified exit-3 on missing tree; P2 `--include` before path; P3 FR-43 grep matches instantiation not comment) + 2 accepted documented regex limitations. Post-patch: audit PASS + fail-loud-on-missing-path verified, demo-lint green, library untouched. Status review → done.
