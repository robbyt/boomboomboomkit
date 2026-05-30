# ``BoomBoomBoomKit``

Standalone audio analysis package for BPM estimation and LUFS loudness
measurement on macOS 15+.

## Overview

BoomBoomBoomKit is a pure-Swift library with zero external dependencies — it
uses only Apple's Accelerate (vDSP), AVFoundation, and Foundation. The
public facade is ``AudioAnalysisService``; analysis depth is controlled via
``AnalysisIntensity`` and ``BPMSelectionPolicy``.

## Topics

### Public Facade

- ``AudioAnalysisService``
- ``AudioAnalysisResult``

### Audio I/O

- ``PCMBufferReader``
- ``PCMBufferReaderError``

### Analysis Configuration

- ``AnalysisIntensity``
- ``BPMSelectionPolicy``
- ``TechniqueSet``
- ``DSPTechnique``
- ``VotingPolicy``

### Progress and Cancellation

- ``ProgressUpdate``

### Metadata Corroboration

- ``MetadataPolicy``
- ``MetadataSource``
- ``MetadataBPMEvidence``
- ``HarmonicRatio``

### Diagnostic Trace

- ``BPMDiagnosticTrace``
- ``ClickCorrelationEntry``
- ``HarmonicRatioEvidence``
- ``SubBandVoteEvidence``
- ``SubBandEnergies``
- ``DurationHintEvidence``
- ``BarCandidate``

### ML Augmentation (BYOW)

- ``MLTechnique``
- ``MLEvaluation``
- ``EnsemblePolicy``
- ``EnsembleDecision``

### ML Diagnostics

- ``MLDiagnosticTechnique``
- ``MLDiagnosticSnapshot``
- ``MLFeatureFrames``
- ``TensorLayout``
- ``MLTechniqueError``
