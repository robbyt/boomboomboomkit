//
//  DocumentationValidatorTests.swift
//  BoomBoomBoomKitTests
//
//  Story 11.4: the authoritative, cross-type documentation validator for the
//  Epic 11 canonical Markdown corpus. Because `BoomBoomBoomKitDocs.docs` is a
//  TOTAL function that silently returns a fallback, and inline-only markdown
//  renders banned block markup as literal text, a green build proves nothing
//  about authoring quality — this suite proves it. It SUPERSEDES the three
//  story-local guards (`DocumentedCaseAuthoredDocsTests` [11.3a],
//  `DocumentedCaseAuthoredDocsTests11B` [11.3b], `RosterDriftCanaries` [11.3
//  follow-up]), which have been deleted; their load-bearing checks are carried
//  here and into the FR-50 drift suites in `DocumentedCaseTests.swift`.
//
//  `DocCorpus` below is the single source of truth (the `kind -> ids` +
//  `kind -> payloads` registry, the representative case lists for the
//  non-CaseIterable enums, and the shared `validate(file:)` core) consumed by
//  both this file and the drift suites, so the two can never disagree about a
//  type's real cases.
//

// Plain import (NOT @testable): every exercised symbol is public.
import BoomBoomBoomKit
import Foundation
import Testing

// MARK: - Shared corpus registry + validator core

/// Single source of truth for the documentation corpus, shared by
/// `DocumentationValidatorTests` and the FR-50 drift suites.
enum DocCorpus {

  // MARK: On-disk root

  /// The on-disk documentation tree, located from THIS test file's source path
  /// so the validator inspects the exact git-tracked bytes (not the parsed
  /// bundle) — required for front-matter, word-count, banned-markup, and
  /// case-sensitive filename checks. Both `DocumentationValidatorTests.swift`
  /// and `DocumentedCaseTests.swift` live in the same directory, so the walk is
  /// identical from either.
  static let docsRoot: URL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()  // BoomBoomBoomKitTests
    .deletingLastPathComponent()  // Tests
    .deletingLastPathComponent()  // repo root
    .appendingPathComponent("Sources/BoomBoomBoomKit/Resources/Documentation")

  // MARK: Representative instances for the non-CaseIterable enums

  /// A well-formed `DownbeatEstimate` for `DownbeatResult.detected(estimate:)`.
  static let sampleEstimate = DownbeatEstimate(
    beats: [BeatTimestamp(presentationTime: 0.0, confidence: 1.0, strength: 1.0)],
    meter: MeterEstimate(beatsPerBar: 4, source: .assumed),
    confidence: 0.9, phaseIndex: 0)

  static let mlCases: [MLExecutionPolicy] = [.never, .always, .whenDSPConfidenceBelow(0.85)]
  static let downbeatCases: [DownbeatResult] = [
    .notAttempted, .noneDetected, .detected(estimate: sampleEstimate),
  ]
  static let abstainCases: [AbstainReason] = [
    .policyDisabled, .inputBelowMinimum, .confidenceBelowFloor, .sourceSpecific("x"),
  ]
  static let demotionCases: [DemotionReason] = [.implausibleForContext, .sourceSpecific("x")]

  // MARK: Source-linked registry (kind -> ids, kind -> payloads)

  /// Canonical `documentationID`s per type, derived from the LIVE enums
  /// (`allCases` / `allPolicies` / the representative lists above) — NOT
  /// re-typed literals. This is the single roster both the file validator and
  /// the drift suites consume, so they cannot disagree about a type's cases.
  static let expectedIDs: [String: [String]] = [
    "BPMSelectionPolicy": BPMSelectionPolicy.allCases.map(\.documentationID),
    "VotingPolicy": VotingPolicy.allCases.map(\.documentationID),
    "DSPTechnique": DSPTechnique.allCases.map(\.documentationID),
    "AnalysisIntensity": AnalysisIntensity.allCases.map(\.documentationID),
    "OctaveEquivalencePolicy": OctaveEquivalencePolicy.allCases.map(\.documentationID),
    "EnsemblePolicy": EnsemblePolicy.allPolicies.map(\.documentationID),
    "MLExecutionPolicy": mlCases.map(\.documentationID),
    "DownbeatResult": downbeatCases.map(\.documentationID),
    "AbstainReason": abstainCases.map(\.documentationID),
    "DemotionReason": demotionCases.map(\.documentationID),
  ]

  /// Per-type map of the stems that MUST carry a `payload:` front-matter key and
  /// the exact type it must name (source-verified). Every other stem MUST NOT
  /// carry `payload:`.
  static let expectedPayloads: [String: [String: String]] = [
    "EnsemblePolicy": ["weightedVoting": "SignalWeights"],
    "MLExecutionPolicy": ["whenDSPConfidenceBelow": "Double"],
    "DownbeatResult": ["detected": "DownbeatEstimate"],
    "AbstainReason": ["sourceSpecific": "String"],
    "DemotionReason": ["sourceSpecific": "String"],
  ]

  // MARK: Scope collection (Paige #6)

  /// Real, visible files in a directory (skips dotfiles like `.DS_Store`).
  static func visibleFiles(in dir: URL) -> [String] {
    ((try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? [])
      .map { $0.lastPathComponent }
      .filter { !$0.hasPrefix(".") }
  }

  /// The non-`_` `<Type>/` directory names directly under `root`.
  static func typeDirectories(under root: URL) -> [String] {
    ((try? FileManager.default.contentsOfDirectory(
      at: root, includingPropertiesForKeys: [.isDirectoryKey])) ?? [])
      .filter { url in
        let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
        return isDir && !url.lastPathComponent.hasPrefix("_")
      }
      .map { $0.lastPathComponent }
  }

  /// The CONTENT-validation collector: `<root>/<Type>/*.md`, one level deep,
  /// excluding `_`-prefixed DIRECTORIES (so `_Fixture/` is skipped wholesale)
  /// and `_`-prefixed file stems, and never descending to `<root>/*.md`. A
  /// wrong `root` yields an empty result (the scope test guards that with a
  /// positive control).
  static func collectInScope(root: URL) -> [URL] {
    var files: [URL] = []
    for typeName in typeDirectories(under: root) {
      let dir = root.appendingPathComponent(typeName)
      for name in visibleFiles(in: dir) where name.hasSuffix(".md") && !name.hasPrefix("_") {
        files.append(dir.appendingPathComponent(name))
      }
    }
    return files.sorted { $0.path < $1.path }
  }

  /// The real in-scope corpus (the 49 authored files).
  static let inScopeFiles: [URL] = collectInScope(root: docsRoot)

  // MARK: Authoring rules

  enum Rule: String, CaseIterable, Sendable {
    case frontMatterSchema
    case fencedCode
    case indentedCode
    case table
    case image
    case link
    case inlineBacktickOrDocLink
    case atxHeading
    case setextHeadingRule
    case blockquote
    case listMarker
    case fileSize
    case threeOrderedBoldLeads
    case paragraphHasProse
    case paragraphSingleLine
    case tradeoffFailureSignal
    case wordCountBand
    case renderRoundTrip
  }

  struct Problem: Sendable, CustomStringConvertible {
    let rule: Rule
    let detail: String
    var description: String { "[\(rule.rawValue)] \(detail)" }
  }

  static let boldLeads = ["**What it does.**", "**When to pick it.**", "**Tradeoff.**"]

  /// Failure-mode signal lexicon for the Tradeoff paragraph (word-boundary
  /// matched). An advisory-strict proxy: it only rejects a Tradeoff with no
  /// failure language at all; the substantive judgment is the reviewer's.
  static let failureLexicon = [
    // Targeted `mis*` stems (the bare "mis" matched innocent words like "mission").
    "mistak", "miscalibr", "misclass", "misrank", "mispick", "misdetect", "mispuls", "misalign",
    "fail", "wrong", "incorrect", "error", "degrad", "break", "regress",
    "confus", "collaps", "spurious", "false", "drift", "overcount", "undercount",
    "underperform", "worse", "lose", "lost", "mislead", "discard", "cannot",
    "never", "poor", "dilut", "sink", "vanish", "hurt", "waste", "smear",
    "entrench", "blind", "ignore",
  ]

  // MARK: Validate core (shared by both @Test axes)

  /// Applies the full authoring contract to one file. Returns hard-failure
  /// `Problem`s plus soft `warnings` (the word-count band 100..199 / 401..600).
  /// `kind`/`stem` come from the file's parent directory + filename so the
  /// front-matter `id`/`payload` checks resolve against the live registry.
  static func validate(fileAt url: URL) -> (problems: [Problem], warnings: [String]) {
    let kind = url.deletingLastPathComponent().lastPathComponent
    let stem = url.deletingPathExtension().lastPathComponent
    var problems: [Problem] = []
    var warnings: [String] = []
    func fail(_ rule: Rule, _ detail: String) {
      problems.append(Problem(rule: rule, detail: detail))
    }

    guard let data = try? Data(contentsOf: url),
      let rawContent = String(data: data, encoding: .utf8)
    else {
      fail(.frontMatterSchema, "unreadable")
      return (problems, warnings)
    }
    if data.count > 10240 { fail(.fileSize, "file > 10 KB (\(data.count) bytes)") }

    // CRLF tolerance for the STRUCTURAL checks: the accessor trims
    // `.whitespacesAndNewlines`, so normalize here too rather than reject a
    // CR-authored-but-renderable file. The render round-trip below deliberately
    // strips from `rawContent` (pre-normalization) so it mirrors the accessor's
    // EXACT path — a pure-CR file the accessor cannot front-matter-strip must
    // fail here too, not pass on conveniently-normalized bytes.
    let content = rawContent.replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
    let lines = content.components(separatedBy: "\n")

    // Front-matter block.
    guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
      fail(.frontMatterSchema, "missing opening front-matter delimiter")
      return (problems, warnings)
    }
    guard
      let closing = lines.dropFirst().firstIndex(where: {
        $0.trimmingCharacters(in: .whitespaces) == "---"
      })
    else {
      fail(.frontMatterSchema, "unterminated front-matter block")
      return (problems, warnings)
    }

    var frontMatter: [String: String] = [:]
    for rawLine in lines[1..<closing] {
      let line = rawLine.trimmingCharacters(in: .whitespaces)
      if line.isEmpty { continue }
      guard let colon = line.firstIndex(of: ":") else {
        fail(.frontMatterSchema, "malformed front-matter line (no colon): \(line)")
        continue
      }
      let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
      let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
      if frontMatter[key] != nil { fail(.frontMatterSchema, "duplicate front-matter key '\(key)'") }
      frontMatter[key] = value
    }
    if frontMatter["id"] == nil { fail(.frontMatterSchema, "missing id") }
    if (frontMatter["title"] ?? "").isEmpty { fail(.frontMatterSchema, "missing/empty title") }
    if let id = frontMatter["id"], id != stem {
      fail(.frontMatterSchema, "id '\(id)' != filename stem '\(stem)'")
    }
    // id must name a real case on the parent-directory type (file -> case). An
    // UNKNOWN kind (a type dir with no validator registry entry) is itself a
    // per-file schema failure — the check must not silently pass just because
    // the registry lookup is nil (the directory<->registry test catches it too,
    // but the per-file axis must be self-sufficient per AC-4/AC-5).
    if let ids = expectedIDs[kind] {
      if let id = frontMatter["id"], !ids.contains(id) {
        fail(.frontMatterSchema, "id '\(id)' is not a real case on \(kind)")
      }
    } else {
      fail(.frontMatterSchema, "unknown documentation type '\(kind)' — no validator registry entry")
    }

    // Payload presence/absence + type + format.
    let expectedPayload = (expectedPayloads[kind] ?? [:])[stem]
    switch (expectedPayload, frontMatter["payload"]) {
    case (nil, .some(let actual)):
      fail(
        .frontMatterSchema, "payload '\(actual)' present but this case carries no associated value")
    case (.some(let expected), nil):
      fail(.frontMatterSchema, "missing required payload '\(expected)'")
    case (.some(let expected), .some(let actual)) where actual != expected:
      fail(.frontMatterSchema, "payload '\(actual)' != expected '\(expected)'")
    default:
      break
    }
    if let payload = frontMatter["payload"],
      payload.range(of: "^[A-Za-z_][A-Za-z0-9_.]*$", options: .regularExpression) == nil
    {
      fail(.frontMatterSchema, "payload '\(payload)' is not a type identifier")
    }

    // Body: everything after the closing delimiter.
    let bodyLines = Array(lines[(closing + 1)...])
    let body = bodyLines.joined(separator: "\n")

    // Three ordered bold leads, each exactly once, each paragraph with prose.
    let paragraphs = splitParagraphs(bodyLines)
    if paragraphs.count != 3 {
      fail(.threeOrderedBoldLeads, "expected 3 paragraphs, found \(paragraphs.count)")
    } else {
      for (index, lead) in boldLeads.enumerated() {
        if !paragraphs[index].hasPrefix(lead) {
          fail(.threeOrderedBoldLeads, "paragraph \(index + 1) does not begin with \(lead)")
        }
        let occurrences = body.components(separatedBy: lead).count - 1
        if occurrences != 1 {
          fail(.threeOrderedBoldLeads, "bold lead \(lead) appears \(occurrences)x (must be 1)")
        }
        if wordCount(paragraphs[index]) < 20 {
          fail(.paragraphHasProse, "paragraph \(index + 1) has < 20 words (lead without prose?)")
        }
      }
      let tradeoff = paragraphs[2].lowercased()
      let anchored = failureLexicon.map { "\\b\($0)" }.joined(separator: "|")
      if tradeoff.range(of: anchored, options: .regularExpression) == nil {
        fail(.tradeoffFailureSignal, "Tradeoff paragraph has no concrete failure-mode signal")
      }
      // Each paragraph is EXACTLY one physical line (the corpus convention). This
      // is what makes the per-line banned-markup scan below sound: a valid file
      // has no continuation lines, so scanning every line can neither
      // false-positive on a wrapped line nor false-NEGATIVE on markup that a
      // wrapped continuation would otherwise hide. A hard-wrapped paragraph fails
      // HERE, so its stray markup is caught regardless of the markup scan.
      for (index, para) in paragraphs.enumerated() where para.contains("\n") {
        fail(
          .paragraphSingleLine,
          "paragraph \(index + 1) spans multiple physical lines (hard-wrapping disallowed)")
      }
    }

    // Word-count band (DD-6): hard fail outside 100..600; soft warn otherwise.
    let words = wordCount(body)
    if words < 100 || words > 600 {
      fail(.wordCountBand, "body word count \(words) outside hard 100...600")
    } else if words < 200 || words > 400 {
      warnings.append("\(kind)/\(stem).md: body word count \(words) outside soft 200...400")
    }

    // Banned block markup. Under `.inlineOnlyPreservingWhitespace` block parsing
    // is OFF, so these forms render as literal noise — rejected here, not by the
    // parser. Because each paragraph is enforced to a single physical line
    // (above), scanning EVERY body line is sound: a valid file has no
    // continuation lines, so a stray block marker on any line is a real defect
    // (never a wrapped-prose false-positive), and nothing hides on a continuation.
    func isTableDelimiterRow(_ s: String) -> Bool {
      // A GFM table's tell is its delimiter row: only |, -, :, and spaces, with a
      // pipe and a 3+ dash run. Never matches prose (which has letters), so a
      // single-pipe table (`A | B` / `--- | ---`) is caught by its delimiter row
      // WITHOUT flagging an inline `P(beat | onset)` or a leading `|x|` magnitude.
      s.range(of: "^[|:\\- ]*\\|[|:\\- ]*$", options: .regularExpression) != nil
        && s.contains("---")
    }
    for line in bodyLines {
      let deindented = String(line.drop(while: { $0 == " " || $0 == "\t" }))
      let leadingSpaces = line.prefix(while: { $0 == " " }).count
      // Position-insensitive: these render as noise anywhere.
      if line.contains("```") || line.contains("~~~") { fail(.fencedCode, "code fence") }
      if line.contains("`") { fail(.inlineBacktickOrDocLink, "inline backtick / symbol link") }
      if line.contains("<doc:") { fail(.inlineBacktickOrDocLink, "DocC symbol link") }
      // Autolinks (rendered as links under inline-only mode). The general
      // CommonMark URI form is `<scheme:…>` (NOT specifically `scheme://…`), so
      // `<tel:+1…>` / `<urn:isbn:…>` count; plus the email form `<user@host>`.
      if line.range(
        of: "<[A-Za-z][A-Za-z0-9+.-]{1,31}:[^<>\\s]*>",
        options: [.regularExpression, .caseInsensitive]) != nil
        || line.range(of: "<[^>\\s@]+@[^>\\s]+>", options: .regularExpression) != nil
      {
        fail(.link, "autolink")
      }
      if line.contains("![") { fail(.image, "image") }
      if line.contains("](") { fail(.link, "markdown link") }
      // Table: detected by its GFM delimiter row (the leading-pipe shortcut was
      // dropped — it false-positived on `|x| denotes …`).
      if isTableDelimiterRow(deindented) { fail(.table, "table delimiter row") }
      if !deindented.isEmpty,
        deindented.range(of: "^(=+|-+)$", options: .regularExpression) != nil
      {
        fail(.setextHeadingRule, "setext heading / thematic-break rule")
      }
      // Block starters (sound to check every line under single-line paragraphs).
      if (line.hasPrefix("\t") || line.hasPrefix("    "))
        && !line.trimmingCharacters(in: .whitespaces).isEmpty
      {
        fail(.indentedCode, "indented code block")
      }
      guard leadingSpaces <= 3 else { continue }
      // ATX heading: 1-6 `#` then whitespace or EOL (NOT `#1`, which needs a space).
      if deindented.range(of: "^#{1,6}(\\s|$)", options: .regularExpression) != nil {
        fail(.atxHeading, "ATX heading")
      }
      // Blockquote: `>` with or without a following space (`>quoted` counts).
      if deindented.hasPrefix(">") { fail(.blockquote, "blockquote") }
      // Unordered list: -, *, + then whitespace or EOL.
      if deindented.range(of: "^[-*+](\\s|$)", options: .regularExpression) != nil {
        fail(.listMarker, "unordered list marker")
      }
      // Ordered list: digits then `.` or `)` then whitespace (`1.` and `1)`).
      if deindented.range(of: "^[0-9]+[.)](\\s|$)", options: .regularExpression) != nil {
        fail(.listMarker, "ordered list marker")
      }
    }

    // Render round-trip through the real path. Strip from `rawContent` (NOT the
    // CRLF-normalized `content`) so this mirrors the accessor EXACTLY: it reads
    // raw text and strips via `split(separator: "\n")`.
    let stripped = strippingFrontMatter(rawContent)
    // Strip-divergence: we KNOW this file has a terminated front-matter block
    // (found above on normalized content), so a strip that returns `rawContent`
    // unchanged means the accessor's raw-path `split("\n")` could NOT find it —
    // a pure-CR (classic-Mac) file. In production that leaks the id:/title:
    // metadata into `.docs`. Fail it here rather than pass on normalized bytes.
    if stripped == rawContent {
      fail(
        .renderRoundTrip,
        "front matter not stripped on the accessor's raw path (pure-CR line endings?) — "
          + "metadata would render as visible docs")
    }
    if let parsed = try? AttributedString(
      markdown: stripped,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    {
      if !parsed.characters.contains(where: { !$0.isWhitespace }) {
        fail(.renderRoundTrip, "rendered to an empty/whitespace-only AttributedString")
      }
    } else {
      fail(.renderRoundTrip, "AttributedString(markdown:) threw on the body")
    }

    return (problems, warnings)
  }

  // MARK: Helpers

  static func wordCount(_ text: String) -> Int {
    text.split(whereSeparator: { $0.isWhitespace }).count
  }

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

  /// Mirrors the accessor's `strippingFrontMatter`: drops a leading `---`…`---`
  /// block so the metadata is not parsed as body.
  static func strippingFrontMatter(_ raw: String) -> String {
    let lines = raw.split(separator: "\n", omittingEmptySubsequences: false)
    guard let first = lines.first,
      first.trimmingCharacters(in: .whitespacesAndNewlines) == "---"
    else {
      return raw
    }
    guard
      let closing = lines.dropFirst().firstIndex(where: {
        $0.trimmingCharacters(in: .whitespacesAndNewlines) == "---"
      })
    else {
      return raw
    }
    return lines[lines.index(after: closing)...].joined(separator: "\n")
  }

  /// Strip-proof `.docs` assertion (migrated from the deleted story-local
  /// validators): non-empty, not the fallback, and front matter actually
  /// stripped. Checks are PRECISE (leading-anchored / exact), not arbitrary
  /// substrings, so legitimate prose that happens to contain "id:" or the phrase
  /// "documentation unavailable" mid-sentence is not wrongly rejected — the
  /// fallback IS the whole string and leaked front matter is at the TOP.
  static func assertResolved(
    _ doc: AttributedString, _ id: String,
    sourceLocation: SourceLocation = #_sourceLocation
  ) {
    let text = String(doc.characters)
    #expect(!text.isEmpty, "\(id): empty docs", sourceLocation: sourceLocation)
    // Fallback: the accessor returns exactly "Documentation unavailable for
    // <kind>.<id>." on a miss — it always STARTS with this, so an anchored check
    // detects it without banning the phrase mid-prose.
    #expect(
      !text.hasPrefix("Documentation unavailable for "),
      "\(id): fell back to the unavailable string", sourceLocation: sourceLocation)
    // Strip-proof: leaked front matter appears at the START (it is the file's
    // head), so only the LEADING content is inspected — a body sentence
    // containing "id:" or "---" mid-line is fine.
    let lead = String(text.drop(while: { $0.isWhitespace }))
    for token in ["---", "id:", "title:", "payload:"] {
      #expect(
        !lead.hasPrefix(token),
        "\(id): front-matter token '\(token)' leaked to the top of rendered docs",
        sourceLocation: sourceLocation)
    }
  }
}

// MARK: - Authoritative file validator

@Suite("Story 11.4 documentation validator")
struct DocumentationValidatorTests {

  // MARK: Per-file axis (one test case per in-scope file)

  @Test("Each in-scope file satisfies every authoring rule", arguments: DocCorpus.inScopeFiles)
  func fileSatisfiesContract(_ url: URL) {
    let (problems, warnings) = DocCorpus.validate(fileAt: url)
    let rel = "\(url.deletingLastPathComponent().lastPathComponent)/\(url.lastPathComponent)"
    #expect(problems.isEmpty, "\(rel): \(problems.map(\.description).joined(separator: "; "))")
    for warning in warnings { Issue.record("\(warning)", severity: .warning) }
  }

  // MARK: Per-rule axis (one test per rule, names the offending files)

  @Test("No file violates any single rule", arguments: DocCorpus.Rule.allCases)
  func noFileViolates(_ rule: DocCorpus.Rule) {
    var offenders: [String] = []
    for url in DocCorpus.inScopeFiles {
      let problems = DocCorpus.validate(fileAt: url).problems.filter { $0.rule == rule }
      if !problems.isEmpty {
        let rel = "\(url.deletingLastPathComponent().lastPathComponent)/\(url.lastPathComponent)"
        offenders.append("\(rel): \(problems.map(\.detail).joined(separator: ", "))")
      }
    }
    #expect(
      offenders.isEmpty,
      "rule '\(rule.rawValue)' violated by:\n\(offenders.joined(separator: "\n"))")
  }

  // MARK: Strict per-type filename lock (case-sensitive; catches _oops.md/.MD/junk)

  @Test(
    "Each type directory contains exactly its case files",
    arguments: DocCorpus.expectedIDs.keys.sorted())
  func filenameLock(_ kind: String) {
    let dir = DocCorpus.docsRoot.appendingPathComponent(kind)
    let onDisk = Set(DocCorpus.visibleFiles(in: dir))
    let expected = Set((DocCorpus.expectedIDs[kind] ?? []).map { "\($0).md" })
    #expect(
      onDisk == expected,
      "\(kind): on-disk \(onDisk.sorted()) != expected \(expected.sorted()) (exact, case-sensitive)"
    )
  }

  // MARK: documentationID uniqueness per type (closes a duplicate-ID drift hole)

  /// A newly added hand-rostered case whose `documentationID` accidentally
  /// DUPLICATES an existing case's ID would otherwise slip past FR-50: the drift
  /// suite resolves the existing `.md`, the filename `Set` collapses the
  /// duplicate, and the 49-count is unchanged. Asserting per-type ID uniqueness
  /// makes that collision a hard failure.
  @Test("Every type's documentationIDs are unique", arguments: DocCorpus.expectedIDs.keys.sorted())
  func documentationIDsAreUnique(_ kind: String) {
    let ids = DocCorpus.expectedIDs[kind] ?? []
    #expect(
      ids.count == Set(ids).count,
      "\(kind): duplicate documentationID(s) in \(ids) — a new case is masking an existing doc")
  }

  // MARK: Corpus total

  @Test("The canonical corpus totals exactly 49 in-scope files")
  func corpusTotalsExactly49() {
    #expect(
      DocCorpus.inScopeFiles.count == 49,
      "expected 49 in-scope files, found \(DocCorpus.inScopeFiles.count)")
  }

  // MARK: Type-level drift — directory <-> registry consistency (DD-11)

  @Test("Every documentation type directory has a validator registry entry")
  func documentedKindDirectoriesMatchValidatedTypes() {
    let dirs = Set(DocCorpus.typeDirectories(under: DocCorpus.docsRoot))
    let known = Set(DocCorpus.expectedIDs.keys)
    #expect(
      dirs == known,
      """
      documentation directories != validator registry.
      on-disk: \(dirs.sorted()); registry: \(known.sorted()).
      NOTE: this is a directory<->registry check; it does NOT detect a \
      DocumentedCase conformer shipped with no directory at all (Swift cannot \
      enumerate conformers at runtime) — that residual is code-review-gated.
      """)
  }

  // MARK: Scope discipline (Paige #6) — proven with a temp fixture + positive control

  @Test("Collector excludes README / templates / _-dirs but keeps real files")
  func validatorScopeRespectsReadmeAndTemplates() throws {
    let fm = FileManager.default
    let tmpRoot = fm.temporaryDirectory.appendingPathComponent(
      "bbbk-docvalidator-scope-\(ProcessInfo.processInfo.globallyUniqueString)")
    let docRoot = tmpRoot.appendingPathComponent("Documentation")
    let typeDir = docRoot.appendingPathComponent("FakeType")
    let fixtureDir = docRoot.appendingPathComponent("_Fixture")
    try fm.createDirectory(at: typeDir, withIntermediateDirectories: true)
    try fm.createDirectory(at: fixtureDir, withIntermediateDirectories: true)
    defer { try? fm.removeItem(at: tmpRoot) }

    // A README with headings at the resource root (one level ABOVE Documentation/).
    try "# Readme\n\n## Section\n".write(
      to: tmpRoot.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
    // Deliberately-invalid `_`-stem file + an `_Fixture/` sentinel — both must be skipped.
    try "# heading\n\n| a | b |\n\n```\ncode\n```\n".write(
      to: typeDir.appendingPathComponent("_test.md"), atomically: true, encoding: .utf8)
    try "   \n".write(
      to: fixtureDir.appendingPathComponent("_blank.md"), atomically: true, encoding: .utf8)
    // Positive in-scope control — MUST be collected (guards a wrong-root vacuous pass).
    try "---\nid: valid\n---\nbody\n".write(
      to: typeDir.appendingPathComponent("valid.md"), atomically: true, encoding: .utf8)

    let collected = Set(DocCorpus.collectInScope(root: docRoot).map { $0.lastPathComponent })
    #expect(
      collected.contains("valid.md"), "positive control not collected — collector root is wrong")
    #expect(!collected.contains("_test.md"), "_-stem file was collected")
    #expect(!collected.contains("README.md"), "resource-root README was collected")
    #expect(!collected.contains("_blank.md"), "_Fixture sentinel was collected")

    // And the REAL collection excludes README, _template, and the _Fixture dir.
    let realPaths = DocCorpus.inScopeFiles.map { $0.path }
    #expect(!realPaths.contains { $0.hasSuffix("/README.md") })
    #expect(!realPaths.contains { $0.hasSuffix("/_template.md") })
    #expect(!realPaths.contains { $0.contains("/_Fixture/") })
  }
}

// MARK: - Type-specific content checks (migrated from the 11.3b guard)

/// Semantic checks the generic file rules cannot express. Migrated from the
/// deleted `DocumentedCaseAuthoredDocsTests11B` so the deletion drops no coverage.
@Suite("Story 11.4 documentation content checks")
struct DocumentationContentChecksTests {

  static func bodyLowercased(_ relativePath: String) -> String {
    let raw =
      (try? String(
        contentsOf: DocCorpus.docsRoot.appendingPathComponent(relativePath), encoding: .utf8)) ?? ""
    // Strip front matter first, else a `title:` value (e.g. level7's "…default…")
    // could satisfy a body content-check the actual prose no longer makes.
    return DocCorpus.strippingFrontMatter(raw).lowercased()
  }

  @Test("level7.md documents the case .default expression-pattern footgun")
  func level7FootgunDocumented() {
    let body = Self.bodyLowercased("AnalysisIntensity/level7.md")
    #expect(body.contains("default"), "level7: no mention of .default")
    #expect(
      body.contains("expression-pattern") || body.contains("expression pattern")
        || body.contains("exhaustiv"),
      "level7: no expression-pattern / exhaustivity footgun note")
  }

  @Test("Every AnalysisIntensity level doc is budget-honest (reserved + uniform)")
  func everyLevelBudgetHonest() {
    for stem in (1...10).map({ "level\($0)" }) {
      let body = Self.bodyLowercased("AnalysisIntensity/\(stem).md")
      #expect(body.contains("budget"), "\(stem): missing budget framing")
      #expect(
        body.contains("reserved") || body.contains("uniform") || body.contains("1.0"),
        "\(stem): missing reserved/uniform budget honesty")
    }
  }

  @Test("sourceSpecific docs use no phantom quoted string value")
  func sourceSpecificNoPhantomString() {
    for path in ["AbstainReason/sourceSpecific.md", "DemotionReason/sourceSpecific.md"] {
      let raw =
        (try? String(contentsOf: DocCorpus.docsRoot.appendingPathComponent(path), encoding: .utf8))
        ?? ""
      #expect(
        !raw.contains("\""), "\(path): contains a double-quote (possible phantom string literal)")
    }
  }
}
