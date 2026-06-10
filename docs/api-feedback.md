# BBBK API Feedback — from the MediaDiff / MetaMan consumer

_Date: 2026-06-04. Author: MediaDiff (MetaMan macOS app + `metaman` CLI), a downstream consumer of BBBK._

This is consumer feedback to inform the new API. It summarizes **how MediaDiff actually uses BBBK today** and gives **prioritized suggestions** for making downstream task/cancellation lifecycle easier. It was written after shipping a fix for a subtle cancel/restart race in the consumer-side task machinery that wraps BBBK (MetaMan PR #35), which prompted the question "should a better cancel API live in BBBK?".

---

## How MediaDiff consumes BBBK

**Dependency:** `MediaDiffCore/Package.swift` → `.package(url: "https://github.com/robbyt/boomboomboomkit.git", branch: "main")` (remote, not local path).

**Public surface we touch:** essentially just `AudioAnalysisService.analyzeBPM(url:)` and `AudioAnalysisService.analyzeLUFS(url:)`. (Two view/thumbnail files also import BBBK for waveform/PCM, separate from analysis.) We use **default `Options`** — we do not currently set `intensity`, `techniqueSet`, ML, `BPMSelectionPolicy`, diagnostic traces, or a custom `isCancelled`. It's `url` in, result out.

**The defining pattern: we always call the two as a PAIR (BPM then LUFS).** Every production call site:

| Context | File:line | Shape |
|---|---|---|
| Core / CLI enrichment | `MediaDiffCore/.../Utilities/MetadataService.swift:159,170` | **sync**, in the caller's task; `analyzeBPM` runs only after a tag-BPM precheck, then `analyzeLUFS` |
| SwiftUI per-file lazy enrichment | `MetaManApp/.../ViewModels/MetadataDetailViewModel.swift:286,389` | **two separate `Task.detached`** (BPM, LUFS) → two `@MainActor` appliers |
| Batch enrichment | `MetaManApp/.../ViewModels/PlaylistViewModel.swift:1550,1555` | sequential BPM then LUFS in the batch pass |
| Library export preparation | `MetaManApp/.../Export/LibraryExportSessionFactory.swift:62,63` | inside an `@concurrent` closure, BPM then LUFS per file |

**Cancellation today:** we cancel our own `Task.detached` handle; BBBK's default `Options.isCancelled = { Task.isCancelled }` picks that up at its internal checkpoints and throws `CancellationError`. That contract works well — no complaints about the *mechanism*.

---

## What's painful (consumer's view)

1. **BPM and LUFS are two separate calls.** That means two PCM reads, and — in the SwiftUI path — **two tasks, two appliers, two cache writes, and a cross-enrichment merge dance** (we persist the BPM-enriched `MediaFile` back onto the VM so the LUFS applier "sees BPM if it completed first," and vice-versa). Every single consumer calls them as a pair, so this split is paid everywhere.

2. **The sync API forces the consumer to own task lifecycle.** To get the work off the MainActor we wrap each call in `Task.detached`, store the handle, and hand-roll cancel/replace semantics. We just shipped a fix (PR #35) for a real cancel/restart race in exactly this machinery: an identity-checked `defer` that clears the task handle, plus `!Task.isCancelled` guards, across three appliers in one ViewModel. That complexity is consumer-side, but **fewer/cleaner BBBK calls would shrink the surface it lives on.**

---

## Suggested API directions (prioritized)

### 1. Combined `analyze` (BPM + LUFS in one call) — highest impact
Already on `TODO.md` ("Combined Analysis API"). For us this is the biggest lever, because **100% of our call sites already call the pair.**

```swift
public struct AudioAnalysis: Sendable {
  public let bpm: AudioAnalysisResult?   // existing type
  public let lufs: Double?
}
public static func analyze(url: URL, options: Options = .init()) throws -> AudioAnalysis
```

Consumer impact: one PCM read instead of two; in the SwiftUI path, **one** task / applier / cache write / defer instead of two, and the BPM↔LUFS merge-ordering coordination disappears entirely. It also halves the surface where the cancel/restart race we just fixed can occur.

### 2. `nonisolated async throws` variants — prompt, structured cancellation
Offer async siblings (keep the sync ones):

```swift
public nonisolated static func analyze(url: URL, options: Options = .init()) async throws -> AudioAnalysis
```

`nonisolated async` runs off the caller's actor (SE-0338 → global executor), so the DSP won't block our MainActor **without us needing `Task.detached`**. Internally, at the existing per-window checkpoints, use `try Task.checkCancellation()` **plus** `await Task.yield()`. Then our code collapses to:

```swift
analysisTask = Task { [weak self, url] in           // inherits the VM's MainActor
  guard let a = try? await AudioAnalysisService.analyze(url: url) else { return }
  guard !Task.isCancelled else { return }
  self?.applyAnalysis(a)                             // one applier, back on MainActor
}
```

Cancellation becomes just `analysisTask?.cancel()`, and the analysis **actually stops promptly** (it's checking the ambient task), instead of running to completion and being discarded.

### 3. Keep `Options.isCancelled` — don't drop it
For the **sync** path, CLI/batch callers, and deterministic tests, the injected closure is the right seam (a non-`Task` caller or a custom cancellation source can't rely on `Task.isCancelled`). Async variants use `Task.checkCancellation()`; sync variants keep honoring `options.isCancelled`. Offer both rather than forcing structured concurrency on the whole API.

### 4. Tag-hint / skip-analysis — cheapest way to avoid a task at all
Also on `TODO.md` ("BPM Tag Hint API"). An `Options.existingTagBPM` (or a cheap `precheck(url:) -> Bool`) so a file with a trustworthy BPM tag needs **no long task** — the cheapest cancellation is not spawning the job. We already do this dance in `MetadataService.extractBPMFromTags`; consolidating it into BBBK means every consumer benefits and the logic stays next to the analyzer.

---

## Explicit non-goal: do NOT add a task-slot / handle-manager to BBBK
The residual pain — owning a *replaceable, cancellable* `Task` handle (identity-checked clear, capture-window guard) — is **generic ViewModel/app lifecycle machinery, not audio.** The tell: our *geocoding* code has the identical race and doesn't touch BBBK at all (it's an app-internal `LocationService`). An audio-analysis library that grows `TaskSlot`/`CancellableJob` primitives would be a category error, and it wouldn't even help the non-audio cases. If that pattern proves painful across our ViewModels, the right home is a small local `@MainActor TaskSlot` utility in MetaMan — not BBBK.

**BBBK's job:** expose cancellable work (sync + an async/cooperative variant). **The app's job:** decide how tasks are started, stored, replaced, and cancelled.

---

## One caveat to validate before committing to async
For very long analyses (high intensity on large files), confirm the per-window `await Task.yield()` keeps the cooperative pool healthy (heavy synchronous DSP can otherwise hold a pool thread). Alternatively, document: "use the sync API on your own executor for batch/long jobs." Today's `Task.detached` wrapping has the same property, so this isn't a regression — just something to get right if async becomes the recommended path.

---

## TL;DR
- We only use `analyzeBPM` + `analyzeLUFS`, always **as a pair**, with default options, in 4 contexts.
- **#1 `analyze` (combined)** and **#2 `nonisolated async`** would cut us from two long-lived tasks to one and make "cancel" a prompt one-liner — the two highest-value changes.
- Keep the `isCancelled` closure; add a tag-hint skip; **keep task ownership out of BBBK.**
