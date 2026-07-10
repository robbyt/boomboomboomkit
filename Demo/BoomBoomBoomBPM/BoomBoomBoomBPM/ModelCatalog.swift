import BoomBoomBoomKit
import Foundation
import Observation

/// Demo-only catalog that wraps the library ``ModelRegistry`` and the Story-10.1
/// ``BookmarkPersistence`` into a single observable source of truth for the
/// model-picker sheet (Story 10.2).
///
/// The library registry is an ephemeral, `Mutex`-guarded, in-memory catalog with
/// no persistence and no source/provenance field. The *persistent, multi-entry,
/// provenance-tagged* view the picker needs is therefore a demo-side construct:
///
/// - **Identity is URL-keyed, never identifier-keyed (DD7).**
///   ``ModelMetadata/identifier`` is derived from the filename and is NOT unique
///   (two `model.mlmodelc` in different folders collide); `register` appends
///   without identifier dedup and `lookup(identifier:)` returns the first match.
///   So provenance, selection, and the `Selected:` mark are all keyed on
///   `url.standardizedFileURL`.
/// - **Add is transactional (DD8).** `addFromDisk` calls `register` FIRST
///   (validate — the digest read must succeed) and only persists the bookmark on
///   success, so a `register` throw never orphans a stored bookmark.
/// - **Restore is resilient (DD8).** `restore()` dedups the resolved tuples by
///   `standardizedFileURL` (W79 — `resolveAll()` can return duplicate URLs) and
///   registers each under security scope, catching per-entry `register` throws
///   so one moved/unhashable file cannot abort restore or the launch.
/// - **Security scope is explicit (DD9).** `resolveAll()` returns URLs with the
///   scope NOT started; every `register` (which does file I/O to hash the
///   bundle) runs inside ``BookmarkPersistence/withSecurityScopedAccess(to:perform:)``.
///
/// `@MainActor @Observable` per the demo's `SWIFT_DEFAULT_ACTOR_ISOLATION =
/// MainActor` default. `register` recomputes SHA-256 synchronously on the main
/// actor (DD5 caveat — accepted for the demo; models are MB-scale); the
/// `withSecurityScopedAccess` bodies stay synchronous (no `await` inside the
/// bracket).
@MainActor
@Observable
final class ModelCatalog {

  /// Provenance of a catalog entry. Today every entry is `.userAdded`; the other
  /// two cases are documented seams for a future bundled / known-public model
  /// (DD2 — no bundled model ships since Story 4-6 Branch C), not dead code.
  enum ModelSource: String, Sendable, CaseIterable {
    case bundled
    case knownPublic
    case userAdded

    /// Human-readable, used behind the FR-44 `Source:` label in the picker row.
    var display: String {
      switch self {
      case .bundled: return "Bundled"
      case .knownPublic: return "Known-public"
      case .userAdded: return "User-added"
      }
    }
  }

  /// Why an `addFromDisk` was rejected. `reason` is a labeled FR-44 string the
  /// picker surfaces verbatim.
  enum AddError: Error, Equatable {
    /// The URL is already in the catalog (deduped by `standardizedFileURL`, W79).
    case alreadyAdded
    /// `register` threw — a wrong selection (not a hashable `.mlmodelc` bundle)
    /// or an unreadable path. No bookmark was persisted, no row added (DD8).
    case registerFailed
    /// `register` succeeded but persisting the bookmark (`store`) threw. No row
    /// is added and no bookmark is persisted, so the add can be retried cleanly
    /// (DD8 — the observable mirror is updated only after BOTH steps succeed).
    case persistFailed

    var reason: String {
      switch self {
      case .alreadyAdded: return "Reason: model-already-added"
      case .registerFailed: return "Reason: model-register-failed"
      case .persistFailed: return "Reason: model-persist-failed"
      }
    }
  }

  /// The library registry. `@ObservationIgnored` — it is not itself observable;
  /// the mirrored ``entries`` below drives the UI.
  @ObservationIgnored
  private let registry = ModelRegistry()

  /// The 10.1 persistence layer, injectable so tests drive the fake `Codec` seam.
  @ObservationIgnored
  private let bookmarks: BookmarkPersistence

  /// Snapshot of the registry entries, mirrored after every successful
  /// `register` so the `@Observable` machinery re-renders the picker `List`
  /// (`registry.entries` alone is not observable).
  private(set) var entries: [ModelRegistryEntry] = []

  /// Provenance keyed by `standardizedFileURL` (DD7 — identifiers are not
  /// unique).
  private var sources: [URL: ModelSource] = [:]

  /// The URL of the model the user chose via "Use this model" (DD7 — keyed by
  /// URL, drives the `Selected:` mark). `nil` until a model is used.
  var selectedURL: URL?

  /// Labeled `Reason:` diagnostics accumulated during `restore()` (one per
  /// skipped, unresolvable/unhashable entry — DD8).
  private(set) var restoreDiagnostics: [String] = []

  var isEmpty: Bool { entries.isEmpty }

  init(bookmarks: BookmarkPersistence = BookmarkPersistence(defaults: .standard)) {
    self.bookmarks = bookmarks
    restore()
  }

  // MARK: - Restore (launch)

  /// Re-register every persisted user-added model through
  /// ``BookmarkPersistence/resolveAll()`` (AC5). Dedups the resolved tuples by
  /// `standardizedFileURL` (W79) and registers each under security scope,
  /// catching per-entry `register` throws so one moved/unhashable file cannot
  /// abort restore or the launch — a failed entry is skipped with a labeled
  /// `Reason: restored-model-unavailable` diagnostic (DD8).
  private func restore() {
    var seen = Set<URL>()
    for (_, url) in bookmarks.resolveAll() {
      let key = url.standardizedFileURL
      guard seen.insert(key).inserted else { continue }
      do {
        let entry = try bookmarks.withSecurityScopedAccess(to: url) {
          try registerEntry(standardizedURL: key)
        }
        mirror(entry, source: .userAdded)
      } catch {
        restoreDiagnostics.append("Reason: restored-model-unavailable")
      }
    }
  }

  // MARK: - Add from disk (transactional)

  /// Validate-then-persist a user-picked model bundle (AC3). Dedups by
  /// `standardizedFileURL` (labeled `model-already-added`); otherwise, inside one
  /// `withSecurityScopedAccess` bracket, calls `register` FIRST (validate) and only
  /// on success persists the bookmark. The observable ``entries`` mirror is
  /// appended **only after BOTH register and store succeed** (DD8), so:
  /// - a `register` throw leaves no orphaned bookmark and no row (`registerFailed`);
  /// - a `store` throw leaves no persisted bookmark and no ghost row, and the add
  ///   can be retried cleanly (`persistFailed`).
  @discardableResult
  func addFromDisk(url: URL) -> Result<Void, AddError> {
    let key = url.standardizedFileURL
    if entries.contains(where: { $0.url.standardizedFileURL == key }) {
      return .failure(.alreadyAdded)
    }
    do {
      let entry = try bookmarks.withSecurityScopedAccess(to: url) {
        () throws -> ModelRegistryEntry in
        let registered: ModelRegistryEntry
        do {
          registered = try registerEntry(standardizedURL: key)
        } catch {
          throw AddError.registerFailed
        }
        do {
          _ = try bookmarks.store(url: url)
        } catch {
          // register succeeded but persistence failed — retryable, no ghost row.
          throw AddError.persistFailed
        }
        return registered
      }
      // Mirror only after both steps committed (never a half-committed row).
      mirror(entry, source: .userAdded)
      return .success(())
    } catch let addError as AddError {
      return .failure(addError)
    } catch {
      return .failure(.registerFailed)
    }
  }

  // MARK: - Accessors

  func source(for url: URL) -> ModelSource {
    sources[url.standardizedFileURL] ?? .userAdded
  }

  /// The labeled trust-on-first-use integrity string (DD4). `register` with
  /// `expectedDigest: nil` records the current bytes; it does NOT verify against
  /// a pin, so the honest label is "recorded", never "verified".
  func integrityLabel(for entry: ModelRegistryEntry) -> String {
    "Integrity: recorded \(entry.digestHexString.prefix(12))"
  }

  /// Mark `url` as the in-use model. Returns the resolved entry URL (the
  /// standardized URL the digest was computed over) or `nil` if no entry matches.
  @discardableResult
  func select(url: URL) -> URL? {
    let key = url.standardizedFileURL
    guard let entry = entries.first(where: { $0.url.standardizedFileURL == key }) else {
      return nil
    }
    selectedURL = entry.url
    return entry.url
  }

  func isSelected(_ entry: ModelRegistryEntry) -> Bool {
    entry.url.standardizedFileURL == selectedURL?.standardizedFileURL
  }

  /// Clear the in-use mark. Called when a load fails so no row can render
  /// `Selected: yes` while no technique is actually attached (FR-44 honesty — a
  /// failed `loadModel` clears the prior technique, so nothing is in use).
  func clearSelection() {
    selectedURL = nil
  }

  // MARK: - Private

  /// Register `standardizedURL` (identity derived from the filename per the story)
  /// and return the entry. Does NOT touch the observable mirror — the caller
  /// mirrors only after every step it requires has committed (DD8). Throws
  /// whatever `register` throws; the caller decides skip (restore) vs reject (add).
  private func registerEntry(standardizedURL: URL) throws -> ModelRegistryEntry {
    try registry.register(
      url: standardizedURL,
      metadata: ModelMetadata(
        identifier: standardizedURL.deletingPathExtension().lastPathComponent,
        capabilities: [.tempoEstimation]))
  }

  /// Append the just-registered `entry` to the observable mirror. Called only
  /// after the caller's steps have all committed, so the mirror never shows a
  /// half-committed (ghost) row. Appends the single entry rather than copying
  /// `registry.entries` wholesale, so a `store`-failure that leaves the ephemeral
  /// registry with an unshown entry cannot resurface as a duplicate row on retry.
  private func mirror(_ entry: ModelRegistryEntry, source: ModelSource) {
    sources[entry.url.standardizedFileURL] = source
    entries.append(entry)
  }
}
