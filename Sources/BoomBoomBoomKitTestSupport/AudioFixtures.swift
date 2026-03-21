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
    guard
      let url = Bundle.module.url(
        forResource: name, withExtension: ext, subdirectory: "AudioFixtures"
      )
    else {
      throw AudioFixtureError.notFound("\(name).\(ext)")
    }
    return url
  }
}

public enum AudioFixtureError: Error {
  case notFound(String)
}
