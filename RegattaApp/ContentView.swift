
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: RegattaViewModel
    @State private var showingCreateRegattaSheet = false

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.regattas) { regatta in
                    NavigationLink {
                        RegattaDetailView(regatta: regatta)
                    } label: {
                        Text(regatta.name)
                    }
                }
            }
            .navigationTitle("Regattas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateRegattaSheet = true
                    } label: {
                        Label("Add Regatta", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingCreateRegattaSheet) {
                CreateRegattaView()
                    .environmentObject(viewModel)
            }
            .overlay {
                if viewModel.regattas.isEmpty {
                    Text("No regattas created yet. Tap + to add one!")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(RegattaViewModel())
    }
}
