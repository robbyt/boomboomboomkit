//
//  BoomBoomBoomKitDocs.swift
//  BoomBoomBoomKit
//
//  Thread-safe, offline accessor for per-case markdown documentation resources
//  bundled under `Documentation/<kind>/<id>.md`, with a Mutex-guarded cache.
//

import Foundation
import Synchronization

// MARK: - BoomBoomBoomKitDocs

/// Namespace for resolving per-case documentation as an `AttributedString` from
/// the package resource bundle.
///
/// This is a caseless-enum namespace (not a class): the core target's sole
/// sanctioned reference type is `ModelRegistry`. State is a single static
/// ``Synchronization/Mutex``-guarded cache.
///
/// The accessor is total: it never throws, never returns `nil`, and never
/// returns an empty string. Any miss — a missing resource, an unreadable file, a
/// markdown parse failure, an empty parse, or a malformed identifier — yields an
/// informative fallback (`"Documentation unavailable for <kind>.<id>."`).
public enum BoomBoomBoomKitDocs {

  /// Cache key over the `(kind, id)` pair. Keys the cache on the lookup tuple,
  /// never on the conformer type — that is why ``DocumentedCase`` need not be
  /// `Hashable`.
  private struct CacheKey: Hashable {
    let kind: String
    let id: String
  }

  /// All cache state, guarded by a single ``Synchronization/Mutex``.
  ///
  /// - Note: Fallbacks are cached too (negative caching). This is safe because
  ///   the resource bundle is fixed for the process lifetime, so a given
  ///   `(kind, id)` resolves identically on every call within a process. A
  ///   documentation rebuild (a later story) ships in a new binary and thus a
  ///   fresh process with an empty static cache. (This does not claim a
  ///   transiently-unreadable resource can never be cached as a fallback — only
  ///   that, for the immutable bundled resources this serves, the cached value
  ///   matches what a fresh read would produce.)
  private static let cache = Mutex<[CacheKey: AttributedString]>([:])

  // MARK: Accessor

  /// Returns the documentation for a `(kind, id)` pair as an `AttributedString`.
  ///
  /// Resolution reads `Documentation/<kind>/<id>.md` from `Bundle.module` and
  /// parses it as inline-only markdown. On any miss the informative fallback is
  /// returned. File I/O and markdown parsing occur OUTSIDE the lock; the cache
  /// is double-checked before insertion.
  ///
  /// This is advertised namespace API (not just the backing for
  /// ``DocumentedCase/docs``): callers may resolve documentation directly by
  /// string `(kind, id)`.
  ///
  /// - Parameters:
  ///   - kind: The catalog name — the resource subdirectory under
  ///     `Documentation/`. Matched by filename; case-PRESERVING, but the actual
  ///     match is filesystem-dependent (the default macOS APFS volume is
  ///     case-INSENSITIVE). Pass the exact enum-identifier casing.
  ///   - id: The per-case identifier — the markdown filename stem (same
  ///     case-folding caveat as `kind`).
  /// - Returns: The parsed documentation, or an informative non-empty fallback.
  public static func attributedString(for kind: String, id: String) -> AttributedString {
    let key = CacheKey(kind: kind, id: id)

    // Fast path: a cached hit (positive or negative) needs no I/O.
    if let cached = cache.withLock({ $0[key] }) {
      return cached
    }

    // Compute the candidate OUTSIDE the lock — never hold the Mutex across I/O.
    let fallback = AttributedString("Documentation unavailable for \(kind).\(id).")
    let candidate = resolve(kind: kind, id: id, fallback: fallback)

    // Double-checked insert: another task may have populated the key while we
    // were reading. Nothing escapes the closure.
    return cache.withLock { store in
      if let existing = store[key] {
        return existing
      }
      store[key] = candidate
      return candidate
    }
  }

  // MARK: Resolution (outside the lock)

  /// Resolves and parses the markdown resource, returning `fallback` on any miss.
  private static func resolve(
    kind: String, id: String, fallback: AttributedString
  ) -> AttributedString {
    // Malformed-input guard: never interpolate an untrusted path separator into
    // `subdirectory:`. Real callers pass controlled enum-identifier tokens, so
    // this normally never fires.
    guard isSafeIdentifier(kind), isSafeIdentifier(id) else {
      return fallback
    }

    guard
      let url = Bundle.module.url(
        forResource: id, withExtension: "md", subdirectory: "Documentation/\(kind)"),
      let parsed = try? AttributedString(
        contentsOf: url,
        options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace),
        baseURL: nil),
      // Blank-parse is a MISS: a zero-length parse OR an all-whitespace file
      // must not defeat the never-empty guarantee. Inline-only mode PRESERVES
      // whitespace, so a whitespace-only file parses to a non-empty but visually
      // blank string — `isEmpty` alone would let it through. Block markup under
      // inline-only mode is retained as literal text, so genuine content always
      // contains a non-whitespace character and is never wrongly rejected.
      parsed.characters.contains(where: { !$0.isWhitespace })
    else {
      return fallback
    }

    return parsed
  }

  /// Rejects an empty identifier or one containing a path separator or a `..`
  /// path segment. Real callers pass controlled enum-identifier tokens (ASCII,
  /// no separators), so this only fires on hostile string input.
  private static func isSafeIdentifier(_ value: String) -> Bool {
    !value.isEmpty && !value.contains("/") && !value.contains("..")
  }
}
