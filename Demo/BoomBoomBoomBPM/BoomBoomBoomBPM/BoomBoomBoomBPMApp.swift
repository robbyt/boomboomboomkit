import SwiftUI

@main
struct BoomBoomBoomBPMApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
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
