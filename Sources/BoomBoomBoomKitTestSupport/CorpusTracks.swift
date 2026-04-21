import Foundation

/// OA300 corpus ground-truth row. Also covers the Ablation-matrix corpus, which shares the
/// same on-disk schema.
///
/// JSON schema (`oa300-ground-truth.json`): `{ filename, bpm, subdir?, title, genre }`.
/// `genre` is non-optional — the ground-truth fixture guarantees every row carries a genre
/// label. The canonical (extensible) taxonomy is tracked in the `ALLOWED_GENRES` constant in
/// `Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py`; Swift intentionally
/// does not validate membership against that list here (so adding a new genre requires no
/// library change), but the decoder does reject **blank** genres: a row missing `genre`
/// throws `DecodingError.keyNotFound`, a row with `"genre": null` throws
/// `DecodingError.valueNotFound`, and a row whose `genre` is empty or whitespace-only
/// throws `DecodingError.dataCorrupted`. No silent skip in any of those cases.
///
/// Required fields (`filename`, `bpm`, `title`, `genre`) are intentionally non-optional: a
/// malformed corpus row missing one of these must break the benchmark suite loudly rather
/// than silently drop to `nil` and be filtered out. Callers that need to tolerate partial
/// rows should pre-clean the JSON file.
public struct OA300Track: Decodable, Sendable {
  public let filename: String
  public let bpm: Double
  public let subdir: String?
  public let title: String
  public let genre: String

  private enum CodingKeys: String, CodingKey {
    case filename, bpm, subdir, title, genre
  }

  public init(from decoder: any Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    self.filename = try c.decode(String.self, forKey: .filename)
    self.bpm = try c.decode(Double.self, forKey: .bpm)
    self.subdir = try c.decodeIfPresent(String.self, forKey: .subdir)
    self.title = try c.decode(String.self, forKey: .title)
    let rawGenre = try c.decode(String.self, forKey: .genre)
    guard !rawGenre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw DecodingError.dataCorruptedError(
        forKey: .genre,
        in: c,
        debugDescription:
          "`genre` must be a non-empty, non-whitespace string (got \(String(reflecting: rawGenre)))"
      )
    }
    self.genre = rawGenre
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

/// DAW-verified oracle row. Produced by `scripts/dawproject-bpm.py` from the `.dawproject` file
/// in the OA300 corpus directory and written to `daw-oracle.json` alongside the corpus.
///
/// On-disk JSON uses snake_case; the struct declares `CodingKeys` so decoding works regardless
/// of decoder configuration (no need for `.convertFromSnakeCase` at the call site).
public struct DAWOracleTrack: Decodable, Sendable {
  public let filename: String
  public let dawBpm: Double
  public let rekordboxBpm: Double
  public let subdir: String?
  public let rekordboxDisagrees: Bool
  public let disagreementType: String?

  private enum CodingKeys: String, CodingKey {
    case filename
    case dawBpm = "daw_bpm"
    case rekordboxBpm = "rekordbox_bpm"
    case subdir
    case rekordboxDisagrees = "rekordbox_disagrees"
    case disagreementType = "disagreement_type"
  }
}
