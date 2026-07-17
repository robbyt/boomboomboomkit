//
//  DocumentedCaseAuthoredDocsTests.swift
//  BoomBoomBoomKitTests
//
//  Story 11.3a: the four ensemble-and-selection enums (BPMSelectionPolicy,
//  VotingPolicy, EnsemblePolicy, DSPTechnique) now conform to DocumentedCase and
//  ship 24 authored per-case Markdown files. This suite is the STORY-LOCAL
//  structural validator (DD-9/DD-11): because `.docs` is a total function that
//  silently falls back and inline-only markdown renders banned block markup as
//  literal text, a green build proves nothing about authoring quality. Story 11.4
//  generalizes this across every DocumentedCase type + adds the drift switch; this
//  suite is scoped to the four types authored here so malformed prose cannot land
//  mid-epic. Hardened per the 11.3a code review (Codex + edge-case hunt) to close
//  validator false-negatives: word-boundary failure lexicon, per-case payload
//  enforcement, wider banned-markup scan, CRLF tolerance, strict filename set,
//  and one-lead-occurrence / per-paragraph-length checks.
//

// Plain import (NOT @testable): every exercised symbol is public.
import BoomBoomBoomKit
import Foundation
import Testing

@Suite("Story 11.3a authored docs")
struct DocumentedCaseAuthoredDocsTests {

  // MARK: - Expected rosters (order = source declaration order)

  static let bpmStems = [
    "maxConfidence", "dedup", "quorum", "average", "median", "weightedAverage",
    "union", "windowVoting",
  ]
  static let votingStems = ["simpleMajority", "confidenceWeighted", "thresholdGated"]
  static let ensembleStems = [
    "default", "dspOnly", "mlOnly", "highestConfidence", "weightedVoting",
  ]
  static let dspStems = [
    "acfSharpening", "adaptiveThreshold", "subBandNormalization", "expandedCandidates",
    "fineGridRefinement", "subBandVoting", "clickTrackCorrelation", "superFluxOnset",
  ]

  /// Per-type map of the stems that MUST carry a `payload:` front-matter key, and
  /// the exact type it must name. Every other stem MUST NOT carry `payload:`. In
  /// 11.3a the only associated-value case is `EnsemblePolicy.weightedVoting`.
  static let requiredPayloads: [String: [String: String]] = [
    "EnsemblePolicy": ["weightedVoting": "SignalWeights"]
  ]

  /// The on-disk documentation tree, located from this test file's source path so
  /// the validator inspects the exact git-tracked bytes (not the parsed bundle) —
  /// required for the front-matter, word-count, banned-markup, and case-sensitive
  /// filename checks.
  static let docsRoot: URL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()  // BoomBoomBoomKitTests
    .deletingLastPathComponent()  // Tests
    .deletingLastPathComponent()  // repo root
    .appendingPathComponent("Sources/BoomBoomBoomKit/Resources/Documentation")

  // MARK: - documentationID stem lists (lock the filename stems 11.4 depends on)

  @Test("BPMSelectionPolicy documentationID stems match the authored files")
  func bpmDocumentationIDs() {
    #expect(BPMSelectionPolicy.allCases.map(\.documentationID) == Self.bpmStems)
  }

  @Test("VotingPolicy documentationID stems match the authored files")
  func votingDocumentationIDs() {
    #expect(VotingPolicy.allCases.map(\.documentationID) == Self.votingStems)
  }

  @Test("EnsemblePolicy documentationID stems match the authored files (allPolicies order)")
  func ensembleDocumentationIDs() {
    #expect(EnsemblePolicy.allPolicies.map(\.documentationID) == Self.ensembleStems)
  }

  @Test("DSPTechnique documentationID stems match the authored files")
  func dspDocumentationIDs() {
    #expect(DSPTechnique.allCases.map(\.documentationID) == Self.dspStems)
  }

  // MARK: - `.docs` resolves to authored prose (not fallback) + strip proof

  @Test("BPMSelectionPolicy docs resolve", arguments: BPMSelectionPolicy.allCases)
  func bpmDocsResolve(_ policy: BPMSelectionPolicy) {
    Self.assertResolved(policy.docs, policy.documentationID)
  }

  @Test("VotingPolicy docs resolve", arguments: VotingPolicy.allCases)
  func votingDocsResolve(_ policy: VotingPolicy) {
    Self.assertResolved(policy.docs, policy.documentationID)
  }

  @Test("EnsemblePolicy docs resolve", arguments: EnsemblePolicy.allPolicies)
  func ensembleDocsResolve(_ policy: EnsemblePolicy) {
    Self.assertResolved(policy.docs, policy.documentationID)
  }

  @Test("DSPTechnique docs resolve", arguments: DSPTechnique.allCases)
  func dspDocsResolve(_ technique: DSPTechnique) {
    Self.assertResolved(technique.docs, technique.documentationID)
  }

  /// A resolved doc is non-empty, is not the fallback, and shows none of the four
  /// front-matter tokens — proving the resource resolved AND the front-matter was
  /// stripped (replaces the retracted "non-fallback proves stripping" claim: an
  /// unterminated block also resolves non-fallback, so we check the render).
  static func assertResolved(_ doc: AttributedString, _ id: String) {
    let text = String(doc.characters)
    #expect(!text.isEmpty, "\(id): empty docs")
    #expect(
      !text.contains("Documentation unavailable"), "\(id): fell back to the unavailable string")
    for token in ["---", "id:", "title:", "payload:"] {
      #expect(
        !text.contains(token), "\(id): front-matter token '\(token)' leaked into rendered docs")
    }
  }

  // MARK: - Structural validator (DD-9) over the on-disk files

  @Test("BPMSelectionPolicy files satisfy the authoring contract")
  func validateBPM() { Self.validateType(kind: "BPMSelectionPolicy", stems: Self.bpmStems) }

  @Test("VotingPolicy files satisfy the authoring contract")
  func validateVoting() { Self.validateType(kind: "VotingPolicy", stems: Self.votingStems) }

  @Test("EnsemblePolicy files satisfy the authoring contract")
  func validateEnsemble() { Self.validateType(kind: "EnsemblePolicy", stems: Self.ensembleStems) }

  @Test("DSPTechnique files satisfy the authoring contract")
  func validateDSP() { Self.validateType(kind: "DSPTechnique", stems: Self.dspStems) }

  @Test("The authored corpus totals exactly 24 files across the four types")
  func totalFileCount() {
    let counts = [
      Self.bpmStems.count, Self.votingStems.count, Self.ensembleStems.count, Self.dspStems.count,
    ]
    #expect(counts.reduce(0, +) == 24)
    var onDiskTotal = 0
    for kind in ["BPMSelectionPolicy", "VotingPolicy", "EnsemblePolicy", "DSPTechnique"] {
      onDiskTotal += Self.visibleFiles(in: Self.docsRoot.appendingPathComponent(kind)).count
    }
    #expect(
      onDiskTotal == 24,
      "expected 24 authored files across the four 11.3a types, found \(onDiskTotal)")
  }

  // MARK: - Validator internals

  /// Failure-mode signal lexicon for the Tradeoff paragraph. An advisory-strict
  /// proxy (DD-9): the substantive "is this a real failure mode?" judgment is the
  /// reviewer's; this only rejects a Tradeoff with no failure language at all.
  /// Matched at a WORD BOUNDARY (a substring match let innocent words through —
  /// e.g. "close" contains "lose", "premise" contains "mis").
  static let failureLexicon = [
    "fail", "mis", "wrong", "incorrect", "error", "degrad", "break", "regress",
    "confus", "collaps", "spurious", "false", "drift", "overcount", "undercount",
    "underperform", "worse", "lose", "lost", "mislead", "discard", "cannot",
    "never", "poor", "dilut", "sink", "vanish", "hurt", "waste", "smear",
    "entrench", "blind", "ignore",
  ]

  static let boldLeads = ["**What it does.**", "**When to pick it.**", "**Tradeoff.**"]

  /// Real, visible files in a directory (skips dotfiles like `.DS_Store`). Used by
  /// the strict filename lock so a stray `_oops.md` / `junk.MD` / extension typo is
  /// caught, not silently filtered away.
  static func visibleFiles(in dir: URL) -> [String] {
    ((try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? [])
      .map { $0.lastPathComponent }
      .filter { !$0.hasPrefix(".") }
  }

  static func validateType(kind: String, stems: [String]) {
    let dir = docsRoot.appendingPathComponent(kind)

    // Strict filename lock: the exact set of visible files must be `<stem>.md` for
    // every expected stem and nothing else (case-sensitive — catches a
    // `MaxConfidence.md` typo that APFS case-insensitivity would mask, and a stray
    // `_oops.md` / `junk.MD` that a filtered count would miss).
    let onDisk = Set(visibleFiles(in: dir))
    let expected = Set(stems.map { "\($0).md" })
    #expect(
      onDisk == expected,
      "\(kind): on-disk files \(onDisk.sorted()) != expected \(expected.sorted()) (exact, case-sensitive)"
    )

    let payloads = requiredPayloads[kind] ?? [:]
    for stem in stems {
      let url = dir.appendingPathComponent("\(stem).md")
      let problems = validateFile(at: url, stem: stem, expectedPayload: payloads[stem])
      #expect(problems.isEmpty, "\(kind)/\(stem).md: \(problems.joined(separator: "; "))")
    }
  }

  /// Applies the DD-9 authoring contract to a single file. `expectedPayload` is
  /// non-nil iff the case carries an associated value (then `payload:` must be
  /// present and equal to it); nil means `payload:` must be ABSENT.
  static func validateFile(at url: URL, stem: String, expectedPayload: String?) -> [String] {
    var problems: [String] = []
    guard let data = try? Data(contentsOf: url),
      var content = String(data: data, encoding: .utf8)
    else {
      return ["unreadable"]
    }
    if data.count > 10240 { problems.append("file > 10 KB (\(data.count) bytes)") }

    // CRLF tolerance: the accessor trims `.whitespacesAndNewlines`, so normalize
    // here too rather than reject a CR-authored-but-renderable file.
    content = content.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(
      of: "\r", with: "\n")

    let lines = content.components(separatedBy: "\n")
    guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
      return problems + ["missing opening front-matter delimiter"]
    }
    guard
      let closing = lines.dropFirst().firstIndex(where: {
        $0.trimmingCharacters(in: .whitespaces) == "---"
      })
    else {
      return problems + ["unterminated front-matter block"]
    }

    // Front-matter keys: every non-blank line must be `key: value`; duplicate keys
    // are rejected (silent last-wins would let a bad key hide behind a good one).
    var frontMatter: [String: String] = [:]
    for rawLine in lines[1..<closing] {
      let line = rawLine.trimmingCharacters(in: .whitespaces)
      if line.isEmpty { continue }
      guard let colon = line.firstIndex(of: ":") else {
        problems.append("malformed front-matter line (no colon): \(line)")
        continue
      }
      let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
      let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
      if frontMatter[key] != nil { problems.append("duplicate front-matter key '\(key)'") }
      frontMatter[key] = value
    }
    if frontMatter["id"] == nil { problems.append("front-matter missing id") }
    if (frontMatter["title"] ?? "").isEmpty { problems.append("front-matter missing/empty title") }
    if let id = frontMatter["id"], id != stem {
      problems.append("id '\(id)' != filename stem '\(stem)'")
    }

    // Per-case payload presence/absence + format.
    switch (expectedPayload, frontMatter["payload"]) {
    case (nil, .some(let actual)):
      problems.append("payload '\(actual)' present but this case carries no associated value")
    case (.some(let expected), nil):
      problems.append("missing required payload '\(expected)'")
    case (.some(let expected), .some(let actual)) where actual != expected:
      problems.append("payload '\(actual)' != expected '\(expected)'")
    default:
      break
    }
    if let payload = frontMatter["payload"],
      payload.range(of: "^[A-Za-z_][A-Za-z0-9_.]*$", options: .regularExpression) == nil
    {
      problems.append("payload '\(payload)' is not a type identifier")
    }

    // Body: everything after the closing delimiter.
    let bodyLines = Array(lines[(closing + 1)...])
    let body = bodyLines.joined(separator: "\n")

    // Exactly three bold-lead paragraphs, in order, each lead appearing once, each
    // paragraph carrying real prose (not just its lead).
    let paragraphs = splitParagraphs(bodyLines)
    if paragraphs.count != 3 {
      problems.append("expected 3 paragraphs, found \(paragraphs.count)")
    } else {
      for (index, lead) in boldLeads.enumerated() {
        if !paragraphs[index].hasPrefix(lead) {
          problems.append("paragraph \(index + 1) does not begin with \(lead)")
        }
        let occurrences = body.components(separatedBy: lead).count - 1
        if occurrences != 1 {
          problems.append("bold lead \(lead) appears \(occurrences)x (must be 1)")
        }
        if wordCount(paragraphs[index]) < 20 {
          problems.append("paragraph \(index + 1) has < 20 words (lead without prose?)")
        }
      }
      let tradeoff = paragraphs[2].lowercased()
      let anchored = failureLexicon.map { "\\b\($0)" }.joined(separator: "|")
      if tradeoff.range(of: anchored, options: .regularExpression) == nil {
        problems.append("Tradeoff paragraph has no concrete failure-mode signal")
      }
    }

    // Word count over the body (200-400).
    let words = wordCount(body)
    if words < 200 || words > 400 { problems.append("body word count \(words) outside 200-400") }

    // Banned markup line scan. Under `.inlineOnlyPreservingWhitespace` all of these
    // block forms render as literal text, so they are rejected here, not by the parser.
    for line in bodyLines {
      let leadingSpaces = line.prefix(while: { $0 == " " }).count
      let deindented = String(line.drop(while: { $0 == " " }))
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if line.hasPrefix("    ") && !trimmed.isEmpty { problems.append("indented code block") }
      if leadingSpaces <= 3 {
        if deindented.hasPrefix("#") { problems.append("ATX heading") }
        if deindented.hasPrefix("> ") { problems.append("blockquote") }
        if deindented.hasPrefix("- ") || deindented.hasPrefix("* ") || deindented.hasPrefix("+ ") {
          problems.append("unordered list marker")
        }
        if deindented.range(of: "^[0-9]+\\. ", options: .regularExpression) != nil {
          problems.append("ordered list marker")
        }
      }
      if trimmed.range(of: "^(=+|-{2,})$", options: .regularExpression) != nil {
        problems.append("setext heading rule")
      }
      if line.contains("```") || line.contains("~~~") { problems.append("code fence") }
      if line.contains("`") { problems.append("inline backtick / DocC link") }
      if line.contains("![") { problems.append("image") }
      if line.contains("](") { problems.append("markdown link") }
      if line.contains("<doc:") { problems.append("DocC symbol link") }
      if line.filter({ $0 == "|" }).count >= 2 { problems.append("table pipes") }
    }

    return problems
  }

  static func wordCount(_ text: String) -> Int {
    text.split(whereSeparator: { $0.isWhitespace }).count
  }

  /// Groups body lines into paragraphs separated by one or more blank lines.
  static func splitParagraphs(_ lines: [String]) -> [String] {
    var paragraphs: [String] = []
    var current: [String] = []
    for line in lines {
      if line.trimmingCharacters(in: .whitespaces).isEmpty {
        if !current.isEmpty {
          paragraphs.append(current.joined(separator: "\n"))
          current = []
        }
      } else {
        current.append(line)
      }
    }
    if !current.isEmpty { paragraphs.append(current.joined(separator: "\n")) }
    return paragraphs
  }
}
