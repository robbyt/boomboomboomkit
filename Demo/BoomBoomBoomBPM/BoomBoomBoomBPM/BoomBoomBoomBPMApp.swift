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
    // appears). The beat-grid section's own height cap is the root fix; this is a
    // belt-and-suspenders guard.
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
