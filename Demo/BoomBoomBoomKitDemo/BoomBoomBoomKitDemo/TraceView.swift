import BoomBoomBoomKit
import SwiftUI

struct TraceView: View {
  let snapshot: LastRunDiagnosticSnapshot
  let finalStep: FinalSelectionStep

  init(snapshot: LastRunDiagnosticSnapshot) {
    self.snapshot = snapshot
    self.finalStep = FinalSelectionStep.derive(
      from: snapshot.trace,
      lastBPM: snapshot.result.bpm
    )
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        runSection
        selectionSection
        candidatesSection
        subBandEnergiesSection
        disambiguationSection
        fineGridSection
        metadataSection
        mlSection
      }
      .padding()
    }
  }

  // MARK: - Section 1: Run

  @ViewBuilder
  private var runSection: some View {
    GroupBox("Run") {
      VStack(alignment: .leading, spacing: 6) {
        LabeledContent("File", value: snapshot.fileName)
        LabeledContent("Intensity (requested)") {
          Text("\(snapshot.runOptions.intensity.rawValue)")
        }
        LabeledContent("Intensity (effective)") {
          Text("\(snapshot.result.effectiveIntensity.rawValue)")
        }
        LabeledContent("Merge strategy", value: snapshot.runOptions.mergeStrategy.rawValue)
        LabeledContent("BPM") {
          monoFloat(snapshot.result.bpm, digits: 2)
        }
        LabeledContent("Confidence") {
          monoFloat(snapshot.result.confidence, digits: 4)
        }
        if let reason = snapshot.result.degradationReason {
          LabeledContent("Degradation", value: reason)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  // MARK: - Section 2: Selection path

  @ViewBuilder
  private var selectionSection: some View {
    GroupBox("Selection path") {
      VStack(alignment: .leading, spacing: 6) {
        LabeledContent("Final step", value: finalStep.rawValue)
        Text(finalStep.reasoning)
          .font(.callout)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  // MARK: - Section 3: Candidates

  @ViewBuilder
  private var candidatesSection: some View {
    GroupBox("Candidates") {
      VStack(alignment: .leading, spacing: 4) {
        LabeledContent("Raw count") {
          Text("\(snapshot.trace.rawCandidates.count)")
        }
        ForEach(Array(snapshot.trace.rawCandidates.enumerated()), id: \.offset) { _, entry in
          candidateRow(bpm: entry.bpm, score: entry.score)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  @ViewBuilder
  private func candidateRow(bpm: Double, score: Float) -> some View {
    HStack {
      Text(String(format: "%.1f BPM", bpm)).monospacedDigit()
      Spacer()
      Text(String(format: "score: %.3f", score)).monospacedDigit()
        .foregroundStyle(.secondary)
    }
    .font(.caption)
  }

  // MARK: - Section 4: Sub-band energies

  @ViewBuilder
  private var subBandEnergiesSection: some View {
    let energies = snapshot.trace.subBandEnergies
    GroupBox("Sub-band energies") {
      VStack(alignment: .leading, spacing: 4) {
        energyRow("Kick", energies.kick)
        energyRow("Snare", energies.snare)
        energyRow("Crack", energies.crack)
        energyRow("Hi-hat", energies.hihat)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  @ViewBuilder
  private func energyRow(_ label: String, _ value: Float) -> some View {
    LabeledContent(label) {
      monoFloat(Double(value), digits: 4)
    }
  }

  // MARK: - Section 5: Disambiguation

  @ViewBuilder
  private var disambiguationSection: some View {
    GroupBox("Disambiguation") {
      VStack(alignment: .leading, spacing: 4) {
        LabeledContent("Winner BPM") {
          monoFloat(snapshot.trace.disambiguationResult.bpm, digits: 2)
        }
        LabeledContent("Winner score") {
          monoFloat(Double(snapshot.trace.disambiguationResult.score), digits: 3)
        }
        if let ratio = snapshot.trace.harmonicRatioDetail {
          LabeledContent("Harmonic ratio", value: ratio.ratio)
          LabeledContent("Ratio winner") {
            monoFloat(ratio.winnerBPM, digits: 2)
          }
        }
        if let vote = snapshot.trace.subBandVoteDetail {
          LabeledContent("Sub-band vote pre") {
            monoFloat(vote.preVoteBPM, digits: 2)
          }
          LabeledContent("Sub-band vote post") {
            monoFloat(vote.postVoteBPM, digits: 2)
          }
          LabeledContent("Vote changed", value: vote.changed ? "yes" : "no")
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  // MARK: - Section 6: Fine-grid

  @ViewBuilder
  private var fineGridSection: some View {
    GroupBox("Fine-grid refinement") {
      VStack(alignment: .leading, spacing: 4) {
        if let refined = snapshot.trace.refinedBPM {
          LabeledContent("Refined BPM") {
            monoFloat(refined, digits: 4)
          }
        } else {
          Text("(not run)").foregroundStyle(.secondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  // MARK: - Section 7: Metadata corroboration

  @ViewBuilder
  private var metadataSection: some View {
    GroupBox("Metadata corroboration") {
      VStack(alignment: .leading, spacing: 6) {
        LabeledContent("Enabled sources") {
          let sources = snapshot.runOptions.metadataPolicyEnabledSources
            .map(\.rawValue)
            .sorted()
            .joined(separator: ", ")
          Text(sources.isEmpty ? "(none)" : sources)
            .foregroundStyle(.secondary)
        }
        if snapshot.metadataEvidence.isEmpty {
          Text("(no tags read)").foregroundStyle(.secondary)
        } else {
          ForEach(Array(snapshot.metadataEvidence.enumerated()), id: \.offset) { _, evidence in
            metadataRow(evidence)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  @ViewBuilder
  private func metadataRow(_ evidence: MetadataBPMEvidence) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        Text(evidence.source.rawValue).font(.caption).bold()
        Spacer()
        if evidence.parsedBPM.isFinite {
          Text(String(format: "%.2f BPM", evidence.parsedBPM))
            .font(.caption).monospacedDigit()
        } else {
          Text("(parse rejected)")
            .font(.caption).foregroundStyle(.secondary)
        }
      }
      if let reason = evidence.rejectionReason {
        Text("rejected: \(reason)")
          .font(.caption2).foregroundStyle(.secondary)
      } else if let corroborated = evidence.corroboratedWith {
        Text(
          String(
            format: "corroborated with %.2f (boost %.2f×)",
            corroborated, evidence.boostApplied)
        )
        .font(.caption2).foregroundStyle(.secondary)
      }
    }
  }

  // MARK: - Section 8: ML ensemble

  @ViewBuilder
  private var mlSection: some View {
    let trace = snapshot.trace
    let hasAnyML =
      trace.ensembleDecision != nil
      || trace.mlDiagnosticSnapshot != nil
      || trace.mlFeatures != nil
    GroupBox("ML ensemble") {
      VStack(alignment: .leading, spacing: 4) {
        if !hasAnyML {
          Text("(ML not active)").foregroundStyle(.secondary)
        } else {
          if let decision = trace.ensembleDecision {
            LabeledContent("Policy", value: decision.policy.rawValue)
            LabeledContent("Winner", value: decision.winner.rawValue)
            LabeledContent("DSP confidence") {
              monoFloat(Double(decision.dspConfidence), digits: 4)
            }
            if let mlConf = decision.mlConfidence {
              LabeledContent("ML confidence") {
                monoFloat(Double(mlConf), digits: 4)
              }
            }
            LabeledContent("ML abstained", value: decision.mlAbstained ? "yes" : "no")
            LabeledContent("Selected BPM") {
              monoFloat(decision.selectedBPM, digits: 2)
            }
          } else {
            Text("(ensemble decision absent — ML abstained pre-ensemble)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          if let diag = trace.mlDiagnosticSnapshot {
            mlDiagnosticRows(diag)
          }
          if let features = trace.mlFeatures {
            Text(
              "Log-mel tensor: \(features.melBands) × \(features.frames) "
                + "(payload omitted from export — large tensor)"
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  @ViewBuilder
  private func mlDiagnosticRows(_ diag: MLDiagnosticSnapshot) -> some View {
    if let decoded = diag.decodedBPM {
      LabeledContent("ML decoded BPM") {
        monoFloat(decoded, digits: 2)
      }
    }
    if let softmaxMax = diag.softmaxMax {
      LabeledContent("Softmax max") {
        monoFloat(softmaxMax, digits: 4)
      }
    }
    if let softmaxSecondMax = diag.softmaxSecondMax {
      LabeledContent("Softmax 2nd") {
        monoFloat(softmaxSecondMax, digits: 4)
      }
    }
    if let failure = diag.failureStage {
      LabeledContent("Failure stage", value: failure.rawValue)
    }
    if let gate = diag.gateFired {
      LabeledContent("Gate fired", value: gate.rawValue)
    }
    // Surface the feature checksum so the user can correlate this run's
    // ML input with the JSON export when diagnosing inference drift.
    LabeledContent("Input feature checksum") {
      Text(String(diag.inputFeatureChecksum)).monospacedDigit()
    }
  }

  // MARK: - Formatting helper

  @ViewBuilder
  private func monoFloat(_ value: Double, digits: Int) -> some View {
    Text(String(format: "%.\(digits)f", value)).monospacedDigit()
  }
}

struct TraceInspectorEmptyView: View {
  var body: some View {
    VStack(spacing: 8) {
      Text("Diagnostic Trace")
        .font(.title3)
      Text("Drop a track to analyze.\nThe pipeline trace appears here.")
        .font(.callout)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
}

// P_D5 / D5 resolution (code review 2026-05-23): in-flight placeholder
// surfaced while `viewModel.isAnalyzing == true` AND `lastRunSnapshot`
// is nil (the analyze-prologue reset window). Avoids the empty-state
// flash that would otherwise read "drop a track to analyze" mid-run,
// which is misleading — the user just dropped something and a run is
// in progress.
struct TraceInspectorAnalyzingView: View {
  var body: some View {
    VStack(spacing: 12) {
      ProgressView()
      Text("Analyzing\u{2026}")
        .font(.callout)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Diagnostic trace, analysis in progress")
  }
}
