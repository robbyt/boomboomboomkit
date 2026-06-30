import Foundation

/// Provides access to shared audio test fixtures bundled in BoomBoomBoomKitTestSupport.
///
/// Usage from any test target that depends on BoomBoomBoomKitTestSupport:
///   let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
public enum AudioFixtures {
  /// Resolves an audio fixture URL from the TestSupport resource bundle.
  /// - Parameters:
  ///   - name: Fixture file name without extension (e.g., "Meta_Man")
  ///   - extension: File extension (e.g., "mp3")
  /// - Returns: URL to the fixture file.
  /// - Throws: `AudioFixtureError.notFound` if the fixture is missing.
  public static func url(for name: String, extension ext: String) throws -> URL {
    if let url = Bundle.module.url(
      forResource: name, withExtension: ext, subdirectory: "AudioFixtures"
    ) {
      return url
    }

    // Fallback: `Bundle.url(forResource:)` is Unicode-normalization SENSITIVE, so a
    // fixture whose name carries combining accents (e.g. Greek) misses when the
    // on-disk / bundled form (NFC vs NFD) differs from the source literal across a
    // git checkout or CI runner. Enumerate the bundle directory and match basename
    // and extension SEPARATELY in canonical (NFC) form — comparing the parts rather
    // than a joined "name.ext" string keeps names containing dots unambiguous.
    let wantName = name.precomposedStringWithCanonicalMapping
    if let candidates = Bundle.module.urls(
      forResourcesWithExtension: ext, subdirectory: "AudioFixtures"
    ) {
      for candidate in candidates
      where candidate.deletingPathExtension().lastPathComponent
        .precomposedStringWithCanonicalMapping == wantName && candidate.pathExtension == ext
      {
        return candidate
      }
    }

    throw AudioFixtureError.notFound("\(name).\(ext)")
  }
}

public enum AudioFixtureError: Error {
  case notFound(String)
}
