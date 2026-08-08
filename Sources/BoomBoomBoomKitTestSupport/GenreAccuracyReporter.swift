//
//  GenreAccuracyReporter.swift
//  BoomBoomBoomKitTestSupport
//
//  Shared genre-stratified accuracy reporter used by both OA300 and GiantSteps
//  benchmark suites. Pure formatter: `[GenreBucket] -> String`, no I/O.
//

import Foundation

/// A per-genre accuracy bucket for stratified reporting.
///
/// Stateless value type. `total` / `acc1Correct` / `acc2Correct` are raw counts;
/// `acc1Percent` / `acc2Percent` are computed (guarded against `total == 0`).
/// A bucket is `isInsufficient` when `total < GenreAccuracyReporter.minSampleSize`,
/// at which point its numeric accuracy is hidden in rendered reports.
/// `genre` is bounded to 100 characters to match the reporter's fixed column width;
/// longer labels trip the initializer precondition rather than silently truncate.
public struct GenreBucket: Sendable {
  public let genre: String
  public let total: Int
  public let acc1Correct: Int
  public let acc2Correct: Int

  /// Acc1 as a `0...100` percentage. Returns `0` when `total == 0` to avoid NaN.
  public var acc1Percent: Double {
    total > 0 ? Double(acc1Correct) / Double(total) * 100 : 0
  }

  /// Acc2 as a `0...100` percentage. Returns `0` when `total == 0` to avoid NaN.
  public var acc2Percent: Double {
    total > 0 ? Double(acc2Correct) / Double(total) * 100 : 0
  }

  /// `Acc2 - Acc1` as a track count — the per-genre octave-error proxy (Story 12.3,
  /// FR-61). Non-negative by the `acc1Correct <= acc2Correct` init precondition.
  public var octaveErrorProxy: Int { acc2Correct - acc1Correct }

  /// The octave-error proxy in percentage points: `100 * (acc2 - acc1) / total`,
  /// `0.0` when `total == 0`.
  public var octaveErrorProxyPercentagePoints: Double {
    total > 0 ? 100.0 * Double(acc2Correct - acc1Correct) / Double(total) : 0.0
  }

  /// True when this bucket has fewer than `GenreAccuracyReporter.minSampleSize` tracks.
  /// Insufficient buckets render the literal string `insufficient` instead of percentages
  /// and never receive the `** LOW **` marker.
  public var isInsufficient: Bool {
    total < GenreAccuracyReporter.minSampleSize
  }

  public init(genre: String, total: Int, acc1Correct: Int, acc2Correct: Int) {
    precondition(total >= 0, "total must be non-negative")
    precondition(acc1Correct >= 0, "acc1Correct must be non-negative")
    precondition(acc2Correct >= 0, "acc2Correct must be non-negative")
    precondition(acc1Correct <= total, "acc1Correct must be <= total")
    precondition(acc2Correct <= total, "acc2Correct must be <= total")
    precondition(
      acc1Correct <= acc2Correct,
      "acc1Correct must be <= acc2Correct (MIREX Acc2 supersets Acc1)")
    precondition(genre.count <= 100, "genre label exceeds 100-char padding width")
    self.genre = genre
    self.total = total
    self.acc1Correct = acc1Correct
    self.acc2Correct = acc2Correct
  }
}

/// Namespace for genre-stratified accuracy reporting.
///
/// Caseless enum (same idiom as `MelFilterbank`). Exposes two policy constants
/// (`minSampleSize`, `significantRegressionPercentagePoints`), a pure-function
/// report formatter `format(...)`, and the threshold helper `isSignificantlyLower(...)`.
/// All members are `Sendable`-safe by value semantics.
public enum GenreAccuracyReporter {

  /// Minimum number of tracks required before a per-genre bucket reports numeric
  /// accuracy. Buckets below this threshold render the literal `insufficient` label
  /// per epic AC (`epics.md:454`).
  public static let minSampleSize: Int = 5

  /// Absolute percentage-point delta threshold for flagging a bucket as significantly
  /// underperforming. See story 2-5 Dev Notes for rationale (interpretability, noise
  /// robustness, round-number discoverability).
  public static let significantRegressionPercentagePoints: Double = 10.0

  /// True when `bucketAcc1Percent` is at least
  /// `significantRegressionPercentagePoints` below `overallAcc1Percent`.
  /// Absolute percentage-point delta; boundary is inclusive (`>=`).
  public static func isSignificantlyLower(
    bucketAcc1Percent: Double,
    overallAcc1Percent: Double
  ) -> Bool {
    overallAcc1Percent - bucketAcc1Percent >= significantRegressionPercentagePoints
  }

  /// Render a stratified accuracy report as a multi-line string.
  ///
  /// Sections (in order, trailing newline):
  /// 1. `=== <corpusLabel> Genre-Stratified Accuracy (Intensity <intensity>) ===`
  /// 2. `Annotation version: <tag>` (Story 12.3, FR-60 — defaults to `untagged`
  ///    when the caller supplies none)
  /// 3. Column header: `Genre<padded to 100>    Acc1    Acc2    Acc2-Acc1  Count  Status`
  /// 4. Rule of `-` characters matching the column-header width
  /// 5. One row per bucket, sorted `total` descending with `genre` ASCII tie-break;
  ///    the `Acc2-Acc1` cell shows the octave-error proxy as a count plus percentage
  ///    points (Story 12.3, FR-61)
  /// 6. `Overall: Acc1=<XX.X>%, Acc2=<XX.X>%`
  ///
  /// Insufficient buckets (`total < minSampleSize`) render `insufficient` in a
  /// left-justified field spanning the numeric columns and never receive the
  /// `** LOW **` marker. Empty `buckets` is valid: header + rule + Overall line,
  /// no data rows.
  public static func format(
    corpusLabel: String,
    intensity: Int,
    annotationVersion: AnnotationVersion = .untagged,
    buckets: [GenreBucket],
    overallAcc1Percent: Double,
    overallAcc2Percent: Double
  ) -> String {
    precondition(
      isValidPercent(overallAcc1Percent),
      "overallAcc1Percent must be finite and in 0...100")
    precondition(
      isValidPercent(overallAcc2Percent),
      "overallAcc2Percent must be finite and in 0...100")

    let columnHeader =
      "Genre".padding(toLength: 100, withPad: " ", startingAt: 0)
      + "    Acc1    Acc2    Acc2-Acc1  Count  Status"
    let rule = String(repeating: "-", count: columnHeader.count)

    let sorted = buckets.sorted { a, b in
      a.total > b.total || (a.total == b.total && a.genre < b.genre)
    }

    var lines: [String] = []
    lines.append("=== \(corpusLabel) Genre-Stratified Accuracy (Intensity \(intensity)) ===")
    lines.append("Annotation version: \(annotationVersion)")
    lines.append(columnHeader)
    lines.append(rule)

    for bucket in sorted {
      lines.append(renderRow(bucket: bucket, overallAcc1Percent: overallAcc1Percent))
    }

    lines.append(
      "Overall: Acc1=\(String(format: "%.1f", overallAcc1Percent))%, "
        + "Acc2=\(String(format: "%.1f", overallAcc2Percent))%")

    // Strip trailing whitespace per-line, join with \n, terminate with single \n.
    let stripped = lines.map { line in
      String(line.reversed().drop(while: { $0 == " " || $0 == "\t" }).reversed())
    }
    return stripped.joined(separator: "\n") + "\n"
  }

  // MARK: - Private

  private static func isValidPercent(_ percent: Double) -> Bool {
    !percent.isNaN && !percent.isInfinite && (0...100).contains(percent)
  }

  private static func renderRow(bucket: GenreBucket, overallAcc1Percent: Double) -> String {
    let genreCell = bucket.genre.padding(toLength: 100, withPad: " ", startingAt: 0)
    let countCell = String(format: "%5d", bucket.total)

    if bucket.isInsufficient {
      // Field spans the numeric columns: 6 (Acc1) + 2 + 6 (Acc2) + 2 + 11 (Acc2-Acc1) = 27.
      let insufficientCell = "insufficient".padding(toLength: 27, withPad: " ", startingAt: 0)
      return "\(genreCell)  \(insufficientCell)  \(countCell)  "
    }

    let acc1Cell = String(format: "%5.1f%%", bucket.acc1Percent)
    let acc2Cell = String(format: "%5.1f%%", bucket.acc2Percent)
    // Story 12.3 (FR-61): the octave-error proxy as a count plus percentage points.
    let proxyCell = String(
      format: "%3d %5.1fpp", bucket.octaveErrorProxy, bucket.octaveErrorProxyPercentagePoints)
    let status =
      isSignificantlyLower(
        bucketAcc1Percent: bucket.acc1Percent,
        overallAcc1Percent: overallAcc1Percent)
      ? "** LOW **" : ""
    return "\(genreCell)  \(acc1Cell)  \(acc2Cell)  \(proxyCell)  \(countCell)  \(status)"
  }
}
