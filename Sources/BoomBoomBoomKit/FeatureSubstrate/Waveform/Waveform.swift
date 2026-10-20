//
//  Waveform.swift
//  BoomBoomBoomKit
//
//  Story 15.4 (Epic 15, Phase 4): public namespace for independent waveform
//  analysis. Covers the detail envelope, peak-preserving overview, and
//  three-band energy channels.
//
//  Rekordbox-independent: no on-disk mimicry (PWV4 chunk tags, byte layouts,
//  etc.), no dependency on `RekordboxReader`, and no SwiftUI consumer. Each
//  output is a pure Sendable value type with explicit per-bin timing so a
//  consumer can draw against the library's own playback timeline.
//

/// Public namespace holding the Story-15.4 waveform data types and the
/// analyzer that produces them.
///
/// Each output carries an explicit ``WaveformDetailEnvelope/schemaVersion``
/// (currently `"v1"`) and an ``WaveformDetailEnvelope/algorithmIdentifier``
/// naming the exact envelope / overview / split code path. The three outputs
/// share a bin grid, so a consumer can align them without resampling.
///
/// Default bin cadence is 150 columns per second (configurable). Bin
/// boundaries use integer sample positions so a short file ending mid-bin
/// keeps a correctly-sized final partial bin (no float accumulation drift).
public enum Waveform {}
