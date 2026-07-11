import BoomBoomBoomKit
import SwiftUI

/// Subordinate loudness panel (Story 10.4, FR-40 + FR-44): integrated LUFS as
/// the primary number with true-peak and loudness-range as labeled secondary
/// context. Scalars only — the momentary/short-term series + `report.samples`
/// Swift Charts adapter are out of scope.
///
/// The pure formatters + `windowCaption` are `nonisolated static` so the CI
/// tests read them off the main actor without a running UI (the demo builds
/// with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; mirrors
/// `BeatGridView.tempoValue` / `SignalPoolDiagnostics`).
struct LUFSReadoutView: View {

  /// The loudness report to render.
  let report: LUFSReport

  /// The `maxSeconds` the analysis used — needed for the honest measurement
  /// caption (DD7). `0` (or non-finite) yields the plain "Integrated loudness"
  /// caption via `windowCaption`'s guard.
  let analysisWindowSeconds: Double

  // Single scaling basis (AC2): one `@ScaledMetric` primary size + a fixed
  // fraction for the secondary, so the ≥2x ratio holds across Dynamic Type
  // (mirrors the BPM hero's `@ScaledMetric` at `ContentView.swift:53`).
  @ScaledMetric(relativeTo: .largeTitle) private var primarySize: CGFloat = 34

  // ~2.3x smaller than the primary — comfortably above the AC2 >=2x floor.
  private var secondarySize: CGFloat { primarySize / 2.3 }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      // Primary: a small field-label caption above the large value line
      // (field-labeled AND unit-carrying — FR-44 never a bare number).
      VStack(alignment: .leading, spacing: 2) {
        Text(Self.windowCaption(report: report, analysisWindowSeconds: analysisWindowSeconds))
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(Self.integratedValue(report.integratedLUFS))
          .font(.system(size: primarySize, weight: .semibold).monospacedDigit())
          .lineLimit(1)
          .minimumScaleFactor(0.6)
      }

      // Secondary: two leading-labeled rows.
      VStack(alignment: .leading, spacing: 4) {
        // The library measures true peak POST-mono-mixdown (LUFSReport.maxTruePeakDBTP
        // Warning): it can understate per-channel inter-sample peaks and is NOT a
        // delivery-compliance value. Surface that honestly via a macOS help tag +
        // accessibility hint so the plain "True peak" number isn't misread as a
        // certified ceiling (the same measurement-honesty discipline as DD7).
        secondaryRow(label: "True peak", value: Self.truePeakValue(report.maxTruePeakDBTP))
          .help(
            "Measured after mono mixdown — may understate per-channel peaks; not a delivery-compliance value."
          )
        secondaryRow(
          label: "Loudness range", value: Self.loudnessRangeValue(report.loudnessRangeLU))
      }
      .font(.system(size: secondarySize))
      .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func secondaryRow(label: String, value: String) -> some View {
    HStack(spacing: 4) {
      Text("\(label):")
      Text(value).monospacedDigit()
    }
  }

  // MARK: - Measurement window (pure, unit-tested — DD7)

  // ITU-R BS.1770 momentary window (fixed 400 ms). `LUFSReport` exposes
  // `stepSeconds` but not the block length; the standard fixes it at 400 ms,
  // so hardcoding it is honest — prefer a report field if the library ever
  // exposes one.
  private nonisolated static let momentaryBlockSeconds: Double = 0.4

  /// The FR-44 field-label caption for the integrated value, honest about the
  /// analyzed window (DD7). The momentary series is 400 ms ITU blocks on a
  /// 100 ms grid, so `count * stepSeconds` UNDER-counts the span by ~0.3 s;
  /// the true span is the END of the last block: `(count - 1) * stepSeconds +
  /// 0.4`. When that span reached the analysis budget (within one hop of the
  /// integer-count quantization) the file was truncated -> "(first N s)";
  /// otherwise the window covered the whole file -> plain caption.
  nonisolated static func windowCaption(report: LUFSReport, analysisWindowSeconds: Double)
    -> String
  {
    let count = report.momentaryLUFS.count
    guard analysisWindowSeconds.isFinite, analysisWindowSeconds > 0, count >= 1 else {
      return "Integrated loudness"
    }
    let measured = Double(count - 1) * report.stepSeconds + Self.momentaryBlockSeconds
    if measured >= analysisWindowSeconds - report.stepSeconds {
      return "Integrated loudness (first \(Int(measured.rounded())) s)"
    }
    return "Integrated loudness"
  }

  // MARK: - Value formatters (pure, unit-tested — FR-44 + sentinel discipline)

  /// `%.1f LUFS`, or `unavailable` when non-finite or at/below the `-100.0`
  /// sentinel floor (silence / non-measurable — never a `-100.0 LUFS` leak).
  nonisolated static func integratedValue(_ lufs: Double) -> String {
    guard lufs.isFinite, lufs > LUFSReport.sentinelFloor else { return "unavailable" }
    return String(format: "%.1f LUFS", lufs)
  }

  /// `%.1f dBTP`, or `unavailable` under the same non-finite / at-or-below-
  /// sentinel guard.
  nonisolated static func truePeakValue(_ dbtp: Double) -> String {
    guard dbtp.isFinite, dbtp > LUFSReport.sentinelFloor else { return "unavailable" }
    return String(format: "%.1f dBTP", dbtp)
  }

  /// `%.1f LU`, or `unavailable` when the value is `nil` (LRA absent — gated
  /// programme < 60 s), non-finite, or at/below the sentinel floor.
  nonisolated static func loudnessRangeValue(_ lra: Double?) -> String {
    guard let lra else { return "unavailable" }
    guard lra.isFinite, lra > LUFSReport.sentinelFloor else { return "unavailable" }
    return String(format: "%.1f LU", lra)
  }
}

// MARK: - Previews (operator macOS Dynamic Type GUI-smoke, AC6)

#Preview("Whole-file loudness") {
  LUFSReadoutView(
    report: LUFSReport(
      integratedLUFS: -14.2,
      maxTruePeakDBTP: -1.0,
      loudnessRangeLU: 6.0,
      lraLowLUFS: -18.0,
      lraHighLUFS: -12.0,
      // ~30 s of momentary blocks -> whole-file at a 120 s window (plain caption).
      momentaryLUFS: Array(repeating: -14.0, count: 297),
      shortTermLUFS: [],
      stepSeconds: 0.1),
    analysisWindowSeconds: 120
  )
  .padding()
  .frame(width: 320)
}

#Preview("Truncated long file, LRA absent (AX1)") {
  LUFSReadoutView(
    report: LUFSReport(
      integratedLUFS: -9.6,
      maxTruePeakDBTP: -0.3,
      loudnessRangeLU: nil,
      lraLowLUFS: -100.0,
      lraHighLUFS: -100.0,
      // 120 s of momentary blocks -> truncated at a 120 s window ("(first 120 s)").
      momentaryLUFS: Array(repeating: -9.5, count: 1197),
      shortTermLUFS: [],
      stepSeconds: 0.1),
    analysisWindowSeconds: 120
  )
  .padding()
  .frame(width: 320)
  .environment(\.dynamicTypeSize, .accessibility1)
}
