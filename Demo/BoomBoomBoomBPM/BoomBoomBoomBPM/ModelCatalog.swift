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
/// - **A token-bearing capability URL is retained per entry.** `entry.url` is the
///   standardized identity URL (tokenless — correct for dedupe/marking, but a
///   sandboxed read on it is denied because `startAccessingSecurityScopedResource()`
///   returns false). So every mirrored entry also retains, in ``accessURLs`` keyed
///   by that standardized identity, the *raw* URL its security scope was started on
///   (the `NSOpenPanel` URL for add; the `resolveAll()` bookmark URL for restore).
///   ``loadableURL(for:)`` hands that back so the load path scopes a URL that can
///   actually grant access. Same-session move/rename before load is an accepted
///   edge case (relaunch recovers via bookmark resolution); full same-session
///   recovery would need a retained bookmark UUID + targeted re-resolve.
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

  /// The token-bearing capability URL per entry, keyed by the entry's standardized
  /// identity URL (DD7). `entry.url` is standardized/tokenless and unusable for a
  /// sandboxed read; this holds the raw URL the security scope was started on (the
  /// `NSOpenPanel` URL for add, the `resolveAll()` bookmark URL for restore), which
  /// retains its scope provenance and can be re-started at load. `@ObservationIgnored`
  /// — it drives no UI; ``entries`` does. Never store `standardizedFileURL` here:
  /// standardizing strips the scope token (the whole reason for the map).
  @ObservationIgnored
  private var accessURLs: [URL: URL] = [:]

  /// The URL of the model the user chose via "Use this model" (DD7 — keyed by
  /// URL, drives the `Selected:` mark). `nil` until a model is used.
  ///
  /// Session-scoped by design: `restore()` re-lists persisted models but does
  /// NOT re-attach a technique, so after relaunch a previously-chosen model
  /// appears in the list but is not loaded and `selectedURL` is `nil` again
  /// (AC5 promises list presence only). Persisting the selection + auto-reload
  /// on launch is deferred-work W81.
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
        // Scope is started on the bookmark-bearing `url` (it carries the
        // security-scope token from resolveAll); `key` is its standardized-path
        // equivalent for the SAME file, so the process-wide sandbox grant covers
        // the `registerEntry` read. Starting the scope on `key` instead would
        // return false — a fresh URL has no token.
        let entry = try BookmarkPersistence.withSecurityScopedAccess(to: url) {
          try registerEntry(standardizedURL: key)
        }
        // Retain the raw resolved bookmark `url` (token-bearing) — NOT `key` — so
        // the later load path can re-start its scope for the sandboxed read.
        mirror(entry, source: .userAdded, accessURL: url)
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
      // Scope started on the token-bearing `url`; `key` is its standardized-path
      // equivalent (same file), so the register/store I/O is covered. Starting
      // on `key` would return false — a fresh URL carries no scope token.
      let entry = try BookmarkPersistence.withSecurityScopedAccess(to: url) {
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
      // Retain the raw panel `url` (token-bearing) — NOT `key` — as the load-path
      // capability URL; an NSOpenPanel URL can be re-started after its add-time
      // scope was stopped.
      mirror(entry, source: .userAdded, accessURL: url)
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

  /// The token-bearing capability URL to hand to the load path for `entry`, or
  /// `nil` if none is retained (e.g. a restore whose earlier resolve failed).
  /// Pure in-memory lookup — no I/O, and NOT `resolveAll()` (that API is
  /// launch-only and destructively prunes/refreshes persistence; running it per
  /// load click could drop an unrelated temporarily-unavailable model).
  ///
  /// `entry.url` is standardized/tokenless, so loading THAT is exactly the P1 bug
  /// (a sandboxed `BNNSTechnique` read is denied). This returns the raw URL whose
  /// scope was started at add/restore, which retains its provenance.
  func loadableURL(for entry: ModelRegistryEntry) -> URL? {
    accessURLs[entry.url.standardizedFileURL]
  }

  /// Outcome of ``useModel(_:load:)`` — the catalog-side decision the picker maps
  /// to its view-side effects (dismiss / detach / error surface).
  enum UseOutcome: Equatable {
    /// The capability URL loaded; the entry is now the `Selected:` model.
    case loaded
    /// A capability URL existed but `load` returned false; selection cleared.
    case loadFailed
    /// No capability URL is retained for the entry; selection cleared. The picker
    /// surfaces this as a load failure (detach + labeled error).
    case capabilityMissing
  }

  /// Resolve `entry` to its token-bearing capability URL and drive `load` with it
  /// (NEVER `entry.url` — that tokenless URL is the original P1). This is the
  /// regression-critical handoff, kept here (not inlined in the SwiftUI view) so a
  /// unit test can assert the raw capability URL — not `entry.url` — reaches the
  /// loader. Applies the catalog-side selection effect; the picker owns the
  /// view-model side (`loadModel` already detaches on its own failure).
  @discardableResult
  func useModel(_ entry: ModelRegistryEntry, load: (URL) -> Bool) -> UseOutcome {
    guard let loadURL = loadableURL(for: entry) else {
      clearSelection()
      return .capabilityMissing
    }
    if load(loadURL) {
      select(url: entry.url)
      return .loaded
    }
    clearSelection()
    return .loadFailed
  }

  /// The labeled trust-on-first-use integrity string (DD4). `register` with
  /// `expectedDigest: nil` records the current bytes; it does NOT verify against
  /// a pin, so the honest label is "recorded", never "verified".
  ///
  /// TOFU limitation: the digest is recorded when `register` reads the bundle at
  /// add/restore; the later ``AnalysisViewModel/loadModel(at:)`` does NOT re-verify
  /// current bytes against it. An on-disk swap between registration and load is not
  /// detected by this label (out of scope for the sandbox-load fix).
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

  /// Clear the launch-time restore diagnostics. `restoreDiagnostics` is a
  /// once-per-launch event; the picker shows it on the first open and calls this
  /// on dismiss so a `Reason: restored-model-unavailable` from launch doesn't
  /// haunt every later sheet open all session. Does NOT touch `entries`.
  func clearRestoreDiagnostics() {
    restoreDiagnostics.removeAll()
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
  ///
  /// `accessURL` is the raw, token-bearing URL the scope was started on for this
  /// entry; it is REQUIRED so the load-path capability can never be missing for a
  /// visible row. `sources`/`accessURLs` are populated BEFORE `entries.append` so
  /// an `@Observable` re-render can never see a row before its capability exists.
  private func mirror(_ entry: ModelRegistryEntry, source: ModelSource, accessURL: URL) {
    assert(
      accessURL.standardizedFileURL == entry.url.standardizedFileURL,
      "capability URL must address the same file as the entry")
    let key = entry.url.standardizedFileURL
    sources[key] = source
    accessURLs[key] = accessURL
    entries.append(entry)
  }
}
