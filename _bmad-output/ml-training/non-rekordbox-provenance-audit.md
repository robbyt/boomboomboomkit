# Non-Rekordbox provenance audit (Story 7.2, FR-13/FR-15)

The tier decision is made by the pure typed function `decide_tier(dsp_bpm, dsp_confidence, file_metadata_bpm, audio_hash)` — the four arguments are the ONLY signals in scope. The following are forbidden as tiering evidence and do not appear in the tiering code path:

- `path / relPath components`
- `parent directory names`
- `Rekordbox XML track IDs`
- `playlist membership`
- `DSP candidate scores`
- `artist embedding`
- `ID3 BPM as a model feature`

## Membership vs tiering evidence (DD #1)

The Rekordbox `<COLLECTION>` is consulted ONLY to PARTITION the universe (in-collection vs non-Rekordbox) — set membership, not a per-file tiering signal. FR-13/FR-15 forbid Rekordbox-derived signals as tiering evidence (the tier decision), never as the boundary that scopes the expansion set.

## Grep verification

Run against the tiering module body AND every `decide_tier` call-site argument expression — expected zero hits:

```
rg -i 'playlist|path|rekordbox|artist|id3' scripts/non-rekordbox-survey.py \
    | rg -i 'decide_tier|def decide_tier|tier ='
```

The four `decide_tier` arguments at the single call site are sourced only from `{dspBPM, dspConfidence, fileMetadataBPM, audioHash}` (AC6).

