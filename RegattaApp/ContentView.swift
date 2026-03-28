
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RegattaViewModel()
    @State private var selectedRegatta: String?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedRegatta) {
                ForEach(viewModel.regattas, id: \.self) { regatta in
                    NavigationLink(value: regatta) {
                        Text(regatta)
                    }
                }
            }
            .navigationTitle("Regattas")
        } detail: {
            if let selectedRegatta = selectedRegatta {
                Text("Details for \(selectedRegatta)")
                // Here you would navigate to a ScoringGridView or similar
                // For now, a placeholder
            } else {
                Text("Select a Regatta")
            }
        }
    }
}

#Preview {
    ContentView()
}
