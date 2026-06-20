//
//  JAMSDecoderTests.swift
//  BoomBoomBoomKit
//
//  Non-env-gated unit tests for the Story-8.7 JAMS decoder: round-trip decode of
//  the multi-track corpus, the decode->encode->decode identity the estimated-JAMS
//  encode path relies on, and typed rejection of an unknown namespace.
//
//  The decoder moved to BoomBoomBoomKitTestSupport in Story 8.8a (DD-1 reversed 8.7
//  DD-7 — see JAMSDecoder.swift). These tests still live in the benchmark target and
//  need no corpus; run them with
//  `swift test --filter BoomBoomBoomKitBenchmarkTests.JAMSDecoderTests`
//  (a bare `swift test` includes them too — they are not env-gated).
//

import BoomBoomBoomKitTestSupport
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
    // Built already-strict (concrete duration + real annotation_metadata, as the
    // benchmark emit now does) so encode is a true identity. A `nil` observation value
    // still round-trips (encodes as JSON null, decodes back to nil); but a `nil`
    // duration/annotation_metadata would NOT — strict-on-encode materializes them, so
    // they are supplied here rather than relying on the fill-in fallbacks.
    let file = JAMSFile(
      fileMetadata: JAMSFileMetadata(
        title: "Est", artist: nil, duration: 12.0,
        identifiers: JAMSIdentifiers(basename: "x.wav", localPath: nil, trackId: "42")),
      annotations: [
        JAMSAnnotation(
          namespace: .beat,
          data: [
            JAMSObservation(time: 0.0, value: JAMSValue(1), confidence: 0.9, duration: 0),
            JAMSObservation(time: 0.4, value: nil, confidence: 0.9, duration: 0),
          ],
          annotationMetadata: JAMSAnnotationMetadata(curator: nil, dataSource: "test"))
      ])
    let corpus = JAMSCorpus(entries: [file])
    let data = try JSONEncoder().encode(corpus)
    let back = try JSONDecoder().decode(JAMSCorpus.self, from: data)
    #expect(back == corpus)
    #expect(back.entries[0].beatAnnotation?.beatTimes == [0.0, 0.4])
    #expect(back.entries[0].beatAnnotation?.downbeatTimes == [0.0])
  }

  // MARK: Strict-emit conformance (JAMS 0.4 required keys)

  @Test("encoded beat corpus always carries JAMS-required keys (strict on encode)")
  func strictEmitRequiredKeys() throws {
    // Build through the SAME constructors the benchmark emit uses, with the nil
    // value/confidence/metadata it passes — the encoder must still write every
    // JAMS-0.4-required key (value/confidence as JSON null) so each entry is
    // standalone-valid. This locks "strict on encode" against an encodeIfPresent regress.
    let file = JAMSFile(
      fileMetadata: JAMSFileMetadata(
        title: nil, artist: nil, duration: 12.5,
        identifiers: JAMSIdentifiers(basename: "x.wav", localPath: nil, trackId: "7")),
      annotations: [
        JAMSAnnotation(
          namespace: .beat,
          data: [
            JAMSObservation(time: 0.0, value: nil, confidence: nil, duration: 0),
            JAMSObservation(time: 0.5, value: nil, confidence: nil, duration: 0),
          ],
          annotationMetadata: nil)
      ],
      sandbox: JAMSSandbox(constantTempo: true))
    let data = try JSONEncoder().encode(JAMSCorpus(entries: [file]))

    // Re-parse generically so we assert on the actual JSON key presence, not the model.
    let root = try #require(
      JSONSerialization.jsonObject(with: data) as? [String: Any], "top-level object")
    let entries = try #require(root["entries"] as? [[String: Any]], "entries array")
    let entry = try #require(entries.first, "one entry")

    let meta = try #require(entry["file_metadata"] as? [String: Any], "file_metadata")
    #expect(meta.keys.contains("jams_version"), "file_metadata must carry jams_version")
    #expect(meta.keys.contains("duration"), "file_metadata must carry duration")
    #expect(meta["jams_version"] as? String == "0.4.0")
    // constant_tempo must live in the JAMS `sandbox`, NOT file_metadata — the real `jams`
    // library rejects unknown file_metadata keys (FileMetadata.__init__ refuses kwargs).
    #expect(!meta.keys.contains("constant_tempo"), "constant_tempo must NOT be in file_metadata")
    let sandbox = try #require(entry["sandbox"] as? [String: Any], "entry-level sandbox")
    #expect(sandbox["constant_tempo"] as? Bool == true)

    let annotations = try #require(entry["annotations"] as? [[String: Any]], "annotations")
    let annotation = try #require(annotations.first, "one annotation")
    for key in ["annotation_metadata", "namespace", "data"] {
      #expect(annotation.keys.contains(key), "annotation must carry \(key)")
    }

    let observations = try #require(annotation["data"] as? [[String: Any]], "observation data")
    #expect(observations.count == 2)
    for obs in observations {
      for key in ["time", "duration", "value", "confidence"] {
        #expect(obs.keys.contains(key), "observation must carry \(key)")
      }
      // value/confidence are present as JSON null (valid for the beat namespace).
      #expect(obs["value"] is NSNull, "nil beat value must encode as JSON null, not be omitted")
      #expect(
        obs["confidence"] is NSNull, "nil confidence must encode as JSON null, not be omitted")
    }
  }

  // MARK: Legacy constant_tempo location (tolerant decode)

  @Test("constant_tempo is read from sandbox, falling back to legacy file_metadata")
  func legacyConstantTempoFallback() throws {
    // A stale oracle carries constant_tempo in file_metadata (no sandbox): it must still
    // decode rather than silently defaulting to constant-tempo (tolerant-on-decode).
    let legacy = Data(
      """
      { "entries": [ { "file_metadata": {
          "duration": 10, "jams_version": "0.4.0", "constant_tempo": false,
          "identifiers": { "track_id": "1" } },
        "annotations": [ { "namespace": "beat", "data": [],
          "annotation_metadata": {} } ] } ] }
      """.utf8)
    let legacyFile = try #require(
      try JSONDecoder().decode(JAMSCorpus.self, from: legacy).entries.first)
    #expect(legacyFile.constantTempo == false, "legacy file_metadata.constant_tempo must be read")

    // sandbox wins when both are present.
    let both = Data(
      """
      { "entries": [ { "file_metadata": {
          "duration": 10, "jams_version": "0.4.0", "constant_tempo": false,
          "identifiers": { "track_id": "1" } },
        "annotations": [ { "namespace": "beat", "data": [], "annotation_metadata": {} } ],
        "sandbox": { "constant_tempo": true } } ] }
      """.utf8)
    let bothFile = try #require(
      try JSONDecoder().decode(JAMSCorpus.self, from: both).entries.first)
    #expect(bothFile.constantTempo == true, "sandbox takes precedence over legacy file_metadata")

    // Re-encoding a legacy file must NOT re-emit file_metadata.constant_tempo (strict home
    // is sandbox; emitting it would break jams.load).
    let reencoded = try JSONEncoder().encode(JAMSCorpus(entries: [legacyFile]))
    let root = try #require(JSONSerialization.jsonObject(with: reencoded) as? [String: Any])
    let entry = try #require((root["entries"] as? [[String: Any]])?.first)
    let meta = try #require(entry["file_metadata"] as? [String: Any])
    #expect(
      !meta.keys.contains("constant_tempo"),
      "legacy constant_tempo must not be re-emitted in file_metadata")
  }

  // MARK: Non-bool constant_tempo (tolerant decode / Swift-Python parity)

  @Test("a present non-bool constant_tempo decodes to nil instead of throwing the whole corpus")
  func nonBoolConstantTempoDecodesTolerantly() throws {
    // A loose/legacy oracle carrying constant_tempo as a STRING or NUMBER must not abort the
    // entire decode — it decodes to nil (parity with eval-beatgrid.py, which coerces a non-bool
    // to its default), honoring the tolerant-on-decode contract. Covers both the sandbox and the
    // legacy file_metadata location.
    let stringSandbox = Data(
      """
      { "entries": [ { "file_metadata": {
          "duration": 10, "jams_version": "0.4.0", "identifiers": { "track_id": "1" } },
        "annotations": [ { "namespace": "beat", "data": [], "annotation_metadata": {} } ],
        "sandbox": { "constant_tempo": "true" } } ] }
      """.utf8)
    let f1 = try #require(
      try JSONDecoder().decode(JAMSCorpus.self, from: stringSandbox).entries.first)
    #expect(
      f1.constantTempo == nil, "non-bool sandbox constant_tempo must decode to nil, not throw")

    let intLegacy = Data(
      """
      { "entries": [ { "file_metadata": {
          "duration": 10, "jams_version": "0.4.0", "constant_tempo": 1,
          "identifiers": { "track_id": "1" } },
        "annotations": [ { "namespace": "beat", "data": [], "annotation_metadata": {} } ] } ] }
      """.utf8)
    let f2 = try #require(
      try JSONDecoder().decode(JAMSCorpus.self, from: intLegacy).entries.first)
    #expect(f2.constantTempo == nil, "non-bool legacy constant_tempo must decode to nil, not throw")
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
