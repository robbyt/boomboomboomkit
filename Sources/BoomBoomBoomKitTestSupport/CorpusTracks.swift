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
  public static func loadCorpus(from data: Data) throws -> [OA300Track] {
    try JSONDecoder().decode(JAMSCorpus.self, from: data).entries.map(OA300Track.init(jamsFile:))
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
  public static func loadCorpus(from data: Data) throws -> [DAWOracleTrack] {
    try JSONDecoder().decode(JAMSCorpus.self, from: data)
      .entries.map(DAWOracleTrack.init(jamsFile:))
  }
}
