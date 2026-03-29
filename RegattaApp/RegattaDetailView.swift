
import SwiftUI

struct RegattaDetailView: View {
    @EnvironmentObject var viewModel: RegattaViewModel
    @State var regatta: Regatta

    @State private var showingAddBoatSheet = false
    @State private var showingAddRaceFinishSheet = false
    @State private var selectedRace: Race? // To pass to the RaceFinish sheet

    var body: some View {
        List {
            Section(header: Text("Regatta Info")) {
                Text("Name: \(regatta.name)")
                Text("Location: \(regatta.location)")
                Text("Throwouts: \(regatta.throwouts)")
            }
            
            Section(header: boatsHeader) {
                if regatta.boats.isEmpty {
                    Text("No boats added yet.")
                } else {
                    ForEach(regatta.boats) { boat in
                        Text("Sail #\(boat.sailNumber): \(boat.name)")
                    }
                }
            }

            Section(header: racesHeader) {
                if regatta.races.isEmpty {
                    Text("No races added yet.")
                } else {
                    ForEach(regatta.races) { race in
                        VStack(alignment: .leading) {
                            Text("Race \(race.raceNumber)")
                                .font(.headline)
                            if race.finishes.isEmpty {
                                Text("No finishes for this race.")
                            } else {
                                ForEach(race.finishes) { finish in
                                    if let boat = regatta.boats.first(where: { $0.id == finish.boatId }) {
                                        Text("\(boat.sailNumber) - Position: \(finish.position)")
                                    }
                                }
                            }
                            Button("Add Finish for Race \(race.raceNumber)") {
                                selectedRace = race
                                showingAddRaceFinishSheet = true
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Scored Results")) {
                if regatta.scoredResults.isEmpty {
                    Text("No scored results yet. Add some races and finishes!")
                } else {
                    ForEach(regatta.scoredResults) { result in
                        if let boat = regatta.boats.first(where: { $0.id == result.boatId }) {
                            Text("\(boat.name) (\(boat.sailNumber)): \(result.score, specifier: "%.2f")")
                        }
                    }
                }
            }
        }
        .navigationTitle(regatta.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.addRace(to: regatta)
                    // Update local regatta state to reflect change if needed, or re-fetch from view model
                    if let updatedRegatta = viewModel.regattas.first(where: { $0.id == regatta.id }) {
                        self.regatta = updatedRegatta
                    }
                } label: {
                    Label("Add Race", systemImage: "flag.checkered")
                }
            }
        }
        .sheet(isPresented: $showingAddBoatSheet) {
            AddBoatView(regatta: $regatta)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingAddRaceFinishSheet) {
            if let selectedRace = selectedRace {
                AddRaceFinishView(regatta: $regatta, race: selectedRace)
                    .environmentObject(viewModel)
            }
        }
        .onReceive(viewModel.$regattas) { updatedRegattas in
            // Keep the local 'regatta' state updated when the view model changes
            if let updated = updatedRegattas.first(where: { $0.id == regatta.id }) {
                self.regatta = updated
            }
        }
    }
    
    var boatsHeader: some View {
        HStack {
            Text("Boats")
            Spacer()
            Button {
                showingAddBoatSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
            }
        }
    }
    
    var racesHeader: some View {
        HStack {
            Text("Races")
            Spacer()
            // The add race button is in the toolbar now.
        }
    }
}

// MARK: - AddBoatView

struct AddBoatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: RegattaViewModel
    @Binding var regatta: Regatta

    @State private var sailNumber: String = ""
    @State private var name: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Boat Details")) {
                    TextField("Sail Number", text: $sailNumber)
                    TextField("Boat Name", text: $name)
                }
            }
            .navigationTitle("Add New Boat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.addBoat(to: regatta, sailNumber: sailNumber, name: name)
                        dismiss()
                    }
                    .disabled(sailNumber.isEmpty || name.isEmpty)
                }
            }
        }
    }
}

// MARK: - AddRaceFinishView

struct AddRaceFinishView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: RegattaViewModel
    @Binding var regatta: Regatta
    var race: Race

    @State private var selectedBoatId: UUID? // Using UUID for boat selection
    @State private var position: Int = 1

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Race \(race.raceNumber) Finish")) {
                    Picker("Boat", selection: $selectedBoatId) {
                        Text("Select a boat").tag(nil as UUID?)
                        ForEach(regatta.boats) {
                            Text("\($0.sailNumber) - \($0.name)").tag($0.id as UUID?)
                        }
                    }
                    Stepper(value: $position, in: 1...regatta.boats.count) {
                        Text("Position: \(position)")
                    }
                }
            }
            .navigationTitle("Add Finish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let boatId = selectedBoatId {
                            viewModel.addRaceFinish(to: regatta, race: race, boatId: boatId, position: position)
                            dismiss()
                        }
                    }
                    .disabled(selectedBoatId == nil)
                }
            }
        }
    }
}

struct RegattaDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy Regatta and ViewModel for preview
        let viewModel = RegattaViewModel()
        let regatta = Regatta(name: "Preview Regatta", location: "Ocean", throwouts: 1)
        viewModel.regattas.append(regatta)
        
        return NavigationView {
            RegattaDetailView(regatta: regatta)
                .environmentObject(viewModel)
        }
    }
}
