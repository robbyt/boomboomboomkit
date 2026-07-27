# Epic 12 PRD — Addendum

Depth that belongs to architecture, solution design, or a downstream story rather than the PRD narrative. Captured during Discovery, 2026-07-26/27.

---

## A. AST-as-regression: the rejected alternative, with independent evidence

The operator supplied an externally written Colab notebook (`Finetune_AST_for_BPM_Regression.ipynb`) fine-tuning `MIT/ast-finetuned-audioset-10-10-0.4593` with `num_labels=1, problem_type="regression"`.

The notebook is competently built: md5-verified GiantSteps download, z-score label normalization (the correct fix for raw-BPM MSE destabilizing a fresh head), held-out split reconstructed from the same seed, and honest diagnostics in its own prose.

Its held-out output is the useful part, because it independently reproduces the failure predicted on theoretical grounds in #166.

| True BPM | Predicted | Error | Note |
|---|---|---|---|
| 127 | 122.4 | −4.6 | near corpus mean |
| 127 | 131.4 | +4.4 | near corpus mean |
| 139 | 136.7 | −2.3 | near corpus mean |
| 141 | 139.8 | −1.2 | near corpus mean |
| 139 | 130.9 | −8.1 | |
| 110 | 124.5 | +14.5 | pulled toward mean |
| 117 | 93.5 | −23.5 | |
| 121 | 161.8 | +40.8 | |
| 89 | 129.2 | +40.2 | collapsed to mean |
| 71 | 133.5 | +62.5 | collapsed to mean |

MAE 20.2 BPM. Scored at the project's 4% Acc1 tolerance: **4 of 10**.

**Reading.** Tracks near the corpus central tempo are accurate to a few BPM; tracks far from it collapse toward ~125-135. This is regression to the conditional mean on a multimodal target. The 71 BPM case is decisive — the prediction is 133.5, which is neither 71 nor its octave 142. An octave error would at least be musically meaningful and Acc2-recoverable; this value corresponds to nothing.

**Caveats before blaming AST itself.** The AST feature extractor's default input window is short relative to a two-minute clip, so the model may only see the head of each track; 20 epochs over 664 tracks is thin; and the evaluation is a random 10% split of the same corpus, i.e. the most favourable protocol available. None of these rescues a scalar head, but all would matter if the head were swapped for classification.

**Conclusion carried into the PRD:** the failure is the head, not the backbone. Pure scalar regression stays rejected. A hybrid head — classify to select the metrical level, small regression head to refine within the selected bin — remains an open candidate but is out of scope while capacity is not the constraint.

---

## B. Distribution options considered, and why the demo app won

| Option | Verdict |
|---|---|
| Commit weights to the repo | **Vetoed by operator.** Was the pre-Story-4-6 approach. |
| Git LFS | **Unworkable.** SwiftPM caches source deps as bare mirrors where LFS smudge filters never run; the issue was open from 2018. A fix (PR #9625) merged to `swift-package-manager` `main` on 2026-03-23, auto-detecting `filter=lfs` and running `git lfs fetch`/`pull` — but it lands only in toolchains built after that commit, requires `git-lfs` on every consumer machine, and bills LFS bandwidth per clone. Without it the package builds and fails at runtime on pointer stubs. |
| `.binaryTarget(url:checksum:)` | **Cannot carry a model.** Accepts XCFramework or `.artifactbundle` only; SE-0305 pins the manifest type to `"executable"`. The resource-bundle pitch is unimplemented. An XCFramework carrying the `.mlmodelc` only materializes when an *app* embeds the framework — which a library cannot assume. |
| Hugging Face download at first use | **Technically viable, structurally wrong for a library.** Plain REST, no auth for public repos: `GET https://huggingface.co/{repo}/resolve/{revision}/{path}`, pinning `revision` to a commit SHA. A `.mlmodelc` is a directory, so it needs the listing API (`/api/models/{repo}` siblings, or `/tree/{rev}/{path}`) rather than a tarball endpoint. Achievable with `URLSession` alone — the HF Swift clients would break the zero-dependency rule, and Argmax's precedent is to vendor rather than depend. Rejected because a library owns none of network policy, entitlements, cache location, or user consent. |
| Apple-native (ODR, Background Assets) | **Unavailable.** On-demand resources are iOS/tvOS only — macOS does not support them. Background Assets requires App Store/TestFlight distribution plus an extension inside the host app's bundle. |
| **Demo app archive** | **Chosen.** `make demo-archive` already delivers a compiled artifact that never passes through git. No repo commit, no network, no new dependency, no change to the library's identity. |

**If the fetch option is ever revisited**, the shape is: cache in Application Support (not Caches — the system purges it under disk pressure, including out from under a non-running app) with `isExcludedFromBackupKey`; stream SHA-256 per file over a canonical sorted manifest since the bundle is a directory; download to a temp dir on the same volume and `FileManager.replaceItemAt` (a half-written `.mlmodelc` fails obscurely in CoreML); require `com.apple.security.network.client`, which is the **app's** entitlement and cannot be granted or reliably detected by a library; and degrade to the existing abstain path when offline, never blocking or throwing at init.

Real-world precedent: WhisperKit/Argmax and MLX Swift examples all download from HF Hub at first use and cache locally. Nobody ships tens of MB inside the package.

---

## C. On-device inference surface (verified 2026-07-27)

**Core AI is real** — WWDC 2026 session 324 "Meet Core AI". `AIModel`, `InferenceFunction` and `.aimodel` are genuine, iOS 27 / macOS 27 generation (Apple-silicon only; Intel ends at macOS 26). Custom-model path: `torch.export` → `coreai_torch.TorchConverter()` → `.to_coreai()` → `.optimize()` → `.save_asset()`, AOT-compiled with `xcrun coreai-build compile`. Compression via `coreai-opt` (int4/int8/FP4/FP8, 4-bit palettization, QAT).

*Unverified:* no Apple statement found exposing explicit ANE/GPU/CPU placement control in Core AI; treat placement as automatic. Core ML is **not** deprecated — that framing comes from press, not Apple.

**`MLComputeUnits.all` is a preference, not a guarantee.** Core ML partitions the graph and falls back to GPU (unsupported ops, varying batch shapes) or CPU silently. Verification is empirical, via Xcode's Core ML Performance Report or the Instruments Core ML template showing per-layer assignment.

**Transformers on ANE need structural surgery,** not a flag: Apple's guidance requires `(B, C, 1, S)` channels-first layout, `Linear` → `Conv2d`, batched matmul rewritten as `einsum`, chunked tensors for L2 residency, and minimal reshape/transpose. An off-the-shelf HuggingFace AST would need that rewrite. A plain 2D-conv CNN is mostly ANE-friendly already, but resamples, transposes, dynamic shapes and host-side softmax fragment the partition.

**BNNSGraph is not deprecated.** Introduced WWDC24 with real-time guarantees explicitly aimed at audio and signal models — no runtime allocation, single-threaded execution — properties Core ML does not offer. `BNNSGraphBuilder` (Swift) added WWDC25. No WWDC 2026 BNNS session found, so 2026 investment is unconfirmed either way; the CPU-only path remains supported and is the better fit for deterministic real-time CPU inference.

---

## D. Tempo-literature reference points

**GiantSteps Acc1 / Acc2, from the arXiv:2401.08891 comparison table:** Böck TCN 87.0 / 96.5 · TempoCNN 82.1 / 97.1 · Gkiokas 72.1 / 92.2 · SDNet 72.8 / 97.9 · Percival 50.6 / 95.6 · Quinton SSL 47.0 / 88.6 · MULE 1-NN 35.9 / 96.1. Best overall found: MULE + tempo-translation probe, 90.7 / 98.2.

**EfficientAT parameter counts** (Schmid et al., ICASSP 2023): mn04 0.98M, mn05 1.43M, mn10 4.88M, mn20 17.91M, mn40 68.43M; dymn04/10/20 at 1.97M / 10.57M / 40.02M. No tempo evaluation exists for any of them.

**Octave-error remedies with published numbers:** Hörschläger et al. SMC 2015 (genre priors, DnB 7.19% → 78.42%) · Gkiokas et al. ISMIR 2012 (periodicity-vector SVM, the canonical learned metrical-level classifier) · Chen et al. AES 2009 (slow/fast pre-classifier over 11 algorithms, mean improvements 45% and 65.5%, though only 3 of 11 exceeded 50% Acc1 after correction).

**Perceptual priors** (Parncutt 1994; Moelants & van Noorden resonance at ~500 ms / 120 BPM; ~94% of pieces within the 80-160 tempo octave) are widely cited but no head-to-head was found showing a resonance prior beating a learned classifier.

**Method warning.** During this research a PDF summarizer fabricated a detailed and confident answer for Böck 2019 — inventing a sigma value, an expectation-decoding scheme, and Acc1/Acc2 figures. Every claim above was re-verified against primary text. Treat summarizer output as a lead, never a citation.
