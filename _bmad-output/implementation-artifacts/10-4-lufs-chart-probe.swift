//
//  LUFSChartSchemaProbe.swift
//  BoomBoomBoomBPM
//
//  ARCHIVED ARTIFACT - Story 8.1 schema validation probe, preserved as the
//  seed for Story 10-4 (demo LUFSReadoutView). Not a member of any build
//  target. Originally a working-tree-only scratch in Demo/BoomBoomBoomBPM/;
//  relocated here at Story 8.1 close-out (commit b901608).
//  Verifies the LUFSReport shape plugs into Swift Charts with zero
//  adaptation (rendered via Xcode RenderPreview during Story 8.1).
//

import Charts
import SwiftUI

// MARK: - Proposed Story 8.1 public schema (probe copy)

struct LUFSReportProbe: Sendable {
  // normative scalars
  let integratedLUFS: Double
  let maxTruePeakDBTP: Double
  let loudnessRangeLU: Double?
  let lraLowLUFS: Double  // P10 of short-term (band edge for plotting)
  let lraHighLUFS: Double  // P95 of short-term

  // series on the shared 100ms grid (EBU Tech 3341)
  let momentaryLUFS: [Double]  // 400ms window
  let shortTermLUFS: [Double]  // 3s window
  let stepSeconds: Double  // 0.1

  // Swift Charts adapter - computed, zero stored cost
  var samples: [LoudnessSampleProbe] {
    let momentary = momentaryLUFS.enumerated().map { pair in
      LoudnessSampleProbe(
        time: Double(pair.offset) * stepSeconds, lufs: pair.element, series: .momentary)
    }
    let shortTerm = shortTermLUFS.enumerated().map { pair in
      LoudnessSampleProbe(
        time: Double(pair.offset) * stepSeconds, lufs: pair.element, series: .shortTerm)
    }
    return momentary + shortTerm
  }
}

enum LoudnessSeriesProbe: String, Sendable, Hashable {
  case momentary = "Momentary"
  case shortTerm = "Short-term"
}

struct LoudnessSampleProbe: Sendable, Identifiable, Hashable {
  var id: String { "\(series.rawValue)@\(time)" }
  let time: Double
  let lufs: Double
  let series: LoudnessSeriesProbe
}

// MARK: - Synthetic track: quiet intro, loud middle, breakdown, loud, outro

private func syntheticReport() -> LUFSReportProbe {
  let step = 0.1
  let duration = 180.0
  let n = Int(duration / step)

  // envelope: the "single number doesn't make sense" song shape
  func envelope(_ t: Double) -> Double {
    switch t {
    case ..<25: return -32 + 6 * (t / 25)  // quiet intro rising
    case ..<30: return -26 + (t - 25) * 3.2  // build
    case ..<100: return -10  // loud middle
    case ..<115: return -20  // breakdown
    case ..<160: return -9  // loud again
    default: return -9 - (t - 160) * 1.1  // outro fade
    }
  }

  var momentary = [Double]()
  momentary.reserveCapacity(n)
  var seed: UInt64 = 0x9E37_79B9_7F4A_7C15
  for i in 0..<n {
    let t = Double(i) * step
    seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    let wiggle = Double(seed >> 40) / Double(1 << 24) * 6 - 3  // +/-3 LU flutter
    momentary.append(envelope(t) + wiggle)
  }

  // short-term = 3s moving average of momentary (30 samples)
  var shortTerm = [Double]()
  shortTerm.reserveCapacity(n)
  for i in 0..<n {
    let lo = max(0, i - 29)
    let window = momentary[lo...i]
    shortTerm.append(window.reduce(0, +) / Double(window.count))
  }

  let sorted = shortTerm.sorted()
  let p10 = sorted[Int(0.10 * Double(sorted.count - 1))]
  let p95 = sorted[Int(0.95 * Double(sorted.count - 1))]

  return LUFSReportProbe(
    integratedLUFS: -12.4,
    maxTruePeakDBTP: -0.6,
    loudnessRangeLU: p95 - p10,
    lraLowLUFS: p10,
    lraHighLUFS: p95,
    momentaryLUFS: momentary,
    shortTermLUFS: shortTerm,
    stepSeconds: step
  )
}

// MARK: - The ebu-plot-style chart, straight off the proposed schema

struct LUFSChartProbeView: View {
  let report: LUFSReportProbe = syntheticReport()

  private var chartSamples: [LoudnessSampleProbe] { report.samples }

  // LRA band (Tech 3342 P10-P95) - shaded region like ebu-plot
  private var lraBand: some ChartContent {
    RectangleMark(
      yStart: .value("LRA low", report.lraLowLUFS),
      yEnd: .value("LRA high", report.lraHighLUFS)
    )
    .foregroundStyle(Color.green.opacity(0.12))
  }

  // integrated as dashed reference rule
  private var integratedRule: some ChartContent {
    RuleMark(y: .value("Integrated", report.integratedLUFS))
      .foregroundStyle(Color.blue)
      .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 3]))
  }

  private var header: some View {
    HStack(spacing: 16) {
      Label(
        String(format: "Integrated %.1f LUFS", report.integratedLUFS),
        systemImage: "waveform")
      Label(
        String(format: "True Peak %.1f dBTP", report.maxTruePeakDBTP),
        systemImage: "arrow.up.to.line")
      if let lra = report.loudnessRangeLU {
        Label(String(format: "LRA %.1f LU", lra), systemImage: "arrow.up.and.down")
      }
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("LUFS over time - schema probe")
        .font(.headline)
      header

      Chart {
        lraBand
        ForEach(chartSamples) { (sample: LoudnessSampleProbe) in
          LineMark(
            x: .value("Time", sample.time),
            y: .value("LUFS", sample.lufs)
          )
          .foregroundStyle(by: .value("Series", sample.series.rawValue))
        }
        integratedRule
      }
      .chartYScale(domain: -40...0)
      .chartXAxisLabel("Time (s)")
      .chartYAxisLabel("LUFS")
      .chartForegroundStyleScale([
        "Momentary": Color.red.opacity(0.55),
        "Short-term": Color.blue,
      ])
      .frame(minHeight: 320)
    }
    .padding()
  }
}

#Preview {
  LUFSChartProbeView()
    .frame(width: 860, height: 460)
}
