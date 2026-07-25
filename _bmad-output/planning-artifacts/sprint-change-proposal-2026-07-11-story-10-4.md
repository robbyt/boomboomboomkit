# Sprint Change Proposal — Story 10.4 doc/code reconciliation (LUFS graph)

**Date:** 2026-07-11
**Author:** Developer (correct-course), prepped via party-mode round-table + Codex (`gpt-5.6-sol`) consult
**Trigger commit:** `d3af680eaf6a4ea65f433ca24d3eddc59edc7797` — "Story 10-4 UX rework: LUFS-over-time graph replaces the scalar loudness panel" (PR #96, branch `rterhaar/10-4`)
**Scope classification:** Moderate (retroactive doc reconciliation of a shipped operator-directed rework; no new code, no library change)

---

## Section 1 — Issue Summary

Story 10.4 shipped, but via an operator-directed UX rework that diverged from its written spec. The story was specified as a **scalar `LUFSReadoutView` panel** (a ≥2×-typography integrated-LUFS number with true-peak + loudness-range secondary rows in a subordinate `GroupBox`). What shipped (`d3af680` / PR #96) is a **`LoudnessGraphView`** — a LUFS-over-time `Canvas` plot (X = time, Y = loudness) of the momentary/short-term/integrated/true-peak/LRA series `LUFSReport` already carries — and the beat-grid + loudness panels were **merged into one `analysisSection` lane** behind a segmented **Beats | Loudness** switch. `LUFSReadoutView.swift` was deleted.

**How it was discovered:** during pre-merge review of PR #95's base branch. The rework commit touched the governing Story-10.4 spec by **exactly one appended changelog line** — the title, Story statement, all ACs, tasks, and DD4 still describe the deleted scalar panel. Every downstream planning artifact (epics.md FR-40 + the Story-10.4 AC block, architecture.md, the readiness report, epic-10-context, the 8-1 story, sprint-status) also still describes the scalar design.

**The deeper finding:** FR-40 itself is the stale artifact. FR-40 mandates "integrated LUFS as a single number + small panel." But **Story 8.1 DD#5 (operator direction, 2026-06-10, `epics.md:893`) already declared "integrated LUFS as a single number misdescribes dynamic material"** and shipped the momentary (400 ms) + short-term (3 s) loudness series + a chart adapter into the library **specifically to enable time-series rendering** — "shape proven by rendering through Swift Charts before spec freeze." FR-40 was internally contradicted by our own architecture a full month before Story 10.4 was written. The rework is drift *toward* the plan we already made (8.1), not away from it. FR-40 also shipped with no wireframe (the review rubric flagged it as "adjective drift — 'without dominating' is tone, not bounds"), which is the seam the rework fell through.

**Design decisions that SURVIVED the rework (still accurate):** DD1 (the demo carries no LUFS today → the story wires a best-effort `analyzeLUFS(url:)` call) and DD2 (true-peak is never nil; `loudnessRangeLU` is the sole optional field). The rework kept the `analyzeLUFS` wiring, the sentinel/optional handling, the four pure formatters, and the DD7 honest-window caption — moved verbatim onto `LoudnessGraphView`.

**Governance note (stated, not buried):** this is the **second** retroactive operator-rework correct-course in Epic 10 (Story 10-3's BeatGridTimelineView rework was the first). Both landed as operator-directed reworks reconciled after the fact. That is a deliberate operating mode for this repo, recorded here as a choice.

---

## Section 2 — Impact Analysis

### Epic Impact
- **Epic 10 (Demo integration — beat-grid, LUFS, model selection, per-case docs popovers).** Story 10.4 is the LUFS story; it now shares a lane with Story 10-3's beat grid. No new stories needed; no build-order change (`10.1 → 10.2 → 10.3 → 10.4 → 10.5`).
- **Epic 8 alignment restored.** The rework realizes the time-series rendering that Story 8.1 built the library series for; the correct-course makes FR-40 consistent with 8.1 DD#5.

### Story Impact
- **Story 10.4** — spec fully diverged from shipped code (title, Story, AC1–7, tasks, DD4, "What this is/is NOT", File List). Normative sections rewritten to the graph (Option A, below). DD1/DD2 retained verbatim. Status stays `done` (it IS shipped).
- **Story 10-3 (ripple)** — its blessed beat-grid lane is now behind the Beats|Loudness segment control. Reconciled with a one-line note in the 10-3 artifact + confirmation the epic's FR-39 entry already reflects the BeatGridView merge (`architecture.md:1237`).

### Artifact Conflicts (docs needing updates)
| Artifact | Conflict | Treatment |
|---|---|---|
| `epics.md` FR-40 (`:105`, `:249`) | Mandates "single number + small panel" | **Amend** to graph-compatible, superseded-by-8.1 framing |
| `epics.md` Story 10.4 block (`:1457–1481`) | Scalar ACs; names `LUFSReadoutView`; AC4 has the DD2 factual error ("true-peak unavailable") | **Rewrite** the ACs to the graph; fix the DD2 error |
| `epics.md:894` | Chart lands in "10.4 (`LUFSReadoutView`)"; cites the probe seed | **Amend** the symbol name; provenance-cite the seed |
| `architecture.md` (`:1098`, `:1237`) | File-tree + FR-40 → `LUFSReadoutView` | **Amend** to `LoudnessGraphView` |
| `epic-10-context.md:14` | "Story 10.4: LUFSReadoutView…" (compiled context cache) | **Amend** the one-liner |
| `sprint-status.yaml` (`:38` last_updated, `:315` key) | last_updated describes only the scalar panel | **Rewrite** last_updated; **keep** the `done` status + the historical key |
| `10-4-…-breakdown.md` (the story spec) | Entire normative body describes the scalar panel | **Rewrite in place (Option A)** — see Section 3 |
| `implementation-readiness-report-2026-05-27.md:307` | Lists `LUFSReadoutView.swift (FR-40)` | **Annotate only** (dated historical snapshot) |
| `8-1-…-promotion.md:38` | "Demo chart follow-up = 10-4 (`LUFSReadoutView`)" | **Annotate only** (dated story record) |
| `10-4-lufs-chart-probe.swift` (dead seed) | Unwired probe, no build target; matches the shipped graph better than the scalar spec did | **Delete file**, cite provenance `732e59c` (22 Jun) |

### Technical Impact
None to shipping code. `Sources/` and `Tests/` are byte-identical to baseline; the rework is entirely under develop-only `Demo/`. Tests were retained + extended (formatter matrix + DD7 truncation regression guard kept; plot-geometry locks added — span / x-map / time-inversion / y sentinel-pinning / tick-step / M:SS). The `analyzeLUFS` wiring test still exists (retargeted to `LoudnessGraphView`).

---

## Section 3 — Recommended Approach

**Direct Adjustment** (modify docs to match the shipped, operator-blessed design). Not a rollback — the graph is the correct realization of the loudness job-to-be-done and aligns with Story 8.1's operator direction. Not an MVP-scope change — the FR count and Epic-10 shape are unchanged; only FR-40's presentation wording moves.

**Spec-artifact strategy: Option A (Codex `gpt-5.6-sol` + round-table consensus).** Rewrite the Story-10.4 spec's normative body in place; **keep the filename + sprint-status key** (the `10-4` identity and link/anchor stability matter more than a descriptive slug; the story WAS born as `LUFSReadoutView`, and git carries the lineage); keep DD1/DD2 verbatim; keep the full changelog + add a reconciliation entry; add a prominent top-of-file reconciliation note citing `d3af680` / #96. Rationale (Codex): *"The audit trail is the sequence of revisions — not permanently incorrect current-state prose."* A `done` story's normative sections must describe the delivered system; the superseded scalar design survives via git history + the changelog + a short non-normative pointer, not via leaving stale ACs looking operative.

**Cross-ref strategy: tiered** (Codex refinement of the room's "rename all"). Rewrite *active/canonical* planning docs where the claim is now misleading (epics.md, architecture.md, epic-10-context). *Annotate — don't rewrite —* dated historical snapshots (the readiness report, the 8-1 story changelog): they were true on their date; a supersession annotation preserves that truth without falsifying the record.

**FR-40 amendment: give it the bound it lacked** (Winston's rider). Don't merely swap "single number" → "graph"; add the subordinate, height-capped placement bound the rubric said FR-40 was missing, and cite 8.1 DD#5 as the supersession source.

**Effort / risk / timeline:** ~1 doc-editing pass; low risk (docs only, no code); no timeline impact (story already `done`). The only judgment risk is over-rewriting the historical Dev Agent Record — mitigated by leaving that section as a dated record and pointing to it from the top note.

---

## Section 4 — Detailed Change Proposals

### 4.1 — `epics.md` FR-40 (`:105`)
**OLD:**
> - **FR-40** LUFS as primary measurement, secondary breakdown. Integrated LUFS as single number with unit label + small panel for true-peak + LRA. Does not dominate BPM-centric flow.

**NEW:**
> - **FR-40** Loudness surfaced as a time-series graph with a labeled scalar summary, subordinate to BPM. LUFS-over-time graph (X time, Y loudness on a fixed dB-FS axis: momentary + short-term series, integrated + max-true-peak reference lines, LRA band) PLUS a compact FR-44-labeled scalar summary (integrated LUFS / true-peak dBTP / loudness range LU). Occupies a subordinate, height-capped region (shares the analysis lane with the beat grid behind a segmented switch); does not dominate the BPM-centric flow. *(Amended 2026-07-11: the original "single number + small panel" wording was superseded by Story 8.1 DD#5 (2026-06-10) — a single integrated number misdescribes dynamic material; 8.1 shipped the momentary/short-term series specifically to enable this time-series rendering. Shipped as `LoudnessGraphView`, `d3af680`/#96.)*

### 4.2 — `epics.md` FR-40 traceability one-liner (`:249`)
**OLD:** `| FR-40 | Epic 10 | LUFS as primary measurement (Epic 8 dep) |`
**NEW:** `| FR-40 | Epic 10 | Loudness-over-time graph + labeled scalar summary, subordinate to BPM (Epic 8 dep; supersedes "single number" per 8.1 DD#5) |`

### 4.3 — `epics.md` Story 10.4 block (`:1457–1481`)
Rewrite heading + Story + the ACs to the shipped graph; fix AC4's DD2 factual error. New content:

- **Heading:** `### Story 10.4: LoudnessGraphView — LUFS-over-time graph + labeled scalar summary` *(shipped; originally specified as LUFSReadoutView — see the story spec's reconciliation note)*
- **Story:** "…**I want** a loudness-over-time graph with a compact labeled scalar summary, sharing one analysis lane with the beat grid, **So that** loudness surfaces without competing with the BPM-centric flow."
- **AC-graph:** renders `LoudnessGraphView.swift` — a `Canvas` plot (X time, Y loudness, fixed −60…+6 dB-FS axis) of the momentary (thin red) + short-term (light-blue) series with integrated (blue) + max-true-peak (green) reference lines and a translucent LRA band (drawn only when `loudnessRangeLU` is non-nil); silence/`−100` sentinel pins to the bottom edge.
- **AC-scalar-summary:** a compact FR-44-labeled caption row under the plot — integrated LUFS / true-peak dBTP (post-mono-mixdown help caveat) / loudness range LU; non-finite or ≤-sentinel → `unavailable` (never a bare number, never `−100.0`).
- **AC-subordinate:** loudness lives in the merged `analysisSection` lane behind a segmented **Beats | Loudness** switch, height-capped, so the BPM hero stays the dominant visual element (FR-40).
- **AC-LRA-absent (DD2 fix):** when `loudnessRangeLU == nil` (gated programme < 60 s), the LRA band is omitted and the scalar row shows `Loudness range: unavailable`. *(Corrects the original AC's factually-wrong "true-peak unavailable for a particular sample rate" — true-peak is a non-optional `Double`; unsupported sample rates throw, and `loudnessRangeLU` is the sole optional field. See story-spec DD2.)*
- **AC-playback:** the plot shares the lane's `PlaybackController`; clicking seeks to the clicked time (no beat snapping in this pane) and starts playback; the playhead animates via `TimelineView(.animation)` (the `BeatGridView` scrubber split).
- **FRs covered:** FR-40.

### 4.4 — `epics.md:894` (chart-consumption note)
Amend `Story 10.4 (`LUFSReadoutView`)` → `Story 10.4 (`LoudnessGraphView`)`, and replace the `LUFSChartSchemaProbe.swift`/probe-seed reference with a provenance pointer: "seeded by the chart probe added in `732e59c` (Land epic 8, 22 Jun); the probe file is removed post-reconciliation, its intent realized in `LoudnessGraphView`."

### 4.5 — `architecture.md` (`:1098`, `:1237`)
- `:1098`: `LUFSReadoutView.swift  # NEW (Epic D FR-40)` → `LoudnessGraphView.swift  # NEW (Epic D FR-40 — LUFS-over-time graph)`
- `:1237`: `FR-40 LUFS readout → `LUFSReadoutView`.` → `FR-40 LUFS-over-time graph → `LoudnessGraphView` (KDD-D2 `Canvas`; merged into the analysis lane with `BeatGridView` behind a Beats|Loudness switch; supersedes the scalar readout per 8.1 DD#5).`

### 4.6 — `epic-10-context.md:14`
`- Story 10.4: LUFSReadoutView — primary integrated LUFS + secondary breakdown` → `- Story 10.4: LoudnessGraphView — LUFS-over-time graph + labeled scalar summary (shipped; orig. LUFSReadoutView, reworked d3af680/#96)`

### 4.7 — `sprint-status.yaml`
- **Status key (`:315`):** unchanged — `10-4-lufsreadoutview-primary-integrated-and-secondary-breakdown: done`. (Keep the historical slug; the story is shipped.)
- **`last_updated` (`:38`):** prepend a 2026-07-11 note describing the shipped graph + the merged Beats|Loudness lane + this reconciliation, superseding the scalar-panel description that currently stands alone.

### 4.8 — Story-10.4 spec (`10-4-…-breakdown.md`) — Option A in-place rewrite
- **Add a top-of-file reconciliation note** (after Status): "Originally specified as `LUFSReadoutView` (a scalar panel); **shipped as `LoudnessGraphView`** (a LUFS-over-time graph) following the operator-directed rework in `d3af680` / PR #96. The normative sections below describe the shipped design; DD1/DD2 survived unchanged; the superseded scalar design survives in the Change Log and git history. FR-40 was amended in the same correct-course (superseded by Story 8.1 DD#5)."
- **Rewrite** the title, Story statement, AC1–AC7, Tasks, DD4 (+ the `LUFSReadoutView` host mentions in DD5/DD7), and the "What this story is (and is NOT)" section to the graph.
- **Keep verbatim:** DD1, DD2, the entire Change Log, the Spec Change Log / Review Triage Log / Dev Agent Record / Auto Run Result (dated records of the dev-auto run — historical, covered by the top note).
- **Add a Change Log reconciliation entry** dated 2026-07-11 referencing this Sprint Change Proposal.

### 4.9 — Delete the dead seed
Delete `_bmad-output/implementation-artifacts/10-4-lufs-chart-probe.swift` (unwired, in no build target). Provenance preserved: added in `732e59c` (22 Jun); intent realized in `LoudnessGraphView`.

### 4.10 — Annotate (do NOT rewrite) historical snapshots
- `implementation-readiness-report-2026-05-27.md:307` — append inline: `(superseded 2026-07-11: shipped as LoudnessGraphView — see sprint-change-proposal-2026-07-11-story-10-4.md)`.
- `8-1-…-promotion.md:38` — append inline supersession annotation, same form.

### 4.11 — Story 10-3 ripple note
Add a one-line note to the 10-3 artifact that the beat-grid lane now shares the `analysisSection` with loudness behind a Beats|Loudness segment control (10.4 rework, `d3af680`/#96); confirm `architecture.md:1237`'s FR-39 entry already reflects the BeatGridView merge.

---

## Section 5 — Implementation Handoff

**Scope:** Moderate — docs only, no code, story already `done`. Directly implementable by the Developer agent in a single batch pass (operator selected Batch mode).

**Deliverables:** this proposal + the 11 edits in Section 4, applied.

**Success criteria:**
- No planning/spec artifact's *normative/current-state* prose describes the deleted scalar `LUFSReadoutView` panel.
- FR-40 reads graph-compatible with the 8.1-supersession provenance and a placement bound.
- The Story-10.4 spec's normative body describes `LoudnessGraphView`; DD1/DD2 + the changelog trail intact; top reconciliation note present.
- Dated historical snapshots annotated, not falsified.
- The dead seed removed; its provenance cited.
- `Sources/` + `Tests/` untouched (docs-only change).
- The `10-3` ripple acknowledged.

**Not in scope:** any code change (the rework already shipped); renaming the story filename/slug or sprint-status key; re-running dev/review on 10.4 (it is `done`).
