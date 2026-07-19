import SwiftUI

@main
struct BoomBoomBoomBPMApp: App {
  // Owns the registry-backed model catalog (Story 10.2). App-level so its
  // synchronous `restore()` (bookmark resolution + SHA-256 of every model) runs
  // ONCE at app lifetime, not on every `ContentView` construction — a
  // `ContentView`-local `@State = ModelCatalog()` would re-run restore-and-throw-
  // away each time SwiftUI rebuilds the view value (the @State-eager-init gotcha).
  @State private var modelCatalog = ModelCatalog()

  var body: some Scene {
    WindowGroup {
      ContentView(modelCatalog: modelCatalog)
    }
    .defaultSize(width: 960, height: 600)
    // Explicit window policy: the window's minimum tracks the content's minimum
    // size and it does not couple to the content's ideal size (which `.contentSize`
    // would, and which the default `.automatic` lets balloon when dynamic content
    // appears). Because the window minimum follows content MIN, the content must
    // keep a small minimum height: the analysis lane fills with `maxHeight:.infinity`
    // (no min/ideal/layoutPriority) so it never raises that minimum, and `.defaultSize`
    // above sets the launch height. That combination keeps the window freely
    // shrinkable regardless of how tall the analysis pane can grow.
    .windowResizability(.contentMinSize)
    .windowStyle(.titleBar)
    // `InspectorCommands` wires Control-Command-I + View menu toggle
    // for the trace inspector — required for an `.inspector(...)` to
    // get standard macOS keyboard/menu affordances.
    .commands {
      InspectorCommands()
    }
  }
}
