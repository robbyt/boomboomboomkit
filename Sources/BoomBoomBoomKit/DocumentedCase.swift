//
//  DocumentedCase.swift
//  BoomBoomBoomKit
//
//  Protocol for public mode enums that expose inline, offline documentation
//  via a `docs: AttributedString` property backed by `BoomBoomBoomKitDocs`.
//

import Foundation

// MARK: - DocumentedCase

/// A public mode case that can expose authored, offline documentation inline in
/// Xcode via a ``docs`` property.
///
/// A conformer identifies its documentation catalog by a static
/// ``documentedKind`` (the enum's name, used as the resource subdirectory) and a
/// per-case ``documentationID`` (the markdown filename stem). The default
/// ``docs`` implementation resolves `Documentation/<documentedKind>/<id>.md`
/// from the package resource bundle through the thread-safe
/// ``BoomBoomBoomKitDocs/attributedString(for:id:)`` accessor.
///
/// ## Deriving `documentationID`
///
/// - String-raw enums (`enum Foo: String, DocumentedCase`) get
///   ``documentationID`` for free — a constrained extension maps it to
///   `rawValue`.
/// - Enums whose cases carry associated values cannot synthesize a raw value, so
///   they hand-write ``documentationID``. They still inherit ``docs`` from the
///   unconstrained extension.
///
/// - Note: The superprotocol bound is `Sendable` only. It deliberately does NOT
///   require `Hashable`: the docs mechanism keys its cache on an internal
///   `(kind, id)` value, never on the conformer, so `Hashable` is unnecessary.
///   Requiring it would also exclude a named future conformer
///   (`MLExecutionPolicy`) whose checked-in design is deliberately non-`Hashable`.
public protocol DocumentedCase: Sendable {
  /// The documentation catalog name for this type — the resource subdirectory
  /// under `Documentation/`. Conventionally the enum's own type name.
  static var documentedKind: String { get }

  /// The per-case documentation identifier — the markdown filename stem
  /// (without extension) under `Documentation/<documentedKind>/`.
  var documentationID: String { get }

  /// Authored, offline documentation for this case, or an informative fallback
  /// when no resource is available.
  var docs: AttributedString { get }
}

// MARK: - Default docs (unconstrained)

extension DocumentedCase {
  /// Resolves the case's documentation from the package resource bundle,
  /// falling back to an informative non-empty string when absent or unreadable.
  ///
  /// This default is intentionally on the UNCONSTRAINED extension so that
  /// associated-value conformers — which hand-write ``documentationID`` and
  /// cannot be `RawRepresentable` — inherit ``docs`` too.
  public var docs: AttributedString {
    BoomBoomBoomKitDocs.attributedString(for: Self.documentedKind, id: documentationID)
  }
}

// MARK: - Free documentationID for String-raw conformers

extension DocumentedCase where Self: RawRepresentable, Self.RawValue == String {
  /// Derives ``documentationID`` from the enum's `String` raw value.
  ///
  /// Kept SEPARATE from the unconstrained ``docs`` default so that trapping
  /// ``docs`` here can never silently strip it from associated-value conformers.
  public var documentationID: String { rawValue }
}
