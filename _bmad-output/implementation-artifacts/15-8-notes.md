# Story 15.8 notes: what the corpus .dawproject retains, and the annotation convention

Date: 2026-10-21. Scope: `${OA300_CORPUS_PATH}/corpus/corpus.dawproject`, the hand-annotated OA300 DAW oracle source. The comparison file `other-bpms.dawproject` is the project behind the training labels and is read here only to check what the exporter preserves.

## Summary

- The corpus file declares no downbeat today. Every clip carries a tempo warp (origin and end of file) and nothing else that names a bar line.
- Bitwig's DAWproject export keeps every warp point a clip has (up to 48 per clip in `other-bpms.dawproject`), so a beat marker the operator snaps to a bar line survives the save as a `Warp` with clip-beat `time` and original-audio-seconds `contentTime`.
- No sidecar file is needed. The annotation lives in the `.dawproject`: the clip offset that places a verified downbeat on an arrangement bar line, plus a `bar=` token in the track comment (convention "15.8.v2", below).
- With the file as it is today, `scripts/dawproject-annotations.py` writes `{"entries": []}`: 23 clips skip with `no-declared-downbeat-bar`, 9 with `unmatched-ground-truth`, exit 0.

## Provenance and counts

| Fact | Value |
|---|---|
| Writer (`Application`) | Bitwig Studio 6.0.11 (corpus); Bitwig Studio 6.0.8 (`other-bpms.dawproject`) |
| `Track` elements | 38 (32 `audio`, 5 `tracks` groups, 1 master) |
| Arrangement audio clips with `Warps` | 32; all 32 `Warps` sit under `Arrangement` |
| Non-empty `comment` attributes | 0 (38 on `Track`, 8 on `Scene`, all empty) |
| `Marker` / `Markers` elements | 0 / 0 |
| `TimeSignatureAutomation` | absent; `Transport/TimeSignature` is 4/4 |
| Clips with two warps (origin and end of file) | 24 |
| Clips with a third warp | 8 |
| Clips whose last `contentTime` equals `Audio@duration` | 32 of 32 |
| Inner clips with a non-zero `time` | 5 (-0.186 to +0.008 beats, about -79.8 to +7.2 ms at each clip's tempo) |
| Outer clips with `loopStart` / `loopEnd` | 3 |
| `other-bpms.dawproject` | 195 clips, up to 48 warps per clip |

The 9 unmatched clips are the nine `.flac` tracks numbered `01` to `09`, which have no OA300 ground-truth row. Both `5. Darkgray Heart ... .mp3` and `.wav` are separate ground-truth rows, so the duplicate-match rule does not fire on the current file; it exists for a stem that appears twice under different extensions with one ground-truth row.

## Element inventory

For each element: what it holds, and whether it can recover `reference_downbeat_time_sec` and the verified stable span.

| Element | What it holds | Downbeat and verified span? |
|---|---|---|
| `Warp` (`time`, `contentTime`) | One point of the map from clip beats to original-audio seconds. `time` is in clip beats (`Warps@timeUnit="beats"`), `contentTime` in audio seconds (`Warps@contentTimeUnit="seconds"`). | Yes, under 15.8.v2, as the conversion step. The warp map, linear between consecutive warps, turns the content beat of a declared bar line into original-audio seconds, which gives the downbeat time, the span ends and the BPM. A warp inside the verified span that sits on an arrangement bar line is an alignment check; any other warp there skips the clip. |
| `Warps` | Container for the warp list, the `Audio` element and the two unit attributes. | Carries the units the rule depends on; no timing of its own. |
| Outer `Clip` (`time`, `duration`, `playStart`, `loopStart`, `loopEnd`, `name`, `enable`) | Where the clip sits in the arrangement and which part plays. All 32 outer clips start at arrangement beat 0. | Yes, under 15.8.v2. `time` and `playStart` are part of the clip offset that places a content beat on an arrangement bar line; with the `bar=` token they name the downbeat. They do not change the warp map from clip beats to audio seconds. `loopStart` and `loopEnd` are ignored. |
| Inner `Clip` (`time`, `duration`, `contentTimeUnit="beats"`, `playStart`) | The audio content inside the outer clip. Five carry a small `time` offset. | Yes, under 15.8.v2. The `time` offset is a phase nudge that lines a beat up with the project grid; it enters the clip offset with the outer clip's values. On its own it does not say which beat is a downbeat; the `bar=` token does. |
| `Audio` (`duration`, `sampleRate`, `channels`, `algorithm`) | The decoded file's length and format. All 32 use `algorithm="repitch"`. | Supplies the end-of-file bound: a warp at `contentTime == duration` is the end marker, never an anchor. |
| `File@path` | The audio path inside the zip, e.g. `audio/x.wav`. | Identity only. Its basename joins the clip to the OA300 ground truth. |
| `Track` (`name`, `comment`) | Track name and a free-text comment, both editable in Bitwig's Inspector. All comments are empty today. | Yes, under 15.8.v2, as the declaration. The comment is the one per-track text field that round-trips. It carries the required `bar=<N>` token (optionally `bar=<N>-<M>`) that names the downbeat bar, plus the optional `level`, `unc` and free note. |
| `Transport` (`Tempo`, `TimeSignature`) | Project tempo (150 BPM) and a 4/4 meter. | No downbeat. The meter is checked so a bar is four beats. |
| `Markers` / `Marker` | Absent. The schema (`Project.xsd`) allows one optional `Markers` under `Arrangement`; a `Marker` has only `name`, `color`, `comment` and `time`. `Markers` inherits an optional `track` attribute from `timeline`, but there is one `Markers` per arrangement, not one per track. | No. With every clip starting at arrangement beat 0, an arrangement cue marker cannot carry an anchor for each of 32 tracks. Whether Bitwig exports cue markers at all was not verified. |
| `TimeSignatureAutomation` | Absent. | Not a timing source. Its presence would make "a bar is 4 beats" false, so the extractor skips every clip when it appears. |

## The three-point warps

Eight clips have a warp between the origin and the end of file. In every case it is collinear with the other two: the two segment BPMs agree within 0.007 BPM. Five sit at 0.986 to 0.999 beats (`10. Hellacopta`, `03 TVR`, `Fixate - Conundrum`, `Icicle - Condense`, `Nautical Divine - Makara`), and three are sub-beat transient nudges at 0.046, 0.141 and 0.188 beats. None is at a bar line at bar 2 or later, so none is a downbeat anchor. They read as leftovers from placing the first beat, not as a declared downbeat.

## Correction to the guidance

`../rekordboxReader/docs/rekordbox-analysis/FINDINGS.md`, item 5 (line 71), says the current SOP "already anchors a DAW grid at a stable downbeat and locks at least 32 beats". That is wrong for the current files. The corpus `.dawproject` holds a tempo warp per clip and a phase nudge on five clips; nothing in it declares a downbeat. The sibling repository is left for the operator to correct.

## Annotation convention (operator SOP)

Per clip, in the Bitwig Arranger:

1. Keep the tempo warp (the BPM annotation) as it is.
2. Find a downbeat you have verified by ear. With grid snap on, slide the clip, or slip its content, so that downbeat sits on an arrangement bar line. Any bar works.
3. In the Inspector's track Comment field, type `bar=<N>` with the ruler bar number you placed it on. Optionally type `bar=<N>-<M>` to bound the verified span; M must be at least 8 bars after N. Optionally add `level=<quarter|half|double>`, `unc=<low|medium|high>` and a free note, separated by `;`, for example `level=quarter; unc=low; bar=49; bass drops on 49`.
4. Do not add stretch markers inside the verified span.

Without M the span runs from bar N to the last arrangement bar line strictly inside the audio. A bar-line stretch marker inside the span is reported as an alignment check; any other stretch marker inside it skips the clip, and `bar=<N>-<M>` can narrow the span to exclude it.

Limitation: the `bar=` token is the only declaration. A clip slid for another reason without the token is not annotated, and a clip with the token is read as declaring a downbeat on bar N whether or not the slide was placed with care.

### Real export check (W102)

The operator annotated one clip in `hand-annotated-training.dawproject` (track `e3-22fffe3b2c53`, 140 BPM) and exported it from Bitwig Studio 6.1.4. The export showed:

- The push-out is saved as the outer clip's `playStart="-62.3652"` (outer `time="0.0"`, inner `time="0.0"` and `playStart="0.0"`). The warp list is unchanged: `(0.0, 0.0)` and `(789.6455583572388, 338.419525)`.
- The end warp's `contentTime` equals `Audio@duration` (338.419525).
- No `Markers` element is written.

The convention was replayed against that file with `bar=49` added to the track comment: the offset is 62.3652 beats, bar 49 maps to content beat 129.6348, and the record has `reference_downbeat_time_sec` 55.557791 and `verified_bpm` 140.0. An energy profile of the decoded audio puts the drop at 55.56 s, which settles the sign of the offset.

## Parse rule (as implemented)

Clips are collected once each: every `Warps` under `Arrangement` belongs to its nearest enclosing `Lanes[@track]`, which supplies the track comment and bounds the clip offsets, so nested (grouped) track lanes do not repeat a clip. On the flat Bitwig shape this sees the same clips as `scripts/dawproject-bpm.py`. The track comment declares one downbeat, so every clip of a track that holds more than one audio clip skips with `multiple-clips-on-track` (checked after the time signature, before ground-truth matching).

Per clip:

- Warp hygiene first: every `time` and `contentTime` parses as a finite float, the list is sorted by `time`, both columns are strictly increasing, and `Audio@duration` is finite and positive. Otherwise `warps-not-monotonic`. A `Warps` element whose `timeUnit` is not `beats` or whose `contentTimeUnit` is not `seconds` skips with `warps-not-beats-seconds`.
- The track comment is split on `;`. `bar=<N>` or `bar=<N>-<M>` takes positive integers of 1 to 6 digits with M > N; `level` and `unc` take the values listed in the SOP. A repeated `bar`, `level` or `unc` key, a non-integer, a run of more than 6 digits, N < 1, M <= N, or an unknown `level` or `unc` value skips with `invalid-comment-token`. No `bar=` token, an empty comment included, skips with `no-declared-downbeat-bar`. Keys are case-insensitive; any other token is the uncertainty note.
- `offset_beats = outer.time + inner.time - outer.playStart - inner.playStart`, summed over every `Clip` between the lane and the `Warps` (the outer clip on the lane's `Clips` timeline and the inner clip holding the `Warps`). A missing attribute is 0.0. A non-finite or unparseable value skips with `clip-offset-not-finite`.
- A warp-timeline beat `c` plays at arrangement beat `c + offset_beats`. Arrangement bar N (1-based) is arrangement beat `4 * (N - 1)`, so its content beat is `c_N = 4 * (N - 1) - offset_beats`. Its seconds come from linear interpolation between consecutive warps.
- The start bar line is N. The end bar line is M when given, otherwise the last arrangement bar line whose content seconds are strictly inside the audio and on the warp map. Both must satisfy `0 < seconds < Audio@duration - 1e-6` with the content beat inside the warp map's `time` range, otherwise `declared-bar-outside-audio`. An end bar fewer than 8 bars after N skips with `verified-span-shorter-than-8-bars`.
- Every warp whose content beat lies strictly between the two bar lines must sit on an arrangement bar line, `|(c + offset_beats)/4 - round((c + offset_beats)/4)| * 4 <= 0.02`, otherwise `unverified-warp-inside-span`. A warp within that tolerance of the start or end bar line is that bar line. Two warps on the same interior bar line also skip with `unverified-warp-inside-span`. Each other one is an entry in `distant_alignment_checks` with its arrangement `bar_position` and `residual_ms`, the gap between its `contentTime` and the time the start-to-end line predicts. Reported, not gated.
- `verified_bpm = (c_end - c_start) / (end seconds - start seconds) * 60`. `reference_downbeat_time_sec = verified_span_start_sec` = the seconds of bar N; `verified_span_end_sec` = the seconds of the end bar. `bar_position = N`, the arrangement bar as typed.
- `loopStart`, `loopEnd`, fades, the inner clip's `contentTimeUnit` and `Clip@duration` are ignored.
- A non-4/4 project, or one with `TimeSignatureAutomation`, skips every clip with `time-signature-not-4-4`.

The 0.02-beat tolerance is about 7 ms at 170 BPM, well inside what reads as snapped.

## Output

`${OA300_CORPUS_PATH}/daw-oracle-annotations.json`, operator-local like `daw-oracle.json` and never committed. One JAMS entry per annotated track, with oracle-style `identifiers`, a `tempo` observation covering only the verified span, a `beat_position` observation at the start bar, at each interior bar-line warp and at the end bar (each `measure` an arrangement bar), and the eight fields plus `annotation_version: "15.8.v2"` and `source: "bitwig-clip-offset-bar-comment"` in `sandbox`. No field describes a beat outside the span. Regenerate with `make oracle-generate-annotations`; verify with the same command line plus `--check`.

`--match` is optional. With it, each clip joins to the OA300 ground truth and a clip with no match skips with `unmatched-ground-truth`. Without it, every clip is a candidate and its identifiers are the audio basename. In both modes a basename that repeats after the first clip skips with `duplicate-basename`.

## Evidence

The counts above come from the committed inventory in `15-8-evidence/`:

- `15-8-evidence/analyze.py`: stdlib script that writes one CSV row per `Warps` element of a `project.xml` (unzip the `.dawproject` first; `uv run analyze.py <project.xml> <out.csv>`).
- `15-8-evidence/corpus-clips.csv`: its output for the corpus `.dawproject` (32 clips).
- `15-8-evidence/other-clips.csv`: its output for `other-bpms.dawproject` (195 clips).

Re-running `analyze.py` on both `project.xml` files on 2026-10-21 reproduced both CSVs byte for byte. The element and attribute facts about `Marker`, `Markers` and `timeline` come from the DAWproject schema, `Project.xsd`, at https://github.com/bitwig/dawproject.
