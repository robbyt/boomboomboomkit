import Foundation

/// OA300 corpus ground-truth row, decoded from the migrated JAMS `tempo` corpus
/// (`oa300-ground-truth.json`, Story 8.8b). Also covers the Ablation-matrix corpus, which
/// shares the same on-disk corpus.
///
/// JAMS mapping: `bpm` from the single `tempo` observation; `filename`/`title` from
/// `file_metadata`; `subdir`/`genre` from the per-entry `sandbox`. `genre` is non-optional —
/// the loud-fail contract is preserved in ``init(jamsFile:)``: an absent `sandbox.genre`
/// throws `DecodingError.keyNotFound`, a blank/whitespace one throws
/// `DecodingError.dataCorrupted`. The canonical (extensible) genre taxonomy lives in the
/// `ALLOWED_GENRES` constant in `Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py`;
/// Swift does not validate membership here (adding a genre needs no library change).
///
/// Decode a full corpus via ``loadCorpus(from:)``; there is no flat `Decodable` path since
/// the on-disk artifact is JAMS (Story 8.8b — `init(from:)` removed).
public struct OA300Track: Sendable {
  public let filename: String
  public let bpm: Double
  public let subdir: String?
  public let title: String
  public let genre: String

  /// Coding keys reused by ``init(jamsFile:)`` so its `DecodingError`s preserve the flat
  /// decoder's `"filename"`/`"title"`/`"genre"` key contract (`CorpusTracksDecodingTests`).
  fileprivate enum CodingKeys: String, CodingKey {
    case filename, bpm, subdir, title, genre
  }
}

/// GiantSteps Tempo Dataset ground-truth row.
///
/// JSON schema: `{ filename, bpm, tempo2?, track_id, genre }`. `tempo2` is the crowdsourced
/// secondary tempo used by MIREX-compliant Acc2 scoring (Story 2-1/2-2).
///
/// `genre` is non-optional by design: a corpus refresh that drops `genre` on any row must
/// fail the benchmark loudly (stratified accuracy reporting and Story 2-5's genre analysis
/// both depend on every row having a genre label). Pre-clean the JSON before running if
/// partial rows need to be tolerated.
public struct GiantStepsTrack: Decodable, Sendable {
  public let filename: String
  public let bpm: Double
  public let tempo2: Double?
  // swiftlint:disable identifier_name
  public let track_id: String
  // swiftlint:enable identifier_name
  public let genre: String
}

/// DAW-verified oracle row, decoded from the migrated JAMS `tempo` corpus (`daw-oracle.json`,
/// Story 8.8b — produced by `scripts/dawproject-bpm.py`, written alongside the OA300 corpus).
///
/// JAMS mapping: `dawBpm` (the canonical manually-verified tempo) from the `tempo` observation;
/// `filename` from `file_metadata.identifiers.basename`; the Rekordbox cross-check fields
/// (`rekordboxBpm`/`rekordboxDisagrees`/`disagreementType`) + `subdir` from the per-entry
/// `sandbox`. Decode a corpus via ``loadCorpus(from:)``; there is no flat `Decodable` path.
public struct DAWOracleTrack: Sendable {
  public let filename: String
  public let dawBpm: Double
  public let rekordboxBpm: Double
  public let subdir: String?
  public let rekordboxDisagrees: Bool
  public let disagreementType: String?

  /// Coding keys reused by ``init(jamsFile:)`` for loud-fail `DecodingError` keys.
  fileprivate enum CodingKeys: String, CodingKey {
    case filename
    case dawBpm = "daw_bpm"
    case rekordboxBpm = "rekordbox_bpm"
    case subdir
    case rekordboxDisagrees = "rekordbox_disagrees"
    case disagreementType = "disagreement_type"
  }
}

// MARK: - Versioned corpus loading (Story 12.3, FR-60)

/// A loaded ground-truth corpus plus its resolved ``AnnotationVersion``. Resolution
/// happens HERE, at the loader choke point, so every downstream emit site inherits
/// the tag rather than each remembering to compute it.
public struct VersionedCorpus<Track: Sendable>: Sendable {
  public let tracks: [Track]
  public let annotationVersion: AnnotationVersion

  public init(tracks: [Track], annotationVersion: AnnotationVersion) {
    self.tracks = tracks
    self.annotationVersion = annotationVersion
  }
}

/// Shared JAMS-corpus annotation-version resolution: collects every declared
/// `annotation_metadata.version` from TEMPO-namespace annotations only (a beat
/// oracle's version must not tag a tempo figure; all must agree; mixed values fail loudly via
/// ``AnnotationVersion/resolve(declaredVersions:corpus:rows:)``) and canonical rows
/// keyed by `file_metadata.identifiers.local_path` (82/82 unique on OA300, where the
/// nested `track_id` is only 80/82). A missing `local_path` fails loudly — the digest
/// would silently drop the row otherwise. NEVER reads `file_metadata.jams_version`
/// (the JAMS FORMAT version — identical across any re-annotation).
/// `alternateTempo` lets a corpus fold a second per-row tempo signal into the
/// digest (the DAW oracle passes `sandbox.rekordbox_bpm`); default is none.
private func resolveJAMSAnnotationVersion(
  _ corpus: JAMSCorpus, corpusName: String,
  alternateTempo: (JAMSFile) -> Double? = { _ in nil }
) throws -> AnnotationVersion {
  var declared: [String] = []
  var rows: [AnnotationVersion.AnnotationRow] = []
  rows.reserveCapacity(corpus.entries.count)
  for entry in corpus.entries {
    for annotation in entry.annotations where annotation.namespace == .tempo {
      if let version = annotation.annotationMetadata?.version {
        declared.append(version)
      }
    }
    guard let rowID = entry.fileMetadata.identifiers?.localPath, !rowID.isEmpty else {
      throw AnnotationVersion.ResolutionError.missingStableRowID(corpus: corpusName)
    }
    rows.append(
      AnnotationVersion.AnnotationRow(
        stableRowID: rowID,
        primaryTempo: try entry.tempoBPM(),
        alternateTempo: alternateTempo(entry),
        genre: entry.sandbox?.genre))
  }
  return try AnnotationVersion.resolve(declaredVersions: declared, corpus: corpusName, rows: rows)
}

// MARK: - JAMS corpus adapters (Story 8.8a)

extension OA300Track {
  /// Decode an OA300 ground-truth row from a migrated JAMS entry. The migration itself
  /// lands in Story 8.8b; this adapter ships in 8.8a alongside the flat `init(from:)` so the
  /// model can decode JAMS without yet flipping any call site. `bpm` reads the `tempo`
  /// observation; `filename`/`title` read `file_metadata`; `subdir`/`genre` read the
  /// per-entry `sandbox`. The non-empty-`genre` loud-fail contract is preserved verbatim:
  /// an absent `sandbox.genre` throws `keyNotFound`, a blank/whitespace one throws
  /// `dataCorrupted` — exactly as the flat decoder did.
  public init(jamsFile: JAMSFile) throws {
    guard let filename = jamsFile.fileMetadata.identifiers?.basename else {
      throw DecodingError.keyNotFound(
        CodingKeys.filename,
        DecodingError.Context(
          codingPath: [], debugDescription: "JAMS entry missing identifiers.basename (filename)"))
    }
    guard let title = jamsFile.fileMetadata.title else {
      throw DecodingError.keyNotFound(
        CodingKeys.title,
        DecodingError.Context(
          codingPath: [], debugDescription: "JAMS entry missing file_metadata.title"))
    }
    let bpm = try jamsFile.tempoBPM()

    guard let rawGenre = jamsFile.sandbox?.genre else {
      throw DecodingError.keyNotFound(
        CodingKeys.genre,
        DecodingError.Context(
          codingPath: [CodingKeys.genre], debugDescription: "JAMS entry missing sandbox.genre"))
    }
    guard !rawGenre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: [CodingKeys.genre],
          debugDescription:
            "`genre` must be a non-empty, non-whitespace string (got \(String(reflecting: rawGenre)))"
        ))
    }

    self.filename = filename
    self.bpm = bpm
    self.subdir = jamsFile.sandbox?.subdir
    self.title = title
    self.genre = rawGenre
  }

  /// Decode a full OA300 corpus from migrated JAMS data (the `{ "entries": [...] }` wrapper).
  /// Wrapper over ``loadVersionedCorpus(from:)`` (Story 12.3) so existing call sites
  /// keep compiling; use the versioned form when the figure will be persisted or gated.
  public static func loadCorpus(from data: Data) throws -> [OA300Track] {
    try loadVersionedCorpus(from: data).tracks
  }

  /// Decode a full OA300 corpus plus its resolved ``AnnotationVersion`` (Story 12.3).
  /// All three shipped corpora take the content-digest branch today (no corpus
  /// declares `annotation_metadata.version`); the declared branch activates if a
  /// future migration populates the field.
  public static func loadVersionedCorpus(from data: Data) throws -> VersionedCorpus<OA300Track> {
    let corpus = try JSONDecoder().decode(JAMSCorpus.self, from: data)
    let tracks = try corpus.entries.map(OA300Track.init(jamsFile:))
    let version = try resolveJAMSAnnotationVersion(corpus, corpusName: "oa300")
    return VersionedCorpus(tracks: tracks, annotationVersion: version)
  }
}

extension GiantStepsTrack {
  /// Decode the GiantSteps flat ground-truth array (Story 12.3 — previously four
  /// suites decoded `[GiantStepsTrack]` raw via `JSONDecoder`; this loader is the
  /// choke point they migrate to).
  public static func loadCorpus(from data: Data) throws -> [GiantStepsTrack] {
    try JSONDecoder().decode([GiantStepsTrack].self, from: data)
  }

  /// Decode the GiantSteps corpus plus its resolved ``AnnotationVersion``. The flat
  /// array carries no version field anywhere, so resolution always takes the
  /// content-digest branch; row ID is the GiantSteps `track_id`.
  public static func loadVersionedCorpus(from data: Data) throws
    -> VersionedCorpus<GiantStepsTrack>
  {
    let tracks = try loadCorpus(from: data)
    let rows = try tracks.map { track in
      guard !track.track_id.isEmpty else {
        throw AnnotationVersion.ResolutionError.missingStableRowID(corpus: "giantsteps")
      }
      return AnnotationVersion.AnnotationRow(
        stableRowID: track.track_id,
        primaryTempo: track.bpm,
        alternateTempo: track.tempo2,
        genre: track.genre)
    }
    return VersionedCorpus(
      tracks: tracks,
      annotationVersion: try AnnotationVersion.contentDigest(corpus: "giantsteps", rows: rows))
  }
}

extension DAWOracleTrack {
  /// Decode a DAW-oracle row from a migrated JAMS entry (Story 8.8b). `dawBpm` (the
  /// canonical manually-verified tempo) reads the `tempo` observation; the Rekordbox
  /// cross-check fields read the per-entry `sandbox`. Required fields fail loudly.
  public init(jamsFile: JAMSFile) throws {
    guard let filename = jamsFile.fileMetadata.identifiers?.basename else {
      throw DecodingError.keyNotFound(
        CodingKeys.filename,
        DecodingError.Context(
          codingPath: [], debugDescription: "JAMS entry missing identifiers.basename (filename)"))
    }
    let dawBpm = try jamsFile.tempoBPM()
    guard let rekordboxBpm = jamsFile.sandbox?.rekordboxBpm else {
      throw DecodingError.keyNotFound(
        CodingKeys.rekordboxBpm,
        DecodingError.Context(
          codingPath: [CodingKeys.rekordboxBpm],
          debugDescription: "JAMS entry missing sandbox.rekordbox_bpm"))
    }
    guard let rekordboxDisagrees = jamsFile.sandbox?.rekordboxDisagrees else {
      throw DecodingError.keyNotFound(
        CodingKeys.rekordboxDisagrees,
        DecodingError.Context(
          codingPath: [CodingKeys.rekordboxDisagrees],
          debugDescription: "JAMS entry missing sandbox.rekordbox_disagrees"))
    }

    self.filename = filename
    self.dawBpm = dawBpm
    self.rekordboxBpm = rekordboxBpm
    self.subdir = jamsFile.sandbox?.subdir
    self.rekordboxDisagrees = rekordboxDisagrees
    self.disagreementType = jamsFile.sandbox?.disagreementType
  }

  /// Decode a full DAW oracle from migrated JAMS data (the `{ "entries": [...] }` wrapper).
  /// Wrapper over ``loadVersionedCorpus(from:)`` (Story 12.3).
  public static func loadCorpus(from data: Data) throws -> [DAWOracleTrack] {
    try loadVersionedCorpus(from: data).tracks
  }

  /// Decode the DAW oracle plus its resolved ``AnnotationVersion`` (Story 12.3).
  /// The digest folds `sandbox.rekordbox_bpm` into each row's `alternateTempo`,
  /// so an oracle regeneration that changes only the Rekordbox cross-check
  /// values mints a new tag.
  public static func loadVersionedCorpus(from data: Data) throws
    -> VersionedCorpus<DAWOracleTrack>
  {
    let corpus = try JSONDecoder().decode(JAMSCorpus.self, from: data)
    let tracks = try corpus.entries.map(DAWOracleTrack.init(jamsFile:))
    let version = try resolveJAMSAnnotationVersion(
      corpus, corpusName: "daw-oracle",
      alternateTempo: { $0.sandbox?.rekordboxBpm })
    return VersionedCorpus(tracks: tracks, annotationVersion: version)
  }
}
