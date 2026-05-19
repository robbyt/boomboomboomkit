import SwiftUI

struct ContentView: View {
  @State private var viewModel = AnalysisViewModel()

  var body: some View {
    VStack(spacing: 12) {
      Text("Drop an audio file")
        .font(.title2)
      Text("File drop wiring lands in Story 5-2")
        .font(.callout)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
}
