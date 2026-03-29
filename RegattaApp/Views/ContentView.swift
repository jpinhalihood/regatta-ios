import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var regattas: [Regatta]
    
    @State private var showingAddRegatta = false
    
    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink("Global Boat Directory") { // New navigation link
                    GlobalBoatDirectoryView()
                }
                
                Section("Regattas") { // Wrap existing regattas in a section
                    ForEach(regattas) { regatta in
                        NavigationLink(regatta.name) {
                            RegattaDetailView(regatta: regatta)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
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
    @Environment(\.modelContext) private var modelContext
    @Bindable var regatta: Regatta
    
    @State private var showingAddBoatSheet = false
    @State private var showingAddRaceSheet = false
    @State private var showingAddRaceFinishSheetForRace: Race? = nil // Holds the race for which we want to add a finish
    
    var body: some View {
        VStack {
            Text(regatta.location)
            Text("Throwouts: \\(regatta.throwouts)")
            
            List {
                Section("Boats") {
                    ForEach(regatta.boats) { boat in
                        Text("\\(boat.sailNumber) - \\(boat.name)")
                    }
                    .onDelete(perform: deleteBoat)
                }
                
                Section("Races") {
                    ForEach(regatta.races.sorted { $0.raceNumber < $1.raceNumber }) { race in
                        VStack(alignment: .leading) {
                            Text("Race \\(race.raceNumber)")
                                .font(.headline)
                            
                            // Display finishes for this race
                            if race.finishes.isEmpty {
                                Text("No finishes recorded.")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            } else {
                                ForEach(race.finishes.sorted { $0.position < $1.position }) { finish in
                                    HStack {
                                        let sailNumber = finish.boat?.sailNumber ?? "N/A"
                                        Text("\\(sailNumber) - Pos: \\(finish.position)")
                                        if finish.isDNC { Text("(DNC)") }
                                        if finish.isDNF { Text("(DNF)") }
                                        if finish.isDNS { Text("(DNS)") }
                                    }
                                    .font(.caption)
                                }
                            }
                            
                            Button("Add Finish to Race \\(race.raceNumber)") {
                                showingAddRaceFinishSheetForRace = race
                            }
                            .buttonStyle(.borderless)
                            .font(.caption)
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteRace)
                }
                
                Section("Live Scores") {
                    if regatta.boats.isEmpty || regatta.races.isEmpty {
                        Text("Add boats and races to see scores.")
                            .foregroundStyle(.gray)
                    } else {
                        let results = ScoringEngine.score(regatta: regatta)
                        ForEach(results) { result in
                            HStack {
                                Text(result.boatName)
                                Spacer()
                                Text("Net: \\(result.netScore) (Total: \\(result.totalScore))")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(regatta.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Add Boat") {
                        showingAddBoatSheet = true
                    }
                    Button("Add Race") {
                        showingAddRaceSheet = true
                    }
                } label: {
                    Label("Add New", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddBoatSheet) {
            AddBoatView(regatta: regatta)
        }
        .sheet(isPresented: $showingAddRaceSheet) {
            CreateRaceView(regatta: regatta)
        }
        .sheet(item: $showingAddRaceFinishSheetForRace) { race in
            AddRaceFinishView(regatta: regatta, race: race)
        }
    }
    
    private func deleteBoat(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let boatToDelete = regatta.boats[index]
                modelContext.delete(boatToDelete)
            }
        }
    }
    
    private func deleteRace(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let raceToDelete = regatta.races[index]
                modelContext.delete(raceToDelete)
            }
        }
    }
}
