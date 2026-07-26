# Sprint Change Proposal — Story 10-3 post-`done` UX rework reconciliation

**Date:** 2026-07-11
**Author:** correct-course workflow (triggered by party-mode review of PR #94)
**Trigger story:** 10-3 — BeatGridTimelineView
**Trigger commit:** `cac4fe6` (merged as PR #94)
**Change scope classification:** **Moderate** (PRD + epics + architecture doc reconciliation; one PRD Non-Goal / FR amended. No replan; MVP intact; demo-only, library byte-identical.)

---

## Section 1 — Issue Summary

An operator-directed UX rework of the Story 10-3 demo surface landed via commit `cac4fe6` / PR #94 **after** the story was marked `done`, with **no bmad governance artifact** (no correct-course, no re-spec, no status change). The code is sound; the problem is that the shipped surface now contradicts its own story ACs *and* a PRD-level Functional Requirement + Non-Goal, and the planning artifacts still describe the superseded design.

**Issue category:** New requirement emerged from the stakeholder (operator UX decision) — a mid/post-implementation UX pivot.

**What actually shipped (evidence — commit body + working tree):**
- The separate waveform-free `BeatGridTimelineView.swift` was **deleted**; its scrubber, transport, and FR-44 readout were **merged into the Epic-8 `BeatGridView`** (which already rendered a waveform since `732e59c`).
- The Timeline/Waveform **view-mode switch was deleted** (`BeatGridViewMode`, `fallbackViewMode`, the `preferredBeatGridViewMode` hydrate/persist, the segmented `Picker`).
- **New feature: click-to-scrub with forced beat-snapping** — a `SpatialTapGesture` maps content-x → time and snaps every click to the nearest raw detected beat (`clickSeekTime`, midpoint tie → earlier beat); a click while stopped/paused starts playback.
- `PlaybackController.seek(to:)` — deleted in `6eea321` as dead code — was **reintroduced** (the tap handler is now its caller).

**Evidence of the governance gap:**
- Story file `Status: done`, yet a grep of the story spec for `snap`/`click-to-scrub`/`clickSeek`/`SpatialTap` returns **0** — the whole feature is unspecced.
- Story **AC5** ("no waveform primitives") governs a file that no longer exists; **AC6** ("the existing view is NOT deleted" + mandated view-mode switch) is inverted.
- **PRD Non-Goal + FR-39** ("no waveform… not to build a mini DJ waveform engine") are contradicted by the shipped surface.
- `sprint-status.yaml` `last_updated` for 10-3 still narrates the deleted switch ("flip to Waveform; relaunch → view-mode persists").
- An orphaned `preferredBeatGridViewMode` UserDefaults key is left behind (BC not a goal — acceptable, but unrecorded).
- **Verification owed:** `cac4fe6` was authored on Linux; only `demo-lint` was run. `demo-build` / `demo-test` are operator-Mac-pending — so `done` is not yet trustworthy on its own gauntlet.

**Key distinction that bounds the blast radius:** the rework built **no new waveform engine**. The Epic-8 `BeatGridView` waveform pre-existed 10-3 (`732e59c`, story DD3). So FR-39's *intent* — "don't build a mini DJ waveform engine" — is **intact**; only FR-39's *presentation letter* ("beats as ticks, no waveform") was overridden by the operator. This is a presentation-scope amendment, not an MVP breach.

---

## Section 2 — Impact Analysis

**Epic impact (Epic 10):** Completable as planned. No epic added/removed/resequenced. Only FR-39's demo-presentation semantics change. Downstream Stories 10.4 (LUFS) and 10.5 (docs) are unaffected — no shared surface.

**Story impact:** Confined to 10-3.
- AC5 retired, AC6 inverted, new beat-snapping/click-to-scrub ACs added.
- `seek(to:)` round-trip (deleted `6eea321` → reintroduced `cac4fe6`) recorded in the change log.
- No other story touches `BeatGridView` / `BeatGridTimelineView`.

**Artifact conflicts (to be edited):**
- **PRD** (`prds/prd-BoomBoomBoomKit-2026-05-25/`): Non-Goal (`prd.md:20`), FR-39 (`prd.md:161`), decision-log (`.decision-log.md:232`).
- **epics.md**: FR-39 definition (`:104`), Story 10.3 section (`:1423–1453`). (Lines `:201/:248/:331` are prose echoes — updated for consistency.)
- **architecture.md**: Epic D summary (`:43`), file tree (`:1097`), FR-39 coverage line (`:1237`).
- **sprint-status.yaml**: stale `last_updated` (`:38`).

**Artifacts intentionally NOT edited:** the dated `implementation-readiness-report-2026-05-27.md` and `-2026-03-31.md` are point-in-time snapshots — historical record, left as-is (editing a dated report would falsify history).

**Technical impact:** orphaned `preferredBeatGridViewMode` UserDefaults key (record, no code action — BC not a goal); `demo-build`/`demo-test` Mac gauntlet owed before `done` is re-affirmed. Library `Sources/`/`Tests/` byte-identical (demo-only).

---

## Section 3 — Recommended Approach

**Option 1 — Direct Adjustment (SELECTED).** Amend the affected artifacts to match the shipped reality; add the beat-snapping ACs; amend FR-39 + the PRD Non-Goal per operator decision; correct sprint-status. Effort **Low–Medium**, Risk **Low** (demo-only, operator-endorsed, no library change).

**Option 2 — Rollback.** Revert PR #94 to restore the two-view + switch design. **Not viable / rejected** — the operator directed the rework and the room agrees it is materially better UX; rollback destroys value to satisfy paperwork.

**Option 3 — PRD MVP Review.** **Not needed** — the MVP goal ("prove the API surface") is unaffected, and FR-39's engine non-goal holds. Only FR-39's presentation letter is amended.

**Recommendation: Option 1 (Direct Adjustment) + FR-39/PRD amendment.** Rationale: the work is good and shipped; the honest, lowest-risk path is to move the acceptance surface to match it, explicitly recording the operator decision so `done` stops being counterfeit. The one genuinely PM-level judgment — amending a published FR + Non-Goal — is made explicit and attributed, not silently.

---

## Section 4 — Detailed Change Proposals

### 4.1 — PRD Non-Goal (`prd.md:20`)
**OLD:**
> - **Waveform rendering in the demo** (per FR-39). Beat-grid surfaces as timeline ticks + text readout. Building a waveform engine is its own product surface and is out of scope.

**NEW:**
> - **Building a waveform *engine* in the demo** (per FR-39). The demo does not implement waveform sampling/decoding as a product surface. *(Amended 2026-07-11, Story 10-3 operator UX decision: the beat-grid timeline is presented on the Epic-8 `BeatGridView`'s pre-existing waveform overlay — reuse of an existing surface, not a new engine. The "no waveform engine" non-goal stands; the earlier "no waveform at all in the beat-grid view" presentation constraint is superseded.)*

**Rationale:** preserves the real non-goal (no new engine), records the operator override of the presentation letter in-place per the PRD's own "annotate, don't silently renumber" convention.

### 4.2 — PRD FR-39 (`prd.md:161`)
**OLD:**
> **FR-39 — Beat-grid as timeline + text readout (no waveform).** Demo presents beats and downbeats on a horizontal timeline with current-time scrubber, plus a text readout (estimated tempo, beat count, downbeat status, grid confidence). Waveform rendering is explicitly out of scope for v1 — the demo's job is to prove the API surface, not to build a mini DJ waveform engine.

**NEW:**
> **FR-39 — Beat-grid as timeline + text readout.** Demo presents beats and downbeats on a horizontal, zoomable time axis with a current-time scrubber and click-to-scrub (snapping to the nearest detected beat), plus a text readout (estimated tempo, beat count, downbeat status, grid confidence). The timeline shares the Epic-8 `BeatGridView` waveform overlay so beats can be auditioned against the signal. Building a waveform *engine* (new sampling/decoding) remains out of scope — the demo's job is to prove the API surface. *(Amended 2026-07-11 per Story 10-3 operator UX decision; original v1 wording was "no waveform," superseded to a single merged view reusing the existing overlay.)*

### 4.3 — PRD decision-log (`.decision-log.md:232`, item 2)
**OLD:**
> 2. **Beat-grid viz:** Defer waveform; timeline + text readout for v1. Translates to FR-39. Reason: waveform rendering is product surface unto itself.

**NEW:**
> 2. **Beat-grid viz:** Defer a *waveform engine*; timeline + text readout for v1. Translates to FR-39. Reason: building a waveform engine is a product surface unto itself. *(2026-07-11 update: Story 10-3 merged the timeline onto the Epic-8 view's existing waveform overlay + added click-to-scrub beat-snapping; the "no waveform at all" presentation stance was superseded, the no-new-engine stance retained.)*

### 4.4 — epics.md FR-39 definition (`:104`)
**OLD:**
> - **FR-39** Beat-grid as timeline + text readout. SwiftUI Canvas timeline with current-time scrubber + text readout (tempo, beat count, downbeat status, confidence). No waveform.

**NEW:**
> - **FR-39** Beat-grid as timeline + text readout. SwiftUI Canvas timeline with current-time scrubber, click-to-scrub (beat-snap), and text readout (tempo, beat count, downbeat status, confidence), on the Epic-8 `BeatGridView` waveform overlay. No new waveform engine. *(Amended 2026-07-11, Story 10-3.)*

*(Prose echoes at `:201`, `:331`, and architecture `:43` — drop the bare "(no waveform)" parenthetical, replace with "(no new waveform engine)".)*

### 4.5 — epics.md Story 10.3 section (`:1423–1453`)
- **Retitle** `:1423`: `### Story 10.3: Beat-grid timeline + text readout on the merged BeatGridView`.
- **AC block `:1431–1433`** — drop the separate-`BeatGridTimelineView.swift` framing; the beats + taller downbeat ticks now render on the merged `BeatGridView` Canvas over the waveform overlay.
- **AC block `:1435–1437`** — keep the `TimelineView(.animation)` scrubber; drop the untestable "60Hz"/"all zoom levels" phrasing (already dropped in the story file).
- **AC block `:1439–1441`** — keep the four-field FR-44 readout unchanged.
- **AC block `:1443–1445`** — keep the downbeats-absent behavior unchanged.
- **REPLACE AC block `:1447–1449`** (the "zero waveform matches" grep AC) **with a new click-to-scrub / beat-snap AC:**
  > **Given** the timeline is visible, **When** the user clicks the lane, **Then** the click maps content-x → time via `pointsPerSecond` and **snaps to the nearest raw detected beat** (`clickSeekTime`; exact-midpoint tie → earlier beat; `>= 0` result); a click while stopped/paused starts playback; the pure `clickSeekTime`/`scrubberX` helpers are unit-locked in `BeatGridLogicTests`.
- **`:1451` FRs covered:** unchanged (FR-39).

### 4.6 — architecture.md
- **`:1097`** file tree — **OLD:** `│           ├── BeatGridTimelineView.swift              # NEW (Epic D FR-39, SwiftUI Canvas)` → **NEW:** `│           ├── BeatGridView.swift                     # Epic 8 + Epic D FR-39 (merged: waveform + beat-grid timeline + scrubber + click-to-scrub)`
- **`:1237`** — **OLD:** `FR-39 timeline → KDD-D2 Canvas.` → **NEW:** `FR-39 timeline → KDD-D2 Canvas, merged into the Epic-8 BeatGridView (click-to-scrub beat-snap; 2026-07-11).`
- **`:43`** — replace "Beat-grid timeline (no waveform)." → "Beat-grid timeline on the shared waveform view (no new waveform engine)."

### 4.7 — Story file `10-3-...md`
- **AC5** ("no waveform primitives (FR-39)") — **retire**, replaced by a note: BeatGridTimelineView.swift deleted; the merged BeatGridView is a waveform view by design; FR-39's engine non-goal still holds (no new sampling/decoding added).
- **AC6** ("view-mode switch keeps the Epic-8 view") — **invert**: the two views were unified into one merged `BeatGridView`; the Picker + `BeatGridViewMode` + `preferredBeatGridViewMode` persistence were deleted; the `preferredBeatGridViewMode` UserDefaults key is left orphaned (BC not a goal — recorded).
- **ADD** an AC for click-to-scrub + forced beat-snap (mirroring 4.5's new AC) and the bordered transport with verbatim `playbackError` render.
- **Change log:** record the `seek(to:)` delete-then-reintroduce round-trip and the operator rework.
- **Status:** hold `done` but with an **explicit open item**: `demo-build`/`demo-test` Mac gauntlet must be green (only `demo-lint` verified so far) before `done` is trustworthy.

### 4.8 — sprint-status.yaml (`:38`, `last_updated`)
Correct the stale 10-3 narration: it currently describes "flip to Waveform; relaunch → view-mode persists" (a deleted switch). Replace with a line describing the merged single-view + click-to-scrub beat-snap reality and the pending Mac gauntlet. `development_status` for `10-3-...` stays `done` (re-affirmed on gauntlet-green).

---

## Section 5 — Implementation Handoff

**Scope: Moderate** — PRD/epics/architecture reconciliation + one PRD FR/Non-Goal amendment.

- **PM (John)** — owns the FR-39 + PRD Non-Goal amendment sign-off (4.1–4.4). This is the one PM-level judgment; the operator has directed it, PM records it.
- **Dev (Amelia)** — applies the doc edits (4.5–4.8): epics.md, architecture.md, the story file ACs, sprint-status. Records the orphaned key.
- **Operator (Robert)** — runs the **Mac gauntlet** (`make demo-fmt` / `demo-build` / `demo-test` / `demo-lint`) + the GUI smoke (click-while-stopped starts at nearest beat; click-while-playing jumps without stopping; pinch-zoom still anchors under the cursor). `done` is re-affirmed only when green.

**Success criteria:** every planning artifact describes the shipped single merged `BeatGridView` + click-to-scrub beat-snap; FR-39 + PRD Non-Goal amended and attributed; sprint-status corrected; orphaned key recorded; Mac gauntlet green.

**Deferred/none:** no rollback, no new story, no epic change.
