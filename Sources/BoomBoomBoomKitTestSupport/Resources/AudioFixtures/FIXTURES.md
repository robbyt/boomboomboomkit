# Audio fixture manifest

Provenance and ground-truth tempos for the audio files in this directory. These files are
compiled into the `BoomBoomBoomKitTestSupport` resource bundle and are redistributed with
the package.

**This manifest records what is known, and is explicit about what is not.** Four distinct
things are tracked separately below, because conflating them is how unfounded rights
claims get made:

1. **Provenance attested by C2PA** — a cryptographic signature identifying a signer. It
   authenticates an assertion about origin. It is *not* a licence and grants no rights.
2. **Human knowledge about generation** — what the repository owner knows about how a file
   came to exist. Reliable, but not independently verifiable from the file.
3. **Redistribution authority** — the actual basis on which a file may be shipped. For
   owner-authored and owner-synthesized work this is authorship. For the five generated
   MP3s it is the owner's judgement as the generating account holder, not documented
   output terms (see Open items).
4. **Unknown provenance** — files whose origin was never recorded. **This category is
   currently empty.** It held nine files until 2026-07-28, when the owner recorded that
   he synthesized them; the category is kept because it is the honest destination for any
   future file whose origin nobody wrote down.

Every file now has a stated origin. What is *not* claimed is that every file rests on a
documented licence: the five generated MP3s rest on the owner's judgement, which is
recorded as such rather than presented as more than it is.

## Ground-truth tempos

The tempos below are the reference values used by the accuracy floor in
`Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift`. They are ground truth
established independently of this library. A value produced by running
`AudioAnalysisService` against a fixture is **not** ground truth and must never be
promoted into this table: doing so would turn the accuracy floor into a change
detector that enshrines whatever error the analyzer currently makes.

| Fixture | BPM | How established |
|---|---|---|
| `bpm-85-click.wav` | 85 | By construction (synthesized at this tempo) |
| `bpm-120-click.wav` | 120 | By construction |
| `bpm-120-downbeat.wav` | 120 | By construction |
| `bpm-140-click.wav` | 140 | By construction |
| `bpm-170-click.wav` | 170 | By construction |
| `Meta_Man.mp3` | 92 | Human-verified by the repository owner, 2026-07-24 |
| `Meta_Man_La_Noche_Digital_.mp3` | 96 | Human-verified, 2026-07-24 |
| `Meta_Man_Είσαι_η_Λύση_.mp3` | 128 | Human-verified, 2026-07-24 |
| `Quantum_Cascade.mp3` | 170.3 | Human-verified, 2026-07-24. Non-integer, which is atypical for the genre |
| `Submerged_Lament.mp3` | 70 | Human-verified, 2026-07-24 |
| `robbyt_x-ray-30s.mp3` | 174 | Known by the author (own composition) |
| `robbyt_x-ray-120s.mp3` | 174 | Same source track as above |

Fixtures not listed have no established tempo and are not used by the accuracy floor.
Most are one-second or five-second format-coverage assets where tempo is meaningless.

## Provenance

### Owner's own work

| Fixture | Detail |
|---|---|
| `robbyt_x-ray-30s.mp3`, `robbyt_x-ray-120s.mp3` | "robbyt - x-ray", composed and owned by the repository owner; master by Fanu. Encoded from the owner's source WAV to 224 kbps MP3, first 30 s and first 120 s respectively, with source metadata stripped via `-map_metadata -1`. **Redistribution authority: composition authorship — with one unresolved aspect.** The track was mastered by a third party (Fanu). Authorship of the composition does not by itself document authority over someone else's master recording; that permission is not recorded here. Treated as owner-controlled on the owner's judgement, same posture as the generated MP3s below. Note the encoder still writes its own `TSSE` / `Lavf` tag — "stripped" means source metadata and BPM tags, not a byte-level absence of all frames. |

Metadata is stripped deliberately. An embedded `TBPM` tag would feed
`MetadataCorroborator` on the default analysis path, and the accuracy floor would then
be measuring the tag rather than the DSP.

### Generated audio (C2PA-attested)

| Fixture | Detail |
|---|---|
| `Meta_Man.mp3`, `Meta_Man_La_Noche_Digital_.mp3`, `Meta_Man_Είσαι_η_Λύση_.mp3`, `Quantum_Cascade.mp3`, `Submerged_Lament.mp3` | **Attested (category 1):** each embeds a C2PA manifest whose signer identifies as Google (verified 2026-07-24 by inspecting the embedded block). This authenticates a provenance assertion and nothing more. **Known (category 2):** the repository owner generated these with a Google audio-generation service. **Redistribution authority (category 3): NOT YET RECORDED** — see Open items. The C2PA signature is not a licence, and the specific service and its output terms have not been written down here. |

### Synthesized for this repository (tooling-generated)

| Fixture | Detail |
|---|---|
| `vorbis-decodable.ogg` | 7,396 bytes. 1.001 s, 440 Hz sine, stereo 44.1 kHz, Vorbis-in-Ogg. Generated 2026-07-25 with ffmpeg 8.1.2 using its **native** `vorbis` encoder (`libvorbis` is absent from this build), and validated with `ffprobe` at authoring time (`codec_name=vorbis`, `format_name=ogg`). Stereo because the native encoder supports only 2 channels. **Redistribution authority: synthesized tone, no third-party content** (category 2 + 3). SHA-256 `0c8ea05c7058779a110f8650f668e33d6bc475657834f5ed867ec6c6241eaca7`. <br><br>Purpose: the library documented in four places that OGG/Vorbis could not be decoded. GH-167 item 5 measured it and found the claim false — AVFoundation decodes this file cleanly on macOS 26. The fixture pins that actual behaviour. Command: <br>`ffmpeg -f lavfi -i "sine=frequency=440:duration=1:sample_rate=44100" -c:a vorbis -strict -2 -ac 2 -map_metadata -1 vorbis-decodable.ogg` |

### Synthesized by this project

| Fixture | Detail |
|---|---|
| `bpm-85-click.wav`, `bpm-120-click.wav`, `bpm-120-downbeat.wav`, `bpm-140-click.wav`, `bpm-170-click.wav` | Synthetic click tracks, 10 s mono 44.1 kHz Int16. Shape matches `TestSignalGenerators.generateClickTrack(bpm:sampleRate:durationSeconds:)`. No third-party content. |

### Derived from other fixtures in this directory

| Fixture | Detail |
|---|---|
| `test-bwf.caf` | `afconvert -f caff -d LEI16` from `test-bwf.wav` (Story 8-1 DD #13; `sample.wav` was rejected as the source because it is 8 kHz) |
| `test-alac.m4a` | `afconvert`-generated ALAC-in-M4A, for the codec mis-tagging case (Story 8-2 AC6) |
| `test-ulaw.caf` | `afconvert`-generated mu-law, for the unmapped-codec fallback (Story 8-2 AC6) |

### Synthesized by the owner (recorded retroactively)

These were added in the initial commit (`468a7b3`, 2026-03-21) before the provenance
requirement existed, so nothing was written down at the time. **The repository owner
states (recorded 2026-07-28) that all of them were synthesized by him, directly or with
ffmpeg.** That is category 2 knowledge — reliable, but not independently verifiable from
the files themselves, which carry no attestation. Redistribution authority (category 3)
follows from it: synthesized content, no third-party material.

- `sample.wav` (1 s, 8 kHz — the unsupported-sample-rate throw case)
- `sample-with-cover.aiff`, `sample-with-cover.flac`, `sample-with-cover.m4a`, `sample-with-cover.mp3`
- `sample-without-cover.flac`
- `test-audio.flac`, `test-audio.m4a`
- `test-bwf.wav`

All are short (1–5 s), low-complexity format-coverage assets exercising sample-rate,
container, cover-art and codec paths; content is irrelevant to what they test. If the
statement above is ever doubted, regenerating them from synthesized tone would settle it
without cost — each one's tested property (8 kHz rate, cover-art present or absent, BWF
chunk) is reproducible.

## Open items

- **Redistribution basis for the five C2PA/Google-generated MP3s rests on the owner's
  judgement, not on documented terms.** Decision recorded 2026-07-28: they ship on the
  repository owner's judgement as the account holder who generated them. This is stated
  plainly rather than dressed up as a licence, because the two are not the same thing.

  What would close it properly is the specific generating product and its output terms.
  Inspecting the embedded C2PA block does not supply that: the certificate chain
  identifies the *signer* — `Google LLC`, `Google Media Processing Services`, under
  `Google C2PA Media Services 1P ICA G3` — and signing attests origin, not permission.
  No Google product name appears anywhere in the manifest.

  If the basis is ever challenged, the fallback is replacing these five, which would cut
  the accuracy floor's real-music coverage from 5 tracks to 2. Tracked as the licensing
  half of issue #159.

- ~~Nine fixtures have unrecorded provenance.~~ **Closed 2026-07-28** by the owner's
  statement recorded under "Synthesized by the owner" above.

## Rules for adding a fixture

1. **Keep it small.** Prefer the shortest clip that exercises the path. For negative
   tests, that can be a header and a few bytes.
2. **No copyrighted material.** Synthesized, generated, or owner-authored audio only.
3. **Record it here** before committing: origin, rights, and — if it carries a tempo —
   how that tempo was established, independently of this library.
4. **Strip metadata** on anything the accuracy floor consumes.
