//
//  JAMSDecoder.swift
//  BoomBoomBoomKit
//
//  Benchmark-target-internal JAMS (JSON Annotated Music Specification) decoder
//  for the Story-8.7 beat-grid acceptance corpus. NOT in BoomBoomBoomKitTestSupport
//  (that product is public and would leak an MIR-format decoder onto consumer test
//  packages — story DD-7). Decodes the multi-track `{ "entries": [ <JAMS> ] }`
//  corpus wrapper (DD-9) plus the `beat` / `tempo` / `tag_open` namespaces, and
//  round-trips both ways so the benchmark can also ENCODE estimated beats.
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
/// carries a BPM `value`; `tag_open` is a free string tag. Any other namespace
/// throws ``JAMSDecodingError/unknownNamespace(_:)``.
enum JAMSNamespace: String, Codable, Equatable, Sendable {
  case tempo
  case beat
  case tagOpen = "tag_open"

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
    try c.encodeIfPresent(value, forKey: .value)
    try c.encodeIfPresent(confidence, forKey: .confidence)
    try c.encode(duration, forKey: .duration)
  }

  private enum CodingKeys: String, CodingKey {
    case time, value, confidence, duration
  }
}

// MARK: - JAMSAnnotation

/// One JAMS annotation: a namespace plus its sparse observation list and optional
/// provenance metadata.
struct JAMSAnnotation: Codable, Equatable, Sendable {
  let namespace: JAMSNamespace
  let data: [JAMSObservation]
  let annotationMetadata: JAMSAnnotationMetadata?

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
  /// `true` when the source grid was a single constant-tempo anchor (a develop-only
  /// extension field — Story DD-19; `nil` on a payload that predates it). The gated
  /// acceptance metrics scope to constant-tempo tracks, the tracker's documented domain.
  let constantTempo: Bool?
  let identifiers: JAMSIdentifiers?

  init(
    title: String?, artist: String?, duration: Double?, constantTempo: Bool? = nil,
    identifiers: JAMSIdentifiers?
  ) {
    self.title = title
    self.artist = artist
    self.duration = duration
    self.constantTempo = constantTempo
    self.identifiers = identifiers
  }

  private enum CodingKeys: String, CodingKey {
    case title, artist, duration
    case constantTempo = "constant_tempo"
    case identifiers
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

// MARK: - JAMSFile

/// A standalone-valid JAMS object: top-level `file_metadata` + `annotations`
/// (DD-9 — each corpus entry is independently valid).
struct JAMSFile: Codable, Equatable, Sendable {
  let fileMetadata: JAMSFileMetadata
  let annotations: [JAMSAnnotation]

  private enum CodingKeys: String, CodingKey {
    case fileMetadata = "file_metadata"
    case annotations
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
