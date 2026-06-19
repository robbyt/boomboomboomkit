//
//  JAMSDecoder.swift
//  BoomBoomBoomKit
//
//  Benchmark-target-internal JAMS (JSON Annotated Music Specification) decoder
//  for the Story-8.7 beat-grid acceptance corpus. NOT in BoomBoomBoomKitTestSupport
//  (that product is public and would leak an MIR-format decoder onto consumer test
//  packages — story DD-7). Decodes the multi-track `{ "entries": [ <JAMS> ] }`
//  corpus wrapper (DD-9) plus the `beat` / `tempo` namespaces, and round-trips both
//  ways so the benchmark can also ENCODE estimated beats.
//
//  Compliance contract (JAMS 0.4, marl/jams-schema): the `entries` wrapper is
//  intentionally NOT a JAMS file (the schema root admits only file_metadata /
//  annotations / sandbox), so it is an internal corpus container; the strict-validity
//  claim is PER-ENTRY — each `entries[i]` is a standalone-valid JAMS object. The model
//  is tolerant on decode (optional fields, `decodeIfPresent`) but strict on encode for
//  the emitted `beat` namespace (required keys always written).
//

import Foundation

// MARK: - JAMSDecodingError

/// Typed decode failure. An unknown namespace is rejected (never silently
/// defaulted) — the story is explicit that the decoder must reject namespaces it
/// does not model rather than mis-interpret their `value` semantics.
enum JAMSDecodingError: Error, Equatable, Sendable {
  case unknownNamespace(String)
}

// MARK: - JAMSNamespace

/// The JAMS annotation namespaces this decoder models. `beat` (8.7 oracle) carries
/// a per-beat bar-phase `value` (`1` = downbeat); `tempo` (8.8 migrated artifacts)
/// carries a BPM `value`. Both have a numeric `value` that ``JAMSValue`` represents
/// faithfully. The `tag_open` namespace (a required *string* `value`) is deliberately
/// NOT modeled — ``JAMSValue`` is numeric-only and would throw on its string payload,
/// so claiming support would be false; it returns alongside a string-capable
/// ``JAMSValue`` in Story 8.8 when a real payload exists. Any unmodeled namespace
/// throws ``JAMSDecodingError/unknownNamespace(_:)``.
enum JAMSNamespace: String, Codable, Equatable, Sendable {
  case tempo
  case beat

  init(from decoder: any Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    guard let ns = JAMSNamespace(rawValue: raw) else {
      throw JAMSDecodingError.unknownNamespace(raw)
    }
    self = ns
  }

  func encode(to encoder: any Encoder) throws {
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
struct JAMSValue: Codable, Equatable, Sendable {
  /// The raw numeric value (a whole `beat` phase decodes as e.g. `1.0`).
  let number: Double

  /// Nearest-integer view, for bar-phase comparisons (`value.int == 1` → downbeat).
  var int: Int { Int(number.rounded()) }

  init(_ number: Double) { self.number = number }

  init(from decoder: any Decoder) throws {
    number = try decoder.singleValueContainer().decode(Double.self)
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(number)
  }
}

// MARK: - JAMSObservation

/// One sparse JAMS observation: a `time` (seconds), an optional namespace-polymorphic
/// `value`, an optional `confidence`, and a `duration` (`0` for instantaneous beats).
struct JAMSObservation: Codable, Equatable, Sendable {
  let time: Double
  let value: JAMSValue?
  let confidence: Double?
  let duration: Double

  init(time: Double, value: JAMSValue?, confidence: Double?, duration: Double) {
    self.time = time
    self.value = value
    self.confidence = confidence
    self.duration = duration
  }

  init(from decoder: any Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    time = try c.decode(Double.self, forKey: .time)
    value = try c.decodeIfPresent(JAMSValue.self, forKey: .value)
    confidence = try c.decodeIfPresent(Double.self, forKey: .confidence)
    duration = try c.decodeIfPresent(Double.self, forKey: .duration) ?? 0
  }

  func encode(to encoder: any Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(time, forKey: .time)
    // Strict-on-encode (JAMS 0.4 SparseObservation requires time/duration/value/
    // confidence): always write `value` and `confidence` — a nil optional encodes as
    // JSON `null`, which the `beat` namespace permits for both. `encodeIfPresent`
    // would omit the key and break required-field validity.
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
/// Strict-on-encode is *guaranteed for the `beat` namespace* (the only one we emit):
/// `annotation_metadata` is always written (JAMS 0.4 marks it required), and the
/// observation encoder always writes `value`/`confidence`. `Codable` can still encode
/// a schema-invalid `tempo` (its `value`/`confidence` must be non-null numbers, with
/// `confidence ∈ [0, 1]`) because the generic encoder does not validate that — a
/// namespace guard for `.tempo` is the Story 8.8 follow-up, added when tempo is
/// actually emitted.
struct JAMSAnnotation: Codable, Equatable, Sendable {
  let namespace: JAMSNamespace
  let data: [JAMSObservation]
  let annotationMetadata: JAMSAnnotationMetadata?

  func encode(to encoder: any Encoder) throws {
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
struct JAMSAnnotationMetadata: Codable, Equatable, Sendable {
  let curator: JAMSCurator?
  let dataSource: String?

  private enum CodingKeys: String, CodingKey {
    case curator
    case dataSource = "data_source"
  }
}

/// A JAMS curator identity (name + email).
struct JAMSCurator: Codable, Equatable, Sendable {
  let name: String?
  let email: String?
}

// MARK: - JAMSFileMetadata

/// Per-track JAMS file metadata. ``identifiers`` carries the basename / on-disk
/// path / Rekordbox `track_id` join keys the benchmark uses to locate audio and to
/// pair estimated beats against the oracle.
struct JAMSFileMetadata: Codable, Equatable, Sendable {
  let title: String?
  let artist: String?
  let duration: Double?
  /// JAMS spec version (`jams.json` requires it, pattern `^0\.[2-4]\.[0-9]+$`).
  /// Decoded tolerantly (`nil` on a payload that predates it) but always written on
  /// encode (fallback `"0.4.0"`) so every emitted entry is standalone-valid.
  let jamsVersion: String?
  let identifiers: JAMSIdentifiers?
  /// LEGACY decode-only fallback: a `constant_tempo` flag that older oracles wrote here
  /// before it moved to the top-level `sandbox` (its strict-valid home). Read so a stale
  /// oracle is not silently mis-scoped as constant-tempo (tolerant-on-decode), but NEVER
  /// re-encoded — `encode` omits it so emitted entries stay `jams.load`-valid. Prefer
  /// ``JAMSFile/constantTempo``, which reads `sandbox` first and falls back to this.
  let constantTempo: Bool?

  init(
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

  init(from decoder: any Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    title = try c.decodeIfPresent(String.self, forKey: .title)
    artist = try c.decodeIfPresent(String.self, forKey: .artist)
    duration = try c.decodeIfPresent(Double.self, forKey: .duration)
    jamsVersion = try c.decodeIfPresent(String.self, forKey: .jamsVersion)
    identifiers = try c.decodeIfPresent(JAMSIdentifiers.self, forKey: .identifiers)
    // Tolerant on decode (parity with eval-beatgrid.py, which coerces a non-bool to its
    // default): a present but non-Bool `constant_tempo` decodes to nil rather than throwing.
    constantTempo = (try? c.decodeIfPresent(Bool.self, forKey: .constantTempo)) ?? nil
  }

  func encode(to encoder: any Encoder) throws {
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
/// the oracle and the estimated corpus; `localPath` is the audio file to analyze.
struct JAMSIdentifiers: Codable, Equatable, Sendable {
  let basename: String?
  let localPath: String?
  let trackId: String?

  private enum CodingKeys: String, CodingKey {
    case basename
    case localPath = "local_path"
    case trackId = "track_id"
  }
}

// MARK: - JAMSSandbox

/// The JAMS top-level `sandbox` — a free-form object for non-standard, pipeline-only
/// data. We carry `constant_tempo` here rather than in `file_metadata`: the real `jams`
/// library constructs a typed `FileMetadata` and rejects unknown keys there, but accepts
/// arbitrary attributes on `sandbox` (Story DD-19 develop-only field; `nil` predates it).
struct JAMSSandbox: Codable, Equatable, Sendable {
  let constantTempo: Bool?

  init(constantTempo: Bool?) { self.constantTempo = constantTempo }

  init(from decoder: any Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    // Tolerant on decode: a present but non-Bool `constant_tempo` decodes to nil, not a throw.
    constantTempo = (try? c.decodeIfPresent(Bool.self, forKey: .constantTempo)) ?? nil
  }

  private enum CodingKeys: String, CodingKey {
    case constantTempo = "constant_tempo"
  }
}

// MARK: - JAMSFile

/// A standalone-valid JAMS object: top-level `file_metadata` + `annotations` (+ optional
/// `sandbox`). DD-9 — each corpus entry is independently valid and loadable by the real
/// `jams` library.
struct JAMSFile: Codable, Equatable, Sendable {
  let fileMetadata: JAMSFileMetadata
  let annotations: [JAMSAnnotation]
  let sandbox: JAMSSandbox?

  init(
    fileMetadata: JAMSFileMetadata, annotations: [JAMSAnnotation], sandbox: JAMSSandbox? = nil
  ) {
    self.fileMetadata = fileMetadata
    self.annotations = annotations
    self.sandbox = sandbox
  }

  /// `constant_tempo` provenance: the `sandbox` (its strict-valid home) first, falling
  /// back to the legacy `file_metadata.constant_tempo` so a stale oracle that predates the
  /// relocation is still read correctly rather than silently defaulting to constant-tempo.
  var constantTempo: Bool? { sandbox?.constantTempo ?? fileMetadata.constantTempo }

  private enum CodingKeys: String, CodingKey {
    case fileMetadata = "file_metadata"
    case annotations, sandbox
  }
}

// MARK: - JAMSCorpus

/// The multi-track corpus wrapper `{ "entries": [ <JAMSFile> ] }` (DD-9). Corpus-level
/// sibling keys (`corpus`, `xml_source`, `track_count`, …) are ignored on decode, so
/// the per-track objects stay standalone-valid and a future split-to-N-`.jams` is
/// lossless (`entries.map { write($0) }`).
struct JAMSCorpus: Codable, Equatable, Sendable {
  let entries: [JAMSFile]
}

// MARK: - Convenience accessors

extension JAMSFile {
  /// The first `beat`-namespace annotation, or `nil` if the file carries none.
  var beatAnnotation: JAMSAnnotation? {
    annotations.first { $0.namespace == .beat }
  }
}

extension JAMSAnnotation {
  /// Beat times in seconds (sorted ascending), for `mir_eval`-style position scoring.
  var beatTimes: [Double] { data.map(\.time).sorted() }

  /// Downbeat times: observations whose bar-phase ``JAMSValue/int`` is `1`
  /// (a non-nil `value == 1`), sorted ascending.
  var downbeatTimes: [Double] {
    data.filter { $0.value?.int == 1 }.map(\.time).sorted()
  }
}
