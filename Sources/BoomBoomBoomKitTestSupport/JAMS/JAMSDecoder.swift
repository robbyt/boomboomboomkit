//
//  JAMSDecoder.swift
//  BoomBoomBoomKit
//
//  Shared JAMS (JSON Annotated Music Specification) decoder/encoder for the
//  ground-truth annotation corpora. Introduced in Story 8.7 (beat-grid acceptance,
//  benchmark-target-internal); RELOCATED here and made public in Story 8.8a.
//
//  DD-1 (Story 8.8a) reverses 8.7 DD-7 (which kept this decoder internal to the
//  benchmark test target so MIR format never reached consumer packages). The
//  shipping corpus decoders `OA300Track` / `DAWOracleTrack` live in this target and
//  must decode JAMS once the oracle/sentinel artifacts migrate (Stories 8.8b/8.8c),
//  so the model lives here — the single home reachable by every consumer. The
//  "don't leak MIR format" constraint is retired for a pre-1.0, unshipped library.
//
//  Decodes the multi-track `{ "entries": [ <JAMS> ] }` corpus wrapper (DD-9) plus the
//  `beat` / `tempo` namespaces, and round-trips both ways so benchmarks can ENCODE.
//
//  Compliance contract (JAMS 0.4, marl/jams-schema): the `entries` wrapper is
//  intentionally NOT a JAMS file (the schema root admits only file_metadata /
//  annotations / sandbox), so it is an internal corpus container; the strict-validity
//  claim is PER-ENTRY — each `entries[i]` is a standalone-valid JAMS object. The model
//  is tolerant on decode (optional fields, `decodeIfPresent`) but strict on encode for
//  the emitted `beat` and `tempo` namespaces (required keys always written; `tempo`
//  additionally guards a non-null numeric `value` + `confidence ∈ [0, 1]` — Story 8.8a).
//

import Foundation

// MARK: - JAMSDecodingError

/// Typed decode failure. An unknown namespace is rejected (never silently
/// defaulted) — the decoder must reject namespaces it does not model rather than
/// mis-interpret their `value` semantics.
public enum JAMSDecodingError: Error, Equatable, Sendable {
  case unknownNamespace(String)
}

// MARK: - JAMSEncodingError

/// Typed encode failure for the strict `tempo` emit path (Story 8.8a). The generic
/// `Codable` encoder cannot validate value semantics, so encoding a `tempo`
/// observation guards the JAMS 0.4 `tempo`-namespace requirements explicitly: a
/// non-null numeric `value` and a `confidence ∈ [0, 1]`.
public enum JAMSEncodingError: Error, Equatable, Sendable {
  /// A `tempo` observation carried a nil or non-finite `value`.
  case tempoValueMissing
  /// A `tempo` observation carried a nil or out-of-`[0, 1]` `confidence`.
  case tempoConfidenceOutOfRange(Double?)
}

// MARK: - JAMSValidationError

/// Typed failure for the artifact-level accessors (Story 8.8a). The typed multi-artifact
/// ``JAMSSandbox`` union makes cross-artifact-invalid payloads representable, so these
/// accessors fail loudly on a missing required field rather than handing callers a raw
/// optional. (Genre loud-fail lives in `OA300Track.init(jamsFile:)`, which throws
/// `DecodingError` to preserve the flat decoder's contract.)
public enum JAMSValidationError: Error, Equatable, Sendable {
  case missingTempoObservation
  case missingDnBPartition
  case missingDnBTrackID
  case unknownDnBPartition(String)
}

// MARK: - Tolerant decode helper

extension KeyedDecodingContainer {
  /// Decode an optional `Bool`, tolerating a present-but-non-Bool payload (decodes to
  /// `nil` rather than throwing). The shared tolerant-on-decode rule for the legacy
  /// `constant_tempo` / `rekordbox_disagrees` flags that older artifacts wrote loosely.
  func decodeTolerantBoolIfPresent(forKey key: Key) -> Bool? {
    (try? decodeIfPresent(Bool.self, forKey: key)) ?? nil
  }
}

// MARK: - JAMSNamespace

/// The JAMS annotation namespaces this decoder models. `beat` (8.7 oracle) carries
/// a per-beat bar-phase `value` (`1` = downbeat); `tempo` (8.8 migrated artifacts)
/// carries a BPM `value`. Both have a numeric `value` that ``JAMSValue`` represents
/// faithfully. The `tag_open` namespace (a required *string* `value`) is deliberately
/// NOT modeled — ``JAMSValue`` is numeric-only and would throw on its string payload,
/// so claiming support would be false. Any unmodeled namespace throws
/// ``JAMSDecodingError/unknownNamespace(_:)``.
public enum JAMSNamespace: String, Codable, Equatable, Sendable {
  case tempo
  case beat

  public init(from decoder: any Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    guard let ns = JAMSNamespace(rawValue: raw) else {
      throw JAMSDecodingError.unknownNamespace(raw)
    }
    self = ns
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

// MARK: - JAMSValue

/// A JAMS observation `value`. Namespace-polymorphic — a `beat` bar-phase (`1...4`,
/// `1` = downbeat) or a `tempo` BPM — carried as a single `Double` so both shapes
/// round-trip through one type. JSON `null`/absent maps to `nil` at the
/// ``JAMSObservation/value`` optional, so this type is only ever constructed for a
/// present, non-null number.
public struct JAMSValue: Codable, Equatable, Sendable {
  /// The raw numeric value (a whole `beat` phase decodes as e.g. `1.0`).
  public let number: Double

  /// Nearest-integer view, for bar-phase comparisons (`value.int == 1` → downbeat).
  /// Irrelevant for `tempo`, where callers read ``number`` directly.
  public var int: Int { Int(number.rounded()) }

  public init(_ number: Double) { self.number = number }

  public init(from decoder: any Decoder) throws {
    number = try decoder.singleValueContainer().decode(Double.self)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(number)
  }
}

// MARK: - JAMSObservation

/// One sparse JAMS observation: a `time` (seconds), an optional namespace-polymorphic
/// `value`, an optional `confidence`, and a `duration` (`0` for instantaneous beats /
/// constant-tempo markers).
public struct JAMSObservation: Codable, Equatable, Sendable {
  public let time: Double
  public let value: JAMSValue?
  public let confidence: Double?
  public let duration: Double

  public init(time: Double, value: JAMSValue?, confidence: Double?, duration: Double) {
    self.time = time
    self.value = value
    self.confidence = confidence
    self.duration = duration
  }

  public init(from decoder: any Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    time = try c.decode(Double.self, forKey: .time)
    value = try c.decodeIfPresent(JAMSValue.self, forKey: .value)
    confidence = try c.decodeIfPresent(Double.self, forKey: .confidence)
    duration = try c.decodeIfPresent(Double.self, forKey: .duration) ?? 0
  }

  public func encode(to encoder: any Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(time, forKey: .time)
    // Strict-on-encode (JAMS 0.4 SparseObservation requires time/duration/value/
    // confidence): always write `value` and `confidence` — a nil optional encodes as
    // JSON `null`, which the `beat` namespace permits for both. `encodeIfPresent`
    // would omit the key and break required-field validity. The `tempo`-namespace
    // additional guard (non-null value + confidence ∈ [0,1]) is applied by
    // ``JAMSAnnotation/encode(to:)`` before this runs.
    try c.encode(value, forKey: .value)
    try c.encode(confidence, forKey: .confidence)
    try c.encode(duration, forKey: .duration)
  }

  private enum CodingKeys: String, CodingKey {
    case time, value, confidence, duration
  }
}

// MARK: - JAMSAnnotation

/// One JAMS annotation: a namespace plus its sparse observation list and optional
/// provenance metadata.
///
/// Strict-on-encode (Story 8.8a) is guaranteed for both emitted namespaces:
/// `annotation_metadata` is always written (JAMS 0.4 marks it required), the
/// observation encoder always writes `value`/`confidence`, AND a `.tempo` annotation
/// additionally guards each observation for a non-null numeric `value` + a
/// `confidence ∈ [0, 1]` (``JAMSEncodingError``) — the JAMS 0.4 `tempo`-namespace
/// requirements the generic encoder cannot validate.
public struct JAMSAnnotation: Codable, Equatable, Sendable {
  public let namespace: JAMSNamespace
  public let data: [JAMSObservation]
  public let annotationMetadata: JAMSAnnotationMetadata?

  public init(
    namespace: JAMSNamespace, data: [JAMSObservation],
    annotationMetadata: JAMSAnnotationMetadata? = nil
  ) {
    self.namespace = namespace
    self.data = data
    self.annotationMetadata = annotationMetadata
  }

  // `init(from:)` is the compiler-synthesized decoder (namespace/data decoded,
  // annotationMetadata `decodeIfPresent`) — only the strict `encode(to:)` below is custom.

  public func encode(to encoder: any Encoder) throws {
    // Strict `tempo` guard (Story 8.8a): validate BEFORE the observation encoder writes
    // a schema-invalid null value/confidence. `beat` is unaffected (it permits null).
    if namespace == .tempo {
      for obs in data {
        guard let v = obs.value, v.number.isFinite else {
          throw JAMSEncodingError.tempoValueMissing
        }
        guard let conf = obs.confidence, (0.0...1.0).contains(conf) else {
          throw JAMSEncodingError.tempoConfidenceOutOfRange(obs.confidence)
        }
      }
    }
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(namespace, forKey: .namespace)
    try c.encode(data, forKey: .data)
    // `annotation_metadata` is required by JAMS 0.4. Always write it; when the model
    // carries none, emit an empty object (AnnotationMetadata has no required
    // sub-fields) so the entry stays standalone-valid.
    try c.encode(
      annotationMetadata ?? JAMSAnnotationMetadata(curator: nil, dataSource: nil),
      forKey: .annotationMetadata)
  }

  private enum CodingKeys: String, CodingKey {
    case namespace, data
    case annotationMetadata = "annotation_metadata"
  }
}

/// Annotation provenance: who curated it and what the underlying source was.
/// `version` (Story 12.3) is the JAMS `annotation_metadata.version` — the declared
/// annotation version consumed by `AnnotationVersion` resolution. No shipped corpus
/// declares one today (verified 2026-08-07); the field makes a declared version
/// representable at all. NEVER confuse it with `file_metadata.jams_version`, the
/// JAMS FORMAT version.
public struct JAMSAnnotationMetadata: Codable, Equatable, Sendable {
  public let curator: JAMSCurator?
  public let dataSource: String?
  public let version: String?

  public init(curator: JAMSCurator?, dataSource: String?, version: String? = nil) {
    self.curator = curator
    self.dataSource = dataSource
    self.version = version
  }

  private enum CodingKeys: String, CodingKey {
    case curator
    case dataSource = "data_source"
    case version
  }
}

/// A JAMS curator identity (name + email).
public struct JAMSCurator: Codable, Equatable, Sendable {
  public let name: String?
  public let email: String?

  public init(name: String?, email: String?) {
    self.name = name
    self.email = email
  }
}

// MARK: - JAMSFileMetadata

/// Per-track JAMS file metadata. ``identifiers`` carries the basename / on-disk
/// path / Rekordbox `track_id` join keys the benchmarks use to locate audio and to
/// pair estimated beats / migrated tempo against the oracle.
public struct JAMSFileMetadata: Codable, Equatable, Sendable {
  public let title: String?
  public let artist: String?
  public let duration: Double?
  /// JAMS spec version (`jams.json` requires it, pattern `^0\.[2-4]\.[0-9]+$`).
  /// Decoded tolerantly (`nil` on a payload that predates it) but always written on
  /// encode (fallback `"0.4.0"`) so every emitted entry is standalone-valid.
  public let jamsVersion: String?
  public let identifiers: JAMSIdentifiers?
  /// LEGACY decode-only fallback: a `constant_tempo` flag that older oracles wrote here
  /// before it moved to the top-level `sandbox` (its strict-valid home). Read so a stale
  /// oracle is not silently mis-scoped as constant-tempo (tolerant-on-decode), but NEVER
  /// re-encoded — `encode` omits it so emitted entries stay `jams.load`-valid. Prefer
  /// ``JAMSFile/constantTempo``, which reads `sandbox` first and falls back to this.
  public let constantTempo: Bool?

  public init(
    title: String?, artist: String?, duration: Double?,
    identifiers: JAMSIdentifiers?, jamsVersion: String? = "0.4.0", constantTempo: Bool? = nil
  ) {
    self.title = title
    self.artist = artist
    self.duration = duration
    self.identifiers = identifiers
    self.jamsVersion = jamsVersion
    self.constantTempo = constantTempo
  }

  public init(from decoder: any Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    title = try c.decodeIfPresent(String.self, forKey: .title)
    artist = try c.decodeIfPresent(String.self, forKey: .artist)
    duration = try c.decodeIfPresent(Double.self, forKey: .duration)
    jamsVersion = try c.decodeIfPresent(String.self, forKey: .jamsVersion)
    identifiers = try c.decodeIfPresent(JAMSIdentifiers.self, forKey: .identifiers)
    // Tolerant on decode (parity with eval-beatgrid.py, which coerces a non-bool to its
    // default): a present but non-Bool `constant_tempo` decodes to nil rather than throwing.
    constantTempo = c.decodeTolerantBoolIfPresent(forKey: .constantTempo)
  }

  public func encode(to encoder: any Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encodeIfPresent(title, forKey: .title)
    try c.encodeIfPresent(artist, forKey: .artist)
    // JAMS 0.4 requires `duration` and `jams_version`; always write them (concrete
    // fallbacks) so the entry stays standalone-valid even if the model left them nil.
    try c.encode(duration ?? 0, forKey: .duration)
    try c.encode(jamsVersion ?? "0.4.0", forKey: .jamsVersion)
    try c.encodeIfPresent(identifiers, forKey: .identifiers)
    // `constantTempo` is intentionally NOT written here — its strict-valid home is the
    // top-level `sandbox`; emitting it in file_metadata would break `jams.load`.
  }

  private enum CodingKeys: String, CodingKey {
    case title, artist, duration
    case jamsVersion = "jams_version"
    case identifiers
    case constantTempo = "constant_tempo"
  }
}

/// JAMS `identifiers` join keys. `trackId` is the unique, stable join key between
/// the oracle and the estimated corpus; `localPath` is the audio file to analyze
/// (relative to the corpus root: `"<subdir>/<basename>"` or just `"<basename>"`).
public struct JAMSIdentifiers: Codable, Equatable, Sendable {
  public let basename: String?
  public let localPath: String?
  public let trackId: String?

  public init(basename: String?, localPath: String?, trackId: String?) {
    self.basename = basename
    self.localPath = localPath
    self.trackId = trackId
  }

  private enum CodingKeys: String, CodingKey {
    case basename
    case localPath = "local_path"
    case trackId = "track_id"
  }
}

// MARK: - JAMSSandbox

/// The JAMS per-entry `sandbox` — a free-form object for non-standard, pipeline-only
/// data. The real `jams` library constructs a typed `FileMetadata` and rejects unknown
/// keys there, but accepts arbitrary attributes on `sandbox`, so every artifact-specific
/// extra rides here.
///
/// Modeled as a TYPED union of optional fields (Story 8.8a) rather than `[String: Any]`
/// — the project bans untyped dictionaries in carried payloads. The union spans all three
/// migrated artifacts (a given entry populates only its relevant subset); the
/// artifact-level accessors on ``JAMSFile`` enforce required fields rather than leaving
/// callers to read raw optionals.
public struct JAMSSandbox: Codable, Equatable, Sendable {
  /// Beat-oracle constant-tempo flag (Story 8.7; strict-valid home for `constant_tempo`).
  public let constantTempo: Bool?
  /// OA300 genre label (no JAMS `file_metadata` slot exists for genre).
  public let genre: String?
  /// Raw corpus subdir (also folded into `identifiers.local_path`); `nil` for a flat corpus.
  public let subdir: String?
  /// DAW-oracle Rekordbox cross-check fields (canonical tempo is `daw_bpm`).
  public let rekordboxBpm: Double?
  public let rekordboxDisagrees: Bool?
  public let disagreementType: String?
  /// DnB regression-config per-entry fields.
  public let partition: String?
  public let source: String?
  public let currentPredictedBpm: Double?
  public let currentAbsError: Double?
  public let rationale: String?

  public init(
    constantTempo: Bool? = nil,
    genre: String? = nil,
    subdir: String? = nil,
    rekordboxBpm: Double? = nil,
    rekordboxDisagrees: Bool? = nil,
    disagreementType: String? = nil,
    partition: String? = nil,
    source: String? = nil,
    currentPredictedBpm: Double? = nil,
    currentAbsError: Double? = nil,
    rationale: String? = nil
  ) {
    self.constantTempo = constantTempo
    self.genre = genre
    self.subdir = subdir
    self.rekordboxBpm = rekordboxBpm
    self.rekordboxDisagrees = rekordboxDisagrees
    self.disagreementType = disagreementType
    self.partition = partition
    self.source = source
    self.currentPredictedBpm = currentPredictedBpm
    self.currentAbsError = currentAbsError
    self.rationale = rationale
  }

  public init(from decoder: any Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    // Tolerant on decode: a present but non-Bool `constant_tempo` decodes to nil, not a throw.
    constantTempo = c.decodeTolerantBoolIfPresent(forKey: .constantTempo)
    genre = try c.decodeIfPresent(String.self, forKey: .genre)
    subdir = try c.decodeIfPresent(String.self, forKey: .subdir)
    rekordboxBpm = try c.decodeIfPresent(Double.self, forKey: .rekordboxBpm)
    rekordboxDisagrees = c.decodeTolerantBoolIfPresent(forKey: .rekordboxDisagrees)
    disagreementType = try c.decodeIfPresent(String.self, forKey: .disagreementType)
    partition = try c.decodeIfPresent(String.self, forKey: .partition)
    source = try c.decodeIfPresent(String.self, forKey: .source)
    currentPredictedBpm = try c.decodeIfPresent(Double.self, forKey: .currentPredictedBpm)
    currentAbsError = try c.decodeIfPresent(Double.self, forKey: .currentAbsError)
    rationale = try c.decodeIfPresent(String.self, forKey: .rationale)
  }

  public func encode(to encoder: any Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encodeIfPresent(constantTempo, forKey: .constantTempo)
    try c.encodeIfPresent(genre, forKey: .genre)
    try c.encodeIfPresent(subdir, forKey: .subdir)
    try c.encodeIfPresent(rekordboxBpm, forKey: .rekordboxBpm)
    try c.encodeIfPresent(rekordboxDisagrees, forKey: .rekordboxDisagrees)
    try c.encodeIfPresent(disagreementType, forKey: .disagreementType)
    try c.encodeIfPresent(partition, forKey: .partition)
    try c.encodeIfPresent(source, forKey: .source)
    try c.encodeIfPresent(currentPredictedBpm, forKey: .currentPredictedBpm)
    try c.encodeIfPresent(currentAbsError, forKey: .currentAbsError)
    try c.encodeIfPresent(rationale, forKey: .rationale)
  }

  private enum CodingKeys: String, CodingKey {
    case constantTempo = "constant_tempo"
    case genre, subdir
    case rekordboxBpm = "rekordbox_bpm"
    case rekordboxDisagrees = "rekordbox_disagrees"
    case disagreementType = "disagreement_type"
    case partition, source
    case currentPredictedBpm = "current_predicted_bpm"
    case currentAbsError = "current_abs_error"
    case rationale
  }
}

// MARK: - JAMSCorpusSandbox

/// Corpus-level (`{entries, sandbox}`) free-form metadata. Carries the DnB
/// regression-config fields that are not per-track (Story 8.8c): `schema_version`,
/// `regression_threshold`, and the `captured_with` provenance block. Typed, optional,
/// `nil` for the plain per-track corpora (oa300 / daw).
public struct JAMSCorpusSandbox: Codable, Equatable, Sendable {
  public let schemaVersion: Int?
  public let regressionThreshold: JAMSRegressionThreshold?
  public let capturedWith: JAMSCapturedWith?

  public init(
    schemaVersion: Int? = nil,
    regressionThreshold: JAMSRegressionThreshold? = nil,
    capturedWith: JAMSCapturedWith? = nil
  ) {
    self.schemaVersion = schemaVersion
    self.regressionThreshold = regressionThreshold
    self.capturedWith = capturedWith
  }

  private enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case regressionThreshold = "regression_threshold"
    case capturedWith = "captured_with"
  }
}

/// DnB regression-config thresholds (corpus-level sandbox sub-object).
public struct JAMSRegressionThreshold: Codable, Equatable, Sendable {
  public let minResolved: Int?
  public let toleranceBpm: Double?
  public let minOA300Acc1: Int?
  public let minGiantStepsAcc1: Int?

  public init(
    minResolved: Int?, toleranceBpm: Double?, minOA300Acc1: Int?, minGiantStepsAcc1: Int?
  ) {
    self.minResolved = minResolved
    self.toleranceBpm = toleranceBpm
    self.minOA300Acc1 = minOA300Acc1
    self.minGiantStepsAcc1 = minGiantStepsAcc1
  }

  private enum CodingKeys: String, CodingKey {
    case minResolved = "min_resolved"
    case toleranceBpm = "tolerance_bpm"
    case minOA300Acc1 = "min_oa300_acc1"
    case minGiantStepsAcc1 = "min_giantsteps_acc1"
  }
}

/// DnB regression-config capture provenance (corpus-level sandbox sub-object).
public struct JAMSCapturedWith: Codable, Equatable, Sendable {
  public let capturedAt: String?
  public let capturedBy: String?
  public let gitSha: String?
  public let macosVersion: String?
  public let xcodeVersion: String?
  public let swiftVersion: String?
  public let note: String?

  public init(
    capturedAt: String? = nil, capturedBy: String? = nil, gitSha: String? = nil,
    macosVersion: String? = nil, xcodeVersion: String? = nil, swiftVersion: String? = nil,
    note: String? = nil
  ) {
    self.capturedAt = capturedAt
    self.capturedBy = capturedBy
    self.gitSha = gitSha
    self.macosVersion = macosVersion
    self.xcodeVersion = xcodeVersion
    self.swiftVersion = swiftVersion
    self.note = note
  }

  private enum CodingKeys: String, CodingKey {
    case capturedAt = "captured_at"
    case capturedBy = "captured_by"
    case gitSha = "git_sha"
    case macosVersion = "macos_version"
    case xcodeVersion = "xcode_version"
    case swiftVersion = "swift_version"
    case note
  }
}

// MARK: - JAMSFile

/// A standalone-valid JAMS object: top-level `file_metadata` + `annotations` (+ optional
/// `sandbox`). DD-9 — each corpus entry is independently valid and loadable by the real
/// `jams` library.
public struct JAMSFile: Codable, Equatable, Sendable {
  public let fileMetadata: JAMSFileMetadata
  public let annotations: [JAMSAnnotation]
  public let sandbox: JAMSSandbox?

  public init(
    fileMetadata: JAMSFileMetadata, annotations: [JAMSAnnotation], sandbox: JAMSSandbox? = nil
  ) {
    self.fileMetadata = fileMetadata
    self.annotations = annotations
    self.sandbox = sandbox
  }

  /// `constant_tempo` provenance: the `sandbox` (its strict-valid home) first, falling
  /// back to the legacy `file_metadata.constant_tempo` so a stale oracle that predates the
  /// relocation is still read correctly rather than silently defaulting to constant-tempo.
  public var constantTempo: Bool? { sandbox?.constantTempo ?? fileMetadata.constantTempo }

  private enum CodingKeys: String, CodingKey {
    case fileMetadata = "file_metadata"
    case annotations, sandbox
  }
}

// MARK: - JAMSCorpus

/// The multi-track corpus wrapper `{ "entries": [ <JAMSFile> ] }` (DD-9) plus an optional
/// corpus-level `sandbox` (Story 8.8c — DnB regression-config fields). Other corpus-level
/// sibling keys (`corpus`, `xml_source`, `track_count`, …) are ignored on decode, so the
/// per-track objects stay standalone-valid and a future split-to-N-`.jams` is lossless
/// (`entries.map { write($0) }`).
public struct JAMSCorpus: Codable, Equatable, Sendable {
  public let entries: [JAMSFile]
  public let sandbox: JAMSCorpusSandbox?

  public init(entries: [JAMSFile], sandbox: JAMSCorpusSandbox? = nil) {
    self.entries = entries
    self.sandbox = sandbox
  }

  // Codable is fully synthesized: `entries` decodes, `sandbox` is `decodeIfPresent`.

  private enum CodingKeys: String, CodingKey {
    case entries, sandbox
  }
}

// MARK: - JAMSDnBEntry

/// A DnB regression-config entry resolved from a JAMS corpus: the source ``JAMSFile``
/// plus the join key and tempo every DnB reader needs, with the `partition` already
/// classified. Produced by ``JAMSCorpus/dnbPartitioned()``.
public struct JAMSDnBEntry: Sendable {
  public let file: JAMSFile
  public let trackID: String
  public let bpm: Double
}

// MARK: - Convenience accessors

extension JAMSCorpus {
  /// Splits the DnB regression-config corpus into its `target` and `control` partitions,
  /// enforcing the invariants every DnB reader needs: each entry carries a non-nil
  /// `track_id`, a numeric `tempo` value, and a `partition ∈ {target, control}`. Throws
  /// on any violation — an absent/unknown `partition`
  /// (``JAMSValidationError/missingDnBPartition`` / ``JAMSValidationError/unknownDnBPartition(_:)``),
  /// a missing `track_id` (``JAMSValidationError/missingDnBTrackID``), or a missing tempo
  /// (``JAMSValidationError/missingTempoObservation``) — so a malformed entry fails loudly
  /// instead of being silently dropped. Completeness is implied: every entry lands in
  /// exactly one partition or the call throws.
  public func dnbPartitioned() throws -> (targets: [JAMSDnBEntry], controls: [JAMSDnBEntry]) {
    var targets: [JAMSDnBEntry] = []
    var controls: [JAMSDnBEntry] = []
    for entry in entries {
      guard let trackID = entry.fileMetadata.identifiers?.trackId else {
        throw JAMSValidationError.missingDnBTrackID
      }
      let resolved = JAMSDnBEntry(file: entry, trackID: trackID, bpm: try entry.tempoBPM())
      switch try entry.dnbPartition() {
      case "target": targets.append(resolved)
      case "control": controls.append(resolved)
      case let other: throw JAMSValidationError.unknownDnBPartition(other)
      }
    }
    return (targets, controls)
  }
}

extension JAMSFile {
  /// The first `beat`-namespace annotation, or `nil` if the file carries none.
  public var beatAnnotation: JAMSAnnotation? {
    annotations.first { $0.namespace == .beat }
  }

  /// The first `tempo`-namespace annotation, or `nil` if the file carries none.
  public var tempoAnnotation: JAMSAnnotation? {
    annotations.first { $0.namespace == .tempo }
  }

  /// The migrated tempo BPM: the first `tempo` observation's numeric `value`.
  /// Throws ``JAMSValidationError/missingTempoObservation`` if no `tempo` annotation
  /// carries a non-null `value` (the typed-union sandbox makes this representable).
  public func tempoBPM() throws -> Double {
    guard let value = tempoAnnotation?.data.first(where: { $0.value != nil })?.value else {
      throw JAMSValidationError.missingTempoObservation
    }
    return value.number
  }

  /// The DnB regression-config partition (`"target"` / `"control"`) from the sandbox.
  /// Throws ``JAMSValidationError/missingDnBPartition`` when absent.
  public func dnbPartition() throws -> String {
    guard let partition = sandbox?.partition else {
      throw JAMSValidationError.missingDnBPartition
    }
    return partition
  }
}

extension JAMSAnnotation {
  /// Beat times in seconds (sorted ascending), for `mir_eval`-style position scoring.
  public var beatTimes: [Double] { data.map(\.time).sorted() }

  /// Downbeat times: observations whose bar-phase ``JAMSValue/int`` is `1`
  /// (a non-nil `value == 1`), sorted ascending.
  public var downbeatTimes: [Double] {
    data.filter { $0.value?.int == 1 }.map(\.time).sorted()
  }
}
