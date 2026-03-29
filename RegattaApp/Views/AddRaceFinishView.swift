
import SwiftUI
import SwiftData

struct AddRaceFinishView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var regatta: Regatta // To access all boats in the regatta
    @Bindable var race: Race // The specific race to add a finish to

    @State private var selectedBoat: Boat? // Selected boat for the finish
    @State private var position: String = "1"
    @State private var isDNC: Bool = false
    @State private var isDNF: Bool = false
    @State private var isDNS: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section("Race Finish Details") {
                    Picker("Boat", selection: $selectedBoat) {
                        Text("Select Boat").tag(nil as Boat?)
                        ForEach(regatta.boats) {
                            Text("\($0.sailNumber) - \($0.name)").tag($0 as Boat?)
                        }
                    }
                    
                    TextField("Position", text: $position)
                        .keyboardType(.numberPad)
                        .disabled(isDNC || isDNF || isDNS) // Position disabled if any penalty is selected
                    
                    Toggle("Did Not Compete (DNC)", isOn: $isDNC)
                    Toggle("Did Not Finish (DNF)", isOn: $isDNF)
                    Toggle("Did Not Start (DNS)", isOn: $isDNS)
                }
            }
            .navigationTitle("Add Race Finish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addRaceFinish()
                        dismiss()
                    }
                    .disabled(selectedBoat == nil || (position.isEmpty && !(isDNC || isDNF || isDNS)))
                }
            }
            .onChange(of: isDNC) { oldValue, newValue in
                if newValue { isDNF = false; isDNS = false }
            }
            .onChange(of: isDNF) { oldValue, newValue in
                if newValue { isDNC = false; isDNS = false }
            }
            .onChange(of: isDNS) { oldValue, newValue in
                if newValue { isDNC = false; isDNF = false }
            }
        }
    }

    private func addRaceFinish() {
        guard let selectedBoat = selectedBoat else { return }
        
        let finishPosition = Int(position) ?? 0 // Default to 0 if position is empty or invalid
        
        let newRaceFinish = RaceFinish(position: finishPosition, isDNC: isDNC, isDNF: isDNF, isDNS: isDNS)
        newRaceFinish.boat = selectedBoat
        newRaceFinish.race = race
        
        selectedBoat.finishes.append(newRaceFinish) // Establish inverse relationship
        race.finishes.append(newRaceFinish) // Establish inverse relationship
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save new race finish: \(error.localizedDescription)")
        }
    }
}
