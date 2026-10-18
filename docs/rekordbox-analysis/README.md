# Rekordbox analysis — preserved research

Snapshot of a reverse-engineering investigation of Rekordbox 7.2.19.0342 and a
Swift timing probe against BoomBoomBoomKit at
`rterhaar/12-7-eval-corpus-harness` HEAD `0f90ed8de52a9626cd47d3a263bed5af90a6c80e`.
Preserved on 2026-10-17 from `/private/tmp`.

This directory is develop-only (see repo-root `CLAUDE.md`). Do not promote any of
it to `main`.

## Layout

| Path | Contents |
|---|---|
| `FINDINGS.md` | The investigation's report. Written in plain prose; every claim cites an evidence file by path |
| `AGENT_GUIDANCE.md` | How future agents should consume this directory and the project plan it feeds into |
| `manifest.json` | Per-file SHA-256, original `/private/tmp` source path, byte size |
| `artifacts/rekordbox-bpm-analysis.hop` | Completed Hopper database (approximately 386 MB). Gitignored. Loaded through Hopper's REA adapter via its Python console |
| `evidence/hopper/*.json`, `*.c` | REA Hopper adapter query output. The `.json` records are local-adapter reports, not MCP Evidence envelopes (ids begin `local-hopper-`). The `.c` files are the adapter's decompiled pseudocode for the same procedure |
| `evidence/native/*.asm` | Rekordbox ARM64 disassembly: entry points for the detect dispatch, high-precision path, learned analyze, downbeat tracking, observation construction, and legacy focus analysis |
| `evidence/models/model-inspection.txt` | TensorFlow SavedModel protobuf summary for model7/model8 |
| `evidence/models/stft-graph.txt` | Dump of the frontend's STFT subgraph (1024/2048/4096 FFT, hop 441) |
| `evidence/timing/results.json` | 24 path/fixture rows from the current-HEAD Swift timing probe |
| `evidence/timing/swift-test.log` | `swift test` log for that probe |
| `evidence/timing/TimingProbeTests.swift` | The probe test source (originally `boomboom-timing-probe/ProbeTests/TimingProbeTests.swift`) |
| `evidence/timing/ProbePackage.swift` | The probe's SPM manifest (originally `boomboom-timing-probe/Package.swift`) |
| `scripts/rekordbox-hopper-query.py` | Queries the loaded Hopper document from Hopper's Python console. Contains the previous environment's absolute paths; update before reuse |
| `scripts/rekordbox-model-inspect.py` | Reads model7/model8 SavedModel protobufs and emits the inspection + stft-graph text |

## Reproducing the Hopper queries

1. Open Hopper and load `artifacts/rekordbox-bpm-analysis.hop`. REA's macOS
   launcher rejects saved-database targets, so the queries are driven from
   Hopper's own Python console using the installed REA Hopper adapter.
2. Update the paths at the top of `scripts/rekordbox-hopper-query.py` so they
   match the current environment, then paste the script into Hopper's console.
3. Each `local-hopper-*` record in `evidence/hopper/*.json` corresponds to a
   dispatch-function call. The `.c` sibling is the adapter's pseudocode for the
   same procedure.

## Reproducing the model inspection

`uv run python3 scripts/rekordbox-model-inspect.py` against the installed
`Contents/Resources/models/detect_beat/{model7,model8}/` writes the two
`evidence/models/*.txt` files. The script never links the Rekordbox binary; it
only reads the TensorFlow SavedModel protobufs.

## Reproducing the timing probe

The probe source and its SPM manifest are preserved as `evidence/timing/*.swift`
(renamed on preservation; see the table). To re-run against the current
BoomBoomBoomKit tree, copy the two files into a fresh SPM package that depends
on BoomBoomBoomKit as a local path dependency and `swift test` it. Phase 2 of
the Epic-13 plan is to port this probe into an in-tree test target rather than
leave it standalone.

## What this preserves — and what it does not

Preserved: original artifact bytes, SHA-256 for every file (see `manifest.json`),
and the investigation's prose findings.

Not preserved and intentionally so: the Rekordbox executable itself, any
proprietary model weights, authentication tokens, Python virtualenvs, build
caches, or the full `/private/tmp` tree.
