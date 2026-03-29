
import SwiftUI
import SwiftData

struct CreateRaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var regatta: Regatta

    @State private var raceNumber: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Race Details") {
                    TextField("Race Number", text: $raceNumber)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add New Race")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addRace()
                        dismiss()
                    }
                    .disabled(raceNumber.isEmpty || (Int(raceNumber) == nil))
                }
            }
        }
    }

    private func addRace() {
        guard let number = Int(raceNumber) else { return }
        let newRace = Race(raceNumber: number)
        regatta.races.append(newRace)
        newRace.regatta = regatta // Establish inverse relationship
        do {
            try modelContext.save()
        } catch {
            print("Failed to save new race: \(error.localizedDescription)")
        }
    }
}
