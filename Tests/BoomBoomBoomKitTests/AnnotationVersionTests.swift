//
//  AnnotationVersionTests.swift
//  BoomBoomBoomKitTests
//
//  Story 12.3 unit coverage for the I/O matrix: annotation-version resolution
//  (declared / digest / untagged), the previous-schema read rule, the AccuracyTally
//  construction invariant, the degenerate zero proxy, and the strict-versus-floor
//  split on a `tempo2` row. No corpus env var required — runs under `make test`.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@Suite("AnnotationVersion")
struct AnnotationVersionTests {

  // MARK: - Declared branch

  @Test("declared value renders declared:<value>")
  func declaredRenders() throws {
    let v = try AnnotationVersion.declared("giantsteps-v2")
    #expect(v.tag == "declared:giantsteps-v2")
    #expect("\(v)" == "declared:giantsteps-v2")
  }

  @Test("declared rejects empty, whitespace, the untagged literal, and reserved prefixes")
  func declaredRejectsInvalidValues() {
    #expect(throws: AnnotationVersion.ResolutionError.emptyDeclaredVersion("")) {
      _ = try AnnotationVersion.declared("")
    }
    #expect(throws: AnnotationVersion.ResolutionError.emptyDeclaredVersion("  \n\t ")) {
      _ = try AnnotationVersion.declared("  \n\t ")
    }
    #expect(throws: AnnotationVersion.ResolutionError.reservedDeclaredVersion("untagged")) {
      _ = try AnnotationVersion.declared("untagged")
    }
    #expect(throws: AnnotationVersion.ResolutionError.reservedDeclaredVersion("sha256:abc")) {
      _ = try AnnotationVersion.declared("sha256:abc")
    }
    #expect(throws: AnnotationVersion.ResolutionError.reservedDeclaredVersion("declared:x")) {
      _ = try AnnotationVersion.declared("declared:x")
    }
  }

  @Test("declared reserved checks are case-insensitive")
  func declaredReservedCaseInsensitive() {
    for forged in ["Untagged", "UNTAGGED", "SHA256:abc", "Sha256:abc", "DECLARED:x"] {
      #expect(
        throws: AnnotationVersion.ResolutionError.reservedDeclaredVersion(forged),
        "expected rejection for \(forged)"
      ) {
        _ = try AnnotationVersion.declared(forged)
      }
    }
  }

  @Test("declared trims surrounding whitespace and rejects control characters")
  func declaredTrimsAndRejectsControlCharacters() throws {
    #expect(try AnnotationVersion.declared("  v2 \n").tag == "declared:v2")
    for bad in ["v\n2", "v\t2", "v\u{0000}2", "v\u{0007}2"] {
      #expect(
        throws: AnnotationVersion.ResolutionError.invalidDeclaredVersion(bad),
        "expected rejection for \(String(reflecting: bad))"
      ) {
        _ = try AnnotationVersion.declared(bad)
      }
    }
  }

  // MARK: - Resolution (two-rule)

  private let rows = [
    AnnotationVersion.AnnotationRow(
      stableRowID: "a.wav", primaryTempo: 120.0, alternateTempo: nil, genre: "techno"),
    AnnotationVersion.AnnotationRow(
      stableRowID: "b.wav", primaryTempo: 174.0, alternateTempo: 87.0, genre: "drum-and-bass"),
  ]

  @Test("no declared version resolves to a sha256 digest, never untagged")
  func noDeclaredVersionDigests() throws {
    let v = try AnnotationVersion.resolve(declaredVersions: [], corpus: "oa300", rows: rows)
    #expect(v != .untagged)
    #expect(v.tag.hasPrefix("sha256:"))
    #expect(v.tag.count == "sha256:".count + 64)
  }

  @Test("agreeing declared versions resolve to the declared tag")
  func agreeingDeclaredVersionsResolve() throws {
    let v = try AnnotationVersion.resolve(
      declaredVersions: ["v2", "v2"], corpus: "oa300", rows: rows)
    #expect(v.tag == "declared:v2")
  }

  @Test("conflicting declared versions fail loudly")
  func conflictingDeclaredVersionsThrow() {
    #expect(
      throws: AnnotationVersion.ResolutionError.conflictingDeclaredVersions(["v1", "v2"])
    ) {
      _ = try AnnotationVersion.resolve(
        declaredVersions: ["v2", "v1"], corpus: "oa300", rows: rows)
    }
  }

  // MARK: - Content digest properties

  @Test("digest is deterministic and row-order invariant")
  func digestDeterministicAndOrderInvariant() throws {
    let a = try AnnotationVersion.contentDigest(corpus: "giantsteps", rows: rows)
    let b = try AnnotationVersion.contentDigest(corpus: "giantsteps", rows: rows.reversed())
    #expect(a == b)
  }

  @Test("two annotation sets over the same corpus resolve to different tags")
  func differentContentDifferentTags() throws {
    let reannotated = [
      rows[0],
      AnnotationVersion.AnnotationRow(
        stableRowID: "b.wav", primaryTempo: 87.0, alternateTempo: 174.0, genre: "drum-and-bass"),
    ]
    let a = try AnnotationVersion.contentDigest(corpus: "giantsteps", rows: rows)
    let b = try AnnotationVersion.contentDigest(corpus: "giantsteps", rows: reannotated)
    #expect(a != b)
  }

  @Test("digest is corpus-namespaced")
  func digestCorpusNamespaced() throws {
    let a = try AnnotationVersion.contentDigest(corpus: "oa300", rows: rows)
    let b = try AnnotationVersion.contentDigest(corpus: "giantsteps", rows: rows)
    #expect(a != b)
  }

  @Test("nil alternate and empty-string-adjacent rows do not collide")
  func nilMarkerDisambiguates() throws {
    // A nil genre must not digest identically to any present genre.
    let withNilGenre = [
      AnnotationVersion.AnnotationRow(
        stableRowID: "a", primaryTempo: 120, alternateTempo: nil, genre: nil)
    ]
    let withEmptyGenre = [
      AnnotationVersion.AnnotationRow(
        stableRowID: "a", primaryTempo: 120, alternateTempo: nil, genre: "")
    ]
    #expect(
      try AnnotationVersion.contentDigest(corpus: "c", rows: withNilGenre)
        != AnnotationVersion.contentDigest(corpus: "c", rows: withEmptyGenre))
  }

  @Test("duplicate stable row IDs throw: the digest must not conflate rows")
  func duplicateRowIDThrows() {
    let duplicated = rows + [rows[0]]
    #expect(
      throws: AnnotationVersion.ResolutionError.duplicateStableRowID(
        corpus: "giantsteps", rowID: "a.wav")
    ) {
      _ = try AnnotationVersion.contentDigest(corpus: "giantsteps", rows: duplicated)
    }
  }

  @Test("an empty corpus must not mint a tag: digest and resolve both throw")
  func emptyCorpusThrows() {
    #expect(throws: AnnotationVersion.ResolutionError.emptyRowSet(corpus: "oa300")) {
      _ = try AnnotationVersion.contentDigest(corpus: "oa300", rows: [])
    }
    #expect(throws: AnnotationVersion.ResolutionError.emptyRowSet(corpus: "oa300")) {
      _ = try AnnotationVersion.resolve(declaredVersions: ["v2"], corpus: "oa300", rows: [])
    }
  }

  @Test("non-finite tempo values throw")
  func nonFiniteTempoThrows() {
    for bad in [Double.nan, .infinity, -.infinity] {
      #expect(
        throws: AnnotationVersion.ResolutionError.nonFiniteTempo(corpus: "c", rowID: "x")
      ) {
        _ = try AnnotationVersion.contentDigest(
          corpus: "c",
          rows: [AnnotationVersion.AnnotationRow(stableRowID: "x", primaryTempo: bad)])
      }
      #expect(
        throws: AnnotationVersion.ResolutionError.nonFiniteTempo(corpus: "c", rowID: "x")
      ) {
        _ = try AnnotationVersion.contentDigest(
          corpus: "c",
          rows: [
            AnnotationVersion.AnnotationRow(
              stableRowID: "x", primaryTempo: 120, alternateTempo: bad)
          ])
      }
    }
  }

  @Test("negative zero and positive zero digest identically")
  func negativeZeroCanonicalized() throws {
    let negative = [AnnotationVersion.AnnotationRow(stableRowID: "x", primaryTempo: -0.0)]
    let positive = [AnnotationVersion.AnnotationRow(stableRowID: "x", primaryTempo: 0.0)]
    let a = try AnnotationVersion.contentDigest(corpus: "c", rows: negative)
    let b = try AnnotationVersion.contentDigest(corpus: "c", rows: positive)
    #expect(a == b)
  }

  @Test("row sort is UTF-8 byte order: two input orderings yield the same tag")
  func utf8ByteOrderSortDeterministic() throws {
    // "É" (U+00C9, utf8 c3 89) sorts after "z" (7a) in byte order; mix in ASCII
    // so a String-comparison sort would disagree with the byte-order sort.
    let mixed = [
      AnnotationVersion.AnnotationRow(stableRowID: "É.wav", primaryTempo: 100),
      AnnotationVersion.AnnotationRow(stableRowID: "z.wav", primaryTempo: 120),
      AnnotationVersion.AnnotationRow(stableRowID: "a.wav", primaryTempo: 140),
    ]
    let a = try AnnotationVersion.contentDigest(corpus: "c", rows: mixed)
    let b = try AnnotationVersion.contentDigest(corpus: "c", rows: mixed.reversed())
    let c = try AnnotationVersion.contentDigest(
      corpus: "c", rows: [mixed[1], mixed[2], mixed[0]])
    #expect(a == b)
    #expect(a == c)
  }

  // MARK: - Codable (validating)

  @Test("untagged round-trips as a first-class value")
  func untaggedRoundTrips() throws {
    let data = try JSONEncoder().encode(AnnotationVersion.untagged)
    #expect(data == Data("\"untagged\"".utf8))
    let decoded = try JSONDecoder().decode(AnnotationVersion.self, from: data)
    #expect(decoded == .untagged)
  }

  @Test("malformed tags are a decode failure, not a silent untagged")
  func malformedTagsFailDecode() {
    for raw in [
      "", "v2", "sha256:short", "sha256:\(String(repeating: "G", count: 64))",
      "declared:", "declared:untagged", "UNTAGGED",
    ] {
      let data = Data("\"\(raw)\"".utf8)
      #expect(throws: (any Error).self, "expected decode failure for \(raw)") {
        _ = try JSONDecoder().decode(AnnotationVersion.self, from: data)
      }
    }
  }

  @Test("well-formed tags decode verbatim")
  func wellFormedTagsDecode() throws {
    let hex = String(repeating: "ab", count: 32)
    for raw in ["untagged", "declared:v2", "sha256:\(hex)"] {
      let decoded = try JSONDecoder().decode(
        AnnotationVersion.self, from: Data("\"\(raw)\"".utf8))
      #expect(decoded.tag == raw)
    }
  }

  // MARK: - Previous-schema read rule (perf-baseline back-compat)

  @Test("previous schema (2) surfaces untagged for an absent version field")
  func previousSchemaDefaultsUntagged() throws {
    let v = try AccuracyRecordSchema.annotationVersion(fromDecoded: nil, schemaVersion: 2)
    #expect(v == .untagged)
  }

  @Test("current schema (3) requires the version field")
  func currentSchemaRequiresVersion() throws {
    let present = try AnnotationVersion.declared("v2")
    let v = try AccuracyRecordSchema.annotationVersion(fromDecoded: present, schemaVersion: 3)
    #expect(v == present)
    #expect(
      throws: AccuracyRecordSchema.SchemaError.missingAnnotationVersion(schemaVersion: 3)
    ) {
      _ = try AccuracyRecordSchema.annotationVersion(fromDecoded: nil, schemaVersion: 3)
    }
  }

  @Test("previous schema (2) with a PRESENT version field is a loud failure")
  func previousSchemaRejectsPresentField() {
    #expect(
      throws: AccuracyRecordSchema.SchemaError.unexpectedAnnotationVersion(schemaVersion: 2)
    ) {
      _ = try AccuracyRecordSchema.annotationVersion(fromDecoded: .untagged, schemaVersion: 2)
    }
  }

  @Test("unsupported schema versions are rejected")
  func unsupportedSchemaRejected() {
    #expect(throws: AccuracyRecordSchema.SchemaError.unsupportedSchemaVersion(1)) {
      _ = try AccuracyRecordSchema.annotationVersion(fromDecoded: nil, schemaVersion: 1)
    }
    #expect(throws: AccuracyRecordSchema.SchemaError.unsupportedSchemaVersion(4)) {
      _ = try AccuracyRecordSchema.annotationVersion(fromDecoded: .untagged, schemaVersion: 4)
    }
  }

  // MARK: - Loader resolution (synthetic fixtures)

  /// One-entry JAMS corpus with a configurable `annotation_metadata` body.
  private func jamsCorpusJSON(annotationMetadata: String) -> Data {
    Data(
      """
      { "entries": [ {
        "file_metadata": { "title": "x", "duration": 0, "jams_version": "0.4.0",
          "identifiers": { "basename": "x.wav", "local_path": "x.wav", "track_id": "x" } },
        "annotations": [ { "namespace": "tempo",
          "data": [ { "time": 0, "duration": 0, "value": 120.0, "confidence": 1.0 } ],
          "annotation_metadata": \(annotationMetadata) } ],
        "sandbox": { "genre": "techno" } } ] }
      """.utf8)
  }

  @Test("OA300 loader takes the digest branch when no annotation declares a version")
  func oa300LoaderDigestsWhenUndeclared() throws {
    let corpus = try OA300Track.loadVersionedCorpus(
      from: jamsCorpusJSON(annotationMetadata: "{}"))
    #expect(corpus.tracks.count == 1)
    #expect(corpus.annotationVersion.tag.hasPrefix("sha256:"))
  }

  @Test("OA300 loader takes the declared branch for a version-declaring annotation")
  func oa300LoaderDeclaredBranch() throws {
    let corpus = try OA300Track.loadVersionedCorpus(
      from: jamsCorpusJSON(annotationMetadata: #"{ "version": "oa300-2026-08" }"#))
    #expect(corpus.annotationVersion.tag == "declared:oa300-2026-08")
  }

  @Test("OA300 loader rejects a forged declared version loudly")
  func oa300LoaderRejectsForgedDeclaredVersion() {
    #expect(throws: AnnotationVersion.ResolutionError.reservedDeclaredVersion("untagged")) {
      _ = try OA300Track.loadVersionedCorpus(
        from: jamsCorpusJSON(annotationMetadata: #"{ "version": "untagged" }"#))
    }
  }

  @Test("GiantSteps loader digests; annotation-identical re-serialization keeps the tag")
  func giantStepsLoaderDigestsCanonically() throws {
    let json = Data(
      """
      [ { "filename": "1.mp3", "bpm": 174.0, "tempo2": 87.0,
          "track_id": "1", "genre": "drum-and-bass" } ]
      """.utf8)
    // Same annotation content, different serialization (key order, whitespace).
    let reserialized = Data(
      """
      [{"genre":"drum-and-bass","track_id":"1","tempo2":87.0,"bpm":174.0,"filename":"1.mp3"}]
      """.utf8)
    let a = try GiantStepsTrack.loadVersionedCorpus(from: json)
    let b = try GiantStepsTrack.loadVersionedCorpus(from: reserialized)
    #expect(a.annotationVersion.tag.hasPrefix("sha256:"))
    #expect(a.annotationVersion == b.annotationVersion)
  }

  @Test("GiantSteps loader rejects an empty-string row ID loudly")
  func giantStepsLoaderRejectsEmptyRowID() {
    let json = Data(
      """
      [ { "filename": "1.mp3", "bpm": 174.0, "track_id": "", "genre": "drum-and-bass" } ]
      """.utf8)
    #expect(
      throws: AnnotationVersion.ResolutionError.missingStableRowID(corpus: "giantsteps")
    ) {
      _ = try GiantStepsTrack.loadVersionedCorpus(from: json)
    }
  }

  @Test("JAMS resolver rejects an empty-string local_path row ID loudly")
  func jamsResolverRejectsEmptyRowID() {
    let json = Data(
      """
      { "entries": [ {
        "file_metadata": { "title": "x", "duration": 0, "jams_version": "0.4.0",
          "identifiers": { "basename": "x.wav", "local_path": "", "track_id": "x" } },
        "annotations": [ { "namespace": "tempo",
          "data": [ { "time": 0, "duration": 0, "value": 120.0, "confidence": 1.0 } ] } ],
        "sandbox": { "genre": "techno" } } ] }
      """.utf8)
    #expect(
      throws: AnnotationVersion.ResolutionError.missingStableRowID(corpus: "oa300")
    ) {
      _ = try OA300Track.loadVersionedCorpus(from: json)
    }
  }
}

@Suite("AccuracyTally")
struct AccuracyTallyTests {

  @Test("octave-error proxy is a track count with percentage points beside it")
  func proxyAggregate() throws {
    let tally = try AccuracyTally(
      acc1: 58, acc2: 74, total: 82, annotationVersion: .untagged)
    #expect(tally.octaveErrorProxy == 16)
    #expect(abs(tally.octaveErrorProxyPercentagePoints - 19.5) < 0.05)
    #expect(tally.formattedOctaveErrorProxy == "16 (19.5 pp)")
  }

  @Test("empty bucket: count 0, percentage points 0.0, no division by zero")
  func proxyEmptyBucket() throws {
    let tally = try AccuracyTally(acc1: 0, acc2: 0, total: 0, annotationVersion: .untagged)
    #expect(tally.octaveErrorProxy == 0)
    #expect(tally.octaveErrorProxyPercentagePoints == 0.0)
    #expect(tally.formattedOctaveErrorProxy == "0 (0.0 pp)")
  }

  @Test("degenerate acc1 == acc2 still emits a zero proxy")
  func proxyDegenerate() throws {
    let tally = try AccuracyTally(acc1: 40, acc2: 40, total: 82, annotationVersion: .untagged)
    #expect(tally.octaveErrorProxy == 0)
    #expect(tally.formattedOctaveErrorProxy == "0 (0.0 pp)")
  }

  @Test("acc1 > acc2 is unrepresentable: rejected at construction")
  func rejectsInvertedCounts() {
    #expect(
      throws: AccuracyTally.TallyError.invalidCounts(acc1: 74, acc2: 58, total: 82)
    ) {
      _ = try AccuracyTally(acc1: 74, acc2: 58, total: 82, annotationVersion: .untagged)
    }
    #expect(throws: AccuracyTally.TallyError.self) {
      _ = try AccuracyTally(acc1: 10, acc2: 90, total: 82, annotationVersion: .untagged)
    }
    #expect(throws: AccuracyTally.TallyError.self) {
      _ = try AccuracyTally(acc1: -1, acc2: 0, total: 82, annotationVersion: .untagged)
    }
  }

  @Test("strict-versus-floor split on a tempo2 octave row")
  func strictVersusFloorSplit() {
    // Detected matches the ALTERNATE annotation exactly; the primary is its octave.
    let verdict = mirexTempoVerdict(
      detected: 87.0, primary: 174.0, alternate: 87.0, tolerance: 0.02)
    #expect(verdict.floorAcc1, "floor-compatible metric accepts the alternate annotation")
    #expect(!verdict.strictAcc1, "octave-strict metric misses the primary annotation")
    #expect(verdict.strictAcc2, "the octave relation is still an Acc2 hit against the primary")
    #expect(verdict.floorAcc2)
  }

  @Test("without an alternate annotation the floor verdicts equal the strict ones")
  func noAlternateFloorEqualsStrict() {
    let verdict = mirexTempoVerdict(
      detected: 120.0, primary: 120.0, alternate: nil, tolerance: 0.02)
    #expect(verdict.strictAcc1 == verdict.floorAcc1)
    #expect(verdict.strictAcc2 == verdict.floorAcc2)
    #expect(verdict.strictAcc1)
  }
}
