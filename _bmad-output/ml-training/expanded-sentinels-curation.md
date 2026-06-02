# Expanded DnB Sentinel Curation (Story 7.1, FR-18 gate (a))

Develop-only rationale for the 8 expanded sentinels in the main-bound `Tests/.../Fixtures/12-dnb-sentinels-expanded.json` (4 originals + 8 expanded).

## DD #8 subgenre asymmetry valve — FIRED

The corpus has NO `subgenre` field. On-disk keyword probe: `neurofunk`=0, `jump-up`=0, `liquid`=0 machine-readable hits; only `jungle` (10) and `amen` (103) have any footprint. A dev agent cannot classify by ear. Therefore:

- Subgenre tags below are **provisional** (`subgenre_provisional: true`), derived from playlist vibe + tempo band + jungle/amen keywords.
- The DD #8 valve (drop below confident 2-per-subgenre) **has fired**. Provisional spread: jump-up=2, jungle=2, liquid=2, neurofunk=2.
- **Operator gate:** confirm/reassign each expanded sentinel by ear into {neurofunk, jungle, jump-up, liquid} before Story 7.6 consumes them.
- Non-DnB substitution is forbidden; every expanded track is DnB (150-180 BPM, Strong/Solid).

## Expanded sentinels (8)

| track_id | name | bpm_truth | truth_conf | provisional subgenre | rationale |
|---|---|---|---|---|---|
| 153359729 | Loon of Doom | 172.562 | 0.72 | jungle (provisional) | amen/jungle footprint in playlist/title |
| 65106896 | Dream | 165.64 | 0.721 | jungle (provisional) | amen/jungle footprint in playlist/title |
| 31785840 | BOO | 160.661 | 0.72 | jump-up (provisional) | 'bouncey' playlist vibe (jump-up proxy) |
| 88208891 | Manic Acid Sex Bunny | 169.233 | 0.72 | jump-up (provisional) | 'bouncey' playlist vibe (jump-up proxy) |
| 223853584 | Sinister Sound | 165.818 | 0.72 | neurofunk (provisional) | dark/grumble playlist or >=174 BPM (neuro proxy) |
| 56119162 | HOOVER1A | 160.705 | 0.72 | neurofunk (provisional) | dark/grumble playlist or >=174 BPM (neuro proxy) |
| 34188226 | Gastown | 172.979 | 0.724 | liquid (provisional) | no jungle/jump-up/neuro signal — default provisional (weakest tag) |
| 90949779 | Cloak (Wingz Remix) | 172.36 | 0.712 | liquid (provisional) | no jungle/jump-up/neuro signal — default provisional (weakest tag) |

## Originals (4)

Re-expressed from `Tests/.../Fixtures/4-dnb-triplet-targets.json` (canonical schema v3) — NOT the diverged schema-v1 `_bmad-output/implementation-artifacts/` copy. These are the named DnB half-time failures (Charly/Faraday_Bunker/Yin Yang/HEFT_Anagram), already OA300 held-out eval.

- `The Prodigy - 160 Experience - 06 Charly (Neekeetone Jungle Rework)` — 160.0 BPM (conf 1.0, dawproject)
- `1. The Faraday_Bunker (D-Struct Remix)` — 170.0 BPM (conf 1.0, dawproject)
- `4. Yin Yang Audio_Within Cells Interlinked (Acid Lab Remix)` — 170.0 BPM (conf 1.0, daw_oracle)
- `9. HEFT_Anagram 6 (Owl Remix)` — 170.0 BPM (conf 1.0, daw_oracle)

