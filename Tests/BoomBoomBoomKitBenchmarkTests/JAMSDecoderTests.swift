//
//  JAMSDecoderTests.swift
//  BoomBoomBoomKit
//
//  Non-env-gated unit tests for the Story-8.7 JAMS decoder: round-trip decode of
//  the multi-track corpus, the decode->encode->decode identity the estimated-JAMS
//  encode path relies on, and typed rejection of an unknown namespace.
//
//  Lives in the benchmark target (DD-7 — the decoder must not leak onto consumer
//  test packages via BoomBoomBoomKitTestSupport). These tests need no corpus; run
//  them with `swift test --filter BoomBoomBoomKitBenchmarkTests.JAMSDecoderTests`
//  (a bare `swift test` includes them too — they are not env-gated).
//

import Foundation
import Testing

// MARK: - JAMS Decoder Tests

@Suite("JAMS Decoder")
struct JAMSDecoderTests {

  private func loadSampleData() throws -> Data {
    let url =
      Bundle.module.url(forResource: "jams-decoder-sample", withExtension: "json")
      ?? Bundle.module.url(forResource: "Fixtures/jams-decoder-sample", withExtension: "json")
    let resolved = try #require(url, "jams-decoder-sample.json fixture not found in bundle")
    return try Data(contentsOf: resolved)
  }

  // MARK: Round-trip decode

  @Test("decodes the multi-track corpus: times, values, null, namespaces")
  func decodeSample() throws {
    let corpus = try JSONDecoder().decode(JAMSCorpus.self, from: loadSampleData())
    try #require(corpus.entries.count == 1)

    let file = corpus.entries[0]
    #expect(file.fileMetadata.title == "Sample Track")
    #expect(file.fileMetadata.identifiers?.trackId == "1")
    #expect(file.fileMetadata.identifiers?.localPath == "/tmp/sample.wav")

    let beat = try #require(file.beatAnnotation, "expected a beat annotation")
    #expect(beat.namespace == .beat)
    #expect(beat.data.count == 2)
    // Beat times round-trip exactly.
    #expect(beat.beatTimes == [0.5, 1.0])
    // The first observation carries bar-phase 1 (a downbeat); the second is null -> nil.
    #expect(beat.data[0].value?.int == 1)
    #expect(beat.data[1].value == nil)
    // Only the value==1 observation is a downbeat.
    #expect(beat.downbeatTimes == [0.5])

    // The tempo namespace decodes too (8.8 reuse): value is the BPM.
    let tempo = try #require(
      file.annotations.first { $0.namespace == .tempo }, "expected a tempo annotation")
    #expect(tempo.data.first?.value?.number == 174.0)
    #expect(tempo.annotationMetadata?.dataSource == "hand-written fixture")
  }

  // MARK: decode -> encode -> decode identity (the estimated-JAMS encode path, F9)

  @Test("decode -> encode -> decode is identity (covers beat, tempo, null)")
  func roundTripIdentity() throws {
    let decoder = JSONDecoder()
    let first = try decoder.decode(JAMSCorpus.self, from: loadSampleData())
    let reencoded = try JSONEncoder().encode(first)
    let second = try decoder.decode(JAMSCorpus.self, from: reencoded)
    #expect(first == second)
  }

  // MARK: Encode a synthesized estimated corpus, then read it back

  @Test("a hand-built estimated corpus round-trips through encode/decode")
  func encodeEstimatedCorpus() throws {
    let file = JAMSFile(
      fileMetadata: JAMSFileMetadata(
        title: "Est", artist: nil, duration: nil,
        identifiers: JAMSIdentifiers(basename: "x.wav", localPath: nil, trackId: "42")),
      annotations: [
        JAMSAnnotation(
          namespace: .beat,
          data: [
            JAMSObservation(time: 0.0, value: JAMSValue(1), confidence: 0.9, duration: 0),
            JAMSObservation(time: 0.4, value: nil, confidence: 0.9, duration: 0),
          ],
          annotationMetadata: nil)
      ])
    let corpus = JAMSCorpus(entries: [file])
    let data = try JSONEncoder().encode(corpus)
    let back = try JSONDecoder().decode(JAMSCorpus.self, from: data)
    #expect(back == corpus)
    #expect(back.entries[0].beatAnnotation?.beatTimes == [0.0, 0.4])
    #expect(back.entries[0].beatAnnotation?.downbeatTimes == [0.0])
  }

  // MARK: Unknown-namespace rejection

  @Test("an unknown namespace throws JAMSDecodingError.unknownNamespace")
  func unknownNamespaceThrows() throws {
    let json = """
      { "entries": [ { "file_metadata": { "identifiers": { "track_id": "1" } },
        "annotations": [ { "namespace": "chord", "data": [] } ] } ] }
      """
    let data = Data(json.utf8)
    #expect(throws: JAMSDecodingError.unknownNamespace("chord")) {
      _ = try JSONDecoder().decode(JAMSCorpus.self, from: data)
    }
  }
}
