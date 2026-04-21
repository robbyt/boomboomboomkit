//
//  CorpusTracksDecodingTests.swift
//  BoomBoomBoomKitTests
//
//  Guards the non-optional `genre` contract on `OA300Track` (Story 2-4).
//  Without these tests, a future careless edit that flips `genre` back to
//  optional, or a ground-truth regeneration that drops the column, would
//  silently skip rows instead of failing the benchmark suite loudly.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@Suite("OA300Track decoding contract")
struct CorpusTracksDecodingTests {

  // MARK: - Happy path

  @Test("OA300Track decodes with genre field")
  func decodesWithGenre() throws {
    let json = Data(
      """
      [{
        "filename": "x.wav",
        "bpm": 120.0,
        "subdir": null,
        "title": "x",
        "genre": "techno"
      }]
      """.utf8)

    let tracks = try JSONDecoder().decode([OA300Track].self, from: json)
    let track = try #require(tracks.first)
    #expect(track.genre == "techno")
    #expect(track.filename == "x.wav")
    #expect(track.bpm == 120.0)
    #expect(track.subdir == nil)
    #expect(track.title == "x")
  }

  // MARK: - Loud fail on missing genre

  @Test("OA300Track throws keyNotFound when genre is missing")
  func throwsWhenGenreMissing() {
    let json = Data(
      """
      [{
        "filename": "x.wav",
        "bpm": 120.0,
        "subdir": null,
        "title": "x"
      }]
      """.utf8)

    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode([OA300Track].self, from: json)
    }

    // Verify the thrown error is specifically a keyNotFound for "genre",
    // not some other DecodingError (e.g., typeMismatch on another field).
    do {
      _ = try JSONDecoder().decode([OA300Track].self, from: json)
      Issue.record("Expected decode to throw DecodingError.keyNotFound")
    } catch let DecodingError.keyNotFound(key, _) {
      #expect(key.stringValue == "genre")
    } catch {
      Issue.record("Expected keyNotFound for 'genre', got: \(error)")
    }
  }

  // MARK: - Loud fail on blank or null genre

  @Test("OA300Track throws dataCorrupted when genre is empty string")
  func throwsWhenGenreEmpty() {
    let json = Data(
      """
      [{"filename": "x.wav", "bpm": 120.0, "subdir": null, "title": "x", "genre": ""}]
      """.utf8)

    do {
      _ = try JSONDecoder().decode([OA300Track].self, from: json)
      Issue.record("Expected decode to throw DecodingError.dataCorrupted for empty genre")
    } catch let DecodingError.dataCorrupted(context) {
      #expect(context.codingPath.last?.stringValue == "genre")
    } catch {
      Issue.record("Expected dataCorrupted for 'genre', got: \(error)")
    }
  }

  @Test("OA300Track throws dataCorrupted when genre is whitespace-only")
  func throwsWhenGenreWhitespace() {
    let json = Data(
      """
      [{"filename": "x.wav", "bpm": 120.0, "subdir": null, "title": "x", "genre": "   \\n\\t "}]
      """.utf8)

    do {
      _ = try JSONDecoder().decode([OA300Track].self, from: json)
      Issue.record("Expected decode to throw DecodingError.dataCorrupted for whitespace genre")
    } catch let DecodingError.dataCorrupted(context) {
      #expect(context.codingPath.last?.stringValue == "genre")
    } catch {
      Issue.record("Expected dataCorrupted for 'genre', got: \(error)")
    }
  }

  @Test("OA300Track throws valueNotFound when genre is null")
  func throwsWhenGenreNull() {
    let json = Data(
      """
      [{"filename": "x.wav", "bpm": 120.0, "subdir": null, "title": "x", "genre": null}]
      """.utf8)

    do {
      _ = try JSONDecoder().decode([OA300Track].self, from: json)
      Issue.record("Expected decode to throw DecodingError.valueNotFound for null genre")
    } catch let DecodingError.valueNotFound(_, context) {
      #expect(context.codingPath.last?.stringValue == "genre")
    } catch {
      Issue.record("Expected valueNotFound for 'genre', got: \(error)")
    }
  }

  // MARK: - Taxonomy drift guard

  /// Swift-side mirror of the canonical `ALLOWED_GENRES` constant in
  /// `Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py`.
  ///
  /// Must stay in sync with the Python list. Adding a new genre to OA300 is
  /// a 4-step workflow: (1) append to `ALLOWED_GENRES` in the Python script,
  /// (2) tag the relevant rows in `oa300-ground-truth.json`, (3) append to
  /// this Set, (4) log the addition in the proposing story's Change Log.
  /// The fixture-compliance test below catches drift in step (2) vs (1)/(3).
  private static let allowedGenres: Set<String> = [
    "breaks",
    "chill-out",
    "deep-house",
    "dj-tools",
    "drum-and-bass",
    "dubstep",
    "electro-house",
    "electronica",
    "footwork",
    "funk-r-and-b",
    "glitch-hop",
    "half-time-dnb",
    "hard-dance",
    "hardcore-hard-techno",
    "hip-hop",
    "house",
    "indie-dance-nu-disco",
    "minimal",
    "pop-rock",
    "progressive-house",
    "psy-trance",
    "reggae-dub",
    "tech-house",
    "techno",
    "trance",
  ]

  @Test("Every row in oa300-ground-truth.json has a genre in ALLOWED_GENRES")
  func fixtureGenresAreWithinAllowedTaxonomy() throws {
    // Resolve the benchmark-target fixture by walking up from this source file.
    // The fixture lives in a sibling test target's Fixtures directory, so
    // `Bundle.module` (which resolves to the unit-test target) cannot find it.
    let thisFile = URL(fileURLWithPath: #filePath)
    let fixtureURL =
      thisFile
      .deletingLastPathComponent()  // Tests/BoomBoomBoomKitTests/
      .deletingLastPathComponent()  // Tests/
      .appending(components: "BoomBoomBoomKitBenchmarkTests", "Fixtures", "oa300-ground-truth.json")

    let data = try Data(contentsOf: fixtureURL)
    let tracks = try JSONDecoder().decode([OA300Track].self, from: data)

    #expect(tracks.count == 82, "OA300 ground truth should have 82 entries")

    let offTaxonomy = tracks.filter { !Self.allowedGenres.contains($0.genre) }
    if !offTaxonomy.isEmpty {
      let details = offTaxonomy.map { "\($0.filename)=\($0.genre)" }.joined(separator: ", ")
      Issue.record("Found \(offTaxonomy.count) rows with genre outside ALLOWED_GENRES: \(details)")
    }
    #expect(offTaxonomy.isEmpty)
  }
}
