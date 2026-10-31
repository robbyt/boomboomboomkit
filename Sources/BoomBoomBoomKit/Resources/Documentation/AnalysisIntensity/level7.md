---
id: level7
title: Level 7: Default (three regions)
---
**What it does.** Runs the _optimal_ technique set on up to three disjoint 30-second rhythmic regions. The default window-voting policy selects a BPM supported by at least two regions when possible, then falls back to the strongest result. This is the library's measured default, aliased _AnalysisIntensity.default_. With _useRhythmicRegions_ disabled, it uses the historical 30-, 60-, and 90-second windows from one energy-transition anchor. The selected rhythmic regions are separate stretches of decoded audio, while historical windows share that anchor and may overlap. _ComputeBudget_ remains reserved and uniform, so the third region provides the extra DSP work.

**When to pick it.** Choose it for the measured default BPM path, especially when an introduction may lack a clear pulse. The selector searches for repeatable rhythmic sections inside the decoded cap. It reports one BPM for the track and does not infer tempo changes. The beat grid is analyzed separately, with its own anchor. This level is DSP-only unless an ML technique is supplied. In Swift, _case .default:_ matches this level through expression-pattern equality; it does not make a switch exhaustive on its own.

**Tradeoff.** Three regions cost more than one, and agreement can still be wrong if several regions lock to the same octave error. When all regions disagree, the policy falls back to the most confident single result. A short clip may offer only one or two disjoint regions, reducing the opportunity for a majority vote. The default does not guarantee that the BPM and the separately anchored beat grid agree. Levels 8-10 reuse this DSP path unless ML is supplied.
