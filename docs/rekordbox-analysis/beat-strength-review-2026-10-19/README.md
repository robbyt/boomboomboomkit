# Beat-evidence review, 2026-10-19

Answer from the rekordbox-analysis effort to `beat-strength-question.md` (the question is preserved here too), with the evidence it cites. The guidance document is `boomboomboomkit-beat-strength-and-ml-guidance.md`; `research.md` is the reader repository's Bitwig notes that it links to.

This directory is develop-only, like its parent. It follows the parent's local-only policy for decompiled and proprietary material:

| Path | Tracked | Contents |
|---|---|---|
| `boomboomboomkit-beat-strength-and-ml-guidance.md` | yes | The guidance: beat evidence, phase tracking, learned parameter selection |
| `beat-strength-question.md` | yes | The question the guidance answers |
| `research.md` | yes | Bitwig `RekordboxDbReader::getBeatGridFromANLZ` findings; its link to the reader's host-integration guide points at that repository |
| `beat-strength-evidence-2026-10-19/manifest.json` | yes | SHA-256 and byte size for every file in that directory, tracked or not |
| `beat-strength-evidence-2026-10-19/scripts/`, `probe/`, `probe-results.jsonl`, `probe-build.log` | yes | The Hopper query script; a standalone Swift probe holding unchanged copies of this package's decoder, selector, fitter and observation sources; its output and build log |
| `beat-strength-evidence-2026-10-19/hopper/`, `native/` | no, local only | Rekordbox decompiled pseudocode and ARM64 disassembly for the threshold helper, observation likelihoods, state space and bar Viterbi |
| `logic-pro-analysis-2026-10-19/` | no, local only, whole directory | Static inspection of Logic Pro 12.4 (REA export with pseudocode and assembly, shipped model graph and metadata, report, manifest). Held on disk at this path and verified by its own `manifest.json`; nothing from it is in the repository |

Links from the guidance document into `logic-pro-analysis-2026-10-19/` resolve only on a machine holding the local copy.
