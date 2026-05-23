import SwiftUI

@main
struct BoomBoomBoomKitDemoApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .defaultSize(width: 960, height: 600)
    .windowStyle(.titleBar)
    // `InspectorCommands` wires Control-Command-I + View menu toggle
    // for the trace inspector — required for an `.inspector(...)` to
    // get standard macOS keyboard/menu affordances.
    .commands {
      InspectorCommands()
    }
  }
}
