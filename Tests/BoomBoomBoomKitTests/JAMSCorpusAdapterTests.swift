//
//  JAMSCorpusAdapterTests.swift
//  BoomBoomBoomKit
//
//  Story 8.8a seam tests. The public JAMS model (relocated to BoomBoomBoomKitTestSupport,
//  DD-1) decodes into the shipping corpus adapters `OA300Track.init(jamsFile:)` /
//  `loadCorpus(from:)`, preserves the non-empty-genre loud-fail contract, and the
//  `tempo`-encode guard rejects schema-invalid output. No corpus required — runs under
//  `make test`. The on-disk fixture migration + call-site flips land in Stories 8.8b/8.8c.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@Suite("JAMS corpus adapter (Story 8.8a)")
struct JAMSCorpusAdapterTests {

  /// Build a synthetic oa300-style `tempo` JAMS entry (bpm in a `tempo` observation,
  /// genre/subdir in the per-entry sandbox).
  private func oa300Entry(
    filename: String = "track.wav", title: String = "Track",
    bpm: Double = 174.0, genre: String? = "drum-and-bass", subdir: String? = nil
  ) -> JAMSFile {
    JAMSFile(
      fileMetadata: JAMSFileMetadata(
        title: title, artist: nil, duration: 0,
        identifiers: JAMSIdentifiers(
          basename: filename, localPath: subdir.map { "\($0)/\(filename)" } ?? filename,
          trackId: title)),
      annotations: [
        JAMSAnnotation(
          namespace: .tempo,
          data: [JAMSObservation(time: 0, value: JAMSValue(bpm), confidence: 1.0, duration: 0)],
          annotationMetadata: JAMSAnnotationMetadata(
            curator: JAMSCurator(name: "Robert Terhaar", email: "robbyt@robbyt.net"),
            dataSource: "OA300 hand-labeled ground truth"))
      ],
      sandbox: JAMSSandbox(genre: genre, subdir: subdir))
  }

  // MARK: OA300Track adapter

  @Test("OA300Track decodes from a JAMS tempo entry, round-tripping bpm/genre/subdir/filename")
  func decodesFromJamsEntry() throws {
    let track = try OA300Track(
      jamsFile: oa300Entry(
        filename: "8. Jonah K_Shadow Work.wav", title: "8. Jonah K_Shadow Work",
        bpm: 150.0, genre: "drum-and-bass", subdir: "Bad BPM"))
    #expect(track.filename == "8. Jonah K_Shadow Work.wav")
    #expect(track.title == "8. Jonah K_Shadow Work")
    #expect(track.bpm == 150.0)
    #expect(track.genre == "drum-and-bass")
    #expect(track.subdir == "Bad BPM")
  }

  @Test("loadCorpus decodes a multi-entry JAMS wrapper")
  func loadCorpusDecodes() throws {
    let corpus = JAMSCorpus(entries: [
      oa300Entry(filename: "a.wav", title: "A", bpm: 120, genre: "techno"),
      oa300Entry(filename: "b.wav", title: "B", bpm: 174, genre: "drum-and-bass"),
    ])
    let data = try JSONEncoder().encode(corpus)
    let tracks = try OA300Track.loadCorpus(from: data)
    #expect(tracks.count == 2)
    #expect(tracks.map(\.filename) == ["a.wav", "b.wav"])
    #expect(tracks.map(\.genre) == ["techno", "drum-and-bass"])
  }

  // MARK: Genre loud-fail contract (preserved from the flat decoder)

  @Test("absent sandbox.genre throws keyNotFound for 'genre'")
  func absentGenreThrows() {
    do {
      _ = try OA300Track(jamsFile: oa300Entry(genre: nil))
      Issue.record("Expected keyNotFound for missing genre")
    } catch let DecodingError.keyNotFound(key, _) {
      #expect(key.stringValue == "genre")
    } catch {
      Issue.record("Expected keyNotFound for 'genre', got: \(error)")
    }
  }

  @Test("blank/whitespace sandbox.genre throws dataCorrupted for 'genre'")
  func blankGenreThrows() {
    for blank in ["", "   \n\t "] {
      do {
        _ = try OA300Track(jamsFile: oa300Entry(genre: blank))
        Issue.record("Expected dataCorrupted for blank genre \(String(reflecting: blank))")
      } catch let DecodingError.dataCorrupted(context) {
        #expect(context.codingPath.last?.stringValue == "genre")
      } catch {
        Issue.record("Expected dataCorrupted for 'genre', got: \(error)")
      }
    }
  }

  @Test("a tempo entry missing its observation value fails loudly")
  func missingTempoValueThrows() {
    let entry = JAMSFile(
      fileMetadata: JAMSFileMetadata(
        title: "T", artist: nil, duration: 0,
        identifiers: JAMSIdentifiers(basename: "t.wav", localPath: "t.wav", trackId: "T")),
      annotations: [
        JAMSAnnotation(
          namespace: .tempo,
          data: [JAMSObservation(time: 0, value: nil, confidence: 1.0, duration: 0)])
      ],
      sandbox: JAMSSandbox(genre: "techno"))
    #expect(throws: JAMSValidationError.missingTempoObservation) {
      _ = try OA300Track(jamsFile: entry)
    }
  }

  // MARK: DAWOracleTrack adapter

  @Test("DAWOracleTrack decodes from a JAMS tempo entry with sandbox cross-check fields")
  func dawOracleDecodesFromJamsEntry() throws {
    let entry = JAMSFile(
      fileMetadata: JAMSFileMetadata(
        title: "Bunker", artist: nil, duration: 0,
        identifiers: JAMSIdentifiers(
          basename: "1. Bunker.wav", localPath: "1. Bunker.wav", trackId: "Bunker")),
      annotations: [
        JAMSAnnotation(
          namespace: .tempo,
          data: [JAMSObservation(time: 0, value: JAMSValue(170.0), confidence: 1.0, duration: 0)])
      ],
      sandbox: JAMSSandbox(
        rekordboxBpm: 85.0, rekordboxDisagrees: true, disagreementType: "octave"))
    let track = try DAWOracleTrack(jamsFile: entry)
    #expect(track.filename == "1. Bunker.wav")
    #expect(track.dawBpm == 170.0)
    #expect(track.rekordboxBpm == 85.0)
    #expect(track.rekordboxDisagrees == true)
    #expect(track.disagreementType == "octave")
  }

  // MARK: tempo-encode guard (Story 8.8a)

  @Test("encoding a tempo observation with nil value throws tempoValueMissing")
  func tempoEncodeGuardRejectsNilValue() {
    let corpus = JAMSCorpus(entries: [
      JAMSFile(
        fileMetadata: JAMSFileMetadata(
          title: "T", artist: nil, duration: 0,
          identifiers: JAMSIdentifiers(basename: "t.wav", localPath: nil, trackId: "T")),
        annotations: [
          JAMSAnnotation(
            namespace: .tempo,
            data: [JAMSObservation(time: 0, value: nil, confidence: 1.0, duration: 0)])
        ])
    ])
    #expect(throws: JAMSEncodingError.tempoValueMissing) {
      _ = try JSONEncoder().encode(corpus)
    }
  }

  @Test("encoding a tempo observation with out-of-range confidence throws")
  func tempoEncodeGuardRejectsBadConfidence() {
    let corpus = JAMSCorpus(entries: [
      JAMSFile(
        fileMetadata: JAMSFileMetadata(
          title: "T", artist: nil, duration: 0,
          identifiers: JAMSIdentifiers(basename: "t.wav", localPath: nil, trackId: "T")),
        annotations: [
          JAMSAnnotation(
            namespace: .tempo,
            data: [JAMSObservation(time: 0, value: JAMSValue(174), confidence: 1.5, duration: 0)])
        ])
    ])
    #expect(throws: JAMSEncodingError.tempoConfidenceOutOfRange(1.5)) {
      _ = try JSONEncoder().encode(corpus)
    }
  }

  @Test("a valid tempo entry encodes and round-trips through tempoBPM()")
  func validTempoEncodesAndRoundTrips() throws {
    let corpus = JAMSCorpus(entries: [oa300Entry(bpm: 128, genre: "house")])
    let data = try JSONEncoder().encode(corpus)
    let back = try JSONDecoder().decode(JAMSCorpus.self, from: data)
    #expect(try back.entries[0].tempoBPM() == 128.0)
  }
}
