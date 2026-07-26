//
//  BNNSImpactTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  Story 4-5 Task 7 — env-gated impact-report harness for BNNSTechnique
//  against the OA300 corpus. Triggered by `make bnns-impact-report` (which
//  sets `BNNS_IMPACT=1` + `BNNS_IMPACT_OUT_DIR`); deliberately NOT run by
//  the unit-test `make test`.
//
//  Pinned config per Story 4-5 AC #7 (Codex MAJOR #9 resolution):
//    intensity = .thorough  (forces ML path activation at intensity 8)
//    ensemblePolicy = .mlOnly  (isolates ML signal; ML abstain falls back to DSP)
//
//  The test produces `4-5-bnns-impact-report.json` per AC #8 schema and
//  asserts ≥ 2 of 4 named DnB triplets resolved within ±0.5 BPM (HALT (b)).
//

import BoomBoomBoomKit
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKitML  // `supportedFeatureSetVersion` is internal.

// MARK: - JSON schema

private struct BNNSImpactReport: Codable, Sendable {
  /// Schema version. Bumped to 3 (from Story 4-6's v2) when the canonical
  /// perf-baselines envelope was adopted: top-level provenance fields
  /// (`recorded_at`, `git_sha`, `build_configuration`, `hardware{}`) match
  /// the same shape the `PerformanceBenchmarkTests` baseline records use,
  /// and the on-disk filename uses the `{fingerprint}--{buildConfig}--{recordedAt}--{gitSHA}--{shortUUID}.json`
  /// pattern under `_bmad-output/perf-baselines/bnns-impact/`. The `snapshot_sha`
  /// field from v2 is removed — `git_sha` carries that signal at the
  /// canonical layer instead.
  let schema_version: Int
  /// ISO-8601 UTC timestamp of when this record was written (extended
  /// form with `-` and `:` separators, seconds precision). The filename
  /// segment uses ISO-8601 basic form (no separators) so the two views of
  /// the same instant are intentionally different — extended for
  /// human-readable JSON bodies, basic for filesystem-safe filenames.
  /// See the `running-benchmarks` skill for the double-form rule.
  let recorded_at: String
  /// Git short SHA at the time of the run. May include a `-dirty` suffix
  /// when the working tree had uncommitted changes — see the
  /// `bnns-impact-report` Makefile target's `GIT_SHA` wiring.
  let git_sha: String
  /// `Debug` or `Release` — copies the `#if DEBUG` macro at test-compile
  /// time. Persisted records from different build configs are separated
  /// at the filename layer so jq recipes can filter cleanly.
  let build_configuration: String
  /// Sibling identity field, mirrors the perf-baselines envelope. Always
  /// `"BoomBoomBoomKit (workspace HEAD)"` since SPM doesn't surface a
  /// runtime version string for the workspace package.
  let swift_package_version: String
  /// Machine identity for cross-machine record disambiguation.
  let hardware: HardwareDescriptor
  let model_identifier: String
  let pinned_config: PinnedConfig
  let named_dnb_track_results: [NamedDnBResult]
  /// Story 4-6 AC #7: per-control results for the schema-v3 partition.
  /// Each entry asks "did ML break a track DSP was right about?" — the
  /// preservation oracle (DD #4).
  let dsp_correct_control_results: [DnBControlResult]
  let all_tracks: [TrackRow]
  /// Story 4-6 AC #7: bucket histogram keyed by `OutcomeKey` — the four
  /// snapshot-representable failure stages, `noAbstain` for the win path,
  /// and the four whole-evaluation outcomes that produce no snapshot.
  /// Empirical proof of which hypothesis was correct across the corpus —
  /// diff before/after a remediation to see what changed.
  let failure_stage_histogram: [String: Int]
  /// Story 4-6 DD #5: corpus-wide distribution stats. Populated only
  /// when the impact run actually reached the decode stage on at least
  /// some tracks (`decoded_bpm_total_count > 0`). At threshold 0.0/0.0
  /// these stats are the load-bearing investigation evidence.
  let corpus_distribution: CorpusDistribution?
  /// Story 4-6 Task 7: which thresholds the run actually applied. When
  /// `BNNS_THRESHOLD_OVERRIDE_*` env vars are set, this records the
  /// override; otherwise records the production defaults. Lets the
  /// aggregated sweep JSON track per-run config without out-of-band
  /// metadata.
  let applied_thresholds: AppliedThresholds
  let summary: Summary
}

private struct AppliedThresholds: Codable, Sendable {
  let confidence: Double
  let margin: Double
}

private struct CorpusDistribution: Codable, Sendable {
  let wrong_non_abstain_count: Int
  let decoded_bpm_total_count: Int
  let decoded_bpm_histogram_5bpm_bins: [Int]
  let decoded_bpm_in_range_fraction: Double
  let decoded_bpm_matches_dsp_within_4pct_fraction: Double
  let softmax_max_p50: Double
  let softmax_max_p95: Double
  let softmax_margin_p50: Double
  let softmax_margin_p95: Double
  let input_feature_checksum_unique_count: Int
}

private struct PinnedConfig: Codable, Sendable {
  let intensity: Int
  let ensemble_policy: String
}

/// Machine identity carried in every impact record. Mirrors the
/// `hardware{}` block in the perf-baselines schema v2 (see
/// `PerformanceBenchmarkTests.swift` and the `running-benchmarks` skill
/// for the canonical shape).
private struct HardwareDescriptor: Codable, Sendable {
  let chip: String
  let cores: Int
  let physical_memory_gib: Int
  let os_version: String
}

private struct NamedDnBResult: Codable, Sendable {
  let track_id: String
  let ground_truth_bpm: Double
  let ensemble_winner_bpm: Double
  let abs_error_bpm: Double
  let resolved_within_05: Bool
}

/// Story 4-6 DD #4 + AC #7: per-control-track result row.
private struct DnBControlResult: Codable, Sendable {
  let track_id: String
  let ground_truth_bpm: Double
  let ensemble_winner_bpm: Double
  let dsp_winner_bpm: Double
  let abs_error_bpm: Double
  /// `true` when the ensemble landed within ±0.5 BPM of ground truth.
  /// This is the Branch A success criterion — controls must all stay
  /// preserved (4/4) for strict Branch A; 3/4 allowed only under
  /// Branch A-conditional per DD #8.
  let preserved_within_05: Bool
  let ml_diagnostic_snapshot: DiagnosticSnapshotJSON?
}

/// The harness's own outcome taxonomy — GH-167 item 6 (#124).
///
/// Deliberately BROADER than ``MLDiagnosticSnapshot/FailureStage``: it must
/// also name whole-evaluation outcomes that produce no snapshot at all
/// (features absent, feature-set drift, ML never ran, conformer opted out of
/// diagnostics). Those are not snapshot-representable — `inputFeatureChecksum`
/// is non-optional and there is nothing to checksum — which is why the two
/// pre-featurize cases were removed from the public enum rather than
/// legalized there.
///
/// Previously these nine keys were bare string literals repeated across the
/// histogram seed, the bucket assignment and the print loop, with nothing
/// tying the three lists together. Now `allCases` drives all three.
private enum OutcomeKey: String, CaseIterable, Sendable {
  case noAbstain
  case featuresAbsent
  case featureVersionMismatch
  case featurizeRejected
  case graphFailed
  case decodeRejected
  case confidenceGateRejected
  case mlNotRun
  case diagnosticSnapshotMissing

  /// Projects a snapshot's stage into the harness taxonomy. A nil stage
  /// is the win path.
  init(failureStage: MLDiagnosticSnapshot.FailureStage?) {
    switch failureStage {
    case nil: self = .noAbstain
    case .featurizeRejected: self = .featurizeRejected
    case .graphFailed: self = .graphFailed
    case .decodeRejected: self = .decodeRejected
    case .confidenceGateRejected: self = .confidenceGateRejected
    }
  }
}

/// Story 4-6 AC #12: private mirror struct for JSON encoding the public
/// `MLDiagnosticSnapshot`. The public type is NOT `Codable` per DD #11
/// + W4 — `BPMDiagnosticTrace` is not `Codable` so there's no synthesis
/// to migrate, and the impact-report harness handles its own
/// serialization here.
private struct DiagnosticSnapshotJSON: Codable, Sendable {
  let failure_stage: String?
  let decoded_bpm: Double?
  let softmax_max: Double?
  let softmax_second_max: Double?
  let input_feature_checksum: UInt64?
  let gate_fired: String?

  /// Construct from a public ``MLDiagnosticSnapshot``. The five abstain
  /// cases plus the win path all flow through this single converter.
  init(from snapshot: MLDiagnosticSnapshot) {
    self.failure_stage = snapshot.failureStage?.rawValue
    self.decoded_bpm = snapshot.decodedBPM
    self.softmax_max = snapshot.softmaxMax
    self.softmax_second_max = snapshot.softmaxSecondMax
    self.input_feature_checksum = snapshot.inputFeatureChecksum
    self.gate_fired = snapshot.gateFired?.rawValue
  }

  /// Construct a synthetic snapshot for the two pre-featurize abstain
  /// paths where the public ``MLDiagnosticSnapshot`` is nil. The
  /// harness inspects the trace's `mlFeatures` to decide
  /// `featuresAbsent` vs `featureVersionMismatch`; all numeric fields
  /// are nil because no feature payload was checksummed.
  init(preFeaturizeAbstain key: OutcomeKey) {
    self.failure_stage = key.rawValue
    self.decoded_bpm = nil
    self.softmax_max = nil
    self.softmax_second_max = nil
    self.input_feature_checksum = nil
    self.gate_fired = nil
  }
}

private struct TrackRow: Codable, Sendable {
  let track: String
  let dsp_winner: Double
  let ml_winner: Double?
  let ensemble_winner: Double
  let ml_confidence: Double?
  let ground_truth: Double
  let dsp_correct: Bool
  let ml_correct: Bool?
  let ensemble_correct: Bool
  let named_dnb_track: Bool
  let latency_ms: Double
  /// Story 4-6 AC #7: per-track diagnostic snapshot mirror. Nil when ML
  /// never ran (DSP-only) OR when the inference path completed without
  /// constructing a snapshot (pre-featurize abstain paths populate this
  /// from trace-state inspection — see `bucketForTrack` in the
  /// per-track loop).
  let ml_diagnostic_snapshot: DiagnosticSnapshotJSON?
}

private struct Summary: Codable, Sendable {
  let total_tracks: Int
  let dsp_acc1: Int
  let ml_acc1: Int
  let ensemble_acc1: Int
  let named_dnb_resolved: Int
  /// Diagnostic counter (review fix N9): named-DnB tracks where ML
  /// abstained AND DSP fell within `regression_threshold.tolerance_bpm`
  /// of ground truth. Does NOT count toward HALT (b) — which requires
  /// ML wins — but surfaces the alternate-resolution scenario so it
  /// can be triaged separately.
  let named_dnb_resolved_via_dsp_fallback: Int
  let named_dnb_total: Int
  /// Story 4-6 AC #7: number of dsp_correct_controls preserved at the
  /// chosen post-fix configuration. Branch A strict gate: == 4/4.
  let dsp_correct_controls_preserved: Int
  let dsp_correct_controls_total: Int
}

// MARK: - Suite

@Suite(
  "Story 4-5 BNNSImpact",
  .enabled(if: ProcessInfo.processInfo.environment["BNNS_IMPACT"] == "1")
)
struct BNNSImpactTests {

  private let corpusPath: String
  private let groundTruth: [OA300Track]
  /// Canonical DnB-triplet targets loaded from
  /// `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json`.
  /// Source of truth for the named-DnB ground-truth lookup (review fix C5)
  /// and the named-DnB membership test (review fix m17). Frozen at SHA
  /// `9185698` per the artifact's `captured_with.git_sha`.
  private let dnbTargets: [DnBTarget]
  /// Decoded `regression_threshold` block from the same artifact. Drives
  /// the HALT (b) min-resolved gate + tolerance values (review fix N8).
  private let regressionThreshold: RegressionThreshold
  /// Story 4-6 DD #4: DSP-correct control set loaded from the schema-v3
  /// `dsp_correct_controls` array. Each entry is a track DSP currently
  /// resolves correctly at default config (within ±0.5 BPM per Story 4-5
  /// impact report); the impact-report harness asserts these are
  /// preserved post-fix as the Branch A success criterion (alongside
  /// ≥2/4 named DnB resolved).
  private let dnbControls: [DnBControl]

  init() throws {
    guard
      let path = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"],
      !path.isEmpty
    else {
      throw BNNSImpactError.corpusPathNotSet
    }
    corpusPath = path

    let url =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(
        forResource: "Fixtures/oa300-ground-truth", withExtension: "json")
    guard let url else {
      throw BNNSImpactError.groundTruthNotFound
    }
    let data = try Data(contentsOf: url)
    groundTruth = try OA300Track.loadCorpus(from: data)

    // Canonical DnB targets bundled under Tests/.../Fixtures/ so the test
    // ships to `main` without any `_bmad-output/` dependency. The two
    // Bundle.module lookup patterns mirror the oa300-ground-truth fallback
    // above (some SPM toolchains resolve via directory prefix, others
    // don't).
    let dnbURL =
      Bundle.module.url(forResource: "4-dnb-triplet-targets", withExtension: "json")
      ?? Bundle.module.url(
        forResource: "Fixtures/4-dnb-triplet-targets", withExtension: "json")
    guard let dnbURL else {
      throw BNNSImpactError.dnbTargetsNotFound
    }
    let dnbData = try Data(contentsOf: dnbURL)
    // Story 8.8c: `4-dnb-triplet-targets.json` is now a JAMS corpus. Decode it through
    // the shared `JAMSCorpus` model and adapt into the thin domain structs the harness
    // logic reads: `ground_truth_bpm` from each entry's `tempo` value, `track_id` from
    // `identifiers`, `target`/`control` from the per-entry sandbox `partition`, and the
    // config (`schema_version`, `regression_threshold`) from the corpus-level sandbox.
    let dnbCorpus = try JSONDecoder().decode(JAMSCorpus.self, from: dnbData)
    // Review fix N8: enforce schema_version and uniqueness invariants the
    // v1 loader silently ignored. A schema bump or duplicate `track_id`
    // now fails fast at suite-init time.
    let schemaVersion = dnbCorpus.sandbox?.schemaVersion ?? -1
    guard schemaVersion == DnBTargetsFile.expectedSchemaVersion else {
      throw BNNSImpactError.dnbTargetsSchemaMismatch(
        expected: DnBTargetsFile.expectedSchemaVersion, got: schemaVersion)
    }
    // `dnbPartitioned()` supplies completeness + non-nil track_id + numeric tempo per
    // entry (throwing on a malformed one); the harness layers the union-uniqueness and
    // ≥4-controls invariants on top and adapts into its thin domain structs.
    let (jamsTargets, jamsControls) = try dnbCorpus.dnbPartitioned()
    // Story 4-6 DD #4: uniqueness extends across the union of `targets` and
    // `dsp_correct_controls`. A control track that's ALSO a named failure would be
    // incoherent (the same audio can't be both "DSP-correct" and "named-DnB-failure").
    var seenIDs = Set<String>()
    for entry in jamsTargets + jamsControls {
      if !seenIDs.insert(entry.trackID).inserted {
        throw BNNSImpactError.dnbTargetsDuplicateTrackID(entry.trackID)
      }
    }
    // DD #4 requires ≥4 controls. Lighter than enforcing an exact count
    // so future stories adding more controls don't break the load.
    guard jamsControls.count >= 4 else {
      throw BNNSImpactError.dnbControlsCountInsufficient(got: jamsControls.count, required: 4)
    }
    guard let jamsThreshold = dnbCorpus.sandbox?.regressionThreshold else {
      throw BNNSImpactError.dnbRegressionThresholdMissing
    }
    dnbTargets = jamsTargets.map { DnBTarget(track_id: $0.trackID, ground_truth_bpm: $0.bpm) }
    dnbControls = jamsControls.map {
      DnBControl(
        track_id: $0.trackID, ground_truth_bpm: $0.bpm,
        rationale: $0.file.sandbox?.rationale ?? "")
    }
    regressionThreshold = try RegressionThreshold(jams: jamsThreshold)
  }

  private func trackURL(_ track: OA300Track) -> URL {
    if let subdir = track.subdir {
      return URL(fileURLWithPath: corpusPath)
        .appendingPathComponent(subdir)
        .appendingPathComponent(track.filename)
    }
    return URL(fileURLWithPath: corpusPath)
      .appendingPathComponent(track.filename)
  }

  /// Returns the canonical DnB target matching `filename` using a base-name
  /// match: an exact equality, OR `track_id` followed by `.` (extension
  /// boundary). Pre-review-pass this used `filename.contains(track_id)` which
  /// is non-deterministic on substring overlap (e.g., adding a target whose
  /// `track_id` is a prefix of another would silently bind to the first
  /// matching entry). Review fix N6 tightens the match.
  ///
  /// Returns `nil` for tracks outside the named-DnB set.
  private func dnbTarget(for filename: String) -> DnBTarget? {
    return dnbTargets.first { target in
      filename == target.track_id || filename.hasPrefix(target.track_id + ".")
    }
  }

  /// Story 4-6: same match rule as ``dnbTarget(for:)`` but for the
  /// `dsp_correct_controls` partition. Returns the matching control
  /// when the filename is in the control set, else `nil`. The metric
  /// for controls is PRESERVATION (DSP was right; did ML break it?)
  /// rather than RESOLUTION (DSP was wrong; did ML fix it?).
  private func dnbControl(for filename: String) -> DnBControl? {
    return dnbControls.first { control in
      filename == control.track_id || filename.hasPrefix(control.track_id + ".")
    }
  }

  @Test(
    "bnnsImpactReport (BNNS_IMPACT=1)",
    .enabled(if: ProcessInfo.processInfo.environment["BNNS_IMPACT"] == "1"),
    .disabled(
      if: {
        // Story 4-6 Branch C: when no model is bundled AND no
        // `BNNS_MODEL_URL` env var is provided, there's nothing to
        // evaluate against. Skip cleanly.
        //
        // The `BNNS_MODEL_URL` BYOW seam (Story 4-6 code review P19)
        // lets develop-only paths (e.g., re-running impact-report
        // against `_bmad-output/ml-models/giantsteps_v1.mlmodelc/`)
        // unblock the harness without re-bundling.
        if #available(macOS 15.0, *) {
          let bundleAvailable = BNNSTechnique.bundledReferenceURL != nil
          let envURL =
            ProcessInfo.processInfo.environment["BNNS_MODEL_URL"]
            .flatMap { $0.isEmpty ? nil : $0 }
          return !bundleAvailable && envURL == nil
        }
        return true
      }())
  )
  func bnnsImpactReport() async throws {
    if #available(macOS 15.0, *) {
      // Story 4-6 Task 7: optional threshold override via env vars so
      // the Makefile sweep loop can drive 7 runs at different thresholds
      // without re-compiling. Both vars MUST be set together; partial
      // override is rejected to avoid mixing default + override states.
      //
      // GH-167 item 6 (#144): the thresholds are now constructor
      // arguments rather than a process-global override, so the sweep
      // configures the instance it builds below and there is no global
      // state to reset afterwards.
      let envConf =
        ProcessInfo.processInfo.environment["BNNS_THRESHOLD_OVERRIDE_CONFIDENCE"]
      let envMargin =
        ProcessInfo.processInfo.environment["BNNS_THRESHOLD_OVERRIDE_MARGIN"]
      // The REQUESTED values. What the technique actually applies after
      // clamping is read back off the instance for the report.
      let requestedThresholds: (confidence: Double, margin: Double)
      if let confStr = envConf, let marginStr = envMargin,
        let confVal = Double(confStr), let marginVal = Double(marginStr)
      {
        requestedThresholds = (confVal, marginVal)
      } else if envConf != nil || envMargin != nil {
        Issue.record(
          Comment(
            rawValue:
              "BNNS_THRESHOLD_OVERRIDE_CONFIDENCE and BNNS_THRESHOLD_OVERRIDE_MARGIN "
              + "must be set together (got confidence=\(envConf ?? "nil"), "
              + "margin=\(envMargin ?? "nil"))"))
        return
      } else {
        requestedThresholds = (
          BNNSTechnique.defaultConfidenceThreshold,
          BNNSTechnique.defaultMarginThreshold
        )
      }
      // Hoist `BNNSTechnique()` out of the per-track loop so the graph
      // compiles ONCE per benchmark run, not 82× (review fix M7).
      //
      // Story 4-6 code review P19 — `BNNS_MODEL_URL` BYOW seam: when
      // set, load the .mlmodelc at that filesystem path. Otherwise
      // fall back to the bundled reference (nil under Branch C, which
      // makes the no-arg construction throw and the `.disabled(if:)`
      // trait above skips cleanly).
      let bnnsTechnique: BNNSTechnique
      do {
        let envModelURL =
          ProcessInfo.processInfo.environment["BNNS_MODEL_URL"]
          .flatMap { $0.isEmpty ? nil : URL(fileURLWithPath: $0) }
        var opts = BNNSTechnique.Options()
        opts.confidenceThreshold = requestedThresholds.confidence
        opts.marginThreshold = requestedThresholds.margin
        if let envURL = envModelURL {
          bnnsTechnique = try BNNSTechnique(modelURL: envURL, options: opts)
        } else {
          bnnsTechnique = try BNNSTechnique(options: opts)
        }
      } catch {
        let msg =
          "BNNSTechnique unavailable — under Story 4-6 Branch C the bundled"
          + " model is no longer shipped from `Sources/BoomBoomBoomKitML/Resources/`"
          + " (relocated to develop-only `_bmad-output/ml-models/giantsteps_v1.mlmodelc/`)."
          + " Pass an explicit `modelURL:` to `BNNSTechnique(modelURL:)` or set"
          + " `BNNS_MODEL_URL=<path>` to run this benchmark against a BYOW model;"
          + " the no-arg form will throw `.modelResourceMissing` until a future"
          + " story re-bundles a higher-quality model."
          + " Underlying error: \(error.localizedDescription)"
        Issue.record(Comment(rawValue: msg))
        return
      }

      // Pre-filter the corpus to readable tracks. PCMBufferReader may
      // reject a few files with unsupported codecs; we just skip them so
      // the impact report reflects only what the pipeline can process.
      let candidateTracks = groundTruth.filter { track in
        FileManager.default.fileExists(atPath: trackURL(track).path)
      }

      var allRows: [TrackRow] = []
      allRows.reserveCapacity(candidateTracks.count)
      var dspAcc1 = 0
      var mlAcc1 = 0
      var ensembleAcc1 = 0
      var namedDnBResolved = 0
      // Track when ML abstains and DSP fallback happens to be close to gt.
      // Spec says DnB-resolved counts ONLY ML wins (review fix M9); this
      // counter surfaces the alternative scenario diagnostically.
      var namedDnBResolvedViaDSPFallback = 0
      // Story 4-6 AC #7: failure-stage histogram across all 82 tracks.
      // 9 buckets: 6 failure stages + `noAbstain` (win path) + two
      // accountability buckets introduced by Story 4-6 code review
      // P18 / Codex Option B: `mlNotRun` (BNNS conformance threw or
      // the path returned no trace at all) and
      // `diagnosticSnapshotMissing` (trace exists, mlFeatures present
      // and supported version, but the conformer did NOT adopt
      // ``MLDiagnosticTechnique`` so no snapshot was attached). Both
      // are real-world outcomes the v3 schema must surface honestly so
      // the conservation invariant `histogramSum == allRows.count`
      // holds without an out-of-band skip counter.
      var failureStageHistogram: [String: Int] = Dictionary(
        uniqueKeysWithValues: OutcomeKey.allCases.map { ($0.rawValue, 0) })
      // Story 4-6 AC #7: per-control results accumulated alongside the
      // named-DnB results. Different metric: PRESERVATION (DSP was
      // right; did ML break it?) rather than RESOLUTION.
      var controlResults: [DnBControlResult] = []
      var controlsPreserved = 0

      // Story 4-6 DD #5 corpus-wide distribution stats. Accumulated
      // across all tracks where the snapshot reached at least the
      // decode stage (so decoded BPM / softmax values are available).
      // Used to distinguish DD #5 Outcome A (threshold too aggressive)
      // from Outcome B (featurize bug) from Outcome C (degenerate
      // distribution) without re-running the full corpus.
      //
      // - wrongNonAbstainCount: tracks where ML emitted a non-abstaining
      //   prediction (i.e., bypass thresholds via override) that was
      //   outside 4% Acc1 tolerance of DSP's correct value. THE HEADLINE
      //   COLUMN at threshold 0.0/0.0 — if high, the model is broken
      //   regardless of gating.
      // - decodedBpmHistogram5bpmBins: count of tracks whose decoded BPM
      //   fell in each 5-BPM bin from 60 to 200 (28 bins).
      // - decodedBpmInRangeCount: count of tracks with decoded BPM in
      //   [60, 200] (i.e., NOT decodeRejected for out-of-range argmax).
      // - decodedBpmMatchesDspCount: count of tracks where the ML
      //   decoded BPM is within 4% of the DSP winner (when DSP is
      //   correct, this is a useful prediction).
      // - softmaxMaxValues / softmaxMarginValues: accumulators for p50/p95.
      // - inputFeatureChecksumSeen: unique checksums (should equal
      //   accumulatedTrackCount as a sanity check; collision would
      //   indicate hash function bug).
      var wrongNonAbstainCount = 0
      var decodedBpmHistogram5bpmBins = [Int](repeating: 0, count: 28)
      var decodedBpmInRangeCount = 0
      var decodedBpmMatchesDspCount = 0
      var decodedBpmTotalCount = 0
      var softmaxMaxValues: [Double] = []
      var softmaxMarginValues: [Double] = []
      var inputFeatureChecksumSeen = Set<UInt64>()

      let clock = ContinuousClock()

      for track in candidateTracks {
        let url = trackURL(track)

        // DSP-only baseline. Review fix N10: distinguish three error classes —
        //   CancellationError      → re-throw (per-run cancellation)
        //   PCMBufferReaderError   → Issue.record + dspBPM=0.0 (unreadable
        //                            corpus track, skip + log; doesn't abort
        //                            the suite)
        //   any other Error        → re-throw (genuine bug — analyzer config,
        //                            unexpected internal state)
        // The v1 catch-all `catch { dspBPM = 0.0 }` swallowed every error,
        // including future analyzer misconfiguration; that masked real bugs
        // as accuracy regressions.
        var dspOpts = AudioAnalysisService.Options()
        dspOpts.intensity = .default  // intensity 7
        dspOpts.ensemblePolicy = .dspOnly
        let dspBPM: Double
        do {
          dspBPM =
            (try AudioAnalysisService.analyzeBPM(url: url, options: dspOpts))?.bpm
            ?? 0.0
        } catch is CancellationError {
          throw CancellationError()
        } catch let error as PCMBufferReaderError {
          Issue.record(
            Comment(rawValue: "DSP analyzeBPM: skipped \(track.filename): \(error)"))
          dspBPM = 0.0
        }

        // BNNS-ML path: pinned impact-report config. Reuse the hoisted
        // technique — single graph, per-call context inside evaluate.
        var bnnsOpts = AudioAnalysisService.Options()
        bnnsOpts.intensity = .thorough  // intensity 8 — activates ML path
        bnnsOpts.ensemblePolicy = .mlOnly
        bnnsOpts.enableTrace = true  // trace.ensembleDecision needed for ml_winner
        bnnsOpts.enableMLDiagnostics = true  // P17: required for trace.mlDiagnosticSnapshot
        bnnsOpts.mlTechnique = bnnsTechnique

        let startTime = clock.now
        let bnnsResult: AudioAnalysisResult?
        do {
          bnnsResult = try AudioAnalysisService.analyzeBPM(
            url: url, options: bnnsOpts)
        } catch is CancellationError {
          throw CancellationError()
        } catch let error as PCMBufferReaderError {
          // Review fix N10: same discipline as the DSP branch — readable-file
          // failure is per-track skip + diagnostic; analyzer-config / internal
          // errors propagate.
          Issue.record(
            Comment(rawValue: "BNNS analyzeBPM: skipped \(track.filename): \(error)"))
          bnnsResult = nil
        }
        // ContinuousClock duration is monotonic — doesn't go negative
        // when system time adjusts (review fix Edge#25). Review fix M4:
        // sample the duration ONCE so seconds and attoseconds are drawn
        // from the same interval; the v1 pattern read `clock.now` twice
        // which could observe two different durations.
        let elapsed = clock.now - startTime
        let latency =
          Double(elapsed.components.seconds) * 1.0e3
          + Double(elapsed.components.attoseconds) / 1.0e15

        let ensembleBPM = bnnsResult?.bpm ?? dspBPM
        // `EnsembleDecision` carries `selectedBPM` + winner enum but not a
        // separate `mlBPM` field — ML's BPM is the same as `selectedBPM`
        // when `winner == .ml`. When `winner == .dsp` (incl. ML abstain),
        // there's no ML BPM to surface in the current trace shape
        // (deferred follow-up: add `EnsembleDecision.rawMLBpm`).
        let decision = bnnsResult?.trace?.ensembleDecision
        let mlWonEnsemble = decision?.winner == .ml
        let mlBPM: Double? = mlWonEnsemble ? decision?.selectedBPM : nil
        let mlConfidence: Double? = decision?.mlConfidence

        // Per-track DnB ground-truth lookup: when the track is in the
        // named DnB set, use the canonical `4-dnb-triplet-targets.json`
        // `ground_truth_bpm` (review fix C5). Yin Yang and HEFT are
        // listed at 85 BPM in OA300's general ground truth (Rekordbox
        // half-tempo canonical) but at 170 BPM in the DnB targets
        // (DAW-verified). The DnB targets file is the accuracy oracle
        // for the named set per AC #7.
        let dnbTargetForTrack = dnbTarget(for: track.filename)
        let gt = dnbTargetForTrack?.ground_truth_bpm ?? track.bpm
        let dspCorrect = abs(dspBPM - gt) / max(gt, 1.0) < 0.02
        let mlCorrectOpt: Bool? = mlBPM.map { abs($0 - gt) / max(gt, 1.0) < 0.02 }
        let ensembleCorrect = abs(ensembleBPM - gt) / max(gt, 1.0) < 0.02

        if dspCorrect { dspAcc1 += 1 }
        if mlCorrectOpt == true { mlAcc1 += 1 }
        if ensembleCorrect { ensembleAcc1 += 1 }

        let namedDnB = dnbTargetForTrack != nil
        // Review fix M9: HALT (b) counts named-DnB resolutions as ML
        // wins only. A DSP-fallback win (ML abstained but DSP happened
        // to be within ±tolerance_bpm) is recorded in a sibling counter
        // for diagnostic visibility but does NOT count toward Branch A
        // promotion. Tolerance is data-driven via `regressionThreshold.tolerance_bpm`
        // (review fix N8) — bumping the JSON value propagates here.
        if namedDnB && abs(ensembleBPM - gt) < regressionThreshold.tolerance_bpm {
          if mlWonEnsemble {
            namedDnBResolved += 1
          } else {
            namedDnBResolvedViaDSPFallback += 1
          }
        }

        // Story 4-6 AC #7: derive per-track diagnostic snapshot view.
        // The trace's `mlDiagnosticSnapshot` is populated by the
        // `MLDiagnosticTechnique` capability path on every evaluation
        // that reached featurize. For the two pre-featurize abstains
        // (featuresAbsent / featureVersionMismatch), the snapshot is
        // nil and the harness derives the bucket from trace state.
        let trace = bnnsResult?.trace
        let snapshotJSON: DiagnosticSnapshotJSON?
        let bucketKey: String
        if let snapshot = trace?.mlDiagnosticSnapshot {
          snapshotJSON = DiagnosticSnapshotJSON(from: snapshot)
          bucketKey = OutcomeKey(failureStage: snapshot.failureStage).rawValue
        } else if trace == nil {
          // ML did not run for this track at all — `bnnsResult` is nil
          // (analyzer threw / returned no result) or trace was never
          // attached. Story 4-6 code review P18 / Codex Option B
          // refinement: this is a real accountability outcome, not a
          // silent skip — bucket it explicitly so the conservation
          // invariant holds.
          snapshotJSON = DiagnosticSnapshotJSON(
            preFeaturizeAbstain: .mlNotRun)
          bucketKey = OutcomeKey.mlNotRun.rawValue
        } else if trace?.mlFeatures == nil {
          // Pre-featurize abstain: featuresAbsent. No snapshot was
          // constructed; harness emits a synthetic JSON record so the
          // report row still names the bucket.
          snapshotJSON = DiagnosticSnapshotJSON(
            preFeaturizeAbstain: .featuresAbsent)
          bucketKey = OutcomeKey.featuresAbsent.rawValue
        } else if trace?.mlFeatures?.featureSetVersion
          != BNNSTechnique.supportedFeatureSetVersion
        {
          // Pre-featurize abstain: featureVersionMismatch.
          snapshotJSON = DiagnosticSnapshotJSON(
            preFeaturizeAbstain: .featureVersionMismatch)
          bucketKey = OutcomeKey.featureVersionMismatch.rawValue
        } else {
          // Trace exists, mlFeatures present and supported version,
          // but no snapshot — implies the conformer did NOT adopt
          // ``MLDiagnosticTechnique`` (a consumer wrapper or custom
          // BYOW implementation would land here). Bundled
          // `BNNSTechnique` always adopts the protocol, so this case
          // is expected only for BYOW consumers using a non-diagnostic
          // technique. Story 4-6 code review P18 / Codex Option B:
          // distinct from `mlNotRun` (which is "ML attempted, failed
          // upstream") — this is "ML ran, diagnostics opted out".
          snapshotJSON = DiagnosticSnapshotJSON(
            preFeaturizeAbstain: .diagnosticSnapshotMissing)
          bucketKey = OutcomeKey.diagnosticSnapshotMissing.rawValue
        }
        // Conservation invariant: every track lands in exactly one
        // bucket. No silent-skip branches remain (Story 4-6 code review
        // P18 / Codex Option B).
        failureStageHistogram[bucketKey, default: 0] += 1

        // Story 4-6 DD #5: corpus-wide distribution stats per track.
        // Accumulate the decoded BPM, softmax max/secondMax, and the
        // checksum into the corpus-wide running totals. Only tracks
        // where the snapshot reached the decode stage contribute
        // (win path + decodeRejected-out-of-range + confidenceGateRejected).
        if let snapshot = trace?.mlDiagnosticSnapshot {
          inputFeatureChecksumSeen.insert(snapshot.inputFeatureChecksum)
          if let bpm = snapshot.decodedBPM, let softmaxMax = snapshot.softmaxMax,
            let softmaxSecondMax = snapshot.softmaxSecondMax
          {
            decodedBpmTotalCount += 1
            softmaxMaxValues.append(softmaxMax)
            softmaxMarginValues.append(softmaxMax - softmaxSecondMax)
            if (60.0...200.0).contains(bpm) {
              decodedBpmInRangeCount += 1
              // 5-BPM bins from 60 to 200. Bin index = floor((bpm-60)/5).
              // Inclusive upper bound: exactly 200.0 BPM (which the
              // (60.0...200.0).contains() filter above admits) goes into
              // bin 27 ([195.0, 200.0]) rather than overflowing bin 28.
              // The 5-BPM aggregation is descriptive; consumers reading
              // bin 27 should treat it as "195 ≤ bpm ≤ 200" not the
              // half-open "[195, 200)" that floor() would imply on a
              // wider value range.
              let binIdx = max(0, min(27, Int((bpm - 60.0) / 5.0)))
              decodedBpmHistogram5bpmBins[binIdx] += 1
              // DSP-vs-ML match: 4% Acc1 tolerance. Only meaningful when
              // DSP itself is correct.
              if dspCorrect, abs(bpm - dspBPM) / max(dspBPM, 1.0) < 0.04 {
                decodedBpmMatchesDspCount += 1
              }
            }
            // "wrong_non_abstain" — ML didn't abstain AND its prediction is
            // outside 4% Acc1 tolerance of DSP's correct value. This is the
            // headline column at threshold 0.0/0.0: if non-trivial, the
            // model is broken regardless of gating. Requires `failureStage
            // == nil` (true win) OR `failureStage == .confidenceGateRejected`
            // (would have been a win without the gate) — both produce a
            // useful "what the model said with thresholds off" measurement.
            let isEffectiveWin =
              snapshot.failureStage == nil
              || snapshot.failureStage == .confidenceGateRejected
            if isEffectiveWin && dspCorrect
              && abs(bpm - dspBPM) / max(dspBPM, 1.0) >= 0.04
            {
              wrongNonAbstainCount += 1
            }
          }
        }

        allRows.append(
          TrackRow(
            track: track.filename,
            dsp_winner: dspBPM,
            ml_winner: mlBPM,
            ensemble_winner: ensembleBPM,
            ml_confidence: mlConfidence,
            ground_truth: gt,
            dsp_correct: dspCorrect,
            ml_correct: mlCorrectOpt,
            ensemble_correct: ensembleCorrect,
            named_dnb_track: namedDnB,
            latency_ms: latency,
            ml_diagnostic_snapshot: snapshotJSON))

        // Story 4-6 DD #4: control-track accumulator. PRESERVATION
        // metric — was the ensemble winner within ±0.5 BPM of ground
        // truth? Branch A strict gate requires all controls preserved.
        if let control = dnbControl(for: track.filename) {
          let absErr = abs(ensembleBPM - control.ground_truth_bpm)
          // Inclusive: comment says "within ±0.5 BPM" — boundary is preserved.
          let preserved = absErr <= 0.5
          if preserved { controlsPreserved += 1 }
          controlResults.append(
            DnBControlResult(
              track_id: track.filename,
              ground_truth_bpm: control.ground_truth_bpm,
              ensemble_winner_bpm: ensembleBPM,
              dsp_winner_bpm: dspBPM,
              abs_error_bpm: absErr,
              preserved_within_05: preserved,
              ml_diagnostic_snapshot: snapshotJSON))
        }
      }

      // Sort all_tracks by filename for byte-stable JSON output.
      allRows.sort { $0.track < $1.track }

      let namedRows = allRows.filter { $0.named_dnb_track }
      let namedResults: [NamedDnBResult] = namedRows.map { row in
        // Review fix N8 (codex 019e28bb): the per-row `resolved_within_05`
        // field is a SCHEMA-FIXED accuracy bucket (always `< 0.5 BPM`) so
        // downstream tooling and historical reports comparing 0.5-bucketed
        // hits stay byte-comparable. The HALT gate above is the moving
        // target — it consumes `regressionThreshold.tolerance_bpm` so the
        // ratchet can tighten without renaming the field. When the two
        // values disagree (e.g., a future story tightens the gate to
        // 0.25), the report should still emit BOTH buckets for continuity.
        NamedDnBResult(
          track_id: row.track,
          ground_truth_bpm: row.ground_truth,
          ensemble_winner_bpm: row.ensemble_winner,
          abs_error_bpm: abs(row.ensemble_winner - row.ground_truth),
          resolved_within_05: abs(row.ensemble_winner - row.ground_truth) < 0.5)
      }

      // Sort control results by track_id for byte-stable JSON output.
      controlResults.sort { $0.track_id < $1.track_id }

      // Story 4-6 DD #5: assemble corpus distribution stats. Nil when
      // the decode stage was never reached (e.g., the bundled model
      // was absent and BNNS init failed) — Codable encodes that as a
      // JSON null so downstream tooling can detect "decode never ran".
      let corpusDistribution: CorpusDistribution?
      if decodedBpmTotalCount > 0 {
        corpusDistribution = CorpusDistribution(
          wrong_non_abstain_count: wrongNonAbstainCount,
          decoded_bpm_total_count: decodedBpmTotalCount,
          decoded_bpm_histogram_5bpm_bins: decodedBpmHistogram5bpmBins,
          decoded_bpm_in_range_fraction:
            Double(decodedBpmInRangeCount) / Double(decodedBpmTotalCount),
          decoded_bpm_matches_dsp_within_4pct_fraction:
            Double(decodedBpmMatchesDspCount) / Double(decodedBpmTotalCount),
          softmax_max_p50: percentile(softmaxMaxValues, 0.50),
          softmax_max_p95: percentile(softmaxMaxValues, 0.95),
          softmax_margin_p50: percentile(softmaxMarginValues, 0.50),
          softmax_margin_p95: percentile(softmaxMarginValues, 0.95),
          input_feature_checksum_unique_count: inputFeatureChecksumSeen.count)
      } else {
        corpusDistribution = nil
      }

      // Capture canonical provenance for the perf-baselines envelope. The
      // ISO-8601 timestamp is generated TWICE in slightly different forms:
      // `recordedAtISO` (extended form, with `-` and `:`) is what the JSON
      // body carries; `recordedAtBasic` (basic form, no separators) is what
      // the filename uses. The skill's `running-benchmarks` doc explains the
      // double-form rule — extended is for human-readable bodies, basic is
      // for filename-safe segments.
      let isoFormatter = ISO8601DateFormatter()
      isoFormatter.formatOptions = [.withInternetDateTime]
      let now = Date()
      let recordedAtISO = isoFormatter.string(from: now)
      let recordedAtBasic =
        recordedAtISO
        .replacingOccurrences(of: "-", with: "")
        .replacingOccurrences(of: ":", with: "")
      let gitSHA = ProcessInfo.processInfo.environment["GIT_SHA"] ?? "unknown"
      let buildConfig = ImpactBaselineStore.resolveBuildConfiguration()
      let chip = ImpactBaselineStore.resolveChip()
      let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
      let osMajor = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
      let physicalMemoryGiB =
        Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024))

      let report = BNNSImpactReport(
        schema_version: 3,
        recorded_at: recordedAtISO,
        git_sha: gitSHA,
        build_configuration: buildConfig,
        swift_package_version: "BoomBoomBoomKit (workspace HEAD)",
        hardware: HardwareDescriptor(
          chip: chip,
          cores: ProcessInfo.processInfo.processorCount,
          physical_memory_gib: physicalMemoryGiB,
          os_version: osVersion),
        model_identifier: bnnsTechnique.modelIdentifier,
        pinned_config: PinnedConfig(
          intensity: AnalysisIntensity.thorough.level,
          ensemble_policy: String(describing: EnsemblePolicy.mlOnly)),
        named_dnb_track_results: namedResults,
        dsp_correct_control_results: controlResults,
        all_tracks: allRows,
        failure_stage_histogram: failureStageHistogram,
        corpus_distribution: corpusDistribution,
        // Record what the technique ACTUALLY applied, not what was
        // requested: the initializer clamps to [0, 1], so an env override
        // of 1.5 runs inference at 1.0. Reporting the request would make
        // the sweep artifact misdescribe the configuration that produced
        // its own measurements (GH-167 item 6 review).
        applied_thresholds: AppliedThresholds(
          confidence: bnnsTechnique.confidenceThreshold,
          margin: bnnsTechnique.marginThreshold),
        summary: Summary(
          total_tracks: allRows.count,
          dsp_acc1: dspAcc1,
          ml_acc1: mlAcc1,
          ensemble_acc1: ensembleAcc1,
          named_dnb_resolved: namedDnBResolved,
          named_dnb_resolved_via_dsp_fallback: namedDnBResolvedViaDSPFallback,
          named_dnb_total: namedRows.count,
          dsp_correct_controls_preserved: controlsPreserved,
          // Story 4-6 code review P7: denominator is FIXTURE count, not
          // appended count. The drift-detection Issue.record above fires
          // separately when the two diverge.
          dsp_correct_controls_total: dnbControls.count))

      // Resolve output path. Canonical convention (`running-benchmarks`
      // skill): records live under `_bmad-output/perf-baselines/bnns-impact/`
      // with filename `{fingerprint}--{buildConfig}--{recordedAt}--{gitSHA}--{shortUUID}.json`.
      // `BNNS_IMPACT_OUT_DIR` may override the directory (the Makefile sets
      // this to the canonical path; tests run via `swift test` directly
      // fall back to TMPDIR). The legacy `BNNS_IMPACT_OUT_FILENAME` env
      // var is intentionally NOT honored — filename uniqueness is now
      // load-bearing for the per-run-immutability invariant.
      let envValue = ProcessInfo.processInfo.environment["BNNS_IMPACT_OUT_DIR"]
      let outDir: String =
        (envValue.flatMap { $0.isEmpty ? nil : $0 }) ?? NSTemporaryDirectory()
      let fingerprint = ImpactBaselineStore.fingerprintPrefix(chip: chip, osMajor: osMajor)
      let outFilename = ImpactBaselineStore.buildFilename(
        fingerprint: fingerprint,
        buildConfiguration: buildConfig,
        recordedAt: recordedAtBasic,
        gitSHA: gitSHA)
      let outPath = (outDir as NSString)
        .appendingPathComponent(outFilename)

      // Create the output directory if missing (review fix Edge#22) —
      // Makefile invocations create it via `mkdir -p`, but `swift test`
      // invoked directly without `make bnns-impact-report` may not. The
      // intermediate-creation flag is a no-op when the dir exists.
      try FileManager.default.createDirectory(
        atPath: outDir, withIntermediateDirectories: true)

      try ImpactBaselineStore.write(report, to: URL(fileURLWithPath: outPath))

      // Console summary.
      print(
        """

        === BNNS Impact Report (Story 4-6 schema v3) ===
        Output: \(outPath)
        Total tracks: \(allRows.count)
        DSP-only Acc1:    \(dspAcc1)/\(allRows.count)
        ML-only Acc1:     \(mlAcc1)/\(allRows.count)
        Ensemble Acc1:    \(ensembleAcc1)/\(allRows.count)
        Named DnB resolved (±0.5 BPM): \(namedDnBResolved)/\(namedRows.count)
        Controls preserved (±0.5 BPM): \(controlsPreserved)/\(dnbControls.count) (encountered \(controlResults.count) of \(dnbControls.count) on disk)
        """)
      for r in namedResults {
        let line =
          "  - \(r.track_id): ensemble=\(r.ensemble_winner_bpm) gt=\(r.ground_truth_bpm)"
          + " abs_err=\(r.abs_error_bpm) resolved=\(r.resolved_within_05)"
        print(line)
      }
      print("Failure-stage histogram:")
      for key in OutcomeKey.allCases.map(\.rawValue) {
        let count = failureStageHistogram[key] ?? 0
        print("  \(key.padding(toLength: 26, withPad: " ", startingAt: 0)) \(count)")
      }

      // Story 4-6 AC #7: histogram conservation invariant — every track
      // in allRows contributes to exactly one bucket. Story 4-6 code
      // review P18 / Codex Option B added `mlNotRun` and
      // `diagnosticSnapshotMissing` explicit buckets so this invariant
      // holds unconditionally — no out-of-band skip counter required.
      let histogramSum = failureStageHistogram.values.reduce(0, +)
      #expect(
        histogramSum == allRows.count,
        "Histogram conservation: sum=\(histogramSum), allRows.count=\(allRows.count)")

      // HALT (b): assert ≥ `regression_threshold.min_resolved` named DnB
      // triplets resolved within ±`tolerance_bpm`. Both values come from
      // the artifact (review fix N8) so the gate moves with the JSON, not
      // a hardcoded literal that could drift. Soft-record below the
      // threshold so the JSON is still written for triage; the test
      // result still fails for ratchet enforcement.
      if namedDnBResolved < regressionThreshold.min_resolved {
        let msg =
          "HALT (b): only \(namedDnBResolved) of \(namedRows.count) named"
          + " DnB triplets resolved within ±\(regressionThreshold.tolerance_bpm) BPM"
          + " (required ≥ \(regressionThreshold.min_resolved); DSP-fallback"
          + " resolved another \(namedDnBResolvedViaDSPFallback) — does not count)."
          + " See \(outPath) for per-track failure modes."
        Issue.record(Comment(rawValue: msg))
      }

      // Story 4-6 code review P7: assert the control denominator first
      // — the gate measures preservation against the FIXTURE count, not
      // against the count we happened to encounter on disk. If a
      // control track is missing from the corpus directory (renamed,
      // moved, removed), `controlResults.count` shrinks silently and a
      // "4/4 preserved" claim becomes "3/3 preserved" against a
      // 4-element fixture — the gate still passes but the metric is a
      // lie. Loud failure on encounter count drift is the correct
      // surface for this class of corpus-state drift.
      if controlResults.count != dnbControls.count {
        Issue.record(
          Comment(
            rawValue:
              "Control-set drift: encountered \(controlResults.count) of "
              + "\(dnbControls.count) DSP-correct controls on disk. The "
              + "preservation gate is meaningless when the denominator "
              + "shrinks — confirm 4-dnb-triplet-targets.json's "
              + "dsp_correct_controls entries still exist in the corpus "
              + "directory at \(corpusPath)."))
      }

      // Story 4-6 DD #8 + AC #10: symmetric control-preservation gate.
      // Branch A strict requires controls_preserved == controls.count
      // (4/4). Soft-record below the threshold so the JSON still lands;
      // the test result still fails for ratchet enforcement. The branch
      // decision is human-applied at close-out time (per DD #8) — this
      // gate fires the alarm; the dev decides Branch A-conditional vs
      // Branch C based on the surrounding investigation evidence. The
      // denominator is the FIXTURE count (see assertion above) so the
      // gate is robust against corpus-state drift.
      if controlsPreserved < dnbControls.count {
        let msg =
          "Control regression: \(controlsPreserved) of \(dnbControls.count) "
          + "DSP-correct controls preserved within ±0.5 BPM. Branch A strict "
          + "gate requires \(dnbControls.count)/\(dnbControls.count). "
          + "See \(outPath) for per-control failure modes."
        Issue.record(Comment(rawValue: msg))
      }
    }
  }
}

/// Story 4-6 DD #5: percentile of a `[Double]` sample. Returns 0.0 on
/// empty input. Uses lower-rank interpolation (no linear interpolation
/// between adjacent samples) for byte-stable JSON output. `p` in
/// `[0.0, 1.0]`.
private func percentile(_ values: [Double], _ p: Double) -> Double {
  guard !values.isEmpty else { return 0.0 }
  let sorted = values.sorted()
  let clamped = max(0.0, min(1.0, p))
  let idx = Int(clamped * Double(sorted.count - 1))
  return sorted[idx]
}

private enum BNNSImpactError: Error {
  case corpusPathNotSet
  case groundTruthNotFound
  case dnbTargetsNotFound
  case dnbTargetsSchemaMismatch(expected: Int, got: Int)
  case dnbTargetsDuplicateTrackID(String)
  case dnbControlsCountInsufficient(got: Int, required: Int)
  case dnbRegressionThresholdMissing
}

// MARK: - 4-dnb-triplet-targets.json domain model (Story 8.8c: adapted from JAMS)

/// Story 8.8c migrated `4-dnb-triplet-targets.json` to a JAMS corpus, so the file is no
/// longer decoded directly into a wire-format root. The suite decodes the shared
/// ``JAMSCorpus`` and adapts each entry into the thin domain structs below; this
/// namespace retains only the expected-schema constant the loader gates on.
enum DnBTargetsFile {
  /// Expected schema version. Tests refuse to run when the artifact
  /// reports a different version — protects against silently consuming
  /// stale or future-incompatible fixtures. Story 4-6 bumped from 2 → 3;
  /// Story 8.8c reads it from the JAMS corpus-level `sandbox.schema_version`.
  static let expectedSchemaVersion = 3
}

/// Per-track DnB-triplet target row. Adapted from the JAMS `target`-partition entries
/// (Story 8.8c): `track_id` from `identifiers`, `ground_truth_bpm` from the `tempo`
/// observation. Consumed for both ground-truth lookup and named-DnB membership.
struct DnBTarget {
  let track_id: String
  let ground_truth_bpm: Double
}

/// Per-track DSP-correct control row introduced in Story 4-6 DD #4. Adapted from the
/// JAMS `control`-partition entries (Story 8.8c) — same shape as ``DnBTarget`` plus a
/// `rationale` string (from the per-entry sandbox) explaining why each entry qualifies
/// as a control (e.g., DnB-genre, heavily-mastered, in 155-175 BPM band). The control
/// set's symmetric gate (≥4/4 preserved at default config) is the Branch A success
/// criterion alongside ≥2/4 named DnB resolved (DD #8).
struct DnBControl {
  let track_id: String
  let ground_truth_bpm: Double
  /// Plain-text justification for the control's inclusion. Surfaced in
  /// the impact report's per-track row so reviewers can audit the
  /// control set composition.
  let rationale: String
}

/// Regression-threshold envelope from `4-dnb-triplet-targets.json`. Adapted from the
/// JAMS corpus-level `sandbox.regression_threshold` (Story 8.8c). Drives the
/// `min_resolved`, `tolerance_bpm`, `min_oa300_acc1`, and `min_giantsteps_acc1`
/// constants the test asserts against, so changing any value in the artifact propagates
/// to the test gate at load time rather than via separate hardcoded literals.
struct RegressionThreshold {
  let min_resolved: Int
  let tolerance_bpm: Double
  let min_oa300_acc1: Int
  let min_giantsteps_acc1: Int

  /// Adapts the optional-field JAMS threshold sub-object into the non-optional domain
  /// struct, throwing if any required field is absent (a malformed corpus sandbox).
  init(jams: JAMSRegressionThreshold) throws {
    guard let minResolved = jams.minResolved,
      let toleranceBpm = jams.toleranceBpm,
      let minOA300 = jams.minOA300Acc1,
      let minGiantSteps = jams.minGiantStepsAcc1
    else {
      throw BNNSImpactError.dnbRegressionThresholdMissing
    }
    self.min_resolved = minResolved
    self.tolerance_bpm = toleranceBpm
    self.min_oa300_acc1 = minOA300
    self.min_giantsteps_acc1 = minGiantSteps
  }
}

// MARK: - ImpactBaselineStore (Story 4-6 schema v3 — canonical perf-baselines convention)

/// File-naming and atomic-write helpers for bnns-impact records. Mirrors
/// the `BaselineStore` shape from `PerformanceBenchmarkTests.swift` —
/// kept file-local so the two stores don't accidentally share state.
/// Records live in `_bmad-output/perf-baselines/bnns-impact/` (subdirectory
/// of the canonical perf-baselines lane, so the existing v2 perf records
/// and the v3 impact records never collide on filename prefix).
///
/// Filename template: `{fingerprint}--{buildConfig}--{recordedAt}--{gitSHA}--{shortUUID}.json`
///   - `--` (double-hyphen) separates segments — see `running-benchmarks` skill.
///   - `recordedAt` is ISO-8601 basic form (`YYYYMMDDTHHMMSSZ`).
///   - `shortUUID` is 8 lowercase hex chars from a fresh `UUID()`.
///
/// Write is atomic: encode to a `.tmp` sibling, then `moveItem` into
/// place. Failures during write remove the temp file; failures during
/// rename leave the published file untouched.
private enum ImpactBaselineStore {
  private static let separator = "--"

  /// Reads the CPU brand string via `sysctlbyname("machdep.cpu.brand_string")`.
  /// Returns `"unknown"` on any sysctl error so the harness still publishes
  /// a record (the fingerprint just won't disambiguate machines).
  static func resolveChip() -> String {
    var size: size_t = 0
    guard sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0) == 0, size > 0
    else { return "unknown" }
    var buffer = [UInt8](repeating: 0, count: size)
    guard sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0) == 0
    else { return "unknown" }
    if buffer.last == 0 { buffer.removeLast() }
    return String(bytes: buffer, encoding: .utf8) ?? "unknown"
  }

  /// Returns `"Debug"` or `"Release"` based on the test-target compile-time
  /// `#if DEBUG` flag. Same convention as `PerformanceBenchmarkTests`.
  static func resolveBuildConfiguration() -> String {
    #if DEBUG
      return "Debug"
    #else
      return "Release"
    #endif
  }

  /// Sanitizes the chip brand string into a filename-safe segment:
  /// `[A-Za-z0-9_-]` survives, everything else collapses to `_`,
  /// consecutive `_` collapse to one, leading/trailing `_` trim.
  /// Appends `-{osMajor}` so two machines with the same chip on
  /// different macOS majors don't share a fingerprint.
  static func fingerprintPrefix(chip: String, osMajor: Int) -> String {
    var sanitized = String(
      chip.map { c -> Character in
        if c.isLetter || c.isNumber || c == "-" || c == "_" { return c }
        return "_"
      })
    while sanitized.contains("__") {
      sanitized = sanitized.replacingOccurrences(of: "__", with: "_")
    }
    sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    return "\(sanitized)-\(osMajor)"
  }

  /// Builds the canonical filename. `recordedAt` should be ISO-8601 basic
  /// form already (no `-` or `:` separators) — same convention as the
  /// perf-baselines reader's `compactRecordedAt`.
  static func buildFilename(
    fingerprint: String, buildConfiguration: String, recordedAt: String, gitSHA: String
  ) -> String {
    let shortUUID = String(UUID().uuidString.lowercased().prefix(8))
    let s = separator
    return
      "\(fingerprint)\(s)\(buildConfiguration)\(s)\(recordedAt)\(s)\(gitSHA)\(s)\(shortUUID).json"
  }

  /// Atomic temp-then-rename write. Failures during encode/write remove
  /// the `.tmp` file; rename failures leave the published file untouched
  /// (a half-published file would be visible to readers, which is worse
  /// than a missing record).
  static func write(_ report: BNNSImpactReport, to fileURL: URL) throws {
    let tempURL = fileURL.appendingPathExtension("tmp")
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(report)
    do {
      try data.write(to: tempURL)
    } catch {
      try? FileManager.default.removeItem(at: tempURL)
      throw error
    }
    do {
      try FileManager.default.moveItem(at: tempURL, to: fileURL)
    } catch {
      try? FileManager.default.removeItem(at: tempURL)
      throw error
    }
  }
}
