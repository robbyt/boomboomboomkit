# Story 15.8 notes: what the corpus .dawproject retains, and the annotation convention

Date: 2026-10-21. Scope: `${OA300_CORPUS_PATH}/corpus/corpus.dawproject`, the hand-annotated OA300 DAW oracle source. The comparison file `other-bpms.dawproject` is the project behind the training labels and is read here only to check what the exporter preserves.

## Summary

- The corpus file declares no downbeat today. Every clip carries a tempo warp (origin and end of file) and nothing else that names a bar line.
- Bitwig's DAWproject export keeps every warp point a clip has (up to 48 per clip in `other-bpms.dawproject`), so a beat marker the operator snaps to a bar line survives the save as a `Warp` with clip-beat `time` and original-audio-seconds `contentTime`.
- No sidecar file is needed. The annotation lives in the `.dawproject`: two or more bar-line warps at bar 2 or later, plus an optional track comment.
- With the file as it is today, `scripts/dawproject-annotations.py` writes `{"entries": []}`: 23 clips skip with `no-declared-downbeat-anchor`, 9 with `unmatched-ground-truth`, exit 0.

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
| `Warp` (`time`, `contentTime`) | One point of the map from clip beats to original-audio seconds. `time` is in clip beats (`Warps@timeUnit="beats"`), `contentTime` in audio seconds (`Warps@contentTimeUnit="seconds"`). | Yes, once the operator places bar-line warps. `contentTime` is already in the original-audio frame, so a bar-line warp gives the downbeat time directly and a pair gives the span and its BPM. Today no warp qualifies (see the three-point reading). |
| `Warps` | Container for the warp list, the `Audio` element and the two unit attributes. | Carries the units the rule depends on; no timing of its own. |
| Outer `Clip` (`time`, `duration`, `playStart`, `loopStart`, `loopEnd`, `name`, `enable`) | Where the clip sits in the arrangement and which part plays. All 32 outer clips start at arrangement beat 0. | No. These select and shift what the arrangement plays. They do not change the warp map from clip beats to audio seconds. |
| Inner `Clip` (`time`, `duration`, `contentTimeUnit="beats"`, `playStart`) | The audio content inside the outer clip. Five carry a small `time` offset. | No. The offset is a phase nudge that lines a beat up with the project grid. It does not say which beat is a downbeat, and it shifts the arrangement position, not the warp map. |
| `Audio` (`duration`, `sampleRate`, `channels`, `algorithm`) | The decoded file's length and format. All 32 use `algorithm="repitch"`. | Supplies the end-of-file bound: a warp at `contentTime == duration` is the end marker, never an anchor. |
| `File@path` | The audio path inside the zip, e.g. `audio/x.wav`. | Identity only. Its basename joins the clip to the OA300 ground truth. |
| `Track` (`name`, `comment`) | Track name and a free-text comment, both editable in Bitwig's Inspector. All comments are empty today. | Not timing. The comment is the one per-track text field that round-trips, so it carries the optional metrical level and uncertainty. |
| `Transport` (`Tempo`, `TimeSignature`) | Project tempo (150 BPM) and a 4/4 meter. | No downbeat. The meter is checked so a bar is four beats. |
| `Markers` / `Marker` | Absent. The schema (`Project.xsd`) allows one optional `Markers` under `Arrangement`; a `Marker` has only `name`, `color`, `comment` and `time`. `Markers` inherits an optional `track` attribute from `timeline`, but there is one `Markers` per arrangement, not one per track. | No. With every clip starting at arrangement beat 0, an arrangement cue marker cannot carry an anchor for each of 32 tracks. Whether Bitwig exports cue markers at all was not verified. |
| `TimeSignatureAutomation` | Absent. | Not a timing source. Its presence would make "a bar is 4 beats" false, so the extractor skips every clip when it appears. |

## The three-point warps

Eight clips have a warp between the origin and the end of file. In every case it is collinear with the other two: the two segment BPMs agree within 0.007 BPM. Five sit at 0.986 to 0.999 beats (`10. Hellacopta`, `03 TVR`, `Fixate - Conundrum`, `Icicle - Condense`, `Nautical Divine - Makara`), and three are sub-beat transient nudges at 0.046, 0.141 and 0.188 beats. None is at a bar line at bar 2 or later, so none is a downbeat anchor. They read as leftovers from placing the first beat, not as a declared downbeat.

## Correction to the guidance

`../rekordboxReader/docs/rekordbox-analysis/FINDINGS.md`, item 5 (line 71), says the current SOP "already anchors a DAW grid at a stable downbeat and locks at least 32 beats". That is wrong for the current files. The corpus `.dawproject` holds a tempo warp per clip and a phase nudge on five clips; nothing in it declares a downbeat. The sibling repository is left for the operator to correct.

## Annotation convention (operator SOP)

Per clip, in Bitwig's clip audio editor:

1. Keep the tempo warp as it is now.
2. Find a downbeat you have verified by ear. Add a beat marker there and snap it to a bar line at bar 2 or later.
3. Find a second verified downbeat at least 8 bars further on. Add a beat marker and snap it to its bar line.
4. Optionally add more bar-line markers between the two. Each one is reported as an alignment check.
5. Never leave an unsnapped marker between the first and the last bar-line marker. A transient nudge inside the span skips the clip.
6. Optionally, in the Inspector's track Comment field, type `level=half; unc=low; any note`. `level` is one of `quarter`, `half`, `double`; `unc` is one of `low`, `medium`, `high`; any other text becomes the uncertainty note. Typing `level=` or `unc=` twice skips the clip with `invalid-comment-token`, and a comment holding only `level=` and `unc=` keys gets the note `derived from bar-line warp pair`.

Limitation: the file carries no separate downbeat flag. By convention a bar-line warp at bar 2 or later IS the downbeat declaration. A bar-line warp placed for another reason would be read as a downbeat.

## Parse rule (as implemented)

Per clip, on the clip-local `Warps` timeline:

- Warp hygiene first: every `time` and `contentTime` parses as a finite float, the list is sorted by `time`, both columns are strictly increasing, and `Audio@duration` is finite and positive. Otherwise `warps-not-monotonic`.
- A warp is an anchor iff it lies within 0.02 beats of a bar line (`|time/4 - round(time/4)| * 4 <= 0.02`), its bar index `b = round(time / 4)` (0-based) is at least 1, so bar 2 or later under the same tolerance (3.99994 beats counts as bar 2), and `0 < contentTime < Audio@duration - 1e-6`. The origin warp, the end-of-file warp and sub-beat nudges never qualify. `bar_position = b + 1`, the clip-local bar number.
- `A1` is the first anchor, `A2` the last. Fewer than two anchors: `no-declared-downbeat-anchor`. `b2 - b1 < 8`: `verified-span-shorter-than-8-bars`. Any warp strictly between them that is not an anchor: `unverified-warp-inside-span`.
- `reference_downbeat_time_sec = verified_span_start_sec = A1.contentTime`, `verified_span_end_sec = A2.contentTime`, `verified_bpm = (A2.time - A1.time) / (A2.contentTime - A1.contentTime) * 60`.
- Each anchor strictly between `A1` and `A2` is an entry in `distant_alignment_checks` with `residual_ms`, the gap between its `contentTime` and the time the `A1` to `A2` line predicts. Reported, not gated.
- `playStart`, `playStop`, `loopStart`, `loopEnd` and the inner clip `time` are ignored: they do not change the warp map.
- A non-4/4 project, or one with `TimeSignatureAutomation`, skips every clip with `time-signature-not-4-4`.

The 0.02-beat tolerance is about 7 ms at 170 BPM, well inside what reads as snapped, and far from the 0.986-beat legacy points.

## Output

`${OA300_CORPUS_PATH}/daw-oracle-annotations.json`, operator-local like `daw-oracle.json` and never committed. One JAMS entry per annotated track, with oracle-style `identifiers`, a `tempo` observation covering only the verified span, a `beat_position` observation per anchor from `A1` to `A2`, and the eight fields plus `annotation_version: "15.8.v1"` in `sandbox`. No field describes a beat outside the span. Regenerate with `make oracle-generate-annotations`; verify with the same command line plus `--check`.

## Evidence

The counts above come from the committed inventory in `15-8-evidence/`:

- `15-8-evidence/analyze.py`: stdlib script that writes one CSV row per `Warps` element of a `project.xml` (unzip the `.dawproject` first; `uv run analyze.py <project.xml> <out.csv>`).
- `15-8-evidence/corpus-clips.csv`: its output for the corpus `.dawproject` (32 clips).
- `15-8-evidence/other-clips.csv`: its output for `other-bpms.dawproject` (195 clips).

Re-running `analyze.py` on both `project.xml` files on 2026-10-21 reproduced both CSVs byte for byte. The element and attribute facts about `Marker`, `Markers` and `timeline` come from the DAWproject schema, `Project.xsd`, at https://github.com/bitwig/dawproject.
