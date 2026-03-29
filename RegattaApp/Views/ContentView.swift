import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var regattas: [Regatta]
    
    @State private var showingAddRegatta = false
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(regattas) { regatta in
                    NavigationLink(regatta.name) {
                        RegattaDetailView(regatta: regatta)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Regattas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddRegatta = true }) {
                        Label("Add Regatta", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRegatta) {
                CreateRegattaView()
            }
        } detail: {
            Text("Select a Regatta")
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(regattas[index])
            }
        }
    }
}

struct RegattaDetailView: View {
    var regatta: Regatta
    
    var body: some View {
        VStack {
            Text(regatta.location)
            Text("Throwouts: \(regatta.throwouts)")
            
            List {
                Section("Boats") {
                    ForEach(regatta.boats) { boat in
                        Text("\(boat.sailNumber) - \(boat.name)")
                    }
                }
                Section("Live Scores") {
                    let results = ScoringEngine.score(regatta: regatta)
                    ForEach(results) { result in
                        HStack {
                            Text(result.boatName)
                            Spacer()
                            Text("Net: \(result.netScore) (Total: \(result.totalScore))")
                        }
                    }
                }
            }
        }
        .navigationTitle(regatta.name)
    }
}
