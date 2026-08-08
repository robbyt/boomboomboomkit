//
//  AnnotationVersion.swift
//  BoomBoomBoomKitTestSupport
//
//  Story 12.3 (FR-60): every accuracy figure carries the annotation version of the
//  ground truth it was scored against. The identifier is an OPEN namespaced tag,
//  not a closed enum, because Story 12.6 must mint a tag for a project-declared
//  convention without reopening this type.
//
//  Tag namespace:
//    - `declared:<value>` — the source file declares a version.
//    - `sha256:<64 lowercase hex>` — a content digest over CANONICALIZED annotation
//      rows (never raw file bytes: a converter re-serialization must not mint a new
//      annotation version for annotation-identical content).
//    - `untagged` — a historical figure whose source is no longer determinable
//      (e.g. a persisted baseline written before this story). A present ground-truth
//      file NEVER resolves to `untagged`.
//

import CryptoKit
import Foundation

/// Open, namespaced annotation-version identifier (Story 12.3, FR-60).
public struct AnnotationVersion: Sendable, Hashable, Codable, CustomStringConvertible {

  /// The rendered tag: `declared:<value>`, `sha256:<hex>`, or `untagged`.
  public let tag: String

  /// The sentinel for a historical figure whose annotation source is no longer
  /// determinable. First-class value — never `nil`, never absent.
  public static let untagged = AnnotationVersion(validatedTag: "untagged")

  private static let declaredPrefix = "declared:"
  private static let sha256Prefix = "sha256:"

  private init(validatedTag: String) {
    self.tag = validatedTag
  }

  public var description: String { tag }

  // MARK: - Resolution errors

  public enum ResolutionError: Error, Equatable, Sendable {
    /// A declared version was empty or whitespace-only.
    case emptyDeclaredVersion(String)
    /// A declared version equals the `untagged` sentinel or collides with a
    /// reserved namespace prefix, which would forge a sentinel or a digest tag.
    case reservedDeclaredVersion(String)
    /// Version-declaring annotations in one source disagree; resolution must fail
    /// loudly rather than pick one.
    case conflictingDeclaredVersions([String])
    /// A declared version contains a newline or another control character.
    case invalidDeclaredVersion(String)
    /// A row is missing the stable row ID the canonical digest requires (absent
    /// OR empty-string: an empty ID cannot distinguish rows).
    case missingStableRowID(corpus: String)
    /// Two rows share a stable row ID; the digest would silently conflate them.
    case duplicateStableRowID(corpus: String, rowID: String)
    /// A tempo value is NaN or infinite; its bit pattern is not canonical.
    case nonFiniteTempo(corpus: String, rowID: String)
    /// An empty corpus must not mint a tag.
    case emptyRowSet(corpus: String)
  }

  // MARK: - Declared branch

  /// A `declared:<value>` tag. The value is trimmed of surrounding whitespace and
  /// newlines before validation. Rejects empty/whitespace values, values containing
  /// newlines or other control characters, the literal `untagged`, and values
  /// colliding with the reserved `declared:`/`sha256:` prefixes — all three
  /// case-INSENSITIVELY, otherwise a truth file declaring `"Untagged"` or
  /// `"SHA256:..."` forges the sentinel or a digest tag.
  public static func declared(_ value: String) throws -> AnnotationVersion {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      throw ResolutionError.emptyDeclaredVersion(value)
    }
    guard trimmed.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) })
    else {
      throw ResolutionError.invalidDeclaredVersion(value)
    }
    let lowered = trimmed.lowercased()
    guard lowered != "untagged", !lowered.hasPrefix(declaredPrefix),
      !lowered.hasPrefix(sha256Prefix)
    else {
      throw ResolutionError.reservedDeclaredVersion(value)
    }
    return AnnotationVersion(validatedTag: declaredPrefix + trimmed)
  }

  // MARK: - Content-digest branch

  /// One canonical annotation row. `stableRowID` is
  /// `file_metadata.identifiers.local_path` for the JAMS corpora (82/82 unique on
  /// OA300, where `track_id` is only 80/82) and the GiantSteps `track_id` for
  /// GiantSteps.
  public struct AnnotationRow: Sendable {
    public let stableRowID: String
    public let primaryTempo: Double
    public let alternateTempo: Double?
    public let genre: String?

    public init(
      stableRowID: String, primaryTempo: Double,
      alternateTempo: Double? = nil, genre: String? = nil
    ) {
      self.stableRowID = stableRowID
      self.primaryTempo = primaryTempo
      self.alternateTempo = alternateTempo
      self.genre = genre
    }
  }

  /// SHA-256 digest over canonicalized annotation content, rendered
  /// `sha256:<64 lowercase hex>`.
  ///
  /// Canonical byte stream (no delimiter ambiguity, no float-format drift):
  /// - domain prefix `BoomBoomBoomKit.annotation.v1/<corpus>` as a length-prefixed
  ///   UTF-8 string;
  /// - rows sorted by `stableRowID` in UTF-8 byte order (cross-platform
  ///   deterministic, unlike `String` `<`);
  /// - strings encoded as an 8-byte big-endian UTF-8 byte count followed by the
  ///   bytes; tempos as 8-byte big-endian IEEE-754 bit patterns (`-0.0`
  ///   canonicalized to `0.0`); optionals as a 1-byte marker (`0x00` nil,
  ///   `0x01` present + payload).
  ///
  /// Throws on an empty row set, a duplicate `stableRowID`, or a non-finite tempo —
  /// all three would otherwise mint a tag that conflates or misrepresents content.
  public static func contentDigest(corpus: String, rows: [AnnotationRow]) throws
    -> AnnotationVersion
  {
    guard !rows.isEmpty else {
      throw ResolutionError.emptyRowSet(corpus: corpus)
    }
    var seenRowIDs = Set<String>()
    for row in rows {
      guard seenRowIDs.insert(row.stableRowID).inserted else {
        throw ResolutionError.duplicateStableRowID(corpus: corpus, rowID: row.stableRowID)
      }
      guard row.primaryTempo.isFinite, row.alternateTempo.map(\.isFinite) ?? true else {
        throw ResolutionError.nonFiniteTempo(corpus: corpus, rowID: row.stableRowID)
      }
    }

    var bytes = Data()

    func putLength(_ count: Int) {
      withUnsafeBytes(of: UInt64(count).bigEndian) { bytes.append(contentsOf: $0) }
    }
    func putString(_ string: String) {
      let utf8 = Data(string.utf8)
      putLength(utf8.count)
      bytes.append(utf8)
    }
    func putDouble(_ value: Double) {
      // Canonicalize the two IEEE-754 zeros to one bit pattern.
      let canonical = value == 0.0 ? 0.0 : value
      withUnsafeBytes(of: canonical.bitPattern.bigEndian) { bytes.append(contentsOf: $0) }
    }

    putString("BoomBoomBoomKit.annotation.v1/\(corpus)")
    let sorted = rows.sorted {
      $0.stableRowID.utf8.lexicographicallyPrecedes($1.stableRowID.utf8)
    }
    for row in sorted {
      putString(row.stableRowID)
      putDouble(row.primaryTempo)
      if let alternate = row.alternateTempo {
        bytes.append(0x01)
        putDouble(alternate)
      } else {
        bytes.append(0x00)
      }
      if let genre = row.genre {
        bytes.append(0x01)
        putString(genre)
      } else {
        bytes.append(0x00)
      }
    }

    let hex = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    return AnnotationVersion(validatedTag: sha256Prefix + hex)
  }

  // MARK: - Two-rule resolution

  /// Resolves a present ground-truth source: the declared version when every
  /// version-declaring annotation agrees (mixed values fail loudly), else a content
  /// digest over the canonical rows. Never resolves to `.untagged` — a present file
  /// always yields a distinguishing tag. An empty row set throws regardless of
  /// declared versions: an empty corpus must not mint a tag.
  public static func resolve(
    declaredVersions: [String], corpus: String, rows: [AnnotationRow]
  ) throws -> AnnotationVersion {
    guard !rows.isEmpty else {
      throw ResolutionError.emptyRowSet(corpus: corpus)
    }
    let unique = Set(declaredVersions)
    guard let sole = unique.first else {
      return try contentDigest(corpus: corpus, rows: rows)
    }
    guard unique.count == 1 else {
      throw ResolutionError.conflictingDeclaredVersions(unique.sorted())
    }
    return try declared(sole)
  }

  // MARK: - Parsing / Codable (validating)

  /// Parses a rendered tag. `nil` when the string is not a well-formed tag —
  /// unnamespaced values, malformed hex, or forged declared payloads all fail.
  /// The `declared:` payload must already be CANONICAL: a payload that is not
  /// its own whitespace-trimmed self (or otherwise fails `declared(_:)`
  /// validation) is rejected rather than normalized, so parsing never mints a
  /// tag string different from its input. Only `declared(_:)` construction trims.
  public init?(parsing raw: String) {
    if raw == "untagged" {
      self.init(validatedTag: raw)
      return
    }
    if raw.hasPrefix(Self.declaredPrefix) {
      let value = String(raw.dropFirst(Self.declaredPrefix.count))
      guard let parsed = try? Self.declared(value), parsed.tag == raw else { return nil }
      self = parsed
      return
    }
    if raw.hasPrefix(Self.sha256Prefix) {
      let hex = raw.dropFirst(Self.sha256Prefix.count)
      guard hex.count == 64,
        hex.allSatisfy({ ("0"..."9").contains($0) || ("a"..."f").contains($0) })
      else { return nil }
      self.init(validatedTag: raw)
      return
    }
    return nil
  }

  /// Single-value string decode. A malformed tag is a decode FAILURE, never a
  /// silent `untagged` (I/O matrix: "current artifact read").
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let raw = try container.decode(String.self)
    guard let parsed = AnnotationVersion(parsing: raw) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription:
          "Malformed annotation-version tag \(String(reflecting: raw)); expected `untagged`, `declared:<value>`, or `sha256:<64 lowercase hex>`"
      )
    }
    self = parsed
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(tag)
  }
}

// MARK: - Persisted-record schema rule (perf-baseline back-compat)

/// The schema-gated annotation-version rule for persisted accuracy records
/// (Story 12.3). The previous perf-baseline schema (2) predates tagging: its
/// records surface `.untagged` explicitly. The bumped schema (3) records the
/// version and a missing/malformed field is a loud failure. Anything else is
/// unsupported. Extracted here so the rule is unit-testable outside the
/// env-gated benchmark target.
public enum AccuracyRecordSchema {
  /// Pre-tagging perf-baseline schema; annotation version reads as `.untagged`.
  public static let previous = 2
  /// The Story 12.3 schema carrying per-corpus annotation versions.
  public static let current = 3
  /// The schema versions a reader accepts.
  public static let supported = previous...current

  public enum SchemaError: Error, Equatable, Sendable {
    case unsupportedSchemaVersion(Int)
    case missingAnnotationVersion(schemaVersion: Int)
    /// A schema-2 record carrying an annotation-version field is malformed: schema 2
    /// predates tagging, so a present field cannot be trusted and must fail loudly.
    case unexpectedAnnotationVersion(schemaVersion: Int)
  }

  /// Applies the rule to an already-decoded optional field: schema 2 requires the
  /// field ABSENT (present is a loud failure) and reads as `.untagged`, schema 3
  /// requires the field, anything else is rejected.
  public static func annotationVersion(
    fromDecoded value: AnnotationVersion?, schemaVersion: Int
  ) throws -> AnnotationVersion {
    switch schemaVersion {
    case previous:
      guard value == nil else {
        throw SchemaError.unexpectedAnnotationVersion(schemaVersion: schemaVersion)
      }
      return .untagged
    case current:
      guard let value else {
        throw SchemaError.missingAnnotationVersion(schemaVersion: schemaVersion)
      }
      return value
    default:
      throw SchemaError.unsupportedSchemaVersion(schemaVersion)
    }
  }
}
