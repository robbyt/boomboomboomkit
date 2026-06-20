//
//  CorpusTracksDecodingTests.swift
//  BoomBoomBoomKitTests
//
//  Guards the non-optional `genre` contract on `OA300Track` (Story 2-4), now decoded
//  from the migrated JAMS `tempo` corpus (Story 8.8b — genre rides the per-entry
//  `sandbox`). Without these tests, a future careless edit that drops the genre
//  loud-fail, or a ground-truth regeneration that loses the column, would silently
//  skip rows instead of failing the benchmark suite loudly.
//
//  Note (Story 8.8b): under JAMS a `null` `sandbox.genre` is indistinguishable from an
//  absent key (both decode to nil), so the legacy "null -> valueNotFound" case now folds
//  into the absent -> keyNotFound case. Blank/whitespace still throw dataCorrupted.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@Suite("OA300Track decoding contract")
struct CorpusTracksDecodingTests {

  /// Build a one-entry JAMS `tempo` corpus with a configurable `sandbox` body, so each
  /// genre case is exercised through the real `OA300Track.loadCorpus` path.
  private func corpusJSON(sandboxBody: String) -> Data {
    Data(
      """
      { "entries": [ {
        "file_metadata": { "title": "x", "duration": 0, "jams_version": "0.4.0",
          "identifiers": { "basename": "x.wav", "local_path": "x.wav", "track_id": "x" } },
        "annotations": [ { "namespace": "tempo",
          "data": [ { "time": 0, "duration": 0, "value": 120.0, "confidence": 1.0 } ],
          "annotation_metadata": {} } ],
        "sandbox": { \(sandboxBody) } } ] }
      """.utf8)
  }

  // MARK: - Happy path

  @Test("OA300Track decodes a JAMS entry with a genre")
  func decodesWithGenre() throws {
    let tracks = try OA300Track.loadCorpus(from: corpusJSON(sandboxBody: #""genre": "techno""#))
    let track = try #require(tracks.first)
    #expect(track.genre == "techno")
    #expect(track.filename == "x.wav")
    #expect(track.bpm == 120.0)
    #expect(track.subdir == nil)
    #expect(track.title == "x")
  }

  // MARK: - Loud fail on missing / null genre (both -> keyNotFound under JAMS)

  @Test("OA300Track throws keyNotFound when sandbox.genre is absent")
  func throwsWhenGenreMissing() {
    do {
      _ = try OA300Track.loadCorpus(from: corpusJSON(sandboxBody: #""subdir": null"#))
      Issue.record("Expected decode to throw DecodingError.keyNotFound")
    } catch let DecodingError.keyNotFound(key, _) {
      #expect(key.stringValue == "genre")
    } catch {
      Issue.record("Expected keyNotFound for 'genre', got: \(error)")
    }
  }

  @Test("OA300Track throws keyNotFound when sandbox.genre is null")
  func throwsWhenGenreNull() {
    do {
      _ = try OA300Track.loadCorpus(from: corpusJSON(sandboxBody: #""genre": null"#))
      Issue.record("Expected decode to throw DecodingError.keyNotFound for null genre")
    } catch let DecodingError.keyNotFound(key, _) {
      #expect(key.stringValue == "genre")
    } catch {
      Issue.record("Expected keyNotFound for 'genre', got: \(error)")
    }
  }

  // MARK: - Loud fail on blank / whitespace genre

  @Test("OA300Track throws dataCorrupted when genre is empty string")
  func throwsWhenGenreEmpty() {
    do {
      _ = try OA300Track.loadCorpus(from: corpusJSON(sandboxBody: #""genre": """#))
      Issue.record("Expected decode to throw DecodingError.dataCorrupted for empty genre")
    } catch let DecodingError.dataCorrupted(context) {
      #expect(context.codingPath.last?.stringValue == "genre")
    } catch {
      Issue.record("Expected dataCorrupted for 'genre', got: \(error)")
    }
  }

  @Test("OA300Track throws dataCorrupted when genre is whitespace-only")
  func throwsWhenGenreWhitespace() {
    do {
      _ = try OA300Track.loadCorpus(from: corpusJSON(sandboxBody: #""genre": "   \n\t ""#))
      Issue.record("Expected decode to throw DecodingError.dataCorrupted for whitespace genre")
    } catch let DecodingError.dataCorrupted(context) {
      #expect(context.codingPath.last?.stringValue == "genre")
    } catch {
      Issue.record("Expected dataCorrupted for 'genre', got: \(error)")
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
    let tracks = try OA300Track.loadCorpus(from: data)

    #expect(tracks.count == 82, "OA300 ground truth should have 82 entries")

    let offTaxonomy = tracks.filter { !Self.allowedGenres.contains($0.genre) }
    if !offTaxonomy.isEmpty {
      let details = offTaxonomy.map { "\($0.filename)=\($0.genre)" }.joined(separator: ", ")
      Issue.record("Found \(offTaxonomy.count) rows with genre outside ALLOWED_GENRES: \(details)")
    }
    #expect(offTaxonomy.isEmpty)
  }
}
